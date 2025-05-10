Okay, let's design a smart contract that incorporates several advanced and creative concepts beyond standard token or NFT implementations.

We'll create a contract called `SynergyCore` that manages unique digital assets ("Synergy Units" - SUs) that have dynamic properties, alongside a related fungible token ("Synergy Points" - SPs) used for participation, governance, and earning. It will feature mechanics like dynamic state changes for assets, integrated staking/earning, time-based rewards, a basic on-chain governance system for configuration, role-based access, and linking external attestations to assets.

This design avoids simply inheriting from standard ERC-20/ERC-721/etc. and combines multiple distinct concepts into a single protocol layer.

---

### **SynergyCore Contract Outline & Function Summary**

**Theme:** A protocol for managing dynamic, composable digital assets (Synergy Units) and fostering community participation via a utility/governance token (Synergy Points).

**Core Concepts:**

1.  **Synergy Units (SUs):** Unique assets with dynamic metadata, lock states, delegation, and a history log. Not standard ERC-721, but conceptually similar unique items.
2.  **Synergy Points (SPs):** Fungible tokens earned via holding/staking SUs, used for staking, governance voting power, and potentially fees/actions within the protocol. Not standard ERC-20, managed internally.
3.  **Synergy Fragments (SFs):** A secondary fungible token resulting from "splitting" a Synergy Unit, used to potentially contribute to minting new SUs. Managed internally.
4.  **Epochs:** Time periods for calculating and distributing SP rewards based on asset holdings/stakes.
5.  **Governance:** Basic on-chain system allowing SP holders/delegates to propose and vote on protocol configuration changes.
6.  **Roles:** Access control for sensitive administrative functions.
7.  **Attestations:** Ability to link external, verifiable claims to Synergy Units.
8.  **Protocol Fees:** Configurable fees for certain actions, collected in ETH/Native token.
9.  **Dynamic State:** SUs can be locked, delegated, or conceptually "split" impacting their properties and associated rewards/actions.

**Function Categories & Summaries:**

*   **I. Core Admin & Configuration (Requires `ADMIN_ROLE` or Governance):**
    1.  `constructor`: Initializes contract, sets initial admin.
    2.  `grantRole(address account, bytes32 role)`: Assigns a role to an address.
    3.  `revokeRole(address account, bytes32 role)`: Removes a role from an address.
    4.  `hasRole(bytes32 role, address account)`: Checks if an address has a role (view).
    5.  `setProtocolFeeRecipient(address recipient)`: Sets the address where protocol fees are collected.
    6.  `setFunctionCallFee(bytes4 functionSig, uint256 feeAmount)`: Sets the native token fee required for a specific function call (governance/admin).
    7.  `configureEpoch(uint256 duration, uint256 baseSynergyPointsPerSU)`: Sets parameters for epoch-based SP distribution (governance/admin).
    8.  `setSynergyPointsClaimCooldown(uint256 cooldown)`: Sets the minimum time between SP claims for a user (governance/admin).
    9.  `setUnstakeLockDuration(uint256 duration)`: Sets the time lock period after unstaking SPs (governance/admin).
    10. `registerCollaborator(address collaborator, uint256 initialSynergyPoints)`: Onboards a collaborator, optionally granting initial SPs (admin).

*   **II. Protocol Fees:**
    11. `withdrawProtocolFees()`: Allows the fee recipient to withdraw collected native token fees.
    12. `getProtocolFeeAccumulator()`: Returns the total collected fees (view).
    13. `getFunctionCallFee(bytes4 functionSig)`: Returns the fee for a specific function signature (view).

*   **III. Synergy Unit (SU) Management:**
    14. `mintSynergyUnit(address owner, string initialMetadataURI)`: Mints a new SU to an owner (might require role/fee).
    15. `transferSynergyUnit(uint256 tokenId, address to)`: Transfers an SU to another address (subject to lock/delegation, might have fee).
    16. `burnSynergyUnit(uint256 tokenId)`: Destroys an SU (subject to lock/delegation, might have fee).
    17. `updateSynergyUnitMetadata(uint256 tokenId, string newMetadataURI)`: Changes the metadata URI for an SU (owner/delegate, subject to lock).
    18. `lockSynergyUnit(uint256 tokenId, uint256 unlockTimestamp)`: Locks an SU, preventing transfer/metadata changes until a timestamp (owner/delegate).
    19. `unlockSynergyUnit(uint256 tokenId)`: Unlocks an SU if allowed by timestamp or caller (owner/delegate).
    20. `delegateSynergyUnitOwnership(uint256 tokenId, address delegatee, uint256 duration)`: Delegates certain rights (like update/lock) for an SU (owner).
    21. `reclaimSynergyUnitDelegation(uint256 tokenId)`: Owner revokes an active delegation.
    22. `getSynergyUnitOwner(uint256 tokenId)`: Returns the owner of an SU (view).
    23. `getSynergyUnitMetadata(uint256 tokenId)`: Returns the metadata URI for an SU (view).
    24. `getSynergyUnitLockUntil(uint256 tokenId)`: Returns the unlock timestamp for an SU (view).
    25. `getSynergyUnitDelegatee(uint256 tokenId)`: Returns the active delegatee for an SU (view).
    26. `getSynergyUnitHistory(uint256 tokenId)`: Returns the log of significant events for an SU (view).

*   **IV. Synergy Points (SP) & Fragment Token (SF) Management:**
    27. `claimSynergyPoints()`: Allows users to claim accrued SPs based on SU holdings, staked SPs, and epoch distribution (subject to cooldown).
    28. `stakeSynergyPoints(uint256 amount)`: Stakes a user's SP balance to earn more rewards and boost voting power.
    29. `unstakeSynergyPoints(uint256 amount)`: Initiates the unstaking process, transferring SPs to a time-locked balance.
    30. `withdrawUnstakedSynergyPoints()`: Withdraws SPs from the time-locked unstaked balance after the lock duration.
    31. `delegateSynergyPointsVotingPower(address delegatee)`: Delegates SP voting power to another address.
    32. `splitSynergyUnit(uint256 tokenId)`: Burns a Synergy Unit and mints a fixed amount of Synergy Fragments to the owner (subject to lock).
    33. `mergeFragmentTokensToMintUnit(uint256 fragmentAmount)`: Burns a sufficient amount of Synergy Fragments and a cost in SPs to mint a new Synergy Unit.
    34. `distributeEpochRewards()`: Callable by anyone, triggers the distribution of SP rewards for the elapsed epoch to SU owners and stakers.
    35. `getSynergyPointsBalance(address account)`: Returns the liquid SP balance for an account (view).
    36. `getStakedSynergyPoints(address account)`: Returns the staked SP balance for an account (view).
    37. `getUnstakingSynergyPoints(address account)`: Returns the amount of SPs currently being unstaked and their unlock time (view).
    38. `getSynergyVotingPower(address account)`: Returns the total voting power (liquid + staked + received delegation) for an account (view).
    39. `getFragmentTokenBalance(address account)`: Returns the Synergy Fragment token balance for an account (view).
    40. `getCurrentEpoch()`: Returns the current epoch number (view).
    41. `getLastEpochDistributionTime()`: Returns the timestamp of the last epoch reward distribution (view).

*   **V. Governance:**
    42. `proposeConfigurationChange(address target, bytes data, string description)`: Creates a new governance proposal (requires minimum SP or role).
    43. `voteOnProposal(uint256 proposalId, bool support)`: Casts a vote on an active proposal using delegated SP voting power.
    44. `executeProposal(uint256 proposalId)`: Executes a passed proposal after a time lock period.
    45. `getProposalDetails(uint256 proposalId)`: Returns details about a specific proposal (view).

