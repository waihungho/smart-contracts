Okay, let's design a smart contract that acts as a **Generative Art NFT Factory with Dynamic Parameters and Epochs**.

This contract allows creators to define generative art *projects*, each with a set of parameters. Users can then mint NFTs from these projects. The unique aspect is that these NFTs store their specific parameter values on-chain, which can potentially be mutated, and the factory owner or project creator can trigger "epochs" that change the parameter ranges for *future* mints from a project. It also incorporates randomness abstraction and royalty splitting.

This concept is interesting because:
*   It ties on-chain data (parameters) to off-chain rendering/metadata.
*   NFTs can be dynamic (parameters can change via mutation).
*   Projects can evolve over time (epochs).
*   It abstracts randomness, showing how on-chain processes can depend on external data.
*   It includes structured project management and royalty distribution.

It aims to be advanced by using custom errors, potentially interacting with oracle-like randomness sources (abstracted here), managing complex state related to projects and individual NFTs, and implementing parameter mutation/evolution logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol"; // For royalties

// --- Outline ---
// 1. Contract Overview: A factory for creating and managing generative art NFT projects.
// 2. Project Management: Functions for creating, configuring, pausing, and updating projects by creators.
// 3. Parameter Management: Defining, updating, and removing generative parameters for projects.
// 4. NFT Minting: Allowing users to mint NFTs from available projects, incorporating randomness and fee distribution.
// 5. NFT Dynamics: Functions for viewing and potentially mutating NFT parameters.
// 6. Project Evolution (Epochs): A mechanism to change parameter ranges for future mints, defining new project epochs.
// 7. Royalties & Fees: Handling royalty distribution for creators and fees for the factory.
// 8. Access Control: Managing project creators, factory owner, and specific roles like parameter modifiers.
// 9. ERC721 & ERC2981 Standards: Core NFT functionality and royalty standard implementation.
// 10. Randomness Abstraction: Modeling interaction with an external randomness source.

// --- Function Summary ---
// Factory Management:
// - createProject(ProjectConfig memory config): Allows anyone (initially, could be restricted) to propose/create a new generative art project.
// - setProjectVisibility(uint256 projectId, bool isPublic): Sets if a project is publicly mintable.
// - pauseProjectMinting(uint256 projectId): Pauses minting for a specific project (only creator).
// - unpauseProjectMinting(uint256 projectId): Unpauses minting for a specific project (only creator).
// - updateFactoryFeeRecipient(address newRecipient): Sets the address receiving factory fees (only factory owner).
// - updateProjectCreatorFeeBasisPoints(uint256 projectId, uint96 feeBasisPoints): Sets the creator royalty percentage for a project (only creator).
// - setDefaultRoyalty(uint96 feeBasisPoints, address recipient): Sets a default royalty for the factory (applied if project doesn't override).
// - withdrawFactoryFees(): Allows the factory fee recipient to withdraw accumulated fees.
// - withdrawProjectRoyalties(uint256 projectId): Allows the project creator to withdraw their accumulated royalties.
// - transferProjectOwnership(uint256 projectId, address newCreator): Transfers project management rights (only current creator).

// Project Configuration (by Creator):
// - setProjectBaseURI(uint256 projectId, string memory newBaseURI): Sets the base URI for NFT metadata (points to renderer/metadata server).
// - addGenerativeParameter(uint256 projectId, string memory name, uint256 min, uint256 max): Defines a new parameter with a range for a project.
// - updateGenerativeParameterRange(uint256 projectId, string memory name, uint256 newMin, uint256 newMax): Updates the range of an existing parameter.
// - removeGenerativeParameter(uint256 projectId, string memory name): Removes a parameter from a project (careful, affects metadata).
// - setMintPrice(uint256 projectId, uint256 price): Sets the price to mint an NFT from a project.
// - setMintLimit(uint256 projectId, uint256 limit): Sets the maximum number of NFTs that can be minted per wallet for a project.

// NFT Minting:
// - mintNFT(uint256 projectId, address recipient): Mints a new NFT from a specific project for a recipient, paying the mint price and triggering parameter generation.
// - requestRandomnessForNFT(uint256 projectId, uint256 tokenId): (Internal/Helper) Requests randomness needed for parameter generation from an oracle. Modeled here for abstraction.
// - fulfillRandomness(bytes32 requestId, uint256 randomness): (External/Callback) Receives randomness from the oracle and finalizes NFT parameters. Modeled here for abstraction.

// NFT Dynamics & Viewing:
// - getNFTGenerativeParameters(uint256 tokenId): Retrieves the current generative parameters stored for an NFT.
// - mutateNFTParameters(uint256 tokenId, ParameterUpdate[] memory updates): Allows the NFT owner (or authorized address) to change some of the NFT's parameters within defined constraints.
// - lockParametersForNFT(uint256 tokenId): Prevents further mutations on a specific NFT's parameters.
// - getNFTMutationCount(uint256 tokenId): Returns how many times an NFT's parameters have been mutated.
// - tokenURI(uint256 tokenId): Returns the metadata URI for an NFT, incorporating project base URI and NFT parameters.

// Project Evolution (Epochs):
// - triggerParameterEpochUpdate(uint256 projectId, string memory parameterName, uint256 newMin, uint256 newMax): Changes the allowed range for a parameter for *future* mints in a project, potentially starting a new 'epoch' of art outputs (only creator or factory owner).
// - getProjectEpoch(uint256 projectId): Returns the current 'epoch' count (number of epoch updates) for a project.

// Access Control:
// - grantParameterModifierRole(address account, uint256 projectId): Grants an address permission to mutate parameters for NFTs within a specific project.
// - revokeParameterModifierRole(address account, uint256 projectId): Revokes the parameter modifier role.
// - hasParameterModifierRole(address account, uint256 projectId): Checks if an address has the parameter modifier role.

// Getters & Standard ERC721/ERC2981:
// - name(): ERC721 standard.
// - symbol(): ERC721 standard.
// - balanceOf(address owner): ERC721 standard.
// - ownerOf(uint256 tokenId): ERC721 standard.
// - safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// - transferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// - approve(address to, uint256 tokenId): ERC721 standard.
// - getApproved(uint256 tokenId): ERC721 standard.
// - setApprovalForAll(address operator, bool approved): ERC721 standard.
// - isApprovedForAll(address owner, address operator): ERC721 standard.
// - supportsInterface(bytes4 interfaceId): ERC165/ERC721/ERC2981 standard.
// - royaltyInfo(uint256 tokenId, uint256 salePrice): ERC2981 standard, calculates royalties based on project config.
// - getProjectDetails(uint256 projectId): Retrieves configuration details for a project.
// - getTotalProjects(): Returns the total number of projects created.
// - getProjectsByCreator(address creator): Returns a list of project IDs created by an address.
// - getNFTProjectID(uint256 tokenId): Returns the project ID an NFT belongs to.
// - getTotalMintedByProject(uint256 projectId): Returns the total NFTs minted from a project.
// - getMintCountForWallet(uint256 projectId, address wallet): Returns the number of NFTs minted by a wallet for a project.
// - isParametersLocked(uint256 tokenId): Checks if an NFT's parameters are locked against mutation.
// - getProjectParameters(uint256 projectId): Retrieves the list of parameters defined for a project.
// - getPendingRandomRequest(bytes32 requestId): Gets the project ID and token ID associated with a randomness request. (Abstraction helper)


