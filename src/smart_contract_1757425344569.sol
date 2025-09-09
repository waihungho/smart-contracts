Here's a Solidity smart contract designed with advanced, creative, and trendy concepts, focusing on a decentralized insight network, dynamic NFTs, and predictive governance. It avoids direct duplication of open-source projects by combining unique mechanics and functions.

---

## Quantum Nexus Protocol

### Contract Overview

The **Quantum Nexus Protocol** introduces a novel framework for decentralized, adaptive decision-making and asset management. At its core, it leverages collective intelligence through a **Decentralized Insight Network (DIN)**, where users submit predictions on future events. These predictions, when accurate, enhance a user's **Dynamic Insight Orb (DIO) NFT**, which in turn grants greater influence in **Reputation-Weighted Governance** and contributes to **Adaptive Treasury Management**.

This protocol combines elements of prediction markets, dynamic NFTs, on-chain reputation systems, and a form of self-adjusting governance, designed to be resilient and forward-looking.

### Outline & Function Summary

**I. Core Structures & State:**

*   **`InsightOrb`**: ERC-721 NFT struct representing a user's staked reputation. Possesses an `insightScore` that adapts based on prediction accuracy.
*   **`PredictionMarket`**: Struct defining a prediction challenge, including its question, duration, resolution, and state.
*   **`TreasuryProposal`**: Struct for governance proposals concerning treasury asset allocation.
*   **`User`**: Tracks user-specific data like delegated voting power.

**II. Dynamic Insight Orb (DIO) Management (NFT Mechanics):**

1.  **`constructor()`**: Initializes the ERC721 token and sets initial administrative roles.
2.  **`initializeProtocol()`**: Sets up initial parameters like prediction fee and links to required external contracts (simulated).
3.  **`mintInsightOrb(string memory _metadataURI)`**: Mints a new DIO NFT for a user, requiring an initial stake. This NFT represents their participation and potential influence.
4.  **`stakeOrbForPrediction(uint256 _orbId, uint256 _marketId)`**: Locks a DIO to participate in a specific prediction market. Enhances commitment and prevents the Orb from being used elsewhere simultaneously.
5.  **`unstakeOrbFromPrediction(uint256 _orbId, uint256 _marketId)`**: Releases a DIO from a prediction market after it has been resolved.
6.  **`getOrbInsightScore(uint256 _orbId)`**: Retrieves the current `insightScore` of a specific DIO, which dictates its influence.
7.  **`evolveOrbAttributes(uint256 _orbId)`**: Simulates the update of an Orb's metadata (e.g., visual traits) based on its `insightScore`. This function would trigger off-chain metadata updates.
8.  **`transferFrom(address from, address to, uint256 tokenId)`**: Overrides the standard ERC721 transfer to prevent transferring staked Orbs.

**III. Prediction Market Operations (Decentralized Insight Network):**

9.  **`createPredictionMarket(string memory _question, uint256 _predictionDuration, uint256 _resolveTime, uint256 _requiredStakePerOrb, uint256 _oracleId)`**: Allows authorized entities (e.g., DAO governance) to propose a new prediction market. `_oracleId` is a placeholder for a specific oracle feed or resolution mechanism.
10. **`submitPredictionCommitment(uint256 _marketId, uint256 _orbId, bytes32 _commitment)`**: Users commit a hash of their prediction and a `salt`. This is a privacy-preserving step preventing front-running of predictions.
11. **`revealPrediction(uint256 _marketId, uint256 _orbId, uint256 _predictionValue, string memory _rationale, bytes32 _salt)`**: Users reveal their actual prediction, rationale, and `salt`. The contract verifies the commitment. `_predictionValue` is generic (e.g., price, index, category choice).
12. **`resolvePredictionMarket(uint256 _marketId, uint224 _actualOutcome, bytes memory _proof)`**: An authorized oracle/resolver submits the true outcome of the event. `_proof` is a placeholder for cryptographic verification (e.g., ZKP, Chainlink VRF proof). This triggers accuracy calculation and score updates.
13. **`claimPredictionRewards(uint256 _marketId, uint256 _orbId)`**: Allows users with accurate predictions to claim their share of the pooled stakes from their DIO.
14. **`getAggregatedMarketPrediction(uint256 _marketId)`**: Computes and returns the collective "wisdom" or average/median prediction from all participants in a market, weighted by Insight Scores.
15. **`getPredictionMarketStatistics(uint256 _marketId)`**: Provides various statistics for a given market (e.g., participant count, range of predictions).

