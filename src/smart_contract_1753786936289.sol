Here's a Solidity smart contract for an "Adaptive Collective Intelligence Guild" (ACIG). This contract focuses on several advanced, creative, and trendy concepts:

1.  **Dynamic Investment Strategies:** Instead of fixed algorithms, the guild's investment parameters (risk tolerance, allocation, rebalancing thresholds) are dynamically adjustable through community governance and external oracle data.
2.  **Reputation System:** Members earn reputation based on their contributions, successful proposals, and active participation. Reputation influences voting power, access to features, and potentially yield distribution.
3.  **AI/ML Integration (via Oracle):** A simulated "Market Sentiment Oracle" provides external, potentially AI-derived, market insights. This sentiment score can directly influence strategy adjustments or trigger actions.
4.  **Dynamic NFTs:** Members can claim "Achievement Badges" that are NFTs. The metadata/visual representation of these NFTs can evolve based on the member's reputation or their success within the guild.
5.  **Collective Intelligence & DAO Principles:** The core idea is that the community's collective intelligence, augmented by external data, drives the evolution of the investment strategies.

---

### Outline: Adaptive Collective Intelligence Guild (ACIG)

This smart contract orchestrates a decentralized investment guild where members collaborate to evolve and execute investment strategies.

**I. Core Infrastructure & Access Control**
    -   `constructor`: Initializes the guild, sets owner, links NFT and Oracle contracts.
    -   `setOracleAddress`: Allows the owner to update the oracle contract address.
    -   `pause`/`unpause`: Emergency functions to halt/resume critical operations.
    -   `withdrawEmergencyFunds`: Allows the owner to withdraw funds in emergencies.

**II. Guild Membership & Reputation System**
    -   `joinGuild`: Allows users to stake capital (ETH) and become a guild member, gaining initial reputation.
    -   `leaveGuild`: Allows members to withdraw their stake and exit, potentially with reputation decay.
    -   `adjustReputation`: Internal/governance function to modify a member's reputation score.
    -   `getMemberReputation`: Returns the current reputation of a member.
    -   `getMemberTier`: Determines a member's tier (Novice, Contributor, Strategist, Elder) based on reputation and stake.

**III. Dynamic Investment Strategies (DIS) Management**
    -   `proposeStrategyParameterChange`: Members propose modifications to current investment strategy parameters.
    -   `voteOnStrategyProposal`: Members vote on pending strategy change proposals (reputation-weighted).
    -   `executeApprovedStrategyChange`: Executes a passed strategy parameter change, updating the live strategy configuration.
    -   `registerSupportedToken`: Owner adds tokens that can be deposited into strategies.
    -   `removeSupportedToken`: Owner removes supported tokens (if no funds locked).
    -   `depositIntoActiveStrategy`: Members deposit supported tokens into the guild's collective investment pool.
    -   `withdrawFromActiveStrategy`: Members withdraw their share of assets from the pool.
    -   `triggerStrategyExecution`: Callable by a keeper service to execute the current investment strategy based on active parameters and oracle data (simplified for concept).

**IV. Funds & Yield Management**
    -   `getGuildTVL`: Returns the total value locked across all guild assets.
    -   `distributeYieldToMembers`: Distributes accrued profits from successful strategies to members based on their stake and reputation.
    -   `collectProtocolFees`: Transfers accumulated protocol fees to the designated fee recipient.
    -   `getGuildTokenBalance`: Returns the balance of a specific token held by the guild.

**V. Oracle Integration (Simulated AI/Sentiment)**
    -   `requestMarketSentimentUpdate`: Initiates a request to the external (simulated) Market Sentiment Oracle for updated market insights.
    -   `fulfillMarketSentimentUpdate`: Callback function from the Oracle, delivering the sentiment score and potentially triggering internal actions.

**VI. Dynamic Achievement Badges (NFTs)**
    -   `claimAchievementBadge`: Allows members to mint/claim a dynamic ERC721 NFT badge upon reaching specific reputation thresholds or guild milestones.
    -   `updateAchievementBadgeMetadata`: Internal function triggered by reputation changes or milestone achievements, dynamically updating the associated NFT's metadata (e.g., visual representation changes).

**VII. Guild Governance & System Parameters**
    -   `proposeGuildParameterChange`: Members propose changes to core guild-level parameters (e.g., minimum stake, fee percentages, governance thresholds).
    -   `voteOnGuildParameterChange`: Members vote on pending guild parameter change proposals.
    -   `executeApprovedGuildParameterChange`: Executes a passed guild parameter change, updating core contract settings.

**VIII. Emergency & Utility Functions**
    -   `getStrategyPerformanceMetrics`: Returns current metrics of the active strategy.
    -   `receive`/`fallback`: Handles incoming native currency.

---

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Using OpenZeppelin for standard components
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For efficient tracking of supported tokens and member IDs
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting numbers to strings for NFT URI

// --- Interfaces for external contracts ---

// Placeholder for a Dynamic NFT contract - would be a separate ERC721 contract
interface IAchievementBadgeNFT {
    function mintBadge(address to, uint256 badgeId, string calldata initialURI) external returns (uint256 tokenId);
    function updateBadgeURI(uint256 tokenId, string calldata newURI) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    // Minimal ERC721 functions required for interaction
    function balanceOf(address owner) external view returns (uint256);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// Placeholder for a Chainlink-like Oracle interface for Market Sentiment
interface IMarketSentimentOracle {
    event SentimentRequested(bytes32 indexed requestId);
    event SentimentFulfilled(bytes32 indexed requestId, int256 sentimentScore);

