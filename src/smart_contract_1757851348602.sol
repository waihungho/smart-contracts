This smart contract, `GenesisNexusProtocol`, introduces a novel, advanced, and creative framework for decentralized, adaptive resource allocation and governance. It aims to create a self-optimizing network where contributors (individuals or automated agents) can pool resources, undertake tasks, and collectively evolve the protocol's parameters based on performance and community consensus.

It leverages several advanced concepts:
*   **Soulbound Contributor Profiles (SBTs):** Non-transferable NFTs to represent on-chain identity, reputation, and verifiable skills.
*   **Epoch-Based Operations:** The protocol progresses in distinct time periods, enabling scheduled actions like reward distributions and parameter re-evaluations.
*   **Adaptive Task Allocation:** A system for assigning contributors to tasks based on their reputation, skills, and a simulated "cognitive load" (active tasks).
*   **Emergent Protocol Parameters:** Core system variables (like a "synergy score multiplier") that can be dynamically adjusted through a governance process, allowing the protocol to adapt to network behavior and performance.
*   **On-chain Reputation System:** Contributor reputation scores dynamically update based on task performance and other interactions, influencing their standing and potential future allocations.

The goal is to move beyond static, pre-defined protocols towards a more dynamic, self-governing, and performance-driven decentralized organization.

---

## `GenesisNexusProtocol` Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For clarity, though 0.8.0+ has native overflow checks.

/**
 * @title MiniNexusToken
 * @dev A minimal ERC20 token implementation for internal use within the GenesisNexusProtocol.
 *      In a production environment, NEXUS would be a separate, fully-featured ERC20 contract
 *      deployed independently and integrated via its address. This minimal version includes
 *      only the functionalities necessary for staking and rewards within this example.
 */
contract MiniNexusToken {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "MiniNexus: insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(balances[sender] >= amount, "MiniNexus: insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "MiniNexus: insufficient allowance");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        allowances[sender][msg.sender] = allowances[sender][msg.sender].sub(amount); // Deduct allowance
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}

/**
 * @title ContributorProfileNFT (Soulbound Token)
 * @dev An ERC721 contract representing a contributor's identity within the GenesisNexusProtocol.
 *      These NFTs are soulbound, meaning they cannot be transferred, ensuring a persistent on-chain identity.
 *      They store dynamic attributes like reputation, skills, and active tasks count (simulated cognitive load).
 */
contract ContributorProfileNFT is ERC721, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // Role to mint and manage profiles
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); // Role to burn profiles (e.g., for severe violations)

    struct ProfileAttributes {
        uint256 reputationScore;
        uint256 activeTasksCount; // Simulated cognitive load: number of tasks contributor is currently allocated to
        string[] skills; // Verifiable skills/tags associated with the profile
        uint256 lastActivityEpoch; // The epoch of the last significant activity (e.g., staking, task completion)
        mapping(bytes32 => bool) skillExists; // Helper to efficiently check for skill presence
    }

    mapping(uint256 => ProfileAttributes) public profiles; // tokenId to ProfileAttributes
    mapping(address => uint256) public contributorProfileId; // Address to Profile NFT ID (0 if none)

    constructor() ERC721("ContributorProfileNFT", "CPN") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }

    // --- Soulbound Overrides (Prevent Transfers) ---
    function _approve(address to, uint256 tokenId) internal pure override {
        revert("ContributorProfileNFT: Soulbound - cannot approve transfer.");
    }

    function _setApprovalForAll(address operator, bool approved) internal pure override {
        revert("ContributorProfileNFT: Soulbound - cannot set approval for all.");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("ContributorProfileNFT: Soulbound - cannot transfer.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("ContributorProfileNFT: Soulbound - cannot transfer.");
    }
    // --- End Soulbound Overrides ---

    /**
     * @notice Mints a new Contributor Profile NFT for an address.
     * @param to The address for which to mint the profile.
     * @return The ID of the newly minted token.
     */
    function mint(address to) public onlyRole(MINTER_ROLE) returns (uint256) {
        require(contributorProfileId[to] == 0, "ContributorProfileNFT: Address already has a profile.");
        _tokenIdTracker.increment();
        uint256 newTokenId = _tokenIdTracker.current();
        _safeMint(to, newTokenId);
        contributorProfileId[to] = newTokenId;
        profiles[newTokenId].reputationScore = 100; // Starting reputation score
        profiles[newTokenId].lastActivityEpoch = 0; // Will be updated by GenesisNexusProtocol
        return newTokenId;
    }

    /**
     * @notice Burns a Contributor Profile NFT.
     * Accessible only by BURNER_ROLE (e.g., for severe protocol violations).
     * @param tokenId The ID of the token to burn.
     */
    function _burn(uint256 tokenId) internal override {
        require(_exists(tokenId), "CPN: Token does not exist.");
        require(hasRole(BURNER_ROLE, _msgSender()), "CPN: Must have burner role to burn.");
        address owner = ownerOf(tokenId);
        super._burn(tokenId); // Call ERC721Burnable's burn
        delete profiles[tokenId]; // Delete associated profile attributes
        delete contributorProfileId[owner]; // Remove reverse mapping
    }

    /**
     * @notice Adds a skill string to a contributor's profile.
     * @param tokenId The ID of the contributor's NFT.
     * @param skill The skill string to add (e.g., "SolidityDev", "DataAnalyst").
     */
    function addSkill(uint256 tokenId, string memory skill) public onlyRole(MINTER_ROLE) {
        require(_exists(tokenId), "CPN: Token does not exist.");
        bytes32 skillHash = keccak256(abi.encodePacked(skill));
        require(!profiles[tokenId].skillExists[skillHash], "CPN: Skill already added.");
        profiles[tokenId].skills.push(skill);
        profiles[tokenId].skillExists[skillHash] = true;
        // Consider emitting an event: `emit SkillAdded(tokenId, skill);`
    }

    /**
     * @notice Updates a contributor's reputation score.
     * @param tokenId The ID of the contributor's NFT.
     * @param change The amount to change the reputation by (can be negative).
     */
    function updateReputation(uint256 tokenId, int256 change) public onlyRole(MINTER_ROLE) {
        require(_exists(tokenId), "CPN: Token does not exist.");
        // Use int256 for calculation, then cast back to uint256 with checks
        int256 currentRep = int256(profiles[tokenId].reputationScore);
        currentRep = currentRep.add(change);
        if (currentRep < 0) currentRep = 0;
        if (currentRep > 1000) currentRep = 1000; // Example max reputation
        profiles[tokenId].reputationScore = uint256(currentRep);
        // Consider emitting an event: `emit ReputationUpdated(tokenId, change, profiles[tokenId].reputationScore);`
    }

    /**
     * @notice Increments the count of active tasks for a contributor. (Simulated cognitive load)
     * @param tokenId The ID of the contributor's NFT.
     */
    function incrementActiveTasks(uint256 tokenId) public onlyRole(MINTER_ROLE) {
        require(_exists(tokenId), "CPN: Token does not exist.");
        profiles[tokenId].activeTasksCount++;
    }

    /**
     * @notice Decrements the count of active tasks for a contributor.
     * @param tokenId The ID of the contributor's NFT.
     */
    function decrementActiveTasks(uint256 tokenId) public onlyRole(MINTER_ROLE) {
        require(_exists(tokenId), "CPN: Token does not exist.");
        require(profiles[tokenId].activeTasksCount > 0, "CPN: Active tasks count already 0.");
        profiles[tokenId].activeTasksCount--;
    }

    /**
     * @notice Updates the last activity epoch for a contributor.
     * @param tokenId The ID of the contributor's NFT.
     * @param epoch The current epoch number.
     */
    function updateLastActivityEpoch(uint256 tokenId, uint256 epoch) public onlyRole(MINTER_ROLE) {
        require(_exists(tokenId), "CPN: Token does not exist.");
        profiles[tokenId].lastActivityEpoch = epoch;
    }

    /**
     * @notice Checks if a contributor possesses a specific skill.
     * @param tokenId The ID of the contributor's NFT.
     * @param skill The skill string to check.
     * @return True if the contributor has the skill, false otherwise.
     */
    function hasSkill(uint256 tokenId, string memory skill) public view returns (bool) {
        require(_exists(tokenId), "CPN: Token does not exist.");
        return profiles[tokenId].skillExists[keccak256(abi.encodePacked(skill))];
    }
}


