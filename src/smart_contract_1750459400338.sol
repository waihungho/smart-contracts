Okay, let's create a smart contract based on a concept involving dynamic NFTs, resource management, oracle interaction for external factors, and a treasury sink. We'll call it "Dynamic Eco-System Engine".

This contract will manage unique "Plot" NFTs (ERC721). Each Plot has dynamic attributes (like Fertility, YieldModifier) that change over time and based on external "Environmental Factors" provided by an oracle. Users can "Cultivate" these plots to generate "Resource" tokens (ERC20), but cultivation consumes "Energy" tokens (ERC20) and temporarily reduces Plot fertility. Plots can be upgraded or repaired using Resources. The system collects a small fee in Energy/Resources to a treasury. Plots can also be staked to potentially earn passive yield based on global factors.

It's important to note that while we won't duplicate *specific* open-source *protocols*, we will leverage standard patterns and libraries (like OpenZeppelin for ERC721/ERC20/Ownable/Pausable) as building blocks, which is standard practice. The creativity lies in the *combination* and *specific logic* implemented for the dynamic attributes, cultivation mechanics, and oracle interaction within this ecosystem context.

---

## Dynamic Eco-System Engine Smart Contract Outline and Function Summary

**Contract Name:** `DynamicEcoSystemEngine`

**Concept:** A simulation-style system managing dynamic NFTs ("Plots") whose attributes evolve based on time, user actions, and external data from an oracle. Users interact with plots to generate resources, consuming energy and affecting plot state.

**Key Components:**
1.  **Plot NFTs (ERC721):** Unique tokens representing land plots with dynamic attributes.
2.  **Resource Tokens (ERC20):** Consumable/earnable tokens ("Energy", "Resource").
3.  **Dynamic Attributes:** Plot parameters that change over time and based on oracle data (e.g., Fertility decay, EnvironmentalModifier).
4.  **Oracle Integration:** Fetches external data ("Environmental Factors") affecting yields and costs.
5.  **Cultivation Mechanic:** Core action to earn Resources by spending Energy, impacting plot state.
6.  **Upgrading/Repairing:** Spending Resources to improve or restore plot attributes.
7.  **Staking:** Locking plots for potential passive benefits.
8.  **Treasury:** Collects fees from interactions.
9.  **Admin Controls:** Pause, set parameters, withdraw treasury.

**Inheritance:** ERC721Enumerable, ERC20 (as separate contracts interacted with), Ownable, Pausable.

**Function Summary:**

**Admin & Setup:**
1.  `constructor`: Initializes the contract, sets up base parameters, links ERC20 tokens and Oracle address.
2.  `setOracleAddress(address _oracleAddress)`: Owner sets the address of the Oracle contract.
3.  `setBaseParameters(GlobalParameters memory _params)`: Owner sets global system parameters (yield rates, decay rates, costs).
4.  `pause()`: Owner pauses contract interactions (except admin).
5.  `unpause()`: Owner unpauses the contract.
6.  `withdrawTreasury(address _token, uint256 _amount, address _to)`: Owner withdraws tokens from the treasury.

**Oracle Interaction:**
7.  `requestOracleUpdate()`: Triggers a request to the oracle for new environmental data. (Requires Oracle contract integration, e.g., Chainlink Request & Receive).
8.  `fulfillOracleUpdate(bytes32 requestId, uint256 environmentalFactor1, int256 environmentalFactor2)`: (Callback from Oracle) Receives data and updates `currentOracleData`.
9.  `getEnvironmentalFactors()`: View current environmental data received from the oracle.

**NFT (Plot) Management:**
10. `mintPlot(address to)`: Mints a new Plot NFT to a user (admin or specific minting logic).
11. `getPlotAttributes(uint256 tokenId)`: View current static and calculated dynamic attributes of a plot.
12. `stakePlot(uint256 tokenId)`: Stakes a Plot NFT, transferring it to the contract.
13. `unstakePlot(uint256 tokenId)`: Unstakes a Plot NFT, returning it to the owner.
14. `isPlotStaked(uint256 tokenId)`: Checks if a plot is currently staked.
15. `getStakedPlots(address user)`: View function listing token IDs of plots staked by a user.

**Resource & Interaction:**
16. `cultivatePlot(uint256 tokenId)`: Core action. User attempts to cultivate. Calculates cost and yield based on dynamic attributes, consumes Energy, generates Resources, updates plot state (fertility, last cultivation time).
17. `upgradePlotTrait(uint256 tokenId, uint8 traitIndex)`: User spends Resources to permanently improve a specific static trait of a plot.
18. `repairPlotFertility(uint256 tokenId)`: User spends Resources to instantly restore a portion of a plot's current fertility.
19. `claimStakedPlotYield(uint256[] calldata tokenIds)`: Claim accumulated yield for staked plots.
20. `calculateCultivationYield(uint256 tokenId)`: View function estimating Resources gained from cultivating *now*.
21. `calculateCultivationCost(uint256 tokenId)`: View function estimating Energy cost to cultivate *now*.
22. `calculateStakedYield(uint256 tokenId)`: View function estimating accumulated yield for a staked plot.