    // Function to request sentiment data. In a real oracle, this would involve payment.
    function requestSentiment(address callbackContract) external returns (bytes32 requestId);
    // The oracle would call a specified callback function on `callbackContract`
    // with the fulfillment data, typically through an external adapter.
    // For this example, we'll simulate the oracle calling `fulfillMarketSentimentUpdate` directly on ACIG.
}


contract AdaptiveCollectiveIntelligenceGuild is Ownable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet; // For managing _guildMembers and _supportedTokens
    using EnumerableSet for EnumerableSet.UintSet; // For managing NFT token IDs within a member struct

    // --- Enums & Structs ---

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    enum MemberTier { Novice, Contributor, Strategist, Elder }

    struct Member {
        uint256 stakedAmount; // Total value member has contributed (can be ETH or ERC20 equivalent)
        int256 reputation;    // Reputation score (can be negative for malfeasance)
        uint256 joinTime;
        EnumerableSet.UintSet ownedBadgeTokenIds; // Set of Token IDs of owned dynamic NFTs
    }

    struct StrategyParameters {
        uint256 minRiskTolerance;      // e.g., 0-100, 0=conservative, 100=aggressive, impacts asset choice
        uint256 maxAllocationPercentage; // Max % of guild's TVL to allocate to a single asset/strategy pool
        uint256 rebalanceThresholdBps; // Basis points (10000 = 100%) for rebalancing (e.g., 100bps = 1% deviation)
        int256 minSentimentScoreRequirement; // Minimum sentiment score needed to engage in aggressive strategies
        uint256 yieldDistributionCutBps; // Basis points (e.g., 8000 = 80%) of yield distributed to members, rest for fees/treasury
    }

    struct Proposal {
        uint256 id;
        bytes32 targetKey;      // Hashed name of the parameter being changed (for strategy or guild params)
        bytes newValue;         // New value for the parameter (abi.encoded)
        string description;
        address proposer;
        uint256 voteCountFor;   // Reputation-weighted 'for' votes
        uint256 voteCountAgainst; // Reputation-weighted 'against' votes
        uint256 quorumRequiredReputation; // Minimum total reputation points required for a proposal to pass
        uint256 votingEndTime;
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks who has voted on this specific proposal
    }

    struct ActiveStrategyMetrics {
        uint256 totalDepositedValue; // Current total value locked in this strategy (can be aggregated USD value)
        uint256 lastExecutionTime;   // Timestamp of the last strategy execution
        int256 lastSentimentScore;   // Last received sentiment score from the oracle
        uint256 lastProfitSnapshot;  // Snapshot of total profit at last distribution
    }

    // --- State Variables ---

    IAchievementBadgeNFT public achievementBadgeNFT;
    IMarketSentimentOracle public marketSentimentOracle;

    uint256 public constant MIN_STAKE_AMOUNT = 1 ether; // Minimum native currency (ETH) to join
    int256 public constant INITIAL_REPUTATION = 100;    // Starting reputation for new members
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days; // Default voting period for proposals
    uint256 public constant DEFAULT_QUORUM_PERCENTAGE_REPUTATION = 50; // 50% of total *staked* reputation for a quorum
    uint256 public constant BASE_PROTOCOL_FEE_BPS = 500; // 5% base fee on guild's portion of yield

    address public feeRecipient; // Address to receive protocol fees

    // Mapping of member address to their data
    mapping(address => Member) public members;
    EnumerableSet.AddressSet private _guildMembers; // Set of all active guild member addresses for iteration

    // Dynamic Investment Strategy (DIS) parameters, current state
    StrategyParameters public currentStrategyParameters;
    ActiveStrategyMetrics public activeStrategyMetrics;

    // Mapping for governance proposals (strategy or guild level)
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId; // Counter for unique proposal IDs

    // Supported tokens for deposit/withdrawal (stored as addresses)
    EnumerableSet.AddressSet private _supportedTokens;
    // Map to track the total amount of each supported token held by the guild contract
    mapping(address => uint256) public totalAmountOfSupportedToken;

    // Mapping to track outstanding oracle requests
    mapping(bytes32 => bool) public pendingSentimentRequests;

    // --- Events ---

    event GuildJoined(address indexed member, uint256 stakedAmount, int256 initialReputation);
    event GuildLeft(address indexed member, uint256 unstakedAmount);
    event ReputationAdjusted(address indexed member, int256 oldReputation, int256 newReputation, string reason);

    event StrategyParameterChangeProposed(uint256 indexed proposalId, bytes32 indexed targetKey, bytes newValue, address indexed proposer);
    event StrategyParameterVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event StrategyParameterChangeExecuted(uint256 indexed proposalId, bytes32 indexed targetKey, bytes newValue);

    event GuildParameterChangeProposed(uint256 indexed proposalId, string indexed parameterName, bytes newValue, address indexed proposer);
    event GuildParameterVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GuildParameterChangeExecuted(uint256 indexed proposalId, string indexed parameterName, bytes newValue);

    event FundsDeposited(address indexed member, address indexed token, uint256 amount);
    event FundsWithdrawn(address indexed member, address indexed token, uint256 amount);
    event YieldDistributed(uint256 totalProfit, uint256 distributedToMembers, uint256 collectedFees);
    event StrategyExecuted(uint256 indexed tvlSnapshot, int256 sentimentScoreUsed, uint256 currentEstimatedTVL);

    event MarketSentimentRequested(bytes32 indexed requestId);
    event MarketSentimentFulfilled(bytes32 indexed requestId, int256 sentimentScore);

    event AchievementBadgeClaimed(address indexed member, uint256 indexed badgeId, uint256 indexed tokenId);
    event AchievementBadgeMetadataUpdated(uint256 indexed tokenId, string newURI);

