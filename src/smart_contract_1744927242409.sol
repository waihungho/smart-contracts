```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for managing a decentralized art collective, incorporating advanced features
 * to foster community-driven art creation, ownership, and governance.
 *
 * Outline and Function Summary:
 *
 * 1.  **Art Proposal Submission (`submitArtProposal`)**: Allows members to submit art proposals with details.
 * 2.  **Art Proposal Voting (`voteOnArtProposal`)**: Members can vote on submitted art proposals.
 * 3.  **Mint Art NFT (`mintArtNFT`)**: Mints an NFT for approved art proposals, rewarding the artist and DAAC.
 * 4.  **Fractionalize Art NFT (`fractionalizeNFT`)**: Allows fractionalization of a DAAC-owned art NFT into ERC20 tokens.
 * 5.  **Purchase Fraction (`purchaseFraction`)**: Allows users to purchase fractions of fractionalized NFTs.
 * 6.  **Create Art Auction (`createArtAuction`)**: Allows DAAC to auction off art NFTs.
 * 7.  **Bid on Auction (`bidOnAuction`)**: Allows users to bid on ongoing art auctions.
 * 8.  **End Auction (`endAuction`)**: Ends an auction and transfers NFT to the highest bidder.
 * 9.  **Set Royalties (`setRoyalties`)**: Sets royalty percentages for artists on secondary sales of their NFTs.
 * 10. **Withdraw Royalties (`withdrawRoyalties`)**: Artists can withdraw accumulated royalties.
 * 11. **Create Governance Proposal (`createGovernanceProposal`)**: Members can create proposals for DAAC governance decisions.
 * 12. **Vote on Governance Proposal (`voteOnGovernanceProposal`)**: Members can vote on governance proposals.
 * 13. **Execute Governance Proposal (`executeGovernanceProposal`)**: Executes approved governance proposals.
 * 14. **Deposit to Treasury (`depositToTreasury`)**: Allows depositing funds into the DAAC treasury.
 * 15. **Withdraw from Treasury (`withdrawFromTreasury`)**: Allows governed withdrawal of funds from the treasury.
 * 16. **Mint Membership NFT (`mintMembershipNFT`)**: Mints a membership NFT to grant users DAAC membership and voting rights.
 * 17. **Transfer Membership NFT (`transferMembershipNFT`)**: Allows members to transfer their membership NFTs.
 * 18. **Set Minting Fee (`setMintingFee`)**: Sets the fee for minting art NFTs.
 * 19. **Set Auction Fee (`setAuctionFee`)**: Sets the fee charged on successful auctions.
 * 20. **Pause Contract (`pauseContract`)**: Pauses core functionalities of the contract in emergencies.
 * 21. **Unpause Contract (`unpauseContract`)**: Resumes paused functionalities of the contract.
 * 22. **Withdraw Contract Balance (`withdrawContractBalance`)**: Allows the contract owner to withdraw contract's ETH balance (governed by DAO in real-world scenario).
 * 23. **Set Base Metadata URI (`setBaseMetadataURI`)**: Sets the base URI for NFT metadata.
 */

contract DecentralizedArtCollective {
    // State Variables

    address public owner; // Contract owner (DAO in real-world scenario)
    bool public paused;

    uint256 public membershipNFTCounter;
    mapping(uint256 => address) public membershipNFTs; // tokenId => owner
    mapping(address => bool) public isMember;

    uint256 public artNFTCounter;
    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => uint256) public artNFTToProposalId; // NFT ID to Proposal ID
    mapping(uint256 => address) public artistRoyalties; // artNFTId => artist address
    mapping(uint256 => uint256) public royaltyPercentage; // artNFTId => percentage (out of 100)
    mapping(address => uint256) public pendingRoyalties; // artist address => amount

    uint256 public artProposalCounter;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => mapping(address => Vote)) public artProposalVotes; // proposalId => voter => vote

    uint256 public governanceProposalCounter;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => Vote)) public governanceProposalVotes; // proposalId => voter => vote

    uint256 public auctionCounter;
    mapping(uint256 => Auction) public auctions;

    mapping(uint256 => address) public fractionalizedNFTContract; // artNFTId => fractionalization contract address

    uint256 public mintingFee;
    uint256 public auctionFeePercentage;
    uint256 public treasuryBalance;

    string public baseMetadataURI;

    // Structs

    struct ArtNFT {
        uint256 id;
        string title;
        string description;
        address artist;
        uint256 proposalId;
        bool fractionalized;
    }

    struct ArtProposal {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address proposer;
        uint256 upVotes;
        uint256 downVotes;
        bool approved;
        bool executed;
        uint256 royaltyPercentageProposal; // Proposed royalty percentage by the artist
    }

    struct GovernanceProposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 upVotes;
        uint256 downVotes;
        bool approved;
        bool executed;
        bytes data; // Data to execute if proposal passes
        address targetContract; // Contract to call if proposal passes
    }

    struct Auction {
        uint256 id;
        uint256 artNFTId;
        address seller;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        bool ended;
    }

    struct Vote {
        bool votedUp;
    }

    // Events

    event MembershipNFTMinted(uint256 tokenId, address member);
    event ArtProposalSubmitted(uint256 proposalId, string title, address proposer);
    event ArtProposalVoted(uint256 proposalId, address voter, bool votedUp);
    event ArtNFTMinted(uint256 nftId, uint256 proposalId, address artist);
    event ArtNFTFractionalized(uint256 nftId, address fractionalizationContract);
    event FractionPurchased(uint256 nftId, address buyer, uint256 amount);
    event ArtAuctionCreated(uint256 auctionId, uint256 artNFTId, address seller, uint256 endTime);
    event AuctionBidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 auctionId, address winner, uint256 finalPrice);
    event RoyaltiesSet(uint256 nftId, uint256 percentage);
    event RoyaltiesWithdrawn(address artist, uint256 amount);
    event GovernanceProposalCreated(uint256 proposalId, string title, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool votedUp);
    event GovernanceProposalExecuted(uint256 proposalId);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawal(address receiver, uint256 amount);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event ContractBalanceWithdrawn(address receiver, uint256 amount);
    event BaseMetadataURISet(string newBaseURI);


    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function.");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        paused = false;
        mintingFee = 0.01 ether; // Default minting fee
        auctionFeePercentage = 5; // Default auction fee percentage
        baseMetadataURI = "ipfs://defaultBaseURI/"; // Default base metadata URI
    }

    // -------------------- Membership Functions --------------------

    /**
     * @dev Mints a membership NFT to the sender, granting them membership status.
     * @notice Members can participate in voting and other collective activities.
     */
    function mintMembershipNFT() external payable whenNotPaused {
        require(!isMember[msg.sender], "Already a member.");
        membershipNFTCounter++;
        membershipNFTs[membershipNFTCounter] = msg.sender;
        isMember[msg.sender] = true;
        emit MembershipNFTMinted(membershipNFTCounter, msg.sender);
    }

    /**
     * @dev Transfers a membership NFT to another address.
     * @param _to The address to transfer the membership NFT to.
     * @param _tokenId The ID of the membership NFT to transfer.
     */
    function transferMembershipNFT(address _to, uint256 _tokenId) external whenNotPaused {
        require(membershipNFTs[_tokenId] == msg.sender, "Not the owner of this membership NFT.");
        isMember[msg.sender] = false;
        isMember[_to] = true;
        membershipNFTs[_tokenId] = _to;
        // Consider adding event for membership transfer if needed.
    }


    // -------------------- Art Proposal Functions --------------------

    /**
     * @dev Allows members to submit art proposals.
     * @param _title Title of the art proposal.
     * @param _description Description of the art proposal.
     * @param _ipfsHash IPFS hash of the art piece.
     * @param _royaltyPercentage Proposed royalty percentage for the artist.
     */
    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _royaltyPercentage
    ) external onlyMember whenNotPaused {
        require(_royaltyPercentage <= 20, "Royalty percentage cannot exceed 20%."); // Example limit
        artProposalCounter++;
        artProposals[artProposalCounter] = ArtProposal({
            id: artProposalCounter,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            upVotes: 0,
            downVotes: 0,
            approved: false,
            executed: false,
            royaltyPercentageProposal: _royaltyPercentage
        });
        emit ArtProposalSubmitted(artProposalCounter, _title, msg.sender);
    }

    /**
     * @dev Allows members to vote on art proposals.
     * @param _proposalId ID of the art proposal to vote on.
     * @param _voteUp True for upvote, false for downvote.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _voteUp) external onlyMember whenNotPaused {
        require(artProposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        require(!artProposals[_proposalId].approved, "Proposal already decided.");
        require(artProposalVotes[_proposalId][msg.sender].votedUp == false && artProposalVotes[_proposalId][msg.sender].votedUp == false, "Already voted on this proposal."); // Ensure only one vote per member

        artProposalVotes[_proposalId][msg.sender] = Vote({votedUp: _voteUp});
        if (_voteUp) {
            artProposals[_proposalId].upVotes++;
        } else {
            artProposals[_proposalId].downVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _voteUp);

        // Example approval logic: more upvotes than downvotes and reaching a quorum (e.g., 50% of members)
        uint256 totalMembers = membershipNFTCounter; // Assuming membershipNFTCounter reflects total members
        uint256 quorum = totalMembers / 2;
        if (artProposals[_proposalId].upVotes > artProposals[_proposalId].downVotes && (artProposals[_proposalId].upVotes + artProposals[_proposalId].downVotes) >= quorum ) {
            artProposals[_proposalId].approved = true;
        }
    }

    // -------------------- Art NFT Functions --------------------

    /**
     * @dev Mints an Art NFT for an approved art proposal.
     * @param _proposalId ID of the approved art proposal.
     */
    function mintArtNFT(uint256 _proposalId) external payable whenNotPaused {
        require(artProposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        require(artProposals[_proposalId].approved, "Proposal not approved yet.");
        require(!artProposals[_proposalId].executed, "Proposal already executed.");
        require(msg.value >= mintingFee, "Insufficient minting fee.");

        artProposals[_proposalId].executed = true;
        artNFTCounter++;

        artNFTs[artNFTCounter] = ArtNFT({
            id: artNFTCounter,
            title: artProposals[_proposalId].title,
            description: artProposals[_proposalId].description,
            artist: artProposals[_proposalId].proposer,
            proposalId: _proposalId,
            fractionalized: false
        });
        artNFTToProposalId[artNFTCounter] = _proposalId;
        artistRoyalties[artNFTCounter] = artProposals[_proposalId].proposer;
        royaltyPercentage[artNFTCounter] = artProposals[_proposalId].royaltyPercentageProposal;


        // Distribute minting fee (example: 80% to treasury, 20% to artist)
        uint256 artistShare = (msg.value * 20) / 100;
        uint256 treasuryShare = msg.value - artistShare;

        payable(artProposals[_proposalId].proposer).transfer(artistShare);
        treasuryBalance += treasuryShare;

        emit ArtNFTMinted(artNFTCounter, _proposalId, artProposals[_proposalId].proposer);
    }

    /**
     * @dev Allows fractionalization of a DAAC-owned Art NFT into ERC20 tokens (conceptual).
     * @param _artNFTId ID of the Art NFT to fractionalize.
     * @notice This function would ideally deploy a separate fractionalization contract.
     *         For simplicity, this example just marks the NFT as fractionalized.
     */
    function fractionalizeNFT(uint256 _artNFTId) external onlyOwner whenNotPaused {
        require(artNFTs[_artNFTId].id == _artNFTId, "Art NFT does not exist.");
        require(!artNFTs[_artNFTId].fractionalized, "Art NFT already fractionalized.");
        // In a real implementation: Deploy a Fractionalization contract, transfer NFT ownership to it.
        artNFTs[_artNFTId].fractionalized = true;
        fractionalizedNFTContract[_artNFTId] = address(0); // Placeholder - Replace with actual contract address
        emit ArtNFTFractionalized(_artNFTId, address(0)); // Placeholder - Replace with actual contract address
    }

    /**
     * @dev Allows users to purchase fractions of a fractionalized NFT (conceptual).
     * @param _artNFTId ID of the fractionalized Art NFT.
     * @param _amount Amount of fraction tokens to purchase.
     */
    function purchaseFraction(uint256 _artNFTId, uint256 _amount) external payable whenNotPaused {
        require(artNFTs[_artNFTId].id == _artNFTId, "Art NFT does not exist.");
        require(artNFTs[_artNFTId].fractionalized, "Art NFT is not fractionalized.");
        address fractionContract = fractionalizedNFTContract[_artNFTId];
        require(fractionContract != address(0), "Fractionalization contract not deployed (placeholder).");
        // In a real implementation: Interact with the fractionalization contract to purchase tokens.
        // This is a placeholder - functionality would depend on the fractionalization contract implementation.

        // Example placeholder logic (not functional without a real fractionalization contract):
        // (Assume 1 fraction token costs 0.001 ether for this example)
        uint256 expectedValue = _amount * 0.001 ether;
        require(msg.value >= expectedValue, "Insufficient funds for fraction purchase.");

        // ... (Integration with fractionalization contract to transfer tokens) ...

        emit FractionPurchased(_artNFTId, msg.sender, _amount);
    }

    // -------------------- Art Auction Functions --------------------

    /**
     * @dev Creates an auction for a DAAC-owned Art NFT.
     * @param _artNFTId ID of the Art NFT to auction.
     * @param _auctionDurationSeconds Duration of the auction in seconds.
     */
    function createArtAuction(uint256 _artNFTId, uint256 _auctionDurationSeconds) external onlyOwner whenNotPaused {
        require(artNFTs[_artNFTId].id == _artNFTId, "Art NFT does not exist.");
        require(!auctions[_artNFTId].ended, "Auction already ended for this NFT."); // Basic check, improve in real scenario
        auctionCounter++;
        auctions[auctionCounter] = Auction({
            id: auctionCounter,
            artNFTId: _artNFTId,
            seller: address(this), // DAAC is the seller
            startTime: block.timestamp,
            endTime: block.timestamp + _auctionDurationSeconds,
            highestBid: 0,
            highestBidder: address(0),
            ended: false
        });
        emit ArtAuctionCreated(auctionCounter, _artNFTId, address(this), block.timestamp + _auctionDurationSeconds);
    }

    /**
     * @dev Allows users to bid on an ongoing art auction.
     * @param _auctionId ID of the auction to bid on.
     */
    function bidOnAuction(uint256 _auctionId) external payable whenNotPaused {
        require(auctions[_auctionId].id == _auctionId, "Auction does not exist.");
        require(block.timestamp < auctions[_auctionId].endTime, "Auction has ended.");
        require(!auctions[_auctionId].ended, "Auction already ended.");
        require(msg.value > auctions[_auctionId].highestBid, "Bid not high enough.");

        if (auctions[_auctionId].highestBidder != address(0)) {
            payable(auctions[_auctionId].highestBidder).transfer(auctions[_auctionId].highestBid); // Refund previous highest bidder
        }

        auctions[_auctionId].highestBid = msg.value;
        auctions[_auctionId].highestBidder = msg.sender;
        emit AuctionBidPlaced(_auctionId, msg.sender, msg.value);
    }

    /**
     * @dev Ends an art auction and transfers the NFT to the highest bidder.
     * @param _auctionId ID of the auction to end.
     */
    function endAuction(uint256 _auctionId) external whenNotPaused {
        require(auctions[_auctionId].id == _auctionId, "Auction does not exist.");
        require(block.timestamp >= auctions[_auctionId].endTime, "Auction end time not reached yet.");
        require(!auctions[_auctionId].ended, "Auction already ended.");

        auctions[_auctionId].ended = true;

        if (auctions[_auctionId].highestBidder != address(0)) {
            // Transfer NFT to highest bidder (in real implementation, NFT ownership needs to be managed correctly)
            // For this example, assume DAAC holds the NFT and transfer logic is handled externally or in a more complex setup.
            // Example:  NFT_CONTRACT.transferFrom(address(this), auctions[_auctionId].highestBidder, auctions[_auctionId].artNFTId);

            // Apply auction fee and distribute proceeds (example: 95% to treasury, 5% auction fee)
            uint256 auctionFee = (auctions[_auctionId].highestBid * auctionFeePercentage) / 100;
            uint256 treasuryProceeds = auctions[_auctionId].highestBid - auctionFee;

            treasuryBalance += treasuryProceeds;
            treasuryBalance += auctionFee; // Auction fee also goes to treasury in this example

            emit AuctionEnded(_auctionId, auctions[_auctionId].highestBidder, auctions[_auctionId].highestBid);
        } else {
            // No bids placed, auction ended without a winner.
            emit AuctionEnded(_auctionId, address(0), 0);
        }
    }

    /**
     * @dev Sets the royalty percentage for an Art NFT.
     * @param _artNFTId ID of the Art NFT.
     * @param _percentage Royalty percentage (out of 100).
     */
    function setRoyalties(uint256 _artNFTId, uint256 _percentage) external onlyOwner whenNotPaused {
        require(artNFTs[_artNFTId].id == _artNFTId, "Art NFT does not exist.");
        require(_percentage <= 20, "Royalty percentage cannot exceed 20%."); // Example limit
        royaltyPercentage[_artNFTId] = _percentage;
        emit RoyaltiesSet(_artNFTId, _percentage);
    }

    /**
     * @dev Allows artists to withdraw their accumulated royalties.
     */
    function withdrawRoyalties() external whenNotPaused {
        uint256 amountToWithdraw = pendingRoyalties[msg.sender];
        require(amountToWithdraw > 0, "No royalties to withdraw.");
        pendingRoyalties[msg.sender] = 0; // Reset pending royalties
        payable(msg.sender).transfer(amountToWithdraw);
        emit RoyaltiesWithdrawn(msg.sender, amountToWithdraw);
    }

    // -------------------- Governance Functions --------------------

    /**
     * @dev Creates a governance proposal.
     * @param _title Title of the governance proposal.
     * @param _description Description of the governance proposal.
     * @param _targetContract Address of the contract to interact with (optional).
     * @param _data Data to send to the target contract (optional).
     */
    function createGovernanceProposal(
        string memory _title,
        string memory _description,
        address _targetContract,
        bytes memory _data
    ) external onlyMember whenNotPaused {
        governanceProposalCounter++;
        governanceProposals[governanceProposalCounter] = GovernanceProposal({
            id: governanceProposalCounter,
            title: _title,
            description: _description,
            proposer: msg.sender,
            upVotes: 0,
            downVotes: 0,
            approved: false,
            executed: false,
            targetContract: _targetContract,
            data: _data
        });
        emit GovernanceProposalCreated(governanceProposalCounter, _title, msg.sender);
    }

    /**
     * @dev Allows members to vote on governance proposals.
     * @param _proposalId ID of the governance proposal to vote on.
     * @param _voteUp True for upvote, false for downvote.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _voteUp) external onlyMember whenNotPaused {
        require(governanceProposals[_proposalId].id == _proposalId, "Governance proposal does not exist.");
        require(!governanceProposals[_proposalId].approved, "Governance proposal already decided.");
        require(governanceProposalVotes[_proposalId][msg.sender].votedUp == false && governanceProposalVotes[_proposalId][msg.sender].votedUp == false, "Already voted on this proposal."); // Ensure only one vote per member

        governanceProposalVotes[_proposalId][msg.sender] = Vote({votedUp: _voteUp});
        if (_voteUp) {
            governanceProposals[_proposalId].upVotes++;
        } else {
            governanceProposals[_proposalId].downVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _voteUp);

        // Example approval logic: more upvotes than downvotes and reaching a quorum (e.g., 50% of members)
        uint256 totalMembers = membershipNFTCounter; // Assuming membershipNFTCounter reflects total members
        uint256 quorum = totalMembers / 2;
        if (governanceProposals[_proposalId].upVotes > governanceProposals[_proposalId].downVotes && (governanceProposals[_proposalId].upVotes + governanceProposals[_proposalId].downVotes) >= quorum) {
            governanceProposals[_proposalId].approved = true;
        }
    }

    /**
     * @dev Executes an approved governance proposal.
     * @param _proposalId ID of the governance proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) external onlyOwner whenNotPaused { // In real DAO, execution might be permissionless or governed differently
        require(governanceProposals[_proposalId].id == _proposalId, "Governance proposal does not exist.");
        require(governanceProposals[_proposalId].approved, "Governance proposal not approved.");
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed.");

        governanceProposals[_proposalId].executed = true;
        emit GovernanceProposalExecuted(_proposalId);

        // Example execution logic: Call a function on a target contract with provided data.
        if (governanceProposals[_proposalId].targetContract != address(0)) {
            (bool success, ) = governanceProposals[_proposalId].targetContract.call(governanceProposals[_proposalId].data);
            require(success, "Governance proposal execution failed.");
        }
    }

    // -------------------- Treasury Functions --------------------

    /**
     * @dev Allows depositing funds into the DAAC treasury.
     */
    function depositToTreasury() external payable whenNotPaused {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows governed withdrawal of funds from the treasury.
     * @param _amount Amount to withdraw.
     * @param _receiver Address to receive the withdrawn funds.
     * @notice In a real DAO, withdrawals would be governed by proposals. This is a simplified version.
     */
    function withdrawFromTreasury(uint256 _amount, address _receiver) external onlyOwner whenNotPaused { // Should ideally be governed by DAO proposal in a real scenario.
        require(treasuryBalance >= _amount, "Insufficient treasury balance.");
        treasuryBalance -= _amount;
        payable(_receiver).transfer(_amount);
        emit TreasuryWithdrawal(_receiver, _amount);
    }

    // -------------------- Admin/Utility Functions --------------------

    /**
     * @dev Sets the minting fee for Art NFTs.
     * @param _fee New minting fee.
     */
    function setMintingFee(uint256 _fee) external onlyOwner whenNotPaused {
        mintingFee = _fee;
    }

    /**
     * @dev Sets the auction fee percentage.
     * @param _percentage New auction fee percentage (out of 100).
     */
    function setAuctionFee(uint256 _percentage) external onlyOwner whenNotPaused {
        require(_percentage <= 100, "Auction fee percentage cannot exceed 100%.");
        auctionFeePercentage = _percentage;
    }

    /**
     * @dev Pauses the contract, preventing core functionalities.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, resuming core functionalities.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw the contract's ETH balance.
     * @notice In a real-world DAO, this might be governed or restricted.
     */
    function withdrawContractBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit ContractBalanceWithdrawn(owner, balance);
    }

    /**
     * @dev Sets the base metadata URI for NFTs.
     * @param _baseURI New base metadata URI.
     */
    function setBaseMetadataURI(string memory _baseURI) external onlyOwner {
        baseMetadataURI = _baseURI;
        emit BaseMetadataURISet(_baseURI);
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```