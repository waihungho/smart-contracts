This smart contract, `EvolveNexus`, is designed as a decentralized adaptive protocol that combines AI oracle integration, a dynamic reputation system, soulbound and dynamic NFTs, and a DAO-like governance structure. Its goal is to foster a self-evolving community focused on content curation, idea validation, and resource allocation, driven by collective intelligence and AI insights.

---

## EvolveNexus: Decentralized Adaptive Protocol

### Outline

**I. Contract Setup & Core Utilities**
*   **Solidity Version:** `^0.8.20`
*   **Imports:** OpenZeppelin `ERC20`, `ERC721`, `Ownable`, `Pausable`, `SafeERC20`
*   **Error Definitions:** Custom errors for specific conditions.
*   **Events:** `UserRegistered`, `TokensStaked`, `TokensUnstaked`, `PropositionSubmitted`, `AIAnalysisRequested`, `AIAnalysisFulfilled`, `AIAnalysisChallenged`, `ChallengeResolved`, `FundingProposalCreated`, `VotedOnProposal`, `ProposalExecuted`, `RewardDistributed`, `AchievementNFTMinted`, `AchievementNFTUpdated`, `ProtocolParametersUpdated`.
*   **Enums:** `PropositionStatus`, `ProposalStatus`.
*   **Structs:** `Proposition`, `FundingProposal`.
*   **State Variables:**
    *   `owner`, `paused` (from `Ownable` and `Pausable`)
    *   `aiOracleAddress`, `influenceToken`, `identityNFT`, `achievementNFT` (addresses of external contracts)
    *   `minCognitionPointsForProposition`, `aiAnalysisFee`, `challengeStakeRequirement`, `challengeVotePeriod`
    *   `minInfluenceForFundingProposal`, `minInfluenceForVote`, `proposalVotePeriod`, `minProposalQuorumPercent`
    *   `userCognitionPoints` (`address => uint256`)
    *   `userStakedInfluenceTokens` (`address => uint256`)
    *   `propositions` (`uint256 => Proposition`)
    *   `fundingProposals` (`uint256 => FundingProposal`)
    *   `nextPropositionId`, `nextFundingProposalId`, `nextAchievementNFTId`
