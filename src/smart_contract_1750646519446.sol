Okay, let's craft a smart contract focusing on time-based mechanics, resource management, and conditional unlocks using oracles – something centered around "creation" or "crafting" with delayed outcomes.

We'll call it `ChronoCrafter`. It will allow users to deposit resources (ERC-20 tokens), initiate timed "crafting" projects that produce NFTs, and manage timed/conditional vaults for holding resources.

Here's the outline and function summary, followed by the Solidity code.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing necessary interfaces and libraries
// We'll assume standard implementations exist for ERC20, ERC721, Ownable, Pausable, ReentrancyGuard.
// For the oracle part, we'll use a simplified oracle pattern or an interface like Chainlink AggregatorV3Interface as an example.
// For this example, let's define a simple Oracle interface for conditional checks.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // We'll be minting/managing these
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // To list user NFTs (optional but useful)
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Define a simple Oracle interface for demonstrating conditional unlocks
interface IConditionOracle {
    // Function to check if a specific condition represented by bytes data is met
    // Returns true if condition is met, false otherwise.
    function checkCondition(bytes calldata conditionData) external view returns (bool);
}


// Contract Outline:
// 1. State Variables: Define contract-level data structures and variables.
// 2. Structs: Define complex data types for recipes, projects, and vaults.
// 3. Events: Define events to signal important state changes.
// 4. Modifiers: Define custom modifiers for access control and state checks.
// 5. Constructor: Initialize the contract.
// 6. Recipe Management: Functions to define, update, and query crafting recipes.
// 7. Catalyst Management: Functions to define and query catalysts (optional items affecting crafting).
// 8. Crafting Management: Functions to start, query, and claim crafting projects.
// 9. Resource Management: Functions for users to deposit and potentially withdraw resources.
// 10. Timed & Conditional Vaults: Functions to define vault types, deposit into, and claim from vaults.
// 11. Oracle Integration: Functionality related to interacting with an oracle for vault conditions.
// 12. NFT Interaction: Basic interaction with the ERC721 standard (minting within claim).
// 13. Admin/Utility: Pause, withdrawal of contract balance, setting key addresses.
// 14. Query Functions: Helper functions for users to query state.

// Function Summary:
// --- Recipe Management ---
// 1. defineRecipe(params...): Admin function to add a new crafting recipe.
// 2. setRecipeActiveStatus(recipeId, isActive): Admin function to enable/disable a recipe.
// 3. updateRecipe(recipeId, params...): Admin function to modify an existing recipe (careful with live projects).
// 4. getRecipeDetails(recipeId): Public function to view details of a recipe.
// --- Catalyst Management ---
// 5. defineCatalyst(params...): Admin function to add a new catalyst type.
// 6. setCatalystActiveStatus(catalystId, isActive): Admin function to enable/disable a catalyst.
// 7. getCatalystDetails(catalystId): Public function to view details of a catalyst.
// --- Crafting Management ---
// 8. startCrafting(recipeId, catalystId, resourceAmounts): User function to initiate a crafting project by providing resources and optionally a catalyst.
// 9. claimCraftedItem(projectId): User function to claim the minted NFT once the crafting project is complete.
// 10. cancelCrafting(projectId): User function to cancel an ongoing project (partial/no resource refund).
// 11. getProjectDetails(projectId): Public function to view details of a specific crafting project.
// 12. getUserProjects(user): Public function to list active/completed projects for a user.
// --- Resource Management ---
// 13. depositResource(tokenAddress, amount): User function to deposit resources into the contract (for future crafting/vaults).
// 14. withdrawResource(tokenAddress, amount): Admin/Restricted function to withdraw specific resources from the contract (e.g., operational).
// --- Timed & Conditional Vaults ---
// 15. defineTimedVaultType(params...): Admin function to add a new type of timed/conditional vault.
// 16. setVaultTypeActiveStatus(vaultTypeId, isActive): Admin function to enable/disable a vault type.
// 17. depositIntoTimedVault(vaultTypeId, amount, conditionData): User function to deposit resources into a vault with a time and potential oracle condition.
// 18. claimFromTimedVault(vaultEntryId): User function to claim resources from a vault entry once conditions are met.
// 19. getVaultTypeDetails(vaultTypeId): Public function to view details of a vault type.
// 20. getUserVaultEntries(user): Public function to list active/completed vault entries for a user.
// 21. getVaultEntryDetails(vaultEntryId): Public function to view details of a specific vault entry.
// 22. checkVaultUnlockStatus(vaultEntryId): Public function to check if a specific vault entry is currently unlockable.
// --- Oracle Integration ---
// 23. setConditionOracle(oracleAddress): Admin function to set the address of the condition oracle contract.
// --- NFT Interaction ---
// (Handled internally within claimCraftedItem using IERC721)
// --- Admin/Utility ---
// 24. pauseContract(): Admin function to pause contract operations (crafting, depositing).
// 25. unpauseContract(): Admin function to unpause the contract.
// 26. setFeeRecipient(recipient): Admin function to set the address receiving protocol fees (if any implemented later).
// 27. emergencyVaultWithdraw(vaultEntryId): Admin function to bypass conditions for a specific vault entry in emergencies (careful!).

