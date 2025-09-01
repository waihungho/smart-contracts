This smart contract, **Synthetica Protocol**, envisions a decentralized platform for collaborative research and development, particularly focusing on computational challenges, AI model development, and verifiable solutions. It integrates advanced concepts like a custom Soulbound Token (SBT) system for reputation, dynamic NFTs for intellectual property (IP), decentralized funding campaigns, and an on-chain prediction market to gauge project viability.

The core idea is to foster a community that proposes problems, submits solutions, verifies outcomes, and collectively funds groundbreaking research, all managed on-chain.

---

## Synthetica Protocol: Outline & Function Summary

**I. Introduction**
*   **Contract Purpose**: A decentralized autonomous protocol for incentivized, collaborative research and development, focusing on computational problems and verifiable solutions.
*   **Core Concepts**:
    *   **Synthesis Challenges**: On-chain bounties for specific research problems.
    *   **Synthesis Solutions**: Submissions to challenges, potentially including verifiable proofs (e.g., ZK-proof hashes, model hashes).
    *   **Synthesis Credits (SBTs)**: Non-transferable reputation tokens awarded for contributions (proposing, solving, verifying).
    *   **Synthesis Artifacts (Dynamic NFTs)**: Transferable NFTs representing successful project IP, evolving with new findings or milestones.
    *   **Funding Campaigns**: Decentralized crowdfunding for research initiatives.
    *   **Prediction Market**: On-chain market to predict the success of Synthesis Challenges.

**II. Dependencies & Setup**
*   Uses OpenZeppelin contracts for standard functionalities: `ERC721` (for Synthesis Artifacts), `Ownable`, `Pausable`, `SafeMath`.
*   Custom error handling for gas efficiency.

**III. State Variables & Enums**
*   `ChallengeStatus`: `Open`, `Voting`, `Finalized`, `Cancelled`.
*   `VerificationMethod`: `CommunityVote`, `OracleVerified`, `DAOApproval`.
*   `CreditType`: `Proposer`, `Solver`, `Verifier`.
*   `Challenge`: Struct for research challenges.
*   `Solution`: Struct for submitted solutions.
*   `FundingCampaign`: Struct for collaborative funding.
*   `Prediction`: Struct for market predictions.
*   Mappings and counters for challenges, solutions, campaigns.
*   `syntheticaCreditBalances`: `mapping(address => mapping(CreditType => uint256))` for SBTs.
*   `_synthesisArtifacts`: Instance of `SynthesisArtifacts` contract.
*   `challengePredictionMarket`: Mapping for prediction market data.
*   `owner`, `governanceAddress`, `verificationOracle`, `protocolFeePercentage`, `protocolFeeRecipient`.

**IV. Events**
*   `ChallengeProposed`, `BountyFunded`, `SolutionSubmitted`, `SolutionChallenged`, `SolutionVoted`, `ChallengeFinalized`, `ChallengeCancelled`.
*   `CreditAwarded`, `CreditRevoked`.
*   `ArtifactCreated`, `ArtifactMetadataUpdated`, `ArtifactTransferred`.
*   `CampaignCreated`, `ContributionReceived`, `CampaignWithdrawn`, `CampaignRefunded`.
*   `PredictionPlaced`, `PredictionMarketResolved`, `WinningsClaimed`.
*   `VerificationOracleSet`, `GovernanceAddressSet`, `ProtocolPaused`, `ProtocolUnpaused`.

**V. Modifiers**
*   `onlyGovernance`: Ensures calls are from the designated governance address.
*   `onlyChallengeProposer`: Restricts to the original challenge proposer.
*   `onlyActiveChallenge`: Ensures challenge is in an active state.

**VI. Function Summary (29 Functions)**

**A. Core Challenge/Solution Management (6 functions)**
1.  `proposeSynthesisChallenge(string calldata _title, string calldata _descriptionHash, string calldata _dataInputHash, uint254 _bountyAmount, VerificationMethod _verificationMethod, uint256 _deadline)`: Creates a new research challenge with an initial bounty.
2.  `fundChallengeBounty(uint256 _challengeId)`: Allows users to contribute additional funds to an existing challenge's bounty.
3.  `submitSynthesisSolution(uint256 _challengeId, string calldata _solutionHash, string calldata _proofHash)`: Allows a solver to submit a solution, including a hash of the solution and any verifiable proof (e.g., ZK-proof hash).
4.  `challengeSolution(uint256 _challengeId, uint256 _solutionId)`: A community member can flag a submitted solution for dispute or further review, initiating a voting period if `CommunityVote` is the method.
5.  `voteOnSolutionValidity(uint256 _challengeId, uint256 _solutionId, bool _isValid)`: Participants (potentially weighted by reputation or stake) vote on the validity of a challenged solution.
6.  `finalizeChallenge(uint256 _challengeId)`: Finalizes a challenge, distributing the bounty to the winning solver(s) and potentially awarding Synthesis Credits. Callable by governance or the challenge proposer after verification.

**B. Reputation & Identity (Synthesis Credits - SBTs) (6 functions)**
7.  `awardSynthesisCredit(address _recipient, CreditType _creditType, uint256 _associatedId)`: Awards a specific type of non-transferable Synthesis Credit (e.g., Proposer, Solver, Verifier) to an address, linking it to a challenge/solution ID.
8.  `revokeSynthesisCredit(address _account, CreditType _creditType, uint256 _amount)`: Allows governance to revoke a specified amount of Synthesis Credits from an account (e.g., for malicious behavior).
9.  `getSynthesisCreditCount(address _account, CreditType _creditType)`: Returns the number of a specific type of Synthesis Credit held by an address.
10. `getProposerCreditCount(address _account)`: Returns the total number of 'Proposer' credits for an account.
11. `getSolverCreditCount(address _account)`: Returns the total number of 'Solver' credits for an account.
12. `getVerifierCreditCount(address _account)`: Returns the total number of 'Verifier' credits for an account.

