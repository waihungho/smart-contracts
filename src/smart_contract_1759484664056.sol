This smart contract, named **EchelonForgeProtocol**, introduces a decentralized framework for collaborative creation, skill development, and community governance. It features dynamic, non-transferable "Skill-Bound Tokens (SBTs)" for reputation, an on-chain skill tree, a project management system issuing ERC-1155-like deliverables with built-in revenue sharing, and a robust DAO powered by an associated ERC-20 token (EchelonToken).

It aims to provide a unique blend of identity, reputation, and collaborative economic models, avoiding direct duplication of existing open-source projects by combining and extending concepts in novel ways.

---

## `EchelonForgeProtocol.sol`

**Outline:**

The `EchelonForgeProtocol` contract orchestrates a comprehensive decentralized ecosystem. It manages user identities as non-transferable Skill-Bound Tokens (SBTs), tracks their progression through a dynamic on-chain skill tree, facilitates collaborative project creation and funding, and empowers its community through a governance (DAO) module. An associated ERC-20 token, `EchelonToken`, serves as the backbone for governance staking and rewards.

**Function Summary:**

**I. Core SBT (Forger) Management:** These functions handle the lifecycle and attributes of "Forger SBTs," which are non-transferable ERC-721-like tokens representing a user's identity and reputation within the protocol.

1.  `mintForgersSBT(string memory initialURI)`: Allows a user to mint their unique Forger SBT, establishing their identity in the protocol. Each user can only mint one SBT.
2.  `updateForgersSBTMetadata(uint256 tokenId, string memory newURI)`: Enables the SBT owner or Guild Master to update the associated metadata URI, allowing for dynamic visual or data representations based on a Forger's progression.
3.  `burnForgersSBT(uint256 tokenId)`: Permits an SBT owner to voluntarily destroy their SBT, clearing their associated on-chain identity and skill data.
4.  `getForgersSBTDetails(uint256 tokenId)`: Provides a comprehensive view of an SBT, including its owner, current metadata URI, and calculated total reputation.

**II. Skill Tree & Progression:** This module defines a skill development system where Forgers can earn experience and level up in various skills, directly impacting their SBT's dynamic properties and governance weight.

5.  `addSkillToTree(string memory skillName, uint256 maxLevel, uint256[] memory levelExpThresholds)`: Allows the Guild Master to define new skills with specific maximum levels and experience thresholds for each level.
6.  `grantSkillExperience(uint256 forgerSBTId, uint256 skillId, uint256 amount)`: Awards experience to a Forger for a specific skill, automatically calculating level-ups if thresholds are met. Callable by Guild Master or approved Project Leads.
7.  `getForgersSkillLevel(uint256 forgerSBTId, uint256 skillId)`: Retrieves the current level of a specific skill for a given Forger.
8.  `getForgersTotalReputation(uint256 forgerSBTId)`: Calculates a Forger's aggregate reputation score, which can be derived from their combined skill levels or other metrics.

**III. Decentralized Governance (DAO):** Implementing a basic DAO structure, Forgers can propose changes, vote using staked `EchelonToken`s, and delegate their voting power.

9.  `createProposal(string memory description, address targetContract, bytes memory callData, uint256 value, uint256 votingPeriod)`: Allows eligible Forgers (based on staked `EchelonToken`s) to submit governance proposals, specifying target contract, function call, and ETH value.
10. `voteOnProposal(uint256 proposalId, bool support)`: Forgers cast their votes ('for' or 'against') on active proposals, with their voting power determined by their staked `EchelonToken`s.
11. `delegateVotingPower(address delegatee)`: Enables a Forger to assign their `EchelonToken` voting power to another address.
12. `executeProposal(uint256 proposalId)`: Executes a proposal if it has successfully passed its voting period and met the required quorum and approval thresholds.

**IV. Collaborative Project Management:** This system allows for the creation, funding, and issuance of "Project Deliverable NFTs" (ERC-1155-like) as outcomes of collaborative efforts, with integrated revenue distribution.

13. `submitProjectIdea(string memory name, string memory description, uint256 requestedFundingAmount, address proposedLead)`: A Forger can submit a detailed proposal for a new collaborative project, including requested funding and a proposed lead.
14. `approveAndFundProject(uint256 projectId, address projectLeadAddress, uint256 initialFunding, string memory baseURI, uint256[] memory milestoneExpRewards)`: The Guild Master (or DAO via a proposal) approves a project, allocates initial funding, designates a project lead, sets a base URI for its deliverables, and defines experience rewards for milestones.
15. `issueProjectDeliverableNFT(uint256 projectId, uint256 supply, string memory uri, bytes memory creatorsData)`: A Project Lead can mint new ERC-1155-like tokens as deliverables for their project, specifying supply, metadata URI, and embedded royalty/creator split data.
16. `distributeProjectRevenue(uint256 projectId, uint256 deliverableTokenId, uint256 amount, address tokenAddress)`: Facilitates the distribution of revenue received from a project deliverable to the defined creators and the guild, based on the `creatorsData` embedded in the deliverable.
17. `getProjectDetails(uint256 projectId)`: Retrieves all detailed information about a particular project.

**V. Oracle & External Data Integration (Mocked):** A simplified function to simulate external data input, crucial for dynamic contract behavior based on real-world events or project progress.

