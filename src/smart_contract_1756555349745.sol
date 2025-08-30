The `AuraSynthCollective` protocol is a decentralized platform designed to leverage collective intelligence for advanced, adaptive asset management. It introduces "AuraSynthesizers" – users who contribute market predictions and build a reputation based on their accuracy. This reputation is tied to dynamic Soulbound-like NFTs, allowing for visual representation of expertise. The protocol aggregates these reputation-weighted predictions into a "Consensus Aura," a collective intelligence signal that informs asset allocation strategies for an associated on-chain vault. It incorporates a comprehensive prediction market, a novel reputation system with decay, and a dispute resolution mechanism to ensure integrity and incentivize continuous, accurate participation.

### Outline of AuraSynthCollective Contract

**I. Core Administration & Configuration:**
   *   Initialization of contract and external dependencies.
   *   Management of global parameters (epoch duration, decay rates, fees).

**II. AuraSynthesizer (User) Management:**
   *   Registration of users as "AuraSynthesizers" with an associated dynamic NFT.
   *   Retrieval of user-specific data and NFT details.

**III. Prediction Market Management:**
   *   Process for proposing and defining new prediction markets.
   *   Mechanism for users to submit and cancel predictions with a stake.
   *   Oracle integration for reporting market outcomes.
   *   Market resolution, including accuracy scoring, reputation updates, and reward distribution.

**IV. Reputation & Reward System:**
   *   Calculation and dynamic adjustment of user reputation based on prediction performance.
   *   Distribution of AST token rewards to accurate predictors.
   *   System for reputation decay to ensure active engagement.

**V. Collective Aura Synthesis & Asset Strategy:**
   *   Aggregation of reputation-weighted predictions to form the "Consensus Aura."
   *   Conceptual framework for generating asset allocation recommendations.
   *   Functionality to trigger actual asset rebalancing in an associated vault based on the Consensus Aura.

**VI. Dispute & Governance:**
   *   System for users to dispute reported oracle outcomes.
   *   Voting mechanism for resolving disputes, with vote weight tied to reputation.
   *   Access control and ownership for critical administrative functions.

### Function Summary

**I. Core Administration & Configuration:**
1.  `constructor(address _astToken, address _auraNFT, address _auraVault, address _oracleFeed, address _trustedOracleAddress)`: Initializes the contract with addresses of core dependencies (AuraSynthToken, AuraSynthesizerNFT, AuraVault, OracleFeed) and sets initial parameters.
2.  `updateDependencyAddress(bytes32 _key, address _newAddress)`: Allows governance to update addresses of external dependencies like `auraSynthesizerNFT`, `auraVault`, `oracleFeed`, or `trustedOracleAddress`.
3.  `setEpochDuration(uint256 _newDuration)`: Sets the duration of a prediction epoch (e.g., 1 day, 1 week) in seconds.
4.  `setReputationDecayRate(uint256 _newRateBasisPoints)`: Sets the annual decay rate for reputation in basis points (e.g., 100 for 1%).
5.  `setMarketCreationFee(uint256 _fee)`: Sets the AST token fee required to propose a new prediction market.

**II. AuraSynthesizer (User) Management:**
6.  `registerAuraSynthesizer()`: Allows a user to mint their unique AuraSynthesizer NFT, representing their identity and reputation within the collective.
7.  `getAuraSynthesizerId(address _user)`: Retrieves the `tokenId` of the AuraSynthesizer NFT owned by a given user address.
8.  `getAuraSynthesizerReputation(uint256 _tokenId)`: Returns the current reputation score (scaled by `REPUTATION_SCALE`) associated with a specific AuraSynthesizer NFT, applying decay.

**III. Prediction Market Management:**
9.  `proposePredictionMarket(string memory _topic, uint256 _submissionEndTime, uint256 _resolutionTime, bytes32[] memory _possibleOutcomes)`: Allows a user (with sufficient reputation or by paying a fee) to propose a new market topic for predictions, defining its duration and possible outcomes.
10. `submitPrediction(uint256 _marketId, bytes32 _predictedOutcome, uint256 _stakeAmount)`: Allows a registered AuraSynthesizer to submit their prediction for a specific market, staking AST tokens.
11. `cancelPrediction(uint256 _marketId)`: Allows a user to cancel their own prediction and reclaim their stake before the `submissionEndTime`.
12. `oracleReportOutcome(uint256 _marketId, bytes32 _actualOutcome, uint256 _outcomeTimestamp)`: (Callable by `trustedOracleAddress`) Reports the actual outcome of a prediction market once it's resolved.
13. `resolveMarketAndDistribute(uint256 _marketId)`: Processes a resolved market, scores predictions, updates user reputations, and distributes rewards to accurate predictors.
14. `getUserPrediction(uint256 _marketId, address _user)`: Retrieves the prediction, stake, and accuracy status of a user for a given market.

**IV. Reputation & Reward System:**
15. `claimPredictionRewards(uint256[] memory _marketIds)`: Allows users to claim their earned AST tokens from one or more resolved prediction markets.
16. `getAuraReputation(address _user)`: Returns the current reputation score (scaled by `REPUTATION_SCALE`) for a specific user address, factoring in decay.
17. `getMarketRewardPool(uint256 _marketId)`: Returns the total amount of AST tokens accumulated as rewards (total stakes) for a specific market.

**V. Collective Aura Synthesis & Asset Strategy:**
18. `getCurrentConsensusAura(uint256 _epochId)`: Calculates and returns the aggregated "Consensus Aura" for a given epoch, representing the collective, reputation-weighted prediction and its overall accuracy.
19. `triggerStrategyExecution(uint256 _epochId, uint256[] memory assetIds, uint256[] memory newAllocationsBasisPoints)`: (Callable by governance or authorized keeper) Executes the asset rebalancing strategy in the associated `IAuraVault` based on the `ConsensusAura`.
20. `getRecommendedAllocation(uint256 _epochId)`: Returns the recommended asset allocation (conceptual, derived from `ConsensusAura`) for a given epoch, for display or off-chain analysis.

