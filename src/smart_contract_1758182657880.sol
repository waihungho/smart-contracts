This smart contract, **AegisProtocol**, is designed as a sophisticated Decentralized Autonomous Organization (DAO) that integrates adaptive governance, a gamified reputation system, and a simulated AI-enhanced treasury management component. It aims to showcase advanced smart contract design by combining several trending Web3 concepts into a cohesive protocol.

**Key Concepts Integrated:**

*   **Adaptive DAO Governance:** Features weighted voting based on staked tokens, reputation score, and unique NFT boosts. Includes standard proposal lifecycle (propose, vote, queue, execute) with a timelock.
*   **Gamified Reputation System:** Users earn reputation for active participation (voting, proposing, executing). Reputation decays over time, encouraging continuous engagement. Users can stake reputation for temporary voting boosts and claim unique NFT badges upon reaching specific reputation tiers.
*   **AI-Enhanced Treasury (Simulated):** A designated "AI Oracle" (a trusted external entity) can suggest treasury asset allocation strategies. The DAO then votes on these strategies, and if approved, the contract simulates their execution for rebalancing and yield farming. This demonstrates a common pattern for integrating off-chain intelligence into on-chain governance.
*   **NFT Utility:** Beyond reputation badges, special Governance NFTs can be minted to core contributors, providing additional, customizable voting power boosts.

---

## AegisProtocol: Adaptive Governance & Treasury Intelligence Smart Contract

**Outline and Function Summary:**

**--- CORE DAO GOVERNANCE (8 Functions) ---**
1.  **`propose(address[] targets, bytes[] calldatas, string description)`**: Allows a user meeting a minimum threshold to submit a new governance proposal for a vote. Proposals can include arbitrary contract calls.
2.  **`vote(uint256 proposalId, bool support)`**: Enables a user to cast a vote (for or against) on an active proposal. Voting power is dynamically calculated based on token stake, reputation, and NFT boosts.
3.  **`delegate(address delegatee)`**: Allows a user to delegate their combined voting power (stake + reputation + NFT boost) to another address.
4.  **`queueProposal(uint256 proposalId)`**: Moves a successfully voted proposal into a timelock queue, ensuring a delay before execution for transparency and safety.
5.  **`executeProposal(uint256 proposalId)`**: Executes a proposal from the queue after its timelock expires, performing the specified arbitrary contract calls.
6.  **`cancelProposal(uint256 proposalId)`**: Allows the proposal creator (before voting starts) or the DAO (via another proposal) to cancel a pending or queued proposal under specific conditions.
7.  **`updateVotingPeriod(uint256 _newPeriod)`**: DAO-governed function to adjust the duration proposals remain open for voting. (Placeholder `onlyOwner` for DAO execution)
8.  **`updateQuorumThreshold(uint256 _newThreshold)`**: DAO-governed function to modify the minimum voting power percentage required for a proposal to pass. (Placeholder `onlyOwner` for DAO execution)

**--- REPUTATION SYSTEM (6 Functions) ---**
9.  **`awardReputation(address user, uint256 amount)`**: Internally or DAO-governed function to grant reputation points to a user for positive engagement (e.g., active voting, successful proposals/executions).
10. **`decayReputation(address user)`**: Explicitly triggers the decay mechanism for a user's reputation, promoting continuous participation.
11. **`getReputation(address user)`**: Retrieves the current reputation score for a given user, accounting for simulated decay without altering state.
12. **`claimReputationBadge(uint256 tierId)`**: Allows users to mint a unique NFT badge (from `reputationBadgeNFT`) when they reach specific, predefined reputation tiers.
13. **`stakeReputationForBoost(uint256 amount)`**: Enables users to temporarily stake their reputation to receive a significant voting power boost for a more impactful governance presence.
14. **`unstakeReputationBoost(uint256 amount)`**: Allows users to reclaim their previously staked reputation, removing the associated voting boost.

**--- TREASURY MANAGEMENT & AI INTEGRATION (SIMULATED) (7 Functions) ---**
15. **`depositToTreasury(address token, uint256 amount)`**: Allows external parties to deposit various ERC20 tokens into the protocol's treasury.
16. **`getTreasuryBalance(address token)`**: Retrieves the balance of a specific ERC20 token held in the protocol's treasury.
17. **`submitAIStrategySuggestion(address[] assets, uint256[] percentages, string description)`**: An "AI Oracle" (a designated trusted address) proposes a treasury asset allocation strategy, including target percentages for various tokens.
18. **`voteOnAIStrategy(uint256 strategyId, bool support)`**: DAO members vote on whether to adopt a submitted AI-suggested treasury strategy, using their weighted voting power.
19. **`executeTreasuryRebalance(uint256 strategyId)`**: Executes a passed AI-suggested strategy, simulating asset reallocations within the treasury. (Placeholder `onlyOwner` for DAO execution)
20. **`allocateFundsForYield(address token, uint256 amount, address yieldProtocol)`**: Simulates sending treasury funds to an external yield-generating protocol. (Placeholder `onlyOwner` for DAO execution)
21. **`reclaimYield(address token, uint256 amount)`**: Simulates retrieving funds (including generated yield) from a yield protocol back to the treasury. (Placeholder `onlyOwner` for DAO execution)

