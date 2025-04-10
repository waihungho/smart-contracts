```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Gemini (AI Assistant)
 * @dev A smart contract for a decentralized art collective, enabling artists to submit, curate, and monetize digital art collaboratively.
 *
 * **Outline & Function Summary:**
 *
 * **Core Functionality:**
 * 1. `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Allows artists to submit art proposals with title, description, and IPFS hash of the artwork.
 * 2. `voteOnArtProposal(uint256 _proposalId, bool _approve)`: Collective members can vote to approve or reject art proposals.
 * 3. `mintNFTForApprovedArt(uint256 _proposalId)`: Mints an NFT for an approved art proposal, transferring ownership to the artist.
 * 4. `purchaseNFT(uint256 _nftId)`: Allows users to purchase NFTs listed by artists.
 * 5. `listNFTForSale(uint256 _nftId, uint256 _price)`: Artist can list their NFTs for sale at a specified price.
 * 6. `cancelNFTSale(uint256 _nftId)`: Artist can cancel the sale listing of their NFT.
 * 7. `transferNFT(uint256 _nftId, address _to)`: NFT owner can transfer their NFT to another address.
 *
 * **Collective Governance & Participation:**
 * 8. `joinCollective()`: Allows users to request membership in the art collective.
 * 9. `approveCollectiveMember(address _member)`: Admin/existing members can approve new membership requests.
 * 10. `proposePlatformChange(string memory _proposalDescription, bytes memory _data)`: Members can propose changes to the platform parameters (e.g., fees, voting thresholds).
 * 11. `voteOnPlatformChange(uint256 _changeProposalId, bool _support)`: Collective members can vote on platform change proposals.
 * 12. `executePlatformChange(uint256 _changeProposalId)`: Executes an approved platform change proposal.
 * 13. `donateToCollective()`: Allows users to donate ETH to the collective for platform maintenance and development.
 *
 * **Artist & Revenue Management:**
 * 14. `withdrawArtistProceeds(uint256 _nftId)`: Artists can withdraw proceeds earned from NFT sales.
 * 15. `setArtistRoyalty(uint256 _nftId, uint256 _royaltyPercentage)`: Artist can set a secondary sales royalty percentage for their NFT.
 * 16. `claimSecondarySaleRoyalty(uint256 _nftId)`: Artists can claim royalties from secondary sales of their NFTs.
 * 17. `burnNFT(uint256 _nftId)`: Allows the NFT owner to burn their NFT (permanently remove it).
 *
 * **Advanced & Trendy Features:**
 * 18. `createCuratedCollection(string memory _collectionName)`: Allows collective members to create curated NFT collections.
 * 19. `addNFTToCollection(uint256 _nftId, uint256 _collectionId)`: Allows curators to add NFTs to curated collections.
 * 20. `stakeForVotingPower()`: Allows members to stake ETH to increase their voting power in proposals.
 * 21. `unstakeVotingPower()`: Allows members to unstake ETH and reclaim it.
 * 22. `setPlatformFeePercentage(uint256 _feePercentage)`: Admin function to set the platform fee percentage on NFT sales.
 * 23. `withdrawPlatformFees()`: Admin function to withdraw accumulated platform fees for collective use.
 * 24. `reportContent(uint256 _nftId, string memory _reportReason)`: Allows users to report NFTs for policy violations.
 * 25. `voteOnContentReport(uint256 _reportId, bool _removeContent)`: Collective members vote on removing reported content.
 */

