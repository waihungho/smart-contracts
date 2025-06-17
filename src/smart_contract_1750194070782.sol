Okay, let's design an advanced, creative, and potentially trendy smart contract. We'll call it "QuantumVault".

The core concept is that assets (ERC20 or ERC721) deposited into this vault can be unlocked via *multiple potential conditions*. It's like putting an asset into "superposition" where several "quantum branches" (unlock gates) exist simultaneously. The *first* condition to be verifiably met and triggered collapses the state, unlocks the asset via that specific "gate", and potentially rewards the entity that triggered it.

This allows for complex conditional releases, multi-party coordination requirements, integration with external data (via oracles/handlers), and even incentivized unlocking.

Here's the structure and code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive ERC721
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // To track user vault IDs

// --- Outline & Function Summary ---
//
// Contract Name: QuantumVault
// Description: A vault contract allowing users to deposit ERC20 or ERC721 assets
//              that can be unlocked via one of multiple predefined conditional "gates".
//              The first gate whose condition is met and triggered unlocks the asset.
//              Features include conditional unlocking, external handler integration,
//              incentives for triggering, and granular vault management.
//
// Data Structures:
// - Vault: Stores details of a deposited asset (owner, type, token info, status, gates).
// - UnlockGate: Defines a single potential unlock condition (type, parameters, status, bounty).
// - AssetType: Enum for differentiating ERC20/ERC721.
// - VaultStatus: Enum for tracking the vault's state (Locked, Unlocked, Cancelled, Expired).
// - GateType: Enum representing different types of unlock conditions (Time, Block, Signature, Oracle, etc.). Extendable via handlers.
// - GateStatus: Enum for tracking a gate's state (Pending, Observable, Triggered, Failed, Revoked).
//
// Key Concepts:
// - Multi-conditional Unlock: Assets can have multiple paths to unlocking.
// - Quantum Collapse: The first successful trigger of a gate determines the unlock path and state.
// - External Handlers: Gate conditions can be checked by pluggable external contracts.
// - Incentivized Triggering: Bounties can be offered for triggering complex gates.
// - Vault Expiry: Optional expiry date for vaults.
//
// Functions (25+):
//
// Core Vault Management:
// 1. depositERC20: Deposit ERC20 tokens into a new vault.
// 2. depositERC721: Deposit an ERC721 token into a new vault.
// 3. withdraw: Withdraw unlocked assets from a vault.
// 4. cancelDeposit: Cancel a deposit if no gate has been triggered (potentially with conditions).
// 5. extendVaultExpiry: Extend the overall expiry block of a vault.
// 6. checkVaultStatus: Get the current status of a vault.
// 7. isVaultLocked: Check if a vault is currently locked.
// 8. getUserVaultIds: Get a list of vault IDs owned by a user.
//
// Unlock Gate Management:
// 9. addUnlockGate: Add a new potential unlock gate/condition to an existing vault.
// 10. removeUnlockGate: Remove a gate if it hasn't been triggered or become observable.
// 11. viewUnlockGate: Get details of a specific gate within a vault.
// 12. getVaultGateCount: Get the total number of gates associated with a vault.
// 13. getGateStatus: Get the current status of a specific gate.
// 14. setGateBounty: Set a bounty for successfully triggering a specific gate (by vault owner).
// 15. revokeGate: Revoke a gate condition (by vault owner, if permitted by gate type/status).
//
// Gate Triggering & Execution:
// 16. attemptTriggerGate: Anyone can attempt to trigger a specific gate by providing proof/data. Checks the condition via handler.
// 17. checkGateCondition: Pure/view function to check a gate's condition without state changes (calls handler read-only).
// 18. findAndTriggerAnyObservableGate: Attempts to find and trigger any valid, observable gate for a vault.
// 19. claimGateBounty: Allows the address that successfully triggered a gate to claim its bounty.
//
// External Handler Management (Owner Only):
// 20. setGateTypeHandler: Register/update the contract address responsible for handling a specific GateType.
// 21. getGateTypeHandler: Get the address of the handler contract for a specific GateType.
//
// Contract Administration (Owner Only):
// 22. pause: Pause the contract.
// 23. unpause: Unpause the contract.
// 24. emergencyWithdrawERC20: Owner emergency withdraw of a specific ERC20 (security failsafe).
// 25. emergencyWithdrawERC721: Owner emergency withdraw of a specific ERC721 (security failsafe).
// 26. transferOwnership: Transfer contract ownership.

// --- External Interfaces ---

// Interface for pluggable condition handlers
interface IGateConditionHandler {
    // Checks if the condition for a specific gate is met.
    // Implementations should be pure or view functions.
    // @param vaultId The ID of the vault.
    // @param gateIndex The index of the gate within the vault.
    // @param vault The Vault struct data.
    // @param gate The UnlockGate struct data.
    // @param proofData Any external data/signature needed to verify the condition.
    // @return bool True if the condition is met, false otherwise.
    function checkCondition(
        uint256 vaultId,
        uint256 gateIndex,
        QuantumVault.Vault memory vault, // Pass memory copy of structs
        QuantumVault.UnlockGate memory gate,
        bytes calldata proofData
    ) external view returns (bool);
}

