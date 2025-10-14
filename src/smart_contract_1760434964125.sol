This smart contract, named **"CognitoNexus"**, envisions a decentralized knowledge and attestation network. It allows users to submit "knowledge claims" (e.g., facts, predictions, interpretations of data). Other users can then "attest" to these claims, either supporting or refuting them, with their attestations weighted by their on-chain reputation and staked tokens. The contract facilitates a reputation-weighted consensus mechanism to determine the validity of claims. It also incorporates dynamic NFTs as "Reputation Badges" for top contributors, a simple DAO for protocol parameter adjustments, and a mechanism for integrating whitelisted oracle data for specific claim types.

---

## CognitoNexus Smart Contract

This contract establishes a decentralized knowledge validation network where users contribute claims and collectively attest to their veracity, with their influence weighted by their on-chain reputation and stake.

### Outline

1.  **State Variables & Constants**: Core parameters, mappings for users, claims, and attestations.
2.  **Enums**: `ClaimStatus`, `AttestationType`, `AttestationStatus`.
3.  **Structs**: `Claim`, `Attestation`, `ReputationProfile`, `ParameterProposal`, `OracleDataFeed`.
4.  **Events**: For tracking key actions like claim submission, attestation, reputation updates, and governance proposals.
5.  **Modifiers**: Access control and state checks.
6.  **ERC-20 & ERC-721 Integration**: Interfaces for a native token (for staking) and a Reputation Badge NFT.
7.  **Core Logic Functions**:
    *   Claim Management
    *   Attestation & Dispute Resolution
    *   Reputation & Staking
    *   Rewards & Withdrawals
    *   Governance (DAO)
    *   Oracle Integration
    *   NFT Minting
    *   View Functions

### Function Summary (20+ Functions)

1.  `constructor()`: Initializes the contract with necessary addresses (token, NFT).
2.  `submitKnowledgeClaim(string memory _claimHash, uint256 _initialStake)`: Submits a new knowledge claim, requiring an initial stake.
3.  `updateKnowledgeClaim(uint256 _claimId, string memory _newClaimHash, uint256 _additionalStake)`: Allows the claim submitter to refine their claim (e.g., add more context) and optionally add more stake before resolution.
4.  `revokeKnowledgeClaim(uint256 _claimId)`: Allows the claim submitter to withdraw their own claim, recovering their stake.
5.  `attestToClaim(uint256 _claimId, AttestationType _type, string memory _justificationHash, uint256 _stake)`: Users attest to a claim, supporting or refuting it, with an associated stake and off-chain justification.
6.  `challengeAttestation(uint256 _claimId, uint256 _attestationIndex, string memory _disputeReasonHash, uint256 _stake)`: Allows users to challenge another attestation, believing it to be inaccurate or malicious.
7.  `finalizeClaimConsensus(uint256 _claimId)`: A callable function (by anyone) that triggers the resolution process for a claim, determining its final `ClaimStatus` based on weighted attestations.
8.  `withdrawClaimStake(uint256 _claimId)`: Allows the original claim submitter to withdraw their initial stake (and any earned rewards) after the claim is finalized.
9.  `withdrawAttestationStake(uint256 _claimId, uint256 _attestationIndex)`: Allows an attestor to withdraw their stake (and any earned rewards/penalties) after their attestation has been resolved.
10. `mintReputationBadgeNFT(uint256 _claimId)`: Mints a unique "Reputation Badge" NFT to the top N most accurate attestors for a successfully resolved claim.
11. `getUserReputation(address _user)`: Returns the current reputation score of a user.
12. `getClaimDetails(uint256 _claimId)`: Returns comprehensive details about a specific knowledge claim.
13. `getAttestationsForClaim(uint256 _claimId)`: Returns an array of attestation IDs for a given claim.
14. `stakeReputationTokens(uint256 _amount)`: Allows users to stake native tokens, boosting their attestation weight and potential rewards.
15. `unstakeReputationTokens(uint256 _amount)`: Allows users to withdraw their staked tokens.
16. `proposeProtocolParameterChange(string memory _paramKey, uint256 _newValue, uint256 _voteDuration)`: Initiates a DAO proposal to change a core protocol parameter (e.g., consensus thresholds, reward rates).
17. `voteOnParameterChange(uint256 _proposalId, bool _support)`: Allows users to vote on an active proposal, with their vote weight determined by reputation and staked tokens.
18. `executeParameterChange(uint256 _proposalId)`: Executes an approved protocol parameter change, making it effective.
19. `registerOracleDataFeed(address _oracleAddress, string memory _description)`: Whitelists an external oracle address, allowing it to provide data for specific claim types.
20. `submitOracleAssurance(uint256 _claimId, bytes32 _oracleReportHash)`: A whitelisted oracle submits an immutable hash of its report/proof for a claim. This data can influence `finalizeClaimConsensus` or `challengeAttestation` outcomes.
21. `delegateAttestationWeight(address _delegatee)`: Delegates a user's attestation weight (reputation + staked tokens) to another address. The delegatee can then use this combined weight for their attestations.
22. `undelegateAttestationWeight()`: Revokes any active delegation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // For name/symbol, though not directly used for minting here

/**
 * @title CognitoNexus
 * @dev A decentralized knowledge and attestation network with reputation-weighted consensus,
 *      dynamic NFTs for recognition, a simple DAO for parameter governance, and oracle integration.
 */