**VI. Dispute & Governance:**
21. `submitDispute(uint256 _marketId, string memory _reason)`: Allows a user to formally dispute an `oracleReportOutcome`, requiring an AST deposit.
22. `voteOnDispute(uint256 _disputeId, bool _support)`: Allows reputable AuraSynthesizers to vote on pending disputes, with vote weight proportional to reputation.
23. `resolveDispute(uint256 _disputeId)`: Resolves a dispute after its voting period, potentially overturning the oracle outcome and refunding the challenger's deposit.
24. `getDisputeDetails(uint256 _disputeId)`: Retrieves the full details of a specific dispute.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For the AuraSynthesizerNFT contract
import "@openzeppelin/contracts/utils/Strings.sol"; // For generating token URI example

// --- Interfaces for External Contracts ---

/**
 * @title IAuraDataFeed
 * @notice Interface for an external oracle service providing market data or event outcomes.
 */
interface IAuraDataFeed {
    /**
     * @notice Retrieves the latest data point for a given key.
     * @param _key A unique identifier for the data feed (e.g., keccak256("ETH/USD_PRICE")).
     * @return value The data value (e.g., price, outcome ID).
     * @return timestamp The timestamp when the data was last updated.
     */
    function getLatestData(bytes32 _key) external view returns (uint256 value, uint256 timestamp);
}

/**
 * @title IAuraVault
 * @notice Interface for an external asset management vault.
 *         This vault holds and rebalances assets based on strategies recommended by AuraSynthCollective.
 */
interface IAuraVault {
    /**
     * @notice Rebalances assets in the vault according to new allocation percentages.
     * @param assetIds Identifiers for different assets (e.g., token addresses, internal IDs).
     * @param newAllocationsBasisPoints New allocation percentages in basis points (e.g., 5000 for 50%).
     *         The sum of `newAllocationsBasisPoints` should typically be 10000.
     */
    function rebalanceAssets(uint256[] memory assetIds, uint256[] memory newAllocationsBasisPoints) external;
    
    /**
     * @notice Allows depositing a specific token into the vault.
     * @param token The ERC20 token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(IERC20 token, uint256 amount) external;

    /**
     * @notice Allows withdrawing a specific token from the vault.
     * @param token The ERC20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(IERC20 token, uint256 amount) external;
}

/**
 * @title IAuraSynthesizerNFT
 * @notice Interface for the AuraSynthesizer NFT contract, representing user identity and reputation.
 */
interface IAuraSynthesizerNFT {
    /**
     * @notice Mints a new AuraSynthesizer NFT for a given address.
     * @param _to The address to mint the NFT to.
     * @param _tokenURI The initial URI for the NFT metadata.
     * @return The ID of the newly minted token.
     */
    function mint(address _to, string memory _tokenURI) external returns (uint256);

    /**
     * @notice Updates the token URI for an existing AuraSynthesizer NFT.
     *         This enables dynamic NFT properties based on reputation changes.
     * @param _tokenId The ID of the NFT to update.
     * @param _newTokenURI The new URI for the NFT metadata.
     */
    function updateTokenURI(uint256 _tokenId, string memory _newTokenURI) external;

    /**
     * @notice Returns the owner of a specific NFT.
     * @param tokenId The ID of the NFT.
     * @return The address of the NFT owner.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @notice Returns the URI for a specific NFT.
     * @param tokenId The ID of the NFT.
     * @return The URI string.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @title AuraSynthesizerNFT
 * @notice A Soulbound-like NFT contract representing a user's identity and reputation
 *         within the AuraSynthCollective. Its metadata can be dynamically updated
 *         by the `AuraSynthCollective` contract to reflect changes in reputation.
 */
contract AuraSynthesizerNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // The address of the AuraSynthCollective contract, which is authorized to mint and update NFTs.
    address public auraSynthCollectiveAddress;

    /**
     * @notice Constructs the AuraSynthesizerNFT contract.
     * @param _auraSynthCollectiveAddress The address of the main AuraSynthCollective contract.
     */
    constructor(address _auraSynthCollectiveAddress) ERC721("AuraSynthesizer NFT", "AS-NFT") {
        require(_auraSynthCollectiveAddress != address(0), "AuraSynthCollective address cannot be zero");
        auraSynthCollectiveAddress = _auraSynthCollectiveAddress;
    }

    /**
     * @dev Modifier to restrict functions to be callable only by the AuraSynthCollective contract.
     */
    modifier onlyAuraSynthCollective() {
        require(msg.sender == auraSynthCollectiveAddress, "Not AuraSynthCollective contract");
        _;
    }

    /**
     * @notice Mints a new AuraSynthesizer NFT. Callable only by `AuraSynthCollective`.
     * @param _to The address to mint the NFT to.
     * @param _tokenURI The initial URI for the NFT metadata.
     * @return The ID of the newly minted token.
     */
    function mint(address _to, string memory _tokenURI) external onlyAuraSynthCollective returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(_to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        return newItemId;
    }

    /**
     * @notice Updates the token URI for an existing AuraSynthesizer NFT.
     *         Callable only by `AuraSynthCollective`. This enables dynamic NFT metadata.
     * @param _tokenId The ID of the NFT to update.
     * @param _newTokenURI The new URI for the NFT metadata.
     */
    function updateTokenURI(uint256 _tokenId, string memory _newTokenURI) external onlyAuraSynthCollective {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        _setTokenURI(_tokenId, _newTokenURI);
    }
}


/**
 * @title AuraSynthCollective
 * @notice A decentralized protocol for reputation-weighted collective intelligence,
 *         driving adaptive asset management strategies.
 *         Users ("AuraSynthesizers") submit predictions, earn reputation for accuracy,
 *         and contribute to a "Consensus Aura" that informs an associated asset vault.
 */
contract AuraSynthCollective is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Constants ---
    uint256 public constant REPUTATION_SCALE = 1e18; // For fixed-point arithmetic (1.0 = 1e18)
    uint256 public constant BASIS_POINTS_DIVISOR = 10000; // For percentages (e.g., 5000 = 50%)
    uint256 public constant SECONDS_IN_YEAR = 31536000; // Average seconds in a non-leap year

