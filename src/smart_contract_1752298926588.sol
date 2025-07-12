Okay, let's design a smart contract centered around a unique concept: **Dynamic, Time-Sensitive, and Interactive Digital Artifacts**.

We'll create a system where users can mint digital "Gems" (representing dynamic NFTs) that evolve, decay, and interact with each other based on time, user actions, and internal game mechanics. This avoids standard ERC-20/ERC-721 and incorporates concepts like time-based state changes, on-chain derived metadata, and NFT-to-NFT interaction.

**Concept:** **The Chrono-Gem Forge**

Users mint Chrono-Gems. These gems have properties (Purity, Resonance, Age) that change over time and through interaction. They can be "charged" (fed a resource token), "tuned" (another resource), or even "clashed" against each other. Unattended gems decay. Their on-chain traits evolve, potentially unlocking new abilities or affecting interactions.

---

### **Outline and Function Summary**

**Contract Name:** `ChronoGemForge`

**Core Concept:** Manages dynamic NFTs ("Chrono-Gems") whose state (Purity, Resonance) changes over time and through user interactions, influencing on-chain derived traits and enabling NFT-to-NFT interactions. Requires an external ERC-20 token ("Charge" token) for many actions.

**Key Features:**
1.  **Dynamic NFT State:** Gems have mutable on-chain properties (Purity, Resonance, LastInteractionTime, Age).
2.  **Time Sensitivity:** Properties like Resonance decay over time; Age increases.
3.  **Resource Interaction:** Users spend a defined ERC-20 "Charge Token" to perform actions ("Charge", "Tune").
4.  **NFT-to-NFT Interaction:** A "Clash" function allows two gem owners to interact their gems, with outcomes potentially based on gem state.
5.  **On-Chain Derived Traits:** Gem traits are not static metadata but computed based on their current Purity, Resonance, and Age.
6.  **Simulation Function:** Allows users to predict gem state changes without transacting.
7.  **Staking (Simple):** A basic lock-up mechanism for gems.
8.  **Parameter Configurability:** Admin can adjust game mechanics.

**Function Summary (25+ functions):**

