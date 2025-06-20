Okay, let's create a smart contract that combines elements of dynamic DeFi, NFTs, oracle interaction, and a mini-prediction market, centered around a concept of "dynamic liquidity states" or "phases". We'll call it the "QuantumLiquidityNexus".

The idea is that users provide liquidity for token pairs, but the yield/rewards aren't static. They change based on external market conditions fed by an oracle (the "quantum phase"). Liquidity positions are represented by dynamic NFTs that accrue yield and might change appearance/properties based on the phase they were in. There's also an internal prediction market where users can stake tokens predicting the *next* phase shift.

This is a complex system, so we'll outline its components and functions first.

---

**QuantumLiquidityNexus Smart Contract**

**Concept:** A decentralized hub for dynamic liquidity provision. Users stake token pairs to earn variable QNX (native token) rewards, represented by dynamic Position NFTs. The yield rate is determined by the contract's "Quantum Phase", which shifts based on external market data from an oracle or triggered events. The contract also features an internal prediction market for phase shifts and a simple governance mechanism for treasury management.

**Core Components:**

1.  **QNX Token (ERC20):** The native reward and governance token.
2.  **PositionNFT (ERC721):** Represents a user's staked liquidity position. Can accrue yield and potentially have dynamic metadata based on the phases experienced.
3.  **Oracle Integration:** Connects to an external oracle (simulated interface here) to get market data (e.g., volatility index, price correlation) influencing the phase.
4.  **Dynamic Phases:** Discrete operating states, each with different QNX emission rates, fee structures, and prediction market parameters. Transitions between phases are based on oracle data or a "Catalyst" function.
5.  **Prediction Market:** Allows users to stake QNX predicting the outcome of the next phase transition.
6.  **Treasury:** Holds protocol fees and potentially initial QNX distribution, managed by governance.
7.  **Governance:** Simple voting system (weighted by QNX holdings) for treasury spending or protocol parameter adjustments.

**Outline:**

*   SPDX License and Pragma
*   Imports (ERC20, ERC721, Ownable, Interface for Oracle)
*   Error Definitions
*   Enums (PhaseState, ProposalState)
*   Structs (PhaseParameters, LiquidityPosition, Prediction, GovernanceProposal)
*   State Variables
*   Events
*   Modifiers
*   Constructor
*   Oracle Interaction Functions (Internal/External)
*   Phase Management Functions (Internal/External)
*   Liquidity Staking Functions (External)
*   Yield Calculation & Claiming (Internal/External)
*   NFT Interaction (Implicit via Staking/Unstaking, Explicit Reads)
*   Prediction Market Functions (External)
*   Treasury Management Functions (External via Governance)
*   Governance Functions (External)
*   Utility/Read Functions (External)
*   Internal Helper Functions

**Function Summary:**

1.  `constructor()`: Initializes the contract, deploys QNX and PositionNFT tokens, sets initial parameters and owner.
2.  `initializeOracle(address oracleAddress)`: Sets the address of the external oracle feed (owner only).
3.  `addSupportedPair(address tokenA, address tokenB)`: Registers a token pair that can be used for liquidity staking (owner/governance only).
4.  `stakeLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB)`: Users stake a balanced amount of a supported token pair, minting a unique PositionNFT representing their position.
5.  `unstakeLiquidity(uint256 positionId)`: Users burn their PositionNFT to withdraw their initial liquidity plus accrued QNX yield.
6.  `claimYield(uint256 positionId)`: Allows users to claim their accrued QNX yield for a specific position without unstaking the principal liquidity.
7.  `extendPositionStake(uint256 positionId, uint256 additionalDuration)`: Allows users to commit to staking a position for a longer period, potentially qualifying for bonuses (logic placeholder).
8.  `updatePhaseFromOracle()`: Anyone can call to trigger the contract to read the oracle and potentially transition to a new phase based on the data.
9.  `triggerCatalystEvent(uint256 requiredQNXStake)`: Allows users to pay a QNX stake to manually attempt to trigger a phase transition (logic placeholder: maybe forces a check, or transitions to a specific 'catalyst' phase). Staked QNX goes to treasury.
10. `enterPredictionMarket(uint8 predictedPhaseIndex, uint256 qnxAmount)`: Users stake QNX to predict the index of the *next* phase the contract will transition to.
11. `resolvePredictionMarket()`: Triggered after a phase transition. Calculates rewards for correct predictors from the staked QNX pool.
12. `claimPredictionRewards()`: Allows users with winning predictions to claim their share of the prediction market pool.
13. `submitGovernanceProposal(bytes memory proposalData)`: Allows QNX holders (above a threshold) to submit a proposal (e.g., treasury spending, changing phase parameters).
14. `voteOnProposal(uint256 proposalId, bool support)`: Allows QNX holders to cast votes (weighted by their QNX balance) on an active proposal.
15. `executeProposal(uint256 proposalId)`: Executes a proposal that has met the required voting threshold and quorum within the voting period.
16. `getAPY(address tokenA, address tokenB)`: Calculates and returns the current estimated annual percentage yield for a specific token pair based on the current phase parameters.
17. `getPositionDetails(uint256 positionId)`: Retrieves and returns the details of a specific liquidity position represented by an NFT.
18. `getAccruedYield(uint256 positionId)`: Calculates and returns the amount of QNX yield accrued for a specific position since the last claim or stake time.
19. `getCurrentPhase()`: Returns the index and parameters of the contract's current operating phase.
20. `getTreasuryBalance()`: Returns the current balance of QNX held in the contract's treasury.
21. `getPhaseParameters(uint8 phaseIndex)`: Returns the parameters associated with a specific phase index.
22. `getSupportedPairs()`: Returns the list of token pairs currently supported for staking.
23. `getUserPositions(address user)`: Returns a list of PositionNFT IDs owned by a specific user.
24. `getProposalDetails(uint256 proposalId)`: Retrieves and returns the details of a specific governance proposal.

---

Now, let's write the Solidity code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // To list NFTs by owner
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Mock/Interface for an Oracle feed. Replace with actual oracle implementation.
interface IQuantumOracle {
    function getMarketVolatilityIndex() external view returns (uint256 index);
    // Add other relevant data feeds if needed
}

// Custom ERC20 for QNX token
contract QNXToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("QuantumNexus Token", "QNX") {
        _mint(msg.sender, initialSupply); // Mint initial supply to deployer (for treasury/initial distribution)
    }

    // Allow minter role or specific contract to mint
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Allow burn by anyone (e.g., for staking costs)
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}

// Custom ERC721 for Position NFTs
contract PositionNFT is ERC721Enumerable {
    constructor() ERC721("QuantumPosition NFT", "QPNFT") {}

    // The main QuantumLiquidityNexus contract will have the minter role
    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    // Placeholder for dynamic metadata - off-chain renderer would use these details
    struct PositionDetails {
        address owner;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint64 stakeStartTime;
        uint64 lastYieldClaimTime;
        uint8 initialPhase;
        uint64 stakeDurationMultiplier; // Placeholder for bonuses
    }

    mapping(uint256 => PositionDetails) private _positionDetails;

    function setPositionDetails(uint256 tokenId, PositionDetails memory details) external onlyOwner {
        _positionDetails[tokenId] = details;
    }

    function getPositionDetails(uint256 tokenId) external view returns (PositionDetails memory) {
        require(_exists(tokenId), "QPNFT: token does not exist");
        return _positionDetails[tokenId];
    }

    // ERC721Enumerable requires implementation details, already handled by inheriting
}


