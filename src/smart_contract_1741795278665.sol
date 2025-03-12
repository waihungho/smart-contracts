```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract Outline and Function Summary
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC) to manage collaborative art creation,
 * ownership, and revenue distribution. This contract introduces several advanced concepts and aims for a creative and
 * trendy approach in the Web3 art space, avoiding duplication of common open-source patterns where possible while
 * still adhering to best practices.
 *
 * **Contract Outline:**
 *
 * **Core Concepts:**
 *   - **Membership NFTs:**  Users can become members of the DAAC by minting a Membership NFT. Membership grants voting rights and participation in collective activities.
 *   - **Art Proposals:** Members can submit proposals for new art pieces to be created by the collective. Proposals include details about the artwork, artists involved, and revenue split.
 *   - **Voting System:**  A decentralized voting mechanism allows members to approve art proposals, manage collective resources, and make governance decisions.
 *   - **Collective Art NFTs:** Approved art proposals result in the minting of Collective Art NFTs, owned by the DAAC and represent the collaborative artwork.
 *   - **Fractional Ownership (Optional, Advanced):**  Potentially fractionalize Collective Art NFTs to further distribute ownership and increase accessibility (not directly implemented in this version for simplicity but a conceptual extension).
 *   - **Revenue Sharing:**  Sales revenue from Collective Art NFTs is distributed transparently to contributing artists and the DAAC treasury based on predefined splits in the proposal.
 *   - **Dynamic Art Attributes (Advanced):**  Potentially incorporate dynamic elements into Collective Art NFTs, where attributes can evolve based on community interaction or external data (concept, not fully implemented here due to complexity).
 *   - **Reputation System (Advanced):**  Optionally, a reputation system can be integrated to reward active and valuable members, influencing voting power or access to certain features (concept, not fully implemented here).
 *
 * **Function Summary (20+ Functions):**
 *
 * **Membership & Access Control:**
 *   1. `mintMembershipNFT()`: Allows users to mint a Membership NFT to join the DAAC.
 *   2. `transferMembershipNFT(address _to, uint256 _tokenId)`: Allows members to transfer their Membership NFT.
 *   3. `isMember(address _user)`: Checks if an address is a member of the DAAC (holds a Membership NFT).
 *   4. `renounceMembership()`: Allows a member to burn their Membership NFT and leave the DAAC.
 *   5. `setMembershipCost(uint256 _newCost)`: (Owner-only) Sets the cost to mint a Membership NFT.
 *
 * **Art Proposal & Voting:**
 *   6. `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash, address[] memory _artists, uint256[] memory _artistShares)`: Allows members to submit a new art proposal.
 *   7. `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Allows members to vote on an active art proposal.
 *   8. `finalizeArtProposal(uint256 _proposalId)`: (Owner/Governance) Finalizes an art proposal after voting ends, minting Collective Art NFT if approved.
 *   9. `cancelArtProposal(uint256 _proposalId)`: (Owner/Governance) Cancels an art proposal before voting ends (e.g., if invalid).
 *  10. `getArtProposalDetails(uint256 _proposalId)`: Retrieves details of a specific art proposal.
 *  11. `getArtProposalVoteCount(uint256 _proposalId)`: Retrieves the vote counts for a specific art proposal.
 *  12. `getMemberVote(uint256 _proposalId, address _member)`: Retrieves a member's vote on a specific art proposal.
 *
 * **Collective Art NFT Management:**
 *  13. `mintCollectiveArtNFT(uint256 _proposalId)`: (Internal/Finalize Function) Mints a Collective Art NFT based on an approved proposal.
 *  14. `transferCollectiveArtNFT(address _to, uint256 _tokenId)`: (Governance/Treasury) Transfers a Collective Art NFT from the DAAC treasury.
 *  15. `listCollectiveArtNFTForSale(uint256 _tokenId, uint256 _price)`: (Governance/Treasury) Lists a Collective Art NFT for sale on a hypothetical internal marketplace.
 *  16. `purchaseCollectiveArtNFT(uint256 _tokenId)`: Allows users to purchase a Collective Art NFT listed for sale.
 *  17. `burnCollectiveArtNFT(uint256 _tokenId)`: (Governance-only, Emergency) Burns a Collective Art NFT (use with caution).
 *
 * **Revenue & Treasury Management:**
 *  18. `distributeArtRevenue(uint256 _tokenId)`: Distributes revenue from the sale of a Collective Art NFT to artists and the DAAC treasury.
 *  19. `viewTreasuryBalance()`: Allows viewing the current balance of the DAAC treasury.
 *  20. `withdrawFromTreasury(address _to, uint256 _amount)`: (Governance-only) Allows withdrawing funds from the DAAC treasury (requires proposal and voting).
 *  21. `setPlatformFee(uint256 _newFeePercentage)`: (Owner-only) Sets the platform fee percentage taken from Collective Art NFT sales for the treasury.
 *
 * **Governance & Parameters:**
 *  22. `setVotingDuration(uint256 _newDuration)`: (Owner-only) Sets the default voting duration for art proposals.
 *  23. `setQuorumPercentage(uint256 _newQuorum)`: (Owner-only) Sets the quorum percentage required for art proposal approval.
 *  24. `pauseContract()`: (Owner-only) Pauses the contract, preventing most state-changing functions.
 *  25. `unpauseContract()`: (Owner-only) Unpauses the contract, restoring normal functionality.
 */

