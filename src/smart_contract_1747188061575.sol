Okay, let's design a smart contract concept that incorporates several advanced ideas: a multi-asset vault with dynamic access rules governed by a "Quantum" state transition mechanism influenced by (pseudo) randomness and time, combined with phase-specific configurations and role-based access control.

We'll call it `QuantumVault`.

**Concept:**
The `QuantumVault` can hold various ERC20 tokens and ERC721 NFTs. Its interaction rules (who can deposit/withdraw which assets) are determined by its current "Phase". The contract can enter a "Superposition" state, an unstable period after which its phase can "collapse" into a new, probabilistically determined phase, influenced by external randomness (conceptually, simulating a quantum measurement). Access control is managed by an Owner and designated "Phase Controllers".

**Advanced/Creative/Trendy Aspects:**
1.  **Multi-Asset Vault:** Handles both ERC20 and ERC721 dynamically.
2.  **Phase-Based Access Control:** Rules change based on the contract's state.
3.  **Dynamic Configuration:** Phase rules can be updated.
4.  **"Quantum" State Transition:** Simulation of superposition and probabilistic collapse influenced by randomness.
5.  **Role-Based Access:** Owner and specific controllers for phase management.
6.  **Time-Sensitive States:** Superposition has a duration.
7.  **Entitlement Tracking:** Explicitly tracks user deposits/entitlements within the vault.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and necessary interfaces/libraries.
2.  **Error Handling:** Custom errors for clarity.
3.  **Enums:** Define different possible Phases.
4.  **Structs:** Define the configuration for each Phase.
5.  **State Variables:** Store contract data (owner, balances, phases, configs, roles, superposition state).
6.  **Events:** Announce key state changes.
7.  **Modifiers:** Restrict function access based on roles, phases, or superposition state.
8.  **Constructor:** Initialize the contract.
9.  **Admin/Setup Functions:**
    *   Manage allowed tokens/NFTs.
    *   Manage Phase Controllers.
    *   Set global superposition parameters.
10. **Phase Configuration Functions:**
    *   Set deposit/withdraw allowances for specific assets within a phase.
    *   Update overall phase rules.
11. **User Interaction Functions (Deposit/Withdraw):**
    *   Deposit/Withdraw ERC20.
    *   Deposit/Withdraw ERC721.
12. **Quantum State Management Functions:**
    *   Initiate Superposition.
    *   Collapse State using randomness.
    *   Check and potentially exit Superposition automatically.
    *   (Conceptual) Trigger external randomness request (e.g., VRF).
13. **View/Information Functions:**
    *   Get current phase, superposition status.
    *   Get user entitlements.
    *   Get vault balances/holdings.
    *   Check phase-specific rules.

**Function Summary:**

