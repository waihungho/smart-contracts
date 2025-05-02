Okay, here is a smart contract concept called "ChronoGenesis Orbs". It's an NFT contract where the NFTs ("Orbs") are dynamic, can be staked with a native token (`ESSENCE`) to earn yield and "evolve" over time based on staking duration, accrued energy, and potentially external data via an oracle.

This combines:
1.  **Dynamic NFTs:** Metadata changes based on the Orb's state (Epoch).
2.  **Yield-Bearing NFTs:** Staking tokens *within* the NFT allows it to generate more tokens.
3.  **Time-Based Evolution:** Orbs accumulate "Chrono-Energy" over time while staked, triggering evolution to higher "Epochs."
4.  **Token Sink & Utility:** A native token (`ESSENCE`) is required for staking and potentially evolution costs, creating demand.
5.  **Oracle Integration (Conceptual):** Allows external data (e.g., market volatility, environmental data, random numbers) to influence evolution rate or outcomes.
6.  **Parameterization:** Key contract mechanics (yield rates, evolution costs) can be adjusted (simulating potential governance).
7.  **Complex State Management:** Each Orb tracks its own staked balance, Chrono-Energy, last update time, and Epoch.

**Outline & Function Summary**

This contract defines a dynamic NFT (`ChronoGenesisOrb`) that interacts with a hypothetical ERC20 token (`GenesisEssence`).

1.  **State Variables:**
    *   `ESSENCE_TOKEN`: Address of the Genesis Essence ERC20 token.
    *   `orbData`: Mapping from `tokenId` to `OrbData` struct, storing epoch, energy, staked essence, last update.
    *   `epochConfigs`: Array of `EpochConfig` structs, defining yield rates, energy requirements, and potential evolution costs per epoch.
    *   `metadataBaseURI`: Base URI for token metadata, appended with epoch/state info.
    *   `oracleAddress`: Address of a trusted oracle contract/adapter.
    *   `oracleInfluenceFactor`: Determines how much oracle data impacts energy gain.
    *   `paused`: State variable for pausing functionality.
    *   Standard ERC721 state (owner, balance, approvals).

2.  **Structs:**
    *   `OrbData`: Represents the state of an individual Orb NFT.
    *   `EpochConfig`: Defines parameters for each evolution stage (Epoch).

3.  **Events:**
    *   `OrbMinted`: When a new Orb is created.
    *   `EssenceStaked`: When ESSENCE is staked into an Orb.
    *   `EssenceUnstaked`: When ESSENCE is unstaked from an Orb.
    *   `EssenceYieldClaimed`: When yield is claimed from an Orb.
    *   `OrbEvolved`: When an Orb evolves to the next epoch.
    *   `OracleDataUpdated`: When the contract receives new data from the oracle.
    *   `ParametersUpdated`: When key parameters are changed.
    *   `Paused`/`Unpaused`: Contract pause state changes.

4.  **Modifiers:**
    *   `onlyOwner`: Restricts access to the contract owner (basic access control).
    *   `whenNotPaused`: Prevents execution if the contract is paused.
    *   `orbExists`: Ensures the given `tokenId` is a valid minted Orb.

5.  **Core Logic Functions (~20+):**

    *   **ERC721 Standard (Implemented or Overridden):**
        *   `balanceOf(address owner)`: Returns the count of tokens owned by an address.
        *   `ownerOf(uint256 tokenId)`: Returns the owner of the token.
        *   `approve(address to, uint256 tokenId)`: Grants approval for a single token.
        *   `getApproved(uint256 tokenId)`: Gets the approved address for a single token.
        *   `setApprovalForAll(address operator, bool approved)`: Grants/revokes approval for all tokens.
        *   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens.
        *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership.
        *   `safeTransferFrom(...)`: Safely transfers ownership.
        *   `tokenURI(uint256 tokenId)`: **(Overridden)** Returns the dynamic metadata URI based on the Orb's current epoch. (1 function)

    *   **Minting:**
        *   `mint()`: Creates a new Orb NFT for the caller (requires payment/conditions). (1 function)

    *   **Orb State & Interaction:**
        *   `stakeEssenceIntoOrb(uint256 tokenId, uint256 amount)`: Stakes `ESSENCE` tokens into a specific Orb. Updates Orb state. (1 function)
        *   `unstakeEssenceFromOrb(uint256 tokenId, uint256 amount)`: Unstakes `ESSENCE` tokens from an Orb. Updates Orb state. (1 function)
        *   `calculatePendingEssenceYield(uint256 tokenId)`: Calculates the accrued but unclaimed `ESSENCE` yield for an Orb. (1 function)
        *   `claimEssenceYield(uint256 tokenId)`: Claims the calculated `ESSENCE` yield. Updates Orb state and transfers tokens. (1 function)
        *   `evolveOrb(uint256 tokenId)`: Attempts to evolve the Orb to the next epoch if conditions (energy, cost) are met. Updates Orb state. (1 function)
        *   `_updateOrbState(uint256 tokenId)`: **(Internal Helper)** Updates Orb's `chronoEnergy` and `stakedEssence` based on time elapsed, staking amount, yield rate, and oracle data. Called before any interaction with an Orb's state. (Not counted in the 20 user-facing, but crucial).

    *   **Getters & View Functions:**
        *   `getOrbData(uint256 tokenId)`: Returns the full `OrbData` struct for a token. (1 function)
        *   `getEpochDetails(uint8 epoch)`: Returns the `EpochConfig` for a specific epoch. (1 function)
        *   `getGlobalParameters()`: Returns key global parameters (oracle address, influence factor, pause status). (1 function)
        *   `isOrbEvolvable(uint256 tokenId)`: Checks if an Orb currently meets the energy requirement to evolve. (1 function)
        *   `getTotalStakedEssenceInOrb(uint256 tokenId)`: Returns the total `ESSENCE` currently staked in an Orb. (1 function)
        *   `getCurrentChronoEnergy(uint256 tokenId)`: Returns the current calculated Chrono-Energy of an Orb (after potential update). (1 function)

    *   **Admin/Parameter Setting (Owner Only):**
        *   `setEssenceToken(address _essenceToken)`: Sets the address of the ESSENCE token. (1 function)
        *   `addOrUpdateEpochConfig(uint8 epoch, uint256 yieldRatePerSecond, uint256 energyRequired, uint256 evolutionEssenceCost)`: Adds or modifies configurations for an epoch. (1 function)
        *   `setMetadataBaseURI(string memory _newURI)`: Sets the base URI for token metadata. (1 function)
        *   `setOracleAddress(address _oracle)`: Sets the address of the trusted oracle adapter. (1 function)
        *   `setOracleInfluenceFactor(uint256 _factor)`: Sets the influence factor for oracle data. (1 function)
        *   `pauseContract()`: Pauses core functionalities. (1 function)
        *   `unpauseContract()`: Unpauses the contract. (1 function)
        *   `withdrawEth(address payable recipient)`: Withdraws ETH from the contract. (1 function)
        *   `withdrawEssence(address recipient, uint256 amount)`: Withdraws ESSENCE tokens held by the contract (e.g., from minting fees or unallocated yield). (1 function)

    *   **Oracle Callback:**
        *   `receiveOracleData(int256 data)`: Endpoint for the oracle to send data. This data is used in `_updateOrbState`. (1 function)

Total Count Check:
*   ERC721 Overridden/Specific: 1 (`tokenURI`)
*   Minting: 1 (`mint`)
*   Orb Interaction/Core: 5 (`stake`, `unstake`, `claim`, `evolve`, `isEvolvable`)
*   Getters/Views: 5 (`getOrbData`, `getEpochDetails`, `getGlobalParameters`, `getTotalStakedEssence`, `getCurrentChronoEnergy`)
*   Admin/Parameter Setters: 8 (`setEssence`, `addEpoch`, `setBaseURI`, `setOracle`, `setInfluence`, `pause`, `unpause`, `withdrawEth`, `withdrawEssence`) - that's 9, let's use 8 common ones.
*   Oracle Callback: 1 (`receiveOracleData`)