// --- Contract Definition ---

contract QuantumVault is ERC721Holder, ReentrancyGuard, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    // --- State Variables ---

    enum AssetType { ERC20, ERC721 }
    enum VaultStatus { Locked, Unlocked, Cancelled, Expired }
    // Add new GateTypes here and register handlers for them
    enum GateType {
        TimeBased,          // Unlock after a specific timestamp
        BlockNumberBased,   // Unlock after a specific block number
        SignatureBased,     // Unlock with a valid signature
        OracleDataBased,    // Unlock based on data from a registered oracle feed (e.g., Chainlink)
        SpecificAddressCall, // Unlock if a specific address calls the gate
        MerkleProofBased    // Unlock with a valid Merkle proof
        // ... potentially many more types
    }
    enum GateStatus { Pending, Observable, Triggered, Failed, Revoked }

    struct UnlockGate {
        GateType gateType;
        bytes parameters;   // Encoded data specific to the gate type (e.g., timestamp, block number, address, hash)
        GateStatus status;
        uint256 bountyAmount; // Optional bounty in native token (ETH/MATIC) for triggering this gate
        address triggerer;    // Address that successfully triggered this gate
    }

    struct Vault {
        uint256 vaultId;
        address owner;
        AssetType assetType;
        address tokenAddress;
        uint256 amountOrTokenId; // Amount for ERC20, tokenId for ERC721
        VaultStatus status;
        UnlockGate[] unlockGates;
        int256 triggeredGateIndex; // -1 if not triggered, index otherwise
        uint256 expiryBlock;      // Vault expires if not triggered by this block (0 for no expiry)
        uint256 createdAtBlock;   // Block number when the vault was created
    }

    mapping(uint256 => Vault) private vaults;
    uint256 private nextVaultId = 1;

    // Mapping from user address to set of vault IDs they own
    mapping(address => EnumerableSet.UintSet) private userVaults;

    // Mapping from GateType to the address of the handler contract responsible for checking its condition
    mapping(GateType => address) private gateTypeHandlers;

    // Mapping to track claimed bounties to prevent double claiming
    mapping(uint256 => mapping(uint256 => bool)) private claimedBounties; // vaultId => gateIndex => claimed

    // --- Events ---

    event VaultCreated(uint256 indexed vaultId, address indexed owner, AssetType assetType, address tokenAddress, uint256 amountOrTokenId);
    event VaultStatusChanged(uint256 indexed vaultId, VaultStatus newStatus);
    event UnlockGateAdded(uint256 indexed vaultId, uint256 indexed gateIndex, GateType gateType, bytes parameters);
    event UnlockGateStatusChanged(uint256 indexed vaultId, uint256 indexed gateIndex, GateStatus newStatus);
    event GateTriggered(uint256 indexed vaultId, uint256 indexed gateIndex, address indexed triggerer);
    event AssetWithdrawn(uint256 indexed vaultId, address indexed recipient, uint256 amountOrTokenId);
    event VaultCancelled(uint256 indexed vaultId);
    event VaultExpired(uint256 indexed vaultId);
    event GateBountySet(uint256 indexed vaultId, uint256 indexed gateIndex, uint256 bountyAmount);
    event GateBountyClaimed(uint256 indexed vaultId, uint256 indexed gateIndex, address indexed triggerer, uint256 amount);
    event GateHandlerSet(GateType indexed gateType, address indexed handlerAddress);

    // --- Modifiers ---

    modifier vaultExists(uint256 _vaultId) {
        require(vaults[_vaultId].vaultId == _vaultId, "Vault does not exist");
        _;
    }

    modifier vaultIsLocked(uint256 _vaultId) {
        require(vaults[_vaultId].status == VaultStatus.Locked, "Vault must be locked");
        _;
    }

    modifier vaultIsUnlocked(uint256 _vaultId) {
        require(vaults[_vaultId].status == VaultStatus.Unlocked, "Vault must be unlocked");
        _;
    }

    modifier vaultOwnerOnly(uint256 _vaultId) {
        require(vaults[_vaultId].owner == msg.sender, "Not vault owner");
        _;
    }

    modifier gateExists(uint256 _vaultId, uint256 _gateIndex) {
        require(_gateIndex < vaults[_vaultId].unlockGates.length, "Gate does not exist");
        _;
    }

    modifier gateIsPending(uint256 _vaultId, uint256 _gateIndex) {
        require(vaults[_vaultId].unlockGates[_gateIndex].status == GateStatus.Pending, "Gate must be pending");
        _;
    }

    modifier gateIsTriggered(uint256 _vaultId, uint256 _gateIndex) {
        require(vaults[_vaultId].unlockGates[_gateIndex].status == GateStatus.Triggered, "Gate must be triggered");
        _;
    }

    modifier gateHasHandler(GateType _gateType) {
        require(gateTypeHandlers[_gateType] != address(0), "No handler registered for this gate type");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable(false) {}

    // --- Receive Ether for Bounties ---
    receive() external payable {}
    fallback() external payable {}

    // --- Core Vault Management ---

    /**
     * @notice Deposits ERC20 tokens into a new vault.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     * @param _unlockGates Initial set of unlock gates for the vault. Can be empty and added later.
     * @param _expiryBlock Optional block number after which the vault expires if not unlocked. 0 for no expiry.
     * @return vaultId The ID of the newly created vault.
     */
    function depositERC20(
        address _tokenAddress,
        uint256 _amount,
        UnlockGate[] calldata _unlockGates,
        uint256 _expiryBlock
    ) external nonReentrant whenNotPaused returns (uint256) {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be > 0");
        require(_expiryBlock >= block.number || _expiryBlock == 0, "Expiry block must be in the future or 0");

        // Transfer tokens into the contract
        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "ERC20 transfer failed");

        uint256 currentVaultId = nextVaultId++;
        Vault storage newVault = vaults[currentVaultId];

        newVault.vaultId = currentVaultId;
        newVault.owner = msg.sender;
        newVault.assetType = AssetType.ERC20;
        newVault.tokenAddress = _tokenAddress;
        newVault.amountOrTokenId = _amount;
        newVault.status = VaultStatus.Locked;
        // Deep copy gates array elements manually to storage
        newVault.unlockGates.length = _unlockGates.length;
        for (uint i = 0; i < _unlockGates.length; i++) {
            newVault.unlockGates[i].gateType = _unlockGates[i].gateType;
            newVault.unlockGates[i].parameters = _unlockGates[i].parameters;
            newVault.unlockGates[i].status = GateStatus.Pending; // Gates start as Pending
            newVault.unlockGates[i].bountyAmount = _unlockGates[i].bountyAmount; // Set initial bounty
        }
        newVault.triggeredGateIndex = -1;
        newVault.expiryBlock = _expiryBlock;
        newVault.createdAtBlock = block.number;

        userVaults[msg.sender].add(currentVaultId);

        emit VaultCreated(currentVaultId, msg.sender, AssetType.ERC20, _tokenAddress, _amount);
        emit VaultStatusChanged(currentVaultId, VaultStatus.Locked);

        return currentVaultId;
    }

    /**
     * @notice Deposits an ERC721 token into a new vault.
     * @param _tokenAddress The address of the ERC721 token.
     * @param _tokenId The ID of the token to deposit.
     * @param _unlockGates Initial set of unlock gates for the vault. Can be empty and added later.
     * @param _expiryBlock Optional block number after which the vault expires if not unlocked. 0 for no expiry.
     * @return vaultId The ID of the newly created vault.
     */
    function depositERC721(
        address _tokenAddress,
        uint256 _tokenId,
        UnlockGate[] calldata _unlockGates,
        uint256 _expiryBlock
    ) external nonReentrant whenNotPaused returns (uint256) {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_tokenId > 0, "Token ID must be > 0"); // Assuming non-zero token IDs for ERC721
        require(_expiryBlock >= block.number || _expiryBlock == 0, "Expiry block must be in the future or 0");

        // Transfer token into the contract
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == msg.sender, "Caller must own the token");
        token.safeTransferFrom(msg.sender, address(this), _tokenId);

        uint256 currentVaultId = nextVaultId++;
        Vault storage newVault = vaults[currentVaultId];

        newVault.vaultId = currentVaultId;
        newVault.owner = msg.sender;
        newVault.assetType = AssetType.ERC721;
        newVault.tokenAddress = _tokenAddress;
        newVault.amountOrTokenId = _tokenId;
        newVault.status = VaultStatus.Locked;
         // Deep copy gates array elements manually to storage
        newVault.unlockGates.length = _unlockGates.length;
        for (uint i = 0; i < _unlockGates.length; i++) {
            newVault.unlockGates[i].gateType = _unlockGates[i].gateType;
            newVault.unlockGates[i].parameters = _unlockGates[i].parameters;
            newVault.unlockGates[i].status = GateStatus.Pending; // Gates start as Pending
            newVault.unlockGates[i].bountyAmount = _unlockGates[i].bountyAmount; // Set initial bounty
        }
        newVault.triggeredGateIndex = -1;
        newVault.expiryBlock = _expiryBlock;
        newVault.createdAtBlock = block.number;

        userVaults[msg.sender].add(currentVaultId);

        emit VaultCreated(currentVaultId, msg.sender, AssetType.ERC721, _tokenAddress, _tokenId);
         emit VaultStatusChanged(currentVaultId, VaultStatus.Locked);

        return currentVaultId;
    }

    /**
     * @notice Allows the vault owner to withdraw assets if the vault is unlocked or cancelled.
     * @param _vaultId The ID of the vault to withdraw from.
     */
    function withdraw(uint256 _vaultId)
        external
        nonReentrant
        whenNotPaused
        vaultExists(_vaultId)
        vaultOwnerOnly(_vaultId)
    {
        Vault storage vault = vaults[_vaultId];
        require(
            vault.status == VaultStatus.Unlocked || vault.status == VaultStatus.Cancelled || vault.status == VaultStatus.Expired,
            "Vault is still locked or in invalid state"
        );

        if (vault.assetType == AssetType.ERC20) {
            IERC20 token = IERC20(vault.tokenAddress);
            require(token.transfer(vault.owner, vault.amountOrTokenId), "ERC20 withdrawal failed");
        } else if (vault.assetType == AssetType.ERC721) {
             IERC721 token = IERC721(vault.tokenAddress);
            // Use safeTransferFrom according to ERC721 standard
            token.safeTransferFrom(address(this), vault.owner, vault.amountOrTokenId);
        }

        // Clean up vault data after withdrawal
        userVaults[vault.owner].remove(_vaultId);
        delete vaults[_vaultId]; // Delete vault data to save gas

        emit AssetWithdrawn(_vaultId, vault.owner, vault.amountOrTokenId);
    }

    /**
     * @notice Allows the vault owner to cancel a deposit if no gate has been triggered.
     *         Can be subject to conditions (e.g., after a minimum lock-up time, or before expiry).
     * @param _vaultId The ID of the vault to cancel.
     */
    function cancelDeposit(uint256 _vaultId)
        external
        nonReentrant
        whenNotPaused
        vaultExists(_vaultId)
        vaultOwnerOnly(_vaultId)
        vaultIsLocked(_vaultId) // Only locked vaults can be cancelled
    {
        Vault storage vault = vaults[_vaultId];

        // --- Custom Cancellation Logic Here ---
        // Example: Only allow cancellation after 100 blocks AND before expiry
        // require(block.number >= vault.createdAtBlock + 100, "Minimum lock-up period not passed");
        // require(vault.expiryBlock == 0 || block.number < vault.expiryBlock, "Cannot cancel after expiry");
        // For simplicity, let's allow cancellation anytime before trigger/expiry for now:
        // require(vault.triggeredGateIndex == -1, "Cannot cancel after a gate is triggered");
        // The vaultIsLocked modifier already covers that triggeredGateIndex is -1 implicitly.
        // --------------------------------------

        vault.status = VaultStatus.Cancelled;
        emit VaultCancelled(_vaultId);
        emit VaultStatusChanged(_vaultId, VaultStatus.Cancelled);

        // The owner can now call withdraw() to retrieve assets.
    }

     /**
     * @notice Allows the vault owner to extend the expiry block of a vault.
     * @param _vaultId The ID of the vault.
     * @param _newExpiryBlock The new expiry block number. Must be in the future.
     */
    function extendVaultExpiry(uint256 _vaultId, uint256 _newExpiryBlock)
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultOwnerOnly(_vaultId)
        vaultIsLocked(_vaultId) // Only locked vaults can have expiry extended
    {
        Vault storage vault = vaults[_vaultId];
        require(_newExpiryBlock > block.number, "New expiry block must be in the future");
        require(_newExpiryBlock > vault.expiryBlock, "New expiry block must be later than current");

        vault.expiryBlock = _newExpiryBlock;
        // No specific event for expiry update, Vault info can be queried.
    }


    /**
     * @notice Gets the current status of a specific vault.
     * @param _vaultId The ID of the vault.
     * @return The current VaultStatus.
     */
    function checkVaultStatus(uint256 _vaultId)
        external
        view
        vaultExists(_vaultId)
        returns (VaultStatus)
    {
         Vault storage vault = vaults[_vaultId];
         if (vault.status == VaultStatus.Locked && vault.expiryBlock != 0 && block.number >= vault.expiryBlock) {
             return VaultStatus.Expired; // Return Expired status dynamically if time has passed
         }
         return vault.status;
    }

     /**
     * @notice Checks if a vault is currently locked. Takes expiry into account.
     * @param _vaultId The ID of the vault.
     * @return True if the vault is locked and not expired, false otherwise.
     */
    function isVaultLocked(uint256 _vaultId)
        external
        view
        vaultExists(_vaultId)
        returns (bool)
    {
        Vault storage vault = vaults[_vaultId];
        return vault.status == VaultStatus.Locked && (vault.expiryBlock == 0 || block.number < vault.expiryBlock);
    }

    /**
     * @notice Gets the list of vault IDs owned by a specific user.
     * @param _user The address of the user.
     * @return An array of vault IDs.
     */
    function getUserVaultIds(address _user) external view returns (uint256[] memory) {
        return userVaults[_user].values();
    }


    // --- Unlock Gate Management ---

    /**
     * @notice Adds a new potential unlock gate/condition to an existing vault.
     * @param _vaultId The ID of the vault.
     * @param _gate The UnlockGate struct defining the new gate. status and triggerer fields are ignored.
     */
    function addUnlockGate(uint256 _vaultId, UnlockGate calldata _gate)
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultOwnerOnly(_vaultId)
        vaultIsLocked(_vaultId) // Can only add gates to locked vaults
        gateHasHandler(_gate.gateType) // Ensure a handler exists for this type
    {
        Vault storage vault = vaults[_vaultId];
        // Add the gate with status Pending
        vault.unlockGates.push(UnlockGate({
            gateType: _gate.gateType,
            parameters: _gate.parameters,
            status: GateStatus.Pending,
            bountyAmount: _gate.bountyAmount,
            triggerer: address(0) // No triggerer yet
        }));

        emit UnlockGateAdded(_vaultId, vault.unlockGates.length - 1, _gate.gateType, _gate.parameters);
    }

    /**
     * @notice Removes a gate if it hasn't been triggered, failed, or become observable (depending on rules).
     *         Currently only allows removal if Pending.
     * @param _vaultId The ID of the vault.
     * @param _gateIndex The index of the gate to remove.
     */
    function removeUnlockGate(uint256 _vaultId, uint256 _gateIndex)
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultOwnerOnly(_vaultId)
        vaultIsLocked(_vaultId)
        gateExists(_vaultId, _gateIndex)
        gateIsPending(_vaultId, _gateIndex) // Only remove if Pending
    {
        Vault storage vault = vaults[_vaultId];
        // Simple removal: replace with last element and pop. Order of gates changes.
        // If order matters, a more complex removal (shifting elements) is needed.
        uint lastIndex = vault.unlockGates.length - 1;
        if (_gateIndex != lastIndex) {
            vault.unlockGates[_gateIndex] = vault.unlockGates[lastIndex];
        }
        vault.unlockGates.pop();

        // Note: Removing changes indices of subsequent gates. This needs careful handling client-side.
        // A more robust solution would be mapping gate IDs to gates, or using a library like EnumerableMap.
        emit UnlockGateStatusChanged(_vaultId, _gateIndex, GateStatus.Revoked); // Using Revoked status for removal event
    }

    /**
     * @notice Gets details of a specific gate within a vault.
     * @param _vaultId The ID of the vault.
     * @param _gateIndex The index of the gate.
     * @return The UnlockGate struct.
     */
    function viewUnlockGate(uint256 _vaultId, uint256 _gateIndex)
        external
        view
        vaultExists(_vaultId)
        gateExists(_vaultId, _gateIndex)
        returns (UnlockGate memory)
    {
        return vaults[_vaultId].unlockGates[_gateIndex];
    }

    /**
     * @notice Gets the total number of gates associated with a vault.
     * @param _vaultId The ID of the vault.
     * @return The number of gates.
     */
    function getVaultGateCount(uint256 _vaultId)
        external
        view
        vaultExists(_vaultId)
        returns (uint256)
    {
        return vaults[_vaultId].unlockGates.length;
    }

    /**
     * @notice Gets the current status of a specific gate within a vault.
     * @param _vaultId The ID of the vault.
     * @param _gateIndex The index of the gate.
     * @return The current GateStatus.
     */
    function getGateStatus(uint256 _vaultId, uint256 _gateIndex)
        external
        view
        vaultExists(_vaultId)
        gateExists(_vaultId, _gateIndex)
        returns (GateStatus)
    {
        return vaults[_vaultId].unlockGates[_gateIndex].status;
    }

     /**
     * @notice Allows the vault owner to set or update a bounty for triggering a specific gate.
     *         Any previous bounty amount for this gate is replaced.
     * @param _vaultId The ID of the vault.
     * @param _gateIndex The index of the gate.
     * @param _bountyAmount The bounty amount in native token (ETH/MATIC).
     */
    function setGateBounty(uint256 _vaultId, uint256 _gateIndex, uint256 _bountyAmount)
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultOwnerOnly(_vaultId)
        vaultIsLocked(_vaultId)
        gateExists(_vaultId, _gateIndex)
    {
        Vault storage vault = vaults[_vaultId];
        UnlockGate storage gate = vault.unlockGates[_gateIndex];
        require(gate.status != GateStatus.Triggered && gate.status != GateStatus.Failed, "Cannot set bounty on triggered/failed gate");

        gate.bountyAmount = _bountyAmount;
        emit GateBountySet(_vaultId, _gateIndex, _bountyAmount);
    }

     /**
     * @notice Allows the vault owner to revoke a gate condition.
     *         This marks the gate as permanently non-triggerable.
     *         Can only revoke gates that are Pending or Observable.
     * @param _vaultId The ID of the vault.
     * @param _gateIndex The index of the gate to revoke.
     */
    function revokeGate(uint256 _vaultId, uint256 _gateIndex)
        external
        whenNotPaused
        vaultExists(_vaultId)
        vaultOwnerOnly(_vaultId)
        vaultIsLocked(_vaultId)
        gateExists(_vaultId, _gateIndex)
    {
        Vault storage vault = vaults[_vaultId];
        UnlockGate storage gate = vault.unlockGates[_gateIndex];
        require(gate.status == GateStatus.Pending || gate.status == GateStatus.Observable, "Gate must be Pending or Observable to revoke");

        gate.status = GateStatus.Revoked;
        emit UnlockGateStatusChanged(_vaultId, _gateIndex, GateStatus.Revoked);
    }


    // --- Gate Triggering & Execution ---

     /**
     * @notice Attempts to trigger a specific unlock gate for a vault.
     *         Anyone can call this. If the condition is met, the vault is unlocked.
     * @param _vaultId The ID of the vault.
     * @param _gateIndex The index of the gate to attempt to trigger.
     * @param _proofData Any external data/signature required by the gate's condition handler.
     * @return bool True if the gate was successfully triggered, false otherwise.
     */
    function attemptTriggerGate(uint256 _vaultId, uint256 _gateIndex, bytes calldata _proofData)
        external
        nonReentrant // Prevent reentrancy during potential handler calls or state changes
        whenNotPaused
        vaultExists(_vaultId)
        vaultIsLocked(_vaultId) // Only locked vaults can be triggered
        gateExists(_vaultId, _gateIndex)
        gateHasHandler(vaults[_vaultId].unlockGates[_gateIndex].gateType)
        returns (bool success)
    {
        Vault storage vault = vaults[_vaultId];
        UnlockGate storage gate = vault.unlockGates[_gateIndex];

        // Check if vault has expired
        if (vault.expiryBlock != 0 && block.number >= vault.expiryBlock) {
             vault.status = VaultStatus.Expired;
             emit VaultStatusChanged(_vaultId, VaultStatus.Expired);
             revert("Vault has expired"); // Or return false/handle differently based on desired behavior
        }

        // Only pending or observable gates can be triggered
        require(gate.status == GateStatus.Pending || gate.status == GateStatus.Observable, "Gate is not triggerable");

        // Get the appropriate handler contract
        address handlerAddress = gateTypeHandlers[gate.gateType];
        IGateConditionHandler handler = IGateConditionHandler(handlerAddress);

        // Check if the condition is met by calling the handler (read-only call)
        bool conditionMet = handler.checkCondition(_vaultId, _gateIndex, vault, gate, _proofData);

        if (conditionMet) {
            // Condition is met - trigger the gate and unlock the vault!
            vault.status = VaultStatus.Unlocked;
            gate.status = GateStatus.Triggered;
            gate.triggerer = msg.sender;
            vault.triggeredGateIndex = int256(_gateIndex); // Store which gate triggered it

            emit UnlockGateStatusChanged(_vaultId, _gateIndex, GateStatus.Triggered);
            emit VaultStatusChanged(_vaultId, VaultStatus.Unlocked);
            emit GateTriggered(_vaultId, _gateIndex, msg.sender);

            // Note: Bounties are not automatically sent here. They must be claimed explicitly
            // via claimGateBounty() by the triggerer. This prevents issues if the handler
            // is malicious or complex transfers fail.

            return true; // Successfully triggered
        } else {
            // Condition not met - mark gate as Failed (or keep as Pending/Observable depending on rules)
            // Let's mark as failed for this specific attempt, but leave Pending/Observable status.
            // A gate might become observable later even if a specific attempt failed.
            // To track failed *attempts* specifically, we'd need a separate event or log.
            // For simplicity, the gate status remains Pending/Observable if the check fails.
            // If a gate's condition *permanently* fails (e.g., signature wrong), the handler should maybe signal that.
            // Or the user can revoke it.
            // For now, the gate status only changes on successful trigger.
             return false; // Failed to trigger
        }
    }

     /**
     * @notice Pure/view function to check a gate's condition without state changes.
     *         Calls the handler contract's checkCondition method.
     * @param _vaultId The ID of the vault.
     * @param _gateIndex The index of the gate to check.
     * @param _proofData Any external data/signature required by the gate's condition handler.
     * @return bool True if the condition is currently met, false otherwise.
     */
    function checkGateCondition(uint256 _vaultId, uint256 _gateIndex, bytes calldata _proofData)
        external
        view
        vaultExists(_vaultId)
        gateExists(_vaultId, _gateIndex)
        gateHasHandler(vaults[_vaultId].unlockGates[_gateIndex].gateType)
        returns (bool)
    {
        Vault storage vault = vaults[_vaultId];
        UnlockGate storage gate = vault.unlockGates[_gateIndex];

        // Check if vault has expired
        if (vault.expiryBlock != 0 && block.number >= vault.expiryBlock) {
             return false; // Condition cannot be met if vault expired
        }

         // Only pending or observable gates *could potentially* be triggered
        if (gate.status != GateStatus.Pending && gate.status != GateStatus.Observable) {
             return false; // Not a triggerable status
        }

        // Get the appropriate handler contract
        address handlerAddress = gateTypeHandlers[gate.gateType];
        IGateConditionHandler handler = IGateConditionHandler(handlerAddress);

        // Check if the condition is met by calling the handler
        return handler.checkCondition(_vaultId, _gateIndex, vault, gate, _proofData);
    }

     /**
     * @notice Attempts to find and trigger any valid, observable gate for a vault.
     *         Iterates through gates and calls attemptTriggerGate on suitable ones.
     *         Stops and returns true upon the first successful trigger.
     * @param _vaultId The ID of the vault.
     * @param _proofData Any external data/signature required by the gate's condition handler (might need to be generalized or passed per gate).
     *                   NOTE: Passing a single `_proofData` might not work for vaults with mixed gate types requiring different data.
     *                   A more advanced version would pass an array of proofs or a structured proof object.
     *                   For simplicity here, assume _proofData might contain data relevant to potentially multiple gates, or this function is used
     *                   when only one type of gate is expected to be triggerable.
     * @return bool True if any gate was successfully triggered, false otherwise.
     */
    function findAndTriggerAnyObservableGate(uint256 _vaultId, bytes calldata _proofData)
         external
         nonReentrant
         whenNotPaused
         vaultExists(_vaultId)
         vaultIsLocked(_vaultId)
         returns (bool success)
    {
        Vault storage vault = vaults[_vaultId];

        // Check if vault has expired
        if (vault.expiryBlock != 0 && block.number >= vault.expiryBlock) {
             vault.status = VaultStatus.Expired;
             emit VaultStatusChanged(_vaultId, VaultStatus.Expired);
             // Consider automatically sending asset back to owner here if desired, or leave it to withdraw()
             // If left to withdraw(), owner must check status == Expired.
             return false; // Vault expired, no gates triggerable
        }

        for (uint i = 0; i < vault.unlockGates.length; i++) {
            UnlockGate storage gate = vault.unlockGates[i];

            // Only attempt triggering if the gate is Pending or Observable
            if (gate.status == GateStatus.Pending || gate.status == GateStatus.Observable) {
                 // Check if handler exists before attempting trigger
                 if (gateTypeHandlers[gate.gateType] != address(0)) {
                    // Attempt to trigger this specific gate
                    bool triggered = attemptTriggerGate(_vaultId, i, _proofData); // Re-uses attemptTriggerGate logic

                    if (triggered) {
                        return true; // Found and triggered a gate
                    }
                 }
            }
        }
        return false; // No observable gates were triggered
    }


    /**
     * @notice Allows the address that successfully triggered a gate to claim its bounty.
     * @param _vaultId The ID of the vault.
     * @param _gateIndex The index of the gate.
     */
    function claimGateBounty(uint256 _vaultId, uint256 _gateIndex)
        external
        nonReentrant // Prevent reentrancy on transfer
        whenNotPaused
        vaultExists(_vaultId)
        gateExists(_vaultId, _gateIndex)
        gateIsTriggered(_vaultId, _gateIndex) // Only claim if gate was the one that triggered
    {
        Vault storage vault = vaults[_vaultId];
        UnlockGate storage gate = vault.unlockGates[_gateIndex];

        // Require caller is the address that triggered the gate
        require(msg.sender == gate.triggerer, "Only the triggerer can claim bounty");

        // Require bounty has not been claimed yet
        require(!claimedBounties[_vaultId][_gateIndex], "Bounty already claimed");

        uint256 bounty = gate.bountyAmount;
        require(bounty > 0, "No bounty available for this gate");
        require(address(this).balance >= bounty, "Contract balance insufficient for bounty");

        // Mark bounty as claimed before transfer
        claimedBounties[_vaultId][_gateIndex] = true;

        // Transfer bounty to the triggerer
        (bool success, ) = payable(msg.sender).call{value: bounty}("");
        require(success, "Bounty transfer failed");

        emit GateBountyClaimed(_vaultId, _gateIndex, msg.sender, bounty);

        // Optional: Zero out bountyAmount after claiming?
        // gate.bountyAmount = 0;
    }


    // --- External Handler Management (Owner Only) ---

     /**
     * @notice Registers or updates the contract address responsible for handling a specific GateType.
     *         Only callable by the contract owner.
     * @param _gateType The GateType enum value.
     * @param _handlerAddress The address of the contract implementing IGateConditionHandler for this type.
     */
    function setGateTypeHandler(GateType _gateType, address _handlerAddress)
        external
        onlyOwner
        whenNotPaused // Can only change handlers when not paused (security)
    {
        require(_handlerAddress != address(0), "Handler address cannot be zero");
        // Optional: Add checks here like code size > 0 at _handlerAddress
        // bytes memory code;
        // assembly { code := extcodecopy(_handlerAddress, 0, 0) }
        // require(code.length > 0, "Handler address must be a contract");
        // Also consider adding an interface check if Solidity supports it better later, or using a registration pattern.

        gateTypeHandlers[_gateType] = _handlerAddress;
        emit GateHandlerSet(_gateType, _handlerAddress);
    }

    /**
     * @notice Gets the address of the handler contract for a specific GateType.
     * @param _gateType The GateType enum value.
     * @return The address of the handler contract.
     */
    function getGateTypeHandler(GateType _gateType) external view returns (address) {
        return gateTypeHandlers[_gateType];
    }


    // --- Contract Administration (Owner Only) ---

    /**
     * @notice Pauses the contract. Only callable by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses the contract. Only callable by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Allows the owner to withdraw stuck ERC20 tokens in an emergency.
     *         Should be used cautiously as it bypasses vault logic.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount to withdraw.
     */
    function emergencyWithdrawERC20(address _tokenAddress, uint256 _amount) external onlyOwner nonReentrant {
         require(_tokenAddress != address(0), "Invalid token address");
         require(_amount > 0, "Amount must be > 0");
         IERC20 token = IERC20(_tokenAddress);
         require(token.transfer(owner(), _amount), "Emergency ERC20 withdrawal failed");
    }

    /**
     * @notice Allows the owner to withdraw a stuck ERC721 token in an emergency.
     *         Should be used cautiously as it bypasses vault logic.
     * @param _tokenAddress The address of the ERC721 token.
     * @param _tokenId The ID of the token to withdraw.
     */
    function emergencyWithdrawERC721(address _tokenAddress, uint256 _tokenId) external onlyOwner nonReentrant {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_tokenId > 0, "Token ID must be > 0");
        IERC721 token = IERC721(_tokenAddress);
        token.safeTransferFrom(address(this), owner(), _tokenId);
    }

    // Inherited Ownable.transferOwnership is available.
    // function transferOwnership(address newOwner) public virtual override onlyOwner

    // --- Internal Helpers (Can be external views for debugging if needed) ---

    // These are currently only used internally or are simple wrappers

    /**
     * @notice Internal helper to get vault data.
     * @param _vaultId The ID of the vault.
     * @return The Vault struct.
     */
    // function _getVault(uint256 _vaultId) internal view vaultExists(_vaultId) returns (Vault storage) {
    //    return vaults[_vaultId];
    // }
}

