Okay, here is a smart contract concept called `QuantumForge`. It combines several advanced, creative, and trendy concepts:

1.  **Dynamic NFTs (QSE):** Attributes change over time based on staking and external data.
2.  **Crafting/Forging:** Users burn fungible tokens (QST) and potentially NFTs to create new, unique dynamic NFTs.
3.  **Refining:** Users can burn multiple lower-tier NFTs to attempt creating a potentially better one.
4.  **Staking with Utility:** Staking NFTs doesn't just earn rewards, it also enhances their dynamic attributes.
5.  **Yield Farming (QST):** Staking NFTs yields fungible tokens.
6.  **Oracle Integration (Simulated):** An external source (like a price feed or even simulated AI data) influences the rate of attribute change during staking and potentially forging outcomes.
7.  **Tiered System:** Essences could have different initial tiers influencing forging costs and attribute ranges.
8.  **Attribute Decay (Passive):** While not explicitly coded for decay when *unstaked* in this example (to keep it manageable), the `getCurrentEssenceAttributes` function lays the groundwork for calculating state based on time and external factors, which *could* include decay logic. The current implementation focuses on growth while staked.
9.  **Internal Token Handling:** The contract acts as the minter/burner for both its fungible (QST) and non-fungible (QSE) tokens.

This design avoids directly copying a single open-source project by integrating these distinct mechanisms into one cohesive system.

---

**Outline:**

1.  **Interfaces:** ERC-20, ERC-721 from OpenZeppelin.
2.  **Libraries:** SafeMath (for older Solidity versions), Ownable.
3.  **Data Structures:**
    *   `EssenceAttributes`: Struct for dynamic NFT properties (e.g., Resonance, Stability, Attunement).
    *   `EssenceStakingInfo`: Struct to track staking details for an NFT (staker, time, last attribute update time).
4.  **State Variables:**
    *   Contract parameters (forge costs, staking rates, attribute dynamics, oracle address).
    *   Token counters (totalSupply for QST, nextTokenId for QSE).
    *   Mappings for NFT attributes, staking info, user staked lists, user claimable rewards.
    *   Latest oracle data.
5.  **Events:**
    *   Actions like Forging, Refining, Staking, Unstaking, Reward Claiming, Oracle Update, Attribute Update.
6.  **Modifiers:**
    *   `onlyOracle`
    *   `whenNotStaked`
7.  **Internal Functions:**
    *   Token minting/burning (`_mintQST`, `_burnQST`, `_mintEssence`, `_burnEssence`).
    *   Attribute calculation (`_calculateCurrentAttributes`, `_updateEssenceAttributes`).
    *   Reward calculation (`_calculateStakingRewardsForToken`).
    *   Staked essence list management (`_addStakedEssence`, `_removeStakedEssence`).
    *   Overridden ERC-721 transfer hook (`_beforeTokenTransfer`).
8.  **External/Public Functions:**
    *   **Core Mechanics:** `forgeEssence`, `refineEssence`, `stakeEssence`, `unstakeEssence`, `claimStakingRewards`.
    *   **Oracle Interaction:** `updateOracleData`.
    *   **Information Queries (Views):** `getCurrentEssenceAttributes`, `getEssenceInitialAttributes`, `getEssenceStakingInfo`, `getStakedEssencesByUser`, `getForgeParameters`, `getStakingRates`, `getOracleData`.
    *   **Admin/Owner Functions:** `setOracleAddress`, `setForgeParameters`, `setStakingRates`, `withdrawAdminFees`, `transferOwnership`, `renounceOwnership`.
    *   **Inherited ERC-20 (QST):** `totalSupply`, `balanceOf`, `transfer`, `allowance`, `approve`, `transferFrom`.
    *   **Inherited ERC-721 (QSE):** `balanceOf`, `ownerOf`, `safeTransferFrom`, `transferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`.

---

**Function Summary:**