    event SupportedTokenAdded(address indexed tokenAddress);
    event SupportedTokenRemoved(address indexed tokenAddress);

    // --- Modifiers ---

    modifier onlyMember() {
        require(_guildMembers.contains(_msgSender()), "ACIG: Caller is not a guild member");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < nextProposalId, "ACIG: Proposal does not exist");
        _;
    }

    modifier proposalState(uint256 _proposalId, ProposalState _expectedState) {
        require(proposals[_proposalId].state == _expectedState, "ACIG: Proposal in wrong state");
        _;
    }

    // --- Constructor ---

    constructor(address _nftContract, address _oracleContract, address _initialFeeRecipient) Pausable(false) {
        require(_nftContract != address(0), "ACIG: Invalid NFT contract address");
        require(_oracleContract != address(0), "ACIG: Invalid Oracle contract address");
        require(_initialFeeRecipient != address(0), "ACIG: Invalid fee recipient address");

        achievementBadgeNFT = IAchievementBadgeNFT(_nftContract);
        marketSentimentOracle = IMarketSentimentOracle(_oracleContract);
        feeRecipient = _initialFeeRecipient;

        // Initialize default strategy parameters
        currentStrategyParameters = StrategyParameters({
            minRiskTolerance: 50,
            maxAllocationPercentage: 20,
            rebalanceThresholdBps: 100,
            minSentimentScoreRequirement: 0, // Neutral sentiment is baseline
            yieldDistributionCutBps: 8000 // 80% to members, 20% to guild treasury/fees
        });

        // Initialize active strategy metrics
        activeStrategyMetrics = ActiveStrategyMetrics({
            totalDepositedValue: 0,
            lastExecutionTime: 0,
            lastSentimentScore: 0,
            lastProfitSnapshot: 0
        });

        // Add native ETH as a default supported token (represented by address(0x0))
        _supportedTokens.add(address(0x0));
        emit SupportedTokenAdded(address(0x0));
    }

    // --- I. Core Infrastructure & Access Control ---

    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "ACIG: Invalid new oracle address");
        marketSentimentOracle = IMarketSentimentOracle(_newOracleAddress);
        // Event for this change could be useful, but not explicitly requested.
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Allows owner to withdraw tokens in an emergency when contract is paused
    function withdrawEmergencyFunds(address _tokenAddress, uint256 _amount) external onlyOwner whenPaused {
        require(_tokenAddress != address(0), "ACIG: Invalid token address");
        if (_tokenAddress == address(0x0)) { // Native ETH
            (bool success, ) = payable(owner()).call{value: _amount}("");
            require(success, "ACIG: ETH transfer failed");
        } else {
            // Transfer ERC20 tokens
            IERC20(_tokenAddress).transfer(owner(), _amount);
        }
    }

    // --- II. Guild Membership & Reputation System ---

    function joinGuild() external payable whenNotPaused {
        require(!_guildMembers.contains(_msgSender()), "ACIG: Already a guild member");
        require(msg.value >= MIN_STAKE_AMOUNT, "ACIG: Insufficient stake amount to join");

        // Create new member record
        members[_msgSender()] = Member({
            stakedAmount: msg.value,
            reputation: INITIAL_REPUTATION,
            joinTime: block.timestamp,
            ownedBadgeTokenIds: EnumerableSet.UintSet(0) // Initialize an empty set for badges
        });
        _guildMembers.add(_msgSender());

        // Update total value locked (assuming initial stake directly contributes to TVL)
        activeStrategyMetrics.totalDepositedValue += msg.value;
        totalAmountOfSupportedToken[address(0x0)] += msg.value; // Track ETH deposit

        emit GuildJoined(_msgSender(), msg.value, INITIAL_REPUTATION);
        // Optionally, mint a "Novice" badge here automatically
    }

    function leaveGuild() external onlyMember whenNotPaused {
        Member storage member = members[_msgSender()];
        require(member.stakedAmount > 0, "ACIG: No stake to withdraw");

        uint256 stakeToReturn = member.stakedAmount;

        // Clean up member's data
        _guildMembers.remove(_msgSender());
        delete members[_msgSender()]; // Clear storage for the member

        // Update guild's TVL and specific token balance
        activeStrategyMetrics.totalDepositedValue -= stakeToReturn;
        totalAmountOfSupportedToken[address(0x0)] -= stakeToReturn; // Assuming stake was ETH

        // Transfer ETH back to member
        (bool success, ) = payable(_msgSender()).call{value: stakeToReturn}("");
        require(success, "ACIG: ETH withdrawal failed");

        emit GuildLeft(_msgSender(), stakeToReturn);

        // In a more robust system:
        // - Burn or transfer member's NFTs to a dead address.
        // - Implement a cooldown period or penalty for early withdrawal.
    }

    // Internal or governance-controlled function to adjust reputation
    function adjustReputation(address _memberAddress, int256 _reputationChange, string calldata _reason) external onlyOwner { // Or by a passed governance vote
        require(_guildMembers.contains(_memberAddress), "ACIG: Not a guild member");
        int256 oldReputation = members[_memberAddress].reputation;
        members[_memberAddress].reputation += _reputationChange;

        emit ReputationAdjusted(_memberAddress, oldReputation, members[_memberAddress].reputation, _reason);

        // Trigger NFT metadata update if reputation tier potentially changes
        // This is a simplified check. A robust implementation would map badge types to tiers.
        MemberTier currentTier = getMemberTier(_memberAddress);
        // Find relevant NFTs and update their URIs
        for(uint256 i = 0; i < members[_memberAddress].ownedBadgeTokenIds.length(); i++) {
            uint256 tokenId = members[_memberAddress].ownedBadgeTokenIds.at(i);
            // Re-generate URI based on current stats and update the NFT
            achievementBadgeNFT.updateBadgeURI(tokenId, generateBadgeURI(tokenId, members[_memberAddress].reputation, members[_memberAddress].stakedAmount, currentTier));
        }
    }

    function getMemberReputation(address _memberAddress) public view returns (int256) {
        require(_guildMembers.contains(_memberAddress), "ACIG: Member not found");
        return members[_memberAddress].reputation;
    }

    function getMemberTier(address _memberAddress) public view returns (MemberTier) {
        require(_guildMembers.contains(_memberAddress), "ACIG: Not a guild member");
        return _getMemberTierLogic(members[_memberAddress].reputation, members[_memberAddress].stakedAmount);
    }

    // Helper to calculate tier based on raw reputation and stake, reusable internally
    function _getMemberTierLogic(int256 _reputation, uint256 _stakedAmount) internal pure returns (MemberTier) {
        if (_reputation >= 1000 && _stakedAmount >= 10 ether) {
            return MemberTier.Elder;
        } else if (_reputation >= 500 && _stakedAmount >= 5 ether) {
            return MemberTier.Strategist;
        } else if (_reputation >= 200 && _stakedAmount >= 2 ether) {
            return MemberTier.Contributor;
        } else {
            return MemberTier.Novice;
        }
    }

    // --- III. Dynamic Investment Strategies (DIS) Management ---

    function proposeStrategyParameterChange(
        bytes32 _parameterNameHash, // Use keccak256(abi.encodePacked("parameterName"))
        bytes calldata _newValue,    // abi.encode() the new value
        string calldata _description
    ) external onlyMember whenNotPaused returns (uint256 proposalId) {
        require(_parameterNameHash != bytes32(0), "ACIG: Invalid parameter name hash");
        require(bytes(_description).length > 0, "ACIG: Description cannot be empty");

        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            targetKey: _parameterNameHash,
            newValue: _newValue,
            description: _description,
            proposer: _msgSender(),
            voteCountFor: 0,
            voteCountAgainst: 0,
            // Quorum based on total sum of all members' reputation
            quorumRequiredReputation: _calculateTotalReputation() * DEFAULT_QUORUM_PERCENTAGE_REPUTATION / 100,
            votingEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            state: ProposalState.Pending
        });

        proposals[proposalId].state = ProposalState.Active; // Ready for voting immediately
        emit StrategyParameterChangeProposed(proposalId, _parameterNameHash, _newValue, _msgSender());
        return proposalId;
    }

    function voteOnStrategyProposal(uint256 _proposalId, bool _support) external onlyMember whenNotPaused proposalExists(_proposalId) proposalState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.hasVoted[_msgSender()], "ACIG: Already voted on this proposal");
        require(block.timestamp < proposal.votingEndTime, "ACIG: Voting period has ended");

        // Votes are weighted by the member's current reputation
        if (_support) {
            proposal.voteCountFor += uint256(members[_msgSender()].reputation);
        } else {
            proposal.voteCountAgainst += uint256(members[_msgSender()].reputation);
        }
        proposal.hasVoted[_msgSender()] = true;

        emit StrategyParameterVoteCast(_proposalId, _msgSender(), _support);
    }

    // Callable by anyone after the voting period ends and proposal passes
    function executeApprovedStrategyChange(uint256 _proposalId) external whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "ACIG: Proposal not active");
        require(block.timestamp >= proposal.votingEndTime, "ACIG: Voting period not ended");

        if (proposal.voteCountFor > proposal.voteCountAgainst && proposal.voteCountFor >= proposal.quorumRequiredReputation) {
            // Apply the new parameter value based on its hash
            if (proposal.targetKey == keccak256(abi.encodePacked("minRiskTolerance"))) {
                currentStrategyParameters.minRiskTolerance = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.targetKey == keccak256(abi.encodePacked("maxAllocationPercentage"))) {
                currentStrategyParameters.maxAllocationPercentage = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.targetKey == keccak256(abi.encodePacked("rebalanceThresholdBps"))) {
                currentStrategyParameters.rebalanceThresholdBps = abi.decode(proposal.newValue, (uint256));
            } else if (proposal.targetKey == keccak256(abi.encodePacked("minSentimentScoreRequirement"))) {
                currentStrategyParameters.minSentimentScoreRequirement = abi.decode(proposal.newValue, (int256));
            } else if (proposal.targetKey == keccak256(abi.encodePacked("yieldDistributionCutBps"))) {
                currentStrategyParameters.yieldDistributionCutBps = abi.decode(proposal.newValue, (uint256));
            } else {
                revert("ACIG: Unknown strategy parameter target");
            }
            proposal.state = ProposalState.Executed;
            emit StrategyParameterChangeExecuted(_proposalId, proposal.targetKey, proposal.newValue);
        } else {
            proposal.state = ProposalState.Failed;
            // Optionally: Penalize the proposer's reputation if proposal fails significantly.
        }
    }

    // Helper to calculate total reputation for quorum checks
    function _calculateTotalReputation() internal view returns (uint256) {
        uint256 totalRep = 0;
        for (uint256 i = 0; i < _guildMembers.length(); i++) {
            totalRep += uint256(members[_guildMembers.at(i)].reputation);
        }
        return totalRep;
    }

    // --- IV. Funds & Yield Management ---

    function registerSupportedToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "ACIG: Cannot register null address");
        require(!_supportedTokens.contains(_tokenAddress), "ACIG: Token already supported");
        _supportedTokens.add(_tokenAddress);
        emit SupportedTokenAdded(_tokenAddress);
    }

    function removeSupportedToken(address _tokenAddress) external onlyOwner {
        require(_supportedTokens.contains(_tokenAddress), "ACIG: Token not supported");
        require(totalAmountOfSupportedToken[_tokenAddress] == 0, "ACIG: Cannot remove token with funds still locked");
        _supportedTokens.remove(_tokenAddress);
        emit SupportedTokenRemoved(_tokenAddress);
    }

    function depositIntoActiveStrategy(address _tokenAddress, uint256 _amount) external payable whenNotPaused {
        require(_supportedTokens.contains(_tokenAddress), "ACIG: Token not supported for deposit");
        require(_amount > 0, "ACIG: Deposit amount must be greater than zero");

        if (_tokenAddress == address(0x0)) { // Native ETH
            require(msg.value == _amount, "ACIG: ETH amount mismatch");
            // ETH is automatically received by the contract
        } else {
            require(msg.value == 0, "ACIG: Do not send ETH with ERC20 deposit");
            IERC20(_tokenAddress).transferFrom(_msgSender(), address(this), _amount);
        }

        // Update guild's TVL (simplified: assumes 1:1 value for all tokens)
        activeStrategyMetrics.totalDepositedValue += _amount;
        totalAmountOfSupportedToken[_tokenAddress] += _amount;
        members[_msgSender()].stakedAmount += _amount; // Add to member's "effective stake"

        emit FundsDeposited(_msgSender(), _tokenAddress, _amount);
    }

    function withdrawFromActiveStrategy(address _tokenAddress, uint256 _amount) external onlyMember whenNotPaused {
        require(_supportedTokens.contains(_tokenAddress), "ACIG: Token not supported for withdrawal");
        require(_amount > 0, "ACIG: Withdrawal amount must be greater than zero");
        require(members[_msgSender()].stakedAmount >= _amount, "ACIG: Insufficient member staked value");

        // In a real system, this would involve calculating member's share of profits/losses
        // and withdrawing from actual external vaults/pools.
        require(totalAmountOfSupportedToken[_tokenAddress] >= _amount, "ACIG: Guild does not hold enough of this token");

        activeStrategyMetrics.totalDepositedValue -= _amount;
        totalAmountOfSupportedToken[_tokenAddress] -= _amount;
        members[_msgSender()].stakedAmount -= _amount; // Reduce member's effective stake

        if (_tokenAddress == address(0x0)) { // Native ETH
            (bool success, ) = payable(_msgSender()).call{value: _amount}("");
            require(success, "ACIG: ETH withdrawal failed");
        } else {
            IERC20(_tokenAddress).transfer(_msgSender(), _amount);
        }
        emit FundsWithdrawn(_msgSender(), _tokenAddress, _amount);
    }

    // This function is the core of the "Adaptive Investment Strategy."
    // It would be called periodically by a trusted keeper service.
    // **Highly simplified simulation**; real trading logic would be complex and gas-intensive.
    function triggerStrategyExecution() external onlyOwner whenNotPaused { // Callable by keeper service or owner
        uint256 currentTVLsnapshot = activeStrategyMetrics.totalDepositedValue;

        // Simulate market interaction, yield generation, or rebalancing based on parameters and sentiment
        uint256 simulatedYield = 0;
        if (activeStrategyMetrics.lastSentimentScore > currentStrategyParameters.minSentimentScoreRequirement) {
            // Example: Positive sentiment allows for higher risk, leading to simulated yield
            simulatedYield = currentTVLsnapshot / 1000; // 0.1% yield for example
            activeStrategyMetrics.totalDepositedValue += simulatedYield; // Guild's TVL increases
            // In a real scenario, actual tokens would be acquired.
            // totalAmountOfSupportedToken[address(0x0)] += simulatedYield; // Assume yield is in ETH
        } else {
            // Example: Negative sentiment or low risk tolerance leads to rebalancing/minor loss
            // Simulate a small rebalance cost or slight reduction in value
            activeStrategyMetrics.totalDepositedValue = activeStrategyMetrics.totalDepositedValue * (10000 - currentStrategyParameters.rebalanceThresholdBps) / 10000;
        }

        activeStrategyMetrics.lastExecutionTime = block.timestamp;
        emit StrategyExecuted(currentTVLsnapshot, activeStrategyMetrics.lastSentimentScore, activeStrategyMetrics.totalDepositedValue);
    }

    function distributeYieldToMembers() external onlyOwner whenNotPaused { // Callable periodically
        // Calculate the profit since the last distribution/snapshot
        uint256 currentEstimatedTVL = activeStrategyMetrics.totalDepositedValue;
        uint256 totalProfit = 0;
        if (currentEstimatedTVL > activeStrategyMetrics.lastProfitSnapshot) {
            totalProfit = currentEstimatedTVL - activeStrategyMetrics.lastProfitSnapshot;
        } else {
            emit YieldDistributed(0, 0, 0); // No profit to distribute
            return;
        }

        uint256 guildCut = totalProfit * (10000 - currentStrategyParameters.yieldDistributionCutBps) / 10000;
        uint256 membersShare = totalProfit - guildCut;

        uint256 totalReputation = _calculateTotalReputation();
        
        if (totalReputation == 0) {
            emit YieldDistributed(totalProfit, 0, guildCut);
            activeStrategyMetrics.lastProfitSnapshot = currentEstimatedTVL; // Update snapshot
            return;
        }

        // Distribute to members based on their reputation (weighted)
        for (uint256 i = 0; i < _guildMembers.length(); i++) {
            address memberAddress = _guildMembers.at(i);
            Member storage member = members[memberAddress];
            // Calculate member's proportional share based on their reputation weight
            uint256 memberShare = (membersShare * uint256(member.reputation)) / totalReputation;
            
            // For simplicity, we add the yield to their stakedAmount in this conceptual contract.
            // In a real system, actual tokens would be transferred to members.
            member.stakedAmount += memberShare;
            // Note: This reduces the conceptual `membersShare` from the `totalDepositedValue` in the simulation.
            // In reality, tokens are moved from the guild's control to members.
            activeStrategyMetrics.totalDepositedValue -= memberShare;
        }

        // Collect protocol fees
        uint256 protocolFees = guildCut * BASE_PROTOCOL_FEE_BPS / 10000;
        // The remaining `guildCut - protocolFees` can be considered part of the guild's treasury/reserves
        
        // In a real system, transfer actual tokens to feeRecipient
        // (bool success, ) = payable(feeRecipient).call{value: protocolFees}("");
        // require(success, "ACIG: Fee transfer failed");
        
        // Update TVL to reflect fees removed (conceptually)
        activeStrategyMetrics.totalDepositedValue -= protocolFees;
        activeStrategyMetrics.totalDepositedValue -= (guildCut - protocolFees); // Remaining guild cut to treasury

        activeStrategyMetrics.lastProfitSnapshot = currentEstimatedTVL; // Reset snapshot for next cycle
        emit YieldDistributed(totalProfit, membersShare, protocolFees);
    }

    function collectProtocolFees() external onlyOwner whenNotPaused {
        // This function would retrieve accumulated actual tokens from the strategy vault
        // that represent the protocol's share of profits and transfer them to `feeRecipient`.
        // The `distributeYieldToMembers` function conceptually handles this.
        // For a full implementation, you'd track `_pendingProtocolFees` and then withdraw them.
    }

    function getGuildTVL() public view returns (uint256) {
        return activeStrategyMetrics.totalDepositedValue;
    }

    function getGuildTokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == address(0x0)) { // Native ETH
            return address(this).balance;
        } else {
            return IERC20(_tokenAddress).balanceOf(address(this));
        }
    }

    // --- V. Oracle Integration (Simulated AI/Sentiment) ---

    // Requests updated market sentiment from the oracle
    function requestMarketSentimentUpdate() external onlyOwner whenNotPaused returns (bytes32 requestId) {
        // In a real Chainlink setup, this would emit an event and potentially cost LINK.
        // We pass `address(this)` so the oracle knows which contract to call back.
        requestId = marketSentimentOracle.requestSentiment(address(this));
        pendingSentimentRequests[requestId] = true;
        emit MarketSentimentRequested(requestId);
        return requestId;
    }

    // This function is intended to be called by the `marketSentimentOracle` contract as a callback
    function fulfillMarketSentimentUpdate(bytes32 _requestId, int256 _sentimentScore) external {
        require(msg.sender == address(marketSentimentOracle), "ACIG: Only oracle can fulfill");
        require(pendingSentimentRequests[_requestId], "ACIG: Unknown or already fulfilled request");

        pendingSentimentRequests[_requestId] = false; // Mark request as fulfilled
        activeStrategyMetrics.lastSentimentScore = _sentimentScore;

        emit MarketSentimentFulfilled(_requestId, _sentimentScore);

        // Optional: Trigger a strategy re-evaluation or execution based on new sentiment
        // triggerStrategyExecution(); // Auto-trigger for dynamic response
    }

    // --- VI. Dynamic Achievement Badges (NFTs) ---

    function claimAchievementBadge(uint256 _badgeId) external onlyMember whenNotPaused returns (uint256 tokenId) {
        Member storage member = members[_msgSender()];
        
        // Define eligibility for different badges (examples):
        if (_badgeId == 1) { // "Novice Contributor" badge
            require(member.reputation >= INITIAL_REPUTATION, "ACIG: Not eligible for initial badge");
            require(!member.ownedBadgeTokenIds.contains(101), "ACIG: Novice badge already claimed"); // Using a distinct ID for this badge instance
            tokenId = achievementBadgeNFT.mintBadge(_msgSender(), _badgeId, generateBadgeURI(_badgeId, member.reputation, member.stakedAmount, _getMemberTierLogic(member.reputation, member.stakedAmount)));
            member.ownedBadgeTokenIds.add(tokenId); // Store the actual token ID of the minted NFT
            emit AchievementBadgeClaimed(_msgSender(), _badgeId, tokenId);
        } else if (_badgeId == 2) { // "Strategist" tier badge
            require(_getMemberTierLogic(member.reputation, member.stakedAmount) >= MemberTier.Strategist, "ACIG: Not yet a Strategist");
            require(!member.ownedBadgeTokenIds.contains(202), "ACIG: Strategist badge already claimed"); // Another distinct ID
            tokenId = achievementBadgeNFT.mintBadge(_msgSender(), _badgeId, generateBadgeURI(_badgeId, member.reputation, member.stakedAmount, _getMemberTierLogic(member.reputation, member.stakedAmount)));
            member.ownedBadgeTokenIds.add(tokenId);
            emit AchievementBadgeClaimed(_msgSender(), _badgeId, tokenId);
        } else {
            revert("ACIG: Invalid badge ID or eligibility not met");
        }
        // In a real system, you might have a mapping of _badgeId to its specific token ID,
        // or a more complex system to manage multiple badge types per member.
        return tokenId;
    }

    // Internal helper function to generate dynamic URI for NFT metadata
    function generateBadgeURI(uint256 _badgeId, int256 _reputation, uint256 _stakedAmount, MemberTier _tier) internal pure returns (string memory) {
        // This is a placeholder. In reality, this URI would point to an API endpoint
        // or a dynamically generated JSON file on IPFS/Arweave.
        // The JSON would contain the metadata (name, description, image, attributes)
        // which changes based on the member's current reputation, stake, and tier.
        
        string memory tierName;
        if (_tier == MemberTier.Novice) tierName = "Novice";
        else if (_tier == MemberTier.Contributor) tierName = "Contributor";
        else if (_tier == MemberTier.Strategist) tierName = "Strategist";
        else if (_tier == MemberTier.Elder) tierName = "Elder";

        // Example: Base URI points to a service that dynamically generates metadata
        string memory baseURI = "https://acig.io/nft/metadata/";
        string memory dynamicPart = string(abi.encodePacked(
            Strings.toString(_badgeId),
            "/reputation_", Strings.toString(_reputation),
            "/stake_", Strings.toString(_stakedAmount),
            "/tier_", tierName
        ));
        return string(abi.encodePacked(baseURI, dynamicPart));
    }

    // This function should be called by the `adjustReputation` function or a keeper service
    // when a member's reputation or a linked metric (like staked amount) changes.
    // It iterates through all badges owned by the member and updates their metadata URI.
    function updateAchievementBadgeMetadata(address _memberAddress) external onlyOwner { // Callable by owner, or internal trigger
        require(_guildMembers.contains(_memberAddress), "ACIG: Member not found");
        Member storage member = members[_memberAddress];
        MemberTier currentTier = _getMemberTierLogic(member.reputation, member.stakedAmount);

        for(uint256 i = 0; i < member.ownedBadgeTokenIds.length(); i++) {
            uint256 tokenId = member.ownedBadgeTokenIds.at(i);
            // Re-generate URI based on current stats
            achievementBadgeNFT.updateBadgeURI(tokenId, generateBadgeURI(0, member.reputation, member.stakedAmount, currentTier)); // 0 for generic badge ID logic
            emit AchievementBadgeMetadataUpdated(tokenId, achievementBadgeNFT.tokenURI(tokenId));
        }
    }


    // --- VII. Guild Governance & System Parameters ---

    function proposeGuildParameterChange(
        string calldata _parameterName,
        bytes calldata _newValue,
        string calldata _description
    ) external onlyMember whenNotPaused returns (uint256 proposalId) {
        require(bytes(_parameterName).length > 0, "ACIG: Parameter name cannot be empty");
        require(bytes(_description).length > 0, "ACIG: Description cannot be empty");

        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            targetKey: keccak256(abi.encodePacked(_parameterName)),
            newValue: _newValue,
            description: _description,
            proposer: _msgSender(),
            voteCountFor: 0,
            voteCountAgainst: 0,
            quorumRequiredReputation: _calculateTotalReputation() * DEFAULT_QUORUM_PERCENTAGE_REPUTATION / 100,
            votingEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            state: ProposalState.Pending
        });
        proposals[proposalId].state = ProposalState.Active;
        emit GuildParameterChangeProposed(proposalId, _parameterName, _newValue, _msgSender());
        return proposalId;
    }

    function voteOnGuildParameterChange(uint256 _proposalId, bool _support) external onlyMember whenNotPaused proposalExists(_proposalId) proposalState(_proposalId, ProposalState.Active) {
        // Logic identical to voteOnStrategyProposal, using member's reputation
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.hasVoted[_msgSender()], "ACIG: Already voted on this proposal");
        require(block.timestamp < proposal.votingEndTime, "ACIG: Voting period has ended");

        if (_support) {
            proposal.voteCountFor += uint256(members[_msgSender()].reputation);
        } else {
            proposal.voteCountAgainst += uint256(members[_msgSender()].reputation);
        }
        proposal.hasVoted[_msgSender()] = true;
        emit GuildParameterVoteCast(_proposalId, _msgSender(), _support);
    }

    // Callable by anyone after the voting period ends and proposal passes
    function executeApprovedGuildParameterChange(uint256 _proposalId) external whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "ACIG: Proposal not active");
        require(block.timestamp >= proposal.votingEndTime, "ACIG: Voting period not ended");

        if (proposal.voteCountFor > proposal.voteCountAgainst && proposal.voteCountFor >= proposal.quorumRequiredReputation) {
            // Apply guild parameter changes based on the targetKey
            if (proposal.targetKey == keccak256(abi.encodePacked("MIN_STAKE_AMOUNT_UPDATE"))) { // Example: updating a MIN_STAKE_AMOUNT state var
                // MIN_STAKE_AMOUNT = abi.decode(proposal.newValue, (uint256)); // If it were a mutable state var
            } else if (proposal.targetKey == keccak256(abi.encodePacked("BASE_PROTOCOL_FEE_BPS_UPDATE"))) {
                // BASE_PROTOCOL_FEE_BPS = abi.decode(proposal.newValue, (uint256)); // If it were a mutable state var
            } else if (proposal.targetKey == keccak256(abi.encodePacked("FEE_RECIPIENT_UPDATE"))) {
                feeRecipient = abi.decode(proposal.newValue, (address));
            } else {
                revert("ACIG: Unknown guild parameter target");
            }
            proposal.state = ProposalState.Executed;
            emit GuildParameterChangeExecuted(_proposalId, "GeneralParameter", proposal.newValue); // Generic name for event
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    // --- VIII. Emergency & Utility Functions ---

    function getStrategyPerformanceMetrics() public view returns (uint256 currentTVL, uint256 lastExecutionTime, int256 lastSentimentScore, uint256 lastProfitSnapshot) {
        return (activeStrategyMetrics.totalDepositedValue, activeStrategyMetrics.lastExecutionTime, activeStrategyMetrics.lastSentimentScore, activeStrategyMetrics.lastProfitSnapshot);
    }

    // Fallback and Receive functions for native ETH
    receive() external payable {
        // Allows the contract to receive raw ETH.
        // Specific functions like `joinGuild` and `depositIntoActiveStrategy` should be used for structured deposits.
        // Any ETH sent without a function call will simply increase contract balance.
    }

    fallback() external payable {
        // Fallback function for calls to non-existent functions.
        // Similar to `receive()`, it can accept ETH.
    }
}


