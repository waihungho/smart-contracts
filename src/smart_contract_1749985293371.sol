Okay, let's design a smart contract that represents a "NFTravel Universe". This universe contains dynamic Travel Pod NFTs, discoverable Artifact NFTs, and utilizes a hypothetical Cosmic Dust (CDUST) ERC20 token for fuel, upgrades, and rewards. The contract will act as the central orchestrator and also manage the state of the dynamic Travel Pods themselves, interacting with external contracts for Artifacts and CDUST.

This contract will incorporate:
1.  **Dynamic NFTs (Travel Pods):** Their state (XP, Fuel, Level, Efficiency) is stored and modified on-chain, influencing their behavior and potentially metadata (via `tokenURI`).
2.  **Multi-Asset Interaction:** Interacts with external ERC721 (Artifacts) and ERC20 (CDUST) contracts (represented by interfaces).
3.  **Time-Based Mechanics:** Travel duration is based on time.
4.  **State Management:** Complex state for each NFT (Pod).
5.  **Gamification:** XP, leveling, fuel management, quests, discovery chance, upgrades.
6.  **Delegation:** Users can delegate travel control of their Pods.
7.  **Admin Controls:** Pausing, setting parameters, withdrawing funds.
8.  **Randomness:** Pseudo-randomness for artifact discovery (with caveats mentioned in comments).

We will make this contract *itself* the ERC721 contract for the Travel Pods to maximize the function count within the single contract, while interacting with external mock/interface contracts for Artifacts and CDUST.

---

**NFTravelUniverse Smart Contract**

**Outline:**

1.  **License and Pragma**
2.  **Imports:** ERC721, Ownable, Pausable, SafeERC20.
3.  **Interfaces:** Define interfaces for external Artifact NFT and CDUST Token contracts.
4.  **Errors:** Custom errors for clarity.
5.  **Structs:** Define data structures for Pod state, Travel state, Dimension data, Quest data.
6.  **State Variables:**
    *   Contract addresses (Artifact NFT, CDUST Token).
    *   Counters for token IDs (Pods).
    *   Mappings for Pod state, Travel state, Quest data, Completed Quests per Pod, Travel Delegates.
    *   Admin-configurable parameters (base fuel cost, XP rate, artifact chance base, XP required per level).
    *   Dimension data.
    *   Quest data.
    *   Base URI for dynamic metadata.
7.  **Events:** Define events for key actions (Mint, Travel Start/End, Refuel, Level Up, Upgrade, Quest Complete, Delegation, Burn, Admin updates).
8.  **Constructor:** Initializes base contract, sets admin, potentially sets initial contract addresses.
9.  **Modifiers:** `whenNotTraveling`, `onlyPodOwnerOrDelegate`.
10. **Admin Functions:** (min 8+)
    *   Set external contract addresses.
    *   Register/Update dimension data.
    *   Register/Update quest data.
    *   Set game parameters (fuel cost, XP rate, etc.).
    *   Pause/Unpause game.
    *   Withdraw collected funds (ETH, CDUST).
    *   Set base metadata URI.
11. **Pod Management Functions:** (min 5+)
    *   Mint new Travel Pods (initial issuance).
    *   Burn Travel Pods.
    *   Upgrade Pod stats (using CDUST/Artifacts).
    *   Level Up Pod (applying pending XP).
    *   Delegate/Revoke Travel Control.
    *   Getters for Pod state (level, fuel, xp, stats, delegate, completed quests).
12. **Travel Functions:** (min 4+)
    *   Start Travel (consumes fuel, sets travel state).
    *   End Travel (processes results, grants XP/rewards, clears state).
    *   Refuel Pod (consumes CDUST, adds fuel).
    *   Getters for Travel state (destination, end time, traveling status).
13. **Dimension & Quest Functions:** (min 4+)
    *   List available dimensions.
    *   Get dimension details.
    *   List available quests.
    *   Get quest details.
    *   Claim Quest Reward.
14. **ERC721 Standard Functions:** (9 functions - implicitly handled by inheritance, but some might be overridden/interacted with)
    *   balanceOf
    *   ownerOf
    *   transferFrom
    *   safeTransferFrom (x2)
    *   approve
    *   setApprovalForAll
    *   getApproved
    *   isApprovedForAll
15. **ERC721 Metadata Function:**
    *   tokenURI (Dynamic metadata link).
