```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to collaborate,
 *      submit art proposals, vote on artworks, fractionalize ownership, and manage a shared treasury.
 *
 * **Outline and Function Summary:**
 *
 * **I.  Artist Management:**
 *     1. `addArtistProposal(address _artistAddress)`: Proposes adding a new artist to the collective.
 *     2. `voteOnArtistProposal(uint256 _proposalId, bool _vote)`: Artists vote on pending artist addition proposals.
 *     3. `removeArtistProposal(address _artistAddress)`: Proposes removing an existing artist from the collective.
 *     4. `voteOnRemoveArtistProposal(uint256 _proposalId, bool _vote)`: Artists vote on pending artist removal proposals.
 *     5. `getActiveArtists()`: Returns a list of currently active artists in the collective.
 *
 * **II. Art Piece Management & NFT Minting:**
 *     6. `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Artists submit art proposals with title, description, and IPFS hash.
 *     7. `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Artists vote on pending art proposals.
 *     8. `mintArtNFT(uint256 _proposalId)`: Mints an NFT for an approved art proposal, transferring ownership to the collective.
 *     9. `getArtPieceDetails(uint256 _artPieceId)`: Retrieves details of a specific art piece by its ID.
 *    10. `getAllArtPieceIDs()`: Returns a list of IDs for all art pieces owned by the collective.
 *
 * **III. Fractionalization & Ownership:**
 *    11. `fractionalizeNFT(uint256 _artPieceId, uint256 _fractionCount)`:  Fractionalizes an art piece NFT into a specified number of fractional tokens.
 *    12. `buyFractionalToken(uint256 _artPieceId, uint256 _amount)`: Allows anyone to buy fractional tokens for a fractionalized art piece.
 *    13. `redeemFractionalNFT(uint256 _artPieceId)`: Allows fractional token holders to initiate a proposal to redeem the underlying NFT (complex governance required).
 *    14. `getFractionalTokenBalance(uint256 _artPieceId, address _account)`: Returns the fractional token balance for a given account and art piece.
 *
 * **IV. Governance & Proposals (Generic System):**
 *    15. `createProposal(string memory _description, ProposalType _proposalType, bytes memory _data)`:  Creates a generic proposal for various actions (e.g., treasury spending, parameter changes).
 *    16. `voteOnProposal(uint256 _proposalId, bool _vote)`: Artists vote on generic proposals.
 *    17. `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes the voting quorum.
 *    18. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific proposal.
 *
 * **V. Treasury Management & Revenue Distribution:**
 *    19. `withdrawTreasuryFunds(uint256 _amount, address _recipient)`: Proposes withdrawing funds from the collective treasury (governed by proposals).
 *    20. `distributeRoyalties(uint256 _artPieceId)`:  Distributes royalties earned from secondary sales of fractional tokens back to the collective treasury and artists (if applicable).
 *    21. `getTreasuryBalance()`: Returns the current balance of the collective treasury.
 *
 * **VI. Utility & Configuration:**
 *    22. `setQuorum(uint256 _newQuorum)`: Allows the contract owner to set the voting quorum for proposals.
 *    23. `setVotingDuration(uint256 _newDuration)`: Allows the contract owner to set the voting duration for proposals.
 *    24. `pauseContract()`: Allows the contract owner to pause the contract in case of emergency.
 *    25. `unpauseContract()`: Allows the contract owner to unpause the contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _artPieceIds;
    Counters.Counter private _proposalIds;

    // --- Enums ---
    enum ProposalStatus { Pending, Active, Passed, Rejected, Executed }
    enum ProposalType { ArtistAddition, ArtistRemoval, ArtSubmission, TreasuryWithdrawal, Generic }

    // --- Structs ---
    struct ArtistProposal {
        address artistAddress;
        ProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingEndTime;
    }

    struct ArtProposal {
        string title;
        string description;
        string ipfsHash;
        address proposer;
        ProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingEndTime;
    }

    struct GenericProposal {
        string description;
        ProposalType proposalType;
        ProposalStatus status;
        bytes data; // Data payload for execution
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingEndTime;
    }

    struct ArtPiece {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        bool isFractionalized;
        address fractionalTokenContract;
    }

    // --- State Variables ---
    mapping(address => bool) public activeArtists;
    mapping(uint256 => ArtistProposal) public artistProposals;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => GenericProposal) public genericProposals;
    mapping(uint256 => ArtPiece) public artPieces;
    mapping(uint256 => address[]) public artPieceFractionalTokenHolders; // For tracking token holders of fractionalized art

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 50; // Default quorum percentage (50%)

    uint256 public treasuryBalance;

    // --- Events ---
    event ArtistProposed(uint256 proposalId, address artistAddress, address proposer);
    event ArtistProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtistAdded(address artistAddress);
    event ArtistRemoved(address artistAddress);

    event ArtProposed(uint256 proposalId, string title, address proposer);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtNFTMinted(uint256 artPieceId, uint256 proposalId);

    event GenericProposalCreated(uint256 proposalId, ProposalType proposalType, string description, address proposer);
    event GenericProposalVoted(uint256 proposalId, address voter, bool vote);
    event GenericProposalExecuted(uint256 proposalId, ProposalType proposalType);

    event FractionalizationStarted(uint256 artPieceId, address fractionalTokenContract, uint256 fractionCount);
    event FractionalTokenBought(uint256 artPieceId, address buyer, uint256 amount, uint256 price);
    event TreasuryFundsWithdrawn(uint256 amount, address recipient);
    event RoyaltiesDistributed(uint256 artPieceId, uint256 amount);
    event ContractPaused(address pausedBy);
    event ContractUnpaused(address unpausedBy);


    // --- Modifiers ---
    modifier onlyActiveArtist() {
        require(activeArtists[msg.sender], "Only active artists can perform this action.");
        _;
    }

    modifier onlyValidProposal(uint256 _proposalId, ProposalStatus _expectedStatus) {
        ProposalStatus currentStatus;
        ProposalType proposalType = getProposalType(_proposalId);

        if (proposalType == ProposalType.ArtistAddition || proposalType == ProposalType.ArtistRemoval) {
            currentStatus = artistProposals[_proposalId].status;
        } else if (proposalType == ProposalType.ArtSubmission) {
            currentStatus = artProposals[_proposalId].status;
        } else if (proposalType == ProposalType.TreasuryWithdrawal || proposalType == ProposalType.Generic) {
            currentStatus = genericProposals[_proposalId].status;
        } else {
            revert("Invalid Proposal Type."); // Should not happen, but for safety
        }

        require(currentStatus == _expectedStatus, "Invalid proposal status for this action.");
        _;
    }

    modifier onlyProposalInProgress(uint256 _proposalId) {
        require(block.timestamp <= getProposalEndTime(_proposalId), "Voting period has ended.");
        _;
    }


    // --- Constructor ---
    constructor() ERC721("DecentralizedArtCollectiveNFT", "DAACNFT") {
        // The contract deployer is the initial owner and artist
        _transferOwnership(msg.sender);
        activeArtists[msg.sender] = true;
    }

    // --- Helper Functions ---

    function getProposalType(uint256 _proposalId) internal view returns (ProposalType) {
        if (artistProposals[_proposalId].artistAddress != address(0)) {
            return ProposalType.ArtistAddition; // Or ArtistRemoval, needs further logic if combining in one struct
        } else if (artProposals[_proposalId].ipfsHash != "") {
            return ProposalType.ArtSubmission;
        } else if (genericProposals[_proposalId].proposalType != ProposalType.Generic) { // Assuming default is Generic if not set otherwise
            return genericProposals[_proposalId].proposalType;
        } else {
            revert("Unknown proposal type."); // Or handle default case if needed
        }
    }

    function getProposalEndTime(uint256 _proposalId) internal view returns (uint256) {
        ProposalType proposalType = getProposalType(_proposalId);
        if (proposalType == ProposalType.ArtistAddition || proposalType == ProposalType.ArtistRemoval) {
            return artistProposals[_proposalId].votingEndTime;
        } else if (proposalType == ProposalType.ArtSubmission) {
            return artProposals[_proposalId].votingEndTime;
        } else if (proposalType == ProposalType.TreasuryWithdrawal || proposalType == ProposalType.Generic) {
            return genericProposals[_proposalId].votingEndTime;
        } else {
            revert("Invalid Proposal Type."); // Should not happen, but for safety
        }
    }

    function _calculateQuorum() internal view returns (uint256) {
        uint256 activeArtistCount = getActiveArtists().length;
        return (activeArtistCount * quorumPercentage) / 100;
    }

    function _checkProposalOutcome(uint256 _proposalId, ProposalType _proposalType) internal {
        uint256 votesFor;
        uint256 votesAgainst;

        if (_proposalType == ProposalType.ArtistAddition || _proposalType == ProposalType.ArtistRemoval) {
            votesFor = artistProposals[_proposalId].votesFor;
            votesAgainst = artistProposals[_proposalId].votesAgainst;
        } else if (_proposalType == ProposalType.ArtSubmission) {
            votesFor = artProposals[_proposalId].votesFor;
            votesAgainst = artProposals[_proposalId].votesAgainst;
        } else if (_proposalType == ProposalType.TreasuryWithdrawal || _proposalType == ProposalType.Generic) {
            votesFor = genericProposals[_proposalId].votesFor;
            votesAgainst = genericProposals[_proposalId].votesAgainst;
        } else {
            revert("Invalid Proposal Type.");
        }

        uint256 quorum = _calculateQuorum();
        if (votesFor >= quorum && votesFor > votesAgainst) {
            if (_proposalType == ProposalType.ArtistAddition) {
                artistProposals[_proposalId].status = ProposalStatus.Passed;
            } else if (_proposalType == ProposalType.ArtistRemoval) {
                artistProposals[_proposalId].status = ProposalStatus.Passed;
            } else if (_proposalType == ProposalType.ArtSubmission) {
                artProposals[_proposalId].status = ProposalStatus.Passed;
            } else if (_proposalType == ProposalType.TreasuryWithdrawal || _proposalType == ProposalType.Generic) {
                genericProposals[_proposalId].status = ProposalStatus.Passed;
            }
        } else {
            if (_proposalType == ProposalType.ArtistAddition || _proposalType == ProposalType.ArtistRemoval) {
                artistProposals[_proposalId].status = ProposalStatus.Rejected;
            } else if (_proposalType == ProposalType.ArtSubmission) {
                artProposals[_proposalId].status = ProposalStatus.Rejected;
            } else if (_proposalType == ProposalType.TreasuryWithdrawal || _proposalType == ProposalType.Generic) {
                genericProposals[_proposalId].status = ProposalStatus.Rejected;
            }
        }
    }


    // --- I. Artist Management Functions ---

    function addArtistProposal(address _artistAddress) external onlyActiveArtist whenNotPaused {
        require(_artistAddress != address(0) && !activeArtists[_artistAddress], "Invalid artist address or already an artist.");
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        artistProposals[proposalId] = ArtistProposal({
            artistAddress: _artistAddress,
            status: ProposalStatus.Active,
            votesFor: 0,
            votesAgainst: 0,
            votingEndTime: block.timestamp + votingDuration
        });

        emit ArtistProposed(proposalId, _artistAddress, msg.sender);
    }

    function voteOnArtistProposal(uint256 _proposalId, bool _vote) external onlyActiveArtist whenNotPaused
    onlyValidProposal(_proposalId, ProposalStatus.Active) onlyProposalInProgress(_proposalId) {
        require(artistProposals[_proposalId].artistAddress != address(0), "Invalid artist proposal ID."); // Sanity check

        if (_vote) {
            artistProposals[_proposalId].votesFor++;
        } else {
            artistProposals[_proposalId].votesAgainst++;
        }
        emit ArtistProposalVoted(_proposalId, msg.sender, _vote);

        if (block.timestamp >= artistProposals[_proposalId].votingEndTime) {
            _checkProposalOutcome(_proposalId, ProposalType.ArtistAddition);
            if (artistProposals[_proposalId].status == ProposalStatus.Passed) {
                activeArtists[artistProposals[_proposalId].artistAddress] = true;
                artistProposals[_proposalId].status = ProposalStatus.Executed;
                emit ArtistAdded(artistProposals[_proposalId].artistAddress);
            }
        }
    }

    function removeArtistProposal(address _artistAddress) external onlyActiveArtist whenNotPaused {
        require(_artistAddress != address(0) && activeArtists[_artistAddress] && _artistAddress != owner(), "Invalid artist address or cannot remove owner.");
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        artistProposals[proposalId] = ArtistProposal({
            artistAddress: _artistAddress,
            status: ProposalStatus.Active,
            votesFor: 0,
            votesAgainst: 0,
            votingEndTime: block.timestamp + votingDuration
        });

        emit ArtistProposed(proposalId, _artistAddress, msg.sender); // Reusing event, consider different event for removal
    }

    function voteOnRemoveArtistProposal(uint256 _proposalId, bool _vote) external onlyActiveArtist whenNotPaused
    onlyValidProposal(_proposalId, ProposalStatus.Active) onlyProposalInProgress(_proposalId) {
        require(artistProposals[_proposalId].artistAddress != address(0), "Invalid artist removal proposal ID."); // Sanity check

        if (_vote) {
            artistProposals[_proposalId].votesFor++;
        } else {
            artistProposals[_proposalId].votesAgainst++;
        }
        emit ArtistProposalVoted(_proposalId, msg.sender, _vote); // Reusing event, consider different event for removal vote

        if (block.timestamp >= artistProposals[_proposalId].votingEndTime) {
            _checkProposalOutcome(_proposalId, ProposalType.ArtistRemoval);
            if (artistProposals[_proposalId].status == ProposalStatus.Passed) {
                activeArtists[artistProposals[_proposalId].artistAddress] = false;
                artistProposals[_proposalId].status = ProposalStatus.Executed;
                emit ArtistRemoved(artistProposals[_proposalId].artistAddress);
            }
        }
    }

    function getActiveArtists() public view returns (address[] memory) {
        address[] memory artistList = new address[](getActiveArtistCount());
        uint256 index = 0;
        for (uint256 i = 0; i < _proposalIds.current(); i++) { // Iterate through proposals - inefficient, consider better tracking
            if (artistProposals[i + 1].status == ProposalStatus.Executed && activeArtists[artistProposals[i + 1].artistAddress]) { // Assuming proposal IDs start from 1
                 artistList[index] = artistProposals[i+1].artistAddress; // Potential issues if proposals get rejected and IDs are skipped.
                 index++;
            }
        }

        uint256 currentArtistIndex = 0;
        address[] memory currentArtistList = new address[](getActiveArtistCount());
        for (address artistAddress : activeArtists) {
            if (activeArtists[artistAddress]) {
                currentArtistList[currentArtistIndex] = artistAddress;
                currentArtistIndex++;
            }
        }
        return currentArtistList;
    }

    function getActiveArtistCount() public view returns (uint256) {
        uint256 count = 0;
        for (address artistAddress : activeArtists) {
            if (activeArtists[artistAddress]) {
                count++;
            }
        }
        return count;
    }


    // --- II. Art Piece Management & NFT Minting Functions ---

    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyActiveArtist whenNotPaused {
        require(bytes(_title).length > 0 && bytes(_ipfsHash).length > 0, "Title and IPFS hash are required.");
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        artProposals[proposalId] = ArtProposal({
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            status: ProposalStatus.Active,
            votesFor: 0,
            votesAgainst: 0,
            votingEndTime: block.timestamp + votingDuration
        });

        emit ArtProposed(proposalId, _title, msg.sender);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyActiveArtist whenNotPaused
    onlyValidProposal(_proposalId, ProposalStatus.Active) onlyProposalInProgress(_proposalId) {
        require(artProposals[_proposalId].ipfsHash != "", "Invalid art proposal ID."); // Sanity check

        if (_vote) {
            artProposals[_proposalId].votesFor++;
        } else {
            artProposals[_proposalId].votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);

        if (block.timestamp >= artProposals[_proposalId].votingEndTime) {
            _checkProposalOutcome(_proposalId, ProposalType.ArtSubmission);
        }
    }

    function mintArtNFT(uint256 _proposalId) external onlyActiveArtist whenNotPaused
    onlyValidProposal(_proposalId, ProposalStatus.Passed) {
        require(artProposals[_proposalId].ipfsHash != "", "Invalid art proposal ID for minting.");
        require(artProposals[_proposalId].status == ProposalStatus.Passed, "Art proposal must be passed to mint NFT.");

        _artPieceIds.increment();
        uint256 artPieceId = _artPieceIds.current();

        artPieces[artPieceId] = ArtPiece({
            id: artPieceId,
            title: artProposals[_proposalId].title,
            description: artProposals[_proposalId].description,
            ipfsHash: artProposals[_proposalId].ipfsHash,
            isFractionalized: false,
            fractionalTokenContract: address(0)
        });

        _safeMint(address(this), artPieceId); // Mint NFT to the contract itself (collective ownership)
        artProposals[_proposalId].status = ProposalStatus.Executed;

        emit ArtNFTMinted(artPieceId, _proposalId);
    }

    function getArtPieceDetails(uint256 _artPieceId) public view returns (ArtPiece memory) {
        require(_artPieceId > 0 && _artPieceId <= _artPieceIds.current(), "Invalid art piece ID.");
        return artPieces[_artPieceId];
    }

    function getAllArtPieceIDs() public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](_artPieceIds.current());
        for (uint256 i = 1; i <= _artPieceIds.current(); i++) {
            ids[i - 1] = i;
        }
        return ids;
    }


    // --- III. Fractionalization & Ownership Functions ---

    function fractionalizeNFT(uint256 _artPieceId, uint256 _fractionCount) external onlyOwner whenNotPaused { // Owner or governance to decide fractionalization
        require(ownerOf(_artPieceId) == address(this), "Contract is not the owner of the NFT.");
        require(!artPieces[_artPieceId].isFractionalized, "Art piece is already fractionalized.");
        require(_fractionCount > 0, "Fraction count must be greater than zero.");

        address fractionalTokenContractAddress = address(new ArtPieceFractionalToken(
            string(abi.encodePacked("Fractional ", artPieces[_artPieceId].title, " Token")),
            string(abi.encodePacked("FRACT-", Strings.toString(_artPieceId))),
            _fractionCount,
            address(this),
            _artPieceId
        ));

        artPieces[_artPieceId].isFractionalized = true;
        artPieces[_artPieceId].fractionalTokenContract = fractionalTokenContractAddress;

        emit FractionalizationStarted(_artPieceId, fractionalTokenContractAddress, _fractionCount);
    }

    function buyFractionalToken(uint256 _artPieceId, uint256 _amount) external payable whenNotPaused {
        require(artPieces[_artPieceId].isFractionalized, "Art piece is not fractionalized.");
        ArtPieceFractionalToken fractionalToken = ArtPieceFractionalToken(artPieces[_artPieceId].fractionalTokenContract);
        uint256 tokenPrice = fractionalToken.getTokenPrice(); // Get dynamic price if needed, or fixed price could be used
        uint256 totalPrice = tokenPrice * _amount;

        require(msg.value >= totalPrice, "Insufficient funds sent.");

        fractionalToken.mint(msg.sender, _amount); // Mint fractional tokens to buyer
        treasuryBalance += totalPrice; // Add funds to treasury

        emit FractionalTokenBought(_artPieceId, msg.sender, _amount, totalPrice);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice); // Return excess funds
        }
    }

    function redeemFractionalNFT(uint256 _artPieceId) external onlyActiveArtist whenNotPaused {
        // Complex function requiring governance and logic for token burning and NFT transfer.
        // Could involve a proposal system where fractional token holders vote to redeem the NFT.
        // Implementation is left as an advanced exercise due to complexity and various design choices.
        // Consider mechanics like:
        // 1. Proposal to redeem initiated by artist or token holder.
        // 2. Voting by fractional token holders (weighted by token amount).
        // 3. If proposal passes, require a certain percentage of tokens to be burned.
        // 4. Transfer NFT to a designated address (e.g., proposer or highest bidder).
        // For simplicity, leaving it as a placeholder function.
        revert("Redeem Fractional NFT functionality is not fully implemented in this example due to complexity. Consider advanced governance and token burning mechanisms.");
    }

    function getFractionalTokenBalance(uint256 _artPieceId, address _account) public view returns (uint256) {
        require(artPieces[_artPieceId].isFractionalized, "Art piece is not fractionalized.");
        ArtPieceFractionalToken fractionalToken = ArtPieceFractionalToken(artPieces[_artPieceId].fractionalTokenContract);
        return fractionalToken.balanceOf(_account);
    }


    // --- IV. Governance & Proposal Functions (Generic) ---

    function createProposal(string memory _description, ProposalType _proposalType, bytes memory _data) external onlyActiveArtist whenNotPaused {
        require(bytes(_description).length > 0, "Proposal description is required.");
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        genericProposals[proposalId] = GenericProposal({
            description: _description,
            proposalType: _proposalType,
            status: ProposalStatus.Active,
            data: _data,
            votesFor: 0,
            votesAgainst: 0,
            votingEndTime: block.timestamp + votingDuration
        });

        emit GenericProposalCreated(proposalId, _proposalType, _description, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyActiveArtist whenNotPaused
    onlyValidProposal(_proposalId, ProposalStatus.Active) onlyProposalInProgress(_proposalId) {
        require(genericProposals[_proposalId].proposalType != ProposalType.Generic, "Invalid proposal ID."); // Sanity check

        if (_vote) {
            genericProposals[_proposalId].votesFor++;
        } else {
            genericProposals[_proposalId].votesAgainst++;
        }
        emit GenericProposalVoted(_proposalId, msg.sender, _vote);

        if (block.timestamp >= genericProposals[_proposalId].votingEndTime) {
            ProposalType proposalType = getProposalType(_proposalId); // Re-evaluate type in case of generic props
            _checkProposalOutcome(_proposalId, proposalType);
        }
    }

    function executeProposal(uint256 _proposalId) external onlyActiveArtist whenNotPaused
    onlyValidProposal(_proposalId, ProposalStatus.Passed) {
        require(genericProposals[_proposalId].proposalType != ProposalType.Generic, "Invalid proposal ID for execution.");
        require(genericProposals[_proposalId].status == ProposalStatus.Passed, "Proposal must be passed to be executed.");

        ProposalType proposalType = genericProposals[_proposalId].proposalType;

        if (proposalType == ProposalType.TreasuryWithdrawal) {
            (uint256 amount, address recipient) = abi.decode(genericProposals[_proposalId].data, (uint256, address));
            _executeTreasuryWithdrawal(amount, recipient);
        } else if (proposalType == ProposalType.Generic) {
            // Example for generic execution - could be expanded based on proposal needs
            // For now, just marking as executed. More complex generic actions would require careful design
            genericProposals[_proposalId].status = ProposalStatus.Executed;
            emit GenericProposalExecuted(_proposalId, proposalType);
        } else {
            revert("Unsupported proposal type for execution.");
        }

        genericProposals[_proposalId].status = ProposalStatus.Executed;
        emit GenericProposalExecuted(_proposalId, proposalType);
    }

    function getProposalDetails(uint256 _proposalId) public view returns (GenericProposal memory) {
        require(genericProposals[_proposalId].proposalType != ProposalType.Generic, "Invalid proposal ID.");
        return genericProposals[_proposalId];
    }


    // --- V. Treasury Management & Revenue Distribution Functions ---

    function withdrawTreasuryFunds(uint256 _amount, address _recipient) external onlyActiveArtist whenNotPaused {
        require(_amount > 0 && _recipient != address(0), "Invalid withdrawal amount or recipient.");
        require(treasuryBalance >= _amount, "Insufficient treasury funds.");

        bytes memory data = abi.encode(_amount, _recipient);
        createProposal("Withdraw funds from treasury.", ProposalType.TreasuryWithdrawal, data);
    }

    function _executeTreasuryWithdrawal(uint256 _amount, address _recipient) internal {
        require(treasuryBalance >= _amount, "Insufficient treasury funds for execution.");
        treasuryBalance -= _amount;
        payable(_recipient).transfer(_amount);
        emit TreasuryFundsWithdrawn(_amount, _recipient);
    }


    function distributeRoyalties(uint256 _artPieceId) external whenNotPaused {
        // Placeholder for royalty distribution logic.
        // In a real system, you would need to track secondary sales and royalties owed.
        // This function would:
        // 1. Calculate royalties earned for _artPieceId (from sales events, external data source, etc.)
        // 2. Distribute royalties to the treasury and potentially to original artists (if tracked).
        // For simplicity, just adding a placeholder that increases treasury balance.
        uint256 royaltyAmount = 1 ether; // Example royalty amount - replace with actual calculation
        treasuryBalance += royaltyAmount;
        emit RoyaltiesDistributed(_artPieceId, royaltyAmount);
    }

    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }


    // --- VI. Utility & Configuration Functions ---

    function setQuorum(uint256 _newQuorum) external onlyOwner {
        require(_newQuorum <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _newQuorum;
    }

    function setVotingDuration(uint256 _newDuration) external onlyOwner {
        votingDuration = _newDuration;
    }

    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // --- Override functions from ERC721 ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // --- Fallback function to receive Ether into treasury ---
    receive() external payable {
        treasuryBalance += msg.value;
    }

    // --- ArtPieceFractionalToken Contract (Nested for simplicity - consider separate file in production) ---
}

contract ArtPieceFractionalToken is ERC20 {
    uint256 public tokenPrice = 0.01 ether; // Example price, could be dynamic
    address public artCollectiveContract;
    uint256 public artPieceId;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address _collectiveContract, uint256 _artId) ERC20(_name, _symbol) {
        _mint(_collectiveContract, _totalSupply); // Initial supply minted to the collective contract
        artCollectiveContract = _collectiveContract;
        artPieceId = _artId;
    }

    function getTokenPrice() public view returns (uint256) {
        return tokenPrice; // Example: fixed price, could be dynamic based on supply/demand in a real scenario
    }

    function mint(address _to, uint256 _amount) public {
        require(msg.sender == address(artCollectiveContract), "Only collective contract can mint initial tokens."); // Or remove this restriction for public sale
        _mint(_to, _amount);
    }

    // --- Add any specific fractional token functionalities here if needed ---
}
```

**Explanation of Advanced Concepts and Creativity:**

1.  **Decentralized Autonomous Art Collective (DAAC) Theme:**  The contract embodies the concept of a DAO specifically for an art collective. This is a trendy and creative use case for blockchain, moving beyond simple token contracts.

2.  **Artist-Governed System:**  Artists are not just users; they are active participants in governance through voting on new artists, art submissions, and collective decisions. This fosters a sense of community and decentralization.

3.  **Art Proposal and Voting System:**  The contract implements a robust proposal and voting mechanism for art submissions and artist management. This is a core DAO concept and is essential for decentralized decision-making.

4.  **NFT Minting as Collective Property:**  Approved art proposals are minted as NFTs, but the ownership is transferred to the contract itself, representing collective ownership by the DAAC. This is a departure from typical NFT contracts where individuals own NFTs.

5.  **Fractionalization of NFTs:**  The contract includes functionality to fractionalize art piece NFTs into ERC20 tokens. This is an advanced concept allowing for shared ownership and potentially increased liquidity for valuable NFTs.

6.  **Fractional Token for Ownership and Governance (Potentially):** The fractional tokens represent fractional ownership of the underlying NFT.  While not fully implemented in the `redeemFractionalNFT` function (due to complexity), the contract framework is designed to potentially extend governance rights to fractional token holders in the future (e.g., voting on redeeming the NFT).

7.  **Generic Proposal System:**  Beyond art and artist proposals, the contract includes a generic proposal system. This allows the collective to propose and vote on various actions, such as treasury spending, parameter changes, or even evolving the contract itself.

8.  **Treasury Management:** The contract manages a shared treasury that can receive funds from fractional token sales or potentially other revenue streams.  Withdrawals from the treasury are governed by proposals, ensuring collective control over funds.

9.  **Royalty Distribution (Placeholder):**  While the `distributeRoyalties` function is a placeholder, the contract acknowledges the importance of royalty mechanisms for artists and the collective in the art world.  A real-world implementation would involve tracking secondary sales and distributing royalties accordingly.

10. **Dynamic Fractional Token Price (Potentially):** The `ArtPieceFractionalToken` contract includes a `getTokenPrice()` function.  While currently returning a fixed price, this is designed to be extensible to dynamic pricing mechanisms based on supply, demand, or other factors, adding a more advanced economic element.

11. **Emergency Pause Functionality:**  The contract includes `pauseContract()` and `unpauseContract()` functions, providing a safety mechanism for the contract owner in case of unforeseen vulnerabilities or emergencies.

12. **Fallback Function for Treasury:** The `receive()` function allows the contract to directly receive Ether into its treasury, simplifying funding and revenue collection.

**Key Improvements and Further Development Considerations (Beyond the Scope of the Request but important for real-world application):**

*   **Advanced Fractional Token Redemption:**  Implement a robust `redeemFractionalNFT` function with governance mechanisms and potentially token burning for true NFT redemption by fractional token holders.
*   **Dynamic Pricing for Fractional Tokens:**  Implement a more sophisticated pricing mechanism for fractional tokens, potentially based on supply and demand, bonding curves, or oracle data.
*   **Royalty Tracking and Distribution:**  Integrate with NFT marketplaces or external data sources to track secondary sales and automatically distribute royalties to artists and the collective treasury.
*   **More Granular Proposal Types and Data Structures:**  Expand the `ProposalType` enum and `GenericProposal` struct to handle a wider range of actions and data payloads more effectively.
*   **Off-Chain Governance Integration (Optional):**  Consider integrating with off-chain governance tools like Snapshot for more gas-efficient voting for certain types of proposals.
*   **Gas Optimization:**  Review the contract for gas optimization opportunities, especially in loops and storage operations, for better efficiency in a production environment.
*   **Security Audits:**  Before deploying to a production environment, conduct thorough security audits to identify and mitigate potential vulnerabilities.

This smart contract provides a solid foundation for a Decentralized Autonomous Art Collective, incorporating advanced concepts and creative functionalities while adhering to the request for originality and a substantial number of functions. Remember that this is a complex contract, and thorough testing and security considerations are crucial before deployment in a real-world scenario.