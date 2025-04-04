```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Not for Production)
 * @dev A smart contract for a decentralized art collective, enabling artists to submit, curators to vote, and collectors to purchase digital art.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Functionality:**
 *    - **submitArtProposal(string _title, string _description, string _ipfsHash, uint256 _initialPrice):** Artists propose new artwork for the collective.
 *    - **voteOnArtProposal(uint256 _proposalId, bool _approve):** Curators vote on pending art proposals.
 *    - **purchaseArt(uint256 _artworkId):** Collectors purchase approved artwork.
 *    - **viewArtDetails(uint256 _artworkId):** Publicly view details of an artwork.
 *    - **viewProposalDetails(uint256 _proposalId):** Publicly view details of an art proposal.
 *
 * **2. Curator & DAO Management:**
 *    - **becomeCurator():**  Request to become a curator of the collective (permissioned initially).
 *    - **addCurator(address _curatorAddress):** Owner/Admin function to approve curator requests.
 *    - **removeCurator(address _curatorAddress):** Owner/Admin function to remove a curator.
 *    - **isCurator(address _address):** Check if an address is a curator.
 *    - **setCuratorVotingThreshold(uint256 _threshold):** Owner/Admin to set the minimum votes needed for proposal approval.
 *    - **proposeCuratorVotingThresholdChange(uint256 _newThreshold):** Curators propose changes to the voting threshold (DAO governance).
 *    - **voteOnThresholdChangeProposal(uint256 _proposalId, bool _approve):** Curators vote on voting threshold change proposals.
 *
 * **3. Artist & Royalty Management:**
 *    - **claimArtistRoyalties(uint256 _artworkId):** Artists claim their earned royalties from artwork sales.
 *    - **setArtistRoyaltyPercentage(uint256 _percentage):** Owner/Admin to set the royalty percentage for artists.
 *    - **proposeRoyaltyPercentageChange(uint256 _newPercentage):** Curators propose changes to the royalty percentage (DAO governance).
 *    - **voteOnRoyaltyPercentageChangeProposal(uint256 _proposalId, bool _approve):** Curators vote on royalty percentage change proposals.
 *
 * **4. Gallery & Platform Management:**
 *    - **setGalleryName(string _name):** Owner/Admin to set the name of the decentralized gallery.
 *    - **setPlatformFeePercentage(uint256 _percentage):** Owner/Admin to set a platform fee on artwork sales.
 *    - **withdrawPlatformFees():** Owner/Admin to withdraw accumulated platform fees.
 *    - **pauseContract():** Owner/Admin to pause core functionalities of the contract for emergency.
 *    - **unpauseContract():** Owner/Admin to resume core functionalities of the contract.
 *
 * **Advanced Concepts Used:**
 *    - **Decentralized Governance (Limited):**  Curator voting for art approval and parameter changes (voting threshold, royalty).
 *    - **NFT-like Structure (Simplified):**  Artwork represented as structs with metadata, managed within the contract (could be extended to real NFTs).
 *    - **Royalty Distribution:**  Automatic royalty tracking and claim mechanism for artists.
 *    - **Platform Fees:**  Mechanism to collect platform fees for maintenance or development.
 *    - **Pausing Mechanism:**  Emergency control for contract owner.
 *    - **Proposal System:**  Structured approach for art submissions and parameter changes.
 */
pragma solidity ^0.8.0;

contract DecentralizedArtCollective {
    string public galleryName = "Decentralized Art Gallery"; // Name of the gallery
    address public owner; // Contract owner (initially the deployer)
    uint256 public platformFeePercentage = 5; // Platform fee percentage (e.g., 5% of sale price)
    uint256 public artistRoyaltyPercentage = 10; // Royalty percentage for artists (e.g., 10% of sale price)
    uint256 public curatorVotingThreshold = 2; // Minimum number of curator votes needed for approval

    bool public paused = false; // Contract paused state

    mapping(address => bool) public curators; // List of curators
    address[] public curatorList; // Array to easily iterate through curators

    struct ArtProposal {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 initialPrice;
        uint256 voteCount;
        mapping(address => bool) votes; // Curators who have voted
        bool approved;
        bool active; // Proposal is still open for voting
    }
    ArtProposal[] public artProposals;
    uint256 public proposalCounter = 0;

    struct Artwork {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 price;
        uint256 salesCount;
    }
    Artwork[] public artworks;
    uint256 public artworkCounter = 0;
    mapping(uint256 => uint256) public artistRoyaltiesDue; // artworkId => royalty amount

    struct ParameterChangeProposal {
        uint256 id;
        address proposer;
        string description;
        uint256 proposedValue; // Generic value, type determined by context
        uint256 voteCount;
        mapping(address => bool) votes;
        bool approved;
        bool executed; // If the change has been applied
        ProposalType proposalType;
        bool active;
    }
    enum ProposalType { VOTING_THRESHOLD, ROYALTY_PERCENTAGE }
    ParameterChangeProposal[] public parameterChangeProposals;
    uint256 public parameterProposalCounter = 0;

    uint256 public platformFeesCollected = 0;

    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address curator, bool approved);
    event ArtProposalApproved(uint256 proposalId, uint256 artworkId);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price);
    event CuratorAdded(address curatorAddress);
    event CuratorRemoved(address curatorAddress);
    event CuratorBecame(address curatorAddress);
    event PlatformFeePercentageChanged(uint256 newPercentage);
    event ArtistRoyaltyPercentageChanged(uint256 newPercentage);
    event VotingThresholdChanged(uint256 newThreshold);
    event ParameterChangeProposalSubmitted(uint256 proposalId, ProposalType proposalType, string description, uint256 proposedValue);
    event ParameterChangeProposalVoted(uint256 proposalId, address curator, bool approved);
    event ParameterChangeProposalExecuted(uint256 proposalId, ProposalType proposalType, uint256 newValue);
    event ContractPaused();
    event ContractUnpaused();
    event PlatformFeesWithdrawn(uint256 amount, address withdrawnBy);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Only curators can call this function.");
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

    constructor() {
        owner = msg.sender;
        curators[owner] = true; // Owner is also initially a curator
        curatorList.push(owner);
    }

    // ------------------------- Core Functionality -------------------------

    /// @dev Artists submit art proposals to the collective.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork's digital file.
    /// @param _initialPrice Initial price of the artwork in wei.
    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _initialPrice
    ) external whenNotPaused {
        require(_initialPrice > 0, "Initial price must be greater than zero.");
        artProposals.push(
            ArtProposal({
                id: proposalCounter,
                artist: msg.sender,
                title: _title,
                description: _description,
                ipfsHash: _ipfsHash,
                initialPrice: _initialPrice,
                voteCount: 0,
                approved: false,
                active: true
            })
        );
        emit ArtProposalSubmitted(proposalCounter, msg.sender, _title);
        proposalCounter++;
    }

    /// @dev Curators vote on pending art proposals.
    /// @param _proposalId ID of the art proposal to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnArtProposal(uint256 _proposalId, bool _approve) external onlyCurator whenNotPaused {
        require(_proposalId < artProposals.length, "Invalid proposal ID.");
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.active, "Proposal is not active.");
        require(!proposal.votes[msg.sender], "Curator has already voted on this proposal.");

        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.voteCount++;
        }

        emit ArtProposalVoted(_proposalId, msg.sender, _approve);

        if (proposal.voteCount >= curatorVotingThreshold && !proposal.approved) {
            proposal.approved = true;
            proposal.active = false; // Proposal is closed after approval

            artworks.push(
                Artwork({
                    id: artworkCounter,
                    artist: proposal.artist,
                    title: proposal.title,
                    description: proposal.description,
                    ipfsHash: proposal.ipfsHash,
                    price: proposal.initialPrice,
                    salesCount: 0
                })
            );
            emit ArtProposalApproved(_proposalId, artworkCounter);
            artworkCounter++;
        }
    }

    /// @dev Collectors purchase approved artwork.
    /// @param _artworkId ID of the artwork to purchase.
    function purchaseArt(uint256 _artworkId) external payable whenNotPaused {
        require(_artworkId < artworks.length, "Invalid artwork ID.");
        Artwork storage artwork = artworks[_artworkId];
        require(msg.value >= artwork.price, "Insufficient payment.");

        uint256 platformFee = (artwork.price * platformFeePercentage) / 100;
        uint256 artistPayment = artwork.price - platformFee;
        uint256 royaltyAmount = (artistPayment * artistRoyaltyPercentage) / 100; // Royalty based on artist's share after platform fee

        payable(artwork.artist).transfer(artistPayment - royaltyAmount); // Pay artist (excluding royalty)
        artistRoyaltiesDue[_artworkId] += royaltyAmount; // Track royalty due to artist
        platformFeesCollected += platformFee;

        artwork.salesCount++;
        emit ArtworkPurchased(_artworkId, msg.sender, artwork.price);

        // Return any excess payment
        if (msg.value > artwork.price) {
            payable(msg.sender).transfer(msg.value - artwork.price);
        }
    }

    /// @dev Publicly view details of an artwork.
    /// @param _artworkId ID of the artwork.
    /// @return title, description, ipfsHash, price, salesCount
    function viewArtDetails(uint256 _artworkId) external view returns (string memory title, string memory description, string memory ipfsHash, uint256 price, uint256 salesCount) {
        require(_artworkId < artworks.length, "Invalid artwork ID.");
        Artwork storage artwork = artworks[_artworkId];
        return (artwork.title, artwork.description, artwork.ipfsHash, artwork.price, artwork.salesCount);
    }

    /// @dev Publicly view details of an art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return artist, title, description, ipfsHash, initialPrice, voteCount, approved, active
    function viewProposalDetails(uint256 _proposalId) external view returns (address artist, string memory title, string memory description, string memory ipfsHash, uint256 initialPrice, uint256 voteCount, bool approved, bool active) {
        require(_proposalId < artProposals.length, "Invalid proposal ID.");
        ArtProposal storage proposal = artProposals[_proposalId];
        return (proposal.artist, proposal.title, proposal.description, proposal.ipfsHash, proposal.initialPrice, proposal.voteCount, proposal.approved, proposal.active);
    }


    // ------------------------- Curator & DAO Management -------------------------

    /// @dev Allows anyone to request to become a curator. Owner will need to approve.
    function becomeCurator() external whenNotPaused {
        // Basic request mechanism - can be expanded with voting/criteria later
        // For now, owner needs to manually approve via addCurator
        emit CuratorBecame(msg.sender);
        // In a real DAO, this could trigger a curator election process
    }

    /// @dev Owner adds a curator to the collective.
    /// @param _curatorAddress Address of the curator to add.
    function addCurator(address _curatorAddress) external onlyOwner whenNotPaused {
        require(!curators[_curatorAddress], "Address is already a curator.");
        curators[_curatorAddress] = true;
        curatorList.push(_curatorAddress);
        emit CuratorAdded(_curatorAddress);
    }

    /// @dev Owner removes a curator from the collective.
    /// @param _curatorAddress Address of the curator to remove.
    function removeCurator(address _curatorAddress) external onlyOwner whenNotPaused {
        require(curators[_curatorAddress], "Address is not a curator.");
        curators[_curatorAddress] = false;

        // Remove from curatorList array (more complex removal to maintain order, simpler for now)
        for (uint256 i = 0; i < curatorList.length; i++) {
            if (curatorList[i] == _curatorAddress) {
                curatorList[i] = curatorList[curatorList.length - 1];
                curatorList.pop();
                break;
            }
        }

        emit CuratorRemoved(_curatorAddress);
    }

    /// @dev Check if an address is a curator.
    /// @param _address Address to check.
    /// @return True if the address is a curator, false otherwise.
    function isCurator(address _address) external view returns (bool) {
        return curators[_address];
    }

    /// @dev Owner sets the curator voting threshold for art proposals.
    /// @param _threshold New voting threshold value.
    function setCuratorVotingThreshold(uint256 _threshold) external onlyOwner whenNotPaused {
        require(_threshold > 0, "Voting threshold must be greater than zero.");
        curatorVotingThreshold = _threshold;
        emit VotingThresholdChanged(_threshold);
    }

    /// @dev Curators propose a change to the curator voting threshold.
    /// @param _newThreshold The proposed new voting threshold value.
    function proposeCuratorVotingThresholdChange(uint256 _newThreshold) external onlyCurator whenNotPaused {
        require(_newThreshold > 0, "Voting threshold must be greater than zero.");
        parameterChangeProposals.push(
            ParameterChangeProposal({
                id: parameterProposalCounter,
                proposer: msg.sender,
                description: "Change Curator Voting Threshold",
                proposedValue: _newThreshold,
                voteCount: 0,
                approved: false,
                executed: false,
                proposalType: ProposalType.VOTING_THRESHOLD,
                active: true
            })
        );
        emit ParameterChangeProposalSubmitted(parameterProposalCounter, ProposalType.VOTING_THRESHOLD, "Change Curator Voting Threshold", _newThreshold);
        parameterProposalCounter++;
    }

    /// @dev Curators vote on a voting threshold change proposal.
    /// @param _proposalId ID of the parameter change proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnThresholdChangeProposal(uint256 _proposalId, bool _approve) external onlyCurator whenNotPaused {
        _voteOnParameterChangeProposal(_proposalId, _approve, ProposalType.VOTING_THRESHOLD);
    }


    // ------------------------- Artist & Royalty Management -------------------------

    /// @dev Artists claim their accumulated royalties for an artwork.
    /// @param _artworkId ID of the artwork.
    function claimArtistRoyalties(uint256 _artworkId) external whenNotPaused {
        require(_artworkId < artworks.length, "Invalid artwork ID.");
        require(artworks[_artworkId].artist == msg.sender, "Only artist of the artwork can claim royalties.");
        uint256 royaltyAmount = artistRoyaltiesDue[_artworkId];
        require(royaltyAmount > 0, "No royalties due for this artwork.");

        artistRoyaltiesDue[_artworkId] = 0; // Reset royalty balance
        payable(msg.sender).transfer(royaltyAmount);
    }

    /// @dev Owner sets the artist royalty percentage for artwork sales.
    /// @param _percentage New royalty percentage value.
    function setArtistRoyaltyPercentage(uint256 _percentage) external onlyOwner whenNotPaused {
        require(_percentage <= 100, "Royalty percentage cannot exceed 100%.");
        artistRoyaltyPercentage = _percentage;
        emit ArtistRoyaltyPercentageChanged(_percentage);
    }

    /// @dev Curators propose a change to the artist royalty percentage.
    /// @param _newPercentage The proposed new royalty percentage value.
    function proposeRoyaltyPercentageChange(uint256 _newPercentage) external onlyCurator whenNotPaused {
        require(_newPercentage <= 100, "Royalty percentage cannot exceed 100%.");
        parameterChangeProposals.push(
            ParameterChangeProposal({
                id: parameterProposalCounter,
                proposer: msg.sender,
                description: "Change Artist Royalty Percentage",
                proposedValue: _newPercentage,
                voteCount: 0,
                approved: false,
                executed: false,
                proposalType: ProposalType.ROYALTY_PERCENTAGE,
                active: true
            })
        );
        emit ParameterChangeProposalSubmitted(parameterProposalCounter, ProposalType.ROYALTY_PERCENTAGE, "Change Artist Royalty Percentage", _newPercentage);
        parameterProposalCounter++;
    }

    /// @dev Curators vote on a royalty percentage change proposal.
    /// @param _proposalId ID of the parameter change proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnRoyaltyPercentageChangeProposal(uint256 _proposalId, bool _approve) external onlyCurator whenNotPaused {
        _voteOnParameterChangeProposal(_proposalId, _approve, ProposalType.ROYALTY_PERCENTAGE);
    }


    // ------------------------- Gallery & Platform Management -------------------------

    /// @dev Owner sets the name of the decentralized gallery.
    /// @param _name New gallery name.
    function setGalleryName(string memory _name) external onlyOwner whenNotPaused {
        galleryName = _name;
    }

    /// @dev Owner sets the platform fee percentage for artwork sales.
    /// @param _percentage New platform fee percentage value.
    function setPlatformFeePercentage(uint256 _percentage) external onlyOwner whenNotPaused {
        require(_percentage <= 100, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _percentage;
        emit PlatformFeePercentageChanged(_percentage);
    }

    /// @dev Owner withdraws accumulated platform fees to their address.
    function withdrawPlatformFees() external onlyOwner whenNotPaused {
        require(platformFeesCollected > 0, "No platform fees collected to withdraw.");
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0; // Reset collected fees
        payable(owner).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw, owner);
    }

    /// @dev Owner pauses the core functionalities of the contract.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @dev Owner unpauses the core functionalities of the contract.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }


    // ------------------------- Internal Functions -------------------------

    /// @dev Internal function to handle voting on parameter change proposals.
    /// @param _proposalId ID of the proposal.
    /// @param _approve True to approve, false to reject.
    /// @param _proposalType Type of parameter change proposal.
    function _voteOnParameterChangeProposal(uint256 _proposalId, bool _approve, ProposalType _proposalType) internal onlyCurator {
        require(_proposalId < parameterChangeProposals.length, "Invalid parameter proposal ID.");
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(proposal.active, "Parameter proposal is not active.");
        require(!proposal.votes[msg.sender], "Curator has already voted on this parameter proposal.");

        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.voteCount++;
        }
        emit ParameterChangeProposalVoted(_proposalId, msg.sender, _approve);

        if (proposal.voteCount >= curatorVotingThreshold && !proposal.approved) {
            proposal.approved = true;
            proposal.active = false; // Proposal is closed after approval

            if (!proposal.executed) {
                if (_proposalType == ProposalType.VOTING_THRESHOLD) {
                    setCuratorVotingThreshold(proposal.proposedValue);
                    proposal.executed = true;
                    emit ParameterChangeProposalExecuted(_proposalId, ProposalType.VOTING_THRESHOLD, proposal.proposedValue);
                } else if (_proposalType == ProposalType.ROYALTY_PERCENTAGE) {
                    setArtistRoyaltyPercentage(proposal.proposedValue);
                    proposal.executed = true;
                    emit ParameterChangeProposalExecuted(_proposalId, ProposalType.ROYALTY_PERCENTAGE, proposal.proposedValue);
                }
            }
        }
    }
}
```