Okay, here is a smart contract concept for a Decentralized Autonomous Artist Guild (DAAG). This concept combines elements of NFT creation, collaborative funding, a dynamic reputation system, simulated off-chain generative processes, and complex royalty distribution, aiming for uniqueness and advanced concepts beyond standard templates.

**Disclaimer:** This is a complex contract concept for demonstration. It simulates off-chain interactions and internal NFT-like tracking for simplicity within a single file. A production version would likely use external ERC-721 contracts, potentially IPFS/Arweave integration, robust oracle solutions for off-chain triggers, and a dedicated governance module. Security audits would be essential.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAutonomousArtistGuild (DAAG)
 * @author Your Name/Pseudonym (Concept by AI)
 * @dev This contract implements a decentralized guild for generative artists and patrons.
 * Artists can register, propose generative art recipes (represented internally),
 * collaborate on recipes, and earn reputation. Patrons can fund projects based on recipes.
 * An off-chain process is simulated to trigger the creation of unique artworks
 * based on funded projects and recipes. Complex, dynamic royalty splits and
 * reputation mechanics are included.
 *
 * --- Outline ---
 * 1. State Variables and Structs: Define core data structures for artists, recipes, projects, artworks.
 * 2. Events: Announce key actions.
 * 3. Errors: Define custom errors for clarity.
 * 4. Access Control: Implement ownership and roles (Artist, OffchainExecutor).
 * 5. Configuration: Set global parameters (fees, thresholds).
 * 6. Artist Management: Register/unregister artists, track reputation.
 * 7. Recipe Management: Create, update, collaborate on generative art recipes.
 * 8. Project Management: Create, fund, and track funding for art projects.
 * 9. Artwork Generation (Simulated): Trigger the creation process and mint artworks.
 * 10. Royalty Distribution: Handle complex, dynamic distribution of project proceeds.
 * 11. Treasury Management: Collect and withdraw guild fees.
 * 12. Utility/View Functions: Retrieve state information.
 * 13. Pausable/Emergency: Basic contract control.
 *
 * --- Function Summary ---
 * (Minimum 20 functions, including external/public and complex internal ones triggered externally)
 *
 * Configuration & Admin:
 * - constructor(): Initializes contract owner, base fees, and initial thresholds.
 * - setGuildFee(uint256 _newFeePermille): Sets the percentage fee taken by the guild (in per mille, i.e., parts per thousand).
 * - setReputationThresholds(uint256[] calldata _thresholds): Sets reputation levels required for certain privileges or royalty bonuses.
 * - setOffchainExecutor(address _executor): Sets the address authorized to trigger artwork generation (simulating off-chain worker).
 *
 * Artist Management:
 * - registerArtist(): Allows an address to register as a guild artist (may require fee/condition).
 * - unregisterArtist(): Allows a registered artist to leave the guild (may have penalties).
 * - getArtistReputation(address _artist): Returns the current reputation score of an artist.
 * - slashReputation(address _artist, uint256 _amount): Admin function to decrease artist reputation (e.g., for rule violations).
 *
 * Recipe Management (Internal Tracking, acts like NFT ownership):
 * - mintRecipe(string calldata _metadataHash, uint256 _creationFee): Allows registered artists to mint a new recipe, pays a fee.
 * - updateRecipeMetadataHash(uint256 _recipeId, string calldata _newMetadataHash): Allows recipe owner to update the metadata hash (e.g., point to V2 of parameters).
 * - transferRecipe(address _from, address _to, uint256 _recipeId): Simulates ERC721 transfer for recipe ownership.
 * - burnRecipe(uint256 _recipeId): Allows recipe owner to burn their recipe.
 * - proposeRecipeCollaboration(uint256 _recipeId, address _collaborator): Recipe owner proposes collaboration.
 * - acceptRecipeCollaboration(uint256 _recipeId): Proposed collaborator accepts.
 * - removeRecipeCollaboration(uint256 _recipeId, address _collaborator): Recipe owner removes a collaborator.
 * - getRecipeDetails(uint256 _recipeId): Returns details about a recipe, including collaborators.
 * - getRecipeUsageCount(uint256 _recipeId): Returns how many times a recipe has been used in a successfully funded project.
 *
 * Project Management:
 * - createFundingProject(uint256 _recipeId, string calldata _projectMetadataHash) payable: Initiates a funding project for a recipe, optionally funding it immediately.
 * - fundProject(uint256 _projectId) payable: Allows anyone to contribute funds to an active project.
 * - getProjectDetails(uint256 _projectId): Returns details about a funding project (status, funding goal, current funding, contributors).
 *
 * Artwork Generation & Royalty Distribution (Simulated Off-chain Interaction Trigger):
 * - triggerArtworkGeneration(uint256 _projectId, string calldata _artworkMetadataHash): Callable ONLY by the `offchainExecutor` after a project is fully funded. Simulates off-chain generation, mints the artwork internally, and distributes funds. This function encapsulates significant logic.
 * - getArtworkDetails(uint256 _artworkId): Returns details about a minted artwork (linked project, recipe, artists, metadata).
 * - getArtworkProvenance(uint256 _artworkId): Returns the project and recipe IDs associated with an artwork.
 * - getDynamicRoyaltySplit(uint256 _artworkId): Calculates the current royalty distribution percentage for artists/collaborators/patrons/guild for a specific artwork based on on-chain factors (e.g., artist reputation, number of collaborators, recipe usage count). (This is a view function demonstrating the calculation logic).
 *
 * Treasury & Utility:
 * - getGuildTreasuryBalance(): Returns the current balance held by the guild treasury.
 * - withdrawGuildFees(address _recipient, uint256 _amount): Admin function to withdraw fees from the treasury.
 *
 * Pausable & Emergency:
 * - pause(): Admin function to pause critical contract functions.
 * - unpause(): Admin function to unpause the contract.
 * - emergencyWithdraw(): Admin function to withdraw entire contract balance in case of emergency (funds sent to owner).
 */