Total unique *user/admin/callback/view* functions: 1 + 1 + 5 + 5 + 8 + 1 = 21.
Plus the standard ERC721 functions required by the interface (transferFrom, balanceOf, ownerOf, etc.), bringing the total significantly over 20. We will implement the core unique logic and assume standard ERC721 interfaces/behavior for brevity.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Note: In a production environment, you would use audited libraries
// like OpenZeppelin for ERC721, ERC20 interfaces, Ownable, ReentrancyGuard, etc.
// This code provides a custom implementation skeleton focused on the unique logic
// requested, assuming standard interface requirements.

// Define interfaces we need
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IOracle {
    // Example interface for an oracle callback
    function fulfill(bytes32 requestId, int256 value) external;
}

// Basic access control (simplified Ownable pattern)
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Basic ReentrancyGuard (simplified)
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}


contract ChronoGenesisOrb is Ownable, ReentrancyGuard {
    using Strings for uint256;

    // --- Structs ---
    struct OrbData {
        uint8 epoch; // Current evolution stage
        uint256 chronoEnergy; // Accumulates over time while staked
        uint256 stakedEssence; // Amount of ESSENCE staked in this orb
        uint256 lastUpdate; // Timestamp of the last state update
        uint256 pendingYield; // Unclaimed ESSENCE yield
    }

    struct EpochConfig {
        uint256 yieldRatePerSecond; // ESSENCE yield rate per second per staked token
        uint256 energyRequired; // Chrono-Energy needed to evolve to this epoch (index = next epoch)
        uint256 evolutionEssenceCost; // ESSENCE cost to evolve to this epoch (index = next epoch)
        // Add more attributes here, e.g., visual representation id, boost factors, etc.
    }

    // --- State Variables ---
    IERC20 public immutable ESSENCE_TOKEN; // The utility/yield token
    string public metadataBaseURI; // Base URI for fetching token metadata

    mapping(uint256 => OrbData) private orbData;
    uint256 private _nextTokenId; // Counter for minting new tokens

    EpochConfig[] public epochConfigs; // Configurations for each epoch (epoch 0, 1, 2...)

    address public oracleAddress; // Address of a trusted oracle contract/adapter
    int256 public currentOracleData; // Last received oracle data
    uint256 public oracleInfluenceFactor = 1; // How much oracle data affects energy gain (multiplier, e.g., 100 = 1x influence)

    // Basic ERC721 data (simplified, real would use library)
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Pausability
    bool public paused = false;

    // --- Events ---
    event OrbMinted(address indexed owner, uint256 indexed tokenId, uint8 initialEpoch);
    event EssenceStaked(address indexed owner, uint256 indexed tokenId, uint256 amount);
    event EssenceUnstaked(address indexed owner, uint256 indexed tokenId, uint256 amount);
    event EssenceYieldClaimed(address indexed owner, uint255 indexed tokenId, uint256 amount);
    event OrbEvolved(uint256 indexed tokenId, uint8 indexed oldEpoch, uint8 indexed newEpoch);
    event OracleDataUpdated(int256 indexed newData, uint256 timestamp);
    event ParametersUpdated(string parameterName);
    event Paused(address account);
    event Unpaused(address account);

    // --- Errors (Solidity 0.8.4+) ---
    error TokenDoesNotExist(uint256 tokenId);
    error NotTokenOwnerOrApproved(address caller, uint256 tokenId);
    error InvalidAmount();
    error InsufficientEssence(uint256 required, uint256 has);
    error NotEligibleToEvolve(uint256 tokenId, uint256 currentEnergy, uint256 requiredEnergy);
    error AlreadyMaxEpoch(uint256 tokenId);
    error CallerIsNotOracle(address caller, address expectedOracle);
    error ContractPaused();
    error TransferFailed();

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    modifier orbExists(uint256 tokenId) {
        if (_owners[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        _;
    }

    // --- Constructor ---
    constructor(address _essenceToken, string memory _metadataBaseURI) {
        ESSENCE_TOKEN = IERC20(_essenceToken);
        metadataBaseURI = _metadataBaseURI;

        // Initialize epoch 0 config (base state)
        // yieldRatePerSecond, energyRequired (to evolve TO epoch 1), evolutionEssenceCost (to evolve TO epoch 1)
        epochConfigs.push(EpochConfig(0, 1000000, 1000000)); // Epoch 0: no yield, needs 1M energy & 1M ESSENCE to reach Epoch 1
    }

    // --- Core Logic Functions (Partial ERC721 + Custom) ---

    // ERC721 Standard (Simplified/Overridden examples)
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist(tokenId);
        return owner;
    }

    // tokenURI is dynamic based on state
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _updateOrbState(tokenId); // Ensure state is fresh for metadata

        string memory base = metadataBaseURI;
        string memory state = string(abi.encodePacked(
            "epoch=", Strings.toString(orbData[tokenId].epoch),
            "&energy=", Strings.toString(orbData[tokenId].chronoEnergy),
            "&staked=", Strings.toString(orbData[tokenId].stakedEssence)
            // Add other relevant data points here
        ));

        return string(abi.encodePacked(base, "/", tokenId.toString(), "?", state));
    }

    // Other ERC721 standard functions (approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom)
    // would be implemented here following ERC721 standard spec.
    // Example simplified transfer (does not handle receiver callback)
    function transferFrom(address from, address to, uint256 tokenId) public virtual nonReentrant whenNotPaused orbExists(tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Before transferring, claim pending yield
        _claimEssenceYield(tokenId); // Claims to the 'from' address

        _beforeTokenTransfer(from, to, tokenId);

        _tokenApprovals[tokenId] = address(0);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    // Internal helper for approval check (simplified)
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId); // Checks existence
        return (spender == owner || _tokenApprovals[tokenId] == spender || isApprovedForAll(owner, spender));
    }

    // --- Custom Orb Functions ---

    /**
     * @notice Mints a new ChronoGenesis Orb.
     * @dev Callable by anyone (example: free mint or requires prior allowlist check, or payment).
     *      For simplicity, this is a free mint example up to a theoretical max.
     */
    function mint() public nonReentrant whenNotPaused returns (uint256) {
        uint256 newItemId = _nextTokenId;
        _nextTokenId++; // Simple incrementing ID

        _mint(_msgSender(), newItemId);

        // Initialize Orb data
        orbData[newItemId] = OrbData({
            epoch: 0,
            chronoEnergy: 0,
            stakedEssence: 0,
            lastUpdate: block.timestamp,
            pendingYield: 0
        });

        emit OrbMinted(_msgSender(), newItemId, 0);
        return newItemId;
    }

    /**
     * @notice Stakes ESSENCE tokens into a specific Orb.
     * @param tokenId The ID of the Orb NFT.
     * @param amount The amount of ESSENCE to stake.
     */
    function stakeEssenceIntoOrb(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused orbExists(tokenId) {
        require(amount > 0, "Stake: amount must be > 0");
        address owner = ownerOf(tokenId); // Ensure owner check implicitly happens
        require(_msgSender() == owner, "Stake: caller is not orb owner");

        // Update state before staking more
        _updateOrbState(tokenId);

        // Transfer ESSENCE from caller to this contract
        bool success = ESSENCE_TOKEN.transferFrom(owner, address(this), amount);
        if (!success) revert TransferFailed();

        orbData[tokenId].stakedEssence += amount;
        orbData[tokenId].lastUpdate = block.timestamp; // Reset update time after staking
        // pendingYield is already updated by _updateOrbState

        emit EssenceStaked(owner, tokenId, amount);
    }

    /**
     * @notice Unstakes ESSENCE tokens from a specific Orb.
     * @param tokenId The ID of the Orb NFT.
     * @param amount The amount of ESSENCE to unstake.
     */
    function unstakeEssenceFromOrb(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused orbExists(tokenId) {
        require(amount > 0, "Unstake: amount must be > 0");
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "Unstake: caller is not orb owner");

        // Update state before unstaking
        _updateOrbState(tokenId);

        OrbData storage orb = orbData[tokenId];
        if (amount > orb.stakedEssence) revert InsufficientEssence(amount, orb.stakedEssence);

        orb.stakedEssence -= amount;
        orb.lastUpdate = block.timestamp; // Reset update time after unstaking
        // pendingYield is already updated by _updateOrbState

        // Transfer ESSENCE from contract to caller
        bool success = ESSENCE_TOKEN.transfer(owner, amount);
        if (!success) revert TransferFailed();

        emit EssenceUnstaked(owner, tokenId, amount);
    }

    /**
     * @notice Claims accrued ESSENCE yield for a specific Orb.
     * @param tokenId The ID of the Orb NFT.
     */
    function claimEssenceYield(uint256 tokenId) public nonReentrant whenNotPaused orbExists(tokenId) {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "Claim: caller is not orb owner");

        _claimEssenceYield(tokenId);
    }

    /**
     * @dev Internal helper to claim yield. Used by claimEssenceYield and _transfer.
     * @param tokenId The ID of the Orb NFT.
     */
    function _claimEssenceYield(uint256 tokenId) internal {
        // Update state before claiming
        _updateOrbState(tokenId);

        OrbData storage orb = orbData[tokenId];
        uint256 yieldToClaim = orb.pendingYield;
        require(yieldToClaim > 0, "Claim: no pending yield");

        orb.pendingYield = 0; // Reset pending yield

        // Transfer ESSENCE from contract to owner
        bool success = ESSENCE_TOKEN.transfer(ownerOf(tokenId), yieldToClaim);
        if (!success) revert TransferFailed(); // Revert if transfer fails

        emit EssenceYieldClaimed(ownerOf(tokenId), tokenId, yieldToClaim);
    }


    /**
     * @notice Attempts to evolve an Orb to the next epoch.
     * @param tokenId The ID of the Orb NFT.
     */
    function evolveOrb(uint256 tokenId) public nonReentrant whenNotPaused orbExists(tokenId) {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "Evolve: caller is not orb owner");

        // Update state before checking evolution eligibility
        _updateOrbState(tokenId);

        OrbData storage orb = orbData[tokenId];
        uint8 currentEpoch = orb.epoch;
        uint8 nextEpoch = currentEpoch + 1;

        if (nextEpoch >= epochConfigs.length) {
            revert AlreadyMaxEpoch(tokenId);
        }

        EpochConfig storage nextConfig = epochConfigs[nextEpoch];

        if (orb.chronoEnergy < nextConfig.energyRequired) {
            revert NotEligibleToEvolve(tokenId, orb.chronoEnergy, nextConfig.energyRequired);
        }

        // Consume energy required for evolution
        orb.chronoEnergy -= nextConfig.energyRequired;

        // Handle ESSENCE cost for evolution (optional based on config)
        uint256 essenceCost = nextConfig.evolutionEssenceCost;
        if (essenceCost > 0) {
             // Transfer ESSENCE from caller to contract
            bool success = ESSENCE_TOKEN.transferFrom(owner, address(this), essenceCost);
            if (!success) revert TransferFailed();
            // Note: This ESSENCE goes to the contract, could be burned or sent elsewhere.
        }

        // Evolve the Orb
        orb.epoch = nextEpoch;
        orb.lastUpdate = block.timestamp; // Reset update time after evolution
        // pendingYield is already updated by _updateOrbState

        emit OrbEvolved(tokenId, currentEpoch, nextEpoch);
    }

    /**
     * @dev Internal function to update an Orb's state based on time elapsed and oracle data.
     *      Calculates and adds chronoEnergy and pendingYield.
     *      Should be called before any interaction with an Orb's dynamic state (stake, unstake, claim, evolve, tokenURI).
     * @param tokenId The ID of the Orb NFT.
     */
    function _updateOrbState(uint256 tokenId) internal view { // Changed to view because it doesn't modify state here, only reads and calculates
         // Use a local storage pointer for gas efficiency
        OrbData storage orb = orbData[tokenId];

        uint256 lastUpdate = orb.lastUpdate;
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - lastUpdate;

        if (timeElapsed == 0) {
            return; // No time has passed, no update needed
        }

        uint8 currentEpoch = orb.epoch;

        if (currentEpoch >= epochConfigs.length) {
             // Handle edge case if epoch config doesn't exist (shouldn't happen if epochConfigs grows correctly)
             // For safety, maybe no gain or yield if in an undefined epoch state.
             // Or revert? Depends on desired behavior. Let's just return.
             return;
        }

        EpochConfig storage config = epochConfigs[currentEpoch];

        // --- Chrono-Energy Gain ---
        // Energy gain is based on time, staked ESSENCE, and potentially oracle data
        // Example calculation: gain = timeElapsed * stakedEssence * config.baseEnergyRate * oracle_factor
        // A simplified example using yieldRate:
        uint256 energyGained = (orb.stakedEssence * config.yieldRatePerSecond * timeElapsed) / 1e18; // Simple linear gain based on staked amount and time

        // Incorporate Oracle Data Influence (Example: positive data boosts, negative reduces)
        // Let's assume oracleData is an int256, scaled (e.g., 100 = neutral, 150 = 1.5x, 50 = 0.5x)
        // Need to handle potential division by zero or negative factors if oracleInfluenceFactor isn't handled carefully.
        // Simple positive boost example: factor = 1 + (oracleData / 1000.0) * oracleInfluenceFactor / 100
        // Let's make it simpler: multiplier is 1 + (oracleData * oracleInfluenceFactor) / SOME_SCALE
        // Ensure oracleData is bounded or scaled appropriately by the oracle adapter.
        // Assuming oracleData is small (e.g., -100 to +100) and oracleInfluenceFactor is percentage (e.g., 50 = 0.5x)
        // Influence: (currentOracleData * oracleInfluenceFactor) / 10000 (100 for factor, 100 for oracle scaling)
        int256 influence = (currentOracleData * int256(oracleInfluenceFactor)) / 10000;
        uint256 effectiveInfluence = (1e18 + uint256(influence)).mulDiv(1, 1e18); // Adds influence percentage to 1x base

        energyGained = energyGained.mulDiv(effectiveInfluence, 1e18); // Apply influence

        orb.chronoEnergy += energyGained;


        // --- Yield Calculation ---
        // Yield is based on time, staked ESSENCE, and the yield rate for the current epoch
        uint256 yieldAccrued = (orb.stakedEssence * config.yieldRatePerSecond * timeElapsed) / 1e18; // Simple linear yield calculation

        orb.pendingYield += yieldAccrued;

        // Update lastUpdate timestamp
        orb.lastUpdate = currentTime;
        // Note: This internal view function doesn't *actually* modify state.
        // A non-view wrapper function that calls this and then *writes* the updated
        // orb struct data would be needed for state-changing interactions.
        // However, Solidity storage references allow writing to `orb` directly
        // from functions that call this view helper first. So, functions like
        // stake/unstake/claim/evolve would do:
        // OrbData storage orb = orbData[tokenId];
        // _updateOrbState(tokenId); // This updates the data pointed to by `orb`
        // Then continue with the action...

        // The view function pattern is a bit awkward for state updates.
        // Let's refactor: _updateOrbState *should* modify state and be internal.
        // The calculation logic can be a view/pure helper.

    }

     /**
     * @dev Internal function to calculate earned energy and yield without modifying state.
     * @param tokenId The ID of the Orb NFT.
     * @return energyGained The calculated Chrono-Energy gained since last update.
     * @return yieldAccrued The calculated ESSENCE yield accrued since last update.
     */
    function _calculateStateUpdate(uint256 tokenId) internal view returns (uint256 energyGained, uint256 yieldAccrued) {
        OrbData storage orb = orbData[tokenId];
        uint256 lastUpdate = orb.lastUpdate;
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - lastUpdate;

        if (timeElapsed == 0 || orb.stakedEssence == 0) {
            return (0, 0); // No time passed or nothing staked, no gain/yield
        }

        uint8 currentEpoch = orb.epoch;
        if (currentEpoch >= epochConfigs.length) {
            return (0, 0); // Invalid epoch state
        }
        EpochConfig storage config = epochConfigs[currentEpoch];

        // --- Chrono-Energy Gain Calculation ---
        // Example: gain = timeElapsed * stakedEssence * config.baseEnergyRate * oracle_factor
        // Simple linear gain based on staked amount and time
        uint256 baseEnergyGain = (orb.stakedEssence * timeElapsed * 1e18) / 1e18; // Placeholder base rate (adjust as needed)

        // Incorporate Oracle Data Influence
        int256 influence = (currentOracleData * int256(oracleInfluenceFactor)) / 10000;
        // Apply influence percentage to 1x base
        // Ensure the effective influence is non-negative, e.g., min 10% or 0%
        uint256 effectiveInfluenceMultiplier = (1e18 + uint256(influence)).mulDiv(1, 1e18);
         if (effectiveInfluenceMultiplier < 1e17) effectiveInfluenceMultiplier = 1e17; // Example: minimum 10% multiplier

        energyGained = baseEnergyGain.mulDiv(effectiveInfluenceMultiplier, 1e18); // Apply influence

        // --- Yield Calculation ---
        yieldAccrued = (orb.stakedEssence * config.yieldRatePerSecond * timeElapsed) / 1e18; // Simple linear yield calculation

        return (energyGained, yieldAccrued);
    }


    /**
     * @dev Internal function to apply the calculated state update and reset lastUpdate.
     * @param tokenId The ID of the Orb NFT.
     * @param energyGained The amount of energy to add.
     * @param yieldAccrued The amount of yield to add.
     */
    function _applyStateUpdate(uint256 tokenId, uint256 energyGained, uint256 yieldAccrued) internal {
         OrbData storage orb = orbData[tokenId];
         orb.chronoEnergy += energyGained;
         orb.pendingYield += yieldAccrued;
         orb.lastUpdate = block.timestamp;
    }


    // --- Getters & View Functions ---

    /**
     * @notice Gets the current data for a specific Orb.
     * @param tokenId The ID of the Orb NFT.
     * @return OrbData struct.
     */
    function getOrbData(uint256 tokenId) public view orbExists(tokenId) returns (OrbData memory) {
        // Calculate pending updates before returning data
        (uint256 energyGained, uint256 yieldAccrued) = _calculateStateUpdate(tokenId);
        OrbData memory currentData = orbData[tokenId];
        currentData.chronoEnergy += energyGained;
        currentData.pendingYield += yieldAccrued;
        // Note: lastUpdate in the returned struct will still be the old one.
        return currentData;
    }

     /**
     * @notice Gets the current Chrono-Energy for a specific Orb, including accrued energy.
     * @param tokenId The ID of the Orb NFT.
     * @return The total current Chrono-Energy.
     */
    function getCurrentChronoEnergy(uint256 tokenId) public view orbExists(tokenId) returns (uint256) {
        (uint256 energyGained, ) = _calculateStateUpdate(tokenId);
        return orbData[tokenId].chronoEnergy + energyGained;
    }

     /**
     * @notice Gets the total staked ESSENCE in an Orb.
     * @param tokenId The ID of the Orb NFT.
     * @return The total staked ESSENCE.
     */
    function getTotalStakedEssenceInOrb(uint256 tokenId) public view orbExists(tokenId) returns (uint256) {
        return orbData[tokenId].stakedEssence;
    }


    /**
     * @notice Calculates the pending ESSENCE yield for an Orb.
     * @param tokenId The ID of the Orb NFT.
     * @return The calculated pending yield.
     */
    function calculatePendingEssenceYield(uint256 tokenId) public view orbExists(tokenId) returns (uint256) {
        ( , uint256 yieldAccrued) = _calculateStateUpdate(tokenId);
        return orbData[tokenId].pendingYield + yieldAccrued;
    }


    /**
     * @notice Checks if an Orb is eligible to evolve to the next epoch based on Chrono-Energy.
     * @param tokenId The ID of the Orb NFT.
     * @return bool True if evolvable, false otherwise.
     */
    function isOrbEvolvable(uint256 tokenId) public view orbExists(tokenId) returns (bool) {
        uint8 currentEpoch = orbData[tokenId].epoch;
        if (currentEpoch + 1 >= epochConfigs.length) {
            return false; // Already at max epoch
        }
        uint256 requiredEnergy = epochConfigs[currentEpoch + 1].energyRequired;
        uint256 currentEnergy = getCurrentChronoEnergy(tokenId);
        return currentEnergy >= requiredEnergy;
    }

    /**
     * @notice Gets the configuration details for a specific epoch.
     * @param epoch The epoch number.
     * @return EpochConfig struct.
     */
    function getEpochDetails(uint8 epoch) public view returns (EpochConfig memory) {
        require(epoch < epochConfigs.length, "Epoch config not found");
        return epochConfigs[epoch];
    }

     /**
     * @notice Gets key global parameters of the contract.
     * @return oracleAddress, oracleInfluenceFactor, paused status.
     */
    function getGlobalParameters() public view returns (address, uint256, bool) {
        return (oracleAddress, oracleInfluenceFactor, paused);
    }


    // --- Admin / Parameter Setting Functions (Owner Only) ---

    /**
     * @notice Sets the address of the ESSENCE token.
     * @dev Only callable by the owner. Should be set once during setup.
     */
    function setEssenceToken(address _essenceToken) public onlyOwner {
         // Add check if already set to non-zero address?
        ESSENCE_TOKEN = IERC20(_essenceToken);
        emit ParametersUpdated("ESSENCE_TOKEN");
    }


    /**
     * @notice Adds or updates the configuration for a specific epoch.
     * @dev Can extend the epochConfigs array or update an existing index.
     * @param epoch The epoch number to configure.
     * @param yieldRatePerSecond Yield rate in ESSENCE per second per staked token (scaled, e.g., 1e18).
     * @param energyRequired Chrono-Energy needed to evolve TO this epoch.
     * @param evolutionEssenceCost ESSENCE cost to evolve TO this epoch.
     */
    function addOrUpdateEpochConfig(
        uint8 epoch,
        uint256 yieldRatePerSecond,
        uint256 energyRequired,
        uint256 evolutionEssenceCost
    ) public onlyOwner {
        require(epoch == epochConfigs.length || epoch < epochConfigs.length, "Epoch index invalid");
        if (epoch == epochConfigs.length) {
            epochConfigs.push(EpochConfig(yieldRatePerSecond, energyRequired, evolutionEssenceCost));
        } else {
            epochConfigs[epoch] = EpochConfig(yieldRatePerSecond, energyRequired, evolutionEssenceCost);
        }
        emit ParametersUpdated(string(abi.encodePacked("EpochConfig_", Strings.toString(epoch))));
    }

    /**
     * @notice Sets the base URI for token metadata.
     * @dev The final URI will be baseURI/tokenId?stateparams.
     */
    function setMetadataBaseURI(string memory _newURI) public onlyOwner {
        metadataBaseURI = _newURI;
        emit ParametersUpdated("metadataBaseURI");
    }

    /**
     * @notice Sets the address of the trusted oracle adapter contract.
     * @dev This address is allowed to call `receiveOracleData`.
     */
    function setOracleAddress(address _oracle) public onlyOwner {
        oracleAddress = _oracle;
        emit ParametersUpdated("oracleAddress");
    }

    /**
     * @notice Sets the factor influencing oracle data effect on energy gain.
     * @dev e.g., 100 = 1x influence (value from oracle is used directly scaled), 50 = 0.5x influence.
     *      Requires careful consideration of oracle data scaling and potential negative values.
     */
    function setOracleInfluenceFactor(uint256 _factor) public onlyOwner {
        oracleInfluenceFactor = _factor;
        emit ParametersUpdated("oracleInfluenceFactor");
    }


    /**
     * @notice Pauses staking, unstaking, claiming, evolving, and transfers.
     * @dev Only callable by the owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @notice Unpauses the contract.
     * @dev Only callable by the owner.
     */
    function unpauseContract() public onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @notice Allows the owner to withdraw accumulated ETH (e.g., from a hypothetical mint fee).
     * @param recipient The address to send ETH to.
     */
    function withdrawEth(address payable recipient) public onlyOwner {
        require(recipient != address(0), "Withdraw: zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "Withdraw: no ETH balance");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Withdraw: ETH transfer failed");
    }

     /**
     * @notice Allows the owner to withdraw accumulated ESSENCE tokens held by the contract.
     * @dev This could be ESSENCE collected from evolution costs or unallocated funds.
     * @param recipient The address to send ESSENCE to.
     * @param amount The amount of ESSENCE to withdraw.
     */
    function withdrawEssence(address recipient, uint256 amount) public onlyOwner {
        require(recipient != address(0), "Withdraw: zero address");
        require(amount > 0, "Withdraw: amount must be > 0");
        require(ESSENCE_TOKEN.balanceOf(address(this)) >= amount, "Withdraw: Insufficient contract balance");

        bool success = ESSENCE_TOKEN.transfer(recipient, amount);
        if (!success) revert TransferFailed();
    }

    // --- Oracle Callback Function ---

    /**
     * @notice Callback function intended to receive data from a trusted oracle adapter.
     * @dev This function should ONLY be callable by the address set in `oracleAddress`.
     * @param data The data received from the oracle (e.g., a price feed value, a random number).
     */
    function receiveOracleData(int256 data) public {
        // Example: Simple check for trusted oracle address
        if (_msgSender() != oracleAddress) revert CallerIsNotOracle(_msgSender(), oracleAddress);

        // Process the received data
        // In a real system, this might update a state variable, trigger logic, etc.
        currentOracleData = data;

        emit OracleDataUpdated(data, block.timestamp);
    }

    // --- Internal ERC721 Helper Functions (Basic Implementation) ---
    // These are minimal examples. Full ERC721 requires more getters and checks.

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[tokenId] == address(0), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual orbExists(tokenId) {
         address owner = ownerOf(tokenId); // Implicitly checks existence

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[owner] -= 1;
        delete _owners[tokenId]; // Use delete for storage mappings

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);

        // Optionally handle staked ESSENCE on burn: send to owner, burn, or keep in contract
        // For simplicity, let's assume staked essence is lost or needs to be unstaked first.
        // If it should transfer to owner:
        // OrbData storage orb = orbData[tokenId];
        // if (orb.stakedEssence > 0) {
        //     bool success = ESSENCE_TOKEN.transfer(owner, orb.stakedEssence);
        //     // Handle transfer success/failure
        // }
        // delete orbData[tokenId]; // Remove orb data on burn
    }


    // Hook that is called before any token transfer.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    // Hook that is called after any token transfer.
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    // --- Fallback for ETH ---
    receive() external payable {}

}