contract DecentralizedAutonomousArtCollective {
    // --- State Variables ---

    // Owner of the contract (for administrative tasks)
    address public owner;

    // Membership NFT contract address (for simplicity, using this contract as both collective and membership for example)
    address public membershipNFTContract; // In real scenarios, this could be a separate ERC721 contract

    // Mapping from address to boolean indicating membership
    mapping(address => bool) public isMemberAddress;

    // Cost to mint a Membership NFT
    uint256 public membershipCost = 0.1 ether; // Example cost

    // Art proposal counter
    uint256 public proposalCounter = 0;

    // Struct to represent an art proposal
    struct ArtProposal {
        string title;
        string description;
        string ipfsHash; // Link to the artwork data (e.g., IPFS)
        address[] artists;
        uint256[] artistShares; // Percentage shares for each artist (sum should be 100)
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool isApproved;
        bool finalized;
        uint256 collectiveArtTokenId; // Token ID of the minted Collective Art NFT (if approved and minted)
    }

    // Mapping from proposal ID to ArtProposal struct
    mapping(uint256 => ArtProposal) public artProposals;

    // Mapping from proposal ID to member address to vote (true = yes, false = no)
    mapping(uint256 => mapping(address => bool)) public proposalVotes;

    // Voting duration for art proposals (in seconds)
    uint256 public votingDuration = 7 days;

    // Quorum percentage for art proposal approval (e.g., 51% for simple majority)
    uint256 public quorumPercentage = 51;

    // Platform fee percentage taken from Collective Art NFT sales (e.g., 5% for DAAC treasury)
    uint256 public platformFeePercentage = 5;

    // Counter for Collective Art NFTs
    uint256 public collectiveArtNFTCounter = 0;

    // Mapping from Collective Art NFT token ID to proposal ID
    mapping(uint256 => uint256) public collectiveArtNFTToProposalId;

    // Mapping from Collective Art NFT token ID to sale price (0 if not for sale)
    mapping(uint256 => uint256) public collectiveArtNFTSalePrice;

    // DAAC Treasury balance
    uint256 public treasuryBalance = 0;

    // Contract paused state
    bool public paused = false;

    // --- Events ---
    event MembershipMinted(address indexed member, uint256 tokenId);
    event MembershipTransferred(address indexed from, address indexed to, uint256 tokenId);
    event MembershipRenounced(address indexed member, uint256 tokenId);
    event MembershipCostSet(uint256 newCost);

    event ArtProposalSubmitted(uint256 proposalId, string title, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ArtProposalFinalized(uint256 proposalId, bool isApproved);
    event ArtProposalCancelled(uint256 proposalId);
    event CollectiveArtNFTMinted(uint256 tokenId, uint256 proposalId);
    event CollectiveArtNFTTransferred(address indexed from, address indexed to, uint256 tokenId);
    event CollectiveArtNFTListedForSale(uint256 tokenId, uint256 price);
    event CollectiveArtNFTPurchased(uint256 tokenId, address buyer, uint256 price);
    event CollectiveArtNFTBurned(uint256 tokenId);
    event ArtRevenueDistributed(uint256 tokenId, address[] artists, uint256[] artistAmounts, uint256 treasuryAmount);
    event TreasuryWithdrawal(address to, uint256 amount, address requestedBy);
    event PlatformFeeSet(uint256 newFeePercentage);
    event VotingDurationSet(uint256 newDuration);
    event QuorumPercentageSet(uint256 newQuorum);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can call this function.");
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


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        membershipNFTContract = address(this); // For simplicity, this contract acts as the NFT contract itself
    }

    // --- Membership & Access Control Functions ---

    /// @notice Allows users to mint a Membership NFT to join the DAAC.
    function mintMembershipNFT() public payable whenNotPaused {
        require(!isMember(msg.sender), "Already a member.");
        require(msg.value >= membershipCost, "Insufficient membership cost paid.");

        // For simplicity, using msg.sender as tokenId for membership in this example
        isMemberAddress[msg.sender] = true;
        emit MembershipMinted(msg.sender, uint256(uint160(msg.sender))); // Using address as token ID for simplicity

        // Optionally send excess ETH back to the minter
        if (msg.value > membershipCost) {
            payable(msg.sender).transfer(msg.value - membershipCost);
        }
    }

    /// @notice Allows members to transfer their Membership NFT.
    /// @param _to The address to transfer the Membership NFT to.
    /// @param _tokenId The token ID of the Membership NFT (in this example, address as tokenId)
    function transferMembershipNFT(address _to, uint256 _tokenId) public whenNotPaused {
        require(isMember(msg.sender), "Not a member.");
        require(uint256(uint160(msg.sender)) == _tokenId, "Invalid tokenId for sender."); // Simple check, in real NFT contract, tokenId would be managed differently

        isMemberAddress[msg.sender] = false;
        isMemberAddress[_to] = true;
        emit MembershipTransferred(msg.sender, _to, _tokenId);
    }

    /// @notice Checks if an address is a member of the DAAC (holds a Membership NFT).
    /// @param _user The address to check.
    /// @return bool True if the address is a member, false otherwise.
    function isMember(address _user) public view returns (bool) {
        return isMemberAddress[_user];
    }

    /// @notice Allows a member to burn their Membership NFT and leave the DAAC.
    function renounceMembership() public whenNotPaused onlyMember {
        isMemberAddress[msg.sender] = false;
        emit MembershipRenounced(msg.sender, uint256(uint160(msg.sender)));
    }

    /// @notice (Owner-only) Sets the cost to mint a Membership NFT.
    /// @param _newCost The new cost in Wei.
    function setMembershipCost(uint256 _newCost) public onlyOwner {
        membershipCost = _newCost;
        emit MembershipCostSet(_newCost);
    }

    // --- Art Proposal & Voting Functions ---

    /// @notice Allows members to submit a new art proposal.
    /// @param _title The title of the art proposal.
    /// @param _description A description of the art proposal.
    /// @param _ipfsHash IPFS hash linking to the artwork data.
    /// @param _artists An array of addresses of contributing artists.
    /// @param _artistShares An array of percentage shares for each artist (sum should be 100).
    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        address[] memory _artists,
        uint256[] memory _artistShares
    ) public whenNotPaused onlyMember {
        require(_artists.length == _artistShares.length, "Artists and shares arrays must have the same length.");
        uint256 totalShares = 0;
        for (uint256 i = 0; i < _artistShares.length; i++) {
            totalShares += _artistShares[i];
        }
        require(totalShares == 100, "Total artist shares must equal 100%.");
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Title, description and IPFS hash cannot be empty.");
        require(_artists.length > 0, "At least one artist must be specified.");

        proposalCounter++;
        ArtProposal storage proposal = artProposals[proposalCounter];
        proposal.title = _title;
        proposal.description = _description;
        proposal.ipfsHash = _ipfsHash;
        proposal.artists = _artists;
        proposal.artistShares = _artistShares;
        proposal.votingStartTime = block.timestamp;
        proposal.votingEndTime = block.timestamp + votingDuration;
        proposal.isActive = true;

        emit ArtProposalSubmitted(proposalCounter, _title, msg.sender);
    }

    /// @notice Allows members to vote on an active art proposal.
    /// @param _proposalId The ID of the art proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnArtProposal(uint256 _proposalId, bool _vote) public whenNotPaused onlyMember {
        require(artProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp < artProposals[_proposalId].votingEndTime, "Voting period has ended.");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");

        proposalVotes[_proposalId][msg.sender] = _vote;
        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice (Owner/Governance - in this simple example, owner finalizes) Finalizes an art proposal after voting ends, minting Collective Art NFT if approved.
    /// @param _proposalId The ID of the art proposal to finalize.
    function finalizeArtProposal(uint256 _proposalId) public whenNotPaused onlyOwner { // In a real DAO, governance could finalize
        require(artProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp >= artProposals[_proposalId].votingEndTime, "Voting period has not ended.");
        require(!artProposals[_proposalId].finalized, "Proposal already finalized.");

        artProposals[_proposalId].isActive = false;
        artProposals[_proposalId].finalized = true;

        uint256 totalVotes = artProposals[_proposalId].yesVotes + artProposals[_proposalId].noVotes;
        uint256 quorumVotesNeeded = (totalVotes * quorumPercentage) / 100;

        if (artProposals[_proposalId].yesVotes >= quorumVotesNeeded) {
            artProposals[_proposalId].isApproved = true;
            _mintCollectiveArtNFT(_proposalId); // Mint Collective Art NFT if approved
            emit ArtProposalFinalized(_proposalId, true);
        } else {
            artProposals[_proposalId].isApproved = false;
            emit ArtProposalFinalized(_proposalId, false);
        }
    }

    /// @notice (Owner/Governance) Cancels an art proposal before voting ends (e.g., if invalid).
    /// @param _proposalId The ID of the art proposal to cancel.
    function cancelArtProposal(uint256 _proposalId) public whenNotPaused onlyOwner { // In a real DAO, governance could cancel
        require(artProposals[_proposalId].isActive, "Proposal is not active.");
        require(!artProposals[_proposalId].finalized, "Proposal already finalized.");

        artProposals[_proposalId].isActive = false;
        artProposals[_proposalId].finalized = true;
        emit ArtProposalCancelled(_proposalId);
    }

    /// @notice Retrieves details of a specific art proposal.
    /// @param _proposalId The ID of the art proposal.
    /// @return ArtProposal struct containing proposal details.
    function getArtProposalDetails(uint256 _proposalId) public view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /// @notice Retrieves the vote counts for a specific art proposal.
    /// @param _proposalId The ID of the art proposal.
    /// @return yesVotes The number of yes votes.
    /// @return noVotes The number of no votes.
    function getArtProposalVoteCount(uint256 _proposalId) public view returns (uint256 yesVotes, uint256 noVotes) {
        return (artProposals[_proposalId].yesVotes, artProposals[_proposalId].noVotes);
    }

    /// @notice Retrieves a member's vote on a specific art proposal.
    /// @param _proposalId The ID of the art proposal.
    /// @param _member The address of the member.
    /// @return bool True if the member voted yes, false if no or did not vote.
    function getMemberVote(uint256 _proposalId, address _member) public view returns (bool) {
        return proposalVotes[_proposalId][_member];
    }

    // --- Collective Art NFT Management Functions ---

    /// @notice (Internal/Finalize Function) Mints a Collective Art NFT based on an approved proposal.
    /// @param _proposalId The ID of the approved art proposal.
    function _mintCollectiveArtNFT(uint256 _proposalId) internal {
        collectiveArtNFTCounter++;
        uint256 tokenId = collectiveArtNFTCounter;
        artProposals[_proposalId].collectiveArtTokenId = tokenId;
        collectiveArtNFTToProposalId[tokenId] = _proposalId;

        // In a real ERC721 contract, actual minting logic would be here (e.g., _safeMint)
        // For this example, assuming token ID is just the counter and ownership is tracked conceptually
        emit CollectiveArtNFTMinted(tokenId, _proposalId);
    }

    /// @notice (Governance/Treasury) Transfers a Collective Art NFT from the DAAC treasury.
    /// @param _to The address to transfer the Collective Art NFT to.
    /// @param _tokenId The token ID of the Collective Art NFT.
    function transferCollectiveArtNFT(address _to, uint256 _tokenId) public whenNotPaused onlyOwner { // In a real DAO, governance would decide transfers
        require(collectiveArtNFTToProposalId[_tokenId] != 0, "Invalid Collective Art NFT token ID.");

        // In a real ERC721 contract, actual transfer logic would be here (e.g., _safeTransferFrom)
        emit CollectiveArtNFTTransferred(address(this), _to, _tokenId); // Assuming this contract is the owner/treasury
    }

    /// @notice (Governance/Treasury) Lists a Collective Art NFT for sale on a hypothetical internal marketplace.
    /// @param _tokenId The token ID of the Collective Art NFT to list.
    /// @param _price The sale price in Wei.
    function listCollectiveArtNFTForSale(uint256 _tokenId, uint256 _price) public whenNotPaused onlyOwner { // In a real DAO, governance would decide listings
        require(collectiveArtNFTToProposalId[_tokenId] != 0, "Invalid Collective Art NFT token ID.");
        require(_price > 0, "Price must be greater than zero.");

        collectiveArtNFTSalePrice[_tokenId] = _price;
        emit CollectiveArtNFTListedForSale(_tokenId, _price);
    }

    /// @notice Allows users to purchase a Collective Art NFT listed for sale.
    /// @param _tokenId The token ID of the Collective Art NFT to purchase.
    function purchaseCollectiveArtNFT(uint256 _tokenId) public payable whenNotPaused {
        require(collectiveArtNFTToProposalId[_tokenId] != 0, "Invalid Collective Art NFT token ID.");
        uint256 salePrice = collectiveArtNFTSalePrice[_tokenId];
        require(salePrice > 0, "NFT is not listed for sale.");
        require(msg.value >= salePrice, "Insufficient purchase amount.");

        collectiveArtNFTSalePrice[_tokenId] = 0; // Remove from sale
        _distributeArtRevenue(_tokenId); // Distribute revenue
        emit CollectiveArtNFTPurchased(_tokenId, msg.sender, salePrice);

        // Transfer NFT ownership (conceptual in this example, in real ERC721, transfer logic would be here)
        emit CollectiveArtNFTTransferred(address(this), msg.sender, _tokenId); // Assuming this contract is the seller/treasury

        // Optionally send excess ETH back to the buyer
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }
    }

    /// @notice (Governance-only, Emergency) Burns a Collective Art NFT (use with caution).
    /// @param _tokenId The token ID of the Collective Art NFT to burn.
    function burnCollectiveArtNFT(uint256 _tokenId) public whenNotPaused onlyOwner { // In a real DAO, governance would decide burning in emergencies
        require(collectiveArtNFTToProposalId[_tokenId] != 0, "Invalid Collective Art NFT token ID.");

        // In a real ERC721 contract, actual burning logic would be here (e.g., _burn)
        delete collectiveArtNFTToProposalId[_tokenId]; // Remove mapping
        delete collectiveArtNFTSalePrice[_tokenId]; // Remove from sale if listed

        emit CollectiveArtNFTBurned(_tokenId);
    }


    // --- Revenue & Treasury Management Functions ---

    /// @notice Distributes revenue from the sale of a Collective Art NFT to artists and the DAAC treasury.
    /// @param _tokenId The token ID of the sold Collective Art NFT.
    function _distributeArtRevenue(uint256 _tokenId) internal {
        uint256 proposalId = collectiveArtNFTToProposalId[_tokenId];
        require(proposalId != 0, "Invalid Collective Art NFT token ID for revenue distribution.");
        uint256 salePrice = collectiveArtNFTSalePrice[_tokenId]; // Price at which it was sold (already paid in purchase function)
        require(salePrice > 0, "Sale price not available for revenue distribution."); // Should not happen if called from purchase function

        ArtProposal storage proposal = artProposals[proposalId];
        address[] memory artists = proposal.artists;
        uint256[] memory artistShares = proposal.artistShares;
        uint256 platformFee = (salePrice * platformFeePercentage) / 100;
        uint256 artistRevenue = salePrice - platformFee;

        uint256[] memory artistAmounts = new uint256[](artists.length);
        for (uint256 i = 0; i < artists.length; i++) {
            artistAmounts[i] = (artistRevenue * artistShares[i]) / 100;
            payable(artists[i]).transfer(artistAmounts[i]);
        }

        treasuryBalance += platformFee;
        emit ArtRevenueDistributed(_tokenId, artists, artistAmounts, platformFee);
    }

    /// @notice Allows viewing the current balance of the DAAC treasury.
    /// @return uint256 The treasury balance in Wei.
    function viewTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }

    /// @notice (Governance-only) Allows withdrawing funds from the DAAC treasury (requires proposal and voting in real DAO).
    /// @param _to The address to withdraw funds to.
    /// @param _amount The amount to withdraw in Wei.
    function withdrawFromTreasury(address _to, uint256 _amount) public whenNotPaused onlyOwner { // In a real DAO, this would require a governance proposal and voting
        require(_to != address(0), "Invalid withdrawal address.");
        require(_amount <= treasuryBalance, "Insufficient treasury balance.");

        treasuryBalance -= _amount;
        payable(_to).transfer(_amount);
        emit TreasuryWithdrawal(_to, _amount, msg.sender);
    }

    /// @notice (Owner-only) Sets the platform fee percentage taken from Collective Art NFT sales for the treasury.
    /// @param _newFeePercentage The new platform fee percentage (0-100).
    function setPlatformFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Platform fee percentage must be between 0 and 100.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    // --- Governance & Parameter Functions ---

    /// @notice (Owner-only) Sets the default voting duration for art proposals.
    /// @param _newDuration The new voting duration in seconds.
    function setVotingDuration(uint256 _newDuration) public onlyOwner {
        votingDuration = _newDuration;
        emit VotingDurationSet(_newDuration);
    }

    /// @notice (Owner-only) Sets the quorum percentage required for art proposal approval.
    /// @param _newQuorum The new quorum percentage (0-100).
    function setQuorumPercentage(uint256 _newQuorum) public onlyOwner {
        require(_newQuorum <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _newQuorum;
        emit QuorumPercentageSet(_newQuorum);
    }


    // --- Pause & Unpause Functions ---
    /// @notice (Owner-only) Pauses the contract, preventing most state-changing functions.
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice (Owner-only) Unpauses the contract, restoring normal functionality.
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // Fallback function to receive Ether (for membership minting)
    receive() external payable {}
}
```