contract CognitoNexus is Ownable, Context {

    // --- Interfaces for integrated contracts ---
    IERC20 public immutable COGNITO_TOKEN; // Native token for staking and rewards
    IERC721Metadata public immutable REPUTATION_BADGE_NFT; // NFT for top attestors

    // --- Enums ---
    enum ClaimStatus {
        Pending,        // Just submitted, awaiting attestations
        AwaitingFinalization, // Sufficient attestations, ready for consensus calculation
        Verified,       // Reached consensus of support
        Refuted,        // Reached consensus of refutation
        Disputed,       // High contention, potentially requiring more input or special resolution
        Revoked         // Withdrawn by submitter
    }

    enum AttestationType {
        Support,
        Refute
    }

    enum AttestationStatus {
        Active,         // Normal attestation
        Challenged,     // Currently under dispute
        Resolved_Accurate, // Found to be accurate
        Resolved_Inaccurate // Found to be inaccurate
    }

    // --- Structs ---
    struct Claim {
        uint256 id;
        address submitter;
        string claimHash;           // IPFS/Arweave hash of the actual claim content
        uint256 initialStake;       // Stake by the submitter
        ClaimStatus status;
        uint256 totalSupportWeight; // Sum of reputation * stake for supporting attestations
        uint256 totalRefuteWeight;  // Sum of reputation * stake for refuting attestations
        uint256 creationTime;
        uint256 resolutionTime;     // When consensus was finalized
        uint256 attestationCount;   // Total number of distinct attestations for this claim
        uint256 oracleAssuranceCount; // Number of oracle reports for this claim
    }

    struct Attestation {
        uint256 id; // Unique ID for attestation (claimId << 128 | index)
        uint256 claimId;
        address attestor;
        AttestationType attestationType;
        string justificationHash;   // IPFS/Arweave hash of the justification content
        uint256 stake;
        uint256 weightedImpact;     // (attestor's reputation + staked_tokens_weight) * stake
        AttestationStatus status;
        uint256 creationTime;
        uint256 challengeCount;     // How many times this attestation was challenged
        uint256 challengeWeight;    // Accumulated weight of challengers
    }

    struct ReputationProfile {
        uint256 score;              // Base reputation score (starts at a default, changes based on accuracy)
        uint256 stakedTokens;       // Amount of COGNITO_TOKEN staked to boost attestation weight
        address delegatee;          // Address to which attestation power is delegated
        address delegator;          // Address that delegated power to this user
        bool isDelegated;           // True if this profile is actively delegating power
    }

    struct ParameterProposal {
        uint256 id;
        string paramKey;            // E.g., "minClaimStake", "consensusThreshold"
        uint256 newValue;
        uint256 proposalTime;
        uint256 voteEndTime;
        uint256 supportWeight;      // Total reputation-weighted support votes
        uint256 refuteWeight;       // Total reputation-weighted refute votes
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        bool executed;
    }

    struct OracleDataFeed {
        address oracleAddress;
        string description;
        bool isWhitelisted;
    }

    // --- State Variables ---
    uint256 public nextClaimId;
    uint256 public nextProposalId;
    uint256 public immutable DEFAULT_REPUTATION_SCORE = 1000;
    uint256 public minClaimStake = 1 ether; // Minimum stake for a claim
    uint256 public minAttestationStake = 0.1 ether; // Minimum stake for an attestation
    uint256 public consensusSupportThreshold = 7000; // 70% for verification (out of 10000)
    uint256 public consensusRefuteThreshold = 7000;  // 70% for refutation
    uint256 public claimFinalizationPeriod = 7 days; // Period after sufficient attestations for finalization
    uint256 public attestationRewardRatio = 10; // 10% of claim stake for accurate attestors
    uint256 public stakeWeightFactor = 2; // How much staked COGNITO_TOKEN boosts effective reputation (e.g., 1 token = 2 reputation points)
    uint256 public proposalVoteDuration = 3 days; // Duration for DAO proposals

    mapping(uint256 => Claim) public claims;
    mapping(uint256 => Attestation[]) public claimAttestations; // claimId => array of attestations
    mapping(address => ReputationProfile) public reputationProfiles;
    mapping(address => uint256) public userStakedTokens; // Separate from reputationProfile.stakedTokens, for general staking
    mapping(address => uint256) public pendingRewards; // Rewards accumulated from accurate attestations
    mapping(uint256 => ParameterProposal) public proposals;
    mapping(address => OracleDataFeed) public oracleFeeds; // oracleAddress => OracleDataFeed

    // Stores hashes of oracle reports for specific claims
    mapping(uint256 => mapping(address => bytes32)) public claimOracleAssurances;

    // --- Events ---
    event ClaimSubmitted(uint256 indexed claimId, address indexed submitter, string claimHash, uint256 initialStake);
    event ClaimUpdated(uint256 indexed claimId, string newClaimHash, uint256 additionalStake);
    event ClaimRevoked(uint256 indexed claimId, address indexed submitter);
    event AttestationMade(uint256 indexed claimId, uint256 attestationId, address indexed attestor, AttestationType _type, uint256 stake, uint256 weightedImpact);
    event AttestationChallenged(uint256 indexed claimId, uint256 indexed attestationIndex, address indexed challenger, uint256 stake);
    event ClaimConsensusFinalized(uint256 indexed claimId, ClaimStatus newStatus, uint256 totalSupportWeight, uint256 totalRefuteWeight, uint256 resolutionTime);
    event StakeWithdrawn(address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 oldScore, uint256 newScore);
    event ReputationBadgeMinted(uint256 indexed claimId, address indexed recipient, uint256 tokenId);
    event ProtocolParameterProposed(uint256 indexed proposalId, string paramKey, uint256 newValue, address indexed proposer);
    event ProtocolParameterVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProtocolParameterExecuted(uint256 indexed proposalId, string paramKey, uint256 newValue);
    event OracleDataFeedRegistered(address indexed oracleAddress, string description);
    event OracleAssuranceSubmitted(uint256 indexed claimId, address indexed oracleAddress, bytes32 reportHash);
    event AttestationWeightDelegated(address indexed delegator, address indexed delegatee);
    event AttestationWeightUndelegated(address indexed delegator);

    // --- Modifiers ---
    modifier onlyClaimSubmitter(uint256 _claimId) {
        require(claims[_claimId].submitter == _msgSender(), "CognitoNexus: Not claim submitter");
        _;
    }

    modifier claimExists(uint256 _claimId) {
        require(claims[_claimId].submitter != address(0), "CognitoNexus: Claim does not exist");
        _;
    }

    modifier attestationExists(uint256 _claimId, uint256 _attestationIndex) {
        require(_attestationIndex < claimAttestations[_claimId].length, "CognitoNexus: Attestation does not exist");
        _;
    }

    modifier onlyWhitelistedOracle(address _oracleAddress) {
        require(oracleFeeds[_oracleAddress].isWhitelisted, "CognitoNexus: Address is not a whitelisted oracle");
        _;
    }

    // --- Constructor ---
    constructor(address _cognitoTokenAddress, address _reputationBadgeNFTAddress) Ownable(_msgSender()) {
        COGNITO_TOKEN = IERC20(_cognitoTokenAddress);
        REPUTATION_BADGE_NFT = IERC721Metadata(_reputationBadgeNFTAddress); // Cast to IERC721Metadata
    }

    // --- Internal Helpers ---
    function _getEffectiveReputation(address _user) internal view returns (uint256) {
        ReputationProfile storage profile = reputationProfiles[_user];
        uint256 baseRep = profile.score == 0 ? DEFAULT_REPUTATION_SCORE : profile.score;
        uint256 stakedTokenBoost = profile.stakedTokens * stakeWeightFactor;
        
        address effectiveUser = _user;
        if (profile.isDelegated) {
            effectiveUser = profile.delegatee; // If _user delegates, their power goes to delegatee
            baseRep = reputationProfiles[effectiveUser].score == 0 ? DEFAULT_REPUTATION_SCORE : reputationProfiles[effectiveUser].score;
            stakedTokenBoost = reputationProfiles[effectiveUser].stakedTokens * stakeWeightFactor;
        } else if (profile.delegator != address(0)) { // This user is a delegatee
             baseRep = reputationProfiles[profile.delegator].score == 0 ? DEFAULT_REPUTATION_SCORE : reputationProfiles[profile.delegator].score;
             stakedTokenBoost = reputationProfiles[profile.delegator].stakedTokens * stakeWeightFactor;
        }

        return baseRep + stakedTokenBoost;
    }

    function _updateReputation(address _user, int256 _change) internal {
        ReputationProfile storage profile = reputationProfiles[_user];
        if (profile.score == 0) profile.score = DEFAULT_REPUTATION_SCORE; // Initialize if first time
        
        uint256 oldScore = profile.score;
        if (_change > 0) {
            profile.score += uint256(_change);
        } else {
            if (profile.score < uint256(-_change)) {
                profile.score = 0; // Prevent underflow, clamp to 0
            } else {
                profile.score -= uint256(-_change);
            }
        }
        emit ReputationUpdated(_user, oldScore, profile.score);
    }

    function _initializeReputationProfile(address _user) internal {
        if (reputationProfiles[_user].score == 0 && reputationProfiles[_user].stakedTokens == 0) {
            reputationProfiles[_user].score = DEFAULT_REPUTATION_SCORE;
        }
    }

    // --- Core Logic Functions ---

    /**
     * @dev Submits a new knowledge claim to the network.
     * @param _claimHash IPFS/Arweave hash pointing to the detailed claim content.
     * @param _initialStake Amount of COGNITO_TOKEN to stake with the claim.
     */
    function submitKnowledgeClaim(string memory _claimHash, uint256 _initialStake) external returns (uint256) {
        require(bytes(_claimHash).length > 0, "CognitoNexus: Claim hash cannot be empty");
        require(_initialStake >= minClaimStake, "CognitoNexus: Initial stake too low");
        require(COGNITO_TOKEN.transferFrom(_msgSender(), address(this), _initialStake), "CognitoNexus: Token transfer failed");

        uint256 claimId = nextClaimId++;
        claims[claimId] = Claim({
            id: claimId,
            submitter: _msgSender(),
            claimHash: _claimHash,
            initialStake: _initialStake,
            status: ClaimStatus.Pending,
            totalSupportWeight: 0,
            totalRefuteWeight: 0,
            creationTime: block.timestamp,
            resolutionTime: 0,
            attestationCount: 0,
            oracleAssuranceCount: 0
        });

        _initializeReputationProfile(_msgSender());
        emit ClaimSubmitted(claimId, _msgSender(), _claimHash, _initialStake);
        return claimId;
    }

    /**
     * @dev Allows the claim submitter to refine their claim or add more stake before it's finalized.
     * @param _claimId The ID of the claim to update.
     * @param _newClaimHash New IPFS/Arweave hash for the updated claim content.
     * @param _additionalStake Optional additional stake to add.
     */
    function updateKnowledgeClaim(uint256 _claimId, string memory _newClaimHash, uint256 _additionalStake)
        external
        onlyClaimSubmitter(_claimId)
        claimExists(_claimId)
    {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Pending, "CognitoNexus: Claim is not in pending status");
        require(bytes(_newClaimHash).length > 0, "CognitoNexus: New claim hash cannot be empty");

        if (_additionalStake > 0) {
            require(COGNITO_TOKEN.transferFrom(_msgSender(), address(this), _additionalStake), "CognitoNexus: Token transfer failed for additional stake");
            claim.initialStake += _additionalStake;
        }
        claim.claimHash = _newClaimHash;
        emit ClaimUpdated(_claimId, _newClaimHash, _additionalStake);
    }

    /**
     * @dev Allows the claim submitter to revoke their own claim if it's still pending.
     *      Recovers their initial stake.
     * @param _claimId The ID of the claim to revoke.
     */
    function revokeKnowledgeClaim(uint256 _claimId)
        external
        onlyClaimSubmitter(_claimId)
        claimExists(_claimId)
    {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Pending, "CognitoNexus: Claim is not in pending status");

        claim.status = ClaimStatus.Revoked;
        require(COGNITO_TOKEN.transfer(claim.submitter, claim.initialStake), "CognitoNexus: Failed to return stake");

        emit ClaimRevoked(_claimId, _msgSender());
    }

    /**
     * @dev Users attest to a claim, supporting or refuting it, with an associated stake and off-chain justification.
     *      Their influence is weighted by their effective reputation.
     * @param _claimId The ID of the claim to attest to.
     * @param _type The type of attestation (Support or Refute).
     * @param _justificationHash IPFS/Arweave hash of the justification for the attestation.
     * @param _stake Amount of COGNITO_TOKEN to stake with this attestation.
     */
    function attestToClaim(uint256 _claimId, AttestationType _type, string memory _justificationHash, uint256 _stake)
        external
        claimExists(_claimId)
    {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.Pending || claim.status == ClaimStatus.AwaitingFinalization, "CognitoNexus: Claim not in active attestation phase");
        require(_msgSender() != claim.submitter, "CognitoNexus: Claim submitter cannot attest to their own claim");
        require(_stake >= minAttestationStake, "CognitoNexus: Attestation stake too low");
        require(COGNITO_TOKEN.transferFrom(_msgSender(), address(this), _stake), "CognitoNexus: Token transfer failed");

        _initializeReputationProfile(_msgSender());
        uint256 effectiveReputation = _getEffectiveReputation(_msgSender());
        uint256 weightedImpact = effectiveReputation * _stake;

        uint256 attestationId = (uint256(_claimId) << 128) | claimAttestations[_claimId].length; // Unique ID per attestation
        claimAttestations[_claimId].push(Attestation({
            id: attestationId,
            claimId: _claimId,
            attestor: _msgSender(),
            attestationType: _type,
            justificationHash: _justificationHash,
            stake: _stake,
            weightedImpact: weightedImpact,
            status: AttestationStatus.Active,
            creationTime: block.timestamp,
            challengeCount: 0,
            challengeWeight: 0
        }));

        if (_type == AttestationType.Support) {
            claim.totalSupportWeight += weightedImpact;
        } else {
            claim.totalRefuteWeight += weightedImpact;
        }
        claim.attestationCount++;

        // If sufficient attestations, transition to AwaitingFinalization
        if (claim.attestationCount >= 5 && claim.status == ClaimStatus.Pending) { // Example threshold
             claim.status = ClaimStatus.AwaitingFinalization;
        }

        emit AttestationMade(_claimId, attestationId, _msgSender(), _type, _stake, weightedImpact);
    }

    /**
     * @dev Allows users to challenge another user's attestation, believing it to be inaccurate or malicious.
     *      A successful challenge can lead to reputation slashing for the challenged attestor.
     * @param _claimId The ID of the claim.
     * @param _attestationIndex The index of the attestation within the claim's attestations array.
     * @param _disputeReasonHash IPFS/Arweave hash of the reason for the dispute.
     * @param _stake Amount of COGNITO_TOKEN to stake for this challenge.
     */
    function challengeAttestation(uint256 _claimId, uint256 _attestationIndex, string memory _disputeReasonHash, uint256 _stake)
        external
        claimExists(_claimId)
        attestationExists(_claimId, _attestationIndex)
    {
        Attestation storage attestation = claimAttestations[_claimId][_attestationIndex];
        Claim storage claim = claims[_claimId];

        require(attestation.attestor != _msgSender(), "CognitoNexus: Cannot challenge your own attestation");
        require(attestation.status == AttestationStatus.Active, "CognitoNexus: Attestation is not active or already challenged");
        require(_stake >= minAttestationStake, "CognitoNexus: Challenge stake too low");
        require(COGNITO_TOKEN.transferFrom(_msgSender(), address(this), _stake), "CognitoNexus: Token transfer failed");

        _initializeReputationProfile(_msgSender());
        uint256 effectiveReputation = _getEffectiveReputation(_msgSender());
        
        attestation.status = AttestationStatus.Challenged;
        attestation.challengeCount++;
        attestation.challengeWeight += effectiveReputation * _stake; // Accumulate challenge weight
        
        // A challenged claim may also transition to disputed status for the overall claim
        if (claim.status != ClaimStatus.Disputed) {
            claim.status = ClaimStatus.Disputed;
        }

        emit AttestationChallenged(_claimId, _attestationIndex, _msgSender(), _stake);
    }

    /**
     * @dev A callable function (by anyone) that triggers the resolution process for a claim.
     *      It determines the final ClaimStatus based on weighted attestations and time.
     *      Distributes rewards and updates reputation accordingly.
     * @param _claimId The ID of the claim to finalize.
     */
    function finalizeClaimConsensus(uint256 _claimId) external claimExists(_claimId) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.AwaitingFinalization || claim.status == ClaimStatus.Disputed, "CognitoNexus: Claim not ready for finalization");
        require(block.timestamp >= claim.creationTime + claimFinalizationPeriod, "CognitoNexus: Finalization period not over");

        uint256 totalWeight = claim.totalSupportWeight + claim.totalRefuteWeight;
        ClaimStatus newStatus;

        if (totalWeight == 0) {
            newStatus = ClaimStatus.Pending; // Not enough participation to decide
        } else if (claim.totalSupportWeight * 10000 / totalWeight >= consensusSupportThreshold) {
            newStatus = ClaimStatus.Verified;
        } else if (claim.totalRefuteWeight * 10000 / totalWeight >= consensusRefuteThreshold) {
            newStatus = ClaimStatus.Refuted;
        } else {
            newStatus = ClaimStatus.Disputed; // Not enough strong consensus for either side
        }
        
        // If there's oracle data for this claim, it might override or heavily influence disputed claims.
        // This part would be more complex, potentially involving a vote on oracle's report
        // For simplicity, let's assume oracle data provides a strong signal for disputed claims.
        if (newStatus == ClaimStatus.Disputed && claim.oracleAssuranceCount > 0) {
            // Placeholder: A real implementation would involve processing oracle data,
            // possibly comparing multiple oracles or using it as a tie-breaker.
            // For now, assume presence of oracle data pushes disputed to Verified or Refuted based on majority attestations.
            if (claim.totalSupportWeight > claim.totalRefuteWeight) {
                newStatus = ClaimStatus.Verified;
            } else if (claim.totalRefuteWeight > claim.totalSupportWeight) {
                newStatus = ClaimStatus.Refuted;
            }
        }


        claim.status = newStatus;
        claim.resolutionTime = block.timestamp;

        // --- Distribute Rewards and Update Reputation ---
        uint256 claimStakePool = claim.initialStake;
        uint256 totalRewardPool = claimStakePool * attestationRewardRatio / 100; // E.g., 10% of initial stake

        uint256 totalAccurateAttestorWeight = 0;
        for (uint256 i = 0; i < claimAttestations[_claimId].length; i++) {
            Attestation storage att = claimAttestations[_claimId][i];
            bool isAccurate;

            if (newStatus == ClaimStatus.Verified && att.attestationType == AttestationType.Support) {
                isAccurate = true;
            } else if (newStatus == ClaimStatus.Refuted && att.attestationType == AttestationType.Refute) {
                isAccurate = true;
            }
            // For Disputed claims, no one gets full rewards/slashes easily.
            // For simplicity, we skip full rewards/slashes for Disputed status.
            // A more complex system might have a separate dispute resolution process.

            if (isAccurate) {
                att.status = AttestationStatus.Resolved_Accurate;
                totalAccurateAttestorWeight += att.weightedImpact;
            } else {
                att.status = AttestationStatus.Resolved_Inaccurate;
                // Slash reputation for inaccurate attestors, proportional to their stake and inaccuracy
                _updateReputation(att.attestor, -int256(att.weightedImpact / 1000)); // Example slash
            }

            // Handle challenges to attestations
            if (att.status == AttestationStatus.Challenged) {
                // If the attestation itself was accurate, then challengers were inaccurate
                if (isAccurate) {
                    // Punish challengers, reward challenged attestor (if accurate)
                    // For simplicity, we just reward the challenged attestor slightly
                     _updateReputation(att.attestor, int256(att.stake / 10)); // Small reward for withstanding challenge
                } else {
                    // If the attestation was inaccurate and challenged, reward challengers
                    // and severely slash attestor
                    _updateReputation(att.attestor, -int256(att.stake / 5)); // Larger slash
                }
            }
        }
        
        // Distribute rewards to accurate attestors
        if (totalAccurateAttestorWeight > 0) {
            for (uint256 i = 0; i < claimAttestations[_claimId].length; i++) {
                Attestation storage att = claimAttestations[_claimId][i];
                if (att.status == AttestationStatus.Resolved_Accurate) {
                    uint256 reward = (totalRewardPool * att.weightedImpact) / totalAccurateAttestorWeight;
                    pendingRewards[att.attestor] += reward;
                     _updateReputation(att.attestor, int256(att.weightedImpact / 500)); // Example reputation boost
                }
            }
        }

        // Return remaining stake to submitter if claim was successful, or keep some for protocol if refuted
        if (newStatus == ClaimStatus.Verified) {
            pendingRewards[claim.submitter] += claimStakePool - totalRewardPool; // Return original stake minus rewards paid out
        } else if (newStatus == ClaimStatus.Refuted) {
            // Submitters of refuted claims lose a portion of their stake
            pendingRewards[claim.submitter] += claimStakePool / 2; // Example: lose 50%
            // The remaining portion can go to protocol treasury or other mechanisms
        } else { // Disputed or Pending (if no consensus reached, stake is returned after a long period)
            pendingRewards[claim.submitter] += claimStakePool;
        }

        emit ClaimConsensusFinalized(_claimId, newStatus, claim.totalSupportWeight, claim.totalRefuteWeight, block.timestamp);
    }

    /**
     * @dev Allows the original claim submitter to withdraw their initial stake (and any earned rewards)
     *      after the claim is finalized.
     * @param _claimId The ID of the claim.
     */
    function withdrawClaimStake(uint256 _claimId) external claimExists(_claimId) {
        Claim storage claim = claims[_claimId];
        require(claim.submitter == _msgSender(), "CognitoNexus: Not the claim submitter");
        require(claim.status != ClaimStatus.Pending && claim.status != ClaimStatus.AwaitingFinalization, "CognitoNexus: Claim not finalized yet");

        uint256 amountToTransfer = pendingRewards[_msgSender()];
        require(amountToTransfer > 0, "CognitoNexus: No pending rewards/stake to withdraw");
        
        pendingRewards[_msgSender()] = 0;
        require(COGNITO_TOKEN.transfer(_msgSender(), amountToTransfer), "CognitoNexus: Failed to transfer funds");
        emit StakeWithdrawn(_msgSender(), amountToTransfer);
    }

    /**
     * @dev Allows an attestor to withdraw their stake (and any earned rewards/penalties)
     *      after their attestation has been resolved.
     * @param _claimId The ID of the claim.
     * @param _attestationIndex The index of the attestation.
     */
    function withdrawAttestationStake(uint256 _claimId, uint256 _attestationIndex)
        external
        claimExists(_claimId)
        attestationExists(_claimId, _attestationIndex)
    {
        Attestation storage att = claimAttestations[_claimId][_attestationIndex];
        require(att.attestor == _msgSender(), "CognitoNexus: Not the attestor");
        require(att.status == AttestationStatus.Resolved_Accurate || att.status == AttestationStatus.Resolved_Inaccurate, "CognitoNexus: Attestation not resolved yet");
        
        uint256 amountToTransfer = pendingRewards[_msgSender()];
        require(amountToTransfer > 0, "CognitoNexus: No pending rewards/stake to withdraw");

        pendingRewards[_msgSender()] = 0;
        require(COGNITO_TOKEN.transfer(_msgSender(), amountToTransfer), "CognitoNexus: Failed to transfer funds");
        emit StakeWithdrawn(_msgSender(), amountToTransfer);
    }

    /**
     * @dev Mints a unique "Reputation Badge" NFT to the top N most accurate attestors for a successfully resolved claim.
     *      Only callable by the contract itself or owner for now, usually triggered as part of finalization.
     * @param _claimId The ID of the claim for which badges are minted.
     */
    function mintReputationBadgeNFT(uint256 _claimId) external {
        // This function is intended to be called internally after finalizeClaimConsensus,
        // or by a privileged account (e.g., contract owner) to reward.
        // For a full system, this might be a governance decision or automated.
        require(claims[_claimId].status == ClaimStatus.Verified || claims[_claimId].status == ClaimStatus.Refuted, "CognitoNexus: Claim not successfully resolved");
        
        // In a real scenario, we'd determine top attestors based on their weighted impact
        // and accuracy and then mint NFTs to them.
        // For simplicity, let's assume it mints to a specific accurate attestor.

        // Placeholder for actual NFT minting logic
        // This would require the REPUTATION_BADGE_NFT contract to have a mint function
        // that allows this contract to call it. Example:
        // REPUTATION_BADGE_NFT.safeMint(_recipient, _tokenId);

        // For demonstration, let's find the single highest impact attestor and assume they get a badge.
        uint256 maxWeightedImpact = 0;
        address topAttestor = address(0);

        for (uint256 i = 0; i < claimAttestations[_claimId].length; i++) {
            Attestation storage att = claimAttestations[_claimId][i];
            if ((claims[_claimId].status == ClaimStatus.Verified && att.attestationType == AttestationType.Support) ||
                (claims[_claimId].status == ClaimStatus.Refuted && att.attestationType == AttestationType.Refute)) {
                if (att.weightedImpact > maxWeightedImpact) {
                    maxWeightedImpact = att.weightedImpact;
                    topAttestor = att.attestor;
                }
            }
        }

        if (topAttestor != address(0)) {
            // This requires the NFT contract to have a `mint(address to, uint256 tokenId)` function
            // or `safeMint(address to, uint256 tokenId)`
            // Assuming REPUTATION_BADGE_NFT.mint(topAttestor, _claimId) for simplicity.
            // In a real contract, the NFT contract address passed to constructor would be a custom ERC721 that
            // allows this contract to mint.
            // REPUTATION_BADGE_NFT.mint(topAttestor, _claimId); // ERC721 doesn't have a direct 'mint' usually
            // Instead, this contract would call a custom mint function on the NFT contract:
            // ICustomReputationBadgeNFT(address(REPUTATION_BADGE_NFT)).mintBadge(topAttestor, _claimId);
            // This is a placeholder for actual cross-contract interaction.
            emit ReputationBadgeMinted(_claimId, topAttestor, _claimId); // Using claimId as a pseudo tokenId
        }
    }

    /**
     * @dev Returns the current reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return reputationProfiles[_user].score == 0 ? DEFAULT_REPUTATION_SCORE : reputationProfiles[_user].score;
    }

    /**
     * @dev Returns comprehensive details about a specific knowledge claim.
     * @param _claimId The ID of the claim.
     * @return Claim struct details.
     */
    function getClaimDetails(uint256 _claimId) external view claimExists(_claimId) returns (Claim memory) {
        return claims[_claimId];
    }

    /**
     * @dev Returns an array of Attestation structs for a given claim.
     * @param _claimId The ID of the claim.
     * @return An array of Attestation structs.
     */
    function getAttestationsForClaim(uint256 _claimId) external view claimExists(_claimId) returns (Attestation[] memory) {
        return claimAttestations[_claimId];
    }

    /**
     * @dev Allows users to stake native tokens, boosting their attestation weight and potential rewards.
     * @param _amount Amount of COGNITO_TOKEN to stake.
     */
    function stakeReputationTokens(uint256 _amount) external {
        require(_amount > 0, "CognitoNexus: Stake amount must be greater than zero");
        require(COGNITO_TOKEN.transferFrom(_msgSender(), address(this), _amount), "CognitoNexus: Token transfer failed");

        _initializeReputationProfile(_msgSender());
        reputationProfiles[_msgSender()].stakedTokens += _amount;
        emit ReputationUpdated(_msgSender(), reputationProfiles[_msgSender()].score, reputationProfiles[_msgSender()].score); // Emit to signify stake change
    }

    /**
     * @dev Allows users to withdraw their staked tokens.
     * @param _amount Amount of COGNITO_TOKEN to unstake.
     */
    function unstakeReputationTokens(uint256 _amount) external {
        require(_amount > 0, "CognitoNexus: Unstake amount must be greater than zero");
        require(reputationProfiles[_msgSender()].stakedTokens >= _amount, "CognitoNexus: Insufficient staked tokens");

        reputationProfiles[_msgSender()].stakedTokens -= _amount;
        require(COGNITO_TOKEN.transfer(_msgSender(), _amount), "CognitoNexus: Token transfer failed");
        emit StakeWithdrawn(_msgSender(), _amount);
    }

    /**
     * @dev Initiates a DAO proposal to change a core protocol parameter.
     *      Requires a minimum reputation score or stake to propose.
     * @param _paramKey The key identifying the parameter (e.g., "minClaimStake").
     * @param _newValue The new value for the parameter.
     * @param _voteDuration The duration in seconds for which the proposal will be open for voting.
     */
    function proposeProtocolParameterChange(string memory _paramKey, uint256 _newValue, uint256 _voteDuration) external {
        // Implement minimum reputation/stake to propose
        require(_getEffectiveReputation(_msgSender()) >= DEFAULT_REPUTATION_SCORE * 2, "CognitoNexus: Insufficient reputation to propose");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = ParameterProposal({
            id: proposalId,
            paramKey: _paramKey,
            newValue: _newValue,
            proposalTime: block.timestamp,
            voteEndTime: block.timestamp + _voteDuration,
            supportWeight: 0,
            refuteWeight: 0,
            hasVoted: mapping(address => bool), // Initialize mapping
            executed: false
        });

        emit ProtocolParameterProposed(proposalId, _paramKey, _newValue, _msgSender());
    }

    /**
     * @dev Allows users to vote on an active proposal, with their vote weight determined
     *      by their effective reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for supporting, false for refuting the proposal.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) external {
        ParameterProposal storage proposal = proposals[_proposalId];
        require(proposal.proposalTime != 0, "CognitoNexus: Proposal does not exist");
        require(block.timestamp < proposal.voteEndTime, "CognitoNexus: Voting period has ended");
        require(!proposal.hasVoted[_msgSender()], "CognitoNexus: Already voted on this proposal");

        uint256 voteWeight = _getEffectiveReputation(_msgSender());
        
        if (_support) {
            proposal.supportWeight += voteWeight;
        } else {
            proposal.refuteWeight += voteWeight;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit ProtocolParameterVoted(_proposalId, _msgSender(), _support, voteWeight);
    }

    /**
     * @dev Executes an approved protocol parameter change, making it effective.
     *      Callable by anyone after the voting period ends and consensus is reached.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 _proposalId) external {
        ParameterProposal storage proposal = proposals[_proposalId];
        require(proposal.proposalTime != 0, "CognitoNexus: Proposal does not exist");
        require(block.timestamp >= proposal.voteEndTime, "CognitoNexus: Voting period not ended");
        require(!proposal.executed, "CognitoNexus: Proposal already executed");

        uint256 totalVoteWeight = proposal.supportWeight + proposal.refuteWeight;
        require(totalVoteWeight > 0, "CognitoNexus: No votes cast for this proposal");
        
        // Simple majority consensus (e.g., 60% support)
        uint256 requiredSupportThreshold = 6000; // 60% out of 10000
        if ((proposal.supportWeight * 10000 / totalVoteWeight) >= requiredSupportThreshold) {
            proposal.executed = true;
            // Apply the parameter change based on _paramKey
            if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("minClaimStake"))) {
                minClaimStake = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("minAttestationStake"))) {
                minAttestationStake = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("consensusSupportThreshold"))) {
                consensusSupportThreshold = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("consensusRefuteThreshold"))) {
                consensusRefuteThreshold = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("claimFinalizationPeriod"))) {
                claimFinalizationPeriod = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("attestationRewardRatio"))) {
                attestationRewardRatio = proposal.newValue;
            } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("stakeWeightFactor"))) {
                stakeWeightFactor = proposal.newValue;
            } else {
                revert("CognitoNexus: Unknown parameter key");
            }
            emit ProtocolParameterExecuted(_proposalId, proposal.paramKey, proposal.newValue);
        } else {
            revert("CognitoNexus: Proposal did not reach consensus");
        }
    }

    /**
     * @dev Whitelists an external oracle address, allowing it to provide data for specific claim types.
     *      Only callable by the contract owner (or DAO).
     * @param _oracleAddress The address of the oracle.
     * @param _description A description of the oracle's function.
     */
    function registerOracleDataFeed(address _oracleAddress, string memory _description) external onlyOwner {
        require(_oracleAddress != address(0), "CognitoNexus: Invalid oracle address");
        require(!oracleFeeds[_oracleAddress].isWhitelisted, "CognitoNexus: Oracle already whitelisted");

        oracleFeeds[_oracleAddress] = OracleDataFeed({
            oracleAddress: _oracleAddress,
            description: _description,
            isWhitelisted: true
        });
        emit OracleDataFeedRegistered(_oracleAddress, _description);
    }

    /**
     * @dev A whitelisted oracle submits an immutable hash of its report/proof for a claim.
     *      This data can influence finalizeClaimConsensus or challengeAttestation outcomes.
     * @param _claimId The ID of the claim the report is for.
     * @param _oracleReportHash The hash of the oracle's report (e.g., IPFS hash or data hash).
     */
    function submitOracleAssurance(uint256 _claimId, bytes32 _oracleReportHash)
        external
        claimExists(_claimId)
        onlyWhitelistedOracle(_msgSender())
    {
        require(claimOracleAssurances[_claimId][_msgSender()] == bytes32(0), "CognitoNexus: Oracle already submitted assurance for this claim");
        
        claimOracleAssurances[_claimId][_msgSender()] = _oracleReportHash;
        claims[_claimId].oracleAssuranceCount++;
        
        // This could potentially trigger a state change or an expedited finalization
        // depending on the protocol rules and the nature of the oracle.
        emit OracleAssuranceSubmitted(_claimId, _msgSender(), _oracleReportHash);
    }

    /**
     * @dev Delegates a user's attestation weight (reputation + staked tokens) to another address.
     *      The delegatee can then use this combined weight for their attestations.
     * @param _delegatee The address to delegate power to.
     */
    function delegateAttestationWeight(address _delegatee) external {
        require(_delegatee != address(0), "CognitoNexus: Invalid delegatee address");
        require(_delegatee != _msgSender(), "CognitoNexus: Cannot delegate to self");
        require(!reputationProfiles[_msgSender()].isDelegated, "CognitoNexus: Already delegated attestation power");
        require(reputationProfiles[_delegatee].delegator == address(0), "CognitoNexus: Delegatee is already a delegatee for someone else");

        ReputationProfile storage delegatorProfile = reputationProfiles[_msgSender()];
        ReputationProfile storage delegateeProfile = reputationProfiles[_delegatee];

        // Ensure profiles are initialized
        _initializeReputationProfile(_msgSender());
        _initializeReputationProfile(_delegatee);

        delegatorProfile.isDelegated = true;
        delegatorProfile.delegatee = _delegatee;
        delegateeProfile.delegator = _msgSender();

        emit AttestationWeightDelegated(_msgSender(), _delegatee);
    }

    /**
     * @dev Revokes any active delegation by the calling user.
     */
    function undelegateAttestationWeight() external {
        ReputationProfile storage delegatorProfile = reputationProfiles[_msgSender()];
        require(delegatorProfile.isDelegated, "CognitoNexus: No active delegation to revoke");

        address delegatee = delegatorProfile.delegatee;
        reputationProfiles[delegatee].delegator = address(0); // Clear delegator field on delegatee

        delegatorProfile.isDelegated = false;
        delegatorProfile.delegatee = address(0);

        emit AttestationWeightUndelegated(_msgSender());
    }

    // --- View Functions (Additional) ---

    /**
     * @dev Returns the total pending rewards for a specific user.
     * @param _user The address of the user.
     * @return The amount of pending rewards.
     */
    function getPendingRewards(address _user) external view returns (uint256) {
        return pendingRewards[_user];
    }

    /**
     * @dev Returns the details of a specific protocol parameter proposal.
     * @param _proposalId The ID of the proposal.
     * @return ParameterProposal struct details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (ParameterProposal memory) {
        require(proposals[_proposalId].proposalTime != 0, "CognitoNexus: Proposal does not exist");
        return proposals[_proposalId];
    }

    /**
     * @dev Returns the current status of the oracle feed for a given address.
     * @param _oracleAddress The address of the potential oracle.
     * @return OracleDataFeed struct details.
     */
    function getOracleFeedStatus(address _oracleAddress) external view returns (OracleDataFeed memory) {
        return oracleFeeds[_oracleAddress];
    }

    /**
     * @dev Returns the oracle assurance hash for a specific claim by a given oracle.
     * @param _claimId The ID of the claim.
     * @param _oracleAddress The address of the oracle.
     * @return The bytes32 hash of the oracle's report.
     */
    function getClaimOracleAssurance(uint256 _claimId, address _oracleAddress) external view returns (bytes32) {
        return claimOracleAssurances[_claimId][_oracleAddress];
    }
}
```