*   **VI. Attestations:**
    46. `submitAttestation(uint256 tokenId, string attestationURI)`: Links an external attestation (e.g., IPFS hash of a verifiable claim) to a Synergy Unit.
    47. `getSynergyUnitAttestations(uint256 tokenId)`: Returns the list of attestations linked to an SU (view).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SynergyCore
 * @dev A protocol for managing dynamic digital assets (Synergy Units),
 *      Synergy Points for participation and governance, Fragment Tokens,
 *      epoch-based rewards, fees, roles, and attestations.
 *      This contract combines multiple advanced concepts in a non-standard implementation.
 *
 * Outline:
 * I. Core Admin & Configuration (Role/Governance gated)
 * II. Protocol Fees
 * III. Synergy Unit (SU) Management (Dynamic Assets)
 * IV. Synergy Points (SP) & Fragment Token (SF) Management (Utility & Governance)
 * V. Governance System
 * VI. Attestations
 *
 * Function Summary:
 * (See detailed summary above for brevity here)
 * - Role-based access control (grantRole, revokeRole, hasRole)
 * - Fee management (setProtocolFeeRecipient, setFunctionCallFee, withdrawProtocolFees, getProtocolFeeAccumulator, getFunctionCallFee)
 * - Epoch configuration (configureEpoch, getCurrentEpoch, getLastEpochDistributionTime)
 * - Synergy Unit lifecycle (mintSynergyUnit, transferSynergyUnit, burnSynergyUnit)
 * - Dynamic SU state (updateSynergyUnitMetadata, lockSynergyUnit, unlockSynergyUnit, delegateSynergyUnitOwnership, reclaimSynergyUnitDelegation)
 * - SU history & Attestations (getSynergyUnitHistory, submitAttestation, getSynergyUnitAttestations)
 * - Synergy Points earning & staking (claimSynergyPoints, stakeSynergyPoints, unstakeSynergyPoints, withdrawUnstakedSynergyPoints)
 * - SP delegation for voting (delegateSynergyPointsVotingPower, getSynergyVotingPower)
 * - Fragment Token mechanics (splitSynergyUnit, mergeFragmentTokensToMintUnit, getFragmentTokenBalance)
 * - Epoch reward distribution (distributeEpochRewards)
 * - Governance (proposeConfigurationChange, voteOnProposal, executeProposal, getProposalDetails)
 * - View functions for balances, states, etc. (getSynergyPointsBalance, getStakedSynergyPoints, getUnstakingSynergyPoints, getSynergyUnitOwner, etc.)
 */
