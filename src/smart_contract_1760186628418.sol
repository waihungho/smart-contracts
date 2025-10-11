The **CognitoNexus** protocol is an advanced, multi-faceted decentralized platform designed for the creation, validation, and evolution of "Knowledge Units" (KUs) as dynamic NFTs. It integrates an AI oracle for augmented validation, a reputation system, dynamic royalties, and a mini-governance module, aiming to foster a reliable and incentive-aligned decentralized knowledge base.

Users can mint KUs, which represent any piece of verifiable knowledge. These KUs undergo a validation process involving both human reviewers (with earned reputation) and an external AI oracle. Based on validation outcomes, KUs can evolve, affecting their visibility, creator's reputation, and even their associated royalties. The protocol also features mechanisms for sponsoring research topics and a governance system for protocol parameter adjustments.

---

## CognitoNexus Smart Contract Outline and Function Summary

**I. Core Protocol Management (Owner/Governance Controlled)**

1.  `constructor(address _aiOracleAddress, address _evoTokenAddress)`: Initializes the contract, setting up the AI Oracle and Evo-Token contract addresses.
2.  `updateAIOracleAddress(address _newOracle)`: Allows the owner to update the trusted AI Oracle contract address.
3.  `updateEvoTokenAddress(address _newEvoToken)`: Allows the owner to update the Evo-Token contract address.
4.  `setProtocolPaused(bool _paused)`: Enables the owner to pause or unpause core protocol functionalities in case of an emergency or upgrade.

**II. Knowledge Unit (KU) Management (ERC-721)**