contract GenerativeArtNFTFactory is ERC721Enumerable, ERC721Pausable, ERC2981, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    // --- Custom Errors ---
    error ProjectNotFound(uint256 projectId);
    error ProjectNotMintable(uint256 projectId);
    error MintLimitReached(uint256 projectId, address wallet);
    error InvalidParameter(string parameterName);
    error InvalidParameterValue(string parameterName, uint256 value);
    error ParametersLocked(uint256 tokenId);
    error NotProjectCreator(uint256 projectId);
    error NotNFTOwnerOrApproved(uint256 tokenId);
    error ParameterNotInProject(uint256 projectId, string parameterName);
    error InvalidParameterUpdate(uint256 tokenId, string parameterName);
    error MintPriceNotMet(uint256 required, uint256 sent);
    error NoFeesToWithdraw();
    error RandomnessNotFulfilled(uint256 tokenId);
    error RandomnessAlreadyFulfilled(uint256 tokenId);
    error RandomnessPending(uint256 tokenId);

    // --- Events ---
    event ProjectCreated(uint256 indexed projectId, string name, address indexed creator, uint256 factoryFeeBasisPoints, uint256 creatorFeeBasisPoints);
    event ProjectVisibilityUpdated(uint256 indexed projectId, bool isPublic);
    event ProjectMintingPaused(uint256 indexed projectId);
    event ProjectMintingUnpaused(uint256 indexed projectId);
    event FactoryFeeRecipientUpdated(address indexed newRecipient);
    event ProjectCreatorFeeBasisPointsUpdated(uint256 indexed projectId, uint96 feeBasisPoints);
    event DefaultRoyaltyUpdated(uint96 feeBasisPoints, address indexed recipient);
    event FactoryFeesWithdrawn(address indexed recipient, uint256 amount);
    event ProjectRoyaltiesWithdrawn(uint256 indexed projectId, address indexed creator, uint256 amount);
    event ProjectOwnershipTransferred(uint256 indexed projectId, address indexed oldCreator, address indexed newCreator);
    event ProjectBaseURIUpdated(uint256 indexed projectId, string newBaseURI);
    event GenerativeParameterAdded(uint256 indexed projectId, string name, uint256 min, uint256 max);
    event GenerativeParameterUpdated(uint256 indexed projectId, string name, uint256 newMin, uint256 newMax);
    event GenerativeParameterRemoved(uint256 indexed projectId, string name);
    event MintPriceUpdated(uint256 indexed projectId, uint256 price);
    event MintLimitUpdated(uint256 indexed projectId, uint256 limit);
    event NFTMinted(uint256 indexed projectId, uint256 indexed tokenId, address indexed recipient);
    event NFTParametersSet(uint256 indexed tokenId, bytes parametersData); // Emitted when randomness fulfilled
    event NFTParametersMutated(uint256 indexed tokenId, bytes oldParametersData, bytes newParametersData, address indexed mutator);
    event ParametersLocked(uint256 indexed tokenId);
    event ParameterEpochUpdated(uint256 indexed projectId, string parameterName, uint256 newMin, uint256 newMax, uint256 newEpoch);
    event ParameterModifierRoleGranted(address indexed account, uint256 indexed projectId, address indexed grantor);
    event ParameterModifierRoleRevoked(address indexed account, uint256 indexed projectId, address indexed revoker);
    event RandomnessRequested(bytes32 indexed requestId, uint256 indexed projectId, uint256 indexed tokenId); // Abstraction event

    // --- Structs ---
    struct ProjectConfig {
        string name;
        address creator; // Address responsible for this project
        string baseURI; // Base URI for tokenURI (points to renderer/metadata)
        uint256 mintPrice;
        uint256 mintLimitPerWallet; // 0 for unlimited
        bool isPublic; // Can anyone mint?
        bool isMintingPaused;
        uint96 creatorFeeBasisPoints; // Royalties percentage for creator (in basis points, 10000 = 100%)
        uint256 epoch; // Counter for parameter epoch updates
        mapping(string => GenerativeParameter) parameters;
        string[] parameterNames; // Maintain order and list of parameter names
        uint256 totalMinted;
        mapping(address => uint256) mintedByWallet;
    }

    struct GenerativeParameter {
        uint256 min;
        uint256 max;
        bool exists; // To check if parameter exists in mapping
    }

    struct NFTGenerativeParameters {
        mapping(string => uint256) values;
        bool areSet; // True after randomness is fulfilled
        bool isLocked; // True if parameters cannot be mutated
        uint256 mutationCount;
        bytes32 randomnessRequestId; // ID of the request used to set initial parameters
    }

    struct ParameterUpdate {
        string name;
        uint256 value;
    }

    // --- State Variables ---
    Counters.Counter private _projectIds;
    mapping(uint256 => ProjectConfig) public projects;
    mapping(uint256 => NFTGenerativeParameters) private _nftParameters; // tokenId => parameters
    mapping(address => uint256[]) private _projectsByCreator; // Creator address => list of project IDs

    uint96 public factoryFeeBasisPoints; // Fee for the factory owner (in basis points)
    address public factoryFeeRecipient;
    uint96 public defaultRoyaltyBasisPoints; // Default royalty if project doesn't set one
    address public defaultRoyaltyRecipient;

    mapping(address => mapping(uint256 => bool)) private _parameterModifierRoles; // account => projectId => hasRole

    mapping(bytes32 => uint256) private _randomnessRequestIdToProjectId; // Randomness request ID => project ID
    mapping(bytes32 => uint256) private _randomnessRequestIdToTokenId; // Randomness request ID => token ID
    mapping(uint256 => bytes32) private _tokenIdToRandomnessRequestId; // Token ID => randomness request ID

    // --- Constructor ---
    constructor(
        string memory name_,
        string memory symbol_,
        uint96 initialFactoryFeeBasisPoints,
        address initialFactoryFeeRecipient,
        uint96 initialDefaultRoyaltyBasisPoints,
        address initialDefaultRoyaltyRecipient
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        require(initialFactoryFeeRecipient != address(0), "Invalid fee recipient");
        require(initialDefaultRoyaltyRecipient != address(0), "Invalid default royalty recipient");

        factoryFeeBasisPoints = initialFactoryFeeBasisPoints;
        factoryFeeRecipient = initialFactoryFeeRecipient;
        defaultRoyaltyBasisPoints = initialDefaultRoyaltyBasisPoints;
        defaultRoyaltyRecipient = initialDefaultRoyaltyRecipient;

        _setDefaultRoyalty(initialDefaultRoyaltyRecipient, initialDefaultRoyaltyBasisPoints);
    }

    // --- Modifiers ---
    modifier onlyProjectCreator(uint256 projectId) {
        if (projects[projectId].creator != msg.sender) {
            revert NotProjectCreator(projectId);
        }
        _;
    }

    modifier onlyNFTOwnerOrApproved(uint256 tokenId) {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotNFTOwnerOrApproved(tokenId);
        }
        _;
    }

    modifier onlyParameterModifier(uint256 projectId) {
        if (!_parameterModifierRoles[msg.sender][projectId] && projects[projectId].creator != msg.sender && owner() != msg.sender) {
            // Allow factory owner and project creator as default modifiers
            revert("Not parameter modifier, creator, or owner");
        }
        _;
    }

    // --- Factory Management ---

    /**
     * @notice Creates a new generative art project.
     * @param config The configuration details for the new project.
     */
    function createProject(ProjectConfig memory config) external { // Could add restriction like only factory owner or require a fee
        _projectIds.increment();
        uint256 projectId = _projectIds.current();

        require(bytes(config.name).length > 0, "Project name cannot be empty");
        require(config.creator != address(0), "Project creator cannot be zero address");

        // Initialize the project struct in storage
        ProjectConfig storage newProject = projects[projectId];
        newProject.name = config.name;
        newProject.creator = config.creator;
        newProject.baseURI = config.baseURI;
        newProject.mintPrice = config.mintPrice;
        newProject.mintLimitPerWallet = config.mintLimitPerWallet;
        newProject.isPublic = config.isPublic;
        newProject.isMintingPaused = config.isMintingPaused;
        newProject.creatorFeeBasisPoints = config.creatorFeeBasisPoints; // Use passed value, or set default later
        newProject.epoch = 0; // Start at epoch 0
        // Mappings and dynamic arrays within the struct are initialized empty by default

        _projectsByCreator[config.creator].push(projectId);

        emit ProjectCreated(projectId, config.name, config.creator, factoryFeeBasisPoints, config.creatorFeeBasisPoints);
    }

    /**
     * @notice Sets the public visibility of a project.
     * @param projectId The ID of the project.
     * @param isPublic True to make the project publicly mintable, false otherwise.
     */
    function setProjectVisibility(uint256 projectId, bool isPublic) external onlyProjectCreator(projectId) {
        ProjectConfig storage project = projects[projectId];
        project.isPublic = isPublic;
        emit ProjectVisibilityUpdated(projectId, isPublic);
    }

    /**
     * @notice Pauses minting for a specific project.
     * @param projectId The ID of the project.
     */
    function pauseProjectMinting(uint256 projectId) external onlyProjectCreator(projectId) {
        projects[projectId].isMintingPaused = true;
        emit ProjectMintingPaused(projectId);
    }

    /**
     * @notice Unpauses minting for a specific project.
     * @param projectId The ID of the project.
     */
    function unpauseProjectMinting(uint256 projectId) external onlyProjectCreator(projectId) {
        projects[projectId].isMintingPaused = false;
        emit ProjectMintingUnpaused(projectId);
    }

    /**
     * @notice Updates the address receiving factory fees.
     * @param newRecipient The new address.
     */
    function updateFactoryFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid recipient");
        factoryFeeRecipient = newRecipient;
        emit FactoryFeeRecipientUpdated(newRecipient);
    }

    /**
     * @notice Updates the creator royalty percentage for a project.
     * @param projectId The ID of the project.
     * @param feeBasisPoints The new royalty percentage in basis points (0-10000).
     */
    function updateProjectCreatorFeeBasisPoints(uint256 projectId, uint96 feeBasisPoints) external onlyProjectCreator(projectId) {
        require(feeBasisPoints <= 10000, "Fee basis points exceeds 100%");
        projects[projectId].creatorFeeBasisPoints = feeBasisPoints;
        emit ProjectCreatorFeeBasisPointsUpdated(projectId, feeBasisPoints);
    }

    /**
     * @notice Sets the default royalty information for the factory.
     * This applies to projects that don't override it.
     * @param feeBasisPoints The new default royalty percentage in basis points (0-10000).
     * @param recipient The new default royalty recipient address.
     */
    function setDefaultRoyalty(uint96 feeBasisPoints, address recipient) external onlyOwner {
        require(feeBasisPoints <= 10000, "Fee basis points exceeds 100%");
        require(recipient != address(0), "Invalid recipient");
        defaultRoyaltyBasisPoints = feeBasisPoints;
        defaultRoyaltyRecipient = recipient;
        _setDefaultRoyalty(recipient, feeBasisPoints); // Update ERC2981 default
        emit DefaultRoyaltyUpdated(feeBasisPoints, recipient);
    }


    /**
     * @notice Allows the factory fee recipient to withdraw accumulated fees.
     */
    function withdrawFactoryFees() external nonReentrant {
        address recipient = factoryFeeRecipient;
        uint256 balance = address(this).balance;
        uint256 factoryShare = (balance * factoryFeeBasisPoints) / 10000;

        if (factoryShare == 0) {
            revert NoFeesToWithdraw();
        }

        (bool success, ) = payable(recipient).call{value: factoryShare}("");
        require(success, "Withdrawal failed");

        emit FactoryFeesWithdrawn(recipient, factoryShare);
    }

    /**
     * @notice Allows the project creator to withdraw their accumulated royalties/fees from minting.
     * @param projectId The ID of the project.
     */
    function withdrawProjectRoyalties(uint256 projectId) external onlyProjectCreator(projectId) nonReentrant {
        // Calculate creator share from contract's *current* balance.
        // Note: This is a simplified model. In a real system, you might track
        // earnings per project more explicitly to avoid issues if one project's creator
        // withdraws before others, potentially taking more than their share if total balance < total earnings.
        // A more robust system would track project-specific balances.
        // For this example, we assume withdrawals happen reasonably often.

        uint256 contractBalance = address(this).balance;
        uint256 totalMintValue = 0;
        // This calculation requires summing up all mint payments, which is inefficient.
        // A better way: Track `projectBalances[projectId]` state variable.
        // For this example, we abstract the withdrawal logic assuming the balance is available.
        // A safer implementation would require tracking balances per project.

        // Abstracted withdrawal logic:
        // Let's assume there's an internal mapping `projectBalances[projectId]`.
        // uint256 creatorShare = projectBalances[projectId];

        // Simplified example assuming fees from mints are the only balance:
        // (This is NOT safe if multiple projects exist and balances aren't tracked per project)
        // uint224 totalFeesCollected = address(this).balance;
        // uint256 creatorShare = (totalFeesCollected * projects[projectId].creatorFeeBasisPoints) / 10000;
        // uint256 factoryShare = (totalFeesCollected * factoryFeeBasisPoints) / 10000;
        // uint256 totalShare = creatorShare + factoryShare; // Total fees collected from *all* mints

        // To make withdrawal safe without per-project balances state:
        // Need to track total fees ever collected by the contract, and total fees ever withdrawn by factory/creators.
        // Or, simply require creator to call `withdraw` immediately after minting? No, that's bad UX.
        // Let's add a simple mapping `projectBalances` for a slightly more realistic example.

        uint256 creatorShare = projectBalances[projectId]; // Assuming this state variable exists internally

        if (creatorShare == 0) {
            revert NoFeesToWithdraw(); // Use the same error for simplicity
        }

        projectBalances[projectId] = 0; // Reset balance *before* sending
        (bool success, ) = payable(projects[projectId].creator).call{value: creatorShare}("");
        require(success, "Creator withdrawal failed");

        emit ProjectRoyaltiesWithdrawn(projectId, projects[projectId].creator, creatorShare);
    }

    // Internal mapping for project-specific balances (simplified for this example)
    mapping(uint256 => uint256) private projectBalances;
    uint256 private factoryBalance;

    // Modified fee distribution during minting (internal helper)
    function _distributeFees(uint256 amount, uint256 projectId) internal {
        uint256 creatorFee = (amount * projects[projectId].creatorFeeBasisPoints) / 10000;
        uint256 factoryFee = (amount * factoryFeeBasisPoints) / 10000;
        // Send remaining amount back if fees < 100%
        // Or, ensure fees don't exceed 10000 basis points total

        projectBalances[projectId] += creatorFee;
        factoryBalance += factoryFee; // Accumulate factory fees internally
    }

    // Modified withdrawFactoryFees to use factoryBalance
    function withdrawFactoryFees() external nonReentrant {
        address recipient = factoryFeeRecipient;
        uint256 amount = factoryBalance;

        if (amount == 0) {
            revert NoFeesToWithdraw();
        }

        factoryBalance = 0; // Reset balance *before* sending
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Factory withdrawal failed");

        emit FactoryFeesWithdrawn(recipient, amount);
    }


    /**
     * @notice Transfers ownership of a project to a new creator.
     * @param projectId The ID of the project.
     * @param newCreator The address of the new creator.
     */
    function transferProjectOwnership(uint256 projectId, address newCreator) external onlyProjectCreator(projectId) {
        require(newCreator != address(0), "Invalid new creator address");
        address oldCreator = projects[projectId].creator;

        // Remove from old creator's list (simplified, needs iteration in real code)
        // In a real scenario, tracking projects by creator might need a more complex data structure
        // or simply accept O(N) cost for removal. For this example, we'll just add to the new list.
        // A better approach for `_projectsByCreator` getter would be to iterate all projects.
        _projectsByCreator[newCreator].push(projectId); // Add to new creator's list

        projects[projectId].creator = newCreator;

        emit ProjectOwnershipTransferred(projectId, oldCreator, newCreator);
    }


    // --- Project Configuration (by Creator) ---

    /**
     * @notice Sets the base URI for the project's NFTs.
     * This URI will be used in the tokenURI call to construct the full metadata/render URL.
     * @param projectId The ID of the project.
     * @param newBaseURI The new base URI string.
     */
    function setProjectBaseURI(uint256 projectId, string memory newBaseURI) external onlyProjectCreator(projectId) {
        projects[projectId].baseURI = newBaseURI;
        emit ProjectBaseURIUpdated(projectId, newBaseURI);
    }

    /**
     * @notice Adds a generative parameter to a project.
     * @param projectId The ID of the project.
     * @param name The name of the parameter (e.g., "colorPalette", "shapeComplexity").
     * @param min The minimum value for the parameter.
     * @param max The maximum value for the parameter.
     */
    function addGenerativeParameter(uint256 projectId, string memory name, uint256 min, uint256 max) external onlyProjectCreator(projectId) {
        require(bytes(name).length > 0, "Parameter name cannot be empty");
        require(min <= max, "Min value must be less than or equal to max value");
        ProjectConfig storage project = projects[projectId];
        require(!project.parameters[name].exists, "Parameter already exists");

        project.parameters[name] = GenerativeParameter({
            min: min,
            max: max,
            exists: true
        });
        project.parameterNames.push(name); // Keep track of names for iteration

        emit GenerativeParameterAdded(projectId, name, min, max);
    }

    /**
     * @notice Updates the range of an existing generative parameter in a project.
     * This affects parameter generation for *future* mints and mutation constraints.
     * @param projectId The ID of the project.
     * @param name The name of the parameter.
     * @param newMin The new minimum value.
     * @param newMax The new maximum value.
     */
    function updateGenerativeParameterRange(uint256 projectId, string memory name, uint256 newMin, uint256 newMax) external onlyProjectCreator(projectId) {
        require(newMin <= newMax, "Min value must be less than or equal to max value");
        ProjectConfig storage project = projects[projectId];
        require(project.parameters[name].exists, ParameterNotInProject(projectId, name));

        project.parameters[name].min = newMin;
        project.parameters[name].max = newMax;

        emit GenerativeParameterUpdated(projectId, name, newMin, newMax);
    }

    /**
     * @notice Removes a generative parameter from a project.
     * WARNING: Removing parameters can break existing metadata/renderers if not handled off-chain.
     * @param projectId The ID of the project.
     * @param name The name of the parameter to remove.
     */
    function removeGenerativeParameter(uint256 projectId, string memory name) external onlyProjectCreator(projectId) {
        ProjectConfig storage project = projects[projectId];
        require(project.parameters[name].exists, ParameterNotInProject(projectId, name));

        delete project.parameters[name];

        // Remove from parameterNames array (simplified O(N) removal)
        for (uint i = 0; i < project.parameterNames.length; i++) {
            if (keccak256(bytes(project.parameterNames[i])) == keccak256(bytes(name))) {
                project.parameterNames[i] = project.parameterNames[project.parameterNames.length - 1];
                project.parameterNames.pop();
                break;
            }
        }

        emit GenerativeParameterRemoved(projectId, name);
    }

    /**
     * @notice Sets the price to mint an NFT from a project.
     * @param projectId The ID of the project.
     * @param price The new mint price in wei.
     */
    function setMintPrice(uint256 projectId, uint256 price) external onlyProjectCreator(projectId) {
        projects[projectId].mintPrice = price;
        emit MintPriceUpdated(projectId, price);
    }

    /**
     * @notice Sets the maximum number of NFTs a single wallet can mint from a project.
     * Set to 0 for no limit.
     * @param projectId The ID of the project.
     * @param limit The new mint limit per wallet.
     */
    function setMintLimit(uint256 projectId, uint256 limit) external onlyProjectCreator(projectId) {
        projects[projectId].mintLimitPerWallet = limit;
        emit MintLimitUpdated(projectId, limit);
    }

    // --- NFT Minting ---

    /**
     * @notice Mints a new NFT from a specific project.
     * Requires payment of the mint price. Parameters are initially pending randomness.
     * @param projectId The ID of the project to mint from.
     * @param recipient The address to receive the NFT.
     */
    function mintNFT(uint256 projectId, address recipient) external payable nonReentrant {
        ProjectConfig storage project = projects[projectId];
        require(project.creator != address(0), ProjectNotFound(projectId)); // Ensure project exists

        if (!project.isPublic && msg.sender != project.creator && msg.sender != owner()) {
             revert ProjectNotMintable(projectId); // Or add a specific allowlist check
        }

        require(!project.isMintingPaused, ProjectNotMintable(projectId));
        require(msg.value >= project.mintPrice, MintPriceNotMet(project.mintPrice, msg.value));

        if (project.mintLimitPerWallet > 0) {
            if (project.mintedByWallet[msg.sender] >= project.mintLimitPerWallet) {
                revert MintLimitReached(projectId, msg.sender);
            }
        }

        project.totalMinted++;
        project.mintedByWallet[msg.sender]++;

        // Mint the ERC721 token first to get a tokenId
        uint256 newTokenId = project.totalMinted; // Simple sequential token ID per project
        // Note: For a factory, token IDs need to be globally unique or scoped per project.
        // A better approach is a global token ID counter `_tokenIds.increment()` and
        // mapping `_tokenIdToProjectId`. Let's use a global counter.

        Counters.Counter private _tokenIds;
        mapping(uint256 => uint256) private _tokenIdToProjectId;

        function mintNFT(uint256 projectId, address recipient) external payable nonReentrant {
             ProjectConfig storage project = projects[projectId];
             require(project.creator != address(0), ProjectNotFound(projectId)); // Ensure project exists

             // ... checks ...

             _tokenIds.increment();
             uint256 newTokenId = _tokenIds.current();
             _tokenIdToProjectId[newTokenId] = projectId; // Link token to project

             project.totalMinted++;
             project.mintedByWallet[msg.sender]++;

             // Store initial pending state for parameters
             _nftParameters[newTokenId].areSet = false;
             _nftParameters[newTokenId].isLocked = false;
             _nftParameters[newTokenId].mutationCount = 0;

             // Request randomness (abstraction)
             bytes32 requestId = _requestRandomness(projectId, newTokenId);
             _nftParameters[newTokenId].randomnessRequestId = requestId;

             _safeMint(recipient, newTokenId);

             // Distribute fees *after* successful mint and potential refund of excess ether
             uint256 amountPaid = msg.value;
             uint256 refund = amountPaid - project.mintPrice;
             if (refund > 0) {
                 (bool successRefund, ) = payable(msg.sender).call{value: refund}("");
                 require(successRefund, "Refund failed"); // This should ideally not revert after successful mint
             }
             _distributeFees(project.mintPrice, projectId); // Distribute fees from the actual price

             emit NFTMinted(projectId, newTokenId, recipient);
         }


    /**
     * @notice Internal helper to abstract randomness request.
     * In a real contract, this would call a VRF coordinator.
     * @param projectId The project ID.
     * @param tokenId The token ID being minted.
     * @return The request ID for tracking the randomness fulfillment.
     */
    function _requestRandomness(uint256 projectId, uint256 tokenId) internal returns (bytes32) {
        // *** ABSTRACTION ONLY ***
        // In a real Chainlink VRF integration, this would look like:
        // bytes32 requestId = i_vrfCoordinator.requestRandomWords(...);
        // _randomnessRequestIdToProjectId[requestId] = projectId;
        // _randomnessRequestIdToTokenId[requestId] = tokenId;
        // _tokenIdToRandomnessRequestId[tokenId] = requestId;
        // emit RandomnessRequested(requestId, projectId, tokenId);
        // return requestId;

        // For this example, simulate a request ID
        bytes32 simulatedRequestId = keccak256(abi.encodePacked(projectId, tokenId, block.timestamp, msg.sender, block.number));
        _randomnessRequestIdToProjectId[simulatedRequestId] = projectId;
        _randomnessRequestIdToTokenId[simulatedRequestId] = tokenId;
        _tokenIdToRandomnessRequestId[tokenId] = simulatedRequestId;

        emit RandomnessRequested(simulatedRequestId, projectId, tokenId);
        return simulatedRequestId;
    }

    /**
     * @notice Callback function for randomness fulfillment.
     * This function would be called by the randomness oracle (e.g., Chainlink VRF).
     * Sets the generative parameters for the NFT.
     * @param requestId The ID of the randomness request.
     * @param randomness The fulfilled randomness value (simplified to one uint256).
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external { // Could add 'onlyOracle' modifier
        uint256 projectId = _randomnessRequestIdToProjectId[requestId];
        uint256 tokenId = _randomnessRequestIdToTokenId[requestId];

        require(projectId != 0, "Unknown randomness request"); // Ensure request exists
        require(ownerOf(tokenId) != address(0), "Token does not exist"); // Ensure token exists and wasn't burnt
        require(!_nftParameters[tokenId].areSet, RandomnessAlreadyFulfilled(tokenId)); // Ensure parameters haven't been set yet
        require(_tokenIdToRandomnessRequestId[tokenId] == requestId, "Mismatched request ID for token");

        ProjectConfig storage project = projects[projectId];
        NFTGenerativeParameters storage nftParams = _nftParameters[tokenId];

        // --- Generative Parameter Calculation (Core Logic) ---
        // This is where the randomness is used to determine parameter values.
        // Simplified example: hash randomness with parameter name/index for each parameter.
        uint265 currentEntropy = uint256(keccak256(abi.encodePacked(randomness, tokenId)));
        uint256 numParameters = project.parameterNames.length;

        for (uint i = 0; i < numParameters; i++) {
            string memory paramName = project.parameterNames[i];
            GenerativeParameter storage projectParam = project.parameters[paramName];

            // Use derived entropy for each parameter
            currentEntropy = uint256(keccak256(abi.encodePacked(currentEntropy, paramName, i)));

            // Scale randomness to fit parameter range [min, max]
            // Ensure range is not zero to avoid division by zero.
            uint256 range = projectParam.max - projectParam.min;
            uint256 paramValue;
            if (range == 0) {
                paramValue = projectParam.min; // If range is 0, value is fixed
            } else {
                // Simple modulo arithmetic for randomness distribution.
                // Note: Modulo bias exists, especially with non-power-of-2 ranges.
                // For production, consider more robust randomness-to-range mapping.
                paramValue = projectParam.min + (currentEntropy % (range + 1));
            }

            nftParams.values[paramName] = paramValue;
        }

        nftParams.areSet = true;

        // Clean up randomness request tracking
        delete _randomnessRequestIdToProjectId[requestId];
        delete _randomnessRequestIdToTokenId[requestId];
        // Keep _tokenIdToRandomnessRequestId for lookup if needed later

        // Encode parameters into bytes for the event (optional, for easier logging/parsing)
        bytes memory parametersData = _encodeParameters(tokenId);
        emit NFTParametersSet(tokenId, parametersData);
    }

    // --- NFT Dynamics & Viewing ---

    /**
     * @notice Retrieves the current generative parameters stored for an NFT.
     * @param tokenId The ID of the NFT.
     * @return An array of structs containing parameter names and values.
     */
    function getNFTGenerativeParameters(uint256 tokenId) public view returns (ParameterUpdate[] memory) {
        uint256 projectId = _tokenIdToProjectId[tokenId];
        require(projectId != 0, "Token does not belong to a project");
        NFTGenerativeParameters storage nftParams = _nftParameters[tokenId];
        require(nftParams.areSet, RandomnessNotFulfilled(tokenId));

        ProjectConfig storage project = projects[projectId];
        uint256 numParams = project.parameterNames.length;
        ParameterUpdate[] memory params = new ParameterUpdate[](numParams);

        for (uint i = 0; i < numParams; i++) {
            string memory paramName = project.parameterNames[i];
            params[i] = ParameterUpdate({
                name: paramName,
                value: nftParams.values[paramName]
            });
        }
        return params;
    }

    /**
     * @notice Allows the NFT owner (or authorized address) to mutate specific parameters.
     * Parameters can only be mutated if they are within the project's current range
     * and the NFT is not locked.
     * @param tokenId The ID of the NFT.
     * @param updates An array of parameter names and new values.
     */
    function mutateNFTParameters(uint256 tokenId, ParameterUpdate[] memory updates) external onlyNFTOwnerOrApproved(tokenId) {
        NFTGenerativeParameters storage nftParams = _nftParameters[tokenId];
        require(nftParams.areSet, RandomnessNotFulfilled(tokenId));
        require(!nftParams.isLocked, ParametersLocked(tokenId));

        uint256 projectId = _tokenIdToProjectId[tokenId];
        require(projectId != 0, "Token does not belong to a project");
        ProjectConfig storage project = projects[projectId];

        // --- Mutation Logic ---
        // Store old parameters for event
        bytes memory oldParametersData = _encodeParameters(tokenId);

        for (uint i = 0; i < updates.length; i++) {
            string memory paramName = updates[i].name;
            uint256 newValue = updates[i].value;

            GenerativeParameter storage projectParam = project.parameters[paramName];
            require(projectParam.exists, InvalidParameterUpdate(tokenId, paramName));
            require(newValue >= projectParam.min && newValue <= projectParam.max, InvalidParameterValue(paramName, newValue));

            nftParams.values[paramName] = newValue;
        }

        nftParams.mutationCount++;

        // Encode new parameters for event
        bytes memory newParametersData = _encodeParameters(tokenId);

        emit NFTParametersMutated(tokenId, oldParametersData, newParametersData, msg.sender);
    }

    /**
     * @notice Locks an NFT's parameters, preventing future mutations.
     * Only the owner or project creator/factory owner can lock.
     * @param tokenId The ID of the NFT.
     */
    function lockParametersForNFT(uint256 tokenId) external {
        uint256 projectId = _tokenIdToProjectId[tokenId];
        require(projectId != 0, "Token does not belong to a project");
        // Allow NFT owner, project creator, or factory owner to lock
        address owner = ownerOf(tokenId);
        ProjectConfig storage project = projects[projectId];
        require(msg.sender == owner || msg.sender == project.creator || msg.sender == owner(), "Not authorized to lock parameters");

        NFTGenerativeParameters storage nftParams = _nftParameters[tokenId];
        require(nftParams.areSet, RandomnessNotFulfilled(tokenId));
        require(!nftParams.isLocked, "Parameters already locked");

        nftParams.isLocked = true;
        emit ParametersLocked(tokenId);
    }

     /**
      * @notice Returns the number of times an NFT's parameters have been mutated.
      * @param tokenId The ID of the NFT.
      * @return The mutation count.
      */
     function getNFTMutationCount(uint256 tokenId) external view returns (uint256) {
         // Check if token exists via ownerOf or similar
         require(ownerOf(tokenId) != address(0) || _exists(tokenId), "ERC721: invalid token ID");
         return _nftParameters[tokenId].mutationCount;
     }


    /**
     * @notice Returns the metadata URI for an NFT.
     * This constructs the URI using the project's base URI and the NFT's parameters.
     * @param tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 projectId = _tokenIdToProjectId[tokenId];
        require(projectId != 0, "Token does not belong to a project");
        ProjectConfig storage project = projects[projectId];

        // If parameters are not set (randomness pending), return a placeholder URI
        if (!_nftParameters[tokenId].areSet) {
             return string(abi.encodePacked(project.baseURI, "/", Strings.toString(tokenId), "/pending"));
        }

        // Construct URI: baseURI + "/" + tokenId + "?param1=value1&param2=value2..."
        bytes memory uriBytes = abi.encodePacked(project.baseURI, "/", Strings.toString(tokenId), "?");

        NFTGenerativeParameters storage nftParams = _nftParameters[tokenId];
        string[] memory paramNames = project.parameterNames;

        for (uint i = 0; i < paramNames.length; i++) {
            string memory paramName = paramNames[i];
            uint256 paramValue = nftParams.values[paramName];

            uriBytes = abi.encodePacked(uriBytes, paramName, "=", Strings.toString(paramValue));

            if (i < paramNames.length - 1) {
                uriBytes = abi.encodePacked(uriBytes, "&");
            }
        }

        return string(uriBytes);
    }

    /**
     * @notice Internal helper to encode NFT parameters into a bytes string.
     * Useful for logging in events. Format: paramName1:value1;paramName2:value2;...
     * @param tokenId The ID of the NFT.
     * @return The encoded parameters as bytes.
     */
    function _encodeParameters(uint256 tokenId) internal view returns (bytes memory) {
        uint256 projectId = _tokenIdToProjectId[tokenId];
        if (projectId == 0 || !_nftParameters[tokenId].areSet) {
             return bytes("");
        }

        ProjectConfig storage project = projects[projectId];
        NFTGenerativeParameters storage nftParams = _nftParameters[tokenId];
        string[] memory paramNames = project.parameterNames;

        bytes memory encoded;
        for (uint i = 0; i < paramNames.length; i++) {
             string memory paramName = paramNames[i];
             uint256 paramValue = nftParams.values[paramName];

             encoded = abi.encodePacked(encoded, paramName, ":", Strings.toString(paramValue));

             if (i < paramNames.length - 1) {
                  encoded = abi.encodePacked(encoded, ";");
             }
        }
        return encoded;
    }


    // --- Project Evolution (Epochs) ---

    /**
     * @notice Triggers an epoch update for a specific parameter in a project.
     * This changes the allowed range [min, max] for *future* mints of that parameter,
     * and increments the project's epoch count. Does *not* affect existing NFTs' parameters.
     * @param projectId The ID of the project.
     * @param parameterName The name of the parameter to update.
     * @param newMin The new minimum value for the parameter.
     * @param newMax The new maximum value for the parameter.
     */
    function triggerParameterEpochUpdate(uint256 projectId, string memory parameterName, uint256 newMin, uint256 newMax) external onlyProjectCreator(projectId) {
        // Could add onlyOwner or specific role check instead of onlyProjectCreator
        require(newMin <= newMax, "New min value must be less than or equal to new max value");
        ProjectConfig storage project = projects[projectId];
        require(project.parameters[parameterName].exists, ParameterNotInProject(projectId, parameterName));

        project.parameters[parameterName].min = newMin;
        project.parameters[parameterName].max = newMax;
        project.epoch++; // Increment epoch counter

        emit ParameterEpochUpdated(projectId, parameterName, newMin, newMax, project.epoch);
    }

    /**
     * @notice Returns the current 'epoch' count for a project.
     * The epoch increments each time `triggerParameterEpochUpdate` is called for any parameter in that project.
     * @param projectId The ID of the project.
     * @return The current epoch number.
     */
    function getProjectEpoch(uint256 projectId) external view returns (uint256) {
        require(projects[projectId].creator != address(0), ProjectNotFound(projectId));
        return projects[projectId].epoch;
    }

    // --- Access Control (Parameter Modifiers) ---

    /**
     * @notice Grants the role to mutate parameters for NFTs within a specific project.
     * @param account The address to grant the role to.
     * @param projectId The ID of the project.
     */
    function grantParameterModifierRole(address account, uint256 projectId) external onlyProjectCreator(projectId) {
        require(account != address(0), "Cannot grant to zero address");
        _parameterModifierRoles[account][projectId] = true;
        emit ParameterModifierRoleGranted(account, projectId, msg.sender);
    }

    /**
     * @notice Revokes the role to mutate parameters for NFTs within a specific project.
     * @param account The address to revoke the role from.
     * @param projectId The ID of the project.
     */
    function revokeParameterModifierRole(address account, uint256 projectId) external onlyProjectCreator(projectId) {
         require(account != address(0), "Cannot revoke from zero address");
        _parameterModifierRoles[account][projectId] = false;
        emit ParameterModifierRoleRevoked(account, projectId, msg.sender);
    }

    /**
     * @notice Checks if an address has the parameter modifier role for a project.
     * Note: Project creators and factory owner implicitly have this permission via modifier.
     * @param account The address to check.
     * @param projectId The ID of the project.
     * @return True if the account has the role, false otherwise.
     */
    function hasParameterModifierRole(address account, uint256 projectId) external view returns (bool) {
        return _parameterModifierRoles[account][projectId];
    }

    // --- Standard ERC721 & ERC2981 Overrides ---

    // The following functions are required by ERC721Enumerable, ERC721Pausable, ERC2981
    // and are largely handled by the OpenZeppelin inheritance.
    // We only need to override `royaltyInfo` and ensure `supportsInterface` is correct.

    /**
     * @dev See {ERC721-baseURI}. This contract uses project-specific base URIs.
     * The baseURI function from ERC721 is not used directly. tokenURI is overridden.
     */
    function baseURI() internal view override(ERC721) returns (string memory) {
        // This baseURI function is not strictly needed as tokenURI is overridden
        // and uses the project-specific base URI.
        return ""; // Or return a generic factory base URI if needed
    }

    /**
     * @dev See {ERC2981-royaltyInfo}.
     * Calculates the royalty amount for a sale based on project configuration.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override(ERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 projectId = _tokenIdToProjectId[tokenId];
        if (projectId == 0) {
            // Token does not belong to a tracked project, return default or 0
             return (defaultRoyaltyRecipient, (salePrice * defaultRoyaltyBasisPoints) / 10000);
        }

        ProjectConfig storage project = projects[projectId];
        uint96 feeBasisPoints = project.creatorFeeBasisPoints > 0 ? project.creatorFeeBasisPoints : defaultRoyaltyBasisPoints;
        address recipient = project.creatorFeeBasisPoints > 0 ? project.creator : defaultRoyaltyRecipient;

        return (recipient, (salePrice * feeBasisPoints) / 10000);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721Pausable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // --- Getters ---

    /**
     * @notice Retrieves configuration details for a project.
     * @param projectId The ID of the project.
     * @return ProjectConfig struct containing project details.
     */
    function getProjectDetails(uint256 projectId) external view returns (
        string memory name,
        address creator,
        string memory baseURI,
        uint256 mintPrice,
        uint256 mintLimitPerWallet,
        bool isPublic,
        bool isMintingPaused,
        uint96 creatorFeeBasisPoints,
        uint256 epoch,
        uint256 totalMinted
    ) {
         ProjectConfig storage project = projects[projectId];
         require(project.creator != address(0), ProjectNotFound(projectId)); // Check if project exists

         return (
             project.name,
             project.creator,
             project.baseURI,
             project.mintPrice,
             project.mintLimitPerWallet,
             project.isPublic,
             project.isMintingPaused,
             project.creatorFeeBasisPoints,
             project.epoch,
             project.totalMinted
         );
    }

    /**
     * @notice Returns the total number of projects created by the factory.
     * @return The total project count.
     */
    function getTotalProjects() external view returns (uint256) {
        return _projectIds.current();
    }

    /**
     * @notice Returns a list of project IDs created by a specific address.
     * @param creator The address of the creator.
     * @return An array of project IDs.
     */
    function getProjectsByCreator(address creator) external view returns (uint256[] memory) {
        return _projectsByCreator[creator];
    }

    /**
     * @notice Returns the project ID that an NFT belongs to.
     * @param tokenId The ID of the NFT.
     * @return The project ID. Returns 0 if token ID is invalid or not associated.
     */
    function getNFTProjectID(uint256 tokenId) external view returns (uint256) {
        return _tokenIdToProjectId[tokenId];
    }

    /**
     * @notice Returns the total number of NFTs minted from a specific project.
     * @param projectId The ID of the project.
     * @return The total minted count for the project.
     */
    function getTotalMintedByProject(uint256 projectId) external view returns (uint256) {
         require(projects[projectId].creator != address(0), ProjectNotFound(projectId));
         return projects[projectId].totalMinted;
    }

    /**
     * @notice Returns the number of NFTs minted by a wallet for a specific project.
     * @param projectId The ID of the project.
     * @param wallet The address of the wallet.
     * @return The number of NFTs minted by the wallet for the project.
     */
    function getMintCountForWallet(uint256 projectId, address wallet) external view returns (uint256) {
         require(projects[projectId].creator != address(0), ProjectNotFound(projectId));
         return projects[projectId].mintedByWallet[wallet];
    }

    /**
     * @notice Checks if an NFT's parameters are locked against mutation.
     * @param tokenId The ID of the NFT.
     * @return True if parameters are locked, false otherwise.
     */
    function isParametersLocked(uint256 tokenId) external view returns (bool) {
        // Check if token exists before accessing _nftParameters
         require(_exists(tokenId), "ERC721: invalid token ID");
        return _nftParameters[tokenId].isLocked;
    }

    /**
     * @notice Retrieves the list of parameter names defined for a project.
     * @param projectId The ID of the project.
     * @return An array of parameter names.
     */
    function getProjectParameterNames(uint256 projectId) external view returns (string[] memory) {
        require(projects[projectId].creator != address(0), ProjectNotFound(projectId));
        return projects[projectId].parameterNames;
    }

     /**
      * @notice Retrieves the min/max range for a specific parameter in a project.
      * @param projectId The ID of the project.
      * @param parameterName The name of the parameter.
      * @return min The minimum value.
      * @return max The maximum value.
      */
    function getProjectParameterRange(uint256 projectId, string memory parameterName) external view returns (uint256 min, uint256 max) {
        ProjectConfig storage project = projects[projectId];
        require(project.creator != address(0), ProjectNotFound(projectId));
        GenerativeParameter storage param = project.parameters[parameterName];
        require(param.exists, ParameterNotInProject(projectId, parameterName));
        return (param.min, param.max);
    }


    /**
     * @notice Gets the project ID and token ID associated with a pending randomness request.
     * Useful for monitoring oracle fulfillment status.
     * @param requestId The ID of the randomness request.
     * @return projectId The associated project ID.
     * @return tokenId The associated token ID.
     */
    function getPendingRandomRequest(bytes32 requestId) external view returns (uint256 projectId, uint256 tokenId) {
         return (_randomnessRequestIdToProjectId[requestId], _randomnessRequestIdToTokenId[requestId]);
    }

    /**
     * @notice Checks if an NFT's parameters are pending randomness fulfillment.
     * @param tokenId The ID of the NFT.
     * @return True if parameters are pending, false otherwise.
     */
    function isParametersPending(uint256 tokenId) external view returns (bool) {
        // Check if token exists via ownerOf or similar
         require(_exists(tokenId), "ERC721: invalid token ID");
        return !_nftParameters[tokenId].areSet && _tokenIdToRandomnessRequestId[tokenId] != bytes32(0);
    }


    // --- ERC721 and ERC2981 implementations provided by OpenZeppelin ---
    // (balanceOf, ownerOf, safeTransferFrom, transferFrom, approve, getApproved,
    // setApprovalForAll, isApprovedForAll, tokenByIndex, tokenOfOwnerByIndex, totalSupply,
    // _beforeTokenTransfer, _afterTokenTransfer, _safeMint etc.)
    // No need to explicitly list or re-implement them here, they are inherited.
    // The overrides for tokenURI and supportsInterface are handled above.
    // Pausable functions (pause, unpause) are inherited from ERC721Pausable.
    // Ownable functions (transferOwnership, renounceOwnership) are inherited.

    // Ensure pausable functions can only be called by owner (ERC721Pausable default)
    // ERC721Pausable requires _pause and _unpause to be called by owner.
    // The standard pause/unpause functions are internal, so this contract's owner
    // would need to add external functions to expose pausing the *whole contract*.
    // Project-specific pausing is handled by `pauseProjectMinting` and `unpauseProjectMinting`.

     function pauseFactory() external onlyOwner {
         _pause();
     }

     function unpauseFactory() external onlyOwner {
         _unpause();
     }

    // Override ERC721Enumerable's _beforeTokenTransfer to handle project and parameter state
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Handle pausing for the whole contract
        require(!paused(), "Factory is paused");

        // No specific actions needed for _tokenIdToProjectId or _nftParameters on transfer
        // as they remain associated with the tokenId regardless of owner.
    }
}
```

---

**Explanation of Concepts and Functions:**

1.  **Generative Art Focus:** The core idea is that the NFT's appearance/properties are derived from a set of parameters stored on-chain (`_nftParameters`). The `tokenURI` function is designed to include these parameters in the URL, allowing an off-chain renderer or metadata server to generate the unique art based on the on-chain data.

2.  **Factory Pattern:** The contract acts as a factory (`createProject`), allowing multiple distinct generative art *projects* to exist within a single contract. Each project has its own settings, parameters, and minting rules.

3.  **Dynamic Parameters (`mutateNFTParameters`):** This is a key advanced feature. Unlike static NFTs, owners (or those with the `PARAMETER_MODIFIER_ROLE`) can call `mutateNFTParameters` to change the parameter values stored for their specific NFT. This could represent evolving art, character customization, etc. Constraints (like parameter ranges and the `isLocked` flag) apply.

4.  **Project Epochs (`triggerParameterEpochUpdate`):** This allows project creators or the factory owner to change the valid range for a parameter *for all future mints* from that project. This introduces the concept of "epochs" or "seasons" for a generative collection, where NFTs from different epochs might have noticeably different characteristics due to varying parameter possibilities. It *doesn't* affect existing NFTs.

5.  **Randomness Abstraction (`_requestRandomness`, `fulfillRandomness`):** Minting generative art often requires randomness to determine initial parameters. Directly using `block.timestamp` or `block.difficulty` is insecure. This contract models the interaction with an external randomness oracle (like Chainlink VRF) using `_requestRandomness` and `fulfillRandomness`. The NFT parameters are only finalized *after* the oracle provides the random value via the callback. While abstracted, it demonstrates the necessary pattern. NFTs are in a "pending" state until randomness is fulfilled.

6.  **Structured Parameters:** Projects define their parameters by name and range (`GenerativeParameter`). The NFT stores specific `uint256` values for these parameters (`NFTGenerativeParameters`). Using a mapping by string name allows for flexible parameter sets per project.

7.  **Roles (`PARAMETER_MODIFIER_ROLE`):** Beyond the standard `Ownable` and project `creator`, a specific role is introduced for parameter mutation, allowing fine-grained control over who can trigger changes on NFTs within a project.

8.  **ERC2981 Royalties:** Implements the standard for NFT royalties, allowing marketplaces to query the contract for the correct royalty recipient and percentage based on the project configuration or a factory default.

9.  **Custom Errors:** Uses `error` instead of `require(..., "string")` for better gas efficiency and clearer error reporting.

10. **Enumerable & Pausable:** Inherits OpenZeppelin modules for standard enumeration features and the ability to pause transfers (or the entire factory in this case).

**Potential Improvements/Further Advanced Concepts (Not fully implemented to keep example focused):**

*   **More Complex Parameter Types:** Parameters could be structs, arrays, or enums rather than just uint256 within a range.
*   **On-Chain Parameter Generation Logic:** Instead of just storing random uint256, implement more complex on-chain algorithms that combine multiple parameters or use the randomness in more sophisticated ways.
*   **Layer 2 Compatibility:** Consider state proofs or different randomness sources compatible with L2s.
*   **Voting/Governance:** Allow NFT holders or project creators to vote on proposed parameter epoch updates or other project changes.
*   **Dynamic Royalty Splits:** Allow royalties to change over time or based on sales volume.
*   **Batch Minting/Mutation:** Functions to handle multiple tokens in a single transaction.
*   **IPFS Pinning Integration:** Abstract or integrate with services to ensure the off-chain art/metadata remains available.
*   **Upgradeability:** Use proxy patterns (like UUPS or Transparent) to make the factory upgradable. (Adds significant complexity).
*   **Gas Optimizations:** Further optimize storage, function calls, and loops.
*   **Security Audits:** A real-world contract would require thorough security review, especially for randomness and access control.

This contract provides a solid framework combining several advanced concepts within the context of dynamic, generative NFTs.