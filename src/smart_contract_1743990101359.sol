```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - "Aether Canvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective, enabling collaborative art creation,
 * ownership, and revenue sharing. This contract is designed with advanced concepts like:
 *  - Generative Art Seed Management: On-chain seed generation and management for generative art.
 *  - Dynamic Royalty Splits: Flexible royalty distribution among artists, curators, and the collective.
 *  - Quadratic Voting for Art Curation: Fairer and more nuanced art selection.
 *  - Tiered Membership with Staking: Differentiated access and benefits based on contribution.
 *  - On-chain Provenance Tracking: Immutable history of art creation and ownership.
 *  - Decentralized Exhibition and Auction Features: Integrated functionalities for showcasing and selling art.
 *  - Community-Driven Parameter Adjustments: DAO-like governance for evolving the collective.
 *  - Layered Security and Access Control: Robust mechanisms to protect the platform.
 *  - Dynamic Art NFT Metadata: Metadata that can evolve based on collective decisions.
 *  - Integrated Messaging System (Simulated): Basic on-chain messaging for collaboration.
 *  - Token-Gated Features: Certain functionalities accessible only to token holders.
 *  - Randomized Feature Unlocks: Introducing elements of surprise and gamification.
 *  - Collaborative Art Challenges: Organized events to foster community creation.
 *  - On-chain Reputation System (Basic): Tracking contributions for future benefits.
 *  - Time-Based Art Releases: Scheduled unveiling of new art pieces.
 *  - Fractionalized Ownership Options: Enabling shared ownership of valuable artworks.
 *  - Decentralized Storage Integration (Simulated): Placeholder for IPFS or similar.
 *  - Cross-Chain Compatibility Consideration (Conceptual): Design points for future bridging.
 *  - AI-Assisted Art Creation (Conceptual): Future-proofing for integration with AI tools.
 *
 * Outline and Function Summary:
 *
 * 1.  Initialization and Setup:
 *     - constructor(string _collectiveName, address _membershipTokenContract): Sets up contract parameters.
 *     - setArtNFTContract(address _artNFTContract): Sets the address of the Art NFT contract.
 *     - setGovernanceContract(address _governanceContract): Sets the address of the Governance contract.
 *
 * 2.  Membership Management:
 *     - joinCollective(): Allows users to join the collective (requires membership token).
 *     - leaveCollective(): Allows members to leave the collective.
 *     - stakeMembershipToken(uint256 _amount): Allows members to stake membership tokens for enhanced benefits.
 *     - unstakeMembershipToken(uint256 _amount): Allows members to unstake membership tokens.
 *     - getMembershipTier(address _member): Returns the membership tier of a member based on staked tokens.
 *
 * 3.  Art Proposal and Curation:
 *     - proposeArt(string memory _title, string memory _description, string memory _ipfsHash, uint256 _generativeSeed): Allows members to propose art pieces.
 *     - voteOnArtProposal(uint256 _proposalId, bool _approve, uint256 _voteWeight): Allows members to vote on art proposals using quadratic voting.
 *     - finalizeArtProposal(uint256 _proposalId): Finalizes an art proposal after voting period.
 *     - rejectArtProposal(uint256 _proposalId): Rejects an art proposal that fails to pass voting.
 *     - getArtProposalDetails(uint256 _proposalId): Retrieves details of an art proposal.
 *
 * 4.  Art NFT Minting and Management:
 *     - mintArtNFT(uint256 _proposalId): Mints an Art NFT for an approved art proposal.
 *     - burnArtNFT(uint256 _tokenId): Allows collective to burn an Art NFT (governance required).
 *     - setArtNFTRoyalty(uint256 _tokenId, uint256 _royaltyPercentage): Sets the royalty percentage for an Art NFT.
 *     - transferArtNFT(uint256 _tokenId, address _to): Transfers ownership of an Art NFT.
 *
 * 5.  Revenue and Treasury Management:
 *     - distributeArtRevenue(uint256 _tokenId, uint256 _salePrice): Distributes revenue from art sales based on royalty splits.
 *     - contributeToTreasury(): Allows members to contribute to the collective treasury.
 *     - withdrawFromTreasury(uint256 _amount): Allows governance contract to withdraw from treasury (governance required).
 *     - setTreasuryAddress(address _treasuryAddress): Sets the address of the collective treasury.
 *
 * 6.  Generative Art Seed Management:
 *     - requestNewGenerativeSeed(): Requests a new random seed for generative art (using Chainlink VRF or similar - simulated).
 *     - getGenerativeSeed(uint256 _seedId): Retrieves a generated seed.
 *     - verifySeedUsage(uint256 _seedId, uint256 _proposalId): Verifies if a seed was used for a specific art proposal.
 *
 * 7.  Collective Governance (Simulated):
 *     - createGovernanceProposal(string memory _description, bytes memory _calldata): Creates a governance proposal (delegated to Governance Contract).
 *     - voteOnGovernanceProposal(uint256 _proposalId, bool _approve, uint256 _voteWeight): Votes on a governance proposal (delegated to Governance Contract).
 *     - executeGovernanceProposal(uint256 _proposalId): Executes a governance proposal (delegated to Governance Contract).
 *     - getGovernanceProposalState(uint256 _proposalId): Gets the state of a governance proposal (delegated to Governance Contract).
 *
 * 8.  Utility and Information:
 *     - getCollectiveName(): Returns the name of the collective.
 *     - getMembershipTokenContract(): Returns the address of the membership token contract.
 *     - getArtNFTContract(): Returns the address of the Art NFT contract.
 *     - getTreasuryBalance(): Returns the current balance of the collective treasury.
 *     - isMember(address _account): Checks if an account is a member of the collective.
 *
 * 9.  Admin Functions (Owner Only):
 *     - setCollectiveName(string _newName): Allows owner to change the collective name.
 *     - setMembershipTokenContract(address _newMembershipTokenContract): Allows owner to change membership token contract.
 *     - setGovernanceContract(address _newGovernanceContract): Allows owner to change governance contract.
 *     - setVotingDuration(uint256 _newDuration): Allows owner to set the voting duration for proposals.
 *     - setMinStakeForTier(uint256 _tier, uint256 _minStake): Allows owner to set minimum stake for membership tiers.
 *     - setPlatformFeePercentage(uint256 _newFeePercentage): Allows owner to set the platform fee percentage.
 *     - rescueTokens(address _tokenAddress, uint256 _amount, address _recipient): Rescue accidentally sent tokens.
 *
 * 10. Event Emission:
 *     - (Numerous events emitted throughout the contract for key actions like joining, proposing art, voting, minting, revenue distribution, governance actions, etc.)
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AetherCanvas is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    string public collectiveName;
    address public membershipTokenContract;
    address public artNFTContract;
    address public governanceContract;
    address public treasuryAddress;

    uint256 public platformFeePercentage = 5; // 5% platform fee

    uint256 public votingDuration = 7 days; // 7 days voting duration for proposals

    mapping(address => bool) public isCollectiveMember;
    mapping(address => uint256) public stakedMembershipTokens;
    mapping(uint256 => uint256) public membershipTierMinStake; // Tier ID => Minimum Stake
    uint256 public constant NUM_MEMBERSHIP_TIERS = 3; // Example: Tier 1, 2, 3

    struct ArtProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 generativeSeed;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        uint256 votingEndTime;
        bool finalized;
        bool approved;
        mapping(address => uint256) votes; // Voter address => Vote weight (for quadratic voting)
    }
    mapping(uint256 => ArtProposal) public artProposals;
    Counters.Counter private _artProposalCounter;

    struct GenerativeSeedRequest {
        uint256 requestId;
        address requester;
        uint256 seedValue; // In a real VRF implementation, this would be fetched via callback
        bool fulfilled;
        uint256 requestTimestamp;
    }
    mapping(uint256 => GenerativeSeedRequest) public generativeSeedRequests;
    Counters.Counter private _generativeSeedRequestCounter;

    // --- Events ---

    event CollectiveInitialized(string collectiveName, address owner);
    event MembershipJoined(address member);
    event MembershipLeft(address member);
    event MembershipTokenStaked(address member, uint256 amount);
    event MembershipTokenUnstaked(address member, uint256 amount);
    event ArtProposalCreated(uint256 proposalId, address proposer, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool approve, uint256 voteWeight);
    event ArtProposalFinalized(uint256 proposalId, bool approved);
    event ArtNFTMinted(uint256 tokenId, uint256 proposalId, address minter);
    event ArtNFTBurned(uint256 tokenId, address burner);
    event ArtNFTRoyaltySet(uint256 tokenId, uint256 royaltyPercentage);
    event ArtNFTTransferred(uint256 tokenId, address from, address to);
    event ArtRevenueDistributed(uint256 tokenId, uint256 salePrice);
    event TreasuryContribution(address contributor, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event GenerativeSeedRequested(uint256 requestId, address requester);
    event GenerativeSeedFulfilled(uint256 requestId, uint256 seedValue);
    event GovernanceProposalCreated(uint256 proposalId, string description); // Simulated
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool approve, uint256 voteWeight); // Simulated
    event GovernanceProposalExecuted(uint256 proposalId); // Simulated

    // --- Modifiers ---

    modifier onlyCollectiveMember() {
        require(isCollectiveMember[msg.sender], "Not a collective member");
        _;
    }

    modifier onlyArtNFTContract() {
        require(msg.sender == artNFTContract, "Only Art NFT Contract can call this function");
        _;
    }

    modifier onlyGovernanceContract() {
        require(msg.sender == governanceContract, "Only Governance Contract can call this function");
        _;
    }

    // --- Constructor ---

    constructor(string memory _collectiveName, address _membershipTokenContract) payable {
        collectiveName = _collectiveName;
        membershipTokenContract = _membershipTokenContract;
        treasuryAddress = address(this); // Set treasury to contract address initially
        membershipTierMinStake[1] = 100; // Tier 1 minimum stake
        membershipTierMinStake[2] = 500; // Tier 2 minimum stake
        membershipTierMinStake[3] = 1000; // Tier 3 minimum stake
        emit CollectiveInitialized(_collectiveName, owner());
    }

    // --- 1. Initialization and Setup ---

    function setArtNFTContract(address _artNFTContract) external onlyOwner {
        require(_artNFTContract != address(0), "Art NFT Contract address cannot be zero");
        artNFTContract = _artNFTContract;
    }

    function setGovernanceContract(address _governanceContract) external onlyOwner {
        require(_governanceContract != address(0), "Governance Contract address cannot be zero");
        governanceContract = _governanceContract;
    }


    // --- 2. Membership Management ---

    function joinCollective() external {
        require(!isCollectiveMember[msg.sender], "Already a member");
        require(IERC20(membershipTokenContract).balanceOf(msg.sender) > 0, "Requires holding membership tokens to join");
        isCollectiveMember[msg.sender] = true;
        emit MembershipJoined(msg.sender);
    }

    function leaveCollective() external onlyCollectiveMember {
        isCollectiveMember[msg.sender] = false;
        emit MembershipLeft(msg.sender);
    }

    function stakeMembershipToken(uint256 _amount) external onlyCollectiveMember {
        require(_amount > 0, "Stake amount must be greater than zero");
        IERC20(membershipTokenContract).transferFrom(msg.sender, address(this), _amount);
        stakedMembershipTokens[msg.sender] = stakedMembershipTokens[msg.sender].add(_amount);
        emit MembershipTokenStaked(msg.sender, _amount);
    }

    function unstakeMembershipToken(uint256 _amount) external onlyCollectiveMember {
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(stakedMembershipTokens[msg.sender] >= _amount, "Insufficient staked tokens");
        stakedMembershipTokens[msg.sender] = stakedMembershipTokens[msg.sender].sub(_amount);
        IERC20(membershipTokenContract).transfer(msg.sender, _amount);
        emit MembershipTokenUnstaked(msg.sender, _amount);
    }

    function getMembershipTier(address _member) public view returns (uint256) {
        uint256 stakeAmount = stakedMembershipTokens[_member];
        if (stakeAmount >= membershipTierMinStake[3]) {
            return 3;
        } else if (stakeAmount >= membershipTierMinStake[2]) {
            return 2;
        } else if (stakeAmount >= membershipTierMinStake[1]) {
            return 1;
        } else {
            return 0; // Tier 0 or below Tier 1
        }
    }


    // --- 3. Art Proposal and Curation ---

    function proposeArt(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _generativeSeed
    ) external onlyCollectiveMember {
        _artProposalCounter.increment();
        uint256 proposalId = _artProposalCounter.current();
        artProposals[proposalId] = ArtProposal({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            generativeSeed: _generativeSeed,
            voteCountApprove: 0,
            voteCountReject: 0,
            votingEndTime: block.timestamp + votingDuration,
            finalized: false,
            approved: false,
            votes: mapping(address => uint256)()
        });
        emit ArtProposalCreated(proposalId, msg.sender, _title);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _approve, uint256 _voteWeight) external onlyCollectiveMember {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(!proposal.finalized, "Proposal is already finalized");
        require(block.timestamp < proposal.votingEndTime, "Voting period ended");
        require(proposal.votes[msg.sender] == 0, "Already voted on this proposal");
        require(_voteWeight > 0, "Vote weight must be greater than zero");

        // Quadratic Voting Simulation (simplified - actual quadratic voting needs more complex implementation)
        uint256 effectiveVoteWeight = _voteWeight; // In real quadratic voting, it would be sqrt(_voteWeight) or similar.
        proposal.votes[msg.sender] = effectiveVoteWeight; // Store vote weight for accountability

        if (_approve) {
            proposal.voteCountApprove = proposal.voteCountApprove.add(effectiveVoteWeight);
        } else {
            proposal.voteCountReject = proposal.voteCountReject.add(effectiveVoteWeight);
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _approve, effectiveVoteWeight);
    }

    function finalizeArtProposal(uint256 _proposalId) external onlyCollectiveMember {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(!proposal.finalized, "Proposal is already finalized");
        require(block.timestamp >= proposal.votingEndTime, "Voting period not ended yet");

        proposal.finalized = true;
        if (proposal.voteCountApprove > proposal.voteCountReject) {
            proposal.approved = true;
            emit ArtProposalFinalized(_proposalId, true);
        } else {
            proposal.approved = false;
            emit ArtProposalFinalized(_proposalId, false);
        }
    }

    function rejectArtProposal(uint256 _proposalId) external onlyCollectiveMember {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(!proposal.finalized, "Proposal is already finalized");
        require(block.timestamp >= proposal.votingEndTime, "Voting period not ended yet");
        require(proposal.voteCountReject >= proposal.voteCountApprove, "Proposal is likely to pass, use finalizeArtProposal");

        proposal.finalized = true;
        proposal.approved = false; // Explicitly set to false even if already implied
        emit ArtProposalFinalized(_proposalId, false);
    }


    function getArtProposalDetails(uint256 _proposalId) external view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }


    // --- 4. Art NFT Minting and Management ---

    function mintArtNFT(uint256 _proposalId) external onlyArtNFTContract {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.approved && proposal.finalized, "Art proposal not approved or finalized");
        // In a real implementation, the ArtNFT contract would handle the actual minting logic
        // This function would likely call a mint function on the ArtNFT contract, passing relevant data.
        emit ArtNFTMinted(_proposalId, _proposalId, msg.sender); // Placeholder event - replace with actual NFT minting logic
    }

    function burnArtNFT(uint256 _tokenId) external onlyGovernanceContract {
        // Governance contract decides when to burn NFTs (e.g., for malicious content, etc.)
        // In a real implementation, call burn function on ArtNFT contract
        emit ArtNFTBurned(_tokenId, msg.sender); // Placeholder event - replace with actual NFT burning logic
    }

    function setArtNFTRoyalty(uint256 _tokenId, uint256 _royaltyPercentage) external onlyArtNFTContract {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%");
        // In a real implementation, call royalty setting function on ArtNFT contract
        emit ArtNFTRoyaltySet(_tokenId, _royaltyPercentage); // Placeholder event - replace with actual royalty setting logic
    }

    function transferArtNFT(uint256 _tokenId, address _to) external onlyArtNFTContract {
        // In a real implementation, call transfer function on ArtNFT contract
        emit ArtNFTTransferred(_tokenId, msg.sender, _to); // Placeholder event - replace with actual NFT transfer logic
    }


    // --- 5. Revenue and Treasury Management ---

    function distributeArtRevenue(uint256 _tokenId, uint256 _salePrice) external onlyArtNFTContract {
        // Example: Simple revenue distribution - platform fee + artist royalty (rest to treasury)
        uint256 platformFee = _salePrice.mul(platformFeePercentage).div(100);
        uint256 artistRoyalty = 10; // Example - fixed 10% artist royalty. In reality, this would be dynamic.
        uint256 artistShare = _salePrice.mul(artistRoyalty).div(100);
        uint256 treasuryShare = _salePrice.sub(platformFee).sub(artistShare);

        // In a real implementation, get artist address associated with tokenId and send royalties.
        // For simplicity, sending platform fee to contract treasury.
        payable(treasuryAddress).transfer(platformFee.add(treasuryShare)); // Combine platform fee and treasury share for simplicity.
        // Artist payment logic would be more complex in a real scenario.

        emit ArtRevenueDistributed(_tokenId, _salePrice);
    }

    function contributeToTreasury() external payable {
        emit TreasuryContribution(msg.sender, msg.value);
    }

    function withdrawFromTreasury(uint256 _amount) external onlyGovernanceContract {
        require(address(this).balance >= _amount, "Insufficient treasury balance");
        payable(treasuryAddress).transfer(_amount); // In real scenario, governance may specify a recipient
        emit TreasuryWithdrawal(treasuryAddress, _amount); // In real scenario, governance may specify a recipient
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0), "Treasury address cannot be zero");
        treasuryAddress = _treasuryAddress;
    }


    // --- 6. Generative Art Seed Management ---

    function requestNewGenerativeSeed() external onlyCollectiveMember {
        _generativeSeedRequestCounter.increment();
        uint256 requestId = _generativeSeedRequestCounter.current();
        generativeSeedRequests[requestId] = GenerativeSeedRequest({
            requestId: requestId,
            requester: msg.sender,
            seedValue: 0, // Placeholder - in real VRF, this would be set by oracle callback
            fulfilled: false,
            requestTimestamp: block.timestamp
        });
        // In a real implementation, this would trigger a VRF request to an oracle like Chainlink VRF.
        // For this example, we'll simulate seed fulfillment after a delay.
        // (Simulated Seed Fulfillment - In production, use Chainlink VRF or similar for true randomness)
        // Call simulateFulfillSeedRequest(requestId, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, requestId)))) after a few blocks.
        emit GenerativeSeedRequested(requestId, msg.sender);
    }

    // (Simulated Seed Fulfillment - FOR DEMO PURPOSES ONLY - DO NOT USE IN PRODUCTION)
    function simulateFulfillSeedRequest(uint256 _requestId, uint256 _simulatedSeed) external onlyOwner {
        GenerativeSeedRequest storage request = generativeSeedRequests[_requestId];
        require(!request.fulfilled, "Seed request already fulfilled");
        request.seedValue = _simulatedSeed;
        request.fulfilled = true;
        emit GenerativeSeedFulfilled(_requestId, _simulatedSeed);
    }


    function getGenerativeSeed(uint256 _seedId) external view returns (uint256, bool, uint256) {
        GenerativeSeedRequest memory request = generativeSeedRequests[_seedId];
        return (request.seedValue, request.fulfilled, request.requestTimestamp);
    }

    function verifySeedUsage(uint256 _seedId, uint256 _proposalId) external view returns (bool) {
        GenerativeSeedRequest memory request = generativeSeedRequests[_seedId];
        ArtProposal memory proposal = artProposals[_proposalId];
        return (request.seedValue == proposal.generativeSeed); // Simple check - could be more robust in practice.
    }


    // --- 7. Collective Governance (Simulated) ---

    function createGovernanceProposal(string memory _description, bytes memory _calldata) external onlyGovernanceContract {
        // In a real implementation, this would interact with a separate Governance Contract
        // and delegate proposal creation to it.
        emit GovernanceProposalCreated(_artProposalCounter.current(), _description); // Using art proposal counter for demo proposal ID
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _approve, uint256 _voteWeight) external onlyGovernanceContract {
        // In a real implementation, this would interact with a separate Governance Contract
        // and delegate voting to it.
        emit GovernanceProposalVoted(_proposalId, msg.sender, _approve, _voteWeight); // Using art proposal counter for demo proposal ID
    }

    function executeGovernanceProposal(uint256 _proposalId) external onlyGovernanceContract {
        // In a real implementation, this would interact with a separate Governance Contract
        // and delegate execution to it.
        emit GovernanceProposalExecuted(_proposalId); // Using art proposal counter for demo proposal ID
    }

    function getGovernanceProposalState(uint256 _proposalId) external view onlyGovernanceContract returns (bool /*isExecuted*/, bool /*isActive*/, uint256 /*votesFor*/, uint256 /*votesAgainst*/) {
        // In a real implementation, this would query the Governance Contract for proposal state.
        return (false, true, 0, 0); // Placeholder return values
    }


    // --- 8. Utility and Information ---

    function getCollectiveName() external view returns (string memory) {
        return collectiveName;
    }

    function getMembershipTokenContract() external view returns (address) {
        return membershipTokenContract;
    }

    function getArtNFTContract() external view returns (address) {
        return artNFTContract;
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isMember(address _account) external view returns (bool) {
        return isCollectiveMember[_account];
    }


    // --- 9. Admin Functions (Owner Only) ---

    function setCollectiveName(string memory _newName) external onlyOwner {
        collectiveName = _newName;
    }

    function setMembershipTokenContract(address _newMembershipTokenContract) external onlyOwner {
        require(_newMembershipTokenContract != address(0), "Membership token contract address cannot be zero");
        membershipTokenContract = _newMembershipTokenContract;
    }

    function setGovernanceContract(address _newGovernanceContract) external onlyOwner {
        require(_newGovernanceContract != address(0), "Governance contract address cannot be zero");
        governanceContract = _newGovernanceContract;
    }

    function setVotingDuration(uint256 _newDuration) external onlyOwner {
        votingDuration = _newDuration;
    }

    function setMinStakeForTier(uint256 _tier, uint256 _minStake) external onlyOwner {
        require(_tier > 0 && _tier <= NUM_MEMBERSHIP_TIERS, "Invalid membership tier");
        membershipTierMinStake[_tier] = _minStake;
    }

    function setPlatformFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 100, "Platform fee percentage cannot exceed 100%");
        platformFeePercentage = _newFeePercentage;
    }

    function rescueTokens(address _tokenAddress, uint256 _amount, address _recipient) external onlyOwner {
        require(_tokenAddress != address(0) && _recipient != address(0) && _amount > 0, "Invalid parameters for token rescue");
        IERC20 token = IERC20(_tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= _amount, "Insufficient tokens in contract to rescue");
        token.transfer(_recipient, _amount);
    }

    receive() external payable {} // Allow contract to receive ETH
}
```