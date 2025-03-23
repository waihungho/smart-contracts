```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC) that enables artists to submit their work,
 * curators to evaluate and approve art, community members to vote on art pieces and proposals, fractionalize art NFTs,
 * participate in art auctions, earn rewards, and govern the collective's operations.
 *
 * Function Summary:
 *
 * 1.  `proposeNewArtSubmission(string memory _metadataURI)`: Allows artists to submit their art for consideration by providing metadata URI.
 * 2.  `voteOnArtSubmission(uint256 _submissionId, bool _approve)`: Allows community members to vote on pending art submissions.
 * 3.  `curateArtSubmission(uint256 _submissionId)`: Allows curators to mark an art submission as curated (after community vote).
 * 4.  `mintArtNFT(uint256 _submissionId)`: Mints an NFT for a curated and approved art submission.
 * 5.  `setArtNFTPrice(uint256 _nftId, uint256 _price)`: Allows the collective to set a price for an art NFT.
 * 6.  `buyArtNFT(uint256 _nftId)`: Allows users to purchase an art NFT from the collective.
 * 7.  `createFractionalNFT(uint256 _nftId, uint256 _fractionCount)`: Allows owners to create fractional NFTs from an art NFT.
 * 8.  `buyFractionalNFT(uint256 _fractionalNFTId, uint256 _amount)`: Allows users to buy fractional NFTs.
 * 9.  `redeemFractionalNFT(uint256 _fractionalNFTId, uint256 _amount)`: Allows fractional NFT holders to redeem and potentially claim a share of the original NFT (implementation detail - can be complex).
 * 10. `proposeNewCollectiveProposal(string memory _proposalDescription, bytes memory _data)`: Allows members to propose new initiatives or changes for the collective.
 * 11. `voteOnCollectiveProposal(uint256 _proposalId, bool _support)`: Allows community members to vote on collective proposals.
 * 12. `executeCollectiveProposal(uint256 _proposalId)`: Executes a passed collective proposal (permissioned or time-locked).
 * 13. `stakeTokens(uint256 _amount)`: Allows members to stake governance tokens to gain voting power and potential rewards.
 * 14. `unstakeTokens(uint256 _amount)`: Allows members to unstake their governance tokens.
 * 15. `claimStakingRewards()`: Allows members to claim staking rewards (if implemented).
 * 16. `startArtAuction(uint256 _nftId, uint256 _startingPrice, uint256 _duration)`: Starts an auction for a specific art NFT.
 * 17. `bidOnAuction(uint256 _auctionId)`: Allows users to bid on an active art auction.
 * 18. `endAuction(uint256 _auctionId)`: Ends an auction and transfers the NFT to the highest bidder.
 * 19. `withdrawContractBalance(address _recipient, uint256 _amount)`: Allows the contract owner (or designated role) to withdraw funds from the contract for collective purposes.
 * 20. `setVotingDuration(uint256 _newDuration)`: Allows the contract owner to set the voting duration for proposals and submissions.
 * 21. `setQuorumThreshold(uint256 _newThreshold)`: Allows the contract owner to set the quorum threshold for proposals and submissions.
 * 22. `addCurator(address _curatorAddress)`: Allows the contract owner to add new curators.
 * 23. `removeCurator(address _curatorAddress)`: Allows the contract owner to remove curators.
 * 24. `pauseContract()`: Allows the contract owner to pause critical contract functionalities in case of emergency.
 * 25. `unpauseContract()`: Allows the contract owner to unpause the contract.
 */

contract DecentralizedArtCollective {
    // -------- State Variables --------

    // --- Governance and Roles ---
    address public owner;
    mapping(address => bool) public curators;
    mapping(address => bool) public members; // Members who can vote (can be token-gated)
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumThreshold = 50; // Percentage quorum for proposals (e.g., 50%)
    bool public paused = false;

    // --- Art Submissions ---
    struct ArtSubmission {
        address artist;
        string metadataURI;
        bool curated;
        uint256 upVotes;
        uint256 downVotes;
        uint256 submissionTime;
        bool active; // Submission is still under voting/consideration
        bool approved; // Approved after voting and curation
    }
    ArtSubmission[] public artSubmissions;
    uint256 public submissionCounter = 0;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnSubmission;

    // --- Art NFTs ---
    struct ArtNFT {
        uint256 submissionId;
        uint256 tokenId;
        address owner;
        uint256 price;
        bool isFractionalized;
    }
    ArtNFT[] public artNFTs;
    uint256 public nftCounter = 0;
    mapping(uint256 => uint256) public nftIdToSubmissionId;

    // --- Fractional NFTs ---
    struct FractionalNFT {
        uint256 originalNFTId;
        uint256 fractionalNFTId; // Unique ID for the fractional NFT type
        uint256 totalSupply;
        uint256 price;
        mapping(address => uint256) public balances; // Balance of fractional NFTs per address
    }
    FractionalNFT[] public fractionalNFTs;
    uint256 public fractionalNFTCounter = 0;
    mapping(uint256 => uint256) public fractionalNFTIdToOriginalNFTId;

    // --- Collective Proposals ---
    struct CollectiveProposal {
        string description;
        bytes data; // Optional data for proposal execution
        uint256 upVotes;
        uint256 downVotes;
        uint256 proposalTime;
        uint256 endTime;
        bool executed;
        bool active;
    }
    CollectiveProposal[] public collectiveProposals;
    uint256 public proposalCounter = 0;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal;

    // --- Art Auctions ---
    struct ArtAuction {
        uint256 nftId;
        uint256 startTime;
        uint256 endTime;
        uint256 startingPrice;
        uint256 highestBid;
        address highestBidder;
        bool active;
    }
    ArtAuction[] public artAuctions;
    uint256 public auctionCounter = 0;

    // --- Staking (Basic Example - Can be expanded) ---
    mapping(address => uint256) public stakedBalances;

    // -------- Events --------
    event ArtSubmissionProposed(uint256 submissionId, address artist, string metadataURI);
    event ArtSubmissionVoted(uint256 submissionId, address voter, bool approve);
    event ArtSubmissionCurated(uint256 submissionId);
    event ArtNFTMinted(uint256 nftId, uint256 submissionId, address owner);
    event ArtNFTPriceSet(uint256 nftId, uint256 price);
    event ArtNFTBought(uint256 nftId, address buyer, uint256 price);
    event FractionalNFTCreated(uint256 fractionalNFTId, uint256 originalNFTId, uint256 fractionCount);
    event FractionalNFTBought(uint256 fractionalNFTId, address buyer, uint256 amount);
    event FractionalNFTRedeemed(uint256 fractionalNFTId, address redeemer, uint256 amount);
    event CollectiveProposalProposed(uint256 proposalId, address proposer, string description);
    event CollectiveProposalVoted(uint256 proposalId, address voter, bool support);
    event CollectiveProposalExecuted(uint256 proposalId);
    event TokensStaked(address staker, uint256 amount);
    event TokensUnstaked(address unstaker, uint256 amount);
    event StakingRewardsClaimed(address claimer, uint256 rewardAmount);
    event AuctionStarted(uint256 auctionId, uint256 nftId, uint256 startingPrice, uint256 duration);
    event AuctionBidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 auctionId, uint256 nftId, address winner, uint256 finalPrice);
    event ContractPaused();
    event ContractUnpaused();

    // -------- Modifiers --------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Only curators can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender] || msg.sender == owner || curators[msg.sender], "Only members can call this function.");
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

    // -------- Constructor --------
    constructor() {
        owner = msg.sender;
        curators[msg.sender] = true; // Owner is also a curator by default
        members[msg.sender] = true; // Owner is also a member by default
    }

    // -------- Governance and Roles Functions --------

    function addCurator(address _curatorAddress) external onlyOwner whenNotPaused {
        curators[_curatorAddress] = true;
    }

    function removeCurator(address _curatorAddress) external onlyOwner whenNotPaused {
        curators[_curatorAddress] = false;
    }

    function addMember(address _memberAddress) public onlyOwner whenNotPaused { // Can be changed to token-gated later
        members[_memberAddress] = true;
    }

    function removeMember(address _memberAddress) public onlyOwner whenNotPaused {
        members[_memberAddress] = false;
    }

    function setVotingDuration(uint256 _newDuration) external onlyOwner whenNotPaused {
        votingDuration = _newDuration;
    }

    function setQuorumThreshold(uint256 _newThreshold) external onlyOwner whenNotPaused {
        require(_newThreshold <= 100, "Quorum threshold cannot exceed 100%");
        quorumThreshold = _newThreshold;
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // -------- Art Submission Functions --------

    function proposeNewArtSubmission(string memory _metadataURI) external whenNotPaused {
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty.");
        artSubmissions.push(ArtSubmission({
            artist: msg.sender,
            metadataURI: _metadataURI,
            curated: false,
            upVotes: 0,
            downVotes: 0,
            submissionTime: block.timestamp,
            active: true,
            approved: false
        }));
        submissionCounter++;
        emit ArtSubmissionProposed(submissionCounter - 1, msg.sender, _metadataURI);
    }

    function voteOnArtSubmission(uint256 _submissionId, bool _approve) external onlyMember whenNotPaused {
        require(_submissionId < submissionCounter, "Invalid submission ID.");
        require(artSubmissions[_submissionId].active, "Submission is not active.");
        require(!hasVotedOnSubmission[_submissionId][msg.sender], "Already voted on this submission.");

        hasVotedOnSubmission[_submissionId][msg.sender] = true;
        if (_approve) {
            artSubmissions[_submissionId].upVotes++;
        } else {
            artSubmissions[_submissionId].downVotes++;
        }
        emit ArtSubmissionVoted(_submissionId, msg.sender, _approve);
    }

    function curateArtSubmission(uint256 _submissionId) external onlyCurator whenNotPaused {
        require(_submissionId < submissionCounter, "Invalid submission ID.");
        require(artSubmissions[_submissionId].active, "Submission is not active.");
        require(!artSubmissions[_submissionId].curated, "Submission already curated.");

        uint256 totalVotes = artSubmissions[_submissionId].upVotes + artSubmissions[_submissionId].downVotes;
        uint256 approvalPercentage = (totalVotes == 0) ? 0 : (artSubmissions[_submissionId].upVotes * 100) / totalVotes;

        if (approvalPercentage >= quorumThreshold) {
            artSubmissions[_submissionId].curated = true;
            artSubmissions[_submissionId].approved = true; // Mark as approved after curation and vote
            artSubmissions[_submissionId].active = false; // Submission process is complete
            emit ArtSubmissionCurated(_submissionId);
        } else {
             artSubmissions[_submissionId].active = false; // Submission process is complete even if not approved
        }
    }

    function mintArtNFT(uint256 _submissionId) external onlyCurator whenNotPaused {
        require(_submissionId < submissionCounter, "Invalid submission ID.");
        require(artSubmissions[_submissionId].curated && artSubmissions[_submissionId].approved, "Submission not curated or approved.");

        artNFTs.push(ArtNFT({
            submissionId: _submissionId,
            tokenId: nftCounter,
            owner: address(this), // Initially owned by the contract
            price: 0, // Price to be set later
            isFractionalized: false
        }));
        nftIdToSubmissionId[nftCounter] = _submissionId;
        nftCounter++;
        emit ArtNFTMinted(nftCounter - 1, _submissionId, address(this));
    }

    function setArtNFTPrice(uint256 _nftId, uint256 _price) external onlyCurator whenNotPaused {
        require(_nftId < nftCounter, "Invalid NFT ID.");
        require(artNFTs[_nftId].owner == address(this), "Cannot set price for NFT not owned by collective.");
        artNFTs[_nftId].price = _price;
        emit ArtNFTPriceSet(_nftId, _price);
    }

    function buyArtNFT(uint256 _nftId) external payable whenNotPaused {
        require(_nftId < nftCounter, "Invalid NFT ID.");
        require(artNFTs[_nftId].owner == address(this), "NFT not available for sale.");
        require(artNFTs[_nftId].price > 0, "Price not set for this NFT.");
        require(msg.value >= artNFTs[_nftId].price, "Insufficient funds sent.");

        address previousOwner = artNFTs[_nftId].owner;
        artNFTs[_nftId].owner = msg.sender;

        payable(owner).transfer(artNFTs[_nftId].price); // Send funds to contract owner (collective funds)
        emit ArtNFTBought(_nftId, msg.sender, artNFTs[_nftId].price);

        // Consider sending change back if msg.value > price
        if (msg.value > artNFTs[_nftId].price) {
            payable(msg.sender).transfer(msg.value - artNFTs[_nftId].price);
        }
    }

    // -------- Fractional NFT Functions --------

    function createFractionalNFT(uint256 _nftId, uint256 _fractionCount) external onlyCurator whenNotPaused {
        require(_nftId < nftCounter, "Invalid NFT ID.");
        require(artNFTs[_nftId].owner == address(this), "Cannot fractionalize NFT not owned by collective.");
        require(!artNFTs[_nftId].isFractionalized, "NFT already fractionalized.");
        require(_fractionCount > 0, "Fraction count must be greater than zero.");

        fractionalNFTs.push(FractionalNFT({
            originalNFTId: _nftId,
            fractionalNFTId: fractionalNFTCounter,
            totalSupply: _fractionCount,
            price: 0, // Price to be set later
            balances: mapping(address => uint256)()
        }));
        fractionalNFTCounter++;
        artNFTs[_nftId].isFractionalized = true; // Mark original NFT as fractionalized
        emit FractionalNFTCreated(fractionalNFTCounter - 1, _nftId, _fractionCount);
    }

    function setFractionalNFTPrice(uint256 _fractionalNFTId, uint256 _price) external onlyCurator whenNotPaused {
        require(_fractionalNFTId < fractionalNFTCounter, "Invalid Fractional NFT ID.");
        fractionalNFTs[_fractionalNFTId].price = _price;
    }


    function buyFractionalNFT(uint256 _fractionalNFTId, uint256 _amount) external payable whenNotPaused {
        require(_fractionalNFTId < fractionalNFTCounter, "Invalid Fractional NFT ID.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(fractionalNFTs[_fractionalNFTId].price > 0, "Fractional NFT price not set.");
        require(msg.value >= fractionalNFTs[_fractionalNFTId].price * _amount, "Insufficient funds sent.");
        require(fractionalNFTs[_fractionalNFTId].totalSupply >= fractionalNFTs[_fractionalNFTId].balances[address(this)] + _amount, "Not enough fractional NFTs available."); // Basic supply check

        fractionalNFTs[_fractionalNFTId].balances[msg.sender] += _amount;
        payable(owner).transfer(fractionalNFTs[_fractionalNFTId].price * _amount); // Send funds to contract owner (collective funds)

        emit FractionalNFTBought(_fractionalNFTId, msg.sender, _amount);

         // Consider sending change back if msg.value > price * amount
        if (msg.value > fractionalNFTs[_fractionalNFTId].price * _amount) {
            payable(msg.sender).transfer(msg.value - (fractionalNFTs[_fractionalNFTId].price * _amount));
        }
    }

    // --- Redeem Fractional NFT (Conceptual - Complex Implementation) ---
    // This function is a placeholder and conceptual. Real redemption logic can be complex and depend on the desired mechanism.
    // It might involve burning fractional NFTs and potentially triggering a mechanism to transfer ownership of the original NFT
    // based on certain conditions (e.g., reaching a threshold of fractional NFT holders, DAO vote, etc.)
    function redeemFractionalNFT(uint256 _fractionalNFTId, uint256 _amount) external whenNotPaused {
        require(_fractionalNFTId < fractionalNFTCounter, "Invalid Fractional NFT ID.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(fractionalNFTs[_fractionalNFTId].balances[msg.sender] >= _amount, "Insufficient fractional NFT balance.");

        fractionalNFTs[_fractionalNFTId].balances[msg.sender] -= _amount;
        fractionalNFTs[_fractionalNFTId].totalSupply -= _amount; // Reduce total supply

        emit FractionalNFTRedeemed(_fractionalNFTId, msg.sender, _amount);

        // ---  Placeholder for Redemption Logic ---
        // In a real implementation, you would add logic here to determine what happens upon redemption.
        // This could involve:
        // 1.  Accumulating redeemed fractional NFTs and triggering a vote to decide the fate of the original NFT.
        // 2.  Allowing holders of a significant portion of fractional NFTs to claim a share of the original NFT (requires more complex tracking and potentially off-chain mechanisms for physical art).
        // 3.  Burning fractional NFTs and providing some form of reward or benefit to redeemers.
        // --- End Placeholder ---
    }


    // -------- Collective Proposal Functions --------

    function proposeNewCollectiveProposal(string memory _proposalDescription, bytes memory _data) external onlyMember whenNotPaused {
        require(bytes(_proposalDescription).length > 0, "Proposal description cannot be empty.");
        collectiveProposals.push(CollectiveProposal({
            description: _proposalDescription,
            data: _data,
            upVotes: 0,
            downVotes: 0,
            proposalTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            executed: false,
            active: true
        }));
        proposalCounter++;
        emit CollectiveProposalProposed(proposalCounter - 1, msg.sender, _proposalDescription);
    }

    function voteOnCollectiveProposal(uint256 _proposalId, bool _support) external onlyMember whenNotPaused {
        require(_proposalId < proposalCounter, "Invalid proposal ID.");
        require(collectiveProposals[_proposalId].active, "Proposal is not active.");
        require(block.timestamp <= collectiveProposals[_proposalId].endTime, "Voting period ended.");
        require(!hasVotedOnProposal[_proposalId][msg.sender], "Already voted on this proposal.");

        hasVotedOnProposal[_proposalId][msg.sender] = true;
        if (_support) {
            collectiveProposals[_proposalId].upVotes++;
        } else {
            collectiveProposals[_proposalId].downVotes++;
        }
        emit CollectiveProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeCollectiveProposal(uint256 _proposalId) external whenNotPaused {
        require(_proposalId < proposalCounter, "Invalid proposal ID.");
        require(collectiveProposals[_proposalId].active, "Proposal is not active.");
        require(block.timestamp > collectiveProposals[_proposalId].endTime, "Voting period not ended yet.");
        require(!collectiveProposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = collectiveProposals[_proposalId].upVotes + collectiveProposals[_proposalId].downVotes;
        uint256 supportPercentage = (totalVotes == 0) ? 0 : (collectiveProposals[_proposalId].upVotes * 100) / totalVotes;

        if (supportPercentage >= quorumThreshold) {
            collectiveProposals[_proposalId].executed = true;
            collectiveProposals[_proposalId].active = false;
            emit CollectiveProposalExecuted(_proposalId);

            // --- Placeholder for Proposal Execution Logic ---
            // In a real implementation, you would decode and execute the `data` field of the proposal.
            // This could be function calls to this contract or other contracts, parameter changes, etc.
            // For security, implement careful checks and consider using delegatecall if necessary and safe.
            // Example (very basic and insecure - for illustration only):
            // (bool success, bytes memory returnData) = address(this).call(collectiveProposals[_proposalId].data);
            // require(success, "Proposal execution failed.");
            // --- End Placeholder ---
        } else {
            collectiveProposals[_proposalId].active = false; // Proposal process is complete, even if not passed
        }
    }

    // -------- Staking Functions (Basic Example) --------
    // This is a very basic staking example. Real staking mechanisms often involve reward distribution, vesting, etc.

    function stakeTokens(uint256 _amount) external payable whenNotPaused {
        require(_amount > 0, "Amount to stake must be greater than zero.");
        require(msg.value >= _amount, "Insufficient funds sent to stake."); // Staking with ETH in this example
        stakedBalances[msg.sender] += _amount;
        emit TokensStaked(msg.sender, _amount);

         // Consider sending change back if msg.value > amount
        if (msg.value > _amount) {
            payable(msg.sender).transfer(msg.value - _amount);
        }
    }

    function unstakeTokens(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Amount to unstake must be greater than zero.");
        require(stakedBalances[msg.sender] >= _amount, "Insufficient staked balance.");
        stakedBalances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount); // Return staked ETH
        emit TokensUnstaked(msg.sender, _amount);
    }

    function claimStakingRewards() external whenNotPaused {
        // --- Placeholder for Reward Calculation and Distribution ---
        // Implement reward calculation logic based on staking duration, amount staked, etc.
        // For simplicity, this example just returns a fixed reward amount.
        uint256 rewardAmount = 0; // Replace with actual reward calculation
        if (stakedBalances[msg.sender] > 0) {
            rewardAmount = stakedBalances[msg.sender] / 100; // Example: 1% reward based on staked balance
            payable(msg.sender).transfer(rewardAmount);
            emit StakingRewardsClaimed(msg.sender, rewardAmount);
        }
        // --- End Placeholder ---
    }

    // -------- Art Auction Functions --------

    function startArtAuction(uint256 _nftId, uint256 _startingPrice, uint256 _duration) external onlyCurator whenNotPaused {
        require(_nftId < nftCounter, "Invalid NFT ID.");
        require(artNFTs[_nftId].owner == address(this), "Cannot auction NFT not owned by collective.");
        require(!artNFTs[_nftId].isFractionalized, "Cannot auction fractionalized NFT.");
        require(_startingPrice > 0, "Starting price must be greater than zero.");
        require(_duration > 0, "Auction duration must be greater than zero.");

        artAuctions.push(ArtAuction({
            nftId: _nftId,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            startingPrice: _startingPrice,
            highestBid: 0,
            highestBidder: address(0),
            active: true
        }));
        auctionCounter++;
        emit AuctionStarted(auctionCounter - 1, _nftId, _startingPrice, _duration);
    }

    function bidOnAuction(uint256 _auctionId) external payable whenNotPaused {
        require(_auctionId < auctionCounter, "Invalid auction ID.");
        require(artAuctions[_auctionId].active, "Auction is not active.");
        require(block.timestamp < artAuctions[_auctionId].endTime, "Auction has ended.");
        require(msg.value > artAuctions[_auctionId].highestBid, "Bid must be higher than current highest bid.");
        require(msg.value >= artAuctions[_auctionId].startingPrice, "Bid must be at least starting price.");

        if (artAuctions[_auctionId].highestBidder != address(0)) {
            // Return previous highest bid
            payable(artAuctions[_auctionId].highestBidder).transfer(artAuctions[_auctionId].highestBid);
        }

        artAuctions[_auctionId].highestBid = msg.value;
        artAuctions[_auctionId].highestBidder = msg.sender;
        emit AuctionBidPlaced(_auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 _auctionId) external whenNotPaused {
        require(_auctionId < auctionCounter, "Invalid auction ID.");
        require(artAuctions[_auctionId].active, "Auction is not active.");
        require(block.timestamp >= artAuctions[_auctionId].endTime, "Auction end time not reached yet.");

        artAuctions[_auctionId].active = false;
        uint256 finalPrice = artAuctions[_auctionId].highestBid;
        address winner = artAuctions[_auctionId].highestBidder;
        uint256 nftId = artAuctions[_auctionId].nftId;

        if (winner != address(0)) {
            artNFTs[nftId].owner = winner; // Transfer NFT to winner
            payable(owner).transfer(finalPrice); // Send funds to collective

            emit AuctionEnded(_auctionId, nftId, winner, finalPrice);
        } else {
            // No bids placed, auction ends without a winner, NFT remains with collective
            emit AuctionEnded(_auctionId, nftId, address(0), 0);
        }
    }

    // -------- Withdrawal Function --------

    function withdrawContractBalance(address _recipient, uint256 _amount) external onlyOwner whenNotPaused {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        payable(_recipient).transfer(_amount);
    }

    // -------- Fallback Function (Optional - for receiving ETH) --------
    receive() external payable {}
}
```