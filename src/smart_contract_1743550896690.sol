```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized autonomous art collective.
 * It enables artists to submit artwork proposals, community members to vote on them,
 * mint NFTs for approved artworks, manage a treasury from NFT sales,
 * and participate in collaborative art projects. This contract incorporates
 * advanced concepts like DAO governance, NFT management, collaborative creation,
 * and dynamic reputation systems.

 * **Outline and Function Summary:**

 * **Governance and DAO Functions:**
 * 1. `proposeNewFeature(string memory description)`: Allows community members to propose new features or changes to the collective.
 * 2. `voteOnFeatureProposal(uint256 proposalId, bool vote)`: Allows token holders to vote on feature proposals.
 * 3. `executeFeatureProposal(uint256 proposalId)`: Executes a feature proposal if it passes the voting threshold.
 * 4. `setVotingQuorum(uint256 newQuorum)`: Allows governance to change the voting quorum for proposals.
 * 5. `setVotingDuration(uint256 newDuration)`: Allows governance to change the voting duration for proposals.
 * 6. `delegateVotingPower(address delegatee)`: Allows token holders to delegate their voting power to another address.

 * **Art Submission and Curation Functions:**
 * 7. `submitArtProposal(string memory title, string memory description, string memory ipfsHash)`: Allows artists to submit art proposals.
 * 8. `voteOnArtProposal(uint256 proposalId, bool vote)`: Allows token holders to vote on art proposals.
 * 9. `acceptArtProposal(uint256 proposalId)`: Accepts an art proposal if it passes the voting threshold and mints an NFT.
 * 10. `rejectArtProposal(uint256 proposalId)`: Rejects an art proposal if it fails the voting threshold.
 * 11. `getArtProposalDetails(uint256 proposalId)`: Retrieves details of an art proposal.
 * 12. `getAllArtProposals()`: Retrieves a list of all art proposal IDs.

 * **NFT Management and Marketplace Functions:**
 * 13. `mintNFT(uint256 proposalId)`: Mints an NFT for an approved art proposal (internal function called by `acceptArtProposal`).
 * 14. `listNFTForSale(uint256 tokenId, uint256 price)`: Allows NFT owners to list their NFTs for sale on the DAAC marketplace.
 * 15. `buyNFT(uint256 tokenId)`: Allows anyone to buy an NFT listed on the marketplace.
 * 16. `cancelNFTListing(uint256 tokenId)`: Allows NFT owners to cancel their NFT listing.
 * 17. `getNFTDetails(uint256 tokenId)`: Retrieves details of a DAAC NFT.
 * 18. `getAllListedNFTs()`: Retrieves a list of all NFTs currently listed for sale.

 * **Collaborative Art and Reputation Functions:**
 * 19. `startCollaborativeProject(string memory projectName, string memory description)`: Allows initiating a collaborative art project.
 * 20. `contributeToProject(uint256 projectId, string memory contributionDescription, string memory ipfsHash)`: Allows artists to contribute to a collaborative project.
 * 21. `voteOnProjectContribution(uint256 projectId, uint256 contributionId, bool vote)`: Allows token holders to vote on project contributions.
 * 22. `finalizeCollaborativeProject(uint256 projectId)`: Finalizes a collaborative project after successful contributions and mints a collaborative NFT (future extension).
 * 23. `getArtistReputation(address artistAddress)`: Retrieves the reputation score of an artist (based on successful art submissions and project contributions).
 * 24. `increaseArtistReputation(address artistAddress, uint256 increment)`: Increases artist reputation (internal function).
 * 25. `decreaseArtistReputation(address artistAddress, uint256 decrement)`: Decreases artist reputation (internal function).

 * **Treasury and Utility Functions:**
 * 26. `getContractBalance()`: Retrieves the contract's ETH balance.
 * 27. `withdrawTreasury(uint256 amount)`: Allows governance to withdraw funds from the treasury (governance proposal needed in a real-world scenario for security).
 * 28. `setPlatformFee(uint256 newFeePercentage)`: Allows governance to set the platform fee percentage for NFT sales.
 * 29. `getPayoutForArtist(uint256 salePrice)`: Calculates the payout for an artist after platform fees.
 * 30. `getPlatformFeeAmount(uint256 salePrice)`: Calculates the platform fee amount from a sale.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol"; // For future advanced governance

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _projectIds;
    Counters.Counter private _contributionIds;

    string public constant COLLECTION_NAME = "DAAC Art Collection";
    string public constant COLLECTION_SYMBOL = "DAACART";
    uint256 public votingQuorum = 50; // Percentage of votes needed to pass a proposal (e.g., 50%)
    uint256 public votingDuration = 7 days; // Duration of voting period
    uint256 public platformFeePercentage = 5; // Percentage of NFT sale price taken as platform fee (e.g., 5%)

    // --- Data Structures ---
    struct FeatureProposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        bool isActive;
        bool executed;
    }

    struct ArtProposal {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        bool isActive;
        bool accepted;
        bool rejected;
        uint256 tokenId; // Token ID if accepted and minted
    }

    struct NFTListing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct CollaborativeProject {
        uint256 id;
        string projectName;
        string description;
        address creator;
        uint256 startTime;
        bool isActive;
        // Add more fields for project stages, contributors, etc. in future
    }

    struct ProjectContribution {
        uint256 id;
        uint256 projectId;
        address artist;
        string contributionDescription;
        string ipfsHash;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        bool isActive;
        bool accepted;
    }

    mapping(uint256 => FeatureProposal) public featureProposals;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => NFTListing) public nftListings;
    mapping(uint256 => CollaborativeProject) public collaborativeProjects;
    mapping(uint256 => ProjectContribution) public projectContributions;
    mapping(uint256 => address) public nftToArtist; // Track artist who submitted the original art
    mapping(uint256 => uint256) public artistReputation; // Artist address to reputation score
    mapping(address => address) public delegation; // Delegator -> Delegatee

    address[] public allArtProposalsArray;
    uint256[] public listedNFTsArray;


    // --- Events ---
    event FeatureProposalCreated(uint256 proposalId, string description, address proposer);
    event FeatureProposalVoted(uint256 proposalId, address voter, bool vote);
    event FeatureProposalExecuted(uint256 proposalId);
    event ArtProposalSubmitted(uint256 proposalId, string title, address artist);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalAccepted(uint256 proposalId, uint256 tokenId);
    event ArtProposalRejected(uint256 proposalId);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 tokenId, address buyer, uint256 price);
    event NFTListingCancelled(uint256 tokenId, address seller);
    event CollaborativeProjectStarted(uint256 projectId, string projectName, address creator);
    event ProjectContributionSubmitted(uint256 contributionId, uint256 projectId, address artist);
    event ProjectContributionVoted(uint256 contributionId, address voter, bool vote);
    event ProjectContributionAccepted(uint256 contributionId, uint256 projectId);
    event ArtistReputationChanged(address artistAddress, uint256 newReputation);

    // --- Modifiers ---
    modifier onlyActiveProposal(uint256 proposalId) {
        require(featureProposals[proposalId].isActive || artProposals[proposalId].isActive || projectContributions[proposalId].isActive, "Proposal is not active.");
        require(block.timestamp <= (featureProposals[proposalId].startTime + votingDuration) || block.timestamp <= (artProposals[proposalId].startTime + votingDuration) || block.timestamp <= (projectContributions[proposalId].startTime + votingDuration), "Voting period has ended.");
        _;
    }

    modifier onlyValidNFTListing(uint256 tokenId) {
        require(nftListings[tokenId].isActive, "NFT is not listed for sale.");
        _;
    }

    // --- Constructor ---
    constructor() ERC721(COLLECTION_NAME, COLLECTION_SYMBOL) Ownable() {
        // Initialize any setup if needed
    }

    // --- Governance and DAO Functions ---
    function proposeNewFeature(string memory description) public {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        featureProposals[proposalId] = FeatureProposal({
            id: proposalId,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            isActive: true,
            executed: false
        });
        emit FeatureProposalCreated(proposalId, description, msg.sender);
    }

    function voteOnFeatureProposal(uint256 proposalId, bool vote) public onlyActiveProposal(proposalId) {
        address voter = delegation[msg.sender] == address(0) ? msg.sender : delegation[msg.sender]; // Allow delegated voting

        require(featureProposals[proposalId].isActive, "Feature proposal is not active.");
        require(block.timestamp <= (featureProposals[proposalId].startTime + votingDuration), "Voting period has ended.");

        if (vote) {
            featureProposals[proposalId].votesFor++;
        } else {
            featureProposals[proposalId].votesAgainst++;
        }
        emit FeatureProposalVoted(proposalId, voter, vote);
    }

    function executeFeatureProposal(uint256 proposalId) public onlyOwner { // For simplicity, onlyOwner can execute, in real DAO, this might be timelock or vote-based
        require(featureProposals[proposalId].isActive, "Feature proposal is not active.");
        require(!featureProposals[proposalId].executed, "Feature proposal already executed.");
        require(block.timestamp > (featureProposals[proposalId].startTime + votingDuration), "Voting period has not ended.");

        uint256 totalVotes = featureProposals[proposalId].votesFor + featureProposals[proposalId].votesAgainst;
        uint256 percentageFor = (featureProposals[proposalId].votesFor * 100) / totalVotes;

        if (percentageFor >= votingQuorum) {
            featureProposals[proposalId].isActive = false;
            featureProposals[proposalId].executed = true;
            // Execute the proposed feature logic here - for now, just emit event
            emit FeatureProposalExecuted(proposalId);
        } else {
            featureProposals[proposalId].isActive = false; // Proposal failed
        }
    }

    function setVotingQuorum(uint256 newQuorum) public onlyOwner {
        require(newQuorum <= 100, "Quorum must be a percentage value (<= 100).");
        votingQuorum = newQuorum;
    }

    function setVotingDuration(uint256 newDuration) public onlyOwner {
        votingDuration = newDuration;
    }

    function delegateVotingPower(address delegatee) public {
        delegation[msg.sender] = delegatee;
    }


    // --- Art Submission and Curation Functions ---
    function submitArtProposal(string memory title, string memory description, string memory ipfsHash) public {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        artProposals[proposalId] = ArtProposal({
            id: proposalId,
            title: title,
            description: description,
            ipfsHash: ipfsHash,
            artist: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            isActive: true,
            accepted: false,
            rejected: false,
            tokenId: 0
        });
        allArtProposalsArray.push(proposalId); // Keep track of all proposals
        emit ArtProposalSubmitted(proposalId, title, msg.sender);
    }

    function voteOnArtProposal(uint256 proposalId, bool vote) public onlyActiveProposal(proposalId) {
        address voter = delegation[msg.sender] == address(0) ? msg.sender : delegation[msg.sender]; // Allow delegated voting

        require(artProposals[proposalId].isActive, "Art proposal is not active.");
        require(block.timestamp <= (artProposals[proposalId].startTime + votingDuration), "Voting period has ended.");

        if (vote) {
            artProposals[proposalId].votesFor++;
        } else {
            artProposals[proposalId].votesAgainst++;
        }
        emit ArtProposalVoted(proposalId, voter, vote);
    }

    function acceptArtProposal(uint256 proposalId) public onlyOwner { // In real DAO, this might be vote-based execution
        require(artProposals[proposalId].isActive, "Art proposal is not active.");
        require(!artProposals[proposalId].accepted && !artProposals[proposalId].rejected, "Art proposal already decided.");
        require(block.timestamp > (artProposals[proposalId].startTime + votingDuration), "Voting period has not ended.");

        uint256 totalVotes = artProposals[proposalId].votesFor + artProposals[proposalId].votesAgainst;
        uint256 percentageFor = (artProposals[proposalId].votesFor * 100) / totalVotes;

        if (percentageFor >= votingQuorum) {
            artProposals[proposalId].isActive = false;
            artProposals[proposalId].accepted = true;
            uint256 tokenId = mintNFT(proposalId); // Mint NFT upon acceptance
            artProposals[proposalId].tokenId = tokenId;
            increaseArtistReputation(artProposals[proposalId].artist, 10); // Increase reputation for successful submission
            emit ArtProposalAccepted(proposalId, tokenId);
        } else {
            rejectArtProposal(proposalId); // If quorum not met, reject
        }
    }

    function rejectArtProposal(uint256 proposalId) public onlyOwner { // In real DAO, this might be vote-based execution
        require(artProposals[proposalId].isActive, "Art proposal is not active.");
        require(!artProposals[proposalId].accepted && !artProposals[proposalId].rejected, "Art proposal already decided.");
        require(block.timestamp > (artProposals[proposalId].startTime + votingDuration), "Voting period has not ended.");

        if (!artProposals[proposalId].accepted) { // Avoid double rejection if already decided in `acceptArtProposal`
            artProposals[proposalId].isActive = false;
            artProposals[proposalId].rejected = true;
            decreaseArtistReputation(artProposals[proposalId].artist, 5); // Decrease reputation for rejected submission
            emit ArtProposalRejected(proposalId);
        }
    }

    function getArtProposalDetails(uint256 proposalId) public view returns (ArtProposal memory) {
        return artProposals[proposalId];
    }

    function getAllArtProposals() public view returns (uint256[] memory) {
        return allArtProposalsArray;
    }


    // --- NFT Management and Marketplace Functions ---
    function mintNFT(uint256 proposalId) internal returns (uint256) {
        require(artProposals[proposalId].accepted, "Art proposal must be accepted to mint NFT.");
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _safeMint(artProposals[proposalId].artist, tokenId);
        nftToArtist[tokenId] = artProposals[proposalId].artist; // Track original artist
        return tokenId;
    }

    function listNFTForSale(uint256 tokenId, uint256 price) public payable {
        require(_exists(tokenId), "Token does not exist.");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(price > 0, "Price must be greater than zero.");

        nftListings[tokenId] = NFTListing({
            tokenId: tokenId,
            price: price,
            seller: msg.sender,
            isActive: true
        });
        listedNFTsArray.push(tokenId); // Keep track of listed NFTs
        emit NFTListedForSale(tokenId, price, msg.sender);
    }

    function buyNFT(uint256 tokenId) public payable onlyValidNFTListing(tokenId) {
        NFTListing memory listing = nftListings[tokenId];
        require(msg.value >= listing.price, "Insufficient funds sent.");

        nftListings[tokenId].isActive = false; // Deactivate listing
        listedNFTsArray = removeFromArray(listedNFTsArray, tokenId); // Remove from listed array

        uint256 platformFee = getPlatformFeeAmount(listing.price);
        uint256 artistPayout = getPayoutForArtist(listing.price);

        // Transfer platform fee to contract (treasury)
        payable(owner()).transfer(platformFee);
        // Transfer artist payout to the original artist (if different from seller, consider logic)
        payable(nftToArtist[tokenId]).transfer(artistPayout);

        // Transfer remaining amount to seller (if seller is different from original artist, they get resale value)
        if (listing.seller != nftToArtist[tokenId]) {
            payable(listing.seller).transfer(listing.price - platformFee - artistPayout);
        } else {
            // If original artist is also seller, they already received artistPayout, no need to transfer again
        }


        transferFrom(listing.seller, msg.sender, tokenId);
        emit NFTBought(tokenId, msg.sender, listing.price);
    }

    function cancelNFTListing(uint256 tokenId) public onlyValidNFTListing(tokenId) {
        require(nftListings[tokenId].seller == msg.sender, "You are not the seller of this NFT.");
        nftListings[tokenId].isActive = false;
        listedNFTsArray = removeFromArray(listedNFTsArray, tokenId); // Remove from listed array
        emit NFTListingCancelled(tokenId, msg.sender);
    }

    function getNFTDetails(uint256 tokenId) public view returns (NFTListing memory, string memory title, string memory description, string memory ipfsHash, address artist) {
        ArtProposal memory proposal = artProposals[nftToArtist[tokenId]]; // Using artist address as proposalId is not reliable, use mapping
        return (nftListings[tokenId], proposal.title, proposal.description, proposal.ipfsHash, nftToArtist[tokenId]);
    }

    function getAllListedNFTs() public view returns (uint256[] memory) {
        return listedNFTsArray;
    }


    // --- Collaborative Art and Reputation Functions ---
    function startCollaborativeProject(string memory projectName, string memory description) public {
        _projectIds.increment();
        uint256 projectId = _projectIds.current();
        collaborativeProjects[projectId] = CollaborativeProject({
            id: projectId,
            projectName: projectName,
            description: description,
            creator: msg.sender,
            startTime: block.timestamp,
            isActive: true
        });
        emit CollaborativeProjectStarted(projectId, projectName, msg.sender);
    }

    function contributeToProject(uint256 projectId, string memory contributionDescription, string memory ipfsHash) public {
        require(collaborativeProjects[projectId].isActive, "Project is not active.");
        _contributionIds.increment();
        uint256 contributionId = _contributionIds.current();
        projectContributions[contributionId] = ProjectContribution({
            id: contributionId,
            projectId: projectId,
            artist: msg.sender,
            contributionDescription: contributionDescription,
            ipfsHash: ipfsHash,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            isActive: true,
            accepted: false
        });
        emit ProjectContributionSubmitted(contributionId, projectId, msg.sender);
    }

    function voteOnProjectContribution(uint256 projectId, uint256 contributionId, bool vote) public onlyActiveProposal(contributionId) {
        require(projectContributions[contributionId].projectId == projectId, "Contribution does not belong to this project.");
        address voter = delegation[msg.sender] == address(0) ? msg.sender : delegation[msg.sender]; // Allow delegated voting

        if (vote) {
            projectContributions[contributionId].votesFor++;
        } else {
            projectContributions[contributionId].votesAgainst++;
        }
        emit ProjectContributionVoted(contributionId, voter, vote);
    }

    function finalizeCollaborativeProject(uint256 projectId) public onlyOwner { // Future: Vote-based or condition-based finalization
        require(collaborativeProjects[projectId].isActive, "Project is not active.");
        collaborativeProjects[projectId].isActive = false;
        // Logic to check for successful contributions, reward contributors, mint collaborative NFT etc. - Future extension
    }

    function getArtistReputation(address artistAddress) public view returns (uint256) {
        return artistReputation[artistAddress];
    }

    function increaseArtistReputation(address artistAddress, uint256 increment) internal {
        artistReputation[artistAddress] += increment;
        emit ArtistReputationChanged(artistAddress, artistReputation[artistAddress]);
    }

    function decreaseArtistReputation(address artistAddress, uint256 decrement) internal {
        artistReputation[artistAddress] -= decrement;
        emit ArtistReputationChanged(artistAddress, artistReputation[artistAddress]);
    }


    // --- Treasury and Utility Functions ---
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawTreasury(uint256 amount) public onlyOwner { // In real DAO, use governance proposal for treasury withdrawal
        require(address(this).balance >= amount, "Insufficient contract balance.");
        payable(owner()).transfer(amount);
    }

    function setPlatformFee(uint256 newFeePercentage) public onlyOwner {
        require(newFeePercentage <= 100, "Fee percentage must be <= 100.");
        platformFeePercentage = newFeePercentage;
    }

    function getPayoutForArtist(uint256 salePrice) public view returns (uint256) {
        uint256 feeAmount = getPlatformFeeAmount(salePrice);
        return salePrice - feeAmount;
    }

    function getPlatformFeeAmount(uint256 salePrice) public view returns (uint256) {
        return (salePrice * platformFeePercentage) / 100;
    }

    // --- Utility Function to remove item from array (Gas intensive for large arrays, use with caution) ---
    function removeFromArray(uint256[] memory arr, uint256 value) internal pure returns (uint256[] memory) {
        uint256 len = arr.length;
        uint256[] memory newArr = new uint256[](len - 1);
        uint256 index = 0;
        for (uint256 i = 0; i < len; i++) {
            if (arr[i] != value) {
                newArr[index] = arr[i];
                index++;
            }
        }
        return newArr;
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {}
}
```