18. `updateProjectMilestoneStatus(uint256 projectId, uint256 milestoneId, bool completed, string memory feedbackURI)`: The Guild Master (or a designated Oracle) updates a project's milestone status. This can trigger automatic rewards (e.g., skill experience for the project lead) and dynamic SBT updates.

**VI. EchelonToken Staking & Rewards:** Manages the staking mechanism for the `EchelonToken`, enabling users to gain voting power and earn rewards for their participation.

19. `stakeEchelonTokens(uint256 amount)`: Allows a Forger to stake their `EchelonToken`s, granting them voting power and making them eligible for rewards.
20. `unstakeEchelonTokens(uint256 amount)`: Enables a Forger to withdraw their staked `EchelonToken`s.
21. `claimStakingRewards()`: Allows staked Forgers to claim their accrued `EchelonToken` rewards.

**VII. Admin & System Utilities:** Essential functions for contract management, including pausing, role assignment, and fund withdrawals.

22. `pauseContract()`: Halts core contract functionalities, useful for emergency situations or upgrades (callable by Owner or Guild Master).
23. `unpauseContract()`: Resumes core contract functionalities (callable by Owner or Guild Master).
24. `setGuildMaster(address newGuildMaster)`: Transfers the `Guild Master` role, which holds elevated permissions within the protocol.
25. `withdrawGuildFunds(address tokenAddress, uint256 amount)`: Allows the Guild Master to withdraw accumulated funds (ETH or ERC-20) from the contract's treasury.

**VIII. View Functions:** Read-only functions for querying various states and parameters of the protocol.

26. `getTotalForgersSBTs()`: Returns the total count of minted Forger SBTs.
27. `getTotalSkills()`: Returns the total number of skills currently defined in the skill tree.
28. `getTotalProjects()`: Returns the total number of projects that have been submitted to the protocol.
29. `getActiveProposalsCount()`: Returns the count of governance proposals currently in their active voting phase.
30. `getVotingPower(address voter)`: Returns the effective voting power of an address, considering any delegation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint to string conversion in URIs.

// --- EchelonToken: A simple ERC-20 token for governance and rewards ---
// This contract serves as the native ERC-20 token for the EchelonForgeProtocol.
// It includes basic ERC-20 functionality along with a controlled minting mechanism
// where the EchelonForgeProtocol contract will typically be designated as the minter.
contract EchelonToken is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    address public minter; // Address allowed to mint new tokens

    event MinterChanged(address indexed oldMinter, address indexed newMinter);

    constructor(string memory name_, string memory symbol_, uint256 initialSupply, address initialMinter) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialSupply;
        _balances[_msgSender()] = initialSupply; // Mint initial supply to deployer
        emit Transfer(address(0), _msgSender(), initialSupply);

        minter = initialMinter; // Set the initial minter (e.g., EchelonForgeProtocol)
        emit MinterChanged(address(0), initialMinter);
    }

    // Modifier to restrict minting
    modifier onlyMinter() {
        require(_msgSender() == minter, "EchelonToken: Only minter can call this function");
        _;
    }

    // Public mint function callable only by the minter
    function mint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }

    // Allows changing the minter (e.g., to a DAO contract)
    function setMinter(address newMinter) public onlyMinter {
        require(newMinter != address(0), "EchelonToken: new minter is the zero address");
        emit MinterChanged(minter, newMinter);
        minter = newMinter;
    }

    // Standard ERC-20 functions
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18; // Common standard
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] = _balances[to] + amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}


