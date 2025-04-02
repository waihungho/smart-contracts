```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI (Example - Adaptable and Innovative)
 * @notice A smart contract for a decentralized art collective, enabling collaborative art curation, exhibitions, fractional ownership, and dynamic artist reputation.
 *
 * Function Summary:
 *
 * --- Membership & Profile ---
 * 1. joinCollective(string memory _profileHash): Allows users to join the art collective with a profile.
 * 2. leaveCollective(): Allows members to leave the collective.
 * 3. updateProfile(string memory _newProfileHash): Allows members to update their profile.
 * 4. getMemberProfile(address _memberAddress): Retrieves a member's profile hash.
 * 5. getCollectiveMembers(): Returns a list of all collective members.
 *
 * --- Artwork Management & Curation ---
 * 6. proposeArtwork(string memory _artworkCID, string memory _metadataCID): Members propose artworks for the collective to acquire.
 * 7. voteOnArtworkProposal(uint256 _proposalId, bool _vote): Members vote on artwork proposals.
 * 8. executeArtworkProposal(uint256 _proposalId): Executes an approved artwork proposal, adding it to the collective's collection.
 * 9. getArtworkDetails(uint256 _artworkId): Retrieves details of an artwork in the collection.
 * 10. getCollectiveArtworks(): Returns a list of artwork IDs in the collective's collection.
 * 11. createFractionalNFT(uint256 _artworkId, uint256 _totalSupply): Creates fractional NFTs representing ownership of a collective artwork.
 * 12. getFractionalNFTAddress(uint256 _artworkId): Retrieves the address of the fractional NFT contract for a specific artwork.
 *
 * --- Exhibition & Showcase ---
 * 13. proposeExhibition(string memory _exhibitionTitle, uint256[] memory _artworkIds, uint256 _startTime, uint256 _endTime): Members propose art exhibitions.
 * 14. voteOnExhibitionProposal(uint256 _proposalId, bool _vote): Members vote on exhibition proposals.
 * 15. executeExhibitionProposal(uint256 _proposalId): Executes an approved exhibition proposal, scheduling the exhibition.
 * 16. getExhibitionDetails(uint256 _exhibitionId): Retrieves details of an exhibition.
 * 17. getUpcomingExhibitions(): Returns a list of upcoming exhibition IDs.
 * 18. getPastExhibitions(): Returns a list of past exhibition IDs.
 *
 * --- Reputation & Rewards ---
 * 19. contributeToCollective(string memory _contributionDetails): Members can log contributions to the collective (e.g., curation, marketing, technical work).
 * 20. voteForReputation(address _memberAddress, uint256 _reputationPoints): Members can vote to award reputation points to other members for contributions.
 * 21. redeemReputationForReward(uint256 _reputationPoints): Members can redeem accumulated reputation points for potential rewards (e.g., governance power, exclusive access - reward mechanism needs further definition and implementation).
 * 22. getMemberReputation(address _memberAddress): Retrieves a member's reputation score.
 *
 * --- Utility & Governance ---
 * 23. getProposalDetails(uint256 _proposalId): Retrieves details of any type of proposal (artwork, exhibition, reputation).
 * 24. getActiveProposals(): Returns a list of active proposal IDs.
 * 25. getCollectiveBalance(): Returns the contract's ETH balance.
 * 26. withdrawFunds(address payable _recipient, uint256 _amount): Allows the contract owner (or DAO-governed address) to withdraw funds from the collective (governance needed for true decentralization).
 * 27. changeOwner(address _newOwner): Allows the current owner to transfer contract ownership.
 */
contract DecentralizedArtCollective {

    // --- Structs ---
    struct Member {
        string profileHash; // IPFS hash of member's profile (e.g., JSON with name, bio, etc.)
        uint256 reputationScore;
        bool isActive;
    }

    struct Artwork {
        string artworkCID; // IPFS CID of the artwork file
        string metadataCID; // IPFS CID of artwork metadata (artist, title, description, etc.)
        bool isAcquired;
        uint256 fractionalNFTContractId; // ID linking to fractional NFT contract if created
    }

    struct Exhibition {
        string title;
        uint256[] artworkIds;
        uint256 startTime; // Unix timestamp
        uint256 endTime;   // Unix timestamp
        bool isActive;
        bool isExecuted;
    }

    enum ProposalType { ARTWORK_ACQUISITION, EXHIBITION_PROPOSAL, REPUTATION_AWARD }

    struct Proposal {
        ProposalType proposalType;
        address proposer;
        uint256 timestamp;
        string description; // General description of the proposal
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isExecuted;
        // Specific proposal details are handled based on proposalType (using separate mappings or data structures if needed for complexity)
        uint256 artworkId;       // For ARTWORK_ACQUISITION proposals
        uint256[] exhibitionArtworkIds; // For EXHIBITION_PROPOSAL proposals
        string exhibitionTitle;         // For EXHIBITION_PROPOSAL proposals
        uint256 exhibitionStartTime;    // For EXHIBITION_PROPOSAL proposals
        uint256 exhibitionEndTime;      // For EXHIBITION_PROPOSAL proposals
        address reputationTargetMember; // For REPUTATION_AWARD proposals
        uint256 reputationPoints;       // For REPUTATION_AWARD proposals
    }

    // --- State Variables ---
    address public owner;
    mapping(address => Member) public members;
    address[] public collectiveMembers;
    uint256 public memberCount;

    mapping(uint256 => Artwork) public artworks;
    uint256 public artworkCount;
    mapping(uint256 => address) public fractionalNFTContracts; // artworkId => fractionalNFTContractAddress

    mapping(uint256 => Exhibition) public exhibitions;
    uint256 public exhibitionCount;

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    uint256 public votingDuration = 7 days; // Default voting duration

    // --- Events ---
    event MemberJoined(address memberAddress, string profileHash);
    event MemberLeft(address memberAddress);
    event ProfileUpdated(address memberAddress, string newProfileHash);
    event ArtworkProposed(uint256 proposalId, address proposer, string artworkCID, string metadataCID);
    event ArtworkProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtworkAcquired(uint256 artworkId, string artworkCID, string metadataCID);
    event ExhibitionProposed(uint256 proposalId, address proposer, string exhibitionTitle, uint256[] artworkIds, uint256 startTime, uint256 endTime);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool vote);
    event ExhibitionScheduled(uint256 exhibitionId, string title, uint256 startTime, uint256 endTime);
    event ContributionLogged(address memberAddress, string contributionDetails);
    event ReputationVoted(address voter, address targetMember, uint256 reputationPoints);
    event ReputationRedeemed(address memberAddress, uint256 reputationPoints);
    event FundsWithdrawn(address recipient, uint256 amount);
    event OwnerChanged(address newOwner);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only active members can call this function.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(proposals[_proposalId].isActive, "Proposal is not active or does not exist.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].isExecuted, "Proposal already executed.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Membership & Profile Functions ---
    function joinCollective(string memory _profileHash) public {
        require(!members[msg.sender].isActive, "Already a member.");
        members[msg.sender] = Member({
            profileHash: _profileHash,
            reputationScore: 0,
            isActive: true
        });
        collectiveMembers.push(msg.sender);
        memberCount++;
        emit MemberJoined(msg.sender, _profileHash);
    }

    function leaveCollective() public onlyMember {
        members[msg.sender].isActive = false;
        // To truly remove from collectiveMembers array would require more complex logic to handle array shifting.
        // For simplicity, we can mark as inactive and handle iteration logic accordingly in getter functions if needed for efficiency.
        emit MemberLeft(msg.sender);
    }

    function updateProfile(string memory _newProfileHash) public onlyMember {
        members[msg.sender].profileHash = _newProfileHash;
        emit ProfileUpdated(msg.sender, _newProfileHash);
    }

    function getMemberProfile(address _memberAddress) public view returns (string memory) {
        require(members[_memberAddress].isActive, "Not an active member.");
        return members[_memberAddress].profileHash;
    }

    function getCollectiveMembers() public view returns (address[] memory) {
        return collectiveMembers;
    }

    // --- Artwork Management & Curation Functions ---
    function proposeArtwork(string memory _artworkCID, string memory _metadataCID) public onlyMember {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposalType: ProposalType.ARTWORK_ACQUISITION,
            proposer: msg.sender,
            timestamp: block.timestamp,
            description: "Acquire artwork: " + _metadataCID, // Simple description - could be enhanced
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false,
            artworkId: artworkCount + 1, // Assigning potential artworkId for later use if approved
            exhibitionArtworkIds: new uint256[](0), // Not relevant for artwork proposals
            exhibitionTitle: "",                 // Not relevant for artwork proposals
            exhibitionStartTime: 0,            // Not relevant for artwork proposals
            exhibitionEndTime: 0,              // Not relevant for artwork proposals
            reputationTargetMember: address(0), // Not relevant
            reputationPoints: 0                // Not relevant
        });
        emit ArtworkProposed(proposalCount, msg.sender, _artworkCID, _metadataCID);
    }

    function voteOnArtworkProposal(uint256 _proposalId, bool _vote) public onlyMember validProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp < proposals[_proposalId].timestamp + votingDuration, "Voting period ended.");
        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ArtworkProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeArtworkProposal(uint256 _proposalId) public onlyMember validProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp >= proposals[_proposalId].timestamp + votingDuration, "Voting period not ended yet.");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal not approved."); // Simple majority
        require(proposals[_proposalId].proposalType == ProposalType.ARTWORK_ACQUISITION, "Invalid proposal type.");

        artworkCount++;
        artworks[artworkCount] = Artwork({
            artworkCID: getProposalDetails(_proposalId).artworkCIDParam, // Accessing parameters - needs refinement for security and clarity
            metadataCID: getProposalDetails(_proposalId).metadataCIDParam, // Accessing parameters - needs refinement for security and clarity
            isAcquired: true,
            fractionalNFTContractId: 0 // Initially no fractional NFT
        });
        proposals[_proposalId].isExecuted = true;
        proposals[_proposalId].isActive = false; // Optionally deactivate proposal
        emit ArtworkAcquired(artworkCount, artworks[artworkCount].artworkCID, artworks[artworkCount].metadataCID);
    }

    function getArtworkDetails(uint256 _artworkId) public view returns (string memory artworkCID, string memory metadataCID, bool isAcquired) {
        require(artworks[_artworkId].isAcquired, "Artwork not in collection.");
        return (artworks[_artworkId].artworkCID, artworks[_artworkId].metadataCID, artworks[_artworkId].isAcquired);
    }

    function getCollectiveArtworks() public view returns (uint256[] memory) {
        uint256[] memory artworkIds = new uint256[](artworkCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= artworkCount; i++) {
            if (artworks[i].isAcquired) {
                artworkIds[index] = i;
                index++;
            }
        }
        // Resize array to actual number of artworks
        assembly {
            mstore(artworkIds, index)
        }
        return artworkIds;
    }

    // --- Fractional NFT Functionality (Conceptual - Requires External NFT Contract Integration) ---
    // In a real-world scenario, you would likely integrate with an existing NFT contract standard (e.g., ERC721 or ERC1155)
    // This function is a placeholder to illustrate the concept.  You would need to deploy a separate fractional NFT contract
    // and integrate with it.  This example just stores a flag and contract ID.

    function createFractionalNFT(uint256 _artworkId, uint256 _totalSupply) public onlyMember {
        require(artworks[_artworkId].isAcquired, "Artwork not in collection.");
        require(fractionalNFTContracts[_artworkId] == address(0), "Fractional NFT already created for this artwork.");
        // --- In a real implementation, you would: ---
        // 1. Deploy a new Fractional NFT contract (e.g., ERC1155) linked to this DAAC contract.
        // 2. Mint _totalSupply of NFTs representing fractions of artwork _artworkId.
        // 3. Store the address of the deployed Fractional NFT contract in `fractionalNFTContracts[_artworkId]`.

        // --- Placeholder for demonstration ---
        fractionalNFTContracts[_artworkId] = address(uint160(blockhash(block.number - 1))); // Dummy address - REPLACE WITH ACTUAL CONTRACT DEPLOYMENT LOGIC
        artworks[_artworkId].fractionalNFTContractId = _artworkId; // For simplicity, reusing artworkId as contract ID
        // --- End Placeholder ---

        // Further logic would be needed to manage distribution/sale of fractional NFTs, potentially through proposals.
    }

    function getFractionalNFTAddress(uint256 _artworkId) public view returns (address) {
        return fractionalNFTContracts[_artworkId];
    }


    // --- Exhibition & Showcase Functions ---
    function proposeExhibition(string memory _exhibitionTitle, uint256[] memory _artworkIds, uint256 _startTime, uint256 _endTime) public onlyMember {
        require(_startTime < _endTime, "Exhibition start time must be before end time.");
        require(_artworkIds.length > 0, "Exhibition must include at least one artwork.");
        for (uint256 i = 0; i < _artworkIds.length; i++) {
            require(artworks[_artworkIds[i]].isAcquired, "Artwork in exhibition must be acquired by the collective.");
        }

        exhibitionCount++;
        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposalType: ProposalType.EXHIBITION_PROPOSAL,
            proposer: msg.sender,
            timestamp: block.timestamp,
            description: "Propose exhibition: " + _exhibitionTitle, // Simple description
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false,
            artworkId: 0, // Not relevant for exhibition proposals
            exhibitionArtworkIds: _artworkIds,
            exhibitionTitle: _exhibitionTitle,
            exhibitionStartTime: _startTime,
            exhibitionEndTime: _endTime,
            reputationTargetMember: address(0), // Not relevant
            reputationPoints: 0                // Not relevant
        });

        emit ExhibitionProposed(proposalCount, msg.sender, _exhibitionTitle, _artworkIds, _startTime, _endTime);
    }

    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) public onlyMember validProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp < proposals[_proposalId].timestamp + votingDuration, "Voting period ended.");
        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ExhibitionProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeExhibitionProposal(uint256 _proposalId) public onlyMember validProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp >= proposals[_proposalId].timestamp + votingDuration, "Voting period not ended yet.");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal not approved."); // Simple majority
        require(proposals[_proposalId].proposalType == ProposalType.EXHIBITION_PROPOSAL, "Invalid proposal type.");
        require(exhibitionCount + 1 <= type(uint256).max, "Exhibition count overflow"); // Prevent overflow

        exhibitionCount++;
        exhibitions[exhibitionCount] = Exhibition({
            title: getProposalDetails(_proposalId).exhibitionTitleParam, // Accessing parameters - needs refinement for security and clarity
            artworkIds: getProposalDetails(_proposalId).exhibitionArtworkIdsParam, // Accessing parameters - needs refinement for security and clarity
            startTime: getProposalDetails(_proposalId).exhibitionStartTimeParam, // Accessing parameters - needs refinement for security and clarity
            endTime: getProposalDetails(_proposalId).exhibitionEndTimeParam,     // Accessing parameters - needs refinement for security and clarity
            isActive: true, // Exhibition is now active upon scheduling
            isExecuted: true
        });
        proposals[_proposalId].isExecuted = true;
        proposals[_proposalId].isActive = false; // Optionally deactivate proposal

        emit ExhibitionScheduled(exhibitionCount, exhibitions[exhibitionCount].title, exhibitions[exhibitionCount].startTime, exhibitions[exhibitionCount].endTime);
    }


    function getExhibitionDetails(uint256 _exhibitionId) public view returns (string memory title, uint256[] memory artworkIds, uint256 startTime, uint256 endTime, bool isActive) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition not found or not active."); // Consider if 'isActive' is the right check here
        return (exhibitions[_exhibitionId].title, exhibitions[_exhibitionId].artworkIds, exhibitions[_exhibitionId].startTime, exhibitions[_exhibitionId].endTime, exhibitions[_exhibitionId].isActive);
    }

    function getUpcomingExhibitions() public view returns (uint256[] memory) {
        uint256[] memory upcomingExhibitions = new uint256[](exhibitionCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= exhibitionCount; i++) {
            if (exhibitions[i].isActive && exhibitions[i].endTime > block.timestamp) { // Assuming 'isActive' means scheduled and not yet ended
                upcomingExhibitions[index] = i;
                index++;
            }
        }
        assembly {
            mstore(upcomingExhibitions, index)
        }
        return upcomingExhibitions;
    }

    function getPastExhibitions() public view returns (uint256[] memory) {
        uint256[] memory pastExhibitions = new uint256[](exhibitionCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= exhibitionCount; i++) {
            if (!exhibitions[i].isActive || exhibitions[i].endTime <= block.timestamp) { // Assuming 'isActive' means scheduled and not yet ended
                pastExhibitions[index] = i;
                index++;
            }
        }
        assembly {
            mstore(pastExhibitions, index)
        }
        return pastExhibitions;
    }


    // --- Reputation & Rewards Functions ---
    function contributeToCollective(string memory _contributionDetails) public onlyMember {
        // This function simply logs contributions. Reputation voting is done separately.
        emit ContributionLogged(msg.sender, _contributionDetails);
    }

    function voteForReputation(address _memberAddress, uint256 _reputationPoints) public onlyMember {
        require(members[_memberAddress].isActive, "Target member is not active.");
        require(_memberAddress != msg.sender, "Cannot vote for yourself.");
        require(_reputationPoints > 0 && _reputationPoints <= 100, "Reputation points must be between 1 and 100."); // Example limit

        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposalType: ProposalType.REPUTATION_AWARD,
            proposer: msg.sender,
            timestamp: block.timestamp,
            description: "Award reputation to " + _memberAddress, // Simple description
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false,
            artworkId: 0, // Not relevant
            exhibitionArtworkIds: new uint256[](0), // Not relevant
            exhibitionTitle: "",                 // Not relevant
            exhibitionStartTime: 0,            // Not relevant
            exhibitionEndTime: 0,              // Not relevant
            reputationTargetMember: _memberAddress,
            reputationPoints: _reputationPoints
        });
        emit ReputationVoted(msg.sender, _memberAddress, _reputationPoints);
    }

    function voteOnReputationProposal(uint256 _proposalId, bool _vote) public onlyMember validProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp < proposals[_proposalId].timestamp + votingDuration, "Voting period ended.");
        require(proposals[_proposalId].proposalType == ProposalType.REPUTATION_AWARD, "Invalid proposal type.");

        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ExhibitionProposalVoted(_proposalId, msg.sender, _vote); // Reusing event for simplicity - consider a more specific event
    }

    function executeReputationProposal(uint256 _proposalId) public onlyMember validProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp >= proposals[_proposalId].timestamp + votingDuration, "Voting period not ended yet.");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal not approved."); // Simple majority
        require(proposals[_proposalId].proposalType == ProposalType.REPUTATION_AWARD, "Invalid proposal type.");

        address targetMember = getProposalDetails(_proposalId).reputationTargetMemberParam; // Accessing parameters - needs refinement for security and clarity
        uint256 reputationPoints = getProposalDetails(_proposalId).reputationPointsParam;   // Accessing parameters - needs refinement for security and clarity
        members[targetMember].reputationScore += reputationPoints;

        proposals[_proposalId].isExecuted = true;
        proposals[_proposalId].isActive = false; // Optionally deactivate proposal
    }


    function redeemReputationForReward(uint256 _reputationPoints) public onlyMember {
        require(members[msg.sender].reputationScore >= _reputationPoints, "Insufficient reputation points.");
        // --- Define Reward Mechanism Here ---
        // Example:  Could grant governance voting power, access to exclusive features, or even token rewards (if the contract holds tokens).
        // For simplicity, this example just reduces reputation. A real system needs a defined reward structure.
        members[msg.sender].reputationScore -= _reputationPoints;
        emit ReputationRedeemed(msg.sender, _reputationPoints);
    }

    function getMemberReputation(address _memberAddress) public view returns (uint256) {
        return members[_memberAddress].reputationScore;
    }


    // --- Utility & Governance Functions ---
    function getProposalDetails(uint256 _proposalId) public view returns (
        ProposalType proposalType,
        address proposer,
        uint256 timestamp,
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        bool isActive,
        bool isExecuted,
        string memory artworkCIDParam,   // Parameters for different proposal types - needs secure and structured approach
        string memory metadataCIDParam,
        uint256[] memory exhibitionArtworkIdsParam,
        string memory exhibitionTitleParam,
        uint256 exhibitionStartTimeParam,
        uint256 exhibitionEndTimeParam,
        address reputationTargetMemberParam,
        uint256 reputationPointsParam
    ) {
        Proposal storage p = proposals[_proposalId];
        return (
            p.proposalType,
            p.proposer,
            p.timestamp,
            p.description,
            p.votesFor,
            p.votesAgainst,
            p.isActive,
            p.isExecuted,
            (p.proposalType == ProposalType.ARTWORK_ACQUISITION ? artworks[p.artworkId].artworkCID : ""),  // Conditional parameter access - INSECURE and INEFFICIENT. Refactor needed!
            (p.proposalType == ProposalType.ARTWORK_ACQUISITION ? artworks[p.artworkId].metadataCID : ""), // Conditional parameter access - INSECURE and INEFFICIENT. Refactor needed!
            (p.proposalType == ProposalType.EXHIBITION_PROPOSAL ? p.exhibitionArtworkIds : new uint256[](0)), // Conditional parameter access - INSECURE and INEFFICIENT. Refactor needed!
            (p.proposalType == ProposalType.EXHIBITION_PROPOSAL ? p.exhibitionTitle : ""),                 // Conditional parameter access - INSECURE and INEFFICIENT. Refactor needed!
            (p.proposalType == ProposalType.EXHIBITION_PROPOSAL ? p.exhibitionStartTime : 0),             // Conditional parameter access - INSECURE and INEFFICIENT. Refactor needed!
            (p.proposalType == ProposalType.EXHIBITION_PROPOSAL ? p.exhibitionEndTime : 0),               // Conditional parameter access - INSECURE and INEFFICIENT. Refactor needed!
            (p.proposalType == ProposalType.REPUTATION_AWARD ? p.reputationTargetMember : address(0)),      // Conditional parameter access - INSECURE and INEFFICIENT. Refactor needed!
            (p.proposalType == ProposalType.REPUTATION_AWARD ? p.reputationPoints : 0)                     // Conditional parameter access - INSECURE and INEFFICIENT. Refactor needed!
        );
    }


    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposals = new uint256[](proposalCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].isActive) {
                activeProposals[index] = i;
                index++;
            }
        }
        assembly {
            mstore(activeProposals, index)
        }
        return activeProposals;
    }

    function getCollectiveBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawFunds(address payable _recipient, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed.");
        emit FundsWithdrawn(_recipient, _amount);
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address.");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    // --- Fallback and Receive functions (Optional - for receiving ETH donations) ---
    receive() external payable {}
    fallback() external payable {}
}
```