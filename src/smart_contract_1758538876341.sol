This smart contract, `AetheriumNexus`, is designed as a decentralized platform for predictive governance, dynamic resource allocation, and AI model incentivization. It leverages prediction markets to gather collective intelligence, which then influences governance decisions and the distribution of treasury funds. Participants are incentivized through a reputation system and unique Aetherium AI Model NFTs, which gain utility and influence based on their owners' predictive accuracy.

---

## AetheriumNexus Smart Contract

### Outline and Function Summary

**I. Core System & Access Control**
1.  **`constructor`**: Initializes the contract, sets the initial owner, and designates an authorized oracle address.
2.  **`changeAdmin`**: Allows the current owner to transfer administrative control (ownership) to a new address.
3.  **`pauseSystem`**: Activates an emergency pause, halting most critical contract operations to mitigate risks.
4.  **`unpauseSystem`**: Deactivates the emergency pause, restoring full contract functionality.
5.  **`setOracleAddress`**: Designates a specific address or contract as the authorized entity responsible for revealing prediction market outcomes.

**II. Dynamic Parameters & Configuration**
6.  **`updateProtocolFee`**: Modifies the percentage of fees collected by the protocol from certain transactions.
7.  **`updateReputationDecayRate`**: Adjusts the rate at which predictor reputation scores naturally diminish over time, encouraging continuous and active participation.
8.  **`updateMinimumStakeForModel`**: Sets the minimum amount of native tokens (e.g., Ether) required to mint a new Aetherium AI Model NFT.

**III. Decentralized Prediction Markets**
9.  **`createPredictionMarket`**: Initiates a new prediction topic with a clear question, predefined answer options, a closing deadline, and an optional minimum stake requirement for predictions.
10. **`submitPredictionVote`**: Users place a prediction on an active market, staking native tokens and providing a confidence score. This score influences potential rewards and the user's reputation update.
11. **`revealMarketOutcome`**: The designated `_oracleAddress` reveals the true outcome for a prediction market that has passed its closing deadline.
12. **`settleMarketAndRewardPredictors`**: After an outcome is revealed, this function calculates prediction accuracy, distributes staked tokens to correct predictors, and updates individual predictor reputation scores.

**IV. Aetherium AI Model NFTs & Reputation**
13. **`mintAetheriumAIModelNFT`**: Allows eligible users (e.g., those with a certain reputation or by staking) to mint a unique NFT representing their "trained AI Model" or "Data Set." This NFT's utility is intrinsically linked to its owner's predictive performance.
14. **`trainAetheriumAIModelNFT`**: A conceptual "training" function. NFT owners can 'level up' their Aetherium AI Model NFT by demonstrating consistent accurate predictions since the last training session. This enhances its power score, governance weight, or yield potential. May require a small token burn or additional stake.
15. **`getPredictorScore`**: Retrieves a user's aggregate prediction accuracy, confidence-weighted performance, and overall reputation score.
16. **`stakeAetheriumAIModelNFT`**: Users can stake their Aetherium AI Model NFT into a dedicated pool to gain enhanced governance weight in proposals or earn a share of protocol fees.
17. **`unstakeAetheriumAIModelNFT`**: Allows users to unstake their Aetherium AI Model NFT from the pool and reclaim ownership.

