Okay, let's design a sophisticated smart contract. We'll create an `EvolvingOracleNFT`, a token that represents a digital asset whose traits and evolution stages are influenced by external data feeds (oracles) and owner interaction (staking, 'feeding' utility tokens).

This goes beyond simple static NFTs by incorporating:
1.  **Dynamic Traits:** Attributes stored on-chain that change over time and based on conditions.
2.  **Oracle Integration:** Using external data (simulated here with a basic interface, could be Chainlink) to influence state.
3.  **Token Interaction:** Requiring interaction with a separate utility token (ERC20) for certain actions like 'feeding' or staking, which affects the NFT's evolution.
4.  **Staking:** Locking the NFT itself (or associated tokens) within the contract to gain benefits or influence state.
5.  **Evolution Stages:** The NFT can transition through distinct stages based on meeting specific, dynamic criteria.
6.  **Role-Based Access:** More granular control than just `onlyOwner`.
7.  **Gas Optimization:** Using custom errors and efficient storage patterns where applicable.
8.  **Pausable Functionality:** For safety.

We'll aim for a mix of view/pure and state-changing functions to exceed the 20 function requirement naturally.

---

**Outline and Function Summary:**

**Contract Name:** `EvolvingOracleNFT`

**Core Concept:** An ERC-721 NFT whose traits and evolution stage are dynamic, influenced by external oracle data and owner-driven interactions involving a utility token (ERC20).

**Key Features:**
*   ERC-721 Compliant (with dynamic `tokenURI`)
*   Dynamic, On-Chain Traits and Evolution Stage
*   Oracle Data Integration for Environmental Influence
*   Utility Token (ERC20) Staking & 'Feeding' Mechanisms
*   Evolution triggered by conditions (time, stake, affinity, environment)
*   Role-Based Access Control (Owner, Manager, Oracle roles)
*   Pausable for safety

**Function Summary:**

*   **ERC721 Core (Inherited/Overridden):**
    1.  `balanceOf(address owner)`: Get number of tokens owned by an address. (Inherited)
    2.  `ownerOf(uint256 tokenId)`: Get owner of a specific token. (Inherited)
    3.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data. (Inherited)
    4.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer. (Inherited)
    5.  `transferFrom(address from, address to, uint256 tokenId)`: Unsafe transfer. (Inherited)
    6.  `approve(address to, uint256 tokenId)`: Approve an address to transfer token. (Inherited)
    7.  `setApprovalForAll(address operator, bool approved)`: Set operator for all tokens. (Inherited)
    8.  `getApproved(uint256 tokenId)`: Get approved address for a token. (Inherited)
    9.  `isApprovedForAll(address owner, address operator)`: Check if operator is approved for owner. (Inherited)
    10. `tokenURI(uint256 tokenId)`: Get dynamic token URI (overridden).

*   **NFT Management:**
    11. `mint(address to)`: Mints a new NFT to an address.
    12. `burn(uint256 tokenId)`: Burns an NFT. (Uses `_burn` internal from ERC721)

*   **Asset State & Traits:**
    13. `getAssetTraits(uint256 tokenId)`: View current on-chain traits and state for an asset.
    14. `triggerTraitUpdate(uint256 tokenId)`: Allows owner/manager to trigger a trait recalculation based on current state.
    15. `_calculateDynamicTraits(uint256 tokenId)`: (Internal) Core logic for calculating current trait values.

*   **Oracle Integration:**
    16. `requestEnvironmentalInfluence()`: Requests new environmental data from the oracle contract (callable by Manager/Oracle).
    17. `fulfillEnvironmentalInfluence(int256 influenceValue)`: Callback function for the oracle contract to provide data (only callable by configured Oracle address).
    18. `getCurrentEnvironmentalInfluence()`: View the last received environmental influence value.

*   **Evolution:**
    19. `tryEvolve(uint256 tokenId)`: Attempts to evolve the asset to the next stage based on meeting dynamic requirements.
    20. `getEvolutionRequirements(uint8 currentStage)`: View the requirements (affinity, stake, environment minimums) for the next evolution stage.
    21. `isEvolutionPossible(uint256 tokenId)`: Check if the asset meets the requirements for the next stage.