5.  `mintKnowledgeUnit(string memory _metadataURI, uint256 _initialBounty, bytes32 _topicHash)`: Permits a user to mint a new Knowledge Unit (KU) NFT. This includes providing initial metadata, allocating an optional Evo-Token bounty for validators, and specifying a topic for potential sponsorship matching.
6.  `updateKnowledgeUnitMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Enables the KU owner (or an approved delegate) to make minor updates to the KU's metadata URI.
7.  `proposeKURevision(uint256 _tokenId, string memory _proposedMetadataURI)`: Allows users with sufficient reputation to propose a significant revision to an existing KU, initiating a review process.
8.  `approveKURevision(uint256 _tokenId, uint256 _revisionId)`: Approves a proposed KU revision (currently by owner, in future via governance), updating the KU's metadata and potentially its impact score.
9.  `retireKnowledgeUnit(uint256 _tokenId)`: Marks a KU as obsolete or retired. This typically affects its discoverability, impact score, and royalty generation.

**III. Reputation & Validation System (Soulbound-like)**

10. `getReputationScore(address _user)`: Retrieves the non-transferable reputation score for a specified user, reflecting their contribution and validation quality.
11. `submitHumanValidation(uint256 _tokenId, bool _isPositive, string memory _reviewHash)`: Allows high-reputation users to review and validate KUs. Positive validation earns the validator reputation and a share of the KU's bounty.
12. `requestAIValidation(uint256 _tokenId, string memory _prompt)`: Initiates a request to the external AI Oracle for automated validation or classification of a KU, requiring a payment in Evo-Tokens.
13. `fulfillAIValidation(uint256 _tokenId, bytes32 _requestId, bool _isPositive, string memory _aiReportHash)`: A callback function, exclusively callable by the AI Oracle, to deliver validation results. This function updates KU status, affects its impact score, and adjusts the creator's reputation.
14. `resolveValidationConflict(uint256 _tokenId)`: Initiates a governance proposal to resolve conflicts arising from differing human and AI validation outcomes for a specific KU.

**IV. Dynamic Incentives & Rewards**

15. `setKnowledgeUnitDynamicRoyalty(uint256 _tokenId, uint96 _initialBps, uint96 _aiBoostBps)`: Empowers the KU creator to set dynamic royalty percentages for their KU. The royalty can have a base rate and an additional boost if the KU achieves AI validation or high impact.
16. `sponsorKnowledgeTopic(bytes32 _topicHash, uint256 _amount)`: Enables users to deposit Evo-Tokens to financially support specific knowledge topics, incentivizing creators to contribute KUs in those areas.
17. `claimSponsorshipFunds(uint256 _tokenId)`: Allows the creator of an impactful KU, which matches a sponsored topic, to claim a portion of the accumulated sponsorship funds.
18. `claimReputationReward()`: Enables users with a sufficiently high reputation score to claim periodic Evo-Token rewards, with a minor reputation decay applied before the reward.

**V. Governance & Protocol Evolution**

19. `stakeEvoTokens(uint256 _amount)`: Allows users to stake their Evo-Tokens, granting them voting power for protocol governance and potentially other privileges.
20. `unstakeEvoTokens(uint256 _amount)`: Enables users to unstake their Evo-Tokens after a specified cooldown period, removing their voting power.
21. `proposeProtocolParameterChange(bytes32 _parameterKey, uint256 _newValue)`: Permits stakers with sufficient reputation to propose changes to key protocol parameters (e.g., minimum reputation for validation, AI validation fees, voting periods).
22. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows stakers to cast their vote (for or against) on active governance proposals. Voting power is proportional to the amount of staked Evo-Tokens.
23. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has successfully passed its voting period and met the required quorum, applying the proposed parameter change to the protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For Evo-Token interface

// --- Interfaces for external contracts ---

/// @title IAIOracle
/// @dev Interface for an AI Oracle contract that provides verifiable AI computations.
///      In a real-world scenario, this would involve more sophisticated proof verification
///      (e.g., Chainlink external adapters, ZKP verification). For this example,
///      we assume the AIOracle contract verifies the input/output and calls back.
interface IAIOracle {
    function requestValidation(address _callbackContract, uint256 _tokenId, string memory _prompt) external returns (bytes32 requestId);
}

/// @title IEvoToken
/// @dev Interface for the Evo-Token (ERC-20) contract. Assumes it has mint/burn functions
///      callable by this protocol for rewards and potential penalties.
interface IEvoToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}


/**
 * @title CognitoNexus
 * @dev A decentralized protocol for dynamic, AI-augmented knowledge contribution, validation, and reputation.
 *      Users can mint "Knowledge Units" (KUs) as NFTs, which can evolve based on human and AI validation.
 *      The protocol integrates a reputation system, dynamic royalties, and a mini-governance module.
 *
 * Outline and Function Summary:
 *
 * I. Core Protocol Management (Owner/Governance Controlled)
 *    1. `constructor()`: Initializes the contract with an AI Oracle address and the Evo-Token contract address.
 *    2. `updateAIOracleAddress(address _newOracle)`: Updates the trusted AI Oracle contract address.
 *    3. `updateEvoTokenAddress(address _newEvoToken)`: Updates the Evo-Token contract address.
 *    4. `setProtocolPaused(bool _paused)`: Pauses or unpauses core protocol functionalities.
 *
 * II. Knowledge Unit (KU) Management (ERC-721)
 *    5. `mintKnowledgeUnit(string memory _metadataURI, uint256 _initialBounty, bytes32 _topicHash)`: Allows a user to mint a new Knowledge Unit (KU) NFT, attaching initial metadata, an optional bounty for validators, and a topic hash.
 *    6. `updateKnowledgeUnitMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Allows the KU owner (or approved entity) to update the KU's metadata URI.
 *    7. `proposeKURevision(uint256 _tokenId, string memory _proposedMetadataURI)`: Initiates a revision proposal for an existing KU, requiring review and approval.
 *    8. `approveKURevision(uint256 _tokenId, uint256 _revisionId)`: Approves a proposed KU revision, updating the KU's metadata and potentially its impact score.
 *    9. `retireKnowledgeUnit(uint256 _tokenId)`: Marks a KU as retired/obsolete, affecting its visibility and impact.
 *
 * III. Reputation & Validation System (Soulbound-like)
 *    10. `getReputationScore(address _user)`: Retrieves the non-transferable reputation score for a given user.
 *    11. `submitHumanValidation(uint256 _tokenId, bool _isPositive, string memory _reviewHash)`: Allows high-reputation users to review and validate KUs, earning reputation and bounty.
 *    12. `requestAIValidation(uint256 _tokenId, string memory _prompt)`: Initiates a request to the AI Oracle for automated validation or classification of a KU, requiring Evo-Token payment.
 *    13. `fulfillAIValidation(uint256 _tokenId, bytes32 _requestId, bool _isPositive, string memory _aiReportHash)`: Callback function used by the AI Oracle to deliver validation results, impacting KU status and creator reputation. (Only callable by AI Oracle)
 *    14. `resolveValidationConflict(uint256 _tokenId)`: Triggers a conflict resolution process if human and AI validations differ significantly, potentially leading to a community vote.
 *
 * IV. Dynamic Incentives & Rewards
 *    15. `setKnowledgeUnitDynamicRoyalty(uint256 _tokenId, uint96 _initialBps, uint96 _aiBoostBps)`: Allows the KU creator to set dynamic royalty percentages, potentially increasing with AI validation or impact.
 *    16. `sponsorKnowledgeTopic(bytes32 _topicHash, uint256 _amount)`: Enables users to deposit Evo-Tokens to sponsor specific knowledge topics, incentivizing contributions in those areas.
 *    17. `claimSponsorshipFunds(uint256 _tokenId)`: Allows the creator of a KU, which matches a sponsored topic and has sufficient impact, to claim a portion of the sponsorship funds.
 *    18. `claimReputationReward()`: Allows users with a sufficiently high reputation score to claim periodic Evo-Token rewards.
 *
 * V. Governance & Protocol Evolution
 *    19. `stakeEvoTokens(uint256 _amount)`: Users can stake Evo-Tokens to gain voting power and participate in governance.
 *    20. `unstakeEvoTokens(uint256 _amount)`: Allows users to unstake their Evo-Tokens after a defined cooldown period.
 *    21. `proposeProtocolParameterChange(bytes32 _parameterKey, uint256 _newValue)`: Allows stakers to propose changes to key protocol parameters (e.g., reputation decay rate, validation fees).
 *    22. `voteOnProposal(uint256 _proposalId, bool _support)`: Enables stakers to cast their vote on active governance proposals.
 *    23. `executeProposal(uint256 _proposalId)`: Executes a successfully passed governance proposal, applying the proposed parameter change.
 */