**--- NFT UTILITY & MISC (4 Functions) ---**
22. **`mintGovernanceNFT(address to, uint256 boostAmount)`**: Mints a special non-transferable NFT (`governanceNFT`) for core contributors or specific roles, granting unique, fixed voting power boosts. (Placeholder `onlyOwner` for DAO execution)
23. **`getNFTVotingBoost(uint256 tokenId)`**: Calculates the additional voting power conferred by a specific Governance NFT.
24. **`setReputationTier(uint256 tierId, uint256 threshold)`**: DAO-governed function to define or update the reputation score thresholds required for claiming various reputation NFT badges. (Placeholder `onlyOwner` for DAO execution)
25. **`emergencyShutdown(bool _paused)`**: A high-privilege function, callable only by the contract owner, to pause critical protocol operations in an emergency.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

// --- Custom Interfaces for Protocol Tokens ---
// Assuming a Governance Token exists and supports minting/burning for protocol control.
interface IGovernanceToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

// Assuming a Reputation Badge NFT exists and allows minting/burning by this protocol.
interface IReputationBadgeNFT is IERC721Metadata {
    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external; // Optional: if badges can be burned
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256); // For iterating owned NFTs
}

// --- Outline and Function Summary ---
// This contract, AegisProtocol, is a sophisticated decentralized autonomous organization (DAO)
// designed with adaptive governance, a gamified reputation system, and a simulated
// AI-enhanced treasury management component. It aims to showcase advanced
// smart contract design principles by combining multiple trending Web3 concepts.

// --- CORE DAO GOVERNANCE ---
// 1.  propose: Allows a user to submit a new governance proposal for a vote.
// 2.  vote: Enables a user to cast a vote (for or against) on an active proposal, with weighted power.
// 3.  delegate: Allows a user to delegate their voting power (stake + reputation) to another address.
// 4.  queueProposal: Moves a successfully voted proposal into a timelock queue before execution.
// 5.  executeProposal: Executes a proposal from the queue after its timelock expires.
// 6.  cancelProposal: Allows the proposal creator or DAO to cancel a pending proposal under specific conditions.
// 7.  updateVotingPeriod: DAO-governed function to adjust the duration proposals remain open for voting.
// 8.  updateQuorumThreshold: DAO-governed function to modify the minimum voting power required for a proposal to pass.

// --- REPUTATION SYSTEM ---
// 9.  awardReputation: Internally/DAO-governed function to grant reputation points to a user for positive engagement.
// 10. decayReputation: A mechanism to simulate the gradual decay of reputation over time, encouraging continuous participation.
// 11. getReputation: Retrieves the current reputation score for a given user, accounting for decay.
// 12. claimReputationBadge: Allows users to mint an NFT badge when they reach specific reputation tiers.
// 13. stakeReputationForBoost: Enables users to temporarily stake reputation to receive a voting power boost.
// 14. unstakeReputationBoost: Allows users to reclaim their staked reputation.

// --- TREASURY MANAGEMENT & AI INTEGRATION (SIMULATED) ---
// 15. depositToTreasury: Allows funds to be deposited into the protocol's treasury.
// 16. getTreasuryBalance: Retrieves the balance of a specific token held in the treasury.
// 17. submitAIStrategySuggestion: An "AI Oracle" (trusted external actor) proposes a treasury allocation strategy.
// 18. voteOnAIStrategy: DAO members vote on whether to adopt a submitted AI-suggested treasury strategy.
// 19. executeTreasuryRebalance: Executes a passed AI-suggested strategy, simulating asset reallocations.
// 20. allocateFundsForYield: Simulates sending treasury funds to an external yield-generating protocol.
// 21. reclaimYield: Simulates retrieving funds (including generated yield) from a yield protocol.

// --- NFT UTILITY & MISC ---
// 22. mintGovernanceNFT: Mints a special non-transferable NFT for core contributors, potentially granting unique benefits.
// 23. getNFTVotingBoost: Calculates the additional voting power conferred by a specific Governance NFT.
// 24. setReputationTier: DAO-governed function to define or update the reputation thresholds for badge claiming.
// 25. emergencyShutdown: A high-privilege function to pause critical protocol operations in an emergency (Ownable).

