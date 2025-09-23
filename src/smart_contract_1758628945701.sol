Here's a Solidity smart contract named `AetheriumPredictiveCollective` that incorporates advanced concepts like dynamic reputation, meritocratic governance, and predictive capital allocation. It aims to be creative, trendy, and distinct from typical open-source projects by tightly integrating these features into a cohesive system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Outline and Function Summary:
//
// The AetheriumPredictiveCollective is a decentralized autonomous collective designed for meritocratic
// capital allocation. Members stake a "Predictive Token" to gain initial influence. This influence,
// combined with a dynamic "Reputation Score" derived from their predictive accuracy on market events,
// dictates their true voting power. The collective proposes and votes on prediction markets,
// and their accuracy on these markets directly updates their reputation. Furthermore, the collective
// manages a treasury, proposing and voting on strategies to allocate these funds based on their
// collective predictions. Successful allocations boost the collective's reputation and potentially
// member rewards, while unsuccessful ones can diminish it. This creates a feedback loop where
// predictive skill directly translates to influence over capital.
//
// ---
//
// **I. Core Infrastructure & Access Control**
// 1.  `constructor`: Initializes the contract, setting the owner, the Predictive Token address, and initial parameters.
// 2.  `setPredictiveToken`: (Owner) Sets the ERC20 token used for staking and influence.
// 3.  `setMinStake`: (Owner) Sets the minimum amount of Predictive Tokens required to become a member.
// 4.  `setUnstakeCooldownDays`: (Owner) Sets the cooldown period for unstaking requests.
// 5.  `setPredictionMarketProposalFee`: (Owner) Sets the fee required to propose a new prediction market.
// 6.  `pause`: (Owner) Pauses the contract in case of emergencies, preventing most state-changing operations.
// 7.  `unpause`: (Owner) Unpauses the contract.
// 8.  `withdrawLostERC20`: (Owner) Allows the owner to recover accidentally sent ERC20 tokens (excluding the Predictive Token).
//
// **II. Membership & Staking**
// 9.  `registerMember`: Allows a user to become a member by staking the minimum required Predictive Tokens.
// 10. `stakeForInfluence`: Allows an existing member to increase their stake, thereby increasing their base influence.
// 11. `requestUnstake`: Allows a member to initiate an unstake request, starting a cooldown period.
// 12. `executeUnstake`: Allows a member to complete an unstake request after the cooldown period has passed.
// 13. `delegateInfluence`: Allows a member to delegate their influence (stake + reputation) to another member.
// 14. `undelegateInfluence`: Allows a member to revoke their influence delegation.
//
// **III. Prediction Market Lifecycle**
// 15. `proposePredictionMarket`: (Member) Proposes a new prediction market, paying a fee.
// 16. `voteOnPredictionMarketProposal`: (Member) Votes on whether to approve a proposed prediction market.
// 17. `submitPrediction`: (Member) Submits their individual prediction for an approved market.
// 18. `finalizePredictionMarket`: (Owner/Oracle) Finalizes a prediction market with its actual outcome. This relies on an off-chain oracle or trusted party.
// 19. `claimReputationUpdate`: (Member) After a market is finalized, a member can call this to update their reputation based on their prediction accuracy.
// 20. `disputePredictionMarket`: (Member) Initiates a dispute for a finalized market, requiring further review (simplified for this contract).
//
// **IV. Treasury & Capital Allocation**
// 21. `proposeCapitalAllocationStrategy`: (Member) Proposes a strategy for allocating treasury funds based on collective predictions or insights.
// 22. `voteOnCapitalAllocationStrategy`: (Member) Votes on a proposed capital allocation strategy.
// 23. `executeCapitalAllocation`: (Owner/Governance) Executes an approved capital allocation strategy, transferring treasury funds to a target address.
// 24. `recordInvestmentReturn`: (Owner/Governance) Records the outcome (profit/loss) of an executed capital allocation, affecting the proposer's reputation and potentially the collective's standing.
//
// **V. View Functions & Metrics**
// 25. `getMemberInfluence`: Retrieves the calculated influence score for a given member (based on stake and reputation).
// 26. `getPredictionMarketDetails`: Retrieves detailed information about a specific prediction market.
// 27. `getCapitalAllocationStrategyDetails`: Retrieves detailed information about a specific capital allocation strategy.
//
// ---