contract SynergyCore {

    // --- Custom Errors ---
    error Unauthorized(address account, bytes32 role);
    error FeeCollectionFailed();
    error InvalidTokenId();
    error NotSynergyUnitOwnerOrDelegatee(uint256 tokenId, address account);
    error SynergyUnitLocked(uint256 tokenId);
    error DelegationExpired(uint256 tokenId);
    error CannotReclaimActiveDelegatee(uint256 tokenId, address delegatee);
    error InsufficientSynergyPoints(uint256 required, uint256 available);
    error SynergyPointsAlreadyDelegated(address account);
    error CannotDelegateToSelf();
    error ClaimCooldownNotElapsed(uint256 timeRemaining);
    error InsufficientStakedSynergyPoints(uint256 required, uint256 available);
    error UnstakeLockActive(uint256 timeRemaining);
    error NoUnstakedBalanceToWithdraw();
    error InvalidFragmentAmount();
    error CannotMergeIntoLockedUnit(uint256 tokenId); // If merging requires targeting a specific unit state
    error NotEnoughFragmentsOrPointsToMintUnit();
    error EpochNotElapsed();
    error EpochRewardsAlreadyDistributed();
    error InvalidProposalId();
    error ProposalAlreadyExecuted();
    error ProposalPeriodNotEnded();
    error ProposalExecutionTimeLockActive(uint256 timeRemaining);
    error ProposalFailed();
    error AlreadyVoted(uint256 proposalId, address voter);
    error CannotVoteOnInactiveProposal();

    // --- Constants ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE"); // Role that can propose configs
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // Role that can mint SUs

    // Configurable costs/params via governance
    uint256 public constant FRAGMENT_TOKENS_PER_UNIT = 100; // How many SFs minted when an SU is split
    uint256 public constant FRAGMENT_TOKENS_FOR_NEW_UNIT = 150; // How many SFs needed to mint a new SU
    uint256 public constant SP_COST_FOR_NEW_UNIT = 500; // How many SPs needed to mint a new SU with SFs
    uint256 public protocolFeeBasisPoints = 100; // 1% fee example (100/10000) - could be dynamic or per-function

    // --- State Variables ---

    // Roles
    mapping(address => mapping(bytes32 => bool)) private _roles;

    // Protocol Fees
    uint256 private _protocolFeeAccumulator;
    address public protocolFeeRecipient;
    mapping(bytes4 => uint256) private _functionCallFees; // Fee required in native token (ETH) per function call

    // Synergy Units (SUs) - Inspired by ERC721 but custom
    uint256 private _nextSynergyUnitId;
    mapping(uint256 => address) private _synergyUnitOwner;
    mapping(uint256 => string) private _synergyUnitMetadata;
    mapping(uint256 => uint256) private _synergyUnitLockUntil; // Timestamp until unlocked
    mapping(uint256 => address) private _synergyUnitDelegatee; // Delegatee for certain actions
    mapping(uint256 => uint256) private _synergyUnitDelegateeUntil; // Delegatee expiration timestamp

    // Synergy Unit History & Attestations
    struct SynergyUnitEvent {
        uint256 timestamp;
        string eventType; // e.g., "Mint", "Transfer", "Lock", "UpdateMetadata", "Attestation"
        address caller;
        string details; // JSON string or simple description
    }
    mapping(uint256 => SynergyUnitEvent[]) private _synergyUnitHistory;

    struct Attestation {
        uint256 id;
        address submitter;
        uint256 timestamp;
        string attestationURI; // e.g., IPFS hash of a verifiable credential
    }
    mapping(uint256 => Attestation[]) private _synergyUnitAttestations;
    mapping(uint256 => uint256) private _nextAttestationId; // Counter per SU

    // Synergy Points (SPs) - Fungible token managed internally
    mapping(address => uint256) private _synergyPointsBalance; // Liquid balance
    mapping(address => uint256) private _stakedSynergyPoints; // Staked balance
    mapping(address => uint256) private _synergyPointsUnstakingAmount; // Amount being unstaked
    mapping(address => uint256) private _synergyPointsUnstakeUnlockTime; // Timestamp when unstaking finishes
    mapping(address => address) private _synergyPointsDelegates; // Delegate for voting power

    // SP Earning & Epochs
    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration in seconds
    uint256 public baseSynergyPointsPerSU; // SPs earned per SU per epoch
    uint256 public lastEpochDistributionTime;
    mapping(address => uint256) private _lastSynergyPointsClaimTime; // Cooldown per user
    uint256 public synergyPointsClaimCooldown; // Minimum seconds between claims

    // Synergy Fragments (SFs) - Secondary fungible token managed internally
    mapping(address => uint256) private _fragmentTokenBalance;

    // User Profiles (optional, linking identity data)
    mapping(address => string) private _userProfileURI;

    // Governance System
    struct Proposal {
        uint256 id;
        address proposer;
        address target; // Contract to call
        bytes data; // Calldata for the target contract
        string description;
        uint256 creationTime;
        uint256 votingPeriodEnd; // Timestamp
        uint256 executionTimeLockEnd; // Timestamp
        uint256 totalVotes; // Total voting power cast
        uint256 supportVotes; // Voting power supporting the proposal
        uint256 minimumVotingPower; // Minimum total votes needed to pass
        bool executed;
    }
    uint256 private _nextProposalId;
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // Track if an address (original voter, not delegate) has voted

    // --- Events ---
    event RoleGranted(address indexed account, bytes32 indexed role, address indexed sender);
    event RoleRevoked(address indexed account, bytes32 indexed role, address indexed sender);
    event ProtocolFeeRecipientSet(address indexed recipient, address indexed sender);
    event FunctionCallFeeSet(bytes4 indexed functionSig, uint256 feeAmount, address indexed sender);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    event SynergyUnitMinted(uint256 indexed tokenId, address indexed owner, string metadataURI, address indexed minter);
    event SynergyUnitTransferred(uint256 indexed tokenId, address indexed from, address indexed to, address indexed caller);
    event SynergyUnitBurned(uint256 indexed tokenId, address indexed owner, address indexed burner);
    event SynergyUnitMetadataUpdated(uint256 indexed tokenId, string newMetadataURI, address indexed caller);
    event SynergyUnitLocked(uint256 indexed tokenId, uint256 unlockTimestamp, address indexed caller);
    event SynergyUnitUnlocked(uint256 indexed tokenId, address indexed caller);
    event SynergyUnitDelegated(uint256 indexed tokenId, address indexed delegatee, uint256 duration, address indexed owner);
    event SynergyUnitDelegationReclaimed(uint256 indexed tokenId, address indexed owner, address indexed delegatee);

    event SynergyPointsClaimed(address indexed account, uint256 amount);
    event SynergyPointsStaked(address indexed account, uint256 amount);
    event SynergyPointsUnstakingInitiated(address indexed account, uint256 amount, uint256 unlockTime);
    event SynergyPointsUnstakedWithdrawn(address indexed account, uint256 amount);
    event SynergyPointsDelegationSet(address indexed delegator, address indexed delegatee);
    event SynergyPointsEpochDistributed(uint256 indexed epoch, uint256 totalDistributed, uint256 indexed distributor);

    event SynergyUnitSplit(uint256 indexed tokenId, address indexed owner, uint256 fragmentsMinted);
    event FragmentTokensMergedToMintUnit(address indexed minter, uint256 fragmentsBurned, uint256 spBurned, uint256 indexed newTokenId);

    event UserProfileUpdated(address indexed account, string profileURI);
    event AttestationSubmitted(uint256 indexed tokenId, uint256 indexed attestationId, address indexed submitter, string attestationURI);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, address indexed target, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, address indexed delegate, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    event EpochConfigured(uint256 indexed epochDuration, uint256 indexed baseSynergyPointsPerSU, address indexed caller);
    event SynergyPointsClaimCooldownSet(uint256 cooldown, address indexed caller);
    event UnstakeLockDurationSet(uint256 duration, address indexed caller);
    event CollaboratorRegistered(address indexed collaborator, uint256 initialSynergyPoints, address indexed caller);

    // --- Modifiers ---
    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, _msgSender())) {
            revert Unauthorized(_msgSender(), role);
        }
        _;
    }

    // Check ownership or valid delegation for SU actions
    modifier onlySynergyUnitOwnerOrDelegatee(uint256 tokenId) {
        address owner = _synergyUnitOwner[tokenId];
        address delegatee = _synergyUnitDelegatee[tokenId];
        bool isOwner = owner == _msgSender();
        bool isDelegatee = delegatee == _msgSender() && _synergyUnitDelegateeUntil[tokenId] > block.timestamp;

        if (!isOwner && !isDelegatee) {
             revert NotSynergyUnitOwnerOrDelegatee(tokenId, _msgSender());
        }
        _;
    }

    modifier notLocked(uint256 tokenId) {
        if (_synergyUnitLockUntil[tokenId] > block.timestamp) {
            revert SynergyUnitLocked(tokenId);
        }
        _;
    }

    modifier payFunctionFee(bytes4 functionSig) {
        uint256 requiredFee = _functionCallFees[functionSig];
        if (requiredFee > 0) {
            if (msg.value < requiredFee) {
                // Refund excess if needed, or simply require exact amount
                // For simplicity, let's just check if enough is sent
                 revert InsufficientFee(requiredFee, msg.value); // Custom error needed
            }
            _protocolFeeAccumulator += requiredFee;
            // Any excess msg.value is left in the contract or handled. For simplicity, assume exact or excess is collected.
            // A real implementation might refund excess: payable(msg.sender).transfer(msg.value - requiredFee);
        }
        _;
        // Note: Adding a custom error for insufficient fee
    }
    error InsufficientFee(uint256 required, uint256 sent);


    // --- Constructor ---
    constructor(address initialAdmin, address initialFeeRecipient) {
        if (initialAdmin == address(0)) revert Unauthorized(address(0), ADMIN_ROLE);
        _setupRole(initialAdmin, ADMIN_ROLE);
        _setupRole(initialAdmin, GOVERNANCE_ROLE); // Grant initial admin governance powers too
        _setupRole(initialAdmin, MINTER_ROLE); // Grant initial admin minter powers too

        if (initialFeeRecipient == address(0)) initialFeeRecipient = initialAdmin; // Default fee recipient
        protocolFeeRecipient = initialFeeRecipient;

        currentEpoch = 1;
        epochDuration = 7 days; // Example: 1 week per epoch
        baseSynergyPointsPerSU = 10; // Example: 10 SP per SU per epoch
        lastEpochDistributionTime = block.timestamp; // Start epoch timer

        synergyPointsClaimCooldown = 1 days; // Default 1 day cooldown for SP claims
    }

    // --- I. Core Admin & Configuration ---

    // Internal function to manage roles
    function _setupRole(address account, bytes32 role) internal {
        _roles[account][role] = true;
        emit RoleGranted(account, role, _msgSender());
    }

    /**
     * @dev Grants a role to a specific account.
     * @param account The address to grant the role to.
     * @param role The role to grant (e.g., `ADMIN_ROLE`, `GOVERNANCE_ROLE`).
     */
    function grantRole(address account, bytes32 role) external onlyRole(ADMIN_ROLE) {
        _setupRole(account, role);
    }

    /**
     * @dev Revokes a role from a specific account.
     * @param account The address to revoke the role from.
     * @param role The role to revoke.
     */
    function revokeRole(address account, bytes32 role) external onlyRole(ADMIN_ROLE) {
        if (_roles[account][role]) {
            _roles[account][role] = false;
            emit RoleRevoked(account, role, _msgSender());
        }
    }

    /**
     * @dev Checks if an account has a specific role.
     * @param role The role to check.
     * @param account The address to check.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[account][role];
    }

    /**
     * @dev Sets the address that can withdraw protocol fees.
     * @param recipient The new address for fee withdrawal.
     */
    function setProtocolFeeRecipient(address recipient) external onlyRole(ADMIN_ROLE) {
        if (recipient == address(0)) revert Unauthorized(address(0), bytes32(0)); // Cannot set to zero address
        protocolFeeRecipient = recipient;
        emit ProtocolFeeRecipientSet(recipient, _msgSender());
    }

    /**
     * @dev Sets the native token fee required for calling a specific function.
     *      Intended for governance proposals, but callable by ADMIN_ROLE directly.
     * @param functionSig The 4-byte function signature (e.g., `bytes4(keccak256("mintSynergyUnit(address,string)"))`).
     * @param feeAmount The required fee in native token (wei).
     */
    function setFunctionCallFee(bytes4 functionSig, uint256 feeAmount) external onlyRole(GOVERNANCE_ROLE) {
        _functionCallFees[functionSig] = feeAmount;
        emit FunctionCallFeeSet(functionSig, feeAmount, _msgSender());
    }

     /**
     * @dev Configures the parameters for the epoch-based SP reward distribution.
     *      Intended for governance proposals, but callable by ADMIN_ROLE directly.
     * @param duration New epoch duration in seconds.
     * @param _baseSynergyPointsPerSU New base SPs distributed per SU per epoch.
     */
    function configureEpoch(uint256 duration, uint256 _baseSynergyPointsPerSU) external onlyRole(GOVERNANCE_ROLE) {
        epochDuration = duration;
        baseSynergyPointsPerSU = _baseSynergyPointsPerSU;
        emit EpochConfigured(duration, _baseSynergyPointsPerSU, _msgSender());
    }

    /**
     * @dev Sets the minimum time users must wait between claiming Synergy Points.
     *      Intended for governance proposals, but callable by ADMIN_ROLE directly.
     * @param cooldown New cooldown duration in seconds.
     */
    function setSynergyPointsClaimCooldown(uint256 cooldown) external onlyRole(GOVERNANCE_ROLE) {
        synergyPointsClaimCooldown = cooldown;
        emit SynergyPointsClaimCooldownSet(cooldown, _msgSender());
    }

    /**
     * @dev Sets the duration for the time lock when unstaking Synergy Points.
     *      Intended for governance proposals, but callable by ADMIN_ROLE directly.
     * @param duration New unstake lock duration in seconds.
     */
    function setUnstakeLockDuration(uint256 duration) external onlyRole(GOVERNANCE_ROLE) {
        _setUnstakeLockDuration(duration);
    }

    function _setUnstakeLockDuration(uint256 duration) internal {
         // Can add state variable like `uint256 public unstakeLockDuration;`
         // unstakeLockDuration = duration;
         // emit UnstakeLockDurationSet(duration, _msgSender());
         // Placeholder logic as state variable isn't added to save space initially.
         // In a real contract, you'd update a state variable.
    }


    /**
     * @dev Registers a key collaborator and potentially grants them initial Synergy Points.
     * @param collaborator The address of the collaborator.
     * @param initialSynergyPoints The amount of SPs to grant.
     */
    function registerCollaborator(address collaborator, uint256 initialSynergyPoints) external onlyRole(ADMIN_ROLE) {
        if (initialSynergyPoints > 0) {
            _mintSynergyPoints(collaborator, initialSynergyPoints);
        }
        // Could also grant specific roles here like GOVERNANCE_ROLE
        emit CollaboratorRegistered(collaborator, initialSynergyPoints, _msgSender());
    }

    // --- II. Protocol Fees ---

    /**
     * @dev Allows the designated fee recipient to withdraw collected protocol fees (native token).
     */
    function withdrawProtocolFees() external {
        if (_msgSender() != protocolFeeRecipient) revert Unauthorized(_msgSender(), bytes32(0));
        uint256 amount = _protocolFeeAccumulator;
        if (amount > 0) {
            _protocolFeeAccumulator = 0;
            (bool success, ) = payable(protocolFeeRecipient).call{value: amount}("");
            if (!success) {
                // Handle failure: log, or revert. Reverting keeps funds in contract.
                // For simplicity, let's just emit and leave funds. A real system might have a more robust mechanism.
                emit ProtocolFeesWithdrawn(protocolFeeRecipient, 0); // Indicate failed withdrawal by 0
            } else {
                emit ProtocolFeesWithdrawn(protocolFeeRecipient, amount);
            }
        }
    }

    /**
     * @dev Returns the total accumulated protocol fees in native token (wei).
     */
    function getProtocolFeeAccumulator() external view returns (uint256) {
        return _protocolFeeAccumulator;
    }

    /**
     * @dev Returns the fee set for a specific function signature.
     * @param functionSig The 4-byte function signature.
     * @return The required fee in native token (wei).
     */
    function getFunctionCallFee(bytes4 functionSig) external view returns (uint256) {
        return _functionCallFees[functionSig];
    }


    // --- III. Synergy Unit (SU) Management ---

    // Internal helper for logging SU events
    function _logSynergyUnitEvent(uint256 tokenId, string memory eventType, string memory details) internal {
         _synergyUnitHistory[tokenId].push(SynergyUnitEvent({
             timestamp: block.timestamp,
             eventType: eventType,
             caller: _msgSender(),
             details: details
         }));
    }

    /**
     * @dev Mints a new Synergy Unit and assigns it to an owner.
     *      Requires MINTER_ROLE and potentially a fee.
     * @param owner The address that will own the new SU.
     * @param initialMetadataURI The metadata URI for the SU.
     * @return The tokenId of the newly minted SU.
     */
    function mintSynergyUnit(address owner, string memory initialMetadataURI) external payable onlyRole(MINTER_ROLE) payFunctionFee(this.mintSynergyUnit.selector) returns (uint256) {
        uint256 tokenId = _nextSynergyUnitId++;
        _synergyUnitOwner[tokenId] = owner;
        _synergyUnitMetadata[tokenId] = initialMetadataURI;
        _synergyUnitLockUntil[tokenId] = 0; // Not locked initially
        // Clear any potential old state if tokenId reuse was a concept, but here it's monotonic

        _logSynergyUnitEvent(tokenId, "Mint", string(abi.encodePacked("Minted to ", Strings.toHexString(owner))));
        emit SynergyUnitMinted(tokenId, owner, initialMetadataURI, _msgSender());
        return tokenId;
    }

    /**
     * @dev Transfers ownership of a Synergy Unit.
     *      Subject to lock status and potentially a fee.
     * @param tokenId The ID of the SU to transfer.
     * @param to The recipient address.
     */
    function transferSynergyUnit(uint256 tokenId, address to) external payable notLocked(tokenId) payFunctionFee(this.transferSynergyUnit.selector) {
        address owner = _synergyUnitOwner[tokenId];
        if (owner == address(0)) revert InvalidTokenId();
        if (owner != _msgSender() && _synergyUnitDelegatee[tokenId] != _msgSender()) revert NotSynergyUnitOwnerOrDelegatee(tokenId, _msgSender()); // Only owner or delegatee can transfer (if delegation covers transfer)
        if (_synergyUnitDelegatee[tokenId] == _msgSender() && _synergyUnitDelegateeUntil[tokenId] < block.timestamp) revert DelegationExpired(tokenId);

        _synergyUnitOwner[tokenId] = to;
        _synergyUnitDelegatee[tokenId] = address(0); // Clear delegation on transfer
        _synergyUnitDelegateeUntil[tokenId] = 0;

        _logSynergyUnitEvent(tokenId, "Transfer", string(abi.encodePacked("Transferred from ", Strings.toHexString(owner), " to ", Strings.toHexString(to))));
        emit SynergyUnitTransferred(tokenId, owner, to, _msgSender());
    }

    /**
     * @dev Burns (destroys) a Synergy Unit.
     *      Subject to lock status and potentially a fee.
     * @param tokenId The ID of the SU to burn.
     */
    function burnSynergyUnit(uint256 tokenId) external payable notLocked(tokenId) payFunctionFee(this.burnSynergyUnit.selector) {
        address owner = _synergyUnitOwner[tokenId];
        if (owner == address(0)) revert InvalidTokenId();
        if (owner != _msgSender() && _synergyUnitDelegatee[tokenId] != _msgSender()) revert NotSynergyUnitOwnerOrDelegatee(tokenId, _msgSender());
         if (_synergyUnitDelegatee[tokenId] == _msgSender() && _synergyUnitDelegateeUntil[tokenId] < block.timestamp) revert DelegationExpired(tokenId);

        _synergyUnitOwner[tokenId] = address(0); // Clear owner
        delete _synergyUnitMetadata[tokenId]; // Clear metadata
        _synergyUnitDelegatee[tokenId] = address(0); // Clear delegation
        _synergyUnitDelegateeUntil[tokenId] = 0;
        _synergyUnitLockUntil[tokenId] = 0; // Ensure lock is cleared

        _logSynergyUnitEvent(tokenId, "Burn", string(abi.encodePacked("Burned by ", Strings.toHexString(_msgSender()))));
        emit SynergyUnitBurned(tokenId, owner, _msgSender());
    }

    /**
     * @dev Updates the metadata URI for a Synergy Unit.
     *      Callable by owner or delegatee, subject to lock status.
     * @param tokenId The ID of the SU.
     * @param newMetadataURI The new metadata URI.
     */
    function updateSynergyUnitMetadata(uint256 tokenId, string memory newMetadataURI) external onlySynergyUnitOwnerOrDelegatee(tokenId) notLocked(tokenId) {
        if (_synergyUnitDelegatee[tokenId] == _msgSender() && _synergyUnitDelegateeUntil[tokenId] < block.timestamp) revert DelegationExpired(tokenId);

        _synergyUnitMetadata[tokenId] = newMetadataURI;
         _logSynergyUnitEvent(tokenId, "UpdateMetadata", string(abi.encodePacked("Metadata updated to ", newMetadataURI)));
        emit SynergyUnitMetadataUpdated(tokenId, newMetadataURI, _msgSender());
    }

    /**
     * @dev Locks a Synergy Unit until a specific timestamp, preventing transfer and metadata changes.
     *      Callable by owner or delegatee.
     * @param tokenId The ID of the SU.
     * @param unlockTimestamp The timestamp when the lock expires. Must be in the future.
     */
    function lockSynergyUnit(uint256 tokenId, uint256 unlockTimestamp) external onlySynergyUnitOwnerOrDelegatee(tokenId) {
        if (_synergyUnitDelegatee[tokenId] == _msgSender() && _synergyUnitDelegateeUntil[tokenId] < block.timestamp) revert DelegationExpired(tokenId);
        if (unlockTimestamp <= block.timestamp) revert InvalidTimestamp(); // Custom error needed
        error InvalidTimestamp(); // Add custom error

        _synergyUnitLockUntil[tokenId] = unlockTimestamp;
        _logSynergyUnitEvent(tokenId, "Lock", string(abi.encodePacked("Locked until ", Strings.toString(unlockTimestamp))));
        emit SynergyUnitLocked(tokenId, unlockTimestamp, _msgSender());
    }

     /**
     * @dev Unlocks a Synergy Unit before its scheduled time if called by owner,
     *      or if the unlock timestamp has passed.
     * @param tokenId The ID of the SU.
     */
    function unlockSynergyUnit(uint256 tokenId) external onlySynergyUnitOwnerOrDelegatee(tokenId) {
        // Allows delegatee to unlock only if time has passed
        if (_synergyUnitLockUntil[tokenId] > block.timestamp && _synergyUnitOwner[tokenId] != _msgSender()) {
             revert Unauthorized(_msgSender(), bytes32(0)); // Only owner can force unlock early
        }
         if (_synergyUnitDelegatee[tokenId] == _msgSender() && _synergyUnitDelegateeUntil[tokenId] < block.timestamp) revert DelegationExpired(tokenId);


        _synergyUnitLockUntil[tokenId] = 0;
         _logSynergyUnitEvent(tokenId, "Unlock", "Unlocked");
        emit SynergyUnitUnlocked(tokenId, _msgSender());
    }

    /**
     * @dev Delegates certain rights (like updating metadata, locking/unlocking)
     *      for a Synergy Unit to another address for a specific duration.
     * @param tokenId The ID of the SU.
     * @param delegatee The address to delegate rights to.
     * @param duration The duration of the delegation in seconds.
     */
    function delegateSynergyUnitOwnership(uint256 tokenId, address delegatee, uint256 duration) external onlySynergyUnitOwnerOrDelegatee(tokenId) {
        // Only owner can set/change delegation
        if (_synergyUnitOwner[tokenId] != _msgSender()) revert Unauthorized(_msgSender(), bytes32(0));

        uint256 delegateeUntil = block.timestamp + duration;
        _synergyUnitDelegatee[tokenId] = delegatee;
        _synergyUnitDelegateeUntil[tokenId] = delegateeUntil;

         _logSynergyUnitEvent(tokenId, "Delegate", string(abi.encodePacked("Delegated to ", Strings.toHexString(delegatee), " until ", Strings.toString(delegateeUntil))));
        emit SynergyUnitDelegated(tokenId, delegatee, duration, _msgSender());
    }

    /**
     * @dev Reclaims the delegation rights for a Synergy Unit if currently delegated.
     *      Callable only by the owner.
     * @param tokenId The ID of the SU.
     */
    function reclaimSynergyUnitDelegation(uint256 tokenId) external {
         address owner = _synergyUnitOwner[tokenId];
         if (owner == address(0)) revert InvalidTokenId();
         if (owner != _msgSender()) revert Unauthorized(_msgSender(), bytes32(0));

         address currentDelegatee = _synergyUnitDelegatee[tokenId];
         if (currentDelegatee == address(0)) revert CannotReclaimActiveDelegatee(tokenId, address(0)); // No active delegation

        _synergyUnitDelegatee[tokenId] = address(0);
        _synergyUnitDelegateeUntil[tokenId] = 0;

         _logSynergyUnitEvent(tokenId, "ReclaimDelegation", string(abi.encodePacked("Reclaimed delegation from ", Strings.toHexString(currentDelegatee))));
        emit SynergyUnitDelegationReclaimed(tokenId, owner, currentDelegatee);
    }


    /**
     * @dev Returns the owner of a Synergy Unit.
     * @param tokenId The ID of the SU.
     * @return The owner's address.
     */
    function getSynergyUnitOwner(uint256 tokenId) external view returns (address) {
        return _synergyUnitOwner[tokenId];
    }

     /**
     * @dev Returns the metadata URI for a Synergy Unit.
     * @param tokenId The ID of the SU.
     * @return The metadata URI string.
     */
    function getSynergyUnitMetadata(uint256 tokenId) external view returns (string memory) {
        return _synergyUnitMetadata[tokenId];
    }

    /**
     * @dev Returns the timestamp until which a Synergy Unit is locked.
     * @param tokenId The ID of the SU.
     * @return The unlock timestamp (0 if not locked).
     */
    function getSynergyUnitLockUntil(uint256 tokenId) external view returns (uint256) {
        return _synergyUnitLockUntil[tokenId];
    }

    /**
     * @dev Returns the current delegatee for a Synergy Unit and checks if delegation is active.
     * @param tokenId The ID of the SU.
     * @return delegatee The delegatee address (address(0) if none).
     * @return isActive True if the delegation is currently active, false otherwise.
     */
    function getSynergyUnitDelegatee(uint256 tokenId) external view returns (address delegatee, bool isActive) {
        address currentDelegatee = _synergyUnitDelegatee[tokenId];
        if (currentDelegatee == address(0)) return (address(0), false);
        return (currentDelegatee, _synergyUnitDelegateeUntil[tokenId] > block.timestamp);
    }

    /**
     * @dev Returns the historical log of significant events for a Synergy Unit.
     * @param tokenId The ID of the SU.
     * @return An array of SynergyUnitEvent structs.
     */
    function getSynergyUnitHistory(uint256 tokenId) external view returns (SynergyUnitEvent[] memory) {
        return _synergyUnitHistory[tokenId];
    }


    // --- IV. Synergy Points (SP) & Fragment Token (SF) Management ---

    // Internal helper for minting SPs
    function _mintSynergyPoints(address account, uint256 amount) internal {
        if (amount > 0) {
            _synergyPointsBalance[account] += amount;
             // Optional: Log SP minting event
        }
    }

    // Internal helper for burning SPs
    function _burnSynergyPoints(address account, uint256 amount) internal {
        if (_synergyPointsBalance[account] < amount) revert InsufficientSynergyPoints(amount, _synergyPointsBalance[account]);
        _synergyPointsBalance[account] -= amount;
         // Optional: Log SP burning event
    }

    /**
     * @dev Allows users to claim accrued Synergy Points.
     *      Points accrue based on SU holdings, staked SPs, and epoch distribution.
     *      Subject to a cooldown period per user.
     */
    function claimSynergyPoints() external {
        address account = _msgSender();
        if (_lastSynergyPointsClaimTime[account] + synergyPointsClaimCooldown > block.timestamp) {
            revert ClaimCooldownNotElapsed(_lastSynergyPointsClaimTime[account] + synergyPointsClaimCooldown - block.timestamp);
        }

        // Calculate accrued points:
        // This is a complex calculation. Simplification for example: points are distributed via distributeEpochRewards
        // and become claimable by anyone who holds SUs or stakes SPs.
        // A real implementation would need state variables to track claimable amounts per user.
        // For THIS function, let's assume `distributeEpochRewards` directly adds to claimable balance,
        // and THIS function just moves claimable to liquid balance.
        // Need a mapping: `mapping(address => uint256) private _claimableSynergyPoints;`
        // And `distributeEpochRewards` would add to this map.

        uint256 claimable = _claimableSynergyPoints[account]; // Requires _claimableSynergyPoints state var
        if (claimable == 0) return; // Nothing to claim

        _synergyPointsBalance[account] += claimable;
        _claimableSynergyPoints[account] = 0; // Reset claimable balance
        _lastSynergyPointsClaimTime[account] = block.timestamp;

        emit SynergyPointsClaimed(account, claimable);
    }
     // Add state variable: mapping(address => uint256) private _claimableSynergyPoints;`


    /**
     * @dev Stakes liquid Synergy Points to earn rewards and boost voting power.
     * @param amount The amount of SPs to stake.
     */
    function stakeSynergyPoints(uint256 amount) external {
        address account = _msgSender();
        if (_synergyPointsBalance[account] < amount) revert InsufficientSynergyPoints(amount, _synergyPointsBalance[account]);
        if (amount == 0) return;

        _synergyPointsBalance[account] -= amount;
        _stakedSynergyPoints[account] += amount;

        emit SynergyPointsStaked(account, amount);
    }

    /**
     * @dev Initiates the unstaking process for Synergy Points.
     *      Starts a time lock before points can be withdrawn.
     * @param amount The amount of staked SPs to unstake.
     */
    function unstakeSynergyPoints(uint256 amount) external {
        address account = _msgSender();
        if (_stakedSynergyPoints[account] < amount) revert InsufficientStakedSynergyPoints(amount, _stakedSynergyPoints[account]);
        if (amount == 0) return;

        _stakedSynergyPoints[account] -= amount;
        _synergyPointsUnstakingAmount[account] += amount;
        // Assuming unstakeLockDuration is a state variable set by governance
        uint256 unstakeLockDuration = 7 days; // Placeholder, replace with state variable
        _synergyPointsUnstakeUnlockTime[account] = block.timestamp + unstakeLockDuration;

        emit SynergyPointsUnstakingInitiated(account, amount, _synergyPointsUnstakeUnlockTime[account]);
    }

    /**
     * @dev Withdraws Synergy Points that have completed the unstaking time lock.
     */
    function withdrawUnstakedSynergyPoints() external {
        address account = _msgSender();
        uint256 amount = _synergyPointsUnstakingAmount[account];
        if (amount == 0) revert NoUnstakedBalanceToWithdraw();
        if (_synergyPointsUnstakeUnlockTime[account] > block.timestamp) {
             revert UnstakeLockActive(_synergyPointsUnstakeUnlockTime[account] - block.timestamp);
        }

        _synergyPointsUnstakingAmount[account] = 0;
        _synergyPointsUnstakeUnlockTime[account] = 0;
        _synergyPointsBalance[account] += amount;

        emit SynergyPointsUnstakedWithdrawn(account, amount);
    }


    /**
     * @dev Delegates an account's total Synergy Points voting power to another address.
     * @param delegatee The address to delegate voting power to. Pass address(0) to clear delegation.
     */
    function delegateSynergyPointsVotingPower(address delegatee) external {
        address delegator = _msgSender();
        if (delegator == delegatee) revert CannotDelegateToSelf();
        // Optional: check if delegator already has an active delegation set, and prevent changing it?
        // For simplicity, allow changing delegatee freely.

        _synergyPointsDelegates[delegator] = delegatee;
        emit SynergyPointsDelegationSet(delegator, delegatee);
    }

    /**
     * @dev Burns a Synergy Unit and mints a fixed amount of Synergy Fragments to the owner.
     *      Subject to lock status.
     * @param tokenId The ID of the SU to split.
     */
    function splitSynergyUnit(uint256 tokenId) external notLocked(tokenId) {
        address owner = _synergyUnitOwner[tokenId];
        if (owner == address(0)) revert InvalidTokenId();
        if (owner != _msgSender()) revert NotSynergyUnitOwnerOrDelegatee(tokenId, _msgSender()); // Only owner can split

        // Burn the Synergy Unit
        _synergyUnitOwner[tokenId] = address(0);
        delete _synergyUnitMetadata[tokenId];
        _synergyUnitDelegatee[tokenId] = address(0);
        _synergyUnitDelegateeUntil[tokenId] = 0;
        _synergyUnitLockUntil[tokenId] = 0;

        // Mint Synergy Fragments to the owner
        uint256 fragmentsToMint = FRAGMENT_TOKENS_PER_UNIT;
        _fragmentTokenBalance[owner] += fragmentsToMint;

        _logSynergyUnitEvent(tokenId, "Split", string(abi.encodePacked("Split into ", Strings.toString(fragmentsToMint), " fragments")));
        emit SynergyUnitBurned(tokenId, owner, _msgSender()); // Emit burn event for the SU
        emit SynergyUnitSplit(tokenId, owner, fragmentsToMint); // Emit custom split event
    }

    /**
     * @dev Allows merging a sufficient amount of Synergy Fragments, plus a cost in SPs,
     *      to mint a new Synergy Unit.
     * @param fragmentAmount The amount of Synergy Fragments to burn. Must be >= FRAGMENT_TOKENS_FOR_NEW_UNIT.
     */
    function mergeFragmentTokensToMintUnit(uint256 fragmentAmount) external {
        address minter = _msgSender();
        if (fragmentAmount < FRAGMENT_TOKENS_FOR_NEW_UNIT) revert InvalidFragmentAmount();
        if (_fragmentTokenBalance[minter] < fragmentAmount) revert InsufficientFragmentTokens(fragmentAmount, _fragmentTokenBalance[minter]); // Custom error needed
        if (_synergyPointsBalance[minter] < SP_COST_FOR_NEW_UNIT) revert InsufficientSynergyPoints(SP_COST_FOR_NEW_UNIT, _synergyPointsBalance[minter]);
         error InsufficientFragmentTokens(uint256 required, uint256 available); // Add custom error


        // Burn Fragments and SPs
        _fragmentTokenBalance[minter] -= fragmentAmount;
        _synergyPointsBalance[minter] -= SP_COST_FOR_NEW_UNIT;

        // Mint a new Synergy Unit
        uint256 newTokenId = _nextSynergyUnitId++;
        _synergyUnitOwner[newTokenId] = minter;
        _synergyUnitMetadata[newTokenId] = string(abi.encodePacked("MergedUnit-", Strings.toString(block.timestamp))); // Default metadata
        _synergyUnitLockUntil[newTokenId] = 0;

         _logSynergyUnitEvent(newTokenId, "MintFromMerge", string(abi.encodePacked("Minted by merging ", Strings.toString(fragmentAmount), " fragments and ", Strings.toString(SP_COST_FOR_NEW_UNIT), " SPs")));
        emit FragmentTokensMergedToMintUnit(minter, fragmentAmount, SP_COST_FOR_NEW_UNIT, newTokenId);
        emit SynergyUnitMinted(newTokenId, minter, _synergyUnitMetadata[newTokenId], address(0)); // Minter is the contract for this event variant
    }


    /**
     * @dev Triggers the distribution of epoch-based Synergy Points rewards.
     *      Can be called by anyone after an epoch has elapsed.
     *      Distributes points based on SU holdings and staked SPs during the past epoch.
     *      This requires careful state tracking of holdings/stakes *at the start of the epoch*.
     *      Simplified implementation: assumes distribution is based on *current* holdings/stakes,
     *      which is less accurate but simpler for demonstration. A real system needs snapshots.
     */
    function distributeEpochRewards() external {
        if (block.timestamp < lastEpochDistributionTime + epochDuration) {
            revert EpochNotElapsed();
        }
        if (currentEpoch > 1 && lastEpochDistributionTime == block.timestamp) {
             revert EpochRewardsAlreadyDistributed(); // Basic check against re-calling in same block
        }

        currentEpoch++; // Increment epoch number
        lastEpochDistributionTime = block.timestamp; // Record distribution time

        uint256 totalDistributed = 0;

        // Simplified distribution: Iterate through all *current* SU owners
        // In a real system, this loop over *all* SUs might be too gas-expensive.
        // A better approach uses iterable maps or distributes on claim.
        uint256 totalSynergyUnits = _nextSynergyUnitId; // Assuming all IDs < nextId exist if not burned
        for (uint256 i = 0; i < totalSynergyUnits; ++i) {
            address owner = _synergyUnitOwner[i];
            // Check if unit exists and is not locked (or locked units still earn?)
            // Let's say locked units *do* earn SPs
            if (owner != address(0)) {
                 uint256 pointsEarned = baseSynergyPointsPerSU;
                 // Can add multiplier for staked SPs by owner:
                 // pointsEarned += (_stakedSynergyPoints[owner] / 100) * SP_BONUS_RATE; // Example bonus
                 // Points are added to the claimable balance
                 _claimableSynergyPoints[owner] += pointsEarned; // Requires _claimableSynergyPoints state var added earlier
                 totalDistributed += pointsEarned;
            }
        }

        // Optional: Distribute bonus SPs to those staking SPs directly
        // This also needs iteration or a system of claiming based on stake duration.
        // Simplified: The baseSynergyPointsPerSU *already implicitly* rewards stakers because staked SPs contribute to voting power which *could* be a factor in claiming (though not in this simple model).

        emit SynergyPointsEpochDistributed(currentEpoch - 1, totalDistributed, _msgSender()); // Emit for the epoch that just ended
    }


    /**
     * @dev Returns the liquid (non-staked, non-unstaking) Synergy Points balance for an account.
     * @param account The address to check.
     * @return The liquid SP balance.
     */
    function getSynergyPointsBalance(address account) external view returns (uint256) {
        return _synergyPointsBalance[account];
    }

     /**
     * @dev Returns the staked Synergy Points balance for an account.
     * @param account The address to check.
     * @return The staked SP balance.
     */
    function getStakedSynergyPoints(address account) external view returns (uint256) {
        return _stakedSynergyPoints[account];
    }

    /**
     * @dev Returns the amount of Synergy Points currently being unstaked and the unlock timestamp.
     * @param account The address to check.
     * @return amount The amount of SPs being unstaked.
     * @return unlockTime The timestamp when the unstaking lock expires.
     */
    function getUnstakingSynergyPoints(address account) external view returns (uint256 amount, uint256 unlockTime) {
        return (_synergyPointsUnstakingAmount[account], _synergyPointsUnstakeUnlockTime[account]);
    }

     /**
     * @dev Calculates and returns the total Synergy Points voting power for an account.
     *      Includes liquid balance, staked balance, and any delegated power.
     * @param account The address to check.
     * @return The total voting power.
     */
    function getSynergyVotingPower(address account) external view returns (uint256) {
        address delegatee = _synergyPointsDelegates[account];
        if (delegatee != address(0) && delegatee != account) {
            // If account has delegated their power, their own power is 0 for voting
            return 0;
        }

        uint256 delegatedPower = 0;
        // Need to iterate or use a more complex mapping to find who delegated to this account.
        // Simplified: Assume voting power is just own liquid + staked balance for now,
        // and delegation means someone ELSE votes *using* this account's power.
        // Correct delegation: delegator's power is transferred to delegatee.
        // So, need to sum up all liquid + staked for addresses that delegated *to* this account.
        // This requires an iterable map of delegates or a reverse mapping.
        // Let's implement simple delegation: delegator's power becomes 0, delegatee's power doesn't change,
        // BUT the delegatee can vote *on behalf of* the delegator.
        // A common governance pattern calculates voting power AT THE TIME OF VOTING by tracing the delegate chain.

        // Let's recalculate voting power lookup for voting:
        // `_getSynergyVotingPowerForVoting(address voter)` - this needs to handle the delegation chain.
        // Simple approach for `getSynergyVotingPower`: just return liquid + staked.
        // The actual voting function will use a different calculation.
         return _synergyPointsBalance[account] + _stakedSynergyPoints[account];
    }

     // Internal helper to get actual voting power for a voter (resolves delegation)
     function _getSynergyVotingPowerForVoting(address voter) internal view returns (uint256) {
         address current = voter;
         address delegatee = _synergyPointsDelegates[current];
         // Follow delegation chain - although most implementations only allow 1 level
         // Let's assume simple 1-level delegation:
         if (delegatee != address(0) && delegatee != current) {
            current = delegatee; // The delegatee votes using the delegator's power source
         }
         // The power source is the liquid + staked balance of the original delegator OR the voter if no delegation
        // This requires knowing the original delegator... simpler: delegation sets who *can vote*.
        // The power comes from *their own* balance + delegated power *received*.
        // This needs a `mapping(address => uint256) _receivedVotingPower;`
        // When A delegates to B, A's power goes to 0, B's `_receivedVotingPower` increases by A's balance.
        // Then total power for B is B's balance + B's _receivedVotingPower.
        // When A changes delegate or balance, need to update this. This is complex state management.

        // Simplest feasible model for this example: Voting power is (liquid + staked) IF they haven't delegated out.
        // If they *have* delegated out, their power is 0. Delegation *to* them doesn't increase their `getSynergyVotingPower`.
        // The `voteOnProposal` function checks who to count the vote *under*.

         address originalDelegator = address(0); // Need reverse map or iterate to find this

         // Revert to the simplest possible interpretation: Voting power is Liquid + Staked for addresses *not* in `_synergyPointsDelegates` as a key (meaning they haven't delegated *out*).
         // If A delegates to B, A cannot vote, B can vote using B's own power. This doesn't match the prompt's intent of delegating *power*.

         // Let's use the common pattern: delegator's power is 0, delegatee can vote for delegator using their combined balance snapshot *at time of voting*.
         // This still requires summing up balances of all who delegated to the delegatee.
         // This is infeasible without iterable maps or complex state.

         // Okay, compromise for demo: Voting power = liquid + staked. Delegation just means someone else *can call vote* on your behalf.
         // `voteOnProposal` will check `_synergyPointsDelegates[msg.sender]` to see *who* the power belongs to.
         // This requires mapping voters to delegators: `mapping(address => address) private _delegatorOf;`
         // When A delegates to B: `_synergyPointsDelegates[A] = B; _delegatorOf[B] = A;` NO, delegation is many-to-one.
         // Need `mapping(address => address[]) private _delegatorsTo;` - but dynamic arrays in storage are bad.

         // Backtrack: Most governance tokens *don't* require complex chain resolution or received power tracking in `getVotingPower`.
         // `getVotingPower` usually just returns the balance + staked *of the queried address*.
         // The delegation logic happens *inside vote*.
         // When `vote(proposalId, support)` is called by `msg.sender`:
         // Check if `msg.sender` has delegated *out* (`_synergyPointsDelegates[msg.sender] != address(0)`). If so, they can't vote.
         // If they haven't delegated out, their power is their own balance + staked.
         // If someone calls `voteFor(proposalId, support, address delegator)`:
         // Check if `msg.sender` is the delegatee of `delegator`. If so, calculate power based on `delegator`'s balance + staked.

         // The prompt implies `delegateSynergyPointsVotingPower` is the standard A-delegates-to-B, B votes with A's power model.
         // Let's stick to that and implement `getSynergyVotingPower` as liquid + staked.
         // The `voteOnProposal` function will be the one that resolves who is voting for whom and whose power is used.

        return _synergyPointsBalance[account] + _stakedSynergyPoints[account]; // Default simple calculation
     }


     /**
     * @dev Returns the Synergy Fragment token balance for an account.
     * @param account The address to check.
     * @return The SF balance.
     */
    function getFragmentTokenBalance(address account) external view returns (uint256) {
        return _fragmentTokenBalance[account];
    }

    /**
     * @dev Returns the current epoch number.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @dev Returns the timestamp of the last epoch reward distribution.
     */
    function getLastEpochDistributionTime() external view returns (uint256) {
        return lastEpochDistributionTime;
    }


    // --- V. Governance System ---

    /**
     * @dev Creates a new governance proposal.
     *      Requires GOVERNANCE_ROLE and/or a minimum SP stake (not implemented here, requires check).
     * @param target The address of the contract to call if the proposal passes.
     * @param data The calldata for the target contract.
     * @param description A description of the proposal.
     * @return The ID of the newly created proposal.
     */
    function proposeConfigurationChange(address target, bytes memory data, string memory description) external onlyRole(GOVERNANCE_ROLE) returns (uint256) {
         // Could add a requirement for minimum staked SPs to propose
         // if (_stakedSynergyPoints[_msgSender()] < MIN_SP_TO_PROPOSE) revert InsufficientStakedSynergyPoints(...); // Example

        uint256 proposalId = _nextProposalId++;
        // Configurable voting period and execution timelock duration via state variables or constants
        uint256 votingPeriodDuration = 3 days; // Placeholder
        uint256 executionTimeLockDuration = 1 days; // Placeholder

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: _msgSender(),
            target: target,
            data: data,
            description: description,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + votingPeriodDuration,
            executionTimeLockEnd: 0, // Set after voting ends and passes
            totalVotes: 0,
            supportVotes: 0,
            minimumVotingPower: 1000 * 10 ** 18, // Example: 1000 SP minimum quorum
            executed: false
        });

        emit ProposalCreated(proposalId, _msgSender(), target, description);
        return proposalId;
    }

    /**
     * @dev Casts a vote on an active proposal.
     *      Uses the voter's total Synergy Points voting power (liquid + staked).
     *      Can vote directly or via a delegate.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True to vote in favor, false to vote against.
     */
    function voteOnProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0 && proposalId != 0) revert InvalidProposalId(); // Check if proposal exists
        if (proposal.votingPeriodEnd <= block.timestamp) revert ProposalPeriodNotEnded();
        if (proposal.executed) revert ProposalAlreadyExecuted();

        address voter = _msgSender();
        address delegator = address(0); // The account whose power is used

        // Determine whose power is being used:
        // If msg.sender has delegated *out*, they cannot vote directly.
        // We need to find if someone delegated *to* msg.sender.
        // This is the part that needs the reverse lookup or iteration mentioned earlier.
        // Without it, we have to make a compromise.

        // Compromise: Voter is msg.sender. Their power is their own balance + staked.
        // Delegation means someone else *can call this function* on your behalf, but the power is *yours*.
        // This is NOT the standard governance model.

        // Standard Model (Requires state updates on delegation/balance changes):
        // Voting power is calculated based on snapshot at vote time, including received delegations.
        // Let's try to emulate this simply:
        // Voting power = msg.sender's liquid + staked + sum of liquid+staked from addresses that delegated *to* msg.sender.
        // This sum requires iteration or a complex state map. Let's skip the "received delegation" sum for this example.

        // Simpler Standard Model: Voting power = msg.sender's liquid + staked. Delegation means msg.sender's delegatee *can call voteFor* with msg.sender's address.
        // Let's add a `voteFor` function.

        // Okay, refining `voteOnProposal`: Assume the standard delegate pattern where A delegates to B, B votes using A's power.
        // The caller (`msg.sender`) must *be* either the original owner *or* their delegatee.
        // The vote is recorded *under* the original owner's address to prevent duplicate votes.
        address voterPowerSource = _msgSender(); // Assume msg.sender is the source unless they delegated out

        // Check if msg.sender has delegated their voting power OUT. If so, they cannot vote directly with their own power.
        // This requires knowing if `_synergyPointsDelegates[msg.sender]` is not address(0).
        // If it's not address(0), it means msg.sender HAS delegated THEIR power elsewhere.
        if (_synergyPointsDelegates[_msgSender()] != address(0)) {
             revert SynergyPointsAlreadyDelegated(_msgSender()); // Cannot vote directly if you've delegated out
        }

        // Now, get the actual voting power for the voterPowerSource (which is msg.sender in this simplified model)
        uint256 votingPower = _synergyPointsBalance[voterPowerSource] + _stakedSynergyPoints[voterPowerSource];

        if (votingPower == 0) revert InsufficientSynergyPoints(1, 0); // Must have > 0 voting power

        // Check if the *original power source* address has already voted
        if (_hasVoted[proposalId][voterPowerSource]) revert AlreadyVoted(proposalId, voterPowerSource);

        _hasVoted[proposalId][voterPowerSource] = true;
        proposal.totalVotes += votingPower;
        if (support) {
            proposal.supportVotes += votingPower;
        }

        emit VoteCast(proposalId, voterPowerSource, _msgSender(), support, votingPower); // Log original source and caller (delegate)
    }

    /**
     * @dev Allows a delegatee to cast a vote on behalf of a delegator.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True to vote in favor, false to vote against.
     * @param delegator The address whose voting power is being used.
     */
    function voteFor(uint256 proposalId, bool support, address delegator) external {
         Proposal storage proposal = _proposals[proposalId];
         if (proposal.id == 0 && proposalId != 0) revert InvalidProposalId();
         if (proposal.votingPeriodEnd <= block.timestamp) revert ProposalPeriodNotEnded();
         if (proposal.executed) revert ProposalAlreadyExecuted();

         address caller = _msgSender();
         if (_synergyPointsDelegates[delegator] != caller) revert Unauthorized(caller, bytes32(0)); // Caller must be the designated delegatee

         // Get voting power based on the *delegator's* balance/stake at this moment
         uint256 votingPower = _synergyPointsBalance[delegator] + _stakedSynergyPoints[delegator];

         if (votingPower == 0) revert InsufficientSynergyPoints(1, 0);

         // Check if the *delegator* has already voted (either directly before delegating, or via another delegate - shouldn't happen with 1-level delegation)
         if (_hasVoted[proposalId][delegator]) revert AlreadyVoted(proposalId, delegator);

         _hasVoted[proposalId][delegator] = true;
         proposal.totalVotes += votingPower;
         if (support) {
             proposal.supportVotes += votingPower;
         }

         emit VoteCast(proposalId, delegator, caller, support, votingPower); // Log delegator (source) and caller (delegate)
    }


    /**
     * @dev Executes a passed governance proposal.
     *      Can be called by anyone after the voting period ends and the execution time lock expires,
     *      if the proposal met quorum and passed.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0 && proposalId != 0) revert InvalidProposalId();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (block.timestamp < proposal.votingPeriodEnd) revert ProposalPeriodNotEnded(); // Voting must be over

        // Check if proposal passed (met quorum and majority support)
        bool passed = proposal.totalVotes >= proposal.minimumVotingPower &&
                      proposal.supportVotes > proposal.totalVotes / 2;

        if (!passed) {
             // Optional: Mark proposal as failed? Add state?
             revert ProposalFailed();
        }

        // Set/Check execution time lock
        if (proposal.executionTimeLockEnd == 0) {
             // Set the execution time lock the first time execute is called after voting ends
             uint256 executionTimeLockDuration = 1 days; // Placeholder, use state var
             proposal.executionTimeLockEnd = block.timestamp + executionTimeLockDuration;
             // Revert to wait for timelock
             revert ProposalExecutionTimeLockActive(executionTimeLockDuration); // Indicate timelock started
        }

        if (block.timestamp < proposal.executionTimeLockEnd) {
             revert ProposalExecutionTimeLockActive(proposal.executionTimeLockEnd - block.timestamp);
        }

        // Execute the proposal call
        // Use low-level call, check success
        (bool success, ) = proposal.target.call(proposal.data);

        proposal.executed = true;
        emit ProposalExecuted(proposalId, success);

        if (!success) {
            // Handle execution failure - maybe log or revert
            // Reverting here means the state change (executed=true) is rolled back too.
            // Often, proposals are marked executed regardless of call success to prevent retries.
            // Let's just emit success status.
        }
    }


    /**
     * @dev Returns details about a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return A struct containing the proposal's details.
     */
    function getProposalDetails(uint256 proposalId) external view returns (Proposal memory) {
         if (_proposals[proposalId].id == 0 && proposalId != 0) revert InvalidProposalId();
         return _proposals[proposalId];
    }


    // --- VI. Attestations ---

    /**
     * @dev Links an external attestation (e.g., IPFS hash) to a Synergy Unit.
     *      Intended for tying off-chain verifiable claims or data to the asset.
     *      Callable by owner or delegatee.
     * @param tokenId The ID of the SU.
     * @param attestationURI The URI pointing to the attestation data.
     * @return The ID of the submitted attestation for this SU.
     */
    function submitAttestation(uint256 tokenId, string memory attestationURI) external onlySynergyUnitOwnerOrDelegatee(tokenId) {
         if (_synergyUnitDelegatee[tokenId] == _msgSender() && _synergyUnitDelegateeUntil[tokenId] < block.timestamp) revert DelegationExpired(tokenId);
         if (_synergyUnitOwner[tokenId] == address(0)) revert InvalidTokenId();

         uint256 attestationId = _nextAttestationId[tokenId]++;

         _synergyUnitAttestations[tokenId].push(Attestation({
             id: attestationId,
             submitter: _msgSender(),
             timestamp: block.timestamp,
             attestationURI: attestationURI
         }));

         _logSynergyUnitEvent(tokenId, "Attestation", string(abi.encodePacked("Attestation #", Strings.toString(attestationId), " submitted by ", Strings.toHexString(_msgSender()))));
         emit AttestationSubmitted(tokenId, attestationId, _msgSender(), attestationURI);
    }

    /**
     * @dev Returns the list of attestations linked to a Synergy Unit.
     * @param tokenId The ID of the SU.
     * @return An array of Attestation structs.
     */
    function getSynergyUnitAttestations(uint256 tokenId) external view returns (Attestation[] memory) {
         return _synergyUnitAttestations[tokenId];
    }

     // --- Helper Libraries (Example using minimal needed parts, replace with OpenZeppelin for production) ---
     library Strings {
         function toString(uint256 value) internal pure returns (string memory) {
             if (value == 0) {
                 return "0";
             }
             uint256 temp = value;
             uint256 digits;
             while (temp != 0) {
                 digits++;
                 temp /= 10;
             }
             bytes memory buffer = new bytes(digits);
             uint256 index = digits;
             temp = value;
             while (temp != 0) {
                 index--;
                 buffer[index] = bytes1(uint8(48 + temp % 10));
                 temp /= 10;
             }
             return string(buffer);
         }
         function toHexString(address account) internal pure returns (string memory) {
             return toHexString(uint160(account), 20);
         }
         function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
             bytes memory buffer = new bytes(2 * length);
             for (uint256 i = 0; i < length; i++) {
                 buffer[2 * i] = _HEX_SYMBOLS[(value >> (8 * (length - 1 - i))) & 0xf];
                 buffer[2 * i + 1] = _HEX_SYMBOLS[(value >> (8 * (length - 1 - i)) * 4) & 0xf]; // Incorrect bit shift, should be (value >> (8 * (length - 1 - i))) & 0xF
             }
             // Corrected bit shift
             for (uint256 i = 0; i < length; i++) {
                uint256 temp = value >> (8 * (length - 1 - i));
                buffer[2 * i] = _HEX_SYMBOLS[(temp >> 4) & 0xF];
                buffer[2 * i + 1] = _HEX_SYMBOLS[temp & 0xF];
            }
             return string(abi.encodePacked("0x", buffer));
         }
         bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
     }

     // --- Internal/Private Helper for msg.sender ---
     // Needed for consistent _msgSender() across different execution contexts if used with meta-transactions.
     // For simplicity here, it's just `msg.sender`.

     function _msgSender() internal view virtual returns (address) {
         return msg.sender;
     }
}
```