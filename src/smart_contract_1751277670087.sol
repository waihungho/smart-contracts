Okay, here is a smart contract in Solidity incorporating several advanced, creative, and trendy concepts beyond standard token or simple NFT contracts.

This contract, named `Auraforge`, represents a dynamic digital asset ecosystem where users can mint unique "Aura" NFTs that evolve, manage an associated "Essence" ERC-20 token, build on-chain "Reputation," and participate in staking and delegated reputation.

It includes concepts like:
*   **Dynamic NFTs:** Aura properties change based on user actions (upgrading).
*   **Dual Token System:** Interplay between an ERC-20 (Essence) and ERC-721 (Aura) within the same ecosystem.
*   **On-chain Reputation:** A non-transferable score influencing user capabilities.
*   **Liquid Reputation Delegation:** Users can delegate their reputation to others.
*   **NFT Staking:** Lock NFTs to potentially earn rewards or reputation over time.
*   **Resource Sinks:** Essence is consumed for actions like forging, upgrading, and boosting reputation, accumulating within the contract.
*   **Parameterized System:** Key costs, rates, and requirements are stored as state variables, allowing potential future governance or admin tuning.
*   **Pausable:** Standard security pattern.

It aims to be creative by combining these elements into a simple, fictional game-like economy structure.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Included for easier listing, though not strictly required by ERC721 base
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- OUTLINE ---
// 1. Imports: OpenZeppelin standard contracts for ERC20, ERC721, Ownable, Pausable, etc.
// 2. Errors: Custom error types for clarity and gas efficiency.
// 3. Events: Announce important actions like forging, upgrading, staking, reputation changes.
// 4. Structs: Define data structures for Aura properties and Staking info.
// 5. State Variables: Store contract parameters, user balances, token data, reputation, staking data.
// 6. ERC20 Implementation (AuraforgeEssence): Inherit and manage the Essence token.
// 7. ERC721 Implementation (AuraforgeAura): Inherit and manage the Aura NFTs, including dynamic properties.
// 8. Constructor: Initialize tokens and base parameters.
// 9. ERC20 Standard Functions: Public methods required by ERC20 interface (inherited).
// 10. ERC721 Standard Functions: Public methods required by ERC721 interface (inherited).
// 11. Aura Interaction Functions: Forging, upgrading, refining Auras.
// 12. Reputation System Functions: Getting reputation, boosting reputation, delegation.
// 13. Staking Functions: Staking, unstaking, claiming rewards, querying staking state.
// 14. Parameter & Query Functions: Get contract parameters, user-specific data, accumulated fees.
// 15. Admin Functions (Ownable): Set parameters, withdraw fees, pause/unpause.
// 16. Internal Helper Functions: Logic used internally (e.g., calculating rewards, spending essence).

// --- FUNCTION SUMMARY ---
// ERC20 Interface (Implemented by inheriting ERC20):
// 1.  balanceOf(address account) view: Get Essence balance.
// 2.  transfer(address to, uint256 amount): Transfer Essence.
// 3.  approve(address spender, uint256 amount): Approve spender for Essence.
// 4.  transferFrom(address from, address to, uint256 amount): Transfer Essence via allowance.
// 5.  allowance(address owner, address spender) view: Get Essence allowance.
// 6.  totalSupply() view: Get total Essence supply.
// 7.  name() view: Get Essence token name ("Auraforge Essence").
// 8.  symbol() view: Get Essence token symbol ("AFE").
// 9.  decimals() view: Get Essence decimals (18).

// ERC721 Interface (Implemented by inheriting ERC721 and ERC721Enumerable):
// 10. balanceOf(address owner) view: Get number of Auras owned by an address.
// 11. ownerOf(uint256 tokenId) view: Get owner of an Aura.
// 12. safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer of Aura.
// 13. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safe transfer with data.
// 14. transferFrom(address from, address to, uint256 tokenId): Transfer of Aura.
// 15. approve(address to, uint256 tokenId): Approve address for specific Aura.
// 16. setApprovalForAll(address operator, bool approved): Approve operator for all Auras.
// 17. getApproved(uint256 tokenId) view: Get approved address for an Aura.
// 18. isApprovedForAll(address owner, address operator) view: Check if operator is approved for all Auras.
// 19. tokenURI(uint256 tokenId) view: Get metadata URI for an Aura (dynamic based on properties).
// 20. supportsInterface(bytes4 interfaceId) view: ERC165 interface support.
// 21. totalSupply() view: Get total number of Auras minted. (From ERC721Enumerable)
// 22. tokenByIndex(uint256 index) view: Get Aura ID by index. (From ERC721Enumerable)
// 23. tokenOfOwnerByIndex(address owner, uint256 index) view: Get Aura ID by owner and index. (From ERC721Enumerable)

