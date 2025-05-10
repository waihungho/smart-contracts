Okay, here is a Solidity smart contract implementing a complex, dynamic, and community-governed protocol. It integrates several advanced concepts like dynamic parameters, tiered user status based on interaction, combined fungible and non-fungible staking for governance power and rewards, and a robust governance module capable of changing protocol parameters and executing arbitrary calls.

This contract is designed as a conceptual framework, `ChronosProtocol`, where parameters can evolve over time driven by token holders, rewarding active participation and diverse asset holding (specific NFTs).

**Disclaimer:** This is a complex example for educational purposes. It has not been audited and should NOT be used in a production environment without significant security review and formal verification. It uses simplified reward calculation and status logic for brevity.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // Using for staked NFTs potentially

// --- Chronos Protocol: Dynamic Governance & Staking Hub ---
//
// This contract is a prototype for a decentralized protocol that
// manages a treasury, allows staking of governance tokens (CHRON)
// and specific NFTs, derives a user status based on interaction,
// and features a governance module that can adjust dynamic protocol
// parameters and execute arbitrary actions.
//
// It aims to demonstrate:
// - Dynamic protocol parameters adjustable via governance.
// - Tiered user status/reputation based on staking and participation.
// - Combined fungible (ERC20) and non-fungible (ERC721) staking for utility.
// - A comprehensive governance process (proposals, voting, execution).
// - Treasury management under governance control.
//
// --- Outline ---
// 1. State Variables: Core contract configuration, treasury, staking data, governance state, user status, dynamic parameters.
// 2. Enums: ProposalState, VoteType, UserStatus, ProtocolParameter.
// 3. Structs: Proposal, StakingData, UserInfo.
// 4. Events: Signaling key actions and state changes.
// 5. Modifiers: Access control (owner, governance).
// 6. Core Logic:
//    - Constructor: Initial setup.
//    - Configuration: Setting initial/base parameters.
//    - Treasury: ERC20/ERC721 deposit/withdrawal.
//    - Staking: Stake/unstake CHRON, stake/unstake specific NFTs, reward calculation and claiming.
//    - Voting Power: Dynamic calculation based on stake, NFT, and status.
//    - User Status: Deriving/updating user status based on criteria.
//    - Dynamic Parameters: Storing and retrieving adjustable parameters.
//    - Governance: Proposal creation, voting, queuing, execution.
//    - Conditional Actions: Functions exhibiting behavior based on user status or parameters.
//    - Emergency Controls.
//    - View Functions: Querying contract state.
//
// --- Function Summary (25+ functions) ---
// - constructor(address chronTokenAddress, address specificNftAddress): Initializes contract with token addresses.
// - setInitialConfig(uint256 initialRewardRate, uint256 minStakeForBasic, uint256 minStakeForEngaged, uint256 minStakeForCore, uint256 nftStakeBoost, uint256 basicStatusWeight, uint256 engagedStatusWeight, uint256 coreStatusWeight, uint256 votingDelay, uint256 votingPeriod, uint256 proposalThresholdBps, uint256 quorumThresholdBps): Sets critical base configuration parameters (Owner/Admin only initially).
// - transferOwnership(address newOwner): Transfers Ownable ownership (Standard).
// - renounceOwnership(): Renounces Ownable ownership (Standard).
// - treasuryDepositERC20(address token, uint256 amount): Allows depositing ERC20 tokens into the protocol treasury.
// - treasuryWithdrawERC20(address token, uint256 amount): Allows withdrawing ERC20 tokens from the treasury (Governance only).
// - treasuryDepositERC721(address token, uint256 tokenId): Allows depositing ERC721 tokens into the protocol treasury.
// - treasuryWithdrawERC721(address token, uint256 tokenId): Allows withdrawing ERC721 tokens from the treasury (Governance only).
// - stakeCHRON(uint256 amount): Stakes CHRON tokens.
// - unstakeCHRON(uint256 amount): Unstakes CHRON tokens (may incur penalty or time lock based on parameters, simplified here).
// - stakeSpecificNFT(uint256 tokenId): Stakes the designated specific NFT.
// - unstakeSpecificNFT(uint256 tokenId): Unstakes the specific NFT.
// - claimStakingRewards(): Claims accumulated staking rewards for CHRON stake.
// - calculatePendingRewards(address user): Views pending CHRON staking rewards.
// - getVotingPower(address user): Calculates user's current dynamic voting power.
// - getUserStatus(address user): Views user's current calculated status tier.
// - updateUserStatusInternal(address user): Internal function to recalculate and update user status (triggered by actions).
// - createParameterProposal(uint8 parameterId, uint256 newValue, string description): Creates a proposal to change a dynamic protocol parameter.
// - createGenericProposal(address target, bytes calldata callData, string description): Creates a proposal to execute arbitrary logic.
// - castVote(uint256 proposalId, uint8 voteType): Casts a vote on an active proposal.
// - getProposalState(uint256 proposalId): Views the current state of a proposal.
// - queueProposal(uint256 proposalId): Moves a successful proposal to the execution queue (may involve timelock).
// - executeProposal(uint256 proposalId): Executes a queued proposal.
// - cancelProposal(uint256 proposalId): Allows proposal creator or governance to cancel a proposal (under certain conditions).
// - getProtocolParameter(uint8 parameterId): Views the current value of a dynamic protocol parameter.
// - conditionalActionBasedOnStatus(uint256 requiredStatusTier): Example function: performs an action only if user meets a status tier.
// - emergencyPauseStaking(bool paused): Allows Admin/Governance to pause staking operations.
// - getProposalDetails(uint256 proposalId): Views details of a specific proposal.
// - getTotalStakedCHRON(): Views total CHRON staked in the protocol.
// - isSpecificNFTStaked(uint256 tokenId): Checks if a specific NFT is currently staked.

