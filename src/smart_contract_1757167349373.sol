This smart contract, `AdaptiveSovereignRegistry`, introduces several advanced, creative, and trendy concepts, aiming to build a unique decentralized identity and reputation system. It focuses on non-transferable identifiers, dynamic reputation influenced by verifiable claims, adaptive on-chain governance, and integrates a conceptual framework for cross-chain and AI-informed interactions.

---

**Contract Name:** `AdaptiveSovereignRegistry`

**Outline:**

1.  **Core Identifiers (SIDs):** Creation, management, and staking of non-transferable Sovereign Identifiers.
2.  **Attestation Layer:** System for verifiable claims about SIDs, including custom schemas.
3.  **Dynamic Reputation Engine:** Algorithmically derived reputation scores influencing privileges, with decay mechanisms.
4.  **Adaptive Governance:** On-chain proposal and voting system with weighted power based on SID reputation and stake, capable of updating protocol parameters.
5.  **Delegated Authority:** SIDs can grant temporary, scoped permissions to others.
6.  **Cross-Chain Integration Layer:** Mechanism for SIDs to assert and verify achievements on other chains.
7.  **AI-Enhanced Parameters/Oracles:** Integration points for AI oracles to provide insights affecting reputation or system parameters.
8.  **Internal State & Parameter Management:** Functions to retrieve system configurations and manage internal counters.

**Function Summary (22 Functions):**

**I. Core SID Management (6 functions)**

1.  `mintSovereignID(string memory _metadataURI)`: Creates a new unique, non-transferable Sovereign Identifier (SID) for the caller, requiring an initial dynamic fee.
2.  `getSIDProfile(uint256 _sidId)`: Retrieves the comprehensive profile of a given SID, including owner, status, and latest reputation.
3.  `updateSIDMetadata(uint256 _sidId, string memory _newMetadataURI)`: Allows an SID owner to update the associated metadata URI.
4.  `deactivateSID(uint256 _sidId)`: Allows an SID owner to temporarily deactivate their SID, pausing certain operations like reputation decay.
5.  `reactivateSID(uint256 _sidId)`: Allows an SID owner to reactivate their previously deactivated SID.
6.  `stakeSID(uint256 _sidId, uint256 _amount)`: Permits an SID owner to stake collateral, potentially boosting their reputation or unlocking advanced features.
7.  `unstakeSID(uint256 _sidId, uint256 _amount)`: Allows an SID owner to withdraw a portion of their staked collateral.

**II. Attestation System (5 functions)**

8.  `attest(uint256 _subjectSID, bytes32 _claimHash, uint256 _schemaId, uint256 _weight, uint256 _expiration)`: An SID makes a verifiable, time-bound claim (attestation) about another SID. The attestation's influence (`_weight`) can be dynamically adjusted based on the attester's reputation.
9.  `revokeAttestation(uint256 _subjectSID, uint256 _attestationId)`: Allows the original attester to revoke a previously made attestation.
10. `getAttestationsBySID(uint256 _sidId)`: Returns an array of all active attestation IDs made *about* a specific SID.
11. `getAttestationDetails(uint256 _subjectSID, uint256 _attestationId)`: Provides full details for a specific attestation about an SID.
12. `defineAttestationSchema(bytes32 _schemaHash, string memory _schemaURI, bool _isVerifiableOffChain)`: Allows governance to define new attestation schemas, enabling structured claims.

**III. Dynamic Reputation Engine (3 functions)**

13. `calculateReputation(uint256 _sidId)`: Triggers an on-demand recalculation of an SID's reputation score, considering all valid attestations, stake, AI insights, and decay, returning the new score. This can be permissioned to be called by anyone but only processes if a cool-down period passed.
14. `getReputationScore(uint256 _sidId)`: Retrieves the last calculated and stored reputation score for a given SID.
15. `_decayReputation(uint256 _sidId)` (internal): An internal helper function to apply time-based decay to an SID's reputation, called during `calculateReputation`.

**IV. Adaptive Governance (4 functions)**

16. `proposeProtocolChange(string memory _description, bytes memory _executionPayload)`: An SID with sufficient reputation and stake can propose changes to protocol parameters or even contract upgrades (via a proxy pattern, implied by `_executionPayload`).
17. `voteOnProposal(uint256 _proposalId, bool _for)`: SIDs cast their vote on an active proposal; voting power is dynamically weighted by reputation and staked amount.
18. `executeProposal(uint256 _proposalId)`: Finalizes a passed proposal, triggering the execution of its payload.
19. `getProposalDetails(uint256 _proposalId)`: Provides comprehensive details about a specific governance proposal.

**V. Advanced Concepts & Interoperability (5 functions)**

20. `delegateAuthority(uint256 _delegatorSID, address _delegatee, uint256 _permissionsBitmap, uint256 _expirationTimestamp, bytes32 _scopeHash)`: An SID can delegate specific, scoped permissions to an EOA or another contract for a defined period, enabling intent-based interactions or sub-agency.
21. `checkDelegatedPermission(uint256 _delegatorSID, address _delegatee, uint256 _permissionBit)`: Checks if an address has a specific delegated permission from an SID.
22. `verifyCrossChainAttestation(uint256 _subjectSID, bytes32 _proofHash, uint256 _chainID, bytes memory _verificationData, uint256 _schemaId, uint256 _weight)`: Allows an SID to submit cryptographic proof of an event or state from another blockchain. This function takes the proof data which is conceptually verified off-chain by an oracle or light client (external to this contract), and if deemed valid, automatically registers a weighted attestation on the `AdaptiveSovereignRegistry`.
23. `registerAIOracle(address _oracleAddress, string memory _description)`: Allows governance to register a trusted AI oracle address capable of submitting insights.
24. `submitAIInsight(uint256 _subjectSID, bytes32 _insightHash, int256 _reputationAdjustment, uint256 _validUntil)`: Registered AI oracles can submit insights about SIDs, which can directly influence their reputation score (positive or negative) for a limited duration.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For staking