    // --- External Contract References ---
    IERC20 public immutable AST_TOKEN; // AuraSynthToken for staking and rewards
    IAuraSynthesizerNFT public auraSynthesizerNFT; // NFT representing user identity and reputation
    IAuraVault public auraVault; // Vault for executing asset management strategies
    IAuraDataFeed public oracleFeed; // Oracle for resolving prediction market outcomes

    // --- Configuration Parameters (set by governance) ---
    uint256 public epochDuration; // Duration of a prediction epoch in seconds
    uint256 public reputationDecayRateBasisPoints; // Annual decay rate for reputation (e.g., 100 = 1%)
    uint256 public marketCreationFee; // AST fee to propose a new prediction market (scaled by REPUTATION_SCALE)
    address public trustedOracleAddress; // Address authorized to call oracleReportOutcome (can be an EOA or a multi-sig/DAO)

    // --- State Variables: User Management ---
    mapping(address => uint256) public userToSynthesizerId; // User address -> AuraSynthesizer NFT ID
    mapping(uint256 => uint256) public synthesizerIdToReputation; // AuraSynthesizer NFT ID -> Reputation score (scaled)
    mapping(uint256 => uint256) public synthesizerIdToLastReputationUpdate; // Last timestamp reputation was updated/decayed

    // --- State Variables: Prediction Markets ---
    Counters.Counter private _marketIdCounter;

    enum MarketStatus { Proposed, Open, Resolved, Disputed, Closed, Invalidated }

    struct PredictionMarket {
        string topic;
        uint256 submissionEndTime;
2        uint256 resolutionTime;
        bytes32[] possibleOutcomes; // Hashed outcomes, e.g., keccak256("Up"), keccak256("Down")
        uint256 totalStaked; // Total AST staked in this market
        bytes32 actualOutcome; // The outcome reported by the oracle
        uint256 outcomeTimestamp; // Timestamp when the outcome was reported
        MarketStatus status;
        bool rewardsDistributed;
    }
    mapping(uint256 => PredictionMarket) public predictionMarkets;

    // This mapping stores the list of addresses that have predicted in a given market.
    mapping(uint256 => address[]) private marketPredictorsList; 

    struct UserPrediction {
        bytes32 predictedOutcome;
        uint256 stakeAmount;
        bool claimedRewards;
        uint256 rewardAmount; // Stored reward amount for easier claiming
        bool hasPredicted; // To check if a user has predicted in a market
    }
    mapping(uint256 => mapping(address => UserPrediction)) public userPredictions; // marketId -> userAddress -> UserPrediction

    // --- State Variables: Disputes ---
    Counters.Counter private _disputeIdCounter;
    
    enum DisputeStatus { Open, ResolvedUpheld, ResolvedOverturned, Closed }

    struct Dispute {
        uint256 marketId;
        address challenger;
        string reason;
        uint256 challengeDeposit; // AST deposit by challenger
        uint256 startTime;
        uint256 endTime; // Period for dispute voting
        uint256 votesForOverturn; // Sum of reputation-weighted votes
        uint256 votesForUphold; // Sum of reputation-weighted votes
        DisputeStatus status;
        bool depositRefunded;
    }
    mapping(uint256 => Dispute) public disputes;
    // To prevent double voting on a dispute
    mapping(uint256 => mapping(address => bool)) public hasVotedOnDispute;

