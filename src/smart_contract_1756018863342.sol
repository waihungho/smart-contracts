This smart contract, "AetherMindCollective," envisions a decentralized platform where collective human intelligence, facilitated by AI oracles, creates, curates, and evolves a shared knowledge base represented by dynamic NFTs. Users contribute prompts, AI generates insights, and the community votes to validate these contributions, earning reputation and rewards. The knowledge itself is embodied in "WisdomNode" NFTs that can be upgraded over time.

The design emphasizes:
*   **AI Oracle Integration:** For generative content and intelligent analysis to power dynamic NFTs.
*   **Dynamic NFTs (Wisdom Nodes):** NFTs whose metadata and perceived value can evolve based on new AI inputs and community consensus.
*   **Reputation System:** On-chain reputation built through active and successful curation, influencing reward distribution and governance weight.
*   **Adaptive Curation & Rewards:** A system where community members stake tokens to curate and are rewarded for their effective contributions to the knowledge base's quality.
*   **Decentralized Governance:** A DAO-like structure allowing token holders to propose and vote on key protocol parameters.

---

### AetherMindCollective: Outline and Function Summary

**I. Core Infrastructure & Access Control**
1.  **`constructor`**: Initializes the contract with the `AetherMindToken` address, sets the deployer as the initial owner, and defines initial parameters.
2.  **`setOracleAddress`**: (Admin) Sets the trusted address of the AI oracle contract, which fulfills AI-related requests.
3.  **`pauseContract`**: (Admin) Halts critical contract operations (e.g., contributions, staking, governance actions) in emergencies.
4.  **`unpauseContract`**: (Admin) Resumes contract operations after a pause.
5.  **`withdrawTreasuryFunds`**: (Admin) Allows the owner to withdraw accumulated protocol fees (e.g., contribution fees) from the contract.

**II. Contribution & Synthesis**
6.  **`submitContributionPrompt`**: Users submit a text prompt or data. A small `AetherMindToken` fee is required to cover potential AI processing costs and deter spam. This initiates an AI oracle request.
7.  **`fulfillAIGenerateOutput`**: (Oracle-Only) Callback function used by the AI oracle to deliver the synthesized output (e.g., text, image URI) for a submitted prompt. Upon successful fulfillment, a `WisdomNodeNFT` is minted in a "pending curation" state.
8.  **`requestWisdomNodeUpgrade`**: Holders of a `WisdomNodeNFT` can request an AI-driven upgrade for their node (e.g., enhancing its content, generating new insights). This burns a small `AetherMindToken` fee and initiates another AI oracle request.
9.  **`fulfillAINodeUpgrade`**: (Oracle-Only) Callback function used by the AI oracle to provide updated metadata URI for a `WisdomNodeNFT` after an upgrade request, moving the node to a "pending upgrade curation" state.

**III. Curation & Validation**
10. **`stakeForCurationRights`**: Users stake `AetherMindToken`s to become a curator, gaining voting power for contributions and upgrades. Staking confers reputation and eligibility for curation rewards.
11. **`unstakeCurationTokens`**: Curators can unstake their `AetherMindToken`s after a defined cooldown period, relinquishing their curator status and voting power.
12. **`voteOnContribution`**: Staked curators vote on the quality and relevance of pending `WisdomNodeNFT` contributions. Votes influence the contribution's final status (validated or rejected).
13. **`voteOnWisdomNodeUpgrade`**: Staked curators vote on the validity and improvement of a proposed `WisdomNodeNFT` upgrade.
14. **`finalizeContribution`**: (Callable after voting period) Finalizes a contribution based on curator votes. If validated, the `WisdomNodeNFT` becomes fully recognized; otherwise, it's rejected.
15. **`distributeCurationRewards`**: (Admin/Scheduled) Distributes `AetherMindToken` rewards to active and successful curators, based on their stake, reputation, and voting accuracy.

