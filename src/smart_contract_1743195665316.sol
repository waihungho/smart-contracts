```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI (Conceptual Smart Contract - Not for Production)
 * @notice This smart contract implements a Decentralized Autonomous Art Collective (DAAC)
 *         with advanced features for collaborative art creation, curation, and governance.
 *         It includes functionalities for generative art, dynamic NFTs, fractional ownership,
 *         artist reputation, decentralized exhibitions, and more.
 *
 * Function Summary:
 *
 * --- Core DAO & Membership ---
 * 1. joinCollective(string _artistStatement): Allows artists to request membership, submitting a statement.
 * 2. approveArtist(address _artist): DAO governance function to approve pending artist applications.
 * 3. leaveCollective(): Allows members to leave the collective, potentially with conditions.
 * 4. getMemberDetails(address _member): Retrieves details about a collective member.
 * 5. getCollectiveSize(): Returns the current number of members in the collective.
 *
 * --- Collaborative Art Creation & Generative Art ---
 * 6. proposeCollaborativeArt(string _title, string _description, string[] memory _collaborators): Proposes a new collaborative art project.
 * 7. voteOnArtProposal(uint _proposalId, bool _vote): Members vote on proposed collaborative art projects.
 * 8. contributeToArtProject(uint _proposalId, string memory _contributionData): Members contribute data or elements to an approved art project.
 * 9. generateArtNFT(uint _proposalId): Generates an NFT representing the completed collaborative art project. (Generative element within contract or integration with external service).
 * 10. setGenerativeArtParameters(uint _proposalId, string memory _parameters): Allows setting parameters for generative art projects.
 *
 * --- Dynamic NFTs & Art Evolution ---
 * 11. evolveArtNFT(uint _nftId, string memory _evolutionData): Allows for the evolution or update of an existing Art NFT based on collective decisions or external factors.
 * 12. proposeNFTEvolution(uint _nftId, string memory _evolutionDataProposal):  Proposes an evolution for a specific Art NFT, requiring DAO vote.
 * 13. voteOnNFTEvolution(uint _evolutionProposalId, bool _vote): Members vote on NFT evolution proposals.
 * 14. finalizeNFTEvolution(uint _evolutionProposalId): Executes approved NFT evolution proposals.
 *
 * --- Art Curation & Exhibition ---
 * 15. submitArtForCuration(string _artMetadata): Members submit their individual art for collective curation.
 * 16. proposeExhibition(uint[] memory _artIds, string _exhibitionTitle, string _exhibitionMetadata): Proposes a decentralized exhibition of curated art.
 * 17. voteOnExhibitionProposal(uint _exhibitionProposalId, bool _vote): Members vote on proposed exhibitions.
 * 18. startExhibition(uint _exhibitionProposalId): Starts an approved decentralized art exhibition (potentially integrating with a virtual gallery or platform - conceptual).
 *
 * --- Reputation & Fractionalization ---
 * 19. rateArtistContribution(address _artist, uint _rating): Allows members to rate contributions of other artists, building a reputation system.
 * 20. fractionalizeArtNFT(uint _nftId, uint _numberOfFractions): Allows fractionalizing an Art NFT, creating ERC1155 fractional tokens.
 * 21. redeemArtFraction(uint _fractionalTokenId): Allows holders of fractional tokens to redeem a share of the underlying Art NFT (complex logic, potentially governance based).
 *
 * --- DAO Governance & Treasury ---
 * 22. proposeRuleChange(string _ruleProposal): Allows members to propose changes to the DAAC rules or parameters.
 * 23. voteOnRuleChange(uint _ruleProposalId, bool _vote): Members vote on proposed rule changes.
 * 24. executeRuleChange(uint _ruleProposalId): Executes approved rule changes.
 * 25. getTreasuryBalance(): Returns the current balance of the DAAC treasury.
 * 26. proposeTreasurySpending(string _spendingProposal, uint _amount): Proposes spending from the DAAC treasury for collective initiatives.
 * 27. voteOnTreasurySpending(uint _treasuryProposalId, bool _vote): Members vote on treasury spending proposals.
 * 28. executeTreasurySpending(uint _treasuryProposalId): Executes approved treasury spending proposals.
 */

contract DecentralizedAutonomousArtCollective {
    // --- State Variables ---

    // Core DAO & Membership
    address public owner; // Contract owner (initial DAO admin - can be replaced by governance)
    mapping(address => Member) public members;
    address[] public memberList;
    uint public memberCount;
    mapping(address => string) public pendingArtistApplications;
    address[] public pendingArtists;

    struct Member {
        address memberAddress;
        string artistStatement;
        uint reputationScore;
        bool isActive;
        uint joinTimestamp;
    }

    // Collaborative Art & Generative Art
    uint public nextArtProposalId;
    mapping(uint => ArtProposal) public artProposals;
    struct ArtProposal {
        uint proposalId;
        string title;
        string description;
        address[] collaborators;
        Contribution[] contributions;
        string generativeParameters; // Parameters for generative art (JSON string or similar)
        bool isActive;
        bool isApproved;
        uint voteEndTime;
        uint yesVotes;
        uint noVotes;
    }

    struct Contribution {
        address contributor;
        string contributionData; // Data contributed by a member
        uint timestamp;
    }

    // Dynamic NFTs & Art Evolution
    uint public nextNFTEvolutionProposalId;
    mapping(uint => NFTEvolutionProposal) public nftEvolutionProposals;
    struct NFTEvolutionProposal {
        uint proposalId;
        uint nftId;
        string evolutionDataProposal;
        bool isActive;
        bool isApproved;
        uint voteEndTime;
        uint yesVotes;
        uint noVotes;
    }

    // Art NFTs (Conceptual - in a real implementation, would likely integrate with an ERC721 contract)
    uint public nextArtNFTId;
    mapping(uint => ArtNFT) public artNFTs;
    struct ArtNFT {
        uint nftId;
        string metadataURI; // URI pointing to NFT metadata (IPFS or similar)
        address creator; // Initially the DAAC contract, but could evolve to individual artists or collaborators
        uint creationTimestamp;
        uint[] evolutionHistory; // Array of evolution proposal IDs that have affected this NFT
    }

    // Art Curation & Exhibition
    uint public nextCurationSubmissionId;
    mapping(uint => CurationSubmission) public curationSubmissions;
    struct CurationSubmission {
        uint submissionId;
        address artist;
        string artMetadata; // Metadata for submitted art
        bool isCurated;
        uint curationTimestamp;
    }

    uint public nextExhibitionProposalId;
    mapping(uint => ExhibitionProposal) public exhibitionProposals;
    struct ExhibitionProposal {
        uint proposalId;
        string title;
        string exhibitionMetadata;
        uint[] artNFTIds;
        bool isActive;
        bool isApproved;
        uint voteEndTime;
        uint yesVotes;
        uint noVotes;
        uint startTime;
    }

    // Reputation System
    mapping(address => mapping(address => uint)) public artistRatings; // Rater => Ratee => Rating

    // Fractionalization (Conceptual - ERC1155 integration needed for real implementation)
    mapping(uint => bool) public isFractionalizedNFT; // nftId => isFractionalized
    // Would need ERC1155 contract and logic for fractional tokens and redemption in a real implementation

    // DAO Governance & Treasury
    uint public nextRuleProposalId;
    mapping(uint => RuleProposal) public ruleProposals;
    struct RuleProposal {
        uint proposalId;
        string ruleProposal;
        bool isActive;
        bool isApproved;
        uint voteEndTime;
        uint yesVotes;
        uint noVotes;
    }

    uint public nextTreasuryProposalId;
    mapping(uint => TreasuryProposal) public treasuryProposals;
    struct TreasuryProposal {
        uint proposalId;
        string spendingProposal;
        uint amount;
        bool isActive;
        bool isApproved;
        uint voteEndTime;
        uint yesVotes;
        uint noVotes;
    }

    uint public treasuryBalance; // Simple treasury balance (in real impl, would be more robust)

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only active members can call this function.");
        _;
    }

    modifier validProposal(uint _proposalId, mapping(uint => ProposalBase) storage proposalMapping) {
        ProposalBase storage proposal = proposalMapping[_proposalId];
        require(proposal.isActive, "Proposal is not active.");
        require(block.timestamp < proposal.voteEndTime, "Voting period has ended.");
        _;
    }

    struct ProposalBase { // Base struct for common proposal fields
        uint proposalId;
        bool isActive;
        bool isApproved;
        uint voteEndTime;
        uint yesVotes;
        uint noVotes;
    }


    // --- Events ---
    event MemberJoined(address memberAddress);
    event ArtistApproved(address artistAddress);
    event MemberLeft(address memberAddress);
    event CollaborativeArtProposed(uint proposalId, string title, address[] collaborators);
    event ArtProposalVoted(uint proposalId, address voter, bool vote);
    event ArtProjectContribution(uint proposalId, address contributor, string contributionData);
    event ArtNFTGenerated(uint nftId, uint proposalId, string metadataURI);
    event GenerativeArtParametersSet(uint proposalId, string parameters);
    event NFTEvolutionProposed(uint proposalId, uint nftId, string evolutionDataProposal);
    event NFTEvolutionVoted(uint proposalId, address voter, bool vote);
    event NFTEvolutionFinalized(uint nftId, uint proposalId, string evolutionData);
    event ArtSubmittedForCuration(uint submissionId, address artist, string artMetadata);
    event ExhibitionProposed(uint proposalId, string title, uint[] artNFTIds);
    event ExhibitionVoted(uint proposalId, address voter, bool vote);
    event ExhibitionStarted(uint proposalId, uint startTime);
    event ArtistRated(address rater, address ratee, uint rating);
    event ArtNFTFractionalized(uint nftId, uint numberOfFractions);
    event RuleChangeProposed(uint proposalId, string ruleProposal);
    event RuleChangeVoted(uint proposalId, address voter, bool vote);
    event RuleChangeExecuted(uint proposalId, string ruleProposal);
    event TreasurySpendingProposed(uint proposalId, string spendingProposal, uint amount);
    event TreasurySpendingVoted(uint proposalId, address voter, bool vote);
    event TreasurySpendingExecuted(uint proposalId, uint amount);
    event TreasuryDeposit(address sender, uint amount);


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Core DAO & Membership Functions ---

    function joinCollective(string memory _artistStatement) public {
        require(pendingArtistApplications[msg.sender].length == 0 && !members[msg.sender].isActive, "Application already pending or already a member.");
        pendingArtistApplications[msg.sender] = _artistStatement;
        pendingArtists.push(msg.sender);
    }

    function approveArtist(address _artist) public onlyOwner { // In real DAO, this would be governed by member voting
        require(pendingArtistApplications[_artist].length > 0 && !members[_artist].isActive, "No pending application or already a member.");
        members[_artist] = Member({
            memberAddress: _artist,
            artistStatement: pendingArtistApplications[_artist],
            reputationScore: 0,
            isActive: true,
            joinTimestamp: block.timestamp
        });
        memberList.push(_artist);
        memberCount++;
        delete pendingArtistApplications[_artist];
        // Remove from pendingArtists array (inefficient, better to use mapping and mark as approved) - simplified for example
        for (uint i = 0; i < pendingArtists.length; i++) {
            if (pendingArtists[i] == _artist) {
                pendingArtists[i] = pendingArtists[pendingArtists.length - 1];
                pendingArtists.pop();
                break;
            }
        }
        emit ArtistApproved(_artist);
        emit MemberJoined(_artist);
    }

    function leaveCollective() public onlyMember {
        members[msg.sender].isActive = false;
        memberCount--;
        // Remove from memberList (inefficient, better to manage active members in a mapping) - simplified for example
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MemberLeft(msg.sender);
    }

    function getMemberDetails(address _member) public view returns (Member memory) {
        return members[_member];
    }

    function getCollectiveSize() public view returns (uint) {
        return memberCount;
    }

    // --- Collaborative Art Creation & Generative Art Functions ---

    function proposeCollaborativeArt(string memory _title, string memory _description, string[] memory _collaborators) public onlyMember {
        require(_collaborators.length > 0, "At least one collaborator required.");
        ArtProposal storage proposal = artProposals[nextArtProposalId];
        proposal.proposalId = nextArtProposalId;
        proposal.title = _title;
        proposal.description = _description;
        proposal.collaborators = _collaborators;
        proposal.isActive = true;
        proposal.isApproved = false;
        proposal.voteEndTime = block.timestamp + 7 days; // Example voting period
        nextArtProposalId++;
        emit CollaborativeArtProposed(proposal.proposalId, _title, _collaborators);
    }

    function voteOnArtProposal(uint _proposalId, bool _vote) public onlyMember validProposal(_proposalId, artProposals) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(!proposal.isApproved, "Proposal already finalized.");
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    function contributeToArtProject(uint _proposalId, string memory _contributionData) public onlyMember {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.isActive && proposal.isApproved, "Project is not active or not approved.");
        bool isCollaborator = false;
        for (uint i = 0; i < proposal.collaborators.length; i++) {
            if (proposal.collaborators[i] == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(isCollaborator, "Only designated collaborators can contribute.");
        proposal.contributions.push(Contribution({
            contributor: msg.sender,
            contributionData: _contributionData,
            timestamp: block.timestamp
        }));
        emit ArtProjectContribution(_proposalId, msg.sender, _contributionData);
    }

    function generateArtNFT(uint _proposalId) public onlyMember {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.isActive && proposal.isApproved && block.timestamp > proposal.voteEndTime, "Proposal not finalized or voting not ended.");
        require(!artNFTs[nextArtNFTId].metadataURI.length > 0 , "NFT already generated for this proposal."); // Simple check to prevent double minting

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.isApproved = true; // Finalize approval after voting period
            ArtNFT storage newNFT = artNFTs[nextArtNFTId];
            newNFT.nftId = nextArtNFTId;
            newNFT.creator = address(this); // DAAC contract is the initial creator
            newNFT.creationTimestamp = block.timestamp;

            // --- Generative Art Logic (Conceptual & Simplified) ---
            string memory metadata = _generateArtMetadata(_proposalId); // Call internal function for generative metadata
            newNFT.metadataURI = metadata; // In real impl, would upload to IPFS and get URI

            nextArtNFTId++;
            proposal.isActive = false; // Mark proposal as completed
            emit ArtNFTGenerated(newNFT.nftId, _proposalId, metadata);
        } else {
            proposal.isActive = false; // Proposal failed
        }
    }

    function setGenerativeArtParameters(uint _proposalId, string memory _parameters) public onlyMember {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.isActive && !proposal.isApproved, "Proposal not active or already finalized.");
        // In a real DAO, this parameter setting might be governed by a vote or specific roles
        proposal.generativeParameters = _parameters;
        emit GenerativeArtParametersSet(_proposalId, _parameters);
    }

    function _generateArtMetadata(uint _proposalId) internal view returns (string memory) {
        ArtProposal storage proposal = artProposals[_proposalId];
        // --- Very Simplified Generative Metadata Example ---
        // In a real implementation, this would be much more complex, potentially calling external services or using libraries.
        string memory baseMetadata = '{"name": "Collaborative Art #';
        string memory idStr = Strings.toString(_proposalId);
        string memory titlePart = '", "description": "';
        string memory descriptionPart = proposal.description;
        string memory parametersPart = '", "generativeParameters": ';
        string memory params = proposal.generativeParameters;
        string memory endMetadata = '}';

        return string(abi.encodePacked(baseMetadata, idStr, titlePart, descriptionPart, parametersPart, params, endMetadata));
    }


    // --- Dynamic NFTs & Art Evolution Functions ---

    function evolveArtNFT(uint _nftId, string memory _evolutionData) public onlyMember {
        require(artNFTs[_nftId].metadataURI.length > 0, "NFT does not exist.");
        // --- Dynamic NFT Logic (Conceptual & Simplified) ---
        // In a real implementation, this would involve updating the NFT metadata, potentially on IPFS,
        // and reflecting the evolution on a visual representation of the NFT.
        artNFTs[_nftId].metadataURI = string(abi.encodePacked(artNFTs[_nftId].metadataURI, " - Evolved: ", _evolutionData));
        // In a real system, you would need to handle metadata updates more robustly and potentially emit events for changes
        emit NFTEvolutionFinalized(_nftId, 0, _evolutionData); // Using 0 as proposal ID since direct evolution, not proposal based in this example (could be changed)
    }

    function proposeNFTEvolution(uint _nftId, string memory _evolutionDataProposal) public onlyMember {
        require(artNFTs[_nftId].metadataURI.length > 0, "NFT does not exist.");
        NFTEvolutionProposal storage proposal = nftEvolutionProposals[nextNFTEvolutionProposalId];
        proposal.proposalId = nextNFTEvolutionProposalId;
        proposal.nftId = _nftId;
        proposal.evolutionDataProposal = _evolutionDataProposal;
        proposal.isActive = true;
        proposal.isApproved = false;
        proposal.voteEndTime = block.timestamp + 5 days; // Example evolution voting period
        nextNFTEvolutionProposalId++;
        emit NFTEvolutionProposed(proposal.proposalId, _nftId, _evolutionDataProposal);
    }

    function voteOnNFTEvolution(uint _evolutionProposalId, bool _vote) public onlyMember validProposal(_evolutionProposalId, nftEvolutionProposals) {
        NFTEvolutionProposal storage proposal = nftEvolutionProposals[_evolutionProposalId];
        require(!proposal.isApproved, "Evolution proposal already finalized.");
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit NFTEvolutionVoted(_evolutionProposalId, msg.sender, _vote);
    }

    function finalizeNFTEvolution(uint _evolutionProposalId) public onlyMember {
        NFTEvolutionProposal storage proposal = nftEvolutionProposals[_evolutionProposalId];
        require(proposal.isActive && block.timestamp > proposal.voteEndTime, "Evolution proposal not active or voting not ended.");

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.isApproved = true;
            evolveArtNFT(proposal.nftId, proposal.evolutionDataProposal); // Apply evolution if approved
            artNFTs[proposal.nftId].evolutionHistory.push(_evolutionProposalId); // Record evolution history
            proposal.isActive = false; // Mark proposal as completed
        } else {
            proposal.isActive = false; // Proposal failed
        }
    }


    // --- Art Curation & Exhibition Functions ---

    function submitArtForCuration(string memory _artMetadata) public onlyMember {
        CurationSubmission storage submission = curationSubmissions[nextCurationSubmissionId];
        submission.submissionId = nextCurationSubmissionId;
        submission.artist = msg.sender;
        submission.artMetadata = _artMetadata;
        submission.isCurated = false;
        submission.curationTimestamp = block.timestamp;
        nextCurationSubmissionId++;
        emit ArtSubmittedForCuration(submission.submissionId, msg.sender, _artMetadata);
        // In a real DAO, curation would involve member voting or a curation committee
    }

    function proposeExhibition(uint[] memory _artNFTIds, string memory _exhibitionTitle, string memory _exhibitionMetadata) public onlyMember {
        require(_artNFTIds.length > 0, "At least one NFT required for exhibition.");
        ExhibitionProposal storage proposal = exhibitionProposals[nextExhibitionProposalId];
        proposal.proposalId = nextExhibitionProposalId;
        proposal.title = _exhibitionTitle;
        proposal.exhibitionMetadata = _exhibitionMetadata;
        proposal.artNFTIds = _artNFTIds;
        proposal.isActive = true;
        proposal.isApproved = false;
        proposal.voteEndTime = block.timestamp + 7 days; // Example exhibition voting period
        nextExhibitionProposalId++;
        emit ExhibitionProposed(proposal.proposalId, _exhibitionTitle, _artNFTIds);
    }

    function voteOnExhibitionProposal(uint _exhibitionProposalId, bool _vote) public onlyMember validProposal(_exhibitionProposalId, exhibitionProposals) {
        ExhibitionProposal storage proposal = exhibitionProposals[_exhibitionProposalId];
        require(!proposal.isApproved, "Exhibition proposal already finalized.");
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ExhibitionVoted(_exhibitionProposalId, msg.sender, _vote);
    }

    function startExhibition(uint _exhibitionProposalId) public onlyMember {
        ExhibitionProposal storage proposal = exhibitionProposals[_exhibitionProposalId];
        require(proposal.isActive && block.timestamp > proposal.voteEndTime, "Exhibition proposal not active or voting not ended.");

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.isApproved = true;
            proposal.startTime = block.timestamp;
            proposal.isActive = false; // Mark proposal as completed
            emit ExhibitionStarted(_exhibitionProposalId, block.timestamp);
            // --- Exhibition Start Logic (Conceptual) ---
            // In a real implementation, this could trigger events or actions to:
            // - Update metadata for exhibition NFTs
            // - Integrate with a virtual gallery platform
            // - Announce the exhibition to the community
        } else {
            proposal.isActive = false; // Proposal failed
        }
    }


    // --- Reputation & Fractionalization Functions ---

    function rateArtistContribution(address _artist, uint _rating) public onlyMember {
        require(members[_artist].isActive, "Cannot rate non-member artist.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        artistRatings[msg.sender][_artist] = _rating;
        members[_artist].reputationScore = (members[_artist].reputationScore + _rating) / 2; // Simple reputation update - could be more sophisticated
        emit ArtistRated(msg.sender, _artist, _rating);
    }

    function fractionalizeArtNFT(uint _nftId, uint _numberOfFractions) public onlyMember {
        require(artNFTs[_nftId].metadataURI.length > 0, "NFT does not exist.");
        require(!isFractionalizedNFT[_nftId], "NFT is already fractionalized.");
        require(_numberOfFractions > 1 && _numberOfFractions <= 1000, "Number of fractions must be between 2 and 1000."); // Example limits

        isFractionalizedNFT[_nftId] = true;
        emit ArtNFTFractionalized(_nftId, _numberOfFractions);
        // --- Fractionalization Logic (Conceptual) ---
        // In a real implementation, this would:
        // 1. Integrate with an ERC1155 contract to create fractional tokens representing ownership.
        // 2. Potentially lock the original ERC721 NFT in the contract or a vault.
        // 3. Distribute the fractional tokens to the collective or original NFT owner based on governance rules.
    }

    function redeemArtFraction(uint _fractionalTokenId) public onlyMember {
        // --- Redeem Fraction Logic (Conceptual & Complex) ---
        // This is a highly complex function and requires significant design considerations in a real implementation.
        // It would involve:
        // 1. Tracking ownership of fractional tokens (ERC1155).
        // 2. Governance mechanisms to decide when and how fractional tokens can be redeemed for the underlying NFT.
        // 3. Potential burning of fractional tokens upon redemption.
        // 4. Handling scenarios with multiple fractional token holders wanting to redeem.
        // This example is left as a placeholder to highlight the concept.
        revert("Redeem Art Fraction functionality is conceptual and not fully implemented in this example.");
    }


    // --- DAO Governance & Treasury Functions ---

    function proposeRuleChange(string memory _ruleProposal) public onlyMember {
        RuleProposal storage proposal = ruleProposals[nextRuleProposalId];
        proposal.proposalId = nextRuleProposalId;
        proposal.ruleProposal = _ruleProposal;
        proposal.isActive = true;
        proposal.isApproved = false;
        proposal.voteEndTime = block.timestamp + 10 days; // Example rule change voting period
        nextRuleProposalId++;
        emit RuleChangeProposed(proposal.proposalId, _ruleProposal);
    }

    function voteOnRuleChange(uint _ruleProposalId, bool _vote) public onlyMember validProposal(_ruleProposalId, ruleProposals) {
        RuleProposal storage proposal = ruleProposals[_ruleProposalId];
        require(!proposal.isApproved, "Rule change proposal already finalized.");
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit RuleChangeVoted(_ruleProposalId, msg.sender, _vote);
    }

    function executeRuleChange(uint _ruleProposalId) public onlyMember {
        RuleProposal storage proposal = ruleProposals[_ruleProposalId];
        require(proposal.isActive && block.timestamp > proposal.voteEndTime, "Rule change proposal not active or voting not ended.");

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.isApproved = true;
            proposal.isActive = false; // Mark proposal as completed
            emit RuleChangeExecuted(_ruleProposalId, proposal.ruleProposal);
            // --- Rule Change Execution Logic (Conceptual) ---
            // In a real DAO, executing rule changes might involve:
            // - Updating contract parameters
            // - Modifying access control
            // - Triggering other contract functions
            // This example assumes rule changes are primarily informational or require manual intervention.
        } else {
            proposal.isActive = false; // Proposal failed
        }
    }

    function getTreasuryBalance() public view returns (uint) {
        return treasuryBalance;
    }

    function proposeTreasurySpending(string memory _spendingProposal, uint _amount) public onlyMember {
        require(_amount > 0, "Spending amount must be positive.");
        require(_amount <= treasuryBalance, "Insufficient treasury balance.");
        TreasuryProposal storage proposal = treasuryProposals[nextTreasuryProposalId];
        proposal.proposalId = nextTreasuryProposalId;
        proposal.spendingProposal = _spendingProposal;
        proposal.amount = _amount;
        proposal.isActive = true;
        proposal.isApproved = false;
        proposal.voteEndTime = block.timestamp + 7 days; // Example treasury voting period
        nextTreasuryProposalId++;
        emit TreasurySpendingProposed(proposal.proposalId, _spendingProposal, _amount);
    }

    function voteOnTreasurySpending(uint _treasuryProposalId, bool _vote) public onlyMember validProposal(_treasuryProposalId, treasuryProposals) {
        TreasuryProposal storage proposal = treasuryProposals[_treasuryProposalId];
        require(!proposal.isApproved, "Treasury spending proposal already finalized.");
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit TreasurySpendingVoted(_treasuryProposalId, msg.sender, _vote);
    }

    function executeTreasurySpending(uint _treasuryProposalId) public onlyMember {
        TreasuryProposal storage proposal = treasuryProposals[_treasuryProposalId];
        require(proposal.isActive && block.timestamp > proposal.voteEndTime, "Treasury spending proposal not active or voting not ended.");

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.isApproved = true;
            treasuryBalance -= proposal.amount;
            payable(owner).transfer(proposal.amount); // Example: Sending to contract owner (replace with actual recipient logic)
            proposal.isActive = false; // Mark proposal as completed
            emit TreasurySpendingExecuted(_treasuryProposalId, proposal.amount);
        } else {
            proposal.isActive = false; // Proposal failed
        }
    }

    function depositToTreasury() public payable {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

}

// --- Utility Library ---
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Assembly snippet from OpenZeppelin's Strings library (modified for simplicity)
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```