contract QuantumLiquidityNexus is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // --- Errors ---
    error InvalidTokenPair();
    error InsufficientLiquidityProvided();
    error PositionNotFound();
    error NothingToClaim();
    error InvalidPhaseIndex();
    error PredictionMarketNotResolvable();
    error AlreadyPredicted();
    error PredictionNotResolved();
    error NoPredictionMade();
    error ProposalNotFound();
    error ProposalNotActive();
    error AlreadyVoted();
    error InsufficientQNXForProposal();
    error ProposalNotExecutable();
    error InvalidOracle();
    error PositionNotOwned();
    error InvalidAmount();
    error UnsupportedPair();


    // --- Enums ---
    enum PhaseState {
        Unknown,
        QuantumFluctuation, // High volatility, potentially higher rewards
        StableEquilibrium,  // Low volatility, potentially lower rewards, maybe higher fees
        CatalystEffect      // Triggered state, special rules/bonuses
    }

    enum ProposalState {
        Pending,
        Active,
        Passed,
        Failed,
        Executed
    }

    // --- Structs ---
    struct PhaseParameters {
        PhaseState state;
        uint256 baseQNXRatePerSec; // Base QNX emission rate per second per unit of liquidity value (scaled)
        uint256 feeMultiplier;     // Multiplier for protocol fees
        uint256 oracleThreshold;   // Threshold value from oracle to trigger this phase (e.g., volatility index)
        uint256 predictionMultiplier; // Multiplier for prediction market rewards in this phase
        uint256 duration;          // How long the phase typically lasts or cooldown (if phase is triggered manually)
    }

    struct LiquidityPosition {
        address owner;
        address tokenA;
        address tokenB;
        uint256 amountA; // Initial amount staked
        uint256 amountB; // Initial amount staked
        uint64 stakeStartTime;
        uint64 lastYieldClaimTime; // Timestamp of last yield claim or stake
        uint8 initialPhase;        // Index of phase when staked
        uint64 stakeDurationMultiplier; // Bonus multiplier for yield (placeholder)
    }

    struct Prediction {
        address predictor;
        uint8 predictedPhaseIndex;
        uint256 qnxStaked;
        bool resolved;
        bool claimed;
        bool correct;
        uint256 rewardAmount; // Amount of QNX earned
    }

    struct GovernanceProposal {
        address proposer;
        bytes proposalData; // Calldata for execution (e.g., targeting treasury)
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        uint64 submissionTime;
        uint64 votingEndTime;
        ProposalState state;
        mapping(address => bool) hasVoted; // Ensure users vote only once
    }

    // --- State Variables ---
    QNXToken public immutable qnxToken;
    PositionNFT public immutable positionNFT;
    IQuantumOracle public quantumOracle;

    mapping(uint8 => PhaseParameters) public phaseConfigs;
    uint8 public currentPhaseIndex;
    uint64 public phaseTransitionTime; // Timestamp of the last phase transition
    uint66 public nextPositionId = 1; // Start token IDs from 1

    mapping(uint256 => LiquidityPosition) public liquidityPositions; // positionId => details

    mapping(address => bool) public supportedPairs; // Hash of (tokenA, tokenB) => bool
    address[] private _supportedPairTokens; // List of unique token addresses in supported pairs (for iteration)

    uint256 public predictionMarketPool; // Total QNX staked in current prediction market
    uint256 public predictionMarketResolutionTime; // When the current market started/resolves
    uint256 public nextPredictionId = 1;
    mapping(uint256 => Prediction) public predictions; // predictionId => details
    mapping(address => uint256[]) public userPredictions; // user => list of predictionIds

    uint256 public nextProposalId = 1;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public constant MIN_QNX_FOR_PROPOSAL = 100e18; // Example: 100 QNX to submit
    uint64 public constant VOTING_PERIOD = 3 days; // Example voting period
    uint256 public constant PROPOSAL_THRESHOLD_PERCENT = 51; // 51% to pass
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 10; // 10% of QNX supply must vote


    // --- Events ---
    event OracleInitialized(address indexed oracleAddress);
    event SupportedPairAdded(address indexed tokenA, address indexed tokenB);
    event LiquidityStaked(address indexed user, uint256 positionId, address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event LiquidityUnstaked(address indexed user, uint256 positionId, uint256 amountA, uint256 amountB, uint256 qnxYield);
    event YieldClaimed(address indexed user, uint256 positionId, uint256 amount);
    event PhaseTransition(uint8 indexed oldPhaseIndex, uint8 indexed newPhaseIndex, PhaseState indexed newState, uint256 oracleData);
    event CatalystTriggered(address indexed user, uint8 indexed newPhaseIndex, uint256 qnxStaked);
    event PredictionMarketEntered(address indexed user, uint256 predictionId, uint8 predictedPhaseIndex, uint256 qnxAmount);
    event PredictionMarketResolved(uint8 indexed finalPhaseIndex, uint256 totalPool, uint256 totalCorrectStake);
    event PredictionRewardsClaimed(address indexed user, uint256 totalRewardAmount);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event GovernanceProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---
    modifier onlySupportedPair(address tokenA, address tokenB) {
        require(supportedPairs[keccak256(abi.encodePacked(tokenA, tokenB))], "UnsupportedPair");
        _;
    }

    modifier onlyProposalState(uint256 proposalId, ProposalState state) {
        require(governanceProposals[proposalId].state == state, "Proposal in wrong state");
        _;
    }

    modifier notResolved(uint256 predictionId) {
        require(!predictions[predictionId].resolved, "Prediction already resolved");
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialQNXSupply, address initialOracle, PhaseParameters[] memory initialPhases) Ownable(msg.sender) {
        qnxToken = new QNXToken(initialQNXSupply);
        positionNFT = new PositionNFT();

        // Grant MINTER_ROLE to this contract (Ownable in QNX/PositionNFT)
        // In a real system, this would likely be a specific MINTER_ROLE constant/check
        // For this example, Owner (deployer) of Nexus is also Owner of QNX/PositionNFT initially
        qnxToken.transferOwnership(address(this));
        positionNFT.transferOwnership(address(this));

        // Configure initial phases
        require(initialPhases.length > 0, "Must provide initial phases");
        for (uint8 i = 0; i < initialPhases.length; i++) {
            phaseConfigs[i] = initialPhases[i];
        }
        currentPhaseIndex = 0; // Start with the first phase
        phaseTransitionTime = uint64(block.timestamp);
        predictionMarketResolutionTime = uint64(block.timestamp); // Reset prediction market

        // Set initial oracle if provided
        if (initialOracle != address(0)) {
            initializeOracle(initialOracle);
        }

        // Placeholder: add some initial supported pairs for testing
        // addSupportedPair(0x...TokenA..., 0x...TokenB...);
        // addSupportedPair(0x...TokenC..., 0x...TokenD...);
    }

    // --- Initialization ---
    function initializeOracle(address oracleAddress) public onlyOwner {
        require(oracleAddress != address(0), "InvalidOracle");
        quantumOracle = IQuantumOracle(oracleAddress);
        emit OracleInitialized(oracleAddress);
    }

    function addSupportedPair(address tokenA, address tokenB) public onlyOwner {
        require(tokenA != address(0) && tokenB != address(0), "InvalidTokenPair");
        // Ensure tokenA is always the smaller address for canonical representation
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        bytes32 pairHash = keccak256(abi.encodePacked(tokenA, tokenB));
        require(!supportedPairs[pairHash], "SupportedPair already added");
        supportedPairs[pairHash] = true;
        _supportedPairTokens.push(tokenA); // Store tokens for iteration (simple list, might have duplicates)
        _supportedPairTokens.push(tokenB);
        emit SupportedPairAdded(tokenA, tokenB);
    }

    // --- Liquidity Staking ---

    /**
     * @notice Stakes a balanced amount of a supported token pair to earn QNX yield.
     * Mints a PositionNFT representing the staked position.
     * @param tokenA Address of the first token in the pair.
     * @param tokenB Address of the second token in the pair.
     * @param amountA Amount of tokenA to stake.
     * @param amountB Amount of tokenB to stake.
     */
    function stakeLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external nonReentrant onlySupportedPair(tokenA, tokenB) {
        require(amountA > 0 && amountB > 0, "InsufficientLiquidityProvided");

        // Ensure tokenA is always the smaller address for canonical representation
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        // Re-check supported pair after potential swap
        require(supportedPairs[keccak256(abi.encodePacked(tokenA, tokenB))], "UnsupportedPair");


        // Transfer tokens from user to contract
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);

        uint256 positionId = nextPositionId++;
        uint64 currentTime = uint64(block.timestamp);

        LiquidityPosition memory newPosition = LiquidityPosition({
            owner: msg.sender,
            tokenA: tokenA,
            tokenB: tokenB,
            amountA: amountA,
            amountB: amountB,
            stakeStartTime: currentTime,
            lastYieldClaimTime: currentTime, // Start yield accrual now
            initialPhase: currentPhaseIndex,
            stakeDurationMultiplier: 1e18 // Start with 1x multiplier (scaled)
        });

        liquidityPositions[positionId] = newPosition;

        // Mint Position NFT to user
        positionNFT.mint(msg.sender, positionId);
        positionNFT.setPositionDetails(positionId, PositionNFT.PositionDetails({
             owner: msg.sender,
             tokenA: tokenA,
             tokenB: tokenB,
             amountA: amountA,
             amountB: amountB,
             stakeStartTime: currentTime,
             lastYieldClaimTime: currentTime,
             initialPhase: currentPhaseIndex,
             stakeDurationMultiplier: 1e18 // Start with 1x multiplier (scaled)
        }));

        emit LiquidityStaked(msg.sender, positionId, tokenA, tokenB, amountA, amountB);
    }

    /**
     * @notice Burns a PositionNFT to unstake liquidity and claim principal + accrued yield.
     * @param positionId The ID of the PositionNFT to burn.
     */
    function unstakeLiquidity(uint256 positionId) external nonReentrant {
        LiquidityPosition storage pos = liquidityPositions[positionId];
        require(pos.owner != address(0), "PositionNotFound");
        require(pos.owner == msg.sender, "PositionNotOwned");

        // Calculate pending yield before unstaking
        uint256 pendingYield = _calculateYield(positionId);

        // Transfer principal back
        IERC20(pos.tokenA).safeTransfer(msg.sender, pos.amountA);
        IERC20(pos.tokenB).safeTransfer(msg.sender, pos.amountB);

        // Transfer accrued QNX yield
        if (pendingYield > 0) {
             // Ensure contract has enough QNX (minted or from treasury/fees)
            uint256 contractQNXBalance = qnxToken.balanceOf(address(this));
            if (contractQNXBalance < pendingYield) {
                // This is a critical point: where does QNX for rewards come from?
                // Option 1: Mint it (requires contract to have minter role) - This is simpler for the example
                // Option 2: It comes from fees/treasury/initial allocation. If insufficient, rewards might be capped.
                // Let's use Minting for this example for simplicity. In a real system, tokenomics design is key.
                qnxToken.mint(address(this), pendingYield - contractQNXBalance); // Mint deficit
            }
             qnxToken.safeTransfer(msg.sender, pendingYield);
        }

        // Burn the Position NFT
        positionNFT.burn(positionId);

        // Clean up state
        delete liquidityPositions[positionId];

        emit LiquidityUnstaked(msg.sender, positionId, pos.amountA, pos.amountB, pendingYield);
    }

    /**
     * @notice Claims accrued QNX yield for a specific staked position without unstaking principal.
     * Updates the last claim time for the position.
     * @param positionId The ID of the PositionNFT.
     */
    function claimYield(uint256 positionId) external nonReentrant {
        LiquidityPosition storage pos = liquidityPositions[positionId];
        require(pos.owner != address(0), "PositionNotFound");
        require(pos.owner == msg.sender, "PositionNotOwned");

        uint256 pendingYield = _calculateYield(positionId);
        require(pendingYield > 0, "NothingToClaim");

        uint64 currentTime = uint64(block.timestamp);

         // Ensure contract has enough QNX
        uint256 contractQNXBalance = qnxToken.balanceOf(address(this));
        if (contractQNXBalance < pendingYield) {
             qnxToken.mint(address(this), pendingYield - contractQNXBalance); // Mint deficit
        }

        qnxToken.safeTransfer(msg.sender, pendingYield);

        // Update last claim time to now
        pos.lastYieldClaimTime = currentTime;

        emit YieldClaimed(msg.sender, positionId, pendingYield);
    }

     /**
      * @notice Allows extending stake duration. Placeholder for potential bonuses.
      * @param positionId The ID of the PositionNFT.
      * @param additionalDuration Placeholder for future duration logic.
      */
    function extendPositionStake(uint256 positionId, uint256 additionalDuration) external {
        LiquidityPosition storage pos = liquidityPositions[positionId];
        require(pos.owner != address(0), "PositionNotFound");
        require(pos.owner == msg.sender, "PositionNotOwned");
        // TODO: Implement logic to update stakeDurationMultiplier or other parameters
        // based on additionalDuration commitment. This could involve locking the position
        // or adding conditions to unstaking.
        // For now, this is just a placeholder function.
        revert("Extend stake not yet fully implemented");
    }


    // --- Yield Calculation ---
    // NOTE: Yield calculation logic is a simplified example. A real system
    // would need a more robust way to track yield accrual across dynamic phases,
    // potentially using checkpoints or integral calculations over time periods in different phases.
    function _calculateYield(uint256 positionId) internal view returns (uint256) {
        LiquidityPosition storage pos = liquidityPositions[positionId];
        if (pos.owner == address(0) || pos.lastYieldClaimTime == uint64(block.timestamp)) {
            return 0; // No position or yield already claimed for this second
        }

        // Simplified approach: Calculate yield based on the CURRENT phase rate
        // and the time elapsed since last claim/stake. This doesn't account
        // for phase changes *between* last claim and now, which is a complex
        // state-dependent yield accrual problem.
        // A more advanced system would track `(phaseIndex, startTime, endTime)` intervals
        // and sum up yield per interval.

        PhaseParameters storage currentParams = phaseConfigs[currentPhaseIndex];

        // A simplistic "value" representation for the position - can be improved
        // Maybe based on token prices via oracle? For now, just use amount A
        // (Assuming a pair like TOKEN/WETH, where WETH price could be used to value position)
        // To keep it simple without external price feeds for every token, let's use amountA * a fixed factor, or sum A+B if they are stable
        // For a creative example, let's assume AmountA represents "units" of liquidity
        // and base rate is per unit per second.
        uint256 liquidityUnits = pos.amountA; // Highly simplified liquidity "value"

        uint256 timeElapsed = uint256(block.timestamp) - pos.lastYieldClaimTime;

        // base QNX / sec / unit * units * time elapsed * duration multiplier
        // Need scaling factor for base rate if it's very small
        // Assume baseQNXRatePerSec is scaled, e.g., 1e18 represents 1 QNX per sec per unit
        // Let's use 1e18 scaling for rates and multipliers
        uint256 rawYield = (currentParams.baseQNXRatePerSec * liquidityUnits * timeElapsed * pos.stakeDurationMultiplier) / (1e18);

        // Add bonus for initial phase? Or phases experienced? Complex logic omitted for example length.

        return rawYield;
    }

    /**
     * @notice Calculates and returns the current estimated annual percentage yield for a specific token pair.
     * @param tokenA Address of the first token.
     * @param tokenB Address of the second token.
     * @return estimatedAPY_1e18 Estimated APY scaled by 1e18.
     */
    function getAPY(address tokenA, address tokenB) public view onlySupportedPair(tokenA, tokenB) returns (uint256 estimatedAPY_1e18) {
         // Ensure tokenA is always the smaller address
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        // This estimation is highly simplified. A real APY depends on:
        // 1. QNX emission rate (phase dependent)
        // 2. Value of staked liquidity (token prices)
        // 3. Value of QNX token
        // 4. Total staked liquidity in that pool
        // 5. Duration multipliers

        // Simplified APY: Assume 1 unit of liquidity is worth 1 unit (e.g. 1 USD, if AmountA is USD).
        // Calculate daily or yearly QNX per unit and convert to APY.

        PhaseParameters storage currentParams = phaseConfigs[currentPhaseIndex];
        uint256 qnxPerSecPerUnit = currentParams.baseQNXRatePerSec; // scaled by 1e18

        // Assume 1 unit of liquidity = 1 tokenA for simplicity here
        // Or better: Value the liquidity based on oracle prices.
        // Without external price oracle for ALL tokens, let's just calculate QNX/second/unit.
        // APY = (QNX / unit / second) * seconds in year * Price(QNX) / Price(Unit)

        // Let's calculate daily yield per unit and extrapolate (requires price feeds)
        // Example using fixed price ratio for simplicity: Assume QNX is 1/10th value of 1 unit of liquidity
        // daily_qnx_per_unit = qnxPerSecPerUnit * 86400 seconds/day / 1e18 (unscale rate)
        // daily_yield_percent = (daily_qnx_per_unit * Price(QNX)) / Price(Unit) * 100
        // annual_yield_percent = daily_yield_percent * 365

        // Let's calculate QNX/unit/year (scaled) and leave price conversion to frontend/off-chain calculation.
        // QNX_per_unit_per_year_scaled = qnxPerSecPerUnit * 31536000 seconds/year
        uint256 qnxPerUnitPerYear_scaled = qnxPerSecPerUnit * 31536000; // Scaled by 1e18

        // This QNX/unit/year value needs to be converted to APY (%) by:
        // APY = (QNX_per_unit_per_year * Price_of_QNX) / Price_of_Unit * 100
        // We return the QNX_per_unit_per_year_scaled. Frontend calculates APY with prices.
        // Let's return a value that can be used to calculate APY assuming 1 unit = 1 token A value and QNX value is X.
        // APY = (QNX_per_sec_per_unit * seconds_in_year * duration_multiplier) / (total_liquidity_units_in_pool * QNX_price_in_tokenA)

        // Let's return the simple QNX_per_sec_per_unit, the frontend can multiply by secs/year and price ratio.
        // Or return a value that implies APY assuming QNX=1 TOKEN_A unit, duration=1.
        // QNX_per_year_assuming_1_unit_and_1x_multiplier = qnxPerSecPerUnit * 31536000
        // This is still scaled by 1e18. If qnxPerSecPerUnit is 1e18 (1 QNX/sec/unit), this returns 31536000e18.
        // APY calculation requires division by total pool units, which is hard to get precisely on-chain without iterating.
        // Let's return a simpler metric: QNX emission rate per unit of liquidity value per year (scaled).
        // Assume 1 unit of liquidity for tokenA/tokenB pair is `amountA`.
        // We need a way to value `amountA` in terms of a base currency (like USD or ETH) using oracle prices.
        // Without token price oracle: APY is relative. Let's return QNX/year *per staked tokenA*.
        // This assumes 1 tokenA == 1 unit of liquidity valuation.
        // QNX_per_tokenA_staked_per_year_scaled = qnxPerSecPerUnit * 31536000
        // This number, when divided by the effective "price" of QNX relative to tokenA, gives APY.
        // e.g. If QNX trades at 0.1 tokenA, and this returns 31536000e18, the APY is (31536000e18 / 1e18) * 0.1 * 100 % = 3153600 * 0.1 * 100 % = 31,536,000 % ... This scaling is tricky.

        // Let's define the return value clearly: It's the annual rate of QNX emission *per unit of base liquidity*.
        // Assume 1 unit of base liquidity corresponds to staking `amountA` of tokenA (and corresponding amountB).
        // The rate `baseQNXRatePerSec` is QNX per second *per unit*.
        // Annual Rate (scaled) = `baseQNXRatePerSec` * 31536000 (seconds in year)
        // This gives a large number. If `baseQNXRatePerSec` was defined as QNX per second *per $1k TVL*, and scaled, this would be clearer.
        // Let's assume `baseQNXRatePerSec` is scaled such that multiplying by time and amountA gives QNX.
        // Example: If 1 QNX/sec/unit, rate is 1e18. Annual rate is 31536000e18.
        // If TokenA is priced at $1, and QNX at $0.1, and TVL is $1M (1M units of TokenA), and total QNX emission is 1 QNX/sec:
        // Rate per unit = 1 QNX / 1M units / sec = 1e-6 QNX/unit/sec.
        // Annual QNX per unit = 1e-6 * 31536000 = 31.536 QNX/unit/year
        // Annual Yield % = (31.536 QNX/unit/year * $0.1/QNX) / ($1/unit) * 100 = 3.1536 * 100 = 315.36 %

        // The contract can only return the QNX emission rate / unit / year. The APY calculation requires off-chain price data.
        // We return `baseQNXRatePerSec` * 31536000 (scaled by 1e18).
        return (currentParams.baseQNXRatePerSec * 31536000e18) / 1e18; // Result is QNX / unit / year (scaled by 1e18)
    }

    /**
     * @notice Calculates and returns the currently accrued QNX yield for a staked position.
     * @param positionId The ID of the PositionNFT.
     * @return accruedYield Amount of QNX accrued.
     */
    function getAccruedYield(uint256 positionId) public view returns (uint256 accruedYield) {
        return _calculateYield(positionId);
    }

    // --- Phase Management ---

    /**
     * @notice Reads the oracle data and potentially triggers a phase transition
     * if thresholds are met. Anyone can call this (permissionless update).
     */
    function updatePhaseFromOracle() external nonReentrant {
        require(address(quantumOracle) != address(0), "InvalidOracle");

        uint256 volatilityIndex = quantumOracle.getMarketVolatilityIndex(); // Example oracle data

        // Determine new phase based on index thresholds
        uint8 newPhaseIndex = currentPhaseIndex; // Default to current
        PhaseState newState = phaseConfigs[currentPhaseIndex].state;

        // This logic is simplistic. A real system would compare index against thresholds
        // of *all* possible phases and find the best match, or have hysteresis.
        // For this example, let's just check against specific thresholds.
        // Assuming phaseConfigs[0] is StableEquilibrium, phaseConfigs[1] is QuantumFluctuation

        if (phaseConfigs.length > 1) {
            // Example logic: If volatility > threshold[1], go to phase 1 (QuantumFluctuation)
            // If volatility <= threshold[1], go to phase 0 (StableEquilibrium)
            // Exclude Catalyst phase logic from oracle transition unless specifically designed.
            // Assuming phase 0 and 1 are the main oracle-driven ones.
            uint8 oracleDrivenPhaseCandidate = 0; // Default to phase 0
            if (volatilityIndex > phaseConfigs[1].oracleThreshold && phaseConfigs[1].state != PhaseState.CatalystEffect) {
                 oracleDrivenPhaseCandidate = 1; // Check if phase 1 is applicable
            }
             // ... more complex checks for other phases ...

            // Only transition if it's a different oracle-driven phase and not currently in a Catalyst state
            if (currentPhaseIndex != oracleDrivenPhaseCandidate && phaseConfigs[currentPhaseIndex].state != PhaseState.CatalystEffect) {
                 newPhaseIndex = oracleDrivenPhaseCandidate;
                 newState = phaseConfigs[newPhaseIndex].state;
            }
        }


        if (newPhaseIndex != currentPhaseIndex) {
            uint8 oldPhaseIndex = currentPhaseIndex;
            currentPhaseIndex = newPhaseIndex;
            phaseTransitionTime = uint64(block.timestamp);
            // Reset prediction market when phase changes via oracle
            _resolvePredictionMarket(oldPhaseIndex, newPhaseIndex); // Resolve market based on *transition*
            predictionMarketResolutionTime = uint64(block.timestamp); // Start new prediction window

            emit PhaseTransition(oldPhaseIndex, newPhaseIndex, newState, volatilityIndex);
        }
         // If phase didn't change, but prediction market window is over, resolve it anyway (predicting NO phase change or the current one)
        else if (block.timestamp >= predictionMarketResolutionTime + phaseConfigs[currentPhaseIndex].duration) {
             _resolvePredictionMarket(currentPhaseIndex, currentPhaseIndex); // Resolve market assuming no change
             predictionMarketResolutionTime = uint64(block.timestamp); // Start new prediction window
        }
    }

    /**
     * @notice Allows users to stake QNX to potentially trigger a phase transition,
     * often to a special 'Catalyst' phase or forcing an oracle check.
     * @param requiredQNXStake The amount of QNX the caller must stake.
     */
    function triggerCatalystEvent(uint256 requiredQNXStake) external nonReentrant {
        require(requiredQNXStake > 0, "InvalidAmount");

        // Transfer QNX stake to treasury/contract
        qnxToken.safeTransferFrom(msg.sender, address(this), requiredQNXStake);

        uint8 oldPhaseIndex = currentPhaseIndex;
        uint8 newPhaseIndex = currentPhaseIndex;
        PhaseState newState = phaseConfigs[currentPhaseIndex].state;

        // Example logic: Force transition to a specific Catalyst phase (if exists, e.g., phase 2)
        // Or force an oracle check AND potentially add a bonus factor to the phase transition logic
        // For this example, let's just transition to a specific phase index if it exists
        uint8 catalystPhaseIdx = 2; // Assume phase index 2 is Catalyst
        if (phaseConfigs.length > catalystPhaseIdx && phaseConfigs[catalystPhaseIdx].state == PhaseState.CatalystEffect) {
             newPhaseIndex = catalystPhaseIdx;
             newState = phaseConfigs[newPhaseIndex].state;

             if (newPhaseIndex != oldPhaseIndex) {
                currentPhaseIndex = newPhaseIndex;
                phaseTransitionTime = uint64(block.timestamp);
                 // Resolve prediction market based on this transition
                _resolvePredictionMarket(oldPhaseIndex, newPhaseIndex);
                predictionMarketResolutionTime = uint64(block.timestamp); // Start new prediction window
                emit CatalystTriggered(msg.sender, newPhaseIndex, requiredQNXStake);
             } else {
                 // If phase didn't change (maybe already in Catalyst?), QNX goes to treasury, no event needed
                 // Or emit a "CatalystAttempted" event
             }
        } else {
            // If no specific catalyst phase, maybe just force an oracle check now?
             // updatePhaseFromOracle(); // This would re-check the oracle right after
            // Or maybe the QNX stake just boosts yield *in the current* phase temporarily?
            // Or the QNX stake unlocks a special action?
             // Let's make it a no-op if no Catalyst phase is defined, but the QNX is still taken.
             // Or refund the QNX? Taking it is simpler for treasury example.
        }
         // If no phase transition occurred by this, the QNX is just added to the treasury/contract balance.
    }

    /**
     * @notice Get details of the current phase.
     */
    function getCurrentPhase() public view returns (uint8 phaseIndex, PhaseParameters memory params) {
        return (currentPhaseIndex, phaseConfigs[currentPhaseIndex]);
    }

    /**
     * @notice Get details of a specific phase.
     */
    function getPhaseParameters(uint8 phaseIndex) public view returns (PhaseParameters memory) {
        require(phaseConfigs[phaseIndex].state != PhaseState.Unknown, "InvalidPhaseIndex");
        return phaseConfigs[phaseIndex];
    }

     /**
      * @notice Get current raw data from the oracle (example).
      */
    function getCurrentOracleData() public view returns (uint256 volatilityIndex) {
        require(address(quantumOracle) != address(0), "InvalidOracle");
        return quantumOracle.getMarketVolatilityIndex();
    }


    // --- Prediction Market ---

    /**
     * @notice Allows users to stake QNX and predict the index of the next phase.
     * Can only be entered during an active prediction window.
     * @param predictedPhaseIndex The index of the phase the user predicts will be the next phase.
     * @param qnxAmount The amount of QNX to stake on this prediction.
     */
    function enterPredictionMarket(uint8 predictedPhaseIndex, uint256 qnxAmount) external nonReentrant {
        require(qnxAmount > 0, "InvalidAmount");
        require(phaseConfigs[predictedPhaseIndex].state != PhaseState.Unknown, "InvalidPhaseIndex"); // Must predict a valid configured phase

        // Can only enter if the current prediction window hasn't ended (or hasn't been resolved yet)
        // The window typically ends when the phase transition happens or its duration passes.
        // Let's allow entry until resolution happens.
        // require(block.timestamp < predictionMarketResolutionTime + phaseConfigs[currentPhaseIndex].duration, "Prediction market window closed");
        // Let's allow entry any time before resolution is *triggered*.

        qnxToken.safeTransferFrom(msg.sender, address(this), qnxAmount);

        uint256 predictionId = nextPredictionId++;
        predictions[predictionId] = Prediction({
            predictor: msg.sender,
            predictedPhaseIndex: predictedPhaseIndex,
            qnxStaked: qnxAmount,
            resolved: false,
            claimed: false,
            correct: false,
            rewardAmount: 0
        });

        userPredictions[msg.sender].push(predictionId);
        predictionMarketPool += qnxAmount;

        emit PredictionMarketEntered(msg.sender, predictionId, predictedPhaseIndex, qnxAmount);
    }

     /**
      * @notice Internal function to resolve the prediction market based on a phase transition.
      * Called automatically by phase transition functions.
      * @param oldPhaseIndex The phase index before the transition.
      * @param newPhaseIndex The phase index after the transition.
      */
    function _resolvePredictionMarket(uint8 oldPhaseIndex, uint8 newPhaseIndex) internal {
        if (predictionMarketPool == 0) {
            // Nothing staked, just reset
            predictionMarketResolutionTime = uint64(block.timestamp);
            return;
        }

        uint256 totalCorrectStake = 0;
        uint256[] memory currentPredictionIds = new uint256[](nextPredictionId - 1); // Array of all prediction IDs
        for (uint256 i = 1; i < nextPredictionId; i++) {
            currentPredictionIds[i - 1] = i;
        }

        for (uint256 i = 0; i < currentPredictionIds.length; i++) {
            uint256 pId = currentPredictionIds[i];
            Prediction storage p = predictions[pId];

            if (!p.resolved) {
                p.resolved = true;
                // Check if prediction was correct.
                // Prediction is correct if predictedPhaseIndex == newPhaseIndex
                if (p.predictedPhaseIndex == newPhaseIndex) {
                    p.correct = true;
                    totalCorrectStake += p.qnxStaked;
                }
            }
        }

        // Calculate rewards for correct predictions
        if (totalCorrectStake > 0) {
            uint256 totalRewardAmount = predictionMarketPool; // Total QNX staked in the market
            // Distribute proportionally to correct stakers
            for (uint256 i = 0; i < currentPredictionIds.length; i++) {
                 uint256 pId = currentPredictionIds[i];
                 Prediction storage p = predictions[pId];
                 if (p.correct) {
                     // reward = (staked_by_user / total_correct_stake) * total_pool
                     p.rewardAmount = (p.qnxStaked * totalRewardAmount) / totalCorrectStake;
                 } else {
                     p.rewardAmount = 0; // Incorrect predictions get nothing
                 }
            }
        }

        emit PredictionMarketResolved(newPhaseIndex, predictionMarketPool, totalCorrectStake);

        // Reset the pool for the next market
        predictionMarketPool = 0;
        // Note: Individual predictions remain stored for claiming.
    }


     /**
      * @notice Allows users to claim rewards from their correct, resolved predictions.
      */
    function claimPredictionRewards() external nonReentrant {
        uint256 totalClaimable = 0;
        uint256[] storage userPredIds = userPredictions[msg.sender];
        uint256[] memory claimableIds;

        for (uint256 i = 0; i < userPredIds.length; i++) {
             uint256 pId = userPredIds[i];
             Prediction storage p = predictions[pId];
             // Check if resolved, correct, and not yet claimed
             if (p.resolved && p.correct && !p.claimed) {
                 totalClaimable += p.rewardAmount;
                 claimableIds.push(pId); // Keep track of which ones to mark claimed
             }
        }

        require(totalClaimable > 0, "NoPredictionMade or NoRewardsClaimable");

        // Transfer total reward amount
         // Ensure contract has enough QNX (should come from prediction market pool, which was staked QNX)
        uint256 contractQNXBalance = qnxToken.balanceOf(address(this));
        if (contractQNXBalance < totalClaimable) {
             // This shouldn't happen if resolution logic is correct and QNX comes from staked pool
             // However, if fees are taken from pool, or rounding issues, could be deficit.
             // Handle defensively: mint or transfer what's available.
             uint256 actualTransfer = Math.min(totalClaimable, contractQNXBalance);
             qnxToken.safeTransfer(msg.sender, actualTransfer);
             // In a real system, log deficit or handle gracefully.
        } else {
            qnxToken.safeTransfer(msg.sender, totalClaimable);
        }


        // Mark claimed predictions
        for (uint256 i = 0; i < claimableIds.length; i++) {
            predictions[claimableIds[i]].claimed = true;
        }

        emit PredictionRewardsClaimed(msg.sender, totalClaimable);

        // Optional: Clean up userPredictions array - challenging to do efficiently in Solidity.
        // A cleaner approach might store prediction IDs in a linked list or use a different mapping structure.
        // For this example, leaving claimed predictions in the array is acceptable; they just won't be claimed again.
    }


    // --- Treasury & Governance ---

     /**
      * @notice Returns the amount of QNX currently held by the contract (Treasury).
      */
    function getTreasuryBalance() public view returns (uint256) {
        // The contract's own QNX balance serves as the treasury
        return qnxToken.balanceOf(address(this)) - predictionMarketPool; // Exclude QNX in prediction pool
    }

    /**
     * @notice Allows QNX holders above a threshold to submit a governance proposal.
     * @param proposalData Calldata for the function call to execute if the proposal passes.
     *                     (e.g., `abi.encodeWithSelector(this.updatePhaseParameters.selector, phaseIndex, newParams)`)
     */
    function submitGovernanceProposal(bytes memory proposalData) external nonReentrant returns (uint256 proposalId) {
        require(qnxToken.balanceOf(msg.sender) >= MIN_QNX_FOR_PROPOSAL, "InsufficientQNXForProposal");

        proposalId = nextProposalId++;
        GovernanceProposal storage proposal = governanceProposals[proposalId];

        proposal.proposer = msg.sender;
        proposal.proposalData = proposalData;
        proposal.totalVotesFor = 0;
        proposal.totalVotesAgainst = 0;
        proposal.submissionTime = uint64(block.timestamp);
        proposal.votingEndTime = uint64(block.timestamp) + VOTING_PERIOD;
        proposal.state = ProposalState.Active;

        emit GovernanceProposalSubmitted(proposalId, msg.sender);
    }

     /**
      * @notice Allows QNX holders to vote on an active proposal.
      * Votes are weighted by the voter's QNX balance at the time of voting.
      * @param proposalId The ID of the proposal to vote on.
      * @param support True for voting 'for', false for voting 'against'.
      */
    function voteOnProposal(uint256 proposalId, bool support) external nonReentrant onlyProposalState(proposalId, ProposalState.Active) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "AlreadyVoted");
        require(block.timestamp <= proposal.votingEndTime, "Proposal voting period ended");

        uint256 votes = qnxToken.balanceOf(msg.sender); // Use current QNX balance as voting power
        require(votes > 0, "Cannot vote with zero QNX");

        if (support) {
            proposal.totalVotesFor += votes;
        } else {
            proposal.totalVotesAgainst += votes;
        }

        proposal.hasVoted[msg.sender] = true;

        emit GovernanceVoteCast(proposalId, msg.sender, support, votes);
    }

    /**
     * @notice Executes a proposal if it has passed the voting threshold and quorum,
     * and the voting period has ended.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external nonReentrant onlyProposalState(proposalId, ProposalState.Active) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(block.timestamp > proposal.votingEndTime, "Proposal voting period not ended");

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        uint256 totalQNXSupply = qnxToken.totalSupply();

        // Check quorum: total votes cast must be at least QUORUM_PERCENT of total supply
        require(totalVotes * 100 >= totalQNXSupply * PROPOSAL_QUORUM_PERCENT, "Proposal quorum not met");

        // Check threshold: votes FOR must be at least THRESHOLD_PERCENT of total votes
        if (proposal.totalVotesFor * 100 >= totalVotes * PROPOSAL_THRESHOLD_PERCENT) {
            // Proposal Passed - Attempt execution
            proposal.state = ProposalState.Passed; // Mark as passed before execution attempt
            bytes memory data = proposal.proposalData;

            (bool success, ) = address(this).call(data); // Execute the proposal calldata

            if (success) {
                proposal.state = ProposalState.Executed;
                emit GovernanceProposalExecuted(proposalId);
            } else {
                 // Execution failed. Revert or mark as failed?
                 // Marking as failed might be better than reverting the whole tx.
                proposal.state = ProposalState.Failed; // Mark as failed on execution error
                // Potentially emit a ProposalExecutionFailed event
                revert("Proposal execution failed"); // Revert for simplicity in example
            }
        } else {
            // Proposal Failed
            proposal.state = ProposalState.Failed;
        }
    }

    // --- Utility / Read Functions ---

    /**
     * @notice Returns the total circulating supply of the QNX token.
     */
    function getQNXCirculatingSupply() public view returns (uint256) {
        return qnxToken.totalSupply();
    }

     /**
      * @notice Returns the total number of Position NFTs minted (which equals the number of active positions).
      */
    function getPositionNFTCount() public view returns (uint256) {
        return positionNFT.totalSupply();
    }

    /**
     * @notice Returns a list of token pairs supported for staking.
     * Note: Iterating through the mapping directly isn't possible. This relies on _supportedPairTokens list.
     * This list can contain duplicates if tokens appear in multiple pairs.
     * @return pairs Array of pairs [tokenA_1, tokenB_1, tokenA_2, tokenB_2, ...]
     */
    function getSupportedPairs() public view returns (address[] memory pairs) {
        uint256 count = 0;
         // Count unique pairs accurately requires iterating the mapping or a separate list of pairs
         // Using the token list is inaccurate for pairs, only lists individual tokens
         // Let's store pairs explicitly if this read function is needed.
         // For this example, we'll return a simplified view or state that this isn't easily iterable.
         // A better pattern is a mapping `bytes32 => bool` for existence and a separate `bytes32[]` for iteration.

         // Example of returning the raw token list for illustration of what's stored:
         // This is NOT a list of pairs. A user would need to reconstruct pairs off-chain.
         // Let's implement a bytes32[] for iteration.
         // Re-structuring required:
         // mapping(bytes32 => bool) public supportedPairs; // Hash => isSupported
         // bytes32[] private _supportedPairHashes; // List of hashes for iteration
         // Update addSupportedPair to push hash.

         // --- Re-implementing getSupportedPairs with a list of hashes ---
         bytes32[] memory pairHashes = new bytes32[](_supportedPairHashes.length);
         for (uint256 i = 0; i < _supportedPairHashes.length; i++) {
             pairHashes[i] = _supportedPairHashes[i];
         }
         // Cannot easily return address pairs from hash. A mapping `bytes32 => (address, address)` would be needed.
         // Let's stick to the simple `supportedPairs` mapping and note that iteration is off-chain,
         // or add a list of pairs like `(address, address)[] public supportedPairsList;`
         // Let's add the list of pairs for easy reading.

         // --- Re-structuring supported pairs state ---
         // mapping(bytes32 => bool) public supportedPairsLookup; // Hash => isSupported
         // (address, address)[] public supportedPairsList; // List of pairs

         // Let's revert to the initial plan of using a mapping and acknowledge the limitation,
         // or add the redundant list just for this function. Adding the redundant list is common
         // for simple iteration.

         // Revert: Use the simple mapping and state iteration isn't native.
         // Or, let's use the list of tokens as a proxy, but document it's not the pairs themselves.
         // Or, store the pairs in a list explicitly. Let's add the list.

         // --- Final Supported Pairs State Plan ---
         // mapping(bytes32 => bool) public supportedPairsLookup; // Hash => isSupported
         // (address tokenA, address tokenB)[] public supportedPairsArray; // List of pairs

         // Update addSupportedPair:
         // bytes32 pairHash = keccak256(abi.encodePacked(tokenA, tokenB));
         // supportedPairsLookup[pairHash] = true;
         // supportedPairsArray.push((tokenA, tokenB));

         // Update getSupportedPairs: Iterate supportedPairsArray

         // --- Back to implementing the function based on this plan ---
         // Assume supportedPairsLookup and supportedPairsArray exist and are populated by `addSupportedPair`
         // For the code completeness without re-writing struct/mapping names above:
         // Use `supportedPairs` as the lookup and add a new array `supportedPairsArray`.

         // Let's add the `supportedPairsArray` and update `addSupportedPair` (mentally or by adding it).
         // For the actual code provided, I'll stick to the simpler `supportedPairs` lookup
         // and explain the off-chain requirement or use the partial list of tokens.
         // Let's use the list of tokens `_supportedPairTokens` for illustration, but document it's not the pairs.

         address[] memory uniqueTokens = new address[](_supportedPairTokens.length);
         uint256 uniqueCount = 0;
         mapping(address => bool) seen;
         for(uint256 i=0; i<_supportedPairTokens.length; i++) {
             if (!seen[_supportedPairTokens[i]]) {
                 seen[_supportedPairTokens[i]] = true;
                 uniqueTokens[uniqueCount++] = _supportedPairTokens[i];
             }
         }
         address[] memory result = new address[](uniqueCount);
         for(uint256 i=0; i<uniqueCount; i++) {
             result[i] = uniqueTokens[i];
         }
         return result; // Returns list of unique tokens in supported pairs, not the pairs themselves.

         // Correct implementation requires a list of tuples: (address, address)[]
         // (address, address)[] memory actualPairs = new (address, address)[supportedPairsArray.length];
         // for(uint256 i=0; i<supportedPairsArray.length; i++) { actualPairs[i] = supportedPairsArray[i]; }
         // return actualPairs;
    }

     /**
      * @notice Returns a list of Position NFT IDs owned by a user.
      * Relies on ERC721Enumerable.
      * @param user The address of the user.
      * @return tokenIds Array of NFT IDs owned by the user.
      */
    function getUserPositions(address user) public view returns (uint256[] memory tokenIds) {
        uint256 balance = positionNFT.balanceOf(user);
        tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = positionNFT.tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

     /**
      * @notice Gets the details of a specific governance proposal.
      * @param proposalId The ID of the proposal.
      * @return proposalDetails Struct containing proposal information.
      */
    function getProposalDetails(uint256 proposalId) public view returns (GovernanceProposal memory proposalDetails) {
        require(governanceProposals[proposalId].proposer != address(0), "ProposalNotFound");
        return governanceProposals[proposalId];
    }

    // --- Internal Helper Functions ---
    // Placeholder for any complex internal logic like fee calculation,
    // dynamic NFT metadata URI generation (would be off-chain usually),
    // or more complex yield calculations.
}
```

Let's add the `supportedPairsArray` and modify `addSupportedPair` and `getSupportedPairs` for better clarity as discussed in the thinking process.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // To list NFTs by owner
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Mock/Interface for an Oracle feed. Replace with actual oracle implementation.
interface IQuantumOracle {
    function getMarketVolatilityIndex() external view returns (uint256 index);
    // Add other relevant data feeds if needed
}

// Custom ERC20 for QNX token
contract QNXToken is ERC20, Ownable { // Inherit Ownable here
    constructor(uint256 initialSupply) ERC20("QuantumNexus Token", "QNX") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply); // Mint initial supply to deployer (for treasury/initial distribution)
    }

    // Allow owner (the main contract) to mint
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Allow burn by anyone (e.g., for staking costs, if implemented)
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}

// Custom ERC721 for Position NFTs
contract PositionNFT is ERC721Enumerable, Ownable { // Inherit Ownable here
    constructor() ERC721("QuantumPosition NFT", "QPNFT") Ownable(msg.sender) {}

    // The main QuantumLiquidityNexus contract will have the minter role
    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    // Placeholder for dynamic metadata - off-chain renderer would use these details
    struct PositionDetails {
        address owner;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint64 stakeStartTime;
        uint64 lastYieldClaimTime;
        uint8 initialPhase;
        uint64 stakeDurationMultiplier; // Placeholder for bonuses
    }

    mapping(uint256 => PositionDetails) private _positionDetails;

    function setPositionDetails(uint256 tokenId, PositionDetails memory details) external onlyOwner {
        _positionDetails[tokenId] = details;
    }

    function getPositionDetails(uint256 tokenId) external view returns (PositionDetails memory) {
        require(_exists(tokenId), "QPNFT: token does not exist");
        return _positionDetails[tokenId];
    }

    // ERC721Enumerable requires implementation details, already handled by inheriting
    // Override _beforeTokenTransfer to potentially update metadata or checks on transfer
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Enumerable) {
    //     super._beforeTokenTransfer(from, to, tokenId);
    //     // Example: Update metadata or state if position is transferred
    // }
}


contract QuantumLiquidityNexus is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // --- Errors ---
    error InvalidTokenPair();
    error InsufficientLiquidityProvided();
    error PositionNotFound();
    error NothingToClaim();
    error InvalidPhaseIndex();
    error PredictionMarketNotResolvable();
    error AlreadyPredicted();
    error PredictionNotResolved();
    error NoPredictionMade();
    error ProposalNotFound();
    error ProposalNotActive();
    error AlreadyVoted();
    error InsufficientQNXForProposal();
    error ProposalNotExecutable();
    error InvalidOracle();
    error PositionNotOwned();
    error InvalidAmount();
    error UnsupportedPair();
    error PairAlreadySupported();


    // --- Enums ---
    enum PhaseState {
        Unknown,
        QuantumFluctuation, // High volatility, potentially higher rewards
        StableEquilibrium,  // Low volatility, potentially lower rewards, maybe higher fees
        CatalystEffect      // Triggered state, special rules/bonuses
    }

    enum ProposalState {
        Pending,
        Active,
        Passed,
        Failed,
        Executed
    }

    // --- Structs ---
    struct PhaseParameters {
        PhaseState state;
        uint256 baseQNXRatePerSec; // Base QNX emission rate per second per unit of liquidity value (scaled 1e18)
        uint256 feeMultiplier;     // Multiplier for protocol fees (scaled 1e18)
        uint256 oracleThreshold;   // Threshold value from oracle to trigger this phase (e.g., volatility index)
        uint256 predictionMultiplier; // Multiplier for prediction market rewards in this phase (scaled 1e18)
        uint64 duration;          // How long the phase typically lasts or cooldown (if phase is triggered manually)
    }

    struct LiquidityPosition {
        address owner;
        address tokenA;
        address tokenB;
        uint256 amountA; // Initial amount staked
        uint256 amountB; // Initial amount staked
        uint64 stakeStartTime;
        uint64 lastYieldClaimTime; // Timestamp of last yield claim or stake
        uint8 initialPhase;        // Index of phase when staked
        uint64 stakeDurationMultiplier; // Bonus multiplier for yield (scaled 1e18)
    }

    struct Prediction {
        address predictor;
        uint8 predictedPhaseIndex;
        uint256 qnxStaked;
        bool resolved;
        bool claimed;
        bool correct;
        uint256 rewardAmount; // Amount of QNX earned
    }

    struct GovernanceProposal {
        address proposer;
        bytes proposalData; // Calldata for execution (e.g., targeting this contract functions)
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        uint64 submissionTime;
        uint64 votingEndTime;
        ProposalState state;
        mapping(address => bool) hasVoted; // Ensure users vote only once
    }

    // --- State Variables ---
    QNXToken public immutable qnxToken;
    PositionNFT public immutable positionNFT;
    IQuantumOracle public quantumOracle;

    mapping(uint8 => PhaseParameters) public phaseConfigs;
    uint8 public currentPhaseIndex;
    uint64 public phaseTransitionTime; // Timestamp of the last phase transition
    uint66 public nextPositionId = 1; // Start token IDs from 1

    mapping(uint256 => LiquidityPosition) public liquidityPositions; // positionId => details

    mapping(bytes32 => bool) public supportedPairsLookup; // Hash of (tokenA, tokenB) => bool
    (address tokenA, address tokenB)[] public supportedPairsArray; // List of pairs for iteration

    uint256 public predictionMarketPool; // Total QNX staked in current prediction market
    uint64 public predictionMarketLastResolvedTime; // Timestamp when market was last resolved
    uint256 public nextPredictionId = 1;
    mapping(uint256 => Prediction) public predictions; // predictionId => details
    mapping(address => uint256[]) public userPredictions; // user => list of predictionIds (stores ALL predictions, claimed or not)

    uint256 public nextProposalId = 1;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public constant MIN_QNX_FOR_PROPOSAL = 100e18; // Example: 100 QNX to submit
    uint64 public constant VOTING_PERIOD = 3 days; // Example voting period
    uint256 public constant PROPOSAL_THRESHOLD_PERCENT = 51; // 51% of total votes to pass
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 10; // 10% of total QNX supply must vote


    // --- Events ---
    event OracleInitialized(address indexed oracleAddress);
    event SupportedPairAdded(address indexed tokenA, address indexed tokenB);
    event LiquidityStaked(address indexed user, uint256 positionId, address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event LiquidityUnstaked(address indexed user, uint256 positionId, uint256 amountA, uint256 amountB, uint256 qnxYield);
    event YieldClaimed(address indexed user, uint256 positionId, uint256 amount);
    event PhaseTransition(uint8 indexed oldPhaseIndex, uint8 indexed newPhaseIndex, PhaseState indexed newState, uint256 oracleData);
    event CatalystTriggered(address indexed user, uint8 indexed triggeredToPhaseIndex, uint256 qnxStaked); // triggeredToPhaseIndex might be different from newPhase if catalyst just forces check
    event PredictionMarketEntered(address indexed user, uint256 predictionId, uint8 predictedPhaseIndex, uint256 qnxAmount);
    event PredictionMarketResolved(uint8 indexed actualFinalPhaseIndex, uint256 totalPool, uint256 totalCorrectStake);
    event PredictionRewardsClaimed(address indexed user, uint256 totalRewardAmount);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event GovernanceProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---
    modifier onlySupportedPair(address tokenA, address tokenB) {
        bytes32 pairHash = keccak256(abi.encodePacked(_sortTokens(tokenA, tokenB)));
        require(supportedPairsLookup[pairHash], "UnsupportedPair");
        _;
    }

    modifier onlyProposalState(uint256 proposalId, ProposalState state) {
        require(governanceProposals[proposalId].state == state, "Proposal in wrong state");
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialQNXSupply, address initialOracle, PhaseParameters[] memory initialPhases) Ownable(msg.sender) {
        qnxToken = new QNXToken(initialQNXSupply);
        positionNFT = new PositionNFT();

        // Transfer token ownerships to this contract
        qnxToken.transferOwnership(address(this));
        positionNFT.transferOwnership(address(this));

        // Configure initial phases
        require(initialPhases.length > 0, "Must provide initial phases");
        for (uint8 i = 0; i < initialPhases.length; i++) {
            phaseConfigs[i] = initialPhases[i];
        }
        currentPhaseIndex = 0; // Start with the first phase
        phaseTransitionTime = uint64(block.timestamp);
        predictionMarketLastResolvedTime = uint64(block.timestamp); // Reset prediction market

        // Set initial oracle if provided
        if (initialOracle != address(0)) {
            initializeOracle(initialOracle);
        }

        // Example: add some initial supported pairs
        // addSupportedPair(0x...TokenA..., 0x...TokenB...);
        // addSupportedPair(0x...TokenC..., 0x...TokenD...);
    }

    // --- Initialization ---
    function initializeOracle(address oracleAddress) public onlyOwner {
        require(oracleAddress != address(0), "InvalidOracle");
        quantumOracle = IQuantumOracle(oracleAddress);
        emit OracleInitialized(oracleAddress);
    }

    function addSupportedPair(address tokenA, address tokenB) public onlyOwner {
        require(tokenA != address(0) && tokenB != address(0) && tokenA != tokenB, "InvalidTokenPair");
        // Ensure tokenA is always the smaller address for canonical representation
        (address tA, address tB) = _sortTokens(tokenA, tokenB);
        bytes32 pairHash = keccak256(abi.encodePacked(tA, tB));
        require(!supportedPairsLookup[pairHash], "PairAlreadySupported");

        supportedPairsLookup[pairHash] = true;
        supportedPairsArray.push((tA, tB)); // Store the sorted pair
        emit SupportedPairAdded(tA, tB);
    }

    // --- Liquidity Staking ---

    /**
     * @notice Stakes a balanced amount of a supported token pair to earn QNX yield.
     * Mints a PositionNFT representing the staked position.
     * @param tokenA Address of the first token in the pair.
     * @param tokenB Address of the second token in the pair.
     * @param amountA Amount of tokenA to stake.
     * @param amountB Amount of tokenB to stake.
     */
    function stakeLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external nonReentrant onlySupportedPair(tokenA, tokenB) {
        require(amountA > 0 && amountB > 0, "InsufficientLiquidityProvided");

        // Ensure tokenA is always the smaller address for canonical representation
        (address tA, address tB) = _sortTokens(tokenA, tokenB);
        // Re-check supported pair after potential swap
        bytes32 pairHash = keccak256(abi.encodePacked(tA, tB));
        require(supportedPairsLookup[pairHash], "UnsupportedPair");


        // Transfer tokens from user to contract
        IERC20(tA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tB).safeTransferFrom(msg.sender, address(this), amountB);

        uint256 positionId = nextPositionId++;
        uint64 currentTime = uint64(block.timestamp);

        LiquidityPosition memory newPosition = LiquidityPosition({
            owner: msg.sender,
            tokenA: tA, // Store sorted addresses
            tokenB: tB,
            amountA: amountA,
            amountB: amountB,
            stakeStartTime: currentTime,
            lastYieldClaimTime: currentTime, // Start yield accrual now
            initialPhase: currentPhaseIndex,
            stakeDurationMultiplier: 1e18 // Start with 1x multiplier (scaled)
        });

        liquidityPositions[positionId] = newPosition;

        // Mint Position NFT to user and set details
        positionNFT.mint(msg.sender, positionId);
        positionNFT.setPositionDetails(positionId, PositionNFT.PositionDetails({
             owner: msg.sender,
             tokenA: tA,
             tokenB: tB,
             amountA: amountA,
             amountB: amountB,
             stakeStartTime: currentTime,
             lastYieldClaimTime: currentTime,
             initialPhase: currentPhaseIndex,
             stakeDurationMultiplier: 1e18 // Start with 1x multiplier (scaled)
        }));

        emit LiquidityStaked(msg.sender, positionId, tA, tB, amountA, amountB);
    }

    /**
     * @notice Burns a PositionNFT to unstake liquidity and claim principal + accrued yield.
     * @param positionId The ID of the PositionNFT to burn.
     */
    function unstakeLiquidity(uint256 positionId) external nonReentrant {
        LiquidityPosition storage pos = liquidityPositions[positionId];
        require(pos.owner != address(0), "PositionNotFound");
        require(pos.owner == msg.sender, "PositionNotOwned");

        // Calculate pending yield before unstaking
        uint256 pendingYield = _calculateYield(positionId);

        // Transfer principal back
        IERC20(pos.tokenA).safeTransfer(msg.sender, pos.amountA);
        IERC20(pos.tokenB).safeTransfer(msg.sender, pos.amountB);

        // Transfer accrued QNX yield
        if (pendingYield > 0) {
            // QNX for rewards is minted on demand in this example for simplicity.
            // In a real system, it might come from fees, staking rewards pool, etc.
             qnxToken.mint(address(this), pendingYield); // Mint QNX to contract first
             qnxToken.safeTransfer(msg.sender, pendingYield);
        }

        // Burn the Position NFT
        positionNFT.burn(positionId);

        // Clean up state
        delete liquidityPositions[positionId];

        emit LiquidityUnstaked(msg.sender, positionId, pos.amountA, pos.amountB, pendingYield);
    }

    /**
     * @notice Claims accrued QNX yield for a specific staked position without unstaking principal.
     * Updates the last claim time for the position.
     * @param positionId The ID of the PositionNFT.
     */
    function claimYield(uint256 positionId) external nonReentrant {
        LiquidityPosition storage pos = liquidityPositions[positionId];
        require(pos.owner != address(0), "PositionNotFound");
        require(pos.owner == msg.sender, "PositionNotOwned");

        uint256 pendingYield = _calculateYield(positionId);
        require(pendingYield > 0, "NothingToClaim");

        uint64 currentTime = uint64(block.timestamp);

        // Mint QNX to contract first, then transfer
        qnxToken.mint(address(this), pendingYield);
        qnxToken.safeTransfer(msg.sender, pendingYield);

        // Update last claim time to now
        pos.lastYieldClaimTime = currentTime;

        emit YieldClaimed(msg.sender, positionId, pendingYield);
    }

     /**
      * @notice Allows extending stake duration. Placeholder for potential bonuses.
      * @param positionId The ID of the PositionNFT.
      * @param additionalDuration Placeholder for future duration logic.
      */
    function extendPositionStake(uint256 positionId, uint256 additionalDuration) external {
        LiquidityPosition storage pos = liquidityPositions[positionId];
        require(pos.owner != address(0), "PositionNotFound");
        require(pos.owner == msg.sender, "PositionNotOwned");
        // TODO: Implement logic to update stakeDurationMultiplier or other parameters
        // based on additionalDuration commitment. This could involve locking the position
        // or adding conditions to unstaking.
        // For now, this is just a placeholder function.
        revert("Extend stake not yet fully implemented");
    }


    // --- Yield Calculation ---
    // NOTE: Yield calculation logic is a simplified example. A real system
    // would need a more robust way to track yield accrual across dynamic phases,
    // potentially using checkpoints or integral calculations over time periods in different phases.
    function _calculateYield(uint256 positionId) internal view returns (uint256) {
        LiquidityPosition storage pos = liquidityPositions[positionId];
        if (pos.owner == address(0) || pos.lastYieldClaimTime == uint64(block.timestamp)) {
            return 0; // No position or yield already claimed for this second
        }

        // Simplified approach: Calculate yield based on the CURRENT phase rate
        // and the time elapsed since last claim/stake. This doesn't account
        // for phase changes *between* last claim and now, which is a complex
        // state-dependent yield accrual problem.
        // A more advanced system would track `(phaseIndex, startTime, endTime)` intervals
        // and sum up yield per interval.

        PhaseParameters storage currentParams = phaseConfigs[currentPhaseIndex];

        // A simplistic "value" representation for the position - amountA
        uint256 liquidityUnits = pos.amountA;

        uint256 timeElapsed = uint256(block.timestamp) - pos.lastYieldClaimTime;

        // base QNX / sec / unit * units * time elapsed * duration multiplier
        // Assume baseQNXRatePerSec and stakeDurationMultiplier are scaled by 1e18
        uint256 rawYield = (currentParams.baseQNXRatePerSec * liquidityUnits).mul(timeElapsed).mul(pos.stakeDurationMultiplier) / (1e18 * 1e18);

        // Add bonus for initial phase? Or phases experienced? Complex logic omitted for example length.

        return rawYield;
    }

    /**
     * @notice Calculates and returns the current estimated annual percentage yield for a specific token pair.
     * Returns QNX per unit of tokenA staked per year (scaled by 1e18).
     * Frontend needs QNX and token prices to convert to APY %.
     * @param tokenA Address of the first token.
     * @param tokenB Address of the second token.
     * @return qnxPerTokenAStakedPerYear_1e18 Annual QNX emission rate per staked tokenA, scaled by 1e18.
     */
    function getAPY(address tokenA, address tokenB) public view onlySupportedPair(tokenA, tokenB) returns (uint256 qnxPerTokenAStakedPerYear_1e18) {
        // Ensure tokenA is always the smaller address
        (address tA, address tB) = _sortTokens(tokenA, tokenB);
        bytes32 pairHash = keccak256(abi.encodePacked(tA, tB));
        require(supportedPairsLookup[pairHash], "UnsupportedPair");

        PhaseParameters storage currentParams = phaseConfigs[currentPhaseIndex];

        // The rate `baseQNXRatePerSec` is QNX per second *per unit*.
        // Assuming 1 unit of liquidity value is represented by 1 tokenA.
        // Annual Rate (scaled) = `baseQNXRatePerSec` * 31536000 (seconds in year)
        // This is QNX emission rate per tokenA staked per year, scaled by 1e18.
        // Frontend calculation: APY % = (qnxPerTokenAStakedPerYear_1e18 / 1e18) * Price_of_QNX / Price_of_TokenA * 100
        return (currentParams.baseQNXRatePerSec * 31536000e18) / 1e18;
    }

    /**
     * @notice Calculates and returns the currently accrued QNX yield for a staked position.
     * @param positionId The ID of the PositionNFT.
     * @return accruedYield Amount of QNX accrued.
     */
    function getAccruedYield(uint256 positionId) public view returns (uint256 accruedYield) {
        return _calculateYield(positionId);
    }

    // --- Phase Management ---

    /**
     * @notice Reads the oracle data and potentially triggers a phase transition
     * if thresholds are met. Anyone can call this (permissionless update).
     */
    function updatePhaseFromOracle() external nonReentrant {
        require(address(quantumOracle) != address(0), "InvalidOracle");

        uint256 volatilityIndex = quantumOracle.getMarketVolatilityIndex(); // Example oracle data

        uint8 oldPhaseIndex = currentPhaseIndex;
        uint8 newPhaseIndex = currentPhaseIndex;

        // Simple phase transition logic based on volatility index thresholds.
        // Iterates through configured phases to find a match.
        // Assumes phaseConfigs are ordered such that higher index means different state.
        // A more robust system would have clearer threshold ranges or use hysteresis.
        for (uint8 i = 0; i < 255; i++) { // Iterate up to 255 phases
            PhaseParameters storage params = phaseConfigs[i];
            if (params.state == PhaseState.Unknown) break; // Stop if phase not configured

            // Exclude Catalyst phase from automatic oracle transitions
            if (params.state != PhaseState.CatalystEffect) {
                // Simple check: If index > threshold, this phase is a candidate
                // This needs refinement for ranges (e.g., threshold_low < index < threshold_high)
                if (volatilityIndex >= params.oracleThreshold) {
                     newPhaseIndex = i; // This is a candidate. If multiple match, the last one wins (basic logic)
                }
            }
        }
        // Add logic: If no threshold was met, maybe revert to a default phase (e.g., phase 0)
        // If newPhaseIndex is still the old one after checking all thresholds, no transition happens by oracle.
        // This simple logic transitions to the *highest index* phase whose threshold is met.

        // Only transition if it's a different phase and not currently in a Catalyst state
        if (currentPhaseIndex != newPhaseIndex && phaseConfigs[currentPhaseIndex].state != PhaseState.CatalystEffect) {
            currentPhaseIndex = newPhaseIndex;
            phaseTransitionTime = uint64(block.timestamp);

            // Resolve prediction market based on *transition*
            _resolvePredictionMarket(oldPhaseIndex, newPhaseIndex);
             predictionMarketLastResolvedTime = uint64(block.timestamp); // Start new prediction window

            emit PhaseTransition(oldPhaseIndex, newPhaseIndex, phaseConfigs[newPhaseIndex].state, volatilityIndex);
        }
         // If phase didn't change, but prediction market window is over, resolve it assuming no change
        else if (block.timestamp >= predictionMarketLastResolvedTime + phaseConfigs[oldPhaseIndex].duration) {
             _resolvePredictionMarket(oldPhaseIndex, oldPhaseIndex); // Resolve market assuming no change occurred
             predictionMarketLastResolvedTime = uint64(block.timestamp); // Start new prediction window
        }
    }

    /**
     * @notice Allows users to stake QNX to potentially trigger a phase transition,
     * often to a special 'Catalyst' phase or forcing an oracle check.
     * This example implements a transition to a specific Catalyst phase if configured.
     * @param requiredQNXStake The amount of QNX the caller must stake.
     * @param targetCatalystPhaseIndex The index of the desired Catalyst phase.
     */
    function triggerCatalystEvent(uint256 requiredQNXStake, uint8 targetCatalystPhaseIndex) external nonReentrant {
        require(requiredQNXStake > 0, "InvalidAmount");
        require(phaseConfigs[targetCatalystPhaseIndex].state == PhaseState.CatalystEffect, "InvalidPhaseIndex or Not a Catalyst Phase");

        // Transfer QNX stake to treasury/contract
        qnxToken.safeTransferFrom(msg.sender, address(this), requiredQNXStake);

        uint8 oldPhaseIndex = currentPhaseIndex;
        uint8 newPhaseIndex = targetCatalystPhaseIndex; // Direct transition to specified catalyst phase

        // Only transition if not already in the target catalyst phase
        if (currentPhaseIndex != newPhaseIndex) {
            currentPhaseIndex = newPhaseIndex;
            phaseTransitionTime = uint64(block.timestamp);
            // Resolve prediction market based on this transition
            _resolvePredictionMarket(oldPhaseIndex, newPhaseIndex);
            predictionMarketLastResolvedTime = uint64(block.timestamp); // Start new prediction window

            emit CatalystTriggered(msg.sender, newPhaseIndex, requiredQNXStake);
             emit PhaseTransition(oldPhaseIndex, newPhaseIndex, phaseConfigs[newPhaseIndex].state, 0); // Oracle data is 0 for catalyst trigger
        } else {
             // Already in the target catalyst phase, QNX goes to treasury, but no state change event
        }
    }

    /**
     * @notice Get details of the current phase.
     */
    function getCurrentPhase() public view returns (uint8 phaseIndex, PhaseParameters memory params) {
        return (currentPhaseIndex, phaseConfigs[currentPhaseIndex]);
    }

    /**
     * @notice Get details of a specific phase.
     */
    function getPhaseParameters(uint8 phaseIndex) public view returns (PhaseParameters memory) {
        require(phaseConfigs[phaseIndex].state != PhaseState.Unknown, "InvalidPhaseIndex");
        return phaseConfigs[phaseIndex];
    }

     /**
      * @notice Get current raw data from the oracle (example).
      */
    function getCurrentOracleData() public view returns (uint256 volatilityIndex) {
        require(address(quantumOracle) != address(0), "InvalidOracle");
        return quantumOracle.getMarketVolatilityIndex();
    }


    // --- Prediction Market ---

    /**
     * @notice Allows users to stake QNX and predict the index of the next phase.
     * Can only be entered during an active prediction window.
     * @param predictedPhaseIndex The index of the phase the user predicts will be the next phase.
     * @param qnxAmount The amount of QNX to stake on this prediction.
     */
    function enterPredictionMarket(uint8 predictedPhaseIndex, uint256 qnxAmount) external nonReentrant {
        require(qnxAmount > 0, "InvalidAmount");
        require(phaseConfigs[predictedPhaseIndex].state != PhaseState.Unknown, "InvalidPhaseIndex"); // Must predict a valid configured phase

        // Can only enter if the prediction market related to the *current* phase hasn't been resolved yet.
        // The market for the *next* transition opens when the previous one is resolved.
        require(block.timestamp < predictionMarketLastResolvedTime + phaseConfigs[currentPhaseIndex].duration, "Prediction market window closed");

        qnxToken.safeTransferFrom(msg.sender, address(this), qnxAmount);

        uint256 predictionId = nextPredictionId++;
        predictions[predictionId] = Prediction({
            predictor: msg.sender,
            predictedPhaseIndex: predictedPhaseIndex,
            qnxStaked: qnxAmount,
            resolved: false,
            claimed: false,
            correct: false,
            rewardAmount: 0
        });

        userPredictions[msg.sender].push(predictionId);
        predictionMarketPool += qnxAmount;

        emit PredictionMarketEntered(msg.sender, predictionId, predictedPhaseIndex, qnxAmount);
    }

     /**
      * @notice Internal function to resolve the prediction market based on a phase transition outcome.
      * Called automatically by phase transition functions.
      * @param oldPhaseIndex The phase index before the transition.
      * @param newPhaseIndex The phase index after the transition.
      */
    function _resolvePredictionMarket(uint8 oldPhaseIndex, uint8 newPhaseIndex) internal {
        // Only resolve if the market window associated with the OLD phase has ended or a transition occurred
        if (predictionMarketPool == 0 || (block.timestamp < predictionMarketLastResolvedTime + phaseConfigs[oldPhaseIndex].duration && oldPhaseIndex == newPhaseIndex) ) {
             // No staked QNX OR the market window for the OLD phase is still active AND no transition happened.
             // Don't resolve yet.
             return;
        }


        uint256 totalCorrectStake = 0;
        uint256[] memory predictionIdsToResolve = new uint256[](0); // Collect IDs to resolve

        // Iterate through ALL predictions that haven't been resolved yet
        // Note: Iterating this way can be gas-intensive if nextPredictionId is very large.
        // A better pattern might track active prediction IDs specifically.
        for (uint256 i = 1; i < nextPredictionId; i++) {
            if (!predictions[i].resolved) {
                 predictionIdsToResolve.push(i);
            }
        }

        for (uint256 i = 0; i < predictionIdsToResolve.length; i++) {
             uint256 pId = predictionIdsToResolve[i];
            Prediction storage p = predictions[pId];

            p.resolved = true;
            // Check if prediction was correct.
            // Prediction is correct if predictedPhaseIndex == the ACTUAL newPhaseIndex
            if (p.predictedPhaseIndex == newPhaseIndex) {
                p.correct = true;
                totalCorrectStake += p.qnxStaked;
            }
        }

        // Calculate rewards for correct predictions
        if (totalCorrectStake > 0) {
            uint256 totalRewardAmount = predictionMarketPool; // Total QNX staked in the market

            for (uint256 i = 0; i < predictionIdsToResolve.length; i++) {
                 uint256 pId = predictionIdsToResolve[i];
                 Prediction storage p = predictions[pId];
                 if (p.correct) {
                     // reward = (staked_by_user / total_correct_stake) * total_pool * prediction_multiplier
                     // Use prediction multiplier from the phase that was PREDICTED to add game-theory element?
                     // Or use the multiplier from the NEW phase that actually occurred?
                     // Let's use the multiplier from the NEW phase for simplicity.
                     uint256 multiplier = phaseConfigs[newPhaseIndex].predictionMultiplier; // Scaled by 1e18
                     p.rewardAmount = (p.qnxStaked * totalRewardAmount * multiplier) / (totalCorrectStake * 1e18); // Apply multiplier
                 } else {
                     p.rewardAmount = 0; // Incorrect predictions get nothing
                 }
            }
        }

        emit PredictionMarketResolved(newPhaseIndex, predictionMarketPool, totalCorrectStake);

        // Reset the pool for the next market
        predictionMarketPool = 0;
        // Note: Individual predictions remain stored for claiming.
    }


     /**
      * @notice Allows users to claim rewards from their correct, resolved predictions.
      */
    function claimPredictionRewards() external nonReentrant {
        uint256 totalClaimable = 0;
        uint256[] storage userPredIds = userPredictions[msg.sender];
        // Need a temporary list because we modify the state (p.claimed) inside the loop
        uint256[] memory claimableIds = new uint256[](userPredIds.length);
        uint256 claimableCount = 0;


        for (uint256 i = 0; i < userPredIds.length; i++) {
             uint256 pId = userPredIds[i];
             // Ensure pId is valid (not 0 if using 0 as invalid)
             if (pId > 0 && pId < nextPredictionId) {
                 Prediction storage p = predictions[pId];
                 // Check if resolved, correct, and not yet claimed, and belongs to caller
                 if (p.resolved && p.correct && !p.claimed && p.predictor == msg.sender) {
                     totalClaimable += p.rewardAmount;
                     claimableIds[claimableCount++] = pId; // Store ID for marking as claimed
                 }
             }
        }

        require(totalClaimable > 0, "NoPredictionMade or NoRewardsClaimable");

        // Transfer total reward amount
        // QNX for prediction rewards comes from the staked pool initially.
        // Ensure contract has enough QNX.
        uint256 contractQNXBalance = qnxToken.balanceOf(address(this));
        require(contractQNXBalance >= totalClaimable, "Insufficient contract QNX for rewards"); // Should not happen with correct logic

        qnxToken.safeTransfer(msg.sender, totalClaimable);

        // Mark claimed predictions
        for (uint256 i = 0; i < claimableCount; i++) {
            predictions[claimableIds[i]].claimed = true;
        }

        emit PredictionRewardsClaimed(msg.sender, totalClaimable);

        // Optional: Clean up userPredictions array. Leaving it grows state but is simpler.
        // A better approach for production is to use a more gas-efficient data structure or paginate.
    }


    // --- Treasury & Governance ---

     /**
      * @notice Returns the amount of QNX currently held by the contract (Treasury).
      * Excludes QNX currently locked in the active prediction market pool.
      */
    function getTreasuryBalance() public view returns (uint256) {
        // The contract's own QNX balance serves as the treasury
        uint256 totalBalance = qnxToken.balanceOf(address(this));
        // Subtract the prediction market pool
        return totalBalance >= predictionMarketPool ? totalBalance - predictionMarketPool : 0;
    }

    /**
     * @notice Allows QNX holders above a threshold to submit a governance proposal.
     * @param proposalData Calldata for the function call to execute if the proposal passes.
     *                     Target address for the call is *this* contract.
     *                     (e.g., `abi.encodeWithSelector(this.updatePhaseParameters.selector, phaseIndex, newParams)`)
     */
    function submitGovernanceProposal(bytes memory proposalData) external nonReentrant returns (uint256 proposalId) {
        require(qnxToken.balanceOf(msg.sender) >= MIN_QNX_FOR_PROPOSAL, "InsufficientQNXForProposal");
        require(proposalData.length > 0, "Proposal data empty");

        proposalId = nextProposalId++;
        GovernanceProposal storage proposal = governanceProposals[proposalId];

        proposal.proposer = msg.sender;
        proposal.proposalData = proposalData;
        proposal.totalVotesFor = 0;
        proposal.totalVotesAgainst = 0;
        proposal.submissionTime = uint64(block.timestamp);
        proposal.votingEndTime = uint64(block.timestamp) + VOTING_PERIOD;
        proposal.state = ProposalState.Active;

        emit GovernanceProposalSubmitted(proposalId, msg.sender);
    }

     /**
      * @notice Allows QNX holders to vote on an active proposal.
      * Votes are weighted by the voter's QNX balance at the time of voting.
      * @param proposalId The ID of the proposal to vote on.
      * @param support True for voting 'for', false for voting 'against'.
      */
    function voteOnProposal(uint256 proposalId, bool support) external nonReentrant onlyProposalState(proposalId, ProposalState.Active) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "AlreadyVoted");
        require(block.timestamp <= proposal.votingEndTime, "Proposal voting period ended");

        uint256 votes = qnxToken.balanceOf(msg.sender); // Use current QNX balance as voting power
        require(votes > 0, "Cannot vote with zero QNX");

        if (support) {
            proposal.totalVotesFor += votes;
        } else {
            proposal.totalVotesAgainst += votes;
        }

        proposal.hasVoted[msg.sender] = true;

        emit GovernanceVoteCast(proposalId, msg.sender, support, votes);
    }

    /**
     * @notice Executes a proposal if it has met the required voting threshold and quorum,
     * and the voting period has ended.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external nonReentrant onlyProposalState(proposalId, ProposalState.Active) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(block.timestamp > proposal.votingEndTime, "Proposal voting period not ended");

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        uint256 totalQNXSupply = qnxToken.totalSupply();

        // Check quorum: total votes cast must be at least QUORUM_PERCENT of total supply
        // Handle totalQNXSupply being 0 initially
        bool quorumMet = totalQNXSupply == 0 ? (totalVotes > 0) : (totalVotes * 100 >= totalQNXSupply * PROPOSAL_QUORUM_PERCENT);
        require(quorumMet, "Proposal quorum not met");


        // Check threshold: votes FOR must be strictly greater than votes AGAINST for >50%
        bool thresholdMet = proposal.totalVotesFor * 100 >= totalVotes * PROPOSAL_THRESHOLD_PERCENT;


        if (thresholdMet) {
            // Proposal Passed - Attempt execution
            proposal.state = ProposalState.Passed; // Mark as passed before execution attempt
            bytes memory data = proposal.proposalData;

            // Use call to execute the proposal data on *this* contract
            (bool success, ) = address(this).call(data);

            if (success) {
                proposal.state = ProposalState.Executed;
                emit GovernanceProposalExecuted(proposalId);
            } else {
                 // Execution failed.
                proposal.state = ProposalState.Failed; // Mark as failed on execution error
                revert("Proposal execution failed"); // Revert the transaction on failure
            }
        } else {
            // Proposal Failed
            proposal.state = ProposalState.Failed;
        }
    }

    // --- Callable by Governance Proposal ---
    // These functions demonstrate what governance could control.

    /**
     * @notice Updates parameters for a specific phase. Callable only via governance.
     * @param phaseIndex The index of the phase to update.
     * @param newParams The new parameters for the phase.
     */
    function updatePhaseParameters(uint8 phaseIndex, PhaseParameters memory newParams) external {
        // Ensure this function is only callable by the contract itself (via `call` in executeProposal)
        require(msg.sender == address(this), "Only callable by governance");
        require(phaseConfigs[phaseIndex].state != PhaseState.Unknown, "InvalidPhaseIndex");
        phaseConfigs[phaseIndex] = newParams;
        // Consider emitting an event here
    }

     /**
      * @notice Transfers QNX from the treasury to a recipient. Callable only via governance.
      * @param recipient The address to send QNX to.
      * @param amount The amount of QNX to send.
      */
    function transferTreasuryQNX(address recipient, uint256 amount) external {
        require(msg.sender == address(this), "Only callable by governance");
        require(recipient != address(0), "Invalid recipient");
        qnxToken.safeTransfer(recipient, amount);
        // Consider emitting an event here
    }

    // --- Utility / Read Functions ---

    /**
     * @notice Returns the total circulating supply of the QNX token.
     */
    function getQNXCirculatingSupply() public view returns (uint256) {
        return qnxToken.totalSupply();
    }

     /**
      * @notice Returns the total number of Position NFTs minted (which equals the number of active positions).
      */
    function getPositionNFTCount() public view returns (uint256) {
        return positionNFT.totalSupply();
    }

    /**
     * @notice Returns the list of supported token pairs for staking.
     * Returns pairs as an array of tuples (tokenA, tokenB).
     */
    function getSupportedPairs() public view returns ((address, address)[] memory) {
         (address tokenA, address tokenB)[] memory pairs = new (address, address)[](supportedPairsArray.length);
         for(uint256 i=0; i<supportedPairsArray.length; i++) {
             pairs[i] = supportedPairsArray[i];
         }
         return pairs;
    }

     /**
      * @notice Returns a list of Position NFT IDs owned by a user.
      * Relies on ERC721Enumerable.
      * @param user The address of the user.
      * @return tokenIds Array of NFT IDs owned by the user.
      */
    function getUserPositions(address user) public view returns (uint256[] memory tokenIds) {
        uint256 balance = positionNFT.balanceOf(user);
        tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = positionNFT.tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

     /**
      * @notice Gets the details of a specific governance proposal.
      * @param proposalId The ID of the proposal.
      * @return proposalDetails Struct containing proposal information.
      */
    function getProposalDetails(uint256 proposalId) public view returns (GovernanceProposal memory proposalDetails) {
        require(proposalId > 0 && proposalId < nextProposalId, "ProposalNotFound");
        // Copy struct to memory for returning
        GovernanceProposal storage p = governanceProposals[proposalId];
        return GovernanceProposal({
            proposer: p.proposer,
            proposalData: p.proposalData,
            totalVotesFor: p.totalVotesFor,
            totalVotesAgainst: p.totalVotesAgainst,
            submissionTime: p.submissionTime,
            votingEndTime: p.votingEndTime,
            state: p.state,
            // hasVoted mapping is not returned directly in a public view function
            hasVoted: mapping(address => bool)(0) // Placeholder, mapping state cannot be returned directly
        });
    }

    /**
     * @notice Gets the details of a specific prediction made by ID.
     * @param predictionId The ID of the prediction.
     * @return predictionDetails Struct containing prediction information.
     */
    function getPredictionDetails(uint256 predictionId) public view returns (Prediction memory predictionDetails) {
        require(predictionId > 0 && predictionId < nextPredictionId, "PredictionNotFound");
         Prediction storage p = predictions[predictionId];
         // Copy struct to memory for returning
         return Prediction({
             predictor: p.predictor,
             predictedPhaseIndex: p.predictedPhaseIndex,
             qnxStaked: p.qnxStaked,
             resolved: p.resolved,
             claimed: p.claimed,
             correct: p.correct,
             rewardAmount: p.rewardAmount
         });
    }

    /**
     * @notice Gets the list of all prediction IDs associated with a user.
     * @param user The address of the user.
     * @return predictionIds Array of prediction IDs.
     */
    function getUserPredictionIds(address user) public view returns (uint256[] memory) {
        uint256[] storage userPreds = userPredictions[user];
        uint256[] memory result = new uint256[](userPreds.length);
        for(uint256 i=0; i<userPreds.length; i++) {
            result[i] = userPreds[i];
        }
        return result;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Sorts two token addresses canonically.
     * @param tokenA Address of the first token.
     * @param tokenB Address of the second token.
     * @return (address, address) Tuple containing the sorted addresses (tokenA, tokenB) where tokenA < tokenB.
     */
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

     /**
      * @dev Calculates the scaled price of a token pair relative to a base currency (e.g., USD or ETH).
      * This is a placeholder and would require actual price feeds integrated.
      * @param tokenA Address of token A.
      * @param tokenB Address of token B.
      * @return price_1e18 Scaled price (placeholder).
      */
    function _getPairPriceValue(address tokenA, address tokenB) internal view returns (uint256 price_1e18) {
        // In a real system, this would use oracle price feeds for tokenA and tokenB
        // and calculate the value of amountA+amountB in USD or ETH.
        // For example: price = (amountA * price_A + amountB * price_B) / Scaling Factor
        // Here, for simplicity, we'll return a fixed placeholder value or base it simply on one token amount.
        // This impacts the APY calculation's potential accuracy.

        // Simple Placeholder: Assume 1 unit of liquidity value is just 1 tokenA
        // This is a very basic assumption.
        return 1e18; // Represents 1 unit of value scaled by 1e18
    }
}
```

