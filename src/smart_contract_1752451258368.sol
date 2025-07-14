Okay, here is a concept for an advanced and creative smart contract called "EcoSphere". It combines elements of Regenerative Finance (ReFi), Gamification, Dynamic NFTs, and On-chain Governance. It focuses on simulating ecological contributions, nurturing dynamic NFT "Habitats", and managing the system through token-weighted voting, with a global "System Health" score that affects dynamics.

This contract will include:
1.  An internal ERC-20 token (`EcoPoints`) representing earned value for ecological actions.
2.  An internal dynamic ERC-721 token (`EcoNFTs`) representing unique ecological "Habitats" that can be improved.
3.  Mechanisms to simulate "contributions" and earn EcoPoints.
4.  Mechanisms to use EcoPoints to "nurture" or "upgrade" EcoNFTs, changing their properties.
5.  A global `systemHealthScore` that dynamically influences rewards and NFT properties.
6.  A simple on-chain governance system based on EcoPoint holdings.
7.  Role-based access control for certain administrative functions.

**Disclaimer:** This is a complex example for demonstration purposes. Real-world deployment would require extensive audits, gas optimization, and potentially breaking down functionality into multiple contracts. The "contribution" simulation is simplified.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- EcoSphere Smart Contract Outline ---
//
// 1.  Assets: Manages EcoPoints (ERC20) and EcoNFTs (ERC721) internally.
// 2.  Core Mechanics: Contribution simulation, NFT nurturing/upgrading.
// 3.  Dynamic System: Global systemHealthScore affecting rewards and NFTs.
// 4.  Staking: Users can stake EcoPoints to earn rewards.
// 5.  Governance: Token-weighted proposals and voting for system parameters.
// 6.  Access Control & Pausing: Roles for admin tasks, emergency pause.
// 7.  Query Functions: View current state, user data, project info, etc.

// --- EcoSphere Function Summary ---
//
// Constructor: Initializes contract, roles, mints initial tokens (optional).
//
// **Core Asset Management (Internal ERC20/ERC721)**
// 1. name(): ERC20/ERC721 standard name.
// 2. symbol(): ERC20/ERC721 standard symbol.
// 3. decimals(): ERC20 standard decimals (for EcoPoints).
// 4. totalSupply(): ERC20 standard total supply (for EcoPoints).
// 5. balanceOf(account): ERC20 standard balance query (for EcoPoints).
// 6. ownerOf(tokenId): ERC721 standard owner query (for EcoNFTs).
// 7. tokenURI(tokenId): ERC721 standard metadata URI query (dynamic).
// 8. mintEcoNFT(to, initialAttributes): Mints a new EcoNFT to an address (ADMIN_ROLE).
// 9. safeTransferFrom(from, to, tokenId): ERC721 standard transfer.
// 10. approve(to, tokenId): ERC721 standard approval.
// 11. setApprovalForAll(operator, approved): ERC721 standard operator approval.
// 12. getApproved(tokenId): ERC721 standard approval query.
// 13. isApprovedForAll(owner, operator): ERC721 standard operator approval query.
//
// **Core Mechanics & Dynamics**
// 14. addEcologicalProject(id, name, description, baseRewardRate): Adds a new project (PROJECT_MANAGER_ROLE).
// 15. contributeToProject(projectId, amount): Simulate contribution, earn EcoPoints based on amount and system health.
// 16. nurtureNFT(tokenId, points): Spend EcoPoints to increase an EcoNFT's 'health'.
// 17. upgradeNFT(tokenId): Upgrade an EcoNFT's 'level' if conditions met (e.g., enough health, points).
// 18. updateSystemHealth(newHealthScore): Update the global health score (HEALTH_ORACLE_ROLE).
// 19. calculateDynamicReward(projectId, amount): View function to estimate reward for contribution (dynamic).
// 20. calculateDynamicNFTProperty(tokenId, propertyType): View function to calculate a dynamic NFT property.
//
// **Staking**
// 21. stakeEcoPoints(amount): Stake EcoPoints to earn rewards.
// 22. unstakeEcoPoints(amount): Unstake EcoPoints.
// 23. claimStakingRewards(): Claim accumulated staking rewards.
// 24. getStakedBalance(account): Query user's staked balance.
// 25. getStakingRewardEstimate(account): Query estimated pending staking rewards.
//
// **Governance**
// 26. createProposal(description, targetFunction, callData, stakeAmount): Create a new governance proposal (requires stake, PROPOSER_ROLE).
// 27. voteOnProposal(proposalId, support): Vote on a proposal (token-weighted).
// 28. executeProposal(proposalId): Execute a successful proposal.
// 29. cancelProposal(proposalId): Cancel a proposal before voting starts (proposer/admin).
// 30. getProposalState(proposalId): Get the current state of a proposal.
// 31. getVotingPower(account): Get user's current voting power (based on EcoPoints).
//
// **Admin & Access Control**
// 32. grantRole(role, account): Grant a role (DEFAULT_ADMIN_ROLE).
// 33. revokeRole(role, account): Revoke a role (DEFAULT_ADMIN_ROLE).
// 34. renounceRole(role): Renounce own role.
// 35. pause(): Pause contract operations (PAUSER_ROLE).
// 36. unpause(): Unpause contract operations (PAUSER_ROLE).
// 37. withdrawAdminFees(tokenAddress, amount): Withdraw accumulated fees/donations (ADMIN_ROLE - Simplified).
//
// **Query & Utility (continued)**
// 38. getProjectDetails(projectId): View details of a project.
// 39. getNFTDetails(tokenId): View dynamic details of an EcoNFT.
// 40. getUserContribution(account, projectId): View user's contribution to a project.
// 41. getProposalDetails(proposalId): View details of a proposal.
// 42. getProposalVoteCounts(proposalId): View vote counts for a proposal.

