This smart contract, `AetherForge`, is designed as a decentralized platform for AI-driven predictive asset allocation. It allows users to create and manage dynamic investment portfolios whose rebalancing is guided by aggregated, external AI market predictions. The platform incorporates unique concepts like NFT-based strategy ownership, an AI agent reputation system, and a governance mechanism.

---

## **AetherForge: Decentralized AI-Driven Predictive Asset Allocation Platform**

**Outline:**

I.  **Core Infrastructure & Access Control:** Foundation of the contract, handling ownership, pausing, and fee management.
II. **Strategy NFT Management:** Defines and manages ERC-721 NFTs representing unique asset allocation strategies.
III. **Prediction Oracle & AI Model Integration:** Handles the submission, aggregation, and consumption of off-chain AI market predictions via an oracle.
IV. **Dynamic Portfolio Management & Rebalancing:** Manages user asset deposits, withdrawals, and automates rebalancing based on AI predictions and chosen strategies.
V.  **Reputation & Incentive System (for AI Providers):** Registers AI agents and tracks their performance to reward accurate predictors.
VI. **Governance & Protocol Parameters:** Enables decentralized governance over key protocol configurations.
VII. **Utility & Simulation:** Provides tools for users to understand and simulate portfolio operations.

---

**Function Summary:**

**I. Core Infrastructure & Access Control**
1.  `constructor()`: Initializes the contract, sets the owner, and deploys/links to the `AetherForgeStrategyNFT` contract.
2.  `pause()`: Pauses certain sensitive contract functionalities, typically used in emergencies. Callable by owner/governance.
3.  `unpause()`: Unpauses the contract functionalities. Callable by owner/governance.
4.  `setProtocolFeeRecipient(address _recipient)`: Sets the address where protocol fees are collected. Callable by owner/governance.
5.  `withdrawProtocolFees(address _token, uint256 _amount)`: Allows the fee recipient to withdraw collected fees for a specific token.

**II. Strategy NFT Management**
6.  `createAdaptiveStrategy(string memory _name, string memory _description, uint256 _riskTolerance, address[] memory _allowedAssets)`: Mints a new `AetherForgeStrategyNFT` for the caller, defining an asset allocation strategy template.
7.  `updateStrategyTemplate(uint256 _strategyId, string memory _name, string memory _description, uint256 _riskTolerance, address[] memory _allowedAssets)`: Allows the owner of a Strategy NFT to modify its underlying parameters.
8.  `setStrategyNFTMetadataURI(uint256 _strategyId, string memory _newURI)`: Allows the owner of a Strategy NFT to update its metadata URI, potentially for dynamic representations.
9.  `transferStrategyNFTOwnership(address _from, address _to, uint256 _strategyId)`: Standard ERC-721 transfer function, inherited from `AetherForgeStrategyNFT`.
10. `getStrategyTemplateDetails(uint256 _strategyId)`: Retrieves the configurable parameters of a specific Strategy NFT.

**III. Prediction Oracle & AI Model Integration**
11. `submitAIPrediction(uint256 _agentId, address _asset, uint256 _predictionValue, uint256 _confidenceScore, uint256 _predictionTimestamp)`: Allows whitelisted AI model providers to submit their market predictions for specific assets.
12. `requestPredictionAggregation(address _asset)`: Triggers an external oracle call to aggregate recent AI predictions for a given asset (e.g., median, weighted average).
13. `fulfillPredictionAggregation(bytes32 _requestId, address _asset, uint256 _aggregatedValue, uint256 _timestamp)`: Callback function executed by the trusted oracle, delivering the aggregated prediction result. (Only callable by `trustedOracleAddress`).
14. `addAITruster(address _agentAddress)`: Whitelists an address as a trusted AI model provider, allowing them to submit predictions. Callable by owner/governance.
15. `removeAITruster(address _agentAddress)`: Removes an address from the trusted AI model provider whitelist. Callable by owner/governance.
16. `getLatestAggregatedPrediction(address _asset)`: Retrieves the most recently fulfilled aggregated prediction for a given asset.

**IV. Dynamic Portfolio Management & Rebalancing**
17. `depositIntoPortfolio(uint256 _strategyId, address _token, uint256 _amount)`: Users deposit base assets into a portfolio, linked to their chosen Strategy NFT.
18. `withdrawFromPortfolio(uint256 _strategyId, address _token, uint256 _amount)`: Users withdraw assets from their portfolio.
19. `initiateRebalance(uint256 _strategyId)`: Triggers a rebalancing operation for a user's portfolio based on the latest aggregated prediction and their chosen Strategy NFT. Interacts with an AMM (e.g., Uniswap V3 Router).
20. `getPortfolioValue(uint256 _strategyId, address _quoteToken)`: Calculates the current value of a user's portfolio, denominated in a specified quote token.
21. `setSupportedToken(address _token, bool _isSupported)`: Owner/DAO adds or removes supported tokens for deposit/trading within portfolios.
22. `updateAMMRouter(address _newRouterAddress)`: Updates the address of the Automated Market Maker (AMM) router used for rebalancing. Callable by owner/governance.