// Aura Interaction & Ecosystem Functions:
// 24. forgeAura(): Mint a new Aura NFT. Requires Essence and Reputation.
// 25. upgradeAura(uint256 tokenId): Improve an existing Aura's properties. Requires Essence and Reputation.
// 26. refineAura(uint256 tokenId): Burn an Aura to recover some Essence.
// 27. getTokenProperties(uint256 tokenId) view: Get the dynamic properties of an Aura.
// 28. getAuraLevel(uint256 tokenId) view: Get the calculated level of an Aura based on properties.

// Reputation System Functions:
// 29. getReputation(address account) view: Get the total effective reputation of an address (self + delegated).
// 30. getSelfReputation(address account) view: Get the base reputation earned by an address.
// 31. boostReputation(uint256 essenceAmount): Spend Essence to increase base reputation.
// 32. delegateReputation(address delegatee): Delegate reputation voting power to another address.
// 33. undelegateReputation(): Remove reputation delegation.
// 34. getDelegatedReputation(address account) view: Get total reputation delegated *to* an address.
// 35. getReputationDelegator(address account) view: Get the address an account is delegating *to*.

// Staking Functions:
// 36. stakeAura(uint256 tokenId): Stake an Aura NFT to earn rewards/reputation.
// 37. unstakeAura(uint256 tokenId): Unstake an Aura NFT. Claims pending rewards.
// 38. claimStakingRewards(uint256 tokenId): Claim pending rewards from a staked Aura without unstaking.
// 39. getUserStakedAuras(address account) view: Get list of Aura IDs staked by an address.
// 40. getPendingRewards(uint256 tokenId) view: Calculate pending rewards for a staked Aura.
// 41. getTotalAurasStaked() view: Get the total number of Auras currently staked in the contract.

// Parameter & Query Functions:
// 42. getMinimumReputationForForging() view: Get min reputation needed to forge.
// 43. getMinimumReputationForUpgrading() view: Get min reputation needed to upgrade.
// 44. getForgingEssenceCost() view: Get Essence cost to forge.
// 45. getUpgradeEssenceCostBase() view: Get base Essence cost to upgrade.
// 46. getReputationBoostCost() view: Get Essence cost per reputation point boost.
// 47. getStakingYieldRate() view: Get Essence reward rate per second for staking.
// 48. getRefineEssenceReturn() view: Get percentage of forging cost returned when refining.
// 49. getAccumulatedFees() view: Get total Essence collected as fees/sinks.
// 50. getContractEssenceBalance() view: Get contract's current Essence balance (includes fees + unstaked/minted essence).

// Admin Functions (Ownable):
// 51. setMinimumReputationForForging(uint256 minRep): Set min reputation for forging.
// 52. setMinimumReputationForUpgrading(uint256 minRep): Set min reputation for upgrading.
// 53. setForgingEssenceCost(uint256 cost): Set Essence cost for forging.
// 54. setUpgradeEssenceCostBase(uint256 cost): Set base Essence cost for upgrading.
// 55. setReputationBoostCost(uint256 cost): Set Essence cost per reputation point boost.
// 56. setReputationBoostAmount(uint256 amount): Set reputation gained per boost action.
// 57. setStakingYieldRate(uint256 rate): Set Essence reward rate per second for staking.
// 58. setRefineEssenceReturn(uint256 percentage): Set percentage return when refining (0-100).
// 59. withdrawFees(address recipient): Withdraw accumulated Essence fees to an address.
// 60. pause(): Pause certain contract actions.
// 61. unpause(): Unpause contract actions.
// 62. paused() view: Check if contract is paused. (From Pausable)
// 63. mintInitialEssence(address account, uint256 amount): Mint initial supply for distribution (only by deployer).

