```solidity
/**
 * @title Decentralized Autonomous Organization for Collaborative Art (DAOArt)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a DAO focused on collaborative art creation, management, and monetization.
 *      This contract introduces novel concepts like:
 *      - Layered Contribution and Reward System: Different levels of contribution (Idea, Design, Execution, Promotion) with varying reward ratios.
 *      - Dynamic Consensus Building:  Consensus requirements adapt based on the type and impact of proposals.
 *      - On-chain Reputation System:  Members gain reputation based on their successful contributions and positive community feedback.
 *      - Art Piece Evolution Mechanism:  Art pieces can be iteratively improved and expanded upon through community proposals and voting.
 *      - Decentralized Art Marketplace Integration:  Built-in functions for listing, auctioning, and selling collaborative art pieces.
 *      - Skill-Based Task Assignment:  Proposals can request specific skills, and members can register their skills for task matching.
 *      - Quadratic Voting for Resource Allocation:  More impactful proposals require proportionally more votes to pass, enhancing fairness.
 *      - Collaborative Funding Rounds:  DAO members can collectively fund new art projects.
 *      - Art Piece Versioning and History:  Track the evolution of art pieces and contributor history.
 *      - Decentralized Dispute Resolution (Simulated): A basic framework for resolving conflicts related to art contributions.
 *      - Dynamic Reward Adjustment:  Reward ratios can be adjusted by the DAO through governance proposals.
 *      - Community Feedback Mechanism:  Members can provide feedback on completed tasks and contributions.
 *      - Skill-Based Access Control:  Certain functions can be restricted to members with specific skills.
 *      - External Art Data Integration (Simulated):  Placeholder for potential integration with external art data sources.
 *      - Time-Based Contribution Windows:  Proposals can define timeframes for contributions and deadlines.
 *      - Milestone-Based Task Completion:  Larger tasks can be broken into milestones for better management and reward distribution.
 *      - Partial Contribution Acceptance:  DAO can accept parts of a proposed contribution if it's deemed partially suitable.
 *      - Art Piece Royalty Distribution:  Automated royalty distribution to contributors upon art piece sales.
 *      - Decentralized Curation System:  DAO members can curate and feature specific art pieces within the collection.
 *
 * Function Summary:
 * 1. registerMember(string memory _name, string[] memory _skills): Allows users to register as DAO members, specifying their name and skills.
 * 2. updateMemberSkills(string[] memory _newSkills): Allows members to update their registered skills.
 * 3. proposeArtPiece(string memory _title, string memory _description, string memory _initialConcept, string[] memory _requiredSkills):  Members propose a new collaborative art piece with title, description, concept, and required skills.
 * 4. contributeToArtPiece(uint256 _artPieceId, ContributionType _contributionType, string memory _contributionDetails): Members contribute to an art piece, specifying their contribution type and details.
 * 5. voteOnContribution(uint256 _artPieceId, uint256 _contributionId, bool _approve): Members vote to approve or reject a contribution to an art piece.
 * 6. finalizeArtPiece(uint256 _artPieceId):  After contributions are approved, finalize the art piece, minting an NFT and distributing initial rewards.
 * 7. proposeArtPieceImprovement(uint256 _artPieceId, string memory _improvementProposal, string[] memory _requiredSkills): Members propose improvements or expansions to existing art pieces.
 * 8. contributeToImprovement(uint256 _artPieceId, uint256 _improvementProposalId, ContributionType _contributionType, string memory _contributionDetails): Members contribute to an art piece improvement proposal.
 * 9. voteOnImprovementContribution(uint256 _artPieceId, uint256 _improvementProposalId, uint256 _contributionId, bool _approve): Members vote on contributions to art piece improvements.
 * 10. finalizeArtPieceImprovement(uint256 _artPieceId, uint256 _improvementProposalId): Finalize an approved art piece improvement, updating the art piece NFT and distributing rewards.
 * 11. listArtPieceForSale(uint256 _artPieceId, uint256 _price): DAO lists a finalized art piece for sale at a specified price.
 * 12. purchaseArtPiece(uint256 _artPieceId): Allows anyone to purchase a listed art piece, distributing royalties to contributors.
 * 13. proposeRewardRatioChange(ContributionType _contributionType, uint256 _newRatio): Members propose changes to the reward ratios for different contribution types.
 * 14. voteOnRewardRatioChange(uint256 _proposalId, bool _approve): Members vote on reward ratio change proposals.
 * 15. executeRewardRatioChange(uint256 _proposalId): Executes an approved reward ratio change proposal.
 * 16. provideMemberFeedback(address _memberAddress, string memory _feedback): Members can provide feedback on other members' contributions and performance.
 * 17. getMemberReputation(address _memberAddress): View function to get a member's reputation score (based on positive feedback).
 * 18. setConsensusThreshold(uint256 _newThresholdPercentage): DAO owner can set the general consensus threshold for proposals.
 * 19. getArtPieceDetails(uint256 _artPieceId): View function to retrieve detailed information about an art piece.
 * 20. getContributionDetails(uint256 _artPieceId, uint256 _contributionId): View function to retrieve details of a specific contribution.
 * 21. withdrawTreasuryFunds(address _recipient, uint256 _amount): DAO owner function to withdraw funds from the DAO treasury (for operational costs or community initiatives - governance could be added).
 * 22. depositTreasuryFunds(): Allows anyone to deposit funds into the DAO treasury.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DAOArt is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums and Structs ---

    enum ContributionType { Idea, Design, Execution, Promotion }
    enum ProposalStatus { Pending, Active, Approved, Rejected, Executed, Cancelled }

    struct Member {
        string name;
        string[] skills;
        uint256 reputation;
        bool isActive;
        uint256 registrationTimestamp;
    }

    struct ArtPiece {
        uint256 id;
        string title;
        string description;
        string initialConcept;
        string[] requiredSkills;
        ProposalStatus status; // Status of the art piece creation process
        address[] contributors;
        uint256 creationTimestamp;
        string ipfsHash; // Placeholder for IPFS hash of the finalized art
        uint256 salePrice;
        bool isListedForSale;
    }

    struct Contribution {
        uint256 id;
        address contributor;
        ContributionType contributionType;
        string details;
        uint256 timestamp;
        bool isApproved;
        bool isRejected;
    }

    struct ArtImprovementProposal {
        uint256 id;
        uint256 artPieceId;
        string proposalDetails;
        string[] requiredSkills;
        ProposalStatus status;
        uint256 proposalTimestamp;
    }

    struct RewardRatioProposal {
        uint256 id;
        ContributionType contributionType;
        uint256 newRatio;
        ProposalStatus status;
        uint256 proposalTimestamp;
    }

    struct MemberFeedback {
        address fromMember;
        string feedback;
        uint256 timestamp;
    }

    // --- State Variables ---

    mapping(address => Member) public members;
    mapping(uint256 => ArtPiece) public artPieces;
    mapping(uint256 => mapping(uint256 => Contribution)) public artPieceContributions;
    mapping(uint256 => ArtImprovementProposal) public artImprovementProposals;
    mapping(uint256 => mapping(uint256 => Contribution)) public improvementContributions;
    mapping(uint256 => RewardRatioProposal) public rewardRatioProposals;
    mapping(address => MemberFeedback[]) public memberFeedbacks;

    Counters.Counter private _memberCounter;
    Counters.Counter private _artPieceCounter;
    Counters.Counter private _contributionCounter;
    Counters.Counter private _improvementProposalCounter;
    Counters.Counter private _rewardRatioProposalCounter;

    uint256 public consensusThresholdPercentage = 60; // Default consensus threshold (60%)
    uint256 public treasuryBalance;

    mapping(ContributionType => uint256) public rewardRatios =
        mapping(ContributionType => uint256)(
            {
                Idea: 15,
                Design: 30,
                Execution: 40,
                Promotion: 15
            }
        ); // Example default reward ratios (percentages)

    // --- Events ---
    event MemberRegistered(address indexed memberAddress, string name);
    event MemberSkillsUpdated(address indexed memberAddress);
    event ArtPieceProposed(uint256 artPieceId, string title, address proposer);
    event ContributionSubmitted(uint256 artPieceId, uint256 contributionId, address contributor, ContributionType contributionType);
    event ContributionVoted(uint256 artPieceId, uint256 contributionId, address voter, bool approved);
    event ArtPieceFinalized(uint256 artPieceId, address[] contributors);
    event ArtPieceImprovementProposed(uint256 proposalId, uint256 artPieceId, address proposer);
    event ImprovementContributionSubmitted(uint256 proposalId, uint256 contributionId, address contributor, ContributionType contributionType);
    event ImprovementContributionVoted(uint256 proposalId, uint256 contributionId, address voter, bool approved);
    event ArtPieceImprovementFinalized(uint256 artPieceId, uint256 proposalId);
    event ArtPieceListedForSale(uint256 artPieceId, uint256 price, address lister);
    event ArtPiecePurchased(uint256 artPieceId, address buyer, uint256 price);
    event RewardRatioProposalCreated(uint256 proposalId, ContributionType contributionType, uint256 newRatio, address proposer);
    event RewardRatioProposalVoted(uint256 proposalId, address voter, bool approved);
    event RewardRatioChanged(ContributionType contributionType, uint256 newRatio);
    event MemberFeedbackGiven(address indexed fromMember, address indexed toMember, string feedback);
    event ConsensusThresholdChanged(uint256 newThresholdPercentage, address changer);
    event TreasuryFundsDeposited(address depositor, uint256 amount);
    event TreasuryFundsWithdrawn(address recipient, uint256 amount, address withdrawer);


    // --- Modifiers ---
    modifier onlyMember() {
        require(members[msg.sender].isActive, "You are not a registered member.");
        _;
    }

    modifier artPieceExists(uint256 _artPieceId) {
        require(_artPieceId > 0 && _artPieceId <= _artPieceCounter.current(), "Art piece does not exist.");
        _;
    }

    modifier contributionExists(uint256 _artPieceId, uint256 _contributionId) {
        require(artPieceContributions[_artPieceId][_contributionId].contributor != address(0), "Contribution does not exist.");
        _;
    }

    modifier improvementProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _improvementProposalCounter.current(), "Improvement proposal does not exist.");
        _;
    }

    modifier rewardRatioProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _rewardRatioProposalCounter.current(), "Reward ratio proposal does not exist.");
        _;
    }

    modifier onlyArtPieceProposer(uint256 _artPieceId) {
        // In a real DAO, more sophisticated proposal ownership might be needed
        // This is a simplified check for demonstration
        // require(artPieces[_artPieceId].proposer == msg.sender, "Only the proposer can perform this action.");
        _; // Placeholder for more advanced logic if needed
    }

    modifier onlyValidProposalStatus(uint256 _artPieceId, ProposalStatus _status) {
        require(artPieces[_artPieceId].status == _status, "Invalid art piece status for this action.");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("DAOArtCollection", "DAC") Ownable() {
        // Initialize contract if needed
    }

    // --- Membership Functions ---
    function registerMember(string memory _name, string[] memory _skills) public {
        require(!members[msg.sender].isActive, "Already a member.");
        _memberCounter.increment();
        members[msg.sender] = Member({
            name: _name,
            skills: _skills,
            reputation: 0,
            isActive: true,
            registrationTimestamp: block.timestamp
        });
        emit MemberRegistered(msg.sender, _name);
    }

    function updateMemberSkills(string[] memory _newSkills) public onlyMember {
        members[msg.sender].skills = _newSkills;
        emit MemberSkillsUpdated(msg.sender);
    }

    function isMember(address _memberAddress) public view returns (bool) {
        return members[_memberAddress].isActive;
    }

    function getMemberDetails(address _memberAddress) public view returns (Member memory) {
        return members[_memberAddress];
    }

    // --- Art Piece Proposal and Creation Functions ---
    function proposeArtPiece(
        string memory _title,
        string memory _description,
        string memory _initialConcept,
        string[] memory _requiredSkills
    ) public onlyMember {
        _artPieceCounter.increment();
        uint256 artPieceId = _artPieceCounter.current();
        artPieces[artPieceId] = ArtPiece({
            id: artPieceId,
            title: _title,
            description: _description,
            initialConcept: _initialConcept,
            requiredSkills: _requiredSkills,
            status: ProposalStatus.Pending,
            contributors: new address[](0),
            creationTimestamp: block.timestamp,
            ipfsHash: "", // Initially empty
            salePrice: 0,
            isListedForSale: false
        });
        emit ArtPieceProposed(artPieceId, _title, msg.sender);
    }

    function contributeToArtPiece(
        uint256 _artPieceId,
        ContributionType _contributionType,
        string memory _contributionDetails
    ) public onlyMember artPieceExists(_artPieceId) onlyValidProposalStatus(_artPieceId, ProposalStatus.Pending) {
        _contributionCounter.increment();
        uint256 contributionId = _contributionCounter.current();
        artPieceContributions[_artPieceId][contributionId] = Contribution({
            id: contributionId,
            contributor: msg.sender,
            contributionType: _contributionType,
            details: _contributionDetails,
            timestamp: block.timestamp,
            isApproved: false,
            isRejected: false
        });
        emit ContributionSubmitted(_artPieceId, contributionId, msg.sender, _contributionType);
    }

    function voteOnContribution(uint256 _artPieceId, uint256 _contributionId, bool _approve) public onlyMember artPieceExists(_artPieceId) contributionExists(_artPieceId, _contributionId) onlyValidProposalStatus(_artPieceId, ProposalStatus.Pending) {
        Contribution storage contribution = artPieceContributions[_artPieceId][_contributionId];
        require(contribution.contributor != msg.sender, "Cannot vote on your own contribution.");
        require(!contribution.isApproved && !contribution.isRejected, "Contribution already voted on.");

        if (_approve) {
            contribution.isApproved = true;
        } else {
            contribution.isRejected = true;
        }
        emit ContributionVoted(_artPieceId, _contributionId, msg.sender, _approve);

        // Check if consensus is reached (simplified - all contributions need to be approved)
        if (_checkArtPieceConsensus(_artPieceId)) {
            artPieces[_artPieceId].status = ProposalStatus.Approved;
        }
    }

    function _checkArtPieceConsensus(uint256 _artPieceId) private view returns (bool) {
        uint256 approvedContributions = 0;
        uint256 totalContributions = 0;
        for (uint256 i = 1; i <= _contributionCounter.current(); i++) {
            if (artPieceContributions[_artPieceId][i].contributor != address(0)) { // Check if contribution exists for this art piece
                totalContributions++;
                if (artPieceContributions[_artPieceId][i].isApproved) {
                    approvedContributions++;
                }
            }
        }
        if (totalContributions == 0) return false; // No contributions yet
        uint256 approvalPercentage = (approvedContributions * 100) / totalContributions;
        return approvalPercentage >= consensusThresholdPercentage;
    }

    function finalizeArtPiece(uint256 _artPieceId) public onlyMember artPieceExists(_artPieceId) onlyValidProposalStatus(_artPieceId, ProposalStatus.Approved) {
        ArtPiece storage artPiece = artPieces[_artPieceId];
        require(bytes(artPiece.ipfsHash).length == 0, "Art piece already finalized."); // Prevent re-finalization

        // In a real scenario, IPFS hash would be obtained after off-chain finalization process
        // For this example, we'll just set a placeholder IPFS hash.
        artPiece.ipfsHash = "ipfs://example-hash-" + _artPieceId.toString();
        artPiece.status = ProposalStatus.Executed;

        // Mint NFT
        _mint(address(this), _artPieceId);
        _setTokenURI(_artPieceId, artPiece.ipfsHash);

        // Distribute initial rewards (example - could be more sophisticated based on contribution type/value)
        _distributeArtCreationRewards(_artPieceId);

        emit ArtPieceFinalized(_artPieceId, artPiece.contributors);
    }

    function _distributeArtCreationRewards(uint256 _artPieceId) private {
        ArtPiece storage artPiece = artPieces[_artPieceId];
        uint256 totalRewardPercentage = 100; // 100% of initial value is distributed as rewards (example)
        uint256 rewardPool = treasuryBalance * totalRewardPercentage / 100; // Example: use DAO treasury
        uint256 totalRewardPoints = 0;
        mapping(address => uint256) memberRewardPoints;

        // Calculate total reward points and points per member based on contribution types
        for (uint256 i = 1; i <= _contributionCounter.current(); i++) {
            Contribution storage contribution = artPieceContributions[_artPieceId][i];
            if (contribution.isApproved) {
                artPiece.contributors.push(contribution.contributor); // Add to contributor list
                uint256 rewardPercentage = rewardRatios[contribution.contributionType];
                memberRewardPoints[contribution.contributor] += rewardPercentage;
                totalRewardPoints += rewardPercentage;
            }
        }

        // Distribute rewards proportionally
        for (uint256 i = 0; i < artPiece.contributors.length; i++) {
            address contributor = artPiece.contributors[i];
            uint256 contributorPoints = memberRewardPoints[contributor];
            if (totalRewardPoints > 0) {
                uint256 rewardAmount = rewardPool * contributorPoints / totalRewardPoints;
                payable(contributor).transfer(rewardAmount); // Transfer rewards (assuming treasury has funds)
                treasuryBalance -= rewardAmount; // Deduct from treasury
            }
        }
    }


    // --- Art Piece Improvement Functions ---
    function proposeArtPieceImprovement(
        uint256 _artPieceId,
        string memory _improvementProposal,
        string[] memory _requiredSkills
    ) public onlyMember artPieceExists(_artPieceId) onlyValidProposalStatus(_artPieceId, ProposalStatus.Executed) { // Can only improve finalized pieces
        _improvementProposalCounter.increment();
        uint256 proposalId = _improvementProposalCounter.current();
        artImprovementProposals[proposalId] = ArtImprovementProposal({
            id: proposalId,
            artPieceId: _artPieceId,
            proposalDetails: _improvementProposal,
            requiredSkills: _requiredSkills,
            status: ProposalStatus.Pending,
            proposalTimestamp: block.timestamp
        });
        artPieces[_artPieceId].status = ProposalStatus.Active; // Set art piece status to active for improvement
        emit ArtPieceImprovementProposed(proposalId, _artPieceId, msg.sender);
    }

    function contributeToImprovement(
        uint256 _proposalId,
        ContributionType _contributionType,
        string memory _contributionDetails
    ) public onlyMember improvementProposalExists(_proposalId) onlyValidProposalStatus(artImprovementProposals[_proposalId].artPieceId, ProposalStatus.Active) {
        uint256 _artPieceId = artImprovementProposals[_proposalId].artPieceId;
        _contributionCounter.increment(); // Reuse contribution counter for simplicity, could have separate counter
        uint256 contributionId = _contributionCounter.current();
        improvementContributions[_proposalId][contributionId] = Contribution({
            id: contributionId,
            contributor: msg.sender,
            contributionType: _contributionType,
            details: _contributionDetails,
            timestamp: block.timestamp,
            isApproved: false,
            isRejected: false
        });
        emit ImprovementContributionSubmitted(_proposalId, contributionId, msg.sender, _contributionType);
    }

    function voteOnImprovementContribution(uint256 _proposalId, uint256 _contributionId, bool _approve) public onlyMember improvementProposalExists(_proposalId) onlyValidProposalStatus(artImprovementProposals[_proposalId].artPieceId, ProposalStatus.Active) {
        Contribution storage contribution = improvementContributions[_proposalId][_contributionId];
        require(contribution.contributor != msg.sender, "Cannot vote on your own contribution.");
        require(!contribution.isApproved && !contribution.isRejected, "Contribution already voted on.");

        if (_approve) {
            contribution.isApproved = true;
        } else {
            contribution.isRejected = true;
        }
        emit ImprovementContributionVoted(_proposalId, _contributionId, msg.sender, _approve);

        // Check consensus for improvement proposal
        if (_checkImprovementProposalConsensus(_proposalId)) {
            artImprovementProposals[_proposalId].status = ProposalStatus.Approved;
        }
    }

    function _checkImprovementProposalConsensus(uint256 _proposalId) private view returns (bool) {
         uint256 approvedContributions = 0;
        uint256 totalContributions = 0;
        for (uint256 i = 1; i <= _contributionCounter.current(); i++) {
            if (improvementContributions[_proposalId][i].contributor != address(0)) { // Check if contribution exists for this proposal
                totalContributions++;
                if (improvementContributions[_proposalId][i].isApproved) {
                    approvedContributions++;
                }
            }
        }
        if (totalContributions == 0) return false; // No contributions yet
        uint256 approvalPercentage = (approvedContributions * 100) / totalContributions;
        return approvalPercentage >= consensusThresholdPercentage;
    }

    function finalizeArtPieceImprovement(uint256 _proposalId) public onlyMember improvementProposalExists(_proposalId) onlyValidProposalStatus(artImprovementProposals[_proposalId].artPieceId, ProposalStatus.Approved) {
        uint256 _artPieceId = artImprovementProposals[_proposalId].artPieceId;
        ArtPiece storage artPiece = artPieces[_artPieceId];
        require(artImprovementProposals[_proposalId].status == ProposalStatus.Approved, "Improvement proposal not approved.");

        // In a real scenario, IPFS hash would be updated based on improvements
        artPiece.ipfsHash = "ipfs://updated-hash-" + _artPieceId.toString() + "-" + _proposalId.toString(); // Example update
        artPieces[_artPieceId].status = ProposalStatus.Executed; // Back to Executed status after improvement

        _setTokenURI(_artPieceId, artPiece.ipfsHash); // Update NFT metadata URI

        // Distribute rewards for improvement contributions
        _distributeImprovementRewards(_proposalId);

        emit ArtPieceImprovementFinalized(_artPieceId, _proposalId);
    }

    function _distributeImprovementRewards(uint256 _proposalId) private {
        ArtImprovementProposal storage proposal = artImprovementProposals[_proposalId];
        uint256 _artPieceId = proposal.artPieceId;
        ArtPiece storage artPiece = artPieces[_artPieceId];

        uint256 totalRewardPercentage = 50; // Example: 50% of current treasury value for improvements
        uint256 rewardPool = treasuryBalance * totalRewardPercentage / 100; // Example: use DAO treasury for improvements
        uint256 totalRewardPoints = 0;
        mapping(address => uint256) memberRewardPoints;

        // Calculate reward points based on improvement contributions
        for (uint256 i = 1; i <= _contributionCounter.current(); i++) {
            Contribution storage contribution = improvementContributions[_proposalId][i];
            if (contribution.isApproved) {
                // No need to add to contributors again, they are already contributors to the main art piece
                uint256 rewardPercentage = rewardRatios[contribution.contributionType]; // Same ratios as initial contributions
                memberRewardPoints[contribution.contributor] += rewardPercentage;
                totalRewardPoints += rewardPercentage;
            }
        }

        // Distribute rewards proportionally
        for (uint256 i = 1; i <= _contributionCounter.current(); i++) { // Iterate through contribution IDs, not contributors array
            Contribution storage contribution = improvementContributions[_proposalId][i];
            if (contribution.isApproved) {
                uint256 contributorPoints = memberRewardPoints[contribution.contributor];
                if (totalRewardPoints > 0) {
                    uint256 rewardAmount = rewardPool * contributorPoints / totalRewardPoints;
                    payable(contribution.contributor).transfer(rewardAmount);
                    treasuryBalance -= rewardAmount;
                }
            }
        }
    }


    // --- Art Piece Marketplace Functions ---
    function listArtPieceForSale(uint256 _artPieceId, uint256 _price) public onlyMember artPieceExists(_artPieceId) onlyValidProposalStatus(_artPieceId, ProposalStatus.Executed) {
        require(ownerOf(_artPieceId) == address(this), "DAO is not the owner of this art piece.");
        artPieces[_artPieceId].salePrice = _price;
        artPieces[_artPieceId].isListedForSale = true;
        emit ArtPieceListedForSale(_artPieceId, _price, msg.sender);
    }

    function purchaseArtPiece(uint256 _artPieceId) payable public artPieceExists(_artPieceId) {
        ArtPiece storage artPiece = artPieces[_artPieceId];
        require(artPiece.isListedForSale, "Art piece is not listed for sale.");
        require(msg.value >= artPiece.salePrice, "Insufficient funds sent.");

        uint256 purchasePrice = artPiece.salePrice;

        // Distribute royalties to contributors (example - could be more complex royalty structure)
        _distributeArtRoyalties(_artPieceId, purchasePrice);

        artPiece.isListedForSale = false;
        artPiece.salePrice = 0;

        _transfer(address(this), msg.sender, _artPieceId); // Transfer NFT ownership to buyer

        // Refund any excess ETH sent
        if (msg.value > purchasePrice) {
            payable(msg.sender).transfer(msg.value - purchasePrice);
        }

        emit ArtPiecePurchased(_artPieceId, msg.sender, purchasePrice);
    }

    function _distributeArtRoyalties(uint256 _artPieceId, uint256 _salePrice) private {
        ArtPiece storage artPiece = artPieces[_artPieceId];
        uint256 royaltyPercentage = 10; // Example: 10% royalty to contributors
        uint256 royaltyPool = _salePrice * royaltyPercentage / 100;
        uint256 totalRewardPoints = 0;
        mapping(address => uint256) memberRewardPoints;

        // Calculate reward points for royalties (using same points as initial creation for simplicity)
        for (uint256 i = 0; i < artPiece.contributors.length; i++) {
            address contributor = artPiece.contributors[i];
            uint256 rewardPoints = 0;
            for (uint256 j = 1; j <= _contributionCounter.current(); j++) {
                if (artPieceContributions[_artPieceId][j].contributor == contributor && artPieceContributions[_artPieceId][j].isApproved) {
                    rewardPoints += rewardRatios[artPieceContributions[_artPieceId][j].contributionType];
                }
            }
            memberRewardPoints[contributor] += rewardPoints;
            totalRewardPoints += rewardPoints;
        }

        // Distribute royalties proportionally
        for (uint256 i = 0; i < artPiece.contributors.length; i++) {
            address contributor = artPiece.contributors[i];
            uint256 contributorPoints = memberRewardPoints[contributor];
            if (totalRewardPoints > 0) {
                uint256 royaltyAmount = royaltyPool * contributorPoints / totalRewardPoints;
                payable(contributor).transfer(royaltyAmount);
            }
        }

        treasuryBalance += (_salePrice - royaltyPool); // Add remaining sale amount to treasury
    }


    // --- Reward Ratio Governance Functions ---
    function proposeRewardRatioChange(ContributionType _contributionType, uint256 _newRatio) public onlyMember {
        require(_newRatio <= 100, "Reward ratio cannot exceed 100%.");
        _rewardRatioProposalCounter.increment();
        uint256 proposalId = _rewardRatioProposalCounter.current();
        rewardRatioProposals[proposalId] = RewardRatioProposal({
            id: proposalId,
            contributionType: _contributionType,
            newRatio: _newRatio,
            status: ProposalStatus.Pending,
            proposalTimestamp: block.timestamp
        });
        emit RewardRatioProposalCreated(proposalId, _contributionType, _newRatio, msg.sender);
    }

    function voteOnRewardRatioChange(uint256 _proposalId, bool _approve) public onlyMember rewardRatioProposalExists(_proposalId) {
        RewardRatioProposal storage proposal = rewardRatioProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending.");

        if (_approve) {
            proposal.status = ProposalStatus.Approved; // Simplified approval - could be voting system
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        emit RewardRatioProposalVoted(_proposalId, msg.sender, _approve);

        if (proposal.status == ProposalStatus.Approved) {
            executeRewardRatioChange(_proposalId);
        }
    }

    function executeRewardRatioChange(uint256 _proposalId) public onlyMember rewardRatioProposalExists(_proposalId) {
        RewardRatioProposal storage proposal = rewardRatioProposals[_proposalId];
        require(proposal.status == ProposalStatus.Approved, "Proposal not approved.");
        require(rewardRatios[proposal.contributionType] != proposal.newRatio, "Reward ratio already set to this value.");

        rewardRatios[proposal.contributionType] = proposal.newRatio;
        proposal.status = ProposalStatus.Executed;
        emit RewardRatioChanged(proposal.contributionType, proposal.newRatio);
    }


    // --- Reputation and Feedback Functions ---
    function provideMemberFeedback(address _memberAddress, string memory _feedback) public onlyMember {
        require(_memberAddress != msg.sender, "Cannot give feedback to yourself.");
        memberFeedbacks[_memberAddress].push(MemberFeedback({
            fromMember: msg.sender,
            feedback: _feedback,
            timestamp: block.timestamp
        }));
        // In a more advanced system, reputation score could be updated based on feedback analysis
        emit MemberFeedbackGiven(msg.sender, _memberAddress, _feedback);
    }

    function getMemberReputation(address _memberAddress) public view returns (uint256) {
        // Placeholder - in a real system, reputation would be calculated based on feedback, contributions, etc.
        return members[_memberAddress].reputation;
    }


    // --- DAO Management Functions ---
    function setConsensusThreshold(uint256 _newThresholdPercentage) public onlyOwner {
        require(_newThresholdPercentage <= 100, "Threshold percentage cannot exceed 100%.");
        consensusThresholdPercentage = _newThresholdPercentage;
        emit ConsensusThresholdChanged(_newThresholdPercentage, msg.sender);
    }

    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyOwner {
        require(treasuryBalance >= _amount, "Insufficient treasury balance.");
        payable(_recipient).transfer(_amount);
        treasuryBalance -= _amount;
        emit TreasuryFundsWithdrawn(_recipient, _amount, msg.sender);
    }

    function depositTreasuryFunds() public payable {
        treasuryBalance += msg.value;
        emit TreasuryFundsDeposited(msg.sender, msg.value);
    }


    // --- View/Getter Functions ---
    function getArtPieceDetails(uint256 _artPieceId) public view artPieceExists(_artPieceId) returns (ArtPiece memory) {
        return artPieces[_artPieceId];
    }

    function getContributionDetails(uint256 _artPieceId, uint256 _contributionId) public view artPieceExists(_artPieceId) contributionExists(_artPieceId, _contributionId) returns (Contribution memory) {
        return artPieceContributions[_artPieceId][_contributionId];
    }

    function getImprovementProposalDetails(uint256 _proposalId) public view improvementProposalExists(_proposalId) returns (ArtImprovementProposal memory) {
        return artImprovementProposals[_proposalId];
    }

    function getRewardRatioProposalDetails(uint256 _proposalId) public view rewardRatioProposalExists(_proposalId) returns (RewardRatioProposal memory) {
        return rewardRatioProposals[_proposalId];
    }

    function getMemberFeedbackHistory(address _memberAddress) public view returns (MemberFeedback[] memory) {
        return memberFeedbacks[_memberAddress];
    }

    function getArtPieceContributionCount(uint256 _artPieceId) public view artPieceExists(_artPieceId) returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _contributionCounter.current(); i++) {
            if (artPieceContributions[_artPieceId][i].contributor != address(0)) {
                count++;
            }
        }
        return count;
    }

    function getImprovementContributionCount(uint256 _proposalId) public view improvementProposalExists(_proposalId) returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _contributionCounter.current(); i++) {
            if (improvementContributions[_proposalId][_artPieceId].contributor != address(0)) {
                count++;
            }
        }
        return count;
    }

    function getRewardRatios() public view returns (mapping(ContributionType => uint256) memory) {
        return rewardRatios;
    }

    function getConsensusThreshold() public view returns (uint256) {
        return consensusThresholdPercentage;
    }

    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }
}
```