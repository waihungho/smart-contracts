```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective, enabling collaborative art creation,
 *      governance, fractional ownership, dynamic NFTs, and community-driven evolution of art.
 *
 * Outline and Function Summary:
 *
 * 1.  **Initialization and Configuration:**
 *     - `constructor(string _collectiveName, address _governanceTokenAddress)`: Initializes the DAAC with a name and governance token address.
 *     - `setPlatformFee(uint256 _feePercentage)`: Allows the owner to set the platform fee percentage for art sales.
 *     - `pauseContract()`: Pauses core functionalities of the contract (except essential reads and unpausing).
 *     - `unpauseContract()`: Resumes the contract functionalities.
 *
 * 2.  **Membership and Governance:**
 *     - `joinCollective()`: Allows users holding the governance token to become members of the collective.
 *     - `leaveCollective()`: Allows members to leave the collective, potentially with conditions (e.g., cooldown).
 *     - `isMember(address _user)`: Checks if an address is a member of the collective.
 *     - `getMemberCount()`: Returns the current number of members in the collective.
 *     - `proposeNewArtist(address _artistAddress)`: Members can propose new artists to be onboarded.
 *     - `voteOnArtistProposal(uint256 _proposalId, bool _vote)`: Members can vote on artist onboarding proposals.
 *     - `listArtists()`: Returns a list of approved artists within the collective.
 *
 * 3.  **Art Submission and Curation:**
 *     - `submitArtProposal(string _title, string _description, string _ipfsHash)`: Approved artists can submit art proposals.
 *     - `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Members vote on submitted art proposals for acceptance into the collective.
 *     - `mintArtNFT(uint256 _proposalId)`: If an art proposal is approved, an NFT representing the artwork can be minted.
 *     - `getArtPieceInfo(uint256 _artPieceId)`: Retrieves information about a specific art piece NFT.
 *     - `listArtPieces()`: Returns a list of all minted art piece IDs in the collective.
 *
 * 4.  **Fractional Ownership and Trading:**
 *     - `fractionalizeArt(uint256 _artPieceId, uint256 _numberOfFractions)`: Allows the collective to fractionalize an art piece NFT into fungible tokens.
 *     - `buyArtFractions(uint256 _artPieceId, uint256 _amount)`: Allows users to buy fractions of an art piece.
 *     - `sellArtFractions(uint256 _artPieceId, uint256 _amount)`: Allows users to sell fractions of an art piece.
 *     - `getFractionBalance(uint256 _artPieceId, address _user)`: Returns the fraction balance of a user for a specific art piece.
 *
 * 5.  **Dynamic NFT Evolution (Concept):**
 *     - `proposeArtEvolution(uint256 _artPieceId, string _evolutionDescription, string _newIpfsHash)`: Members can propose evolutions for existing art NFTs (e.g., updating metadata or visual representation).
 *     - `voteOnArtEvolution(uint256 _proposalId, bool _vote)`: Members vote on art evolution proposals.
 *     - `evolveArtNFT(uint256 _proposalId)`: If an evolution proposal is approved, the art NFT is updated to reflect the evolution.
 *
 * 6.  **Treasury and Revenue Management:**
 *     - `depositFunds()`: Allows depositing ETH or other accepted tokens into the DAAC treasury.
 *     - `withdrawFunds(address _recipient, uint256 _amount)`: Allows governance (e.g., through proposals) to withdraw funds from the treasury.
 *     - `getTreasuryBalance()`: Returns the current balance of the DAAC treasury.
 *     - `distributeRevenueToFractionHolders(uint256 _artPieceId, uint256 _revenueAmount)`: Distributes revenue generated from an art piece to its fraction holders proportionally.
 *
 * 7.  **Voting and Proposal System (Generic):**
 *     - `createProposal(string _description, bytes _calldata, address _targetContract)`: Generic function for members to create proposals for various actions (e.g., treasury withdrawals, parameter changes).
 *     - `voteOnGenericProposal(uint256 _proposalId, bool _vote)`: Members vote on generic proposals.
 *     - `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes the voting threshold.
 *     - `getProposalInfo(uint256 _proposalId)`: Retrieves information about a generic proposal.
 *
 * 8.  **Utility and Information:**
 *     - `getCollectiveName()`: Returns the name of the art collective.
 *     - `getGovernanceTokenAddress()`: Returns the address of the governance token.
 *     - `getPlatformFee()`: Returns the current platform fee percentage.
 *     - `getVotingDuration()`: Returns the default voting duration.
 *     - `setVotingDuration(uint256 _durationInBlocks)`: Allows the owner to set the voting duration.
 *     - `getQuorum()`: Returns the quorum percentage required for proposals to pass.
 *     - `setQuorum(uint256 _quorumPercentage)`: Allows the owner to set the quorum percentage.
 *     - `getProposalCount()`: Returns the total number of proposals created.
 *     - `getArtPieceCount()`: Returns the total number of minted art pieces.
 *     - `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support.
 */

