Okay, this is an exciting challenge! I've designed a smart contract system called "Ethereal Echoes," focusing on verifiable data claims, dynamic reputation (Soulbound Tokens), AI oracle integration for enhanced validation, and the creation of a decentralized knowledge graph through semantic linking of validated claims.

The core idea is to move beyond simple tokenization to a system that incentivizes truthful data attestation and collaborative, AI-assisted validation, all while building an on-chain, evolving identity for participants.

---

## Ethereal Echoes: The Verifiable Data Synthesis Network

**Concept:** A decentralized network for synthesizing, attesting, and validating *verifiable data claims* that contribute to a "Collective Intelligence Ledger." Users can submit data claims (hashes of data, metadata), stake tokens on their veracity, request validation, and evolve a "Reputation Echo" (a Soulbound Token/Dynamic NFT) based on their contributions and accuracy. The system also integrates bounties for AI-powered data analysis and allows for the semantic linking of validated claims to form a decentralized knowledge graph.

### Outline and Function Summary

This contract, "EtherealEchoes," establishes a decentralized network for synthesizing, attesting, and validating verifiable data claims. Participants submit data claims (represented by a hash and metadata URI), stake a native token (EEToken) on their veracity, and engage in a validation and dispute resolution process. A unique "Reputation Echo" (a non-transferable Soulbound Token or SBT) tracks each participant's standing, dynamically evolving based on their contributions, accuracy, and engagement. The system also integrates AI oracle bounties for advanced claim analysis and enables the creation of a decentralized knowledge graph by linking related validated claims.

---

**I. Core Data Claims & Attestation**
*   Manages the lifecycle of data claims, from submission to final validation.
*   Functions for submitting new claims, updating metadata, revoking pending claims, and retrieving claim details.

1.  `submitDataClaim(bytes32 _dataHash, string calldata _metadataURI, uint256 _stakeAmount)`: Submit a new data claim with its hash, metadata, and initial stake.
2.  `updateClaimMetadata(uint256 _claimId, string calldata _newMetadataURI)`: Update the metadata URI of a pending claim.
3.  `revokeDataClaim(uint256 _claimId)`: Revoke a pending claim and retrieve the initial stake.
4.  `getDataClaimDetails(uint256 _claimId) view returns (...)`: Retrieve comprehensive details of a specific data claim.
5.  `getClaimsByStatus(ClaimStatus _status, uint256 _offset, uint256 _limit) view returns (uint256[] memory)`: Retrieve a paginated list of claim IDs based on their status.

---

**II. Reputation Echo (Soulbound Token - ERC721-NonTransferable)**
*   Mints and manages non-transferable ERC721 tokens that represent a user's reputation.
*   Reputation scores are dynamically updated based on user actions within the network.
*   *Note: The `ReputationEcho` contract is a separate, dedicated SBT contract that `EtherealEchoes` interacts with. Its functions are listed here for completeness of the system.*

6.  `mintReputationEcho()` (on `EtherealEchoes`): Trigger the minting of a new Reputation Echo SBT for the caller if they don't have one (delegates to `ReputationEcho`).
7.  `getReputationScore(address _owner) view returns (uint256)`: Retrieve the current reputation score of an address.
8.  `getEchoTokenURI(uint256 _tokenId) view returns (string memory)`: Retrieve the dynamic metadata URI for an Echo (reflects its score).
9.  `_updateReputationScore(address _user, int256 _delta)` (Internal on `EtherealEchoes`): Internal function to adjust a user's reputation score on their Reputation Echo.

---

**III. Validation Network & Staking**
*   Facilitates a decentralized validation process for data claims.
*   Users stake EEToken to become validators and earn rewards for accurate assessments.

10. `stakeForValidation(uint256 _amount)`: Stake EEToken to join the validator network.
11. `unstakeFromValidation(uint256 _amount)`: Request to unstake EEToken, subject to a cooldown.
12. `withdrawStakedTokens()`: Withdraw unstaked tokens after the cooldown period.
13. `requestClaimValidation(uint256 _claimId, uint256 _bountyAmount)`: Initiate a validation request for a claim, offering a bounty.
14. `submitValidationResult(uint256 _claimId, bool _isValid, uint256 _confidenceScore, uint256 _stakeAmount)`: Validators submit their assessment (true/false, confidence) and stake on it.
15. `finalizeClaimValidation(uint256 _claimId)`: Finalize a claim's status based on validation consensus, distributing rewards/penalties.

---

**IV. Dispute Resolution System**
*   Provides a mechanism to challenge and resolve contested claims or validation results.
*   Users stake tokens to initiate disputes, which are then resolved by an arbiter.

16. `initiateDispute(uint256 _claimId, uint256 _validationResultId, string calldata _evidenceURI, uint256 _stakeAmount)`: Initiate a dispute against a finalized claim or specific validation result.
17. `submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceURI)`: Submit additional evidence during an active dispute.
18. `resolveDispute(uint256 _disputeId, bool _ruling)`: An authorized arbiter resolves a dispute, distributing stakes and applying penalties/rewards.

---

**V. AI-Assisted Analysis Bounties (Oracle Integration)**
*   Enables the creation of bounties for off-chain AI services to analyze data claims.
*   Integrates with authorized AI oracles to enrich claim validation.

19. `setAuthorizedAIOracle(address _oracleAddress, bool _isAuthorized)`: Owner function to authorize or deauthorize AI oracles.
20. `requestAIAssistedAnalysis(uint256 _claimId, uint256 _bountyAmount, string calldata _analysisRequestURI)`: Create a bounty for an AI oracle to analyze a claim.
21. `submitAIAssistedAnalysisResult(uint256 _bountyId, string calldata _resultURI, bytes32 _resultHash)`: Authorized AI oracle submits its analysis result.
22. `claimAIAnalysisBounty(uint256 _bountyId)`: AI oracle claims its bounty after result acceptance.

---

**VI. Semantic Linking & Knowledge Graph**
*   Allows users to propose and validate semantic relationships between claims, building a decentralized knowledge graph.

23. `proposeClaimRelationship(uint256 _claimId1, uint256 _claimId2, string calldata _relationshipType, string calldata _descriptionURI, uint256 _stakeAmount)`: Propose a semantic link between two validated claims.
24. `validateClaimRelationship(uint256 _relationshipId, bool _isAccurate, uint256 _confidenceScore, uint256 _stakeAmount)`: Validators assess the accuracy of a proposed relationship.
25. `getRelatedClaims(uint256 _claimId) view returns (uint256[] memory)`: Retrieve all validated claims semantically linked to a given claim.

---

**Total Functions:** 25 functions in the `EtherealEchoes` contract, plus 5 core functions in the `ReputationEcho` (SBT) contract that `EtherealEchoes` interacts with, fulfilling the requirement for at least 20 functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For ReputationEcho's tokenURI

// --- Outline and Function Summary ---
// This contract, "EtherealEchoes," establishes a decentralized network for synthesizing,
// attesting, and validating verifiable data claims. Participants submit data claims
// (represented by a hash and metadata URI), stake a native token (EEToken) on their veracity,
// and engage in a validation and dispute resolution process. A unique "Reputation Echo"
// (a non-transferable Soulbound Token or SBT) tracks each participant's standing, dynamically
// evolving based on their contributions, accuracy, and engagement. The system also
// integrates AI oracle bounties for advanced claim analysis and enables the creation
// of a decentralized knowledge graph by linking related validated claims.

