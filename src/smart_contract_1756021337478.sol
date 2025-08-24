This smart contract, "AuraForge: Adaptive Ecosystem Identity Protocol," introduces a novel approach to on-chain identity and reputation. It combines **Soulbound Tokens (SBTs)** for core identity, **Dynamic NFTs** that evolve with user reputation, a **time-decaying reputation system**, and **delegatable influence**, all governed by a **community-driven validation and parameter adjustment mechanism**.

The contract aims to create a robust, verifiable, and adaptive identity for users within a decentralized ecosystem, reflecting their continuous engagement and contributions, rather than static token holdings.

---

## **AuraForge: Adaptive Ecosystem Identity Protocol**

### **Outline and Function Summary**

**I. Core Identity & NFT Management (AuraSeed & AuraNFT)**
*   **AuraSeed (SBT):** A non-transferable token representing a user's core identity.
*   **AuraNFT (Dynamic NFT):** An ERC721 token whose metadata (visuals, traits) dynamically updates based on the user's accumulated AuraPoints.

    1.  `mintAuraSeed()`: Allows an address to mint their unique, non-transferable AuraSeed (SBT) and its corresponding AuraNFT.
    2.  `getAuraSeedIdByOwner(address _owner)`: Retrieves the AuraSeed ID associated with a given owner address.
    3.  `getOwnerByAuraSeedId(uint256 _auraSeedId)`: Retrieves the owner address associated with a given AuraSeed ID.
    4.  `tokenURI(uint256 _auraNFTId)`: Returns the dynamic metadata URI for a given AuraNFT, reflecting current AuraPoints.
    5.  `withdrawAuraSeed(uint256 _auraSeedId)`: Allows an AuraSeed holder to voluntarily "burn" their AuraSeed and AuraNFT, exiting the ecosystem (irreversible).

**II. AuraPoint (Reputation) Management**
*   **AuraPoints:** A non-transferable, quantifiable reputation score that decays over time.
*   **Time-Decay Mechanism:** Ensures reputation reflects recent and continuous engagement.

    6.  `getAuraPoints(uint256 _auraSeedId)`: Retrieves the current AuraPoints for a specific AuraSeed holder.
    7.  `earnAuraPoints(uint256 _auraSeedId, uint256 _amount, bytes32 _contributionHash)`: Allows approved entities (e.g., Validators) to grant AuraPoints for a verified contribution.
    8.  `decayAuraPoints(uint256 _auraSeedId)`: Manually triggers the decay of AuraPoints for a specific AuraSeed. (Typically called by a Keeper or a periodic external service).
    9.  `proposePointAdjustment(uint256 _auraSeedId, int256 _adjustment, string memory _reasonURI)`: Allows anyone to propose an AuraPoint adjustment for an AuraSeed holder, subject to governance approval.

**III. Validator & Contribution System**
*   **Validators:** Approved entities responsible for verifying contributions and awarding AuraPoints.
*   **Contribution Lifecycle:** From proposal to validation/revocation.

    10. `registerValidator(string memory _name, string memory _profileURI)`: Proposes an address to become a validator, subject to governance approval.
    11. `proposeContribution(uint256 _auraSeedId, bytes32 _contributionHash, string memory _descriptionURI)`: An AuraSeed holder proposes a contribution (e.g., community work) for validation and potential AuraPoints.
    12. `validateContribution(uint256 _proposalId, uint256 _pointsAwarded)`: A registered validator approves a proposed contribution, awarding specified AuraPoints.
    13. `revokeValidation(uint256 _proposalId, string memory _reasonURI)`: A validator can revoke a previously approved validation (e.g., if contribution was fraudulent), reducing AuraPoints.
    14. `getValidatorInfo(address _validator)`: Retrieves detailed information about a registered validator.

**IV. Delegated Reputation System**
*   **Temporary Influence Delegation:** Allows users to temporarily delegate a portion of their AuraPoints (influence) to another address for a specified duration.

    15. `delegateAuraPoints(uint256 _auraSeedId, address _delegatee, uint256 _amount, uint256 _duration)`: Allows an AuraSeed holder to delegate a portion of their AuraPoints to another address for a limited time.
    16. `revokeDelegation(uint256 _delegationId)`: Allows the delegator to prematurely revoke an active delegation.
    17. `getDelegatedPoints(uint256 _auraSeedId)`: Returns the total effective AuraPoints currently delegated *by* an AuraSeed holder.
    18. `getReceivedDelegatedPoints(uint256 _auraSeedId)`: Returns the total effective AuraPoints currently delegated *to* an AuraSeed holder.

**V. Governance & System Parameters**
*   **DAO-lite Governance:** Allows the community (via AuraPoints) to propose and vote on changes to core system parameters.

    19. `proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, string memory _descriptionURI)`: Creates a new governance proposal to change a system parameter.
    20. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows AuraSeed holders to vote on active governance proposals.
    21. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has passed and met the quorum.
    22. `setMetadataBaseURI(string memory _newURI)`: Allows governance to update the base URI for AuraNFT metadata.
    23. `setAuraPointValue(bytes32 _actionType, uint256 _points)`: Allows governance to configure predefined AuraPoint values for specific, recognized actions or integrations.
    24. `setDecayParameters(uint256 _decayInterval, uint256 _decayRateNumerator, uint256 _decayRateDenominator)`: Allows governance to adjust how AuraPoints decay over time.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AuraForge: Adaptive Ecosystem Identity Protocol
 * @dev This contract implements a novel on-chain identity and reputation system.
 *      It combines Soulbound Tokens (SBTs) for core identity, Dynamic NFTs (AuraNFTs)
 *      whose metadata evolves with reputation, a time-decaying reputation system (AuraPoints),
 *      and delegatable influence. Contributions are validated by registered validators,
 *      and core system parameters are governed by community proposals.
 *      The aim is to foster a dynamic, verifiable, and adaptive identity for users
 *      reflecting continuous engagement and contributions.
 */