*   **Utility Token Interaction (CatalystToken):**
    22. `stakeCatalyst(uint256 tokenId, uint256 amount)`: Stake CatalystTokens towards a specific asset.
    23. `unstakeCatalyst(uint256 tokenId, uint256 amount)`: Unstake CatalystTokens from a specific asset.
    24. `feedCatalyst(uint256 tokenId, uint256 amount)`: Burn CatalystTokens to increase the asset's affinity score.
    25. `getStakedCatalyst(uint256 tokenId)`: View the amount of CatalystTokens staked for an asset.

*   **Configuration & Access Control:**
    26. `setBaseTokenURI(string memory newBaseURI)`: Sets the base URI for token metadata. (Owner only)
    27. `setCatalystTokenAddress(address _catalystToken)`: Sets the address of the utility token contract. (Owner only)
    28. `setOracleAddress(address _oracleAddress)`: Sets the address of the Oracle contract. (Owner only)
    29. `setRole(address account, bytes32 role, bool enabled)`: Grant or revoke roles (Manager, Oracle). (Owner only)
    30. `setEvolutionRequirements(uint8 stage, uint256 minAffinity, uint256 minStake, int256 minInfluence)`: Sets requirements for a specific evolution stage. (Owner/Manager only)
    31. `getRole(address account, bytes32 role)`: Check if an account has a specific role. (View)

*   **Pausable:**
    32. `pause()`: Pauses certain contract functions. (Owner only)
    33. `unpause()`: Unpauses the contract. (Owner only)

*   **Emergency:**
    34. `emergencyWithdrawCatalyst()`: Allows owner to withdraw stuck Catalyst tokens from the contract (e.g., if ERC20 is paused). (Owner only)

*   **Views (Helper):**
    35. `getRequiredCatalystForFeed(uint256 currentAffinity)`: View the current cost to 'feed' (burn) CatalystToken. (Example of a dynamic parameter)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Define custom errors for gas efficiency
error EONFT_Unauthorized(address account, bytes32 role);
error EONFT_NotTokenOwnerOrApproved();
error EONFT_InvalidAmount();
error EONFT_EvolutionNotPossible(uint8 currentStage);
error EONFT_EvolutionStageNotFound(uint8 stage);
error EONFT_ERC20TransferFailed(address token, address target);
error EONFT_CannotStakeZero();
error EONFT_CannotUnstakeZero();
error EONFT_InsufficientStake();
error EONFT_CannotFeedZero();
error EONFT_InsufficientCatalystBalance(address account);
error EONFT_OracleAddressNotSet();
error EONFT_CatalystAddressNotSet();
error EONFT_InvalidTokenId();

// Interface for a basic Oracle contract
// In a real scenario, this would integrate with Chainlink or similar
interface IOracle {
    // Function the NFT contract calls to request data
    // request ID pattern depends on oracle service
    function requestData() external;

    // Oracle calls this function on our contract with the result
    // Function signature must match what your oracle integration requires
    // Here we assume a simple push model by a trusted address
    // function fulfillData(bytes32 requestId, int256 value) external; // Example for Chainlink VRF
    // We'll use a simpler push model for demonstration
}


