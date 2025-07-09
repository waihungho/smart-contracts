Okay, let's design a smart contract that combines several advanced concepts:
1.  **Resource Generation via Staking:** Users stake a utility token to generate a non-transferable 'Energy' resource over time.
2.  **Dynamic NFTs:** Users own unique NFTs (let's call them "Artefacts") whose attributes are stored *on-chain* and can change based on interactions.
3.  **On-Chain Crafting/Transformation:** A core mechanic where users combine (burn) certain Artefacts and expend Energy/Tokens to create new, different Artefacts with potentially better or different attributes.
4.  **Attribute Evolution/Attunement:** A mechanism to spend Energy to 'attune' an Artefact, potentially altering its on-chain attributes based on logic and maybe a pseudo-random factor (with caveats about on-chain randomness).
5.  **Decay/Volatility:** Introduce mechanics where generated Energy or certain Artefact attributes decay over time or are volatile.
6.  **Parametric Control:** The core mechanics (generation rates, costs, outcomes) are governed by adjustable parameters.
7.  **Treasury/Fee System:** Fees collected from interactions fund a contract treasury.
8.  **Internal Token Management:** The contract manages its own simple ERC-20 (utility token, "Flux") and ERC-721 (Artefacts). *Note: For a real system, you'd use standard library implementations or deploy separate contracts and interact.* Here, they are simplified *within* the main contract for demonstration and function count.

Let's call this contract the "Chrono-Synthesizer Nexus".

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoSynthesizerNexus
 * @dev A smart contract system for resource generation (Flux staking),
 *      dynamic NFT management (Artefacts), on-chain crafting/fusion,
 *      and attribute attunement. Artefact attributes are stored and
 *      modified directly on-chain.
 *
 * Outline:
 * 1.  Error Definitions
 * 2.  Events
 * 3.  Structs for Artefact Attributes and Global Parameters
 * 4.  State Variables (Owner, Tokens, Staking, Artefacts, Treasury, Parameters)
 * 5.  Modifiers
 * 6.  Internal ERC-20 (Flux) Implementations
 * 7.  Internal ERC-721 (Artefact) Implementations
 * 8.  Internal Core Nexus Logic Helpers
 * 9.  Constructor
 * 10. ERC-20 (Flux) Public Interface Functions
 * 11. ERC-721 (Artefact) Public Interface Functions
 * 12. Core Nexus Interaction Functions (Stake, Claim, Attune, Fuse, Extract)
 * 13. View/Calculation Functions
 * 14. Admin/Control Functions
 *
 * Concepts Covered:
 * - Staking for yield (Resonance Energy)
 * - Dynamic NFT attributes stored and modified on-chain
 * - Complex resource management (Flux, Resonance Energy)
 * - On-chain crafting/fusion with outcome based on inputs/parameters
 * - Attribute decay/volatility (simulated via calculations)
 * - Parameterized mechanics
 * - Simple internal token management (ERC20 & ERC721)
 * - Treasury system
 * - Basic Access Control (Owner)
 *
 * Function Summary:
 * ERC-20 (Flux) Interface:
 * - nameQF, symbolQF, decimalsQF, getQFTotalSupply: Standard ERC-20 view functions.
 * - transferQF, approveQF, transferFromQF, allowanceQF, getQFBalance: Standard ERC-20 transfer/approval functions.
 * ERC-721 (Artefact) Interface:
 * - nameArtefact, symbolArtefact: Standard ERC-721 view functions.
 * - balanceOfArtefacts, ownerOfArtefact, getApprovedArtefact, isApprovedForAllArtefacts: Standard ERC-721 ownership/approval views.
 * - transferFromArtefact, safeTransferFromArtefact: Standard ERC-721 transfer functions.
 * - approveArtefact, setApprovalForAllArtefacts: Standard ERC-721 approval functions.
 * - getTokenURIArtefact: Standard ERC-721 metadata view (points to off-chain, but attributes are on-chain).
 * - getFragmentAttributes: View function to get *on-chain* attributes of an Artefact.
 * Core Nexus Interactions:
 * - stakeFlux: Deposit Flux to start generating Resonance Energy.
 * - unstakeFlux: Withdraw staked Flux and claim accrued Resonance Energy.
 * - claimResonanceEnergy: Claim accrued Resonance Energy without unstaking.
 * - attuneFragment: Spend Resonance Energy (and potentially Flux) to modify Artefact attributes.
 * - fuseFragments: Burn multiple Artefacts and spend resources to create a new Artefact.
 * - extractFlux: Burn an Artefact to recover some Flux based on its attributes.
 * View/Calculation:
 * - getUserStakedFlux: View staked amount for a user.
 * - getUserPendingEnergy: Calculate pending Resonance Energy for a user.
 * - calculateAttunementCost: Calculate cost for attuning a specific Artefact.
 * - calculateFusionCost: Calculate cost for fusing specific Artefacts.
 * - calculateExtractionAmount: Calculate Flux recovered from extracting an Artefact.
 * - getGlobalParameters: View current global parameters.
 * - getTotalStakedFlux: View total Flux staked in the contract.
 * - getTotalFragmentsMinted: View total Artefacts ever minted.
 * - getTotalFragmentsOwned: View total active Artefacts (not burned).
 * Admin Controls:
 * - adminCalibrateNexus: Update global parameters (owner only).
 * - adminMintInitialFragments: Mint initial Artefacts for distribution (owner only).
 * - adminWithdrawTreasury: Withdraw collected fees from the treasury (owner only).
 * - adminSetBaseURI: Set the base URI for Artefact metadata (owner only).
 */
contract ChronoSynthesizerNexus {

    // 1. Error Definitions
    error NotOwnerError();
    error InsufficientFlux(uint256 required, uint256 has);
    error InsufficientResonanceEnergy(uint256 required, uint256 has);
    error ArtefactDoesNotExist(uint256 tokenId);
    error NotArtefactOwner(uint256 tokenId, address caller);
    error TransferRequiresApproval(uint256 tokenId);
    error ApprovalForSelf();
    error ApproveToZeroAddress();
    error CannotTransferToZeroAddress();
    error InvalidArtefactCountForFusion(uint256 provided, uint256 requiredMin, uint256 requiredMax);
    error CannotFuseIntoSelf(uint256 sourceTokenId, uint256 targetTokenId);
    error InvalidFusionTarget(uint256 targetTokenId);
    error ArtefactAlreadyApprovedOrForAll(uint256 tokenId, address approved, bool approvedForAll);


    // 2. Events
    event FluxStaked(address indexed user, uint256 amount, uint256 timestamp);
    event FluxUnstaked(address indexed user, uint256 amount, uint256 timestamp);
    event ResonanceEnergyClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event ArtefactAttuned(address indexed user, uint256 tokenId, uint256 energySpent, uint256 fluxSpent, bytes32 indexed attributeChanged, int256 changeAmount);
    event ArtefactsFused(address indexed user, uint256[] sourceTokenIds, uint256 targetTokenId, uint256 energySpent, uint256 fluxSpent);
    event ArtefactExtracted(address indexed user, uint256 tokenId, uint256 fluxReturned);
    event NexusCalibrated(address indexed admin, GlobalParameters newParams);
    event InitialArtefactsMinted(address indexed admin, uint256[] tokenIds);
    event TreasuryWithdrawn(address indexed admin, uint256 amount);
    event ArtefactAttributesChanged(uint256 indexed tokenId, ArtefactAttributes oldAttributes, ArtefactAttributes newAttributes);

    // Standard ERC-20 Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Standard ERC-721 Events
    event TransferArtefact(address indexed from, address indexed to, uint256 indexed tokenId);
    event ApprovalArtefact(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAllArtefacts(address indexed owner, address indexed operator, bool approved);

    // 3. Structs
    struct ArtefactAttributes {
        uint128 harmony;      // Affects energy efficiency, decay resistance
        uint128 instability;  // Affects attunement variability, fusion unpredictability
        uint128 resilience;   // Affects extraction value, decay rate
        uint128 resonance;    // Affects energy generation multiplier when staked with
        uint32 rarityTier;    // General tier influencing base values/outcomes
        uint64 created;       // Timestamp of creation
    }

    struct GlobalParameters {
        uint256 energyGenerationRatePerFluxPerSecond; // How much energy 1 Flux generates per second
        uint256 energyDecayRatePerSecond;           // Flat decay per second on total energy
        uint256 attunementBaseEnergyCost;           // Base energy cost for attuning
        uint256 attunementFluxCostPerAttributePoint; // Flux cost based on total attribute points
        uint256 fusionBaseEnergyCost;               // Base energy cost for fusion
        uint256 fusionBaseFluxCost;                 // Base flux cost for fusion
        uint256 extractionBaseFluxReturn;           // Base flux returned on extraction
        uint256 extractionFluxReturnPerResilience;  // Added flux return per resilience point
        uint256 minFusionSources;                   // Minimum number of artefacts required for fusion
        uint256 maxFusionSources;                   // Maximum number of artefacts required for fusion
        uint256 baseAttributeChangeMagnitude;       // Base change amount during attunement
        uint256 attributeChangeInstabilityFactor;   // Multiplier for instability effect on attunement change
    }


    // 4. State Variables
    address public immutable owner;

    // Internal ERC-20 (Flux) State
    string public constant nameQF = "Quantum Flux";
    string public constant symbolQF = "QF";
    uint8 public constant decimalsQF = 18;
    uint256 private _totalSupplyQF;
    mapping(address => uint256) private _balancesQF;
    mapping(address => mapping(address => uint256)) private _allowancesQF;

    // Staking and Resonance Energy State
    mapping(address => uint256) private _stakedFlux; // User -> Amount staked
    mapping(address => uint256) private _lastEnergyClaimTimestamp; // User -> Last claim or stake timestamp
    mapping(address => uint256) private _accruedEnergy; // User -> Resonance Energy currently held
    uint256 private _totalStakedFlux;

    // Internal ERC-721 (Artefact) State
    string public constant nameArtefact = "Nexus Artefact";
    string public constant symbolArtefact = "NA";
    uint256 private _nextTokenId;
    mapping(uint256 => address) private _artefactOwners;
    mapping(address => uint256) private _artefactBalances;
    mapping(uint256 => address) private _artefactApprovals;
    mapping(address => mapping(address => bool)) private _artefactOperatorApprovals;
    mapping(uint256 => ArtefactAttributes) private _artefactAttributes; // On-chain attributes!
    string private _baseTokenURI;

    // Treasury
    uint256 private _treasuryBalance; // Holds Flux collected from fees

    // Global Parameters
    GlobalParameters public globalParams;

    // 5. Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerError();
        _;
    }

    // 6. Internal ERC-20 (Flux) Implementations
    function _transferQF(address from, address to, uint256 amount) internal {
        uint256 fromBalance = _balancesQF[from];
        if (fromBalance < amount) revert InsufficientFlux(amount, fromBalance);
        _balancesQF[from] = fromBalance - amount;
        _balancesQF[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mintQF(address account, uint256 amount) internal {
        _totalSupplyQF += amount;
        _balancesQF[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burnQF(address account, uint256 amount) internal {
         uint256 accountBalance = _balancesQF[account];
        if (accountBalance < amount) revert InsufficientFlux(amount, accountBalance);
        _balancesQF[account] = accountBalance - amount;
        _totalSupplyQF -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approveQF(address _owner, address spender, uint256 amount) internal {
        _allowancesQF[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    // 7. Internal ERC-721 (Artefact) Implementations
    function _existsArtefact(uint256 tokenId) internal view returns (bool) {
        return _artefactOwners[tokenId] != address(0);
    }

    function _requireArtefactExists(uint256 tokenId) internal view {
        if (!_existsArtefact(tokenId)) revert ArtefactDoesNotExist(tokenId);
    }

    function _isApprovedOrOwnerArtefact(address spender, uint256 tokenId) internal view returns (bool) {
        _requireArtefactExists(tokenId);
        address owner_ = _artefactOwners[tokenId];
        return (spender == owner_ || getApprovedArtefact(tokenId) == spender || isApprovedForAllArtefacts(owner_, spender));
    }

    function _transferFromArtefact(address from, address to, uint256 tokenId) internal {
        if (_artefactOwners[tokenId] != from) revert NotArtefactOwner(tokenId, from);
        if (to == address(0)) revert CannotTransferToZeroAddress();

        // Clear approvals
        _approveArtefact(address(0), tokenId);

        _artefactBalances[from] -= 1;
        _artefactOwners[tokenId] = to;
        _artefactBalances[to] += 1;

        emit TransferArtefact(from, to, tokenId);
    }

    function _safeTransferFromArtefact(address from, address to, uint256 tokenId) internal {
        _transferFromArtefact(from, to, tokenId);
        // In a real ERC721 implementation, you'd check if 'to' is a contract
        // and if it implements ERC721TokenReceiver and calls onERC721Received.
        // Skipping for brevity in this example.
    }


    function _mintFragment(address to, ArtefactAttributes memory attributes) internal returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _artefactOwners[tokenId] = to;
        _artefactBalances[to] += 1;
        _artefactAttributes[tokenId] = attributes; // Set on-chain attributes
        emit TransferArtefact(address(0), to, tokenId);
        emit ArtefactAttributesChanged(tokenId, ArtefactAttributes(0, 0, 0, 0, 0, 0), attributes); // Initial attribute set
    }

    function _burnFragment(uint256 tokenId) internal {
        _requireArtefactExists(tokenId);
        address owner_ = _artefactOwners[tokenId];

        // Clear approvals
        _approveArtefact(address(0), tokenId);

        _artefactBalances[owner_] -= 1;
        delete _artefactOwners[tokenId];
        delete _artefactApprovals[tokenId]; // Ensure approval is cleared
        delete _artefactAttributes[tokenId]; // Remove on-chain attributes
        // Note: Operator approvals for the owner remain.

        emit TransferArtefact(owner_, address(0), tokenId);
        // No specific attribute removal event, implicit by burn.
    }

    function _approveArtefact(address to, uint256 tokenId) internal {
        _requireArtefactExists(tokenId);
        address owner_ = _artefactOwners[tokenId];
        if (to == owner_) revert ApprovalForSelf();
        _artefactApprovals[tokenId] = to;
        emit ApprovalArtefact(owner_, to, tokenId);
    }

    function _setApprovalForAllArtefacts(address owner_, address operator, bool approved) internal {
         _artefactOperatorApprovals[owner_][operator] = approved;
         emit ApprovalForAllArtefacts(owner_, operator, approved);
    }


    // 8. Internal Core Nexus Logic Helpers

    function _generateResonanceEnergy(address user) internal view returns (uint256 pendingEnergy) {
        uint256 staked = _stakedFlux[user];
        uint256 lastClaim = _lastEnergyClaimTimestamp[user];
        uint256 timeElapsed = block.timestamp - lastClaim;

        // Energy generation: staked amount * rate * time
        pendingEnergy = staked * globalParams.energyGenerationRatePerFluxPerSecond * timeElapsed;

        // Apply Artefact resonance bonus (simplified: sum of resonance attributes of owned artefacts)
        // This would require iterating user's owned tokens, which is gas-intensive.
        // For this example, let's assume a fixed bonus or skip, or add a note.
        // Let's skip for simplicity and gas efficiency in this demo.
        // In a real app, resonance could be applied *when* staking, or requires active user action.

        // Apply flat decay (simplified: decay proportional to time, on *generated* energy)
        // A more complex model might decay based on current _accruedEnergy,
        // requiring tracking total ever-generated energy or a different timestamp.
        // Let's skip decay calculation here and assume it's a factor in *usage* costs or happens off-chain / via admin.
        // Or, simplest decay: decay is a flat rate applied when claiming/using.
        // Let's apply simple decay on the *pending* amount based on elapsed time.
        uint256 decayAmount = globalParams.energyDecayRatePerSecond * timeElapsed;
        if (pendingEnergy > decayAmount) {
            pendingEnergy -= decayAmount;
        } else {
            pendingEnergy = 0;
        }

         return pendingEnergy;
    }

     function _updateArtefactAttributes(uint256 tokenId, int256 harmonyChange, int256 instabilityChange, int256 resilienceChange, int256 resonanceChange) internal {
        _requireArtefactExists(tokenId);
        ArtefactAttributes storage current = _artefactAttributes[tokenId];
        ArtefactAttributes memory old = current; // Copy for event

        // Apply changes, preventing wrap-around (simpler bounds or more complex saturation/clamping could be used)
        current.harmony = uint128(int256(current.harmony) + harmonyChange > 0 ? int256(current.harmony) + harmonyChange : 0);
        current.instability = uint128(int256(current.instability) + instabilityChange > 0 ? int256(current.instability) + instabilityChange : 0);
        current.resilience = uint128(int256(current.resilience) + resilienceChange > 0 ? int256(current.resilience) + resilienceChange : 0);
        current.resonance = uint128(int256(current.resonance) + resonanceChange > 0 ? int256(current.resonance) + resonanceChange : 0);

        // Note: Rarity tier and created timestamp are typically static after minting/fusion.
        // Attunement affects the mutable attributes.

        emit ArtefactAttributesChanged(tokenId, old, current);
    }

    // 9. Constructor
    constructor(uint256 initialFluxSupply, GlobalParameters memory initialParams) {
        owner = msg.sender;
        _mintQF(msg.sender, initialFluxSupply); // Mint initial supply to owner or a minter address

        globalParams = initialParams;

        // Set initial token ID counter
        _nextTokenId = 1;

        // Set default Base URI (can be changed by admin)
        _baseTokenURI = "ipfs://baseuri/"; // Example base URI
    }

    // 10. ERC-20 (Flux) Public Interface Functions
    function transferQF(address to, uint256 amount) external returns (bool) {
        _transferQF(msg.sender, to, amount);
        return true;
    }

    function approveQF(address spender, uint256 amount) external returns (bool) {
        _approveQF(msg.sender, spender, amount);
        return true;
    }

    function transferFromQF(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowancesQF[from][msg.sender];
        if (currentAllowance < amount) revert InsufficientFlux(amount, currentAllowance);
        _approveQF(from, msg.sender, currentAllowance - amount); // Decrease allowance
        _transferQF(from, to, amount);
        return true;
    }

    function getQFBalance(address account) external view returns (uint256) {
        return _balancesQF[account];
    }

    function allowanceQF(address _owner, address spender) external view returns (uint256) {
        return _allowancesQF[_owner][spender];
    }

    function getQFTotalSupply() external view returns (uint256) {
        return _totalSupplyQF;
    }

    // 11. ERC-721 (Artefact) Public Interface Functions
    function nameArtefact() external pure returns (string memory) {
        return nameArtefact;
    }

    function symbolArtefact() external pure returns (string memory) {
        return symbolArtefact;
    }

    function balanceOfArtefacts(address owner_) external view returns (uint256) {
        return _artefactBalances[owner_];
    }

    function ownerOfArtefact(uint256 tokenId) external view returns (address) {
        _requireArtefactExists(tokenId);
        return _artefactOwners[tokenId];
    }

    function getApprovedArtefact(uint256 tokenId) external view returns (address) {
        _requireArtefactExists(tokenId); // Ensure token exists before returning approval
        return _artefactApprovals[tokenId];
    }

    function isApprovedForAllArtefacts(address owner_, address operator) external view returns (bool) {
        return _artefactOperatorApprovals[owner_][operator];
    }

    function transferFromArtefact(address from, address to, uint256 tokenId) external {
        if (!_isApprovedOrOwnerArtefact(msg.sender, tokenId)) revert TransferRequiresApproval(tokenId);
        _transferFromArtefact(from, to, tokenId);
    }

    function safeTransferFromArtefact(address from, address to, uint256 tokenId) external {
         if (!_isApprovedOrOwnerArtefact(msg.sender, tokenId)) revert TransferRequiresApproval(tokenId);
         _safeTransferFromArtefact(from, to, tokenId);
    }

    function approveArtefact(address to, uint256 tokenId) external {
        _requireArtefactExists(tokenId);
        address owner_ = _artefactOwners[tokenId];
        if (msg.sender != owner_ && !isApprovedForAllArtefacts(owner_, msg.sender)) revert TransferRequiresApproval(tokenId);
        _approveArtefact(to, tokenId);
    }

    function setApprovalForAllArtefacts(address operator, bool approved) external {
        _setApprovalForAllArtefacts(msg.sender, operator, approved);
    }

    function getTokenURIArtefact(uint256 tokenId) external view returns (string memory) {
        _requireArtefactExists(tokenId);
        // In a real scenario, this would typically return baseURI + tokenId + extension (.json)
        // The JSON metadata would then point to an image and description,
        // and *could* also include the *current* on-chain attributes for display purposes.
        // But the source of truth for mutable attributes is storage!
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json"));
    }

    function getFragmentAttributes(uint256 tokenId) external view returns (ArtefactAttributes memory) {
        _requireArtefactExists(tokenId);
        return _artefactAttributes[tokenId];
    }


    // 12. Core Nexus Interaction Functions

    function stakeFlux(uint256 amount) external {
        if (amount == 0) return; // No-op for 0 stake

        // Claim pending energy before updating stake
        uint256 pending = _generateResonanceEnergy(msg.sender);
        _accruedEnergy[msg.sender] += pending;
        _lastEnergyClaimTimestamp[msg.sender] = block.timestamp;
        emit ResonanceEnergyClaimed(msg.sender, pending, block.timestamp);

        // Transfer Flux from user to contract
        _transferQF(msg.sender, address(this), amount);

        _stakedFlux[msg.sender] += amount;
        _totalStakedFlux += amount;

        emit FluxStaked(msg.sender, amount, block.timestamp);
    }

    function unstakeFlux(uint256 amount) external {
        if (amount == 0) return;
        uint256 staked = _stakedFlux[msg.sender];
        if (staked < amount) revert InsufficientFlux(amount, staked);

        // Claim pending energy before updating stake
        uint256 pending = _generateResonanceEnergy(msg.sender);
        _accruedEnergy[msg.sender] += pending;
        _lastEnergyClaimTimestamp[msg.sender] = block.timestamp;
        emit ResonanceEnergyClaimed(msg.sender, pending, block.timestamp);

        _stakedFlux[msg.sender] -= amount;
        _totalStakedFlux -= amount;

        // Transfer Flux from contract back to user
        // Using pull payment model implicitly as user calls this function
        _transferQF(address(this), msg.sender, amount);

        emit FluxUnstaked(msg.sender, amount, block.timestamp);
    }

    function claimResonanceEnergy() external {
        uint256 pending = _generateResonanceEnergy(msg.sender);
        if (pending == 0 && _accruedEnergy[msg.sender] == 0) return; // Nothing to claim

        _accruedEnergy[msg.sender] += pending;
        _lastEnergyClaimTimestamp[msg.sender] = block.timestamp; // Reset timer even if 0 pending

        // Energy is not transferred, it's added to the user's internal accrued balance
        emit ResonanceEnergyClaimed(msg.sender, pending, block.timestamp);
    }

    function attuneFragment(uint256 tokenId, uint256 energyToSpend) external {
        _requireArtefactExists(tokenId);
        if (_artefactOwners[tokenId] != msg.sender && !_isApprovedOrOwnerArtefact(msg.sender, tokenId)) revert NotArtefactOwner(tokenId, msg.sender);

        uint256 requiredEnergy = calculateAttunementCost(tokenId, energyToSpend); // Calculate actual cost based on desired spend capped by available
        if (_accruedEnergy[msg.sender] < requiredEnergy) revert InsufficientResonanceEnergy(requiredEnergy, _accruedEnergy[msg.sender]);

        // Optional: Require some Flux cost based on attributes/energy spent
        uint256 fluxCost = globalParams.attunementFluxCostPerAttributePoint * (energyToSpend / 1000); // Example calculation
         if (_balancesQF[msg.sender] < fluxCost) revert InsufficientFlux(fluxCost, _balancesQF[msg.sender]);


        _accruedEnergy[msg.sender] -= requiredEnergy;
        if (fluxCost > 0) {
            _transferQF(msg.sender, address(this), fluxCost);
            _treasuryBalance += fluxCost; // Add Flux cost to treasury
        }


        // --- Dynamic Attribute Change Logic ---
        // This is where the "creative" part is. Logic based on:
        // 1. Energy spent (`requiredEnergy`)
        // 2. Artefact's current attributes (_artefactAttributes[tokenId])
        // 3. Global parameters (globalParams)
        // 4. A source of (pseudo)randomness - *CRITICAL SECURITY NOTE*: Block hashes are NOT secure for randomness in adversarial contexts. Use Chainlink VRF or similar for production.
        bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, requiredEnergy));
        uint256 randomValue = uint256(randomSeed);

        int256 harmonyChange = 0;
        int256 instabilityChange = 0;
        int256 resilienceChange = 0;
        int256 resonanceChange = 0;

        // Example Logic: Distribute the base change amount (influenced by energy and parameters)
        // across attributes based on randomness and artefact instability.
        int256 totalBaseChange = int256(globalParams.baseAttributeChangeMagnitude * (requiredEnergy / globalParams.attunementBaseEnergyCost)); // Scale change by energy spent relative to base cost

        // Distribute totalBaseChange (positive or negative) across attributes randomly
        // More instability means larger potential changes (positive or negative)
        uint265 volatility = uint256(_artefactAttributes[tokenId].instability) * globalParams.attributeChangeInstabilityFactor / 1e18; // Scale instability factor
        int256 maxAttributeChange = int256(totalBaseChange + volatility);

        // Example: Use randomValue to decide which attributes change and by how much
        // This is a very simplified probabilistic distribution.
        if (randomValue % 4 == 0) harmonyChange = int256(randomValue % maxAttributeChange) - (maxAttributeChange / 2); // Random +/- up to max
        if (randomValue % 4 == 1) instabilityChange = int256(randomValue % maxAttributeChange) - (maxAttributeChange / 2);
        if (randomValue % 4 == 2) resilienceChange = int256(randomValue % maxAttributeChange) - (maxAttributeChange / 2);
        if (randomValue % 4 == 3) resonanceChange = int256(randomValue % maxAttributeChange) - (maxAttributeChange / 2);


        _updateArtefactAttributes(tokenId, harmonyChange, instabilityChange, resilienceChange, resonanceChange);

        emit ArtefactAttuned(msg.sender, tokenId, requiredEnergy, fluxCost, 0, 0); // Event simplified, specific attribute changes can be detailed
    }

    function fuseFragments(uint256[] calldata sourceTokenIds, uint256 targetTokenId) external {
        uint256 numSources = sourceTokenIds.length;
        if (numSources < globalParams.minFusionSources || numSources > globalParams.maxFusionSources) {
            revert InvalidArtefactCountForFusion(numSources, globalParams.minFusionSources, globalParams.maxFusionSources);
        }

        _requireArtefactExists(targetTokenId);
        if (_artefactOwners[targetTokenId] != msg.sender && !_isApprovedOrOwnerArtefact(msg.sender, targetTokenId)) revert NotArtefactOwner(targetTokenId, msg.sender);

        // Ensure all source tokens exist and are owned/approved by sender
        for (uint256 i = 0; i < numSources; i++) {
            uint256 sourceId = sourceTokenIds[i];
            if (sourceId == targetTokenId) revert CannotFuseIntoSelf(sourceId, targetTokenId); // Cannot use target as source
            _requireArtefactExists(sourceId);
            if (_artefactOwners[sourceId] != msg.sender && !_isApprovedOrOwnerArtefact(msg.sender, sourceId)) revert NotArtefactOwner(sourceId, msg.sender);
        }

        // Calculate costs based on number/attributes of sources and target
        (uint256 requiredEnergy, uint256 requiredFlux) = calculateFusionCost(sourceTokenIds, targetTokenId);

        if (_accruedEnergy[msg.sender] < requiredEnergy) revert InsufficientResonanceEnergy(requiredEnergy, _accruedEnergy[msg.sender]);
        if (_balancesQF[msg.sender] < requiredFlux) revert InsufficientFlux(requiredFlux, _balancesQF[msg.sender]);

        // Pay costs
        _accruedEnergy[msg.sender] -= requiredEnergy;
        if (requiredFlux > 0) {
             _transferQF(msg.sender, address(this), requiredFlux);
            _treasuryBalance += requiredFlux; // Add Flux cost to treasury
        }

        // --- Fusion Logic ---
        // Combine attributes from sources into the target.
        // Example: Weighted average of attributes + bonus based on total rarity/harmony/etc.
        ArtefactAttributes storage targetAttributes = _artefactAttributes[targetTokenId];
        ArtefactAttributes memory oldTargetAttributes = targetAttributes; // Copy for event

        int256 totalHarmony = int256(targetAttributes.harmony);
        int256 totalInstability = int256(targetAttributes.instability);
        int256 totalResilience = int256(targetAttributes.resilience);
        int256 totalResonance = int256(targetAttributes.resonance);
        uint256 totalRarity = targetAttributes.rarityTier;

        for (uint256 i = 0; i < numSources; i++) {
            ArtefactAttributes memory sourceAttrs = _artefactAttributes[sourceTokenIds[i]];
            totalHarmony += int256(sourceAttrs.harmony);
            totalInstability += int256(sourceAttrs.instability);
            totalResilience += int256(sourceAttrs.resilience);
            totalResonance += int256(sourceAttrs.resonance);
            totalRarity += sourceAttrs.rarityTier; // Sum rarity for a simple bonus factor
        }

        // Apply fusion effect - example: average + small bonus/penalty based on randomness
        // *CRITICAL SECURITY NOTE*: Use secure randomness for production.
        bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, targetTokenId, sourceTokenIds, requiredEnergy, requiredFlux));
        uint256 randomFactor = uint256(randomSeed % 100); // 0-99

        int256 avgHarmony = totalHarmony / int256(numSources + 1);
        int256 avgInstability = totalInstability / int256(numSources + 1);
        int256 avgResilience = totalResilience / int256(numSources + 1);
        int256 avgResonance = totalResonance / int256(numSources + 1);

        // Apply a random bonus/penalty based on the random factor
        int256 harmonyBonus = (randomFactor > 50 ? (randomFactor - 50) : -(50 - randomFactor)); // +/- 50 range
        int256 instabilityBonus = (randomFactor % 30) - 15; // Smaller +/- 15 range
        int256 resilienceBonus = (randomFactor % 20) - 10;
        int256 resonanceBonus = (randomFactor % 25) - 12;

        targetAttributes.harmony = uint128(avgHarmony + harmonyBonus > 0 ? avgHarmony + harmonyBonus : 0);
        targetAttributes.instability = uint128(avgInstability + instabilityBonus > 0 ? avgInstability + instabilityBonus : 0);
        targetAttributes.resilience = uint128(avgResilience + resilienceBonus > 0 ? avgResilience + resilienceBonus : 0);
        targetAttributes.resonance = uint128(avgResonance + resonanceBonus > 0 ? avgResonance + resonanceBonus : 0);
        // Rarity tier might increase based on average/sum or a probability roll

        emit ArtefactAttributesChanged(targetTokenId, oldTargetAttributes, targetAttributes);

        // Burn source artefacts
        for (uint256 i = 0; i < numSources; i++) {
            _burnFragment(sourceTokenIds[i]);
        }

        emit ArtefactsFused(msg.sender, sourceTokenIds, targetTokenId, requiredEnergy, requiredFlux);
    }

    function extractFlux(uint256 tokenId) external {
        _requireArtefactExists(tokenId);
        if (_artefactOwners[tokenId] != msg.sender && !_isApprovedOrOwnerArtefact(msg.sender, tokenId)) revert NotArtefactOwner(tokenId, msg.sender);

        uint256 fluxReturnAmount = calculateExtractionAmount(tokenId);

        // Burn the artefact
        _burnFragment(tokenId);

        // Transfer Flux back to user
        _transferQF(address(this), msg.sender, fluxReturnAmount);

        emit ArtefactExtracted(msg.sender, tokenId, fluxReturnAmount);
    }

    // 13. View/Calculation Functions

    function getUserStakedFlux(address user) external view returns (uint256) {
        return _stakedFlux[user];
    }

    function getUserPendingEnergy(address user) external view returns (uint256) {
        // Accrued energy already claimed + currently generated energy
        return _accruedEnergy[user] + _generateResonanceEnergy(user);
    }

    function calculateAttunementCost(uint256 tokenId, uint256 energyToSpend) public view returns (uint256) {
        _requireArtefactExists(tokenId);
        // Simple cost: Base cost + cost based on energy spent
        uint256 baseCost = globalParams.attunementBaseEnergyCost;
        // Cap energy spent by pending energy if called from external context for calculation?
        // No, the caller provides energyToSpend as the *desired* amount to apply effect.
        // The actual cost check happens in `attuneFragment`.
        // This function just calculates the cost structure *if* that energy is spent.
        // Let's simplify and just return the desired spend amount, as the logic in attuneFragment
        // already checks if the user has enough energy.
        // A more complex cost could depend on the Artefact's attributes directly.
        // Example: Cost scales with the sum of current attributes?
         ArtefactAttributes memory attrs = _artefactAttributes[tokenId];
         uint256 attributeSum = attrs.harmony + attrs.instability + attrs.resilience + attrs.resonance;
         uint256 calculatedCost = globalParams.attunementBaseEnergyCost + (attributeSum * 100); // Example scaling by attribute sum

        // Return the *minimum* of desired spend and calculated cost, or perhaps just the calculated cost?
        // Let's return the calculated cost structure, allowing the user to see what it *would* cost
        // to achieve a certain magnitude of change (which is tied to energy spent).
        // Re-evaluating: The function `attuneFragment` takes `energyToSpend` and uses that amount.
        // This calculation view should reflect the cost *per unit* or the total cost for a *potential* outcome.
        // Let's make this view return the base cost + a factor based on attribute sum.
        // The amount actually spent is what the user provides, up to their balance.
        // Let's simplify the view: Just return the minimum energy required for *any* attunement step.
        // The actual cost depends on the `energyToSpend` parameter in the mutable function.
        // Okay, let's refine: `attuneFragment` takes `energyToSpend`. This view calculates the minimum energy cost *to perform any attunement*.
        // A better view would be `calculateExpectedAttributeChange(tokenId, energyToSpend)` but that requires replicating the random logic.
        // Let's just return the *base* attunement energy cost. The total cost is `baseCost + energyToSpend`.
         return globalParams.attunementBaseEnergyCost + energyToSpend; // Total energy cost is base + user-provided energy for effect magnitude
    }


    function calculateFusionCost(uint256[] calldata sourceTokenIds, uint256 targetTokenId) public view returns (uint256 requiredEnergy, uint256 requiredFlux) {
         _requireArtefactExists(targetTokenId); // Ensure target exists for calculation

         // Cost based on number of sources + target's rarity/complexity
        uint256 numSources = sourceTokenIds.length;
        if (numSources < globalParams.minFusionSources || numSources > globalParams.maxFusionSources) {
            // Cannot calculate cost for invalid number of sources, perhaps return max_int or revert? Revert is safer.
             revert InvalidArtefactCountForFusion(numSources, globalParams.minFusionSources, globalParams.maxFusionSources);
        }

        ArtefactAttributes memory targetAttrs = _artefactAttributes[targetTokenId];
        uint256 totalSourceRarity = 0;
        for (uint256 i = 0; i < numSources; i++) {
             // In a real scenario, you'd validate sourceTokenIds exist and belong to the caller.
             // Skipping existence check here for a pure view function.
             // Add a note: This pure function *assumes* valid input IDs.
             ArtefactAttributes memory sourceAttrs = _artefactAttributes[sourceTokenIds[i]];
             totalSourceRarity += sourceAttrs.rarityTier;
        }

        // Example cost calculation:
        requiredEnergy = globalParams.fusionBaseEnergyCost + (numSources * 500) + (targetAttrs.rarityTier * 100);
        requiredFlux = globalParams.fusionBaseFluxCost + (totalSourceRarity * 50) + (numSources * 20);

        return (requiredEnergy, requiredFlux);
    }

    function calculateExtractionAmount(uint256 tokenId) public view returns (uint256) {
        _requireArtefactExists(tokenId);
        ArtefactAttributes memory attrs = _artefactAttributes[tokenId];
        // Example calculation: Base return + bonus per resilience point + bonus per rarity tier
        return globalParams.extractionBaseFluxReturn + (attrs.resilience * globalParams.extractionFluxReturnPerResilience) + (attrs.rarityTier * 20);
    }

    function getGlobalParameters() external view returns (GlobalParameters memory) {
        return globalParams;
    }

    function getTotalStakedFlux() external view returns (uint256) {
        return _totalStakedFlux;
    }

    function getTotalFragmentsMinted() external view returns (uint256) {
        return _nextTokenId - 1; // nextTokenId is the ID for the *next* token
    }

    function getTotalFragmentsOwned() external view returns (uint256) {
        return getTotalFragmentsMinted() - _artefactBalances[address(0)]; // Total minted minus balance of zero address (burned tokens)
    }

    // 14. Admin/Control Functions
    function adminCalibrateNexus(GlobalParameters memory newParams) external onlyOwner {
        globalParams = newParams;
        emit NexusCalibrated(msg.sender, newParams);
    }

    function adminMintInitialFragments(address[] calldata recipients, ArtefactAttributes[] calldata initialAttributes) external onlyOwner {
        if (recipients.length != initialAttributes.length) revert("Admin: Mismatched arrays");
        uint256[] memory mintedTokenIds = new uint256[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            ArtefactAttributes memory attrs = initialAttributes[i];
            // Ensure created timestamp is current
            attrs.created = uint64(block.timestamp);
            mintedTokenIds[i] = _mintFragment(recipients[i], attrs);
        }
        emit InitialArtefactsMinted(msg.sender, mintedTokenIds);
    }

    function adminWithdrawTreasury(address payable recipient, uint256 amount) external onlyOwner {
        if (_treasuryBalance < amount) revert InsufficientFlux(amount, _treasuryBalance);
        _treasuryBalance -= amount;
        _transferQF(address(this), recipient, amount); // Transfer Flux from contract balance
        emit TreasuryWithdrawn(msg.sender, amount);
    }

    function adminSetBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Helper library (Strings) for toString, included here for self-containment
    library Strings {
        bytes16 private constant _HEX_TABLE = "0123456789abcdef";

        function toString(uint256 value) internal pure returns (string memory) {
            // Inspired by Oraclize's uint2str the original library was licensed under GPL.
            // This simplified version is distributed under MIT license.
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 length = 0;
            while (temp != 0) {
                length++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(length);
            while (value != 0) {
                length -= 1;
                buffer[length] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```

**Explanation of Advanced/Creative Concepts & Functions:**

1.  **Dynamic On-Chain Attributes (`ArtefactAttributes` struct, `_artefactAttributes` mapping, `getFragmentAttributes`, `attuneFragment`, `fuseFragments`, `extractFlux`, `ArtefactAttributesChanged` event):** Instead of storing just a metadata URI, the core attributes of the Artefacts are directly stored in the contract's storage. Functions like `attuneFragment` and `fuseFragments` mutate these attributes based on specific game/system logic, making the NFTs truly dynamic and stateful on the blockchain itself. `ArtefactAttributesChanged` event makes these state changes easily trackable off-chain.
2.  **Resource Generation via Staking (`stakeFlux`, `unstakeFlux`, `claimResonanceEnergy`, `_stakedFlux`, `_accruedEnergy`, `_lastEnergyClaimTimestamp`, `_generateResonanceEnergy`, `FluxStaked`, `FluxUnstaked`, `ResonanceEnergyClaimed`, `getUserStakedFlux`, `getUserPendingEnergy`):** Users lock up `QF` tokens to passively generate `Resonance Energy` over time. This energy is a separate, non-transferable resource (`_accruedEnergy`) required for core interactions like attuning and fusing. The generation logic (`_generateResonanceEnergy`) considers time elapsed and staked amount. This creates a resource sink/faucet mechanism.
3.  **On-Chain Fusion/Crafting (`fuseFragments`, `calculateFusionCost`, `ArtefactsFused` event):** This function allows users to combine multiple Artefacts (`sourceTokenIds`) and potentially a target Artefact (`targetTokenId`) to create a new or upgraded Artefact. The source Artefacts are *burned* (`_burnFragment`). The outcome and cost (`requiredEnergy`, `requiredFlux`) are calculated based on the attributes of the input Artefacts and global parameters. This is a complex state transition involving multiple assets and resources.
4.  **Attribute Attunement (`attuneFragment`, `calculateAttunementCost`, `ArtefactAttuned` event):** Users can spend `Resonance Energy` (and potentially `QF`) to directly modify the attributes of a single Artefact. The magnitude and direction of the attribute changes are influenced by the amount of energy spent, the Artefact's current attributes (like `instability`), global parameters, and a source of (pseudo)randomness. This allows users to influence the development of their NFTs.
5.  **Attribute-Based Extraction (`extractFlux`, `calculateExtractionAmount`, `ArtefactExtracted` event):** Artefacts aren't just burned in fusion; they can also be "extracted" to recover a certain amount of `QF`. The amount recovered is calculated based on the Artefact's specific attributes (like `resilience`), providing another strategic consideration for users regarding their assets.
6.  **Parametric Control (`GlobalParameters` struct, `globalParams` state, `adminCalibrateNexus`, `NexusCalibrated` event, various calculation functions):** Key economic and mechanical parameters of the system (energy rates, costs, attribute change factors, min/max fusion sources) are held in a `GlobalParameters` struct. An admin function (`adminCalibrateNexus`) allows the owner to adjust these parameters, enabling the system to be balanced or evolved over time without a full contract upgrade (though a real system might use a DAO or timelock for this).
7.  **Treasury System (`_treasuryBalance`, `adminWithdrawTreasury`):** Fees collected from interactions (like attunement and fusion `fluxCost`) are sent to the contract itself, building a treasury balance that can be managed by the owner (or a DAO).
8.  **Internal Token Management:** The contract includes simplified internal implementations of ERC-20 (`_balancesQF`, `_totalSupplyQF`, etc.) and ERC-721 (`_artefactOwners`, `_artefactAttributes`, etc.) logic. This is done to make the example self-contained and easily demonstrate interaction between the core Nexus logic and the tokens it manages. In a production system, you would typically deploy standard, audited ERC-20 and ERC-721 contracts separately and interact with them via interfaces, but for demonstrating the complex *Nexus* logic and meeting the function count requirement, internal handling is shown here.

**Security Considerations (Important Notes):**

*   **Randomness:** The example uses `block.timestamp` and `block.difficulty` (or hashes derived from them) for pseudo-randomness in attribute changes and fusion outcomes. **This is highly insecure for production** in adversarial environments like public blockchains, as miners/validators can influence these values to game the system. A secure random number generator like Chainlink VRF should be used in production.
*   **Complexity:** This contract is complex. It manages multiple state variables and involves non-trivial logic in attunement and fusion. This increases the surface area for potential bugs. Thorough testing and professional auditing would be essential for deployment.
*   **Gas Costs:** Iterating through arrays (like `sourceTokenIds` in `fuseFragments` or potentially when calculating Artefact Resonance bonus) can be gas-intensive. The current example simplifies this, but for large numbers of inputs or Artefacts, optimization (e.g., mapping ownership to arrays, limiting array sizes, or requiring users to provide necessary data upfront) would be needed.
*   **Integer Overflows/Underflows:** While Solidity 0.8+ provides checked arithmetic by default, careful consideration is needed for type conversions and calculations, especially with potentially large attribute values or quantities. `uint128` for attributes provides a large range but could still potentially overflow if logic isn't careful.
*   **Access Control:** Basic `onlyOwner` is used. A more robust system might use roles, multi-sig, or DAO governance for admin functions.
*   **Reentrancy:** While less likely with simple `_transferQF` calls, any external calls (which aren't present here as tokens are internal) or complex interaction patterns would require reentrancy guards.

This contract provides a blueprint for a dynamic on-chain system with interlocking mechanics beyond simple token transfers or static NFTs, fulfilling the requirements for complexity, creativity, and function count.