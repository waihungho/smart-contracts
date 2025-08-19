This smart contract, `AI_Powered_DePredictive_NFTs` (AIP_dPNFTs), introduces a unique ecosystem where **AI prediction models are represented as Dynamic NFTs (dPNFTs)**. The traits of these dPNFTs evolve based on their predictive accuracy in on-chain prediction markets. A utility token ($PRDX) facilitates payments, staking, and rewards within this system.

---

## Contract Outline

1.  **Interfaces & Libraries:** Standard imports for ERC721, ERC20, access control, and a mock Chainlink Oracle interface for external data.
2.  **State Variables:** Definitions for core contract parameters, NFT details, AI model data, prediction market information, staking data, and fee configurations.
3.  **Structs:** Detailed structures for `AIModel`, `PredictionMarket`, and `StakingInfo` to organize complex data.
4.  **Events:** Comprehensive event declarations for all significant state changes, crucial for off-chain indexing and dApp responsiveness.
5.  **Modifiers:** Custom modifiers for access control (e.g., `onlyAIModelOwner`) and standard `pausable`, `nonReentrant` checks.
6.  **Constructor:** Initializes the contract with necessary token and oracle addresses.
7.  **ERC-721 Standard Overrides:** Custom implementation of `tokenURI` to reflect dynamic NFT traits.
8.  **AI Model (dPNFT) Management:** Functions for registering, updating, querying, and deactivating AI models (dPNFTs).
9.  **Dynamic NFT Logic & Reputation:** Internal and external functions to update NFT traits based on prediction accuracy and calculate a model's reputation score, including staking influence.
10. **Reputation Staking System:** Enables users to stake $PRDX tokens on specific AI models to boost their reputation and earn rewards.
11. **Prediction Market Functions:** Allows creation of new prediction markets, submission of predictions by AI models, oracle-based resolution, and claiming of winnings.
12. **Platform & Fee Management:** Functions for setting fees and withdrawing accumulated platform fees by the owner.
13. **Oracle Integration:** Designed to interact with a mock Chainlink oracle for market resolution, showcasing the pattern for real oracle integration.
14. **Utility & Query Functions:** Various read-only functions to retrieve data about models, markets, and staking information, including a simplified function to get top-performing models.
15. **Pausable Functionality:** Standard emergency pause/unpause mechanisms.

---

## Function Summary

1.  **`constructor(address _prdxToken, address _chainlinkOracle)`**:
    *   **Description**: Initializes the contract, setting the ERC20 token address for $PRDX and the address of the mock Chainlink Oracle.
    *   **Concept**: Foundation setup, immutable token/oracle links.

2.  **`registerAIModel(string calldata _modelURI, string calldata _modelName)`**:
    *   **Description**: Mints a new dPNFT, representing an AI model. The `_modelURI` typically points to off-chain data (e.g., IPFS hash) about the AI.
    *   **Concept**: NFT minting, AI model on-chain representation.

3.  **`updateAIModelURI(uint256 _tokenId, string calldata _newModelURI)`**:
    *   **Description**: Allows the owner of an AI model dPNFT to update its associated URI, useful for model upgrades or documentation changes.
    *   **Concept**: NFT metadata updates, owner control.

4.  **`deactivateAIModel(uint256 _tokenId)`**:
    *   **Description**: Soft-deactivates an AI model, preventing it from participating in new markets. The dPNFT remains owned.
    *   **Concept**: Lifecycle management, opt-out for models.

5.  **`getAIModelInfo(uint256 _tokenId)`**:
    *   **Description**: Retrieves all stored details (URI, name, performance metrics, active status) for a specific AI model dPNFT.
    *   **Concept**: Data querying, transparency.

6.  **`tokenURI(uint256 _tokenId)`**:
    *   **Description**: (Override ERC721) Generates a dynamic URI for the dPNFT, reflecting its current accuracy and reputation score, intended for metadata APIs.
    *   **Concept**: Dynamic NFTs, on-chain state affecting off-chain representation.

7.  **`updateModelAccuracy(uint256 _tokenId, bool _isCorrect)`**:
    *   **Description**: (Internal) Updates an AI model's historical prediction count and correct prediction count. Called after market resolution.
    *   **Concept**: On-chain performance tracking, core logic for dynamic NFTs.

8.  **`calculateModelReputation(uint256 _tokenId)`**:
    *   **Description**: Calculates a dynamic reputation score for an AI model, primarily based on its accuracy, with a potential boost from staked tokens.
    *   **Concept**: On-chain reputation system, weighted metrics.

9.  **`updateNFTTraits(uint256 _tokenId)`**:
    *   **Description**: Triggers an update to the dPNFT's `lastTraitUpdate` timestamp, signaling that its dynamic `tokenURI` should be re-evaluated by clients.
    *   **Concept**: Explicit refresh for dynamic NFT metadata.