**Explanation and Advanced Concepts Used:**

1.  **Dynamic State/Phases:** The contract isn't static. Its core parameters (yield rate, fees - though fees are just a multiplier placeholder in this code) change based on an internal `currentPhaseIndex`.
2.  **Oracle Integration:** Demonstrates how a contract can interact with external data (`IQuantumOracle`) to influence its on-chain state (`updatePhaseFromOracle`).
3.  **Dynamic NFTs (Conceptual):** `PositionNFT` stores detailed staking information (`PositionDetails`). While the ERC721 metadata URI logic isn't fully implemented here (it's typically off-chain), the structure supports an external renderer using `getPositionDetails` to create dynamic NFT visuals or properties that change based on stake duration, current phase, initial phase, etc.
4.  **Internal Prediction Market:** A mini game-theory mechanism where users stake native tokens (`QNX`) to predict phase changes, adding another layer of interaction and utility for the token. The market resolution (`_resolvePredictionMarket`) and reward distribution (`claimPredictionRewards`) happen within the contract.
5.  **Native Token Utility:** `QNX` serves multiple purposes: yield rewards, staking for prediction market, governance voting power, and a cost for triggering catalyst events.
6.  **Simple Governance:** A basic on-chain voting system (`submitGovernanceProposal`, `voteOnProposal`, `executeProposal`) allows QNX holders to influence the protocol (demonstrated by `updatePhaseParameters` and `transferTreasuryQNX` being callable only by the contract itself via `call`). This shows a common pattern for protocol upgrades or treasury management.
7.  **ReentrancyGuard:** Used in sensitive functions (`stakeLiquidity`, `unstakeLiquidity`, `claimYield`, `enterPredictionMarket`, `claimPredictionRewards`, `submitGovernanceProposal`, `voteOnProposal`, `executeProposal`) to prevent reentrancy attacks, which are crucial in DeFi contracts handling asset transfers.
8.  **SafeERC20:** Used for ERC20 interactions (`safeTransfer`, `safeTransferFrom`) to prevent issues with tokens that don't properly return booleans or have other non-standard behavior.
9.  **Canonical Pair Representation:** Using `_sortTokens` and hashing (`keccak256`) ensures that token pairs are stored and looked up consistently regardless of the input order (e.g., WETH/DAI is treated the same as DAI/WETH).
10. **ERC721Enumerable:** Allows iterating through the list of NFTs owned by a user, which is useful for retrieving all their positions.
11. **Structs and Mappings:** Extensive use of structs to group related data (`PhaseParameters`, `LiquidityPosition`, etc.) and mappings for efficient lookups by ID or address.
12. **Gas Efficiency Considerations (Acknowledged Limitations):** While building, some areas were noted as potentially gas-intensive for a real-world deployment with large state (e.g., iterating all predictions in `_resolvePredictionMarket`, the state growth of `userPredictions`). A production system might employ techniques like pagination, linked lists, or external subgraph indexing for reads.

This contract is a conceptual blend of several advanced DeFi and NFT patterns. It is not audited or production-ready but demonstrates creative ways to combine features and create a dynamic protocol state.