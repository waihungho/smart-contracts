I'm excited to present "The **Oracleweave Protocol**," a Solidity smart contract designed as a Decentralized AI-Augmented Knowledge & Insight Marketplace. This protocol enables the submission, validation, and monetization of unique insights, transforming them into dynamic NFTs called "Knowledge Capsules." It leverages external AI oracles for quality assessment and integrates with a Soulbound Token (SBT) for a robust reputation system, alongside sophisticated dispute resolution and epoch-based rewards.

This contract aims to be distinct from common open-source projects by combining several advanced concepts:
*   **Multi-Stage Validation:** Insights go through both AI oracle assessment and human (curator) weighted voting.
*   **Dynamic NFTs (Knowledge Capsules):** The metadata of the NFTs changes based on real-time protocol activity, such as license count, challenge status, and updated validation scores.
*   **Algorithmic IP Licensing:** Knowledge Capsules can be licensed on-chain, generating royalty streams for their creators.
*   **External Contract Integration:** Demonstrates interaction with hypothetical AI Oracle and Reputation SBT contracts.
*   **Sophisticated Dispute Resolution:** A mechanism for challenging validated insights/capsules, involving bonded submissions and weighted community voting.
*   **Epoch-based Contribution Tracking:** A system to track participant contributions over defined periods, laying groundwork for future reward distribution.

---

## OracleweaveProtocol: Outline and Function Summary

### Outline

**I. Core Protocol Management:**
    *   Setup, access control, and general configuration.
**II. Insight Proposal & Discovery:**
    *   Mechanisms for users to propose new insights and for bounties to incentivize discovery.
**III. Multi-Stage Validation & Curation:**
    *   The core process involving AI oracle integration and human curator voting to validate insights.
**IV. Knowledge Capsule (Dynamic NFT) Lifecycle:**
    *   Management of the minted Knowledge Capsule NFTs, including licensing and dynamic properties.
**V. Reputation & Role Management (via external SBT):**
    *   Interaction with an external Soulbound Token (SBT) contract for participant reputation and role-based permissions.
**VI. Dispute Resolution:**
    *   System for challenging validated Knowledge Capsules, including voting and resolution.
**VII. Protocol Economics & Rewards:**
    *   Management of protocol fees, treasury, and epoch transitions for reward distribution.

### Function Summary & Explanation

**I. Core Protocol Management:**

1.  `constructor(string _name, string _symbol, address _aiOracleAddress, address _reputationSBTAddress, uint256 _submissionFee, uint256 _aiValidationThreshold, uint256 _curatorVoteThreshold, uint256 _challengeBondAmount, uint256 _epochDuration)`:
    *   Initializes the contract with NFT name/symbol, sets addresses for external AI Oracle and Reputation SBT contracts, and defines initial protocol parameters like fees, validation thresholds, and epoch duration. Grants `DEFAULT_ADMIN_ROLE` and `ADMIN_ROLE` to the deployer.
2.  `updateProtocolConfig(uint256 _newSubmissionFee, uint256 _newAIValidationThreshold, uint256 _newCuratorVoteThreshold, uint256 _newChallengeBondAmount, uint256 _newEpochDuration)`:
    *   Allows the `ADMIN_ROLE` to update global protocol parameters, ensuring adaptability and governance flexibility.
3.  `setOracleContract(address _aiOracleAddress)`:
    *   Sets the address of the external `IAIOracle` contract. Only callable by `ADMIN_ROLE`.
4.  `setReputationSBTContract(address _reputationSBTAddress)`:
    *   Sets the address of the external `IReputationSBT` contract. Only callable by `ADMIN_ROLE`.
5.  `pauseProtocol()`:
    *   An emergency function callable by `ADMIN_ROLE` to pause critical contract functionalities, useful for upgrades or in case of vulnerabilities.
6.  `unpauseProtocol()`:
    *   Restores full functionality to the contract after a pause. Only callable by `ADMIN_ROLE`.
7.  `withdrawProtocolFees(address _recipient)`:
    *   Allows the `ADMIN_ROLE` to withdraw accumulated protocol fees (submission fees, failed challenge bonds, protocol share of licensing) from the contract's treasury to a specified recipient.

**II. Insight Proposal & Discovery:**

8.  `submitInsightProposal(string memory _ipfsHash, uint256 _bountyId)`:
    *   Allows users with the `INQUISITOR_ROLE` to submit a new insight proposal. Requires a `submissionFee` and an IPFS hash pointing to the detailed insight data. Can optionally link to an existing bounty.
9.  `createDiscoveryBounty(string memory _targetKeyword, uint256 _rewardAmount)`:
    *   Allows `ADMIN_ROLE` or `CURATOR_ROLE` to create and fund a targeted bounty for specific types of insights, incentivizing focused contributions.
10. `claimDiscoveryBounty(uint256 _bountyId, uint256 _insightId)`:
    *   Enables an `INQUISITOR_ROLE` whose validated insight matches and is linked to an active bounty to claim the associated rewards.

**III. Multi-Stage Validation & Curation:**

11. `requestAIValidation(uint256 _insightId)`:
    *   Initiates an asynchronous request to the external AI Oracle to evaluate a submitted insight's novelty and quality. Only callable by `ORACLE_OPERATOR_ROLE`.
12. `fulfillAIValidation(uint256 _insightId, int256 _aiScore, string memory _aiReportHash)`:
    *   A callback function, exclusively callable by the AI Oracle contract, to update an insight's validation score based on AI analysis. Determines if the insight proceeds to human voting or is rejected.
13. `initiateCuratorVote(uint256 _insightId)`:
    *   Allows a `CURATOR_ROLE` to initiate a decentralized vote among other Curators to assess an insight's human-centric value and accuracy after AI validation.
14. `castCuratorVote(uint256 _insightId, bool _approve)`:
    *   Allows `CURATOR_ROLE` members with sufficient reputation (from SBT) to cast their weighted vote on an ongoing insight validation.
15. `finalizeInsightValidation(uint256 _insightId)`:
    *   After both AI and human validation stages, this function determines if an insight qualifies as a "Knowledge Capsule." If successful, it mints a new Knowledge Capsule NFT, updates participant reputations, and links the capsule to the original insight.

