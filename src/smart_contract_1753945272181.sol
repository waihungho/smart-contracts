Here's a Solidity smart contract named **AuraNet: The Adaptive Reputation & Resource Layer**.

This contract introduces several advanced, creative, and trendy concepts:

1.  **Dynamic Reputation (AuraScore):** A non-transferable, on-chain reputation score that decays over time but can be boosted by community proposals or protocol engagement.
2.  **Protocol Mood:** The contract itself has a "mood" (e.g., Serene, Turbulent) which is determined by a decentralized sentiment input mechanism and influences core protocol parameters.
3.  **Adaptive Parameters:** Fees, reward rates, and resource allocation rates are not static but dynamically adjust based on the current `ProtocolMood`.
4.  **Decentralized Sentiment Input:** Users can submit "sentiment signals" which aggregate to influence the overall `ProtocolMood`, giving a form of continuous, soft governance.
5.  **Essence Token (ERC-20):** A core utility token that can be minted based on AuraScore and ProtocolMood, and staked for rewards.
6.  **Adaptive NFTs:** NFTs minted through the protocol can have properties (e.g., rarity, visual traits) that dynamically change based on the owner's AuraScore or the current Protocol Mood. (For simplicity, this example will show how traits *would* be derived dynamically).
7.  **Community-Driven Aura Boosts:** Users can propose and vote on boosting other users' AuraScores.
8.  **Internal Governance:** A standard proposal/vote/execute system for critical parameter changes.

---

## AuraNet: The Adaptive Reputation & Resource Layer

**Description:**
AuraNet is a decentralized protocol designed to foster a dynamic and adaptive ecosystem where user reputation (`AuraScore`) directly influences access to resources and the protocol's own operational parameters. Unlike static systems, AuraNet introduces a concept of "Protocol Mood" – a state derived from aggregated community sentiment signals – that dynamically adjusts critical variables such as resource minting rates, staking rewards, and governance thresholds. This creates a living, responsive protocol that evolves with its community's collective sentiment.

---

### Outline & Function Summary

**I. Core Infrastructure & Access Control**
*   `constructor`: Initializes the contract, sets the owner, and links the Essence Token.
*   `updateCoreContracts`: Allows the owner/governance to update addresses of integrated contracts (e.g., Essence Token, Sentiment Oracle).
*   `pause`/`unpause`: Emergency functions to pause/unpause critical protocol operations.
*   `withdrawProtocolFunds`: Allows the owner/governance to withdraw collected protocol fees.

**II. Reputation (AuraScore) Management**
*   `registerUserProfile`: Allows a new user to register and get an initial `AuraScore`.
*   `getAuraScore`: Reads the current `AuraScore` for a specific user.
*   `proposeAuraBoost`: Allows a user to propose an `AuraScore` boost for another user.
*   `voteOnAuraBoostProposal`: Allows users to vote on an active `AuraBoost` proposal.
*   `executeAuraBoostProposal`: Executes a successful `AuraBoost` proposal, updating the target user's `AuraScore`.
*   `decayAuraScore`: Internal function triggered to decay a user's `AuraScore` over time. (Potentially callable by anyone to incentivize network health or called by an upkeep bot)

**III. Protocol Mood & Dynamic Parameters**
*   `getProtocolMood`: Returns the current `ProtocolMood` (e.g., Serene, Turbulent).
*   `getDynamicParameter`: Retrieves the value of a specific dynamic parameter (e.g., `FEE_MULTIPLIER`) based on the current `ProtocolMood`.
*   `submitSentimentSignal`: Allows users to submit their preference, influencing the raw sentiment data.
*   `processPendingSentimentSignals`: Processes accumulated sentiment signals to update the raw sentiment score, which in turn determines the `ProtocolMood`.
*   `setMoodThresholds`: Allows governance to define the ranges for each `ProtocolMood`.
*   `updateDynamicParameterFormulas`: Allows governance to update the formulas used to calculate dynamic parameters based on the `ProtocolMood`.

**IV. Resource (EssenceToken) Allocation & Staking**
*   `mintEssenceByAura`: Allows users to mint `EssenceToken` based on their `AuraScore` and the current `ProtocolMood`.
*   `stakeEssence`: Allows users to stake their `EssenceToken` for rewards and potential `AuraScore` boosts.
*   `unstakeEssence`: Allows users to unstake their `EssenceToken`.
*   `claimStakingRewards`: Allows users to claim their accrued staking rewards.
*   `getClaimableRewards`: Calculates and returns the amount of `EssenceToken` a user can claim from staking.

**V. Internal Governance & Adaptability**
*   `submitGovernanceProposal`: Allows users to submit a formal governance proposal (e.g., update a core contract address, change a major parameter).
*   `voteOnGovernanceProposal`: Allows users to vote on an active governance proposal.
*   `executeGovernanceProposal`: Executes a successful governance proposal.
*   `delegateAuraVote`: Allows users to delegate their `AuraScore`-based voting power to another address.

