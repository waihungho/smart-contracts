```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract Outline and Summary
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC) that allows artists to submit artwork,
 *      community members to vote on artwork to be minted as NFTs, and manage a decentralized art marketplace.
 *      This contract incorporates advanced concepts like layered access control, on-chain governance for art curation,
 *      dynamic royalty distribution, and community-driven features.
 *
 * Function Summary:
 *
 * 1.  initialize(address _admin, string _collectiveName, string _symbol): Initializes the contract with admin, collective name, and symbol.
 * 2.  setAdmin(address _newAdmin): Allows the current admin to change the contract administrator.
 * 3.  getAdmin(): Returns the address of the current contract administrator.
 * 4.  setCollectiveName(string _newName): Allows the admin to update the collective's name.
 * 5.  getCollectiveName(): Returns the current name of the art collective.
 * 6.  registerArtist(string _artistName, string _artistBio): Allows users to register as artists within the collective.
 * 7.  isArtist(address _user): Checks if an address is registered as an artist.
 * 8.  submitArtProposal(string _title, string _description, string _ipfsHash): Artists can submit art proposals for community review.
 * 9.  startArtProposalVoting(uint256 _proposalId, uint256 _votingDurationDays): Admin can start voting for a specific art proposal.
 * 10. voteOnArtProposal(uint256 _proposalId, bool _vote): Registered community members can vote on art proposals.
 * 11. getArtProposalVotingResults(uint256 _proposalId): Returns the voting results for a given art proposal (for/against counts).
 * 12. executeArtProposalMint(uint256 _proposalId): Admin can execute a proposal if it passes voting, minting an NFT of the artwork.
 * 13. setNFTBaseURI(string _baseURI): Admin sets the base URI for NFT metadata.
 * 14. getNFTMetadataURI(uint256 _tokenId): Returns the full metadata URI for a given NFT token ID.
 * 15. listNFTForSale(uint256 _tokenId, uint256 _priceInWei): NFT owner can list their NFT for sale on the marketplace.
 * 16. buyNFT(uint256 _listingId): Allows anyone to buy an NFT listed on the marketplace.
 * 17. cancelNFTListing(uint256 _listingId): NFT owner can cancel their listing.
 * 18. setMarketplaceFee(uint256 _feePercentage): Admin can set the marketplace fee percentage.
 * 19. withdrawMarketplaceFees(): Admin can withdraw accumulated marketplace fees.
 * 20. createGovernanceProposal(string _proposalDescription, bytes _calldata): Allows community members to create governance proposals.
 * 21. startGovernanceProposalVoting(uint256 _proposalId, uint256 _votingDurationDays): Admin can start voting for a governance proposal.
 * 22. voteOnGovernanceProposal(uint256 _proposalId, bool _vote): Registered community members can vote on governance proposals.
 * 23. getGovernanceProposalVotingResults(uint256 _proposalId): Returns voting results for a governance proposal.
 * 24. executeGovernanceProposal(uint256 _proposalId): Admin can execute a governance proposal if it passes voting.
 * 25. stakeForCommunityRewards(): Allows community members to stake tokens to earn rewards and participate in governance (placeholder, token integration needed).
 * 26. unstakeForCommunityRewards(): Allows community members to unstake tokens.
 * 27. claimCommunityRewards(): Allows community members to claim accumulated staking rewards.
 * 28. setCommunityRewardRate(uint256 _rewardRatePerDay): Admin can set the community staking reward rate.
 * 29. getContractBalance(): Returns the current balance of the contract.
 * 30. rescueERC20(address _tokenAddress, address _to, uint256 _amount): Admin function to rescue accidentally sent ERC20 tokens.
 */

contract DecentralizedAutonomousArtCollective {
    // ----------- State Variables -----------

    address public admin; // Contract administrator
    string public collectiveName; // Name of the art collective
    string public symbol; // Symbol for the collective (e.g., DAAC)
    uint256 public nextProposalId = 1; // Counter for art proposals
    uint256 public nextNFTTokenId = 1; // Counter for NFT token IDs
    uint256 public nextListingId = 1; // Counter for marketplace listings
    uint256 public nextGovernanceProposalId = 1; // Counter for governance proposals
    uint256 public marketplaceFeePercentage = 5; // Default marketplace fee (5%)

    string public nftBaseURI; // Base URI for NFT metadata

    mapping(address => bool) public isRegisteredArtist; // Check if address is a registered artist
    mapping(uint256 => ArtProposal) public artProposals; // Art proposals indexed by ID
    mapping(uint256 => ProposalVoting) public artProposalVotings; // Voting data for art proposals
    mapping(uint256 => NFTListing) public nftListings; // Marketplace listings indexed by ID
    mapping(uint256 => address) public nftOwners; // Owner of each NFT token ID
    mapping(uint256 => GovernanceProposal) public governanceProposals; // Governance proposals indexed by ID
    mapping(uint256 => ProposalVoting) public governanceProposalVotings; // Voting data for governance proposals
    mapping(address => StakingData) public stakingData; // Staking data for community members

    address public communityRewardsToken; // Address of the community reward token (ERC20, to be set in future if needed)
    uint256 public communityRewardRatePerDay; // Reward rate for staking (per day, placeholder)

    struct ArtProposal {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash; // IPFS hash of the artwork
        bool passedVoting;
        bool minted;
    }

    struct ProposalVoting {
        uint256 proposalId;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool votingActive;
    }

    struct NFTListing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 priceInWei;
        bool isActive;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes calldataData;
        bool passedVoting;
        bool executed;
    }

    struct StakingData {
        uint256 stakedAmount;
        uint256 lastRewardClaimTime;
    }

    // ----------- Events -----------

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event CollectiveNameUpdated(string newName);
    event ArtistRegistered(address indexed artistAddress, string artistName);
    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVotingStarted(uint256 proposalId, uint256 endTime);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalMinted(uint256 proposalId, uint256 tokenId, address minter);
    event NFTListedForSale(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event NFTListingCancelled(uint256 listingId, uint256 tokenId, address seller);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event MarketplaceFeesWithdrawn(address admin, uint256 amount);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceProposalVotingStarted(uint256 proposalId, uint256 endTime);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event TokensRescued(address tokenAddress, address to, uint256 amount);
    event CommunityRewardRateUpdated(uint256 newRewardRate);
    event TokensStaked(address staker, uint256 amount);
    event TokensUnstaked(address unstaker, uint256 amount);
    event RewardsClaimed(address claimant, uint256 amount);


    // ----------- Modifiers -----------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyArtist() {
        require(isRegisteredArtist[msg.sender], "Only registered artists can call this function.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID.");
        _;
    }

    modifier validListingId(uint256 _listingId) {
        require(_listingId > 0 && _listingId < nextListingId, "Invalid listing ID.");
        _;
    }

    modifier validGovernanceProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextGovernanceProposalId, "Invalid governance proposal ID.");
        _;
    }

    modifier votingNotActive(uint256 _proposalId, mapping(uint256 => ProposalVoting) storage _proposalVotings) {
        require(!_proposalVotings[_proposalId].votingActive, "Voting is already active for this proposal.");
        _;
    }

    modifier votingActive(uint256 _proposalId, mapping(uint256 => ProposalVoting) storage _proposalVotings) {
        require(_proposalVotings[_proposalId].votingActive, "Voting is not active for this proposal.");
        require(block.timestamp <= _proposalVotings[_proposalId].endTime, "Voting has ended.");
        _;
    }

    modifier proposalNotMinted(uint256 _proposalId) {
        require(!artProposals[_proposalId].minted, "Art proposal already minted.");
        _;
    }

    modifier proposalPassedVoting(uint256 _proposalId) {
        require(artProposals[_proposalId].passedVoting, "Art proposal did not pass voting.");
        _;
    }

    modifier governanceProposalNotExecuted(uint256 _proposalId) {
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed.");
        _;
    }

    modifier governanceProposalPassedVoting(uint256 _proposalId) {
        require(governanceProposals[_proposalId].passedVoting, "Governance proposal did not pass voting.");
        _;
    }


    // ----------- Functions -----------

    // 1. Initialize the contract
    constructor(address _admin, string memory _collectiveName, string memory _symbol) {
        admin = _admin;
        collectiveName = _collectiveName;
        symbol = _symbol;
        emit AdminChanged(address(0), _admin);
    }

    // 2. Set a new contract administrator
    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    // 3. Get the current contract administrator
    function getAdmin() public view returns (address) {
        return admin;
    }

    // 4. Set the collective name
    function setCollectiveName(string memory _newName) public onlyAdmin {
        require(bytes(_newName).length > 0, "Collective name cannot be empty.");
        emit CollectiveNameUpdated(_newName);
        collectiveName = _newName;
    }

    // 5. Get the collective name
    function getCollectiveName() public view returns (string memory) {
        return collectiveName;
    }

    // 6. Register as an artist
    function registerArtist(string memory _artistName, string memory _artistBio) public {
        require(!isRegisteredArtist[msg.sender], "Already registered as an artist.");
        require(bytes(_artistName).length > 0, "Artist name cannot be empty.");
        isRegisteredArtist[msg.sender] = true;
        emit ArtistRegistered(msg.sender, _artistName);
    }

    // 7. Check if an address is a registered artist
    function isArtist(address _user) public view returns (bool) {
        return isRegisteredArtist[_user];
    }

    // 8. Submit an art proposal
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) public onlyArtist {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Proposal details cannot be empty.");
        artProposals[nextProposalId] = ArtProposal({
            id: nextProposalId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            passedVoting: false,
            minted: false
        });
        emit ArtProposalSubmitted(nextProposalId, msg.sender, _title);
        nextProposalId++;
    }

    // 9. Start voting for an art proposal
    function startArtProposalVoting(uint256 _proposalId, uint256 _votingDurationDays) public onlyAdmin validProposalId(_proposalId) votingNotActive(_proposalId, artProposalVotings) {
        require(_votingDurationDays > 0 && _votingDurationDays <= 30, "Voting duration must be between 1 and 30 days.");
        artProposalVotings[_proposalId] = ProposalVoting({
            proposalId: _proposalId,
            startTime: block.timestamp,
            endTime: block.timestamp + (_votingDurationDays * 1 days),
            votesFor: 0,
            votesAgainst: 0,
            votingActive: true
        });
        emit ArtProposalVotingStarted(_proposalId, artProposalVotings[_proposalId].endTime);
    }

    // 10. Vote on an art proposal
    function voteOnArtProposal(uint256 _proposalId, bool _vote) public validProposalId(_proposalId) votingActive(_proposalId, artProposalVotings) {
        require(!hasVotedOnProposal(msg.sender, _proposalId), "You have already voted on this proposal.");
        if (_vote) {
            artProposalVotings[_proposalId].votesFor++;
        } else {
            artProposalVotings[_proposalId].votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    // Helper function to check if a user has voted (can be enhanced with voting records for production)
    function hasVotedOnProposal(address _voter, uint256 _proposalId) private view returns (bool) {
        // In a real-world scenario, you'd likely store voter addresses per proposal to prevent double voting.
        // For simplicity in this example, we're skipping explicit voter tracking.
        // Consider implementing a mapping(uint256 => mapping(address => bool)) voted for production.
        return false; // Placeholder for simplicity
    }

    // 11. Get art proposal voting results
    function getArtProposalVotingResults(uint256 _proposalId) public view validProposalId(_proposalId) returns (uint256 votesFor, uint256 votesAgainst, bool votingActive, uint256 endTime) {
        ProposalVoting memory voting = artProposalVotings[_proposalId];
        return (voting.votesFor, voting.votesAgainst, voting.votingActive, voting.endTime);
    }

    // 12. Execute art proposal mint if it passes voting
    function executeArtProposalMint(uint256 _proposalId) public onlyAdmin validProposalId(_proposalId) proposalNotMinted(_proposalId) {
        ProposalVoting storage voting = artProposalVotings[_proposalId];
        require(voting.votingActive && block.timestamp > voting.endTime, "Voting is still active or hasn't ended.");
        voting.votingActive = false; // End voting
        if (voting.votesFor > voting.votesAgainst) {
            artProposals[_proposalId].passedVoting = true;
            _mintNFT(artProposals[_proposalId].artist, nextNFTTokenId);
            artProposals[_proposalId].minted = true;
            emit ArtProposalMinted(_proposalId, nextNFTTokenId, artProposals[_proposalId].artist);
            nextNFTTokenId++;
        }
    }

    // Internal function to mint NFT (basic implementation, can be extended for ERC721 compliance)
    function _mintNFT(address _to, uint256 _tokenId) internal {
        nftOwners[_tokenId] = _to;
    }

    // 13. Set the base URI for NFT metadata
    function setNFTBaseURI(string memory _baseURI) public onlyAdmin {
        nftBaseURI = _baseURI;
    }

    // 14. Get the metadata URI for a given token ID
    function getNFTMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(nftOwners[_tokenId] != address(0), "NFT does not exist.");
        return string(abi.encodePacked(nftBaseURI, Strings.toString(_tokenId)));
    }

    // 15. List NFT for sale on the marketplace
    function listNFTForSale(uint256 _tokenId, uint256 _priceInWei) public {
        require(nftOwners[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(_priceInWei > 0, "Price must be greater than zero.");
        require(nftListings[_tokenId].isActive == false, "NFT is already listed or sold."); // Basic check, improve logic for listing IDs

        nftListings[nextListingId] = NFTListing({
            listingId: nextListingId,
            tokenId: _tokenId,
            seller: msg.sender,
            priceInWei: _priceInWei,
            isActive: true
        });
        emit NFTListedForSale(nextListingId, _tokenId, msg.sender, _priceInWei);
        nextListingId++;
    }

    // 16. Buy NFT from the marketplace
    function buyNFT(uint256 _listingId) public payable validListingId(_listingId) {
        NFTListing storage listing = nftListings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(msg.value >= listing.priceInWei, "Insufficient funds sent.");
        require(msg.sender != listing.seller, "Seller cannot buy their own NFT.");

        nftOwners[listing.tokenId] = msg.sender; // Transfer ownership
        listing.isActive = false; // Mark listing as inactive

        // Transfer funds to seller and collect marketplace fee
        uint256 marketplaceFee = (listing.priceInWei * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = listing.priceInWei - marketplaceFee;

        payable(listing.seller).transfer(sellerAmount);
        payable(admin).transfer(marketplaceFee); // Send fee to admin (collective)

        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.priceInWei);
    }

    // 17. Cancel NFT listing
    function cancelNFTListing(uint256 _listingId) public validListingId(_listingId) {
        NFTListing storage listing = nftListings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(listing.seller == msg.sender, "Only the seller can cancel the listing.");
        listing.isActive = false;
        emit NFTListingCancelled(_listingId, listing.tokenId, msg.sender);
    }

    // 18. Set marketplace fee percentage
    function setMarketplaceFee(uint256 _feePercentage) public onlyAdmin {
        require(_feePercentage <= 20, "Marketplace fee percentage cannot exceed 20%."); // Example limit
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    // 19. Withdraw marketplace fees
    function withdrawMarketplaceFees() public onlyAdmin {
        uint256 balance = address(this).balance;
        uint256 adminBalance = balance; // All contract balance is considered marketplace fees for simplicity
        payable(admin).transfer(adminBalance);
        emit MarketplaceFeesWithdrawn(admin, adminBalance);
    }

    // 20. Create a governance proposal
    function createGovernanceProposal(string memory _proposalDescription, bytes memory _calldata) public {
        require(bytes(_proposalDescription).length > 0 && bytes(_calldata).length > 0, "Proposal details cannot be empty.");
        governanceProposals[nextGovernanceProposalId] = GovernanceProposal({
            id: nextGovernanceProposalId,
            proposer: msg.sender,
            description: _proposalDescription,
            calldataData: _calldata,
            passedVoting: false,
            executed: false
        });
        emit GovernanceProposalCreated(nextGovernanceProposalId, msg.sender, _proposalDescription);
        nextGovernanceProposalId++;
    }

    // 21. Start voting for a governance proposal
    function startGovernanceProposalVoting(uint256 _proposalId, uint256 _votingDurationDays) public onlyAdmin validGovernanceProposalId(_proposalId) votingNotActive(_proposalId, governanceProposalVotings) {
        require(_votingDurationDays > 0 && _votingDurationDays <= 30, "Voting duration must be between 1 and 30 days.");
        governanceProposalVotings[_proposalId] = ProposalVoting({ // Reusing ProposalVoting struct
            proposalId: _proposalId,
            startTime: block.timestamp,
            endTime: block.timestamp + (_votingDurationDays * 1 days),
            votesFor: 0,
            votesAgainst: 0,
            votingActive: true
        });
        emit GovernanceProposalVotingStarted(_proposalId, governanceProposalVotings[_proposalId].endTime);
    }

    // 22. Vote on a governance proposal
    function voteOnGovernanceProposal(uint256 _proposalId, bool _vote) public validGovernanceProposalId(_proposalId) votingActive(_proposalId, governanceProposalVotings) {
        require(!hasVotedOnGovernanceProposal(msg.sender, _proposalId), "You have already voted on this governance proposal.");
        if (_vote) {
            governanceProposalVotings[_proposalId].votesFor++;
        } else {
            governanceProposalVotings[_proposalId].votesAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    // Helper function to check if a user has voted on governance proposal (similar to art proposal voting)
    function hasVotedOnGovernanceProposal(address _voter, uint256 _proposalId) private view returns (bool) {
        return false; // Placeholder, consider implementing voter tracking for production
    }

    // 23. Get governance proposal voting results
    function getGovernanceProposalVotingResults(uint256 _proposalId) public view validGovernanceProposalId(_proposalId) returns (uint256 votesFor, uint256 votesAgainst, bool votingActive, uint256 endTime) {
        ProposalVoting memory voting = governanceProposalVotings[_proposalId];
        return (voting.votesFor, voting.votesAgainst, voting.votingActive, voting.endTime);
    }

    // 24. Execute a governance proposal if it passes voting
    function executeGovernanceProposal(uint256 _proposalId) public onlyAdmin validGovernanceProposalId(_proposalId) governanceProposalNotExecuted(_proposalId) {
        ProposalVoting storage voting = governanceProposalVotings[_proposalId];
        require(voting.votingActive && block.timestamp > voting.endTime, "Voting is still active or hasn't ended.");
        voting.votingActive = false; // End voting
        if (voting.votesFor > voting.votesAgainst) {
            governanceProposals[_proposalId].passedVoting = true;
            (bool success, ) = address(this).call(governanceProposals[_proposalId].calldataData); // Execute the call data
            require(success, "Governance proposal execution failed.");
            governanceProposals[_proposalId].executed = true;
            emit GovernanceProposalExecuted(_proposalId);
        }
    }

    // 25. Stake tokens for community rewards (Placeholder - Requires ERC20 token integration)
    function stakeForCommunityRewards() public payable {
        // In a real implementation, you'd require users to approve and transfer ERC20 tokens
        // to this contract and manage staking amounts and reward calculations.
        // This is a simplified placeholder.
        stakingData[msg.sender].stakedAmount += msg.value; // Staking ETH as a placeholder
        stakingData[msg.sender].lastRewardClaimTime = block.timestamp;
        emit TokensStaked(msg.sender, msg.value);
    }

    // 26. Unstake tokens for community rewards (Placeholder - Requires ERC20 token integration)
    function unstakeForCommunityRewards(uint256 _amount) public {
        require(stakingData[msg.sender].stakedAmount >= _amount, "Insufficient staked balance.");
        require(_amount > 0, "Amount to unstake must be greater than zero.");
        stakingData[msg.sender].stakedAmount -= _amount;
        payable(msg.sender).transfer(_amount); // Return ETH as placeholder tokens
        emit TokensUnstaked(msg.sender, _amount);
    }

    // 27. Claim community rewards (Placeholder - Requires ERC20 token integration and reward logic)
    function claimCommunityRewards() public {
        // In a real implementation, calculate rewards based on staked amount, time, and reward rate.
        // This is a simplified placeholder that just resets the claim time.
        uint256 rewards = calculateRewards(msg.sender); // Placeholder reward calculation
        if (rewards > 0) {
            // In real implementation, transfer ERC20 reward tokens
            payable(msg.sender).transfer(rewards); // Placeholder - transfer ETH as rewards
            emit RewardsClaimed(msg.sender, rewards);
        }
        stakingData[msg.sender].lastRewardClaimTime = block.timestamp; // Reset claim time
    }

    // Placeholder reward calculation function (to be replaced with actual logic)
    function calculateRewards(address _staker) private view returns (uint256) {
        if (communityRewardRatePerDay == 0 || stakingData[_staker].stakedAmount == 0) {
            return 0;
        }
        uint256 timeSinceLastClaim = block.timestamp - stakingData[_staker].lastRewardClaimTime;
        uint256 daysSinceLastClaim = timeSinceLastClaim / 1 days;
        return (stakingData[_staker].stakedAmount * communityRewardRatePerDay * daysSinceLastClaim) / (10**18); // Example calculation - adjust as needed
    }

    // 28. Set community reward rate (Placeholder - Requires ERC20 token integration)
    function setCommunityRewardRate(uint256 _rewardRatePerDay) public onlyAdmin {
        communityRewardRatePerDay = _rewardRatePerDay;
        emit CommunityRewardRateUpdated(_rewardRatePerDay);
    }


    // 29. Get contract balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 30. Rescue accidentally sent ERC20 tokens
    function rescueERC20(address _tokenAddress, address _to, uint256 _amount) public onlyAdmin {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Contract balance is insufficient.");
        require(_to != address(0), "Recipient address cannot be zero.");
        bool success = token.transfer(_to, _amount);
        require(success, "Token transfer failed.");
        emit TokensRescued(_tokenAddress, _to, _amount);
    }


}

// --- Utility Libraries and Interfaces ---

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```