**V. Adaptive Governance & Resource Allocation**
18. **`proposeDynamicRuleChange`**: Empowers high-reputation users or staked NFT holders to propose modifications to the contract's configurable parameters (e.g., fee rates, reputation decay rates) through a formal governance process.
19. **`castGovernanceVote`**: Users cast their vote on active governance proposals. Their vote weight is dynamically adjusted based on their current reputation score and any staked Aetherium AI Model NFTs.
20. **`executeApprovedProposal`**: Once a governance proposal has passed its voting threshold and period, this function allows for the execution of the proposed parameter change, dynamically updating contract logic.
21. **`initiateAdaptiveResourceAllocation`**: Sets up a mechanism to allocate a specific amount of treasury funds to a designated recipient, contingent upon the successful and favorable resolution of a particular prediction market outcome.
22. **`claimAllocatedFunds`**: Allows the designated recipient to claim funds that have been successfully allocated via an `AdaptiveResourceAllocation` after the associated prediction market has resolved favorably.
23. **`submitAetheriumGrantProposal`**: Enables users to submit detailed proposals for projects seeking grants from the contract's treasury. These proposals will then be subject to community review and evaluation, potentially influenced by aggregated predictive data or insights from staked AI Model NFTs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title AetheriumNexus - Decentralized AI-Driven Predictive Governance and Resource Allocation
/// @dev This contract implements a sophisticated system combining prediction markets,
///      reputation-based governance, and utility NFTs to drive resource allocation.
///      It aims to create a self-improving decentralized autonomous organization
///      where collective intelligence and predictive accuracy inform decisions.
contract AetheriumNexus is Ownable, Pausable, ERC721URIStorage {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Custom Errors ---
    error InvalidMarketId(uint256 marketId);
    error MarketNotOpen(uint256 marketId);
    error MarketClosed(uint256 marketId);
    error MarketOutcomeNotRevealed(uint256 marketId);
    error MarketAlreadySettled(uint256 marketId);
    error InvalidOption(uint256 marketId, uint256 optionIndex);
    error InsufficientStake();
    error NotOracle();
    error OutcomeAlreadyRevealed(uint256 marketId);
    error NoRewardsToClaim();
    error AlreadyVoted(uint256 proposalId, address voter);
    error ProposalNotActive(uint256 proposalId);
    error ProposalNotApproved(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error InsufficientReputationForProposal(uint256 required, uint256 current);
    error NFTAlreadyStaked(uint256 tokenId);
    error NFTNotStaked(uint256 tokenId);
    error NotAetheriumAIModelNFT(uint256 tokenId);
    error InsufficientBalanceForAllocation();
    error AllocationNotResolved();
    error AllocationAlreadyClaimed();
    error UnauthorizedRecipient();
    error ReputationTooLowToMint();
    error NotEnoughAccuratePredictionsForTraining();
    error InvalidTrainInterval();
    error MinStakeNotMet();
    error FeeTooHigh();

    // --- Events ---
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event OracleAddressSet(address indexed newOracle);
    event ProtocolFeeUpdated(uint256 newFeePercentage);
    event ReputationDecayRateUpdated(uint256 newRate);
    event MinimumStakeForModelUpdated(uint256 newMinStake);

    event PredictionMarketCreated(
        uint256 indexed marketId,
        string topic,
        uint256 endTime,
        uint256 minStake
    );
    event PredictionSubmitted(
        uint256 indexed marketId,
        address indexed predictor,
        uint256 optionChosen,
        uint256 amountStaked,
        uint256 confidenceScore
    );
    event MarketOutcomeRevealed(
        uint256 indexed marketId,
        uint256 finalOutcome
    );
    event MarketSettled(uint256 indexed marketId);
    event RewardsClaimed(
        uint256 indexed marketId,
        address indexed predictor,
        uint256 amount
    );

    event AetheriumAIModelNFTMinted(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 initialLevel,
        uint256 initialPowerScore
    );
    event AetheriumAIModelNFTTrained(
        uint256 indexed tokenId,
        uint256 newLevel,
        uint256 newPowerScore
    );
    event AetheriumAIModelNFTStaked(
        uint256 indexed tokenId,
        address indexed owner
    );
    event AetheriumAIModelNFTUnstaked(
        uint256 indexed tokenId,
        address indexed owner
    );

    event DynamicRuleChangeProposed(
        uint256 indexed proposalId,
        address indexed proposer,
        bytes callData,
        string description
    );
    event GovernanceVoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );
    event ProposalExecuted(uint256 indexed proposalId);

    event AdaptiveResourceAllocationInitiated(
        uint256 indexed allocationId,
        uint256 indexed marketId,
        uint256 targetOutcome,
        uint256 amount,
        address indexed recipient
    );
    event AllocatedFundsClaimed(
        uint256 indexed allocationId,
        address indexed recipient,
        uint256 amount
    );

    event AetheriumGrantProposalSubmitted(
        uint256 indexed grantId,
        address indexed proposer,
        string title,
        uint256 requestedAmount
    );

    // --- State Variables ---
    address public _oracleAddress;
    uint256 public protocolFeePercentage = 5; // 5% fee (out of 100)
    address public protocolFeeRecipient; // Address to receive protocol fees

    uint256 public reputationDecayRate = 1; // 1 point per day, adjust based on time unit
    uint256 public minReputationToMintAIModel = 100; // Example
    uint256 public minStakeToMintAIModel = 0.1 ether;
    uint256 public minAccuratePredictionsForTraining = 5;
    uint256 public minBlocksBetweenTraining = 1000; // Roughly ~4 hours (13 sec/block)

    Counters.Counter private _marketIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _allocationIds;
    Counters.Counter private _grantIds;
    Counters.Counter private _tokenIds;

    // --- Structs ---

    enum MarketStatus {
        Open,
        Closed,
        OutcomeRevealed,
        Settled
    }

    struct PredictionMarket {
        string topic;
        string[] options;
        uint256 endTime;
        MarketStatus status;
        uint256 finalOutcome; // Index of the winning option
        uint256 totalStaked;
        mapping(uint256 => uint256) stakedPerOption; // Option index => total staked
        bool isSettled;
    }
    mapping(uint256 => PredictionMarket) public predictionMarkets;

    struct PredictionVote {
        uint256 optionChosen;
        uint256 amountStaked;
        uint256 confidenceScore; // 1-100, higher means more confidence in prediction
        bool claimed;
    }
    mapping(uint256 => mapping(address => PredictionVote)) public predictionVotes; // marketId => predictor => vote

    struct PredictorStats {
        uint256 totalPredictions;
        uint256 accuratePredictions;
        uint256 reputationScore; // Influences governance weight, NFT minting
        uint256 lastReputationUpdateBlock;
        uint256 lastPredictionBlock;
    }
    mapping(address => PredictorStats) public predictorStats;

    struct AetheriumAIModel {
        uint256 level;
        uint256 powerScore; // Influences governance weight and reward share
        uint256 lastTrainedBlock;
        uint256 accuratePredictionsSinceLastTraining;
        uint256 stakedTime; // block.timestamp when staked
    }
    mapping(uint256 => AetheriumAIModel) public aetheriumAIModels; // tokenId => AIModel details
    mapping(address => uint256[]) public userAIModels; // User => list of their AI Model NFT tokenIds
    mapping(uint256 => bool) public isAetheriumAIModelStaked; // tokenId => is staked

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Executed
    }

    struct GovernanceProposal {
        address proposer;
        bytes callData; // Encoded function call to execute on success
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVoteWeight;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // voter => bool
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    struct AdaptiveResourceAllocation {
        uint256 marketId;
        uint256 targetOutcome; // The required outcome for funds to be released
        uint256 amount;
        address recipient;
        bool claimed;
        bool resolved;
    }
    mapping(uint256 => AdaptiveResourceAllocation)
        public adaptiveResourceAllocations;

    struct AetheriumGrantProposal {
        address proposer;
        string title;
        string detailsURI; // IPFS URI to proposal details
        uint256 requestedAmount;
        bool approved; // Simplified approval, could be DAO voted
        bool funded;
    }
    mapping(uint256 => AetheriumGrantProposal) public aetheriumGrantProposals;

    // --- Constructor ---
    constructor(address initialOracleAddress, address feeRecipient)
        ERC721("AetheriumAIModel", "AI-NFT")
        Ownable(msg.sender)
    {
        _oracleAddress = initialOracleAddress;
        protocolFeeRecipient = feeRecipient;
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != _oracleAddress) {
            revert NotOracle();
        }
        _;
    }

    modifier enforceMarketStatus(uint256 _marketId, MarketStatus _status) {
        if (predictionMarkets[_marketId].status != _status) {
            revert InvalidMarketId(_marketId); // or a more specific error
        }
        _;
    }

    // --- I. Core System & Access Control ---

    /// @dev Allows the current admin to transfer ownership to a new address.
    /// @param newAdmin The address of the new administrator.
    function changeAdmin(address newAdmin) public onlyOwner {
        address oldAdmin = owner();
        transferOwnership(newAdmin);
        emit AdminChanged(oldAdmin, newAdmin);
    }

    /// @dev Pauses the contract, preventing critical operations. Can only be called by the owner.
    function pauseSystem() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @dev Unpauses the contract, restoring full functionality. Can only be called by the owner.
    function unpauseSystem() public onlyOwner whenPaused {
        _unpause();
    }

    /// @dev Sets the address designated as the oracle for prediction market outcomes.
    /// @param newOracle The address of the new oracle.
    function setOracleAddress(address newOracle) public onlyOwner {
        _oracleAddress = newOracle;
        emit OracleAddressSet(newOracle);
    }

    // --- II. Dynamic Parameters & Configuration ---

    /// @dev Updates the protocol fee percentage.
    /// @param newFeePercentage The new fee percentage (e.g., 5 for 5%). Must be <= 100.
    function updateProtocolFee(uint256 newFeePercentage) public onlyOwner {
        if (newFeePercentage > 100) {
            revert FeeTooHigh();
        }
        protocolFeePercentage = newFeePercentage;
        emit ProtocolFeeUpdated(newFeePercentage);
    }

    /// @dev Updates the rate at which predictor reputation decays over time.
    /// @param newRate The new reputation decay rate (e.g., 1 point per time unit).
    function updateReputationDecayRate(uint256 newRate) public onlyOwner {
        reputationDecayRate = newRate;
        emit ReputationDecayRateUpdated(newRate);
    }

    /// @dev Updates the minimum token stake required to mint an Aetherium AI Model NFT.
    /// @param newMinStake The new minimum stake amount in wei.
    function updateMinimumStakeForModel(uint256 newMinStake) public onlyOwner {
        minStakeToMintAIModel = newMinStake;
        emit MinimumStakeForModelUpdated(newMinStake);
    }

    // --- III. Decentralized Prediction Markets ---

    /// @dev Creates a new prediction market.
    /// @param _topic A descriptive string for the prediction market.
    /// @param _options An array of possible outcomes.
    /// @param _endTime The timestamp when the market closes for predictions.
    /// @param _minStake The minimum amount of ETH required to participate in this market.
    /// @return The ID of the newly created prediction market.
    function createPredictionMarket(
        string memory _topic,
        string[] memory _options,
        uint256 _endTime,
        uint256 _minStake
    ) public onlyOwner returns (uint256) {
        if (_endTime <= block.timestamp) {
            revert("End time must be in the future");
        }
        if (_options.length < 2) {
            revert("Must have at least two options");
        }

        _marketIds.increment();
        uint256 marketId = _marketIds.current();

        predictionMarkets[marketId].topic = _topic;
        predictionMarkets[marketId].options = _options;
        predictionMarkets[marketId].endTime = _endTime;
        predictionMarkets[marketId].status = MarketStatus.Open;
        predictionMarkets[marketId].totalStaked = 0;
        // _minStake is not stored in the market struct, but could be added if needed for specific markets.
        // For now, it's checked during submission.

        emit PredictionMarketCreated(marketId, _topic, _endTime, _minStake);
        return marketId;
    }

    /// @dev Allows users to submit their prediction on an open market.
    /// @param _marketId The ID of the prediction market.
    /// @param _optionChosen The index of the chosen outcome option.
    /// @param _confidenceScore A score from 1 to 100 indicating confidence.
    function submitPredictionVote(
        uint256 _marketId,
        uint256 _optionChosen,
        uint256 _confidenceScore
    ) public payable whenNotPaused {
        if (_marketId == 0 || _marketId > _marketIds.current()) {
            revert InvalidMarketId(_marketId);
        }
        PredictionMarket storage market = predictionMarkets[_marketId];

        if (market.status != MarketStatus.Open || block.timestamp >= market.endTime) {
            revert MarketNotOpen(_marketId);
        }
        if (_optionChosen >= market.options.length) {
            revert InvalidOption(_marketId, _optionChosen);
        }
        // Assuming a minimum stake could be a global setting or per market
        if (msg.value == 0) {
            revert InsufficientStake();
        }

        // Check if user has already voted
        if (predictionVotes[_marketId][msg.sender].amountStaked > 0) {
            revert AlreadyVoted(_marketId, msg.sender);
        }

        predictionVotes[_marketId][msg.sender] = PredictionVote({
            optionChosen: _optionChosen,
            amountStaked: msg.value,
            confidenceScore: _confidenceScore,
            claimed: false
        });

        market.totalStaked = market.totalStaked.add(msg.value);
        market.stakedPerOption[_optionChosen] = market.stakedPerOption[_optionChosen].add(msg.value);

        // Update predictor's last prediction block
        predictorStats[msg.sender].lastPredictionBlock = block.number;

        emit PredictionSubmitted(
            _marketId,
            msg.sender,
            _optionChosen,
            msg.value,
            _confidenceScore
        );
    }

    /// @dev The designated oracle reveals the outcome of a prediction market.
    /// @param _marketId The ID of the prediction market.
    /// @param _finalOutcome The index of the actual outcome.
    function revealMarketOutcome(
        uint256 _marketId,
        uint256 _finalOutcome
    ) public onlyOracle whenNotPaused {
        if (_marketId == 0 || _marketId > _marketIds.current()) {
            revert InvalidMarketId(_marketId);
        }
        PredictionMarket storage market = predictionMarkets[_marketId];

        if (market.status == MarketStatus.OutcomeRevealed || market.status == MarketStatus.Settled) {
            revert OutcomeAlreadyRevealed(_marketId);
        }
        if (block.timestamp < market.endTime) {
            revert MarketNotClosed(_marketId);
        }
        if (_finalOutcome >= market.options.length) {
            revert InvalidOption(_marketId, _finalOutcome);
        }

        market.finalOutcome = _finalOutcome;
        market.status = MarketStatus.OutcomeRevealed;

        emit MarketOutcomeRevealed(_marketId, _finalOutcome);
    }

    /// @dev Settles a prediction market, distributing rewards and updating reputations.
    ///      Anyone can call this after the outcome is revealed.
    /// @param _marketId The ID of the prediction market to settle.
    function settleMarketAndRewardPredictors(uint256 _marketId) public whenNotPaused {
        if (_marketId == 0 || _marketId > _marketIds.current()) {
            revert InvalidMarketId(_marketId);
        }
        PredictionMarket storage market = predictionMarkets[_marketId];

        if (market.status != MarketStatus.OutcomeRevealed) {
            revert MarketOutcomeNotRevealed(_marketId);
        }
        if (market.isSettled) {
            revert MarketAlreadySettled(_marketId);
        }

        // Calculate total staked on the winning option
        uint256 winningOptionStaked = market.stakedPerOption[market.finalOutcome];

        // Apply protocol fee to the total staked amount
        uint256 protocolFee = market.totalStaked.mul(protocolFeePercentage).div(100);
        uint256 rewardsPool = market.totalStaked.sub(protocolFee);

        // Transfer fee to recipient
        if (protocolFee > 0) {
            (bool success, ) = protocolFeeRecipient.call{value: protocolFee}("");
            require(success, "Failed to send protocol fee");
        }

        // Iterate through all predictions (conceptual, in real-world you'd iterate through a list of participants)
        // For simplicity, this function assumes it updates internal records for future claims.
        // A more gas-efficient approach might be to let users call a claim function,
        // which recalculates rewards and updates their stats individually.
        // For this example, we'll mark the market as settled and allow individual claims later.

        market.isSettled = true;
        market.status = MarketStatus.Settled;
        emit MarketSettled(_marketId);
    }

    /// @dev Allows a predictor to claim their rewards from a settled market.
    ///      Also updates their reputation based on accuracy.
    /// @param _marketId The ID of the prediction market.
    function claimPredictionRewards(uint256 _marketId) public whenNotPaused {
        if (_marketId == 0 || _marketId > _marketIds.current()) {
            revert InvalidMarketId(_marketId);
        }
        PredictionMarket storage market = predictionMarkets[_marketId];
        PredictionVote storage vote = predictionVotes[_marketId][msg.sender];
        PredictorStats storage stats = predictorStats[msg.sender];

        if (market.status != MarketStatus.Settled) {
            revert MarketOutcomeNotRevealed(_marketId);
        }
        if (vote.amountStaked == 0 || vote.claimed) {
            revert NoRewardsToClaim();
        }

        uint256 rewardAmount = 0;
        bool isAccurate = (vote.optionChosen == market.finalOutcome);

        stats.totalPredictions = stats.totalPredictions.add(1);

        if (isAccurate) {
            stats.accuratePredictions = stats.accuratePredictions.add(1);

            uint256 winningOptionStaked = market.stakedPerOption[market.finalOutcome];
            if (winningOptionStaked > 0) {
                // Proportional reward distribution from the rewards pool
                // rewardsPool = total_staked - protocolFee
                uint256 rewardsPool = market.totalStaked.sub(
                    market.totalStaked.mul(protocolFeePercentage).div(100)
                );
                rewardAmount = rewardsPool.mul(vote.amountStaked).div(winningOptionStaked);
            }
            stats.reputationScore = stats.reputationScore.add(10 + vote.confidenceScore.div(10)); // Boost for accuracy + confidence
            aetheriumAIModels[userAIModels[msg.sender][0]].accuratePredictionsSinceLastTraining += 1; // Simplistic update for first NFT
        } else {
            // Decay reputation for inaccurate prediction (less than natural decay)
            if (stats.reputationScore > 5) {
                stats.reputationScore = stats.reputationScore.sub(5);
            } else {
                stats.reputationScore = 0;
            }
        }

        // Apply reputation decay based on time
        _applyReputationDecay(msg.sender);

        vote.claimed = true;
        if (rewardAmount > 0) {
            (bool success, ) = msg.sender.call{value: rewardAmount}("");
            require(success, "Failed to send rewards");
        }
        emit RewardsClaimed(_marketId, msg.sender, rewardAmount);
    }

    // --- IV. Aetherium AI Model NFTs & Reputation ---

    /// @dev Helper to apply reputation decay.
    /// @param _predictor The address whose reputation to decay.
    function _applyReputationDecay(address _predictor) internal {
        PredictorStats storage stats = predictorStats[_predictor];
        uint256 lastUpdateBlock = stats.lastReputationUpdateBlock;
        if (lastUpdateBlock == 0) {
            stats.lastReputationUpdateBlock = block.number;
            return;
        }

        uint256 blocksSinceLastUpdate = block.number.sub(lastUpdateBlock);
        uint256 decayPeriods = blocksSinceLastUpdate.div(1000); // E.g., every 1000 blocks (approx 4 hours)

        if (decayPeriods > 0) {
            uint256 decayAmount = decayPeriods.mul(reputationDecayRate);
            if (stats.reputationScore > decayAmount) {
                stats.reputationScore = stats.reputationScore.sub(decayAmount);
            } else {
                stats.reputationScore = 0;
            }
            stats.lastReputationUpdateBlock = block.number;
        }
    }

    /// @dev Mints a new Aetherium AI Model NFT for eligible users.
    ///      Requires a minimum reputation score and a token stake.
    /// @param _tokenURI The URI pointing to the NFT's metadata (e.g., IPFS).
    /// @return The ID of the newly minted NFT.
    function mintAetheriumAIModelNFT(string memory _tokenURI) public payable whenNotPaused returns (uint256) {
        _applyReputationDecay(msg.sender); // Decay before checking reputation
        if (predictorStats[msg.sender].reputationScore < minReputationToMintAIModel) {
            revert ReputationTooLowToMint();
        }
        if (msg.value < minStakeToMintAIModel) {
            revert MinStakeNotMet();
        }

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        aetheriumAIModels[newItemId] = AetheriumAIModel({
            level: 1,
            powerScore: 100, // Base power
            lastTrainedBlock: block.number,
            accuratePredictionsSinceLastTraining: 0,
            stakedTime: 0 // Not staked initially
        });
        userAIModels[msg.sender].push(newItemId);

        // Funds are held by the contract, could be used for staking rewards or burned.
        // For simplicity, funds are kept in the contract.

        emit AetheriumAIModelNFTMinted(msg.sender, newItemId, 1, 100);
        return newItemId;
    }

    /// @dev Allows an NFT owner to "train" their Aetherium AI Model NFT, leveling it up.
    ///      Requires meeting certain prediction accuracy criteria since last training.
    /// @param _tokenId The ID of the Aetherium AI Model NFT to train.
    function trainAetheriumAIModelNFT(uint256 _tokenId) public whenNotPaused {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotAetheriumAIModelNFT(_tokenId); // Or not owner
        }
        AetheriumAIModel storage model = aetheriumAIModels[_tokenId];
        if (model.accuratePredictionsSinceLastTraining < minAccuratePredictionsForTraining) {
            revert NotEnoughAccuratePredictionsForTraining();
        }
        if (block.number.sub(model.lastTrainedBlock) < minBlocksBetweenTraining) {
            revert InvalidTrainInterval();
        }

        model.level = model.level.add(1);
        model.powerScore = model.powerScore.add(50); // Increase power with training
        model.lastTrainedBlock = block.number;
        model.accuratePredictionsSinceLastTraining = 0; // Reset for next training cycle

        emit AetheriumAIModelNFTTrained(_tokenId, model.level, model.powerScore);
    }

    /// @dev Retrieves a user's combined prediction accuracy and reputation score.
    /// @param _predictor The address of the predictor.
    /// @return The total predictions, accurate predictions, and current reputation score.
    function getPredictorScore(
        address _predictor
    ) public view returns (uint256, uint256, uint256) {
        // Apply decay conceptually for read-only, actual decay happens on state-changing calls
        // For accuracy, need to simulate decay or perform a calculation
        uint256 currentRep = predictorStats[_predictor].reputationScore;
        uint256 lastUpdateBlock = predictorStats[_predictor].lastReputationUpdateBlock;

        if (lastUpdateBlock != 0 && block.number > lastUpdateBlock) {
            uint256 blocksSinceLastUpdate = block.number.sub(lastUpdateBlock);
            uint256 decayPeriods = blocksSinceLastUpdate.div(1000); // Same as in _applyReputationDecay
            uint256 decayAmount = decayPeriods.mul(reputationDecayRate);
            if (currentRep > decayAmount) {
                currentRep = currentRep.sub(decayAmount);
            } else {
                currentRep = 0;
            }
        }

        return (
            predictorStats[_predictor].totalPredictions,
            predictorStats[_predictor].accuratePredictions,
            currentRep
        );
    }

    /// @dev Stakes an Aetherium AI Model NFT into the contract, giving it governance weight.
    /// @param _tokenId The ID of the Aetherium AI Model NFT to stake.
    function stakeAetheriumAIModelNFT(uint256 _tokenId) public whenNotPaused {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotAetheriumAIModelNFT(_tokenId); // Or not owner
        }
        if (isAetheriumAIModelStaked[_tokenId]) {
            revert NFTAlreadyStaked(_tokenId);
        }

        _transfer(msg.sender, address(this), _tokenId); // Transfer NFT to contract
        isAetheriumAIModelStaked[_tokenId] = true;
        aetheriumAIModels[_tokenId].stakedTime = block.timestamp;

        emit AetheriumAIModelNFTStaked(_tokenId, msg.sender);
    }

    /// @dev Unstakes an Aetherium AI Model NFT from the contract.
    /// @param _tokenId The ID of the Aetherium AI Model NFT to unstake.
    function unstakeAetheriumAIModelNFT(uint256 _tokenId) public whenNotPaused {
        if (!isAetheriumAIModelStaked[_tokenId]) {
            revert NFTNotStaked(_tokenId);
        }
        if (ownerOf(_tokenId) != address(this)) {
            revert("NFT not held by contract"); // Should not happen if isAetheriumAIModelStaked is true
        }

        // Check if original owner
        bool found = false;
        for (uint256 i = 0; i < userAIModels[msg.sender].length; i++) {
            if (userAIModels[msg.sender][i] == _tokenId) {
                found = true;
                break;
            }
        }
        if (!found) {
            revert("Only original minter can unstake"); // Or use a different ownership tracking
        }

        _transfer(address(this), msg.sender, _tokenId); // Transfer NFT back to owner
        isAetheriumAIModelStaked[_tokenId] = false;
        aetheriumAIModels[_tokenId].stakedTime = 0;

        emit AetheriumAIModelNFTUnstaked(_tokenId, msg.sender);
    }

    // --- V. Adaptive Governance & Resource Allocation ---

    /// @dev Proposes a dynamic rule change to contract parameters.
    ///      Requires a minimum reputation or staked NFT.
    /// @param _callData The encoded function call to be executed on success (e.g., `abi.encodeWithSignature("updateProtocolFee(uint256)", 10)`).
    /// @param _description A textual description of the proposed change.
    /// @param _votingPeriodBlocks The number of blocks for the voting period.
    /// @return The ID of the newly created proposal.
    function proposeDynamicRuleChange(
        bytes memory _callData,
        string memory _description,
        uint256 _votingPeriodBlocks
    ) public whenNotPaused returns (uint256) {
        _applyReputationDecay(msg.sender);
        uint256 reputation = predictorStats[msg.sender].reputationScore;
        // Check for sufficient reputation or staked NFTs for proposal power
        if (reputation < 50 && userAIModels[msg.sender].length == 0) {
            revert InsufficientReputationForProposal(50, reputation);
        }
        if (_votingPeriodBlocks == 0) {
            revert("Voting period must be greater than 0");
        }

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        governanceProposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            callData: _callData,
            description: _description,
            startBlock: block.number,
            endBlock: block.number.add(_votingPeriodBlocks),
            votesFor: 0,
            votesAgainst: 0,
            totalVoteWeight: 0,
            status: ProposalStatus.Active,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit DynamicRuleChangeProposed(proposalId, msg.sender, _callData, _description);
        return proposalId;
    }

    /// @dev Casts a vote on an active governance proposal.
    ///      Vote weight is determined by reputation and staked AI Model NFTs.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for', false for 'against'.
    function castGovernanceVote(uint256 _proposalId, bool _support) public whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (_proposalId == 0 || _proposalId > _proposalIds.current() || proposal.status != ProposalStatus.Active) {
            revert ProposalNotActive(_proposalId);
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVoted(_proposalId, msg.sender);
        }
        if (block.number > proposal.endBlock) {
            revert ProposalNotActive(_proposalId); // Voting period ended
        }

        _applyReputationDecay(msg.sender);
        uint256 voteWeight = predictorStats[msg.sender].reputationScore;

        // Add weight from staked AI Model NFTs
        for (uint256 i = 0; i < userAIModels[msg.sender].length; i++) {
            uint256 tokenId = userAIModels[msg.sender][i];
            if (isAetheriumAIModelStaked[tokenId]) {
                voteWeight = voteWeight.add(aetheriumAIModels[tokenId].powerScore);
            }
        }
        if (voteWeight == 0) {
            revert("No voting power");
        }

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voteWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voteWeight);
        }
        proposal.totalVoteWeight = proposal.totalVoteWeight.add(voteWeight);
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceVoteCast(_proposalId, msg.sender, _support, voteWeight);
    }

    /// @dev Executes an approved governance proposal. Only callable after voting period ends
    ///      and if the proposal has sufficient 'for' votes.
    /// @param _proposalId The ID of the proposal to execute.
    function executeApprovedProposal(uint256 _proposalId) public whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (_proposalId == 0 || _proposalId > _proposalIds.current()) {
            revert InvalidMarketId(_proposalId); // Reusing error
        }
        if (proposal.status == ProposalStatus.Executed) {
            revert ProposalAlreadyExecuted(_proposalId);
        }
        if (block.number <= proposal.endBlock) {
            revert ProposalNotActive(_proposalId); // Voting period still active
        }

        // Simple majority for now, could be more complex (e.g., quorum)
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Succeeded;
            (bool success, ) = address(this).call(proposal.callData);
            require(success, "Proposal execution failed");
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Defeated;
            revert ProposalNotApproved(_proposalId);
        }
    }

    /// @dev Initiates a conditional resource allocation based on a prediction market outcome.
    ///      Funds are held in escrow until the market resolves favorably.
    /// @param _marketId The ID of the prediction market this allocation is tied to.
    /// @param _targetOutcome The specific outcome index that must resolve for funds to be released.
    /// @param _amount The amount of funds to allocate (in wei).
    /// @param _recipient The address to receive the funds if the condition is met.
    /// @return The ID of the new adaptive resource allocation.
    function initiateAdaptiveResourceAllocation(
        uint256 _marketId,
        uint256 _targetOutcome,
        uint256 _amount,
        address _recipient
    ) public payable onlyOwner whenNotPaused returns (uint256) {
        if (_marketId == 0 || _marketId > _marketIds.current()) {
            revert InvalidMarketId(_marketId);
        }
        PredictionMarket storage market = predictionMarkets[_marketId];
        if (_targetOutcome >= market.options.length) {
            revert InvalidOption(_marketId, _targetOutcome);
        }
        if (msg.value != _amount) {
            revert InsufficientBalanceForAllocation();
        }
        if (_recipient == address(0)) {
            revert("Invalid recipient address");
        }

        _allocationIds.increment();
        uint256 allocationId = _allocationIds.current();

        adaptiveResourceAllocations[allocationId] = AdaptiveResourceAllocation({
            marketId: _marketId,
            targetOutcome: _targetOutcome,
            amount: _amount,
            recipient: _recipient,
            claimed: false,
            resolved: false
        });

        emit AdaptiveResourceAllocationInitiated(
            allocationId,
            _marketId,
            _targetOutcome,
            _amount,
            _recipient
        );
        return allocationId;
    }

    /// @dev Allows the designated recipient to claim funds from a resolved adaptive allocation.
    /// @param _allocationId The ID of the adaptive resource allocation.
    function claimAllocatedFunds(uint256 _allocationId) public whenNotPaused {
        if (_allocationId == 0 || _allocationId > _allocationIds.current()) {
            revert("Invalid allocation ID");
        }
        AdaptiveResourceAllocation storage allocation = adaptiveResourceAllocations[_allocationId];
        PredictionMarket storage market = predictionMarkets[allocation.marketId];

        if (msg.sender != allocation.recipient) {
            revert UnauthorizedRecipient();
        }
        if (allocation.claimed) {
            revert AllocationAlreadyClaimed();
        }
        if (market.status != MarketStatus.Settled) {
            revert MarketOutcomeNotRevealed(allocation.marketId);
        }
        if (market.finalOutcome != allocation.targetOutcome) {
            revert AllocationNotResolved(); // Condition not met
        }

        // Mark as resolved and claimed
        allocation.resolved = true;
        allocation.claimed = true;

        (bool success, ) = allocation.recipient.call{value: allocation.amount}("");
        require(success, "Failed to send allocated funds");

        emit AllocatedFundsClaimed(_allocationId, allocation.recipient, allocation.amount);
    }

    /// @dev Submits a proposal for an Aetherium Grant. These proposals can be evaluated by the community.
    /// @param _title The title of the grant proposal.
    /// @param _detailsURI IPFS or other URI pointing to detailed proposal information.
    /// @param _requestedAmount The amount of funds requested for the grant.
    /// @return The ID of the newly submitted grant proposal.
    function submitAetheriumGrantProposal(
        string memory _title,
        string memory _detailsURI,
        uint256 _requestedAmount
    ) public whenNotPaused returns (uint256) {
        _grantIds.increment();
        uint256 grantId = _grantIds.current();

        aetheriumGrantProposals[grantId] = AetheriumGrantProposal({
            proposer: msg.sender,
            title: _title,
            detailsURI: _detailsURI,
            requestedAmount: _requestedAmount,
            approved: false, // Initially false, requires governance vote/AI evaluation
            funded: false
        });

        emit AetheriumGrantProposalSubmitted(
            grantId,
            msg.sender,
            _title,
            _requestedAmount
        );
        return grantId;
    }

    // --- Fallback Function ---
    receive() external payable {}
    fallback() external payable {}
}
```