// Total functions: 27 (More than 20 as requested)

contract ChronoCrafter is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- State Variables ---
    address public resourceNFT; // Address of the ERC721 contract this ChronoCrafter mints to.
    address public conditionOracle; // Address of the IConditionOracle contract.
    address public feeRecipient; // Address to send any collected fees (fees not implemented in detail here but structure exists).

    Counters.Counter private _recipeIdCounter;
    Counters.Counter private _catalystIdCounter;
    Counters.Counter private _projectIdCounter;
    Counters.Counter private _vaultTypeIdCounter;
    Counters.Counter private _vaultEntryIdCounter;

    // --- Structs ---

    struct Recipe {
        bool isActive;
        string name;
        uint256 duration; // Base time required to craft (seconds)
        IERC20[] requiredResources; // List of resource tokens required
        uint256[] requiredAmounts; // Corresponding amounts of required resources
        bytes nftMetadataBase; // Base data for NFT metadata (e.g., IPFS hash prefix or type)
        bytes nftPropertiesData; // Data influencing NFT properties (e.g., rarity, stats)
    }

    struct Catalyst {
        bool isActive;
        string name;
        uint256 durationMultiplier; // E.g., 9000 for 90% (0.9) speedup. 10000 means no effect.
        // Add other potential effects like outcome bonus, resource discount, etc.
    }

    enum ProjectStatus { Ongoing, Completed, Claimed, Cancelled }

    struct CraftingProject {
        uint256 id;
        address owner;
        uint256 recipeId;
        uint256 catalystId; // 0 if no catalyst used
        uint256 startTime;
        uint256 endTime;
        ProjectStatus status;
        // Store the actual resources paid? Or assume they are held by contract?
        // For simplicity, assume resources are transferred and held.
    }

    enum VaultConditionType {
        None,          // Only time-based
        OracleBased    // Time + external condition verified by Oracle
        // Add other types like min/max block number, specific event triggered elsewhere, etc.
    }

    struct TimedVaultType {
        bool isActive;
        string name;
        IERC20 resourceToken; // The single token type allowed in this vault type
        uint256 baseLockDuration; // Base time the deposit is locked (seconds)
        VaultConditionType conditionType;
        // Specific parameters for the condition might be stored here or per-entry
    }

    enum VaultEntryStatus { Locked, Unlockable, Claimed }

    struct UserVaultEntry {
        uint256 id;
        address owner;
        uint256 vaultTypeId;
        uint256 amount;
        uint256 depositTime;
        uint256 unlockTime; // Calculated based on baseLockDuration + modifiers
        VaultEntryStatus status;
        bytes conditionData; // Data specific to the condition (e.g., oracle query parameters, threshold value)
    }

    // --- Mappings ---
    mapping(uint256 => Recipe) public recipes;
    mapping(uint256 => Catalyst) public catalysts;
    mapping(uint256 => CraftingProject) public projects;
    mapping(uint256 => TimedVaultType) public vaultTypes;
    mapping(uint256 => UserVaultEntry) public vaultEntries;

    // Keep track of projects/vaults owned by each user for easier querying
    mapping(address => uint256[]) public userProjectIds;
    mapping(address => uint256[]) public userVaultEntryIds;

    // --- Events ---
    event RecipeDefined(uint256 indexed recipeId, string name, bool isActive);
    event CatalystDefined(uint256 indexed catalystId, string name, bool isActive);
    event ProjectStarted(uint256 indexed projectId, address indexed owner, uint256 indexed recipeId, uint256 catalystId, uint256 endTime);
    event ItemClaimed(uint256 indexed projectId, address indexed owner, uint256 indexed tokenId);
    event ProjectCancelled(uint256 indexed projectId, address indexed owner);
    event VaultTypeDefined(uint256 indexed vaultTypeId, string name, bool isActive);
    event VaultDeposited(uint256 indexed vaultEntryId, address indexed owner, uint256 indexed vaultTypeId, uint256 amount, uint256 unlockTime);
    event VaultClaimed(uint256 indexed vaultEntryId, address indexed owner, uint256 amount);
    event ConditionOracleSet(address indexed oracleAddress);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier onlyRecipeActive(uint256 _recipeId) {
        require(recipes[_recipeId].isActive, "Recipe is not active");
        _;
    }

    modifier onlyCatalystActive(uint256 _catalystId) {
        // If catalystId is 0, it means no catalyst is used, bypass the check
        if (_catalystId != 0) {
            require(catalysts[_catalystId].isActive, "Catalyst is not active");
        }
        _;
    }

    modifier onlyVaultTypeActive(uint256 _vaultTypeId) {
        require(vaultTypes[_vaultTypeId].isActive, "Vault type is not active");
        _;
    }

    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].owner == msg.sender, "Not project owner");
        _;
    }

    modifier onlyVaultEntryOwner(uint256 _vaultEntryId) {
        require(vaultEntries[_vaultEntryId].owner == msg.sender, "Not vault entry owner");
        _;
    }

    // --- Constructor ---
    constructor(address _resourceNFTAddress) Ownable(msg.sender) Pausable() {
        resourceNFT = _resourceNFTAddress;
        feeRecipient = msg.sender; // Default fee recipient is owner
        // _conditionOracle is set via admin function
    }

    // --- Recipe Management ---

    // 1. defineRecipe
    function defineRecipe(
        string calldata _name,
        uint256 _duration,
        IERC20[] calldata _requiredResources,
        uint256[] calldata _requiredAmounts,
        bytes calldata _nftMetadataBase,
        bytes calldata _nftPropertiesData
    ) external onlyOwner nonReentrant whenNotPaused {
        require(_requiredResources.length == _requiredAmounts.length, "Resource array length mismatch");
        _recipeIdCounter.increment();
        uint256 newRecipeId = _recipeIdCounter.current();

        recipes[newRecipeId] = Recipe({
            isActive: true,
            name: _name,
            duration: _duration,
            requiredResources: _requiredResources,
            requiredAmounts: _requiredAmounts,
            nftMetadataBase: _nftMetadataBase,
            nftPropertiesData: _nftPropertiesData
        });

        emit RecipeDefined(newRecipeId, _name, true);
    }

    // 2. setRecipeActiveStatus
    function setRecipeActiveStatus(uint256 _recipeId, bool _isActive) external onlyOwner nonReentrant {
        require(_recipeId > 0 && _recipeId <= _recipeIdCounter.current(), "Invalid recipe ID");
        recipes[_recipeId].isActive = _isActive;
        emit RecipeDefined(_recipeId, recipes[_recipeId].name, _isActive); // Re-emit with status change
    }

    // 3. updateRecipe (Caution: Updating recipes might affect ongoing projects)
    // Consider adding checks like 'no active projects using this recipe' or versioning
    function updateRecipe(
        uint256 _recipeId,
        string calldata _name,
        uint256 _duration,
        IERC20[] calldata _requiredResources,
        uint256[] calldata _requiredAmounts,
        bytes calldata _nftMetadataBase,
        bytes calldata _nftPropertiesData
    ) external onlyOwner nonReentrant {
         require(_recipeId > 0 && _recipeId <= _recipeIdCounter.current(), "Invalid recipe ID");
         require(_requiredResources.length == _requiredAmounts.length, "Resource array length mismatch");

         recipes[_recipeId].name = _name;
         recipes[_recipeId].duration = _duration;
         recipes[_recipeId].requiredResources = _requiredResources; // This replaces the array!
         recipes[_recipeId].requiredAmounts = _requiredAmounts; // This replaces the array!
         recipes[_recipeId].nftMetadataBase = _nftMetadataBase;
         recipes[_recipeId].nftPropertiesData = _nftPropertiesData;

         // Note: isActive status is not changed by this update
         emit RecipeDefined(_recipeId, _name, recipes[_recipeId].isActive);
    }

    // 4. getRecipeDetails
    function getRecipeDetails(uint256 _recipeId) external view returns (
        uint256 recipeId,
        bool isActive,
        string memory name,
        uint256 duration,
        address[] memory requiredResourceAddresses,
        uint256[] memory requiredAmounts,
        bytes memory nftMetadataBase,
        bytes memory nftPropertiesData
    ) {
        require(_recipeId > 0 && _recipeId <= _recipeIdCounter.current(), "Invalid recipe ID");
        Recipe storage r = recipes[_recipeId];

        address[] memory resourceAddresses = new address[](r.requiredResources.length);
        for (uint i = 0; i < r.requiredResources.length; i++) {
            resourceAddresses[i] = address(r.requiredResources[i]);
        }

        return (
            _recipeId,
            r.isActive,
            r.name,
            r.duration,
            resourceAddresses,
            r.requiredAmounts,
            r.nftMetadataBase,
            r.nftPropertiesData
        );
    }

    // --- Catalyst Management ---

    // 5. defineCatalyst
    function defineCatalyst(
        string calldata _name,
        uint256 _durationMultiplier // e.g., 9000 for 0.9x duration (10% speedup)
    ) external onlyOwner nonReentrant whenNotPaused {
        require(_durationMultiplier > 0, "Multiplier must be positive");
         _catalystIdCounter.increment();
        uint256 newCatalystId = _catalystIdCounter.current();

        catalysts[newCatalystId] = Catalyst({
            isActive: true,
            name: _name,
            durationMultiplier: _durationMultiplier
        });

        emit CatalystDefined(newCatalystId, _name, true);
    }

    // 6. setCatalystActiveStatus
    function setCatalystActiveStatus(uint256 _catalystId, bool _isActive) external onlyOwner nonReentrant {
         require(_catalystId > 0 && _catalystId <= _catalystIdCounter.current(), "Invalid catalyst ID");
         catalysts[_catalystId].isActive = _isActive;
         emit CatalystDefined(_catalystId, catalysts[_catalystId].name, _isActive); // Re-emit with status change
    }

    // 7. getCatalystDetails
    function getCatalystDetails(uint256 _catalystId) external view returns (
        uint256 catalystId,
        bool isActive,
        string memory name,
        uint256 durationMultiplier
    ) {
        require(_catalystId > 0 && _catalystId <= _catalystIdCounter.current(), "Invalid catalyst ID");
        Catalyst storage c = catalysts[_catalystId];
        return (_catalystId, c.isActive, c.name, c.durationMultiplier);
    }

    // --- Crafting Management ---

    // 8. startCrafting
    function startCrafting(
        uint256 _recipeId,
        uint256 _catalystId, // 0 for no catalyst
        uint256[] calldata _providedAmounts // Amounts of resources provided, must match recipe order
    ) external nonReentrant whenNotPaused onlyRecipeActive(_recipeId) onlyCatalystActive(_catalystId) {
        Recipe storage recipe = recipes[_recipeId];
        require(_providedAmounts.length == recipe.requiredAmounts.length, "Provided amounts array length mismatch");

        // Transfer required resources from user to contract
        for (uint i = 0; i < recipe.requiredResources.length; i++) {
            require(_providedAmounts[i] >= recipe.requiredAmounts[i], "Insufficient resource provided");
            IERC20 resourceToken = recipe.requiredResources[i];
            uint256 requiredAmount = recipe.requiredAmounts[i];
            // Note: User needs to approve this contract to spend the tokens *before* calling this function
            resourceToken.safeTransferFrom(msg.sender, address(this), requiredAmount);

            // Handle potential surplus returned to user or kept by contract?
            // For simplicity, user provides *exactly* required amount or more (but only required is taken).
            // If more is provided, the surplus stays with the user.
        }

        uint256 calculatedDuration = recipe.duration;
        if (_catalystId != 0) {
            Catalyst storage catalyst = catalysts[_catalystId];
            // Apply catalyst effect (e.g., reduce duration)
            // Assuming multiplier is applied such that 10000 is no change, <10000 is faster
            // Example: duration = duration * multiplier / 10000
            calculatedDuration = (recipe.duration * catalyst.durationMultiplier) / 10000;
             require(calculatedDuration > 0, "Calculated duration must be positive"); // Prevent infinite crafts
        }

        _projectIdCounter.increment();
        uint256 newProjectId = _projectIdCounter.current();
        uint256 endTime = block.timestamp + calculatedDuration;

        projects[newProjectId] = CraftingProject({
            id: newProjectId,
            owner: msg.sender,
            recipeId: _recipeId,
            catalystId: _catalystId,
            startTime: block.timestamp,
            endTime: endTime,
            status: ProjectStatus.Ongoing
        });

        userProjectIds[msg.sender].push(newProjectId);

        emit ProjectStarted(newProjectId, msg.sender, _recipeId, _catalystId, endTime);
    }

    // 9. claimCraftedItem
    function claimCraftedItem(uint256 _projectId) external nonReentrant whenNotPaused onlyProjectOwner(_projectId) {
        CraftingProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.Ongoing, "Project is not ongoing");
        require(block.timestamp >= project.endTime, "Project not yet completed");

        project.status = ProjectStatus.Completed; // Mark as completed before minting (state-first)

        // --- NFT Minting Logic ---
        // This part needs to interact with the actual ERC721 contract (resourceNFT)
        // The token ID needs to be determined. Could be sequential, or based on project ID. Let's use project ID for uniqueness.
        uint256 newTokenId = _projectId; // Using project ID as token ID for simplicity

        // Determine tokenURI and other potential properties based on recipe and project data
        Recipe storage recipe = recipes[project.recipeId];
        // Example: Combine base metadata with project-specific data or properties data
        bytes memory nftMetadata = abi.encodePacked(recipe.nftMetadataBase, "/", Strings.toString(newTokenId));
        // Note: Real-world tokenURIs typically point to JSON files (e.g., ipfs://.../token_id.json)

        // Assuming resourceNFT is an ERC721 contract with a mint function callable by ChronoCrafter
        IERC721(resourceNFT).safeMint(project.owner, newTokenId); // Assumes ERC721 has safeMint

        // Set tokenURI (requires the ERC721 contract to have a function like setTokenURI or handle it internally during mint)
        // This contract doesn't implement ERC721, so we assume the target NFT contract handles metadata based on token ID
        // or has a function like setTokenMetadata(tokenId, metadata). For this example, we'll skip calling setTokenMetadata
        // directly and assume the ERC721 contract knows how to generate it based on ID and possibly querying this contract.

        project.status = ProjectStatus.Claimed; // Mark as claimed after successful mint
        emit ItemClaimed(_projectId, msg.sender, newTokenId);
    }

     // Function stub assuming the target ERC721 has a way to get URI data
     // This could be integrated into the ERC721 contract itself based on project data
     // function getTokenURI(uint256 _tokenId) public view returns (string memory) {
     //     // Logic to construct URI based on _tokenId (which is project ID here)
     //     // and potentially querying project/recipe data from this contract.
     //     CraftingProject storage project = projects[_tokenId]; // Assuming tokenId is projectId
     //     Recipe storage recipe = recipes[project.recipeId];
     //     bytes memory baseURI = recipe.nftMetadataBase;
     //     // Further logic to combine baseURI, properties, etc.
     //     return string(abi.encodePacked("ipfs://", baseURI, "/", Strings.toString(_tokenId), ".json"));
     // }


    // 10. cancelCrafting
    function cancelCrafting(uint256 _projectId) external nonReentrant whenNotPaused onlyProjectOwner(_projectId) {
        CraftingProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.Ongoing, "Project is not ongoing");
        require(block.timestamp < project.endTime, "Project is already completed");

        project.status = ProjectStatus.Cancelled;

        // --- Resource Refund Logic ---
        // Refund logic is complex: partial based on time elapsed? No refund?
        // For simplicity in this example, let's say no refund on cancellation.
        // If refund were implemented, need to track resources per project or store them differently.

        emit ProjectCancelled(_projectId, msg.sender);
    }

    // 11. getProjectDetails
    function getProjectDetails(uint256 _projectId) external view returns (
        uint256 id,
        address owner,
        uint256 recipeId,
        uint256 catalystId,
        uint256 startTime,
        uint256 endTime,
        ProjectStatus status,
        bool isCompleted // Helper flag
    ) {
        require(_projectId > 0 && _projectId <= _projectIdCounter.current(), "Invalid project ID");
        CraftingProject storage p = projects[_projectId];
        return (
            p.id,
            p.owner,
            p.recipeId,
            p.catalystId,
            p.startTime,
            p.endTime,
            p.status,
            p.status == ProjectStatus.Ongoing && block.timestamp >= p.endTime // Check completion status for ongoing projects
        );
    }

    // 12. getUserProjects
    function getUserProjects(address _user) external view returns (uint256[] memory) {
        return userProjectIds[_user];
    }


    // --- Resource Management ---

    // 13. depositResource (Users can deposit tokens into the contract for future use)
    function depositResource(IERC20 _token, uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        // User needs to approve this contract to spend the tokens *before* calling this function
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        // No event or specific tracking per user for general deposit, resources are pooled.
        // Resource tracking per user is only relevant *within* projects/vaults.
    }

    // 14. withdrawResource (Admin function to pull out funds if needed, e.g., for upgrades, redistribution)
    function withdrawResource(IERC20 _token, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        _token.safeTransfer(msg.sender, _amount);
    }

    // --- Timed & Conditional Vaults ---

    // 15. defineTimedVaultType
    function defineTimedVaultType(
        string calldata _name,
        IERC20 _resourceToken,
        uint256 _baseLockDuration,
        VaultConditionType _conditionType
    ) external onlyOwner nonReentrant whenNotPaused {
        require(address(_resourceToken) != address(0), "Invalid token address");
        require(_baseLockDuration > 0, "Lock duration must be positive");
        if (_conditionType == VaultConditionType.OracleBased) {
             require(conditionOracle != address(0), "Oracle address not set for OracleBased condition");
        }

        _vaultTypeIdCounter.increment();
        uint256 newVaultTypeId = _vaultTypeIdCounter.current();

        vaultTypes[newVaultTypeId] = TimedVaultType({
            isActive: true,
            name: _name,
            resourceToken: _resourceToken,
            baseLockDuration: _baseLockDuration,
            conditionType: _conditionType
        });

        emit VaultTypeDefined(newVaultTypeId, _name, true);
    }

    // 16. setVaultTypeActiveStatus
     function setVaultTypeActiveStatus(uint256 _vaultTypeId, bool _isActive) external onlyOwner nonReentrant {
         require(_vaultTypeId > 0 && _vaultTypeId <= _vaultTypeIdCounter.current(), "Invalid vault type ID");
         vaultTypes[_vaultTypeId].isActive = _isActive;
         emit VaultTypeDefined(_vaultTypeId, vaultTypes[_vaultTypeId].name, _isActive); // Re-emit with status change
     }


    // 17. depositIntoTimedVault
    function depositIntoTimedVault(
        uint256 _vaultTypeId,
        uint256 _amount,
        bytes calldata _conditionData // Data specific to the condition (e.g., oracle query)
    ) external nonReentrant whenNotPaused onlyVaultTypeActive(_vaultTypeId) {
        require(_amount > 0, "Amount must be greater than zero");
        TimedVaultType storage vaultType = vaultTypes[_vaultTypeId];

        // Transfer resources from user to contract
        vaultType.resourceToken.safeTransferFrom(msg.sender, address(this), _amount);
        // User needs to approve the vaultType.resourceToken for this contract beforehand.

        // Calculate unlock time
        uint256 unlockTime = block.timestamp + vaultType.baseLockDuration;

        // Check condition data compatibility with type (basic check)
        if (vaultType.conditionType == VaultConditionType.OracleBased) {
            require(_conditionData.length > 0, "Condition data required for OracleBased vault");
            require(conditionOracle != address(0), "Oracle address not set for OracleBased condition");
            // Further validation of conditionData format could be added
        } else {
             // For None type, conditionData must be empty
            require(_conditionData.length == 0, "Condition data not allowed for this vault type");
        }


        _vaultEntryIdCounter.increment();
        uint256 newVaultEntryId = _vaultEntryIdCounter.current();

        vaultEntries[newVaultEntryId] = UserVaultEntry({
            id: newVaultEntryId,
            owner: msg.sender,
            vaultTypeId: _vaultTypeId,
            amount: _amount,
            depositTime: block.timestamp,
            unlockTime: unlockTime, // This is the time component of the unlock
            status: VaultEntryStatus.Locked,
            conditionData: _conditionData // Store the specific condition parameters
        });

        userVaultEntryIds[msg.sender].push(newVaultEntryId);

        emit VaultDeposited(newVaultEntryId, msg.sender, _vaultTypeId, _amount, unlockTime);
    }

    // 18. claimFromTimedVault
    function claimFromTimedVault(uint256 _vaultEntryId) external nonReentrant whenNotPaused onlyVaultEntryOwner(_vaultEntryId) {
        UserVaultEntry storage vaultEntry = vaultEntries[_vaultEntryId];
        require(vaultEntry.status == VaultEntryStatus.Locked || vaultEntry.status == VaultEntryStatus.Unlockable, "Vault entry not locked or unlockable");

        // Check time condition
        require(block.timestamp >= vaultEntry.unlockTime, "Vault entry is still time-locked");

        // Check additional condition if required
        TimedVaultType storage vaultType = vaultTypes[vaultEntry.vaultTypeId];
        if (vaultType.conditionType == VaultConditionType.OracleBased) {
            require(conditionOracle != address(0), "Oracle address not set for OracleBased condition");
             // Call the oracle to check the specific condition data
             bool conditionMet = IConditionOracle(conditionOracle).checkCondition(vaultEntry.conditionData);
             require(conditionMet, "Oracle condition not met");
        }
        // Note: If other condition types were added (e.g., minBlockNumber), they would be checked here.

        // If time and condition are met, transfer funds
        vaultEntry.status = VaultEntryStatus.Claimed; // State-first
        vaultType.resourceToken.safeTransfer(msg.sender, vaultEntry.amount);

        emit VaultClaimed(_vaultEntryId, msg.sender, vaultEntry.amount);
    }

    // 19. getVaultTypeDetails
    function getVaultTypeDetails(uint256 _vaultTypeId) external view returns (
        uint256 vaultTypeId,
        bool isActive,
        string memory name,
        address resourceTokenAddress,
        uint256 baseLockDuration,
        VaultConditionType conditionType
    ) {
         require(_vaultTypeId > 0 && _vaultTypeId <= _vaultTypeIdCounter.current(), "Invalid vault type ID");
         TimedVaultType storage vt = vaultTypes[_vaultTypeId];
         return (
             _vaultTypeId,
             vt.isActive,
             vt.name,
             address(vt.resourceToken),
             vt.baseLockDuration,
             vt.conditionType
         );
    }

    // 20. getUserVaultEntries
    function getUserVaultEntries(address _user) external view returns (uint256[] memory) {
        return userVaultEntryIds[_user];
    }

    // 21. getVaultEntryDetails
    function getVaultEntryDetails(uint256 _vaultEntryId) external view returns (
        uint256 id,
        address owner,
        uint256 vaultTypeId,
        uint256 amount,
        uint256 depositTime,
        uint256 unlockTime,
        VaultEntryStatus status,
        bytes memory conditionData
    ) {
        require(_vaultEntryId > 0 && _vaultEntryId <= _vaultEntryIdCounter.current(), "Invalid vault entry ID");
        UserVaultEntry storage entry = vaultEntries[_vaultEntryId];
        return (
            entry.id,
            entry.owner,
            entry.vaultTypeId,
            entry.amount,
            entry.depositTime,
            entry.unlockTime,
            entry.status,
            entry.conditionData
        );
    }

    // 22. checkVaultUnlockStatus
    function checkVaultUnlockStatus(uint256 _vaultEntryId) public view returns (bool timeMet, bool conditionMet, bool isUnlockable) {
         require(_vaultEntryId > 0 && _vaultEntryId <= _vaultEntryIdCounter.current(), "Invalid vault entry ID");
         UserVaultEntry storage vaultEntry = vaultEntries[_vaultEntryId];

         timeMet = block.timestamp >= vaultEntry.unlockTime;
         conditionMet = true; // Assume true unless oracle condition applies

         TimedVaultType storage vaultType = vaultTypes[vaultEntry.vaultTypeId];

         if (vaultType.conditionType == VaultConditionType.OracleBased) {
             if (conditionOracle == address(0)) {
                 conditionMet = false; // Cannot check condition if oracle is not set
             } else {
                // Call the oracle view function
                conditionMet = IConditionOracle(conditionOracle).checkCondition(vaultEntry.conditionData);
             }
         }
         // Add checks for other condition types if implemented

         isUnlockable = timeMet && conditionMet && (vaultEntry.status == VaultEntryStatus.Locked || vaultEntry.status == VaultEntryStatus.Unlockable);

         return (timeMet, conditionMet, isUnlockable);
    }

    // --- Oracle Integration ---

    // 23. setConditionOracle
    function setConditionOracle(address _oracleAddress) external onlyOwner nonReentrant {
         require(_oracleAddress != address(0), "Oracle address cannot be zero");
         conditionOracle = _oracleAddress;
         emit ConditionOracleSet(_oracleAddress);
    }

    // --- NFT Interaction ---
    // ERC721 logic (minting) is handled internally in claimCraftedItem
    // Assuming resourceNFT contract has `safeMint(address to, uint256 tokenId)` and is set correctly.
    // The ChronoCrafter contract needs permissions to mint on the resourceNFT contract.

    // --- Admin/Utility ---

    // 24. pauseContract
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    // 25. unpauseContract
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    // 26. setFeeRecipient
    function setFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Recipient cannot be zero address");
        feeRecipient = _recipient;
        // No event for this, but could add one.
    }

    // 27. emergencyVaultWithdraw (Admin override - use with extreme caution!)
    function emergencyVaultWithdraw(uint256 _vaultEntryId) external onlyOwner nonReentrant {
         require(_vaultEntryId > 0 && _vaultEntryId <= _vaultEntryIdCounter.current(), "Invalid vault entry ID");
         UserVaultEntry storage vaultEntry = vaultEntries[_vaultEntryId];
         require(vaultEntry.status != VaultEntryStatus.Claimed, "Vault entry already claimed");

         vaultEntry.status = VaultEntryStatus.Claimed; // Mark as claimed
         TimedVaultType storage vaultType = vaultTypes[vaultEntry.vaultTypeId];

         // Bypass time and condition checks!
         vaultType.resourceToken.safeTransfer(vaultEntry.owner, vaultEntry.amount);

         // Note: No event emitted for this special admin withdrawal,
         // to differentiate it from a regular claim. Could add a dedicated event.
    }


    // --- Query Functions ---
    // Functions like getRecipeDetails, getCatalystDetails, getProjectDetails, getUserProjects,
    // getVaultTypeDetails, getUserVaultEntries, getVaultEntryDetails, checkVaultUnlockStatus
    // serve as query functions and are listed above.

    // Public getters for state variables
    function getResourceNFTAddress() external view returns (address) {
        return resourceNFT;
    }

     function getConditionOracleAddress() external view returns (address) {
        return conditionOracle;
    }

    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    function getCurrentRecipeId() external view returns (uint256) {
        return _recipeIdCounter.current();
    }

    function getCurrentCatalystId() external view returns (uint256) {
        return _catalystIdCounter.current();
    }

    function getCurrentProjectId() external view returns (uint256) {
        return _projectIdCounter.current();
    }

    function getCurrentVaultTypeId() external view returns (uint256) {
        return _vaultTypeIdCounter.current();
    }

    function getCurrentVaultEntryId() external view returns (uint256) {
        return _vaultEntryIdCounter.current();
    }

    // Fallback/Receive functions (optional)
    // receive() external payable {} // Allows receiving Ether
    // fallback() external payable {} // Allows receiving Ether and handling arbitrary calls

}
```

---

**Explanation of Advanced Concepts & Creativity:**

1.  **Time-Based Mechanics:** Crafting projects and vault entries are explicitly time-locked (`duration`, `baseLockDuration`, `startTime`, `endTime`, `unlockTime`). This is a core mechanic governing access and completion.
2.  **Resource Management:** Users supply specific ERC-20 tokens (`requiredResources`, `requiredAmounts`) to initiate processes. The contract manages custody of these tokens until the process is complete or cancelled.
3.  **NFT Crafting:** A clear process (`startCrafting`, `claimCraftedItem`) exists to consume fungible resources over time and produce a unique, non-fungible asset (NFT). The NFT's properties can conceptually be linked to the recipe, catalyst, and project timing.
4.  **Catalysts:** Introduces an optional input (`Catalyst` struct, `applyCatalystToProject`) that modifies the crafting process (specifically duration in this example), adding strategic depth. This can be extended to influence NFT properties or resource costs.
5.  **Conditional Timelocks (Vaults):** Vaults combine a time lock with an *additional condition* (`VaultConditionType`). This allows for flexible release criteria beyond just a fixed time.
6.  **Oracle Integration:** The `OracleBased` vault condition relies on an external `IConditionOracle` contract. This demonstrates how a smart contract can interact with external data (or proofs derived from external data) to gate functionality. The `checkCondition` function allows for arbitrary logic off-chain, verified by the oracle contract on-chain using the `conditionData`.
7.  **Structs and Mappings:** Extensive use of structs (`Recipe`, `Catalyst`, `CraftingProject`, `TimedVaultType`, `UserVaultEntry`) and mappings to organize complex, related data for multiple users and items.
8.  **Enumerations:** Use of enums (`ProjectStatus`, `VaultConditionType`, `VaultEntryStatus`) makes the contract state clearer and safer than using raw integers.
9.  **Separation of Concerns (Interfaces):** The contract relies on `IERC20`, `IERC721`, and `IConditionOracle` interfaces. This means the ChronoCrafter contract is *not* implementing these standards itself but *interacting* with external contracts that do, promoting modularity. The `resourceNFT` contract must be deployed separately and grant minting rights to the ChronoCrafter contract. The `IConditionOracle` must implement the specified view function.
10. **Access Control & Pausability:** Standard `Ownable` and `Pausable` patterns are included for basic administrative control and emergency stop functionality.
11. **Reentrancy Guard:** Used on sensitive functions (`claimCraftedItem`, `claimFromTimedVault`, transfers) to prevent reentrancy attacks.
12. **SafeERC20:** Used for ERC-20 interactions to handle varying return types and prevent issues with non-compliant tokens.
13. **Counters:** Used for ID generation to ensure unique, non-repeating identifiers for recipes, projects, vaults, etc.
14. **Detailed State Querying:** Numerous view functions (`getRecipeDetails`, `getProjectDetails`, `getUserVaults`, `checkVaultUnlockStatus`, etc.) provide comprehensive ways for users and interfaces to inspect the state of recipes, projects, and vaults.
15. **User-Specific Data Structures:** Mappings like `userProjectIds` and `userVaultEntryIds` store arrays of IDs per user, simplifying the process of fetching a user's active items.
16. **Configuration:** Admin functions (`setRecipeActiveStatus`, `setCatalystActiveStatus`, `setVaultTypeActiveStatus`, `setConditionOracle`, `setFeeRecipient`) allow the owner to configure the contract's parameters after deployment.
17. **Data Encoding/Decoding (Bytes):** Using `bytes` (`nftMetadataBase`, `nftPropertiesData`, `conditionData`) allows for flexible storage of data whose interpretation is handled off-chain or by other specialized contracts (like the Oracle or the NFT metadata service).
18. **Update Functions:** Including `updateRecipe` shows a potential approach to contract evolution, though it highlights the complexity of changing parameters for ongoing processes.
19. **Emergency Measures:** `emergencyVaultWithdraw` is included as an admin override, demonstrating how to add escape hatches for critical situations, while also highlighting the security implications.
20. **Clear Events:** Events are emitted for key actions, providing a history and allowing off-chain applications to track contract activity.

This contract architecture goes beyond basic token or simple interaction patterns by combining time-based state changes, resource consumption, NFT issuance, and external data dependencies through an oracle for complex conditionality.