10. **`stakeForReputation(uint256 _tokenId, uint256 _amount)`**:
    *   **Description**: Allows users to stake $PRDX tokens on a specific AI model. Staking boosts the model's reputation and makes the staker eligible for rewards from its successful predictions.
    *   **Concept**: Staking, reputation boosting, incentive alignment.

11. **`unstakeFromReputation(uint256 _tokenId, uint256 _amount)`**:
    *   **Description**: Enables stakers to retrieve their $PRDX tokens from a staked AI model.
    *   **Concept**: Unstaking, liquidity management.

12. **`claimStakingRewards(uint256 _tokenId)`**:
    *   **Description**: Allows stakers to claim their share of $PRDX rewards accumulated from successful predictions of the AI model they backed.
    *   **Concept**: Reward distribution, yield.

13. **`createPredictionMarket(string calldata _marketTitle, string calldata _outcomeA, string calldata _outcomeB, uint256 _closingTime, uint256 _resolutionTime, uint256 _collateralAmount)`**:
    *   **Description**: Creates a new binary prediction market, requiring collateral for each prediction entry.
    *   **Concept**: Decentralized prediction markets, market creation.

14. **`submitPrediction(uint256 _marketId, uint256 _tokenId, uint8 _outcomeChoice)`**:
    *   **Description**: Allows a registered AI model (dPNFT) to submit its prediction for a specific market, locking up collateral.
    *   **Concept**: AI participation in DeFi, on-chain prediction.

15. **`requestMarketResolution(uint256 _marketId)`**:
    *   **Description**: Initiates a request to the Chainlink Oracle (mocked) to resolve the outcome of a prediction market once `resolutionTime` is passed.
    *   **Concept**: Oracle integration, market resolution trigger.

16. **`fulfillMarketResolution(uint256 _marketId, uint8 _winningOutcome)`**:
    *   **Description**: (Callback) This function is called by the Chainlink Oracle to provide the final winning outcome of a market. It then updates model accuracies and calculates fees.
    *   **Concept**: Oracle callback, off-chain data integration, market settlement.

17. **`claimPredictionWinnings(uint256 _marketId, uint256 _tokenId)`**:
    *   **Description**: Allows the owner of an AI model to claim its share of winnings from a correctly predicted market. A portion of these winnings is allocated to the model's staker reward pool.
    *   **Concept**: Winnings distribution, internal token flow, staker incentives.

18. **`setPlatformFee(uint256 _newFeeBps)`**:
    *   **Description**: (Owner-only) Sets the platform fee percentage (in basis points) applied to market collateral.
    *   **Concept**: Fee management, administrative control.

19. **`withdrawPlatformFees()`**:
    *   **Description**: (Owner-only) Allows the contract owner to withdraw accumulated platform fees.
    *   **Concept**: Treasury management, fund withdrawal.

20. **`setOracleAddress(address _newOracle)`**:
    *   **Description**: (Owner-only) Updates the address of the Chainlink Oracle used for market resolution.
    *   **Concept**: Administrative control, upgradability of dependencies.

21. **`getMarketDetails(uint256 _marketId)`**:
    *   **Description**: Retrieves all details about a specific prediction market, including outcomes, times, and resolution status.
    *   **Concept**: Data querying, market transparency.

22. **`getTopPerformingModels(uint256 _limit)`**:
    *   **Description**: Returns a list of the top N AI model dPNFTs based on their calculated reputation score. (Simplified in-contract sorting for demonstration).
    *   **Concept**: Leaderboards, ranking, data aggregation.

23. **`pause()`**:
    *   **Description**: (Owner-only) Pauses certain contract functionalities in an emergency.
    *   **Concept**: Emergency stop, security.

24. **`unpause()`**:
    *   **Description**: (Owner-only) Unpauses the contract functionalities.
    *   **Concept**: Resumption of operations.

25. **`getModelReputation(uint256 _tokenId)`**:
    *   **Description**: A public view function to directly get the current reputation score of an AI model.
    *   **Concept**: Direct data access, analytics.

26. **`getStakerInfo(uint256 _tokenId, address _staker)`**:
    *   **Description**: Retrieves the staking amount and any pending reward debt for a specific staker on a particular AI model.
    *   **Concept**: User-specific data query, staking transparency.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Mock Chainlink Oracle Interface for demonstration purposes
// In a real scenario, this would interact with a Chainlink VRF or Any API consumer contract.
interface IMockChainlinkOracle {
    function requestData(uint256 _marketId, address _callbackContract, bytes4 _callbackSelector) external;
    function fulfillData(uint256 _marketId, uint8 _outcome) external; // Simplified fulfillment
}


/**
 * @title AI_Powered_DePredictive_NFTs (AIP_dPNFTs)
 * @dev A decentralized platform for registering AI prediction models as dynamic NFTs (dPNFTs).
 *      These dPNFTs evolve based on their predictive accuracy and participate in on-chain prediction markets.
 *      A utility token ($PRDX) facilitates operations, staking, and rewards.
 */