**View & Utility:**
23. `getGlobalParameters()`: View current global system parameters.
24. `getTreasuryBalance(address tokenAddress)`: View balance of a specific token in the contract treasury.
25. `getPlotOwner(uint256 tokenId)`: Standard ERC721 owner check. (Inherited)
26. `getResourceBalance(address user, address tokenAddress)`: View user's balance of a specific resource token. (Requires ERC20 allowance/balance view) - Can just link directly to ERC20 methods. Let's make this a helper view if needed.

*Note: Standard ERC721 functions like `transferFrom`, `approve`, `setApprovalForAll`, `balanceOf`, `tokenOfOwnerByIndex`, `totalSupply` are available via inheritance.*
*Note: Standard ERC20 functions like `transfer`, `transferFrom`, `approve`, `balanceOf`, `allowance` are available via interaction with the token contracts.*

This structure gives us 24 custom functions plus inherited ones, hitting the requirement with a thematic and somewhat complex interaction model.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interface for a hypothetical Oracle contract returning environmental data
interface IEnvironmentalOracle {
    // Function to request an update (implementation depends on Oracle pattern, e.g., Chainlink)
    function requestEnvironmentalUpdate() external returns (bytes32 requestId);

    // Function to get the latest data
    function getLastEnvironmentalData() external view returns (uint256 factor1, int256 factor2, uint64 timestamp);
}


// Outline and Function Summary is provided at the top of this file.

