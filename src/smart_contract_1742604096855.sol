```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @notice A smart contract for a decentralized art collective, enabling collaborative art creation,
 * governance, dynamic NFTs, and community-driven art evolution.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1.  `proposeArtistMembership(address _artistAddress, string memory _artistName, string memory _artistBio)`: Allows existing members to propose new artists.
 * 2.  `voteOnArtistMembership(uint256 _proposalId, bool _approve)`: Members can vote on artist membership proposals.
 * 3.  `executeArtistMembershipProposal(uint256 _proposalId)`: Executes approved artist membership proposals.
 * 4.  `removeArtistMembership(address _artistAddress)`: Governance function to remove an artist from the collective.
 * 5.  `proposeArtworkCreation(string memory _artworkTitle, string memory _artworkDescription, string memory _initialMetadataURI)`:  Artists propose new artwork concepts.
 * 6.  `voteOnArtworkCreation(uint256 _proposalId, bool _approve)`: Members vote on artwork creation proposals.
 * 7.  `executeArtworkCreationProposal(uint256 _proposalId)`: Executes approved artwork creation proposals, minting a Dynamic NFT.
 * 8.  `contributeToArtwork(uint256 _artworkId, string memory _contributionMetadataURI)`: Artists contribute to existing artworks, evolving their metadata.
 * 9.  `voteOnContribution(uint256 _artworkId, uint256 _contributionIndex, bool _approve)`: Members vote on contributions to artworks.
 * 10. `executeContributionProposal(uint256 _artworkId, uint256 _contributionIndex)`: Executes approved contributions, updating artwork metadata.
 * 11. `transferArtworkOwnership(uint256 _artworkId, address _newOwner)`: Allows collective to transfer artwork ownership (e.g., for sales, collaborations).
 * 12. `proposeMetadataUpdate(uint256 _artworkId, string memory _newMetadataURI)`: Propose a direct metadata update for an artwork.
 * 13. `voteOnMetadataUpdate(uint256 _proposalId, bool _approve)`: Vote on metadata update proposals.
 * 14. `executeMetadataUpdateProposal(uint256 _proposalId)`: Executes approved metadata update proposals.
 * 15. `burnArtwork(uint256 _artworkId)`: Governance function to burn an artwork (remove from existence).
 * 16. `setGovernanceThreshold(uint256 _newThreshold)`:  Governance function to change the voting threshold for proposals.
 * 17. `donateToCollective()`: Allows anyone to donate to the collective's treasury.
 * 18. `withdrawDonations(address _recipient, uint256 _amount)`: Governance function to withdraw funds from the treasury.
 * 19. `getArtworkDetails(uint256 _artworkId)`: View function to retrieve detailed information about an artwork.
 * 20. `getArtistDetails(address _artistAddress)`: View function to retrieve details about an artist.
 * 21. `getProposalDetails(uint256 _proposalId)`: View function to retrieve details about a proposal.
 * 22. `getCollectiveBalance()`: View function to check the collective's treasury balance.
 * 23. `getMyVotingPower()`: View function for members to see their voting power (currently simple, could be enhanced).
 * 24. `getArtworkCurrentMetadataURI(uint256 _artworkId)`: View function to get the current metadata URI of an artwork.

 * **Events:**
 * - `ArtistProposed(uint256 proposalId, address artistAddress, string artistName)`
 * - `ArtistMembershipVoted(uint256 proposalId, address voter, bool approved)`
 * - `ArtistAdded(address artistAddress, string artistName)`
 * - `ArtistRemoved(address artistAddress)`
 * - `ArtworkProposed(uint256 proposalId, string artworkTitle)`
 * - `ArtworkCreationVoted(uint256 proposalId, address voter, bool approved)`
 * - `ArtworkCreated(uint256 artworkId, string artworkTitle, address creator)`
 * - `ArtworkContributionProposed(uint256 artworkId, uint256 contributionIndex, address contributor)`
 * - `ContributionVoted(uint256 artworkId, uint256 contributionIndex, address voter, bool approved)`
 * - `ArtworkContributed(uint256 artworkId, uint256 contributionIndex, address contributor)`
 * - `ArtworkOwnershipTransferred(uint256 artworkId, address oldOwner, address newOwner)`
 * - `MetadataUpdateProposed(uint256 proposalId, uint256 artworkId, string newMetadataURI)`
 * - `MetadataUpdateVoted(uint256 proposalId, address voter, bool approved)`
 * - `MetadataUpdated(uint256 artworkId, string newMetadataURI)`
 * - `ArtworkBurned(uint256 artworkId)`
 * - `GovernanceThresholdChanged(uint256 newThreshold)`
 * - `DonationReceived(address donor, uint256 amount)`
 * - `WithdrawalMade(address recipient, uint256 amount)`
 */
contract DecentralizedAutonomousArtCollective {
    // --- State Variables ---

    // Artist Membership
    mapping(address => Artist) public artists; // Artist address to Artist struct
    address[] public artistList; // List of artist addresses for easy iteration

    // Artwork Management
    uint256 public artworkCounter;
    mapping(uint256 => Artwork) public artworks; // Artwork ID to Artwork struct

    // Proposals - Generic Proposal Structure for various actions
    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;

    uint256 public governanceThreshold = 50; // Percentage threshold for proposal approval (e.g., 50% for majority)

    address payable public treasury; // Contract's treasury address

    // --- Structs ---

    struct Artist {
        string name;
        string bio;
        bool isActive;
        uint256 reputation; // Future: Could be used for more nuanced voting power
    }

    struct Artwork {
        uint256 id;
        string title;
        string description;
        address creator; // Initial creator (could be collective or individual artist)
        string currentMetadataURI; // IPFS URI or similar
        string[] contributionMetadataURIs; // Array of metadata URIs for contributions over time
        address owner; // Current owner of the artwork (initially the collective)
        bool exists; // To track if artwork has been burned
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        bytes proposalData; // Encoded data specific to the proposal type
        mapping(address => bool) votes; // Voter address to vote status (true = voted, false = not voted)
        uint256 yesVotes;
        uint256 noVotes;
        bool isExecuted;
        uint256 creationTimestamp;
    }

    enum ProposalType {
        ARTIST_MEMBERSHIP,
        ARTWORK_CREATION,
        ARTWORK_CONTRIBUTION,
        METADATA_UPDATE,
        GOVERNANCE_CHANGE,
        TREASURY_WITHDRAWAL,
        ARTIST_REMOVAL,
        ARTWORK_BURN
    }

    // --- Events ---
    event ArtistProposed(uint256 proposalId, address artistAddress, string artistName);
    event ArtistMembershipVoted(uint256 proposalId, address voter, bool approved);
    event ArtistAdded(address artistAddress, string artistName);
    event ArtistRemoved(address artistAddress);

    event ArtworkProposed(uint256 proposalId, string artworkTitle);
    event ArtworkCreationVoted(uint256 proposalId, address voter, bool approved);
    event ArtworkCreated(uint256 artworkId, string artworkTitle, address creator);
    event ArtworkContributionProposed(uint256 artworkId, uint256 contributionIndex, address contributor);
    event ContributionVoted(uint256 artworkId, uint256 contributionIndex, address voter, bool approved);
    event ArtworkContributed(uint256 artworkId, uint256 contributionIndex, address contributor);
    event ArtworkOwnershipTransferred(uint256 artworkId, address oldOwner, address newOwner);

    event MetadataUpdateProposed(uint256 proposalId, uint256 artworkId, string newMetadataURI);
    event MetadataUpdateVoted(uint256 proposalId, address voter, bool approved);
    event MetadataUpdated(uint256 artworkId, string newMetadataURI);

    event ArtworkBurned(uint256 artworkId);
    event GovernanceThresholdChanged(uint256 newThreshold);
    event DonationReceived(address donor, uint256 amount);
    event WithdrawalMade(address recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyArtist() {
        require(artists[msg.sender].isActive, "Only active artists can perform this action.");
        _;
    }

    modifier onlyGovernance() {
        require(isGovernance(msg.sender), "Only governance members can perform this action.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(proposals[_proposalId].id == _proposalId, "Invalid proposal ID.");
        require(!proposals[_proposalId].isExecuted, "Proposal already executed.");
        _;
    }

    modifier validArtwork(uint256 _artworkId) {
        require(artworks[_artworkId].exists, "Invalid artwork ID or artwork burned.");
        _;
    }

    // --- Constructor ---
    constructor() payable {
        treasury = payable(address(this)); // Contract address is the treasury
        // Optionally add initial governance members during deployment.
        // For simplicity, we'll assume the deployer is the initial governance.
        artists[msg.sender] = Artist({
            name: "Initial Governance",
            bio: "Initial governance member - Contract Deployer",
            isActive: true,
            reputation: 100 // Initial reputation
        });
        artistList.push(msg.sender);
    }

    // --- Helper Functions ---
    function isGovernance(address _account) public view returns (bool) {
        return artists[_account].isActive; // For now, all active artists are governance. Can be more sophisticated later.
    }

    function _createProposal(ProposalType _proposalType, bytes memory _proposalData) internal returns (uint256) {
        proposalCounter++;
        uint256 proposalId = proposalCounter;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: _proposalType,
            proposalData: _proposalData,
            yesVotes: 0,
            noVotes: 0,
            isExecuted: false,
            creationTimestamp: block.timestamp
        });
        return proposalId;
    }

    function _executeProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");

        uint256 totalActiveArtists = artistList.length;
        uint256 percentageYesVotes = (proposal.yesVotes * 100) / totalActiveArtists;

        if (percentageYesVotes >= governanceThreshold) {
            proposal.isExecuted = true;
            ProposalType proposalType = proposal.proposalType;

            if (proposalType == ProposalType.ARTIST_MEMBERSHIP) {
                _executeArtistMembership(proposal.proposalData);
            } else if (proposalType == ProposalType.ARTWORK_CREATION) {
                _executeArtworkCreation(proposal.proposalData);
            } else if (proposalType == ProposalType.ARTWORK_CONTRIBUTION) {
                _executeArtworkContribution(proposal.proposalData);
            } else if (proposalType == ProposalType.METADATA_UPDATE) {
                _executeMetadataUpdate(proposal.proposalData);
            } else if (proposalType == ProposalType.GOVERNANCE_CHANGE) {
                _executeGovernanceChange(proposal.proposalData);
            } else if (proposalType == ProposalType.TREASURY_WITHDRAWAL) {
                _executeTreasuryWithdrawal(proposal.proposalData);
            } else if (proposalType == ProposalType.ARTIST_REMOVAL) {
                _executeArtistRemoval(proposal.proposalData);
            } else if (proposalType == ProposalType.ARTWORK_BURN) {
                _executeArtworkBurn(proposal.proposalData);
            }
        } else {
            // Proposal failed to reach threshold - optionally handle differently (e.g., emit event)
        }
    }


    // --- Artist Membership Functions ---

    function proposeArtistMembership(address _artistAddress, string memory _artistName, string memory _artistBio) external onlyArtist {
        require(artists[_artistAddress].isActive == false, "Address is already an artist.");
        bytes memory proposalData = abi.encode(_artistAddress, _artistName, _artistBio);
        uint256 proposalId = _createProposal(ProposalType.ARTIST_MEMBERSHIP, proposalData);
        emit ArtistProposed(proposalId, _artistAddress, _artistName);
    }

    function voteOnArtistMembership(uint256 _proposalId, bool _approve) external onlyArtist validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.votes[msg.sender], "Artist has already voted on this proposal.");
        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtistMembershipVoted(_proposalId, msg.sender, _approve);
    }

    function executeArtistMembershipProposal(uint256 _proposalId) external onlyGovernance validProposal(_proposalId) {
        _executeProposal(_proposalId);
    }

    function _executeArtistMembership(bytes memory _proposalData) internal {
        (address _artistAddress, string memory _artistName, string memory _artistBio) = abi.decode(_proposalData, (address, string, string));
        artists[_artistAddress] = Artist({
            name: _artistName,
            bio: _artistBio,
            isActive: true,
            reputation: 0 // Initial reputation for new artists
        });
        artistList.push(_artistAddress);
        emit ArtistAdded(_artistAddress, _artistName);
    }

    function removeArtistMembership(address _artistAddress) external onlyGovernance {
        require(artists[_artistAddress].isActive, "Address is not an active artist.");
        bytes memory proposalData = abi.encode(_artistAddress);
        uint256 proposalId = _createProposal(ProposalType.ARTIST_REMOVAL, proposalData);
        // No specific event for artist removal proposal, can reuse general proposal event if needed.
    }

    function voteOnArtistRemoval(uint256 _proposalId, bool _approve) external onlyArtist validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.votes[msg.sender], "Artist has already voted on this proposal.");
        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtistMembershipVoted(_proposalId, msg.sender, _approve); // Reusing event, consider specific event if needed.
    }

    function executeArtistRemovalProposal(uint256 _proposalId) external onlyGovernance validProposal(_proposalId) {
        _executeProposal(_proposalId);
    }

    function _executeArtistRemoval(bytes memory _proposalData) internal {
        (address _artistAddress) = abi.decode(_proposalData, (address));
        artists[_artistAddress].isActive = false;
        // Remove from artistList (more complex, consider different data structure if frequent removals needed)
        for (uint i = 0; i < artistList.length; i++) {
            if (artistList[i] == _artistAddress) {
                artistList[i] = artistList[artistList.length - 1];
                artistList.pop();
                break;
            }
        }
        emit ArtistRemoved(_artistAddress);
    }


    // --- Artwork Creation Functions ---

    function proposeArtworkCreation(string memory _artworkTitle, string memory _artworkDescription, string memory _initialMetadataURI) external onlyArtist {
        bytes memory proposalData = abi.encode(_artworkTitle, _artworkDescription, _initialMetadataURI, msg.sender);
        uint256 proposalId = _createProposal(ProposalType.ARTWORK_CREATION, proposalData);
        emit ArtworkProposed(proposalId, _artworkTitle);
    }

    function voteOnArtworkCreation(uint256 _proposalId, bool _approve) external onlyArtist validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.votes[msg.sender], "Artist has already voted on this proposal.");
        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtworkCreationVoted(_proposalId, msg.sender, _approve);
    }

    function executeArtworkCreationProposal(uint256 _proposalId) external onlyGovernance validProposal(_proposalId) {
        _executeProposal(_proposalId);
    }

    function _executeArtworkCreation(bytes memory _proposalData) internal {
        (string memory _artworkTitle, string memory _artworkDescription, string memory _initialMetadataURI, address _creator) = abi.decode(_proposalData, (string, string, string, address));
        artworkCounter++;
        uint256 artworkId = artworkCounter;
        artworks[artworkId] = Artwork({
            id: artworkId,
            title: _artworkTitle,
            description: _artworkDescription,
            creator: _creator,
            currentMetadataURI: _initialMetadataURI,
            contributionMetadataURIs: new string[](0), // Initialize empty contributions array
            owner: address(this), // Collective owns initially
            exists: true
        });
        emit ArtworkCreated(artworkId, _artworkTitle, _creator);
    }

    // --- Artwork Contribution Functions ---

    function contributeToArtwork(uint256 _artworkId, string memory _contributionMetadataURI) external onlyArtist validArtwork(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        uint256 contributionIndex = artwork.contributionMetadataURIs.length;
        bytes memory proposalData = abi.encode(_artworkId, contributionIndex, _contributionMetadataURI, msg.sender);
        uint256 proposalId = _createProposal(ProposalType.ARTWORK_CONTRIBUTION, proposalData);
        emit ArtworkContributionProposed(_artworkId, contributionIndex, msg.sender);
    }

    function voteOnContribution(uint256 _artworkId, uint256 _contributionIndex, bool _approve) external onlyArtist validArtwork(_artworkId) {
        Proposal storage proposal = proposals[_proposalCounter]; // Assuming _createProposal increments counter immediately
        require(proposal.proposalType == ProposalType.ARTWORK_CONTRIBUTION, "Invalid proposal type for contribution vote."); // Sanity check
        require(!proposal.votes[msg.sender], "Artist has already voted on this proposal.");
        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ContributionVoted(_artworkId, _contributionIndex, msg.sender, _approve);
    }

    function executeContributionProposal(uint256 _artworkId, uint256 _contributionIndex) external onlyGovernance validArtwork(_artworkId) {
        _executeProposal(_proposalCounter); // Assuming voteOnContribution is called just before execution
    }

    function _executeArtworkContribution(bytes memory _proposalData) internal {
        (uint256 _artworkId, uint256 _contributionIndex, string memory _contributionMetadataURI, address _contributor) = abi.decode(_proposalData, (uint256, uint256, string, address));
        Artwork storage artwork = artworks[_artworkId];
        artwork.contributionMetadataURIs.push(_contributionMetadataURI);
        artwork.currentMetadataURI = _contributionMetadataURI; // Update to latest contribution (can be configurable)
        emit ArtworkContributed(_artworkId, _contributionIndex, _contributor);
    }

    // --- Artwork Ownership Transfer ---

    function transferArtworkOwnership(uint256 _artworkId, address _newOwner) external onlyGovernance validArtwork(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        address oldOwner = artwork.owner;
        artwork.owner = _newOwner;
        emit ArtworkOwnershipTransferred(_artworkId, oldOwner, _newOwner);
    }

    // --- Metadata Update Functions ---

    function proposeMetadataUpdate(uint256 _artworkId, string memory _newMetadataURI) external onlyArtist validArtwork(_artworkId) {
        bytes memory proposalData = abi.encode(_artworkId, _newMetadataURI);
        uint256 proposalId = _createProposal(ProposalType.METADATA_UPDATE, proposalData);
        emit MetadataUpdateProposed(proposalId, _artworkId, _newMetadataURI);
    }

    function voteOnMetadataUpdate(uint256 _proposalId, bool _approve) external onlyArtist validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.votes[msg.sender], "Artist has already voted on this proposal.");
        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit MetadataUpdateVoted(_proposalId, msg.sender, _approve);
    }

    function executeMetadataUpdateProposal(uint256 _proposalId) external onlyGovernance validProposal(_proposalId) {
        _executeProposal(_proposalId);
    }

    function _executeMetadataUpdate(bytes memory _proposalData) internal {
        (uint256 _artworkId, string memory _newMetadataURI) = abi.decode(_proposalData, (uint256, string));
        artworks[_artworkId].currentMetadataURI = _newMetadataURI;
        emit MetadataUpdated(_artworkId, _newMetadataURI);
    }

    // --- Artwork Burning ---

    function burnArtwork(uint256 _artworkId) external onlyGovernance validArtwork(_artworkId) {
        bytes memory proposalData = abi.encode(_artworkId);
        uint256 proposalId = _createProposal(ProposalType.ARTWORK_BURN, proposalData);
        // No specific event for artwork burn proposal, can reuse general proposal event if needed.
    }

    function voteOnArtworkBurn(uint256 _proposalId, bool _approve) external onlyArtist validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.votes[msg.sender], "Artist has already voted on this proposal.");
        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit MetadataUpdateVoted(_proposalId, msg.sender, _approve); // Reusing event, consider specific event if needed.
    }

    function executeArtworkBurnProposal(uint256 _proposalId) external onlyGovernance validProposal(_proposalId) {
        _executeProposal(_proposalId);
    }

    function _executeArtworkBurn(bytes memory _proposalData) internal {
        (uint256 _artworkId) = abi.decode(_proposalData, (uint256));
        artworks[_artworkId].exists = false;
        emit ArtworkBurned(_artworkId);
    }


    // --- Governance Functions ---

    function setGovernanceThreshold(uint256 _newThreshold) external onlyGovernance {
        require(_newThreshold <= 100, "Threshold cannot exceed 100%.");
        bytes memory proposalData = abi.encode(_newThreshold);
        uint256 proposalId = _createProposal(ProposalType.GOVERNANCE_CHANGE, proposalData);
        // No specific event for governance change proposal, can reuse general proposal event if needed.
    }

    function voteOnGovernanceThresholdChange(uint256 _proposalId, bool _approve) external onlyArtist validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.votes[msg.sender], "Artist has already voted on this proposal.");
        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit MetadataUpdateVoted(_proposalId, msg.sender, _approve); // Reusing event, consider specific event if needed.
    }

    function executeGovernanceThresholdChangeProposal(uint256 _proposalId) external onlyGovernance validProposal(_proposalId) {
        _executeProposal(_proposalId);
    }

    function _executeGovernanceChange(bytes memory _proposalData) internal {
        (uint256 _newThreshold) = abi.decode(_proposalData, (uint256));
        governanceThreshold = _newThreshold;
        emit GovernanceThresholdChanged(_newThreshold);
    }


    // --- Treasury Functions ---

    function donateToCollective() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    function withdrawDonations(address _recipient, uint256 _amount) external onlyGovernance {
        require(address(this).balance >= _amount, "Insufficient funds in treasury.");
        bytes memory proposalData = abi.encode(_recipient, _amount);
        uint256 proposalId = _createProposal(ProposalType.TREASURY_WITHDRAWAL, proposalData);
        // No specific event for treasury withdrawal proposal, can reuse general proposal event if needed.
    }

    function voteOnWithdrawal(uint256 _proposalId, bool _approve) external onlyArtist validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.votes[msg.sender], "Artist has already voted on this proposal.");
        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit MetadataUpdateVoted(_proposalId, msg.sender, _approve); // Reusing event, consider specific event if needed.
    }

    function executeWithdrawalProposal(uint256 _proposalId) external onlyGovernance validProposal(_proposalId) {
        _executeProposal(_proposalId);
    }

    function _executeTreasuryWithdrawal(bytes memory _proposalData) internal {
        (address _recipient, uint256 _amount) = abi.decode(_proposalData, (address, uint256));
        payable(_recipient).transfer(_amount);
        emit WithdrawalMade(_recipient, _amount);
    }


    // --- View Functions ---

    function getArtworkDetails(uint256 _artworkId) external view validArtwork(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getArtistDetails(address _artistAddress) external view returns (Artist memory) {
        return artists[_artistAddress];
    }

    function getProposalDetails(uint256 _proposalId) external view validProposal(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getCollectiveBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getMyVotingPower() external view onlyArtist returns (uint256) {
        // Simple voting power: 1 vote per artist. Can be enhanced based on reputation, etc.
        return 1;
    }

    function getArtworkCurrentMetadataURI(uint256 _artworkId) external view validArtwork(_artworkId) returns (string memory) {
        return artworks[_artworkId].currentMetadataURI;
    }
}
```