Okay, this is an exciting challenge! We'll create a smart contract called **"ChronoSculptor"**.

The core idea is to create Non-Fungible Tokens (NFTs) that are inherently tied to **time and conditions**. These "ChronoFragments" represent a commitment, a locked value, or a right that evolves and matures over time, based on a set of on-chain verifiable conditions. It introduces concepts like:

1.  **Temporal Evolution:** NFTs that change their "phase" based on `block.timestamp`.
2.  **Conditional Fulfillment:** NFTs that require external conditions (via oracles or ZK proofs) to be met throughout their active duration.
3.  **Time-Based Yield/Rewards:** Incentivizing sustained condition adherence.
4.  **ZK-Proof Integration (Conceptual):** Proving adherence to a temporal condition without revealing specific sensitive data.
5.  **Decentralized Governance:** For protocol parameters and condition whitelisting.

---

## ChronoSculptor: A Temporal & Conditional NFT Protocol

**Contract Name:** `ChronoSculptor`

**Core Concept:** `ChronoSculptor` allows users to create, manage, and redeem "ChronoFragments" – unique NFTs representing a time-locked value or commitment, whose maturity and redeemability are contingent upon meeting specific, verifiable conditions throughout a defined temporal window. These conditions can be set via trusted oracles or, in advanced scenarios, verified through Zero-Knowledge Proofs.

---

### Outline & Function Summary

**I. Core Data Structures & Enumerations**
*   `Phase`: Enum representing the lifecycle of a ChronoFragment (e.g., `Uninitialized`, `PendingActivation`, `Active`, `Matured`, `Forfeited`, `Redeemed`).
*   `ChronoFragment`: Struct holding all properties of an NFT (ID, owner, sculptor, collateral, time bounds, conditions, current phase, etc.).
*   `ConditionDefinition`: Struct defining a condition (e.g., `oracleAddress`, `expectedValue`, `zkpVerifierAddress`).

**II. ERC-721 Standard Compliance**
*   `constructor`: Initializes ERC-721 with name and symbol.
*   `balanceOf`: Returns number of fragments owned by an address.
*   `ownerOf`: Returns owner of a fragment.
*   `safeTransferFrom`, `transferFrom`: Transfer fragment ownership.
*   `approve`, `setApprovalForAll`: Standard approval mechanisms.
*   `getApproved`, `isApprovedForAll`: Standard approval checks.
*   `supportsInterface`: ERC-165 support.
*   `tokenURI`: Generates dynamic metadata URI based on fragment state.

**III. ChronoFragment Lifecycle Management**
1.  `createChronoFragment`: Mints a new ChronoFragment, defining its time window, collateral, and initial conditions.
2.  `activateChronoFragment`: Marks a fragment as `Active` if its `startTime` has passed and initial conditions are met. Starts the active period.
3.  `checkFragmentStatusAndAdvance`: Internal function (called by many external functions) to evaluate a fragment's current state based on `block.timestamp` and current condition adherence, potentially advancing its `Phase`.
4.  `updateFragmentConditionStatus`: **(Oracle/ZKP only)** Allows whitelisted oracles or ZKP verifiers to update the status of a specific condition for a fragment.
5.  `redeemChronoFragment`: Allows the owner to claim the underlying `collateralAmount` if the fragment is `Matured` and all conditions were met throughout its `Active` phase.
6.  `forfeitChronoFragment`: Allows an owner to voluntarily forfeit a fragment, or automatically transitions if conditions consistently fail over time.
7.  `extendFragmentDuration`: Allows the owner to extend the `endTime` of an `Active` fragment, potentially requiring additional collateral or a fee.
8.  `shortenFragmentDuration`: Allows the owner to shorten the `endTime` of an `Active` fragment, potentially incurring a penalty.
9.  `migrateFragmentData`: Allows the protocol to upgrade the data structure of an old fragment to a new version (if governance approves, for future compatibility).

**IV. Condition & Oracle Management**
10. `defineCondition`: DAO-governed function to register a new condition type, associating it with an oracle address or a ZKP verifier.
11. `removeCondition`: DAO-governed function to deprecate a condition type.
12. `registerOracle`: DAO-governed function to whitelist an address as a trusted oracle for specific condition types.
13. `deregisterOracle`: DAO-governed function to remove an oracle.
14. `submitZKProofForCondition`: Allows a user to submit a ZK proof (e.g., `proofOfDuration`) to verify a condition without revealing sensitive data. The contract will verify the proof against a pre-registered verifier.

**V. Time-Based Yield & Staking**
15. `claimTimeYield`: Allows owners of `Active` fragments that consistently meet conditions to claim a small, continuous yield (e.g., from protocol fees, or a dedicated rewards pool) based on the duration of adherence.
16. `stakeChronoFragment`: Locks a ChronoFragment for a specified duration, potentially granting boosted `claimTimeYield` or governance power.
17. `unstakeChronoFragment`: Releases a staked ChronoFragment after its staking period ends.

**VI. Protocol Governance & Treasury**
18. `proposeParameterChange`: Allows whitelisted addresses (e.g., staked fragment holders) to propose changes to protocol parameters (e.g., fees, reward curves, new condition types).
19. `voteOnProposal`: Allows eligible voters to cast votes on active proposals.
20. `executeProposal`: Allows anyone to execute a proposal once the voting period ends and quorum/thresholds are met.
21. `setProtocolFeeRate`: Sets the percentage fee taken on certain operations (e.g., fragment creation, redemption).
22. `collectProtocolFees`: Allows the DAO/treasury to withdraw accumulated fees.
23. `emergencyPause`: Allows the owner/DAO to pause critical operations in an emergency.

**VII. View/Helper Functions**
24. `getFragmentDetails`: Returns all details of a specific ChronoFragment.
25. `getConditionDefinition`: Returns details of a registered condition.
26. `isOracleRegistered`: Checks if an address is a registered oracle.

---

### ChronoSculptor Smart Contract (Solidity)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Using SafeCast for explicit casting checks where needed, though Solidity 0.8+ handles overflow/underflow for basic ops.

