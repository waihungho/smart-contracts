```solidity
/**
 * @title Decentralized Autonomous Art Gallery - "ArtVerse DAO"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery where artists can submit their artwork (represented as NFTs),
 * curators can vote on submissions, and approved art pieces can be exhibited in virtual exhibitions.
 *
 * **Outline:**
 * 1. **Art Submission and Management:** Artists can submit their artwork (NFTs). The contract manages art piece metadata, approval status, and exhibition status.
 * 2. **Decentralized Curation (Voting):** A system for registered curators to vote on submitted art pieces.
 * 3. **Exhibition Management:** Create and manage virtual art exhibitions, showcasing approved artworks for a limited time.
 * 4. **Artist and Curator Profiles:** Basic profiles for artists and curators to establish reputation and identity within the gallery.
 * 5. **Revenue Sharing (Optional, but included for advanced concept):**  Potentially for future features like ticketed exhibitions or NFT sales within the gallery.
 * 6. **DAO Governance (Simple):**  Basic proposals and voting for gallery parameters (e.g., curator additions, exhibition durations).
 * 7. **Emergency Stop/Pause Functionality:**  For contract owner to pause operations in case of critical issues.
 * 8. **Data Retrieval and View Functions:**  Functions to query art pieces, exhibitions, curators, and voting results.
 * 9. **Event Emission:**  Emit events for significant actions to enable off-chain monitoring and integration.
 * 10. **NFT Interaction (Assumes ERC721 or similar):**  Interact with external NFT contracts to verify and manage submitted artwork.
 *
 * **Function Summary:**
 * | Function Name                 | Visibility   | Parameters                                   | Return Values                               | Description                                                                       |
 * |------------------------------|--------------|-----------------------------------------------|--------------------------------------------|-----------------------------------------------------------------------------------|
 * | `submitArt`                    | `public`     | `address _nftContract`, `uint256 _tokenId`, `string memory _metadataURI` | `uint256 _artPieceId`                        | Allows artists to submit their NFT artwork to the gallery for curation.       |
 * | `getArtPieceDetails`           | `public view` | `uint256 _artPieceId`                       | `ArtPiece`                                 | Retrieves detailed information about a specific art piece.                     |
 * | `approveArtPiece`             | `onlyCurator`| `uint256 _artPieceId`                       | `bool`                                     | Curator approves a submitted art piece for exhibition consideration.              |
 * | `rejectArtPiece`              | `onlyCurator`| `uint256 _artPieceId`                       | `bool`                                     | Curator rejects a submitted art piece.                                          |
 * | `startArtVoting`              | `onlyCurator`| `uint256 _artPieceId`, `uint256 _votingDuration` | `bool`                                     | Starts a voting period for curators to decide on an art piece's approval.       |
 * | `castVote`                    | `onlyCurator`| `uint256 _artPieceId`, `bool _vote`         | `bool`                                     | Allows curators to cast their vote (approve/reject) for an art piece.           |
 * | `endArtVoting`                | `onlyCurator`| `uint256 _artPieceId`                       | `bool`                                     | Ends the voting period for an art piece and determines approval based on votes. |
 * | `createExhibition`            | `onlyCurator`| `string memory _exhibitionName`, `uint256 _startTime`, `uint256 _endTime` | `uint256 _exhibitionId`                     | Creates a new virtual art exhibition.                                       |
 * | `addArtToExhibition`          | `onlyCurator`| `uint256 _exhibitionId`, `uint256 _artPieceId` | `bool`                                     | Adds an approved art piece to a specific exhibition.                          |
 * | `removeArtFromExhibition`       | `onlyCurator`| `uint256 _exhibitionId`, `uint256 _artPieceId` | `bool`                                     | Removes an art piece from an exhibition.                                       |
 * | `startExhibition`             | `onlyCurator`| `uint256 _exhibitionId`                       | `bool`                                     | Starts a scheduled exhibition, making it visible in the gallery.              |
 * | `endExhibition`               | `onlyCurator`| `uint256 _exhibitionId`                       | `bool`                                     | Ends an active exhibition.                                                   |
 * | `getExhibitionDetails`        | `public view` | `uint256 _exhibitionId`                       | `Exhibition`                               | Retrieves details of a specific exhibition.                                   |
 * | `registerCurator`             | `onlyOwner`  | `address _curatorAddress`                      | `bool`                                     | Allows the contract owner to register new curators.                            |
 * | `removeCurator`               | `onlyOwner`  | `address _curatorAddress`                      | `bool`                                     | Allows the contract owner to remove curators.                                  |
 * | `isCurator`                   | `public view` | `address _address`                             | `bool`                                     | Checks if an address is registered as a curator.                               |
 * | `proposeCuratorChange`        | `onlyOwner`  | `address _targetCurator`, `bool _add`         | `uint256 _proposalId`                       | Proposes adding or removing a curator, requiring DAO-like voting (simple owner-only for this example). |
 * | `voteOnProposal`              | `onlyOwner`  | `uint256 _proposalId`, `bool _vote`          | `bool`                                     | Allows the owner (acting as DAO for simplicity) to vote on proposals.         |
 * | `getProposalDetails`          | `public view` | `uint256 _proposalId`                       | `CuratorProposal`                            | Retrieves details of a curator change proposal.                               |
 * | `pauseContract`               | `onlyOwner`  |                                                 | `bool`                                     | Pauses the contract, halting most functions.                                 |
 * | `unpauseContract`             | `onlyOwner`  |                                                 | `bool`                                     | Unpauses the contract, resuming normal operations.                             |
 * | `withdrawContractBalance`     | `onlyOwner`  | `address payable _recipient`                   | `bool`                                     | Allows the contract owner to withdraw any Ether held by the contract.         |
 * | `getAllApprovedArtPieces`      | `public view` |                                                 | `uint256[]`                                | Returns a list of IDs of all approved art pieces.                             |
 * | `getAllPendingArtPieces`       | `public view` |                                                 | `uint256[]`                                | Returns a list of IDs of all pending art pieces (awaiting curation).           |
 * | `getAllExhibitions`           | `public view` |                                                 | `uint256[]`                                | Returns a list of IDs of all exhibitions.                                      |
 * | `getActiveExhibitions`        | `public view` |                                                 | `uint256[]`                                | Returns a list of IDs of exhibitions that are currently active.              |
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ArtVerseDAO is Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _artPieceIds;
    Counters.Counter private _exhibitionIds;
    Counters.Counter private _proposalIds;

    // Struct to represent an art piece submission
    struct ArtPiece {
        uint256 artPieceId;
        address artist;
        address nftContract;
        uint256 tokenId;
        string metadataURI;
        bool isApproved;
        bool isRejected;
        bool inExhibition;
        uint256 submissionTimestamp;
        uint256 votingEndTime;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        bool votingActive;
    }

    // Struct to represent an exhibition
    struct Exhibition {
        uint256 exhibitionId;
        string exhibitionName;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256[] artPieceIds;
        address curator; // Curator who created the exhibition
    }

    // Struct for Curator Change Proposals (Simple owner-only DAO in this example)
    struct CuratorProposal {
        uint256 proposalId;
        address targetCurator;
        bool addCurator; // True for add, false for remove
        uint256 votesFor;
        uint256 votesAgainst;
        bool proposalActive;
        bool proposalPassed;
        address proposer; // Owner who proposed it
    }

    mapping(uint256 => ArtPiece) public artPieces;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => CuratorProposal) public curatorProposals;
    mapping(address => bool) public curators;
    mapping(uint256 => mapping(address => bool)) public artPieceVotes; // artPieceId => curatorAddress => vote (true=approve, false=reject)
    mapping(uint256 => bool) public exhibitionActiveStatus; // exhibitionId => isActive

    event ArtSubmitted(uint256 artPieceId, address artist, address nftContract, uint256 tokenId);
    event ArtPieceApproved(uint256 artPieceId);
    event ArtPieceRejected(uint256 artPieceId);
    event ExhibitionCreated(uint256 exhibitionId, string exhibitionName, uint256 startTime, uint256 endTime, address curator);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artPieceId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 artPieceId);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event CuratorRegistered(address curatorAddress);
    event CuratorRemoved(address curatorAddress);
    event CuratorProposalCreated(uint256 proposalId, address targetCurator, bool addCurator, address proposer);
    event CuratorProposalVoted(uint256 proposalId, address voter, bool vote);
    event ContractPaused();
    event ContractUnpaused();
    event BalanceWithdrawn(address recipient, uint256 amount);

    modifier onlyCurator() {
        require(curators[msg.sender], "Only curators can perform this action");
        _;
    }

    modifier validArtPiece(uint256 _artPieceId) {
        require(_artPieceId > 0 && _artPieceId <= _artPieceIds.current(), "Invalid Art Piece ID");
        _;
    }

    modifier validExhibition(uint256 _exhibitionId) {
        require(_exhibitionId > 0 && _exhibitionId <= _exhibitionIds.current(), "Invalid Exhibition ID");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Invalid Proposal ID");
        _;
    }

    constructor() payable {
        // Optionally register the contract deployer as the first curator
        registerCurator(msg.sender);
    }

    /**
     * @dev Allows artists to submit their NFT artwork to the gallery.
     * @param _nftContract Address of the NFT contract.
     * @param _tokenId Token ID of the NFT.
     * @param _metadataURI URI pointing to the metadata of the NFT.
     * @return _artPieceId The ID of the newly submitted art piece.
     */
    function submitArt(address _nftContract, uint256 _tokenId, string memory _metadataURI) public whenNotPaused returns (uint256 _artPieceId) {
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");

        _artPieceIds.increment();
        uint256 artPieceId = _artPieceIds.current();

        artPieces[artPieceId] = ArtPiece({
            artPieceId: artPieceId,
            artist: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            metadataURI: _metadataURI,
            isApproved: false,
            isRejected: false,
            inExhibition: false,
            submissionTimestamp: block.timestamp,
            votingEndTime: 0,
            approvalVotes: 0,
            rejectionVotes: 0,
            votingActive: false
        });

        emit ArtSubmitted(artPieceId, msg.sender, _nftContract, _tokenId);
        return artPieceId;
    }

    /**
     * @dev Retrieves detailed information about a specific art piece.
     * @param _artPieceId ID of the art piece.
     * @return ArtPiece struct containing art piece details.
     */
    function getArtPieceDetails(uint256 _artPieceId) public view validArtPiece(_artPieceId) returns (ArtPiece memory) {
        return artPieces[_artPieceId];
    }

    /**
     * @dev Starts a voting period for curators to decide on an art piece's approval.
     * @param _artPieceId ID of the art piece to start voting for.
     * @param _votingDuration Duration of the voting period in seconds.
     */
    function startArtVoting(uint256 _artPieceId, uint256 _votingDuration) public onlyCurator validArtPiece(_artPieceId) whenNotPaused {
        require(!artPieces[_artPieceId].isApproved && !artPieces[_artPieceId].isRejected, "Art piece already decided");
        require(!artPieces[_artPieceId].votingActive, "Voting already active for this art piece");

        artPieces[_artPieceId].votingActive = true;
        artPieces[_artPieceId].votingEndTime = block.timestamp + _votingDuration;
    }

    /**
     * @dev Allows curators to cast their vote (approve/reject) for an art piece.
     * @param _artPieceId ID of the art piece to vote on.
     * @param _vote Boolean indicating the vote: true for approve, false for reject.
     */
    function castVote(uint256 _artPieceId, bool _vote) public onlyCurator validArtPiece(_artPieceId) whenNotPaused {
        require(artPieces[_artPieceId].votingActive, "Voting is not active for this art piece");
        require(block.timestamp <= artPieces[_artPieceId].votingEndTime, "Voting period has ended");
        require(!artPieceVotes[_artPieceId][msg.sender], "You have already voted on this art piece");

        artPieceVotes[_artPieceId][msg.sender] = true;
        if (_vote) {
            artPieces[_artPieceId].approvalVotes++;
        } else {
            artPieces[_artPieceId].rejectionVotes++;
        }
    }

    /**
     * @dev Ends the voting period for an art piece and determines approval based on votes.
     * @param _artPieceId ID of the art piece to end voting for.
     */
    function endArtVoting(uint256 _artPieceId) public onlyCurator validArtPiece(_artPieceId) whenNotPaused {
        require(artPieces[_artPieceId].votingActive, "Voting is not active for this art piece");
        require(block.timestamp > artPieces[_artPieceId].votingEndTime, "Voting period has not ended yet");

        artPieces[_artPieceId].votingActive = false;

        // Simple majority vote for approval (can be adjusted for more complex rules)
        if (artPieces[_artPieceId].approvalVotes > artPieces[_artPieceId].rejectionVotes) {
            approveArtPiece(_artPieceId);
        } else {
            rejectArtPiece(_artPieceId);
        }
    }


    /**
     * @dev Curator approves a submitted art piece for exhibition consideration.
     * @param _artPieceId ID of the art piece to approve.
     */
    function approveArtPiece(uint256 _artPieceId) public onlyCurator validArtPiece(_artPieceId) whenNotPaused {
        require(!artPieces[_artPieceId].isApproved && !artPieces[_artPieceId].isRejected, "Art piece already decided");
        artPieces[_artPieceId].isApproved = true;
        emit ArtPieceApproved(_artPieceId);
    }

    /**
     * @dev Curator rejects a submitted art piece.
     * @param _artPieceId ID of the art piece to reject.
     */
    function rejectArtPiece(uint256 _artPieceId) public onlyCurator validArtPiece(_artPieceId) whenNotPaused {
        require(!artPieces[_artPieceId].isApproved && !artPieces[_artPieceId].isRejected, "Art piece already decided");
        artPieces[_artPieceId].isRejected = true;
        emit ArtPieceRejected(_artPieceId);
    }

    /**
     * @dev Creates a new virtual art exhibition.
     * @param _exhibitionName Name of the exhibition.
     * @param _startTime Unix timestamp for the exhibition start time.
     * @param _endTime Unix timestamp for the exhibition end time.
     * @return _exhibitionId The ID of the newly created exhibition.
     */
    function createExhibition(string memory _exhibitionName, uint256 _startTime, uint256 _endTime) public onlyCurator whenNotPaused returns (uint256 _exhibitionId) {
        require(_startTime < _endTime, "Exhibition start time must be before end time");
        _exhibitionIds.increment();
        uint256 exhibitionId = _exhibitionIds.current();

        exhibitions[exhibitionId] = Exhibition({
            exhibitionId: exhibitionId,
            exhibitionName: _exhibitionName,
            startTime: _startTime,
            endTime: _endTime,
            isActive: false,
            artPieceIds: new uint256[](0),
            curator: msg.sender
        });
        exhibitionActiveStatus[exhibitionId] = false;

        emit ExhibitionCreated(exhibitionId, _exhibitionName, _startTime, _endTime, msg.sender);
        return exhibitionId;
    }

    /**
     * @dev Adds an approved art piece to a specific exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @param _artPieceId ID of the art piece to add.
     */
    function addArtToExhibition(uint256 _exhibitionId, uint256 _artPieceId) public onlyCurator validExhibition(_exhibitionId) validArtPiece(_artPieceId) whenNotPaused {
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only exhibition creator can add art");
        require(artPieces[_artPieceId].isApproved, "Art piece must be approved to be added to an exhibition");
        require(!artPieces[_artPieceId].inExhibition, "Art piece is already in an exhibition");

        exhibitions[_exhibitionId].artPieceIds.push(_artPieceId);
        artPieces[_artPieceId].inExhibition = true;
        emit ArtAddedToExhibition(_exhibitionId, _artPieceId);
    }

    /**
     * @dev Removes an art piece from an exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @param _artPieceId ID of the art piece to remove.
     */
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artPieceId) public onlyCurator validExhibition(_exhibitionId) validArtPiece(_artPieceId) whenNotPaused {
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only exhibition creator can remove art");
        require(artPieces[_artPieceId].inExhibition, "Art piece is not in this exhibition");

        uint256[] storage artPieceList = exhibitions[_exhibitionId].artPieceIds;
        for (uint256 i = 0; i < artPieceList.length; i++) {
            if (artPieceList[i] == _artPieceId) {
                artPieceList[i] = artPieceList[artPieceList.length - 1];
                artPieceList.pop();
                artPieces[_artPieceId].inExhibition = false;
                emit ArtRemovedFromExhibition(_exhibitionId, _artPieceId);
                return;
            }
        }
        revert("Art piece not found in exhibition"); // Should not reach here if inExhibition check is correct
    }

    /**
     * @dev Starts a scheduled exhibition, making it visible in the gallery.
     * @param _exhibitionId ID of the exhibition to start.
     */
    function startExhibition(uint256 _exhibitionId) public onlyCurator validExhibition(_exhibitionId) whenNotPaused {
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only exhibition creator can start exhibition");
        require(block.timestamp >= exhibitions[_exhibitionId].startTime, "Exhibition start time has not been reached yet");
        require(!exhibitions[_exhibitionId].isActive, "Exhibition is already active");

        exhibitions[_exhibitionId].isActive = true;
        exhibitionActiveStatus[_exhibitionId] = true;
        emit ExhibitionStarted(_exhibitionId);
    }

    /**
     * @dev Ends an active exhibition.
     * @param _exhibitionId ID of the exhibition to end.
     */
    function endExhibition(uint256 _exhibitionId) public onlyCurator validExhibition(_exhibitionId) whenNotPaused {
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only exhibition creator can end exhibition");
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active");
        require(block.timestamp >= exhibitions[_exhibitionId].endTime, "Exhibition end time has not been reached yet");

        exhibitions[_exhibitionId].isActive = false;
        exhibitionActiveStatus[_exhibitionId] = false;
        emit ExhibitionEnded(_exhibitionId);
    }

    /**
     * @dev Retrieves details of a specific exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @return Exhibition struct containing exhibition details.
     */
    function getExhibitionDetails(uint256 _exhibitionId) public view validExhibition(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /**
     * @dev Allows the contract owner to register new curators.
     * @param _curatorAddress Address of the curator to register.
     */
    function registerCurator(address _curatorAddress) public onlyOwner whenNotPaused returns (bool) {
        require(!curators[_curatorAddress], "Address is already a curator");
        curators[_curatorAddress] = true;
        emit CuratorRegistered(_curatorAddress);
        return true;
    }

    /**
     * @dev Allows the contract owner to remove curators.
     * @param _curatorAddress Address of the curator to remove.
     */
    function removeCurator(address _curatorAddress) public onlyOwner whenNotPaused returns (bool) {
        require(curators[_curatorAddress], "Address is not a curator");
        curators[_curatorAddress] = false;
        emit CuratorRemoved(_curatorAddress);
        return true;
    }

    /**
     * @dev Checks if an address is registered as a curator.
     * @param _address Address to check.
     * @return True if the address is a curator, false otherwise.
     */
    function isCurator(address _address) public view returns (bool) {
        return curators[_address];
    }

    /**
     * @dev Proposes adding or removing a curator (Simple owner-only DAO for this example).
     * @param _targetCurator Address of the curator to be added or removed.
     * @param _add Boolean: true to add, false to remove.
     * @return _proposalId The ID of the newly created proposal.
     */
    function proposeCuratorChange(address _targetCurator, bool _add) public onlyOwner whenNotPaused returns (uint256 _proposalId) {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        curatorProposals[proposalId] = CuratorProposal({
            proposalId: proposalId,
            targetCurator: _targetCurator,
            addCurator: _add,
            votesFor: 0,
            votesAgainst: 0,
            proposalActive: true,
            proposalPassed: false,
            proposer: msg.sender
        });

        emit CuratorProposalCreated(proposalId, _targetCurator, _add, msg.sender);
        return proposalId;
    }

    /**
     * @dev Allows the owner (acting as DAO for simplicity) to vote on proposals.
     * @param _proposalId ID of the proposal to vote on.
     * @param _vote Boolean: true for vote in favor, false for vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyOwner validProposal(_proposalId) whenNotPaused {
        require(curatorProposals[_proposalId].proposalActive, "Proposal is not active");
        require(curatorProposals[_proposalId].proposer == msg.sender, "Only proposer (owner in this case) can vote"); // Simple owner-only DAO

        if (_vote) {
            curatorProposals[_proposalId].votesFor++;
        } else {
            curatorProposals[_proposalId].votesAgainst++;
        }

        emit CuratorProposalVoted(_proposalId, msg.sender, _vote);
        _endCuratorProposal(_proposalId); // Automatically end proposal after owner votes (simple DAO)
    }

    /**
     * @dev Internal function to end a curator proposal and enact changes if passed (simple owner-only DAO).
     * @param _proposalId ID of the proposal to end.
     */
    function _endCuratorProposal(uint256 _proposalId) internal {
        require(curatorProposals[_proposalId].proposalActive, "Proposal is not active");

        curatorProposals[_proposalId].proposalActive = false;

        // Simple logic: if votesFor > votesAgainst, proposal passes (adjust for more complex DAO)
        if (curatorProposals[_proposalId].votesFor > curatorProposals[_proposalId].votesAgainst) {
            curatorProposals[_proposalId].proposalPassed = true;
            if (curatorProposals[_proposalId].addCurator) {
                registerCurator(curatorProposals[_proposalId].targetCurator);
            } else {
                removeCurator(curatorProposals[_proposalId].targetCurator);
            }
        }
    }

    /**
     * @dev Retrieves details of a curator change proposal.
     * @param _proposalId ID of the proposal.
     * @return CuratorProposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view validProposal(_proposalId) returns (CuratorProposal memory) {
        return curatorProposals[_proposalId];
    }

    /**
     * @dev Pauses the contract, halting most functions.
     */
    function pauseContract() public onlyOwner whenNotPaused returns (bool) {
        _pause();
        emit ContractPaused();
        return true;
    }

    /**
     * @dev Unpauses the contract, resuming normal operations.
     */
    function unpauseContract() public onlyOwner whenPaused returns (bool) {
        _unpause();
        emit ContractUnpaused();
        return true;
    }

    /**
     * @dev Allows the contract owner to withdraw any Ether held by the contract.
     * @param _recipient Address to receive the withdrawn Ether.
     */
    function withdrawContractBalance(address payable _recipient) public onlyOwner whenNotPaused returns (bool) {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance is zero");
        (bool success, ) = _recipient.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit BalanceWithdrawn(_recipient, balance);
        return true;
    }

    /**
     * @dev Returns a list of IDs of all approved art pieces.
     * @return Array of art piece IDs.
     */
    function getAllApprovedArtPieces() public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _artPieceIds.current(); i++) {
            if (artPieces[i].isApproved) {
                count++;
            }
        }
        uint256[] memory approvedArtPieceIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= _artPieceIds.current(); i++) {
            if (artPieces[i].isApproved) {
                approvedArtPieceIds[index] = i;
                index++;
            }
        }
        return approvedArtPieceIds;
    }

    /**
     * @dev Returns a list of IDs of all pending art pieces (awaiting curation).
     * @return Array of art piece IDs.
     */
    function getAllPendingArtPieces() public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _artPieceIds.current(); i++) {
            if (!artPieces[i].isApproved && !artPieces[i].isRejected) {
                count++;
            }
        }
        uint256[] memory pendingArtPieceIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= _artPieceIds.current(); i++) {
            if (!artPieces[i].isApproved && !artPieces[i].isRejected) {
                pendingArtPieceIds[index] = i;
                index++;
            }
        }
        return pendingArtPieceIds;
    }

    /**
     * @dev Returns a list of IDs of all exhibitions.
     * @return Array of exhibition IDs.
     */
    function getAllExhibitions() public view returns (uint256[] memory) {
        uint256[] memory allExhibitionIds = new uint256[](_exhibitionIds.current());
        for (uint256 i = 1; i <= _exhibitionIds.current(); i++) {
            allExhibitionIds[i - 1] = i;
        }
        return allExhibitionIds;
    }

    /**
     * @dev Returns a list of IDs of exhibitions that are currently active.
     * @return Array of exhibition IDs.
     */
    function getActiveExhibitions() public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _exhibitionIds.current(); i++) {
            if (exhibitions[i].isActive) {
                count++;
            }
        }
        uint256[] memory activeExhibitionIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= _exhibitionIds.current(); i++) {
            if (exhibitions[i].isActive) {
                activeExhibitionIds[index] = i;
                index++;
            }
        }
        return activeExhibitionIds;
    }
}
```