**I. ERC-721 Basic Implementation (Avoiding standard library import to meet criteria):**
1.  `balanceOf(address owner)`: Get the number of gems owned by an address.
2.  `ownerOf(uint256 tokenId)`: Get the owner of a specific gem.
3.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer gem ownership.
4.  `approve(address to, uint256 tokenId)`: Approve an address to spend a specific gem.
5.  `getApproved(uint256 tokenId)`: Get the approved address for a specific gem.
6.  `setApprovalForAll(address operator, bool approved)`: Set approval for an operator across all owned gems.
7.  `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for an owner.

**II. Gem Lifecycle & Interaction:**
8.  `mintGem()`: Mint a new Chrono-Gem (requires burning Charge Token).
9.  `chargeGem(uint256 tokenId)`: Increase a gem's Resonance (requires Charge Token).
10. `tuneGem(uint256 tokenId)`: Increase a gem's Purity (requires Charge Token).
11. `clashGems(uint256 callerGemId, uint256 targetGemId)`: Initiate an interaction between two gems.
12. `stakeGem(uint256 tokenId)`: Lock a gem into the contract (simple staking).
13. `unstakeGem(uint256 tokenId)`: Unlock a staked gem.

**III. Dynamic State & Queries:**
14. `getGemData(uint256 tokenId)`: Get the raw state data of a gem.
15. `getGemPurity(uint256 tokenId)`: Get the current calculated Purity (considering decay).
16. `getGemResonance(uint256 tokenId)`: Get the current calculated Resonance (considering decay).
17. `getGemAge(uint256 tokenId)`: Get the current calculated Age.
18. `getGemDerivedTraits(uint256 tokenId)`: Calculate and return the gem's current on-chain traits (e.g., as a bytes32 hash or packed uints).
19. `getGemDecayAmount(uint256 tokenId)`: Calculate how much Resonance has decayed since last interaction.
20. `simulateGemEvolution(uint256 tokenId, uint256 timeDelta, uint256 chargeAmount, uint256 tuneAmount)`: Pure function to simulate gem state after actions/time.

**IV. Admin & Parameter Control:**
21. `setChargeToken(address _chargeToken)`: Set the address of the ERC-20 charge token.
22. `setMintCost(uint256 _mintCost)`: Set the cost in charge tokens to mint.
23. `setChargeCost(uint256 _chargeCost)`: Set the cost to charge a gem.
24. `setTuneCost(uint256 _tuneCost)`: Set the cost to tune a gem.
25. `setResonanceDecayRate(uint256 _rate)`: Set the per-second decay rate for Resonance.
26. `setChargeBoostAmount(uint256 _amount)`: Set how much Resonance increases per charge.
27. `setTuneBoostAmount(uint256 _amount)`: Set how much Purity increases per tune.
28. `setClashCost(uint256 _cost)`: Set the cost to initiate a gem clash.
29. `setClashFeeRecipient(address _recipient)`: Set the recipient of clash fees.
30. `withdrawAdminFees(address tokenAddress, uint256 amount)`: Admin can withdraw accumulated fees.
31. `setBaseTraitsHash(bytes32 _hash)`: Admin sets a base value used in trait derivation.
32. `setTraitTierThresholds(uint256[] calldata purityThresholds, uint256[] calldata resonanceThresholds)`: Admin sets thresholds for trait tiers. *Advanced: Configurable on-chain logic parameters.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// --- OUTLINE ---
// Contract: ChronoGemForge
// Core Concept: Manages dynamic NFTs (Chrono-Gems) that evolve based on time, resources, and interaction.
// Features: Dynamic state, time-based decay, resource consumption (ERC20), NFT-to-NFT interaction,
//           on-chain derived traits, simulation, staking, configurable parameters.
// ERC-721 Implementation: Custom, not using OpenZeppelin standard library directly for uniqueness.

// --- FUNCTION SUMMARY ---
// I. ERC-721 Basics: balanceOf, ownerOf, transferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll
// II. Gem Lifecycle & Interaction: mintGem, chargeGem, tuneGem, clashGems, stakeGem, unstakeGem
// III. Dynamic State & Queries: getGemData, getGemPurity, getGemResonance, getGemAge, getGemDerivedTraits, getGemDecayAmount, simulateGemEvolution
// IV. Admin & Parameters: setChargeToken, setMintCost, setChargeCost, setTuneCost, setResonanceDecayRate, setChargeBoostAmount,
//    setTuneBoostAmount, setClashCost, setClashFeeRecipient, withdrawAdminFees, setBaseTraitsHash, setTraitTierThresholds

contract ChronoGemForge is Ownable {
    // --- State Variables ---

    // ERC-721 State
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _currentTokenId;

    // Gem Specific Data
    struct GemData {
        uint256 purity; // Represents quality, decays slowly
        uint256 resonance; // Represents energy level, decays faster
        uint256 creationTime;
        uint256 lastInteractionTime;
        bool isStaked;
        uint256 clashWins;
        uint256 clashLosses;
    }
    mapping(uint256 => GemData) private _gems;

    // Configuration Parameters
    address public chargeToken; // ERC-20 token address used for interactions
    uint256 public mintCost = 1 ether; // Cost in charge token to mint
    uint256 public chargeCost = 0.1 ether; // Cost in charge token to charge
    uint256 public tuneCost = 0.2 ether; // Cost in charge token to tune
    uint256 public clashCost = 0.3 ether; // Cost in charge token to clash
    address public clashFeeRecipient; // Recipient of clash fees

    // Decay Rates (Per second. Higher means faster decay)
    uint256 public constant PURITY_DECAY_RATE_PER_SEC = 1e15; // Example: 0.001 ether equivalent
    uint256 public resonanceDecayRatePerSec = 1e16; // Example: 0.01 ether equivalent

    // Boost Amounts
    uint256 public chargeBoostAmount = 5e17; // Example: 0.5 ether equivalent
    uint256 public tuneBoostAmount = 1e18; // Example: 1 ether equivalent

    // Trait Derivation Parameters
    bytes32 public baseTraitsHash; // Base value for trait calculation
    uint256[] public purityThresholds; // Thresholds for purity-based trait tiers
    uint256[] public resonanceThresholds; // Thresholds for resonance-based trait tiers

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event GemMinted(uint256 indexed tokenId, address indexed owner, uint256 creationTime);
    event GemCharged(uint256 indexed tokenId, uint256 newResonance);
    event GemTuned(uint256 indexed tokenId, uint256 newPurity);
    event GemClashed(uint256 indexed callerId, uint256 indexed targetId, bool callerWon);
    event GemStaked(uint256 indexed tokenId);
    event GemUnstaked(uint256 indexed tokenId);
    event ParametersUpdated(string paramName, uint256 newValue);
    event AddressParameterUpdated(string paramName, address newAddress);

    // --- Errors ---
    error InvalidTokenId();
    error NotOwnerOrApproved();
    error NotApprovedForAll();
    error TransferToZeroAddress();
    error NotMinter(); // Not used in this simple example but good practice
    error ERC721EnumerableNotSupported(); // Not implementing enumeration
    error GemDoesNotExist(uint256 tokenId);
    error GemIsStaked(uint256 tokenId);
    error GemNotStaked(uint256 tokenId);
    error InsufficientChargeTokens();
    error SameGemIds();
    error RequiresChargeTokenSet();

    // --- Constructor ---
    constructor(address _initialChargeToken, address _initialClashFeeRecipient) Ownable(msg.sender) {
        chargeToken = _initialChargeToken;
        clashFeeRecipient = _initialClashFeeRecipient;
        // Initialize thresholds with some dummy values if needed, or leave empty
        purityThresholds = [5000, 8000]; // Example thresholds (scaled by 1e18 internally)
        resonanceThresholds = [6000, 9000]; // Example thresholds (scaled by 1e18 internally)
    }

    // --- Modifiers ---
    modifier onlyGemOwnerOrApproved(uint256 tokenId) {
        if (_owners[tokenId] != msg.sender && _getApproved(tokenId) != msg.sender && !_operatorApprovals[_owners[tokenId]][msg.sender]) {
            revert NotOwnerOrApproved();
        }
        _;
    }

    modifier whenGemExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert GemDoesNotExist(tokenId);
        }
        _;
    }

    modifier onlyWhenChargeTokenSet() {
        if (chargeToken == address(0)) {
            revert RequiresChargeTokenSet();
        }
        _;
    }

    // --- I. ERC-721 Basic Implementation ---

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert TransferToZeroAddress(); // ERC721: balance query for the zero address
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidTokenId(); // ERC721: owner query for nonexistent token
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual whenGemExists(tokenId) {
        // Check authorization
        if (from != msg.sender && _getApproved(tokenId) != msg.sender && !_isApprovedForAll(from, msg.sender)) {
             revert NotOwnerOrApproved();
        }
        if (to == address(0)) revert TransferToZeroAddress();

        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual whenGemExists(tokenId) {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !_isApprovedForAll(owner, msg.sender)) {
            revert NotOwnerOrApproved();
        }
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view whenGemExists(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Internal ERC721 helpers
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

     function _safeMint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert TransferToZeroAddress();
        if (_exists(tokenId)) revert InvalidTokenId(); // ERC721: token already minted

        _owners[tokenId] = to;
        _balances[to]++;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
         if (_owners[tokenId] != from) revert NotOwnerOrApproved(); // Should not happen if called correctly internally
         if (to == address(0)) revert TransferToZeroAddress();

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from]--;
        _owners[tokenId] = to;
        _balances[to]++;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    // --- II. Gem Lifecycle & Interaction ---

    /// @notice Mints a new Chrono-Gem, requiring payment in the charge token.
    function mintGem() public onlyWhenChargeTokenSet {
        uint256 newItemId = _currentTokenId + 1;

        // Require charge token payment
        if (chargeToken != address(0)) {
            // Ensure the contract has allowance to pull tokens from the caller
            // Caller must approve the contract *before* calling mintGem
             bool success = IERC20(chargeToken).transferFrom(msg.sender, address(this), mintCost);
             if (!success) revert InsufficientChargeTokens();
        }

        _safeMint(msg.sender, newItemId);

        _gems[newItemId] = GemData({
            purity: 5000, // Initial purity
            resonance: 5000, // Initial resonance
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            isStaked: false,
            clashWins: 0,
            clashLosses: 0
        });

        _currentTokenId = newItemId;

        emit GemMinted(newItemId, msg.sender, block.timestamp);
    }

    /// @notice Increases a gem's resonance by spending charge tokens.
    function chargeGem(uint256 tokenId) public payable onlyGemOwnerOrApproved(tokenId) whenGemExists(tokenId) onlyWhenChargeTokenSet {
        if (_gems[tokenId].isStaked) revert GemIsStaked(tokenId);

        // Require charge token payment
        if (chargeToken != address(0)) {
             bool success = IERC20(chargeToken).transferFrom(msg.sender, address(this), chargeCost);
             if (!success) revert InsufficientChargeTokens();
        }

        GemData storage gem = _gems[tokenId];
        _updateGemState(tokenId); // Apply decay first
        gem.resonance = Math.min(gem.resonance + chargeBoostAmount, 10000); // Cap resonance at 10000
        gem.lastInteractionTime = block.timestamp;

        emit GemCharged(tokenId, gem.resonance);
    }

     /// @notice Increases a gem's purity by spending charge tokens.
    function tuneGem(uint256 tokenId) public payable onlyGemOwnerOrApproved(tokenId) whenGemExists(tokenId) onlyWhenChargeTokenSet {
        if (_gems[tokenId].isStaked) revert GemIsStaked(tokenId);

        // Require charge token payment
        if (chargeToken != address(0)) {
             bool success = IERC20(chargeToken).transferFrom(msg.sender, address(this), tuneCost);
             if (!success) revert InsufficientChargeTokens();
        }

        GemData storage gem = _gems[tokenId];
        _updateGemState(tokenId); // Apply decay first
        gem.purity = Math.min(gem.purity + tuneBoostAmount, 10000); // Cap purity at 10000
        gem.lastInteractionTime = block.timestamp;

        emit GemTuned(tokenId, gem.purity);
    }

    /// @notice Initiates a clash between two gems. Outcome is simplified for this example.
    /// @dev The outcome logic is deterministic and simple. For real-world use, consider Chainlink VRF or similar.
    function clashGems(uint256 callerGemId, uint256 targetGemId) public onlyGemOwnerOrApproved(callerGemId) whenGemExists(callerGemId) whenGemExists(targetGemId) onlyWhenChargeTokenSet {
        if (callerGemId == targetGemId) revert SameGemIds();
        if (_gems[callerGemId].isStaked) revert GemIsStaked(callerGemId);
         if (_gems[targetGemId].isStaked) revert GemIsStaked(targetGemId);

        // Charge cost to the caller
         if (chargeToken != address(0)) {
             bool success = IERC20(chargeToken).transferFrom(msg.sender, address(this), clashCost);
             if (!success) revert InsufficientChargeTokens();
         }

        GemData storage callerGem = _gems[callerGemId];
        GemData storage targetGem = _gems[targetGemId];

        _updateGemState(callerGemId); // Apply decay before clash
        _updateGemState(targetGemId); // Apply decay before clash

        // Simplified Clash Logic: Compare a combined stat (e.g., Purity + Resonance)
        // In a real scenario, this would be more complex, potentially involve random elements
        // and have different effects on gem state.
        uint256 callerPower = callerGem.purity + callerGem.resonance + callerGem.clashWins * 10; // Add slight win bonus
        uint256 targetPower = targetGem.purity + targetGem.resonance + targetGem.clashWins * 10;

        bool callerWon = false;
        if (callerPower > targetPower) {
            callerWon = true;
        } else if (callerPower == targetPower) {
            // Tie-breaker: Older gem wins? Lower token ID wins? Simple tie-breaker
            if (callerGem.creationTime < targetGem.creationTime) {
                 callerWon = true;
            }
        }
        // If callerPower < targetPower or tie-breaker favors target, callerWon remains false

        if (callerWon) {
            callerGem.clashWins++;
            targetGem.clashLosses++;
            // Example effect: boost winner's resonance slightly, decay loser's resonance slightly
            callerGem.resonance = Math.min(callerGem.resonance + 100, 10000);
            targetGem.resonance = targetGem.resonance > 100 ? targetGem.resonance - 100 : 0;

        } else {
            callerGem.clashLosses++;
            targetGem.clashWins++;
             // Example effect: boost winner's resonance slightly, decay loser's resonance slightly
            targetGem.resonance = Math.min(targetGem.resonance + 100, 10000);
            callerGem.resonance = callerGem.resonance > 100 ? callerGem.resonance - 100 : 0;
        }

        // Update last interaction time for both gems
        callerGem.lastInteractionTime = block.timestamp;
        targetGem.lastInteractionTime = block.timestamp;

        emit GemClashed(callerGemId, targetGemId, callerWon);

        // Send clash fee if recipient is set
        if (clashFeeRecipient != address(0) && chargeToken != address(0)) {
             // transferFrom was already used to pull cost, now transfer to recipient
             // Assumes the contract holds enough tokens from previous transactions or admin deposits
             // In a real scenario, you'd transfer the fee portion directly here if clashCost was split
             // or handle fee collection differently. For simplicity, fees accrue to contract balance.
        }
    }

    /// @notice Stakes a gem, making it unusable for other interactions.
    function stakeGem(uint256 tokenId) public onlyGemOwnerOrApproved(tokenId) whenGemExists(tokenId) {
        if (_gems[tokenId].isStaked) revert GemIsStaked(tokenId);
        // Clear any approvals before staking for security/simplicity
        _approve(address(0), tokenId);

        GemData storage gem = _gems[tokenId];
        gem.isStaked = true;
        // Note: No direct reward earning implemented in this example, just a state change.
        // A real staking system would track stake time and rewards.
        emit GemStaked(tokenId);
    }

    /// @notice Unstakes a gem, making it available again.
    function unstakeGem(uint256 tokenId) public onlyGemOwnerOrApproved(tokenId) whenGemExists(tokenId) {
         if (!_gems[tokenId].isStaked) revert GemNotStaked(tokenId);

        GemData storage gem = _gems[tokenId];
        gem.isStaked = false;
        // Note: Reward claim logic would go here in a real system.
        emit GemUnstaked(tokenId);
    }

    // --- III. Dynamic State & Queries ---

    /// @notice Gets the raw stored state data of a gem.
    function getGemData(uint256 tokenId) public view whenGemExists(tokenId) returns (GemData memory) {
        return _gems[tokenId];
    }

     /// @notice Gets the current calculated Purity, accounting for decay.
    function getGemPurity(uint256 tokenId) public view whenGemExists(tokenId) returns (uint256) {
        GemData memory gem = _gems[tokenId];
        uint256 timeElapsed = block.timestamp - gem.lastInteractionTime;
        uint256 decay = Math.min(timeElapsed * PURITY_DECAY_RATE_PER_SEC, gem.purity); // Decay max up to current purity
        return gem.purity - decay;
    }

     /// @notice Gets the current calculated Resonance, accounting for decay.
    function getGemResonance(uint256 tokenId) public view whenGemExists(tokenId) returns (uint256) {
        GemData memory gem = _gems[tokenId];
        uint256 timeElapsed = block.timestamp - gem.lastInteractionTime;
        uint256 decay = Math.min(timeElapsed * resonanceDecayRatePerSec, gem.resonance); // Decay max up to current resonance
        return gem.resonance - decay;
    }

    /// @notice Gets the current calculated Age in seconds.
    function getGemAge(uint256 tokenId) public view whenGemExists(tokenId) returns (uint256) {
        GemData memory gem = _gems[tokenId];
        return block.timestamp - gem.creationTime;
    }

    /// @notice Calculates and returns the gem's current on-chain derived traits.
    /// @dev Traits are derived dynamically based on current state. Simplified example uses a hash.
    /// In a real system, this would map to specific traits (e.g., color, glow intensity, shape).
    function getGemDerivedTraits(uint256 tokenId) public view whenGemExists(tokenId) returns (bytes32) {
        uint256 currentPurity = getGemPurity(tokenId);
        uint256 currentResonance = getGemResonance(tokenId);
        uint256 currentAge = getGemAge(tokenId);
        GemData memory gem = _gems[tokenId]; // Get static parts

        // Simple deterministic trait derivation
        // Combine key stats and admin-set base hash into a new hash
        bytes32 derivedHash = keccak256(
            abi.encodePacked(
                baseTraitsHash,
                currentPurity,
                currentResonance,
                currentAge,
                gem.clashWins,
                gem.clashLosses,
                gem.creationTime,
                tokenId // Include token ID for uniqueness
            )
        );

        // Example: Apply a tier modifier based on stats (conceptual)
        uint256 purityTier = _getTier(currentPurity, purityThresholds);
        uint256 resonanceTier = _getTier(currentResonance, resonanceThresholds);

        // Combine derived hash with tier info
         derivedHash = keccak256(abi.encodePacked(derivedHash, purityTier, resonanceTier));

        return derivedHash;
    }

    /// @notice Calculates the amount of Resonance decay since the last interaction.
    function getGemDecayAmount(uint256 tokenId) public view whenGemExists(tokenId) returns (uint256) {
        GemData memory gem = _gems[tokenId];
        uint256 timeElapsed = block.timestamp - gem.lastInteractionTime;
        return Math.min(timeElapsed * resonanceDecayRatePerSec, gem.resonance);
    }

    /// @notice Pure function to simulate gem state after applying actions and time.
    /// Doesn't change contract state. Useful for UI previews.
    /// @param tokenId The ID of the gem to simulate.
    /// @param timeDelta The time in seconds to simulate forward.
    /// @param chargeAmount The number of 'charge' actions to simulate.
    /// @param tuneAmount The number of 'tune' actions to simulate.
    function simulateGemEvolution(
        uint256 tokenId,
        uint256 timeDelta,
        uint256 chargeAmount,
        uint256 tuneAmount
    ) public view whenGemExists(tokenId) returns (uint256 simulatedPurity, uint256 simulatedResonance) {
        GemData memory gem = _gems[tokenId];

        // Calculate decay over timeDelta
        uint256 totalSimulatedTime = (block.timestamp - gem.lastInteractionTime) + timeDelta;
        uint256 purityDecay = Math.min(totalSimulatedTime * PURITY_DECAY_RATE_PER_SEC, gem.purity);
        uint256 resonanceDecay = Math.min(totalSimulatedTime * resonanceDecayRatePerSec, gem.resonance);

        simulatedPurity = gem.purity > purityDecay ? gem.purity - purityDecay : 0;
        simulatedResonance = gem.resonance > resonanceDecay ? gem.resonance - resonanceDecay : 0;

        // Apply simulated boosts
        simulatedResonance = Math.min(simulatedResonance + chargeAmount * chargeBoostAmount, 10000);
        simulatedPurity = Math.min(simulatedPurity + tuneAmount * tuneBoostAmount, 10000);
    }


    // --- IV. Admin & Parameter Control ---

    /// @notice Sets the address of the ERC-20 token used for charges and fees.
    function setChargeToken(address _chargeToken) public onlyOwner {
        chargeToken = _chargeToken;
        emit AddressParameterUpdated("chargeToken", _chargeToken);
    }

     /// @notice Sets the cost in charge tokens to mint a gem.
    function setMintCost(uint256 _mintCost) public onlyOwner {
        mintCost = _mintCost;
        emit ParametersUpdated("mintCost", _mintCost);
    }

    /// @notice Sets the cost in charge tokens to charge a gem.
    function setChargeCost(uint256 _chargeCost) public onlyOwner {
        chargeCost = _chargeCost;
        emit ParametersUpdated("chargeCost", _chargeCost);
    }

    /// @notice Sets the cost in charge tokens to tune a gem.
    function setTuneCost(uint256 _tuneCost) public onlyOwner {
        tuneCost = _tuneCost;
        emit ParametersUpdated("tuneCost", _tuneCost);
    }

    /// @notice Sets the per-second decay rate for Resonance.
    function setResonanceDecayRate(uint256 _rate) public onlyOwner {
        resonanceDecayRatePerSec = _rate;
        emit ParametersUpdated("resonanceDecayRatePerSec", _rate);
    }

    /// @notice Sets the amount Resonance increases per charge action.
    function setChargeBoostAmount(uint256 _amount) public onlyOwner {
        chargeBoostAmount = _amount;
        emit ParametersUpdated("chargeBoostAmount", _amount);
    }

     /// @notice Sets the amount Purity increases per tune action.
    function setTuneBoostAmount(uint256 _amount) public onlyOwner {
        tuneBoostAmount = _amount;
        emit ParametersUpdated("tuneBoostAmount", _amount);
    }

    /// @notice Sets the cost in charge tokens to initiate a gem clash.
    function setClashCost(uint256 _cost) public onlyOwner {
        clashCost = _cost;
        emit ParametersUpdated("clashCost", _cost);
    }

    /// @notice Sets the recipient address for clash fees.
    function setClashFeeRecipient(address _recipient) public onlyOwner {
        clashFeeRecipient = _recipient;
        emit AddressParameterUpdated("clashFeeRecipient", _recipient);
    }

    /// @notice Admin function to withdraw collected charge tokens or other ERC20s held by the contract.
    /// @dev Use with caution. Assumes the contract holds transferable tokens.
    function withdrawAdminFees(address tokenAddress, uint256 amount) public onlyOwner {
        if (tokenAddress == address(0)) {
            // Handle potential ETH withdrawal if needed, but ERC20 is the focus here
            // require(address(this).balance >= amount, "Insufficient ETH balance");
            // payable(msg.sender).transfer(amount);
             revert("Cannot withdraw zero address token"); // Prevent accidental ETH call if not intended
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint256 contractBalance = token.balanceOf(address(this));
            if (contractBalance < amount) revert InsufficientChargeTokens(); // Re-use error for clarity
            token.transfer(msg.sender, amount);
        }
    }

     /// @notice Sets the base hash used in trait derivation. Changing this significantly alters traits.
    function setBaseTraitsHash(bytes32 _hash) public onlyOwner {
        baseTraitsHash = _hash;
        // No event needed for bytes32, or define a specific one
    }

    /// @notice Sets the thresholds used to determine trait tiers based on Purity and Resonance.
    /// @dev Thresholds should be sorted ascending.
    function setTraitTierThresholds(uint256[] calldata _purityThresholds, uint256[] calldata _resonanceThresholds) public onlyOwner {
        // Basic validation: check sorting if necessary in a real scenario
        purityThresholds = _purityThresholds;
        resonanceThresholds = _resonanceThresholds;
        // No event needed for arrays
    }


    // --- Internal Helper Functions ---

    /// @dev Applies decay to a gem's Purity and Resonance based on time since last interaction.
    function _updateGemState(uint256 tokenId) internal {
        GemData storage gem = _gems[tokenId];
        uint256 timeElapsed = block.timestamp - gem.lastInteractionTime;

        // Apply decay
        uint256 purityDecay = Math.min(timeElapsed * PURITY_DECAY_RATE_PER_SEC, gem.purity);
        uint256 resonanceDecay = Math.min(timeElapsed * resonanceDecayRatePerSec, gem.resonance);

        gem.purity = gem.purity > purityDecay ? gem.purity - purityDecay : 0;
        gem.resonance = gem.resonance > resonanceDecay ? gem.resonance - resonanceDecay : 0;

        // Update last interaction time
        gem.lastInteractionTime = block.timestamp;
    }

    /// @dev Helper to get a tier index based on a value and sorted thresholds.
    /// For example, thresholds [50, 80] -> value 40 is tier 0, 60 is tier 1, 90 is tier 2.
    function _getTier(uint256 value, uint256[] memory thresholds) internal pure returns (uint256) {
        uint256 tier = 0;
        for (uint i = 0; i < thresholds.length; i++) {
            if (value >= thresholds[i]) {
                tier++;
            } else {
                break;
            }
        }
        return tier;
    }

     // Fallback/Receive functions could be added if receiving ETH is part of the design,
     // but this design relies on ERC20 payments via transferFrom which requires prior approval.
     // receive() external payable {}
     // fallback() external payable {}
}
```

