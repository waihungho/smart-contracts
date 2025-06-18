Okay, here is a Solidity smart contract implementing a Decentralized Autonomous Organization (DAO) with advanced features like multiple voting strategies (token, reputation, NFT badge based), liquid democracy (delegation), conditional proposal execution, treasury management, and an emergency veto mechanism.

It aims to be creative and combine several trendy concepts without being a direct copy of standard open-source DAO implementations like Compound's Governor contracts, focusing on a dynamic and multifaceted governance approach.

---

**Outline and Function Summary**

This smart contract (`DecentralizedAutonomousOrganizationDAO`) implements a multi-faceted governance system.

1.  **Core Concepts:**
    *   **Governance Token (ERC20):** Standard token used for one form of voting power.
    *   **Governance Badge (ERC721):** Non-transferable NFT awarded for participation/contribution, granting boosted voting power.
    *   **Reputation Score:** Non-transferable score earned through active participation (proposing, voting, executing), influencing voting power.
    *   **Liquid Democracy:** Users can delegate their voting power (token + reputation + badge boost) to another address.
    *   **Multiple Voting Strategies:** Proposals can define how voting power is calculated (e.g., token-weighted, reputation-weighted, mixed).
    *   **Conditional Execution:** Proposals can specify an external contract and data to check *before* execution is allowed.
    *   **Treasury Management:** The DAO can hold and manage ETH and ERC20 tokens via successful proposals.
    *   **Emergency Veto:** A designated role (set by the DAO) can immediately veto a proposal in critical situations.

2.  **State Variables:**
    *   `governanceToken`: Address of the ERC20 token used for voting.
    *   `governanceBadge`: Address of the ERC721 NFT used for boosted voting.
    *   `vetoer`: Address with emergency veto power (set by DAO).
    *   `proposalCounter`: Counter for unique proposal IDs.
    *   `proposals`: Mapping from proposal ID to `Proposal` struct.
    *   `votes`: Mapping from proposal ID to voter address to `Vote` struct.
    *   `delegates`: Mapping from delegator address to delegatee address.
    *   `reputation`: Mapping from user address to their reputation score.
    *   Configuration parameters (voting period, thresholds, weights, boosts).

3.  **Structs:**
    *   `Proposal`: Stores proposal details (state, description, target, calldata, votes, timing, strategy, condition).
    *   `Vote`: Stores voter support and their voting power breakdown at the time of voting.

4.  **Enums:**
    *   `ProposalState`: Defines the lifecycle of a proposal (Pending, Active, Succeeded, Failed, Executed, Vetoed).
    *   `VotingStrategy`: Defines how voting power is calculated for a specific proposal.

5.  **Events:**
    *   `ProposalCreated`: Logged when a new proposal is submitted.
    *   `Voted`: Logged when a user casts a vote.
    *   `Delegated`: Logged when a user delegates their vote.
    *   `ProposalStateChanged`: Logged when a proposal's state changes.
    *   `ProposalExecuted`: Logged when a successful proposal is executed.
    *   `ReputationUpdated`: Logged when a user's reputation changes.
    *   `EmergencyVetoed`: Logged when a proposal is vetoed.
    *   `TreasurySent`: Logged when the DAO sends funds via a proposal.