// Helper for string conversions (basic, can use OpenZeppelin's)
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

// Helper for mulDiv (can use OpenZeppelin's SafeMath)
library Math {
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        uint256 xy = x * y;
        require(denominator != 0, "Math: division by zero");
        result = xy / denominator;
    }
}

// Use the Math library
using Math for uint256;

// Minimal ERC721 events for standard compatibility
abstract contract ERC721Events {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

// Extend the main contract to emit ERC721 events
abstract contract ChronoGenesisOrbBase is ERC721Events {}

contract ChronoGenesisOrb is ChronoGenesisOrbBase, Ownable, ReentrancyGuard {
    // ... (all code from ChronoGenesisOrb above goes here) ...
    // Need to adjust the contract declaration line to inherit from ChronoGenesisOrbBase

    // Corrected inheritance:
    // contract ChronoGenesisOrb is ChronoGenesisOrbBase, Ownable, ReentrancyGuard {
    //     using Strings for uint256;
    //     using Math for uint256; // Added Math library usage

    //     // ... rest of the contract ...
    // }

    // Let's integrate the Math library using statement into the final contract
    // and ensure events are properly emitted.
}

// Final combined contract with necessary elements

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Note: In a production environment, you would use audited libraries
// like OpenZeppelin for ERC721, ERC20 interfaces, Ownable, ReentrancyGuard, etc.
// This code provides a custom implementation skeleton focused on the unique logic
// requested, assuming standard interface requirements.

// Define interfaces we need
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IOracle {
    // Example interface for an oracle callback
    // In a real Chainlink integration, this would match their VRF/Price Feed interfaces
    function fulfill(bytes32 requestId, int256 value) external; // Example: fulfill a request with a value
}

// Basic access control (simplified Ownable pattern)
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Basic ReentrancyGuard (simplified)
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

// Helper for string conversions (basic)
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

// Helper for mulDiv
library Math {
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        uint256 xy = x * y;
        require(denominator != 0, "Math: division by zero");
        result = xy / denominator;
    }
}

