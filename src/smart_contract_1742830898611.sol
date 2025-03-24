```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract Outline and Function Summary
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 *      This contract allows artists to submit digital art proposals, community members to vote on them,
 *      and the DAAC to curate and manage a digital art collection. It incorporates advanced concepts like
 *      dynamic NFT royalties, on-chain reputation, curated art exhibitions, and decentralized governance.
 *
 * Function Summary:
 * -----------------
 * **Membership & Reputation:**
 * 1. requestMembership(): Allows users to request membership to the DAAC.
 * 2. approveMembership(address _user): Admin function to approve membership requests.
 * 3. revokeMembership(address _user): Admin function to revoke membership.
 * 4. getMemberReputation(address _user): Retrieves the reputation score of a member.
 * 5. contributeToReputation(address _user, uint256 _amount): Allows members to contribute to another member's reputation.
 * 6. getMembershipStatus(address _user): Checks if an address is a member.
 *
 * **Art Submission & Curation:**
 * 7. submitArtProposal(string _metadataURI, uint256 _royaltyPercentage): Allows members to submit art proposals with metadata URI and royalty percentage.
 * 8. voteOnArtProposal(uint256 _proposalId, bool _vote): Members can vote on art proposals.
 * 9. getArtProposalDetails(uint256 _proposalId): Retrieves details of a specific art proposal.
 * 10. finalizeArtProposal(uint256 _proposalId): Admin function to finalize an approved art proposal and mint an NFT.
 * 11. rejectArtProposal(uint256 _proposalId): Admin function to reject an art proposal.
 * 12. getApprovedArtCount(): Returns the number of approved art pieces.
 * 13. getProposalVotingStatus(uint256 _proposalId): Returns the current voting status of a proposal (open/closed).
 *
 * **NFT Management & Royalties:**
 * 14. transferArtNFT(uint256 _tokenId, address _to): Allows transfer of curated art NFTs.
 * 15. getArtNFTRoyaltyInfo(uint256 _tokenId): Retrieves royalty information for a specific art NFT.
 * 16. setDynamicRoyaltyMultiplier(uint256 _multiplier): Admin function to set a multiplier for dynamic royalties based on reputation.
 * 17. withdrawArtistRoyalties(): Artists can withdraw their accumulated royalties.
 * 18. getArtistRoyaltyBalance(address _artist): Retrieves the royalty balance of an artist.
 *
 * **Exhibitions & Events:**
 * 19. createExhibition(string _exhibitionName, uint256[] _tokenIds): Admin function to create a curated digital art exhibition.
 * 20. getExhibitionDetails(uint256 _exhibitionId): Retrieves details of a specific exhibition.
 * 21. participateInExhibition(uint256 _exhibitionId): Allows members to participate in an exhibition (future functionality - e.g., virtual gallery access).
 *
 * **DAO Governance & Parameters:**
 * 22. proposeParameterChange(string _parameterName, uint256 _newValue): Members can propose changes to DAO parameters.
 * 23. voteOnParameterChange(uint256 _proposalId, bool _vote): Members can vote on parameter change proposals.
 * 24. executeParameterChange(uint256 _proposalId): Admin function to execute approved parameter changes.
 * 25. getParameterValue(string _parameterName): Retrieves the value of a specific DAO parameter.
 * 26. pauseContract(): Admin function to pause critical contract functionalities.
 * 27. unpauseContract(): Admin function to unpause contract functionalities.
 * 28. isContractPaused(): Checks if the contract is currently paused.
 */

contract DecentralizedArtCollective {

    // --- State Variables ---

    address public admin; // Address of the contract administrator
    bool public paused; // Contract pause status

    // Membership Management
    mapping(address => bool) public members; // Mapping of member addresses
    mapping(address => uint256) public memberReputation; // Reputation score for each member
    address[] public membershipRequests; // Array of addresses requesting membership

    // Art Proposal Management
    uint256 public proposalCounter; // Counter for art proposals
    struct ArtProposal {
        address proposer;
        string metadataURI;
        uint256 royaltyPercentage;
        uint256 upVotes;
        uint256 downVotes;
        bool finalized;
        bool rejected;
        uint256 submissionTimestamp;
        bool votingOpen;
    }
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Track votes per proposal per member
    uint256 public proposalVoteDuration = 7 days; // Default voting duration for proposals

    // Curated Art NFT Management
    uint256 public artNFTCounter; // Counter for minted art NFTs
    mapping(uint256 => string) public artNFTMetadataURIs; // Metadata URI for each art NFT
    mapping(uint256 => uint256) public artNFTRoyaltyPercentages; // Royalty percentage for each art NFT
    mapping(uint256 => address) public artNFTArtists; // Artist (proposer) of each art NFT
    mapping(address => uint256) public artistRoyaltyBalances; // Accumulated royalty balance for each artist
    uint256 public dynamicRoyaltyMultiplier = 100; // Multiplier for dynamic royalties (e.g., 100 = 1x)

    // Exhibitions Management
    uint256 public exhibitionCounter; // Counter for exhibitions
    struct Exhibition {
        string name;
        uint256[] artTokenIds;
        address curator;
        uint256 creationTimestamp;
    }
    mapping(uint256 => Exhibition) public exhibitions;

    // DAO Governance Parameters
    mapping(string => uint256) public daoParameters; // Generic storage for DAO parameters (e.g., membershipFee, votingThreshold)
    uint256 public parameterProposalCounter;
    struct ParameterProposal {
        string parameterName;
        uint256 newValue;
        uint256 upVotes;
        uint256 downVotes;
        bool finalized;
        uint256 submissionTimestamp;
        bool votingOpen;
    }
    mapping(uint256 => ParameterProposal) public parameterProposals;
    mapping(uint256 => mapping(address => bool)) public parameterProposalVotes; // Track votes for parameter proposals
    uint256 public parameterVoteDuration = 14 days; // Default voting duration for parameter proposals

    // --- Events ---
    event MembershipRequested(address indexed user);
    event MembershipApproved(address indexed user, address indexed approvedBy);
    event MembershipRevoked(address indexed user, address indexed revokedBy);
    event ReputationContributed(address indexed from, address indexed to, uint256 amount);
    event ArtProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string metadataURI, uint256 royaltyPercentage);
    event ArtProposalVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event ArtProposalFinalized(uint256 indexed proposalId, uint256 indexed tokenId);
    event ArtProposalRejected(uint256 indexed proposalId, address indexed rejectedBy);
    event ArtNFTMinted(uint256 indexed tokenId, string metadataURI, address indexed artist);
    event ArtNFTTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event ArtistRoyaltyWithdrawn(address indexed artist, uint256 amount);
    event ExhibitionCreated(uint256 indexed exhibitionId, string name, address indexed curator);
    event ParameterProposalSubmitted(uint256 indexed proposalId, string parameterName, uint256 newValue);
    event ParameterProposalVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event ParameterProposalExecuted(uint256 indexed proposalId, string parameterName, uint256 newValue);
    event ContractPaused(address indexed pausedBy);
    event ContractUnpaused(address indexed unpausedBy);


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(artProposals[_proposalId].votingOpen, "Voting period is not active or already closed");
        _;
    }

    modifier parameterVotingPeriodActive(uint256 _proposalId) {
        require(parameterProposals[_proposalId].votingOpen, "Voting period is not active or already closed");
        _;
    }


    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        paused = false;
        daoParameters["membershipFee"] = 1 ether; // Example default membership fee
        daoParameters["artApprovalThreshold"] = 50; // Example default art approval threshold (percentage)
        daoParameters["parameterChangeThreshold"] = 60; // Example default parameter change threshold (percentage)
    }


    // --- Membership & Reputation Functions ---

    /// @notice Allows users to request membership to the DAAC.
    function requestMembership() external whenNotPaused {
        require(!members[msg.sender], "Already a member");
        require(!isMembershipRequested(msg.sender), "Membership already requested");
        membershipRequests.push(msg.sender);
        emit MembershipRequested(msg.sender);
    }

    /// @notice Admin function to approve membership requests.
    /// @param _user The address to approve for membership.
    function approveMembership(address _user) external onlyAdmin whenNotPaused {
        require(!members[_user], "User is already a member");
        members[_user] = true;
        memberReputation[_user] = 100; // Initial reputation score for new members
        // Remove from pending requests (inefficient with array, consider linked list or mapping for large scale)
        for (uint256 i = 0; i < membershipRequests.length; i++) {
            if (membershipRequests[i] == _user) {
                membershipRequests[i] = membershipRequests[membershipRequests.length - 1];
                membershipRequests.pop();
                break;
            }
        }
        emit MembershipApproved(_user, msg.sender);
    }

    /// @notice Admin function to revoke membership.
    /// @param _user The address to revoke membership from.
    function revokeMembership(address _user) external onlyAdmin whenNotPaused {
        require(members[_user], "User is not a member");
        delete members[_user];
        delete memberReputation[_user];
        emit MembershipRevoked(_user, msg.sender);
    }

    /// @notice Retrieves the reputation score of a member.
    /// @param _user The address of the member.
    /// @return The reputation score of the member.
    function getMemberReputation(address _user) external view returns (uint256) {
        return memberReputation[_user];
    }

    /// @notice Allows members to contribute to another member's reputation.
    /// @param _user The address to contribute reputation to.
    /// @param _amount The amount of reputation to contribute.
    function contributeToReputation(address _user, uint256 _amount) external onlyMember whenNotPaused {
        require(_user != msg.sender, "Cannot contribute to your own reputation");
        memberReputation[_user] += _amount;
        emit ReputationContributed(msg.sender, _user, _amount);
    }

    /// @notice Checks if an address is a member.
    /// @param _user The address to check.
    /// @return True if the address is a member, false otherwise.
    function getMembershipStatus(address _user) external view returns (bool) {
        return members[_user];
    }

    /// @dev Helper function to check if membership is already requested.
    function isMembershipRequested(address _user) private view returns (bool) {
        for (uint256 i = 0; i < membershipRequests.length; i++) {
            if (membershipRequests[i] == _user) {
                return true;
            }
        }
        return false;
    }


    // --- Art Submission & Curation Functions ---

    /// @notice Allows members to submit art proposals with metadata URI and royalty percentage.
    /// @param _metadataURI URI pointing to the art metadata (e.g., IPFS).
    /// @param _royaltyPercentage Percentage of secondary sales royalties for the artist (0-100).
    function submitArtProposal(string memory _metadataURI, uint256 _royaltyPercentage) external onlyMember whenNotPaused {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100");
        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            proposer: msg.sender,
            metadataURI: _metadataURI,
            royaltyPercentage: _royaltyPercentage,
            upVotes: 0,
            downVotes: 0,
            finalized: false,
            rejected: false,
            submissionTimestamp: block.timestamp,
            votingOpen: true
        });
        emit ArtProposalSubmitted(proposalCounter, msg.sender, _metadataURI, _royaltyPercentage);
    }

    /// @notice Members can vote on art proposals.
    /// @param _proposalId The ID of the art proposal to vote on.
    /// @param _vote True for upvote, false for downvote.
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused validProposalId(_proposalId) votingPeriodActive(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            artProposals[_proposalId].upVotes++;
        } else {
            artProposals[_proposalId].downVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
        checkProposalVotingEnd(_proposalId); // Check if voting period ended after each vote
    }

    /// @dev Internal function to check if proposal voting period ended and finalize if threshold is met.
    /// @param _proposalId The ID of the art proposal to check.
    function checkProposalVotingEnd(uint256 _proposalId) private validProposalId(_proposalId) votingPeriodActive(_proposalId) {
        if (block.timestamp >= artProposals[_proposalId].submissionTimestamp + proposalVoteDuration) {
            artProposals[_proposalId].votingOpen = false; // Close voting
            uint256 totalVotes = artProposals[_proposalId].upVotes + artProposals[_proposalId].downVotes;
            if (totalVotes > 0) {
                uint256 approvalPercentage = (artProposals[_proposalId].upVotes * 100) / totalVotes;
                if (approvalPercentage >= daoParameters["artApprovalThreshold"]) {
                    finalizeArtProposal(_proposalId); // Auto-finalize if threshold met
                }
            }
        }
    }

    /// @notice Retrieves details of a specific art proposal.
    /// @param _proposalId The ID of the art proposal.
    /// @return ArtProposal struct containing proposal details.
    function getArtProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /// @notice Admin function to finalize an approved art proposal and mint an NFT.
    /// @param _proposalId The ID of the art proposal to finalize.
    function finalizeArtProposal(uint256 _proposalId) public onlyAdmin whenNotPaused validProposalId(_proposalId) {
        require(!artProposals[_proposalId].finalized && !artProposals[_proposalId].rejected, "Proposal already finalized or rejected");
        require(!artProposals[_proposalId].votingOpen || !votingPeriodActive(_proposalId), "Voting still open or period active"); // Ensure voting closed or time elapsed

        artNFTCounter++;
        artNFTMetadataURIs[artNFTCounter] = artProposals[_proposalId].metadataURI;
        artNFTRoyaltyPercentages[artNFTCounter] = calculateDynamicRoyalty(artProposals[_proposalId].royaltyPercentage, artProposals[_proposalId].proposer);
        artNFTArtists[artNFTCounter] = artProposals[_proposalId].proposer;
        artProposals[_proposalId].finalized = true;
        emit ArtProposalFinalized(_proposalId, artNFTCounter);
        emit ArtNFTMinted(artNFTCounter, artProposals[_proposalId].metadataURI, artProposals[_proposalId].proposer);
    }

    /// @notice Admin function to reject an art proposal.
    /// @param _proposalId The ID of the art proposal to reject.
    function rejectArtProposal(uint256 _proposalId) external onlyAdmin whenNotPaused validProposalId(_proposalId) {
        require(!artProposals[_proposalId].finalized && !artProposals[_proposalId].rejected, "Proposal already finalized or rejected");
        artProposals[_proposalId].rejected = true;
        artProposals[_proposalId].votingOpen = false; // Close voting if still open
        emit ArtProposalRejected(_proposalId, msg.sender);
    }

    /// @notice Returns the number of approved art pieces (NFTs minted).
    /// @return The count of approved art pieces.
    function getApprovedArtCount() external view returns (uint256) {
        return artNFTCounter;
    }

    /// @notice Returns the current voting status of a proposal (open/closed).
    /// @param _proposalId The ID of the proposal.
    /// @return True if voting is open, false otherwise.
    function getProposalVotingStatus(uint256 _proposalId) external view validProposalId(_proposalId) returns (bool) {
        return artProposals[_proposalId].votingOpen;
    }


    // --- NFT Management & Royalties Functions ---

    /// @notice Allows transfer of curated art NFTs.
    /// @param _tokenId The ID of the art NFT to transfer.
    /// @param _to The address to transfer the NFT to.
    function transferArtNFT(uint256 _tokenId, address _to) external whenNotPaused {
        require(artNFTArtists[_tokenId] != address(0), "Invalid token ID"); // Check if token exists (basic check, more robust NFT implementation needed in real-world)
        // In a real-world scenario, implement proper ERC721/ERC1155 contract and integrate here.
        // For simplicity, we are just simulating NFT transfer and royalty handling.
        // Assume a sale price of 1 ETH for demonstration purposes
        uint256 salePrice = 1 ether;
        uint256 royaltyAmount = (salePrice * artNFTRoyaltyPercentages[_tokenId]) / 100;
        artistRoyaltyBalances[artNFTArtists[_tokenId]] += royaltyAmount;
        emit ArtNFTTransferred(_tokenId, msg.sender, _to); // Assuming sender is the current "owner"
        // In a real NFT implementation, ownership and transfer logic would be handled by the NFT contract.
    }

    /// @notice Retrieves royalty information for a specific art NFT.
    /// @param _tokenId The ID of the art NFT.
    /// @return Royalty percentage and artist address.
    function getArtNFTRoyaltyInfo(uint256 _tokenId) external view returns (uint256 royaltyPercentage, address artist) {
        return (artNFTRoyaltyPercentages[_tokenId], artNFTArtists[_tokenId]);
    }

    /// @notice Admin function to set a multiplier for dynamic royalties based on reputation.
    /// @param _multiplier The new multiplier value (e.g., 100 for 1x, 150 for 1.5x).
    function setDynamicRoyaltyMultiplier(uint256 _multiplier) external onlyAdmin whenNotPaused {
        dynamicRoyaltyMultiplier = _multiplier;
    }

    /// @dev Calculates dynamic royalty based on base percentage and artist reputation.
    /// @param _baseRoyaltyPercentage The base royalty percentage submitted by the artist.
    /// @param _artist The address of the artist.
    /// @return The dynamically adjusted royalty percentage.
    function calculateDynamicRoyalty(uint256 _baseRoyaltyPercentage, address _artist) private view returns (uint256) {
        uint256 reputationScore = memberReputation[_artist];
        // Example dynamic royalty calculation: increase royalty slightly for higher reputation
        uint256 dynamicPercentageIncrease = (reputationScore / 200); // Example: 50 reputation increments percentage by 0.25%
        uint256 adjustedRoyalty = _baseRoyaltyPercentage + dynamicPercentageIncrease;
        return (adjustedRoyalty * dynamicRoyaltyMultiplier) / 100; // Apply multiplier
    }

    /// @notice Artists can withdraw their accumulated royalties.
    function withdrawArtistRoyalties() external whenNotPaused {
        uint256 balance = artistRoyaltyBalances[msg.sender];
        require(balance > 0, "No royalties to withdraw");
        artistRoyaltyBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
        emit ArtistRoyaltyWithdrawn(msg.sender, balance);
    }

    /// @notice Retrieves the royalty balance of an artist.
    /// @param _artist The address of the artist.
    /// @return The royalty balance of the artist.
    function getArtistRoyaltyBalance(address _artist) external view returns (uint256) {
        return artistRoyaltyBalances[_artist];
    }


    // --- Exhibitions & Events Functions ---

    /// @notice Admin function to create a curated digital art exhibition.
    /// @param _exhibitionName Name of the exhibition.
    /// @param _tokenIds Array of art NFT token IDs to include in the exhibition.
    function createExhibition(string memory _exhibitionName, uint256[] memory _tokenIds) external onlyAdmin whenNotPaused {
        exhibitionCounter++;
        exhibitions[exhibitionCounter] = Exhibition({
            name: _exhibitionName,
            artTokenIds: _tokenIds,
            curator: msg.sender,
            creationTimestamp: block.timestamp
        });
        emit ExhibitionCreated(exhibitionCounter, _exhibitionName, msg.sender);
    }

    /// @notice Retrieves details of a specific exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @return Exhibition struct containing exhibition details.
    function getExhibitionDetails(uint256 _exhibitionId) external view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /// @notice Allows members to participate in an exhibition (Future functionality - e.g., virtual gallery access).
    /// @param _exhibitionId The ID of the exhibition to participate in.
    function participateInExhibition(uint256 _exhibitionId) external onlyMember whenNotPaused {
        // Future functionality: Could implement access control, virtual gallery integration, etc.
        // For now, just a placeholder function to indicate exhibition participation.
        // Example: Could track participants, offer digital badges, etc.
        // Placeholder: For now, just emit an event.
        // emit ExhibitionParticipantAdded(exhibitionId, msg.sender); // If you want to track participation
    }


    // --- DAO Governance & Parameters Functions ---

    /// @notice Members can propose changes to DAO parameters.
    /// @param _parameterName Name of the DAO parameter to change.
    /// @param _newValue New value for the DAO parameter.
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external onlyMember whenNotPaused {
        parameterProposalCounter++;
        parameterProposals[parameterProposalCounter] = ParameterProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            upVotes: 0,
            downVotes: 0,
            finalized: false,
            submissionTimestamp: block.timestamp,
            votingOpen: true
        });
        emit ParameterProposalSubmitted(parameterProposalCounter, _parameterName, _newValue);
    }

    /// @notice Members can vote on parameter change proposals.
    /// @param _proposalId The ID of the parameter change proposal to vote on.
    /// @param _vote True for upvote, false for downvote.
    function voteOnParameterChange(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused parameterVotingPeriodActive(_proposalId) {
        require(!parameterProposalVotes[_proposalId][msg.sender], "Already voted on this parameter proposal");
        parameterProposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            parameterProposals[_proposalId].upVotes++;
        } else {
            parameterProposals[_proposalId].downVotes++;
        }
        emit ParameterProposalVoted(_proposalId, msg.sender, _vote);
        checkParameterVotingEnd(_proposalId); // Check if voting period ended after each vote
    }

    /// @dev Internal function to check if parameter voting period ended and execute if threshold is met.
    /// @param _proposalId The ID of the parameter proposal to check.
    function checkParameterVotingEnd(uint256 _proposalId) private parameterVotingPeriodActive(_proposalId) {
         if (block.timestamp >= parameterProposals[_proposalId].submissionTimestamp + parameterVoteDuration) {
            parameterProposals[_proposalId].votingOpen = false; // Close voting
            uint256 totalVotes = parameterProposals[_proposalId].upVotes + parameterProposals[_proposalId].downVotes;
            if (totalVotes > 0) {
                uint256 approvalPercentage = (parameterProposals[_proposalId].upVotes * 100) / totalVotes;
                if (approvalPercentage >= daoParameters["parameterChangeThreshold"]) {
                    executeParameterChange(_proposalId); // Auto-execute if threshold met
                }
            }
        }
    }

    /// @notice Admin function to execute approved parameter changes.
    /// @param _proposalId The ID of the parameter change proposal to execute.
    function executeParameterChange(uint256 _proposalId) external onlyAdmin whenNotPaused {
        require(!parameterProposals[_proposalId].finalized, "Parameter proposal already executed");
        require(!parameterProposals[_proposalId].votingOpen || !parameterVotingPeriodActive(_proposalId), "Voting still open or period active"); // Ensure voting closed or time elapsed

        daoParameters[parameterProposals[_proposalId].parameterName] = parameterProposals[_proposalId].newValue;
        parameterProposals[_proposalId].finalized = true;
        emit ParameterProposalExecuted(_proposalId, parameterProposals[_proposalId].parameterName, parameterProposals[_proposalId].newValue);
    }

    /// @notice Retrieves the value of a specific DAO parameter.
    /// @param _parameterName The name of the DAO parameter.
    /// @return The value of the DAO parameter.
    function getParameterValue(string memory _parameterName) external view returns (uint256) {
        return daoParameters[_parameterName];
    }


    // --- Emergency Pause Functionality ---

    /// @notice Admin function to pause critical contract functionalities in case of emergency.
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Admin function to unpause contract functionalities.
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Checks if the contract is currently paused.
    /// @return True if the contract is paused, false otherwise.
    function isContractPaused() external view returns (bool) {
        return paused;
    }


    // --- Fallback and Receive Functions (Optional for security and ETH handling) ---
    receive() external payable {} // To receive ETH if needed
    fallback() external {}       // To handle any unexpected calls
}
```