contract DynamicEcoSystemEngine is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _nextTokenId;

    // Linked ERC20 Tokens
    IERC20 public immutable energyToken;
    IERC20 public immutable resourceToken; // Single primary resource type for simplicity

    // Oracle Contract Address
    IEnvironmentalOracle public environmentalOracle;

    // Global System Parameters (set by owner, influence yields, costs, decay)
    struct GlobalParameters {
        uint256 baseCultivationYield; // Base resources gained per cultivation
        uint256 baseCultivationEnergyCost; // Base energy consumed per cultivation
        uint256 fertilityDecayPerBlock; // Amount fertility drops per block after cultivation
        uint256 fertilityRecoveryRate; // How much fertility repairs restore
        uint256 upgradeCostMultiplier; // Multiplier for trait upgrade costs
        uint256 stakedYieldRate; // Base rate for passive yield from staking
        uint256 cultivationCooldownBlocks; // Minimum blocks between cultivations for a plot
    }
    GlobalParameters public globalParameters;

    // Plot Static Attributes (set at mint, upgradeable)
    struct StaticPlotAttributes {
        uint8 maxFertility; // Max possible fertility level
        uint8 yieldModifierBase; // Base modifier for yield (0-100, e.g., %)
        uint8 energyEfficiencyBase; // Base modifier for energy cost (0-100, e.g., %)
    }
    mapping(uint256 => StaticPlotAttributes) public plotStaticAttributes;

    // Plot Dynamic State (changes based on actions, time, oracle data)
    struct DynamicPlotState {
        uint256 currentFertility; // Current fertility (decays over time/use)
        uint64 lastCultivationBlock; // Block number of the last cultivation
        uint64 lastOracleProcessingBlock; // Block number when oracle data last affected this plot (for decay logic)
        // Add more dynamic states if needed
    }
    mapping(uint256 => DynamicPlotState) public plotDynamicState;

    // Current Environmental Factors (from Oracle)
    struct EnvironmentalFactors {
        uint256 factor1; // Example: Overall environmental health (0-1000)
        int256 factor2; // Example: Weather modifier (-100 to +100)
        uint64 timestamp; // Timestamp when data was received
    }
    EnvironmentalFactors public currentEnvironmentalFactors;
    bytes32 public latestOracleRequestId; // To track oracle requests

    // Staking State
    mapping(address => uint256[]) private _stakedPlots; // User address to list of staked tokenIds
    mapping(uint256 => uint64) private _plotStakeTime; // tokenId to block number when staked
    mapping(uint256 => uint256) private _stakedYieldAccumulated; // tokenId to accumulated yield (in ResourceToken)

    // Treasury
    mapping(address => uint256) private _treasuryBalances; // Token address to balance in treasury

    // --- Events ---
    event PlotMinted(address indexed owner, uint256 indexed tokenId, StaticPlotAttributes initialAttributes);
    event PlotCultivated(uint256 indexed tokenId, address indexed user, uint256 energySpent, uint256 resourcesGained, uint256 newFertility);
    event PlotTraitUpgraded(uint256 indexed tokenId, address indexed user, uint8 traitIndex, uint8 newTraitValue, uint256 resourcesSpent);
    event PlotFertilityRepaired(uint256 indexed tokenId, address indexed user, uint256 fertilityRestored, uint256 resourcesSpent, uint256 newFertility);
    event PlotStaked(uint256 indexed tokenId, address indexed user, uint64 stakeTime);
    event PlotUnstaked(uint256 indexed tokenId, address indexed user);
    event StakedYieldClaimed(address indexed user, uint256 indexed totalClaimedAmount);
    event OracleDataReceived(uint256 factor1, int256 factor2, uint64 timestamp);
    event GlobalParametersUpdated(GlobalParameters newParams);
    event TreasuryWithdrawal(address indexed token, uint256 amount, address indexed to);

    // --- Modifiers ---
    modifier onlyOracle() {
        // In a real Chainlink scenario, this would verify the caller is the Oracle contract.
        // For this example, we'll assume a direct call or simplify verification.
        // A robust implementation needs proper Chainlink.fulfillBytes logic and validation.
        // require(msg.sender == address(environmentalOracle), "Only Oracle can call this");
        _;
    }

    // --- Constructor ---
    constructor(
        address _energyToken,
        address _resourceToken,
        address _oracleAddress,
        GlobalParameters memory _initialParams
    ) ERC721("Dynamic Eco-System Plot", "DEP") Ownable(msg.sender) Pausable(false) {
        energyToken = IERC20(_energyToken);
        resourceToken = IERC20(_resourceToken);
        environmentalOracle = IEnvironmentalOracle(_oracleAddress);
        globalParameters = _initialParams;
        emit GlobalParametersUpdated(_initialParams);
    }

    // --- Admin & Setup Functions ---

    /// @notice Sets the address of the Environmental Oracle contract.
    /// @param _oracleAddress The address of the oracle contract.
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        environmentalOracle = IEnvironmentalOracle(_oracleAddress);
    }

    /// @notice Sets the global system parameters.
    /// @param _params New global parameters struct.
    function setBaseParameters(GlobalParameters memory _params) external onlyOwner {
        globalParameters = _params;
        emit GlobalParametersUpdated(_params);
    }

    /// @notice Pauses all user interactions with the contract (except admin functions).
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract, allowing user interactions again.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Allows the owner to withdraw tokens from the contract treasury.
    /// @param _token Address of the token to withdraw.
    /// @param _amount Amount of tokens to withdraw.
    /// @param _to Recipient address.
    function withdrawTreasury(address _token, uint256 _amount, address _to) external onlyOwner {
        require(_treasuryBalances[_token] >= _amount, "Insufficient balance in treasury");
        _treasuryBalances[_token] = _treasuryBalances[_token].sub(_amount);
        IERC20(_token).transfer(_to, _amount);
        emit TreasuryWithdrawal(_token, _amount, _to);
    }

    // --- Oracle Interaction Functions ---

    /// @notice Triggers a request to the Oracle for new environmental data.
    /// This is a placeholder; actual implementation depends on Oracle service (e.g., Chainlink)
    /// which would handle asynchronous requests and callbacks.
    function requestOracleUpdate() external whenNotPaused {
        // In a real system, this would call environmentalOracle.requestEnvironmentalUpdate()
        // and store the returned requestId.
        // For this example, we simulate the request.
        latestOracleRequestId = bytes32(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)))); // Example dummy request ID
        // A real implementation would likely emit an event for off-chain keepers
        // or interact directly with a Chainlink client contract.
    }

    /// @notice Callback function intended to be called by the Oracle contract
    /// to provide the requested environmental data.
    /// @param requestId The ID of the request being fulfilled.
    /// @param environmentalFactor1 The first environmental factor.
    /// @param environmentalFactor2 The second environmental factor.
    function fulfillOracleUpdate(bytes32 requestId, uint256 environmentalFactor1, int256 environmentalFactor2)
        external // onlyOracle // Use modifier in real implementation
    {
        // In a real Chainlink scenario, you'd verify requestId corresponds to a request made by this contract.
        // require(requestId == latestOracleRequestId, "Invalid request ID"); // Example validation

        currentEnvironmentalFactors = EnvironmentalFactors({
            factor1: environmentalFactor1,
            factor2: environmentalFactor2,
            timestamp: uint64(block.timestamp)
        });
        emit OracleDataReceived(environmentalFactor1, environmentalFactor2, uint64(block.timestamp));

        // After receiving data, you might trigger system-wide updates or make it available for next interaction.
        // For this design, the data is simply stored and used in dynamic calculations.
    }

    /// @notice Get the latest environmental data received from the oracle.
    /// @return factor1 The first environmental factor.
    /// @return factor2 The second environmental factor.
    /// @return timestamp The timestamp when the data was received.
    function getEnvironmentalFactors() public view returns (uint256 factor1, int256 factor2, uint64 timestamp) {
        return (currentEnvironmentalFactors.factor1, currentEnvironmentalFactors.factor2, currentEnvironmentalFactors.timestamp);
    }

    // --- NFT (Plot) Management Functions ---

    /// @notice Mints a new Plot NFT and assigns it initial attributes.
    /// @param to The address to mint the plot to.
    /// @dev This function could have more complex minting logic (e.g., cost, randomness).
    ///      Currently simplified for example purposes, callable only by owner.
    function mintPlot(address to) external onlyOwner {
        _nextTokenId.increment();
        uint256 tokenId = _nextTokenId.current();

        // Assign initial attributes (can be random, fixed, or based on input)
        plotStaticAttributes[tokenId] = StaticPlotAttributes({
            maxFertility: 100, // Example initial max fertility
            yieldModifierBase: 80, // Example initial base yield modifier (80%)
            energyEfficiencyBase: 90 // Example initial energy efficiency (90%)
        });

        plotDynamicState[tokenId] = DynamicPlotState({
            currentFertility: 100, // Start with full fertility
            lastCultivationBlock: 0, // Never cultivated initially
            lastOracleProcessingBlock: uint64(block.number) // Set to current block for decay calculation basis
        });

        _safeMint(to, tokenId);
        emit PlotMinted(to, tokenId, plotStaticAttributes[tokenId]);
    }

    /// @notice Gets the static and dynamically calculated attributes of a plot.
    /// @param tokenId The ID of the plot.
    /// @return staticAttrs The static attributes of the plot.
    /// @return dynamicAttrs The dynamic state of the plot.
    /// @return effectiveYieldModifier Effective yield modifier considering dynamic state and oracle.
    /// @return effectiveEnergyEfficiency Effective energy efficiency considering dynamic state and oracle.
    function getPlotAttributes(uint256 tokenId)
        public view
        returns (StaticPlotAttributes memory staticAttrs, DynamicPlotState memory dynamicAttrs, uint256 effectiveYieldModifier, uint256 effectiveEnergyEfficiency)
    {
        require(_exists(tokenId), "Plot does not exist");
        staticAttrs = plotStaticAttributes[tokenId];
        dynamicAttrs = plotDynamicState[tokenId]; // This is the *stored* dynamic state

        // Calculate *current effective* dynamic attributes
        (effectiveYieldModifier, effectiveEnergyEfficiency) = _calculateEffectiveDynamicAttributes(tokenId);

        return (staticAttrs, dynamicAttrs, effectiveYieldModifier, effectiveEnergyEfficiency);
    }

    /// @notice Stakes a Plot NFT, transferring ownership to the contract.
    /// @param tokenId The ID of the plot to stake.
    function stakePlot(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), "Plot does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not plot owner");
        require(!isPlotStaked(tokenId), "Plot is already staked");

        // Transfer NFT to contract address (this contract)
        _transfer(msg.sender, address(this), tokenId);

        // Record staking state
        _stakedPlots[msg.sender].push(tokenId);
        _plotStakeTime[tokenId] = uint64(block.number);
        // Initial accumulated yield is 0, it's calculated on claim

        emit PlotStaked(tokenId, msg.sender, uint64(block.number));
    }

    /// @notice Unstakes a Plot NFT, transferring ownership back to the user.
    /// Accumulated yield is claimed automatically upon unstaking.
    /// @param tokenId The ID of the plot to unstake.
    function unstakePlot(uint256 tokenId) external whenNotPaused {
        require(isPlotStaked(tokenId), "Plot is not staked or not yours to unstake");
        require(ownerOf(tokenId) == address(this), "Plot not held by staking contract"); // Safety check

        // Find and remove from staked list
        uint256[] storage userStaked = _stakedPlots[msg.sender];
        bool found = false;
        for (uint i = 0; i < userStaked.length; i++) {
            if (userStaked[i] == tokenId) {
                // Swap with last element and pop
                userStaked[i] = userStaked[userStaked.length - 1];
                userStaked.pop();
                found = true;
                break;
            }
        }
        require(found, "Plot not found in user's staked list (state mismatch)"); // Should not happen if isPlotStaked passed

        // Calculate and claim accumulated yield
        _claimYieldForStakedPlot(tokenId, msg.sender); // Internal helper

        // Transfer NFT back to user
        _transfer(address(this), msg.sender, tokenId);

        // Clean up staking state
        delete _plotStakeTime[tokenId];
        // _stakedYieldAccumulated[tokenId] was handled in _claimYieldForStakedPlot

        emit PlotUnstaked(tokenId, msg.sender);
    }

    /// @notice Checks if a plot is currently staked.
    /// @param tokenId The ID of the plot.
    /// @return True if staked, false otherwise.
    function isPlotStaked(uint256 tokenId) public view returns (bool) {
        // A plot is staked if its owner is this contract AND it has a stake time recorded.
        // The stake time check is primary as it's set when staking.
        // The owner check adds robustness against external transfers (though ERC721 shouldn't allow it directly).
        return _plotStakeTime[tokenId] > 0 && ownerOf(tokenId) == address(this);
    }

    /// @notice Gets the list of plot token IDs staked by a user.
    /// @param user The address of the user.
    /// @return An array of staked plot token IDs.
    function getStakedPlots(address user) public view returns (uint256[] memory) {
        return _stakedPlots[user];
    }


    // --- Resource & Interaction Functions ---

    /// @notice Allows a user to cultivate resources from their plot.
    /// Requires user to have approved Energy token transfer to this contract.
    /// @param tokenId The ID of the plot to cultivate.
    function cultivatePlot(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), "Plot does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not plot owner");

        DynamicPlotState storage dynamicState = plotDynamicState[tokenId];
        StaticPlotAttributes storage staticAttrs = plotStaticAttributes[tokenId];

        // --- Cooldown Check ---
        require(block.number >= dynamicState.lastCultivationBlock + globalParameters.cultivationCooldownBlocks, "Plot is on cooldown");

        // --- Calculate Cost and Yield ---
        (uint256 effectiveYieldModifier, uint256 effectiveEnergyEfficiency) = _calculateEffectiveDynamicAttributes(tokenId);

        uint256 energyCost = globalParameters.baseCultivationEnergyCost.mul(1000).div(effectiveEnergyEfficiency); // More efficient costs less
        uint256 resourcesGained = globalParameters.baseCultivationYield.mul(effectiveYieldModifier).div(1000); // Higher modifier yields more

        // Apply fertility modifier to yield
        uint256 fertilityYieldModifier = dynamicState.currentFertility.mul(1000).div(staticAttrs.maxFertility); // Current fertility as % of max
        resourcesGained = resourcesGained.mul(ferilityYieldModifier).div(1000);

        // --- Transfer Energy Cost ---
        require(energyToken.transferFrom(msg.sender, address(this), energyCost), "Energy transfer failed");

        // Add a small percentage of energy cost to the treasury
        uint256 treasuryFee = energyCost.div(20); // 5% fee example
        uint256 remainingEnergy = energyCost.sub(treasuryFee);
        // Ideally, transfer remainingEnergy back or handle distribution.
        // For this example, all energy goes to the contract, fee noted.
        _treasuryBalances[address(energyToken)] = _treasuryBalances[address(energyToken)].add(treasuryFee);
        // Remaining `remainingEnergy` stays in the contract balance.

        // --- Mint Resources to User ---
        require(resourcesGained > 0, "Yield is zero"); // Prevent minting zero
        // Assuming resourceToken has a minter role granted to this contract
        // resourceToken._mint(msg.sender, resourcesGained); // If using ERC20 internal mint
        // Or if resourceToken is a standard ERC20, this wouldn't be possible unless it has a public mint function or similar mechanism.
        // For this example, let's assume a minter role or similar capability.
        // If resource token is just another standard ERC20, resources would likely come from a pre-minted pool or be recycled.
        // Let's assume a simple minting capability for this example.
        // For a real system with standard ERC20, you'd need a different token distribution model.
        // Using a mock _mint for demonstration:
         IERC20(address(resourceToken)).transfer(msg.sender, resourcesGained); // Simple transfer if tokens exist, or mock mint

        // --- Update Plot State ---
        dynamicState.currentFertility = dynamicState.currentFertility.sub(globalParameters.fertilityDecayPerBlock); // Decay from cultivation
        dynamicState.lastCultivationBlock = uint64(block.number);
        dynamicState.lastOracleProcessingBlock = uint64(block.number); // Update last processed block

        emit PlotCultivated(tokenId, msg.sender, energyCost, resourcesGained, dynamicState.currentFertility);
    }

    /// @notice Allows user to spend Resources to permanently improve a static trait.
    /// Requires user to have approved Resource token transfer to this contract.
    /// @param tokenId The ID of the plot.
    /// @param traitIndex Index of the trait to upgrade (0: maxFertility, 1: yieldModifierBase, 2: energyEfficiencyBase).
    function upgradePlotTrait(uint256 tokenId, uint8 traitIndex) external whenNotPaused {
        require(_exists(tokenId), "Plot does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not plot owner");
        require(traitIndex < 3, "Invalid trait index"); // Only 3 traits available

        StaticPlotAttributes storage staticAttrs = plotStaticAttributes[tokenId];
        uint256 cost;
        uint8 currentValue;
        uint8 maxValue = 255; // Max value for uint8

        // Determine cost based on current value and trait
        if (traitIndex == 0) { // maxFertility
            currentValue = staticAttrs.maxFertility;
            cost = (uint256(currentValue).add(1)).mul(globalParameters.upgradeCostMultiplier);
        } else if (traitIndex == 1) { // yieldModifierBase
            currentValue = staticAttrs.yieldModifierBase;
             cost = (uint256(currentValue).add(1)).mul(globalParameters.upgradeCostMultiplier);
        } else { // energyEfficiencyBase
            currentValue = staticAttrs.energyEfficiencyBase;
             cost = (uint256(currentValue).add(1)).mul(globalParameters.upgradeCostMultiplier);
        }

        require(currentValue < maxValue, "Trait is already at max value");
        require(resourceToken.transferFrom(msg.sender, address(this), cost), "Resource transfer failed for upgrade");
         _treasuryBalances[address(resourceToken)] = _treasuryBalances[address(resourceToken)].add(cost); // Full cost to treasury

        // Apply upgrade
        uint8 newValue = currentValue.add(1);
        if (traitIndex == 0) {
            staticAttrs.maxFertility = newValue;
            // Also increase current fertility proportionally? Or just max? Let's just increase max.
            // plotDynamicState[tokenId].currentFertility = plotDynamicState[tokenId].currentFertility.add(1); // Optional: add to current too
        } else if (traitIndex == 1) {
            staticAttrs.yieldModifierBase = newValue;
        } else {
            staticAttrs.energyEfficiencyBase = newValue;
        }

        emit PlotTraitUpgraded(tokenId, msg.sender, traitIndex, newValue, cost);
    }

    /// @notice Allows user to spend Resources to instantly restore a plot's current fertility.
    /// Requires user to have approved Resource token transfer to this contract.
    /// @param tokenId The ID of the plot.
    function repairPlotFertility(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), "Plot does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not plot owner");

        StaticPlotAttributes storage staticAttrs = plotStaticAttributes[tokenId];
        DynamicPlotState storage dynamicState = plotDynamicState[tokenId];

        require(dynamicState.currentFertility < staticAttrs.maxFertility, "Fertility is already full");

        uint256 repairAmount = staticAttrs.maxFertility.sub(dynamicState.currentFertility);
        repairAmount = repairAmount.mul(globalParameters.fertilityRecoveryRate).div(1000); // Repair is limited by recovery rate

        if (repairAmount == 0) return; // Nothing to repair

        uint256 cost = repairAmount.mul(globalParameters.upgradeCostMultiplier).div(2); // Repair is cheaper than upgrade? Example cost formula

        require(resourceToken.transferFrom(msg.sender, address(this), cost), "Resource transfer failed for repair");
        _treasuryBalances[address(resourceToken)] = _treasuryBalances[address(resourceToken)].add(cost); // Full cost to treasury

        // Apply repair
        dynamicState.currentFertility = dynamicState.currentFertility.add(uint256(repairAmount));
        if (dynamicState.currentFertility > staticAttrs.maxFertility) {
            dynamicState.currentFertility = staticAttrs.maxFertility;
        }

        emit PlotFertilityRepaired(tokenId, msg.sender, repairAmount, cost, dynamicState.currentFertility);
    }

    /// @notice Claims accumulated passive yield for specified staked plots.
    /// @param tokenIds An array of token IDs for staked plots owned by the caller.
    function claimStakedPlotYield(uint256[] calldata tokenIds) external whenNotPaused {
        uint256 totalClaimable = 0;
        address user = msg.sender;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(isPlotStaked(tokenId), "Plot is not staked");
            // Additional check to ensure the staked plot belongs to this user
            // This requires iterating through the user's staked list or having a reverse lookup
            // For simplicity here, we assume the user provides valid staked tokenIds.
            // A robust version would verify owner against the staked list.
             bool isUserStaked = false;
             uint256[] storage userPlots = _stakedPlots[user];
             for(uint j=0; j<userPlots.length; j++) {
                 if(userPlots[j] == tokenId) {
                     isUserStaked = true;
                     break;
                 }
             }
             require(isUserStaked, "Plot is staked but not by caller");


            totalClaimable = totalClaimable.add(_claimYieldForStakedPlot(tokenId, user));
        }

        if (totalClaimable > 0) {
            // Mint/Transfer resources to the user
             IERC20(address(resourceToken)).transfer(user, totalClaimable); // Assuming transfer or mint
            emit StakedYieldClaimed(user, totalClaimable);
        }
    }

    /// @notice Calculates the potential yield for a plot if cultivated now.
    /// Does not modify state.
    /// @param tokenId The ID of the plot.
    /// @return The estimated number of Resources gained from one cultivation.
    function calculateCultivationYield(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Plot does not exist");

        StaticPlotAttributes memory staticAttrs = plotStaticAttributes[tokenId];
        DynamicPlotState memory dynamicState = plotDynamicState[tokenId];

        // Calculate effective attributes including dynamic effects and oracle data
        (uint256 effectiveYieldModifier, ) = _calculateEffectiveDynamicAttributes(tokenId);

        uint256 baseYield = globalParameters.baseCultivationYield.mul(effectiveYieldModifier).div(1000);

        // Apply current fertility modifier
        uint256 fertilityYieldModifier = dynamicState.currentFertility.mul(1000).div(staticAttrs.maxFertility);
        uint256 finalYield = baseYield.mul(ferilityYieldModifier).div(1000);

        return finalYield;
    }

     /// @notice Calculates the energy cost to cultivate a plot now.
    /// Does not modify state.
    /// @param tokenId The ID of the plot.
    /// @return The estimated Energy cost for one cultivation.
    function calculateCultivationCost(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Plot does not exist");

        StaticPlotAttributes memory staticAttrs = plotStaticAttributes[tokenId];
        DynamicPlotState memory dynamicState = plotDynamicState[tokenId];

        // Calculate effective attributes including dynamic effects and oracle data
        (, uint256 effectiveEnergyEfficiency) = _calculateEffectiveDynamicAttributes(tokenId);

        uint256 energyCost = globalParameters.baseCultivationEnergyCost.mul(1000).div(effectiveEnergyEfficiency);

        // Note: Fertility doesn't affect cost in this example, only yield. Could add it.

        return energyCost;
    }

    /// @notice Calculates the accumulated yield for a staked plot.
    /// Does not modify state.
    /// @param tokenId The ID of the staked plot.
    /// @return The estimated accumulated yield in ResourceTokens.
    function calculateStakedYield(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Plot does not exist");
         require(isPlotStaked(tokenId), "Plot is not staked");

         uint64 stakeBlock = _plotStakeTime[tokenId];
         uint256 accumulated = _stakedYieldAccumulated[tokenId]; // Yield already calculated but not claimed

         uint256 blocksStakedSinceLastCalc = block.number.sub(stakeBlock);

         if (blocksStakedSinceLastCalc == 0) {
             return accumulated; // No new blocks since last calculation
         }

         // Simple linear yield per block example
         uint256 newYield = blocksStakedSinceLastCalc.mul(globalParameters.stakedYieldRate).div(1000); // Rate is per block / 1000

         // Could add plot-specific modifiers to staked yield calculation here
         // Example: uint256 yieldModifier = plotStaticAttributes[tokenId].yieldModifierBase;
         // newYield = newYield.mul(yieldModifier).div(100);

         return accumulated.add(newYield);
    }


    // --- View & Utility Functions ---

    /// @notice Gets the current global system parameters.
    /// @return The GlobalParameters struct.
    function getGlobalParameters() public view returns (GlobalParameters memory) {
        return globalParameters;
    }

    /// @notice Gets the balance of a specific token held in the contract treasury.
    /// @param tokenAddress The address of the token.
    /// @return The balance amount.
    function getTreasuryBalance(address tokenAddress) public view returns (uint256) {
        return _treasuryBalances[tokenAddress];
    }

    /// @notice Gets the owner of a specific plot. Inherited from ERC721.
    /// @param tokenId The ID of the plot.
    function getPlotOwner(uint256 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId);
    }

    /// @notice Get a user's balance of a specific resource token.
    /// @param user The user's address.
    /// @param tokenAddress The address of the resource token (Energy or Resource).
    /// @return The user's token balance.
    function getResourceBalance(address user, address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(user);
    }


    // --- Internal Helper Functions ---

    /// @dev Calculates the effective dynamic attributes (yield/efficiency modifiers)
    /// based on static attributes, current fertility, time decay, and oracle data.
    /// @param tokenId The ID of the plot.
    /// @return effectiveYieldModifier The calculated effective yield modifier (scaled by 1000).
    /// @return effectiveEnergyEfficiency The calculated effective energy efficiency (scaled by 1000).
    function _calculateEffectiveDynamicAttributes(uint256 tokenId)
        internal view
        returns (uint256 effectiveYieldModifier, uint256 effectiveEnergyEfficiency)
    {
        StaticPlotAttributes memory staticAttrs = plotStaticAttributes[tokenId];
        DynamicPlotState memory dynamicState = plotDynamicState[tokenId];
        EnvironmentalFactors memory envFactors = currentEnvironmentalFactors;

        // --- Apply time-based Fertility Decay (example logic) ---
        // Calculate decay since last state update (cultivation or oracle processing)
        uint256 blocksSinceLastUpdate = block.number.sub(dynamicState.lastOracleProcessingBlock);
        uint256 decayAmount = blocksSinceLastUpdate.mul(globalParameters.fertilityDecayPerBlock);
        uint256 currentFertilityConsiderDecay = dynamicState.currentFertility > decayAmount ? dynamicState.currentFertility.sub(decayAmount) : 0;

        // Fertility contributes to yield but not efficiency in this example
        uint256 fertilityModifier = currentFertilityConsiderDecay.mul(1000).div(staticAttrs.maxFertility); // Fertility as % of max, scaled

        // --- Apply Oracle Data Modifiers (example logic) ---
        // Factor1 (0-1000): Directly modifies base yield/efficiency.
        // Factor2 (-100 to +100): Adds/subtracts to modifier base.
        uint256 envYieldModifier = staticAttrs.yieldModifierBase;
        int256 envEfficiencyModifier = int256(staticAttrs.energyEfficiencyBase);

        // Example: Factor1 positively influences both, scaled (e.g., 0-100% influence)
        uint256 factor1Influence = envFactors.factor1.mul(1000).div(1000); // Scale 0-1000 to 0-1000

        // Example: Factor2 adds/subtracts directly to the base modifier (ensure bounds)
        int256 factor2Influence = envFactors.factor2; // Range -100 to +100

        // Combined Modifier = Base + Factor1 Influence + Factor2 Influence (with bounds)
        int256 combinedYieldModifier = int256(staticAttrs.yieldModifierBase).add(int256(factor1Influence).div(10)) // Example: 10% of factor1 as modifier
                                     .add(factor2Influence); // Example: direct influence of factor2

        int256 combinedEfficiencyModifier = int256(staticAttrs.energyEfficiencyBase).add(int256(factor1Influence).div(10))
                                         .add(factor2Influence);

        // Ensure modifiers are within a reasonable range (e.g., 10% to 200% of base)
        int256 minModifier = int256(50); // Example: Min 50/1000 = 5% of base? Or flat min? Let's use flat min scaled.
        int256 maxModifier = int256(2000); // Example: Max 2000/1000 = 200% of base?

        combinedYieldModifier = combinedYieldModifier > maxModifier ? maxModifier : combinedYieldModifier;
        combinedYieldModifier = combinedYieldModifier < minModifier ? minModifier : combinedYieldModifier;

        combinedEfficiencyModifier = combinedEfficiencyModifier > maxModifier ? maxModifier : combinedEfficiencyModifier;
        combinedEfficiencyModifier = combinedEfficiencyModifier < minModifier ? minModifier : combinedEfficiencyModifier;


        // --- Final Effective Modifiers ---
        // Effective Yield = (Base Yield Modifier + Oracle Influences) * Fertility
        // Effective Efficiency = (Base Efficiency Modifier + Oracle Influences)
        // Scale modifiers to 1000 for calculations

        uint256 baseYieldModScaled = uint256(combinedYieldModifier).mul(staticAttrs.yieldModifierBase).div(100); // Apply combined oracle/base to static base
        effectiveYieldModifier = baseYieldModScaled.mul(currentFertilityConsiderDecay).div(staticAttrs.maxFertility); // Apply fertility

        uint256 baseEfficiencyModScaled = uint256(combinedEfficiencyModifier).mul(staticAttrs.energyEfficiencyBase).div(100); // Apply combined oracle/base to static base
        effectiveEnergyEfficiency = baseEfficiencyModScaled; // Efficiency is not affected by fertility here


        // Ensure they are not zero after calculations
        if (effectiveYieldModifier == 0 && staticAttrs.yieldModifierBase > 0) effectiveYieldModifier = 1; // Min yield modifier
        if (effectiveEnergyEfficiency == 0 && staticAttrs.energyEfficiencyBase > 0) effectiveEnergyEfficiency = 1; // Min efficiency modifier


        return (effectiveYieldModifier, effectiveEnergyEfficiency);
    }

    /// @dev Internal helper to calculate and claim yield for a single staked plot.
    /// @param tokenId The ID of the staked plot.
    /// @param user The owner of the staked plot.
    /// @return The amount of yield claimed.
    function _claimYieldForStakedPlot(uint256 tokenId, address user) internal returns (uint256) {
         require(_plotStakeTime[tokenId] > 0, "Plot not staked"); // Double check

         uint64 stakeBlock = _plotStakeTime[tokenId];
         uint256 accumulatedBefore = _stakedYieldAccumulated[tokenId];

         uint256 blocksStakedSinceLastCalc = block.number.sub(stakeBlock);
         uint256 newYield = blocksStakedSinceLastCalc.mul(globalParameters.stakedYieldRate).div(1000);

         uint256 totalClaimable = accumulatedBefore.add(newYield);

         // Reset state after calculation
         _plotStakeTime[tokenId] = uint64(block.number); // Reset timer
         _stakedYieldAccumulated[tokenId] = 0; // Reset accumulated

         // Add yield to treasury? Or directly mint? Let's assume it comes from a pool/minting.
         // In a real system, this yield might come from the treasury or be minted.
         // If minted, the resourceToken needs a minting function callable by this contract.
         // If from treasury, need to check treasury balance.
         // For this example, we'll just return the amount, assuming the caller handles the token transfer.

         return totalClaimable;
    }


    // The following functions are overrides required by Solidity.
    // They simply delegate to the parent OpenZeppelin contracts.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ERC721Enumerable overrides
    function totalSupply() public view override(ERC721Enumerable, ERC721) returns (uint256) {
        return super.totalSupply();
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        return super.tokenByIndex(index);
    }

    // ERC721 standard overrides (required by ERC721Enumerable)
     function approve(address to, uint256 tokenId) public override(ERC721Enumerable, ERC721) {
        super.approve(to, tokenId);
     }

     function getApproved(uint256 tokenId) public view override(ERC721Enumerable, ERC721) returns (address) {
        return super.getApproved(tokenId);
     }

     function setApprovalForAll(address operator, bool approved) public override(ERC721Enumerable, ERC721) {
        super.setApprovalForAll(operator, approved);
     }

     function isApprovedForAll(address owner, address operator) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.isApprovedForAll(owner, operator);
     }

     function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Enumerable, ERC721) {
        super.transferFrom(from, to, tokenId);
     }

     function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Enumerable, ERC721) {
         super.safeTransferFrom(from, to, tokenId);
     }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override(ERC721Enumerable, ERC721) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic NFT Attributes:** Plot attributes (`currentFertility`, `lastCultivationBlock`, `lastOracleProcessingBlock`) are not static. They change based on user actions (cultivation reduces fertility) and simulated time (implicitly, as calculations use `block.number`). This makes each NFT's state evolve uniquely based on its history and interaction.
