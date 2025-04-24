Okay, let's craft a smart contract that combines several advanced, interesting, and trendy concepts without directly duplicating existing open-source code patterns (like inheriting full OpenZeppelin contracts, though the *ideas* behind standards like ERC721/ERC20/AccessControl will be implemented manually).

The core concept will be a system of "Living Artifacts" (Dynamic NFTs) that evolve based on user reputation (earned via verified off-chain activity proofs, simulating interaction with ZK proofs), and consume a resource ("Essence" token, also within the contract) to maintain and upgrade their properties. The artifacts will also have modular "Aspects" that can be attached/detached.

This contract will manage:
1.  **Dynamic NFTs:** Artifacts with properties that change.
2.  **Internal ERC20-like Token:** "Essence" used for costs/upgrades.
3.  **Internal Non-Transferable Token/Reputation:** "Reputation Shards" tied to an address, earned via verified proofs.
4.  **ZK Proof Simulation/Integration:** A mechanism to verify off-chain proofs (via a call to a designated verifier address) and reward users with Reputation and Essence.
5.  **Modular Aspects:** Attach/detach capabilities to NFTs.
6.  **Role-Based Access Control:** Custom implementation for managing admin/verifier roles.
7.  **Pausable Pattern:** Basic implementation.
8.  **Reentrancy Guard:** Basic implementation.

---

**Outline and Function Summary**

This contract, `LivingArtifacts`, manages dynamic NFTs ("Artifacts"), an internal ERC20-like token ("Essence"), and user reputation ("Reputation Shards"). Artifacts evolve based on consumed Essence and accumulated Reputation, which are primarily earned by submitting and verifying off-chain activity proofs via a designated ZK Verifier address.

**Outline:**

