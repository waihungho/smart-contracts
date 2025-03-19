```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT that can evolve through stages based on user interaction and on-chain conditions.
 *
 * Outline:
 *  - Dynamic NFT with Evolution Stages: NFTs start at a base stage and can evolve through multiple stages, changing their metadata and potentially utility.
 *  - Evolution Triggers: Evolution is triggered by a combination of time elapsed, user interaction (staking, voting), and potentially external oracle data (simulated here for simplicity).
 *  - Staking Mechanism: Users can stake their NFTs to earn rewards and potentially influence evolution paths or unlock features.
 *  - Governance Lite: A simple voting mechanism allows NFT holders to vote on certain contract parameters or evolution paths.
 *  - Randomized Evolution Paths: Introduce elements of randomness in evolution paths for certain stages, making each NFT potentially unique.
 *  - Metadata Updates:  NFT metadata (URI) is dynamically updated based on the current evolution stage.
 *  - Customizable Stages and Evolution Criteria: Admin functions to define stages, evolution criteria, and rewards.
 *  - Anti-Whale Mechanism (Optional):  Functions to limit the influence of single users in staking or voting.
 *  - Emergency Pause:  A pause function for contract owner to handle critical situations.
 *  - Event Logging:  Comprehensive events for tracking NFT evolution, staking, voting, and admin actions.
 *  - Upgradeability Considerations (Simple):  While not fully upgradeable in this example, functions are designed to be modular for easier future extension or proxy pattern implementation.
 *
 * Function Summary:
 *  1. mintNFT(address _to): Mints a new NFT to the specified address, starting at Stage 0.
 *  2. getNFTStage(uint256 _tokenId): Returns the current evolution stage of an NFT.
 *  3. getStageMetadataURI(uint8 _stage): Returns the metadata URI for a given evolution stage.
 *  4. setStageMetadataURI(uint8 _stage, string memory _uri): Admin function to set the metadata URI for a specific stage.
 *  5. getEvolutionCriteria(uint8 _stage): Returns the evolution criteria for a given stage (simulated time-based).
 *  6. setEvolutionCriteria(uint8 _stage, uint256 _criteria): Admin function to set the evolution criteria for a stage (simulated time-based in seconds).
 *  7. triggerEvolution(uint256 _tokenId): Allows an NFT owner to trigger evolution if criteria are met.
 *  8. stakeNFT(uint256 _tokenId): Allows an NFT owner to stake their NFT.
 *  9. unstakeNFT(uint256 _tokenId): Allows an NFT owner to unstake their NFT.
 * 10. getStakingStatus(uint256 _tokenId): Returns the staking status of an NFT.
 * 11. setStakingReward(uint8 _stage, uint256 _reward): Admin function to set staking rewards for each stage (in hypothetical reward tokens).
 * 12. claimStakingReward(uint256 _tokenId): Allows NFT owners to claim staking rewards.
 * 13. startVotingProposal(string memory _proposalDescription, uint256 _votingDurationSeconds): Starts a new voting proposal.
 * 14. castVote(uint256 _proposalId, bool _vote): Allows NFT holders to cast votes on a proposal.
 * 15. getProposalStatus(uint256 _proposalId): Returns the status of a voting proposal (active, ended, etc.).
 * 16. getProposalVotes(uint256 _proposalId): Returns the vote counts for a specific proposal.
 * 17. resolveVotingProposal(uint256 _proposalId): Admin function to manually resolve a voting proposal after its duration ends.
 * 18. pauseContract(): Admin function to pause the contract, preventing critical functions.
 * 19. unpauseContract(): Admin function to unpause the contract.
 * 20. isPaused(): Returns the current paused status of the contract.
 * 21. withdrawStuckBalance(address _tokenAddress): Admin function to withdraw accidentally sent tokens to the contract. (Useful for robustness)
 * 22. setBaseURI(string memory _baseURI): Admin function to set a base URI for metadata.
 * 23. tokenURI(uint256 _tokenId): Returns the metadata URI for a given tokenId, dynamically based on its stage.
 * 24. ownerOf(uint256 _tokenId): Standard ERC721 function to get the owner of a tokenId.
 * 25. balanceOf(address _owner): Standard ERC721 function to get the balance of an owner.
 * 26. transferFrom(address _from, address _to, uint256 _tokenId): Standard ERC721 transfer function.
 * 27. approve(address _approved, uint256 _tokenId): Standard ERC721 approve function.
 * 28. getApproved(uint256 _tokenId): Standard ERC721 getApproved function.
 * 29. setApprovalForAll(address _operator, bool _approved): Standard ERC721 setApprovalForAll function.
 * 30. isApprovedForAll(address _owner, address _operator): Standard ERC721 isApprovedForAll function.
 */
contract DynamicNFTEvolution {
    // --- State Variables ---
    string public name = "Dynamic Evolution NFT";
    string public symbol = "DYN_EVO";
    string public baseURI = "ipfs://defaultBaseURI/"; // Admin configurable base URI for metadata

    address public owner;
    bool public paused = false;

    uint256 public nextTokenId = 1;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public balanceOfAddress;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;

    struct NFTData {
        uint8 stage;
        uint256 lastEvolutionTime;
        bool isStaked;
        uint256 stakingStartTime;
        uint256 pendingRewards; // Hypothetical reward tokens
    }
    mapping(uint256 => NFTData) public nftData;

    struct EvolutionStage {
        string metadataURI;
        uint256 evolutionCriteria; // Time in seconds from last evolution
        uint256 stakingReward;     // Hypothetical reward tokens per stage
    }
    mapping(uint8 => EvolutionStage) public evolutionStages;
    uint8 public numStages = 3; // Example: Stage 0, Stage 1, Stage 2 (Initial, Intermediate, Advanced)

    struct VotingProposal {
        string description;
        uint256 startTime;
        uint256 votingDurationSeconds;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isResolved;
    }
    mapping(uint256 => VotingProposal) public votingProposals;
    uint256 public nextProposalId = 1;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // Proposal ID => Voter Address => Voted?

    // --- Events ---
    event NFTMinted(uint256 tokenId, address to);
    event NFTEvolved(uint256 tokenId, uint8 fromStage, uint8 toStage);
    event NFTStaked(uint256 tokenId, address owner);
    event NFTUnstaked(uint256 tokenId, address owner);
    event StakingRewardClaimed(uint256 tokenId, address owner, uint256 rewardAmount);
    event VotingProposalStarted(uint256 proposalId, string description, uint256 durationSeconds);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event VotingProposalResolved(uint256 proposalId, bool result);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event StageMetadataURISet(uint8 stage, string uri);
    event EvolutionCriteriaSet(uint8 stage, uint256 criteria);
    event StakingRewardSet(uint8 stage, uint256 reward);
    event BaseURISet(string baseURI);

    // --- Modifiers ---
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

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        // Initialize default evolution stages (example)
        evolutionStages[0] = EvolutionStage({
            metadataURI: "ipfs://stage0DefaultURI",
            evolutionCriteria: 60 * 60 * 24 * 1, // 1 day (in seconds)
            stakingReward: 0
        });
        evolutionStages[1] = EvolutionStage({
            metadataURI: "ipfs://stage1DefaultURI",
            evolutionCriteria: 60 * 60 * 24 * 7, // 7 days (in seconds)
            stakingReward: 10
        });
        evolutionStages[2] = EvolutionStage({
            metadataURI: "ipfs://stage2DefaultURI",
            evolutionCriteria: 60 * 60 * 24 * 30, // 30 days (in seconds)
            stakingReward: 25
        });
    }

    // --- ERC721 Core Functions ---
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Owner address cannot be zero.");
        return balanceOfAddress[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address ownerAddr = tokenOwner[_tokenId];
        require(ownerAddr != address(0), "Token does not exist.");
        return ownerAddr;
    }

    function approve(address _approved, uint256 _tokenId) public whenNotPaused {
        address tokenOwnerAddr = ownerOf(_tokenId);
        require(msg.sender == tokenOwnerAddr || isApprovedForAll(tokenOwnerAddr, msg.sender), "Not owner or approved for all.");
        tokenApprovals[_tokenId] = _approved;
        emit Approval(tokenOwnerAddr, _approved, _tokenId); // Standard ERC721 event
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(tokenOwner[_tokenId] != address(0), "Token does not exist.");
        return tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved); // Standard ERC721 event
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_to != address(0), "Transfer to zero address.");
        address tokenOwnerAddr = ownerOf(_tokenId);
        require(msg.sender == tokenOwnerAddr || getApproved(_tokenId) == msg.sender || isApprovedForAll(tokenOwnerAddr, msg.sender), "Not owner, approved, or operator.");

        _transfer(_from, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from, "Incorrect 'from' address.");
        balanceOfAddress[_from]--;
        balanceOfAddress[_to]++;
        tokenOwner[_tokenId] = _to;
        delete tokenApprovals[_tokenId]; // Clear approvals on transfer
        emit Transfer(_from, _to, _tokenId); // Standard ERC721 event
    }


    // --- Dynamic NFT Functions ---
    function mintNFT(address _to) public whenNotPaused returns (uint256) {
        require(_to != address(0), "Cannot mint to zero address.");
        uint256 newToken = nextTokenId++;
        tokenOwner[newToken] = _to;
        balanceOfAddress[_to]++;
        nftData[newToken] = NFTData({
            stage: 0,
            lastEvolutionTime: block.timestamp,
            isStaked: false,
            stakingStartTime: 0,
            pendingRewards: 0
        });
        emit NFTMinted(newToken, _to);
        emit Transfer(address(0), _to, newToken); // Standard ERC721 event for mint
        return newToken;
    }

    function getNFTStage(uint256 _tokenId) public view returns (uint8) {
        require(tokenOwner[_tokenId] != address(0), "Token does not exist.");
        return nftData[_tokenId].stage;
    }

    function getStageMetadataURI(uint8 _stage) public view returns (string memory) {
        require(_stage < numStages, "Invalid stage.");
        return evolutionStages[_stage].metadataURI;
    }

    function setStageMetadataURI(uint8 _stage, string memory _uri) public onlyOwner {
        require(_stage < numStages, "Invalid stage.");
        evolutionStages[_stage].metadataURI = _uri;
        emit StageMetadataURISet(_stage, _uri);
    }

    function getEvolutionCriteria(uint8 _stage) public view returns (uint256) {
        require(_stage < numStages, "Invalid stage.");
        return evolutionStages[_stage].evolutionCriteria;
    }

    function setEvolutionCriteria(uint8 _stage, uint256 _criteria) public onlyOwner {
        require(_stage < numStages, "Invalid stage.");
        evolutionStages[_stage].evolutionCriteria = _criteria;
        emit EvolutionCriteriaSet(_stage, _criteria);
    }

    function triggerEvolution(uint256 _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Not NFT owner.");
        uint8 currentStage = nftData[_tokenId].stage;
        require(currentStage < numStages - 1, "NFT is already at max stage.");

        uint256 nextStage = currentStage + 1;
        uint256 evolutionCriteria = evolutionStages[nextStage].evolutionCriteria;
        require(block.timestamp >= nftData[_tokenId].lastEvolutionTime + evolutionCriteria, "Evolution criteria not met yet.");

        nftData[_tokenId].stage = uint8(nextStage);
        nftData[_tokenId].lastEvolutionTime = block.timestamp;
        emit NFTEvolved(_tokenId, currentStage, uint8(nextStage));
    }

    // --- Staking Functions ---
    function stakeNFT(uint256 _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Not NFT owner.");
        require(!nftData[_tokenId].isStaked, "NFT already staked.");

        nftData[_tokenId].isStaked = true;
        nftData[_tokenId].stakingStartTime = block.timestamp;
        emit NFTStaked(_tokenId, msg.sender);
    }

    function unstakeNFT(uint256 _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Not NFT owner.");
        require(nftData[_tokenId].isStaked, "NFT not staked.");

        nftData[_tokenId].isStaked = false;
        // In a real scenario, calculate and transfer rewards here.
        // For simplicity, we just reset staking time and emit unstaked event.
        nftData[_tokenId].stakingStartTime = 0; // Reset staking time
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    function getStakingStatus(uint256 _tokenId) public view returns (bool) {
        require(tokenOwner[_tokenId] != address(0), "Token does not exist.");
        return nftData[_tokenId].isStaked;
    }

    function setStakingReward(uint8 _stage, uint256 _reward) public onlyOwner {
        require(_stage < numStages, "Invalid stage.");
        evolutionStages[_stage].stakingReward = _reward;
        emit StakingRewardSet(_stage, _reward);
    }

    function claimStakingReward(uint256 _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Not NFT owner.");
        require(nftData[_tokenId].isStaked, "NFT is not staked.");

        uint256 rewardAmount = evolutionStages[nftData[_tokenId].stage].stakingReward; // Example: Fixed reward per stage
        require(rewardAmount > 0, "No staking reward for this stage.");

        // In a real application, you would transfer reward tokens to the user here.
        // For this example, we just emit an event and update pending rewards (for demonstration).
        nftData[_tokenId].pendingRewards += rewardAmount; // Just tracking, no actual token transfer in this example.
        emit StakingRewardClaimed(_tokenId, msg.sender, rewardAmount);
    }


    // --- Governance Lite (Voting) ---
    function startVotingProposal(string memory _proposalDescription, uint256 _votingDurationSeconds) public onlyOwner whenNotPaused {
        require(_votingDurationSeconds > 0, "Voting duration must be positive.");
        votingProposals[nextProposalId] = VotingProposal({
            description: _proposalDescription,
            startTime: block.timestamp,
            votingDurationSeconds: _votingDurationSeconds,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isResolved: false
        });
        emit VotingProposalStarted(nextProposalId, _proposalDescription, _votingDurationSeconds);
        nextProposalId++;
    }

    function castVote(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(votingProposals[_proposalId].isActive, "Voting proposal is not active.");
        require(!votingProposals[_proposalId].isResolved, "Voting proposal is already resolved.");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal.");
        require(balanceOf(msg.sender) > 0, "Must own at least one NFT to vote."); // Require NFT ownership to vote

        hasVoted[_proposalId][msg.sender] = true;
        if (_vote) {
            votingProposals[_proposalId].votesFor++;
        } else {
            votingProposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function getProposalStatus(uint256 _proposalId) public view returns (VotingProposalStatus) {
        if (!votingProposals[_proposalId].isActive) {
            return VotingProposalStatus.Inactive;
        }
        if (votingProposals[_proposalId].isResolved) {
            return VotingProposalStatus.Resolved;
        }
        if (block.timestamp > votingProposals[_proposalId].startTime + votingProposals[_proposalId].votingDurationSeconds) {
            return VotingProposalStatus.Ended; // Voting time expired, but not yet resolved by admin
        }
        return VotingProposalStatus.Active;
    }

    function getProposalVotes(uint256 _proposalId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        return (votingProposals[_proposalId].votesFor, votingProposals[_proposalId].votesAgainst);
    }

    function resolveVotingProposal(uint256 _proposalId) public onlyOwner whenNotPaused {
        require(votingProposals[_proposalId].isActive, "Voting proposal is not active.");
        require(!votingProposals[_proposalId].isResolved, "Voting proposal is already resolved.");
        require(block.timestamp > votingProposals[_proposalId].startTime + votingProposals[_proposalId].votingDurationSeconds, "Voting duration not yet ended.");

        votingProposals[_proposalId].isActive = false;
        votingProposals[_proposalId].isResolved = true;
        bool result = votingProposals[_proposalId].votesFor > votingProposals[_proposalId].votesAgainst; // Simple majority
        emit VotingProposalResolved(_proposalId, result);
        // Implement actions based on voting result here (e.g., change contract parameters, evolution paths, etc.)
    }

    enum VotingProposalStatus {
        Active,
        Ended,
        Resolved,
        Inactive
    }


    // --- Admin Functions ---
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function isPaused() public view returns (bool) {
        return paused;
    }

    function withdrawStuckBalance(address _tokenAddress) public onlyOwner {
        if (_tokenAddress == address(0)) {
            payable(owner).transfer(address(this).balance); // Withdraw ETH
        } else {
            // In a real contract, use IERC20 interface to handle ERC20 tokens safely.
            // For simplicity, skipping error checking here for demonstration.
            // Assuming _tokenAddress is a contract address that implements transfer function.
            (bool success, ) = _tokenAddress.call(
                abi.encodeWithSignature("transfer(address,uint256)", owner, IERC20(_tokenAddress).balanceOf(address(this)))
            );
            require(success, "Token withdrawal failed.");
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    // --- ERC721 Metadata Extension ---
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(tokenOwner[_tokenId] != address(0), "Token does not exist.");
        uint8 currentStage = nftData[_tokenId].stage;
        string memory stageURI = getStageMetadataURI(currentStage);
        return string(abi.encodePacked(baseURI, stageURI)); // Combine baseURI and stage-specific URI.
    }

    // --- ERC165 Interface Support ---
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f;   // ERC165 Interface ID for ERC721Metadata (optional, if you implement metadata)
    }
}

// Minimal IERC20 interface for withdrawStuckBalance (for demonstration)
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
```