contract AegisProtocol is Ownable {
    using SafeMath for uint256; // Explicit SafeMath for clarity, though 0.8.x provides default checks
    using Address for address; // For `functionCall`

    // --- State Variables ---

    // Governance Token and NFT Addresses (Assumed to be deployed separately)
    IGovernanceToken public governanceToken;
    IReputationBadgeNFT public reputationBadgeNFT;
    IReputationBadgeNFT public governanceNFT; // A separate NFT for core contributors, using the same interface

    // DAO Configuration
    uint256 public constant MIN_PROPOSAL_THRESHOLD = 100e18; // Min tokens required to propose (e.g., 100 tokens with 18 decimals)
    uint256 public constant MIN_VOTING_DELAY_BLOCKS = 300; // ~1 hour @ 12s/block delay before voting starts
    uint256 public constant PROPOSAL_EXECUTION_TIMELOCK = 2 days; // Timelock for passed proposals before execution
    uint256 public votingPeriodBlocks = 7200; // ~1 day @ 12s/block. Default voting period in blocks.
    uint256 public quorumThresholdPercent = 4; // 4% of total voting power needed for quorum

    // Reputation System
    uint256 public constant REPUTATION_DECAY_RATE_PER_DAY = 1; // 1 point per day
    uint256 public constant REPUTATION_DECAY_WINDOW = 30 days; // How often decay is applied when activity occurs
    uint256 public constant REPUTATION_BOOST_FACTOR = 2; // Multiplier for reputation staked for boost

    mapping(address => uint256) public reputationScores; // Current reputation points for each user
    mapping(address => uint256) public lastReputationUpdate; // Timestamp of last reputation update for decay calculation
    mapping(address => uint256) public stakedReputationBoost; // Reputation temporarily staked for a boost

    // Reputation Tiers for NFT Badges: tierId => reputationThreshold
    mapping(uint256 => uint256) public reputationTiers; // e.g., reputationTiers[1] = 100;
    uint256 public nextReputationBadgeId = 1; // Counter for new badge token IDs (unique per claim)

    // Governance NFT boost (tokenId => votingBoostAmount)
    mapping(uint256 => uint256) public governanceNFTBoosts;
    uint256 public nextGovernanceNFTId = 1000; // Starting ID for Governance NFTs

    // Proposal Management
    struct Proposal {
        uint256 id;
        address proposer;
        address[] targets;
        bytes[] calldatas;
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        uint256 queuedAt; // Timestamp when proposal was queued for execution
        mapping(address => bool) hasVoted; // Check if an address has voted on this proposal
        mapping(address => uint256) votesCast; // Stores the actual voting power used by each voter
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;

    // Delegation: user => delegatee
    mapping(address => address) public delegates;

    // Treasury Management & AI Strategy
    struct AIStrategy {
        uint256 id;
        address proposer; // The "AI Oracle" or trusted party
        address[] assets; // Tokens to allocate
        uint256[] percentages; // Percentage allocation (sum to 100)
        string description;
        uint256 submittedAt;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted; // Check if an address has voted on this strategy
    }
    uint256 public nextAIStrategyId = 1;
    mapping(uint256 => AIStrategy) public aiStrategies;
    address public aiOracleAddress; // The address authorized to submit AI strategies

    // Emergency State
    bool public paused = false;

    // --- Events ---
    event ProposalCreated(uint256 id, address proposer, address[] targets, string description, uint256 startBlock, uint256 endBlock);
    event VoteCast(uint256 proposalId, address voter, bool support, uint256 votes);
    event DelegateChanged(address delegator, address fromDelegate, address toDelegate);
    event DelegateVotesChanged(address delegatee, uint256 previousBalance, uint256 newBalance);
    event ProposalQueued(uint256 id, uint256 queuedAt);
    event ProposalExecuted(uint256 id);
    event ProposalCanceled(uint256 id);
    event ReputationAwarded(address indexed user, uint256 amount, uint256 newScore);
    event ReputationDecayed(address indexed user, uint256 amount, uint256 newScore);
    event ReputationBadgeClaimed(address indexed user, uint256 badgeId, uint256 tierId);
    event ReputationStakedForBoost(address indexed user, uint256 amount, uint256 currentBoost);
    event ReputationUnstakedBoost(address indexed user, uint256 amount, uint256 currentBoost);
    event AIStrategySuggested(uint256 id, address proposer, string description);
    event AIStrategyVoted(uint256 strategyId, address voter, bool support, uint256 votes);
    event AIStrategyExecuted(uint256 strategyId);
    event TreasuryDeposit(address indexed token, uint256 amount);
    event FundsAllocatedForYield(address indexed token, uint256 amount, address indexed yieldProtocol);
    event YieldReclaimed(address indexed token, uint256 amount);
    event GovernanceNFTMinted(address indexed to, uint256 tokenId, uint256 boostAmount);
    event ProtocolPaused(bool status);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "AegisProtocol: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "AegisProtocol: not paused");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "AegisProtocol: Only AI Oracle can call this function");
        _;
    }

    // --- Constructor ---
    constructor(
        address _governanceToken,
        address _reputationBadgeNFT,
        address _governanceNFT,
        address _aiOracleAddress
    ) Ownable(msg.sender) {
        require(_governanceToken != address(0), "AegisProtocol: invalid governance token address");
        require(_reputationBadgeNFT != address(0), "AegisProtocol: invalid reputation badge NFT address");
        require(_governanceNFT != address(0), "AegisProtocol: invalid governance NFT address");
        require(_aiOracleAddress != address(0), "AegisProtocol: invalid AI Oracle address");

        governanceToken = IGovernanceToken(_governanceToken);
        reputationBadgeNFT = IReputationBadgeNFT(_reputationBadgeNFT);
        governanceNFT = IReputationBadgeNFT(_governanceNFT); // Using same interface as Badge NFT
        aiOracleAddress = _aiOracleAddress;

        // Set initial reputation tiers
        reputationTiers[1] = 100; // Tier 1 badge for 100 reputation
        reputationTiers[2] = 500; // Tier 2 badge for 500 reputation
        reputationTiers[3] = 1000; // Tier 3 badge for 1000 reputation
    }

    // --- INTERNAL HELPER FUNCTIONS ---

    /// @dev Calculates the total voting power for a given address, including stake, reputation, and NFT boosts.
    /// @param _voter The address whose voting power to calculate.
    /// @return The total voting power.
    function _getVotingPower(address _voter) internal view returns (uint256) {
        address currentDelegatee = delegates[_voter] == address(0) ? _voter : delegates[_voter];
        
        // Stake-based voting power (current balance of governance token)
        uint256 stakePower = governanceToken.balanceOf(currentDelegatee);

        // Reputation-based voting power (simulated decay applied conceptually)
        uint256 repPower = getReputation(currentDelegatee); // Uses the view function to get decayed score
        
        // Staked Reputation Boost
        repPower = repPower.add(stakedReputationBoost[currentDelegatee].mul(REPUTATION_BOOST_FACTOR));

        // Governance NFT boost: Sum boosts from all Governance NFTs owned by the delegatee
        uint256 nftBoost = 0;
        uint256 numGovernanceNFTs = governanceNFT.balanceOf(currentDelegatee);
        for (uint256 i = 0; i < numGovernanceNFTs; i++) {
            uint256 tokenId = governanceNFT.tokenOfOwnerByIndex(currentDelegatee, i);
            nftBoost = nftBoost.add(governanceNFTBoosts[tokenId]);
        }

        return stakePower.add(repPower).add(nftBoost);
    }

    /// @dev Applies reputation decay to a user's score based on time passed since last update.
    /// This function modifies state and is called by other state-modifying functions.
    /// @param _user The address whose reputation to decay.
    function _updateReputationDecay(address _user) internal {
        uint256 lastUpdate = lastReputationUpdate[_user];
        if (lastUpdate == 0 || reputationScores[_user] == 0) { // No previous update or no reputation to decay
            lastReputationUpdate[_user] = block.timestamp;
            return;
        }

        uint256 currentTime = block.timestamp;
        if (currentTime > lastUpdate && (currentTime - lastUpdate) >= REPUTATION_DECAY_WINDOW) {
            uint256 daysPassed = (currentTime - lastUpdate) / 1 days;
            uint256 decayAmount = daysPassed.mul(REPUTATION_DECAY_RATE_PER_DAY);
            
            if (reputationScores[_user] > decayAmount) {
                reputationScores[_user] = reputationScores[_user].sub(decayAmount);
                emit ReputationDecayed(_user, decayAmount, reputationScores[_user]);
            } else {
                decayAmount = reputationScores[_user]; // Decay by current score if it's less than calculated decay
                reputationScores[_user] = 0;
                emit ReputationDecayed(_user, decayAmount, 0);
            }
            lastReputationUpdate[_user] = currentTime;
        }
    }

    /// @dev Returns the total supply of the governance token as a proxy for total active voting power.
    /// In a more complex system, this would involve summing active delegates' powers.
    /// @return The total active voting power.
    function _getTotalActiveVotingPower() internal view returns (uint256) {
        return governanceToken.totalSupply();
    }

    // --- CORE DAO GOVERNANCE ---

    /// @notice Allows a user to submit a new governance proposal for a vote.
    /// @param targets Addresses of contracts to call during execution.
    /// @param calldatas Calldata for each target contract.
    /// @param description Description of the proposal.
    /// @return The ID of the created proposal.
    function propose(address[] calldata targets, bytes[] calldata calldatas, string calldata description)
        external
        whenNotPaused
        returns (uint256)
    {
        require(targets.length == calldatas.length, "AegisProtocol: target and calldata length mismatch");
        require(targets.length > 0, "AegisProtocol: must provide at least one target");
        require(bytes(description).length > 0, "AegisProtocol: description cannot be empty");
        
        _updateReputationDecay(msg.sender); // Ensure proposer's reputation is current
        require(_getVotingPower(msg.sender) >= MIN_PROPOSAL_THRESHOLD, "AegisProtocol: proposer does not meet minimum threshold");

        uint256 proposalId = nextProposalId++;
        uint256 startBlock = block.number.add(MIN_VOTING_DELAY_BLOCKS);
        uint256 endBlock = startBlock.add(votingPeriodBlocks);

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.targets = targets;
        newProposal.calldatas = calldatas;
        newProposal.description = description;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;

        emit ProposalCreated(proposalId, msg.sender, targets, description, startBlock, endBlock);
        return proposalId;
    }

    /// @notice Enables a user to cast a vote (for or against) on an active proposal, with weighted power.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'for' vote, false for 'against' vote.
    function vote(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "AegisProtocol: proposal does not exist");
        require(block.number >= proposal.startBlock, "AegisProtocol: voting not started yet");
        require(block.number <= proposal.endBlock, "AegisProtocol: voting period ended");
        require(!proposal.hasVoted[msg.sender], "AegisProtocol: already voted");
        require(!proposal.executed, "AegisProtocol: proposal already executed");
        require(!proposal.canceled, "AegisProtocol: proposal canceled");

        _updateReputationDecay(msg.sender); // Apply decay before getting voting power
        uint256 voterPower = _getVotingPower(msg.sender);
        require(voterPower > 0, "AegisProtocol: voter has no power");

        proposal.hasVoted[msg.sender] = true;
        proposal.votesCast[msg.sender] = voterPower;

        if (support) {
            proposal.forVotes = proposal.forVotes.add(voterPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voterPower);
        }

        awardReputation(msg.sender, 5); // Example: 5 reputation points for voting

        emit VoteCast(proposalId, msg.sender, support, voterPower);
    }

    /// @notice Allows a user to delegate their voting power (stake + reputation) to another address.
    /// @param delegatee The address to delegate voting power to.
    function delegate(address delegatee) external whenNotPaused {
        require(delegatee != address(0), "AegisProtocol: delegatee cannot be zero address");
        require(delegatee != msg.sender, "AegisProtocol: cannot delegate to self");

        address currentDelegate = delegates[msg.sender];
        require(currentDelegate != delegatee, "AegisProtocol: already delegated to this address");

        // Recalculate votes for old and new delegatees (conceptual update)
        // In a real system, a more complex vote tracking system would be needed for historical votes.
        // For active/future votes, _getVotingPower handles it.
        uint256 previousDelegateePower = _getVotingPower(currentDelegate);
        uint256 newDelegateeInitialPower = _getVotingPower(delegatee);

        delegates[msg.sender] = delegatee;

        emit DelegateChanged(msg.sender, currentDelegate, delegatee);
        emit DelegateVotesChanged(currentDelegate, previousDelegateePower, _getVotingPower(currentDelegate));
        emit DelegateVotesChanged(delegatee, newDelegateeInitialPower, _getVotingPower(delegatee));
    }

    /// @notice Moves a successfully voted proposal into a timelock queue before execution.
    /// @param proposalId The ID of the proposal to queue.
    function queueProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "AegisProtocol: proposal does not exist");
        require(block.number > proposal.endBlock, "AegisProtocol: voting period not ended");
        require(proposal.forVotes > proposal.againstVotes, "AegisProtocol: proposal did not pass");

        uint256 totalVotingPower = _getTotalActiveVotingPower();
        uint256 requiredQuorum = totalVotingPower.mul(quorumThresholdPercent).div(100);
        require(proposal.forVotes >= requiredQuorum, "AegisProtocol: quorum not met");

        require(proposal.queuedAt == 0, "AegisProtocol: proposal already queued");
        require(!proposal.executed, "AegisProtocol: proposal already executed");
        require(!proposal.canceled, "AegisProtocol: proposal canceled");

        proposal.queuedAt = block.timestamp;
        emit ProposalQueued(proposalId, proposal.queuedAt);
    }

    /// @notice Executes a proposal from the queue after its timelock expires.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external payable whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "AegisProtocol: proposal does not exist");
        require(proposal.queuedAt > 0, "AegisProtocol: proposal not queued");
        require(block.timestamp >= proposal.queuedAt.add(PROPOSAL_EXECUTION_TIMELOCK), "AegisProtocol: timelock not expired");
        require(!proposal.executed, "AegisProtocol: proposal already executed");
        require(!proposal.canceled, "AegisProtocol: proposal canceled");

        proposal.executed = true;

        for (uint i = 0; i < proposal.targets.length; i++) {
            address target = proposal.targets[i];
            bytes memory calldata = proposal.calldatas[i];

            // Use Address.functionCall for safe external calls
            (bool success, bytes memory result) = target.functionCall(calldata, msg.value); // msg.value might be needed for some calls
            require(success, string(abi.encodePacked("AegisProtocol: execution failed for target ", Address.toString(target), " with result: ", string(result))));
        }

        awardReputation(proposal.proposer, 50); // Award reputation to proposer for successful execution

        emit ProposalExecuted(proposalId);
    }

    /// @notice Allows the proposal creator or DAO to cancel a pending proposal under specific conditions.
    /// @param proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "AegisProtocol: proposal does not exist");
        require(!proposal.executed, "AegisProtocol: proposal already executed");
        require(!proposal.canceled, "AegisProtocol: proposal already canceled");

        // Conditions to cancel:
        // 1. Proposer can cancel if voting hasn't started (`block.number < proposal.startBlock`).
        // 2. A DAO-approved cancellation: This function can be called by `executeProposal` if a DAO vote passes.
        //    For this example, a simple `msg.sender == owner()` is used as a placeholder for a trusted DAO agent.
        require(
            (msg.sender == proposal.proposer && block.number < proposal.startBlock) || 
            (msg.sender == owner()) // Placeholder for DAO-approved cancellation
            , "AegisProtocol: unauthorized to cancel proposal"
        );

        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    /// @notice DAO-governed function to adjust the duration proposals remain open for voting (in blocks).
    /// This function should be called via `executeProposal`. `onlyOwner` is used as a placeholder.
    /// @param _newPeriodBlocks The new voting period in blocks.
    function updateVotingPeriod(uint256 _newPeriodBlocks) external onlyOwner whenNotPaused {
        require(_newPeriodBlocks > 0, "AegisProtocol: new voting period must be positive");
        votingPeriodBlocks = _newPeriodBlocks;
    }

    /// @notice DAO-governed function to modify the minimum voting power required for a proposal to pass.
    /// This function should be called via `executeProposal`. `onlyOwner` is used as a placeholder.
    /// @param _newThreshold The new quorum threshold as a percentage (e.g., 5 for 5%).
    function updateQuorumThreshold(uint256 _newThreshold) external onlyOwner whenNotPaused {
        require(_newThreshold > 0 && _newThreshold <= 100, "AegisProtocol: new quorum must be between 1 and 100");
        quorumThresholdPercent = _newThreshold;
    }

    // --- REPUTATION SYSTEM ---

    /// @notice Internally/DAO-governed function to grant reputation points to a user for positive engagement.
    /// This function would typically be called internally (e.g., after successful vote, proposal, execution)
    /// or explicitly via a DAO-executed proposal.
    /// @param user The address to award reputation to.
    /// @param amount The amount of reputation points to award.
    function awardReputation(address user, uint256 amount) public { // Public for external DAO calls, or internal for automated triggers
        // In a production system, this would be restricted to internal calls or a specific role (e.g., MINTER_ROLE)
        // require(msg.sender == address(this) || hasRole(MINTER_ROLE, msg.sender), "AegisProtocol: unauthorized to award reputation");
        
        _updateReputationDecay(user); // Apply decay before adding new reputation
        reputationScores[user] = reputationScores[user].add(amount);
        lastReputationUpdate[user] = block.timestamp; // Update timestamp after activity
        emit ReputationAwarded(user, amount, reputationScores[user]);
    }

    /// @notice Explicitly triggers the reputation decay mechanism for a user.
    /// Can be called by anyone to update a user's on-chain reputation score.
    /// @param user The address whose reputation to decay.
    function decayReputation(address user) external {
        _updateReputationDecay(user);
    }

    /// @notice Retrieves the current reputation score for a given user, accounting for simulated decay.
    /// This is a view function and does not modify state.
    /// @param user The address to query.
    /// @return The current reputation score.
    function getReputation(address user) public view returns (uint256) {
        uint256 currentRep = reputationScores[user];
        uint256 lastUpdate = lastReputationUpdate[user];

        if (lastUpdate == 0 || currentRep == 0) {
            return currentRep; // No reputation or no update recorded
        }

        uint256 currentTime = block.timestamp;
        if (currentTime > lastUpdate && (currentTime - lastUpdate) >= REPUTATION_DECAY_WINDOW) {
            uint256 daysPassed = (currentTime - lastUpdate) / 1 days;
            uint256 decayAmount = daysPassed.mul(REPUTATION_DECAY_RATE_PER_DAY);
            
            if (currentRep > decayAmount) {
                return currentRep.sub(decayAmount);
            } else {
                return 0; // Reputation fully decayed
            }
        }
        return currentRep; // No decay needed yet or already handled
    }

    /// @notice Allows users to mint an NFT badge from `reputationBadgeNFT` when they reach specific reputation tiers.
    /// Each claim for a tier will mint a new unique NFT.
    /// @param tierId The ID of the reputation tier for which to claim the badge.
    function claimReputationBadge(uint256 tierId) external whenNotPaused {
        require(reputationTiers[tierId] > 0, "AegisProtocol: invalid reputation tier");
        _updateReputationDecay(msg.sender); // Ensure reputation is current before check
        require(reputationScores[msg.sender] >= reputationTiers[tierId], "AegisProtocol: not enough reputation for this tier");

        uint256 badgeId = nextReputationBadgeId;
        nextReputationBadgeId++; // Increment for next badge claim

        reputationBadgeNFT.mint(msg.sender, badgeId);
        emit ReputationBadgeClaimed(msg.sender, badgeId, tierId);
    }

    /// @notice Enables users to temporarily stake reputation to receive a voting power boost.
    /// Staked reputation is removed from the active `reputationScores` and added to `stakedReputationBoost`.
    /// @param amount The amount of reputation to stake.
    function stakeReputationForBoost(uint256 amount) external whenNotPaused {
        _updateReputationDecay(msg.sender); // Ensure reputation is current
        require(amount > 0, "AegisProtocol: amount must be positive");
        require(reputationScores[msg.sender] >= amount, "AegisProtocol: not enough active reputation to stake");

        reputationScores[msg.sender] = reputationScores[msg.sender].sub(amount);
        stakedReputationBoost[msg.sender] = stakedReputationBoost[msg.sender].add(amount);

        emit ReputationStakedForBoost(msg.sender, amount, stakedReputationBoost[msg.sender]);
    }

    /// @notice Allows users to reclaim their staked reputation, which then reverts back to their active `reputationScores`.
    /// @param amount The amount of staked reputation to unstake.
    function unstakeReputationBoost(uint256 amount) external whenNotPaused {
        require(amount > 0, "AegisProtocol: amount must be positive");
        require(stakedReputationBoost[msg.sender] >= amount, "AegisProtocol: not enough staked reputation to unstake");

        stakedReputationBoost[msg.sender] = stakedReputationBoost[msg.sender].sub(amount);
        reputationScores[msg.sender] = reputationScores[msg.sender].add(amount);
        lastReputationUpdate[msg.sender] = block.timestamp; // Update timestamp as reputation changed

        emit ReputationUnstakedBoost(msg.sender, amount, stakedReputationBoost[msg.sender]);
    }

    // --- TREASURY MANAGEMENT & AI INTEGRATION (SIMULATED) ---

    /// @notice Allows funds to be deposited into the protocol's treasury.
    /// Requires `msg.sender` to have approved `AegisProtocol` for the `amount` of `token`.
    /// @param token The address of the ERC20 token to deposit.
    /// @param amount The amount of tokens to deposit.
    function depositToTreasury(address token, uint256 amount) external whenNotPaused {
        require(token != address(0), "AegisProtocol: invalid token address");
        require(amount > 0, "AegisProtocol: amount must be positive");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit TreasuryDeposit(token, amount);
    }

    /// @notice Retrieves the balance of a specific token held in the treasury.
    /// @param token The address of the token to query.
    /// @return The balance of the token in the treasury.
    function getTreasuryBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice An "AI Oracle" (trusted external actor) proposes a treasury allocation strategy.
    /// DAO members then vote on whether to adopt it.
    /// @param assets An array of ERC20 token addresses for the new allocation.
    /// @param percentages An array of percentages corresponding to each asset, summing to 100.
    /// @param description Description of the proposed strategy.
    /// @return The ID of the newly created AI strategy.
    function submitAIStrategySuggestion(address[] calldata assets, uint256[] calldata percentages, string calldata description)
        external
        onlyAIOracle
        whenNotPaused
        returns (uint256)
    {
        require(assets.length == percentages.length, "AegisProtocol: assets and percentages length mismatch");
        require(assets.length > 0, "AegisProtocol: must provide at least one asset");
        uint256 totalPercentage;
        for (uint i = 0; i < percentages.length; i++) {
            totalPercentage = totalPercentage.add(percentages[i]);
        }
        require(totalPercentage == 100, "AegisProtocol: percentages must sum to 100");

        uint256 strategyId = nextAIStrategyId++;
        AIStrategy storage newStrategy = aiStrategies[strategyId];
        newStrategy.id = strategyId;
        newStrategy.proposer = msg.sender;
        newStrategy.assets = assets;
        newStrategy.percentages = percentages;
        newStrategy.description = description;
        newStrategy.submittedAt = block.timestamp;

        // An AI strategy is open for vote immediately and persists until executed or superseded.
        emit AIStrategySuggested(strategyId, msg.sender, description);
        return strategyId;
    }

    /// @notice DAO members vote on whether to adopt a submitted AI-suggested treasury strategy.
    /// @param strategyId The ID of the AI strategy to vote on.
    /// @param support True for 'for' vote, false for 'against' vote.
    function voteOnAIStrategy(uint256 strategyId, bool support) external whenNotPaused {
        AIStrategy storage strategy = aiStrategies[strategyId];
        require(strategy.id != 0, "AegisProtocol: AI strategy does not exist");
        require(!strategy.executed, "AegisProtocol: AI strategy already executed");
        require(!strategy.hasVoted[msg.sender], "AegisProtocol: already voted on this AI strategy");

        _updateReputationDecay(msg.sender); // Update voter's reputation before getting power
        uint256 voterPower = _getVotingPower(msg.sender);
        require(voterPower > 0, "AegisProtocol: voter has no power");

        strategy.hasVoted[msg.sender] = true;

        if (support) {
            strategy.forVotes = strategy.forVotes.add(voterPower);
        } else {
            strategy.againstVotes = strategy.againstVotes.add(voterPower);
        }

        awardReputation(msg.sender, 3); // Award reputation for voting on AI strategy

        emit AIStrategyVoted(strategyId, msg.sender, support, voterPower);
    }

    /// @notice Executes a passed AI-suggested strategy, simulating asset reallocations within the treasury.
    /// This function should be called via `executeProposal`. `onlyOwner` is used as a placeholder for DAO execution.
    /// This is a simplified simulation and does not involve real AMM swaps or oracle price feeds.
    /// @param strategyId The ID of the AI strategy to execute.
    function executeTreasuryRebalance(uint256 strategyId) external onlyOwner whenNotPaused {
        AIStrategy storage strategy = aiStrategies[strategyId];
        require(strategy.id != 0, "AegisProtocol: AI strategy does not exist");
        require(!strategy.executed, "AegisProtocol: AI strategy already executed");

        uint256 totalVotingPower = _getTotalActiveVotingPower();
        uint256 requiredQuorum = totalVotingPower.mul(quorumThresholdPercent).div(100);
        require(strategy.forVotes >= requiredQuorum, "AegisProtocol: quorum not met for AI strategy");
        require(strategy.forVotes > strategy.againstVotes, "AegisProtocol: AI strategy did not pass vote");

        strategy.executed = true;

        // --- SIMULATE REBALANCING ---
        // In a real-world scenario, this would involve complex interactions with AMMs (e.g., Uniswap)
        // and oracle price feeds to determine the current value and execute swaps.
        // For this simulation, we simplify by assuming:
        // 1. The total value of the treasury is the sum of all tokens involved in the strategy.
        // 2. Excess tokens are "sent out" (e.g., to the owner acting as an exchange partner).
        // 3. Deficit tokens (for GovernanceToken) are "minted" or (for other tokens) are assumed to be "received" from an external source.

        uint256 totalTreasuryValue = 0; // Simplified total value, assuming 1:1 conversion for demonstration
        for (uint i = 0; i < strategy.assets.length; i++) {
            totalTreasuryValue = totalTreasuryValue.add(IERC20(strategy.assets[i]).balanceOf(address(this)));
        }
        
        for (uint i = 0; i < strategy.assets.length; i++) {
            address token = strategy.assets[i];
            uint256 targetAmount = totalTreasuryValue.mul(strategy.percentages[i]).div(100);
            uint256 currentAmount = IERC20(token).balanceOf(address(this));

            if (currentAmount > targetAmount) {
                // Simulate selling excess by transferring to owner (acting as a conceptual exchange)
                IERC20(token).transfer(owner(), currentAmount.sub(targetAmount));
            } else if (currentAmount < targetAmount) {
                // Simulate buying deficit by minting (if governance token) or receiving from owner
                if (token == address(governanceToken)) {
                    governanceToken.mint(address(this), targetAmount.sub(currentAmount));
                } else {
                    // For other tokens, a real system would swap. Here, assume external funding by owner.
                    // This would require `owner()` to have approved AegisProtocol to `transferFrom`.
                    // IERC20(token).transferFrom(owner(), address(this), targetAmount.sub(currentAmount));
                }
            }
        }

        awardReputation(strategy.proposer, 100); // Award AI Oracle for successful strategy
        // Additional reputation could be awarded to voters who supported the winning strategy.

        emit AIStrategyExecuted(strategyId);
    }

    /// @notice Simulates sending treasury funds to an external yield-generating protocol.
    /// This function should be called via `executeProposal`. `onlyOwner` is used as a placeholder for DAO execution.
    /// @param token The address of the token to allocate.
    /// @param amount The amount of tokens to allocate.
    /// @param yieldProtocol The address of the external yield protocol.
    function allocateFundsForYield(address token, uint256 amount, address yieldProtocol) external onlyOwner whenNotPaused {
        require(token != address(0), "AegisProtocol: invalid token address");
        require(amount > 0, "AegisProtocol: amount must be positive");
        require(yieldProtocol != address(0), "AegisProtocol: invalid yield protocol address");
        require(IERC20(token).balanceOf(address(this)) >= amount, "AegisProtocol: insufficient treasury balance");

        // In a real scenario, this would involve calling a specific `deposit` function on the yield protocol.
        // e.g., `IYIELDPool(yieldProtocol).deposit(amount);`
        IERC20(token).transfer(yieldProtocol, amount); // Simplified: direct transfer
        emit FundsAllocatedForYield(token, amount, yieldProtocol);
    }

    /// @notice Simulates retrieving funds (including generated yield) from a yield protocol.
    /// This function should be called via `executeProposal`. `onlyOwner` is used as a placeholder for DAO execution.
    /// @param token The address of the token to reclaim.
    /// @param amount The total amount to reclaim (principal + yield).
    function reclaimYield(address token, uint256 amount) external onlyOwner whenNotPaused {
        require(token != address(0), "AegisProtocol: invalid token address");
        require(amount > 0, "AegisProtocol: amount must be positive");

        // In a real scenario, this would involve calling a specific `withdraw` function on the yield protocol.
        // e.g., `IYIELDPool(yieldProtocol).withdraw(amount, address(this));`
        // For simulation, we assume `owner()` (acting as the yield protocol) provides these funds back.
        // This requires `owner()` to have approved AegisProtocol to `transferFrom`.
        IERC20(token).transferFrom(owner(), address(this), amount);
        emit YieldReclaimed(token, amount);
    }

    // --- NFT UTILITY & MISC ---

    /// @notice Mints a special non-transferable NFT (`governanceNFT`) for core contributors, potentially granting unique benefits.
    /// This is typically a one-time mint for specific roles or early contributors, callable via DAO proposal.
    /// `onlyOwner` is used as a placeholder for DAO execution.
    /// @param to The address to mint the Governance NFT to.
    /// @param boostAmount The voting power boost this NFT provides.
    function mintGovernanceNFT(address to, uint256 boostAmount) external onlyOwner whenNotPaused {
        require(to != address(0), "AegisProtocol: cannot mint to zero address");
        uint256 tokenId = nextGovernanceNFTId++;
        governanceNFT.mint(to, tokenId);
        governanceNFTBoosts[tokenId] = boostAmount;
        emit GovernanceNFTMinted(to, tokenId, boostAmount);
    }

    /// @notice Calculates the additional voting power conferred by a specific Governance NFT.
    /// @param tokenId The ID of the Governance NFT.
    /// @return The voting boost amount.
    function getNFTVotingBoost(uint256 tokenId) public view returns (uint256) {
        return governanceNFTBoosts[tokenId];
    }

    /// @notice DAO-governed function to define or update the reputation thresholds for badge claiming.
    /// This function should be called via `executeProposal`. `onlyOwner` is used as a placeholder for DAO execution.
    /// @param tierId The ID of the reputation tier.
    /// @param threshold The reputation score required for this tier.
    function setReputationTier(uint256 tierId, uint256 threshold) external onlyOwner whenNotPaused {
        require(tierId > 0, "AegisProtocol: tier ID must be positive");
        reputationTiers[tierId] = threshold;
    }

    /// @notice A high-privilege function to pause critical protocol operations in an emergency.
    /// Callable only by the contract owner.
    /// @param _paused True to pause, false to unpause.
    function emergencyShutdown(bool _paused) external onlyOwner {
        paused = _paused;
        emit ProtocolPaused(_paused);
    }
}
```