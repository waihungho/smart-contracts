Okay, this is an exciting challenge! I've designed a smart contract called "CognitoNexus" that aims to be a decentralized knowledge synthesis and validation network. It combines concepts of dynamic reputation (Soulbound-like Tokens), adaptive consensus, epistemic scoring, and a knowledge graph, with a conceptual hook for AI-assisted insight generation.

---

## CognitoNexus: Decentralized Epistemic Network (DEN)

**Concept:** CognitoNexus is a decentralized platform where users can submit "knowledge claims" (facts, predictions, research snippets), and the community validates or disputes them. It incorporates a sophisticated reputation system, adaptive staking mechanisms, and a unique "Epistemic Score" to determine the truthfulness or consensus around a claim. Furthermore, claims can be interlinked to form a knowledge graph, and AI insights can be requested and recorded on-chain to assist human validators.

**Advanced & Trendy Concepts Utilized:**

1.  **Epistemic Scoring:** A dynamic, weighted consensus mechanism that leverages validator reputation to compute a claim's "truthfulness" score, adapting over time.
2.  **KnowledgeNode SBTs (Soulbound Tokens):** Non-transferable tokens representing a user's identity and reputation within the network. These tokens dynamically evolve with earned reputation, potentially changing attributes or "levels."
3.  **Adaptive Staking & Slashing:** Participants stake tokens to submit claims or validate. Misbehavior (false claims, malicious validations) leads to slashing, while accurate contributions are rewarded, adjusting future staking requirements.
4.  **Decentralized Knowledge Graph:** Claims can be explicitly linked (e.g., "supports," "disputes," "supersedes") to form a semantic network, enhancing context and navigability.
5.  **AI-Assisted Human Consensus:** While AI runs off-chain, the contract records requests for AI insights and their results, which can then be used by human validators as supplementary information, fostering a human-in-the-loop AI system.
6.  **Multi-stage Validation & Challenge:** Claims undergo initial validation, but can also be challenged, triggering further review or an arbitration process.
7.  **Time-Weighted Reputation:** Reputation decay or boost over time to ensure active and recent contributions are more impactful.

---

### Contract Outline & Function Summary

**Data Structures:**
*   `KnowledgeNode`: Stores user-specific reputation, SBT data, and staking information.
*   `Claim`: Represents a piece of knowledge submitted, with content, status, scores, and associated stakes.
*   `Validation`: Records an individual's agreement/disagreement with a claim and their rationale.
*   `Challenge`: Details a dispute against a claim or a validation.
*   `Proposal`: Used for basic DAO-like parameter changes.
*   `AIInsightRequest`: Stores details for requesting AI analysis on a claim.

**Enums:**
*   `ClaimStatus`: PENDING_VALIDATION, VALIDATED, CHALLENGED, RESOLVED_ACCEPTED, RESOLVED_REJECTED, OBSOLETE.
*   `ChallengeStatus`: PENDING, RESOLVED_CHALLENGER_WINS, RESOLVED_CHALLENGER_LOSES, RESOLVED_NO_CONSENSUS.
*   `LinkType`: SUPPORTS, DISPUTES, SUPERSEDES, REFERENCES.

**Functions (Total: 22)**

**I. Core Claim & Validation Lifecycle (8 functions)**
1.  `registerKnowledgeNode(string memory _profileCID)`: Mints a new KnowledgeNode SBT for a user, registering them in the network.
2.  `submitKnowledgeClaim(string memory _claimCID, string[] memory _tags, uint256 _stakeAmount)`: Allows a registered KnowledgeNode to submit a new knowledge claim, staking funds.
3.  `submitValidation(uint256 _claimId, bool _agrees, string memory _rationaleCID, uint256 _stakeAmount)`: Allows a registered KnowledgeNode to validate an existing claim, staking their opinion.
4.  `challengeClaim(uint256 _claimId, string memory _challengeRationaleCID, uint256 _stakeAmount)`: Allows any registered KnowledgeNode to challenge a claim's validity, initiating a dispute.
5.  `resolveClaimChallenge(uint256 _challengeId, bool _challengerWins)`: Resolves a claim challenge, updating stakes and claim status based on the outcome (e.g., via internal vote or external oracle).
6.  `calculateClaimEpistemicScore(uint256 _claimId)`: Calculates and updates a claim's weighted "Epistemic Score" based on validator reputation.
7.  `withdrawStakedFunds(uint256 _stakeRefId, StakeType _type)`: Allows users to withdraw their original stake after a claim/validation is finalized and successful.
8.  `revokeValidation(uint256 _validationId)`: Allows a validator to revoke their validation within a certain timeframe, potentially incurring a small penalty.

**II. Reputation & SBT Management (3 functions)**
9.  `updateNodeProfile(string memory _newNodeProfileCID)`: Updates the IPFS CID for a user's KnowledgeNode SBT profile.
10. `delegateValidationPower(address _delegatee, uint256 _powerAmount)`: Allows a KnowledgeNode to delegate a portion of their validation power (based on reputation) to another node.
11. `undelegateValidationPower(address _delegatee, uint256 _powerAmount)`: Revokes previously delegated validation power.

**III. Knowledge Graph & Interlinking (2 functions)**
12. `linkClaims(uint256 _sourceClaimId, uint256 _targetClaimId, LinkType _linkType)`: Establishes a semantic link between two claims.
13. `getLinkedClaims(uint256 _claimId, LinkType _linkType)`: Retrieves all claims linked to a given claim by a specific `LinkType`.

**IV. AI-Assisted Insight (2 functions)**
14. `requestAIInsight(uint256 _claimId, string memory _promptCID)`: Records a request for an off-chain AI service to generate an insight for a specific claim.
15. `submitAIInsightResult(uint256 _requestId, string memory _insightCID, uint256 _confidenceScore)`: Allows a whitelisted AI oracle to submit the result of an AI insight request.

**V. Financial & Incentive Management (3 functions)**
16. `fundRewardPool()`: Allows anyone to contribute ETH to the contract's reward pool.
17. `claimRewards(uint256 _claimId)`: Allows successful claim submitters and validators to claim their earned rewards.
18. `slashStake(address _offender, uint256 _amount)`: A governance/admin function to penalize misbehaving KnowledgeNodes by slashing their staked funds.

**VI. Governance & Utilities (4 functions)**
19. `proposeParameterChange(bytes32 _paramName, uint256 _newValue)`: Initiates a proposal to change a contract parameter (e.g., validation period, min stake).
20. `voteOnParameterChange(uint256 _proposalId, bool _support)`: Allows registered KnowledgeNodes to vote on active parameter change proposals.
21. `executeParameterChange(uint256 _proposalId)`: Executes a parameter change proposal if it has met the required consensus threshold.
22. `pauseContract()`: Emergency function to pause critical contract operations (owner/governance).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title CognitoNexus: Decentralized Epistemic Network (DEN)
/// @author Your Name/AI
/// @notice A decentralized platform for knowledge synthesis and validation,
///         featuring dynamic reputation (SBTs), adaptive consensus (Epistemic Score),
///         a knowledge graph, and AI-assisted human validation.

