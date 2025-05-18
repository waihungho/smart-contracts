Okay, let's create a smart contract that represents a novel financial primitive: a "Quantum Entanglement Bond".

This contract combines concepts from NFTs (each bond is unique), DeFi (dynamic yield), Oracles (yield reacts to external data), and introduces a custom "entanglement" mechanic where the state or yield of one bond can influence another it's paired with, simulating a non-local correlation.

We will aim for at least 20 custom functions beyond the standard ERC721/Ownable/Pausable methods.

---

**Quantum Entanglement Bond (QEB) Contract**

**Outline:**

1.  **Contract Setup:** Basic imports (ERC721Enumerable, Ownable, Pausable, ReentrancyGuard).
2.  **State Variables:** Store bond details, entanglement data, yield parameters, oracle addresses, administrative settings.
3.  **Structs:** Define the structure of a `Bond` and an `EntanglementDetails` object.
4.  **Enums:** Define types of entanglement effects.
5.  **Events:** Log key actions like issuance, redemption, entanglement, yield updates.
6.  **Core Bond Logic:** Functions for issuing, redeeming, and claiming yield.
7.  **Dynamic Yield Logic:** Functions to calculate yield based on base rate, oracle data, and entanglement effects. Admin functions to set parameters.
8.  **Entanglement Logic:** Functions to propose, accept, query, and break entanglements. Logic to apply entanglement effects.
9.  **Administration:** Functions for pausing, rescuing funds, setting core parameters.
10. **Querying/Views:** Functions to retrieve bond, entanglement, and contract state information.

**Function Summary:**

