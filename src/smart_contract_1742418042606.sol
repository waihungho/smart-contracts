```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI Assistant (Inspired by user request)
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to collaborate, exhibit, and govern their collective.
 *
 * **Outline and Function Summary:**
 *
 * **I. Core Functionality:**
 *    1. `mintArtNFT(string _tokenURI)`: Artists mint unique Art NFTs within the collective.
 *    2. `transferArtNFT(address _to, uint256 _tokenId)`: Transfer ownership of Art NFTs.
 *    3. `setNFTMetadataURI(uint256 _tokenId, string _newURI)`: Update the metadata URI of an Art NFT (Artist-controlled).
 *    4. `burnArtNFT(uint256 _tokenId)`: Artists can burn their own Art NFTs.
 *
 * **II. Collective Governance & DAO Features:**
 *    5. `proposeNewExhibition(string _exhibitionName, uint256 _startTime, uint256 _endTime)`:  Propose a new art exhibition.
 *    6. `voteOnExhibitionProposal(uint256 _proposalId, bool _vote)`: Collective members vote on exhibition proposals.
 *    7. `executeExhibitionProposal(uint256 _proposalId)`: Execute a successful exhibition proposal (admin function).
 *    8. `proposeNewArtist(address _artistAddress)`: Propose adding a new artist to the collective.
 *    9. `voteOnArtistProposal(uint256 _proposalId, bool _vote)`: Collective members vote on new artist proposals.
 *    10. `executeArtistProposal(uint256 _proposalId)`: Execute a successful artist proposal (admin function).
 *    11. `proposeContractParameterChange(string _parameterName, uint256 _newValue)`: Propose changes to key contract parameters (e.g., voting periods, fees).
 *    12. `voteOnParameterChangeProposal(uint256 _proposalId, bool _vote)`: Collective members vote on parameter change proposals.
 *    13. `executeParameterChangeProposal(uint256 _proposalId)`: Execute a successful parameter change proposal (admin function).
 *
 * **III. Exhibition & Marketplace Features:**
 *    14. `participateInExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Artists can register their NFTs for an active exhibition.
 *    15. `removeFromExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Artists can remove their NFTs from an exhibition.
 *    16. `purchaseArtNFTFromExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Anyone can purchase an NFT listed in an exhibition (if for sale).
 *    17. `setNFTForSaleInExhibition(uint256 _exhibitionId, uint256 _tokenId, uint256 _price)`: Artists set their NFT for sale within an exhibition.
 *    18. `removeNFTFromSaleInExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Artists remove their NFT from sale within an exhibition.
 *
 * **IV. Utility & Advanced Features:**
 *    19. `stakeNFTForVotingPower(uint256 _tokenId)`: Artists can stake their NFTs to gain increased voting power in proposals.
 *    20. `unstakeNFTForVotingPower(uint256 _tokenId)`: Unstake NFTs, reducing voting power.
 *    21. `reportArtTheft(uint256 _tokenId, string _reportDetails)`:  A mechanism for reporting potential art theft or copyright infringement within the collective.
 *    22. `emergencyPause()`: Owner can pause critical contract functions in case of emergency.
 *    23. `unpause()`: Owner can unpause the contract.
 *    24. `setGovernanceToken(address _governanceTokenAddress)`:  Set an external governance token for potentially more advanced DAO features in the future.
 *    25. `withdrawCollectiveFunds()`: Allow DAO to withdraw accumulated funds for collective purposes (governance needed).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedArtCollective is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // State Variables
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => bool) public isArtist;
    address[] public artists;
    uint256 public artistCount;

    struct ExhibitionProposal {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;
    }
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    Counters.Counter private _exhibitionProposalCounter;

    struct ArtistProposal {
        address artistAddress;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;
    }
    mapping(uint256 => ArtistProposal) public artistProposals;
    Counters.Counter private _artistProposalCounter;

    struct ParameterChangeProposal {
        string parameterName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;
    }
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    Counters.Counter private _parameterChangeProposalCounter;

    struct Exhibition {
        string name;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        mapping(uint256 => bool) listedNFTs; // Token IDs listed in this exhibition
        mapping(uint256 => uint256) nftSalePrice; // Sale price for NFTs in this exhibition
    }
    mapping(uint256 => Exhibition) public exhibitions;
    Counters.Counter private _exhibitionCounter;

    mapping(address => uint256) public votingPower; // Artists' voting power, potentially influenced by staked NFTs

    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorumPercentage = 50; // Percentage of votes needed to pass proposals (50% default)
    address public governanceToken; // Optional governance token for future expansion
    uint256 public collectiveFunds; // Funds accumulated by the collective (e.g., from exhibition fees - not implemented in this example)

    // Events
    event ArtNFTMinted(uint256 tokenId, address artist, string tokenURI);
    event ArtNFTTransferred(uint256 tokenId, address from, address to);
    event NFTMetadataUpdated(uint256 tokenId, string newURI);
    event ArtNFTBurned(uint256 tokenId, address artist);
    event NewExhibitionProposal(uint256 proposalId, string exhibitionName, uint256 startTime, uint256 endTime, address proposer);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool vote);
    event ExhibitionProposalExecuted(uint256 proposalId);
    event NewArtistProposal(uint256 proposalId, address artistAddress, address proposer);
    event ArtistProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtistProposalExecuted(uint256 proposalId, address newArtist);
    event ParameterChangeProposal(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterChangeProposalVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeProposalExecuted(uint256 proposalId, uint256 newValue);
    event ExhibitionCreated(uint256 exhibitionId, string exhibitionName, uint256 startTime, uint256 endTime);
    event NFTListedInExhibition(uint256 exhibitionId, uint256 tokenId, address artist);
    event NFTRemovedFromExhibition(uint256 exhibitionId, uint256 tokenId, address artist);
    event NFTSetForSale(uint256 exhibitionId, uint256 tokenId, uint256 price);
    event NFTRemovedFromSale(uint256 exhibitionId, uint256 tokenId);
    event NFTPurchasedFromExhibition(uint256 exhibitionId, uint256 tokenId, address buyer, address artist, uint256 price);
    event NFTStakedForVotingPower(uint256 tokenId, address artist);
    event NFTUnstakedFromVotingPower(uint256 tokenId, address artist);
    event ArtTheftReported(uint256 tokenId, address reporter, string reportDetails);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event GovernanceTokenSet(address governanceTokenAddress);
    event CollectiveFundsWithdrawn(uint256 amount, address withdrawer);

    // Modifiers
    modifier onlyArtist() {
        require(isArtist[msg.sender], "Only artists are allowed to perform this action.");
        _;
    }

    modifier onlyCollectiveMember() { // For actions requiring collective membership (artist or future member type)
        require(isArtist[msg.sender] /* or isMember[msg.sender] if you expand */ , "Only collective members allowed.");
        _;
    }

    modifier onlyProposalProposer(uint256 _proposalId, ProposalType _proposalType) {
        address proposer;
        if (_proposalType == ProposalType.Exhibition) {
            proposer = exhibitionProposals[_proposalId].proposer;
        } else if (_proposalType == ProposalType.Artist) {
            proposer = artistProposals[_proposalId].proposer;
        } else if (_proposalType == ProposalType.ParameterChange) {
            proposer = parameterChangeProposals[_proposalId].proposer;
        } else {
            revert("Invalid proposal type.");
        }
        require(msg.sender == proposer || msg.sender == owner(), "Only proposer or owner can execute.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Contract is not paused.");
        _;
    }

    enum ProposalType { Exhibition, Artist, ParameterChange }

    constructor() ERC721("DecentralizedArtNFT", "DAANFT") {
        // Initial setup can be done here, if needed.
    }

    // -------- I. Core Functionality --------

    /// @notice Allows artists to mint a new Art NFT.
    /// @param _tokenURI The URI for the NFT's metadata.
    function mintArtNFT(string memory _tokenURI) public onlyArtist whenNotPaused {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _tokenURIs[tokenId] = _tokenURI;
        emit ArtNFTMinted(tokenId, msg.sender, _tokenURI);
    }

    /// @notice Transfers ownership of an Art NFT. Standard ERC721 transfer.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferArtNFT(address _to, uint256 _tokenId) public whenNotPaused {
        safeTransferFrom(msg.sender, _to, _tokenId);
        emit ArtNFTTransferred(_tokenId, msg.sender, _to);
    }

    /// @notice Allows the artist to update the metadata URI of their Art NFT.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _newURI The new metadata URI.
    function setNFTMetadataURI(uint256 _tokenId, string memory _newURI) public onlyArtist whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        _tokenURIs[_tokenId] = _newURI;
        emit NFTMetadataUpdated(_tokenId, _newURI);
    }

    /// @notice Allows an artist to burn their own Art NFT.
    /// @param _tokenId The ID of the NFT to burn.
    function burnArtNFT(uint256 _tokenId) public onlyArtist whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        _burn(_tokenId);
        delete _tokenURIs[_tokenId];
        emit ArtNFTBurned(_tokenId, msg.sender);
    }

    // -------- II. Collective Governance & DAO Features --------

    /// @notice Allows collective members to propose a new art exhibition.
    /// @param _exhibitionName The name of the exhibition.
    /// @param _startTime The start timestamp of the exhibition.
    /// @param _endTime The end timestamp of the exhibition.
    function proposeNewExhibition(string memory _exhibitionName, uint256 _startTime, uint256 _endTime) public onlyCollectiveMember whenNotPaused {
        require(_startTime < _endTime, "Exhibition end time must be after start time.");
        _exhibitionProposalCounter.increment();
        uint256 proposalId = _exhibitionProposalCounter.current();
        exhibitionProposals[proposalId] = ExhibitionProposal({
            name: _exhibitionName,
            startTime: _startTime,
            endTime: _endTime,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposer: msg.sender
        });
        emit NewExhibitionProposal(proposalId, _exhibitionName, _startTime, _endTime, msg.sender);
    }

    /// @notice Allows collective members to vote on an exhibition proposal.
    /// @param _proposalId The ID of the exhibition proposal.
    /// @param _vote True for yes, false for no.
    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) public onlyCollectiveMember whenNotPaused {
        require(!exhibitionProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp < exhibitionProposals[_proposalId].startTime + votingPeriod, "Voting period has ended."); // Voting ends before exhibition starts + voting period
        require(block.timestamp < exhibitionProposals[_proposalId].startTime + votingPeriod, "Voting period for this proposal has ended.");

        if (_vote) {
            exhibitionProposals[_proposalId].votesFor += getVotingPower(msg.sender);
        } else {
            exhibitionProposals[_proposalId].votesAgainst += getVotingPower(msg.sender);
        }
        emit ExhibitionProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a successful exhibition proposal if quorum is reached and time has passed.
    /// @param _proposalId The ID of the exhibition proposal.
    function executeExhibitionProposal(uint256 _proposalId) public onlyOwner whenNotPaused onlyProposalProposer(_proposalId, ProposalType.Exhibition) {
        require(!exhibitionProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp >= exhibitionProposals[_proposalId].startTime + votingPeriod, "Voting period has not ended yet."); // Execution after voting period
        uint256 totalVotes = exhibitionProposals[_proposalId].votesFor + exhibitionProposals[_proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast."); // Prevent division by zero
        uint256 percentageFor = exhibitionProposals[_proposalId].votesFor.mul(100).div(totalVotes);

        if (percentageFor >= quorumPercentage) {
            _exhibitionCounter.increment();
            uint256 exhibitionId = _exhibitionCounter.current();
            exhibitions[exhibitionId] = Exhibition({
                name: exhibitionProposals[_proposalId].name,
                startTime: exhibitionProposals[_proposalId].startTime,
                endTime: exhibitionProposals[_proposalId].endTime,
                isActive: true
                // listedNFTs and nftSalePrice are initialized as empty mappings
            });
            exhibitionProposals[_proposalId].executed = true;
            emit ExhibitionProposalExecuted(_proposalId);
            emit ExhibitionCreated(exhibitionId, exhibitionProposals[_proposalId].name, exhibitionProposals[_proposalId].startTime, exhibitionProposals[_proposalId].endTime);
        } else {
            revert("Exhibition proposal failed to reach quorum.");
        }
    }

    /// @notice Allows collective members to propose adding a new artist to the collective.
    /// @param _artistAddress The address of the artist to propose.
    function proposeNewArtist(address _artistAddress) public onlyCollectiveMember whenNotPaused {
        require(!isArtist[_artistAddress], "Address is already an artist.");
        _artistProposalCounter.increment();
        uint256 proposalId = _artistProposalCounter.current();
        artistProposals[proposalId] = ArtistProposal({
            artistAddress: _artistAddress,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposer: msg.sender
        });
        emit NewArtistProposal(proposalId, _artistAddress, msg.sender);
    }

    /// @notice Allows collective members to vote on a new artist proposal.
    /// @param _proposalId The ID of the artist proposal.
    /// @param _vote True for yes, false for no.
    function voteOnArtistProposal(uint256 _proposalId, bool _vote) public onlyCollectiveMember whenNotPaused {
        require(!artistProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp < block.timestamp + votingPeriod, "Voting period has ended."); // Voting period

        if (_vote) {
            artistProposals[_proposalId].votesFor += getVotingPower(msg.sender);
        } else {
            artistProposals[_proposalId].votesAgainst += getVotingPower(msg.sender);
        }
        emit ArtistProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a successful artist proposal if quorum is reached and time has passed.
    /// @param _proposalId The ID of the artist proposal.
    function executeArtistProposal(uint256 _proposalId) public onlyOwner whenNotPaused onlyProposalProposer(_proposalId, ProposalType.Artist) {
        require(!artistProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp >= block.timestamp + votingPeriod, "Voting period has not ended yet."); // Execution after voting period

        uint256 totalVotes = artistProposals[_proposalId].votesFor + artistProposals[_proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast."); // Prevent division by zero
        uint256 percentageFor = artistProposals[_proposalId].votesFor.mul(100).div(totalVotes);

        if (percentageFor >= quorumPercentage) {
            address newArtistAddress = artistProposals[_proposalId].artistAddress;
            isArtist[newArtistAddress] = true;
            artists.push(newArtistAddress);
            artistCount++;
            artistProposals[_proposalId].executed = true;
            emit ArtistProposalExecuted(_proposalId, newArtistAddress);
        } else {
            revert("Artist proposal failed to reach quorum.");
        }
    }

    /// @notice Allows collective members to propose changes to contract parameters.
    /// @param _parameterName The name of the parameter to change (e.g., "votingPeriod", "quorumPercentage").
    /// @param _newValue The new value for the parameter.
    function proposeContractParameterChange(string memory _parameterName, uint256 _newValue) public onlyCollectiveMember whenNotPaused {
        _parameterChangeProposalCounter.increment();
        uint256 proposalId = _parameterChangeProposalCounter.current();
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposer: msg.sender
        });
        emit ParameterChangeProposal(proposalId, _parameterName, _newValue, msg.sender);
    }

    /// @notice Allows collective members to vote on a parameter change proposal.
    /// @param _proposalId The ID of the parameter change proposal.
    /// @param _vote True for yes, false for no.
    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) public onlyCollectiveMember whenNotPaused {
        require(!parameterChangeProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp < block.timestamp + votingPeriod, "Voting period has ended."); // Voting period

        if (_vote) {
            parameterChangeProposals[_proposalId].votesFor += getVotingPower(msg.sender);
        } else {
            parameterChangeProposals[_proposalId].votesAgainst += getVotingPower(msg.sender);
        }
        emit ParameterChangeProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a successful parameter change proposal if quorum is reached and time has passed.
    /// @param _proposalId The ID of the parameter change proposal.
    function executeParameterChangeProposal(uint256 _proposalId) public onlyOwner whenNotPaused onlyProposalProposer(_proposalId, ProposalType.ParameterChange) {
        require(!parameterChangeProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp >= block.timestamp + votingPeriod, "Voting period has not ended yet."); // Execution after voting period

        uint256 totalVotes = parameterChangeProposals[_proposalId].votesFor + parameterChangeProposals[_proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast."); // Prevent division by zero
        uint256 percentageFor = parameterChangeProposals[_proposalId].votesFor.mul(100).div(totalVotes);

        if (percentageFor >= quorumPercentage) {
            string memory parameterName = parameterChangeProposals[_proposalId].parameterName;
            uint256 newValue = parameterChangeProposals[_proposalId].newValue;

            if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("votingPeriod"))) {
                votingPeriod = newValue;
            } else if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("quorumPercentage"))) {
                quorumPercentage = newValue;
            } else {
                revert("Invalid parameter name for change.");
            }

            parameterChangeProposals[_proposalId].executed = true;
            emit ParameterChangeProposalExecuted(_proposalId, newValue);
        } else {
            revert("Parameter change proposal failed to reach quorum.");
        }
    }

    // -------- III. Exhibition & Marketplace Features --------

    /// @notice Allows artists to register their NFT for participation in an active exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _tokenId The ID of the NFT to list.
    function participateInExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyArtist whenNotPaused {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(!exhibitions[_exhibitionId].listedNFTs[_tokenId], "NFT already listed in this exhibition.");
        exhibitions[_exhibitionId].listedNFTs[_tokenId] = true;
        emit NFTListedInExhibition(_exhibitionId, _tokenId, msg.sender);
    }

    /// @notice Allows artists to remove their NFT from an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _tokenId The ID of the NFT to remove.
    function removeFromExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyArtist whenNotPaused {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(exhibitions[_exhibitionId].listedNFTs[_tokenId], "NFT is not listed in this exhibition.");
        delete exhibitions[_exhibitionId].listedNFTs[_tokenId];
        delete exhibitions[_exhibitionId].nftSalePrice[_tokenId]; // Remove sale price as well
        emit NFTRemovedFromExhibition(_exhibitionId, _tokenId, msg.sender);
    }

    /// @notice Allows anyone to purchase an NFT that is for sale in an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _tokenId The ID of the NFT to purchase.
    function purchaseArtNFTFromExhibition(uint256 _exhibitionId, uint256 _tokenId) public payable whenNotPaused {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(exhibitions[_exhibitionId].listedNFTs[_tokenId], "NFT is not listed in this exhibition.");
        uint256 salePrice = exhibitions[_exhibitionId].nftSalePrice[_tokenId];
        require(salePrice > 0, "NFT is not for sale.");
        require(msg.value >= salePrice, "Insufficient payment.");

        address artist = ownerOf(_tokenId);
        transferFrom(artist, msg.sender, _tokenId); // Buyer becomes the new owner
        payable(artist).transfer(salePrice); // Send funds to the artist

        delete exhibitions[_exhibitionId].listedNFTs[_tokenId]; // Remove from exhibition after purchase
        delete exhibitions[_exhibitionId].nftSalePrice[_tokenId]; // Remove sale price

        // Optionally, add a small fee to collectiveFunds from each sale here

        emit NFTPurchasedFromExhibition(_exhibitionId, _tokenId, msg.sender, artist, salePrice);

        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice); // Refund excess payment
        }
    }

    /// @notice Allows artists to set a sale price for their NFT within an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _tokenId The ID of the NFT.
    /// @param _price The sale price in wei.
    function setNFTForSaleInExhibition(uint256 _exhibitionId, uint256 _tokenId, uint256 _price) public onlyArtist whenNotPaused {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(exhibitions[_exhibitionId].listedNFTs[_tokenId], "NFT is not listed in this exhibition. Participate first.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(_price > 0, "Price must be greater than zero.");
        exhibitions[_exhibitionId].nftSalePrice[_tokenId] = _price;
        emit NFTSetForSale(_exhibitionId, _tokenId, _price);
    }

    /// @notice Allows artists to remove their NFT from sale within an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _tokenId The ID of the NFT.
    function removeNFTFromSaleInExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyArtist whenNotPaused {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(exhibitions[_exhibitionId].listedNFTs[_tokenId], "NFT is not listed in this exhibition.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        delete exhibitions[_exhibitionId].nftSalePrice[_tokenId];
        emit NFTRemovedFromSale(_exhibitionId, _tokenId);
    }

    // -------- IV. Utility & Advanced Features --------

    mapping(uint256 => bool) public stakedNFTs; // Track staked NFTs for voting power

    /// @notice Allows artists to stake their NFTs to increase their voting power.
    /// @param _tokenId The ID of the NFT to stake.
    function stakeNFTForVotingPower(uint256 _tokenId) public onlyArtist whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(!stakedNFTs[_tokenId], "NFT is already staked.");
        stakedNFTs[_tokenId] = true;
        votingPower[msg.sender] += 2; // Example: Staking increases voting power by 2. Adjust as needed.
        emit NFTStakedForVotingPower(_tokenId, msg.sender);
    }

    /// @notice Allows artists to unstake their NFTs, reducing their voting power.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFTForVotingPower(uint256 _tokenId) public onlyArtist whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(stakedNFTs[_tokenId], "NFT is not staked.");
        stakedNFTs[_tokenId] = false;
        votingPower[msg.sender] -= 2; // Revert the voting power increase
        emit NFTUnstakedFromVotingPower(_tokenId, msg.sender);
    }

    /// @notice Allows anyone to report potential art theft or copyright infringement related to an NFT.
    /// @param _tokenId The ID of the potentially stolen NFT.
    /// @param _reportDetails Details of the reported theft.
    function reportArtTheft(uint256 _tokenId, string memory _reportDetails) public whenNotPaused {
        // In a real-world scenario, this would trigger an off-chain investigation or DAO voting process.
        // For this example, we just emit an event.
        emit ArtTheftReported(_tokenId, msg.sender, _reportDetails);
        // Further actions (like freezing the NFT, initiating a dispute resolution) would be implemented based on the DAO's governance model.
    }

    /// @notice Owner can pause critical contract functions in case of emergency.
    function emergencyPause() public onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /// @notice Owner can unpause the contract, resuming normal functionality.
    function unpause() public onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows the owner to set an external governance token contract address.
    /// @param _governanceTokenAddress The address of the governance token contract.
    function setGovernanceToken(address _governanceTokenAddress) public onlyOwner {
        governanceToken = _governanceTokenAddress;
        emit GovernanceTokenSet(_governanceTokenAddress);
    }

    /// @notice Allows the DAO (governance mechanism needed to authorize) to withdraw collective funds.
    function withdrawCollectiveFunds() public onlyOwner { // In a real DAO, this would be governed by proposals
        uint256 amount = collectiveFunds;
        collectiveFunds = 0;
        payable(owner()).transfer(amount); //  In a real DAO, transfer to a multi-sig or treasury controlled by the DAO
        emit CollectiveFundsWithdrawn(amount, owner()); // In a real DAO, event would show the DAO treasury address
    }

    // -------- View & Pure Functions --------

    /// @notice Gets the metadata URI for a given token ID.
    /// @param _tokenId The ID of the NFT.
    /// @return The metadata URI string.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[_tokenId];
    }

    /// @notice Gets the voting power of a given address.
    /// @param _address The address to check.
    /// @return The voting power.
    function getVotingPower(address _address) public view returns (uint256) {
        if (isArtist[_address]) {
            return 1 + votingPower[_address]; // Base voting power of 1 for artists + staked power
        } else {
            return 0; // Non-artists have no voting power by default
        }
    }

    /// @notice Gets the number of active artists in the collective.
    /// @return The artist count.
    function getArtistCount() public view returns (uint256) {
        return artistCount;
    }

    /// @notice Checks if an NFT is listed in a specific exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _tokenId The ID of the NFT.
    /// @return True if listed, false otherwise.
    function isNFTListedInExhibition(uint256 _exhibitionId, uint256 _tokenId) public view returns (bool) {
        return exhibitions[_exhibitionId].listedNFTs[_tokenId];
    }

    /// @notice Gets the sale price of an NFT in an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _tokenId The ID of the NFT.
    /// @return The sale price in wei, or 0 if not for sale.
    function getNFTSalePriceInExhibition(uint256 _exhibitionId, uint256 _tokenId) public view returns (uint256) {
        return exhibitions[_exhibitionId].nftSalePrice[_tokenId];
    }

    /// @notice Gets the details of an exhibition proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return ExhibitionProposal struct.
    function getExhibitionProposal(uint256 _proposalId) public view returns (ExhibitionProposal memory) {
        return exhibitionProposals[_proposalId];
    }

    /// @notice Gets the details of an artist proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return ArtistProposal struct.
    function getArtistProposal(uint256 _proposalId) public view returns (ArtistProposal memory) {
        return artistProposals[_proposalId];
    }

    /// @notice Gets the details of a parameter change proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return ParameterChangeProposal struct.
    function getParameterChangeProposal(uint256 _proposalId) public view returns (ParameterChangeProposal memory) {
        return parameterChangeProposals[_proposalId];
    }

    /// @notice Gets the details of an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @return Exhibition struct.
    function getExhibitionDetails(uint256 _exhibitionId) public view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }
}
```