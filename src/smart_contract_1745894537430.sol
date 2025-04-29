Okay, let's design a smart contract for a "Decentralized Autonomous Artisan Guild" (DAAG). This contract will manage guild membership (via NFTs), track artisan reputation and skills, manage collaborative projects and quests, and feature a unique "Mystic Crafting" system where artisans can combine digital assets (like other NFTs and tokens) based on their skills to create new, unique output items (also potentially NFTs).

This design incorporates:
*   **NFTs:** For membership and potentially crafting output.
*   **On-Chain Reputation/Skill System:** Dynamic state based on performance.
*   **Structured Workflows:** Projects and Quests with defined states.
*   **Resource Management:** Treasury and token/NFT inputs for crafting.
*   **Dynamic Configuration:** Adjustable parameters.
*   **Inter-contract interaction:** Assumes external ERC20 and ERC721 contracts for tokens and NFTs.

---

**Outline and Function Summary**

**Contract Name:** DecentralizedAutonomousArtisanGuild

**Brief Description:** A smart contract managing a decentralized guild of artisans. It handles membership via unique NFTs, tracks artisan reputation and skill points earned through completing on-chain projects and quests, facilitates collaboration, manages a treasury, and includes a unique "Mystic Crafting" system allowing skilled artisans to combine digital assets into new items.

**Key Concepts:**
*   NFT-based Membership (Assumes external Membership NFT contract).
*   On-chain Reputation and Skill Points (Dynamic state).
*   Project & Quest Management (On-chain workflow).
*   Mystic Crafting (Combining assets to create new items - Assumes external output NFT contract).
*   Treasury Management.
*   Configurable Guild Parameters.

**Dependencies:**
*   IERC20 (For skill token, bounty payments, crafting costs).
*   IERC721 (For membership NFTs, required crafting items, output crafted items).

**State Variables Summary:**
*   `owner`: Address with initial administrative privileges.
*   `treasuryAddress`: Address holding guild funds/assets.
*   `membershipNFT`: Address of the ERC721 contract for membership tokens.
*   `skillToken`: Address of the ERC20 contract representing artisan skill points/token.
*   `outputItemNFT`: Address of the ERC721 contract for crafted output items.
*   `artisanInfo`: Mapping `address => Artisan` struct storing member details.
*   `projectCounter`: Counter for unique project IDs.
*   `projects`: Mapping `uint => Project` struct storing project details.
*   `questCounter`: Counter for unique quest IDs.
*   `quests`: Mapping `uint => Quest` struct storing quest details.
*   `craftingRecipeCounter`: Counter for unique recipe IDs.
*   `craftingRecipes`: Mapping `uint => Recipe` struct storing crafting recipe details.
*   `guildConfig`: Struct holding adjustable configuration parameters.

**Structs and Enums Summary:**
*   `Artisan`: Details about a guild member (active status, join time, reputation, skill points, completed work, membership NFT ID).
*   `Project`: Details about a significant work commission (creator, title, description, bounty, status, assignee, submission hash, evaluation score).
*   `Quest`: Details about a smaller task (proposer, title, description, reward, status, assignee).
*   `Recipe`: Details for crafting (creator, required skill points, required ERC20 tokens, required ERC721 items, expected output item ID/type, duration).
*   `GuildConfig`: Adjustable parameters (min reputation for actions, reputation/skill rewards, fee percentages).
*   `ProjectStatus`: Enum for project lifecycle (Open, Assigned, Submitted, Evaluated, Completed, Failed).
*   `QuestStatus`: Enum for quest lifecycle (Open, Accepted, Completed, Verified).

**Function Summary (Minimum 20 Functions):**

**Initialization & Configuration:**
1.  `constructor`: Sets initial owner and treasury address.
2.  `initializeGuild`: Sets addresses for dependent NFT and token contracts.
3.  `updateGuildConfig`: Allows owner/governors to adjust guild parameters.
4.  `getGuildConfig`: Views current guild configuration.

**Membership Management:**
5.  `requestMembership`: Allows an address to request to join the guild (might have prerequisites).
6.  `approveMembershipRequest`: Owner/Governor approves a membership request and triggers minting of a membership NFT.
7.  `renounceMembership`: Allows an artisan to leave the guild.
8.  `isArtisanActive`: Checks if an address is a currently active guild member.
9.  `getArtisanInfo`: Retrieves detailed information about an artisan.

**Reputation & Skill System:**
10. `getArtisanReputation`: Views an artisan's current reputation score.
11. `getArtisanSkillPoints`: Views an artisan's current skill points.
12. `_updateArtisanStats`: (Internal) Handles updates to reputation and skill points upon project/quest completion.

**Project Management:**
13. `proposeProject`: Allows a qualified address to propose a new project with a bounty.
14. `assignProject`: Owner/Governor assigns an open project to an artisan.
15. `submitProject`: Assigned artisan submits their work (e.g., IPFS hash).
16. `evaluateProject`: Creator/Owner/Governor evaluates a submitted project, determines outcome, releases bounty, and updates stats.
17. `cancelProject`: Creator/Owner/Governor cancels a project.
18. `getProjectDetails`: Views details of a specific project.
19. `getArtisanProjects`: Views projects assigned to a specific artisan.

**Quest Management:**
20. `createQuest`: Allows a qualified address to create a simpler quest with rewards.
21. `acceptQuest`: Artisan accepts an open quest.
22. `completeQuest`: Artisan marks a quest as completed.
23. `verifyQuestCompletion`: Owner/Governor verifies quest completion and distributes rewards/updates stats.
24. `getQuestDetails`: Views details of a specific quest.