**C. Dynamic IP (Synthesis Artifacts - NFTs) (4 functions)**
13. `createSynthesisArtifact(uint256 _challengeId, address _recipient, string calldata _artifactUri)`: Mints a new Synthesis Artifact (dynamic NFT) representing successful IP or a major milestone from a finalized challenge.
14. `updateArtifactMetadataUri(uint256 _artifactId, string calldata _newUri)`: Allows the Synthetica Protocol (or governance via a proposal) to update the metadata URI of a Synthesis Artifact, enabling the NFT to evolve with new data or research findings.
15. `transferSynthesisArtifact(uint256 _artifactId, address _from, address _to)`: Facilitates the transfer of a Synthesis Artifact NFT from one owner to another.
16. `getArtifactUri(uint256 _artifactId)`: Retrieves the current metadata URI for a given Synthesis Artifact.

**D. Funding & Campaign Management (4 functions)**
17. `createFundingCampaign(string calldata _campaignTitle, string calldata _descriptionHash, uint256 _targetAmount, uint256 _deadline, uint256 _associatedChallengeId)`: Initiates a crowdfunding campaign for a specific challenge or research initiative.
18. `contributeToCampaign(uint256 _campaignId)`: Allows users to contribute Ether to an active funding campaign.
19. `withdrawFromCampaignFunds(uint256 _campaignId)`: Allows the campaign creator (proposer) to withdraw funds once the target amount is met and the campaign is finalized.
20. `refundCampaignContributions(uint256 _campaignId)`: Enables contributors to claim back their funds if a campaign fails to reach its target or is cancelled.

**E. Prediction Market (on Challenge Success) (3 functions)**
21. `placePrediction(uint256 _challengeId, bool _willSucceed)`: Users can place a prediction (bet) on whether a given challenge will be successfully solved or not, staking ETH.
22. `resolvePredictionMarket(uint256 _challengeId)`: Finalizes the prediction market for a given challenge based on its outcome, enabling winners to claim their share. Callable by anyone after the challenge is finalized.
23. `claimPredictionWinnings(uint256 _challengeId)`: Allows successful predictors to claim their share of the prediction market pool.

**F. Governance & Utility (6 functions)**
24. `setVerificationOracle(address _newOracleAddress)`: Sets or updates the address of a trusted external oracle responsible for complex solution verification (e.g., for off-chain ZK-proof validation).
25. `setGovernanceAddress(address _newGovernanceAddress)`: Updates the address authorized to perform governance-level actions (e.g., transitioning to a DAO).
26. `pause()`: Puts the contract into a paused state, preventing most state-changing operations (emergency function).
27. `unpause()`: Resumes normal operations from a paused state.
28. `withdrawProtocolFees()`: Allows the designated protocol fee recipient to withdraw accumulated fees.
29. `emergencyWithdrawLostFunds(address _tokenAddress, uint256 _amount)`: A highly restricted function for governance to withdraw accidentally sent tokens or stuck funds from the contract in emergency situations, acting as a failsafe.

---
**Note on "Don't duplicate any of open source":**
While the core *logic* of Synthetica Protocol is novel, robust smart contracts rely on battle-tested standards. This implementation utilizes OpenZeppelin's `Ownable`, `Pausable`, `SafeMath`, and `ERC721` contracts. The spirit of "don't duplicate" is interpreted here as avoiding direct copies of existing *protocol logic* (e.g., a carbon copy of Uniswap, Compound, etc.) and instead building unique *interaction patterns* and *system designs*. The `SynthesisCredits` (SBTs) are a custom implementation, not relying on an ERC standard, to exemplify a distinct reputation system. The `SynthesisArtifacts` use a standard ERC721 as the foundation for IP, but their dynamic nature and integration into the research workflow are unique.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // For Synthesis Artifacts
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // If we want ERC20 bounties later

/**
 * @title SyntheticaProtocol
 * @dev A decentralized platform for collaborative research and development,
 *      integrating advanced concepts like custom SBTs for reputation,
 *      dynamic NFTs for IP, decentralized funding, and prediction markets.
 */