contract AetheriumPredictiveCollective is Ownable, Pausable {

    // --- Events ---
    event MemberRegistered(address indexed member, uint256 stakedAmount);
    event Staked(address indexed member, uint256 amount);
    event UnstakeRequested(address indexed member, uint256 requestId, uint256 amount, uint256 cooldownEnd);
    event Unstaked(address indexed member, uint256 requestId, uint256 amount);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee);
    event InfluenceUndelegated(address indexed delegator);
    event ReputationUpdated(address indexed member, uint256 marketId, int256 reputationChange, int256 newReputation);

    event PredictionMarketProposed(uint256 indexed marketId, address indexed proposer, string title, uint256 deadline);
    event PredictionMarketProposalVoted(uint256 indexed marketId, address indexed voter, bool approved, uint256 influenceUsed);
    event PredictionMarketApproved(uint256 indexed marketId);
    event PredictionSubmitted(uint256 indexed marketId, address indexed member, bool predictedOutcome);
    event PredictionMarketFinalized(uint256 indexed marketId, bool actualOutcome);
    event PredictionMarketDisputed(uint256 indexed marketId, address indexed disputer);

    event CapitalAllocationStrategyProposed(uint256 indexed strategyId, address indexed proposer, string description, address treasuryToken, uint256 amount);
    event CapitalAllocationStrategyVoted(uint256 indexed strategyId, address indexed voter, bool approved, uint256 influenceUsed);
    event CapitalAllocationStrategyApproved(uint256 indexed strategyId);
    event CapitalAllocationExecuted(uint256 indexed strategyId, address indexed targetAddress, address treasuryToken, uint256 amount);
    event InvestmentReturnRecorded(uint256 indexed strategyId, address indexed treasuryToken, uint256 returnAmount, bool isProfit);

    // --- Structures ---

    struct Member {
        uint256 stake;             // Amount of Predictive Tokens staked by the member
        int256 reputationScore;    // Score based on predictive accuracy, can be negative
        address delegatedTo;       // Address of the member to whom this member has delegated influence
        uint256 lastStakeChange;   // Timestamp of the last stake change (for reputation recalibration logic, if any)
        bool isMember;             // True if the address is a registered member
    }

    struct UnstakeRequest {
        uint256 amount;
        uint256 cooldownEnd;
        bool exists;
    }

    enum MarketStatus { Proposed, Approved, Finalized, Disputed }

    struct PredictionMarket {
        uint256 id;
        address proposer;
        string title;
        string description;
        string resolutionSource;   // URL or description of where to find the actual outcome
        uint256 deadline;          // Timestamp by which predictions must be submitted
        MarketStatus status;
        bool actualOutcome;        // True/False outcome (e.g., "price above X" -> True)
        uint256 proposalVotesFor;
        uint256 proposalVotesAgainst;
        uint256 disputeCount;      // How many times this market has been disputed
        bool exists;
    }

    enum StrategyStatus { Proposed, Approved, Executed, Rejected }

    struct CapitalAllocationStrategy {
        uint256 id;
        address proposer;
        string description;
        address targetAddress;      // The contract/address to send funds to
        address treasuryToken;      // ERC20 token to be allocated
        uint256 amount;
        StrategyStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        bool exists;
    }

    // --- State Variables ---

    IERC20 public predictiveToken;
    uint256 public minStake;
    uint256 public unstakeCooldownDays;
    uint256 public predictionMarketProposalFee;

    uint256 public nextPredictionMarketId;
    uint256 public nextCapitalAllocationStrategyId;

    mapping(address => Member) public members;
    mapping(address => mapping(uint256 => UnstakeRequest)) public unstakeRequests; // member => requestId => request
    mapping(address => uint256) public nextUnstakeRequestId;

    mapping(uint256 => PredictionMarket) public predictionMarkets;
    mapping(uint256 => mapping(address => bool)) public memberSubmittedPrediction; // marketId => member => hasSubmitted
    mapping(uint256 => mapping(address => bool)) public memberPredictedOutcome;    // marketId => member => predictedOutcome (true/false)
    mapping(uint256 => mapping(address => bool)) public hasVotedOnMarketProposal;  // marketId => member => hasVoted
    mapping(uint256 => mapping(address => bool)) public hasVotedOnStrategy;        // strategyId => member => hasVoted

    mapping(uint256 => mapping(address => bool)) public reputationUpdatedForMarket; // marketId => member => hasReputationBeenUpdated

    mapping(uint256 => CapitalAllocationStrategy) public capitalAllocationStrategies;

    // Reputation impact parameters
    int256 public constant INITIAL_REPUTATION = 1000; // Starting reputation for new members
    uint256 public constant REPUTATION_MULTIPLIER = 1; // How much reputation scales influence (e.g., 1 reputation point = 1 token equivalent influence)
    uint256 public constant CORRECT_PREDICTION_REPUTATION_GAIN = 50;
    int256 public constant INCORRECT_PREDICTION_REPUTATION_LOSS = -25;
    uint256 public constant PROPOSER_PROFIT_REPUTATION_GAIN = 10;
    // int256 public constant PROPOSER_LOSS_REPUTATION_LOSS = -5; // Example, currently commented out

    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender].isMember, "APC: Caller is not a registered member");
        _;
    }

    modifier onlyActivePredictionMarket(uint256 _marketId) {
        require(predictionMarkets[_marketId].exists, "APC: Prediction market does not exist");
        require(predictionMarkets[_marketId].status == MarketStatus.Approved, "APC: Prediction market is not active");
        require(block.timestamp <= predictionMarkets[_marketId].deadline, "APC: Prediction market deadline passed");
        _;
    }

    // --- Constructor ---

    constructor(address _predictiveToken, uint256 _minStake, uint256 _unstakeCooldownDays, uint256 _predictionMarketProposalFee) Ownable(msg.sender) {
        require(_predictiveToken != address(0), "APC: Predictive Token address cannot be zero");
        predictiveToken = IERC20(_predictiveToken);
        minStake = _minStake;
        unstakeCooldownDays = _unstakeCooldownDays;
        predictionMarketProposalFee = _predictionMarketProposalFee;
        nextPredictionMarketId = 1;
        nextCapitalAllocationStrategyId = 1;
    }

    // --- I. Core Infrastructure & Access Control ---

    function setPredictiveToken(address _newToken) external onlyOwner {
        require(_newToken != address(0), "APC: New Predictive Token address cannot be zero");
        predictiveToken = IERC20(_newToken);
    }

    function setMinStake(uint256 _newMinStake) external onlyOwner {
        require(_newMinStake > 0, "APC: Min stake must be greater than zero");
        minStake = _newMinStake;
    }

    function setUnstakeCooldownDays(uint256 _newCooldownDays) external onlyOwner {
        unstakeCooldownDays = _newCooldownDays;
    }

    function setPredictionMarketProposalFee(uint256 _newFee) external onlyOwner {
        predictionMarketProposalFee = _newFee;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawLostERC20(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        require(_tokenAddress != address(predictiveToken), "APC: Cannot withdraw predictive token (use unstake mechanism)");
        require(_tokenAddress != address(0), "APC: Token address cannot be zero");
        require(_to != address(0), "APC: Recipient address cannot be zero");
        IERC20(_tokenAddress).transfer(_to, _amount);
    }

    // --- II. Membership & Staking ---

    function registerMember() external whenNotPaused {
        require(!members[msg.sender].isMember, "APC: Already a registered member");
        require(msg.sender != address(0), "APC: Invalid sender");

        // Requires msg.sender to have approved this contract to spend minStake
        require(predictiveToken.transferFrom(msg.sender, address(this), minStake), "APC: Token transfer failed for min stake. Ensure sufficient allowance.");

        members[msg.sender] = Member({
            stake: minStake,
            reputationScore: INITIAL_REPUTATION,
            delegatedTo: address(0),
            lastStakeChange: block.timestamp,
            isMember: true
        });

        emit MemberRegistered(msg.sender, minStake);
    }

    function stakeForInfluence(uint256 _amount) external whenNotPaused onlyMember {
        require(_amount > 0, "APC: Stake amount must be greater than zero");
        // Requires msg.sender to have approved this contract to spend _amount
        require(predictiveToken.transferFrom(msg.sender, address(this), _amount), "APC: Token transfer failed for staking. Ensure sufficient allowance.");

        members[msg.sender].stake += _amount;
        members[msg.sender].lastStakeChange = block.timestamp; // Update for potential future reputation recalibration

        emit Staked(msg.sender, _amount);
    }

    function requestUnstake(uint256 _amount) external whenNotPaused onlyMember {
        require(_amount > 0, "APC: Unstake amount must be greater than zero");
        require(members[msg.sender].stake >= _amount + minStake, "APC: Cannot unstake below min stake or more than available"); // Always maintain minStake

        uint256 requestId = nextUnstakeRequestId[msg.sender]++;
        unstakeRequests[msg.sender][requestId] = UnstakeRequest({
            amount: _amount,
            cooldownEnd: block.timestamp + (unstakeCooldownDays * 1 days),
            exists: true
        });

        emit UnstakeRequested(msg.sender, requestId, _amount, unstakeRequests[msg.sender][requestId].cooldownEnd);
    }

    function executeUnstake(uint256 _requestId) external whenNotPaused onlyMember {
        UnstakeRequest storage req = unstakeRequests[msg.sender][_requestId];
        require(req.exists, "APC: Unstake request does not exist");
        require(block.timestamp >= req.cooldownEnd, "APC: Unstake cooldown period not over");
        require(members[msg.sender].stake >= req.amount, "APC: Insufficient staked amount for this request");

        members[msg.sender].stake -= req.amount;
        members[msg.sender].lastStakeChange = block.timestamp;

        delete unstakeRequests[msg.sender][_requestId]; // Remove request after execution

        require(predictiveToken.transfer(msg.sender, req.amount), "APC: Token transfer failed for unstake");

        emit Unstaked(msg.sender, _requestId, req.amount);
    }

    function delegateInfluence(address _delegatee) external whenNotPaused onlyMember {
        require(_delegatee != address(0), "APC: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "APC: Cannot delegate to self");
        require(members[_delegatee].isMember, "APC: Delegatee is not a registered member");
        
        members[msg.sender].delegatedTo = _delegatee;
        emit InfluenceDelegated(msg.sender, _delegatee);
    }

    function undelegateInfluence() external whenNotPaused onlyMember {
        require(members[msg.sender].delegatedTo != address(0), "APC: No active delegation to undelegate");
        members[msg.sender].delegatedTo = address(0);
        emit InfluenceUndelegated(msg.sender);
    }

    // Internal function to calculate the effective influence for a member, considering delegations and reputation.
    // Influence = Staked Tokens + (Reputation Score * REPUTATION_MULTIPLIER)
    // Reputation contributes positively to influence only if it's above zero.
    function _getEffectiveInfluence(address _member) internal view returns (uint256) {
        if (!members[_member].isMember) return 0;

        address currentMember = _member;
        // Simple 1-level delegation for influence. More complex delegation (e.g., weighted, multi-level)
        // would require additional logic to prevent loops and manage complexity.
        if (members[currentMember].delegatedTo != address(0)) {
            currentMember = members[currentMember].delegatedTo;
        }
                                     
        uint256 reputationInfluence = members[currentMember].reputationScore > 0 ? 
                                     uint256(members[currentMember].reputationScore) * REPUTATION_MULTIPLIER : 0;
                                     
        return members[currentMember].stake + reputationInfluence;
    }

    // --- III. Prediction Market Lifecycle ---

    function proposePredictionMarket(
        string memory _title,
        string memory _description,
        string memory _resolutionSource, // e.g., "coinmarketcap.com/eth-usd"
        uint256 _deadline // Timestamp
    ) external whenNotPaused onlyMember {
        require(bytes(_title).length > 0, "APC: Title cannot be empty");
        require(bytes(_description).length > 0, "APC: Description cannot be empty");
        require(bytes(_resolutionSource).length > 0, "APC: Resolution source cannot be empty");
        require(_deadline > block.timestamp, "APC: Deadline must be in the future");
        
        // Requires msg.sender to have approved this contract to spend predictionMarketProposalFee
        require(predictiveToken.transferFrom(msg.sender, address(this), predictionMarketProposalFee), "APC: Fee transfer failed. Ensure sufficient allowance.");

        uint256 marketId = nextPredictionMarketId++;
        predictionMarkets[marketId] = PredictionMarket({
            id: marketId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            resolutionSource: _resolutionSource,
            deadline: _deadline,
            status: MarketStatus.Proposed,
            actualOutcome: false, // Default, will be set upon finalization
            proposalVotesFor: 0,
            proposalVotesAgainst: 0,
            disputeCount: 0,
            exists: true
        });

        emit PredictionMarketProposed(marketId, msg.sender, _title, _deadline);
    }

    function voteOnPredictionMarketProposal(uint256 _marketId, bool _approve) external whenNotPaused onlyMember {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.exists, "APC: Prediction market does not exist");
        require(market.status == MarketStatus.Proposed, "APC: Market is not in proposed status");
        require(!hasVotedOnMarketProposal[_marketId][msg.sender], "APC: Already voted on this proposal");

        uint256 voterInfluence = _getEffectiveInfluence(msg.sender);
        require(voterInfluence > 0, "APC: Caller has no influence to vote");

        hasVotedOnMarketProposal[_marketId][msg.sender] = true;

        if (_approve) {
            market.proposalVotesFor += voterInfluence;
        } else {
            market.proposalVotesAgainst += voterInfluence;
        }

        emit PredictionMarketProposalVoted(_marketId, msg.sender, _approve, voterInfluence);

        // Simple approval threshold: If votesFor is significantly higher than votesAgainst, the market is approved.
        // In a production system, this would be a more complex governance mechanism (e.g., quorum, voting duration, decay).
        if (market.proposalVotesFor >= market.proposalVotesAgainst * 2 && market.proposalVotesFor > 0) {
            market.status = MarketStatus.Approved;
            emit PredictionMarketApproved(_marketId);
        }
    }

    function submitPrediction(uint256 _marketId, bool _predictedOutcome) external whenNotPaused onlyActivePredictionMarket(_marketId) onlyMember {
        require(!memberSubmittedPrediction[_marketId][msg.sender], "APC: Already submitted prediction for this market");

        memberSubmittedPrediction[_marketId][msg.sender] = true;
        memberPredictedOutcome[_marketId][msg.sender] = _predictedOutcome;

        emit PredictionSubmitted(_marketId, msg.sender, _predictedOutcome);
    }

    // Owner/Oracle function to finalize a prediction market. This is where external data (the actual outcome) is provided.
    // This function doesn't update reputation directly but sets the market status, allowing members to claim updates.
    function finalizePredictionMarket(uint256 _marketId, bool _actualOutcome) external onlyOwner whenNotPaused {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.exists, "APC: Prediction market does not exist");
        require(market.status == MarketStatus.Approved, "APC: Market is not in approved status");
        require(block.timestamp > market.deadline, "APC: Market deadline has not passed yet");

        market.actualOutcome = _actualOutcome;
        market.status = MarketStatus.Finalized;
        
        emit PredictionMarketFinalized(_marketId, _actualOutcome);
    }

    // This function can be called by any member to get their reputation updated for a finalized market.
    // This allows gas costs to be borne by the individual member claiming their update, rather than by the oracle/owner.
    function claimReputationUpdate(uint256 _marketId) external onlyMember whenNotPaused {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Finalized, "APC: Market is not finalized");
        require(memberSubmittedPrediction[_marketId][msg.sender], "APC: Member did not submit prediction for this market");
        require(!reputationUpdatedForMarket[_marketId][msg.sender], "APC: Reputation already updated for this market"); 

        int256 reputationChange;
        if (memberPredictedOutcome[_marketId][msg.sender] == market.actualOutcome) {
            reputationChange = int256(CORRECT_PREDICTION_REPUTATION_GAIN); 
        } else {
            reputationChange = INCORRECT_PREDICTION_REPUTATION_LOSS; 
        }

        members[msg.sender].reputationScore += reputationChange;
        reputationUpdatedForMarket[_marketId][msg.sender] = true; 

        emit ReputationUpdated(msg.sender, _marketId, reputationChange, members[msg.sender].reputationScore);
    }

    // Simplified dispute mechanism. In a real system, this would trigger a more robust
    // dispute resolution process (e.g., Schelling Point, further voting, arbitration).
    function disputePredictionMarket(uint256 _marketId) external whenNotPaused onlyMember {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.exists, "APC: Prediction market does not exist");
        require(market.status == MarketStatus.Finalized, "APC: Market is already finalized. To dispute, it must be finalized.");
        
        market.disputeCount++;
        market.status = MarketStatus.Disputed; // Set to disputed, awaiting further action by owner/governance
        emit PredictionMarketDisputed(_marketId, msg.sender);
    }

    // --- IV. Treasury & Capital Allocation ---

    function proposeCapitalAllocationStrategy(
        string memory _description,
        address _targetAddress,
        address _treasuryToken, // The ERC20 token to be allocated (e.g., USDC, WETH)
        uint256 _amount
    ) external whenNotPaused onlyMember {
        require(bytes(_description).length > 0, "APC: Description cannot be empty");
        require(_targetAddress != address(0), "APC: Target address cannot be zero");
        require(_treasuryToken != address(0), "APC: Treasury token address cannot be zero");
        require(_amount > 0, "APC: Allocation amount must be greater than zero");
        
        // Ensure the contract actually holds enough of this treasury token
        require(IERC20(_treasuryToken).balanceOf(address(this)) >= _amount, "APC: Insufficient treasury funds for allocation");

        uint256 strategyId = nextCapitalAllocationStrategyId++;
        capitalAllocationStrategies[strategyId] = CapitalAllocationStrategy({
            id: strategyId,
            proposer: msg.sender,
            description: _description,
            targetAddress: _targetAddress,
            treasuryToken: _treasuryToken,
            amount: _amount,
            status: StrategyStatus.Proposed,
            votesFor: 0,
            votesAgainst: 0,
            exists: true
        });

        emit CapitalAllocationStrategyProposed(strategyId, msg.sender, _description, _treasuryToken, _amount);
    }

    function voteOnCapitalAllocationStrategy(uint256 _strategyId, bool _approve) external whenNotPaused onlyMember {
        CapitalAllocationStrategy storage strategy = capitalAllocationStrategies[_strategyId];
        require(strategy.exists, "APC: Capital allocation strategy does not exist");
        require(strategy.status == StrategyStatus.Proposed, "APC: Strategy is not in proposed status");
        require(!hasVotedOnStrategy[_strategyId][msg.sender], "APC: Already voted on this strategy");

        uint256 voterInfluence = _getEffectiveInfluence(msg.sender);
        require(voterInfluence > 0, "APC: Caller has no influence to vote");

        hasVotedOnStrategy[_strategyId][msg.sender] = true;

        if (_approve) {
            strategy.votesFor += voterInfluence;
        } else {
            strategy.votesAgainst += voterInfluence;
        }

        emit CapitalAllocationStrategyVoted(_strategyId, msg.sender, _approve, voterInfluence);

        // Simple approval threshold for strategy approval
        if (strategy.votesFor >= strategy.votesAgainst * 2 && strategy.votesFor > 0) {
            strategy.status = StrategyStatus.Approved;
            emit CapitalAllocationStrategyApproved(_strategyId);
        }
    }

    // Owner/Governance function to execute an approved capital allocation strategy
    function executeCapitalAllocation(uint256 _strategyId) external onlyOwner whenNotPaused {
        CapitalAllocationStrategy storage strategy = capitalAllocationStrategies[_strategyId];
        require(strategy.exists, "APC: Capital allocation strategy does not exist");
        require(strategy.status == StrategyStatus.Approved, "APC: Strategy is not in approved status");
        
        strategy.status = StrategyStatus.Executed;
        
        // Perform the token transfer from the contract's treasury to the target address
        require(IERC20(strategy.treasuryToken).transfer(strategy.targetAddress, strategy.amount), "APC: Token transfer failed for allocation");

        emit CapitalAllocationExecuted(strategy.id, strategy.targetAddress, strategy.treasuryToken, strategy.amount);
    }

    // Owner/Governance function to record the outcome of an investment made by the collective.
    // This feeds back into the collective's reputation, especially for the proposer of the strategy.
    function recordInvestmentReturn(uint256 _strategyId, address _treasuryToken, uint256 _returnAmount, bool _isProfit) external onlyOwner whenNotPaused {
        CapitalAllocationStrategy storage strategy = capitalAllocationStrategies[_strategyId];
        require(strategy.exists, "APC: Capital allocation strategy does not exist");
        require(strategy.status == StrategyStatus.Executed, "APC: Strategy was not executed");
        require(strategy.treasuryToken == _treasuryToken, "APC: Mismatched treasury token");

        if (_isProfit) {
            // If there's a profit, the returning entity (e.g., an investment fund contract)
            // must have approved this contract to transfer the _returnAmount.
            require(IERC20(_treasuryToken).transferFrom(msg.sender, address(this), _returnAmount), "APC: Failed to deposit profit. Ensure sufficient allowance.");
            
            // Adjust proposer's reputation for successful strategy
            if (members[strategy.proposer].isMember) {
                members[strategy.proposer].reputationScore += int256(PROPOSER_PROFIT_REPUTATION_GAIN);
                emit ReputationUpdated(strategy.proposer, _strategyId, int256(PROPOSER_PROFIT_REPUTATION_GAIN), members[strategy.proposer].reputationScore);
            }
        } else {
            // For a loss, we just record the event. The actual funds would have been lost/spent by the targetAddress.
            // A small penalty for a losing strategy proposer could be implemented here if desired:
            // if (members[strategy.proposer].isMember) {
            //     members[strategy.proposer].reputationScore += PROPOSER_LOSS_REPUTATION_LOSS;
            //     emit ReputationUpdated(strategy.proposer, _strategyId, PROPOSER_LOSS_REPUTATION_LOSS, members[strategy.proposer].reputationScore);
            // }
        }
        
        emit InvestmentReturnRecorded(_strategyId, _treasuryToken, _returnAmount, _isProfit);
    }

    // --- V. View Functions & Metrics ---

    function getMemberInfluence(address _member) public view returns (uint256) {
        return _getEffectiveInfluence(_member);
    }

    function getPredictionMarketDetails(uint256 _marketId)
        public view
        returns (
            uint256 id,
            address proposer,
            string memory title,
            string memory description,
            string memory resolutionSource,
            uint256 deadline,
            MarketStatus status,
            bool actualOutcome,
            uint256 proposalVotesFor,
            uint256 proposalVotesAgainst,
            uint256 disputeCount
        )
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.exists, "APC: Prediction market does not exist");

        return (
            market.id,
            market.proposer,
            market.title,
            market.description,
            market.resolutionSource,
            market.deadline,
            market.status,
            market.actualOutcome,
            market.proposalVotesFor,
            market.proposalVotesAgainst,
            market.disputeCount
        );
    }

    function getCapitalAllocationStrategyDetails(uint256 _strategyId)
        public view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            address targetAddress,
            address treasuryToken,
            uint256 amount,
            StrategyStatus status,
            uint256 votesFor,
            uint256 votesAgainst
        )
    {
        CapitalAllocationStrategy storage strategy = capitalAllocationStrategies[_strategyId];
        require(strategy.exists, "APC: Capital allocation strategy does not exist");

        return (
            strategy.id,
            strategy.proposer,
            strategy.description,
            strategy.targetAddress,
            strategy.treasuryToken,
            strategy.amount,
            strategy.status,
            strategy.votesFor,
            strategy.votesAgainst
        );
    }
}
```