    // --- Events ---
    event AuraSynthesizerRegistered(address indexed user, uint256 indexed tokenId);
    event ReputationUpdated(uint256 indexed tokenId, uint256 oldReputation, uint256 newReputation);
    event MarketProposed(uint256 indexed marketId, string topic, address indexed proposer);
    event PredictionSubmitted(uint256 indexed marketId, address indexed predictor, bytes32 predictedOutcome, uint256 stakeAmount);
    event PredictionCancelled(uint256 indexed marketId, address indexed predictor, uint256 stakeRefunded);
    event OutcomeReported(uint256 indexed marketId, bytes32 actualOutcome, uint256 timestamp);
    event MarketResolved(uint256 indexed marketId, bytes32 actualOutcome, uint256 totalRewardsDistributed);
    event RewardsClaimed(uint256 indexed marketId, address indexed user, uint256 amount);
    event ConsensusAuraGenerated(uint256 indexed epochId, bytes32 consensusOutcome, uint256 avgAccuracy);
    event StrategyExecuted(uint256 indexed epochId, address indexed vault, uint256[] assetIds, uint256[] newAllocations);
    event DisputeSubmitted(uint256 indexed disputeId, uint256 indexed marketId, address indexed challenger);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool support);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status);

    // --- Constructor ---
    /**
     * @notice Initializes the AuraSynthCollective contract.
     * @param _astToken The address of the AuraSynth ERC20 token.
     * @param _auraNFT The address of the AuraSynthesizerNFT contract.
     * @param _auraVault The address of the IAuraVault contract.
     * @param _oracleFeed The address of the IAuraDataFeed oracle.
     * @param _trustedOracleAddress The address authorized to report outcomes.
     */
    constructor(
        address _astToken,
        address _auraNFT,
        address _auraVault,
        address _oracleFeed,
        address _trustedOracleAddress
    ) Ownable(msg.sender) {
        require(_astToken != address(0), "Invalid AST token address");
        require(_auraNFT != address(0), "Invalid AuraNFT address");
        require(_auraVault != address(0), "Invalid AuraVault address");
        require(_oracleFeed != address(0), "Invalid OracleFeed address");
        require(_trustedOracleAddress != address(0), "Invalid Trusted Oracle address");

        AST_TOKEN = IERC20(_astToken);
        auraSynthesizerNFT = IAuraSynthesizerNFT(_auraNFT);
        auraVault = IAuraVault(_auraVault);
        oracleFeed = IAuraDataFeed(_oracleFeed);
        trustedOracleAddress = _trustedOracleAddress;

        epochDuration = 7 days; // Default: 1 week
        reputationDecayRateBasisPoints = 100; // Default: 1% per year (100 / 10000 = 0.01)
        marketCreationFee = 10 * REPUTATION_SCALE; // Default: 10 AST tokens (scaled)
    }

    // --- I. Core Administration & Configuration ---

    /**
     * @notice Allows governance to update addresses of external dependencies.
     * @param _key Identifier for the dependency (e.g., keccak256("AuraNFT"), keccak256("AuraVault")).
     * @param _newAddress The new address for the dependency.
     */
    function updateDependencyAddress(bytes32 _key, address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid new address");
        if (_key == keccak256("AuraNFT")) {
            auraSynthesizerNFT = IAuraSynthesizerNFT(_newAddress);
        } else if (_key == keccak256("AuraVault")) {
            auraVault = IAuraVault(_newAddress);
        } else if (_key == keccak256("OracleFeed")) {
            oracleFeed = IAuraDataFeed(_newAddress);
        } else if (_key == keccak256("TrustedOracleAddress")) {
            trustedOracleAddress = _newAddress;
        } else {
            revert("Unknown dependency key");
        }
    }

    /**
     * @notice Sets the duration for prediction epochs.
     * @param _newDuration The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0, "Epoch duration must be positive");
        epochDuration = _newDuration;
    }

    /**
     * @notice Sets the annual reputation decay rate.
     * @param _newRateBasisPoints New decay rate in basis points (e.g., 100 for 1%).
     */
    function setReputationDecayRate(uint256 _newRateBasisPoints) external onlyOwner {
        require(_newRateBasisPoints <= BASIS_POINTS_DIVISOR, "Decay rate cannot exceed 100%");
        reputationDecayRateBasisPoints = _newRateBasisPoints;
    }

    /**
     * @notice Sets the AST token fee required to propose a new prediction market.
     * @param _fee The new market creation fee in AST (scaled).
     */
    function setMarketCreationFee(uint256 _fee) external onlyOwner {
        marketCreationFee = _fee;
    }

    // --- II. AuraSynthesizer (User) Management ---

    /**
     * @notice Allows a user to mint their unique AuraSynthesizer NFT.
     *         This NFT represents their identity and reputation within the collective.
     *         Initial reputation is 0.
     *         Requires the AuraSynthesizerNFT contract to be initialized with this contract's address.
     */
    function registerAuraSynthesizer() external nonReentrant {
        require(userToSynthesizerId[msg.sender] == 0, "User already has an AuraSynthesizer");

        uint256 tokenId = auraSynthesizerNFT.mint(msg.sender, string(abi.encodePacked("ipfs://aura-synthesizer/", Strings.toString(block.timestamp), ".json")));
        userToSynthesizerId[msg.sender] = tokenId;
        synthesizerIdToLastReputationUpdate[tokenId] = block.timestamp; // Initialize for decay calculation
        emit AuraSynthesizerRegistered(msg.sender, tokenId);
    }

    /**
     * @notice Retrieves the tokenId of the AuraSynthesizer NFT owned by a given user address.
     * @param _user The address of the user.
     * @return The tokenId of the user's AuraSynthesizer NFT, or 0 if not registered.
     */
    function getAuraSynthesizerId(address _user) external view returns (uint256) {
        return userToSynthesizerId[_user];
    }

    /**
     * @notice Returns the current reputation score associated with a specific AuraSynthesizer NFT.
     *         Automatically applies decay before returning the current score.
     * @param _tokenId The ID of the AuraSynthesizer NFT.
     * @return The reputation score, scaled by REPUTATION_SCALE.
     */
    function getAuraSynthesizerReputation(uint256 _tokenId) public view returns (uint256) {
        if (_tokenId == 0) return 0; // No reputation for unregistered
        uint256 currentRep = synthesizerIdToReputation[_tokenId];
        uint256 lastUpdate = synthesizerIdToLastReputationUpdate[_tokenId];

        if (reputationDecayRateBasisPoints > 0 && currentRep > 0 && lastUpdate < block.timestamp) {
            uint256 timeElapsed = block.timestamp.sub(lastUpdate);
            // Calculate decay based on time elapsed and annual rate.
            // Simplified linear decay: (rate / 1 year_in_seconds) per second.
            uint256 decayAmount = currentRep.mul(reputationDecayRateBasisPoints).mul(timeElapsed).div(BASIS_POINTS_DIVISOR).div(SECONDS_IN_YEAR);
            
            return currentRep.sub(decayAmount);
        }
        return currentRep;
    }
    
    /**
     * @notice Internal function to update the reputation of a specific AuraSynthesizer.
     *         Applies decay before adding/subtracting the delta.
     * @param _tokenId The ID of the AuraSynthesizer NFT.
     * @param _deltaReputation The amount to add or subtract from reputation (scaled by REPUTATION_SCALE).
     * @param _isAddition True if adding, false if subtracting.
     */
    function _updateAuraSynthesizerReputation(uint256 _tokenId, uint256 _deltaReputation, bool _isAddition) internal {
        uint256 currentRep = getAuraSynthesizerReputation(_tokenId); // Get decayed reputation
        uint256 newRep;

        if (_isAddition) {
            newRep = currentRep.add(_deltaReputation);
        } else {
            newRep = currentRep.sub(_deltaReputation); // Will revert if currentRep < _deltaReputation
        }
        
        synthesizerIdToReputation[_tokenId] = newRep;
        synthesizerIdToLastReputationUpdate[_tokenId] = block.timestamp; // Update last decay timestamp
        emit ReputationUpdated(_tokenId, currentRep, newRep);

        // Optional: Trigger NFT URI update based on reputation tiers (e.g., for dynamic visuals)
        // Example: if (newRep >= TIER_3_REP_THRESHOLD) auraSynthesizerNFT.updateTokenURI(_tokenId, "ipfs://tier3-aura-uri");
        // This dynamic NFT update based on reputation is a core advanced feature.
        // The actual URI logic would be external or more complex, but the hook is here.
    }

    // --- III. Prediction Market Management ---

    /**
     * @notice Allows a user to propose a new market topic for predictions.
     *         Requires an AST fee to prevent spam.
     * @param _topic A descriptive string for the market (e.g., "ETH Price above $3000 by Jan 1, 2025").
     * @param _submissionEndTime Timestamp when predictions close.
     * @param _resolutionTime Timestamp when the market is expected to be resolved by the oracle.
     * @param _possibleOutcomes An array of hashed possible outcomes (e.g., keccak256("YES"), keccak256("NO")).
     */
    function proposePredictionMarket(
        string memory _topic,
        uint256 _submissionEndTime,
        uint256 _resolutionTime,
        bytes32[] memory _possibleOutcomes
    ) external nonReentrant {
        require(userToSynthesizerId[msg.sender] != 0, "Only registered AuraSynthesizers can propose markets");
        require(block.timestamp < _submissionEndTime, "Submission end time must be in the future");
        require(_submissionEndTime < _resolutionTime, "Resolution time must be after submission end time");
        require(_possibleOutcomes.length >= 2, "Must have at least two possible outcomes");

        // Collect market creation fee
        require(AST_TOKEN.transferFrom(msg.sender, address(this), marketCreationFee), "AST transfer failed for market creation fee");

        _marketIdCounter.increment();
        uint256 newMarketId = _marketIdCounter.current();

        predictionMarkets[newMarketId] = PredictionMarket({
            topic: _topic,
            submissionEndTime: _submissionEndTime,
            resolutionTime: _resolutionTime,
            possibleOutcomes: _possibleOutcomes,
            totalStaked: 0,
            actualOutcome: bytes32(0),
            outcomeTimestamp: 0,
            status: MarketStatus.Open,
            rewardsDistributed: false
        });

        emit MarketProposed(newMarketId, _topic, msg.sender);
    }

    /**
     * @notice Allows a registered AuraSynthesizer to submit their prediction for a specific market.
     *         Requires staking AST tokens.
     * @param _marketId The ID of the prediction market.
     * @param _predictedOutcome The hashed outcome the user is predicting.
     * @param _stakeAmount The amount of AST tokens to stake.
     */
    function submitPrediction(uint256 _marketId, bytes32 _predictedOutcome, uint256 _stakeAmount) external nonReentrant {
        require(userToSynthesizerId[msg.sender] != 0, "User not a registered AuraSynthesizer");
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Open, "Market is not open for predictions");
        require(block.timestamp < market.submissionEndTime, "Prediction submission time has ended");
        require(_stakeAmount > 0, "Stake amount must be positive");
        
        UserPrediction storage userPred = userPredictions[_marketId][msg.sender];
        require(!userPred.hasPredicted, "User already predicted in this market");

        // Verify predicted outcome is one of the possible outcomes
        bool isValidOutcome = false;
        for (uint i = 0; i < market.possibleOutcomes.length; i++) {
            if (market.possibleOutcomes[i] == _predictedOutcome) {
                isValidOutcome = true;
                break;
            }
        }
        require(isValidOutcome, "Predicted outcome is not valid for this market");

        require(AST_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount), "AST transfer failed for stake");

        userPred.predictedOutcome = _predictedOutcome;
        userPred.stakeAmount = _stakeAmount;
        userPred.hasPredicted = true;
        
        marketPredictorsList[_marketId].push(msg.sender); // Add user to the list of predictors for this market

        market.totalStaked = market.totalStaked.add(_stakeAmount);

        emit PredictionSubmitted(_marketId, msg.sender, _predictedOutcome, _stakeAmount);
    }

    /**
     * @notice Allows a user to cancel their own prediction and reclaim their stake before the submission end time.
     * @param _marketId The ID of the prediction market.
     */
    function cancelPrediction(uint256 _marketId) external nonReentrant {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Open, "Market is not open");
        require(block.timestamp < market.submissionEndTime, "Cannot cancel after submission ends");

        UserPrediction storage userPred = userPredictions[_marketId][msg.sender];
        require(userPred.hasPredicted, "No prediction found for this user in this market");
        require(userPred.stakeAmount > 0, "No stake to reclaim");

        uint256 stakeToRefund = userPred.stakeAmount;
        market.totalStaked = market.totalStaked.sub(stakeToRefund);

        // Reset user's prediction data
        userPred.predictedOutcome = bytes32(0);
        userPred.stakeAmount = 0;
        userPred.hasPredicted = false;
        // Note: Removing from marketPredictorsList is gas intensive. For simplicity, we keep it,
        // but exclude canceled predictions during resolution.

        require(AST_TOKEN.transfer(msg.sender, stakeToRefund), "AST refund failed");
        emit PredictionCancelled(_marketId, msg.sender, stakeToRefund);
    }

    /**
     * @notice (Callable by trusted oracle address) Reports the actual outcome of a prediction market.
     *         Can only be called once, after submission ends and resolution time.
     * @param _marketId The ID of the prediction market.
     * @param _actualOutcome The hashed actual outcome.
     * @param _outcomeTimestamp The timestamp when the outcome was observed/reported.
     */
    function oracleReportOutcome(uint256 _marketId, bytes32 _actualOutcome, uint256 _outcomeTimestamp) external {
        require(msg.sender == trustedOracleAddress, "Only trusted oracle can report outcome");
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Open, "Market is not open for outcome reporting");
        require(block.timestamp >= market.submissionEndTime, "Cannot report outcome before submission ends");
        require(block.timestamp >= market.resolutionTime, "Cannot report outcome before resolution time");

        // Verify actual outcome is one of the possible outcomes
        bool isValidOutcome = false;
        for (uint i = 0; i < market.possibleOutcomes.length; i++) {
            if (market.possibleOutcomes[i] == _actualOutcome) {
                isValidOutcome = true;
                break;
            }
        }
        require(isValidOutcome, "Actual outcome is not valid for this market");

        market.actualOutcome = _actualOutcome;
        market.outcomeTimestamp = _outcomeTimestamp;
        market.status = MarketStatus.Resolved;

        emit OutcomeReported(_marketId, _actualOutcome, _outcomeTimestamp);
    }

    /**
     * @notice Processes a resolved market, scores predictions, updates user reputations,
     *         and distributes rewards to accurate predictors.
     *         Can be called by anyone after the market is resolved by the oracle.
     * @param _marketId The ID of the prediction market to resolve.
     */
    function resolveMarketAndDistribute(uint256 _marketId) external nonReentrant {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Resolved, "Market is not in Resolved status");
        require(!market.rewardsDistributed, "Rewards already distributed for this market");

        bytes32 actualOutcome = market.actualOutcome;
        uint256 totalWinningStake = 0;
        address[] storage predictors = marketPredictorsList[_marketId];
        
        // First pass: Calculate total winning stake and mark winners
        for (uint i = 0; i < predictors.length; i++) {
            address predictor = predictors[i];
            UserPrediction storage userPred = userPredictions[_marketId][predictor];
            // Only consider active, non-cancelled predictions
            if (userPred.hasPredicted && userPred.predictedOutcome == actualOutcome) {
                totalWinningStake = totalWinningStake.add(userPred.stakeAmount);
            }
        }

        uint256 totalRewardsFromPool = market.totalStaked; // Total staked tokens are the reward pool

        // Second pass: Update reputation and calculate individual rewards
        for (uint i = 0; i < predictors.length; i++) {
            address predictor = predictors[i];
            UserPrediction storage userPred = userPredictions[_marketId][predictor];
            
            // Skip if prediction was cancelled or never made (hasPredicted check)
            if (!userPred.hasPredicted) continue;

            uint256 synthesizerId = userToSynthesizerId[predictor];
            if (synthesizerId == 0) continue; // Should not happen if only registered users can predict

            if (userPred.predictedOutcome == actualOutcome) {
                // Winning prediction: Boost reputation and calculate reward
                uint256 reputationBoost = 100 * REPUTATION_SCALE / 1000; // Base boost, e.g., 0.1 Reputation unit
                reputationBoost = reputationBoost.add(userPred.stakeAmount.mul(5).div(100)); // 5% of stake converted to rep units (scaled)
                _updateAuraSynthesizerReputation(synthesizerId, reputationBoost, true);

                // Calculate reward: stake + (total pool - total winning stake) * (individual stake / total winning stake)
                // Winners get their stake back, plus a share of the losers' stakes.
                uint256 rewardAmount = userPred.stakeAmount;
                if (totalWinningStake > 0) { // Avoid division by zero if all lost or no one predicted
                    rewardAmount = rewardAmount.add(
                        totalRewardsFromPool.sub(totalWinningStake).mul(userPred.stakeAmount).div(totalWinningStake)
                    );
                }
                userPred.rewardAmount = rewardAmount; // Store reward for later claiming
            } else {
                // Losing prediction: Deduct reputation.
                uint256 reputationPenalty = synthesizerIdToReputation[synthesizerId].mul(50).div(BASIS_POINTS_DIVISOR); // 0.5% of current rep
                if (reputationPenalty < (1 * REPUTATION_SCALE / 1000)) reputationPenalty = (1 * REPUTATION_SCALE / 1000); // Minimum penalty
                _updateAuraSynthesizerReputation(synthesizerId, reputationPenalty, false);
                userPred.rewardAmount = 0; // No reward for losers
            }
        }

        market.rewardsDistributed = true;
        market.status = MarketStatus.Closed; // Mark as closed after distribution logic
        emit MarketResolved(_marketId, actualOutcome, totalRewardsFromPool);
    }

    /**
     * @notice Retrieves a user's prediction, stake, and accuracy status for a given market.
     * @param _marketId The ID of the prediction market.
     * @param _user The address of the user.
     * @return predictedOutcome The outcome predicted by the user.
     * @return stakeAmount The amount of AST tokens staked.
     * @return hasPredicted True if the user has predicted in this market.
     * @return isCorrect True if the prediction was correct (only after market is resolved).
     * @return claimedRewards True if the user has claimed rewards.
     */
    function getUserPrediction(
        uint256 _marketId,
        address _user
    ) external view returns (bytes32 predictedOutcome, uint256 stakeAmount, bool hasPredicted, bool isCorrect, bool claimedRewards) {
        PredictionMarket storage market = predictionMarkets[_marketId];
        UserPrediction storage userPred = userPredictions[_marketId][_user];
        
        predictedOutcome = userPred.predictedOutcome;
        stakeAmount = userPred.stakeAmount;
        hasPredicted = userPred.hasPredicted;
        claimedRewards = userPred.claimedRewards;
        isCorrect = false;

        if (market.status == MarketStatus.Closed || market.status == MarketStatus.Resolved) {
            isCorrect = (userPred.predictedOutcome == market.actualOutcome);
        }
    }

    // --- IV. Reputation & Reward System ---

    /**
     * @notice Allows users to claim their earned AST tokens from one or more resolved prediction markets.
     * @param _marketIds An array of market IDs for which to claim rewards.
     */
    function claimPredictionRewards(uint256[] memory _marketIds) external nonReentrant {
        uint256 totalClaimable = 0;
        for (uint i = 0; i < _marketIds.length; i++) {
            uint256 marketId = _marketIds[i];
            UserPrediction storage userPred = userPredictions[marketId][msg.sender];
            PredictionMarket storage market = predictionMarkets[marketId];

            require(market.status == MarketStatus.Closed, "Market not closed yet");
            require(!userPred.claimedRewards, "Rewards already claimed for this market");
            require(userPred.hasPredicted, "No prediction found for this market");
            require(userPred.rewardAmount > 0, "No rewards to claim for this market");
            
            totalClaimable = totalClaimable.add(userPred.rewardAmount);
            userPred.claimedRewards = true; // Mark as claimed immediately
            
            emit RewardsClaimed(marketId, msg.sender, userPred.rewardAmount);
        }
        require(totalClaimable > 0, "No claimable rewards found");
        require(AST_TOKEN.transfer(msg.sender, totalClaimable), "AST transfer failed for claiming rewards");
    }

    /**
     * @notice Returns the current reputation score for a specific user address.
     *         This function fetches the reputation from the NFT associated with the user,
     *         applying decay before returning.
     * @param _user The address of the user.
     * @return The reputation score, scaled by REPUTATION_SCALE.
     */
    function getAuraReputation(address _user) external view returns (uint256) {
        uint256 tokenId = userToSynthesizerId[_user];
        return getAuraSynthesizerReputation(tokenId);
    }

    /**
     * @notice Returns the total amount of AST tokens accumulated as rewards for a specific market.
     *         This represents the total staked tokens that form the prize pool.
     * @param _marketId The ID of the prediction market.
     * @return The total reward pool amount.
     */
    function getMarketRewardPool(uint256 _marketId) external view returns (uint256) {
        return predictionMarkets[_marketId].totalStaked;
    }

    // --- V. Collective Aura Synthesis & Asset Strategy ---

    /**
     * @notice Calculates and returns the aggregated "Consensus Aura" for a given epoch.
     *         This represents the collective, reputation-weighted prediction and confidence.
     *         It aggregates predictions from a set of recent *resolved* markets.
     * @param _epochId The ID of the epoch for which to calculate the Consensus Aura.
     * @return consensusOutcome The aggregated most-voted outcome (hashed).
     * @return avgAccuracy A numerical representation of the collective's confidence/accuracy (scaled).
     */
    function getCurrentConsensusAura(uint256 _epochId) public view returns (bytes32 consensusOutcome, uint256 avgAccuracy) {
        // Define the current epoch's time boundaries
        uint256 currentEpochStartTime = _epochId.mul(epochDuration); // Assuming epochId 0 starts at contract deployment
        uint256 currentEpochEndTime = currentEpochStartTime.add(epochDuration);

        mapping(bytes32 => uint256) outcomeWeights; // outcome -> total weighted reputation
        uint256 totalReputationInEpoch = 0;
        uint256 totalAccurateReputation = 0;
        uint256 processedPredictions = 0;

        // Iterate through recent markets (up to a limit for gas safety, e.g., last 50 markets)
        uint256 lastMarketId = _marketIdCounter.current();
        uint256 startMarketId = (lastMarketId > 50) ? lastMarketId.sub(50) : 1;
        
        for (uint256 i = startMarketId; i <= lastMarketId; i++) {
            PredictionMarket storage market = predictionMarkets[i];
            // Consider markets resolved within the epoch, or whose resolution contributes to current sentiment.
            // For simplicity, we check if market.outcomeTimestamp falls within the current epoch.
            if (market.status == MarketStatus.Closed && market.outcomeTimestamp >= currentEpochStartTime && market.outcomeTimestamp < currentEpochEndTime) {
                address[] storage predictors = marketPredictorsList[i];
                for (uint j = 0; j < predictors.length; j++) {
                    address predictor = predictors[j];
                    UserPrediction storage userPred = userPredictions[i][predictor];
                    
                    if (userPred.hasPredicted) { // Only consider active predictions
                        uint256 synthesizerId = userToSynthesizerId[predictor];
                        if (synthesizerId != 0) { // Ensure user is a registered AuraSynthesizer
                            uint256 rep = getAuraSynthesizerReputation(synthesizerId); // Get decayed reputation
                            
                            outcomeWeights[userPred.predictedOutcome] = outcomeWeights[userPred.predictedOutcome].add(rep);
                            totalReputationInEpoch = totalReputationInEpoch.add(rep);
                            processedPredictions++;

                            if (userPred.predictedOutcome == market.actualOutcome) {
                                totalAccurateReputation = totalAccurateReputation.add(rep);
                            }
                        }
                    }
                }
            }
        }

        if (processedPredictions == 0) {
            return (bytes32(0), 0); // No data for this epoch
        }

        // Determine the consensus outcome (outcome with the highest cumulative reputation weight)
        uint256 maxWeight = 0;
        consensusOutcome = bytes32(0);
        // We iterate through all possible outcomes from the last market as a representative set.
        // In a real system, these outcomes would be standardized across markets or fed by an oracle.
        if (predictionMarkets[lastMarketId].possibleOutcomes.length > 0) {
             for (uint k = 0; k < predictionMarkets[lastMarketId].possibleOutcomes.length; k++) {
                bytes32 outcome = predictionMarkets[lastMarketId].possibleOutcomes[k];
                if (outcomeWeights[outcome] > maxWeight) {
                    maxWeight = outcomeWeights[outcome];
                    consensusOutcome = outcome;
                }
            }
        } else { // Fallback if no recent market, use a dummy "neutral" outcome
            consensusOutcome = keccak256(abi.encodePacked("NEUTRAL"));
        }
       

        // Calculate average accuracy (reputation-weighted)
        avgAccuracy = totalAccurateReputation.mul(REPUTATION_SCALE).div(totalReputationInEpoch);

        emit ConsensusAuraGenerated(_epochId, consensusOutcome, avgAccuracy);
    }

    /**
     * @notice Triggers the associated vault to rebalance assets based on the Consensus Aura.
     *         This function would typically be called by a trusted keeper or governance.
     * @param _epochId The epoch ID for which the strategy is being executed.
     * @param assetIds Array of asset identifiers (e.g., token addresses, internal IDs recognized by the vault).
     * @param newAllocationsBasisPoints Array of new allocation percentages in basis points (e.g., 5000 for 50%).
     */
    function triggerStrategyExecution(
        uint256 _epochId,
        uint256[] memory assetIds,
        uint256[] memory newAllocationsBasisPoints
    ) external onlyOwner { // Or by a specific Keeper role
        require(assetIds.length == newAllocationsBasisPoints.length, "Mismatched array lengths");
        
        // A full validation would check if the sum of newAllocationsBasisPoints is BASIS_POINTS_DIVISOR (10000).
        // It would also cross-reference with the `getCurrentConsensusAura` for the epoch to ensure consistency
        // with the collective's recommendation.
        
        auraVault.rebalanceAssets(assetIds, newAllocationsBasisPoints);
        emit StrategyExecuted(_epochId, address(auraVault), assetIds, newAllocationsBasisPoints);
    }

    /**
     * @notice Returns the recommended asset allocation based on the ConsensusAura for a given epoch.
     *         This function is conceptual and provides a high-level recommendation for off-chain analysis or UI.
     *         The actual execution is handled by `triggerStrategyExecution`.
     * @param _epochId The epoch ID.
     * @return assetIds The recommended asset identifiers.
     * @return allocationsBasisPoints The recommended allocation percentages.
     */
    function getRecommendedAllocation(uint256 _epochId) external view returns (uint256[] memory assetIds, uint256[] memory allocationsBasisPoints) {
        bytes32 consensusOutcome;
        uint256 avgAccuracy;
        (consensusOutcome, avgAccuracy) = getCurrentConsensusAura(_epochId);

        // Example strategy:
        // Assume assetId 0 = Stablecoin (e.g., USDC), assetId 1 = VolatileAsset (e.g., WETH)
        // If high confidence in "UP" (a specific outcome hash), recommend more volatile.
        // Else, recommend more stable.
        
        // For this example, let's define a dummy "UP" outcome for strategy mapping.
        bytes32 UP_OUTCOME = keccak256(abi.encodePacked("UP")); 

        assetIds = new uint256[](2);
        allocationsBasisPoints = new uint256[](2);

        // These IDs would map to actual tokens/assets in the IAuraVault
        assetIds[0] = 0; // Represents a stable asset (e.g., USDC, USDT)
        assetIds[1] = 1; // Represents a volatile asset (e.g., WETH, WBTC)

        // Threshold for "high confidence" (e.g., 80% accuracy)
        if (consensusOutcome == UP_OUTCOME && avgAccuracy >= 800 * REPUTATION_SCALE / 1000) { 
            allocationsBasisPoints[0] = 3000; // 30% stable
            allocationsBasisPoints[1] = 7000; // 70% volatile
        } else {
            allocationsBasisPoints[0] = 6000; // 60% stable
            allocationsBasisPoints[1] = 4000; // 40% volatile
        }
        // In a real system, a more complex strategy contract would be plugged in here,
        // or the oracleFeed could directly provide allocation recommendations.
    }

    // --- VI. Dispute & Governance ---

    /**
     * @notice Allows a user to formally dispute an `oracleReportOutcome`, requiring a deposit.
     *         This initiates a dispute resolution process.
     * @param _marketId The ID of the market whose outcome is being disputed.
     * @param _reason A string explaining the reason for the dispute.
     */
    function submitDispute(uint256 _marketId, string memory _reason) external nonReentrant {
        require(userToSynthesizerId[msg.sender] != 0, "Only registered AuraSynthesizers can submit disputes");
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Resolved || market.status == MarketStatus.Closed, "Market must be resolved or closed to dispute");
        
        // Ensure no active dispute for this market
        uint256 lastDisputeId = _disputeIdCounter.current();
        if (lastDisputeId > 0 && disputes[lastDisputeId].marketId == _marketId && disputes[lastDisputeId].status == DisputeStatus.Open) {
            revert("Market already has an open dispute");
        }

        uint256 disputeDeposit = marketCreationFee.mul(2); // Example: 2x market creation fee for dispute
        require(AST_TOKEN.transferFrom(msg.sender, address(this), disputeDeposit), "AST transfer failed for dispute deposit");

        _disputeIdCounter.increment();
        uint256 newDisputeId = _disputeIdCounter.current();

        disputes[newDisputeId] = Dispute({
            marketId: _marketId,
            challenger: msg.sender,
            reason: _reason,
            challengeDeposit: disputeDeposit,
            startTime: block.timestamp,
            endTime: block.timestamp.add(3 days), // Example: 3 days for voting
            votesForOverturn: 0,
            votesForUphold: 0,
            status: DisputeStatus.Open,
            depositRefunded: false
        });

        market.status = MarketStatus.Disputed; // Change market status to Disputed while dispute is active
        emit DisputeSubmitted(newDisputeId, _marketId, msg.sender);
    }

    /**
     * @notice Allows reputable AuraSynthesizers to vote on pending disputes.
     *         Vote weight is proportional to reputation.
     * @param _disputeId The ID of the dispute.
     * @param _support True to support the original oracle outcome (uphold), False to support overturning it.
     */
    function voteOnDispute(uint256 _disputeId, bool _support) external nonReentrant {
        uint256 synthesizerId = userToSynthesizerId[msg.sender];
        require(synthesizerId != 0, "Only registered AuraSynthesizers can vote");
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "Dispute is not open for voting");
        require(block.timestamp < dispute.endTime, "Dispute voting period has ended");
        require(!hasVotedOnDispute[_disputeId][msg.sender], "Already voted on this dispute");

        // Reputation-weighted voting
        uint256 voterReputation = getAuraSynthesizerReputation(synthesizerId);
        require(voterReputation > 0, "Voter must have positive reputation");

        if (_support) {
            dispute.votesForUphold = dispute.votesForUphold.add(voterReputation);
        } else {
            dispute.votesForOverturn = dispute.votesForOverturn.add(voterReputation);
        }
        hasVotedOnDispute[_disputeId][msg.sender] = true;
        emit DisputeVoted(_disputeId, msg.sender, _support);
    }

    /**
     * @notice Resolves a dispute after its voting period ends.
     *         If votes to overturn exceed votes to uphold, the oracle outcome is marked as invalid.
     *         The challenger's deposit is refunded if the dispute is overturned.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) external nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "Dispute is not open");
        require(block.timestamp >= dispute.endTime, "Dispute voting period has not ended");

        PredictionMarket storage market = predictionMarkets[dispute.marketId];

        if (dispute.votesForOverturn > dispute.votesForUphold) {
            // Dispute overturned: Oracle outcome was incorrect.
            dispute.status = DisputeStatus.ResolvedOverturned;
            market.status = MarketStatus.Invalidated; // Market outcome is now considered invalid
            market.actualOutcome = bytes32(0); // Clear the invalid outcome
            market.rewardsDistributed = false; // Prevent distribution based on invalid outcome

            // Refund challenger's deposit
            require(AST_TOKEN.transfer(dispute.challenger, dispute.challengeDeposit), "Failed to refund dispute deposit");
            dispute.depositRefunded = true;

            // Optional: Punish Oracle/TrustedOracleAddress's reputation here
            // _updateAuraSynthesizerReputation(userToSynthesizerId[trustedOracleAddress], PENALTY_AMOUNT, false);

        } else {
            // Dispute upheld: Oracle outcome was correct.
            dispute.status = DisputeStatus.ResolvedUpheld;
            // Restore market to its resolved state so rewards can be processed or re-processed
            market.status = MarketStatus.Resolved; 

            // Challenger loses deposit. The tokens remain in the contract as part of the overall pool.
        }
        dispute.status = DisputeStatus.Closed; // Mark dispute as closed after resolution logic
        emit DisputeResolved(_disputeId, dispute.status);
    }

    /**
     * @notice Retrieves the full details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return Dispute details.
     */
    function getDisputeDetails(uint256 _disputeId) external view returns (Dispute memory) {
        return disputes[_disputeId];
    }
}

```