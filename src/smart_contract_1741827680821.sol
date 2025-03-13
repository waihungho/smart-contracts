```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective.
 * It allows artists to join, submit art proposals, vote on proposals, mint NFTs,
 * participate in exhibitions, earn royalties, and govern the collective.
 *
 * Function Summary:
 *
 * **Membership & Governance:**
 * 1. applyForMembership(): Allows artists to apply for membership.
 * 2. approveMembership(address _artist): Allows admin/governance to approve membership applications.
 * 3. revokeMembership(address _artist): Allows admin/governance to revoke membership.
 * 4. proposeCollectiveDecision(string memory _proposalDetails): Allows members to propose collective decisions.
 * 5. voteOnDecision(uint256 _decisionId, bool _support): Allows members to vote on collective decisions.
 * 6. executeDecision(uint256 _decisionId): Allows admin/governance to execute passed collective decisions.
 * 7. setGovernanceToken(address _tokenAddress): Allows admin to set the governance token address.
 * 8. stakeGovernanceToken(uint256 _amount): Allows members to stake governance tokens for increased voting power.
 * 9. unstakeGovernanceToken(uint256 _amount): Allows members to unstake governance tokens.
 *
 * **Art Submission & NFT Minting:**
 * 10. submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash): Allows members to submit art proposals.
 * 11. voteOnArtProposal(uint256 _proposalId, bool _approve): Allows members to vote on art proposals.
 * 12. mintArtNFT(uint256 _proposalId): Mints an NFT for an approved art proposal.
 * 13. setArtMetadataURI(uint256 _tokenId, string memory _metadataURI): Allows admin to set the metadata URI for an NFT.
 * 14. setBaseURI(string memory _baseURI): Allows admin to set the base URI for NFT metadata.
 *
 * **Exhibitions & Royalties:**
 * 15. createExhibition(string memory _exhibitionName, string memory _exhibitionDescription, uint256 _startTime, uint256 _endTime): Allows admin to create a new exhibition.
 * 16. addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId): Allows admin to add art NFTs to an exhibition.
 * 17. voteForExhibitionArt(uint256 _exhibitionId, uint256 _tokenId): Allows members to vote for art to be featured in exhibitions.
 * 18. startExhibitionVoting(uint256 _exhibitionId): Allows admin to start voting for an exhibition.
 * 19. endExhibitionVoting(uint256 _exhibitionId): Allows admin to end voting for an exhibition and finalize the selection.
 * 20. distributeRoyalties(uint256 _tokenId): Distributes royalties to the artist and collective upon NFT sale (simulated).
 * 21. withdrawEarnings(): Allows members (artists and collective) to withdraw their accumulated earnings.
 * 22. setRoyaltyPercentage(uint256 _percentage): Allows admin to set the royalty percentage for NFT sales.
 *
 * **Utility & Admin:**
 * 23. pauseContract(): Allows admin to pause the contract functionality.
 * 24. unpauseContract(): Allows admin to unpause the contract functionality.
 * 25. getArtDetails(uint256 _tokenId): Retrieves details of a specific art NFT.
 * 26. getExhibitionDetails(uint256 _exhibitionId): Retrieves details of a specific exhibition.
 * 27. getMemberDetails(address _member): Retrieves details of a collective member.
 */
contract DecentralizedArtCollective {
    // --- State Variables ---

    string public contractName = "Decentralized Autonomous Art Collective";
    address public admin;
    bool public paused = false;
    uint256 public nextProposalId = 0;
    uint256 public nextExhibitionId = 0;
    uint256 public nextNFTTokenId = 0;
    string public baseURI;
    uint256 public royaltyPercentage = 5; // Default 5% royalty

    address public governanceTokenAddress; // Address of the governance token contract

    // Structs
    struct Member {
        address memberAddress;
        bool isApproved;
        uint256 stakedGovernanceTokens;
        uint256 earnings;
        uint256 membershipApplyTime;
    }

    struct ArtProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        bool isApproved;
        bool isActive;
        uint256 proposalTime;
    }

    struct ArtNFT {
        uint256 tokenId;
        uint256 proposalId;
        address artist;
        string metadataURI;
        uint256 royaltyEarnings;
    }

    struct Exhibition {
        uint256 exhibitionId;
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 votingStartTime;
        uint256 votingEndTime;
        bool isVotingActive;
        bool isVotingEnded;
        uint256[] featuredArtTokenIds;
        uint256 exhibitionEarnings;
    }

    struct CollectiveDecision {
        uint256 decisionId;
        address proposer;
        string proposalDetails;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool isExecuted;
        bool isActive;
        uint256 proposalTime;
    }

    // Mappings
    mapping(address => Member) public members;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => CollectiveDecision) public collectiveDecisions;
    mapping(uint256 => mapping(address => bool)) public artProposalVotes; // proposalId => voterAddress => votedApprove (true/false)
    mapping(uint256 => mapping(address => bool)) public exhibitionArtVotes; // exhibitionId => tokenId => voterAddress => voted (true)
    mapping(uint256 => mapping(address => bool)) public collectiveDecisionVotes; // decisionId => voterAddress => votedYes (true/false)

    // Events
    event MembershipApplied(address indexed applicant, uint256 timestamp);
    event MembershipApproved(address indexed member, address indexed approvedBy, uint256 timestamp);
    event MembershipRevoked(address indexed member, address indexed revokedBy, uint256 timestamp);
    event ArtProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 timestamp);
    event ArtProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 timestamp);
    event ArtNFTMinted(uint256 indexed tokenId, uint256 indexed proposalId, address indexed artist, uint256 timestamp);
    event MetadataURISet(uint256 indexed tokenId, string metadataURI);
    event BaseURISet(string baseURI);
    event ExhibitionCreated(uint256 indexed exhibitionId, string name, uint256 startTime, uint256 endTime, uint256 timestamp);
    event ArtAddedToExhibition(uint256 indexed exhibitionId, uint256 indexed tokenId, uint256 timestamp);
    event ExhibitionArtVoted(uint256 indexed exhibitionId, uint256 indexed tokenId, address indexed voter, uint256 timestamp);
    event ExhibitionVotingStarted(uint256 indexed exhibitionId, uint256 timestamp);
    event ExhibitionVotingEnded(uint256 indexed exhibitionId, uint256 timestamp);
    event RoyaltiesDistributed(uint256 indexed tokenId, uint256 royaltyAmount, address indexed artist, uint256 collectiveShare, uint256 timestamp);
    event EarningsWithdrawn(address indexed member, uint256 amount, uint256 timestamp);
    event GovernanceTokenSet(address indexed tokenAddress, address indexed admin, uint256 timestamp);
    event GovernanceTokenStaked(address indexed member, uint256 amount, uint256 timestamp);
    event GovernanceTokenUnstaked(address indexed member, uint256 amount, uint256 timestamp);
    event CollectiveDecisionProposed(uint256 indexed decisionId, address indexed proposer, string proposalDetails, uint256 timestamp);
    event CollectiveDecisionVoted(uint256 indexed decisionId, address indexed voter, bool support, uint256 timestamp);
    event CollectiveDecisionExecuted(uint256 indexed decisionId, address indexed executor, uint256 timestamp);
    event ContractPaused(address indexed admin, uint256 timestamp);
    event ContractUnpaused(address indexed admin, uint256 timestamp);


    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isApproved, "Only approved members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(artProposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID.");
        _;
    }

    modifier validExhibitionId(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].exhibitionId == _exhibitionId, "Invalid exhibition ID.");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(artNFTs[_tokenId].tokenId == _tokenId, "Invalid token ID.");
        _;
    }

    modifier validDecisionId(uint256 _decisionId) {
        require(collectiveDecisions[_decisionId].decisionId == _decisionId, "Invalid decision ID.");
        _;
    }


    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        baseURI = "ipfs://default-base-uri/"; // Set a default base URI for metadata
    }

    // --- Membership & Governance Functions ---

    /// @notice Allows artists to apply for membership to the collective.
    function applyForMembership() external notPaused {
        require(!members[msg.sender].isApproved, "Already a member or membership pending.");
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            isApproved: false,
            stakedGovernanceTokens: 0,
            earnings: 0,
            membershipApplyTime: block.timestamp
        });
        emit MembershipApplied(msg.sender, block.timestamp);
    }

    /// @notice Allows admin to approve a membership application.
    /// @param _artist The address of the artist to approve.
    function approveMembership(address _artist) external onlyAdmin notPaused {
        require(!members[_artist].isApproved, "Artist is already a member.");
        require(members[_artist].membershipApplyTime > 0, "Artist has not applied for membership.");
        members[_artist].isApproved = true;
        emit MembershipApproved(_artist, msg.sender, block.timestamp);
    }

    /// @notice Allows admin to revoke membership from an artist.
    /// @param _artist The address of the artist to revoke membership from.
    function revokeMembership(address _artist) external onlyAdmin notPaused {
        require(members[_artist].isApproved, "Artist is not a member or membership is not active.");
        members[_artist].isApproved = false;
        emit MembershipRevoked(_artist, msg.sender, block.timestamp);
    }

    /// @notice Allows members to propose a collective decision.
    /// @param _proposalDetails Details of the decision proposal.
    function proposeCollectiveDecision(string memory _proposalDetails) external onlyMember notPaused {
        uint256 decisionId = nextProposalId++;
        collectiveDecisions[decisionId] = CollectiveDecision({
            decisionId: decisionId,
            proposer: msg.sender,
            proposalDetails: _proposalDetails,
            voteCountYes: 0,
            voteCountNo: 0,
            isExecuted: false,
            isActive: true,
            proposalTime: block.timestamp
        });
        emit CollectiveDecisionProposed(decisionId, msg.sender, _proposalDetails, block.timestamp);
    }

    /// @notice Allows members to vote on a collective decision.
    /// @param _decisionId The ID of the decision to vote on.
    /// @param _support True for yes, false for no.
    function voteOnDecision(uint256 _decisionId, bool _support) external onlyMember notPaused validDecisionId(_decisionId) {
        require(collectiveDecisions[_decisionId].isActive, "Decision is not active.");
        require(!collectiveDecisionVotes[_decisionId][msg.sender], "Already voted on this decision.");

        collectiveDecisionVotes[_decisionId][msg.sender] = true;
        if (_support) {
            collectiveDecisions[_decisionId].voteCountYes += getVotingPower(msg.sender);
        } else {
            collectiveDecisions[_decisionId].voteCountNo += getVotingPower(msg.sender);
        }
        emit CollectiveDecisionVoted(_decisionId, msg.sender, _support, block.timestamp);
    }

    /// @notice Allows admin to execute a passed collective decision.
    /// @param _decisionId The ID of the decision to execute.
    function executeDecision(uint256 _decisionId) external onlyAdmin notPaused validDecisionId(_decisionId) {
        require(collectiveDecisions[_decisionId].isActive, "Decision is not active.");
        require(!collectiveDecisions[_decisionId].isExecuted, "Decision already executed.");
        require(collectiveDecisions[_decisionId].voteCountYes > collectiveDecisions[_decisionId].voteCountNo, "Decision did not pass.");

        collectiveDecisions[_decisionId].isExecuted = true;
        collectiveDecisions[_decisionId].isActive = false;
        // @dev Add logic here to actually execute the decision based on proposalDetails if needed.
        emit CollectiveDecisionExecuted(_decisionId, msg.sender, block.timestamp);
    }

    /// @notice Sets the address of the governance token contract.
    /// @param _tokenAddress The address of the governance token.
    function setGovernanceToken(address _tokenAddress) external onlyAdmin notPaused {
        governanceTokenAddress = _tokenAddress;
        emit GovernanceTokenSet(_tokenAddress, msg.sender, block.timestamp);
    }

    /// @notice Allows members to stake governance tokens to increase voting power.
    /// @param _amount The amount of tokens to stake.
    function stakeGovernanceToken(uint256 _amount) external onlyMember notPaused {
        require(governanceTokenAddress != address(0), "Governance token address not set.");
        // @dev In a real implementation, you would interact with the governance token contract to transfer and lock tokens.
        // For simplicity, we are just updating the staked amount in this contract.
        // **Important: This is a simplified simulation. In a real scenario, you MUST handle token transfers securely.**
        // Assume governance token contract has a `transferFrom` function and this contract is approved to spend tokens.
        // IERC20(governanceTokenAddress).transferFrom(msg.sender, address(this), _amount); // Real implementation would require approval setup

        members[msg.sender].stakedGovernanceTokens += _amount;
        emit GovernanceTokenStaked(msg.sender, _amount, block.timestamp);
    }

    /// @notice Allows members to unstake governance tokens, reducing voting power.
    /// @param _amount The amount of tokens to unstake.
    function unstakeGovernanceToken(uint256 _amount) external onlyMember notPaused {
        require(members[msg.sender].stakedGovernanceTokens >= _amount, "Not enough staked tokens.");
        // @dev In a real implementation, you would interact with the governance token contract to transfer tokens back.
        // **Important: This is a simplified simulation. In a real scenario, you MUST handle token transfers securely.**
        // IERC20(governanceTokenAddress).transfer(msg.sender, _amount); // Real implementation would require token transfer back

        members[msg.sender].stakedGovernanceTokens -= _amount;
        emit GovernanceTokenUnstaked(msg.sender, _amount, block.timestamp);
    }

    /// @dev Helper function to get voting power, considering staked governance tokens.
    function getVotingPower(address _member) internal view returns (uint256) {
        // Basic voting power: 1 vote per member + staked tokens (example: 1 token = 1 vote)
        return 1 + members[_member].stakedGovernanceTokens;
        // @dev Can implement more complex voting power logic if needed (e.g., time-weighted staking, different token weights).
    }


    // --- Art Submission & NFT Minting Functions ---

    /// @notice Allows members to submit an art proposal.
    /// @param _title Title of the art piece.
    /// @param _description Description of the art piece.
    /// @param _ipfsHash IPFS hash of the art piece's media.
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyMember notPaused {
        uint256 proposalId = nextProposalId++;
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            voteCountApprove: 0,
            voteCountReject: 0,
            isApproved: false,
            isActive: true,
            proposalTime: block.timestamp
        });
        emit ArtProposalSubmitted(proposalId, msg.sender, _title, block.timestamp);
    }

    /// @notice Allows members to vote on an art proposal.
    /// @param _proposalId The ID of the art proposal to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnArtProposal(uint256 _proposalId, bool _approve) external onlyMember notPaused validProposalId(_proposalId) {
        require(artProposals[_proposalId].isActive, "Proposal is not active.");
        require(!artProposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");

        artProposalVotes[_proposalId][_msgSender()] = true; // using _msgSender() to be explicit about msg.sender in OZ style if needed.
        if (_approve) {
            artProposals[_proposalId].voteCountApprove += getVotingPower(msg.sender);
        } else {
            artProposals[_proposalId].voteCountReject += getVotingPower(msg.sender);
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _approve, block.timestamp);
    }

    /// @notice Mints an NFT for an approved art proposal.
    /// @param _proposalId The ID of the approved art proposal.
    function mintArtNFT(uint256 _proposalId) external onlyAdmin notPaused validProposalId(_proposalId) {
        require(!artProposals[_proposalId].isApproved, "NFT already minted for this proposal or proposal not active.");
        require(artProposals[_proposalId].isActive, "Proposal is not active.");
        require(artProposals[_proposalId].voteCountApprove > artProposals[_proposalId].voteCountReject, "Art proposal not approved.");

        artProposals[_proposalId].isApproved = true;
        artProposals[_proposalId].isActive = false;
        uint256 tokenId = nextNFTTokenId++;
        artNFTs[tokenId] = ArtNFT({
            tokenId: tokenId,
            proposalId: _proposalId,
            artist: artProposals[_proposalId].proposer,
            metadataURI: "", // Metadata URI will be set later by admin
            royaltyEarnings: 0
        });
        emit ArtNFTMinted(tokenId, _proposalId, artProposals[_proposalId].proposer, block.timestamp);
    }

    /// @notice Allows admin to set the metadata URI for a specific art NFT.
    /// @param _tokenId The ID of the NFT.
    /// @param _metadataURI The URI for the NFT's metadata.
    function setArtMetadataURI(uint256 _tokenId, string memory _metadataURI) external onlyAdmin notPaused validTokenId(_tokenId) {
        artNFTs[_tokenId].metadataURI = _metadataURI;
        emit MetadataURISet(_tokenId, _metadataURI);
    }

    /// @notice Allows admin to set the base URI for NFT metadata.
    /// @param _baseURI The base URI string.
    function setBaseURI(string memory _baseURI) external onlyAdmin notPaused {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }


    // --- Exhibitions & Royalties Functions ---

    /// @notice Allows admin to create a new exhibition.
    /// @param _exhibitionName Name of the exhibition.
    /// @param _exhibitionDescription Description of the exhibition.
    /// @param _startTime Unix timestamp for the exhibition start time.
    /// @param _endTime Unix timestamp for the exhibition end time.
    function createExhibition(string memory _exhibitionName, string memory _exhibitionDescription, uint256 _startTime, uint256 _endTime) external onlyAdmin notPaused {
        uint256 exhibitionId = nextExhibitionId++;
        exhibitions[exhibitionId] = Exhibition({
            exhibitionId: exhibitionId,
            name: _exhibitionName,
            description: _exhibitionDescription,
            startTime: _startTime,
            endTime: _endTime,
            votingStartTime: 0,
            votingEndTime: 0,
            isVotingActive: false,
            isVotingEnded: false,
            featuredArtTokenIds: new uint256[](0),
            exhibitionEarnings: 0
        });
        emit ExhibitionCreated(exhibitionId, _exhibitionName, _startTime, _endTime, block.timestamp);
    }

    /// @notice Allows admin to add an art NFT to an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _tokenId The ID of the art NFT to add.
    function addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId) external onlyAdmin notPaused validExhibitionId(_exhibitionId) validTokenId(_tokenId) {
        exhibitions[_exhibitionId].featuredArtTokenIds.push(_tokenId);
        emit ArtAddedToExhibition(_exhibitionId, _tokenId, block.timestamp);
    }

    /// @notice Allows members to vote for art NFTs to be featured in an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _tokenId The ID of the art NFT to vote for.
    function voteForExhibitionArt(uint256 _exhibitionId, uint256 _tokenId) external onlyMember notPaused validExhibitionId(_exhibitionId) validTokenId(_tokenId) {
        require(exhibitions[_exhibitionId].isVotingActive, "Exhibition voting is not active.");
        require(!exhibitionArtVotes[_exhibitionId][_tokenId][msg.sender], "Already voted for this artwork in this exhibition.");
        require(isArtInExhibition(_exhibitionId, _tokenId), "Art is not part of this exhibition.");

        exhibitionArtVotes[_exhibitionId][_tokenId][msg.sender] = true;
        // @dev In a real voting system, you might want to track vote counts per token per exhibition.
        emit ExhibitionArtVoted(_exhibitionId, _tokenId, msg.sender, block.timestamp);
    }

    /// @notice Allows admin to start voting for art in an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    function startExhibitionVoting(uint256 _exhibitionId) external onlyAdmin notPaused validExhibitionId(_exhibitionId) {
        require(!exhibitions[_exhibitionId].isVotingActive, "Exhibition voting is already active.");
        require(!exhibitions[_exhibitionId].isVotingEnded, "Exhibition voting is already ended.");
        exhibitions[_exhibitionId].isVotingActive = true;
        exhibitions[_exhibitionId].votingStartTime = block.timestamp;
        // @dev Set a reasonable voting end time, e.g., 7 days from start.
        exhibitions[_exhibitionId].votingEndTime = block.timestamp + 7 days; // Example: 7 days voting period
        emit ExhibitionVotingStarted(_exhibitionId, block.timestamp);
    }

    /// @notice Allows admin to end voting for art in an exhibition and finalize selection.
    /// @param _exhibitionId The ID of the exhibition.
    function endExhibitionVoting(uint256 _exhibitionId) external onlyAdmin notPaused validExhibitionId(_exhibitionId) {
        require(exhibitions[_exhibitionId].isVotingActive, "Exhibition voting is not active.");
        require(!exhibitions[_exhibitionId].isVotingEnded, "Exhibition voting is already ended.");
        require(block.timestamp >= exhibitions[_exhibitionId].votingEndTime, "Voting period not ended yet.");

        exhibitions[_exhibitionId].isVotingActive = false;
        exhibitions[_exhibitionId].isVotingEnded = true;
        // @dev Here you would implement logic to select the top voted artworks based on `exhibitionArtVotes` and update `exhibitions[_exhibitionId].featuredArtTokenIds` if needed.
        // For simplicity, in this example, we are just ending the voting.
        emit ExhibitionVotingEnded(_exhibitionId, block.timestamp);
    }

    /// @notice Simulates royalty distribution upon an NFT sale.
    /// @param _tokenId The ID of the sold NFT.
    function distributeRoyalties(uint256 _tokenId) external notPaused validTokenId(_tokenId) {
        // @dev In a real marketplace integration, this would be triggered by a sale event.
        // For this example, we are simulating a sale and distributing royalties.
        uint256 salePrice = 1 ether; // Example sale price - replace with actual sale price from marketplace
        uint256 royaltyAmount = (salePrice * royaltyPercentage) / 100;
        uint256 artistShare = royaltyAmount; // Artist gets the full royalty in this example. Can be split further.
        uint256 collectiveShare = salePrice - royaltyAmount; // Collective gets the rest (example)

        artNFTs[_tokenId].royaltyEarnings += artistShare;
        members[artNFTs[_tokenId].artist].earnings += artistShare;
        exhibitions[0].exhibitionEarnings += collectiveShare; // Example: All collective earnings go to exhibition 0 (can be managed differently)

        emit RoyaltiesDistributed(_tokenId, royaltyAmount, artNFTs[_tokenId].artist, collectiveShare, block.timestamp);
    }

    /// @notice Allows members to withdraw their accumulated earnings.
    function withdrawEarnings() external onlyMember notPaused {
        uint256 amountToWithdraw = members[msg.sender].earnings;
        require(amountToWithdraw > 0, "No earnings to withdraw.");
        members[msg.sender].earnings = 0;
        payable(msg.sender).transfer(amountToWithdraw); // Transfer earnings to the member
        emit EarningsWithdrawn(msg.sender, amountToWithdraw, block.timestamp);
    }

    /// @notice Allows admin to set the royalty percentage for NFT sales.
    /// @param _percentage The royalty percentage (e.g., 5 for 5%).
    function setRoyaltyPercentage(uint256 _percentage) external onlyAdmin notPaused {
        require(_percentage <= 100, "Royalty percentage cannot exceed 100.");
        royaltyPercentage = _percentage;
    }


    // --- Utility & Admin Functions ---

    /// @notice Allows admin to pause the contract.
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused(msg.sender, block.timestamp);
    }

    /// @notice Allows admin to unpause the contract.
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender, block.timestamp);
    }

    /// @notice Retrieves details of a specific art NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return ArtNFT struct containing NFT details.
    function getArtDetails(uint256 _tokenId) external view validTokenId(_tokenId) returns (ArtNFT memory) {
        return artNFTs[_tokenId];
    }

    /// @notice Retrieves details of a specific exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @return Exhibition struct containing exhibition details.
    function getExhibitionDetails(uint256 _exhibitionId) external view validExhibitionId(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /// @notice Retrieves details of a collective member.
    /// @param _member The address of the member.
    /// @return Member struct containing member details.
    function getMemberDetails(address _member) external view returns (Member memory) {
        return members[_member];
    }

    /// @dev Helper function to check if an art token is in an exhibition.
    function isArtInExhibition(uint256 _exhibitionId, uint256 _tokenId) internal view validExhibitionId(_exhibitionId) validTokenId(_tokenId) returns (bool) {
        for (uint256 i = 0; i < exhibitions[_exhibitionId].featuredArtTokenIds.length; i++) {
            if (exhibitions[_exhibitionId].featuredArtTokenIds[i] == _tokenId) {
                return true;
            }
        }
        return false;
    }

    // --- Fallback and Receive Functions (Optional) ---
    receive() external payable {} // To accept ETH if needed for contract funding or other purposes.
    fallback() external {}
}
```