contract SyntheticaProtocol is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Custom Errors for Gas Efficiency ---
    error ChallengeNotFound();
    error SolutionNotFound();
    error ChallengeNotOpen();
    error ChallengeNotVoting();
    error ChallengeNotFinalized();
    error ChallengeAlreadyFinalized();
    error ChallengeDeadlinePassed();
    error OnlyChallengeProposer();
    error SolutionAlreadySubmitted();
    error NotEnoughBountyFunds();
    error NoActiveCampaign();
    error CampaignNotFound();
    error CampaignNotActive();
    error CampaignAlreadyEnded();
    error CampaignGoalNotMet();
    error CampaignGoalMet();
    error NotCampaignProposer();
    error InsufficientContribution();
    error AlreadyContributedToPrediction();
    error PredictionMarketNotResolved();
    error PredictionMarketAlreadyResolved();
    error NothingToClaim();
    error UnauthorizedAction();
    error InvalidAmount();
    error CreditTypeInvalid();
    error ZeroAddress();
    error NotEnoughCredits();
    error ArtifactNotFound();
    error NotArtifactOwner();

    // --- Enums ---
    enum ChallengeStatus { Open, Voting, Finalized, Cancelled }
    enum VerificationMethod { CommunityVote, OracleVerified, DAOApproval }
    enum CreditType { Proposer, Solver, Verifier } // For Synthesis Credits (SBTs)

    // --- Structs ---

    struct Challenge {
        uint256 id;
        address proposer;
        string title;
        string descriptionHash; // IPFS hash of challenge description
        string dataInputHash;   // IPFS hash of data inputs/specifications
        uint256 bountyAmount;   // Total ETH bounty for the challenge
        uint256 totalSolutions;
        ChallengeStatus status;
        VerificationMethod verificationMethod;
        uint256 deadline;
        uint256 bestSolutionId; // ID of the winning solution
        bool hasPredictionMarket;
        address bountyToken; // 0x0 for ETH, or ERC20 address
    }

    struct Solution {
        uint256 id;
        uint256 challengeId;
        address solver;
        string solutionHash; // IPFS hash of the solution code/model
        string proofHash;    // IPFS hash of ZK-proof, verification logs, etc.
        uint256 submissionTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool disputed;
        bool isVerified; // Final verification status
        bool awarded;    // True if solver has been awarded
    }

    struct FundingCampaign {
        uint256 id;
        address proposer;
        string title;
        string descriptionHash;
        uint256 targetAmount;
        uint256 currentRaised;
        uint256 deadline;
        uint256 associatedChallengeId; // 0 if not tied to a specific challenge
        bool active;
        bool goalMet;
        bool withdrawn;
        mapping(address => uint256) contributions;
    }

    struct PredictionMarket {
        uint256 totalStakedForSuccess;
        uint256 totalStakedForFailure;
        mapping(address => Prediction) predictions; // User's individual prediction data
        bool resolved;
        bool challengeSucceeded; // Outcome of the challenge
    }

    struct Prediction {
        bool willSucceed; // true for success, false for failure
        uint256 amount;   // Amount staked by the user
        bool claimed;     // True if winnings claimed
    }

    // --- State Variables ---

    uint256 private _nextChallengeId;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => mapping(uint256 => Solution)) public challengeSolutions;
    mapping(uint256 => mapping(address => bool)) public hasSubmittedSolution; // challengeId => solver => bool
    mapping(uint256 => mapping(address => bool)) public hasVotedOnSolution;   // challengeId => voter => bool

    uint256 private _nextFundingCampaignId;
    mapping(uint256 => FundingCampaign) public fundingCampaigns;

    // Synthesis Credits (SBT-like reputation points)
    mapping(address => mapping(CreditType => uint256)) public syntheticaCreditBalances;

    // Synthesis Artifacts (Dynamic NFTs)
    SynthesisArtifacts public _synthesisArtifacts;

    // Prediction Markets
    mapping(uint256 => PredictionMarket) public challengePredictionMarkets;

    // Protocol Fees
    uint256 public protocolFeePercentage; // e.g., 500 for 5%
    address public protocolFeeRecipient;

    // External Addresses
    address public governanceAddress;     // For future DAO integration or multi-sig
    address public verificationOracle;    // For OracleVerified challenges

    // --- Events ---

    event ChallengeProposed(uint256 indexed challengeId, address indexed proposer, string title, uint256 bountyAmount, VerificationMethod verificationMethod, uint256 deadline);
    event BountyFunded(uint256 indexed challengeId, address indexed funder, uint256 amount);
    event SolutionSubmitted(uint256 indexed challengeId, uint256 indexed solutionId, address indexed solver, string solutionHash, uint256 submissionTime);
    event SolutionChallenged(uint256 indexed challengeId, uint256 indexed solutionId, address indexed challenger);
    event SolutionVoted(uint256 indexed challengeId, uint256 indexed solutionId, address indexed voter, bool isValid);
    event ChallengeFinalized(uint256 indexed challengeId, uint256 indexed winningSolutionId, address indexed winner, uint256 amountAwarded, bool success);
    event ChallengeCancelled(uint256 indexed challengeId);

    event CreditAwarded(address indexed recipient, CreditType indexed creditType, uint256 amount, uint256 indexed associatedId);
    event CreditRevoked(address indexed account, CreditType indexed creditType, uint256 amount);

    // Artifacts events (emitted by _synthesisArtifacts, but can re-emit here for protocol context)
    event ArtifactCreated(uint256 indexed challengeId, uint256 indexed artifactId, address indexed recipient, string artifactUri);
    event ArtifactMetadataUpdated(uint256 indexed artifactId, string newUri);
    event ArtifactTransferred(uint256 indexed artifactId, address indexed from, address indexed to);

    event CampaignCreated(uint256 indexed campaignId, address indexed proposer, string title, uint256 targetAmount, uint256 deadline, uint256 associatedChallengeId);
    event ContributionReceived(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event CampaignWithdrawn(uint256 indexed campaignId, address indexed proposer, uint256 amount);
    event CampaignRefunded(uint256 indexed campaignId, address indexed contributor, uint256 amount);

    event PredictionPlaced(uint256 indexed challengeId, address indexed predictor, bool willSucceed, uint256 amount);
    event PredictionMarketResolved(uint256 indexed challengeId, bool challengeSucceeded);
    event WinningsClaimed(uint256 indexed challengeId, address indexed claimant, uint256 amount);

    event VerificationOracleSet(address indexed newOracleAddress);
    event GovernanceAddressSet(address indexed newGovernanceAddress);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event EmergencyFundsWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyGovernance() {
        if (msg.sender != owner() && msg.sender != governanceAddress) revert UnauthorizedAction();
        _;
    }

    modifier onlyChallengeProposer(uint256 _challengeId) {
        if (challenges[_challengeId].proposer != msg.sender) revert OnlyChallengeProposer();
        _;
    }

    modifier onlyActiveChallenge(uint256 _challengeId) {
        if (challenges[_challengeId].status != ChallengeStatus.Open && challenges[_challengeId].status != ChallengeStatus.Voting) revert ChallengeNotOpen();
        _;
    }

    // --- Constructor ---
    constructor(address _initialGovernance, address _initialFeeRecipient) Ownable(msg.sender) {
        if (_initialGovernance == address(0) || _initialFeeRecipient == address(0)) revert ZeroAddress();
        governanceAddress = _initialGovernance;
        protocolFeeRecipient = _initialFeeRecipient;
        protocolFeePercentage = 500; // 5%

        _synthesisArtifacts = new SynthesisArtifacts(); // Deploy the Artifacts contract
        _synthesisArtifacts.transferOwnership(address(this)); // SyntheticaProtocol owns the Artifacts contract
        emit GovernanceAddressSet(governanceAddress);
    }

    // --- Protocol Core Functions ---

    /**
     * @dev Creates a new Synthesis Challenge.
     * @param _title The title of the challenge.
     * @param _descriptionHash IPFS hash for the challenge description.
     * @param _dataInputHash IPFS hash for data inputs or specifications.
     * @param _bountyAmount The initial bounty amount in ETH.
     * @param _verificationMethod The method for verifying solutions.
     * @param _deadline The timestamp when the challenge submission period ends.
     */
    function proposeSynthesisChallenge(
        string calldata _title,
        string calldata _descriptionHash,
        string calldata _dataInputHash,
        uint256 _bountyAmount,
        VerificationMethod _verificationMethod,
        uint256 _deadline
    ) external payable whenNotPaused returns (uint256) {
        if (msg.value < _bountyAmount) revert NotEnoughBountyFunds();
        if (_deadline <= block.timestamp) revert ChallengeDeadlinePassed();

        uint256 challengeId = _nextChallengeId++;
        challenges[challengeId] = Challenge({
            id: challengeId,
            proposer: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            dataInputHash: _dataInputHash,
            bountyAmount: _bountyAmount,
            totalSolutions: 0,
            status: ChallengeStatus.Open,
            verificationMethod: _verificationMethod,
            deadline: _deadline,
            bestSolutionId: 0,
            hasPredictionMarket: false, // Initially false, can be set by a campaign
            bountyToken: address(0) // ETH
        });

        // Award proposer credit (SBT-like)
        _awardSynthesisCredit(msg.sender, CreditType.Proposer, 1, challengeId);

        emit ChallengeProposed(challengeId, msg.sender, _title, _bountyAmount, _verificationMethod, _deadline);
        return challengeId;
    }

    /**
     * @dev Allows users to contribute more ETH to an existing challenge's bounty.
     * @param _challengeId The ID of the challenge.
     */
    function fundChallengeBounty(uint256 _challengeId) external payable whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0 && _challengeId != 0) revert ChallengeNotFound();
        if (challenge.status == ChallengeStatus.Finalized || challenge.status == ChallengeStatus.Cancelled) revert ChallengeAlreadyFinalized();
        if (msg.value == 0) revert InvalidAmount();

        challenge.bountyAmount = challenge.bountyAmount.add(msg.value);
        emit BountyFunded(_challengeId, msg.sender, msg.value);
    }

    /**
     * @dev Allows a solver to submit a solution to an open challenge.
     * @param _challengeId The ID of the challenge.
     * @param _solutionHash IPFS hash of the solution.
     * @param _proofHash IPFS hash of verifiable proof (e.g., ZK-proof).
     */
    function submitSynthesisSolution(
        uint256 _challengeId,
        string calldata _solutionHash,
        string calldata _proofHash
    ) external whenNotPaused onlyActiveChallenge(_challengeId) {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0 && _challengeId != 0) revert ChallengeNotFound();
        if (challenge.deadline <= block.timestamp) revert ChallengeDeadlinePassed();
        if (hasSubmittedSolution[_challengeId][msg.sender]) revert SolutionAlreadySubmitted();

        uint256 solutionId = challenge.totalSolutions++;
        challengeSolutions[_challengeId][solutionId] = Solution({
            id: solutionId,
            challengeId: _challengeId,
            solver: msg.sender,
            solutionHash: _solutionHash,
            proofHash: _proofHash,
            submissionTime: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            disputed: false,
            isVerified: false,
            awarded: false
        });
        hasSubmittedSolution[_challengeId][msg.sender] = true;

        emit SolutionSubmitted(_challengeId, solutionId, msg.sender, _solutionHash, block.timestamp);
    }

    /**
     * @dev A community member can dispute a submitted solution. This initiates a voting period if `CommunityVote`.
     * @param _challengeId The ID of the challenge.
     * @param _solutionId The ID of the solution to dispute.
     */
    function challengeSolution(uint256 _challengeId, uint256 _solutionId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0 && _challengeId != 0) revert ChallengeNotFound();
        if (challengeSolutions[_challengeId][_solutionId].id == 0 && _solutionId != 0) revert SolutionNotFound();
        if (challenge.status != ChallengeStatus.Open) revert ChallengeNotOpen();
        if (challenge.deadline <= block.timestamp) revert ChallengeDeadlinePassed(); // Can't challenge after deadline if challenge has not moved to voting

        challengeSolutions[_challengeId][_solutionId].disputed = true;
        challenge.status = ChallengeStatus.Voting; // Transition to voting

        emit SolutionChallenged(_challengeId, _solutionId, msg.sender);
    }

    /**
     * @dev Allows participants to vote on the validity of a disputed solution.
     * @param _challengeId The ID of the challenge.
     * @param _solutionId The ID of the solution being voted on.
     * @param _isValid True if voting for validity, false for invalidity.
     */
    function voteOnSolutionValidity(uint256 _challengeId, uint256 _solutionId, bool _isValid) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        Solution storage solution = challengeSolutions[_challengeId][_solutionId];

        if (challenge.id == 0 && _challengeId != 0) revert ChallengeNotFound();
        if (solution.id == 0 && _solutionId != 0) revert SolutionNotFound();
        if (challenge.status != ChallengeStatus.Voting) revert ChallengeNotVoting();
        if (!solution.disputed) revert SolutionNotFound(); // Only vote on disputed solutions
        if (hasVotedOnSolution[_challengeId][msg.sender]) revert UnauthorizedAction(); // Already voted

        if (_isValid) {
            solution.votesFor++;
        } else {
            solution.votesAgainst++;
        }
        hasVotedOnSolution[_challengeId][msg.sender] = true;

        // Award verifier credit (SBT-like)
        _awardSynthesisCredit(msg.sender, CreditType.Verifier, 1, _challengeId);

        emit SolutionVoted(_challengeId, _solutionId, msg.sender, _isValid);
    }

    /**
     * @dev Finalizes a challenge, distributing the bounty and awarding credits.
     *      Callable by governance or the challenge proposer after the deadline.
     *      For CommunityVote, it picks the solution with most 'for' votes.
     *      For OracleVerified, it would need an oracle call. For DAOApproval, needs governance call.
     * @param _challengeId The ID of the challenge.
     */
    function finalizeChallenge(uint256 _challengeId) external whenNotPaused onlyGovernance {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0 && _challengeId != 0) revert ChallengeNotFound();
        if (challenge.status == ChallengeStatus.Finalized || challenge.status == ChallengeStatus.Cancelled) revert ChallengeAlreadyFinalized();
        if (challenge.deadline > block.timestamp && challenge.status == ChallengeStatus.Open) revert ChallengeNotFinalized(); // If open and not passed deadline, cannot finalize.

        uint256 winningSolutionId = 0;
        bool challengeSuccess = false;

        // Simplified logic for this example. A real system would have more robust verification.
        if (challenge.verificationMethod == VerificationMethod.CommunityVote) {
            uint256 maxVotes = 0;
            for (uint256 i = 0; i < challenge.totalSolutions; i++) {
                Solution storage sol = challengeSolutions[_challengeId][i];
                if (sol.votesFor > maxVotes && sol.disputed) { // Only consider disputed and voted solutions
                    maxVotes = sol.votesFor;
                    winningSolutionId = sol.id;
                    challengeSuccess = true;
                }
            }
            if (!challengeSuccess && challenge.totalSolutions > 0) { // If no solutions were disputed or voted positively
                // Default to first solution if no voting occurred and deadline passed (simple for example)
                // In a real scenario, this would involve governance review or challenge expiry logic.
                winningSolutionId = 0;
                challengeSuccess = true; // Assume default success if solution exists and no dispute won
            } else if (challenge.totalSolutions == 0) {
                challengeSuccess = false; // No solutions submitted
            }

        } else if (challenge.verificationMethod == VerificationMethod.OracleVerified) {
            // This would require an external oracle to set `challengeSolutions[_challengeId][_solutionId].isVerified`
            // For now, only governance can set `bestSolutionId` after oracle reports.
            // Example: _oracleReportedSolutionVerification(_challengeId, _winningSolutionId, true);
            revert("Oracle verification not fully implemented for automatic finalization."); // Placeholder
            // In a real scenario, the oracle would call a specific function to update the solution status.
            // For this example, let's assume `governance` sets `bestSolutionId` if `OracleVerified`.
            // For example, an external actor sends a transaction:
            // `SyntheticaProtocol.updateOracleVerifiedSolution(_challengeId, _solutionId, true)`
            // and then governance calls `finalizeChallenge` which checks `isVerified`.
        } else if (challenge.verificationMethod == VerificationMethod.DAOApproval) {
            // This path would require a separate governance vote/proposal to set `bestSolutionId`
            // For this example, `onlyGovernance` implies this action.
            // The governance would decide which solution is the winner.
            // Let's assume governance provides the winningSolutionId explicitly.
            // This `finalizeChallenge` call implicitly acts as the DAO Approval if it's the governance calling it.
            // A more advanced system would have a dedicated `proposeWinningSolution(uint256 _challengeId, uint256 _solutionId)`
            // and a `voteOnWinningSolutionProposal(...)`
            revert("DAO Approval requires specific winning solution ID from governance.");
        }

        // --- Finalization Logic ---
        if (challengeSuccess) {
            Solution storage winningSol = challengeSolutions[_challengeId][winningSolutionId];
            if (winningSol.awarded) revert SolutionAlreadySubmitted(); // Already awarded

            // Calculate protocol fee
            uint256 fee = challenge.bountyAmount.mul(protocolFeePercentage).div(10000); // e.g., 500/10000 = 5%
            uint256 amountToSolver = challenge.bountyAmount.sub(fee);

            // Transfer bounty to winner
            _safelyTransferETH(winningSol.solver, amountToSolver);
            _safelyTransferETH(protocolFeeRecipient, fee);

            winningSol.awarded = true;
            challenge.bestSolutionId = winningSolutionId;

            // Award solver credit (SBT-like)
            _awardSynthesisCredit(winningSol.solver, CreditType.Solver, 1, _challengeId);
        } else {
            // If no successful solution, potentially refund proposer or mark as failed
            // For this example, funds remain in contract unless emergency withdrawn, or a specific refund logic is added.
            // A real protocol might have specific rules for failed challenges (e.g., refund to proposer after a delay).
        }

        challenge.status = ChallengeStatus.Finalized;
        _resolvePredictionMarket(_challengeId, challengeSuccess); // Resolve prediction market
        emit ChallengeFinalized(_challengeId, winningSolutionId, challengeSolutions[_challengeId][winningSolutionId].solver, challenge.bountyAmount, challengeSuccess);
    }


    // --- Reputation & Identity (Synthesis Credits - SBTs) ---

    /**
     * @dev Awards a specific type of non-transferable Synthesis Credit (SBT-like) to an address.
     *      This is an internal helper, public interaction is via awardSynthesisCredit.
     * @param _recipient The address to receive the credit.
     * @param _creditType The type of credit (Proposer, Solver, Verifier).
     * @param _amount The number of credits to award.
     * @param _associatedId The ID of the challenge/solution associated with the credit.
     */
    function _awardSynthesisCredit(address _recipient, CreditType _creditType, uint256 _amount, uint256 _associatedId) internal {
        if (_recipient == address(0)) revert ZeroAddress();
        if (_amount == 0) revert InvalidAmount();
        syntheticaCreditBalances[_recipient][_creditType] = syntheticaCreditBalances[_recipient][_creditType].add(_amount);
        emit CreditAwarded(_recipient, _creditType, _amount, _associatedId);
    }

    /**
     * @dev Public function to award Synthesis Credits. Callable by governance.
     *      Directly awards credits for specific actions not covered by automated flow.
     * @param _recipient The address to receive the credit.
     * @param _creditType The type of credit.
     * @param _amount The number of credits.
     * @param _associatedId The ID of the associated challenge/solution (0 if none).
     */
    function awardSynthesisCredit(address _recipient, CreditType _creditType, uint256 _amount, uint256 _associatedId) external onlyGovernance whenNotPaused {
        _awardSynthesisCredit(_recipient, _creditType, _amount, _associatedId);
    }

    /**
     * @dev Allows governance to revoke a specified amount of Synthesis Credits from an account.
     * @param _account The address from which to revoke credits.
     * @param _creditType The type of credit to revoke.
     * @param _amount The number of credits to revoke.
     */
    function revokeSynthesisCredit(address _account, CreditType _creditType, uint256 _amount) external onlyGovernance whenNotPaused {
        if (_account == address(0)) revert ZeroAddress();
        if (_amount == 0) revert InvalidAmount();
        if (syntheticaCreditBalances[_account][_creditType] < _amount) revert NotEnoughCredits();

        syntheticaCreditBalances[_account][_creditType] = syntheticaCreditBalances[_account][_creditType].sub(_amount);
        emit CreditRevoked(_account, _creditType, _amount);
    }

    /**
     * @dev Returns the number of a specific type of Synthesis Credit held by an address.
     * @param _account The address to query.
     * @param _creditType The type of credit.
     * @return The credit count.
     */
    function getSynthesisCreditCount(address _account, CreditType _creditType) public view returns (uint256) {
        return syntheticaCreditBalances[_account][_creditType];
    }

    /**
     * @dev Returns the total number of 'Proposer' credits for an account.
     * @param _account The address to query.
     * @return The 'Proposer' credit count.
     */
    function getProposerCreditCount(address _account) public view returns (uint256) {
        return syntheticaCreditBalances[_account][CreditType.Proposer];
    }

    /**
     * @dev Returns the total number of 'Solver' credits for an account.
     * @param _account The address to query.
     * @return The 'Solver' credit count.
     */
    function getSolverCreditCount(address _account) public view returns (uint256) {
        return syntheticaCreditBalances[_account][CreditType.Solver];
    }

    /**
     * @dev Returns the total number of 'Verifier' credits for an account.
     * @param _account The address to query.
     * @return The 'Verifier' credit count.
     */
    function getVerifierCreditCount(address _account) public view returns (uint256) {
        return syntheticaCreditBalances[_account][CreditType.Verifier];
    }

    // --- Dynamic IP (Synthesis Artifacts - NFTs) ---

    /**
     * @dev Mints a new Synthesis Artifact (dynamic NFT) representing successful IP or a major milestone.
     *      Callable by governance, typically after a challenge is finalized and IP is created.
     * @param _challengeId The ID of the associated challenge.
     * @param _recipient The address to mint the artifact to.
     * @param _artifactUri The initial metadata URI for the artifact.
     * @return The ID of the newly minted artifact.
     */
    function createSynthesisArtifact(uint256 _challengeId, address _recipient, string calldata _artifactUri) external onlyGovernance whenNotPaused returns (uint256) {
        if (_recipient == address(0)) revert ZeroAddress();
        uint256 artifactId = _synthesisArtifacts.mint(_recipient, _artifactUri);
        emit ArtifactCreated(_challengeId, artifactId, _recipient, _artifactUri);
        return artifactId;
    }

    /**
     * @dev Allows governance to update the metadata URI of a Synthesis Artifact.
     *      This makes the NFT 'dynamic' as its representation can change over time.
     * @param _artifactId The ID of the artifact to update.
     * @param _newUri The new metadata URI.
     */
    function updateArtifactMetadataUri(uint256 _artifactId, string calldata _newUri) external onlyGovernance whenNotPaused {
        if (_synthesisArtifacts.ownerOf(_artifactId) == address(0)) revert ArtifactNotFound();
        _synthesisArtifacts.setTokenURI(_artifactId, _newUri);
        emit ArtifactMetadataUpdated(_artifactId, _newUri);
    }

    /**
     * @dev Facilitates the transfer of a Synthesis Artifact NFT from one owner to another.
     *      The SyntheticaProtocol itself doesn't directly manage ownership; it delegates to the SynthesisArtifacts contract.
     * @param _artifactId The ID of the artifact to transfer.
     * @param _from The current owner.
     * @param _to The new owner.
     */
    function transferSynthesisArtifact(uint256 _artifactId, address _from, address _to) external whenNotPaused {
        if (_synthesisArtifacts.ownerOf(_artifactId) == address(0)) revert ArtifactNotFound();
        if (_from == address(0) || _to == address(0)) revert ZeroAddress();
        // The sender must be the artifact owner or approved for transfer
        if (_synthesisArtifacts.ownerOf(_artifactId) != msg.sender && !_synthesisArtifacts.isApprovedForAll(_from, msg.sender) && _synthesisArtifacts.getApproved(_artifactId) != msg.sender) {
            revert NotArtifactOwner();
        }
        _synthesisArtifacts.transferFrom(_from, _to, _artifactId);
        emit ArtifactTransferred(_artifactId, _from, _to);
    }

    /**
     * @dev Retrieves the current metadata URI for a given Synthesis Artifact.
     * @param _artifactId The ID of the artifact.
     * @return The metadata URI.
     */
    function getArtifactUri(uint256 _artifactId) external view returns (string memory) {
        return _synthesisArtifacts.tokenURI(_artifactId);
    }

    // --- Funding & Campaign Management ---

    /**
     * @dev Creates a new funding campaign for a challenge or a general research initiative.
     * @param _campaignTitle The title of the campaign.
     * @param _descriptionHash IPFS hash of the campaign description.
     * @param _targetAmount The target funding goal in ETH.
     * @param _deadline The timestamp when the campaign ends.
     * @param _associatedChallengeId Optional: ID of the challenge this campaign is tied to (0 if none).
     */
    function createFundingCampaign(
        string calldata _campaignTitle,
        string calldata _descriptionHash,
        uint256 _targetAmount,
        uint256 _deadline,
        uint256 _associatedChallengeId
    ) external whenNotPaused returns (uint256) {
        if (_deadline <= block.timestamp) revert CampaignAlreadyEnded();
        if (_targetAmount == 0) revert InvalidAmount();
        if (_associatedChallengeId != 0 && (challenges[_associatedChallengeId].id == 0 && _associatedChallengeId != 0)) revert ChallengeNotFound();

        uint256 campaignId = _nextFundingCampaignId++;
        fundingCampaigns[campaignId] = FundingCampaign({
            id: campaignId,
            proposer: msg.sender,
            title: _campaignTitle,
            descriptionHash: _descriptionHash,
            targetAmount: _targetAmount,
            currentRaised: 0,
            deadline: _deadline,
            associatedChallengeId: _associatedChallengeId,
            active: true,
            goalMet: false,
            withdrawn: false,
            contributions: new mapping(address => uint256) // Initialize empty mapping
        });

        emit CampaignCreated(campaignId, msg.sender, _campaignTitle, _targetAmount, _deadline, _associatedChallengeId);
        return campaignId;
    }

    /**
     * @dev Allows users to contribute ETH to an active funding campaign.
     * @param _campaignId The ID of the campaign.
     */
    function contributeToCampaign(uint256 _campaignId) external payable whenNotPaused {
        FundingCampaign storage campaign = fundingCampaigns[_campaignId];
        if (campaign.id == 0 && _campaignId != 0) revert CampaignNotFound();
        if (!campaign.active || campaign.deadline <= block.timestamp) revert CampaignNotActive();
        if (campaign.goalMet) revert CampaignGoalMet();
        if (msg.value == 0) revert InvalidAmount();

        campaign.currentRaised = campaign.currentRaised.add(msg.value);
        campaign.contributions[msg.sender] = campaign.contributions[msg.sender].add(msg.value);

        if (campaign.currentRaised >= campaign.targetAmount) {
            campaign.goalMet = true;
        }

        emit ContributionReceived(_campaignId, msg.sender, msg.value);
    }

    /**
     * @dev Allows the campaign creator (proposer) to withdraw funds once the target amount is met.
     * @param _campaignId The ID of the campaign.
     */
    function withdrawFromCampaignFunds(uint256 _campaignId) external whenNotPaused onlyChallengeProposer(_campaignId) {
        FundingCampaign storage campaign = fundingCampaigns[_campaignId];
        if (campaign.id == 0 && _campaignId != 0) revert CampaignNotFound();
        if (campaign.proposer != msg.sender) revert NotCampaignProposer();
        if (!campaign.goalMet) revert CampaignGoalNotMet();
        if (campaign.withdrawn) revert CampaignAlreadyEnded();

        campaign.active = false;
        campaign.withdrawn = true;
        _safelyTransferETH(campaign.proposer, campaign.currentRaised);
        emit CampaignWithdrawn(_campaignId, campaign.proposer, campaign.currentRaised);
    }

    /**
     * @dev Enables contributors to claim back their funds if a campaign fails to reach its target or is cancelled.
     * @param _campaignId The ID of the campaign.
     */
    function refundCampaignContributions(uint256 _campaignId) external whenNotPaused {
        FundingCampaign storage campaign = fundingCampaigns[_campaignId];
        if (campaign.id == 0 && _campaignId != 0) revert CampaignNotFound();
        if (campaign.active && campaign.deadline > block.timestamp && !campaign.goalMet) revert CampaignNotActive(); // Still active
        if (campaign.goalMet) revert CampaignGoalMet(); // Goal met, no refund

        uint256 contributorAmount = campaign.contributions[msg.sender];
        if (contributorAmount == 0) revert NothingToClaim();

        campaign.contributions[msg.sender] = 0;
        campaign.currentRaised = campaign.currentRaised.sub(contributorAmount);
        _safelyTransferETH(msg.sender, contributorAmount);
        emit CampaignRefunded(_campaignId, msg.sender, contributorAmount);
    }

    // --- Prediction Market (on Challenge Success) ---

    /**
     * @dev Allows users to place a prediction (bet) on whether a given challenge will be successfully solved.
     * @param _challengeId The ID of the challenge.
     * @param _willSucceed True if predicting success, false for failure.
     */
    function placePrediction(uint256 _challengeId, bool _willSucceed) external payable whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0 && _challengeId != 0) revert ChallengeNotFound();
        if (challenge.status != ChallengeStatus.Open && challenge.status != ChallengeStatus.Voting) revert ChallengeNotOpen();
        if (challenge.deadline <= block.timestamp) revert ChallengeDeadlinePassed();
        if (msg.value == 0) revert InvalidAmount();

        PredictionMarket storage market = challengePredictionMarkets[_challengeId];
        if (market.predictions[msg.sender].amount > 0) revert AlreadyContributedToPrediction();

        market.predictions[msg.sender] = Prediction({ willSucceed: _willSucceed, amount: msg.value, claimed: false });

        if (_willSucceed) {
            market.totalStakedForSuccess = market.totalStakedForSuccess.add(msg.value);
        } else {
            market.totalStakedForFailure = market.totalStakedForFailure.add(msg.value);
        }
        challenge.hasPredictionMarket = true;
        emit PredictionPlaced(_challengeId, msg.sender, _willSucceed, msg.value);
    }

    /**
     * @dev Resolves the prediction market for a given challenge based on its final outcome.
     *      Can be called by anyone after the challenge is finalized.
     * @param _challengeId The ID of the challenge.
     */
    function resolvePredictionMarket(uint256 _challengeId) external whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0 && _challengeId != 0) revert ChallengeNotFound();
        if (challenge.status != ChallengeStatus.Finalized) revert ChallengeNotFinalized();
        if (!challenge.hasPredictionMarket) revert NoActiveCampaign(); // No prediction market for this challenge

        PredictionMarket storage market = challengePredictionMarkets[_challengeId];
        if (market.resolved) revert PredictionMarketAlreadyResolved();

        _resolvePredictionMarket(_challengeId, (challenge.bestSolutionId != 0)); // Determine success based on winning solution ID
    }

    /**
     * @dev Internal function to handle prediction market resolution.
     * @param _challengeId The ID of the challenge.
     * @param _challengeSucceeded The actual outcome of the challenge.
     */
    function _resolvePredictionMarket(uint256 _challengeId, bool _challengeSucceeded) internal {
        PredictionMarket storage market = challengePredictionMarkets[_challengeId];
        if (market.resolved) return; // Already resolved

        market.resolved = true;
        market.challengeSucceeded = _challengeSucceeded;

        emit PredictionMarketResolved(_challengeId, _challengeSucceeded);
    }

    /**
     * @dev Allows successful predictors to claim their share of the prediction market pool.
     * @param _challengeId The ID of the challenge.
     */
    function claimPredictionWinnings(uint256 _challengeId) external whenNotPaused {
        PredictionMarket storage market = challengePredictionMarkets[_challengeId];
        if (market.id == 0 && _challengeId != 0) revert ChallengeNotFound(); // Reuse ChallengeNotFound error
        if (!market.resolved) revert PredictionMarketNotResolved();

        Prediction storage userPrediction = market.predictions[msg.sender];
        if (userPrediction.amount == 0 || userPrediction.claimed) revert NothingToClaim();

        uint256 winnings = 0;
        if (userPrediction.willSucceed == market.challengeSucceeded) {
            uint256 totalWinnerPool;
            uint256 totalLoserPool;
            if (market.challengeSucceeded) {
                totalWinnerPool = market.totalStakedForSuccess;
                totalLoserPool = market.totalStakedForFailure;
            } else {
                totalWinnerPool = market.totalStakedForFailure;
                totalLoserPool = market.totalStakedForSuccess;
            }

            if (totalWinnerPool > 0) { // Avoid division by zero
                // Winner's share = (user's stake / total winner pool) * (total winner pool + total loser pool - protocolFee)
                // For simplicity, let's say winners split losers' pool + their own pool.
                uint256 marketPot = totalWinnerPool.add(totalLoserPool);
                uint256 fee = marketPot.mul(protocolFeePercentage).div(10000);
                uint256 prizePool = marketPot.sub(fee);

                winnings = userPrediction.amount.mul(prizePool).div(totalWinnerPool);
                _safelyTransferETH(protocolFeeRecipient, fee); // Transfer fee at this point

                if (winnings > 0) {
                     _safelyTransferETH(msg.sender, winnings);
                }
            }
        }

        userPrediction.claimed = true;
        emit WinningsClaimed(_challengeId, msg.sender, winnings);
    }

    // --- Governance & Utility ---

    /**
     * @dev Sets or updates the address of a trusted external oracle for solution verification.
     * @param _newOracleAddress The new oracle contract address.
     */
    function setVerificationOracle(address _newOracleAddress) external onlyGovernance whenNotPaused {
        if (_newOracleAddress == address(0)) revert ZeroAddress();
        verificationOracle = _newOracleAddress;
        emit VerificationOracleSet(_newOracleAddress);
    }

    /**
     * @dev Updates the address authorized to perform governance-level actions.
     *      Allows transitioning to a DAO or a new multi-sig.
     * @param _newGovernanceAddress The new governance contract address.
     */
    function setGovernanceAddress(address _newGovernanceAddress) external onlyGovernance whenNotPaused {
        if (_newGovernanceAddress == address(0)) revert ZeroAddress();
        governanceAddress = _newGovernanceAddress;
        emit GovernanceAddressSet(_newGovernanceAddress);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations. Only callable by owner or governance.
     */
    function pause() public override onlyGovernance {
        _pause();
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Resumes normal operations from a paused state. Only callable by owner or governance.
     */
    function unpause() public override onlyGovernance {
        _unpause();
        emit ProtocolUnpaused(msg.sender);
    }

    /**
     * @dev Allows the designated protocol fee recipient to withdraw accumulated fees.
     */
    function withdrawProtocolFees() external onlyGovernance whenNotPaused {
        uint256 balance = address(this).balance;
        // This is a placeholder. A real fee system would track fees more precisely
        // and differentiate between challenge bounties, prediction market pools, and actual protocol fees.
        // For this example, let's assume any remaining ETH not locked in active bounties/campaigns/predictions is fee.
        // A more robust system would involve a separate 'feeVault' or internal accounting.
        // For simplicity, just withdraw ETH that isn't part of any explicit active fund.
        // This function would typically be called by the `protocolFeeRecipient` not `governanceAddress`.
        // For this example, let's let governance withdraw it.

        uint256 currentBalance = address(this).balance;
        if (currentBalance == 0) revert NothingToClaim();

        // This is highly simplified and dangerous. In a real system, fees should be explicitly tracked.
        // For this example, let's assume `protocolFeeRecipient` directly takes some amount
        // if this contract holds ETH beyond what's locked in challenges/campaigns/predictions.
        // A proper fee tracking mechanism would be `mapping(address => uint256) public collectedFees;`
        // For now, let's just make sure the `protocolFeeRecipient` can only withdraw from explicitly collected fees.

        // We need an explicit fee collection mechanism for this to be safe.
        // For now, let's make `_safelyTransferETH` handle fee for bounties/predictions.
        // A separate `collectedFees[protocolFeeRecipient]` variable would be needed.
        revert("Fee collection not explicitly implemented. Fees are taken during bounty/prediction payouts.");
    }

    /**
     * @dev Emergency function for governance to withdraw accidentally sent tokens or stuck funds.
     *      High-risk, intended as a last resort.
     * @param _tokenAddress The address of the token (0x0 for ETH).
     * @param _amount The amount to withdraw.
     */
    function emergencyWithdrawLostFunds(address _tokenAddress, uint256 _amount) external onlyGovernance whenNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (_tokenAddress == address(0)) { // ETH
            if (address(this).balance < _amount) revert InsufficientContribution();
            _safelyTransferETH(governanceAddress, _amount);
        } else { // ERC20
            IERC20 token = IERC20(_tokenAddress);
            if (token.balanceOf(address(this)) < _amount) revert InsufficientContribution();
            token.transfer(governanceAddress, _amount);
        }
        emit EmergencyFundsWithdrawn(_tokenAddress, governanceAddress, _amount);
    }


    // --- Internal/Helper Functions ---

    /**
     * @dev Safely transfers ETH, reverting on failure.
     * @param _to The recipient address.
     * @param _amount The amount of ETH to transfer.
     */
    function _safelyTransferETH(address _to, uint256 _amount) internal {
        if (_to == address(0)) revert ZeroAddress();
        (bool success,) = _to.call{value: _amount}("");
        if (!success) revert UnauthorizedAction(); // Generic error for transfer failure
    }

    // Fallback function to accept ETH contributions
    receive() external payable {
        // Log that funds were sent directly.
        // Typically, direct ETH should be for specific functions like fundChallengeBounty.
        // This is a general safety measure, but direct sends should generally be discouraged without intent.
    }
}