**IV. Reputation & Dynamic NFTs**
16. **`getUserReputation`**: Retrieves the on-chain reputation score for a specific user, accumulated through successful contributions and accurate curation.
17. **`getWisdomNodeDetails`**: Provides comprehensive information about a `WisdomNodeNFT`, including its owner, current metadata URI, and upgrade status.
18. **`getPendingContributionDetails`**: Retrieves all relevant details for a contribution that is currently awaiting AI processing or community curation.

**V. Tokenomics & Governance**
19. **`getCurrentStakedBalance`**: Returns the total amount of `AetherMindToken`s a user has currently staked within the protocol.
20. **`proposeGovernanceChange`**: Staked token holders can propose changes to protocol parameters (e.g., fees, reward rates, voting thresholds). Requires a minimum stake to propose.
21. **`voteOnGovernanceProposal`**: Staked token holders vote on active governance proposals. Voting power is proportional to their staked tokens and potentially their reputation.
22. **`executeGovernanceProposal`**: (Callable after voting period) Executes a governance proposal that has successfully passed, enacting the proposed changes to the contract's parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This contract leverages a simulated AI Oracle and custom ERC-20/ERC-721
// implementations to avoid external OpenZeppelin dependencies, as per the request.
// In a real-world scenario, robust, audited OpenZeppelin contracts would be used.