**IV. Adaptive Treasury & Governance:**

16. **`depositToTreasury(address _token, uint256 _amount)`**: Allows external parties or the protocol itself to deposit assets into the decentralized treasury.
17. **`proposeTreasuryAllocation(string memory _description, address[] memory _targetAssets, uint224[] memory _percentages)`**: Users or governance propose a new strategy for allocating treasury assets.
18. **`voteOnTreasuryProposal(uint256 _proposalId, uint256 _orbId, bool _support)`**: DIO holders vote on treasury proposals. Their voting power is directly proportional to their DIO's `insightScore`.
19. **`delegateInsightVote(address _delegate)`**: Allows a DIO holder to delegate their aggregated voting power to another address.
20. **`revokeInsightVoteDelegation()`**: Revokes an existing vote delegation.
21. **`executeTreasuryAllocation(uint256 _proposalId)`**: Executes an approved treasury allocation proposal, dynamically rebalancing specified assets.
22. **`adjustPredictionFee(uint256 _newFeeBps)`**: Governance function to adjust the percentage fee taken from prediction stakes, used to fund the treasury or reward pool.
23. **`updateProtocolParameter(bytes32 _parameterKey, uint256 _newValue, bytes memory _data)`**: A generic governance function to update adaptable protocol parameters. This enables the "self-amending" nature, where specific parameters can be changed via successful prediction-driven proposals.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Mock for a generic oracle interface
interface IOracle {
    function getOutcome(uint256 _oracleId) external view returns (uint224);
}

// Mock for a generic treasury management interface
interface ITreasuryManager {
    function allocate(address[] memory _targetAssets, uint224[] memory _percentages) external;
    function deposit(address _token, uint256 _amount) external;
    function withdraw(address _token, uint256 _amount) external;
}

