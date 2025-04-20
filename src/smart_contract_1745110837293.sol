```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (Example - Not for Production)
 * @dev A smart contract for a decentralized autonomous art collective,
 *      enabling artists to submit work, community to curate, and dynamic art evolution.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. `registerArtist(string _artistName)`: Allows artists to register with the collective.
 * 2. `submitArtwork(string _title, string _ipfsHash, string _description)`: Registered artists can submit artwork proposals.
 * 3. `voteOnArtwork(uint _artworkId, bool _approve)`: Community members (token holders) can vote on artwork submissions.
 * 4. `finalizeArtworkCuration(uint _artworkId)`:  Executes curation after voting period, accepting or rejecting artwork.
 * 5. `viewArtworkDetails(uint _artworkId)`: Allows anyone to view details of a submitted artwork.
 * 6. `buyArtworkFraction(uint _artworkId, uint _fractionAmount)`: Allows users to buy fractions of curated artworks.
 * 7. `sellArtworkFraction(uint _artworkId, uint _fractionAmount)`: Allows users to sell fractions of curated artworks.
 * 8. `transferArtworkFraction(uint _artworkId, address _recipient, uint _fractionAmount)`: Allows users to transfer artwork fractions to others.
 * 9. `getArtistArtworks(address _artistAddress)`: Retrieves a list of artworks submitted by a specific artist.
 * 10. `getCuratedArtworks()`: Retrieves a list of all curated and accepted artworks.
 * 11. `getRandomCuratedArtwork()`: Returns a random curated artwork ID.
 *
 * **DAO & Governance Functions:**
 * 12. `proposeNewParameter(string _parameterName, uint _newValue)`: Token holders can propose changes to contract parameters.
 * 13. `voteOnParameterProposal(uint _proposalId, bool _approve)`: Token holders can vote on parameter change proposals.
 * 14. `executeParameterProposal(uint _proposalId)`: Executes a successful parameter change proposal.
 * 15. `delegateVotingPower(address _delegateAddress)`: Token holders can delegate their voting power to another address.
 * 16. `revokeDelegation()`: Revokes voting power delegation.
 *
 * **Dynamic & Advanced Features:**
 * 17. `triggerArtworkEvolution(uint _artworkId)`: Allows initiating an "evolution" event for dynamic artworks (based on community vote or time).
 * 18. `setArtworkEvolutionMetadata(uint _artworkId, string _newMetadataIPFSHash)`:  (Admin/Curator) Sets the new metadata for an evolved artwork.
 * 19. `claimArtistRoyalties(uint _artworkId)`: Artists can claim accumulated royalties from artwork fraction sales.
 * 20. `donateToCollective()`: Allows users to donate ETH to the collective's fund.
 * 21. `withdrawDonations(uint _amount)`: (DAO Controlled) Allows withdrawal of funds from the collective's donation pool for collective purposes.
 * 22. `emergencyPause()`: (Admin Only)  Emergency pause function to halt critical contract operations in case of unforeseen issues.
 * 23. `emergencyUnpause()`: (Admin Only)  Unpauses the contract after an emergency pause.
 */

contract DecentralizedAutonomousArtCollective {
    // -------- State Variables --------

    address public owner; // Contract owner (DAO multisig or similar)
    string public collectiveName;
    uint public curationVotingPeriod; // Duration of artwork curation voting in blocks
    uint public parameterVotingPeriod; // Duration of parameter voting in blocks
    uint public curationQuorumPercentage = 50; // Percentage of votes needed for curation quorum
    uint public parameterQuorumPercentage = 60; // Percentage of votes needed for parameter change quorum
    uint public fractionPrice = 0.01 ether; // Default price per artwork fraction
    uint public royaltyPercentage = 5; // Artist royalty percentage on fraction sales

    bool public paused = false; // Emergency pause state

    uint public nextArtistId = 1;
    mapping(address => uint) public artistIds; // Address to Artist ID
    mapping(uint => Artist) public artists;
    address[] public registeredArtists;

    uint public nextArtworkId = 1;
    mapping(uint => Artwork) public artworks;
    Artwork[] public curatedArtworks; // Array to store curated artworks IDs for easy access

    uint public nextProposalId = 1;
    mapping(uint => ParameterProposal) public parameterProposals;

    mapping(address => address) public votingDelegations; // Delegator => Delegate

    mapping(uint => mapping(address => uint)) public artworkFractionsOwned; // Artwork ID => Owner => Fraction Count

    uint public donationPoolBalance;

    // -------- Structs --------

    struct Artist {
        uint id;
        address artistAddress;
        string artistName;
        bool registered;
    }

    struct Artwork {
        uint id;
        address artistAddress;
        string title;
        string ipfsHash; // IPFS hash of artwork metadata
        string description;
        bool curated;
        uint curationStartTime;
        uint curationEndTime;
        uint yesVotes;
        uint noVotes;
        bool evolutionTriggered;
        string currentMetadataIPFSHash; // IPFS hash of current artwork metadata (can evolve)
        uint totalFractions; // Total fractions minted for this artwork
        uint fractionsSold;
        uint accumulatedRoyalties;
    }

    struct ParameterProposal {
        uint id;
        string parameterName;
        uint newValue;
        uint proposalStartTime;
        uint proposalEndTime;
        uint yesVotes;
        uint noVotes;
        bool executed;
    }

    // -------- Events --------

    event ArtistRegistered(uint artistId, address artistAddress, string artistName);
    event ArtworkSubmitted(uint artworkId, address artistAddress, string title, string ipfsHash);
    event ArtworkVoteCast(uint artworkId, address voter, bool vote);
    event ArtworkCurated(uint artworkId, bool accepted);
    event ArtworkFractionBought(uint artworkId, address buyer, uint fractionAmount);
    event ArtworkFractionSold(uint artworkId, address seller, address buyer, uint fractionAmount);
    event ArtworkFractionTransferred(uint artworkId, address from, address to, uint fractionAmount);
    event ParameterProposalCreated(uint proposalId, string parameterName, uint newValue);
    event ParameterVoteCast(uint proposalId, address voter, bool vote);
    event ParameterProposalExecuted(uint proposalId, string parameterName, uint newValue);
    event VotingPowerDelegated(address delegator, address delegate);
    event VotingPowerRevoked(address delegator);
    event ArtworkEvolutionTriggered(uint artworkId);
    event ArtworkMetadataUpdated(uint artworkId, string newMetadataIPFSHash);
    event RoyaltiesClaimed(uint artworkId, address artist, uint amount);
    event DonationReceived(address donor, uint amount);
    event DonationsWithdrawn(address withdrawer, uint amount);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
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

    modifier onlyRegisteredArtist() {
        require(artists[artistIds[msg.sender]].registered, "Only registered artists can call this function.");
        _;
    }

    modifier onlyTokenHolders() {
        // Placeholder for token holding check - Replace with actual token logic if integrated.
        // For simplicity, assuming everyone with ETH can vote for now.
        // In a real scenario, this would check for holding a governance token (ERC20/ERC721).
        _;
    }

    modifier onlyCurator() {
        // Placeholder for curator role check - Implement curator logic based on DAO governance.
        // For simplicity, allowing contract owner to curate.
        require(msg.sender == owner, "Only curators can call this function (Owner in this example).");
        _;
    }

    // -------- Constructor --------

    constructor(string memory _collectiveName, uint _curationVotingBlocks, uint _parameterVotingBlocks) {
        owner = msg.sender;
        collectiveName = _collectiveName;
        curationVotingPeriod = _curationVotingBlocks;
        parameterVotingPeriod = _parameterVotingBlocks;
        donationPoolBalance = 0;
    }

    // -------- Artist Registration --------

    function registerArtist(string memory _artistName) external whenNotPaused {
        require(artistIds[msg.sender] == 0, "Artist already registered.");
        uint artistId = nextArtistId++;
        artists[artistId] = Artist(artistId, msg.sender, _artistName, true);
        artistIds[msg.sender] = artistId;
        registeredArtists.push(msg.sender);
        emit ArtistRegistered(artistId, msg.sender, _artistName);
    }

    // -------- Artwork Submission & Curation --------

    function submitArtwork(string memory _title, string memory _ipfsHash, string memory _description) external whenNotPaused onlyRegisteredArtist {
        uint artworkId = nextArtworkId++;
        artworks[artworkId] = Artwork({
            id: artworkId,
            artistAddress: msg.sender,
            title: _title,
            ipfsHash: _ipfsHash,
            description: _description,
            curated: false,
            curationStartTime: 0,
            curationEndTime: 0,
            yesVotes: 0,
            noVotes: 0,
            evolutionTriggered: false,
            currentMetadataIPFSHash: _ipfsHash, // Initial metadata is the submitted metadata
            totalFractions: 100, // Example: 100 fractions per artwork
            fractionsSold: 0,
            accumulatedRoyalties: 0
        });
        emit ArtworkSubmitted(artworkId, msg.sender, _title, _ipfsHash);
    }

    function startArtworkCuration(uint _artworkId) external whenNotPaused onlyCurator {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        require(!artworks[_artworkId].curated, "Artwork already curated.");
        require(artworks[_artworkId].curationStartTime == 0, "Curation already in progress.");

        artworks[_artworkId].curationStartTime = block.number;
        artworks[_artworkId].curationEndTime = block.number + curationVotingPeriod;
    }

    function voteOnArtwork(uint _artworkId, bool _approve) external whenNotPaused onlyTokenHolders {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        require(artworks[_artworkId].curationStartTime != 0 && block.number <= artworks[_artworkId].curationEndTime, "Curation voting is not active.");
        require(!artworks[_artworkId].curated, "Artwork already curated.");

        // Prevent double voting (simple example - in real DAO, more robust voting mechanisms are needed)
        require(keccak256(abi.encode(msg.sender, _artworkId)) != keccak256(abi.encode(address(0), _artworkId)), "Already voted on this artwork."); // Placeholder double vote check

        if (_approve) {
            artworks[_artworkId].yesVotes++;
        } else {
            artworks[_artworkId].noVotes++;
        }
        emit ArtworkVoteCast(_artworkId, msg.sender, _approve);
    }

    function finalizeArtworkCuration(uint _artworkId) external whenNotPaused onlyCurator {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        require(!artworks[_artworkId].curated, "Artwork already curated.");
        require(block.number > artworks[_artworkId].curationEndTime, "Curation voting period is still active.");

        uint totalVotes = artworks[_artworkId].yesVotes + artworks[_artworkId].noVotes;
        uint quorumVotesNeeded = (totalVotes * curationQuorumPercentage) / 100;

        if (artworks[_artworkId].yesVotes >= quorumVotesNeeded) {
            artworks[_artworkId].curated = true;
            curatedArtworks.push(artworks[_artworkId]); // Add to curated artworks array
            emit ArtworkCurated(_artworkId, true);
        } else {
            emit ArtworkCurated(_artworkId, false); // Rejected even if quorum not met could be considered rejection
        }
    }

    function viewArtworkDetails(uint _artworkId) external view returns (Artwork memory) {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        return artworks[_artworkId];
    }

    function getArtistArtworks(address _artistAddress) external view returns (uint[] memory) {
        uint[] memory artistArtworkIds = new uint[](nextArtworkId); // Max possible size - can be optimized
        uint count = 0;
        for (uint i = 1; i < nextArtworkId; i++) {
            if (artworks[i].artistAddress == _artistAddress) {
                artistArtworkIds[count++] = i;
            }
        }
        uint[] memory result = new uint[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = artistArtworkIds[i];
        }
        return result;
    }

    function getCuratedArtworks() external view returns (uint[] memory) {
        uint[] memory curatedIds = new uint[](curatedArtworks.length);
        for (uint i = 0; i < curatedArtworks.length; i++) {
            curatedIds[i] = curatedArtworks[i].id;
        }
        return curatedIds;
    }

    function getRandomCuratedArtwork() external view returns (uint) {
        require(curatedArtworks.length > 0, "No curated artworks yet.");
        uint randomIndex = uint(keccak256(abi.encode(block.timestamp, block.difficulty, msg.sender))) % curatedArtworks.length;
        return curatedArtworks[randomIndex].id;
    }


    // -------- Artwork Fraction Ownership & Trading --------

    function buyArtworkFraction(uint _artworkId, uint _fractionAmount) external payable whenNotPaused {
        require(artworks[_artworkId].id != 0 && artworks[_artworkId].curated, "Artwork does not exist or is not curated.");
        require(_fractionAmount > 0, "Fraction amount must be greater than zero.");
        require(artworks[_artworkId].fractionsSold + _fractionAmount <= artworks[_artworkId].totalFractions, "Not enough fractions available.");

        uint totalPrice = _fractionAmount * fractionPrice;
        require(msg.value >= totalPrice, "Insufficient ETH sent.");

        artworkFractionsOwned[_artworkId][msg.sender] += _fractionAmount;
        artworks[_artworkId].fractionsSold += _fractionAmount;

        // Transfer funds to artist (minus royalty) and collective
        uint artistShare = (totalPrice * (100 - royaltyPercentage)) / 100;
        uint royaltyAmount = totalPrice - artistShare;

        payable(artworks[_artworkId].artistAddress).transfer(artistShare);
        artworks[_artworkId].accumulatedRoyalties += royaltyAmount;

        emit ArtworkFractionBought(_artworkId, msg.sender, _fractionAmount);

        // Refund extra ETH if sent
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function sellArtworkFraction(uint _artworkId, uint _fractionAmount) external whenNotPaused {
        require(artworks[_artworkId].id != 0 && artworks[_artworkId].curated, "Artwork does not exist or is not curated.");
        require(_fractionAmount > 0, "Fraction amount must be greater than zero.");
        require(artworkFractionsOwned[_artworkId][msg.sender] >= _fractionAmount, "Not enough fractions owned to sell.");

        uint totalPrice = _fractionAmount * fractionPrice; // Current price for buying back

        artworkFractionsOwned[_artworkId][msg.sender] -= _fractionAmount;
        artworks[_artworkId].fractionsSold -= _fractionAmount;

        payable(msg.sender).transfer(totalPrice); // Seller receives ETH

        emit ArtworkFractionSold(_artworkId, msg.sender, address(this), _fractionAmount); // Buyer is the contract in this case
    }

    function transferArtworkFraction(uint _artworkId, address _recipient, uint _fractionAmount) external whenNotPaused {
        require(artworks[_artworkId].id != 0 && artworks[_artworkId].curated, "Artwork does not exist or is not curated.");
        require(_recipient != address(0), "Invalid recipient address.");
        require(_fractionAmount > 0, "Fraction amount must be greater than zero.");
        require(artworkFractionsOwned[_artworkId][msg.sender] >= _fractionAmount, "Not enough fractions owned to transfer.");

        artworkFractionsOwned[_artworkId][msg.sender] -= _fractionAmount;
        artworkFractionsOwned[_artworkId][_recipient] += _fractionAmount;

        emit ArtworkFractionTransferred(_artworkId, msg.sender, _recipient, _fractionAmount);
    }

    function claimArtistRoyalties(uint _artworkId) external whenNotPaused onlyRegisteredArtist {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the artist of this artwork can claim royalties.");
        require(artworks[_artworkId].accumulatedRoyalties > 0, "No royalties to claim.");

        uint royaltyAmount = artworks[_artworkId].accumulatedRoyalties;
        artworks[_artworkId].accumulatedRoyalties = 0;

        payable(msg.sender).transfer(royaltyAmount);
        emit RoyaltiesClaimed(_artworkId, msg.sender, royaltyAmount);
    }


    // -------- DAO & Governance Functions --------

    function proposeNewParameter(string memory _parameterName, uint _newValue) external whenNotPaused onlyTokenHolders {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");

        uint proposalId = nextProposalId++;
        parameterProposals[proposalId] = ParameterProposal({
            id: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            proposalStartTime: block.number,
            proposalEndTime: block.number + parameterVotingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit ParameterProposalCreated(proposalId, _parameterName, _newValue);
    }

    function voteOnParameterProposal(uint _proposalId, bool _approve) external whenNotPaused onlyTokenHolders {
        require(parameterProposals[_proposalId].id != 0, "Proposal does not exist.");
        require(!parameterProposals[_proposalId].executed, "Proposal already executed.");
        require(block.number <= parameterProposals[_proposalId].proposalEndTime, "Parameter voting period is over.");

        // Prevent double voting (simple example - in real DAO, more robust voting mechanisms are needed)
        require(keccak256(abi.encode(msg.sender, _proposalId)) != keccak256(abi.encode(address(0), _proposalId)), "Already voted on this proposal."); // Placeholder double vote check

        if (_approve) {
            parameterProposals[_proposalId].yesVotes++;
        } else {
            parameterProposals[_proposalId].noVotes++;
        }
        emit ParameterVoteCast(_proposalId, msg.sender, _approve);
    }

    function executeParameterProposal(uint _proposalId) external whenNotPaused onlyOwner { // For simplicity, owner executes, in DAO, this would be automated
        require(parameterProposals[_proposalId].id != 0, "Proposal does not exist.");
        require(!parameterProposals[_proposalId].executed, "Proposal already executed.");
        require(block.number > parameterProposals[_proposalId].proposalEndTime, "Parameter voting period is still active.");

        uint totalVotes = parameterProposals[_proposalId].yesVotes + parameterProposals[_proposalId].noVotes;
        uint quorumVotesNeeded = (totalVotes * parameterQuorumPercentage) / 100;

        if (parameterProposals[_proposalId].yesVotes >= quorumVotesNeeded) {
            parameterProposals[_proposalId].executed = true;
            string memory paramName = parameterProposals[_proposalId].parameterName;
            uint newValue = parameterProposals[_proposalId].newValue;

            if (keccak256(bytes(paramName)) == keccak256(bytes("curationVotingPeriod"))) {
                curationVotingPeriod = newValue;
            } else if (keccak256(bytes(paramName)) == keccak256(bytes("parameterVotingPeriod"))) {
                parameterVotingPeriod = newValue;
            } else if (keccak256(bytes(paramName)) == keccak256(bytes("curationQuorumPercentage"))) {
                curationQuorumPercentage = newValue;
            } else if (keccak256(bytes(paramName)) == keccak256(bytes("parameterQuorumPercentage"))) {
                parameterQuorumPercentage = newValue;
            } else if (keccak256(bytes(paramName)) == keccak256(bytes("fractionPrice"))) {
                fractionPrice = newValue;
            } else if (keccak256(bytes(paramName)) == keccak256(bytes("royaltyPercentage"))) {
                royaltyPercentage = newValue;
            } else {
                revert("Unknown parameter name.");
            }

            emit ParameterProposalExecuted(_proposalId, paramName, newValue);
        } else {
            revert("Parameter proposal did not reach quorum.");
        }
    }

    function delegateVotingPower(address _delegateAddress) external whenNotPaused onlyTokenHolders {
        require(_delegateAddress != address(0) && _delegateAddress != msg.sender, "Invalid delegate address.");
        votingDelegations[msg.sender] = _delegateAddress;
        emit VotingPowerDelegated(msg.sender, _delegateAddress);
    }

    function revokeDelegation() external whenNotPaused onlyTokenHolders {
        delete votingDelegations[msg.sender];
        emit VotingPowerRevoked(msg.sender);
    }


    // -------- Dynamic & Advanced Artwork Evolution --------

    function triggerArtworkEvolution(uint _artworkId) external whenNotPaused onlyCurator { // In a real DAO, this could be community-voted or time-based
        require(artworks[_artworkId].id != 0 && artworks[_artworkId].curated, "Artwork does not exist or is not curated.");
        require(!artworks[_artworkId].evolutionTriggered, "Artwork evolution already triggered.");

        artworks[_artworkId].evolutionTriggered = true;
        emit ArtworkEvolutionTriggered(_artworkId);
        // In a more advanced scenario, this could trigger a generative art process or external oracle call.
    }

    function setArtworkEvolutionMetadata(uint _artworkId, string memory _newMetadataIPFSHash) external whenNotPaused onlyCurator {
        require(artworks[_artworkId].id != 0 && artworks[_artworkId].curated, "Artwork does not exist or is not curated.");
        require(artworks[_artworkId].evolutionTriggered, "Artwork evolution not triggered yet.");
        require(bytes(_newMetadataIPFSHash).length > 0, "New metadata IPFS hash cannot be empty.");

        artworks[_artworkId].currentMetadataIPFSHash = _newMetadataIPFSHash;
        artworks[_artworkId].evolutionTriggered = false; // Reset evolution trigger for next evolution
        emit ArtworkMetadataUpdated(_artworkId, _newMetadataIPFSHash);
    }


    // -------- Collective Funding & Donations --------

    function donateToCollective() external payable whenNotPaused {
        require(msg.value > 0, "Donation amount must be greater than zero.");
        donationPoolBalance += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    function withdrawDonations(uint _amount) external whenNotPaused onlyOwner { // DAO controlled withdrawal in real scenario
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(donationPoolBalance >= _amount, "Insufficient funds in donation pool.");

        donationPoolBalance -= _amount;
        payable(owner).transfer(_amount); // Owner address receives funds - in DAO, this would be collective treasury
        emit DonationsWithdrawn(owner, _amount);
    }


    // -------- Emergency Pause Functionality --------

    function emergencyPause() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function emergencyUnpause() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // -------- Fallback & Receive --------
    receive() external payable {
        donateToCollective(); // Any ETH sent to contract without data will be treated as a donation.
    }

    fallback() external {}
}
```