contract AIP_dPNFTs is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {

    // --- Outline ---
    // 1. Interfaces & Libraries
    // 2. State Variables & Structs
    // 3. Events
    // 4. Modifiers
    // 5. Constructor
    // 6. ERC-721 Standard Overrides (tokenURI)
    // 7. AI Model (dPNFT) Management
    // 8. Dynamic NFT Logic & Reputation
    // 9. Reputation Staking System
    // 10. Prediction Market Functions
    // 11. Platform & Fee Management
    // 12. Utility & Query Functions
    // 13. Pausable Functionality

    // --- Function Summary ---
    // Constructor & Core Setup:
    // 1. constructor(address _prdxToken, address _chainlinkOracle)
    // AI Model (dPNFT) Management:
    // 2. registerAIModel(string calldata _modelURI, string calldata _modelName)
    // 3. updateAIModelURI(uint256 _tokenId, string calldata _newModelURI)
    // 4. deactivateAIModel(uint256 _tokenId)
    // 5. getAIModelInfo(uint256 _tokenId)
    // 6. tokenURI(uint256 _tokenId)
    // Dynamic NFT Logic & Reputation:
    // 7. updateModelAccuracy(uint256 _tokenId, bool _isCorrect) (Internal)
    // 8. calculateModelReputation(uint256 _tokenId)
    // 9. updateNFTTraits(uint256 _tokenId)
    // Reputation Staking System:
    // 10. stakeForReputation(uint256 _tokenId, uint256 _amount)
    // 11. unstakeFromReputation(uint256 _tokenId, uint256 _amount)
    // 12. claimStakingRewards(uint256 _tokenId)
    // Prediction Market Functions:
    // 13. createPredictionMarket(string calldata _marketTitle, string calldata _outcomeA, string calldata _outcomeB, uint256 _closingTime, uint256 _resolutionTime, uint256 _collateralAmount)
    // 14. submitPrediction(uint256 _marketId, uint256 _tokenId, uint8 _outcomeChoice)
    // 15. requestMarketResolution(uint256 _marketId)
    // 16. fulfillMarketResolution(uint256 _marketId, uint8 _winningOutcome) (Oracle Callback)
    // 17. claimPredictionWinnings(uint256 _marketId, uint256 _tokenId)
    // Platform & Fee Management:
    // 18. setPlatformFee(uint256 _newFeeBps)
    // 19. withdrawPlatformFees()
    // 20. setOracleAddress(address _newOracle)
    // Utility & Query Functions:
    // 21. getMarketDetails(uint256 _marketId)
    // 22. getTopPerformingModels(uint256 _limit)
    // 23. getModelReputation(uint256 _tokenId)
    // 24. getStakerInfo(uint256 _tokenId, address _staker)
    // Pausable Functionality:
    // 25. pause()
    // 26. unpause()


    // --- State Variables ---

    IERC20 public immutable PRDX_TOKEN;
    IMockChainlinkOracle public chainlinkOracle;

    uint256 private _nextTokenId;
    uint256 private _nextMarketId;

    uint256 public platformFeeBps = 500; // 5% default fee in basis points (100 = 1%)
    uint256 public totalPlatformFeesCollected;

    // Structs for data
    struct AIModel {
        uint256 tokenId;
        address owner;
        string modelURI; // IPFS hash or URL to model details/code
        string modelName;
        uint256 predictionCount;
        uint256 correctPredictions;
        bool isActive; // Can be deactivated by owner
        uint256 lastTraitUpdate; // Timestamp of last trait update, triggers tokenURI refresh
    }

    struct PredictionMarket {
        uint256 marketId;
        string title;
        string outcomeA;
        string outcomeB;
        uint256 closingTime; // When predictions can no longer be submitted
        uint256 resolutionTime; // When the market can be resolved by oracle
        uint256 collateralAmount; // Amount of PRDX tokens required as collateral for participation per model
        uint8 winningOutcome; // 0 = not resolved, 1 = outcomeA, 2 = outcomeB
        bool isResolved;
        address creator;
        uint256 totalCollateral; // Sum of all collateral from participating models

        // Mapping: tokenId => outcome choice (1 for A, 2 for B)
        mapping(uint256 => uint8) predictions;
        // Mapping: tokenId => bool (has claimed winnings?)
        mapping(uint256 => bool) hasClaimedWinnings;
        // Array to store tokenIds of models that participated for iteration during resolution
        uint256[] predictedTokenIds;
    }

    struct StakingInfo {
        uint256 amountStaked;
        // `rewardDebt` is simplified here; a full MasterChef-like system is more complex.
        // For this example, rewards are pulled from `stakerRewardPool` directly.
    }

    // Mappings
    mapping(uint256 => AIModel) public aiModels; // tokenId => AIModel details
    mapping(uint256 => PredictionMarket) public predictionMarkets; // marketId => PredictionMarket details
    mapping(uint256 => mapping(address => StakingInfo)) public modelStakes; // tokenId => stakerAddress => StakingInfo
    mapping(uint256 => uint256) public totalModelStakes; // tokenId => total PRDX staked on this model (for reputation)
    mapping(uint256 => uint256) public stakerRewardPool; // tokenId => accumulated PRDX rewards for stakers of this model


    // --- Events ---

    event AIModelRegistered(uint256 indexed tokenId, address indexed owner, string modelURI, string modelName);
    event AIModelUpdated(uint256 indexed tokenId, string newModelURI);
    event AIModelDeactivated(uint256 indexed tokenId);
    event NFTTraitsUpdated(uint256 indexed tokenId, uint256 newReputationScore);

    event PredictionMarketCreated(uint256 indexed marketId, address indexed creator, string title, uint256 collateralAmount, uint256 closingTime);
    event PredictionSubmitted(uint256 indexed marketId, uint256 indexed tokenId, uint8 outcomeChoice);
    event MarketResolutionRequested(uint256 indexed marketId);
    event MarketResolved(uint256 indexed marketId, uint8 winningOutcome);
    event WinningsClaimed(uint256 indexed marketId, uint256 indexed tokenId, uint256 amount);

    event ReputationStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event ReputationUnstaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed staker, uint256 amount);

    event PlatformFeeSet(uint256 newFeeBps);
    event PlatformFeesWithdrawn(uint256 amount);
    event OracleAddressSet(address newOracle);


    // --- Modifiers ---

    modifier onlyAIModelOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "AIP: NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "AIP: Not NFT owner");
        _;
    }

    // --- Constructor ---

    constructor(address _prdxToken, address _chainlinkOracle)
        ERC721("AI_Powered_DePredictive_NFT", "AIP_dPNFT")
        Ownable(msg.sender)
    {
        require(_prdxToken != address(0), "AIP: PRDX token address cannot be zero");
        require(_chainlinkOracle != address(0), "AIP: Chainlink Oracle address cannot be zero");
        PRDX_TOKEN = IERC20(_prdxToken);
        chainlinkOracle = IMockChainlinkOracle(_chainlinkOracle);
        _nextTokenId = 1; // Start token IDs from 1
        _nextMarketId = 1; // Start market IDs from 1
    }

    // --- ERC-721 Standard Overrides ---

    /**
     * @dev Overrides ERC721 `tokenURI` to return a dynamic URI based on model's performance.
     *      This URI should point to an API endpoint that generates dynamic JSON metadata
     *      reflecting the current on-chain state (accuracy, reputation, etc.) of the AIModel.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        AIModel storage model = aiModels[_tokenId];
        uint256 reputation = calculateModelReputation(_tokenId);
        uint256 accuracy = model.predictionCount == 0 ? 0 : (model.correctPredictions * 10000) / model.predictionCount;

        // Example dynamic URI: a real implementation would use a dedicated service
        // to serve proper JSON metadata for marketplaces like OpenSea.
        return string(abi.encodePacked(
            "https://aip.io/api/nft/",
            Strings.toString(_tokenId),
            "?accuracy=",
            Strings.toString(accuracy),
            "&reputation=",
            Strings.toString(reputation),
            "&lastUpdate=",
            Strings.toString(model.lastTraitUpdate)
        ));
    }


    // --- AI Model (dPNFT) Management ---

    /**
     * @dev Registers a new AI model and mints a dynamic NFT (dPNFT) for it.
     *      The `_modelURI` should link to off-chain data detailing the AI model.
     * @param _modelURI The URI (e.g., IPFS hash) pointing to the AI model's details/code.
     * @param _modelName A human-readable name for the AI model.
     * @return The tokenId of the newly minted dPNFT.
     */
    function registerAIModel(string calldata _modelURI, string calldata _modelName)
        external
        nonReentrant
        pausable
        returns (uint256)
    {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(msg.sender, newTokenId);

        aiModels[newTokenId] = AIModel({
            tokenId: newTokenId,
            owner: msg.sender,
            modelURI: _modelURI,
            modelName: _modelName,
            predictionCount: 0,
            correctPredictions: 0,
            isActive: true,
            lastTraitUpdate: block.timestamp
        });

        emit AIModelRegistered(newTokenId, msg.sender, _modelURI, _modelName);
        return newTokenId;
    }

    /**
     * @dev Allows the owner of an AI model dPNFT to update its associated URI.
     * @param _tokenId The ID of the dPNFT to update.
     * @param _newModelURI The new URI for the model's details.
     */
    function updateAIModelURI(uint256 _tokenId, string calldata _newModelURI)
        external
        onlyAIModelOwner(_tokenId)
        pausable
    {
        aiModels[_tokenId].modelURI = _newModelURI;
        emit AIModelUpdated(_tokenId, _newModelURI);
        _triggerNFTTraitUpdate(_tokenId); // Update traits to reflect potential URI change
    }

    /**
     * @dev Deactivates an AI model, preventing it from participating in new prediction markets.
     *      The dPNFT still exists, but the model is marked inactive.
     * @param _tokenId The ID of the dPNFT to deactivate.
     */
    function deactivateAIModel(uint256 _tokenId)
        external
        onlyAIModelOwner(_tokenId)
        pausable
    {
        require(aiModels[_tokenId].isActive, "AIP: Model is already inactive");
        aiModels[_tokenId].isActive = false;
        emit AIModelDeactivated(_tokenId);
    }

    /**
     * @dev Retrieves comprehensive information about a registered AI model (dPNFT).
     * @param _tokenId The ID of the dPNFT.
     * @return AIModel struct containing all relevant data.
     */
    function getAIModelInfo(uint256 _tokenId)
        public
        view
        returns (AIModel memory)
    {
        require(_exists(_tokenId), "AIP: NFT does not exist");
        return aiModels[_tokenId];
    }


    // --- Dynamic NFT Logic & Reputation ---

    /**
     * @dev Internal function to update an AI model's accuracy score.
     *      Called by `fulfillMarketResolution` after a market outcome is known.
     * @param _tokenId The ID of the AI model.
     * @param _isCorrect True if the model's prediction was correct, false otherwise.
     */
    function updateModelAccuracy(uint256 _tokenId, bool _isCorrect) internal {
        AIModel storage model = aiModels[_tokenId];
        model.predictionCount++;
        if (_isCorrect) {
            model.correctPredictions++;
        }
        _triggerNFTTraitUpdate(_tokenId); // Trigger potential NFT trait update
    }

    /**
     * @dev Calculates the dynamic reputation score for an AI model.
     *      Reputation is based on a weighted average of accuracy and staking support.
     *      Formula: (Accuracy % * 0.7) + (Staking Boost * 0.3)
     *      Staking Boost: Logarithmic scale based on total PRDX staked on the model.
     *      Score out of 10000.
     * @param _tokenId The ID of the AI model.
     * @return The calculated reputation score.
     */
    function calculateModelReputation(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        AIModel storage model = aiModels[_tokenId];
        if (model.predictionCount == 0 && totalModelStakes[_tokenId] == 0) {
            return 0; // No data, no reputation
        }

        uint256 accuracyPercentage = 0;
        if (model.predictionCount > 0) {
            accuracyPercentage = (model.correctPredictions * 10000) / model.predictionCount; // Max 10000
        }

        uint256 stakingInfluence = 0;
        if (totalModelStakes[_tokenId] > 0) {
            // Simple logarithmic scaling for staking influence: sqrt(amount) * factor
            // For simplicity, let's use a cap/scaling factor for staking.
            // Example: A base influence + an additional amount for higher stakes, capped.
            // Simplified: max 3000 contribution from staking, scaling with log or sqrt.
            uint256 cappedStakes = totalModelStakes[_tokenId] > 1e18 ? 1e18 : totalModelStakes[_tokenId]; // Cap at 1 PRDX for simple scaling
            stakingInfluence = (cappedStakes * 3000) / 1e18; // Scales up to 3000 if 1 PRDX staked
        }

        // Weighted average: Accuracy (70%) + Staking Influence (30%)
        // Example weights: 70% accuracy, 30% staking influence
        uint256 reputationScore = (accuracyPercentage * 70) / 100 + (stakingInfluence * 30) / 100;

        return reputationScore;
    }

    /**
     * @dev Public function to trigger an update of the visual/metadata traits of the dPNFT.
     *      This function can be called by anyone to encourage metadata refresh.
     * @param _tokenId The ID of the dPNFT to update.
     */
    function updateNFTTraits(uint256 _tokenId) public pausable {
        require(_exists(_tokenId), "AIP: NFT does not exist");
        _triggerNFTTraitUpdate(_tokenId);
    }

    /**
     * @dev Internal function to update the `lastTraitUpdate` timestamp,
     *      which signifies that the `tokenURI` should reflect the latest state.
     *      This is called internally when model accuracy changes or external `updateNFTTraits` is called.
     * @param _tokenId The ID of the dPNFT to update.
     */
    function _triggerNFTTraitUpdate(uint256 _tokenId) internal {
        aiModels[_tokenId].lastTraitUpdate = block.timestamp;
        emit NFTTraitsUpdated(_tokenId, calculateModelReputation(_tokenId));
    }


    // --- Reputation Staking System ---

    /**
     * @dev Users stake PRDX tokens on a specific AI model to boost its perceived reputation
     *      and earn rewards if the model performs well in markets.
     * @param _tokenId The ID of the AI model dPNFT.
     * @param _amount The amount of PRDX tokens to stake.
     */
    function stakeForReputation(uint256 _tokenId, uint256 _amount)
        external
        nonReentrant
        pausable
    {
        require(_exists(_tokenId), "AIP: Model does not exist");
        require(aiModels[_tokenId].isActive, "AIP: Model is inactive");
        require(_amount > 0, "AIP: Stake amount must be positive");

        PRDX_TOKEN.transferFrom(msg.sender, address(this), _amount);
        modelStakes[_tokenId][msg.sender].amountStaked += _amount;
        totalModelStakes[_tokenId] += _amount; // Update total stakes for reputation calculation

        emit ReputationStaked(_tokenId, msg.sender, _amount);
        _triggerNFTTraitUpdate(_tokenId); // Staking affects reputation, so update traits
    }

    /**
     * @dev Users unstake their PRDX tokens from a model.
     * @param _tokenId The ID of the AI model dPNFT.
     * @param _amount The amount of PRDX tokens to unstake.
     */
    function unstakeFromReputation(uint256 _tokenId, uint256 _amount)
        external
        nonReentrant
        pausable
    {
        require(_exists(_tokenId), "AIP: Model does not exist");
        require(_amount > 0, "AIP: Unstake amount must be positive");
        require(modelStakes[_tokenId][msg.sender].amountStaked >= _amount, "AIP: Not enough staked balance");

        modelStakes[_tokenId][msg.sender].amountStaked -= _amount;
        totalModelStakes[_tokenId] -= _amount; // Update total stakes
        PRDX_TOKEN.transfer(msg.sender, _amount);

        emit ReputationUnstaked(_tokenId, msg.sender, _amount);
        _triggerNFTTraitUpdate(_tokenId); // Unstaking affects reputation
    }

    /**
     * @dev Stakers claim rewards from successful predictions of the model they backed.
     *      Rewards are proportional to their staked amount relative to the model's total stakes
     *      from the `stakerRewardPool` for that model.
     * @param _tokenId The ID of the AI model dPNFT.
     */
    function claimStakingRewards(uint256 _tokenId)
        external
        nonReentrant
        pausable
    {
        require(_exists(_tokenId), "AIP: Model does not exist");
        uint256 stakerAmount = modelStakes[_tokenId][msg.sender].amountStaked;
        require(stakerAmount > 0, "AIP: No active stake found");
        require(totalModelStakes[_tokenId] > 0, "AIP: No total stakes on model");

        // Calculate proportionate share of rewards from the stakerRewardPool
        uint256 currentRewardPool = stakerRewardPool[_tokenId];
        uint256 rewardsToClaim = (stakerAmount * currentRewardPool) / totalModelStakes[_tokenId];

        require(rewardsToClaim > 0, "AIP: No rewards to claim");

        // Reduce the global stakerRewardPool for this model, and transfer to staker
        stakerRewardPool[_tokenId] -= rewardsToClaim; // This must be handled carefully to avoid re-entry or state inconsistencies
        PRDX_TOKEN.transfer(msg.sender, rewardsToClaim);
        emit StakingRewardsClaimed(_tokenId, msg.sender, rewardsToClaim);
    }


    // --- Prediction Market Functions ---

    /**
     * @dev Creates a new binary prediction market.
     *      Requires the creator to define outcomes, times, and collateral per prediction.
     * @param _marketTitle A descriptive title for the market.
     * @param _outcomeA Description of the first outcome.
     * @param _outcomeB Description of the second outcome.
     * @param _closingTime Unix timestamp when predictions close.
     * @param _resolutionTime Unix timestamp when the market can be resolved by oracle.
     * @param _collateralAmount The PRDX token amount required per prediction entry.
     * @return The ID of the newly created market.
     */
    function createPredictionMarket(
        string calldata _marketTitle,
        string calldata _outcomeA,
        string calldata _outcomeB,
        uint256 _closingTime,
        uint256 _resolutionTime,
        uint256 _collateralAmount
    ) external
      nonReentrant
      pausable
      returns (uint256)
    {
        require(bytes(_marketTitle).length > 0, "AIP: Market title cannot be empty");
        require(_closingTime > block.timestamp, "AIP: Closing time must be in the future");
        require(_resolutionTime > _closingTime, "AIP: Resolution time must be after closing time");
        require(_collateralAmount > 0, "AIP: Collateral amount must be positive");

        uint256 newMarketId = _nextMarketId++;

        predictionMarkets[newMarketId] = PredictionMarket({
            marketId: newMarketId,
            title: _marketTitle,
            outcomeA: _outcomeA,
            outcomeB: _outcomeB,
            closingTime: _closingTime,
            resolutionTime: _resolutionTime,
            collateralAmount: _collateralAmount,
            winningOutcome: 0, // 0 means not resolved
            isResolved: false,
            creator: msg.sender,
            totalCollateral: 0, // Will accumulate as models submit predictions
            predictedTokenIds: new uint256[](0) // Initialize empty array for participants
        });

        emit PredictionMarketCreated(newMarketId, msg.sender, _marketTitle, _collateralAmount, _closingTime);
        return newMarketId;
    }

    /**
     * @dev Allows a registered dPNFT (AI model) to submit a prediction for a market.
     *      Requires the model owner to send the `collateralAmount` for this market.
     * @param _marketId The ID of the market.
     * @param _tokenId The ID of the AI model dPNFT submitting the prediction.
     * @param _outcomeChoice The chosen outcome (1 for Outcome A, 2 for Outcome B).
     */
    function submitPrediction(uint256 _marketId, uint256 _tokenId, uint8 _outcomeChoice)
        external
        onlyAIModelOwner(_tokenId)
        nonReentrant
        pausable
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.marketId != 0, "AIP: Market does not exist");
        require(block.timestamp < market.closingTime, "AIP: Market is closed for predictions");
        require(aiModels[_tokenId].isActive, "AIP: AI model is inactive");
        require(market.predictions[_tokenId] == 0, "AIP: Model already submitted prediction");
        require(_outcomeChoice == 1 || _outcomeChoice == 2, "AIP: Invalid outcome choice");

        PRDX_TOKEN.transferFrom(msg.sender, address(this), market.collateralAmount);
        market.predictions[_tokenId] = _outcomeChoice;
        market.totalCollateral += market.collateralAmount;
        market.predictedTokenIds.push(_tokenId); // Track participant

        emit PredictionSubmitted(_marketId, _tokenId, _outcomeChoice);
    }

    /**
     * @dev Initiates an oracle request to resolve a prediction market.
     *      Can be called by anyone after the `resolutionTime`.
     *      This function interacts with the `IMockChainlinkOracle` to simulate an external request.
     * @param _marketId The ID of the market to resolve.
     */
    function requestMarketResolution(uint256 _marketId)
        external
        pausable
        nonReentrant
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.marketId != 0, "AIP: Market does not exist");
        require(!market.isResolved, "AIP: Market already resolved");
        require(block.timestamp >= market.resolutionTime, "AIP: Market not yet ready for resolution");

        // In a real Chainlink setup, this would use ChainlinkClient's request methods
        // with specific job IDs and LINK payments.
        chainlinkOracle.requestData(_marketId, address(this), this.fulfillMarketResolution.selector);
        emit MarketResolutionRequested(_marketId);
    }

    /**
     * @dev Callback function for the Chainlink Oracle to provide the market outcome.
     *      This function can only be called by the registered `chainlinkOracle` address.
     *      It distributes fees and updates participating model accuracies.
     * @param _marketId The ID of the market being resolved.
     * @param _winningOutcome The winning outcome (1 for A, 2 for B).
     */
    function fulfillMarketResolution(uint256 _marketId, uint8 _winningOutcome)
        external
        nonReentrant
    {
        require(msg.sender == address(chainlinkOracle), "AIP: Only oracle can call this function");
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.marketId != 0, "AIP: Market does not exist");
        require(!market.isResolved, "AIP: Market already resolved");
        require(_winningOutcome == 1 || _winningOutcome == 2, "AIP: Invalid winning outcome");

        market.winningOutcome = _winningOutcome;
        market.isResolved = true;

        // Calculate and collect platform fees from total market collateral
        uint256 totalMarketValue = market.totalCollateral;
        uint256 platformFee = (totalMarketValue * platformFeeBps) / 10000;
        totalPlatformFeesCollected += platformFee;
        // The remaining amount (totalMarketValue - platformFee) is available for payouts

        // Iterate through all predictions to update model accuracy
        for (uint i = 0; i < market.predictedTokenIds.length; i++) {
            uint256 tokenId = market.predictedTokenIds[i];
            if (market.predictions[tokenId] == _winningOutcome) {
                updateModelAccuracy(tokenId, true);
                // Winnings are claimed by model owners later via claimPredictionWinnings
            } else {
                updateModelAccuracy(tokenId, false);
            }
        }

        emit MarketResolved(_marketId, _winningOutcome);
    }

    /**
     * @dev Allows an AI model owner to claim winnings if their model predicted correctly.
     *      A portion of these winnings is automatically redirected to the model's staker reward pool.
     * @param _marketId The ID of the market.
     * @param _tokenId The ID of the AI model dPNFT.
     */
    function claimPredictionWinnings(uint256 _marketId, uint256 _tokenId)
        external
        onlyAIModelOwner(_tokenId)
        nonReentrant
        pausable
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.marketId != 0, "AIP: Market does not exist");
        require(market.isResolved, "AIP: Market not yet resolved");
        require(market.predictions[_tokenId] == market.winningOutcome, "AIP: Model predicted incorrectly");
        require(!market.hasClaimedWinnings[_tokenId], "AIP: Winnings already claimed for this model");

        market.hasClaimedWinnings[_tokenId] = true;

        // The gross amount for this specific correct prediction (before platform fee was taken globally)
        uint256 winningAmount = market.collateralAmount;

        // Define the percentage of winnings that goes to stakers (e.g., 10%)
        uint256 stakerSharePercentageBps = 1000; // 10%
        uint256 stakerShare = (winningAmount * stakerSharePercentageBps) / 10000;
        uint256 ownerShare = winningAmount - stakerShare;

        // Add the staker's share to the model's reward pool
        stakerRewardPool[_tokenId] += stakerShare;
        // Transfer the remaining share to the model owner
        PRDX_TOKEN.transfer(msg.sender, ownerShare);

        emit WinningsClaimed(_marketId, _tokenId, ownerShare);
    }

    // --- Platform & Fee Management ---

    /**
     * @dev Sets the platform fee percentage for new markets, in basis points.
     *      (e.g., 100 = 1%, 500 = 5%)
     * @param _newFeeBps The new fee percentage in basis points.
     */
    function setPlatformFee(uint256 _newFeeBps) external onlyOwner pausable {
        require(_newFeeBps <= 10000, "AIP: Fee cannot exceed 100%"); // Max 100%
        platformFeeBps = _newFeeBps;
        emit PlatformFeeSet(_newFeeBps);
    }

    /**
     * @dev Allows the owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        require(totalPlatformFeesCollected > 0, "AIP: No fees to withdraw");
        uint256 amountToWithdraw = totalPlatformFeesCollected;
        totalPlatformFeesCollected = 0;
        PRDX_TOKEN.transfer(msg.sender, amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw);
    }

    /**
     * @dev Sets the address of the Chainlink Oracle contract.
     * @param _newOracle The address of the new Chainlink Oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "AIP: New oracle address cannot be zero");
        chainlinkOracle = IMockChainlinkOracle(_newOracle);
        emit OracleAddressSet(_newOracle);
    }

    // --- Utility & Query Functions ---

    /**
     * @dev Retrieves details about a specific prediction market.
     * @param _marketId The ID of the market.
     * @return A struct containing all market details.
     */
    function getMarketDetails(uint256 _marketId)
        public
        view
        returns (PredictionMarket memory)
    {
        require(predictionMarkets[_marketId].marketId != 0, "AIP: Market does not exist");
        return predictionMarkets[_marketId];
    }

    /**
     * @dev Retrieves a list of the top N AI models based on their reputation score.
     *      This is a simplified implementation for demonstration using bubble sort;
     *      NOT gas-efficient for a large number of models.
     *      A real-world scenario would require off-chain indexing or a specialized data structure.
     * @param _limit The maximum number of top models to return.
     * @return An array of top AI model token IDs.
     */
    function getTopPerformingModels(uint256 _limit)
        public
        view
        returns (uint256[] memory)
    {
        uint256 totalModels = totalSupply();
        if (totalModels == 0) {
            return new uint256[](0);
        }

        uint256[] memory allModelIds = new uint256[](totalModels);
        for (uint256 i = 0; i < totalModels; i++) {
            allModelIds[i] = tokenByIndex(i); // From ERC721Enumerable
        }

        // Basic bubble sort for demonstration. Inefficient for many items.
        // For production, consider external indexing or a different data structure like a max-heap.
        for (uint256 i = 0; i < totalModels; i++) {
            for (uint256 j = i + 1; j < totalModels; j++) {
                if (calculateModelReputation(allModelIds[i]) < calculateModelReputation(allModelIds[j])) {
                    uint256 temp = allModelIds[i];
                    allModelIds[i] = allModelIds[j];
                    allModelIds[j] = temp;
                }
            }
        }

        uint256 resultSize = _limit < totalModels ? _limit : totalModels;
        uint256[] memory topModels = new uint256[](resultSize);
        for (uint256 i = 0; i < resultSize; i++) {
            topModels[i] = allModelIds[i];
        }
        return topModels;
    }

    /**
     * @dev Returns the current reputation score for a given AI model.
     * @param _tokenId The ID of the AI model dPNFT.
     * @return The reputation score.
     */
    function getModelReputation(uint256 _tokenId) public view returns (uint256) {
        return calculateModelReputation(_tokenId);
    }

    /**
     * @dev Returns the staking information for a specific staker on a specific model.
     * @param _tokenId The ID of the AI model dPNFT.
     * @param _staker The address of the staker.
     * @return amountStaked The amount of PRDX staked by this staker on this model.
     */
    function getStakerInfo(uint256 _tokenId, address _staker) public view returns (uint256 amountStaked) {
        return modelStakes[_tokenId][_staker].amountStaked;
    }

    // --- Pausable Functionality ---

    /**
     * @dev Pauses the contract. Callable by owner.
     *      Prevents most state-changing user functions from being called.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Callable by owner.
     *      Re-enables state-changing user functions.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}
```