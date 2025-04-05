```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective, enabling artists to submit, curate, and monetize their digital art through NFTs.
 *
 * Outline and Function Summary:
 *
 * 1.  **Membership Management:**
 *     - `joinCollective()`: Allows artists and art enthusiasts to become members of the collective.
 *     - `leaveCollective()`: Allows members to leave the collective.
 *     - `getMemberDetails(address _member)`: Retrieves details of a specific member.
 *     - `isMember(address _account)`: Checks if an address is a member.
 *     - `getMemberCount()`: Returns the total number of members in the collective.
 *
 * 2.  **Artwork Submission and Curation:**
 *     - `submitArtwork(string memory _artworkCID, string memory _metadataCID)`: Allows members to submit their artwork with IPFS CID for artwork and metadata.
 *     - `voteOnArtwork(uint256 _artworkId, bool _approve)`: Members can vote to approve or reject submitted artworks for inclusion in the official collection.
 *     - `getCurationStatus(uint256 _artworkId)`: Returns the current curation status (pending, approved, rejected) of an artwork.
 *     - `getCurationVotes(uint256 _artworkId)`: Returns the current approval and rejection vote counts for an artwork.
 *     - `finalizeCuration(uint256 _artworkId)`: Finalizes the curation process for an artwork after a voting period, automatically approving or rejecting based on quorum.
 *     - `getArtworkDetails(uint256 _artworkId)`: Retrieves details of a specific artwork.
 *     - `getPendingArtworkCount()`: Returns the number of artworks currently in the curation process.
 *
 * 3.  **NFT Minting and Marketplace:**
 *     - `mintNFT(uint256 _artworkId)`: Mints an NFT for an approved artwork, making it part of the official collective collection. Only callable after curation is finalized and approved.
 *     - `setNFTPrice(uint256 _nftId, uint256 _price)`: Allows the NFT owner (initially the collective, then buyer) to set the price of an NFT for sale.
 *     - `buyNFT(uint256 _nftId)`: Allows anyone to purchase an NFT listed for sale. Transfers ownership and distributes revenue.
 *     - `unlistNFT(uint256 _nftId)`: Allows the NFT owner to remove an NFT from the marketplace, making it not for sale.
 *     - `getNFTPrice(uint256 _nftId)`: Retrieves the current price of an NFT if it's listed for sale.
 *     - `isNFTListed(uint256 _nftId)`: Checks if an NFT is currently listed for sale.
 *     - `getNFTOwner(uint256 _nftId)`: Returns the current owner of an NFT.
 *
 * 4.  **Revenue Sharing and Collective Treasury:**
 *     - `withdrawCollectiveFunds()`: Allows the contract owner to withdraw funds accumulated in the collective treasury (e.g., from NFT sales commissions).  (Can be adapted for DAO governance later).
 *     - `getCollectiveTreasuryBalance()`: Returns the current balance of the collective treasury.
 *     - `setCommissionRate(uint256 _rate)`: Allows the contract owner to set the commission rate taken by the collective from NFT sales.
 *
 * 5.  **Governance and Parameters (Simple for now, can be expanded):**
 *     - `setCurationThreshold(uint256 _thresholdPercentage)`: Allows the contract owner to set the percentage of votes required for artwork approval.
 *     - `setCurationDuration(uint256 _durationInBlocks)`: Allows the contract owner to set the duration of the artwork curation voting period.
 *     - `pauseContract()`: Allows the contract owner to pause the contract in case of emergency.
 *     - `unpauseContract()`: Allows the contract owner to unpause the contract.
 *     - `isContractPaused()`: Checks if the contract is currently paused.
 */

contract DecentralizedArtCollective {
    // --- Structs ---
    struct Member {
        address memberAddress;
        uint256 joinTimestamp;
        string profileCID; // Optional: IPFS CID for member profile/portfolio
        bool isActive;
    }

    struct Artwork {
        uint256 artworkId;
        address artist;
        string artworkCID; // IPFS CID for the artwork file itself
        string metadataCID; // IPFS CID for artwork metadata (title, description, etc.)
        uint256 submissionTimestamp;
        CurationStatus curationStatus;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 curationEndTime;
        bool isNFTMinted;
    }

    struct NFTListing {
        uint256 nftId;
        uint256 price;
        bool isListed;
    }

    enum CurationStatus {
        PENDING,
        APPROVED,
        REJECTED
    }

    // --- State Variables ---
    address public owner;
    mapping(address => Member) public members;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => NFTListing) public nftListings;
    mapping(uint256 => address) public nftOwners; // Tracks NFT ownership (NFT ID => Owner Address)

    uint256 public memberCount;
    uint256 public artworkIdCounter;
    uint256 public nftIdCounter;

    uint256 public curationThresholdPercentage = 60; // Percentage of votes needed for approval
    uint256 public curationDurationBlocks = 100; // Duration of curation period in blocks
    uint256 public commissionRatePercentage = 5; // Percentage taken from NFT sales for the collective

    bool public contractPaused;

    // --- Events ---
    event MemberJoined(address memberAddress, uint256 timestamp);
    event MemberLeft(address memberAddress, uint256 timestamp);
    event ArtworkSubmitted(uint256 artworkId, address artist, string artworkCID, string metadataCID, uint256 timestamp);
    event ArtworkVoted(uint256 artworkId, address voter, bool approved, uint256 timestamp);
    event CurationFinalized(uint256 artworkId, CurationStatus status, uint256 timestamp);
    event NFTMinted(uint256 nftId, uint256 artworkId, address minter, uint256 timestamp);
    event NFTListedForSale(uint256 nftId, uint256 price, uint256 timestamp);
    event NFTSold(uint256 nftId, address buyer, uint256 price, uint256 timestamp);
    event NFTUnlisted(uint256 nftId, uint256 timestamp);
    event CommissionRateSet(uint256 newRatePercentage, uint256 timestamp);
    event CurationThresholdSet(uint256 newThresholdPercentage, uint256 timestamp);
    event CurationDurationSet(uint256 newDurationBlocks, uint256 timestamp);
    event ContractPaused(address pauser, uint256 timestamp);
    event ContractUnpaused(address unpauser, uint256 timestamp);
    event CollectiveFundsWithdrawn(address withdrawer, uint256 amount, uint256 timestamp);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= artworkIdCounter && artworks[_artworkId].artworkId == _artworkId, "Artwork does not exist.");
        _;
    }

    modifier nftExists(uint256 _nftId) {
        require(_nftId > 0 && _nftId <= nftIdCounter && nftOwners[_nftId] != address(0), "NFT does not exist.");
        _;
    }

    modifier onlyNFTOwner(uint256 _nftId) {
        require(nftOwners[_nftId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier curationPending(uint256 _artworkId) {
        require(artworks[_artworkId].curationStatus == CurationStatus.PENDING, "Curation is not pending for this artwork.");
        _;
    }

    modifier curationFinalized(uint256 _artworkId) {
        require(artworks[_artworkId].curationStatus != CurationStatus.PENDING, "Curation is still pending for this artwork.");
        _;
    }

    modifier curationApproved(uint256 _artworkId) {
        require(artworks[_artworkId].curationStatus == CurationStatus.APPROVED, "Artwork curation was not approved.");
        _;
    }

    modifier notNFTMinted(uint256 _artworkId) {
        require(!artworks[_artworkId].isNFTMinted, "NFT already minted for this artwork.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        memberCount = 0;
        artworkIdCounter = 0;
        nftIdCounter = 0;
        contractPaused = false;
    }

    // --- 1. Membership Management ---
    function joinCollective(string memory _profileCID) external notPaused {
        require(!isMember(msg.sender), "Already a member.");
        memberCount++;
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            joinTimestamp: block.timestamp,
            profileCID: _profileCID,
            isActive: true
        });
        emit MemberJoined(msg.sender, block.timestamp);
    }

    function leaveCollective() external onlyMember notPaused {
        require(members[msg.sender].isActive, "Not an active member.");
        members[msg.sender].isActive = false;
        memberCount--;
        emit MemberLeft(msg.sender, block.timestamp);
    }

    function getMemberDetails(address _member) external view returns (Member memory) {
        require(isMember(_member), "Not a member.");
        return members[_member];
    }

    function isMember(address _account) public view returns (bool) {
        return members[_account].isActive;
    }

    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }

    // --- 2. Artwork Submission and Curation ---
    function submitArtwork(string memory _artworkCID, string memory _metadataCID) external onlyMember notPaused {
        artworkIdCounter++;
        artworks[artworkIdCounter] = Artwork({
            artworkId: artworkIdCounter,
            artist: msg.sender,
            artworkCID: _artworkCID,
            metadataCID: _metadataCID,
            submissionTimestamp: block.timestamp,
            curationStatus: CurationStatus.PENDING,
            approvalVotes: 0,
            rejectionVotes: 0,
            curationEndTime: block.number + curationDurationBlocks,
            isNFTMinted: false
        });
        emit ArtworkSubmitted(artworkIdCounter, msg.sender, _artworkCID, _metadataCID, block.timestamp);
    }

    function voteOnArtwork(uint256 _artworkId, bool _approve) external onlyMember notPaused artworkExists(_artworkId) curationPending(_artworkId) {
        require(block.number <= artworks[_artworkId].curationEndTime, "Curation period has ended.");
        if (_approve) {
            artworks[_artworkId].approvalVotes++;
        } else {
            artworks[_artworkId].rejectionVotes++;
        }
        emit ArtworkVoted(_artworkId, msg.sender, _approve, block.timestamp);
    }

    function getCurationStatus(uint256 _artworkId) external view artworkExists(_artworkId) returns (CurationStatus) {
        return artworks[_artworkId].curationStatus;
    }

    function getCurationVotes(uint256 _artworkId) external view artworkExists(_artworkId) returns (uint256 approvals, uint256 rejections) {
        return (artworks[_artworkId].approvalVotes, artworks[_artworkId].rejectionVotes);
    }

    function finalizeCuration(uint256 _artworkId) external notPaused artworkExists(_artworkId) curationPending(_artworkId) {
        require(block.number > artworks[_artworkId].curationEndTime, "Curation period has not ended yet.");
        uint256 totalVotes = artworks[_artworkId].approvalVotes + artworks[_artworkId].rejectionVotes;
        CurationStatus finalStatus;
        if (totalVotes == 0) {
            finalStatus = CurationStatus.REJECTED; // Default to reject if no votes
        } else {
            uint256 approvalPercentage = (artworks[_artworkId].approvalVotes * 100) / totalVotes;
            if (approvalPercentage >= curationThresholdPercentage) {
                finalStatus = CurationStatus.APPROVED;
            } else {
                finalStatus = CurationStatus.REJECTED;
            }
        }
        artworks[_artworkId].curationStatus = finalStatus;
        emit CurationFinalized(_artworkId, finalStatus, block.timestamp);
    }

    function getArtworkDetails(uint256 _artworkId) external view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getPendingArtworkCount() external view returns (uint256) {
        uint256 pendingCount = 0;
        for (uint256 i = 1; i <= artworkIdCounter; i++) {
            if (artworks[i].curationStatus == CurationStatus.PENDING) {
                pendingCount++;
            }
        }
        return pendingCount;
    }

    // --- 3. NFT Minting and Marketplace ---
    function mintNFT(uint256 _artworkId) external onlyOwner notPaused artworkExists(_artworkId) curationFinalized(_artworkId) curationApproved(_artworkId) notNFTMinted(_artworkId) {
        nftIdCounter++;
        nftOwners[nftIdCounter] = address(this); // Collective initially owns the NFT
        artworks[_artworkId].isNFTMinted = true;
        emit NFTMinted(nftIdCounter, _artworkId, msg.sender, block.timestamp);
    }

    function setNFTPrice(uint256 _nftId, uint256 _price) external notPaused nftExists(_nftId) onlyNFTOwner(_nftId) {
        require(_price > 0, "Price must be greater than zero.");
        nftListings[_nftId] = NFTListing({
            nftId: _nftId,
            price: _price,
            isListed: true
        });
        emit NFTListedForSale(_nftId, _price, block.timestamp);
    }

    function buyNFT(uint256 _nftId) external payable notPaused nftExists(_nftId) {
        require(nftListings[_nftId].isListed, "NFT is not listed for sale.");
        require(msg.value >= nftListings[_nftId].price, "Insufficient payment.");

        uint256 price = nftListings[_nftId].price;
        address currentOwner = nftOwners[_nftId];

        nftOwners[_nftId] = msg.sender; // Transfer ownership
        nftListings[_nftId].isListed = false; // Unlist after purchase

        uint256 commissionAmount = (price * commissionRatePercentage) / 100;
        uint256 artistShare = price - commissionAmount;

        // Send funds
        payable(artworks[getArtworkIdFromNFTId(_nftId)].artist).transfer(artistShare); // Send to artist
        payable(owner).transfer(commissionAmount); // Send commission to collective treasury (owner as proxy for now, can be a DAO wallet later)

        emit NFTSold(_nftId, msg.sender, price, block.timestamp);

        // Refund any extra payment
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function unlistNFT(uint256 _nftId) external notPaused nftExists(_nftId) onlyNFTOwner(_nftId) {
        require(nftListings[_nftId].isListed, "NFT is not listed.");
        nftListings[_nftId].isListed = false;
        emit NFTUnlisted(_nftId, block.timestamp);
    }

    function getNFTPrice(uint256 _nftId) external view nftExists(_nftId) returns (uint256) {
        return nftListings[_nftId].price;
    }

    function isNFTListed(uint256 _nftId) external view nftExists(_nftId) returns (bool) {
        return nftListings[_nftId].isListed;
    }

    function getNFTOwner(uint256 _nftId) external view nftExists(_nftId) returns (address) {
        return nftOwners[_nftId];
    }

    function getArtworkIdFromNFTId(uint256 _nftId) internal view nftExists(_nftId) returns (uint256) {
        for (uint256 i = 1; i <= artworkIdCounter; i++) {
            if (artworks[i].isNFTMinted && getNftIdForArtworkId(i) == _nftId) { // Assumes NFTs are minted in order of artworkId
                return i;
            }
        }
        revert("Artwork ID not found for NFT ID."); // Should not happen if NFT exists is checked
    }

    function getNftIdForArtworkId(uint256 _artworkId) internal view artworkExists(_artworkId) returns (uint256) {
        uint256 nftCounter = 0;
        for (uint256 i = 1; i <= artworkIdCounter; i++) {
            if (artworks[i].isNFTMinted) {
                nftCounter++;
                if (i == _artworkId) {
                    return nftCounter;
                }
            }
        }
        return 0; // Should not happen if artwork exists and isNFTMinted are checked beforehand if used correctly
    }

    // --- 4. Revenue Sharing and Collective Treasury ---
    function withdrawCollectiveFunds() external onlyOwner notPaused {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        payable(owner).transfer(balance);
        emit CollectiveFundsWithdrawn(owner, balance, block.timestamp);
    }

    function getCollectiveTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setCommissionRate(uint256 _ratePercentage) external onlyOwner notPaused {
        require(_ratePercentage <= 100, "Commission rate cannot exceed 100%.");
        commissionRatePercentage = _ratePercentage;
        emit CommissionRateSet(_ratePercentage, block.timestamp);
    }

    // --- 5. Governance and Parameters ---
    function setCurationThreshold(uint256 _thresholdPercentage) external onlyOwner notPaused {
        require(_thresholdPercentage <= 100, "Curation threshold cannot exceed 100%.");
        curationThresholdPercentage = _thresholdPercentage;
        emit CurationThresholdSet(_thresholdPercentage, block.timestamp);
    }

    function setCurationDuration(uint256 _durationInBlocks) external onlyOwner notPaused {
        curationDurationBlocks = _durationInBlocks;
        emit CurationDurationSet(_durationInBlocks, block.timestamp);
    }

    // --- 6. Pausable Functionality ---
    function pauseContract() external onlyOwner {
        contractPaused = true;
        emit ContractPaused(msg.sender, block.timestamp);
    }

    function unpauseContract() external onlyOwner {
        contractPaused = false;
        emit ContractUnpaused(msg.sender, block.timestamp);
    }

    function isContractPaused() external view returns (bool) {
        return contractPaused;
    }

    // --- Fallback and Receive (for direct ETH deposits to treasury - optional) ---
    receive() external payable {}
    fallback() external payable {}
}
```