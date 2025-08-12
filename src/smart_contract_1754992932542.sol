Here's a Solidity smart contract for a decentralized protocol called "SynergyForge," designed around interesting, advanced, creative, and trendy concepts like reputation-bound NFTs (SBT-like), incentivized collective intelligence (via "Insight Validation Markets"), and reputation-weighted governance. It aims to avoid direct duplication of existing large open-source projects by combining these elements in a novel way.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol"; // For unique IDs

// --- Outline of SynergyForge Protocol ---
// SynergyForge is a decentralized protocol designed to foster and incentivize collective intelligence and valuable insights.
// It leverages a unique blend of reputation-based governance, dynamic utility NFTs, and a novel "insight validation market"
// to allocate resources towards impactful contributions. Participants stake funds, contribute insights, and validate proposals
// to earn reputation (SynergyScore) and rewards.

// --- Core Concepts ---
// 1. Participant Staking: Users stake ETH to participate, earn baseline rewards, and gain eligibility for other features.
// 2. SynergyScore (SBT-like): A non-transferable, on-chain reputation score accumulated through meaningful contributions
//    (e.g., submitting validated insights, voting accurately in markets, participating in governance). This score determines
//    voting power in the DAO, NFT level, and potential reward multipliers.
// 3. SynergyNode NFT (Dynamic ERC721): An evolving utility NFT representing a participant's stake and SynergyScore.
//    Its metadata and "level" change as the participant's SynergyScore increases, visually upgrading the NFT and
//    potentially unlocking in-protocol benefits or exclusive features. These NFTs are designed to be non-transferable,
//    similar to Soulbound Tokens, linking a user's identity to their on-chain contributions.
// 4. Insight Validation Market: A core mechanism where participants propose "insights" (e.g., research findings, solutions to
//    problems, predictions, or even outputs from off-chain AI models). Other participants can then "stake" on the perceived
//    validity or impact of these insights. An external, trusted oracle provides the definitive evaluation. Stakers who predict
//    correctly are rewarded and gain SynergyScore, while those who predict incorrectly are penalized. Proposers of validated
//    insights also gain significant SynergyScore.
// 5. Synergy Treasury & Grant System: A community-governed treasury funded by protocol fees (e.g., losing stakes from insight markets)
//    and voluntary contributions. Funds are allocated to impactful projects (grants) that align with the protocol's mission,
//    based on reputation-weighted votes from SynergyScore holders.
// 6. Decentralized Governance: Key protocol parameters (like staking APY, minimum stake) and treasury allocations are managed
//    through a reputation-weighted voting system, where voting power is directly tied to a participant's SynergyScore.

// --- Function Summary (Total: 26 distinct functions excluding constructor, internal, and basic getters) ---

// I. Core Protocol & Staking (4 functions)
//    1. stakeForParticipation(uint256 amount): Allows users to stake ETH into the protocol to earn rewards and participate.
//    2. unstakeParticipation(): Allows users to withdraw their staked ETH.
//    3. claimStakingRewards(): Allows users to claim accumulated staking rewards.
//    4. getParticipantInfo(address participant): Retrieves detailed information about a participant's stake and rewards.

// II. SynergyScore & SynergyNode NFT (ERC721URIStorage extension) (5 functions)
//    5. mintSynergyNodeNFT(): Mints the initial SynergyNode NFT for a participant. Requires initial stake.
//    6. upgradeSynergyNodeNFT(): Triggers an upgrade of the SynergyNode NFT's visual representation (URI) based on SynergyScore.
//    7. getSynergyScore(address user): Returns the current SynergyScore of a given user.
//    8. getSynergyNodeLevel(address user): Returns the current level of a user's SynergyNode NFT.
//    9. getSynergyNodeURI(address user): Returns the current metadata URI of a user's SynergyNode NFT.

// III. Insight Management & Validation (6 functions)
//    10. submitInsightProposal(string calldata ipfsHash, uint256 collateralAmount): Allows users to submit a new insight proposal and stake collateral.
//    11. stakeOnInsightValidity(uint256 insightId, bool prediction, uint256 amount): Allows users to stake ETH on the predicted validity/impact of an insight.
//    12. reportInsightEvaluation(uint256 insightId, bool isValid, uint256 impactScore): Callable by the designated oracle to report the external evaluation of an insight.
//    13. resolveInsightValidationMarket(uint256 insightId): Resolves an insight's validation market, distributing rewards/penalties and updating SynergyScores.
//    14. getInsightDetails(uint256 insightId): Retrieves detailed information about a specific insight proposal.
//    15. getInsightStakeDetails(uint256 insightId, address staker): Retrieves details of a specific user's stake on an insight.

// IV. Synergy Treasury & Grant Allocation (4 functions)
//    16. depositToTreasury(): Allows anyone to contribute ETH to the protocol's treasury.
//    17. createGrantProposal(string calldata ipfsHash, uint256 requestedAmount): Allows a participant to propose a grant request from the treasury.
//    18. voteOnGrantProposal(uint256 proposalId, bool support): Allows participants to vote on a grant proposal, weighted by SynergyScore.
//    19. executeGrantProposal(uint256 proposalId): Executes an approved grant proposal, transferring funds from the treasury.