// Minimal ERC721 events for standard compatibility
abstract contract ERC721Events {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}


contract ChronoGenesisOrb is ERC721Events, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Math for uint256;

    // --- Structs ---
    struct OrbData {
        uint8 epoch; // Current evolution stage
        uint256 chronoEnergy; // Accumulates over time while staked
        uint256 stakedEssence; // Amount of ESSENCE staked in this orb
        uint256 lastUpdate; // Timestamp of the last state update
        uint256 pendingYield; // Unclaimed ESSENCE yield
    }

    struct EpochConfig {
        uint256 yieldRatePerSecond; // ESSENCE yield rate per second per staked token (scaled, e.g., 1e18 = 1 ESSENCE per second per ESSENCE staked)
        uint256 energyRequired; // Chrono-Energy needed to evolve to this epoch (index = next epoch)
        uint256 evolutionEssenceCost; // ESSENCE cost to evolve to this epoch (index = next epoch)
        // Add more attributes here, e.g., visual representation id, boost factors, etc.
    }

    // --- State Variables ---
    IERC20 public ESSENCE_TOKEN; // The utility/yield token (mutable via owner initially if needed)
    string public metadataBaseURI; // Base URI for fetching token metadata

    mapping(uint256 => OrbData) private orbData;
    uint256 private _nextTokenId; // Counter for minting new tokens

    EpochConfig[] public epochConfigs; // Configurations for each epoch (epoch 0, 1, 2...)

    address public oracleAddress; // Address of a trusted oracle contract/adapter
    int256 public currentOracleData; // Last received oracle data
    uint256 public oracleInfluenceFactor = 10000; // How much oracle data affects energy gain (scaled, e.g., 10000 = 1x, 5000 = 0.5x). Assumes oracleData is scaled like Chainlink AggregatorV3 (e.g., 8 decimals)


    // Basic ERC721 data (simplified, real would use library)
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Pausability
    bool public paused = false;

    // --- Events ---
    event OrbMinted(address indexed owner, uint256 indexed tokenId, uint8 initialEpoch);
    event EssenceStaked(address indexed owner, uint256 indexed tokenId, uint256 amount);
    event EssenceUnstaked(address indexed owner, uint256 indexed tokenId, uint256 amount);
    event EssenceYieldClaimed(address indexed owner, uint256 indexed tokenId, uint256 amount);
    event OrbEvolved(uint256 indexed tokenId, uint8 indexed oldEpoch, uint8 indexed newEpoch);
    event OracleDataUpdated(int256 indexed newData, uint256 timestamp);
    event ParametersUpdated(string parameterName);
    event Paused(address account);
    event Unpaused(address account);

    // --- Errors (Solidity 0.8.4+) ---
    error TokenDoesNotExist(uint256 tokenId);
    error NotTokenOwnerOrApproved(address caller, uint256 tokenId); // ERC721
    error InvalidAmount();
    error InsufficientEssence(uint256 required, uint256 has); // For unstaking
    error NotEligibleToEvolve(uint256 tokenId, uint256 currentEnergy, uint256 requiredEnergy);
    error AlreadyMaxEpoch(uint256 tokenId);
    error CallerIsNotOracle(address caller, address expectedOracle);
    error ContractPaused();
    error TransferFailed(); // ERC20/ETH transfer failure
    error EssenceTokenNotSet(); // If ESSENCE_TOKEN is address(0)
    error MintToZeroAddress(); // ERC721
    error TokenAlreadyMinted(); // ERC721
    error TransferFromIncorrectOwner(); // ERC721
    error TransferToZeroAddress(); // ERC721
    error NotApprovedOrOwner(); // ERC721 simplified
    error NothingToClaim(); // Claim yield
    error NotPaused(); // Unpause
    error AlreadyPaused(); // Pause
    error WithdrawZeroEth();
    error WithdrawZeroEssence();
    error InsufficientContractEssence();


    // --- Modifiers ---
    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    modifier orbExists(uint256 tokenId) {
        if (_owners[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        _;
    }

    modifier onlyOrbOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "ChronoGenesisOrb: caller is not orb owner");
        _;
    }

    // --- Constructor ---
    constructor(address _essenceToken, string memory _metadataBaseURI) {
        ESSENCE_TOKEN = IERC20(_essenceToken);
        metadataBaseURI = _metadataBaseURI;

        // Initialize epoch 0 config (base state)
        // yieldRatePerSecond (scaled 1e18), energyRequired (to evolve TO epoch 1), evolutionEssenceCost (to evolve TO epoch 1)
        epochConfigs.push(EpochConfig(0, 1e6, 1e6)); // Epoch 0: no yield, needs 1M energy & 1M ESSENCE to reach Epoch 1
    }

    // --- Core Logic Functions (Partial ERC721 + Custom) ---

    // ERC721 Standard View Functions
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist(tokenId);
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId); // Check existence
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        ownerOf(tokenId); // Check existence
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // ERC721 Transfer Functions
    function transferFrom(address from, address to, uint256 tokenId) public virtual nonReentrant whenNotPaused orbExists(tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual nonReentrant whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual nonReentrant whenNotPaused orbExists(tokenId) {
         require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    // tokenURI is dynamic based on state
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        orbExists(tokenId); // Ensure token exists

        // Calculate pending updates for metadata representation
        (uint256 energyGained, uint256 yieldAccrued) = _calculateStateUpdate(tokenId);
        OrbData memory currentData = orbData[tokenId];

        string memory base = metadataBaseURI;
        string memory state = string(abi.encodePacked(
            "epoch=", Strings.toString(currentData.epoch),
            "&energy=", Strings.toString(currentData.chronoEnergy + energyGained), // Show potential energy
            "&staked=", Strings.toString(currentData.stakedEssence),
            "&yield=", Strings.toString(currentData.pendingYield + yieldAccrued) // Show potential yield
            // Add other relevant data points here
        ));

        return string(abi.encodePacked(base, "/", tokenId.toString(), "?", state));
    }

    // --- Internal ERC721 Helper Functions ---

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

     function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != address(0), "ERC721: approve caller is zero address");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Before transferring, claim pending yield to the 'from' address
        _claimEssenceYieldInternal(tokenId); // Handles state update and transfer

        _beforeTokenTransfer(from, to, tokenId);

        _tokenApprovals[tokenId] = address(0);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        private returns (bool)
    {
        if (to.code.length == 0) {
            return true; // EOA can always receive
        }
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
            return retval == _ERC721_RECEIVED;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId); // Checks existence
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Hook that is called before any token transfer.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    // Hook that is called after any token transfer.
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}


    // --- Custom Orb Functions ---

    /**
     * @notice Mints a new ChronoGenesis Orb.
     * @dev Callable by anyone (example: free mint). Emits OrbMinted event.
     *      Initializes Orb data to epoch 0.
     *      For simplicity, this is a free mint example up to a theoretical max `_nextTokenId`.
     */
    function mint() public nonReentrant whenNotPaused returns (uint256) {
        uint256 newItemId = _nextTokenId;
        _nextTokenId++; // Simple incrementing ID

        _mint(_msgSender(), newItemId);

        // Initialize Orb data
        orbData[newItemId] = OrbData({
            epoch: 0,
            chronoEnergy: 0,
            stakedEssence: 0,
            lastUpdate: block.timestamp,
            pendingYield: 0
        });

        emit OrbMinted(_msgSender(), newItemId, 0);
        return newItemId;
    }

    /**
     * @notice Stakes ESSENCE tokens into a specific Orb owned by the caller.
     * @dev Requires ESSENCE allowance for the contract. Updates Orb state and calculates accrued energy/yield. Emits EssenceStaked event.
     * @param tokenId The ID of the Orb NFT.
     * @param amount The amount of ESSENCE to stake.
     */
    function stakeEssenceIntoOrb(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused orbExists(tokenId) onlyOrbOwner(tokenId) {
        if (amount == 0) revert InvalidAmount();
        if (address(ESSENCE_TOKEN) == address(0)) revert EssenceTokenNotSet();

        // Update state before staking more
        _updateOrbState(tokenId);

        // Transfer ESSENCE from caller to this contract
        bool success = ESSENCE_TOKEN.transferFrom(_msgSender(), address(this), amount);
        if (!success) revert TransferFailed();

        orbData[tokenId].stakedEssence += amount;
        // lastUpdate is reset in _updateOrbState, already done above

        emit EssenceStaked(_msgSender(), tokenId, amount);
    }

    /**
     * @notice Unstakes ESSENCE tokens from a specific Orb owned by the caller.
     * @dev Updates Orb state, calculates accrued energy/yield, and transfers unstaked tokens back. Emits EssenceUnstaked event.
     * @param tokenId The ID of the Orb NFT.
     * @param amount The amount of ESSENCE to unstake.
     */
    function unstakeEssenceFromOrb(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused orbExists(tokenId) onlyOrbOwner(tokenId) {
        if (amount == 0) revert InvalidAmount();
         if (address(ESSENCE_TOKEN) == address(0)) revert EssenceTokenNotSet();


        // Update state before unstaking
        _updateOrbState(tokenId);

        OrbData storage orb = orbData[tokenId];
        if (amount > orb.stakedEssence) revert InsufficientEssence(amount, orb.stakedEssence);

        orb.stakedEssence -= amount;
        // lastUpdate is reset in _updateOrbState, already done above

        // Transfer ESSENCE from contract to caller
        bool success = ESSENCE_TOKEN.transfer(_msgSender(), amount);
        if (!success) revert TransferFailed();

        emit EssenceUnstaked(_msgSender(), tokenId, amount);
    }

    /**
     * @notice Claims accrued ESSENCE yield for a specific Orb owned by the caller.
     * @dev Updates Orb state, calculates accrued energy/yield, transfers pending yield, and resets pendingYield. Emits EssenceYieldClaimed event.
     * @param tokenId The ID of the Orb NFT.
     */
    function claimEssenceYield(uint256 tokenId) public nonReentrant whenNotPaused orbExists(tokenId) onlyOrbOwner(tokenId) {
        _claimEssenceYieldInternal(tokenId);
    }

    /**
     * @dev Internal helper to claim yield. Updates state, transfers tokens, emits event.
     *      Used by claimEssenceYield and _transfer.
     * @param tokenId The ID of the Orb NFT.
     */
    function _claimEssenceYieldInternal(uint256 tokenId) internal {
        // Update state before claiming
        _updateOrbState(tokenId);

        OrbData storage orb = orbData[tokenId];
        uint256 yieldToClaim = orb.pendingYield;
        if (yieldToClaim == 0) revert NothingToClaim();

        orb.pendingYield = 0; // Reset pending yield

        // Transfer ESSENCE from contract to owner
        bool success = ESSENCE_TOKEN.transfer(ownerOf(tokenId), yieldToClaim);
        if (!success) revert TransferFailed(); // Revert if transfer fails

        emit EssenceYieldClaimed(ownerOf(tokenId), tokenId, yieldToClaim);
    }


    /**
     * @notice Attempts to evolve an Orb owned by the caller to the next epoch.
     * @dev Requires sufficient Chrono-Energy and potentially ESSENCE cost. Updates Orb state, consumes energy/ESSENCE, and increments epoch. Emits OrbEvolved event.
     * @param tokenId The ID of the Orb NFT.
     */
    function evolveOrb(uint256 tokenId) public nonReentrant whenNotPaused orbExists(tokenId) onlyOrbOwner(tokenId) {
         if (address(ESSENCE_TOKEN) == address(0)) revert EssenceTokenNotSet();

        // Update state before checking evolution eligibility
        _updateOrbState(tokenId);

        OrbData storage orb = orbData[tokenId];
        uint8 currentEpoch = orb.epoch;
        uint8 nextEpoch = currentEpoch + 1;

        if (nextEpoch >= epochConfigs.length) {
            revert AlreadyMaxEpoch(tokenId);
        }

        EpochConfig storage nextConfig = epochConfigs[nextEpoch];

        if (orb.chronoEnergy < nextConfig.energyRequired) {
            revert NotEligibleToEvolve(tokenId, orb.chronoEnergy, nextConfig.energyRequired);
        }

        // Consume energy required for evolution
        orb.chronoEnergy -= nextConfig.energyRequired;

        // Handle ESSENCE cost for evolution (optional based on config)
        uint256 essenceCost = nextConfig.evolutionEssenceCost;
        if (essenceCost > 0) {
             // Transfer ESSENCE from caller to contract
            bool success = ESSENCE_TOKEN.transferFrom(_msgSender(), address(this), essenceCost);
            if (!success) revert TransferFailed();
            // Note: This ESSENCE goes to the contract, could be burned or sent elsewhere.
        }

        // Evolve the Orb
        orb.epoch = nextEpoch;
        // lastUpdate is reset in _updateOrbState, already done above
        // pendingYield is already updated by _updateOrbState

        emit OrbEvolved(tokenId, currentEpoch, nextEpoch);
    }

    /**
     * @dev Internal function to update an Orb's state based on time elapsed and oracle data.
     *      Calculates and adds chronoEnergy and pendingYield.
     *      Should be called before any interaction with an Orb's dynamic state (stake, unstake, claim, evolve).
     * @param tokenId The ID of the Orb NFT.
     */
    function _updateOrbState(uint256 tokenId) internal {
        OrbData storage orb = orbData[tokenId];
        uint256 lastUpdate = orb.lastUpdate;
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - lastUpdate;

        if (timeElapsed == 0 || orb.stakedEssence == 0) {
             orb.lastUpdate = currentTime; // Still update timestamp even if no gain/yield
            return;
        }

        uint8 currentEpoch = orb.epoch;
        if (currentEpoch >= epochConfigs.length) {
             orb.lastUpdate = currentTime; // Still update timestamp even if in invalid epoch
             return;
        }
        EpochConfig storage config = epochConfigs[currentEpoch];

        // --- Chrono-Energy Gain Calculation ---
        // Example: gain = timeElapsed * stakedEssence * config.baseEnergyRate * oracle_factor
        // Using yieldRate as a base for energy gain for simplicity, scaled down
        uint256 baseEnergyGain = (orb.stakedEssence * config.yieldRatePerSecond * timeElapsed) / 1e18; // Example: 1 unit energy per sec per staked token @ base rate

        // Incorporate Oracle Data Influence
        // Assuming currentOracleData is scaled like AggregatorV3 (e.g., 8 decimals),
        // and oracleInfluenceFactor is scaled (e.g., 10000 = 1x influence multiplier).
        // Influence multiplier: 1 + (oracleData * oracleInfluenceFactor) / (10^oracle_decimals * 10000)
        // Let's simplify and assume oracleData is a percentage influence scaled by 10000 (e.g., 10000 = +100%, 0 = +0%, -5000 = -50%)
        // Effective multiplier = 1 + (oracleData / 10000)
        // Example: oracleData = 5000 (+50%), factor = 10000. Multiplier = 1 + (5000/10000) = 1.5x
        // Example: oracleData = -2000 (-20%), factor = 10000. Multiplier = 1 + (-2000/10000) = 0.8x
        // Need to ensure multiplier is non-negative.
        int256 influencePercentScaled = (currentOracleData * int256(oracleInfluenceFactor)) / 1e8; // Assuming oracle data has 8 decimals
        int256 totalMultiplierScaled = 1e18 + (influencePercentScaled * 1e18 / 10000); // Add influence percentage to 1x base (scaled 1e18)

        // Ensure minimum multiplier (e.g., 10% of base energy gain)
        if (totalMultiplierScaled < 1e17) totalMultiplierScaled = 1e17; // Example: minimum 0.1x multiplier


        uint256 energyGained = baseEnergyGain.mulDiv(uint256(totalMultiplierScaled), 1e18); // Apply influence

        orb.chronoEnergy += energyGained;


        // --- Yield Calculation ---
        // Yield is based on time, staked ESSENCE, and the yield rate for the current epoch
        uint256 yieldAccrued = (orb.stakedEssence * config.yieldRatePerSecond * timeElapsed) / 1e18; // Simple linear yield calculation

        orb.pendingYield += yieldAccrued;

        // Update lastUpdate timestamp
        orb.lastUpdate = currentTime;
    }


    // --- Getters & View Functions ---

    /**
     * @notice Gets the current data for a specific Orb, including potentially accrued state since last update.
     * @param tokenId The ID of the Orb NFT.
     * @return OrbData struct with current state including accrued yield/energy.
     */
    function getOrbData(uint256 tokenId) public view orbExists(tokenId) returns (OrbData memory) {
        // Calculate pending updates without modifying state
        uint256 timeElapsed = block.timestamp - orbData[tokenId].lastUpdate;
        uint8 currentEpoch = orbData[tokenId].epoch;
        uint256 energyGained = 0;
        uint256 yieldAccrued = 0;

        if (timeElapsed > 0 && orbData[tokenId].stakedEssence > 0 && currentEpoch < epochConfigs.length) {
             EpochConfig storage config = epochConfigs[currentEpoch];

             // --- Chrono-Energy Gain Calculation (View) ---
            uint256 baseEnergyGain = (orbData[tokenId].stakedEssence * timeElapsed * 1e18) / 1e18; // Placeholder base rate

            int256 influencePercentScaled = (currentOracleData * int256(oracleInfluenceFactor)) / 1e8; // Assuming oracle data has 8 decimals
            int256 totalMultiplierScaled = 1e18 + (influencePercentScaled * 1e18 / 10000);
            if (totalMultiplierScaled < 1e17) totalMultiplierScaled = 1e17; // Example: minimum 0.1x multiplier

            energyGained = baseEnergyGain.mulDiv(uint256(totalMultiplierScaled), 1e18);

            // --- Yield Calculation (View) ---
            yieldAccrued = (orbData[tokenId].stakedEssence * config.yieldRatePerSecond * timeElapsed) / 1e18;
        }

        OrbData memory currentData = orbData[tokenId];
        currentData.chronoEnergy += energyGained;
        currentData.pendingYield += yieldAccrued;

        return currentData;
    }

     /**
     * @notice Gets the current Chrono-Energy for a specific Orb, including accrued energy since last update.
     * @param tokenId The ID of the Orb NFT.
     * @return The total current Chrono-Energy.
     */
    function getCurrentChronoEnergy(uint256 tokenId) public view orbExists(tokenId) returns (uint256) {
        uint256 timeElapsed = block.timestamp - orbData[tokenId].lastUpdate;
        uint8 currentEpoch = orbData[tokenId].epoch;
        uint256 energyGained = 0;

        if (timeElapsed > 0 && orbData[tokenId].stakedEssence > 0 && currentEpoch < epochConfigs.length) {
             EpochConfig storage config = epochConfigs[currentEpoch];
             uint256 baseEnergyGain = (orbData[tokenId].stakedEssence * timeElapsed * 1e18) / 1e18;

             int256 influencePercentScaled = (currentOracleData * int256(oracleInfluenceFactor)) / 1e8;
             int256 totalMultiplierScaled = 1e18 + (influencePercentScaled * 1e18 / 10000);
             if (totalMultiplierScaled < 1e17) totalMultiplierScaled = 1e17;

             energyGained = baseEnergyGain.mulDiv(uint256(totalMultiplierScaled), 1e18);
        }

        return orbData[tokenId].chronoEnergy + energyGained;
    }

     /**
     * @notice Gets the total staked ESSENCE in an Orb.
     * @param tokenId The ID of the Orb NFT.
     * @return The total staked ESSENCE.
     */
    function getTotalStakedEssenceInOrb(uint256 tokenId) public view orbExists(tokenId) returns (uint256) {
        return orbData[tokenId].stakedEssence;
    }


    /**
     * @notice Calculates the pending ESSENCE yield for an Orb, including accrued yield since last update.
     * @param tokenId The ID of the Orb NFT.
     * @return The calculated pending yield.
     */
    function calculatePendingEssenceYield(uint256 tokenId) public view orbExists(tokenId) returns (uint256) {
         uint256 timeElapsed = block.timestamp - orbData[tokenId].lastUpdate;
        uint8 currentEpoch = orbData[tokenId].epoch;
        uint256 yieldAccrued = 0;

        if (timeElapsed > 0 && orbData[tokenId].stakedEssence > 0 && currentEpoch < epochConfigs.length) {
             EpochConfig storage config = epochConfigs[currentEpoch];
             yieldAccrued = (orbData[tokenId].stakedEssence * config.yieldRatePerSecond * timeElapsed) / 1e18;
        }

        return orbData[tokenId].pendingYield + yieldAccrued;
    }


    /**
     * @notice Checks if an Orb is eligible to evolve to the next epoch based on Chrono-Energy.
     * @param tokenId The ID of the Orb NFT.
     * @return bool True if evolvable, false otherwise.
     */
    function isOrbEvolvable(uint256 tokenId) public view orbExists(tokenId) returns (bool) {
        uint8 currentEpoch = orbData[tokenId].epoch;
        if (currentEpoch + 1 >= epochConfigs.length) {
            return false; // Already at max epoch
        }
        uint256 requiredEnergy = epochConfigs[currentEpoch + 1].energyRequired;
        uint256 currentEnergy = getCurrentChronoEnergy(tokenId); // Uses view function to get current energy
        return currentEnergy >= requiredEnergy;
    }

    /**
     * @notice Gets the configuration details for a specific epoch.
     * @param epoch The epoch number.
     * @return EpochConfig struct.
     */
    function getEpochDetails(uint8 epoch) public view returns (EpochConfig memory) {
        require(epoch < epochConfigs.length, "Epoch config not found");
        return epochConfigs[epoch];
    }

     /**
     * @notice Gets key global parameters of the contract.
     * @return oracleAddress, oracleInfluenceFactor, paused status.
     */
    function getGlobalParameters() public view returns (address, uint256, bool) {
        return (oracleAddress, oracleInfluenceFactor, paused);
    }


    // --- Admin / Parameter Setting Functions (Owner Only) ---

    /**
     * @notice Sets the address of the ESSENCE token.
     * @dev Only callable by the owner. Should be set once during setup.
     */
    function setEssenceToken(address _essenceToken) public onlyOwner {
         // Consider adding a check if it's already set and non-zero to prevent accidental changes
        ESSENCE_TOKEN = IERC20(_essenceToken);
        emit ParametersUpdated("ESSENCE_TOKEN");
    }


    /**
     * @notice Adds or updates the configuration for a specific epoch.
     * @dev Can extend the epochConfigs array or update an existing index.
     * @param epoch The epoch number to configure.
     * @param yieldRatePerSecond Yield rate in ESSENCE per second per staked token (scaled, e.g., 1e18).
     * @param energyRequired Chrono-Energy needed to evolve TO this epoch.
     * @param evolutionEssenceCost ESSENCE cost to evolve TO this epoch.
     */
    function addOrUpdateEpochConfig(
        uint8 epoch,
        uint256 yieldRatePerSecond,
        uint256 energyRequired,
        uint256 evolutionEssenceCost
    ) public onlyOwner {
        require(epoch == epochConfigs.length || epoch < epochConfigs.length, "Epoch index invalid");
        if (epoch == epochConfigs.length) {
            epochConfigs.push(EpochConfig(yieldRatePerSecond, energyRequired, evolutionEssenceCost));
        } else {
            epochConfigs[epoch] = EpochConfig(yieldRatePerSecond, energyRequired, evolutionEssenceCost);
        }
        emit ParametersUpdated(string(abi.encodePacked("EpochConfig_", Strings.toString(epoch))));
    }

    /**
     * @notice Sets the base URI for token metadata.
     * @dev The final URI will be baseURI/tokenId?stateparams.
     */
    function setMetadataBaseURI(string memory _newURI) public onlyOwner {
        metadataBaseURI = _newURI;
        emit ParametersUpdated("metadataBaseURI");
    }

    /**
     * @notice Sets the address of the trusted oracle adapter contract.
     * @dev This address is allowed to call `receiveOracleData`.
     */
    function setOracleAddress(address _oracle) public onlyOwner {
        oracleAddress = _oracle;
        emit ParametersUpdated("oracleAddress");
    }

    /**
     * @notice Sets the factor influencing oracle data effect on energy gain.
     * @dev e.g., 10000 = 1x influence, 5000 = 0.5x influence, 0 = 0x influence. Scaled by 10000.
     *      This factor is multiplied by the oracle data (assumed 8 decimals) to get a percentage influence.
     */
    function setOracleInfluenceFactor(uint256 _factor) public onlyOwner {
        oracleInfluenceFactor = _factor;
        emit ParametersUpdated("oracleInfluenceFactor");
    }


    /**
     * @notice Pauses staking, unstaking, claiming, evolving, and transfers.
     * @dev Only callable by the owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @notice Unpauses the contract.
     * @dev Only callable by the owner.
     */
    function unpauseContract() public onlyOwner {
        if (!paused) revert NotPaused();
        paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @notice Allows the owner to withdraw accumulated ETH (e.g., from a hypothetical mint fee).
     * @param recipient The address to send ETH to.
     */
    function withdrawEth(address payable recipient) public onlyOwner {
        require(recipient != address(0), "Withdraw: zero address");
        uint256 balance = address(this).balance;
        if (balance == 0) revert WithdrawZeroEth();
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Withdraw: ETH transfer failed");
    }

     /**
     * @notice Allows the owner to withdraw accumulated ESSENCE tokens held by the contract.
     * @dev This could be ESSENCE collected from evolution costs or unallocated funds.
     * @param recipient The address to send ESSENCE to.
     * @param amount The amount of ESSENCE to withdraw.
     */
    function withdrawEssence(address recipient, uint256 amount) public onlyOwner {
        require(recipient != address(0), "Withdraw: zero address");
        if (amount == 0) revert WithdrawZeroEssence();
         if (address(ESSENCE_TOKEN) == address(0)) revert EssenceTokenNotSet();

        if (ESSENCE_TOKEN.balanceOf(address(this)) < amount) revert InsufficientContractEssence();

        bool success = ESSENCE_TOKEN.transfer(recipient, amount);
        if (!success) revert TransferFailed();
    }

    // --- Oracle Callback Function ---

    /**
     * @notice Callback function intended to receive data from a trusted oracle adapter.
     * @dev This function should ONLY be callable by the address set in `oracleAddress`.
     *      Updates the `currentOracleData` state variable.
     * @param data The data received from the oracle (e.g., a price feed value, a random number).
     */
    function receiveOracleData(int256 data) public {
        // Example: Simple check for trusted oracle address
        if (_msgSender() != oracleAddress) revert CallerIsNotOracle(_msgSender(), oracleAddress);

        // Update the received data
        currentOracleData = data;

        emit OracleDataUpdated(data, block.timestamp);
    }

    // --- Internal ERC721 Helper Functions (Basic Implementation) ---

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (_owners[tokenId] != address(0)) revert TokenAlreadyMinted();

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual orbExists(tokenId) {
         address owner = ownerOf(tokenId); // Implicitly checks existence

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[owner] -= 1;
        delete _owners[tokenId]; // Use delete for storage mappings
        delete orbData[tokenId]; // Delete associated orb data on burn

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);

        // Note: Staked ESSENCE should ideally be handled before burning.
        // The unstake function should be used by the owner prior to burning.
        // If _burn was callable by others (e.g., protocol burning), logic to handle staked tokens would be needed here.
    }

    // --- ERC165 Support (Minimal) ---
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC721
            || interfaceId == _INTERFACE_ID_ERC721_METADATA
            || interfaceId == type(Ownable).interfaceId // Minimal Ownable interfaceId
            || super.supportsInterface(interfaceId); // If inheriting from other interfaces
    }


    // --- Fallback for ETH ---
    receive() external payable {}

}
```