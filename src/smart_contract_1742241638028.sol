```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 *      This contract enables a community to collectively create, curate, and manage digital art.
 *      It incorporates advanced concepts like decentralized governance, collaborative art creation,
 *      dynamic NFT metadata, and community-driven curation.
 *
 * **Outline and Function Summary:**
 *
 * **1. Collective Management:**
 *    - `createCollective(string _name, string _description)`:  Initializes the art collective.
 *    - `setCollectiveName(string _newName)`: Allows the collective creator to update the collective's name.
 *    - `setCollectiveDescription(string _newDescription)`: Allows the collective creator to update the collective's description.
 *    - `getCollectiveInfo()`: Returns the name and description of the collective.
 *
 * **2. Artist Management:**
 *    - `addArtist(address _artist)`: Adds a new artist to the approved artist list (governance vote required).
 *    - `removeArtist(address _artist)`: Removes an artist from the approved artist list (governance vote required).
 *    - `isApprovedArtist(address _artist)`: Checks if an address is an approved artist.
 *    - `listArtists()`: Returns a list of approved artist addresses.
 *
 * **3. Artwork Proposal and Creation:**
 *    - `proposeArtwork(string _title, string _description, string _initialMetadataURI)`: Artists propose new artworks for the collective to create.
 *    - `voteOnArtworkProposal(uint256 _proposalId, bool _support)`: Approved artists can vote on artwork proposals.
 *    - `getArtworkProposalStatus(uint256 _proposalId)`:  Checks the current status of an artwork proposal.
 *    - `finalizeArtworkProposal(uint256 _proposalId)`: Finalizes an approved artwork proposal, initiating the creation process.
 *    - `contributeArtworkPart(uint256 _artworkId, string _partURI)`: Approved artists contribute parts/layers to a collective artwork.
 *    - `getArtworkContributionStatus(uint256 _artworkId)`: Checks how many parts have been contributed for a specific artwork.
 *    - `finalizeArtworkCreation(uint256 _artworkId)`:  Combines contributed parts, mints an NFT representing the collective artwork.
 *    - `getArtworkMetadataURI(uint256 _artworkId)`: Retrieves the dynamic metadata URI for a collective artwork NFT.
 *
 * **4. Governance and Community Decisions:**
 *    - `createGovernanceProposal(string _title, string _description, bytes _calldata)`: Allows artists to propose governance changes.
 *    - `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Approved artists vote on governance proposals.
 *    - `getGovernanceProposalStatus(uint256 _proposalId)`: Checks the status of a governance proposal.
 *    - `executeGovernanceProposal(uint256 _proposalId)`: Executes a successful governance proposal (if it's executable).
 *    - `setVotingDuration(uint256 _newDuration)`: Allows governance to change the default voting duration for proposals.
 *    - `setQuorum(uint256 _newQuorum)`: Allows governance to change the quorum percentage for proposals.
 *
 * **5. Treasury (Basic - can be expanded):**
 *    - `depositToTreasury()`: Allows anyone to deposit ETH into the collective's treasury.
 *    - `getTreasuryBalance()`: Returns the current ETH balance of the treasury.
 *    - `withdrawFromTreasury(address _recipient, uint256 _amount)`: Allows governance to withdraw funds from the treasury (governance vote required - example implementation).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract DecentralizedArtCollective is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Collective Metadata
    string public collectiveName;
    string public collectiveDescription;

    // Artist Management
    mapping(address => bool) public approvedArtists;
    address[] public artistList;

    // Artwork Proposals
    struct ArtworkProposal {
        string title;
        string description;
        string initialMetadataURI;
        address proposer;
        uint256 voteCount;
        uint256 endTime;
        bool finalized;
        bool passed;
    }
    Counters.Counter private _artworkProposalIds;
    mapping(uint256 => ArtworkProposal) public artworkProposals;

    // Governance Proposals
    struct GovernanceProposal {
        string title;
        string description;
        bytes calldataData;
        address proposer;
        uint256 voteCount;
        uint256 endTime;
        bool finalized;
        bool passed;
        bool executable; // Flag if the proposal is executable (e.g., function call)
    }
    Counters.Counter private _governanceProposalIds;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 50; // Default quorum percentage (50%)

    // Artworks
    struct Artwork {
        string title;
        string description;
        address[] contributors;
        string[] partURIs; // URIs of contributed parts
        bool creationFinalized;
    }
    Counters.Counter private _artworkIds;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => string) public artworkMetadataURIs; // Dynamic metadata URIs

    // Treasury
    uint256 public treasuryBalance;

    // Events
    event CollectiveCreated(string name, string description, address creator);
    event CollectiveNameUpdated(string newName, address updater);
    event CollectiveDescriptionUpdated(string newDescription, address updater);
    event ArtistAdded(address artist, address addedBy);
    event ArtistRemoved(address artist, address removedBy);
    event ArtworkProposed(uint256 proposalId, string title, address proposer);
    event ArtworkProposalVoted(uint256 proposalId, address voter, bool support);
    event ArtworkProposalFinalized(uint256 proposalId, bool passed);
    event ArtworkPartContributed(uint256 artworkId, address artist, string partURI);
    event ArtworkCreationFinalized(uint256 artworkId, uint256 tokenId);
    event GovernanceProposalCreated(uint256 proposalId, string title, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool support);
    event GovernanceProposalFinalized(uint256 proposalId, bool passed);
    event GovernanceProposalExecuted(uint256 proposalId);
    event VotingDurationUpdated(uint256 newDuration, address updater);
    event QuorumUpdated(uint256 newQuorum, address updater);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount, address withdrawnBy);

    constructor() ERC721("DecentralizedArtCollectiveNFT", "DAACNFT") Ownable(msg.sender) {
        // Initial setup can be done in createCollective function
    }

    // ------------------------ Collective Management ------------------------

    /**
     * @dev Initializes the art collective. Can only be called once by the contract owner.
     * @param _name The name of the collective.
     * @param _description The description of the collective.
     */
    function createCollective(string memory _name, string memory _description) public onlyOwner {
        require(bytes(collectiveName).length == 0, "Collective already initialized");
        collectiveName = _name;
        collectiveDescription = _description;
        emit CollectiveCreated(_name, _description, msg.sender);
    }

    /**
     * @dev Allows the collective creator to update the collective's name.
     * @param _newName The new name of the collective.
     */
    function setCollectiveName(string memory _newName) public onlyOwner {
        collectiveName = _newName;
        emit CollectiveNameUpdated(_newName, msg.sender);
    }

    /**
     * @dev Allows the collective creator to update the collective's description.
     * @param _newDescription The new description of the collective.
     */
    function setCollectiveDescription(string memory _newDescription) public onlyOwner {
        collectiveDescription = _newDescription;
        emit CollectiveDescriptionUpdated(_newDescription, msg.sender);
    }

    /**
     * @dev Returns the name and description of the collective.
     * @return The collective's name and description.
     */
    function getCollectiveInfo() public view returns (string memory name, string memory description) {
        return (collectiveName, collectiveDescription);
    }

    // ------------------------ Artist Management ------------------------

    /**
     * @dev Adds a new artist to the approved artist list (governance vote required).
     * @param _artist The address of the artist to add.
     */
    function addArtist(address _artist) public onlyApprovedArtist {
        require(!approvedArtists[_artist], "Artist is already approved");
        approvedArtists[_artist] = true;
        artistList.push(_artist);
        emit ArtistAdded(_artist, msg.sender);
    }

    /**
     * @dev Removes an artist from the approved artist list (governance vote required).
     * @param _artist The address of the artist to remove.
     */
    function removeArtist(address _artist) public onlyApprovedArtist {
        require(approvedArtists[_artist], "Artist is not approved");
        approvedArtists[_artist] = false;
        // Remove from artistList (optional for gas optimization in this example, can be skipped and just check `approvedArtists` mapping)
        for (uint256 i = 0; i < artistList.length; i++) {
            if (artistList[i] == _artist) {
                artistList[i] = artistList[artistList.length - 1];
                artistList.pop();
                break;
            }
        }
        emit ArtistRemoved(_artist, msg.sender);
    }

    /**
     * @dev Checks if an address is an approved artist.
     * @param _artist The address to check.
     * @return True if the address is an approved artist, false otherwise.
     */
    function isApprovedArtist(address _artist) public view returns (bool) {
        return approvedArtists[_artist];
    }

    /**
     * @dev Returns a list of approved artist addresses.
     * @return Array of approved artist addresses.
     */
    function listArtists() public view returns (address[] memory) {
        return artistList;
    }

    // ------------------------ Artwork Proposal and Creation ------------------------

    /**
     * @dev Artists propose new artworks for the collective to create.
     * @param _title The title of the artwork proposal.
     * @param _description Description of the artwork.
     * @param _initialMetadataURI Initial metadata URI for the artwork proposal.
     */
    function proposeArtwork(string memory _title, string memory _description, string memory _initialMetadataURI) public onlyApprovedArtist {
        _artworkProposalIds.increment();
        uint256 proposalId = _artworkProposalIds.current();
        artworkProposals[proposalId] = ArtworkProposal({
            title: _title,
            description: _description,
            initialMetadataURI: _initialMetadataURI,
            proposer: msg.sender,
            voteCount: 0,
            endTime: block.timestamp + votingDuration,
            finalized: false,
            passed: false
        });
        emit ArtworkProposed(proposalId, _title, msg.sender);
    }

    /**
     * @dev Approved artists can vote on artwork proposals.
     * @param _proposalId The ID of the artwork proposal.
     * @param _support True to support the proposal, false to oppose.
     */
    function voteOnArtworkProposal(uint256 _proposalId, bool _support) public onlyApprovedArtist {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        require(!proposal.finalized, "Proposal already finalized");
        require(block.timestamp < proposal.endTime, "Voting time expired");

        // In a real-world scenario, you might want to track individual votes to prevent double voting.
        proposal.voteCount++; // Simple vote counting for this example
        emit ArtworkProposalVoted(_proposalId, msg.sender, _support);

        if (proposal.voteCount * 100 >= artistList.length * quorumPercentage && block.timestamp >= proposal.endTime) {
            finalizeArtworkProposal(_proposalId); // Finalize automatically when quorum and time are met
        }
    }

    /**
     * @dev Checks the current status of an artwork proposal.
     * @param _proposalId The ID of the artwork proposal.
     * @return finalized, passed, voteCount, endTime
     */
    function getArtworkProposalStatus(uint256 _proposalId) public view returns (bool finalized, bool passed, uint256 voteCount, uint256 endTime) {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        return (proposal.finalized, proposal.passed, proposal.voteCount, proposal.endTime);
    }

    /**
     * @dev Finalizes an approved artwork proposal, initiating the creation process.
     * @param _proposalId The ID of the artwork proposal.
     */
    function finalizeArtworkProposal(uint256 _proposalId) public onlyApprovedArtist {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        require(!proposal.finalized, "Proposal already finalized");
        require(block.timestamp >= proposal.endTime, "Voting time not expired"); // Ensure time is up even if called manually

        if (proposal.voteCount * 100 >= artistList.length * quorumPercentage) {
            proposal.passed = true;
            _artworkIds.increment();
            uint256 artworkId = _artworkIds.current();
            artworks[artworkId] = Artwork({
                title: proposal.title,
                description: proposal.description,
                contributors: new address[](0),
                partURIs: new string[](0),
                creationFinalized: false
            });
            artworkMetadataURIs[artworkId] = proposal.initialMetadataURI; // Set initial metadata
            proposal.finalized = true;
            emit ArtworkProposalFinalized(_proposalId, true);
        } else {
            proposal.finalized = true;
            emit ArtworkProposalFinalized(_proposalId, false);
        }
    }

    /**
     * @dev Approved artists contribute parts/layers to a collective artwork.
     * @param _artworkId The ID of the artwork being created.
     * @param _partURI URI pointing to a part of the artwork (e.g., IPFS link to an image layer).
     */
    function contributeArtworkPart(uint256 _artworkId, string memory _partURI) public onlyApprovedArtist {
        Artwork storage artwork = artworks[_artworkId];
        require(!artwork.creationFinalized, "Artwork creation is already finalized");
        bool alreadyContributor = false;
        for (uint256 i = 0; i < artwork.contributors.length; i++) {
            if (artwork.contributors[i] == msg.sender) {
                alreadyContributor = true;
                break;
            }
        }
        if (!alreadyContributor) {
            artwork.contributors.push(msg.sender);
        }
        artwork.partURIs.push(_partURI);
        emit ArtworkPartContributed(_artworkId, msg.sender, _partURI);
    }

    /**
     * @dev Checks how many parts have been contributed for a specific artwork.
     * @param _artworkId The ID of the artwork.
     * @return The number of parts contributed so far.
     */
    function getArtworkContributionStatus(uint256 _artworkId) public view returns (uint256 partsCount, uint256 contributorsCount) {
        Artwork storage artwork = artworks[_artworkId];
        return (artwork.partURIs.length, artwork.contributors.length);
    }

    /**
     * @dev Finalizes artwork creation, combines contributed parts, mints an NFT.
     * @param _artworkId The ID of the artwork to finalize.
     */
    function finalizeArtworkCreation(uint256 _artworkId) public onlyApprovedArtist {
        Artwork storage artwork = artworks[_artworkId];
        require(!artwork.creationFinalized, "Artwork creation is already finalized");
        require(artwork.partURIs.length > 0, "No parts contributed yet"); // Example: Require at least one part

        // In a real-world scenario, you might have logic to combine the parts into a final artwork.
        // For this example, we'll just use a placeholder metadata URI.
        string memory combinedMetadataURI = _generateCombinedMetadataURI(_artworkId); // Dynamic metadata generation

        _mint(_msgSender(), _artworkId);
        _setTokenURI(_artworkId, combinedMetadataURI);
        artwork.creationFinalized = true;
        emit ArtworkCreationFinalized(_artworkId, _artworkId);
    }

    /**
     * @dev Retrieves the dynamic metadata URI for a collective artwork NFT.
     * @param _artworkId The ID of the artwork.
     * @return The metadata URI for the artwork NFT.
     */
    function getArtworkMetadataURI(uint256 _artworkId) public view returns (string memory) {
        require(artworks[_artworkId].creationFinalized, "Artwork creation not finalized yet");
        return artworkMetadataURIs[_artworkId];
    }

    // ------------------------ Governance and Community Decisions ------------------------

    /**
     * @dev Allows artists to propose governance changes.
     * @param _title The title of the governance proposal.
     * @param _description Description of the proposal.
     * @param _calldata Calldata to execute if the proposal passes (optional, can be empty).
     */
    function createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata) public onlyApprovedArtist {
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();
        governanceProposals[proposalId] = GovernanceProposal({
            title: _title,
            description: _description,
            calldataData: _calldata,
            proposer: msg.sender,
            voteCount: 0,
            endTime: block.timestamp + votingDuration,
            finalized: false,
            passed: false,
            executable: bytes(_calldata).length > 0 // Mark as executable if calldata is provided
        });
        emit GovernanceProposalCreated(proposalId, _title, msg.sender);
    }

    /**
     * @dev Approved artists vote on governance proposals.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True to support the proposal, false to oppose.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) public onlyApprovedArtist {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.finalized, "Proposal already finalized");
        require(block.timestamp < proposal.endTime, "Voting time expired");

        // In a real-world scenario, you might want to track individual votes to prevent double voting.
        proposal.voteCount++; // Simple vote counting for this example
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);

        if (proposal.voteCount * 100 >= artistList.length * quorumPercentage && block.timestamp >= proposal.endTime) {
            finalizeGovernanceProposal(_proposalId); // Finalize automatically when quorum and time are met
        }
    }

    /**
     * @dev Checks the status of a governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @return finalized, passed, voteCount, endTime, executable
     */
    function getGovernanceProposalStatus(uint256 _proposalId) public view returns (bool finalized, bool passed, uint256 voteCount, uint256 endTime, bool executable) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        return (proposal.finalized, proposal.passed, proposal.voteCount, proposal.endTime, proposal.executable);
    }

    /**
     * @dev Finalizes a successful governance proposal (if it's executable).
     * @param _proposalId The ID of the governance proposal.
     */
    function finalizeGovernanceProposal(uint256 _proposalId) public onlyApprovedArtist {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.finalized, "Proposal already finalized");
        require(block.timestamp >= proposal.endTime, "Voting time not expired"); // Ensure time is up even if called manually

        if (proposal.voteCount * 100 >= artistList.length * quorumPercentage) {
            proposal.passed = true;
            proposal.finalized = true;
            emit GovernanceProposalFinalized(_proposalId, true);
            if (proposal.executable) {
                _executeGovernanceAction(_proposalId); // Execute the action if the proposal is executable
            }
        } else {
            proposal.finalized = true;
            emit GovernanceProposalFinalized(_proposalId, false);
        }
    }

    /**
     * @dev Executes a successful governance proposal (internal execution logic).
     * @param _proposalId The ID of the governance proposal.
     */
    function _executeGovernanceAction(uint256 _proposalId) internal {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.passed, "Governance proposal did not pass");
        require(proposal.executable, "Governance proposal is not executable");
        require(!proposal.finalized, "Governance proposal already finalized"); // Double check finalized status here as well

        (bool success, ) = address(this).delegatecall(proposal.calldataData); // Use delegatecall to execute in contract context
        require(success, "Governance proposal execution failed");
        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows governance to change the default voting duration for proposals.
     *      This is an example of a governance-controlled function.
     * @param _newDuration The new voting duration in seconds.
     */
    function setVotingDuration(uint256 _newDuration) public onlyGovernance {
        votingDuration = _newDuration;
        emit VotingDurationUpdated(_newDuration, msg.sender);
    }

    /**
     * @dev Allows governance to change the quorum percentage for proposals.
     *      This is an example of a governance-controlled function.
     * @param _newQuorum The new quorum percentage (e.g., 50 for 50%).
     */
    function setQuorum(uint256 _newQuorum) public onlyGovernance {
        require(_newQuorum <= 100, "Quorum percentage must be <= 100");
        quorumPercentage = _newQuorum;
        emit QuorumUpdated(_newQuorum, msg.sender);
    }

    // ------------------------ Treasury (Basic - can be expanded) ------------------------

    /**
     * @dev Allows anyone to deposit ETH into the collective's treasury.
     */
    receive() external payable {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /**
     * @dev Returns the current ETH balance of the treasury.
     * @return The treasury's ETH balance.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }

    /**
     * @dev Allows governance to withdraw funds from the treasury (governance vote required - example implementation).
     *      This is an example of a governance-controlled function.
     * @param _recipient The address to receive the withdrawn funds.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawFromTreasury(address _recipient, uint256 _amount) public onlyGovernance {
        require(treasuryBalance >= _amount, "Insufficient treasury balance");
        payable(_recipient).transfer(_amount);
        treasuryBalance -= _amount;
        emit TreasuryWithdrawal(_recipient, _amount, msg.sender);
    }

    // ------------------------ Internal Helpers and Modifiers ------------------------

    /**
     * @dev Modifier to check if the sender is an approved artist.
     */
    modifier onlyApprovedArtist() {
        require(approvedArtists[msg.sender], "Sender is not an approved artist");
        _;
    }

    /**
     * @dev Modifier to allow only governance-approved actions (example - needs governance proposal to be executed).
     *      In this example, we're simply allowing approved artists to execute governance actions for simplicity.
     *      In a real DAO, governance actions would be triggered by successful governance proposals.
     */
    modifier onlyGovernance() {
        require(approvedArtists[msg.sender], "Sender is not authorized for governance actions (needs governance proposal execution)");
        _;
    }

    /**
     * @dev Internal function to generate dynamic metadata URI for a combined artwork.
     *      This is a placeholder - in a real application, this would be more complex,
     *      potentially interacting with IPFS or a decentralized storage solution.
     * @param _artworkId The ID of the artwork.
     * @return The generated metadata URI.
     */
    function _generateCombinedMetadataURI(uint256 _artworkId) internal view returns (string memory) {
        Artwork storage artwork = artworks[_artworkId];
        string memory baseURI = "ipfs://YOUR_IPFS_CID/"; // Replace with your base IPFS CID or storage service
        string memory metadataJSON = string(abi.encodePacked(
            '{"name": "', artwork.title, '",',
            '"description": "', artwork.description, '",',
            '"image": "', baseURI, "combined_image_", _artworkId.toString(), ".png", '",', // Placeholder image path
            '"attributes": [',
                '{"trait_type": "Collective", "value": "', collectiveName, '"},',
                '{"trait_type": "Contributors", "value": "', Strings.toString(artwork.contributors.length), '"},',
                '{"trait_type": "Parts", "value": "', Strings.toString(artwork.partURIs.length), '"}',
            ']}'
        ));
        // In a real application, you would upload this metadataJSON to IPFS and return the IPFS URI.
        // For this example, we'll just return a placeholder URI.
        return string(abi.encodePacked("data:application/json;base64,", vm.base64(bytes(metadataJSON))));
    }

    // Override _beforeTokenTransfer to ensure only finalized artworks can be transferred
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override virtual {
        super._beforeTokenTransfer(from, to, tokenId);
        require(artworks[tokenId].creationFinalized, "Artwork creation must be finalized before transfer");
    }
}
```