// I. Core Data Claims & Attestation
//    - Manages the lifecycle of data claims, from submission to final validation.
//    - Functions for submitting new claims, updating metadata, revoking pending claims,
//      and retrieving claim details.
//      1. submitDataClaim: Submit a new data claim with its hash, metadata, and initial stake.
//      2. updateClaimMetadata: Update the metadata URI of a pending claim.
//      3. revokeDataClaim: Revoke a pending claim and retrieve the initial stake.
//      4. getDataClaimDetails: Retrieve comprehensive details of a specific data claim.
//      5. getClaimsByStatus: Retrieve a paginated list of claim IDs based on their status.

// II. Reputation Echo (Soulbound Token - ERC721-NonTransferable)
//    - Mints and manages non-transferable ERC721 tokens that represent a user's reputation.
//    - Reputation scores are dynamically updated based on user actions within the network.
//      6. mintReputationEcho: Trigger the minting of a new Reputation Echo SBT for a user.
//      7. getReputationScore: Retrieve the current reputation score of an address.
//      8. getEchoTokenURI: Retrieve the dynamic metadata URI for an Echo (reflects score).
//      9. _updateReputationScore: Internal function to adjust a user's reputation score.

// III. Validation Network & Staking
//    - Facilitates a decentralized validation process for data claims.
//    - Users stake EEToken to become validators and earn rewards for accurate assessments.
//      10. stakeForValidation: Stake EEToken to join the validator network.
//      11. unstakeFromValidation: Request to unstake EEToken, subject to a cooldown.
//      12. withdrawStakedTokens: Withdraw unstaked tokens after the cooldown period.
//      13. requestClaimValidation: Initiate a validation request for a claim, offering a bounty.
//      14. submitValidationResult: Validators submit their assessment (true/false, confidence).
//      15. finalizeClaimValidation: Finalize a claim's status based on validation consensus.

// IV. Dispute Resolution System
//    - Provides a mechanism to challenge and resolve contested claims or validation results.
//    - Users stake tokens to initiate disputes, which are then resolved by an arbiter.
//      16. initiateDispute: Initiate a dispute against a finalized claim/validation.
//      17. submitDisputeEvidence: Submit additional evidence during an active dispute.
//      18. resolveDispute: An arbiter resolves a dispute, distributing stakes and applying penalties.

// V. AI-Assisted Analysis Bounties (Oracle Integration)
//    - Enables the creation of bounties for off-chain AI services to analyze data claims.
//    - Integrates with authorized AI oracles to enrich claim validation.
//      19. setAuthorizedAIOracle: Owner function to authorize or deauthorize AI oracles.
//      20. requestAIAssistedAnalysis: Create a bounty for an AI oracle to analyze a claim.
//      21. submitAIAssistedAnalysisResult: Authorized AI oracle submits its analysis result.
//      22. claimAIAnalysisBounty: AI oracle claims its bounty after result acceptance.

// VI. Semantic Linking & Knowledge Graph
//    - Allows users to propose and validate semantic relationships between claims, building a decentralized knowledge graph.
//      23. proposeClaimRelationship: Propose a semantic link between two validated claims.
//      24. validateClaimRelationship: Validators assess the accuracy of a proposed relationship.
//      25. getRelatedClaims: Retrieve all validated claims semantically linked to a given claim.


