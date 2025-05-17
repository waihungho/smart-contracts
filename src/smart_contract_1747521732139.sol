```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. Contract Description: A sophisticated asset vault (`QuantumVault`) allowing deposits
//    under multiple, complex, time-sensitive, and state-dependent release conditions.
//    Inspired by concepts of quantum states and entanglement, it links release to
//    probabilistic outcomes, external data feeds, other vault states, future proofs,
//    multi-signature requirements, and internal contract states. It aims for complex,
//    non-standard conditional release mechanisms.
// 2. Data Structures:
//    - VaultState: Enum for the state of a vault (Locked, PendingUnlock, Unlocked, Cancelled).
//    - ReleaseConditions: Struct holding parameters for all potential release conditions.
//    - Vault: Struct representing a single vault with its details, state, and conditions.
// 3. State Variables:
//    - Owner address.
//    - Mapping of vault IDs (bytes32) to Vault structs.
//    - Mapping to track ERC20 balances per token within vaults.
//    - Counter for unique vault ID generation (simplified using hash of params + nonce).
//    - Authorized addresses for specific operations (external data, probabilistic seed, internal state update).
//    - Internal state variable for state-dependent conditions.
//    - Pause mechanism flag.
// 4. Modifiers:
//    - onlyOwner: Restricts access to the contract owner.
//    - vaultExists: Ensures a vault with the given ID exists.
//    - vaultInState: Ensures a vault is in a specific state.
//    - whenNotPaused / whenPaused: Standard pause mechanism modifiers.
//    - onlyDepositor: Restricts access to the vault's depositor.
//    - onlyAuthorized: Restricts access to configured authorized addresses.
// 5. Events:
//    - VaultCreated: Emitted when a new vault is created.
//    - AssetAddedToVault: Emitted when more assets are added to a vault.
//    - VaultStateChanged: Emitted when a vault's state changes.
//    - VaultUnlocked: Emitted when a vault successfully unlocks and assets are released.
//    - VaultCancelled: Emitted when a vault is cancelled.
//    - ExternalDataProvided: Emitted when external data is submitted for a vault condition.
//    - FutureProofPreimageRevealed: Emitted when a future proof pre-image is revealed.
//    - MultisigConfirmationSubmitted: Emitted when a multisig signer confirms.
//    - ProbabilisticSeedSet: Emitted when a probabilistic seed is set.
//    - InternalStateUpdated: Emitted when the internal state variable is changed.
//    - FlexibleConditionsUpdated: Emitted when flexible conditions are updated.
//    - ExcessTokenWithdrawn: Emitted when owner withdraws excess tokens.
// 6. Functions: (At least 20 public/external functions)
//    - Core Vault Management: createVault, addToVault, attemptUnlock, cancelVault.
//    - Condition Input: provideExternalData, revealFutureProofPreimage, submitMultisigConfirmation, setProbabilisticSeed, setInternalStateValue.
//    - Configuration/Updates: updateFlexibleConditions, setAuthorisedExternalDataProvider, setAuthorisedProbabilisticSeedProvider, setAuthorisedInternalStateUpdater.
//    - View Functions: getVaultDetails, getVaultState, checkConditionsMet, getMultisigStatus, getContractEthBalance, getContractTokenBalance, getInternalStateValue.
//    - Admin: transferOwnership, pause, unpause, withdrawExcessTokens.

// --- Function Summary ---
// constructor(): Initializes the contract and sets the owner.
// createVault(asset, amount, conditions): Creates a new vault with specified asset (ETH or ERC20), amount, and complex release conditions. Handles incoming ETH or checks ERC20 allowance.
// addToVault(vaultId, amount): Adds more asset (ETH or ERC20) to an existing vault. Handles incoming ETH or checks ERC20 allowance. Vault must be in Locked state.
// attemptUnlock(vaultId, _futureProofPreimage): Attempts to check all conditions for a vault and unlock it if met. Takes the future proof pre-image as input if required.
// cancelVault(vaultId): Allows the depositor to cancel a vault under specific conditions (e.g., before unlock time).
// updateFlexibleConditions(vaultId, newUnlockTime, newProbabilisticProbabilityBasisPoints): Allows the depositor to update certain conditions before the unlock time passes.
// provideExternalData(vaultId, data): Allows a configured authorized address (or anyone, based on auth config) to provide external data required for a condition. Data must match the stored hash.
// revealFutureProofPreimage(vaultId, preimage): Allows the designated revealer (or depositor) to reveal the pre-image for the future proof condition.
// submitMultisigConfirmation(vaultId): Allows a designated multisig signer to submit their confirmation for a vault unlock.
// setProbabilisticSeed(vaultId, seed): Allows a configured authorized address (e.g., VRF coordinator) to set the seed for the probabilistic condition.
// setInternalStateValue(newValue): Allows a configured authorized address (or owner) to update the internal state variable used in state-dependent conditions.
// setAuthorisedExternalDataProvider(provider): Owner function to set or unset the authorized address for providing external data.
// setAuthorisedProbabilisticSeedProvider(provider): Owner function to set or unset the authorized address for setting probabilistic seeds.
// setAuthorisedInternalStateUpdater(updater): Owner function to set or unset the authorized address for updating the internal state value.
// getVaultDetails(vaultId): View function returning all details of a specific vault.
// getVaultState(vaultId): View function returning the current state of a specific vault.
// checkConditionsMet(vaultId): View function checking and returning which *individual* conditions are currently met for a vault. Does not attempt unlock.
// getMultisigStatus(vaultId): View function returning the list of required signers and their confirmation status for a vault.
// getContractEthBalance(): View function returning the contract's current ETH balance.
// getContractTokenBalance(tokenAddress): View function returning the contract's balance for a specific ERC20 token.
// getInternalStateValue(): View function returning the current value of the internal state variable.
// transferOwnership(newOwner): Transfers contract ownership.
// pause(): Pauses contract operations (createVault, addToVault, attemptUnlock, condition inputs).
// unpause(): Unpauses contract operations.
// withdrawExcessTokens(tokenAddress, recipient): Allows the owner to withdraw tokens sent to the contract address that are not associated with any active vault.

contract QuantumVault {
    address public owner;
    bool public paused;

    enum VaultState {
        Locked,          // Assets are held, conditions not met, cannot unlock yet
        PendingUnlock,   // Some conditions met, awaiting others or inputs (e.g., multisig, external data)
        Unlocked,        // All conditions met, assets claimed or ready to be claimed
        Cancelled        // Vault was cancelled, assets released back to depositor
    }

    struct ReleaseConditions {
        uint64 unlockTime; // Standard time lock timestamp (condition 1)

        bytes32 requiredExternalDataHash; // Hash of data required (condition 2)
        bytes submittedExternalData;      // Data provided to meet condition 2

        uint256 probabilisticProbabilityBasisPoints; // Probability of success in basis points (e.g., 5000 = 50%) (condition 3)
        bytes32 probabilisticSeed;                   // Seed for probability calculation (e.g., from VRF) (condition 3 input)
        bool probabilisticOutcomeDetermined;         // Flag to ensure seed is set only once

        bytes32 linkedVaultId; // ID of another vault that must be in Unlocked state (condition 4)

        bytes32 futureProofUnlockHash; // Hash of a secret (condition 5)
        bytes futureProofPreimage;     // Revealed secret pre-image (condition 5 input)

        address[] multisigSigners; // Addresses required for multisig (condition 6)
        uint256 requiredConfirmations; // Number of confirmations needed (condition 6)
        mapping(address => bool) multisigConfirmed; // Track confirmations (condition 6 state)

        uint256 requiredInternalStateValue; // A specific internal contract state value required (condition 7)

        uint64 negativeConditionDeadline; // Timestamp before which a negative event *must NOT* happen (condition 8)
        bool negativeConditionMet;        // Flag if the negative condition *was* met (failed) before deadline (condition 8 state)

        bool conditionsConfigured; // Flag to ensure conditions are immutable after creation (except flexible)
    }

    struct Vault {
        bytes32 id;
        address depositor;
        address asset; // address(0) for ETH
        uint256 amount;
        bool isEth;
        VaultState state;
        ReleaseConditions conditions;
    }

    mapping(bytes32 => Vault) public vaults;
    mapping(address => mapping(address => uint256)) private vaultErc20Balances; // tokenAddress => vaultId (placeholder) => amount
    // Note: Using vaultId as a key in a direct mapping like this isn't standard for ERC20 balances.
    // The standard way is to track total ERC20 balance *in the contract* and the specific amount *per vault* in the Vault struct.
    // Let's correct this mapping to just track the total token balance held by the contract for *any* vault of that token type.
    mapping(address => uint256) private totalVaultErc20Balances; // tokenAddress => total amount held in the contract for vaults

    uint256 private nonce; // Used to help generate unique vault IDs

    address public authorisedExternalDataProvider;
    address public authorisedProbabilisticSeedProvider;
    address public authorisedInternalStateUpdater;
    uint256 public currentInternalStateValue; // The state variable for condition 7

    // --- Events ---
    event VaultCreated(bytes32 indexed vaultId, address indexed depositor, address asset, uint256 amount, uint64 unlockTime);
    event AssetAddedToVault(bytes32 indexed vaultId, address asset, uint256 amount);
    event VaultStateChanged(bytes32 indexed vaultId, VaultState newState, VaultState oldState);
    event VaultUnlocked(bytes32 indexed vaultId, address indexed recipient, address asset, uint256 amount);
    event VaultCancelled(bytes32 indexed vaultId, address indexed recipient, address asset, uint256 amount);
    event ExternalDataProvided(bytes32 indexed vaultId, bytes data, bool hashMatch);
    event FutureProofPreimageRevealed(bytes32 indexed vaultId, bytes preimage);
    event MultisigConfirmationSubmitted(bytes32 indexed vaultId, address indexed signer);
    event ProbabilisticSeedSet(bytes32 indexed vaultId, bytes32 seed);
    event InternalStateUpdated(uint256 oldValue, uint256 newValue);
    event FlexibleConditionsUpdated(bytes32 indexed vaultId, uint64 newUnlockTime, uint256 newProbabilisticProbabilityBasisPoints);
    event ExcessTokenWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier vaultExists(bytes32 _vaultId) {
        require(vaults[_vaultId].id != bytes32(0), "Vault does not exist");
        _;
    }

    modifier vaultInState(bytes32 _vaultId, VaultState _state) {
        require(vaults[_vaultId].state == _state, "Vault not in required state");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyDepositor(bytes32 _vaultId) {
        require(vaults[_vaultId].depositor == msg.sender, "Only depositor");
        _;
    }

    modifier onlyAuthorized(address authorizedAddress) {
        require(msg.sender == authorizedAddress || msg.sender == owner, "Not authorized");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        paused = false;
        nonce = 0;
        currentInternalStateValue = 0;
    }

    // --- Core Vault Management Functions ---

    /// @notice Creates a new vault with specified conditions and initial asset deposit.
    /// @param _asset The address of the ERC20 token, or address(0) for ETH.
    /// @param _amount The amount of assets to deposit.
    /// @param _conditions The release conditions for the vault.
    function createVault(
        address _asset,
        uint256 _amount,
        ReleaseConditions calldata _conditions
    ) external payable whenNotPaused {
        require(_amount > 0, "Amount must be > 0");
        require(_conditions.unlockTime > block.timestamp, "Unlock time must be in the future");
        if (_conditions.multisigSigners.length > 0) {
             require(_conditions.requiredConfirmations > 0 && _conditions.requiredConfirmations <= _conditions.multisigSigners.length, "Invalid multisig requirements");
        }

        bool isEth = _asset == address(0);
        if (isEth) {
            require(msg.value == _amount, "ETH amount mismatch");
        } else {
            require(msg.value == 0, "Do not send ETH for token vault");
            // ERC20 transferFrom must be called by this contract, meaning the user must have
            // approved this contract beforehand.
            bool success = IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
            require(success, "Token transfer failed");
            totalVaultErc20Balances[_asset] += _amount; // Track total held
        }

        nonce++;
        // Generate a unique vault ID based on depositor, asset, amount, unlock time, and nonce
        bytes32 vaultId = keccak256(abi.encodePacked(msg.sender, _asset, _amount, _conditions.unlockTime, nonce));

        require(vaults[vaultId].id == bytes32(0), "Vault ID collision"); // Extremely unlikely

        Vault storage newVault = vaults[vaultId];
        newVault.id = vaultId;
        newVault.depositor = msg.sender;
        newVault.asset = _asset;
        newVault.amount = _amount;
        newVault.isEth = isEth;
        newVault.state = VaultState.Locked;
        newVault.conditions = _conditions;
        newVault.conditions.conditionsConfigured = true; // Lock conditions except flexible ones

        emit VaultCreated(vaultId, msg.sender, _asset, _amount, _conditions.unlockTime);
        emit VaultStateChanged(vaultId, VaultState.Locked, VaultState.Locked);
    }

    /// @notice Adds more assets to an existing vault.
    /// @param _vaultId The ID of the vault to add assets to.
    /// @param _amount The amount of assets to add.
    function addToVault(bytes32 _vaultId, uint256 _amount)
        external
        payable
        whenNotPaused
        vaultExists(_vaultId)
        vaultInState(_vaultId, VaultState.Locked)
        onlyDepositor(_vaultId)
    {
        require(_amount > 0, "Amount must be > 0");
        Vault storage vault = vaults[_vaultId];

        if (vault.isEth) {
            require(msg.value == _amount, "ETH amount mismatch");
        } else {
            require(msg.value == 0, "Do not send ETH for token vault");
            require(msg.sender == vault.depositor, "Only depositor can add tokens"); // Double check depositor for token adds
            // ERC20 transferFrom must be called by this contract
            bool success = IERC20(vault.asset).transferFrom(msg.sender, address(this), _amount);
            require(success, "Token transfer failed");
            totalVaultErc20Balances[vault.asset] += _amount; // Track total held
        }

        vault.amount += _amount;

        emit AssetAddedToVault(_vaultId, vault.asset, _amount);
    }

    /// @notice Attempts to unlock a vault by checking all release conditions.
    /// @param _vaultId The ID of the vault to attempt unlocking.
    /// @param _futureProofPreimage The pre-image for the future proof condition, if required.
    function attemptUnlock(bytes32 _vaultId, bytes calldata _futureProofPreimage)
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultInState(_vaultId, VaultState.Locked) // Can only attempt unlock from Locked
    {
        Vault storage vault = vaults[_vaultId];
        vault.conditions.futureProofPreimage = _futureProofPreimage; // Provide preimage for check

        // Check if all conditions are met
        bool allMet = _checkAllConditions(_vaultId);

        // Clean up the provided preimage immediately after check for privacy
        delete vault.conditions.futureProofPreimage;

        if (allMet) {
            // Transition state
            VaultState oldState = vault.state;
            vault.state = VaultState.Unlocked;
            emit VaultStateChanged(_vaultId, VaultState.Unlocked, oldState);

            // Transfer assets to the depositor
            if (vault.isEth) {
                (bool success, ) = payable(vault.depositor).call{value: vault.amount}("");
                require(success, "ETH transfer failed");
            } else {
                // Manual ERC20 transfer, checking return value
                bytes memory payload = abi.encodeWithSelector(IERC20.transfer.selector, vault.depositor, vault.amount);
                (bool success, bytes memory retdata) = address(vault.asset).call(payload);
                require(success, "Token transfer failed (call)");
                // Optional: Check retdata if the token implements EIP-20 `transfer` correctly (returns bool)
                if (retdata.length > 0) {
                     require(abi.decode(retdata, (bool)), "Token transfer failed (retdata)");
                }
                totalVaultErc20Balances[vault.asset] -= vault.amount; // Update total held
            }

            emit VaultUnlocked(_vaultId, vault.depositor, vault.asset, vault.amount);

            // Vault is now Unlocked, amount is zeroed out conceptually after transfer.
            // Keep the vault struct for historical lookups, state indicates it's unlocked.

        } else {
             // If not all conditions met, it remains Locked or could transition to PendingUnlock if applicable
             // For simplicity, we keep it Locked unless a specific condition check implies PendingUnlock state
             // (like requiring multisig confirmations). The current design keeps it Locked until *all* are met.
             // Could add a PendingUnlock state transition here if *some* complex conditions are met.
             // Let's add a PendingUnlock state check function later.
        }
    }

    /// @notice Allows the depositor to cancel a vault and reclaim assets under specific constraints.
    /// @dev Cancellation might only be possible before the unlockTime is reached.
    /// @param _vaultId The ID of the vault to cancel.
    function cancelVault(bytes32 _vaultId)
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultInState(_vaultId, VaultState.Locked) // Can only cancel from Locked
        onlyDepositor(_vaultId)
    {
        Vault storage vault = vaults[_vaultId];

        // --- Cancellation Condition: Must be before unlock time ---
        require(block.timestamp < vault.conditions.unlockTime, "Cannot cancel after unlock time");

        VaultState oldState = vault.state;
        vault.state = VaultState.Cancelled;
        emit VaultStateChanged(_vaultId, VaultState.Cancelled, oldState);

        // Transfer assets back to the depositor
        if (vault.isEth) {
            (bool success, ) = payable(vault.depositor).call{value: vault.amount}("");
            require(success, "ETH transfer failed on cancel");
        } else {
            // Manual ERC20 transfer, checking return value
            bytes memory payload = abi.encodeWithSelector(IERC20.transfer.selector, vault.depositor, vault.amount);
            (bool success, bytes memory retdata) = address(vault.asset).call(payload);
            require(success, "Token transfer failed on cancel (call)");
            if (retdata.length > 0) {
                 require(abi.decode(retdata, (bool)), "Token transfer failed on cancel (retdata)");
            }
            totalVaultErc20Balances[vault.asset] -= vault.amount; // Update total held
        }

        emit VaultCancelled(_vaultId, vault.depositor, vault.asset, vault.amount);

        // Vault is now Cancelled, amount is zeroed out conceptually.
    }

    // --- Condition Input/Trigger Functions ---

    /// @notice Allows updating certain flexible conditions for a vault *before* unlock time.
    /// @dev This demonstrates conditions that can adapt before the main unlock window.
    /// @param _vaultId The ID of the vault.
    /// @param _newUnlockTime A new unlock time (must be in the future).
    /// @param _newProbabilisticProbabilityBasisPoints A new probability for the probabilistic condition (0-10000).
    function updateFlexibleConditions(
        bytes32 _vaultId,
        uint64 _newUnlockTime,
        uint256 _newProbabilisticProbabilityBasisPoints
    )
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultInState(_vaultId, VaultState.Locked)
        onlyDepositor(_vaultId)
    {
        Vault storage vault = vaults[_vaultId];

        // Cannot update if the original unlock time has passed
        require(block.timestamp < vault.conditions.unlockTime, "Original unlock time already passed");
        require(_newUnlockTime > block.timestamp, "New unlock time must be in the future");
        require(_newProbabilisticProbabilityBasisPoints <= 10000, "Probability must be between 0 and 10000");

        vault.conditions.unlockTime = _newUnlockTime;
        vault.conditions.probabilisticProbabilityBasisPoints = _newProbabilisticProbabilityBasisPoints;

        emit FlexibleConditionsUpdated(_vaultId, _newUnlockTime, _newProbabilisticProbabilityBasisPoints);
    }

    /// @notice Provides external data for a vault's condition.
    /// @dev The provided data must match the hash stored in the conditions.
    /// @param _vaultId The ID of the vault.
    /// @param _data The external data.
    function provideExternalData(bytes32 _vaultId, bytes calldata _data)
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultInState(_vaultId, VaultState.Locked) // Data must be provided before unlock attempt/state change
    {
        Vault storage vault = vaults[_vaultId];
        // Optional: Restrict to authorized provider
        if (authorisedExternalDataProvider != address(0)) {
            require(msg.sender == authorisedExternalDataProvider || msg.sender == owner, "Not authorized to provide external data");
        }

        require(vault.conditions.submittedExternalData.length == 0, "External data already submitted");
        require(keccak256(_data) == vault.conditions.requiredExternalDataHash, "External data hash mismatch");

        vault.conditions.submittedExternalData = _data;

        emit ExternalDataProvided(_vaultId, _data, true);
    }

    /// @notice Reveals the pre-image for the future proof hash condition.
    /// @param _vaultId The ID of the vault.
    /// @param _preimage The secret pre-image.
    function revealFutureProofPreimage(bytes32 _vaultId, bytes calldata _preimage)
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultInState(_vaultId, VaultState.Locked)
    {
        Vault storage vault = vaults[_vaultId];
        // Optional: Restrict who can reveal (e.g., depositor or a designated revealer address in conditions struct)
        // For now, let's allow anyone to reveal if the hash matches, mirroring some hash-puzzle concepts.
        // Could add `require(msg.sender == vault.depositor, "Only depositor can reveal");` if needed.

        require(vault.conditions.futureProofPreimage.length == 0, "Preimage already revealed");
        require(keccak256(_preimage) == vault.conditions.futureProofUnlockHash, "Preimage hash mismatch");

        vault.conditions.futureProofPreimage = _preimage;

        emit FutureProofPreimageRevealed(_vaultId, _preimage);
    }

    /// @notice Submits a confirmation for the multisig condition.
    /// @param _vaultId The ID of the vault.
    function submitMultisigConfirmation(bytes32 _vaultId)
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultInState(_vaultId, VaultState.Locked)
    {
        Vault storage vault = vaults[_vaultId];
        bool isSigner = false;
        for (uint i = 0; i < vault.conditions.multisigSigners.length; i++) {
            if (vault.conditions.multisigSigners[i] == msg.sender) {
                isSigner = true;
                break;
            }
        }
        require(isSigner, "Not a designated multisig signer");
        require(!vault.conditions.multisigConfirmed[msg.sender], "Confirmation already submitted");

        vault.conditions.multisigConfirmed[msg.sender] = true;

        emit MultisigConfirmationSubmitted(_vaultId, msg.sender);
    }

    /// @notice Sets the seed for the probabilistic condition.
    /// @dev This should typically be called by an oracle or keeper after external randomness is available.
    /// @param _vaultId The ID of the vault.
    /// @param _seed The seed value (e.g., VRF output).
    function setProbabilisticSeed(bytes32 _vaultId, bytes32 _seed)
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultInState(_vaultId, VaultState.Locked)
    {
        Vault storage vault = vaults[_vaultId];
        // Optional: Restrict to authorized provider
        if (authorisedProbabilisticSeedProvider != address(0)) {
            require(msg.sender == authorisedProbabilisticSeedProvider || msg.sender == owner, "Not authorized to set probabilistic seed");
        }

        require(!vault.conditions.probabilisticOutcomeDetermined, "Probabilistic seed already set");

        vault.conditions.probabilisticSeed = _seed;
        vault.conditions.probabilisticOutcomeDetermined = true; // Lock the seed input

        emit ProbabilisticSeedSet(_vaultId, _seed);
    }

    /// @notice Updates the internal state value used for condition 7.
    /// @dev This value represents a potentially dynamic state within the contract or system.
    /// @param _newValue The new value for the internal state.
    function setInternalStateValue(uint256 _newValue)
        external
        whenNotPaused
        onlyAuthorized(authorisedInternalStateUpdater) // Owner is also authorized by default
    {
        uint256 oldValue = currentInternalStateValue;
        currentInternalStateValue = _newValue;
        emit InternalStateUpdated(oldValue, _newValue);
    }


    // --- Configuration/Authorization Functions ---

    /// @notice Owner function to set or unset the authorized address for providing external data.
    function setAuthorisedExternalDataProvider(address _provider) external onlyOwner {
        authorisedExternalDataProvider = _provider;
    }

    /// @notice Owner function to set or unset the authorized address for setting probabilistic seeds.
    function setAuthorisedProbabilisticSeedProvider(address _provider) external onlyOwner {
        authorisedProbabilisticSeedProvider = _provider;
    }

    /// @notice Owner function to set or unset the authorized address for updating the internal state value.
    function setAuthorisedInternalStateUpdater(address _updater) external onlyOwner {
        authorisedInternalStateUpdater = _updater;
    }


    // --- View Functions ---

    /// @notice Gets all details for a specific vault.
    /// @param _vaultId The ID of the vault.
    /// @return Vault struct containing all vault data.
    function getVaultDetails(bytes32 _vaultId) external view vaultExists(_vaultId) returns (Vault memory) {
        return vaults[_vaultId];
    }

    /// @notice Gets the current state of a specific vault.
    /// @param _vaultId The ID of the vault.
    /// @return The VaultState enum value.
    function getVaultState(bytes32 _vaultId) external view vaultExists(_vaultId) returns (VaultState) {
        return vaults[_vaultId].state;
    }

    /// @notice Checks the status of each individual condition for a vault. Does not attempt unlock.
    /// @dev Returns a boolean array indicating which conditions are currently met.
    ///      Order: [UnlockTime, ExternalData, Probabilistic, LinkedVault, FutureProof, Multisig, InternalState, NegativeCondition]
    /// @param _vaultId The ID of the vault.
    /// @return bool[8] Array of booleans indicating if each condition type is met.
    function checkConditionsMet(bytes32 _vaultId) external view vaultExists(_vaultId) returns (bool[8] memory) {
        Vault storage vault = vaults[_vaultId];
        ReleaseConditions storage conditions = vault.conditions;
        bool[8] memory metStatus;

        // Condition 1: Unlock Time
        metStatus[0] = (block.timestamp >= conditions.unlockTime);

        // Condition 2: External Data
        metStatus[1] = (conditions.requiredExternalDataHash == bytes32(0) || (conditions.submittedExternalData.length > 0 && keccak256(conditions.submittedExternalData) == conditions.requiredExternalDataHash));

        // Condition 3: Probabilistic
        metStatus[2] = (conditions.probabilisticProbabilityBasisPoints == 0 || (conditions.probabilisticOutcomeDetermined && _checkProbabilisticCondition(vault.probabilisticSeed, conditions.probabilisticProbabilityBasisPoints)));

        // Condition 4: Linked Vault
        metStatus[3] = (conditions.linkedVaultId == bytes32(0) || (vaults[conditions.linkedVaultId].id != bytes32(0) && vaults[conditions.linkedVaultId].state == VaultState.Unlocked));

        // Condition 5: Future Proof
        metStatus[4] = (conditions.futureProofUnlockHash == bytes32(0) || (conditions.futureProofPreimage.length > 0 && keccak256(conditions.futureProofPreimage) == conditions.futureProofUnlockHash));

        // Condition 6: Multisig
        uint256 confirmedCount = 0;
        for (uint i = 0; i < conditions.multisigSigners.length; i++) {
            if (conditions.multisigConfirmed[conditions.multisigSigners[i]]) {
                confirmedCount++;
            }
        }
        metStatus[5] = (conditions.multisigSigners.length == 0 || confirmedCount >= conditions.requiredConfirmations);

        // Condition 7: Internal State
        metStatus[6] = (conditions.requiredInternalStateValue == 0 || currentInternalStateValue >= conditions.requiredInternalStateValue);

        // Condition 8: Negative Condition
        metStatus[7] = (conditions.negativeConditionDeadline == 0 || block.timestamp < conditions.negativeConditionDeadline || !conditions.negativeConditionMet);
        // If deadline passed and negative condition *was NOT* met, this condition is met.
        // If deadline not passed, or deadline passed and negative condition *was* met, this condition is NOT met.

        return metStatus;
    }

    /// @notice Gets the required signers and confirmation status for the multisig condition.
    /// @param _vaultId The ID of the vault.
    /// @return signers Array of signer addresses.
    /// @return confirmedStatuses Array of booleans indicating if each signer has confirmed.
    /// @return required The number of required confirmations.
    function getMultisigStatus(bytes32 _vaultId) external view vaultExists(_vaultId) returns (address[] memory signers, bool[] memory confirmedStatuses, uint256 required) {
        Vault storage vault = vaults[_vaultId];
        signers = vault.conditions.multisigSigners;
        required = vault.conditions.requiredConfirmations;
        confirmedStatuses = new bool[](signers.length);
        for (uint i = 0; i < signers.length; i++) {
            confirmedStatuses[i] = vault.conditions.multisigConfirmed[signers[i]];
        }
        return (signers, confirmedStatuses, required);
    }

    /// @notice Gets the contract's current ETH balance.
    function getContractEthBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Gets the contract's total balance for a specific ERC20 token held across all vaults.
    /// @param _tokenAddress The address of the ERC20 token.
    function getContractTokenBalance(address _tokenAddress) external view returns (uint256) {
        return totalVaultErc20Balances[_tokenAddress];
    }

    /// @notice Gets the current value of the internal state variable used in condition 7.
    function getInternalStateValue() external view returns (uint256) {
        return currentInternalStateValue;
    }


    // --- Admin Functions ---

    /// @notice Transfers contract ownership.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    /// @notice Pauses contract operations.
    /// @dev Only owner can pause. Affects functions modified with `whenNotPaused`.
    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    /// @notice Unpauses contract operations.
    /// @dev Only owner can unpause.
    function unpause() external onlyOwner whenPaused {
        paused = false;
    }

    /// @notice Allows the owner to withdraw ERC20 tokens sent to the contract address that are not associated with any active vault.
    /// @dev Useful for recovering tokens sent by mistake or dust.
    /// @param _tokenAddress The address of the ERC20 token.
    /// @param _recipient The address to send the tokens to.
    function withdrawExcessTokens(address _tokenAddress, address _recipient) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_recipient != address(0), "Invalid recipient address");

        uint256 contractTokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
        uint256 vaultLockedBalance = totalVaultErc20Balances[_tokenAddress];
        uint256 withdrawableAmount = contractTokenBalance - vaultLockedBalance; // Amount not tracked by vaults

        require(withdrawableAmount > 0, "No excess tokens to withdraw");

        // Manual ERC20 transfer, checking return value
        bytes memory payload = abi.encodeWithSelector(IERC20.transfer.selector, _recipient, withdrawableAmount);
        (bool success, bytes memory retdata) = address(_tokenAddress).call(payload);
        require(success, "Excess token transfer failed (call)");
        if (retdata.length > 0) {
             require(abi.decode(retdata, (bool)), "Excess token transfer failed (retdata)");
        }

        emit ExcessTokenWithdrawn(_tokenAddress, _recipient, withdrawableAmount);
    }


    // --- Internal Helper Functions ---

    /// @notice Checks if all required conditions for a vault are met.
    /// @param _vaultId The ID of the vault.
    /// @return bool True if all conditions are met, false otherwise.
    function _checkAllConditions(bytes32 _vaultId) internal view returns (bool) {
        Vault storage vault = vaults[_vaultId];
        ReleaseConditions storage conditions = vault.conditions;

        // Condition 1: Unlock Time
        if (block.timestamp < conditions.unlockTime) {
            return false;
        }

        // Condition 2: External Data
        if (conditions.requiredExternalDataHash != bytes32(0) && (conditions.submittedExternalData.length == 0 || keccak256(conditions.submittedExternalData) != conditions.requiredExternalDataHash)) {
             return false;
        }

        // Condition 3: Probabilistic
        // If probability > 0, requires seed set and outcome to be success
        if (conditions.probabilisticProbabilityBasisPoints > 0 && (!conditions.probabilisticOutcomeDetermined || !_checkProbabilisticCondition(conditions.probabilisticSeed, conditions.probabilisticProbabilityBasisPoints))) {
            return false;
        }

        // Condition 4: Linked Vault
        if (conditions.linkedVaultId != bytes32(0)) {
            // Require linked vault to exist and be Unlocked
            if (vaults[conditions.linkedVaultId].id == bytes32(0) || vaults[conditions.linkedVaultId].state != VaultState.Unlocked) {
                return false;
            }
        }

        // Condition 5: Future Proof
        if (conditions.futureProofUnlockHash != bytes32(0) && (conditions.futureProofPreimage.length == 0 || keccak256(conditions.futureProofPreimage) != conditions.futureProofUnlockHash)) {
            return false;
        }

        // Condition 6: Multisig
        if (conditions.multisigSigners.length > 0) {
            uint256 confirmedCount = 0;
            for (uint i = 0; i < conditions.multisigSigners.length; i++) {
                if (conditions.multisigConfirmed[conditions.multisigSigners[i]]) {
                    confirmedCount++;
                }
            }
            if (confirmedCount < conditions.requiredConfirmations) {
                return false;
            }
        }

        // Condition 7: Internal State
        if (conditions.requiredInternalStateValue > 0 && currentInternalStateValue < conditions.requiredInternalStateValue) {
             return false;
        }

        // Condition 8: Negative Condition
        // If deadline passed AND negative condition *was* met, this condition fails.
        // If deadline not passed, or deadline passed and negative condition *was NOT* met, this condition is met (passes).
        if (conditions.negativeConditionDeadline > 0 && block.timestamp >= conditions.negativeConditionDeadline && conditions.negativeConditionMet) {
             return false;
        }


        // If all checks passed
        return true;
    }

    /// @notice Determines the outcome of the probabilistic condition based on the seed.
    /// @dev Uses a simple hash-based probability check. NOT cryptographically secure randomness on its own.
    ///      Relies on an external entity providing a truly random seed (e.g., VRF).
    /// @param _seed The random seed (e.g., from Chainlink VRF).
    /// @param _probabilityBasisPoints Probability in basis points (0-10000).
    /// @return bool True if the outcome is successful based on probability.
    function _checkProbabilisticCondition(bytes32 _seed, uint256 _probabilityBasisPoints) internal pure returns (bool) {
        if (_probabilityBasisPoints == 0) return false; // 0% chance never succeeds
        if (_probabilityBasisPoints == 10000) return true; // 100% chance always succeeds

        // Use the seed to get a random number between 0 and 9999
        uint256 randomValue = uint256(keccak256(abi.encodePacked(_seed))) % 10000;

        // Check if the random value is within the success range
        return randomValue < _probabilityBasisPoints;
    }

    // --- Receiver function to accept ETH ---
    receive() external payable {
        // This allows the contract to receive raw ETH transfers.
        // However, ETH deposits should primarily go through createVault or addToVault
        // with an explicit amount. Any raw ETH sent here without a function call
        // will increase the contract's balance but won't be tracked in any vault.
        // Owner can withdraw such excess ETH (or it could be lost if no withdrawal mechanism).
        // We could add a `withdrawExcessEth` function similar to `withdrawExcessTokens` if needed.
        // For this design, excess ETH is effectively locked unless owner can withdraw.
        // Let's assume this is fine or a future upgrade adds excess ETH withdrawal.
    }

    // --- Interface for ERC20 ---
    interface IERC20 {
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function balanceOf(address account) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
    }
}
```