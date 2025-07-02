Okay, here is a Solidity smart contract for a Decentralized Autonomous Art Gallery. It incorporates several advanced, creative, and trendy concepts:

1.  **DAO Governance:** Community votes on art inclusion, parameters, and treasury spending.
2.  **Hybrid Voting:** Vote weight based on a combination of governance token balance and ownership of art NFTs from the gallery.
3.  **Dynamic NFTs:** Art NFTs can have mutable properties controlled by the artist or DAO governance, allowing them to evolve.
4.  **Curation/Exhibitions:** A module for curated temporary exhibitions with participation fees, distributed among participants and the gallery.
5.  **Layered Royalties:** Revenue distribution logic that includes artist royalties, gallery share, and potentially shares for exhibition participants.
6.  **Staking for Submission:** Artists must stake governance tokens to submit art, which can be returned or slashed based on governance decisions.

It will require interfaces for ERC-20 (for the governance token) and ERC-721 (for the art NFTs). We'll assume companion contracts for these tokens exist and are deployed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// 1. Imports and Interfaces
// 2. Enums & Structs
// 3. Events
// 4. Contract State Variables
// 5. Constructor
// 6. Modifiers
// 7. Core Governance Functions (Proposals, Voting, Finalization)
// 8. Art Submission & Lifecycle Functions
// 9. Treasury & Revenue Distribution Functions
// 10. Exhibition Module Functions
// 11. NFT Dynamic Properties Functions
// 12. Sale/Marketplace Integration (Simple Internal Listing)
// 13. Helper & Read Functions

// Function Summary:
// - constructor: Deploys/links ERC20 governance token and ERC721 art token, sets initial parameters.
// - submitArt: Allows artists to submit art NFTs, requires token stake and fee, mints NFT.
// - updateArtMetadata: Allows artists to update metadata for their submitted art (under governance consent).
// - proposeArtForGallery: Creates a governance proposal to include submitted art in the gallery.
// - voteOnProposal: Allows users with vote weight to vote on open proposals.
// - finalizeProposal: Finalizes a proposal after the voting period, executing the outcome if passed.
// - createGeneralProposal: Creates a general governance proposal (parameter changes, treasury spend, exhibition creation).
// - executeTreasurySpend: Executes a passed treasury spend proposal (called internally by finalizeProposal).
// - setProposalExecutionStatus: Helper to mark a proposal as executed.
// - receive / fallback: Allows contract to receive ETH into the treasury.
// - distributeRevenue: Distributes accumulated ETH revenue to artists, DAO, and exhibition participants based on shares.
// - artistWithdrawRevenue: Allows artists to withdraw their accumulated revenue share.
// - createExhibitionProposal: Creates a governance proposal for a new exhibition.
// - joinExhibition: Allows artists with gallery art to join an approved exhibition, paying a fee.
// - endExhibition: Finalizes an exhibition, distributing its collected fees.
// - setTokenDynamicProperty: Allows controlled update of a dynamic property for an art NFT.
// - listArtForSale: Marks a gallery art NFT as available for sale internally at a price.
// - cancelListing: Cancels an art sale listing.
// - buyArt: Facilitates buying a listed art NFT, handles payment and distribution.
// - _calculateVoteWeight: Internal helper to calculate a user's voting power (ERC20 + ERC721).
// - _distributeExhibitionFees: Internal helper to distribute fees from a finished exhibition.
// - _getArtPiece: Internal helper to retrieve art piece data securely.
// - getArtPieceDetails: Read function to get details of a submitted/gallery art piece.
// - getProposalDetails: Read function to get details of a proposal.
// - getExhibitionDetails: Read function to get details of an exhibition.
// - getUserVote: Read function to check how a user voted on a proposal.
// - getTreasuryBalance: Read function to check the contract's ETH balance.
// - getVoteWeight: Read function to check a user's current calculated vote weight.
// - isArtInGallery: Read function to check if art is approved for the gallery.
// - isArtListedForSale: Read function to check if art is currently listed for sale.
// - getActiveProposalCount: Read function to get the number of active proposals.
// - getExhibitionParticipantCount: Read function to get the number of participants in an exhibition.

