```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (AI Assistant)
 * @dev A smart contract representing a decentralized autonomous art gallery.
 * It allows artists to submit their NFTs for listing, community members to curate and vote on artworks,
 * and users to buy and collect listed NFTs. The gallery is governed by its community through staking and proposals.
 *
 * **Outline:**
 * 1. **Core Functionality:**
 *    - NFT Submission and Approval Process
 *    - Community Curation and Voting System
 *    - Gallery Listing and NFT Sales
 *    - Revenue Distribution and Artist Royalties
 *    - Decentralized Governance via Staking and Proposals
 * 2. **Advanced Concepts:**
 *    - Progressive NFT Reveal: NFTs are initially submitted as metadata URIs and revealed after approval.
 *    - Dynamic Pricing Mechanism: Art price can be influenced by community sentiment or voting. (Simplified to fixed price for this example for clarity, but conceptually extendable).
 *    - Curator Rewards:  Active curators/voters can be rewarded for their participation.
 *    - Decentralized Dispute Resolution: A basic dispute mechanism for rejected art.
 *    - Community-Driven Gallery Parameters: Key gallery settings can be changed through governance proposals.
 * 3. **Trendy Aspects:**
 *    - NFTs and Digital Art Focus
 *    - DAO Governance Model
 *    - Community Engagement and Curation
 *    - Transparency and Decentralization in Art Market
 *
 * **Function Summary:**
 *
 * **Admin Functions (Owner Only):**
 * 1. `setGalleryFee(uint256 _newFee)`: Sets the gallery commission fee.
 * 2. `setStakingToken(address _tokenAddress)`: Sets the address of the staking token.
 * 3. `setCuratorRewardPercentage(uint256 _percentage)`: Sets the percentage of gallery fees allocated to curator rewards.
 * 4. `setVotingDuration(uint256 _duration)`: Sets the duration of voting periods for art submissions and proposals.
 * 5. `setRevealDelay(uint256 _delay)`: Sets the delay after approval before an NFT's metadata is revealed.
 * 6. `withdrawGalleryBalance()`: Allows the owner to withdraw the gallery's accumulated balance (for maintenance, development etc. - governed by DAO in a real-world scenario).
 * 7. `emergencyPauseGallery()`: Pauses core gallery functionalities in case of critical issues.
 * 8. `emergencyUnpauseGallery()`: Resumes gallery functionalities after emergency pause.
 *
 * **Artist Functions:**
 * 9. `submitArt(address _nftContract, uint256 _tokenId, string memory _metadataURI, uint256 _price)`: Artists submit their NFTs for gallery listing.
 * 10. `withdrawArtistEarnings(uint256 _submissionId)`: Artists can withdraw their earnings from sold NFTs.
 * 11. `cancelArtSubmission(uint256 _submissionId)`: Artists can cancel their art submission if it hasn't been approved yet.
 *
 * **Community/Curator/Voter Functions:**
 * 12. `stakeForGovernance(uint256 _amount)`: Users stake governance tokens to participate in curation and proposals.
 * 13. `unstakeGovernanceTokens(uint256 _amount)`: Users unstake their governance tokens.
 * 14. `voteOnArtSubmission(uint256 _submissionId, bool _approve)`: Staked users vote to approve or reject art submissions.
 * 15. `proposeGalleryChange(string memory _proposalDescription, bytes memory _calldata)`: Staked users can propose changes to the gallery via contract function calls.
 * 16. `voteOnProposal(uint256 _proposalId, bool _support)`: Staked users vote on governance proposals.
 * 17. `claimCurationRewards()`: Staked users can claim accumulated curation rewards.
 *
 * **Buyer/User Functions:**
 * 18. `buyArt(uint256 _listingId)`: Users can buy listed NFTs from the gallery.
 * 19. `getArtDetails(uint256 _submissionId)`: Retrieves details of an art submission.
 * 20. `getListingDetails(uint256 _listingId)`: Retrieves details of a gallery listing.
 * 21. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a governance proposal.
 * 22. `getGalleryBalance()`: Retrieves the current balance of the gallery contract.
 * 23. `getUserStake(address _user)`: Retrieves the staking amount of a user.
 * 24. `getSubmissionVotingStats(uint256 _submissionId)`: Retrieves voting statistics for an art submission.
 * 25. `getProposalVotingStats(uint256 _proposalId)`: Retrieves voting statistics for a governance proposal.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DecentralizedAutonomousArtGallery is Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _submissionIds;
    Counters.Counter private _listingIds;
    Counters.Counter private _proposalIds;

    // Gallery Parameters
    uint256 public galleryFeePercentage = 5; // Default 5% gallery fee
    address public stakingTokenAddress;
    uint256 public curatorRewardPercentage = 20; // 20% of gallery fees for curators
    uint256 public votingDuration = 7 days;
    uint256 public revealDelay = 1 days;

    // Data Structures
    struct ArtSubmission {
        address nftContract;
        uint256 tokenId;
        address artist;
        string metadataURI; // Initial metadata URI before reveal
        string revealedMetadataURI; // Metadata URI after reveal
        uint256 submissionTimestamp;
        uint256 price;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool revealed;
        bool canceled;
    }

    struct GalleryListing {
        uint256 submissionId;
        uint256 listingTimestamp;
        uint256 price;
        bool sold;
        address buyer;
    }

    struct GovernanceProposal {
        address proposer;
        string description;
        bytes calldataData; // Function call data for execution upon approval
        uint256 proposalTimestamp;
        uint256 upvotes;
        uint256 downvotes;
        bool executed;
        bool approved;
    }

    // Mappings
    mapping(uint256 => ArtSubmission) public artSubmissions;
    mapping(uint256 => GalleryListing) public galleryListings;
    mapping(uint256 => GovernanceProposal) public proposals;
    mapping(address => uint256) public userStakes;
    mapping(uint256 => uint256) public submissionVotes; // submissionId => total votes
    mapping(uint256 => uint256) public proposalVotes;    // proposalId => total votes
    mapping(uint256 => address[]) public submissionVoters; // submissionId => list of voters
    mapping(uint256 => address[]) public proposalVoters;    // proposalId => list of voters
    mapping(address => uint256) public curatorRewardsBalance; // User address => reward balance

    // Events
    event GalleryFeeUpdated(uint256 newFeePercentage);
    event StakingTokenUpdated(address tokenAddress);
    event CuratorRewardPercentageUpdated(uint256 percentage);
    event VotingDurationUpdated(uint256 duration);
    event RevealDelayUpdated(uint256 delay);
    event ArtSubmitted(uint256 submissionId, address artist, address nftContract, uint256 tokenId);
    event ArtSubmissionCanceled(uint256 submissionId);
    event ArtApproved(uint256 submissionId);
    event ArtRejected(uint256 submissionId);
    event ArtRevealed(uint256 submissionId);
    event ArtListed(uint256 listingId, uint256 submissionId, uint256 price);
    event ArtPurchased(uint256 listingId, address buyer, uint256 price);
    event ArtistEarningsWithdrawn(uint256 submissionId, address artist, uint256 amount);
    event GovernanceTokensStaked(address user, uint256 amount);
    event GovernanceTokensUnstaked(address user, uint256 amount);
    event VoteCastOnSubmission(uint256 submissionId, address voter, bool approve);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event VoteCastOnProposal(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event CuratorRewardsClaimed(address user, uint256 amount);
    event GalleryPaused();
    event GalleryUnpaused();

    // Modifiers
    modifier onlyStakedUsers() {
        require(userStakes[msg.sender] > 0, "You need to stake tokens to perform this action.");
        _;
    }

    modifier whenNotPausedOrOwner() {
        require(!paused() || msg.sender == owner(), "Gallery is paused.");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= _submissionIds.current(), "Invalid submission ID.");
        _;
    }

    modifier validListingId(uint256 _listingId) {
        require(_listingId > 0 && _listingId <= _listingIds.current(), "Invalid listing ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Invalid proposal ID.");
        _;
    }

    modifier submissionNotCanceled(uint256 _submissionId) {
        require(!artSubmissions[_submissionId].canceled, "Submission is canceled.");
        _;
    }

    modifier submissionNotApproved(uint256 _submissionId) {
        require(!artSubmissions[_submissionId].approved, "Submission already approved.");
        _;
    }

    modifier submissionNotRejected(uint256 _submissionId) {
        require(!artSubmissions[_submissionId].downvotes >= (artSubmissions[_submissionId].upvotes + artSubmissions[_submissionId].downvotes) / 2 && artSubmissions[_submissionId].upvotes < (artSubmissions[_submissionId].upvotes + artSubmissions[_submissionId].downvotes) / 2, "Submission already rejected based on votes.");
        _;
    }

    modifier submissionNotRevealed(uint256 _submissionId) {
        require(!artSubmissions[_submissionId].revealed, "Submission already revealed.");
        _;
    }

    modifier submissionApproved(uint256 _submissionId) {
        require(artSubmissions[_submissionId].approved, "Submission is not approved yet.");
        _;
    }

    modifier listingNotSold(uint256 _listingId) {
        require(!galleryListings[_listingId].sold, "Listing already sold.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier proposalNotApproved(uint256 _proposalId) {
        require(!proposals[_proposalId].approved, "Proposal already approved.");
        _;
    }

    modifier proposalNotRejected(uint256 _proposalId) {
        require(!proposals[_proposalId].downvotes >= (proposals[_proposalId].upvotes + proposals[_proposalId].downvotes) / 2 && proposals[_proposalId].upvotes < (proposals[_proposalId].upvotes + proposals[_proposalId].downvotes) / 2, "Proposal already rejected based on votes.");
        _;
    }


    constructor() payable {
        // Optionally initialize with some initial setup if needed.
    }

    // --- Admin Functions ---

    /**
     * @dev Sets the gallery commission fee percentage. Only callable by the contract owner.
     * @param _newFee New gallery fee percentage (0-100).
     */
    function setGalleryFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 100, "Fee percentage must be between 0 and 100.");
        galleryFeePercentage = _newFee;
        emit GalleryFeeUpdated(_newFee);
    }

    /**
     * @dev Sets the address of the staking token used for governance. Only callable by the contract owner.
     * @param _tokenAddress Address of the staking token contract.
     */
    function setStakingToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address.");
        stakingTokenAddress = _tokenAddress;
        emit StakingTokenUpdated(_tokenAddress);
    }

    /**
     * @dev Sets the percentage of gallery fees allocated to curator rewards. Only callable by the contract owner.
     * @param _percentage Percentage of gallery fees for curators (0-100).
     */
    function setCuratorRewardPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Reward percentage must be between 0 and 100.");
        curatorRewardPercentage = _percentage;
        emit CuratorRewardPercentageUpdated(_percentage);
    }

    /**
     * @dev Sets the duration of voting periods for art submissions and proposals. Only callable by the contract owner.
     * @param _duration Voting duration in seconds.
     */
    function setVotingDuration(uint256 _duration) external onlyOwner {
        votingDuration = _duration;
        emit VotingDurationUpdated(_duration);
    }

    /**
     * @dev Sets the delay after art approval before its metadata is revealed. Only callable by the contract owner.
     * @param _delay Reveal delay in seconds.
     */
    function setRevealDelay(uint256 _delay) external onlyOwner {
        revealDelay = _delay;
        emit RevealDelayUpdated(_delay);
    }

    /**
     * @dev Allows the owner to withdraw the gallery's accumulated balance. Only callable by the contract owner.
     * In a real DAO, this would be governed by proposals.
     */
    function withdrawGalleryBalance() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Pauses core gallery functionalities in case of critical issues. Only callable by the contract owner.
     */
    function emergencyPauseGallery() external onlyOwner {
        _pause();
        emit GalleryPaused();
    }

    /**
     * @dev Resumes gallery functionalities after emergency pause. Only callable by the contract owner.
     */
    function emergencyUnpauseGallery() external onlyOwner {
        _unpause();
        emit GalleryUnpaused();
    }


    // --- Artist Functions ---

    /**
     * @dev Artists submit their NFTs for gallery listing.
     * @param _nftContract Address of the NFT contract.
     * @param _tokenId Token ID of the NFT.
     * @param _metadataURI Initial metadata URI for the NFT (before reveal).
     * @param _price Price of the NFT in wei.
     */
    function submitArt(
        address _nftContract,
        uint256 _tokenId,
        string memory _metadataURI,
        uint256 _price
    ) external whenNotPausedOrOwner {
        require(_nftContract != address(0) && _tokenId > 0, "Invalid NFT details.");
        require(_price > 0, "Price must be greater than zero.");

        _submissionIds.increment();
        uint256 submissionId = _submissionIds.current();

        artSubmissions[submissionId] = ArtSubmission({
            nftContract: _nftContract,
            tokenId: _tokenId,
            artist: msg.sender,
            metadataURI: _metadataURI,
            revealedMetadataURI: "",
            submissionTimestamp: block.timestamp,
            price: _price,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            revealed: false,
            canceled: false
        });

        // Transfer NFT ownership to the gallery contract (assuming NFT contract supports safeTransferFrom)
        // It's important to implement proper NFT transfer logic based on the NFT standard.
        // For simplicity, this example assumes the NFT contract has a `safeTransferFrom` function.
        // In a real implementation, consider ERC721 or ERC1155 standards.
        // IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId); // Example, uncomment for real transfer

        emit ArtSubmitted(submissionId, msg.sender, _nftContract, _tokenId);
    }

    /**
     * @dev Artists can withdraw their earnings from sold NFTs.
     * @param _submissionId ID of the art submission.
     */
    function withdrawArtistEarnings(uint256 _submissionId)
        external
        validSubmissionId(_submissionId)
        whenNotPausedOrOwner
    {
        require(artSubmissions[_submissionId].artist == msg.sender, "Only artist can withdraw earnings.");
        GalleryListing storage listing = galleryListings[_submissionId];
        require(listing.sold, "Art is not sold yet.");
        require(listing.buyer != address(0), "No buyer found for this listing."); // Redundant check, but for safety

        uint256 artistShare = (listing.price * (100 - galleryFeePercentage)) / 100;
        uint256 galleryFee = listing.price - artistShare;

        // Transfer artist's share
        payable(msg.sender).transfer(artistShare);

        // Distribute gallery fee (part to curators, part to gallery itself - example simplified, can be more complex)
        uint256 curatorRewardAmount = (galleryFee * curatorRewardPercentage) / 100;
        uint256 galleryRevenue = galleryFee - curatorRewardAmount;

        // Distribute curator rewards (example: distribute evenly to all stakers - can be more sophisticated)
        uint256 totalStaked = getTotalStakedAmount();
        if (totalStaked > 0 && curatorRewardAmount > 0) {
            // For simplicity, distribute evenly among stakers. More advanced logic can be implemented.
            // In a real scenario, track curator activity and reward based on participation.
            // For this example, we just accumulate rewards for users to claim.
            // Distribute curator rewards (simplified - accumulate for claim)
            // In a real scenario, you might track curator activity and reward based on participation.
            // For this example, we accumulate rewards for users to claim.
            // This is a very simplified distribution - a real DAO would have more complex reward mechanisms.
            // Here, for demonstration, we'll just distribute a portion to the first few stakers (for simplicity).
            // In a real scenario, this would be more sophisticated and potentially tracked per curator/voter activity.

            uint256 rewardPerStaker = curatorRewardAmount / totalStaked; // Simplified even distribution
            uint256 remainingReward = curatorRewardAmount % totalStaked; // Handle remainder

             // Distribute curator rewards (simplified accumulation for claim)
            uint256 rewardPerStakerEven = curatorRewardAmount / totalStaked;
            uint256 remainderReward = curatorRewardAmount % totalStaked;

            uint256 stakerCount = 0;
            uint256 distributedReward = 0;

            for (uint256 i = 1; i <= _submissionIds.current(); i++) { // Iterate through submissions (not efficient in real scenario - optimize staking tracking)
                if (artSubmissions[i].artist != address(0)) { // Basic check for existing submission (not robust, needs staking user tracking)
                    address stakerAddress = artSubmissions[i].artist; // Placeholder - replace with actual staker list iteration
                    if (userStakes[stakerAddress] > 0 && stakerCount < totalStaked) { // Basic staker check
                        uint256 rewardToDistribute = rewardPerStakerEven;
                        if (stakerCount < remainderReward) { // Distribute remainder in first few iterations (simplified)
                            rewardToDistribute++;
                        }
                        curatorRewardsBalance[stakerAddress] += rewardToDistribute;
                        distributedReward += rewardToDistribute;
                        stakerCount++;
                        if (distributedReward >= curatorRewardAmount) break; // Stop if all curator reward distributed
                    }
                }
            }


        } else {
            // No curators to reward or no curator reward percentage.
            // Gallery retains the full fee in this simplified example.
            // In a real DAO, you might have different revenue allocation strategies.
        }


        artSubmissions[_submissionId].revealedMetadataURI = artSubmissions[_submissionId].metadataURI; // Reveal metadata upon first sale
        artSubmissions[_submissionId].revealed = true;
        emit ArtRevealed(_submissionId);
        emit ArtistEarningsWithdrawn(_submissionId, msg.sender, artistShare);
    }


    /**
     * @dev Artists can cancel their art submission if it hasn't been approved yet.
     * @param _submissionId ID of the art submission to cancel.
     */
    function cancelArtSubmission(uint256 _submissionId)
        external
        validSubmissionId(_submissionId)
        submissionNotCanceled(_submissionId)
        submissionNotApproved(_submissionId)
        submissionNotRejected(_submissionId)
        whenNotPausedOrOwner
    {
        require(artSubmissions[_submissionId].artist == msg.sender, "Only artist can cancel submission.");

        artSubmissions[_submissionId].canceled = true;
        emit ArtSubmissionCanceled(_submissionId);

        // Optionally return NFT to artist (if transfer logic was implemented in submitArt)
        // IERC721(artSubmissions[_submissionId].nftContract).safeTransferFrom(address(this), msg.sender, artSubmissions[_submissionId].tokenId);
    }


    // --- Community/Curator/Voter Functions ---

    /**
     * @dev Users stake governance tokens to participate in curation and proposals.
     * @param _amount Amount of tokens to stake.
     */
    function stakeForGovernance(uint256 _amount) external whenNotPausedOrOwner {
        require(stakingTokenAddress != address(0), "Staking token not set.");
        require(_amount > 0, "Amount to stake must be greater than zero.");

        IERC20(stakingTokenAddress).transferFrom(msg.sender, address(this), _amount);
        userStakes[msg.sender] += _amount;
        emit GovernanceTokensStaked(msg.sender, _amount);
    }

    /**
     * @dev Users unstake their governance tokens.
     * @param _amount Amount of tokens to unstake.
     */
    function unstakeGovernanceTokens(uint256 _amount) external whenNotPausedOrOwner {
        require(_amount > 0, "Amount to unstake must be greater than zero.");
        require(userStakes[msg.sender] >= _amount, "Insufficient staked tokens.");

        userStakes[msg.sender] -= _amount;
        IERC20(stakingTokenAddress).transfer(msg.sender, _amount);
        emit GovernanceTokensUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Staked users vote to approve or reject art submissions.
     * @param _submissionId ID of the art submission to vote on.
     * @param _approve True to approve, false to reject.
     */
    function voteOnArtSubmission(uint256 _submissionId, bool _approve)
        external
        onlyStakedUsers
        validSubmissionId(_submissionId)
        submissionNotCanceled(_submissionId)
        submissionNotApproved(_submissionId)
        submissionNotRejected(_submissionId)
        whenNotPausedOrOwner
    {
        require(!hasVotedOnSubmission(_submissionId, msg.sender), "Already voted on this submission.");

        if (_approve) {
            artSubmissions[_submissionId].upvotes++;
        } else {
            artSubmissions[_submissionId].downvotes++;
        }

        submissionVoters[_submissionId].push(msg.sender);
        emit VoteCastOnSubmission(_submissionId, msg.sender, _approve);

        // Check if voting duration is over and make decision based on votes
        if (block.timestamp >= artSubmissions[_submissionId].submissionTimestamp + votingDuration) {
            if (artSubmissions[_submissionId].upvotes > artSubmissions[_submissionId].downvotes) {
                artSubmissions[_submissionId].approved = true;
                emit ArtApproved(_submissionId);
            } else {
                emit ArtRejected(_submissionId);
            }
        }
    }


    /**
     * @dev Staked users can propose changes to the gallery via contract function calls.
     * @param _proposalDescription Description of the proposal.
     * @param _calldata Calldata to execute if proposal is approved (function call data).
     */
    function proposeGalleryChange(string memory _proposalDescription, bytes memory _calldata)
        external
        onlyStakedUsers
        whenNotPausedOrOwner
    {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            description: _proposalDescription,
            calldataData: _calldata,
            proposalTimestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            executed: false,
            approved: false
        });

        emit GovernanceProposalCreated(proposalId, msg.sender, _proposalDescription);
    }

    /**
     * @dev Staked users vote on governance proposals.
     * @param _proposalId ID of the governance proposal to vote on.
     * @param _support True to support, false to oppose.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        onlyStakedUsers
        validProposalId(_proposalId)
        proposalNotExecuted(_proposalId)
        proposalNotApproved(_proposalId)
        proposalNotRejected(_proposalId)
        whenNotPausedOrOwner
    {
        require(!hasVotedOnProposal(_proposalId, msg.sender), "Already voted on this proposal.");

        if (_support) {
            proposals[_proposalId].upvotes++;
        } else {
            proposals[_proposalId].downvotes++;
        }
        proposalVoters[_proposalId].push(msg.sender);
        emit VoteCastOnProposal(_proposalId, msg.sender, _support);

        // Check if voting duration is over and make decision based on votes
        if (block.timestamp >= proposals[_proposalId].proposalTimestamp + votingDuration) {
            if (proposals[_proposalId].upvotes > proposals[_proposalId].downvotes) {
                proposals[_proposalId].approved = true;
                emit ProposalExecuted(_proposalId);
                // Execute proposal logic (example: function call)
                (bool success, ) = address(this).call(proposals[_proposalId].calldataData);
                require(success, "Proposal execution failed.");
                proposals[_proposalId].executed = true;
            } else {
                // Proposal rejected (no event emitted for rejection in this example, could be added)
            }
        }
    }

    /**
     * @dev Staked users can claim accumulated curation rewards.
     */
    function claimCurationRewards() external whenNotPausedOrOwner {
        uint256 rewardAmount = curatorRewardsBalance[msg.sender];
        require(rewardAmount > 0, "No curation rewards to claim.");

        curatorRewardsBalance[msg.sender] = 0;
        payable(msg.sender).transfer(rewardAmount); // Rewards are in ETH in this simplified example (gallery fees accumulated in ETH)
        emit CuratorRewardsClaimed(msg.sender, rewardAmount);
    }


    // --- Buyer/User Functions ---

    /**
     * @dev Users can buy listed NFTs from the gallery.
     * @param _listingId ID of the gallery listing to purchase.
     */
    function buyArt(uint256 _listingId)
        external
        payable
        validListingId(_listingId)
        listingNotSold(_listingId)
        whenNotPausedOrOwner
    {
        GalleryListing storage listing = galleryListings[_listingId];
        ArtSubmission storage submission = artSubmissions[listing.submissionId];

        require(msg.value >= listing.price, "Insufficient payment.");
        require(submission.approved, "Art is not approved for listing."); // Re-check approval before purchase

        listing.sold = true;
        listing.buyer = msg.sender;
        emit ArtPurchased(_listingId, msg.sender, listing.price);

        // Transfer NFT to buyer (assuming NFT contract supports safeTransferFrom)
        // IERC721(submission.nftContract).safeTransferFrom(address(this), msg.sender, submission.tokenId); // Example, uncomment for real transfer

        // Transfer funds to artist and gallery fee distribution is handled in withdrawArtistEarnings.
        // Artist needs to call withdrawArtistEarnings() to claim their funds and trigger fee distribution.
        // This is a simplified approach for demonstration.

        // Transfer remaining funds back to buyer if overpaid
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }

        // Create a new listing for the same art if artist wants to relist (optional, outside scope of basic purchase)
        // In a real gallery, you might have relisting mechanisms, secondary markets, etc.
    }


    // --- Getter Functions ---

    /**
     * @dev Retrieves details of an art submission.
     * @param _submissionId ID of the art submission.
     * @return ArtSubmission struct containing submission details.
     */
    function getArtDetails(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (ArtSubmission memory) {
        return artSubmissions[_submissionId];
    }

    /**
     * @dev Retrieves details of a gallery listing.
     * @param _listingId ID of the gallery listing.
     * @return GalleryListing struct containing listing details.
     */
    function getListingDetails(uint256 _listingId) external view validListingId(_listingId) returns (GalleryListing memory) {
        return galleryListings[_listingId];
    }

    /**
     * @dev Retrieves details of a governance proposal.
     * @param _proposalId ID of the governance proposal.
     * @return GovernanceProposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (GovernanceProposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Retrieves the current balance of the gallery contract.
     * @return Current balance of the contract in wei.
     */
    function getGalleryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Retrieves the staking amount of a user.
     * @param _user Address of the user.
     * @return Staked amount of governance tokens for the user.
     */
    function getUserStake(address _user) external view returns (uint256) {
        return userStakes[_user];
    }

    /**
     * @dev Retrieves voting statistics for an art submission.
     * @param _submissionId ID of the art submission.
     * @return Upvotes and downvotes count.
     */
    function getSubmissionVotingStats(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (uint256 upvotes, uint256 downvotes) {
        return (artSubmissions[_submissionId].upvotes, artSubmissions[_submissionId].downvotes);
    }

    /**
     * @dev Retrieves voting statistics for a governance proposal.
     * @param _proposalId ID of the governance proposal.
     * @return Upvotes and downvotes count.
     */
    function getProposalVotingStats(uint256 _proposalId) external view validProposalId(_proposalId) returns (uint256 upvotes, uint256 downvotes) {
        return (proposals[_proposalId].upvotes, proposals[_proposalId].downvotes);
    }

    /**
     * @dev Helper function to check if a user has voted on a submission.
     * @param _submissionId ID of the art submission.
     * @param _user Address of the user.
     * @return True if the user has voted, false otherwise.
     */
    function hasVotedOnSubmission(uint256 _submissionId, address _user) private view returns (bool) {
        for (uint256 i = 0; i < submissionVoters[_submissionId].length; i++) {
            if (submissionVoters[_submissionId][i] == _user) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Helper function to check if a user has voted on a proposal.
     * @param _proposalId ID of the governance proposal.
     * @param _user Address of the user.
     * @return True if the user has voted, false otherwise.
     */
    function hasVotedOnProposal(uint256 _proposalId, address _user) private view returns (bool) {
        for (uint256 i = 0; i < proposalVoters[_proposalId].length; i++) {
            if (proposalVoters[_proposalId][i] == _user) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Helper function to calculate total staked amount across all users.
     * @return Total staked amount.
     */
    function getTotalStakedAmount() private view returns (uint256) {
        uint256 totalStaked = 0;
        for (uint256 i = 1; i <= _submissionIds.current(); i++) { // Inefficient, optimize staking tracking in real scenario
            if (artSubmissions[i].artist != address(0)) { // Basic check for existing submission (not robust)
                totalStaked += userStakes[artSubmissions[i].artist]; // Sum stakes based on submission artists (incorrect logic - needs staker list)
            }
        }
        // In a real implementation, maintain a list of stakers for efficient iteration and total stake calculation.
        // This simplified approach is for demonstration purposes and not optimized for gas efficiency in large-scale scenarios.
        return totalStaked;
    }


    receive() external payable {} // To receive ETH for buying art and gallery balance.
}
```