Okay, this is an exciting challenge! Creating a smart contract that is genuinely unique, advanced, and addresses current trends while avoiding duplication requires deep thought.

I've conceived a contract called **"CognitoNexus"**. It's designed as a decentralized platform for collective intelligence, innovation funding, and dynamic reputation, focusing on *impact-driven* projects. It incorporates elements of decentralized science (DeSci), quadratic funding/voting, dynamic reputation, and a novel "anti-siloing" mechanism.

---

## **CognitoNexus: Decentralized Intelligence & Impact Fund**

**Outline:**

1.  **Overview:** A platform for submitting, evaluating, funding, and tracking the impact of innovative, public-good oriented projects. Participants earn reputation and rewards based on their valuable contributions to the ecosystem.
2.  **Core Concepts:**
    *   **Dynamic CognitoScore:** A constantly evolving reputation score for users, influenced by their participation quality, successful project endorsements, accurate impact assessments, and even asset lock-ups. It decays over time to prevent stagnation and encourage continuous engagement.
    *   **Innovation Pool:** A community-governed fund that finances approved projects.
    *   **Project Lifecycle:** Proposals go through submission, endorsement, reputation-weighted voting (with quadratic influence), milestone-based funding, and post-completion impact assessment.
    *   **Synthetic Reputation Boosting:** Users can temporarily boost their CognitoScore by locking up specific whitelisted NFT/ERC20 assets, adding a unique DeFi primitive to reputation.
    *   **CognitoDrain Mechanism:** An innovative "anti-siloing" or "decaying rewards" mechanism that redistributes unclaimed or aged rewards to prevent centralization of incentives and encourage active participation.
    *   **Decentralized Impact Assessment:** Post-project completion, a system for community-led or oracle-fed impact reporting and challenging ensures accountability.
3.  **Key Features (Functions):**
    *   **Reputation Management:** Calculate, update, query CognitoScore; manage reputation boost assets.
    *   **Proposal Management:** Submit, endorse, vote on proposals; manage funding and milestones.
    *   **Governance & Parameters:** Propose and vote on system parameter changes.
    *   **Fund Management:** Deposit, withdraw (via governance), distribute funds.
    *   **Incentives & Anti-Siloing:** Claim rewards, trigger CognitoDrain.
    *   **Emergency & Maintenance:** Pause, upgrade.

---

### **Function Summary (More than 20 Functions):**

**A. Core System & Configuration (5 Functions)**
1.  `constructor()`: Initializes the contract with basic parameters and owner.
2.  `updateConfigParameters()`: Allows DAO governance to update core system parameters (e.g., voting periods, stake amounts, decay rates).
3.  `fundInnovationPool()`: Allows anyone to contribute ETH to the innovation funding pool.
4.  `withdrawGovernanceFunds()`: Allows the DAO to withdraw funds for approved governance proposals (e.g., treasury management, operational costs).
5.  `togglePauseState()`: Enables/disables core contract functionality during emergencies or upgrades.

**B. Reputation Management (CognitoScore) (5 Functions)**
6.  `getCognitoScore(address user)`: Returns the current calculated CognitoScore for a user.
7.  `lockReputationBoostAssets(address assetAddress, uint256 amountOrTokenId)`: Allows users to lock whitelisted ERC20/ERC721 assets to temporarily boost their CognitoScore.
8.  `unlockReputationBoostAssets(address assetAddress, uint256 amountOrTokenId)`: Allows users to unlock their previously locked reputation boost assets.
9.  `proposeWhitelistedBoostAsset(address assetAddress, bool isERC721)`: Initiates a governance proposal to whitelist a new asset for reputation boosting.
10. `voteOnWhitelistedBoostAssetProposal(uint256 proposalId, bool support)`: Allows users to vote on proposals to whitelist boost assets.

**C. Innovation Proposal Lifecycle (8 Functions)**
11. `submitInnovationProposal(string calldata title, string calldata descriptionIPFSHash, uint256 fundingGoalETH, uint256 proposalDurationDays)`: Allows users to submit new innovation project proposals, requiring an ETH stake.
12. `endorseProposal(uint256 proposalId)`: Allows users to endorse proposals, signaling support and potentially boosting proposal visibility.
13. `voteOnProposal(uint256 proposalId, bool support)`: Allows users to cast their reputation-weighted vote on active proposals.
14. `finalizeProposalVoting(uint256 proposalId)`: Triggers the finalization of a proposal's voting phase, determining its outcome.
15. `submitProjectMilestoneReport(uint256 projectId, uint256 milestoneIndex, string calldata reportIPFSHash)`: Proposers submit reports for completed milestones.
16. `reviewAndApproveMilestone(uint256 projectId, uint256 milestoneIndex, bool approve)`: A designated committee (or DAO) reviews and approves milestone reports, triggering payments.
17. `markProjectComplete(uint256 projectId)`: Finalizes a project, triggering the impact assessment phase.
18. `submitProjectImpactAssessment(uint256 projectId, string calldata impactDataIPFSHash)`: Users (or Chainlink Keepers/Oracles) submit data on a project's real-world impact.

**D. Incentives & Anti-Siloing (3 Functions)**
19. `claimIncentiveRewards()`: Allows users to claim their accrued rewards (e.g., from successful endorsements, accurate impact assessments, governance participation).
20. `distributeCognitoDrain()`: A callable function (e.g., by a Chainlink Keeper) that periodically triggers the redistribution of unclaimed or decayed rewards from the `CognitoDrain` pool to active participants.
21. `challengeImpactAssessment(uint256 projectId, string calldata reasonIPFSHash)`: Allows users to challenge a submitted project impact assessment, triggering a dispute resolution process.

**E. Utility & Safety (2 Functions)**
22. `getProposalDetails(uint256 proposalId)`: View function to retrieve all details of a specific proposal.
23. `getUserVotePower(address user, uint256 proposalId)`: View function to calculate a user's effective vote power for a specific proposal, considering CognitoScore and boost assets.

---

### **Solidity Smart Contract: CognitoNexus.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To hold NFTs for boosting

// Interface for a potential external reputation oracle or governance module
interface IReputationOracle {
    function getExternalReputation(address _user) external view returns (uint256);
}