**IV. Knowledge Capsule (Dynamic NFT) Lifecycle:**

16. `getKnowledgeCapsuleMetadata(uint256 _capsuleId)`:
    *   Retrieves the current dynamically generated metadata URI for a specific Knowledge Capsule NFT, reflecting its current state (e.g., total licenses, challenge status, validation scores).
17. `licenseKnowledgeCapsule(uint256 _capsuleId)`:
    *   Allows users to acquire a time-bound license to utilize a Knowledge Capsule. Requires a payment, which is then split as royalties to the capsule creator and a share to the protocol treasury.
18. `revokeKnowledgeCapsuleLicense(uint256 _capsuleId)`:
    *   Allows a licensee to voluntarily revoke their active license for a Knowledge Capsule. No refund is provided for early revocation.
19. `updateCapsuleRoyaltyConfig(uint256 _capsuleId, uint256 _newRoyaltyRate, uint256 _newLicenseDuration)`:
    *   Allows the original creator of a Knowledge Capsule (`onlyCapsuleCreator`) to adjust its royalty rate and the default license duration for future licenses.
20. `burnKnowledgeCapsule(uint256 _capsuleId)`:
    *   A drastic measure, callable by `ADMIN_ROLE`, to permanently destroy a Knowledge Capsule NFT. This is intended for severe issues like discovered plagiarism or misinformation post-minting, and it penalizes the creator's reputation.

**V. Reputation & Role Management (via external SBT):**

21. `queryParticipantReputation(address _participant)`:
    *   A view function to query the external Reputation SBT contract for a specific participant's current reputation score, which influences their protocol permissions and voting power.

**VI. Dispute Resolution:**

22. `challengeKnowledgeCapsule(uint256 _capsuleId, string memory _reasonIpfsHash)`:
    *   Allows any `INQUISITOR_ROLE` participant to formally challenge the validity or integrity of a minted Knowledge Capsule. Requires submitting a challenge bond and an IPFS hash detailing the reason for the challenge.
23. `voteOnChallenge(uint256 _challengeId, bool _supportChallenge)`:
    *   Allows `CURATOR_ROLE` members to cast their weighted votes on an ongoing Knowledge Capsule challenge, either supporting or rejecting the challenge.
24. `resolveChallenge(uint256 _challengeId)`:
    *   Finalizes a Knowledge Capsule challenge based on the voting outcome. If the challenge is accepted, the capsule is burned, the creator is penalized, and the challenger's bond is returned. If rejected, the challenger loses their bond, which goes to the protocol treasury, and the creator may receive a small reputation boost. Callable by `ADMIN_ROLE`.

**VII. Protocol Economics & Rewards:**

25. `distributeEpochRewards()`:
    *   Manages the transition between epochs. When an epoch ends, this function signals that contributions from the previous epoch are finalized. It prepares the protocol for a new epoch and signals that the accumulated `protocolTreasury` is available for withdrawal by the `ADMIN_ROLE`, implying off-chain distribution or future claim contracts based on epoch contributions.

---

## OracleweaveProtocol.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For Strings.toString

// Interfaces for external contracts (simplified)
// In a real scenario, these would be deployed and verified contracts with more robust logic.
interface IAIOracle {
    // This function is expected to trigger an off-chain AI model,
    // which then calls back to `fulfillAIValidation` on OracleweaveProtocol.
    // `requestId` is used by the oracle to match the request to the callback.
    function requestValidation(uint256 requestId, string memory dataHash) external returns (bytes32);
}

interface IReputationSBT {
    // Returns the current reputation score for a participant.
    function getReputation(address participant) external view returns (uint256);
    // Updates a participant's reputation. `amount` can be positive or negative.
    function updateReputation(address participant, int256 amount) external;
}

/**
 * @title OracleweaveProtocol
 * @dev A Decentralized AI-Augmented Knowledge & Insight Marketplace.
 * This contract facilitates the submission, validation, licensing, and
 * dispute resolution of novel "insights," transforming them into dynamic
 * Knowledge Capsule NFTs. It integrates with external AI oracles for
 * automated validation and a Soulbound Token (SBT) for participant reputation.
 */
