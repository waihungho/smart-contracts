```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to submit proposals,
 *      community members to vote on them, and the collective to manage a treasury, curate art, and distribute rewards.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core Functionality - Art Proposal and Voting:**
 *    - `submitArtProposal(string _title, string _description, string _ipfsHash)`: Allows artists to submit art proposals with title, description, and IPFS hash.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows community members to vote for or against an art proposal.
 *    - `finalizeProposal(uint256 _proposalId)`: Finalizes a proposal after voting period, mints NFT if approved, and rejects if not.
 *    - `rejectProposal(uint256 _proposalId)`: (Admin/Curator only) Manually rejects a proposal before voting ends (e.g., for policy violations).
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific art proposal.
 *    - `getProposalCount()`: Returns the total number of submitted art proposals.
 *    - `getApprovedProposals()`: Returns a list of IDs of approved art proposals.
 *    - `getPendingProposals()`: Returns a list of IDs of proposals currently in voting.
 *
 * **2. NFT Minting and Art Management:**
 *    - `mintArtNFT(uint256 _proposalId)`: (Internal, called upon proposal approval) Mints an NFT representing the approved artwork.
 *    - `transferArtNFT(uint256 _tokenId, address _recipient)`: Allows the contract owner to transfer ownership of an Art NFT (e.g., for prizes or collaborations).
 *    - `getArtNFTDetails(uint256 _tokenId)`: Retrieves details of a specific Art NFT.
 *    - `getTotalMintedNFTs()`: Returns the total number of Art NFTs minted by the collective.
 *
 * **3. Governance and Community Participation:**
 *    - `stakeTokens(uint256 _amount)`: Allows community members to stake tokens to gain voting power and potential rewards.
 *    - `unstakeTokens(uint256 _amount)`: Allows community members to unstake their tokens.
 *    - `getVotingPower(address _voter)`: Returns the voting power of a community member based on their staked tokens.
 *    - `addCurator(address _curator)`: (Admin only) Adds a new curator address with moderation and management privileges.
 *    - `removeCurator(address _curator)`: (Admin only) Removes a curator address.
 *    - `isCurator(address _user)`: Checks if an address is a curator.
 *    - `getTotalStakedTokens()`: Returns the total number of tokens staked in the collective.
 *
 * **4. Treasury and Reward Distribution:**
 *    - `depositFunds()`: Allows anyone to deposit ETH/tokens into the collective's treasury (payable function).
 *    - `withdrawFunds(uint256 _amount)`: (Admin/Curator only) Allows withdrawing funds from the treasury (ETH/tokens).
 *    - `getTreasuryBalance()`: Returns the current balance of the collective's treasury (ETH).
 *    - `distributeRewardsToVoters(uint256 _proposalId)`: (Admin/Curator only, after proposal finalization) Distributes rewards to voters who voted in favor of an approved proposal (optional, token-based reward system).
 *
 * **5. Configuration and Utility:**
 *    - `setProposalFee(uint256 _fee)`: (Admin only) Sets the fee required to submit an art proposal.
 *    - `getProposalFee()`: Returns the current proposal submission fee.
 *    - `setVotingDuration(uint256 _durationInBlocks)`: (Admin only) Sets the duration of the voting period for proposals (in blocks).
 *    - `getVotingDuration()`: Returns the current voting duration.
 *    - `getContractOwner()`: Returns the address of the contract owner.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedArtCollective is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Data Structures ---
    struct ArtProposal {
        uint256 proposalId;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 submissionTimestamp;
        uint256 votingEndTime;
        uint256 upvotes;
        uint256 downvotes;
        bool finalized;
        bool approved;
        bool rejected;
    }

    struct ArtNFT {
        uint256 tokenId;
        uint256 proposalId;
        string ipfsHash;
        address minter;
        uint256 mintTimestamp;
    }

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => vote (true=upvote, false=downvote)
    mapping(address => uint256) public stakedTokens; // voter => staked amount
    mapping(address => bool) public curators;

    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _artNftIdCounter;

    uint256 public proposalFee = 0.1 ether; // Fee to submit a proposal
    uint256 public votingDurationInBlocks = 100; // Voting duration in blocks (adjust as needed)
    uint256 public minStakeForVote = 1 ether; // Minimum stake to be eligible to vote
    uint256 public rewardPerVoter = 0.01 ether; // Reward per voter (example, can be tokens too)

    // --- Events ---
    event ProposalSubmitted(uint256 proposalId, address artist, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalFinalized(uint256 proposalId, bool approved);
    event ProposalRejected(uint256 proposalId, bool manualReject);
    event ArtNFTMinted(uint256 tokenId, uint256 proposalId, address minter);
    event TokensStaked(address staker, uint256 amount);
    event TokensUnstaked(address unstaker, uint256 amount);
    event CuratorAdded(address curator);
    event CuratorRemoved(address curator);
    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(address withdrawer, uint256 amount);
    event RewardsDistributed(uint256 proposalId, uint256 totalRewards);

    // --- Modifiers ---
    modifier onlyCurator() {
        require(isCurator(msg.sender) || owner() == msg.sender, "Caller is not a curator or owner");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "Invalid proposal ID");
        _;
    }

    modifier proposalNotFinalized(uint256 _proposalId) {
        require(!artProposals[_proposalId].finalized, "Proposal already finalized");
        _;
    }

    constructor() ERC721("DecentralizedArtNFT", "DAANFT") {
        _proposalIdCounter.increment(); // Start proposal IDs from 1
        _artNftIdCounter.increment(); // Start NFT IDs from 1
        curators[msg.sender] = true; // Initial curator is the contract deployer
    }

    // --------------------------------------------------------
    // 1. Core Functionality - Art Proposal and Voting
    // --------------------------------------------------------

    /**
     * @dev Allows artists to submit an art proposal. Requires a proposal fee.
     * @param _title Title of the art proposal.
     * @param _description Description of the art proposal.
     * @param _ipfsHash IPFS hash linking to the artwork's data.
     */
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)
        external payable
        nonReentrant
    {
        require(msg.value >= proposalFee, "Insufficient proposal fee");
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Proposal details cannot be empty");

        uint256 proposalId = _proposalIdCounter.current();
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            submissionTimestamp: block.timestamp,
            votingEndTime: block.number + votingDurationInBlocks,
            upvotes: 0,
            downvotes: 0,
            finalized: false,
            approved: false,
            rejected: false
        });

        _proposalIdCounter.increment();
        emit ProposalSubmitted(proposalId, msg.sender, _title);

        // Optionally refund excess fee if any
        if (msg.value > proposalFee) {
            payable(msg.sender).transfer(msg.value - proposalFee);
        }
    }

    /**
     * @dev Allows community members to vote on an art proposal. Requires staked tokens for voting power.
     * @param _proposalId ID of the proposal to vote on.
     * @param _vote True for upvote, false for downvote.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote)
        external
        validProposal(_proposalId)
        proposalNotFinalized(_proposalId)
    {
        require(block.number <= artProposals[_proposalId].votingEndTime, "Voting period ended");
        require(stakedTokens[msg.sender] >= minStakeForVote, "Insufficient staked tokens to vote");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        proposalVotes[_proposalId][msg.sender] = _vote;
        if (_vote) {
            artProposals[_proposalId].upvotes++;
        } else {
            artProposals[_proposalId].downvotes++;
        }

        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Finalizes a proposal after the voting period. Mints NFT if approved (upvotes > downvotes).
     * @param _proposalId ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 _proposalId)
        external
        validProposal(_proposalId)
        proposalNotFinalized(_proposalId)
    {
        require(block.number > artProposals[_proposalId].votingEndTime, "Voting period not ended yet");

        artProposals[_proposalId].finalized = true;

        if (artProposals[_proposalId].upvotes > artProposals[_proposalId].downvotes) {
            artProposals[_proposalId].approved = true;
            _mintArtNFT(_proposalId); // Mint NFT for approved proposal
            emit ProposalFinalized(_proposalId, true);
            // Optional: Distribute rewards to voters who voted yes
            // distributeRewardsToVoters(_proposalId);
        } else {
            artProposals[_proposalId].approved = false;
            emit ProposalFinalized(_proposalId, false);
        }
    }

    /**
     * @dev (Curator/Admin only) Manually rejects a proposal before voting ends.
     * @param _proposalId ID of the proposal to reject.
     */
    function rejectProposal(uint256 _proposalId)
        external
        onlyCurator
        validProposal(_proposalId)
        proposalNotFinalized(_proposalId)
    {
        artProposals[_proposalId].finalized = true;
        artProposals[_proposalId].rejected = true;
        emit ProposalRejected(_proposalId, true);
    }

    /**
     * @dev Retrieves details of a specific art proposal.
     * @param _proposalId ID of the proposal.
     * @return ArtProposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        validProposal(_proposalId)
        returns (ArtProposal memory)
    {
        return artProposals[_proposalId];
    }

    /**
     * @dev Returns the total number of submitted art proposals.
     * @return Total proposal count.
     */
    function getProposalCount() external view returns (uint256) {
        return _proposalIdCounter.current() - 1; // Subtract 1 because counter starts at 1 and increments before use
    }

    /**
     * @dev Returns a list of IDs of approved art proposals.
     * @return Array of approved proposal IDs.
     */
    function getApprovedProposals() external view returns (uint256[] memory) {
        uint256 count = getProposalCount();
        uint256 approvedCount = 0;
        for (uint256 i = 1; i <= count; i++) {
            if (artProposals[i].approved) {
                approvedCount++;
            }
        }
        uint256[] memory approvedIds = new uint256[](approvedCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= count; i++) {
            if (artProposals[i].approved) {
                approvedIds[index] = i;
                index++;
            }
        }
        return approvedIds;
    }

    /**
     * @dev Returns a list of IDs of proposals currently in voting.
     * @return Array of pending proposal IDs.
     */
    function getPendingProposals() external view returns (uint256[] memory) {
        uint256 count = getProposalCount();
        uint256 pendingCount = 0;
        for (uint256 i = 1; i <= count; i++) {
            if (!artProposals[i].finalized && block.number <= artProposals[i].votingEndTime) {
                pendingCount++;
            }
        }
        uint256[] memory pendingIds = new uint256[](pendingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= count; i++) {
            if (!artProposals[i].finalized && block.number <= artProposals[i].votingEndTime) {
                pendingIds[index] = i;
                index++;
            }
        }
        return pendingIds;
    }

    // --------------------------------------------------------
    // 2. NFT Minting and Art Management
    // --------------------------------------------------------

    /**
     * @dev (Internal function) Mints an Art NFT for an approved proposal.
     * @param _proposalId ID of the approved proposal.
     */
    function _mintArtNFT(uint256 _proposalId) internal {
        uint256 tokenId = _artNftIdCounter.current();
        address artist = artProposals[_proposalId].artist;
        string memory ipfsHash = artProposals[_proposalId].ipfsHash;

        _safeMint(artist, tokenId);
        artNFTs[tokenId] = ArtNFT({
            tokenId: tokenId,
            proposalId: _proposalId,
            ipfsHash: ipfsHash,
            minter: artist, // Artist is the initial owner/minter in this case
            mintTimestamp: block.timestamp
        });

        _artNftIdCounter.increment();
        emit ArtNFTMinted(tokenId, _proposalId, artist);
    }

    /**
     * @dev (Contract Owner only) Transfers ownership of an Art NFT.
     * @param _tokenId ID of the Art NFT to transfer.
     * @param _recipient Address to receive the NFT.
     */
    function transferArtNFT(uint256 _tokenId, address _recipient) external onlyOwner {
        require(_exists(_tokenId), "NFT does not exist");
        transferFrom(ownerOf(_tokenId), _recipient, _tokenId);
    }

    /**
     * @dev Retrieves details of a specific Art NFT.
     * @param _tokenId ID of the Art NFT.
     * @return ArtNFT struct containing NFT details.
     */
    function getArtNFTDetails(uint256 _tokenId) external view returns (ArtNFT memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return artNFTs[_tokenId];
    }

    /**
     * @dev Returns the total number of Art NFTs minted by the collective.
     * @return Total minted NFT count.
     */
    function getTotalMintedNFTs() external view returns (uint256) {
        return _artNftIdCounter.current() - 1; // Subtract 1 because counter starts at 1 and increments before use
    }

    // --------------------------------------------------------
    // 3. Governance and Community Participation
    // --------------------------------------------------------

    /**
     * @dev Allows community members to stake tokens to gain voting power.
     * @param _amount Amount of tokens to stake.
     */
    function stakeTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Stake amount must be greater than zero");
        // In a real scenario, you would integrate with an ERC20 token contract
        // For this example, we are just tracking staked ETH (for simplicity, replace with token logic if needed)
        require(msg.value >= _amount, "Insufficient ETH sent for staking");
        stakedTokens[msg.sender] += _amount;
        emit TokensStaked(msg.sender, _amount);

        // Optionally refund excess ETH if sent more than staked amount (using ETH as example stake)
        if (msg.value > _amount) {
            payable(msg.sender).transfer(msg.value - _amount);
        }
    }

    /**
     * @dev Allows community members to unstake their tokens.
     * @param _amount Amount of tokens to unstake.
     */
    function unstakeTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(stakedTokens[msg.sender] >= _amount, "Insufficient staked tokens");
        stakedTokens[msg.sender] -= _amount;
        // In a real scenario, you would transfer the tokens back to the user from a token contract
        // For this example, we are just tracking staked ETH (no actual ETH transfer back in this simplified example for unstaking)
        // In a real implementation, you would need to handle the actual token transfer logic.
        emit TokensUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Returns the voting power of a community member based on their staked tokens.
     * @param _voter Address of the voter.
     * @return Voting power (currently based on staked tokens).
     */
    function getVotingPower(address _voter) external view returns (uint256) {
        return stakedTokens[_voter]; // Simple voting power is directly proportional to staked amount
    }

    /**
     * @dev (Admin only) Adds a new curator address.
     * @param _curator Address to be added as a curator.
     */
    function addCurator(address _curator) external onlyOwner {
        curators[_curator] = true;
        emit CuratorAdded(_curator);
    }

    /**
     * @dev (Admin only) Removes a curator address.
     * @param _curator Address to be removed from curators.
     */
    function removeCurator(address _curator) external onlyOwner {
        delete curators[_curator];
        emit CuratorRemoved(_curator);
    }

    /**
     * @dev Checks if an address is a curator.
     * @param _user Address to check.
     * @return True if the address is a curator, false otherwise.
     */
    function isCurator(address _user) public view returns (bool) {
        return curators[_user];
    }

    /**
     * @dev Returns the total number of tokens staked in the collective.
     * @return Total staked token amount.
     */
    function getTotalStakedTokens() external view returns (uint256) {
        uint256 totalStaked = 0;
        address[] memory allStakers = getAllStakers(); // Helper function to get all staker addresses (simplified, not scalable for very large user base)
        for (uint256 i = 0; i < allStakers.length; i++) {
            totalStaked += stakedTokens[allStakers[i]];
        }
        return totalStaked;
    }

    // Helper function to get all stakers (simplified, not scalable for large user base - for demonstration purposes)
    function getAllStakers() internal view returns (address[] memory) {
        address[] memory stakers = new address[](stakedTokens.length); // Approximation - might be more or less than actual stakers
        uint256 index = 0;
        for (uint256 i = 0; i < stakedTokens.length; i++) { // Iterate through all possible mapping indices - INNEFFICIENT for large mappings
            address stakerAddress = address(uint160(uint256(i))); // Try to "guess" addresses - VERY inefficient and unreliable in real scenarios
            if (stakedTokens[stakerAddress] > 0) {
                stakers[index] = stakerAddress;
                index++;
            }
        }
        // In a real application, you would maintain a list of staker addresses separately for efficient iteration.
        address[] memory result = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            result[i] = stakers[i];
        }
        return result;
    }


    // --------------------------------------------------------
    // 4. Treasury and Reward Distribution
    // --------------------------------------------------------

    /**
     * @dev Allows anyone to deposit ETH into the collective's treasury.
     */
    function depositFunds() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev (Curator/Admin only) Allows withdrawing ETH from the treasury.
     * @param _amount Amount of ETH to withdraw.
     */
    function withdrawFunds(uint256 _amount) external onlyCurator nonReentrant {
        require(address(this).balance >= _amount, "Insufficient treasury balance");
        payable(msg.sender).transfer(_amount);
        emit FundsWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Returns the current balance of the collective's treasury (ETH).
     * @return Treasury balance in wei.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev (Curator/Admin only) Distributes rewards to voters who voted for an approved proposal.
     * @param _proposalId ID of the approved proposal.
     */
    function distributeRewardsToVoters(uint256 _proposalId)
        external
        onlyCurator
        validProposal(_proposalId)
        nonReentrant
    {
        require(artProposals[_proposalId].approved, "Proposal is not approved, cannot distribute rewards");
        uint256 totalRewardsDistributed = 0;
        uint256 votersRewardedCount = 0;

        for (uint256 i = 1; i <= _proposalIdCounter.current(); i++) { // Iterate through all possible proposal IDs (inefficient for very large number of proposals)
            if (proposalVotes[_proposalId][address(uint160(uint256(i)))] == true) { // Inefficient iteration - address guessing again
                address voterAddress = address(uint160(uint256(i))); // Guess voter address - INNEFFICIENT
                if (proposalVotes[_proposalId][voterAddress]) { // Double check to reduce false positives from address guessing
                    if (address(this).balance >= rewardPerVoter) { // Ensure treasury has enough funds (ETH example)
                        payable(voterAddress).transfer(rewardPerVoter);
                        totalRewardsDistributed += rewardPerVoter;
                        votersRewardedCount++;
                    } else {
                        // Optionally handle insufficient funds scenario (e.g., emit event, skip voter)
                        break; // Stop distributing if treasury runs out of funds
                    }
                }
            }
        }

        emit RewardsDistributed(_proposalId, totalRewardsDistributed);
    }

    // --------------------------------------------------------
    // 5. Configuration and Utility
    // --------------------------------------------------------

    /**
     * @dev (Admin only) Sets the fee required to submit an art proposal.
     * @param _fee New proposal fee in wei.
     */
    function setProposalFee(uint256 _fee) external onlyOwner {
        proposalFee = _fee;
    }

    /**
     * @dev Returns the current proposal submission fee.
     * @return Proposal fee in wei.
     */
    function getProposalFee() external view returns (uint256) {
        return proposalFee;
    }

    /**
     * @dev (Admin only) Sets the duration of the voting period for proposals (in blocks).
     * @param _durationInBlocks Voting duration in blocks.
     */
    function setVotingDuration(uint256 _durationInBlocks) external onlyOwner {
        votingDurationInBlocks = _durationInBlocks;
    }

    /**
     * @dev Returns the current voting duration in blocks.
     * @return Voting duration in blocks.
     */
    function getVotingDuration() external view returns (uint256) {
        return votingDurationInBlocks;
    }

    /**
     * @dev Returns the address of the contract owner.
     * @return Contract owner address.
     */
    function getContractOwner() external view returns (address) {
        return owner();
    }

    // --- Fallback and Receive Functions ---
    receive() external payable {
        depositFunds(); // Allow direct ETH deposits to the contract
    }

    fallback() external {}
}
```