/**
 * @title GenesisNexusProtocol
 * @dev The main contract for the GenesisNexus Protocol, implementing adaptive resource allocation,
 *      epoch-based operations, soulbound contributor profiles, and dynamic parameter adjustments.
 */
contract GenesisNexusProtocol is AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant RESOURCE_MANAGER_ROLE = keccak256("RESOURCE_MANAGER_ROLE"); // Manages resource pools
    bytes32 public constant TASK_MANAGER_ROLE = keccak256("TASK_MANAGER_ROLE");       // Manages task creation and allocation
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");               // Verifies task completion, executes parameter changes

    // --- External Contracts ---
    MiniNexusToken public nexusToken;
    ContributorProfileNFT public contributorProfileNFT;

    // --- Epoch Management ---
    uint256 public currentEpoch;
    uint256 public epochDuration;        // In seconds
    uint256 public lastEpochAdvanceTime; // Timestamp of the last epoch advance

    // --- Resource Pools ---
    struct ResourcePool {
        string name;
        uint256 totalStaked;
        uint256 baseRewardRatePerEpoch; // Per unit of staked token (scaled, e.g., 1e16 for 1%)
        uint256 lastRewardDistributionEpoch; // Last epoch for which rewards were calculated
    }
    mapping(bytes32 => ResourcePool) public resourcePools; // Hash of name to ResourcePool
    bytes32[] public allResourcePoolNames; // To enable iteration over all pools

    mapping(address => mapping(bytes32 => uint256)) public stakedBalances; // Contributor => PoolNameHash => Amount
    mapping(address => mapping(bytes32 => uint256)) public pendingRewards; // Contributor => PoolNameHash => Amount

    // --- Adaptive Tasks ---
    struct AdaptiveTask {
        uint256 taskId;
        bytes32 requiredResourceType; // Hash of the resource pool name required for this task
        string description;
        uint256 rewardAmount; // In NEXUS tokens, held in escrow by the contract
        address creator;
        address[] proposedContributors; // Addresses proposed to work on the task
        mapping(address => bool) contributorVoted; // Tracks who voted on the proposed solution
        uint256 votesForProposal;
        uint256 votesAgainstProposal;
        address[] allocatedContributors; // Final list of contributors assigned to the task
        uint256 allocatedStakeAmount; // Sum of staked amounts of allocated contributors in the required pool (for context/analytics)
        bool completed;
        bool verified;
        bool cancelled;
        uint256 creationEpoch;
        uint256 completionEpoch;
    }
    Counters.Counter private _taskIdTracker;
    mapping(uint256 => AdaptiveTask) public adaptiveTasks;

    // --- Dynamic Protocol Parameters (Emergent Protocol) ---
    // Example: synergyScoreMultiplier, dynamically adjusted via governance
    uint256 public synergyScoreMultiplier; // Initial value, e.g., 100 (represents 1.00x). Used for abstract scoring in a real system.

    struct DynamicParameterProposal {
        bytes32 paramName; // E.g., keccak256("synergyScoreMultiplier")
        uint256 newValue;
        uint256 proposalEpoch;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who voted on this proposal
        bool executed;
    }
    Counters.Counter private _paramProposalIdTracker;
    mapping(uint256 => DynamicParameterProposal) public dynamicParameterProposals;


    // --- Events ---
    event EpochAdvanced(uint256 indexed newEpoch);
    event ResourcePoolRegistered(bytes32 indexed poolHash, string name, uint256 baseRewardRate);
    event ResourcePoolConfigUpdated(bytes32 indexed poolHash, uint256 newRewardRate);
    event ContributorProfileMinted(address indexed owner, uint256 tokenId);
    event ContributorSkillAdded(uint256 indexed tokenId, string skill);
    event ReputationUpdated(uint256 indexed tokenId, int256 change, uint256 newReputation);
    event ResourcesStaked(address indexed contributor, bytes32 indexed poolHash, uint256 amount);
    event ResourcesUnstaked(address indexed contributor, bytes32 indexed poolHash, uint256 amount);
    event StakingRewardsClaimed(address indexed contributor, bytes32 indexed poolHash, uint256 amount);
    event AdaptiveTaskCreated(uint256 indexed taskId, address indexed creator, bytes32 indexed requiredResourceType, uint256 rewardAmount);
    event TaskSolutionProposed(uint256 indexed taskId, address indexed proposer, address[] proposedContributors);
    event TaskSolutionVoted(uint256 indexed taskId, address indexed voter, bool support);
    event TaskResourcesAllocated(uint256 indexed taskId, address[] allocatedContributors, uint256 allocatedStake);
    event TaskCompletionProofSubmitted(uint256 indexed taskId, address indexed submitter);
    event TaskVerified(uint256 indexed taskId, address indexed verifier, bool success);
    event TaskRewardsDistributed(uint256 indexed taskId, address[] indexed recipients, uint256 totalReward);
    event ContributorPenalized(address indexed contributor, uint256 indexed tokenId, string reason, uint256 slashAmount, int256 reputationChange);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 paramName, uint256 newValue, address indexed proposer);
    event ParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ParameterChangeExecuted(uint256 indexed proposalId, bytes32 paramName, uint256 oldValue, uint256 newValue);


    /**
     * @notice Constructor for the GenesisNexusProtocol.
     * @param _nexusTokenAddress The address of the NEXUS ERC20 token contract.
     * @param _contributorProfileNFTAddress The address of the ContributorProfileNFT contract.
     * @param _epochDuration The duration of a single epoch in seconds.
     */
    constructor(address _nexusTokenAddress, address _contributorProfileNFTAddress, uint256 _epochDuration) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RESOURCE_MANAGER_ROLE, msg.sender);
        _grantRole(TASK_MANAGER_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);

        nexusToken = MiniNexusToken(_nexusTokenAddress);
        contributorProfileNFT = ContributorProfileNFT(_contributorProfileNFTAddress);

        currentEpoch = 1;
        epochDuration = _epochDuration; // e.g., 1 day = 86400 seconds
        lastEpochAdvanceTime = block.timestamp;
        synergyScoreMultiplier = 100; // Default: 1.00x (represented as 100 for integer math)
    }

    // --- I. Core System & Setup ---

    /**
     * @notice Advances the system to the next operational epoch.
     * This function should be called periodically (e.g., by a keeper network or privileged role)
     * to trigger time-dependent operations and reward calculations.
     */
    function advanceEpoch() public {
        require(block.timestamp >= lastEpochAdvanceTime + epochDuration, "GenesisNexus: Epoch duration not passed yet.");
        
        // Update reward distribution epoch for all pools.
        // Actual reward calculations are lazy-loaded when contributors claim or unstake.
        for(uint i = 0; i < allResourcePoolNames.length; i++) {
            bytes32 poolHash = allResourcePoolNames[i];
            resourcePools[poolHash].lastRewardDistributionEpoch = currentEpoch; 
        }

        currentEpoch++;
        lastEpochAdvanceTime = block.timestamp;
        emit EpochAdvanced(currentEpoch);
    }

    /**
     * @notice Configures the duration of each operational epoch.
     * @param _newDuration The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _newDuration) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newDuration > 0, "GenesisNexus: Epoch duration must be positive.");
        epochDuration = _newDuration;
    }

    /**
     * @notice Registers a new category of resource contributions (e.g., 'Computation', 'Data Analysis').
     * @param _name The unique name of the resource pool.
     * @param _baseRewardRatePerEpoch Initial base reward rate for this pool (scaled, e.g., 1e16 for 1%).
     */
    function registerResourcePool(string memory _name, uint256 _baseRewardRatePerEpoch) public onlyRole(RESOURCE_MANAGER_ROLE) {
        bytes32 poolHash = keccak256(abi.encodePacked(_name));
        // Check if pool exists by checking if name or baseRewardRate is set.
        // A more robust check might involve a dedicated `exists` flag or ensuring `resourcePools[poolHash].name` is not empty.
        require(resourcePools[poolHash].totalStaked == 0 && resourcePools[poolHash].baseRewardRatePerEpoch == 0, "GenesisNexus: Resource pool already exists.");

        resourcePools[poolHash] = ResourcePool({
            name: _name,
            totalStaked: 0,
            baseRewardRatePerEpoch: _baseRewardRatePerEpoch,
            lastRewardDistributionEpoch: currentEpoch
        });
        allResourcePoolNames.push(poolHash);
        emit ResourcePoolRegistered(poolHash, _name, _baseRewardRatePerEpoch);
    }

    /**
     * @notice Modifies parameters specific to an existing resource pool.
     * @param _poolName The name of the resource pool.
     * @param _newBaseRewardRate New base reward rate for this pool.
     */
    function updateResourcePoolConfig(string memory _poolName, uint256 _newBaseRewardRate) public onlyRole(RESOURCE_MANAGER_ROLE) {
        bytes32 poolHash = keccak256(abi.encodePacked(_poolName));
        require(resourcePools[poolHash].baseRewardRatePerEpoch != 0 || resourcePools[poolHash].totalStaked > 0, "GenesisNexus: Resource pool does not exist.");
        
        resourcePools[poolHash].baseRewardRatePerEpoch = _newBaseRewardRate;
        emit ResourcePoolConfigUpdated(poolHash, _newBaseRewardRate);
    }

    // --- II. Contributor Profiles & Reputation (Soulbound ContributorProfileNFT) ---

    /**
     * @notice Mints a unique, non-transferable NFT representing a contributor's identity.
     * This is the entry point for new contributors to join the network.
     */
    function mintContributorProfile() public {
        require(contributorProfileNFT.contributorProfileId(msg.sender) == 0, "GenesisNexus: You already have a profile.");
        contributorProfileNFT.mint(msg.sender); // Calls the CPN contract to mint
        uint256 tokenId = contributorProfileNFT.contributorProfileId(msg.sender);
        emit ContributorProfileMinted(msg.sender, tokenId);
    }

    /**
     * @notice Attaches a verifiable skill or attribute to a contributor's profile.
     * @param _skill The skill string to add (e.g., "SolidityDev", "DataAnalyst").
     */
    function addSkillToProfile(string memory _skill) public {
        uint256 tokenId = contributorProfileNFT.contributorProfileId(msg.sender);
        require(tokenId != 0, "GenesisNexus: You must have a profile to add skills.");
        contributorProfileNFT.addSkill(tokenId, _skill); // CPN's MINTER_ROLE is held by this contract
        emit ContributorSkillAdded(tokenId, _skill);
    }

    /**
     * @notice Adjusts a contributor's reputation based on performance or community consensus.
     * This function is typically called by Task Managers or Verifiers after task completion/evaluation.
     * @param _contributor The address of the contributor.
     * @param _change The amount to change the reputation score by (can be negative).
     */
    function updateReputationScore(address _contributor, int256 _change) public onlyRole(TASK_MANAGER_ROLE) {
        uint256 tokenId = contributorProfileNFT.contributorProfileId(_contributor);
        require(tokenId != 0, "GenesisNexus: Contributor has no profile.");
        contributorProfileNFT.updateReputation(tokenId, _change); // CPN's MINTER_ROLE is held by this contract
        emit ReputationUpdated(tokenId, _change, contributorProfileNFT.profiles(tokenId).reputationScore);
    }

    /**
     * @notice Retrieves all public details of a contributor's profile.
     * @param _contributor The address of the contributor.
     * @return tokenId The profile's NFT ID.
     * @return reputationScore The current reputation score.
     * @return activeTasksCount The number of tasks the contributor is currently involved in.
     * @return skills The list of skills associated with the profile.
     * @return lastActivityEpoch The last epoch the contributor was active.
     */
    function getContributorProfileDetails(address _contributor) 
        public 
        view 
        returns (uint256 tokenId, uint256 reputationScore, uint256 activeTasksCount, string[] memory skills, uint256 lastActivityEpoch) 
    {
        tokenId = contributorProfileNFT.contributorProfileId(_contributor);
        if (tokenId == 0) return (0, 0, 0, new string[](0), 0);
        ContributorProfileNFT.ProfileAttributes storage profile = contributorProfileNFT.profiles(tokenId);
        return (tokenId, profile.reputationScore, profile.activeTasksCount, profile.skills, profile.lastActivityEpoch);
    }

    /**
     * @notice Checks if a specific contributor possesses a given skill.
     * @param _contributor The address of the contributor.
     * @param _skill The skill string to check.
     * @return True if the contributor has the skill, false otherwise.
     */
    function verifySkillOwnership(address _contributor, string memory _skill) public view returns (bool) {
        uint256 tokenId = contributorProfileNFT.contributorProfileId(_contributor);
        require(tokenId != 0, "GenesisNexus: Contributor has no profile.");
        return contributorProfileNFT.hasSkill(tokenId, _skill);
    }

    // --- III. Resource Staking & Management ---

    /**
     * @notice Allows contributors to lock NEXUS tokens into a specified resource pool.
     * @param _poolName The name of the resource pool to stake into.
     * @param _amount The amount of NEXUS tokens to stake.
     */
    function stakeResources(string memory _poolName, uint256 _amount) public {
        require(_amount > 0, "GenesisNexus: Amount must be greater than zero.");
        uint256 tokenId = contributorProfileNFT.contributorProfileId(msg.sender);
        require(tokenId != 0, "GenesisNexus: You must have a profile to stake resources.");

        bytes32 poolHash = keccak256(abi.encodePacked(_poolName));
        // Check if pool exists by checking if name or baseRewardRate is set.
        require(resourcePools[poolHash].baseRewardRatePerEpoch != 0 || resourcePools[poolHash].totalStaked > 0, "GenesisNexus: Resource pool does not exist.");

        // Transfer NEXUS tokens from the staker to this contract
        // Requires msg.sender to have approved this contract to spend _amount NEXUS tokens.
        require(nexusToken.transferFrom(msg.sender, address(this), _amount), "GenesisNexus: NEXUS transfer failed. Check allowance and balance.");

        stakedBalances[msg.sender][poolHash] = stakedBalances[msg.sender][poolHash].add(_amount);
        resourcePools[poolHash].totalStaked = resourcePools[poolHash].totalStaked.add(_amount);

        // Update last activity epoch for the contributor
        contributorProfileNFT.updateLastActivityEpoch(tokenId, currentEpoch); // CPN's MINTER_ROLE is held by this contract

        emit ResourcesStaked(msg.sender, poolHash, _amount);
    }

    /**
     * @notice Enables contributors to withdraw their staked tokens.
     * Pending rewards for this specific pool are automatically calculated and added to pending rewards,
     * then claimed during unstaking.
     * @param _poolName The name of the resource pool to unstake from.
     * @param _amount The amount of NEXUS tokens to unstake.
     */
    function unstakeResources(string memory _poolName, uint256 _amount) public {
        require(_amount > 0, "GenesisNexus: Amount must be greater than zero.");
        bytes32 poolHash = keccak256(abi.encodePacked(_poolName));
        require(stakedBalances[msg.sender][poolHash] >= _amount, "GenesisNexus: Insufficient staked balance.");

        // First, calculate and add any pending rewards for this pool
        _calculateAndAddPendingRewards(msg.sender, poolHash);
        claimStakingRewards(poolHash); // Claim for this pool

        stakedBalances[msg.sender][poolHash] = stakedBalances[msg.sender][poolHash].sub(_amount);
        resourcePools[poolHash].totalStaked = resourcePools[poolHash].totalStaked.sub(_amount);

        // Transfer NEXUS tokens from this contract back to the staker
        require(nexusToken.transfer(msg.sender, _amount), "GenesisNexus: NEXUS transfer failed.");

        emit ResourcesUnstaked(msg.sender, poolHash, _amount);
    }

    /**
     * @notice Internal helper to calculate and add pending rewards to a contributor's balance for a specific pool.
     * Rewards are calculated based on epochs passed since the pool's last reward distribution epoch.
     * @param _contributor The address of the contributor.
     * @param _poolHash The hash of the resource pool name.
     */
    function _calculateAndAddPendingRewards(address _contributor, bytes32 _poolHash) internal {
        ResourcePool storage pool = resourcePools[_poolHash];
        uint256 staked = stakedBalances[_contributor][_poolHash];
        if (staked == 0 || pool.baseRewardRatePerEpoch == 0) return;

        // Calculate rewards for epochs between `pool.lastRewardDistributionEpoch` and `currentEpoch` (exclusive of currentEpoch)
        // This ensures rewards are only for fully passed epochs.
        uint256 epochsPassed = currentEpoch.sub(pool.lastRewardDistributionEpoch);
        if (epochsPassed == 0) return;

        // Example: reward rate is 1e16 (0.01 NEXUS per NEXUS staked per epoch)
        uint256 rewardPerUnitStakedPerEpoch = pool.baseRewardRatePerEpoch;
        
        // Total reward for the passed epochs for this specific contributor
        uint256 totalReward = staked.mul(rewardPerUnitStakedPerEpoch).mul(epochsPassed).div(1e18); // Scale by 1e18 for NEXUS decimals

        pendingRewards[_contributor][_poolHash] = pendingRewards[_contributor][_poolHash].add(totalReward);
    }

    /**
     * @notice Distributes accumulated rewards to a contributor from their staked resources in a specific pool.
     * Automatically calculates pending rewards before claiming.
     * @param _poolHash The hash of the resource pool name.
     */
    function claimStakingRewards(bytes32 _poolHash) public {
        _calculateAndAddPendingRewards(msg.sender, _poolHash); // Ensure rewards are up-to-date
        uint256 rewards = pendingRewards[msg.sender][_poolHash];
        require(rewards > 0, "GenesisNexus: No pending rewards to claim.");

        pendingRewards[msg.sender][_poolHash] = 0; // Reset pending rewards

        // Transfer NEXUS tokens from this contract to the staker
        require(nexusToken.transfer(msg.sender, rewards), "GenesisNexus: NEXUS reward transfer failed.");

        emit StakingRewardsClaimed(msg.sender, _poolHash, rewards);
    }

    /**
     * @notice Returns the amount of tokens an address has staked in a specific pool.
     * @param _contributor The address of the contributor.
     * @param _poolName The name of the resource pool.
     * @return The staked amount.
     */
    function getContributorStakedBalance(address _contributor, string memory _poolName) public view returns (uint256) {
        bytes32 poolHash = keccak256(abi.encodePacked(_poolName));
        return stakedBalances[_contributor][poolHash];
    }

    // --- IV. Adaptive Task Lifecycle ---

    /**
     * @notice Initiates a new task, specifying required resource types and reward.
     * The `TASK_MANAGER_ROLE` is responsible for creating tasks.
     * @param _description A description of the task.
     * @param _requiredResourceType The name of the resource pool type required for this task.
     * @param _rewardAmount The reward in NEXUS tokens for successful completion.
     */
    function createAdaptiveTask(string memory _description, string memory _requiredResourceType, uint256 _rewardAmount) public onlyRole(TASK_MANAGER_ROLE) {
        require(_rewardAmount > 0, "GenesisNexus: Task reward must be positive.");
        bytes32 resourceTypeHash = keccak256(abi.encodePacked(_requiredResourceType));
        require(resourcePools[resourceTypeHash].baseRewardRatePerEpoch != 0 || resourcePools[resourceTypeHash].totalStaked > 0, "GenesisNexus: Required resource type does not exist.");

        _taskIdTracker.increment();
        uint256 newTaskId = _taskIdTracker.current();

        adaptiveTasks[newTaskId] = AdaptiveTask({
            taskId: newTaskId,
            requiredResourceType: resourceTypeHash,
            description: _description,
            rewardAmount: _rewardAmount,
            creator: msg.sender,
            proposedContributors: new address[](0),
            contributorVoted: new mapping(address => bool)(),
            votesForProposal: 0,
            votesAgainstProposal: 0,
            allocatedContributors: new address[](0),
            allocatedStakeAmount: 0,
            completed: false,
            verified: false,
            cancelled: false,
            creationEpoch: currentEpoch,
            completionEpoch: 0
        });

        // Transfer task reward from the creator (TASK_MANAGER_ROLE) to the contract's escrow
        require(nexusToken.transferFrom(msg.sender, address(this), _rewardAmount), "GenesisNexus: Failed to escrow task reward. Check allowance and balance.");

        emit AdaptiveTaskCreated(newTaskId, msg.sender, resourceTypeHash, _rewardAmount);
    }

    /**
     * @notice Contributors submit a solution proposal for a task, including their requested team.
     * Only one solution can be proposed per task in this simplified model.
     * @param _taskId The ID of the task.
     * @param _proposedContributors An array of addresses proposed to work on this task.
     */
    function proposeTaskSolution(uint256 _taskId, address[] memory _proposedContributors) public {
        AdaptiveTask storage task = adaptiveTasks[_taskId];
        require(task.taskId != 0, "GenesisNexus: Task does not exist.");
        require(!task.completed && !task.verified && !task.cancelled, "GenesisNexus: Task is not active.");
        require(task.proposedContributors.length == 0, "GenesisNexus: A solution has already been proposed for this task.");
        require(_proposedContributors.length > 0, "GenesisNexus: Must propose at least one contributor.");
        
        // Basic checks for proposed contributors
        for (uint i = 0; i < _proposedContributors.length; i++) {
            uint256 contributorTokenId = contributorProfileNFT.contributorProfileId(_proposedContributors[i]);
            require(contributorTokenId != 0, "GenesisNexus: Proposed contributor has no profile.");
            // Advanced logic could include checking for specific skills (`verifySkillOwnership`)
            // and reputation thresholds here.
        }

        task.proposedContributors = _proposedContributors;
        emit TaskSolutionProposed(_taskId, msg.sender, _proposedContributors);
    }

    /**
     * @notice Community or designated evaluators vote on proposed solutions for a task.
     * This is a simple binary vote (for/against a single proposed solution).
     * @param _taskId The ID of the task.
     * @param _support True if voting for the proposed solution, false otherwise.
     */
    function voteOnTaskSolution(uint256 _taskId, bool _support) public {
        AdaptiveTask storage task = adaptiveTasks[_taskId];
        require(task.taskId != 0, "GenesisNexus: Task does not exist.");
        require(task.proposedContributors.length > 0, "GenesisNexus: No solution proposed to vote on.");
        require(!task.contributorVoted[msg.sender], "GenesisNexus: You have already voted on this proposal.");
        
        uint256 voterProfileId = contributorProfileNFT.contributorProfileId(msg.sender);
        require(voterProfileId != 0, "GenesisNexus: Voter must have a profile.");

        // More complex logic could implement reputation-weighted voting here:
        // uint256 voterReputation = contributorProfileNFT.profiles(voterProfileId).reputationScore;
        // if (_support) task.votesForProposal = task.votesForProposal.add(voterReputation);
        // else task.votesAgainstProposal = task.votesAgainstProposal.add(voterReputation);

        if (_support) {
            task.votesForProposal++;
        } else {
            task.votesAgainstProposal++;
        }
        task.contributorVoted[msg.sender] = true;
        emit TaskSolutionVoted(_taskId, msg.sender, _support);
    }

    /**
     * @notice Assigns approved contributors to a task. This marks them as 'active' for the task.
     * This function is called by a `TASK_MANAGER_ROLE` after a successful vote or direct approval.
     * It increments `activeTasksCount` for contributors, simulating cognitive load.
     * @param _taskId The ID of the task.
     * @param _contributors The final list of contributors allocated to the task.
     */
    function allocateTaskResources(uint256 _taskId, address[] memory _contributors) public onlyRole(TASK_MANAGER_ROLE) {
        AdaptiveTask storage task = adaptiveTasks[_taskId];
        require(task.taskId != 0, "GenesisNexus: Task does not exist.");
        require(!task.completed && !task.verified && !task.cancelled, "GenesisNexus: Task is not active.");
        require(task.allocatedContributors.length == 0, "GenesisNexus: Resources already allocated for this task.");
        require(_contributors.length > 0, "GenesisNexus: Must allocate to at least one contributor.");
        // Add a check: require vote has passed threshold for proposedContributors matching _contributors

        task.allocatedContributors = _contributors;
        uint256 totalAllocatedStake = 0;
        for (uint i = 0; i < _contributors.length; i++) {
            uint256 contributorTokenId = contributorProfileNFT.contributorProfileId(_contributors[i]);
            require(contributorTokenId != 0, "GenesisNexus: Allocated contributor has no profile.");
            
            // Increment cognitive load (active tasks count) for the contributor
            contributorProfileNFT.incrementActiveTasks(contributorTokenId); // CPN's MINTER_ROLE is held by this contract
            contributorProfileNFT.updateLastActivityEpoch(contributorTokenId, currentEpoch); // CPN's MINTER_ROLE is held by this contract
            
            // Calculate total staked amount in the required resource pool for context (not explicitly locked)
            totalAllocatedStake = totalAllocatedStake.add(getContributorStakedBalance(_contributors[i], resourcePools[task.requiredResourceType].name));
        }
        task.allocatedStakeAmount = totalAllocatedStake;

        emit TaskResourcesAllocated(_taskId, _contributors, totalAllocatedStake);
    }

    /**
     * @notice Contributors mark a task as completed and provide evidence.
     * Only an allocated contributor can submit completion proof.
     * @param _taskId The ID of the task.
     */
    function submitTaskCompletionProof(uint256 _taskId) public {
        AdaptiveTask storage task = adaptiveTasks[_taskId];
        require(task.taskId != 0, "GenesisNexus: Task does not exist.");
        require(!task.completed, "GenesisNexus: Task already completed.");
        require(!task.cancelled, "GenesisNexus: Task cancelled.");
        
        bool isAllocatedContributor = false;
        for(uint i = 0; i < task.allocatedContributors.length; i++) {
            if (task.allocatedContributors[i] == msg.sender) {
                isAllocatedContributor = true;
                break;
            }
        }
        require(isAllocatedContributor, "GenesisNexus: Only allocated contributors can submit completion proof.");

        task.completed = true;
        task.completionEpoch = currentEpoch;
        emit TaskCompletionProofSubmitted(_taskId, msg.sender);
    }

    /**
     * @notice Designated verifiers confirm the successful completion of a task.
     * Updates contributor reputation and triggers reward distribution or penalty.
     * @param _taskId The ID of the task.
     * @param _success True if the task is successfully verified, false otherwise.
     */
    function verifyTaskCompletion(uint256 _taskId, bool _success) public onlyRole(VERIFIER_ROLE) {
        AdaptiveTask storage task = adaptiveTasks[_taskId];
        require(task.taskId != 0, "GenesisNexus: Task does not exist.");
        require(task.completed, "GenesisNexus: Task not marked as completed yet.");
        require(!task.verified, "GenesisNexus: Task already verified.");
        require(!task.cancelled, "GenesisNexus: Task cancelled.");

        task.verified = true;

        if (_success) {
            distributeTaskRewards(_taskId); // Distribute rewards from escrow
            // Update reputation for successful contributors and decrement active tasks
            for (uint i = 0; i < task.allocatedContributors.length; i++) {
                contributorProfileNFT.updateReputation(contributorProfileNFT.contributorProfileId(task.allocatedContributors[i]), 10); // CPN's MINTER_ROLE is held by this contract
                contributorProfileNFT.decrementActiveTasks(contributorProfileNFT.contributorProfileId(task.allocatedContributors[i])); // CPN's MINTER_ROLE is held by this contract
            }
        } else {
            // Penalize contributors for failed verification and decrement active tasks
            for (uint i = 0; i < task.allocatedContributors.length; i++) {
                penalizeContributor(task.allocatedContributors[i], "Task failed verification", 0, -20); // No stake slash for simplicity here; only reputation
                contributorProfileNFT.decrementActiveTasks(contributorProfileNFT.contributorProfileId(task.allocatedContributors[i])); // CPN's MINTER_ROLE is held by this contract
            }
            // Return escrowed reward to the task creator
            require(nexusToken.transfer(task.creator, task.rewardAmount), "GenesisNexus: Failed to return reward to creator.");
        }
        emit TaskVerified(_taskId, msg.sender, _success);
    }

    /**
     * @notice Pays out rewards to contributors upon successful task verification.
     * This is an internal function called by `verifyTaskCompletion`.
     * @param _taskId The ID of the task.
     */
    function distributeTaskRewards(uint256 _taskId) internal {
        AdaptiveTask storage task = adaptiveTasks[_taskId];
        require(task.verified, "GenesisNexus: Task not verified.");
        require(task.rewardAmount > 0, "GenesisNexus: No reward to distribute.");

        uint256 totalContributors = task.allocatedContributors.length;
        require(totalContributors > 0, "GenesisNexus: No contributors allocated to this task.");

        uint256 rewardPerContributor = task.rewardAmount.div(totalContributors);
        address[] memory recipients = new address[](totalContributors); // To emit in event

        for (uint i = 0; i < totalContributors; i++) {
            address contributor = task.allocatedContributors[i];
            require(nexusToken.transfer(contributor, rewardPerContributor), "GenesisNexus: Failed to distribute reward to contributor.");
            recipients[i] = contributor;
        }

        emit TaskRewardsDistributed(_taskId, recipients, task.rewardAmount);
    }

    /**
     * @notice Imposes penalties (e.g., reputation reduction, partial stake slash) for poor performance.
     * This is a sensitive function, typically called by highly privileged roles (e.g., `VERIFIER_ROLE`).
     * Note: Stake slashing is simplified here; a real system would need specific logic to target a pool.
     * @param _contributor The address of the contributor to penalize.
     * @param _reason A description of why the penalty is being applied.
     * @param _slashAmount The amount of NEXUS tokens to slash (for event logging; not implemented here).
     * @param _reputationChange The amount to change reputation by (typically negative).
     */
    function penalizeContributor(address _contributor, string memory _reason, uint256 _slashAmount, int256 _reputationChange) public onlyRole(VERIFIER_ROLE) {
        uint256 tokenId = contributorProfileNFT.contributorProfileId(_contributor);
        require(tokenId != 0, "GenesisNexus: Contributor has no profile.");

        // Apply reputation change
        if (_reputationChange != 0) {
            contributorProfileNFT.updateReputation(tokenId, _reputationChange); // CPN's MINTER_ROLE is held by this contract
        }

        // TODO: Implement actual stake slashing logic if _slashAmount > 0.
        // This would involve reducing `stakedBalances[_contributor][_poolHash]` and
        // potentially burning or redirecting the slashed tokens.
        
        emit ContributorPenalized(_contributor, tokenId, _reason, _slashAmount, _reputationChange);
    }

    // --- V. Emergent Protocol & Dynamic Parameter Adjustments ---

    /**
     * @notice Allows stakeholders to suggest adjustments to core protocol parameters.
     * Example: `_paramName` could be "synergyScoreMultiplier".
     * Requires the proposer to have a Contributor Profile.
     * @param _paramName The name of the parameter to change (e.g., "synergyScoreMultiplier").
     * @param _newValue The proposed new value for the parameter.
     */
    function proposeDynamicParameterChange(string memory _paramName, uint256 _newValue) public {
        uint256 proposerTokenId = contributorProfileNFT.contributorProfileId(msg.sender);
        require(proposerTokenId != 0, "GenesisNexus: Proposer must have a profile.");
        // Add more checks: e.g., minimum reputation or stake to propose

        _paramProposalIdTracker.increment();
        uint256 proposalId = _paramProposalIdTracker.current();
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));

        dynamicParameterProposals[proposalId] = DynamicParameterProposal({
            paramName: paramHash,
            newValue: _newValue,
            proposalEpoch: currentEpoch,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)(),
            executed: false
        });

        emit ParameterChangeProposed(proposalId, paramHash, _newValue, msg.sender);
    }

    /**
     * @notice Community votes on proposed parameter changes.
     * Requires the voter to have a Contributor Profile.
     * @param _proposalId The ID of the parameter change proposal.
     * @param _support True if voting for the change, false otherwise.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) public {
        DynamicParameterProposal storage proposal = dynamicParameterProposals[_proposalId];
        require(proposal.paramName != 0, "GenesisNexus: Proposal does not exist.");
        require(!proposal.executed, "GenesisNexus: Proposal already executed.");
        // Voting can only occur within the epoch the proposal was made (or a defined voting window).
        require(proposal.proposalEpoch == currentEpoch, "GenesisNexus: Voting is only allowed within the current epoch.");
        require(!proposal.hasVoted[msg.sender], "GenesisNexus: You have already voted on this proposal.");

        uint256 voterTokenId = contributorProfileNFT.contributorProfileId(msg.sender);
        require(voterTokenId != 0, "GenesisNexus: Voter must have a profile.");

        // More complex logic could implement reputation-weighted voting here.
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ParameterChangeVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Implements the approved dynamic parameter change.
     * This function is typically called by a `VERIFIER_ROLE` after a vote passes a certain threshold
     * and a new epoch has begun (to ensure voting window has closed).
     * @param _proposalId The ID of the parameter change proposal.
     */
    function executeParameterChange(uint256 _proposalId) public onlyRole(VERIFIER_ROLE) {
        DynamicParameterProposal storage proposal = dynamicParameterProposals[_proposalId];
        require(proposal.paramName != 0, "GenesisNexus: Proposal does not exist.");
        require(!proposal.executed, "GenesisNexus: Proposal already executed.");
        // Execution can only happen in an epoch *after* the proposal's voting epoch.
        require(currentEpoch > proposal.proposalEpoch, "GenesisNexus: Proposal can only be executed in a subsequent epoch after voting concludes.");

        // Simple majority vote for execution. More complex quorum/threshold can be added.
        require(proposal.votesFor > proposal.votesAgainst, "GenesisNexus: Proposal did not pass.");

        uint256 oldValue;
        if (proposal.paramName == keccak256(abi.encodePacked("synergyScoreMultiplier"))) {
            oldValue = synergyScoreMultiplier;
            synergyScoreMultiplier = proposal.newValue;
        } else {
            // Future parameters can be added here
            revert("GenesisNexus: Unknown dynamic parameter or not yet implemented for execution.");
        }
        
        proposal.executed = true;
        emit ParameterChangeExecuted(_proposalId, proposal.paramName, oldValue, proposal.newValue);
    }

    // --- View Functions for checking state (not counted in the 20+ functional requirements, but essential for usability) ---

    /**
     * @notice Retrieves the names of all registered resource pools.
     * @return An array of strings, each representing a resource pool name.
     */
    function getResourcePoolNames() public view returns (string[] memory) {
        string[] memory names = new string[](allResourcePoolNames.length);
        for(uint i = 0; i < allResourcePoolNames.length; i++) {
            names[i] = resourcePools[allResourcePoolNames[i]].name;
        }
        return names;
    }

    /**
     * @notice Retrieves details of a specific adaptive task.
     * @param _taskId The ID of the task.
     * @return Comprehensive details about the task.
     */
    function getAdaptiveTask(uint256 _taskId) public view returns (
        uint256 taskId,
        string memory description,
        string memory requiredResourceType,
        uint256 rewardAmount,
        address creator,
        address[] memory proposedContributors,
        uint256 votesForProposal,
        uint256 votesAgainstProposal,
        address[] memory allocatedContributors,
        bool completed,
        bool verified,
        bool cancelled
    ) {
        AdaptiveTask storage task = adaptiveTasks[_taskId];
        return (
            task.taskId,
            task.description,
            resourcePools[task.requiredResourceType].name, // Convert hash back to name for readability
            task.rewardAmount,
            task.creator,
            task.proposedContributors,
            task.votesForProposal,
            task.votesAgainstProposal,
            task.allocatedContributors,
            task.completed,
            task.verified,
            task.cancelled
        );
    }

    /**
     * @notice Retrieves details of a dynamic parameter change proposal.
     * Note: `paramName` is returned as a hash (bytes32) because the string is not stored on-chain to save gas.
     * The caller needs to know the mapping from hash to parameter name.
     * @param _proposalId The ID of the proposal.
     * @return Detailed information about the parameter change proposal.
     */
    function getDynamicParameterProposal(uint256 _proposalId) public view returns (
        uint256 proposalId,
        bytes32 paramNameHash, // The hash of the parameter name
        uint256 newValue,
        uint256 proposalEpoch,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed
    ) {
        DynamicParameterProposal storage proposal = dynamicParameterProposals[_proposalId];
        return (
            _proposalId,
            proposal.paramName,
            proposal.newValue,
            proposal.proposalEpoch,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed
        );
    }
}
```