// --- Custom Errors ---
error AdaptiveSovereignRegistry__SIDNotFound(uint256 sidId);
error AdaptiveSovereignRegistry__NotSIDOwner(uint256 sidId, address caller);
error AdaptiveSovereignRegistry__SIDAlreadyActive(uint256 sidId);
error AdaptiveSovereignRegistry__SIDAlreadyInactive(uint256 sidId);
error AdaptiveSovereignRegistry__InsufficientStake(uint256 sidId, uint256 required, uint256 current);
error AdaptiveSovereignRegistry__AttestationExpired(uint256 attestationId);
error AdaptiveSovereignRegistry__AttestationNotFound(uint256 sidId, uint256 attestationId);
error AdaptiveSovereignRegistry__NotAttester(uint256 attestationId, uint256 attesterSID);
error AdaptiveSovereignRegistry__ProposalNotFound(uint256 proposalId);
error AdaptiveSovereignRegistry__ProposalNotActive(uint256 proposalId);
error AdaptiveSovereignRegistry__ProposalAlreadyVoted(uint256 proposalId, uint256 voterSID);
error AdaptiveSovereignRegistry__ProposalThresholdNotMet(uint256 proposalId);
error AdaptiveSovereignRegistry__ProposalAlreadyExecuted(uint256 proposalId);
error AdaptiveSovereignRegistry__InvalidPermissionsBitmap();
error AdaptiveSovereignRegistry__DelegationNotFound();
error AdaptiveSovereignRegistry__DelegationExpired();
error AdaptiveSovereignRegistry__NotAIOracle(address caller);
error AdaptiveSovereignRegistry__AIInsightExpired();
error AdaptiveSovereignRegistry__InsufficientReputation(uint256 sidId, uint256 required, uint256 current);
error AdaptiveSovereignRegistry__UnauthorizedCall();
error AdaptiveSovereignRegistry__AttestationSchemaNotFound(uint256 schemaId);
error AdaptiveSovereignRegistry__CooldownNotPassed(uint256 sidId, uint256 timeRemaining);


// --- Outline ---
// 1. Core Identifiers (SIDs): Creation, management, and staking of non-transferable Sovereign Identifiers.
// 2. Attestation Layer: System for verifiable claims about SIDs, including custom schemas.
// 3. Dynamic Reputation Engine: Algorithmically derived reputation scores influencing privileges, with decay mechanisms.
// 4. Adaptive Governance: On-chain proposal and voting system with weighted power based on SID reputation and stake, capable of updating protocol parameters.
// 5. Delegated Authority: SIDs can grant temporary, scoped permissions to others.
// 6. Cross-Chain Integration Layer: Mechanism for SIDs to assert and verify achievements on other chains.
// 7. AI-Enhanced Parameters/Oracles: Integration points for AI oracles to provide insights affecting reputation or system parameters.
// 8. Internal State & Parameter Management: Functions to retrieve system configurations and manage internal counters.

// --- Function Summary ---

// I. Core SID Management (6 functions)
// 1. mintSovereignID(string memory _metadataURI): Creates a new unique, non-transferable Sovereign Identifier (SID) for the caller, requiring an initial dynamic fee.
// 2. getSIDProfile(uint256 _sidId): Retrieves the comprehensive profile of a given SID, including owner, status, and latest reputation.
// 3. updateSIDMetadata(uint256 _sidId, string memory _newMetadataURI): Allows an SID owner to update the associated metadata URI.
// 4. deactivateSID(uint256 _sidId): Allows an SID owner to temporarily deactivate their SID, pausing certain operations like reputation decay.
// 5. reactivateSID(uint256 _sidId): Allows an SID owner to reactivate their previously deactivated SID.
// 6. stakeSID(uint256 _sidId, uint256 _amount): Permits an SID owner to stake collateral, potentially boosting their reputation or unlocking advanced features.
// 7. unstakeSID(uint256 _sidId, uint256 _amount): Allows an SID owner to withdraw a portion of their staked collateral.

// II. Attestation System (5 functions)
// 8. attest(uint256 _subjectSID, bytes32 _claimHash, uint256 _schemaId, uint256 _weight, uint256 _expiration): An SID makes a verifiable, time-bound claim (attestation) about another SID. The attestation's influence (`_weight`) can be dynamically adjusted based on the attester's reputation.
// 9. revokeAttestation(uint256 _subjectSID, uint256 _attestationId): Allows the original attester to revoke a previously made attestation.
// 10. getAttestationsBySID(uint256 _sidId): Returns an array of all active attestation IDs made *about* a specific SID.
// 11. getAttestationDetails(uint256 _subjectSID, uint256 _attestationId): Provides full details for a specific attestation about an SID.
// 12. defineAttestationSchema(bytes32 _schemaHash, string memory _schemaURI, bool _isVerifiableOffChain): Allows governance to define new attestation schemas, enabling structured claims.

// III. Dynamic Reputation Engine (3 functions)
// 13. calculateReputation(uint256 _sidId): Triggers an on-demand recalculation of an SID's reputation score, considering all valid attestations, stake, AI insights, and decay, returning the new score. This can be permissioned to be called by anyone but only processes if a cool down period passed.
// 14. getReputationScore(uint256 _sidId): Retrieves the last calculated and stored reputation score for a given SID.
// 15. _decayReputation(uint256 _sidId) (internal): An internal helper function to apply time-based decay to an SID's reputation, called during `calculateReputation`.

// IV. Adaptive Governance (4 functions)
// 16. proposeProtocolChange(string memory _description, bytes memory _executionPayload): An SID with sufficient reputation and stake can propose changes to protocol parameters or even contract upgrades (via a proxy pattern, implied by `_executionPayload`).
// 17. voteOnProposal(uint256 _proposalId, bool _for): SIDs cast their vote on an active proposal; voting power is dynamically weighted by reputation and staked amount.
// 18. executeProposal(uint256 _proposalId): Finalizes a passed proposal, triggering the execution of its payload.
// 19. getProposalDetails(uint256 _proposalId): Provides comprehensive details about a specific governance proposal.