**Mystic Crafting System:**
25. `proposeCraftingRecipe`: Allows a qualified artisan to propose a new crafting recipe.
26. `approveCraftingRecipe`: Owner/Governor approves a proposed recipe, making it available.
27. `craftItem`: Allows an artisan to craft an item using an approved recipe, consuming required assets and potentially triggering output NFT minting.
28. `getCraftingRecipe`: Views details of a specific crafting recipe.

**Treasury & Finance:**
29. `depositToTreasury`: Allows sending funds (ETH/tokens) to the guild treasury.
30. `withdrawFromTreasury`: Owner/Governor withdraws funds from the treasury (for bounties, operations).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive NFTs safely

// Outline and Function Summary are above the code block.

contract DecentralizedAutonomousArtisanGuild is Ownable, ERC721Holder {
    // --- State Variables ---

    address public treasuryAddress; // Address where guild funds/assets are held
    address public membershipNFT; // Address of the ERC721 contract for membership tokens
    address public skillToken; // Address of the ERC20 contract for skill points/token
    address public outputItemNFT; // Address of the ERC721 contract for crafted output items

    struct GuildConfig {
        uint256 minReputationToProposeProject;
        uint256 minReputationToCreateQuest;
        uint256 minSkillPointsToCraft;
        uint256 projectCompletionReputationBoost;
        uint256 projectCompletionSkillPointsBoost;
        uint256 questCompletionReputationBoost;
        uint256 questCompletionSkillPointsBoost;
        uint256 projectEvaluationThreshold; // Score required for success
        uint256 recipeApprovalThreshold; // Reputation required to approve recipe (if not owner)
        uint256 membershipApprovalFee; // Cost to request membership (example)
    }
    GuildConfig public guildConfig;

    enum ProjectStatus { Open, Assigned, Submitted, Evaluated, Completed, Failed }
    enum QuestStatus { Open, Accepted, Completed, Verified }

    struct Artisan {
        bool isActive;
        uint256 joinTime;
        uint256 reputationScore; // Earned through completing projects/quests
        uint256 skillPoints; // Earned through work, required for crafting
        uint256 completedProjects;
        uint256 completedQuests;
        uint256 membershipTokenId; // The ID of their membership NFT
        uint256 lastActivity; // Timestamp of last significant interaction
    }
    mapping(address => Artisan) public artisanInfo;

    struct Project {
        address creator;
        string title;
        string description;
        uint256 bountyAmount; // In ETH or tokens
        address bountyToken; // Address of the bounty token (0x0 for ETH)
        ProjectStatus status;
        address assignee; // Artisan assigned to the project
        string submissionHash; // e.g., IPFS hash of completed work
        int256 evaluationScore; // Score given during evaluation (e.g., -10 to 10)
        uint256 creationTime;
        uint256 completionTime;
    }
    uint256 public projectCounter;
    mapping(uint256 => Project) public projects;

    struct Quest {
        address proposer;
        string title;
        string description;
        uint256 rewardAmount; // In tokens or ETH
        address rewardToken; // Address of reward token (0x0 for ETH)
        uint256 rewardReputation;
        uint256 rewardSkillPoints;
        QuestStatus status;
        address assignee;
        uint256 creationTime;
    }
    uint256 public questCounter;
    mapping(uint256 => Quest) public quests;

    struct Recipe {
        address creator; // Artisan who proposed the recipe
        bool isApproved;
        string name;
        string description;
        uint256 requiredSkillPoints;
        uint256[] requiredTokenAmounts; // Amounts corresponding to requiredTokens
        address[] requiredTokens; // Addresses of required ERC20 tokens
        uint256[] requiredItemTokenIds; // Specific IDs of required NFTs (if applicable, e.g., unique crafting components)
        address[] requiredItemNFTs; // Addresses of required ERC721 contracts
        uint256 expectedOutputTokenId; // Identifier for the output item type (e.g., ID in outputItemNFT contract)
        uint256 duration; // Time required to "craft" (optional, could be instant)
        uint256 creationTime;
    }
    uint256 public craftingRecipeCounter;
    mapping(uint256 => Recipe) public craftingRecipes;

    // --- Events ---

    event Initialized(address indexed owner, address indexed treasury);
    event GuildConfigUpdated(address indexed updater);
    event MembershipRequested(address indexed requester);
    event MembershipApproved(address indexed member, uint256 tokenId);
    event MembershipRenounced(address indexed member);
    event ProjectProposed(uint256 indexed projectId, address indexed creator, address indexed bountyToken, uint256 bountyAmount);
    event ProjectAssigned(uint256 indexed projectId, address indexed assignee);
    event ProjectSubmitted(uint256 indexed projectId, address indexed submitter, string submissionHash);
    event ProjectEvaluated(uint256 indexed projectId, int256 evaluationScore, ProjectStatus newStatus);
    event ProjectCompleted(uint256 indexed projectId, address indexed assignee, uint256 finalBountyAmount);
    event ProjectFailed(uint256 indexed projectId, address indexed assignee);
    event ProjectCancelled(uint256 indexed projectId);
    event QuestCreated(uint256 indexed questId, address indexed proposer);
    event QuestAccepted(uint256 indexed questId, address indexed assignee);
    event QuestCompleted(uint256 indexed questId, address indexed completer);
    event QuestVerified(uint256 indexed questId, address indexed assignee);
    event RecipeProposed(uint256 indexed recipeId, address indexed creator);
    event RecipeApproved(uint256 indexed recipeId, address indexed approver);
    event ItemCrafted(uint256 indexed recipeId, address indexed crafter, uint256 outputItemId);
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);
    event SkillPointsUpdated(address indexed artisan, uint256 newSkillPoints);
    event ReputationUpdated(address indexed artisan, uint256 newReputation);

    // --- Modifiers ---

    modifier onlyArtisan() {
        require(artisanInfo[msg.sender].isActive, "DAAG: Not an active artisan");
        _;
    }

    modifier onlyProjectAssignee(uint256 _projectId) {
        require(projects[_projectId].assignee == msg.sender, "DAAG: Not the project assignee");
        _;
    }

    modifier onlyQuestAssignee(uint256 _questId) {
        require(quests[_questId].assignee == msg.sender, "DAAG: Not the quest assignee");
        _;
    }

    modifier onlyProjectCreatorOrOwner(uint256 _projectId) {
        require(projects[_projectId].creator == msg.sender || owner() == msg.sender, "DAAG: Not project creator or owner");
        _;
    }

    modifier onlyQuestProposerOrOwner(uint256 _questId) {
        require(quests[_questId].proposer == msg.sender || owner() == msg.sender, "DAAG: Not quest proposer or owner");
        _;
    }

    modifier onlyApprovedRecipe(uint256 _recipeId) {
        require(craftingRecipes[_recipeId].isApproved, "DAAG: Recipe not approved");
        _;
    }

    // --- Constructor ---

    constructor(address _treasuryAddress) Ownable(msg.sender) {
        require(_treasuryAddress != address(0), "DAAG: Treasury address cannot be zero");
        treasuryAddress = _treasoryAddress;
        projectCounter = 1; // Start IDs from 1
        questCounter = 1;
        craftingRecipeCounter = 1;

        // Set some initial default configurations
        guildConfig = GuildConfig({
            minReputationToProposeProject: 100,
            minReputationToCreateQuest: 50,
            minSkillPointsToCraft: 0, // Default, recipes override
            projectCompletionReputationBoost: 50,
            projectCompletionSkillPointsBoost: 20,
            questCompletionReputationBoost: 10,
            questCompletionSkillPointsBoost: 5,
            projectEvaluationThreshold: 5, // Score > 5 is successful
            recipeApprovalThreshold: 200, // Reputation needed to vote/approve recipes
            membershipApprovalFee: 0 // Example: 0 ETH or token amount
        });

        emit Initialized(msg.sender, treasuryAddress);
    }

    // --- Initialization & Configuration Functions ---

    /// @notice Initializes the addresses of dependent token and NFT contracts.
    /// @param _membershipNFT Address of the ERC721 membership contract.
    /// @param _skillToken Address of the ERC20 skill token contract.
    /// @param _outputItemNFT Address of the ERC721 crafted item contract.
    function initializeGuild(address _membershipNFT, address _skillToken, address _outputItemNFT) public onlyOwner {
        require(membershipNFT == address(0), "DAAG: Membership NFT already initialized");
        require(skillToken == address(0), "DAAG: Skill token already initialized");
        require(outputItemNFT == address(0), "DAAG: Output item NFT already initialized");
        require(_membershipNFT != address(0), "DAAG: Membership NFT address cannot be zero");
        require(_skillToken != address(0), "DAAG: Skill token address cannot be zero");
        require(_outputItemNFT != address(0), "DAAG: Output item NFT address cannot be zero");

        membershipNFT = _membershipNFT;
        skillToken = _skillToken;
        outputItemNFT = _outputItemNFT;
    }

    /// @notice Updates various configuration parameters for the guild.
    /// Can only be called by the contract owner (or future governance).
    /// @param _config The new GuildConfig struct.
    function updateGuildConfig(GuildConfig calldata _config) public onlyOwner {
        guildConfig = _config;
        emit GuildConfigUpdated(msg.sender);
    }

    /// @notice Retrieves the current guild configuration parameters.
    /// @return The current GuildConfig struct.
    function getGuildConfig() public view returns (GuildConfig memory) {
        return guildConfig;
    }

    // --- Membership Management Functions ---

    /// @notice Allows an address to submit a request to join the guild.
    /// May require payment of a membership fee.
    function requestMembership() public payable {
        require(!artisanInfo[msg.sender].isActive, "DAAG: Already an active artisan");
        // Optional: require msg.value == guildConfig.membershipApprovalFee or require token transfer
        emit MembershipRequested(msg.sender);
        // In a real DAO, this would likely trigger a proposal/vote.
        // Here, we just emit the event and expect `approveMembershipRequest` to be called.
    }

    /// @notice Approves a pending membership request and mints the membership NFT.
    /// Can only be called by the owner (or future governance).
    /// Assumes the membershipNFT contract has a `safeMint(address to, uint256 tokenId)` or similar function callable by this contract.
    /// @param _member The address requesting membership.
    /// @param _tokenId The unique ID for the membership NFT to mint for this member.
    function approveMembershipRequest(address _member, uint256 _tokenId) public onlyOwner {
        require(!artisanInfo[_member].isActive, "DAAG: Member is already active");
        require(membershipNFT != address(0), "DAAG: Membership NFT contract not set");
        // Optional: Check if a request from _member exists (if `requestMembership` stored requests)

        // Call the external membership NFT contract to mint the token
        IERC721(membershipNFT).safeMint(_member, _tokenId);

        artisanInfo[_member] = Artisan({
            isActive: true,
            joinTime: block.timestamp,
            reputationScore: 0,
            skillPoints: 0,
            completedProjects: 0,
            completedQuests: 0,
            membershipTokenId: _tokenId,
            lastActivity: block.timestamp
        });

        emit MembershipApproved(_member, _tokenId);
    }

    /// @notice Allows an artisan to renounce their membership.
    /// This will burn or transfer their membership NFT.
    /// Assumes the membershipNFT contract allows burning/transferring by the token owner or approved address.
    function renounceMembership() public onlyArtisan {
        address member = msg.sender;
        uint256 tokenId = artisanInfo[member].membershipTokenId;

        artisanInfo[member].isActive = false;
        // Reset stats? Or keep historical record? Keeping for history.
        // artisanInfo[member].reputationScore = 0;
        // artisanInfo[member].skillPoints = 0;
        artisanInfo[member].membershipTokenId = 0; // Invalidate

        // Call the external membership NFT contract to burn or transfer the token
        // Example: Burning the token
        IERC721(membershipNFT).burn(tokenId);
        // Example: Transferring to a dead address
        // IERC721(membershipNFT).safeTransferFrom(member, address(0), tokenId);

        emit MembershipRenounced(member);
    }

    /// @notice Checks if a given address is currently an active artisan.
    /// @param _addr The address to check.
    /// @return bool True if the address is an active artisan, false otherwise.
    function isArtisanActive(address _addr) public view returns (bool) {
        return artisanInfo[_addr].isActive;
    }

    /// @notice Retrieves the detailed information struct for a given artisan address.
    /// @param _artisan Address of the artisan.
    /// @return The Artisan struct.
    function getArtisanInfo(address _artisan) public view returns (Artisan memory) {
        require(artisanInfo[_artisan].isActive, "DAAG: Address is not an active artisan");
        return artisanInfo[_artisan];
    }

    // --- Reputation & Skill System Functions ---

    /// @notice Views the current reputation score of an artisan.
    /// @param _artisan Address of the artisan.
    /// @return uint256 The artisan's reputation score.
    function getArtisanReputation(address _artisan) public view returns (uint256) {
        require(artisanInfo[_artisan].isActive, "DAAG: Address is not an active artisan");
        return artisanInfo[_artisan].reputationScore;
    }

    /// @notice Views the current skill points of an artisan.
    /// @param _artisan Address of the artisan.
    /// @return uint256 The artisan's skill points.
    function getArtisanSkillPoints(address _artisan) public view returns (uint256) {
        require(artisanInfo[_artisan].isActive, "DAAG: Address is not an active artisan");
        return artisanInfo[_artisan].skillPoints;
    }

    /// @dev Internal function to update an artisan's stats (reputation and skill points).
    /// @param _artisan The artisan's address.
    /// @param _reputationDelta Change in reputation (can be positive or negative).
    /// @param _skillPointsDelta Change in skill points.
    function _updateArtisanStats(address _artisan, int256 _reputationDelta, int256 _skillPointsDelta) internal {
        Artisan storage artisan = artisanInfo[_artisan];
        // Ensure reputation doesn't go below zero
        artisan.reputationScore = uint256(int256(artisan.reputationScore) + _reputationDelta > 0 ? int256(artisan.reputationScore) + _reputationDelta : 0);
        // Ensure skill points don't go below zero
        artisan.skillPoints = uint256(int256(artisan.skillPoints) + _skillPointsDelta > 0 ? int256(artisan.skillPoints) + _skillPointsDelta : 0);
        artisan.lastActivity = block.timestamp;

        emit ReputationUpdated(_artisan, artisan.reputationScore);
        emit SkillPointsUpdated(_artisan, artisan.skillPoints);
    }

    // --- Project Management Functions ---

    /// @notice Allows a qualified address to propose a new project.
    /// Requires minimum reputation or owner privilege. Bounty is sent to the treasury upon creation.
    /// @param _title Title of the project.
    /// @param _description Description of the work required.
    /// @param _bountyAmount The amount of bounty for the project.
    /// @param _bountyToken The address of the bounty token (0x0 for ETH).
    function proposeProject(string memory _title, string memory _description, uint256 _bountyAmount, address _bountyToken) public payable {
        // Either an active artisan with sufficient reputation OR the owner
        require(artisanInfo[msg.sender].isActive && artisanInfo[msg.sender].reputationScore >= guildConfig.minReputationToProposeProject || msg.sender == owner(), "DAAG: Not authorized to propose projects");
        require(_bountyAmount > 0, "DAAG: Bounty must be greater than zero");

        uint256 projectId = projectCounter++;

        if (_bountyToken == address(0)) {
            // ETH bounty
            require(msg.value == _bountyAmount, "DAAG: ETH amount sent must match bounty");
            // ETH is automatically transferred to the contract balance
        } else {
            // ERC20 token bounty
            require(msg.value == 0, "DAAG: Do not send ETH for token bounty");
            require(IERC20(_bountyToken).transferFrom(msg.sender, address(this), _bountyAmount), "DAAG: Token transfer failed");
        }

        projects[projectId] = Project({
            creator: msg.sender,
            title: _title,
            description: _description,
            bountyAmount: _bountyAmount,
            bountyToken: _bountyToken,
            status: ProjectStatus.Open,
            assignee: address(0),
            submissionHash: "",
            evaluationScore: 0,
            creationTime: block.timestamp,
            completionTime: 0
        });

        emit ProjectProposed(projectId, msg.sender, _bountyToken, _bountyAmount);
    }

    /// @notice Assigns an open project to an active artisan.
    /// Can only be called by the project creator or the owner.
    /// @param _projectId ID of the project to assign.
    /// @param _assignee Address of the artisan to assign the project to.
    function assignProject(uint256 _projectId, address _assignee) public onlyProjectCreatorOrOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Open, "DAAG: Project is not open");
        require(artisanInfo[_assignee].isActive, "DAAG: Assignee is not an active artisan");

        project.assignee = _assignee;
        project.status = ProjectStatus.Assigned;

        emit ProjectAssigned(_projectId, _assignee);
    }

    /// @notice Allows the assigned artisan to submit their completed work.
    /// @param _projectId ID of the project.
    /// @param _submissionHash Hash referencing the submitted work (e.g., IPFS hash).
    function submitProject(uint256 _projectId, string memory _submissionHash) public onlyProjectAssignee(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Assigned, "DAAG: Project is not assigned");
        require(bytes(_submissionHash).length > 0, "DAAG: Submission hash cannot be empty");

        project.submissionHash = _submissionHash;
        project.status = ProjectStatus.Submitted;

        emit ProjectSubmitted(_projectId, msg.sender, _submissionHash);
    }

    /// @notice Allows the project creator or owner to evaluate a submitted project.
    /// Determines success/failure and potentially distributes bounty and updates stats.
    /// @param _projectId ID of the project.
    /// @param _evaluationScore Score given to the submission (e.g., on a scale). Positive indicates success potential.
    function evaluateProject(uint256 _projectId, int256 _evaluationScore) public onlyProjectCreatorOrOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Submitted, "DAAG: Project is not submitted");
        require(project.assignee != address(0), "DAAG: Project has no assignee"); // Should not happen if status is Submitted

        project.evaluationScore = _evaluationScore;
        project.completionTime = block.timestamp;

        address assignee = project.assignee;
        uint256 bountyAmount = project.bountyAmount;
        address bountyToken = project.bountyToken;

        if (_evaluationScore >= int256(guildConfig.projectEvaluationThreshold)) {
            // Project successful
            project.status = ProjectStatus.Completed;

            // Transfer bounty
            if (bountyToken == address(0)) {
                // ETH bounty
                (bool sent, ) = payable(assignee).call{value: bountyAmount}("");
                require(sent, "DAAG: Failed to send ETH bounty");
            } else {
                // ERC20 token bounty
                require(IERC20(bountyToken).transfer(assignee, bountyAmount), "DAAG: Failed to send token bounty");
            }

            // Update artisan stats
            _updateArtisanStats(assignee, int256(guildConfig.projectCompletionReputationBoost), int256(guildConfig.projectCompletionSkillPointsBoost));
            artisanInfo[assignee].completedProjects++;

            emit ProjectCompleted(_projectId, assignee, bountyAmount);
        } else {
            // Project failed
            project.status = ProjectStatus.Failed;
            // Optionally penalize reputation/skill points here
            // _updateArtisanStats(assignee, -int256(guildConfig.projectCompletionReputationBoost / 2), -int256(guildConfig.projectCompletionSkillPointsBoost / 2)); // Example penalty

            // Bounty remains in treasury (could be re-assigned or returned)
            emit ProjectFailed(_projectId, assignee);
        }

        emit ProjectEvaluated(_projectId, _evaluationScore, project.status);
    }

    /// @notice Allows the project creator or owner to cancel an open or assigned project.
    /// Bounty is returned to the creator (if applicable).
    /// @param _projectId ID of the project to cancel.
    function cancelProject(uint256 _projectId) public onlyProjectCreatorOrOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Open || project.status == ProjectStatus.Assigned, "DAAG: Project cannot be cancelled in its current state");

        project.status = ProjectStatus.Failed; // Use Failed status to indicate termination

        // Return bounty to the creator if it hasn't been paid out
        if (project.bountyAmount > 0) {
            if (project.bountyToken == address(0)) {
                // ETH bounty
                 (bool sent, ) = payable(project.creator).call{value: project.bountyAmount}("");
                 require(sent, "DAAG: Failed to return ETH bounty");
            } else {
                // ERC20 token bounty
                 require(IERC20(project.bountyToken).transfer(project.creator, project.bountyAmount), "DAAG: Failed to return token bounty");
            }
        }

        emit ProjectCancelled(_projectId);
    }


    /// @notice Retrieves the details of a specific project by its ID.
    /// @param _projectId ID of the project.
    /// @return The Project struct.
    function getProjectDetails(uint256 _projectId) public view returns (Project memory) {
        require(_projectId > 0 && _projectId < projectCounter, "DAAG: Invalid project ID");
        return projects[_projectId];
    }

    /// @notice Retrieves a list of projects assigned to a specific artisan.
    /// This is an inefficient way to do this on-chain, typically done off-chain or with helper contracts/indices.
    /// Included here for demonstration, but not recommended for large numbers of projects.
    /// @param _artisan Address of the artisan.
    /// @return uint256[] An array of project IDs assigned to the artisan.
    function getArtisanProjects(address _artisan) public view returns (uint256[] memory) {
        // This function is highly inefficient for a large number of projects and should be
        // implemented with an off-chain indexer or a dedicated mapping in a real scenario.
        uint256[] memory artisanProjectIds = new uint256[](projectCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < projectCounter; i++) {
            if (projects[i].assignee == _artisan) {
                artisanProjectIds[count] = i;
                count++;
            }
        }
        // Trim the array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = artisanProjectIds[i];
        }
        return result;
    }


    // --- Quest Management Functions ---

    /// @notice Allows a qualified address to create a new quest.
    /// Requires minimum reputation or owner privilege. Reward is sent to the treasury upon creation.
    /// @param _title Title of the quest.
    /// @param _description Description of the task.
    /// @param _rewardAmount The amount of token/ETH reward.
    /// @param _rewardToken Address of the reward token (0x0 for ETH).
    /// @param _rewardReputation Reputation points awarded.
    /// @param _rewardSkillPoints Skill points awarded.
    function createQuest(
        string memory _title,
        string memory _description,
        uint256 _rewardAmount,
        address _rewardToken,
        uint256 _rewardReputation,
        uint256 _rewardSkillPoints
    ) public payable {
        // Either an active artisan with sufficient reputation OR the owner
        require(artisanInfo[msg.sender].isActive && artisanInfo[msg.sender].reputationScore >= guildConfig.minReputationToCreateQuest || msg.sender == owner(), "DAAG: Not authorized to create quests");
        require(_rewardAmount > 0 || _rewardReputation > 0 || _rewardSkillPoints > 0, "DAAG: Quest must have some reward");

        uint256 questId = questCounter++;

        if (_rewardToken == address(0)) {
            // ETH reward
            require(msg.value == _rewardAmount, "DAAG: ETH amount sent must match reward");
             // ETH is automatically transferred to the contract balance
        } else if (_rewardAmount > 0) {
            // ERC20 token reward
            require(msg.value == 0, "DAAG: Do not send ETH for token reward");
            require(IERC20(_rewardToken).transferFrom(msg.sender, address(this), _rewardAmount), "DAAG: Token transfer failed");
        }

        quests[questId] = Quest({
            proposer: msg.sender,
            title: _title,
            description: _description,
            rewardAmount: _rewardAmount,
            rewardToken: _rewardToken,
            rewardReputation: _rewardReputation,
            rewardSkillPoints: _rewardSkillPoints,
            status: QuestStatus.Open,
            assignee: address(0),
            creationTime: block.timestamp
        });

        emit QuestCreated(questId, msg.sender);
    }

    /// @notice Allows an active artisan to accept an open quest.
    /// @param _questId ID of the quest.
    function acceptQuest(uint256 _questId) public onlyArtisan {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Open, "DAAG: Quest is not open");

        quest.assignee = msg.sender;
        quest.status = QuestStatus.Accepted;

        emit QuestAccepted(_questId, msg.sender);
    }

    /// @notice Allows the assigned artisan to mark a quest as completed.
    /// This typically requires verification by the proposer or owner.
    /// @param _questId ID of the quest.
    function completeQuest(uint256 _questId) public onlyQuestAssignee(_questId) {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Accepted, "DAAG: Quest is not accepted by you");

        quest.status = QuestStatus.Completed;
        emit QuestCompleted(_questId, msg.sender);
    }

    /// @notice Allows the quest proposer or owner to verify a completed quest.
    /// Distributes rewards and updates artisan stats upon verification.
    /// @param _questId ID of the quest.
    function verifyQuestCompletion(uint256 _questId) public onlyQuestProposerOrOwner(_questId) {
        Quest storage quest = quests[_questId];
        require(quest.status == QuestStatus.Completed, "DAAG: Quest is not in completed state");
        require(quest.assignee != address(0), "DAAG: Quest has no assignee"); // Should not happen

        quest.status = QuestStatus.Verified;

        address assignee = quest.assignee;
        uint256 rewardAmount = quest.rewardAmount;
        address rewardToken = quest.rewardToken;
        uint256 rewardReputation = quest.rewardReputation;
        uint256 rewardSkillPoints = quest.rewardSkillPoints;

        // Transfer reward
        if (rewardAmount > 0) {
            if (rewardToken == address(0)) {
                // ETH reward
                (bool sent, ) = payable(assignee).call{value: rewardAmount}("");
                require(sent, "DAAG: Failed to send ETH reward");
            } else {
                // ERC20 token reward
                require(IERC20(rewardToken).transfer(assignee, rewardAmount), "DAAG: Failed to send token reward");
            }
        }


        // Update artisan stats
        _updateArtisanStats(assignee, int256(rewardReputation + guildConfig.questCompletionReputationBoost), int256(rewardSkillPoints + guildConfig.questCompletionSkillPointsBoost));
        artisanInfo[assignee].completedQuests++;

        emit QuestVerified(_questId, assignee);
    }

    /// @notice Retrieves the details of a specific quest by its ID.
    /// @param _questId ID of the quest.
    /// @return The Quest struct.
    function getQuestDetails(uint256 _questId) public view returns (Quest memory) {
        require(_questId > 0 && _questId < questCounter, "DAAG: Invalid quest ID");
        return quests[_questId];
    }

    // --- Mystic Crafting System Functions ---

    /// @notice Allows a qualified artisan to propose a new crafting recipe.
    /// Requires minimum reputation. Recipe must specify input tokens/NFTs and expected output.
    /// @param _name Recipe name.
    /// @param _description Recipe description.
    /// @param _requiredSkillPoints Skill points needed to craft.
    /// @param _requiredTokenAmounts Amounts of required ERC20 tokens.
    /// @param _requiredTokens Addresses of required ERC20 tokens.
    /// @param _requiredItemTokenIds Specific IDs of required NFTs (corresponds to requiredItemNFTs). Use 0 if any token ID is acceptable from a collection.
    /// @param _requiredItemNFTs Addresses of required ERC721 contracts.
    /// @param _expectedOutputTokenId Identifier for the output item type.
    /// @param _duration Optional crafting duration.
    function proposeCraftingRecipe(
        string memory _name,
        string memory _description,
        uint256 _requiredSkillPoints,
        uint256[] memory _requiredTokenAmounts,
        address[] memory _requiredTokens,
        uint256[] memory _requiredItemTokenIds,
        address[] memory _requiredItemNFTs,
        uint256 _expectedOutputTokenId,
        uint256 _duration
    ) public onlyArtisan {
        require(artisanInfo[msg.sender].reputationScore >= guildConfig.recipeApprovalThreshold, "DAAG: Insufficient reputation to propose recipe");
        require(_requiredTokens.length == _requiredTokenAmounts.length, "DAAG: Mismatch in token arrays");
        require(_requiredItemNFTs.length == _requiredItemTokenIds.length, "DAAG: Mismatch in NFT arrays"); // Allow 0 for any token ID of a collection

        uint256 recipeId = craftingRecipeCounter++;

        craftingRecipes[recipeId] = Recipe({
            creator: msg.sender,
            isApproved: false, // Requires approval
            name: _name,
            description: _description,
            requiredSkillPoints: _requiredSkillPoints,
            requiredTokenAmounts: _requiredTokenAmounts,
            requiredTokens: _requiredTokens,
            requiredItemTokenIds: _requiredItemTokenIds,
            requiredItemNFTs: _requiredItemNFTs,
            expectedOutputTokenId: _expectedOutputTokenId,
            duration: _duration,
            creationTime: block.timestamp
        });

        emit RecipeProposed(recipeId, msg.sender);
    }

    /// @notice Approves a proposed crafting recipe, making it usable.
    /// Can be called by the owner or possibly artisans with high reputation (governance).
    /// @param _recipeId ID of the recipe to approve.
    function approveCraftingRecipe(uint256 _recipeId) public {
         // Can be called by owner or an artisan with high reputation (example governance logic)
        require(owner() == msg.sender || (artisanInfo[msg.sender].isActive && artisanInfo[msg.sender].reputationScore >= guildConfig.recipeApprovalThreshold), "DAAG: Not authorized to approve recipes");
        require(_recipeId > 0 && _recipeId < craftingRecipeCounter, "DAAG: Invalid recipe ID");
        Recipe storage recipe = craftingRecipes[_recipeId];
        require(!recipe.isApproved, "DAAG: Recipe is already approved");

        recipe.isApproved = true;
        emit RecipeApproved(_recipeId, msg.sender);
    }

    /// @notice Allows an artisan to craft an item using an approved recipe.
    /// Requires sufficient skill points and transfer of required input assets (tokens/NFTs).
    /// Assumes the outputItemNFT contract has a minting function callable by this contract.
    /// @param _recipeId ID of the recipe to use.
    function craftItem(uint256 _recipeId) public onlyArtisan onlyApprovedRecipe(_recipeId) {
        Recipe storage recipe = craftingRecipes[_recipeId];
        Artisan storage artisan = artisanInfo[msg.sender];

        require(artisan.skillPoints >= recipe.requiredSkillPoints, "DAAG: Insufficient skill points");
        // Optional: Add check for crafting duration/cooldown if recipe.duration > 0

        // Transfer required ERC20 tokens from artisan to guild treasury
        for (uint i = 0; i < recipe.requiredTokens.length; i++) {
            address token = recipe.requiredTokens[i];
            uint256 amount = recipe.requiredTokenAmounts[i];
            if (amount > 0) {
                 require(IERC20(token).transferFrom(msg.sender, treasuryAddress, amount), "DAAG: Failed to transfer required token");
            }
        }

        // Transfer required ERC721 items from artisan to guild contract (or burn/transfer as per recipe logic)
        // IMPORTANT: The user must approve THIS contract to transfer their NFTs *before* calling craftItem
        for (uint i = 0; i < recipe.requiredItemNFTs.length; i++) {
            address nftContract = recipe.requiredItemNFTs[i];
            uint256 tokenId = recipe.requiredItemTokenIds[i]; // 0 means any token ID from collection is ok

            if (nftContract != address(0)) {
                 if (tokenId > 0) {
                     // Require specific token ID
                    require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "DAAG: Required NFT not owned by crafter");
                    IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId); // Transfer to guild contract
                    // Alternatively: Burn the NFT: IERC721(nftContract).burn(tokenId);
                 } else {
                     // Require any token ID from the collection (more complex, needs indexer or user specifies which to burn/transfer)
                     // For this example, we'll require a specific ID (tokenId > 0). A real implementation would need user input for which token ID if tokenId is 0.
                     revert("DAAG: Recipe requires specific NFT ID (must be > 0)");
                 }
            }
        }

        // Call the external output NFT contract to mint the new item
        // Assumes outputItemNFT contract has a minting function like mintItem(address recipient, uint256 itemTypeId, ...)
        require(outputItemNFT != address(0), "DAAG: Output item NFT contract not set");
        // Example call (exact function depends on your output NFT contract):
        // IERC721(outputItemNFT).mintItem(msg.sender, recipe.expectedOutputTokenId, ...);
        // For a simple example, let's assume it has a basic mint function we can call:
        uint256 newItemTokenId = IERC721(outputItemNFT).totalSupply() + 1; // Very basic ID generation example
        IERC721(outputItemNFT).safeMint(msg.sender, newItemTokenId); // Example: Mints a new generic NFT for the artisan

        // Optionally burn the transferred input NFTs from the guild contract if they were transferred here
        // (This depends on the crafting logic - do inputs get consumed or just used as key?)
        // For consumption:
        // for (uint i = 0; i < recipe.requiredItemNFTs.length; i++) {
        //      if (recipe.requiredItemTokenIds[i] > 0) {
        //          IERC721(recipe.requiredItemNFTs[i]).burn(recipe.requiredItemTokenIds[i]);
        //      }
        // }


        // Optionally update skill points based on crafting difficulty
        // _updateArtisanStats(msg.sender, 0, int256(recipe.requiredSkillPoints / 10)); // Example skill gain

        emit ItemCrafted(_recipeId, msg.sender, newItemTokenId); // Emitting the *new* item's potential ID
    }

    /// @notice Retrieves the details of a specific crafting recipe by its ID.
    /// @param _recipeId ID of the recipe.
    /// @return The Recipe struct.
    function getCraftingRecipe(uint256 _recipeId) public view returns (Recipe memory) {
         require(_recipeId > 0 && _recipeId < craftingRecipeCounter, "DAAG: Invalid recipe ID");
        return craftingRecipes[_recipeId];
    }

    // --- Treasury & Finance Functions ---

    /// @notice Allows anyone to send ETH or approved ERC20 tokens to the guild treasury.
    /// ERC20 tokens require prior approval by the sender to the guild contract.
    /// @param _tokenAddress Address of the token to deposit (0x0 for ETH).
    /// @param _amount Amount to deposit.
    function depositToTreasury(address _tokenAddress, uint256 _amount) public payable {
        require(_amount > 0, "DAAG: Amount must be greater than zero");

        if (_tokenAddress == address(0)) {
            // ETH deposit
            require(msg.value == _amount, "DAAG: ETH amount sent must match deposit amount");
             // ETH is automatically transferred to the contract balance
        } else {
            // ERC20 token deposit
            require(msg.value == 0, "DAAG: Do not send ETH for token deposit");
             // Token must be approved by sender to this contract address first
            require(IERC20(_tokenAddress).transferFrom(msg.sender, treasuryAddress, _amount), "DAAG: Token deposit failed");
        }

        emit Deposit(msg.sender, _amount);
    }

    /// @notice Allows the owner (or future governance) to withdraw funds from the treasury.
    /// This is needed to pay for operational costs, external services, etc. (Bounties are paid directly).
    /// @param _tokenAddress Address of the token to withdraw (0x0 for ETH).
    /// @param _amount Amount to withdraw.
    /// @param _recipient The address to send the funds to.
    function withdrawFromTreasury(address _tokenAddress, uint256 _amount, address _recipient) public onlyOwner {
        require(_amount > 0, "DAAG: Amount must be greater than zero");
        require(_recipient != address(0), "DAAG: Recipient cannot be zero address");

        if (_tokenAddress == address(0)) {
            // ETH withdrawal
            require(address(this).balance >= _amount, "DAAG: Insufficient ETH balance");
            (bool sent, ) = payable(_recipient).call{value: _amount}("");
            require(sent, "DAAG: ETH withdrawal failed");
        } else {
            // ERC20 token withdrawal from Treasury address
            // Requires this contract to have allowance to spend from treasuryAddress
            // OR treasuryAddress is another contract that allows withdrawal calls.
            // Simplest: Assume treasuryAddress is just an EOA controlled by the owner,
            // and the owner will manage token withdrawals manually from that account.
            // A more complex version would have treasury logic here.
            // Let's simplify and assume the contract *is* the treasury for simplicity in this example.
             require(address(this).balance >= _amount, "DAAG: Insufficient token balance"); // Check contract's token balance
             require(IERC20(_tokenAddress).transfer(_recipient, _amount), "DAAG: Token withdrawal failed");
        }

        emit Withdrawal(_recipient, _amount);
    }

    /// @notice Retrieves the current balance of the guild treasury for a given token or ETH.
    /// @param _tokenAddress Address of the token (0x0 for ETH).
    /// @return uint256 The balance.
    function getTreasuryBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == address(0)) {
            return address(this).balance;
        } else {
            // Check the balance held by THIS contract, assuming it IS the treasury for simplicity.
            return IERC20(_tokenAddress).balanceOf(address(this));
        }
    }

    // --- Utility/View Functions ---

     /// @notice Gets the total number of active artisans in the guild.
     /// WARNING: This is inefficient and should be replaced with a counter updated on join/leave in production.
     /// Included for demonstration purposes.
     /// @return uint256 The count of active artisans.
    function getTotalActiveArtisans() public view returns (uint256) {
        uint256 count = 0;
        // This requires iterating over all possible addresses if we don't store them in an array.
        // Since we can't iterate mappings directly, this implementation is just a placeholder
        // and would need an auxiliary data structure (like an array of active members) or off-chain indexing.
        // A simple placeholder returning 0 or a fixed number:
        // return 0; // Inefficient to calculate on-chain

        // A proper implementation would require tracking active members in an array or linked list,
        // or relying on off-chain data. Let's return 0 as a placeholder for on-chain calculation constraint.
         return 0;
    }

    // Required for ERC721Holder to receive NFTs
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        // Optional: Add logic here to ensure only expected NFTs (e.g., required for crafting) are accepted,
        // or log which NFTs were received.
        // For crafting inputs, this receives the NFTs when `craftItem` calls `safeTransferFrom`.
        return this.onERC721Received.selector;
    }
}
```