contract ChronoSculptor is ERC721URIStorage, Ownable {
    using Strings for uint256;
    using SafeCast for uint256;

    // --- Events ---
    event FragmentCreated(
        uint256 indexed tokenId,
        address indexed sculptor,
        address indexed initialOwner,
        address collateralAsset,
        uint256 collateralAmount,
        uint256 startTime,
        uint256 endTime
    );
    event FragmentActivated(uint256 indexed tokenId, uint256 activationTime);
    event FragmentPhaseAdvanced(
        uint256 indexed tokenId,
        Phase oldPhase,
        Phase newPhase
    );
    event FragmentRedeemed(
        uint256 indexed tokenId,
        address indexed redeemer,
        uint256 amountRedeemed
    );
    event FragmentForfeited(uint256 indexed tokenId, address indexed forfeiter);
    event FragmentDurationExtended(
        uint256 indexed tokenId,
        uint256 oldEndTime,
        uint256 newEndTime
    );
    event FragmentDurationShortened(
        uint256 indexed tokenId,
        uint256 oldEndTime,
        uint256 newEndTime
    );
    event ConditionStatusUpdated(
        uint256 indexed tokenId,
        bytes32 indexed conditionId,
        bool newStatus
    );
    event TimeYieldClaimed(
        uint256 indexed tokenId,
        address indexed claimant,
        uint256 amount
    );
    event FragmentStaked(uint256 indexed tokenId, address indexed staker);
    event FragmentUnstaked(uint256 indexed tokenId, address indexed unstaker);
    event ProtocolFeeRateSet(uint256 newRateBps);
    event ProtocolFeesCollected(address indexed collector, uint256 amount);
    event OracleRegistered(address indexed oracleAddress, bytes32 indexed conditionId);
    event OracleDeregistered(address indexed oracleAddress, bytes32 indexed conditionId);
    event ConditionDefined(bytes32 indexed conditionId, address associatedAddress, ConditionType cType);
    event ConditionRemoved(bytes32 indexed conditionId);
    event ZKProofSubmitted(uint256 indexed tokenId, bytes32 indexed conditionId);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 indexed paramHash, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);


    // --- Errors ---
    error NotFragmentOwner(uint256 tokenId);
    error InvalidPhase(uint256 tokenId, Phase expectedPhase, Phase actualPhase);
    error ConditionsNotMet(uint256 tokenId);
    error InvalidTimeWindow(uint256 startTime, uint256 endTime);
    error InsufficientCollateral();
    error AlreadyActivated();
    error NotOracleOrVerifier(bytes32 conditionId);
    error ConditionNotRegistered(bytes32 conditionId);
    error InvalidConditionType(bytes32 conditionId);
    error FragmentNotStaked(uint256 tokenId);
    error FragmentAlreadyStaked(uint256 tokenId);
    error StakingPeriodNotEnded(uint256 tokenId, uint256 endTime);
    error NoYieldToClaim(uint256 tokenId);
    error CannotUpdateActiveFragmentConditions();
    error NotEnoughTimeElapsed();
    error ProposalNotFound(uint256 proposalId);
    error VotingPeriodActive(uint256 proposalId);
    error VotingPeriodEnded(uint256 proposalId);
    error QuorumNotReached(uint256 proposalId);
    error ThresholdNotMet(uint256 proposalId);
    error AlreadyVoted(uint256 proposalId);
    error InsufficientVotingPower();
    error EmergencyPaused();

    // --- Enums ---
    enum Phase {
        Uninitialized,
        PendingActivation, // Created, but not yet active (e.g., start time in future)
        Active,            // Start time passed, conditions being monitored
        Matured,           // End time passed, conditions met throughout active phase
        Forfeited,         // Conditions failed, or voluntarily forfeited
        Redeemed           // Collateral claimed by owner
    }

    enum ConditionType {
        Oracle, // Verified by a whitelisted oracle address
        ZKProof // Verified by a ZK proof verifier contract
    }

    // --- Structs ---
    struct ChronoFragment {
        uint256 id;                 // Unique token ID
        address sculptor;           // Creator of the fragment
        address currentOwner;       // Current owner of the NFT
        address collateralAsset;    // ERC20 token address backing this fragment
        uint256 collateralAmount;   // Amount of collateral held
        uint256 startTime;          // When the fragment becomes active
        uint256 endTime;            // When the fragment matures or expires
        Phase currentPhase;         // Current lifecycle phase
        uint256 lastConditionCheckTime; // Timestamp of the last successful condition check for yield calculation
        uint256 cumulativeYieldClaimed; // Total yield claimed so far for this fragment
        uint256 lastYieldClaimTime; // Last time yield was claimed

        mapping(bytes32 => bool) conditionsMetStatus; // State of each active condition
        bytes32[] activeConditionIds; // List of condition IDs that must be met

        // Staking related
        bool isStaked;
        uint256 stakingEndTime;
        address stakingDelegator; // If staked by someone else, or who to delegate governance power to
    }

    struct ConditionDefinition {
        ConditionType cType;         // Type of condition (Oracle or ZKProof)
        address associatedAddress;   // Oracle address or ZKP verifier contract address
        bool isEnabled;              // Whether this condition type is currently active
    }

    // Simple proposal struct for DAO (simplified for this example)
    struct Proposal {
        bytes32 paramHash;      // Unique identifier for the parameter being changed
        string description;     // Description of the proposed change
        uint256 voteStartTime;  // When voting begins
        uint256 voteEndTime;    // When voting ends
        uint256 votesFor;       // Number of votes in favor
        uint256 votesAgainst;   // Number of votes against
        bool executed;          // Whether the proposal has been executed
        mapping(address => bool) hasVoted; // Tracks who has voted
    }

    // --- State Variables ---
    uint256 private _nextTokenId;
    mapping(uint256 => ChronoFragment) public chronoFragments;

    // Condition management
    mapping(bytes32 => ConditionDefinition) public conditionDefinitions;
    // Map conditionId to oracle addresses
    mapping(bytes32 => mapping(address => bool)) public registeredOracles;

    // Protocol Fees
    uint256 public protocolFeeRateBPS; // Basis points (e.g., 100 = 1%)
    uint256 public totalProtocolFeesCollected;
    address public protocolFeeTreasury; // Address where fees are sent (e.g., a DAO treasury)

    // Governance related
    uint256 public minStakedFragmentsForProposal; // Minimum number of staked fragments to propose
    uint256 public votingPeriodDuration; // Duration of voting in seconds
    uint256 public proposalQuorumBPS; // Quorum percentage (basis points)
    uint256 public proposalThresholdBPS; // Approval threshold percentage (basis points)
    uint256 public totalStakedFragments; // Total count of currently staked fragments
    uint256 private _nextProposalId;
    mapping(uint256 => Proposal) public proposals;


    // Emergency pause mechanism
    bool public paused = false;

    // --- Modifiers ---
    modifier onlyFragmentOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert NotFragmentOwner(tokenId);
        }
        _;
    }

    modifier onlyOracleOrVerifier(bytes32 conditionId) {
        ConditionDefinition storage condDef = conditionDefinitions[conditionId];
        if (!condDef.isEnabled) {
            revert ConditionNotRegistered(conditionId);
        }
        if (condDef.cType == ConditionType.Oracle && !registeredOracles[conditionId][_msgSender()]) {
            revert NotOracleOrVerifier(conditionId);
        }
        if (condDef.cType == ConditionType.ZKProof && condDef.associatedAddress != address(0) && condDef.associatedAddress != _msgSender()) {
            // This assumes the ZKP verifier contract calls this, or the ZKP caller is whitelisted
            // In a real ZKP integration, this would be more nuanced, potentially verifying the proof
            // within this function call. For simplicity, we assume the 'associatedAddress' *is* the verifier
            // and it's calling directly or a trusted gateway for ZKP submission.
            revert NotOracleOrVerifier(conditionId);
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) {
            revert EmergencyPaused();
        }
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _nextTokenId = 1;
        protocolFeeRateBPS = 50; // 0.5% default fee
        protocolFeeTreasury = msg.sender; // Owner is initial treasury
        minStakedFragmentsForProposal = 1; // 1 staked fragment to propose
        votingPeriodDuration = 3 days; // 3 days voting period
        proposalQuorumBPS = 4000; // 40% quorum
        proposalThresholdBPS = 5000; // 50% majority
        _nextProposalId = 1;
    }

    // --- Core ChronoFragment Lifecycle Management ---

    /**
     * @notice Mints a new ChronoFragment NFT with specified time bounds, collateral, and initial conditions.
     * @dev Collateral ERC20 tokens must be approved to this contract address prior to calling.
     * @param _collateralAsset Address of the ERC20 token to use as collateral.
     * @param _collateralAmount Amount of collateral tokens.
     * @param _startTime Timestamp when the fragment becomes active.
     * @param _endTime Timestamp when the fragment matures.
     * @param _initialConditionIds Array of condition IDs that must be met.
     * @return The ID of the newly minted ChronoFragment.
     */
    function createChronoFragment(
        address _collateralAsset,
        uint256 _collateralAmount,
        uint256 _startTime,
        uint256 _endTime,
        bytes32[] calldata _initialConditionIds
    ) external whenNotPaused returns (uint256) {
        if (_startTime >= _endTime || _endTime <= block.timestamp) {
            revert InvalidTimeWindow(_startTime, _endTime);
        }
        if (_collateralAmount == 0) {
            revert InsufficientCollateral();
        }

        uint256 tokenId = _nextTokenId++;
        address currentOwner = _msgSender();

        // Transfer collateral from creator to this contract
        IERC20(_collateralAsset).transferFrom(currentOwner, address(this), _collateralAmount);

        // Initialize conditions status
        mapping(bytes32 => bool) storage conditionsMap = chronoFragments[tokenId].conditionsMetStatus;
        for (uint256 i = 0; i < _initialConditionIds.length; i++) {
            bytes32 conditionId = _initialConditionIds[i];
            if (!conditionDefinitions[conditionId].isEnabled) {
                revert ConditionNotRegistered(conditionId);
            }
            // All initial conditions are considered 'true' until an oracle/ZKP says otherwise
            // This assumes initial state is good, and monitors for failures.
            conditionsMap[conditionId] = true;
        }

        chronoFragments[tokenId] = ChronoFragment({
            id: tokenId,
            sculptor: currentOwner,
            currentOwner: currentOwner,
            collateralAsset: _collateralAsset,
            collateralAmount: _collateralAmount,
            startTime: _startTime,
            endTime: _endTime,
            currentPhase: Phase.Uninitialized, // Set to PendingActivation by _checkFragmentStatusAndAdvance
            lastConditionCheckTime: block.timestamp,
            cumulativeYieldClaimed: 0,
            lastYieldClaimTime: block.timestamp,
            activeConditionIds: _initialConditionIds,
            isStaked: false,
            stakingEndTime: 0,
            stakingDelegator: address(0)
        });

        _safeMint(currentOwner, tokenId);
        _setTokenURI(tokenId, _generateTokenURI(tokenId));

        // Set initial phase
        _checkFragmentStatusAndAdvance(tokenId);

        emit FragmentCreated(tokenId, currentOwner, currentOwner, _collateralAsset, _collateralAmount, _startTime, _endTime);
        return tokenId;
    }

    /**
     * @notice Activates a ChronoFragment if its start time has passed and it's in a pending phase.
     * @param tokenId The ID of the ChronoFragment to activate.
     */
    function activateChronoFragment(uint256 tokenId) external onlyFragmentOwner(tokenId) whenNotPaused {
        ChronoFragment storage fragment = chronoFragments[tokenId];
        if (fragment.currentPhase == Phase.Active) {
            revert AlreadyActivated();
        }
        if (fragment.currentPhase != Phase.PendingActivation && fragment.currentPhase != Phase.Uninitialized) {
            revert InvalidPhase(tokenId, Phase.PendingActivation, fragment.currentPhase);
        }

        _checkFragmentStatusAndAdvance(tokenId); // Will transition to Active if startTime passed
        if (fragment.currentPhase != Phase.Active) {
            revert ConditionsNotMet(tokenId); // If it still isn't active, conditions aren't met
        }
        emit FragmentActivated(tokenId, block.timestamp);
    }

    /**
     * @notice Internal function to evaluate a fragment's state and advance its phase.
     * @dev This function is called internally by most public functions that interact with fragments.
     * @param tokenId The ID of the ChronoFragment.
     * @return The new phase of the fragment.
     */
    function _checkFragmentStatusAndAdvance(uint256 tokenId) internal returns (Phase) {
        ChronoFragment storage fragment = chronoFragments[tokenId];
        Phase oldPhase = fragment.currentPhase;
        bool allConditionsMet = true;

        // Check all active conditions
        for (uint256 i = 0; i < fragment.activeConditionIds.length; i++) {
            bytes32 conditionId = fragment.activeConditionIds[i];
            if (!fragment.conditionsMetStatus[conditionId]) {
                allConditionsMet = false;
                break;
            }
        }

        // State machine transitions
        if (fragment.currentPhase == Phase.Uninitialized) {
            if (block.timestamp >= fragment.startTime) {
                fragment.currentPhase = Phase.PendingActivation;
            }
        }

        if (fragment.currentPhase == Phase.PendingActivation) {
            if (block.timestamp >= fragment.startTime && allConditionsMet) {
                fragment.currentPhase = Phase.Active;
            } else if (block.timestamp > fragment.endTime) {
                fragment.currentPhase = Phase.Forfeited; // Did not activate in time
            }
        }

        if (fragment.currentPhase == Phase.Active) {
            if (!allConditionsMet) {
                fragment.currentPhase = Phase.Forfeited;
            } else if (block.timestamp >= fragment.endTime) {
                fragment.currentPhase = Phase.Matured;
            }
        }

        // If conditions were met, update last check time for yield calculation
        if (fragment.currentPhase == Phase.Active && allConditionsMet) {
            fragment.lastConditionCheckTime = block.timestamp;
        }

        if (oldPhase != fragment.currentPhase) {
            emit FragmentPhaseAdvanced(tokenId, oldPhase, fragment.currentPhase);
            _setTokenURI(tokenId, _generateTokenURI(tokenId)); // Update metadata on phase change
        }
        return fragment.currentPhase;
    }

    /**
     * @notice Allows the owner to redeem the collateral of a Matured ChronoFragment.
     * @param tokenId The ID of the ChronoFragment to redeem.
     */
    function redeemChronoFragment(uint256 tokenId) external onlyFragmentOwner(tokenId) whenNotPaused {
        ChronoFragment storage fragment = chronoFragments[tokenId];
        
        _checkFragmentStatusAndAdvance(tokenId); // Ensure phase is up-to-date

        if (fragment.currentPhase != Phase.Matured) {
            revert InvalidPhase(tokenId, Phase.Matured, fragment.currentPhase);
        }

        // Transfer collateral to owner
        IERC20(fragment.collateralAsset).transfer(fragment.currentOwner, fragment.collateralAmount);

        uint256 redeemedAmount = fragment.collateralAmount;
        fragment.currentPhase = Phase.Redeemed; // Mark as redeemed
        fragment.collateralAmount = 0; // Clear collateral amount
        _setTokenURI(tokenId, _generateTokenURI(tokenId));

        emit FragmentRedeemed(tokenId, _msgSender(), redeemedAmount);
    }

    /**
     * @notice Allows the owner to voluntarily forfeit a ChronoFragment, or marks it as forfeited if conditions fail.
     * @param tokenId The ID of the ChronoFragment to forfeit.
     */
    function forfeitChronoFragment(uint256 tokenId) external onlyFragmentOwner(tokenId) whenNotPaused {
        ChronoFragment storage fragment = chronoFragments[tokenId];

        _checkFragmentStatusAndAdvance(tokenId); // Ensure phase is up-to-date

        if (fragment.currentPhase == Phase.Redeemed || fragment.currentPhase == Phase.Forfeited) {
            revert InvalidPhase(tokenId, Phase.Active, fragment.currentPhase); // Already finished or forfeited
        }

        fragment.currentPhase = Phase.Forfeited; // Explicitly set to forfeited
        // Collateral may be sent to treasury or burned based on protocol rules
        // For now, it remains in the contract, unredeemable by the user.
        _setTokenURI(tokenId, _generateTokenURI(tokenId));

        emit FragmentForfeited(tokenId, _msgSender());
    }

    /**
     * @notice Allows the owner to extend the end time of an Active ChronoFragment.
     * @dev May require additional collateral or a protocol fee.
     * @param tokenId The ID of the ChronoFragment.
     * @param newEndTime The new timestamp for the fragment's end. Must be greater than current end time.
     */
    function extendFragmentDuration(uint256 tokenId, uint256 newEndTime) external onlyFragmentOwner(tokenId) whenNotPaused {
        ChronoFragment storage fragment = chronoFragments[tokenId];

        _checkFragmentStatusAndAdvance(tokenId);

        if (fragment.currentPhase != Phase.Active) {
            revert InvalidPhase(tokenId, Phase.Active, fragment.currentPhase);
        }
        if (newEndTime <= fragment.endTime) {
            revert InvalidTimeWindow(fragment.startTime, newEndTime); // Must be truly extended
        }

        uint256 oldEndTime = fragment.endTime;
        fragment.endTime = newEndTime;

        // Apply a fee or additional collateral if desired
        // uint256 durationIncrease = newEndTime - oldEndTime;
        // uint256 additionalCost = (durationIncrease * fragment.collateralAmount) / (1 days * 100); // Example cost model

        // if (additionalCost > 0) {
        //     IERC20(fragment.collateralAsset).transferFrom(_msgSender(), address(this), additionalCost);
        //     fragment.collateralAmount += additionalCost;
        // }

        _setTokenURI(tokenId, _generateTokenURI(tokenId));
        emit FragmentDurationExtended(tokenId, oldEndTime, newEndTime);
    }

    /**
     * @notice Allows the owner to shorten the end time of an Active ChronoFragment.
     * @dev May incur a penalty or fee.
     * @param tokenId The ID of the ChronoFragment.
     * @param newEndTime The new timestamp for the fragment's end. Must be greater than block.timestamp and less than current end time.
     */
    function shortenFragmentDuration(uint256 tokenId, uint256 newEndTime) external onlyFragmentOwner(tokenId) whenNotPaused {
        ChronoFragment storage fragment = chronoFragments[tokenId];

        _checkFragmentStatusAndAdvance(tokenId);

        if (fragment.currentPhase != Phase.Active) {
            revert InvalidPhase(tokenId, Phase.Active, fragment.currentPhase);
        }
        if (newEndTime <= block.timestamp || newEndTime >= fragment.endTime) {
            revert InvalidTimeWindow(fragment.startTime, newEndTime); // Must be shortened, but not expired
        }

        uint256 oldEndTime = fragment.endTime;
        fragment.endTime = newEndTime;

        // Apply a penalty or fee if desired
        // uint256 durationDecrease = oldEndTime - newEndTime;
        // uint256 penaltyAmount = (durationDecrease * fragment.collateralAmount) / (1 days * 100); // Example penalty model
        // totalProtocolFeesCollected += penaltyAmount; // Send penalty to protocol

        _setTokenURI(tokenId, _generateTokenURI(tokenId));
        emit FragmentDurationShortened(tokenId, oldEndTime, newEndTime);
    }

    /**
     * @notice Allows the protocol to upgrade the data structure of an old fragment.
     * @dev This would be used in a phased rollout of new features or structural changes,
     *      allowing old fragments to be compatible with new logic. Requires governance approval.
     * @param tokenId The ID of the fragment to migrate.
     */
    function migrateFragmentData(uint256 tokenId) external onlyOwner {
        // This is a placeholder for a complex migration logic.
        // In a real scenario, this would involve reading old data, transforming it,
        // and writing it back in a new format. It would likely be triggered by a DAO proposal.
        // For example:
        // ChronoFragmentV1 storage oldFragment = oldChronoFragments[tokenId];
        // ChronoFragmentV2 storage newFragment = chronoFragments[tokenId];
        // newFragment.id = oldFragment.id;
        // ... copy and transform data ...
        // delete oldChronoFragments[tokenId]; // If migrating out of an old storage mapping
        // emit FragmentMigrated(tokenId, "V1 to V2");
    }

    // --- Condition & Oracle Management ---

    /**
     * @notice Owner/DAO function to define a new condition type and its associated verifier.
     * @param _conditionId A unique identifier for the condition.
     * @param _cType The type of condition (Oracle or ZKProof).
     * @param _associatedAddress The address of the oracle or ZKP verifier contract.
     */
    function defineCondition(bytes32 _conditionId, ConditionType _cType, address _associatedAddress) external onlyOwner {
        conditionDefinitions[_conditionId] = ConditionDefinition({
            cType: _cType,
            associatedAddress: _associatedAddress,
            isEnabled: true
        });
        emit ConditionDefined(_conditionId, _associatedAddress, _cType);
    }

    /**
     * @notice Owner/DAO function to remove (disable) a condition type.
     * @param _conditionId The ID of the condition to remove.
     */
    function removeCondition(bytes32 _conditionId) external onlyOwner {
        if (!conditionDefinitions[_conditionId].isEnabled) {
            revert ConditionNotRegistered(_conditionId);
        }
        conditionDefinitions[_conditionId].isEnabled = false;
        emit ConditionRemoved(_conditionId);
    }

    /**
     * @notice Owner/DAO function to register an address as a trusted oracle for a specific condition type.
     * @param _oracleAddress The address of the oracle.
     * @param _conditionId The ID of the condition this oracle can update.
     */
    function registerOracle(address _oracleAddress, bytes32 _conditionId) external onlyOwner {
        if (conditionDefinitions[_conditionId].cType != ConditionType.Oracle) {
            revert InvalidConditionType(_conditionId);
        }
        registeredOracles[_conditionId][_oracleAddress] = true;
        emit OracleRegistered(_oracleAddress, _conditionId);
    }

    /**
     * @notice Owner/DAO function to deregister an oracle for a specific condition type.
     * @param _oracleAddress The address of the oracle.
     * @param _conditionId The ID of the condition this oracle was able to update.
     */
    function deregisterOracle(address _oracleAddress, bytes32 _conditionId) external onlyOwner {
        registeredOracles[_conditionId][_oracleAddress] = false;
        emit OracleDeregistered(_oracleAddress, _conditionId);
    }

    /**
     * @notice Allows a whitelisted oracle or ZKP verifier to update the status of a condition for a specific fragment.
     * @param tokenId The ID of the ChronoFragment.
     * @param conditionId The ID of the condition being updated.
     * @param status The new status (true if met, false if failed).
     */
    function updateFragmentConditionStatus(uint256 tokenId, bytes32 conditionId, bool status)
        external
        onlyOracleOrVerifier(conditionId)
        whenNotPaused
    {
        ChronoFragment storage fragment = chronoFragments[tokenId];
        if (fragment.currentPhase != Phase.Active && fragment.currentPhase != Phase.PendingActivation) {
            revert InvalidPhase(tokenId, Phase.Active, fragment.currentPhase);
        }

        fragment.conditionsMetStatus[conditionId] = status;
        _checkFragmentStatusAndAdvance(tokenId); // Re-evaluate fragment status based on new condition
        emit ConditionStatusUpdated(tokenId, conditionId, status);
    }

    /**
     * @notice Submits a Zero-Knowledge Proof to verify a condition without revealing sensitive data.
     * @dev This is a conceptual function. Real integration requires a separate ZKP verifier contract
     *      and a well-defined proof system (e.g., Groth16, Plonk).
     * @param tokenId The ID of the ChronoFragment.
     * @param conditionId The ID of the condition associated with this ZK proof.
     * @param _proof The actual ZK proof data (e.g., `[uint256 a, uint256[2] b, uint256[2] c]`).
     * @param _publicInputs The public inputs for the ZK proof (e.g., `[uint256 hashOfValue, uint256 threshold]`).
     */
    function submitZKProofForCondition(
        uint256 tokenId,
        bytes32 conditionId,
        uint256[2] calldata _proofA,
        uint256[2][2] calldata _proofB,
        uint256[2] calldata _proofC,
        uint256[/* arbitrary */] calldata _publicInputs
    ) external whenNotPaused {
        ConditionDefinition storage condDef = conditionDefinitions[conditionId];
        if (condDef.cType != ConditionType.ZKProof || condDef.associatedAddress == address(0)) {
            revert InvalidConditionType(conditionId);
        }

        // --- CONCEPTUAL ZKP VERIFICATION ---
        // In a real scenario, you would call the associated ZKP verifier contract like:
        // bool isValid = IVerifier(condDef.associatedAddress).verifyProof(_proofA, _proofB, _proofC, _publicInputs);
        // require(isValid, "ZKProof verification failed.");

        // For this example, we'll simulate success, assuming the external verifier handles the actual logic.
        // The sender needs to be the `associatedAddress` or a trusted relay for the verifier,
        // or the ZKP verifier calls this function directly after a successful verification.
        // The `onlyOracleOrVerifier` modifier above would need to be adapted for this.
        bool simulatedZKPSuccess = true; // Placeholder for actual verification
        if (!simulatedZKPSuccess) {
            revert("Simulated ZKProof failure.");
        }

        updateFragmentConditionStatus(tokenId, conditionId, true); // Update status if proof passes
        emit ZKProofSubmitted(tokenId, conditionId);
    }

    // --- Time-Based Yield & Staking ---

    /**
     * @notice Allows owners of Active fragments to claim time-based yield.
     * @dev Yield accrues based on the duration the fragment has been Active and conditions met.
     *      Yield calculation can be complex (e.g., based on collateral, time, protocol fees).
     * @param tokenId The ID of the ChronoFragment.
     */
    function claimTimeYield(uint256 tokenId) external onlyFragmentOwner(tokenId) whenNotPaused {
        ChronoFragment storage fragment = chronoFragments[tokenId];
        _checkFragmentStatusAndAdvance(tokenId); // Ensure phase is up-to-date

        if (fragment.currentPhase != Phase.Active && fragment.currentPhase != Phase.Matured) {
            revert InvalidPhase(tokenId, Phase.Active, fragment.currentPhase);
        }

        // Calculate accrued yield since last check/claim
        // Example simple yield calculation: 0.01% of collateral per day conditions met
        uint256 yieldableDuration = block.timestamp - fragment.lastYieldClaimTime;
        if (yieldableDuration < 1 hours) { // Minimum 1 hour to claim yield
            revert NotEnoughTimeElapsed();
        }

        // Example calculation: (collateral * rate * duration_in_seconds) / (seconds_in_year)
        // This is a highly simplified example. Real systems might use a dynamic rate,
        // a dedicated rewards token, or distribute a share of protocol fees.
        uint256 dailyYieldRate = 1; // 0.0001% per second for example (very small)
        uint256 yieldAmount = (fragment.collateralAmount * dailyYieldRate * yieldableDuration) / (1e10); // Adjust denominator for proper scaling

        if (yieldAmount == 0) {
            revert NoYieldToClaim(tokenId);
        }

        // Deduct from protocol fees or a separate rewards pool
        // For simplicity, let's assume yield comes from an external source or pre-deposited funds.
        // In a full protocol, this could involve swapping accumulated fees for the collateral token
        // or distributing a dedicated rewards token.
        // For this example, we'll just track it as "claimed" and assume an external mechanism delivers it.
        // Or, if the collateral asset is also the yield asset:
        // require(IERC20(fragment.collateralAsset).transfer(_msgSender(), yieldAmount), "Yield transfer failed");

        fragment.cumulativeYieldClaimed += yieldAmount;
        fragment.lastYieldClaimTime = block.timestamp;

        emit TimeYieldClaimed(tokenId, _msgSender(), yieldAmount);
    }

    /**
     * @notice Allows a fragment owner to stake their ChronoFragment for a given duration.
     * @dev Staking can grant additional yield, governance power, or other benefits.
     * @param tokenId The ID of the ChronoFragment to stake.
     * @param duration The duration in seconds for which to stake the fragment.
     */
    function stakeChronoFragment(uint256 tokenId, uint256 duration) external onlyFragmentOwner(tokenId) whenNotPaused {
        ChronoFragment storage fragment = chronoFragments[tokenId];

        if (fragment.isStaked) {
            revert FragmentAlreadyStaked(tokenId);
        }
        if (fragment.currentPhase != Phase.Active && fragment.currentPhase != Phase.Matured) {
            revert InvalidPhase(tokenId, Phase.Active, fragment.currentPhase);
        }
        if (duration == 0) {
            revert("Staking duration must be greater than zero.");
        }

        fragment.isStaked = true;
        fragment.stakingEndTime = block.timestamp + duration;
        fragment.stakingDelegator = _msgSender(); // For delegated voting if applicable
        totalStakedFragments++;

        // Additional benefits like boosted yield or governance power would be implemented here
        // or in related functions.

        emit FragmentStaked(tokenId, _msgSender());
    }

    /**
     * @notice Allows a fragment owner to unstake their ChronoFragment after its staking period ends.
     * @param tokenId The ID of the ChronoFragment to unstake.
     */
    function unstakeChronoFragment(uint256 tokenId) external onlyFragmentOwner(tokenId) whenNotPaused {
        ChronoFragment storage fragment = chronoFragments[tokenId];

        if (!fragment.isStaked) {
            revert FragmentNotStaked(tokenId);
        }
        if (block.timestamp < fragment.stakingEndTime) {
            revert StakingPeriodNotEnded(tokenId, fragment.stakingEndTime);
        }

        fragment.isStaked = false;
        fragment.stakingEndTime = 0;
        fragment.stakingDelegator = address(0);
        totalStakedFragments--;

        emit FragmentUnstaked(tokenId, _msgSender());
    }

    // --- Protocol Governance & Treasury ---

    /**
     * @notice Allows eligible users (e.g., those with sufficient staked fragments) to propose a change.
     * @param _paramHash A unique identifier for the parameter being changed (e.g., hash of new value).
     * @param _description A detailed description of the proposal.
     */
    function proposeParameterChange(bytes32 _paramHash, string calldata _description) external whenNotPaused {
        // Simple check: user must own at least `minStakedFragmentsForProposal`
        // In a real DAO, this would integrate with a voting power calculation (e.g., based on staked tokens/NFTs).
        uint256 userStakedCount = 0;
        // This is inefficient for many NFTs. A separate token or a more complex governance token would be better.
        // For demonstration, let's assume a simplified check.
        // for (uint256 i = 1; i < _nextTokenId; i++) {
        //     if (chronoFragments[i].currentOwner == _msgSender() && chronoFragments[i].isStaked) {
        //         userStakedCount++;
        //     }
        // }
        // if (userStakedCount < minStakedFragmentsForProposal) {
        //     revert InsufficientVotingPower();
        // }
        // Simplified check: Does the sender own ANY staked fragment? (needs proper loop for count)
        bool hasEnoughPower = false;
        for (uint256 i = 1; i < _nextTokenId; i++) { // Iterate all possible fragment IDs
            if (ownerOf(i) == _msgSender() && chronoFragments[i].isStaked) {
                hasEnoughPower = true;
                break;
            }
        }
        if (!hasEnoughPower) revert InsufficientVotingPower();


        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            paramHash: _paramHash,
            description: _description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit ParameterChangeProposed(proposalId, _paramHash, _description);
    }

    /**
     * @notice Allows eligible voters to cast votes on active proposals.
     * @dev Voting power is determined by the number of staked ChronoFragments.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.voteStartTime == 0) { // Check if proposal exists
            revert ProposalNotFound(proposalId);
        }
        if (block.timestamp < proposal.voteStartTime || block.timestamp > proposal.voteEndTime) {
            revert VotingPeriodEnded(proposalId);
        }
        if (proposal.executed) {
            revert("Proposal already executed.");
        }
        if (proposal.hasVoted[_msgSender()]) {
            revert AlreadyVoted(proposalId);
        }

        // Determine voting power (e.g., number of currently staked fragments owned by _msgSender())
        uint256 voterPower = 0;
        for (uint256 i = 1; i < _nextTokenId; i++) { // Inefficient for large _nextTokenId. Use a dedicated governance token.
            if (ownerOf(i) == _msgSender() && chronoFragments[i].isStaked) {
                voterPower++;
            }
        }
        if (voterPower == 0) {
            revert InsufficientVotingPower();
        }

        if (support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit VoteCast(proposalId, _msgSender(), support);
    }

    /**
     * @notice Allows anyone to execute a proposal once the voting period has ended and it passed.
     * @dev This is a placeholder for actual parameter change logic.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.voteStartTime == 0) {
            revert ProposalNotFound(proposalId);
        }
        if (block.timestamp < proposal.voteEndTime) {
            revert VotingPeriodActive(proposalId);
        }
        if (proposal.executed) {
            revert("Proposal already executed.");
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        if (totalVotes == 0) { // No votes cast
            revert QuorumNotReached(proposalId);
        }

        uint256 currentQuorum = (totalVotes * 10000) / totalStakedFragments;
        if (currentQuorum < proposalQuorumBPS) {
            revert QuorumNotReached(proposalId);
        }

        uint256 currentThreshold = (proposal.votesFor * 10000) / totalVotes;
        if (currentThreshold < proposalThresholdBPS) {
            revert ThresholdNotMet(proposalId);
        }

        // --- EXECUTE THE CHANGE ---
        // This is the critical part where the actual protocol parameter would be updated.
        // It's highly specific to what `paramHash` represents.
        // Example:
        // if (proposal.paramHash == keccak256(abi.encodePacked("newFeeRate", value))) {
        //     protocolFeeRateBPS = value;
        // } else if (...) { ... }
        // For this generic example, we just mark it as executed.

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }


    /**
     * @notice Allows the owner/DAO to set the protocol fee rate.
     * @param _newRateBPS New fee rate in basis points (e.g., 100 for 1%).
     */
    function setProtocolFeeRate(uint256 _newRateBPS) external onlyOwner {
        protocolFeeRateBPS = _newRateBPS;
        emit ProtocolFeeRateSet(_newRateBPS);
    }

    /**
     * @notice Allows the protocol treasury to collect accumulated fees.
     * @dev This assumes fees are in ETH, or a single token. If multiple tokens are used as collateral,
     *      this would need to be `collectProtocolFees(address tokenAddress)`.
     */
    function collectProtocolFees() external onlyOwner {
        // In a real scenario, fees could be held in specific ERC20s or ETH.
        // This simplified version just collects 'totalProtocolFeesCollected' which needs to be populated.
        // For actual collection, it needs to iterate through fees per asset type, or only collect in ETH.
        // Example if ETH fees were collected:
        // (bool success,) = protocolFeeTreasury.call{value: address(this).balance}("");
        // require(success, "ETH transfer failed");

        // If fees are taken in the collateral token directly:
        // IERC20(someFeeToken).transfer(protocolFeeTreasury, totalProtocolFeesCollected);
        // totalProtocolFeesCollected = 0; // Reset after collection

        emit ProtocolFeesCollected(protocolFeeTreasury, 0); // Placeholder for actual amount
    }

    /**
     * @notice Allows the owner/DAO to pause critical functions in an emergency.
     */
    function emergencyPause() external onlyOwner {
        paused = true;
    }

    /**
     * @notice Allows the owner/DAO to unpause critical functions.
     */
    function emergencyUnpause() external onlyOwner {
        paused = false;
    }

    // --- View/Helper Functions ---

    /**
     * @notice Returns all details of a specific ChronoFragment.
     * @param tokenId The ID of the ChronoFragment.
     * @return A tuple containing all fragment properties.
     */
    function getFragmentDetails(uint256 tokenId)
        public
        view
        returns (
            uint256 id,
            address sculptor,
            address currentOwner,
            address collateralAsset,
            uint256 collateralAmount,
            uint256 startTime,
            uint256 endTime,
            Phase currentPhase,
            uint256 lastConditionCheckTime,
            uint256 cumulativeYieldClaimed,
            uint256 lastYieldClaimTime,
            bytes32[] memory activeConditionIds,
            bool isStaked,
            uint256 stakingEndTime,
            address stakingDelegator
        )
    {
        ChronoFragment storage fragment = chronoFragments[tokenId];
        require(fragment.id != 0, "Fragment does not exist."); // Check if fragment exists

        return (
            fragment.id,
            fragment.sculptor,
            fragment.currentOwner,
            fragment.collateralAsset,
            fragment.collateralAmount,
            fragment.startTime,
            fragment.endTime,
            fragment.currentPhase,
            fragment.lastConditionCheckTime,
            fragment.cumulativeYieldClaimed,
            fragment.lastYieldClaimTime,
            fragment.activeConditionIds,
            fragment.isStaked,
            fragment.stakingEndTime,
            fragment.stakingDelegator
        );
    }

    /**
     * @notice Returns the current status of a specific condition for a fragment.
     * @param tokenId The ID of the ChronoFragment.
     * @param conditionId The ID of the condition.
     * @return True if the condition is currently met, false otherwise.
     */
    function getFragmentConditionStatus(uint256 tokenId, bytes32 conditionId) public view returns (bool) {
        return chronoFragments[tokenId].conditionsMetStatus[conditionId];
    }

    /**
     * @notice Returns details of a registered condition definition.
     * @param conditionId The ID of the condition.
     * @return A tuple containing condition type, associated address, and enabled status.
     */
    function getConditionDefinition(bytes32 conditionId)
        public
        view
        returns (ConditionType cType, address associatedAddress, bool isEnabled)
    {
        ConditionDefinition storage def = conditionDefinitions[conditionId];
        return (def.cType, def.associatedAddress, def.isEnabled);
    }

    /**
     * @notice Checks if an address is registered as an oracle for a specific condition.
     * @param _oracleAddress The address to check.
     * @param _conditionId The ID of the condition.
     * @return True if registered, false otherwise.
     */
    function isOracleRegistered(address _oracleAddress, bytes32 _conditionId) public view returns (bool) {
        return registeredOracles[_conditionId][_oracleAddress];
    }

    /**
     * @notice Returns the total number of ChronoFragments that are currently staked.
     */
    function getTotalStakedFragments() external view returns (uint256) {
        return totalStakedFragments;
    }

    // --- ERC721 Overrides ---
    function _approve(address to, uint256 tokenId) internal override {
        // Update currentOwner mapping when approving
        ChronoFragment storage fragment = chronoFragments[tokenId];
        fragment.currentOwner = to; // Or handle this in transferFrom
        super._approve(to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override {
        // Update currentOwner mapping when transferring
        ChronoFragment storage fragment = chronoFragments[tokenId];
        require(fragment.currentOwner == from, "ChronoSculptor: transfer from incorrect owner");
        fragment.currentOwner = to;
        super._transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Ensure fragment is not staked when transferring (or allow and handle logic)
        if (chronoFragments[tokenId].isStaked) {
            revert FragmentAlreadyStaked(tokenId); // Cannot transfer while staked
        }
    }

    /**
     * @dev Generates a dynamic token URI based on the ChronoFragment's current state.
     * In a real DApp, this would point to an API endpoint that serves
     * JSON metadata, potentially with an image/animation that changes
     * based on `currentPhase` and `conditionsMetStatus`.
     */
    function _generateTokenURI(uint256 tokenId) internal view returns (string memory) {
        ChronoFragment storage fragment = chronoFragments[tokenId];
        string memory phase;
        if (fragment.currentPhase == Phase.Uninitialized) phase = "uninitialized";
        else if (fragment.currentPhase == Phase.PendingActivation) phase = "pending_activation";
        else if (fragment.currentPhase == Phase.Active) phase = "active";
        else if (fragment.currentPhase == Phase.Matured) phase = "matured";
        else if (fragment.currentPhase == Phase.Forfeited) phase = "forfeited";
        else if (fragment.currentPhase == Phase.Redeemed) phase = "redeemed";
        else phase = "unknown";

        string memory baseURI = "https://chronosculptor.io/api/metadata/"; // Replace with your actual API endpoint
        string memory finalURI = string(abi.encodePacked(
            baseURI,
            tokenId.toString(),
            "?",
            "phase=",
            phase,
            "&",
            "conditions=",
            _getConditionsString(tokenId) // Helper to build conditions part
        ));
        return finalURI;
    }

    function _getConditionsString(uint256 tokenId) internal view returns (string memory) {
        ChronoFragment storage fragment = chronoFragments[tokenId];
        string memory conditionsStr = "";
        for (uint256 i = 0; i < fragment.activeConditionIds.length; i++) {
            bytes32 condId = fragment.activeConditionIds[i];
            bool status = fragment.conditionsMetStatus[condId];
            conditionsStr = string(abi.encodePacked(
                conditionsStr,
                "cond_",
                Strings.toHexString(uint256(condId), 32),
                "=",
                status ? "true" : "false",
                (i == fragment.activeConditionIds.length - 1 ? "" : "&")
            ));
        }
        return conditionsStr;
    }
}
```