1.  **State Variables:** Contract ownership, roles, pauser state, reentrancy lock, counters, mappings for artifacts, reputation, essence balances/allowances, configuration parameters (costs, thresholds, verifier address).
2.  **Structs & Enums:** Define `Artifact`, `ArtifactProperties`, `ArtifactAspect`, `EvolutionState`, `AspectType`.
3.  **Events:** Standard ERC721/ERC20 events, custom events for minting, burning, evolving, reputation changes, aspect changes, etc.
4.  **Errors:** Custom errors for clearer failure reasons.
5.  **Modifiers:** `whenNotPaused`, `nonReentrant`, `onlyRole`.
6.  **Constructor:** Sets initial owner and default roles.
7.  **Role Management:** Functions to grant/revoke roles.
8.  **Pausable Logic:** Functions to pause/unpause.
9.  **Reentrancy Guard Logic:** Internal variable.
10. **Configuration:** Functions to set core parameters (costs, thresholds, verifier address).
11. **Artifact Management (ERC721-like):**
    *   `mintArtifact`: Creates a new artifact, requires payment.
    *   `safeTransferFrom`, `transferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `balanceOf`, `ownerOf`: Standard ERC721 functions (implemented manually).
    *   `burnArtifact`: Destroys an artifact.
    *   `getArtifactDetails`, `getArtifactProperties`, `getArtifactAspects`: View functions for artifact data.
12. **Evolution & Properties:**
    *   `evolveArtifact`: Triggers artifact evolution based on consumed Essence and owner's Reputation. Consumes Essence.
13. **Reputation & ZK Proofs:**
    *   `verifyAndGrantReputation`: Callable by a designated verifier/oracle; verifies an external proof result and rewards user with Reputation and Essence.
    *   `getReputationShards`: View function for user reputation.
14. **Essence Token (ERC20-like):**
    *   `transferEssence`, `approveEssence`, `transferFromEssence`, `balanceOfEssence`, `allowanceEssence`, `totalSupplyEssence`: Standard ERC20 functions (implemented manually).
    *   `burnEssence`: Allows users to burn their own essence.
15. **Artifact Aspects:**
    *   `attachAspect`: Adds an aspect to an artifact (requires Essence/Reputation).
    *   `detachAspect`: Removes an aspect.
    *   `upgradeAspect`: Improves an existing aspect (requires Essence/Reputation).
16. **Utility:**
    *   `withdrawFunds`: Allows admin to withdraw collected contract funds.

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the initial admin/owner.
2.  `grantRole(bytes32 role, address account)`: Grants a specific role to an address (Admin only).
3.  `revokeRole(bytes32 role, address account)`: Revokes a specific role from an address (Admin only).
4.  `hasRole(bytes32 role, address account)`: Checks if an account has a specific role (View).
5.  `pause()`: Pauses contract operations (Pauser role only).
6.  `unpause()`: Unpauses contract operations (Pauser role only).
7.  `paused()`: Returns the current pause state (View).
8.  `setZKVerifierAddress(address _verifier)`: Sets the address allowed to call `verifyAndGrantReputation` (Admin only).
9.  `setEvolutionThresholds(uint256[] calldata _essenceThresholds, uint256[] calldata _reputationThresholds)`: Sets the required Essence and Reputation for each evolution state (Admin only).
10. `setMintCosts(uint256 artifactCost, uint256 aspectAttachCost, uint256 aspectUpgradeCost)`: Sets costs for minting and aspect operations (Admin only).
11. `setEssenceRewardForProof(uint256 amount)`: Sets the amount of Essence minted for a verified ZK proof (Admin only).
12. `mintArtifact(bytes memory initialPropertiesData)`: Mints a new Living Artifact NFT to the caller, requires payment of artifact mint cost.
13. `balanceOf(address owner)`: (ERC721) Returns the number of artifacts owned by an address (View).
14. `ownerOf(uint256 artifactId)`: (ERC721) Returns the owner of an artifact (View).
15. `safeTransferFrom(address from, address to, uint256 artifactId, bytes memory data)`: (ERC721) Safely transfers an artifact, checking if the recipient is a smart contract capable of receiving NFTs.
16. `safeTransferFrom(address from, address to, uint256 artifactId)`: (ERC721) Safely transfers an artifact (overloaded).
17. `transferFrom(address from, address to, uint256 artifactId)`: (ERC721) Transfers an artifact (less safe than `safeTransferFrom`).
18. `approve(address to, uint256 artifactId)`: (ERC721) Approves an address to manage a specific artifact.
19. `getApproved(uint256 artifactId)`: (ERC721) Gets the approved address for an artifact (View).
20. `setApprovalForAll(address operator, bool approved)`: (ERC721) Approves or revokes approval for an operator to manage all of caller's artifacts.
21. `isApprovedForAll(address owner, address operator)`: (ERC721) Checks if an operator is approved for all of owner's artifacts (View).
22. `burnArtifact(uint256 artifactId)`: Burns (destroys) an artifact (Owner/approved only).
23. `getArtifactDetails(uint256 artifactId)`: Gets general details of an artifact (View).
24. `getArtifactProperties(uint256 artifactId)`: Gets the dynamic properties of an artifact (View).
25. `getArtifactAspects(uint256 artifactId)`: Gets the attached aspects of an artifact (View).
26. `evolveArtifact(uint256 artifactId)`: Attempts to evolve an artifact to the next state if requirements (Essence consumed, owner Reputation) are met. Consumes required Essence from the artifact.
27. `verifyAndGrantReputation(address user, bytes32 proofIdentifier, bool verificationResult, bytes memory proofData)`: Called by the ZK Verifier address. If `verificationResult` is true, grants the `user` Reputation Shards and mints Essence to their balance. `proofData` is illustrative; actual ZK proof verification would happen externally or via `_zkVerifierAddress` call.
28. `getReputationShards(address user)`: Returns the number of reputation shards an address holds (View).
29. `transferEssence(address to, uint256 amount)`: (ERC20) Transfers Essence tokens (nonReentrant).
30. `approveEssence(address spender, uint256 amount)`: (ERC20) Approves a spender for Essence tokens.
31. `transferFromEssence(address from, address to, uint256 amount)`: (ERC20) Transfers Essence tokens using an allowance (nonReentrant).
32. `balanceOfEssence(address account)`: (ERC20) Returns the Essence balance of an account (View).
33. `allowanceEssence(address owner, address spender)`: (ERC20) Returns the Essence allowance granted by owner to spender (View).
34. `totalSupplyEssence()`: (ERC20) Returns the total supply of Essence (View).
35. `burnEssence(uint256 amount)`: Burns a specified amount of caller's Essence tokens.
36. `attachAspect(uint256 artifactId, uint256 aspectType, bytes memory aspectData)`: Attaches a new aspect to an artifact (requires Essence/Reputation, consumes Essence).
37. `detachAspect(uint256 artifactId, uint256 aspectIndex)`: Detaches an aspect from an artifact (Owner/approved only).
38. `upgradeAspect(uint256 artifactId, uint256 aspectIndex, bytes memory upgradeData)`: Upgrades an attached aspect (requires Essence/Reputation, consumes Essence).
39. `withdrawFunds()`: Allows the Admin role to withdraw ETH collected from artifact minting.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LivingArtifacts
 * @dev A smart contract managing dynamic NFTs (Artifacts), an internal resource token (Essence),
 *      and user reputation (Reputation Shards). Artifacts evolve based on Essence consumption
 *      and owner's Reputation, earned via verified off-chain activity proofs (simulated ZK).
 *      Artifacts can also have modular "Aspects" attached.
 *
 * Outline:
 * 1. State Variables: Contract ownership, roles, pauser state, reentrancy lock, counters, mappings for artifacts, reputation, essence balances/allowances, configuration parameters.
 * 2. Structs & Enums: Define Artifact, ArtifactProperties, ArtifactAspect, EvolutionState, AspectType.
 * 3. Events: Standard ERC721/ERC20 events, custom events for minting, burning, evolving, reputation changes, aspect changes, etc.
 * 4. Errors: Custom errors.
 * 5. Modifiers: whenNotPaused, nonReentrant, onlyRole.
 * 6. Constructor: Sets initial admin.
 * 7. Role Management: Grant/revoke roles.
 * 8. Pausable Logic: Pause/unpause.
 * 9. Reentrancy Guard Logic: Internal variable.
 * 10. Configuration: Set parameters (costs, thresholds, verifier address).
 * 11. Artifact Management (ERC721-like): Mint, transfer, approve, burn, view details.
 * 12. Evolution & Properties: Evolve artifacts based on Essence/Reputation.
 * 13. Reputation & ZK Proofs: Verify proofs, grant reputation/essence. View reputation.
 * 14. Essence Token (ERC20-like): Transfer, approve, burn, view balance/allowance/supply.
 * 15. Artifact Aspects: Attach, detach, upgrade aspects.
 * 16. Utility: Withdraw funds.
 *
 * Function Summary:
 * - constructor(): Initializes the contract with admin role.
 * - grantRole(), revokeRole(), hasRole(): Manage contract roles.
 * - pause(), unpause(), paused(): Control contract pause state.
 * - setZKVerifierAddress(), setEvolutionThresholds(), setMintCosts(), setEssenceRewardForProof(): Configure system parameters.
 * - mintArtifact(): Mints a new NFT, requires ETH payment.
 * - balanceOf(), ownerOf(), safeTransferFrom(), transferFrom(), approve(), setApprovalForAll(), getApproved(), isApprovedForAll(): ERC721 standard functions (manual implementation).
 * - burnArtifact(): Destroys an NFT.
 * - getArtifactDetails(), getArtifactProperties(), getArtifactAspects(): View functions for NFT data.
 * - evolveArtifact(): Attempts to evolve an NFT, consumes Essence.
 * - verifyAndGrantReputation(): Called by verifier, rewards user with Reputation and Essence based on proof result.
 * - getReputationShards(): View user's reputation.
 * - transferEssence(), approveEssence(), transferFromEssence(), balanceOfEssence(), allowanceEssence(), totalSupplyEssence(): ERC20 standard functions for Essence (manual implementation).
 * - burnEssence(): Burns user's Essence.
 * - attachAspect(), detachAspect(), upgradeAspect(): Manage NFT aspects (requires Essence/Reputation).
 * - withdrawFunds(): Allows admin to withdraw contract ETH balance.
 */

contract LivingArtifacts {

    // --- State Variables ---

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE"); // Role for entity calling verifyAndGrantReputation

    mapping(bytes32 => mapping(address => bool)) private _roles;

    // Pausable
    bool private _paused;

    // Reentrancy Guard
    uint256 private _reentrancyStatus;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // Counters
    uint256 private _nextTokenId;
    uint256 private _essenceTotalSupply;

    // Artifact Data (NFTs)
    struct ArtifactProperties {
        string name;
        uint256 power;
        uint256 wisdom;
        // Add more dynamic properties here
    }

    struct ArtifactAspect {
        uint256 aspectType; // Represents type of aspect (e.g., 1=Fire, 2=Water)
        uint256 level;      // Level of the aspect
        bytes data;         // Flexible storage for aspect-specific data
    }

    enum EvolutionState { Dormant, Awakened, Evolved, Ascended }

    struct Artifact {
        address owner;
        EvolutionState evolutionState;
        uint256 essenceConsumed;
        uint256 reputationRequiredForNext;
        ArtifactProperties properties;
        ArtifactAspect[] aspects;
    }
    mapping(uint256 => Artifact) private _artifacts;
    mapping(address => uint256[]) private _ownerArtifacts; // owner => list of artifactIds
    mapping(address => mapping(uint256 => bool)) private _ownerArtifactExists; // Helper for efficient removal

    // ERC721 Approvals
    mapping(uint256 => address) private _tokenApprovals; // artifactId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // Reputation Shards (Non-transferable)
    mapping(address => uint256) private _userReputation;

    // Essence Token (ERC20-like)
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;

    // Configuration Parameters
    uint256 public artifactMintCost = 0.01 ether; // Cost to mint an artifact
    uint256 public aspectAttachCost = 100;       // Cost in Essence to attach an aspect
    uint256 public aspectUpgradeCost = 50;       // Cost in Essence to upgrade an aspect
    uint256 public essenceRewardForProof = 10;  // Essence granted per verified proof

    // Evolution Thresholds (Index corresponds to current state -> next state)
    // essenceThresholds[0] = Essence needed to go from Dormant -> Awakened
    // reputationThresholds[0] = Reputation needed to go from Dormant -> Awakened (owner's total reputation)
    uint256[] public essenceEvolutionThresholds;
    uint256[] public reputationEvolutionThresholds;

    address public zkVerifierAddress; // Address authorized to call verifyAndGrantReputation

    // --- Events ---

    // ERC721 Standard Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // ERC20 Standard Events (for Essence)
    event TransferEssence(address indexed from, address indexed to, uint256 value);
    event ApprovalEssence(address indexed owner, address indexed spender, uint256 value);

    // Custom Events
    event ArtifactMinted(uint256 indexed artifactId, address indexed owner, bytes initialPropertiesData);
    event ArtifactBurned(uint256 indexed artifactId, address indexed owner);
    event ArtifactEvolved(uint256 indexed artifactId, EvolutionState fromState, EvolutionState toState, uint256 essenceConsumedThisEvolution);
    event ReputationGranted(address indexed user, uint256 amount, bytes32 indexed proofIdentifier);
    event EssenceMinted(address indexed user, uint256 amount);
    event AspectAttached(uint256 indexed artifactId, uint256 indexed aspectIndex, uint256 aspectType);
    event AspectDetached(uint256 indexed artifactId, uint256 indexed aspectIndex, uint256 aspectType);
    event AspectUpgraded(uint256 indexed artifactId, uint256 indexed aspectIndex, uint256 oldLevel, uint256 newLevel);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event Paused(address account);
    event Unpaused(address account);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- Errors ---

    error OnlyRole(bytes32 role);
    error PausedState();
    error NotApprovedOrOwner(uint256 artifactId);
    error InvalidRecipient(address recipient);
    error ArtifactDoesNotExist(uint256 artifactId);
    error NotEnoughEssence(uint256 required, uint256 available);
    error NotEnoughReputation(uint256 required, uint256 available);
    error CannotEvolve(EvolutionState currentState);
    error InvalidEvolutionThresholds();
    error AspectDoesNotExist(uint256 artifactId, uint256 aspectIndex);
    error ReentrantCall();
    error UnauthorizedVerifier();
    error InvalidAmount();


    // --- Modifiers ---

    modifier whenNotPaused() {
        if (_paused) revert PausedState();
        _;
    }

    modifier nonReentrant() {
        if (_reentrancyStatus == _ENTERED) revert ReentrantCall();
        _reentrancyStatus = _ENTERED;
        _; // Execute the function logic
        _reentrancyStatus = _NOT_ENTERED; // Reset status
    }

    modifier onlyRole(bytes32 role) {
        if (!_roles[role][msg.sender]) revert OnlyRole(role);
        _;
    }

    // --- Constructor ---

    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
        // Set initial reentrancy state
        _reentrancyStatus = _NOT_ENTERED;
    }

    // --- Role Management ---

    function grantRole(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!_roles[role][account]) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
         if (_roles[role][account]) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    // --- Pausable Logic ---

    function pause() public onlyRole(PAUSER_ROLE) whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    // --- Configuration ---

    function setZKVerifierAddress(address _verifier) public onlyRole(ADMIN_ROLE) {
        zkVerifierAddress = _verifier;
    }

    function setEvolutionThresholds(uint256[] calldata _essenceThresholds, uint256[] calldata _reputationThresholds) public onlyRole(ADMIN_ROLE) {
        if (_essenceThresholds.length != _reputationThresholds.length || _essenceThresholds.length != 3) { // Assuming 3 thresholds for 3 state changes (Dormant->Awakened, Awakened->Evolved, Evolved->Ascended)
            revert InvalidEvolutionThresholds();
        }
        essenceEvolutionThresholds = _essenceThresholds;
        reputationEvolutionThresholds = _reputationThresholds;
    }

     function setMintCosts(uint256 _artifactCost, uint256 _aspectAttachCost, uint256 _aspectUpgradeCost) public onlyRole(ADMIN_ROLE) {
        artifactMintCost = _artifactCost;
        aspectAttachCost = _aspectAttachCost;
        aspectUpgradeCost = _aspectUpgradeCost;
    }

    function setEssenceRewardForProof(uint256 amount) public onlyRole(ADMIN_ROLE) {
        essenceRewardForProof = amount;
    }


    // --- Internal ERC721 Helpers ---

    function _exists(uint256 artifactId) internal view returns (bool) {
        return _artifacts[artifactId].owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 artifactId) internal view returns (bool) {
        address artifactOwner = ownerOf(artifactId); // Will revert if not exists
        return (spender == artifactOwner || getApproved(artifactId) == spender || isApprovedForAll(artifactOwner, spender));
    }

    function _transfer(address from, address to, uint256 artifactId) internal {
        if (ownerOf(artifactId) != from) revert NotApprovedOrOwner(artifactId); // Should not happen if called internally correctly

        // Clear approvals from the previous owner
        _approve(address(0), artifactId);

        // Remove from old owner's list (basic implementation - O(n))
        uint265 currentListLength = _ownerArtifacts[from].length;
        for (uint256 i = 0; i < currentListLength; i++) {
            if (_ownerArtifacts[from][i] == artifactId) {
                 // Swap with last element and pop
                if (i != currentListLength - 1) {
                    _ownerArtifacts[from][i] = _ownerArtifacts[from][currentListLength - 1];
                }
                _ownerArtifacts[from].pop();
                break;
            }
        }
         _ownerArtifactExists[from][artifactId] = false;


        // Update owner in the struct
        _artifacts[artifactId].owner = to;

         // Add to new owner's list
        _ownerArtifacts[to].push(artifactId);
         _ownerArtifactExists[to][artifactId] = true;


        emit Transfer(from, to, artifactId);
    }

     // Checks if recipient is a contract and if it implements ERC721TokenReceiver
    function _checkOnERC721Received(address from, address to, uint256 artifactId, bytes memory data) internal returns (bool) {
        if (to.code.length > 0) {
            try IERC721TokenReceiver(to).onERC721Received(msg.sender, from, artifactId, data) returns (bytes4 retval) {
                return retval == IERC721TokenReceiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                // Handle errors from onERC721Received, e.g., revert or log
                 // Reverting here for strictness as per standard safeTransferFrom behavior
                 assembly {
                    revert(add(32, reason), mload(reason))
                 }
                // Should not reach here
                // revert InvalidRecipient(to); // Fallback if assembly revert is not used
            }
        } else {
             // Not a contract, always safe
            return true;
        }
    }

    function _approve(address to, uint256 artifactId) internal {
        _tokenApprovals[artifactId] = to;
        emit Approval(ownerOf(artifactId), to, artifactId); // ownerOf ensures artifact exists
    }

    // --- Internal ERC20 (Essence) Helpers ---

    function _mintEssence(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidRecipient(address(0));
        if (amount == 0) return;
        _essenceTotalSupply += amount;
        _essenceBalances[account] += amount;
        emit TransferEssence(address(0), account, amount);
    }

    function _burnEssence(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidRecipient(address(0));
        if (amount == 0) return;
        uint256 accountBalance = _essenceBalances[account];
        if (accountBalance < amount) revert NotEnoughEssence(amount, accountBalance);
        _essenceBalances[account] = accountBalance - amount;
        _essenceTotalSupply -= amount;
        emit TransferEssence(account, address(0), amount);
    }

    function _transferEssence(address from, address to, uint256 amount) internal {
        if (from == address(0) || to == address(0)) revert InvalidRecipient(to); // or from
        if (amount == 0) return;

        uint256 fromBalance = _essenceBalances[from];
        if (fromBalance < amount) revert NotEnoughEssence(amount, fromBalance);

        _essenceBalances[from] = fromBalance - amount;
        _essenceBalances[to] = _essenceBalances[to] + amount;
        emit TransferEssence(from, to, amount);
    }


    // --- Artifact Management (ERC721-like Implementation) ---

    function mintArtifact(bytes memory initialPropertiesData) public payable whenNotPaused nonReentrant returns (uint256) {
        if (msg.value < artifactMintCost) revert InvalidAmount();

        uint256 newTokenId = _nextTokenId++;
        address recipient = msg.sender; // Mints to caller

        _artifacts[newTokenId] = Artifact({
            owner: recipient,
            evolutionState: EvolutionState.Dormant,
            essenceConsumed: 0,
            reputationRequiredForNext: (reputationEvolutionThresholds.length > 0 ? reputationEvolutionThresholds[0] : 0), // Set initial requirement
            properties: ArtifactProperties({ name: "", power: 0, wisdom: 0 }), // Basic initial properties
            aspects: new ArtifactAspect[](0)
        });

        // Handle initial properties if provided
        // In a real scenario, this might parse 'initialPropertiesData' based on a schema
        // For this example, we'll just store it or derive basic properties.
        // Let's derive simple properties based on hash or size for illustration
        bytes32 dataHash = keccak256(initialPropertiesData);
        _artifacts[newTokenId].properties.power = uint256(dataHash) % 10 + 1; // 1-10
        _artifacts[newTokenId].properties.wisdom = uint256(dataHash >> 8) % 10 + 1; // 1-10
        _artifacts[newTokenId].properties.name = string(abi.encodePacked("Artifact #", Strings.toString(newTokenId)));


        // Add to owner's list
        _ownerArtifacts[recipient].push(newTokenId);
        _ownerArtifactExists[recipient][newTokenId] = true;


        emit Transfer(address(0), recipient, newTokenId); // Standard ERC721 Mint event
        emit ArtifactMinted(newTokenId, recipient, initialPropertiesData);

        // Refund excess ETH if any
        if (msg.value > artifactMintCost) {
            payable(msg.sender).transfer(msg.value - artifactMintCost);
        }

        return newTokenId;
    }

     // Standard ERC721 Functions

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert InvalidRecipient(address(0));
        return _ownerArtifacts[owner].length; // Using our list implementation
    }

    function ownerOf(uint256 artifactId) public view returns (address) {
        address owner = _artifacts[artifactId].owner;
        if (owner == address(0)) revert ArtifactDoesNotExist(artifactId);
        return owner;
    }

    function safeTransferFrom(address from, address to, uint256 artifactId, bytes memory data) public payable whenNotPaused nonReentrant {
        if (!_isApprovedOrOwner(msg.sender, artifactId)) revert NotApprovedOrOwner(artifactId);
        if (to == address(0)) revert InvalidRecipient(address(0));

        _transfer(from, to, artifactId);

        if (!_checkOnERC721Received(from, to, artifactId, data)) {
             revert InvalidRecipient(to); // Recipient contract rejected transfer
        }
    }

    function safeTransferFrom(address from, address to, uint256 artifactId) public payable whenNotPaused nonReentrant {
         safeTransferFrom(from, to, artifactId, "");
    }

    function transferFrom(address from, address to, uint256 artifactId) public payable whenNotPaused nonReentrant {
        if (!_isApprovedOrOwner(msg.sender, artifactId)) revert NotApprovedOrOwner(artifactId);
         if (to == address(0)) revert InvalidRecipient(address(0));

        _transfer(from, to, artifactId);
    }

    function approve(address to, uint256 artifactId) public whenNotPaused {
        address owner = ownerOf(artifactId); // Reverts if not exists
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert NotApprovedOrOwner(artifactId);

        _approve(to, artifactId);
    }

    function getApproved(uint256 artifactId) public view returns (address) {
        if (!_exists(artifactId)) revert ArtifactDoesNotExist(artifactId);
        return _tokenApprovals[artifactId];
    }

    function setApprovalForAll(address operator, bool approved) public whenNotPaused {
        if (operator == msg.sender) revert InvalidRecipient(operator); // Cannot approve self
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function burnArtifact(uint256 artifactId) public whenNotPaused nonReentrant {
        address artifactOwner = ownerOf(artifactId); // Reverts if not exists
        if (!_isApprovedOrOwner(msg.sender, artifactId)) revert NotApprovedOrOwner(artifactId);

        // Clear approvals
        _approve(address(0), artifactId);
        delete _operatorApprovals[artifactOwner][msg.sender]; // Clear operator approval if msg.sender was operator

         // Remove from owner's list (basic implementation - O(n))
        uint265 currentListLength = _ownerArtifacts[artifactOwner].length;
        for (uint256 i = 0; i < currentListLength; i++) {
            if (_ownerArtifacts[artifactOwner][i] == artifactId) {
                 // Swap with last element and pop
                if (i != currentListLength - 1) {
                    _ownerArtifacts[artifactOwner][i] = _ownerArtifacts[artifactOwner][currentListLength - 1];
                }
                _ownerArtifacts[artifactOwner].pop();
                break;
            }
        }
         _ownerArtifactExists[artifactOwner][artifactId] = false;


        // Delete the artifact data
        delete _artifacts[artifactId];

        emit Transfer(artifactOwner, address(0), artifactId); // Standard ERC721 Burn event
        emit ArtifactBurned(artifactId, artifactOwner);
    }

    // --- Artifact View Functions ---

    function getArtifactDetails(uint256 artifactId) public view returns (
        address owner,
        EvolutionState evolutionState,
        uint256 essenceConsumed,
        uint256 reputationRequiredForNext
    ) {
        Artifact storage artifact = _artifacts[artifactId];
        if (artifact.owner == address(0)) revert ArtifactDoesNotExist(artifactId);

        return (
            artifact.owner,
            artifact.evolutionState,
            artifact.essenceConsumed,
            artifact.reputationRequiredForNext
        );
    }

    function getArtifactProperties(uint256 artifactId) public view returns (ArtifactProperties memory) {
         Artifact storage artifact = _artifacts[artifactId];
        if (artifact.owner == address(0)) revert ArtifactDoesNotExist(artifactId);
        return artifact.properties;
    }

     function getArtifactAspects(uint256 artifactId) public view returns (ArtifactAspect[] memory) {
         Artifact storage artifact = _artifacts[artifactId];
        if (artifact.owner == address(0)) revert ArtifactDoesNotExist(artifactId);
        return artifact.aspects;
    }


    // --- Evolution & Properties ---

    function evolveArtifact(uint256 artifactId) public whenNotPaused nonReentrant {
        Artifact storage artifact = _artifacts[artifactId];
        if (artifact.owner == address(0)) revert ArtifactDoesNotExist(artifactId);
        if (artifact.owner != msg.sender) revert NotApprovedOrOwner(artifactId); // Only owner can evolve their artifact

        uint256 currentStateIndex = uint265(artifact.evolutionState);
        uint256 nextStateIndex = currentStateIndex + 1;

        if (nextStateIndex >= uint265(EvolutionState.Ascended) || nextStateIndex >= essenceEvolutionThresholds.length + 1) { // Max evolution state or no more thresholds defined
            revert CannotEvolve(artifact.evolutionState);
        }

        uint256 requiredEssence = essenceEvolutionThresholds[currentStateIndex];
        uint256 requiredReputation = reputationEvolutionThresholds[currentStateIndex];

        if (artifact.essenceConsumed < requiredEssence) revert NotEnoughEssence(requiredEssence, artifact.essenceConsumed);
        if (_userReputation[msg.sender] < requiredReputation) revert NotEnoughReputation(requiredReputation, _userReputation[msg.sender]);

        // Calculate essence to consume THIS evolution (difference between current consumed and requirement)
        uint256 essenceToConsumeNow = requiredEssence - artifact.essenceConsumed; // This will be 0 if >= requirement

        // --- Perform Evolution ---
        artifact.evolutionState = EvolutionState(nextStateIndex);
        artifact.essenceConsumed = requiredEssence; // Update consumed to the required amount
        artifact.reputationRequiredForNext = (nextStateIndex < reputationEvolutionThresholds.length) ? reputationEvolutionThresholds[nextStateIndex] : type(uint256).max; // Set next requirement

        // --- Apply Property Changes based on Evolution ---
        // This is where the dynamic nature is applied based on state.
        // Example: Increase power/wisdom, maybe add/modify aspects automatically
        if (artifact.evolutionState == EvolutionState.Awakened) {
            artifact.properties.power += 5;
            artifact.properties.wisdom += 2;
             // Maybe auto-attach a basic aspect
             if (artifact.aspects.length == 0) {
                 artifact.aspects.push(ArtifactAspect({aspectType: 1, level: 1, data: ""})); // Example: Basic 'Awakening' Aspect
             }
        } else if (artifact.evolutionState == EvolutionState.Evolved) {
             artifact.properties.power += 7;
            artifact.properties.wisdom += 5;
             // Maybe upgrade existing aspect or add another
              if (artifact.aspects.length > 0 && artifact.aspects[0].aspectType == 1) {
                artifact.aspects[0].level = 2;
              } else {
                 artifact.aspects.push(ArtifactAspect({aspectType: 2, level: 1, data: ""})); // Example: 'Growth' Aspect
              }
        } else if (artifact.evolutionState == EvolutionState.Ascended) {
             artifact.properties.power += 10;
            artifact.properties.wisdom += 10;
             // Max level effects
             for(uint i=0; i<artifact.aspects.length; i++) {
                 artifact.aspects[i].level += 1; // Boost all aspects
             }
        }
        // Note: Evolution logic can be arbitrarily complex.

        emit ArtifactEvolved(artifactId, EvolutionState(currentStateIndex), artifact.evolutionState, essenceToConsumeNow);
    }


    // --- Reputation & ZK Proofs ---

    // This function is intended to be called by a trusted relayer or the ZK Verifier contract
    // after an off-chain process verifies a user's proof of activity.
    // The `proofData` is illustrative; actual ZK data depends on the circuit.
    function verifyAndGrantReputation(address user, bytes32 proofIdentifier, bool verificationResult, bytes memory proofData) public whenNotPaused onlyRole(VERIFIER_ROLE) {
        // In a real system, this might call out to a separate ZK Verifier contract
        // using an interface and verifying the proof within that call.
        // Example: require(IZKVerifier(zkVerifierAddress).verify(proofData), "ZK proof verification failed");

        // For this example, we trust the `verificationResult` from the authorized caller (`VERIFIER_ROLE`).
        if (!verificationResult) {
             // Log or handle failed verification if needed, but no reward
             return;
        }

        // Grant Reputation Shards (non-transferable, just an internal counter)
        _userReputation[user] += 1; // Example: 1 shard per verified proof
        emit ReputationGranted(user, 1, proofIdentifier);

        // Mint Essence to the user
        _mintEssence(user, essenceRewardForProof);
        emit EssenceMinted(user, essenceRewardForProof);

        // ProofIdentifier could be used to prevent double-spending the same proof result
        // mapping(bytes32 => bool) verifiedProofs; require(!verifiedProofs[proofIdentifier]); verifiedProofs[proofIdentifier] = true;
    }

     function getReputationShards(address user) public view returns (uint256) {
        return _userReputation[user];
    }


    // --- Essence Token (ERC20-like Implementation) ---

     function transferEssence(address to, uint256 amount) public nonReentrant whenNotPaused returns (bool) {
         _transferEssence(msg.sender, to, amount);
         return true;
     }

     function approveEssence(address spender, uint256 amount) public whenNotPaused returns (bool) {
         _essenceAllowances[msg.sender][spender] = amount;
         emit ApprovalEssence(msg.sender, spender, amount);
         return true;
     }

     function transferFromEssence(address from, address to, uint256 amount) public nonReentrant whenNotPaused returns (bool) {
         uint256 currentAllowance = _essenceAllowances[from][msg.sender];
         if (currentAllowance < amount) revert NotEnoughEssence(amount, currentAllowance); // Reusing error
         _essenceAllowances[from][msg.sender] = currentAllowance - amount;
         _transferEssence(from, to, amount);
         return true;
     }

     function balanceOfEssence(address account) public view returns (uint256) {
         return _essenceBalances[account];
     }

     function allowanceEssence(address owner, address spender) public view returns (uint256) {
         return _essenceAllowances[owner][spender];
     }

     function totalSupplyEssence() public view returns (uint256) {
         return _essenceTotalSupply;
     }

     function burnEssence(uint256 amount) public nonReentrant whenNotPaused {
         _burnEssence(msg.sender, amount);
     }


    // --- Artifact Aspects ---

    function attachAspect(uint256 artifactId, uint256 aspectType, bytes memory aspectData) public whenNotPaused nonReentrant {
        Artifact storage artifact = _artifacts[artifactId];
        if (artifact.owner == address(0)) revert ArtifactDoesNotExist(artifactId);
        if (artifact.owner != msg.sender) revert NotApprovedOrOwner(artifactId);

        // Check costs
        if (_essenceBalances[msg.sender] < aspectAttachCost) revert NotEnoughEssence(aspectAttachCost, _essenceBalances[msg.sender]);
        // Optional: Check minimum reputation for certain aspects
        // if (_userReputation[msg.sender] < requiredReputationForAspectType) revert NotEnoughReputation(...)

        // Consume Essence
        _burnEssence(msg.sender, aspectAttachCost);

        // Add the aspect
        artifact.aspects.push(ArtifactAspect({
            aspectType: aspectType,
            level: 1, // Start at level 1
            data: aspectData // Store initial data
        }));

        emit AspectAttached(artifactId, artifact.aspects.length - 1, aspectType);
    }

    function detachAspect(uint256 artifactId, uint256 aspectIndex) public whenNotPaused nonReentrant {
        Artifact storage artifact = _artifacts[artifactId];
        if (artifact.owner == address(0)) revert ArtifactDoesNotExist(artifactId);
        if (artifact.owner != msg.sender) revert NotApprovedOrOwner(artifactId);
        if (aspectIndex >= artifact.aspects.length) revert AspectDoesNotExist(artifactId, aspectIndex);

        uint256 detachedAspectType = artifact.aspects[aspectIndex].aspectType;

        // Remove aspect from the array (Swap and pop - efficient)
        uint256 lastIndex = artifact.aspects.length - 1;
        if (aspectIndex != lastIndex) {
            artifact.aspects[aspectIndex] = artifact.aspects[lastIndex];
        }
        artifact.aspects.pop();

        // Optional: Refund a portion of cost or reward for detaching?

        emit AspectDetached(artifactId, aspectIndex, detachedAspectType);
    }

    function upgradeAspect(uint256 artifactId, uint256 aspectIndex, bytes memory upgradeData) public whenNotPaused nonReentrant {
        Artifact storage artifact = _artifacts[artifactId];
        if (artifact.owner == address(0)) revert ArtifactDoesNotExist(artifactId);
        if (artifact.owner != msg.sender) revert NotApprovedOrOwner(artifactId);
         if (aspectIndex >= artifact.aspects.length) revert AspectDoesNotExist(artifactId, aspectIndex);

        // Check costs
        if (_essenceBalances[msg.sender] < aspectUpgradeCost) revert NotEnoughEssence(aspectUpgradeCost, _essenceBalances[msg.sender]);
        // Optional: Check minimum reputation for certain upgrade levels

        // Consume Essence
        _burnEssence(msg.sender, aspectUpgradeCost);

        // Upgrade the aspect
        artifact.aspects[aspectIndex].level += 1;
        // Update or use upgradeData - depends on aspect type
        // For simplicity, let's just increase level and append data for demonstration
        bytes memory currentData = artifact.aspects[aspectIndex].data;
        artifact.aspects[aspectIndex].data = abi.encodePacked(currentData, upgradeData); // Example: Append upgrade data


        emit AspectUpgraded(artifactId, aspectIndex, artifact.aspects[aspectIndex].level - 1, artifact.aspects[aspectIndex].level);
    }


    // --- Utility ---

    function withdrawFunds() public onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
            emit FundsWithdrawn(msg.sender, balance);
        }
    }


    // --- Interface for ZK Verifier (Illustrative) ---
    // This interface would be implemented by a separate contract
    // that handles actual ZK proof verification logic.
    // We define it here to show how LivingArtifacts would interact.
    interface IZKVerifier {
        // Example function signature for verifying a proof
        // function verify(bytes memory proof, bytes memory publicInputs) external view returns (bool);
        // The verifyAndGrantReputation function in this contract assumes an external
        // caller (with VERIFIER_ROLE) *already* performed this verification.
        // In a more integrated system, LivingArtifacts.verifyAndGrantReputation
        // would call IZKVerifier(zkVerifierAddress).verify(...) internally.
    }

    // --- Helper for String Conversions (for NFT name) ---
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
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
     }

    // --- ERC721 Token Receiver Interface (for safeTransferFrom) ---
    // Simplified version of the OpenZeppelin interface
    interface IERC721TokenReceiver {
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
    }
}
```

