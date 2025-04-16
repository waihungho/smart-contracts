```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to collaborate, curate, exhibit, and monetize their digital art.
 *
 * **Outline & Function Summary:**
 *
 * **1. Membership & Governance:**
 *   - `requestMembership()`: Artists can request to join the collective.
 *   - `approveMembership(address _artist)`: Governance members can approve membership requests.
 *   - `revokeMembership(address _artist)`: Governance members can revoke membership.
 *   - `delegateVotePower(address _delegate)`: Members can delegate their voting power to another member.
 *   - `createGovernanceProposal(string _title, string _description, bytes _calldata)`: Governance members propose changes to the collective (contract parameters, rules, etc.).
 *   - `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Members vote on governance proposals.
 *   - `executeGovernanceProposal(uint256 _proposalId)`: Governance members execute approved proposals.
 *   - `getGovernanceProposalStatus(uint256 _proposalId)`: View the status of a governance proposal.
 *   - `setGovernanceThreshold(uint256 _newThreshold)`: Governance function to change the quorum for proposals.
 *
 * **2. Art Submission & Curation:**
 *   - `submitArtProposal(string _title, string _description, string _ipfsHash, uint256 _royaltyPercentage)`: Artists submit art proposals with metadata and IPFS hash.
 *   - `voteOnArtProposal(uint256 _proposalId, bool _support)`: Members vote on art proposals for curation.
 *   - `mintArtNFT(uint256 _proposalId)`: Mint an NFT for approved art proposals (creates an ERC721 token representing the artwork).
 *   - `setArtMetadata(uint256 _artId, string _newIpfsHash)`: Artists can update metadata of their submitted art (governance approval might be needed for significant changes).
 *   - `burnArtNFT(uint256 _artId)`: In rare cases, governance can decide to burn an NFT (e.g., copyright issues).
 *   - `getArtDetails(uint256 _artId)`: View details of a specific artwork.
 *   - `getArtProposalDetails(uint256 _proposalId)`: View details of an art proposal.
 *
 * **3. Exhibition & Marketplace:**
 *   - `createExhibitionProposal(string _title, string _description, uint256 _startTime, uint256 _endTime)`: Governance members propose art exhibitions.
 *   - `voteOnExhibitionProposal(uint256 _proposalId, bool _support)`: Members vote on exhibition proposals.
 *   - `addArtToExhibition(uint256 _exhibitionId, uint256 _artId)`: Governance members add curated art to approved exhibitions.
 *   - `removeArtFromExhibition(uint256 _exhibitionId, uint256 _artId)`: Governance members remove art from exhibitions.
 *   - `startExhibition(uint256 _exhibitionId)`: Governance members manually start an exhibition (can be automated based on time).
 *   - `endExhibition(uint256 _exhibitionId)`: Governance members manually end an exhibition (can be automated).
 *   - `purchaseArt(uint256 _artId)`: Users can purchase NFTs of curated art directly from the contract (marketplace functionality).
 *   - `setArtPrice(uint256 _artId, uint256 _price)`: Artists can set the price for their curated art (governance approval might be needed).
 *   - `getExhibitionDetails(uint256 _exhibitionId)`: View details of an exhibition.
 *
 * **4. Treasury & Revenue Sharing:**
 *   - `donateToCollective()`: Anyone can donate ETH to the collective treasury.
 *   - `createFundingProposal(string _title, string _description, address _recipient, uint256 _amount)`: Governance members can propose funding proposals to allocate treasury funds.
 *   - `voteOnFundingProposal(uint256 _proposalId, bool _support)`: Members vote on funding proposals.
 *   - `executeFundingProposal(uint256 _proposalId)`: Governance members execute approved funding proposals, sending ETH from the treasury.
 *   - `distributeArtistRoyalties(uint256 _artId)`: Distribute royalties to the original artist upon secondary sales (if implemented).
 *   - `withdrawTreasury(address _recipient, uint256 _amount)`: Governance function to withdraw funds from the treasury for collective purposes (e.g., operating costs, marketing).
 *   - `getTreasuryBalance()`: View the current balance of the collective treasury.
 *
 * **5. Utility & Helper Functions:**
 *   - `pauseContract()`: Governance function to pause the contract in case of emergency.
 *   - `unpauseContract()`: Governance function to unpause the contract.
 *   - `isMember(address _artist)`: Check if an address is a member of the collective.
 *   - `getMemberCount()`: Get the total number of members.
 *   - `getArtCount()`: Get the total number of curated artworks.
 *   - `getExhibitionCount()`: Get the total number of exhibitions.
 *   - `getProposalCount()`: Get the total number of proposals (all types).
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/governance/utils/Votes.sol";