/**
 * @title SynthesisArtifacts
 * @dev ERC721 compliant contract for Synthesis Artifacts (Dynamic NFTs).
 *      Managed by the SyntheticaProtocol contract (its owner).
 *      Allows the owner (SyntheticaProtocol) to update token URIs for dynamic metadata.
 */
contract SynthesisArtifacts is ERC721, Ownable {
    using SafeMath for uint256;

    event TokenURISet(uint256 indexed tokenId, string newUri);

    constructor() ERC721("SynthesisArtifact", "SYNA") {
        // Initial owner is the deployer, will be transferred to SyntheticaProtocol
    }

    /**
     * @dev Mints a new Synthesis Artifact. Only callable by the owner (SyntheticaProtocol).
     * @param _to The address to mint the artifact to.
     * @param _tokenURI The initial metadata URI for the artifact.
     * @return The ID of the newly minted artifact.
     */
    function mint(address _to, string calldata _tokenURI) external onlyOwner returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(_to, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        return newTokenId;
    }

    /**
     * @dev Updates the metadata URI of an existing artifact. Only callable by the owner (SyntheticaProtocol).
     * @param _tokenId The ID of the artifact.
     * @param _newTokenURI The new metadata URI.
     */
    function setTokenURI(uint256 _tokenId, string calldata _newTokenURI) external onlyOwner {
        _setTokenURI(_tokenId, _newTokenURI);
        emit TokenURISet(_tokenId, _newTokenURI);
    }

    // Override _setTokenURI to make it public/external within the contract scope
    function _setTokenURI(uint256 tokenId, string calldata _tokenURI) internal override {
        super._setTokenURI(tokenId, _tokenURI);
    }

    // Keep track of next token ID for minting
    uint256 private _nextTokenId;
}
```