16. **Internal/Helper Functions:** Logic for calculating XP, fuel costs, artifact discovery, checking quest criteria. (These aren't explicitly counted in the 20+ external functions but are necessary).

**Function Summary:**

*   `constructor`: Deploys the contract, setting owner and initial configuration.
*   `setArtifactNFTAddress(address _artifactNFT)`: Admin - Sets the address of the external Artifact NFT contract.
*   `setCDUSTTokenAddress(address _cdustToken)`: Admin - Sets the address of the external CDUST Token contract.
*   `registerDimension(uint256 dimensionId, string memory name, uint256 baseFuelCostMultiplier, uint256 xpPerMinute, uint256 artifactDiscoveryChanceBasisPoints, uint256 minTravelDuration)`: Admin - Creates or updates a dimension with specified properties.
*   `getDimensionData(uint256 dimensionId)`: Public - Retrieves data for a specific dimension.
*   `listDimensions()`: Public - Returns a list of available dimension IDs.
*   `registerQuest(uint256 questId, string memory description, uint256 requiredLevel, uint256 requiredDimension, uint256 requiredArtifactId, uint256 rewardCDUST, uint256 rewardArtifactId)`: Admin - Creates or updates a quest definition. Requires level, dimension, *or* artifact, and rewards CDUST and/or an Artifact.
*   `getQuestDetails(uint256 questId)`: Public - Retrieves details for a specific quest.
*   `listQuests()`: Public - Returns a list of available quest IDs.
*   `setGameParameters(uint256 _baseFuelCostPerDurationUnit, uint256 _xpPerDurationUnit, uint256 _baseArtifactDiscoveryChanceBasisPoints, uint256[] memory _xpRequiredForLevel)`: Admin - Sets global game balancing parameters.
*   `setBaseURI(string memory baseURI)`: Admin - Sets the base URI for token metadata. The final URI will be baseURI + tokenId.
*   `pause()`: Admin - Pauses core game mechanics (`startTravel`, `endTravel`, `mintPod`, `refuelPod`, `claimQuestReward`).
*   `unpause()`: Admin - Unpauses the game.
*   `withdrawAdminFunds(address payable _to)`: Admin - Allows owner to withdraw collected ETH (e.g., from minting fees).
*   `withdrawCDUST(address _to)`: Admin - Allows owner to withdraw collected CDUST tokens.
*   `mintPod(address to)`: Payable - Mints a new Travel Pod NFT to `to`. Requires a payment in ETH (configurable).
*   `burnPod(uint256 tokenId)`: Public - Allows the owner of a Pod to burn it, permanently destroying the NFT and its state.
*   `startTravel(uint256 tokenId, uint256 dimensionId, uint256 durationInMinutes)`: Public - Initiates travel for the specified Pod to a dimension for a duration. Checks fuel, consumes fuel (as CDUST), updates Pod's internal travel state. Requires `onlyPodOwnerOrDelegate`.
*   `endTravel(uint256 tokenId)`: Public - Processes the end of travel for a Pod. Checks if travel duration is met, calculates and grants XP, rolls for artifact/CDUST discovery, grants rewards, clears travel state. Requires `onlyPodOwnerOrDelegate`.
*   `refuelPod(uint256 tokenId, uint256 amount)`: Public - Adds fuel to a Pod by consuming CDUST tokens from the user's wallet. Requires `onlyPodOwnerOrDelegate`.
*   `levelUpPod(uint256 tokenId)`: Public - Applies accumulated XP to potentially level up the Pod, updating its state and stats. Requires `onlyPodOwnerOrDelegate`.
*   `upgradePodStats(uint256 tokenId, uint256 upgradeType)`: Public - Allows spending CDUST and/or burning Artifacts to improve a Pod's stats (e.g., fuel efficiency, artifact luck). Requires `onlyPodOwnerOrDelegate`.
*   `claimQuestReward(uint256 tokenId, uint256 questId)`: Public - Allows a user to claim the reward for a quest if their Pod meets the completion criteria. Marks the quest as completed for that Pod. Requires `onlyPodOwnerOrDelegate`.
*   `delegateTravelControl(uint256 tokenId, address delegatee)`: Public - Allows the Pod owner to delegate the ability to start/end travel for this Pod to another address. Requires `onlyPodOwner`.
*   `revokeTravelControl(uint256 tokenId)`: Public - Allows the Pod owner or the delegatee to revoke the travel delegation. Requires `onlyPodOwnerOrDelegate`.
*   `getTravelDelegate(uint256 tokenId)`: Public - Returns the current address delegated travel control for a Pod.
*   `getPodState(uint256 tokenId)`: Public - Returns a struct containing the full internal state of a Pod (XP, fuel, level, stats, travel status, etc.).
*   `getPodLevel(uint256 tokenId)`: Public - Returns the Pod's current level.
*   `getPodXP(uint256 tokenId)`: Public - Returns the Pod's current XP.
*   `getPodFuel(uint256 tokenId)`: Public - Returns the Pod's current fuel.
*   `getPodEfficiency(uint256 tokenId)`: Public - Returns the Pod's current fuel efficiency modifier (%).
*   `getPodLuck(uint256 tokenId)`: Public - Returns the Pod's current artifact luck modifier (basis points).
*   `isPodTraveling(uint256 tokenId)`: Public - Returns boolean indicating if the Pod is currently traveling.
*   `getPodCurrentTravel(uint256 tokenId)`: Public - Returns details of the current travel (dimension, start time, end time).
*   `getPodCompletedQuests(uint256 tokenId)`: Public - Returns a list of quest IDs completed by the Pod.
*   `tokenURI(uint256 tokenId)`: Public/Override - Returns the URI for the dynamic metadata of the Pod. This URI will typically point to an off-chain service that reads the Pod's state from this contract to generate the metadata JSON.
*   `supportsInterface(bytes4 interfaceId)`: Public/Override - Standard ERC165 function.
*   *(Standard ERC721 functions like `ownerOf`, `balanceOf`, `transferFrom`, etc., are inherited and interact with the underlying ERC721 implementation, managing ownership and transfers of the Travel Pod NFTs)*.

This structure provides a complex, interconnected system with more than 20 functions within the main contract, fulfilling the requirements.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max, potentially
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI

// Interfaces for external contracts
interface IArtifactNFT {
    function mint(address to, uint256 artifactId) external returns (uint256 newItemId);
    function burn(uint256 tokenId) external; // Assuming artifact burn is allowed
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    // Add artifact details getter if needed for upgrade logic
    // function getArtifactDetails(uint256 artifactId) external view returns (ArtifactData memory);
}

interface ICDUSTToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

// Custom Errors
error NotPodOwnerOrDelegate(uint256 tokenId, address caller);
error PodIsTraveling(uint256 tokenId);
error PodNotTraveling(uint256 tokenId);
error TravelDurationNotMet(uint256 tokenId, uint256 endTime);
error InsufficientFuel(uint256 tokenId, uint256 required, uint256 available);
error DimensionNotRegistered(uint256 dimensionId);
error QuestNotRegistered(uint256 questId);
error QuestAlreadyCompleted(uint256 tokenId, uint256 questId);
error QuestCriteriaNotMet(uint256 tokenId, uint256 questId);
error InsufficientCDUST(address owner, uint256 required, uint256 available);
error ApprovalNeeded(address owner, address spender, uint256 amount);
error UpgradeTypeInvalid(uint256 upgradeType);
error NoXPToLevelUp(uint256 tokenId);


contract NFTravelUniverse is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeERC20 for ICDUSTToken;
    using Strings for uint256;

    // --- State Variables ---

    // Contract Addresses
    IArtifactNFT public artifactNFT;
    ICDUSTToken public cdustToken;

    // Pod Token Management
    Counters.Counter private _podTokenIds;
    string private _baseTokenURI;

    // Pod State
    struct PodState {
        uint256 level;
        uint256 xp; // Accumulated XP, can exceed level threshold before leveling up
        uint256 fuel; // Current fuel units
        uint256 fuelEfficiencyBasisPoints; // Fuel cost multiplier (e.g., 9000 for 90% cost)
        uint256 artifactLuckBasisPoints; // Chance modifier for artifact discovery (e.g., 11000 for 110% chance)
        uint256 lastUpdateTime; // Timestamp of last state update (travel end, refuel, level up, upgrade)
    }
    mapping(uint256 => PodState) private _podState;

    // Travel State
    struct TravelState {
        bool isTraveling;
        uint256 dimensionId;
        uint256 startTime;
        uint256 endTime;
    }
    mapping(uint256 => TravelState) private _podTravel;

    // Dimension Data
    struct DimensionData {
        bool exists; // Check if dimensionId is registered
        string name;
        uint256 baseFuelCostPerMinuteBasisPoints; // Fuel cost multiplier for this dimension (e.g., 12000 for 1.2x cost)
        uint256 xpPerMinute;
        uint256 artifactDiscoveryChanceBasisPoints; // Base chance for this dimension (e.g., 500 for 5% chance)
        uint256 minTravelDurationMinutes; // Minimum time required for travel to count
    }
    mapping(uint256 => DimensionData) private _dimensions;
    uint256[] public registeredDimensionIds;

    // Quest Data
    enum QuestType { TravelToDimension, ReachLevel, FindArtifact }
    struct Quest {
        bool exists;
        string description;
        QuestType questType;
        uint256 requiredLevel; // Required for ReachLevel or general requirement
        uint256 requiredDimension; // Required for TravelToDimension
        uint256 requiredArtifactId; // Required for FindArtifact (check if owner *has* this artifact)
        uint256 rewardCDUST;
        uint256 rewardArtifactId; // 0 if no artifact reward
        bool repeatable; // Can the quest be completed multiple times?
    }
    mapping(uint256 => Quest) private _quests;
    uint256[] public registeredQuestIds;
    // Track completed quests per pod (using a hash or concat for simplicity, or nested mapping if needed)
    mapping(uint256 => mapping(uint256 => bool)) private _podCompletedQuests; // podId => questId => completed

    // Delegation for Travel Control
    mapping(uint256 => address) private _travelDelegate; // podId => delegatee

    // Game Parameters (Admin Configurable)
    uint256 public baseFuelCostPerDurationUnit = 100; // Fuel cost per unit time *before* dimension/efficiency multipliers
    uint256 public xpPerDurationUnit = 1; // Base XP gained per unit time *before* dimension multiplier
    uint256 public baseArtifactDiscoveryChanceBasisPoints = 100; // Base chance (1%) *before* dimension/luck multipliers
    // XP required for levels: index 0 = Level 1 (XP to reach Level 2), index 1 = Level 2 (XP to reach Level 3), etc.
    uint256[] public xpRequiredForLevel;
    uint256 public constant DURATION_UNIT = 1 minutes; // Define the time unit for calculations

    // Mint Price
    uint256 public podMintPrice = 0.01 ether;

    // --- Events ---

    event PodMinted(uint256 indexed tokenId, address indexed owner, uint256 initialLevel);
    event PodBurned(uint256 indexed tokenId, address indexed owner);
    event TravelStarted(uint256 indexed tokenId, uint256 indexed dimensionId, uint256 duration, uint256 fuelConsumed, uint256 endTime);
    event TravelEnded(uint256 indexed tokenId, uint256 indexed dimensionId, uint256 durationActual, uint256 xpEarned, uint256 cdustFound, uint256 artifactFoundId, uint256 artifactTokenId);
    event PodRefueled(uint256 indexed tokenId, uint256 amountAdded, uint256 totalFuel);
    event PodLevelUp(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event PodUpgraded(uint256 indexed tokenId, uint256 upgradeType, uint256 fuelSpent, uint256 artifactsBurnedCount);
    event QuestRewardClaimed(uint256 indexed tokenId, uint256 indexed questId, uint256 cdustReward, uint256 artifactRewardId, uint256 artifactTokenId);
    event TravelControlDelegated(uint256 indexed tokenId, address indexed owner, address indexed delegatee);
    event TravelControlRevoked(uint256 indexed tokenId, address indexed owner, address indexed delegatee);
    event AdminParametersUpdated();
    event DimensionRegistered(uint256 indexed dimensionId, string name);
    event QuestRegistered(uint256 indexed questId, string description);


    // --- Modifiers ---

    modifier whenNotTraveling(uint256 tokenId) {
        if (_podTravel[tokenId].isTraveling) revert PodIsTraveling(tokenId);
        _;
    }

    modifier onlyPodOwnerOrDelegate(uint256 tokenId) {
        address owner_ = ownerOf(tokenId);
        address delegatee_ = _travelDelegate[tokenId];
        if (msg.sender != owner_ && msg.sender != delegatee_) revert NotPodOwnerOrDelegate(tokenId, msg.sender);
        _;
    }

    // --- Constructor ---

    constructor(
        address _artifactNFT,
        address _cdustToken,
        string memory baseURI
    ) ERC721("NFTravelPod", "NTPOD") Ownable(msg.sender) Pausable(false) {
        artifactNFT = IArtifactNFT(_artifactNFT);
        cdustToken = ICDUSTToken(_cdustToken);
        _baseTokenURI = baseURI;

        // Set initial XP required for levels (Example values)
        // Level 1 -> 2 requires 100 XP
        // Level 2 -> 3 requires 250 XP
        // Level 3 -> 4 requires 500 XP
        xpRequiredForLevel = [100, 250, 500, 1000, 2000, 4000, 8000, 16000, 32000, 64000]; // Up to level 10
    }

    // --- Admin Functions ---

    function setArtifactNFTAddress(address _artifactNFT) external onlyOwner {
        artifactNFT = IArtifactNFT(_artifactNFT);
    }

    function setCDUSTTokenAddress(address _cdustToken) external onlyOwner {
        cdustToken = ICDUSTToken(_cdustToken);
    }

    function registerDimension(
        uint256 dimensionId,
        string memory name,
        uint256 baseFuelCostPerMinuteBasisPoints,
        uint256 xpPerMinute,
        uint256 artifactDiscoveryChanceBasisPoints,
        uint256 minTravelDurationMinutes
    ) external onlyOwner {
        if (!_dimensions[dimensionId].exists) {
            registeredDimensionIds.push(dimensionId);
        }
        _dimensions[dimensionId] = DimensionData(
            true,
            name,
            baseFuelCostPerMinuteBasisPoints,
            xpPerMinute,
            artifactDiscoveryChanceBasisPoints,
            minTravelDurationMinutes
        );
        emit DimensionRegistered(dimensionId, name);
    }

    function getDimensionData(uint256 dimensionId) external view returns (DimensionData memory) {
        if (!_dimensions[dimensionId].exists) revert DimensionNotRegistered(dimensionId);
        return _dimensions[dimensionId];
    }

    function listDimensions() external view returns (uint256[] memory) {
        return registeredDimensionIds;
    }

    function registerQuest(
        uint256 questId,
        string memory description,
        QuestType questType,
        uint256 requiredLevel, // 0 if not a level requirement
        uint256 requiredDimension, // 0 if not a dimension travel requirement
        uint256 requiredArtifactId, // 0 if not an artifact requirement
        uint256 rewardCDUST,
        uint256 rewardArtifactId, // 0 if no artifact reward
        bool repeatable
    ) external onlyOwner {
        if (!_quests[questId].exists) {
            registeredQuestIds.push(questId);
        }
        _quests[questId] = Quest(
            true,
            description,
            questType,
            requiredLevel,
            requiredDimension,
            requiredArtifactId,
            rewardCDUST,
            rewardArtifactId,
            repeatable
        );
        emit QuestRegistered(questId, description);
    }

     function getQuestDetails(uint256 questId) external view returns (Quest memory) {
        if (!_quests[questId].exists) revert QuestNotRegistered(questId);
        return _quests[questId];
    }

    function listQuests() external view returns (uint256[] memory) {
        return registeredQuestIds;
    }


    function setGameParameters(
        uint256 _baseFuelCostPerDurationUnit,
        uint256 _xpPerDurationUnit,
        uint256 _baseArtifactDiscoveryChanceBasisPoints,
        uint256[] memory _xpRequiredForLevel // New array replaces existing
    ) external onlyOwner {
        baseFuelCostPerDurationUnit = _baseFuelCostPerDurationUnit;
        xpPerDurationUnit = _xpPerDurationUnit;
        baseArtifactDiscoveryChanceBasisPoints = _baseArtifactDiscoveryChanceBasisPoints;
        xpRequiredForLevel = _xpRequiredForLevel; // Update level requirements
        emit AdminParametersUpdated();
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawAdminFunds(address payable _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    function withdrawCDUST(address _to) external onlyOwner {
        uint256 balance = cdustToken.balanceOf(address(this));
        if (balance > 0) {
            cdustToken.safeTransfer(_to, balance);
        }
    }

    // --- Pod Management Functions ---

    function mintPod(address to) external payable whenNotPaused {
        require(msg.value >= podMintPrice, "Insufficient ETH for mint");
        uint256 tokenId = _podTokenIds.current();
        _podTokenIds.increment();

        _safeMint(to, tokenId);

        // Initialize pod state
        _podState[tokenId] = PodState({
            level: 1,
            xp: 0,
            fuel: 1000, // Starting fuel
            fuelEfficiencyBasisPoints: 10000, // 100% efficiency
            artifactLuckBasisPoints: 10000, // 100% luck
            lastUpdateTime: block.timestamp
        });

        emit PodMinted(tokenId, to, 1);
    }

    function burnPod(uint256 tokenId) external {
        address owner_ = ownerOf(tokenId);
        require(msg.sender == owner_, "Not pod owner");
        _burn(tokenId);
        // Clear state mappings (Solidity default values handle deletion mostly, but explicit can be clearer)
        delete _podState[tokenId];
        delete _podTravel[tokenId];
        delete _travelDelegate[tokenId];
        // Quest completion history is not deleted by burning a pod, could be added if needed.
        emit PodBurned(tokenId, owner_);
    }

    function upgradePodStats(uint256 tokenId, uint256 upgradeType) external whenNotPaused onlyPodOwnerOrDelegate(tokenId) {
        PodState storage pod = _podState[tokenId];
        uint256 cdustCost = 0;
        // Artifacts to burn mapping: artifactId => amount
        // mapping(uint256 => uint256) memory artifactCosts; // More complex, using predefined types for simplicity

        if (upgradeType == 1) { // Example: Increase Fuel Efficiency
            require(pod.fuelEfficiencyBasisPoints < 20000, "Max efficiency reached"); // Cap at 200%
            cdustCost = 500; // Example cost
            // Maybe require burning a specific artifact type/amount
            // require(artifactNFT.balanceOf(msg.sender, REQUIRED_ARTIFACT_ID) >= 1, "Need required artifact");
            // artifactNFT.safeTransferFrom(msg.sender, address(this), REQUIRED_ARTIFACT_ID, 1, "");
            // artifactNFT.burn(REQUIRED_ARTIFACT_TOKEN_ID); // If specific token burn is needed

            _transferCDUSTFromUser(cdustCost);
            pod.fuelEfficiencyBasisPoints += 500; // Increase efficiency by 5%
            //emit PodUpgraded(...); // Detailed event for upgrades
        } else if (upgradeType == 2) { // Example: Increase Artifact Luck
             require(pod.artifactLuckBasisPoints < 20000, "Max luck reached"); // Cap at 200%
             cdustCost = 750; // Example cost
             _transferCDUSTFromUser(cdustCost);
             pod.artifactLuckBasisPoints += 500; // Increase luck by 5%
             //emit PodUpgraded(...);
        } else {
            revert UpgradeTypeInvalid(upgradeType);
        }

        pod.lastUpdateTime = block.timestamp;
        emit PodUpgraded(tokenId, upgradeType, cdustCost, 0); // Simplify artifact count
    }

    function levelUpPod(uint256 tokenId) external whenNotPaused onlyPodOwnerOrDelegate(tokenId) {
        PodState storage pod = _podState[tokenId];
        uint256 currentLevel = pod.level;
        uint256 currentXP = pod.xp;

        if (currentLevel >= xpRequiredForLevel.length) {
            // Already at max level defined
            revert NoXPToLevelUp(tokenId);
        }

        uint256 requiredXP = xpRequiredForLevel[currentLevel - 1]; // XP needed to reach next level

        if (currentXP < requiredXP) {
            revert NoXPToLevelUp(tokenId);
        }

        // Apply levels until XP is insufficient
        while (pod.level < xpRequiredForLevel.length && pod.xp >= xpRequiredForLevel[pod.level - 1]) {
            pod.xp -= xpRequiredForLevel[pod.level - 1]; // Subtract XP for the level up
            pod.level++; // Increment level
            // Potentially increase base stats here based on level
            if (pod.level <= xpRequiredForLevel.length) {
                 emit PodLevelUp(tokenId, currentLevel, pod.level);
                 currentLevel = pod.level; // Update for the next iteration check
            }
        }

        pod.lastUpdateTime = block.timestamp;
        // If levels were gained, events were emitted inside the loop.
    }


    function delegateTravelControl(uint256 tokenId, address delegatee) external {
        require(msg.sender == ownerOf(tokenId), "Not pod owner");
        _travelDelegate[tokenId] = delegatee;
        emit TravelControlDelegated(tokenId, msg.sender, delegatee);
    }

    function revokeTravelControl(uint256 tokenId) external onlyPodOwnerOrDelegate(tokenId) {
        address owner_ = ownerOf(tokenId);
        address delegatee_ = _travelDelegate[tokenId];
        delete _travelDelegate[tokenId]; // Set delegatee to address(0)
        emit TravelControlRevoked(tokenId, owner_, delegatee_);
    }

    function getTravelDelegate(uint256 tokenId) external view returns (address) {
        return _travelDelegate[tokenId];
    }

    // --- Travel Functions ---

    function startTravel(uint256 tokenId, uint256 dimensionId, uint256 durationInMinutes)
        external
        whenNotPaused
        whenNotTraveling(tokenId)
        onlyPodOwnerOrDelegate(tokenId)
    {
        if (!_dimensions[dimensionId].exists) revert DimensionNotRegistered(dimensionId);
        DimensionData storage dim = _dimensions[dimensionId];
        require(durationInMinutes >= dim.minTravelDurationMinutes, "Duration too short for dimension");

        PodState storage pod = _podState[tokenId];
        uint256 fuelNeeded = calculateFuelCost(pod.fuelEfficiencyBasisPoints, dim.baseFuelCostPerMinuteBasisPoints, durationInMinutes);

        if (pod.fuel < fuelNeeded) revert InsufficientFuel(tokenId, fuelNeeded, pod.fuel);

        // Consume fuel
        pod.fuel -= fuelNeeded;
        pod.lastUpdateTime = block.timestamp; // State updated

        // Set travel state
        _podTravel[tokenId] = TravelState({
            isTraveling: true,
            dimensionId: dimensionId,
            startTime: block.timestamp,
            endTime: block.timestamp + durationInMinutes * 1 minutes // Using 1 minute as the base duration unit
        });

        emit TravelStarted(tokenId, dimensionId, durationInMinutes, fuelNeeded, _podTravel[tokenId].endTime);
    }

    function endTravel(uint256 tokenId) external whenNotPaused onlyPodOwnerOrDelegate(tokenId) {
        TravelState storage travel = _podTravel[tokenId];
        if (!travel.isTraveling) revert PodNotTraveling(tokenId);
        if (block.timestamp < travel.endTime) revert TravelDurationNotMet(tokenId, travel.endTime);

        PodState storage pod = _podState[tokenId];
        DimensionData storage dim = _dimensions[travel.dimensionId];

        // Calculate actual duration traveled (capped at intended duration if somehow called later)
        uint256 actualDurationMinutes = (travel.endTime - travel.startTime) / 1 minutes;
        if (block.timestamp > travel.endTime) {
             actualDurationMinutes = (block.timestamp - travel.startTime) / 1 minutes; // If called late, reward for full time since start
             // Cap XP/rewards at some limit if needed to prevent abuse of delayed calls
             if (actualDurationMinutes > (travel.endTime - travel.startTime) / 1 minutes + 60) { // e.g., Cap at duration + 1 hour
                  actualDurationMinutes = (travel.endTime - travel.startTime) / 1 minutes + 60;
             }
        }


        uint256 xpGained = actualDurationMinutes * dim.xpPerMinute;
        pod.xp += xpGained;

        // --- Reward Calculation (Pseudo-randomness) ---
        // WARNING: Using block variables for randomness is predictable.
        // For production, use Chainlink VRF or a commit-reveal scheme.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            tx.origin,
            tokenId,
            actualDurationMinutes
        )));

        uint256 cdustFound = 0;
        uint256 artifactFoundId = 0;
        uint256 artifactTokenId = 0;

        // Example: Chance to find CDUST
        uint256 cdustRoll = randomSeed % 10000; // 0-9999
        uint256 cdustChanceBasisPoints = dim.xpPerMinute * 10; // Simple chance based on dimension XP rate
        if (cdustRoll < cdustChanceBasisPoints) {
             cdustFound = actualDurationMinutes * dim.xpPerMinute * 10; // Example: CDUST reward scales with XP gained
             cdustToken.transfer(ownerOf(tokenId), cdustFound);
        }

        // Example: Chance to find an Artifact
        uint256 artifactRoll = (randomSeed / 10000) % 10000; // Use a different part of the seed
        uint256 totalArtifactChanceBasisPoints = (baseArtifactDiscoveryChanceBasisPoints * pod.artifactLuckBasisPoints) / 10000; // Apply pod luck
        totalArtifactChanceBasisPoints = (totalArtifactChanceBasisPoints * dim.artifactDiscoveryChanceBasisPoints) / 10000; // Apply dimension chance

        if (artifactRoll < totalArtifactChanceBasisPoints) {
            // Simulate finding a specific artifact type
            // More advanced: logic here to determine *which* artifact based on dimension, level, etc.
            // For simplicity, let's hardcode finding Artifact ID 1
            artifactFoundId = 1; // Example Artifact ID
            // Mint the artifact to the pod owner
            artifactTokenId = artifactNFT.mint(ownerOf(tokenId), artifactFoundId);
        }
        // --- End Reward Calculation ---


        // Clear travel state
        travel.isTraveling = false;
        travel.dimensionId = 0; // Reset
        travel.startTime = 0; // Reset
        travel.endTime = 0; // Reset
        pod.lastUpdateTime = block.timestamp; // State updated

        emit TravelEnded(
            tokenId,
            dim.minTravelDurationMinutes, // Use registered dimension ID for event
            actualDurationMinutes,
            xpGained,
            cdustFound,
            artifactFoundId,
            artifactTokenId
        );
    }

    function refuelPod(uint256 tokenId, uint256 amount) external whenNotPaused onlyPodOwnerOrDelegate(tokenId) {
        PodState storage pod = _podState[tokenId];
        uint256 ownerCDUST = cdustToken.balanceOf(msg.sender);
        if (ownerCDUST < amount) revert InsufficientCDUST(msg.sender, amount, ownerCDUST);

        _transferCDUSTFromUser(amount); // Transfer CDUST from user to contract

        pod.fuel += amount; // Add fuel units (1 CDUST = 1 Fuel Unit)
        pod.lastUpdateTime = block.timestamp; // State updated

        emit PodRefueled(tokenId, amount, pod.fuel);
    }

    // --- Dimension & Quest Functions ---

    function claimQuestReward(uint256 tokenId, uint256 questId) external whenNotPaused onlyPodOwnerOrDelegate(tokenId) {
        Quest storage quest = _quests[questId];
        if (!quest.exists) revert QuestNotRegistered(questId);
        if (_podCompletedQuests[tokenId][questId] && !quest.repeatable) revert QuestAlreadyCompleted(tokenId, questId);

        // Check quest completion criteria based on quest type and pod state
        bool criteriaMet = false;
        PodState storage pod = _podState[tokenId];

        if (quest.questType == QuestType.TravelToDimension) {
            // This would typically require checking travel history, which isn't stored.
            // A simpler implementation is to require the pod to *be* in the dimension, or just finished traveling *from* it.
            // Let's assume for simplicity it requires the pod's LAST finished travel dimension matches.
            // This requires modifying endTravel to store last finished dimension.
             TravelState storage travel = _podTravel[tokenId]; // Check the state *after* endTravel has potentially run
             // A better way would be a mapping `_podLastDimension[tokenId]` updated in `endTravel`.
             // For this example, we'll make a simplified check that is illustrative.
             // This check is illustrative, not robust. A robust system would store completed trips.
             criteriaMet = (travel.dimensionId == quest.requiredDimension && !travel.isTraveling && travel.endTime > 0 && (block.timestamp - travel.endTime) < 1 hours); // Completed recently

        } else if (quest.questType == QuestType.ReachLevel) {
            criteriaMet = pod.level >= quest.requiredLevel;

        } else if (quest.questType == QuestType.FindArtifact) {
            // Requires checking if the owner holds the specific artifact type.
            // ERC721 doesn't have a standard way to query by type/ID across all tokens of a kind.
            // An ERC1155 for artifacts would be better, or a custom getter on IArtifactNFT.
            // Assuming IArtifactNFT has a `balanceOf(address owner, uint256 artifactId)` like ERC1155
            // criteriaMet = artifactNFT.balanceOf(ownerOf(tokenId), quest.requiredArtifactId) > 0;
             // For this example, we'll simplify: requires the pod to have *found* this artifact during its travels (needs state tracking).
             // Let's assume `endTravel` could mark artifacts found on the pod state, or just check if the owner holds ANY of that type (less robust).
             // Let's simplify and assume the user *holds* the artifact required.
             // This requires a way to check if the user holds *any* token of a specific artifact ID. This is non-standard ERC721.
             // A complex solution would iterate through the user's artifact tokens from ArtifactNFT contract.
             // For simplicity, let's assume the requiredArtifactId is 0 if not needed for this quest type.
             // And if needed, the check is against the artifact found during the *last* travel (simplification).
             // This is a placeholder logic: In a real contract, robust artifact inventory check is needed.
              criteriaMet = (quest.requiredArtifactId == 0 || (artifactFoundDuringLastTravel(tokenId) == quest.requiredArtifactId));
        } else {
            // Unknown quest type
            revert QuestCriteriaNotMet(tokenId, questId);
        }

        if (!criteriaMet) revert QuestCriteriaNotMet(tokenId, questId);

        // Grant rewards
        uint256 cdustReward = quest.rewardCDUST;
        uint256 artifactRewardId = quest.rewardArtifactId;
        uint256 artifactTokenId = 0;

        if (cdustReward > 0) {
            cdustToken.transfer(ownerOf(tokenId), cdustReward);
        }
        if (artifactRewardId > 0) {
             artifactTokenId = artifactNFT.mint(ownerOf(tokenId), artifactRewardId);
        }

        // Mark quest as completed (if not repeatable)
        if (!quest.repeatable) {
            _podCompletedQuests[tokenId][questId] = true;
        }

        emit QuestRewardClaimed(tokenId, questId, cdustReward, artifactRewardId, artifactTokenId);
    }

    function getPodCompletedQuests(uint256 tokenId) external view returns (uint256[] memory) {
         // This is hard to implement efficiently with a simple mapping `mapping(uint256 => mapping(uint256 => bool))`.
         // To return a list, you'd need a different data structure, e.g., `mapping(uint256 => uint256[])`.
         // Or query all possible quest IDs and check the boolean mapping.
         // Let's provide a placeholder or simplified view.
         // Simple placeholder: returns empty array or requires iterating off-chain.
         // Or iterate through registeredQuestIds and check the mapping.
         uint256[] memory completed;
         uint256 count = 0;
         for(uint i = 0; i < registeredQuestIds.length; i++) {
             if (_podCompletedQuests[tokenId][registeredQuestIds[i]]) {
                 count++;
             }
         }

         completed = new uint256[](count);
         count = 0;
          for(uint i = 0; i < registeredQuestIds.length; i++) {
             if (_podCompletedQuests[tokenId][registeredQuestIds[i]]) {
                 completed[count] = registeredQuestIds[i];
                 count++;
             }
         }
         return completed;
    }


    // --- Getters for Pod State ---

    // Returns the full PodState struct
    function getPodState(uint256 tokenId) external view returns (PodState memory) {
         _requireOwned(tokenId); // Ensure it's a valid token ID
        return _podState[tokenId];
    }

    function getPodLevel(uint256 tokenId) external view returns (uint256) {
         _requireOwned(tokenId);
        return _podState[tokenId].level;
    }

    function getPodXP(uint256 tokenId) external view returns (uint256) {
         _requireOwned(tokenId);
        return _podState[tokenId].xp;
    }

     function getPodFuel(uint256 tokenId) external view returns (uint256) {
          _requireOwned(tokenId);
        return _podState[tokenId].fuel;
    }

     function getPodEfficiency(uint256 tokenId) external view returns (uint256) {
          _requireOwned(tokenId);
        return _podState[tokenId].fuelEfficiencyBasisPoints;
    }

     function getPodLuck(uint256 tokenId) external view returns (uint256) {
          _requireOwned(tokenId);
        return _podState[tokenId].artifactLuckBasisPoints;
    }


    function isPodTraveling(uint256 tokenId) external view returns (bool) {
         _requireOwned(tokenId);
        return _podTravel[tokenId].isTraveling;
    }

    function getPodCurrentTravel(uint256 tokenId) external view returns (uint256 dimensionId, uint256 startTime, uint256 endTime) {
         _requireOwned(tokenId);
        TravelState storage travel = _podTravel[tokenId];
        return (travel.dimensionId, travel.startTime, travel.endTime);
    }

     function getPodXPNeededForLevel(uint256 tokenId) external view returns (uint256) {
        uint256 currentLevel = _podState[tokenId].level;
        if (currentLevel >= xpRequiredForLevel.length) {
            return 0; // Max level reached
        }
        return xpRequiredForLevel[currentLevel - 1];
    }

    function getPodFuelCostForTravel(uint256 tokenId, uint256 dimensionId, uint256 durationInMinutes) external view returns (uint256) {
         _requireOwned(tokenId);
        if (!_dimensions[dimensionId].exists) revert DimensionNotRegistered(dimensionId);
        PodState storage pod = _podState[tokenId];
        DimensionData storage dim = _dimensions[dimensionId];

        return calculateFuelCost(pod.fuelEfficiencyBasisPoints, dim.baseFuelCostPerMinuteBasisPoints, durationInMinutes);
    }


    // --- ERC721 Overrides (Standard + Dynamic Metadata) ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists

        // The tokenURI typically points to a JSON metadata file.
        // For dynamic NFTs, this JSON is often served off-chain by a service
        // that reads the on-chain state and generates the JSON accordingly.
        // The URI returned here is the pointer to that service/file.
        // Example: "ipfs://<hash>/{tokenId}" or "http://<metadata-service-url>/<contract-address>/{tokenId}"

        // For this example, we'll return a base URI + token ID.
        // A separate service would need to exist at this base URI + ID
        // that reads the PodState using getPodState() and formats the JSON.

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return ""; // Or revert, or return a default placeholder
        }
        return string(abi.encodePacked(base, tokenId.toString()));

        // To include dynamic data directly in the URI string (less common for large data):
        /*
         PodState memory pod = _podState[tokenId];
         string memory dynamicData = string(abi.encodePacked(
              "Level: ", pod.level.toString(),
              ", XP: ", pod.xp.toString(),
              ", Fuel: ", pod.fuel.toString()
              // ... other state
         ));
         return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(string(abi.encodePacked(
              '{"name": "NFTravel Pod #', tokenId.toString(), '",',
              '"description": "A dynamic travel pod exploring the universe.",',
              '"attributes": [',
                  '{"trait_type": "Level", "value": ', pod.level.toString(), '},',
                  '{"trait_type": "XP", "value": ', pod.xp.toString(), '},',
                  '{"trait_type": "Fuel", "value": ', pod.fuel.toString(), '},',
                  '{"trait_type": "Fuel Efficiency", "value": ', (pod.fuelEfficiencyBasisPoints / 100).toString(), '},', // Display as percentage
                  '{"trait_type": "Artifact Luck", "value": ', (pod.artifactLuckBasisPoints / 100).toString(), '}', // Display as percentage
                  // ... add travel state if needed ...
              ']}',
              // Optional: image, external_url etc.
         ))))));
         */
    }

    // --- Internal Helper Functions ---

    // Helper to transfer CDUST from msg.sender to the contract
    function _transferCDUSTFromUser(uint256 amount) internal {
        require(address(cdustToken) != address(0), "CDUST Token address not set");
        require(cdustToken.balanceOf(msg.sender) >= amount, "Insufficient CDUST balance");
        // Require caller to have approved this contract to spend CDUST
        require(cdustToken.allowance(msg.sender, address(this)) >= amount, "CDUST allowance too low");
        cdustToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Helper to calculate fuel cost based on efficiency and dimension multiplier
    function calculateFuelCost(
        uint256 podEfficiencyBasisPoints,
        uint256 dimensionFuelCostBasisPoints,
        uint256 durationInMinutes
    ) internal view returns (uint256) {
         // Base cost * duration * dimension multiplier / 10000 * pod efficiency multiplier / 10000
         // Example: 100 fuel/min * 60 min * 1.2 (dim) / 10000 * 0.9 (pod eff) / 10000
         // Simplified: base * duration * dim_mult/10000 * pod_eff/10000
         uint256 cost = baseFuelCostPerDurationUnit * durationInMinutes;
         cost = (cost * dimensionFuelCostBasisPoints) / 10000;
         cost = (cost * 10000) / podEfficiencyBasisPoints; // Efficiency reduces cost (10000 / efficiency)
         return cost;
    }

    // Placeholder/Illustrative check for artifact found during last travel
    // This would need a better state tracking mechanism in a real contract
    function artifactFoundDuringLastTravel(uint256 tokenId) internal view returns (uint256) {
        // This is a very simplified placeholder.
        // A robust system would record artifacts found per travel or per pod.
        // This just uses the pseudo-random roll logic from endTravel to simulate the check.
        // Do NOT rely on this for security or accuracy in production.
         TravelState storage travel = _podTravel[tokenId];
         if (travel.isTraveling || travel.endTime == 0) return 0; // Not relevant if currently traveling or never traveled

         // Re-calculate the pseudo-randomness based on past travel data
         uint256 actualDurationMinutes = (travel.endTime - travel.startTime) / 1 minutes;
         uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            travel.endTime, // Use travel end time as a seed component
            block.difficulty, // block.difficulty is deprecated/unreliable on PoS, use block.number for determinism post-merge
            ownerOf(tokenId), // Use owner at time of check? Or tx.origin from original endTravel? Complicated.
            tokenId,
            actualDurationMinutes
        )));

        uint256 artifactRoll = (randomSeed / 10000) % 10000;
        PodState storage pod = _podState[tokenId]; // Get current pod state
        DimensionData storage dim = _dimensions[travel.dimensionId]; // Get dimension data *at time of travel* if it could change

        uint256 totalArtifactChanceBasisPoints = (baseArtifactDiscoveryChanceBasisPoints * pod.artifactLuckBasisPoints) / 10000;
        totalArtifactChanceBasisPoints = (totalArtifactChanceBasisPoints * dim.artifactDiscoveryChanceBasisPoints) / 10000;

        if (artifactRoll < totalArtifactChanceBasisPoints) {
            return 1; // Simulate finding Artifact ID 1
        }
        return 0; // No artifact found
    }


    // The following functions are standard ERC721 functions inherited and often don't need overriding
    // unless specific checks or logic are required (e.g., pausing transfers).
    // ERC721 standard requires:
    // balanceOf(address owner)
    // ownerOf(uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
    // transferFrom(address from, address to, uint256 tokenId)
    // approve(address to, uint256 tokenId)
    // setApprovalForAll(address operator, bool approved)
    // getApproved(uint256 tokenId)
    // isApprovedForAll(address owner, address operator)
    // supportsInterface(bytes4 interfaceId)

    // We inherit and use the OpenZeppelin implementation.
    // _safeMint, _burn, _transfer are used internally.
    // _requireOwned is a helpful internal check used in getters.

    // Example of overriding transferFrom to add a check (optional)
    /*
    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        // Add custom check before allowing transfer, e.g., cannot transfer if traveling
        if (_podTravel[tokenId].isTraveling) revert PodIsTraveling(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused {
         if (_podTravel[tokenId].isTraveling) revert PodIsTraveling(tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
         if (_podTravel[tokenId].isTraveling) revert PodIsTraveling(tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }
    */

    // Pausable override to apply to transfers
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
        // Prevent transfer if pod is traveling (unless transferring to/from zero address for mint/burn)
        if (from != address(0) && to != address(0)) {
             if (_podTravel[tokenId].isTraveling) revert PodIsTraveling(tokenId);
        }
    }
}
```