*   `constructor()`: Initializes owner and starting phase.
*   `addAllowedERC20(address tokenAddress)`: Owner adds an ERC20 token to the globally allowed list.
*   `removeAllowedERC20(address tokenAddress)`: Owner removes an ERC20 token from the allowed list.
*   `addAllowedERC721(address nftAddress)`: Owner adds an ERC721 contract to the globally allowed list.
*   `removeAllowedERC721(address nftAddress)`: Owner removes an ERC721 contract from the allowed list.
*   `addPhaseController(address controller)`: Owner grants the Phase Controller role.
*   `removePhaseController(address controller)`: Owner revokes the Phase Controller role.
*   `setSuperpositionParameters(uint256 duration)`: Owner sets how long superposition lasts.
*   `setPhaseERC20DepositAllowed(Phase phase, address token, bool allowed)`: Controller sets if an ERC20 is allowed for deposit in a specific phase.
*   `setPhaseERC20WithdrawAllowed(Phase phase, address token, bool allowed)`: Controller sets if an ERC20 is allowed for withdrawal in a specific phase.
*   `setPhaseERC721DepositAllowed(Phase phase, address nft, bool allowed)`: Controller sets if an ERC721 is allowed for deposit in a specific phase.
*   `setPhaseERC721WithdrawAllowed(Phase phase, address nft, bool allowed)`: Controller sets if an ERC721 is allowed for withdrawal in a specific phase.
*   `depositERC20(address tokenAddress, uint256 amount)`: User deposits ERC20 tokens into the vault.
*   `withdrawERC20(address tokenAddress, uint256 amount)`: User withdraws deposited ERC20 tokens.
*   `depositERC721(address nftAddress, uint256 tokenId)`: User deposits an ERC721 NFT into the vault.
*   `withdrawERC721(address nftAddress, uint256 tokenId)`: User withdraws an entitled ERC721 NFT.
*   `initiateSuperposition()`: Controller initiates the Superposition state.
*   `collapseStateWithRandomness(uint256 randomness)`: Controller/Oracle provides randomness to collapse the state and determine the next phase.
*   `checkAndExitSuperposition()`: Any user can call this to exit superposition if the duration has passed without collapse.
*   `getCurrentPhase()`: View the contract's current phase.
*   `getUserERC20Deposit(address user, address token)`: View user's deposited amount for a token.
*   `getUserNFTEntitlement(address nftAddress, uint256 tokenId)`: View which user is entitled to a specific NFT.
*   `isAllowedERC20(address tokenAddress)`: View if an ERC20 is globally allowed.
*   `isAllowedERC721(address nftAddress)`: View if an ERC721 is globally allowed.
*   `isInSuperposition()`: View if the contract is currently in superposition.
*   `getSuperpositionEndTime()`: View the timestamp when superposition is set to end.
*   `canDepositERC20InPhase(Phase phase, address token)`: View if depositing a specific ERC20 is allowed in a given phase.
*   `canWithdrawERC20InPhase(Phase phase, address token)`: View if withdrawing a specific ERC20 is allowed in a given phase.
*   `canDepositERC721InPhase(Phase phase, address nft)`: View if depositing a specific ERC721 is allowed in a given phase.
*   `canWithdrawERC721InPhase(Phase phase, address nft)`: View if withdrawing a specific ERC721 is allowed in a given phase.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. Pragma and Imports
// 2. Error Handling
// 3. Enums (Phases)
// 4. Structs (PhaseConfig)
// 5. State Variables
// 6. Events
// 7. Modifiers
// 8. Constructor
// 9. Admin/Setup Functions
// 10. Phase Configuration Functions
// 11. User Interaction Functions (Deposit/Withdraw)
// 12. Quantum State Management Functions
// 13. View/Information Functions

// Function Summary:
// - constructor(): Initializes owner and starting phase.
// - addAllowedERC20(address tokenAddress): Owner adds an ERC20 token to the globally allowed list.
// - removeAllowedERC20(address tokenAddress): Owner removes an ERC20 token from the allowed list.
// - addAllowedERC721(address nftAddress): Owner adds an ERC721 contract to the globally allowed list.
// - removeAllowedERC721(address nftAddress): Owner removes an ERC721 contract from the allowed list.
// - addPhaseController(address controller): Owner grants the Phase Controller role.
// - removePhaseController(address controller): Owner revokes the Phase Controller role.
// - setSuperpositionParameters(uint256 duration): Owner sets how long superposition lasts.
// - setPhaseERC20DepositAllowed(Phase phase, address token, bool allowed): Controller sets if an ERC20 is allowed for deposit in a specific phase.
// - setPhaseERC20WithdrawAllowed(Phase phase, address token, bool allowed): Controller sets if an ERC20 is allowed for withdrawal in a specific phase.
// - setPhaseERC721DepositAllowed(Phase phase, address nft, bool allowed): Controller sets if an ERC721 is allowed for deposit in a specific phase.
// - setPhaseERC721WithdrawAllowed(Phase phase, address nft, bool allowed): Controller sets if an ERC721 is allowed for withdrawal in a specific phase.
// - depositERC20(address tokenAddress, uint256 amount): User deposits ERC20 tokens into the vault.
// - withdrawERC20(address tokenAddress, uint256 amount): User withdraws deposited ERC20 tokens.
// - depositERC721(address nftAddress, uint256 tokenId): User deposits an ERC721 NFT into the vault.
// - withdrawERC721(address nftAddress, uint256 tokenId): User withdraws an entitled ERC721 NFT.
// - initiateSuperposition(): Controller initiates the Superposition state.
// - collapseStateWithRandomness(uint256 randomness): Controller/Oracle provides randomness to collapse the state and determine the next phase.
// - checkAndExitSuperposition(): Any user can call this to exit superposition if the duration has passed without collapse.
// - getCurrentPhase(): View the contract's current phase.
// - getUserERC20Deposit(address user, address token): View user's deposited amount for a token.
// - getUserNFTEntitlement(address nftAddress, uint256 tokenId): View which user is entitled to a specific NFT.
// - isAllowedERC20(address tokenAddress): View if an ERC20 is globally allowed.
// - isAllowedERC721(address nftAddress): View if an ERC721 is globally allowed.
// - isInSuperposition(): View if the contract is currently in superposition.
// - getSuperpositionEndTime(): View the timestamp when superposition is set to end.
// - canDepositERC20InPhase(Phase phase, address token): View if depositing a specific ERC20 is allowed in a given phase.
// - canWithdrawERC20InPhase(Phase phase, address token): View if withdrawing a specific ERC20 is allowed in a given phase.
// - canDepositERC721InPhase(Phase phase, address nft): View if depositing a specific ERC721 is allowed in a given phase.
// - canWithdrawERC721InPhase(Phase phase, address nft): View if withdrawing a specific ERC721 is allowed in a given phase.