contract DecentralizedArtCollective is ERC721, Ownable, Pausable, Votes {
    using Counters for Counters.Counter;
    Counters.Counter private _artIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _exhibitionIdCounter;
    Counters.Counter private _memberCounter;

    // --- Enums & Structs ---
    enum ProposalStatus { Pending, Active, Approved, Rejected, Executed }
    enum ProposalType { Governance, ArtCuration, Exhibition, Funding }
    enum ArtStatus { Proposed, Curated, Exhibited, Sold }
    enum ExhibitionStatus { Proposed, Scheduled, Active, Ended }

    struct ArtProposal {
        uint256 proposalId;
        ProposalStatus status;
        ProposalType proposalType;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 royaltyPercentage; // Percentage for artist on secondary sales
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct Art {
        uint256 artId;
        address artist;
        ArtStatus status;
        string title;
        string description;
        string ipfsHash;
        uint256 royaltyPercentage;
        uint256 price; // Price in wei
    }

    struct GovernanceProposal {
        uint256 proposalId;
        ProposalStatus status;
        ProposalType proposalType;
        address proposer;
        string title;
        string description;
        bytes calldataData; // Encoded function call data
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct ExhibitionProposal {
        uint256 proposalId;
        ProposalStatus status;
        ProposalType proposalType;
        address proposer;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct Exhibition {
        uint256 exhibitionId;
        ExhibitionStatus status;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256[] artIds; // Array of Art IDs in this exhibition
    }

    struct FundingProposal {
        uint256 proposalId;
        ProposalStatus status;
        ProposalType proposalType;
        address proposer;
        string title;
        string description;
        address recipient;
        uint256 amount; // Amount in wei
        uint256 votesFor;
        uint256 votesAgainst;
    }

    // --- State Variables ---
    mapping(address => bool) public isCollectiveMember;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => Art) public artworks;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => FundingProposal) public fundingProposals;
    mapping(address => address) public voteDelegations; // Delegate voting power

    uint256 public governanceThreshold = 50; // Percentage of votes needed for approval (e.g., 50% for simple majority)
    uint256 public membershipFee = 0.1 ether; // Optional membership fee

    // --- Events ---
    event MembershipRequested(address artist);
    event MembershipApproved(address artist);
    event MembershipRevoked(address artist);
    event VoteDelegated(address delegator, address delegate);
    event GovernanceProposalCreated(uint256 proposalId, string title, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool support);
    event ArtNFTMinted(uint256 artId, address artist, uint256 tokenId);
    event ArtMetadataUpdated(uint256 artId, string newIpfsHash);
    event ArtNFTBurned(uint256 artId);
    event ExhibitionProposalCreated(uint256 proposalId, string title, address proposer);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool support);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 artId);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event ArtPurchased(uint256 artId, address buyer, uint256 price);
    event ArtPriceSet(uint256 artId, uint256 price);
    event DonationReceived(address donor, uint256 amount);
    event FundingProposalCreated(uint256 proposalId, string title, address proposer);
    event FundingProposalVoted(uint256 proposalId, address voter, bool support);
    event FundingProposalExecuted(uint256 proposalId, address recipient, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();
    event GovernanceThresholdChanged(uint256 newThreshold);


    // --- Modifiers ---
    modifier onlyMember() {
        require(isCollectiveMember[msg.sender], "Only collective members allowed.");
        _;
    }

    modifier onlyGovernance() {
        // For simplicity, owner is governance in this example. In a real DAAC, governance would be more decentralized.
        require(msg.sender == owner(), "Only governance members allowed."); // Replace with more robust governance check in production
        _;
    }

    modifier validProposal(uint256 _proposalId, ProposalType _proposalType) {
        ProposalStatus status;
        ProposalType type;

        if (_proposalType == ProposalType.Governance) {
            require(_proposalId <= _proposalIdCounter.current(), "Governance proposal does not exist.");
            status = governanceProposals[_proposalId].status;
            type = governanceProposals[_proposalId].proposalType;
        } else if (_proposalType == ProposalType.ArtCuration) {
            require(_proposalId <= _artIdCounter.current(), "Art proposal does not exist.");
            status = artProposals[_proposalId].status;
            type = artProposals[_proposalId].proposalType;
        } else if (_proposalType == ProposalType.Exhibition) {
             require(_proposalId <= _exhibitionIdCounter.current(), "Exhibition proposal does not exist.");
             status = exhibitionProposals[_proposalId].status;
             type = exhibitionProposals[_proposalId].proposalType;
        } else if (_proposalType == ProposalType.Funding) {
            require(_proposalId <= _proposalIdCounter.current(), "Funding proposal does not exist.");
            status = fundingProposals[_proposalId].status;
            type = fundingProposals[_proposalId].proposalType;
        } else {
            revert("Invalid proposal type.");
        }

        require(status == ProposalStatus.Active, "Proposal is not active.");
        require(type == _proposalType, "Proposal type mismatch.");
        _;
    }

    modifier proposalExists(uint256 _proposalId, ProposalType _proposalType) {
        bool exists = false;
        if (_proposalType == ProposalType.Governance) {
            exists = _proposalId <= _proposalIdCounter.current() && governanceProposals[_proposalId].proposalType == ProposalType.Governance;
        } else if (_proposalType == ProposalType.ArtCuration) {
            exists = _proposalId <= _artIdCounter.current() && artProposals[_proposalId].proposalType == ProposalType.ArtCuration;
        } else if (_proposalType == ProposalType.Exhibition) {
            exists = _proposalId <= _exhibitionIdCounter.current() && exhibitionProposals[_proposalId].proposalType == ProposalType.Exhibition;
        } else if (_proposalType == ProposalType.Funding) {
            exists = _proposalId <= _proposalIdCounter.current() && fundingProposals[_proposalId].proposalType == ProposalType.Funding;
        }
        require(exists, "Proposal does not exist or type mismatch.");
        _;
    }

    modifier notPaused() {
        require(!paused(), "Contract is paused.");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("DecentralizedArtNFT", "DAANFT") Votes("DAAC Governance") {
        // Optionally set initial governance members here, or leave it to owner to bootstrap.
        // For simplicity, the contract deployer is the initial governance.
        _mint(owner(), 1); // Mint initial governance token to owner (for voting rights)
        _setVotingPower(owner(), 1);
    }

    // --- 1. Membership & Governance Functions ---

    /// @notice Request to join the collective. May require a membership fee in the future.
    function requestMembership() external payable notPaused {
        // Optional: require(msg.value >= membershipFee, "Membership fee required.");
        emit MembershipRequested(msg.sender);
        // Membership requests need to be approved by governance in `approveMembership`.
    }

    /// @notice Approve a membership request. Only callable by governance members.
    /// @param _artist The address of the artist to approve.
    function approveMembership(address _artist) external onlyGovernance notPaused {
        require(!isCollectiveMember[_artist], "Artist is already a member.");
        isCollectiveMember[_artist] = true;
        _memberCounter.increment();
        _mint(_artist, _memberCounter.current()); // Mint membership NFT (optional, can be used for identity/access)
        emit MembershipApproved(_artist);
    }

    /// @notice Revoke membership from an artist. Only callable by governance members.
    /// @param _artist The address of the artist to revoke membership from.
    function revokeMembership(address _artist) external onlyGovernance notPaused {
        require(isCollectiveMember[_artist], "Artist is not a member.");
        isCollectiveMember[_artist] = false;
        // Consider burning membership NFT or transferring it to a null address.
        emit MembershipRevoked(_artist);
    }

    /// @notice Delegate voting power to another member.
    /// @param _delegate The address to delegate voting power to.
    function delegateVotePower(address _delegate) external onlyMember notPaused {
        require(isCollectiveMember[_delegate], "Delegate must be a collective member.");
        voteDelegations[msg.sender] = _delegate;
        _delegateVotingPower(msg.sender, _delegate); // OpenZeppelin Votes contract function
        emit VoteDelegated(msg.sender, _delegate);
    }

    /// @notice Create a governance proposal to change contract parameters or rules. Only callable by governance members.
    /// @param _title Title of the proposal.
    /// @param _description Detailed description of the proposal.
    /// @param _calldata Encoded function call data to be executed if the proposal passes.
    function createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata) external onlyGovernance notPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            status: ProposalStatus.Active,
            proposalType: ProposalType.Governance,
            proposer: msg.sender,
            title: _title,
            description: _description,
            calldataData: _calldata,
            votesFor: 0,
            votesAgainst: 0
        });
        emit GovernanceProposalCreated(proposalId, _title, msg.sender);
    }

    /// @notice Vote on a governance proposal. Only callable by collective members.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external onlyMember notPaused validProposal(_proposalId, ProposalType.Governance) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active.");
        require(getVotes(msg.sender) > 0, "You do not have voting power."); // Ensure member has voting power

        if (_support) {
            proposal.votesFor += getVotes(msg.sender);
        } else {
            proposal.votesAgainst += getVotes(msg.sender);
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
        _checkProposalOutcome(_proposalId, ProposalType.Governance);
    }

    /// @notice Execute an approved governance proposal. Only callable by governance members.
    /// @param _proposalId The ID of the governance proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId) external onlyGovernance notPaused proposalExists(_proposalId, ProposalType.Governance) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Approved, "Proposal must be approved to execute.");
        proposal.status = ProposalStatus.Executed;
        (bool success, ) = address(this).call(proposal.calldataData); // Execute the encoded function call
        require(success, "Governance proposal execution failed.");
        emit GovernanceProposalExecuted(_proposalId);
    }

    /// @notice Get the status of a governance proposal.
    /// @param _proposalId The ID of the governance proposal.
    /// @return The status of the proposal.
    function getGovernanceProposalStatus(uint256 _proposalId) external view proposalExists(_proposalId, ProposalType.Governance) returns (ProposalStatus) {
        return governanceProposals[_proposalId].status;
    }

    /// @notice Set the governance threshold (percentage of votes needed for proposal approval). Only callable by governance members.
    /// @param _newThreshold The new governance threshold percentage (e.g., 50 for 50%).
    function setGovernanceThreshold(uint256 _newThreshold) external onlyGovernance notPaused {
        require(_newThreshold <= 100, "Threshold must be a percentage (<= 100).");
        governanceThreshold = _newThreshold;
        emit GovernanceThresholdChanged(_newThreshold);
    }


    // --- 2. Art Submission & Curation Functions ---

    /// @notice Submit an art proposal for curation. Only callable by collective members.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork's metadata.
    /// @param _royaltyPercentage Royalty percentage for the artist on secondary sales.
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash, uint256 _royaltyPercentage) external onlyMember notPaused {
        require(_royaltyPercentage <= 100, "Royalty percentage must be <= 100.");
        _artIdCounter.increment();
        uint256 proposalId = _artIdCounter.current();
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            status: ProposalStatus.Active,
            proposalType: ProposalType.ArtCuration,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            royaltyPercentage: _royaltyPercentage,
            votesFor: 0,
            votesAgainst: 0
        });
        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    /// @notice Vote on an art proposal. Only callable by collective members.
    /// @param _proposalId The ID of the art proposal.
    /// @param _support True to vote in favor (curate), false to vote against.
    function voteOnArtProposal(uint256 _proposalId, bool _support) external onlyMember notPaused validProposal(_proposalId, ProposalType.ArtCuration) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active.");
        require(getVotes(msg.sender) > 0, "You do not have voting power."); // Ensure member has voting power

        if (_support) {
            proposal.votesFor += getVotes(msg.sender);
        } else {
            proposal.votesAgainst += getVotes(msg.sender);
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _support);
        _checkProposalOutcome(_proposalId, ProposalType.ArtCuration);
    }

    /// @notice Mint an NFT for an approved art proposal. Only callable by governance members after art proposal is approved.
    /// @param _proposalId The ID of the approved art proposal.
    function mintArtNFT(uint256 _proposalId) external onlyGovernance notPaused proposalExists(_proposalId, ProposalType.ArtCuration) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.status == ProposalStatus.Approved, "Art proposal must be approved to mint NFT.");
        _artIdCounter.increment(); // Use a different counter for actual artworks, or reuse proposal ID if proposal and art ID are the same.
        uint256 artId = _artIdCounter.current();
        artworks[artId] = Art({
            artId: artId,
            artist: proposal.proposer,
            status: ArtStatus.Curated,
            title: proposal.title,
            description: proposal.description,
            ipfsHash: proposal.ipfsHash,
            royaltyPercentage: proposal.royaltyPercentage,
            price: 0 // Initial price is 0, artist can set later.
        });
        _mint(proposal.proposer, artId); // Mint ERC721 NFT to the artist
        artProposals[_proposalId].status = ProposalStatus.Executed; // Mark proposal as executed (NFT minted)
        emit ArtNFTMinted(artId, proposal.proposer, artId);
    }

    /// @notice Set the metadata (IPFS hash) of a curated artwork. Only callable by the original artist.
    /// @param _artId The ID of the artwork.
    /// @param _newIpfsHash The new IPFS hash for the artwork's metadata.
    function setArtMetadata(uint256 _artId, string memory _newIpfsHash) external onlyMember notPaused {
        require(artworks[_artId].artist == msg.sender, "Only the original artist can set metadata.");
        artworks[_artId].ipfsHash = _newIpfsHash;
        emit ArtMetadataUpdated(_artId, _newIpfsHash);
    }

    /// @notice Burn an NFT of a curated artwork. Only callable by governance members in exceptional cases.
    /// @param _artId The ID of the artwork NFT to burn.
    function burnArtNFT(uint256 _artId) external onlyGovernance notPaused {
        require(artworks[_artId].status != ArtStatus.Sold, "Cannot burn a sold artwork."); // Prevent burning sold art
        _burn(_artId);
        artworks[_artId].status = ArtStatus.Burned; // Update art status
        emit ArtNFTBurned(_artId);
    }

    /// @notice Get details of a specific artwork.
    /// @param _artId The ID of the artwork.
    /// @return Art details struct.
    function getArtDetails(uint256 _artId) external view returns (Art memory) {
        require(_artId <= _artIdCounter.current(), "Artwork does not exist.");
        return artworks[_artId];
    }

    /// @notice Get details of a specific art proposal.
    /// @param _proposalId The ID of the art proposal.
    /// @return ArtProposal details struct.
    function getArtProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId, ProposalType.ArtCuration) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }


    // --- 3. Exhibition & Marketplace Functions ---

    /// @notice Create an exhibition proposal. Only callable by governance members.
    /// @param _title Title of the exhibition.
    /// @param _description Description of the exhibition.
    /// @param _startTime Unix timestamp for the exhibition start time.
    /// @param _endTime Unix timestamp for the exhibition end time.
    function createExhibitionProposal(string memory _title, string memory _description, uint256 _startTime, uint256 _endTime) external onlyGovernance notPaused {
        require(_startTime < _endTime, "Exhibition start time must be before end time.");
        _exhibitionIdCounter.increment();
        uint256 proposalId = _exhibitionIdCounter.current();
        exhibitionProposals[proposalId] = ExhibitionProposal({
            proposalId: proposalId,
            status: ProposalStatus.Active,
            proposalType: ProposalType.Exhibition,
            proposer: msg.sender,
            title: _title,
            description: _description,
            startTime: _startTime,
            endTime: _endTime,
            votesFor: 0,
            votesAgainst: 0
        });
        emit ExhibitionProposalCreated(proposalId, _title, msg.sender);
    }

    /// @notice Vote on an exhibition proposal. Only callable by collective members.
    /// @param _proposalId The ID of the exhibition proposal.
    /// @param _support True to vote in favor (approve exhibition), false to vote against.
    function voteOnExhibitionProposal(uint256 _proposalId, bool _support) external onlyMember notPaused validProposal(_proposalId, ProposalType.Exhibition) {
        ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active.");
        require(getVotes(msg.sender) > 0, "You do not have voting power."); // Ensure member has voting power

        if (_support) {
            proposal.votesFor += getVotes(msg.sender);
        } else {
            proposal.votesAgainst += getVotes(msg.sender);
        }
        emit ExhibitionProposalVoted(_proposalId, msg.sender, _support);
        _checkProposalOutcome(_proposalId, ProposalType.Exhibition);
    }

    /// @notice Add curated art to an approved exhibition. Only callable by governance members.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _artId The ID of the artwork to add.
    function addArtToExhibition(uint256 _exhibitionId, uint256 _artId) external onlyGovernance notPaused {
        require(exhibitions[_exhibitionId].status == ExhibitionStatus.Scheduled || exhibitions[_exhibitionId].status == ExhibitionStatus.Active, "Exhibition must be scheduled or active.");
        require(artworks[_artId].status == ArtStatus.Curated || artworks[_artId].status == ArtStatus.Exhibited, "Artwork must be curated to be added to exhibition.");
        exhibitions[_exhibitionId].artIds.push(_artId);
        artworks[_artId].status = ArtStatus.Exhibited; // Update art status to exhibited
        emit ArtAddedToExhibition(_exhibitionId, _artId);
    }

    /// @notice Remove art from an exhibition. Only callable by governance members.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _artId The ID of the artwork to remove.
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artId) external onlyGovernance notPaused {
        require(exhibitions[_exhibitionId].status == ExhibitionStatus.Scheduled || exhibitions[_exhibitionId].status == ExhibitionStatus.Active, "Exhibition must be scheduled or active.");
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        for (uint256 i = 0; i < exhibition.artIds.length; i++) {
            if (exhibition.artIds[i] == _artId) {
                exhibition.artIds[i] = exhibition.artIds[exhibition.artIds.length - 1];
                exhibition.artIds.pop();
                artworks[_artId].status = ArtStatus.Curated; // Revert art status back to curated
                emit ArtRemovedFromExhibition(_exhibitionId, _artId);
                return;
            }
        }
        revert("Artwork not found in exhibition.");
    }

    /// @notice Start an exhibition. Only callable by governance members.
    /// @param _exhibitionId The ID of the exhibition to start.
    function startExhibition(uint256 _exhibitionId) external onlyGovernance notPaused {
        require(exhibitions[_exhibitionId].status == ExhibitionStatus.Scheduled, "Exhibition must be scheduled to start.");
        exhibitions[_exhibitionId].status = ExhibitionStatus.Active;
        emit ExhibitionStarted(_exhibitionId);
    }

    /// @notice End an exhibition. Only callable by governance members.
    /// @param _exhibitionId The ID of the exhibition to end.
    function endExhibition(uint256 _exhibitionId) external onlyGovernance notPaused {
        require(exhibitions[_exhibitionId].status == ExhibitionStatus.Active, "Exhibition must be active to end.");
        exhibitions[_exhibitionId].status = ExhibitionStatus.Ended;
        emit ExhibitionEnded(_exhibitionId);
    }

    /// @notice Purchase an artwork NFT from the collective marketplace.
    /// @param _artId The ID of the artwork NFT to purchase.
    function purchaseArt(uint256 _artId) external payable notPaused {
        require(artworks[_artId].status == ArtStatus.Exhibited || artworks[_artId].status == ArtStatus.Curated, "Artwork must be curated or exhibited to be purchased.");
        require(artworks[_artId].price > 0, "Artwork is not for sale or price is not set.");
        require(msg.value >= artworks[_artId].price, "Insufficient funds sent for purchase.");

        uint256 price = artworks[_artId].price;
        address artist = artworks[_artId].artist;

        artworks[_artId].status = ArtStatus.Sold; // Update art status to sold

        // Transfer NFT to buyer
        _transfer(artist, msg.sender, _artId);

        // Transfer funds to artist (consider royalty distribution logic here if secondary sales are implemented)
        (bool artistTransferSuccess, ) = payable(artist).call{value: price * (100 - artworks[_artId].royaltyPercentage) / 100}(""); // Distribute artist share
        (bool collectiveTransferSuccess, ) = payable(owner()).call{value: price * artworks[_artId].royaltyPercentage / 100}(""); // Send royalty to collective treasury (example - owner is treasury in this simple case)

        require(artistTransferSuccess && collectiveTransferSuccess, "Fund transfer failed during purchase.");

        emit ArtPurchased(_artId, msg.sender, price);

        // Refund any extra ETH sent
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /// @notice Set the price of a curated artwork for sale. Only callable by the original artist (governance approval could be added).
    /// @param _artId The ID of the artwork.
    /// @param _price The price in wei.
    function setArtPrice(uint256 _artId, uint256 _price) external onlyMember notPaused {
        require(artworks[_artId].artist == msg.sender, "Only the original artist can set the price.");
        artworks[_artId].price = _price;
        emit ArtPriceSet(_artId, _price);
    }

    /// @notice Get details of an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @return Exhibition details struct.
    function getExhibitionDetails(uint256 _exhibitionId) external view proposalExists(_exhibitionId, ProposalType.Exhibition) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }


    // --- 4. Treasury & Revenue Sharing Functions ---

    /// @notice Donate ETH to the collective treasury. Anyone can donate.
    function donateToCollective() external payable notPaused {
        emit DonationReceived(msg.sender, msg.value);
    }

    /// @notice Create a funding proposal to allocate treasury funds. Only callable by governance members.
    /// @param _title Title of the funding proposal.
    /// @param _description Description of the funding proposal.
    /// @param _recipient Address to receive the funds.
    /// @param _amount Amount of ETH to allocate (in wei).
    function createFundingProposal(string memory _title, string memory _description, address _recipient, uint256 _amount) external onlyGovernance notPaused {
        require(_amount > 0, "Funding amount must be greater than 0.");
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        fundingProposals[proposalId] = FundingProposal({
            proposalId: proposalId,
            status: ProposalStatus.Active,
            proposalType: ProposalType.Funding,
            proposer: msg.sender,
            title: _title,
            description: _description,
            recipient: _recipient,
            amount: _amount,
            votesFor: 0,
            votesAgainst: 0
        });
        emit FundingProposalCreated(proposalId, _title, msg.sender);
    }

    /// @notice Vote on a funding proposal. Only callable by collective members.
    /// @param _proposalId The ID of the funding proposal.
    /// @param _support True to vote in favor (approve funding), false to vote against.
    function voteOnFundingProposal(uint256 _proposalId, bool _support) external onlyMember notPaused validProposal(_proposalId, ProposalType.Funding) {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active.");
        require(getVotes(msg.sender) > 0, "You do not have voting power."); // Ensure member has voting power

        if (_support) {
            proposal.votesFor += getVotes(msg.sender);
        } else {
            proposal.votesAgainst += getVotes(msg.sender);
        }
        emit FundingProposalVoted(_proposalId, msg.sender, _support);
        _checkProposalOutcome(_proposalId, ProposalType.Funding);
    }

    /// @notice Execute an approved funding proposal, sending ETH from the treasury. Only callable by governance members.
    /// @param _proposalId The ID of the funding proposal to execute.
    function executeFundingProposal(uint256 _proposalId) external onlyGovernance notPaused proposalExists(_proposalId, ProposalType.Funding) {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        require(proposal.status == ProposalStatus.Approved, "Funding proposal must be approved to execute.");
        require(address(this).balance >= proposal.amount, "Insufficient treasury balance for funding proposal.");
        proposal.status = ProposalStatus.Executed;
        (bool success, ) = payable(proposal.recipient).call{value: proposal.amount}("");
        require(success, "Funding proposal execution failed.");
        emit FundingProposalExecuted(_proposalId, proposal.recipient, proposal.amount);
    }

    /// @notice Distribute royalties to the original artist upon secondary sales. (Example - not fully implemented in this basic contract).
    /// @param _artId The ID of the sold artwork.
    function distributeArtistRoyalties(uint256 _artId) external onlyGovernance notPaused {
        // In a real implementation, this would be triggered on secondary market sales.
        // This is a simplified placeholder.
        // Example logic: Retrieve sale price from event logs of a marketplace, calculate royalty, transfer to artist.
        // This example assumes royalties are handled during primary sales in `purchaseArt`.
        // For secondary sales, integration with a royalty registry or marketplace is needed.
        revert("Royalty distribution for secondary sales not fully implemented in this example.");
    }

    /// @notice Withdraw funds from the treasury for collective purposes. Only callable by governance members.
    /// @param _recipient Address to receive the withdrawn funds.
    /// @param _amount Amount of ETH to withdraw (in wei).
    function withdrawTreasury(address _recipient, uint256 _amount) external onlyGovernance notPaused {
        require(_amount > 0, "Withdrawal amount must be greater than 0.");
        require(address(this).balance >= _amount, "Insufficient treasury balance for withdrawal.");
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Treasury withdrawal failed.");
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /// @notice Get the current balance of the collective treasury.
    /// @return The treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // --- 5. Utility & Helper Functions ---

    /// @notice Pause the contract functionality in case of emergency. Only callable by governance members.
    function pauseContract() external onlyGovernance notPaused {
        _pause();
        emit ContractPaused();
    }

    /// @notice Unpause the contract functionality. Only callable by governance members.
    function unpauseContract() external onlyGovernance whenPaused {
        _unpause();
        emit ContractUnpaused();
    }

    /// @notice Check if an address is a member of the collective.
    /// @param _artist The address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _artist) external view returns (bool) {
        return isCollectiveMember[_artist];
    }

    /// @notice Get the total number of collective members.
    /// @return The member count.
    function getMemberCount() external view returns (uint256) {
        return _memberCounter.current();
    }

    /// @notice Get the total number of curated artworks.
    /// @return The artwork count.
    function getArtCount() external view returns (uint256) {
        return _artIdCounter.current();
    }

    /// @notice Get the total number of exhibitions created.
    /// @return The exhibition count.
    function getExhibitionCount() external view returns (uint256) {
        return _exhibitionIdCounter.current();
    }

    /// @notice Get the total number of proposals created (all types).
    /// @return The proposal count.
    function getProposalCount() external view returns (uint256) {
        return _proposalIdCounter.current() + _artIdCounter.current() + _exhibitionIdCounter.current(); // Sum of all proposal counters
    }

    // --- Internal Helper Functions ---

    /// @dev Check if a proposal has reached the governance threshold and update its status.
    /// @param _proposalId The ID of the proposal.
    /// @param _proposalType The type of the proposal.
    function _checkProposalOutcome(uint256 _proposalId, ProposalType _proposalType) internal {
        uint256 votesFor;
        uint256 votesAgainst;

        if (_proposalType == ProposalType.Governance) {
            votesFor = governanceProposals[_proposalId].votesFor;
            votesAgainst = governanceProposals[_proposalId].votesAgainst;
        } else if (_proposalType == ProposalType.ArtCuration) {
            votesFor = artProposals[_proposalId].votesFor;
            votesAgainst = artProposals[_proposalId].votesAgainst;
        } else if (_proposalType == ProposalType.Exhibition) {
            votesFor = exhibitionProposals[_proposalId].votesFor;
            votesAgainst = exhibitionProposals[_proposalId].votesAgainst;
        } else if (_proposalType == ProposalType.Funding) {
            votesFor = fundingProposals[_proposalId].votesFor;
            votesAgainst = fundingProposals[_proposalId].votesAgainst;
        } else {
            return; // Invalid proposal type
        }

        uint256 totalVotes = votesFor + votesAgainst;
        if (totalVotes > 0) {
            uint256 percentageFor = (votesFor * 100) / totalVotes;
            if (percentageFor >= governanceThreshold) {
                if (_proposalType == ProposalType.Governance) {
                    governanceProposals[_proposalId].status = ProposalStatus.Approved;
                } else if (_proposalType == ProposalType.ArtCuration) {
                    artProposals[_proposalId].status = ProposalStatus.Approved;
                } else if (_proposalType == ProposalType.Exhibition) {
                    exhibitionProposals[_proposalId].status = ProposalStatus.Approved;
                    exhibitions[_exhibitionIdCounter.current()] = Exhibition({ // Create exhibition struct upon approval
                        exhibitionId: _exhibitionIdCounter.current(),
                        status: ExhibitionStatus.Scheduled,
                        title: exhibitionProposals[_proposalId].title,
                        description: exhibitionProposals[_proposalId].description,
                        startTime: exhibitionProposals[_proposalId].startTime,
                        endTime: exhibitionProposals[_proposalId].endTime,
                        artIds: new uint256[](0) // Initialize with empty art array
                    });
                } else if (_proposalType == ProposalType.Funding) {
                    fundingProposals[_proposalId].status = ProposalStatus.Approved;
                }
                emit GovernanceProposalStatusUpdated(_proposalId, ProposalStatus.Approved); // Generic event for proposal status change
            } else {
                if (_proposalType == ProposalType.Governance) {
                    governanceProposals[_proposalId].status = ProposalStatus.Rejected;
                } else if (_proposalType == ProposalType.ArtCuration) {
                    artProposals[_proposalId].status = ProposalStatus.Rejected;
                } else if (_proposalType == ProposalType.Exhibition) {
                    exhibitionProposals[_proposalId].status = ProposalStatus.Rejected;
                } else if (_proposalType == ProposalType.Funding) {
                    fundingProposals[_proposalId].status = ProposalStatus.Rejected;
                }
                emit GovernanceProposalStatusUpdated(_proposalId, ProposalStatus.Rejected); // Generic event for proposal status change
            }
        }
    }

    event GovernanceProposalStatusUpdated(uint256 proposalId, ProposalStatus newStatus);
}
```