// V. Advanced Concepts & Interoperability (5 functions)
// 20. delegateAuthority(uint256 _delegatorSID, address _delegatee, uint256 _permissionsBitmap, uint256 _expirationTimestamp, bytes32 _scopeHash): An SID can delegate specific, scoped permissions to an EOA or another contract for a defined period, enabling intent-based interactions or sub-agency.
// 21. checkDelegatedPermission(uint256 _delegatorSID, address _delegatee, uint256 _permissionBit): Checks if an address has a specific delegated permission from an SID.
// 22. verifyCrossChainAttestation(uint256 _subjectSID, bytes32 _proofHash, uint256 _chainID, bytes memory _verificationData, uint256 _schemaId, uint256 _weight): Allows an SID to submit cryptographic proof of an event or state from another blockchain. This function takes the proof data which is conceptually verified off-chain by an oracle or light client (external to this contract), and if deemed valid, automatically registers a weighted attestation on the `AdaptiveSovereignRegistry`.
// 23. registerAIOracle(address _oracleAddress, string memory _description): Allows governance to register a trusted AI oracle address capable of submitting insights.
// 24. submitAIInsight(uint256 _subjectSID, bytes32 _insightHash, int256 _reputationAdjustment, uint256 _validUntil): Registered AI oracles can submit insights about SIDs, which can directly influence their reputation score (positive or negative) for a limited duration.