contract QuantumVault is Ownable, ERC721Holder {
    using SafeMath for uint256;

    // 2. Error Handling
    error NotAllowedToken(address token);
    error NotAllowedNFTContract(address nft);
    error DepositNotAllowedInPhase(Phase phase, address assetAddress);
    error WithdrawNotAllowedInPhase(Phase phase, address assetAddress);
    error InsufficientDeposit(address user, address token);
    error NFTNotOwnedOrEntitled(address nft, uint256 tokenId, address user);
    error NotPhaseController(address caller);
    error AlreadyInSuperposition();
    error NotInSuperposition();
    error SuperpositionDurationNotElapsed();
    error SuperpositionStillActive();
    error RandomnessZero();

    // 3. Enums
    // Define different operational phases of the vault
    enum Phase {
        Genesis,       // Initial state
        OpenFlow,      // Liberal deposit/withdraw rules
        Restricted,    // Limited access
        QuantumFlux,   // Preparing for superposition, maybe specific rules apply
        BlackHole      // No access (conceptual emergency state or final state)
        // Add more creative phases as needed
    }

    // 4. Structs
    // Configuration for each phase
    struct PhaseConfig {
        // Mapping of allowed assets for deposit/withdrawal within this phase
        mapping(address => bool) allowedERC20Deposits;
        mapping(address => bool) allowedERC20Withdrawals;
        mapping(address => bool) allowedERC721Deposits;
        mapping(address => bool) allowedERC721Withdrawals;
        // Add other phase-specific parameters here (e.g., fee multipliers, reward rates)
    }

    // 5. State Variables
    Phase public currentPhase;

    // Global lists of approved assets the vault *can* interact with
    mapping(address => bool) private allowedERC20;
    mapping(address => bool) private allowedERC721;

    // User deposits/entitlements
    mapping(address => mapping(address => uint256)) private userERC20Deposits; // tokenAddress => userAddress => amount
    mapping(address => mapping(uint256 => address)) private userNFTEntitlements; // nftAddress => tokenId => userAddress (address(0) means not deposited or currently owned by nobody user-wise)

    // Phase configuration storage
    mapping(Phase => PhaseConfig) private phaseConfigs;

    // Role-based access control for phase management
    mapping(address => bool) private phaseControllers;

    // State variables for the "Quantum" state
    bool public inSuperposition;
    uint256 public superpositionStartTime;
    uint256 public superpositionDuration; // Duration in seconds

    // 6. Events
    event Deposited(address indexed user, address indexed asset, uint256 amountOrId, bool isERC721);
    event Withdrew(address indexed user, address indexed asset, uint256 amountOrId, bool isERC721);
    event PhaseChanged(Phase indexed oldPhase, Phase indexed newPhase);
    event SuperpositionInitiated(uint256 startTime, uint256 duration);
    event StateCollapsed(Phase indexed newPhase, uint256 randomnessUsed);
    event ExitedSuperpositionNaturally();
    event AllowedERC20Added(address indexed token);
    event AllowedERC20Removed(address indexed token);
    event AllowedERC721Added(address indexed nft);
    event AllowedERC721Removed(address indexed nft);
    event PhaseControllerAdded(address indexed controller);
    event PhaseControllerRemoved(address indexed controller);
    event PhaseERC20DepositAllowanceUpdated(Phase indexed phase, address indexed token, bool allowed);
    event PhaseERC20WithdrawAllowanceUpdated(Phase indexed phase, address indexed token, bool allowed);
    event PhaseERC721DepositAllowanceUpdated(Phase indexed phase, address indexed nft, bool allowed);
    event PhaseERC721WithdrawAllowanceUpdated(Phase indexed phase, address indexed nft, bool allowed);
    event SuperpositionParametersSet(uint256 duration);


    // 7. Modifiers
    modifier onlyPhaseController() {
        if (!phaseControllers[msg.sender] && msg.sender != owner()) {
            revert NotPhaseController(msg.sender);
        }
        _;
    }

    modifier notInSuperposition() {
        if (inSuperposition) {
            revert AlreadyInSuperposition();
        }
        _;
    }

    modifier whenInSuperposition() {
        if (!inSuperposition) {
            revert NotInSuperposition();
        }
        _;
    }

    // 8. Constructor
    constructor() Ownable(msg.sender) ERC721Holder() {
        currentPhase = Phase.Genesis;
        inSuperposition = false;
        superpositionDuration = 1 hours; // Default duration

        // Initialize some default phase configs (can be updated later)
        // Genesis: Maybe no deposits/withdrawals initially allowed by default
        phaseConfigs[Phase.Genesis].allowedERC20Deposits[address(0)] = false; // Dummy entry to initialize mapping
        phaseConfigs[Phase.Genesis].allowedERC20Withdrawals[address(0)] = false;
        phaseConfigs[Phase.Genesis].allowedERC721Deposits[address(0)] = false;
        phaseConfigs[Phase.Genesis].allowedERC721Withdrawals[address(0)] = false;

        // OpenFlow: Allow everything initially (assuming asset is allowed globally)
        // Specific assets still need to be explicitly allowed per phase config
        // This is handled by the setPhaseAllowance functions, not in constructor init
    }

    // 9. Admin/Setup Functions

    /// @notice Adds an ERC20 token address to the globally allowed list.
    /// @param tokenAddress The address of the ERC20 token.
    function addAllowedERC20(address tokenAddress) external onlyOwner {
        allowedERC20[tokenAddress] = true;
        emit AllowedERC20Added(tokenAddress);
    }

    /// @notice Removes an ERC20 token address from the globally allowed list.
    /// @param tokenAddress The address of the ERC20 token.
    function removeAllowedERC20(address tokenAddress) external onlyOwner {
        allowedERC20[tokenAddress] = false;
        emit AllowedERC20Removed(tokenAddress);
    }

    /// @notice Adds an ERC721 contract address to the globally allowed list.
    /// @param nftAddress The address of the ERC721 contract.
    function addAllowedERC721(address nftAddress) external onlyOwner {
        allowedERC721[nftAddress] = true;
        emit AllowedERC721Added(nftAddress);
    }

    /// @notice Removes an ERC721 contract address from the globally allowed list.
    /// @param nftAddress The address of the ERC721 contract.
    function removeAllowedERC721(address nftAddress) external onlyOwner {
        allowedERC721[nftAddress] = false;
        emit AllowedERC721Removed(nftAddress);
    }

    /// @notice Grants the Phase Controller role to an address.
    /// @param controller The address to grant the role to.
    function addPhaseController(address controller) external onlyOwner {
        phaseControllers[controller] = true;
        emit PhaseControllerAdded(controller);
    }

    /// @notice Revokes the Phase Controller role from an address.
    /// @param controller The address to revoke the role from.
    function removePhaseController(address controller) external onlyOwner {
        phaseControllers[controller] = false;
        emit PhaseControllerRemoved(controller);
    }

    /// @notice Sets the duration for the Superposition state.
    /// @param duration The duration in seconds.
    function setSuperpositionParameters(uint256 duration) external onlyOwner {
        superpositionDuration = duration;
        emit SuperpositionParametersSet(duration);
    }

    // 10. Phase Configuration Functions

    /// @notice Sets whether a specific ERC20 token is allowed for deposit in a given phase.
    /// @param phase The phase to configure.
    /// @param token The address of the ERC20 token.
    /// @param allowed Whether deposit is allowed (true) or disallowed (false).
    function setPhaseERC20DepositAllowed(Phase phase, address token, bool allowed) external onlyPhaseController {
        if (!allowedERC20[token]) revert NotAllowedToken(token);
        phaseConfigs[phase].allowedERC20Deposits[token] = allowed;
        emit PhaseERC20DepositAllowanceUpdated(phase, token, allowed);
    }

    /// @notice Sets whether a specific ERC20 token is allowed for withdrawal in a given phase.
    /// @param phase The phase to configure.
    /// @param token The address of the ERC20 token.
    /// @param allowed Whether withdrawal is allowed (true) or disallowed (false).
    function setPhaseERC20WithdrawAllowed(Phase phase, address token, bool allowed) external onlyPhaseController {
         if (!allowedERC20[token]) revert NotAllowedToken(token);
        phaseConfigs[phase].allowedERC20Withdrawals[token] = allowed;
        emit PhaseERC20WithdrawAllowanceUpdated(phase, token, allowed);
    }

    /// @notice Sets whether a specific ERC721 contract is allowed for deposit in a given phase.
    /// @param phase The phase to configure.
    /// @param nft The address of the ERC721 contract.
    /// @param allowed Whether deposit is allowed (true) or disallowed (false).
    function setPhaseERC721DepositAllowed(Phase phase, address nft, bool allowed) external onlyPhaseController {
        if (!allowedERC721[nft]) revert NotAllowedNFTContract(nft);
        phaseConfigs[phase].allowedERC721Deposits[nft] = allowed;
        emit PhaseERC721DepositAllowanceUpdated(phase, nft, allowed);
    }

    /// @notice Sets whether a specific ERC721 contract is allowed for withdrawal in a given phase.
    /// @param phase The phase to configure.
    /// @param nft The address of the ERC721 contract.
    /// @param allowed Whether withdrawal is allowed (true) or disallowed (false).
    function setPhaseERC721WithdrawAllowed(Phase phase, address nft, bool allowed) external onlyPhaseController {
        if (!allowedERC721[nft]) revert NotAllowedNFTContract(nft);
        phaseConfigs[phase].allowedERC721Withdrawals[nft] = allowed;
        emit PhaseERC721WithdrawAllowanceUpdated(phase, nft, allowed);
    }

    // 11. User Interaction Functions

    /// @notice Deposits ERC20 tokens into the vault.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address tokenAddress, uint256 amount) external {
        if (!allowedERC20[tokenAddress]) revert NotAllowedToken(tokenAddress);
        if (!phaseConfigs[currentPhase].allowedERC20Deposits[tokenAddress]) revert DepositNotAllowedInPhase(currentPhase, tokenAddress);

        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), amount);
        uint256 receivedAmount = token.balanceOf(address(this)).sub(balanceBefore);

        userERC20Deposits[tokenAddress][msg.sender] = userERC20Deposits[tokenAddress][msg.sender].add(receivedAmount);

        emit Deposited(msg.sender, tokenAddress, receivedAmount, false);
    }

    /// @notice Withdraws deposited ERC20 tokens from the vault.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to withdraw.
    function withdrawERC20(address tokenAddress, uint256 amount) external {
        if (!allowedERC20[tokenAddress]) revert NotAllowedToken(tokenAddress);
        if (!phaseConfigs[currentPhase].allowedERC20Withdrawals[tokenAddress]) revert WithdrawNotAllowedInPhase(currentPhase, tokenAddress);
        if (userERC20Deposits[tokenAddress][msg.sender] < amount) revert InsufficientDeposit(msg.sender, tokenAddress);

        userERC20Deposits[tokenAddress][msg.sender] = userERC20Deposits[tokenAddress][msg.sender].sub(amount);

        IERC20(tokenAddress).transfer(msg.sender, amount);

        emit Withdrew(msg.sender, tokenAddress, amount, false);
    }

    /// @notice Deposits an ERC721 NFT into the vault. Requires prior approval or setApprovalForAll.
    /// @param nftAddress The address of the ERC721 contract.
    /// @param tokenId The ID of the NFT.
    function depositERC721(address nftAddress, uint256 tokenId) external {
        if (!allowedERC721[nftAddress]) revert NotAllowedNFTContract(nftAddress);
         if (!phaseConfigs[currentPhase].allowedERC721Deposits[nftAddress]) revert DepositNotAllowedInPhase(currentPhase, nftAddress);

        // Ensure the user owns the NFT before transferring
        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "NFT must be owned by caller");

        // Transfer the NFT to the vault contract
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        // Record the user's entitlement to withdraw this specific NFT later
        userNFTEntitlements[nftAddress][tokenId] = msg.sender;

        emit Deposited(msg.sender, nftAddress, tokenId, true);
    }

     /// @notice Withdraws an entitled ERC721 NFT from the vault.
     /// @param nftAddress The address of the ERC721 contract.
     /// @param tokenId The ID of the NFT.
    function withdrawERC721(address nftAddress, uint256 tokenId) external {
        if (!allowedERC721[nftAddress]) revert NotAllowedNFTContract(nftAddress);
        if (!phaseConfigs[currentPhase].allowedERC721Withdrawals[nftAddress]) revert WithdrawNotAllowedInPhase(currentPhase, nftAddress);

        // Check if the caller is entitled to withdraw this NFT
        if (userNFTEntitlements[nftAddress][tokenId] != msg.sender) revert NFTNotOwnedOrEntitled(nftAddress, tokenId, msg.sender);

        // Clear the entitlement before transferring
        userNFTEntitlements[nftAddress][tokenId] = address(0);

        // Transfer the NFT back to the user
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Withdrew(msg.sender, nftAddress, tokenId, true);
    }

    // 12. Quantum State Management Functions

    /// @notice Initiates the Superposition state for a set duration.
    /// Only callable by Phase Controllers when not already in superposition.
    function initiateSuperposition() external onlyPhaseController notInSuperposition {
        inSuperposition = true;
        superpositionStartTime = block.timestamp;
        // The state is now 'unstable' or 'probabilistic' until collapse or timeout
        emit SuperpositionInitiated(superpositionStartTime, superpositionDuration);
    }

    /// @notice Collapses the Superposition state to a new phase using external randomness.
    /// Intended to be called by an oracle or trusted source providing randomness.
    /// @param randomness A uint256 value representing the random outcome. Should be from a secure source like Chainlink VRF.
    function collapseStateWithRandomness(uint256 randomness) external onlyPhaseController whenInSuperposition {
        if (randomness == 0) revert RandomnessZero(); // Avoid bias from 0

        // Ensure superposition duration has NOT yet passed, otherwise it might auto-exit
        if (block.timestamp >= superpositionStartTime.add(superpositionDuration)) revert SuperpositionDurationNotElapsed();

        inSuperposition = false; // State collapses
        superpositionStartTime = 0; // Reset timer

        // Determine the next phase based on randomness
        // This is a simplified probabilistic model. A more complex model could use weighted probabilities.
        uint256 numPhases = uint256(Phase.BlackHole) + 1; // Get number of defined enum values
        Phase nextPhase = Phase(randomness % numPhases);

        Phase oldPhase = currentPhase;
        currentPhase = nextPhase;

        emit StateCollapsed(currentPhase, randomness);
        emit PhaseChanged(oldPhase, currentPhase);
    }

    /// @notice Allows anyone to exit the Superposition state if its duration has passed without collapse.
    function checkAndExitSuperposition() external whenInSuperposition {
        if (block.timestamp < superpositionStartTime.add(superpositionDuration)) revert SuperpositionStillActive();

        // Duration has passed, exit superposition naturally
        inSuperposition = false;
        superpositionStartTime = 0; // Reset timer
        // Phase remains unchanged unless explicitly collapsed

        emit ExitedSuperpositionNaturally();
    }

    // Note: A real-world application needing secure randomness would integrate with
    // a VRF (Verifiable Random Function) like Chainlink VRF. This would involve:
    // 1. A function to request randomness (requires LINK token payment usually).
    // 2. A callback function (`rawFulfillRandomness` or similar) that the VRF oracle calls
    //    once randomness is available. This callback would then trigger the
    //    state transition logic (e.g., calculate the next phase).
    // The `collapseStateWithRandomness` above serves as a simplified example
    // where randomness is provided directly by a trusted role.


    // 13. View/Information Functions

    /// @notice Gets the contract's current operational phase.
    /// @return The current Phase enum value.
    function getCurrentPhase() external view returns (Phase) {
        return currentPhase;
    }

    /// @notice Gets the amount of a specific ERC20 token deposited by a user.
    /// @param user The address of the user.
    /// @param token The address of the ERC20 token.
    /// @return The deposited amount.
    function getUserERC20Deposit(address user, address token) external view returns (uint256) {
        return userERC20Deposits[token][user];
    }

    /// @notice Gets the address of the user entitled to withdraw a specific NFT.
    /// Returns address(0) if the NFT is not in the vault or no user is entitled.
    /// @param nftAddress The address of the ERC721 contract.
    /// @param tokenId The ID of the NFT.
    /// @return The address of the entitled user, or address(0).
    function getUserNFTEntitlement(address nftAddress, uint256 tokenId) external view returns (address) {
        return userNFTEntitlements[nftAddress][tokenId];
    }

    /// @notice Checks if an ERC20 token is globally allowed to be held by the vault.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return True if allowed, false otherwise.
    function isAllowedERC20(address tokenAddress) external view returns (bool) {
        return allowedERC20[tokenAddress];
    }

    /// @notice Checks if an ERC721 contract is globally allowed to be held by the vault.
    /// @param nftAddress The address of the ERC721 contract.
    /// @return True if allowed, false otherwise.
    function isAllowedERC721(address nftAddress) external view returns (bool) {
        return allowedERC721[nftAddress];
    }

    /// @notice Checks if the vault is currently in the Superposition state.
    /// @return True if in superposition, false otherwise.
    function isInSuperposition() external view returns (bool) {
        return inSuperposition;
    }

    /// @notice Gets the timestamp when the current Superposition state is set to end.
    /// Returns 0 if not in superposition or parameters not set.
    /// @return The end timestamp.
    function getSuperpositionEndTime() external view returns (uint256) {
        if (!inSuperposition) return 0;
        return superpositionStartTime.add(superpositionDuration);
    }

    /// @notice Checks if depositing a specific ERC20 is allowed in a given phase configuration.
    /// Requires the token to be globally allowed first.
    /// @param phase The phase to check.
    /// @param token The address of the ERC20 token.
    /// @return True if allowed, false otherwise.
    function canDepositERC20InPhase(Phase phase, address token) external view returns (bool) {
        if (!allowedERC20[token]) return false; // Must be globally allowed
        return phaseConfigs[phase].allowedERC20Deposits[token];
    }

    /// @notice Checks if withdrawing a specific ERC20 is allowed in a given phase configuration.
    /// Requires the token to be globally allowed first.
    /// @param phase The phase to check.
    /// @param token The address of the ERC20 token.
    /// @return True if allowed, false otherwise.
    function canWithdrawERC20InPhase(Phase phase, address token) external view returns (bool) {
        if (!allowedERC20[token]) return false; // Must be globally allowed
        return phaseConfigs[phase].allowedERC20Withdrawals[token];
    }

    /// @notice Checks if depositing a specific ERC721 is allowed in a given phase configuration.
    /// Requires the NFT contract to be globally allowed first.
    /// @param phase The phase to check.
    /// @param nft The address of the ERC721 contract.
    /// @return True if allowed, false otherwise.
    function canDepositERC721InPhase(Phase phase, address nft) external view returns (bool) {
        if (!allowedERC721[nft]) return false; // Must be globally allowed
        return phaseConfigs[phase].allowedERC721Deposits[nft];
    }

    /// @notice Checks if withdrawing a specific ERC721 is allowed in a given phase configuration.
    /// Requires the NFT contract to be globally allowed first.
    /// @param phase The phase to check.
    /// @param nft The address of the ERC721 contract.
    /// @return True if allowed, false otherwise.
    function canWithdrawERC721InPhase(Phase phase, address nft) external view returns (bool) {
        if (!allowedERC721[nft]) return false; // Must be globally allowed
        return phaseConfigs[phase].allowedERC721Withdrawals[nft];
    }

    /// @notice Checks if an address has the Phase Controller role.
    /// @param controller The address to check.
    /// @return True if the address is a Phase Controller (or owner), false otherwise.
    function isPhaseController(address controller) external view returns (bool) {
        return phaseControllers[controller] || controller == owner();
    }

    // ERC721Holder requires receiving NFTs
    // Default onERC721Received implementation from OpenZeppelin is sufficient.
    // It returns the required selector bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))

    // Fallback function to receive Ether (optional for a vault, but good practice if intending to hold ETH)
    // receive() external payable {}
}
```