```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Contract: AetherMindNexus ---

// I. Overview
// The AetherMindNexus is a Decentralized Adaptive Intelligence Protocol (DACI) designed to foster a community-driven ecosystem
// for collective decision-making, trend prediction, and adaptive resource allocation. It combines dynamic NFTs, a
// reputation-based governance model, and AI oracle integration to create a fluid and responsive on-chain organization.
// The protocol aims to leverage collective human intelligence augmented by AI insights for more effective and transparent
// decentralized governance and resource management.

// II. Core Concepts
// *   Agent NFTs (dNFTs): Unique, mutable NFTs representing "Intelligent Agents" within the protocol. Their "Intelligence Score"
//     dynamically evolves based on the owner's on-chain contributions and reputation. Metadata (e.g., visual traits, rank)
//     adapts accordingly, visible through their dynamic tokenURI.
// *   Reputation System: A non-transferable, soulbound-like score (`Soulbound Reputation`) that reflects a user's historical
//     contributions, prediction accuracy, and positive engagement. It directly influences voting power and reward multipliers.
// *   AI Oracle Integration: The protocol interfaces with a designated AI oracle for objective (or semi-objective) assessments,
//     such as sentiment analysis of proposed ideas, generative insights, or validation of complex outcomes. This allows
//     incorporation of off-chain intelligence into on-chain decisions.
// *   Dynamic Governance: Voting power is weighted by Reputation and Agent Intelligence. Treasury allocation is determined
//     not only by community votes but also by AI-driven sentiment analysis and generative insights, leading to more adaptive funding.
// *   Gamified Prediction Markets: Users can predict outcomes or sentiment scores related to ideas or monitored topics,
//     earning rewards for accuracy and boosting their reputation, which incentivizes informed participation.

// III. Key Features
// 1.  Dynamic Agent NFTs: Mint, manage, and evolve unique Agent NFTs whose metadata dynamically reflects on-chain activity.
// 2.  Reputation-Based Access & Influence: Earn and utilize a non-transferable reputation score for enhanced voting power and rewards.
// 3.  Idea & Proposal Lifecycle: Submit, vote on, and manage the full lifecycle of community ideas and proposals.
// 4.  AI-Assisted Decision Making: Leverage AI oracles for sentiment analysis and generative insights to inform governance and resource allocation.
// 5.  Adaptive Treasury Management: Intelligently allocate funds to approved proposals based on community votes and AI assessment.
// 6.  Gamified Prediction Market: Engage in predicting outcomes and earn rewards for accuracy, fostering informed and strategic participation.
// 7.  On-chain Topic Monitoring: Register and monitor specific topics using AI for ongoing sentiment analysis and trend tracking.

// IV. Function Summary

// A. Core Protocol Management (Owner/Admin Controlled)
// 1.  `constructor(address _oracleAddress)`: Initializes the contract, setting the trusted AI oracle address and the base URI for Agent NFTs.
// 2.  `setOracleAddress(address _newOracleAddress)`: Updates the address of the trusted AI oracle.
// 3.  `pause()`: Pauses core protocol functionalities in emergencies. Only callable by the owner.
// 4.  `unpause()`: Unpauses the protocol. Only callable by the owner.
// 5.  `withdrawProtocolFees(address _to, uint256 _amount)`: Allows the owner to withdraw accumulated protocol fees (e.g., prediction market fees).

// B. Agent NFT (dNFT) Management (ERC721 Standard)
// 6.  `mintAgentNFT(address _to)`: Mints a new Agent NFT to a specified address, initializing its intelligence score to a base value.
// 7.  `burnAgentNFT(uint256 _tokenId)`: Allows an Agent NFT owner to burn their NFT, permanently removing it from circulation.
// 8.  `getAgentIntelligenceScore(uint256 _tokenId)`: Retrieves the current intelligence score of an Agent NFT.
// 9.  `_updateAgentIntelligence(uint256 _tokenId, uint256 _scoreChange, bool _increase)`: Internal function to update an Agent NFT's intelligence score.
// 10. `tokenURI(uint256 _tokenId)`: Overridden ERC721 function that returns the dynamic metadata URI for an Agent NFT, reflecting its current intelligence and other traits as a base64 encoded JSON string.

// C. Reputation System (Soulbound-like)
// 11. `earnReputation(address _user, uint256 _points)`: Awards reputation points to a user for positive contributions (e.g., accurate predictions, good ideas).
// 12. `loseReputation(address _user, uint256 _points)`: Decreases a user's reputation points for negative actions (e.g., spamming, consistently wrong predictions).
// 13. `getReputationScore(address _user)`: Retrieves a user's current soulbound reputation score.
// 14. `getEffectiveVotingPower(address _user)`: Calculates a user's total voting power, combining their reputation score and the intelligence scores of all owned Agent NFTs.

// D. Idea & Proposal Lifecycle
// 15. `submitIdea(string memory _description, uint256 _initialFundingRequest)`: Allows users to submit a new idea or proposal to the community, specifying a requested funding amount.
// 16. `voteOnIdea(uint256 _ideaId, bool _support)`: Users vote on a submitted idea (for or against) using their calculated effective voting power.
// 17. `closeIdeaVoting(uint256 _ideaId)`: Owner/Admin closes the voting period for an idea. This prepares it for AI assessment and potential funding.

// E. AI Oracle Integration
// 18. `requestAISentimentAnalysis(uint256 _ideaId)`: Initiates a request to the AI oracle to perform sentiment analysis on an idea's description.
// 19. `fulfillAISentimentAnalysis(uint256 _ideaId, int256 _sentimentScore, string memory _analysisReport)`: Callback function executed by the trusted AI oracle to update an idea with its sentiment score and a detailed report.
// 20. `requestAIGenerativeInsight(uint256 _ideaId)`: Initiates a request to the AI oracle to generate further insights or potential outcomes for a given idea.
// 21. `fulfillAIGenerativeInsight(uint256 _ideaId, string memory _generatedInsight)`: Callback function executed by the trusted AI oracle to update an idea with AI-generated insights.

// F. Adaptive Treasury & Rewards
// 22. `depositToTreasury()`: Allows anyone to deposit funds (ETH) into the protocol's treasury, which is used for funding approved ideas and rewards.
// 23. `allocateTreasuryFunds(uint256 _ideaId)`: Allocates treasury funds to an approved idea. This function considers both community voting results and AI sentiment score to make an adaptive allocation decision.
// 24. `claimRewards(uint256[] memory _predictionIds)`: Allows users to claim rewards for correct predictions in the prediction market.

// G. Prediction Market
// 25. `submitPrediction(uint256 _ideaId, int256 _predictedSentiment, uint256 _stakeAmount)`: Users stake ETH to predict the AI sentiment score of an idea before the oracle fulfills the analysis.
// 26. `evaluatePredictions(uint256 _ideaId)`: Owner/Admin triggers the evaluation of predictions for a given idea after its AI sentiment analysis has been fulfilled. Rewards are calculated and marked for claiming.

// H. Topic Monitoring
// 27. `registerTopic(string memory _description)`: Registers a new topic for continuous monitoring by the AI oracle. This could be anything from market trends to social issues.
// 28. `deregisterTopic(uint256 _topicId)`: Deregisters an existing topic, stopping its continuous AI monitoring.
// 29. `updateTopicAISentiment(uint256 _topicId, int256 _sentimentScore)`: Internal function, callable by the oracle, to update a registered topic's sentiment score based on ongoing AI analysis.

contract AetherMindNexus is Ownable, Pausable, ReentrancyGuard, ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Error Definitions ---
    error AetherMindNexus__InvalidOracleAddress();
    error AetherMindNexus__OnlyOracle();
    error AetherMindNexus__IdeaNotFound();
    error AetherMindNexus__IdeaVotingNotActive();
    error AetherMindNexus__IdeaVotingClosed();
    error AetherMindNexus__AlreadyVoted();
    error AetherMindNexus__NoVotingPower();
    error AetherMindNexus__IdeaNotReadyForFunding();
    error AetherMindNexus__InsufficientTreasuryFunds();
    error AetherMindNexus__PredictionNotFound();
    error AetherMindNexus__PredictionNotEvaluated();
    error AetherMindNexus__PredictionAlreadyClaimed();
    error AetherMindNexus__PredictionNotCorrect();
    error AetherMindNexus__NoActivePredictionsToEvaluate();
    error AetherMindNexus__TopicNotFound();
    error AetherMindNexus__InvalidTokenId();
    error AetherMindNexus__AgentNFTAlreadyMinted();
    error AetherMindNexus__NotEnoughETH();
    error AetherMindNexus__IdeaAlreadyFunded();
    error AetherMindNexus__OracleCallFailed();

    // --- Events ---
    event OracleAddressUpdated(address indexed newAddress);
    event AgentNFTMinted(address indexed owner, uint256 indexed tokenId, uint256 intelligenceScore);
    event AgentNFTBurnt(uint256 indexed tokenId);
    event AgentIntelligenceUpdated(uint256 indexed tokenId, uint256 newScore);
    event ReputationEarned(address indexed user, uint256 points);
    event ReputationLost(address indexed user, uint256 points);
    event IdeaSubmitted(uint256 indexed ideaId, address indexed proposer, string description, uint256 fundingRequest);
    event IdeaVoted(uint256 indexed ideaId, address indexed voter, bool support, uint256 votingPower);
    event IdeaVotingClosed(uint256 indexed ideaId);
    event AISentimentRequested(uint256 indexed ideaId);
    event AISentimentFulfilled(uint256 indexed ideaId, int256 sentimentScore, string analysisReport);
    event AIGenerativeInsightRequested(uint256 indexed ideaId);
    event AIGenerativeInsightFulfilled(uint256 indexed ideaId, string generatedInsight);
    event FundsDepositedToTreasury(address indexed depositor, uint256 amount);
    event TreasuryFundsAllocated(uint256 indexed ideaId, uint256 amount);
    event PredictionSubmitted(uint256 indexed predictionId, uint256 indexed ideaId, address indexed predictor, int256 predictedSentiment, uint256 stakeAmount);
    event PredictionEvaluated(uint256 indexed predictionId, bool isCorrect, uint256 rewardAmount);
    event RewardsClaimed(address indexed claimant, uint256 indexed predictionId, uint256 amount);
    event TopicRegistered(uint256 indexed topicId, string description);
    event TopicDeregistered(uint256 indexed topicId);
    event TopicAISentimentUpdated(uint256 indexed topicId, int256 newSentimentScore);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    // --- Enums ---
    enum IdeaStatus {
        Voting,
        VotingClosed,
        SentimentAnalysisPending,
        SentimentAnalysisFulfilled,
        Funded,
        Rejected
    }

    // --- Structs ---
    struct Idea {
        uint256 id;
        address proposer;
        string description;
        uint256 initialFundingRequest;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        IdeaStatus status;
        int256 aiSentimentScore; // Range -100 to 100
        string aiSentimentReport;
        string aiGenerativeInsight;
        uint256 allocatedFunds;
        uint256 votingPeriodEnd;
        mapping(address => bool) hasVoted; // Tracks if a user has voted on this idea
        mapping(address => uint256) userVoteWeight; // Stores the actual voting power used by the user
    }

    struct Prediction {
        uint256 id;
        uint256 ideaId;
        address predictor;
        int256 predictedSentiment;
        uint256 stakeAmount;
        uint256 rewardAmount;
        bool isCorrect;
        bool evaluated;
        bool claimed;
    }

    struct Topic {
        uint256 id;
        string description;
        int256 currentAISentiment; // Range -100 to 100
        uint256 lastUpdated;
    }

    // --- State Variables ---
    address public oracleAddress;
    uint256 public treasuryBalance;
    uint256 public totalProtocolFees; // Accumulated fees from prediction market

    // Agent NFT specific
    uint256 private _nextTokenId;
    uint256 public constant BASE_AGENT_INTELLIGENCE = 100; // Starting intelligence for new Agent NFTs
    uint256 public constant MAX_AGENT_INTELLIGENCE = 1000; // Cap for intelligence score
    mapping(uint256 => uint256) public agentIntelligenceScore; // tokenId => intelligence
    mapping(address => uint256[]) public userAgentNFTs; // owner => list of tokenIds
    mapping(address => bool) public hasAgentNFT; // owner => has at least one Agent NFT

    // Reputation System
    mapping(address => uint256) public userReputation; // user address => reputation score (non-transferable)

    // Idea & Proposal System
    mapping(uint256 => Idea) public ideas;
    uint256 public nextIdeaId;
    uint256 public constant VOTING_PERIOD_DURATION = 3 days; // Example duration

    // Prediction Market
    mapping(uint256 => Prediction) public predictions;
    uint256 public nextPredictionId;
    uint256 public constant PREDICTION_FEE_PERCENT = 5; // 5% fee on stakes goes to protocol

    // Topic Monitoring
    mapping(uint256 => Topic) public topics;
    uint256 public nextTopicId;

    // --- Constructor ---
    constructor(address _oracleAddress)
        ERC721("AetherMindNexus Agent", "AMNA")
        Ownable(msg.sender)
        ReentrancyGuard()
    {
        if (_oracleAddress == address(0)) {
            revert AetherMindNexus__InvalidOracleAddress();
        }
        oracleAddress = _oracleAddress;
        _nextTokenId = 0;
        nextIdeaId = 0;
        nextPredictionId = 0;
        nextTopicId = 0;
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert AetherMindNexus__OnlyOracle();
        }
        _;
    }

    // --- A. Core Protocol Management ---

    /// @notice Updates the address of the trusted AI oracle.
    /// @param _newOracleAddress The new address for the AI oracle.
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        if (_newOracleAddress == address(0)) {
            revert AetherMindNexus__InvalidOracleAddress();
        }
        oracleAddress = _newOracleAddress;
        emit OracleAddressUpdated(_newOracleAddress);
    }

    /// @notice Pauses core protocol functionalities in emergencies.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the protocol.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw accumulated protocol fees.
    /// @param _to The address to send the fees to.
    /// @param _amount The amount of fees to withdraw.
    function withdrawProtocolFees(address _to, uint256 _amount) public onlyOwner nonReentrant {
        if (_amount == 0) revert AetherMindNexus__NotEnoughETH();
        if (totalProtocolFees < _amount) revert AetherMindNexus__InsufficientTreasuryFunds(); // Misuse of error name, but signifies not enough fees.

        totalProtocolFees = totalProtocolFees.sub(_amount);
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert AetherMindNexus__OracleCallFailed(); // Misuse of error name, but signifies transfer failure.
        } // Consider a more specific error or re-add funds to totalProtocolFees.

        emit ProtocolFeesWithdrawn(_to, _amount);
    }

    // --- B. Agent NFT (dNFT) Management ---

    /// @notice Mints a new Agent NFT to a specified address, initializing its intelligence score.
    /// @param _to The address to mint the Agent NFT to.
    /// @return The tokenId of the newly minted Agent NFT.
    function mintAgentNFT(address _to) public whenNotPaused returns (uint256) {
        if (hasAgentNFT[_to]) revert AetherMindNexus__AgentNFTAlreadyMinted();

        uint256 tokenId = _nextTokenId++;
        _safeMint(_to, tokenId);
        agentIntelligenceScore[tokenId] = BASE_AGENT_INTELLIGENCE;
        userAgentNFTs[_to].push(tokenId);
        hasAgentNFT[_to] = true;
        emit AgentNFTMinted(_to, tokenId, BASE_AGENT_INTELLIGENCE);
        return tokenId;
    }

    /// @notice Allows an Agent NFT owner to burn their NFT.
    /// @param _tokenId The ID of the Agent NFT to burn.
    function burnAgentNFT(uint256 _tokenId) public whenNotPaused {
        if (ownerOf(_tokenId) != msg.sender) revert AetherMindNexus__InvalidTokenId(); // Using a generic error. Should be more specific like AetherMindNexus__NotNFTOwner.
        
        _burn(_tokenId);
        delete agentIntelligenceScore[_tokenId];
        
        // Remove from userAgentNFTs array
        uint252[] storage tokenList = userAgentNFTs[msg.sender];
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == _tokenId) {
                tokenList[i] = tokenList[tokenList.length - 1];
                tokenList.pop();
                break;
            }
        }
        if (tokenList.length == 0) {
            hasAgentNFT[msg.sender] = false;
        }

        emit AgentNFTBurnt(_tokenId);
    }

    /// @notice Retrieves the current intelligence score of an Agent NFT.
    /// @param _tokenId The ID of the Agent NFT.
    /// @return The intelligence score of the Agent NFT.
    function getAgentIntelligenceScore(uint256 _tokenId) public view returns (uint256) {
        if (!_exists(_tokenId)) revert AetherMindNexus__InvalidTokenId();
        return agentIntelligenceScore[_tokenId];
    }

    /// @notice Internal function to update an Agent NFT's intelligence score.
    /// @dev This function can be called by owner or other internal logic to adjust scores.
    /// @param _tokenId The ID of the Agent NFT.
    /// @param _scoreChange The amount to change the score by.
    /// @param _increase True to increase, false to decrease.
    function _updateAgentIntelligence(uint256 _tokenId, uint256 _scoreChange, bool _increase) internal {
        if (!_exists(_tokenId)) revert AetherMindNexus__InvalidTokenId();

        uint256 currentScore = agentIntelligenceScore[_tokenId];
        uint256 newScore;

        if (_increase) {
            newScore = currentScore.add(_scoreChange);
            if (newScore > MAX_AGENT_INTELLIGENCE) {
                newScore = MAX_AGENT_INTELLIGENCE;
            }
        } else {
            if (currentScore < _scoreChange) {
                newScore = 0; // Don't go below zero
            } else {
                newScore = currentScore.sub(_scoreChange);
            }
        }
        agentIntelligenceScore[_tokenId] = newScore;
        emit AgentIntelligenceUpdated(_tokenId, newScore);
    }

    /// @notice Overridden ERC721 function that returns the dynamic metadata URI for an Agent NFT.
    /// @param _tokenId The ID of the Agent NFT.
    /// @return A base64 encoded JSON string representing the NFT's metadata.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);

        uint256 intelligence = agentIntelligenceScore[_tokenId];
        string memory name = string(abi.encodePacked("AetherMind Agent #", _tokenId.toString()));
        string memory description = string(abi.encodePacked("A dynamic AetherMind Agent. Intelligence: ", intelligence.toString()));
        string memory image = "data:image/svg+xml;base64,..."; // Placeholder for an SVG image base64 encoded

        // Basic attributes, can be expanded
        string memory attributes = string(abi.encodePacked(
            '[{"trait_type": "Intelligence", "value": ', intelligence.toString(), '}]'
        ));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', image, '",',
            '"attributes": ', attributes, '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- C. Reputation System ---

    /// @notice Awards reputation points to a user for positive contributions.
    /// @param _user The address of the user to award reputation to.
    /// @param _points The number of reputation points to add.
    function earnReputation(address _user, uint256 _points) public whenNotPaused {
        userReputation[_user] = userReputation[_user].add(_points);
        if (hasAgentNFT[_user]) {
            // Distribute intelligence gain among user's Agent NFTs
            uint256[] storage tokens = userAgentNFTs[_user];
            if (tokens.length > 0) {
                uint256 pointsPerNFT = _points.div(tokens.length);
                for (uint256 i = 0; i < tokens.length; i++) {
                    _updateAgentIntelligence(tokens[i], pointsPerNFT, true);
                }
            }
        }
        emit ReputationEarned(_user, _points);
    }

    /// @notice Decreases a user's reputation points for negative actions.
    /// @param _user The address of the user to deduct reputation from.
    /// @param _points The number of reputation points to deduct.
    function loseReputation(address _user, uint256 _points) public whenNotPaused {
        if (userReputation[_user] < _points) {
            userReputation[_user] = 0;
        } else {
            userReputation[_user] = userReputation[_user].sub(_points);
        }
        if (hasAgentNFT[_user]) {
             // Distribute intelligence loss among user's Agent NFTs
            uint256[] storage tokens = userAgentNFTs[_user];
            if (tokens.length > 0) {
                uint256 pointsPerNFT = _points.div(tokens.length);
                for (uint256 i = 0; i < tokens.length; i++) {
                    _updateAgentIntelligence(tokens[i], pointsPerNFT, false);
                }
            }
        }
        emit ReputationLost(_user, _points);
    }

    /// @notice Retrieves a user's current soulbound reputation score.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getReputationScore(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Calculates a user's total voting power, combining reputation and owned Agent NFTs' intelligence.
    /// @param _user The address of the user.
    /// @return The effective voting power.
    function getEffectiveVotingPower(address _user) public view returns (uint256) {
        uint256 totalIntelligence = 0;
        for (uint256 i = 0; i < userAgentNFTs[_user].length; i++) {
            uint256 tokenId = userAgentNFTs[_user][i];
            totalIntelligence = totalIntelligence.add(agentIntelligenceScore[tokenId]);
        }
        // Voting power is reputation + total intelligence from owned Agent NFTs
        return userReputation[_user].add(totalIntelligence);
    }

    // --- D. Idea & Proposal Lifecycle ---

    /// @notice Allows users to submit a new idea or proposal, requesting initial funding.
    /// @param _description The description of the idea/proposal.
    /// @param _initialFundingRequest The amount of ETH requested if the idea is approved.
    /// @return The ID of the newly submitted idea.
    function submitIdea(string memory _description, uint256 _initialFundingRequest) public whenNotPaused returns (uint256) {
        uint256 ideaId = nextIdeaId++;
        ideas[ideaId].id = ideaId;
        ideas[ideaId].proposer = msg.sender;
        ideas[ideaId].description = _description;
        ideas[ideaId].initialFundingRequest = _initialFundingRequest;
        ideas[ideaId].status = IdeaStatus.Voting;
        ideas[ideaId].votingPeriodEnd = block.timestamp.add(VOTING_PERIOD_DURATION);

        emit IdeaSubmitted(ideaId, msg.sender, _description, _initialFundingRequest);
        return ideaId;
    }

    /// @notice Users vote on a submitted idea (for or against) using their effective voting power.
    /// @param _ideaId The ID of the idea to vote on.
    /// @param _support True for a 'for' vote, false for an 'against' vote.
    function voteOnIdea(uint256 _ideaId, bool _support) public whenNotPaused {
        Idea storage idea = ideas[_ideaId];
        if (idea.id == 0 && nextIdeaId == 0) revert AetherMindNexus__IdeaNotFound(); // Special handling for id 0 if nextIdeaId is 0 (no ideas submitted yet)
        if (idea.proposer == address(0)) revert AetherMindNexus__IdeaNotFound();
        if (idea.status != IdeaStatus.Voting || block.timestamp > idea.votingPeriodEnd) revert AetherMindNexus__IdeaVotingNotActive();
        if (idea.hasVoted[msg.sender]) revert AetherMindNexus__AlreadyVoted();

        uint256 votingPower = getEffectiveVotingPower(msg.sender);
        if (votingPower == 0) revert AetherMindNexus__NoVotingPower();

        idea.hasVoted[msg.sender] = true;
        idea.userVoteWeight[msg.sender] = votingPower;

        if (_support) {
            idea.totalForVotes = idea.totalForVotes.add(votingPower);
        } else {
            idea.totalAgainstVotes = idea.totalAgainstVotes.add(votingPower);
        }

        emit IdeaVoted(_ideaId, msg.sender, _support, votingPower);
    }

    /// @notice Owner/Admin closes the voting period for an idea, triggering final assessment.
    /// @param _ideaId The ID of the idea to close voting for.
    function closeIdeaVoting(uint256 _ideaId) public onlyOwner whenNotPaused {
        Idea storage idea = ideas[_ideaId];
        if (idea.proposer == address(0)) revert AetherMindNexus__IdeaNotFound();
        if (idea.status != IdeaStatus.Voting) revert AetherMindNexus__IdeaVotingClosed();
        if (block.timestamp < idea.votingPeriodEnd) {
             // Allow owner to close early but also enforce period end.
             // Forcing voting period end is the more robust approach:
             // For immediate close without waiting for `votingPeriodEnd`:
             // Remove 'block.timestamp < idea.votingPeriodEnd' check OR set idea.votingPeriodEnd = block.timestamp before next check.
             // For now, adhere to a strict voting period.
            revert AetherMindNexus__IdeaVotingNotActive();
        }

        idea.status = IdeaStatus.SentimentAnalysisPending; // Transition to next stage
        emit IdeaVotingClosed(_ideaId);
    }

    // --- E. AI Oracle Integration ---

    /// @notice Requests the AI oracle to perform sentiment analysis on an idea's description.
    /// @dev This function assumes an off-chain oracle system listens for this event or a direct call.
    /// @param _ideaId The ID of the idea for analysis.
    function requestAISentimentAnalysis(uint256 _ideaId) public whenNotPaused {
        Idea storage idea = ideas[_ideaId];
        if (idea.proposer == address(0)) revert AetherMindNexus__IdeaNotFound();
        if (idea.status != IdeaStatus.SentimentAnalysisPending) revert AetherMindNexus__IdeaNotReadyForFunding(); // Or a more specific error

        // In a real system, this would emit an event or call a Chainlink-like oracle contract.
        // For this example, we directly transition for the oracle to fulfill.
        // `oracleAddress` would monitor this contract for new requests.
        emit AISentimentRequested(_ideaId);
    }

    /// @notice Callback function executed by the trusted AI oracle to update an idea with its sentiment score and report.
    /// @param _ideaId The ID of the idea being updated.
    /// @param _sentimentScore The AI-determined sentiment score (-100 to 100).
    /// @param _analysisReport A string containing the AI's detailed analysis report.
    function fulfillAISentimentAnalysis(uint256 _ideaId, int256 _sentimentScore, string memory _analysisReport) public onlyOracle whenNotPaused {
        Idea storage idea = ideas[_ideaId];
        if (idea.proposer == address(0)) revert AetherMindNexus__IdeaNotFound();
        if (idea.status != IdeaStatus.SentimentAnalysisPending) revert AetherMindNexus__IdeaNotReadyForFunding(); // Or a more specific error

        idea.aiSentimentScore = _sentimentScore;
        idea.aiSentimentReport = _analysisReport;
        idea.status = IdeaStatus.SentimentAnalysisFulfilled;

        emit AISentimentFulfilled(_ideaId, _sentimentScore, _analysisReport);
    }

    /// @notice Requests the AI oracle to generate further insights or potential outcomes for a given idea.
    /// @param _ideaId The ID of the idea for insight generation.
    function requestAIGenerativeInsight(uint256 _ideaId) public whenNotPaused {
        Idea storage idea = ideas[_ideaId];
        if (idea.proposer == address(0)) revert AetherMindNexus__IdeaNotFound();
        if (idea.status != IdeaStatus.SentimentAnalysisFulfilled && idea.status != IdeaStatus.Funded) revert AetherMindNexus__IdeaNotReadyForFunding();

        emit AIGenerativeInsightRequested(_ideaId);
    }

    /// @notice Callback function executed by the trusted AI oracle to update an idea with AI-generated insights.
    /// @param _ideaId The ID of the idea being updated.
    /// @param _generatedInsight A string containing the AI's generated insights or outcomes.
    function fulfillAIGenerativeInsight(uint252 _ideaId, string memory _generatedInsight) public onlyOracle whenNotPaused {
        Idea storage idea = ideas[_ideaId];
        if (idea.proposer == address(0)) revert AetherMindNexus__IdeaNotFound();
        if (idea.status != IdeaStatus.SentimentAnalysisFulfilled && idea.status != IdeaStatus.Funded) revert AetherMindNexus__IdeaNotReadyForFunding();

        idea.aiGenerativeInsight = _generatedInsight;
        // No status change, as this is supplementary.
        emit AIGenerativeInsightFulfilled(_ideaId, _generatedInsight);
    }

    // --- F. Adaptive Treasury & Rewards ---

    /// @notice Allows anyone to deposit funds (ETH) into the protocol's treasury.
    function depositToTreasury() public payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert AetherMindNexus__NotEnoughETH();
        treasuryBalance = treasuryBalance.add(msg.value);
        emit FundsDepositedToTreasury(msg.sender, msg.value);
    }

    /// @notice Allocates treasury funds to an approved idea based on voting outcome and AI sentiment.
    /// @param _ideaId The ID of the idea to allocate funds to.
    function allocateTreasuryFunds(uint256 _ideaId) public onlyOwner whenNotPaused nonReentrant {
        Idea storage idea = ideas[_ideaId];
        if (idea.proposer == address(0)) revert AetherMindNexus__IdeaNotFound();
        if (idea.status != IdeaStatus.SentimentAnalysisFulfilled) revert AetherMindNexus__IdeaNotReadyForFunding();
        if (idea.allocatedFunds > 0) revert AetherMindNexus__IdeaAlreadyFunded();

        // Decision logic for funding based on votes and AI sentiment
        bool communityApproved = idea.totalForVotes > idea.totalAgainstVotes;
        bool aiPositiveSentiment = idea.aiSentimentScore >= 0; // Or a higher threshold like 50 for strong positive

        if (communityApproved && aiPositiveSentiment) {
            uint256 amountToAllocate = idea.initialFundingRequest;
            // Introduce adaptive scaling based on sentiment strength, e.g., if sentiment is very high, allocate more.
            if (idea.aiSentimentScore > 75) { // Very positive sentiment
                amountToAllocate = amountToAllocate.mul(120).div(100); // 20% bonus
            } else if (idea.aiSentimentScore < 25) { // Mildly positive sentiment
                amountToAllocate = amountToAllocate.mul(80).div(100); // 20% reduction
            }

            if (treasuryBalance < amountToAllocate) revert AetherMindNexus__InsufficientTreasuryFunds();

            treasuryBalance = treasuryBalance.sub(amountToAllocate);
            idea.allocatedFunds = amountToAllocate;
            idea.status = IdeaStatus.Funded;

            (bool success, ) = idea.proposer.call{value: amountToAllocate}("");
            if (!success) {
                // If transfer fails, revert the state changes. This is important.
                treasuryBalance = treasuryBalance.add(amountToAllocate);
                idea.allocatedFunds = 0;
                idea.status = IdeaStatus.SentimentAnalysisFulfilled; // Revert status
                revert AetherMindNexus__OracleCallFailed(); // Placeholder error
            }

            emit TreasuryFundsAllocated(_ideaId, amountToAllocate);
        } else {
            idea.status = IdeaStatus.Rejected;
            // Optionally, penalize proposer for rejected ideas or burn reputation.
        }
    }

    /// @notice Allows users to claim rewards for correct predictions.
    /// @param _predictionIds An array of prediction IDs to claim rewards for.
    function claimRewards(uint256[] memory _predictionIds) public whenNotPaused nonReentrant {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < _predictionIds.length; i++) {
            uint256 predictionId = _predictionIds[i];
            Prediction storage prediction = predictions[predictionId];

            if (prediction.predictor == address(0)) revert AetherMindNexus__PredictionNotFound();
            if (prediction.predictor != msg.sender) revert AetherMindNexus__PredictionNotFound(); // Not the owner
            if (!prediction.evaluated) revert AetherMindNexus__PredictionNotEvaluated();
            if (prediction.claimed) revert AetherMindNexus__PredictionAlreadyClaimed();
            if (!prediction.isCorrect) revert AetherMindNexus__PredictionNotCorrect();

            prediction.claimed = true;
            totalReward = totalReward.add(prediction.rewardAmount);
            emit RewardsClaimed(msg.sender, predictionId, prediction.rewardAmount);
        }

        if (totalReward == 0) revert AetherMindNexus__NoActivePredictionsToEvaluate(); // No rewards to claim

        if (treasuryBalance < totalReward) revert AetherMindNexus__InsufficientTreasuryFunds();
        treasuryBalance = treasuryBalance.sub(totalReward);

        (bool success, ) = msg.sender.call{value: totalReward}("");
        if (!success) {
            // Revert claims if transfer fails
            treasuryBalance = treasuryBalance.add(totalReward);
            for (uint256 i = 0; i < _predictionIds.length; i++) {
                predictions[_predictionIds[i]].claimed = false;
            }
            revert AetherMindNexus__OracleCallFailed(); // Placeholder error
        }
    }

    // --- G. Prediction Market ---

    /// @notice Users stake funds to predict the AI sentiment score of an idea.
    /// @param _ideaId The ID of the idea for which to predict sentiment.
    /// @param _predictedSentiment The user's predicted AI sentiment score (-100 to 100).
    /// @param _stakeAmount The amount of ETH to stake on the prediction.
    function submitPrediction(uint256 _ideaId, int256 _predictedSentiment, uint256 _stakeAmount) public payable whenNotPaused nonReentrant {
        Idea storage idea = ideas[_ideaId];
        if (idea.proposer == address(0)) revert AetherMindNexus__IdeaNotFound();
        if (idea.status != IdeaStatus.SentimentAnalysisPending) revert AetherMindNexus__IdeaNotReadyForFunding(); // Can only predict before fulfillment
        if (msg.value < _stakeAmount) revert AetherMindNexus__NotEnoughETH();
        if (_stakeAmount == 0) revert AetherMindNexus__NotEnoughETH();

        // Calculate protocol fee
        uint256 protocolFee = _stakeAmount.mul(PREDICTION_FEE_PERCENT).div(100);
        uint256 netStake = _stakeAmount.sub(protocolFee);

        treasuryBalance = treasuryBalance.add(netStake); // Add net stake to treasury
        totalProtocolFees = totalProtocolFees.add(protocolFee); // Add fee to protocol fees

        uint256 predictionId = nextPredictionId++;
        predictions[predictionId] = Prediction({
            id: predictionId,
            ideaId: _ideaId,
            predictor: msg.sender,
            predictedSentiment: _predictedSentiment,
            stakeAmount: _stakeAmount,
            rewardAmount: 0, // Calculated upon evaluation
            isCorrect: false,
            evaluated: false,
            claimed: false
        });

        emit PredictionSubmitted(predictionId, _ideaId, msg.sender, _predictedSentiment, _stakeAmount);
    }

    /// @notice Owner/Admin triggers the evaluation of predictions for a given idea after its AI sentiment analysis has been fulfilled.
    /// @param _ideaId The ID of the idea whose predictions are to be evaluated.
    function evaluatePredictions(uint256 _ideaId) public onlyOwner whenNotPaused {
        Idea storage idea = ideas[_ideaId];
        if (idea.proposer == address(0)) revert AetherMindNexus__IdeaNotFound();
        if (idea.status != IdeaStatus.SentimentAnalysisFulfilled && idea.status != IdeaStatus.Funded && idea.status != IdeaStatus.Rejected) revert AetherMindNexus__IdeaNotReadyForFunding();

        uint256[] memory activePredictionIds = new uint256[](nextPredictionId); // Max possible size
        uint256 count = 0;

        for (uint252 i = 0; i < nextPredictionId; i++) {
            if (predictions[i].ideaId == _ideaId && !predictions[i].evaluated) {
                activePredictionIds[count++] = i;
            }
        }

        if (count == 0) revert AetherMindNexus__NoActivePredictionsToEvaluate();

        uint256 totalCorrectStakes = 0;
        uint256 totalIncorrectStakes = 0;
        address[] memory correctPredictors;
        uint256[] memory correctPredictionIds;

        // First pass: Identify correct predictions and tally stakes
        for (uint224 i = 0; i < count; i++) {
            uint256 predictionId = activePredictionIds[i];
            Prediction storage prediction = predictions[predictionId];

            int256 sentimentDifference = idea.aiSentimentScore - prediction.predictedSentiment;
            bool isCorrect = (sentimentDifference >= -10 && sentimentDifference <= 10); // Example: within 10 points range

            if (isCorrect) {
                prediction.isCorrect = true;
                totalCorrectStakes = totalCorrectStakes.add(prediction.stakeAmount.sub(prediction.stakeAmount.mul(PREDICTION_FEE_PERCENT).div(100)));
                correctPredictors.push(prediction.predictor);
                correctPredictionIds.push(predictionId);
            } else {
                totalIncorrectStakes = totalIncorrectStakes.add(prediction.stakeAmount.sub(prediction.stakeAmount.mul(PREDICTION_FEE_PERCENT).div(100)));
            }
            prediction.evaluated = true;
        }

        // Second pass: Distribute rewards if any correct predictions
        if (totalCorrectStakes > 0) {
            uint256 rewardPool = totalCorrectStakes.add(totalIncorrectStakes); // Pool is sum of all net stakes
            for (uint256 i = 0; i < correctPredictionIds.length; i++) {
                Prediction storage prediction = predictions[correctPredictionIds[i]];
                uint256 netStake = prediction.stakeAmount.sub(prediction.stakeAmount.mul(PREDICTION_FEE_PERCENT).div(100));
                // Proportionate reward based on their correct stake vs total correct stakes
                prediction.rewardAmount = rewardPool.mul(netStake).div(totalCorrectStakes);
                earnReputation(prediction.predictor, 10); // Example: Award reputation for correct prediction
                emit PredictionEvaluated(prediction.id, true, prediction.rewardAmount);
            }
        } else {
            // If no correct predictions, all stakes remain in treasury (minus fees)
            // Or can be distributed as a reward to other participants or burned
            // For now, they simply stay in treasury.
            for (uint256 i = 0; i < count; i++) {
                Prediction storage prediction = predictions[activePredictionIds[i]];
                emit PredictionEvaluated(prediction.id, false, 0);
            }
        }
    }

    // --- H. Topic Monitoring ---

    /// @notice Registers a new topic for continuous AI sentiment monitoring.
    /// @param _description The description of the topic to monitor.
    /// @return The ID of the newly registered topic.
    function registerTopic(string memory _description) public whenNotPaused returns (uint256) {
        uint256 topicId = nextTopicId++;
        topics[topicId].id = topicId;
        topics[topicId].description = _description;
        topics[topicId].lastUpdated = block.timestamp;
        topics[topicId].currentAISentiment = 0; // Initialize neutral

        // In a real scenario, this would trigger an initial AI analysis request
        emit TopicRegistered(topicId, _description);
        return topicId;
    }

    /// @notice Deregisters an existing topic, stopping its continuous AI monitoring.
    /// @param _topicId The ID of the topic to deregister.
    function deregisterTopic(uint256 _topicId) public onlyOwner whenNotPaused {
        if (topics[_topicId].id == 0 && nextTopicId == 0) revert AetherMindNexus__TopicNotFound();
        if (topics[_topicId].description.length == 0) revert AetherMindNexus__TopicNotFound();

        delete topics[_topicId]; // Removes the topic data
        emit TopicDeregistered(_topicId);
    }

    /// @notice Internal function, callable by the oracle, to update a registered topic's sentiment score.
    /// @param _topicId The ID of the topic being updated.
    /// @param _sentimentScore The new AI-determined sentiment score (-100 to 100).
    function updateTopicAISentiment(uint256 _topicId, int256 _sentimentScore) public onlyOracle whenNotPaused {
        if (topics[_topicId].description.length == 0) revert AetherMindNexus__TopicNotFound();

        topics[_topicId].currentAISentiment = _sentimentScore;
        topics[_topicId].lastUpdated = block.timestamp;
        emit TopicAISentimentUpdated(_topicId, _sentimentScore);
    }
}
```