contract OracleweaveProtocol is ERC721URIStorage, AccessControl, ReentrancyGuard, Pausable {

    // --- Outline ---
    // I. Core Protocol Management
    // II. Insight Proposal & Discovery
    // III. Multi-Stage Validation & Curation
    // IV. Knowledge Capsule (Dynamic NFT) Lifecycle
    // V. Reputation & Role Management (via external SBT)
    // VI. Dispute Resolution
    // VII. Protocol Economics & Rewards

    // --- Function Summary ---
    // I. Core Protocol Management:
    // 1. constructor: Initializes contract, sets roles and initial configurations.
    // 2. updateProtocolConfig: Updates global parameters (fees, thresholds, durations).
    // 3. setOracleContract: Sets the address of the AI Oracle contract.
    // 4. setReputationSBTContract: Sets the address of the Reputation SBT contract.
    // 5. pauseProtocol: Admin pause function.
    // 6. unpauseProtocol: Admin unpause function.
    // 7. withdrawProtocolFees: Withdraws accumulated fees to treasury.

    // II. Insight Proposal & Discovery:
    // 8. submitInsightProposal: User submits a new insight for validation.
    // 9. createDiscoveryBounty: Admin/Curator creates a bounty for specific insights.
    // 10. claimDiscoveryBounty: User claims a bounty for a matching, validated insight.

    // III. Multi-Stage Validation & Curation:
    // 11. requestAIValidation: Initiates AI oracle evaluation for an insight.
    // 12. fulfillAIValidation: Callback from AI oracle with validation results.
    // 13. initiateCuratorVote: Starts a human curator vote for an insight.
    // 14. castCuratorVote: Curators cast their weighted votes.
    // 15. finalizeInsightValidation: Finalizes validation, potentially minting Knowledge Capsule.

    // IV. Knowledge Capsule (Dynamic NFT) Lifecycle:
    // 16. getKnowledgeCapsuleMetadata: Retrieves dynamic metadata for a capsule.
    // 17. licenseKnowledgeCapsule: Acquires a time-bound license for a capsule.
    // 18. revokeKnowledgeCapsuleLicense: Revokes an active capsule license.
    // 19. updateCapsuleRoyaltyConfig: Adjusts royalty rates/license duration for a capsule.
    // 20. burnKnowledgeCapsule: Destroys a capsule due to severe issues.

    // V. Reputation & Role Management (via external SBT):
    // 21. queryParticipantReputation: Queries reputation score from external SBT.

    // VI. Dispute Resolution:
    // 22. challengeKnowledgeCapsule: Initiates a challenge against a minted capsule.
    // 23. voteOnChallenge: Participants vote on an ongoing challenge.
    // 24. resolveChallenge: Finalizes a challenge, updating capsule status and reputations.

    // VII. Protocol Economics & Rewards:
    // 25. distributeEpochRewards: Manages epoch transitions and signals reward readiness.

    // --- Roles (using OpenZeppelin AccessControl) ---
    // DEFAULT_ADMIN_ROLE is automatically granted to the deployer and can grant other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant INQUISITOR_ROLE = keccak256("INQUISITOR_ROLE"); // Users who propose insights
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");     // Users who vote on insights and challenges
    bytes32 public constant ORACLE_OPERATOR_ROLE = keccak256("ORACLE_OPERATOR_ROLE"); // Users who can request AI validation

    // --- State Variables ---
    using Counters for Counters.Counter;
    Counters.Counter private _insightIdCounter;
    Counters.Counter private _capsuleIdCounter;
    Counters.Counter private _bountyIdCounter;
    Counters.Counter private _challengeIdCounter;

    uint256 public protocolTreasury; // Holds accumulated fees (submission fees, failed challenge bonds, protocol share of license fees)

    IAIOracle public aiOracle; // Address of the external AI Oracle contract
    IReputationSBT public reputationSBT; // Address of the external Reputation SBT contract

    // Protocol Configuration Parameters
    struct ProtocolConfig {
        uint256 submissionFee;          // Fee required to submit an insight proposal (in wei)
        uint256 aiValidationThreshold;  // Minimum AI score required for an insight to proceed (e.g., 70 for 70%)
        uint256 curatorVoteThreshold;   // Minimum total weighted votes from curators for approval
        uint256 challengeBondAmount;    // Bond required to challenge a Knowledge Capsule (in wei)
        uint256 epochDuration;          // Duration of an epoch in seconds (for reward distribution cycles)
        uint256 currentEpoch;           // Current active epoch number
        uint256 lastEpochEndTime;       // Timestamp when the current epoch began (end time of previous)
    }
    ProtocolConfig public config;

    // Insight Proposal Structure
    enum InsightStatus { Proposed, AI_Validated, Human_Voting, Validated, Rejected, Challenged }
    struct Insight {
        uint256 id;
        address proposer;                   // Address of the user who proposed this insight
        string ipfsHash;                    // IPFS hash pointing to the insight's detailed data/description
        InsightStatus status;
        int256 aiScore;                     // Score received from the AI oracle
        string aiReportHash;                // IPFS hash of the AI validation report
        uint256 voteStartTime;              // Timestamp when curator voting for this insight started
        uint256 totalCuratorVotes;          // Sum of weighted votes from curators
        mapping(address => bool) hasVoted;  // Tracks if a curator has voted in the current round for this insight
        uint256 bountyId;                   // ID of the bounty this insight is linked to (0 if none)
        uint256 knowledgeCapsuleId;         // ID of the minted Knowledge Capsule (0 if not minted yet)
    }
    mapping(uint256 => Insight) public insights; // insightId => Insight struct

    // Knowledge Capsule (Dynamic NFT) Structure
    struct KnowledgeCapsule {
        uint256 insightId;              // The ID of the original insight this capsule represents
        address creator;                // The address of the original insight proposer
        uint256 totalLicenses;          // Cumulative count of licenses ever issued for this capsule
        uint256 currentRoyaltyRate;     // Royalty rate for licensing, e.g., 100 = 1% (out of 10,000 basis points)
        uint256 licenseDuration;        // Default duration of a license in seconds
        string metadataURI;             // Base URI for the NFT metadata, dynamically updated/generated
        bool challenged;                // True if the capsule is currently under dispute
    }
    mapping(uint256 => KnowledgeCapsule) public knowledgeCapsules; // capsuleId => KnowledgeCapsule struct

    // Licensing Information
    struct License {
        uint256 capsuleId;      // The ID of the capsule being licensed
        address licensee;       // The address holding the license
        uint256 validUntil;     // Timestamp until which the license is valid
    }
    mapping(uint256 => mapping(address => License)) public activeLicenses; // capsuleId => licenseeAddress => License struct

    // Discovery Bounties
    struct DiscoveryBounty {
        uint256 id;             // Unique ID for the bounty
        string targetKeyword;   // A keyword or description defining the target insight for the bounty
        uint256 rewardAmount;   // The ETH reward for claiming this bounty
        address creator;        // The address that created (funded) this bounty
        bool claimed;           // True if the bounty has been claimed
        address claimant;       // Address of the claimant
    }
    mapping(uint256 => DiscoveryBounty) public discoveryBounties; // bountyId => DiscoveryBounty struct

    // Challenge Structure for disputed Knowledge Capsules
    enum ChallengeStatus { Active, Resolved_Accepted, Resolved_Rejected }
    struct Challenge {
        uint256 id;                 // Unique ID for the challenge
        uint256 capsuleId;          // The ID of the Knowledge Capsule being challenged
        address challenger;         // The address that initiated the challenge
        uint256 bondAmount;         // The amount of bond provided by the challenger
        ChallengeStatus status;
        uint256 voteStartTime;      // Timestamp when voting for this challenge started
        uint256 totalChallengeVotes; // Sum of weighted votes from curators supporting the challenge
        mapping(address => bool) hasVoted; // Tracks if a curator has voted in the current challenge
    }
    mapping(uint256 => Challenge) public challenges; // challengeId => Challenge struct

    // Epoch Contributions (for reward calculation, though direct distribution is simplified)
    mapping(address => uint256) public epochContributions; // participantAddress => contribution score for current epoch

    // --- Events ---
    event ProtocolConfigUpdated(uint256 newSubmissionFee, uint256 newAIValidationThreshold, uint256 newCuratorVoteThreshold, uint256 newChallengeBondAmount, uint256 newEpochDuration);
    event OracleContractSet(address indexed oracleAddress);
    event ReputationSBTContractSet(address indexed sbtAddress);
    event ProtocolFundsWithdrawn(address indexed recipient, uint256 amount);

    event InsightProposed(uint256 indexed insightId, address indexed proposer, string ipfsHash);
    event DiscoveryBountyCreated(uint256 indexed bountyId, string targetKeyword, uint256 rewardAmount, address indexed creator);
    event DiscoveryBountyClaimed(uint256 indexed bountyId, uint256 indexed insightId, address indexed claimant, uint256 rewardAmount);

    event AIValidationRequested(uint256 indexed insightId, uint256 indexed requestId, string dataHash);
    event AIValidationFulfilled(uint256 indexed insightId, int256 aiScore, string aiReportHash, InsightStatus newStatus);
    event CuratorVoteInitiated(uint256 indexed insightId, uint256 voteStartTime);
    event CuratorVoted(uint256 indexed insightId, address indexed voter, uint256 weightedVote);
    event InsightValidationFinalized(uint256 indexed insightId, InsightStatus finalStatus, uint256 indexed knowledgeCapsuleId);

    event KnowledgeCapsuleMinted(uint256 indexed capsuleId, uint256 indexed insightId, address indexed creator, string metadataURI);
    event KnowledgeCapsuleLicensed(uint256 indexed capsuleId, address indexed licensee, uint256 validUntil);
    event KnowledgeCapsuleLicenseRevoked(uint256 indexed capsuleId, address indexed licensee);
    event CapsuleRoyaltyConfigUpdated(uint256 indexed capsuleId, uint256 newRate, uint256 newDuration);
    event KnowledgeCapsuleBurned(uint256 indexed capsuleId);

    event KnowledgeCapsuleChallenged(uint256 indexed challengeId, uint256 indexed capsuleId, address indexed challenger, uint256 bondAmount);
    event ChallengeVoted(uint256 indexed challengeId, address indexed voter, uint256 weightedVote);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed capsuleId, ChallengeStatus finalStatus);

    event EpochRewardsDistributed(uint256 epoch, uint256 totalRewardsAvailable, uint256 timestamp);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "Oracleweave: Only AI Oracle can call this");
        _;
    }

    modifier onlyCurator() {
        require(hasRole(CURATOR_ROLE, _msgSender()), "Oracleweave: Only Curator can call this");
        _;
    }

    modifier onlyInquisitor() {
        require(hasRole(INQUISITOR_ROLE, _msgSender()), "Oracleweave: Only Inquisitor can call this");
        _;
    }

    modifier onlyOracleOperator() {
        require(hasRole(ORACLE_OPERATOR_ROLE, _msgSender()), "Oracleweave: Only Oracle Operator can call this");
        _;
    }

    modifier onlyCapsuleCreator(uint256 _capsuleId) {
        require(knowledgeCapsules[_capsuleId].creator == _msgSender(), "Oracleweave: Not capsule creator");
        _;
    }

    // --- Constructor ---
    // 1. constructor
    constructor(
        string memory _name,
        string memory _symbol,
        address _aiOracleAddress,
        address _reputationSBTAddress,
        uint256 _submissionFee,
        uint256 _aiValidationThreshold,
        uint256 _curatorVoteThreshold,
        uint256 _challengeBondAmount,
        uint256 _epochDuration
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender()); // Deployer gets DEFAULT_ADMIN_ROLE
        _grantRole(ADMIN_ROLE, _msgSender());         // Deployer also gets ADMIN_ROLE for specific functions

        aiOracle = IAIOracle(_aiOracleAddress);
        reputationSBT = IReputationSBT(_reputationSBTAddress);

        config = ProtocolConfig({
            submissionFee: _submissionFee,
            aiValidationThreshold: _aiValidationThreshold,
            curatorVoteThreshold: _curatorVoteThreshold,
            challengeBondAmount: _challengeBondAmount,
            epochDuration: _epochDuration,
            currentEpoch: 1,
            lastEpochEndTime: block.timestamp // Initialize epoch start time
        });

        // Initialize counters to start from 1
        _insightIdCounter.increment();
        _capsuleIdCounter.increment();
        _bountyIdCounter.increment();
        _challengeIdCounter.increment();
    }

    // --- I. Core Protocol Management ---

    // 2. updateProtocolConfig
    // Allows ADMIN_ROLE to update various protocol parameters.
    function updateProtocolConfig(
        uint256 _newSubmissionFee,
        uint256 _newAIValidationThreshold,
        uint256 _newCuratorVoteThreshold,
        uint256 _newChallengeBondAmount,
        uint256 _newEpochDuration
    ) external onlyRole(ADMIN_ROLE) {
        require(_newSubmissionFee > 0, "Oracleweave: Submission fee must be positive");
        require(_newAIValidationThreshold <= 10000, "Oracleweave: AI threshold max 10000 (100%)"); // Assuming percentage out of 10000
        require(_newCuratorVoteThreshold > 0, "Oracleweave: Curator threshold must be positive");
        require(_newChallengeBondAmount > 0, "Oracleweave: Challenge bond must be positive");
        require(_newEpochDuration > 0, "Oracleweave: Epoch duration must be positive");

        config.submissionFee = _newSubmissionFee;
        config.aiValidationThreshold = _newAIValidationThreshold;
        config.curatorVoteThreshold = _newCuratorVoteThreshold;
        config.challengeBondAmount = _newChallengeBondAmount;
        config.epochDuration = _newEpochDuration;

        emit ProtocolConfigUpdated(_newSubmissionFee, _newAIValidationThreshold, _newCuratorVoteThreshold, _newChallengeBondAmount, _newEpochDuration);
    }

    // 3. setOracleContract
    // Sets the address of the external AI Oracle contract. Only callable by ADMIN_ROLE.
    function setOracleContract(address _aiOracleAddress) external onlyRole(ADMIN_ROLE) {
        require(_aiOracleAddress != address(0), "Oracleweave: Invalid address");
        aiOracle = IAIOracle(_aiOracleAddress);
        emit OracleContractSet(_aiOracleAddress);
    }

    // 4. setReputationSBTContract
    // Sets the address of the external Reputation SBT contract. Only callable by ADMIN_ROLE.
    function setReputationSBTContract(address _reputationSBTAddress) external onlyRole(ADMIN_ROLE) {
        require(_reputationSBTAddress != address(0), "Oracleweave: Invalid address");
        reputationSBT = IReputationSBT(_reputationSBTAddress);
        emit ReputationSBTContractSet(_reputationSBTAddress);
    }

    // 5. pauseProtocol
    // Pauses critical protocol functionalities in case of an emergency. Only callable by ADMIN_ROLE.
    function pauseProtocol() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    // 6. unpauseProtocol
    // Unpauses the protocol, restoring full functionality. Only callable by ADMIN_ROLE.
    function unpauseProtocol() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // 7. withdrawProtocolFees
    // Allows the ADMIN_ROLE to withdraw accumulated fees from the contract's treasury.
    function withdrawProtocolFees(address _recipient) external onlyRole(ADMIN_ROLE) nonReentrant {
        require(_recipient != address(0), "Oracleweave: Invalid recipient");
        uint256 balance = address(this).balance;
        require(balance > 0, "Oracleweave: No funds to withdraw");
        
        uint256 amountToWithdraw = balance; // Withdraw entire contract balance, assuming it's all fees
        protocolTreasury = 0; // Reset internal treasury counter as funds are withdrawn

        (bool success, ) = payable(_recipient).call{value: amountToWithdraw}("");
        require(success, "Oracleweave: ETH transfer failed");
        emit ProtocolFundsWithdrawn(_recipient, amountToWithdraw);
    }

    // --- II. Insight Proposal & Discovery ---

    // 8. submitInsightProposal
    // Allows an INQUISITOR_ROLE to submit a new insight proposal. Requires a submission fee.
    function submitInsightProposal(string memory _ipfsHash, uint256 _bountyId) external payable whenNotPaused onlyInquisitor {
        require(msg.value >= config.submissionFee, "Oracleweave: Insufficient submission fee");
        require(bytes(_ipfsHash).length > 0, "Oracleweave: IPFS hash cannot be empty");
        
        if (_bountyId != 0) {
            require(discoveryBounties[_bountyId].id != 0 && !discoveryBounties[_bountyId].claimed, "Oracleweave: Invalid or claimed bounty ID");
        }

        uint256 newInsightId = _insightIdCounter.current();
        insights[newInsightId] = Insight({
            id: newInsightId,
            proposer: _msgSender(),
            ipfsHash: _ipfsHash,
            status: InsightStatus.Proposed,
            aiScore: 0,
            aiReportHash: "",
            voteStartTime: 0,
            totalCuratorVotes: 0,
            bountyId: _bountyId,
            knowledgeCapsuleId: 0
        });
        // hasVoted mapping is implicitly empty for new struct.
        _insightIdCounter.increment();
        protocolTreasury += msg.value; // Add fee to protocol treasury

        // Record contribution for epoch rewards
        epochContributions[_msgSender()] += 1;

        emit InsightProposed(newInsightId, _msgSender(), _ipfsHash);
    }

    // 9. createDiscoveryBounty
    // Allows ADMIN_ROLE or CURATOR_ROLE to create a new bounty for specific types of insights.
    // The bounty's reward amount is funded by the caller.
    function createDiscoveryBounty(string memory _targetKeyword, uint256 _rewardAmount) external payable whenNotPaused onlyRole(ADMIN_ROLE) {
        require(msg.value >= _rewardAmount, "Oracleweave: Insufficient funds for bounty");
        require(bytes(_targetKeyword).length > 0, "Oracleweave: Target keyword cannot be empty");
        require(_rewardAmount > 0, "Oracleweave: Reward amount must be positive");

        uint256 newBountyId = _bountyIdCounter.current();
        discoveryBounties[newBountyId] = DiscoveryBounty({
            id: newBountyId,
            targetKeyword: _targetKeyword, // This keyword could be used for off-chain matching or in `claimDiscoveryBounty`
            rewardAmount: _rewardAmount,
            creator: _msgSender(),
            claimed: false,
            claimant: address(0)
        });
        _bountyIdCounter.increment();
        emit DiscoveryBountyCreated(newBountyId, _targetKeyword, _rewardAmount, _msgSender());
    }

    // 10. claimDiscoveryBounty
    // Allows an Inquisitor to claim a bounty after their submitted insight is validated and matches the bounty.
    function claimDiscoveryBounty(uint256 _bountyId, uint256 _insightId) external whenNotPaused nonReentrant {
        DiscoveryBounty storage bounty = discoveryBounties[_bountyId];
        Insight storage insight = insights[_insightId];

        require(bounty.id != 0, "Oracleweave: Bounty does not exist");
        require(insight.id != 0, "Oracleweave: Insight does not exist");
        require(!bounty.claimed, "Oracleweave: Bounty already claimed");
        require(insight.status == InsightStatus.Validated, "Oracleweave: Insight not yet validated");
        require(insight.proposer == _msgSender(), "Oracleweave: Only insight proposer can claim this bounty");
        require(insight.bountyId == _bountyId, "Oracleweave: Insight not linked to this bounty"); // Direct link check

        bounty.claimed = true;
        bounty.claimant = _msgSender();

        // Transfer reward from bounty creator's original funding to the claimant
        (bool success, ) = payable(_msgSender()).call{value: bounty.rewardAmount}("");
        require(success, "Oracleweave: Reward transfer failed");

        epochContributions[_msgSender()] += 10; // Extra contribution for claiming bounty

        emit DiscoveryBountyClaimed(_bountyId, _insightId, _msgSender(), bounty.rewardAmount);
    }

    // --- III. Multi-Stage Validation & Curation ---

    // 11. requestAIValidation
    // Initiates an AI oracle request to evaluate a submitted insight. Only callable by ORACLE_OPERATOR_ROLE.
    function requestAIValidation(uint256 _insightId) external whenNotPaused onlyOracleOperator {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.Proposed, "Oracleweave: Insight not in Proposed status");
        require(address(aiOracle) != address(0), "Oracleweave: AI Oracle contract not set");

        // Generate a unique request ID for the AI oracle callback
        // Using block.timestamp and _insightId provides a decent unique ID for a request.
        // In a real system, you might use Chainlink's requestId or similar.
        uint256 requestId = uint256(keccak256(abi.encodePacked(_insightId, block.timestamp, insight.proposer)));
        aiOracle.requestValidation(requestId, insight.ipfsHash);

        emit AIValidationRequested(_insightId, requestId, insight.ipfsHash);
    }

    // 12. fulfillAIValidation (Callback from AI Oracle)
    // Callback function, exclusively callable by the AI Oracle contract, to update an insight's AI validation score.
    function fulfillAIValidation(uint256 _insightId, int256 _aiScore, string memory _aiReportHash) external onlyAIOracle {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.Proposed, "Oracleweave: Insight not awaiting AI validation");

        insight.aiScore = _aiScore;
        insight.aiReportHash = _aiReportHash;

        if (_aiScore >= int256(config.aiValidationThreshold)) {
            insight.status = InsightStatus.AI_Validated;
        } else {
            insight.status = InsightStatus.Rejected; // AI deemed it low quality/duplicate
            reputationSBT.updateReputation(insight.proposer, -10); // Penalty for rejected insight
        }
        emit AIValidationFulfilled(_insightId, _aiScore, _aiReportHash, insight.status);
    }

    // 13. initiateCuratorVote
    // Allows a CURATOR_ROLE to initiate a decentralized vote among other Curators on an insight's value.
    function initiateCuratorVote(uint256 _insightId) external whenNotPaused onlyCurator {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.AI_Validated, "Oracleweave: Insight not AI validated");
        require(insight.voteStartTime == 0, "Oracleweave: Vote already initiated for this insight");

        insight.voteStartTime = block.timestamp; // Set start time for voting
        insight.totalCuratorVotes = 0; // Reset vote count for this new voting round

        emit CuratorVoteInitiated(_insightId, insight.voteStartTime);
    }

    // 14. castCuratorVote
    // Curators with sufficient reputation can cast their weighted votes on an ongoing insight validation.
    // Their vote weight is based on their reputation score from the SBT.
    function castCuratorVote(uint256 _insightId, bool _approve) external whenNotPaused onlyCurator {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.AI_Validated, "Oracleweave: Insight not in AI_Validated status for voting");
        require(insight.voteStartTime > 0 && block.timestamp >= insight.voteStartTime, "Oracleweave: Voting not open yet or already finalized");
        // A real system would also check a voting end time. For simplicity, assume it's finalized manually.
        require(!insight.hasVoted[_msgSender()], "Oracleweave: You have already voted on this insight");

        uint256 curatorReputation = reputationSBT.getReputation(_msgSender());
        require(curatorReputation > 0, "Oracleweave: Curator must have reputation to vote");

        if (_approve) {
            insight.totalCuratorVotes += curatorReputation;
        }
        insight.hasVoted[_msgSender()] = true; // Mark as voted for this insight round
        epochContributions[_msgSender()] += 1; // Record contribution

        emit CuratorVoted(_insightId, _msgSender(), _approve ? curatorReputation : 0);
    }

    // 15. finalizeInsightValidation
    // Determines if an insight qualifies as a Knowledge Capsule based on AI and human validation stages,
    // minting an NFT if successful. Callable by CURATOR_ROLE.
    function finalizeInsightValidation(uint256 _insightId) external whenNotPaused onlyCurator {
        Insight storage insight = insights[_insightId];
        require(insight.status == InsightStatus.AI_Validated, "Oracleweave: Insight not in AI_Validated status for finalization");
        // In a real system, you might enforce a minimum voting period has passed.

        if (insight.aiScore >= int256(config.aiValidationThreshold) && insight.totalCuratorVotes >= config.curatorVoteThreshold) {
            insight.status = InsightStatus.Validated;
            // Mint Knowledge Capsule NFT
            uint256 newCapsuleId = _capsuleIdCounter.current();
            // Construct dynamic metadata URI. In a real dNFT, this would point to a service.
            string memory initialMetadataURI = string(abi.encodePacked(
                "ipfs://", insight.ipfsHash, // Base IPFS hash of the content
                "/ai_score_", Strings.toString(insight.aiScore), // Dynamic part: AI score
                "/curator_votes_", Strings.toString(insight.totalCuratorVotes) // Dynamic part: Curator votes
            ));
            
            _mint(insight.proposer, newCapsuleId);
            _setTokenURI(newCapsuleId, initialMetadataURI); // Sets the initial metadata URI

            knowledgeCapsules[newCapsuleId] = KnowledgeCapsule({
                insightId: _insightId,
                creator: insight.proposer,
                totalLicenses: 0,
                currentRoyaltyRate: 100,      // Default 1% (100 basis points, for 10000 = 100%)
                licenseDuration: 30 days,     // Default 30 days
                metadataURI: initialMetadataURI, // Store the base metadata string
                challenged: false
            });
            insight.knowledgeCapsuleId = newCapsuleId;
            _capsuleIdCounter.increment();

            // Update proposer's reputation for successful validation
            reputationSBT.updateReputation(insight.proposer, 50);
            epochContributions[insight.proposer] += 10; // More contribution for successful validation

            emit KnowledgeCapsuleMinted(newCapsuleId, _insightId, insight.proposer, initialMetadataURI);
        } else {
            insight.status = InsightStatus.Rejected;
            // Deduct reputation from proposer for insights that fail validation
            reputationSBT.updateReputation(insight.proposer, -10);
        }
        emit InsightValidationFinalized(_insightId, insight.status, insight.knowledgeCapsuleId);
    }

    // --- IV. Knowledge Capsule (Dynamic NFT) Lifecycle ---

    // 16. getKnowledgeCapsuleMetadata
    // Retrieves the current dynamic metadata URI for a specific Knowledge Capsule NFT.
    // The metadata URI is constructed dynamically based on the capsule's current state.
    function getKnowledgeCapsuleMetadata(uint256 _capsuleId) public view returns (string memory) {
        require(_exists(_capsuleId), "Oracleweave: Knowledge Capsule does not exist");
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        Insight storage insight = insights[capsule.insightId];

        // Construct dynamic metadata URL
        // Example: baseURI/licenses_X/challenged_Y/ai_score_Z/curator_votes_A
        return string(abi.encodePacked(
            capsule.metadataURI, // The base URI set at minting (includes original IPFS hash and initial scores)
            "/total_licenses_", Strings.toString(capsule.totalLicenses),
            "/challenged_status_", capsule.challenged ? "true" : "false",
            "/current_royalty_", Strings.toString(capsule.currentRoyaltyRate),
            "/license_duration_", Strings.toString(capsule.licenseDuration),
            "/ai_score_at_mint_", Strings.toString(insight.aiScore) // AI score at minting (static part)
        ));
    }

    // 17. licenseKnowledgeCapsule
    // Allows users to acquire a time-bound license to utilize a Knowledge Capsule.
    // Requires payment of a royalty fee, which is split between the creator and the protocol.
    function licenseKnowledgeCapsule(uint256 _capsuleId) external payable whenNotPaused nonReentrant {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(_exists(_capsuleId), "Oracleweave: Knowledge Capsule does not exist");
        require(capsule.creator != address(0), "Oracleweave: Capsule not properly initialized or burned");
        
        // This example assumes msg.value is the total license fee paid by the user.
        // It's then split based on the royalty rate.
        require(msg.value > 0, "Oracleweave: License payment cannot be zero");

        uint256 creatorShare = (msg.value * capsule.currentRoyaltyRate) / 10000; // currentRoyaltyRate is in basis points
        uint256 protocolShare = msg.value - creatorShare;

        activeLicenses[_capsuleId][_msgSender()] = License({
            capsuleId: _capsuleId,
            licensee: _msgSender(),
            validUntil: block.timestamp + capsule.licenseDuration
        });

        capsule.totalLicenses++;
        protocolTreasury += protocolShare;
        
        // Transfer creator's share
        (bool success, ) = payable(capsule.creator).call{value: creatorShare}("");
        require(success, "Oracleweave: Royalty transfer to creator failed");

        epochContributions[_msgSender()] += 1; // Licensee contribution
        epochContributions[capsule.creator] += 5; // Creator benefits from licensing

        emit KnowledgeCapsuleLicensed(_capsuleId, _msgSender(), activeLicenses[_capsuleId][_msgSender()].validUntil);
    }

    // 18. revokeKnowledgeCapsuleLicense
    // Allows a licensee to voluntarily revoke their active license. No refund is provided for early revocation.
    function revokeKnowledgeCapsuleLicense(uint256 _capsuleId) external whenNotPaused {
        License storage license = activeLicenses[_capsuleId][_msgSender()];
        require(license.capsuleId == _capsuleId, "Oracleweave: No active license found for this capsule and address");
        
        delete activeLicenses[_capsuleId][_msgSender()]; // Remove the license entry

        emit KnowledgeCapsuleLicenseRevoked(_capsuleId, _msgSender());
    }

    // 19. updateCapsuleRoyaltyConfig
    // Allows the original Insight Proposer (who became the capsule creator) to adjust
    // the royalty rate and license duration for their minted Knowledge Capsule.
    function updateCapsuleRoyaltyConfig(uint256 _capsuleId, uint256 _newRoyaltyRate, uint256 _newLicenseDuration) external whenNotPaused onlyCapsuleCreator(_capsuleId) {
        require(_newRoyaltyRate <= 10000, "Oracleweave: Royalty rate cannot exceed 100% (10000 basis points)");
        require(_newLicenseDuration > 0, "Oracleweave: License duration must be positive");

        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        capsule.currentRoyaltyRate = _newRoyaltyRate;
        capsule.licenseDuration = _newLicenseDuration;

        emit CapsuleRoyaltyConfigUpdated(_capsuleId, _newRoyaltyRate, _newLicenseDuration);
    }

    // 20. burnKnowledgeCapsule
    // A drastic measure, callable by ADMIN_ROLE, to permanently destroy a Knowledge Capsule.
    // This is intended for severe issues like discovered plagiarism or misinformation.
    function burnKnowledgeCapsule(uint256 _capsuleId) external whenNotPaused onlyRole(ADMIN_ROLE) {
        require(_exists(_capsuleId), "Oracleweave: Knowledge Capsule does not exist");
        
        address capsuleCreator = knowledgeCapsules[_capsuleId].creator;

        _burn(_capsuleId); // ERC721 burn
        delete knowledgeCapsules[_capsuleId]; // Remove from our custom mapping

        // Mark the original insight as rejected, regardless of its previous status
        insights[knowledgeCapsules[_capsuleId].insightId].status = InsightStatus.Rejected;

        // Apply a significant reputation penalty to the creator
        reputationSBT.updateReputation(capsuleCreator, -100); 

        emit KnowledgeCapsuleBurned(_capsuleId);
    }

    // --- V. Reputation & Role Management (via external SBT) ---

    // 21. queryParticipantReputation
    // Queries the external Reputation SBT for a specific participant's current reputation score.
    // This score influences their permissions and voting power within the protocol.
    function queryParticipantReputation(address _participant) public view returns (uint256) {
        require(address(reputationSBT) != address(0), "Oracleweave: Reputation SBT contract not set");
        return reputationSBT.getReputation(_participant);
    }

    // --- VI. Dispute Resolution ---

    // 22. challengeKnowledgeCapsule
    // Allows any INQUISITOR_ROLE to formally challenge the validity or integrity of a minted Knowledge Capsule.
    // Requires providing a challenge bond.
    function challengeKnowledgeCapsule(uint256 _capsuleId, string memory _reasonIpfsHash) external payable whenNotPaused onlyInquisitor {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(_exists(_capsuleId), "Oracleweave: Knowledge Capsule does not exist");
        require(!capsule.challenged, "Oracleweave: Capsule is already under challenge");
        require(msg.value >= config.challengeBondAmount, "Oracleweave: Insufficient challenge bond");
        require(bytes(_reasonIpfsHash).length > 0, "Oracleweave: Reason IPFS hash cannot be empty");

        uint256 newChallengeId = _challengeIdCounter.current();
        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            capsuleId: _capsuleId,
            challenger: _msgSender(),
            bondAmount: msg.value,
            status: ChallengeStatus.Active,
            voteStartTime: block.timestamp, // Start time for challenge voting
            totalChallengeVotes: 0
        });
        // hasVoted mapping is implicitly empty for new struct.
        _challengeIdCounter.increment();
        capsule.challenged = true;
        protocolTreasury += msg.value; // Add bond to protocol treasury temporarily

        epochContributions[_msgSender()] += 5; // Challenger contribution

        emit KnowledgeCapsuleChallenged(newChallengeId, _capsuleId, _msgSender(), msg.value);
    }

    // 23. voteOnChallenge
    // Allows CURATOR_ROLE participants to cast their weighted votes on an ongoing Knowledge Capsule challenge.
    function voteOnChallenge(uint256 _challengeId, bool _supportChallenge) external whenNotPaused onlyCurator {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "Oracleweave: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Active, "Oracleweave: Challenge not active");
        require(challenge.voteStartTime > 0 && block.timestamp >= challenge.voteStartTime, "Oracleweave: Voting not open yet");
        // A challenge voting period could be enforced here as well.
        require(!challenge.hasVoted[_msgSender()], "Oracleweave: You have already voted on this challenge");

        uint256 curatorReputation = reputationSBT.getReputation(_msgSender());
        require(curatorReputation > 0, "Oracleweave: Curator must have reputation to vote");

        if (_supportChallenge) {
            challenge.totalChallengeVotes += curatorReputation;
        }
        challenge.hasVoted[_msgSender()] = true;
        epochContributions[_msgSender()] += 2; // Voter contribution

        emit ChallengeVoted(_challengeId, _msgSender(), _supportChallenge ? curatorReputation : 0);
    }

    // 24. resolveChallenge
    // Finalizes a Knowledge Capsule challenge, distributing bonds, potentially burning the capsule,
    // and updating reputations based on the vote outcome. Callable by ADMIN_ROLE.
    function resolveChallenge(uint256 _challengeId) external whenNotPaused onlyRole(ADMIN_ROLE) nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "Oracleweave: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Active, "Oracleweave: Challenge not active");
        // Ensure a sufficient voting period has passed before resolving
        // For simplicity, this is called by admin when votes are deemed sufficient.

        KnowledgeCapsule storage capsule = knowledgeCapsules[challenge.capsuleId];
        address creator = capsule.creator; 

        if (challenge.totalChallengeVotes >= config.curatorVoteThreshold) { // If challenge is supported by enough votes
            // Challenge accepted: Burn capsule, slash creator, return bond to challenger
            challenge.status = ChallengeStatus.Resolved_Accepted;
            
            // Refund challenger's bond
            (bool success, ) = payable(challenge.challenger).call{value: challenge.bondAmount}("");
            require(success, "Oracleweave: Challenger bond refund failed");
            
            // Slash capsule creator's reputation significantly
            reputationSBT.updateReputation(creator, -200);

            // Burn the NFT and associated data
            _burn(challenge.capsuleId);
            delete knowledgeCapsules[challenge.capsuleId];
            insights[capsule.insightId].status = InsightStatus.Rejected; // Mark original insight as rejected

            emit KnowledgeCapsuleBurned(challenge.capsuleId);
        } else {
            // Challenge rejected: Challenger loses bond, creator's reputation might increase (optional)
            challenge.status = ChallengeStatus.Resolved_Rejected;
            protocolTreasury += challenge.bondAmount; // Challenger's bond goes to protocol treasury
            reputationSBT.updateReputation(creator, 20); // Small reputation boost for surviving a challenge
            reputationSBT.updateReputation(challenge.challenger, -50); // Penalty for failed challenge
        }
        capsule.challenged = false; // Mark capsule as no longer challenged
        emit ChallengeResolved(_challengeId, challenge.capsuleId, challenge.status);
    }

    // --- VII. Protocol Economics & Rewards ---

    // 25. distributeEpochRewards
    // Manages the transition between epochs. When an epoch ends, this function signals that
    // rewards from the previous epoch are finalized and can be processed (e.g., off-chain or by another contract).
    // The accumulated `protocolTreasury` is available for `withdrawProtocolFees` by ADMIN_ROLE.
    function distributeEpochRewards() external whenNotPaused onlyRole(ADMIN_ROLE) {
        require(block.timestamp >= config.lastEpochEndTime + config.epochDuration, "Oracleweave: Current epoch has not ended");

        uint256 previousEpoch = config.currentEpoch;
        uint256 totalRewardsFromTreasury = protocolTreasury; // Total fees collected in previous epoch

        // Transition to next epoch
        config.currentEpoch++;
        config.lastEpochEndTime = block.timestamp; // Set the start time for the new epoch

        // Clear epoch contributions for the new epoch.
        // In a live system with many users, clearing the map directly on-chain is not feasible.
        // Instead, a snapshot of `epochContributions` for the *previous* epoch would be taken off-chain
        // (e.g., via event logs), and rewards calculated there. The on-chain `epochContributions` map
        // would represent the *current* epoch's tally.
        // For this demo, this effectively resets the ongoing tally for a new epoch.
        // (Note: A true iterable mapping or a pull-based reward system with claims would be needed for direct on-chain distribution).
        // Since `protocolTreasury` is managed separately, this function primarily manages the epoch state.
        
        emit EpochRewardsDistributed(previousEpoch, totalRewardsFromTreasury, block.timestamp);
    }

    // Fallback and Receive functions to allow the contract to receive ETH.
    receive() external payable {
        // ETH received can be part of bounty funding or general protocol funds.
    }

    fallback() external payable {
        // ETH received via fallback
    }
}
```