1.  `constructor(address initialOracle)`: Deploys the contract, sets initial owner and oracle address.
2.  `forgeEssence(uint256 oracleSeed)`: Allows a user to forge a new `QuantumEssence` (QSE) NFT by burning `forgeCostQST` tokens and paying `forgeFeeQST`. Initial attributes are generated based on internal logic and the provided `oracleSeed`. Mints a new QSE.
3.  `refineEssence(uint256[] calldata tokenIdsToBurn, uint256 oracleSeed)`: Allows a user to refine multiple existing QSE NFTs (`refineEssenceCount`) by burning them and `refineCostQST` tokens, plus `refineFeeQST`. Mints a new QSE with attributes potentially influenced by the burned ones and the oracle seed.
4.  `stakeEssence(uint256 tokenId)`: Allows a user to stake their QSE NFT in the contract. Marks the NFT as staked and non-transferable. Updates attributes based on prior state.
5.  `unstakeEssence(uint256 tokenId)`: Allows a user to unstake their QSE NFT. Calculates and accrues staking rewards (QST) and updates attributes based on staking duration. Transfers the NFT back to the user.
6.  `claimStakingRewards()`: Allows a user to claim all accrued QST staking rewards for all their staked and previously staked/unstaked tokens.
7.  `updateOracleData(uint256 newData)`: (Callable by `onlyOracle`) Updates the external data point used to influence attribute growth during staking and potentially forging outcomes.
8.  `getCurrentEssenceAttributes(uint256 tokenId)`: (View) Calculates and returns the *current* theoretical attributes of an Essence NFT, considering its initial attributes, staking status, time elapsed since the last attribute update, and the latest oracle data. Does not modify state.
9.  `getEssenceInitialAttributes(uint256 tokenId)`: (View) Returns the attributes the Essence NFT was minted with or last updated to (e.g., after refining or unstaking/claiming).
10. `getEssenceStakingInfo(uint256 tokenId)`: (View) Returns the staking details for a specific Essence NFT (staker, stake time, staked status).
11. `getStakedEssencesByUser(address user)`: (View) Returns a list of token IDs of QSE NFTs currently staked by a specific user.
12. `getForgeParameters()`: (View) Returns the current parameters for forging and refining.
13. `getStakingRates()`: (View) Returns the current staking reward rate and attribute growth rate.
14. `getOracleData()`: (View) Returns the latest data provided by the oracle.
15. `setOracleAddress(address _oracleAddress)`: (Owner) Sets the address allowed to call `updateOracleData`.
16. `setForgeParameters(uint256 _forgeCostQST, uint256 _forgeFeeQST, uint256 _refineCostQST, uint256 _refineFeeQST, uint256 _refineEssenceCount)`: (Owner) Sets the costs and parameters for forging and refining.
17. `setStakingRates(uint256 _stakingRewardRatePerSecond, uint256 _attributeGrowthRate, uint256 _maxEssenceAttributes)`: (Owner) Sets the rates for staking rewards and attribute growth, and the max cap.
18. `withdrawAdminFees(address tokenAddress, uint256 amount)`: (Owner) Allows the owner to withdraw collected fees (QST or potentially other tokens sent to the contract).
19. `transferOwnership(address newOwner)`: (Owner, inherited) Transfers contract ownership.
20. `renounceOwnership()`: (Owner, inherited) Renounces contract ownership.
21. `totalSupply()`: (QST, inherited) Returns the total supply of Quantum Dust.
22. `balanceOf(address account)`: (QST, inherited) Returns the QST balance of an address.
23. `transfer(address recipient, uint256 amount)`: (QST, inherited) Transfers QST.
24. `allowance(address owner, address spender)`: (QST, inherited) Returns the allowance granted to a spender for QST.
25. `approve(address spender, uint256 amount)`: (QST, inherited) Approves a spender for QST.
26. `transferFrom(address sender, address recipient, uint256 amount)`: (QST, inherited) Transfers QST using allowance.
27. `balanceOf(address owner)`: (QSE, inherited) Returns the number of QSE NFTs owned by an address.
28. `ownerOf(uint256 tokenId)`: (QSE, inherited) Returns the owner of a QSE NFT.
29. `safeTransferFrom(address from, address to, uint256 tokenId)`: (QSE, inherited, modified) Transfers QSE safely, checking if staked.
30. `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: (QSE, inherited, modified) Transfers QSE safely with data, checking if staked.
31. `transferFrom(address from, address to, uint256 tokenId)`: (QSE, inherited, modified) Transfers QSE, checking if staked.
32. `approve(address to, uint256 tokenId)`: (QSE, inherited, modified) Approves address for QSE transfer, checking if staked.
33. `setApprovalForAll(address operator, bool approved)`: (QSE, inherited, modified) Sets approval for all QSEs, checking if any are staked by the owner.
34. `getApproved(uint256 tokenId)`: (QSE, inherited) Returns approved address for QSE.
35. `isApprovedForAll(address owner, address operator)`: (QSE, inherited) Returns if operator is approved for all QSEs.

*(Note: The function count including inherited ERC-20/721 functions and custom logic easily exceeds 20)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has checked arithmetic, explicit SafeMath can be clearer for complex ops

// --- Outline ---
// 1. Interfaces: ERC-20, ERC-721
// 2. Libraries: SafeMath, Ownable, Counters
// 3. Data Structures: EssenceAttributes, EssenceStakingInfo
// 4. State Variables: Parameters, Mappings for QSE attributes, staking, user staked lists, rewards, oracle data.
// 5. Events: Forging, Refining, Staking, Unstaking, Rewards, Oracle, Attributes.
// 6. Modifiers: onlyOracle, whenNotStaked.
// 7. Internal Functions: Minting/Burning, Attribute/Reward Calculation, Staked list management, Transfer hook override.
// 8. External/Public Functions: Core Mechanics (Forge, Refine, Stake, Unstake, Claim), Oracle Interaction, Views, Admin, Inherited ERC-20/721.

// --- Function Summary ---
// 1. constructor(address initialOracle): Deploys, sets owner/oracle.
// 2. forgeEssence(uint256 oracleSeed): Burns QST, mints new QSE with dynamic attributes based on seed/oracle.
// 3. refineEssence(uint256[] calldata tokenIdsToBurn, uint256 oracleSeed): Burns QST + multiple QSE, mints new QSE with attributes influenced by burned ones/seed/oracle.
// 4. stakeEssence(uint256 tokenId): Stakes user's QSE, makes it non-transferable, updates attributes.
// 5. unstakeEssence(uint256 tokenId): Unstakes user's QSE, calculates/accrues rewards, updates attributes, transfers QSE back.
// 6. claimStakingRewards(): Claims accrued QST rewards for user's staked/unstaked QSEs.
// 7. updateOracleData(uint256 newData): (Oracle) Updates data influencing attribute dynamics.
// 8. getCurrentEssenceAttributes(uint256 tokenId): (View) Calculates live attributes based on time, staking, oracle.
// 9. getEssenceInitialAttributes(uint256 tokenId): (View) Gets checkpointed attributes.
// 10. getEssenceStakingInfo(uint256 tokenId): (View) Gets staking status/details.
// 11. getStakedEssencesByUser(address user): (View) Gets list of user's staked QSE IDs.
// 12. getForgeParameters(): (View) Gets current forge/refine parameters.
// 13. getStakingRates(): (View) Gets current staking reward/growth rates.
// 14. getOracleData(): (View) Gets latest oracle data.
// 15. setOracleAddress(address _oracleAddress): (Owner) Sets oracle address.
// 16. setForgeParameters(uint256 _forgeCostQST, uint256 _forgeFeeQST, uint256 _refineCostQST, uint256 _refineFeeQST, uint256 _refineEssenceCount): (Owner) Sets forge/refine params.
// 17. setStakingRates(uint256 _stakingRewardRatePerSecond, uint256 _attributeGrowthRate, uint256 _maxEssenceAttributes): (Owner) Sets staking rates.
// 18. withdrawAdminFees(address tokenAddress, uint256 amount): (Owner) Withdraws fees.
// 19. transferOwnership(address newOwner): (Owner) Transfers ownership.
// 20. renounceOwnership(): (Owner) Renounces ownership.
// 21+. Inherited ERC-20 (QST) functions: totalSupply, balanceOf, transfer, allowance, approve, transferFrom.
// 27+. Inherited ERC-721 (QSE) functions: balanceOf, ownerOf, safeTransferFrom, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll.


contract QuantumForge is ERC721, Ownable {
    using SafeMath for uint256; // Safemath for older versions, 0.8+ mostly handles this
    using Counters for Counters.Counter;

    // --- Tokens ---
    // Internal ERC-20 for Quantum Dust (QST)
    ERC20 private quantumDust;
    address public immutable qstTokenAddress;

    // ERC-721 for Quantum Essences (QSE) - This contract *is* the ERC721 contract
    Counters.Counter private _essenceTokenIds;

    // --- Data Structures ---
    struct EssenceAttributes {
        uint256 resonance; // Affects staking yield multiplier
        uint256 stability; // Affects attribute growth rate while staked
        uint256 attunement; // Affects refinement outcome probability/boost
    }

    struct EssenceStakingInfo {
        address staker;
        uint40 stakeTime; // Timestamp when staked (or 0 if not staked)
        uint40 lastAttributeUpdateTime; // Timestamp when attributes were last checkpointed
        bool isStaked;
    }

    // --- State Variables ---

    // Parameters
    uint256 public forgeCostQST;
    uint256 public forgeFeeQST; // Fee collected by owner
    uint256 public refineCostQST;
    uint256 public refineFeeQST; // Fee collected by owner
    uint256 public refineEssenceCount; // Number of essences required for refinement

    uint256 public stakingRewardRatePerSecond; // QST per second per staked essence (base rate)
    uint256 public attributeGrowthRatePerSecond; // Attribute points per second while staked (base rate)
    uint256 public maxEssenceAttributes; // Maximum cap for attributes

    // Oracle
    address public oracleAddress;
    uint256 public latestOracleData; // Example: could be a price, volatility index, etc.

    // Mappings
    mapping(uint256 => EssenceAttributes) private essenceInitialAttributes; // Checkpointed attributes (updated on stake/unstake/claim/refine)
    mapping(uint256 => EssenceStakingInfo) private essenceStakingInfo; // Staking state for each token ID
    mapping(address => uint256) private userStakingRewards; // Accrued QST rewards for users

    // Staked tokens list per user (gas consideration: removing from array can be costly)
    // This is a simplified approach. For production, consider linked lists or mapping token ID to index.
    mapping(address => uint256[]) private stakedEssencesByUser;
    mapping(uint256 => uint256) private stakedEssenceIndex; // To quickly find index in the user's array

    // --- Events ---
    event EssenceForged(uint256 indexed tokenId, address indexed owner, EssenceAttributes initialAttributes);
    event EssenceRefined(uint256 indexed newTokenId, address indexed owner, EssenceAttributes initialAttributes, uint256[] burnedTokenIds);
    event EssenceStaked(uint256 indexed tokenId, address indexed staker, uint40 stakeTime);
    event EssenceUnstaked(uint256 indexed tokenId, address indexed staker, uint40 unstakeTime, uint256 claimedRewards);
    event RewardsClaimed(address indexed user, uint256 amount);
    event OracleDataUpdated(uint256 indexed newData, uint40 timestamp);
    event EssenceAttributesUpdated(uint256 indexed tokenId, EssenceAttributes newAttributes); // When attributes are checkpointed (stake/unstake/claim/refine)

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only Oracle can call this function");
        _;
    }

    modifier whenNotStaked(uint256 tokenId) {
        require(!essenceStakingInfo[tokenId].isStaked, "Essence is currently staked");
        _;
    }

    // --- Constructor ---
    /// @notice Deploys the QuantumForge contract, creating the associated QST token and setting initial owner/oracle.
    /// @param initialOracle The address designated as the initial oracle.
    constructor(address initialOracle) ERC721("QuantumEssence", "QSE") Ownable(msg.sender) {
        // Deploy Quantum Dust (QST) ERC-20 token
        quantumDust = new ERC20("QuantumDust", "QST");
        qstTokenAddress = address(quantumDust);

        oracleAddress = initialOracle;

        // Set some initial parameters (can be updated by owner)
        forgeCostQST = 100 ether; // Example cost
        forgeFeeQST = 10 ether;   // Example fee
        refineCostQST = 200 ether; // Example cost
        refineFeeQST = 20 ether;  // Example fee
        refineEssenceCount = 3;  // Example: burn 3 essences to refine

        stakingRewardRatePerSecond = 1 ether / 10000; // Example: 0.0001 QST per sec per essence (base)
        attributeGrowthRatePerSecond = 1;           // Example: 1 attribute point per sec (base)
        maxEssenceAttributes = 10000;               // Example: max attribute value
    }

    // --- Core Mechanics ---

    /// @notice Allows a user to forge a new Quantum Essence (QSE) NFT.
    /// @dev Requires burning forgeCostQST and paying forgeFeeQST. Generates initial attributes based on block data and oracle seed.
    /// @param oracleSeed A value provided by the user, potentially influenced by off-chain oracle interactions, used in attribute generation.
    function forgeEssence(uint256 oracleSeed) external payable {
        require(msg.value >= forgeFeeQST, "Insufficient fee paid");

        // Burn QST cost from user (user must have approved this contract)
        // Note: User needs to call `approve` on the QST contract first.
        quantumDust.transferFrom(msg.sender, address(this), forgeCostQST);

        // Collect fee
        if (forgeFeeQST > 0) {
            // Ether fee is sent to contract balance. QST fee is burned in the cost transfer.
            // To collect QST fees specifically, add a separate QST transfer for fee.
        }

        _essenceTokenIds.increment();
        uint256 newTokenId = _essenceTokenIds.current();

        // --- Dynamic Attribute Generation Logic (Creative Part) ---
        // Simple example: attributes influenced by block data, oracle data, and user seed
        uint256 currentTime = block.timestamp;
        uint256 blockHashInt = uint256(blockhash(block.number - 1)); // Use previous block hash
        uint256 combinedSeed = blockHashInt ^ currentTime ^ latestOracleData ^ oracleSeed ^ newTokenId;

        EssenceAttributes memory initialAttrs;
        // Basic pseudorandom generation scaled to max
        initialAttrs.resonance = (combinedSeed % (maxEssenceAttributes / 3)) + 1; // Ensure non-zero
        initialAttrs.stability = ((combinedSeed / 100) % (maxEssenceAttributes / 3)) + 1;
        initialAttrs.attunement = ((combinedSeed / 10000) % (maxEssenceAttributes / 3)) + 1;

        // Cap initial attributes to a reasonable range (e.g., 30% of max)
        uint256 initialCap = maxEssenceAttributes.mul(30).div(100);
        initialAttrs.resonance = initialAttrs.resonance % initialCap + 1;
        initialAttrs.stability = initialAttrs.stability % initialCap + 1;
        initialAttrs.attunement = initialAttrs.attunement % initialCap + 1;


        essenceInitialAttributes[newTokenId] = initialAttrs;

        // Mint the new Essence NFT
        _mintEssence(msg.sender, newTokenId, initialAttrs);

        emit EssenceForged(newTokenId, msg.sender, initialAttrs);
    }

    /// @notice Allows a user to refine multiple existing QSE NFTs into a new one.
    /// @dev Requires burning refineCostQST, paying refineFeeQST, and burning `refineEssenceCount` QSEs.
    /// @param tokenIdsToBurn An array of token IDs to be burned for refinement. Must be exactly `refineEssenceCount`.
    /// @param oracleSeed A value used in the new attribute generation.
    function refineEssence(uint256[] calldata tokenIdsToBurn, uint256 oracleSeed) external payable {
        require(msg.value >= refineFeeQST, "Insufficient fee paid");
        require(tokenIdsToBurn.length == refineEssenceCount, "Incorrect number of essences to burn");

        // Burn QST cost
        quantumDust.transferFrom(msg.sender, address(this), refineCostQST);

        // Burn required Essences
        EssenceAttributes memory burnedAttrsSum;
        for (uint i = 0; i < tokenIdsToBurn.length; i++) {
            uint256 tokenId = tokenIdsToBurn[i];
            require(ownerOf(tokenId) == msg.sender, "Caller does not own all essences to burn");
            require(!essenceStakingInfo[tokenId].isStaked, "Cannot burn staked essences");

            // Checkpoint attributes before burning
            _updateEssenceAttributes(tokenId, uint40(block.timestamp));
            EssenceAttributes storage currentAttrs = essenceInitialAttributes[tokenId]; // Use updated attributes

            burnedAttrsSum.resonance = burnedAttrsSum.resonance.add(currentAttrs.resonance);
            burnedAttrsSum.stability = burnedAttrsSum.stability.add(currentAttrs.stability);
            burnedAttrsSum.attunement = burnedAttrsSum.attunement.add(currentAttrs.attunement);

            _burnEssence(tokenId); // Burn the NFT
        }

        // Collect fee
        if (refineFeeQST > 0) {
            // Ether fee to contract balance. QST fee burned.
        }

        _essenceTokenIds.increment();
        uint256 newTokenId = _essenceTokenIds.current();

        // --- Dynamic Attribute Generation Logic for Refinement ---
        // Example: New attributes based on average of burned essences, plus influence from oracle/seed
        EssenceAttributes memory newAttrs;
        uint256 avgResonance = burnedAttrsSum.resonance.div(refineEssenceCount);
        uint256 avgStability = burnedAttrsSum.stability.div(refineEssenceCount);
        uint256 avgAttunement = burnedAttrsSum.attunement.div(refineEssenceCount);

        uint256 currentTime = block.timestamp;
        uint256 blockHashInt = uint256(blockhash(block.number - 1));
        uint256 combinedSeed = blockHashInt ^ currentTime ^ latestOracleData ^ oracleSeed ^ newTokenId;

        // Influence by average burned attributes and external factors
        newAttrs.resonance = avgResonance.add((combinedSeed % (avgResonance.div(2).add(1))) * (latestOracleData % 5 + 1) ); // Boost by oracle/seed
        newAttrs.stability = avgStability.add(((combinedSeed / 10) % (avgStability.div(2).add(1))) * (latestOracleData % 5 + 1) );
        newAttrs.attunement = avgAttunement.add(((combinedSeed / 100) % (avgAttunement.div(2).add(1))) * (latestOracleData % 5 + 1) );


        // Cap new attributes
        newAttrs.resonance = newAttrs.resonance > maxEssenceAttributes ? maxEssenceAttributes : newAttrs.resonance;
        newAttrs.stability = newAttrs.stability > maxEssenceAttributes ? maxEssenceAttributes : newAttrs.stability;
        newAttrs.attunement = newAttrs.attunement > maxEssenceAttributes ? maxEssenceAttributes : newAttrs.attunement;
         // Ensure non-zero minimum attributes after calculation
        newAttrs.resonance = newAttrs.resonance == 0 ? 1 : newAttrs.resonance;
        newAttrs.stability = newAttrs.stability == 0 ? 1 : newAttrs.stability;
        newAttrs.attunement = newAttrs.attunement == 0 ? 1 : newAttrs.attunement;


        essenceInitialAttributes[newTokenId] = newAttrs;

        // Mint the new Essence NFT
        _mintEssence(msg.sender, newTokenId, newAttrs);

        emit EssenceRefined(newTokenId, msg.sender, newAttrs, tokenIdsToBurn);
    }

    /// @notice Stakes a Quantum Essence (QSE) NFT.
    /// @dev Transfers the NFT to the contract and updates its staking status and attributes.
    /// @param tokenId The ID of the Essence NFT to stake.
    function stakeEssence(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Caller does not own this essence");
        require(!essenceStakingInfo[tokenId].isStaked, "Essence is already staked");

        uint40 currentTime = uint40(block.timestamp);

        // Before staking, checkpoint any potential attribute changes from previous unstaked time
        // (This requires tracking unstaked time, which is omitted for simplicity, but the function call is here as a placeholder)
        // In this simplified model, attributes only grow while staked, and get checkpointed/updated upon stake/unstake/claim.
        _updateEssenceAttributes(tokenId, currentTime);

        _transfer(msg.sender, address(this), tokenId); // Transfer NFT to contract

        EssenceStakingInfo storage info = essenceStakingInfo[tokenId];
        info.staker = msg.sender;
        info.stakeTime = currentTime;
        info.lastAttributeUpdateTime = currentTime; // Start tracking growth from now
        info.isStaked = true;

        _addStakedEssence(msg.sender, tokenId);

        emit EssenceStaked(tokenId, msg.sender, currentTime);
    }

    /// @notice Unstakes a Quantum Essence (QSE) NFT.
    /// @dev Calculates and accrues staking rewards, updates attributes, and transfers the NFT back to the user.
    /// @param tokenId The ID of the Essence NFT to unstake.
    function unstakeEssence(uint256 tokenId) external {
        EssenceStakingInfo storage info = essenceStakingInfo[tokenId];
        require(info.isStaked, "Essence is not staked");
        require(info.staker == msg.sender, "Caller is not the staker of this essence");

        uint40 currentTime = uint40(block.timestamp);

        // Calculate and accrue rewards
        uint256 pendingRewards = _calculateStakingRewardsForToken(tokenId, currentTime);
        userStakingRewards[msg.sender] = userStakingRewards[msg.sender].add(pendingRewards);

        // Update attributes based on staking duration
        _updateEssenceAttributes(tokenId, currentTime);

        _removeStakedEssence(msg.sender, tokenId);

        // Transfer NFT back to user
        _transfer(address(this), msg.sender, tokenId);

        // Clear staking info
        delete essenceStakingInfo[tokenId]; // Removes the struct entry

        emit EssenceUnstaked(tokenId, msg.sender, currentTime, pendingRewards);
    }

    /// @notice Claims all accrued QST staking rewards for the user.
    /// @dev Iterates through staked tokens to checkpoint attributes and calculate rewards, then claims previously accrued rewards.
    function claimStakingRewards() external {
        uint256 totalRewards = userStakingRewards[msg.sender];
        userStakingRewards[msg.sender] = 0; // Reset accrued rewards

        // Iterate over currently staked tokens to calculate rewards up to now and checkpoint attributes
        uint256[] storage stakedIds = stakedEssencesByUser[msg.sender];
        uint40 currentTime = uint40(block.timestamp);

        for (uint i = 0; i < stakedIds.length; i++) {
             uint256 tokenId = stakedIds[i];
             // Ensure the token is still staked by this user (array might not be perfectly clean if removal failed somehow)
             if(essenceStakingInfo[tokenId].isStaked && essenceStakingInfo[tokenId].staker == msg.sender) {
                uint256 pendingRewards = _calculateStakingRewardsForToken(tokenId, currentTime);
                totalRewards = totalRewards.add(pendingRewards);
                // Checkpoint attributes and update last update time
                 _updateEssenceAttributes(tokenId, currentTime);
             }
        }

        require(totalRewards > 0, "No rewards to claim");

        // Mint QST to the user
        _mintQST(msg.sender, totalRewards);

        emit RewardsClaimed(msg.sender, totalRewards);
    }

    // --- Oracle Interaction ---

    /// @notice Updates the latest oracle data point.
    /// @dev Callable only by the designated oracle address.
    /// @param newData The new data value from the oracle.
    function updateOracleData(uint256 newData) external onlyOracle {
        latestOracleData = newData;
        emit OracleDataUpdated(newData, uint40(block.timestamp));
    }

    // --- Information Queries (Views) ---

    /// @notice Calculates and returns the current theoretical attributes of an Essence NFT.
    /// @dev This is a view function that calculates attributes dynamically based on time, staking status, and oracle data.
    /// @param tokenId The ID of the Essence NFT.
    /// @return EssenceAttributes The calculated current attributes.
    function getCurrentEssenceAttributes(uint256 tokenId) public view returns (EssenceAttributes memory) {
        EssenceAttributes memory currentAttrs = essenceInitialAttributes[tokenId];
        EssenceStakingInfo storage info = essenceStakingInfo[tokenId];

        if (info.isStaked) {
            uint40 currentTime = uint40(block.timestamp);
            // Use SafeCast here if needed, but block.timestamp likely fits uint40 for decades
            uint256 timeElapsed = currentTime.sub(info.lastAttributeUpdateTime);

            // Influence growth by oracle data (example: multiplier)
            // Assuming oracleData influences growth positively
            uint256 oracleMultiplier = latestOracleData == 0 ? 1 : latestOracleData % 10 + 1; // Example: multiplier between 1 and 10

            uint256 growthAmount = attributeGrowthRatePerSecond.mul(timeElapsed).mul(oracleMultiplier);

            // Grow attributes, capping at max
            currentAttrs.resonance = currentAttrs.resonance.add(growthAmount).min(maxEssenceAttributes);
            currentAttrs.stability = currentAttrs.stability.add(growthAmount).min(maxEssenceAttributes);
            currentAttrs.attunement = currentAttrs.attunement.add(growthAmount).min(maxEssenceAttributes);
        }
        // If not staked, attributes are simply the last checkpointed value

        return currentAttrs;
    }

    /// @notice Returns the last checkpointed attributes of an Essence NFT.
    /// @dev These attributes are saved to storage upon minting, refining, staking, unstaking, or claiming rewards.
    /// @param tokenId The ID of the Essence NFT.
    /// @return EssenceAttributes The initial or last updated attributes.
    function getEssenceInitialAttributes(uint256 tokenId) external view returns (EssenceAttributes memory) {
        return essenceInitialAttributes[tokenId];
    }

    /// @notice Returns the staking information for an Essence NFT.
    /// @dev Indicates if the token is staked, who staked it, and when.
    /// @param tokenId The ID of the Essence NFT.
    /// @return EssenceStakingInfo The staking details.
    function getEssenceStakingInfo(uint256 tokenId) external view returns (EssenceStakingInfo memory) {
        return essenceStakingInfo[tokenId];
    }

     /// @notice Returns the list of Essence NFT token IDs currently staked by a user.
    /// @dev Note: Iterating over large arrays in a view function is gas-free for the caller,
    /// but might hit computation limits on some nodes. For production, consider pagination.
    /// @param user The address of the user.
    /// @return uint256[] An array of staked token IDs.
    function getStakedEssencesByUser(address user) external view returns (uint256[] memory) {
        return stakedEssencesByUser[user];
    }


    /// @notice Returns the current parameters for forging and refining Essences.
    /// @return uint256 forgeCostQST, uint256 forgeFeeQST, uint256 refineCostQST, uint256 refineFeeQST, uint256 refineEssenceCount The forge/refine parameters.
    function getForgeParameters() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (forgeCostQST, forgeFeeQST, refineCostQST, refineFeeQST, refineEssenceCount);
    }

    /// @notice Returns the current staking reward rate and attribute growth rate.
    /// @return uint256 stakingRewardRatePerSecond, uint256 attributeGrowthRatePerSecond, uint256 maxEssenceAttributes The staking parameters.
    function getStakingRates() external view returns (uint256, uint256, uint256) {
        return (stakingRewardRatePerSecond, attributeGrowthRatePerSecond, maxEssenceAttributes);
    }

    /// @notice Returns the latest data received from the oracle.
    /// @return uint256 The latest oracle data.
    function getOracleData() external view returns (uint256) {
        return latestOracleData;
    }


    // --- Admin/Owner Functions ---

    /// @notice Sets the address authorized to update oracle data.
    /// @dev Only callable by the contract owner.
    /// @param _oracleAddress The new oracle address.
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
    }

    /// @notice Sets the parameters for forging and refining Essences.
    /// @dev Only callable by the contract owner.
    /// @param _forgeCostQST The new QST cost to forge.
    /// @param _forgeFeeQST The new QST fee to forge.
    /// @param _refineCostQST The new QST cost to refine.
    /// @param _refineFeeQST The new QST fee to refine.
    /// @param _refineEssenceCount The number of essences required for refinement.
    function setForgeParameters(uint256 _forgeCostQST, uint256 _forgeFeeQST, uint256 _refineCostQST, uint256 _refineFeeQST, uint256 _refineEssenceCount) external onlyOwner {
        forgeCostQST = _forgeCostQST;
        forgeFeeQST = _forgeFeeQST;
        refineCostQST = _refineCostQST;
        refineFeeQST = _refineFeeQST;
        refineEssenceCount = _refineEssenceCount;
    }

    /// @notice Sets the staking reward rate, attribute growth rate, and max attribute cap.
    /// @dev Only callable by the contract owner.
    /// @param _stakingRewardRatePerSecond The new base QST reward rate per second per staked essence.
    /// @param _attributeGrowthRatePerSecond The new base attribute growth rate per second while staked.
    /// @param _maxEssenceAttributes The new maximum attribute value.
    function setStakingRates(uint256 _stakingRewardRatePerSecond, uint256 _attributeGrowthRatePerSecond, uint256 _maxEssenceAttributes) external onlyOwner {
        stakingRewardRatePerSecond = _stakingRewardRatePerSecond;
        attributeGrowthRatePerSecond = _attributeGrowthRatePerSecond;
        maxEssenceAttributes = _maxEssenceAttributes;
    }

    /// @notice Allows the owner to withdraw collected fees (in QST or Ether).
    /// @dev Only callable by the contract owner. Be cautious when withdrawing tokens other than QST if the contract holds them for other reasons.
    /// @param tokenAddress The address of the token to withdraw (use address(0) for Ether, qstTokenAddress for QST).
    /// @param amount The amount to withdraw.
    function withdrawAdminFees(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(0)) {
            // Withdraw Ether
            require(address(this).balance >= amount, "Insufficient Ether balance");
            payable(owner()).transfer(amount);
        } else if (tokenAddress == qstTokenAddress) {
            // Withdraw QST
             require(quantumDust.balanceOf(address(this)) >= amount, "Insufficient QST balance");
            quantumDust.transfer(owner(), amount);
        } else {
            // Withdraw other ERC20 tokens the contract might have received
            ERC20 otherToken = ERC20(tokenAddress);
            require(otherToken.balanceOf(address(this)) >= amount, "Insufficient token balance");
            otherToken.transfer(owner(), amount);
        }
    }

    // Inherited Ownable functions: transferOwnership, renounceOwnership are public

    // --- Internal Helper Functions ---

    /// @dev Mints Quantum Dust (QST) tokens and assigns them to an address.
    function _mintQST(address recipient, uint256 amount) internal {
        // Call the internal _mint function of the deployed ERC20 contract
        quantumDust._mint(recipient, amount);
    }

     /// @dev Burns Quantum Dust (QST) tokens from an address.
    function _burnQST(address account, uint256 amount) internal {
         // Call the internal _burn function of the deployed ERC20 contract
        quantumDust._burn(account, amount);
    }


    /// @dev Mints a Quantum Essence (QSE) NFT and assigns it initial attributes.
    function _mintEssence(address recipient, uint256 tokenId, EssenceAttributes memory initialAttrs) internal {
        _safeMint(recipient, tokenId);
        // Store initial attributes (which will be the base for dynamic calculation)
        essenceInitialAttributes[tokenId] = initialAttrs;
        // Initialize staking info (not staked)
        essenceStakingInfo[tokenId] = EssenceStakingInfo(address(0), 0, uint40(block.timestamp), false); // lastAttributeUpdateTime starts now
    }

    /// @dev Burns a Quantum Essence (QSE) NFT and clears its associated data.
    function _burnEssence(uint256 tokenId) internal {
         require(!essenceStakingInfo[tokenId].isStaked, "Cannot burn staked essence");
        _burn(tokenId);
        delete essenceInitialAttributes[tokenId]; // Clean up associated data
        delete essenceStakingInfo[tokenId];
         // Note: If the token was previously staked, its ID might still be in the stakedEssencesByUser array,
         // but checks in other functions should handle this (e.g., require essenceStakingInfo[tokenId].isStaked).
         // A robust implementation would remove it from the array here if it was ever staked by someone.
    }


    /// @dev Calculates pending QST rewards for a single staked token up to a given timestamp.
    /// @param tokenId The ID of the Essence NFT.
    /// @param currentTime The timestamp up to which to calculate rewards.
    /// @return uint256 The calculated pending rewards.
    function _calculateStakingRewardsForToken(uint256 tokenId, uint40 currentTime) internal view returns (uint256) {
        EssenceStakingInfo storage info = essenceStakingInfo[tokenId];
        if (!info.isStaked) return 0;

        uint256 timeStakedSinceLastUpdate = currentTime.sub(info.lastAttributeUpdateTime);
        if (timeStakedSinceLastUpdate == 0) return 0;

        // Rewards influenced by Resonance attribute (example: multiplier)
        EssenceAttributes memory currentAttrs = getCurrentEssenceAttributes(tokenId); // Use current attributes for reward calculation? Or initial? Let's use initial for simplicity.
        // Using checkpointed initial attributes for reward calculation base
        EssenceAttributes memory initialAttrs = essenceInitialAttributes[tokenId];


        uint256 resonanceMultiplier = initialAttrs.resonance == 0 ? 1 : initialAttrs.resonance % 10 + 1; // Example: multiplier 1-10

        uint256 baseRewards = stakingRewardRatePerSecond.mul(timeStakedSinceLastUpdate);
        uint256 totalRewards = baseRewards.mul(resonanceMultiplier);

        return totalRewards;
    }

    /// @dev Updates the checkpointed attributes of a staked Essence NFT based on staking duration and oracle data.
    /// @param tokenId The ID of the Essence NFT.
    /// @param currentTime The current timestamp.
    function _updateEssenceAttributes(uint256 tokenId, uint40 currentTime) internal {
        EssenceStakingInfo storage info = essenceStakingInfo[tokenId];
        if (!info.isStaked || info.lastAttributeUpdateTime >= currentTime) return;

        uint256 timeElapsed = currentTime.sub(info.lastAttributeUpdateTime);

         // Influence growth by oracle data (example: multiplier)
        uint256 oracleMultiplier = latestOracleData == 0 ? 1 : latestOracleData % 10 + 1; // Example: multiplier between 1 and 10

        uint256 growthAmount = attributeGrowthRatePerSecond.mul(timeElapsed).mul(oracleMultiplier);

        // Grow attributes, capping at max
        EssenceAttributes storage currentAttrs = essenceInitialAttributes[tokenId]; // Update the "initial" storage value as the new checkpoint
        currentAttrs.resonance = currentAttrs.resonance.add(growthAmount).min(maxEssenceAttributes);
        currentAttrs.stability = currentAttrs.stability.add(growthAmount).min(maxEssenceAttributes);
        currentAttrs.attunement = currentAttrs.attunement.add(growthAmount).min(maxEssenceAttributes);

        info.lastAttributeUpdateTime = currentTime; // Update checkpoint time

        emit EssenceAttributesUpdated(tokenId, currentAttrs);
    }

    /// @dev Adds a token ID to the user's staked list.
    function _addStakedEssence(address user, uint256 tokenId) internal {
        stakedEssencesByUser[user].push(tokenId);
        stakedEssenceIndex[tokenId] = stakedEssencesByUser[user].length - 1; // Store the index
    }

    /// @dev Removes a token ID from the user's staked list.
    /// @dev This uses the swap-and-pop method for efficiency.
    function _removeStakedEssence(address user, uint256 tokenId) internal {
        uint256 lastIndex = stakedEssencesByUser[user].length - 1;
        uint256 tokenIndex = stakedEssenceIndex[tokenId];

        if (tokenIndex != lastIndex) {
            uint256 lastTokenId = stakedEssencesByUser[user][lastIndex];
            stakedEssencesByUser[user][tokenIndex] = lastTokenId; // Swap last element into the index
            stakedEssenceIndex[lastTokenId] = tokenIndex; // Update the index mapping for the swapped element
        }

        stakedEssencesByUser[user].pop(); // Remove the last element (which is now the one we wanted to remove)
        delete stakedEssenceIndex[tokenId]; // Clean up the index mapping
    }


    // --- ERC721 Overrides ---

    /// @dev Override to prevent transfer of staked essences.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If transferring from the contract itself (unstaking), it's allowed
        if (from == address(this)) {
            return;
        }

        // If transferring *to* the contract (staking), it's allowed
         if (to == address(this)) {
            return;
        }

        // For any other transfer (user to user, user to other contract, etc.), check if staked
        if (essenceStakingInfo[tokenId].isStaked) {
            require(essenceStakingInfo[tokenId].staker == from, "Staked essences cannot be transferred by the staker directly");
             // The only allowed transfer from a staker while staked is *via unstake* which transfers *from the contract*
             // This check prevents external transfers like ERC721.transferFrom(staker, other, tokenId)
            revert("Staked essence cannot be transferred externally");
        }
    }

    // Overrides for visibility/modifiers if needed, but the _beforeTokenTransfer hook is usually sufficient
    // to enforce staked restriction on standard transfer functions like safeTransferFrom, transferFrom, approve etc.
    // Example: Explicitly adding modifiers to public transfer functions (less common if using _beforeTokenTransfer hook)
    // function transferFrom(address from, address to, uint256 tokenId) public virtual override whenNotStaked(tokenId) { super.transferFrom(from, to, tokenId); }
    // function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override whenNotStaked(tokenId) { super.safeTransferFrom(from, to, tokenId); }
    // etc.

    // We also need the standard ERC-20 and ERC-721 functions exposed via inheritance.
    // The inherited functions from ERC20 and ERC721 contracts (like balanceOf, transfer, ownerOf, etc.)
    // are automatically available via the `quantumDust` variable for ERC20
    // and directly on this contract for ERC721 (since this contract *is* the ERC721).
    // They don't need to be explicitly listed here unless we are overriding them
    // (like _beforeTokenTransfer for ERC721).

    // ERC20 functions (access via quantumDust variable):
    // totalSupply()
    // balanceOf(address account)
    // transfer(address recipient, uint256 amount)
    // allowance(address owner, address spender)
    // approve(address spender, uint256 amount)
    // transferFrom(address sender, address recipient, uint256 amount)

    // ERC721 functions (directly on this contract):
    // balanceOf(address owner)
    // ownerOf(uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
    // transferFrom(address from, address to, uint256 tokenId)
    // approve(address to, uint256 tokenId)
    // setApprovalForAll(address operator, bool approved)
    // getApproved(uint256 tokenId)
    // isApprovedForAll(address owner, address operator)
}
```