**Explanation of Advanced Concepts & Why it's Not Standard:**

1.  **Dynamic On-Chain State & Traits:** Unlike typical NFTs where traits are static JSON metadata, this contract's `GemData` struct holds mutable properties (`purity`, `resonance`, `lastInteractionTime`, `clashWins`, `clashLosses`). The `getGemDerivedTraits` function *computes* the traits dynamically based on this current on-chain state and time. This means an NFT's appearance or in-game properties can change *without* requiring a metadata update off-chain; the data is derived directly from the smart contract state.
2.  **Time-Based Mechanics:** The `PURITY_DECAY_RATE_PER_SEC`, `resonanceDecayRatePerSec`, and `lastInteractionTime` are used to simulate decay. Functions like `getGemPurity`, `getGemResonance`, and `_updateGemState` explicitly calculate state changes based on the elapsed time (`block.timestamp`). This adds a crucial time-sensitive element to the digital asset.
3.  **Resource Management & Burning/Spending:** Actions like `mintGem`, `chargeGem`, `tuneGem`, and `clashGems` require the user to spend a specific ERC-20 `chargeToken`. This integrates external tokenomics directly into the NFT's utility and lifecycle, potentially creating a deflationary pressure on the charge token if it's minted elsewhere. The contract uses `transferFrom`, meaning users must `approve` the contract first.
4.  **NFT-to-NFT Interaction:** The `clashGems` function is a distinct interaction between two *separate* NFT tokens *within the same contract*. This is more complex than simple token transfers or approvals and introduces a gamified element where one NFT's state/outcome is influenced by another NFT's state.
5.  **On-Chain Simulation:** The `simulateGemEvolution` function is a `pure` or `view` function that takes current state and parameters (time delta, actions) and calculates the *resultant* state *without* performing a transaction. This is valuable for user interfaces to show "what if" scenarios without costing gas, an advanced pattern for complex stateful systems.
6.  **Configurable Logic Parameters:** The admin functions (`setMintCost`, `setResonanceDecayRate`, `setTraitTierThresholds`, etc.) allow the contract owner (or eventually a DAO if extended) to tune the core mechanics of the game/system *after* deployment. This adds flexibility compared to hardcoding all values. The use of arrays (`purityThresholds`, `resonanceThresholds`) for trait tiering shows more complex on-chain configuration.
7.  **Avoiding Standard Libraries:** While using standard interfaces (`IERC20`, `Ownable`, `Math`), the core ERC-721 logic (`_owners`, `_balances`, `_transfer`, `_safeMint`, `approve`, etc.) is implemented manually. This fulfills the request to *not duplicate* an open-source *implementation* like OpenZeppelin's ERC721 *directly*, showcasing understanding of the underlying standard.

This contract combines multiple advanced concepts to create a digital asset that feels more alive and interactive on-chain than a typical static NFT or simple fungible token.