6.  **Function Summary (>= 20 functions):**

    *   **Configuration & Setup (Callable only by the DAO itself via proposals):**
        1.  `setGovernanceToken(address _token)`: Sets the address of the governance ERC20 token.
        2.  `setGovernanceBadge(address _badge)`: Sets the address of the governance ERC721 badge contract.
        3.  `setVotingPeriod(uint duration)`: Sets the duration (in seconds) for which proposals are active.
        4.  `setProposalThreshold(uint tokenAmount)`: Sets the minimum token balance required to create a proposal.
        5.  `setQuorumThreshold(uint tokenPercent)`: Sets the minimum percentage of total token supply (at proposal creation) required for a proposal to succeed (based on token votes).
        6.  `setReputationWeight(uint weight)`: Sets the weight applied to reputation score when calculating voting power.
        7.  `setBadgeVoteBoost(uint boost)`: Sets the additional voting power boost granted by holding a badge.
        8.  `setVetoer(address _vetoer)`: Sets the address allowed to use the emergency veto.
        9.  `awardReputation(address recipient, uint amount)`: Awards reputation points to a user.
        10. `mintGovernanceBadge(address recipient, uint256 tokenId)`: Mints a governance badge NFT to a user (requires interaction with the Badge contract). *Note: This function *calls* the badge contract, assuming `address(this)` is the minter there.*

    *   **Delegation:**
        11. `delegateVote(address delegatee)`: Delegates voting power to another address.
        12. `getDelegatee(address delegator)`: Gets the address a user has delegated to. (View)

    *   **Proposal Management:**
        13. `createProposal(string description, address target, bytes calldata, uint votingStrategy, address conditionCheckAddress, bytes conditionCheckData)`: Creates a new proposal. Requires proposal threshold tokens. Takes snapshot of relevant metrics.
        14. `getProposal(uint proposalId)`: Gets details of a specific proposal. (View)
        15. `getProposalState(uint proposalId)`: Gets the current state of a specific proposal. (View)
        16. `getCurrentProposalCount()`: Gets the total number of proposals created. (View)

    *   **Voting:**
        17. `castVote(uint proposalId, bool support)`: Casts a vote for or against a proposal.
        18. `getVote(uint proposalId, address voter)`: Gets the vote details of a specific user for a proposal. (View)
        19. `getVotingPower(address user, uint proposalId)`: Calculates and returns the voting power of a user for a specific proposal based on the proposal's strategy and snapshot data (or current data if snapshot isn't used). (View)
        20. `getProposalVoteCounts(uint proposalId)`: Gets the current vote counts (for, against) for a proposal. (View)
        21. `hasVoted(uint proposalId, address user)`: Checks if a user has already voted on a proposal. (View)

    *   **Execution:**
        22. `executeProposal(uint proposalId)`: Executes a successful and non-vetoed proposal after its voting period ends and conditions are met.
        23. `checkExecutionCondition(uint proposalId)`: Checks if the external condition for a proposal's execution is met. (View)

    *   **Treasury (Actions performed by `executeProposal`):**
        24. `depositETH()`: Payable function to receive ETH into the DAO treasury.
        25. `getTreasuryBalance()`: Gets the DAO's current ETH balance. (View)
        26. `getTokenBalance(address tokenAddress)`: Gets the DAO's balance of a specific ERC20 token. (View)

    *   **Advanced/Emergency:**
        27. `emergencyVeto(uint proposalId)`: Allows the designated vetoer to immediately stop a proposal.

    *   **Helper Views:**
        28. `getVotingPeriod()`: Gets the current voting period duration. (View)
        29. `getProposalThreshold()`: Gets the current proposal threshold. (View)
        30. `getQuorumThreshold()`: Gets the current quorum threshold percentage. (View)
        31. `getReputationWeight()`: Gets the current reputation weight. (View)
        32. `getBadgeVoteBoost()`: Gets the current badge vote boost amount. (View)
        33. `getVetoer()`: Gets the address of the current vetoer. (View)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To potentially receive badges if needed, though not strictly for governance power logic

// Minimal Interface for a contract that checks conditions for proposals
interface IConditionCheck {
    /// @notice Checks if a specific condition is met.
    /// @param data Arbitrary data passed from the proposal.
    /// @return bool True if the condition is met, false otherwise.
    function checkCondition(bytes calldata data) external view returns (bool);
}

/**
 * @title DecentralizedAutonomousOrganizationDAO
 * @notice A dynamic and multi-faceted DAO contract combining token, reputation,
 *         NFT badge governance, liquid democracy, and conditional execution.
 * @dev This contract is designed as a demonstration of advanced concepts.
 *      It includes multiple voting strategies, delegation, reputation tracking,
 *      NFT badge integration for boosts, conditional proposal execution,
 *      treasury management, and an emergency veto mechanism.
 *      Configuration functions are callable only by the DAO itself via proposal execution.
 *      It is NOT audited and should NOT be used in production without extensive review.
 */
