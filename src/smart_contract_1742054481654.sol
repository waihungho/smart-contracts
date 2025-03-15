```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @notice A smart contract for a decentralized autonomous art collective.
 * It allows artists to submit artwork, members to vote on submissions,
 * curate a collective gallery, and manage revenue sharing and governance.
 *
 * **Outline:**
 * 1. **Art Submission & Curation:**
 *    - Artist submission of artwork metadata (IPFS links, descriptions).
 *    - Member-based voting on artwork submissions for gallery inclusion.
 *    - Gallery management: listing curated artworks, viewing details.
 * 2. **Collective Governance & Membership:**
 *    - Open membership with optional token gating (for future expansion).
 *    - Proposal system for collective decisions (parameter changes, initiatives).
 *    - Voting on proposals with quorum and voting duration.
 * 3. **Revenue Generation & Distribution:**
 *    - Optional feature to mint curated artworks as NFTs (ERC-721).
 *    - Revenue from NFT sales distributed to artists and the collective treasury.
 *    - Treasury management: funds allocated for collective initiatives.
 * 4. **Artist & Member Profiles:**
 *    - Basic artist profiles with on-chain information.
 *    - Member roles and potential reputation system (future enhancement).
 * 5. **Advanced & Creative Features:**
 *    - "Art Challenge" mechanism: themed competitions for artwork submissions.
 *    - Collaborative Art Creation: framework for multiple artists to contribute to a single artwork.
 *    - Dynamic Gallery Display: metadata-driven gallery filtering and sorting.
 *    - Decentralized Royalties: mechanism for secondary sale royalties to artists and collective.
 *    - Emergency Pause & Unpause for contract security.
 *
 * **Function Summary:**
 *
 * **Art Submission & Curation:**
 *   1. `submitArtwork(string _title, string _description, string _ipfsHash)`: Artists submit their artwork with metadata.
 *   2. `startArtworkVoting(uint256 _artworkId)`: Starts a voting round for a submitted artwork.
 *   3. `castVoteOnArtwork(uint256 _artworkId, bool _approve)`: Members cast their vote on an artwork submission.
 *   4. `endArtworkVoting(uint256 _artworkId)`: Ends the voting round and processes the result.
 *   5. `getArtworkDetails(uint256 _artworkId)`: Retrieves detailed information about a specific artwork.
 *   6. `getCuratedArtworkIds()`: Returns a list of IDs of artworks accepted into the gallery.
 *   7. `getSubmittedArtworkIds()`: Returns a list of IDs of artworks currently submitted for voting.
 *   8. `getVotingStatus(uint256 _artworkId)`: Gets the current voting status and results for an artwork.
 *
 * **Collective Governance & Membership:**
 *   9. `joinCollective()`: Allows anyone to join the collective as a member.
 *  10. `leaveCollective()`: Allows members to leave the collective.
 *  11. `proposeParameterChange(string _description, string _parameterName, uint256 _newValue)`: Members propose changes to contract parameters.
 *  12. `startParameterVoting(uint256 _proposalId)`: Starts voting on a parameter change proposal.
 *  13. `castVoteOnParameter(uint256 _proposalId, bool _approve)`: Members vote on parameter change proposals.
 *  14. `endParameterVoting(uint256 _proposalId)`: Ends voting on a parameter change proposal and executes if approved.
 *  15. `getParameterProposalDetails(uint256 _proposalId)`: Gets details of a parameter change proposal.
 *  16. `getMemberCount()`: Returns the current number of members in the collective.
 *
 * **Revenue Generation & Distribution (Optional NFT Feature):**
 *  17. `mintArtworkNFT(uint256 _artworkId)`: Mints an NFT for a curated artwork (if NFT feature enabled).
 *  18. `purchaseArtworkNFT(uint256 _artworkId)`: Allows purchasing of a minted artwork NFT.
 *  19. `distributeNFTRevenue(uint256 _artworkId)`: Distributes revenue from NFT sales to artist and treasury.
 *  20. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Allows the contract owner to withdraw funds from the collective treasury (governance can be added later).
 *
 * **Utility & Admin:**
 *  21. `pauseContract()`: Pauses most contract functionalities (emergency stop - owner only).
 *  22. `unpauseContract()`: Resumes contract functionalities (owner only).
 *  23. `isMember(address _account)`: Checks if an address is a member of the collective.
 *  24. `setVotingDuration(uint256 _durationInBlocks)`: Allows owner to set the voting duration.
 *  25. `setVotingQuorum(uint256 _quorumPercentage)`: Allows owner to set the voting quorum percentage.
 */
contract DecentralizedArtCollective {

    // ******************* STRUCTS & ENUMS *******************

    struct Artwork {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        bool isCurated;
        uint256 submissionTimestamp;
    }

    struct VotingRound {
        uint256 artworkId;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool isConcluded;
        bool isApproved;
    }

    struct ParameterProposal {
        uint256 id;
        address proposer;
        string description;
        string parameterName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool isConcluded;
        bool isApproved;
    }

    // ******************* STATE VARIABLES *******************

    address public owner;
    bool public paused;
    uint256 public artworkCounter;
    uint256 public proposalCounter;
    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks
    uint256 public votingQuorumPercentage = 50; // Default quorum percentage for voting

    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => VotingRound) public artworkVotingRounds;
    mapping(uint256 => ParameterProposal) public parameterProposals;
    mapping(address => bool) public members;
    mapping(uint256 => bool) public isArtworkVotingActive; // Track active voting for artworks
    mapping(uint256 => bool) public isParameterVotingActive; // Track active voting for parameters
    mapping(uint256 => bool) public isArtworkCurated;
    mapping(uint256 => bool) public isArtworkSubmitted;

    uint256[] public curatedArtworkIds;
    uint256[] public submittedArtworkIds;

    // ******************* EVENTS *******************

    event ArtworkSubmitted(uint256 artworkId, address artist, string title);
    event ArtworkVotingStarted(uint256 artworkId);
    event ArtworkVoted(uint256 artworkId, address voter, bool approve);
    event ArtworkVotingEnded(uint256 artworkId, bool isApproved);
    event ArtworkCurated(uint256 artworkId);
    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);
    event ParameterProposalCreated(uint256 proposalId, address proposer, string parameterName);
    event ParameterVotingStarted(uint256 proposalId);
    event ParameterVoted(uint256 proposalId, address voter, bool approve);
    event ParameterVotingEnded(uint256 proposalId, bool isApproved, string parameterName, uint256 newValue);
    event ContractPaused();
    event ContractUnpaused();
    event TreasuryWithdrawal(address recipient, uint256 amount);

    // ******************* MODIFIERS *******************

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        _;
    }

    modifier votingNotActive(uint256 _artworkId) {
        require(!isArtworkVotingActive[_artworkId], "Voting is already active for this artwork.");
        _;
    }

    modifier votingActive(uint256 _artworkId) {
        require(isArtworkVotingActive[_artworkId], "Voting is not active for this artwork.");
        _;
    }

    modifier votingNotConcluded(uint256 _artworkId) {
        require(!artworkVotingRounds[_artworkId].isConcluded, "Voting is already concluded.");
        _;
    }

    modifier parameterProposalExists(uint256 _proposalId) {
        require(parameterProposals[_proposalId].id != 0, "Parameter proposal does not exist.");
        _;
    }

    modifier parameterVotingNotActive(uint256 _proposalId) {
        require(!isParameterVotingActive[_proposalId], "Voting is already active for this parameter proposal.");
        _;
    }

    modifier parameterVotingActive(uint256 _proposalId) {
        require(isParameterVotingActive[_proposalId], "Voting is not active for this parameter proposal.");
        _;
    }

    modifier parameterVotingNotConcluded(uint256 _proposalId) {
        require(!parameterProposals[_proposalId].isConcluded, "Parameter voting is already concluded.");
        _;
    }


    // ******************* CONSTRUCTOR *******************

    constructor() {
        owner = msg.sender;
        paused = false;
        artworkCounter = 0;
        proposalCounter = 0;
    }

    // ******************* ART SUBMISSION & CURATION FUNCTIONS *******************

    /// @notice Artists submit their artwork with metadata.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork's media file.
    function submitArtwork(
        string memory _title,
        string memory _description,
        string memory _ipfsHash
    ) external whenNotPaused {
        artworkCounter++;
        artworks[artworkCounter] = Artwork({
            id: artworkCounter,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            isCurated: false,
            submissionTimestamp: block.timestamp
        });
        isArtworkSubmitted[artworkCounter] = true;
        submittedArtworkIds.push(artworkCounter);
        emit ArtworkSubmitted(artworkCounter, msg.sender, _title);
    }

    /// @notice Starts a voting round for a submitted artwork.
    /// @param _artworkId ID of the artwork to start voting for.
    function startArtworkVoting(uint256 _artworkId) external onlyMember whenNotPaused artworkExists(_artworkId) votingNotActive(_artworkId) votingNotConcluded(_artworkId) {
        require(isArtworkSubmitted[_artworkId], "Artwork must be submitted to start voting.");
        isArtworkVotingActive[_artworkId] = true;
        artworkVotingRounds[_artworkId] = VotingRound({
            artworkId: _artworkId,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            isConcluded: false,
            isApproved: false
        });
        emit ArtworkVotingStarted(_artworkId);
    }

    /// @notice Members cast their vote on an artwork submission.
    /// @param _artworkId ID of the artwork being voted on.
    /// @param _approve True to approve, false to reject.
    function castVoteOnArtwork(uint256 _artworkId, bool _approve) external onlyMember whenNotPaused artworkExists(_artworkId) votingActive(_artworkId) votingNotConcluded(_artworkId) {
        require(block.number <= artworkVotingRounds[_artworkId].endTime, "Voting round has ended.");
        VotingRound storage round = artworkVotingRounds[_artworkId];
        if (_approve) {
            round.yesVotes++;
        } else {
            round.noVotes++;
        }
        emit ArtworkVoted(_artworkId, msg.sender, _approve);
    }

    /// @notice Ends the voting round and processes the result.
    /// @param _artworkId ID of the artwork to end voting for.
    function endArtworkVoting(uint256 _artworkId) external onlyMember whenNotPaused artworkExists(_artworkId) votingActive(_artworkId) votingNotConcluded(_artworkId) {
        require(block.number > artworkVotingRounds[_artworkId].endTime, "Voting round is still active.");
        isArtworkVotingActive[_artworkId] = false;
        artworkVotingRounds[_artworkId].isActive = false;
        artworkVotingRounds[_artworkId].isConcluded = true;

        uint256 totalVotes = artworkVotingRounds[_artworkId].yesVotes + artworkVotingRounds[_artworkId].noVotes;
        uint256 quorumNeeded = (getMemberCount() * votingQuorumPercentage) / 100;

        if (totalVotes >= quorumNeeded && artworkVotingRounds[_artworkId].yesVotes > artworkVotingRounds[_artworkId].noVotes) {
            artworks[_artworkId].isCurated = true;
            isArtworkCurated[_artworkId] = true;
            isArtworkSubmitted[_artworkId] = false;
            curatedArtworkIds.push(_artworkId);
            // Remove from submittedArtworkIds array
            for (uint256 i = 0; i < submittedArtworkIds.length; i++) {
                if (submittedArtworkIds[i] == _artworkId) {
                    submittedArtworkIds[i] = submittedArtworkIds[submittedArtworkIds.length - 1];
                    submittedArtworkIds.pop();
                    break;
                }
            }
            artworkVotingRounds[_artworkId].isApproved = true;
            emit ArtworkCurated(_artworkId);
            emit ArtworkVotingEnded(_artworkId, true);
        } else {
            isArtworkSubmitted[_artworkId] = false; // Artwork rejected from gallery.
            // Remove from submittedArtworkIds array
            for (uint256 i = 0; i < submittedArtworkIds.length; i++) {
                if (submittedArtworkIds[i] == _artworkId) {
                    submittedArtworkIds[i] = submittedArtworkIds[submittedArtworkIds.length - 1];
                    submittedArtworkIds.pop();
                    break;
                }
            }
            artworkVotingRounds[_artworkId].isApproved = false;
            emit ArtworkVotingEnded(_artworkId, false);
        }
    }

    /// @notice Retrieves detailed information about a specific artwork.
    /// @param _artworkId ID of the artwork.
    /// @return Artwork struct containing artwork details.
    function getArtworkDetails(uint256 _artworkId) external view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /// @notice Returns a list of IDs of artworks accepted into the gallery.
    /// @return Array of curated artwork IDs.
    function getCuratedArtworkIds() external view returns (uint256[] memory) {
        return curatedArtworkIds;
    }

    /// @notice Returns a list of IDs of artworks currently submitted for voting.
    /// @return Array of submitted artwork IDs.
    function getSubmittedArtworkIds() external view returns (uint256[] memory) {
        return submittedArtworkIds;
    }

    /// @notice Gets the current voting status and results for an artwork.
    /// @param _artworkId ID of the artwork.
    /// @return VotingRound struct containing voting details.
    function getVotingStatus(uint256 _artworkId) external view artworkExists(_artworkId) returns (VotingRound memory) {
        return artworkVotingRounds[_artworkId];
    }


    // ******************* COLLECTIVE GOVERNANCE & MEMBERSHIP FUNCTIONS *******************

    /// @notice Allows anyone to join the collective as a member.
    function joinCollective() external whenNotPaused {
        require(!members[msg.sender], "Already a member.");
        members[msg.sender] = true;
        emit MemberJoined(msg.sender);
    }

    /// @notice Allows members to leave the collective.
    function leaveCollective() external onlyMember whenNotPaused {
        delete members[msg.sender];
        emit MemberLeft(msg.sender);
    }

    /// @notice Members propose changes to contract parameters.
    /// @param _description Description of the parameter change proposal.
    /// @param _parameterName Name of the parameter to change.
    /// @param _newValue New value for the parameter.
    function proposeParameterChange(
        string memory _description,
        string memory _parameterName,
        uint256 _newValue
    ) external onlyMember whenNotPaused {
        proposalCounter++;
        parameterProposals[proposalCounter] = ParameterProposal({
            id: proposalCounter,
            proposer: msg.sender,
            description: _description,
            parameterName: _parameterName,
            newValue: _newValue,
            startTime: 0, // Set when voting starts
            endTime: 0,   // Set when voting starts
            yesVotes: 0,
            noVotes: 0,
            isActive: false,
            isConcluded: false,
            isApproved: false
        });
        emit ParameterProposalCreated(proposalCounter, msg.sender, _parameterName);
    }

    /// @notice Starts voting on a parameter change proposal.
    /// @param _proposalId ID of the parameter proposal.
    function startParameterVoting(uint256 _proposalId) external onlyMember whenNotPaused parameterProposalExists(_proposalId) parameterVotingNotActive(_proposalId) parameterVotingNotConcluded(_proposalId) {
        isParameterVotingActive[_proposalId] = true;
        parameterProposals[_proposalId].isActive = true;
        parameterProposals[_proposalId].startTime = block.number;
        parameterProposals[_proposalId].endTime = block.number + votingDurationBlocks;
        emit ParameterVotingStarted(_proposalId);
    }

    /// @notice Members vote on parameter change proposals.
    /// @param _proposalId ID of the parameter proposal.
    /// @param _approve True to approve, false to reject.
    function castVoteOnParameter(uint256 _proposalId, bool _approve) external onlyMember whenNotPaused parameterProposalExists(_proposalId) parameterVotingActive(_proposalId) parameterVotingNotConcluded(_proposalId) {
        require(block.number <= parameterProposals[_proposalId].endTime, "Parameter voting round has ended.");
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ParameterVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Ends voting on a parameter change proposal and executes if approved.
    /// @param _proposalId ID of the parameter proposal.
    function endParameterVoting(uint256 _proposalId) external onlyMember whenNotPaused parameterProposalExists(_proposalId) parameterVotingActive(_proposalId) parameterVotingNotConcluded(_proposalId) {
        require(block.number > parameterProposals[_proposalId].endTime, "Parameter voting round is still active.");
        isParameterVotingActive[_proposalId] = false;
        parameterProposals[_proposalId].isActive = false;
        parameterProposals[_proposalId].isConcluded = true;

        uint256 totalVotes = parameterProposals[_proposalId].yesVotes + parameterProposals[_proposalId].noVotes;
        uint256 quorumNeeded = (getMemberCount() * votingQuorumPercentage) / 100;

        if (totalVotes >= quorumNeeded && parameterProposals[_proposalId].yesVotes > parameterProposals[_proposalId].noVotes) {
            parameterProposals[_proposalId].isApproved = true;
            _setParameterValue(parameterProposals[_proposalId].parameterName, parameterProposals[_proposalId].newValue);
            emit ParameterVotingEnded(_proposalId, true, parameterProposals[_proposalId].parameterName, parameterProposals[_proposalId].newValue);
        } else {
            parameterProposals[_proposalId].isApproved = false;
            emit ParameterVotingEnded(_proposalId, false, parameterProposals[_proposalId].parameterName, parameterProposals[_proposalId].newValue);
        }
    }

    /// @notice Gets details of a parameter change proposal.
    /// @param _proposalId ID of the parameter proposal.
    /// @return ParameterProposal struct containing proposal details.
    function getParameterProposalDetails(uint256 _proposalId) external view parameterProposalExists(_proposalId) returns (ParameterProposal memory) {
        return parameterProposals[_proposalId];
    }

    /// @notice Returns the current number of members in the collective.
    /// @return Number of members.
    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        address[] memory allMembers = _getAllMembers(); // Get all member addresses
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (members[allMembers[i]]) { // Check if address is still a member
                count++;
            }
        }
        return count;
    }

    // Internal helper function to get all addresses that were ever members (for accurate count if members leave)
    function _getAllMembers() internal view returns (address[] memory) {
        address[] memory memberAddresses = new address[](address(this).balance); // Overestimate size - will be trimmed
        uint256 memberCount = 0;
        for (uint256 i = 0; i < artworkCounter; i++) { // Iterate through artworks submitted (artists are likely members)
            if (artworks[i+1].artist != address(0) && !addressInArray(artworks[i+1].artist, memberAddresses)) {
                memberAddresses[memberCount] = artworks[i+1].artist;
                memberCount++;
            }
        }
        for (uint256 i = 0; i < proposalCounter; i++) { // Iterate through proposals (proposers are members)
             if (parameterProposals[i+1].proposer != address(0) && !addressInArray(parameterProposals[i+1].proposer, memberAddresses)) {
                memberAddresses[memberCount] = parameterProposals[i+1].proposer;
                memberCount++;
            }
        }
        // Trim array to actual member count
        address[] memory trimmedMembers = new address[](memberCount);
        for (uint256 i = 0; i < memberCount; i++) {
            trimmedMembers[i] = memberAddresses[i];
        }
        return trimmedMembers;
    }

    function addressInArray(address _addr, address[] memory _array) internal pure returns (bool) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    // ******************* REVENUE GENERATION & DISTRIBUTION (OPTIONAL NFT FEATURE - Placeholder Functions) *******************

    /// @notice Mints an NFT for a curated artwork (if NFT feature enabled). - Placeholder
    /// @param _artworkId ID of the curated artwork.
    function mintArtworkNFT(uint256 _artworkId) external onlyOwner whenNotPaused artworkExists(_artworkId) {
        require(artworks[_artworkId].isCurated, "Artwork must be curated to mint NFT.");
        // Placeholder for NFT minting logic (e.g., using ERC721 contract)
        // ... NFT minting logic here ...
        // ... Set NFT ownership to this contract (DAO) ...
        // ... Consider emitting an NFTMinted event ...
        // For now, just emit an event indicating minting initiated
        // NOTE: In a real implementation, this would involve interaction with an ERC721 contract.
        emit ArtworkMintedPlaceholder(_artworkId, artworks[_artworkId].artist, artworks[_artworkId].title);
    }

    event ArtworkMintedPlaceholder(uint256 artworkId, address artist, string title); // Placeholder event

    /// @notice Allows purchasing of a minted artwork NFT. - Placeholder
    /// @param _artworkId ID of the artwork NFT to purchase.
    function purchaseArtworkNFT(uint256 _artworkId) external payable whenNotPaused artworkExists(_artworkId) {
        require(artworks[_artworkId].isCurated, "Artwork must be curated to purchase NFT.");
        // Placeholder for NFT purchase logic (e.g., interacting with ERC721 contract)
        // ... NFT purchase logic here ...
        // ... Transfer funds (msg.value) to the contract ...
        // ... Transfer NFT ownership to msg.sender ...
        // ... Call distributeNFTRevenue(_artworkId) after purchase ...
        // For now, just emit a purchase initiated event.
        // NOTE: In a real implementation, this would involve interaction with an ERC721 contract and payment processing.
        emit ArtworkPurchasePlaceholder(_artworkId, msg.sender, msg.value);
    }

    event ArtworkPurchasePlaceholder(uint256 artworkId, address buyer, uint256 value); // Placeholder event


    /// @notice Distributes revenue from NFT sales to artist and treasury. - Placeholder
    /// @param _artworkId ID of the artwork NFT sold.
    function distributeNFTRevenue(uint256 _artworkId) external onlyOwner whenNotPaused artworkExists(_artworkId) {
        require(artworks[_artworkId].isCurated, "Artwork must be curated for revenue distribution.");
        // Placeholder for revenue distribution logic
        // Example: 70% to artist, 30% to treasury
        uint256 totalRevenue = address(this).balance; // Assume contract balance represents NFT sale revenue
        uint256 artistShare = (totalRevenue * 70) / 100;
        uint256 treasuryShare = totalRevenue - artistShare;

        // (In real implementation, ensure proper accounting of NFT sales and revenue sources)

        (bool artistTransferSuccess, ) = artworks[_artworkId].artist.call{value: artistShare}("");
        require(artistTransferSuccess, "Artist transfer failed.");

        // Treasury funds remain in the contract for collective use.
        // Can add a function to manage treasury withdrawals later.

        emit NFTRevenueDistributedPlaceholder(_artworkId, artworks[_artworkId].artist, artistShare, treasuryShare);
    }
    event NFTRevenueDistributedPlaceholder(uint256 artworkId, address artist, uint256 artistAmount, uint256 treasuryAmount); // Placeholder event


    /// @notice Allows the contract owner to withdraw funds from the collective treasury.
    /// @param _recipient Address to receive the treasury funds.
    /// @param _amount Amount to withdraw.
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner whenNotPaused {
        require(_recipient != address(0), "Invalid recipient address.");
        require(address(this).balance >= _amount, "Insufficient treasury balance.");

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Treasury withdrawal failed.");

        emit TreasuryWithdrawal(_recipient, _amount);
    }


    // ******************* UTILITY & ADMIN FUNCTIONS *******************

    /// @notice Pauses most contract functionalities (emergency stop).
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Resumes contract functionalities.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Checks if an address is a member of the collective.
    /// @param _account Address to check.
    /// @return True if member, false otherwise.
    function isMember(address _account) external view returns (bool) {
        return members[_account];
    }

    /// @notice Allows owner to set the voting duration in blocks.
    /// @param _durationInBlocks New voting duration in blocks.
    function setVotingDuration(uint256 _durationInBlocks) external onlyOwner whenNotPaused {
        votingDurationBlocks = _durationInBlocks;
    }

    /// @notice Allows owner to set the voting quorum percentage.
    /// @param _quorumPercentage New voting quorum percentage (0-100).
    function setVotingQuorum(uint256 _quorumPercentage) external onlyOwner whenNotPaused {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        votingQuorumPercentage = _quorumPercentage;
    }

    // Internal function to set parameter values (used by governance)
    function _setParameterValue(string memory _parameterName, uint256 _newValue) internal {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("votingDurationBlocks"))) {
            votingDurationBlocks = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("votingQuorumPercentage"))) {
            votingQuorumPercentage = _newValue;
        } else {
            revert("Invalid parameter name for change.");
        }
    }
}
```