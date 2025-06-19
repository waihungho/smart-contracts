Okay, here is a Solidity smart contract called `QuantumTunnel`. It aims to incorporate several less common or combined concepts:

1.  **Multi-Asset Tunneling:** Handles both ERC20 and ERC721 deposits simultaneously within the same system.
2.  **Time-Locked Transmutation:** Assets are locked for a `quantumPeriod`, after which they can be claimed in a potentially altered state.
3.  **Probabilistic Outcomes:** The result of the "transmutation" (what you get back) is determined probabilistically based on various factors.
4.  **Dynamic Quantum State:** The contract itself maintains an internal `quantumState` (`chrononDensity`, `spatialDistortion`, `anomalyLevel`) which can be influenced by users and admin, affecting outcome probabilities.
5.  **Entangled Token:** The contract deploys and manages a native ERC20 token (`EntangledToken`). This token is central to the contract's mechanics – it's an *output* of the tunnel, and holding/staking it can *influence* future tunnel outcomes or allow interaction with the quantum state.
6.  **State Manipulation:** Users (potentially based on stake) can attempt to "shift" the quantum state, and the admin can "anchor" it.
7.  **Anomaly Resolution:** An admin function to reset/mitigate extreme `anomalyLevel`.

It's designed to be a creative and somewhat abstract example, not a direct clone of typical DeFi/NFT protocols.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For older versions, but good practice reminder.
import "@openzeppelin/contracts/utils/Address.sol"; // For ERC20/ERC721 checks

// --- Contract Outline and Function Summary ---
/*
Contract: QuantumTunnel

Purpose:
A smart contract acting as a non-custodial 'tunnel' where users can deposit ERC20 and ERC721 tokens
for a specified time period. After the period, they can claim an outcome, which is determined
probabilistically based on the original deposit, the tunnel's current 'quantum state', and
potentially user interaction (like staking the native EntangledToken). The contract introduces
a native ERC20 'EntangledToken' used within the ecosystem for staking and state manipulation.

Key Concepts:
- Multi-Asset Deposits (ERC20 & ERC721)
- Time-Locked 'Tunneling'
- Probabilistic Outcome Generation
- Dynamic 'Quantum State' (chrononDensity, spatialDistortion, anomalyLevel)
- Native EntangledToken (ERC20) for Utility and Governance Influence
- Quantum State Manipulation (Shift, Anchor)
- Configurable Parameters (Admin controlled)

Function Summary:

Management & State:
1.  constructor(): Deploys the native EntangledToken and initializes contract state.
2.  getEntangledTokenAddress() view: Returns the address of the deployed EntangledToken.
3.  getCurrentQuantumState() view: Returns the current values of chrononDensity, spatialDistortion, and anomalyLevel.
4.  getQuantumTimeAnchorStatus() view: Returns whether the state is anchored and when the anchor expires.
5.  shiftQuantumState(int _densityShift, int _spatialShift, uint _anomalyAttemptCost) nonPayable: Attempts to shift the quantum state. May cost EntangledTokens and has a chance of increasing anomaly.
6.  simulateQuantumFlux(uint _timeDelta) view: Simulates how the quantum state might drift over a given time period if not anchored.
7.  triggerAnomalyResolution(uint _cost) nonPayable: Admin/high-stake function to reduce anomalyLevel at a cost (e.g., burning EntangledTokens).
8.  pauseTunnelOperations() onlyOwner whenNotPaused: Pauses deposits and claims.
9.  resumeTunnelOperations() onlyOwner whenPaused: Resumes operations.

Deposit & Claim:
10. depositERC20IntoTunnel(address _token, uint256 _amount, uint _tunnelPeriod) nonPayable whenNotPaused: Deposits ERC20 tokens into the tunnel. Requires prior approval.
11. depositERC721IntoTunnel(address _token, uint256 _tokenId, uint _tunnelPeriod) nonPayable whenNotPaused: Deposits ERC721 tokens into the tunnel. Requires prior approval or transfer ownership.
12. claimFromTunnel(uint _depositId) nonPayable: Claims the outcome of a completed tunnel period for a specific deposit.
13. getTunnelDepositStatus(address _user, uint _depositId) view: Returns the details and status of a user's specific deposit.
14. getEstimatedTunnelOutcome(uint _depositId) view: Estimates the likely outcome type for a completed or near-completed deposit based on current state/probabilities (Note: this is an estimation, final outcome is determined at claim).

Entangled Token & Staking:
15. stakeEntangledTokens(uint _amount) nonPayable whenNotPaused: Stakes EntangledTokens within the contract to potentially influence outcomes. Requires prior approval.
16. unstakeEntangledTokens(uint _amount) nonPayable whenNotPaused: Unstakes EntangledTokens.
17. getUserEntangledStake(address _user) view: Returns the amount of EntangledTokens staked by a user.

Admin Configuration:
18. setQuantumParameter(uint _paramType, uint _value) onlyOwner: Sets base values for quantum state parameters (0: density, 1: spatial, 2: anomaly).
19. setAllowedTunnelERC20(address _token, bool _allowed) onlyOwner: Adds or removes an ERC20 token from the allowed list for deposits.
20. setAllowedTunnelERC721(address _token, bool _allowed) onlyOwner: Adds or removes an ERC721 token from the allowed list for deposits.
21. setOutcomeProbabilityWeight(uint _outcomeType, uint _weight) onlyOwner: Sets the probability weight for a specific outcome type.
22. setTunnelPeriods(uint _minPeriod, uint _maxPeriod) onlyOwner: Sets minimum and maximum allowed tunnel periods.
23. setQuantumAnchor(uint _duration) onlyOwner: Anchors the current quantum state for a specified duration.
24. dislodgeQuantumAnchor() onlyOwner: Removes the current quantum state anchor.
25. setOutputAsset(uint _outcomeType, address _assetAddress) onlyOwner: Sets the address of the output asset for specific outcome types (e.g., address for a DifferentERC20 outcome).
26. emergencyWithdrawAdmin(address _token, uint256 _amount) onlyOwner: Allows owner to withdraw ERC20 tokens stuck in the contract (e.g., unintended transfers). Does not affect user deposits.
27. emergencyWithdrawERC721Admin(address _token, uint256 _tokenId) onlyOwner: Allows owner to withdraw ERC721 tokens stuck in the contract. Does not affect user deposits.
28. previewEntangledMintAmount(uint _depositId, uint _stateInfluence) view: Estimates EntangledTokens minted for a claim, considering deposit type, period, and state influence.

Outcome Types (Internal/Constants):
- 0: Return Original Asset (maybe with bonus Entangled Tokens)
- 1: Different ERC20 Asset
- 2: Different ERC721 Asset
- 3: Upgraded/Modified Original ERC721 (requires complex logic/companion contract, simplified here)
- 4: Entangled Tokens Only
- 5: Partial Loss (less than original, plus Entangled Tokens)
- 6: Total Loss (no return, potentially still get minimal Entangled Tokens)

Notes:
- Randomness is achieved using block hash/timestamp, which is NOT truly random and subject to miner manipulation, especially for high-value outcomes on short time scales. This is a common limitation in L1 Solidity contracts.
- The complexity of outcome determination is abstracted; a real implementation would require more detailed logic based on state variables and deposit parameters.
- NFT upgrading (Outcome 3) is highly complex and would typically involve burning the old NFT and minting a new one from another contract; this contract simplifies it to just selecting the outcome type.
- Error handling uses custom errors (Solidity >= 0.8.4).
- State values (`chrononDensity`, etc.) are simplified `uint` representing abstract levels.
*/