// --- EchelonForgeProtocol: The main contract with advanced logic ---
contract EchelonForgeProtocol is Ownable, Pausable {
    using Strings for uint256;

    // --- State Variables ---
    address public echelonTokenAddress;
    address public guildMaster; // A specific role with more permissions than a regular owner

    // Forgers Skill-Bound Tokens (SBTs) - ERC721-like but non-transferable
    uint256 private _nextForgersSBTId;
    mapping(uint256 => address) private _sbtOwners;      // SBT ID -> Owner address
    mapping(address => uint256) private _sbtIdByOwner;   // Owner address -> SBT ID (each address can only have one SBT)
    mapping(uint256 => string) private _sbtTokenURIs;    // SBT ID -> Metadata URI

    // Skill Tree System
    struct Skill {
        string name;
        uint256 maxLevel;
        uint256[] levelExpThresholds; // exp needed to reach level 'n' from 'n-1' (0-indexed)
    }
    mapping(uint256 => Skill) public skills; // skillId -> Skill data
    uint256 private _nextSkillId;

    struct ForgersSkillData {
        uint256 currentLevel;
        uint256 currentExp; // Experience for the *current* level
    }
    // forgerSBTId -> skillId -> ForgersSkillData
    mapping(uint256 => mapping(uint256 => ForgersSkillData)) private _forgersSkillProgress;

    // Project Management (ERC-1155-like for deliverables)
    struct Project {
        string name;
        string description;
        address projectLead;
        uint256 requestedFundingAmount;
        uint256 allocatedFunding;
        enum Status { Pending, Approved, Active, Completed, Cancelled }
        Status status;
        string baseURI; // Base URI for project's ERC-1155 deliverables
        uint256 nextDeliverableId; // Counter for ERC-1155-like token IDs for this project
        address[] contributors; // List of Forgers who contributed to this project
        uint256[] milestoneExpRewards; // Experience rewards for each milestone
    }
    mapping(uint256 => Project) public projects; // projectId -> Project data
    uint256 private _nextProjectId;

    // Project Deliverable NFTs (ERC-1155-like specific properties)
    struct DeliverableNFT {
        uint256 projectId;
        uint256 supply;
        string uri; // specific URI for this deliverable
        bytes creatorsData; // encoded array of (address, percentage) for royalties/splits
    }
    mapping(uint256 => DeliverableNFT) public projectDeliverables; // Global unique deliverableId -> DeliverableNFT data
    mapping(uint256 => mapping(address => uint256)) private _projectDeliverableBalances; // deliverableId -> owner -> balance (simple model)

    // Governance System (DAO)
    struct Proposal {
        string description;
        address target;
        bytes callData;
        uint256 value; // ETH to send with call
        address creator;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool cancelled;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId;
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // proposalId -> voterAddress -> hasVoted
    uint256 public minEchelonTokensToCreateProposal = 1000 * (10 ** 18); // Example: 1000 ECH
    uint256 public quorumPercentage = 4; // 4% of total staked tokens must vote 'for' for proposal to pass (out of 100)
    uint256 public votingDelayBlocks = 10; // Number of blocks before voting can start after creation
    uint256 public votingPeriodBlocks = 100; // Number of blocks for voting

    // EchelonToken Staking & Rewards
    struct StakingPosition {
        uint256 amount;
        address delegatee; // Address this user has delegated their voting power to
        uint256 lastInteractionBlock; // For calculating rewards and preventing double-counting
        uint256 rewardsClaimed; // Total rewards claimed by this staker
    }
    mapping(address => StakingPosition) public stakingPositions;
    mapping(address => address) public votingDelegates; // delegator -> delegatee (who they delegate to)
    uint256 public totalStakedEchelonTokens;
    uint256 public rewardRatePerBlock = 1 * (10 ** 17); // Example: 0.1 ECH per 1 ECH staked per block (simplified for demo)

    // --- Events ---
    event ForgerSBTMinted(address indexed owner, uint256 tokenId, string uri);
    event ForgerSBTBurned(uint256 indexed tokenId);
    event ForgerSBTMetadataUpdated(uint256 indexed tokenId, string newUri);
    event SkillAdded(uint256 indexed skillId, string name, uint256 maxLevel);
    event SkillExperienceGranted(uint256 indexed forgerSBTId, uint256 indexed skillId, uint256 amount, uint256 newLevel, uint256 newExp);
    event ProjectIdeaSubmitted(uint256 indexed projectId, address indexed submitter, string name, uint256 requestedFunding);
    event ProjectApprovedAndFunded(uint256 indexed projectId, address indexed lead, uint256 allocatedFunding);
    event ProjectDeliverableIssued(uint256 indexed projectId, uint256 indexed deliverableId, uint256 supply, string uri);
    event RevenueDistributed(uint256 indexed projectId, uint256 indexed deliverableId, uint256 amount, address indexed tokenAddress);
    event ProjectMilestoneStatusUpdated(uint256 indexed projectId, uint256 indexed milestoneId, bool completed, string feedbackURI);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description, uint256 startBlock, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event TokensStaked(address indexed staker, uint256 amount);
    event TokensUnstaked(address indexed staker, uint256 amount);
    event StakingRewardsClaimed(address indexed staker, uint256 amount);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);

    // --- Modifiers ---
    modifier onlyGuildMaster() {
        require(_msgSender() == guildMaster, "EchelonForge: Only Guild Master can call this function");
        _;
    }

    modifier onlyForgerWithSBT() {
        require(_sbtIdByOwner[_msgSender()] != 0, "EchelonForge: Caller must own a Forger SBT");
        _;
    }

    modifier onlyProjectLead(uint256 projectId) {
        require(projects[projectId].projectLead == _msgSender(), "EchelonForge: Only project lead can call this function");
        _;
    }

    constructor(address _echelonTokenAddress) Ownable(_msgSender()) {
        require(_echelonTokenAddress != address(0), "EchelonForge: EchelonToken address cannot be zero");
        echelonTokenAddress = _echelonTokenAddress;
        guildMaster = _msgSender(); // Deployer is initially Guild Master
        _nextForgersSBTId = 1; // Start SBT IDs from 1
        _nextSkillId = 1; // Start Skill IDs from 1
        _nextProjectId = 1; // Start Project IDs from 1
        _nextProposalId = 1; // Start Proposal IDs from 1

        // Initialize a default skill (e.g., "General Contribution") for milestone rewards
        // In a real system, the Guild Master would add specific skills.
        uint256[] memory defaultExpThresholds = new uint256[](5); // 5 levels
        defaultExpThresholds[0] = 100; // Level 1
        defaultExpThresholds[1] = 200; // Level 2
        defaultExpThresholds[2] = 400; // Level 3
        defaultExpThresholds[3] = 800; // Level 4
        defaultExpThresholds[4] = 1600; // Level 5
        addSkillToTree("General Contribution", 5, defaultExpThresholds);
    }

    // --- I. Core SBT (Forger) Management ---

    /// @notice Mints a new non-transferable Forger's Skill-Bound Token (SBT) for the caller.
    /// @dev Each address can only mint one SBT. The SBT is non-transferable by design (no transfer function).
    /// @param initialURI The initial metadata URI for the SBT.
    /// @return The ID of the newly minted SBT.
    function mintForgersSBT(string memory initialURI) public whenNotPaused returns (uint256) {
        require(_sbtIdByOwner[_msgSender()] == 0, "EchelonForge: You already own a Forger SBT");

        uint256 newSBTId = _nextForgersSBTId++;
        _sbtOwners[newSBTId] = _msgSender();
        _sbtIdByOwner[_msgSender()] = newSBTId;
        _sbtTokenURIs[newSBTId] = initialURI;

        emit ForgerSBTMinted(_msgSender(), newSBTId, initialURI);
        return newSBTId;
    }

    /// @notice Allows a Forger to suggest metadata changes, or Guild Master to enforce, for an SBT.
    /// @param tokenId The ID of the SBT to update.
    /// @param newURI The new metadata URI.
    function updateForgersSBTMetadata(uint256 tokenId, string memory newURI) public whenNotPaused {
        require(_sbtOwners[tokenId] != address(0), "EchelonForge: SBT does not exist");
        require(_msgSender() == _sbtOwners[tokenId] || _msgSender() == guildMaster, "EchelonForge: Only owner or Guild Master can update SBT metadata");

        _sbtTokenURIs[tokenId] = newURI;
        emit ForgerSBTMetadataUpdated(tokenId, newURI);
    }

    /// @notice Allows a Forger to voluntarily burn their own SBT.
    /// @param tokenId The ID of the SBT to burn.
    function burnForgersSBT(uint256 tokenId) public whenNotPaused {
        require(_sbtOwners[tokenId] != address(0), "EchelonForge: SBT does not exist");
        require(_msgSender() == _sbtOwners[tokenId], "EchelonForge: Only the SBT owner can burn it");

        delete _sbtOwners[tokenId];
        delete _sbtIdByOwner[_msgSender()];
        delete _sbtTokenURIs[tokenId];
        // Clear skill data associated with this SBT
        for (uint256 i = 1; i < _nextSkillId; i++) {
            delete _forgersSkillProgress[tokenId][i];
        }

        emit ForgerSBTBurned(tokenId);
    }

    /// @notice Retrieves comprehensive details of a Forger's SBT.
    /// @param tokenId The ID of the SBT.
    /// @return owner_ The owner's address.
    /// @return uri_ The current metadata URI.
    /// @return reputation_ The total calculated reputation.
    /// @return exists_ Whether the SBT exists.
    function getForgersSBTDetails(uint256 tokenId) public view returns (address owner_, string memory uri_, uint256 reputation_, bool exists_) {
        owner_ = _sbtOwners[tokenId];
        exists_ = (owner_ != address(0));
        if (exists_) {
            uri_ = _sbtTokenURIs[tokenId];
            reputation_ = getForgersTotalReputation(tokenId);
        }
    }

    // --- II. Skill Tree & Progression ---

    /// @notice Adds a new skill to the global skill tree. Only Guild Master can add.
    /// @param skillName The name of the skill.
    /// @param maxLevel The maximum achievable level for this skill.
    /// @param levelExpThresholds An array defining experience points required for each level.
    ///                          `levelExpThresholds[0]` is exp for Level 1, `levelExpThresholds[1]` for Level 2, etc. (0-indexed)
    function addSkillToTree(string memory skillName, uint256 maxLevel, uint256[] memory levelExpThresholds) public onlyGuildMaster whenNotPaused {
        require(maxLevel == levelExpThresholds.length, "EchelonForge: maxLevel must match length of exp thresholds array");
        require(maxLevel > 0, "EchelonForge: maxLevel must be greater than 0");

        uint256 newSkillId = _nextSkillId++;
        skills[newSkillId] = Skill({
            name: skillName,
            maxLevel: maxLevel,
            levelExpThresholds: levelExpThresholds
        });

        emit SkillAdded(newSkillId, skillName, maxLevel);
    }

    /// @notice Awards experience to a forger for a specific skill, potentially leveling them up.
    /// @dev Can be called by Guild Master or Project Lead (if linked to project milestones).
    /// @param forgerSBTId The ID of the Forger's SBT.
    /// @param skillId The ID of the skill to grant experience for.
    /// @param amount The amount of experience to grant.
    function grantSkillExperience(uint256 forgerSBTId, uint256 skillId, uint256 amount) public whenNotPaused {
        require(_sbtOwners[forgerSBTId] != address(0), "EchelonForge: Forger SBT does not exist");
        require(skills[skillId].maxLevel > 0, "EchelonForge: Skill does not exist");
        require(_msgSender() == guildMaster || _isProjectLeadOfActiveProject(_msgSender()), "EchelonForge: Only Guild Master or an active Project Lead can grant experience");

        ForgersSkillData storage skillData = _forgersSkillProgress[forgerSBTId][skillId];
        Skill storage skillDef = skills[skillId];

        uint256 currentLevel = skillData.currentLevel;
        uint256 currentExp = skillData.currentExp;

        currentExp += amount;

        while (currentLevel < skillDef.maxLevel && currentExp >= skillDef.levelExpThresholds[currentLevel]) {
            currentExp -= skillDef.levelExpThresholds[currentLevel];
            currentLevel++;
        }

        skillData.currentLevel = currentLevel;
        skillData.currentExp = currentExp;

        emit SkillExperienceGranted(forgerSBTId, skillId, amount, currentLevel, currentExp);
    }

    /// @notice Returns a Forger's level for a specific skill.
    /// @param forgerSBTId The ID of the Forger's SBT.
    /// @param skillId The ID of the skill.
    /// @return The current level of the skill for the given Forger.
    function getForgersSkillLevel(uint256 forgerSBTId, uint256 skillId) public view returns (uint256) {
        return _forgersSkillProgress[forgerSBTId][skillId].currentLevel;
    }

    /// @notice Calculates a Forger's aggregate reputation based on all skills.
    /// @dev Simple sum of levels for now; can be expanded to weighted sum.
    /// @param forgerSBTId The ID of the Forger's SBT.
    /// @return The total reputation score.
    function getForgersTotalReputation(uint256 forgerSBTId) public view returns (uint256) {
        require(_sbtOwners[forgerSBTId] != address(0), "EchelonForge: Forger SBT does not exist");
        uint256 totalReputation = 0;
        for (uint256 i = 1; i < _nextSkillId; i++) { // Iterate through all defined skills (starting from 1)
            if (skills[i].maxLevel > 0) { // Check if skill exists
                totalReputation += _forgersSkillProgress[forgerSBTId][i].currentLevel;
            }
        }
        return totalReputation;
    }

    /// @dev Internal helper to check if an address is an active project lead.
    function _isProjectLeadOfActiveProject(address _addr) internal view returns (bool) {
        for (uint256 i = 1; i < _nextProjectId; i++) {
            if (projects[i].projectLead == _addr && projects[i].status == Project.Status.Active) {
                return true;
            }
        }
        return false;
    }

    // --- III. Decentralized Governance (DAO) ---

    /// @notice Allows Forgers with enough staked EchelonTokens to create a governance proposal.
    /// @param description A brief description of the proposal.
    /// @param targetContract The address of the contract the proposal will interact with.
    /// @param callData The encoded function call (calldata) for the targetContract.
    /// @param value The amount of ETH (in wei) to send with the call (if any).
    /// @param votingPeriod The number of blocks for which voting will be open.
    function createProposal(
        string memory description,
        address targetContract,
        bytes memory callData,
        uint256 value,
        uint256 votingPeriod
    ) public onlyForgerWithSBT whenNotPaused returns (uint256) {
        require(stakingPositions[_msgSender()].amount >= minEchelonTokensToCreateProposal, "EchelonForge: Not enough staked EchelonTokens to create proposal");
        require(votingPeriod > 0, "EchelonForge: Voting period must be positive");

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            description: description,
            target: targetContract,
            callData: callData,
            value: value,
            creator: _msgSender(),
            startBlock: block.number + votingDelayBlocks,
            endBlock: block.number + votingDelayBlocks + votingPeriod,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            cancelled: false
        });

        emit ProposalCreated(proposalId, _msgSender(), description, proposals[proposalId].startBlock, proposals[proposalId].endBlock);
        return proposalId;
    }

    /// @notice Forgers cast their vote on an active proposal using their staked EchelonTokens as power.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support `true` for 'for', `false` for 'against'.
    function voteOnProposal(uint256 proposalId, bool support) public onlyForgerWithSBT whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creator != address(0), "EchelonForge: Proposal does not exist");
        require(block.number >= proposal.startBlock, "EchelonForge: Voting has not started yet");
        require(block.number <= proposal.endBlock, "EchelonForge: Voting period has ended");
        require(!_hasVoted[proposalId][_msgSender()], "EchelonForge: Already voted on this proposal");
        
        // Get actual voting power, considering delegation
        uint256 votingPower = getVotingPower(_msgSender());
        require(votingPower > 0, "EchelonForge: No voting power from staked tokens or delegation");

        _hasVoted[proposalId][_msgSender()] = true; // Mark voter as having cast a vote
        if (support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }

        emit VoteCast(proposalId, _msgSender(), support, votingPower);
    }

    /// @notice Allows a Forger to delegate their EchelonToken voting power to another address.
    /// @param delegatee The address to delegate voting power to.
    function delegateVotingPower(address delegatee) public onlyForgerWithSBT whenNotPaused {
        require(delegatee != address(0), "EchelonForge: Delegatee cannot be zero address");
        require(delegatee != _msgSender(), "EchelonForge: Cannot delegate to yourself");

        // The current staker's voting power is now attributed to the delegatee.
        // If the staker later stakes more or unstakes, the delegated power changes.
        // This simple model assumes delegatee accumulates voting power, but the stake itself stays with the delegator.
        votingDelegates[_msgSender()] = delegatee;
        emit VotingPowerDelegated(_msgSender(), delegatee);
    }

    /// @notice Executes a proposal if it has passed and the voting period has ended.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public payable whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creator != address(0), "EchelonForge: Proposal does not exist");
        require(!proposal.executed, "EchelonForge: Proposal already executed");
        require(!proposal.cancelled, "EchelonForge: Proposal cancelled");
        require(block.number > proposal.endBlock, "EchelonForge: Voting period has not ended yet");

        // Check if proposal passed
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        require(totalVotes > 0, "EchelonForge: No votes cast on proposal");
        require(proposal.forVotes > proposal.againstVotes, "EchelonForge: Proposal did not pass (more 'for' votes needed)");
        
        // Quorum check: at least `quorumPercentage` of total staked tokens must have voted 'for'.
        // Simplified: `totalStakedEchelonTokens` might change during voting. A snapshot-based quorum
        // would be more robust but adds complexity.
        require(proposal.forVotes * 100 >= totalStakedEchelonTokens * quorumPercentage, "EchelonForge: Quorum not met");

        proposal.executed = true;

        // Execute the proposal's action
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        require(success, "EchelonForge: Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

    // --- IV. Collaborative Project Management ---

    /// @notice Allows a Forger to propose a new collaborative project.
    /// @param name The name of the project.
    /// @param description A detailed description of the project.
    /// @param requestedFundingAmount The initial funding requested for the project.
    /// @param proposedLead The address proposed as the project lead.
    /// @return The ID of the newly submitted project idea.
    function submitProjectIdea(
        string memory name,
        string memory description,
        uint256 requestedFundingAmount,
        address proposedLead
    ) public onlyForgerWithSBT whenNotPaused returns (uint256) {
        require(proposedLead != address(0), "EchelonForge: Proposed lead cannot be zero address");

        uint256 newProjectId = _nextProjectId++;
        projects[newProjectId] = Project({
            name: name,
            description: description,
            projectLead: proposedLead,
            requestedFundingAmount: requestedFundingAmount,
            allocatedFunding: 0,
            status: Project.Status.Pending,
            baseURI: "", // Set upon approval
            nextDeliverableId: 1, // Start deliverable IDs from 1 for this project
            contributors: new address[](0), // Initially empty
            milestoneExpRewards: new uint256[](0) // Initially empty
        });

        emit ProjectIdeaSubmitted(newProjectId, _msgSender(), name, requestedFundingAmount);
        return newProjectId;
    }

    /// @notice Guild Master or DAO approves and funds a project, setting up its ERC-1155 base URI.
    /// @dev This function could also be a target of a DAO proposal.
    /// @param projectId The ID of the project to approve.
    /// @param projectLeadAddress The final designated project lead.
    /// @param initialFunding The amount of ETH/tokens to allocate to the project.
    /// @param baseURI The base URI for this project's ERC-1155 deliverables.
    /// @param milestoneExpRewards Array of experience rewards for each milestone completion.
    function approveAndFundProject(
        uint256 projectId,
        address projectLeadAddress,
        uint256 initialFunding,
        string memory baseURI,
        uint256[] memory milestoneExpRewards
    ) public payable onlyGuildMaster whenNotPaused { // Could also be a DAO execute target
        Project storage project = projects[projectId];
        require(project.status == Project.Status.Pending, "EchelonForge: Project not in pending status");
        require(projectLeadAddress != address(0), "EchelonForge: Project lead cannot be zero address");
        require(initialFunding == msg.value, "EchelonForge: Sent ETH must match initialFunding");

        project.projectLead = projectLeadAddress;
        project.allocatedFunding = initialFunding;
        project.status = Project.Status.Active;
        project.baseURI = baseURI;
        project.milestoneExpRewards = milestoneExpRewards;

        emit ProjectApprovedAndFunded(projectId, projectLeadAddress, initialFunding);
    }

    /// @notice Project Lead issues a new ERC-1155 token as a specific deliverable for a project.
    /// @dev `creatorsData` should encode addresses and royalty percentages (e.g., using `abi.encode`).
    /// @param projectId The ID of the project.
    /// @param supply The total supply of this specific deliverable NFT.
    /// @param uri The specific metadata URI for this deliverable.
    /// @param creatorsData Encoded data for royalty splits (e.g., `abi.encode((address[] _creators, uint256[] _shares))`).
    /// @return The global unique ID for this deliverable NFT.
    function issueProjectDeliverableNFT(
        uint256 projectId,
        uint256 supply,
        string memory uri,
        bytes memory creatorsData
    ) public onlyProjectLead(projectId) whenNotPaused returns (uint256) {
        Project storage project = projects[projectId];
        require(project.status == Project.Status.Active, "EchelonForge: Project is not active");
        require(supply > 0, "EchelonForge: Supply must be greater than zero");

        uint256 deliverableId = projectId * (10**10) + project.nextDeliverableId++; // Simple unique ID generation
        projectDeliverables[deliverableId] = DeliverableNFT({
            projectId: projectId,
            supply: supply,
            uri: uri,
            creatorsData: creatorsData
        });

        // Mint the tokens to the project lead initially
        _projectDeliverableBalances[deliverableId][_msgSender()] += supply;

        emit ProjectDeliverableIssued(projectId, deliverableId, supply, uri);
        return deliverableId;
    }

    /// @notice Distributes received revenue from a project deliverable according to pre-defined creator splits and guild share.
    /// @dev The contract must hold the `amount` of `tokenAddress` to distribute.
    /// @param projectId The ID of the project.
    /// @param deliverableTokenId The unique ID of the deliverable NFT.
    /// @param amount The total revenue amount to distribute.
    /// @param tokenAddress The address of the token being distributed (address(0) for ETH).
    function distributeProjectRevenue(
        uint256 projectId,
        uint256 deliverableTokenId,
        uint256 amount,
        address tokenAddress
    ) public onlyProjectLead(projectId) whenNotPaused {
        DeliverableNFT storage deliverable = projectDeliverables[deliverableTokenId];
        require(deliverable.projectId == projectId, "EchelonForge: Deliverable does not belong to this project");
        require(amount > 0, "EchelonForge: Amount must be positive");

        if (tokenAddress == address(0)) {
            require(address(this).balance >= amount, "EchelonForge: Insufficient ETH balance in contract");
        } else {
            IERC20 token = IERC20(tokenAddress);
            require(token.balanceOf(address(this)) >= amount, "EchelonForge: Insufficient token balance in contract");
        }

        // Example: 10% goes to guild treasury, rest to creators based on creatorsData
        uint256 guildShare = amount * 10 / 100; // 10% guild share
        uint256 remainingForCreators = amount - guildShare;

        // Send guild share
        if (tokenAddress == address(0)) {
            payable(guildMaster).transfer(guildShare);
        } else {
            IERC20(tokenAddress).transfer(guildMaster, guildShare);
        }

        // Decode creatorsData and distribute remaining
        // Assumes `creatorsData` is an `abi.encode` of `(address[] _creators, uint256[] _shares)`
        // where shares are basis points (sum to 10000).
        (address[] memory creators, uint256[] memory shares) = abi.decode(deliverable.creatorsData, (address[], uint256[]));
        require(creators.length == shares.length, "EchelonForge: Creators and shares mismatch");
        uint256 totalShares;
        for (uint256 i = 0; i < shares.length; i++) {
            totalShares += shares[i];
        }
        require(totalShares == 10000, "EchelonForge: Creator shares must sum to 10000 basis points (100%)");

        for (uint256 i = 0; i < creators.length; i++) {
            uint256 creatorAmount = remainingForCreators * shares[i] / 10000;
            if (tokenAddress == address(0)) {
                payable(creators[i]).transfer(creatorAmount);
            } else {
                IERC20(tokenAddress).transfer(creators[i], creatorAmount);
            }
        }

        emit RevenueDistributed(projectId, deliverableTokenId, amount, tokenAddress);
    }

    /// @notice Retrieves all stored information about a specific project.
    /// @param projectId The ID of the project.
    /// @return Project struct details.
    function getProjectDetails(uint256 projectId) public view returns (Project memory) {
        require(projects[projectId].projectLead != address(0), "EchelonForge: Project does not exist");
        return projects[projectId];
    }

    // --- V. Oracle & External Data Integration (Mocked) ---

    /// @notice Guild Master or designated Oracle updates a project milestone, potentially triggering dynamic SBT updates or rewards.
    /// @dev This is a simplified mock. In a real system, an Oracle contract would typically call this.
    /// @param projectId The ID of the project.
    /// @param milestoneId The specific milestone being updated (0-indexed).
    /// @param completed `true` if milestone is completed, `false` otherwise.
    /// @param feedbackURI An optional URI linking to external feedback or proof of completion.
    function updateProjectMilestoneStatus(
        uint256 projectId,
        uint256 milestoneId,
        bool completed,
        string memory feedbackURI
    ) public onlyGuildMaster whenNotPaused {
        Project storage project = projects[projectId];
        require(project.projectLead != address(0), "EchelonForge: Project does not exist");
        require(project.status == Project.Status.Active, "EchelonForge: Project is not active");
        require(milestoneId < project.milestoneExpRewards.length, "EchelonForge: Milestone ID out of bounds");

        // In a real system, track completion status per milestone. Here, just trigger rewards.
        if (completed) {
            uint256 expReward = project.milestoneExpRewards[milestoneId];
            if (expReward > 0) {
                // Award experience to project lead
                uint256 leadSBTId = _sbtIdByOwner[project.projectLead];
                if (leadSBTId != 0) {
                    // For simplicity, we grant to skill ID 1 (General Contribution)
                    grantSkillExperience(leadSBTId, 1, expReward);
                }
            }
            // Optionally, update project status to Completed if all milestones are done
        }
        // Could also update a project-specific dynamic NFT metadata here

        emit ProjectMilestoneStatusUpdated(projectId, milestoneId, completed, feedbackURI);
    }

    // --- VI. EchelonToken Staking & Rewards ---

    /// @notice Stakes EchelonTokens to gain voting power and accrue rewards.
    /// @param amount The amount of EchelonTokens to stake.
    function stakeEchelonTokens(uint256 amount) public onlyForgerWithSBT whenNotPaused {
        require(amount > 0, "EchelonForge: Must stake a positive amount");

        EchelonToken echelonToken = EchelonToken(echelonTokenAddress);
        require(echelonToken.transferFrom(_msgSender(), address(this), amount), "EchelonForge: EchelonToken transfer failed");

        StakingPosition storage pos = stakingPositions[_msgSender()];
        // Calculate and distribute pending rewards before updating stake
        _distributeStakingRewards(_msgSender());

        pos.amount += amount;
        pos.lastInteractionBlock = block.number;
        totalStakedEchelonTokens += amount;

        emit TokensStaked(_msgSender(), amount);
    }

    /// @notice Unstakes EchelonTokens, subject to potential unbonding periods (not implemented for demo).
    /// @param amount The amount of EchelonTokens to unstake.
    function unstakeEchelonTokens(uint256 amount) public onlyForgerWithSBT whenNotPaused {
        StakingPosition storage pos = stakingPositions[_msgSender()];
        require(pos.amount >= amount, "EchelonForge: Insufficient staked amount");
        require(amount > 0, "EchelonForge: Must unstake a positive amount");

        // Calculate and distribute pending rewards before updating stake
        _distributeStakingRewards(_msgSender());

        pos.amount -= amount;
        pos.lastInteractionBlock = block.number;
        totalStakedEchelonTokens -= amount;

        EchelonToken echelonToken = EchelonToken(echelonTokenAddress);
        require(echelonToken.transfer(_msgSender(), amount), "EchelonForge: EchelonToken withdrawal failed");

        emit TokensUnstaked(_msgSender(), amount);
    }

    /// @notice Allows stakers to claim their accrued EchelonToken rewards.
    function claimStakingRewards() public onlyForgerWithSBT whenNotPaused {
        _distributeStakingRewards(_msgSender()); // This internally calculates and claims
    }

    /// @dev Internal function to calculate and distribute staking rewards.
    function _distributeStakingRewards(address staker) internal {
        StakingPosition storage pos = stakingPositions[staker];
        if (pos.amount == 0 || pos.lastInteractionBlock == block.number) {
            return; // No stake or already processed for this block
        }

        uint256 blocksPassed = block.number - pos.lastInteractionBlock;
        if (blocksPassed == 0) return; 

        // Rewards are calculated based on blocks passed and reward rate
        uint256 rewards = (pos.amount * rewardRatePerBlock * blocksPassed) / (10**18); // Scale for 18 decimals

        if (rewards > 0) {
            EchelonToken(echelonTokenAddress).mint(staker, rewards); // Use the protected mint function
            pos.rewardsClaimed += rewards;
            emit StakingRewardsClaimed(staker, rewards);
        }
        pos.lastInteractionBlock = block.number;
    }


    // --- VII. Admin & System Utilities ---

    /// @notice Pauses core contract functionalities (only by Owner/Guild Master).
    function pauseContract() public onlyOwnerOrGuildMaster {
        _pause();
    }

    /// @notice Unpauses core contract functionalities (only by Owner/Guild Master).
    function unpauseContract() public onlyOwnerOrGuildMaster {
        _unpause();
    }

    /// @notice Transfers the Guild Master role.
    /// @param newGuildMaster The address of the new Guild Master.
    function setGuildMaster(address newGuildMaster) public onlyGuildMaster {
        require(newGuildMaster != address(0), "EchelonForge: New Guild Master cannot be zero address");
        guildMaster = newGuildMaster;
    }

    /// @notice Allows Guild Master to withdraw funds from the contract treasury.
    /// @dev Can withdraw ETH or any ERC-20 token the contract holds.
    /// @param tokenAddress The address of the token to withdraw (address(0) for ETH).
    /// @param amount The amount to withdraw.
    function withdrawGuildFunds(address tokenAddress, uint256 amount) public onlyGuildMaster whenNotPaused {
        if (tokenAddress == address(0)) {
            payable(_msgSender()).transfer(amount);
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(_msgSender(), amount);
        }
    }

    // --- VIII. View Functions ---

    /// @notice Returns the total number of Forger SBTs minted.
    function getTotalForgersSBTs() public view returns (uint256) {
        return _nextForgersSBTId - 1;
    }

    /// @notice Returns the total number of skills defined in the tree.
    function getTotalSkills() public view returns (uint256) {
        return _nextSkillId - 1;
    }

    /// @notice Returns the total number of projects submitted.
    function getTotalProjects() public view returns (uint256) {
        return _nextProjectId - 1;
    }

    /// @notice Returns the number of active proposals.
    function getActiveProposalsCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i < _nextProposalId; i++) {
            if (proposals[i].startBlock <= block.number && block.number <= proposals[i].endBlock && !proposals[i].executed && !proposals[i].cancelled) {
                count++;
            }
        }
        return count;
    }

    /// @notice Returns the current voting power of an address, considering delegation.
    /// @param voter The address to check voting power for.
    /// @return The effective voting power.
    function getVotingPower(address voter) public view returns (uint256) {
        address delegatee = votingDelegates[voter];
        address effectiveVoter = (delegatee != address(0) ? delegatee : voter);
        // This simple model implies direct delegation. A more advanced model might aggregate power.
        return stakingPositions[effectiveVoter].amount;
    }

    /// @dev Utility modifier for functions callable by owner or guild master.
    modifier onlyOwnerOrGuildMaster() {
        require(_msgSender() == owner() || _msgSender() == guildMaster, "EchelonForge: Only owner or Guild Master can call this function");
        _;
    }

    // Fallback function to receive ETH
    receive() external payable {
        // ETH sent directly to the contract (e.g., for project funding)
    }
}
```