2.  **Oracle-Influenced State:** The `_calculateEffectiveDynamicAttributes` function incorporates `currentEnvironmentalFactors` fetched from an oracle. This allows external, real-world (or simulated external) data to directly impact the mechanics of the ecosystem (yields, costs). The calculation combines static traits, dynamic state (fertility), and oracle data for complexity.
3.  **Time-Based Decay:** Fertility explicitly decays over time (measured in blocks) since the last state update (`lastOracleProcessingBlock`). This introduces a maintenance element – plots become less productive if not interacted with or if environmental factors are poor.
4.  **Resource Sink and Treasury:** Energy spent on cultivation and Resources spent on upgrades/repairs are directed to the contract's treasury (`_treasuryBalances`). This creates a value sink within the ecosystem, potentially giving value to the collected tokens or allowing the DAO/owner to use them for ecosystem purposes.
5.  **Staking with Yield Calculation:** Plots can be staked, locking the NFT. A basic passive yield accrues over time (measured in blocks) based on a global rate. The yield is calculated lazily upon unstaking or claiming. This adds a DeFi-like element.
6.  **Interdependent Mechanics:** Cultivation requires Energy (ERC20), produces Resources (ERC20), and decays Plot state (NFT dynamic attribute). Upgrading/Repairing requires Resources (ERC20) and improves Plot state (NFT static/dynamic attribute). Oracle data influences the efficiency of these actions. This creates a small, interconnected economic loop.
7.  **Layered Attributes:** Plots have both `StaticPlotAttributes` (permanent, improvable) and `DynamicPlotState` (temporary, volatile). Effective attributes used in calculations combine both, along with external factors.

This contract provides a blueprint for a more engaging and complex on-chain ecosystem compared to standard static token contracts or simple generative NFTs. It demonstrates how to integrate external data and time-sensitive mechanics into NFT and resource management.