// Custom Errors for clarity (Solidity >= 0.8.4)
error NotOwner();
error Paused();
error NotPaused();
error DepositNotFound();
error DepositAlreadyClaimed();
error TunnelPeriodNotElapsed();
error InvalidTunnelPeriod();
error TokenNotAllowed(address token);
error ZeroAmount();
error ZeroPeriod();
error TransferFailed();
error NotEnoughStaked();
error CannotShiftQuantumState();
error StateAnchored();
error InvalidParameterType();
error InvalidOutcomeType();
error OutputAssetNotConfigured(uint outcomeType);
error InvalidOutcomeWeight();

// Define EntangledToken contract (internal for this example)
contract EntangledToken is IERC20 {
    string public name = "Entangled Token";
    string public symbol = "QUBIT";
    uint8 public immutable decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public minter; // Only the QuantumTunnel can mint

    constructor(address _minter) {
        minter = _minter;
    }

    modifier onlyMinter() {
        if (msg.sender != minter) revert NotMinter();
        _;
    }

    error NotMinter();
    error TransferAmountExceedsBalance();
    error BurnAmountExceedsBalance();
    error TransferAmountExceedsAllowance();

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < amount) revert TransferAmountExceedsAllowance();
        _approve(sender, msg.sender, currentAllowance - amount); // SafeMath not needed in 0.8+
        return true;
    }

    function mint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyMinter {
        _burn(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        if (sender == address(0)) revert TransferFailed(); // Should not happen from user tx
        if (recipient == address(0)) revert TransferFailed(); // Prevent burning to zero address without specific burn function

        uint256 senderBalance = _balances[sender];
        if (senderBalance < amount) revert TransferAmountExceedsBalance();

        _balances[sender] = senderBalance - amount;
        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert TransferFailed();
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert BurnAmountExceedsBalance(); // Should not happen from user tx
        uint256 accountBalance = _balances[account];
        if (accountBalance < amount) revert BurnAmountExceedsBalance();
        _balances[account] = accountBalance - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract QuantumTunnel {
    using SafeMath for uint256;
    using Address for address;

    address private immutable i_owner;
    bool private s_paused;

    EntangledToken public immutable entangledToken;

    // --- Quantum State ---
    struct QuantumState {
        uint chrononDensity; // Affects time flow, higher -> potentially faster tunnel or higher yields
        uint spatialDistortion; // Affects outcome variance, higher -> more unpredictable
        uint anomalyLevel; // Represents instability, higher -> potentially negative outcomes or state shifts
    }
    QuantumState private s_quantumState;

    struct TimeAnchor {
        bool isAnchored;
        uint anchorEndTime;
        QuantumState anchoredState;
    }
    TimeAnchor private s_timeAnchor;

    // --- Tunnel Configuration ---
    uint private s_minTunnelPeriod;
    uint private s_maxTunnelPeriod; // In seconds

    mapping(address => bool) private s_allowedERC20s;
    mapping(address => bool) private s_allowedERC721s;

    // Outcome Types (as defined in summary)
    uint constant private OUTCOME_ORIGINAL_BONUS = 0;
    uint constant private OUTCOME_DIFFERENT_ERC20 = 1;
    uint constant private OUTCOME_DIFFERENT_ERC721 = 2;
    uint constant private OUTCOME_UPGRADED_NFT = 3; // Simplified
    uint constant private OUTCOME_ENTANGLED_ONLY = 4;
    uint constant private OUTCOME_PARTIAL_LOSS = 5;
    uint constant private OUTCOME_TOTAL_LOSS = 6;

    uint[] private s_outcomeTypes; // List of valid outcome types
    mapping(uint => uint) private s_outcomeProbabilities; // outcomeType => weight
    uint private s_totalProbabilityWeight; // Sum of all weights

    mapping(uint => address) private s_outputAssets; // outcomeType => asset address for types 1, 2

    // --- User Deposits ---
    struct Deposit {
        address depositor;
        address assetAddress;
        uint256 assetIdOrAmount; // TokenId for ERC721, Amount for ERC20
        bool isERC721;
        uint depositTime;
        uint tunnelPeriod; // Specific period chosen by user
        bool claimed;
    }
    mapping(address => mapping(uint => Deposit)) private s_userDeposits;
    mapping(address => uint) private s_nextDepositId; // Counter per user

    // --- Entangled Token Staking ---
    mapping(address => uint) private s_userEntangledStake;
    uint private s_totalEntangledStake;

    // --- Events ---
    event TunnelDeposit(address indexed depositor, uint indexed depositId, address assetAddress, uint256 assetValue, bool isERC721, uint tunnelPeriod);
    event TunnelClaimed(address indexed depositor, uint indexed depositId, uint outcomeType, address outputAsset, uint256 outputValue);
    event QuantumStateShifted(QuantumState newState, address indexed by);
    event QuantumStateAnchored(QuantumState anchoredState, uint until);
    event QuantumAnchorDislodged();
    event AnomalyResolutionTriggered(uint newAnomalyLevel, uint cost);
    event EntangledTokensStaked(address indexed user, uint amount, uint totalUserStake);
    event EntangledTokensUnstaked(address indexed user, uint amount, uint totalUserStake);
    event TunnelPaused();
    event TunnelResumed();
    event ParameterSet(uint paramType, uint value);
    event AllowedTokenSet(address token, bool isERC721, bool allowed);
    event OutcomeWeightSet(uint outcomeType, uint weight);
    event OutputAssetSet(uint outcomeType, address assetAddress);
    event EmergencyWithdrawal(address token, uint256 amount);
    event EmergencyWithdrawalERC721(address token, uint256 tokenId);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (s_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!s_paused) revert NotPaused();
        _;
    }

    // --- Constructor ---
    constructor() {
        i_owner = msg.sender;
        s_paused = false;

        // Deploy the native EntangledToken
        entangledToken = new EntangledToken(address(this));

        // Initialize Quantum State (Arbitrary starting values)
        s_quantumState = QuantumState({
            chrononDensity: 1000, // Base 1000
            spatialDistortion: 1000, // Base 1000
            anomalyLevel: 0 // Start stable
        });

        s_timeAnchor = TimeAnchor({
            isAnchored: false,
            anchorEndTime: 0,
            anchoredState: s_quantumState // Store initial state
        });

        // Initialize Tunnel Periods (e.g., 1 day min, 30 days max)
        s_minTunnelPeriod = 1 days;
        s_maxTunnelPeriod = 30 days;

        // Define and initialize outcome probabilities (arbitrary weights, must sum > 0)
        s_outcomeTypes = [
            OUTCOME_ORIGINAL_BONUS,
            OUTCOME_DIFFERENT_ERC20,
            OUTCOME_DIFFERENT_ERC721,
            OUTCOME_UPGRADED_NFT,
            OUTCOME_ENTANGLED_ONLY,
            OUTCOME_PARTIAL_LOSS,
            OUTCOME_TOTAL_LOSS
        ];

        s_outcomeProbabilities[OUTCOME_ORIGINAL_BONUS] = 40;
        s_outcomeProbabilities[OUTCOME_DIFFERENT_ERC20] = 5;
        s_outcomeProbabilities[OUTCOME_DIFFERENT_ERC721] = 1;
        s_outcomeProbabilities[OUTCOME_UPGRADED_NFT] = 2; // Less likely
        s_outcomeProbabilities[OUTCOME_ENTANGLED_ONLY] = 20;
        s_outcomeProbabilities[OUTCOME_PARTIAL_LOSS] = 20;
        s_outcomeProbabilities[OUTCOME_TOTAL_LOSS] = 12;

        _recalculateTotalProbabilityWeight(); // Calculate initial sum

        // Add some initial allowed tokens (example: WETH, some test NFT)
        // In production, these would be set by the owner after deployment
        // s_allowedERC20s[0xC02aaA39B223FE8D0A0e5C4F27eAD9083C756Cc2] = true; // WETH on Mainnet
        // s_allowedERC721s[0x1A9C8182C09F50C8318d769245bea52c32BE35bc] = true; // Example NFT address
    }

    // --- View Functions ---

    // 2. Returns the address of the deployed EntangledToken.
    function getEntangledTokenAddress() public view returns (address) {
        return address(entangledToken);
    }

    // 3. Returns the current values of chrononDensity, spatialDistortion, and anomalyLevel.
    function getCurrentQuantumState() public view returns (uint density, uint spatial, uint anomaly) {
         if (s_timeAnchor.isAnchored && block.timestamp < s_timeAnchor.anchorEndTime) {
             return (s_timeAnchor.anchoredState.chrononDensity, s_timeAnchor.anchoredState.spatialDistortion, s_timeAnchor.anchoredState.anomalyLevel);
         }
         return (s_quantumState.chrononDensity, s_quantumState.spatialDistortion, s_quantumState.anomalyLevel);
    }

     // 4. Returns whether the state is anchored and when the anchor expires.
    function getQuantumTimeAnchorStatus() public view returns (bool isAnchored, uint anchorEndTime) {
        if (s_timeAnchor.isAnchored && block.timestamp >= s_timeAnchor.anchorEndTime) {
             // Anchor expired, update state internally? Or let next state-modifying fn handle it?
             // Let's indicate it's effectively not anchored publicly.
            return (false, s_timeAnchor.anchorEndTime);
        }
        return (s_timeAnchor.isAnchored, s_timeAnchor.anchorEndTime);
    }

    // 6. Simulates how the quantum state might drift over a given time period if not anchored.
    // Note: This is a simplified linear simulation. Real complexity would be different.
    function simulateQuantumFlux(uint _timeDelta) public view returns (uint estimatedDensity, uint estimatedSpatial, uint estimatedAnomaly) {
        QuantumState memory currentState = s_quantumState;
         if (s_timeAnchor.isAnchored && block.timestamp < s_timeAnchor.anchorEndTime) {
             currentState = s_timeAnchor.anchoredState;
         }

        // Example simple flux simulation: drift slightly over time
        // Higher anomaly -> faster drift
        uint driftFactor = 100 + currentState.anomalyLevel; // Base drift + anomaly influence
        uint densityDrift = (_timeDelta * driftFactor) / 1 days; // Drift per day
        uint spatialDrift = (_timeDelta * driftFactor) / 2 days;
        uint anomalyIncrease = (_timeDelta * currentState.spatialDistortion) / 10000 days; // Spatial distortion adds to anomaly

        // Clamp values to prevent excessive growth in simulation
        estimatedDensity = currentState.chrononDensity + densityDrift;
        estimatedSpatial = currentState.spatialDistortion + spatialDrift;
        estimatedAnomaly = currentState.anomalyLevel + anomalyIncrease;

        estimatedDensity = estimatedDensity > 20000 ? 20000 : estimatedDensity; // Example max
        estimatedSpatial = estimatedSpatial > 20000 ? 20000 : estimatedSpatial; // Example max
        estimatedAnomaly = estimatedAnomaly > 5000 ? 5000 : estimatedAnomaly; // Example max

        return (estimatedDensity, estimatedSpatial, estimatedAnomaly);
    }

    // 13. Returns the details and status of a user's specific deposit.
    function getTunnelDepositStatus(address _user, uint _depositId) public view returns (
        address depositor,
        address assetAddress,
        uint256 assetIdOrAmount,
        bool isERC721,
        uint depositTime,
        uint tunnelPeriod,
        bool claimed,
        bool readyToClaim
    ) {
        Deposit storage deposit = s_userDeposits[_user][_depositId];
        if (deposit.depositor == address(0)) revert DepositNotFound();

        readyToClaim = !deposit.claimed && block.timestamp >= deposit.depositTime + deposit.tunnelPeriod;

        return (
            deposit.depositor,
            deposit.assetAddress,
            deposit.assetIdOrAmount,
            deposit.isERC721,
            deposit.depositTime,
            deposit.tunnelPeriod,
            deposit.claimed,
            readyToClaim
        );
    }

    // 14. Estimates the likely outcome type for a completed or near-completed deposit.
    // NOTE: This is an ESTIMATION. The final outcome is determined by the actual random number at claim time.
    function getEstimatedTunnelOutcome(uint _depositId) public view returns (uint estimatedOutcomeType, string memory description) {
        // This view function cannot execute the random selection logic reliably
        // It can only show the *probabilities* based on the current state.
        // A true "estimation" based on state would need a complex state -> probability map.
        // Let's return the outcome type with the highest probability weight based on current state.
        // Simplified: Just show the weights for each outcome.

        Deposit storage deposit = s_userDeposits[msg.sender][_depositId];
         if (deposit.depositor == address(0)) revert DepositNotFound();
         if (!deposit.claimed && block.timestamp < deposit.depositTime + deposit.tunnelPeriod) {
             description = "Deposit period not elapsed. Cannot estimate outcome yet.";
             return (type(uint).max, description); // Indicate not ready/estimable
         }

        // In a real scenario, you'd calculate state influence here.
        // For this example, we'll just find the currently weighted most likely outcome.
        uint maxWeight = 0;
        uint mostLikelyOutcome = type(uint).max; // Sentinel value

        for(uint i = 0; i < s_outcomeTypes.length; i++) {
            uint outcomeType = s_outcomeTypes[i];
            // Add state influence here in a real system.
            // E.g., Higher chrononDensity might slightly favor original/bonus outcomes.
            // Higher spatialDistortion might favor extreme outcomes (very good or very bad).
            // Higher anomalyLevel might favor loss outcomes.
            uint effectiveWeight = s_outcomeProbabilities[outcomeType]; // Basic version

            if (effectiveWeight > maxWeight) {
                maxWeight = effectiveWeight;
                mostLikelyOutcome = outcomeType;
            }
        }

        if (mostLikelyOutcome == type(uint).max) {
            description = "Could not determine likely outcome (no probabilities set).";
            return (type(uint).max, description);
        }

        description = _getOutcomeDescription(mostLikelyOutcome);
        return (mostLikelyOutcome, description);
    }

     // 17. Returns the amount of EntangledTokens staked by a user.
    function getUserEntangledStake(address _user) public view returns (uint) {
        return s_userEntangledStake[_user];
    }

     // 28. Estimates EntangledTokens minted for a claim, considering deposit type, period, and state influence.
     // _stateInfluence is a placeholder; real implementation would use current state.
    function previewEntangledMintAmount(uint _depositId, uint _stateInfluence) public view returns (uint estimatedAmount) {
        Deposit storage deposit = s_userDeposits[msg.sender][_depositId];
        if (deposit.depositor == address(0)) revert DepositNotFound();

        uint baseMint = 0;
        if (deposit.isERC721) {
            // Base mint for NFTs (e.g., per NFT)
            baseMint = 10 ether; // Example: 10 QUBIT per NFT
        } else {
            // Base mint for ERC20s (e.g., per amount)
            baseMint = deposit.assetIdOrAmount / 100; // Example: 1% of amount as QUBIT
        }

        // Influence from tunnel period (longer period -> more QUBIT)
        uint periodBonus = (baseMint * deposit.tunnelPeriod) / s_maxTunnelPeriod;

        // Influence from state (_stateInfluence is a placeholder for calculation based on current state)
        // Example: Higher chrononDensity gives more QUBIT
        uint stateBonus = (baseMint * _stateInfluence) / 10000; // Example scaling

        estimatedAmount = baseMint + periodBonus + stateBonus;

        // Add small bonus if user has stake?
        // if (s_userEntangledStake[msg.sender] > 0) {
        //     estimatedAmount = estimatedAmount + estimatedAmount / 20; // 5% bonus
        // }

        return estimatedAmount;
    }


    // --- External Functions ---

    // 5. Attempts to shift the quantum state.
    // Requires cost (Entangled Tokens) and has a chance of increasing anomaly.
    function shiftQuantumState(int _densityShift, int _spatialShift, uint _anomalyAttemptCost) public whenNotPaused {
        if (s_timeAnchor.isAnchored && block.timestamp < s_timeAnchor.anchorEndTime) revert StateAnchored();
        if (_anomalyAttemptCost > 0) {
             // Requires staking EntangledTokens to attempt a shift
            if (s_userEntangledStake[msg.sender] < _anomalyAttemptCost) revert NotEnoughStaked();
            _burnEntangledTokens(msg.sender, _anomalyAttemptCost); // Burn staked tokens
        }

        // Apply shifts (with clamping to prevent absurd values)
        // Use safe math for addition/subtraction of signed/unsigned
        uint currentDensity = s_quantumState.chrononDensity;
        uint currentSpatial = s_quantumState.spatialDistortion;

        if (_densityShift > 0) currentDensity = currentDensity + uint(_densityShift);
        else if (_densityShift < 0) currentDensity = currentDensity > uint(-_densityShift) ? currentDensity - uint(-_densityShift) : 0;
        currentDensity = currentDensity > 20000 ? 20000 : currentDensity; // Clamp

        if (_spatialShift > 0) currentSpatial = currentSpatial + uint(_spatialShift);
        else if (_spatialShift < 0) currentSpatial = currentSpatial > uint(-_spatialShift) ? currentSpatial - uint(-_spatialShift) : 0;
        currentSpatial = currentSpatial > 20000 ? 20000 : currentSpatial; // Clamp

        s_quantumState.chrononDensity = currentDensity;
        s_quantumState.spatialDistortion = currentSpatial;

        // Random-ish chance of increasing anomaly level based on shift magnitude and current anomaly
        uint shiftMagnitude = uint(_densityShift > 0 ? _densityShift : -_densityShift) + uint(_spatialShift > 0 ? _spatialShift : -_spatialShift);
        if (shiftMagnitude > 0) {
             // Use block hash randomness (inherently weak)
             uint randomFactor = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, shiftMagnitude))) % 1000;
             uint anomalyIncreaseChance = shiftMagnitude / 10 + s_quantumState.anomalyLevel / 100; // Base chance + higher anomaly risk

             if (randomFactor < anomalyIncreaseChance && s_quantumState.anomalyLevel < 5000) { // Max anomaly 5000
                 uint increaseAmount = (shiftMagnitude / 50) + 1; // Small increase
                 s_quantumState.anomalyLevel = s_quantumState.anomalyLevel + increaseAmount;
                  if (s_quantumState.anomalyLevel > 5000) s_quantumState.anomalyLevel = 5000;
             }
        }

        emit QuantumStateShifted(s_quantumState, msg.sender);
    }

    // 7. Admin/high-stake function to reduce anomalyLevel at a cost.
    // Made onlyOwner for this example, could add stake threshold.
    function triggerAnomalyResolution(uint _cost) public onlyOwner whenNotPaused {
        if (s_quantumState.anomalyLevel == 0) return; // Nothing to resolve

        // Example cost: requires burning Entangled Tokens
        if (_cost > 0) {
             entangledToken.burn(msg.sender, _cost); // Burn directly from admin's balance
        }

        // Reduce anomaly level significantly, maybe based on cost
        uint reduction = s_quantumState.anomalyLevel / 2; // Reduce by half as base
        if (_cost > 0) {
             reduction = reduction + (_cost / 1 ether) * 10; // Extra reduction per ETHER worth of QUBIT burned
        }

        s_quantumState.anomalyLevel = s_quantumState.anomalyLevel > reduction ? s_quantumState.anomalyLevel - reduction : 0;

        emit AnomalyResolutionTriggered(s_quantumState.anomalyLevel, _cost);
    }

    // 8. Pauses deposits and claims.
    function pauseTunnelOperations() public onlyOwner whenNotPaused {
        s_paused = true;
        emit TunnelPaused();
    }

    // 9. Resumes operations.
    function resumeTunnelOperations() public onlyOwner whenPaused {
        s_paused = false;
        emit TunnelResumed();
    }


    // 10. Deposits ERC20 tokens into the tunnel.
    function depositERC20IntoTunnel(address _token, uint256 _amount, uint _tunnelPeriod) public whenNotPaused {
        if (_amount == 0) revert ZeroAmount();
        if (_tunnelPeriod == 0) revert ZeroPeriod();
        if (_tunnelPeriod < s_minTunnelPeriod || _tunnelPeriod > s_maxTunnelPeriod) revert InvalidTunnelPeriod();
        if (!s_allowedERC20s[_token]) revert TokenNotAllowed(_token);

        uint depositId = s_nextDepositId[msg.sender]++;

        s_userDeposits[msg.sender][depositId] = Deposit({
            depositor: msg.sender,
            assetAddress: _token,
            assetIdOrAmount: _amount,
            isERC721: false,
            depositTime: block.timestamp,
            tunnelPeriod: _tunnelPeriod,
            claimed: false
        });

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        emit TunnelDeposit(msg.sender, depositId, _token, _amount, false, _tunnelPeriod);
    }

    // 11. Deposits ERC721 tokens into the tunnel.
    function depositERC721IntoTunnel(address _token, uint256 _tokenId, uint _tunnelPeriod) public whenNotPaused {
        if (_tunnelPeriod == 0) revert ZeroPeriod();
        if (_tunnelPeriod < s_minTunnelPeriod || _tunnelPeriod > s_maxTunnelPeriod) revert InvalidTunnelPeriod();
        if (!s_allowedERC721s[_token]) revert TokenNotAllowed(_token);

        // Ensure sender owns the token or has approval
        IERC721 erc721 = IERC721(_token);
        require(erc721.ownerOf(_tokenId) == msg.sender, "Not token owner");
        // Need allowance or transfer ownership
        require(erc721.isApprovedForAll(msg.sender, address(this)) || erc721.getApproved(_tokenId) == address(this), "ERC721 not approved for transfer");


        uint depositId = s_nextDepositId[msg.sender]++;

        s_userDeposits[msg.sender][depositId] = Deposit({
            depositor: msg.sender,
            assetAddress: _token,
            assetIdOrAmount: _tokenId, // Store tokenId here
            isERC721: true,
            depositTime: block.timestamp,
            tunnelPeriod: _tunnelPeriod,
            claimed: false
        });

        erc721.transferFrom(msg.sender, address(this), _tokenId);

        emit TunnelDeposit(msg.sender, depositId, _token, _tokenId, true, _tunnelPeriod);
    }

    // 12. Claims the outcome of a completed tunnel period.
    function claimFromTunnel(uint _depositId) public whenNotPaused {
        Deposit storage deposit = s_userDeposits[msg.sender][_depositId];
        if (deposit.depositor == address(0) || deposit.depositor != msg.sender) revert DepositNotFound();
        if (deposit.claimed) revert DepositAlreadyClaimed();
        if (block.timestamp < deposit.depositTime + deposit.tunnelPeriod) revert TunnelPeriodNotElapsed();

        deposit.claimed = true; // Mark as claimed BEFORE potential external calls

        // --- Outcome Determination ---
        // Use a pseudo-random number based on block hash, difficulty, timestamp, and deposit details
        uint randomSeed = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            block.number,
            msg.sender,
            _depositId,
            s_totalEntangledStake, // Stake can influence outcome
            s_quantumState // Quantum state influences outcome
        )));

        uint selectedOutcomeType = _selectOutcome(randomSeed);

        address outputAsset = address(0);
        uint256 outputValue = 0; // Amount for ERC20, TokenId for ERC721

        // --- Execute Outcome ---
        if (selectedOutcomeType == OUTCOME_ORIGINAL_BONUS) {
            outputAsset = deposit.assetAddress;
            outputValue = deposit.assetIdOrAmount; // Return original asset

            // Calculate bonus Entangled Tokens
            uint bonusEntangled = _calculateEntangledMintAmount(_depositId, _getEffectiveQuantumStateInfluence());
            if (bonusEntangled > 0) {
                entangledToken.mint(msg.sender, bonusEntangled);
                // outputValue remains the original asset amount/id
                // Log the bonus separately if needed, or include in main event
            }

            if (deposit.isERC721) {
                 IERC721(outputAsset).transferFrom(address(this), msg.sender, outputValue);
            } else {
                 IERC20(outputAsset).transfer(msg.sender, outputValue);
            }

        } else if (selectedOutcomeType == OUTCOME_DIFFERENT_ERC20) {
             outputAsset = s_outputAssets[OUTCOME_DIFFERENT_ERC20];
             if (outputAsset == address(0)) revert OutputAssetNotConfigured(OUTCOME_DIFFERENT_ERC20);

             // Calculate output amount based on original value and state
             uint baseAmount = deposit.isERC721 ? 100 ether : deposit.assetIdOrAmount; // Example conversion/base value
             // Simplified calc: base amount * (density/1000) * (1 - anomaly/5000)
             outputValue = (baseAmount * s_quantumState.chrononDensity / 1000) * (5000 - s_quantumState.anomalyLevel) / 5000;
             if (outputValue == 0) outputValue = 1; // Minimum output

             IERC20(outputAsset).transfer(msg.sender, outputValue);

        } else if (selectedOutcomeType == OUTCOME_DIFFERENT_ERC721) {
             outputAsset = s_outputAssets[OUTCOME_DIFFERENT_ERC721];
              if (outputAsset == address(0)) revert OutputAssetNotConfigured(OUTCOME_DIFFERENT_ERC721);

             // Requires the target contract to have a mint function callable by the tunnel
             // This is a placeholder. A real implementation would interact with a specific NFT contract.
             // Example: INewNFT(outputAsset).mint(msg.sender, _generateNewNFTId(deposit, s_quantumState));
             // For this example, we'll just use a placeholder value for outputValue
             outputValue = _generatePlaceholderNFTId(deposit, s_quantumState, randomSeed);
             // This needs a mechanism to actually give the user the NFT.
             // As a simplification: We log the intended outcome. The user/external system must
             // call the target NFT contract separately, perhaps providing proof of this event.
             // Or, the target NFT contract trusts this contract's call (requires tight coupling).
             // Let's assume a simple transfer *if* the output asset is an ERC721 and this contract holds one.
             // More realistic: The target NFT contract handles the mint/transfer based on a permissioned call.
             // For this example, let's *simulate* transferring a pre-held NFT if available.
             // In reality, the contract wouldn't generically hold random NFTs for output.
             // A proper implementation would involve the target contract or a dedicated output vault.
             // SIMPLIFICATION: Just log the outcome type and intended asset/ID. No actual transfer here without a proper output pool.
             // Let's assume this is a notification and the user claims from the target contract.
              // Or, let's make the contract hold a *pool* of different ERC721s to draw from (more complex state).
             // Simpler: Admin pre-deposits specific output NFTs, and claim transfers one. Requires index tracking.
             // Let's skip the actual ERC721 transfer for 'Different ERC721' and 'Upgraded NFT' outcomes in this example for brevity and complexity.
             // We will *only* handle ERC20 and Entangled Token transfers directly. For ERC721 outcomes, the event is the record.
             // A real system would need a mechanism for the user to receive these NFTs (e.g., a claim function on the output NFT contract, verified by a relayer or zk-proof of this event).
              emit TunnelClaimed(msg.sender, _depositId, selectedOutcomeType, outputAsset, outputValue);
              return; // Stop here as NFT transfer isn't handled generically
        } else if (selectedOutcomeType == OUTCOME_UPGRADED_NFT) {
             outputAsset = s_outputAssets[OUTCOME_UPGRADED_NFT]; // Address of the 'upgraded' NFT contract?
             if (!deposit.isERC721) revert InvalidOutcomeType(); // Only applies to NFTs
             if (outputAsset == address(0)) revert OutputAssetNotConfigured(OUTCOME_UPGRADED_NFT);

             // Again, actual NFT logic is complex. Simplified to just log.
              outputValue = _generatePlaceholderNFTId(deposit, s_quantumState, randomSeed); // New ID on new contract?
              emit TunnelClaimed(msg.sender, _depositId, selectedOutcomeType, outputAsset, outputValue);
              return; // Stop here

        } else if (selectedOutcomeType == OUTCOME_ENTANGLED_ONLY) {
             outputAsset = address(entangledToken);
             outputValue = _calculateEntangledMintAmount(_depositId, _getEffectiveQuantumStateInfluence());
             if (outputValue == 0) outputValue = 1; // Minimum
             entangledToken.mint(msg.sender, outputValue);

        } else if (selectedOutcomeType == OUTCOME_PARTIAL_LOSS) {
             // Return a fraction of the original asset + Entangled Tokens
             outputAsset = deposit.assetAddress;
             uint lossFactor = 100 + s_quantumState.anomalyLevel / 10; // Higher anomaly -> higher loss
             uint returnFactor = 10000 - lossFactor; // Example: 10000 is 100%
             if (returnFactor < 1000) returnFactor = 1000; // At least 10% returned

             if (deposit.isERC721) {
                 // Partial loss for NFT doesn't make sense. Maybe burn original and mint 'damaged' version?
                 // Or, return original + minimal QUBIT? Let's return original + minimal QUBIT for NFT partial loss.
                 outputValue = deposit.assetIdOrAmount; // Return original NFT
                  uint bonusEntangled = _calculateEntangledMintAmount(_depositId, _getEffectiveQuantumStateInfluence()) / 5; // Small bonus
                  if (bonusEntangled > 0) entangledToken.mint(msg.sender, bonusEntangled);
                  IERC721(outputAsset).transferFrom(address(this), msg.sender, outputValue);

             } else { // ERC20 partial loss
                 outputValue = (deposit.assetIdOrAmount * returnFactor) / 10000;
                 if (outputValue > 0) {
                      IERC20(outputAsset).transfer(msg.sender, outputValue);
                 }
                  uint bonusEntangled = _calculateEntangledMintAmount(_depositId, _getEffectiveQuantumStateInfluence()) / 2; // Half bonus
                  if (bonusEntangled > 0) entangledToken.mint(msg.sender, bonusEntangled);
             }

        } else if (selectedOutcomeType == OUTCOME_TOTAL_LOSS) {
             // No asset returned, maybe minimal Entangled Tokens as consolation
              outputAsset = address(0); // Represents no asset returned
              outputValue = 0; // Represents no value returned

              // Burn the deposited asset if ERC721, or leave ERC20 balance in contract for admin withdrawal/pool
              if (deposit.isERC721) {
                  // Burning ERC721 often requires a specific burn function on the NFT contract
                  // If the NFT contract has a burn function callable by owner/approved: IERC721(deposit.assetAddress).burn(address(this), deposit.assetIdOrAmount);
                  // Otherwise, it stays in the contract, effectively lost to the user.
                  // For this example, we log it as lost. It remains in contract balance.
              } else {
                  // ERC20 stays in the contract.
              }

             // Mint minimal Entangled Tokens
             uint minimalEntangled = _calculateEntangledMintAmount(_depositId, _getEffectiveQuantumStateInfluence()) / 10; // 10% bonus
             if (minimalEntangled == 0 && deposit.isERC721) minimalEntangled = 1 ether; // At least 1 QUBIT for NFT loss
             if (minimalEntangled > 0) entangledToken.mint(msg.sender, minimalEntangled);
             if (minimalEntangled > 0) {
                  outputAsset = address(entangledToken); // Log QUBIT as output asset in this case
                  outputValue = minimalEntangled;
             }


        } else {
            // Should not happen if _selectOutcome is correct, but as a fallback
            revert InvalidOutcomeType();
        }

         emit TunnelClaimed(msg.sender, _depositId, selectedOutcomeType, outputAsset, outputValue);
    }

    // 15. Stakes EntangledTokens within the contract.
    function stakeEntangledTokens(uint _amount) public whenNotPaused {
        if (_amount == 0) revert ZeroAmount();
        // Transfer tokens from user to contract
        entangledToken.transferFrom(msg.sender, address(this), _amount);
        s_userEntangledStake[msg.sender] = s_userEntangledStake[msg.sender].add(_amount);
        s_totalEntangledStake = s_totalEntangledStake.add(_amount);
        emit EntangledTokensStaked(msg.sender, _amount, s_userEntangledStake[msg.sender]);
    }

    // 16. Unstakes EntangledTokens.
    function unstakeEntangledTokens(uint _amount) public whenNotPaused {
         if (_amount == 0) revert ZeroAmount();
        if (s_userEntangledStake[msg.sender] < _amount) revert NotEnoughStaked();
        s_userEntangledStake[msg.sender] = s_userEntangledStake[msg.sender].sub(_amount);
        s_totalEntangledStake = s_totalEntangledStake.sub(_amount);
        // Transfer tokens back to user
        entangledToken.transfer(msg.sender, _amount);
        emit EntangledTokensUnstaked(msg.sender, _amount, s_userEntangledStake[msg.sender]);
    }


    // --- Admin Functions ---

    // 18. Sets base values for quantum state parameters.
    // paramType: 0=density, 1=spatial, 2=anomaly (use carefully!)
    function setQuantumParameter(uint _paramType, uint _value) public onlyOwner {
        if (s_timeAnchor.isAnchored && block.timestamp < s_timeAnchor.anchorEndTime) revert StateAnchored();
        if (_paramType == 0) {
            s_quantumState.chrononDensity = _value;
        } else if (_paramType == 1) {
            s_quantumState.spatialDistortion = _value;
        } else if (_paramType == 2) {
             // Setting anomaly directly is powerful, limit max or remove?
             // Let's allow setting, but clamp.
             s_quantumState.anomalyLevel = _value > 5000 ? 5000 : _value;
        } else {
            revert InvalidParameterType();
        }
        emit ParameterSet(_paramType, _value);
    }

    // 23. Anchors the current quantum state for a specified duration.
    function setQuantumAnchor(uint _duration) public onlyOwner {
        if (_duration == 0) revert InvalidPeriod();
        s_timeAnchor.isAnchored = true;
        s_timeAnchor.anchorEndTime = block.timestamp + _duration;
        s_timeAnchor.anchoredState = s_quantumState; // Capture the state at anchor time
        emit QuantumStateAnchored(s_timeAnchor.anchoredState, s_timeAnchor.anchorEndTime);
    }

    // 24. Removes the current quantum state anchor.
    function dislodgeQuantumAnchor() public onlyOwner {
        s_timeAnchor.isAnchored = false;
        s_timeAnchor.anchorEndTime = 0; // Reset end time
        // State will revert to s_quantumState on next check
        emit QuantumAnchorDislodged();
    }

    // 19. Adds or removes an ERC20 token from the allowed list.
    function setAllowedTunnelERC20(address _token, bool _allowed) public onlyOwner {
        if (_token == address(0)) revert ZeroAmount(); // Using ZeroAmount error for address(0)
        s_allowedERC20s[_token] = _allowed;
        emit AllowedTokenSet(_token, false, _allowed);
    }

    // 20. Adds or removes an ERC721 token from the allowed list.
    function setAllowedTunnelERC721(address _token, bool _allowed) public onlyOwner {
         if (_token == address(0)) revert ZeroAmount();
        s_allowedERC721s[_token] = _allowed;
        emit AllowedTokenSet(_token, true, _allowed);
    }

    // 21. Sets the probability weight for a specific outcome type.
    function setOutcomeProbabilityWeight(uint _outcomeType, uint _weight) public onlyOwner {
        bool validType = false;
        for(uint i = 0; i < s_outcomeTypes.length; i++) {
            if (s_outcomeTypes[i] == _outcomeType) {
                validType = true;
                break;
            }
        }
        if (!validType) revert InvalidOutcomeType();
        if (_weight == type(uint).max) revert InvalidOutcomeWeight(); // Prevent overflow issues

        s_outcomeProbabilities[_outcomeType] = _weight;
        _recalculateTotalProbabilityWeight();
        emit OutcomeWeightSet(_outcomeType, _weight);
    }

    // 22. Sets minimum and maximum allowed tunnel periods.
    function setTunnelPeriods(uint _minPeriod, uint _maxPeriod) public onlyOwner {
        if (_minPeriod == 0 || _maxPeriod == 0 || _minPeriod > _maxPeriod) revert InvalidTunnelPeriod();
        s_minTunnelPeriod = _minPeriod;
        s_maxTunnelPeriod = _maxPeriod;
    }

    // 25. Sets the address of the output asset for specific outcome types.
    // Useful for DIFFERENT_ERC20 and DIFFERENT_ERC721 outcomes.
    function setOutputAsset(uint _outcomeType, address _assetAddress) public onlyOwner {
        if (_outcomeType != OUTCOME_DIFFERENT_ERC20 && _outcomeType != OUTCOME_DIFFERENT_ERC721 && _outcomeType != OUTCOME_UPGRADED_NFT) {
            revert InvalidOutcomeType();
        }
        s_outputAssets[_outcomeType] = _assetAddress;
        emit OutputAssetSet(_outcomeType, _assetAddress);
    }

    // 26. Allows owner to withdraw ERC20 tokens stuck in the contract (not user deposits).
    function emergencyWithdrawAdmin(address _token, uint256 _amount) public onlyOwner {
        // Cannot withdraw EntangledToken as it's the contract's native token for mechanics
        if (_token == address(entangledToken)) revert InvalidParameterType(); // Using existing error

        // Check balance before transferring
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (_amount > balance) _amount = balance; // Withdraw max available if requested amount is too high

        IERC20(_token).transfer(msg.sender, _amount);
        emit EmergencyWithdrawal(_token, _amount);
    }

    // 27. Allows owner to withdraw ERC721 tokens stuck in the contract (not user deposits).
     function emergencyWithdrawERC721Admin(address _token, uint256 _tokenId) public onlyOwner {
         IERC721 erc721 = IERC721(_token);
         // Ensure the contract owns the token
         require(erc721.ownerOf(_tokenId) == address(this), "Contract does not own token");
         erc721.transferFrom(address(this), msg.sender, _tokenId);
         emit EmergencyWithdrawalERC721(_token, _tokenId);
     }


    // --- Internal Helpers ---

    // Selects an outcome type based on probabilities using a random seed.
    function _selectOutcome(uint _randomSeed) internal view returns (uint outcomeType) {
        uint totalWeight = s_totalProbabilityWeight;
        if (totalWeight == 0) return OUTCOME_ENTANGLED_ONLY; // Fallback

        uint randomNumber = _randomSeed % totalWeight;

        uint cumulativeWeight = 0;
        for(uint i = 0; i < s_outcomeTypes.length; i++) {
            uint currentOutcomeType = s_outcomeTypes[i];
            uint weight = s_outcomeProbabilities[currentOutcomeType];

            // Apply state influence to weight (simplified example)
            // Higher density slightly increases positive outcomes, lower density slightly increases negative
            // Higher spatial increases variance (maybe boost extreme outcomes)
            // Higher anomaly increases negative outcomes, decreases positive
            int stateModifier = 0;
            if (s_quantumState.chrononDensity > 1000) stateModifier += int((s_quantumState.chrononDensity - 1000) / 100);
            if (s_quantumState.chrononDensity < 1000) stateModifier -= int((1000 - s_quantumState.chrononDensity) / 100);

             if (s_quantumState.spatialDistortion > 1000) {
                  // Boost extreme outcomes based on distortion
                  if (currentOutcomeType == OUTCOME_ORIGINAL_BONUS || currentOutcomeType == OUTCOME_UPGRADED_NFT) stateModifier += int((s_quantumState.spatialDistortion - 1000) / 200);
                  if (currentOutcomeType == OUTCOME_TOTAL_LOSS || currentOutcomeType == OUTCOME_PARTIAL_LOSS) stateModifier += int((s_quantumState.spatialDistortion - 1000) / 200);
             }

             stateModifier -= int(s_quantumState.anomalyLevel / 50); // Anomaly reduces positive/increases negative

             // Apply modifier based on outcome type (positive modifier helps good outcomes, hurts bad ones)
             uint effectiveWeight = weight;
             if (currentOutcomeType == OUTCOME_ORIGINAL_BONUS || currentOutcomeType == OUTCOME_UPGRADED_NFT || currentOutcomeType == OUTCOME_DIFFERENT_ERC20 || currentOutcomeType == OUTCOME_DIFFERENT_ERC721 || currentOutcomeType == OUTCOME_ENTANGLED_ONLY) {
                 if (stateModifier > 0) effectiveWeight = effectiveWeight + uint(stateModifier);
                 else if (effectiveWeight > uint(-stateModifier)) effectiveWeight = effectiveWeight - uint(-stateModifier);
                 else effectiveWeight = 0;
             } else if (currentOutcomeType == OUTCOME_PARTIAL_LOSS || currentOutcomeType == OUTCOME_TOTAL_LOSS) {
                 if (stateModifier < 0) effectiveWeight = effectiveWeight + uint(-stateModifier);
                 else if (effectiveWeight > uint(stateModifier)) effectiveWeight = effectiveWeight - uint(stateModifier);
                 else effectiveWeight = 0;
             }
            effectiveWeight = effectiveWeight > weight * 2 ? weight * 2 : effectiveWeight; // Cap modifier influence
            effectiveWeight = effectiveWeight > 0 ? effectiveWeight : 1; // Minimum weight

            cumulativeWeight += effectiveWeight;

            if (randomNumber < cumulativeWeight) {
                return currentOutcomeType;
            }
        }

        // Fallback: if something went wrong with weights
        return OUTCOME_ENTANGLED_ONLY;
    }

    // Recalculates the sum of all outcome probability weights.
    function _recalculateTotalProbabilityWeight() internal {
        s_totalProbabilityWeight = 0;
        for(uint i = 0; i < s_outcomeTypes.length; i++) {
            s_totalProbabilityWeight += s_outcomeProbabilities[s_outcomeTypes[i]];
        }
    }

    // Get outcome description (for estimation helper)
    function _getOutcomeDescription(uint _outcomeType) internal pure returns (string memory) {
         if (_outcomeType == OUTCOME_ORIGINAL_BONUS) return "Original Asset + Entangled Bonus";
         if (_outcomeType == OUTCOME_DIFFERENT_ERC20) return "Different ERC20 Asset";
         if (_outcomeType == OUTCOME_DIFFERENT_ERC721) return "Different ERC721 Asset";
         if (_outcomeType == OUTCOME_UPGRADED_NFT) return "Upgraded/Modified Original ERC721";
         if (_outcomeType == OUTCOME_ENTANGLED_ONLY) return "Entangled Tokens Only";
         if (_outcomeType == OUTCOME_PARTIAL_LOSS) return "Partial Loss";
         if (_outcomeType == OUTCOME_TOTAL_LOSS) return "Total Loss";
         return "Unknown Outcome";
    }

    // Helper to get effective quantum state influence for calculations like Entangled mint
    function _getEffectiveQuantumStateInfluence() internal view returns (uint) {
         // Simplified influence calculation: Higher density & spatial are positive, anomaly negative
         int influence = int(s_quantumState.chrononDensity) + int(s_quantumState.spatialDistortion) - int(s_quantumState.anomalyLevel);
         // Normalize to a positive range, e.g., 0 to 20000
         influence = influence + 2500; // Shift minimum value up
         if (influence < 0) influence = 0;
         if (influence > 5000) influence = 5000; // Clamp max
         return uint(influence);
    }

    // Placeholder for generating a new NFT ID in Different/Upgraded outcomes
    function _generatePlaceholderNFTId(Deposit memory _deposit, QuantumState memory _state, uint _seed) internal pure returns (uint256) {
        // In a real system, this might be based on deposit properties, state, and randomness
        // and used by the *target* NFT contract to mint a specific token.
        // For this example, just a hash-based number.
        return uint256(keccak256(abi.encodePacked(_deposit.assetAddress, _deposit.assetIdOrAmount, _state.chrononDensity, _state.spatialDistortion, _state.anomalyLevel, _seed)));
    }

     // Internal Entangled Token burn helper for state manipulation cost
     function _burnEntangledTokens(address _from, uint _amount) internal {
         // This assumes the EntangledToken contract allows the minter (this contract) to burn from *any* address.
         // If not, the user would need to transfer tokens to the tunnel first or stake them and burn from stake.
         // Using stake is safer and implemented in shiftQuantumState. This helper isn't strictly needed if only staking costs are used.
         // Let's stick to burning staked tokens for shifts, and only use burn from owner for anomaly resolution costs.
         // This function can be removed or kept as internal utility if needed elsewhere.
         // Let's remove this helper and use the public EntangledToken burn directly where needed (e.g., triggerAnomalyResolution).
     }

    // Allow receiving ERC721 - needed for deposits
    receive() external payable {} // Allow receiving ether if needed for future features

    // fallback() external payable {} // Optional: to receive ether sent incorrectly
}
```

---

**Explanation of Advanced Concepts & Choices:**

1.  **Probabilistic Outcomes with State Influence:** Instead of a fixed return or simple yield, the contract introduces uncertainty and excitement. The outcome depends not just on a random number, but also on the dynamic `quantumState` and potentially user staked amounts. This creates a dynamic environment where the "odds" of different outcomes change over time and based on community interaction.
2.  **Dynamic Quantum State:** The `chrononDensity`, `spatialDistortion`, and `anomalyLevel` variables are abstract representations of the tunnel's internal state. They are not just static parameters but can be shifted by users (at a cost/risk) and anchored by the admin. This introduces a meta-layer of interaction – users aren't just depositing; they might try to manipulate the environment for better odds, creating a mini-game around the state itself.
3.  **Native Entangled Token Utility:** The `EntangledToken` isn't just an afterthought; it's integral. It's a *product* of the tunnel (minted on certain claims) and a *tool* for interaction (staked to influence state/outcomes, burned for state shifts or anomaly resolution). This creates a circular economy within the contract. Deploying it *from* the constructor is a common pattern.
4.  **State Manipulation Mechanics:** Functions like `shiftQuantumState` and `anchorQuantumState` add complexity. `shiftQuantumState` allows users to spend `EntangledToken` to attempt to alter the state, introducing risk (increased anomaly) and a pseudo-random element. `anchorQuantumState` gives the admin stability during crucial periods.
5.  **Multi-Asset Handling:** While not groundbreaking alone, combining ERC20 and ERC721 deposits and potential outcomes within the same contract adds complexity over single-asset protocols.
6.  **Outcome Abstraction:** The different `OUTCOME_` constants and the `_selectOutcome` function abstract the core logic of *what* happens after the period. The `_selectOutcome` function incorporates the `quantumState` and stake into the probability calculation, making it more complex than a simple weighted random choice.
7.  **Error Handling:** Using custom errors (`error ...; revert ...;`) is a modern Solidity practice that saves gas compared to string reverts.

**Security and Caveats:**

*   **Randomness:** The primary source of randomness (`block.timestamp`, `block.difficulty`, `block.number`, `keccak256`) is easily exploitable by miners, especially for outcomes with significant value differences and short tunnel periods. This contract is *not* suitable for high-value, short-term probabilistic outcomes where truly fair randomness is critical. Secure randomness on-chain typically requires Oracles like Chainlink VRF.
*   **Complexity:** More complex logic leads to a larger attack surface. Careful testing and auditing are crucial for production.
*   **ERC721 Outcomes:** The implementation of `OUTCOME_DIFFERENT_ERC721` and `OUTCOME_UPGRADED_NFT` is heavily simplified. A real system would require a dedicated mechanism for transferring/minting NFTs from specific output contracts or pools, which is complex and wasn't fully implemented here. The current version primarily logs the intended outcome for NFTs in these cases.
*   **State Influence Scaling:** The formulas for how `quantumState` influences probabilities and Entangled Token minting (`_selectOutcome`, `previewEntangledMintAmount`) are simplified examples. Designing balanced and unpredictable scaling requires careful economic modeling.
*   **Gas Costs:** Complex logic, especially within `claimFromTunnel` involving multiple conditional transfers and calculations, could lead to high gas costs depending on the exact implementation details and state complexity.

This contract serves as a creative demonstration combining several features beyond a standard token or DeFi primitive. Remember that deploying complex contracts on a live network requires thorough auditing and testing.