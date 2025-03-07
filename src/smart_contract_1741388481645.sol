```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI (Example - Not for Production)
 * @notice This contract implements a Decentralized Autonomous Art Collective, allowing artists to register,
 *         submit and manage artworks, participate in collaborative art projects, and govern the collective through proposals and voting.
 *         It incorporates advanced concepts like collaborative art generation, dynamic royalty splitting, decentralized curation,
 *         and community-driven governance. This is a conceptual example and may require further security audits and
 *         testing for production use.
 *
 * **Outline and Function Summary:**
 *
 * **1. Artist Management:**
 *    - `registerArtist(string memory _artistName, string memory _artistDescription)`: Allows artists to register with the collective.
 *    - `updateArtistProfile(string memory _artistName, string memory _artistDescription)`: Allows registered artists to update their profile information.
 *    - `getArtistProfile(address _artistAddress)`: Retrieves the profile information of a registered artist.
 *    - `isArtistRegistered(address _artistAddress)`: Checks if an address is registered as an artist.
 *    - `getAllArtists()`: Returns a list of all registered artist addresses.
 *    - `removeArtist(address _artistAddress)`: Allows the collective council to remove an artist (governance function).
 *
 * **2. Artwork Management:**
 *    - `submitArtwork(string memory _artworkTitle, string memory _artworkDescription, string memory _artworkIPFSHash, uint256 _initialSalePrice)`: Artists submit their artworks to the collective.
 *    - `updateArtworkDetails(uint256 _artworkId, string memory _artworkTitle, string memory _artworkDescription, string memory _artworkIPFSHash)`: Artists can update details of their submitted artwork.
 *    - `setArtworkSalePrice(uint256 _artworkId, uint256 _newSalePrice)`: Artists can set or update the sale price of their artwork.
 *    - `purchaseArtwork(uint256 _artworkId)`: Allows anyone to purchase artwork, transferring ownership and royalties.
 *    - `listArtworkForSale(uint256 _artworkId)`:  Marks an artwork as available for sale.
 *    - `unlistArtworkForSale(uint256 _artworkId)`: Removes an artwork from being listed for sale.
 *    - `getArtworkDetails(uint256 _artworkId)`: Retrieves details of a specific artwork.
 *    - `getAllArtworkByArtist(address _artistAddress)`: Returns a list of artwork IDs submitted by a specific artist.
 *    - `getAllArtworkForSale()`: Returns a list of artwork IDs currently listed for sale.
 *    - `transferArtworkOwnership(uint256 _artworkId, address _newOwner)`: Allows the current artwork owner to transfer ownership.
 *
 * **3. Collaborative Art Projects:**
 *    - `createCollaborativeProject(string memory _projectName, string memory _projectDescription, uint256 _maxCollaborators, uint256 _deadline)`:  Allows artists to propose collaborative art projects.
 *    - `joinCollaborativeProject(uint256 _projectId)`: Artists can join open collaborative projects.
 *    - `submitContributionToProject(uint256 _projectId, string memory _contributionDescription, string memory _contributionIPFSHash)`: Collaborators submit their contributions to a project.
 *    - `finalizeCollaborativeProject(uint256 _projectId)`:  Project initiator can finalize a project, triggering royalty distribution (governance function, potentially with voting).
 *    - `getProjectDetails(uint256 _projectId)`: Retrieves details of a collaborative project.
 *    - `getProjectCollaborators(uint256 _projectId)`: Returns a list of collaborators for a specific project.
 *
 * **4. Decentralized Governance & Collective Management:**
 *    - `createProposal(string memory _proposalTitle, string memory _proposalDescription, ProposalType _proposalType, bytes memory _proposalData)`: Registered artists can create proposals for collective governance.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Registered artists can vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes (governance function).
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific proposal.
 *    - `getProposalVotingStatus(uint256 _proposalId)`: Gets the current voting status of a proposal.
 *    - `setGovernanceParameter(GovernanceParameter _parameter, uint256 _newValue)`: Allows the collective council to change governance parameters (governance function, potentially with voting for critical parameters).
 *    - `fundCollective()`: Allows anyone to contribute funds to the collective treasury.
 *    - `withdrawCollectiveFunds(address _recipient, uint256 _amount)`: Allows the collective council to withdraw funds from the treasury (governance function).
 *
 * **5. Utility & Data Retrieval:**
 *    - `getCollectiveBalance()`: Returns the current balance of the collective treasury.
 *    - `getVersion()`: Returns the contract version.
 */
contract DecentralizedAutonomousArtCollective {
    // -------- State Variables --------

    // Artist Management
    mapping(address => ArtistProfile) public artistProfiles;
    address[] public registeredArtists;
    uint256 public artistCount;

    // Artwork Management
    uint256 public artworkCount;
    mapping(uint256 => Artwork) public artworks;
    mapping(address => uint256[]) public artistArtworkList; // Artist to list of artwork IDs
    mapping(uint256 => address) public artworkOwners; // Artwork ID to owner address

    // Collaborative Projects
    uint256 public projectCount;
    mapping(uint256 => CollaborativeProject) public projects;
    mapping(uint256 => address[]) public projectCollaborators; // Project ID to list of collaborator addresses
    mapping(uint256 => Contribution[]) public projectContributions; // Project ID to list of contributions

    // Governance & Proposals
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Proposal ID -> Voter Address -> Voted (true/false)
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 50; // Default quorum percentage for proposals
    address public collectiveCouncil; // Address authorized to execute governance functions

    uint256 public collectiveTreasuryBalance;

    string public contractName = "Decentralized Autonomous Art Collective";
    string public contractVersion = "1.0.0";

    // -------- Enums and Structs --------

    enum ProposalType {
        GENERIC,
        REMOVE_ARTIST,
        SET_GOVERNANCE_PARAMETER,
        WITHDRAW_FUNDS,
        FINALIZE_PROJECT
    }

    enum GovernanceParameter {
        VOTING_DURATION,
        QUORUM_PERCENTAGE
    }

    struct ArtistProfile {
        string artistName;
        string artistDescription;
        bool isRegistered;
    }

    struct Artwork {
        uint256 artworkId;
        address artistAddress;
        string artworkTitle;
        string artworkDescription;
        string artworkIPFSHash;
        uint256 salePrice;
        bool isForSale;
        address currentOwner;
        uint256 submissionTimestamp;
    }

    struct CollaborativeProject {
        uint256 projectId;
        string projectName;
        string projectDescription;
        address projectInitiator;
        uint256 maxCollaborators;
        uint256 deadline;
        bool isFinalized;
        uint256 creationTimestamp;
    }

    struct Contribution {
        address contributorAddress;
        string contributionDescription;
        string contributionIPFSHash;
        uint256 submissionTimestamp;
    }

    struct Proposal {
        uint256 proposalId;
        string proposalTitle;
        string proposalDescription;
        ProposalType proposalType;
        bytes proposalData; // Encoded data specific to proposal type
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        address proposer;
    }

    // -------- Events --------

    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress, string artistName);
    event ArtworkSubmitted(uint256 artworkId, address artistAddress, string artworkTitle);
    event ArtworkDetailsUpdated(uint256 artworkId, string artworkTitle);
    event ArtworkPriceSet(uint256 artworkId, uint256 newPrice);
    event ArtworkPurchased(uint256 artworkId, address buyer, address seller, uint256 price);
    event ArtworkListedForSale(uint256 artworkId);
    event ArtworkUnlistedForSale(uint256 artworkId);
    event ArtworkOwnershipTransferred(uint256 artworkId, address oldOwner, address newOwner);
    event CollaborativeProjectCreated(uint256 projectId, string projectName, address initiator);
    event CollaborativeProjectJoined(uint256 projectId, address collaborator);
    event ContributionSubmitted(uint256 projectId, address contributor);
    event CollaborativeProjectFinalized(uint256 projectId);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, string proposalTitle, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, ProposalType proposalType);
    event GovernanceParameterSet(GovernanceParameter parameter, uint256 newValue);
    event CollectiveFunded(address sender, uint256 amount);
    event CollectiveFundsWithdrawn(address recipient, uint256 amount);
    event ArtistRemoved(address artistAddress);


    // -------- Modifiers --------

    modifier onlyArtist() {
        require(artistProfiles[msg.sender].isRegistered, "Only registered artists can perform this action.");
        _;
    }

    modifier onlyCollectiveCouncil() {
        require(msg.sender == collectiveCouncil, "Only the collective council can perform this action.");
        _;
    }

    modifier onlyProjectInitiator(uint256 _projectId) {
        require(projects[_projectId].projectInitiator == msg.sender, "Only the project initiator can perform this action.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId < proposalCount, "Invalid proposal ID.");
        _;
    }

    modifier validArtworkId(uint256 _artworkId) {
        require(_artworkId < artworkCount, "Invalid artwork ID.");
        _;
    }

    modifier validProjectId(uint256 _projectId) {
        require(_projectId < projectCount, "Invalid project ID.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].voteStartTime && block.timestamp <= proposals[_proposalId].voteEndTime, "Proposal is not currently active for voting.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal has already been executed.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        collectiveCouncil = msg.sender; // Deployer is initially the collective council
        collectiveTreasuryBalance = 0;
    }

    // -------- 1. Artist Management Functions --------

    function registerArtist(string memory _artistName, string memory _artistDescription) public {
        require(!artistProfiles[msg.sender].isRegistered, "Artist is already registered.");
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: _artistName,
            artistDescription: _artistDescription,
            isRegistered: true
        });
        registeredArtists.push(msg.sender);
        artistCount++;
        emit ArtistRegistered(msg.sender, _artistName);
    }

    function updateArtistProfile(string memory _artistName, string memory _artistDescription) public onlyArtist {
        artistProfiles[msg.sender].artistName = _artistName;
        artistProfiles[msg.sender].artistDescription = _artistDescription;
        emit ArtistProfileUpdated(msg.sender, _artistName);
    }

    function getArtistProfile(address _artistAddress) public view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }

    function isArtistRegistered(address _artistAddress) public view returns (bool) {
        return artistProfiles[_artistAddress].isRegistered;
    }

    function getAllArtists() public view returns (address[] memory) {
        return registeredArtists;
    }

    function removeArtist(address _artistAddress) public onlyCollectiveCouncil {
        require(artistProfiles[_artistAddress].isRegistered, "Artist is not registered.");
        artistProfiles[_artistAddress].isRegistered = false;
        // Remove from registeredArtists array (more complex in Solidity, omitted for simplicity in this example - can use filtering or marking as inactive)
        artistCount--;
        emit ArtistRemoved(_artistAddress);
    }


    // -------- 2. Artwork Management Functions --------

    function submitArtwork(
        string memory _artworkTitle,
        string memory _artworkDescription,
        string memory _artworkIPFSHash,
        uint256 _initialSalePrice
    ) public onlyArtist {
        artworks[artworkCount] = Artwork({
            artworkId: artworkCount,
            artistAddress: msg.sender,
            artworkTitle: _artworkTitle,
            artworkDescription: _artworkDescription,
            artworkIPFSHash: _artworkIPFSHash,
            salePrice: _initialSalePrice,
            isForSale: false,
            currentOwner: msg.sender, // Initially artist owns it
            submissionTimestamp: block.timestamp
        });
        artistArtworkList[msg.sender].push(artworkCount);
        artworkOwners[artworkCount] = msg.sender;
        emit ArtworkSubmitted(artworkCount, msg.sender, _artworkTitle);
        artworkCount++;
    }

    function updateArtworkDetails(
        uint256 _artworkId,
        string memory _artworkTitle,
        string memory _artworkDescription,
        string memory _artworkIPFSHash
    ) public onlyArtist validArtworkId(_artworkId) {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the artist who submitted the artwork can update details.");
        artworks[_artworkId].artworkTitle = _artworkTitle;
        artworks[_artworkId].artworkDescription = _artworkDescription;
        artworks[_artworkId].artworkIPFSHash = _artworkIPFSHash;
        emit ArtworkDetailsUpdated(_artworkId, _artworkTitle);
    }

    function setArtworkSalePrice(uint256 _artworkId, uint256 _newSalePrice) public onlyArtist validArtworkId(_artworkId) {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the artist who submitted the artwork can set the price.");
        artworks[_artworkId].salePrice = _newSalePrice;
        emit ArtworkPriceSet(_artworkId, _newSalePrice);
    }

    function purchaseArtwork(uint256 _artworkId) public payable validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isForSale, "Artwork is not currently for sale.");
        require(msg.value >= artwork.salePrice, "Insufficient funds sent.");

        address seller = artwork.currentOwner;
        address artist = artwork.artistAddress;
        uint256 salePrice = artwork.salePrice;

        artwork.currentOwner = msg.sender;
        artwork.isForSale = false;
        artworkOwners[_artworkId] = msg.sender;

        // Royalty Distribution Logic (Example - can be more complex based on collective rules)
        uint256 artistRoyalty = (salePrice * 80) / 100; // 80% to artist
        uint256 collectiveFee = salePrice - artistRoyalty; // 20% to collective

        payable(artist).transfer(artistRoyalty);
        collectiveTreasuryBalance += collectiveFee;

        emit ArtworkPurchased(_artworkId, msg.sender, seller, salePrice);

        // Return excess funds if any
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }
    }

    function listArtworkForSale(uint256 _artworkId) public onlyArtist validArtworkId(_artworkId) {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the artist who submitted the artwork can list it for sale.");
        artworks[_artworkId].isForSale = true;
        emit ArtworkListedForSale(_artworkId);
    }

    function unlistArtworkForSale(uint256 _artworkId) public onlyArtist validArtworkId(_artworkId) {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the artist who submitted the artwork can unlist it.");
        artworks[_artworkId].isForSale = false;
        emit ArtworkUnlistedForSale(_artworkId);
    }

    function getArtworkDetails(uint256 _artworkId) public view validArtworkId(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getAllArtworkByArtist(address _artistAddress) public view returns (uint256[] memory) {
        return artistArtworkList[_artistAddress];
    }

    function getAllArtworkForSale() public view returns (uint256[] memory) {
        uint256[] memory forSaleArtworkIds = new uint256[](artworkCount);
        uint256 count = 0;
        for (uint256 i = 0; i < artworkCount; i++) {
            if (artworks[i].isForSale) {
                forSaleArtworkIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of for-sale artworks
        assembly {
            mstore(forSaleArtworkIds, count) // Update the length of the array in memory
        }
        return forSaleArtworkIds;
    }

    function transferArtworkOwnership(uint256 _artworkId, address _newOwner) public validArtworkId(_artworkId) {
        require(artworkOwners[_artworkId] == msg.sender, "Only the current owner can transfer ownership.");
        artworkOwners[_artworkId] = _newOwner;
        artworks[_artworkId].currentOwner = _newOwner;
        emit ArtworkOwnershipTransferred(_artworkId, msg.sender, _newOwner);
    }


    // -------- 3. Collaborative Art Projects Functions --------

    function createCollaborativeProject(
        string memory _projectName,
        string memory _projectDescription,
        uint256 _maxCollaborators,
        uint256 _deadline
    ) public onlyArtist {
        projects[projectCount] = CollaborativeProject({
            projectId: projectCount,
            projectName: _projectName,
            projectDescription: _projectDescription,
            projectInitiator: msg.sender,
            maxCollaborators: _maxCollaborators,
            deadline: block.timestamp + _deadline,
            isFinalized: false,
            creationTimestamp: block.timestamp
        });
        emit CollaborativeProjectCreated(projectCount, _projectName, msg.sender);
        projectCount++;
    }

    function joinCollaborativeProject(uint256 _projectId) public onlyArtist validProjectId(_projectId) {
        CollaborativeProject storage project = projects[_projectId];
        require(!project.isFinalized, "Project is already finalized.");
        require(block.timestamp < project.deadline, "Project deadline has passed.");
        require(projectCollaborators[_projectId].length < project.maxCollaborators, "Project is full.");

        // Check if already joined (optional, depending on desired behavior)
        for (uint256 i = 0; i < projectCollaborators[_projectId].length; i++) {
            if (projectCollaborators[_projectId][i] == msg.sender) {
                revert("Artist has already joined this project.");
            }
        }

        projectCollaborators[_projectId].push(msg.sender);
        emit CollaborativeProjectJoined(_projectId, msg.sender);
    }

    function submitContributionToProject(
        uint256 _projectId,
        string memory _contributionDescription,
        string memory _contributionIPFSHash
    ) public onlyArtist validProjectId(_projectId) {
        bool isCollaborator = false;
        for (uint256 i = 0; i < projectCollaborators[_projectId].length; i++) {
            if (projectCollaborators[_projectId][i] == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(isCollaborator || projects[_projectId].projectInitiator == msg.sender, "Only project collaborators or initiator can submit contributions.");
        require(!projects[_projectId].isFinalized, "Project is already finalized.");
        require(block.timestamp < projects[_projectId].deadline, "Project deadline has passed.");

        projectContributions[_projectId].push(Contribution({
            contributorAddress: msg.sender,
            contributionDescription: _contributionDescription,
            contributionIPFSHash: _contributionIPFSHash,
            submissionTimestamp: block.timestamp
        }));
        emit ContributionSubmitted(_projectId, msg.sender);
    }

    function finalizeCollaborativeProject(uint256 _projectId) public onlyProjectInitiator(_projectId) validProjectId(_projectId) {
        require(!projects[_projectId].isFinalized, "Project is already finalized.");
        projects[_projectId].isFinalized = true;

        // Royalty Distribution Logic for Collaborative Project (Example - needs detailed rules)
        // ... (Complex logic based on contributions, project rules, voting etc. - omitted for brevity) ...
        // In a real scenario, this would involve distributing funds to project collaborators
        // based on agreed-upon terms, perhaps using a proposal and voting mechanism.

        emit CollaborativeProjectFinalized(_projectId);
    }

    function getProjectDetails(uint256 _projectId) public view validProjectId(_projectId) returns (CollaborativeProject memory) {
        return projects[_projectId];
    }

    function getProjectCollaborators(uint256 _projectId) public view validProjectId(_projectId) returns (address[] memory) {
        return projectCollaborators[_projectId];
    }


    // -------- 4. Decentralized Governance & Collective Management Functions --------

    function createProposal(
        string memory _proposalTitle,
        string memory _proposalDescription,
        ProposalType _proposalType,
        bytes memory _proposalData
    ) public onlyArtist {
        proposals[proposalCount] = Proposal({
            proposalId: proposalCount,
            proposalTitle: _proposalTitle,
            proposalDescription: _proposalDescription,
            proposalType: _proposalType,
            proposalData: _proposalData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposer: msg.sender
        });
        emit ProposalCreated(proposalCount, _proposalType, _proposalTitle, msg.sender);
        proposalCount++;
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyArtist validProposalId(_proposalId) proposalActive(_proposalId) proposalNotExecuted(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Artist has already voted on this proposal.");
        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public onlyCollectiveCouncil validProposalId(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp > proposals[_proposalId].voteEndTime, "Voting is still active.");
        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        uint256 quorum = (registeredArtists.length * quorumPercentage) / 100;
        require(totalVotes >= quorum, "Proposal did not reach quorum.");
        require(proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes, "Proposal failed to pass.");

        proposals[_proposalId].executed = true;
        ProposalType proposalType = proposals[_proposalId].proposalType;

        if (proposalType == ProposalType.REMOVE_ARTIST) {
            address artistToRemove;
            artistToRemove = abi.decode(proposals[_proposalId].proposalData, (address));
            removeArtist(artistToRemove);
        } else if (proposalType == ProposalType.SET_GOVERNANCE_PARAMETER) {
            (GovernanceParameter parameterToSet, uint256 newValue) = abi.decode(proposals[_proposalId].proposalData, (GovernanceParameter, uint256));
            setGovernanceParameterInternal(parameterToSet, newValue);
        } else if (proposalType == ProposalType.WITHDRAW_FUNDS) {
            (address recipient, uint256 amount) = abi.decode(proposals[_proposalId].proposalData, (address, uint256));
            withdrawCollectiveFundsInternal(recipient, amount);
        } else if (proposalType == ProposalType.FINALIZE_PROJECT) {
            uint256 projectIdToFinalize;
            projectIdToFinalize = abi.decode(proposals[_proposalId].proposalData, (uint256));
            finalizeCollaborativeProject(projectIdToFinalize);
        }
        // Add more proposal type executions here as needed

        emit ProposalExecuted(_proposalId, proposalType);
    }

    function getProposalDetails(uint256 _proposalId) public view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getProposalVotingStatus(uint256 _proposalId) public view validProposalId(_proposalId) returns (uint256 yesVotes, uint256 noVotes, uint256 votingEndTime, bool executed) {
        return (proposals[_proposalId].yesVotes, proposals[_proposalId].noVotes, proposals[_proposalId].voteEndTime, proposals[_proposalId].executed);
    }

    function setGovernanceParameter(GovernanceParameter _parameter, uint256 _newValue) public onlyCollectiveCouncil {
        // In a real DAO, changing critical parameters might require a proposal and voting itself.
        // For simplicity, council can set in this example, but consider adding governance for this in a real application.
        bytes memory proposalData = abi.encode(_parameter, _newValue);
        createProposal(
            "Set Governance Parameter",
            string(abi.encodePacked("Setting ", parameterToString(_parameter), " to ", uint2str(_newValue))),
            ProposalType.SET_GOVERNANCE_PARAMETER,
            proposalData
        );
    }

    function setGovernanceParameterInternal(GovernanceParameter _parameter, uint256 _newValue) internal {
        if (_parameter == GovernanceParameter.VOTING_DURATION) {
            votingDuration = _newValue;
        } else if (_parameter == GovernanceParameter.QUORUM_PERCENTAGE) {
            quorumPercentage = _newValue;
        }
        emit GovernanceParameterSet(_parameter, _newValue);
    }

    function fundCollective() public payable {
        collectiveTreasuryBalance += msg.value;
        emit CollectiveFunded(msg.sender, msg.value);
    }

    function withdrawCollectiveFunds(address _recipient, uint256 _amount) public onlyCollectiveCouncil {
        bytes memory proposalData = abi.encode(_recipient, _amount);
        createProposal(
            "Withdraw Collective Funds",
            string(abi.encodePacked("Withdraw ", uint2str(_amount), " to ", addressToString(_recipient))),
            ProposalType.WITHDRAW_FUNDS,
            proposalData
        );
    }

    function withdrawCollectiveFundsInternal(address _recipient, uint256 _amount) internal {
        require(collectiveTreasuryBalance >= _amount, "Insufficient collective funds.");
        collectiveTreasuryBalance -= _amount;
        payable(_recipient).transfer(_amount);
        emit CollectiveFundsWithdrawn(_recipient, _amount);
    }


    // -------- 5. Utility & Data Retrieval Functions --------

    function getCollectiveBalance() public view returns (uint256) {
        return collectiveTreasuryBalance;
    }

    function getVersion() public view returns (string memory) {
        return contractVersion;
    }

    // -------- Helper Functions (for string conversion - for events/descriptions) --------
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 lsb = uint8(uint256(_i % 10) + 48);
            bstr[k] = bytes1(lsb);
            _i /= 10;
        }
        return string(bstr);
    }

    function addressToString(address _addr) internal pure returns (string memory) {
        bytes memory str = new bytes(42);
        bytes memory alphabet = "0123456789abcdef";

        for (uint i = 0; i < 20; i++) {
            uint8 byteValue = uint8(uint256(_addr) / (2**(8*(19 - i))));
            str[2+i*2] = alphabet[byteValue >> 4];
            str[3+i*2] = alphabet[byteValue & 0xf];
        }

        str[0] = '0';
        str[1] = 'x';
        return string(str);
    }

    function parameterToString(GovernanceParameter _param) internal pure returns (string memory) {
        if (_param == GovernanceParameter.VOTING_DURATION) {
            return "Voting Duration";
        } else if (_param == GovernanceParameter.QUORUM_PERCENTAGE) {
            return "Quorum Percentage";
        } else {
            return "Unknown Parameter";
        }
    }
}
```