contract EtherealEchoes is Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    IERC20 public immutable EEToken; // The native utility token for staking and rewards

    // --- Configuration Constants ---
    uint256 public constant MIN_CLAIM_STAKE = 1 ether; // Minimum stake for submitting a claim
    uint256 public constant MIN_VALIDATOR_STAKE = 10 ether; // Minimum stake to be a validator
    uint256 public constant VALIDATION_COOLDOWN_PERIOD = 7 days; // Cooldown for unstaking and claim validation period
    uint256 public constant MIN_VALIDATORS_FOR_CONSENSUS = 3; // Minimum validators required for claim finalization
    uint256 public constant CONSENSUS_THRESHOLD_PERCENT = 70; // % positive votes for VALIDATED status
    uint256 public constant REPUTATION_GAIN_VALIDATION_CORRECT = 10; // Reputation points gained for correct validation
    uint256 public constant REPUTATION_LOSS_VALIDATION_INCORRECT = 20; // Reputation points lost for incorrect validation
    uint256 public constant REPUTATION_GAIN_CLAIM_VALIDATED = 5; // Reputation points gained for own claim being validated
    uint256 public constant REPUTATION_LOSS_CLAIM_INVALIDATED = 15; // Reputation points lost for own claim being invalidated
    uint256 public constant DISPUTE_RESOLUTION_FEE_PERCENT = 10; // % of dispute stake as fee for resolution
    address public immutable ARBITER_OR_DAO_GOVERNOR; // Address for dispute resolution/governance

    // --- Enums ---
    enum ClaimStatus { PENDING, VALIDATION_REQUESTED, VALIDATED, INVALIDATED, DISPUTED }
    enum DisputeStatus { ACTIVE, RESOLVED_FOR_CLAIMANT, RESOLVED_AGAINST_CLAIMANT }
    enum RelationshipStatus { PROPOSED, VALIDATED, REJECTED }

    // --- Structs ---
    struct DataClaim {
        bytes32 dataHash;
        string metadataURI;
        address owner;
        uint256 initialStake;
        ClaimStatus status;
        uint256 validationBounty; // Total bounty offered for validation
        uint256 totalValidationStake; // Sum of stakes from all validators for this claim
        uint256 submittedTimestamp;
        uint256 validationDeadline; // When validation period ends
        uint256 positiveValidationVotes;
        uint256 negativeValidationVotes;
        uint256 disputeId; // 0 if no active dispute
        mapping(address => bool) hasValidated; // Tracks if a validator has already voted
    }

    struct ValidationResult {
        uint256 claimId;
        address validator;
        bool isValid;
        uint256 confidenceScore; // 0-100
        uint256 stake; // Validator's stake on this specific validation
        uint256 rewardAmount; // Actual reward amount for this specific result
        uint256 timestamp;
        bool rewarded; // To prevent double rewarding
        bool slashed; // To prevent double slashing
        bool claimed; // To prevent double claiming
    }

    struct ValidatorProfile {
        uint256 stakedAmount; // Total amount staked by the validator
        uint256 unstakeRequestedAmount; // Amount requested to unstake
        uint256 unstakeRequestTimestamp; // 0 if no unstake request
        uint256 lastActivityTimestamp; // For liveness checks
        uint256 totalRewardEarned; // Total rewards accumulated, but not yet withdrawn
        uint256 totalPenaltyIncurred;
    }

    struct Dispute {
        uint256 claimId;
        uint256 validationResultId; // If dispute is against a specific validation (0 for overall claim)
        address initiator;
        string evidenceURI;
        uint256 initiatorStake;
        DisputeStatus status;
        uint256 timestamp;
        address arbiter; // Who resolved it
    }

    struct AIBounty {
        uint256 claimId;
        address creator;
        uint256 bountyAmount;
        string analysisRequestURI; // URI to description of required analysis
        string resultURI; // URI to AI analysis result
        bytes32 resultHash; // Hash of the AI analysis result
        address aiOracle; // Address of the AI oracle that fulfilled the bounty
        bool fulfilled;
        bool claimed;
        uint256 creationTimestamp;
    }

    struct ClaimRelationship {
        uint256 claimId1;
        uint256 claimId2;
        string relationshipType; // e.g., "supersedes", "is_part_of", "contradicts"
        string descriptionURI; // URI explaining the relationship
        address proposer;
        uint256 proposerStake;
        RelationshipStatus status;
        uint256 validationBounty; // Could add bounty for relationship validation
        uint256 positiveValidationVotes;
        uint256 negativeValidationVotes;
        mapping(address => bool) hasValidated;
    }

    // --- Mappings ---
    mapping(uint256 => DataClaim) public claims;
    Counters.Counter private _claimIds;

    mapping(uint256 => ValidationResult) public validationResults;
    Counters.Counter private _validationResultIds;
    mapping(uint256 => uint256[]) public claimToValidationResults; // claimId => array of validationResultIds

    mapping(address => ValidatorProfile) public validators;
    mapping(address => bool) public isValidator; // Quick check

    mapping(uint256 => Dispute) public disputes;
    Counters.Counter private _disputeIds;

    mapping(uint256 => AIBounty) public aiBounties;
    Counters.Counter private _aiBountyIds;
    mapping(address => bool) public authorizedAIOracles; // Whitelist of trusted AI oracles

    mapping(uint256 => ClaimRelationship) public claimRelationships;
    Counters.Counter private _relationshipIds;
    mapping(uint256 => uint256[]) public claimToRelationships; // claimId => array of relationshipIds

    // --- Reputation Echo (SBT) ---
    ReputationEcho public reputationEcho;

    // --- Events ---
    event ClaimSubmitted(uint256 indexed claimId, address indexed owner, bytes32 dataHash, string metadataURI);
    event ClaimMetadataUpdated(uint256 indexed claimId, string newMetadataURI);
    event ClaimRevoked(uint256 indexed claimId, address indexed owner);
    event ValidationRequested(uint256 indexed claimId, address indexed requestor, uint256 bountyAmount);
    event ValidationSubmitted(uint256 indexed claimId, uint256 indexed validationResultId, address indexed validator, bool isValid, uint256 confidenceScore);
    event ClaimFinalized(uint256 indexed claimId, ClaimStatus newStatus, uint256 totalBountyDistributed);
    event ValidatorStaked(address indexed validator, uint256 amount);
    event ValidatorUnstakeRequested(address indexed validator, uint256 amount, uint256 unlockTime);
    event ValidatorUnstaked(address indexed validator, uint256 amount);
    event ValidationRewardClaimed(address indexed validator, uint256 amount);
    event ReputationScoreUpdated(address indexed user, uint256 newScore, int256 delta);
    event DisputeInitiated(uint252 indexed disputeId, uint256 indexed claimId, address indexed initiator);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, string evidenceURI);
    event DisputeResolved(uint256 indexed disputeId, bool ruling, address indexed arbiter);
    event AIBountyRequested(uint256 indexed bountyId, uint256 indexed claimId, address indexed creator, uint256 bountyAmount);
    event AIBountyFulfilled(uint256 indexed bountyId, address indexed aiOracle, string resultURI, bytes32 resultHash);
    event AIBountyClaimed(uint256 indexed bountyId, address indexed aiOracle, uint256 amount);
    event RelationshipProposed(uint256 indexed relationshipId, uint256 indexed claimId1, uint256 indexed claimId2, string relationshipType);
    event RelationshipValidated(uint256 indexed relationshipId, address indexed validator, bool isAccurate);
    event RelationshipFinalized(uint256 indexed relationshipId, RelationshipStatus newStatus);

    modifier onlyValidator() {
        require(isValidator[msg.sender], "EE: Caller is not a validator");
        _;
    }

    modifier onlyAuthorizedAIOracle() {
        require(authorizedAIOracles[msg.sender], "EE: Caller is not an authorized AI oracle");
        _;
    }

    constructor(address _EETokenAddress, address _reputationEchoAddress, address _arbiterOrDaoGovernor) Ownable(msg.sender) {
        require(_EETokenAddress != address(0), "EE: EEToken address cannot be zero");
        require(_reputationEchoAddress != address(0), "EE: ReputationEcho address cannot be zero");
        require(_arbiterOrDaoGovernor != address(0), "EE: Arbiter/Governor address cannot be zero");
        EEToken = IERC20(_EETokenAddress);
        reputationEcho = ReputationEcho(_reputationEchoAddress);
        ARBITER_OR_DAO_GOVERNOR = _arbiterOrDaoGovernor;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // --- I. Core Data Claims & Attestation ---

    /**
     * @notice Submits a new data claim with its hash, metadata URI, and an initial stake.
     * @param _dataHash The SHA256 hash of the data being claimed.
     * @param _metadataURI A URI pointing to additional metadata about the claim (e.g., IPFS hash).
     * @param _stakeAmount The amount of EEToken to stake on the claim's veracity.
     */
    function submitDataClaim(bytes32 _dataHash, string calldata _metadataURI, uint256 _stakeAmount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_stakeAmount >= MIN_CLAIM_STAKE, "EE: Initial stake below minimum");
        require(EEToken.transferFrom(msg.sender, address(this), _stakeAmount), "EE: Token transfer failed");

        _claimIds.increment();
        uint256 newClaimId = _claimIds.current();

        claims[newClaimId] = DataClaim({
            dataHash: _dataHash,
            metadataURI: _metadataURI,
            owner: msg.sender,
            initialStake: _stakeAmount,
            status: ClaimStatus.PENDING,
            validationBounty: 0,
            totalValidationStake: 0,
            submittedTimestamp: block.timestamp,
            validationDeadline: 0, // Set when validation is requested
            positiveValidationVotes: 0,
            negativeValidationVotes: 0,
            disputeId: 0
        });

        // Ensure user has an Echo, mint if not, and give small reputation boost
        if (reputationEcho.balanceOf(msg.sender) == 0) {
            reputationEcho.mintReputationEcho(msg.sender);
        }
        _updateReputationScore(msg.sender, REPUTATION_GAIN_CLAIM_VALIDATED / 2);

        emit ClaimSubmitted(newClaimId, msg.sender, _dataHash, _metadataURI);
    }

    /**
     * @notice Allows the owner of a PENDING claim to update its metadata URI.
     * @param _claimId The ID of the claim to update.
     * @param _newMetadataURI The new URI for the claim's metadata.
     */
    function updateClaimMetadata(uint256 _claimId, string calldata _newMetadataURI) external whenNotPaused {
        DataClaim storage claim = claims[_claimId];
        require(claim.owner == msg.sender, "EE: Not claim owner");
        require(claim.status == ClaimStatus.PENDING, "EE: Claim not in PENDING status");

        claim.metadataURI = _newMetadataURI;
        emit ClaimMetadataUpdated(_claimId, _newMetadataURI);
    }

    /**
     * @notice Allows the owner of a PENDING claim to revoke it, retrieving their initial stake.
     * @param _claimId The ID of the claim to revoke.
     */
    function revokeDataClaim(uint256 _claimId) external whenNotPaused nonReentrant {
        DataClaim storage claim = claims[_claimId];
        require(claim.owner == msg.sender, "EE: Not claim owner");
        require(claim.status == ClaimStatus.PENDING, "EE: Claim not in PENDING status");

        require(EEToken.transfer(msg.sender, claim.initialStake), "EE: Failed to return stake");
        
        claim.status = ClaimStatus.INVALIDATED; // Mark as invalidated/revoked
        claim.initialStake = 0; // Clear stake reference

        _updateReputationScore(msg.sender, -(REPUTATION_LOSS_CLAIM_INVALIDATED / 2)); // Small penalty for revocation

        emit ClaimRevoked(_claimId, msg.sender);
    }

    /**
     * @notice Retrieves all details of a specific data claim.
     * @param _claimId The ID of the claim.
     * @return dataHash The hash of the data.
     * @return metadataURI The URI for the claim's metadata.
     * @return owner The address of the claim's owner.
     * @return initialStake The initial stake amount.
     * @return status The current status of the claim.
     * @return validationBounty The current total bounty for validation.
     * @return totalValidationStake The total stake from validators.
     * @return submittedTimestamp The timestamp of submission.
     * @return validationDeadline The deadline for validation.
     * @return positiveVotes Count of positive validation votes.
     * @return negativeVotes Count of negative validation votes.
     * @return disputeId The ID of an active dispute, if any.
     */
    function getDataClaimDetails(uint256 _claimId)
        external
        view
        returns (
            bytes32 dataHash,
            string memory metadataURI,
            address owner,
            uint256 initialStake,
            ClaimStatus status,
            uint256 validationBounty,
            uint256 totalValidationStake,
            uint256 submittedTimestamp,
            uint256 validationDeadline,
            uint256 positiveVotes,
            uint256 negativeVotes,
            uint256 disputeId
        )
    {
        DataClaim storage claim = claims[_claimId];
        require(claim.owner != address(0), "EE: Claim does not exist");
        return (
            claim.dataHash,
            claim.metadataURI,
            claim.owner,
            claim.initialStake,
            claim.status,
            claim.validationBounty,
            claim.totalValidationStake,
            claim.submittedTimestamp,
            claim.validationDeadline,
            claim.positiveValidationVotes,
            claim.negativeValidationVotes,
            claim.disputeId
        );
    }

    /**
     * @notice Retrieves a paginated list of claim IDs by their current status.
     *         Note: This is an expensive operation for many claims and might exceed gas limits.
     *         For production, off-chain indexing is usually preferred for such queries.
     * @param _status The desired status to filter claims.
     * @param _offset The starting index for pagination.
     * @param _limit The maximum number of claim IDs to return.
     * @return An array of claim IDs matching the criteria.
     */
    function getClaimsByStatus(ClaimStatus _status, uint256 _offset, uint256 _limit)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tempResult = new uint256[](_claimIds.current()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _claimIds.current(); i++) {
            if (claims[i].owner != address(0) && claims[i].status == _status) {
                tempResult[count] = i;
                count++;
            }
        }

        uint256 actualStart = _offset;
        uint256 actualEnd = _offset + _limit;
        if (actualStart >= count) {
            return new uint256[](0); // No results for this offset
        }
        if (actualEnd > count) {
            actualEnd = count;
        }

        uint256[] memory paginatedResult = new uint256[](actualEnd - actualStart);
        for (uint256 i = actualStart; i < actualEnd; i++) {
            paginatedResult[i - actualStart] = tempResult[i];
        }
        return paginatedResult;
    }


    // --- II. Reputation Echo (Soulbound Token - ERC721-NonTransferable) ---
    // The ReputationEcho contract is deployed separately and its address is passed to the constructor.

    /**
     * @notice Internal function to adjust a user's reputation score.
     *         Called by other functions within this contract based on user actions.
     * @param _user The address whose reputation to update.
     * @param _delta The amount to change the reputation score by (can be negative).
     */
    function _updateReputationScore(address _user, int256 _delta) internal {
        if (reputationEcho.balanceOf(_user) == 0) {
            reputationEcho.mintReputationEcho(_user); // Ensure user has an Echo
        }
        uint256 tokenId = reputationEcho.tokenOfOwnerByIndex(_user, 0); // Assuming one Echo per user
        uint256 currentScore = reputationEcho.getScore(tokenId);
        
        uint256 newScore;
        unchecked {
            if (_delta < 0) {
                uint256 absDelta = uint256(-_delta);
                newScore = currentScore > absDelta ? currentScore - absDelta : 0;
            } else {
                newScore = currentScore + uint256(_delta);
            }
        }
        reputationEcho.setScore(tokenId, newScore);
        emit ReputationScoreUpdated(_user, newScore, _delta);
    }

    /**
     * @notice Mints a new Reputation Echo SBT for the caller if they don't have one.
     *         If the user already has one, this function does nothing as per `ReputationEcho` logic.
     */
    function mintReputationEcho() external whenNotPaused {
        reputationEcho.mintReputationEcho(msg.sender);
    }

    /**
     * @notice Returns the current reputation score of an address.
     * @param _owner The address whose reputation score is to be retrieved.
     * @return The current reputation score.
     */
    function getReputationScore(address _owner) external view returns (uint256) {
        if (reputationEcho.balanceOf(_owner) == 0) {
            return 0; // No Echo, no reputation
        }
        uint256 tokenId = reputationEcho.tokenOfOwnerByIndex(_owner, 0);
        return reputationEcho.getScore(tokenId);
    }

    /**
     * @notice Returns the dynamic metadata URI for an Echo, reflecting its evolving traits/score.
     * @param _tokenId The token ID of the Reputation Echo.
     * @return The metadata URI.
     */
    function getEchoTokenURI(uint256 _tokenId) external view returns (string memory) {
        return reputationEcho.tokenURI(_tokenId);
    }


    // --- III. Validation Network & Staking ---

    /**
     * @notice Allows a user to stake tokens to become an active validator.
     * @param _amount The amount of EEToken to stake.
     */
    function stakeForValidation(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount >= MIN_VALIDATOR_STAKE, "EE: Stake amount below minimum");
        require(EEToken.transferFrom(msg.sender, address(this), _amount), "EE: Token transfer failed");

        ValidatorProfile storage profile = validators[msg.sender];
        profile.stakedAmount += _amount;
        profile.lastActivityTimestamp = block.timestamp;
        isValidator[msg.sender] = true;

        if (reputationEcho.balanceOf(msg.sender) == 0) {
            reputationEcho.mintReputationEcho(msg.sender);
        }
        _updateReputationScore(msg.sender, REPUTATION_GAIN_VALIDATION_CORRECT / 2); // Small boost for staking

        emit ValidatorStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a validator to request unstaking tokens, subject to a cooldown period.
     * @param _amount The amount of EEToken to unstake.
     */
    function unstakeFromValidation(uint256 _amount) external whenNotPaused nonReentrant {
        ValidatorProfile storage profile = validators[msg.sender];
        require(profile.stakedAmount >= _amount, "EE: Not enough staked tokens");
        require(profile.unstakeRequestTimestamp == 0, "EE: Already have an unstake request pending");
        require(_amount > 0, "EE: Unstake amount must be positive");
        
        profile.unstakeRequestedAmount = _amount;
        profile.unstakeRequestTimestamp = block.timestamp;

        // Note: The actual 'stakedAmount' is not reduced until withdraw to ensure full stake is available for current duties
        // but 'unstakeRequestedAmount' is now pending.
        
        emit ValidatorUnstakeRequested(msg.sender, _amount, block.timestamp + VALIDATION_COOLDOWN_PERIOD);
    }

    /**
     * @notice Allows a user to withdraw their unstaked tokens after the cooldown period.
     */
    function withdrawStakedTokens() external whenNotPaused nonReentrant {
        ValidatorProfile storage profile = validators[msg.sender];
        require(profile.unstakeRequestTimestamp != 0, "EE: No pending unstake request");
        require(block.timestamp >= profile.unstakeRequestTimestamp + VALIDATION_COOLDOWN_PERIOD, "EE: Cooldown period not over");
        
        uint256 amountToWithdraw = profile.unstakeRequestedAmount;
        require(amountToWithdraw > 0, "EE: No tokens to withdraw from request");

        profile.stakedAmount -= amountToWithdraw; // Reduce actual staked amount
        profile.unstakeRequestedAmount = 0;
        profile.unstakeRequestTimestamp = 0;
        
        if (profile.stakedAmount < MIN_VALIDATOR_STAKE) {
            isValidator[msg.sender] = false; // Revoke validator status if below minimum
        }

        require(EEToken.transfer(msg.sender, amountToWithdraw), "EE: Failed to withdraw tokens");
        emit ValidatorUnstaked(msg.sender, amountToWithdraw);
    }

    /**
     * @notice Initiates a validation request for a claim, offering a bounty to validators.
     * @param _claimId The ID of the claim to validate.
     * @param _bountyAmount The total bounty offered for validation.
     */
    function requestClaimValidation(uint256 _claimId, uint256 _bountyAmount) external whenNotPaused nonReentrant {
        DataClaim storage claim = claims[_claimId];
        require(claim.owner != address(0), "EE: Claim does not exist");
        require(claim.status == ClaimStatus.PENDING, "EE: Claim not in PENDING status");
        require(_bountyAmount > 0, "EE: Bounty must be greater than zero");
        require(EEToken.transferFrom(msg.sender, address(this), _bountyAmount), "EE: Bounty token transfer failed");

        claim.status = ClaimStatus.VALIDATION_REQUESTED;
        claim.validationBounty += _bountyAmount;
        claim.validationDeadline = block.timestamp + VALIDATION_COOLDOWN_PERIOD;

        emit ValidationRequested(_claimId, msg.sender, _bountyAmount);
    }

    /**
     * @notice A staked validator submits their assessment of a claim's veracity and a confidence score.
     * @param _claimId The ID of the claim being validated.
     * @param _isValid True if the validator believes the claim is valid, false otherwise.
     * @param _confidenceScore A score from 0 to 100 indicating the validator's confidence.
     * @param _stakeAmount The amount of EEToken the validator stakes on their assessment.
     */
    function submitValidationResult(uint256 _claimId, bool _isValid, uint256 _confidenceScore, uint256 _stakeAmount)
        external
        onlyValidator
        whenNotPaused
        nonReentrant
    {
        DataClaim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.VALIDATION_REQUESTED, "EE: Claim not in validation stage");
        require(block.timestamp <= claim.validationDeadline, "EE: Validation period has ended");
        require(!claim.hasValidated[msg.sender], "EE: Validator already submitted for this claim");
        require(validators[msg.sender].stakedAmount >= _stakeAmount, "EE: Validator's total stake is less than submitted stake");
        require(_stakeAmount > 0, "EE: Must stake a positive amount for validation");
        require(_confidenceScore <= 100, "EE: Confidence score out of range (0-100)");

        // Temporarily transfer stake from validator's total staked amount to the contract for this validation
        // This stake will be managed during finalization.
        validators[msg.sender].stakedAmount -= _stakeAmount;
        claim.totalValidationStake += _stakeAmount; // Track total stake involved in this claim's validation

        _validationResultIds.increment();
        uint256 newResultId = _validationResultIds.current();

        validationResults[newResultId] = ValidationResult({
            claimId: _claimId,
            validator: msg.sender,
            isValid: _isValid,
            confidenceScore: _confidenceScore,
            stake: _stakeAmount,
            rewardAmount: 0, // Calculated during finalization
            timestamp: block.timestamp,
            rewarded: false,
            slashed: false,
            claimed: false
        });

        if (_isValid) {
            claim.positiveValidationVotes++;
        } else {
            claim.negativeValidationVotes++;
        }
        claim.hasValidated[msg.sender] = true;
        claimToValidationResults[_claimId].push(newResultId);

        emit ValidationSubmitted(_claimId, newResultId, msg.sender, _isValid, _confidenceScore);
    }

    /**
     * @notice Finalizes a claim's status based on validation consensus.
     *         Can be called by any user after validation period or minimum validators met.
     * @param _claimId The ID of the claim to finalize.
     */
    function finalizeClaimValidation(uint256 _claimId) external whenNotPaused nonReentrant {
        DataClaim storage claim = claims[_claimId];
        require(claim.owner != address(0), "EE: Claim does not exist");
        require(claim.status == ClaimStatus.VALIDATION_REQUESTED, "EE: Claim not in validation stage");
        
        // Ensure minimum validators have participated or deadline passed
        uint256 totalValidationVotes = claim.positiveValidationVotes + claim.negativeValidationVotes;
        require(
            totalValidationVotes >= MIN_VALIDATORS_FOR_CONSENSUS || 
            block.timestamp > claim.validationDeadline, 
            "EE: Not enough validators or deadline not reached"
        );

        ClaimStatus newStatus;
        uint256 totalBountyDistributed = 0;

        if (totalValidationVotes == 0) {
            // If no validators participated, revert to PENDING or handle as unvalidated
            // For now, revert original state if no one validated
            claim.status = ClaimStatus.PENDING;
            if (claim.validationBounty > 0) {
                require(EEToken.transfer(claim.owner, claim.validationBounty), "EE: Failed to return bounty");
                claim.validationBounty = 0;
            }
            emit ClaimFinalized(_claimId, ClaimStatus.PENDING, 0);
            return;
        }

        bool isClaimValid = (claim.positiveValidationVotes * 100 / totalValidationVotes >= CONSENSUS_THRESHOLD_PERCENT);
        newStatus = isClaimValid ? ClaimStatus.VALIDATED : ClaimStatus.INVALIDATED;

        // Handle Claim Owner's Stake & Reputation
        if (newStatus == ClaimStatus.VALIDATED) {
            require(EEToken.transfer(claim.owner, claim.initialStake), "EE: Failed to return initial stake for validated claim");
            _updateReputationScore(claim.owner, REPUTATION_GAIN_CLAIM_VALIDATED);
        } else { // INVALIDATED
            // Owner's initial stake is now effectively lost (stays in contract as part of system pool)
            _updateReputationScore(claim.owner, -REPUTATION_LOSS_CLAIM_INVALIDATED);
        }
        claim.initialStake = 0; // Clear stake reference

        // Handle Validators' Stakes, Rewards, and Reputation
        uint256 totalCorrectValidatorStake = 0;
        for (uint256 i = 0; i < claimToValidationResults[_claimId].length; i++) {
            uint256 resultId = claimToValidationResults[_claimId][i];
            ValidationResult storage result = validationResults[resultId];
            
            if (result.isValid == isClaimValid) { // Validator voted correctly
                totalCorrectValidatorStake += result.stake;
                // Return staked amount to validator's available stakedAmount (before potential reward)
                validators[result.validator].stakedAmount += result.stake;
                _updateReputationScore(result.validator, REPUTATION_GAIN_VALIDATION_CORRECT);
                result.rewarded = true; // Mark as eligible for reward
            } else { // Validator voted incorrectly
                // Slash the validator's stake. This stake stays in the contract
                validators[result.validator].totalPenaltyIncurred += result.stake;
                _updateReputationScore(result.validator, -REPUTATION_LOSS_VALIDATION_INCORRECT);
                result.slashed = true;
            }
        }

        // Distribute bounty proportionally among correct validators
        if (isClaimValid && claim.validationBounty > 0 && totalCorrectValidatorStake > 0) {
            for (uint256 i = 0; i < claimToValidationResults[_claimId].length; i++) {
                uint256 resultId = claimToValidationResults[_claimId][i];
                ValidationResult storage result = validationResults[resultId];

                if (result.rewarded) { // If validator was correct
                    uint256 reward = (claim.validationBounty * result.stake) / totalCorrectValidatorStake;
                    result.rewardAmount = reward; // Store specific reward amount for claiming
                    validators[result.validator].totalRewardEarned += reward; // Accumulate for validator
                    totalBountyDistributed += reward;
                }
            }
        }
        // Any undistributed bounty (e.g., if totalCorrectValidatorStake was 0) remains in the contract's balance

        claim.status = newStatus;
        emit ClaimFinalized(_claimId, newStatus, totalBountyDistributed);
    }

    // --- IV. Dispute Resolution System ---

    /**
     * @notice Initiates a dispute against a finalized claim's status or a specific validation result.
     * @param _claimId The ID of the claim being disputed.
     * @param _validationResultId The ID of the specific validation result being disputed (0 if disputing overall claim status).
     * @param _evidenceURI A URI pointing to evidence supporting the dispute.
     * @param _stakeAmount The amount of EEToken to stake on the dispute.
     */
    function initiateDispute(uint256 _claimId, uint256 _validationResultId, string calldata _evidenceURI, uint256 _stakeAmount)
        external
        whenNotPaused
        nonReentrant
    {
        DataClaim storage claim = claims[_claimId];
        require(claim.owner != address(0), "EE: Claim does not exist");
        require(claim.status == ClaimStatus.VALIDATED || claim.status == ClaimStatus.INVALIDATED, "EE: Claim not finalized");
        require(claim.disputeId == 0, "EE: Claim already has an active dispute");
        require(_stakeAmount > 0, "EE: Dispute stake must be positive");
        require(EEToken.transferFrom(msg.sender, address(this), _stakeAmount), "EE: Dispute stake transfer failed");

        if (_validationResultId != 0) {
            require(validationResults[_validationResultId].claimId == _claimId, "EE: Validation result not for this claim");
        }

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            claimId: _claimId,
            validationResultId: _validationResultId,
            initiator: msg.sender,
            evidenceURI: _evidenceURI,
            initiatorStake: _stakeAmount,
            status: DisputeStatus.ACTIVE,
            timestamp: block.timestamp,
            arbiter: address(0)
        });

        claim.disputeId = newDisputeId;
        claim.status = ClaimStatus.DISPUTED; // Mark claim as disputed

        emit DisputeInitiated(newDisputeId, _claimId, msg.sender);
    }

    /**
     * @notice Allows participants in a dispute to submit additional evidence.
     * @param _disputeId The ID of the active dispute.
     * @param _evidenceURI A URI pointing to the additional evidence.
     */
    function submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceURI) external whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.initiator != address(0), "EE: Dispute does not exist");
        require(dispute.status == DisputeStatus.ACTIVE, "EE: Dispute is not active");

        // Simple implementation: update evidence URI. A more complex system might store an array of evidence.
        dispute.evidenceURI = _evidenceURI; 
        
        emit DisputeEvidenceSubmitted(_disputeId, msg.sender, _evidenceURI);
    }

    /**
     * @notice An authorized arbiter resolves a dispute, distributing stakes and applying penalties/rewards.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _ruling True if the dispute initiator's claim is upheld (original status/validation was wrong), false otherwise.
     */
    function resolveDispute(uint256 _disputeId, bool _ruling) external whenNotPaused nonReentrant {
        require(msg.sender == owner() || msg.sender == ARBITER_OR_DAO_GOVERNOR, "EE: Caller is not an authorized arbiter");

        Dispute storage dispute = disputes[_disputeId];
        require(dispute.initiator != address(0), "EE: Dispute does not exist");
        require(dispute.status == DisputeStatus.ACTIVE, "EE: Dispute is not active");

        DataClaim storage claim = claims[dispute.claimId];
        dispute.arbiter = msg.sender;

        if (_ruling) { // Initiator's claim upheld (original validation/status was incorrect)
            dispute.status = DisputeStatus.RESOLVED_FOR_CLAIMANT;
            uint256 rewardAmount = dispute.initiatorStake; // Initiator gets their stake back

            // Apply penalties to original incorrect validators
            for (uint256 i = 0; i < claimToValidationResults[dispute.claimId].length; i++) {
                uint256 resultId = claimToValidationResults[dispute.claimId][i];
                ValidationResult storage originalResult = validationResults[resultId];

                // If this specific validation was the target of dispute OR if overall claim status changed,
                // and this validator's vote now contradicts the new ruling.
                bool validatorWasIncorrect = (dispute.validationResultId != 0 && resultId == dispute.validationResultId && !originalResult.isValid) ||
                                             (dispute.validationResultId == 0 && originalResult.isValid == (claim.status == ClaimStatus.VALIDATED));

                if (validatorWasIncorrect && !originalResult.slashed) {
                    validators[originalResult.validator].totalPenaltyIncurred += originalResult.stake;
                    _updateReputationScore(originalResult.validator, -REPUTATION_LOSS_VALIDATION_INCORRECT * 2); // Double penalty
                    originalResult.slashed = true;
                    // The slashed stake could be added to dispute initiator's reward or burned. For now, it stays in contract.
                }
            }

            // Update original claim owner's reputation and status if overall claim was disputed
            if (dispute.validationResultId == 0) {
                if (claim.status == ClaimStatus.VALIDATED) { // Original was VALIDATED, now proven INVALIDATED
                    claim.status = ClaimStatus.INVALIDATED;
                    _updateReputationScore(claim.owner, -REPUTATION_LOSS_CLAIM_INVALIDATED * 2); // Double penalty for owner
                } else if (claim.status == ClaimStatus.INVALIDATED) { // Original was INVALIDATED, now proven VALIDATED
                    claim.status = ClaimStatus.VALIDATED;
                    _updateReputationScore(claim.owner, REPUTATION_GAIN_CLAIM_VALIDATED * 2); // Double reward for owner
                    // If initial stake was "slashed" for original invalidation, it's not recoverable here easily without more complex tracking.
                }
            }
            
            require(EEToken.transfer(dispute.initiator, rewardAmount), "EE: Failed to return dispute initiator stake");
            _updateReputationScore(dispute.initiator, REPUTATION_GAIN_VALIDATION_CORRECT * 2); // Reward for successful dispute
        } else { // Initiator's claim rejected (original validation/status was correct)
            dispute.status = DisputeStatus.RESOLVED_AGAINST_CLAIMANT;
            uint256 arbiterFee = (dispute.initiatorStake * DISPUTE_RESOLUTION_FEE_PERCENT) / 100;
            require(EEToken.transfer(ARBITER_OR_DAO_GOVERNOR, arbiterFee), "EE: Failed to pay arbiter fee");
            // Remainder of initiator's stake is effectively burned (stays in contract)
            _updateReputationScore(dispute.initiator, -REPUTATION_LOSS_VALIDATION_INCORRECT * 2); // Penalty for failed dispute
        }
        claim.disputeId = 0; // Clear active dispute
        emit DisputeResolved(_disputeId, _ruling, msg.sender);
    }

    // --- V. AI-Assisted Analysis Bounties (Oracle Integration) ---

    /**
     * @notice Allows the owner to authorize or deauthorize an AI oracle.
     * @param _oracleAddress The address of the AI oracle.
     * @param _isAuthorized True to authorize, false to deauthorize.
     */
    function setAuthorizedAIOracle(address _oracleAddress, bool _isAuthorized) external onlyOwner {
        authorizedAIOracles[_oracleAddress] = _isAuthorized;
    }

    /**
     * @notice Creates a bounty for an AI oracle service to perform an advanced analysis on a claim.
     * @param _claimId The ID of the claim requiring AI analysis.
     * @param _bountyAmount The amount of EEToken offered as a bounty.
     * @param _analysisRequestURI A URI describing the specific AI analysis requested.
     */
    function requestAIAssistedAnalysis(uint256 _claimId, uint256 _bountyAmount, string calldata _analysisRequestURI)
        external
        whenNotPaused
        nonReentrant
    {
        DataClaim storage claim = claims[_claimId];
        require(claim.owner != address(0), "EE: Claim does not exist");
        require(claim.status == ClaimStatus.VALIDATION_REQUESTED || claim.status == ClaimStatus.DISPUTED, "EE: AI analysis only for validation or disputed claims");
        require(_bountyAmount > 0, "EE: Bounty must be greater than zero");
        require(EEToken.transferFrom(msg.sender, address(this), _bountyAmount), "EE: Bounty token transfer failed");

        _aiBountyIds.increment();
        uint256 newBountyId = _aiBountyIds.current();

        aiBounties[newBountyId] = AIBounty({
            claimId: _claimId,
            creator: msg.sender,
            bountyAmount: _bountyAmount,
            analysisRequestURI: _analysisRequestURI,
            resultURI: "",
            resultHash: bytes32(0),
            aiOracle: address(0),
            fulfilled: false,
            claimed: false,
            creationTimestamp: block.timestamp
        });

        emit AIBountyRequested(newBountyId, _claimId, msg.sender, _bountyAmount);
    }

    /**
     * @notice An authorized AI oracle submits its analysis result for a bounty.
     * @param _bountyId The ID of the AI bounty being fulfilled.
     * @param _resultURI A URI pointing to the AI analysis result.
     * @param _resultHash The hash of the AI analysis result (for integrity verification).
     */
    function submitAIAssistedAnalysisResult(uint256 _bountyId, string calldata _resultURI, bytes32 _resultHash)
        external
        onlyAuthorizedAIOracle
        whenNotPaused
    {
        AIBounty storage bounty = aiBounties[_bountyId];
        require(bounty.creator != address(0), "EE: AI Bounty does not exist");
        require(!bounty.fulfilled, "EE: AI Bounty already fulfilled");

        bounty.resultURI = _resultURI;
        bounty.resultHash = _resultHash;
        bounty.aiOracle = msg.sender;
        bounty.fulfilled = true;

        emit AIBountyFulfilled(_bountyId, msg.sender, _resultURI, _resultHash);
    }

    /**
     * @notice The AI oracle claims its bounty after submission is accepted.
     *         Acceptance logic is simplified to implicit upon submission by an authorized oracle.
     * @param _bountyId The ID of the AI bounty to claim.
     */
    function claimAIAnalysisBounty(uint256 _bountyId) external onlyAuthorizedAIOracle whenNotPaused nonReentrant {
        AIBounty storage bounty = aiBounties[_bountyId];
        require(bounty.creator != address(0), "EE: AI Bounty does not exist");
        require(bounty.fulfilled, "EE: AI Bounty not yet fulfilled");
        require(!bounty.claimed, "EE: AI Bounty already claimed");
        require(bounty.aiOracle == msg.sender, "EE: Only fulfilling oracle can claim bounty");

        bounty.claimed = true;
        require(EEToken.transfer(msg.sender, bounty.bountyAmount), "EE: Failed to transfer bounty");

        emit AIBountyClaimed(_bountyId, msg.sender, bounty.bountyAmount);
    }


    // --- VI. Semantic Linking & Knowledge Graph ---

    /**
     * @notice Allows users to propose a semantic link between two validated claims.
     * @param _claimId1 The ID of the first claim.
     * @param _claimId2 The ID of the second claim.
     * @param _relationshipType A string describing the nature of the relationship (e.g., "supersedes", "is_part_of").
     * @param _descriptionURI A URI providing more context/evidence for the relationship.
     * @param _stakeAmount The amount of EEToken to stake on the proposed relationship.
     */
    function proposeClaimRelationship(uint256 _claimId1, uint256 _claimId2, string calldata _relationshipType, string calldata _descriptionURI, uint256 _stakeAmount)
        external
        whenNotPaused
        nonReentrant
    {
        DataClaim storage claim1 = claims[_claimId1];
        DataClaim storage claim2 = claims[_claimId2];
        require(claim1.owner != address(0) && claim2.owner != address(0), "EE: One or both claims do not exist");
        require(claim1.status == ClaimStatus.VALIDATED && claim2.status == ClaimStatus.VALIDATED, "EE: Both claims must be VALIDATED");
        require(_claimId1 != _claimId2, "EE: Cannot relate a claim to itself");
        require(_stakeAmount >= MIN_CLAIM_STAKE, "EE: Relationship stake below minimum");
        require(EEToken.transferFrom(msg.sender, address(this), _stakeAmount), "EE: Relationship stake transfer failed");

        _relationshipIds.increment();
        uint256 newRelationshipId = _relationshipIds.current();

        claimRelationships[newRelationshipId] = ClaimRelationship({
            claimId1: _claimId1,
            claimId2: _claimId2,
            relationshipType: _relationshipType,
            descriptionURI: _descriptionURI,
            proposer: msg.sender,
            proposerStake: _stakeAmount,
            status: RelationshipStatus.PROPOSED,
            validationBounty: 0, 
            positiveValidationVotes: 0,
            negativeValidationVotes: 0
        });

        claimToRelationships[_claimId1].push(newRelationshipId);
        claimToRelationships[_claimId2].push(newRelationshipId); // Bidirectional linking

        emit RelationshipProposed(newRelationshipId, _claimId1, _claimId2, _relationshipType);
    }

    /**
     * @notice Staked validators assess the accuracy of a proposed claim relationship.
     * @param _relationshipId The ID of the relationship to validate.
     * @param _isAccurate True if the validator agrees with the proposed relationship, false otherwise.
     * @param _confidenceScore A score from 0 to 100 indicating the validator's confidence.
     * @param _stakeAmount The amount of EEToken the validator stakes on their assessment.
     */
    function validateClaimRelationship(uint256 _relationshipId, bool _isAccurate, uint256 _confidenceScore, uint256 _stakeAmount)
        external
        onlyValidator
        whenNotPaused
        nonReentrant
    {
        ClaimRelationship storage relationship = claimRelationships[_relationshipId];
        require(relationship.proposer != address(0), "EE: Relationship does not exist");
        require(relationship.status == RelationshipStatus.PROPOSED, "EE: Relationship not in PROPOSED status");
        require(!relationship.hasValidated[msg.sender], "EE: Validator already submitted for this relationship");
        require(validators[msg.sender].stakedAmount >= _stakeAmount, "EE: Validator's total stake is less than submitted stake");
        require(_stakeAmount > 0, "EE: Must stake a positive amount for relationship validation");
        require(_confidenceScore <= 100, "EE: Confidence score out of range (0-100)");

        // Reduce validator's available stake (conceptually, it's now 'staked' on this relationship)
        validators[msg.sender].stakedAmount -= _stakeAmount;

        if (_isAccurate) {
            relationship.positiveValidationVotes++;
        } else {
            relationship.negativeValidationVotes++;
        }
        relationship.hasValidated[msg.sender] = true;

        // Simplified finalization: If enough votes are in, finalize immediately.
        uint256 totalVotes = relationship.positiveValidationVotes + relationship.negativeValidationVotes;
        if (totalVotes >= MIN_VALIDATORS_FOR_CONSENSUS) {
            bool isRelationshipAccurate = (relationship.positiveValidationVotes * 100 / totalVotes >= CONSENSUS_THRESHOLD_PERCENT);
            
            if (isRelationshipAccurate) {
                relationship.status = RelationshipStatus.VALIDATED;
                _updateReputationScore(relationship.proposer, REPUTATION_GAIN_CLAIM_VALIDATED); // Reward proposer
                require(EEToken.transfer(relationship.proposer, relationship.proposerStake), "EE: Failed to return proposer stake");
            } else {
                relationship.status = RelationshipStatus.REJECTED;
                _updateReputationScore(relationship.proposer, -REPUTATION_LOSS_CLAIM_INVALIDATED); // Penalize proposer
                // Proposer stake is burned (remains in contract)
            }
            
            // For a robust system, validators' stakes on relationship would also be managed (returned/slashed).
            // This would require storing individual validator stakes per relationship similar to DataClaim.
            // For brevity here, that detailed logic is omitted, and only proposer's stake is handled.
        }

        emit RelationshipValidated(_relationshipId, msg.sender, _isAccurate);
        if (relationship.status != RelationshipStatus.PROPOSED) {
            emit RelationshipFinalized(_relationshipId, relationship.status);
        }
    }

    /**
     * @notice Retrieves all validated claims semantically linked to a given claim.
     * @param _claimId The ID of the claim for which to find related claims.
     * @return An array of claim IDs related to the input claim.
     */
    function getRelatedClaims(uint256 _claimId) external view returns (uint256[] memory) {
        require(claims[_claimId].owner != address(0), "EE: Claim does not exist");

        uint256[] memory relatedRelationshipIds = claimToRelationships[_claimId];
        uint256[] memory tempRelatedClaims = new uint256[](relatedRelationshipIds.length);
        uint256 count = 0;

        for (uint256 i = 0; i < relatedRelationshipIds.length; i++) {
            ClaimRelationship storage rel = claimRelationships[relatedRelationshipIds[i]];
            if (rel.status == RelationshipStatus.VALIDATED) {
                if (rel.claimId1 == _claimId) {
                    tempRelatedClaims[count] = rel.claimId2;
                } else {
                    tempRelatedClaims[count] = rel.claimId1;
                }
                count++;
            }
        }

        uint256[] memory finalResult = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalResult[i] = tempRelatedClaims[i];
        }
        return finalResult;
    }

    // --- VII. Token & Reward Management ---

    /**
     * @notice Allows validators to claim rewards for multiple successful validations.
     * @param _validationResultIds An array of validation result IDs for which to claim rewards.
     */
    function claimValidationReward(uint256[] calldata _validationResultIds) external whenNotPaused nonReentrant {
        uint256 totalRewardToClaim = 0;
        for (uint256 i = 0; i < _validationResultIds.length; i++) {
            ValidationResult storage result = validationResults[_validationResultIds[i]];
            require(result.validator == msg.sender, "EE: Not validator of this result");
            require(result.rewarded, "EE: Result not eligible for reward (or incorrect)");
            require(!result.claimed, "EE: Reward for this result already claimed");
            
            totalRewardToClaim += result.rewardAmount;
            result.claimed = true;
            validators[msg.sender].totalRewardEarned -= result.rewardAmount; // Deduct from accumulated
        }
        require(totalRewardToClaim > 0, "EE: No rewards to claim");
        require(EEToken.transfer(msg.sender, totalRewardToClaim), "EE: Failed to transfer total rewards");
        emit ValidationRewardClaimed(msg.sender, totalRewardToClaim);
    }
}