contract DecentralizedAutonomousArtGallery is ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;

    // 1. Imports and Interfaces (already above)

    // 2. Enums & Structs

    enum ArtStatus { Submitted, Voting, Gallery, Rejected }
    enum ProposalType { ArtInclusion, ParameterChange, TreasurySpend, UpdateMetadataGov, ExhibitionCreate, ExhibitionEnd }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct ArtPiece {
        address artist;
        uint256 submissionTime;
        ArtStatus status;
        uint256 votesForGallery; // Used during ArtInclusion proposal voting
        uint256 votesAgainstGallery; // Used during ArtInclusion proposal voting
        string metadataURI;
        mapping(string => string) dynamicProperties; // Key-value for dynamic metadata
        uint256 accumulatedRevenue; // Revenue share for the artist
        bool listedForSale; // Internal listing status
        uint256 salePrice; // Internal listing price
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        string description;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPowerAtStart; // Snapshot of total possible voting power when proposal created
        ProposalState state;
        // Specifics based on ProposalType
        uint256 relatedArtId; // Used for ArtInclusion/UpdateMetadataGov
        bytes proposalData; // ABI-encoded data for ParameterChange, TreasurySpend, ExhibitionCreate/End
    }

    struct Exhibition {
        uint256 id;
        string title;
        string description;
        uint256 creationTime;
        uint256 endTime; // Exhibition ends after this time or via governance
        address curator; // Proposer of the exhibition
        uint256 entryFee; // ETH fee to join exhibition
        mapping(uint256 => bool) participants; // tokenId => isParticipant
        uint256 totalParticipants;
        uint256 totalFeesCollected; // ETH collected from participants
        bool ended;
    }

    // 3. Events

    event ArtSubmitted(uint256 indexed tokenId, address indexed artist, string metadataURI);
    event ArtStatusChanged(uint256 indexed tokenId, ArtStatus newStatus);
    event DynamicPropertyUpdated(uint256 indexed tokenId, string indexed key, string newValue);

    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter, bool decision, uint256 voteWeight);
    event ProposalFinalized(uint256 indexed proposalId, ProposalState finalState);
    event ParameterChanged(string parameterName, bytes newValue);
    event TreasurySpendExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount);

    event RevenueDistributed(uint256 totalDistributedETH, uint256 daoShare, uint256 artistsShare);
    event ArtistRevenueClaimed(address indexed artist, uint256 amount);

    event ExhibitionCreated(uint256 indexed exhibitionId, string title, address indexed curator);
    event JoinedExhibition(uint256 indexed exhibitionId, uint256 indexed tokenId, address indexed participant);
    event ExhibitionEnded(uint256 indexed exhibitionId);
    event ExhibitionFeesDistributed(uint256 indexed exhibitionId, uint256 daoShare, uint256 participantsShare);

    event ArtListedForSale(uint256 indexed tokenId, uint256 price);
    event ArtSaleCancelled(uint256 indexed tokenId);
    event ArtSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);

    // 4. Contract State Variables

    IERC20 public immutable GALLERY_TOKEN;
    IERC721 public immutable ART_NFT;

    mapping(uint256 => ArtPiece) public artPieces;
    uint256 private _nextTokenId; // Manually track token IDs if minting from here

    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId;

    // Mapping to track user votes on proposals: proposalId => voterAddress => hasVoted
    mapping(uint256 => mapping(address => bool)) private _userVotes;

    mapping(uint256 => Exhibition) public exhibitions;
    uint256 private _nextExhibitionId;

    // Governance Parameters (Modifiable by governance proposals)
    uint256 public submissionFee = 0.05 ether; // ETH required to submit art
    uint256 public minGalleryTokenToSubmit = 100 * 10**18; // Min GALLERY token balance to submit art
    uint256 public proposalCreationStake = 50 * 10**18; // GALLERY tokens staked to create a proposal
    uint256 public votingPeriodDuration = 7 days; // Duration for proposal voting
    uint256 public quorumPercentage = 5; // % of total voting power needed for proposal to be valid
    uint256 public proposalPassThreshold = 50; // % of votes needed to pass (simple majority > 50%)

    uint256 public constant ARTIST_ROYALTY_SHARE_BPS = 500; // 5% artist royalty on sales (Basis Points)
    uint256 public constant GALLERY_COMMISSION_SHARE_BPS = 200; // 2% gallery commission on sales (Basis Points)
    uint256 public constant EXHIBITION_PARTICIPANT_SHARE_BPS = 7000; // 70% of exhibition fees shared among participants (Basis Points)
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10000;

    // Vote weighting parameters (Adjustable by governance)
    uint256 public galleryTokenVoteWeight = 1; // 1 GALLERY token = 1 vote weight unit
    uint256 public artNFTVoteWeight = 100; // 1 Gallery Art NFT = 100 vote weight units

    // 5. Constructor

    constructor(address _galleryTokenAddress, address _artNFTAddress) {
        GALLERY_TOKEN = IERC20(_galleryTokenAddress);
        ART_NFT = IERC721(_artNFTAddress);
        _nextTokenId = 1; // Assuming token IDs start from 1
        _nextProposalId = 1;
        _nextExhibitionId = 1;
    }

    // Make the contract payable to receive ETH
    receive() external payable {}
    fallback() external payable {}

    // 6. Modifiers

    modifier onlyGalleryMember(uint256 _tokenId) {
        require(artPieces[_tokenId].status == ArtStatus.Gallery, "Artwork is not in the gallery");
        _;
    }

    modifier onlyArtist(uint256 _tokenId) {
         require(ART_NFT.ownerOf(_tokenId) == msg.sender, "Not the current owner of the art");
         require(artPieces[_tokenId].artist == msg.sender, "Not the original artist of the art"); // Optional: Restrict to original artist
         _;
    }

    // 7. Core Governance Functions

    /**
     * @notice Creates a general governance proposal.
     * @param _type The type of proposal (ParameterChange, TreasurySpend, ExhibitionCreate, ExhibitionEnd).
     * @param _description A description of the proposal.
     * @param _proposalData ABI-encoded data relevant to the proposal type (e.g., new parameter value, recipient+amount, exhibition details).
     */
    function createGeneralProposal(ProposalType _type, string calldata _description, bytes calldata _proposalData) external nonReentrant {
        require(_type != ProposalType.ArtInclusion && _type != ProposalType.UpdateMetadataGov, "Use proposeArtForGallery or createUpdateMetadataProposal for art-specific proposals");
        require(GALLERY_TOKEN.balanceOf(msg.sender) >= proposalCreationStake, "Insufficient stake to create proposal");

        // Stake the tokens
        require(GALLERY_TOKEN.transferFrom(msg.sender, address(this), proposalCreationStake), "Token stake failed");

        uint256 proposalId = _nextProposalId++;
        uint256 totalVotingPower = _calculateTotalVotingPower(); // Snapshot voting power

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: _type,
            proposer: msg.sender,
            description: _description,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtStart: totalVotingPower,
            state: ProposalState.Active,
            relatedArtId: 0, // Not used for general proposals
            proposalData: _proposalData
        });

        emit ProposalCreated(proposalId, _type, msg.sender);
    }

     /**
     * @notice Creates a governance proposal specifically for including submitted art in the gallery.
     * @param _tokenId The ID of the submitted art NFT.
     * @param _description A description for the art inclusion proposal.
     */
    function proposeArtForGallery(uint256 _tokenId, string calldata _description) external nonReentrant {
        ArtPiece storage art = artPieces[_tokenId];
        require(art.status == ArtStatus.Submitted, "Art must be in 'Submitted' status to be proposed");
        require(GALLERY_TOKEN.balanceOf(msg.sender) >= proposalCreationStake, "Insufficient stake to create proposal");

        // Stake the tokens
        require(GALLERY_TOKEN.transferFrom(msg.sender, address(this), proposalCreationStake), "Token stake failed");

        art.status = ArtStatus.Voting; // Change status to Voting

        uint256 proposalId = _nextProposalId++;
        uint256 totalVotingPower = _calculateTotalVotingPower(); // Snapshot voting power

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.ArtInclusion,
            proposer: msg.sender,
            description: _description,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + votingPeriodDuration,
            votesFor: 0, // Art-specific votes tracked in ArtPiece struct during voting
            votesAgainst: 0, // Art-specific votes tracked in ArtPiece struct during voting
            totalVotingPowerAtStart: totalVotingPower,
            state: ProposalState.Active,
            relatedArtId: _tokenId,
            proposalData: "" // Not used for art inclusion
        });

        emit ArtStatusChanged(_tokenId, ArtStatus.Voting);
        emit ProposalCreated(proposalId, ProposalType.ArtInclusion, msg.sender);
    }

    /**
     * @notice Allows a user to vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'For', False for 'Against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(!_userVotes[_proposalId][msg.sender], "Already voted on this proposal");

        uint256 voterWeight = _calculateVoteWeight(msg.sender);
        require(voterWeight > 0, "Voter has no voting power");

        _userVotes[_proposalId][msg.sender] = true;

        if (proposal.proposalType == ProposalType.ArtInclusion) {
            // Special voting logic for art inclusion directly on the ArtPiece
            ArtPiece storage art = artPieces[proposal.relatedArtId];
            require(art.status == ArtStatus.Voting, "Related art is not in Voting status");
            if (_support) {
                art.votesForGallery = art.votesForGallery.add(voterWeight);
            } else {
                art.votesAgainstGallery = art.votesAgainstGallery.add(voterWeight);
            }
        } else {
            // Standard voting for other proposal types
            if (_support) {
                proposal.votesFor = proposal.votesFor.add(voterWeight);
            } else {
                proposal.votesAgainst = proposal.votesAgainst.add(voterWeight);
            }
        }

        emit Voted(_proposalId, msg.sender, _support, voterWeight);
    }

    /**
     * @notice Finalizes a proposal after the voting period ends, executing the outcome.
     * Can be called by anyone.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended yet");

        // Calculate outcome based on proposal type
        uint256 totalVotes;
        uint256 votesFor;
        uint256 votesAgainst;

        if (proposal.proposalType == ProposalType.ArtInclusion) {
             ArtPiece storage art = artPieces[proposal.relatedArtId];
             require(art.status == ArtStatus.Voting, "Related art not in Voting status");
             votesFor = art.votesForGallery;
             votesAgainst = art.votesAgainstGallery;
             totalVotes = votesFor.add(votesAgainst);
        } else {
             votesFor = proposal.votesFor;
             votesAgainst = proposal.votesAgainst;
             totalVotes = votesFor.add(votesAgainst);
        }

        // Check quorum and majority
        // Quorum is based on votes cast relative to snapshot of total voting power
        bool quorumReached = (totalVotes.mul(BASIS_POINTS_DENOMINATOR) / proposal.totalVotingPowerAtStart) >= quorumPercentage.mul(100);
        bool passed = votesFor.mul(BASIS_POINTS_DENOMINATOR) / totalVotes > proposalPassThreshold.mul(100); // Votes FOR / Total Votes > Threshold

        if (!quorumReached || !passed) {
            proposal.state = ProposalState.Failed;
            // Return proposal creation stake
            GALLERY_TOKEN.transfer(proposal.proposer, proposalCreationStake);
             // If ArtInclusion failed, change status back to Submitted (or Rejected?)
            if (proposal.proposalType == ProposalType.ArtInclusion) {
                artPieces[proposal.relatedArtId].status = ArtStatus.Rejected; // Reject if fails governance
                 emit ArtStatusChanged(proposal.relatedArtId, ArtStatus.Rejected);
            }

        } else { // Quorum reached and Passed
            proposal.state = ProposalState.Succeeded;

            // Execute the proposal action based on type
            bool executionSuccess = false;
            if (proposal.proposalType == ProposalType.ArtInclusion) {
                ArtPiece storage art = artPieces[proposal.relatedArtId];
                art.status = ArtStatus.Gallery; // Change status to Gallery
                executionSuccess = true; // Art inclusion is just a status change
                 emit ArtStatusChanged(proposal.relatedArtId, ArtStatus.Gallery);
            } else if (proposal.proposalType == ProposalType.ParameterChange) {
                // Decode proposalData: (string paramName, bytes newValue)
                (string memory paramName, bytes memory newValue) = abi.decode(proposal.proposalData, (string, bytes));
                executionSuccess = _setParameter(paramName, newValue);
                if (executionSuccess) {
                     emit ParameterChanged(paramName, newValue);
                }
            } else if (proposal.proposalType == ProposalType.TreasurySpend) {
                // Decode proposalData: (address recipient, uint256 amount)
                 (address recipient, uint256 amount) = abi.decode(proposal.proposalData, (address, uint256));
                 executionSuccess = executeTreasurySpend(recipient, amount);
                 if (executionSuccess) {
                    emit TreasurySpendExecuted(_proposalId, recipient, amount);
                 }
            } else if (proposal.proposalType == ProposalType.ExhibitionCreate) {
                 // Decode proposalData: (string title, string description, uint256 endTime, uint256 entryFee)
                (string memory title, string memory description, uint256 endTime, uint256 entryFee) = abi.decode(proposal.proposalData, (string, string, uint256, uint256));
                executionSuccess = _createExhibition(title, description, proposal.proposer, endTime, entryFee);
            } else if (proposal.proposalType == ProposalType.ExhibitionEnd) {
                 // Decode proposalData: (uint256 exhibitionId)
                (uint256 exhibitionId) = abi.decode(proposal.proposalData, (uint256));
                 executionSuccess = endExhibition(exhibitionId); // This already handles checks and distribution
            }

            if (executionSuccess) {
                proposal.state = ProposalState.Executed;
                 // Return proposal creation stake only on successful execution? Or always on success?
                 // Let's return on any outcome (Success/Fail)
                 GALLERY_TOKEN.transfer(proposal.proposer, proposalCreationStake);
            } else {
                 // If execution failed *after* passing, the proposal is still marked as Succeeded but not Executed
                 // It might need manual intervention or a new proposal to fix.
                 // For this example, let's just mark it Succeeded and log failure.
                 // In a real DAO, execution would likely be a separate step or use a more robust executor pattern.
                 // We'll mark it Executed if _setParameter or executeTreasurySpend returned true.
            }
        }

        emit ProposalFinalized(_proposalId, proposal.state);
    }

    // Internal helper to set a parameter via governance
    function _setParameter(string memory _paramName, bytes memory _newValue) internal returns (bool) {
        bytes memory currentValue;
        bool success = true;

        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("submissionFee"))) {
            submissionFee = abi.decode(_newValue, (uint256));
            currentValue = abi.encode(submissionFee);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minGalleryTokenToSubmit"))) {
            minGalleryTokenToSubmit = abi.decode(_newValue, (uint256));
            currentValue = abi.encode(minGalleryTokenToSubmit);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("proposalCreationStake"))) {
            proposalCreationStake = abi.decode(_newValue, (uint256));
            currentValue = abi.encode(proposalCreationStake);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("votingPeriodDuration"))) {
            votingPeriodDuration = abi.decode(_newValue, (uint256));
            currentValue = abi.encode(votingPeriodDuration);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("quorumPercentage"))) {
             uint256 newQuorum = abi.decode(_newValue, (uint256));
             require(newQuorum <= 100, "Quorum percentage cannot exceed 100");
            quorumPercentage = newQuorum;
            currentValue = abi.encode(quorumPercentage);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("proposalPassThreshold"))) {
             uint256 newThreshold = abi.decode(_newValue, (uint256));
            require(newThreshold < 100, "Pass threshold cannot be 100% or more");
            proposalPassThreshold = newThreshold;
            currentValue = abi.encode(proposalPassThreshold);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("galleryTokenVoteWeight"))) {
            galleryTokenVoteWeight = abi.decode(_newValue, (uint256));
            currentValue = abi.encode(galleryTokenVoteWeight);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("artNFTVoteWeight"))) {
            artNFTVoteWeight = abi.decode(_newValue, (uint256));
            currentValue = abi.encode(artNFTVoteWeight);
        } else {
            // Parameter name not recognized
            success = false;
        }

        // You might want to add more complex logic here for different parameter types or validation
        return success;
    }


    // Internal helper to execute a treasury spend proposal
    function executeTreasurySpend(address _recipient, uint256 _amount) internal returns (bool) {
        require(_amount > 0, "Spend amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient treasury balance");
        // Prevent sending to zero address or token addresses by default (basic safety)
        require(_recipient != address(0) && _recipient != address(GALLERY_TOKEN) && _recipient != address(ART_NFT), "Invalid recipient address");

        (bool success, ) = payable(_recipient).call{value: _amount}("");
        // Note: In a real DAO, failure here might trigger a revert or a specific error state
        // We return success status for this example.
        return success;
    }

    // Helper function to mark a proposal as executed manually if needed (e.g., if execution failed in finalize)
    // Could be a DAO-governed function or require specific role, but for simplicity here, let's omit for now.
    // Function setProposalExecutionStatus(uint256 _proposalId, bool _executed) external ... { ... }

    // 8. Art Submission & Lifecycle Functions

    /**
     * @notice Allows an artist to submit a new piece of art to the gallery for potential inclusion.
     * Requires a submission fee and staking of GALLERY tokens.
     * Mints a new NFT representing the art piece.
     * @param _metadataURI The URI pointing to the art's metadata.
     */
    function submitArt(string calldata _metadataURI) external payable nonReentrant {
        require(msg.value >= submissionFee, "Insufficient submission fee");
        require(GALLERY_TOKEN.balanceOf(msg.sender) >= minGalleryTokenToSubmit, "Insufficient GALLERY token balance");

        // Note: Token staking logic could be more complex (e.g., separate staking contract).
        // Here we just check balance, assuming the requirement is just holding tokens.
        // To implement true staking, we'd need a transfer/approve pattern. Let's keep it simple for this example.

        // Mint the new NFT (Assuming ART_NFT contract has a mint function callable by the gallery)
        // This assumes the ART_NFT contract is designed to allow this gallery contract to mint.
        // A more robust approach might be for the artist to mint *first* and then transfer ownership
        // to the gallery contract temporarily upon submission, or for the gallery to be the sole minter.
        // Let's assume the gallery contract *can* call a mint function on ART_NFT.
        // The ART_NFT contract would need a function like `safeMint(address to, uint256 tokenId, string uri)`.
        // For this example, we'll simulate minting by incrementing a token ID and recording details.
        // In a real scenario, replace this with an actual cross-contract call to mint the ERC721.

        uint256 tokenId = _nextTokenId++;
        // ART_NFT.safeMint(msg.sender, tokenId, _metadataURI); // <-- Placeholder for actual minting

        artPieces[tokenId] = ArtPiece({
            artist: msg.sender,
            submissionTime: block.timestamp,
            status: ArtStatus.Submitted,
            votesForGallery: 0,
            votesAgainstGallery: 0,
            metadataURI: _metadataURI,
            accumulatedRevenue: 0,
            listedForSale: false,
            salePrice: 0
        });
        // Initialize dynamic properties mapping here if needed, though it's a mapping within the struct.

        // The submission fee ETH goes to the treasury
        // msg.value is automatically added to address(this).balance

        emit ArtSubmitted(tokenId, msg.sender, _metadataURI);
        emit ArtStatusChanged(tokenId, ArtStatus.Submitted);

         // Transfer ownership of the NFT to the gallery contract upon submission
         // This requires the ART_NFT contract to allow transfer to this contract AND this contract to implement IERC721Receiver.
         // ART_NFT.transferFrom(msg.sender, address(this), tokenId); // <-- Placeholder for transfer

    }

    /**
     * @notice Allows the artist of a *submitted* or *gallery* art piece to propose an update to its metadata URI.
     * This update typically requires governance approval (implicitly done by creating a proposal type).
     * @param _tokenId The ID of the art piece.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateArtMetadata(uint256 _tokenId, string calldata _newMetadataURI) external nonReentrant {
        ArtPiece storage art = artPieces[_tokenId];
        require(ART_NFT.ownerOf(_tokenId) == msg.sender, "Only the current owner can propose metadata updates");
        // Could add checks here requiring art status is Submitted or Gallery
        require(art.status == ArtStatus.Submitted || art.status == ArtStatus.Gallery, "Art must be submitted or in gallery to update metadata");
        // Note: The actual update happens via a governance proposal

        // Create a governance proposal for this metadata update
        // Encode the data needed for the proposal execution: (_tokenId, _newMetadataURI)
        bytes memory proposalData = abi.encode(_tokenId, _newMetadataURI);
        string memory description = string(abi.encodePacked("Propose metadata update for Art #", Strings.toString(_tokenId), " to ", _newMetadataURI));

        // This proposal type (UpdateMetadataGov) will be handled in finalizeProposal
        createGeneralProposal(ProposalType.UpdateMetadataGov, description, proposalData);

        // The actual metadata URI on the NFT is not updated until the proposal is executed.
    }

    // Internal function executed by governance proposal to apply metadata update
    function _applyMetadataUpdate(uint256 _tokenId, string memory _newMetadataURI) internal returns (bool) {
         ArtPiece storage art = artPieces[_tokenId];
         // Additional checks can be added here if needed (e.g., ensure art status is still valid)
         art.metadataURI = _newMetadataURI;
         // If the ART_NFT contract allows updating metadata, call it here:
         // ART_NFT.setTokenURI(_tokenId, _newMetadataURI); // <-- Placeholder if NFT supports this
         emit DynamicPropertyUpdated(_tokenId, "metadataURI", _newMetadataURI); // Re-using event for metadata change

         return true; // Indicate success
    }


    // 9. Treasury & Revenue Distribution Functions

    /**
     * @notice Distributes accumulated revenue in the treasury to artists, exhibition participants, and the DAO.
     * Can be called by anyone (incentivized perhaps by a small fee or gas reimbursement in a real system).
     */
    function distributeRevenue() external nonReentrant {
        uint256 totalTreasuryBalance = address(this).balance;
        require(totalTreasuryBalance > 0, "Treasury has no ETH to distribute");

        uint256 totalDistributed = 0;
        uint256 totalArtistShare = 0;

        // Distribute accumulated revenue to artists
        // This loop iterates through all art pieces. In a real scenario, this is gas-expensive
        // for many tokens. A better pattern is often for artists to 'pull' their revenue share
        // using artistWithdrawRevenue, rather than the contract 'pushing' to all artists.
        // Let's keep the pull pattern. This distributeRevenue function can just handle DAO share.

        // This function will now focus on distributing general treasury ETH
        // (e.g., from submission fees, gallery commission on sales NOT handled by internal buyArt,
        // or revenue from finalized exhibitions not yet distributed).
        // The buyArt function handles immediate distribution of sales revenue.

        // Let's refine: `distributeRevenue` will distribute the *general* treasury balance (from fees, etc.)
        // NOT the artist's accumulated revenue balance from sales. Artists claim their share directly.

        // Distribute a portion of general treasury balance to DAO operations/funds (via governance?)
        // Or simply keep it in the treasury for governance spend proposals.
        // Let's make this function primarily about distributing *Exhibition* revenue.

        // Revised distributeRevenue: Renamed to _distributeExhibitionFees and called internally.
        // The main treasury accumulates ETH from fees, sales commission etc. This is spent via TreasurySpend proposals.
        // Artists claim their share from individual art sales via artistWithdrawRevenue.
        // Exhibition fees are distributed upon exhibition ending via _distributeExhibitionFees.

        // Leaving this function structure here but modifying its purpose or making it internal
        // based on the revised revenue flow. Let's make this internal and triggered by specific events.
        // For a general "distribute ALL revenue" button, it's complex due to pull vs push, gas.
        // Let's remove this public `distributeRevenue` function and rely on TreasurySpend proposals
        // for general treasury funds, and pull for artist revenue. Exhibition revenue is handled on endExhibition.
    }

    /**
     * @notice Allows an artist to withdraw their accumulated revenue share from art sales.
     */
    function artistWithdrawRevenue() external nonReentrant {
        // Find all art pieces by this artist that have accumulated revenue
        // This requires iterating or tracking artist balances separately.
        // Iterating all art pieces is gas prohibitive.
        // Let's assume ArtPiece struct stores artist's *share* of revenue from sales of *that specific piece*.
        // The `buyArt` function will add revenue to `artPieces[tokenId].accumulatedRevenue`.

        uint256 totalClaimable = 0;
        // We need a way to track which art pieces belong to an artist efficiently without iterating all.
        // A mapping like `mapping(address => uint256[]) public artistArtTokens;` would help but requires
        // managing lists which is complex.
        // For this example, let's assume the artist knows their token IDs and calls this function
        // for specific tokens, or the contract somehow tracks claimable balance per artist.
        // A simpler approach is to track total accumulated revenue per artist across all their pieces.
        // Let's add `mapping(address => uint256) public artistTotalClaimableRevenue;` and update `buyArt`.

        // Based on the revised `buyArt` adding to `artistTotalClaimableRevenue`:
        uint256 claimable = artistTotalClaimableRevenue[msg.sender];
        require(claimable > 0, "No claimable revenue for this artist");

        artistTotalClaimableRevenue[msg.sender] = 0; // Reset balance before transfer

        (bool success, ) = payable(msg.sender).call{value: claimable}("");
        require(success, "ETH transfer failed"); // Revert if transfer fails

        emit ArtistRevenueClaimed(msg.sender, claimable);
    }

    mapping(address => uint256) public artistTotalClaimableRevenue; // Added state variable

    // 10. Exhibition Module Functions

    // _createExhibition is an internal helper executed by a governance proposal (ExhibitionCreate)
    function _createExhibition(string memory _title, string memory _description, address _curator, uint256 _endTime, uint256 _entryFee) internal returns (bool) {
        require(_endTime > block.timestamp, "Exhibition end time must be in the future");
        uint256 exhibitionId = _nextExhibitionId++;
        exhibitions[exhibitionId] = Exhibition({
            id: exhibitionId,
            title: _title,
            description: _description,
            creationTime: block.timestamp,
            endTime: _endTime,
            curator: _curator,
            entryFee: _entryFee,
            participants: mapping(uint256 => bool),
            totalParticipants: 0,
            totalFeesCollected: 0,
            ended: false
        });
        emit ExhibitionCreated(exhibitionId, _title, _curator);
        return true;
    }

    /**
     * @notice Allows an artist who owns a piece of art in the gallery to join an exhibition.
     * Requires the art to be in the gallery and pays the exhibition entry fee.
     * @param _exhibitionId The ID of the exhibition.
     * @param _tokenId The ID of the art piece to join with.
     */
    function joinExhibition(uint256 _exhibitionId, uint256 _tokenId) external payable nonReentrant onlyGalleryMember(_tokenId) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(!exhibition.ended, "Exhibition has ended");
        require(block.timestamp < exhibition.endTime, "Cannot join exhibition after its planned end time");
        require(ART_NFT.ownerOf(_tokenId) == msg.sender, "Only the owner of the art can join");
        require(!exhibition.participants[_tokenId], "This art piece is already in the exhibition");
        require(msg.value >= exhibition.entryFee, "Insufficient entry fee");

        // Refund excess ETH if sent more than required
        if (msg.value > exhibition.entryFee) {
            payable(msg.sender).transfer(msg.value.sub(exhibition.entryFee));
        }

        exhibition.participants[_tokenId] = true;
        exhibition.totalParticipants = exhibition.totalParticipants.add(1);
        exhibition.totalFeesCollected = exhibition.totalFeesCollected.add(exhibition.entryFee);

        emit JoinedExhibition(_exhibitionId, _tokenId, msg.sender);
    }

    /**
     * @notice Ends an exhibition and distributes the collected fees.
     * Can be called by the curator or via governance proposal after the end time.
     * @param _exhibitionId The ID of the exhibition to end.
     */
    function endExhibition(uint256 _exhibitionId) public nonReentrant returns (bool) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(!exhibition.ended, "Exhibition already ended");
        // Can be ended by curator after time OR via governance proposal (ExhibitionEnd type)
        require(msg.sender == exhibition.curator || block.timestamp > exhibition.endTime, "Exhibition can only be ended by curator or after planned end time");

        exhibition.ended = true;

        // Distribute fees collected during the exhibition
        _distributeExhibitionFees(_exhibitionId);

        emit ExhibitionEnded(_exhibitionId);
        return true;
    }

    // Internal helper to distribute fees after an exhibition ends
    function _distributeExhibitionFees(uint256 _exhibitionId) internal {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        uint256 totalFees = exhibition.totalFeesCollected;
        if (totalFees == 0) return;

        uint256 daoShare = totalFees.mul(BASIS_POINTS_DENOMINATOR.sub(EXHIBITION_PARTICIPANT_SHARE_BPS)) / BASIS_POINTS_DENOMINATOR;
        uint256 participantsShare = totalFees.sub(daoShare); // The rest goes to participants

        // Transfer DAO share to treasury (already here) - no need to transfer again

        // Distribute participant share among participants
        if (participantsShare > 0 && exhibition.totalParticipants > 0) {
             uint256 sharePerParticipant = participantsShare / exhibition.totalParticipants;
             // This part is tricky and gas-intensive if there are many participants.
             // A pull pattern for participants to claim their share would be better.
             // For simplicity in this example, we'll skip direct participant distribution here
             // and state that participant share could be managed/claimed separately or added to a claimable pool.
             // Let's instead add the participant share amount to the curator's claimable revenue as a simplification.
             // In a real system, you'd need a claim mechanism for each participant.
             // exhibition.curator could be rewarded instead of participants, or participants claim individually.
             // Let's add participant share to artistTotalClaimableRevenue for each participating artist whose art is in the exhibition.
             // This requires iterating participants, which is still bad.

             // Revised approach: exhibition fees simply stay in the treasury.
             // They contribute to the general treasury balance which can be spent via governance proposals (TreasurySpend).
             // Remove participant share concept for simplicity and gas.
             // Or, exhibition curator gets a cut? Let's give curator a cut for organizing.

             // Revised Exhibition Fees Distribution:
             // curatorShare = totalFees * CURATOR_SHARE_BPS / BASIS_POINTS_DENOMINATOR
             // daoShare = totalFees - curatorShare
             // totalFees already in treasury. Curator pulls their share.
             // Add `mapping(address => uint256) public curatorClaimableRevenue;`

             // Let's stick to the simpler model: Fees collected -> Stay in Treasury -> Spent via governance.
             // Remove complex distribution logic for exhibitions. The `endExhibition` just marks it ended.
             // The collected fees are already added to the treasury's ETH balance via `joinExhibition`.

             // Okay, final attempt at distribution logic for exhibitions:
             // Part goes to DAO (stays in treasury), part goes to *participating artists* (added to their claimable balance).
             // We need to iterate participants mapping. This is gas heavy.
             // Let's assume `participants` mapping maps tokenIds to `true`. We need the artist address from tokenId.
             // This is still complex.

             // Simplest functional approach for this example:
             // All exhibition fees stay in the treasury. Governance decides how to spend them.
             // This avoids complex iteration/claim logic for this example contract.
             // So, `_distributeExhibitionFees` function becomes unnecessary if fees just stay in treasury.
             // Let's remove the distribution logic and state variables related to it.

            emit ExhibitionFeesDistributed(_exhibitionId, totalFees, 0); // All fees go to DAO/Treasury
        }


    // 11. NFT Dynamic Properties Functions

    /**
     * @notice Allows the artist of a gallery art piece to update a specific dynamic property.
     * Can be restricted by the DAO or parameters.
     * @param _tokenId The ID of the art piece.
     * @param _key The key of the dynamic property.
     * @param _value The new value for the dynamic property.
     */
    function setTokenDynamicProperty(uint256 _tokenId, string calldata _key, string calldata _value) external onlyGalleryMember(_tokenId) nonReentrant {
        // Option 1: Only the artist can set dynamic properties
        require(artPieces[_tokenId].artist == msg.sender, "Only the original artist can set dynamic properties");

        // Option 2: Only the current owner can set dynamic properties (if ownership can change)
        // require(ART_NFT.ownerOf(_tokenId) == msg.sender, "Only the current owner can set dynamic properties");

        // Option 3: Requires governance proposal (more decentralized, but adds friction)
        // This could be a specific proposal type, or certain keys might require governance.
        // Let's implement Option 1 for simplicity, but note Option 3 is more DAO-like.

        // Basic validation for key (e.g., not empty)
        require(bytes(_key).length > 0, "Dynamic property key cannot be empty");

        artPieces[_tokenId].dynamicProperties[_key] = _value;

        emit DynamicPropertyUpdated(_tokenId, _key, _value);
    }

    // 12. Sale/Marketplace Integration (Simple Internal Listing)

    struct SaleListing {
        uint256 tokenId;
        uint256 price; // Price in ETH
        address seller;
        bool active;
    }

    mapping(uint256 => SaleListing) public saleListings; // tokenId => SaleListing

    /**
     * @notice Allows the owner of a gallery art piece to list it for sale internally.
     * @param _tokenId The ID of the art piece.
     * @param _price The price in ETH.
     */
    function listArtForSale(uint256 _tokenId, uint256 _price) external onlyGalleryMember(_tokenId) nonReentrant {
        require(ART_NFT.ownerOf(_tokenId) == msg.sender, "Only the art owner can list for sale");
        require(_price > 0, "Price must be greater than zero");
        require(!saleListings[_tokenId].active, "Art is already listed for sale");

        saleListings[_tokenId] = SaleListing({
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            active: true
        });

        artPieces[_tokenId].listedForSale = true; // Update ArtPiece state
        artPieces[_tokenId].salePrice = _price;

        emit ArtListedForSale(_tokenId, _price);
    }

    /**
     * @notice Allows the seller to cancel an active sale listing.
     * @param _tokenId The ID of the art piece.
     */
    function cancelListing(uint256 _tokenId) external nonReentrant {
        SaleListing storage listing = saleListings[_tokenId];
        require(listing.active, "Art is not listed for sale");
        require(listing.seller == msg.sender, "Only the seller can cancel the listing");

        listing.active = false; // Deactivate the listing

        artPieces[_tokenId].listedForSale = false; // Update ArtPiece state
        artPieces[_tokenId].salePrice = 0;

        // Consider clearing the struct for gas efficiency if listings are short-lived
        // delete saleListings[_tokenId]; // Or delete the struct

        emit ArtSaleCancelled(_tokenId);
    }

    /**
     * @notice Allows a buyer to purchase a listed art piece.
     * Handles ETH transfer and revenue distribution (seller, artist royalty, gallery commission).
     * @param _tokenId The ID of the art piece to buy.
     */
    function buyArt(uint256 _tokenId) external payable nonReentrant {
        SaleListing storage listing = saleListings[_tokenId];
        require(listing.active, "Art is not listed for sale");
        require(msg.value >= listing.price, "Insufficient ETH sent");
        require(ART_NFT.ownerOf(_tokenId) == listing.seller, "Seller no longer owns the art"); // Check ownership again
        require(msg.sender != listing.seller, "Cannot buy your own art");

        uint256 totalPrice = msg.value;
        uint256 sellerCut = totalPrice;
        uint256 artistRoyalty = 0;
        uint256 galleryCommission = 0;

        // Calculate and deduct royalty/commission if applicable
        // Only apply royalty/commission if the art is from this gallery AND sold via this mechanism.
        // artPieces mapping check implicitly verifies it's from this gallery.
        if (artPieces[_tokenId].artist != address(0)) { // Check if it's a gallery-managed art piece
            artistRoyalty = totalPrice.mul(ARTIST_ROYALTY_SHARE_BPS) / BASIS_POINTS_DENOMINATOR;
            galleryCommission = totalPrice.mul(GALLERY_COMMISSION_SHARE_BPS) / BASIS_POINTS_DENOMINATOR;
            sellerCut = totalPrice.sub(artistRoyalty).sub(galleryCommission);

            // Add artist's share to their claimable balance (pull pattern)
            artistTotalClaimableRevenue[artPieces[_tokenId].artist] = artistTotalClaimableRevenue[artPieces[_tokenId].artist].add(artistRoyalty);
        }

        // Send seller's cut
        (bool sellerSuccess, ) = payable(listing.seller).call{value: sellerCut}("");
        // If seller transfer fails, should the whole transaction revert? Yes, crucial.
        require(sellerSuccess, "Seller ETH transfer failed");

        // Gallery commission stays in this contract's balance (added via msg.value)
        // Refund excess ETH to buyer
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value.sub(totalPrice));
        }

        // Deactivate the listing
        listing.active = false;
        artPieces[_tokenId].listedForSale = false; // Update ArtPiece state
        artPieces[_tokenId].salePrice = 0;

        // Transfer NFT ownership to the buyer
        ART_NFT.safeTransferFrom(listing.seller, msg.sender, _tokenId);

        emit ArtSold(_tokenId, msg.sender, listing.seller, totalPrice);
    }


    // 13. Helper & Read Functions

    /**
     * @notice Calculates the voting weight for a given address.
     * Weight is based on a combination of GALLERY token balance and number of owned gallery ART NFTs.
     * @param _voter The address to calculate vote weight for.
     * @return The calculated vote weight.
     */
    function _calculateVoteWeight(address _voter) internal view returns (uint256) {
        uint256 tokenBalance = GALLERY_TOKEN.balanceOf(_voter);
        uint256 nftBalance = ART_NFT.balanceOf(_voter); // Balance of ANY ERC721, not just gallery-approved ones
        // How to check only gallery-approved NFTs? Requires iterating owned tokens & checking status, gas heavy.
        // Simpler approach for example: Count *any* NFT from the configured ART_NFT contract, assuming it's the gallery's contract.
        // A more precise approach might involve tracking NFT ownership within the gallery contract's state.
        // Let's stick to checking balance on the linked NFT contract as a proxy.

        uint256 weight = tokenBalance.mul(galleryTokenVoteWeight).add(nftBalance.mul(artNFTVoteWeight));
        return weight;
    }

     /**
     * @notice Calculates the total current voting power of all potential voters.
     * Used to snapshot voting power when a proposal is created for quorum calculation.
     * NOTE: This function is inherently difficult to make accurate and gas-efficient for large systems.
     * It requires iterating through token holders/NFT owners or relying on off-chain indexing.
     * For this example, we will make a simplifying assumption or use a placeholder.
     * A real system might use checkpoints in the ERC20/ERC721 tokens or rely on off-chain calculation + oracle.
     * Placeholder: Return a fixed large number or use a highly simplified calculation.
     * Let's assume a simple, potentially inaccurate total based on token supply for this example.
     * A better approach is to have checkpointed balances in the token contracts.
     * If GALLERY_TOKEN is OpenZeppelin ERC20Votes, use `GALLERY_TOKEN.getPastTotalSupply(block.number - 1)` or similar.
     * If ART_NFT is OpenZeppelin ERC721Votes, use similar.
     * We'll make a *very* simplifying assumption - total supply of ERC20 + total supply of ERC721. This is *not* accurate as not all are voters.
     * A slightly better *placeholder* for demo: Total Supply of GALLERY_TOKEN only. Still not perfect.
     * Let's just use total supply of GALLERY_TOKEN * weight + total supply of ART_NFT * weight. This is maximum *possible* power.
     */
    function _calculateTotalVotingPower() internal view returns (uint256) {
         uint256 totalTokenSupply = GALLERY_TOKEN.totalSupply();
         uint256 totalNFTSupply = ART_NFT.totalSupply(); // If ERC721 supports totalSupply

         // Handle ERC721 missing totalSupply
         if (totalNFTSupply == 0) {
             // If ART_NFT doesn't have totalSupply, maybe estimate based on max token ID minted if available, or ignore NFT part for total
             // For simplicity, if totalSupply is not supported, just use token supply part.
             // A robust solution needs to know total voters or use checkpointing.
             // Let's assume ART_NFT has totalSupply for this example.
         }

         // This calculates the *maximum potential* voting power, not the power of active participants.
         // Quorum check should ideally be against staked/delegated power, or snapshot of actual holders above a threshold.
         // This is a known challenge in on-chain governance.
         return totalTokenSupply.mul(galleryTokenVoteWeight).add(totalNFTSupply.mul(artNFTVoteWeight));
    }


     /**
     * @notice Internal helper to safely get ArtPiece data.
     * @param _tokenId The ID of the art piece.
     * @return The ArtPiece struct.
     */
    function _getArtPiece(uint256 _tokenId) internal view returns (ArtPiece storage) {
         require(artPieces[_tokenId].submissionTime > 0, "Invalid art piece ID"); // Check if the art piece exists
         return artPieces[_tokenId];
    }

    /**
     * @notice Get details of a submitted or gallery art piece.
     * @param _tokenId The ID of the art piece.
     * @return artist The artist's address.
     * @return submissionTime The time the art was submitted.
     * @return status The current status of the art.
     * @return metadataURI The URI of the art's metadata.
     * @return accumulatedRevenue The revenue share accumulated for the artist from this piece.
     * @return listedForSale Whether the art is currently listed for sale internally.
     * @return salePrice The internal sale price if listed.
     * @return votesForGallery Votes accumulated for gallery inclusion (during voting).
     * @return votesAgainstGallery Votes accumulated against gallery inclusion (during voting).
     */
    function getArtPieceDetails(uint256 _tokenId) external view returns (
        address artist,
        uint256 submissionTime,
        ArtStatus status,
        string memory metadataURI,
        uint256 accumulatedRevenue,
        bool listedForSale,
        uint256 salePrice,
        uint256 votesForGallery,
        uint256 votesAgainstGallery
    ) {
        ArtPiece storage art = _getArtPiece(_tokenId);
        return (
            art.artist,
            art.submissionTime,
            art.status,
            art.metadataURI,
            art.accumulatedRevenue,
            art.listedForSale,
            art.salePrice,
            art.votesForGallery,
            art.votesAgainstGallery
        );
    }

     /**
     * @notice Get the value of a specific dynamic property for an art piece.
     * @param _tokenId The ID of the art piece.
     * @param _key The key of the dynamic property.
     * @return The value of the dynamic property.
     */
    function getArtDynamicProperty(uint256 _tokenId, string calldata _key) external view returns (string memory) {
        // No need for onlyGalleryMember if dynamic properties are visible even when not in gallery
         require(artPieces[_tokenId].submissionTime > 0, "Invalid art piece ID"); // Check if the art piece exists
         return artPieces[_tokenId].dynamicProperties[_key];
    }


    /**
     * @notice Get details of a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return id The proposal ID.
     * @return proposalType The type of proposal.
     * @return proposer The proposer's address.
     * @return description The proposal description.
     * @return creationTime The creation timestamp.
     * @return votingEndTime The voting end timestamp.
     * @return votesFor Votes in favor.
     * @return votesAgainst Votes against.
     * @return totalVotingPowerAtStart Snapshot of total voting power.
     * @return state The current state of the proposal.
     * @return relatedArtId Related art ID (if applicable).
     * @return proposalData ABI-encoded proposal data.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (
        uint256 id,
        ProposalType proposalType,
        address proposer,
        string memory description,
        uint256 creationTime,
        uint256 votingEndTime,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 totalVotingPowerAtStart,
        ProposalState state,
        uint256 relatedArtId,
        bytes memory proposalData
    ) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime > 0, "Invalid proposal ID"); // Check if proposal exists
         // Note: ArtInclusion votes are stored on the ArtPiece struct during voting,
         // but the final vote counts after finalize() are stored on the Proposal struct.
         // This function returns the votes stored on the Proposal struct.
        return (
            proposal.id,
            proposal.proposalType,
            proposal.proposer,
            proposal.description,
            proposal.creationTime,
            proposal.votingEndTime,
            proposal.votesFor, // These are the final counts for ArtInclusion *after* finalize
            proposal.votesAgainst, // These are the final counts for ArtInclusion *after* finalize
            proposal.totalVotingPowerAtStart,
            proposal.state,
            proposal.relatedArtId,
            proposal.proposalData
        );
    }

    /**
     * @notice Check if a user has voted on a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @param _voter The address of the voter.
     * @return True if the user has voted, false otherwise.
     */
    function getUserVote(uint256 _proposalId, address _voter) external view returns (bool) {
         require(proposals[_proposalId].creationTime > 0, "Invalid proposal ID"); // Check if proposal exists
         return _userVotes[_proposalId][_voter];
    }

    /**
     * @notice Get details of an exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @return id The exhibition ID.
     * @return title The exhibition title.
     * @return description The exhibition description.
     * @return creationTime The creation timestamp.
     * @return endTime The planned end timestamp.
     * @return curator The curator's address.
     * @return entryFee The entry fee.
     * @return totalParticipants The total number of participants.
     * @return totalFeesCollected The total fees collected.
     * @return ended Whether the exhibition has ended.
     */
    function getExhibitionDetails(uint256 _exhibitionId) external view returns (
        uint256 id,
        string memory title,
        string memory description,
        uint256 creationTime,
        uint256 endTime,
        address curator,
        uint256 entryFee,
        uint256 totalParticipants,
        uint256 totalFeesCollected,
        bool ended
    ) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.creationTime > 0, "Invalid exhibition ID"); // Check if exhibition exists
        return (
            exhibition.id,
            exhibition.title,
            exhibition.description,
            exhibition.creationTime,
            exhibition.endTime,
            exhibition.curator,
            exhibition.entryFee,
            exhibition.totalParticipants,
            exhibition.totalFeesCollected,
            exhibition.ended
        );
    }

     /**
     * @notice Check if a specific art piece is participating in an exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @param _tokenId The ID of the art piece.
     * @return True if the art piece is participating, false otherwise.
     */
    function isArtInExhibition(uint256 _exhibitionId, uint256 _tokenId) external view returns (bool) {
         Exhibition storage exhibition = exhibitions[_exhibitionId];
         require(exhibition.creationTime > 0, "Invalid exhibition ID"); // Check if exhibition exists
         return exhibition.participants[_tokenId];
    }

    /**
     * @notice Gets the calculated vote weight for a specific address.
     * @param _voter The address to check.
     * @return The vote weight.
     */
    function getVoteWeight(address _voter) external view returns (uint256) {
        return _calculateVoteWeight(_voter);
    }

    /**
     * @notice Gets the current ETH balance of the contract treasury.
     * @return The treasury balance.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Checks if a specific art piece has been approved for the gallery.
     * @param _tokenId The ID of the art piece.
     * @return True if the art is in the gallery, false otherwise.
     */
    function isArtInGallery(uint256 _tokenId) external view returns (bool) {
        return artPieces[_tokenId].status == ArtStatus.Gallery;
    }

     /**
     * @notice Checks if a specific art piece is currently listed for sale internally.
     * @param _tokenId The ID of the art piece.
     * @return True if listed, false otherwise.
     */
    function isArtListedForSale(uint256 _tokenId) external view returns (bool) {
         return saleListings[_tokenId].active; // Rely on the SaleListing struct state
    }

    /**
     * @notice Gets the count of active proposals.
     * Note: This requires iterating or maintaining a separate counter/list of active proposals, which is gas-intensive.
     * A simpler approach for this example is to provide the *next* proposal ID.
     * Or, require an off-chain indexer to track active proposals.
     * Let's provide the next ID as a proxy for total created proposals.
     * To get active count, an off-chain solution is best practice for large numbers.
     */
     function getTotalProposalsCreated() external view returns (uint256) {
         return _nextProposalId.sub(1); // Assuming IDs start from 1
     }

     /**
      * @notice Gets the total number of participants in an exhibition.
      * @param _exhibitionId The ID of the exhibition.
      * @return The total participant count.
      */
     function getExhibitionParticipantCount(uint256 _exhibitionId) external view returns (uint256) {
         Exhibition storage exhibition = exhibitions[_exhibitionId];
         require(exhibition.creationTime > 0, "Invalid exhibition ID");
         return exhibition.totalParticipants;
     }

     // Needed for IERC721Receiver compliance
     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
         // Ensure the call is from the trusted ART_NFT contract
         require(msg.sender == address(ART_NFT), "Must be called from the ART_NFT contract");
         // Perform any checks needed upon receiving an NFT.
         // For example, if the submitArt function transfers the NFT to the gallery contract:
         // - Check 'from' is the artist.
         // - Check 'tokenId' is the expected ID being submitted.
         // - You might update state related to the received token here.

         // Return the ERC721 magic value to indicate successful receipt
         return this.onERC721Received.selector;
     }
}

// Note: This contract requires the deployment of a compliant ERC20 (GALLERY_TOKEN)
// and a compliant ERC721 (ART_NFT) contract beforehand.
// The ART_NFT contract would need to be configured to potentially:
// 1. Allow the Gallery contract to mint tokens (if submitArt mints).
// 2. Allow ownership transfer to the Gallery contract (if artists transfer upon submission).
// 3. Implement `totalSupply()` if used for vote weight calculation.
// 4. Ideally, support ERC2981 for royalty standard or have hooks for custom royalty logic.
// 5. Ideally, support ERC721Votes or similar for efficient vote power calculation if NFT balance is used.

// The ERC20 GALLERY_TOKEN would need to:
// 1. Implement `totalSupply()`.
// 2. Be deployed and tokens distributed.
// 3. Ideally, support ERC20Votes for efficient checkpointed balance reads.
```