contract QuantumNexusProtocol is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Events ---
    event InsightOrbMinted(address indexed owner, uint256 indexed tokenId, uint256 initialStake);
    event OrbStakedForPrediction(uint256 indexed orbId, uint256 indexed marketId, address indexed staker);
    event OrbUnstakedFromPrediction(uint256 indexed orbId, uint256 indexed marketId, address indexed unstaker);
    event PredictionMarketCreated(uint256 indexed marketId, string question, uint256 duration, uint256 resolveTime);
    event PredictionCommitted(uint256 indexed marketId, uint256 indexed orbId, bytes32 commitment);
    event PredictionRevealed(uint256 indexed marketId, uint256 indexed orbId, uint256 predictionValue, string rationale);
    event PredictionMarketResolved(uint256 indexed marketId, uint224 actualOutcome, uint256 totalRewardPool);
    event PredictionRewardClaimed(uint256 indexed marketId, uint256 indexed orbId, uint256 rewardAmount);
    event InsightOrbScoreUpdated(uint256 indexed orbId, int256 scoreChange, uint256 newScore);
    event OrbAttributesEvolved(uint256 indexed orbId, uint256 newLevel);
    event TreasuryDeposit(address indexed token, uint256 amount);
    event TreasuryProposalCreated(uint256 indexed proposalId, string description);
    event TreasuryProposalVoted(uint256 indexed proposalId, uint256 indexed orbId, bool support);
    event TreasuryAllocationExecuted(uint256 indexed proposalId);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteDelegationRevoked(address indexed delegator);
    event PredictionFeeAdjusted(uint256 newFeeBps);
    event ProtocolParameterUpdated(bytes32 indexed parameterKey, uint256 newValue);

    // --- Enums ---
    enum MarketStatus { Open, CommitmentPhase, RevealPhase, Resolved, Canceled }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    // --- Structs ---

    struct InsightOrb {
        uint256 insightScore; // Reputation score, influences voting power and rewards
        uint256 stakeAmount; // Amount of tokens staked to mint/maintain the Orb
        uint256[] activeMarketStakes; // List of market IDs where this Orb is currently staked
        uint256 lastScoreUpdateTimestamp; // To prevent rapid manipulation or for decay
    }

    struct PredictionMarket {
        string question;
        uint256 predictionDuration; // Time until commitment phase ends
        uint256 revealDuration; // Time until reveal phase ends
        uint256 resolveTime; // Expected time for market resolution
        MarketStatus status;
        uint256 requiredStakePerOrb; // Token amount required per Orb to stake in this market
        uint256 totalStakedAmount; // Total tokens staked in this market (potential reward pool)
        uint224 actualOutcome; // The true outcome, set by oracle/resolver
        uint256 oracleId; // Identifier for the external oracle feed/data point
        uint256 totalCorrectPredictionsValue; // Sum of correct prediction values for weighted average
        uint256 totalCorrectInsightScore; // Sum of insight scores of correct predictors for weighted average
        uint256 totalParticipants; // Number of unique participants
    }

    struct TreasuryProposal {
        string description;
        address[] targetAssets; // Tokens to allocate
        uint224[] percentages; // Percentage of treasury to allocate to each asset (sum must be 10000 for 100%)
        uint256 deadline;
        uint256 totalVotesFor; // Sum of insightScores for 'for' votes
        uint256 totalVotesAgainst; // Sum of insightScores for 'against' votes
        ProposalStatus status;
        mapping(uint256 => bool) hasVoted; // orbId => voted
    }

    struct UserData {
        address delegate; // Address to which voting power is delegated
        bool isDelegating; // True if the user has delegated
    }

    // --- State Variables ---

    uint256 public nextOrbId;
    uint256 public nextMarketId;
    uint256 public nextProposalId;
    address public predictionStakeToken; // The token used for staking in predictions and minting Orbs

    uint256 public predictionFeeBps; // Basis points (e.g., 100 = 1%) charged on total staked amount per market
    address public treasuryAddress; // Address of the ITreasuryManager contract

    // Mappings
    mapping(uint256 => InsightOrb) public insightOrbs; // orbId => InsightOrb data
    mapping(uint256 => PredictionMarket) public predictionMarkets; // marketId => PredictionMarket data
    mapping(uint256 => mapping(uint256 => bytes32)) public predictionCommitments; // marketId => orbId => commitment hash
    mapping(uint256 => mapping(uint256 => uint256)) public revealedPredictionValues; // marketId => orbId => revealed prediction value
    mapping(uint256 => mapping(uint256 => string)) public revealedRationales; // marketId => orbId => revealed rationale
    mapping(uint256 => mapping(uint256 => bool)) public hasRevealed; // marketId => orbId => has revealed
    mapping(uint256 => mapping(uint256 => bool)) public hasClaimedReward; // marketId => orbId => has claimed
    mapping(address => UserData) public users; // address => UserData

    mapping(uint256 => TreasuryProposal) public treasuryProposals; // proposalId => TreasuryProposal data

    // Roles (can be extended with more sophisticated access control)
    address public oracleResolverAddress; // Address authorized to resolve prediction markets

    // --- Modifiers ---
    modifier onlyOracleResolver() {
        require(msg.sender == oracleResolverAddress, "Caller is not the oracle resolver");
        _;
    }

    modifier onlyPredictionStakeToken() {
        require(msg.sender == predictionStakeToken, "Invalid token address");
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == treasuryAddress, "Caller is not the Treasury Manager");
        _;
    }

    // --- Constructor ---
    constructor(
        address _predictionStakeToken,
        address _treasuryAddress,
        address _oracleResolverAddress,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        predictionStakeToken = _predictionStakeToken;
        treasuryAddress = _treasuryAddress;
        oracleResolverAddress = _oracleResolverAddress;
        predictionFeeBps = 50; // Default 0.5% fee
    }

    // --- I. Dynamic Insight Orb (DIO) Management (NFT Mechanics) ---

    // 1. initializeProtocol - Sets up initial parameters and roles (admin).
    function initializeProtocol(uint256 _initialPredictionFeeBps) public onlyOwner {
        require(_initialPredictionFeeBps <= 10000, "Fee cannot exceed 100%");
        predictionFeeBps = _initialPredictionFeeBps;
        // Further setup logic for other parameters if needed
    }

    // 2. mintInsightOrb - Mints a new Dynamic Insight Orb (NFT) for a user, requiring a stake.
    function mintInsightOrb(string memory _metadataURI) public {
        uint256 requiredStake = 1 ether; // Example: 1 token to mint an Orb
        require(IERC20(predictionStakeToken).transferFrom(msg.sender, address(this), requiredStake), "Stake transfer failed");

        uint256 tokenId = nextOrbId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _metadataURI); // Set initial metadata URI

        insightOrbs[tokenId] = InsightOrb({
            insightScore: 1000, // Starting score for new Orbs
            stakeAmount: requiredStake,
            activeMarketStakes: new uint256[](0),
            lastScoreUpdateTimestamp: block.timestamp
        });

        emit InsightOrbMinted(msg.sender, tokenId, requiredStake);
    }

    // 3. stakeOrbForPrediction - Stakes an Insight Orb into an active prediction market to participate.
    function stakeOrbForPrediction(uint256 _orbId, uint256 _marketId) public {
        require(_isApprovedOrOwner(msg.sender, _orbId), "Not owner or approved for Orb");
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Open || market.status == MarketStatus.CommitmentPhase, "Market not open for staking");
        require(block.timestamp <= market.predictionDuration, "Commitment phase has ended");

        // Check if Orb is already staked in this market
        for (uint256 i = 0; i < insightOrbs[_orbId].activeMarketStakes.length; i++) {
            require(insightOrbs[_orbId].activeMarketStakes[i] != _marketId, "Orb already staked in this market");
        }

        require(IERC20(predictionStakeToken).transferFrom(msg.sender, address(this), market.requiredStakePerOrb), "Stake transfer failed");

        insightOrbs[_orbId].activeMarketStakes.push(_marketId);
        market.totalStakedAmount = market.totalStakedAmount.add(market.requiredStakePerOrb);

        emit OrbStakedForPrediction(_orbId, _marketId, msg.sender);
    }

    // 4. unstakeOrbFromPrediction - Releases a DIO from a prediction market after it has been resolved.
    function unstakeOrbFromPrediction(uint256 _orbId, uint256 _marketId) public {
        require(_isApprovedOrOwner(msg.sender, _orbId), "Not owner or approved for Orb");
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Resolved, "Market not yet resolved");
        require(!hasClaimedReward[_marketId][_orbId], "Rewards have already been claimed for this Orb in this market.");

        bool found = false;
        uint256 index = 0;
        for (uint256 i = 0; i < insightOrbs[_orbId].activeMarketStakes.length; i++) {
            if (insightOrbs[_orbId].activeMarketStakes[i] == _marketId) {
                found = true;
                index = i;
                break;
            }
        }
        require(found, "Orb not staked in this market");

        // Remove from activeMarketStakes
        insightOrbs[_orbId].activeMarketStakes[index] = insightOrbs[_orbId].activeMarketStakes[insightOrbs[_orbId].activeMarketStakes.length - 1];
        insightOrbs[_orbId].activeMarketStakes.pop();

        emit OrbUnstakedFromPrediction(_orbId, _marketId, msg.sender);
    }

    // 5. getOrbInsightScore - Retrieves the current Insight Score of a specific Orb.
    function getOrbInsightScore(uint256 _orbId) public view returns (uint256) {
        return insightOrbs[_orbId].insightScore;
    }

    // 6. evolveOrbAttributes - Triggers a metadata update for the DIO based on its current Insight Score.
    // In a real dApp, this would interact with an off-chain service to update IPFS metadata.
    function evolveOrbAttributes(uint256 _orbId) public {
        require(_isApprovedOrOwner(msg.sender, _orbId), "Not owner or approved for Orb");
        // Simplified on-chain representation of evolution
        uint256 currentScore = insightOrbs[_orbId].insightScore;
        uint256 newLevel = currentScore.div(100); // Example: 100 score points = 1 level

        // In a real dApp, this would trigger an external system to update the NFT's metadataURI
        // Example: call an oracle/chainlink function that notifies an off-chain service
        // For demonstration, we just emit an event
        emit OrbAttributesEvolved(_orbId, newLevel);
    }

    // 7. transferFrom - Overrides the standard ERC721 transfer to prevent transferring staked Orbs.
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(insightOrbs[tokenId].activeMarketStakes.length == 0, "Cannot transfer a staked Orb.");
        super.transferFrom(from, to, tokenId);
    }

    // --- II. Prediction Market Operations (Decentralized Insight Network) ---

    // 8. createPredictionMarket - Allows authorized entities to propose a new prediction market.
    function createPredictionMarket(
        string memory _question,
        uint256 _predictionDuration, // Timestamp when commitment phase ends
        uint256 _revealDuration, // Timestamp when reveal phase ends
        uint256 _resolveTime, // Expected timestamp for market resolution
        uint256 _requiredStakePerOrb,
        uint256 _oracleId // Identifier for the oracle data source
    ) public onlyOwner returns (uint256) {
        require(_predictionDuration > block.timestamp, "Prediction duration must be in the future");
        require(_revealDuration > _predictionDuration, "Reveal duration must be after prediction duration");
        require(_resolveTime > _revealDuration, "Resolve time must be after reveal duration");
        require(_requiredStakePerOrb > 0, "Stake per Orb must be positive");

        uint256 marketId = nextMarketId++;
        predictionMarkets[marketId] = PredictionMarket({
            question: _question,
            predictionDuration: _predictionDuration,
            revealDuration: _revealDuration,
            resolveTime: _resolveTime,
            status: MarketStatus.Open,
            requiredStakePerOrb: _requiredStakePerOrb,
            totalStakedAmount: 0,
            actualOutcome: 0,
            oracleId: _oracleId,
            totalCorrectPredictionsValue: 0,
            totalCorrectInsightScore: 0,
            totalParticipants: 0
        });

        emit PredictionMarketCreated(marketId, _question, _predictionDuration, _resolveTime);
        return marketId;
    }

    // 9. submitPredictionCommitment - Users commit a hash of their prediction and a salt.
    function submitPredictionCommitment(uint256 _marketId, uint256 _orbId, bytes32 _commitment) public {
        require(_isApprovedOrOwner(msg.sender, _orbId), "Not owner or approved for Orb");
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Open || market.status == MarketStatus.CommitmentPhase, "Market not in commitment phase");
        require(block.timestamp <= market.predictionDuration, "Commitment phase has ended");

        // Check if Orb is staked for this market
        bool isStaked = false;
        for (uint256 i = 0; i < insightOrbs[_orbId].activeMarketStakes.length; i++) {
            if (insightOrbs[_orbId].activeMarketStakes[i] == _marketId) {
                isStaked = true;
                break;
            }
        }
        require(isStaked, "Orb not staked in this market");
        require(predictionCommitments[_marketId][_orbId] == bytes32(0), "Prediction already committed for this Orb and market");

        predictionCommitments[_marketId][_orbId] = _commitment;
        market.totalParticipants = market.totalParticipants.add(1); // Increment participant count

        emit PredictionCommitted(_marketId, _orbId, _commitment);
    }

    // 10. revealPrediction - Users reveal their actual prediction, rationale, and salt.
    function revealPrediction(uint256 _marketId, uint256 _orbId, uint256 _predictionValue, string memory _rationale, bytes32 _salt) public {
        require(_isApprovedOrOwner(msg.sender, _orbId), "Not owner or approved for Orb");
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Open || market.status == MarketStatus.CommitmentPhase || market.status == MarketStatus.RevealPhase, "Market not in reveal phase");
        require(block.timestamp > market.predictionDuration, "Commitment phase not ended yet");
        require(block.timestamp <= market.revealDuration, "Reveal phase has ended");

        bytes32 expectedCommitment = keccak256(abi.encodePacked(_predictionValue, _rationale, _salt));
        require(predictionCommitments[_marketId][_orbId] == expectedCommitment, "Commitment mismatch");
        require(!hasRevealed[_marketId][_orbId], "Prediction already revealed for this Orb");

        revealedPredictionValues[_marketId][_orbId] = _predictionValue;
        revealedRationales[_marketId][_orbId] = _rationale;
        hasRevealed[_marketId][_orbId] = true;

        emit PredictionRevealed(_marketId, _orbId, _predictionValue, _rationale);
    }

    // 11. resolvePredictionMarket - Oracle/trusted resolver sets the true outcome.
    function resolvePredictionMarket(uint256 _marketId, uint224 _actualOutcome, bytes memory _proof) public onlyOracleResolver {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status != MarketStatus.Resolved && market.status != MarketStatus.Canceled, "Market already resolved or canceled");
        require(block.timestamp > market.revealDuration, "Reveal phase not ended yet");

        // In a real system, _proof would be verified here (e.g., Chainlink VRF proof, ZKP)
        // For this example, we trust the oracleResolverAddress.

        market.actualOutcome = _actualOutcome;
        market.status = MarketStatus.Resolved;

        // Calculate reward pool
        uint256 feeAmount = market.totalStakedAmount.mul(predictionFeeBps).div(10000); // Fee in basis points
        uint256 rewardPool = market.totalStakedAmount.sub(feeAmount);

        // Transfer fee to treasury
        require(IERC20(predictionStakeToken).transfer(treasuryAddress, feeAmount), "Failed to transfer fee to treasury");

        // Update Orb scores and calculate weighted average for market
        uint256[] memory activeOrbs = new uint256[](0); // Collect active orb IDs for this market
        uint256 totalMarketInsightScore = 0; // Total insight score of all participants in this market
        uint256 totalCorrectInsightScore = 0;
        uint256 totalCorrectPredictionSum = 0;

        for (uint256 i = 0; i < nextOrbId; i++) {
            if (ownerOf(i) != address(0)) { // Check if Orb exists
                for (uint256 j = 0; j < insightOrbs[i].activeMarketStakes.length; j++) {
                    if (insightOrbs[i].activeMarketStakes[j] == _marketId) {
                        activeOrbs = _append(activeOrbs, i);
                        totalMarketInsightScore = totalMarketInsightScore.add(insightOrbs[i].insightScore);

                        if (hasRevealed[_marketId][i]) {
                            uint256 revealedVal = revealedPredictionValues[_marketId][i];
                            // Simple accuracy check: exact match or within a tolerance (can be more complex)
                            if (revealedVal == uint256(_actualOutcome)) {
                                updateInsightOrbScore(ownerOf(i), i, 100); // Reward for accuracy
                                totalCorrectInsightScore = totalCorrectInsightScore.add(insightOrbs[i].insightScore);
                                totalCorrectPredictionSum = totalCorrectPredictionSum.add(revealedVal.mul(insightOrbs[i].insightScore));
                            } else {
                                updateInsightOrbScore(ownerOf(i), i, -50); // Penalty for inaccuracy
                            }
                        } else {
                            // Penalty for not revealing a committed prediction
                            if (predictionCommitments[_marketId][i] != bytes32(0)) {
                                updateInsightOrbScore(ownerOf(i), i, -20);
                            }
                        }
                        break;
                    }
                }
            }
        }

        market.totalCorrectInsightScore = totalCorrectInsightScore;
        market.totalCorrectPredictionsValue = totalCorrectPredictionSum; // For weighted average or similar collective insight

        emit PredictionMarketResolved(_marketId, _actualOutcome, rewardPool);
    }

    // 12. claimPredictionRewards - Allows accurate predictors to claim their share of the pooled stakes.
    function claimPredictionRewards(uint256 _marketId, uint256 _orbId) public {
        require(_isApprovedOrOwner(msg.sender, _orbId), "Not owner or approved for Orb");
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Resolved, "Market not resolved");
        require(hasRevealed[_marketId][_orbId], "Prediction not revealed for this Orb");
        require(!hasClaimedReward[_marketId][_orbId], "Rewards already claimed for this Orb in this market");

        uint256 revealedVal = revealedPredictionValues[_marketId][_orbId];
        require(revealedVal == uint256(market.actualOutcome), "Prediction was not accurate");

        uint256 currentOrbScore = insightOrbs[_orbId].insightScore;
        uint256 rewardPool = market.totalStakedAmount.sub(market.totalStakedAmount.mul(predictionFeeBps).div(10000));

        // Calculate proportional reward based on Insight Score
        uint256 rewardAmount = 0;
        if (market.totalCorrectInsightScore > 0) {
            rewardAmount = rewardPool.mul(currentOrbScore).div(market.totalCorrectInsightScore);
        }

        require(rewardAmount > 0, "No reward to claim or invalid calculation");
        require(IERC20(predictionStakeToken).transfer(msg.sender, rewardAmount), "Reward transfer failed");

        hasClaimedReward[_marketId][_orbId] = true;
        // The individual's stake is considered part of the `totalStakedAmount` and is returned from the rewardPool
        // if they are accurate. If inaccurate, their stake remains in the pool for accurate predictors.

        emit PredictionRewardClaimed(_marketId, _orbId, rewardAmount);
    }

    // Internal helper for updating Orb scores
    function updateInsightOrbScore(address _owner, uint256 _orbId, int256 _scoreChange) internal {
        InsightOrb storage orb = insightOrbs[_orbId];
        uint256 oldScore = orb.insightScore;

        if (_scoreChange > 0) {
            orb.insightScore = orb.insightScore.add(uint256(_scoreChange));
        } else {
            // Ensure score doesn't drop below a minimum (e.g., 100 for basic participation)
            uint256 changeAbs = uint256(-_scoreChange);
            if (orb.insightScore > changeAbs) {
                orb.insightScore = orb.insightScore.sub(changeAbs);
            } else {
                orb.insightScore = 100; // Minimum score
            }
        }
        orb.lastScoreUpdateTimestamp = block.timestamp;
        emit InsightOrbScoreUpdated(_orbId, _scoreChange, orb.insightScore);
    }

    // 13. getAggregatedMarketPrediction - Calculates and returns the collective "wisdom" (e.g., median or weighted average)
    function getAggregatedMarketPrediction(uint256 _marketId) public view returns (uint256 weightedAverage) {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.status == MarketStatus.Resolved, "Market not resolved");
        require(market.totalCorrectInsightScore > 0, "No correct predictions with insight score to aggregate");

        // Weighted average of correct predictions by their orb's insight score
        weightedAverage = market.totalCorrectPredictionSum.div(market.totalCorrectInsightScore);
    }

    // 14. getPredictionMarketStatistics - Returns various statistics about a prediction market.
    function getPredictionMarketStatistics(uint256 _marketId) public view returns (uint256 totalParticipants, uint256 totalStakedAmount, MarketStatus status, uint224 actualOutcome) {
        PredictionMarket storage market = predictionMarkets[_marketId];
        return (market.totalParticipants, market.totalStakedAmount, market.status, market.actualOutcome);
    }

    // --- III. Adaptive Treasury & Governance ---

    // 15. depositToTreasury - Allows external parties or the protocol itself to deposit assets.
    function depositToTreasury(address _token, uint256 _amount) public {
        require(IERC20(_token).transferFrom(msg.sender, treasuryAddress, _amount), "Treasury deposit failed");
        ITreasuryManager(treasuryAddress).deposit(_token, _amount); // Notify treasury manager
        emit TreasuryDeposit(_token, _amount);
    }

    // 16. proposeTreasuryAllocation - Proposes a new strategy for allocating treasury assets.
    function proposeTreasuryAllocation(string memory _description, address[] memory _targetAssets, uint224[] memory _percentages) public {
        require(_targetAssets.length == _percentages.length, "Arrays length mismatch");
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _percentages.length; i++) {
            totalPercentage = totalPercentage.add(_percentages[i]);
        }
        require(totalPercentage == 10000, "Percentages must sum to 10000 (100%)"); // Bps for 100%

        uint256 proposalId = nextProposalId++;
        treasuryProposals[proposalId] = TreasuryProposal({
            description: _description,
            targetAssets: _targetAssets,
            percentages: _percentages,
            deadline: block.timestamp + 3 days, // Example: 3 days for voting
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            status: ProposalStatus.Pending
        });

        emit TreasuryProposalCreated(proposalId, _description);
    }

    // 17. voteOnTreasuryProposal - DIO holders vote on treasury proposals, weighted by insightScore.
    function voteOnTreasuryProposal(uint256 _proposalId, uint256 _orbId, bool _support) public {
        require(_isApprovedOrOwner(msg.sender, _orbId), "Not owner or approved for Orb");
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal not in pending state");
        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!proposal.hasVoted[_orbId], "Orb has already voted on this proposal");

        uint256 voterScore = getVotingPower(ownerOf(_orbId));

        if (_support) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(voterScore);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(voterScore);
        }
        proposal.hasVoted[_orbId] = true;

        emit TreasuryProposalVoted(_proposalId, _orbId, _support);
    }

    // Helper to get total voting power for an address, considering delegation
    function getVotingPower(address _voter) public view returns (uint256) {
        address currentVoter = _voter;
        // Resolve delegation chain
        while (users[currentVoter].isDelegating) {
            currentVoter = users[currentVoter].delegate;
            require(currentVoter != _voter, "Circular delegation detected"); // Prevent infinite loop
        }

        uint256 totalScore = 0;
        for (uint256 i = 0; i < nextOrbId; i++) {
            if (ownerOf(i) == currentVoter) {
                totalScore = totalScore.add(insightOrbs[i].insightScore);
            }
        }
        return totalScore;
    }


    // 18. delegateInsightVote - Allows a user to delegate their aggregated voting power to another address.
    function delegateInsightVote(address _delegate) public {
        require(_delegate != address(0), "Cannot delegate to zero address");
        require(_delegate != msg.sender, "Cannot delegate to self");
        users[msg.sender].delegate = _delegate;
        users[msg.sender].isDelegating = true;
        emit VoteDelegated(msg.sender, _delegate);
    }

    // 19. revokeInsightVoteDelegation - Revokes an existing vote delegation.
    function revokeInsightVoteDelegation() public {
        require(users[msg.sender].isDelegating, "No active delegation to revoke");
        delete users[msg.sender].delegate;
        users[msg.sender].isDelegating = false;
        emit VoteDelegationRevoked(msg.sender);
    }

    // 20. executeTreasuryAllocation - Executes an approved treasury allocation proposal.
    function executeTreasuryAllocation(uint256 _proposalId) public {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal not in pending state");
        require(block.timestamp > proposal.deadline, "Voting period not ended yet");

        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            proposal.status = ProposalStatus.Approved;
            ITreasuryManager(treasuryAddress).allocate(proposal.targetAssets, proposal.percentages);
            proposal.status = ProposalStatus.Executed;
            emit TreasuryAllocationExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
    }

    // 21. adjustPredictionFee - Governance function to adjust the percentage fee.
    function adjustPredictionFee(uint256 _newFeeBps) public onlyOwner {
        require(_newFeeBps <= 10000, "Fee cannot exceed 100%");
        predictionFeeBps = _newFeeBps;
        emit PredictionFeeAdjusted(_newFeeBps);
    }

    // 22. updateProtocolParameter - A generic governance function to update adaptable protocol parameters.
    // This function can be called via governance vote, adapting protocol logic/constants dynamically.
    // The specific parameter keys and how they impact the contract would be defined in a more complex system.
    function updateProtocolParameter(bytes32 _parameterKey, uint256 _newValue, bytes memory _data) public onlyOwner {
        // In a real system, this would be integrated with a DAO voting process
        // For demonstration, only the owner can call it.
        // Examples of parameters: minimumOrbStake, predictionMarketGracePeriod, etc.
        // The interpretation of _parameterKey and _newValue would depend on specific protocol needs.
        
        // This function symbolizes the contract's capacity for adaptive/self-amending behavior
        // without directly modifying bytecode (which would require upgradeability patterns like proxies).

        // Placeholder logic:
        // if (_parameterKey == keccak256("MIN_ORB_STAKE")) {
        //     minOrbStake = _newValue;
        // }
        // emit ProtocolParameterUpdated(_parameterKey, _newValue);

        // For this example, we just emit an event
        emit ProtocolParameterUpdated(_parameterKey, _newValue);
    }

    // Internal utility function to append to a dynamic array
    function _append(uint256[] storage arr, uint256 element) internal pure returns (uint256[] storage) {
        arr.push(element);
        return arr;
    }

    // The rest are standard ERC721 view functions or overrides for internal use.
    // ERC721 `tokenURI` and `_baseURI` can be implemented to point to an off-chain metadata service
    // where `evolveOrbAttributes` would trigger updates.
}
```