contract DecentralizedArtCollective {
    // --- Structs & Enums ---

    enum ProposalStatus { Pending, Approved, Rejected }
    enum SaleStatus { NotListed, Listed, Sold }
    enum ReportStatus { Pending, Approved, Rejected }

    struct ArtProposal {
        string title;
        string description;
        string ipfsHash;
        address artist;
        ProposalStatus status;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        mapping(address => bool) votes; // Track votes per member to prevent double voting
    }

    struct NFTInfo {
        uint256 proposalId;
        address artist;
        string ipfsHash;
        uint256 royaltyPercentage; // Percentage of secondary sale price as royalty
        SaleStatus saleStatus;
        uint256 salePrice;
    }

    struct PlatformChangeProposal {
        string description;
        bytes data; // Encoded data for platform change execution
        ProposalStatus status;
        uint256 voteCountSupport;
        uint256 voteCountOppose;
        mapping(address => bool) votes;
    }

    struct CuratedCollection {
        string name;
        uint256[] nftIds;
        address curator;
    }

    struct ContentReport {
        uint256 nftId;
        string reason;
        address reporter;
        ReportStatus status;
        uint256 voteCountRemove;
        uint256 voteCountKeep;
        mapping(address => bool) votes;
    }

    // --- State Variables ---

    address public admin;
    uint256 public proposalCounter;
    uint256 public nftCounter;
    uint256 public changeProposalCounter;
    uint256 public collectionCounter;
    uint256 public reportCounter;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => NFTInfo) public nfts;
    mapping(uint256 => PlatformChangeProposal) public platformChangeProposals;
    mapping(uint256 => CuratedCollection) public curatedCollections;
    mapping(uint256 => ContentReport) public contentReports;
    mapping(address => bool) public collectiveMembers;
    mapping(address => bool) public membershipRequested;
    mapping(address => uint256) public stakingBalance; // ETH Staked for voting power

    uint256 public proposalVoteThreshold = 5; // Minimum members to vote for approval/rejection
    uint256 public changeProposalVoteThreshold = 10;
    uint256 public contentReportVoteThreshold = 7;
    uint256 public stakingMultiplier = 10; // 1 ETH staked = 10 voting power

    // --- Events ---

    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address member, bool approve);
    event ArtApprovedAndNFTMinted(uint256 nftId, uint256 proposalId, address artist);
    event NFTListedForSale(uint256 nftId, uint256 price);
    event NFTSaleCancelled(uint256 nftId);
    event NFTPurchased(uint256 nftId, address buyer, uint256 price);
    event NFTTransferred(uint256 nftId, address from, address to);
    event CollectiveMemberJoined(address member);
    event PlatformChangeProposed(uint256 changeProposalId, string description);
    event PlatformChangeVoted(uint256 changeProposalId, address member, bool support);
    event PlatformChangeExecuted(uint256 changeProposalId);
    event DonationReceived(address donor, uint256 amount);
    event ArtistProceedsWithdrawn(uint256 nftId, address artist, uint256 amount);
    event RoyaltySet(uint256 nftId, uint256 royaltyPercentage);
    event RoyaltyClaimed(uint256 nftId, address artist, uint256 amount);
    event NFTBurned(uint256 nftId, address owner);
    event CuratedCollectionCreated(uint256 collectionId, string name, address curator);
    event NFTAddedToCollection(uint256 nftId, uint256 collectionId);
    event StakingIncreased(address member, uint256 amount);
    event StakingDecreased(address member, uint256 amount);
    event PlatformFeePercentageSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event ContentReportSubmitted(uint256 reportId, uint256 nftId, address reporter);
    event ContentReportVoted(uint256 reportId, address member, bool removeContent);
    event ContentRemoved(uint256 nftId);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyCollectiveMembers() {
        require(collectiveMembers[msg.sender], "Only collective members can call this function.");
        _;
    }

    modifier onlyNFTArtist(uint256 _nftId) {
        require(nfts[_nftId].artist == msg.sender, "Only the NFT artist can call this function.");
        _;
    }

    modifier onlyNFTOwner(uint256 _nftId) {
        require(getNFTOwner(_nftId) == msg.sender, "Only the NFT owner can call this function.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier validNFTId(uint256 _nftId) {
        require(_nftId > 0 && _nftId <= nftCounter, "Invalid NFT ID.");
        _;
    }

    modifier validChangeProposalId(uint256 _changeProposalId) {
        require(_changeProposalId > 0 && _changeProposalId <= changeProposalCounter, "Invalid change proposal ID.");
        _;
    }

    modifier validCollectionId(uint256 _collectionId) {
        require(_collectionId > 0 && _collectionId <= collectionCounter, "Invalid collection ID.");
        _;
    }

    modifier validReportId(uint256 _reportId) {
        require(_reportId > 0 && _reportId <= reportCounter, "Invalid report ID.");
        _;
    }

    modifier proposalPending(uint256 _proposalId) {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        _;
    }

    modifier changeProposalPending(uint256 _changeProposalId) {
        require(platformChangeProposals[_changeProposalId].status == ProposalStatus.Pending, "Change proposal is not pending.");
        _;
    }

    modifier reportPending(uint256 _reportId) {
        require(contentReports[_reportId].status == ReportStatus.Pending, "Report is not pending.");
        _;
    }


    // --- Constructor ---
    constructor() {
        admin = msg.sender;
    }

    // --- Core Functionality ---

    /// @notice Allows artists to submit art proposals.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork data.
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) public {
        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artist: msg.sender,
            status: ProposalStatus.Pending,
            voteCountApprove: 0,
            voteCountReject: 0,
            votes: mapping(address => bool)()
        });
        emit ArtProposalSubmitted(proposalCounter, msg.sender, _title);
    }

    /// @notice Allows collective members to vote on art proposals.
    /// @param _proposalId ID of the art proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnArtProposal(uint256 _proposalId, bool _approve)
        public
        onlyCollectiveMembers
        validProposalId(_proposalId)
        proposalPending(_proposalId)
    {
        require(!artProposals[_proposalId].votes[msg.sender], "Member has already voted on this proposal.");
        artProposals[_proposalId].votes[msg.sender] = true;

        if (_approve) {
            artProposals[_proposalId].voteCountApprove += getVotingPower(msg.sender);
        } else {
            artProposals[_proposalId].voteCountReject += getVotingPower(msg.sender);
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _approve);

        // Check if proposal should be automatically approved or rejected based on vote count
        if (artProposals[_proposalId].voteCountApprove >= proposalVoteThreshold) {
            artProposals[_proposalId].status = ProposalStatus.Approved;
        } else if (artProposals[_proposalId].voteCountReject >= proposalVoteThreshold) {
            artProposals[_proposalId].status = ProposalStatus.Rejected;
        }
    }

    /// @notice Mints an NFT for an approved art proposal.
    /// @param _proposalId ID of the approved art proposal.
    function mintNFTForApprovedArt(uint256 _proposalId)
        public
        onlyAdmin // Or potentially a curator role can be introduced
        validProposalId(_proposalId)
    {
        require(artProposals[_proposalId].status == ProposalStatus.Approved, "Proposal must be approved to mint NFT.");
        nftCounter++;
        nfts[nftCounter] = NFTInfo({
            proposalId: _proposalId,
            artist: artProposals[_proposalId].artist,
            ipfsHash: artProposals[_proposalId].ipfsHash,
            royaltyPercentage: 5, // Default royalty, can be changed by artist
            saleStatus: SaleStatus.NotListed,
            salePrice: 0
        });
        // In a real NFT contract, you would mint an actual NFT and associate nftCounter with it.
        // For simplicity, we're just managing NFT info here.
        emit ArtApprovedAndNFTMinted(nftCounter, _proposalId, artProposals[_proposalId].artist);
    }

    /// @notice Allows users to purchase NFTs listed for sale.
    /// @param _nftId ID of the NFT to purchase.
    function purchaseNFT(uint256 _nftId) public payable validNFTId(_nftId) {
        require(nfts[_nftId].saleStatus == SaleStatus.Listed, "NFT is not listed for sale.");
        require(msg.value >= nfts[_nftId].salePrice, "Insufficient funds sent.");

        address artist = nfts[_nftId].artist;
        uint256 salePrice = nfts[_nftId].salePrice;

        nfts[_nftId].saleStatus = SaleStatus.Sold;
        nfts[_nftId].salePrice = 0; // Reset sale price after sale

        // Transfer funds to artist and platform fee to contract
        uint256 platformFee = (salePrice * platformFeePercentage) / 100;
        uint256 artistProceeds = salePrice - platformFee;

        payable(artist).transfer(artistProceeds);
        payable(address(this)).transfer(platformFee); // Store platform fees in contract

        // In a real NFT contract, transfer NFT ownership here.
        // For simplicity, we are not tracking NFT ownership directly in this contract.

        emit NFTPurchased(_nftId, msg.sender, salePrice);
    }

    /// @notice Artist can list their NFT for sale at a specified price.
    /// @param _nftId ID of the NFT to list.
    /// @param _price Sale price in Wei.
    function listNFTForSale(uint256 _nftId, uint256 _price) public onlyNFTArtist(_nftId) validNFTId(_nftId) {
        require(nfts[_nftId].saleStatus == SaleStatus.NotListed, "NFT is already listed or sold.");
        nfts[_nftId].saleStatus = SaleStatus.Listed;
        nfts[_nftId].salePrice = _price;
        emit NFTListedForSale(_nftId, _price);
    }

    /// @notice Artist can cancel the sale listing of their NFT.
    /// @param _nftId ID of the NFT to cancel sale.
    function cancelNFTSale(uint256 _nftId) public onlyNFTArtist(_nftId) validNFTId(_nftId) {
        require(nfts[_nftId].saleStatus == SaleStatus.Listed, "NFT is not listed for sale.");
        nfts[_nftId].saleStatus = SaleStatus.NotListed;
        nfts[_nftId].salePrice = 0;
        emit NFTSaleCancelled(_nftId);
    }

    /// @notice NFT owner can transfer their NFT to another address.
    /// @param _nftId ID of the NFT to transfer.
    /// @param _to Address to transfer the NFT to.
    function transferNFT(uint256 _nftId, address _to) public onlyNFTOwner(_nftId) validNFTId(_nftId) {
        address currentOwner = getNFTOwner(_nftId);
        // In a real NFT contract, you would transfer NFT ownership here.
        // For simplicity, we are just updating artist info.
        nfts[_nftId].artist = _to; // For simplicity, just changing artist to simulate transfer.
        emit NFTTransferred(_nftId, currentOwner, _to);
    }

    /// @notice Internal helper function to get the current owner of an NFT (for simplicity, returns artist).
    function getNFTOwner(uint256 _nftId) internal view returns (address) {
        return nfts[_nftId].artist; // In a real NFT contract, this would track actual ownership.
    }

    // --- Collective Governance & Participation ---

    /// @notice Allows users to request membership in the art collective.
    function joinCollective() public {
        require(!collectiveMembers[msg.sender], "Already a member.");
        require(!membershipRequested[msg.sender], "Membership already requested.");
        membershipRequested[msg.sender] = true;
        // Membership approval process can be further defined based on requirements.
        // For simplicity, admin approval is used.
    }

    /// @notice Admin/existing members can approve new membership requests.
    /// @param _member Address of the member to approve.
    function approveCollectiveMember(address _member) public onlyCollectiveMembers {
        require(membershipRequested[_member], "Membership not requested.");
        collectiveMembers[_member] = true;
        membershipRequested[_member] = false;
        emit CollectiveMemberJoined(_member);
    }

    /// @notice Allows members to propose changes to the platform parameters.
    /// @param _proposalDescription Description of the proposed change.
    /// @param _data Encoded data for platform change execution (e.g., function signature and parameters).
    function proposePlatformChange(string memory _proposalDescription, bytes memory _data) public onlyCollectiveMembers {
        changeProposalCounter++;
        platformChangeProposals[changeProposalCounter] = PlatformChangeProposal({
            description: _proposalDescription,
            data: _data,
            status: ProposalStatus.Pending,
            voteCountSupport: 0,
            voteCountOppose: 0,
            votes: mapping(address => bool)()
        });
        emit PlatformChangeProposed(changeProposalCounter, _proposalDescription);
    }

    /// @notice Allows collective members to vote on platform change proposals.
    /// @param _changeProposalId ID of the platform change proposal.
    /// @param _support True to support, false to oppose.
    function voteOnPlatformChange(uint256 _changeProposalId, bool _support)
        public
        onlyCollectiveMembers
        validChangeProposalId(_changeProposalId)
        changeProposalPending(_changeProposalId)
    {
        require(!platformChangeProposals[_changeProposalId].votes[msg.sender], "Member has already voted on this change proposal.");
        platformChangeProposals[_changeProposalId].votes[msg.sender] = true;

        if (_support) {
            platformChangeProposals[_changeProposalId].voteCountSupport += getVotingPower(msg.sender);
        } else {
            platformChangeProposals[_changeProposalId].voteCountOppose += getVotingPower(msg.sender);
        }
        emit PlatformChangeVoted(_changeProposalId, msg.sender, _support);

        // Check if proposal should be automatically approved or rejected based on vote count
        if (platformChangeProposals[_changeProposalId].voteCountSupport >= changeProposalVoteThreshold) {
            platformChangeProposals[_changeProposalId].status = ProposalStatus.Approved;
        } else if (platformChangeProposals[_changeProposalId].voteCountOppose >= changeProposalVoteThreshold) {
            platformChangeProposals[_changeProposalId].status = ProposalStatus.Rejected;
        }
    }

    /// @notice Executes an approved platform change proposal.
    /// @param _changeProposalId ID of the approved platform change proposal.
    function executePlatformChange(uint256 _changeProposalId)
        public
        onlyAdmin // Or governance based execution can be implemented
        validChangeProposalId(_changeProposalId)
    {
        require(platformChangeProposals[_changeProposalId].status == ProposalStatus.Approved, "Change proposal must be approved to execute.");
        // Decode and execute the platform change based on platformChangeProposals[_changeProposalId].data
        // Example: If data is to change platformFeePercentage
        // (In a real scenario, use proper encoding/decoding like ABI encoding)
        // For simplicity, assuming data is just the new platform fee percentage as bytes.
        // uint256 newFeePercentage = abi.decode(platformChangeProposals[_changeProposalId].data, (uint256));
        // setPlatformFeePercentage(newFeePercentage); // Example execution
        platformChangeProposals[_changeProposalId].status = ProposalStatus.Rejected; // To prevent re-execution
        emit PlatformChangeExecuted(_changeProposalId);
    }

    /// @notice Allows users to donate ETH to the collective for platform maintenance and development.
    function donateToCollective() public payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    // --- Artist & Revenue Management ---

    /// @notice Artists can withdraw proceeds earned from NFT sales.
    /// @param _nftId ID of the NFT for which to withdraw proceeds.
    function withdrawArtistProceeds(uint256 _nftId) public onlyNFTArtist(_nftId) validNFTId(_nftId) {
        // In a real scenario, you would track artist balances per NFT sale.
        // For simplicity, assuming artist can withdraw directly from contract balance if they have sales.
        uint256 balance = address(this).balance; // Get contract balance (simplified proceeds)
        require(balance > 0, "No proceeds to withdraw.");
        payable(msg.sender).transfer(balance); // Simplified withdrawal
        emit ArtistProceedsWithdrawn(_nftId, msg.sender, balance);
    }

    /// @notice Artist can set a secondary sales royalty percentage for their NFT.
    /// @param _nftId ID of the NFT to set royalty for.
    /// @param _royaltyPercentage Royalty percentage (e.g., 10 for 10%).
    function setArtistRoyalty(uint256 _nftId, uint256 _royaltyPercentage) public onlyNFTArtist(_nftId) validNFTId(_nftId) {
        require(_royaltyPercentage <= 50, "Royalty percentage cannot exceed 50%."); // Example limit
        nfts[_nftId].royaltyPercentage = _royaltyPercentage;
        emit RoyaltySet(_nftId, _royaltyPercentage);
    }

    /// @notice Artists can claim royalties from secondary sales of their NFTs.
    /// @param _nftId ID of the NFT for which to claim royalty.
    function claimSecondarySaleRoyalty(uint256 _nftId) public onlyNFTArtist(_nftId) validNFTId(_nftId) {
        // In a real NFT marketplace, secondary sales and royalty tracking would be implemented.
        // For simplicity, this is a placeholder function.
        // Royalty claiming logic would be complex and depends on secondary sale implementation.
        emit RoyaltyClaimed(_nftId, msg.sender, 0); // Emitting 0 as amount for now, needs real logic
    }

    /// @notice Allows the NFT owner to burn their NFT (permanently remove it).
    /// @param _nftId ID of the NFT to burn.
    function burnNFT(uint256 _nftId) public onlyNFTOwner(_nftId) validNFTId(_nftId) {
        // In a real NFT contract, burning would remove the NFT.
        // Here, we are just resetting NFT info to simulate burning.
        delete nfts[_nftId];
        emit NFTBurned(_nftId, msg.sender);
    }

    // --- Advanced & Trendy Features ---

    /// @notice Allows collective members to create curated NFT collections.
    /// @param _collectionName Name of the curated collection.
    function createCuratedCollection(string memory _collectionName) public onlyCollectiveMembers {
        collectionCounter++;
        curatedCollections[collectionCounter] = CuratedCollection({
            name: _collectionName,
            nftIds: new uint256[](0),
            curator: msg.sender
        });
        emit CuratedCollectionCreated(collectionCounter, _collectionName, msg.sender);
    }

    /// @notice Allows curators to add NFTs to curated collections.
    /// @param _nftId ID of the NFT to add to the collection.
    /// @param _collectionId ID of the curated collection.
    function addNFTToCollection(uint256 _nftId, uint256 _collectionId)
        public
        onlyCollectiveMembers // Or only curator of collection
        validNFTId(_nftId)
        validCollectionId(_collectionId)
    {
        // In a real implementation, might check if NFT already in collection or meets criteria.
        curatedCollections[_collectionId].nftIds.push(_nftId);
        emit NFTAddedToCollection(_nftId, _collectionId);
    }

    /// @notice Allows members to stake ETH to increase their voting power in proposals.
    function stakeForVotingPower() public payable onlyCollectiveMembers {
        require(msg.value > 0, "Stake amount must be greater than zero.");
        stakingBalance[msg.sender] += msg.value;
        emit StakingIncreased(msg.sender, msg.value);
    }

    /// @notice Allows members to unstake ETH and reclaim it.
    function unstakeVotingPower(uint256 _amount) public onlyCollectiveMembers {
        require(_amount > 0, "Unstake amount must be greater than zero.");
        require(stakingBalance[msg.sender] >= _amount, "Insufficient staking balance.");
        stakingBalance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit StakingDecreased(msg.sender, _amount);
    }

    /// @notice Internal function to get voting power of a member based on staking.
    function getVotingPower(address _member) internal view returns (uint256) {
        return 1 + (stakingBalance[_member] / 1 ether * stakingMultiplier); // Base power 1 + staked ETH * multiplier
    }

    /// @notice Admin function to set the platform fee percentage on NFT sales.
    /// @param _feePercentage New platform fee percentage (e.g., 5 for 5%).
    function setPlatformFeePercentage(uint256 _feePercentage) public onlyAdmin {
        require(_feePercentage <= 20, "Platform fee percentage cannot exceed 20%."); // Example limit
        platformFeePercentage = _feePercentage;
        emit PlatformFeePercentageSet(_feePercentage);
    }

    /// @notice Admin function to withdraw accumulated platform fees for collective use.
    function withdrawPlatformFees() public onlyAdmin {
        uint256 contractBalance = address(this).balance;
        uint256 withdrawableFees = contractBalance; // Assuming all contract balance is platform fees for now.
        require(withdrawableFees > 0, "No platform fees to withdraw.");
        payable(admin).transfer(withdrawableFees);
        emit PlatformFeesWithdrawn(withdrawableFees, admin);
    }

    /// @notice Allows users to report NFTs for policy violations.
    /// @param _nftId ID of the NFT being reported.
    /// @param _reportReason Reason for reporting the content.
    function reportContent(uint256 _nftId, string memory _reportReason) public validNFTId(_nftId) {
        reportCounter++;
        contentReports[reportCounter] = ContentReport({
            nftId: _nftId,
            reason: _reportReason,
            reporter: msg.sender,
            status: ReportStatus.Pending,
            voteCountRemove: 0,
            voteCountKeep: 0,
            votes: mapping(address => bool)()
        });
        emit ContentReportSubmitted(reportCounter, _nftId, msg.sender);
    }

    /// @notice Collective members vote on removing reported content.
    /// @param _reportId ID of the content report.
    /// @param _removeContent True to remove content, false to keep.
    function voteOnContentReport(uint256 _reportId, bool _removeContent)
        public
        onlyCollectiveMembers
        validReportId(_reportId)
        reportPending(_reportId)
    {
        require(!contentReports[_reportId].votes[msg.sender], "Member has already voted on this report.");
        contentReports[_reportId].votes[msg.sender] = true;

        if (_removeContent) {
            contentReports[_reportId].voteCountRemove += getVotingPower(msg.sender);
        } else {
            contentReports[_reportId].voteCountKeep += getVotingPower(msg.sender);
        }
        emit ContentReportVoted(_reportId, msg.sender, _removeContent);

        // Check if report should be automatically approved or rejected based on vote count
        if (contentReports[_reportId].voteCountRemove >= contentReportVoteThreshold) {
            contentReports[_reportId].status = ReportStatus.Approved;
            removeNFTContent(contentReports[_reportId].nftId); // Remove content if approved
        } else if (contentReports[_reportId].voteCountKeep >= contentReportVoteThreshold) {
            contentReports[_reportId].status = ReportStatus.Rejected;
        }
    }

    /// @notice Internal function to remove NFT content (simulated).
    /// @param _nftId ID of the NFT to remove content for.
    function removeNFTContent(uint256 _nftId) internal {
        // In a real scenario, this would involve actions like removing metadata from IPFS, etc.
        // For simplicity, we are just marking NFT as 'content removed' in name.
        nfts[_nftId].ipfsHash = "Content Removed - Policy Violation";
        emit ContentRemoved(_nftId);
    }
}
```