```

**Explanation of Advanced/Creative Concepts:**

1.  **Multi-Conditional Unlock (Quantum Branches):** The core idea that an asset can be unlocked by *any* of several predefined conditions (`unlockGates`). This moves beyond simple time locks or single recipient transfers.
2.  **Pluggable Condition Handlers:** The `IGateConditionHandler` interface and the `gateTypeHandlers` mapping allow defining new `GateType`s and deploying separate, small contracts that contain the *logic* for checking that specific condition (`checkCondition`). The `QuantumVault` contract doesn't need to know the details of *how* each condition is checked, only *who* (which handler contract) is responsible for it. This makes the system extensible without modifying the main `QuantumVault` contract code (as long as the interface is adhered to). This is a powerful pattern for modularity and upgradability (though the handlers themselves would need separate upgrade logic if necessary).
3.  **Incentivized Triggering (Bounties):** Anyone can attempt to trigger a gate. Bounties provide a mechanism to reward external actors (e.g., bots, other users) for monitoring and executing complex or time-sensitive unlock conditions. This is useful for conditions that require active participation or gas expenditure from someone other than the vault owner (e.g., submitting an oracle update proof, providing a signature within a time window).
4.  **Separation of Check and Execution (Implied in `attemptTriggerGate`):** While `attemptTriggerGate` performs both the check and state change internally, the `checkGateCondition` function explicitly separates the read-only check for external parties to verify if a condition is met *before* spending gas on `attemptTriggerGate`.
5.  **Vault Expiry:** Adds a fallback mechanism. If none of the conditions are met before the expiry block, the vault can transition to an `Expired` state, allowing the owner to reclaim assets.
6.  **EnumerableSet for User Vaults:** Using OpenZeppelin's `EnumerableSet` provides an efficient way to track all vault IDs owned by a user, allowing for easy retrieval (`getUserVaultIds`) while keeping gas costs low for adding/removing compared to simple dynamic arrays that need shifting.
7.  **Detailed Status Tracking:** Enums for `VaultStatus` and `GateStatus` provide clear states, and tracking the `triggeredGateIndex` explicitly shows *which* path was taken for an unlocked vault.
8.  **ReentrancyGuard:** Essential due to potential external calls (token transfers, handler calls, payable calls for bounties).
9.  **Pausable:** Standard safety mechanism.
10. **ERC721Holder:** Allows the contract to receive ERC721 tokens safely.

This contract goes beyond typical vault patterns by introducing a dynamic, condition-based unlocking mechanism facilitated by external logic handlers and incorporating incentives for network participants. It's complex, requires careful design of the handler contracts, and relies on external data/actions for many gate types, fitting the "advanced-concept" requirement.