// Internal Helper Functions (Not exposed externally):
// calculateAuraLevel(uint256 tokenId): Calculates aura level.
// _spendEssence(address from, uint256 amount): Handles internal Essence transfer for costs.
// _mintEssence(address to, uint256 amount): Handles internal Essence minting (e.g., for rewards).
// _calculateStakingRewards(uint256 tokenId): Calculates pending staking rewards.
// _updateStakingStartTime(uint256 tokenId): Resets staking timer after rewards claim.
// _transferToStaking(uint256 tokenId): Transfers NFT ownership to contract for staking.
// _transferFromStaking(uint256 tokenId): Transfers NFT ownership from contract upon unstaking.

contract Auraforge is ERC20, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Errors ---
    error NotEnoughEssence(uint256 required, uint256 has);
    error NotEnoughReputation(uint256 required, uint256 has);
    error AuraNotFound(uint256 tokenId);
    error NotAuraOwner(uint256 tokenId, address caller);
    error AuraAlreadyStaked(uint256 tokenId);
    error AuraNotStaked(uint256 tokenId);
    error CannotRefineStakedAura(uint256 tokenId);
    error InvalidRefinePercentage();
    error CannotDelegateToSelf();
    error DelegateeCannotBeZeroAddress();
    error NoActiveDelegation(address account);


    // --- Events ---
    event AuraForged(address indexed owner, uint256 indexed tokenId, uint256 forgingCost, uint256 ownerReputation);
    event AuraUpgraded(uint256 indexed tokenId, uint256 newLevel, uint256 upgradeCost, uint256 ownerReputation);
    event AuraRefined(address indexed owner, uint256 indexed tokenId, uint256 essenceReturned);
    event ReputationBoosted(address indexed account, uint256 essenceCost, uint256 reputationGained, uint256 newTotalReputation);
    event AuraStaked(address indexed owner, uint256 indexed tokenId, uint256 stakingStartTime);
    event AuraUnstaked(address indexed owner, uint256 indexed tokenId, uint256 rewardsClaimed);
    event StakingRewardsClaimed(address indexed owner, uint256 indexed tokenId, uint256 rewardsAmount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator);
    event ParameterUpdated(string paramName, uint256 oldValue, uint256 newValue);


    // --- Structs ---
    struct AuraProperties {
        uint256 level;       // Level increases with upgrades
        uint256 primaryTrait; // Example trait (could represent power, visual aspect, etc.)
        uint256 secondaryTrait; // Another example trait
        // Could add more traits, unique IDs, etc.
    }

    struct StakingInfo {
        address staker;      // Address that staked the token
        uint40 startTime;    // Timestamp when staking started or rewards were last claimed
        bool isStaked;       // Is the token currently staked
    }


    // --- State Variables ---

    // Token Data
    mapping(uint256 => AuraProperties) private _auraProperties;
    mapping(uint256 => StakingInfo) private _stakingInfo;
    uint256 private _totalAurasStaked;

    // Ecosystem Parameters (Can be tuned by owner/governance)
    uint256 public minimumReputationForForging;
    uint256 public minimumReputationForUpgrading;
    uint256 public forgingEssenceCost;
    uint256 public upgradeEssenceCostBase; // Base cost for first upgrade
    uint256 public reputationBoostCost;    // Essence cost per reputation point gained
    uint256 public reputationBoostAmount;  // How much reputation is gained per boost action
    uint256 public stakingYieldRate;       // Essence per second per staked Aura (in wei)
    uint256 public refineEssenceReturnPercentage; // Percentage of forging cost returned (0-100)

    // Reputation Data (Non-transferable score)
    mapping(address => uint256) private _reputation;
    mapping(address => address) private _reputationDelegatee; // Address user delegates reputation to
    mapping(address => uint256) private _delegatedReputationCount; // Total reputation delegated *to* an address

    // Accumulated Fees
    uint256 private _accumulatedFees;


    // --- Constructor ---
    constructor(uint256 initialEssenceSupply)
        ERC20("Auraforge Essence", "AFE")
        ERC721("Auraforge Aura", "AFA")
        Ownable(msg.sender)
        Pausable()
    {
        // Initialize parameters (Owner can change these later)
        minimumReputationForForging = 100;
        minimumReputationForUpgrading = 200;
        forgingEssenceCost = 500 ether; // Example cost in wei (using 18 decimals)
        upgradeEssenceCostBase = 200 ether; // Example base cost
        reputationBoostCost = 1 ether; // 1 Essence per reputation point
        reputationBoostAmount = 10; // Gain 10 reputation per boost action
        stakingYieldRate = 1000; // Example: 1000 wei (0.000000000000001 Essence) per second per Aura
        refineEssenceReturnPercentage = 75; // Return 75% of forging cost

        // Mint initial supply to the deployer (or a specified treasury/distribution contract)
        _mint(msg.sender, initialEssenceSupply);
        emit Transfer(address(0), msg.sender, initialEssenceSupply); // ERC20 Transfer event for initial mint
    }

    // --- ERC721 Standard Functions (Overridden/Required) ---

    // Override _update and _increaseBalance to correctly handle staking ownership
    // When staking, ownership moves to the contract address
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        // If transferring *to* this contract address, it's likely staking
        // If transferring *from* this contract address, it's likely unstaking
        // ERC721Enumerable requires hooks for internal state changes
        return super._update(to, tokenId, auth);
    }

    // Override _increaseBalance to correctly handle staking balance vs user balance
    // Not strictly necessary for _balanceOf if relying solely on super.balanceOf,
    // but useful if tracking contract balance separately. For this contract, ERC721Enumerable handles balances.
    function _increaseBalance(address account, uint176 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }


    /// @dev Generates dynamic metadata URI for an Aura based on its properties.
    /// In a real dApp, this would point to a backend service or IPFS gateway
    /// that serves JSON metadata based on the token ID and its current properties.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        // Construct a simple base URI, real implementations would pass tokenId to a service
        string memory baseURI = "ipfs://auraforge/metadata/";
        string memory uri = string(abi.encodePacked(baseURI, Strings.toString(tokenId)));

        // Optional: Append parameters to the URI for dynamic fetching
        // Example: ipfs://auraforge/metadata/123?level=5&primaryTrait=1&secondaryTrait=2
        AuraProperties storage props = _auraProperties[tokenId];
        string memory dynamicParams = string(abi.encodePacked(
            "?level=", Strings.toString(props.level),
            "&primaryTrait=", Strings.toString(props.primaryTrait),
            "&secondaryTrait=", Strings.toString(props.secondaryTrait)
        ));

        return string(abi.encodePacked(uri, dynamicParams));
    }

    // --- Aura Interaction & Ecosystem Functions ---

    /// @dev Forges a new Aura NFT. Requires sufficient Essence and Reputation.
    /// The forging cost in Essence is sent to the contract as a fee sink.
    /// Base properties for the first Aura are simple defaults here.
    function forgeAura() external payable nonReentrant whenNotPaused {
        address sender = msg.sender;
        uint256 currentReputation = getReputation(sender);

        if (currentReputation < minimumReputationForForging) {
            revert NotEnoughReputation(minimumReputationForForging, currentReputation);
        }

        // Essence cost must be paid
        _spendEssence(sender, forgingEssenceCost);
        _accumulatedFees += forgingEssenceCost;

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // Mint the new Aura to the sender
        _safeMint(sender, newItemId);

        // Assign base properties to the new Aura
        _auraProperties[newItemId] = AuraProperties({
            level: 1,
            primaryTrait: 1, // Example initial trait value
            secondaryTrait: 1 // Example initial trait value
        });

        emit AuraForged(sender, newItemId, forgingEssenceCost, currentReputation);
    }

    /// @dev Upgrades an existing Aura NFT. Requires sufficient Essence and Reputation.
    /// Upgrade increases the Aura's level and potentially modifies traits.
    /// Costs increase with the current level of the Aura.
    function upgradeAura(uint256 tokenId) external payable nonReentrant whenNotPaused {
        address sender = msg.sender;
        address owner = ownerOf(tokenId); // Uses ERC721 ownerOf

        if (owner != sender) {
            revert NotAuraOwner(tokenId, sender);
        }
        if (_stakingInfo[tokenId].isStaked) {
            revert AuraAlreadyStaked(tokenId); // Cannot upgrade if staked - must unstake first
        }

        uint256 currentReputation = getReputation(sender);
        if (currentReputation < minimumReputationForUpgrading) {
            revert NotEnoughReputation(minimumReputationForUpgrading, currentReputation);
        }

        AuraProperties storage props = _auraProperties[tokenId];
        uint256 currentLevel = props.level;

        // Calculate upgrade cost: base cost + cost increases with level
        uint256 upgradeCost = upgradeEssenceCostBase + (upgradeEssenceCostBase * (currentLevel - 1) / 10); // Example: 10% increase per level

        _spendEssence(sender, upgradeCost);
        _accumulatedFees += upgradeCost;

        // Apply upgrade effects: Increase level and modify traits (example logic)
        props.level = currentLevel + 1;
        props.primaryTrait = props.primaryTrait + 1; // Simple increment
        props.secondaryTrait = props.secondaryTrait + currentLevel % 3; // More complex example increment

        emit AuraUpgraded(tokenId, props.level, upgradeCost, currentReputation);
    }

    /// @dev Burns an Aura NFT and returns a percentage of its forging cost in Essence.
    function refineAura(uint256 tokenId) external nonReentrant whenNotPaused {
        address sender = msg.sender;
        address owner = ownerOf(tokenId);

        if (owner != sender) {
            revert NotAuraOwner(tokenId, sender);
        }
         if (_stakingInfo[tokenId].isStaked) {
            revert CannotRefineStakedAura(tokenId); // Cannot refine if staked
        }

        // Calculate Essence to return based on original forging cost and percentage
        uint256 essenceReturn = (forgingEssenceCost * refineEssenceReturnPercentage) / 100;

        // Ensure the contract has enough accumulated fees/Essence to return
        if (_accumulatedFees < essenceReturn) {
             // In a real system, you'd handle this carefully.
             // For simplicity here, we assume the contract will eventually have enough,
             // or fees are managed off-chain/differently. Or reduce the return percentage.
             // For this example, let's just revert if fees aren't enough to keep it simple.
             // A more robust system might draw from a general pool or return less.
             revert NotEnoughEssence(essenceReturn, _accumulatedFees);
        }
        _accumulatedFees -= essenceReturn; // Reduce fees
        _mint(sender, essenceReturn); // Mint new essence to the user (or transfer from contract balance if not minting)

        // Burn the Aura
        _burn(tokenId);
        delete _auraProperties[tokenId]; // Clean up properties

        emit AuraRefined(sender, tokenId, essenceReturn);
    }

    /// @dev Gets the dynamic properties of a given Aura token.
    function getTokenProperties(uint256 tokenId) public view returns (AuraProperties memory) {
         if (!_exists(tokenId)) {
            revert AuraNotFound(tokenId);
        }
        return _auraProperties[tokenId];
    }

     /// @dev Calculates the level of an Aura based on its dynamic properties.
    function getAuraLevel(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            revert AuraNotFound(tokenId);
        }
        // Simple example: Level is stored directly. Could be calculated from traits.
        return _auraProperties[tokenId].level;
    }

    // --- Reputation System Functions ---

    /// @dev Gets the effective total reputation of an account, including self-earned and delegated reputation.
    function getReputation(address account) public view returns (uint256) {
        if (account == address(0)) return 0;
        // Effective reputation is self-reputation + reputation delegated *to* this account
        return _reputation[account] + _delegatedReputationCount[account];
    }

    /// @dev Gets the base reputation earned directly by an account, excluding delegated reputation.
    function getSelfReputation(address account) public view returns (uint256) {
        if (account == address(0)) return 0;
        return _reputation[account];
    }

    /// @dev Allows a user to spend Essence to boost their base reputation score.
    function boostReputation(uint256 essenceAmount) external payable nonReentrant whenNotPaused {
        address sender = msg.sender;

        if (essenceAmount == 0) return; // No op if 0 amount

        uint256 reputationGain = (essenceAmount / reputationBoostCost) * reputationBoostAmount;
        if (reputationGain == 0) {
             // Revert if the amount is less than the cost needed for any gain
             revert NotEnoughEssence(reputationBoostCost, essenceAmount);
        }

        // Spend the Essence
        _spendEssence(sender, essenceAmount);
        _accumulatedFees += essenceAmount; // Add to fee sink

        // Increase base reputation
        _reputation[sender] += reputationGain;

        emit ReputationBoosted(sender, essenceAmount, reputationGain, _reputation[sender]);
    }

    /// @dev Delegates the calling account's *self-reputation* voting power to another address.
    /// The effective reputation for actions like forging/upgrading will use the delegatee's total reputation.
    function delegateReputation(address delegatee) external nonReentrant whenNotPaused {
        address sender = msg.sender;
        if (sender == delegatee) {
            revert CannotDelegateToSelf();
        }
        if (delegatee == address(0)) {
            revert DelegateeCannotBeZeroAddress();
        }

        address currentDelegatee = _reputationDelegatee[sender];

        // If already delegating, first remove from the old delegatee's count
        if (currentDelegatee != address(0)) {
             _delegatedReputationCount[currentDelegatee] -= _reputation[sender];
        }

        // Set the new delegatee
        _reputationDelegatee[sender] = delegatee;
        // Add the sender's self-reputation to the new delegatee's count
        _delegatedReputationCount[delegatee] += _reputation[sender];

        emit ReputationDelegated(sender, delegatee);
    }

    /// @dev Removes the current reputation delegation.
    function undelegateReputation() external nonReentrant whenNotPaused {
        address sender = msg.sender;
        address currentDelegatee = _reputationDelegatee[sender];

        if (currentDelegatee == address(0)) {
            revert NoActiveDelegation(sender);
        }

        // Remove the sender's self-reputation from the delegatee's count
        _delegatedReputationCount[currentDelegatee] -= _reputation[sender];

        // Clear the delegatee
        delete _reputationDelegatee[sender];

        emit ReputationUndelegated(sender);
    }

    /// @dev Gets the total reputation that has been delegated *to* a specific address.
    function getDelegatedReputation(address account) public view returns (uint256) {
        if (account == address(0)) return 0;
        return _delegatedReputationCount[account];
    }

    /// @dev Gets the address that an account is currently delegating their reputation to.
    /// Returns address(0) if no active delegation.
    function getReputationDelegator(address account) public view returns (address) {
        return _reputationDelegatee[account];
    }

    // --- Staking Functions ---

    /// @dev Stakes an Aura NFT. The NFT is transferred to the contract.
    function stakeAura(uint256 tokenId) external nonReentrant whenNotPaused {
        address sender = msg.sender;
        address owner = ownerOf(tokenId); // Uses ERC721 ownerOf

        if (owner != sender) {
            revert NotAuraOwner(tokenId, sender);
        }
         if (_stakingInfo[tokenId].isStaked) {
            revert AuraAlreadyStaked(tokenId);
        }

        // Transfer the token to the contract
        _transferToStaking(tokenId);

        // Record staking info
        _stakingInfo[tokenId] = StakingInfo({
            staker: sender,
            startTime: uint40(block.timestamp),
            isStaked: true
        });

        _totalAurasStaked++;

        emit AuraStaked(sender, tokenId, block.timestamp);
    }

    /// @dev Unstakes an Aura NFT. Transfers the NFT back to the owner and claims pending rewards.
    function unstakeAura(uint256 tokenId) external nonReentrant whenNotPaused {
        address sender = msg.sender;
        StakingInfo storage staking = _stakingInfo[tokenId];

        // Ensure the caller was the staker and it is currently staked
        if (!staking.isStaked || staking.staker != sender) {
            revert AuraNotStaked(tokenId);
        }

        // Claim pending rewards before unstaking
        uint256 claimedRewards = claimStakingRewards(tokenId);

        // Transfer the token back to the staker
        _transferFromStaking(tokenId);

        // Clear staking info
        delete _stakingInfo[tokenId];
        _totalAurasStaked--;

        emit AuraUnstaked(sender, tokenId, claimedRewards);
    }

    /// @dev Claims pending rewards from a staked Aura without unstaking it.
    /// Resets the staking timer for that token. Rewards are minted as Essence.
    function claimStakingRewards(uint256 tokenId) public nonReentrant whenNotPaused returns (uint256 rewardsAmount) {
        StakingInfo storage staking = _stakingInfo[tokenId];

         // Ensure the caller was the staker and it is currently staked
        if (!staking.isStaked || staking.staker != msg.sender) {
            revert AuraNotStaked(tokenId);
        }

        rewardsAmount = _calculateStakingRewards(tokenId);

        if (rewardsAmount > 0) {
            // Mint Essence rewards to the staker
            _mintEssence(staking.staker, rewardsAmount);
            emit StakingRewardsClaimed(staking.staker, tokenId, rewardsAmount);

            // Optional: Provide a small reputation boost for claiming
            // _reputation[staking.staker] += rewardsAmount / 100; // Example small boost
        }

        // Update the staking start time to now for future reward calculations
        _updateStakingStartTime(tokenId);

        return rewardsAmount;
    }

    /// @dev Internal helper to calculate pending staking rewards.
    function _calculateStakingRewards(uint256 tokenId) internal view returns (uint256) {
        StakingInfo storage staking = _stakingInfo[tokenId];
        if (!staking.isStaked) {
            return 0;
        }

        // Calculate duration staked since last claim/stake time
        uint256 duration = block.timestamp - staking.startTime;

        // Calculate rewards: duration * yield rate
        // Ensure no overflow for very long durations or high rates if necessary (not shown here for brevity)
        return duration * stakingYieldRate;
    }

    /// @dev Internal helper to update the staking start time.
    function _updateStakingStartTime(uint256 tokenId) internal {
         StakingInfo storage staking = _stakingInfo[tokenId];
         if (staking.isStaked) {
              staking.startTime = uint40(block.timestamp);
         }
    }


    /// @dev Internal helper to transfer NFT to contract for staking.
    function _transferToStaking(uint256 tokenId) internal {
        // Transfer from current owner to this contract address
        // Use _transfer which doesn't check onERC721Received on the recipient (this contract)
        _transfer(ownerOf(tokenId), address(this), tokenId);
    }

     /// @dev Internal helper to transfer NFT from contract upon unstaking.
    function _transferFromStaking(uint256 tokenId) internal {
        address staker = _stakingInfo[tokenId].staker;
        // Transfer from this contract address back to the original staker
        _transfer(address(this), staker, tokenId);
    }

    /// @dev Gets the list of Aura token IDs currently staked by a user.
    /// Note: This is gas-intensive for users with many staked tokens.
    /// An off-chain indexer is recommended for production.
    function getUserStakedAuras(address account) external view returns (uint256[] memory) {
        uint256 totalStaked = _totalAurasStaked; // Total count in the contract
        uint256[] memory stakedTokens = new uint256[](totalStaked);
        uint256 count = 0;

        // Iterate through all possible token IDs up to the max minted.
        // This is INEFFICIENT. A mapping from staker address to staked token IDs is better,
        // but adds complexity to stake/unstake logic. Sticking to this simple iteration
        // for the example to meet function count without excessive state/complexity.
        // max minted ID might be high, this loop could hit gas limits.
        // Better approach: Require ERC721Enumerable and iterate tokens owned by THIS contract address.
        // Let's use ERC721Enumerable's tokenOfOwnerByIndex on *this* contract's address.

        uint256 contractStakedCount = balanceOf(address(this)); // Auras owned by this contract (staked)
        uint256[] memory userStakedTokens = new uint256[](contractStakedCount);
        uint256 userStakedCount = 0;

        for (uint256 i = 0; i < contractStakedCount; i++) {
             uint256 tokenId = tokenOfOwnerByIndex(address(this), i);
             if (_stakingInfo[tokenId].isStaked && _stakingInfo[tokenId].staker == account) {
                 userStakedTokens[userStakedCount] = tokenId;
                 userStakedCount++;
             }
        }

        // Resize array
        uint256[] memory finalStakedTokens = new uint256[](userStakedCount);
        for (uint256 i = 0; i < userStakedCount; i++) {
            finalStakedTokens[i] = userStakedTokens[i];
        }
        return finalStakedTokens;

    }

    /// @dev Calculates the pending Essence rewards for a specific staked Aura.
    function getPendingRewards(uint256 tokenId) public view returns (uint256) {
         StakingInfo storage staking = _stakingInfo[tokenId];
         if (!staking.isStaked || staking.staker == address(0)) {
             return 0; // Not staked or invalid
         }
         return _calculateStakingRewards(tokenId);
    }

    /// @dev Gets the total number of Aura NFTs currently staked in the contract.
    function getTotalAurasStaked() public view returns (uint256) {
        return _totalAurasStaked;
    }

    // --- Parameter & Query Functions ---

    function getMinimumReputationForForging() public view returns (uint256) { return minimumReputationForForging; }
    function getMinimumReputationForUpgrading() public view returns (uint256) { return minimumReputationForUpgrading; }
    function getForgingEssenceCost() public view returns (uint256) { return forgingEssenceCost; }
    function getUpgradeEssenceCostBase() public view returns (uint256) { return upgradeEssenceCostBase; }
    function getReputationBoostCost() public view returns (uint256) { return reputationBoostCost; }
    function getReputationBoostAmount() public view returns (uint256) { return reputationBoostAmount; }
    function getStakingYieldRate() public view returns (uint256) { return stakingYieldRate; }
    function getRefineEssenceReturn() public view returns (uint256) { return refineEssenceReturnPercentage; }
    function getAccumulatedFees() public view returns (uint256) { return _accumulatedFees; }

    /// @dev Gets the contract's current balance of Auraforge Essence.
    /// This includes accumulated fees and Essence potentially minted for staking/refining rewards
    /// that hasn't been withdrawn by the admin yet.
    function getContractEssenceBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    // --- Admin Functions (Ownable) ---

    function setMinimumReputationForForging(uint256 minRep) external onlyOwner {
        emit ParameterUpdated("minimumReputationForForging", minimumReputationForForging, minRep);
        minimumReputationForForging = minRep;
    }

    function setMinimumReputationForUpgrading(uint256 minRep) external onlyOwner {
        emit ParameterUpdated("minimumReputationForUpgrading", minimumReputationForUpgrading, minRep);
        minimumReputationForUpgrading = minRep;
    }

    function setForgingEssenceCost(uint256 cost) external onlyOwner {
         emit ParameterUpdated("forgingEssenceCost", forgingEssenceCost, cost);
        forgingEssenceCost = cost;
    }

    function setUpgradeEssenceCostBase(uint256 cost) external onlyOwner {
        emit ParameterUpdated("upgradeEssenceCostBase", upgradeEssenceCostBase, cost);
        upgradeEssenceCostBase = cost;
    }

    function setReputationBoostCost(uint256 cost) external onlyOwner {
         // Prevent setting cost to 0 to avoid division by zero or infinite reputation gain
         require(cost > 0, "Boost cost must be > 0");
         emit ParameterUpdated("reputationBoostCost", reputationBoostCost, cost);
        reputationBoostCost = cost;
    }

     function setReputationBoostAmount(uint256 amount) external onlyOwner {
        emit ParameterUpdated("reputationBoostAmount", reputationBoostAmount, amount);
        reputationBoostAmount = amount;
    }


    function setStakingYieldRate(uint256 rate) external onlyOwner {
        emit ParameterUpdated("stakingYieldRate", stakingYieldRate, rate);
        stakingYieldRate = rate;
    }

    function setRefineEssenceReturn(uint256 percentage) external onlyOwner {
         if (percentage > 100) revert InvalidRefinePercentage();
         emit ParameterUpdated("refineEssenceReturnPercentage", refineEssenceReturnPercentage, percentage);
        refineEssenceReturnPercentage = percentage;
    }

    /// @dev Allows the owner to withdraw accumulated Essence fees.
    function withdrawFees(address recipient) external onlyOwner nonReentrant {
        uint256 amount = _accumulatedFees;
        if (amount > 0) {
            _accumulatedFees = 0;
            // Transfer accumulated fees from the contract's balance
            // Use _transfer function inherited from ERC20
            _transfer(address(this), recipient, amount);
        }
    }

    /// @dev Pauses contract actions that are time-sensitive or rely on external state.
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses contract actions.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Mints initial supply of Essence to a recipient. Callable only once by the owner.
    /// This is separate from ongoing minting for rewards. Useful for initial distribution.
    bool private initialEssenceMinted = false;
    function mintInitialEssence(address account, uint256 amount) external onlyOwner nonReentrant {
        require(!initialEssenceMinted, "Initial essence already minted");
        _mint(account, amount);
        initialEssenceMinted = true;
    }


    // --- Internal Helper Functions ---

    /// @dev Handles spending Essence. Checks balance and transfers to the contract address.
    function _spendEssence(address from, uint256 amount) internal {
        if (amount == 0) return;
        if (balanceOf(from) < amount) {
            revert NotEnoughEssence(amount, balanceOf(from));
        }
        // Transfer from the user to the contract (fee sink)
        _transfer(from, address(this), amount);
    }

     /// @dev Handles minting Essence internally. Used for rewards or initial supply.
     /// Note: This relies on this contract being the minter. OpenZeppelin's ERC20 _mint is protected.
     /// If using a separate minter role, this function would need adjustment.
     /// Here, inheriting ERC20 directly makes `_mint` available to this contract.
    function _mintEssence(address to, uint256 amount) internal {
        if (amount > 0) {
            _mint(to, amount);
        }
    }

    // Optional: Override ERC721 _beforeTokenTransfer if needed for specific hooks
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    // Optional: Override ERC721 _afterTokenTransfer if needed for specific hooks
    // function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //      super._afterTokenTransfer(from, to, tokenId, batchSize);
    //      // Handle reputation update if reputation was linked to NFT ownership (more complex)
    // }
}
```