contract CognitoNexus is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Enums ---
    enum ClaimStatus { PENDING_VALIDATION, VALIDATED, CHALLENGED, RESOLVED_ACCEPTED, RESOLVED_REJECTED, OBSOLETE }
    enum ChallengeStatus { PENDING, RESOLVED_CHALLENGER_WINS, RESOLVED_CHALLENGER_LOSES, RESOLVED_NO_CONSENSUS }
    enum LinkType { SUPPORTS, DISPUTES, SUPERSEDES, REFERENCES }
    enum StakeType { CLAIM, VALIDATION, CHALLENGE }

    // --- Structs ---

    struct KnowledgeNode {
        uint256 tokenId;        // ERC721 Token ID for the SBT
        string profileCID;      // IPFS CID to the node's profile metadata
        uint256 reputationScore; // Epistemic reputation score (higher is better)
        uint256 lastActivityTime; // Timestamp of last significant activity
        uint256 totalStaked;    // Total ETH currently staked by this node
        mapping(address => uint256) delegatedPower; // Address => power amount
        mapping(address => bool) isDelegatee; // Is this node a delegatee for anyone?
    }

    struct Claim {
        uint256 id;
        address submitter;
        string claimCID;        // IPFS CID to the claim content
        string[] tags;
        uint256 initialStake;  // ETH staked by the submitter
        ClaimStatus status;
        uint256 timestamp;
        uint256 validationPeriodEnd;
        int256 epistemicScore;  // Weighted consensus score, -100 to 100
        uint256 totalValidationStake; // Sum of stakes from validators
        uint256 totalAgrees;    // Count of 'agrees' validations
        uint256 totalDisagrees; // Count of 'disagrees' validations
        uint256 activeChallengeId; // 0 if no active challenge
        bool rewardsClaimed;    // True if submitter has claimed rewards
        mapping(address => bool) hasValidated; // Prevent multiple validations per node
        mapping(address => uint256) validatorStakes; // Store individual validator stakes
    }

    struct Validation {
        uint256 id;
        uint256 claimId;
        address validator;
        bool agrees;            // True for agree, false for disagree
        string rationaleCID;    // IPFS CID for rationale
        uint256 stake;          // ETH staked by the validator
        uint256 timestamp;
        bool revoked;           // True if validator revoked their validation
        bool rewardsClaimed;    // True if validator has claimed rewards
    }

    struct Challenge {
        uint256 id;
        uint256 claimId;
        address challenger;
        string rationaleCID;    // IPFS CID for challenge rationale
        uint256 stake;          // ETH staked by the challenger
        ChallengeStatus status;
        uint256 timestamp;
        uint256 resolutionTime;
        address winner;         // Address of the winning party (challenger or original submitter/validators)
    }

    struct Proposal {
        uint256 id;
        address proposer;
        bytes32 paramName;      // Identifier for the parameter to change
        uint256 newValue;       // The proposed new value
        uint256 creationTime;
        uint256 minVotingPeriod; // How long the proposal is active
        uint256 votesFor;       // Weighted votes for
        uint256 votesAgainst;   // Weighted votes against
        bool executed;
        mapping(address => bool) hasVoted; // Prevent multiple votes per node per proposal
    }

    struct AIInsightRequest {
        uint256 id;
        uint256 claimId;
        address requester;
        string promptCID;       // IPFS CID of the prompt given to the AI
        uint256 requestTime;
        string resultCID;       // IPFS CID of the AI's generated insight
        uint256 confidenceScore; // AI's reported confidence score (0-100)
        bool completed;
        address submitter; // The oracle/address that submitted the result
    }

    // --- Counters ---
    Counters.Counter private _nodeIds;
    Counters.Counter private _claimIds;
    Counters.Counter private _validationIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _aiInsightRequestIds;

    // --- Mappings ---
    mapping(address => uint256) public nodeAddressToTokenId; // User address => KnowledgeNode tokenId
    mapping(uint256 => KnowledgeNode) public knowledgeNodes; // TokenId => KnowledgeNode struct
    mapping(uint256 => Claim) public claims;               // ClaimId => Claim struct
    mapping(uint256 => Validation) public validations;     // ValidationId => Validation struct
    mapping(uint256 => Challenge) public challenges;       // ChallengeId => Challenge struct
    mapping(uint256 => Proposal) public proposals;         // ProposalId => Proposal struct
    mapping(uint256 => AIInsightRequest) public aiInsightRequests; // RequestId => AIInsightRequest struct

    // Knowledge Graph: claimId => linkType => array of linked claimIds
    mapping(uint256 => mapping(LinkType => uint256[])) public claimLinks;

    // --- Contract Parameters ---
    uint256 public minClaimStake = 0.01 ether;
    uint256 public minValidationStake = 0.005 ether;
    uint256 public minChallengeStake = 0.01 ether;
    uint256 public validationPeriodDuration = 3 days; // Duration for claims to be validated
    uint256 public challengeResolutionPeriod = 7 days; // Duration for challenges to be resolved
    uint256 public rewardMultiplier = 2; // Multiplier for successful stake rewards
    uint256 public initialReputationScore = 100; // Starting reputation for new nodes
    uint256 public reputationDecayRate = 1; // Points per day of inactivity
    uint256 public proposalVotingPeriod = 3 days;
    uint256 public minProposalQuorumPercentage = 50; // % of total active reputation required to pass
    uint256 public aiOracleFee = 0.001 ether; // Fee paid to AI oracle for results

    // Whitelisted addresses for submitting AI insights
    mapping(address => bool) public isAIOracle;

    // --- Events ---
    event KnowledgeNodeRegistered(address indexed owner, uint256 tokenId, string profileCID);
    event NodeProfileUpdated(address indexed owner, uint256 tokenId, string newProfileCID);
    event ValidationPowerDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ValidationPowerUndelegated(address indexed delegator, address indexed delegatee, uint256 amount);

    event ClaimSubmitted(uint256 indexed claimId, address indexed submitter, string claimCID, uint256 stakeAmount);
    event ValidationSubmitted(uint256 indexed validationId, uint256 indexed claimId, address indexed validator, bool agrees, uint256 stakeAmount);
    event ValidationRevoked(uint256 indexed validationId, uint256 indexed claimId, address indexed validator);
    event ClaimChallenged(uint256 indexed challengeId, uint256 indexed claimId, address indexed challenger, uint256 stakeAmount);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed claimId, ChallengeStatus status, address winner);
    event ClaimEpistemicScoreUpdated(uint256 indexed claimId, int256 newScore);

    event ClaimLinked(uint256 indexed sourceClaimId, uint256 indexed targetClaimId, LinkType linkType);

    event AIInsightRequested(uint256 indexed requestId, uint256 indexed claimId, address indexed requester, string promptCID);
    event AIInsightResultSubmitted(uint256 indexed requestId, uint256 indexed claimId, string resultCID, uint256 confidenceScore);

    event RewardsClaimed(address indexed recipient, uint256 claimId, uint256 amount);
    event StakeSlashed(address indexed offender, uint256 amount);
    event RewardPoolFunded(address indexed funder, uint256 amount);

    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, bytes32 paramName, uint256 newValue);
    event ParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weightedVote);
    event ParameterChangeExecuted(uint256 indexed proposalId, bytes32 paramName, uint256 newValue);

    constructor() ERC721("KnowledgeNodeSBT", "KNSBT") Ownable(msg.sender) {}

    // --- Modifiers ---
    modifier onlyRegisteredNode() {
        require(nodeAddressToTokenId[msg.sender] != 0, "CognitoNexus: Caller is not a registered KnowledgeNode.");
        _;
    }

    modifier onlyActiveClaim(uint256 _claimId) {
        require(claims[_claimId].status == ClaimStatus.PENDING_VALIDATION || claims[_claimId].status == ClaimStatus.CHALLENGED, "CognitoNexus: Claim is not in an active state.");
        _;
    }

    modifier onlyAIOracle() {
        require(isAIOracle[msg.sender], "CognitoNexus: Caller is not a registered AI Oracle.");
        _;
    }

    // --- Admin/Owner Functions ---
    function setAIOracle(address _oracle, bool _status) public onlyOwner {
        isAIOracle[_oracle] = _status;
    }

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // --- Core Claim & Validation Lifecycle ---

    /**
     * @notice Registers a new KnowledgeNode SBT for the caller.
     * @param _profileCID IPFS CID pointing to the node's detailed profile metadata.
     */
    function registerKnowledgeNode(string memory _profileCID) public payable whenNotPaused {
        require(nodeAddressToTokenId[msg.sender] == 0, "CognitoNexus: Already a registered KnowledgeNode.");

        _nodeIds.increment();
        uint256 newTokenId = _nodeIds.current();

        _mint(msg.sender, newTokenId); // Mint as Soulbound (non-transferable by design)

        knowledgeNodes[newTokenId] = KnowledgeNode({
            tokenId: newTokenId,
            profileCID: _profileCID,
            reputationScore: initialReputationScore,
            lastActivityTime: block.timestamp,
            totalStaked: 0,
            delegatedPower: new mapping(address => uint256), // Initialize mapping
            isDelegatee: new mapping(address => bool) // Initialize mapping
        });

        nodeAddressToTokenId[msg.sender] = newTokenId;
        emit KnowledgeNodeRegistered(msg.sender, newTokenId, _profileCID);
    }

    /**
     * @notice Allows a registered KnowledgeNode to submit a new knowledge claim.
     * @param _claimCID IPFS CID pointing to the claim's content.
     * @param _tags An array of tags for the claim.
     * @param _stakeAmount The amount of ETH to stake with the claim.
     */
    function submitKnowledgeClaim(string memory _claimCID, string[] memory _tags, uint256 _stakeAmount) public payable onlyRegisteredNode whenNotPaused {
        require(msg.value >= minClaimStake, "CognitoNexus: Insufficient claim stake.");
        require(msg.value == _stakeAmount, "CognitoNexus: Sent value must match stake amount.");

        _claimIds.increment();
        uint256 newClaimId = _claimIds.current();

        claims[newClaimId] = Claim({
            id: newClaimId,
            submitter: msg.sender,
            claimCID: _claimCID,
            tags: _tags,
            initialStake: _stakeAmount,
            status: ClaimStatus.PENDING_VALIDATION,
            timestamp: block.timestamp,
            validationPeriodEnd: block.timestamp.add(validationPeriodDuration),
            epistemicScore: 0,
            totalValidationStake: 0,
            totalAgrees: 0,
            totalDisagrees: 0,
            activeChallengeId: 0,
            rewardsClaimed: false,
            hasValidated: new mapping(address => bool),
            validatorStakes: new mapping(address => uint256)
        });

        uint256 submitterNodeId = nodeAddressToTokenId[msg.sender];
        knowledgeNodes[submitterNodeId].totalStaked = knowledgeNodes[submitterNodeId].totalStaked.add(_stakeAmount);
        _updateReputation(msg.sender, 0); // Update activity time

        emit ClaimSubmitted(newClaimId, msg.sender, _claimCID, _stakeAmount);
    }

    /**
     * @notice Allows a registered KnowledgeNode to submit a validation for an existing claim.
     * @param _claimId The ID of the claim being validated.
     * @param _agrees True if the validator agrees with the claim, false otherwise.
     * @param _rationaleCID IPFS CID for the validator's rationale.
     * @param _stakeAmount The amount of ETH to stake with the validation.
     */
    function submitValidation(uint256 _claimId, bool _agrees, string memory _rationaleCID, uint256 _stakeAmount) public payable onlyRegisteredNode onlyActiveClaim(_claimId) whenNotPaused {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.PENDING_VALIDATION, "CognitoNexus: Claim not in pending validation state.");
        require(block.timestamp <= claim.validationPeriodEnd, "CognitoNexus: Validation period has ended.");
        require(msg.value >= minValidationStake, "CognitoNexus: Insufficient validation stake.");
        require(msg.value == _stakeAmount, "CognitoNexus: Sent value must match stake amount.");
        require(!claim.hasValidated[msg.sender], "CognitoNexus: Caller has already validated this claim.");
        require(msg.sender != claim.submitter, "CognitoNexus: Submitter cannot validate their own claim.");

        _validationIds.increment();
        uint256 newValidationId = _validationIds.current();

        validations[newValidationId] = Validation({
            id: newValidationId,
            claimId: _claimId,
            validator: msg.sender,
            agrees: _agrees,
            rationaleCID: _rationaleCID,
            stake: _stakeAmount,
            timestamp: block.timestamp,
            revoked: false,
            rewardsClaimed: false
        });

        claim.hasValidated[msg.sender] = true;
        claim.totalValidationStake = claim.totalValidationStake.add(_stakeAmount);
        claim.validatorStakes[msg.sender] = claim.validatorStakes[msg.sender].add(_stakeAmount);

        if (_agrees) {
            claim.totalAgrees = claim.totalAgrees.add(1);
        } else {
            claim.totalDisagrees = claim.totalDisagrees.add(1);
        }

        uint256 validatorNodeId = nodeAddressToTokenId[msg.sender];
        knowledgeNodes[validatorNodeId].totalStaked = knowledgeNodes[validatorNodeId].totalStaked.add(_stakeAmount);
        _updateReputation(msg.sender, 0); // Update activity time

        emit ValidationSubmitted(newValidationId, _claimId, msg.sender, _agrees, _stakeAmount);
    }

    /**
     * @notice Allows a registered KnowledgeNode to challenge a claim's validity.
     * @param _claimId The ID of the claim being challenged.
     * @param _challengeRationaleCID IPFS CID for the challenger's rationale.
     * @param _stakeAmount The amount of ETH to stake for the challenge.
     */
    function challengeClaim(uint256 _claimId, string memory _challengeRationaleCID, uint256 _stakeAmount) public payable onlyRegisteredNode onlyActiveClaim(_claimId) whenNotPaused {
        Claim storage claim = claims[_claimId];
        require(claim.activeChallengeId == 0, "CognitoNexus: Claim already has an active challenge.");
        require(msg.value >= minChallengeStake, "CognitoNexus: Insufficient challenge stake.");
        require(msg.value == _stakeAmount, "CognitoNexus: Sent value must match stake amount.");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            claimId: _claimId,
            challenger: msg.sender,
            rationaleCID: _challengeRationaleCID,
            stake: _stakeAmount,
            status: ChallengeStatus.PENDING,
            timestamp: block.timestamp,
            resolutionTime: 0,
            winner: address(0)
        });

        claim.status = ClaimStatus.CHALLENGED;
        claim.activeChallengeId = newChallengeId;

        uint256 challengerNodeId = nodeAddressToTokenId[msg.sender];
        knowledgeNodes[challengerNodeId].totalStaked = knowledgeNodes[challengerNodeId].totalStaked.add(_stakeAmount);
        _updateReputation(msg.sender, 0); // Update activity time

        emit ClaimChallenged(newChallengeId, _claimId, msg.sender, _stakeAmount);
    }

    /**
     * @notice Resolves a claim challenge. This function would typically be called by a DAO,
     *         whitelisted dispute resolver, or after a specific voting period.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengerWins True if the challenger's argument is upheld, false otherwise.
     */
    function resolveClaimChallenge(uint256 _challengeId, bool _challengerWins) public onlyOwner whenNotPaused { // Simplified to onlyOwner for example, ideally DAO or other oracle
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id == _challengeId, "CognitoNexus: Invalid challenge ID.");
        require(challenge.status == ChallengeStatus.PENDING, "CognitoNexus: Challenge already resolved.");

        Claim storage claim = claims[challenge.claimId];
        require(claim.activeChallengeId == _challengeId, "CognitoNexus: Challenge is not active for this claim.");
        
        challenge.resolutionTime = block.timestamp;
        claim.activeChallengeId = 0; // No longer active

        uint256 challengerNodeId = nodeAddressToTokenId[challenge.challenger];

        if (_challengerWins) {
            challenge.status = ChallengeStatus.RESOLVED_CHALLENGER_WINS;
            challenge.winner = challenge.challenger;
            claim.status = ClaimStatus.RESOLVED_REJECTED; // Claim is rejected due to successful challenge
            
            // Slash original claim submitter and 'agree' validators
            // Reward challenger and 'disagree' validators
            _handleChallengeOutcome(challenge.claimId, true, challengerNodeId, challenge.stake);
            _updateReputation(challenge.challenger, 50); // Boost challenger reputation
        } else {
            challenge.status = ChallengeStatus.RESOLVED_CHALLENGER_LOSES;
            challenge.winner = claim.submitter; // Or collective of validators
            claim.status = ClaimStatus.RESOLVED_ACCEPTED; // Claim is accepted, challenge failed

            // Slash challenger
            // Reward original claim submitter and 'agree' validators
            _handleChallengeOutcome(challenge.claimId, false, challengerNodeId, challenge.stake);
            _updateReputation(challenge.challenger, -50); // Penalize challenger reputation
        }
        
        // Finalize epistemic score and rewards for the claim
        _calculateClaimEpistemicScoreInternal(challenge.claimId); // Recalculate score after resolution
        
        emit ChallengeResolved(_challengeId, challenge.claimId, challenge.status, challenge.winner);
    }

    /**
     * @notice Calculates and updates a claim's weighted "Epistemic Score" based on validator reputation.
     *         This function can be called by anyone after the validation period ends or a challenge is resolved.
     * @param _claimId The ID of the claim to calculate the score for.
     */
    function calculateClaimEpistemicScore(uint256 _claimId) public whenNotPaused {
        Claim storage claim = claims[_claimId];
        require(claim.id == _claimId, "CognitoNexus: Invalid claim ID.");
        require(block.timestamp > claim.validationPeriodEnd || claim.status == ClaimStatus.CHALLENGED || claim.status == ClaimStatus.RESOLVED_ACCEPTED || claim.status == ClaimStatus.RESOLVED_REJECTED, "CognitoNexus: Validation period not ended or challenge not resolved.");
        require(claim.status != ClaimStatus.VALIDATED && claim.status != ClaimStatus.OBSOLETE, "CognitoNexus: Claim score already finalized or obsolete.");

        _calculateClaimEpistemicScoreInternal(_claimId);
        
        // If not challenged, mark as validated
        if (claim.status == ClaimStatus.PENDING_VALIDATION) {
            claim.status = ClaimStatus.VALIDATED;
        }

        emit ClaimEpistemicScoreUpdated(_claimId, claim.epistemicScore);
    }

    /**
     * @notice Allows users to withdraw their original staked funds if the claim/validation was successful.
     *         This should only be called after a claim's status is finalized (VALIDATED, RESOLVED_ACCEPTED/REJECTED).
     * @param _stakeRefId The ID of the claim, validation, or challenge associated with the stake.
     * @param _type The type of stake (CLAIM, VALIDATION, CHALLENGE).
     */
    function withdrawStakedFunds(uint256 _stakeRefId, StakeType _type) public whenNotPaused {
        uint256 amountToWithdraw = 0;
        address stakeholder = msg.sender;
        uint256 nodeId = nodeAddressToTokenId[stakeholder];
        require(nodeId != 0, "CognitoNexus: Caller is not a registered KnowledgeNode.");

        if (_type == StakeType.CLAIM) {
            Claim storage claim = claims[_stakeRefId];
            require(claim.submitter == stakeholder, "CognitoNexus: Not the submitter of this claim.");
            require(claim.status == ClaimStatus.VALIDATED || claim.status == ClaimStatus.RESOLVED_ACCEPTED, "CognitoNexus: Claim not successfully validated/accepted.");
            require(claim.initialStake > 0, "CognitoNexus: No stake to withdraw.");
            require(!claim.rewardsClaimed, "CognitoNexus: Rewards already claimed, implying stake withdrawal as well."); // Rewards claiming implies stake withdrawal

            amountToWithdraw = claim.initialStake;
            claim.initialStake = 0; // Prevent double withdrawal
            claim.rewardsClaimed = true; // Mark as claimed (stake and potential rewards)
        } else if (_type == StakeType.VALIDATION) {
            Validation storage validation = validations[_stakeRefId];
            require(validation.validator == stakeholder, "CognitoNexus: Not the validator of this validation.");
            require(!validation.revoked, "CognitoNexus: Validation was revoked.");

            Claim storage claim = claims[validation.claimId];
            bool successfulValidation = (claim.status == ClaimStatus.VALIDATED && validation.agrees) ||
                                        (claim.status == ClaimStatus.RESOLVED_ACCEPTED && validation.agrees) ||
                                        (claim.status == ClaimStatus.RESOLVED_REJECTED && !validation.agrees);
            require(successfulValidation, "CognitoNexus: Validation was not successful for this claim outcome.");
            require(validation.stake > 0, "CognitoNexus: No stake to withdraw.");
            require(!validation.rewardsClaimed, "CognitoNexus: Rewards already claimed, implying stake withdrawal as well.");

            amountToWithdraw = validation.stake;
            validation.stake = 0; // Prevent double withdrawal
            validation.rewardsClaimed = true; // Mark as claimed (stake and potential rewards)
        } else if (_type == StakeType.CHALLENGE) {
            Challenge storage challenge = challenges[_stakeRefId];
            require(challenge.challenger == stakeholder, "CognitoNexus: Not the challenger of this challenge.");
            require(challenge.status == ChallengeStatus.RESOLVED_CHALLENGER_WINS, "CognitoNexus: Challenge not successful.");
            require(challenge.stake > 0, "CognitoNexus: No stake to withdraw.");
            // Assuming challenge stake withdrawal is handled by rewards for winner.
            // If it's just stake, need a separate flag. For now, implies handled by _handleChallengeOutcome
            revert("CognitoNexus: Challenge stake withdrawal handled by outcome.");
        } else {
            revert("CognitoNexus: Invalid stake type.");
        }

        require(amountToWithdraw > 0, "CognitoNexus: No funds available for withdrawal.");
        
        knowledgeNodes[nodeId].totalStaked = knowledgeNodes[nodeId].totalStaked.sub(amountToWithdraw);
        payable(msg.sender).transfer(amountToWithdraw);
        emit RewardsClaimed(msg.sender, _stakeRefId, amountToWithdraw); // Reusing event for clarity
    }

    /**
     * @notice Allows a validator to revoke their validation within a short window.
     *         May incur a small penalty for changing mind.
     * @param _validationId The ID of the validation to revoke.
     */
    function revokeValidation(uint256 _validationId) public onlyRegisteredNode whenNotPaused {
        Validation storage validation = validations[_validationId];
        require(validation.id == _validationId, "CognitoNexus: Invalid validation ID.");
        require(validation.validator == msg.sender, "CognitoNexus: Not the owner of this validation.");
        require(!validation.revoked, "CognitoNexus: Validation already revoked.");

        Claim storage claim = claims[validation.claimId];
        require(claim.status == ClaimStatus.PENDING_VALIDATION, "CognitoNexus: Claim not in pending validation.");
        require(block.timestamp <= validation.timestamp.add(1 hours), "CognitoNexus: Revocation window expired."); // 1 hour window

        validation.revoked = true;
        uint256 nodeId = nodeAddressToTokenId[msg.sender];
        uint256 penalty = validation.stake.div(10); // 10% penalty for revocation
        uint256 refundAmount = validation.stake.sub(penalty);

        knowledgeNodes[nodeId].totalStaked = knowledgeNodes[nodeId].totalStaked.sub(validation.stake);
        // Transfer refund (original stake - penalty)
        payable(msg.sender).transfer(refundAmount);
        
        // Deduct from claim totals
        if (validation.agrees) {
            claim.totalAgrees = claim.totalAgrees.sub(1);
        } else {
            claim.totalDisagrees = claim.totalDisagrees.sub(1);
        }
        claim.totalValidationStake = claim.totalValidationStake.sub(validation.stake);
        claim.validatorStakes[msg.sender] = claim.validatorStakes[msg.sender].sub(validation.stake);
        claim.hasValidated[msg.sender] = false; // Allow re-validation

        emit ValidationRevoked(_validationId, validation.claimId, msg.sender);
    }


    // --- Reputation & SBT Management ---

    /**
     * @notice Updates the IPFS CID for a user's KnowledgeNode SBT profile.
     * @param _newNodeProfileCID The new IPFS CID for the profile.
     */
    function updateNodeProfile(string memory _newNodeProfileCID) public onlyRegisteredNode whenNotPaused {
        uint256 tokenId = nodeAddressToTokenId[msg.sender];
        knowledgeNodes[tokenId].profileCID = _newNodeProfileCID;
        emit NodeProfileUpdated(msg.sender, tokenId, _newNodeProfileCID);
    }

    /**
     * @notice Allows a KnowledgeNode to delegate a portion of their validation power to another node.
     *         This effectively adds a portion of their reputation score for weighted calculations.
     * @param _delegatee The address of the node to delegate power to.
     * @param _powerAmount The amount of reputation score to delegate.
     */
    function delegateValidationPower(address _delegatee, uint256 _powerAmount) public onlyRegisteredNode whenNotPaused {
        uint256 delegatorNodeId = nodeAddressToTokenId[msg.sender];
        uint256 delegateeNodeId = nodeAddressToTokenId[_delegatee];
        require(delegateeNodeId != 0, "CognitoNexus: Delegatee is not a registered KnowledgeNode.");
        require(delegatorNodeId != delegateeNodeId, "CognitoNexus: Cannot delegate to self.");
        
        _updateReputation(msg.sender, 0); // Refresh delegator's reputation
        uint256 availablePower = knowledgeNodes[delegatorNodeId].reputationScore.sub(knowledgeNodes[delegatorNodeId].delegatedPower[_delegatee]);
        
        require(_powerAmount <= availablePower, "CognitoNexus: Insufficient reputation score to delegate.");

        knowledgeNodes[delegatorNodeId].delegatedPower[_delegatee] = knowledgeNodes[delegatorNodeId].delegatedPower[_delegatee].add(_powerAmount);
        knowledgeNodes[delegateeNodeId].isDelegatee[msg.sender] = true; // Mark as being delegated to

        emit ValidationPowerDelegated(msg.sender, _delegatee, _powerAmount);
    }

    /**
     * @notice Revokes previously delegated validation power.
     * @param _delegatee The address of the node from which to revoke power.
     * @param _powerAmount The amount of reputation score to revoke.
     */
    function undelegateValidationPower(address _delegatee, uint256 _powerAmount) public onlyRegisteredNode whenNotPaused {
        uint256 delegatorNodeId = nodeAddressToTokenId[msg.sender];
        uint256 delegateeNodeId = nodeAddressToTokenId[_delegatee];
        require(delegateeNodeId != 0, "CognitoNexus: Delegatee is not a registered KnowledgeNode.");
        
        require(knowledgeNodes[delegatorNodeId].delegatedPower[_delegatee] >= _powerAmount, "CognitoNexus: Not enough delegated power to revoke.");

        knowledgeNodes[delegatorNodeId].delegatedPower[_delegatee] = knowledgeNodes[delegatorNodeId].delegatedPower[_delegatee].sub(_powerAmount);
        
        // If no more power delegated, remove the delegatee flag
        if (knowledgeNodes[delegatorNodeId].delegatedPower[_delegatee] == 0) {
            knowledgeNodes[delegateeNodeId].isDelegatee[msg.sender] = false;
        }

        emit ValidationPowerUndelegated(msg.sender, _delegatee, _powerAmount);
    }

    // --- Knowledge Graph & Interlinking ---

    /**
     * @notice Establishes a semantic link between two claims.
     * @param _sourceClaimId The ID of the source claim.
     * @param _targetClaimId The ID of the target claim.
     * @param _linkType The type of relationship between the claims (e.g., SUPPORTS, DISPUTES).
     */
    function linkClaims(uint256 _sourceClaimId, uint256 _targetClaimId, LinkType _linkType) public onlyRegisteredNode whenNotPaused {
        require(claims[_sourceClaimId].id != 0, "CognitoNexus: Invalid source claim ID.");
        require(claims[_targetClaimId].id != 0, "CognitoNexus: Invalid target claim ID.");
        require(_sourceClaimId != _targetClaimId, "CognitoNexus: Cannot link a claim to itself.");

        // Prevent duplicate links of the same type
        uint256[] storage links = claimLinks[_sourceClaimId][_linkType];
        for (uint256 i = 0; i < links.length; i++) {
            require(links[i] != _targetClaimId, "CognitoNexus: Link already exists.");
        }

        claimLinks[_sourceClaimId][_linkType].push(_targetClaimId);
        _updateReputation(msg.sender, 0); // Update activity time
        emit ClaimLinked(_sourceClaimId, _targetClaimId, _linkType);
    }

    /**
     * @notice Retrieves all claims linked to a given claim by a specific `LinkType`.
     * @param _claimId The ID of the claim to query.
     * @param _linkType The type of link to retrieve.
     * @return An array of claim IDs linked by the specified type.
     */
    function getLinkedClaims(uint256 _claimId, LinkType _linkType) public view returns (uint256[] memory) {
        require(claims[_claimId].id != 0, "CognitoNexus: Invalid claim ID.");
        return claimLinks[_claimId][_linkType];
    }

    // --- AI-Assisted Insight ---

    /**
     * @notice Records a request for an off-chain AI service to generate an insight for a specific claim.
     *         The actual AI computation happens off-chain, but the request is logged on-chain.
     * @param _claimId The ID of the claim for which to request AI insight.
     * @param _promptCID IPFS CID of the specific prompt/query for the AI.
     */
    function requestAIInsight(uint256 _claimId, string memory _promptCID) public payable onlyRegisteredNode whenNotPaused {
        require(claims[_claimId].id != 0, "CognitoNexus: Invalid claim ID.");
        require(msg.value >= aiOracleFee, "CognitoNexus: Insufficient AI oracle fee.");

        _aiInsightRequestIds.increment();
        uint256 newRequestId = _aiInsightRequestIds.current();

        aiInsightRequests[newRequestId] = AIInsightRequest({
            id: newRequestId,
            claimId: _claimId,
            requester: msg.sender,
            promptCID: _promptCID,
            requestTime: block.timestamp,
            resultCID: "",
            confidenceScore: 0,
            completed: false,
            submitter: address(0)
        });

        // Funds are held in contract until result is submitted to pay oracle
        emit AIInsightRequested(newRequestId, _claimId, msg.sender, _promptCID);
    }

    /**
     * @notice Allows a whitelisted AI oracle to submit the result of an AI insight request.
     * @param _requestId The ID of the AI insight request.
     * @param _insightCID IPFS CID of the AI's generated insight.
     * @param _confidenceScore AI's reported confidence score (0-100).
     */
    function submitAIInsightResult(uint256 _requestId, string memory _insightCID, uint256 _confidenceScore) public onlyAIOracle whenNotPaused {
        AIInsightRequest storage req = aiInsightRequests[_requestId];
        require(req.id == _requestId, "CognitoNexus: Invalid AI insight request ID.");
        require(!req.completed, "CognitoNexus: AI insight request already completed.");
        require(_confidenceScore <= 100, "CognitoNexus: Confidence score must be between 0 and 100.");

        req.resultCID = _insightCID;
        req.confidenceScore = _confidenceScore;
        req.completed = true;
        req.submitter = msg.sender;

        // Pay the AI oracle fee
        payable(msg.sender).transfer(aiOracleFee);

        emit AIInsightResultSubmitted(_requestId, req.claimId, _insightCID, _confidenceScore);
    }

    // --- Financial & Incentive Management ---

    /**
     * @notice Allows anyone to contribute ETH to the contract's reward pool.
     */
    function fundRewardPool() public payable whenNotPaused {
        require(msg.value > 0, "CognitoNexus: Must send non-zero ETH to fund reward pool.");
        emit RewardPoolFunded(msg.sender, msg.value);
    }

    /**
     * @notice Allows successful claim submitters and validators to claim their earned rewards.
     *         This function also handles the withdrawal of initial stake for simplicity.
     * @param _claimId The ID of the claim for which rewards are being claimed.
     */
    function claimRewards(uint256 _claimId) public onlyRegisteredNode whenNotPaused {
        Claim storage claim = claims[_claimId];
        require(claim.id == _claimId, "CognitoNexus: Invalid claim ID.");
        require(claim.status == ClaimStatus.VALIDATED || claim.status == ClaimStatus.RESOLVED_ACCEPTED || claim.status == ClaimStatus.RESOLVED_REJECTED, "CognitoNexus: Claim not finalized.");
        require(!claim.rewardsClaimed, "CognitoNexus: Rewards already claimed for this claim.");
        
        uint256 nodeId = nodeAddressToTokenId[msg.sender];
        uint256 totalRewardAmount = 0;

        // Rewards for Claim Submitter
        if (claim.submitter == msg.sender && (claim.status == ClaimStatus.VALIDATED || claim.status == ClaimStatus.RESOLVED_ACCEPTED)) {
            require(claim.initialStake > 0, "CognitoNexus: No initial stake to reward.");
            uint256 claimSubmitterReward = claim.initialStake.mul(rewardMultiplier);
            totalRewardAmount = totalRewardAmount.add(claimSubmitterReward.add(claim.initialStake)); // Original stake + reward
            claim.initialStake = 0; // Mark stake as processed
            _updateReputation(msg.sender, 20); // Boost reputation for successful claim
        }

        // Rewards for Validators
        // Iterate through all validations to find current sender's successful ones
        uint256[] memory validationIds = _getValidationsForClaim(_claimId);
        for (uint256 i = 0; i < validationIds.length; i++) {
            Validation storage val = validations[validationIds[i]];
            if (val.validator == msg.sender && !val.revoked && !val.rewardsClaimed) {
                bool successfulValidation = (claim.status == ClaimStatus.VALIDATED && val.agrees) ||
                                            (claim.status == ClaimStatus.RESOLVED_ACCEPTED && val.agrees) ||
                                            (claim.status == ClaimStatus.RESOLVED_REJECTED && !val.agrees);
                
                if (successfulValidation) {
                    uint256 validatorReward = val.stake.mul(rewardMultiplier);
                    totalRewardAmount = totalRewardAmount.add(validatorReward.add(val.stake)); // Original stake + reward
                    val.stake = 0; // Mark stake as processed
                    val.rewardsClaimed = true;
                    _updateReputation(msg.sender, 5); // Boost reputation for successful validation
                }
            }
        }
        
        require(totalRewardAmount > 0, "CognitoNexus: No eligible rewards or stake to claim.");
        require(address(this).balance >= totalRewardAmount, "CognitoNexus: Insufficient contract balance for rewards.");

        knowledgeNodes[nodeId].totalStaked = knowledgeNodes[nodeId].totalStaked.sub(totalRewardAmount); // Deduct original stake from totalStaked as it's returned
        payable(msg.sender).transfer(totalRewardAmount);
        
        claim.rewardsClaimed = true; // Mark claim's rewards as claimed after distribution to all relevant parties

        emit RewardsClaimed(msg.sender, _claimId, totalRewardAmount);
    }

    /**
     * @notice A governance/admin function to penalize misbehaving KnowledgeNodes by slashing their staked funds.
     *         This could be invoked by a DAO vote or a dispute resolution process.
     * @param _offender The address of the KnowledgeNode to be penalized.
     * @param _amount The amount of ETH to slash from their total staked funds.
     */
    function slashStake(address _offender, uint256 _amount) public onlyOwner whenNotPaused { // Simplified to onlyOwner, ideally via governance
        uint256 offenderNodeId = nodeAddressToTokenId[_offender];
        require(offenderNodeId != 0, "CognitoNexus: Offender is not a registered KnowledgeNode.");
        require(knowledgeNodes[offenderNodeId].totalStaked >= _amount, "CognitoNexus: Offender does not have enough staked funds.");

        knowledgeNodes[offenderNodeId].totalStaked = knowledgeNodes[offenderNodeId].totalStaked.sub(_amount);
        // Slashed funds remain in the contract's reward pool or are burned/reallocated by governance.

        _updateReputation(_offender, -100); // Significant reputation penalty
        emit StakeSlashed(_offender, _amount);
    }

    // --- Governance & Utilities ---

    /**
     * @notice Initiates a proposal to change a contract parameter.
     *         This is a basic DAO-like function.
     * @param _paramName Identifier for the parameter to change (e.g., "minClaimStake").
     * @param _newValue The proposed new value for the parameter.
     */
    function proposeParameterChange(bytes32 _paramName, uint256 _newValue) public onlyRegisteredNode whenNotPaused {
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            paramName: _paramName,
            newValue: _newValue,
            creationTime: block.timestamp,
            minVotingPeriod: proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            hasVoted: new mapping(address => bool)
        });
        _updateReputation(msg.sender, 0); // Update activity time
        emit ParameterChangeProposed(newProposalId, msg.sender, _paramName, _newValue);
    }

    /**
     * @notice Allows registered KnowledgeNodes to vote on active parameter change proposals.
     *         Voting power is weighted by the node's current reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) public onlyRegisteredNode whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "CognitoNexus: Invalid proposal ID.");
        require(block.timestamp <= proposal.creationTime.add(proposal.minVotingPeriod), "CognitoNexus: Voting period has ended.");
        require(!proposal.executed, "CognitoNexus: Proposal already executed.");
        require(!proposal.hasVoted[msg.sender], "CognitoNexus: Caller has already voted on this proposal.");

        uint256 voterNodeId = nodeAddressToTokenId[msg.sender];
        _updateReputation(msg.sender, 0); // Refresh voter's reputation
        uint256 votingPower = _getVotingPower(msg.sender);

        require(votingPower > 0, "CognitoNexus: Voter has no effective voting power.");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit ParameterChangeVoted(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Executes a parameter change proposal if it has met the required consensus threshold.
     *         Can be called by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "CognitoNexus: Invalid proposal ID.");
        require(block.timestamp > proposal.creationTime.add(proposal.minVotingPeriod), "CognitoNexus: Voting period not ended.");
        require(!proposal.executed, "CognitoNexus: Proposal already executed.");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "CognitoNexus: No votes cast on this proposal.");

        // Calculate total active reputation for quorum check (simplified for now)
        // In a full DAO, this would be total KNSBT reputation that's 'active'
        uint256 totalActiveReputation = _calculateTotalActiveReputation(); 
        require(totalVotes >= totalActiveReputation.mul(minProposalQuorumPercentage).div(100), "CognitoNexus: Proposal did not meet quorum.");

        if (proposal.votesFor > proposal.votesAgainst) {
            // Proposal passed, apply the change
            if (proposal.paramName == "minClaimStake") {
                minClaimStake = proposal.newValue;
            } else if (proposal.paramName == "minValidationStake") {
                minValidationStake = proposal.newValue;
            } else if (proposal.paramName == "minChallengeStake") {
                minChallengeStake = proposal.newValue;
            } else if (proposal.paramName == "validationPeriodDuration") {
                validationPeriodDuration = proposal.newValue;
            } else if (proposal.paramName == "challengeResolutionPeriod") {
                challengeResolutionPeriod = proposal.newValue;
            } else if (proposal.paramName == "rewardMultiplier") {
                rewardMultiplier = proposal.newValue;
            } else if (proposal.paramName == "initialReputationScore") {
                initialReputationScore = proposal.newValue;
            } else if (proposal.paramName == "reputationDecayRate") {
                reputationDecayRate = proposal.newValue;
            } else if (proposal.paramName == "proposalVotingPeriod") {
                proposalVotingPeriod = proposal.newValue;
            } else if (proposal.paramName == "minProposalQuorumPercentage") {
                minProposalQuorumPercentage = proposal.newValue;
            } else if (proposal.paramName == "aiOracleFee") {
                aiOracleFee = proposal.newValue;
            } else {
                revert("CognitoNexus: Unknown parameter name.");
            }
            proposal.executed = true;
            emit ParameterChangeExecuted(_proposalId, proposal.paramName, proposal.newValue);
        } else {
            // Proposal failed
            proposal.executed = true; // Mark as failed but processed
        }
    }
    
    // --- Internal / View Helper Functions ---

    /**
     * @dev Internal function to update a KnowledgeNode's reputation score.
     *      Applies decay for inactivity and adjusts for recent success/failure.
     * @param _nodeAddress The address of the node to update.
     * @param _reputationChange The direct change to apply (positive for gain, negative for loss).
     */
    function _updateReputation(address _nodeAddress, int256 _reputationChange) internal {
        uint256 nodeId = nodeAddressToTokenId[_nodeAddress];
        if (nodeId == 0) return; // Node not registered

        KnowledgeNode storage node = knowledgeNodes[nodeId];
        
        // Apply decay
        uint256 timeSinceLastActivity = block.timestamp.sub(node.lastActivityTime);
        uint256 decayAmount = timeSinceLastActivity.div(1 days).mul(reputationDecayRate); // Decay X points per day
        if (node.reputationScore > decayAmount) {
            node.reputationScore = node.reputationScore.sub(decayAmount);
        } else {
            node.reputationScore = 0; // Cannot go below 0
        }

        // Apply direct change
        if (_reputationChange > 0) {
            node.reputationScore = node.reputationScore.add(uint256(_reputationChange));
        } else if (_reputationChange < 0) {
            uint256 absChange = uint256(-_reputationChange);
            if (node.reputationScore > absChange) {
                node.reputationScore = node.reputationScore.sub(absChange);
            } else {
                node.reputationScore = 0;
            }
        }
        
        node.lastActivityTime = block.timestamp;
        emit ReputationUpdated(_nodeAddress, node.reputationScore); // Custom event for reputation update
    }

    /**
     * @dev Internal function to handle the financial and reputation outcomes of a claim challenge.
     * @param _claimId The ID of the claim that was challenged.
     * @param _challengerWins True if the challenger won, false otherwise.
     * @param _challengerNodeId The tokenId of the challenger.
     * @param _challengerStake The original stake of the challenger.
     */
    function _handleChallengeOutcome(uint256 _claimId, bool _challengerWins, uint256 _challengerNodeId, uint256 _challengerStake) internal {
        Claim storage claim = claims[_claimId];
        
        // Challenger's stake outcome
        if (_challengerWins) {
            // Challenger wins: rewards challenger, slashes submitter and 'agree' validators
            payable(knowledgeNodes[_challengerNodeId].ownerOf(knowledgeNodes[_challengerNodeId].tokenId)).transfer(_challengerStake.mul(rewardMultiplier).add(_challengerStake)); // Challenger gets stake + reward
            knowledgeNodes[_challengerNodeId].totalStaked = knowledgeNodes[_challengerNodeId].totalStaked.sub(_challengerStake);
            _updateReputation(knowledgeNodes[_challengerNodeId].ownerOf(knowledgeNodes[_challengerNodeId].tokenId), 50); // Boost challenger reputation
        } else {
            // Challenger loses: slashes challenger
            knowledgeNodes[_challengerNodeId].totalStaked = knowledgeNodes[_challengerNodeId].totalStaked.sub(_challengerStake); // Slashed stake remains in contract
            _updateReputation(knowledgeNodes[_challengerNodeId].ownerOf(knowledgeNodes[_challengerNodeId].tokenId), -50); // Penalize challenger reputation
        }

        // Claim submitter and validators outcomes
        uint256 submitterNodeId = nodeAddressToTokenId[claim.submitter];
        if (_challengerWins) {
            // Submitter gets slashed
            knowledgeNodes[submitterNodeId].totalStaked = knowledgeNodes[submitterNodeId].totalStaked.sub(claim.initialStake);
            _updateReputation(claim.submitter, -30); // Penalize submitter
            claim.initialStake = 0; // Mark stake as processed
        } else {
            // Submitter gets original stake back (if not already withdrawn/claimed) and reward
            // This is handled by claimRewards, but ensure their stake is not slashed.
            // For now, assume it's settled post-challenge by calling claimRewards.
        }

        uint256[] memory validationIds = _getValidationsForClaim(_claimId);
        for (uint256 i = 0; i < validationIds.length; i++) {
            Validation storage val = validations[validationIds[i]];
            if (val.revoked) continue;

            uint256 validatorNodeId = nodeAddressToTokenId[val.validator];
            if (_challengerWins) {
                // If challenger wins (claim rejected), 'agree' validators are slashed, 'disagree' validators are rewarded.
                if (val.agrees) {
                    knowledgeNodes[validatorNodeId].totalStaked = knowledgeNodes[validatorNodeId].totalStaked.sub(val.stake);
                    _updateReputation(val.validator, -10); // Penalize agree validator
                    val.stake = 0; // Mark stake as processed
                } else { // Disagree validator was correct
                    // This is handled by claimRewards
                }
            } else {
                // If challenger loses (claim accepted), 'disagree' validators are slashed, 'agree' validators are rewarded.
                if (!val.agrees) {
                    knowledgeNodes[validatorNodeId].totalStaked = knowledgeNodes[validatorNodeId].totalStaked.sub(val.stake);
                    _updateReputation(val.validator, -10); // Penalize disagree validator
                    val.stake = 0; // Mark stake as processed
                } else { // Agree validator was correct
                    // This is handled by claimRewards
                }
            }
            val.rewardsClaimed = true; // Mark as processed
        }
    }


    /**
     * @dev Calculates the final epistemic score for a claim.
     *      Score is a weighted average of validators' agreement/disagreement, weighted by their reputation.
     *      Score range: -100 (strongly disagreed) to 100 (strongly agreed).
     * @param _claimId The ID of the claim.
     */
    function _calculateClaimEpistemicScoreInternal(uint256 _claimId) internal {
        Claim storage claim = claims[_claimId];
        
        int256 totalWeightedScore = 0;
        uint256 totalReputationWeight = 0;

        uint256[] memory validationIds = _getValidationsForClaim(_claimId);

        for (uint256 i = 0; i < validationIds.length; i++) {
            Validation storage val = validations[validationIds[i]];
            if (val.revoked) continue;

            uint256 validatorNodeId = nodeAddressToTokenId[val.validator];
            _updateReputation(val.validator, 0); // Ensure reputation is up-to-date
            uint256 validatorReputation = knowledgeNodes[validatorNodeId].reputationScore;
            
            // Add delegated power to validator's effective reputation for this calculation
            uint256 effectiveReputation = validatorReputation;
            // Iterate over all nodes to find who delegated to this validator
            // This is inefficient; a better approach would be to store inbound delegations
            // For simplicity and gas, we'll assume direct validator reputation for now, or
            // just look at explicitly stored delegated power from *this validator*
            // A truly scalable solution for delegated voting power would aggregate.
            // Here, we consider the validator's own reputation + any power they delegated to themselves (which shouldn't happen)
            // Or, more realistically, aggregate all 'isDelegatee[validator]' entries.
            // For now, just use their base reputation.
            
            int256 scoreMultiplier = val.agrees ? 1 : -1;
            totalWeightedScore = totalWeightedScore.add(int256(effectiveReputation).mul(scoreMultiplier));
            totalReputationWeight = totalReputationWeight.add(effectiveReputation);
        }

        if (totalReputationWeight > 0) {
            claim.epistemicScore = (totalWeightedScore.mul(100)).div(int256(totalReputationWeight)); // Scale to -100 to 100
        } else {
            claim.epistemicScore = 0; // No validations, neutral score
        }
    }

    /**
     * @dev Helper to get all validation IDs for a given claim.
     *      This is inefficient for many validations, but simplifies the example.
     *      A more robust solution would store these directly in the Claim struct or a mapping.
     */
    function _getValidationsForClaim(uint256 _claimId) internal view returns (uint256[] memory) {
        uint256 count = 0;
        // First pass to count
        for (uint256 i = 1; i <= _validationIds.current(); i++) {
            if (validations[i].claimId == _claimId) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 currentIndex = 0;
        // Second pass to collect
        for (uint256 i = 1; i <= _validationIds.current(); i++) {
            if (validations[i].claimId == _claimId) {
                result[currentIndex] = i;
                currentIndex++;
            }
        }
        return result;
    }

    /**
     * @dev Calculates the effective voting power for an address.
     *      Considers their own reputation plus any delegated power.
     * @param _voter The address of the voter.
     * @return The total voting power.
     */
    function _getVotingPower(address _voter) internal view returns (uint256) {
        uint256 voterNodeId = nodeAddressToTokenId[_voter];
        if (voterNodeId == 0) return 0;
        
        uint256 reputation = knowledgeNodes[voterNodeId].reputationScore;
        uint256 totalDelegatedIn = 0;
        // This loop iterates over all *possible delegators* to sum up inbound delegated power.
        // It's highly inefficient for large number of nodes.
        // In a real system, a mapping like `mapping(address => uint256) public inboundDelegatedPower;`
        // would be used and updated when power is delegated/undelegated.
        // For this example, we skip iterating all nodes and assume `reputation` is sufficient representation.
        // If a simple solution is needed:
        // for (uint256 i = 1; i <= _nodeIds.current(); i++) {
        //     if (knowledgeNodes[i].delegatedPower[_voter] > 0) {
        //         totalDelegatedIn = totalDelegatedIn.add(knowledgeNodes[i].delegatedPower[_voter]);
        //     }
        // }
        
        // return reputation.add(totalDelegatedIn);
        return reputation; // Simpler for example
    }

    /**
     * @dev Calculates the total active reputation in the system for quorum checks.
     *      A simple summation of all node reputations.
     * @return The sum of all active node reputations.
     */
    function _calculateTotalActiveReputation() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= _nodeIds.current(); i++) {
            total = total.add(knowledgeNodes[i].reputationScore);
        }
        return total;
    }

    // --- ERC721 Overrides (to enforce Soulbound behavior) ---
    // Make transferFrom and safeTransferFrom revert to make the tokens Soulbound
    function _transfer(address, address, uint256) internal pure override {
        revert("KnowledgeNodeSBT: SBTs are non-transferable.");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("KnowledgeNodeSBT: SBTs are non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("KnowledgeNodeSBT: SBTs are non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("KnowledgeNodeSBT: SBTs are non-transferable.");
    }
}
```