// V. Decentralized Governance (4 functions)
//    20. proposeGovernanceChange(address target, bytes calldata callData, string calldata description): Allows participants to propose changes to protocol parameters or upgrades.
//    21. voteOnGovernanceChange(uint256 proposalId, bool support): Allows participants to vote on a governance proposal, weighted by SynergyScore.
//    22. executeGovernanceChange(uint256 proposalId): Executes an approved governance proposal.
//    23. getGovernanceProposalDetails(uint256 proposalId): Retrieves details of a governance proposal.

// VI. Protocol Configuration (3 functions - set via governance proposals, but using `onlyOwner` for simplicity in this example)
//    24. setStakingAPY(uint256 newAPY): Sets the annual percentage yield for staking rewards.
//    25. setMinStakeAmount(uint256 newMinAmount): Sets the minimum amount required to stake for participation.
//    26. setInsightOracle(address newOracle): Sets the address of the trusted insight evaluation oracle.

contract SynergyForge is Ownable, ReentrancyGuard, ERC721URIStorage {
    using SafeMath for uint256;
    using Counters for Counters.Counter; // For unique IDs

    // --- State Variables ---

    // Protocol Configuration
    uint256 public stakingAPY; // Annual Percentage Yield for staking, e.g., 500 = 5% (stored as basis points)
    uint256 public minStakeAmount; // Minimum ETH required to stake for participation in wei
    uint256 public constant MAX_SYNERGY_SCORE = 10_000_000; // Max possible synergy score
    uint256 public constant INSIGHT_COLLATERAL_MIN = 0.05 ether; // Min ETH collateral for insight proposals
    uint256 public constant INSIGHT_VALIDATION_STAKE_MIN = 0.01 ether; // Min ETH stake for insight validation
    uint256 public constant SYNERGY_SCORE_INSIGHT_ACCURATE_REWARD = 100; // SynergyScore increase for accurate insight validation/submission
    uint256 public constant SYNERGY_SCORE_INSIGHT_INACCURATE_PENALTY = 50; // SynergyScore decrease for inaccurate insight validation/submission
    uint256 public constant SYNERGY_SCORE_GRANT_VOTE_REWARD = 5; // SynergyScore increase for participating in a grant vote

    address public insightEvaluationOracle; // Address of the trusted oracle for evaluating insights

    // Staking Pool & Participants
    struct Participant {
        uint256 stakedAmount;
        uint256 lastRewardUpdate;
        uint256 claimedRewards;
        uint256 synergyScore; // Non-transferable reputation score
        bool hasSynergyNodeNFT;
        uint256 synergyNodeLevel; // Corresponds to NFT URI level
        uint256 synergyNodeTokenId; // Storing the specific token ID for easy lookup
    }
    mapping(address => Participant) public participants;
    uint256 public totalStakedETH; // Total ETH locked in the staking pool

    // Insight Management
    enum InsightStatus { Proposed, Evaluating, Resolved }
    struct Insight {
        uint256 id;
        address proposer;
        string ipfsHash; // IPFS hash to store detailed insight proposal
        uint256 collateralAmount;
        InsightStatus status;
        bool isValidated; // Outcome from oracle: true if valid, false if invalid
        uint256 impactScore; // Oracle-provided score (0-100), influences reward distribution
        uint256 totalValidStakes; // Total ETH staked for `true` prediction
        uint256 totalInvalidStakes; // Total ETH staked for `false` prediction
        uint256 creationTime;
        uint256 resolutionTime;
        mapping(address => InsightStake) stakes; // Mapping of staker to their stake details
        address[] stakersList; // To iterate over stakers efficiently when resolving
    }
    struct InsightStake {
        bool prediction; // True if predicted valid, false if invalid
        uint256 amount;
        bool claimed; // To prevent double claiming rewards/penalties
    }
    Insight[] public insights;
    Counters.Counter private _insightIds;

    // Treasury & Grants
    struct GrantProposal {
        uint256 id;
        address proposer;
        string ipfsHash; // IPFS hash for detailed grant proposal
        uint256 requestedAmount;
        uint256 totalVotesFor; // Sum of SynergyScores of "for" voters
        uint256 totalVotesAgainst; // Sum of SynergyScores of "against" voters
        uint256 creationTime;
        uint256 votingEndTime;
        bool executed;
        mapping(address => bool) hasVoted; // To prevent double voting per address
    }
    GrantProposal[] public grantProposals;
    Counters.Counter private _grantProposalIds;
    uint256 public constant GRANT_VOTING_PERIOD = 7 days; // Voting period for grant proposals
    uint256 public constant GRANT_PASS_THRESHOLD_PERCENT = 60; // Percentage of total SynergyScore needed for approval (e.g., 60 means 60%)

    // Governance
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct GovernanceProposal {
        uint256 id;
        string description; // Description of the proposed change
        address target; // Address of the contract to call (e.g., this contract for parameter changes)
        bytes callData; // Encoded function call to execute (e.g., `abi.encodeWithSignature("setStakingAPY(uint256)", 600)`)
        uint256 totalVotesFor; // Sum of SynergyScores of "for" voters
        uint252 totalVotesAgainst; // Sum of SynergyScores of "against" voters
        uint256 creationTime;
        uint256 votingEndTime;
        ProposalState state;
        mapping(address => bool) hasVoted; // To prevent double voting per address
    }
    GovernanceProposal[] public governanceProposals;
    Counters.Counter private _governanceProposalIds;
    uint256 public constant GOVERNANCE_VOTING_PERIOD = 3 days; // Voting period for governance proposals
    uint256 public constant GOVERNANCE_QUORUM_MIN_SYNERGYSCORE_VOTES = 1000; // Minimum aggregate SynergyScore required for a governance proposal to be valid for execution

    // --- Events ---
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event SynergyScoreUpdated(address indexed user, int256 change, uint256 newScore);
    event SynergyNodeNFTMinted(address indexed user, uint256 tokenId);
    event SynergyNodeNFTUpgraded(address indexed user, uint256 tokenId, uint256 newLevel);
    event InsightProposed(uint256 indexed insightId, address indexed proposer, string ipfsHash, uint256 collateral);
    event InsightValidationStaked(uint256 indexed insightId, address indexed staker, bool prediction, uint256 amount);
    event InsightEvaluationReported(uint256 indexed insightId, address indexed oracle, bool isValid, uint256 impactScore);
    event InsightResolved(uint256 indexed insightId, bool isValidated, uint256 totalRewardPool);
    event TreasuryDeposited(address indexed depositor, uint256 amount);
    event GrantProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 requestedAmount);
    event GrantVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GrantExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceExecuted(uint256 indexed proposalId);
    event ProtocolParameterUpdated(string indexed parameterName, uint256 oldValue, uint256 newValue);

    // --- Constructor ---
    /// @notice Deploys the SynergyForge contract.
    /// @param initialOracle The address of the trusted oracle for evaluating insights.
    /// @param initialStakingAPY The initial annual percentage yield for staking (e.g., 500 for 5%).
    /// @param initialMinStakeAmount The initial minimum ETH required to stake for participation (in wei).
    constructor(
        address initialOracle,
        uint256 initialStakingAPY,
        uint256 initialMinStakeAmount
    ) ERC721URIStorage("SynergyNode", "SYN") Ownable(msg.sender) {
        require(initialOracle != address(0), "Invalid oracle address");
        insightEvaluationOracle = initialOracle;
        stakingAPY = initialStakingAPY;
        minStakeAmount = initialMinStakeAmount;
    }

    // --- Modifiers ---
    modifier onlyInsightOracle() {
        require(msg.sender == insightEvaluationOracle, "Caller is not the insight oracle");
        _;
    }

    // --- I. Core Protocol & Staking ---

    /// @notice Allows users to stake ETH into the protocol to earn rewards and participate.
    /// @param amount The amount of ETH (in wei) to stake. Must be sent with the transaction.
    function stakeForParticipation(uint256 amount) external payable nonReentrant {
        require(msg.value == amount, "ETH amount mismatch with value");
        require(amount >= minStakeAmount, "Amount too low to stake");

        Participant storage participant = participants[msg.sender];

        // Claim pending rewards before updating stake to prevent reward manipulation
        _updateStakingRewards(msg.sender);

        participant.stakedAmount = participant.stakedAmount.add(amount);
        totalStakedETH = totalStakedETH.add(amount);
        participant.lastRewardUpdate = block.timestamp;

        // If it's a new participant or re-staking after full unstake, initialize SynergyScore
        if (participant.synergyScore == 0) {
            participant.synergyScore = 1; // Initial minimal score for participation
            emit SynergyScoreUpdated(msg.sender, 1, 1);
        }

        emit Staked(msg.sender, amount);
    }

    /// @notice Allows users to withdraw their staked ETH.
    /// @dev Requires the participant to have staked ETH. Their SynergyScore will be reset upon full unstake.
    function unstakeParticipation() external nonReentrant {
        Participant storage participant = participants[msg.sender];
        require(participant.stakedAmount > 0, "No ETH staked to unstake");

        // Claim pending rewards before unstaking to finalize rewards
        _updateStakingRewards(msg.sender);

        uint256 amountToUnstake = participant.stakedAmount;
        participant.stakedAmount = 0; // Set staked amount to zero
        totalStakedETH = totalStakedETH.sub(amountToUnstake);

        // Reset SynergyScore if fully unstaked (can be re-earned upon re-staking)
        uint256 oldScore = participant.synergyScore;
        participant.synergyScore = 0;
        emit SynergyScoreUpdated(msg.sender, -int256(oldScore), 0);

        // Burn the associated SynergyNode NFT if it exists
        if (participant.hasSynergyNodeNFT) {
            _burn(participant.synergyNodeTokenId);
            participant.hasSynergyNodeNFT = false;
            participant.synergyNodeLevel = 0;
            participant.synergyNodeTokenId = 0;
        }

        payable(msg.sender).transfer(amountToUnstake);
        emit Unstaked(msg.sender, amountToUnstake);
    }

    /// @notice Allows users to claim accumulated staking rewards.
    /// @dev Rewards are calculated based on staking duration and APY.
    function claimStakingRewards() external nonReentrant {
        _updateStakingRewards(msg.sender); // Calculate and add new rewards
        Participant storage participant = participants[msg.sender];
        uint256 rewardsToClaim = participant.claimedRewards;
        require(rewardsToClaim > 0, "No rewards to claim");

        participant.claimedRewards = 0; // Reset claimed rewards
        payable(msg.sender).transfer(rewardsToClaim);
        emit RewardsClaimed(msg.sender, rewardsToClaim);
    }

    /// @notice Retrieves detailed information about a participant's stake and rewards.
    /// @param participantAddress The address of the participant.
    /// @return stakedAmount The amount of ETH staked.
    /// @return pendingRewards The amount of pending staking rewards.
    /// @return synergyScore The participant's SynergyScore.
    /// @return hasNFT True if the participant owns a SynergyNode NFT.
    /// @return nodeLevel The level of the participant's SynergyNode NFT.
    function getParticipantInfo(address participantAddress)
        external
        view
        returns (
            uint256 stakedAmount,
            uint256 pendingRewards,
            uint256 synergyScore,
            bool hasNFT,
            uint256 nodeLevel
        )
    {
        Participant storage participant = participants[participantAddress];
        stakedAmount = participant.stakedAmount;
        synergyScore = participant.synergyScore;
        hasNFT = participant.hasSynergyNodeNFT;
        nodeLevel = participant.synergyNodeLevel;

        if (stakedAmount > 0) {
            uint256 timeElapsed = block.timestamp.sub(participant.lastRewardUpdate);
            // Calculate rewards: (stakedAmount * stakingAPY / 10000) * timeElapsed / 1 year in seconds (31,536,000)
            pendingRewards = stakedAmount.mul(stakingAPY).mul(timeElapsed).div(10000).div(31_536_000);
        }
        pendingRewards = pendingRewards.add(participant.claimedRewards);
    }

    // --- Internal Helper for Staking Rewards ---
    function _updateStakingRewards(address user) internal {
        Participant storage participant = participants[user];
        if (participant.stakedAmount > 0) {
            uint256 timeElapsed = block.timestamp.sub(participant.lastRewardUpdate);
            uint256 newRewards = participant.stakedAmount.mul(stakingAPY).mul(timeElapsed).div(10000).div(31_536_000);
            participant.claimedRewards = participant.claimedRewards.add(newRewards);
            participant.lastRewardUpdate = block.timestamp;
        }
    }

    // --- Internal Helper for SynergyScore ---
    function _updateSynergyScore(address user, int256 change) internal {
        Participant storage participant = participants[user];
        uint256 oldScore = participant.synergyScore;
        uint256 newScore;

        if (change > 0) {
            newScore = oldScore.add(uint256(change));
            if (newScore > MAX_SYNERGY_SCORE) newScore = MAX_SYNERGY_SCORE;
        } else {
            uint256 absChange = uint256(change * -1);
            if (oldScore > absChange) {
                newScore = oldScore.sub(absChange);
            } else {
                newScore = 0; // SynergyScore cannot go below zero
            }
        }
        participant.synergyScore = newScore;
        emit SynergyScoreUpdated(user, change, newScore);

        // Trigger NFT upgrade check
        _checkAndUpgradeSynergyNodeNFT(user);
    }

    // --- II. SynergyScore & SynergyNode NFT ---

    /// @notice Mints the initial SynergyNode NFT for a participant.
    /// @dev Requires the participant to have a stake and not already own an NFT.
    function mintSynergyNodeNFT() external {
        Participant storage participant = participants[msg.sender];
        require(participant.stakedAmount > 0, "Must stake ETH to mint SynergyNode NFT");
        require(!participant.hasSynergyNodeNFT, "Already owns a SynergyNode NFT");

        // Use a simple counter for token IDs for deterministic IDs tied to mint order
        uint256 tokenId = _insightIds.current(); // Reusing the counter for simplicity, could be a separate one
        _insightIds.increment();

        _safeMint(msg.sender, tokenId);
        participant.hasSynergyNodeNFT = true;
        participant.synergyNodeLevel = 1; // Initial level
        participant.synergyNodeTokenId = tokenId;
        _setTokenURI(tokenId, _getTokenURIForLevel(1)); // Set initial URI
        emit SynergyNodeNFTMinted(msg.sender, tokenId);
        emit SynergyNodeNFTUpgraded(msg.sender, tokenId, 1);
    }

    /// @notice Triggers an upgrade of the SynergyNode NFT's visual representation (URI) based on SynergyScore.
    /// @dev This function is automatically called by `_updateSynergyScore` but can be called externally by the owner.
    function upgradeSynergyNodeNFT() external {
        _checkAndUpgradeSynergyNodeNFT(msg.sender);
    }

    function _checkAndUpgradeSynergyNodeNFT(address user) internal {
        Participant storage participant = participants[user];
        if (!participant.hasSynergyNodeNFT) return;

        uint256 currentScore = participant.synergyScore;
        uint256 currentLevel = participant.synergyNodeLevel;
        uint256 newLevel = currentLevel;

        // Define level thresholds. Adjust these for your desired progression.
        // Example thresholds (can be updated via governance)
        if (currentScore >= 5000 && currentLevel < 5) newLevel = 5;
        else if (currentScore >= 1000 && currentLevel < 4) newLevel = 4;
        else if (currentScore >= 250 && currentLevel < 3) newLevel = 3;
        else if (currentScore >= 50 && currentLevel < 2) newLevel = 2;

        if (newLevel > currentLevel) {
            participant.synergyNodeLevel = newLevel;
            uint256 tokenId = participant.synergyNodeTokenId;
            _setTokenURI(tokenId, _getTokenURIForLevel(newLevel));
            emit SynergyNodeNFTUpgraded(user, tokenId, newLevel);
        }
    }

    // Dynamic URI generation based on level
    function _getTokenURIForLevel(uint256 level) internal pure returns (string memory) {
        // In a real scenario, this would point to IPFS/Arweave with JSON metadata
        // For demonstration, a placeholder string that mimics IPFS CIDs.
        // Each level would have unique metadata (image, description, attributes).
        if (level == 1) return "ipfs://QmSynergyNodeL1";
        if (level == 2) return "ipfs://QmSynergyNodeL2";
        if (level == 3) return "ipfs://QmSynergyNodeL3";
        if (level == 4) return "ipfs://QmSynergyNodeL4";
        if (level == 5) return "ipfs://QmSynergyNodeL5";
        return "ipfs://QmSynergyNodeUnknown"; // Default or error
    }

    /// @notice Returns the current SynergyScore of a given user.
    /// @param user The address of the user.
    /// @return The SynergyScore.
    function getSynergyScore(address user) external view returns (uint256) {
        return participants[user].synergyScore;
    }

    /// @notice Returns the current level of a user's SynergyNode NFT.
    /// @param user The address of the user.
    /// @return The SynergyNode NFT level.
    function getSynergyNodeLevel(address user) external view returns (uint256) {
        return participants[user].synergyNodeLevel;
    }

    /// @notice Returns the current metadata URI of a user's SynergyNode NFT.
    /// @param user The address of the user.
    /// @return The metadata URI.
    function getSynergyNodeURI(address user) external view returns (string memory) {
        require(participants[user].hasSynergyNodeNFT, "User does not own a SynergyNode NFT");
        return tokenURI(participants[user].synergyNodeTokenId);
    }

    // --- III. Insight Management & Validation ---

    /// @notice Allows users to submit a new insight proposal and stake collateral.
    /// @param ipfsHash IPFS hash to store detailed insight proposal.
    /// @param collateralAmount Amount of ETH (in wei) staked as collateral for the insight.
    function submitInsightProposal(string calldata ipfsHash, uint256 collateralAmount) external payable nonReentrant {
        require(msg.value == collateralAmount, "Collateral amount mismatch with value");
        require(collateralAmount >= INSIGHT_COLLATERAL_MIN, "Collateral amount too low");
        require(participants[msg.sender].synergyScore > 0, "Must be a participant with SynergyScore to submit an insight");

        uint256 newInsightId = _insightIds.current();
        _insightIds.increment();

        insights.push(Insight({
            id: newInsightId,
            proposer: msg.sender,
            ipfsHash: ipfsHash,
            collateralAmount: collateralAmount,
            status: InsightStatus.Proposed,
            isValidated: false,
            impactScore: 0,
            totalValidStakes: 0,
            totalInvalidStakes: 0,
            creationTime: block.timestamp,
            resolutionTime: 0,
            stakersList: new address[](0)
        }));
        emit InsightProposed(newInsightId, msg.sender, ipfsHash, collateralAmount);
    }

    /// @notice Allows users to stake ETH on the predicted validity/impact of an insight.
    /// @param insightId The ID of the insight to stake on.
    /// @param prediction True if predicting valid, false if predicting invalid.
    /// @param amount The amount of ETH (in wei) to stake. Must be sent with the transaction.
    function stakeOnInsightValidity(uint256 insightId, bool prediction, uint256 amount) external payable nonReentrant {
        require(insightId < insights.length && insights[insightId].id == insightId, "Insight does not exist or invalid ID");
        Insight storage insight = insights[insightId];
        require(insight.status == InsightStatus.Proposed, "Insight is not in proposed status");
        require(msg.value == amount, "Stake amount mismatch with value");
        require(amount >= INSIGHT_VALIDATION_STAKE_MIN, "Stake amount too low");
        require(insight.stakes[msg.sender].amount == 0, "Already staked on this insight");
        require(participants[msg.sender].synergyScore > 0, "Must be a participant to stake on insights");

        insight.stakes[msg.sender] = InsightStake({
            prediction: prediction,
            amount: amount,
            claimed: false
        });
        insight.stakersList.push(msg.sender); // Add to list for iteration

        if (prediction) {
            insight.totalValidStakes = insight.totalValidStakes.add(amount);
        } else {
            insight.totalInvalidStakes = insight.totalInvalidStakes.add(amount);
        }

        emit InsightValidationStaked(insightId, msg.sender, prediction, amount);
    }

    /// @notice Callable by the designated oracle to report the external evaluation of an insight.
    /// @param insightId The ID of the insight.
    /// @param isValid True if the insight is validated as correct/useful, false otherwise.
    /// @param impactScore A score representing the impact/quality of the insight (0-100).
    function reportInsightEvaluation(uint256 insightId, bool isValid, uint256 impactScore) external onlyInsightOracle {
        require(insightId < insights.length && insights[insightId].id == insightId, "Insight does not exist or invalid ID");
        Insight storage insight = insights[insightId];
        require(insight.status == InsightStatus.Proposed, "Insight is not in proposed status");
        require(impactScore <= 100, "Impact score must be between 0 and 100");

        insight.isValidated = isValid;
        insight.impactScore = impactScore;
        insight.status = InsightStatus.Evaluating; // Temporarily 'Evaluating' until resolved
        insight.resolutionTime = block.timestamp;

        emit InsightEvaluationReported(insightId, msg.sender, isValid, impactScore);
    }

    /// @notice Resolves an insight's validation market, distributing rewards/penalties and updating SynergyScores.
    /// @param insightId The ID of the insight to resolve.
    function resolveInsightValidationMarket(uint256 insightId) external nonReentrant {
        require(insightId < insights.length && insights[insightId].id == insightId, "Insight does not exist or invalid ID");
        Insight storage insight = insights[insightId];
        require(insight.status == InsightStatus.Evaluating, "Insight is not in evaluation status or already resolved");

        // Calculate total pool including proposer's collateral and all stakers' funds
        uint256 totalPool = insight.totalValidStakes.add(insight.totalInvalidStakes).add(insight.collateralAmount);

        // Handle proposer's collateral and SynergyScore based on validation outcome
        if (!insight.isValidated) {
            // Proposer's collateral is forfeited to the contract's treasury
            _updateSynergyScore(insight.proposer, -int256(SYNERGY_SCORE_INSIGHT_INACCURATE_PENALTY));
        } else {
            // Proposer gets collateral back and earns SynergyScore based on impact
            payable(insight.proposer).transfer(insight.collateralAmount);
            _updateSynergyScore(insight.proposer, int256(SYNERGY_SCORE_INSIGHT_ACCURATE_REWARD).mul(insight.impactScore).div(100));
        }

        uint256 winningStakesTotal = insight.isValidated ? insight.totalValidStakes : insight.totalInvalidStakes;
        uint256 losingStakesTotal = insight.isValidated ? insight.totalInvalidStakes : insight.totalValidStakes;

        // Distribute rewards to winning stakers from the losing pool
        if (winningStakesTotal > 0) {
            for (uint256 i = 0; i < insight.stakersList.length; i++) {
                address staker = insight.stakersList[i];
                InsightStake storage stake = insight.stakes[staker];

                if (!stake.claimed) {
                    if (stake.prediction == insight.isValidated) { // Winner
                        // Winning stakers get their original stake back + a proportional share of the losing stakes
                        uint256 rewardShare = stake.amount.mul(losingStakesTotal).div(winningStakesTotal);
                        uint256 totalPayout = stake.amount.add(rewardShare);
                        payable(staker).transfer(totalPayout);
                        _updateSynergyScore(staker, int256(SYNERGY_SCORE_INSIGHT_ACCURATE_REWARD).mul(insight.impactScore).div(100));
                    } else { // Loser
                        // Losing stakes are absorbed into the pool to reward winners. No transfer out.
                        _updateSynergyScore(staker, -int256(SYNERGY_SCORE_INSIGHT_INACCURATE_PENALTY));
                    }
                    stake.claimed = true; // Mark as claimed
                }
            }
        } else if (losingStakesTotal > 0) {
            // If there are only losers (e.g., no one predicted correctly), all stakes go to treasury.
            // No explicit transfer here, funds simply remain in the contract balance as treasury.
            for (uint256 i = 0; i < insight.stakersList.length; i++) {
                address staker = insight.stakersList[i];
                InsightStake storage stake = insight.stakes[staker];
                if (!stake.claimed) {
                    _updateSynergyScore(staker, -int256(SYNERGY_SCORE_INSIGHT_INACCURATE_PENALTY));
                    stake.claimed = true;
                }
            }
        }

        insight.status = InsightStatus.Resolved; // Mark as resolved
        emit InsightResolved(insightId, insight.isValidated, totalPool);
    }

    /// @notice Retrieves detailed information about a specific insight proposal.
    /// @param insightId The ID of the insight.
    function getInsightDetails(uint256 insightId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory ipfsHash,
            uint256 collateralAmount,
            InsightStatus status,
            bool isValidated,
            uint256 impactScore,
            uint256 totalValidStakes,
            uint256 totalInvalidStakes,
            uint256 creationTime,
            uint256 resolutionTime
        )
    {
        require(insightId < insights.length && insights[insightId].id == insightId, "Insight does not exist or invalid ID");
        Insight storage insight = insights[insightId];
        return (
            insight.id,
            insight.proposer,
            insight.ipfsHash,
            insight.collateralAmount,
            insight.status,
            insight.isValidated,
            insight.impactScore,
            insight.totalValidStakes,
            insight.totalInvalidStakes,
            insight.creationTime,
            insight.resolutionTime
        );
    }

    /// @notice Retrieves details of a specific user's stake on an insight.
    /// @param insightId The ID of the insight.
    /// @param staker The address of the staker.
    /// @return prediction The staker's prediction (true for valid, false for invalid).
    /// @return amount The amount staked by the user.
    /// @return claimed True if the stake has been claimed/resolved.
    function getInsightStakeDetails(uint256 insightId, address staker)
        external
        view
        returns (bool prediction, uint256 amount, bool claimed)
    {
        require(insightId < insights.length && insights[insightId].id == insightId, "Insight does not exist or invalid ID");
        InsightStake storage stake = insights[insightId].stakes[staker];
        return (stake.prediction, stake.amount, stake.claimed);
    }

    // --- IV. Synergy Treasury & Grant Allocation ---

    /// @notice Allows anyone to contribute ETH to the protocol's treasury.
    function depositToTreasury() external payable {
        require(msg.value > 0, "Amount must be greater than zero");
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /// @notice Allows a participant to propose a grant request from the treasury.
    /// @param ipfsHash IPFS hash for detailed grant proposal.
    /// @param requestedAmount The amount of ETH (in wei) requested from the treasury.
    function createGrantProposal(string calldata ipfsHash, uint256 requestedAmount) external {
        require(participants[msg.sender].synergyScore > 0, "Only participants can create grant proposals");
        require(requestedAmount > 0, "Requested amount must be greater than zero");

        uint256 newGrantId = _grantProposalIds.current();
        _grantProposalIds.increment();

        grantProposals.push(GrantProposal({
            id: newGrantId,
            proposer: msg.sender,
            ipfsHash: ipfsHash,
            requestedAmount: requestedAmount,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(GRANT_VOTING_PERIOD),
            executed: false
        }));
        emit GrantProposalCreated(newGrantId, msg.sender, requestedAmount);
    }

    /// @notice Allows participants to vote on a grant proposal, weighted by SynergyScore.
    /// @param proposalId The ID of the grant proposal.
    /// @param support True to vote for, false to vote against.
    function voteOnGrantProposal(uint256 proposalId, bool support) external {
        require(proposalId < grantProposals.length && grantProposals[proposalId].id == proposalId, "Grant proposal does not exist or invalid ID");
        GrantProposal storage proposal = grantProposals[proposalId];
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(participants[msg.sender].synergyScore > 0, "Must be a participant with SynergyScore to vote");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterSynergyScore = participants[msg.sender].synergyScore;
        require(voterSynergyScore > 0, "Voter has no SynergyScore"); // Redundant but explicit check

        if (support) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(voterSynergyScore);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(voterSynergyScore);
        }
        proposal.hasVoted[msg.sender] = true;
        _updateSynergyScore(msg.sender, SYNERGY_SCORE_GRANT_VOTE_REWARD);
        emit GrantVoteCast(proposalId, msg.sender, support);
    }

    /// @notice Executes an approved grant proposal, transferring funds from the treasury.
    /// @dev Requires the voting period to be over and the proposal to meet the passing threshold.
    /// @param proposalId The ID of the grant proposal.
    function executeGrantProposal(uint256 proposalId) external nonReentrant {
        require(proposalId < grantProposals.length && grantProposals[proposalId].id == proposalId, "Grant proposal does not exist or invalid ID");
        GrantProposal storage proposal = grantProposals[proposalId];
        require(!proposal.executed, "Grant proposal already executed");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended");

        uint256 totalVotes = proposal.totalVotesFor.add(proposal.totalVotesAgainst);
        require(totalVotes > 0, "No votes cast for this proposal"); // Must have at least one vote to be considered

        bool passed = (proposal.totalVotesFor.mul(100) / totalVotes) >= GRANT_PASS_THRESHOLD_PERCENT;

        require(passed, "Grant proposal did not pass the voting threshold");
        require(address(this).balance >= proposal.requestedAmount, "Insufficient funds in treasury");

        proposal.executed = true;
        payable(proposal.proposer).transfer(proposal.requestedAmount);
        emit GrantExecuted(proposalId, proposal.proposer, proposal.requestedAmount);
    }

    /// @notice Retrieves detailed information about a grant proposal.
    /// @param proposalId The ID of the grant proposal.
    function getGrantProposalDetails(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory ipfsHash,
            uint256 requestedAmount,
            uint256 totalVotesFor,
            uint256 totalVotesAgainst,
            uint256 creationTime,
            uint256 votingEndTime,
            bool executed
        )
    {
        require(proposalId < grantProposals.length && grantProposals[proposalId].id == proposalId, "Grant proposal does not exist or invalid ID");
        GrantProposal storage proposal = grantProposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.ipfsHash,
            proposal.requestedAmount,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.creationTime,
            proposal.votingEndTime,
            proposal.executed
        );
    }

    // --- V. Decentralized Governance ---
    // Note: A more robust DAO would often use a separate Governor contract (like OpenZeppelin's Governor)
    // with a timelock to allow for review periods before execution. This is a simplified, direct-execution model.

    /// @notice Allows participants to propose changes to protocol parameters or upgrades.
    /// @param target The address of the contract to call for the change (can be `address(this)` for self-modification).
    /// @param callData The encoded function call to execute (e.g., `abi.encodeWithSignature("setStakingAPY(uint256)", 600)`).
    /// @param description A description of the proposed change.
    function proposeGovernanceChange(address target, bytes calldata callData, string calldata description) external {
        require(participants[msg.sender].synergyScore > 0, "Only participants can propose governance changes");

        uint256 newProposalId = _governanceProposalIds.current();
        _governanceProposalIds.increment();

        governanceProposals.push(GovernanceProposal({
            id: newProposalId,
            description: description,
            target: target,
            callData: callData,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(GOVERNANCE_VOTING_PERIOD),
            state: ProposalState.Pending
        }));
        emit GovernanceProposalCreated(newProposalId, msg.sender, description);
    }

    /// @notice Allows participants to vote on a governance proposal, weighted by SynergyScore.
    /// @param proposalId The ID of the governance proposal.
    /// @param support True to vote for, false to vote against.
    function voteOnGovernanceChange(uint256 proposalId, bool support) external {
        require(proposalId < governanceProposals.length && governanceProposals[proposalId].id == proposalId, "Governance proposal does not exist or invalid ID");
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Proposal not in active voting state");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(participants[msg.sender].synergyScore > 0, "Must be a participant with SynergyScore to vote");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        if (proposal.state == ProposalState.Pending) {
            proposal.state = ProposalState.Active; // Activate proposal on first vote
        }

        uint256 voterSynergyScore = participants[msg.sender].synergyScore;
        require(voterSynergyScore > 0, "Voter has no SynergyScore");

        if (support) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(voterSynergyScore);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(voterSynergyScore);
        }
        proposal.hasVoted[msg.sender] = true;
        _updateSynergyScore(msg.sender, SYNERGY_SCORE_GRANT_VOTE_REWARD); // Reuse score reward for any vote participation
        emit GovernanceVoteCast(proposalId, msg.sender, support);
    }

    /// @notice Executes an approved governance proposal.
    /// @dev Requires voting period to be over, proposal to pass quorum and threshold.
    /// @param proposalId The ID of the governance proposal.
    function executeGovernanceChange(uint256 proposalId) external nonReentrant {
        require(proposalId < governanceProposals.length && governanceProposals[proposalId].id == proposalId, "Governance proposal does not exist or invalid ID");
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.state != ProposalState.Executed, "Proposal already executed");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended");

        uint256 totalVotesCast = proposal.totalVotesFor.add(proposal.totalVotesAgainst);
        require(totalVotesCast >= GOVERNANCE_QUORUM_MIN_SYNERGYSCORE_VOTES, "Governance quorum not met");

        bool passed = (proposal.totalVotesFor.mul(100) / totalVotesCast) >= GOVERNANCE_PASS_THRESHOLD_PERCENT;

        if (passed) {
            proposal.state = ProposalState.Succeeded;
            // Execute the proposed function call
            (bool success, ) = proposal.target.call(proposal.callData);
            require(success, "Governance execution failed");
            proposal.state = ProposalState.Executed;
            emit GovernanceExecuted(proposalId);
        } else {
            proposal.state = ProposalState.Failed;
            revert("Governance proposal failed to pass");
        }
    }

    /// @notice Retrieves details of a governance proposal.
    /// @param proposalId The ID of the governance proposal.
    function getGovernanceProposalDetails(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            string memory description,
            address target,
            bytes memory callData,
            uint256 totalVotesFor,
            uint256 totalVotesAgainst,
            uint256 creationTime,
            uint256 votingEndTime,
            ProposalState state
        )
    {
        require(proposalId < governanceProposals.length && governanceProposals[proposalId].id == proposalId, "Governance proposal does not exist or invalid ID");
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        return (
            proposal.id,
            proposal.description,
            proposal.target,
            proposal.callData,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.creationTime,
            proposal.votingEndTime,
            proposal.state
        );
    }

    // --- VI. Protocol Configuration (Set via Governance) ---
    // These functions are intended to be called by the `executeGovernanceChange` function after a successful vote.
    // For simplicity in this example, they are marked `onlyOwner`, mimicking a privileged executor role.
    // In a full DAO, they would require a specific "governance executor" role (often the governance contract itself via a timelock).

    /// @notice Sets the annual percentage yield for staking rewards. Callable only via governance.
    /// @param newAPY The new APY (e.g., 500 for 5%).
    function setStakingAPY(uint256 newAPY) external onlyOwner {
        uint256 oldAPY = stakingAPY;
        stakingAPY = newAPY;
        emit ProtocolParameterUpdated("stakingAPY", oldAPY, newAPY);
    }

    /// @notice Sets the minimum amount required to stake for participation. Callable only via governance.
    /// @param newMinAmount The new minimum stake amount in wei.
    function setMinStakeAmount(uint256 newMinAmount) external onlyOwner {
        uint256 oldMinAmount = minStakeAmount;
        minStakeAmount = newMinAmount;
        emit ProtocolParameterUpdated("minStakeAmount", oldMinAmount, newMinAmount);
    }

    /// @notice Sets the address of the trusted insight evaluation oracle. Callable only via governance.
    /// @param newOracle The new oracle address.
    function setInsightOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Invalid oracle address");
        address oldOracle = insightEvaluationOracle;
        insightEvaluationOracle = newOracle;
        // Convert addresses to uint256 for event logging as addresses cannot be indexed as data type in event
        emit ProtocolParameterUpdated("insightOracle", uint256(uint160(oldOracle)), uint256(uint160(newOracle)));
    }

    // --- ERC721 Overrides for Non-Transferable NFTs (SBT-like) ---
    // The SynergyNode NFTs are designed to be non-transferable and tied to a user's reputation.
    // Therefore, transfer functions are overridden to revert.
    function _approve(address to, uint256 tokenId) internal override {
        revert("SynergyNode NFTs are non-transferable");
    }

    function _transfer(address from, address to, uint256 tokenId) internal override {
        revert("SynergyNode NFTs are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("SynergyNode NFTs are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SynergyNode NFTs are non-transferable");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SynergyNode NFTs are non-transferable");
    }

    // --- Fallback Function ---
    /// @notice Any direct ETH sent to the contract without calling a specific function will be treated as a treasury deposit.
    receive() external payable {
        depositToTreasury();
    }
}
```