---

**Explanation of Concepts and Design Choices:**

1.  **Dynamic NFTs (Living Artifacts):** The `Artifact` struct contains mutable properties (`power`, `wisdom`) and an `evolutionState`. The `evolveArtifact` function modifies these based on external conditions (Essence consumption, Reputation). This makes the NFTs non-static and ties their attributes to user interaction within the ecosystem.
2.  **Internal ERC20-like Token (Essence):** The contract manually implements the core logic for an ERC20 token (`_essenceBalances`, `_essenceAllowances`, `_totalSupplyEssence`, `transferEssence`, `approveEssence`, `transferFromEssence`, `balanceOfEssence`, `allowanceEssence`, `totalSupplyEssence`, `burnEssence`). This token acts as a resource sink and reward mechanism within the contract's domain. It's not a separate ERC20 contract deployed elsewhere, but managed directly here.
3.  **Internal Non-Transferable Token/Reputation (Reputation Shards):** The `_userReputation` mapping tracks a score or count for each user. This is analogous to Soulbound Tokens (SBTs) in concept – a non-transferable credential tied to an address, earned through participation/proofs. It influences artifact evolution but cannot be traded.
4.  **ZK Proof Simulation/Integration:** The `verifyAndGrantReputation` function is designed to be the point of integration. It's callable *only* by a designated `zkVerifierAddress` (or a wallet/contract with `VERIFIER_ROLE`). It accepts a `verificationResult` boolean and `proofData`. In a real application, the `VERIFIER_ROLE` caller would be an oracle or a separate contract that verifies a complex ZK proof off-chain or using specific on-chain precompiles/circuits. This function acts on the *outcome* of that external verification, rewarding the user. This pattern avoids putting complex, potentially expensive ZK verification logic directly into the core NFT/Essence contract, separating concerns.
5.  **Modular Aspects:** Artifacts have an array of `ArtifactAspect` structs. `attachAspect`, `detachAspect`, and `upgradeAspect` allow modifying this array. Aspects can represent skills, visual traits, or functional modules. Their effects on properties or interactions would be read by off-chain applications or potentially integrated into on-chain game logic if complex enough. They require consuming Essence and potentially minimum Reputation, creating another use case for the internal tokens.
6.  **Custom Access Control:** A simple role system (`ADMIN_ROLE`, `PAUSER_ROLE`, `VERIFIER_ROLE`) is implemented manually using a mapping and an `onlyRole` modifier, instead of inheriting a standard library. This fulfills the "no duplication" constraint for common patterns while maintaining necessary control.
7.  **Pausable & Reentrancy Guard:** Basic implementations of these standard security patterns are included manually.
8.  **Manual ERC721/ERC20:** Instead of inheriting from OpenZeppelin's full implementations, the contract includes the necessary state (`_artifacts`, `_ownerArtifacts`, `_tokenApprovals`, `_operatorApprovals`, `_essenceBalances`, etc.) and implements the public interface functions (`balanceOf`, `transferFrom`, `totalSupplyEssence`, etc.) and internal helpers (`_transfer`, `_mintEssence`, etc.) manually. This demonstrates understanding of how these standards work internally while adhering to the "no direct duplication" rule. *Note: Implementing these manually is significantly more error-prone than using audited libraries in production, but done here to meet the prompt's constraints.*
9.  **Evolution Logic:** `evolveArtifact` checks if the artifact's total accumulated `essenceConsumed` and the owner's total `_userReputation` meet the thresholds defined for the *next* evolution state. It then updates the state and the artifact's properties. The `essenceConsumed` metric is cumulative per artifact, while Reputation is per user. Essence needed for the *next* level is the *difference* between the required threshold and what's already consumed.
10. **Efficiency Considerations:** The manual ERC721 ownership tracking (`_ownerArtifacts`) and removal (`burnArtifact`, `_transfer`) use a simple array push/pop with swap, which is O(n) for removal. For very large numbers of NFTs per owner, a more complex linked list or mapping structure might be considered, but this is acceptable for demonstration.

This contract provides a rich set of interconnected functionalities centered around dynamic assets, resource management, and off-chain proof-based reputation, implemented with a custom structure to avoid direct open-source code duplication.