**V. Reputation & Incentive System (for AI Providers)**
23. `registerAIAgent(string memory _agentName, string memory _agentDescription)`: AI providers register their agent with a unique identifier and initially zero reputation.
24. `updateAgentReputationScore(uint256 _agentId, int256 _delta)`: Internal function called after prediction aggregation to update an AI agent's reputation based on the accuracy of their submitted predictions.
25. `claimAIAgentRewards(uint256 _agentId)`: Allows high-reputation AI agents to claim rewards from a protocol pool (rewards mechanism not fully implemented in this example but conceptually present).
26. `getAIAgentReputation(uint256 _agentId)`: Retrieves the current reputation score of a registered AI agent.

**VI. Governance & Protocol Parameters**
27. `proposeConfigChange(bytes memory _callData, string memory _description)`: Allows a whitelisted address (or governance token holders) to propose a change to a protocol parameter.
28. `voteOnConfigProposal(uint256 _proposalId, bool _support)`: Allows whitelisted voters to vote on a governance proposal.
29. `executeConfigProposal(uint256 _proposalId)`: Executes a successful proposal after its voting period has ended and it has passed.

**VII. Utility & Simulation**
30. `simulateRebalanceEffect(uint256 _strategyId, address _currentPredictionAsset, uint256 _currentPredictionValue)`: Allows users to simulate the outcome of a rebalance operation on their portfolio without executing it on-chain, using a hypothetical prediction.
31. `getExpectedRebalanceOutput(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _slippage)`: Calculates the expected output amount for a swap given current prices (simulated via AMM interface) and a slippage tolerance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Interfaces for external contracts (e.g., AMM Router, Oracle)
interface IUniswapV3Router {
    // Simplified interface for a swap function. Real AMMs have more complex interfaces.
    // This is for demonstration purposes.
    function exactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address recipient,
        uint256 deadline,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}

interface IAetherForgeOracle {
    // Function the AetherForge contract will call on the Oracle to request data
    function requestData(string memory _jobId, uint256 _callbackGasLimit, bytes memory _data) external returns (bytes32 requestId);

    // Placeholder for a function the Oracle would call to get status (if needed)
    function getJobStatus(bytes32 _jobId) external view returns (bool exists, bool completed, bytes memory result);
}


// --- AetherForgeStrategyNFT Contract ---
// This contract handles the minting and management of Strategy NFTs.
// It's separated for modularity and to adhere to the ERC-721 standard.
contract AetherForgeStrategyNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Struct to define the parameters of an adaptive strategy
    struct StrategyTemplate {
        string name;
        string description;
        uint256 riskTolerance; // e.g., 1-100, lower for conservative, higher for aggressive
        address[] allowedAssets; // Whitelisted assets for this strategy
        string metadataURI; // URI for off-chain metadata (e.g., IPFS link to JSON)
    }

    // Mapping from tokenId to StrategyTemplate
    mapping(uint256 => StrategyTemplate) public strategyTemplates;

    // Event for strategy creation
    event StrategyCreated(uint256 indexed tokenId, address indexed creator, string name);
    // Event for strategy update
    event StrategyUpdated(uint256 indexed tokenId, string name, uint256 riskTolerance);

    // Modifier to ensure only the NFT owner can update its template
    modifier onlyStrategyOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AFSN: Not strategy owner or approved");
        _;
    }

    constructor() ERC721("AetherForge Strategy NFT", "AFSN") Ownable(msg.sender) {}

    // Function to mint a new Strategy NFT
    function createStrategy(
        address _to,
        string memory _name,
        string memory _description,
        uint256 _riskTolerance,
        address[] memory _allowedAssets,
        string memory _metadataURI
    ) external onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _mint(_to, newItemId);
        _setTokenURI(newItemId, _metadataURI); // Set initial metadata URI

        strategyTemplates[newItemId] = StrategyTemplate({
            name: _name,
            description: _description,
            riskTolerance: _riskTolerance,
            allowedAssets: _allowedAssets,
            metadataURI: _metadataURI
        });

        emit StrategyCreated(newItemId, _to, _name);
        return newItemId;
    }

    // Function to update an existing Strategy NFT's template parameters
    function updateStrategyTemplate(
        uint256 _strategyId,
        string memory _newName,
        string memory _newDescription,
        uint256 _newRiskTolerance,
        address[] memory _newAllowedAssets
    ) external onlyStrategyOwner(_strategyId) {
        StrategyTemplate storage template = strategyTemplates[_strategyId];
        template.name = _newName;
        template.description = _newDescription;
        template.riskTolerance = _newRiskTolerance;
        template.allowedAssets = _newAllowedAssets; // Overwrite completely

        emit StrategyUpdated(_strategyId, _newName, _newRiskTolerance);
    }

    // Function to update the metadata URI for a Strategy NFT
    function setTokenURI(uint256 _tokenId, string memory _newURI) public onlyStrategyOwner(_tokenId) {
        _setTokenURI(_tokenId, _newURI);
        strategyTemplates[_tokenId].metadataURI = _newURI; // Also update in our struct
    }

    // Override base ERC721 _approve and _transfer functions to make them internal if needed,
    // or keep them public if external transfers are desired. For simplicity,
    // we assume the base ERC721 functions are sufficient for transfer and approvals.
    // The main AetherForge contract will call the `createStrategy` function.
}