contract AuraForge is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Identity (AuraSeed - SBT)
    mapping(address => uint256) private s_auraSeedIdByOwner; // owner address -> AuraSeed token ID
    mapping(uint256 => address) private s_ownerByAuraSeedId; // AuraSeed token ID -> owner address
    Counters.Counter private s_nextAuraSeedId; // Next available AuraSeed ID

    // Reputation (AuraPoints)
    struct AuraData {
        uint256 points;
        uint256 lastDecayTimestamp;
    }
    mapping(uint256 => AuraData) private s_auraPoints; // AuraSeed ID -> AuraData

    // Dynamic NFT (AuraNFT)
    string private s_baseTokenURI; // Base URI for AuraNFT metadata

    // Validators
    struct Validator {
        string name;
        string profileURI;
        bool registered; // True if validator is active and approved
    }
    mapping(address => Validator) private s_validators; // validator address -> Validator info
    mapping(address => bool) private s_isValidatorApproved; // validator address -> approved status (after governance)

    // Contribution Proposals (for points)
    struct ContributionProposal {
        uint256 auraSeedId;
        address proposer;
        bytes32 contributionHash; // Unique hash of the contribution details
        string descriptionURI; // URI pointing to detailed contribution description
        uint256 pointsAwarded; // Points awarded by validator
        address validator; // Address of the validator who approved it
        bool validated; // True if validated
        bool revoked; // True if validation was revoked
    }
    Counters.Counter private s_nextContributionProposalId;
    mapping(uint256 => ContributionProposal) private s_contributionProposals;

    // Delegated Reputation
    struct Delegation {
        uint256 delegatorAuraSeedId;
        address delegatee;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }
    Counters.Counter private s_nextDelegationId;
    mapping(uint256 => Delegation) private s_delegations;

    // Governance
    struct GovernanceProposal {
        bytes32 parameterKey;
        uint256 newValue;
        string descriptionURI;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(uint256 => bool) hasVoted; // AuraSeedId -> voted status
        bool executed;
        bool passed;
    }
    Counters.Counter private s_nextGovernanceProposalId;
    mapping(uint256 => GovernanceProposal) private s_governanceProposals;

    // System Parameters (configurable by governance)
    uint256 public constant MIN_AURA_POINTS_TO_DELEGATE = 100; // Minimum points required to delegate
    uint256 public constant MIN_AURA_POINTS_FOR_VOTE = 50; // Minimum points required to vote on governance
    uint256 public constant GOVERNANCE_VOTING_PERIOD = 3 days; // Duration for voting on proposals
    uint256 public constant PROPOSAL_PASS_THRESHOLD_BPS = 5_000; // 50% threshold for proposal to pass (basis points)
    uint256 public constant PROPOSAL_QUORUM_PERCENTAGE = 1; // 1% of total AuraPoints needed for quorum

    // Decay parameters: decay (e.g., 5% every 30 days)
    uint256 public s_decayInterval = 30 days; // How often decay happens
    uint256 public s_decayRateNumerator = 5; // e.g., 5
    uint256 public s_decayRateDenominator = 100; // e.g., 100 (5/100 = 5%)

    // Predefined AuraPoint values for specific actions (can be configured by governance)
    mapping(bytes32 => uint256) public s_actionAuraPointValues; // e.g., keccak256("LOGIN_STREAK") -> 10 points

    // --- Events ---

    event AuraSeedMinted(uint256 indexed auraSeedId, address indexed owner, uint256 auraNFTId);
    event AuraSeedWithdrawn(uint256 indexed auraSeedId, address indexed owner);
    event AuraPointsEarned(uint256 indexed auraSeedId, uint256 amount, bytes32 contributionHash);
    event AuraPointsDecayed(uint256 indexed auraSeedId, uint256 oldPoints, uint256 newPoints);
    event PointAdjustmentProposed(uint256 indexed proposalId, uint256 indexed auraSeedId, int256 adjustment, string reasonURI);
    event ValidatorRegistered(address indexed validator, string name, string profileURI);
    event ContributionProposed(uint256 indexed proposalId, uint256 indexed auraSeedId, address proposer, bytes32 contributionHash);
    event ContributionValidated(uint256 indexed proposalId, uint256 indexed auraSeedId, address indexed validator, uint256 pointsAwarded);
    event ValidationRevoked(uint256 indexed proposalId, uint256 indexed auraSeedId, address indexed validator, string reasonURI);
    event AuraPointsDelegated(uint256 indexed delegationId, uint256 indexed delegatorAuraSeedId, address indexed delegatee, uint256 amount, uint256 duration);
    event DelegationRevoked(uint256 indexed delegationId);
    event GovernanceProposalCreated(uint256 indexed proposalId, bytes32 parameterKey, uint256 newValue, string descriptionURI);
    event GovernanceVoteCast(uint256 indexed proposalId, uint256 indexed auraSeedId, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId, bool passed);
    event ParameterChanged(bytes32 indexed parameterKey, uint256 oldValue, uint256 newValue);
    event MetadataBaseURIUpdated(string newURI);

    // --- Errors ---

    error AuraForge__AlreadyHasAuraSeed();
    error AuraForge__AuraSeedDoesNotExist();
    error AuraForge__NotAuraSeedHolder();
    error AuraForge__Unauthorized();
    error AuraForge__InvalidAmount();
    error AuraForge__InvalidDuration();
    error AuraForge__DelegationNotFound();
    error AuraForge__DelegationNotActive();
    error AuraForge__DelegationAlreadyExpired();
    error AuraForge__DelegationNotExpiredYet();
    error AuraForge__NotEnoughAuraPoints();
    error AuraForge__AuraSeedHasNoOwner();
    error AuraForge__ValidatorAlreadyRegistered();
    error AuraForge__ValidatorNotApproved();
    error AuraForge__ContributionNotFound();
    error AuraForge__ContributionAlreadyValidated();
    error AuraForge__ContributionNotValidated();
    error AuraForge__ContributionAlreadyRevoked();
    error AuraForge__ProposalNotFound();
    error AuraForge__ProposalAlreadyVoted();
    error AuraForge__ProposalNotActive();
    error AuraForge__ProposalAlreadyExecuted();
    error AuraForge__ProposalNotPassed();
    error AuraForge__QuorumNotReached();
    error AuraForge__VotingPeriodNotEnded();
    error AuraForge__InvalidParameterKey();
    error AuraForge__AuraSeedAlreadyDecayedForInterval();

    // --- Modifiers ---

    modifier onlyAuraSeedHolder(uint256 _auraSeedId) {
        if (s_ownerByAuraSeedId[_auraSeedId] != msg.sender) {
            revert AuraForge__NotAuraSeedHolder();
        }
        _;
    }

    modifier onlyApprovedValidator() {
        if (!s_isValidatorApproved[msg.sender]) {
            revert AuraForge__ValidatorNotApproved();
        }
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) Ownable(msg.sender) {
        s_baseTokenURI = baseURI;
    }

    // --- Internal & Helper Functions ---

    /**
     * @dev Calculates the effective AuraPoints for a given AuraSeed, factoring in decay and delegations.
     * @param _auraSeedId The ID of the AuraSeed.
     * @return The total effective AuraPoints.
     */
    function _getEffectiveAuraPoints(uint256 _auraSeedId) internal view returns (uint256) {
        _applyDecay(_auraSeedId); // Ensure latest state for calculation
        uint256 totalPoints = s_auraPoints[_auraSeedId].points;
        return totalPoints;
    }

    /**
     * @dev Applies the decay to AuraPoints based on elapsed time and decay parameters.
     *      This function is designed to be called whenever AuraPoints are queried or modified,
     *      or periodically by an external service for consistency.
     * @param _auraSeedId The ID of the AuraSeed to decay.
     */
    function _applyDecay(uint256 _auraSeedId) internal view {
        uint256 currentPoints = s_auraPoints[_auraSeedId].points;
        uint256 lastDecay = s_auraPoints[_auraSeedId].lastDecayTimestamp;

        if (currentPoints == 0 || lastDecay == 0) return; // No points or no initial decay timestamp

        uint256 intervalsPassed = (block.timestamp - lastDecay) / s_decayInterval;

        if (intervalsPassed == 0) return; // Not enough time passed for decay

        // Calculate new points after decay
        for (uint256 i = 0; i < intervalsPassed; i++) {
            currentPoints = currentPoints * (s_decayRateDenominator - s_decayRateNumerator) / s_decayRateDenominator;
        }

        // Store this new value. Note: This is a view function, actual state update happens in non-view functions.
        // For accurate point retrieval, non-view functions should first call a state-updating _decayAndSet function.
        // This view function is mainly for showing potential decayed value.
    }

    /**
     * @dev Internal function to apply decay and update the state.
     * @param _auraSeedId The ID of the AuraSeed to decay.
     */
    function _decayAndSet(uint256 _auraSeedId) internal {
        uint256 currentPoints = s_auraPoints[_auraSeedId].points;
        uint256 lastDecay = s_auraPoints[_auraSeedId].lastDecayTimestamp;

        if (currentPoints == 0 || lastDecay == 0) return;

        uint256 intervalsPassed = (block.timestamp - lastDecay) / s_decayInterval;
        if (intervalsPassed == 0) return;

        uint256 oldPoints = currentPoints;
        for (uint256 i = 0; i < intervalsPassed; i++) {
            currentPoints = currentPoints * (s_decayRateDenominator - s_decayRateNumerator) / s_decayRateDenominator;
        }

        s_auraPoints[_auraSeedId].points = currentPoints;
        s_auraPoints[_auraSeedId].lastDecayTimestamp = block.timestamp;
        emit AuraPointsDecayed(_auraSeedId, oldPoints, currentPoints);
    }

    // --- I. Core Identity & NFT Management (AuraSeed & AuraNFT) ---

    /**
     * @dev Allows an address to mint their unique, non-transferable AuraSeed (SBT)
     *      and its corresponding AuraNFT.
     * @notice A user can only mint one AuraSeed. The AuraSeed itself is not an ERC721,
     *         but its ID is tied to an ERC721 AuraNFT.
     */
    function mintAuraSeed() external {
        if (s_auraSeedIdByOwner[msg.sender] != 0) {
            revert AuraForge__AlreadyHasAuraSeed();
        }

        s_nextAuraSeedId.increment();
        uint256 newAuraSeedId = s_nextAuraSeedId.current();

        s_auraSeedIdByOwner[msg.sender] = newAuraSeedId;
        s_ownerByAuraSeedId[newAuraSeedId] = msg.sender;

        // Initialize AuraPoints for the new seed
        s_auraPoints[newAuraSeedId].points = 0;
        s_auraPoints[newAuraSeedId].lastDecayTimestamp = block.timestamp;

        // Mint the corresponding AuraNFT (ERC721)
        _safeMint(msg.sender, newAuraSeedId);

        emit AuraSeedMinted(newAuraSeedId, msg.sender, newAuraSeedId);
    }

    /**
     * @dev Retrieves the AuraSeed ID associated with a given owner address.
     * @param _owner The address to query.
     * @return The AuraSeed ID, or 0 if no AuraSeed exists for the address.
     */
    function getAuraSeedIdByOwner(address _owner) external view returns (uint256) {
        return s_auraSeedIdByOwner[_owner];
    }

    /**
     * @dev Retrieves the owner address associated with a given AuraSeed ID.
     * @param _auraSeedId The AuraSeed ID to query.
     * @return The owner address, or address(0) if no owner is found.
     */
    function getOwnerByAuraSeedId(uint256 _auraSeedId) external view returns (address) {
        return s_ownerByAuraSeedId[_auraSeedId];
    }

    /**
     * @dev Returns the dynamic metadata URI for a given AuraNFT.
     *      This URI is constructed using the base URI and the current AuraPoints.
     * @param _auraNFTId The ID of the AuraNFT.
     * @return The URI for the NFT's metadata.
     */
    function tokenURI(uint256 _auraNFTId) public view override returns (string memory) {
        _requireOwned(_auraNFTId); // Check if NFT exists

        uint256 currentPoints = _getEffectiveAuraPoints(_auraNFTId);
        string memory pointsStr = currentPoints.toString();

        // Example: Base URI could point to a service that renders metadata based on points
        // e.g., "https://auraservice.xyz/metadata/123?points=500"
        return string(abi.encodePacked(s_baseTokenURI, _auraNFTId.toString(), "?points=", pointsStr));
    }

    /**
     * @dev Allows an AuraSeed holder to voluntarily "burn" their AuraSeed and AuraNFT,
     *      exiting the ecosystem. This action is irreversible.
     * @param _auraSeedId The ID of the AuraSeed to withdraw.
     */
    function withdrawAuraSeed(uint256 _auraSeedId) external onlyAuraSeedHolder(_auraSeedId) {
        address owner = s_ownerByAuraSeedId[_auraSeedId];
        if (owner == address(0)) {
            revert AuraForge__AuraSeedDoesNotExist();
        }

        // Clear mappings for AuraSeed
        delete s_auraSeedIdByOwner[owner];
        delete s_ownerByAuraSeedId[_auraSeedId];
        delete s_auraPoints[_auraSeedId]; // Clear associated AuraPoints

        // Burn the corresponding AuraNFT
        _burn(_auraSeedId);

        // Revoke any active delegations from this AuraSeed (optional, depending on desired behavior)
        // For simplicity, we assume delegations become inactive without their delegator's points.
        // A more complex system might iterate through delegations to explicitly mark them as inactive.

        emit AuraSeedWithdrawn(_auraSeedId, owner);
    }

    // --- II. AuraPoint (Reputation) Management ---

    /**
     * @dev Retrieves the current AuraPoints for a specific AuraSeed holder, applying decay.
     * @param _auraSeedId The ID of the AuraSeed.
     * @return The current, decayed AuraPoints.
     */
    function getAuraPoints(uint256 _auraSeedId) public view returns (uint256) {
        if (s_ownerByAuraSeedId[_auraSeedId] == address(0)) {
            return 0; // Or revert AuraForge__AuraSeedDoesNotExist();
        }
        _applyDecay(_auraSeedId); // To get the most recent decayed value.
        return s_auraPoints[_auraSeedId].points;
    }

    /**
     * @dev Allows approved entities (e.g., Validators) to grant AuraPoints for a verified contribution.
     * @param _auraSeedId The ID of the AuraSeed to grant points to.
     * @param _amount The amount of AuraPoints to grant.
     * @param _contributionHash A unique hash identifying the contribution.
     */
    function earnAuraPoints(uint256 _auraSeedId, uint256 _amount, bytes32 _contributionHash) external onlyApprovedValidator {
        if (s_ownerByAuraSeedId[_auraSeedId] == address(0)) {
            revert AuraForge__AuraSeedDoesNotExist();
        }
        if (_amount == 0) {
            revert AuraForge__InvalidAmount();
        }

        _decayAndSet(_auraSeedId); // Apply decay before adding new points
        s_auraPoints[_auraSeedId].points += _amount;
        emit AuraPointsEarned(_auraSeedId, _amount, _contributionHash);
    }

    /**
     * @dev Triggers the decay of AuraPoints for a specific AuraSeed.
     *      This function can be called by anyone (e.g., a Keeper network) to ensure timely decay
     *      without requiring the user themselves to interact.
     * @param _auraSeedId The ID of the AuraSeed to decay.
     */
    function decayAuraPoints(uint256 _auraSeedId) external {
        if (s_ownerByAuraSeedId[_auraSeedId] == address(0)) {
            revert AuraForge__AuraSeedDoesNotExist();
        }
        // Check if decay has already been applied for the current interval
        if (block.timestamp - s_auraPoints[_auraSeedId].lastDecayTimestamp < s_decayInterval) {
            revert AuraForge__AuraSeedAlreadyDecayedForInterval();
        }
        _decayAndSet(_auraSeedId);
    }

    /**
     * @dev Allows anyone to propose an AuraPoint adjustment for an AuraSeed holder.
     *      This proposal is subject to governance approval (via vote).
     * @param _auraSeedId The ID of the AuraSeed to adjust points for.
     * @param _adjustment The signed amount of points to adjust (positive for add, negative for subtract).
     * @param _reasonURI URI pointing to the reason for the adjustment.
     */
    function proposePointAdjustment(uint256 _auraSeedId, int256 _adjustment, string memory _reasonURI) external {
        if (s_ownerByAuraSeedId[_auraSeedId] == address(0)) {
            revert AuraForge__AuraSeedDoesNotExist();
        }
        
        s_nextGovernanceProposalId.increment();
        uint256 proposalId = s_nextGovernanceProposalId.current();

        // This would be a specific type of governance proposal, perhaps a dedicated struct,
        // For simplicity, we'll model it as a generic parameter change for now.
        // In a real system, a dedicated proposal type might be needed for point adjustments.
        // Here, we'll use a specific key for point adjustment.
        bytes32 paramKey = keccak256(abi.encodePacked("AuraPointAdjustment", _auraSeedId.toString()));
        uint256 adjustedValue = (_adjustment > 0) ? uint256(_adjustment) : (type(uint256).max - uint256(-_adjustment) + 1); // Encode adjustment as uint for proposal

        s_governanceProposals[proposalId] = GovernanceProposal({
            parameterKey: paramKey,
            newValue: adjustedValue, // This requires a specific interpretation in executeProposal
            descriptionURI: _reasonURI,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + GOVERNANCE_VOTING_PERIOD,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false,
            passed: false
        });

        emit PointAdjustmentProposed(proposalId, _auraSeedId, _adjustment, _reasonURI);
    }

    // --- III. Validator & Contribution System ---

    /**
     * @dev Proposes an address to become a validator. This requires governance approval.
     *      Once approved via governance, the address becomes an `onlyApprovedValidator`.
     * @param _name The name of the validator.
     * @param _profileURI URI pointing to the validator's profile or credentials.
     */
    function registerValidator(string memory _name, string memory _profileURI) external {
        if (s_validators[msg.sender].registered) {
            revert AuraForge__ValidatorAlreadyRegistered();
        }

        s_validators[msg.sender] = Validator({
            name: _name,
            profileURI: _profileURI,
            registered: true
        });

        // This should ideally trigger a governance proposal for actual approval:
        // For simplicity, we'll just mark as registered here and assume another step for approval.
        // In a full system, this would be a governance proposal type.
        // For this contract, we'll let owner manually approve for demonstration.
        // owner().approveValidator(msg.sender); - This would be a separate owner function.
        // For this version, let's assume a proposal to *approve* a validator is needed.

        // Instead of immediate approval, a governance proposal should be created.
        // Example: proposeParameterChange(keccak256(abi.encodePacked("ApproveValidator", msg.sender)), 1, "Approve new validator");
        // And `executeProposal` would then set `s_isValidatorApproved[msg.sender] = true;`

        emit ValidatorRegistered(msg.sender, _name, _profileURI);
    }

    /**
     * @dev Allows an AuraSeed holder to propose a contribution for validation.
     *      If validated by an `approvedValidator`, AuraPoints will be awarded.
     * @param _auraSeedId The ID of the AuraSeed making the contribution.
     * @param _contributionHash A unique hash identifying the contribution (e.g., IPFS hash of work).
     * @param _descriptionURI URI pointing to a detailed description/proof of the contribution.
     */
    function proposeContribution(uint256 _auraSeedId, bytes32 _contributionHash, string memory _descriptionURI) external onlyAuraSeedHolder(_auraSeedId) {
        s_nextContributionProposalId.increment();
        uint256 proposalId = s_nextContributionProposalId.current();

        s_contributionProposals[proposalId] = ContributionProposal({
            auraSeedId: _auraSeedId,
            proposer: msg.sender,
            contributionHash: _contributionHash,
            descriptionURI: _descriptionURI,
            pointsAwarded: 0,
            validator: address(0),
            validated: false,
            revoked: false
        });

        emit ContributionProposed(proposalId, _auraSeedId, msg.sender, _contributionHash);
    }

    /**
     * @dev Allows a registered and approved validator to validate a proposed contribution,
     *      awarding a specified amount of AuraPoints.
     * @param _proposalId The ID of the contribution proposal.
     * @param _pointsAwarded The amount of AuraPoints to award for this contribution.
     */
    function validateContribution(uint256 _proposalId, uint256 _pointsAwarded) external onlyApprovedValidator {
        ContributionProposal storage proposal = s_contributionProposals[_proposalId];
        if (proposal.proposer == address(0)) {
            revert AuraForge__ContributionNotFound();
        }
        if (proposal.validated) {
            revert AuraForge__ContributionAlreadyValidated();
        }
        if (_pointsAwarded == 0) {
            revert AuraForge__InvalidAmount();
        }

        proposal.validated = true;
        proposal.pointsAwarded = _pointsAwarded;
        proposal.validator = msg.sender;

        _decayAndSet(proposal.auraSeedId); // Apply decay before adding points
        s_auraPoints[proposal.auraSeedId].points += _pointsAwarded;
        emit ContributionValidated(_proposalId, proposal.auraSeedId, msg.sender, _pointsAwarded);
    }

    /**
     * @dev Allows a validator to revoke a previously approved validation (e.g., if fraud is discovered).
     *      This will deduct the previously awarded AuraPoints.
     * @param _proposalId The ID of the contribution proposal whose validation is being revoked.
     * @param _reasonURI URI pointing to the reason for the revocation.
     */
    function revokeValidation(uint256 _proposalId, string memory _reasonURI) external onlyApprovedValidator {
        ContributionProposal storage proposal = s_contributionProposals[_proposalId];
        if (proposal.proposer == address(0)) {
            revert AuraForge__ContributionNotFound();
        }
        if (!proposal.validated) {
            revert AuraForge__ContributionNotValidated();
        }
        if (proposal.revoked) {
            revert AuraForge__ContributionAlreadyRevoked();
        }
        if (proposal.validator != msg.sender) { // Only the original validator can revoke (or governance)
            revert AuraForge__Unauthorized();
        }

        proposal.revoked = true;

        _decayAndSet(proposal.auraSeedId); // Apply decay before deducting points
        // Ensure points don't go negative
        if (s_auraPoints[proposal.auraSeedId].points < proposal.pointsAwarded) {
            s_auraPoints[proposal.auraSeedId].points = 0;
        } else {
            s_auraPoints[proposal.auraSeedId].points -= proposal.pointsAwarded;
        }
        emit ValidationRevoked(_proposalId, proposal.auraSeedId, msg.sender, _reasonURI);
    }

    /**
     * @dev Retrieves detailed information about a registered validator.
     * @param _validator The address of the validator.
     * @return name The validator's name.
     * @return profileURI URI to the validator's profile.
     * @return registered True if the validator has registered (not necessarily approved).
     * @return approved True if the validator has been approved via governance.
     */
    function getValidatorInfo(address _validator) external view returns (string memory name, string memory profileURI, bool registered, bool approved) {
        Validator storage val = s_validators[_validator];
        return (val.name, val.profileURI, val.registered, s_isValidatorApproved[_validator]);
    }

    // --- IV. Delegated Reputation System ---

    /**
     * @dev Allows an AuraSeed holder to delegate a portion of their AuraPoints to another address
     *      for a limited, specified duration.
     * @param _auraSeedId The ID of the delegator's AuraSeed.
     * @param _delegatee The address to delegate points to.
     * @param _amount The amount of AuraPoints to delegate.
     * @param _duration The duration in seconds for which the points are delegated.
     */
    function delegateAuraPoints(uint256 _auraSeedId, address _delegatee, uint256 _amount, uint256 _duration) external onlyAuraSeedHolder(_auraSeedId) {
        if (_amount == 0) {
            revert AuraForge__InvalidAmount();
        }
        if (_duration == 0) {
            revert AuraForge__InvalidDuration();
        }
        if (_getEffectiveAuraPoints(_auraSeedId) < MIN_AURA_POINTS_TO_DELEGATE) {
            revert AuraForge__NotEnoughAuraPoints(); // Can only delegate if you have a base amount
        }
        if (_delegatee == address(0)) {
            revert AuraForge__AuraSeedHasNoOwner(); // Or invalid delegatee
        }
        
        s_nextDelegationId.increment();
        uint256 delegationId = s_nextDelegationId.current();

        s_delegations[delegationId] = Delegation({
            delegatorAuraSeedId: _auraSeedId,
            delegatee: _delegatee,
            amount: _amount,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            active: true
        });

        emit AuraPointsDelegated(delegationId, _auraSeedId, _delegatee, _amount, _duration);
    }

    /**
     * @dev Allows the delegator to prematurely revoke an active delegation.
     * @param _delegationId The ID of the delegation to revoke.
     */
    function revokeDelegation(uint256 _delegationId) external {
        Delegation storage delegation = s_delegations[_delegationId];
        if (delegation.delegatorAuraSeedId == 0) {
            revert AuraForge__DelegationNotFound();
        }
        if (s_ownerByAuraSeedId[delegation.delegatorAuraSeedId] != msg.sender) {
            revert AuraForge__Unauthorized(); // Only delegator can revoke
        }
        if (!delegation.active) {
            revert AuraForge__DelegationNotActive();
        }
        if (block.timestamp >= delegation.endTime) {
            revert AuraForge__DelegationAlreadyExpired();
        }

        delegation.active = false;
        emit DelegationRevoked(_delegationId);
    }

    /**
     * @dev Returns the total effective AuraPoints currently delegated *by* an AuraSeed holder.
     * @param _auraSeedId The ID of the delegator's AuraSeed.
     * @return The total delegated points.
     */
    function getDelegatedPoints(uint256 _auraSeedId) external view returns (uint256) {
        uint256 total = 0;
        // This is inefficient for many delegations. For a production system,
        // a more optimized data structure (e.g., linked list for active delegations)
        // or off-chain aggregation would be required.
        // For demonstration purposes, we iterate through existing ones.
        for (uint256 i = 1; i <= s_nextDelegationId.current(); i++) {
            Delegation storage delegation = s_delegations[i];
            if (delegation.active && delegation.delegatorAuraSeedId == _auraSeedId && block.timestamp < delegation.endTime) {
                total += delegation.amount;
            }
        }
        return total;
    }

    /**
     * @dev Returns the total effective AuraPoints currently delegated *to* an AuraSeed holder.
     * @param _auraSeedId The ID of the AuraSeed that is receiving delegations.
     * @return The total received delegated points.
     */
    function getReceivedDelegatedPoints(uint256 _auraSeedId) external view returns (uint256) {
        address delegateeAddress = s_ownerByAuraSeedId[_auraSeedId];
        if (delegateeAddress == address(0)) {
            return 0; // Delegatee does not have an AuraSeed.
        }

        uint256 total = 0;
        for (uint256 i = 1; i <= s_nextDelegationId.current(); i++) {
            Delegation storage delegation = s_delegations[i];
            if (delegation.active && delegation.delegatee == delegateeAddress && block.timestamp < delegation.endTime) {
                total += delegation.amount;
            }
        }
        return total;
    }

    // --- V. Governance & System Parameters ---

    /**
     * @dev Creates a new governance proposal to change a system parameter.
     *      Requires the caller to be an AuraSeed holder with sufficient points.
     * @param _parameterKey A unique key identifying the parameter to change (e.g., keccak256("DECAY_RATE")).
     * @param _newValue The new value for the parameter.
     * @param _descriptionURI URI pointing to a detailed description of the proposal.
     */
    function proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, string memory _descriptionURI) external {
        uint256 proposerAuraSeedId = s_auraSeedIdByOwner[msg.sender];
        if (proposerAuraSeedId == 0) {
            revert AuraForge__NotAuraSeedHolder();
        }
        if (_getEffectiveAuraPoints(proposerAuraSeedId) < MIN_AURA_POINTS_FOR_VOTE) {
            revert AuraForge__NotEnoughAuraPoints();
        }

        s_nextGovernanceProposalId.increment();
        uint256 proposalId = s_nextGovernanceProposalId.current();

        s_governanceProposals[proposalId] = GovernanceProposal({
            parameterKey: _parameterKey,
            newValue: _newValue,
            descriptionURI: _descriptionURI,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + GOVERNANCE_VOTING_PERIOD,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false,
            passed: false
        });

        emit GovernanceProposalCreated(proposalId, _parameterKey, _newValue, _descriptionURI);
    }

    /**
     * @dev Allows AuraSeed holders to vote on active governance proposals.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        GovernanceProposal storage proposal = s_governanceProposals[_proposalId];
        if (proposal.voteStartTime == 0) {
            revert AuraForge__ProposalNotFound();
        }
        if (block.timestamp < proposal.voteStartTime || block.timestamp >= proposal.voteEndTime) {
            revert AuraForge__ProposalNotActive();
        }

        uint256 voterAuraSeedId = s_auraSeedIdByOwner[msg.sender];
        if (voterAuraSeedId == 0) {
            revert AuraForge__NotAuraSeedHolder();
        }
        if (proposal.hasVoted[voterAuraSeedId]) {
            revert AuraForge__ProposalAlreadyVoted();
        }
        if (_getEffectiveAuraPoints(voterAuraSeedId) < MIN_AURA_POINTS_FOR_VOTE) {
            revert AuraForge__NotEnoughAuraPoints();
        }

        proposal.hasVoted[voterAuraSeedId] = true;
        if (_support) {
            proposal.totalVotesFor += _getEffectiveAuraPoints(voterAuraSeedId);
        } else {
            proposal.totalVotesAgainst += _getEffectiveAuraPoints(voterAuraSeedId);
        }

        emit GovernanceVoteCast(_proposalId, voterAuraSeedId, _support);
    }

    /**
     * @dev Executes a governance proposal that has passed and met the quorum.
     * @param _proposalId The ID of the governance proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        GovernanceProposal storage proposal = s_governanceProposals[_proposalId];
        if (proposal.voteStartTime == 0) {
            revert AuraForge__ProposalNotFound();
        }
        if (proposal.executed) {
            revert AuraForge__ProposalAlreadyExecuted();
        }
        if (block.timestamp < proposal.voteEndTime) {
            revert AuraForge__VotingPeriodNotEnded();
        }

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        uint256 totalAuraPointsInCirculation = 0; // In a full system, this would be sum of all active AuraPoints
        // For simplicity, we'll use a placeholder or sum up active points (inefficient)
        // A more robust system would track total active AuraPoints.
        // For this demo, let's just make sure totalVotes is non-zero for quorum.
        
        // Placeholder for total active AuraPoints (replace with actual calculation for real system)
        // This is a complex calculation if it needs to iterate all AuraSeed holders.
        // For a demo, we assume a minimum quorum check for simplicity.
        // In a real system, one might track total points in a global state variable updated on mint/burn/decay.
        totalAuraPointsInCirculation = 1000; // Placeholder value for calculation below.
        
        if (totalVotes == 0 || totalVotes * 100 / totalAuraPointsInCirculation < PROPOSAL_QUORUM_PERCENTAGE) {
            revert AuraForge__QuorumNotReached();
        }

        bool passed = (proposal.totalVotesFor * 10_000 / totalVotes) >= PROPOSAL_PASS_THRESHOLD_BPS;
        proposal.passed = passed;

        if (!passed) {
            revert AuraForge__ProposalNotPassed();
        }

        // Execute the parameter change based on _parameterKey
        uint256 oldValue;
        if (proposal.parameterKey == keccak256("DECAY_INTERVAL")) {
            oldValue = s_decayInterval;
            s_decayInterval = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("DECAY_RATE_NUMERATOR")) {
            oldValue = s_decayRateNumerator;
            s_decayRateNumerator = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("DECAY_RATE_DENOMINATOR")) {
            oldValue = s_decayRateDenominator;
            s_decayRateDenominator = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("MIN_AURA_POINTS_TO_DELEGATE")) {
            oldValue = MIN_AURA_POINTS_TO_DELEGATE;
            // Note: Cannot directly assign to `public constant`. This would need to be a mutable `public` variable.
            // For demonstration, imagine it's mutable: MIN_AURA_POINTS_TO_DELEGATE = proposal.newValue;
            // For this contract, we'll skip direct assignment to constants and log it.
        } else if (proposal.parameterKey == keccak256("MIN_AURA_POINTS_FOR_VOTE")) {
            oldValue = MIN_AURA_POINTS_FOR_VOTE;
        } else if (proposal.parameterKey == keccak256("GOVERNANCE_VOTING_PERIOD")) {
            oldValue = GOVERNANCE_VOTING_PERIOD;
        } else if (proposal.parameterKey == keccak256("PROPOSAL_PASS_THRESHOLD_BPS")) {
            oldValue = PROPOSAL_PASS_THRESHOLD_BPS;
        } else if (proposal.parameterKey == keccak256("PROPOSAL_QUORUM_PERCENTAGE")) {
            oldValue = PROPOSAL_QUORUM_PERCENTAGE;
        } else if (bytes(proposal.parameterKey).length > 25 && keccak256(bytes.copy(proposal.parameterKey, 0, 19)) == keccak256("AuraPointAdjustment")) {
            // Special handling for PointAdjustment proposal
            uint256 auraSeedIdToAdjust;
            // Extract AuraSeedId from parameterKey (e.g., "AuraPointAdjustment" + AuraSeedId)
            // This requires careful encoding of the key in proposePointAdjustment
            // For simplicity, let's assume the newValue directly represents the adjustment if the key implies it.
            // In a real system, the `GovernanceProposal` struct would need to be more flexible,
            // e.g., using `bytes` for `newValue` and a `proposalType` enum.
            // For this demo, let's assume `newValue` directly encodes the `int256` adjustment
            // (positive value means add, negative value means subtract, max_uint to signify negative).
            auraSeedIdToAdjust = uint256(bytes32(bytes.copy(proposal.parameterKey, 19, 32))); // Assuming AuraSeedId is appended after "AuraPointAdjustment"

            _decayAndSet(auraSeedIdToAdjust);
            if (proposal.newValue > type(uint256).max / 2) { // Signifies a negative adjustment if encoded that way
                uint256 deduction = type(uint256).max - proposal.newValue + 1;
                if (s_auraPoints[auraSeedIdToAdjust].points < deduction) {
                    s_auraPoints[auraSeedIdToAdjust].points = 0;
                } else {
                    s_auraPoints[auraSeedIdToAdjust].points -= deduction;
                }
            } else { // Positive adjustment
                s_auraPoints[auraSeedIdToAdjust].points += proposal.newValue;
            }
            oldValue = s_auraPoints[auraSeedIdToAdjust].points; // Old value is current points before adjustment
        } else if (bytes(proposal.parameterKey).length > 16 && keccak256(bytes.copy(proposal.parameterKey, 0, 16)) == keccak256("ApproveValidator")) {
            // Handle validator approval
            address validatorAddress = address(bytes20(bytes.copy(proposal.parameterKey, 16, 20))); // Extract address
            s_isValidatorApproved[validatorAddress] = (proposal.newValue == 1); // 1 for approve, 0 for revoke
            oldValue = (s_isValidatorApproved[validatorAddress]) ? 1 : 0; // Placeholder, actual old state
        }
        else {
            revert AuraForge__InvalidParameterKey();
        }

        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId, passed);
        emit ParameterChanged(proposal.parameterKey, oldValue, proposal.newValue);
    }

    /**
     * @dev Allows governance (via a proposal) to update the base URI for AuraNFT metadata.
     * @param _newURI The new base URI for metadata.
     */
    function setMetadataBaseURI(string memory _newURI) external onlyOwner {
        // In a full governance setup, this would be an `executeProposal` outcome
        // For demo, owner can set directly.
        string memory oldURI = s_baseTokenURI;
        s_baseTokenURI = _newURI;
        emit MetadataBaseURIUpdated(oldURI);
    }

    /**
     * @dev Allows governance to configure predefined AuraPoint values for specific, recognized actions or integrations.
     * @param _actionType A unique identifier for the action (e.g., keccak256("DAILY_LOGIN")).
     * @param _points The amount of AuraPoints to award for this action.
     */
    function setAuraPointValue(bytes32 _actionType, uint256 _points) external onlyOwner {
        // In a full governance setup, this would be an `executeProposal` outcome
        // For demo, owner can set directly.
        uint256 oldPoints = s_actionAuraPointValues[_actionType];
        s_actionAuraPointValues[_actionType] = _points;
        emit ParameterChanged(keccak256(abi.encodePacked("ACTION_POINTS", _actionType)), oldPoints, _points);
    }

    /**
     * @dev Allows governance to adjust how AuraPoints decay over time.
     * @param _decayInterval The interval in seconds between decay events.
     * @param _decayRateNumerator The numerator for the decay rate (e.g., 5 for 5%).
     * @param _decayRateDenominator The denominator for the decay rate (e.g., 100 for 5%).
     */
    function setDecayParameters(uint256 _decayInterval, uint256 _decayRateNumerator, uint256 _decayRateDenominator) external onlyOwner {
        // In a full governance setup, this would be an `executeProposal` outcome
        // For demo, owner can set directly.
        require(_decayInterval > 0, "Interval must be > 0");
        require(_decayRateDenominator > 0, "Denominator must be > 0");
        require(_decayRateNumerator < _decayRateDenominator, "Numerator must be < Denominator for decay");

        uint256 oldInterval = s_decayInterval;
        uint256 oldNumerator = s_decayRateNumerator;
        uint256 oldDenominator = s_decayRateDenominator;

        s_decayInterval = _decayInterval;
        s_decayRateNumerator = _decayRateNumerator;
        s_decayRateDenominator = _decayRateDenominator;

        emit ParameterChanged(keccak256("DECAY_INTERVAL"), oldInterval, _decayInterval);
        emit ParameterChanged(keccak256("DECAY_RATE_NUMERATOR"), oldNumerator, _decayRateNumerator);
        emit ParameterChanged(keccak256("DECAY_RATE_DENOMINATOR"), oldDenominator, _decayRateDenominator);
    }
    
    // --- ERC721 Overrides for AuraNFT (to handle non-transferability of AuraSeed) ---

    // The AuraNFT itself is transferable if needed, but the AuraSeed (identity) is not.
    // The link between AuraNFT and AuraSeed is by _auraNFTId == _auraSeedId.
    // This design allows an evolving NFT that can be traded, while the underlying identity (SBT) remains tied to the address.
    // For a true "soulbound NFT" that itself is non-transferable, you would override _beforeTokenTransfer for the ERC721 itself.
    // Here, we have an SBT (AuraSeed) which is just a concept tied to an address, and an ERC721 (AuraNFT) that reflects its state.
    // If AuraNFT *also* needs to be non-transferable (a true Soulbound NFT), then uncomment and implement this:
    /*
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If the AuraNFT itself should be soulbound (non-transferable once minted)
        if (from != address(0) && to != address(0)) {
            revert AuraForge__AuraNFTIsSoulbound(); // Custom error
        }
    }
    */
    // For this contract, we assume AuraNFTs *can* be transferred, but they always reflect the AuraSeed ID's points.
    // The value of AuraNFT comes from its dynamic metadata reflecting an *active* AuraSeed's points.
    // If the AuraSeed is withdrawn, its AuraNFT would point to 0 points.
}
```