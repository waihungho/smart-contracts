The `ChronosGuardianForge` is a sophisticated smart contract designed to manage an ecosystem of utility-driven, evolving NFTs called "Chronos Guardians." These Guardians are not merely static collectibles; they represent a user's progression, activity, and commitment within a broader, imagined "Chronos Protocol." Owners can evolve their Guardians through various levels by meeting on-chain conditions, consuming resources, and actively participating, thereby unlocking unique "Traits" that confer special permissions, benefits, or enhanced capabilities within the protocol. The system also integrates `SparkEssence` (an ERC20 resource) for fueling evolution and `TemporalSigils` (ERC1155 utility items) for temporary boosts, fostering a dynamic and interactive on-chain experience.

---

## Contract: ChronosGuardianForge

### Outline

The `ChronosGuardianForge` contract is the core of an evolving utility NFT system. It mints and manages "Chronos Guardian" NFTs (ERC721s) that can level up and unlock powerful "Traits." These traits grant special permissions or benefits within an imagined broader "Chronos Protocol." Guardians evolve by consuming `SparkEssence` tokens (an ERC20 resource) and meeting specific on-chain conditions. The system also introduces `TemporalSigils` (ERC1155s) which can be used to further augment Guardians or trigger unique events. A Protocol Treasury dynamically allocates resources based on Guardian activity and enables trait delegation.

### Function Summary

*   **Guardian Minting & Management:**
    1.  `mintInitialGuardian`: Mints a new Gen-0 Guardian NFT to a specified recipient.
    2.  `setBaseURI`: Allows the contract admin to update the base URI for Guardian NFT metadata.
    3.  `tokenURI`: Returns the dynamic metadata URI for a given Guardian, reflecting its current state (level, traits, etc.).
    4.  `getGuardianDetails`: Retrieves all crucial details (level, XP, last activity, current traits) for a Guardian.
*   **Evolution & Progression:**
    5.  `evolveGuardian`: Initiates the evolution process for a Guardian, requiring `SparkEssence` and fulfilling level-specific conditions.
    6.  `ascendGuardian`: A higher-tier evolution, requiring more resources and stringent conditions, potentially unlocking rarer traits.
    7.  `burnSparkEssenceForXP`: Allows a Guardian owner to burn `SparkEssence` directly to gain XP for their Guardian.
    8.  `claimActivityXP`: Allows Guardian owners to claim XP based on their general protocol activity (simulated by elapsed time since last claim).
*   **Trait System:**
    9.  `_unlockTrait`: Internal function to assign a specific trait to a Guardian upon evolution or other events.
    10. `hasTrait`: Checks if a Guardian possesses a specific trait.
    11. `delegateTrait`: Allows a Guardian owner to temporarily delegate a specific trait's utility to another address.
    12. `revokeTraitDelegation`: Revokes an active trait delegation, ending the delegated utility.
    13. `getDelegatedTraitRecipient`: Returns the address to whom a trait is delegated, if any.
    14. `getEvolutionTraitUnlock`: Returns the traits unlocked at a specific evolution level.
*   **SparkEssence (ERC20 Resource) Interaction:**
    15. `depositSparkEssence`: Users deposit `SparkEssence` into the Forge for future Guardian evolutions or XP gain.
    16. `withdrawSparkEssence`: Users withdraw their deposited `SparkEssence` from the Forge.
    17. `getDepositedSparkEssence`: Returns the amount of SparkEssence deposited by a specific user.
*   **Temporal Sigils (ERC1155 Utility Items):**
    18. `mintTemporalSigil`: Mints a specific type of Temporal Sigil (ERC1155) to a recipient.
    19. `applySigilToGuardian`: Consumes a `TemporalSigil` to grant a temporary boost or effect to a Guardian.
    20. `removeSigilEffect`: Manually removes a temporary sigil effect before its natural expiration.
    21. `getSigilEffectExpiration`: Returns the expiration time for a sigil effect on a Guardian.