*   `constructor`: Initializes the contract (ERC721 name/symbol).
*   `issueBond(uint256 _principalAmount, uint64 _maturityTimestamp)`: Mints a new QEB NFT, receives principal payment.
*   `redeemBond(uint256 _bondId)`: Burns a QEB NFT, pays out principal + accumulated yield.
*   `claimYield(uint256 _bondId)`: Pays out accumulated yield for a bond without burning it.
*   `calculateAccumulatedYield(uint256 _bondId)`: (View) Calculates the yield accrued since the last claim or issuance.
*   `getCurrentEffectiveYieldRate(uint256 _bondId)`: (View) Calculates the instantaneous yield rate for a bond, considering all factors (base, oracle, entanglement).
*   `updateBaseYieldRate(uint64 _newBaseRate)`: (Admin) Sets the global base yield rate.
*   `setOracleAddress(address _oracle)`: (Admin) Sets the address of the oracle contract used for yield calculation.
*   `fetchAndApplyOracleData()`: (Callable by Admin/Keeper) Calls the oracle to get the latest external data influencing yield.
*   `simulateExternalYieldSource(uint256 _amount)`: (Admin/Keeper) Represents funds entering the contract that accrue from underlying assets (needed to pay yield).
*   `proposeEntanglement(uint256 _bondIdA, uint256 _bondIdB, EntanglementEffectType _effectType)`: Proposes linking bond A (owned by caller) to bond B.
*   `acceptEntanglement(uint256 _bondIdA, uint256 _bondIdB)`: Owner of bond B accepts the proposal from bond A's owner.
*   `disentangle(uint256 _bondId)`: Breaks the entanglement link involving this bond.
*   `getEntanglementDetails(uint256 _bondId)`: (View) Returns details if a bond is entangled.
*   `getPendingEntanglements(uint256 _bondId)`: (View) Returns pending entanglement proposals involving this bond.
*   `removePendingEntanglement(uint256 _bondIdA, uint256 _bondIdB)`: Proposer removes their entanglement proposal.
*   `setAllowedEntanglementEffect(EntanglementEffectType _effectType, bool _allowed)`: (Admin) Toggles permission for specific entanglement effects.
*   `updateEntanglementEffectParameters(EntanglementEffectType _effectType, int256[] memory _params)`: (Admin) Sets or updates parameters for an entanglement effect (e.g., percentage boost, penalty amount).
*   `pause()`: (Admin) Pauses sensitive contract functions.
*   `unpause()`: (Admin) Unpauses the contract.
*   `rescueFunds(address _token, uint256 _amount)`: (Admin) Recovers accidentally sent tokens (excluding the contract's core assets).
*   `getBondDetails(uint256 _bondId)`: (View) Retrieves all stored data for a specific bond.
*   `getTotalPrincipalIssued()`: (View) Returns the total principal amount across all active bonds.
*   `getTotalContractBalance()`: (View) Returns the contract's balance of the primary payment token (e.g., Ether/Wrapped Ether).

*(Note: ERC721Enumerable, Ownable, Pausable, and ReentrancyGuard add functions like `transferFrom`, `ownerOf`, `totalSupply`, `owner`, `paused`, etc., bringing the total function count well over 20, but the summary focuses on the custom logic.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max if needed later
import "@openzeppelin/contracts/utils/Address.sol";

// Interface for a simplified Oracle (replace with real oracle like Chainlink in production)
interface ISimplifiedOracle {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

/**
 * @title QuantumEntanglementBond
 * @dev A novel ERC721-based bond contract with dynamic yield and entanglement mechanics.
 * Yield is influenced by a base rate, external oracle data, and the state of an entangled bond.
 * Each bond is a unique NFT.
 */
contract QuantumEntanglementBond is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {

    using Address for address;

    // --- Enums ---

    enum EntanglementEffectType {
        NONE,
        YIELD_BOOST_OTHER,      // When owner of bond A claims yield, bond B gets a yield boost factor applied to its rate calculation
        YIELD_PENALTY_OTHER,    // When owner of bond A claims yield, bond B gets a yield penalty factor applied
        REDEMPTION_BONUS_SELF,  // Redeeming entangled bond A gives A's owner a bonus on principal
        REDEMPTION_PENALTY_SELF,// Redeeming entangled bond A gives A's owner a penalty on principal
        YIELD_RATE_CORRELATION  // Bond A's current rate is adjusted based on Bond B's rate (e.g., inversely correlated)
        // Add more complex effects here...
    }

    // --- Structs ---

    struct Bond {
        uint256 principalAmount;      // The initial amount invested
        uint64 issueTimestamp;        // When the bond was minted
        uint64 maturityTimestamp;     // When the bond matures (0 for perpetual)
        uint256 accumulatedYield;     // Yield calculated but not yet claimed/paid out
        uint64 lastYieldUpdateTimestamp; // Last time yield was calculated/claimed/redeemed

        // Entanglement State
        uint256 entangledBondId;      // ID of the bond it's entangled with (0 if none)
        EntanglementEffectType effect; // The specific effect applied when entangled
        int256[] effectParameters;   // Parameters for the effect (e.g., percentage points, multiplier)
    }

    struct EntanglementProposal {
        uint256 bondIdA;             // The bond initiating the proposal
        address proposer;            // Owner of bondIdA
        uint256 bondIdB;             // The target bond
        EntanglementEffectType effectType; // Proposed effect
        uint64 proposalTimestamp;    // When the proposal was made
    }

    // --- State Variables ---

    mapping(uint256 => Bond) public bonds;
    uint256 private _bondCounter; // Counter for unique bond IDs

    // Entanglement Storage
    // Mapping from bondIdA to bondIdB for active entanglements (unidirectional storage, but links are bidirectional)
    mapping(uint256 => uint256) private _entangledBondLink; // bondId => entangledBondId
    // Details stored on bond A's struct. bondIdB's struct will only store the link.
    mapping(uint256 => EntanglementProposal) private _pendingEntanglements; // bondIdB => proposal details (only one pending proposal per bond B)

    // Yield Parameters
    uint64 public baseYieldRateBps; // Base yield rate in Basis Points (e.g., 100 = 1%) per year
    ISimplifiedOracle public oracle;
    int256 public currentOracleData; // Latest data fetched from the oracle
    uint64 public lastOracleFetchTimestamp;

    // Configuration
    address public yieldPaymentToken; // The token used for principal and yield payment (e.g., WETH)
    mapping(EntanglementEffectType => bool) public allowedEntanglementEffects;
    mapping(EntanglementEffectType => int256[]) public entanglementEffectParams; // Configurable parameters per effect type

    // --- Events ---

    event BondIssued(uint256 indexed bondId, address indexed owner, uint256 principalAmount, uint64 maturityTimestamp);
    event BondRedeemed(uint256 indexed bondId, address indexed owner, uint256 principalAmount, uint256 yieldPaid);
    event YieldClaimed(uint256 indexed bondId, address indexed owner, uint256 yieldPaid);
    event BaseYieldRateUpdated(uint64 newRateBps);
    event OracleAddressUpdated(address indexed oracleAddress);
    event OracleDataFetched(int256 data, uint64 timestamp);
    event EntanglementProposed(uint256 indexed bondIdA, uint256 indexed bondIdB, EntanglementEffectType effectType);
    event EntanglementAccepted(uint256 indexed bondIdA, uint256 indexed bondIdB, EntanglementEffectType effectType);
    event Disentangled(uint256 indexed bondId1, uint256 indexed bondId2);
    event AllowedEntanglementEffectUpdated(EntanglementEffectType effectType, bool allowed);
    event EntanglementEffectParametersUpdated(EntanglementEffectType effectType, int256[] params);
    event FundsRescued(address indexed token, address indexed recipient, uint256 amount);
    event SimulatedYieldSource(uint256 amount);

    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        address _yieldPaymentToken,
        uint64 _initialBaseYieldRateBps,
        address _initialOracle
    ) ERC721(name, symbol) Ownable(msg.sender) Pausable(false) {
        require(_yieldPaymentToken != address(0), "Invalid token address");
        require(_initialOracle != address(0), "Invalid oracle address");

        yieldPaymentToken = _yieldPaymentToken;
        baseYieldRateBps = _initialBaseYieldRateBps;
        oracle = ISimplifiedOracle(_initialOracle);
        _bondCounter = 0; // Bond IDs start from 1

        // Default allowed effects (example)
        allowedEntanglementEffects[EntanglementEffectType.YIELD_BOOST_OTHER] = true;
        allowedEntanglementEffects[EntanglementEffectType.REDEMPTION_BONUS_SELF] = true;
        allowedEntanglementEffects[EntanglementEffectType.YIELD_RATE_CORRELATION] = true;

        emit BaseYieldRateUpdated(baseYieldRateBps);
        emit OracleAddressUpdated(_initialOracle);

        // Fetch initial oracle data
        fetchAndApplyOracleData();
    }

    // --- Core Bond Logic ---

    /**
     * @dev Issues a new Quantum Entanglement Bond NFT.
     * Mints a unique bond token to the caller and records bond details.
     * Requires the caller to send `_principalAmount` of the yieldPaymentToken.
     * @param _principalAmount The principal amount of the bond.
     * @param _maturityTimestamp The timestamp when the bond matures (0 for perpetual).
     */
    function issueBond(uint256 _principalAmount, uint64 _maturityTimestamp)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(_principalAmount > 0, "Principal must be greater than 0");
        // In a real system, would check msg.value if using ETH or require IERC20.transferFrom
        // Here we assume yieldPaymentToken is ERC20 and requires approval
        // Or, if yieldPaymentToken is WETH, msg.value can be used for WETH deposit/wrap
        // For simplicity in this example, let's assume yieldPaymentToken is an ERC20
        // and the user has pre-approved the contract.
        // require(msg.value == 0, "Use approve/transferFrom for ERC20"); // If using ERC20
        // Or require msg.value if yieldPaymentToken is WETH and depositing ETH

        // Let's assume the ERC20 transfer happens *before* calling issueBond
        // Or handle WETH wrap/deposit logic here if yieldPaymentToken is WETH

        uint256 bondId = _bondCounter + 1;
        _bondCounter = bondId;

        // Transfer principal from the user
        IERC20(yieldPaymentToken).transferFrom(msg.sender, address(this), _principalAmount);

        bonds[bondId] = Bond({
            principalAmount: _principalAmount,
            issueTimestamp: uint64(block.timestamp),
            maturityTimestamp: _maturityTimestamp,
            accumulatedYield: 0,
            lastYieldUpdateTimestamp: uint64(block.timestamp),
            entangledBondId: 0,
            effect: EntanglementEffectType.NONE,
            effectParameters: new int256[](0)
        });

        _safeMint(msg.sender, bondId);

        emit BondIssued(bondId, msg.sender, _principalAmount, _maturityTimestamp);
    }

    /**
     * @dev Redeems a Quantum Entanglement Bond.
     * Burns the bond NFT and pays out the principal plus accumulated yield to the owner.
     * Applies potential entanglement effects on redemption.
     * @param _bondId The ID of the bond to redeem.
     */
    function redeemBond(uint256 _bondId)
        external
        nonReentrant
        whenNotPaused
    {
        address owner = ownerOf(_bondId);
        require(owner == msg.sender, "Caller is not the bond owner");

        Bond storage bond = bonds[_bondId];
        require(bond.principalAmount > 0, "Bond does not exist or already redeemed"); // Check bond existence

        // Calculate final yield before redemption
        _accumulateYield(_bondId); // Ensure yield is up-to-date

        uint256 principalToPay = bond.principalAmount;
        uint256 yieldToPay = bond.accumulatedYield;
        uint256 totalToPay = principalToPay + yieldToPay;

        // Apply potential entanglement effects on redemption (affecting self)
        if (bond.entangledBondId != 0 && bond.effect != EntanglementEffectType.NONE) {
             (uint256 adjustedPrincipal, uint256 adjustedYield) = _applyRedemptionEntanglementEffect(_bondId, principalToPay, yieldToPay);
             principalToPay = adjustedPrincipal;
             yieldToPay = adjustedYield;
             totalToPay = principalToPay + yieldToPay;
        }

        // Ensure contract has enough balance
        require(IERC20(yieldPaymentToken).balanceOf(address(this)) >= totalToPay, "Insufficient contract balance for redemption");

        // Reset bond data before transfer (important for reentrancy)
        delete bonds[_bondId];
        // Remove entanglement link if exists
        if (_entangledBondLink[_bondId] != 0) {
             disentangle(_bondId); // Calls _disentangleInternal which clears link for both
        }


        // Burn the NFT
        _burn(_bondId);

        // Transfer funds
        IERC20(yieldPaymentToken).transfer(owner, totalToPay);

        emit BondRedeemed(_bondId, owner, principalToPay, yieldToPay);
    }

     /**
     * @dev Claims accumulated yield for a Quantum Entanglement Bond without redeeming it.
     * Pays out the accrued yield and resets the yield counter for the bond.
     * Applies potential entanglement effects on yield claim (affecting the other bond).
     * @param _bondId The ID of the bond to claim yield for.
     */
    function claimYield(uint256 _bondId)
        external
        nonReentrant
        whenNotPaused
    {
        address owner = ownerOf(_bondId);
        require(owner == msg.sender, "Caller is not the bond owner");

        Bond storage bond = bonds[_bondId];
        require(bond.principalAmount > 0, "Bond does not exist"); // Check bond existence

        // Ensure yield is up-to-date before claiming
        _accumulateYield(_bondId);

        uint256 yieldToPay = bond.accumulatedYield;
        require(yieldToPay > 0, "No yield to claim");

        // Reset accumulated yield BEFORE transfer
        bond.accumulatedYield = 0;
        bond.lastYieldUpdateTimestamp = uint64(block.timestamp);

        // Ensure contract has enough balance
        require(IERC20(yieldPaymentToken).balanceOf(address(this)) >= yieldToPay, "Insufficient contract balance for yield claim");

        // Transfer yield
        IERC20(yieldPaymentToken).transfer(owner, yieldToPay);

        emit YieldClaimed(_bondId, owner, yieldToPay);

        // Apply potential entanglement effects after successful yield claim (affecting the OTHER bond)
        if (bond.entangledBondId != 0 && bond.effect != EntanglementEffectType.NONE) {
            _applyYieldClaimEntanglementEffect(_bondId, bond.entangledBondId, yieldToPay);
        }
    }


    // --- Dynamic Yield Logic ---

     /**
     * @dev Internal function to calculate and accumulate yield for a bond since its last update.
     * Updates the `accumulatedYield` and `lastYieldUpdateTimestamp` fields of the Bond struct.
     * @param _bondId The ID of the bond to update.
     */
    function _accumulateYield(uint256 _bondId) internal {
        Bond storage bond = bonds[_bondId];
        require(bond.principalAmount > 0, "Bond does not exist"); // Should not happen if called internally after checks

        uint64 lastUpdate = bond.lastYieldUpdateTimestamp;
        uint66 timeElapsed = uint66(block.timestamp - lastUpdate);

        if (timeElapsed == 0) {
            return; // No time elapsed, no yield to accumulate
        }

        uint256 currentRateBps = getCurrentEffectiveYieldRate(_bondId);

        // Prevent yield calculation issues with negative rates
        if (currentRateBps == 0) {
            bond.lastYieldUpdateTimestamp = uint64(block.timestamp);
            return;
        }

        // Yield = Principal * Rate * Time / (Basis Points Divisor * Time Period Divisor)
        // Rate is in BPS per year. Time is in seconds.
        // Annual basis points: 10000 (100%)
        // Seconds in a year: 31536000 (approx)
        // Yield = principal * (rateBps / 10000) * (timeElapsed / 31536000)
        //       = (principal * rateBps * timeElapsed) / (10000 * 31536000)

        // Use a fixed large denominator to maintain precision during multiplication
        // Let's use seconds in a year and basis points divisor: 31536000 * 10000 = 315,360,000,000
        uint256 yieldAmount = (bond.principalAmount * currentRateBps * timeElapsed) / (10000 * 31536000);

        bond.accumulatedYield += yieldAmount;
        bond.lastYieldUpdateTimestamp = uint64(block.timestamp);
    }


     /**
     * @dev Calculates the current effective annual yield rate for a specific bond in Basis Points (BPS).
     * This rate is influenced by the base rate, current oracle data, and entanglement effects.
     * @param _bondId The ID of the bond.
     * @return The effective annual yield rate in BPS.
     */
    function getCurrentEffectiveYieldRate(uint256 _bondId)
        public
        view
        returns (uint256)
    {
        require(bonds[_bondId].principalAmount > 0, "Bond does not exist");

        uint256 rateBps = baseYieldRateBps;

        // Influence from Oracle Data (example: positive oracle data increases yield)
        // Assuming oracle data is signed integer, maybe map it to a BPS adjustment
        // Example: rateBps += (uint256(currentOracleData) * OracleFactor) / Denominator
        // Let's keep it simple: positive oracle data adds BPS, negative subtracts
        if (currentOracleData > 0) {
            rateBps += uint256(currentOracleData);
        } else if (currentOracleData < 0) {
             // Ensure rate doesn't go below 0
            uint256 deduction = uint256(-currentOracleData);
            rateBps = rateBps > deduction ? rateBps - deduction : 0;
        }


        // Influence from Entanglement (affecting SELF)
        // This part depends on the EntanglementEffectType associated with THIS bond (_bondId)
        uint256 entangledBondId = bonds[_bondId].entangledBondId;
        EntanglementEffectType effect = bonds[_bondId].effect;
        int256[] memory params = bonds[_bondId].effectParameters;

        if (entangledBondId != 0 && effect == EntanglementEffectType.YIELD_RATE_CORRELATION) {
             // Example: Inverse Correlation
             // Rate of Bond A = BaseRate - Factor * (Rate of Bond B)
             // This could get complex quickly with recursive calls.
             // Let's simplify: YIELD_RATE_CORRELATION means Bond A's rate is adjusted by a factor based on Oracle *data* of Bond B
             // This needs Bond B's oracle data state, which isn't easily accessible directly on chain without specific design.
             // A simpler approach: YIELD_RATE_CORRELATION effect on Bond A means Bond A's rate is adjusted based on *its own*
             // state relative to the entangled pair, or based on parameters set for the correlation effect type.
             // Let's use a simpler, non-recursive example: Add or subtract a BPS value from params[0]
             if (params.length > 0) {
                 if (params[0] >= 0) {
                     rateBps += uint256(params[0]);
                 } else {
                     uint256 deduction = uint256(-params[0]);
                     rateBps = rateBps > deduction ? rateBps - deduction : 0;
                 }
             }
        }
         // Add other effects that influence SELF's rate here... e.g. STATE_DEPENDENT_BOOST

        return rateBps;
    }

    /**
     * @dev (View) Calculates the potential yield that has accumulated for a bond.
     * Does NOT update the bond's state. For display purposes.
     * @param _bondId The ID of the bond.
     * @return The amount of accumulated yield.
     */
    function calculateAccumulatedYield(uint256 _bondId)
        public
        view
        returns (uint256)
    {
        Bond storage bond = bonds[_bondId];
         require(bond.principalAmount > 0, "Bond does not exist");

        uint64 lastUpdate = bond.lastYieldUpdateTimestamp;
        uint64 timeElapsed = uint64(block.timestamp - lastUpdate);

        if (timeElapsed == 0) {
            return bond.accumulatedYield; // Return already accumulated yield
        }

        uint256 currentRateBps = getCurrentEffectiveYieldRate(_bondId);

        if (currentRateBps == 0) {
             return bond.accumulatedYield; // Return already accumulated yield
        }

        uint256 yieldAmount = (bond.principalAmount * currentRateBps * timeElapsed) / (10000 * 31536000);

        return bond.accumulatedYield + yieldAmount;
    }


    /**
     * @dev Sets the base annual yield rate for all bonds in Basis Points (BPS).
     * Only callable by the owner.
     * @param _newBaseRateBps The new base rate in BPS.
     */
    function updateBaseYieldRate(uint64 _newBaseRateBps) external onlyOwner {
        baseYieldRateBps = _newBaseRateBps;
        emit BaseYieldRateUpdated(_newBaseRateBps);
    }

     /**
     * @dev Sets the address of the oracle contract.
     * Only callable by the owner.
     * @param _oracle The address of the oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
         require(_oracle != address(0), "Invalid oracle address");
        oracle = ISimplifiedOracle(_oracle);
        emit OracleAddressUpdated(_oracle);
    }

     /**
     * @dev Fetches the latest data from the configured oracle and updates the state.
     * This function would typically be called by a keeper or automation service.
     * In a real application, consider requiring a specific caller address or role.
     */
    function fetchAndApplyOracleData() public {
        // Add access control here if not intended for public call
        // require(msg.sender == keeperAddress, "Unauthorized"); // Example

        require(address(oracle) != address(0), "Oracle address not set");
        (int256 data, uint265 timestamp) = oracle.latestAnswer(); // Simplified: assuming oracle returns data and timestamp

        // Add logic to validate timestamp if needed (e.g., data is recent enough)
        currentOracleData = data;
        lastOracleFetchTimestamp = uint64(timestamp);

        emit OracleDataFetched(data, lastOracleFetchTimestamp);
    }

    /**
     * @dev Simulates yield being generated by underlying assets and added to the contract balance.
     * In a real protocol, this would be where yield farming rewards are harvested
     * or fees are collected and transferred to the contract.
     * @param _amount The amount of yieldPaymentToken to add to the contract's balance.
     */
    function simulateExternalYieldSource(uint256 _amount) external onlyOwner {
        // This function requires the caller to transfer the tokens *separately*
        // to the contract address before calling this function, OR
        // This function is called *after* harvesting from a yield source
        // and the tokens are already in the contract.
        // For this example, we assume the tokens are already in the contract.
        // In a real scenario, you might want to pull from a specific yield vault.
        // require(IERC20(yieldPaymentToken).balanceOf(address(this)) >= _amount, "Insufficient balance to simulate adding"); // Not needed if funds are already here

        // No state change needed in this simple simulation, just an event
        // The actual funds must arrive via a direct transfer to the contract address.
        emit SimulatedYieldSource(_amount);
    }

    // --- Entanglement Logic ---

     /**
     * @dev Proposes an entanglement between two bonds.
     * The caller must own bondIdA. bondIdB is the target bond owned by another user.
     * The owner of bondIdB must accept the proposal.
     * Only one pending proposal is allowed for bondIdB at a time.
     * Bonds cannot be entangled if they are already entangled or part of an active proposal.
     * @param _bondIdA The ID of the bond initiating the proposal (owned by msg.sender).
     * @param _bondIdB The ID of the bond to be entangled with.
     * @param _effectType The proposed entanglement effect type.
     */
    function proposeEntanglement(uint256 _bondIdA, uint256 _bondIdB, EntanglementEffectType _effectType)
        external
        whenNotPaused
    {
        require(_bondIdA != _bondIdB, "Cannot entangle a bond with itself");
        require(ownerOf(_bondIdA) == msg.sender, "Caller must own bondIdA");
        require(ownerOf(_bondIdB) != msg.sender, "Cannot propose entanglement to self-owned bond"); // Entangle with others
        require(bonds[_bondIdA].principalAmount > 0 && bonds[_bondIdB].principalAmount > 0, "Bonds must exist");
        require(bonds[_bondIdA].entangledBondId == 0 && bonds[_bondIdB].entangledBondId == 0, "Bonds must not be already entangled");
        require(_pendingEntanglements[_bondIdB].bondIdB == 0, "Bond B already has a pending proposal"); // No proposal for B

        require(allowedEntanglementEffects[_effectType], "Proposed effect type is not allowed");
        require(_effectType != EntanglementEffectType.NONE, "Cannot propose NONE effect");

        _pendingEntanglements[_bondIdB] = EntanglementProposal({
            bondIdA: _bondIdA,
            proposer: msg.sender,
            bondIdB: _bondIdB,
            effectType: _effectType,
            proposalTimestamp: uint64(block.timestamp)
        });

        emit EntanglementProposed(_bondIdA, _bondIdB, _effectType);
    }

    /**
     * @dev Accepts a pending entanglement proposal for a bond owned by the caller.
     * Establishes the entanglement link between bondIdA and bondIdB.
     * @param _bondIdA The ID of the bond that initiated the proposal.
     * @param _bondIdB The ID of the bond owned by the caller (target of the proposal).
     */
    function acceptEntanglement(uint256 _bondIdA, uint256 _bondIdB)
        external
        whenNotPaused
    {
        require(_bondIdA != _bondIdB, "Invalid entanglement pair");
        require(ownerOf(_bondIdB) == msg.sender, "Caller must own bondIdB to accept");

        EntanglementProposal storage proposal = _pendingEntanglements[_bondIdB];
        require(proposal.bondIdA == _bondIdA, "No pending proposal from bondIdA for bondIdB");
        require(bonds[_bondIdA].entangledBondId == 0 && bonds[_bondIdB].entangledBondId == 0, "Bonds must not be already entangled");
        require(bonds[_bondIdA].principalAmount > 0 && bonds[_bondIdB].principalAmount > 0, "Bonds must exist");

        // Clear pending proposal
        delete _pendingEntanglements[_bondIdB];

        // Establish entanglement link
        bonds[_bondIdA].entangledBondId = _bondIdB;
        bonds[_bondIdA].effect = proposal.effectType;
         // Copy effect parameters for the active entanglement
        bonds[_bondIdA].effectParameters = entanglementEffectParams[proposal.effectType];


        bonds[_bondIdB].entangledBondId = _bondIdA;
        // Note: bondIdB's struct only stores the link. bondIdA's struct stores the effect details.
        // This simplifies lookup: you always check bond A's struct for details.
        // Need to decide if effects are symmetric or asymmetric. Let's assume asymmetric - effect is stored on bond A, applied based on actions involving A or B.
        // A simpler way: store effect on BOTH, but maybe mirrored. Or, enforce one direction.
        // Let's refine: The effect is applied *on* bond B when something happens to bond A (or vice versa depending on effect type). The details are stored on bond A.
        // So bond B just needs to know it's linked and lookup A for details.
         bonds[_bonddB].effect = EntanglementEffectType.NONE; // B's struct doesn't hold effect details
         bonds[_bonddB].effectParameters = new int256[](0);

        // Store the link bidirectionally for easy lookup
        _entangledBondLink[_bondIdA] = _bondIdB;
        _entangledBondLink[_bondIdB] = _bondIdA;


        emit EntanglementAccepted(_bondIdA, _bondIdB, proposal.effectType);
    }

    /**
     * @dev Breaks an active entanglement link involving the specified bond.
     * Either owner of the entangled pair can call this.
     * @param _bondId The ID of one of the bonds in the entangled pair.
     */
    function disentangle(uint256 _bondId)
        public // Made public so redeem/transfer can call it
        whenNotPaused // Check pause status here or in internal function? Let's check here.
    {
        address owner1 = ownerOf(_bondId);
        require(owner1 == msg.sender, "Caller must own the bond");

        uint256 bondId2 = _entangledBondLink[_bondId];
        require(bondId2 != 0, "Bond is not entangled");

        // Ensure the caller owns *one* of the bonds in the pair
        require(owner1 == ownerOf(bondId2) || owner1 == msg.sender, "Caller must own one of the entangled bonds");

        _disentangleInternal(_bondId, bondId2);
    }

     /**
     * @dev Internal function to break the entanglement link between two bonds.
     * Called by disentangle or potentially redeem/transfer logic if entanglement must break on state change.
     * @param _bondId1 The ID of the first bond.
     * @param _bondId2 The ID of the second bond.
     */
    function _disentangleInternal(uint256 _bondId1, uint256 _bondId2) internal {
        // Clear links
        delete _entangledBondLink[_bondId1];
        delete _entangledBondLink[_bondId2];

        // Clear entanglement details from the bond struct that stored them (bondId1)
        bonds[_bondId1].entangledBondId = 0;
        bonds[_bondId1].effect = EntanglementEffectType.NONE;
        bonds[_bondId1].effectParameters = new int256[](0);

         // Clear entanglement details from the other bond struct (bondId2)
        bonds[_bondId2].entangledBondId = 0;
        bonds[_bondId2].effect = EntanglementEffectType.NONE; // This should already be NONE based on our design
        bonds[_bondId2].effectParameters = new int256[](0); // This should already be empty based on our design

        // Clear any pending proposal involving bondId2 (as target)
        if (_pendingEntanglements[_bondId2].bondIdB != 0 && _pendingEntanglements[_bondId2].bondIdA == _bondId1) {
             delete _pendingEntanglements[_bondId2];
        }
         // Clear any pending proposal involving bondId1 (as target)
        if (_pendingEntanglements[_bondId1].bondIdB != 0 && _pendingEntanglements[_bondId1].bondIdA == _bondId2) {
             delete _pendingEntanglements[_bondId1];
        }


        emit Disentangled(_bondId1, _bondId2);
    }


    /**
     * @dev Internal function to apply entanglement effects that occur upon redeeming a bond.
     * Effects of type REDEMPTION_*_SELF apply to the bond being redeemed.
     * Effects of type REDEMPTION_*_OTHER would apply to the entangled bond (though not implemented here).
     * @param _bondId The bond being redeemed.
     * @param _principal The principal amount before effect.
     * @param _yield The yield amount before effect.
     * @return adjustedPrincipal, adjustedYield
     */
    function _applyRedemptionEntanglementEffect(uint256 _bondId, uint256 _principal, uint256 _yield)
        internal
        view // This view assumes effects only depend on *parameters*, not other bond's state
        returns (uint256, uint256)
    {
        Bond storage bond = bonds[_bondId];
        uint256 adjustedPrincipal = _principal;
        uint256 adjustedYield = _yield;

        if (bond.entangledBondId == 0 || bond.effect == EntanglementEffectType.NONE) {
            return (_principal, _yield); // No entanglement or no effect
        }

        // Effect details are stored on the bond struct itself according to our design
        EntanglementEffectType effect = bond.effect;
        int256[] memory params = bond.effectParameters;

        // Apply effects that modify the SELF bond being redeemed
        if (effect == EntanglementEffectType.REDEMPTION_BONUS_SELF && params.length > 0) {
            // Assume params[0] is percentage boost (e.g., 500 = 5%)
            uint256 bonusBps = uint256(params[0]);
            adjustedPrincipal += (_principal * bonusBps) / 10000; // Apply bonus to principal
            // Or apply to yield, or both? Let's apply to principal for this example.

        } else if (effect == EntanglementEffectType.REDEMPTION_PENALTY_SELF && params.length > 0) {
            // Assume params[0] is percentage penalty (e.g., 200 = 2%)
             uint265 penaltyBps = uint256(params[0]);
             // Ensure penalty doesn't exceed principal
             uint256 deduction = (_principal * penaltyBps) / 10000;
             adjustedPrincipal = adjustedPrincipal > deduction ? adjustedPrincipal - deduction : 0;
             // Note: Penalties on yield are tricky if yield is already calculated. Better to affect principal or future yield.

        }
        // Add other redemption effects affecting SELF here... e.g., BURN_OTHER_BOND

        // Effects that would apply to the *other* bond on this redemption event
        // This would require interacting with the other bond's state or calling a function on it.
        // For now, we won't implement cross-bond state changes triggered *by* this function call
        // because it adds complexity and potential reentrancy concerns if the other bond had complex logic.
        // A safer pattern is for the *other* bond's functions (like getYieldRate or redeemBond)
        // to *read* the state of this bond and apply an effect *on itself*.

        return (adjustedPrincipal, adjustedYield);
    }

    /**
     * @dev Internal function to apply entanglement effects that occur upon claiming yield from a bond.
     * Effects of type YIELD_*_OTHER apply to the entangled bond.
     * @param _bondIdClaiming The bond whose yield is being claimed.
     * @param _bondIdAffected The entangled bond that might be affected.
     * @param _yieldAmountClaimed The amount of yield claimed by the first bond. (Could be a parameter for some effects)
     */
    function _applyYieldClaimEntanglementEffect(uint256 _bondIdClaiming, uint256 _bondIdAffected, uint225 _yieldAmountClaimed) internal {
        // This function is called *after* the yield claim is successful.
        // Effects applied here should modify the STATE of _bondIdAffected or emit events for it.
        // They should NOT modify the payout of _bondIdClaiming as that's already done.

        // The entanglement effect details are stored on the bond that INITIATED the entanglement.
        // We need to find which bond (claiming vs affected) is the "initiator" to get the effect details.
        uint256 initiatorBondId = _bondIdClaiming;
        uint256 targetBondId = _bondIdAffected;

        if (_entangledBondLink[_bondIdAffected] == _bondIdClaiming) {
             // If affected bond points back to claiming bond, the claiming bond is the initiator
             initiatorBondId = _bondIdClaiming;
             targetBondId = _bondIdAffected;
        } else if (_entangledBondLink[_bondIdClaiming] == _bondIdAffected) {
             // If claiming bond points to affected bond, claiming bond is the initiator (already set)
             initiatorBondId = _bondIdClaiming;
             targetBondId = _bondIdAffected;
        } else {
            // Should not happen if called correctly after checking entanglement
            return;
        }


        Bond storage initiatorBond = bonds[initiatorBondId];
        EntanglementEffectType effect = initiatorBond.effect;
        int256[] memory params = initiatorBond.effectParameters;

        // Apply effects that modify the OTHER bond (_bondIdAffected) based on this yield claim event
        if (effect == EntanglementEffectType.YIELD_BOOST_OTHER && params.length > 0) {
            // Example: Add a BPS boost to the affected bond's rate calculation for a duration or permanently?
            // Permanent boost: Add a modifier to the affected bond's state? This needs a more complex Bond struct.
            // Temporary boost: Hard to manage time-based effects without state.
            // Alternative: Just add a lump sum to the affected bond's accumulated yield?
            // Let's add a BPS boost *parameter* to the affected bond's struct temporarily or semi-permanently.
            // This requires the Affected Bond's struct to also store effect/parameters applied TO it.
            // Our current struct design stores the *effect initiated by* that bond.
            // Need to revise Bond struct or store incoming effects separately.

            // REVISED DESIGN: Let's store ACTIVE incoming effects on the target bond.
            // struct Bond { ... EntanglementState[] incomingEffects; } -> Too complex with dynamic arrays.
            // Let's simplify EntanglementEffectType: It's the effect that applies TO Bond B when something happens to Bond A, where A proposed.
            // So Bond A's struct `effect` field describes what happens to Bond B.

            // Back to applying YIELD_BOOST_OTHER: The effect is stored on Bond A.
            // When Bond A (initiatorBondId) claims yield, Bond B (targetBondId) gets a boost.
            // This boost should affect B's `getCurrentEffectiveYieldRate` calculation.
            // This implies `getCurrentEffectiveYieldRate` needs to check if the bond is a *target* of an effect.
            // This requires Bond B's struct to know *what effect is applied TO it* by A.

            // Let's reconsider the struct:
            // Bond { ... uint256 entangledBondId; EntanglementDetails details; }
            // EntanglementDetails { uint256 partnerBondId; EntanglementEffectType effectType; int256[] params; bool isInitiator; }
            // This adds complexity.

            // Simpler approach sticking to current struct:
            // When Bond A claims yield, *if A is the initiator and effect is YIELD_BOOST_OTHER*,
            // add a lump sum to Bond B's accumulated yield based on `params[0]`.
             if (params.length > 0) {
                 uint256 boostPercentageBps = uint256(params[0]); // e.g., 100 means 1% of principal
                 uint256 boostAmount = (bonds[targetBondId].principalAmount * boostPercentageBps) / 10000;

                // Ensure target bond's yield is accumulated first for a clean state
                _accumulateYield(targetBondId); // Apply any accrued yield before adding bonus
                bonds[targetBondId].accumulatedYield += boostAmount;
                // No need to update lastYieldUpdateTimestamp for target, as _accumulateYield did that.

                // Optional: Emit event for the boost received by the target bond
                // emit EntanglementYieldBoostApplied(targetBondId, initiatorBondId, boostAmount);
             }
        }
        // Add other yield claim effects affecting OTHER here... e.g., TRANSFER_PORTION_OF_YIELD_TO_OTHER
    }


    /**
     * @dev Allows the proposer of a pending entanglement to cancel it.
     * @param _bondIdA The ID of the bond that initiated the proposal (owned by msg.sender).
     * @param _bondIdB The ID of the target bond.
     */
    function removePendingEntanglement(uint256 _bondIdA, uint256 _bondIdB) external whenNotPaused {
        EntanglementProposal storage proposal = _pendingEntanglements[_bondIdB];
        require(proposal.bondIdB == _bondIdB && proposal.bondIdA == _bondIdA, "No matching pending proposal");
        require(proposal.proposer == msg.sender, "Caller is not the proposer");

        delete _pendingEntanglements[_bondIdB];
        // No event needed here, or add one if desired.
    }


    /**
     * @dev Sets whether a specific entanglement effect type is allowed for new entanglements.
     * Only callable by the owner.
     * @param _effectType The effect type to configure.
     * @param _allowed True to allow, false to disallow.
     */
    function setAllowedEntanglementEffect(EntanglementEffectType _effectType, bool _allowed) external onlyOwner {
        require(_effectType != EntanglementEffectType.NONE, "NONE effect cannot be configured");
        allowedEntanglementEffects[_effectType] = _allowed;
        emit AllowedEntanglementEffectUpdated(_effectType, _allowed);
    }

    /**
     * @dev Sets or updates the parameters for a specific allowed entanglement effect type.
     * These parameters are copied when an entanglement is accepted.
     * Only callable by the owner.
     * @param _effectType The effect type to configure parameters for.
     * @param _params The array of integer parameters for the effect.
     */
    function updateEntanglementEffectParameters(EntanglementEffectType _effectType, int256[] memory _params) external onlyOwner {
        require(allowedEntanglementEffects[_effectType], "Effect type is not allowed");
        require(_effectType != EntanglementEffectType.NONE, "NONE effect cannot be configured");

        entanglementEffectParams[_effectType] = _params; // Overwrites previous parameters
        emit EntanglementEffectParametersUpdated(_effectType, _params);
    }


    // --- Administration ---

    /**
     * @dev Pauses the contract. Prevents core actions like issue, redeem, claim, entanglement.
     * Only callable by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     * Only callable by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

     /**
     * @dev Allows the owner to rescue tokens accidentally sent to the contract.
     * Excludes the primary yieldPaymentToken to prevent draining contract funds needed for redemptions.
     * @param _token The address of the token to rescue.
     * @param _amount The amount of tokens to rescue.
     */
    function rescueFunds(address _token, uint256 _amount) external onlyOwner nonReentrant {
        require(_token != yieldPaymentToken, "Cannot rescue primary payment token");
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount, "Insufficient contract balance of token");
        token.transfer(owner(), _amount);
        emit FundsRescued(_token, owner(), _amount);
    }


    // --- Querying/Views ---

     /**
     * @dev Retrieves the details of a specific bond.
     * @param _bondId The ID of the bond.
     * @return The Bond struct containing all details.
     */
    function getBondDetails(uint256 _bondId)
        external
        view
        returns (Bond memory)
    {
        require(bonds[_bondId].principalAmount > 0, "Bond does not exist");
        return bonds[_bondId];
    }

     /**
     * @dev Retrieves the entanglement details for a bond.
     * @param _bondId The ID of the bond.
     * @return entangledBondId, effect, effectParameters (or default values if not entangled)
     */
    function getEntanglementDetails(uint256 _bondId)
        external
        view
        returns (uint256, EntanglementEffectType, int256[] memory)
    {
         require(bonds[_bondId].principalAmount > 0, "Bond does not exist");
         uint256 partnerBondId = _entangledBondLink[_bondId];
         if (partnerBondId == 0) {
             return (0, EntanglementEffectType.NONE, new int256[](0));
         }

         // The bond that initiated the entanglement stores the effect details.
         // We need to determine which bond (this one or its partner) is the initiator.
         uint256 initiatorBondId = _bondId;
         uint256 targetBondId = partnerBondId;

         // If the partner bond's link points back to us, we are the initiator
         if (_entangledBondLink[partnerBondId] == _bondId) {
             // We are the initiator
             return (partnerBondId, bonds[_bondId].effect, bonds[_bondId].effectParameters);
         } else {
             // The partner is the initiator, we need to fetch its details
             // NOTE: This cross-lookup assumes Bond A initiated with Bond B.
             // If entanglement was symmetric, this would be simpler.
             // With our current asymmetric design (A initiates, B accepts, A stores details),
             // if querying Bond B, we need to look up Bond A's details.
             // A simpler (but potentially less efficient) approach: always store symmetric EntanglementDetails on both sides.
             // Let's stick to the A-initiates/A-stores model for now.
             // If this query is for bond B, find bond A.
             // There isn't a direct lookup from target back to initiator in our current link mapping.
             // The _entangledBondLink[_bondId] gives the partner. We need to check if *that partner* has _bondId as its link.
             // This requires reading the partner bond's _entangledBondLink.

             uint256 partnerOfPartner = _entangledBondLink[partnerBondId];
             if (partnerOfPartner == _bondId) {
                  // Yes, partner points back to us. We are the initiator. Data is on us.
                  return (partnerBondId, bonds[_bondId].effect, bonds[_bondId].effectParameters);
             } else {
                 // The partner is the initiator. The effect details are on the partner's struct.
                 // Return the partner's details.
                  return (partnerBondId, bonds[partnerBondId].effect, bonds[partnerBondId].effectParameters);
             }

         }
    }


    /**
     * @dev Retrieves the details of a pending entanglement proposal for a specific target bond.
     * @param _bondIdB The ID of the target bond.
     * @return bondIdA, proposer, bondIdB, effectType, proposalTimestamp (or default if no proposal)
     */
    function getPendingEntanglements(uint256 _bondIdB)
        external
        view
        returns (uint256, address, uint256, EntanglementEffectType, uint64)
    {
        EntanglementProposal memory proposal = _pendingEntanglements[_bondIdB];
        return (
            proposal.bondIdA,
            proposal.proposer,
            proposal.bondIdB,
            proposal.effectType,
            proposal.proposalTimestamp
        );
    }


    /**
     * @dev Gets the total principal amount currently locked in active bonds.
     * Iterates through all owned tokens (bonds). Could be gas-intensive for many bonds.
     * @return totalPrincipal The sum of principal amounts for all existing bonds.
     */
    function getTotalPrincipalIssued() external view returns (uint256) {
        uint256 totalPrincipal = 0;
        uint256 tokenCount = totalSupply();
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 bondId = tokenByIndex(i);
            totalPrincipal += bonds[bondId].principalAmount;
        }
        return totalPrincipal;
    }

     /**
     * @dev Gets the total balance of the primary yield payment token held by the contract.
     * Represents the pool available for redemptions and yield claims.
     * @return totalBalance The balance of yieldPaymentToken.
     */
    function getTotalContractBalance() external view returns (uint256) {
        return IERC20(yieldPaymentToken).balanceOf(address(this));
    }


    // --- Overrides and Internal ERC721 functions ---

    // Required overrides for ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Optional: Break entanglement on transfer? Or only if transferring outside original pair owners?
        // For simplicity, let's not automatically break entanglement on transfer in this version.
        // A more complex version might add rules like "entangled bonds must be transferred together" or "transfer breaks entanglement".
    }

    // The following functions are standard ERC721/ERC721Enumerable/Ownable/Pausable functions
    // and are included via inheritance. They contribute to the total function count
    // but are not detailed in the custom summary above as they are standard implementations.
    // - approve
    // - getApproved
    // - setApprovalForAll
    // - isApprovedForAll
    // - transferFrom
    // - safeTransferFrom (ERC721)
    // - balanceOf
    // - ownerOf
    // - supportsInterface
    // - tokenOfOwnerByIndex (ERC721Enumerable)
    // - tokenByIndex (ERC721Enumerable)
    // - totalSupply (ERC721Enumerable)
    // - owner (Ownable)
    // - renounceOwnership (Ownable)
    // - transferOwnership (Ownable)
    // - paused (Pausable)


    // Add any other necessary helper functions or internal logic below.
    // Ensure all paths that update a bond's state call `_accumulateYield` first.

    // Example: A function to get parameters for a specific effect type
     function getEntanglementEffectParameters(EntanglementEffectType _effectType)
         external
         view
         returns (int256[] memory)
     {
         return entanglementEffectParams[_effectType];
     }

    // Total custom functions implemented beyond basic ERC721/Ownable/Pausable/ReentrancyGuard:
    // 1. constructor (custom init)
    // 2. issueBond
    // 3. redeemBond
    // 4. claimYield
    // 5. calculateAccumulatedYield (View)
    // 6. getCurrentEffectiveYieldRate (View)
    // 7. updateBaseYieldRate (Admin)
    // 8. setOracleAddress (Admin)
    // 9. fetchAndApplyOracleData
    // 10. simulateExternalYieldSource (Admin)
    // 11. proposeEntanglement
    // 12. acceptEntanglement
    // 13. disentangle
    // 14. getEntanglementDetails (View)
    // 15. getPendingEntanglements (View)
    // 16. removePendingEntanglement
    // 17. setAllowedEntanglementEffect (Admin)
    // 18. updateEntanglementEffectParameters (Admin)
    // 19. pause (Admin override, but part of custom logic flow)
    // 20. unpause (Admin override, but part of custom logic flow)
    // 21. rescueFunds (Admin)
    // 22. getBondDetails (View)
    // 23. getTotalPrincipalIssued (View)
    // 24. getTotalContractBalance (View)
    // 25. getEntanglementEffectParameters (View)

    // This gives 25 custom functions, exceeding the requirement of 20.
}
```

---

**Explanation of Concepts and Design Choices:**

1.  **ERC721 NFT for Bonds:** Each bond is a unique digital asset. This allows individual bonds to have different parameters (principal, maturity) and, importantly, to be entangled uniquely. They can be owned, transferred, and potentially listed on NFT marketplaces.
2.  **Dynamic Yield:** The yield is not fixed. It changes based on:
    *   A `baseYieldRateBps` set by the contract owner (simulating protocol-level interest policy).
    *   `currentOracleData` fetched from an external oracle (simulating market data, real-world events, or other protocol health metrics influencing yield).
    *   `EntanglementEffectType.YIELD_RATE_CORRELATION`: An entanglement effect that directly modifies the bond's *current* yield rate based on parameters.
3.  **Accumulated Yield:** Yield is calculated and added to `accumulatedYield` over time. The `_accumulateYield` internal function ensures the yield is up-to-date before claiming or redeeming. It uses `lastYieldUpdateTimestamp` to track time elapsed.
4.  **Entanglement:** This is the core novel concept.
    *   Two bonds can be linked (`entangledBondId`).
    *   An `EntanglementEffectType` and associated `effectParameters` are stored on the *initiating* bond's struct. This determines *what happens* when specific events occur (like claiming yield or redeeming) involving either of the entangled bonds.
    *   `proposeEntanglement` / `acceptEntanglement`: A two-step process for entanglement requires consent from both bond owners.
    *   `disentangle`: Allows breaking the link.
    *   `_applyRedemptionEntanglementEffect`: An internal function called during `redeemBond`. It checks if the bond being redeemed has an effect defined that applies to itself upon redemption (e.g., principal bonus/penalty).
    *   `_applyYieldClaimEntanglementEffect`: An internal function called *after* `claimYield`. It checks if the bond whose yield was claimed has an effect defined that applies to its *entangled partner* (e.g., giving the partner a yield boost/penalty).
    *   `getCurrentEffectiveYieldRate`: This view function *also* checks for entanglement effects that directly modify the yield rate itself (`YIELD_RATE_CORRELATION`).
5.  **Asymmetric Entanglement State Storage:** In this design, the bond that *initiates* the entanglement proposal (`bondIdA` in `proposeEntanglement`) stores the `effect` and `effectParameters`. The target bond (`bondIdB`) only stores the `entangledBondId` linking back to `bondIdA`. This slightly complicates lookups (`getEntanglementDetails`) as you need to figure out which bond is the initiator, but simplifies storage by not duplicating effect details on both sides. Effects like `YIELD_BOOST_OTHER` are stored on bond A but *applied* to bond B.
6.  **Oracle Integration:** A simplified `ISimplifiedOracle` interface is used. `fetchAndApplyOracleData` would be called periodically by an off-chain service (keeper) to update `currentOracleData`, which then influences the yield rate calculation.
7.  **Yield Payment Token:** The contract uses a specific ERC20 token (`yieldPaymentToken`) for all principal payments and yield payouts. The `issueBond` function requires users to transfer this token. The contract must hold enough balance of this token (via principal payments and `simulateExternalYieldSource`) to fulfill redemptions and yield claims.
8.  **Admin Controls:** `Ownable` provides admin functions to set core parameters (base yield rate, oracle address, allowed entanglement effects/parameters) and pause/unpause the contract for maintenance.
9.  **ReentrancyGuard:** Used on critical functions like `redeemBond` and `claimYield` to prevent reentrancy attacks, especially important when transferring tokens.
10. **Pausable:** Allows pausing key functions during upgrades or emergencies.
11. **`simulateExternalYieldSource`:** This is a crucial placeholder. In a real DeFi protocol, the contract's balance would increase because the principal is put to work (e.g., lent out, used in yield farming). This function represents that inflow of generated yield, allowing the contract to pay out more than just the initial principal.

This contract provides a foundation for a complex, interactive bond system where the performance and features of individual bonds are dynamically linked and influenced by external data and their relationship with other bonds.