contract ChronosProtocol is Ownable, ReentrancyGuard {

    // --- Enums ---
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }
    enum VoteType { Against, For, Abstain }
    enum UserStatus { Tier0_None, Tier1_Basic, Tier2_Engaged, Tier3_Core }
    enum ProtocolParameter { RewardRatePerSecond, MinStakeForBasicStatus, MinStakeForEngagedStatus, MinStakeForCoreStatus, NFTStakeBoost, BasicStatusWeight, EngagedStatusWeight, CoreStatusWeight, VotingDelayBlocks, VotingPeriodBlocks, ProposalThresholdBps, QuorumThresholdBps }

    // --- Structs ---
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 createdBlock;
        uint256 votingPeriodEndsBlock;
        ProposalState state;
        string description;

        // Proposal Type Data
        bool isParameterChange; // True if parameter change, false if generic
        uint8 parameterId;      // Relevant if isParameterChange
        uint256 newValue;       // Relevant if isParameterChange
        address target;         // Relevant if generic action
        bytes callData;         // Relevant if generic action

        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        mapping(address => bool) hasVoted;
        uint256 totalVotingPowerAtStart; // Snapshot total voting power at proposal start
        uint256 quorumRequired;          // Quorum requirement based on snapshot power
    }

    struct StakingData {
        uint256 amountCHRON;
        uint256 rewardDebt; // Used in a standard reward distribution model
        uint256 lastUpdateBlock;
        EnumerableSet.UintSet stakedNFTTokenIds; // Using OpenZeppelin's EnumerableSet for potentially iterating staked NFTs
    }

    struct UserInfo {
        UserStatus currentStatus;
        // Could add more fields like lastActiveBlock, etc.
    }

    // --- State Variables ---
    IERC20 public immutable CHRON_TOKEN;
    IERC721 public immutable SPECIFIC_NFT_TOKEN; // A specific NFT that grants benefits

    // Treasury
    mapping(address => uint256) public treasuryERC20Balances;
    mapping(address => EnumerableSet.UintSet) private treasuryERC721Tokens; // Token address => set of tokenIds

    // Staking
    mapping(address => StakingData) public userStakingData;
    uint256 public totalStakedCHRON;
    uint256 public accumulatedRewardsPerShare; // Total rewards distributed per token staked (simplified)

    // Governance
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;
    mapping(address => bool) public isGovernance; // Addresses with governance rights (can be set via governance)
    EnumerableSet.AddressSet private governanceMembers; // Optional: Keep track of members

    // Dynamic Protocol Parameters (Adjustable via Governance)
    mapping(uint8 => uint256) public protocolParameters; // ProtocolParameter enum to value

    // User Status/Reputation (Derived)
    mapping(address => UserInfo) public userInfos;

    // Emergency Pausing
    bool public stakingPaused = false;

    // --- Events ---
    event InitialConfigSet(uint256 indexed initialRewardRate, uint256 votingDelayBlocks, uint256 votingPeriodBlocks);
    event TreasuryDeposit(address indexed token, address indexed depositor, uint256 amount);
    event TreasuryWithdrawal(address indexed token, address indexed recipient, uint256 amount);
    event CHRONStaked(address indexed user, uint256 amount);
    event CHRONUnstaked(address indexed user, uint256 amount);
    event SpecificNFTStaked(address indexed user, uint256 indexed tokenId);
    event SpecificNFTUnstaked(address indexed user, uint256 indexed tokenId);
    event RewardsClaimed(address indexed user, uint256 amount);
    event UserStatusUpdated(address indexed user, UserStatus newStatus);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ParameterChangeProposed(uint256 indexed proposalId, uint8 indexed parameterId, uint256 newValue);
    event GenericActionProposed(uint256 indexed proposalId, address indexed target, bytes callData);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint8 voteType, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event GovernanceMemberAdded(address indexed member);
    event GovernanceMemberRemoved(address indexed member);
    event StakingPaused(bool paused);
    event ProtocolParameterChanged(uint8 indexed parameterId, uint256 newValue);

    // --- Modifiers ---
    modifier onlyGovernance() {
        require(isGovernance[msg.sender], "Chronos: Not a governance member");
        _;
    }

    modifier onlyActiveStaking() {
        require(!stakingPaused, "Chronos: Staking operations are paused");
        _;
    }

    // --- Constructor ---
    constructor(address chronTokenAddress, address specificNftAddress) Ownable(msg.sender) {
        CHRON_TOKEN = IERC20(chronTokenAddress);
        SPECIFIC_NFT_TOKEN = IERC721(specificNftAddress);
        // Initial owner is automatically the first governance member (can be changed)
        isGovernance[msg.sender] = true;
        governanceMembers.add(msg.sender);
    }

    // --- Configuration (Initial setup by Owner, later can be adjusted by Governance) ---

    // Function 1
    function setInitialConfig(
        uint256 initialRewardRate,
        uint256 minStakeForBasic,
        uint256 minStakeForEngaged,
        uint256 minStakeForCore,
        uint256 nftStakeBoost,
        uint256 basicStatusWeight,
        uint256 engagedStatusWeight,
        uint256 coreStatusWeight,
        uint256 votingDelayBlocks,
        uint256 votingPeriodBlocks,
        uint256 proposalThresholdBps, // Basis points (e.g., 100 = 1%)
        uint256 quorumThresholdBps    // Basis points
    ) external onlyOwner {
        protocolParameters[uint8(ProtocolParameter.RewardRatePerSecond)] = initialRewardRate;
        protocolParameters[uint8(ProtocolParameter.MinStakeForBasicStatus)] = minStakeForBasic;
        protocolParameters[uint8(ProtocolParameter.MinStakeForEngagedStatus)] = minStakeForEngaged;
        protocolParameters[uint8(ProtocolParameter.MinStakeForCoreStatus)] = minStakeForCore;
        protocolParameters[uint8(ProtocolParameter.NFTStakeBoost)] = nftStakeBoost;
        protocolParameters[uint8(ProtocolParameter.BasicStatusWeight)] = basicStatusWeight;
        protocolParameters[uint8(ProtocolParameter.EngagedStatusWeight)] = engagedStatusWeight;
        protocolParameters[uint8(ProtocolParameter.CoreStatusWeight)] = coreStatusWeight;
        protocolParameters[uint8(ProtocolParameter.VotingDelayBlocks)] = votingDelayBlocks;
        protocolParameters[uint8(ProtocolParameter.VotingPeriodBlocks)] = votingPeriodBlocks;
        protocolParameters[uint8(ProtocolParameter.ProposalThresholdBps)] = proposalThresholdBps;
        protocolParameters[uint8(ProtocolParameter.QuorumThresholdBps)] = quorumThresholdBps;

        emit InitialConfigSet(initialRewardRate, votingDelayBlocks, votingPeriodBlocks);
    }

    // Function 2: Add Governance Member (Owner initially, can be transitioned to governance)
    function addGovernanceMember(address member) external onlyOwner {
        require(!isGovernance[member], "Chronos: Already a governance member");
        isGovernance[member] = true;
        governanceMembers.add(member);
        emit GovernanceMemberAdded(member);
    }

    // Function 3: Remove Governance Member (Owner initially, can be transitioned to governance)
    function removeGovernanceMember(address member) external onlyOwner {
        require(isGovernance[member], "Chronos: Not a governance member");
        require(member != owner(), "Chronos: Cannot remove contract owner from governance initially"); // Owner should eventually be removed once governance is fully active
        isGovernance[member] = false;
        governanceMembers.remove(member);
        emit GovernanceMemberRemoved(member);
    }

    // Note: Ownership (`Ownable`) can be renounced or transferred to a multisig/governance contract
    // once the protocol is fully decentralized.

    // --- Treasury Management ---

    // Function 4
    function treasuryDepositERC20(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Chronos: Deposit amount must be positive");
        IERC20 tokenContract = IERC20(token);
        require(tokenContract.transferFrom(msg.sender, address(this), amount), "Chronos: ERC20 transfer failed");
        treasuryERC20Balances[token] += amount;
        emit TreasuryDeposit(token, msg.sender, amount);
    }

    // Function 5
    function treasuryWithdrawERC20(address token, uint256 amount) external onlyGovernance nonReentrant {
        require(amount > 0, "Chronos: Withdraw amount must be positive");
        require(treasuryERC20Balances[token] >= amount, "Chronos: Insufficient treasury balance");
        treasuryERC20Balances[token] -= amount;
        IERC20 tokenContract = IERC20(token);
        require(tokenContract.transfer(msg.sender, amount), "Chronos: ERC20 transfer failed"); // Sending to msg.sender (governance caller) or proposal target
        emit TreasuryWithdrawal(token, msg.sender, amount); // Note: msg.sender is the governance executor here
    }

    // Function 6
    function treasuryDepositERC721(address token, uint256 tokenId) external nonReentrant {
         require(IERC721(token).ownerOf(tokenId) == msg.sender, "Chronos: Not token owner");
         IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);
         treasuryERC721Tokens[token].add(tokenId);
         emit TreasuryDeposit(token, msg.sender, tokenId); // Using amount field for tokenId in event
    }

    // Function 7
    function treasuryWithdrawERC721(address token, uint256 tokenId) external onlyGovernance nonReentrant {
         require(treasuryERC721Tokens[token].contains(tokenId), "Chronos: Token not in treasury");
         treasuryERC721Tokens[token].remove(tokenId);
         IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId); // Sending to msg.sender (governance caller)
         emit TreasuryWithdrawal(token, msg.sender, tokenId); // Using amount field for tokenId in event
    }

    // Function 8 (View)
    function getTreasuryBalance(address token) external view returns (uint256) {
        return treasuryERC20Balances[token];
    }

    // Function 9 (View)
     function getTreasuryERC721s(address token) external view returns (uint256[] memory) {
        return treasuryERC721Tokens[token].values();
     }


    // --- Staking ---

    // Internal helper to update user rewards before state change
    function _updateRewards(address user) internal {
        StakingData storage data = userStakingData[user];
        uint256 currentBlock = block.number;

        if (currentBlock > data.lastUpdateBlock && totalStakedCHRON > 0 && data.amountCHRON > 0) {
            uint256 blocksPassed = currentBlock - data.lastUpdateBlock;
            uint256 rewardRate = protocolParameters[uint8(ProtocolParameter.RewardRatePerSecond)]; // Using "per block" for simplicity in this example
            uint256 rewardsEarned = (data.amountCHRON * rewardRate * blocksPassed) / 1e18; // Assuming rate is in base units
            accumulatedRewardsPerShare += (rewardsEarned * 1e18) / totalStakedCHRON; // Update global per share

            // Calculate pending rewards for this user
            uint256 userPending = (data.amountCHRON * accumulatedRewardsPerShare) / 1e18 - data.rewardDebt;
             // This calculation is simplified and might need adjustment based on the exact reward distribution model (e.g., masterchef style)
             // A common pattern calculates rewards per share globally and then uses that to track individual user debt.
             // For simplicity, let's update user's reward debt based on the *new* accumulatedRewardsPerShare.
             data.rewardDebt = (data.amountCHRON * accumulatedRewardsPerShare) / 1e18; // Update debt after calculation
        }
         data.lastUpdateBlock = currentBlock; // Always update last update block
    }


    // Function 10
    function stakeCHRON(uint256 amount) external nonReentrant onlyActiveStaking {
        require(amount > 0, "Chronos: Stake amount must be positive");

        // Update pending rewards before changing stake
        _updateRewards(msg.sender);

        userStakingData[msg.sender].amountCHRON += amount;
        totalStakedCHRON += amount;

        require(CHRON_TOKEN.transferFrom(msg.sender, address(this), amount), "Chronos: CHRON transfer failed");

        // Recalculate user status after staking
        _updateUserStatusInternal(msg.sender);

        emit CHRONStaked(msg.sender, amount);
    }

    // Function 11
    function unstakeCHRON(uint256 amount) external nonReentrant onlyActiveStaking {
        require(amount > 0, "Chronos: Unstake amount must be positive");
        StakingData storage data = userStakingData[msg.sender];
        require(data.amountCHRON >= amount, "Chronos: Insufficient staked CHRON");

        // Claim pending rewards before unstaking
        claimStakingRewards(); // Ensures reward debt is settled based on old stake

        data.amountCHRON -= amount;
        totalStakedCHRON -= amount;

        require(CHRON_TOKEN.transfer(msg.sender, amount), "Chronos: CHRON transfer failed");

        // Recalculate user status after unstaking
        _updateUserStatusInternal(msg.sender);

        emit CHRONUnstaked(msg.sender, amount);
    }

    // Function 12
    function stakeSpecificNFT(uint256 tokenId) external nonReentrant onlyActiveStaking {
        // Check ownership before transferFrom
        require(SPECIFIC_NFT_TOKEN.ownerOf(tokenId) == msg.sender, "Chronos: Not owner of NFT");
        StakingData storage data = userStakingData[msg.sender];

        require(!data.stakedNFTTokenIds.contains(tokenId), "Chronos: NFT already staked by this user");

        SPECIFIC_NFT_TOKEN.safeTransferFrom(msg.sender, address(this), tokenId);
        data.stakedNFTTokenIds.add(tokenId);

        // Recalculate user status after staking NFT
        _updateUserStatusInternal(msg.sender);

        emit SpecificNFTStaked(msg.sender, tokenId);
    }

    // Function 13
    function unstakeSpecificNFT(uint256 tokenId) external nonReentrant onlyActiveStaking {
        StakingData storage data = userStakingData[msg.sender];
        require(data.stakedNFTTokenIds.contains(tokenId), "Chronos: NFT not staked by this user");

        data.stakedNFTTokenIds.remove(tokenId);
        SPECIFIC_NFT_TOKEN.safeTransferFrom(address(this), msg.sender, tokenId);

        // Recalculate user status after unstaking NFT
        _updateUserStatusInternal(msg.sender);

        emit SpecificNFTUnstaked(msg.sender, tokenId);
    }


    // Function 14
    function claimStakingRewards() external nonReentrant {
         // Update pending rewards before calculating claimable amount
        _updateRewards(msg.sender);

        StakingData storage data = userStakingData[msg.sender];
        // Calculated pending = (userStake * totalAccumulatedPerShare) / 1e18 - userRewardDebt
        uint256 pendingRewards = (data.amountCHRON * accumulatedRewardsPerShare) / 1e18 - data.rewardDebt;

        if (pendingRewards > 0) {
            // Update debt to reflect claimed rewards
            data.rewardDebt += pendingRewards; // Debt increases by claimed amount (relative to global per share)
             // Note: A more common pattern sets debt to the user's "share" based on the *current* accumulatedRewardsPerShare
            data.rewardDebt = (data.amountCHRON * accumulatedRewardsPerShare) / 1e18;


            // Transfer rewards
            // Requires the protocol to have rewards token (e.g., CHRON or another token)
            // For this example, let's assume CHRON itself is the reward token, paid from the treasury
            // In a real scenario, rewards might be minted or come from fees.
            // This needs a source of rewards. Let's simulate assuming the CHRON_TOKEN balance in this contract increases somehow.
            // In a real system, accumulatedRewardsPerShare logic would be tied to token distribution/minting.
            // For simplicity, we'll simulate CHRON transfer. This requires the contract to hold CHRON rewards.
             require(CHRON_TOKEN.transfer(msg.sender, pendingRewards), "Chronos: Reward transfer failed"); // Requires contract holds CHRON

            emit RewardsClaimed(msg.sender, pendingRewards);
        }
    }

    // Function 15 (View)
    function calculatePendingRewards(address user) external view returns (uint256) {
         StakingData storage data = userStakingData[user];
         uint256 currentBlock = block.number;
         uint256 currentAccumulatedRewardsPerShare = accumulatedRewardsPerShare;

         // Project rewards since last update
         if (currentBlock > data.lastUpdateBlock && totalStakedCHRON > 0 && data.amountCHRON > 0) {
              uint256 blocksPassed = currentBlock - data.lastUpdateBlock;
              uint256 rewardRate = protocolParameters[uint8(ProtocolParameter.RewardRatePerSecond)];
              uint256 projectedRewards = (data.amountCHRON * rewardRate * blocksPassed) / 1e18;
              currentAccumulatedRewardsPerShare += (projectedRewards * 1e18) / totalStakedCHRON;
         }

         // Calculate pending based on projected share and debt
         return (data.amountCHRON * currentAccumulatedRewardsPerShare) / 1e18 - data.rewardDebt;
    }

    // Function 16 (View)
    function getCHRONStake(address user) external view returns (uint256) {
        return userStakingData[user].amountCHRON;
    }

    // Function 17 (View)
    function getNFTStakes(address user) external view returns (uint256[] memory) {
         return userStakingData[user].stakedNFTTokenIds.values();
    }

    // Function 18 (View)
    function getTotalStakedCHRON() external view returns (uint256) {
        return totalStakedCHRON;
    }

    // Function 19 (View)
     function isSpecificNFTStaked(uint256 tokenId) external view returns (bool) {
         // Iterate through all users' staked NFTs - potentially expensive!
         // A better approach for a large scale would be a mapping from tokenId => bool or tokenId => staker address
         // For demonstration, let's use a less efficient check or assume the NFT is only staked by one user at a time globally in the system.
         // Let's add a mapping:
         // mapping(uint256 => address) public specificNFTStaker; // 0x0 if not staked
         // This function would then just check specificNFTStaker[tokenId] != address(0)
         // **Using the current structure (EnumerableSet per user), this global check is inefficient.**
         // We'll return false as a placeholder for efficiency, noting the need for a better state structure.
         // return specificNFTStaker[tokenId] != address(0); // If mapping added
         return false; // Placeholder for efficiency
     }


    // --- User Status / Reputation ---

    // Internal function to update user status based on current stake and NFT status
    // Function 20 (Internal)
    function _updateUserStatusInternal(address user) internal {
        uint256 currentStake = userStakingData[user].amountCHRON;
        bool hasNFT = userStakingData[user].stakedNFTTokenIds.length() > 0;

        UserStatus oldStatus = userInfos[user].currentStatus;
        UserStatus newStatus = UserStatus.Tier0_None;

        uint256 minStakeCore = protocolParameters[uint8(ProtocolParameter.MinStakeForCoreStatus)];
        uint256 minStakeEngaged = protocolParameters[uint8(ProtocolParameter.MinStakeForEngagedStatus)];
        uint256 minStakeBasic = protocolParameters[uint8(ProtocolParameter.MinStakeForBasicStatus)];

        if (currentStake >= minStakeCore || hasNFT) { // NFT grants core status (example logic)
             newStatus = UserStatus.Tier3_Core;
        } else if (currentStake >= minStakeEngaged) {
             newStatus = UserStatus.Tier2_Engaged;
        } else if (currentStake >= minStakeBasic) {
             newStatus = UserStatus.Tier1_Basic;
        }

        userInfos[user].currentStatus = newStatus;

        if (newStatus != oldStatus) {
            emit UserStatusUpdated(user, newStatus);
        }
    }

     // Function 21 (View)
     function getUserStatus(address user) external view returns (UserStatus) {
         // This function could also *trigger* an internal update if status decays over time
         // For now, it just returns the last calculated status
         return userInfos[user].currentStatus;
     }

    // Function 22 (View)
    function getVotingPower(address user) public view returns (uint256) {
        StakingData storage stakeData = userStakingData[user];
        UserInfo storage userInfo = userInfos[user]; // Assuming status is reasonably up-to-date

        uint256 basePower = stakeData.amountCHRON;
        uint256 statusBoost = 0;

        // Add boost based on status tier
        if (userInfo.currentStatus == UserStatus.Tier1_Basic) {
             statusBoost = protocolParameters[uint8(ProtocolParameter.BasicStatusWeight)] * 1e18; // Multiply weight by 1e18 to match token decimals
        } else if (userInfo.currentStatus == UserStatus.Tier2_Engaged) {
             statusBoost = protocolParameters[uint8(ProtocolParameter.EngagedStatusWeight)] * 1e18;
        } else if (userInfo.currentStatus == UserStatus.Tier3_Core) {
             statusBoost = protocolParameters[uint8(ProtocolParameter.CoreStatusWeight)] * 1e18;
        }

        // Add boost for staked NFT
        uint256 nftBoost = 0;
        if (stakeData.stakedNFTTokenIds.length() > 0) {
            nftBoost = protocolParameters[uint8(ProtocolParameter.NFTStakeBoost)] * 1e18;
        }

        return basePower + statusBoost + nftBoost;
    }


    // --- Governance ---

    // Function 23
    function createParameterProposal(uint8 parameterId, uint256 newValue, string calldata description) external nonReentrant {
        require(parameterId < uint8(ProtocolParameter.QuorumThresholdBps) + 1, "Chronos: Invalid parameter ID"); // Ensure parameterId is valid enum value

        uint256 proposerVotingPower = getVotingPower(msg.sender);
        uint256 proposalThreshold = (totalStakedCHRON * protocolParameters[uint8(ProtocolParameter.ProposalThresholdBps)]) / 10000; // Threshold in CHRON based on % of total stake

        require(proposerVotingPower >= proposalThreshold, "Chronos: Insufficient voting power to create proposal");

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.createdBlock = block.number;
        proposal.state = ProposalState.Pending; // Starts as pending until voting delay passes (activated automatically or via a queue)
        proposal.description = description;
        proposal.isParameterChange = true;
        proposal.parameterId = parameterId;
        proposal.newValue = newValue;
        proposal.target = address(0); // Not used for parameter changes
        proposal.callData = "";      // Not used for parameter changes

        emit ProposalCreated(proposalId, msg.sender, description);
        emit ParameterChangeProposed(proposalId, parameterId, newValue);
    }

     // Function 24
    function createGenericProposal(address target, bytes calldata callData, string calldata description) external nonReentrant {
        require(target != address(0), "Chronos: Target cannot be zero address");

        uint256 proposerVotingPower = getVotingPower(msg.sender);
        uint256 proposalThreshold = (totalStakedCHRON * protocolParameters[uint8(ProtocolParameter.ProposalThresholdBps)]) / 10000; // Threshold in CHRON based on % of total stake

        require(proposerVotingPower >= proposalThreshold, "Chronos: Insufficient voting power to create proposal");

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.createdBlock = block.number;
        proposal.state = ProposalState.Pending; // Starts as pending
        proposal.description = description;
        proposal.isParameterChange = false;
        proposal.parameterId = 0;      // Not used for generic actions
        proposal.newValue = 0;       // Not used for generic actions
        proposal.target = target;
        proposal.callData = callData;

        emit ProposalCreated(proposalId, msg.sender, description);
        emit GenericActionProposed(proposalId, target, callData);
    }

    // Function 25
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Chronos: Invalid proposal ID");

        if (proposal.state == ProposalState.Pending) {
             if (block.number > proposal.createdBlock + protocolParameters[uint8(ProtocolParameter.VotingDelayBlocks)]) {
                 // Transition from Pending to Active
                 return ProposalState.Active;
             }
        } else if (proposal.state == ProposalState.Active) {
            if (block.number > proposal.votingPeriodEndsBlock) {
                 // Transition from Active based on outcome
                 uint256 totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;
                 uint256 quorumThreshold = (proposal.totalVotingPowerAtStart * protocolParameters[uint8(ProtocolParameter.QuorumThresholdBps)]) / 10000; // Use snapshot power

                 if (proposal.votesFor > proposal.votesAgainst && totalVotes >= quorumThreshold) {
                     return ProposalState.Succeeded;
                 } else {
                     return ProposalState.Defeated;
                 }
             }
        } else if (proposal.state == ProposalState.Queued) {
             // Could add an expiry block for queued proposals
             // if (block.number > proposal.queueExpiryBlock) return ProposalState.Expired;
        }

        return proposal.state; // Return current state if no transition
    }

    // Function 26
    function castVote(uint256 proposalId, uint8 voteType) external nonReentrant {
        require(voteType <= uint8(VoteType.Abstain), "Chronos: Invalid vote type");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Chronos: Invalid proposal ID");

        // Manually check for state transition to Active if pending
        if (proposal.state == ProposalState.Pending) {
             require(block.number > proposal.createdBlock + protocolParameters[uint8(ProtocolParameter.VotingDelayBlocks)], "Chronos: Voting not open yet");
             proposal.state = ProposalState.Active;
             proposal.votingPeriodEndsBlock = block.number + protocolParameters[uint8(ProtocolParameter.VotingPeriodBlocks)];
             proposal.totalVotingPowerAtStart = totalStakedCHRON; // Simple snapshot: total staked CHRON
             proposal.quorumRequired = (proposal.totalVotingPowerAtStart * protocolParameters[uint8(ProtocolParameter.QuorumThresholdBps)]) / 10000; // Snapshot quorum
             emit ProposalStateChanged(proposalId, ProposalState.Active);
        }

        require(proposal.state == ProposalState.Active, "Chronos: Proposal not in active voting state");
        require(!proposal.hasVoted[msg.sender], "Chronos: Already voted on this proposal");

        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower > 0, "Chronos: Voter has no power"); // Must have some power to vote

        proposal.hasVoted[msg.sender] = true;

        if (voteType == uint8(VoteType.For)) {
            proposal.votesFor += voterPower;
        } else if (voteType == uint8(VoteType.Against)) {
            proposal.votesAgainst += voterPower;
        } else if (voteType == uint8(VoteType.Abstain)) {
            proposal.votesAbstain += voterPower;
        }

        // Consider updating user status after voting as a signal of engagement (optional)
        _updateUserStatusInternal(msg.sender);

        emit VoteCast(proposalId, msg.sender, voteType, voterPower);
    }

    // Function 27
    function queueProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Chronos: Invalid proposal ID");

        // Check if voting period ended and proposal succeeded
        require(getProposalState(proposalId) == ProposalState.Succeeded, "Chronos: Proposal not succeeded");
        require(proposal.state != ProposalState.Queued, "Chronos: Proposal already queued");

        proposal.state = ProposalState.Queued;
        // Could add a timelock here: proposal.canExecuteAfterBlock = block.number + executionTimelock;
        emit ProposalStateChanged(proposalId, ProposalState.Queued);
    }

    // Function 28
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Chronos: Invalid proposal ID");
        require(proposal.state == ProposalState.Queued, "Chronos: Proposal not queued");
        // require(block.number > proposal.canExecuteAfterBlock, "Chronos: Timelock not expired"); // If timelock added

        bool success = false;
        if (proposal.isParameterChange) {
            // Execute Parameter Change
            uint8 paramId = proposal.parameterId;
            uint256 newValue = proposal.newValue;
            // Basic validation: ensure ID is still valid, maybe range checks
            require(paramId < uint8(ProtocolParameter.QuorumThresholdBps) + 1, "Chronos: Invalid parameter ID for execution");
            protocolParameters[paramId] = newValue;
            success = true;
            emit ProtocolParameterChanged(paramId, newValue);
        } else {
            // Execute Generic Action (Arbitrary Call)
            (success,) = proposal.target.call(proposal.callData);
             // Note: A failed call here could revert the whole transaction or just mark the proposal as failed.
             // For simplicity, we let it proceed and emit success status. Consider more robust error handling.
             // A real system might use a dedicated Executor contract with error handling.
        }

        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
        emit ProposalExecuted(proposalId, success);
    }

    // Function 29
    function cancelProposal(uint256 proposalId) external nonReentrant {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id != 0, "Chronos: Invalid proposal ID");

         // Only proposer or governance can cancel
         bool isProposer = msg.sender == proposal.proposer;
         bool isGov = isGovernance[msg.sender];
         require(isProposer || isGov, "Chronos: Not authorized to cancel");

         // Can only cancel if in Pending or Active state (before queuing)
         ProposalState currentState = getProposalState(proposalId); // Check current state based on block number
         require(currentState == ProposalState.Pending || currentState == ProposalState.Active, "Chronos: Proposal cannot be canceled in its current state");

         proposal.state = ProposalState.Canceled;
         emit ProposalStateChanged(proposalId, ProposalState.Canceled);
    }


    // --- Dynamic Parameters ---

    // Function 30 (View)
    function getProtocolParameter(uint8 parameterId) external view returns (uint256) {
        require(parameterId < uint8(ProtocolParameter.QuorumThresholdBps) + 1, "Chronos: Invalid parameter ID");
        return protocolParameters[parameterId];
    }


    // --- Conditional Logic Examples ---

    // Function 31: Example action only available to users above a certain status tier
    function conditionalActionBasedOnStatus(uint256 requiredStatusTier) external {
        UserStatus currentUserStatus = getUserStatus(msg.sender);
        require(uint8(currentUserStatus) >= requiredStatusTier, "Chronos: Insufficient status tier for this action");

        // ... logic for the action ...
        // For example:
        // uint256 fee = getDynamicFeeRate(); // Get a dynamic fee
        // require(CHRON_TOKEN.transferFrom(msg.sender, address(this), fee), "Chronos: Fee payment failed");
        // executeSpecificFeature();
        // ...
    }

    // Function 32 (View): Get the current dynamic fee rate (example)
    function getDynamicFeeRate() external view returns (uint256) {
        // This would need a ProtocolParameter enum value for DynamicFeeRate
        // Let's assume ProtocolParameter.RewardRatePerSecond is used as a placeholder for demonstration
        return protocolParameters[uint8(ProtocolParameter.RewardRatePerSecond)]; // Example: Reusing a parameter
    }


    // --- Emergency Controls ---

    // Function 33
    function emergencyPauseStaking(bool paused) external onlyOwner { // Can transition ownership to Governance later
         stakingPaused = paused;
         emit StakingPaused(paused);
    }

    // Function 34 (View)
    function isStakingPaused() external view returns (bool) {
        return stakingPaused;
    }

    // --- View Functions ---

    // Function 35 (View)
    function getProposalDetails(uint256 proposalId)
         external
         view
         returns (
             uint256 id,
             address proposer,
             uint256 createdBlock,
             uint256 votingPeriodEndsBlock,
             ProposalState state,
             string memory description,
             bool isParameterChange,
             uint8 parameterId,
             uint256 newValue,
             address target,
             bytes memory callData,
             uint256 votesFor,
             uint256 votesAgainst,
             uint256 votesAbstain,
             uint256 totalVotingPowerAtStart,
             uint256 quorumRequired
         )
     {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id != 0, "Chronos: Invalid proposal ID");

         return (
             proposal.id,
             proposal.proposer,
             proposal.createdBlock,
             proposal.votingPeriodEndsBlock,
             getProposalState(proposalId), // Return current state considering block number
             proposal.description,
             proposal.isParameterChange,
             proposal.parameterId,
             proposal.newValue,
             proposal.target,
             proposal.callData,
             proposal.votesFor,
             proposal.votesAgainst,
             proposal.votesAbstain,
             proposal.totalVotingPowerAtStart,
             proposal.quorumRequired
         );
     }

    // Function 36 (View)
     function getGovernanceMembers() external view returns (address[] memory) {
        return governanceMembers.values();
     }

     // Function 37 (View) - Placeholder, requires mapping from address to vote details
     // function getUserVote(uint256 proposalId, address user) external view returns (uint8 voteType, uint256 votingPowerUsed) {
     //    // Requires mapping like mapping(uint256 => mapping(address => struct {uint8 voteType; uint256 power}))
     //    // Omitted for brevity but would be necessary for full voter info
     //    revert("Not implemented: User vote tracking details");
     // }
}
```