// --- AetherForge Main Contract ---
contract AetherForge is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- State Variables ---
    AetherForgeStrategyNFT public strategyNFT; // Address of the deployed AetherForgeStrategyNFT contract
    address public trustedOracleAddress;       // Address of the trusted oracle contract
    address public ammRouterAddress;           // Address of the AMM router (e.g., Uniswap V3 Router)
    address public protocolFeeRecipient;       // Address to send protocol fees
    uint256 public protocolFeeBasisPoints;     // Protocol fee (e.g., 50 for 0.5%)

    // AI Agent related
    Counters.Counter private _aiAgentIdCounter;
    struct AIAgent {
        string name;
        string description;
        int256 reputationScore; // Can be positive or negative
        address agentAddress;   // The address associated with the agent
    }
    mapping(uint256 => AIAgent) public aiAgents;
    mapping(address => uint256) public aiAgentAddressToId; // Map address to agent ID
    mapping(address => bool) public isTrustedAITruster;    // Whitelist for AI model providers

    // Prediction related
    struct Prediction {
        uint256 agentId;
        address asset;
        uint256 predictionValue;   // e.g., price prediction scaled by decimals
        uint256 confidenceScore;   // e.g., 1-100
        uint256 predictionTimestamp; // Timestamp of prediction submission
    }
    mapping(address => Prediction) public latestAggregatedPredictions; // asset => latest aggregated prediction
    mapping(address => bytes32) public pendingOracleRequests;          // asset => request ID for pending aggregation

    // Portfolio related
    struct Portfolio {
        uint256 strategyId;
        mapping(address => uint256) balances; // Token address => amount
        address[] heldTokens; // List of tokens currently held for easy iteration
    }
    mapping(address => mapping(uint256 => Portfolio)) public portfolios; // user => strategyId => Portfolio
    mapping(address => bool) public supportedTokens; // Whitelist of supported ERC20 tokens

    // Governance related
    Counters.Counter private _proposalIdCounter;
    struct Proposal {
        address proposer;
        bytes callData;         // The function call to execute if proposal passes
        string description;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
        bool passed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant VOTING_PERIOD = 7 days; // Example voting period
    address[] public governanceVoters; // Example: simple whitelist for voters. Could be a governance token.

    // --- Events ---
    event ProtocolFeeRecipientSet(address indexed _recipient);
    event ProtocolFeesWithdrawn(address indexed _token, uint256 _amount);
    event AIPredictionSubmitted(uint256 indexed agentId, address indexed asset, uint256 predictionValue, uint256 confidenceScore);
    event PredictionAggregationRequested(address indexed asset, bytes32 requestId);
    event PredictionAggregationFulfilled(address indexed asset, uint256 aggregatedValue, uint256 timestamp);
    event AITrusterAdded(address indexed agentAddress);
    event AITrusterRemoved(address indexed agentAddress);
    event DepositMade(address indexed user, uint256 indexed strategyId, address indexed token, uint256 amount);
    event WithdrawalMade(address indexed user, uint256 indexed strategyId, address indexed token, uint256 amount);
    event PortfolioRebalanced(address indexed user, uint256 indexed strategyId, uint256 oldPortfolioValue, uint256 newPortfolioValue);
    event SupportedTokenSet(address indexed token, bool isSupported);
    event AMMRouterUpdated(address indexed newRouterAddress);
    event AIAgentRegistered(uint256 indexed agentId, address indexed agentAddress, string name);
    event AIAgentReputationUpdated(uint256 indexed agentId, int256 newReputationScore);
    event AIAgentRewardsClaimed(uint256 indexed agentId, address indexed claimant, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);

    // --- Constructor ---
    constructor(address _strategyNFTAddress, address _trustedOracleAddress, address _ammRouterAddress) Ownable(msg.sender) Pausable() {
        require(_strategyNFTAddress != address(0), "AetherForge: Invalid strategy NFT address");
        require(_trustedOracleAddress != address(0), "AetherForge: Invalid oracle address");
        require(_ammRouterAddress != address(0), "AetherForge: Invalid AMM router address");

        strategyNFT = AetherForgeStrategyNFT(_strategyNFTAddress);
        trustedOracleAddress = _trustedOracleAddress;
        ammRouterAddress = _ammRouterAddress;
        protocolFeeRecipient = msg.sender; // Default to owner, can be changed by governance
        protocolFeeBasisPoints = 50; // 0.5% default fee

        // Example: Add initial governance voters (could be replaced by a token-based voting system)
        governanceVoters.push(msg.sender);
    }

    // --- I. Core Infrastructure & Access Control ---

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function setProtocolFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "AetherForge: Invalid recipient address");
        protocolFeeRecipient = _recipient;
        emit ProtocolFeeRecipientSet(_recipient);
    }

    function withdrawProtocolFees(address _token, uint256 _amount) external {
        require(msg.sender == protocolFeeRecipient, "AetherForge: Only fee recipient can withdraw");
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "AetherForge: Insufficient fees");
        IERC20(_token).safeTransfer(protocolFeeRecipient, _amount);
        emit ProtocolFeesWithdrawn(_token, _amount);
    }

    // --- II. Strategy NFT Management ---
    // (create, update, get details handled by AetherForgeStrategyNFT contract directly,
    // but the main contract will interact with it. Transfer is standard ERC721)

    // Helper to get strategy details from the linked NFT contract
    function getStrategyTemplateDetails(uint256 _strategyId)
        public view
        returns (string memory name, string memory description, uint256 riskTolerance, address[] memory allowedAssets, string memory metadataURI)
    {
        AetherForgeStrategyNFT.StrategyTemplate memory template = strategyNFT.strategyTemplates(_strategyId);
        return (template.name, template.description, template.riskTolerance, template.allowedAssets, template.metadataURI);
    }


    // --- III. Prediction Oracle & AI Model Integration ---

    function submitAIPrediction(
        uint256 _agentId,
        address _asset,
        uint256 _predictionValue,
        uint256 _confidenceScore,
        uint256 _predictionTimestamp
    ) external whenNotPaused {
        require(isTrustedAITruster[msg.sender], "AetherForge: Caller not a trusted AI provider");
        require(aiAgentAddressToId[msg.sender] == _agentId, "AetherForge: Invalid agent ID for caller");
        require(supportedTokens[_asset], "AetherForge: Asset not supported");
        require(_predictionTimestamp <= block.timestamp, "AetherForge: Future timestamp not allowed");

        // Store the individual prediction for later aggregation and reputation calculation
        // In a real system, you'd store all recent predictions for aggregation, not just overwrite.
        // For simplicity, this example assumes immediate use or a separate off-chain process collects.
        // The oracle will handle actual aggregation.

        emit AIPredictionSubmitted(_agentId, _asset, _predictionValue, _confidenceScore);
    }

    function requestPredictionAggregation(address _asset) external whenNotPaused {
        require(supportedTokens[_asset], "AetherForge: Asset not supported for prediction");
        require(pendingOracleRequests[_asset] == bytes32(0), "AetherForge: Prediction aggregation already pending for this asset");

        // Prepare data for the oracle. A real oracle might need specific job IDs or parameters.
        // This is a simplified example.
        bytes memory data = abi.encodePacked("getAggregatedPrediction(", _asset, ")");
        bytes32 requestId = IAetherForgeOracle(trustedOracleAddress).requestData("AGGREGATE_PREDICTION_JOB", 200000, data);
        pendingOracleRequests[_asset] = requestId;

        emit PredictionAggregationRequested(_asset, requestId);
    }

    // This function is a callback from the trusted oracle.
    function fulfillPredictionAggregation(
        bytes32 _requestId,
        address _asset,
        uint256 _aggregatedValue,
        uint256 _timestamp
    ) external {
        require(msg.sender == trustedOracleAddress, "AetherForge: Only trusted oracle can fulfill");
        require(pendingOracleRequests[_asset] == _requestId, "AetherForge: Mismatched request ID or no pending request");

        latestAggregatedPredictions[_asset] = Prediction({
            agentId: 0, // Not applicable for aggregated value
            asset: _asset,
            predictionValue: _aggregatedValue,
            confidenceScore: 100, // Aggregated value is assumed highly confident
            predictionTimestamp: _timestamp
        });

        delete pendingOracleRequests[_asset]; // Clear pending request

        // In a more complex system, this is where you'd iterate through recent individual predictions
        // for `_asset` and call `updateAgentReputationScore` based on their accuracy against `_aggregatedValue`.

        emit PredictionAggregationFulfilled(_asset, _aggregatedValue, _timestamp);
    }

    function addAITruster(address _agentAddress) external onlyOwner {
        require(_agentAddress != address(0), "AetherForge: Invalid address");
        isTrustedAITruster[_agentAddress] = true;
        emit AITrusterAdded(_agentAddress);
    }

    function removeAITruster(address _agentAddress) external onlyOwner {
        require(_agentAddress != address(0), "AetherForge: Invalid address");
        isTrustedAITruster[_agentAddress] = false;
        emit AITrusterRemoved(_agentAddress);
    }

    function getLatestAggregatedPrediction(address _asset) public view returns (uint256, uint256) {
        Prediction memory p = latestAggregatedPredictions[_asset];
        require(p.predictionTimestamp > 0, "AetherForge: No aggregated prediction available for this asset");
        return (p.predictionValue, p.predictionTimestamp);
    }

    // --- IV. Dynamic Portfolio Management & Rebalancing ---

    function depositIntoPortfolio(uint256 _strategyId, address _token, uint256 _amount) external whenNotPaused {
        require(strategyNFT.ownerOf(_strategyId) == msg.sender, "AetherForge: Not the owner of this strategy NFT");
        require(supportedTokens[_token], "AetherForge: Token not supported for deposits");
        require(_amount > 0, "AetherForge: Deposit amount must be greater than zero");

        Portfolio storage userPortfolio = portfolios[msg.sender][_strategyId];
        if (userPortfolio.strategyId == 0) {
            // First deposit for this strategy ID
            userPortfolio.strategyId = _strategyId;
        }

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        userPortfolio.balances[_token] += _amount;

        bool found = false;
        for (uint256 i = 0; i < userPortfolio.heldTokens.length; i++) {
            if (userPortfolio.heldTokens[i] == _token) {
                found = true;
                break;
            }
        }
        if (!found) {
            userPortfolio.heldTokens.push(_token);
        }

        emit DepositMade(msg.sender, _strategyId, _token, _amount);
    }

    function withdrawFromPortfolio(uint256 _strategyId, address _token, uint256 _amount) external whenNotPaused {
        require(strategyNFT.ownerOf(_strategyId) == msg.sender, "AetherForge: Not the owner of this strategy NFT");
        Portfolio storage userPortfolio = portfolios[msg.sender][_strategyId];
        require(userPortfolio.strategyId == _strategyId, "AetherForge: Portfolio does not exist for this strategy");
        require(userPortfolio.balances[_token] >= _amount, "AetherForge: Insufficient balance in portfolio");
        require(_amount > 0, "AetherForge: Withdraw amount must be greater than zero");

        userPortfolio.balances[_token] -= _amount;
        IERC20(_token).safeTransfer(msg.sender, _amount);

        // Remove token from heldTokens array if balance becomes zero
        if (userPortfolio.balances[_token] == 0) {
            for (uint256 i = 0; i < userPortfolio.heldTokens.length; i++) {
                if (userPortfolio.heldTokens[i] == _token) {
                    userPortfolio.heldTokens[i] = userPortfolio.heldTokens[userPortfolio.heldTokens.length - 1];
                    userPortfolio.heldTokens.pop();
                    break;
                }
            }
        }

        emit WithdrawalMade(msg.sender, _strategyId, _token, _amount);
    }

    function initiateRebalance(uint256 _strategyId) external whenNotPaused {
        require(strategyNFT.ownerOf(_strategyId) == msg.sender, "AetherForge: Not the owner of this strategy NFT");
        Portfolio storage userPortfolio = portfolios[msg.sender][_strategyId];
        require(userPortfolio.strategyId == _strategyId, "AetherForge: Portfolio does not exist for this strategy");
        require(userPortfolio.heldTokens.length > 0, "AetherForge: Portfolio has no assets to rebalance");

        // Get strategy template details
        AetherForgeStrategyNFT.StrategyTemplate memory template = strategyNFT.strategyTemplates(_strategyId);
        require(template.riskTolerance > 0, "AetherForge: Strategy not configured");

        // Get the latest aggregated prediction for relevant assets
        // This is a simplified example, a real system would need to fetch predictions for all relevant assets
        // or a specific target asset. For now, let's assume one target asset the strategy focuses on.
        // We'll use a hardcoded example for `_targetAsset`
        address targetAsset = template.allowedAssets[0]; // Example: Assume the first allowed asset is the target
        (uint256 predictedValue, uint256 predictionTimestamp) = getLatestAggregatedPrediction(targetAsset);
        require(predictedValue > 0, "AetherForge: No recent prediction for target asset");
        require(block.timestamp - predictionTimestamp < 1 hours, "AetherForge: Prediction is too old"); // Example freshness check

        // --- Rebalancing Logic (Simplified) ---
        // The actual rebalancing logic here is highly complex and depends on the strategy,
        // risk tolerance, current portfolio composition, and prediction.
        // This is a conceptual example:
        // 1. Calculate current portfolio value (e.g., in ETH/USDC)
        uint256 oldPortfolioValue = getPortfolioValue(msg.sender, _strategyId, targetAsset); // Using targetAsset as quote

        // 2. Determine target allocation based on `predictedValue` and `riskTolerance`
        //    (e.g., if predictedValue goes up for targetAsset, increase allocation to it)
        //    This part requires complex off-chain calculation or on-chain price feeds.
        //    For this example, we'll simulate a simple swap based on a hypothetical need.
        //    Let's say the strategy decides to swap 10% of some token to the target asset.

        address tokenToSell = userPortfolio.heldTokens[0]; // Example: Sell the first token
        if (tokenToSell == targetAsset && userPortfolio.heldTokens.length > 1) {
            tokenToSell = userPortfolio.heldTokens[1]; // Don't sell the target asset if it's the only one
        } else if (tokenToSell == targetAsset && userPortfolio.heldTokens.length == 1) {
            // Cannot rebalance if only target asset is held and it is also the sell token
            return; // No rebalance needed or possible
        }

        uint256 amountToSell = userPortfolio.balances[tokenToSell] / 10; // Sell 10% of this token
        if (amountToSell == 0) {
            return; // Not enough to sell
        }

        // 3. Execute swaps via AMM
        IERC20(tokenToSell).safeApprove(ammRouterAddress, amountToSell);

        // Call the AMM Router to perform the swap
        uint256 amountOutMin = 1; // Simplified: set a very low minimum for demonstration
        uint256 deadline = block.timestamp + 300; // 5 minutes deadline
        uint24 fee = 3000; // Example fee for Uniswap V3 (0.3%)

        // A real implementation would consider fees dynamically and `sqrtPriceLimitX96` for specific pools.
        // For demonstration, we'll use a placeholder `exactInputSingle`
        uint256 amountReceived = IUniswapV3Router(ammRouterAddress).exactInputSingle(
            tokenToSell,
            targetAsset,
            fee,
            address(this), // Send output to this contract, then update portfolio
            deadline,
            amountToSell,
            amountOutMin,
            0 // sqrtPriceLimitX96, 0 for no limit
        );

        // Update portfolio balances after successful swap
        userPortfolio.balances[tokenToSell] -= amountToSell;
        userPortfolio.balances[targetAsset] += amountReceived;

        // Ensure targetAsset is in heldTokens
        bool foundTarget = false;
        for (uint256 i = 0; i < userPortfolio.heldTokens.length; i++) {
            if (userPortfolio.heldTokens[i] == targetAsset) {
                foundTarget = true;
                break;
            }
        }
        if (!foundTarget) {
            userPortfolio.heldTokens.push(targetAsset);
        }

        // Remove token from heldTokens if balance becomes zero after trade
        if (userPortfolio.balances[tokenToSell] == 0) {
            for (uint256 i = 0; i < userPortfolio.heldTokens.length; i++) {
                if (userPortfolio.heldTokens[i] == tokenToSell) {
                    userPortfolio.heldTokens[i] = userPortfolio.heldTokens[userPortfolio.heldTokens.length - 1];
                    userPortfolio.heldTokens.pop();
                    break;
                }
            }
        }


        // 4. Calculate new portfolio value
        uint256 newPortfolioValue = getPortfolioValue(msg.sender, _strategyId, targetAsset);

        emit PortfolioRebalanced(msg.sender, _strategyId, oldPortfolioValue, newPortfolioValue);
    }

    // Helper function to get current portfolio value
    // This function is simplified and would require robust on-chain price oracles for each token.
    // For this example, it assumes a fixed conversion rate or a very simple oracle lookup.
    function getPortfolioValue(address _user, uint256 _strategyId, address _quoteToken) public view returns (uint256) {
        Portfolio storage userPortfolio = portfolios[_user][_strategyId];
        require(userPortfolio.strategyId == _strategyId, "AetherForge: Portfolio does not exist");

        uint256 totalValue = 0;
        // In a real dApp, you'd use a robust price oracle (e.g., Chainlink) for each token.
        // For simplicity, let's assume _quoteToken is the reference, and other tokens
        // can be converted via a mock price feed or AMM quote.
        for (uint256 i = 0; i < userPortfolio.heldTokens.length; i++) {
            address token = userPortfolio.heldTokens[i];
            uint256 amount = userPortfolio.balances[token];

            if (token == _quoteToken) {
                totalValue += amount;
            } else {
                // Mock conversion: Assume 1:1 for demonstration or get quote from AMM
                // This would be replaced by actual oracle price lookup:
                // uint256 price = IPriceOracle(oracleAddress).getPrice(token, _quoteToken);
                // totalValue += (amount * price) / 10**tokenDecimalsDifference;

                // Example using AMM quote (highly simplified, no path, just direct pair)
                // This would need proper Uniswap V3 quoting for different fees and pools
                try IUniswapV3Router(ammRouterAddress).quoteExactInputSingle(token, _quoteToken, 3000, amount, 0) returns (uint256 quotedAmount) {
                    totalValue += quotedAmount;
                } catch {
                    // Fallback or error if quote fails, maybe return 0 for this token
                    totalValue += 0; // Or handle error
                }
            }
        }
        return totalValue;
    }

    function setSupportedToken(address _token, bool _isSupported) external onlyOwner {
        require(_token != address(0), "AetherForge: Invalid token address");
        supportedTokens[_token] = _isSupported;
        emit SupportedTokenSet(_token, _isSupported);
    }

    function updateAMMRouter(address _newRouterAddress) external onlyOwner {
        require(_newRouterAddress != address(0), "AetherForge: Invalid AMM router address");
        ammRouterAddress = _newRouterAddress;
        emit AMMRouterUpdated(_newRouterAddress);
    }

    // --- V. Reputation & Incentive System (for AI Providers) ---

    function registerAIAgent(string memory _agentName, string memory _agentDescription) external {
        require(aiAgentAddressToId[msg.sender] == 0, "AetherForge: Address already registered as an AI agent");

        _aiAgentIdCounter.increment();
        uint256 newAgentId = _aiAgentIdCounter.current();

        aiAgents[newAgentId] = AIAgent({
            name: _agentName,
            description: _agentDescription,
            reputationScore: 0, // Start with zero reputation
            agentAddress: msg.sender
        });
        aiAgentAddressToId[msg.sender] = newAgentId;

        // Automatically add to trusted list upon registration for simplicity in this example
        // In a real system, this might require a governance vote or stake.
        isTrustedAITruster[msg.sender] = true;

        emit AIAgentRegistered(newAgentId, msg.sender, _agentName);
    }

    // This function would be called internally, likely by the oracle fulfillment callback
    // or by a separate resolver, to update agent scores based on prediction accuracy.
    function updateAgentReputationScore(uint256 _agentId, int256 _delta) internal {
        require(_agentId <= _aiAgentIdCounter.current() && _agentId > 0, "AetherForge: Invalid agent ID");
        aiAgents[_agentId].reputationScore += _delta;
        emit AIAgentReputationUpdated(_agentId, aiAgents[_agentId].reputationScore);
    }

    function claimAIAgentRewards(uint256 _agentId) external {
        require(aiAgents[_agentId].agentAddress == msg.sender, "AetherForge: Not the agent owner");
        // This is a placeholder for a complex reward distribution mechanism.
        // Rewards could be based on reputation, successful rebalances using their predictions,
        // or a share of protocol fees.
        // For demonstration, let's assume a mock reward.
        int256 currentReputation = aiAgents[_agentId].reputationScore;
        require(currentReputation > 100, "AetherForge: Insufficient reputation for rewards"); // Example threshold

        // Example: Reward based on reputation score (needs a reward token/pool setup)
        uint256 rewardAmount = uint256(currentReputation / 100) * 1 ether; // 1 unit of some token per 100 reputation
        // IERC20(rewardToken).safeTransfer(msg.sender, rewardAmount);

        // Reset reputation or reduce it after claiming to prevent infinite claims
        aiAgents[_agentId].reputationScore = 0; // Simplified
        emit AIAgentRewardsClaimed(_agentId, msg.sender, rewardAmount);
    }

    function getAIAgentReputation(uint256 _agentId) public view returns (int256) {
        require(_agentId <= _aiAgentIdCounter.current() && _agentId > 0, "AetherForge: Invalid agent ID");
        return aiAgents[_agentId].reputationScore;
    }

    // --- VI. Governance & Protocol Parameters ---
    // Simple whitelist based voting for now. Could be upgraded to a governance token based system.

    function proposeConfigChange(bytes memory _callData, string memory _description) external {
        // Only existing governance voters can propose for this example
        bool isVoter = false;
        for (uint256 i = 0; i < governanceVoters.length; i++) {
            if (governanceVoters[i] == msg.sender) {
                isVoter = true;
                break;
            }
        }
        require(isVoter, "AetherForge: Only whitelisted voters can propose");
        require(_callData.length > 0, "AetherForge: Proposal call data cannot be empty");
        require(bytes(_description).length > 0, "AetherForge: Proposal description cannot be empty");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            callData: _callData,
            description: _description,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + VOTING_PERIOD,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize mapping
            executed: false,
            passed: false
        });

        emit ProposalCreated(newProposalId, msg.sender, _description);
    }

    function voteOnConfigProposal(uint256 _proposalId, bool _support) external {
        require(_proposalId <= _proposalIdCounter.current() && _proposalId > 0, "AetherForge: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "AetherForge: Proposal already executed");
        require(block.timestamp < proposal.votingEndTime, "AetherForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherForge: Already voted on this proposal");

        // Only existing governance voters can vote for this example
        bool isVoter = false;
        for (uint256 i = 0; i < governanceVoters.length; i++) {
            if (governanceVoters[i] == msg.sender) {
                isVoter = true;
                break;
            }
        }
        require(isVoter, "AetherForge: Not a whitelisted voter");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeConfigProposal(uint256 _proposalId) external onlyOwner {
        require(_proposalId <= _proposalIdCounter.current() && _proposalId > 0, "AetherForge: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "AetherForge: Proposal already executed");
        require(block.timestamp >= proposal.votingEndTime, "AetherForge: Voting period not ended");

        // Simple majority voting for demonstration
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.passed = true;
            // Execute the proposed function call
            (bool success, ) = address(this).call(proposal.callData);
            require(success, "AetherForge: Proposal execution failed");
        } else {
            proposal.passed = false;
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    // --- VII. Utility & Simulation ---

    // This function allows users to simulate a rebalance without actually executing trades.
    // It would typically interact with the AMM's quoting functions.
    function simulateRebalanceEffect(uint256 _strategyId, address _hypotheticalTargetAsset, uint256 _hypotheticalPredictionValue)
        public view
        returns (uint256 simulatedOldValue, uint256 simulatedNewValue)
    {
        require(strategyNFT.ownerOf(_strategyId) == msg.sender, "AFSim: Not the owner of this strategy NFT");
        Portfolio storage userPortfolio = portfolios[msg.sender][_strategyId];
        require(userPortfolio.strategyId == _strategyId, "AFSim: Portfolio does not exist");
        require(userPortfolio.heldTokens.length > 0, "AFSim: Portfolio has no assets");

        simulatedOldValue = getPortfolioValue(msg.sender, _strategyId, _hypotheticalTargetAsset);

        // Deep copy the portfolio balances for simulation
        mapping(address => uint256) tempBalances;
        address[] memory tempHeldTokens = new address[](userPortfolio.heldTokens.length);
        for (uint256 i = 0; i < userPortfolio.heldTokens.length; i++) {
            address token = userPortfolio.heldTokens[i];
            tempBalances[token] = userPortfolio.balances[token];
            tempHeldTokens[i] = token;
        }

        // --- Simplified Simulation of Trade ---
        // Based on hypothetical prediction, calculate a hypothetical swap
        // This is a very basic example; a real simulation would need a complex strategy engine.
        address tokenToSell;
        uint256 amountToSell;

        // Try to find a token to sell that is not the target
        for (uint256 i = 0; i < tempHeldTokens.length; i++) {
            if (tempHeldTokens[i] != _hypotheticalTargetAsset && tempBalances[tempHeldTokens[i]] > 0) {
                tokenToSell = tempHeldTokens[i];
                amountToSell = tempBalances[tokenToSell] / 5; // Sell 20% for simulation
                if (amountToSell > 0) break;
            }
        }

        if (tokenToSell == address(0) || amountToSell == 0) {
            // Cannot simulate a meaningful rebalance if no other token to sell
            return (simulatedOldValue, simulatedOldValue);
        }

        // Simulate swap using AMM's quote function
        uint24 fee = 3000; // Example Uniswap V3 fee
        uint256 simulatedAmountOut = 0;
        try IUniswapV3Router(ammRouterAddress).quoteExactInputSingle(tokenToSell, _hypotheticalTargetAsset, fee, amountToSell, 0) returns (uint256 quotedAmount) {
            simulatedAmountOut = quotedAmount;
        } catch {
            // If quote fails, assume no trade is possible
            return (simulatedOldValue, simulatedOldValue);
        }

        // Apply simulated trade to temp balances
        tempBalances[tokenToSell] -= amountToSell;
        tempBalances[_hypotheticalTargetAsset] += simulatedAmountOut;

        // Calculate new portfolio value based on simulated balances
        uint256 currentSimulatedValue = 0;
        for (uint256 i = 0; i < tempHeldTokens.length; i++) {
            address token = tempHeldTokens[i];
            uint256 amount = tempBalances[token];

            if (token == _hypotheticalTargetAsset) {
                currentSimulatedValue += amount;
            } else {
                try IUniswapV3Router(ammRouterAddress).quoteExactInputSingle(token, _hypotheticalTargetAsset, fee, amount, 0) returns (uint256 quotedAmount) {
                    currentSimulatedValue += quotedAmount;
                } catch {
                    currentSimulatedValue += 0; // Skip if cannot quote
                }
            }
        }
        simulatedNewValue = currentSimulatedValue;
        return (simulatedOldValue, simulatedNewValue);
    }

    // Function to get expected output for a swap from the AMM router
    function getExpectedRebalanceOutput(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _slippageBasisPoints)
        public view
        returns (uint256 expectedAmountOut, uint256 minAmountOut)
    {
        require(supportedTokens[_tokenIn], "AetherForge: TokenIn not supported");
        require(supportedTokens[_tokenOut], "AetherForge: TokenOut not supported");
        require(_amountIn > 0, "AetherForge: AmountIn must be greater than zero");
        require(_slippageBasisPoints <= 10000, "AetherForge: Slippage cannot exceed 100%"); // 10000 basis points = 100%

        uint24 fee = 3000; // Example Uniswap V3 fee, should be dynamic or configured

        try IUniswapV3Router(ammRouterAddress).quoteExactInputSingle(_tokenIn, _tokenOut, fee, _amountIn, 0) returns (uint256 quotedAmount) {
            expectedAmountOut = quotedAmount;
            minAmountOut = (expectedAmountOut * (10000 - _slippageBasisPoints)) / 10000;
        } catch {
            revert("AetherForge: Failed to get quote from AMM router");
        }
    }
}
```