contract DecentralizedAutonomousArtCollective {
    string public collectiveName;
    address public governanceTokenAddress;
    address public owner;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    bool public paused = false;
    uint256 public votingDuration = 7 days; // Default voting duration in blocks (adjust as needed)
    uint256 public quorumPercentage = 50; // Default 50% quorum for proposals

    uint256 public proposalCount = 0;
    uint256 public artPieceCount = 0;

    mapping(address => bool) public members;
    address[] public memberList;

    mapping(address => bool) public approvedArtists;
    address[] public artistList;

    struct ArtistProposal {
        address proposer;
        address artistAddress;
        bool approved;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
    }
    mapping(uint256 => ArtistProposal) public artistProposals;
    uint256 public artistProposalCount = 0;

    struct ArtProposal {
        address artist;
        string title;
        string description;
        string ipfsHash;
        bool approved;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
    }
    mapping(uint256 => ArtProposal) public artProposals;
    uint256 public artProposalCount = 0;

    struct ArtPiece {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        bool fractionalized;
    }
    mapping(uint256 => ArtPiece) public artPieces;
    uint256[] public artPieceIds;

    mapping(uint256 => mapping(address => uint256)) public artFractionBalances; // ArtPieceID => User => Balance
    mapping(uint256 => uint256) public totalArtFractions; // ArtPieceID => Total Fractions Supply

    struct EvolutionProposal {
        uint256 artPieceId;
        address proposer;
        string description;
        string newIpfsHash;
        bool approved;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
    }
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    uint256 public evolutionProposalCount = 0;


    struct GenericProposal {
        uint256 id;
        address proposer;
        string description;
        bytes calldata;
        address targetContract;
        bool executed;
        bool passed;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
    }
    mapping(uint256 => GenericProposal) public proposals;

    event CollectiveInitialized(string collectiveName, address governanceTokenAddress, address owner);
    event PlatformFeeSet(uint256 feePercentage);
    event ContractPaused();
    event ContractUnpaused();

    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);

    event ArtistProposed(uint256 proposalId, address proposer, address artistAddress);
    event ArtistProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtistApproved(address artistAddress);

    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtNFTMinted(uint256 artPieceId, address artist, string title);

    event ArtFractionalized(uint256 artPieceId, uint256 numberOfFractions);
    event ArtFractionsBought(uint256 artPieceId, address buyer, uint256 amount);
    event ArtFractionsSold(uint256 artPieceId, address seller, uint256 amount);
    event RevenueDistributed(uint256 artPieceId, uint256 revenueAmount);

    event ArtEvolutionProposed(uint256 proposalId, uint256 artPieceId, address proposer, string description);
    event ArtEvolutionVoted(uint256 proposalId, address voter, bool vote);
    event ArtEvolved(uint256 artPieceId, string newIpfsHash);

    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);

    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(address recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier onlyApprovedArtist() {
        require(approvedArtists[msg.sender], "Only approved artists can call this function.");
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

    constructor(string memory _collectiveName, address _governanceTokenAddress) {
        collectiveName = _collectiveName;
        governanceTokenAddress = _governanceTokenAddress;
        owner = msg.sender;
        emit CollectiveInitialized(_collectiveName, _governanceTokenAddress, owner);
    }

    // ------------------------------------------------------------------------
    // 1. Initialization and Configuration
    // ------------------------------------------------------------------------

    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // ------------------------------------------------------------------------
    // 2. Membership and Governance
    // ------------------------------------------------------------------------

    function joinCollective() external whenNotPaused {
        // In a real application, you would check if msg.sender holds governance tokens.
        // For simplicity in this example, we'll assume anyone can join (remove require for token check).
        // require(GovernanceToken(_governanceTokenAddress).balanceOf(msg.sender) > 0, "Must hold governance tokens to join.");

        require(!members[msg.sender], "Already a member.");
        members[msg.sender] = true;
        memberList.push(msg.sender);
        emit MemberJoined(msg.sender);
    }

    function leaveCollective() external onlyMember whenNotPaused {
        require(members[msg.sender], "Not a member.");
        members[msg.sender] = false;
        // Remove from memberList (less efficient, consider alternative for large lists in production)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MemberLeft(msg.sender);
    }

    function isMember(address _user) external view returns (bool) {
        return members[_user];
    }

    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }

    function proposeNewArtist(address _artistAddress) external onlyMember whenNotPaused {
        require(_artistAddress != address(0), "Invalid artist address.");
        require(!approvedArtists[_artistAddress], "Artist already approved.");

        artistProposalCount++;
        artistProposals[artistProposalCount] = ArtistProposal({
            proposer: msg.sender,
            artistAddress: _artistAddress,
            approved: false,
            votesFor: 0,
            votesAgainst: 0,
            endTime: block.timestamp + votingDuration
        });
        emit ArtistProposed(artistProposalCount, msg.sender, _artistAddress);
    }

    function voteOnArtistProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(_proposalId > 0 && _proposalId <= artistProposalCount, "Invalid proposal ID.");
        ArtistProposal storage proposal = artistProposals[_proposalId];
        require(!proposal.approved, "Proposal already finalized.");
        require(block.timestamp < proposal.endTime, "Voting has ended.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ArtistProposalVoted(_proposalId, msg.sender, _vote);

        if (block.timestamp >= proposal.endTime) {
            finalizeArtistProposal(_proposalId);
        }
    }

    function finalizeArtistProposal(uint256 _proposalId) private {
        ArtistProposal storage proposal = artistProposals[_proposalId];
        if (!proposal.approved && block.timestamp >= proposal.endTime) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            if (totalVotes > 0 && (proposal.votesFor * 100) / totalVotes >= quorumPercentage) {
                proposal.approved = true;
                approvedArtists[proposal.artistAddress] = true;
                artistList.push(proposal.artistAddress);
                emit ArtistApproved(proposal.artistAddress);
            }
        }
    }

    function listArtists() external view returns (address[] memory) {
        return artistList;
    }

    // ------------------------------------------------------------------------
    // 3. Art Submission and Curation
    // ------------------------------------------------------------------------

    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyApprovedArtist whenNotPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Invalid art proposal details.");

        artProposalCount++;
        artProposals[artProposalCount] = ArtProposal({
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            approved: false,
            votesFor: 0,
            votesAgainst: 0,
            endTime: block.timestamp + votingDuration
        });
        emit ArtProposalSubmitted(artProposalCount, msg.sender, _title);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(_proposalId > 0 && _proposalId <= artProposalCount, "Invalid proposal ID.");
        ArtProposal storage proposal = artProposals[_proposalId];
        require(!proposal.approved, "Proposal already finalized.");
        require(block.timestamp < proposal.endTime, "Voting has ended.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);

        if (block.timestamp >= proposal.endTime) {
            finalizeArtProposalCuration(_proposalId);
        }
    }

    function finalizeArtProposalCuration(uint256 _proposalId) private {
        ArtProposal storage proposal = artProposals[_proposalId];
        if (!proposal.approved && block.timestamp >= proposal.endTime) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            if (totalVotes > 0 && (proposal.votesFor * 100) / totalVotes >= quorumPercentage) {
                proposal.approved = true;
            }
        }
    }

    function mintArtNFT(uint256 _proposalId) external onlyApprovedArtist whenNotPaused {
        require(_proposalId > 0 && _proposalId <= artProposalCount, "Invalid proposal ID.");
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.artist == msg.sender, "Only the proposing artist can mint.");
        require(proposal.approved, "Art proposal not approved yet.");

        artPieceCount++;
        artPieces[artPieceCount] = ArtPiece({
            id: artPieceCount,
            artist: proposal.artist,
            title: proposal.title,
            description: proposal.description,
            ipfsHash: proposal.ipfsHash,
            fractionalized: false
        });
        artPieceIds.push(artPieceCount);
        emit ArtNFTMinted(artPieceCount, proposal.artist, proposal.title);
    }

    function getArtPieceInfo(uint256 _artPieceId) external view returns (ArtPiece memory) {
        require(_artPieceId > 0 && _artPieceId <= artPieceCount, "Invalid art piece ID.");
        return artPieces[_artPieceId];
    }

    function listArtPieces() external view returns (uint256[] memory) {
        return artPieceIds;
    }

    // ------------------------------------------------------------------------
    // 4. Fractional Ownership and Trading
    // ------------------------------------------------------------------------

    function fractionalizeArt(uint256 _artPieceId, uint256 _numberOfFractions) external onlyMember whenNotPaused {
        require(_artPieceId > 0 && _artPieceId <= artPieceCount, "Invalid art piece ID.");
        ArtPiece storage artPiece = artPieces[_artPieceId];
        require(!artPiece.fractionalized, "Art piece already fractionalized.");
        require(_numberOfFractions > 0, "Number of fractions must be positive.");

        artPiece.fractionalized = true;
        totalArtFractions[_artPieceId] = _numberOfFractions;
        // In a real application, you might mint ERC20 tokens representing fractions here.
        emit ArtFractionalized(_artPieceId, _numberOfFractions);
    }

    function buyArtFractions(uint256 _artPieceId, uint256 _amount) external payable whenNotPaused {
        require(_artPieceId > 0 && _artPieceId <= artPieceCount, "Invalid art piece ID.");
        ArtPiece storage artPiece = artPieces[_artPieceId];
        require(artPiece.fractionalized, "Art piece is not fractionalized.");
        require(_amount > 0, "Amount to buy must be positive.");

        // Simple example: Price per fraction is 0.01 ETH (adjust as needed)
        uint256 pricePerFraction = 0.01 ether;
        uint256 totalPrice = pricePerFraction * _amount;
        require(msg.value >= totalPrice, "Insufficient ETH sent.");

        artFractionBalances[_artPieceId][msg.sender] += _amount;

        // Transfer ETH to the treasury (after platform fee)
        uint256 platformFee = (totalPrice * platformFeePercentage) / 100;
        uint256 artistShare = totalPrice - platformFee;

        payable(owner).transfer(platformFee); // Platform Fee to Owner/Treasury
        payable(artPiece.artist).transfer(artistShare); // Artist Share

        emit ArtFractionsBought(_artPieceId, msg.sender, _amount);

        // Refund any extra ETH sent
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function sellArtFractions(uint256 _artPieceId, uint256 _amount) external whenNotPaused {
        require(_artPieceId > 0 && _artPieceId <= artPieceCount, "Invalid art piece ID.");
        ArtPiece storage artPiece = artPieces[_artPieceId];
        require(artPiece.fractionalized, "Art piece is not fractionalized.");
        require(_amount > 0, "Amount to sell must be positive.");
        require(artFractionBalances[_artPieceId][msg.sender] >= _amount, "Insufficient fraction balance.");

        // Simple example: Price per fraction is 0.009 ETH (slightly lower than buy price for market making)
        uint256 pricePerFraction = 0.009 ether;
        uint256 payoutAmount = pricePerFraction * _amount;

        artFractionBalances[_artPieceId][msg.sender] -= _amount;

        payable(msg.sender).transfer(payoutAmount); // Pay the seller

        emit ArtFractionsSold(_artPieceId, msg.sender, _amount);
    }

    function getFractionBalance(uint256 _artPieceId, address _user) external view returns (uint256) {
        return artFractionBalances[_artPieceId][_user];
    }

    // ------------------------------------------------------------------------
    // 5. Dynamic NFT Evolution (Concept)
    // ------------------------------------------------------------------------

    function proposeArtEvolution(uint256 _artPieceId, string memory _evolutionDescription, string memory _newIpfsHash) external onlyMember whenNotPaused {
        require(_artPieceId > 0 && _artPieceId <= artPieceCount, "Invalid art piece ID.");
        require(bytes(_evolutionDescription).length > 0 && bytes(_newIpfsHash).length > 0, "Invalid evolution details.");

        evolutionProposalCount++;
        evolutionProposals[evolutionProposalCount] = EvolutionProposal({
            artPieceId: _artPieceId,
            proposer: msg.sender,
            description: _evolutionDescription,
            newIpfsHash: _newIpfsHash,
            approved: false,
            votesFor: 0,
            votesAgainst: 0,
            endTime: block.timestamp + votingDuration
        });
        emit ArtEvolutionProposed(evolutionProposalCount, _artPieceId, msg.sender, _evolutionDescription);
    }

    function voteOnArtEvolution(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(_proposalId > 0 && _proposalId <= evolutionProposalCount, "Invalid proposal ID.");
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        require(!proposal.approved, "Proposal already finalized.");
        require(block.timestamp < proposal.endTime, "Voting has ended.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ArtEvolutionVoted(_proposalId, msg.sender, _vote);

        if (block.timestamp >= proposal.endTime) {
            finalizeArtEvolutionProposal(_proposalId);
        }
    }

    function finalizeArtEvolutionProposal(uint256 _proposalId) private {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        if (!proposal.approved && block.timestamp >= proposal.endTime) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            if (totalVotes > 0 && (proposal.votesFor * 100) / totalVotes >= quorumPercentage) {
                proposal.approved = true;
                evolveArtNFT(_proposalId); // Execute evolution if approved
            }
        }
    }

    function evolveArtNFT(uint256 _proposalId) private {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.approved, "Evolution proposal not approved.");
        ArtPiece storage artPiece = artPieces[proposal.artPieceId];

        artPiece.ipfsHash = proposal.newIpfsHash; // Update IPFS hash to represent evolution
        emit ArtEvolved(proposal.artPieceId, proposal.newIpfsHash);
    }

    // ------------------------------------------------------------------------
    // 6. Treasury and Revenue Management
    // ------------------------------------------------------------------------

    function depositFunds() external payable whenNotPaused {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function withdrawFunds(address _recipient, uint256 _amount) external onlyMember whenNotPaused {
        require(_recipient != address(0), "Invalid recipient address.");
        require(address(this).balance >= _amount, "Insufficient contract balance.");

        // In a real DAO, withdrawals should typically be governed by proposals.
        // This is a simplified example for demonstration purposes.

        payable(_recipient).transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function distributeRevenueToFractionHolders(uint256 _artPieceId, uint256 _revenueAmount) external onlyMember whenNotPaused {
        require(_artPieceId > 0 && _artPieceId <= artPieceCount, "Invalid art piece ID.");
        ArtPiece storage artPiece = artPieces[_artPieceId];
        require(artPiece.fractionalized, "Art piece is not fractionalized.");
        require(_revenueAmount > 0, "Revenue amount must be positive.");

        uint256 totalFractions = totalArtFractions[_artPieceId];
        require(totalFractions > 0, "No fractions exist for this art piece.");

        for (uint256 i = 0; i < memberList.length; i++) { // Iterate through members (consider optimization for large member lists)
            address memberAddress = memberList[i];
            uint256 memberFractions = artFractionBalances[_artPieceId][memberAddress];
            if (memberFractions > 0) {
                uint256 payout = (_revenueAmount * memberFractions) / totalFractions;
                if (payout > 0) {
                    payable(memberAddress).transfer(payout);
                }
            }
        }
        emit RevenueDistributed(_artPieceId, _revenueAmount);
    }


    // ------------------------------------------------------------------------
    // 7. Voting and Proposal System (Generic)
    // ------------------------------------------------------------------------

    function createProposal(string memory _description, bytes memory _calldata, address _targetContract) external onlyMember whenNotPaused {
        require(bytes(_description).length > 0 && _targetContract != address(0), "Invalid proposal details.");

        proposalCount++;
        proposals[proposalCount] = GenericProposal({
            id: proposalCount,
            proposer: msg.sender,
            description: _description,
            calldata: _calldata,
            targetContract: _targetContract,
            executed: false,
            passed: false,
            votesFor: 0,
            votesAgainst: 0,
            endTime: block.timestamp + votingDuration
        });
        emit ProposalCreated(proposalCount, msg.sender, _description);
    }

    function voteOnGenericProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        GenericProposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(block.timestamp < proposal.endTime, "Voting has ended.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);

        if (block.timestamp >= proposal.endTime) {
            finalizeGenericProposal(_proposalId);
        }
    }

    function finalizeGenericProposal(uint256 _proposalId) private {
        GenericProposal storage proposal = proposals[_proposalId];
        if (!proposal.executed && block.timestamp >= proposal.endTime) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            if (totalVotes > 0 && (proposal.votesFor * 100) / totalVotes >= quorumPercentage) {
                proposal.passed = true;
                executeProposal(_proposalId); // Auto-execute if passed (consider making execution separate in real DAO)
            }
        }
    }

    function executeProposal(uint256 _proposalId) public whenNotPaused { // Public for potential timelock or external execution
        GenericProposal storage proposal = proposals[_proposalId];
        require(proposal.passed, "Proposal not passed.");
        require(!proposal.executed, "Proposal already executed.");

        (bool success, ) = proposal.targetContract.call(proposal.calldata);
        require(success, "Proposal execution failed.");
        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function getProposalInfo(uint256 _proposalId) external view returns (GenericProposal memory) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        return proposals[_proposalId];
    }

    // ------------------------------------------------------------------------
    // 8. Utility and Information
    // ------------------------------------------------------------------------

    function getCollectiveName() external view returns (string memory) {
        return collectiveName;
    }

    function getGovernanceTokenAddress() external view returns (address) {
        return governanceTokenAddress;
    }

    function getPlatformFee() external view returns (uint256) {
        return platformFeePercentage;
    }

    function getVotingDuration() external view returns (uint256) {
        return votingDuration;
    }

    function setVotingDuration(uint256 _durationInBlocks) external onlyOwner {
        votingDuration = _durationInBlocks;
    }

    function getQuorum() external view returns (uint256) {
        return quorumPercentage;
    }

    function setQuorum(uint256 _quorumPercentage) external onlyOwner {
        require(_quorumPercentage <= 100, "Quorum percentage cannot exceed 100.");
        quorumPercentage = _quorumPercentage;
    }

    function getProposalCount() external view returns (uint256) {
        return proposalCount;
    }

    function getArtPieceCount() external view returns (uint256) {
        return artPieceCount;
    }

    // ERC165 interface support (for basic interface detection)
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(DecentralizedAutonomousArtCollective).interfaceId;
    }

    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value); // Allow direct deposits to the contract
    }
}
```