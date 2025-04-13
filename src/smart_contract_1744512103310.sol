```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to submit artwork,
 *      members to vote on artwork acceptance, collective ownership of curated art, and innovative
 *      mechanisms for art evolution and interaction.

 * **Outline & Function Summary:**

 * **1. Core Collective Management:**
 *    - `initializeCollective(string _collectiveName, uint256 _votingPeriod, uint256 _quorumPercentage)`: Initializes the collective with a name, voting period, and quorum. (Once only)
 *    - `changeVotingPeriod(uint256 _newVotingPeriod)`: Allows governance to change the voting period for proposals.
 *    - `changeQuorumPercentage(uint256 _newQuorumPercentage)`: Allows governance to change the quorum percentage for proposals.
 *    - `pauseContract()`: Pauses core contract functionalities for emergency situations (Governance only).
 *    - `unpauseContract()`: Resumes contract functionalities after pausing (Governance only).

 * **2. Artist & Membership Management:**
 *    - `applyForArtistMembership(string memory _artistStatement, string memory _portfolioLink)`: Artists can apply for membership by submitting a statement and portfolio link.
 *    - `proposeArtistMembership(address _artistAddress)`: Members can propose an artist for membership (Requires voting).
 *    - `voteOnArtistMembership(uint256 _proposalId, bool _support)`: Members can vote on artist membership proposals.
 *    - `executeArtistMembershipProposal(uint256 _proposalId)`: Executes a successful artist membership proposal (Governance or automatic after voting period).
 *    - `revokeArtistMembership(address _artistAddress)`: Allows governance to revoke artist membership (Requires voting).
 *    - `getArtistMembershipStatus(address _artistAddress)`: View function to check if an address is an artist member.

 * **3. Artwork Submission & Curation:**
 *    - `submitArtwork(string memory _artworkTitle, string memory _artworkDescription, string memory _artworkIPFSHash)`: Artist members can submit their artwork with title, description, and IPFS hash.
 *    - `proposeArtworkCuration(uint256 _artworkId)`: Members can propose submitted artwork for curation into the collective (Requires voting).
 *    - `voteOnArtworkCuration(uint256 _proposalId, bool _support)`: Members can vote on artwork curation proposals.
 *    - `executeArtworkCurationProposal(uint256 _proposalId)`: Executes a successful artwork curation proposal, officially adding the artwork to the collective.
 *    - `removeCuratedArtwork(uint256 _artworkId)`: Allows governance to remove a curated artwork from the collective (Requires voting).
 *    - `getArtworkDetails(uint256 _artworkId)`: View function to retrieve details of a submitted or curated artwork.

 * **4. Dynamic Artwork Evolution (Concept):**
 *    - `proposeArtworkEvolution(uint256 _artworkId, string memory _evolutionDescription, string memory _evolutionIPFSHash)`: Members can propose an evolution/remix/derivative of a curated artwork.
 *    - `voteOnArtworkEvolution(uint256 _proposalId, bool _support)`: Members vote on artwork evolution proposals.
 *    - `executeArtworkEvolutionProposal(uint256 _proposalId)`: Executes a successful artwork evolution proposal, creating a new evolved artwork linked to the original.
 *    - `getArtworkEvolutions(uint256 _artworkId)`: View function to get a list of evolutions associated with a curated artwork.

 * **5. Interactive Art & Community Engagement (Concept):**
 *    - `interactWithArtwork(uint256 _artworkId, string memory _interactionData)`: Allows members to interact with curated artwork (e.g., leave comments, interpretations, etc.).  Interaction data stored off-chain (IPFS or similar).
 *    - `getArtworkInteractions(uint256 _artworkId)`: View function to retrieve interaction data hashes for a curated artwork.

 * **6. Governance & Proposals:**
 *    - `createGenericProposal(string memory _proposalDescription, bytes calldata _actions)`:  Allows governance to create generic proposals for contract upgrades or complex actions (Advanced governance).
 *    - `voteOnGenericProposal(uint256 _proposalId, bool _support)`: Members vote on generic proposals.
 *    - `executeGenericProposal(uint256 _proposalId)`: Executes a successful generic proposal.
 *    - `getProposalDetails(uint256 _proposalId)`: View function to retrieve details of any proposal.
 *    - `getProposalVotingStatus(uint256 _proposalId)`: View function to get the current voting status of a proposal.

 * **7. Utility & Information:**
 *    - `getCollectiveName()`: View function to retrieve the name of the collective.
 *    - `getVotingPeriod()`: View function to retrieve the current voting period.
 *    - `getQuorumPercentage()`: View function to retrieve the current quorum percentage.
 *    - `isContractPaused()`: View function to check if the contract is currently paused.
 *    - `getMemberCount()`: View function to get the total number of members in the collective.
 *    - `getArtworkCount()`: View function to get the total number of curated artworks.
 */

contract DecentralizedArtCollective {

    // --- State Variables ---

    string public collectiveName;
    uint256 public votingPeriod;
    uint256 public quorumPercentage; // Percentage for quorum
    bool public paused;
    address public governance; // Address of the governance contract or multi-sig

    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    enum ProposalType { ARTIST_MEMBERSHIP, ARTWORK_CURATION, ARTWORK_EVOLUTION, GENERIC, GOVERNANCE_CHANGE, ARTIST_REVOCATION, ARTWORK_REMOVAL }

    struct Proposal {
        ProposalType proposalType;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        address proposer;
        bytes actions; // For generic proposals
        address artistAddress; // For artist membership proposals
        uint256 artworkId; // For artwork proposals
    }

    mapping(uint256 => mapping(address => bool)) public votes; // proposalId => voterAddress => votedSupport
    mapping(address => bool) public artistMembers;
    uint256 public artistMemberCount;

    uint256 public artworkCounter;
    mapping(uint256 => Artwork) public artworks;
    struct Artwork {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        bool curated;
        uint256 submissionTime;
    }

    mapping(uint256 => string[]) public artworkInteractions; // artworkId => array of interactionDataHashes
    mapping(uint256 => uint256[]) public artworkEvolutions; // artworkId => array of evolutionArtworkIds

    mapping(address => ArtistApplication) public artistApplications;
    uint256 public artistApplicationCounter;
    struct ArtistApplication {
        uint256 id;
        address applicant;
        string artistStatement;
        string portfolioLink;
        uint256 applicationTime;
        bool proposed; // Flag to indicate if an artist membership proposal has been created for this application
    }


    // --- Events ---

    event CollectiveInitialized(string collectiveName, address governance, uint256 votingPeriod, uint256 quorumPercentage);
    event VotingPeriodChanged(uint256 newVotingPeriod);
    event QuorumPercentageChanged(uint256 newQuorumPercentage);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    event ArtistMembershipApplied(uint256 applicationId, address applicant, string artistStatement, string portfolioLink);
    event ArtistMembershipProposed(uint256 proposalId, address artistAddress, address proposer);
    event ArtistMembershipVoted(uint256 proposalId, address voter, bool support);
    event ArtistMembershipExecuted(uint256 proposalId, address artistAddress);
    event ArtistMembershipRevoked(address artistAddress, address revoker);

    event ArtworkSubmitted(uint256 artworkId, address artist, string artworkTitle);
    event ArtworkCurationProposed(uint256 proposalId, uint256 artworkId, address proposer);
    event ArtworkCurationVoted(uint256 proposalId, address voter, bool support);
    event ArtworkCurated(uint256 proposalId, uint256 artworkId);
    event ArtworkRemoved(uint256 artworkId, address remover);

    event ArtworkEvolutionProposed(uint256 proposalId, uint256 artworkId, address proposer);
    event ArtworkEvolutionVoted(uint256 proposalId, address voter, bool support);
    event ArtworkEvolutionExecuted(uint256 proposalId, uint256 evolvedArtworkId, uint256 originalArtworkId);

    event ArtworkInteractionRecorded(uint256 artworkId, address interactor, string interactionDataHash);

    event GenericProposalCreated(uint256 proposalId, string description, address proposer);
    event GenericProposalVoted(uint256 proposalId, address voter, bool support);
    event GenericProposalExecuted(uint256 proposalId);
    event GovernanceChanged(address newGovernance);


    // --- Modifiers ---

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance can perform this action");
        _;
    }

    modifier onlyArtistMembers() {
        require(artistMembers[msg.sender], "Only artist members can perform this action");
        _;
    }

    modifier onlyMembers() {
        require(artistMembers[msg.sender] || msg.sender == governance, "Only members or governance can perform this action"); // Members + Governance can propose
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter && proposals[_proposalId].startTime != 0, "Proposal does not exist");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].startTime && block.timestamp <= proposals[_proposalId].endTime, "Voting period is not active");
        _;
    }

    modifier contractNotPaused() {
        require(!paused, "Contract is currently paused");
        _;
    }


    // --- Constructor & Initialization ---

    constructor() {
        governance = msg.sender; // Deployer is initial governance
    }

    function initializeCollective(string memory _collectiveName, uint256 _votingPeriod, uint256 _quorumPercentage) external onlyGovernance {
        require(bytes(collectiveName).length == 0, "Collective already initialized"); // Prevent re-initialization
        collectiveName = _collectiveName;
        votingPeriod = _votingPeriod;
        quorumPercentage = _quorumPercentage;
        emit CollectiveInitialized(_collectiveName, governance, _votingPeriod, _quorumPercentage);
    }

    // --- 1. Core Collective Management Functions ---

    function changeVotingPeriod(uint256 _newVotingPeriod) external onlyGovernance contractNotPaused {
        require(_newVotingPeriod > 0, "Voting period must be greater than 0");
        votingPeriod = _newVotingPeriod;
        emit VotingPeriodChanged(_newVotingPeriod);
    }

    function changeQuorumPercentage(uint256 _newQuorumPercentage) external onlyGovernance contractNotPaused {
        require(_newQuorumPercentage <= 100, "Quorum percentage cannot exceed 100%");
        quorumPercentage = _newQuorumPercentage;
        emit QuorumPercentageChanged(_newQuorumPercentage);
    }

    function pauseContract() external onlyGovernance {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyGovernance {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }


    // --- 2. Artist & Membership Management Functions ---

    function applyForArtistMembership(string memory _artistStatement, string memory _portfolioLink) external contractNotPaused {
        artistApplicationCounter++;
        artistApplications[msg.sender] = ArtistApplication({
            id: artistApplicationCounter,
            applicant: msg.sender,
            artistStatement: _artistStatement,
            portfolioLink: _portfolioLink,
            applicationTime: block.timestamp,
            proposed: false
        });
        emit ArtistMembershipApplied(artistApplicationCounter, msg.sender, _artistStatement, _portfolioLink);
    }

    function proposeArtistMembership(address _artistAddress) external onlyMembers contractNotPaused {
        require(!artistMembers[_artistAddress], "Address is already an artist member");
        require(artistApplications[_artistAddress].id != 0 && !artistApplications[_artistAddress].proposed, "Artist must have applied and not already proposed");

        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalType: ProposalType.ARTIST_MEMBERSHIP,
            description: string(abi.encodePacked("Propose artist membership for ", Strings.toString(_artistAddress))),
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposer: msg.sender,
            actions: "", // No actions needed for this type
            artistAddress: _artistAddress,
            artworkId: 0 // Not applicable
        });
        artistApplications[_artistAddress].proposed = true; // Mark application as proposed

        emit ArtistMembershipProposed(proposalCounter, _artistAddress, msg.sender);
    }

    function voteOnArtistMembership(uint256 _proposalId, bool _support) external onlyMembers proposalExists(_proposalId) proposalNotExecuted(_proposalId) votingPeriodActive(_proposalId) contractNotPaused {
        require(!votes[_proposalId][msg.sender], "Address has already voted on this proposal");
        votes[_proposalId][msg.sender] = true;

        if (_support) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ArtistMembershipVoted(_proposalId, msg.sender, _support);
    }

    function executeArtistMembershipProposal(uint256 _proposalId) external onlyGovernance proposalExists(_proposalId) proposalNotExecuted(_proposalId) contractNotPaused {
        require(proposals[_proposalId].proposalType == ProposalType.ARTIST_MEMBERSHIP, "Proposal type is not artist membership");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period is still active");

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        require(totalVotes > 0, "No votes cast, cannot execute"); // Prevent division by zero in rare cases
        uint256 yesPercentage = (proposals[_proposalId].yesVotes * 100) / totalVotes;

        if (yesPercentage >= quorumPercentage) {
            address artistAddress = proposals[_proposalId].artistAddress;
            artistMembers[artistAddress] = true;
            artistMemberCount++;
            proposals[_proposalId].executed = true;
            emit ArtistMembershipExecuted(_proposalId, artistAddress);
        } else {
            proposals[_proposalId].executed = true; // Mark as executed even if failed to avoid re-execution
            // Proposal failed quorum - could emit an event if needed
        }
    }

    function revokeArtistMembership(address _artistAddress) external onlyGovernance contractNotPaused {
        require(artistMembers[_artistAddress], "Address is not an artist member");

        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalType: ProposalType.ARTIST_REVOCATION,
            description: string(abi.encodePacked("Revoke artist membership for ", Strings.toString(_artistAddress))),
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposer: msg.sender,
            actions: "", // No actions needed for this type
            artistAddress: _artistAddress,
            artworkId: 0 // Not applicable
        });
        emit ArtistMembershipRevoked(_artistAddress, msg.sender); // Event emitted before voting, could adjust based on desired flow
    }

    function getArtistMembershipStatus(address _artistAddress) external view returns (bool) {
        return artistMembers[_artistAddress];
    }


    // --- 3. Artwork Submission & Curation Functions ---

    function submitArtwork(string memory _artworkTitle, string memory _artworkDescription, string memory _artworkIPFSHash) external onlyArtistMembers contractNotPaused {
        artworkCounter++;
        artworks[artworkCounter] = Artwork({
            id: artworkCounter,
            title: _artworkTitle,
            description: _artworkDescription,
            ipfsHash: _artworkIPFSHash,
            artist: msg.sender,
            curated: false,
            submissionTime: block.timestamp
        });
        emit ArtworkSubmitted(artworkCounter, msg.sender, _artworkTitle);
    }

    function proposeArtworkCuration(uint256 _artworkId) external onlyMembers contractNotPaused {
        require(_artworkId > 0 && _artworkId <= artworkCounter && artworks[_artworkId].id == _artworkId, "Artwork does not exist");
        require(!artworks[_artworkId].curated, "Artwork is already curated");

        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalType: ProposalType.ARTWORK_CURATION,
            description: string(abi.encodePacked("Propose artwork curation for artwork ID ", Strings.toString(_artworkId))),
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposer: msg.sender,
            actions: "", // No actions needed for this type
            artistAddress: address(0), // Not applicable
            artworkId: _artworkId
        });
        emit ArtworkCurationProposed(proposalCounter, _artworkId, msg.sender);
    }

    function voteOnArtworkCuration(uint256 _proposalId, bool _support) external onlyMembers proposalExists(_proposalId) proposalNotExecuted(_proposalId) votingPeriodActive(_proposalId) contractNotPaused {
        require(!votes[_proposalId][msg.sender], "Address has already voted on this proposal");
        votes[_proposalId][msg.sender] = true;

        if (_support) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ArtworkCurationVoted(_proposalId, msg.sender, _support);
    }

    function executeArtworkCurationProposal(uint256 _proposalId) external onlyGovernance proposalExists(_proposalId) proposalNotExecuted(_proposalId) contractNotPaused {
        require(proposals[_proposalId].proposalType == ProposalType.ARTWORK_CURATION, "Proposal type is not artwork curation");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period is still active");

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        require(totalVotes > 0, "No votes cast, cannot execute"); // Prevent division by zero in rare cases
        uint256 yesPercentage = (proposals[_proposalId].yesVotes * 100) / totalVotes;

        if (yesPercentage >= quorumPercentage) {
            uint256 artworkId = proposals[_proposalId].artworkId;
            artworks[artworkId].curated = true;
            proposals[_proposalId].executed = true;
            emit ArtworkCurated(_proposalId, artworkId);
        } else {
            proposals[_proposalId].executed = true; // Mark as executed even if failed to avoid re-execution
            // Proposal failed quorum - could emit an event if needed
        }
    }

    function removeCuratedArtwork(uint256 _artworkId) external onlyGovernance contractNotPaused {
        require(_artworkId > 0 && _artworkId <= artworkCounter && artworks[_artworkId].id == _artworkId, "Artwork does not exist");
        require(artworks[_artworkId].curated, "Artwork is not curated");

        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalType: ProposalType.ARTWORK_REMOVAL,
            description: string(abi.encodePacked("Remove curated artwork ID ", Strings.toString(_artworkId))),
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposer: msg.sender,
            actions: "", // No actions needed for this type
            artistAddress: address(0), // Not applicable
            artworkId: _artworkId
        });
        emit ArtworkRemoved(_artworkId, msg.sender); // Event emitted before voting, adjust based on desired flow
    }

    function getArtworkDetails(uint256 _artworkId) external view returns (Artwork memory) {
        require(_artworkId > 0 && _artworkId <= artworkCounter && artworks[_artworkId].id == _artworkId, "Artwork does not exist");
        return artworks[_artworkId];
    }


    // --- 4. Dynamic Artwork Evolution Functions ---

    function proposeArtworkEvolution(uint256 _artworkId, string memory _evolutionDescription, string memory _evolutionIPFSHash) external onlyMembers contractNotPaused {
        require(_artworkId > 0 && _artworkId <= artworkCounter && artworks[_artworkId].id == _artworkId, "Original artwork does not exist");
        require(artworks[_artworkId].curated, "Original artwork must be curated to propose evolution");

        artworkCounter++; // Increment artwork counter for the new evolution artwork
        uint256 evolutionArtworkId = artworkCounter;

        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalType: ProposalType.ARTWORK_EVOLUTION,
            description: string(abi.encodePacked("Propose evolution of artwork ID ", Strings.toString(_artworkId))),
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposer: msg.sender,
            actions: "", // No actions needed for this type
            artistAddress: address(0), // Not applicable
            artworkId: _artworkId // Original artwork ID
        });

        // Store evolution artwork details temporarily - finalized after proposal execution
        artworks[evolutionArtworkId] = Artwork({
            id: evolutionArtworkId,
            title: string(abi.encodePacked("Evolution of ", artworks[_artworkId].title)), // Default title, artists can refine in future iterations
            description: _evolutionDescription,
            ipfsHash: _evolutionIPFSHash,
            artist: msg.sender, // Evolver is the artist
            curated: false, // Evolution starts as not curated
            submissionTime: block.timestamp // Submission time of evolution proposal
        });

        emit ArtworkEvolutionProposed(proposalCounter, _artworkId, msg.sender);
    }

    function voteOnArtworkEvolution(uint256 _proposalId, bool _support) external onlyMembers proposalExists(_proposalId) proposalNotExecuted(_proposalId) votingPeriodActive(_proposalId) contractNotPaused {
        require(proposals[_proposalId].proposalType == ProposalType.ARTWORK_EVOLUTION, "Proposal type is not artwork evolution");
        require(!votes[_proposalId][msg.sender], "Address has already voted on this proposal");
        votes[_proposalId][msg.sender] = true;

        if (_support) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ArtworkEvolutionVoted(_proposalId, msg.sender, _support);
    }

    function executeArtworkEvolutionProposal(uint256 _proposalId) external onlyGovernance proposalExists(_proposalId) proposalNotExecuted(_proposalId) contractNotPaused {
        require(proposals[_proposalId].proposalType == ProposalType.ARTWORK_EVOLUTION, "Proposal type is not artwork evolution");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period is still active");

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        require(totalVotes > 0, "No votes cast, cannot execute"); // Prevent division by zero in rare cases
        uint256 yesPercentage = (proposals[_proposalId].yesVotes * 100) / totalVotes;

        if (yesPercentage >= quorumPercentage) {
            uint256 originalArtworkId = proposals[_proposalId].artworkId;
            uint256 evolvedArtworkId = artworkCounter; // Evolution artwork ID was set during proposal
            artworks[evolvedArtworkId].curated = true; // Curate the evolved artwork upon successful proposal
            artworkEvolutions[originalArtworkId].push(evolvedArtworkId); // Link evolution to original artwork
            proposals[_proposalId].executed = true;
            emit ArtworkEvolutionExecuted(_proposalId, evolvedArtworkId, originalArtworkId);
        } else {
            proposals[_proposalId].executed = true; // Mark as executed even if failed to avoid re-execution
            // Proposal failed quorum - could emit an event if needed
            // Consider reverting the artworkCounter decrement if evolution proposal fails to keep IDs sequential, or handle ID gaps.
        }
    }

    function getArtworkEvolutions(uint256 _artworkId) external view returns (uint256[] memory) {
        require(_artworkId > 0 && _artworkId <= artworkCounter && artworks[_artworkId].id == _artworkId, "Artwork does not exist");
        return artworkEvolutions[_artworkId];
    }


    // --- 5. Interactive Art & Community Engagement Functions ---

    function interactWithArtwork(uint256 _artworkId, string memory _interactionDataHash) external onlyMembers contractNotPaused {
        require(_artworkId > 0 && _artworkId <= artworkCounter && artworks[_artworkId].id == _artworkId, "Artwork does not exist");
        require(artworks[_artworkId].curated, "Artwork must be curated for interaction");
        artworkInteractions[_artworkId].push(_interactionDataHash);
        emit ArtworkInteractionRecorded(_artworkId, msg.sender, _interactionDataHash);
    }

    function getArtworkInteractions(uint256 _artworkId) external view returns (string[] memory) {
        require(_artworkId > 0 && _artworkId <= artworkCounter && artworks[_artworkId].id == _artworkId, "Artwork does not exist");
        return artworkInteractions[_artworkId];
    }


    // --- 6. Governance & Generic Proposal Functions ---

    function createGenericProposal(string memory _proposalDescription, bytes calldata _actions) external onlyGovernance contractNotPaused {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalType: ProposalType.GENERIC,
            description: _proposalDescription,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposer: msg.sender,
            actions: _actions,
            artistAddress: address(0), // Not applicable
            artworkId: 0 // Not applicable
        });
        emit GenericProposalCreated(proposalCounter, _proposalDescription, msg.sender);
    }

    function voteOnGenericProposal(uint256 _proposalId, bool _support) external onlyMembers proposalExists(_proposalId) proposalNotExecuted(_proposalId) votingPeriodActive(_proposalId) contractNotPaused {
        require(proposals[_proposalId].proposalType == ProposalType.GENERIC, "Proposal type is not generic");
        require(!votes[_proposalId][msg.sender], "Address has already voted on this proposal");
        votes[_proposalId][msg.sender] = true;

        if (_support) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit GenericProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeGenericProposal(uint256 _proposalId) external onlyGovernance proposalExists(_proposalId) proposalNotExecuted(_proposalId) contractNotPaused {
        require(proposals[_proposalId].proposalType == ProposalType.GENERIC, "Proposal type is not generic");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period is still active");

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        require(totalVotes > 0, "No votes cast, cannot execute"); // Prevent division by zero in rare cases
        uint256 yesPercentage = (proposals[_proposalId].yesVotes * 100) / totalVotes;

        if (yesPercentage >= quorumPercentage) {
            (bool success, ) = address(this).delegatecall(proposals[_proposalId].actions); // Delegatecall for complex actions. Be very cautious with delegatecall.
            require(success, "Generic proposal execution failed");
            proposals[_proposalId].executed = true;
            emit GenericProposalExecuted(_proposalId);
        } else {
            proposals[_proposalId].executed = true; // Mark as executed even if failed to avoid re-execution
            // Proposal failed quorum - could emit an event if needed
        }
    }

    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getProposalVotingStatus(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256 yesVotes, uint256 noVotes, uint256 endTime, bool executed) {
        return (proposals[_proposalId].yesVotes, proposals[_proposalId].noVotes, proposals[_proposalId].endTime, proposals[_proposalId].executed);
    }

    function changeGovernance(address _newGovernance) external onlyGovernance contractNotPaused {
        require(_newGovernance != address(0), "New governance address cannot be zero address");
        governance = _newGovernance;
        emit GovernanceChanged(_newGovernance);
    }


    // --- 7. Utility & Information Functions ---

    function getCollectiveName() external view returns (string memory) {
        return collectiveName;
    }

    function getVotingPeriod() external view returns (uint256) {
        return votingPeriod;
    }

    function getQuorumPercentage() external view returns (uint256) {
        return quorumPercentage;
    }

    function isContractPaused() external view returns (bool) {
        return paused;
    }

    function getMemberCount() external view returns (uint256) {
        return artistMemberCount;
    }

    function getArtworkCount() external view returns (uint256) {
        return artworkCounter;
    }

    // --- Library for String Conversion (Needed for event string encoding) ---
    // Minimal String conversion for addresses and numbers for event descriptions.
    library Strings {
        function toString(address account) internal pure returns (string memory) {
            return toString(uint160(account));
        }

        function toString(uint256 value) internal pure returns (string memory) {
            // Inspired by OraclizeAPI's implementation - MIT licence
            // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.5.sol

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
}
```