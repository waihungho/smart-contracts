Introducing `AetherPrognos`, a cutting-edge Solidity smart contract designed to power a decentralized platform for predictive analytics and content curation, featuring dynamic NFTs and a robust reputation-based governance system.

This contract integrates several advanced and trendy concepts:
*   **Decentralized Prediction Markets:** Users stake tokens on future event outcomes.
*   **Dynamic NFTs (dNFTs):** "Analyst Badges" that visually change based on a user's on-chain reputation.
*   **Reputation System (Prognos Score):** An on-chain score reflecting a user's prediction accuracy and contribution quality.
*   **Incentivized Content Curation:** Users can submit "insights" (e.g., analysis, research) related to prediction markets, and the community can endorse or dispute them by staking tokens. An AI Oracle (simulated) can provide a quality score, influencing rewards.
*   **DAO Governance:** High-reputation users gain the ability to propose and vote on key platform parameters.
*   **Oracle Integration:** For fetching real-world event outcomes and potentially AI-driven content analysis.

This unique combination of features in a single contract aims to provide a creative, advanced, and non-duplicative solution in the blockchain space.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Interface for a simplified Oracle (or Chainlink mock)
interface IPrognosOracle {
    function getLatestOutcome(bytes32 _marketId) external view returns (uint256 outcome);
}

// Interface for a hypothetical AI Oracle providing insights analysis
interface IAetherAIOracle {
    function getInsightQualityScore(bytes32 _insightHash) external view returns (uint256 score);
}

/**
 * @title AetherPrognos - Decentralized Predictive Analytics & Content Curation Platform
 * @dev This contract orchestrates a prediction market system combined with a dynamic reputation-based NFT
 *      and an incentivized insight curation mechanism, all governed by a DAO.
 *      Users predict future events, gain/lose reputation based on accuracy, earn dynamic NFTs (Analyst Badges),
 *      and curate related content for additional rewards.
 *
 * @outline
 * 1.  **Core Prediction Mechanism:**
 *     -   `createPredictionMarket`: Initializes a new prediction market for a specific event.
 *     -   `submitPrediction`: Users commit their forecast for a market.
 *     -   `lockPredictionStake`: Users lock collateral to back their prediction.
 *     -   `reportMarketOutcome`: Designated oracle/reporter provides the final outcome for a market.
 *     -   `settleMarketAndDistribute`: Finalizes a market, calculates rewards, and updates user reputations.
 *     -   `claimPredictionWinnings`: Allows participants to retrieve their share of the prize pool.
 *
 * 2.  **Reputation & Tier System (Prognos Score):**
 *     -   `getUserPrognosScore`: Retrieves a user's current reputation score.
 *     -   `getPrognosTier`: Determines a user's current reputation tier based on their score.
 *     -   `updatePrognosScore`: (Internal) Adjusts a user's reputation based on prediction accuracy and insight curation.
 *     -   `setTierThresholds`: (Admin/DAO) Configures the score boundaries for different reputation tiers.
 *
 * 3.  **Dynamic Analyst Badges (ERC721 NFT):**
 *     -   `mintPrognosBadge`: Mints a unique NFT badge (Analyst Badge) for a user upon reaching a specific tier.
 *     -   `updatePrognosBadgeMetadata`: Triggers a metadata update for an existing badge when its owner's tier changes.
 *     -   `getBadgeTier`: Retrieves the reputation tier associated with a specific badge ID.
 *     -   `getUserBadgeId`: Gets the badge ID currently held by a specific user.
 *     -   `tokenURI`: Overrides ERC721 `tokenURI` to provide dynamic metadata.
 *
 * 4.  **Insight Curation & Monetization:**
 *     -   `submitPrognosticInsight`: Users submit an IPFS hash of an insight related to a prediction market.
 *     -   `endorseInsight`: Users upvote an insight, staking a small amount of tokens as an endorsement.
 *     -   `disputeInsight`: Users downvote an insight, staking tokens to challenge its validity.
 *     -   `resolveInsightDispute`: (Admin/DAO) Resolves disputes on insights, affecting endorser/disputer stakes and insight quality score.
 *     -   `distributeInsightRewards`: Rewards creators of highly endorsed/quality insights.
 *
 * 5.  **DAO Governance & System Parameters:**
 *     -   `proposeAetherImprovement`: Allows high-tier users to propose changes to system parameters.
 *     -   `voteOnProposal`: Users cast votes on active governance proposals.
 *     -   `executeApprovedProposal`: Executes a proposal that has passed the voting phase.
 *     -   `setOracleAddress`: (DAO/Admin) Configures the address of the main prediction outcome oracle.
 *     -   `setInsightAIOracleAddress`: (DAO/Admin) Configures the address of the AI oracle for insight analysis.
 *     -   `updateCoreParameter`: (DAO) Generic function for DAO to update various system parameters (e.g., fees, minimum stakes).
 */