// --- Helper Contracts (for compilation and conceptual completeness) ---

// MyAchievementBadgeNFT: A simplified ERC721 contract to simulate dynamic NFT behavior.
// In a real project, this would be a full-fledged ERC721 contract (e.g., OpenZeppelin's ERC721)
// with custom logic for metadata generation and potentially IPFS integration.
contract MyAchievementBadgeNFT is IAchievementBadgeNFT, Ownable {
    using Strings for uint256; // For converting uint256 to string for URIs
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) private _owners; // Simple owner tracking
    mapping(address => uint256) private _balances; // Simple balance tracking
    uint256 private _nextTokenId; // Counter for unique token IDs

    // ERC721 events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor() {
        // Constructor is empty as `Ownable` sets the deployer as owner.
        // The ACIG contract will be granted minter/updater rights.
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // Allows the owner (ACIG contract in this setup) to mint badges
    function mintBadge(address to, uint256 badgeId, string calldata initialURI) external returns (uint256) {
        require(msg.sender == owner(), "MyNFT: Only contract owner can mint");
        require(to != address(0), "MyNFT: Mint to zero address");

        uint256 tokenId = _nextTokenId++; // Assign a new unique token ID
        _owners[tokenId] = to;
        _balances[to]++;
        _tokenURIs[tokenId] = initialURI; // Set the initial metadata URI

        emit Transfer(address(0), to, tokenId); // ERC721 Transfer event for minting
        return tokenId;
    }

    // Allows the owner (ACIG contract) to update the metadata URI of a badge
    function updateBadgeURI(uint256 tokenId, string calldata newURI) external override {
        require(msg.sender == owner(), "MyNFT: Only contract owner can update URI");
        require(_exists(tokenId), "MyNFT: Token ID does not exist");
        _tokenURIs[tokenId] = newURI;
        // A specific event for metadata updates could be useful, e.g., `event MetadataUpdate(uint256 _tokenId);`
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "MyNFT: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "MyNFT: owner query for nonexistent token");
        return _owners[tokenId];
    }

    function balanceOf(address owner_) public view override returns (uint256) {
        require(owner_ != address(0), "MyNFT: balance query for zero address");
        return _balances[owner_];
    }
    
    // --- ERC721 Required functions (stubbed for compilation, not functional for transfers) ---
    // In a production environment, these would be fully implemented using OpenZeppelin's ERC721.
    function approve(address to, uint256 tokenId) public override { /* stub */ emit Approval(address(0), address(0), 0); }
    function getApproved(uint256 tokenId) public view override returns (address) { return address(0); }
    function setApprovalForAll(address operator, bool approved) public override { /* stub */ emit ApprovalForAll(address(0), address(0), false); }
    function isApprovedForAll(address owner_, address operator) public view override returns (bool) { return false; }
    function transferFrom(address from, address to, uint256 tokenId) public override { /* stub */ emit Transfer(address(0), address(0), 0); }
    function safeTransferFrom(address from, address to, uint256 tokenId) public override { /* stub */ emit Transfer(address(0), address(0), 0); }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override { /* stub */ emit Transfer(address(0), address(0), 0); }
}