// --- Reputation Echo SBT Contract ---
// This is a separate contract that EtherealEchoes interacts with.
// It is kept simple for demonstration.

contract ReputationEcho is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;

    // Reputation score for each token
    mapping(uint256 => uint256) public tokenReputationScore;

    constructor() ERC721("ReputationEcho", "ECHO") Ownable(msg.sender) {}

    // Overrides to make tokens non-transferable (Soulbound)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        // Allow minting (from address(0)) and burning (to address(0)) but no transfers between users
        require(from == address(0) || to == address(0), "ECHO: Reputation Echo tokens are non-transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Explicitly make transfer functions unavailable to reinforce non-transferability
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("ECHO: Reputation Echo tokens are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("ECHO: Reputation Echo tokens are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert("ECHO: Reputation Echo tokens are non-transferable");
    }

    /**
     * @notice Mints a new Reputation Echo SBT for the specified address if they don't have one.
     * @param _to The address to mint the token for.
     */
    function mintReputationEcho(address _to) external onlyOwner { // Only owner (EtherealEchoes contract) can mint
        require(balanceOf(_to) == 0, "ECHO: Address already has a Reputation Echo");
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(_to, newTokenId);
        tokenReputationScore[newTokenId] = 0; // Initialize score
    }

    /**
     * @notice Returns the reputation score of a specific Reputation Echo token.
     * @param _tokenId The ID of the token.
     * @return The reputation score.
     */
    function getScore(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "ECHO: Token does not exist");
        return tokenReputationScore[_tokenId];
    }

    /**
     * @notice Sets the reputation score for a specific Reputation Echo token.
     *         Only callable by the owner (EtherealEchoes contract).
     * @param _tokenId The ID of the token.
     * @param _newScore The new reputation score.
     */
    function setScore(uint256 _tokenId, uint256 _newScore) external onlyOwner {
        require(_exists(_tokenId), "ECHO: Token does not exist");
        tokenReputationScore[_tokenId] = _newScore;
    }

    /**
     * @notice Returns the metadata URI for a specific Reputation Echo token.
     *         This URI can be dynamic, reflecting the current reputation score.
     *         In a real implementation, this would point to an API endpoint that generates
     *         JSON metadata with dynamic traits based on the score.
     * @param _tokenId The ID of the token.
     * @return The metadata URI.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 score = tokenReputationScore[_tokenId];
        
        // Example: Generate a dynamic URI based on score
        // A real system would use a more sophisticated off-chain metadata service.
        string memory baseURI = "https://echoes.network/api/metadata/"; // Placeholder base URI
        return string(abi.encodePacked(baseURI, _tokenId.toString(), "/", score.toString()));
    }
}
```