contract CognitoNexus is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Token IDs for Knowledge Units
    Counters.Counter private _tokenIdCounter;

    // References to external contracts
    IAIOracle public aiOracle;
    IEvoToken public evoToken;

    // Structs for Knowledge Units
    enum KUStatus { Pending, HumanValidated, AIValidated, Conflict, Retired }
    struct KnowledgeUnit {
        address creator;
        string metadataURI;
        uint256 mintTime;
        KUStatus status;
        uint256 impactScore; // Represents quality/relevance, influenced by validation
        uint96 initialRoyaltyBps; // Base royalty percentage (basis points)
        uint96 aiBoostRoyaltyBps; // Additional royalty for AI-validated KUs
        uint256 currentBounty; // Evo-Tokens allocated for validators
        bytes32 topicHash; // Hashed topic for sponsorship matching
        uint256 latestRevisionId; // Reference to the latest approved revision
    }
    mapping(uint256 => KnowledgeUnit) public knowledgeUnits;

    // Struct for KU Revisions
    enum RevisionStatus { Pending, Approved, Rejected }
    struct KURevision {
        uint256 parentTokenId;
        address proposer;
        string proposedMetadataURI;
        uint256 proposalTime;
        RevisionStatus status;
    }
    Counters.Counter private _revisionIdCounter;
    mapping(uint256 => KURevision) public kuRevisions;

    // Reputation System (Soulbound-like, non-transferable)
    mapping(address => uint256) public reputationScores;
    uint256 public minReputationForValidation = 100; // Minimum reputation to submit human validation
    uint256 public reputationGainPerValidation = 10;
    uint256 public reputationLossPerInvalidKU = 20;
    uint256 public reputationDecayRateBps = 100; // 1% per 'decay cycle' for passive users, basis points
    uint256 public lastReputationDecayCycleTime; // Global timestamp for the last decay cycle

    // AI Validation Fees & Status
    uint256 public aiValidationFee = 10 * (10 ** 18); // 10 Evo-Tokens for AI validation
    mapping(bytes32 => uint256) public aiRequestTokenId; // Maps AI request ID to tokenId

    // Sponsorship for Knowledge Topics
    mapping(bytes32 => uint256) public sponsoredTopics; // topicHash => total Evo-Tokens sponsored
    mapping(uint256 => mapping(address => bool)) public kuTopicClaimed; // tokenId => claimant => bool (prevents multiple claims per KU per person)

    // Governance Parameters
    uint256 public constant MAX_BPS = 10000; // 100% in basis points
    uint256 public minReputationForProposal = 500;
    uint256 public votingPeriod = 3 days;
    uint256 public proposalQuorum = 51; // Percentage (out of 100) of total participating votes needed for approval

    struct Proposal {
        uint256 id;
        bytes32 parameterKey;
        uint256 newValue;
        uint256 startVoteTime;
        uint256 endVoteTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
        bool passed;
    }
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public stakedEvoTokens;
    mapping(address => uint256) public lastUnstakeRequestTime;
    uint256 public unstakeCooldown = 7 days;

    // --- Events ---
    event AIOracleUpdated(address indexed _oldOracle, address indexed _newOracle);
    event EvoTokenUpdated(address indexed _oldToken, address indexed _newToken);
    event KnowledgeUnitMinted(uint256 indexed tokenId, address indexed creator, string metadataURI, uint256 initialBounty, bytes32 topicHash);
    event KnowledgeUnitMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event KnowledgeUnitRetired(uint256 indexed tokenId);
    event KURevisionProposed(uint256 indexed tokenId, uint256 indexed revisionId, address indexed proposer, string proposedMetadataURI);
    event KURevisionApproved(uint256 indexed tokenId, uint256 indexed revisionId, address indexed approver);
    event HumanValidationSubmitted(uint256 indexed tokenId, address indexed validator, bool isPositive, string reviewHash);
    event AIValidationRequested(uint256 indexed tokenId, bytes32 indexed requestId, address indexed requester);
    event AIValidationFulfilled(uint256 indexed tokenId, bytes32 indexed requestId, bool isPositive, string aiReportHash);
    event ValidationConflictProposalCreated(uint256 indexed tokenId, uint256 indexed proposalId, address indexed initiator);
    event ReputationIncreased(address indexed user, uint256 amount);
    event ReputationDecreased(address indexed user, uint256 amount);
    event RoyaltySet(uint256 indexed tokenId, uint96 initialBps, uint96 aiBoostBps);
    event TopicSponsored(bytes32 indexed topicHash, address indexed sponsor, uint256 amount);
    event SponsorshipFundsClaimed(uint256 indexed tokenId, address indexed claimant, uint256 amount);
    event ReputationRewardClaimed(address indexed claimant, uint256 amount);
    event EvoTokensStaked(address indexed user, uint256 amount);
    event EvoTokensUnstaked(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, bytes32 parameterKey, uint256 newValue, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);


    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "CognitoNexus: Caller is not the AI Oracle");
        _;
    }

    modifier hasMinReputation(uint256 _minReputation) {
        require(reputationScores[msg.sender] >= _minReputation, "CognitoNexus: Insufficient reputation");
        _;
    }

    modifier notPaused() {
        _checkNotPaused();
        _;
    }

    // --- Constructor ---
    constructor(address _aiOracleAddress, address _evoTokenAddress) ERC721("KnowledgeUnit", "KU") Ownable(msg.sender) {
        require(_aiOracleAddress != address(0), "CognitoNexus: AI Oracle address cannot be zero");
        require(_evoTokenAddress != address(0), "CognitoNexus: Evo-Token address cannot be zero");
        aiOracle = IAIOracle(_aiOracleAddress);
        evoToken = IEvoToken(_evoTokenAddress);
        lastReputationDecayCycleTime = block.timestamp; // Initialize decay timer
    }

    // --- I. Core Protocol Management ---

    /// @dev Updates the trusted AI Oracle contract address. Only callable by the owner.
    /// @param _newOracle The new address of the AI Oracle contract.
    function updateAIOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "CognitoNexus: New AI Oracle address cannot be zero");
        emit AIOracleUpdated(address(aiOracle), _newOracle);
        aiOracle = IAIOracle(_newOracle);
    }

    /// @dev Updates the Evo-Token contract address. Only callable by the owner.
    /// @param _newEvoToken The new address of the Evo-Token contract.
    function updateEvoTokenAddress(address _newEvoToken) external onlyOwner {
        require(_newEvoToken != address(0), "CognitoNexus: New Evo-Token address cannot be zero");
        emit EvoTokenUpdated(address(evoToken), _newEvoToken);
        evoToken = IEvoToken(_newEvoToken);
    }

    /// @dev Pauses or unpauses core protocol functionalities. Only callable by the owner.
    /// @param _paused True to pause, false to unpause.
    function setProtocolPaused(bool _paused) external onlyOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    // --- II. Knowledge Unit (KU) Management (ERC-721) ---

    /// @dev Allows a user to mint a new Knowledge Unit (KU) NFT.
    ///      Requires an initial bounty in Evo-Tokens for validators.
    /// @param _metadataURI The URI pointing to the KU's metadata (e.g., IPFS hash).
    /// @param _initialBounty The amount of Evo-Tokens to allocate as a bounty for validation.
    /// @param _topicHash A hash representing the topic of the KU, for sponsorship matching.
    function mintKnowledgeUnit(string memory _metadataURI, uint256 _initialBounty, bytes32 _topicHash)
        external
        notPaused
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Transfer bounty from msg.sender to this contract
        require(evoToken.transferFrom(msg.sender, address(this), _initialBounty), "CognitoNexus: Evo-Token transfer failed for bounty");

        _safeMint(msg.sender, newTokenId);
        knowledgeUnits[newTokenId] = KnowledgeUnit({
            creator: msg.sender,
            metadataURI: _metadataURI,
            mintTime: block.timestamp,
            status: KUStatus.Pending,
            impactScore: 0,
            initialRoyaltyBps: 0, // Default to 0, creator can set later
            aiBoostRoyaltyBps: 0, // Default to 0, creator can set later
            currentBounty: _initialBounty,
            topicHash: _topicHash,
            latestRevisionId: 0
        });

        emit KnowledgeUnitMinted(newTokenId, msg.sender, _metadataURI, _initialBounty, _topicHash);
    }

    /// @dev Allows the KU owner (or approved entity) to update the KU's metadata URI.
    ///      This is for minor updates, for major changes `proposeKURevision` should be used.
    /// @param _tokenId The ID of the KU to update.
    /// @param _newMetadataURI The new URI for the KU's metadata.
    function updateKnowledgeUnitMetadata(uint256 _tokenId, string memory _newMetadataURI)
        external
        notPaused
    {
        require(_exists(_tokenId), "CognitoNexus: KU does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "CognitoNexus: Not KU owner or approved");
        
        knowledgeUnits[_tokenId].metadataURI = _newMetadataURI;
        emit KnowledgeUnitMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /// @dev Initiates a revision proposal for an existing KU.
    ///      Requires a certain reputation score to propose.
    /// @param _tokenId The ID of the KU to revise.
    /// @param _proposedMetadataURI The URI of the proposed new metadata.
    function proposeKURevision(uint256 _tokenId, string memory _proposedMetadataURI)
        external
        notPaused
        hasMinReputation(minReputationForProposal)
    {
        require(_exists(_tokenId), "CognitoNexus: KU does not exist");
        require(knowledgeUnits[_tokenId].status != KUStatus.Retired, "CognitoNexus: Cannot revise a retired KU");

        _revisionIdCounter.increment();
        uint256 newRevisionId = _revisionIdCounter.current();

        kuRevisions[newRevisionId] = KURevision({
            parentTokenId: _tokenId,
            proposer: msg.sender,
            proposedMetadataURI: _proposedMetadataURI,
            proposalTime: block.timestamp,
            status: RevisionStatus.Pending
        });

        emit KURevisionProposed(_tokenId, newRevisionId, msg.sender, _proposedMetadataURI);
    }

    /// @dev Approves a proposed KU revision. This simplified version assumes owner approval.
    ///      In a more complex system, this would be a vote or a multi-sig.
    /// @param _tokenId The ID of the KU.
    /// @param _revisionId The ID of the revision to approve.
    function approveKURevision(uint256 _tokenId, uint256 _revisionId)
        external
        onlyOwner // Simplified: only owner can approve revision. Could be a DAO vote.
        notPaused
    {
        require(_exists(_tokenId), "CognitoNexus: KU does not exist");
        require(kuRevisions[_revisionId].parentTokenId == _tokenId, "CognitoNexus: Revision ID mismatch");
        require(kuRevisions[_revisionId].status == RevisionStatus.Pending, "CognitoNexus: Revision not pending");

        kuRevisions[_revisionId].status = RevisionStatus.Approved;
        knowledgeUnits[_tokenId].metadataURI = kuRevisions[_revisionId].proposedMetadataURI;
        knowledgeUnits[_tokenId].latestRevisionId = _revisionId;
        // Optionally, impact score could be adjusted here based on revision quality/approval.

        emit KURevisionApproved(_tokenId, _revisionId, msg.sender);
        emit KnowledgeUnitMetadataUpdated(_tokenId, kuRevisions[_revisionId].proposedMetadataURI); // Re-emit for clarity
    }

    /// @dev Marks a KU as retired/obsolete. Can only be done by the owner or governance.
    /// @param _tokenId The ID of the KU to retire.
    function retireKnowledgeUnit(uint256 _tokenId) external onlyOwner notPaused {
        require(_exists(_tokenId), "CognitoNexus: KU does not exist");
        require(knowledgeUnits[_tokenId].status != KUStatus.Retired, "CognitoNexus: KU is already retired");
        
        knowledgeUnits[_tokenId].status = KUStatus.Retired;
        // Further actions: disable royalties, remove from active lists etc.
        emit KnowledgeUnitRetired(_tokenId);
    }

    // --- III. Reputation & Validation System ---

    /// @dev Retrieves the non-transferable reputation score for a given user.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    /// @dev Internal function to increase a user's reputation.
    /// @param _user The user's address.
    /// @param _amount The amount to increase reputation by.
    function _increaseReputation(address _user, uint256 _amount) internal {
        reputationScores[_user] += _amount;
        emit ReputationIncreased(_user, _amount);
    }

    /// @dev Internal function to decrease a user's reputation.
    /// @param _user The user's address.
    /// @param _amount The amount to decrease reputation by.
    function _decreaseReputation(address _user, uint256 _amount) internal {
        if (reputationScores[_user] > _amount) {
            reputationScores[_user] -= _amount;
        } else {
            reputationScores[_user] = 0;
        }
        emit ReputationDecreased(_user, _amount);
    }

    /// @dev Allows a high-reputation user to review and validate KUs.
    ///      Requires `minReputationForValidation`.
    ///      Awards reputation and transfers a portion of the KU's bounty.
    /// @param _tokenId The ID of the KU to validate.
    /// @param _isPositive True if the validation is positive, false otherwise.
    /// @param _reviewHash A hash linking to the human review details (e.g., IPFS).
    function submitHumanValidation(uint256 _tokenId, bool _isPositive, string memory _reviewHash)
        external
        notPaused
        hasMinReputation(minReputationForValidation)
    {
        require(_exists(_tokenId), "CognitoNexus: KU does not exist");
        require(
            knowledgeUnits[_tokenId].status == KUStatus.Pending || knowledgeUnits[_tokenId].status == KUStatus.Conflict,
            "CognitoNexus: KU not in valid state for human validation"
        );

        if (_isPositive) {
            _increaseReputation(msg.sender, reputationGainPerValidation);
            knowledgeUnits[_tokenId].status = KUStatus.HumanValidated;
            knowledgeUnits[_tokenId].impactScore += 1; // Simple impact boost
            
            // Transfer bounty to validator
            uint256 bountyShare = knowledgeUnits[_tokenId].currentBounty / 2; // For example, split bounty
            knowledgeUnits[_tokenId].currentBounty -= bountyShare;
            if (bountyShare > 0) {
                require(evoToken.transfer(msg.sender, bountyShare), "CognitoNexus: Bounty transfer failed");
            }

        } else {
            // Negative validation could lead to further review or decrease creator reputation
            _decreaseReputation(knowledgeUnits[_tokenId].creator, reputationLossPerInvalidKU / 2); // Half loss
        }
        emit HumanValidationSubmitted(_tokenId, msg.sender, _isPositive, _reviewHash);
    }

    /// @dev Initiates a request to the AI Oracle for automated validation or classification of a KU.
    ///      Requires payment of `aiValidationFee` in Evo-Tokens.
    /// @param _tokenId The ID of the KU to validate.
    /// @param _prompt A prompt string for the AI oracle (e.g., "classify this research paper").
    function requestAIValidation(uint256 _tokenId, string memory _prompt)
        external
        notPaused
    {
        require(_exists(_tokenId), "CognitoNexus: KU does not exist");
        require(knowledgeUnits[_tokenId].status != KUStatus.AIValidated, "CognitoNexus: KU already AI validated");
        
        // Transfer AI validation fee from msg.sender to this contract
        require(evoToken.transferFrom(msg.sender, address(this), aiValidationFee), "CognitoNexus: Evo-Token transfer failed for AI fee");

        bytes32 requestId = aiOracle.requestValidation(address(this), _tokenId, _prompt);
        aiRequestTokenId[requestId] = _tokenId; // Map request ID to the token ID

        emit AIValidationRequested(_tokenId, requestId, msg.sender);
    }

    /// @dev Callback function used by the AI Oracle to deliver validation results.
    ///      Only callable by the `aiOracle` address.
    /// @param _tokenId The ID of the KU that was validated.
    /// @param _requestId The request ID originally provided to the AI Oracle.
    /// @param _isPositive True if the AI validation is positive, false otherwise.
    /// @param _aiReportHash A hash linking to the AI's detailed report (e.g., IPFS).
    function fulfillAIValidation(uint256 _tokenId, bytes32 _requestId, bool _isPositive, string memory _aiReportHash)
        external
        onlyAIOracle
        notPaused
    {
        require(aiRequestTokenId[_requestId] == _tokenId, "CognitoNexus: Mismatched request ID and token ID");
        require(_exists(_tokenId), "CognitoNexus: KU does not exist");
        
        KUStatus currentStatus = knowledgeUnits[_tokenId].status;

        if (_isPositive) {
            if (currentStatus == KUStatus.HumanValidated) {
                knowledgeUnits[_tokenId].impactScore += 2;
                knowledgeUnits[_tokenId].status = KUStatus.AIValidated;
                _increaseReputation(knowledgeUnits[_tokenId].creator, reputationGainPerValidation * 2);
            } else if (currentStatus == KUStatus.Pending) {
                knowledgeUnits[_tokenId].impactScore += 1;
                knowledgeUnits[_tokenId].status = KUStatus.AIValidated;
                _increaseReputation(knowledgeUnits[_tokenId].creator, reputationGainPerValidation);
            } else if (currentStatus == KUStatus.Conflict) {
                 knowledgeUnits[_tokenId].status = KUStatus.AIValidated; // AI resolves positively
                 _increaseReputation(knowledgeUnits[_tokenId].creator, reputationGainPerValidation / 2);
            }
        } else { // AI validation is negative
            if (currentStatus == KUStatus.HumanValidated) {
                knowledgeUnits[_tokenId].status = KUStatus.Conflict; // Conflict detected
                _decreaseReputation(knowledgeUnits[_tokenId].creator, reputationLossPerInvalidKU / 2); // Partial penalty
            } else if (currentStatus == KUStatus.Pending) {
                _decreaseReputation(knowledgeUnits[_tokenId].creator, reputationLossPerInvalidKU);
                // KU remains pending or gets marked as disputed, not explicitly retired.
            }
        }
        
        delete aiRequestTokenId[_requestId]; // Clean up request ID
        emit AIValidationFulfilled(_tokenId, _requestId, _isPositive, _aiReportHash);
    }

    /// @dev Triggers a governance proposal to resolve conflicts if human and AI validations differ significantly.
    /// @param _tokenId The ID of the KU with a conflict.
    function resolveValidationConflict(uint256 _tokenId) external notPaused {
        require(_exists(_tokenId), "CognitoNexus: KU does not exist");
        require(knowledgeUnits[_tokenId].status == KUStatus.Conflict, "CognitoNexus: No validation conflict for this KU");
        require(stakedEvoTokens[msg.sender] > 0, "CognitoNexus: Must have staked Evo-Tokens to initiate conflict resolution");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();
        
        // This parameterKey indicates a special proposal type for KU status resolution
        bytes32 conflictResolutionKey = keccak256(abi.encodePacked("KU_STATUS_RESOLUTION_", _tokenId));

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            parameterKey: conflictResolutionKey,
            newValue: 0, // Value decided by vote, e.g., vote FOR (newValue=1) to approve, AGAINST (newValue=0) to reject (retire/re-evaluate)
            startVoteTime: block.timestamp,
            endVoteTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });
        
        emit ProposalCreated(newProposalId, conflictResolutionKey, 0, msg.sender);
        emit ValidationConflictProposalCreated(_tokenId, newProposalId, msg.sender);
    }
    
    // --- IV. Dynamic Incentives & Rewards ---

    /// @dev Allows the KU creator to set dynamic royalty percentages for their KU.
    ///      Royalties can increase if the KU achieves AI validation.
    /// @param _tokenId The ID of the KU.
    /// @param _initialBps The base royalty percentage in basis points (e.g., 250 for 2.5%).
    /// @param _aiBoostBps The additional royalty percentage if the KU is AI-validated.
    function setKnowledgeUnitDynamicRoyalty(uint256 _tokenId, uint96 _initialBps, uint96 _aiBoostBps)
        external
        notPaused
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "CognitoNexus: Not KU owner or approved");
        require(_initialBps <= MAX_BPS, "CognitoNexus: Initial royalty exceeds 100%");
        require((_initialBps + _aiBoostBps) <= MAX_BPS, "CognitoNexus: Total royalty exceeds 100%");

        knowledgeUnits[_tokenId].initialRoyaltyBps = _initialBps;
        knowledgeUnits[_tokenId].aiBoostRoyaltyBps = _aiBoostBps;

        emit RoyaltySet(_tokenId, _initialBps, _aiBoostBps);
    }

    /// @dev Enables users to deposit Evo-Tokens to sponsor specific knowledge topics.
    ///      This incentivizes contributions in those areas.
    /// @param _topicHash A hash representing the topic to sponsor.
    /// @param _amount The amount of Evo-Tokens to deposit for sponsorship.
    function sponsorKnowledgeTopic(bytes32 _topicHash, uint256 _amount)
        external
        notPaused
    {
        require(_amount > 0, "CognitoNexus: Sponsorship amount must be greater than zero");
        require(evoToken.transferFrom(msg.sender, address(this), _amount), "CognitoNexus: Evo-Token transfer failed for sponsorship");

        sponsoredTopics[_topicHash] += _amount;
        emit TopicSponsored(_topicHash, msg.sender, _amount);
    }

    /// @dev Allows the creator of a KU, which matches a sponsored topic and has sufficient impact,
    ///      to claim a portion of the sponsorship funds.
    /// @param _tokenId The ID of the KU.
    function claimSponsorshipFunds(uint256 _tokenId) external notPaused {
        require(_exists(_tokenId), "CognitoNexus: KU does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "CognitoNexus: Not KU owner or approved");
        require(knowledgeUnits[_tokenId].impactScore > 0, "CognitoNexus: KU has no impact score");
        require(!kuTopicClaimed[_tokenId][msg.sender], "CognitoNexus: Sponsorship already claimed for this KU by this user");

        bytes32 kuTopicHash = knowledgeUnits[_tokenId].topicHash;
        uint256 availableSponsorship = sponsoredTopics[kuTopicHash];

        require(availableSponsorship > 0, "CognitoNexus: No sponsorship available for this topic");

        // Simple claim logic: A percentage of the total pool based on impact score, capped.
        // E.g., (impact / (impact + 100)) of the pool, capped at a certain amount or percentage.
        uint256 claimAmount = (availableSponsorship * knowledgeUnits[_tokenId].impactScore) / (knowledgeUnits[_tokenId].impactScore + 1000); // 0.1% for impact=1, up to ~10% for impact=100

        if (claimAmount == 0) return; // Not enough to claim, or impact too low

        require(evoToken.transfer(msg.sender, claimAmount), "CognitoNexus: Failed to transfer claim funds");
        sponsoredTopics[kuTopicHash] -= claimAmount;
        kuTopicClaimed[_tokenId][msg.sender] = true;

        emit SponsorshipFundsClaimed(_tokenId, msg.sender, claimAmount);
    }

    /// @dev Allows users with a sufficiently high reputation score to claim periodic Evo-Token rewards.
    ///      This function also triggers a simplified reputation decay for the caller.
    function claimReputationReward() external notPaused {
        uint256 currentReputation = reputationScores[msg.sender];
        require(currentReputation > 0, "CognitoNexus: No reputation to claim rewards");

        // Apply decay lazily when user interacts
        _applyReputationDecay(msg.sender);

        // Example reward mechanism: 1 Evo-Token per 1000 reputation score
        uint256 rewardAmount = (currentReputation / 1000) * 1 * (10 ** 18);

        if (rewardAmount == 0) return;

        // Mint Evo-Tokens to the user (assuming EvoToken has a mint function callable by this contract)
        evoToken.mint(msg.sender, rewardAmount);
        
        emit ReputationRewardClaimed(msg.sender, rewardAmount);
    }
    
    /// @dev Internal function to apply reputation decay for a user.
    ///      This is a lazy decay, calculated based on the global decay cycle time.
    /// @param _user The address of the user for whom to apply decay.
    function _applyReputationDecay(address _user) internal {
        uint256 currentRep = reputationScores[_user];
        if (currentRep == 0) return;

        // Simplified decay: Decay is applied based on the time elapsed since the last global decay cycle.
        // Each `decayCycleDuration` (e.g., 1 week) results in `reputationDecayRateBps` decay.
        uint256 decayCycleDuration = 7 days; // One week
        uint256 elapsedCycles = (block.timestamp - lastReputationDecayCycleTime) / decayCycleDuration;

        if (elapsedCycles == 0) return; // No new decay cycles have passed globally

        // Recalculate reputation based on how many global decay cycles have passed.
        // This is a simplified model. A more accurate model would use a 'last active' timestamp per user.
        uint256 decayFactor = 10000 - reputationDecayRateBps; // e.g., 9900 if rate is 100 (1%)

        // Apply decay repeatedly for each elapsed cycle
        for (uint256 i = 0; i < elapsedCycles; i++) {
            currentRep = (currentRep * decayFactor) / MAX_BPS;
        }
        
        if (currentRep < reputationScores[_user]) {
            reputationScores[_user] = currentRep;
            emit ReputationDecreased(_user, reputationScores[_user] - currentRep);
        }
    }
    
    // Function to update the global reputation decay cycle time.
    // Can be called by anyone, but only applies to the *global* timer after a cooldown.
    // Actual decay is lazy-calculated per user.
    function triggerGlobalReputationDecayCycle() external notPaused {
        uint256 decayCycleDuration = 7 days; // One week
        require(block.timestamp >= lastReputationDecayCycleTime + decayCycleDuration, "CognitoNexus: Global decay cycle already triggered recently");
        lastReputationDecayCycleTime = block.timestamp;
        // This acts as a timestamp update for the lazy decay calculation.
    }


    // --- V. Governance & Protocol Evolution ---

    /// @dev Users can stake Evo-Tokens to gain voting power and participate in governance.
    /// @param _amount The amount of Evo-Tokens to stake.
    function stakeEvoTokens(uint256 _amount) external notPaused {
        require(_amount > 0, "CognitoNexus: Stake amount must be greater than zero");
        require(evoToken.transferFrom(msg.sender, address(this), _amount), "CognitoNexus: Evo-Token transfer failed for staking");
        stakedEvoTokens[msg.sender] += _amount;
        emit EvoTokensStaked(msg.sender, _amount);
    }

    /// @dev Allows users to unstake their Evo-Tokens after a defined cooldown period.
    /// @param _amount The amount of Evo-Tokens to unstake.
    function unstakeEvoTokens(uint256 _amount) external notPaused {
        require(_amount > 0, "CognitoNexus: Unstake amount must be greater than zero");
        require(stakedEvoTokens[msg.sender] >= _amount, "CognitoNexus: Insufficient staked Evo-Tokens");
        require(block.timestamp >= lastUnstakeRequestTime[msg.sender] + unstakeCooldown, "CognitoNexus: Unstake cooldown period not over");

        stakedEvoTokens[msg.sender] -= _amount;
        require(evoToken.transfer(msg.sender, _amount), "CognitoNexus: Evo-Token transfer failed for unstaking");
        lastUnstakeRequestTime[msg.sender] = block.timestamp; // Update cooldown for next request
        emit EvoTokensUnstaked(msg.sender, _amount);
    }

    /// @dev Allows stakers to propose changes to key protocol parameters.
    ///      Requires a certain reputation score and minimum staked tokens.
    /// @param _parameterKey A unique key identifying the parameter (e.g., "AI_FEE", "REPUTATION_DECAY_RATE").
    /// @param _newValue The new value proposed for the parameter.
    function proposeProtocolParameterChange(bytes32 _parameterKey, uint256 _newValue)
        external
        notPaused
        hasMinReputation(minReputationForProposal)
    {
        require(stakedEvoTokens[msg.sender] > 0, "CognitoNexus: Must have staked Evo-Tokens to propose");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            parameterKey: _parameterKey,
            newValue: _newValue,
            startVoteTime: block.timestamp,
            endVoteTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });

        emit ProposalCreated(newProposalId, _parameterKey, _newValue, msg.sender);
    }

    /// @dev Enables stakers to cast their vote on active governance proposals.
    ///      Voting power is proportional to staked Evo-Tokens.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external notPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "CognitoNexus: Proposal does not exist");
        require(block.timestamp >= proposal.startVoteTime && block.timestamp <= proposal.endVoteTime, "CognitoNexus: Voting period not active");
        require(!proposal.hasVoted[msg.sender], "CognitoNexus: Already voted on this proposal");
        require(stakedEvoTokens[msg.sender] > 0, "CognitoNexus: Must have staked Evo-Tokens to vote");

        if (_support) {
            proposal.votesFor += stakedEvoTokens[msg.sender];
        } else {
            proposal.votesAgainst += stakedEvoTokens[msg.sender];
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _support);
    }

    /// @dev Executes a successfully passed governance proposal, applying the proposed parameter change.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external notPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "CognitoNexus: Proposal does not exist");
        require(block.timestamp > proposal.endVoteTime, "CognitoNexus: Voting period not ended");
        require(!proposal.executed, "CognitoNexus: Proposal already executed");

        uint256 totalParticipatingVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalParticipatingVotes > 0, "CognitoNexus: No votes cast");

        // Check quorum: require min percentage of participating votes to be 'for'
        bool passed = (proposal.votesFor * 100) / totalParticipatingVotes >= proposalQuorum;
        proposal.passed = passed;

        if (passed) {
            // Apply the parameter change based on parameterKey
            bytes32 key = proposal.parameterKey;
            uint256 val = proposal.newValue;

            if (key == keccak256(abi.encodePacked("MIN_REP_VALIDATION"))) {
                minReputationForValidation = val;
            } else if (key == keccak256(abi.encodePacked("REP_GAIN_VALIDATION"))) {
                reputationGainPerValidation = val;
            } else if (key == keccak256(abi.encodePacked("REP_LOSS_INVALID_KU"))) {
                reputationLossPerInvalidKU = val;
            } else if (key == keccak256(abi.encodePacked("AI_VALIDATION_FEE"))) {
                aiValidationFee = val;
            } else if (key == keccak256(abi.encodePacked("VOTING_PERIOD"))) {
                votingPeriod = val;
            } else if (key == keccak256(abi.encodePacked("PROPOSAL_QUORUM"))) {
                require(val <= 100, "CognitoNexus: Quorum percent invalid (max 100)");
                proposalQuorum = val;
            } else if (key == keccak256(abi.encodePacked("UNSTAKE_COOLDOWN"))) {
                unstakeCooldown = val;
            } else if (key == keccak256(abi.encodePacked("MIN_REP_PROPOSAL"))) {
                minReputationForProposal = val;
            } else if (key == keccak256(abi.encodePacked("REPUTATION_DECAY_RATE_BPS"))) {
                require(val <= MAX_BPS, "CognitoNexus: Decay rate invalid (max 10000)");
                reputationDecayRateBps = val;
            }
            // Handling KU_STATUS_RESOLUTION proposals from `resolveValidationConflict`
            else if (bytes(key).length > keccak256(abi.encodePacked("KU_STATUS_RESOLUTION_")).length && keccak256(bytes(key).slice(0, keccak256(abi.encodePacked("KU_STATUS_RESOLUTION_")).length)) == keccak256(abi.encodePacked("KU_STATUS_RESOLUTION_"))) {
                // Extract tokenId from the key. This requires careful byte manipulation.
                // For simplicity, let's assume `newValue` directly indicates the KU status (e.g., 1 for AIValidated, 4 for Retired)
                // In a real system, the proposal might explicitly include the tokenId in a dedicated field or the target status.
                
                // For this example, let's hardcode the effect for passed KU_STATUS_RESOLUTION proposals:
                // It means the conflict is resolved in favor of making it AIValidated.
                // If it was meant to be retired, that would be a separate proposal type or `newValue`.
                uint256 tokenId = uint256(key); // Simplified: Treat the last part of the hash as tokenId (not robust, for example only)
                // A better approach would embed the tokenId directly in the Proposal struct for this type of proposal.
                
                // Example simplified resolution: If passed, force to AIValidated. Otherwise, mark as Retired.
                if (proposal.votesFor > proposal.votesAgainst) { // If 'for' votes prevail in conflict resolution
                     knowledgeUnits[tokenId].status = KUStatus.AIValidated;
                     knowledgeUnits[tokenId].impactScore +=1; // Small boost for resolution
                     _increaseReputation(knowledgeUnits[tokenId].creator, reputationGainPerValidation);
                } else {
                     knowledgeUnits[tokenId].status = KUStatus.Retired;
                     _decreaseReputation(knowledgeUnits[tokenId].creator, reputationLossPerInvalidKU);
                }
            }
            // Add more parameter keys as needed
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }
}
```