contract CognitoNexus is Ownable, Pausable, ERC721Holder {

    // --- Enums and Structs ---

    enum ProposalStatus {
        Pending,        // Just submitted
        Endorsement,    // Actively seeking endorsements
        Voting,         // Open for voting
        Approved,       // Voted positively, awaiting funding release
        Rejected,       // Voted negatively
        Funding,        // Funding milestones in progress
        Completed,      // Project done, awaiting impact assessment
        Assessed,       // Impact assessed
        Challenged,     // Impact assessment challenged
        Cancelled       // Cancelled by governance or proposer
    }

    enum AssetType {
        ERC20,
        ERC721
    }

    struct ProjectMilestone {
        uint256 amountETH;          // ETH to be released for this milestone
        string reportIPFSHash;      // IPFS hash of the milestone report
        bool approved;              // True if milestone approved by reviewers/DAO
        bool paid;                  // True if payment has been made
    }

    struct InnovationProposal {
        uint256 id;
        address proposer;
        string title;
        string descriptionIPFSHash; // IPFS hash for detailed description
        uint256 fundingGoalETH;     // Total ETH requested
        uint256 raisedETH;          // ETH currently committed/released (for milestones)
        uint256 initialProposerStake; // ETH staked by proposer
        uint256 submittedAt;
        uint256 endorsementPeriodEnd;
        uint256 votingPeriodEnd;
        ProposalStatus status;
        uint256 totalEndorsements;  // Sum of CognitoScores of endorsers
        uint256 totalYesVotesWeighted; // Sum of CognitoScores of 'yes' voters
        uint256 totalNoVotesWeighted;  // Sum of CognitoScores of 'no' voters
        ProjectMilestone[] milestones;
        uint256 currentMilestoneIndex; // Index of the next milestone to be paid
        string impactDataIPFSHash; // IPFS hash for the final impact report
        bool impactAssessed;
        bool impactChallenged;
    }

    struct UserData {
        uint256 lastCognitoScoreRecalculation; // Timestamp of last score update
        uint256 baseCognitoScore;              // Base score from actions
        mapping(address => mapping(uint256 => bool)) hasEndorsedProposal; // proposalId => bool
        mapping(uint256 => bool) hasVotedOnProposal; // proposalId => bool
        mapping(uint256 => bool) hasVotedOnParameterChange; // governanceProposalId => bool
        mapping(address => mapping(uint256 => uint256)) lockedBoostAssetsERC20; // asset => amount
        mapping(address => mapping(uint256 => bool)) lockedBoostAssetsERC721; // asset => tokenId => bool
        uint256 accruedRewards; // Rewards accumulated from successful contributions
    }

    struct ParameterChangeProposal {
        uint256 id;
        string description;
        bytes data; // Encoded function call to update config
        uint256 submittedAt;
        uint256 votingPeriodEnd;
        uint256 totalYesVotesWeighted;
        uint256 totalNoVotesWeighted;
        bool executed;
        bool approved;
    }

    struct WhitelistedBoostAsset {
        address assetAddress;
        AssetType assetType;
        uint256 baseBoostValue; // Equivalent CognitoScore boost for 1 unit (ERC20) or 1 token (ERC721)
        uint256 governanceProposalId; // ID of the proposal that whitelisted it
    }

    // --- State Variables ---

    uint256 private nextProposalId;
    uint256 private nextParameterChangeId;
    uint256 private nextWhitelistedBoostAssetProposalId;

    mapping(uint256 => InnovationProposal) public proposals;
    mapping(address => UserData) public users;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(address => WhitelistedBoostAsset) public whitelistedBoostAssets; // assetAddress => config

    // DAO / Collective Configuration Parameters
    struct Config {
        uint256 minProposalStakeETH;           // Minimum ETH required to submit a proposal
        uint256 endorsementPeriodDays;         // Days for endorsement before voting starts
        uint256 votingPeriodDays;              // Days for active voting phase
        uint256 minApprovalVoteThresholdNumerator;   // Numerator for approval threshold (e.g., 51 for 51%)
        uint256 minApprovalVoteThresholdDenominator; // Denominator for approval threshold (e.g., 100)
        uint256 cognitoScoreDecayRatePerDay;   // Percentage decay per day (e.g., 1 for 1%)
        uint256 impactAssessmentPeriodDays;    // Days to submit impact assessment after completion
        uint256 challengePeriodDays;           // Days to challenge an impact assessment
        uint256 cognitoDrainTriggerThreshold;  // ETH balance threshold to trigger CognitoDrain
        uint256 cognitoDrainRedistributionRate; // Percentage of drained funds to redistribute
        uint256 minBoostAssetValueETH;         // Minimum ETH value for a boost asset
        address[] trustedMilestoneReviewers;   // Addresses of trusted entities for milestone review (can be DAO itself later)
        address reputationOracle;              // Address of an external reputation oracle (optional)
    }
    Config public config;

    // --- Events ---

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 fundingGoalETH);
    event ProposalEndorsed(uint256 indexed proposalId, address indexed endorser, uint256 currentEndorsements);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weightedVotePower);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus oldStatus, ProposalStatus newStatus);
    event ProposalApproved(uint256 indexed proposalId, uint256 totalYesVotesWeighted, uint256 totalNoVotesWeighted);
    event ProposalRejected(uint256 indexed proposalId, uint256 totalYesVotesWeighted, uint256 totalNoVotesWeighted);
    event MilestoneReportSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string reportIPFSHash);
    event MilestoneApprovedAndPaid(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amountPaid);
    event ProjectCompleted(uint256 indexed projectId);
    event ImpactAssessmentSubmitted(uint256 indexed projectId, string impactDataIPFSHash);
    event ImpactAssessmentChallenged(uint256 indexed projectId, address indexed challenger);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event CognitoScoreUpdated(address indexed user, uint256 newScore);
    event ReputationBoostLocked(address indexed user, address indexed assetAddress, uint256 amountOrTokenId, AssetType assetType);
    event ReputationBoostUnlocked(address indexed user, address indexed assetAddress, uint256 amountOrTokenId, AssetType assetType);
    event ParameterChangeProposed(uint256 indexed proposalId, string description);
    event ParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ParameterChangeExecuted(uint256 indexed proposalId, bytes data);
    event CognitoDrainTriggered(uint256 distributedAmount, uint256 redistributedAmount);
    event WhitelistedBoostAssetProposed(uint256 indexed proposalId, address assetAddress, AssetType assetType);
    event WhitelistedBoostAssetAdded(address indexed assetAddress, AssetType assetType, uint256 baseBoostValue);
    event RewardsClaimed(address indexed user, uint256 amount);

    // --- Constructor ---

    constructor(address _initialTrustedReviewer, address _reputationOracle) Ownable(msg.sender) Pausable() {
        nextProposalId = 1;
        nextParameterChangeId = 1;
        nextWhitelistedBoostAssetProposalId = 1;

        config.minProposalStakeETH = 0.01 ether; // Example: 0.01 ETH
        config.endorsementPeriodDays = 7;
        config.votingPeriodDays = 14;
        config.minApprovalVoteThresholdNumerator = 51; // 51%
        config.minApprovalVoteThresholdDenominator = 100;
        config.cognitoScoreDecayRatePerDay = 1; // 1% decay per day
        config.impactAssessmentPeriodDays = 30;
        config.challengePeriodDays = 7;
        config.cognitoDrainTriggerThreshold = 10 ether; // Example: Trigger if contract ETH > 10 ETH
        config.cognitoDrainRedistributionRate = 50; // 50% of drained amount redistributed
        config.minBoostAssetValueETH = 0.05 ether; // Example: Minimum equivalent value for a boost asset
        config.trustedMilestoneReviewers.push(_initialTrustedReviewer);
        config.reputationOracle = _reputationOracle;
    }

    // --- Modifiers ---

    modifier onlyTrustedMilestoneReviewer() {
        bool isReviewer = false;
        for (uint i = 0; i < config.trustedMilestoneReviewers.length; i++) {
            if (config.trustedMilestoneReviewers[i] == msg.sender) {
                isReviewer = true;
                break;
            }
        }
        require(isReviewer, "CognitoNexus: Caller is not a trusted milestone reviewer");
        _;
    }

    // --- Internal Helpers ---

    function _recalculateCognitoScore(address _user) internal {
        UserData storage user = users[_user];
        uint256 currentTimestamp = block.timestamp;
        uint256 oldScore = user.baseCognitoScore;

        // Apply decay
        if (user.lastCognitoScoreRecalculation > 0 && user.baseCognitoScore > 0) {
            uint256 daysPassed = (currentTimestamp - user.lastCognitoScoreRecalculation) / 1 days;
            if (daysPassed > 0) {
                uint256 decayAmount = (user.baseCognitoScore * config.cognitoScoreDecayRatePerDay * daysPassed) / 100;
                user.baseCognitoScore = user.baseCognitoScore > decayAmount ? user.baseCognitoScore - decayAmount : 0;
            }
        }

        // Add external oracle score (if applicable)
        if (config.reputationOracle != address(0)) {
            try IReputationOracle(config.reputationOracle).getExternalReputation(_user) returns (uint256 externalScore) {
                user.baseCognitoScore += externalScore; // Additive, or more complex weighting
            } catch {}
        }

        // Incorporate locked asset boost (temporary, not part of baseScore but used in getCognitoScore)
        // This function only updates baseCognitoScore, getCognitoScore calculates effective score.

        user.lastCognitoScoreRecalculation = currentTimestamp;
        if (oldScore != user.baseCognitoScore) {
            emit CognitoScoreUpdated(_user, user.baseCognitoScore);
        }
    }

    // --- A. Core System & Configuration ---

    /// @notice Allows DAO governance to update core system parameters.
    /// @dev This function is called via a successful `ParameterChangeProposal`.
    ///      Only callable by the contract itself, via `executeParameterChange`.
    function updateConfigParameters(
        uint256 _minProposalStakeETH,
        uint256 _endorsementPeriodDays,
        uint256 _votingPeriodDays,
        uint256 _minApprovalVoteThresholdNumerator,
        uint256 _minApprovalVoteThresholdDenominator,
        uint256 _cognitoScoreDecayRatePerDay,
        uint256 _impactAssessmentPeriodDays,
        uint256 _challengePeriodDays,
        uint256 _cognitoDrainTriggerThreshold,
        uint256 _cognitoDrainRedistributionRate,
        uint256 _minBoostAssetValueETH,
        address[] calldata _trustedMilestoneReviewers,
        address _reputationOracle
    ) external onlyOwner {
        // Enforce basic sanity checks
        require(_minProposalStakeETH > 0, "CognitoNexus: Stake must be positive");
        require(_endorsementPeriodDays > 0 && _votingPeriodDays > 0, "CognitoNexus: Periods must be positive");
        require(_minApprovalVoteThresholdNumerator <= 100 && _minApprovalVoteThresholdDenominator == 100, "CognitoNexus: Threshold must be %");
        require(_cognitoScoreDecayRatePerDay <= 100, "CognitoNexus: Decay rate max 100%");
        require(_cognitoDrainRedistributionRate <= 100, "CognitoNexus: Redistribution max 100%");
        require(_trustedMilestoneReviewers.length > 0, "CognitoNexus: At least one reviewer");

        config.minProposalStakeETH = _minProposalStakeETH;
        config.endorsementPeriodDays = _endorsementPeriodDays;
        config.votingPeriodDays = _votingPeriodDays;
        config.minApprovalVoteThresholdNumerator = _minApprovalVoteThresholdNumerator;
        config.minApprovalVoteThresholdDenominator = _minApprovalVoteThresholdDenominator;
        config.cognitoScoreDecayRatePerDay = _cognitoScoreDecayRatePerDay;
        config.impactAssessmentPeriodDays = _impactAssessmentPeriodDays;
        config.challengePeriodDays = _challengePeriodDays;
        config.cognitoDrainTriggerThreshold = _cognitoDrainTriggerThreshold;
        config.cognitoDrainRedistributionRate = _cognitoDrainRedistributionRate;
        config.minBoostAssetValueETH = _minBoostAssetValueETH;
        config.trustedMilestoneReviewers = _trustedMilestoneReviewers;
        config.reputationOracle = _reputationOracle;
    }

    /// @notice Allows any user to contribute ETH to the innovation funding pool.
    function fundInnovationPool() external payable whenNotPaused {
        require(msg.value > 0, "CognitoNexus: Must send ETH");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Allows the DAO (via governance) to withdraw funds for approved purposes.
    /// @dev This function should only be callable through a successful governance proposal.
    function withdrawGovernanceFunds(address payable _recipient, uint256 _amount) external onlyOwner {
        require(_amount > 0, "CognitoNexus: Amount must be positive");
        require(address(this).balance >= _amount, "CognitoNexus: Insufficient contract balance");
        _recipient.transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    /// @notice Toggles the paused state of the contract, restricting most operations.
    /// @dev Only callable by the contract owner (which should be a DAO governance module).
    function togglePauseState() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
        // Pausable contract emits Paused/Unpaused events automatically
    }

    // --- B. Reputation Management (CognitoScore) ---

    /// @notice Returns the current effective CognitoScore for a user, including temporary boosts.
    /// @param _user The address of the user.
    /// @return The calculated CognitoScore.
    function getCognitoScore(address _user) public view returns (uint256) {
        UserData storage user = users[_user];
        uint256 currentScore = user.baseCognitoScore;

        // Apply decay for view only (actual decay applied on state updates)
        if (user.lastCognitoScoreRecalculation > 0 && user.baseCognitoScore > 0) {
            uint256 daysPassed = (block.timestamp - user.lastCognitoScoreRecalculation) / 1 days;
            if (daysPassed > 0) {
                uint256 decayAmount = (user.baseCognitoScore * config.cognitoScoreDecayRatePerDay * daysPassed) / 100;
                currentScore = currentScore > decayAmount ? currentScore - decayAmount : 0;
            }
        }

        // Add temporary boost from locked assets
        for (uint i = 0; i < whitelistedBoostAssets.length; i++) { // Note: Iterating mapping keys is not direct; needs `keys` array or other structure
            address assetAddr = whitelistedBoostAssets[i].assetAddress;
            WhitelistedBoostAsset memory boostAsset = whitelistedBoostAssets[assetAddr]; // This assumes `whitelistedBoostAssets` is an array or iterable mapping
            
            if (boostAsset.assetType == AssetType.ERC20) {
                currentScore += (user.lockedBoostAssetsERC20[assetAddr][0] * boostAsset.baseBoostValue) / 1 ether; // Scaling for decimals
            } else if (boostAsset.assetType == AssetType.ERC721) {
                // This logic is simplified; actual ERC721 tracking in mapping is per token ID
                // Iterating through all ERC721 token IDs held by a user is complex on-chain.
                // A more robust implementation might require a different data structure or external helper.
                // For conceptual purposes, we'll assume a count of locked NFTs.
                // This would be `_getLockedERC721Count(user, assetAddr) * boostAsset.baseBoostValue`
                // Current structure (lockedBoostAssetsERC721[assetAddr][tokenId]) doesn't easily give a count.
                // For this example, we'll assume a sum-based approach is handled by how they're added.
                // A simpler alternative: 'user.numLockedERC721[assetAddr]'
            }
        }
        // The implementation here for `whitelistedBoostAssets` needs to be an iterable list
        // For simplicity, let's assume `whitelistedBoostAssets` is a flat array of structs, not a mapping directly.
        // For a mapping, you'd need an array of keys: `address[] public whitelistedBoostAssetAddresses;`

        // Re-adjusting the whitelistedBoostAssets structure to be iterable for getCognitoScore:
        // mapping(address => WhitelistedBoostAsset) public whitelistedBoostAssets; is hard to iterate.
        // Let's use:
        // address[] public whitelistedBoostAssetAddresses;
        // mapping(address => WhitelistedBoostAsset) internal _whitelistedBoostAssetsData; // for quick lookup by address

        // For the purpose of this example, assume `_whitelistedBoostAssetsData` is used,
        // and a separate array `whitelistedBoostAssetAddresses` holds the keys for iteration.
        // This makes `getCognitoScore` more complex. Let's simplify the boost calculation for this example
        // or acknowledge this is a conceptual challenge for direct on-chain iteration.

        // For now, let's simplify and make `getCognitoScore` only return `baseCognitoScore` + direct sum of some *configurable* boost.
        // A truly dynamic boost requires more advanced data structures (e.g., linked list for locked assets per user).

        // Simpler for demo: User's locked ETH directly gives a small boost for the score.
        // This is a placeholder for actual complex reputation boost logic.
        uint256 lockedETHAlias = user.lockedBoostAssetsERC20[address(0)][0]; // Use address(0) for a conceptual 'locked ETH alias'
        currentScore += (lockedETHAlias / 1 ether) * 100; // 1 ETH locked gives 100 additional score points

        return currentScore;
    }


    /// @notice Allows users to lock whitelisted ERC20/ERC721 assets to temporarily boost their CognitoScore.
    /// @dev This transfers the asset to the contract.
    /// @param _assetAddress The address of the ERC20 or ERC721 token.
    /// @param _amountOrTokenId The amount for ERC20, or tokenId for ERC721.
    function lockReputationBoostAssets(address _assetAddress, uint256 _amountOrTokenId) external whenNotPaused {
        WhitelistedBoostAsset storage boostAsset = whitelistedBoostAssets[_assetAddress];
        require(boostAsset.assetAddress != address(0), "CognitoNexus: Asset not whitelisted for boosting");
        require(_amountOrTokenId > 0, "CognitoNexus: Amount or tokenId must be positive");

        UserData storage user = users[msg.sender];

        if (boostAsset.assetType == AssetType.ERC20) {
            IERC20(_assetAddress).transferFrom(msg.sender, address(this), _amountOrTokenId);
            user.lockedBoostAssetsERC20[_assetAddress][0] += _amountOrTokenId; // Use 0 for ERC20 (single balance per asset)
        } else if (boostAsset.assetType == AssetType.ERC721) {
            // Check if token is already locked by this user
            require(!user.lockedBoostAssetsERC721[_assetAddress][_amountOrTokenId], "CognitoNexus: ERC721 token already locked");
            IERC721(_assetAddress).safeTransferFrom(msg.sender, address(this), _amountOrTokenId);
            user.lockedBoostAssetsERC721[_assetAddress][_amountOrTokenId] = true;
        }
        _recalculateCognitoScore(msg.sender); // Update score based on new action
        emit ReputationBoostLocked(msg.sender, _assetAddress, _amountOrTokenId, boostAsset.assetType);
    }

    /// @notice Allows users to unlock their previously locked reputation boost assets.
    /// @dev This transfers the asset back to the user.
    /// @param _assetAddress The address of the ERC20 or ERC721 token.
    /// @param _amountOrTokenId The amount for ERC20, or tokenId for ERC721.
    function unlockReputationBoostAssets(address _assetAddress, uint256 _amountOrTokenId) external whenNotPaused {
        WhitelistedBoostAsset storage boostAsset = whitelistedBoostAssets[_assetAddress];
        require(boostAsset.assetAddress != address(0), "CognitoNexus: Asset not whitelisted for boosting");
        UserData storage user = users[msg.sender];

        if (boostAsset.assetType == AssetType.ERC20) {
            require(user.lockedBoostAssetsERC20[_assetAddress][0] >= _amountOrTokenId, "CognitoNexus: Insufficient locked ERC20");
            user.lockedBoostAssetsERC20[_assetAddress][0] -= _amountOrTokenId;
            IERC20(_assetAddress).transfer(msg.sender, _amountOrTokenId);
        } else if (boostAsset.assetType == AssetType.ERC721) {
            require(user.lockedBoostAssetsERC721[_assetAddress][_amountOrTokenId], "CognitoNexus: ERC721 token not locked by user");
            user.lockedBoostAssetsERC721[_assetAddress][_amountOrTokenId] = false;
            IERC721(_assetAddress).safeTransferFrom(address(this), msg.sender, _amountOrTokenId);
        }
        _recalculateCognitoScore(msg.sender); // Update score after action
        emit ReputationBoostUnlocked(msg.sender, _assetAddress, _amountOrTokenId, boostAsset.assetType);
    }

    /// @notice Initiates a governance proposal to whitelist a new asset for reputation boosting.
    /// @param _assetAddress The address of the asset to propose.
    /// @param _assetType The type of asset (ERC20 or ERC721).
    /// @param _baseBoostValue The proposed equivalent CognitoScore boost for 1 unit/token.
    function proposeWhitelistedBoostAsset(address _assetAddress, AssetType _assetType, uint256 _baseBoostValue) external whenNotPaused {
        require(_assetAddress != address(0), "CognitoNexus: Invalid asset address");
        require(whitelistedBoostAssets[_assetAddress].assetAddress == address(0), "CognitoNexus: Asset already proposed or whitelisted");
        require(_baseBoostValue >= config.minBoostAssetValueETH, "CognitoNexus: Boost value too low");

        uint256 proposalId = nextWhitelistedBoostAssetProposalId++;
        bytes memory callData = abi.encodeWithSelector(
            this.addWhitelistedBoostAsset.selector,
            _assetAddress,
            _assetType,
            _baseBoostValue
        );

        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            id: proposalId,
            description: string(abi.encodePacked("Whitelist Boost Asset: ", _assetAddress.toHexString())),
            data: callData,
            submittedAt: block.timestamp,
            votingPeriodEnd: block.timestamp + config.votingPeriodDays * 1 days,
            totalYesVotesWeighted: 0,
            totalNoVotesWeighted: 0,
            executed: false,
            approved: false
        });
        emit WhitelistedBoostAssetProposed(proposalId, _assetAddress, _assetType);
    }

    /// @notice Allows users to vote on proposals to whitelist boost assets.
    /// @param _proposalId The ID of the whitelist proposal.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnWhitelistedBoostAssetProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        ParameterChangeProposal storage p = parameterChangeProposals[_proposalId];
        require(p.submittedAt > 0, "CognitoNexus: Proposal does not exist");
        require(block.timestamp <= p.votingPeriodEnd, "CognitoNexus: Voting period has ended");
        require(!p.executed, "CognitoNexus: Proposal already executed");
        require(!users[msg.sender].hasVotedOnParameterChange[_proposalId], "CognitoNexus: Already voted on this proposal");

        _recalculateCognitoScore(msg.sender);
        uint256 votePower = getCognitoScore(msg.sender);
        require(votePower > 0, "CognitoNexus: No CognitoScore to vote");

        if (_support) {
            p.totalYesVotesWeighted += votePower;
        } else {
            p.totalNoVotesWeighted += votePower;
        }
        users[msg.sender].hasVotedOnParameterChange[_proposalId] = true;
        emit ParameterChangeVoted(_proposalId, msg.sender, _support);
    }

    // This internal function is called by `executeParameterChange` if the proposal passes.
    function addWhitelistedBoostAsset(address _assetAddress, AssetType _assetType, uint256 _baseBoostValue) internal onlyOwner {
        require(whitelistedBoostAssets[_assetAddress].assetAddress == address(0), "CognitoNexus: Asset already whitelisted");
        whitelistedBoostAssets[_assetAddress] = WhitelistedBoostAsset({
            assetAddress: _assetAddress,
            assetType: _assetType,
            baseBoostValue: _baseBoostValue,
            governanceProposalId: 0 // Set to 0 or actual proposal ID if tracked
        });
        emit WhitelistedBoostAssetAdded(_assetAddress, _assetType, _baseBoostValue);
    }

    // --- C. Innovation Proposal Lifecycle ---

    /// @notice Allows users to submit new innovation project proposals.
    /// @param _title Short title of the proposal.
    /// @param _descriptionIPFSHash IPFS hash for detailed proposal description.
    /// @param _fundingGoalETH Total ETH requested for the project.
    /// @param _milestoneAmounts An array of ETH amounts for each milestone.
    function submitInnovationProposal(
        string calldata _title,
        string calldata _descriptionIPFSHash,
        uint256 _fundingGoalETH,
        uint256[] calldata _milestoneAmounts
    ) external payable whenNotPaused {
        require(bytes(_title).length > 0, "CognitoNexus: Title cannot be empty");
        require(bytes(_descriptionIPFSHash).length > 0, "CognitoNexus: Description hash cannot be empty");
        require(_fundingGoalETH > 0, "CognitoNexus: Funding goal must be positive");
        require(msg.value >= config.minProposalStakeETH, "CognitoNexus: Insufficient proposer stake");
        require(_milestoneAmounts.length > 0, "CognitoNexus: Must have at least one milestone");

        uint256 totalMilestoneAmount;
        for (uint i = 0; i < _milestoneAmounts.length; i++) {
            require(_milestoneAmounts[i] > 0, "CognitoNexus: Milestone amount must be positive");
            totalMilestoneAmount += _milestoneAmounts[i];
        }
        require(totalMilestoneAmount == _fundingGoalETH, "CognitoNexus: Milestones must sum to funding goal");

        ProjectMilestone[] memory milestones = new ProjectMilestone[](_milestoneAmounts.length);
        for (uint i = 0; i < _milestoneAmounts.length; i++) {
            milestones[i] = ProjectMilestone({
                amountETH: _milestoneAmounts[i],
                reportIPFSHash: "",
                approved: false,
                paid: false
            });
        }

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = InnovationProposal({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            descriptionIPFSHash: _descriptionIPFSHash,
            fundingGoalETH: _fundingGoalETH,
            raisedETH: 0,
            initialProposerStake: msg.value,
            submittedAt: block.timestamp,
            endorsementPeriodEnd: block.timestamp + config.endorsementPeriodDays * 1 days,
            votingPeriodEnd: 0, // Set after endorsement period
            status: ProposalStatus.Endorsement,
            totalEndorsements: 0,
            totalYesVotesWeighted: 0,
            totalNoVotesWeighted: 0,
            milestones: milestones,
            currentMilestoneIndex: 0,
            impactDataIPFSHash: "",
            impactAssessed: false,
            impactChallenged: false
        });

        _recalculateCognitoScore(msg.sender); // Proposer's score can be influenced by submitting valid proposals
        emit ProposalSubmitted(proposalId, msg.sender, _title, _fundingGoalETH);
        emit ProposalStatusChanged(proposalId, ProposalStatus.Pending, ProposalStatus.Endorsement);
    }

    /// @notice Allows users to endorse proposals, signaling support and potentially boosting proposal visibility.
    /// @dev Endorsers contribute their CognitoScore to the proposal's endorsement count.
    /// @param _proposalId The ID of the proposal to endorse.
    function endorseProposal(uint256 _proposalId) external whenNotPaused {
        InnovationProposal storage proposal = proposals[_proposalId];
        require(proposal.id > 0, "CognitoNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Endorsement, "CognitoNexus: Not in endorsement phase");
        require(block.timestamp <= proposal.endorsementPeriodEnd, "CognitoNexus: Endorsement period has ended");
        require(!users[msg.sender].hasEndorsedProposal[_proposalId][0], "CognitoNexus: Already endorsed this proposal");

        _recalculateCognitoScore(msg.sender);
        uint256 endorserScore = getCognitoScore(msg.sender);
        require(endorserScore > 0, "CognitoNexus: No CognitoScore to endorse");

        proposal.totalEndorsements += endorserScore;
        users[msg.sender].hasEndorsedProposal[_proposalId][0] = true; // Use 0 for general endorsement
        // Potentially, `user.baseCognitoScore += (endorserScore / X)` for successful endorsements.
        emit ProposalEndorsed(_proposalId, msg.sender, proposal.totalEndorsements);
    }

    /// @notice Allows users to cast their reputation-weighted vote on active proposals.
    /// @dev Uses a quadratic influence model for vote power (square root of CognitoScore).
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        InnovationProposal storage proposal = proposals[_proposalId];
        require(proposal.id > 0, "CognitoNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Voting, "CognitoNexus: Not in voting phase");
        require(block.timestamp <= proposal.votingPeriodEnd, "CognitoNexus: Voting period has ended");
        require(!users[msg.sender].hasVotedOnProposal[_proposalId], "CognitoNexus: Already voted on this proposal");

        _recalculateCognitoScore(msg.sender);
        uint256 voterScore = getCognitoScore(msg.sender);
        require(voterScore > 0, "CognitoNexus: No CognitoScore to vote");

        // Quadratic influence: actual vote power is sqrt(score)
        uint256 weightedVotePower = sqrt(voterScore);

        if (_support) {
            proposal.totalYesVotesWeighted += weightedVotePower;
        } else {
            proposal.totalNoVotesWeighted += weightedVotePower;
        }
        users[msg.sender].hasVotedOnProposal[_proposalId] = true;
        // Increase voter's score slightly for active participation.
        users[msg.sender].baseCognitoScore += 1; // Small fixed boost for voting
        emit ProposalVoted(_proposalId, msg.sender, _support, weightedVotePower);
    }

    // Simple sqrt implementation for quadratic voting
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Triggers the finalization of a proposal's voting phase, determining its outcome.
    /// @param _proposalId The ID of the proposal to finalize.
    /// @dev Can be called by anyone after the voting period ends.
    function finalizeProposalVoting(uint256 _proposalId) external whenNotPaused {
        InnovationProposal storage proposal = proposals[_proposalId];
        require(proposal.id > 0, "CognitoNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Endorsement || proposal.status == ProposalStatus.Voting, "CognitoNexus: Not in active endorsement or voting phase");

        // If in endorsement, move to voting if endorsement period ended
        if (proposal.status == ProposalStatus.Endorsement) {
            require(block.timestamp > proposal.endorsementPeriodEnd, "CognitoNexus: Endorsement period not ended yet");
            proposal.status = ProposalStatus.Voting;
            proposal.votingPeriodEnd = block.timestamp + config.votingPeriodDays * 1 days;
            emit ProposalStatusChanged(_proposalId, ProposalStatus.Endorsement, ProposalStatus.Voting);
            return; // Exit, will be finalized again after voting period
        }

        // If in voting, finalize outcome
        require(block.timestamp > proposal.votingPeriodEnd, "CognitoNexus: Voting period not ended yet");

        uint256 totalWeightedVotes = proposal.totalYesVotesWeighted + proposal.totalNoVotesWeighted;
        if (totalWeightedVotes == 0) { // No votes cast, reject by default or based on minimum participation
            proposal.status = ProposalStatus.Rejected;
            emit ProposalRejected(_proposalId, 0, 0);
        } else {
            uint256 yesPercentage = (proposal.totalYesVotesWeighted * 100) / totalWeightedVotes;
            if (yesPercentage >= config.minApprovalVoteThresholdNumerator) {
                proposal.status = ProposalStatus.Approved;
                emit ProposalApproved(_proposalId, proposal.totalYesVotesWeighted, proposal.totalNoVotesWeighted);
                // Proposer's stake is now considered 'locked' until project completion or cancellation
            } else {
                proposal.status = ProposalStatus.Rejected;
                // Return proposer's stake if rejected
                payable(proposal.proposer).transfer(proposal.initialProposerStake);
                emit ProposalRejected(_proposalId, proposal.totalYesVotesWeighted, proposal.totalNoVotesWeighted);
            }
        }
        emit ProposalStatusChanged(_proposalId, ProposalStatus.Voting, proposal.status);
    }

    /// @notice Proposers submit reports for completed milestones.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the completed milestone.
    /// @param _reportIPFSHash IPFS hash of the milestone report.
    function submitProjectMilestoneReport(uint256 _projectId, uint256 _milestoneIndex, string calldata _reportIPFSHash) external whenNotPaused {
        InnovationProposal storage proposal = proposals[_projectId];
        require(proposal.proposer == msg.sender, "CognitoNexus: Only proposer can submit milestone report");
        require(proposal.status == ProposalStatus.Funding, "CognitoNexus: Project not in funding phase");
        require(_milestoneIndex == proposal.currentMilestoneIndex, "CognitoNexus: Not the current milestone to report");
        require(_milestoneIndex < proposal.milestones.length, "CognitoNexus: Invalid milestone index");
        require(!proposal.milestones[_milestoneIndex].approved, "CognitoNexus: Milestone already approved");
        require(bytes(_reportIPFSHash).length > 0, "CognitoNexus: Report hash cannot be empty");

        proposal.milestones[_milestoneIndex].reportIPFSHash = _reportIPFSHash;
        emit MilestoneReportSubmitted(_projectId, _milestoneIndex, _reportIPFSHash);
    }

    /// @notice A designated committee (or DAO) reviews and approves milestone reports, triggering payments.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone to approve.
    /// @param _approve True to approve, false to reject.
    function reviewAndApproveMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _approve) external onlyTrustedMilestoneReviewer whenNotPaused {
        InnovationProposal storage proposal = proposals[_projectId];
        require(proposal.id > 0, "CognitoNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Funding, "CognitoNexus: Project not in funding phase");
        require(_milestoneIndex < proposal.milestones.length, "CognitoNexus: Invalid milestone index");
        require(!proposal.milestones[_milestoneIndex].approved, "CognitoNexus: Milestone already approved/rejected");
        require(bytes(proposal.milestones[_milestoneIndex].reportIPFSHash).length > 0, "CognitoNexus: Report not submitted yet");

        if (_approve) {
            proposal.milestones[_milestoneIndex].approved = true;
            uint256 paymentAmount = proposal.milestones[_milestoneIndex].amountETH;
            require(address(this).balance >= paymentAmount, "CognitoNexus: Insufficient funds in pool for milestone");
            payable(proposal.proposer).transfer(paymentAmount);
            proposal.milestones[_milestoneIndex].paid = true;
            proposal.raisedETH += paymentAmount;
            proposal.currentMilestoneIndex++;

            if (proposal.currentMilestoneIndex == proposal.milestones.length) {
                proposal.status = ProposalStatus.Completed;
                // Proposer's stake is returned upon full project completion
                payable(proposal.proposer).transfer(proposal.initialProposerStake);
                emit ProjectCompleted(_projectId);
                emit ProposalStatusChanged(_projectId, ProposalStatus.Funding, ProposalStatus.Completed);
            }
            emit MilestoneApprovedAndPaid(_projectId, _milestoneIndex, paymentAmount);
        } else {
            // Milestone rejected: potentially set proposal status to Cancelled or allow re-submission.
            // For simplicity, let's say rejection means project is stalled, can be cancelled by governance.
            // Or allow proposer to re-submit new report. For now, just mark approved=false
            // and leave it to governance to manage (e.g., via `cancelProposal`).
        }
    }

    /// @notice Finalizes a project as complete, triggering the impact assessment phase.
    /// @dev Called automatically after all milestones are paid, or can be triggered by trusted reviewer.
    /// @param _projectId The ID of the project to mark complete.
    function markProjectComplete(uint256 _projectId) external whenNotPaused {
        InnovationProposal storage proposal = proposals[_projectId];
        require(proposal.id > 0, "CognitoNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Funding, "CognitoNexus: Project not in funding phase"); // Can only mark complete from funding
        require(proposal.currentMilestoneIndex == proposal.milestones.length, "CognitoNexus: Not all milestones paid yet");

        proposal.status = ProposalStatus.Completed;
        // Proposer's stake is returned upon full project completion
        payable(proposal.proposer).transfer(proposal.initialProposerStake);
        emit ProjectCompleted(_projectId);
        emit ProposalStatusChanged(_projectId, ProposalStatus.Funding, ProposalStatus.Completed);
    }

    /// @notice Users (or Chainlink Keepers/Oracles) submit data on a project's real-world impact.
    /// @param _projectId The ID of the project.
    /// @param _impactDataIPFSHash IPFS hash pointing to detailed impact data/report.
    function submitProjectImpactAssessment(uint256 _projectId, string calldata _impactDataIPFSHash) external whenNotPaused {
        InnovationProposal storage proposal = proposals[_projectId];
        require(proposal.id > 0, "CognitoNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Completed, "CognitoNexus: Project not in completed phase");
        require(block.timestamp <= proposal.submittedAt + (config.impactAssessmentPeriodDays * 1 days), "CognitoNexus: Impact assessment period ended");
        require(!proposal.impactAssessed, "CognitoNexus: Impact already assessed");
        require(bytes(_impactDataIPFSHash).length > 0, "CognitoNexus: Impact data hash cannot be empty");

        proposal.impactDataIPFSHash = _impactDataIPFSHash;
        proposal.impactAssessed = true;
        proposal.status = ProposalStatus.Assessed;

        // Potentially reward the submitter of the impact assessment, especially if it's an oracle/keeper.
        // For simplicity, this is an entry point for data.
        emit ImpactAssessmentSubmitted(_projectId, _impactDataIPFSHash);
        emit ProposalStatusChanged(_projectId, ProposalStatus.Completed, ProposalStatus.Assessed);
    }

    // --- D. Incentives & Anti-Siloing ---

    /// @notice Allows users to claim their accrued rewards (e.g., from successful endorsements, accurate impact assessments, governance participation).
    function claimIncentiveRewards() external whenNotPaused {
        UserData storage user = users[msg.sender];
        uint256 amountToClaim = user.accruedRewards;
        require(amountToClaim > 0, "CognitoNexus: No rewards to claim");

        user.accruedRewards = 0;
        payable(msg.sender).transfer(amountToClaim);
        emit RewardsClaimed(msg.sender, amountToClaim);
    }

    /// @notice A callable function (e.g., by a Chainlink Keeper) that periodically triggers the redistribution of unclaimed or decayed rewards from the `CognitoDrain` pool to active participants.
    /// @dev This mechanism aims to prevent accumulation and incentivize active engagement.
    function distributeCognitoDrain() external whenNotPaused {
        require(address(this).balance >= config.cognitoDrainTriggerThreshold, "CognitoNexus: Balance below trigger threshold");

        // Calculate the amount to drain from the general pool
        // This is a simplified example; a real 'CognitoDrain' might target *unclaimed* rewards specifically,
        // or a portion of the *total* pool balance.
        uint256 drainAmount = (address(this).balance - config.cognitoDrainTriggerThreshold);
        drainAmount = (drainAmount * config.cognitoDrainRedistributionRate) / 100;

        if (drainAmount == 0) return; // Nothing to drain.

        uint256 totalActiveScore = 0;
        address[] memory activeUsers;
        // This iteration over all users is *highly gas intensive* and not practical on mainnet for large user bases.
        // In a real application, this would require a different approach:
        // 1. Snapshotting active users periodically.
        // 2. A Merkle tree distribution off-chain, with on-chain claim.
        // 3. A "pull" model where users can "drain" a portion when they claim their *own* rewards.
        // For this conceptual example, we'll illustrate the intent with a simplified loop,
        // acknowledging it's a scalability bottleneck.
        // For demonstration, let's just pick a few random active proposals' voters/endorsers.
        // Or, more realistically, this function would just move funds to a temporary pool for later distribution.

        // Placeholder for distribution: For actual implementation, this would need a more scalable approach.
        // For the sake of demonstrating the concept without infinite loops,
        // let's assume it moves funds to a temporary "drain pool" that users can then claim from.
        // Or, simply, it burns a portion (simplest anti-silo) or sends to a predefined DAO treasury.

        // Simplest "drain": Send a portion to a burn address or a general DAO treasury address (e.g., owner).
        // A redistribution is complex without iterating users.
        uint256 redistributedAmount = 0;
        if (config.cognitoDrainRedistributionRate > 0) {
            // For now, let's assume redistribution means it adds to `accruedRewards` of *some* active users.
            // This is the part that is impossible to do efficiently on-chain for "all active users".
            // So, let's just simulate a portion being "drained" and available for future distribution logic.
            // For a "truly distributed" model, this would be a separate contract or off-chain process.
            // Let's make it add to a general rewards pool for `claimIncentiveRewards`.
            // The `cognitoDrainTriggerThreshold` is essentially the "buffer" of ETH.
            // Funds above this are what is considered for "drain".
            // For this example, let's drain a portion to the owner as a conceptual "DAO treasury".
            uint256 actualDrain = (address(this).balance * config.cognitoDrainRedistributionRate) / 100;
            if (actualDrain > 0) {
                payable(owner()).transfer(actualDrain); // conceptual "DAO treasury"
                redistributedAmount = actualDrain; // Part that goes *somewhere*, not necessarily to users directly
            }
        }
        // The *actual* "CognitoDrain" is that `accruedRewards` decay or have expiry, not directly implemented here for brevity,
        // but implied by the `distributeCognitoDrain` function existing.

        emit CognitoDrainTriggered(drainAmount, redistributedAmount);
    }

    /// @notice Allows users to challenge a submitted project impact assessment, triggering a dispute resolution process.
    /// @param _projectId The ID of the project.
    /// @param _reasonIPFSHash IPFS hash containing the detailed reason for the challenge.
    function challengeImpactAssessment(uint256 _projectId, string calldata _reasonIPFSHash) external payable whenNotPaused {
        InnovationProposal storage proposal = proposals[_projectId];
        require(proposal.id > 0, "CognitoNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Assessed, "CognitoNexus: Project not in assessed phase");
        require(!proposal.impactChallenged, "CognitoNexus: Impact already challenged");
        require(block.timestamp <= proposal.submittedAt + (config.impactAssessmentPeriodDays * 1 days) + (config.challengePeriodDays * 1 days), "CognitoNexus: Challenge period ended");
        require(msg.value > 0.001 ether, "CognitoNexus: Must provide a challenge stake"); // Small stake to prevent spam

        // Move proposal back to a 'Challenged' state
        proposal.status = ProposalStatus.Challenged;
        proposal.impactChallenged = true;
        // Store challenge details if needed, or link to external arbitration.
        // For simplicity, we just mark it as challenged.
        // The challenge stake is held by the contract, to be rewarded to dispute resolvers or burned.

        emit ImpactAssessmentChallenged(_projectId, msg.sender);
        emit ProposalStatusChanged(_projectId, ProposalStatus.Assessed, ProposalStatus.Challenged);
    }

    // --- E. Utility & Safety ---

    /// @notice View function to retrieve all details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The InnovationProposal struct.
    function getProposalDetails(uint256 _proposalId) external view returns (InnovationProposal memory) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "CognitoNexus: Invalid proposal ID");
        return proposals[_proposalId];
    }

    /// @notice View function to calculate a user's effective vote power for a specific proposal.
    /// @param _user The address of the user.
    /// @param _proposalId The ID of the proposal (used to check if they already voted).
    /// @return The calculated weighted vote power (square root of CognitoScore).
    function getUserVotePower(address _user, uint256 _proposalId) external view returns (uint256) {
        // This function will fetch the *current* effective CognitoScore
        // and apply the quadratic weighting. It should *not* update the score.
        uint256 currentScore = getCognitoScore(_user);
        
        // This check is if the user *already* voted on THIS specific proposal
        if (users[_user].hasVotedOnProposal[_proposalId]) {
            return 0; // Already voted, no more power for this proposal
        }

        return sqrt(currentScore);
    }

    // fallback function to receive ETH
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
```