// MyMarketSentimentOracle: A minimal oracle stub for demonstration purposes.
// In a real DApp, this would be a Chainlink oracle contract or a custom decentralized oracle network.
contract MyMarketSentimentOracle is IMarketSentimentOracle, Ownable {
    mapping(bytes32 => bool) public pendingRequests;
    mapping(bytes32 => address) public requestCallbackAddress; // Address of the contract to callback
    mapping(bytes32 => address) public requestSender; // Who initiated the request (for logging)
    mapping(bytes32 => uint256) public requestTime; // When the request was made

    constructor() {}

    // Callable by a requesting contract (e.g., ACIG) to ask for sentiment data.
    // In Chainlink, this would involve a `request` function and a `bytes32 _jobId`.
    function requestSentiment(address callbackContract) external onlyOwner returns (bytes32 requestId) {
        require(callbackContract != address(0), "Oracle: Callback address cannot be zero");
        requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, callbackContract, block.difficulty));
        pendingRequests[requestId] = true;
        requestCallbackAddress[requestId] = callbackContract;
        requestSender[requestId] = msg.sender;
        requestTime[requestId] = block.timestamp;
        emit SentimentRequested(requestId);
    }

    // This function simulates the oracle fulfilling the request by sending data back.
    // In a real oracle, this would be called by the oracle node or an authorized relayer.
    // For this example, only the owner can call it to simulate.
    function fulfill(bytes32 requestId, int256 sentimentScore) external override {
        require(pendingRequests[requestId], "Oracle: Request not pending or does not exist");
        require(msg.sender == owner(), "Oracle: Only owner can fulfill for simulation"); // Simulate oracle node auth

        pendingRequests[requestId] = false; // Mark as fulfilled

        // Call the callback function on the requesting contract (ACIG)
        // This dynamic call is crucial for the oracle pattern.
        bytes memory payload = abi.encodeWithSelector(
            AdaptiveCollectiveIntelligenceGuild.fulfillMarketSentimentUpdate.selector,
            requestId,
            sentimentScore
        );
        (bool success, ) = requestCallbackAddress[requestId].call(payload);
        require(success, "Oracle: Callback to requesting contract failed");

        emit SentimentFulfilled(requestId, sentimentScore);
    }
}
```