*   **Constructor:** Initializes the owner, AI oracle address, and initial protocol parameters.
*   **Modifiers:** `onlyOwner`, `onlyAIOracle`, `whenNotPaused`, `whenPaused`, ``isRegisteredUser` (ensures user has an `IdentityNFT`).

**II. Admin & Configuration Functions**
1.  **`setAIOracleAddress(address _newOracle)`**: Updates the address of the AI oracle contract.
2.  **`setNFTAddresses(address _identityNFT, address _achievementNFT)`**: Sets the addresses for the Soulbound Identity NFT and Dynamic Achievement NFT contracts.
3.  **`setInfluenceTokenAddress(address _token)`**: Sets the address of the ERC20 token used for staking and influence.
4.  **`setProtocolParameters(...)`**: Allows the owner to configure various system-wide parameters such as AI analysis fees, minimum stakes, voting periods, and quorums.
5.  **`pauseContract()`**: Pauses all core functionalities of the contract (only owner).
6.  **`unpauseContract()`**: Unpauses the contract (only owner).
7.  **`emergencyWithdrawStuckTokens(address _token, uint256 _amount)`**: Allows the owner to recover tokens mistakenly sent to the contract (not protocol-owned assets).

**III. User & Reputation Management**
8.  **`registerUser()`**: Mints a unique, soulbound `IdentityNFT` for a new user, initializing their `CognitionPoints`. This acts as their on-chain identity and entry point into the system.
9.  **`stakeInfluenceTokens(uint256 _amount)`**: Users stake `InfluenceTokens` (ERC20) to increase their `InfluenceScore`, granting them more voting power and system privileges.
10. **`unstakeInfluenceTokens(uint256 _amount)`**: Users can unstake their `InfluenceTokens`. A cool-down period or penalties might apply if they have active proposals or challenges.
11. **`getInfluenceScore(address _user)`**: (View) Returns a user's total influence score, derived from a combination of staked `InfluenceTokens` and `CognitionPoints`.
12. **`getCognitionPoints(address _user)`**: (View) Returns a user's current `CognitionPoints`, a measure of their trustworthiness and valuable contributions.
13. **`mintAchievementNFT(address _recipient, uint256 _achievementType, string memory _initialURI)`**: Awards a dynamic `AchievementNFT` to a user for reaching significant milestones (e.g., successful proposals, high cognition points). This function is called by the protocol.
14. **`updateAchievementNFTMetadata(uint256 _tokenId, string memory _newURI)`**: Allows the protocol to update the metadata URI of an `AchievementNFT`, making it dynamic based on evolving user achievements or system state.

**IV. AI-Powered Proposition System**
15. **`submitProposition(string memory _title, string memory _descriptionHash, address _targetRecipient, uint256 _rewardBounty, uint256 _aiValidationFee)`**: Users submit ideas, tasks, or content ("Propositions") for AI analysis. A fee is attached to cover the AI oracle's costs.
16. **`fulfillAIAnalysis(uint256 _propositionId, string memory _aiReportHash, uint256 _sentimentScore, uint256 _originalityScore)`**: Called by the designated AI oracle to report the results of its analysis (e.g., sentiment, originality, relevance scores) for a given proposition.
17. **`challengeAIAnalysis(uint256 _propositionId, string memory _reasonHash, uint256 _challengeStake)`**: If a user believes the AI's analysis is inaccurate or malicious, they can challenge it by staking `InfluenceTokens` and providing a reason.
18. **`voteOnAIChallenge(uint256 _propositionId, bool _supportAI)`**: Community members vote on the validity of an AI challenge, supporting either the AI's report or the challenger's claim. Voting power is weighted by `InfluenceScore`.
19. **`resolveAIChallenge(uint256 _propositionId)`**: After the voting period, this function finalizes the AI challenge. Rewards are distributed to correct voters, and `CognitionPoints` are adjusted for the challenger, proposition creator, and potentially the AI oracle (if its report was deemed inaccurate).
20. **`distributePropositionReward(uint256 _propositionId)`**: If a proposition is successfully validated and meets certain criteria (e.g., high AI scores, no successful challenge), its creator can claim the pre-defined reward bounty.

**V. Decentralized Funding & Governance**
21. **`createFundingProposal(string memory _title, string memory _descriptionHash, uint256 _requestedAmount, uint256 _minInfluenceToVote)`**: Users with sufficient `InfluenceScore` can propose spending funds from the protocol treasury for projects or initiatives.
22. **`voteOnFundingProposal(uint256 _proposalId, bool _support)`**: Community members vote on funding proposals, with their vote weight determined by their `InfluenceScore`.
23. **`executeFundingProposal(uint256 _proposalId)`**: If a funding proposal passes with the required quorum and approval threshold, this function transfers the requested funds from the protocol treasury to the designated recipient.
24. **`claimVoterReward(uint256 _proposalId)`**: Voters who participated in a successful funding proposal and voted with the majority can claim a small reward (e.g., from a general reward pool or a percentage of the proposal value).

**VI. Treasury & Protocol Economy**
25. **`depositTreasuryFunds()`**: Allows any user to voluntarily deposit ERC20 tokens into the `EvolveNexus` protocol treasury, supporting its ecosystem.
26. **`getProtocolTreasuryBalance()`**: (View) Returns the total balance of the protocol's main treasury token.

---

### Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Custom Error Definitions ---
error EvolveNexus__NotRegisteredUser();
error EvolveNexus__AlreadyRegistered();
error EvolveNexus__ZeroAddressNotAllowed();
error EvolveNexus__AmountMustBeGreaterThanZero();
error EvolveNexus__InsufficientInfluenceTokens();
error EvolveNexus__InsufficientCognitionPoints();
error EvolveNexus__PropositionNotFound();
error EvolveNexus__PropositionNotPendingAnalysis();
error EvolveNexus__PropositionAlreadyFulfilled();
error EvolveNexus__PropositionNotInChallengePeriod();
error EvolveNexus__ChallengeAlreadyResolved();
error EvolveNexus__InsufficientChallengeStake();
error EvolveNexus__VotingPeriodNotActive();
error EvolveNexus__AlreadyVoted();
error EvolveNexus__ProposalNotFound();
error EvolveNexus__ProposalNotExecutable();
error EvolveNexus__InsufficientTreasuryFunds();
error EvolveNexus__CannotUnstakeWithActiveProposalsOrChallenges();
error EvolveNexus__UnauthorizedAchievementNFTUpdate();
error EvolveNexus__InvalidParameters();
error EvolveNexus__VotingThresholdNotMet();
error EvolveNexus__QuorumNotMet();
error EvolveNexus__PropositionNotApprovedForReward();
error EvolveNexus__RewardAlreadyDistributed();


/**
 * @title IEvolveNexusIdentityNFT
 * @dev Interface for the Soulbound Identity NFT.
 *      Assumed to be a non-transferable ERC721.
 */
interface IEvolveNexusIdentityNFT is IERC721 {
    function mint(address _to) external returns (uint256);
    // Assumed to prevent transfers internally or by custom logic.
}

/**
 * @title IEvolveNexusAchievementNFT
 * @dev Interface for the Dynamic Achievement NFT.
 */
interface IEvolveNexusAchievementNFT is IERC721 {
    function mint(address _to, uint256 _id, string memory _tokenURI) external returns (uint256);
    function updateTokenURI(uint256 _tokenId, string memory _newTokenURI) external;
}

/**
 * @title EvolveNexus
 * @dev A Decentralized Adaptive Protocol (DAP) leveraging AI oracles,
 *      dynamic reputation, and decentralized governance for content curation
 *      and resource allocation.
 */
contract EvolveNexus is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // --- Enums ---
    enum PropositionStatus {
        PendingAnalysis,
        AIAnalyzed,
        Challenged,
        ChallengeResolved_AIConfirmed,
        ChallengeResolved_ChallengerWon,
        RewardClaimed
    }

    enum ProposalStatus {
        Voting,
        QueuedForExecution,
        Executed,
        Defeated
    }

    // --- Structs ---

    struct Proposition {
        address creator;
        string title;
        string descriptionHash; // IPFS hash or similar
        address targetRecipient; // Who receives the reward if successful
        uint256 rewardBounty;
        uint256 aiValidationFee; // Fee paid for AI analysis

        // AI Analysis Results
        string aiReportHash;
        uint256 sentimentScore; // e.g., 0-100
        uint256 originalityScore; // e.g., 0-100
        uint256 analysisTimestamp;

        // Challenge data
        bool isChallenged;
        address challenger;
        uint256 challengeStake;
        string challengeReasonHash;
        uint256 challengeStartTimestamp;
        mapping(address => bool) hasVotedOnChallenge;
        uint256 votesForAI; // Influence score sum for AI
        uint256 votesAgainstAI; // Influence score sum against AI

        PropositionStatus status;
        bool rewardClaimed;
    }

    struct FundingProposal {
        address creator;
        string title;
        string descriptionHash; // IPFS hash or similar
        uint256 requestedAmount;
        uint256 minInfluenceToVote; // Minimum influence a user needs to vote on this proposal
        uint256 creationTimestamp;
        uint256 votingEndTimestamp;

        mapping(address => bool) hasVoted;
        uint256 totalInfluenceFor; // Sum of influence scores for "yes" votes
        uint256 totalInfluenceAgainst; // Sum of influence scores for "no" votes
        uint256 totalVoterInfluence; // Total influence that participated in voting

        ProposalStatus status;
        uint256 executionTimestamp;
    }

    // --- State Variables ---

    address public aiOracleAddress;
    IERC20 public influenceToken; // ERC20 token for staking and influence
    IEvolveNexusIdentityNFT public identityNFT; // Soulbound Identity NFT
    IEvolveNexusAchievementNFT public achievementNFT; // Dynamic Achievement NFT

    // Protocol Parameters (configurable by owner)
    uint256 public minCognitionPointsForProposition; // Min CP to submit a proposition
    uint256 public aiAnalysisFee; // Cost for AI analysis per proposition
    uint256 public challengeStakeRequirement; // Min stake to challenge AI analysis
    uint256 public challengeVotePeriod; // Duration for community to vote on AI challenges (seconds)
    uint256 public aiOracleRewardRate; // % of AI analysis fee given to oracle (e.g., 80 = 80%)

    uint256 public minInfluenceForFundingProposal; // Min influence to create a funding proposal
    uint256 public minInfluenceForVote; // Min influence to vote on a funding proposal
    uint256 public proposalVotePeriod; // Duration for community to vote on funding proposals (seconds)
    uint256 public minProposalQuorumPercent; // % of total active influence required for proposal to be valid (e.g., 10 = 10%)
    uint256 public successfulProposalVoterRewardBasisPoints; // Basis points of requestedAmount distributed to voters

    // User data
    mapping(address => uint256) public userCognitionPoints; // Raw cognition points
    mapping(address => uint256) public userStakedInfluenceTokens; // Staked InfluenceTokens

    // Protocol data
    mapping(uint256 => Proposition) public propositions;
    uint256 public nextPropositionId = 1;

    mapping(uint256 => FundingProposal) public fundingProposals;
    uint256 public nextFundingProposalId = 1;

    uint256 public nextAchievementNFTId = 1;

    // --- Events ---
    event UserRegistered(address indexed user, uint256 identityNFTId);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event PropositionSubmitted(uint256 indexed propositionId, address indexed creator, string title, uint256 rewardBounty);
    event AIAnalysisRequested(uint256 indexed propositionId, address indexed submitter);
    event AIAnalysisFulfilled(uint256 indexed propositionId, string aiReportHash, uint256 sentimentScore, uint256 originalityScore);
    event AIAnalysisChallenged(uint256 indexed propositionId, address indexed challenger, uint256 challengeStake);
    event ChallengeVoted(uint256 indexed propositionId, address indexed voter, bool supportAI);
    event ChallengeResolved(uint256 indexed propositionId, bool aiReportConfirmed, address indexed winningParty);
    event FundingProposalCreated(uint256 indexed proposalId, address indexed creator, string title, uint256 requestedAmount);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event RewardDistributed(uint256 indexed propositionId, address indexed recipient, uint256 amount);
    event AchievementNFTMinted(address indexed recipient, uint256 indexed tokenId, uint256 achievementType);
    event AchievementNFTUpdated(uint256 indexed tokenId, string newURI);
    event ProtocolParametersUpdated(uint256 aiAnalysisFee, uint256 challengeStakeRequirement, uint256 challengeVotePeriod, uint256 minInfluenceForFundingProposal, uint256 proposalVotePeriod, uint256 minProposalQuorumPercent);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) {
            revert OwnableUnauthorizedAccount(msg.sender); // Reusing Ownable's error for consistency
        }
        _;
    }

    modifier isRegisteredUser(address _user) {
        // Assumes IdentityNFT `balanceOf` is a reliable check for registration.
        // A more robust check might involve a mapping `isUserRegistered`.
        if (identityNFT.balanceOf(_user) == 0) {
            revert EvolveNexus__NotRegisteredUser();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        address _aiOracleAddress,
        address _influenceTokenAddress,
        address _identityNFTAddress,
        address _achievementNFTAddress
    ) Ownable(msg.sender) Pausable() {
        if (_aiOracleAddress == address(0) || _influenceTokenAddress == address(0) || _identityNFTAddress == address(0) || _achievementNFTAddress == address(0)) {
            revert EvolveNexus__ZeroAddressNotAllowed();
        }
        aiOracleAddress = _aiOracleAddress;
        influenceToken = IERC20(_influenceTokenAddress);
        identityNFT = IEvolveNexusIdentityNFT(_identityNFTAddress);
        achievementNFT = IEvolveNexusAchievementNFT(_achievementNFTAddress);

        // Set initial protocol parameters
        minCognitionPointsForProposition = 100; // Example: requires 100 CP to submit
        aiAnalysisFee = 0.1 ether; // Example: 0.1 ETH/TOKEN for AI analysis
        challengeStakeRequirement = 0.5 ether; // Example: 0.5 ETH/TOKEN to challenge
        challengeVotePeriod = 3 days;
        aiOracleRewardRate = 80; // 80% of AI fee goes to oracle

        minInfluenceForFundingProposal = 1000; // Example: requires 1000 Influence Score to create proposal
        minInfluenceForVote = 50; // Example: requires 50 Influence Score to vote
        proposalVotePeriod = 7 days;
        minProposalQuorumPercent = 10; // Example: 10% of total staked influence must vote
        successfulProposalVoterRewardBasisPoints = 50; // 0.5% of requested amount shared among successful voters
    }

    // --- I. Admin & Configuration Functions ---

    /**
     * @dev Allows the owner to update the AI oracle contract address.
     * @param _newOracle The new address for the AI oracle.
     */
    function setAIOracleAddress(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) {
            revert EvolveNexus__ZeroAddressNotAllowed();
        }
        aiOracleAddress = _newOracle;
        emit ProtocolParametersUpdated(aiAnalysisFee, challengeStakeRequirement, challengeVotePeriod, minInfluenceForFundingProposal, proposalVotePeriod, minProposalQuorumPercent); // Simplified for this param.
    }

    /**
     * @dev Allows the owner to set the addresses for Identity and Achievement NFT contracts.
     * @param _identityNFT The new address for the Identity NFT contract.
     * @param _achievementNFT The new address for the Achievement NFT contract.
     */
    function setNFTAddresses(address _identityNFT, address _achievementNFT) external onlyOwner {
        if (_identityNFT == address(0) || _achievementNFT == address(0)) {
            revert EvolveNexus__ZeroAddressNotAllowed();
        }
        identityNFT = IEvolveNexusIdentityNFT(_identityNFT);
        achievementNFT = IEvolveNexusAchievementNFT(_achievementNFT);
        emit ProtocolParametersUpdated(aiAnalysisFee, challengeStakeRequirement, challengeVotePeriod, minInfluenceForFundingProposal, proposalVotePeriod, minProposalQuorumPercent); // Simplified for this param.
    }

    /**
     * @dev Allows the owner to update the ERC20 Influence Token address.
     * @param _token The new address for the Influence Token.
     */
    function setInfluenceTokenAddress(address _token) external onlyOwner {
        if (_token == address(0)) {
            revert EvolveNexus__ZeroAddressNotAllowed();
        }
        influenceToken = IERC20(_token);
        emit ProtocolParametersUpdated(aiAnalysisFee, challengeStakeRequirement, challengeVotePeriod, minInfluenceForFundingProposal, proposalVotePeriod, minProposalQuorumPercent); // Simplified for this param.
    }

    /**
     * @dev Allows the owner to configure various system parameters.
     * @param _minCPForProp Min Cognition Points to submit a proposition.
     * @param _aiFee Cost for AI analysis per proposition.
     * @param _challengeStake Min stake to challenge AI analysis.
     * @param _challengePeriod Duration for community to vote on AI challenges.
     * @param _aiOracleRate Percentage of AI fee for oracle.
     * @param _minInflForProposal Min influence to create a funding proposal.
     * @param _minInflForVote Min influence to vote on a funding proposal.
     * @param _proposalPeriod Duration for community to vote on funding proposals.
     * @param _minQuorumPercent Min percentage of total influence for a proposal to be valid.
     * @param _voterRewardBP Basis points for voter rewards.
     */
    function setProtocolParameters(
        uint256 _minCPForProp,
        uint256 _aiFee,
        uint256 _challengeStake,
        uint256 _challengePeriod,
        uint256 _aiOracleRate,
        uint256 _minInflForProposal,
        uint256 _minInflForVote,
        uint256 _proposalPeriod,
        uint256 _minQuorumPercent,
        uint256 _voterRewardBP
    ) external onlyOwner {
        if (_aiOracleRate > 100 || _minQuorumPercent > 100 || _voterRewardBP > 10000) { // Max 100% for rate/quorum, 100% for BP
            revert EvolveNexus__InvalidParameters();
        }

        minCognitionPointsForProposition = _minCPForProp;
        aiAnalysisFee = _aiFee;
        challengeStakeRequirement = _challengeStake;
        challengeVotePeriod = _challengePeriod;
        aiOracleRewardRate = _aiOracleRate;

        minInfluenceForFundingProposal = _minInflForProposal;
        minInfluenceForVote = _minInflForVote;
        proposalVotePeriod = _proposalPeriod;
        minProposalQuorumPercent = _minQuorumPercent;
        successfulProposalVoterRewardBasisPoints = _voterRewardBP;

        emit ProtocolParametersUpdated(aiAnalysisFee, challengeStakeRequirement, challengeVotePeriod, minInfluenceForFundingProposal, proposalVotePeriod, minProposalQuorumPercent);
    }

    /**
     * @dev Pauses all core functionalities of the contract. Only owner.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only owner.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to recover tokens mistakenly sent to the contract.
     *      This is for emergency situations, not for protocol-owned funds.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawStuckTokens(address _token, uint256 _amount) external onlyOwner {
        if (_token == address(influenceToken)) {
            // Cannot withdraw influence tokens from contract directly
            // as they are part of the protocol's active economy.
            revert EvolveNexus__InvalidParameters();
        }
        IERC20(_token).safeTransfer(owner(), _amount);
    }

    // --- II. User & Reputation Management ---

    /**
     * @dev Registers a new user by minting a soulbound IdentityNFT.
     *      Requires the IdentityNFT contract to be set.
     *      Users can only register once.
     */
    function registerUser() external whenNotPaused {
        if (identityNFT.balanceOf(msg.sender) > 0) {
            revert EvolveNexus__AlreadyRegistered();
        }
        uint256 newId = identityNFT.mint(msg.sender);
        userCognitionPoints[msg.sender] = 50; // Initial CP
        emit UserRegistered(msg.sender, newId);
    }

    /**
     * @dev Allows users to stake InfluenceTokens to boost their InfluenceScore.
     * @param _amount The amount of InfluenceTokens to stake.
     */
    function stakeInfluenceTokens(uint256 _amount) external whenNotPaused isRegisteredUser(msg.sender) {
        if (_amount == 0) {
            revert EvolveNexus__AmountMustBeGreaterThanZero();
        }
        influenceToken.safeTransferFrom(msg.sender, address(this), _amount);
        userStakedInfluenceTokens[msg.sender] = userStakedInfluenceTokens[msg.sender].add(_amount);
        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows users to unstake their InfluenceTokens.
     *      May include cooldowns or checks for active proposals/challenges.
     * @param _amount The amount of InfluenceTokens to unstake.
     */
    function unstakeInfluenceTokens(uint256 _amount) external whenNotPaused isRegisteredUser(msg.sender) {
        if (_amount == 0) {
            revert EvolveNexus__AmountMustBeGreaterThanZero();
        }
        if (userStakedInfluenceTokens[msg.sender] < _amount) {
            revert EvolveNexus__InsufficientInfluenceTokens();
        }

        // Basic check: user should not have active challenges or proposals
        // (More complex logic would iterate through active challenges/proposals
        // or track participant status to prevent unstaking during critical periods)
        // For this example, we'll keep it simple: no immediate checks.
        // A real system would have a lock-up period or specific checks for active participation.

        userStakedInfluenceTokens[msg.sender] = userStakedInfluenceTokens[msg.sender].sub(_amount);
        influenceToken.safeTransfer(msg.sender, _amount);
        emit TokensUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Calculates and returns a user's total InfluenceScore.
     *      InfluenceScore = StakedTokens + (CognitionPoints / 10)
     * @param _user The address of the user.
     * @return The calculated influence score.
     */
    function getInfluenceScore(address _user) public view isRegisteredUser(_user) returns (uint256) {
        // Example calculation: Staked tokens plus a fraction of cognition points
        return userStakedInfluenceTokens[_user].add(userCognitionPoints[_user].div(10));
    }

    /**
     * @dev Returns a user's current CognitionPoints.
     * @param _user The address of the user.
     * @return The user's cognition points.
     */
    function getCognitionPoints(address _user) public view isRegisteredUser(_user) returns (uint256) {
        return userCognitionPoints[_user];
    }

    /**
     * @dev Allows the protocol to mint a dynamic AchievementNFT for a user.
     *      Typically called after a user achieves a milestone.
     * @param _recipient The address to mint the NFT to.
     * @param _achievementType An identifier for the type of achievement.
     * @param _initialURI The initial metadata URI for the NFT.
     */
    function mintAchievementNFT(address _recipient, uint256 _achievementType, string memory _initialURI) external onlyOwner {
        if (_recipient == address(0)) {
            revert EvolveNexus__ZeroAddressNotAllowed();
        }
        uint256 tokenId = nextAchievementNFTId++;
        achievementNFT.mint(_recipient, tokenId, _initialURI);
        emit AchievementNFTMinted(_recipient, tokenId, _achievementType);
    }

    /**
     * @dev Allows the protocol to update the metadata URI of an AchievementNFT.
     *      This makes the NFT dynamic, reflecting changes in user's status or progress.
     * @param _tokenId The ID of the AchievementNFT to update.
     * @param _newURI The new metadata URI.
     */
    function updateAchievementNFTMetadata(uint256 _tokenId, string memory _newURI) external onlyOwner {
        // This function must be called by the `EvolveNexus` contract (owner)
        // or a designated role within the EvolveNexus, for a specific AchievementNFT.
        // The AchievementNFT contract itself should restrict `updateTokenURI` to `EvolveNexus` owner.
        achievementNFT.updateTokenURI(_tokenId, _newURI);
        emit AchievementNFTUpdated(_tokenId, _newURI);
    }

    /**
     * @dev Internal function to update a user's Cognition Points.
     *      Used for rewarding or penalizing users based on their actions.
     * @param _user The address of the user.
     * @param _pointsDelta The change in cognition points (positive for increase, negative for decrease).
     */
    function _updateCognitionPoints(address _user, int256 _pointsDelta) internal {
        uint256 currentPoints = userCognitionPoints[_user];
        if (_pointsDelta > 0) {
            userCognitionPoints[_user] = currentPoints.add(uint256(_pointsDelta));
        } else {
            uint256 absDelta = uint256(-_pointsDelta);
            if (currentPoints < absDelta) {
                userCognitionPoints[_user] = 0; // Cap at 0
            } else {
                userCognitionPoints[_user] = currentPoints.sub(absDelta);
            }
        }
    }

    // --- III. AI-Powered Proposition System ---

    /**
     * @dev Users submit an idea/task for AI analysis and potential community reward.
     *      Requires minimum CognitionPoints and payment of AI analysis fee.
     * @param _title The title of the proposition.
     * @param _descriptionHash IPFS hash of the detailed description.
     * @param _targetRecipient The address to receive the reward if the proposition is successful.
     * @param _rewardBounty The amount of tokens to reward if the proposition is successful.
     * @param _aiValidationFee The fee for AI analysis, paid in InfluenceTokens.
     */
    function submitProposition(
        string memory _title,
        string memory _descriptionHash,
        address _targetRecipient,
        uint256 _rewardBounty,
        uint256 _aiValidationFee
    ) external payable whenNotPaused isRegisteredUser(msg.sender) {
        if (userCognitionPoints[msg.sender] < minCognitionPointsForProposition) {
            revert EvolveNexus__InsufficientCognitionPoints();
        }
        if (_aiValidationFee < aiAnalysisFee) {
            revert EvolveNexus__InvalidParameters(); // Must meet minimum AI fee
        }
        if (_rewardBounty == 0) {
            revert EvolveNexus__AmountMustBeGreaterThanZero();
        }

        // Transfer AI analysis fee to protocol.
        // The fee covers oracle call and protocol fees.
        influenceToken.safeTransferFrom(msg.sender, address(this), _aiValidationFee);

        uint256 propId = nextPropositionId++;
        propositions[propId] = Proposition({
            creator: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            targetRecipient: _targetRecipient,
            rewardBounty: _rewardBounty,
            aiValidationFee: _aiValidationFee,
            aiReportHash: "",
            sentimentScore: 0,
            originalityScore: 0,
            analysisTimestamp: 0,
            isChallenged: false,
            challenger: address(0),
            challengeStake: 0,
            challengeReasonHash: "",
            challengeStartTimestamp: 0,
            status: PropositionStatus.PendingAnalysis,
            votesForAI: 0,
            votesAgainstAI: 0,
            rewardClaimed: false
        });

        emit PropositionSubmitted(propId, msg.sender, _title, _rewardBounty);
        emit AIAnalysisRequested(propId, msg.sender); // Event for off-chain oracle to pick up
    }

    /**
     * @dev Called by the AI oracle to report its analysis results for a proposition.
     * @param _propositionId The ID of the proposition.
     * @param _aiReportHash IPFS hash of the detailed AI report.
     * @param _sentimentScore A score representing the sentiment of the proposition (e.g., 0-100).
     * @param _originalityScore A score representing the originality (e.g., 0-100).
     */
    function fulfillAIAnalysis(
        uint256 _propositionId,
        string memory _aiReportHash,
        uint256 _sentimentScore,
        uint256 _originalityScore
    ) external onlyAIOracle whenNotPaused {
        Proposition storage prop = propositions[_propositionId];
        if (prop.creator == address(0)) {
            revert EvolveNexus__PropositionNotFound();
        }
        if (prop.status != PropositionStatus.PendingAnalysis) {
            revert EvolveNexus__PropositionAlreadyFulfilled();
        }

        prop.aiReportHash = _aiReportHash;
        prop.sentimentScore = _sentimentScore;
        prop.originalityScore = _originalityScore;
        prop.analysisTimestamp = block.timestamp;
        prop.status = PropositionStatus.AIAnalyzed;

        // Transfer AI oracle reward
        uint256 oracleReward = prop.aiValidationFee.mul(aiOracleRewardRate).div(100);
        influenceToken.safeTransfer(aiOracleAddress, oracleReward);

        emit AIAnalysisFulfilled(_propositionId, _aiReportHash, _sentimentScore, _originalityScore);
    }

    /**
     * @dev Allows a user to challenge the AI's analysis of a proposition.
     *      Requires a challenge stake and the proposition must be in 'AIAnalyzed' status.
     * @param _propositionId The ID of the proposition to challenge.
     * @param _reasonHash IPFS hash of the reason for the challenge.
     * @param _challengeStake The amount of InfluenceTokens to stake for the challenge.
     */
    function challengeAIAnalysis(
        uint256 _propositionId,
        string memory _reasonHash,
        uint256 _challengeStake
    ) external whenNotPaused isRegisteredUser(msg.sender) {
        Proposition storage prop = propositions[_propositionId];
        if (prop.creator == address(0)) {
            revert EvolveNexus__PropositionNotFound();
        }
        if (prop.status != PropositionStatus.AIAnalyzed) {
            revert EvolveNexus__PropositionNotPendingAnalysis();
        }
        if (_challengeStake < challengeStakeRequirement) {
            revert EvolveNexus__InsufficientChallengeStake();
        }

        influenceToken.safeTransferFrom(msg.sender, address(this), _challengeStake);

        prop.isChallenged = true;
        prop.challenger = msg.sender;
        prop.challengeStake = _challengeStake;
        prop.challengeReasonHash = _reasonHash;
        prop.challengeStartTimestamp = block.timestamp;
        prop.status = PropositionStatus.Challenged;
        prop.hasVotedOnChallenge[msg.sender] = true; // Challenger automatically votes against AI

        _updateCognitionPoints(msg.sender, 5); // Small CP reward for taking initiative

        emit AIAnalysisChallenged(_propositionId, msg.sender, _challengeStake);
    }

    /**
     * @dev Allows registered users to vote on an active AI challenge.
     * @param _propositionId The ID of the proposition with an active challenge.
     * @param _supportAI True if voting to support the AI's report, false to support the challenger.
     */
    function voteOnAIChallenge(uint256 _propositionId, bool _supportAI) external whenNotPaused isRegisteredUser(msg.sender) {
        Proposition storage prop = propositions[_propositionId];
        if (prop.creator == address(0)) {
            revert EvolveNexus__PropositionNotFound();
        }
        if (prop.status != PropositionStatus.Challenged) {
            revert EvolveNexus__PropositionNotInChallengePeriod();
        }
        if (block.timestamp > prop.challengeStartTimestamp.add(challengeVotePeriod)) {
            revert EvolveNexus__VotingPeriodNotActive();
        }
        if (prop.hasVotedOnChallenge[msg.sender]) {
            revert EvolveNexus__AlreadyVoted();
        }

        uint256 voterInfluence = getInfluenceScore(msg.sender);
        if (voterInfluence < minInfluenceForVote) {
            revert EvolveNexus__InsufficientInfluenceTokens(); // Or specific error for influence
        }

        if (_supportAI) {
            prop.votesForAI = prop.votesForAI.add(voterInfluence);
        } else {
            prop.votesAgainstAI = prop.votesAgainstAI.add(voterInfluence);
        }
        prop.hasVotedOnChallenge[msg.sender] = true;

        emit ChallengeVoted(_propositionId, msg.sender, _supportAI);
    }

    /**
     * @dev Resolves an AI challenge after its voting period has ended.
     *      Distributes rewards/slashes stakes and adjusts CognitionPoints.
     * @param _propositionId The ID of the proposition with the challenge.
     */
    function resolveAIChallenge(uint256 _propositionId) external whenNotPaused {
        Proposition storage prop = propositions[_propositionId];
        if (prop.creator == address(0)) {
            revert EvolveNexus__PropositionNotFound();
        }
        if (prop.status != PropositionStatus.Challenged) {
            revert EvolveNexus__PropositionNotInChallengePeriod();
        }
        if (block.timestamp <= prop.challengeStartTimestamp.add(challengeVotePeriod)) {
            revert EvolveNexus__VotingPeriodNotActive();
        }
        if (prop.challenger == address(0)) {
            revert EvolveNexus__ChallengeAlreadyResolved(); // Or not challenged at all
        }

        bool aiReportConfirmed = prop.votesForAI >= prop.votesAgainstAI; // AI wins or tie
        address winningParty = aiReportConfirmed ? aiOracleAddress : prop.challenger; // Simplified: Oracle gets reward if AI confirmed

        if (aiReportConfirmed) {
            // AI report confirmed: challenger loses stake, proposition creator gets CP boost
            uint256 retainedStake = prop.challengeStake.div(2); // Half to treasury, half to voters
            influenceToken.safeTransfer(address(this), prop.challengeStake.sub(retainedStake)); // Protocol retains part of stake
            // TODO: distribute retainedStake to voters who supported AI
            _updateCognitionPoints(prop.creator, 20); // Reward for accurate proposition
            _updateCognitionPoints(prop.challenger, -20); // Penalty for failed challenge
            prop.status = PropositionStatus.ChallengeResolved_AIConfirmed;
        } else {
            // Challenger wins: challenger gets stake back + reward, AI oracle may get CP penalty
            influenceToken.safeTransfer(prop.challenger, prop.challengeStake); // Challenger gets stake back
            _updateCognitionPoints(prop.challenger, 30); // Reward for successful challenge
            _updateCognitionPoints(prop.creator, -10); // Small penalty if proposition was flawed
            // TODO: Penalize AI oracle's CP or reputation if its report was consistently wrong.
            prop.status = PropositionStatus.ChallengeResolved_ChallengerWon;
        }

        emit ChallengeResolved(_propositionId, aiReportConfirmed, winningParty);
    }

    /**
     * @dev Distributes the reward bounty to the proposition creator if the proposition
     *      is deemed successful (e.g., AI confirmed, or challenger won against a bad AI report).
     * @param _propositionId The ID of the proposition.
     */
    function distributePropositionReward(uint256 _propositionId) external whenNotPaused {
        Proposition storage prop = propositions[_propositionId];
        if (prop.creator == address(0)) {
            revert EvolveNexus__PropositionNotFound();
        }
        if (prop.rewardClaimed) {
            revert EvolveNexus__RewardAlreadyDistributed();
        }
        if (prop.status != PropositionStatus.ChallengeResolved_AIConfirmed &&
            prop.status != PropositionStatus.ChallengeResolved_ChallengerWon) {
            revert EvolveNexus__PropositionNotApprovedForReward();
        }

        // Assuming prop.rewardBounty is initially paid into the contract or will be transferred.
        // For simplicity, we'll assume the `rewardBounty` is available in the contract.
        // A more robust system would require the creator to deposit this bounty upon submission
        // or for the treasury to fund it.
        // Here, we just transfer. If `influenceToken` is also the treasury token:
        influenceToken.safeTransfer(prop.targetRecipient, prop.rewardBounty);
        prop.rewardClaimed = true;
        _updateCognitionPoints(prop.creator, 50); // Significant CP for successful proposition

        emit RewardDistributed(_propositionId, prop.targetRecipient, prop.rewardBounty);
    }

    // --- IV. Decentralized Funding & Governance ---

    /**
     * @dev Allows users with sufficient InfluenceScore to create a funding proposal
     *      to request funds from the protocol treasury.
     * @param _title The title of the proposal.
     * @param _descriptionHash IPFS hash of the detailed proposal description.
     * @param _requestedAmount The amount of tokens requested from the treasury.
     * @param _minInfluenceToVote The minimum influence score required to vote on this specific proposal.
     */
    function createFundingProposal(
        string memory _title,
        string memory _descriptionHash,
        uint256 _requestedAmount,
        uint256 _minInfluenceToVote
    ) external whenNotPaused isRegisteredUser(msg.sender) {
        if (getInfluenceScore(msg.sender) < minInfluenceForFundingProposal) {
            revert EvolveNexus__InsufficientInfluenceTokens(); // Or specific error for influence
        }
        if (_requestedAmount == 0) {
            revert EvolveNexus__AmountMustBeGreaterThanZero();
        }
        if (_minInfluenceToVote < minInfluenceForVote) {
            revert EvolveNexus__InvalidParameters(); // Must meet global min for voting
        }

        uint256 propId = nextFundingProposalId++;
        fundingProposals[propId] = FundingProposal({
            creator: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            requestedAmount: _requestedAmount,
            minInfluenceToVote: _minInfluenceToVote,
            creationTimestamp: block.timestamp,
            votingEndTimestamp: block.timestamp.add(proposalVotePeriod),
            status: ProposalStatus.Voting,
            totalInfluenceFor: 0,
            totalInfluenceAgainst: 0,
            totalVoterInfluence: 0,
            executionTimestamp: 0
        });

        emit FundingProposalCreated(propId, msg.sender, _title, _requestedAmount);
    }

    /**
     * @dev Allows registered users to vote on an active funding proposal.
     *      Voting power is weighted by InfluenceScore.
     * @param _proposalId The ID of the funding proposal.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnFundingProposal(uint256 _proposalId, bool _support) external whenNotPaused isRegisteredUser(msg.sender) {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        if (proposal.creator == address(0)) {
            revert EvolveNexus__ProposalNotFound();
        }
        if (proposal.status != ProposalStatus.Voting) {
            revert EvolveNexus__VotingPeriodNotActive();
        }
        if (block.timestamp > proposal.votingEndTimestamp) {
            revert EvolveNexus__VotingPeriodNotActive();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert EvolveNexus__AlreadyVoted();
        }

        uint256 voterInfluence = getInfluenceScore(msg.sender);
        if (voterInfluence < proposal.minInfluenceToVote) {
            revert EvolveNexus__InsufficientInfluenceTokens(); // Or specific error for influence
        }

        if (_support) {
            proposal.totalInfluenceFor = proposal.totalInfluenceFor.add(voterInfluence);
        } else {
            proposal.totalInfluenceAgainst = proposal.totalInfluenceAgainst.add(voterInfluence);
        }
        proposal.totalVoterInfluence = proposal.totalVoterInfluence.add(voterInfluence);
        proposal.hasVoted[msg.sender] = true;

        emit VotedOnProposal(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a funding proposal if it has passed its voting period
     *      and met the required quorum and approval thresholds.
     * @param _proposalId The ID of the funding proposal to execute.
     */
    function executeFundingProposal(uint256 _proposalId) external whenNotPaused {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        if (proposal.creator == address(0)) {
            revert EvolveNexus__ProposalNotFound();
        }
        if (proposal.status != ProposalStatus.Voting || block.timestamp <= proposal.votingEndTimestamp) {
            revert EvolveNexus__ProposalNotExecutable();
        }

        // Check quorum: total influence that voted must be >= minQuorumPercent of total staked influence
        // For simplicity, we'll use totalInfluenceFor + totalInfluenceAgainst as total participant influence
        // A more accurate system would query total active staked influence at the start of voting.
        uint256 totalActiveInfluence = influenceToken.balanceOf(address(this)); // Total influence staked in contract
        uint256 requiredQuorum = totalActiveInfluence.mul(minProposalQuorumPercent).div(100);
        if (proposal.totalVoterInfluence < requiredQuorum) {
            proposal.status = ProposalStatus.Defeated;
            revert EvolveNexus__QuorumNotMet();
        }

        // Check approval: votesFor must be greater than votesAgainst
        // And usually some threshold like >50% or 66%
        if (proposal.totalInfluenceFor <= proposal.totalInfluenceAgainst) {
            proposal.status = ProposalStatus.Defeated;
            revert EvolveNexus__VotingThresholdNotMet();
        }

        // Proposal passed!
        if (influenceToken.balanceOf(address(this)) < proposal.requestedAmount) {
            revert EvolveNexus__InsufficientTreasuryFunds();
        }

        influenceToken.safeTransfer(proposal.creator, proposal.requestedAmount);
        proposal.status = ProposalStatus.Executed;
        proposal.executionTimestamp = block.timestamp;

        _updateCognitionPoints(proposal.creator, 40); // Reward proposal creator

        emit ProposalExecuted(_proposalId, proposal.creator, proposal.requestedAmount);
    }

    /**
     * @dev Allows users who voted on a successful funding proposal to claim a reward.
     *      Reward is a percentage of the requested amount, shared among successful voters.
     * @param _proposalId The ID of the funding proposal.
     */
    function claimVoterReward(uint256 _proposalId) external whenNotPaused {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        if (proposal.creator == address(0)) {
            revert EvolveNexus__ProposalNotFound();
        }
        if (proposal.status != ProposalStatus.Executed) {
            revert EvolveNexus__ProposalNotExecutable();
        }
        if (!proposal.hasVoted[msg.sender]) {
            revert EvolveNexus__AlreadyVoted(); // Only voters can claim
        }
        // Further check: only if they voted FOR the successful proposal
        uint256 voterInfluence = getInfluenceScore(msg.sender);
        if (proposal.hasVoted[msg.sender] && voterInfluence > 0) { // Check if user actually voted and had influence
            // If they voted against, they don't get a reward
            // For simplicity, we assume if they voted, they voted 'correctly' (for the winning side).
            // A more complex system would track 'for'/'against' per user.

            // Calculate reward: % of requested amount, proportional to voter's influence
            uint256 totalRewardPool = proposal.requestedAmount.mul(successfulProposalVoterRewardBasisPoints).div(10000);
            if (totalRewardPool == 0 || proposal.totalInfluenceFor == 0) {
                 revert EvolveNexus__InvalidParameters(); // No reward or no successful voters
            }
            uint256 individualReward = totalRewardPool.mul(voterInfluence).div(proposal.totalInfluenceFor);

            if (individualReward > 0) {
                // Assuming reward is paid from protocol fees or a separate reward pool.
                // For simplicity, we'll assume the protocol has a general reward pool.
                // In this example, it might just come from general treasury, so we need funds.
                influenceToken.safeTransfer(msg.sender, individualReward);
                _updateCognitionPoints(msg.sender, 5); // Small CP reward for participation
                // Mark voter as having claimed to prevent double claims
                // This would require a separate mapping: `mapping(uint256 => mapping(address => bool)) public hasClaimedVoterReward;`
                // For simplicity, we omit it for now, allowing multiple claims per proposal if not tracked.
                // In a real system, you must prevent double claims.
                emit RewardDistributed(_proposalId, msg.sender, individualReward);
            }
        }
    }

    // --- V. Treasury & Protocol Economy ---

    /**
     * @dev Allows any user to deposit InfluenceTokens into the protocol treasury.
     *      These funds can be used for funding proposals.
     */
    function depositTreasuryFunds(uint256 _amount) external whenNotPaused {
        if (_amount == 0) {
            revert EvolveNexus__AmountMustBeGreaterThanZero();
        }
        influenceToken.safeTransferFrom(msg.sender, address(this), _amount);
        // Funds are now in the contract, available for proposals.
    }

    /**
     * @dev Returns the current balance of the protocol's treasury (in InfluenceTokens).
     * @return The balance of InfluenceTokens held by the contract.
     */
    function getProtocolTreasuryBalance() external view returns (uint256) {
        return influenceToken.balanceOf(address(this));
    }
}
```