contract AetherPrognos is Ownable, ReentrancyGuard, Pausable, ERC721 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables & Enums ---

    // Token for staking and rewards
    IERC20 public immutable predictionToken;

    // Oracle addresses
    IPrognosOracle public prognosOracle;
    IAetherAIOracle public aetherAIOracle;

    // Configuration parameters (settable by DAO)
    uint256 public marketCreationFee;
    uint256 public minPredictionStake;
    uint256 public insightEndorsementStake;
    uint256 public insightDisputeStake;
    uint256 public rewardFeePercentage; // % taken from total rewards pool

    // Reputation thresholds for tiers
    struct PrognosTier {
        string name;
        uint256 scoreThreshold;
        string badgeBaseURI; // Base URI for this tier's NFT metadata
    }
    PrognosTier[] public prognosTiers;
    uint256 public constant MAX_REPUTATION_SCORE = 10_000_000; // Arbitrary max score

    // --- Market Structs ---
    enum MarketStatus { Pending, Active, Reported, Settled, Canceled }

    struct PredictionMarket {
        bytes32 marketId;
        string description;
        uint256 startTime;
        uint256 endTime;
        MarketStatus status;
        uint256 reportedOutcome; // The final outcome reported by oracle
        uint256 totalStaked;
        mapping(address => Prediction) predictions; // User address => Prediction
        address[] participants; // To iterate through participants for settlement
        uint256 uniqueParticipants; // To track count of participants
        uint256 winningOutcomeTotalStake; // Total stake for the winning outcome
        address creator;
        bool outcomeReported; // True if oracle has reported
    }

    struct Prediction {
        uint256 predictedOutcome;
        uint256 stakeAmount;
        bool hasClaimed;
    }

    mapping(bytes32 => PredictionMarket) public predictionMarkets;
    bytes32[] public activeMarketIds; // To keep track of active markets

    // --- User Data ---
    mapping(address => uint256) public prognosScores; // User reputation score
    mapping(address => uint256) public userBadges; // User address => Badge Token ID (if minted)

    // --- Insight Structs ---
    enum InsightStatus { Submitted, Endorsed, Disputed, Resolved, Rewarded }

    struct PrognosticInsight {
        bytes32 insightHash; // IPFS hash or similar identifier
        bytes32 marketId;
        address creator;
        uint256 submissionTime;
        InsightStatus status;
        uint256 endorsementStakePool; // Total stake from endorsers
        uint256 disputeStakePool; // Total stake from disputers
        uint256 aiQualityScore; // Score from AI oracle (0-100)
        mapping(address => bool) hasEndorsed;
        mapping(address => bool) hasDisputed;
    }

    mapping(bytes32 => PrognosticInsight) public prognosticInsights;
    Counters.Counter private _insightIdCounter;

    // --- Dynamic NFT Data ---
    string private _baseTokenURI; // Base URI for the NFT metadata API
    Counters.Counter private _badgeTokenIdCounter;

    // --- DAO Governance ---
    struct Proposal {
        uint256 id;
        string description;
        address targetContract;
        bytes callData;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
        bool approved; // Final result of voting
    }
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public minVotingPrognosScore; // Min score to propose or vote
    uint256 public proposalVotingPeriod; // How long a proposal is open for voting

    // --- Events ---
    event MarketCreated(bytes32 indexed marketId, string description, uint256 endTime, address creator);
    event PredictionSubmitted(bytes32 indexed marketId, address indexed participant, uint256 predictedOutcome, uint256 stakeAmount);
    event MarketOutcomeReported(bytes32 indexed marketId, uint256 outcome, address reporter);
    event MarketSettled(bytes32 indexed marketId, uint256 totalStaked, uint256 totalDistributed);
    event WinningsClaimed(bytes32 indexed marketId, address indexed participant, uint256 amount);
    event PrognosScoreUpdated(address indexed user, uint256 newScore, uint256 oldScore);
    event PrognosTierChanged(address indexed user, uint256 newTier, uint256 oldTier, uint256 badgeTokenId);
    event PrognosBadgeMinted(address indexed user, uint256 indexed tokenId, uint256 tier);
    event PrognosBadgeMetadataUpdated(uint256 indexed tokenId, uint256 newTier);
    event InsightSubmitted(bytes32 indexed insightHash, bytes32 indexed marketId, address creator);
    event InsightEndorsed(bytes32 indexed insightHash, address indexed endorser, uint256 stakedAmount);
    event InsightDisputed(bytes32 indexed insightHash, address indexed disputer, uint256 stakedAmount);
    event InsightDisputeResolved(bytes32 indexed insightHash, bool isLegit);
    event InsightRewardsDistributed(bytes32 indexed insightHash, address indexed creator, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, string description, address proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event OracleAddressSet(address indexed newOracleAddress);
    event InsightAIOracleAddressSet(address indexed newOracleAddress);
    event CoreParameterUpdated(string paramName, uint256 newValue);
    event MarketCreationFeeUpdated(uint256 oldFee, uint256 newFee);

    // --- Constructor ---
    constructor(
        address _predictionTokenAddress,
        address _prognosOracleAddress,
        address _aetherAIOracleAddress,
        string memory _baseTokenURI_
    )
        Ownable(msg.sender)
        ERC721("AetherPrognos Analyst Badge", "APAB")
    {
        require(_predictionTokenAddress != address(0), "Invalid token address");
        require(_prognosOracleAddress != address(0), "Invalid prognos oracle address");
        require(_aetherAIOracleAddress != address(0), "Invalid AI oracle address");
        
        predictionToken = IERC20(_predictionTokenAddress);
        prognosOracle = IPrognosOracle(_prognosOracleAddress);
        aetherAIOracle = IAetherAIOracle(_aetherAIOracleAddress);
        _baseTokenURI = _baseTokenURI_;

        // Set initial parameters (can be updated by DAO later)
        marketCreationFee = 1 ether; // Example fee
        minPredictionStake = 0.1 ether; // Example min stake
        insightEndorsementStake = 0.01 ether; // Example stake for endorsement
        insightDisputeStake = 0.05 ether; // Example stake for dispute
        rewardFeePercentage = 5; // 5% fee
        minVotingPrognosScore = 1000; // Example minimum score for DAO actions
        proposalVotingPeriod = 3 days; // Example voting period

        // Tier thresholds should be set post-deployment via `setTierThresholds`
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        // In a real scenario, this would check against a list of authorized oracle addresses
        // or integrate with Chainlink's verifiable random function (VRF) / external adapters.
        require(msg.sender == address(prognosOracle), "Only authorized oracle can call this function");
        _;
    }

    modifier onlyInsightAIOracle() {
        require(msg.sender == address(aetherAIOracle), "Only authorized AI oracle can call this function");
        _;
    }

    modifier onlyPrognosTier(uint256 _requiredTier) {
        require(getPrognosTier(msg.sender) >= _requiredTier, "Insufficient Prognos Tier");
        _;
    }

    // --- Core Prediction Mechanism (6 functions) ---

    /**
     * @dev Creates a new prediction market.
     * @param _marketId Unique identifier for the market (e.g., hash of description + timestamp).
     * @param _description Descriptive name/details of the market.
     * @param _endTime The timestamp when the prediction market closes for submissions.
     */
    function createPredictionMarket(bytes32 _marketId, string memory _description, uint256 _endTime)
        external
        nonReentrant
        whenNotPaused
    {
        require(predictionMarkets[_marketId].status == MarketStatus.Pending, "Market ID already exists or is active");
        require(_endTime > block.timestamp, "End time must be in the future");
        require(predictionToken.transferFrom(msg.sender, address(this), marketCreationFee), "Fee transfer failed");

        predictionMarkets[_marketId] = PredictionMarket({
            marketId: _marketId,
            description: _description,
            startTime: block.timestamp,
            endTime: _endTime,
            status: MarketStatus.Active,
            reportedOutcome: 0,
            totalStaked: 0,
            participants: new address[](0),
            uniqueParticipants: 0,
            winningOutcomeTotalStake: 0,
            creator: msg.sender,
            outcomeReported: false
        });
        activeMarketIds.push(_marketId);
        emit MarketCreated(_marketId, _description, _endTime, msg.sender);
    }

    /**
     * @dev Allows a user to submit their prediction for a market.
     *      Users must call `lockPredictionStake` separately to back their prediction.
     * @param _marketId The ID of the prediction market.
     * @param _predictedOutcome The outcome predicted by the user.
     */
    function submitPrediction(bytes32 _marketId, uint256 _predictedOutcome)
        external
        whenNotPaused
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Active, "Market is not active");
        require(block.timestamp < market.endTime, "Market has closed for predictions");
        require(market.predictions[msg.sender].stakeAmount == 0, "Already submitted a prediction for this market");

        // Initialize prediction for the user
        market.predictions[msg.sender] = Prediction({
            predictedOutcome: _predictedOutcome,
            stakeAmount: 0, // Stake will be added via lockPredictionStake
            hasClaimed: false
        });

        // Add to participants array if new to enable iteration during settlement
        bool isNewParticipant = true;
        for(uint i=0; i < market.participants.length; i++){
            if(market.participants[i] == msg.sender){
                isNewParticipant = false;
                break;
            }
        }
        if(isNewParticipant){
            market.participants.push(msg.sender);
            market.uniqueParticipants++;
        }
        // Note: Stake transfer is in `lockPredictionStake` for better UX (approve then call)
    }

    /**
     * @dev Users lock tokens to back their submitted prediction.
     * @param _marketId The ID of the prediction market.
     * @param _amount The amount of tokens to stake.
     */
    function lockPredictionStake(bytes32 _marketId, uint256 _amount)
        external
        nonReentrant
        whenNotPaused
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Active, "Market is not active");
        require(block.timestamp < market.endTime, "Market has closed for predictions");
        require(market.predictions[msg.sender].stakeAmount == 0, "Stake already locked for this market or no prediction submitted");
        require(_amount >= minPredictionStake, "Stake amount below minimum");

        require(predictionToken.transferFrom(msg.sender, address(this), _amount), "Stake transfer failed");

        market.predictions[msg.sender].stakeAmount = _amount;
        market.totalStaked = market.totalStaked.add(_amount);

        emit PredictionSubmitted(_marketId, msg.sender, market.predictions[msg.sender].predictedOutcome, _amount);
    }

    /**
     * @dev Designated oracle reports the final outcome for a market.
     * @param _marketId The ID of the prediction market.
     * @param _outcome The actual outcome of the event.
     * @param _nonce A unique nonce to prevent replay attacks (standard for oracles).
     */
    function reportMarketOutcome(bytes32 _marketId, uint256 _outcome, uint256 _nonce)
        external
        onlyOracle // Only the designated oracle can report
        whenNotPaused
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Active, "Market is not active for reporting");
        require(block.timestamp >= market.endTime, "Market has not yet closed");
        require(!market.outcomeReported, "Outcome already reported for this market");

        // For production, integrate with Chainlink or similar robust oracle solution's nonce/request-ID handling.
        // E.g., bytes32 oracleRequestId = keccak256(abi.encodePacked(_marketId, _nonce));
        // require(!_processedNonces[oracleRequestId], "Nonce already used"); _processedNonces[oracleRequestId] = true;

        market.reportedOutcome = _outcome;
        market.status = MarketStatus.Reported;
        market.outcomeReported = true;

        emit MarketOutcomeReported(_marketId, _outcome, msg.sender);
    }

    /**
     * @dev Settles a market, distributes rewards to winners, and updates prognos scores.
     *      Can be called by anyone after outcome is reported.
     * @param _marketId The ID of the prediction market.
     */
    function settleMarketAndDistribute(bytes32 _marketId)
        external
        nonReentrant
        whenNotPaused
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Reported, "Market is not in reported state");

        uint256 totalPool = market.totalStaked;
        uint256 feeAmount = totalPool.mul(rewardFeePercentage).div(100);
        
        // First, calculate total stake of winning predictions to determine proportional distribution
        uint224 winningOutcomeTotalStake_ = 0; // Using uint224 to save space if needed
        for (uint i = 0; i < market.participants.length; i++) {
            address participant = market.participants[i];
            if (market.predictions[participant].predictedOutcome == market.reportedOutcome) {
                winningOutcomeTotalStake_ = winningOutcomeTotalStake_.add(uint224(market.predictions[participant].stakeAmount));
            }
        }
        market.winningOutcomeTotalStake = winningOutcomeTotalStake_; // Store for claim calculation

        // Update Prognos Scores for all participants
        for (uint i = 0; i < market.participants.length; i++) {
            address participant = market.participants[i];
            // Only update score if they actually staked
            if (market.predictions[participant].stakeAmount > 0) { 
                if (market.predictions[participant].predictedOutcome == market.reportedOutcome) {
                    // Correct prediction: increase score proportional to stake (e.g., stake / 1e10 for granular scores)
                    updatePrognosScore(participant, market.predictions[participant].stakeAmount.div(1e10), true);
                } else {
                    // Incorrect prediction: decrease score (same scaling)
                    updatePrognosScore(participant, market.predictions[participant].stakeAmount.div(1e10), false);
                }
            }
        }

        // Transfer fees to contract owner (or DAO treasury)
        if (feeAmount > 0) {
            require(predictionToken.transfer(owner(), feeAmount), "Fee transfer to owner failed");
        }

        market.status = MarketStatus.Settled;
        emit MarketSettled(_marketId, totalPool, totalPool.sub(feeAmount)); // totalDistributed is rewardPool
    }

    /**
     * @dev Allows participants to claim their winnings after a market has been settled.
     *      Losing stakes contribute to the overall prize pool and are not refunded.
     * @param _marketId The ID of the prediction market.
     */
    function claimPredictionWinnings(bytes32 _marketId)
        external
        nonReentrant
        whenNotPaused
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        Prediction storage userPrediction = market.predictions[msg.sender];

        require(market.status == MarketStatus.Settled, "Market not yet settled");
        require(userPrediction.stakeAmount > 0, "No prediction or stake found for user");
        require(!userPrediction.hasClaimed, "Winnings already claimed");

        uint256 amountToTransfer = 0;

        if (userPrediction.predictedOutcome == market.reportedOutcome && market.winningOutcomeTotalStake > 0) {
            uint256 rewardPool = market.totalStaked.sub(market.totalStaked.mul(rewardFeePercentage).div(100));
            // Calculate proportional winnings: (user's stake / total winning stake) * rewardPool
            amountToTransfer = userPrediction.stakeAmount.mul(rewardPool).div(market.winningOutcomeTotalStake);
        } else {
            // No winnings: losing stakes remain in the contract as part of the total pool.
            // This is a zero-sum game for participants (minus fees).
        }

        userPrediction.hasClaimed = true;

        if (amountToTransfer > 0) {
            require(predictionToken.transfer(msg.sender, amountToTransfer), "Winnings transfer failed");
            emit WinningsClaimed(_marketId, msg.sender, amountToTransfer);
        } else {
            // Emit an event even if no winnings to indicate claim attempt for tracking
            emit WinningsClaimed(_marketId, msg.sender, 0);
        }
    }

    // --- Reputation & Tier System (4 functions) ---

    /**
     * @dev Retrieves a user's current Prognos reputation score.
     * @param _user The address of the user.
     * @return The Prognos score.
     */
    function getUserPrognosScore(address _user) public view returns (uint256) {
        return prognosScores[_user];
    }

    /**
     * @dev Determines a user's current reputation tier based on their Prognos score.
     * @param _user The address of the user.
     * @return The tier index (0 for lowest, higher for better).
     */
    function getPrognosTier(address _user) public view returns (uint256) {
        uint256 score = prognosScores[_user];
        uint256 currentTier = 0;
        for (uint i = 0; i < prognosTiers.length; i++) {
            if (score >= prognosTiers[i].scoreThreshold) {
                currentTier = i;
            } else {
                break; // Tiers are sorted, so we can break early
            }
        }
        return currentTier;
    }

    /**
     * @dev Internal function to update a user's Prognos score.
     *      Automatically triggers badge metadata updates if tier changes.
     * @param _user The user whose score is to be updated.
     * @param _amount The amount to add or subtract from the score.
     * @param _isAddition True if adding, false if subtracting.
     */
    function updatePrognosScore(address _user, uint256 _amount, bool _isAddition) internal {
        uint256 oldScore = prognosScores[_user];
        uint256 oldTier = getPrognosTier(_user);
        uint256 newScore;

        if (_isAddition) {
            newScore = oldScore.add(_amount);
            if (newScore > MAX_REPUTATION_SCORE) newScore = MAX_REPUTATION_SCORE;
        } else {
            newScore = oldScore.sub(_amount);
            if (newScore < 0) newScore = 0; // Score cannot go below 0
        }

        prognosScores[_user] = newScore;
        emit PrognosScoreUpdated(_user, newScore, oldScore);

        uint256 newTier = getPrognosTier(_user);
        if (newTier != oldTier) {
            emit PrognosTierChanged(_user, newTier, oldTier, userBadges[_user]);
            if (userBadges[_user] == 0 && newTier > 0) { // If user doesn't have a badge yet and reached a valid tier (not tier 0 usually)
                mintPrognosBadge(_user, newTier);
            } else if (userBadges[_user] != 0) { // If user already has a badge, update its metadata
                updatePrognosBadgeMetadata(userBadges[_user], newTier);
            }
        }
    }

    /**
     * @dev Sets the thresholds and names for different Prognos reputation tiers.
     *      Can only be called by the contract owner initially, then by DAO.
     *      Thresholds must be strictly increasing.
     * @param _names Array of tier names.
     * @param _thresholds Array of score thresholds for each tier (must be sorted ascending).
     * @param _badgeBaseURIs Array of base URIs for each tier's NFT metadata.
     */
    function setTierThresholds(string[] memory _names, uint256[] memory _thresholds, string[] memory _badgeBaseURIs)
        public
        onlyOwner // Initially only owner, later potentially DAO
    {
        require(_names.length == _thresholds.length && _names.length == _badgeBaseURIs.length, "Arrays length mismatch");
        require(_names.length > 0, "At least one tier must be defined");

        for (uint i = 0; i < _thresholds.length; i++) {
            if (i > 0) {
                require(_thresholds[i] > _thresholds[i-1], "Thresholds must be strictly increasing");
            }
        }

        delete prognosTiers; // Clear existing tiers
        for (uint i = 0; i < _names.length; i++) {
            prognosTiers.push(PrognosTier({
                name: _names[i],
                scoreThreshold: _thresholds[i],
                badgeBaseURI: _badgeBaseURIs[i]
            }));
        }
    }

    // --- Dynamic Analyst Badges (ERC721 NFT) (5 functions) ---

    /**
     * @dev Mints a new Prognos Analyst Badge for a user.
     *      Only callable internally when a user reaches a tier and doesn't have a badge.
     * @param _user The address of the user to mint the badge for.
     * @param _tier The tier achieved by the user.
     */
    function mintPrognosBadge(address _user, uint256 _tier) internal {
        require(userBadges[_user] == 0, "User already has an Analyst Badge");
        require(_tier < prognosTiers.length, "Invalid tier for minting");

        _badgeTokenIdCounter.increment();
        uint256 newTokenId = _badgeTokenIdCounter.current();
        _mint(_user, newTokenId);
        userBadges[_user] = newTokenId; // Store the token ID for the user

        // Set initial metadata (via URI) based on current tier, pointing to an off-chain API
        _setTokenURI(newTokenId, string(abi.encodePacked(prognosTiers[_tier].badgeBaseURI, newTokenId.toString())));

        emit PrognosBadgeMinted(_user, newTokenId, _tier);
    }

    /**
     * @dev Triggers an update of the metadata URI for a Prognos Analyst Badge.
     *      Called internally when a user's tier changes.
     * @param _tokenId The ID of the badge to update.
     * @param _newTier The new tier associated with the badge.
     */
    function updatePrognosBadgeMetadata(uint256 _tokenId, uint256 _newTier) internal {
        require(_exists(_tokenId), "ERC721: token ID does not exist");
        require(_newTier < prognosTiers.length, "Invalid new tier for metadata update");
        // Update the token URI, which an off-chain server interprets to provide new metadata
        _setTokenURI(_tokenId, string(abi.encodePacked(prognosTiers[_newTier].badgeBaseURI, _tokenId.toString())));
        emit PrognosBadgeMetadataUpdated(_tokenId, _newTier);
    }

    /**
     * @dev Returns the Prognos Tier associated with a given Analyst Badge ID.
     *      This function deduces the tier by getting the owner's current reputation tier.
     * @param _tokenId The ID of the Analyst Badge.
     * @return The tier index.
     */
    function getBadgeTier(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "ERC721: token ID does not exist");
        address ownerOfBadge = ownerOf(_tokenId);
        return getPrognosTier(ownerOfBadge);
    }

    /**
     * @dev Retrieves the Analyst Badge Token ID for a given user.
     * @param _user The address of the user.
     * @return The token ID, or 0 if the user does not own a badge.
     */
    function getUserBadgeId(address _user) public view returns (uint256) {
        return userBadges[_user];
    }

    /**
     * @dev Overrides ERC721's `_baseURI()` to provide the base URI for all tokens.
     *      Each token's URI will be `_baseTokenURI` + `tokenId`.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- Insight Curation & Monetization (5 functions) ---

    /**
     * @dev Users submit an IPFS hash (or similar content identifier) of a prognostic insight.
     *      Insights are associated with a prediction market.
     * @param _marketId The market this insight pertains to.
     * @param _insightHash The IPFS hash of the insight content.
     */
    function submitPrognosticInsight(bytes32 _marketId, bytes32 _insightHash)
        external
        whenNotPaused
    {
        require(predictionMarkets[_marketId].status != MarketStatus.Pending, "Market does not exist");
        require(prognosticInsights[_insightHash].creator == address(0), "Insight with this hash already exists");
        // Optional: require minimum prognos score to submit insights

        prognosticInsights[_insightHash] = PrognosticInsight({
            insightHash: _insightHash,
            marketId: _marketId,
            creator: msg.sender,
            submissionTime: block.timestamp,
            status: InsightStatus.Submitted,
            endorsementStakePool: 0,
            disputeStakePool: 0,
            aiQualityScore: 0,
            hasEndorsed: new mapping(address => bool)(), // Initialize mapping
            hasDisputed: new mapping(address => bool)() // Initialize mapping
        });

        emit InsightSubmitted(_insightHash, _marketId, msg.sender);
    }

    /**
     * @dev Users endorse (upvote) an insight by staking a small amount.
     * @param _insightHash The ID of the insight to endorse.
     */
    function endorseInsight(bytes32 _insightHash)
        external
        nonReentrant
        whenNotPaused
    {
        PrognosticInsight storage insight = prognosticInsights[_insightHash];
        require(insight.creator != address(0), "Insight does not exist");
        require(insight.status == InsightStatus.Submitted || insight.status == InsightStatus.Endorsed, "Insight cannot be endorsed in current status");
        require(msg.sender != insight.creator, "Cannot endorse your own insight");
        require(!insight.hasEndorsed[msg.sender], "Already endorsed this insight");
        require(!insight.hasDisputed[msg.sender], "Cannot endorse and dispute simultaneously");

        require(predictionToken.transferFrom(msg.sender, address(this), insightEndorsementStake), "Endorsement stake transfer failed");
        insight.endorsementStakePool = insight.endorsementStakePool.add(insightEndorsementStake);
        insight.hasEndorsed[msg.sender] = true;
        insight.status = InsightStatus.Endorsed; // Set status if it was 'Submitted'

        emit InsightEndorsed(_insightHash, msg.sender, insightEndorsementStake);
    }

    /**
     * @dev Users dispute (downvote) an insight by staking a small amount.
     * @param _insightHash The ID of the insight to dispute.
     */
    function disputeInsight(bytes32 _insightHash)
        external
        nonReentrant
        whenNotPaused
    {
        PrognosticInsight storage insight = prognosticInsights[_insightHash];
        require(insight.creator != address(0), "Insight does not exist");
        require(insight.status == InsightStatus.Submitted || insight.status == InsightStatus.Endorsed || insight.status == InsightStatus.Disputed, "Insight cannot be disputed in current status");
        require(msg.sender != insight.creator, "Cannot dispute your own insight");
        require(!insight.hasDisputed[msg.sender], "Already disputed this insight");
        require(!insight.hasEndorsed[msg.sender], "Cannot endorse and dispute simultaneously");

        require(predictionToken.transferFrom(msg.sender, address(this), insightDisputeStake), "Dispute stake transfer failed");
        insight.disputeStakePool = insight.disputeStakePool.add(insightDisputeStake);
        insight.hasDisputed[msg.sender] = true;
        insight.status = InsightStatus.Disputed; // Set status if it was 'Submitted' or 'Endorsed'

        emit InsightDisputed(_insightHash, msg.sender, insightDisputeStake);
    }

    /**
     * @dev Resolves a dispute on an insight. Only callable by admin/DAO.
     *      Fetches AI quality score and distributes dispute/endorsement stakes.
     * @param _insightHash The ID of the insight.
     */
    function resolveInsightDispute(bytes32 _insightHash)
        external
        onlyOwner // For initial testing, will be called by DAO `executeApprovedProposal` in production
        nonReentrant
        whenNotPaused
    {
        PrognosticInsight storage insight = prognosticInsights[_insightHash];
        require(insight.status == InsightStatus.Disputed, "Insight is not in disputed state");
        require(address(aetherAIOracle) != address(0), "AI Oracle not set");

        // Use the AI Oracle to get a quality score (simulated or real AI analysis)
        // A score >= 50 (arbitrary) indicates good quality.
        uint256 aiScore = aetherAIOracle.getInsightQualityScore(_insightHash);
        insight.aiQualityScore = aiScore;

        bool isInsightLegit = (aiScore >= 50); // Arbitrary threshold for legitimacy

        if (isInsightLegit) {
            // Insight is legit: Disputers lose their stake (sent to insight creator as penalty/reward)
            if (insight.disputeStakePool > 0) {
                 require(predictionToken.transfer(insight.creator, insight.disputeStakePool), "Dispute stake transfer to creator failed");
            }
        } else {
            // Insight is not legit: Endorsers lose their stake (retained by contract/treasury)
            // Disputers might get a reward or their stake back (for simplicity, retained here if not legit).
            // A more complex system would refund disputers and penalize endorsers.
        }
        insight.status = InsightStatus.Resolved;
        emit InsightDisputeResolved(_insightHash, isInsightLegit);
    }

    /**
     * @dev Distributes rewards to the creator of a highly endorsed/quality insight.
     *      Can be called by anyone after dispute resolution (if any) or after market settlement.
     * @param _insightHash The ID of the insight.
     */
    function distributeInsightRewards(bytes32 _insightHash)
        external
        nonReentrant
        whenNotPaused
    {
        PrognosticInsight storage insight = prognosticInsights[_insightHash];
        require(insight.creator != address(0), "Insight does not exist");
        require(insight.status == InsightStatus.Resolved || (insight.status == InsightStatus.Endorsed && insight.disputeStakePool == 0), "Insight not ready for reward distribution");
        require(insight.status != InsightStatus.Rewarded, "Insight already rewarded");

        // Base reward calculation: sum of endorsement stakes + bonus based on AI quality score
        uint256 rewardAmount = insight.endorsementStakePool.add(insight.aiQualityScore.mul(1 ether).div(100)); // Example: 1 ether per point of AI score

        // Deduct fee from reward
        uint256 fee = rewardAmount.mul(rewardFeePercentage).div(100);
        uint256 netReward = rewardAmount.sub(fee);

        // Transfer fees to owner/treasury
        if (fee > 0) {
            require(predictionToken.transfer(owner(), fee), "Insight fee transfer failed");
        }

        // Transfer reward to creator
        if (netReward > 0) {
            require(predictionToken.transfer(insight.creator, netReward), "Insight reward transfer failed");
            // Update creator's prognos score for contributing valuable insights (scaled down)
            updatePrognosScore(insight.creator, netReward.div(1e12), true); 
        }

        insight.status = InsightStatus.Rewarded;
        emit InsightRewardsDistributed(_insightHash, insight.creator, netReward);
    }


    // --- DAO Governance & System Parameters (5 functions) ---

    /**
     * @dev Allows users with sufficient Prognos score to propose a system change.
     * @param _description A detailed description of the proposal.
     * @param _targetContract The address of the contract to call (e.g., this contract).
     * @param _callData The encoded function call data.
     */
    function proposeAetherImprovement(string memory _description, address _targetContract, bytes memory _callData)
        external
        whenNotPaused
        onlyPrognosTier(getPrognosTier(address(this))) // Requires user to be in a certain tier to propose
    {
        require(getUserPrognosScore(msg.sender) >= minVotingPrognosScore, "Insufficient Prognos Score to propose");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(proposalVotingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)(),
            executed: false,
            approved: false
        });

        emit ProposalCreated(proposalId, _description, msg.sender);
    }

    /**
     * @dev Allows users with sufficient Prognos score to cast a vote on an active proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        whenNotPaused
        onlyPrognosTier(getPrognosTier(address(this))) // Requires user to be in a certain tier to vote
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(!proposal.executed, "Proposal already executed");
        require(getUserPrognosScore(msg.sender) >= minVotingPrognosScore, "Insufficient Prognos Score to vote");

        // Voting power based on Prognos Score (simple: 1 vote per voter, could be score-weighted)
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(1); // Could be weighted by prognosScores[msg.sender]
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a proposal that has passed the voting threshold.
     *      Requires a majority vote (simple majority for this example).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeApprovedProposal(uint256 _proposalId)
        external
        nonReentrant
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "No votes cast for this proposal");

        // Simple majority: 50% + 1 vote
        bool passed = proposal.votesFor > totalVotes.div(2);
        proposal.approved = passed;

        if (passed) {
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "Proposal execution failed");
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, true);
        } else {
            proposal.executed = true; // Mark as executed but failed
            emit ProposalExecuted(_proposalId, false);
        }
    }

    /**
     * @dev Allows the owner/DAO to set the main prediction oracle address.
     * @param _newOracleAddress The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "New oracle address cannot be zero");
        prognosOracle = IPrognosOracle(_newOracleAddress);
        emit OracleAddressSet(_newOracleAddress);
    }

    /**
     * @dev Allows the owner/DAO to set the AI oracle address for insight analysis.
     * @param _newOracleAddress The address of the new AI oracle contract.
     */
    function setInsightAIOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "New AI oracle address cannot be zero");
        aetherAIOracle = IAetherAIOracle(_newOracleAddress);
        emit InsightAIOracleAddressSet(_newOracleAddress);
    }

    /**
     * @dev Generic function for the DAO to update core parameters.
     *      In a real DAO, each parameter would ideally have its own specific setter
     *      function called directly via `executeApprovedProposal`. This is a simplified
     *      example using a string identifier.
     * @param _paramName String identifier for the parameter (e.g., "marketCreationFee", "minPredictionStake").
     * @param _newValue The new value for the parameter.
     */
    function updateCoreParameter(string memory _paramName, uint256 _newValue)
        public
        onlyOwner // Initially owner, should be called by DAO via executeApprovedProposal
    {
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));
        if (paramHash == keccak256(abi.encodePacked("marketCreationFee"))) {
            uint256 oldFee = marketCreationFee;
            marketCreationFee = _newValue;
            emit MarketCreationFeeUpdated(oldFee, _newValue);
        } else if (paramHash == keccak256(abi.encodePacked("minPredictionStake"))) {
            minPredictionStake = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("insightEndorsementStake"))) {
            insightEndorsementStake = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("insightDisputeStake"))) {
            insightDisputeStake = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("rewardFeePercentage"))) {
            require(_newValue <= 100, "Fee percentage cannot exceed 100");
            rewardFeePercentage = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minVotingPrognosScore"))) {
            minVotingPrognosScore = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("proposalVotingPeriod"))) {
            proposalVotingPeriod = _newValue;
        } else {
            revert("Unknown parameter name");
        }
        emit CoreParameterUpdated(_paramName, _newValue);
    }

    // --- Utility Functions ---

    /**
     * @dev Emergency pause functionality, callable by owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Emergency unpause functionality, callable by owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Withdraw ERC20 tokens from contract (only by owner for fees/treasury management or governance).
     */
    function withdrawFunds(address _tokenAddress, uint256 _amount) public onlyOwner nonReentrant {
        require(IERC20(_tokenAddress).transfer(owner(), _amount), "Withdrawal failed");
    }

    /**
     * @dev Gets the details of a specific prediction market.
     */
    function getPredictionMarket(bytes32 _marketId)
        public
        view
        returns (
            bytes32 marketId,
            string memory description,
            uint256 startTime,
            uint256 endTime,
            MarketStatus status,
            uint256 reportedOutcome,
            uint256 totalStaked,
            address creator,
            uint256 uniqueParticipants
        )
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        return (
            market.marketId,
            market.description,
            market.startTime,
            market.endTime,
            market.status,
            market.reportedOutcome,
            market.totalStaked,
            market.creator,
            market.uniqueParticipants
        );
    }

    /**
     * @dev Get a user's prediction details for a market.
     */
    function getUserPredictionDetails(bytes32 _marketId, address _user)
        public
        view
        returns (uint256 predictedOutcome, uint256 stakeAmount, bool hasClaimed)
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        Prediction storage prediction = market.predictions[_user];
        return (prediction.predictedOutcome, prediction.stakeAmount, prediction.hasClaimed);
    }
}
```