contract AdaptiveSovereignRegistry is Ownable, ReentrancyGuard {

    // --- Events ---
    event SIDMinted(uint256 indexed sidId, address indexed owner, string metadataURI, uint256 mintTimestamp);
    event SIDMetadataUpdated(uint256 indexed sidId, string newMetadataURI);
    event SIDDeactivated(uint256 indexed sidId);
    event SIDReactivated(uint256 indexed sidId);
    event SIDStaked(uint256 indexed sidId, uint256 amount, uint256 totalStaked);
    event SIDUnstaked(uint256 indexed sidId, uint256 amount, uint256 totalStaked);
    event AttestationMade(uint256 indexed attestationId, uint256 indexed subjectSID, uint256 indexed attesterSID, bytes32 claimHash, uint256 weight);
    event AttestationRevoked(uint256 indexed attestationId, uint256 indexed subjectSID, uint256 indexed attesterSID);
    event ReputationCalculated(uint256 indexed sidId, uint256 newScore);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed proposerSID, string description);
    event Voted(uint256 indexed proposalId, uint256 indexed voterSID, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event AuthorityDelegated(uint256 indexed delegatorSID, address indexed delegatee, uint256 permissionsBitmap, uint256 expirationTimestamp);
    event CrossChainAttestationVerified(uint256 indexed subjectSID, uint256 indexed attestationId, uint256 chainID, bytes32 proofHash);
    event AIOracleRegistered(address indexed oracleAddress, string description);
    event AIInsightSubmitted(uint256 indexed subjectSID, address indexed oracleAddress, bytes32 insightHash, int256 reputationAdjustment);
    event AttestationSchemaDefined(uint256 indexed schemaId, bytes32 schemaHash, string schemaURI, bool isVerifiableOffChain);
    event DynamicParamsUpdated(DynamicParams newParams);

    // --- Structs ---

    struct SIDProfile {
        address owner;
        uint256 mintTimestamp;
        uint256 latestReputationScore;
        uint256 lastReputationRecalculation; // Timestamp of the last reputation recalculation
        bool isActive;
        string metadataURI;
        uint256 stakedAmount; // Amount of the staking token
        uint256 attestationCount; // Total attestations made *about* this SID
    }

    struct Attestation {
        uint256 attesterSID;
        uint256 subjectSID;
        bytes32 claimHash; // Hash of the claim content
        uint256 schemaId; // ID of the schema defining the claim
        uint256 timestamp;
        uint256 weight; // Influence of this attestation on reputation
        uint256 expiration; // When the attestation becomes invalid
        bool revoked; // Flag if the attestation has been revoked
    }

    struct AttestationSchema {
        bytes32 schemaHash; // A unique hash for the schema
        string schemaURI; // URI pointing to the full schema definition
        bool isVerifiableOffChain; // True if this schema's claims are expected to be verified off-chain
        bool exists; // To check if schemaId is valid
    }

    struct Proposal {
        uint256 proposerSID;
        string description;
        bytes executionPayload; // Data for potential contract call (e.g., set new params, upgrade proxy)
        uint256 voteThresholdPercentage; // Percentage of total cast votes required to pass
        uint256 quorumPercentage; // Percentage of total voting power that must participate
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(uint256 => bool) hasVoted; // SID ID => Voted?
    }

    struct DynamicParams {
        uint256 baseMintFee; // Base fee to mint a new SID
        uint256 reputationDecayRate; // Percentage decay per time unit (e.g., per month) (e.g., 1000 = 10%)
        uint256 attestationWeightMultiplier; // Multiplier for attestation's base weight (e.g., 100 = 1x)
        uint256 minStakeForAttestation; // Minimum stake required for an SID to make attestations
        uint256 minReputationForProposal; // Minimum reputation required to propose changes
        uint256 reputationRecalculationCooldown; // Min time between forced reputation recalculations
        uint256 initialReputationScore; // Starting reputation for new SIDs
        uint256 governanceVoteQuorumPercentage; // Quorum for governance proposals (e.g., 2000 = 20% of total voting power)
        uint256 governanceVoteThresholdPercentage; // Threshold for governance proposals (e.g., 5000 = 50% of cast votes)
        uint256 votingPowerStakeMultiplier; // Multiplier for staked amount in voting power (e.g., 10 per ether)
        uint256 votingPowerReputationDivisor; // Divisor for reputation in voting power (e.g., 100 for 1 point per 100 rep)
    }

    struct Delegation {
        uint256 delegatorSID;
        address delegateeAddress;
        uint256 permissionsBitmap; // Bitmask for delegated permissions (e.g., 1=attest, 2=vote, 4=update_metadata)
        uint256 expirationTimestamp;
        bytes32 scopeHash; // Hash representing the specific scope/context of the delegation
        bool active;
    }

    struct AIReputationAdjustment {
        int256 adjustmentValue;
        uint256 validUntil;
        address oracleAddress;
        bytes32 insightHash;
        bool active;
    }

    // --- State Variables ---
    uint256 public nextSIDId = 1; // SID IDs start from 1
    uint256 public nextAttestationSchemaId = 1;
    uint256 public nextProposalId = 1;

    IERC20 public stakingToken; // The token used for staking and fees

    mapping(uint256 => SIDProfile) public sids;
    mapping(address => uint256) public addressToSID; // For quick lookup of SID by owner address

    // subjectSID => attestationId => Attestation
    mapping(uint256 => mapping(uint256 => Attestation)) public attestations;
    // subjectSID => array of attestation IDs made *about* it
    mapping(uint256 => uint256[]) private _attestationsBySubject;

    mapping(uint256 => AttestationSchema) public attestationSchemas;

    mapping(uint256 => Proposal) public proposals;

    // delegatorSID => delegateeAddress => Delegation
    mapping(uint256 => mapping(address => Delegation)) public authorityDelegations;

    address[] public aiOracles;
    mapping(address => bool) public isAIOracle;

    // sidId => adjustmentId => AIReputationAdjustment
    mapping(uint252 => mapping(uint256 => AIReputationAdjustment)) public aiInsights;
    // sidId => array of insight IDs
    mapping(uint256 => uint256[]) private _aiInsightsBySID;
    mapping(uint256 => uint256) private _nextInsightIdForSID;


    DynamicParams public dynamicParams;

    // --- Modifiers ---

    modifier onlySIDOwner(uint256 _sidId) {
        if (sids[_sidId].owner == address(0)) { revert AdaptiveSovereignRegistry__SIDNotFound(_sidId); }
        if (sids[_sidId].owner != msg.sender) { revert AdaptiveSovereignRegistry__NotSIDOwner(_sidId, msg.sender); }
        _;
    }

    modifier onlyActiveSID(uint256 _sidId) {
        if (sids[_sidId].owner == address(0)) { revert AdaptiveSovereignRegistry__SIDNotFound(_sidId); }
        if (!sids[_sidId].isActive) { revert AdaptiveSovereignRegistry__SIDAlreadyInactive(_sidId); }
        _;
    }

    modifier onlyReputableSID(uint256 _sidId) {
        if (sids[_sidId].owner == address(0)) { revert AdaptiveSovereignRegistry__SIDNotFound(_sidId); }
        if (sids[_sidId].latestReputationScore < dynamicParams.minReputationForProposal) {
            revert AdaptiveSovereignRegistry__InsufficientReputation(_sidId, dynamicParams.minReputationForProposal, sids[_sidId].latestReputationScore);
        }
        _;
    }

    modifier onlyAIOracle() {
        if (!isAIOracle[msg.sender]) { revert AdaptiveSovereignRegistry__NotAIOracle(msg.sender); }
        _;
    }

    // --- Constructor ---

    constructor(address _stakingTokenAddress) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingTokenAddress);

        // Initialize default dynamic parameters
        dynamicParams = DynamicParams({
            baseMintFee: 1 ether, // Example: 1 token
            reputationDecayRate: 1000, // 10% per recalculation interval (1000 = 10% of 10000)
            attestationWeightMultiplier: 100, // Multiplier for base attestation weight (100 means 1x)
            minStakeForAttestation: 0, // No minimum stake required initially
            minReputationForProposal: 1000, // Min reputation score to propose
            reputationRecalculationCooldown: 1 days, // Allow recalculation every day
            initialReputationScore: 100, // Starting reputation for new SIDs
            governanceVoteQuorumPercentage: 2000, // 20%
            governanceVoteThresholdPercentage: 5000, // 50%
            votingPowerStakeMultiplier: 10, // 10 points per 1 ether staked
            votingPowerReputationDivisor: 100 // 1 point per 100 reputation
        });
    }

    // --- Internal/Private Helpers ---

    function _getSID(address _addr) internal view returns (uint256) {
        return addressToSID[_addr];
    }

    function _calculateReputationInternal(uint256 _sidId) internal returns (uint256) {
        SIDProfile storage sid = sids[_sidId];
        if (sid.owner == address(0) || !sid.isActive) { return 0; } // Inactive SIDs don't accrue reputation

        uint256 currentScore = sid.latestReputationScore;

        // Apply decay if enough time has passed since last calculation
        if (block.timestamp > sid.lastReputationRecalculation && sid.lastReputationRecalculation != 0) {
            uint256 decayAmount = (currentScore * dynamicParams.reputationDecayRate) / 10000; // Assuming 10000 = 100% for percentage
            currentScore = currentScore >= decayAmount ? currentScore - decayAmount : 0;
        }

        // Apply attestation influence
        uint256[] memory attestationIds = _attestationsBySubject[_sidId];
        for (uint256 i = 0; i < attestationIds.length; i++) {
            Attestation storage att = attestations[_sidId][attestationIds[i]];
            if (!att.revoked && att.expiration > block.timestamp) {
                // Heuristic: Simple sum with multiplier.
                currentScore += (att.weight * dynamicParams.attestationWeightMultiplier) / 100; // Divide by 100 as _weight is probably out of 100
            }
        }

        // Apply AI insights influence
        uint256[] memory insightIds = _aiInsightsBySID[_sidId];
        for (uint256 i = 0; i < insightIds.length; i++) {
            AIReputationAdjustment storage insight = aiInsights[_sidId][insightIds[i]];
            if (insight.active && insight.validUntil > block.timestamp) {
                if (insight.adjustmentValue > 0) {
                    currentScore += uint256(insight.adjustmentValue);
                } else {
                    uint256 absAdjustment = uint256(insight.adjustmentValue * -1);
                    currentScore = currentScore >= absAdjustment ? currentScore - absAdjustment : 0;
                }
            } else {
                // Deactivate expired insights to avoid processing them again and reduce gas
                insight.active = false;
            }
        }

        // Apply stake bonus
        currentScore += (sid.stakedAmount / 1 ether) * dynamicParams.votingPowerStakeMultiplier;

        sid.latestReputationScore = currentScore;
        sid.lastReputationRecalculation = block.timestamp;

        emit ReputationCalculated(_sidId, currentScore);
        return currentScore;
    }

    function _getVotingPower(uint256 _sidId) internal view returns (uint256) {
        SIDProfile storage sid = sids[_sidId];
        if (!sid.isActive) return 0;
        // Voting power based on reputation and stake, with configurable multipliers
        uint256 reputationPower = sid.latestReputationScore / dynamicParams.votingPowerReputationDivisor;
        uint256 stakePower = (sid.stakedAmount / 1 ether) * dynamicParams.votingPowerStakeMultiplier;
        return reputationPower + stakePower;
    }

    // Internal function to update parameters, callable only by a successful proposal execution.
    function _updateDynamicParams(DynamicParams calldata _newParams) internal {
        dynamicParams = _newParams;
        emit DynamicParamsUpdated(_newParams);
    }

    // --- I. Core SID Management ---

    /// @notice Creates a new unique, non-transferable Sovereign Identifier (SID) for the caller.
    /// @param _metadataURI A URI pointing to off-chain metadata describing the SID.
    /// @return sidId The ID of the newly minted SID.
    function mintSovereignID(string memory _metadataURI) external nonReentrant returns (uint256 sidId) {
        if (addressToSID[msg.sender] != 0) { // Already owns an SID
            revert AdaptiveSovereignRegistry__UnauthorizedCall();
        }

        uint256 mintFee = dynamicParams.baseMintFee;
        if (mintFee > 0) {
            require(stakingToken.transferFrom(msg.sender, address(this), mintFee), "Fee transfer failed");
        }

        sidId = nextSIDId++;
        sids[sidId] = SIDProfile({
            owner: msg.sender,
            mintTimestamp: block.timestamp,
            latestReputationScore: dynamicParams.initialReputationScore,
            lastReputationRecalculation: block.timestamp,
            isActive: true,
            metadataURI: _metadataURI,
            stakedAmount: 0,
            attestationCount: 0
        });
        addressToSID[msg.sender] = sidId;

        emit SIDMinted(sidId, msg.sender, _metadataURI, block.timestamp);
        return sidId;
    }

    /// @notice Retrieves the comprehensive profile of a given SID.
    /// @param _sidId The ID of the SID to retrieve.
    /// @return profile The SIDProfile struct containing all details.
    function getSIDProfile(uint256 _sidId) external view returns (SIDProfile memory profile) {
        profile = sids[_sidId];
        if (profile.owner == address(0)) { revert AdaptiveSovereignRegistry__SIDNotFound(_sidId); }
        return profile;
    }

    /// @notice Allows an SID owner to update the associated metadata URI.
    /// @param _sidId The ID of the SID to update.
    /// @param _newMetadataURI The new URI pointing to off-chain metadata.
    function updateSIDMetadata(uint256 _sidId, string memory _newMetadataURI) external onlySIDOwner(_sidId) {
        sids[_sidId].metadataURI = _newMetadataURI;
        emit SIDMetadataUpdated(_sidId, _newMetadataURI);
    }

    /// @notice Allows an SID owner to temporarily deactivate their SID.
    /// @param _sidId The ID of the SID to deactivate.
    function deactivateSID(uint256 _sidId) external onlySIDOwner(_sidId) {
        if (!sids[_sidId].isActive) { revert AdaptiveSovereignRegistry__SIDAlreadyInactive(_sidId); }
        sids[_sidId].isActive = false;
        emit SIDDeactivated(_sidId);
    }

    /// @notice Allows an SID owner to reactivate their previously deactivated SID.
    /// @param _sidId The ID of the SID to reactivate.
    function reactivateSID(uint256 _sidId) external onlySIDOwner(_sidId) {
        if (sids[_sidId].isActive) { revert AdaptiveSovereignRegistry__SIDAlreadyActive(_sidId); }
        sids[_sidId].isActive = true;
        emit SIDReactivated(_sidId);
    }

    /// @notice Permits an SID owner to stake collateral to boost their reputation or unlock advanced features.
    /// @param _sidId The ID of the SID to stake for.
    /// @param _amount The amount of staking tokens to stake.
    function stakeSID(uint256 _sidId, uint256 _amount) external onlySIDOwner(_sidId) nonReentrant {
        if (_amount == 0) return;
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Staking token transfer failed");
        sids[_sidId].stakedAmount += _amount;
        emit SIDStaked(_sidId, _amount, sids[_sidId].stakedAmount);
    }

    /// @notice Allows an SID owner to withdraw a portion of their staked collateral.
    /// @param _sidId The ID of the SID to unstake from.
    /// @param _amount The amount of staking tokens to unstake.
    function unstakeSID(uint256 _sidId, uint256 _amount) external onlySIDOwner(_sidId) nonReentrant {
        SIDProfile storage sid = sids[_sidId];
        require(sid.stakedAmount >= _amount, "Insufficient staked amount");
        sid.stakedAmount -= _amount;
        require(stakingToken.transfer(msg.sender, _amount), "Unstaking token transfer failed");
        emit SIDUnstaked(_sidId, _amount, sid.stakedAmount);
    }

    // --- II. Attestation System ---

    /// @notice An SID makes a verifiable, time-bound claim (attestation) about another SID.
    ///         The attestation's influence (`_weight`) can be dynamically adjusted based on the attester's reputation.
    /// @param _subjectSID The ID of the SID being attested about.
    /// @param _claimHash A hash representing the content of the claim.
    /// @param _schemaId The ID of the attestation schema being used.
    /// @param _weight The base weight of this attestation before multipliers.
    /// @param _expiration Unix timestamp when the attestation expires.
    function attest(
        uint256 _subjectSID,
        bytes32 _claimHash,
        uint256 _schemaId,
        uint256 _weight,
        uint256 _expiration
    ) external onlyActiveSID(addressToSID[msg.sender]) nonReentrant {
        uint256 attesterSID = addressToSID[msg.sender];
        if (attesterSID == 0) { revert AdaptiveSovereignRegistry__UnauthorizedCall(); }
        if (sids[attesterSID].stakedAmount < dynamicParams.minStakeForAttestation) {
            revert AdaptiveSovereignRegistry__InsufficientStake(
                attesterSID, dynamicParams.minStakeForAttestation, sids[attesterSID].stakedAmount
            );
        }
        if (attestationSchemas[_schemaId].exists == false) { revert AdaptiveSovereignRegistry__AttestationSchemaNotFound(_schemaId); }

        uint256 currentSIDAttestationCount = sids[_subjectSID].attestationCount;
        sids[_subjectSID].attestationCount++;

        attestations[_subjectSID][currentSIDAttestationCount] = Attestation({
            attesterSID: attesterSID,
            subjectSID: _subjectSID,
            claimHash: _claimHash,
            schemaId: _schemaId,
            timestamp: block.timestamp,
            weight: _weight,
            expiration: _expiration,
            revoked: false
        });

        _attestationsBySubject[_subjectSID].push(currentSIDAttestationCount);

        emit AttestationMade(currentSIDAttestationCount, _subjectSID, attesterSID, _claimHash, _weight);
    }

    /// @notice Allows the original attester to revoke a previously made attestation.
    /// @param _subjectSID The ID of the SID the attestation was about.
    /// @param _attestationId The ID of the attestation to revoke.
    function revokeAttestation(uint256 _subjectSID, uint256 _attestationId) external onlyActiveSID(addressToSID[msg.sender]) {
        uint256 attesterSID = addressToSID[msg.sender];
        Attestation storage att = attestations[_subjectSID][_attestationId];

        if (att.attesterSID == 0 || att.subjectSID != _subjectSID) { revert AdaptiveSovereignRegistry__AttestationNotFound(_subjectSID, _attestationId); }
        if (att.attesterSID != attesterSID) { revert AdaptiveSovereignRegistry__NotAttester(_attestationId, attesterSID); }
        if (att.revoked) { revert AdaptiveSovereignRegistry__AttestationNotFound(_subjectSID, _attestationId); } // Already revoked or invalid ID

        att.revoked = true;
        emit AttestationRevoked(_attestationId, _subjectSID, attesterSID);
    }

    /// @notice Returns an array of all active attestation IDs made *about* a specific SID.
    /// @param _sidId The ID of the SID.
    /// @return An array of attestation IDs.
    function getAttestationsBySID(uint256 _sidId) external view returns (uint256[] memory) {
        if (sids[_sidId].owner == address(0)) { revert AdaptiveSovereignRegistry__SIDNotFound(_sidId); }
        return _attestationsBySubject[_sidId];
    }

    /// @notice Provides full details for a specific attestation about an SID.
    /// @param _subjectSID The ID of the SID the attestation is about.
    /// @param _attestationId The ID of the attestation.
    /// @return The Attestation struct.
    function getAttestationDetails(uint256 _subjectSID, uint256 _attestationId) external view returns (Attestation memory) {
        Attestation memory att = attestations[_subjectSID][_attestationId];
        if (att.attesterSID == 0 || att.subjectSID != _subjectSID) { revert AdaptiveSovereignRegistry__AttestationNotFound(_subjectSID, _attestationId); }
        return att;
    }

    /// @notice Allows governance to define new attestation schemas, enabling structured claims.
    /// @param _schemaHash A unique hash identifying the schema.
    /// @param _schemaURI A URI pointing to the full schema definition (e.g., JSON schema).
    /// @param _isVerifiableOffChain True if claims using this schema require off-chain verification proofs.
    function defineAttestationSchema(bytes32 _schemaHash, string memory _schemaURI, bool _isVerifiableOffChain) external onlyOwner {
        uint256 schemaId = nextAttestationSchemaId++;
        attestationSchemas[schemaId] = AttestationSchema({
            schemaHash: _schemaHash,
            schemaURI: _schemaURI,
            isVerifiableOffChain: _isVerifiableOffChain,
            exists: true
        });
        emit AttestationSchemaDefined(schemaId, _schemaHash, _schemaURI, _isVerifiableOffChain);
    }


    // --- III. Dynamic Reputation Engine ---

    /// @notice Triggers an on-demand recalculation of an SID's reputation score.
    ///         Consider all valid attestations, stake, AI insights, and decay.
    ///         Can be called by anyone, but only processes if a cool down period passed.
    /// @param _sidId The ID of the SID for which to calculate reputation.
    /// @return The newly calculated reputation score.
    function calculateReputation(uint256 _sidId) external returns (uint256) {
        SIDProfile storage sid = sids[_sidId];
        if (sid.owner == address(0)) { revert AdaptiveSovereignRegistry__SIDNotFound(_sidId); }
        
        // Prevent frequent recalculations to save gas, unless it's a new SID or explicitly forced by owner (not implemented)
        if (block.timestamp < sid.lastReputationRecalculation + dynamicParams.reputationRecalculationCooldown && sid.lastReputationRecalculation != 0) {
            revert AdaptiveSovereignRegistry__CooldownNotPassed(_sidId, (sid.lastReputationRecalculation + dynamicParams.reputationRecalculationCooldown) - block.timestamp);
        }

        return _calculateReputationInternal(_sidId);
    }

    /// @notice Retrieves the last calculated and stored reputation score for a given SID.
    /// @param _sidId The ID of the SID.
    /// @return The current reputation score.
    function getReputationScore(uint256 _sidId) external view returns (uint256) {
        if (sids[_sidId].owner == address(0)) { revert AdaptiveSovereignRegistry__SIDNotFound(_sidId); }
        return sids[_sidId].latestReputationScore;
    }

    /// @notice A placeholder internal helper function to apply time-based decay to an SID's reputation.
    ///         This is called within `_calculateReputationInternal`
    function _decayReputation(uint256 _sidId) internal pure {
        // Implementation is now part of _calculateReputationInternal
        _sidId; // suppress unused warning
    }

    // --- IV. Adaptive Governance ---

    /// @notice An SID with sufficient reputation and stake can propose changes to protocol parameters.
    /// @param _description A detailed description of the proposed change.
    /// @param _executionPayload The encoded call data for the function to execute if the proposal passes.
    ///                          For parameter changes, this would encode a call to `_updateDynamicParams`.
    function proposeProtocolChange(string memory _description, bytes memory _executionPayload) external onlyActiveSID(addressToSID[msg.sender]) onlyReputableSID(addressToSID[msg.sender]) returns (uint256 proposalId) {
        uint256 proposerSID = addressToSID[msg.sender];
        proposalId = nextProposalId++;

        proposals[proposalId] = Proposal({
            proposerSID: proposerSID,
            description: _description,
            executionPayload: _executionPayload,
            voteThresholdPercentage: dynamicParams.governanceVoteThresholdPercentage,
            quorumPercentage: dynamicParams.governanceVoteQuorumPercentage,
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp + 7 days, // Example: 7-day voting period
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            hasVoted: new mapping(uint256 => bool)
        });

        emit ProposalCreated(proposalId, proposerSID, _description);
        return proposalId;
    }

    /// @notice SIDs cast their vote on an active proposal; voting power is dynamically weighted by reputation and staked amount.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _for True to vote for the proposal, false to vote against.
    function voteOnProposal(uint256 _proposalId, bool _for) external onlyActiveSID(addressToSID[msg.sender]) nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        uint256 voterSID = addressToSID[msg.sender];

        if (proposal.proposerSID == 0) { revert AdaptiveSovereignRegistry__ProposalNotFound(_proposalId); }
        if (block.timestamp < proposal.startTimestamp || block.timestamp > proposal.endTimestamp) {
            revert AdaptiveSovereignRegistry__ProposalNotActive(_proposalId);
        }
        if (proposal.hasVoted[voterSID]) { revert AdaptiveSovereignRegistry__ProposalAlreadyVoted(_proposalId, voterSID); }

        uint256 votingPower = _getVotingPower(voterSID);
        require(votingPower > 0, "Voter has no voting power");

        if (_for) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }
        proposal.hasVoted[voterSID] = true;

        emit Voted(_proposalId, voterSID, _for);
    }

    /// @notice Finalizes a passed proposal, triggering the execution of its payload.
    ///         Callable by anyone after the voting period ends and checks pass.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposerSID == 0) { revert AdaptiveSovereignRegistry__ProposalNotFound(_proposalId); }
        if (block.timestamp <= proposal.endTimestamp) { revert AdaptiveSovereignRegistry__ProposalNotActive(_proposalId); } // Voting period must be over
        if (proposal.executed) { revert AdaptiveSovereignRegistry__ProposalAlreadyExecuted(_proposalId); }

        // Calculate total potential voting power to check quorum
        uint256 totalVotingPower = 0;
        for (uint256 i = 1; i < nextSIDId; i++) { // Iterate all SIDs to sum up their potential voting power
            totalVotingPower += _getVotingPower(i);
        }
        
        uint256 votesCast = proposal.forVotes + proposal.againstVotes;
        if (totalVotingPower == 0 || votesCast * 10000 < totalVotingPower * proposal.quorumPercentage) { // 10000 for percentage math
            revert AdaptiveSovereignRegistry__ProposalThresholdNotMet(_proposalId); // Quorum not met
        }

        // Check if the proposal received enough 'for' votes
        if (proposal.forVotes * 10000 < votesCast * proposal.voteThresholdPercentage) { // 10000 for percentage math
             revert AdaptiveSovereignRegistry__ProposalThresholdNotMet(_proposalId); // Threshold not met
        }

        proposal.executed = true;

        // Execute the payload. This uses a `call` which preserves context for internal functions
        // or can call external contracts. The payload should be crafted accordingly.
        // E.g., for updating dynamic parameters:
        // abi.encodeWithSelector(this._updateDynamicParams.selector, _newParams);
        (bool success, ) = address(this).call(proposal.executionPayload);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Provides comprehensive details about a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The Proposal struct.
    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        Proposal memory proposal = proposals[_proposalId];
        if (proposal.proposerSID == 0) { revert AdaptiveSovereignRegistry__ProposalNotFound(_proposalId); }
        return proposal;
    }

    // --- V. Advanced Concepts & Interoperability ---

    /// @notice An SID can delegate specific, scoped permissions to an EOA or another contract for a defined period.
    /// @param _delegatorSID The ID of the SID granting permissions.
    /// @param _delegatee The address to which permissions are delegated.
    /// @param _permissionsBitmap A bitmask representing the delegated permissions (e.g., 1=attest, 2=vote, 4=update_metadata).
    /// @param _expirationTimestamp Unix timestamp when the delegation expires.
    /// @param _scopeHash A hash representing the specific scope/context of the delegation.
    function delegateAuthority(
        uint256 _delegatorSID,
        address _delegatee,
        uint256 _permissionsBitmap,
        uint256 _expirationTimestamp,
        bytes32 _scopeHash
    ) external onlySIDOwner(_delegatorSID) {
        require(_permissionsBitmap > 0, "No permissions specified");
        require(_expirationTimestamp > block.timestamp, "Expiration must be in the future");

        authorityDelegations[_delegatorSID][_delegatee] = Delegation({
            delegatorSID: _delegatorSID,
            delegateeAddress: _delegatee,
            permissionsBitmap: _permissionsBitmap,
            expirationTimestamp: _expirationTimestamp,
            scopeHash: _scopeHash,
            active: true
        });

        emit AuthorityDelegated(_delegatorSID, _delegatee, _permissionsBitmap, _expirationTimestamp);
    }

    /// @notice Checks if an address has a specific delegated permission from an SID.
    /// @param _delegatorSID The ID of the SID that delegated.
    /// @param _delegatee The address claiming delegation.
    /// @param _permissionBit The specific permission bit to check (e.g., 1 for attest).
    /// @return True if the delegation is active and includes the permission, false otherwise.
    function checkDelegatedPermission(uint256 _delegatorSID, address _delegatee, uint256 _permissionBit) external view returns (bool) {
        Delegation memory delegation = authorityDelegations[_delegatorSID][_delegatee];
        if (!delegation.active || delegation.delegatorSID == 0) { return false; }
        if (delegation.expirationTimestamp <= block.timestamp) { return false; }
        return (delegation.permissionsBitmap & _permissionBit) == _permissionBit;
    }

    /// @notice Allows an SID to submit cryptographic proof of an event or state from another blockchain.
    ///         This function takes the proof data which is conceptually verified off-chain by an oracle or light client (external to this contract),
    ///         and if deemed valid, automatically registers a weighted attestation on the `AdaptiveSovereignRegistry`.
    ///         The contract does not *verify* the proof directly, but assumes it's verified externally and passed validly.
    /// @param _subjectSID The SID to which this cross-chain attestation applies.
    /// @param _proofHash A hash of the cryptographic proof.
    /// @param _chainID The ID of the originating blockchain.
    /// @param _verificationData Raw data needed for off-chain verification (e.g., block hash, transaction hash, merkle root).
    /// @param _schemaId The schema ID for this type of cross-chain claim.
    /// @param _weight The weight of this attestation.
    function verifyCrossChainAttestation(
        uint256 _subjectSID,
        bytes32 _proofHash,
        uint256 _chainID,
        bytes memory _verificationData, // This data is for *external* verification.
        uint256 _schemaId,
        uint256 _weight
    ) external nonReentrant {
        // This function would typically be called by a trusted oracle/relayer or a governance-approved gateway contract
        // after *they* have successfully verified the proof on the other chain.
        // For simplicity, we make it `external` and rely on *implicit* trust or future governance-controlled callers.
        // A more robust system would require `onlyCrossChainGateway` modifier.
        
        // This function defines the *interface* for submitting verified cross-chain claims.
        // The actual verification of `_proofHash` using `_verificationData` happens *off-chain*.
        // The responsibility of calling this function with valid data lies with the caller.
        
        // Ensure the schema exists and is marked as verifiable off-chain.
        AttestationSchema storage schema = attestationSchemas[_schemaId];
        if (!schema.exists || !schema.isVerifiableOffChain) { revert AdaptiveSovereignRegistry__AttestationSchemaNotFound(_schemaId); }
        
        // The attesterSID for this attestation would implicitly be 'the system' or a designated oracle.
        // For simplicity, we'll make it msg.sender, implying `msg.sender` is a trusted relayer/oracle.
        
        uint256 attesterSID = addressToSID[msg.sender]; // Could be a trusted relayer's SID
        if (attesterSID == 0) {
            // Or only allow pre-registered relayers/oracles to call this
            revert AdaptiveSovereignRegistry__UnauthorizedCall();
        }

        uint256 currentSIDAttestationCount = sids[_subjectSID].attestationCount;
        sids[_subjectSID].attestationCount++;

        attestations[_subjectSID][currentSIDAttestationCount] = Attestation({
            attesterSID: attesterSID, // The relayer's SID or a special system SID
            subjectSID: _subjectSID,
            claimHash: keccak256(abi.encodePacked(_proofHash, _chainID, _verificationData)), // Hash incorporating proof data
            schemaId: _schemaId,
            timestamp: block.timestamp,
            weight: _weight,
            expiration: block.timestamp + 365 days, // Example: Cross-chain proofs could have long validity
            revoked: false
        });

        _attestationsBySubject[_subjectSID].push(currentSIDAttestationCount);

        emit CrossChainAttestationVerified(_subjectSID, currentSIDAttestationCount, _chainID, _proofHash);
    }

    /// @notice Allows governance to register a trusted AI oracle address capable of submitting insights.
    /// @param _oracleAddress The address of the AI oracle.
    /// @param _description A description of the AI oracle.
    function registerAIOracle(address _oracleAddress, string memory _description) external onlyOwner {
        require(!isAIOracle[_oracleAddress], "AI Oracle already registered");
        aiOracles.push(_oracleAddress);
        isAIOracle[_oracleAddress] = true;
        emit AIOracleRegistered(_oracleAddress, _description);
    }
    
    /// @notice Allows governance to remove a trusted AI oracle address.
    /// @param _oracleAddress The address of the AI oracle to remove.
    function removeAIOracle(address _oracleAddress) external onlyOwner {
        require(isAIOracle[_oracleAddress], "AI Oracle not registered");
        isAIOracle[_oracleAddress] = false;
        // Efficiently remove from array (order doesn't matter)
        for (uint256 i = 0; i < aiOracles.length; i++) {
            if (aiOracles[i] == _oracleAddress) {
                aiOracles[i] = aiOracles[aiOracles.length - 1];
                aiOracles.pop();
                break;
            }
        }
    }

    /// @notice Registered AI oracles can submit insights about SIDs, which can directly influence their reputation score (positive or negative) for a limited duration.
    /// @param _subjectSID The SID affected by the AI insight.
    /// @param _insightHash A hash representing the AI insight's content.
    /// @param _reputationAdjustment The integer value by which reputation should be adjusted (can be negative).
    /// @param _validUntil Unix timestamp until which this insight's adjustment is valid.
    function submitAIInsight(
        uint256 _subjectSID,
        bytes32 _insightHash,
        int256 _reputationAdjustment,
        uint256 _validUntil
    ) external onlyAIOracle nonReentrant {
        if (_validUntil <= block.timestamp) { revert AdaptiveSovereignRegistry__AIInsightExpired(); }
        if (sids[_subjectSID].owner == address(0)) { revert AdaptiveSovereignRegistry__SIDNotFound(_subjectSID); }

        uint256 insightId = _nextInsightIdForSID[_subjectSID]++;

        aiInsights[_subjectSID][insightId] = AIReputationAdjustment({
            adjustmentValue: _reputationAdjustment,
            validUntil: _validUntil,
            oracleAddress: msg.sender,
            insightHash: _insightHash,
            active: true
        });
        _aiInsightsBySID[_subjectSID].push(insightId);

        // Immediately trigger a reputation recalculation for this SID to reflect the insight
        _calculateReputationInternal(_subjectSID);

        emit AIInsightSubmitted(_subjectSID, msg.sender, _insightHash, _reputationAdjustment);
    }
}
```