contract EvolvingOracleNFT is ERC721, Ownable, Pausable {
    using Strings for uint256;

    // --- State Variables ---

    // NFT Counter
    uint256 private _nextTokenId;

    // Base URI for metadata - actual traits will be dynamic via an API resolver
    string private _baseTokenURI;

    // Struct to hold the dynamic state of each asset
    struct AssetState {
        uint256 creationTime;
        uint8 evolutionStage; // 0, 1, 2, ...
        uint256 lastTraitUpdateTime;
        uint256 affinityScore; // Influenced by 'feeding'
        uint256 stakedCatalyst; // Amount of utility token staked for this asset
    }

    // Mapping from token ID to its state
    mapping(uint256 => AssetState) private _assetStates;

    // Address of the Catalyst ERC20 token
    IERC20 private _catalystToken;

    // Address of the trusted Oracle contract
    IOracle private _oracle;
    int256 private _currentEnvironmentalInfluence; // Last value received from oracle

    // Roles for access control (using bytes32 for gas)
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    mapping(address => mapping(bytes32 => bool)) private _roles;

    // Evolution requirements for each stage
    // stage => {minAffinity, minStake, minEnvironmentalInfluence}
    mapping(uint8 => EvolutionRequirements) private _evolutionRequirements;
    struct EvolutionRequirements {
        uint256 minAffinity;
        uint256 minStake; // Minimum staked CatalystToken
        int256 minEnvironmentalInfluence;
        bool initialized; // Flag to check if requirements for this stage are set
    }

    // --- Events ---

    event NFTMinted(address indexed to, uint256 indexed tokenId);
    event NFTBurned(uint256 indexed tokenId);
    event TraitsUpdated(uint256 indexed tokenId, uint256 affinityScore, uint256 stakedCatalyst, int256 environmentalInfluence);
    event EvolutionStageChanged(uint256 indexed tokenId, uint8 fromStage, uint8 toStage);
    event CatalystStaked(uint256 indexed tokenId, address indexed account, uint256 amount);
    event CatalystUnstaked(uint256 indexed tokenId, address indexed account, uint256 amount);
    event CatalystFed(uint256 indexed tokenId, address indexed account, uint256 amount, uint256 newAffinityScore);
    event EnvironmentalInfluenceReceived(int256 influenceValue);
    event RoleSet(address indexed account, bytes32 indexed role, bool enabled);
    event EvolutionRequirementsSet(uint8 indexed stage, uint256 minAffinity, uint256 minStake, int256 minInfluence);

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Modifiers ---

    modifier onlyRole(bytes32 role) {
        if (!_roles[msg.sender][role] && msg.sender != owner()) {
            revert EONFT_Unauthorized(msg.sender, role);
        }
        _;
    }

    // Check if sender is token owner or approved operator for it
    modifier onlyAssetOwnerOrApproved(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) {
            revert EONFT_NotTokenOwnerOrApproved();
        }
        _;
    }

    // --- Access Control (Owner/Manager/Oracle) ---

    /// @notice Grants or revokes a role for an account. Only callable by the contract owner.
    /// @param account The address to modify roles for.
    /// @param role The role to grant or revoke (e.g., MANAGER_ROLE, ORACLE_ROLE).
    /// @param enabled True to grant the role, false to revoke.
    function setRole(address account, bytes32 role, bool enabled) external onlyOwner {
        _roles[account][role] = enabled;
        emit RoleSet(account, role, enabled);
    }

    /// @notice Checks if an account has a specific role.
    /// @param account The address to check.
    /// @param role The role to check for.
    /// @return True if the account has the role, false otherwise.
    function getRole(address account, bytes32 role) external view returns (bool) {
        return _roles[account][role];
    }

    // --- ERC721 Overrides ---

    /// @notice Returns the URI for a given token ID. This can be dynamic based on the asset's state.
    /// @param tokenId The ID of the token.
    /// @return The URI for the token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Check if token exists
        if (!_exists(tokenId)) {
             revert EONFT_InvalidTokenId();
        }

        // Construct a URI that includes token state parameters (e.g., stage, affinity)
        // An off-chain metadata server should interpret this URI to provide the actual JSON metadata
        // Example: https://your-api.com/metadata/{tokenId}?stage={stage}&affinity={affinity}&influence={influence}
        AssetState storage state = _assetStates[tokenId];
        int256 currentInfluence = _currentEnvironmentalInfluence; // Or fetch the specific one if stored per token

        string memory uri = string(abi.encodePacked(
            _baseTokenURI,
            tokenId.toString(),
            "?stage=", state.evolutionStage.toString(),
            "&affinity=", state.affinityScore.toString(),
            "&stake=", state.stakedCatalyst.toString(),
            "&influence=", currentInfluence.toString()
             // Add other relevant state variables
        ));

        return uri;
    }

    // --- NFT Management ---

    /// @notice Mints a new EvolvingOracleNFT.
    /// @param to The address to mint the NFT to.
    /// @return The ID of the newly minted token.
    function mint(address to) external onlyOwner whenNotPaused returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        // Initialize asset state
        _assetStates[tokenId] = AssetState({
            creationTime: block.timestamp,
            evolutionStage: 0,
            lastTraitUpdateTime: block.timestamp,
            affinityScore: 0,
            stakedCatalyst: 0
        });

        emit NFTMinted(to, tokenId);
        return tokenId;
    }

    /// @notice Burns an EvolvingOracleNFT.
    /// @param tokenId The ID of the token to burn.
    function burn(uint256 tokenId) external onlyAssetOwnerOrApproved(tokenId) whenNotPaused {
        if (!_exists(tokenId)) {
             revert EONFT_InvalidTokenId();
        }

        // Clean up staked Catalyst if any (return to owner or burn?) - Returning is safer
        uint256 staked = _assetStates[tokenId].stakedCatalyst;
        if (staked > 0) {
             if (address(_catalystToken) == address(0)) revert EONFT_CatalystAddressNotSet();
            _assetStates[tokenId].stakedCatalyst = 0;
            // Ensure the owner of the NFT receives the unstaked tokens before burning the NFT
            address owner = ownerOf(tokenId);
            if (!_catalystToken.transfer(owner, staked)) {
                 // This is critical - failing to return tokens might lock them.
                 // Depending on the severity, either re-add to staked balance, or use an emergency mechanism.
                 // For simplicity here, we use a custom error. A robust system might need a recovery pattern.
                revert EONFT_ERC20TransferFailed(address(_catalystToken), owner);
            }
        }

        // Delete state
        delete _assetStates[tokenId];

        _burn(tokenId);
        emit NFTBurned(tokenId);
    }

    // --- Asset State & Traits ---

    /// @notice Gets the current state and traits for a given asset ID.
    /// @param tokenId The ID of the token.
    /// @return A tuple containing the asset's state variables.
    function getAssetTraits(uint256 tokenId) public view returns (
        uint256 creationTime,
        uint8 evolutionStage,
        uint256 lastTraitUpdateTime,
        uint256 affinityScore,
        uint256 stakedCatalyst
    ) {
        if (!_exists(tokenId)) {
             revert EONFT_InvalidTokenId();
        }
        AssetState storage state = _assetStates[tokenId];
        return (
            state.creationTime,
            state.evolutionStage,
            state.lastTraitUpdateTime,
            state.affinityScore,
            state.stakedCatalyst
        );
    }

     /// @notice Triggers an update of the asset's internal state and traits.
     /// Can be called by the owner of the asset or a manager.
     /// This function *calculates* the state, but doesn't necessarily evolve it.
     /// Evolution requires calling `tryEvolve`.
     /// @param tokenId The ID of the token to update.
    function triggerTraitUpdate(uint256 tokenId) external onlyAssetOwnerOrApproved(tokenId) whenNotPaused {
         if (!_exists(tokenId)) {
             revert EONFT_InvalidTokenId();
         }
         // This function primarily recalculates things affected by time or interactions
         // Oracle influence is updated separately via the oracle callback
         AssetState storage state = _assetStates[tokenId];

         // Example: Decay affinity score over time (optional dynamic trait logic)
         // uint256 timeSinceLastUpdate = block.timestamp - state.lastTraitUpdateTime;
         // state.affinityScore = state.affinityScore > timeSinceLastUpdate / 1 days ? state.affinityScore - timeSinceLastUpdate / 1 days : 0; // Decay by 1 per day

         // Recalculate dynamic values based on current state (time elapsed, staked, fed)
         _calculateDynamicTraits(tokenId); // Updates state.affinityScore (if decay logic added) and state.lastTraitUpdateTime

         emit TraitsUpdated(tokenId, state.affinityScore, state.stakedCatalyst, _currentEnvironmentalInfluence);
    }

    /// @dev Internal function to recalculate dynamic traits based on current state.
    /// This is where complex trait logic combining different factors would live.
    function _calculateDynamicTraits(uint256 tokenId) internal {
        if (!_exists(tokenId)) {
             revert EONFT_InvalidTokenId();
         }
        AssetState storage state = _assetStates[tokenId];

        // Example: Affinity decays over time
        uint256 timeSinceLastUpdate = block.timestamp - state.lastTraitUpdateTime;
        uint256 decayAmount = timeSinceLastUpdate / 1 days; // Decay 1 point per day (example)
        state.affinityScore = state.affinityScore > decayAmount ? state.affinityScore - decayAmount : 0;

        // Traits could also be influenced by staked amount, environmental influence, etc.
        // These influences would typically be used by the off-chain metadata API
        // to render the asset, but their *values* are derived from on-chain state.

        state.lastTraitUpdateTime = block.timestamp;
    }


    // --- Oracle Integration ---

    /// @notice Requests new environmental data from the configured oracle.
    /// Callable by Manager or Oracle role.
    function requestEnvironmentalInfluence() external onlyRole(ORACLE_ROLE) whenNotPaused {
        if (address(_oracle) == address(0)) revert EONFT_OracleAddressNotSet();
        // In a real Chainlink integration, this would call request functions
        // that involve LINK tokens and request IDs.
        // Here, we simulate a simple request. The oracle contract would need
        // to call `fulfillEnvironmentalInfluence` later.
        _oracle.requestData();
        // Emit an event indicating a request was made
    }

    /// @notice Callback function for the oracle to provide environmental data.
    /// Only callable by the trusted oracle address.
    /// @param influenceValue The environmental influence value provided by the oracle.
    function fulfillEnvironmentalInfluence(int256 influenceValue) external onlyRole(ORACLE_ROLE) whenNotPaused {
        // Add security checks: e.g., require msg.sender == address(_oracle) in a pull model
        // In this push model example, only accounts with ORACLE_ROLE can call this.

        _currentEnvironmentalInfluence = influenceValue;
        emit EnvironmentalInfluenceReceived(influenceValue);

        // Optionally trigger trait updates or check for evolution for *all* tokens
        // based on the new environmental data (can be gas intensive for many NFTs)
        // A better approach is to update traits/check evolution on-demand per NFT.
    }

    /// @notice Gets the last received environmental influence value from the oracle.
    /// @return The current environmental influence value.
    function getCurrentEnvironmentalInfluence() external view returns (int256) {
        return _currentEnvironmentalInfluence;
    }

    /// @notice Sets the address of the Oracle contract.
    /// @param _oracleAddress The address of the oracle contract.
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        _oracle = IOracle(_oracleAddress);
    }


    // --- Evolution ---

    /// @notice Attempts to evolve the asset to the next stage.
    /// Requires the asset to meet the criteria for the next stage.
    /// @param tokenId The ID of the token to evolve.
    function tryEvolve(uint256 tokenId) external onlyAssetOwnerOrApproved(tokenId) whenNotPaused {
         if (!_exists(tokenId)) {
             revert EONFT_InvalidTokenId();
         }
        AssetState storage state = _assetStates[tokenId];
        uint8 currentStage = state.evolutionStage;
        uint8 nextStage = currentStage + 1;

        // Ensure traits are up-to-date before checking evolution requirements
        _calculateDynamicTraits(tokenId);

        if (!isEvolutionPossible(tokenId)) {
             revert EONFT_EvolutionNotPossible(currentStage);
        }

        // Update evolution stage
        state.evolutionStage = nextStage;
        emit EvolutionStageChanged(tokenId, currentStage, nextStage);

         // Optionally, reset certain stats upon evolution
         // state.affinityScore = 0;
         // state.stakedCatalyst = 0; // Or only a percentage reset
    }

    /// @notice Checks if an asset meets the requirements for the next evolution stage.
    /// @param tokenId The ID of the token to check.
    /// @return True if evolution is possible, false otherwise.
    function isEvolutionPossible(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) {
             return false; // Or revert? depends on desired behavior
        }
        AssetState storage state = _assetStates[tokenId];
        uint8 nextStage = state.evolutionStage + 1;
        EvolutionRequirements storage requirements = _evolutionRequirements[nextStage];

        if (!requirements.initialized) {
            // No requirements set for the next stage means no evolution possible to that stage
            return false;
        }

        // Check requirements
        bool meetsAffinity = state.affinityScore >= requirements.minAffinity;
        bool meetsStake = state.stakedCatalyst >= requirements.minStake;
        bool meetsInfluence = _currentEnvironmentalInfluence >= requirements.minEnvironmentalInfluence;
        // Add other conditions like age: bool meetsAge = block.timestamp - state.creationTime >= minAge;

        return meetsAffinity && meetsStake && meetsInfluence; // Combine all conditions
    }

    /// @notice Gets the requirements for a specific evolution stage.
    /// @param stage The evolution stage to check requirements for.
    /// @return A tuple containing the requirements (minAffinity, minStake, minInfluence, initialized).
    function getEvolutionRequirements(uint8 stage) public view returns (
        uint256 minAffinity,
        uint256 minStake,
        int256 minInfluence,
        bool initialized
    ) {
        EvolutionRequirements storage req = _evolutionRequirements[stage];
        if (!req.initialized) {
            revert EONFT_EvolutionStageNotFound(stage);
        }
        return (req.minAffinity, req.minStake, req.minEnvironmentalInfluence, req.initialized);
    }

    /// @notice Sets the evolution requirements for a specific stage.
    /// Callable by Owner or Manager role.
    /// @param stage The evolution stage to set requirements for.
    /// @param minAffinity The minimum affinity score required.
    /// @param minStake The minimum staked CatalystToken required.
    /// @param minInfluence The minimum environmental influence required.
    function setEvolutionRequirements(uint8 stage, uint255 minAffinity, uint255 minStake, int256 minInfluence) external onlyRole(MANAGER_ROLE) whenNotPaused {
         // Use uint255 to avoid potential overflow warnings with max uint256
         uint256 safeMinAffinity = minAffinity;
         uint256 safeMinStake = minStake;

        _evolutionRequirements[stage] = EvolutionRequirements({
            minAffinity: safeMinAffinity,
            minStake: safeMinStake,
            minEnvironmentalInfluence: minInfluence,
            initialized: true
        });
        emit EvolutionRequirementsSet(stage, safeMinAffinity, safeMinStake, minInfluence);
    }


    // --- Utility Token Interaction (CatalystToken) ---

    /// @notice Sets the address of the Catalyst ERC20 token.
    /// @param _catalystTokenAddress The address of the Catalyst token contract.
    function setCatalystTokenAddress(address _catalystTokenAddress) external onlyOwner {
        _catalystToken = IERC20(_catalystTokenAddress);
    }

    /// @notice Stakes CatalystTokens towards a specific asset ID.
    /// The tokens are transferred from the caller to this contract.
    /// @param tokenId The ID of the asset to stake for.
    /// @param amount The amount of CatalystTokens to stake.
    function stakeCatalyst(uint256 tokenId, uint256 amount) external whenNotPaused {
         if (!_exists(tokenId)) {
             revert EONFT_InvalidTokenId();
         }
        if (amount == 0) revert EONFT_CannotStakeZero();
        if (address(_catalystToken) == address(0)) revert EONFT_CatalystAddressNotSet();

        // Ensure the user has approved this contract to spend their Catalyst tokens
        // User must call `approve` on the CatalystToken contract first.
        AssetState storage state = _assetStates[tokenId];

        // Transfer tokens from the caller to this contract
        if (!_catalystToken.transferFrom(msg.sender, address(this), amount)) {
            revert EONFT_ERC20TransferFailed(address(_catalystToken), address(this));
        }

        state.stakedCatalyst += amount;
        emit CatalystStaked(tokenId, msg.sender, amount);

         // Optionally recalculate traits immediately
         _calculateDynamicTraits(tokenId);
         emit TraitsUpdated(tokenId, state.affinityScore, state.stakedCatalyst, _currentEnvironmentalInfluence);
    }

    /// @notice Unstakes CatalystTokens from a specific asset ID.
    /// The tokens are transferred from this contract back to the caller.
    /// @param tokenId The ID of the asset to unstake from.
    /// @param amount The amount of CatalystTokens to unstake.
    function unstakeCatalyst(uint256 tokenId, uint256 amount) external whenNotPaused {
         if (!_exists(tokenId)) {
             revert EONFT_InvalidTokenId();
         }
        if (amount == 0) revert EONFT_CannotUnstakeZero();
        if (address(_catalystToken) == address(0)) revert EONFT_CatalystAddressNotSet();

        AssetState storage state = _assetStates[tokenId];

        if (state.stakedCatalyst < amount) {
            revert EONFT_InsufficientStake();
        }

        state.stakedCatalyst -= amount;

        // Transfer tokens from this contract back to the caller
        if (!_catalystToken.transfer(msg.sender, amount)) {
             // This is critical - failing to return tokens might lock them.
             // The state variable has already been decreased. Need recovery.
             // A robust system might use a pull pattern or revert the state change.
             // For simplicity here, we use a custom error but acknowledge the risk.
            revert EONFT_ERC20TransferFailed(address(_catalystToken), msg.sender);
        }

        emit CatalystUnstaked(tokenId, msg.sender, amount);

         // Optionally recalculate traits immediately
         _calculateDynamicTraits(tokenId);
         emit TraitsUpdated(tokenId, state.affinityScore, state.stakedCatalyst, _currentEnvironmentalInfluence);
    }

    /// @notice Burns CatalystTokens to 'feed' an asset, increasing its affinity score.
    /// The tokens are transferred from the caller to this contract and then burned (sent to address(0)).
    /// @param tokenId The ID of the asset to feed.
    /// @param amount The amount of CatalystTokens to feed (burn).
    function feedCatalyst(uint256 tokenId, uint256 amount) external whenNotPaused {
         if (!_exists(tokenId)) {
             revert EONFT_InvalidTokenId();
         }
        if (amount == 0) revert EONFT_CannotFeedZero();
        if (address(_catalystToken) == address(0)) revert EONFT_CatalystAddressNotSet();

        AssetState storage state = _assetStates[tokenId];

         // Optional: Implement dynamic feed cost based on current affinity or other factors
         // uint256 requiredAmount = getRequiredCatalystForFeed(state.affinityScore);
         // if (amount < requiredAmount) revert EONFT_InsufficientAmountForFeed(requiredAmount);

         // Check user's balance before transferFrom to provide a better error message
         if (_catalystToken.balanceOf(msg.sender) < amount) {
             revert EONFT_InsufficientCatalystBalance(msg.sender);
         }

        // Transfer tokens from the caller to this contract
        if (!_catalystToken.transferFrom(msg.sender, address(this), amount)) {
            revert EONFT_ERC20TransferFailed(address(_catalystToken), address(this));
        }

        // Burn the tokens (send to address(0))
         // Check balance before burning to prevent issues if transferFrom failed silently (rare but possible)
         if (_catalystToken.balanceOf(address(this)) < amount) {
              // This indicates a problem with the transferFrom call above
              revert EONFT_ERC20TransferFailed(address(_catalystToken), address(this));
         }
        if (!_catalystToken.transfer(address(0), amount)) {
             // Burning failed? This shouldn't happen with a standard ERC20 unless amount > balance(this)
            revert EONFT_ERC20TransferFailed(address(_catalystToken), address(0));
        }

        // Increase affinity score (example logic: 1 Catalyst = 1 affinity point)
        state.affinityScore += amount; // Or a more complex function

        emit CatalystFed(tokenId, msg.sender, amount, state.affinityScore);

         // Optionally recalculate traits immediately
         _calculateDynamicTraits(tokenId);
         emit TraitsUpdated(tokenId, state.affinityScore, state.stakedCatalyst, _currentEnvironmentalInfluence);
    }

    /// @notice Gets the amount of CatalystTokens staked for a specific asset.
    /// @param tokenId The ID of the token.
    /// @return The staked amount.
    function getStakedCatalyst(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
             revert EONFT_InvalidTokenId();
         }
        return _assetStates[tokenId].stakedCatalyst;
    }

    /// @notice Example of a dynamic parameter calculation - get the cost to feed
    /// based on current affinity (e.g., becomes more expensive as affinity grows).
    /// @param currentAffinity The current affinity score of the asset.
    /// @return The required amount of CatalystToken for feeding.
    function getRequiredCatalystForFeed(uint256 currentAffinity) public pure returns (uint256) {
        // Simple example: cost is 1 + affinity / 100
        // In production, use carefully designed token sinks/mechanics
        return 1 + (currentAffinity / 100);
    }


    // --- Configuration ---

    /// @notice Sets the base URI for token metadata.
    /// An off-chain service should append the tokenId and potentially query state to generate full metadata.
    /// @param newBaseURI The new base URI.
    function setBaseTokenURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }


    // --- Pausable ---

    /// @notice Pauses the contract, preventing state-changing operations.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract, allowing state-changing operations.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Emergency ---

    /// @notice Allows the contract owner to withdraw all Catalyst tokens held by the contract.
    /// Use with extreme caution - intended for emergency recovery if tokens get stuck.
    function emergencyWithdrawCatalyst() external onlyOwner {
         if (address(_catalystToken) == address(0)) revert EONFT_CatalystAddressNotSet();
        uint256 balance = _catalystToken.balanceOf(address(this));
        if (balance > 0) {
            if (!_catalystToken.transfer(owner(), balance)) {
                 // This could indicate a serious issue with the ERC20 token or network
                revert EONFT_ERC20TransferFailed(address(_catalystToken), owner());
            }
        }
    }

    // --- Internal/Helper Functions (not included in the 20+ count summary as they aren't external) ---

    /// @dev Internal function to check if a token ID exists. Used by several functions.
    /// @param tokenId The ID of the token.
    /// @return True if the token exists, false otherwise.
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // Override base _update function if needed for custom transfer logic (optional)
    // function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
    //     return super._update(to, tokenId, auth);
    // }
}
```