// --- Minimal Ownable Implementation ---
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// --- Minimal Pausable Implementation ---
contract Pausable is Ownable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _pause() internal virtual onlyOwner {
        require(!_paused, "Pausable: paused");
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual onlyOwner {
        require(_paused, "Pausable: not paused");
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


// --- Minimal ERC-20 Interface (for AetherMindToken) ---
interface IAetherMindToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// --- Minimal ERC-721 Interface (for WisdomNodeNFT) ---
interface IWisdomNodeNFT {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Custom functions for AetherMindCollective's specific needs
    function _mint(address to, uint256 tokenId, string calldata initialURI) external;
    function _updateTokenURI(uint256 tokenId, string calldata newURI) external;
}


// --- Main AetherMindCollective Contract ---
contract AetherMindCollective is Pausable {
    IAetherMindToken public immutable AETHER_TOKEN;
    IWisdomNodeNFT public immutable WISDOM_NODE_NFT;

    address public aiOracleAddress;

    // Configuration parameters (can be changed via governance)
    uint256 public constant MIN_C_STAKE_FOR_CURATION = 100 ether; // Minimum AETHER to stake for curation rights
    uint256 public constant MIN_G_STAKE_FOR_PROPOSAL = 500 ether; // Minimum AETHER to stake for proposing governance
    uint256 public constant COOLDOWN_PERIOD_UNSTAKE = 7 days; // Cooldown for unstaking curation tokens
    uint256 public constant VOTING_PERIOD_CONTRIBUTION = 3 days; // Duration for contribution voting
    uint256 public constant VOTING_PERIOD_UPGRADE = 2 days; // Duration for upgrade voting
    uint256 public constant VOTING_PERIOD_GOVERNANCE = 5 days; // Duration for governance voting
    uint256 public constant CONTRIBUTION_FEE = 10 ether; // Fee in AETHER to submit a prompt
    uint256 public constant UPGRADE_REQUEST_FEE = 5 ether; // Fee in AETHER to request an NFT upgrade
    uint256 public constant MIN_VALIDATION_VOTES = 5; // Minimum votes for a contribution/upgrade to be considered valid
    uint256 public constant MIN_APPROVAL_PERCENTAGE = 60; // Minimum percentage of 'yes' votes to pass (60%)
    uint256 public constant CURATION_REWARD_POOL_SHARE = 10; // 10% of fees go to curation rewards (per distribution cycle)


    // --- Enums and Structs ---
    enum ContributionStatus { PendingAI, PendingCuration, Validated, Rejected }
    enum NodeUpgradeStatus { None, PendingAI, PendingCuration, Upgraded, Rejected }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Contribution {
        address contributor;
        string prompt;
        string aiOutputURI; // URI to AI generated content (e.g., IPFS)
        uint256 submissionTime;
        ContributionStatus status;
        uint256 upvotes;
        uint256 downvotes;
        uint256 associatedNodeId; // 0 if not yet minted, or the ID of the WisdomNodeNFT
        mapping(address => bool) hasVoted; // Tracks if a curator has voted on this contribution
    }

    struct WisdomNode {
        address owner;
        string metadataURI; // Evolving metadata URI for the NFT
        uint256 lastUpgradeTime;
        NodeUpgradeStatus upgradeStatus; // Tracks if an upgrade is pending or completed
        uint256 upgradeRequestID; // Link to the latest upgrade request, if any
        uint256 upgradeUpvotes; // Votes for the current upgrade request
        uint256 upgradeDownvotes; // Votes against the current upgrade request
        mapping(address => bool) hasVotedUpgrade; // Tracks if a curator has voted on this upgrade
    }

    struct CuratorStake {
        uint256 amount;
        uint256 lastUnstakeRequestTime; // To enforce cooldown for unstaking
        bool isStaking; // True if actively staking for curation
    }

    struct GovernanceProposal {
        address proposer;
        string description;
        bytes callData; // Encoded function call to execute (e.g., set new fee)
        address targetContract; // Contract to call (e.g., this contract)
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks if a staker has voted on this proposal
    }

    // --- State Variables ---
    uint256 private _nextContributionId = 1;
    uint256 private _nextTokenId = 1;
    uint256 private _nextRequestId = 1; // Used for oracle calls
    uint256 private _nextProposalId = 1;

    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => WisdomNode) public wisdomNodes; // wisdomNodes[tokenId]
    mapping(address => uint256) public userReputation; // Simple score for now, could be more complex
    mapping(address => CuratorStake) public curatorStakes;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // --- Events ---
    event PromptSubmitted(uint256 indexed contributionId, address indexed contributor, string prompt);
    event AIGeneratedOutput(uint256 indexed requestId, uint256 indexed contributionId, string aiOutputURI, uint256 indexed nodeId);
    event ContributionVoted(uint256 indexed contributionId, address indexed voter, bool isUpvote);
    event ContributionFinalized(uint256 indexed contributionId, uint256 indexed nodeId, ContributionStatus status);
    event NodeUpgradeRequested(uint256 indexed nodeId, uint256 indexed requestId, address indexed requester);
    event NodeUpgraded(uint256 indexed nodeId, string newMetadataURI);
    event NodeUpgradeVoted(uint256 indexed nodeId, address indexed voter, bool isUpvote);
    event CurationStakeChanged(address indexed user, uint256 newStakeAmount);
    event CurationRewardsDistributed(address indexed curator, uint256 amount);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool supportsProposal);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event TreasuryFundsWithdrawn(address indexed recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == aiOracleAddress, "AetherMindCollective: Caller is not the AI Oracle");
        _;
    }

    modifier onlyCurator() {
        require(curatorStakes[msg.sender].isStaking && curatorStakes[msg.sender].amount >= MIN_C_STAKE_FOR_CURATION, "AetherMindCollective: Caller is not an active curator");
        _;
    }

    modifier onlyStakedGovernanceMember() {
        require(curatorStakes[msg.sender].amount >= MIN_G_STAKE_FOR_PROPOSAL, "AetherMindCollective: Caller does not meet governance stake requirement");
        _;
    }

    // --- Constructor ---
    constructor(address _aetherTokenAddress, address _wisdomNodeNFTAddress) {
        require(_aetherTokenAddress != address(0), "AetherMindCollective: Aether token address cannot be zero");
        require(_wisdomNodeNFTAddress != address(0), "AetherMindCollective: WisdomNode NFT address cannot be zero");
        AETHER_TOKEN = IAetherMindToken(_aetherTokenAddress);
        WISDOM_NODE_NFT = IWisdomNodeNFT(_wisdomNodeNFTAddress);
    }

    // --- I. Core Infrastructure & Access Control ---

    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "AetherMindCollective: Oracle address cannot be zero");
        aiOracleAddress = _newOracleAddress;
    }

    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner whenPaused {
        require(_recipient != address(0), "AetherMindCollective: Recipient cannot be zero address");
        require(AETHER_TOKEN.balanceOf(address(this)) >= _amount, "AetherMindCollective: Insufficient balance in contract treasury");
        AETHER_TOKEN.transfer(_recipient, _amount);
        emit TreasuryFundsWithdrawn(_recipient, _amount);
    }

    // --- II. Contribution & Synthesis ---

    function submitContributionPrompt(string calldata _prompt) external whenNotPaused returns (uint256 contributionId, uint256 requestId) {
        require(bytes(_prompt).length > 0, "AetherMindCollective: Prompt cannot be empty");

        // Collect fee for AI processing
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), CONTRIBUTION_FEE), "AetherMindCollective: Fee payment failed");

        uint256 newContributionId = _nextContributionId++;
        uint256 newRequestId = _nextRequestId++;

        contributions[newContributionId] = Contribution({
            contributor: msg.sender,
            prompt: _prompt,
            aiOutputURI: "",
            submissionTime: block.timestamp,
            status: ContributionStatus.PendingAI,
            upvotes: 0,
            downvotes: 0,
            associatedNodeId: 0
        });

        // Simulate AI oracle request (in real-world, this would call an oracle like Chainlink Functions)
        // The oracle would then call fulfillAIGenerateOutput with the requestId
        emit PromptSubmitted(newContributionId, msg.sender, _prompt);
        // Assuming requestId is returned to user to track their request if needed off-chain
        // For simplicity, we just return it here for demonstration.
        return (newContributionId, newRequestId);
    }

    function fulfillAIGenerateOutput(uint256 _contributionId, string calldata _aiOutputURI) external onlyOracle whenNotPaused {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.status == ContributionStatus.PendingAI, "AetherMindCollective: Contribution not in PendingAI state");
        require(bytes(_aiOutputURI).length > 0, "AetherMindCollective: AI output URI cannot be empty");

        contribution.aiOutputURI = _aiOutputURI;
        contribution.status = ContributionStatus.PendingCuration;

        uint256 newWisdomNodeId = _nextTokenId++;
        contribution.associatedNodeId = newWisdomNodeId;

        // Mint a new WisdomNode NFT
        WISDOM_NODE_NFT._mint(contribution.contributor, newWisdomNodeId, _aiOutputURI);
        wisdomNodes[newWisdomNodeId] = WisdomNode({
            owner: contribution.contributor,
            metadataURI: _aiOutputURI,
            lastUpgradeTime: block.timestamp,
            upgradeStatus: NodeUpgradeStatus.None,
            upgradeRequestID: 0,
            upgradeUpvotes: 0,
            upgradeDownvotes: 0
        });

        emit AIGeneratedOutput(0, _contributionId, _aiOutputURI, newWisdomNodeId); // requestId 0 as it's a callback, not an outgoing request
    }

    function requestWisdomNodeUpgrade(uint256 _nodeId, string calldata _newPromptForAI) external whenNotPaused returns (uint256 requestId) {
        WisdomNode storage node = wisdomNodes[_nodeId];
        require(node.owner == msg.sender, "AetherMindCollective: Not the owner of this WisdomNode");
        require(node.upgradeStatus != NodeUpgradeStatus.PendingAI && node.upgradeStatus != NodeUpgradeStatus.PendingCuration, "AetherMindCollective: An upgrade is already pending for this node");
        require(bytes(_newPromptForAI).length > 0, "AetherMindCollective: Upgrade prompt cannot be empty");

        // Collect fee for AI processing
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), UPGRADE_REQUEST_FEE), "AetherMindCollective: Upgrade fee payment failed");

        uint256 newRequestId = _nextRequestId++;
        node.upgradeRequestID = newRequestId;
        node.upgradeStatus = NodeUpgradeStatus.PendingAI;
        // Reset votes for new upgrade request
        node.upgradeUpvotes = 0;
        node.upgradeDownvotes = 0;
        // Clear previous votes from all curators
        // Note: For simplicity, not iterating through all curators to reset hasVotedUpgrade,
        // but assuming it's reset per new request for an individual node by new request.
        // A more complex system might store a mapping per request ID.

        emit NodeUpgradeRequested(_nodeId, newRequestId, msg.sender);
        return newRequestId;
    }

    function fulfillAINodeUpgrade(uint256 _nodeId, string calldata _newMetadataURI) external onlyOracle whenNotPaused {
        WisdomNode storage node = wisdomNodes[_nodeId];
        require(node.upgradeStatus == NodeUpgradeStatus.PendingAI, "AetherMindCollective: Node upgrade not in PendingAI state");
        require(bytes(_newMetadataURI).length > 0, "AetherMindCollective: New metadata URI cannot be empty");

        node.metadataURI = _newMetadataURI;
        node.upgradeStatus = NodeUpgradeStatus.PendingCuration;
        node.lastUpgradeTime = block.timestamp;
        // Resetting votes for the new curation round for this upgrade
        // (Similar to voteOnContribution, specific tracking per request ID could be added for more robust system)
        delete node.hasVotedUpgrade; // Clear mapping for new vote round

        // Update the NFT's metadata URI through its contract
        WISDOM_NODE_NFT._updateTokenURI(_nodeId, _newMetadataURI);

        emit NodeUpgraded(_nodeId, _newMetadataURI); // Emitted even if pending curation
    }

    // --- III. Curation & Validation ---

    function stakeForCurationRights(uint256 _amount) external whenNotPaused {
        require(_amount >= MIN_C_STAKE_FOR_CURATION, "AetherMindCollective: Minimum stake not met");
        require(AETHER_TOKEN.transferFrom(msg.sender, address(this), _amount), "AetherMindCollective: Token transfer failed");

        curatorStakes[msg.sender].amount += _amount;
        curatorStakes[msg.sender].isStaking = true; // Mark as actively staking

        emit CurationStakeChanged(msg.sender, curatorStakes[msg.sender].amount);
    }

    function unstakeCurationTokens() external whenNotPaused {
        CuratorStake storage stake = curatorStakes[msg.sender];
        require(stake.isStaking, "AetherMindCollective: Not an active curator or no stake");
        require(block.timestamp >= stake.lastUnstakeRequestTime + COOLDOWN_PERIOD_UNSTAKE, "AetherMindCollective: Unstaking is in cooldown period");

        uint256 amountToUnstake = stake.amount;
        stake.amount = 0;
        stake.isStaking = false;
        stake.lastUnstakeRequestTime = block.timestamp; // Update last request time

        require(AETHER_TOKEN.transfer(msg.sender, amountToUnstake), "AetherMindCollective: Token transfer failed during unstake");

        emit CurationStakeChanged(msg.sender, 0);
    }

    function voteOnContribution(uint256 _contributionId, bool _isUpvote) external onlyCurator whenNotPaused {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.status == ContributionStatus.PendingCuration, "AetherMindCollective: Contribution is not in pending curation state");
        require(block.timestamp < contribution.submissionTime + VOTING_PERIOD_CONTRIBUTION, "AetherMindCollective: Voting period has ended");
        require(!contribution.hasVoted[msg.sender], "AetherMindCollective: Already voted on this contribution");

        contribution.hasVoted[msg.sender] = true;
        if (_isUpvote) {
            contribution.upvotes++;
        } else {
            contribution.downvotes++;
        }
        emit ContributionVoted(_contributionId, msg.sender, _isUpvote);
    }

    function voteOnWisdomNodeUpgrade(uint256 _nodeId, bool _isUpvote) external onlyCurator whenNotPaused {
        WisdomNode storage node = wisdomNodes[_nodeId];
        require(node.upgradeStatus == NodeUpgradeStatus.PendingCuration, "AetherMindCollective: Node upgrade is not in pending curation state");
        require(block.timestamp < node.lastUpgradeTime + VOTING_PERIOD_UPGRADE, "AetherMindCollective: Voting period for upgrade has ended");
        require(!node.hasVotedUpgrade[msg.sender], "AetherMindCollective: Already voted on this node upgrade");

        node.hasVotedUpgrade[msg.sender] = true;
        if (_isUpvote) {
            node.upgradeUpvotes++;
        } else {
            node.upgradeDownvotes++;
        }
        emit NodeUpgradeVoted(_nodeId, msg.sender, _isUpvote);
    }

    function finalizeContribution(uint256 _contributionId) external whenNotPaused {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.status == ContributionStatus.PendingCuration, "AetherMindCollective: Contribution not in pending curation state");
        require(block.timestamp >= contribution.submissionTime + VOTING_PERIOD_CONTRIBUTION, "AetherMindCollective: Voting period is still active");

        uint256 totalVotes = contribution.upvotes + contribution.downvotes;
        if (totalVotes >= MIN_VALIDATION_VOTES && (contribution.upvotes * 100) / totalVotes >= MIN_APPROVAL_PERCENTAGE) {
            contribution.status = ContributionStatus.Validated;
            // Reward the contributor for validated content
            userReputation[contribution.contributor]++; // Simple reputation increase
            // Additional rewards for contributor can be implemented here
        } else {
            contribution.status = ContributionStatus.Rejected;
            // Optionally, return fee to contributor for rejected content, or burn it
        }

        emit ContributionFinalized(_contributionId, contribution.associatedNodeId, contribution.status);
    }

    function finalizeWisdomNodeUpgrade(uint256 _nodeId) external whenNotPaused {
        WisdomNode storage node = wisdomNodes[_nodeId];
        require(node.upgradeStatus == NodeUpgradeStatus.PendingCuration, "AetherMindCollective: Node upgrade not in pending curation state");
        require(block.timestamp >= node.lastUpgradeTime + VOTING_PERIOD_UPGRADE, "AetherMindCollective: Voting period is still active");

        uint256 totalVotes = node.upgradeUpvotes + node.upgradeDownvotes;
        if (totalVotes >= MIN_VALIDATION_VOTES && (node.upgradeUpvotes * 100) / totalVotes >= MIN_APPROVAL_PERCENTAGE) {
            node.upgradeStatus = NodeUpgradeStatus.Upgraded;
            userReputation[node.owner]++; // Simple reputation increase for successful upgrade
        } else {
            node.upgradeStatus = NodeUpgradeStatus.Rejected;
            // Revert metadata or keep the old one, depending on desired logic.
            // For now, it simply rejects the *upgrade state* but the metadata may have already been updated by oracle.
            // A more complex system would store the original URI for rollback.
        }
        // Clear votes for next potential upgrade request
        delete node.hasVotedUpgrade;
    }

    function distributeCurationRewards() external onlyOwner whenNotPaused {
        // This is a simplified distribution. In a real system,
        // it would track active curators, their voting accuracy, and distribute from a reward pool.
        // For demonstration, we'll just transfer a portion of the contract's AETHER to a hypothetical reward pool.
        uint256 totalFeesCollected = AETHER_TOKEN.balanceOf(address(this));
        uint256 rewardAmount = (totalFeesCollected * CURATION_REWARD_POOL_SHARE) / 100;

        require(rewardAmount > 0, "AetherMindCollective: No rewards to distribute");

        // In a real system, this would iterate over active curators, weight by reputation/accuracy, and distribute.
        // For this example, we'll simulate transferring to owner for further manual distribution or a separate reward contract.
        require(AETHER_TOKEN.transfer(owner(), rewardAmount), "AetherMindCollective: Reward distribution failed");

        // Clear collected fees from this round from the contract balance (conceptually)
        // (Note: The actual transfer above already reduces the balance)
        emit CurationRewardsDistributed(owner(), rewardAmount); // Signifies rewards are available for distribution
    }


    // --- IV. Reputation & Dynamic NFTs ---

    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    function getWisdomNodeDetails(uint256 _nodeId) external view returns (address owner_, string memory metadataURI_, uint256 lastUpgradeTime_, NodeUpgradeStatus upgradeStatus_) {
        WisdomNode storage node = wisdomNodes[_nodeId];
        require(node.owner != address(0), "AetherMindCollective: WisdomNode does not exist");
        return (node.owner, node.metadataURI, node.lastUpgradeTime, node.upgradeStatus);
    }

    function getPendingContributionDetails(uint256 _contributionId) external view returns (address contributor_, string memory prompt_, string memory aiOutputURI_, uint256 submissionTime_, ContributionStatus status_, uint256 upvotes_, uint256 downvotes_) {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.contributor != address(0), "AetherMindCollective: Contribution does not exist");
        return (contribution.contributor, contribution.prompt, contribution.aiOutputURI, contribution.submissionTime, contribution.status, contribution.upvotes, contribution.downvotes);
    }


    // --- V. Tokenomics & Governance ---

    function getCurrentStakedBalance(address _user) external view returns (uint256) {
        return curatorStakes[_user].amount;
    }

    function proposeGovernanceChange(string calldata _description, address _targetContract, bytes calldata _callData) external onlyStakedGovernanceMember whenNotPaused returns (uint256 proposalId) {
        require(bytes(_description).length > 0, "AetherMindCollective: Description cannot be empty");
        require(_targetContract != address(0), "AetherMindCollective: Target contract cannot be zero");
        require(bytes(_callData).length > 0, "AetherMindCollective: Calldata cannot be empty");

        uint256 newProposalId = _nextProposalId++;
        governanceProposals[newProposalId] = GovernanceProposal({
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            targetContract: _targetContract,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + VOTING_PERIOD_GOVERNANCE,
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Active
        });

        emit GovernanceProposalCreated(newProposalId, msg.sender);
        return newProposalId;
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _supportsProposal) external onlyStakedGovernanceMember whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "AetherMindCollective: Proposal is not active");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp < proposal.voteEndTime, "AetherMindCollective: Voting period has ended or not started");
        require(!proposal.hasVoted[msg.sender], "AetherMindCollective: Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_supportsProposal) {
            proposal.yesVotes += curatorStakes[msg.sender].amount;
        } else {
            proposal.noVotes += curatorStakes[msg.sender].amount;
        }

        emit GovernanceVoteCast(_proposalId, msg.sender, _supportsProposal);
    }

    function executeGovernanceProposal(uint256 _proposalId) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "AetherMindCollective: Proposal is not active");
        require(block.timestamp >= proposal.voteEndTime, "AetherMindCollective: Voting period not ended");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        if (totalVotes == 0 || (proposal.yesVotes * 100) / totalVotes < MIN_APPROVAL_PERCENTAGE) {
            proposal.state = ProposalState.Failed;
        } else {
            proposal.state = ProposalState.Succeeded;
        }

        require(proposal.state == ProposalState.Succeeded, "AetherMindCollective: Proposal did not pass");
        require(proposal.targetContract != address(0), "AetherMindCollective: Invalid target contract");

        // Execute the proposal
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "AetherMindCollective: Proposal execution failed");

        proposal.state = ProposalState.Executed;
        emit GovernanceProposalExecuted(_proposalId);
    }
}
```