contract EcoSphere is ERC20, ERC721, AccessControl, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant PROJECT_MANAGER_ROLE = keccak256("PROJECT_MANAGER_ROLE");
    bytes32 public constant HEALTH_ORACLE_ROLE = keccak256("HEALTH_ORACLE_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // --- Assets ---
    // EcoPoints are the internal ERC20 token
    // EcoNFTs are the internal ERC721 token

    // --- Core Mechanics State ---
    struct EcologicalProject {
        uint256 id;
        string name;
        string description;
        uint256 baseRewardRate; // EcoPoints per unit of contribution
        bool isActive;
        uint256 totalContributed;
    }

    mapping(uint256 => EcologicalProject) public projects;
    Counters.Counter private _projectIds;
    mapping(address => mapping(uint256 => uint256)) public userContributions; // user => projectId => amount

    struct NFTAttributes {
        uint256 baseBiodiversityScore; // Base static score
        uint256 nurturedHealth;       // Increased by nurturing
        uint256 level;                // Increased by upgrading
        uint64 lastNurturedTimestamp;
    }

    mapping(uint256 => NFTAttributes) private _nftAttributes; // tokenId => attributes

    // --- Dynamic System State ---
    uint256 public systemHealthScore; // Represents overall system health, 0-10000 (scaled for precision)
    uint256 public constant MAX_HEALTH_SCORE = 10000;

    // Factors influencing dynamic rewards/properties
    uint256 public healthImpactFactorReward = 100; // % impact on reward (100 = 1x base reward at MAX_HEALTH_SCORE, 0 at 0)
    uint256 public healthImpactFactorNFT = 50;    // % impact on NFT property calculation

    // --- Staking State ---
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) private _stakingRewards; // accumulated rewards
    uint256 public stakingRewardRatePerPointPerSecond = 1e12; // Example: 1e12 wei-scaled EcoPoints per staked point per second (very small)
    mapping(address => uint256) private _lastStakingRewardCalcTimestamp;

    // --- Governance State ---
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed, Canceled }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes targetFunction; // ABI encoded function call on this contract
        uint256 stakeAmount;  // Amount staked by proposer
        uint64 voteStartTimestamp;
        uint64 voteEndTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // proposalId => voterAddress => voted?

    uint64 public votingPeriodSeconds = 3 days;
    uint256 public proposalStakeRequired = 1000e18; // 1000 EcoPoints to create proposal
    uint256 public quorumPercentage = 4;           // 4% of total supply needed for quorum (scaled by 10000)
    uint256 public proposalThresholdPercentage = 5000; // 50% + 1 vote needed to pass (scaled by 10000)

    // --- Events ---
    event ProjectAdded(uint256 indexed id, string name, address indexed manager);
    event ProjectCompleted(uint256 indexed id);
    event ContributionMade(address indexed contributor, uint256 indexed projectId, uint256 amount, uint256 earnedEcoPoints);
    event NFTNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 pointsSpent, uint256 newHealth);
    event NFTUpgraded(uint256 indexed tokenId, address indexed upgrader, uint256 newLevel);
    event SystemHealthUpdated(uint256 newHealthScore);
    event TokensStaked(address indexed account, uint256 amount);
    event TokensUnstaked(address indexed account, uint256 amount);
    event StakingRewardsClaimed(address indexed account, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint64 voteEnd);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ProposalCanceled(uint256 indexed proposalId);
    event AdminFeesWithdrawn(address indexed token, uint256 amount, address indexed receiver);

    constructor(address adminAddress)
        ERC20("EcoPoint", "EP")
        ERC721("EcoHabitat", "EHNFT")
        Pausable() // Pausable is inherited last
    {
        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _grantRole(PAUSER_ROLE, adminAddress);
        // Grant initial roles, more can be granted later via governance or admin
        _grantRole(PROJECT_MANAGER_ROLE, adminAddress);
        _grantRole(HEALTH_ORACLE_ROLE, adminAddress);
        _grantRole(PROPOSER_ROLE, adminAddress);

        // Initial system health
        systemHealthScore = MAX_HEALTH_SCORE / 2; // Start neutral
    }

    // --- ERC20/ERC721 Standard Implementations (Internal) ---

    // name, symbol, decimals, totalSupply, balanceOf are provided by ERC20 inheritance
    // ownerOf, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll are provided by ERC721 inheritance

    // tokenURI - Dynamic based on NFT attributes
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        NFTAttributes storage attrs = _nftAttributes[tokenId];
        // In a real contract, this would point to a metadata service
        // that generates JSON based on tokenId and the dynamic attributes.
        // For demonstration, return a placeholder showing some state.
        // Example: ipfs://.../{tokenId}?health={health}&level={level}
        return string(abi.encodePacked(
            "ipfs://",
            _toString(tokenId),
            "?health=", _toString(attrs.nurturedHealth),
            "&level=", _toString(attrs.level),
            "&systemHealth=", _toString(systemHealthScore)
        ));
    }

    // Minting EcoNFTs (Admin controlled)
    function mintEcoNFT(address to, uint256 baseBiodiversityScore_)
        public onlyRole(PROJECT_MANAGER_ROLE) whenNotPaused
    {
        uint256 newItemId = _nextTokenId();
        _mint(to, newItemId);
        _nftAttributes[newItemId] = NFTAttributes({
            baseBiodiversityScore: baseBiodiversityScore_,
            nurturedHealth: 0, // Starts at 0 additional health
            level: 1,        // Starts at level 1
            lastNurturedTimestamp: uint64(block.timestamp)
        });
        emit Transfer(address(0), to, newItemId); // ERC721 Transfer event
    }

    // Helper to get the next token ID (used internally by mint)
    Counters.Counter private _tokenIds;
    function _nextTokenId() private returns (uint256) {
        _tokenIds.increment();
        return _tokenIds.current();
    }

    // --- Core Mechanics Functions ---

    // Add a new ecological project (Admin/Manager controlled)
    function addEcologicalProject(uint256 id, string memory name_, string memory description_, uint256 baseRewardRate_)
        public onlyRole(PROJECT_MANAGER_ROLE) whenNotPaused
    {
        require(projects[id].id == 0, "Project ID already exists"); // Basic check if ID is already used
        _projectIds.increment(); // Use counter if preferring sequential IDs, or use the provided ID
        // Note: If using external IDs, the counter logic should be adjusted or removed.
        // Using the provided ID directly here as requested by function signature.

        projects[id] = EcologicalProject({
            id: id,
            name: name_,
            description: description_,
            baseRewardRate: baseRewardRate_,
            isActive: true,
            totalContributed: 0
        });
        emit ProjectAdded(id, name_, _msgSender());
    }

    // Simulate contribution to a project
    // In a real scenario, this would verify proof of contribution (e.g., through oracle, external system call)
    // Here, it's simplified: user calls this function and specifies contribution amount
    function contributeToProject(uint256 projectId, uint256 amount) public whenNotPaused {
        require(projects[projectId].isActive, "Project is not active");
        require(amount > 0, "Contribution amount must be greater than 0");

        // Simulate earning EcoPoints based on contribution amount and dynamic reward rate
        uint256 earnedPoints = calculateDynamicReward(projectId, amount);
        require(earnedPoints > 0, "Contribution did not yield points");

        // Mint EcoPoints to the contributor
        _mint(_msgSender(), earnedPoints);

        // Update state
        userContributions[_msgSender()][projectId] = userContributions[_msgSender()][projectId].add(amount);
        projects[projectId].totalContributed = projects[projectId].totalContributed.add(amount);

        emit ContributionMade(_msgSender(), projectId, amount, earnedPoints);

        // Optional: Trigger system health update here based on total contributions
        // updateSystemHealth(...); // Could be called by an oracle or admin periodically
    }

    // Nurture an EcoNFT by spending EcoPoints
    function nurtureNFT(uint256 tokenId, uint256 points) public whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not your token");
        require(points > 0, "Points must be greater than 0");
        require(balanceOf(_msgSender()) >= points, "Insufficient EcoPoints");

        // Burn the spent EcoPoints
        _burn(_msgSender(), points);

        // Increase nurtured health (simplified logic)
        // Maybe diminishing returns: sqrt(current_health + points) - sqrt(current_health)
        uint256 healthIncrease = points / 100; // Example: 100 points per health point
        _nftAttributes[tokenId].nurturedHealth = _nftAttributes[tokenId].nurturedHealth.add(healthIncrease);
        _nftAttributes[tokenId].lastNurturedTimestamp = uint64(block.timestamp);

        emit NFTNurtured(tokenId, _msgSender(), points, _nftAttributes[tokenId].nurturedHealth);
    }

    // Upgrade an EcoNFT's level
    function upgradeNFT(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "Not your token");

        NFTAttributes storage attrs = _nftAttributes[tokenId];
        uint256 currentLevel = attrs.level;
        uint256 requiredHealthForNextLevel = currentLevel.mul(1000); // Example: Level 2 needs 1000 health, Level 3 needs 2000, etc.
        uint256 pointsCost = currentLevel.mul(5000e18); // Example: Level 2 costs 5000 EP, Level 3 costs 10000 EP

        require(attrs.nurturedHealth >= requiredHealthForNextLevel, "Not enough nurtured health for next level");
        require(balanceOf(_msgSender()) >= pointsCost, "Insufficient EcoPoints for upgrade");

        // Burn the cost
        _burn(_msgSender(), pointsCost);

        // Perform upgrade
        attrs.level = currentLevel.add(1);
        // Optional: Reset nurtured health or modify base stats upon level up

        emit NFTUpgraded(tokenId, _msgSender(), attrs.level);
    }

    // --- Dynamic System Functions ---

    // Update the global system health score (Trusted Oracle/Admin controlled)
    // In a real scenario, this might be called by a Chainlink oracle or similar,
    // fetching data on real-world ecological metrics or project completion status.
    function updateSystemHealth(uint256 newHealthScore) public onlyRole(HEALTH_ORACLE_ROLE) {
        require(newHealthScore <= MAX_HEALTH_SCORE, "Health score exceeds max");
        systemHealthScore = newHealthScore;
        emit SystemHealthUpdated(newHealthScore);
    }

    // Calculate dynamic reward for a contribution (View function)
    // Reward is base rate adjusted by system health.
    // At 0 health, reward is base rate * (1 - healthImpactFactorReward/100) (potentially 0 or less)
    // At MAX_HEALTH_SCORE health, reward is base rate * (1 + healthImpactFactorReward/100) (potentially 2x base rate)
    function calculateDynamicReward(uint256 projectId, uint256 amount) public view returns (uint256) {
        require(projects[projectId].isActive, "Project is not active");
        uint256 baseRate = projects[projectId].baseRewardRate;

        // Simple linear scaling based on system health
        // healthFactor: 0 at 0 health, 10000 at MAX_HEALTH_SCORE
        uint256 healthFactor = systemHealthScore;

        // Adjustment factor: goes from (10000 - healthImpactFactorReward * 100) to (10000 + healthImpactFactorReward * 100)
        // as health goes from 0 to MAX_HEALTH_SCORE
        // Example: healthImpactFactorReward = 50. Factor goes from 5000 to 15000.
        // Scaled by 10000: goes from 0.5x to 1.5x
        uint256 scaledImpactFactor = healthImpactFactorReward.mul(MAX_HEALTH_SCORE).div(100); // Scale % to MAX_HEALTH_SCORE range

        uint256 healthAdjustedFactor;
        if (healthFactor < MAX_HEALTH_SCORE / 2) {
            // Below 50% health, apply penalty
            healthAdjustedFactor = MAX_HEALTH_SCORE.mul(healthFactor).div(MAX_HEALTH_SCORE / 2).mul(MAX_HEALTH_SCORE - scaledImpactFactor).div(MAX_HEALTH_SCORE);
            // At 0 health, this is 0. At MAX_HEALTH_SCORE/2, this is MAX_HEALTH_SCORE - scaledImpactFactor
        } else {
             // Above 50% health, apply bonus
            healthAdjustedFactor = MAX_HEALTH_SCORE - scaledImpactFactor + scaledImpactFactor.mul(healthFactor - MAX_HEALTH_SCORE / 2).div(MAX_HEALTH_SCORE / 2);
             // At MAX_HEALTH_SCORE/2, this is MAX_HEALTH_SCORE - scaledImpactFactor. At MAX_HEALTH_SCORE, this is MAX_HEALTH_SCORE.
        }
        // Simplified: Linear interpolation from (100 - impact)% to (100 + impact)% relative to base
        int256 impactMultiplier = int256(systemHealthScore) * int256(healthImpactFactorReward) / int256(MAX_HEALTH_SCORE / 100); // Scaled %
        int256 healthBonusPercentage = impactMultiplier - int256(healthImpactFactorReward); // goes from -impact to +impact

        uint256 rewardPercentage = 10000 + uint256(int256(10000) * healthBonusPercentage / 100); // 100% + health bonus/penalty %

        return baseRate.mul(amount).mul(rewardPercentage).div(10000); // Apply health adjustment
    }

    // Calculate a dynamic property of an NFT (View function)
    // Example: Effective Biodiversity Score = Base Score + Nurtured Health + Bonus/Penalty from System Health
    function calculateDynamicNFTProperty(uint256 tokenId, uint265 propertyType) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        NFTAttributes storage attrs = _nftAttributes[tokenId];

        if (propertyType == 1) { // Example: Calculate Effective Biodiversity Score
            uint256 base = attrs.baseBiodiversityScore;
            uint256 nurtured = attrs.nurturedHealth;

            // Health impact: at 0 health, maybe -healthImpactFactorNFT% of nurtured health is lost.
            // at MAX_HEALTH_SCORE, maybe +healthImpactFactorNFT% of nurtured health is added.
            int256 healthEffect = int224(systemHealthScore) * int224(healthImpactFactorNFT) / int224(MAX_HEALTH_SCORE / 100); // Scaled % impact
            int256 nurturedAdjustment = int256(nurtured) * (healthEffect - int256(healthImpactFactorNFT)) / 100; // goes from -impact to +impact

            int256 effectiveBiodiversity = int256(base) + int256(nurtured) + nurturedAdjustment;

            return uint256(int256(0) > effectiveBiodiversity ? 0 : effectiveBiodiversity); // Ensure non-negative
        }
        // Add more property types here...
        return 0; // Default for unknown propertyType
    }

    // --- Staking Functions ---

    // Stake EcoPoints
    function stakeEcoPoints(uint256 amount) public whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(_msgSender()) >= amount, "Insufficient EcoPoints");

        // Calculate pending rewards before updating stake
        _calculateStakingRewards(_msgSender());

        // Transfer (burn from user)
        _burn(_msgSender(), amount);

        // Update staked balance
        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].add(amount);
        _lastStakingRewardCalcTimestamp[_msgSender()] = uint256(block.timestamp); // Reset timestamp

        emit TokensStaked(_msgSender(), amount);
    }

    // Unstake EcoPoints
    function unstakeEcoPoints(uint256 amount) public whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(stakedBalances[_msgSender()] >= amount, "Insufficient staked balance");

        // Calculate pending rewards before updating stake
        _calculateStakingRewards(_msgSender());

        // Update staked balance
        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].sub(amount);
        _lastStakingRewardCalcTimestamp[_msgSender()] = uint256(block.timestamp); // Reset timestamp

        // Transfer (mint to user)
        _mint(_msgSender(), amount);

        emit TokensUnstaked(_msgSender(), amount);
    }

    // Claim accumulated staking rewards
    function claimStakingRewards() public whenNotPaused {
        // Calculate pending rewards
        _calculateStakingRewards(_msgSender());

        uint256 rewards = _stakingRewards[_msgSender()];
        require(rewards > 0, "No rewards to claim");

        // Reset rewards
        _stakingRewards[_msgSender()] = 0;
        _lastStakingRewardCalcTimestamp[_msgSender()] = uint256(block.timestamp); // Reset timestamp

        // Transfer (mint rewards to user)
        _mint(_msgSender(), rewards);

        emit StakingRewardsClaimed(_msgSender(), rewards);
    }

    // Internal function to calculate and add pending staking rewards
    function _calculateStakingRewards(address account) internal {
        uint256 staked = stakedBalances[account];
        if (staked == 0) {
            _lastStakingRewardCalcTimestamp[account] = uint256(block.timestamp);
            return;
        }

        uint256 lastCalc = _lastStakingRewardCalcTimestamp[account];
        uint256 timeElapsed = block.timestamp - lastCalc;

        if (timeElapsed > 0) {
            uint256 newRewards = staked.mul(stakingRewardRatePerPointPerSecond).mul(timeElapsed);
            _stakingRewards[account] = _stakingRewards[account].add(newRewards);
            _lastStakingRewardCalcTimestamp[account] = uint256(block.timestamp);
        }
    }

    // Query user's staked balance
    function getStakedBalance(address account) public view returns (uint256) {
        return stakedBalances[account];
    }

    // Query estimated pending staking rewards (calls internal calculation without saving)
    function getStakingRewardEstimate(address account) public view returns (uint256) {
         uint256 staked = stakedBalances[account];
        if (staked == 0) {
            return _stakingRewards[account];
        }

        uint256 lastCalc = _lastStakingRewardCalcTimestamp[account];
        uint265 timeElapsed = block.timestamp - lastCalc;

        uint256 estimatedNewRewards = staked.mul(stakingRewardRatePerPointPerSecond).mul(timeElapsed);
        return _stakingRewards[account].add(estimatedNewRewards);
    }

    // --- Governance Functions ---

    // Create a new governance proposal
    function createProposal(string memory description_, address targetContract, bytes memory callData_, uint256 stakeAmount_)
        public onlyRole(PROPOSER_ROLE) whenNotPaused
    {
        require(stakeAmount_ >= proposalStakeRequired, "Stake amount less than required");
        require(balanceOf(_msgSender()) >= stakeAmount_, "Insufficient EcoPoints to stake");
        require(targetContract == address(this), "Only proposals targeting this contract are allowed"); // Simplified: Proposals only call back to EcoSphere

        // Burn the staked points (or transfer to a governance module contract if separate)
        // For simplicity here, let's assume they are just 'locked' by being burned, and maybe some are minted back on success/failure
        // Or, better, require approval and transfer to *this* contract's balance. Let's do transfer.
        require(allowance(_msgSender(), address(this)) >= stakeAmount_, "Approve required stake for proposal");
        _transfer(_msgSender(), address(this), stakeAmount_);

        uint256 proposalId = _proposalIds.current();
        _proposalIds.increment();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: _msgSender(),
            description: description_,
            targetFunction: callData_, // The encoded function call data
            stakeAmount: stakeAmount_,
            voteStartTimestamp: uint64(block.timestamp),
            voteEndTimestamp: uint64(block.timestamp + votingPeriodSeconds),
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit ProposalCreated(proposalId, _msgSender(), uint64(block.timestamp + votingPeriodSeconds));
    }

    // Vote on an active proposal
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId && proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp >= proposal.voteStartTimestamp && block.timestamp <= proposal.voteEndTimestamp, "Voting period has ended or not started");
        require(!_hasVoted[proposalId][_msgSender()], "Already voted on this proposal");

        uint256 votingPower = getVotingPower(_msgSender());
        require(votingPower > 0, "No voting power");

        if (support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }

        _hasVoted[proposalId][_msgSender()] = true;

        emit Voted(proposalId, _msgSender(), support, votingPower);
    }

    // Execute a successful proposal
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId && proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal is not active"); // State must be active to transition
        require(block.timestamp > proposal.voteEndTimestamp, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 currentTotalSupply = totalSupply();

        // Check quorum: Total votes must be >= quorum percentage of total supply
        bool quorumReached = totalVotes.mul(10000) >= currentTotalSupply.mul(quorumPercentage);

        // Check threshold: Votes for must be > votes against and >= threshold percentage of total votes
        bool thresholdReached = proposal.votesFor > proposal.votesAgainst &&
                                proposal.votesFor.mul(10000) > totalVotes.mul(proposalThresholdPercentage);


        if (quorumReached && thresholdReached) {
            proposal.state = ProposalState.Succeeded;
            // Execute the function call
            (bool success, ) = address(this).call(proposal.targetFunction); // Self-call

            proposal.executed = true;
            emit ProposalExecuted(proposalId, success);

            // Optional: Return stake to proposer on success (or portion)
             // For simplicity, just keep the stake in the contract for now.
             // In a real DAO, stake mechanics are crucial.

            require(success, "Proposal execution failed"); // Revert if the proposal call failed
        } else {
            proposal.state = ProposalState.Defeated;
            emit ProposalExecuted(proposalId, false);

            // Optional: Return stake to proposer on failure (or burn)
        }
    }

    // Get the current state of a proposal
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) { // Check for existence
            return ProposalState.Pending; // Or a dedicated 'NonExistent' state
        }
        if (proposal.executed) {
            return ProposalState.Executed;
        }
         if (proposal.state == ProposalState.Canceled) {
            return ProposalState.Canceled;
        }
        if (block.timestamp <= proposal.voteEndTimestamp) {
            return ProposalState.Active;
        }
        // Voting period ended, check if it succeeded or failed
        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 currentTotalSupply = totalSupply(); // Use current supply for quorum check at execution time

        bool quorumReached = totalVotes.mul(10000) >= currentTotalSupply.mul(quorumPercentage);
        bool thresholdReached = proposal.votesFor > proposal.votesAgainst &&
                                proposal.votesFor.mul(10000) > totalVotes.mul(proposalThresholdPercentage);

        if (quorumReached && thresholdReached) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

     // Cancel a proposal before voting starts (proposer or admin)
    function cancelProposal(uint256 proposalId) public onlyRole(DEFAULT_ADMIN_ROLE, PROPOSER_ROLE) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId && proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp < proposal.voteStartTimestamp.add(1 minutes), "Cannot cancel after voting starts"); // Small grace period or block based start

        // Only proposer can cancel their own, unless admin
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            require(proposal.proposer == _msgSender(), "Not authorized to cancel this proposal");
        }

        proposal.state = ProposalState.Canceled;
         // Return stake to proposer
        _transfer(address(this), proposal.proposer, proposal.stakeAmount);

        emit ProposalCanceled(proposalId);
    }


    // Get user's voting power (Based on EcoPoint balance)
    function getVotingPower(address account) public view returns (uint256) {
        // Could potentially include staked balances, or even owned NFTs based on their level/attributes
        // For simplicity, let's just use the liquid balance for this example.
        return balanceOf(account);
    }

    // --- Admin & Access Control Functions ---

    // grantRole, revokeRole, renounceRole are provided by AccessControl inheritance
    // pause, unpause are provided by Pausable inheritance

    // Example admin withdrawal function (Simplified)
    function withdrawAdminFees(address tokenAddress, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        // In a real contract, manage specific fee/donation balances, not arbitrary withdrawal
        // This is a simplification for demonstration.
        require(amount > 0, "Amount must be greater than 0");

        if (tokenAddress == address(this)) { // Withdrawing EcoPoints held by the contract
             _transfer(address(this), _msgSender(), amount);
        } else { // Withdrawing other ERC20s held by the contract
            IERC20 externalToken = IERC20(tokenAddress);
            require(externalToken.transfer(_msgSender(), amount), "Token transfer failed");
        }
        emit AdminFeesWithdrawn(tokenAddress, amount, _msgSender());
    }

    // --- Query & Utility Functions ---

    // Get details for a specific project
    function getProjectDetails(uint256 projectId) public view returns (EcologicalProject memory) {
        require(projects[projectId].id != 0 || _projectIds.current() >= projectId, "Project does not exist"); // Basic existence check
        return projects[projectId];
    }

    // Get dynamic details for an EcoNFT
    function getNFTDetails(uint256 tokenId) public view returns (NFTAttributes memory, uint256 currentEffectiveBiodiversity) {
        require(_exists(tokenId), "Token does not exist");
        NFTAttributes storage attrs = _nftAttributes[tokenId];
        uint256 effectiveBiodiversity = calculateDynamicNFTProperty(tokenId, 1); // Calculate effective biodiversity
        return (attrs, effectiveBiodiversity);
    }

     // Get user's total contribution to a specific project
    function getUserContribution(address account, uint256 projectId) public view returns (uint256) {
        return userContributions[account][projectId];
    }

     // Get details for a specific proposal
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id == proposalId && proposal.proposer != address(0), "Proposal does not exist");
         return proposal;
    }

    // Get vote counts for a specific proposal
     function getProposalVoteCounts(uint256 proposalId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        Proposal storage proposal = proposals[proposalId];
         require(proposal.id == proposalId && proposal.proposer != address(0), "Proposal does not exist");
         return (proposal.votesFor, proposal.votesAgainst);
     }

    // --- Internal Helpers ---

    // Helper to convert uint256 to string (for tokenURI)
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Override ERC20 _update function to include staking reward calculation
    // This ensures rewards are calculated whenever a balance changes (mint, burn, transfer)
     function _update(address from, address to, uint256 value) internal override {
        if (from != address(0)) {
            _calculateStakingRewards(from);
        }
        if (to != address(0)) {
            _calculateStakingRewards(to);
        }
        super._update(from, to, value);
    }

    // Override ERC721 _update function (less critical for staking, but good practice)
     function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) {
        // No staking impact from NFT transfers in this model, so no need to recalculate rewards here.
        // Keep super call.
         super._update(to, tokenId, auth);
    }

    // Fallback/Receive function (optional, but good practice for handling Ether sent)
    receive() external payable {
        // Could potentially treat incoming Ether as a general donation or convert to EcoPoints
        // For this example, just revert or let it sit.
        revert("EcoSphere: Direct Ether payments not supported");
    }
}
```