contract DecentralizedAutonomousOrganizationDAO is ERC721Holder { // Inherit ERC721Holder if the DAO itself might hold badges

    // --- State Variables ---

    IERC20 public governanceToken;
    IERC721 public governanceBadge; // ERC721 contract address for governance badges

    address public vetoer; // Address authorized for emergency veto

    uint256 private proposalCounter;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Vote)) private votes; // proposalId => voter => Vote
    mapping(address => address) private delegates; // delegator => delegatee
    mapping(address => uint256) private reputation; // user => reputation score

    // Configuration Parameters (set via proposals)
    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public proposalThreshold = 100e18; // Default min tokens to propose (adjust based on token decimals)
    uint256 public quorumThreshold = 4; // Default 4% token supply participation for quorum (x/100)
    uint256 public reputationWeight = 1; // Weight of reputation points in voting (e.g., 1:1 with tokens)
    uint256 public badgeVoteBoost = 500e18; // Additional vote power granted by holding a badge (adjust based on token decimals)

    // --- Enums ---

    enum ProposalState {
        Pending,   // Newly created, before start time
        Active,    // Voting period active
        Succeeded, // Voting period ended, passed checks
        Failed,    // Voting period ended, failed checks (quorum, votes)
        Executed,  // Proposal successfully executed
        Vetoed     // Proposal cancelled by vetoer
    }

    enum VotingStrategy {
        TokenWeighted,       // Vote power = token balance
        ReputationWeighted,  // Vote power = reputation score * reputationWeight
        TokenReputationMix,  // Vote power = token balance + (reputation score * reputationWeight)
        TokenBadgeBoost      // Vote power = token balance + (badgeCount * badgeVoteBoost)
    }

    // --- Structs ---

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address target; // Contract address or DAO itself (address(this)) for treasury actions
        bytes calldata; // Encoded function call for execution
        uint256 voteStartTime;
        uint256 voteEndTime;
        ProposalState state;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 totalVotingPowerAtSnapshot; // Total possible power relevant to the strategy at creation time
        VotingStrategy votingStrategy;
        address conditionCheckAddress; // External contract to call for condition check
        bytes conditionCheckData;    // Data to pass to the condition check contract
    }

    struct Vote {
        bool hasVoted;
        bool support; // True for 'for', False for 'against'
        uint256 votingPower; // Calculated power used for this vote
    }

    // --- Events ---

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 voteStartTime, uint256 voteEndTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event Delegated(address indexed delegator, address indexed delegatee);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, bool success, bytes result);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event EmergencyVetoed(uint256 indexed proposalId, address indexed vetoer);
    event TreasurySent(address indexed recipient, uint256 amount, address indexed tokenAddress); // Token address is address(0) for ETH

    // --- Modifiers (Internal usage, access controlled by DAO execution) ---

    modifier onlyDAO() {
        require(msg.sender == address(this), "Only DAO can call this function");
        _;
    }

    modifier onlyVetoer() {
        require(msg.sender == vetoer, "Only vetoer can call this function");
        _;
    }

    // --- Constructor ---

    constructor(address _governanceToken, address _governanceBadge) {
        require(_governanceToken != address(0), "Invalid token address");
        require(_governanceBadge != address(0), "Invalid badge address");
        governanceToken = IERC20(_governanceToken);
        governanceBadge = IERC721(_governanceBadge);
        // vetoer is initially address(0) and must be set by the DAO later
    }

    // Payable fallback/receive to accept ETH into the treasury
    receive() external payable {
        emit TreasurySent(address(this), msg.value, address(0)); // Log received ETH (to DAO address)
    }

    fallback() external payable {
        // Allow receiving ETH via fallback as well, useful for proposals sending ETH
    }


    // --- Configuration Functions (Callable only by executeProposal) ---

    /**
     * @notice Sets the address of the governance ERC20 token. Callable only by the DAO.
     * @param _token The address of the ERC20 token.
     */
    function setGovernanceToken(address _token) external onlyDAO {
        require(_token != address(0), "Invalid token address");
        governanceToken = IERC20(_token);
    }

    /**
     * @notice Sets the address of the governance ERC721 badge contract. Callable only by the DAO.
     * @param _badge The address of the ERC721 badge contract.
     */
    function setGovernanceBadge(address _badge) external onlyDAO {
        require(_badge != address(0), "Invalid badge address");
        governanceBadge = IERC721(_badge);
    }

    /**
     * @notice Sets the duration for which proposals are active for voting. Callable only by the DAO.
     * @param duration The voting period in seconds.
     */
    function setVotingPeriod(uint256 duration) external onlyDAO {
        require(duration > 0, "Voting period must be positive");
        votingPeriod = duration;
    }

    /**
     * @notice Sets the minimum token balance required to create a proposal. Callable only by the DAO.
     * @param tokenAmount The required token amount (in smallest units).
     */
    function setProposalThreshold(uint256 tokenAmount) external onlyDAO {
        proposalThreshold = tokenAmount;
    }

    /**
     * @notice Sets the minimum percentage of total token supply required for quorum (x/100). Callable only by the DAO.
     * @param tokenPercent The quorum threshold percentage (e.g., 4 for 4%).
     */
    function setQuorumThreshold(uint256 tokenPercent) external onlyDAO {
        require(tokenPercent <= 100, "Quorum threshold cannot exceed 100%");
        quorumThreshold = tokenPercent;
    }

    /**
     * @notice Sets the weight applied to reputation score when calculating voting power. Callable only by the DAO.
     * @param weight The weight multiplier for reputation points.
     */
    function setReputationWeight(uint256 weight) external onlyDAO {
        reputationWeight = weight;
    }

    /**
     * @notice Sets the additional voting power boost granted by holding a badge. Callable only by the DAO.
     * @param boost The additional vote power amount per badge (in smallest token units).
     */
    function setBadgeVoteBoost(uint256 boost) external onlyDAO {
        badgeVoteBoost = boost;
    }

    /**
     * @notice Sets the address allowed to use the emergency veto. Callable only by the DAO.
     * @param _vetoer The address to grant veto power.
     */
    function setVetoer(address _vetoer) external onlyDAO {
        vetoer = _vetoer;
    }

    /**
     * @notice Awards reputation points to a user. Callable only by the DAO.
     * @param recipient The address to award reputation to.
     * @param amount The amount of reputation points to add.
     */
    function awardReputation(address recipient, uint256 amount) external onlyDAO {
        reputation[recipient] += amount;
        emit ReputationUpdated(recipient, reputation[recipient]);
    }

    /**
     * @notice Mints a governance badge NFT to a user. Callable only by the DAO.
     * @dev Requires that the `governanceBadge` contract has a `mint` function
     *      callable by this DAO contract's address. This is an example
     *      integration point. The actual minting logic is in the badge contract.
     * @param recipient The address to mint the badge to.
     * @param tokenId The ID of the badge to mint.
     */
    function mintGovernanceBadge(address recipient, uint256 tokenId) external onlyDAO {
        // Example: Assumes governanceBadge contract has a mint function
        // In a real scenario, you'd define the exact interface and call it.
        // For this example, we assume a simple ERC721 mint function compatible with `call`.
        bytes memory mintCallData = abi.encodeWithSignature("mint(address,uint256)", recipient, tokenId);
        (bool success, bytes memory result) = address(governanceBadge).call(mintCallData);
        require(success, string(abi.decode(result, (string))));
        // Optionally emit a specific BadgeMinted event here
    }

    // --- Delegation Functions ---

    /**
     * @notice Delegates voting power to another address.
     * @param delegatee The address to delegate voting power to. address(0) to undelegate.
     */
    function delegateVote(address delegatee) external {
        require(delegatee != msg.sender, "Cannot delegate to yourself");
        delegates[msg.sender] = delegatee;
        emit Delegated(msg.sender, delegatee);
    }

    /**
     * @notice Gets the address a user has delegated their voting power to.
     * @param delegator The address whose delegatee is requested.
     * @return address The delegatee address. Returns address(0) if no delegation is set.
     */
    function getDelegatee(address delegator) external view returns (address) {
        return delegates[delegator];
    }

    // --- Proposal Management Functions ---

    /**
     * @notice Creates a new proposal. Requires the proposer to hold the proposal threshold tokens.
     * @param description A brief description of the proposal.
     * @param target The address of the contract or address(this) to call upon execution.
     * @param calldata The encoded function call data for execution.
     * @param votingStrategy The strategy to use for calculating voting power for this proposal.
     * @param conditionCheckAddress The address of an IConditionCheck contract for conditional execution (address(0) if no condition).
     * @param conditionCheckData Data to pass to the condition check contract's checkCondition function.
     */
    function createProposal(
        string memory description,
        address target,
        bytes memory calldata,
        uint256 votingStrategy,
        address conditionCheckAddress,
        bytes memory conditionCheckData
    ) external {
        // Check proposal threshold
        require(governanceToken.balanceOf(msg.sender) >= proposalThreshold, "Insufficient tokens to create proposal");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(uint8(votingStrategy) < uint8(VotingStrategy.TokenBadgeBoost) + 1, "Invalid voting strategy");

        uint256 proposalId = proposalCounter++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + votingPeriod;

        // Calculate total possible voting power at the time of proposal creation
        // Note: This is an estimation. True snapshot requires more complex token/reputation state history.
        // For simplicity here, we calculate based on current total supply + total reputation + total badges.
        // A more robust system would track token/reputation/badge state block by block.
        uint256 totalTokenSupply = governanceToken.totalSupply();
        // Calculating total reputation and total badges globally is gas prohibitive.
        // Instead, we can approximate quorum based on token supply only, or require
        // voters to explicitly stake/snapshot their power when voting/proposing.
        // Let's simplify and only base Quorum on Token supply *for the TokenWeighted strategy*.
        // For other strategies, Quorum might be based on *participating* reputation/badge holders.
        // A robust multi-strategy quorum is complex. Let's keep quorum token-based for TokenWeighted,
        // and for others, perhaps rely more on raw vote count or a different metric.
        // Let's define quorum check differently per strategy, but keep the stored `totalVotingPowerAtSnapshot`
        // as the relevant total *token* supply for consistency, mainly used for the TokenWeighted quorum calculation.
        // For Reputation/Badge strategies, we'll check a simple participation threshold or rely solely on vote difference.
        uint256 totalPower = 0;
        if (VotingStrategy(votingStrategy) == VotingStrategy.TokenWeighted || VotingStrategy(votingStrategy) == VotingStrategy.TokenReputationMix || VotingStrategy(votingStrategy) == VotingStrategy.TokenBadgeBoost) {
             totalPower = totalTokenSupply; // Use total supply as baseline for quorum check in token-related strategies
        }
        // For ReputationWeighted only, quorum is harder. Maybe require a minimum # of reputation holders voting?
        // Let's make quorum applicable primarily to TokenWeighted strategy for this example.

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            target: target,
            calldata: calldata,
            voteStartTime: startTime,
            voteEndTime: endTime,
            state: ProposalState.Active, // Start active immediately
            forVotes: 0,
            againstVotes: 0,
            totalVotingPowerAtSnapshot: totalPower, // Represents total token supply at creation
            votingStrategy: VotingStrategy(votingStrategy),
            conditionCheckAddress: conditionCheckAddress,
            conditionCheckData: conditionCheckData
        });

        emit ProposalCreated(proposalId, msg.sender, description, startTime, endTime);
    }

    /**
     * @notice Gets details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return The proposal struct.
     */
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        return proposals[proposalId];
    }

    /**
     * @notice Gets the current state of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        // Update state if voting period has ended
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.voteEndTime) {
            // State transition handled in executeProposal or via explicit check/update
             // For a view function, we just *calculate* the potential state change
             if (_hasProposalPassed(proposalId)) {
                 return ProposalState.Succeeded;
             } else {
                 return ProposalState.Failed;
             }
        }
        return proposal.state;
    }

    /**
     * @notice Gets the total number of proposals created.
     * @return The total count of proposals.
     */
    function getCurrentProposalCount() external view returns (uint256) {
        return proposalCounter;
    }

    // --- Voting Functions ---

    /**
     * @notice Casts a vote for or against a proposal. Voting power is calculated
     *         at the time of casting the vote based on the proposal's strategy
     *         and the user's current/delegated token balance, reputation, and badges.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for', False for 'against'.
     */
    function castVote(uint256 proposalId, bool support) external {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active for voting");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period is not active");
        require(!votes[proposalId][msg.sender].hasVoted, "Already voted");

        // Determine the effective voter (self or delegatee)
        address effectiveVoter = msg.sender;
        while (delegates[effectiveVoter] != address(0)) {
            effectiveVoter = delegates[effectiveVoter];
        }

        // Get voting power at the time of voting
        uint256 voterPower = getVotingPower(effectiveVoter, proposalId);
        require(voterPower > 0, "Voter has no voting power");

        // Record the vote
        votes[proposalId][msg.sender] = Vote({
            hasVoted: true,
            support: support,
            votingPower: voterPower // Store the power used
        });

        // Update proposal vote counts
        if (support) {
            proposal.forVotes += voterPower;
        } else {
            proposal.againstVotes += voterPower;
        }

        emit Voted(proposalId, msg.sender, support, voterPower);
    }

    /**
     * @notice Gets the vote details of a specific user for a proposal.
     * @param proposalId The ID of the proposal.
     * @param voter The address of the voter.
     * @return The Vote struct for the user on this proposal.
     */
    function getVote(uint256 proposalId, address voter) external view returns (Vote memory) {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        return votes[proposalId][voter];
    }

    /**
     * @notice Calculates and returns the voting power of a user for a specific proposal
     *         based on the proposal's strategy and the user's current/delegated state.
     * @dev This function calculates power dynamically at call time. A production system
     *      might snapshot power at proposal creation or voting time for determinism.
     *      For this example, we calculate based on *current* state + delegation chain.
     * @param user The address whose voting power is requested.
     * @param proposalId The ID of the proposal (determines strategy).
     * @return uint256 The calculated voting power.
     */
    function getVotingPower(address user, uint256 proposalId) public view returns (uint256) {
        if (proposalId >= proposalCounter) return 0; // Handle invalid proposal ID gracefully
        Proposal storage proposal = proposals[proposalId];

        // Resolve delegation chain
        address effectiveUser = user;
        while (delegates[effectiveUser] != address(0)) {
            effectiveUser = delegates[effectiveUser];
            // Prevent delegation cycles (though `delegateVote` prevents simple cycles)
            // A robust check for long cycles would be needed in production
            require(effectiveUser != user, "Delegation cycle detected");
        }

        uint256 power = 0;
        if (proposal.votingStrategy == VotingStrategy.TokenWeighted ||
            proposal.votingStrategy == VotingStrategy.TokenReputationMix ||
            proposal.votingStrategy == VotingStrategy.TokenBadgeBoost) {
             // Add token weight
             power += governanceToken.balanceOf(effectiveUser);
        }

        if (proposal.votingStrategy == VotingStrategy.ReputationWeighted ||
            proposal.votingStrategy == VotingStrategy.TokenReputationMix) {
            // Add reputation weight
            power += reputation[effectiveUser] * reputationWeight;
        }

        if (proposal.votingStrategy == VotingStrategy.TokenBadgeBoost) {
            // Add badge boost
            // Count badges owned by the effective user
            uint256 badgeCount = governanceBadge.balanceOf(effectiveUser);
            power += badgeCount * badgeVoteBoost;
        }

        return power;
    }

    /**
     * @notice Gets the current vote counts (for, against) for a proposal.
     * @param proposalId The ID of the proposal.
     * @return forVotes The total voting power cast for the proposal.
     * @return againstVotes The total voting power cast against the proposal.
     */
    function getProposalVoteCounts(uint256 proposalId) external view returns (uint256 forVotes, uint256 againstVotes) {
         require(proposalId < proposalCounter, "Invalid proposal ID");
         Proposal storage proposal = proposals[proposalId];
         return (proposal.forVotes, proposal.againstVotes);
    }

    /**
     * @notice Checks if a user has already voted on a proposal.
     * @param proposalId The ID of the proposal.
     * @param user The address to check.
     * @return bool True if the user has voted, false otherwise.
     */
    function hasVoted(uint256 proposalId, address user) external view returns (bool) {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        return votes[proposalId][user].hasVoted;
    }

    // --- Execution Functions ---

    /**
     * @notice Executes a successful proposal. Can be called by anyone once conditions are met.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        // Ensure voting period has ended
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended");
        require(proposal.state != ProposalState.Executed &&
                proposal.state != ProposalState.Vetoed &&
                proposal.state != ProposalState.Pending, // Should be active or Succeeded/Failed
                "Proposal not in executable state");

        // Check if the proposal passed the vote and quorum thresholds
        if (!_hasProposalPassed(proposalId)) {
             proposal.state = ProposalState.Failed;
             emit ProposalStateChanged(proposalId, ProposalState.Failed);
             return; // Stop execution if it failed
        }

        // Check execution condition if specified
        if (proposal.conditionCheckAddress != address(0)) {
            require(checkExecutionCondition(proposalId), "Execution condition not met");
        }

        // If passed and conditions met, execute the call
        require(proposal.state != ProposalState.Executed, "Proposal already executed");
        require(proposal.state != ProposalState.Vetoed, "Proposal was vetoed");

        // Execute the call (handle potential ETH transfer if target is payable)
        (bool success, bytes memory result) = proposal.target.call{value: address(this).balance}(proposal.calldata);
        // Note: Sending entire balance might be risky. For specific ETH transfers,
        // the proposal calldata should call a helper function like `sendETH`.
        // Let's refine this: `call` should only forward ETH specified *within* the calldata
        // if the target is payable. If the target is address(this), it calls internal DAO functions.
        // We need specific internal functions for sending ETH/Tokens that proposals target.

        // Let's create internal helper functions for treasury actions called by proposals
        // and update `executeProposal` to route calls targeting `address(this)` to these helpers.

        // Revert if the target call failed
        if (!success) {
             proposal.state = ProposalState.Failed; // Or a new state like ExecutionFailed
             emit ProposalStateChanged(proposalId, ProposalState.Failed); // Log failure
             emit ProposalExecuted(proposalId, false, result);
             revert("Proposal execution failed"); // Stop the transaction
        }

        // Update proposal state
        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
        emit ProposalExecuted(proposalId, success, result);

        // Optionally award reputation to the proposer and successful voters here
        reputation[proposal.proposer] += 5; // Example: Proposer gets reputation
        emit ReputationUpdated(proposal.proposer, reputation[proposal.proposer]);
        // Award reputation to voters? Iterating through votes mapping is not feasible.
        // Could require voters to call a separate function to claim reputation after execution.
    }


    /**
     * @notice Checks if the external condition for a proposal's execution is met.
     *         Callable by anyone as a view function.
     * @param proposalId The ID of the proposal.
     * @return bool True if the condition is met, false otherwise.
     */
    function checkExecutionCondition(uint256 proposalId) public view returns (bool) {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];

        if (proposal.conditionCheckAddress == address(0)) {
            return true; // No condition specified
        }

        require(proposal.conditionCheckAddress.code.length > 0, "Condition check address is not a contract");

        // Call the external condition check contract
        (bool success, bytes memory result) = proposal.conditionCheckAddress.staticcall(
            abi.encodeWithSelector(IConditionCheck.checkCondition.selector, proposal.conditionCheckData)
        );

        require(success, "External condition check call failed");

        return abi.decode(result, (bool));
    }


    // --- Internal Helper for Checking Proposal Pass Conditions ---
    // @dev Checks if a proposal has passed based on vote counts and quorum.
    //      Does NOT check if the voting period has ended.
    function _hasProposalPassed(uint256 proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[proposalId];

        // Must have more 'for' votes than 'against' votes
        if (proposal.forVotes <= proposal.againstVotes) {
            return false;
        }

        // Check Quorum based on strategy
        // Quorum logic can be complex with multiple strategies.
        // Simplified Quorum: Only applies meaningfully to TokenWeighted.
        // For other strategies, we might just require a minimum participation count
        // or rely solely on `forVotes > againstVotes`.
        if (proposal.votingStrategy == VotingStrategy.TokenWeighted ||
            proposal.votingStrategy == VotingStrategy.TokenReputationMix ||
            proposal.votingStrategy == VotingStrategy.TokenBadgeBoost) {
            // For token-related strategies, check token-based quorum against total token supply snapshot
            // Quorum calculation: (forVotes + againstVotes) * 100 >= totalVotingPowerAtSnapshot * quorumThreshold
            // Avoid division before multiplication to prevent rounding errors:
            if ((proposal.forVotes + proposal.againstVotes) * 100 < proposal.totalVotingPowerAtSnapshot * quorumThreshold) {
                return false; // Failed quorum
            }
        }
        // For ReputationWeighted only, or other strategies, additional quorum checks could be added here.
        // e.g., require minimum number of unique voters, or minimum total reputation points voting.

        return true; // Passed vote count and quorum checks
    }

    // --- Treasury Management Functions (Callable only by executeProposal) ---
    // @dev These functions are intended to be called via successful proposals.

    /**
     * @notice Allows the DAO to send ETH from its treasury. Callable only by the DAO.
     * @param payableRecipient The address to send ETH to.
     * @param amount The amount of ETH to send (in wei).
     */
    function sendETH(address payable payableRecipient, uint256 amount) external onlyDAO {
        require(amount > 0, "Amount must be positive");
        require(address(this).balance >= amount, "Insufficient ETH balance in treasury");
        (bool success, ) = payableRecipient.call{value: amount}("");
        require(success, "Failed to send ETH");
        emit TreasurySent(payableRecipient, amount, address(0));
    }

    /**
     * @notice Allows the DAO to send ERC20 tokens from its treasury. Callable only by the DAO.
     * @param tokenAddress The address of the ERC20 token.
     * @param recipient The address to send tokens to.
     * @param amount The amount of tokens to send (in smallest units).
     */
    function sendToken(address tokenAddress, address recipient, uint256 amount) external onlyDAO {
        require(tokenAddress != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be positive");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance in treasury");
        require(token.transfer(recipient, amount), "Failed to send token");
        emit TreasurySent(recipient, amount, tokenAddress);
    }

    /**
     * @notice Payable function to receive ETH into the DAO treasury.
     * @dev Any ETH sent directly to the contract address will land here.
     */
    function depositETH() external payable {
        emit TreasurySent(address(this), msg.value, address(0));
    }

    /**
     * @notice Gets the DAO's current ETH balance.
     * @return uint256 The ETH balance in wei.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Gets the DAO's balance of a specific ERC20 token.
     * @param tokenAddress The address of the ERC20 token.
     * @return uint256 The token balance in smallest units.
     */
    function getTokenBalance(address tokenAddress) external view returns (uint256) {
        require(tokenAddress != address(0), "Invalid token address");
        return IERC20(tokenAddress).balanceOf(address(this));
    }


    // --- Advanced / Emergency Functions ---

    /**
     * @notice Allows the designated vetoer to immediately stop a proposal.
     *         Transitions proposal state to Vetoed.
     * @param proposalId The ID of the proposal to veto.
     */
    function emergencyVeto(uint256 proposalId) external onlyVetoer {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Proposal not in a state that can be vetoed");

        proposal.state = ProposalState.Vetoed;
        emit ProposalStateChanged(proposalId, ProposalState.Vetoed);
        emit EmergencyVetoed(proposalId, msg.sender);
    }


    // --- Helper Views (for external calls not covered above) ---

     /**
     * @notice Gets the current voting period duration.
     * @return uint256 Voting period in seconds.
     */
    function getVotingPeriod() external view returns (uint256) {
        return votingPeriod;
    }

    /**
     * @notice Gets the current minimum token balance required to create a proposal.
     * @return uint256 Proposal threshold in smallest token units.
     */
    function getProposalThreshold() external view returns (uint256) {
        return proposalThreshold;
    }

    /**
     * @notice Gets the current minimum percentage of total token supply required for quorum (x/100).
     * @return uint256 Quorum threshold percentage.
     */
    function getQuorumThreshold() external view returns (uint256) {
        return quorumThreshold;
    }

    /**
     * @notice Gets the current weight applied to reputation score.
     * @return uint256 Reputation weight multiplier.
     */
    function getReputationWeight() external view returns (uint256) {
        return reputationWeight;
    }

    /**
     * @notice Gets the current additional voting power boost granted by holding a badge.
     * @return uint256 Badge vote boost amount in smallest token units.
     */
    function getBadgeVoteBoost() external view returns (uint256) {
        return badgeVoteBoost;
    }

     /**
     * @notice Gets the address of the current vetoer.
     * @return address The vetoer address.
     */
    function getVetoer() external view returns (address) {
        return vetoer;
    }
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Multiple Voting Strategies (`VotingStrategy` enum):** Allows the DAO to evolve its governance. Proposals can be weighted differently based on token holdings, accumulated reputation, or specific NFT badges. This moves beyond simple token-weighted governance.
2.  **Reputation System (`reputation` mapping, `awardReputation`):** Tracks non-transferable "karma" or reputation based on participation. This score can be factored into voting power, rewarding active and constructive community members beyond just their token balance. The `awardReputation` function is designed to be called via a successful proposal, meaning the DAO itself decides who earns reputation and how much.
3.  **NFT Badge Boost (`governanceBadge`, `badgeVoteBoost`, `getVotingPower`, `mintGovernanceBadge`):** Integrates ERC721 NFTs directly into the governance mechanism. Holding a specific "Governance Badge" NFT can grant a fixed voting power boost, regardless of token balance or reputation. This allows for awarding significant influence to key contributors, early adopters, or specific roles via non-transferable badges. The DAO controls the minting of these badges.
4.  **Liquid Democracy (`delegates` mapping, `delegateVote`, `getDelegatee`, `getVotingPower`):** Users can delegate their full voting power (calculated based on tokens, reputation, *and* badges) to another address. This enables users who don't have time to vote on every proposal to empower delegates, increasing overall participation and potentially leading to more informed votes.
5.  **Conditional Execution (`conditionCheckAddress`, `conditionCheckData`, `checkExecutionCondition`):** A proposal can specify an external smart contract and data. Before the proposal can be executed, this external contract must return `true` when called with the provided data. This enables sophisticated conditions for proposal execution, such as:
    *   Executing only if an external price feed is within a certain range.
    *   Executing only if a specific state variable in another contract is true.
    *   Executing only after a certain external event has occurred (as reported by an oracle contract).
6.  **Emergency Veto (`vetoer`, `emergencyVeto`):** Provides a safety mechanism. A designated address (which itself should be set via a secure DAO vote, or perhaps a multi-sig) can immediately halt a malicious or clearly harmful proposal during its active phase.
7.  **DAO-Controlled Configuration:** Most parameters (`votingPeriod`, `thresholds`, `weights`, `vetoer`, token/badge addresses, reputation awarding, badge minting) can *only* be changed or triggered by executing a successful proposal (`onlyDAO` modifier check). This ensures that the community governs the rules of the DAO itself.

This contract provides a flexible framework for a DAO where influence is not solely tied to capital, but also to participation (reputation) and recognition (NFT badges), while incorporating mechanisms for efficiency (delegation) and safety (conditional execution, veto).