*   **Protocol Treasury & Empowerment:**
    22. `depositToTreasury`: Allows external entities or the protocol to deposit `CHRONOS_TOKEN` into the treasury.
    23. `claimEmpowermentFund`: Allows Guardians meeting specific criteria to claim a share from the treasury.
    24. `distributeTreasuryFunds`: Admin function to allocate treasury funds to specific initiatives or addresses.
*   **Admin & Maintenance:**
    25. `pauseContract`: Pauses critical contract functions in an emergency.
    26. `unpauseContract`: Unpauses the contract.
    27. `setEvolutionTier`: Configures the requirements (cost, XP, conditions, traits) for a specific evolution level.
    28. `fulfillExternalCondition`: Admin/privileged function to mark an external condition as met for a user.
    29. `setActivityXPPerPeriod`: Sets the amount of XP a Guardian can claim per activity period.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces for external tokens (if they were separate contracts) ---
interface ISparkEssence is IERC20 {}
interface IChronosToken is IERC20 {}
interface ITemporalSigils is IERC1155 {}

contract ChronosGuardianForge is ERC721, ERC721Burnable, Ownable, Pausable {
    using Strings for uint256;

    // --- State Variables ---
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    // External token addresses
    ISparkEssence public immutable SPARK_ESSENCE;
    IChronosToken public immutable CHRONOS_TOKEN;
    ITemporalSigils public immutable TEMPORAL_SIGILS;

    // --- Guardian Data Structures ---
    struct GuardianDetails {
        uint256 level;
        uint256 xp;
        uint256 lastActivityClaimTime;
        mapping(bytes32 => bool) traits; // trait hash => unlocked
        mapping(bytes32 => uint256) sigilEffects; // sigil ID => expiration time
    }
    mapping(uint256 => GuardianDetails) public guardianData;

    // --- Evolution & Progression ---
    struct EvolutionTier {
        uint256 sparkEssenceCost;
        uint256 xpThreshold;
        bytes32[] requiredExternalConditions; // E.g., keccak256("staked_100_chronos"), keccak256("participated_dao_vote")
        bytes32[] unlockedTraits;
    }
    mapping(uint256 => EvolutionTier) public evolutionTiers; // level => EvolutionTier config
    mapping(address => mapping(bytes32 => bool)) public externalConditionMet; // user => conditionHash => met

    uint256 public activityXPPerPeriod = 100; // XP per claim period
    uint256 public activityClaimPeriod = 1 days; // How often XP can be claimed

    // --- Trait Delegation ---
    struct TraitDelegation {
        address delegatee;
        uint256 expirationTime;
    }
    mapping(uint256 => mapping(bytes32 => TraitDelegation)) public delegatedTraits; // guardianId => traitHash => delegation

    // --- SparkEssence Deposits ---
    mapping(address => uint256) public depositedSparkEssence;

    // --- Protocol Treasury ---
    uint256 public treasuryBalance; // Tracks CHRONOS_TOKEN deposited

    // --- Events ---
    event GuardianMinted(address indexed owner, uint256 indexed tokenId, uint256 initialLevel);
    event GuardianEvolved(uint256 indexed tokenId, uint256 newLevel, bytes32[] unlockedTraits);
    event XPClaimed(uint256 indexed tokenId, uint256 amount);
    event TraitUnlocked(uint256 indexed tokenId, bytes32 indexed traitHash);
    event TraitDelegated(uint256 indexed tokenId, bytes32 indexed traitHash, address indexed delegatee, uint256 expiration);
    event TraitDelegationRevoked(uint256 indexed tokenId, bytes32 indexed traitHash, address indexed delegatee);
    event SparkEssenceDeposited(address indexed user, uint256 amount);
    event SparkEssenceWithdrawal(address indexed user, uint256 amount);
    event SigilApplied(uint256 indexed tokenId, bytes32 indexed sigilId, uint256 expirationTime);
    event SigilEffectRemoved(uint256 indexed tokenId, bytes32 indexed sigilId);
    event ExternalConditionFulfilled(address indexed user, bytes32 indexed conditionHash);
    event FundsDepositedToTreasury(address indexed depositor, uint256 amount);
    event EmpowermentFundClaimed(address indexed claimant, uint256 amount);
    event TreasuryFundsDistributed(address indexed recipient, uint256 amount);

    // --- Constructor ---
    constructor(
        address sparkEssenceAddress,
        address chronosTokenAddress,
        address temporalSigilsAddress,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) Ownable(msg.sender) Pausable() {
        require(sparkEssenceAddress != address(0), "Invalid SparkEssence address");
        require(chronosTokenAddress != address(0), "Invalid ChronosToken address");
        require(temporalSigilsAddress != address(0), "Invalid TemporalSigils address");

        SPARK_ESSENCE = ISparkEssence(sparkEssenceAddress);
        CHRONOS_TOKEN = IChronosToken(chronosTokenAddress);
        TEMPORAL_SIGILS = ITemporalSigils(temporalSigilsAddress);

        // Initialize level 1 evolution (no cost/conditions for genesis)
        evolutionTiers[1] = EvolutionTier({
            sparkEssenceCost: 0,
            xpThreshold: 0,
            requiredExternalConditions: new bytes32[](0),
            unlockedTraits: new bytes32[](0)
        });
    }

    // --- Modifiers ---
    modifier onlyGuardianOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized to manage this Guardian");
        _;
    }

    // --- Guardian Minting & Management ---

    /**
     * @notice Mints a new Gen-0 Guardian NFT to a specified recipient.
     * @param recipient The address to receive the new Guardian.
     */
    function mintInitialGuardian(address recipient) external onlyOwner whenNotPaused {
        _mint(recipient, _nextTokenId);
        guardianData[_nextTokenId].level = 1; // All Guardians start at level 1
        guardianData[_nextTokenId].xp = 0;
        guardianData[_nextTokenId].lastActivityClaimTime = block.timestamp;
        emit GuardianMinted(recipient, _nextTokenId, 1);
        _nextTokenId++;
    }

    /**
     * @notice Allows the contract admin to update the base URI for Guardian NFT metadata.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /**
     * @notice Returns the dynamic metadata URI for a given Guardian, reflecting its current state.
     * @param tokenId The ID of the Guardian NFT.
     * @return The URI string for the Guardian's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensures the token exists

        // Example dynamic URI: baseURI/tokenId.json?level=X&xp=Y&traits=A,B,C
        // A real implementation would involve an API endpoint that queries the contract's state
        // and constructs the JSON metadata on the fly.
        return string(
            abi.encodePacked(
                _baseTokenURI,
                tokenId.toString(),
                ".json?level=", guardianData[tokenId].level.toString(),
                "&xp=", guardianData[tokenId].xp.toString()
                // ... potentially more detailed trait info
            )
        );
    }

    /**
     * @notice Retrieves all crucial details (level, XP, last activity, current traits) for a Guardian.
     * @param tokenId The ID of the Guardian NFT.
     * @return _level The current level of the Guardian.
     * @return _xp The current experience points of the Guardian.
     * @return _lastActivityClaimTime The last timestamp XP was claimed from activity.
     * @return _traits An array of bytes32 hashes representing unlocked traits.
     */
    function getGuardianDetails(uint256 tokenId)
        public
        view
        returns (uint256 _level, uint256 _xp, uint256 _lastActivityClaimTime, bytes32[] memory _traits)
    {
        _requireOwned(tokenId);
        GuardianDetails storage guardian = guardianData[tokenId];
        _level = guardian.level;
        _xp = guardian.xp;
        _lastActivityClaimTime = guardian.lastActivityClaimTime;

        uint256 traitCount = 0;
        for (uint256 i = 0; i < evolutionTiers[guardian.level].unlockedTraits.length; i++) {
            if (guardian.traits[evolutionTiers[guardian.level].unlockedTraits[i]]) {
                traitCount++;
            }
        }
        for (uint256 level = 1; level <= guardian.level; level++) {
            for (uint256 i = 0; i < evolutionTiers[level].unlockedTraits.length; i++) {
                if (guardian.traits[evolutionTiers[level].unlockedTraits[i]]) {
                    traitCount++;
                }
            }
        }

        _traits = new bytes32[](traitCount);
        uint256 currentTraitIndex = 0;
        for (uint256 level = 1; level <= guardian.level; level++) {
            for (uint256 i = 0; i < evolutionTiers[level].unlockedTraits.length; i++) {
                bytes32 trait = evolutionTiers[level].unlockedTraits[i];
                if (guardian.traits[trait]) {
                    _traits[currentTraitIndex++] = trait;
                }
            }
        }
    }

    // --- Evolution & Progression ---

    /**
     * @notice Initiates the evolution process for a Guardian.
     * Requires deposited SparkEssence and fulfilling level-specific conditions.
     * @param tokenId The ID of the Guardian NFT to evolve.
     */
    function evolveGuardian(uint256 tokenId) external onlyGuardianOwner(tokenId) whenNotPaused {
        GuardianDetails storage guardian = guardianData[tokenId];
        uint256 currentLevel = guardian.level;
        uint256 nextLevel = currentLevel + 1;

        EvolutionTier storage nextTier = evolutionTiers[nextLevel];
        require(nextTier.xpThreshold > 0 || nextTier.sparkEssenceCost > 0, "No next evolution tier configured");
        require(guardian.xp >= nextTier.xpThreshold, "Not enough XP for evolution");
        require(depositedSparkEssence[_msgSender()] >= nextTier.sparkEssenceCost, "Not enough deposited SparkEssence");

        // Check external conditions
        for (uint256 i = 0; i < nextTier.requiredExternalConditions.length; i++) {
            require(externalConditionMet[_msgSender()][nextTier.requiredExternalConditions[i]], "External condition not met");
        }

        // Consume resources
        depositedSparkEssence[_msgSender()] -= nextTier.sparkEssenceCost;

        // Apply evolution
        guardian.level = nextLevel;
        // Optionally reset XP or carry over excess: for simplicity, we keep current XP
        // guardian.xp = 0; // Or (guardian.xp - nextTier.xpThreshold) for rollover

        bytes32[] memory newTraits = new bytes32[](nextTier.unlockedTraits.length);
        for (uint256 i = 0; i < nextTier.unlockedTraits.length; i++) {
            _unlockTrait(tokenId, nextTier.unlockedTraits[i]);
            newTraits[i] = nextTier.unlockedTraits[i];
        }

        emit GuardianEvolved(tokenId, nextLevel, newTraits);
    }

    /**
     * @notice A higher-tier evolution, requiring more resources and stringent conditions.
     * This is conceptually similar to evolveGuardian but could have different visual effects
     * or unlock rarer traits/functions.
     * @param tokenId The ID of the Guardian NFT to ascend.
     */
    function ascendGuardian(uint256 tokenId) external onlyGuardianOwner(tokenId) whenNotPaused {
        // This function could be a specific 'evolveGuardian' with much higher requirements
        // or trigger a specific rare evolution path.
        // For demonstration, let's make it evolve to a fixed higher level requiring more resources.
        GuardianDetails storage guardian = guardianData[tokenId];
        uint256 currentLevel = guardian.level;
        uint256 targetAscensionLevel = currentLevel + 5; // Example: ascend 5 levels at once

        require(evolutionTiers[targetAscensionLevel].sparkEssenceCost > 0, "Ascension target not configured or too high");

        // Aggregated cost and conditions check for ascension over multiple levels
        uint256 totalEssenceCost = 0;
        uint256 requiredXP = 0;
        for (uint256 level = currentLevel + 1; level <= targetAscensionLevel; level++) {
            totalEssenceCost += evolutionTiers[level].sparkEssenceCost;
            requiredXP += evolutionTiers[level].xpThreshold; // Or max of thresholds, depending on XP model
            for (uint256 i = 0; i < evolutionTiers[level].requiredExternalConditions.length; i++) {
                require(externalConditionMet[_msgSender()][evolutionTiers[level].requiredExternalConditions[i]], "Ascension external condition not met");
            }
        }

        require(guardian.xp >= requiredXP, "Not enough XP for ascension");
        require(depositedSparkEssence[_msgSender()] >= totalEssenceCost, "Not enough deposited SparkEssence for ascension");

        depositedSparkEssence[_msgSender()] -= totalEssenceCost;
        guardian.level = targetAscensionLevel;

        bytes32[] memory newTraits = new bytes32[](0);
        for (uint256 level = currentLevel + 1; level <= targetAscensionLevel; level++) {
            for (uint256 i = 0; i < evolutionTiers[level].unlockedTraits.length; i++) {
                _unlockTrait(tokenId, evolutionTiers[level].unlockedTraits[i]);
                // Dynamically grow newTraits array - a bit inefficient, but for example
                bytes32[] memory temp = new bytes32[](newTraits.length + 1);
                for(uint256 j=0; j<newTraits.length; j++) temp[j] = newTraits[j];
                temp[newTraits.length] = evolutionTiers[level].unlockedTraits[i];
                newTraits = temp;
            }
        }

        emit GuardianEvolved(tokenId, targetAscensionLevel, newTraits);
    }

    /**
     * @notice Allows a Guardian owner to burn `SparkEssence` directly to gain XP for their Guardian.
     * @param tokenId The ID of the Guardian NFT.
     * @param amount The amount of SparkEssence to burn.
     */
    function burnSparkEssenceForXP(uint256 tokenId, uint256 amount) external onlyGuardianOwner(tokenId) whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        require(depositedSparkEssence[_msgSender()] >= amount, "Not enough deposited SparkEssence");

        // Example: 1 SparkEssence = 10 XP
        uint256 xpGained = amount * 10;
        depositedSparkEssence[_msgSender()] -= amount;
        guardianData[tokenId].xp += xpGained;
        emit XPClaimed(tokenId, xpGained);
    }

    /**
     * @notice Allows Guardian owners to claim XP based on their general protocol activity.
     * Activity is simulated by elapsed time since last claim.
     * @param tokenId The ID of the Guardian NFT.
     */
    function claimActivityXP(uint256 tokenId) external onlyGuardianOwner(tokenId) whenNotPaused {
        GuardianDetails storage guardian = guardianData[tokenId];
        uint256 timeElapsed = block.timestamp - guardian.lastActivityClaimTime;
        require(timeElapsed >= activityClaimPeriod, "Activity XP not ready to claim");

        uint256 periods = timeElapsed / activityClaimPeriod;
        uint256 xpGained = periods * activityXPPerPeriod;

        guardian.xp += xpGained;
        guardian.lastActivityClaimTime = block.timestamp;
        emit XPClaimed(tokenId, xpGained);
    }

    // --- Trait System ---

    /**
     * @notice Internal function to assign a specific trait to a Guardian.
     * @param tokenId The ID of the Guardian NFT.
     * @param traitHash The keccak256 hash of the trait name (e.g., keccak256("ReducedFees")).
     */
    function _unlockTrait(uint256 tokenId, bytes32 traitHash) internal {
        require(traitHash != bytes32(0), "Trait hash cannot be zero");
        require(!guardianData[tokenId].traits[traitHash], "Trait already unlocked");
        guardianData[tokenId].traits[traitHash] = true;
        emit TraitUnlocked(tokenId, traitHash);
    }

    /**
     * @notice Checks if a Guardian possesses a specific trait.
     * @param tokenId The ID of the Guardian NFT.
     * @param traitHash The keccak256 hash of the trait name.
     * @return True if the Guardian has the trait, false otherwise.
     */
    function hasTrait(uint256 tokenId, bytes32 traitHash) public view returns (bool) {
        return guardianData[tokenId].traits[traitHash];
    }

    /**
     * @notice Allows a Guardian owner to temporarily delegate a specific trait's utility to another address.
     * @param tokenId The ID of the Guardian NFT.
     * @param traitHash The keccak256 hash of the trait to delegate.
     * @param delegatee The address to delegate the trait to.
     * @param duration The duration (in seconds) for which the trait is delegated.
     */
    function delegateTrait(uint256 tokenId, bytes32 traitHash, address delegatee, uint256 duration)
        external
        onlyGuardianOwner(tokenId)
        whenNotPaused
    {
        require(hasTrait(tokenId, traitHash), "Guardian does not possess this trait");
        require(delegatee != address(0), "Delegatee cannot be zero address");
        require(duration > 0, "Delegation duration must be positive");

        uint256 expirationTime = block.timestamp + duration;
        delegatedTraits[tokenId][traitHash] = TraitDelegation({
            delegatee: delegatee,
            expirationTime: expirationTime
        });
        emit TraitDelegated(tokenId, traitHash, delegatee, expirationTime);
    }

    /**
     * @notice Revokes an active trait delegation. Only the Guardian owner can revoke.
     * @param tokenId The ID of the Guardian NFT.
     * @param traitHash The keccak256 hash of the trait whose delegation is to be revoked.
     */
    function revokeTraitDelegation(uint256 tokenId, bytes32 traitHash) external onlyGuardianOwner(tokenId) whenNotPaused {
        TraitDelegation storage delegation = delegatedTraits[tokenId][traitHash];
        require(delegation.delegatee != address(0) && delegation.expirationTime > block.timestamp, "No active delegation to revoke");

        delete delegatedTraits[tokenId][traitHash];
        emit TraitDelegationRevoked(tokenId, traitHash, delegation.delegatee);
    }

    /**
     * @notice Returns the address to whom a trait is currently delegated, if any, and if active.
     * @param tokenId The ID of the Guardian NFT.
     * @param traitHash The keccak256 hash of the trait.
     * @return The delegatee address, or address(0) if not delegated or expired.
     */
    function getDelegatedTraitRecipient(uint256 tokenId, bytes32 traitHash) public view returns (address) {
        TraitDelegation storage delegation = delegatedTraits[tokenId][traitHash];
        if (delegation.delegatee != address(0) && delegation.expirationTime > block.timestamp) {
            return delegation.delegatee;
        }
        return address(0);
    }

    /**
     * @notice Returns the array of traits unlocked at a specific evolution level.
     * @param level The evolution level.
     * @return An array of bytes32 hashes representing traits unlocked at that level.
     */
    function getEvolutionTraitUnlock(uint256 level) public view returns (bytes32[] memory) {
        return evolutionTiers[level].unlockedTraits;
    }

    // --- SparkEssence (ERC20 Resource) Interaction ---

    /**
     * @notice Users deposit `SparkEssence` into the Forge for future Guardian evolutions or XP gain.
     * Requires prior ERC20 approval.
     * @param amount The amount of SparkEssence to deposit.
     */
    function depositSparkEssence(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        SPARK_ESSENCE.transferFrom(_msgSender(), address(this), amount);
        depositedSparkEssence[_msgSender()] += amount;
        emit SparkEssenceDeposited(_msgSender(), amount);
    }

    /**
     * @notice Users withdraw their deposited `SparkEssence` from the Forge.
     * @param amount The amount of SparkEssence to withdraw.
     */
    function withdrawSparkEssence(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        require(depositedSparkEssence[_msgSender()] >= amount, "Insufficient deposited SparkEssence");
        depositedSparkEssence[_msgSender()] -= amount;
        SPARK_ESSENCE.transfer(_msgSender(), amount);
        emit SparkEssenceWithdrawal(_msgSender(), amount);
    }

    /**
     * @notice Returns the amount of SparkEssence deposited by a specific user.
     * @param user The address of the user.
     * @return The deposited amount.
     */
    function getDepositedSparkEssence(address user) public view returns (uint256) {
        return depositedSparkEssence[user];
    }

    // --- Temporal Sigils (ERC1155 Utility Items) ---

    /**
     * @notice Mints a specific type of Temporal Sigil (ERC1155) to a recipient.
     * @param recipient The address to receive the Sigil.
     * @param sigilId The ID of the Sigil to mint (from the ITemporalSigils contract).
     * @param amount The amount of Sigils to mint.
     * @param data Optional data to pass to the ERC1155 `mint` function.
     */
    function mintTemporalSigil(address recipient, uint256 sigilId, uint256 amount, bytes memory data)
        external
        onlyOwner
        whenNotPaused
    {
        TEMPORAL_SIGILS.mint(recipient, sigilId, amount, data);
    }

    /**
     * @notice Consumes a `TemporalSigil` to grant a temporary boost or effect to a Guardian.
     * Requires prior ERC1155 approval for the Sigil.
     * @param tokenId The ID of the Guardian NFT.
     * @param sigilId The ID of the Temporal Sigil to apply.
     * @param duration The duration (in seconds) for which the sigil's effect lasts.
     */
    function applySigilToGuardian(uint256 tokenId, uint256 sigilId, uint256 duration)
        external
        onlyGuardianOwner(tokenId)
        whenNotPaused
    {
        require(duration > 0, "Sigil effect duration must be positive");

        // Requires the user to approve this contract to move the sigil (ERC1155 `setApprovalForAll`)
        TEMPORAL_SIGILS.safeTransferFrom(_msgSender(), address(this), sigilId, 1, "");

        guardianData[tokenId].sigilEffects[bytes32(sigilId)] = block.timestamp + duration;
        emit SigilApplied(tokenId, bytes32(sigilId), block.timestamp + duration);
    }

    /**
     * @notice Manually removes a temporary sigil effect from a Guardian before its natural expiration.
     * @param tokenId The ID of the Guardian NFT.
     * @param sigilId The ID of the Temporal Sigil whose effect to remove.
     */
    function removeSigilEffect(uint256 tokenId, bytes32 sigilId) external onlyGuardianOwner(tokenId) {
        require(guardianData[tokenId].sigilEffects[sigilId] > block.timestamp, "Sigil effect is not active or already expired");
        delete guardianData[tokenId].sigilEffects[sigilId];
        emit SigilEffectRemoved(tokenId, sigilId);
    }

    /**
     * @notice Returns the expiration time for a specific sigil effect on a Guardian.
     * @param tokenId The ID of the Guardian NFT.
     * @param sigilId The ID of the Temporal Sigil.
     * @return The expiration timestamp, or 0 if no active effect.
     */
    function getSigilEffectExpiration(uint256 tokenId, bytes32 sigilId) public view returns (uint256) {
        uint256 expiration = guardianData[tokenId].sigilEffects[sigilId];
        if (expiration > block.timestamp) {
            return expiration;
        }
        return 0; // Effect has expired or never existed
    }

    // --- Protocol Treasury & Empowerment ---

    /**
     * @notice Allows external entities or the protocol to deposit `CHRONOS_TOKEN` into the treasury.
     * Requires prior ERC20 approval.
     * @param amount The amount of CHRONOS_TOKEN to deposit.
     */
    function depositToTreasury(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        CHRONOS_TOKEN.transferFrom(_msgSender(), address(this), amount);
        treasuryBalance += amount;
        emit FundsDepositedToTreasury(_msgSender(), amount);
    }

    /**
     * @notice Allows Guardians meeting certain criteria to claim a share from the treasury.
     * Example: Only Guardians level 5 or higher can claim.
     * @param tokenId The ID of the Guardian NFT claiming the fund.
     */
    function claimEmpowermentFund(uint256 tokenId) external onlyGuardianOwner(tokenId) whenNotPaused {
        GuardianDetails storage guardian = guardianData[tokenId];
        require(guardian.level >= 5, "Guardian level too low to claim empowerment fund"); // Example condition

        uint256 claimAmount = treasuryBalance / 100; // Example: 1% of current treasury
        if (claimAmount == 0 && treasuryBalance > 0) claimAmount = 1; // Minimum claim for non-zero treasury
        require(claimAmount > 0 && treasuryBalance >= claimAmount, "No funds available to claim or treasury too low");

        treasuryBalance -= claimAmount;
        CHRONOS_TOKEN.transfer(_msgSender(), claimAmount);
        emit EmpowermentFundClaimed(_msgSender(), claimAmount);
    }

    /**
     * @notice Admin function to allocate treasury funds to specific initiatives or addresses.
     * @param recipient The address to receive the funds.
     * @param amount The amount of CHRONOS_TOKEN to distribute.
     */
    function distributeTreasuryFunds(address recipient, uint256 amount) external onlyOwner whenNotPaused {
        require(recipient != address(0), "Recipient cannot be zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(treasuryBalance >= amount, "Insufficient funds in treasury");

        treasuryBalance -= amount;
        CHRONOS_TOKEN.transfer(recipient, amount);
        emit TreasuryFundsDistributed(recipient, amount);
    }

    // --- Admin & Maintenance ---

    /**
     * @notice Pauses critical contract functions in an emergency.
     * Inherited from Pausable.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * Inherited from Pausable.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Configures the requirements (cost, XP, conditions, traits) for a specific evolution level.
     * Only the owner can set these.
     * @param level The evolution level being configured.
     * @param sparkEssenceCost The amount of SparkEssence required.
     * @param xpThreshold The XP required.
     * @param requiredConditions An array of bytes32 hashes for external conditions.
     * @param unlockedTraits An array of bytes32 hashes for traits unlocked at this level.
     */
    function setEvolutionTier(
        uint256 level,
        uint256 sparkEssenceCost,
        uint256 xpThreshold,
        bytes32[] memory requiredConditions,
        bytes32[] memory unlockedTraits
    ) external onlyOwner {
        require(level > 0, "Level must be greater than zero");
        evolutionTiers[level] = EvolutionTier({
            sparkEssenceCost: sparkEssenceCost,
            xpThreshold: xpThreshold,
            requiredExternalConditions: requiredConditions,
            unlockedTraits: unlockedTraits
        });
    }

    /**
     * @notice Admin/privileged function to mark an external condition as met for a user.
     * In a real DApp, this might be triggered by an oracle, a sub-protocol, or a governance vote.
     * @param user The address for whom the condition is met.
     * @param conditionHash The keccak256 hash of the condition (e.g., keccak256("staked_100_chronos")).
     */
    function fulfillExternalCondition(address user, bytes32 conditionHash) external onlyOwner {
        require(user != address(0), "User address cannot be zero");
        require(conditionHash != bytes32(0), "Condition hash cannot be zero");
        externalConditionMet[user][conditionHash] = true;
        emit ExternalConditionFulfilled(user, conditionHash);
    }

    /**
     * @notice Sets the amount of XP a Guardian can claim per activity period.
     * @param xp Amount of XP.
     * @param period Duration in seconds.
     */
    function setActivityXPPerPeriod(uint256 xp, uint256 period) external onlyOwner {
        require(xp > 0, "XP must be positive");
        require(period > 0, "Period must be positive");
        activityXPPerPeriod = xp;
        activityClaimPeriod = period;
    }

    // --- ERC721 Overrides ---
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // The following two functions are required for ERC721Burnable
    function _approve(address to, uint256 tokenId) internal override(ERC721, ERC721Burnable) {
        super._approve(to, tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Burnable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Burnable) {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```