**VI. Adaptive NFT Integration**
*   `mintAdaptiveNFT`: Mints an NFT whose properties are dynamically derived based on the owner's `AuraScore` and the `ProtocolMood` at the time of query.
*   `getAdaptiveNFTProperties`: Retrieves the current dynamic properties of a specific Adaptive NFT.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Interfaces for external contracts
interface IEssenceToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

// Simplified interface for a "Decentralized Sentiment Oracle"
// In a real scenario, this would be a more complex oracle network (e.g., Chainlink, Tellor, custom)
// For this example, it represents an external entity feeding sentiment data.
interface ISentimentOracle {
    function getLatestSentimentScore() external view returns (int256);
}

contract AuraNet is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum ProtocolMood {
        Serene,    // High positive sentiment, stable.
        Thriving,  // Positive and growing, perhaps slightly higher activity fees.
        Vigilant,  // Neutral to slightly negative, cautious.
        Stagnant,  // Low activity, neutral, possibly encouraging growth.
        Turbulent  // Strong negative sentiment, high fees/restrictions, encourages stabilization.
    }

    // --- Structs ---
    struct UserProfile {
        uint256 auraScore;
        uint64 lastReputationUpdate; // Timestamp for decay calculation
        uint256 stakedEssence;
        uint64 lastStakeTime; // For staking reward calculation
        uint256 claimableRewards;
    }

    struct MoodThresholds {
        int256 minSentiment;
        int256 maxSentiment;
    }

    struct DynamicParameterFormula {
        string name;
        bytes data; // Could encode formula, e.g., "mood * multiplier + base"
    }

    struct GovernanceProposal {
        bytes signature; // E.g., keccak256(abi.encodePacked(target, value, callData, description))
        address proposer;
        uint66 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    struct AuraBoostProposal {
        address targetUser;
        uint256 boostAmount;
        uint66 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // --- State Variables ---
    IEssenceToken public essenceToken;
    ISentimentOracle public sentimentOracle; // Address of the decentralized sentiment oracle

    // User data
    mapping(address => UserProfile) public userProfiles;

    // Protocol Mood & Sentiment
    ProtocolMood public currentProtocolMood;
    int252 public rawSentimentScore; // Aggregated sentiment from user signals
    uint64 public lastSentimentProcessTime; // Timestamp of last sentiment processing

    // Dynamic Parameters
    // Maps parameter names (e.g., "MINT_RATE_MULTIPLIER") to their formulas/values
    mapping(string => uint256) public dynamicParameterValues; // Simplified: direct value for now
    mapping(ProtocolMood => MoodThresholds) public moodThresholds;

    // Governance
    Counters.Counter private _governanceProposalIds;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public constant MIN_GOVERNANCE_VOTING_POWER = 1000; // Minimum AuraScore to submit/vote
    uint66 public constant GOVERNANCE_VOTING_PERIOD = 3 days;

    // Aura Boosts
    Counters.Counter private _auraBoostProposalIds;
    mapping(uint256 => AuraBoostProposal) public auraBoostProposals;
    uint66 public constant AURA_BOOST_VOTING_PERIOD = 2 days;

    // Adaptive NFTs
    ERC721 public adaptiveNFT; // An ERC721 contract for dynamic NFTs
    Counters.Counter private _nftTokenIds; // For minting unique NFT IDs

    // Delegation
    mapping(address => address) public auraVoteDelegates; // Delegate AuraScore voting power

    // --- Constants & Configuration ---
    uint256 public constant INITIAL_AURA_SCORE = 100;
    uint256 public constant MAX_AURA_SCORE = 10000;
    uint256 public constant MIN_AURA_SCORE = 1; // Can't go below this
    uint256 public constant AURA_DECAY_RATE_PER_DAY = 1; // Aura points decayed per day
    uint64 public constant SENTIMENT_PROCESS_INTERVAL = 1 hours; // How often sentiment can be processed

    uint256 public constant BASE_ESSENCE_MINT_RATE = 10; // Base Essence per Aura point
    uint256 public constant STAKING_REWARD_RATE_PER_DAY_PER_UNIT = 1; // Rewards per 1000 staked Essence per day

    // --- Events ---
    event UserRegistered(address indexed user, uint256 initialAuraScore);
    event AuraScoreUpdated(address indexed user, uint256 newScore, string reason);
    event ProtocolMoodChanged(ProtocolMood newMood, int256 rawSentiment);
    event SentimentSignalSubmitted(address indexed user, int256 signal);
    event EssenceMinted(address indexed user, uint256 amount);
    event EssenceStaked(address indexed user, uint256 amount);
    event EssenceUnstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes signature);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event AuraBoostProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address indexed target, uint256 amount);
    event AuraBoostVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event AuraBoostExecuted(uint256 indexed proposalId, address indexed target, uint256 boostedAmount);
    event AuraVoteDelegated(address indexed delegator, address indexed delegatee);
    event AdaptiveNFTMinted(uint256 indexed tokenId, address indexed owner);

    // --- Custom Errors ---
    error AlreadyRegistered();
    error UserNotRegistered();
    error InsufficientAuraScore(uint256 required, uint256 current);
    error InvalidSentimentSignal();
    error SentimentNotReadyForProcessing(uint64 nextProcessTime);
    error InvalidMoodThresholds();
    error ProposalNotFound();
    error ProposalAlreadyVoted();
    error ProposalExpired();
    error ProposalNotExpired();
    error ProposalNotExecutable();
    error ProposalAlreadyExecuted();
    error NotEnoughVotes();
    error InvalidStakeAmount();
    error InsufficientStakedBalance();
    error NothingToClaim();
    error InvalidNFTTemplate();
    error CoreContractNotSet(string contractName);

    // --- Modifiers ---
    modifier onlyRegisteredUser() {
        if (userProfiles[msg.sender].lastReputationUpdate == 0) revert UserNotRegistered();
        _;
    }

    modifier onlyWithSufficientAura(uint256 _requiredAura) {
        _decayAuraScore(msg.sender); // Decay before check
        if (userProfiles[msg.sender].auraScore < _requiredAura) revert InsufficientAuraScore(_requiredAura, userProfiles[msg.sender].auraScore);
        _;
    }

    // --- Constructor ---
    constructor(address _essenceTokenAddress, address _sentimentOracleAddress, address _adaptiveNFTAddress) Ownable(msg.sender) Pausable() {
        if (_essenceTokenAddress == address(0)) revert CoreContractNotSet("Essence Token");
        if (_sentimentOracleAddress == address(0)) revert CoreContractNotSet("Sentiment Oracle");
        if (_adaptiveNFTAddress == address(0)) revert CoreContractNotSet("Adaptive NFT");

        essenceToken = IEssenceToken(_essenceTokenAddress);
        sentimentOracle = ISentimentOracle(_sentimentOracleAddress);
        adaptiveNFT = ERC721("AuraNet Adaptive NFT", "AANFT"); // Initialize ERC721 inside constructor
        adaptiveNFT = ERC721(_adaptiveNFTAddress); // Or set an existing NFT contract

        // Initial Mood Thresholds (example values)
        moodThresholds[ProtocolMood.Serene] = MoodThresholds(60, 100); // 60-100%
        moodThresholds[ProtocolMood.Thriving] = MoodThresholds(30, 59); // 30-59%
        moodThresholds[ProtocolMood.Vigilant] = MoodThresholds(-29, 29); // -29% to 29%
        moodThresholds[ProtocolMood.Stagnant] = MoodThresholds(-59, -30); // -59% to -30%
        moodThresholds[ProtocolMood.Turbulent] = MoodThresholds(-100, -60); // -100% to -60%

        // Initial Dynamic Parameter Values (example values)
        dynamicParameterValues["ESSENCE_MINT_MULTIPLIER_SERENE"] = 150; // 1.5x
        dynamicParameterValues["ESSENCE_MINT_MULTIPLIER_THRIVING"] = 120; // 1.2x
        dynamicParameterValues["ESSENCE_MINT_MULTIPLIER_VIGILANT"] = 100; // 1.0x
        dynamicParameterValues["ESSENCE_MINT_MULTIPLIER_STAGNANT"] = 80;  // 0.8x
        dynamicParameterValues["ESSENCE_MINT_MULTIPLIER_TURBULENT"] = 50; // 0.5x

        dynamicParameterValues["STAKING_REWARD_MULTIPLIER_SERENE"] = 120; // 1.2x
        dynamicParameterValues["STAKING_REWARD_MULTIPLIER_THRIVING"] = 100; // 1.0x
        dynamicParameterValues["STAKING_REWARD_MULTIPLIER_VIGILANT"] = 80; // 0.8x
        dynamicParameterValues["STAKING_REWARD_MULTIPLIER_STAGNANT"] = 100; // 1.0x
        dynamicParameterValues["STAKING_REWARD_MULTIPLIER_TURBULENT"] = 50; // 0.5x

        lastSentimentProcessTime = uint64(block.timestamp);
        currentProtocolMood = ProtocolMood.Vigilant; // Initial mood
    }

    // --- I. Core Infrastructure & Access Control ---

    function updateCoreContracts(address _essenceTokenAddress, address _sentimentOracleAddress, address _adaptiveNFTAddress) external onlyOwner {
        if (_essenceTokenAddress != address(0)) {
            essenceToken = IEssenceToken(_essenceTokenAddress);
        }
        if (_sentimentOracleAddress != address(0)) {
            sentimentOracle = ISentimentOracle(_sentimentOracleAddress);
        }
        if (_adaptiveNFTAddress != address(0)) {
            adaptiveNFT = ERC721(_adaptiveNFTAddress);
        }
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function withdrawProtocolFunds(address _tokenAddress, uint256 _amount) external onlyOwner {
        // Allows owner to withdraw any collected tokens (e.g., fees)
        // Ensure this is carefully managed in a real system with multi-sig/DAO control
        if (_tokenAddress == address(essenceToken)) {
            essenceToken.transfer(owner(), _amount);
        } else {
            IERC20(_tokenAddress).transfer(owner(), _amount);
        }
    }

    // --- II. Reputation (AuraScore) Management ---

    function registerUserProfile() external whenNotPaused {
        if (userProfiles[msg.sender].lastReputationUpdate != 0) {
            revert AlreadyRegistered();
        }
        userProfiles[msg.sender] = UserProfile({
            auraScore: INITIAL_AURA_SCORE,
            lastReputationUpdate: uint64(block.timestamp),
            stakedEssence: 0,
            lastStakeTime: uint64(block.timestamp),
            claimableRewards: 0
        });
        emit UserRegistered(msg.sender, INITIAL_AURA_SCORE);
        _updateProtocolMood(); // Update mood after user registration
    }

    function getAuraScore(address _user) external view returns (uint256) {
        // Always return the decayed score for public query
        if (userProfiles[_user].lastReputationUpdate == 0) return 0; // Not registered
        return _calculateDecayedAura(_user);
    }

    /// @notice Allows a user to propose an AuraScore boost for another user.
    /// @param _targetUser The address of the user to propose a boost for.
    /// @param _boostAmount The amount of AuraScore to propose.
    function proposeAuraBoost(address _targetUser, uint256 _boostAmount) external onlyRegisteredUser whenNotPaused onlyWithSufficientAura(MIN_GOVERNANCE_VOTING_POWER) {
        if (_targetUser == address(0) || _boostAmount == 0) revert("Invalid boost parameters");
        _auraBoostProposalIds.increment();
        uint256 proposalId = _auraBoostProposalIds.current();

        auraBoostProposals[proposalId] = AuraBoostProposal({
            targetUser: _targetUser,
            boostAmount: _boostAmount,
            deadline: uint66(block.timestamp + AURA_BOOST_VOTING_PERIOD),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit AuraBoostProposalSubmitted(proposalId, msg.sender, _targetUser, _boostAmount);
    }

    /// @notice Allows a user to vote on an active AuraBoost proposal.
    /// @param _proposalId The ID of the AuraBoost proposal.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnAuraBoostProposal(uint256 _proposalId, bool _support) external onlyRegisteredUser whenNotPaused onlyWithSufficientAura(MIN_GOVERNANCE_VOTING_POWER) {
        AuraBoostProposal storage proposal = auraBoostProposals[_proposalId];
        if (proposal.targetUser == address(0)) revert ProposalNotFound();
        if (proposal.deadline < block.timestamp) revert ProposalExpired();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        _decayAuraScore(msg.sender); // Decay aura before voting power is used
        uint256 voterAura = userProfiles[msg.sender].auraScore;

        if (_support) {
            proposal.votesFor += voterAura;
        } else {
            proposal.votesAgainst += voterAura;
        }
        proposal.hasVoted[msg.sender] = true;

        emit AuraBoostVoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a successful AuraBoost proposal.
    /// @param _proposalId The ID of the AuraBoost proposal.
    function executeAuraBoostProposal(uint256 _proposalId) external whenNotPaused {
        AuraBoostProposal storage proposal = auraBoostProposals[_proposalId];
        if (proposal.targetUser == address(0)) revert ProposalNotFound();
        if (proposal.deadline > block.timestamp) revert ProposalNotExpired();
        if (proposal.executed) revert ProposalAlreadyExecuted();

        // Simple majority based on total votes for/against relative to some threshold (e.g., minimum turnout)
        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor > MIN_GOVERNANCE_VOTING_POWER * 5) { // Example threshold
            _updateAuraScore(proposal.targetUser, proposal.boostAmount, "Aura Boost Proposal Executed", true);
            proposal.executed = true;
            emit AuraBoostExecuted(_proposalId, proposal.targetUser, proposal.boostAmount);
        } else {
            revert NotEnoughVotes();
        }
    }

    // Internal helper to update AuraScore
    function _updateAuraScore(address _user, uint256 _amount, string memory _reason, bool _add) internal {
        UserProfile storage profile = userProfiles[_user];
        _calculateDecayedAura(_user); // Ensure current aura is up-to-date

        if (_add) {
            profile.auraScore = Math.min(profile.auraScore + _amount, MAX_AURA_SCORE);
        } else {
            profile.auraScore = Math.max(profile.auraScore - _amount, MIN_AURA_SCORE);
        }
        profile.lastReputationUpdate = uint64(block.timestamp);
        emit AuraScoreUpdated(_user, profile.auraScore, _reason);
    }

    // Internal function to apply decay
    function _decayAuraScore(address _user) internal view returns (uint256) {
        UserProfile storage profile = userProfiles[_user];
        if (profile.lastReputationUpdate == 0) return 0; // Not registered

        uint256 timeElapsed = block.timestamp - profile.lastReputationUpdate;
        uint256 decayAmount = (timeElapsed / 1 days) * AURA_DECAY_RATE_PER_DAY;

        if (decayAmount > 0) {
            uint256 newScore = Math.max(profile.auraScore - decayAmount, MIN_AURA_SCORE);
            profile.auraScore = newScore;
            profile.lastReputationUpdate = uint64(block.timestamp);
            emit AuraScoreUpdated(_user, profile.auraScore, "Decay");
            return newScore;
        }
        return profile.auraScore;
    }

    // Public wrapper to explicitly decay aura (anyone can call to help upkeep)
    function decayAuraScore(address _user) external whenNotPaused {
        _decayAuraScore(_user);
    }


    // --- III. Protocol Mood & Dynamic Parameters ---

    function getProtocolMood() external view returns (ProtocolMood) {
        return currentProtocolMood;
    }

    function getDynamicParameter(string memory _paramName) external view returns (uint256) {
        // This is a simplified lookup. In a more complex system, this could
        // interpret the 'data' in a DynamicParameterFormula struct based on mood.
        string memory moodSuffix;
        if (currentProtocolMood == ProtocolMood.Serene) moodSuffix = "_SERENE";
        else if (currentProtocolMood == ProtocolMood.Thriving) moodSuffix = "_THRIVING";
        else if (currentProtocolMood == ProtocolMood.Vigilant) moodSuffix = "_VIGILANT";
        else if (currentProtocolMood == ProtocolMood.Stagnant) moodSuffix = "_STAGNANT";
        else if (currentProtocolMood == ProtocolMood.Turbulent) moodSuffix = "_TURBULENT";

        // Concatenate string (simple for demo, but costly)
        // In practice, use pre-calculated keys or a lookup based on mood enum directly.
        bytes memory concat = abi.encodePacked(_paramName, moodSuffix);
        string memory key = string(concat);
        
        uint256 value = dynamicParameterValues[key];
        if (value == 0) return dynamicParameterValues[_paramName]; // Fallback to base if mood-specific not found
        return value;
    }

    /// @notice Allows users to submit their sentiment towards the protocol.
    /// @param _signal A value from -100 to 100, representing negative to positive sentiment.
    function submitSentimentSignal(int256 _signal) external onlyRegisteredUser whenNotPaused {
        if (_signal < -100 || _signal > 100) revert InvalidSentimentSignal();
        
        // This is a simplified aggregation. In a real system, signals could be weighted by AuraScore,
        // and decayed over time, or involve more complex consensus.
        // For now, it's a direct addition to rawSentimentScore.
        rawSentimentScore += _signal;
        emit SentimentSignalSubmitted(msg.sender, _signal);
    }

    /// @notice Processes accumulated sentiment signals and updates the Protocol Mood.
    /// Can be called by anyone, incentivizing network health.
    function processPendingSentimentSignals() external whenNotPaused {
        if (block.timestamp < lastSentimentProcessTime + SENTIMENT_PROCESS_INTERVAL) {
            revert SentimentNotReadyForProcessing(lastSentimentProcessTime + SENTIMENT_PROCESS_INTERVAL);
        }

        // Apply a decay to raw sentiment over time if not processed
        uint256 timeSinceLastProcess = block.timestamp - lastSentimentProcessTime;
        int256 decayFactor = int256(timeSinceLastProcess / (1 days)) * 5; // Example: decay 5 points per day
        rawSentimentScore = Math.max(rawSentimentScore - decayFactor, -1000); // Prevent endless growth/decay

        // Clamp rawSentimentScore to a conceptual range (e.g., -1000 to 1000) for mood calculation
        int256 clampedSentiment = Math.max(Math.min(rawSentimentScore, 1000), -1000); // Max +- 1000

        // Normalize clampedSentiment to a percentage (-100 to 100) for mood thresholds
        int256 normalizedSentiment = (clampedSentiment * 100) / 1000;

        ProtocolMood newMood = currentProtocolMood; // Default to current
        if (normalizedSentiment >= moodThresholds[ProtocolMood.Serene].minSentiment && normalizedSentiment <= moodThresholds[ProtocolMood.Serene].maxSentiment) {
            newMood = ProtocolMood.Serene;
        } else if (normalizedSentiment >= moodThresholds[ProtocolMood.Thriving].minSentiment && normalizedSentiment <= moodThresholds[ProtocolMood.Thriving].maxSentiment) {
            newMood = ProtocolMood.Thriving;
        } else if (normalizedSentiment >= moodThresholds[ProtocolMood.Vigilant].minSentiment && normalizedSentiment <= moodThresholds[ProtocolMood.Vigilant].maxSentiment) {
            newMood = ProtocolMood.Vigilant;
        } else if (normalizedSentiment >= moodThresholds[ProtocolMood.Stagnant].minSentiment && normalizedSentiment <= moodThresholds[ProtocolMood.Stagnant].maxSentiment) {
            newMood = ProtocolMood.Stagnant;
        } else if (normalizedSentiment >= moodThresholds[ProtocolMood.Turbulent].minSentiment && normalizedSentiment <= moodThresholds[ProtocolMood.Turbulent].maxSentiment) {
            newMood = ProtocolMood.Turbulent;
        } else {
            // Handle edge cases or maintain current mood if outside defined ranges (shouldn't happen with proper thresholds)
        }

        if (newMood != currentProtocolMood) {
            currentProtocolMood = newMood;
            emit ProtocolMoodChanged(newMood, normalizedSentiment);
        }
        lastSentimentProcessTime = uint64(block.timestamp);
    }

    /// @notice Allows governance to update the sentiment ranges for each ProtocolMood.
    /// @param _mood The ProtocolMood to update.
    /// @param _minSentiment The minimum sentiment score for this mood.
    /// @param _maxSentiment The maximum sentiment score for this mood.
    function setMoodThresholds(ProtocolMood _mood, int256 _minSentiment, int256 _maxSentiment) external onlyRegisteredUser whenNotPaused onlyWithSufficientAura(MIN_GOVERNANCE_VOTING_POWER * 2) {
        if (_minSentiment > _maxSentiment || _minSentiment < -100 || _maxSentiment > 100) revert InvalidMoodThresholds();
        // Additional checks to ensure no overlaps between moods would be needed in a full system.
        moodThresholds[_mood] = MoodThresholds(_minSentiment, _maxSentiment);
    }

    /// @notice Allows governance to update the direct values of dynamic parameters.
    /// For more advanced use cases, this could update formulas instead of direct values.
    /// @param _paramName The name of the dynamic parameter (e.g., "MINT_RATE_MULTIPLIER_SERENE").
    /// @param _value The new value for the parameter.
    function updateDynamicParameterFormulas(string memory _paramName, uint256 _value) external onlyRegisteredUser whenNotPaused onlyWithSufficientAura(MIN_GOVERNANCE_VOTING_POWER * 2) {
        dynamicParameterValues[_paramName] = _value;
    }


    // --- IV. Resource (EssenceToken) Allocation & Staking ---

    /// @notice Allows users to mint EssenceToken based on their AuraScore and ProtocolMood.
    function mintEssenceByAura() external onlyRegisteredUser whenNotPaused {
        _decayAuraScore(msg.sender); // Decay aura first
        UserProfile storage profile = userProfiles[msg.sender];
        if (profile.auraScore < MIN_AURA_SCORE) revert InsufficientAuraScore(MIN_AURA_SCORE, profile.auraScore);

        // Get dynamic mint multiplier based on current mood
        uint256 mintMultiplier = getDynamicParameter("ESSENCE_MINT_MULTIPLIER"); // Assuming default value if specific not found
        if (mintMultiplier == 0) mintMultiplier = 100; // Default to 100 (1.0x) if not explicitly set

        uint256 amountToMint = (profile.auraScore * BASE_ESSENCE_MINT_RATE * mintMultiplier) / 100; // Divide by 100 for percentage

        if (amountToMint == 0) revert("No essence to mint");

        essenceToken.mint(msg.sender, amountToMint);
        emit EssenceMinted(msg.sender, amountToMint);
        _updateAuraScore(msg.sender, amountToMint / 100, "Essence Minted", false); // Minor Aura decay for minting
    }

    /// @notice Allows users to stake EssenceToken.
    /// @param _amount The amount of EssenceToken to stake.
    function stakeEssence(uint256 _amount) external onlyRegisteredUser whenNotPaused {
        if (_amount == 0) revert InvalidStakeAmount();
        essenceToken.transferFrom(msg.sender, address(this), _amount);

        // Calculate and add pending rewards before updating stake
        _updateClaimableRewards(msg.sender);

        UserProfile storage profile = userProfiles[msg.sender];
        profile.stakedEssence += _amount;
        profile.lastStakeTime = uint64(block.timestamp); // Reset last stake time for fresh calculation
        emit EssenceStaked(msg.sender, _amount);
        _updateAuraScore(msg.sender, _amount / 100, "Essence Staked", true); // Aura boost for staking
    }

    /// @notice Allows users to unstake EssenceToken.
    /// @param _amount The amount of EssenceToken to unstake.
    function unstakeEssence(uint256 _amount) external onlyRegisteredUser whenNotPaused {
        UserProfile storage profile = userProfiles[msg.sender];
        if (_amount == 0 || _amount > profile.stakedEssence) revert InsufficientStakedBalance();

        // Calculate and add pending rewards before updating stake
        _updateClaimableRewards(msg.sender);

        profile.stakedEssence -= _amount;
        profile.lastStakeTime = uint64(block.timestamp); // Reset last stake time for fresh calculation
        essenceToken.transfer(msg.sender, _amount);
        emit EssenceUnstaked(msg.sender, _amount);
        _updateAuraScore(msg.sender, _amount / 100, "Essence Unstaked", false); // Aura decay for unstaking
    }

    /// @notice Allows users to claim their accrued staking rewards.
    function claimStakingRewards() external onlyRegisteredUser whenNotPaused {
        UserProfile storage profile = userProfiles[msg.sender];
        _updateClaimableRewards(msg.sender); // Ensure rewards are up-to-date

        uint256 rewardsToClaim = profile.claimableRewards;
        if (rewardsToClaim == 0) revert NothingToClaim();

        profile.claimableRewards = 0;
        essenceToken.mint(msg.sender, rewardsToClaim); // Mint new Essence as rewards
        emit StakingRewardsClaimed(msg.sender, rewardsToClaim);
    }

    /// @notice Calculates the claimable rewards for a user.
    function getClaimableRewards(address _user) external view returns (uint256) {
        UserProfile storage profile = userProfiles[_user];
        if (profile.stakedEssence == 0) return profile.claimableRewards;

        uint256 timeElapsed = block.timestamp - profile.lastStakeTime;
        uint256 rewardMultiplier = getDynamicParameter("STAKING_REWARD_MULTIPLIER"); // Dynamic reward multiplier
        if (rewardMultiplier == 0) rewardMultiplier = 100; // Default to 100 (1.0x)

        uint256 newRewards = (profile.stakedEssence * (timeElapsed / 1 days) * STAKING_REWARD_RATE_PER_DAY_PER_UNIT * rewardMultiplier) / 100000; // Adjusted for 1000 units and 100 multiplier

        return profile.claimableRewards + newRewards;
    }

    // Internal helper to update claimable rewards before stake/unstake/claim
    function _updateClaimableRewards(address _user) internal {
        UserProfile storage profile = userProfiles[_user];
        if (profile.stakedEssence == 0) return;

        uint256 timeElapsed = block.timestamp - profile.lastStakeTime;
        uint256 rewardMultiplier = getDynamicParameter("STAKING_REWARD_MULTIPLIER");
        if (rewardMultiplier == 0) rewardMultiplier = 100;

        uint256 newRewards = (profile.stakedEssence * (timeElapsed / 1 days) * STAKING_REWARD_RATE_PER_DAY_PER_UNIT * rewardMultiplier) / 100000;

        profile.claimableRewards += newRewards;
        profile.lastStakeTime = uint64(block.timestamp); // Reset time for next calculation
    }

    // --- V. Internal Governance & Adaptability ---

    /// @notice Allows users to submit a formal governance proposal.
    /// @param _target The address of the contract to call.
    /// @param _value The ETH value to send with the call.
    /// @param _callData The encoded function call data.
    /// @param _description A description of the proposal.
    function submitGovernanceProposal(address _target, uint256 _value, bytes calldata _callData, string calldata _description) external onlyRegisteredUser whenNotPaused onlyWithSufficientAura(MIN_GOVERNANCE_VOTING_POWER) {
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();

        governanceProposals[proposalId] = GovernanceProposal({
            signature: keccak256(abi.encodePacked(_target, _value, _callData, _description)),
            proposer: msg.sender,
            deadline: uint66(block.timestamp + GOVERNANCE_VOTING_PERIOD),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit GovernanceProposalSubmitted(proposalId, msg.sender, keccak256(abi.encodePacked(_target, _value, _callData)));
    }

    /// @notice Allows users to vote on an active governance proposal.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external onlyRegisteredUser whenNotPaused onlyWithSufficientAura(MIN_GOVERNANCE_VOTING_POWER) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.deadline < block.timestamp) revert ProposalExpired();
        if (proposal.executed) revert ProposalAlreadyExecuted();

        address voter = auraVoteDelegates[msg.sender] == address(0) ? msg.sender : auraVoteDelegates[msg.sender];
        if (proposal.hasVoted[voter]) revert ProposalAlreadyVoted();

        _decayAuraScore(voter); // Decay aura before voting power is used
        uint256 voterAura = userProfiles[voter].auraScore;

        if (_support) {
            proposal.votesFor += voterAura;
        } else {
            proposal.votesAgainst += voterAura;
        }
        proposal.hasVoted[voter] = true;

        emit GovernanceVoteCast(_proposalId, voter, _support);
    }

    /// @notice Executes a successful governance proposal.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _target The address of the contract to call.
    /// @param _value The ETH value to send with the call.
    /// @param _callData The encoded function call data.
    function executeGovernanceProposal(uint256 _proposalId, address _target, uint256 _value, bytes calldata _callData) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.deadline > block.timestamp) revert ProposalNotExpired();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (keccak256(abi.encodePacked(_target, _value, _callData, "")) != keccak256(abi.encodePacked(proposal.signature, ""))) revert ProposalNotExecutable(); // Ensure matching signature without description

        // Simple majority: votesFor > votesAgainst AND votesFor meets a minimum quorum
        uint256 totalAuraSupply = _getTotalRegisteredAura(); // Would need to track total AuraSupply
        uint256 quorumThreshold = totalAuraSupply / 10; // Example: 10% quorum

        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= quorumThreshold) {
            (bool success,) = _target.call{value: _value}(_callData);
            require(success, "Proposal call failed");
            proposal.executed = true;
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            revert NotEnoughVotes();
        }
    }

    /// @notice Allows a user to delegate their AuraScore-based voting power.
    /// @param _delegatee The address to delegate voting power to.
    function delegateAuraVote(address _delegatee) external onlyRegisteredUser whenNotPaused {
        if (_delegatee == msg.sender) revert("Cannot delegate to self");
        auraVoteDelegates[msg.sender] = _delegatee;
        emit AuraVoteDelegated(msg.sender, _delegatee);
    }

    // Internal helper to get total AuraScore (simplistic, real system would be more robust)
    function _getTotalRegisteredAura() internal view returns (uint256) {
        // This would require iterating through all user profiles or maintaining a running sum,
        // which can be gas-expensive. In a real system, you might sample, or use a merklized sum,
        // or a dedicated contract for aggregated statistics. For this demo, return a placeholder.
        return MAX_AURA_SCORE * 100; // Placeholder for demonstration
    }

    // --- VI. Adaptive NFT Integration ---

    /// @notice Mints a new Adaptive NFT to the caller.
    function mintAdaptiveNFT() external onlyRegisteredUser whenNotPaused {
        _nftTokenIds.increment();
        uint256 newId = _nftTokenIds.current();
        adaptiveNFT._mint(msg.sender, newId);
        emit AdaptiveNFTMinted(newId, msg.sender);
    }

    /// @notice Retrieves the dynamic properties of an Adaptive NFT based on current AuraScore and Mood.
    /// In a real system, this would influence SVG/JSON metadata off-chain or return specific trait values.
    /// @param _tokenId The ID of the Adaptive NFT.
    function getAdaptiveNFTProperties(uint256 _tokenId) external view returns (string memory moodTrait, string memory auraTierTrait, uint256 currentAura) {
        address ownerOfNFT = adaptiveNFT.ownerOf(_tokenId);
        if (ownerOfNFT == address(0)) revert("NFT does not exist or has no owner");

        // Get owner's current AuraScore (decayed)
        currentAura = _calculateDecayedAura(ownerOfNFT);

        // Derive mood-based trait
        if (currentProtocolMood == ProtocolMood.Serene) moodTrait = "SereneBloom";
        else if (currentProtocolMood == ProtocolMood.Thriving) moodTrait = "ThrivingGrowth";
        else if (currentProtocolMood == ProtocolMood.Vigilant) moodTrait = "VigilantWatch";
        else if (currentProtocolMood == ProtocolMood.Stagnant) moodTrait = "StagnantPatience";
        else if (currentProtocolMood == ProtocolMood.Turbulent) moodTrait = "TurbulentStorm";
        else moodTrait = "UnknownMood"; // Should not happen

        // Derive Aura-based tier trait
        if (currentAura >= MAX_AURA_SCORE * 0.9) auraTierTrait = "LegendaryAura";
        else if (currentAura >= MAX_AURA_SCORE * 0.7) auraTierTrait = "EpicAura";
        else if (currentAura >= MAX_AURA_SCORE * 0.5) auraTierTrait = "RareAura";
        else if (currentAura >= MAX_AURA_SCORE * 0.2) auraTierTrait = "UncommonAura";
        else auraTierTrait = "CommonAura";

        return (moodTrait, auraTierTrait, currentAura);
    }

    // --- Internal Helpers ---
    // Make _calculateDecayedAura a view function for external use and internal consistency
    function _calculateDecayedAura(address _user) internal view returns (uint256) {
        UserProfile storage profile = userProfiles[_user];
        if (profile.lastReputationUpdate == 0) return 0; // Not registered

        uint256 timeElapsed = block.timestamp - profile.lastReputationUpdate;
        uint256 decayAmount = (timeElapsed / 1 days) * AURA_DECAY_RATE_PER_DAY;

        return Math.max(profile.auraScore - decayAmount, MIN_AURA_SCORE);
    }
}

// Simple Math library for min/max - can be replaced with OpenZeppelin's Math if preferred
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }
}
```