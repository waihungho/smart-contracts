```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to submit artworks,
 *      community members to curate and vote on them, mint NFTs for approved artworks, manage a treasury,
 *      organize virtual exhibitions, and implement a dynamic royalty distribution system.
 *
 * **Outline and Function Summary:**
 *
 * **1. Artist Submission & Curation:**
 *    - `submitArtworkProposal(string _title, string _description, string _ipfsHash)`: Artists submit artwork proposals with metadata.
 *    - `voteOnArtworkProposal(uint256 _proposalId, bool _vote)`: Community members vote on artwork proposals.
 *    - `getArtworkProposalDetails(uint256 _proposalId)`: View details of an artwork proposal.
 *    - `getArtworkProposalVoteCount(uint256 _proposalId)`: Get the current vote count for a proposal.
 *    - `finalizeArtworkProposal(uint256 _proposalId)`: Finalize a proposal after voting period, minting NFT if approved.
 *
 * **2. NFT Minting & Management:**
 *    - `mintNFT(uint256 _proposalId)`: (Internal) Mints an NFT for an approved artwork proposal.
 *    - `transferNFT(address _to, uint256 _tokenId)`: (ERC721) Standard NFT transfer function.
 *    - `getArtworkNFTDetails(uint256 _tokenId)`: Get details associated with a minted artwork NFT.
 *    - `burnNFT(uint256 _tokenId)`: (Governance) Allows burning of NFTs under specific collective decisions.
 *
 * **3. Community & Governance:**
 *    - `registerAsMember()`: Allow users to register as community members.
 *    - `delegateVote(address _delegatee)`: Delegate voting power to another community member.
 *    - `proposeParameterChange(string _parameterName, uint256 _newValue)`: Propose changes to contract parameters (e.g., voting duration).
 *    - `voteOnParameterChange(uint256 _proposalId, bool _vote)`: Vote on parameter change proposals.
 *    - `getParameterChangeProposalDetails(uint256 _proposalId)`: View details of a parameter change proposal.
 *    - `finalizeParameterChangeProposal(uint256 _proposalId)`: Finalize a parameter change proposal after voting.
 *
 * **4. Treasury & Royalties:**
 *    - `depositToTreasury()`: Allow anyone to deposit funds into the collective treasury.
 *    - `withdrawFromTreasury(uint256 _amount)`: (Governance) Allow withdrawal from the treasury via collective decision.
 *    - `setRoyaltyPercentage(uint256 _percentage)`: (Governance) Set the royalty percentage for secondary sales.
 *    - `getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice)`: (ERC2981) Returns royalty information for NFT sales.
 *    - `distributeRoyalties(uint256 _tokenId)`: (Internal/Triggered on Sale) Distributes royalties to the artist and treasury.
 *
 * **5. Virtual Exhibitions:**
 *    - `createExhibitionProposal(string _exhibitionName, uint256[] _tokenIds, uint256 _startTime, uint256 _endTime)`: Propose a virtual art exhibition.
 *    - `voteOnExhibitionProposal(uint256 _proposalId, bool _vote)`: Vote on exhibition proposals.
 *    - `getExhibitionProposalDetails(uint256 _proposalId)`: View details of an exhibition proposal.
 *    - `finalizeExhibitionProposal(uint256 _proposalId)`: Finalize an exhibition proposal after voting, scheduling the exhibition.
 *    - `getActiveExhibitions()`: Get a list of currently active virtual exhibitions.
 *
 * **6. Utility & Admin:**
 *    - `pauseContract()`: (Admin) Pause core contract functionalities in case of emergency.
 *    - `unpauseContract()`: (Admin) Unpause contract functionalities.
 *    - `setVotingDuration(uint256 _durationInBlocks)`: (Admin) Set the voting duration for proposals.
 *    - `setQuorumPercentage(uint256 _percentage)`: (Admin) Set the quorum percentage required for proposal approval.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract DecentralizedAutonomousArtCollective is ERC721, Ownable, IERC2981 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _artworkProposalIds;
    Counters.Counter private _parameterProposalIds;
    Counters.Counter private _exhibitionProposalIds;
    Counters.Counter private _nftTokenIds;

    uint256 public votingDurationInBlocks = 100; // Default voting duration (blocks)
    uint256 public quorumPercentage = 50;        // Default quorum percentage for proposals
    uint256 public royaltyPercentage = 5;         // Default royalty percentage on secondary sales (5%)

    address public treasuryAddress;
    bool public paused = false;

    struct ArtworkProposal {
        uint256 proposalId;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 voteCountPositive;
        uint256 voteCountNegative;
        uint256 votingEndTime;
        bool finalized;
        bool approved;
        uint256 tokenId; // Token ID if proposal is approved and NFT minted
    }
    mapping(uint256 => ArtworkProposal) public artworkProposals;

    struct ParameterChangeProposal {
        uint256 proposalId;
        address proposer;
        string parameterName;
        uint256 newValue;
        uint256 voteCountPositive;
        uint256 voteCountNegative;
        uint256 votingEndTime;
        bool finalized;
        bool approved;
    }
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;

    struct ExhibitionProposal {
        uint256 proposalId;
        address proposer;
        string exhibitionName;
        uint256[] tokenIds;
        uint256 startTime;
        uint256 endTime;
        uint256 voteCountPositive;
        uint256 voteCountNegative;
        uint256 votingEndTime;
        bool finalized;
        bool approved;
        bool scheduled;
    }
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;

    struct Member {
        bool isRegistered;
        address delegate;
    }
    mapping(address => Member) public members;

    mapping(uint256 => address) public artworkTokenToArtist; // Track artist for each NFT

    // --- Events ---
    event ArtworkProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtworkProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtworkProposalFinalized(uint256 proposalId, bool approved, uint256 tokenId);
    event NFTMinted(uint256 tokenId, uint256 proposalId, address artist);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterChangeVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeFinalized(uint256 proposalId, bool approved, string parameterName, uint256 newValue);
    event ExhibitionProposalSubmitted(uint256 proposalId, string exhibitionName);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool vote);
    event ExhibitionProposalFinalized(uint256 proposalId, bool approved, uint256 exhibitionId);
    event ExhibitionScheduled(uint256 proposalId, string exhibitionName, uint256 startTime, uint256 endTime);
    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isRegistered, "You are not a registered community member");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can call this function");
        _;
    }

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol, address _treasuryAddress) ERC721(_name, _symbol) {
        treasuryAddress = _treasuryAddress;
    }

    // --- 1. Artist Submission & Curation ---

    /// @notice Artists submit artwork proposals.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork metadata.
    function submitArtworkProposal(string memory _title, string memory _description, string memory _ipfsHash) external whenNotPaused {
        _artworkProposalIds.increment();
        uint256 proposalId = _artworkProposalIds.current();
        artworkProposals[proposalId] = ArtworkProposal({
            proposalId: proposalId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            voteCountPositive: 0,
            voteCountNegative: 0,
            votingEndTime: block.number + votingDurationInBlocks,
            finalized: false,
            approved: false,
            tokenId: 0
        });
        emit ArtworkProposalSubmitted(proposalId, msg.sender, _title);
    }

    /// @notice Community members vote on artwork proposals.
    /// @param _proposalId ID of the artwork proposal.
    /// @param _vote True for positive vote, false for negative vote.
    function voteOnArtworkProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(!artworkProposals[_proposalId].finalized, "Proposal already finalized");
        require(block.number < artworkProposals[_proposalId].votingEndTime, "Voting period ended");

        address voter = members[msg.sender].delegate != address(0) ? members[msg.sender].delegate : msg.sender; // Use delegate if set

        // To prevent double voting, you would typically need to track voters per proposal.
        // For simplicity in this example, we skip double voting protection.
        // In a real-world scenario, implement a mapping to track votes per voter and proposal.

        if (_vote) {
            artworkProposals[_proposalId].voteCountPositive++;
        } else {
            artworkProposals[_proposalId].voteCountNegative++;
        }
        emit ArtworkProposalVoted(_proposalId, voter, _vote);
    }

    /// @notice Get details of an artwork proposal.
    /// @param _proposalId ID of the artwork proposal.
    /// @return ArtworkProposal struct.
    function getArtworkProposalDetails(uint256 _proposalId) external view returns (ArtworkProposal memory) {
        return artworkProposals[_proposalId];
    }

    /// @notice Get the current vote count for an artwork proposal.
    /// @param _proposalId ID of the artwork proposal.
    /// @return Positive vote count and negative vote count.
    function getArtworkProposalVoteCount(uint256 _proposalId) external view returns (uint256 positiveVotes, uint256 negativeVotes) {
        return (artworkProposals[_proposalId].voteCountPositive, artworkProposals[_proposalId].voteCountNegative);
    }

    /// @notice Finalize an artwork proposal after the voting period.
    /// @param _proposalId ID of the artwork proposal.
    function finalizeArtworkProposal(uint256 _proposalId) external whenNotPaused {
        require(!artworkProposals[_proposalId].finalized, "Proposal already finalized");
        require(block.number >= artworkProposals[_proposalId].votingEndTime, "Voting period not ended yet");

        uint256 totalVotes = artworkProposals[_proposalId].voteCountPositive + artworkProposals[_proposalId].voteCountNegative;
        uint256 quorum = (totalVotes * quorumPercentage) / 100; // Calculate quorum based on total votes
        bool approved = artworkProposals[_proposalId].voteCountPositive > artworkProposals[_proposalId].voteCountNegative && totalVotes >= quorum;

        artworkProposals[_proposalId].finalized = true;
        artworkProposals[_proposalId].approved = approved;

        if (approved) {
            _mintNFT(_proposalId); // Mint NFT if approved
        }

        emit ArtworkProposalFinalized(_proposalId, approved, artworkProposals[_proposalId].tokenId);
    }

    // --- 2. NFT Minting & Management ---

    /// @dev Internal function to mint an NFT for an approved artwork proposal.
    /// @param _proposalId ID of the approved artwork proposal.
    function _mintNFT(uint256 _proposalId) internal {
        require(artworkProposals[_proposalId].approved, "Proposal not approved for minting");
        require(artworkProposals[_proposalId].tokenId == 0, "NFT already minted for this proposal");

        _nftTokenIds.increment();
        uint256 tokenId = _nftTokenIds.current();
        _safeMint(artworkProposals[_proposalId].artist, tokenId);

        artworkProposals[_proposalId].tokenId = tokenId;
        artworkTokenToArtist[tokenId] = artworkProposals[_proposalId].artist;

        _setTokenURI(tokenId, artworkProposals[_proposalId].ipfsHash); // Set metadata URI
        emit NFTMinted(tokenId, _proposalId, artworkProposals[_proposalId].artist);
    }

    /// @inheritdoc ERC721
    function transferNFT(address _to, uint256 _tokenId) external whenNotPaused {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }

    /// @notice Get details associated with a minted artwork NFT.
    /// @param _tokenId ID of the NFT.
    /// @return Artwork proposal details related to the NFT.
    function getArtworkNFTDetails(uint256 _tokenId) external view returns (ArtworkProposal memory) {
        uint256 proposalId = 0;
        for (uint256 i = 1; i <= _artworkProposalIds.current(); i++) {
            if (artworkProposals[i].tokenId == _tokenId) {
                proposalId = i;
                break;
            }
        }
        require(proposalId != 0, "NFT not associated with any artwork proposal");
        return artworkProposals[proposalId];
    }

    /// @notice (Governance) Allows burning of NFTs under specific collective decisions.
    /// @param _tokenId ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) external onlyAdmin whenNotPaused { // Example: Only admin can burn for now, could be governance
        require(_exists(_tokenId), "NFT does not exist");
        _burn(_tokenId);
    }

    // --- 3. Community & Governance ---

    /// @notice Allow users to register as community members.
    function registerAsMember() external whenNotPaused {
        members[msg.sender].isRegistered = true;
    }

    /// @notice Delegate voting power to another community member.
    /// @param _delegatee Address of the member to delegate voting power to.
    function delegateVote(address _delegatee) external onlyMember whenNotPaused {
        require(members[_delegatee].isRegistered, "Delegatee is not a registered member");
        require(_delegatee != msg.sender, "Cannot delegate to yourself");
        members[msg.sender].delegate = _delegatee;
    }

    /// @notice Propose changes to contract parameters (e.g., voting duration).
    /// @param _parameterName Name of the parameter to change.
    /// @param _newValue New value for the parameter.
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external onlyMember whenNotPaused {
        _parameterProposalIds.increment();
        uint256 proposalId = _parameterProposalIds.current();
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            parameterName: _parameterName,
            newValue: _newValue,
            voteCountPositive: 0,
            voteCountNegative: 0,
            votingEndTime: block.number + votingDurationInBlocks,
            finalized: false,
            approved: false
        });
        emit ParameterChangeProposed(proposalId, _parameterName, _newValue);
    }

    /// @notice Vote on parameter change proposals.
    /// @param _proposalId ID of the parameter change proposal.
    /// @param _vote True for positive vote, false for negative vote.
    function voteOnParameterChange(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(!parameterChangeProposals[_proposalId].finalized, "Proposal already finalized");
        require(block.number < parameterChangeProposals[_proposalId].votingEndTime, "Voting period ended");

        address voter = members[msg.sender].delegate != address(0) ? members[msg.sender].delegate : msg.sender; // Use delegate if set

        if (_vote) {
            parameterChangeProposals[_proposalId].voteCountPositive++;
        } else {
            parameterChangeProposals[_proposalId].voteCountNegative++;
        }
        emit ParameterChangeVoted(_proposalId, voter, _vote);
    }

    /// @notice Get details of a parameter change proposal.
    /// @param _proposalId ID of the parameter change proposal.
    /// @return ParameterChangeProposal struct.
    function getParameterChangeProposalDetails(uint256 _proposalId) external view returns (ParameterChangeProposal memory) {
        return parameterChangeProposals[_proposalId];
    }

    /// @notice Finalize a parameter change proposal after voting.
    /// @param _proposalId ID of the parameter change proposal.
    function finalizeParameterChangeProposal(uint256 _proposalId) external whenNotPaused {
        require(!parameterChangeProposals[_proposalId].finalized, "Proposal already finalized");
        require(block.number >= parameterChangeProposals[_proposalId].votingEndTime, "Voting period not ended yet");

        uint256 totalVotes = parameterChangeProposals[_proposalId].voteCountPositive + parameterChangeProposals[_proposalId].voteCountNegative;
        uint256 quorum = (totalVotes * quorumPercentage) / 100;
        bool approved = parameterChangeProposals[_proposalId].voteCountPositive > parameterChangeProposals[_proposalId].voteCountNegative && totalVotes >= quorum;

        parameterChangeProposals[_proposalId].finalized = true;
        parameterChangeProposals[_proposalId].approved = approved;

        if (approved) {
            if (keccak256(abi.encodePacked(parameterChangeProposals[_proposalId].parameterName)) == keccak256(abi.encodePacked("votingDurationInBlocks"))) {
                votingDurationInBlocks = parameterChangeProposals[_proposalId].newValue;
            } else if (keccak256(abi.encodePacked(parameterChangeProposals[_proposalId].parameterName)) == keccak256(abi.encodePacked("quorumPercentage"))) {
                quorumPercentage = parameterChangeProposals[_proposalId].newValue;
            } else if (keccak256(abi.encodePacked(parameterChangeProposals[_proposalId].parameterName)) == keccak256(abi.encodePacked("royaltyPercentage"))) {
                royaltyPercentage = parameterChangeProposals[_proposalId].newValue;
            } // Add more parameters as needed, using if/else if or a mapping for parameter names to state variables

            emit ParameterChangeFinalized(_proposalId, approved, parameterChangeProposals[_proposalId].parameterName, parameterChangeProposals[_proposalId].newValue);
        }
    }

    // --- 4. Treasury & Royalties ---

    /// @notice Allow anyone to deposit funds into the collective treasury.
    function depositToTreasury() external payable whenNotPaused {
        payable(treasuryAddress).transfer(msg.value);
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice (Governance) Allow withdrawal from the treasury via collective decision.
    /// @param _amount Amount to withdraw.
    function withdrawFromTreasury(uint256 _amount) external onlyAdmin whenNotPaused { // Example: Admin controlled, could be governance based
        payable(owner()).transfer(_amount); // Example: Withdraw to contract owner for distribution, governance logic needed in real scenario
        emit TreasuryWithdrawal(owner(), _amount);
    }

    /// @notice (Governance) Set the royalty percentage for secondary sales.
    /// @param _percentage Royalty percentage (e.g., 5 for 5%).
    function setRoyaltyPercentage(uint256 _percentage) external onlyAdmin whenNotPaused { // Example: Admin controlled, could be governance
        royaltyPercentage = _percentage;
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = treasuryAddress; // Royalties go to the treasury
        royaltyAmount = (_salePrice * royaltyPercentage) / 100;
        return (receiver, royaltyAmount);
    }

    /// @dev Internal/Triggered on Sale - Distributes royalties to the artist and treasury.
    /// In a real marketplace integration, royalty distribution would be triggered by the marketplace contract during sale.
    /// This is a simplified example for demonstration.
    function distributeRoyalties(uint256 _tokenId, uint256 _salePrice) internal {
        (address royaltyReceiver, uint256 royaltyAmount) = royaltyInfo(_tokenId, _salePrice);
        payable(royaltyReceiver).transfer(royaltyAmount);

        address artist = artworkTokenToArtist[_tokenId];
        uint256 artistEarning = _salePrice - royaltyAmount;
        payable(artist).transfer(artistEarning);
        // In a real implementation, consider more complex royalty splits and artist earning structures.
    }


    // --- 5. Virtual Exhibitions ---

    /// @notice Propose a virtual art exhibition.
    /// @param _exhibitionName Name of the exhibition.
    /// @param _tokenIds Array of token IDs to include in the exhibition.
    /// @param _startTime Unix timestamp for exhibition start time.
    /// @param _endTime Unix timestamp for exhibition end time.
    function createExhibitionProposal(string memory _exhibitionName, uint256[] memory _tokenIds, uint256 _startTime, uint256 _endTime) external onlyMember whenNotPaused {
        _exhibitionProposalIds.increment();
        uint256 proposalId = _exhibitionProposalIds.current();
        exhibitionProposals[proposalId] = ExhibitionProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            exhibitionName: _exhibitionName,
            tokenIds: _tokenIds,
            startTime: _startTime,
            endTime: _endTime,
            voteCountPositive: 0,
            voteCountNegative: 0,
            votingEndTime: block.number + votingDurationInBlocks,
            finalized: false,
            approved: false,
            scheduled: false
        });
        emit ExhibitionProposalSubmitted(proposalId, _exhibitionName);
    }

    /// @notice Vote on exhibition proposals.
    /// @param _proposalId ID of the exhibition proposal.
    /// @param _vote True for positive vote, false for negative vote.
    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(!exhibitionProposals[_proposalId].finalized, "Proposal already finalized");
        require(block.number < exhibitionProposals[_proposalId].votingEndTime, "Voting period ended");

        address voter = members[msg.sender].delegate != address(0) ? members[msg.sender].delegate : msg.sender; // Use delegate if set

        if (_vote) {
            exhibitionProposals[_proposalId].voteCountPositive++;
        } else {
            exhibitionProposals[_proposalId].voteCountNegative++;
        }
        emit ExhibitionProposalVoted(_proposalId, voter, _vote);
    }

    /// @notice Get details of an exhibition proposal.
    /// @param _proposalId ID of the exhibition proposal.
    /// @return ExhibitionProposal struct.
    function getExhibitionProposalDetails(uint256 _proposalId) external view returns (ExhibitionProposal memory) {
        return exhibitionProposals[_proposalId];
    }

    /// @notice Finalize an exhibition proposal after voting, scheduling if approved.
    /// @param _proposalId ID of the exhibition proposal.
    function finalizeExhibitionProposal(uint256 _proposalId) external whenNotPaused {
        require(!exhibitionProposals[_proposalId].finalized, "Proposal already finalized");
        require(block.number >= exhibitionProposals[_proposalId].votingEndTime, "Voting period not ended yet");

        uint256 totalVotes = exhibitionProposals[_proposalId].voteCountPositive + exhibitionProposals[_proposalId].voteCountNegative;
        uint256 quorum = (totalVotes * quorumPercentage) / 100;
        bool approved = exhibitionProposals[_proposalId].voteCountPositive > exhibitionProposals[_proposalId].voteCountNegative && totalVotes >= quorum;

        exhibitionProposals[_proposalId].finalized = true;
        exhibitionProposals[_proposalId].approved = approved;

        if (approved) {
            exhibitionProposals[_proposalId].scheduled = true;
            emit ExhibitionScheduled(_proposalId, exhibitionProposals[_proposalId].exhibitionName, exhibitionProposals[_proposalId].startTime, exhibitionProposals[_proposalId].endTime);
        }

        emit ExhibitionProposalFinalized(_proposalId, approved, _exhibitionProposalIds.current()); // Using proposal ID as exhibition ID for simplicity
    }

    /// @notice Get a list of currently active virtual exhibitions.
    /// @return Array of exhibition proposal IDs that are currently active.
    function getActiveExhibitions() external view returns (uint256[] memory) {
        uint256[] memory activeExhibitionIds = new uint256[](_exhibitionProposalIds.current()); // Max size assumption
        uint256 count = 0;
        for (uint256 i = 1; i <= _exhibitionProposalIds.current(); i++) {
            if (exhibitionProposals[i].scheduled && block.timestamp >= exhibitionProposals[i].startTime && block.timestamp <= exhibitionProposals[i].endTime) {
                activeExhibitionIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of active exhibitions
        uint256[] memory resizedActiveExhibitionIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedActiveExhibitionIds[i] = activeExhibitionIds[i];
        }
        return resizedActiveExhibitionIds;
    }


    // --- 6. Utility & Admin ---

    /// @notice (Admin) Pause core contract functionalities in case of emergency.
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice (Admin) Unpause contract functionalities.
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice (Admin) Set the voting duration for proposals.
    /// @param _durationInBlocks Voting duration in blocks.
    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin {
        votingDurationInBlocks = _durationInBlocks;
    }

    /// @notice (Admin) Set the quorum percentage required for proposal approval.
    /// @param _percentage Quorum percentage (e.g., 50 for 50%).
    function setQuorumPercentage(uint256 _percentage) external onlyAdmin {
        quorumPercentage = _percentage;
    }

    // --- ERC721 Metadata URI ---
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory _uri) internal virtual {
        _tokenURIs[tokenId] = _uri;
    }

    mapping(uint256 => string) private _tokenURIs;

    // --- ERC2981 Support ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC2981) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
```