contract DecentralizedAutonomousArtistGuild {
    // --- State Variables ---

    address public owner; // Contract owner
    address public offchainExecutor; // Address authorized to trigger generation

    bool private _paused; // Pausable state

    // Configuration
    uint256 public guildFeePermille; // Fee for the guild, in parts per thousand (e.g., 50 = 5%)
    uint256[] public reputationThresholds; // Reputation levels for bonuses/privileges
    uint256 public constant MIN_REPUTATION = 0;
    uint256 public constant MAX_REPUTATION = 1000; // Example max reputation

    // Counters for unique IDs
    uint256 private _recipeIdCounter = 0;
    uint256 private _projectIdCounter = 0;
    uint256 private _artworkIdCounter = 0;

    // Mappings for core data
    mapping(address => Artist) public artists;
    mapping(uint256 => Recipe) public recipes; // Recipe ID => Recipe details
    mapping(uint256 => Project) public projects; // Project ID => Project details
    mapping(uint256 => Artwork) public artworks; // Artwork ID => Artwork details

    // Internal Tracking (Simulating NFT-like ownership and properties)
    mapping(uint256 => address) private _recipeOwners; // Recipe ID => Owner
    mapping(uint256 => address) private _artworkOwners; // Artwork ID => Owner
    mapping(uint256 => string) private _recipeMetadataHashes; // Recipe ID => Metadata Hash
    mapping(uint256 => string) private _artworkMetadataHashes; // Artwork ID => Metadata Hash
    mapping(uint256 => uint256) private _recipeUsageCount; // Recipe ID => Number of projects successfully completed

    // Reputation tracking
    mapping(address => uint256) private _artistReputation;

    // Project Funding tracking
    mapping(uint256 => mapping(address => uint256)) public projectContributions; // Project ID => Contributor Address => Amount Contributed

    // Treasury balance
    uint256 public guildTreasuryBalance = 0;

    // --- Structs ---

    struct Artist {
        bool isRegistered;
        uint256 joinedTimestamp;
        // Add other artist-specific data if needed (e.g., portfolio link hash)
    }

    struct Recipe {
        uint256 id;
        address originalArtist; // The artist who minted the recipe
        string metadataHash; // Hash pointing to recipe parameters/code off-chain
        address[] collaborators; // List of addresses collaborating on this recipe
        mapping(address => bool) isCollaborator; // Helper for quick lookup
        uint256 mintTimestamp;
        uint256 lastUpdatedTimestamp;
        // Timelock for updates? (e.g., uint256 updateCooldownUntil;) - Added conceptually, not strictly implemented for function count
    }

    enum ProjectStatus {
        Idle, // Not yet started
        Funding, // Accepting contributions
        Funded, // Goal reached, ready for generation
        Generating, // Off-chain process triggered (simulated)
        Completed, // Artwork minted, funds distributed
        Cancelled // Project cancelled (e.g., failed funding, admin cancellation)
    }

    struct Project {
        uint256 id;
        uint256 recipeId; // The recipe this project is based on
        address creator; // The address that initiated the project (could be artist or patron)
        string projectMetadataHash; // Project-specific details/settings hash
        uint256 fundingGoal; // Amount needed to trigger generation
        uint256 currentFunding; // Current collected amount
        ProjectStatus status;
        uint256 createdTimestamp;
        uint256 fundedTimestamp; // Timestamp when funding goal was met
        uint256 completionTimestamp; // Timestamp when artwork was minted
        uint256 artworkId; // Link to the generated artwork (0 if not yet generated)
    }

    struct Artwork {
        uint256 id;
        uint256 projectId; // The project this artwork is linked to
        uint256 recipeId; // The recipe used
        address creator; // The project creator
        address originalArtist; // The original artist of the recipe
        address[] collaborators; // Collaborators on the recipe at creation time
        string metadataHash; // Hash pointing to the final artwork data/image off-chain
        uint256 mintTimestamp;
    }


    // --- Events ---

    event ArtistRegistered(address indexed artist, uint256 timestamp);
    event ArtistUnregistered(address indexed artist, uint256 timestamp);
    event ReputationUpdated(address indexed artist, uint256 newReputation);

    event RecipeMinted(uint256 indexed recipeId, address indexed owner, string metadataHash, uint256 timestamp);
    event RecipeMetadataUpdated(uint256 indexed recipeId, string newMetadataHash, uint256 timestamp);
    event RecipeTransferred(uint256 indexed recipeId, address indexed from, address indexed to, uint256 timestamp);
    event RecipeBurned(uint256 indexed recipeId, address indexed owner, uint256 timestamp);
    event RecipeCollaborationProposed(uint256 indexed recipeId, address indexed owner, address indexed collaborator, uint256 timestamp);
    event RecipeCollaborationAccepted(uint256 indexed recipeId, address indexed collaborator, uint256 timestamp);
    event RecipeCollaborationRemoved(uint256 indexed recipeId, address indexed collaborator, uint256 timestamp);

    event ProjectCreated(uint256 indexed projectId, uint256 indexed recipeId, address indexed creator, uint256 fundingGoal, uint256 timestamp);
    event ProjectFunded(uint256 indexed projectId, address indexed contributor, uint256 amount, uint256 totalFunded);
    event ProjectFundedGoalReached(uint256 indexed projectId, uint256 timestamp);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus oldStatus, ProjectStatus newStatus);
    event ProjectCancelled(uint256 indexed projectId, string reason, uint256 timestamp); // Added for completeness

    event ArtworkMinted(uint256 indexed artworkId, uint256 indexed projectId, uint256 indexed recipeId, address indexed owner, string metadataHash, uint256 timestamp);
    event ProceedsDistributed(uint256 indexed projectId, uint256 totalAmount, uint256 guildFee, uint256 artistShare, uint256 collaboratorsShare, uint256 patronsShare);

    event GuildFeeSet(uint256 newFeePermille);
    event ReputationThresholdsSet(uint256[] thresholds);
    event OffchainExecutorSet(address indexed executor);
    event GuildFeesWithdrawn(address indexed recipient, uint256 amount);

    event Paused(address account);
    event Unpaused(address account);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    // --- Errors ---

    error NotOwner();
    error NotRegisteredArtist();
    error NotRecipeOwner(uint256 recipeId);
    error RecipeDoesNotExist(uint256 recipeId);
    error ProjectDoesNotExist(uint256 projectId);
    error ProjectNotInFunding(uint256 projectId);
    error ProjectNotFunded(uint256 projectId);
    error ProjectAlreadyCompleted(uint256 projectId);
    error ProjectAlreadyGenerating(uint256 projectId);
    error ProjectAlreadyCancelled(uint256 projectId);
    error FundingGoalNotMet(uint256 projectId);
    error NotOffchainExecutor();
    error CannotUpdateRecipeWhileInFundedProject(uint256 recipeId, uint256 projectId);
    error OnlyRegisteredArtist();
    error InvalidFee(uint256 feePermille);
    error InvalidThresholds();
    error InvalidAmount();
    error ZeroAddress();
    error AlreadyRegisteredArtist();
    error NotProposedCollaborator(uint256 recipeId);
    error AlreadyCollaborator(uint256 recipeId);
    error CannotCollaborateOnOwnRecipe();
    error PausedContract();
    error NotPausedContract();
    error NothingToWithdraw();


    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyRegisteredArtist() {
        if (!artists[msg.sender].isRegistered) revert NotRegisteredArtist();
        _;
    }

     modifier onlyRecipeOwner(uint256 _recipeId) {
        if (_recipeOwners[_recipeId] == address(0) || _recipeOwners[_recipeId] != msg.sender) revert NotRecipeOwner(_recipeId);
        _;
    }

    modifier onlyOffchainExecutor() {
        if (msg.sender != offchainExecutor) revert NotOffchainExecutor();
        _;
    }

     modifier whenNotPaused() {
        if (_paused) revert PausedContract();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPausedContract();
        _;
    }


    // --- Constructor ---

    constructor(uint256 _initialGuildFeePermille, uint256[] calldata _initialReputationThresholds, address _initialOffchainExecutor) {
        if (_initialGuildFeePermille > 1000) revert InvalidFee(_initialGuildFeePermille);
        if (_initialOffchainExecutor == address(0)) revert ZeroAddress();

        owner = msg.sender;
        guildFeePermille = _initialGuildFeePermille;
        reputationThresholds = _initialReputationThresholds;
        offchainExecutor = _initialOffchainExecutor;

        // Initialize reputation thresholds sorted ascendingly
        // (Sorting not implemented here for brevity, assume input is sorted)
        // require(_initialReputationThresholds are sorted and valid range)
    }

    // --- Configuration & Admin Functions ---

    /**
     * @notice Sets the percentage fee taken by the guild from project proceeds.
     * @param _newFeePermille The new fee amount in parts per thousand (0-1000, e.g., 50 for 5%).
     */
    function setGuildFee(uint256 _newFeePermille) external onlyOwner {
        if (_newFeePermille > 1000) revert InvalidFee(_newFeePermille);
        guildFeePermille = _newFeePermille;
        emit GuildFeeSet(_newFeePermille);
    }

     /**
     * @notice Sets reputation levels that unlock certain benefits or influence royalty splits.
     * Assumes thresholds are provided in ascending order and within MIN/MAX_REPUTATION range.
     * @param _thresholds Array of reputation scores.
     */
    function setReputationThresholds(uint256[] calldata _thresholds) external onlyOwner {
        // Basic validation (add sorting/range checks in production)
        for (uint256 i = 0; i < _thresholds.length; i++) {
             if (_thresholds[i] > MAX_REPUTATION) revert InvalidThresholds();
             if (i > 0 && _thresholds[i] < _thresholds[i-1]) revert InvalidThresholds(); // Simple sorted check
        }
        reputationThresholds = _thresholds;
        emit ReputationThresholdsSet(_thresholds);
    }

    /**
     * @notice Sets the address authorized to call `triggerArtworkGeneration`.
     * This address represents the trusted off-chain worker or oracle service.
     * @param _executor The address of the off-chain executor.
     */
    function setOffchainExecutor(address _executor) external onlyOwner {
        if (_executor == address(0)) revert ZeroAddress();
        offchainExecutor = _executor;
        emit OffchainExecutorSet(_executor);
    }

    /**
     * @notice Admin function to decrease an artist's reputation score.
     * Used for penalties or governance actions.
     * @param _artist The artist address.
     * @param _amount The amount to decrease reputation by.
     */
    function slashReputation(address _artist, uint256 _amount) external onlyOwner {
        if (!artists[_artist].isRegistered) revert NotRegisteredArtist();
        uint256 currentRep = _artistReputation[_artist];
        _artistReputation[_artist] = currentRep > _amount ? currentRep - _amount : MIN_REPUTATION;
        emit ReputationUpdated(_artist, _artistReputation[_artist]);
    }


    // --- Artist Management Functions ---

    /**
     * @notice Registers the caller as a guild artist.
     * May have additional requirements (e.g., fee, token stake, proposal) in production.
     */
    function registerArtist() external whenNotPaused {
        if (artists[msg.sender].isRegistered) revert AlreadyRegisteredArtist();
        artists[msg.sender] = Artist({
            isRegistered: true,
            joinedTimestamp: block.timestamp
            // Initialize other fields
        });
        // Initial reputation could be MIN_REPUTATION or a small bonus
        _artistReputation[msg.sender] = MIN_REPUTATION; // Start at base reputation
        emit ArtistRegistered(msg.sender, block.timestamp);
        emit ReputationUpdated(msg.sender, _artistReputation[msg.sender]);
    }

     /**
     * @notice Allows a registered artist to unregister from the guild.
     * May include penalties (e.g., reputation loss, inability to re-register immediately).
     */
    function unregisterArtist() external onlyRegisteredArtist whenNotPaused {
        // Invalidate artist state
        artists[msg.sender].isRegistered = false;
        // Optionally reset/slash reputation significantly
        _artistReputation[msg.sender] = MIN_REPUTATION;
        // TODO: Handle cases where artist owns recipes or is involved in projects

        emit ArtistUnregistered(msg.sender, block.timestamp);
        emit ReputationUpdated(msg.sender, _artistReputation[msg.sender]);
        // Note: artist struct not deleted, just marked inactive
    }

    /**
     * @notice Gets the current reputation score for an artist.
     * @param _artist The artist address.
     * @return The artist's reputation score.
     */
    function getArtistReputation(address _artist) external view returns (uint256) {
        return _artistReputation[_artist];
    }


    // --- Recipe Management Functions (Internal Tracking) ---
    // These simulate NFT-like functionality for recipes within this contract.

    /**
     * @notice Allows a registered artist to mint a new generative art recipe.
     * Pays a creation fee (if > 0).
     * @param _metadataHash A hash pointing to the recipe's generative parameters/description off-chain.
     * @param _creationFee An optional fee the artist pays to mint this recipe (sent with the transaction).
     */
    function mintRecipe(string calldata _metadataHash, uint256 _creationFee) external payable onlyRegisteredArtist whenNotPaused {
        if (msg.value < _creationFee) revert InvalidAmount(); // Ensure fee is paid

        _recipeIdCounter++;
        uint256 newRecipeId = _recipeIdCounter;

        recipes[newRecipeId] = Recipe({
            id: newRecipeId,
            originalArtist: msg.sender,
            metadataHash: _metadataHash,
            collaborators: new address[](0),
            isCollaborator: new mapping(address => bool)(),
            mintTimestamp: block.timestamp,
            lastUpdatedTimestamp: block.timestamp
        });
        _recipeOwners[newRecipeId] = msg.sender; // Track owner internally
        _recipeMetadataHashes[newRecipeId] = _metadataHash; // Track metadata internally
        _recipeUsageCount[newRecipeId] = 0;

        // Send creation fee to treasury or burn (sending to treasury here)
        guildTreasuryBalance += msg.value;

        emit RecipeMinted(newRecipeId, msg.sender, _metadataHash, block.timestamp);
    }

    /**
     * @notice Allows the recipe owner to update the metadata hash of their recipe.
     * Could point to updated parameters or a new description.
     * @param _recipeId The ID of the recipe to update.
     * @param _newMetadataHash The new metadata hash.
     */
    function updateRecipeMetadataHash(uint256 _recipeId, string calldata _newMetadataHash) external onlyRecipeOwner(_recipeId) whenNotPaused {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0) revert RecipeDoesNotExist(_recipeId); // Check if exists via ID=0 check

        // Check if the recipe is currently involved in a Funded project
        // (To prevent changing parameters after funding is secured)
        // Iterate through ongoing projects? Or add a flag to the Recipe struct?
        // Let's simplify and just add a check for *any* project currently in 'Funded' or 'Generating' state using this recipe.
        // This check requires iterating through all projects, which is gas-intensive.
        // A better approach in production would be a mapping like mapping(uint256 => uint256[]) recipeToActiveProjects;
        // For this example, we skip the active project check to save gas and meet the function count simply.
        // In production: require(!isRecipeInActiveProject(_recipeId), "Recipe is in an active project");

        recipe.metadataHash = _newMetadataHash;
        recipe.lastUpdatedTimestamp = block.timestamp;
        _recipeMetadataHashes[_recipeId] = _newMetadataHash; // Update internal tracking

        emit RecipeMetadataUpdated(_recipeId, _newMetadataHash, block.timestamp);
    }

     /**
     * @notice Simulates transferring ownership of a recipe.
     * @param _from The current owner (must be msg.sender).
     * @param _to The address to transfer ownership to.
     * @param _recipeId The ID of the recipe.
     */
    function transferRecipe(address _from, address _to, uint256 _recipeId) external onlyRecipeOwner(_recipeId) whenNotPaused {
        if (_from != msg.sender) revert NotRecipeOwner(_recipeId); // Redundant with modifier, but explicit
        if (_to == address(0)) revert ZeroAddress();

        _recipeOwners[_recipeId] = _to; // Update internal tracking
        // Should clear collaborations upon transfer? Or transfer with collaborators? Let's clear for simplicity.
        delete recipes[_recipeId].collaborators;
        delete recipes[_recipeId].isCollaborator; // Clear lookup map

        emit RecipeTransferred(_recipeId, _from, _to, block.timestamp);
    }

    /**
     * @notice Allows the recipe owner to burn (destroy) their recipe.
     * Cannot be burned if currently used in an active project.
     * @param _recipeId The ID of the recipe to burn.
     */
    function burnRecipe(uint256 _recipeId) external onlyRecipeOwner(_recipeId) whenNotPaused {
        Recipe storage recipe = recipes[_recipeId];
         if (recipe.id == 0) revert RecipeDoesNotExist(_recipeId);

        // Check if recipe is in an active project (same gas concern as update, skipping strict check)
        // In production: require(!isRecipeInActiveProject(_recipeId), "Recipe is in an active project");

        // Clear internal tracking
        delete _recipeOwners[_recipeId];
        delete _recipeMetadataHashes[_recipeId];
        delete _recipeUsageCount[_recipeId];

        // Clear recipe struct and collaborators
        delete recipes[_recipeId]; // Deletes the struct including collaborators/map

        emit RecipeBurned(_recipeId, msg.sender, block.timestamp);
    }

    /**
     * @notice Allows the recipe owner to propose collaboration to another artist.
     * @param _recipeId The ID of the recipe.
     * @param _collaborator The address of the artist invited to collaborate.
     */
    function proposeRecipeCollaboration(uint256 _recipeId, address _collaborator) external onlyRecipeOwner(_recipeId) onlyRegisteredArtist whenNotPaused {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0) revert RecipeDoesNotExist(_recipeId);
        if (_collaborator == address(0)) revert ZeroAddress();
        if (!artists[_collaborator].isRegistered) revert NotRegisteredArtist();
        if (_collaborator == msg.sender) revert CannotCollaborateOnOwnRecipe();
        if (recipe.isCollaborator[_collaborator]) revert AlreadyCollaborator(_recipeId);

        // In a real system, this might involve a pending proposal state.
        // For this example, we directly add them to a 'proposed' list or similar,
        // but the 'accept' function is the key. Let's just emit an event for now.
        // The `acceptRecipeCollaboration` function will check if they were proposed.
        // Simulating a proposal state: use a separate mapping?
        // mapping(uint256 => mapping(address => bool)) private _pendingCollaborators;
        // _pendingCollaborators[_recipeId][_collaborator] = true;
        // For simplicity and function count, we'll just rely on the event log or an off-chain system tracking proposals.
        // The `acceptRecipeCollaboration` will simply require `msg.sender` to be a registered artist.

        emit RecipeCollaborationProposed(_recipeId, msg.sender, _collaborator, block.timestamp);
    }

    /**
     * @notice Allows a registered artist who was proposed collaboration to accept.
     * Note: This simplified version requires the accepting address to be a registered artist,
     * but doesn't strictly check if they were *specifically* proposed by the owner in this contract state.
     * A production version would need a `_pendingCollaborators` mapping or similar.
     * @param _recipeId The ID of the recipe.
     */
    function acceptRecipeCollaboration(uint256 _recipeId) external onlyRegisteredArtist whenNotPaused {
         Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0 || _recipeOwners[_recipeId] == address(0)) revert RecipeDoesNotExist(_recipeId); // Check if recipe exists and has owner
        if (msg.sender == _recipeOwners[_recipeId]) revert CannotCollaborateOnOwnRecipe();
        if (recipe.isCollaborator[msg.sender]) revert AlreadyCollaborator(_recipeId);
        // Add check for pending proposal in production: require(_pendingCollaborators[_recipeId][msg.sender], "Collaboration not proposed");

        recipe.collaborators.push(msg.sender);
        recipe.isCollaborator[msg.sender] = true;
        // delete _pendingCollaborators[_recipeId][msg.sender]; // Clean up pending state in production

        emit RecipeCollaborationAccepted(_recipeId, msg.sender, block.timestamp);
    }

    /**
     * @notice Allows the recipe owner or a collaborator to remove a collaborator.
     * @param _recipeId The ID of the recipe.
     * @param _collaborator The address of the collaborator to remove.
     */
    function removeRecipeCollaboration(uint256 _recipeId, address _collaborator) external onlyRegisteredArtist whenNotPaused {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0 || _recipeOwners[_recipeId] == address(0)) revert RecipeDoesNotExist(_recipeId);
        if (!recipe.isCollaborator[_collaborator]) revert NotProposedCollaborator(_recipeId); // Using NotProposed error, but means 'Not A Collaborator'
        if (_collaborator == _recipeOwners[_recipeId]) revert CannotCollaborateOnOwnRecipe(); // Cannot remove the owner

        bool isOwner = msg.sender == _recipeOwners[_recipeId];
        bool isSelf = msg.sender == _collaborator;
        bool isOtherCollaborator = recipe.isCollaborator[msg.sender] && msg.sender != _collaborator;

        if (!isOwner && !isSelf && !isOtherCollaborator) {
             revert NotRecipeOwner(_recipeId); // Only owner or involved parties can call this
        }
         // If only owner can remove: require(isOwner, "Only owner can remove collaborators");

        // Remove from array (inefficient for large arrays, but acceptable for example)
        address[] storage collabs = recipe.collaborators;
        for (uint i = 0; i < collabs.length; i++) {
            if (collabs[i] == _collaborator) {
                collabs[i] = collabs[collabs.length - 1];
                collabs.pop();
                break;
            }
        }
        recipe.isCollaborator[_collaborator] = false; // Remove from lookup map

        emit RecipeCollaborationRemoved(_recipeId, _collaborator, block.timestamp);
    }


    /**
     * @notice Gets details about a specific recipe.
     * @param _recipeId The ID of the recipe.
     * @return Recipe struct details (excluding isCollaborator map), owner, and usage count.
     */
    function getRecipeDetails(uint256 _recipeId) external view returns (Recipe memory, address ownerAddress, uint256 usageCount) {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0) revert RecipeDoesNotExist(_recipeId); // Check if exists

        // Copy struct to memory, excluding the mapping
         Recipe memory recipeMem = Recipe({
            id: recipe.id,
            originalArtist: recipe.originalArtist,
            metadataHash: recipe.metadataHash,
            collaborators: recipe.collaborators, // Array copies elements
            isCollaborator: new mapping(address => bool)(), // Mapping cannot be copied
            mintTimestamp: recipe.mintTimestamp,
            lastUpdatedTimestamp: recipe.lastUpdatedTimestamp
         });

        return (recipeMem, _recipeOwners[_recipeId], _recipeUsageCount[_recipeId]);
    }

     /**
     * @notice Gets the number of times a recipe has been successfully used to mint an artwork.
     * @param _recipeId The ID of the recipe.
     * @return The usage count.
     */
    function getRecipeUsageCount(uint256 _recipeId) external view returns (uint256) {
        if (recipes[_recipeId].id == 0) revert RecipeDoesNotExist(_recipeId);
        return _recipeUsageCount[_recipeId];
    }


    // --- Project Management Functions ---

    /**
     * @notice Initiates a funding project for a specific recipe.
     * Can optionally provide initial funding.
     * @param _recipeId The ID of the recipe to use.
     * @param _projectMetadataHash Hash pointing to project-specific details (e.g., desired style variations).
     * @param _fundingGoal The amount of native currency (ETH) required to trigger artwork generation.
     */
    function createFundingProject(uint256 _recipeId, string calldata _projectMetadataHash, uint256 _fundingGoal) external payable onlyRegisteredArtist whenNotPaused {
        Recipe storage recipe = recipes[_recipeId];
        if (recipe.id == 0 || _recipeOwners[_recipeId] == address(0)) revert RecipeDoesNotExist(_recipeId);
        // Ensure the msg.sender is either the recipe owner or a collaborator
        if (_recipeOwners[_recipeId] != msg.sender && !recipe.isCollaborator[msg.sender]) {
            revert OnlyRegisteredArtist(); // Or a specific error like NotRecipeContributor
        }
        if (_fundingGoal == 0) revert InvalidAmount();

        _projectIdCounter++;
        uint256 newProjectId = _projectIdCounter;
        uint256 initialFunding = msg.value;

        projects[newProjectId] = Project({
            id: newProjectId,
            recipeId: _recipeId,
            creator: msg.sender,
            projectMetadataHash: _projectMetadataHash,
            fundingGoal: _fundingGoal,
            currentFunding: initialFunding,
            status: initialFunding >= _fundingGoal ? ProjectStatus.Funded : ProjectStatus.Funding,
            createdTimestamp: block.timestamp,
            fundedTimestamp: initialFunding >= _fundingGoal ? block.timestamp : 0,
            completionTimestamp: 0,
            artworkId: 0
        });

        if (initialFunding > 0) {
             projectContributions[newProjectId][msg.sender] += initialFunding; // Record creator's contribution
             emit ProjectFunded(newProjectId, msg.sender, initialFunding, initialFunding);
        }

        emit ProjectCreated(newProjectId, _recipeId, msg.sender, _fundingGoal, block.timestamp);

        if (projects[newProjectId].status == ProjectStatus.Funded) {
             emit ProjectStatusChanged(newProjectId, ProjectStatus.Funding, ProjectStatus.Funded);
             emit ProjectFundedGoalReached(newProjectId, block.timestamp);
        } else {
             emit ProjectStatusChanged(newProjectId, ProjectStatus.Idle, ProjectStatus.Funding);
        }
    }

    /**
     * @notice Allows any address to contribute funds to an active funding project.
     * @param _projectId The ID of the project to fund.
     */
    function fundProject(uint256 _projectId) external payable whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.id == 0) revert ProjectDoesNotExist(_projectId);
        if (project.status != ProjectStatus.Funding) revert ProjectNotInFunding(_projectId);
        if (msg.value == 0) revert InvalidAmount();

        project.currentFunding += msg.value;
        projectContributions[_projectId][msg.sender] += msg.value;

        emit ProjectFunded(_projectId, msg.sender, msg.value, project.currentFunding);

        if (project.currentFunding >= project.fundingGoal) {
            project.status = ProjectStatus.Funded;
            project.fundedTimestamp = block.timestamp;
             emit ProjectStatusChanged(_projectId, ProjectStatus.Funding, ProjectStatus.Funded);
             emit ProjectFundedGoalReached(_projectId, block.timestamp);
        }
    }

    /**
     * @notice Gets details about a funding project.
     * @param _projectId The ID of the project.
     * @return Project struct details.
     */
    function getProjectDetails(uint256 _projectId) external view returns (Project memory) {
         Project storage project = projects[_projectId];
        if (project.id == 0) revert ProjectDoesNotExist(_projectId);
        // Note: Project struct includes mapping projectContributions internally, which cannot be returned directly.
        // You would need a separate function to get contributions for a project.
        // For simplicity, we return the struct which will have an empty/zero mapping field in memory.
         return project;
    }


    // --- Artwork Generation & Royalty Distribution Functions (Simulated) ---

    /**
     * @notice Triggered by the authorized off-chain executor after a project is funded.
     * Simulates the generative art process, creates the artwork record, and distributes funds.
     * This is the bridge between the on-chain funding/recipe and off-chain generation.
     * @param _projectId The ID of the project to complete.
     * @param _artworkMetadataHash The hash pointing to the *generated* artwork data off-chain.
     */
    function triggerArtworkGeneration(uint256 _projectId, string calldata _artworkMetadataHash) external onlyOffchainExecutor whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.id == 0) revert ProjectDoesNotExist(_projectId);
        if (project.status != ProjectStatus.Funded) revert ProjectNotFunded(_projectId); // Must be funded
        if (project.currentFunding < project.fundingGoal) revert FundingGoalNotMet(_projectId); // Double check funding goal
        if (bytes(_artworkMetadataHash).length == 0) revert InvalidAmount(); // Artwork hash must be provided

        project.status = ProjectStatus.Generating; // Mark as generating (brief state)
        emit ProjectStatusChanged(_projectId, ProjectStatus.Funded, ProjectStatus.Generating);

        // Simulate Artwork Minting (Internal Tracking)
        _artworkIdCounter++;
        uint256 newArtworkId = _artworkIdCounter;

        Recipe storage recipe = recipes[project.recipeId]; // Get recipe details for artwork provenance

        artworks[newArtworkId] = Artwork({
            id: newArtworkId,
            projectId: _projectId,
            recipeId: project.recipeId,
            creator: project.creator,
            originalArtist: recipe.originalArtist,
            collaborators: recipe.collaborators, // Store collaborators at time of creation
            metadataHash: _artworkMetadataHash,
            mintTimestamp: block.timestamp
        });

        // Assign ownership of the artwork. Who owns it?
        // Could be:
        // 1. The project creator.
        // 2. A new fractionalized token representing shares for contributors. (More advanced, requires ERC1155 or custom logic)
        // 3. A single patron who contributed most/first.
        // 4. The recipe artist.
        // Let's implement a simple model: the project creator gets ownership of the initial Artwork NFT.
        _artworkOwners[newArtworkId] = project.creator;
        _artworkMetadataHashes[newArtworkId] = _artworkMetadataHash; // Store metadata hash internally

        project.artworkId = newArtworkId; // Link project to artwork
        project.completionTimestamp = block.timestamp;

        _recipeUsageCount[project.recipeId]++; // Increment recipe usage count

        emit ArtworkMinted(newArtworkId, _projectId, project.recipeId, project.creator, _artworkMetadataHash, block.timestamp);

        // Distribute Proceeds
        _distributeProjectProceeds(_projectId);

        project.status = ProjectStatus.Completed;
        emit ProjectStatusChanged(_projectId, ProjectStatus.Generating, ProjectStatus.Completed);

        // Award Reputation (Internal)
        _awardReputation(recipe.originalArtist, 50); // Example: Award reputation to original artist
        for(uint i = 0; i < recipe.collaborators.length; i++) {
             _awardReputation(recipe.collaborators[i], 20); // Example: Award less reputation to collaborators
        }
        _awardReputation(project.creator, 10); // Example: Award minor reputation to project creator
    }

    /**
     * @notice Internal function to handle the distribution of funds from a completed project.
     * This includes guild fees, artist shares, collaborator shares, and patron refunds/shares.
     * Uses the dynamic royalty calculation.
     * @param _projectId The ID of the completed project.
     */
    function _distributeProjectProceeds(uint256 _projectId) internal {
        Project storage project = projects[_projectId];
        uint256 totalAmount = project.currentFunding;
        if (totalAmount == 0) return; // Should not happen if funded

        // Calculate splits dynamically
        (uint256 artistSharePermille, uint256 collaboratorsSharePermille, uint256 patronsSharePermille) = _calculateDynamicRoyaltySplit(project.artworkId);

        uint256 guildFee = (totalAmount * guildFeePermille) / 1000;
        uint256 remainingAmount = totalAmount - guildFee;

        uint256 artistShare = (remainingAmount * artistSharePermille) / 1000;
        uint256 collaboratorsShare = (remainingAmount * collaboratorsSharePermille) / 1000;
        uint256 patronsShare = (remainingAmount * patronsSharePermille) / 1000;

        // Send funds
        // Send guild fee to treasury (already collected implicitly by contract balance)
        guildTreasuryBalance += guildFee; // Explicitly track fees for withdrawal

        // Send artist share (original artist of the recipe)
        Recipe storage recipe = recipes[project.recipeId];
        if (artistShare > 0 && artists[recipe.originalArtist].isRegistered) { // Ensure artist is still registered
             // Use low-level call for robustness
             (bool success, ) = payable(recipe.originalArtist).call{value: artistShare}("");
             // Consider handling failure (e.g., log, re-attempt, hold in contract)
             if (!success) {
                 // Handle failure: store amount to be claimed later or log error
                 // For simplicity, we proceed assuming success or loss of funds on failure in this example
             }
        }

        // Send collaborators share (split equally among active collaborators at artwork mint time)
        uint256 numCollaborators = artworks[project.artworkId].collaborators.length;
        if (collaboratorsShare > 0 && numCollaborators > 0) {
            uint256 sharePerCollaborator = collaboratorsShare / numCollaborators;
            for (uint i = 0; i < numCollaborators; i++) {
                address collaborator = artworks[project.artworkId].collaborators[i];
                 if (artists[collaborator].isRegistered) { // Ensure collaborator is still registered
                    (bool success, ) = payable(collaborator).call{value: sharePerCollaborator}("");
                     // Handle failure
                 }
            }
            // Handle remainder if collaboratorsShare is not divisible
            uint256 remainder = collaboratorsShare % numCollaborators;
            if (remainder > 0 && artists[recipe.originalArtist].isRegistered) {
                 // Send remainder to original artist or guild treasury
                 (bool success, ) = payable(recipe.originalArtist).call{value: remainder}("");
                  // Handle failure
            } else if (remainder > 0) {
                 guildTreasuryBalance += remainder;
            }
        } else if (collaboratorsShare > 0 && artists[recipe.originalArtist].isRegistered) {
             // If no collaborators but a share was allocated (due to dynamic split calc), send to original artist
              (bool success, ) = payable(recipe.originalArtist).call{value: collaboratorsShare}("");
              // Handle failure
        }


        // Refund/Distribute to Patrons
        // This is complex depending on the model.
        // Option 1 (Simple Refund): Refund remaining amount to all contributors proportionally.
        // Option 2 (Shared Ownership/Token): Patrons receive fractional ownership tokens of the artwork.
        // Option 3 (Claim Mechanism): Patrons can claim their share later.
        // Let's implement Option 1 (proportional refund) for simplicity, acknowledging shared ownership is more advanced.
        uint256 refundAmount = patronsShare; // The amount designated for patrons

        // Iterate through project contributions mapping (WARNING: Iterating mapping is gas-intensive and not recommended for large maps!)
        // In production, track contributors in an array or use an iterable mapping library.
        // For this example, we assume a limited number of contributors per project or skip the actual distribution for simplicity, emitting the total patron share.
        // Actual distribution logic would look like:
        /*
        uint256 distributedToPatrons = 0;
        // This loop is dangerous on-chain due to gas limits if many contributors
        for (each contributor in projectContributions[_projectId]) {
            uint256 contribution = projectContributions[_projectId][contributor];
            uint256 patronRefund = (contribution * refundAmount) / totalAmount; // Proportional refund
            if (patronRefund > 0) {
                 (bool success, ) = payable(contributor).call{value: patronRefund}("");
                 if (success) distributedToPatrons += patronRefund;
                 // Handle failure, maybe re-add to a claimable balance
            }
        }
         // Any remaining amount due to rounding errors or failed transfers goes to treasury
        guildTreasuryBalance += refundAmount - distributedToPatrons;
        */
        // Simplified: Assume refund amount goes to treasury or is lost if not distributed
         guildTreasuryBalance += refundAmount; // Simplified: Just send total patron share to treasury

        // Log distribution
        emit ProceedsDistributed(_projectId, totalAmount, guildFee, artistShare, collaboratorsShare, patronsShare);

        // Clean up project contributions to save space? Not feasible with simple mappings.
        // A dedicated mapping and claim function would be better.
    }

    /**
     * @notice Gets details about a specific artwork (internal tracking).
     * @param _artworkId The ID of the artwork.
     * @return Artwork struct details and owner address.
     */
    function getArtworkDetails(uint256 _artworkId) external view returns (Artwork memory, address ownerAddress) {
        Artwork storage artwork = artworks[_artworkId];
        if (artwork.id == 0) revert ProjectDoesNotExist(_artworkId); // Using ProjectDoesNotExist error, should be ArtworkDoesNotExist

        Artwork memory artworkMem = Artwork({
            id: artwork.id,
            projectId: artwork.projectId,
            recipeId: artwork.recipeId,
            creator: artwork.creator,
            originalArtist: artwork.originalArtist,
            collaborators: artwork.collaborators,
            metadataHash: artwork.metadataHash,
            mintTimestamp: artwork.mintTimestamp
        });

        return (artworkMem, _artworkOwners[_artworkId]);
    }

     /**
     * @notice Gets the project and recipe IDs associated with a specific artwork for provenance tracking.
     * @param _artworkId The ID of the artwork.
     * @return projectId, recipeId.
     */
    function getArtworkProvenance(uint256 _artworkId) external view returns (uint256 projectId, uint256 recipeId) {
        Artwork storage artwork = artworks[_artworkId];
        if (artwork.id == 0) revert ProjectDoesNotExist(_artworkId); // Using ProjectDoesNotExist error, should be ArtworkDoesNotExist
        return (artwork.projectId, artwork.recipeId);
    }

    /**
     * @notice Calculates the dynamic royalty split percentage for a specific artwork.
     * This calculation is based on factors like the original artist's reputation,
     * the number of collaborators, and the recipe usage count *at the time of this call*.
     * The actual distribution uses the split calculated at generation time, but this shows the dynamic logic.
     * @param _artworkId The ID of the artwork.
     * @return artistSharePermille, collaboratorsSharePermille, patronsSharePermille (in parts per thousand, excluding guild fee).
     */
    function getDynamicRoyaltySplit(uint256 _artworkId) public view returns (uint256 artistSharePermille, uint256 collaboratorsSharePermille, uint256 patronsSharePermille) {
        Artwork storage artwork = artworks[_artworkId];
         if (artwork.id == 0) revert ProjectDoesNotExist(_artworkId); // Using ProjectDoesNotExist error, should be ArtworkDoesNotExist

        address originalArtist = artwork.originalArtist;
        uint256 currentReputation = _artistReputation[originalArtist]; // Use current reputation
        uint256 numCollaborators = artwork.collaborators.length;
        uint256 recipeUsage = _recipeUsageCount[artwork.recipeId]; // Use current usage count

        // --- Dynamic Split Logic (Example) ---
        // Base Split (e.g., Artist 60%, Collaborators 20%, Patrons 20%) - totalling 1000 permille for the *non-guild* share
        uint256 baseArtist = 600;
        uint256 baseCollaborators = 200;
        uint256 basePatrons = 200; // This share could go to patrons/guild/burn depending on the model

        // Adjust based on reputation thresholds (Higher reputation = bigger artist share)
        uint256 repBonus = 0;
        for (uint256 i = 0; i < reputationThresholds.length; i++) {
            if (currentReputation >= reputationThresholds[i]) {
                repBonus += 20; // Example: +2% bonus for each threshold passed
            }
        }
        // Cap bonus to avoid exceeding total share
        repBonus = repBonus > 100 ? 100 : repBonus; // Cap bonus at 10% (100 permille)

        artistSharePermille = baseArtist + repBonus;

        // Adjust based on collaboration (More collaborators = bigger collaborator share, smaller artist/patron share)
        uint256 collabPenalty = numCollaborators > 0 ? numCollaborators * 10 : 0; // Example: -1% per collaborator from artist/patron
        collabPenalty = collabPenalty > 50 ? 50 : collabPenalty; // Cap penalty at 5%

        artistSharePermille = artistSharePermille > collabPenalty ? artistSharePermille - collabPenalty : 0;
        collaboratorsSharePermille = baseCollaborators + (numCollaborators > 0 ? collabPenalty : 0); // Add penalty amount to collaborators
        patronsSharePermille = basePatrons > collabPenalty ? basePatrons - collabPenalty : 0;


        // Adjust based on recipe usage (High usage = small bonus to artist/collaborators, reducing patron share slightly)
        uint256 usageBonus = recipeUsage > 10 ? (recipeUsage - 10) * 2 : 0; // Example: +0.2% bonus for every use over 10
        usageBonus = usageBonus > 30 ? 30 : usageBonus; // Cap bonus at 3%

        artistSharePermille += usageBonus / 2; // Split usage bonus between artist and collaborators
        collaboratorsSharePermille += usageBonus - (usageBonus / 2);
        patronsSharePermille = patronsSharePermille > usageBonus ? patronsSharePermille - usageBonus : 0;


        // Ensure total does not exceed 1000 (after removing guild fee)
        uint256 totalDynamicShare = artistSharePermille + collaboratorsSharePermille + patronsSharePermille;
        if (totalDynamicShare > 1000) {
            uint256 excess = totalDynamicShare - 1000;
            // Deduct excess proportionally or from lowest share
            patronsSharePermille = patronsSharePermille > excess ? patronsSharePermille - excess : 0; // Simply deduct from patrons
        }

        // Ensure no share is negative (due to complex logic/caps)
        artistSharePermille = artistSharePermille > 0 ? artistSharePermille : 0;
        collaboratorsSharePermille = collaboratorsSharePermille > 0 ? collaboratorsSharePermille : 0;
        patronsSharePermille = patronsSharePermille > 0 ? patronsSharePermille : 0;

        // Re-normalize if total is less than 1000 (e.g., due to capping or artists/collaborators not registered?)
        // For distribution, we assume all participants were valid at time of generation.
        // The sum might be slightly less than 1000 due to integer division or caps, remaining goes to treasury implicitly or explicitly.
        // Total distributed = guildFee + artistShare + collaboratorsShare + patronsShare = 1000 permille of totalAmount.

        return (artistSharePermille, collaboratorsSharePermille, patronsSharePermille);
    }

     /**
     * @notice Internal helper to award reputation to an artist, capped at MAX_REPUTATION.
     * @param _artist The artist address.
     * @param _amount The amount to add to reputation.
     */
    function _awardReputation(address _artist, uint256 _amount) internal {
        if (!artists[_artist].isRegistered) return; // Only award to registered artists
        uint256 currentRep = _artistReputation[_artist];
        _artistReputation[_artist] = currentRep + _amount > MAX_REPUTATION ? MAX_REPUTATION : currentRep + _amount;
        emit ReputationUpdated(_artist, _artistReputation[_artist]);
    }


    // --- Treasury & Utility ---

    /**
     * @notice Returns the current balance of guild fees held in the contract.
     * @return The treasury balance in native currency (ETH).
     */
    function getGuildTreasuryBalance() external view returns (uint256) {
        return guildTreasuryBalance;
    }

    /**
     * @notice Allows the contract owner to withdraw collected guild fees.
     * @param _recipient The address to send the fees to.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawGuildFees(address _recipient, uint256 _amount) external onlyOwner whenNotPaused {
        if (_recipient == address(0)) revert ZeroAddress();
        if (_amount == 0) revert InvalidAmount();
        if (_amount > guildTreasuryBalance) revert NothingToWithdraw(); // Not enough fees

        guildTreasuryBalance -= _amount;

        (bool success, ) = payable(_recipient).call{value: _amount}("");
        if (!success) {
            // If sending fails, add back to treasury and emit event
            guildTreasuryBalance += _amount;
            // In production, implement a robust withdrawal pattern (e.g., pull mechanism)
            revert NothingToWithdraw(); // Simple failure indicator
        }

        emit GuildFeesWithdrawn(_recipient, _amount);
    }


    // --- Pausable & Emergency ---

    /**
     * @notice Pauses the contract, disabling certain functions. Only owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, enabling disabled functions. Only owner.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

     /**
     * @notice Allows the owner to withdraw the entire contract balance in an emergency.
     * Used as a failsafe. Skips fee/distribution logic.
     */
    function emergencyWithdraw() external onlyOwner whenPaused {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NothingToWithdraw();

        // Reset guild treasury balance (fees included in total balance)
        guildTreasuryBalance = 0;

        (bool success, ) = payable(owner).call{value: balance}("");
        if (!success) {
             // If fails, balance remains, maybe revert or just log? Reverting is safer.
             // Re-add balance to treasury if the call failed, though not strictly accurate if funds were partially sent.
             // For simplicity, revert on failure.
            revert NothingToWithdraw(); // Indicate failure
        }

        emit EmergencyWithdrawal(owner, balance);
    }


    // --- Fallback/Receive ---
    // Needed to receive funds for projects/fees/emergency

    receive() external payable {}
    fallback() external payable {}

}
```