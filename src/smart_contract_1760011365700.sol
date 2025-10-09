This Solidity smart contract, `RealityForgeDAO`, introduces an advanced decentralized autonomous organization focused on governing and evolving "Reality Shards" – dynamic NFTs (dNFTs) that represent programmable elements within a hypothetical decentralized metaverse, game, or simulation.

It incorporates several advanced, creative, and trendy concepts:

*   **Dynamic NFTs (dNFTs) via AI Oracle:** Reality Shards possess `dynamicAttributes` that can be evolved and updated by a trusted AI Oracle. The DAO governs *when* and *how* these evolutions are triggered and their results recorded.
*   **Reputation-Weighted Governance:** Voting power is not solely based on staked tokens but also incorporates a user's reputation score from an external Soulbound Token (SBT) contract, allowing for more nuanced and meritocratic decision-making.
*   **Liquid Democracy:** Token holders can delegate their voting power to trusted delegates, enabling more efficient and representative governance.
*   **Arbitrary Call Execution:** The DAO can approve and execute arbitrary calls on any contract, allowing for self-modification, upgrades, and complex interactions with other decentralized protocols.
*   **Epoch-Based Operations:** Governance and staking rewards operate on a defined epoch system, providing predictable timing for proposals and reward distribution.
*   **Staking for Participation & Rewards:** Users stake governance tokens to gain voting power and earn a share of rewards from a community pool.

---

## RealityForgeDAO: Outline & Function Summary

This contract, `RealityForgeDAO`, is an advanced decentralized autonomous organization designed to govern and manage "Reality Shards" – dynamic NFTs (dNFTs) representing game mechanics, virtual assets, or rule sets within a decentralized metaverse. It integrates AI oracle interaction for dynamic NFT evolution and proposal insights, a reputation system for nuanced governance, liquid democracy for voting, and staking for active participation and rewards.

**I. Core Infrastructure & Access Control (7 functions)**

1.  `constructor`: Initializes the DAO with an initial admin, AI oracle address, reputation token address, governance token address, and epoch duration. Sets default governance parameters.
2.  `changeAdmin`: Transfers the primary admin role of the contract (inherited from OpenZeppelin's `Ownable`).
3.  `pauseContract`: Activates emergency pause, preventing critical functions from being called (inherited from OpenZeppelin's `Pausable`).
4.  `unpauseContract`: Deactivates emergency pause, re-enabling paused functions (inherited from OpenZeppelin's `Pausable`).
5.  `setAIOracleAddress`: Updates the trusted AI Oracle contract address. This action typically requires a governance proposal to pass.
6.  `setReputationTokenAddress`: Updates the trusted Reputation Token (SBT) contract address. This action typically requires a governance proposal to pass.
7.  `setEpochDuration`: Updates the length of a governance epoch in seconds. This action typically requires a governance proposal to pass.

**II. Reality Shards (dNFTs) Management (6 functions)**

8.  `proposeRealityShard`: Allows users to propose a new dynamic NFT (Shard) with initial properties. Proposed shards require DAO approval to become active/mintable.
9.  `mintRealityShard`: Mints an approved Reality Shard to a specified recipient. This function is typically called as part of a passed governance proposal's execution.
10. `updateShardMetadataURI`: Allows the creator or current owner of an active Shard to update its metadata URI, pointing to its latest descriptive data.
11. `triggerShardEvolution`: Requests the AI Oracle to process and potentially evolve a specific Shard's dynamic attributes based on a provided prompt hash.
12. `recordShardEvolutionResult`: A callback function, callable *only* by the trusted AI Oracle, to update a Shard's dynamic attributes after an evolution process.
13. `getShardDetails`: Retrieves all comprehensive details of a specific Reality Shard.

**III. DAO Governance & Decision Making (8 functions)**

14. `submitProposal`: Initiates a new governance proposal. Proposers must stake a minimum amount of tokens. Proposal types include changing DAO parameters, setting oracle/token addresses, approving new shards, or executing arbitrary calls.
15. `delegateVote`: Allows a governance token holder to delegate their voting power (staked tokens + reputation) to another address, enabling liquid democracy.
16. `undelegateVote`: Revokes any existing voting delegation, returning voting power directly to the delegator.
17. `castVote`: Allows a user (or their delegatee) to cast a 'yes' or 'no' vote on an active proposal. Voting power is dynamically calculated based on staked tokens and reputation.
18. `executeProposal`: Executes a proposal that has successfully passed its voting phase, applying the proposed changes or actions.
19. `getProposalState`: Returns the current state of a proposal (e.g., Pending, Active, Succeeded, Defeated, Executed, Expired), considering quorum and pass thresholds.
20. `getVoterVotingPower`: Returns the combined voting power (from staked tokens and reputation) of a specific address at the current moment.
21. `getDelegatee`: Returns the address to whom a given voter has delegated their voting power. Returns `address(0)` if no delegation exists.

**IV. Staking & Rewards (6 functions)**

22. `stakeForGovernance`: Allows users to stake their governance tokens into the DAO. Staked tokens contribute to voting power and accrue staking rewards.
23. `unstakeFromGovernance`: Allows users to unstake their governance tokens, reducing their voting power and stopping future reward accumulation for the unstaked amount.
24. `claimStakingRewards`: Allows stakers to claim their accumulated governance token rewards earned from participating in the DAO.
25. `distributeStakingRewards`: Callable by the admin (or a privileged role) to add more governance tokens to the reward pool for distribution to stakers.
26. `setStakingRewardRate`: Updates the rate at which staking rewards are accumulated. This typically requires a governance proposal to pass.
27. `getTotalStaked`: Returns the total amount of governance tokens currently staked across all users in the DAO.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces for External Contracts ---

/// @title IAIOracle
/// @notice Interface for a trusted AI Oracle contract that can process and return results for Shard evolution or proposal insights.
interface IAIOracle {
    /// @notice Requests the AI Oracle to process and evolve a specific Reality Shard.
    /// @param _shardId The ID of the Reality Shard to evolve.
    /// @param _evolutionPromptHash A hash representing the context or prompt for the AI's evolution process.
    function requestShardEvolution(uint256 _shardId, bytes32 _evolutionPromptHash) external;

    /// @notice Requests the AI Oracle to provide insight or analysis on a specific governance proposal.
    /// @param _proposalId The ID of the proposal to analyze.
    /// @param _proposalHash A hash representing the proposal's content for AI analysis.
    function requestProposalInsight(uint256 _proposalId, bytes32 _proposalHash) external;
}

/// @title IReputationToken
/// @notice Interface for a Soulbound Token (SBT) or similar contract that tracks user reputation.
interface IReputationToken {
    /// @notice Returns the reputation score of a given account.
    /// @param account The address of the account.
    /// @return The reputation score as a uint256.
    function getReputation(address account) external view returns (uint256);
}

// --- Main Contract ---

/// @title RealityForgeDAO
/// @author YourName (or AI)
/// @notice A decentralized autonomous organization for governing and evolving dynamic NFTs (Reality Shards)
///         with AI oracle integration, reputation-weighted voting, and liquid democracy.
contract RealityForgeDAO is Ownable, Pausable {
    using Strings for uint256;

    // --- Events ---
    event ShardProposed(uint256 indexed shardId, address indexed creator, string name);
    event ShardMinted(uint256 indexed shardId, address indexed owner);
    event ShardEvolutionTriggered(uint256 indexed shardId, bytes32 evolutionPromptHash);
    event ShardEvolutionResult(uint256 indexed shardId, bytes32[] newDynamicAttributes);
    event ShardMetadataURIUpdated(uint256 indexed shardId, string newURI);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event DelegateVote(address indexed delegator, address indexed delegatee);
    event UndelegateVote(address indexed delegator);

    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 amount);
    event StakingRewardRateUpdated(uint256 newRate);

    // --- State Variables ---

    // Governance Parameters
    uint256 public nextProposalId;
    uint256 public nextShardId;
    uint256 public epochDuration; // Duration of one epoch in seconds
    uint256 public proposalQuorumThreshold; // Percentage of total voting power required for a proposal to pass (e.g., 4000 = 40%)
    uint256 public proposalPassThreshold; // Percentage of 'yes' votes required among total votes cast (e.g., 5000 = 50%)
    uint256 public proposalMinStakedTokens; // Minimum governance tokens staked to submit a proposal

    // External Contract Addresses
    IAIOracle public aiOracle;
    IReputationToken public reputationToken;
    IERC20 public governanceToken; // ERC20 token used for staking and voting power

    // Reality Shard Definitions (dNFTs)
    struct RealityShard {
        uint256 id;
        string name;
        string description;
        address creator;
        string currentURI;
        uint256 createdEpoch;
        uint256 lastEvolutionEpoch;
        bytes32[] dynamicAttributes; // Core dynamic properties managed by AI/governance
        bool active; // Can be deactivated by governance, or indicates mintable state
        address owner; // The current owner of the Shard NFT (simplified, could be ERC721)
    }
    mapping(uint256 => RealityShard) public realityShards;

    // DAO Proposal Definitions
    enum ProposalType {
        Generic,              // Simple text proposal, no on-chain execution
        ChangeDAOParameter,   // Change an internal DAO parameter (e.g., quorum, thresholds, epoch duration)
        SetAIOracle,          // Set new AI oracle address
        SetReputationToken,   // Set new Reputation Token address
        ApproveNewRealityShard, // Approve a proposed shard to be mintable
        ExecuteArbitraryCall  // Execute arbitrary call data on a target contract (powerful, requires high trust)
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Executed,
        Expired
    }

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 startEpoch;
        uint256 endEpoch;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        string description;
        ProposalType proposalType;
        bytes callData;       // For ExecuteArbitraryCall
        address callTarget;   // For ExecuteArbitraryCall, SetAIOracle, SetReputationToken
        bytes32 targetParamHash; // For ChangeDAOParameter, a hash identifier for the parameter to change
        uint256 newParamValue; // For ChangeDAOParameter, the new value
        uint256 shardProposalId; // For ApproveNewRealityShard, points to the proposed shard
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => bool

    // Liquid Democracy
    mapping(address => address) public delegates; // delegator => delegatee

    // Staking for Governance Power & Rewards
    uint256 public totalStaked;
    uint256 public stakingRewardRate; // Rewards per governance token per epoch (e.g., 10 = 0.1%)
    uint256 public lastRewardUpdateEpoch;

    mapping(address => uint256) public stakedTokens; // user => amount staked
    mapping(address => uint256) public userRewardPerTokenPaid; // user => accumulated reward per token at last claim/update (scaled)
    mapping(address => uint256) public rewardsClaimable; // user => actual rewards accumulated

    uint256 public rewardPerTokenAccumulated; // Total rewards per token since inception (scaled by 10**18)
    uint256 public totalRewardPool; // Total amount of rewards available in the contract

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "RealityForgeDAO: Not AI Oracle");
        _;
    }

    modifier onlyShardOwner(uint256 _shardId) {
        require(realityShards[_shardId].id != 0, "RealityForgeDAO: Shard does not exist");
        require(realityShards[_shardId].owner == msg.sender, "RealityForgeDAO: Not Shard Owner");
        _;
    }

    // --- Constructor ---
    /// @notice Initializes the RealityForgeDAO contract.
    /// @param _initialAdmin The address of the initial administrator/owner.
    /// @param _aiOracle The address of the trusted AI Oracle contract.
    /// @param _reputationToken The address of the Reputation Token (SBT) contract.
    /// @param _governanceToken The address of the ERC20 governance token contract.
    /// @param _epochDuration The duration of one governance epoch in seconds.
    constructor(
        address _initialAdmin,
        address _aiOracle,
        address _reputationToken,
        address _governanceToken,
        uint256 _epochDuration
    ) Ownable(_initialAdmin) Pausable() {
        require(_aiOracle != address(0), "RealityForgeDAO: AI Oracle address cannot be zero");
        require(_reputationToken != address(0), "RealityForgeDAO: Reputation Token address cannot be zero");
        require(_governanceToken != address(0), "RealityForgeDAO: Governance Token address cannot be zero");
        require(_epochDuration > 0, "RealityForgeDAO: Epoch duration must be positive");

        aiOracle = IAIOracle(_aiOracle);
        reputationToken = IReputationToken(_reputationToken);
        governanceToken = IERC20(_governanceToken);
        epochDuration = _epochDuration;

        nextProposalId = 1;
        nextShardId = 1;
        proposalQuorumThreshold = 4000; // 40%
        proposalPassThreshold = 5000;   // 50%
        proposalMinStakedTokens = 100 * (10 ** governanceToken.decimals()); // Example: 100 tokens (assuming 18 decimals)
        stakingRewardRate = 10; // Example: 0.1% per epoch per token (scaled, 10000 = 100%)
        lastRewardUpdateEpoch = _getCurrentEpoch();
    }

    // --- I. Core Infrastructure & Access Control ---

    // `transferOwnership` (changes admin/owner), `pause`, `unpause` are inherited from OpenZeppelin.

    /// @notice Updates the trusted AI Oracle contract address. Requires a governance proposal to pass.
    ///         This function is primarily called by `executeProposal` after a `SetAIOracle` proposal.
    /// @param _newOracle The address of the new AI Oracle contract.
    function setAIOracleAddress(address _newOracle) public virtual onlyOwner onlyWhenNotPaused {
        require(_newOracle != address(0), "RealityForgeDAO: New AI Oracle address cannot be zero");
        aiOracle = IAIOracle(_newOracle);
    }

    /// @notice Updates the trusted Reputation Token (SBT) contract address. Requires a governance proposal to pass.
    ///         This function is primarily called by `executeProposal` after a `SetReputationToken` proposal.
    /// @param _newReputationToken The address of the new Reputation Token contract.
    function setReputationTokenAddress(address _newReputationToken) public virtual onlyOwner onlyWhenNotPaused {
        require(_newReputationToken != address(0), "RealityForgeDAO: New Reputation Token address cannot be zero");
        reputationToken = IReputationToken(_newReputationToken);
    }

    /// @notice Updates the length of a governance epoch in seconds. Requires a governance proposal to pass.
    ///         This function is primarily called by `executeProposal` after a `ChangeDAOParameter` proposal.
    /// @param _newDuration The new duration for an epoch in seconds.
    function setEpochDuration(uint256 _newDuration) public virtual onlyOwner onlyWhenNotPaused {
        require(_newDuration > 0, "RealityForgeDAO: Epoch duration must be positive");
        epochDuration = _newDuration;
    }

    // --- II. Reality Shards (dNFTs) Management ---

    /// @notice Allows users to propose a new dynamic NFT (Reality Shard) to be approved by governance.
    ///         A `ApproveNewRealityShard` proposal must then be submitted and pass to make it mintable.
    /// @param _name The name of the proposed Shard.
    /// @param _description A description of the Shard.
    /// @param _initialURI The initial metadata URI for the Shard.
    /// @param _initialDynamicAttributes An array of bytes32 representing the initial dynamic properties.
    /// @return The ID of the newly proposed Shard.
    function proposeRealityShard(
        string memory _name,
        string memory _description,
        string memory _initialURI,
        bytes32[] memory _initialDynamicAttributes
    ) public onlyWhenNotPaused returns (uint256) {
        uint256 shardId = nextShardId++;
        realityShards[shardId] = RealityShard({
            id: shardId,
            name: _name,
            description: _description,
            creator: msg.sender,
            currentURI: _initialURI,
            createdEpoch: _getCurrentEpoch(),
            lastEvolutionEpoch: _getCurrentEpoch(),
            dynamicAttributes: _initialDynamicAttributes,
            active: false, // Not active/mintable until approved by governance
            owner: address(0) // No owner until minted
        });
        emit ShardProposed(shardId, msg.sender, _name);
        return shardId;
    }

    /// @notice Mints an approved Reality Shard to a recipient.
    ///         This function is intended to be called by `executeProposal` after an `ApproveNewRealityShard` proposal passes.
    /// @param _shardId The ID of the Reality Shard that was previously proposed and approved.
    /// @param _to The address to which the Shard will be minted.
    function mintRealityShard(uint256 _shardId, address _to) public onlyWhenNotPaused {
        require(realityShards[_shardId].id != 0, "RealityForgeDAO: Shard does not exist");
        require(realityShards[_shardId].active, "RealityForgeDAO: Shard is not approved for minting");
        require(realityShards[_shardId].owner == address(0), "RealityForgeDAO: Shard already minted");
        require(_to != address(0), "RealityForgeDAO: Cannot mint to zero address");

        realityShards[_shardId].owner = _to;
        emit ShardMinted(_shardId, _to);
    }

    /// @notice Allows the creator or current owner to update the metadata URI of a Reality Shard.
    /// @param _shardId The ID of the Reality Shard.
    /// @param _newURI The new URI pointing to the Shard's metadata.
    function updateShardMetadataURI(uint256 _shardId, string memory _newURI) public onlyWhenNotPaused onlyShardOwner(_shardId) {
        require(realityShards[_shardId].active, "RealityForgeDAO: Shard is not active");
        realityShards[_shardId].currentURI = _newURI;
        emit ShardMetadataURIUpdated(_shardId, _newURI);
    }

    /// @notice Requests the AI Oracle to process and potentially evolve a specific Reality Shard's dynamic attributes.
    ///         Can be called by any active user for public shards, or restricted by governance.
    /// @param _shardId The ID of the Reality Shard to evolve.
    /// @param _evolutionPromptHash A hash representing the context or prompt for the AI's evolution process.
    function triggerShardEvolution(uint256 _shardId, bytes32 _evolutionPromptHash) public onlyWhenNotPaused {
        require(realityShards[_shardId].active, "RealityForgeDAO: Shard is not active or does not exist");
        // Further access control could be added here, e.g., onlyShardOwner, or a specific role
        aiOracle.requestShardEvolution(_shardId, _evolutionPromptHash);
        emit ShardEvolutionTriggered(_shardId, _evolutionPromptHash);
    }

    /// @notice Callback function, callable *only* by the AI Oracle, to update a Shard's attributes after evolution.
    /// @param _shardId The ID of the Reality Shard that evolved.
    /// @param _newDynamicAttributes An array of bytes32 representing the new dynamic properties.
    function recordShardEvolutionResult(uint256 _shardId, bytes32[] memory _newDynamicAttributes) public onlyWhenNotPaused onlyAIOracle {
        require(realityShards[_shardId].active, "RealityForgeDAO: Shard is not active or does not exist");
        realityShards[_shardId].dynamicAttributes = _newDynamicAttributes;
        realityShards[_shardId].lastEvolutionEpoch = _getCurrentEpoch();
        emit ShardEvolutionResult(_shardId, _newDynamicAttributes);
    }

    /// @notice Retrieves all details of a specific Reality Shard.
    /// @param _shardId The ID of the Reality Shard.
    /// @return A tuple containing all properties of the Shard.
    function getShardDetails(uint256 _shardId)
        public
        view
        returns (
            uint256 id,
            string memory name,
            string memory description,
            address creator,
            string memory currentURI,
            uint256 createdEpoch,
            uint256 lastEvolutionEpoch,
            bytes32[] memory dynamicAttributes,
            bool active,
            address owner
        )
    {
        RealityShard storage shard = realityShards[_shardId];
        require(shard.id != 0, "RealityForgeDAO: Shard does not exist");
        return (
            shard.id,
            shard.name,
            shard.description,
            shard.creator,
            shard.currentURI,
            shard.createdEpoch,
            shard.lastEvolutionEpoch,
            shard.dynamicAttributes,
            shard.active,
            shard.owner
        );
    }

    // --- III. DAO Governance & Decision Making ---

    /// @notice Submits a new governance proposal. Requires a minimum staked token amount.
    /// @param _proposalHash A unique hash representing the proposal content for integrity.
    /// @param _description A human-readable description of the proposal.
    /// @param _type The type of proposal (e.g., ChangeDAOParameter, ApproveNewRealityShard, ExecuteArbitraryCall).
    /// @param _callData The encoded call data for executable proposals (e.g., ExecuteArbitraryCall).
    /// @param _callTarget The target address for arbitrary calls or new address for setting parameters (e.g., SetAIOracle).
    /// @param _targetParamHash A hash identifier for the specific parameter to change (for ChangeDAOParameter).
    /// @param _newParamValue The new value for the parameter (for ChangeDAOParameter).
    /// @param _shardProposalId For `ApproveNewRealityShard`, the ID of the proposed shard.
    /// @return The ID of the newly created proposal.
    function submitProposal(
        bytes32 _proposalHash,
        string memory _description,
        ProposalType _type,
        bytes memory _callData,
        address _callTarget,
        bytes32 _targetParamHash,
        uint256 _newParamValue,
        uint256 _shardProposalId
    ) public onlyWhenNotPaused returns (uint256) {
        require(stakedTokens[msg.sender] >= proposalMinStakedTokens, "RealityForgeDAO: Not enough tokens staked to submit a proposal");
        require(bytes(_description).length > 0, "RealityForgeDAO: Description cannot be empty");

        uint256 proposalId = nextProposalId++;
        uint256 currentEpoch = _getCurrentEpoch();

        // Specific checks for proposal types
        if (_type == ProposalType.ApproveNewRealityShard) {
            require(realityShards[_shardProposalId].id != 0, "RealityForgeDAO: Shard ID for approval does not exist");
            require(!realityShards[_shardProposalId].active, "RealityForgeDAO: Shard is already approved/active");
        } else if (_type == ProposalType.ExecuteArbitraryCall) {
            require(_callTarget != address(0), "RealityForgeDAO: Target for arbitrary call cannot be zero");
            require(_callData.length > 0, "RealityForgeDAO: Call data for arbitrary call cannot be empty");
        } else if (_type == ProposalType.ChangeDAOParameter) {
            require(_targetParamHash != bytes32(0), "RealityForgeDAO: Parameter hash for change cannot be zero");
        } else if (_type == ProposalType.SetAIOracle || _type == ProposalType.SetReputationToken) {
            require(_callTarget != address(0), "RealityForgeDAO: New address cannot be zero for oracle/reputation token");
        }


        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            startEpoch: currentEpoch,
            endEpoch: currentEpoch + epochDuration, // Voting period is one epoch
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            description: _description,
            proposalType: _type,
            callData: _callData,
            callTarget: _callTarget,
            targetParamHash: _targetParamHash,
            newParamValue: _newParamValue,
            shardProposalId: _shardProposalId
        });

        emit ProposalSubmitted(proposalId, msg.sender, _type, _description);
        return proposalId;
    }

    /// @notice Delegates a user's voting power to another address.
    /// @param _delegatee The address to delegate voting power to.
    function delegateVote(address _delegatee) public onlyWhenNotPaused {
        require(_delegatee != address(0), "RealityForgeDAO: Cannot delegate to zero address");
        require(_delegatee != msg.sender, "RealityForgeDAO: Cannot delegate to self");
        delegates[msg.sender] = _delegatee;
        emit DelegateVote(msg.sender, _delegatee);
    }

    /// @notice Revokes any existing voting delegation, returning voting power to the delegator.
    function undelegateVote() public onlyWhenNotPaused {
        require(delegates[msg.sender] != address(0), "RealityForgeDAO: No active delegation to revoke");
        delete delegates[msg.sender];
        emit UndelegateVote(msg.sender);
    }

    /// @notice Casts a 'yes' or 'no' vote on an active proposal. Voting power is dynamic.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yes', false for 'no'.
    function castVote(uint256 _proposalId, bool _support) public onlyWhenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "RealityForgeDAO: Proposal does not exist");
        require(_getCurrentEpoch() >= proposal.startEpoch && _getCurrentEpoch() < proposal.endEpoch, "RealityForgeDAO: Proposal not in active voting period");

        address voter = msg.sender;
        // Resolve delegatee if applicable
        address actualVoter = delegates[voter] == address(0) ? voter : delegates[voter];
        require(!hasVoted[_proposalId][actualVoter], "RealityForgeDAO: Already voted on this proposal");

        uint256 votingPower = _calculateVotingPower(actualVoter);
        require(votingPower > 0, "RealityForgeDAO: No voting power to cast a vote");

        if (_support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        hasVoted[_proposalId][actualVoter] = true;

        emit VoteCast(_proposalId, actualVoter, _support, votingPower);
    }

    /// @notice Executes a proposal that has passed the voting phase.
    ///         Only executable after the voting period has ended and the proposal has succeeded.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public onlyWhenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "RealityForgeDAO: Proposal does not exist");
        require(!proposal.executed, "RealityForgeDAO: Proposal already executed");
        require(_getCurrentEpoch() >= proposal.endEpoch, "RealityForgeDAO: Voting period not ended");

        ProposalState state = getProposalState(_proposalId);
        require(state == ProposalState.Succeeded, "RealityForgeDAO: Proposal not succeeded");

        proposal.executed = true;

        if (proposal.proposalType == ProposalType.ChangeDAOParameter) {
            _executeChangeDAOParameter(proposal);
        } else if (proposal.proposalType == ProposalType.SetAIOracle) {
            setAIOracleAddress(proposal.callTarget);
        } else if (proposal.proposalType == ProposalType.SetReputationToken) {
            setReputationTokenAddress(proposal.callTarget);
        } else if (proposal.proposalType == ProposalType.ApproveNewRealityShard) {
            RealityShard storage shard = realityShards[proposal.shardProposalId];
            require(shard.id != 0, "RealityForgeDAO: Shard for approval does not exist");
            shard.active = true; // Mark as active, ready for minting by creator/specified owner
            // Optionally, assign owner here: shard.owner = shard.creator;
        } else if (proposal.proposalType == ProposalType.ExecuteArbitraryCall) {
            require(proposal.callTarget != address(0), "RealityForgeDAO: Call target must not be zero");
            (bool success, ) = proposal.callTarget.call(proposal.callData);
            require(success, "RealityForgeDAO: Arbitrary call failed");
        }
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Returns the current state of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The current `ProposalState` of the proposal.
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "RealityForgeDAO: Proposal does not exist");

        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (_getCurrentEpoch() < proposal.startEpoch) {
            return ProposalState.Pending;
        }
        if (_getCurrentEpoch() < proposal.endEpoch) {
            return ProposalState.Active;
        }

        // Voting period has ended
        uint256 totalVotesCast = proposal.yesVotes + proposal.noVotes;
        // Approximation: total voting power in DAO. In a real system, this would be a snapshot.
        uint256 totalVotingPowerInDAO = _getTotalVotingPowerInDAO();

        // Quorum check: total votes cast vs. total DAO voting power
        // Avoid division by zero if totalVotingPowerInDAO is 0. If 0, quorum technically fails unless threshold is 0.
        if (totalVotingPowerInDAO == 0 && proposalQuorumThreshold > 0) return ProposalState.Defeated;
        if (totalVotesCast < (totalVotingPowerInDAO * proposalQuorumThreshold / 10000)) {
            return ProposalState.Defeated; // Failed quorum
        }

        // Pass threshold check: yes votes vs. total votes cast
        if (totalVotesCast == 0 && proposal.yesVotes == 0 && proposalPassThreshold > 0) return ProposalState.Defeated; // No votes, fails pass threshold
        if (proposal.yesVotes * 10000 / totalVotesCast >= proposalPassThreshold) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated; // Failed pass threshold
        }
    }

    /// @notice Returns the combined voting power of a specific address.
    ///         Includes staked tokens and reputation score.
    /// @param _voter The address to check voting power for.
    /// @return The total voting power.
    function getVoterVotingPower(address _voter) public view returns (uint256) {
        return _calculateVotingPower(_voter);
    }

    /// @notice Returns the address to whom a voter has delegated their vote.
    /// @param _voter The address whose delegatee is to be retrieved.
    /// @return The address of the delegatee, or address(0) if no delegation.
    function getDelegatee(address _voter) public view returns (address) {
        return delegates[_voter];
    }

    // --- IV. Staking & Rewards ---

    /// @notice Allows users to stake governance tokens to gain voting power and earn rewards.
    /// @param _amount The amount of governance tokens to stake.
    function stakeForGovernance(uint256 _amount) public onlyWhenNotPaused {
        require(_amount > 0, "RealityForgeDAO: Amount must be greater than zero");
        _updateReward(msg.sender); // Update user's rewards before changing stake
        totalStaked += _amount;
        stakedTokens[msg.sender] += _amount;
        require(governanceToken.transferFrom(msg.sender, address(this), _amount), "RealityForgeDAO: Token transfer failed");
        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Allows users to unstake their governance tokens.
    /// @param _amount The amount of governance tokens to unstake.
    function unstakeFromGovernance(uint256 _amount) public onlyWhenNotPaused {
        require(_amount > 0, "RealityForgeDAO: Amount must be greater than zero");
        require(stakedTokens[msg.sender] >= _amount, "RealityForgeDAO: Not enough staked tokens");
        _updateReward(msg.sender); // Update user's rewards before changing stake
        totalStaked -= _amount;
        stakedTokens[msg.sender] -= _amount;
        require(governanceToken.transfer(msg.sender, _amount), "RealityForgeDAO: Token transfer failed");
        emit TokensUnstaked(msg.sender, _amount);
    }

    /// @notice Allows stakers to claim their accumulated rewards.
    function claimStakingRewards() public onlyWhenNotPaused {
        _updateReward(msg.sender); // Final update for the user
        uint256 rewards = rewardsClaimable[msg.sender];
        require(rewards > 0, "RealityForgeDAO: No rewards to claim");
        rewardsClaimable[msg.sender] = 0;
        totalRewardPool -= rewards; // Reduce from global pool
        require(governanceToken.transfer(msg.sender, rewards), "RealityForgeDAO: Reward transfer failed");
        emit RewardsClaimed(msg.sender, rewards);
    }

    /// @notice Callable by admin or specific role to add rewards to the pool.
    /// @param _amount The amount of governance tokens to distribute as rewards.
    function distributeStakingRewards(uint256 _amount) public onlyWhenNotPaused onlyOwner {
        require(_amount > 0, "RealityForgeDAO: Amount must be greater than zero");
        _updateReward(address(0)); // Update global rewards before adding more
        totalRewardPool += _amount;
        require(governanceToken.transferFrom(msg.sender, address(this), _amount), "RealityForgeDAO: Token transfer failed for distribution");
        emit RewardsDistributed(_amount);
    }

    /// @notice Updates the reward rate for staking. Requires a governance proposal to pass.
    ///         This function is primarily called by `executeProposal` after a `ChangeDAOParameter` proposal.
    /// @param _newRate The new reward rate (e.g., 10 for 0.1%).
    function setStakingRewardRate(uint256 _newRate) public virtual onlyOwner onlyWhenNotPaused {
        _updateReward(address(0)); // Update rewards before changing rate
        stakingRewardRate = _newRate;
        emit StakingRewardRateUpdated(_newRate);
    }

    /// @notice Returns the total amount of governance tokens currently staked in the DAO.
    /// @return The total amount staked.
    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }

    // --- Internal / Private Helper Functions ---

    /// @dev Calculates the current epoch based on `block.timestamp` and `epochDuration`.
    function _getCurrentEpoch() internal view returns (uint256) {
        return block.timestamp / epochDuration;
    }

    /// @dev Calculates the combined voting power of a user, considering staked tokens and reputation.
    /// @param _voter The address for whom to calculate voting power.
    /// @return The total voting power.
    function _calculateVotingPower(address _voter) internal view returns (uint256) {
        uint256 stakePower = stakedTokens[_voter];
        uint256 reputationPower = reputationToken.getReputation(_voter);
        // Example: 1 token = 1 voting power. 1 reputation point = 0.5 voting power.
        // Scaling factor for reputation can be adjusted.
        // Assuming reputation points are roughly equivalent to governance token decimals for simplicity.
        return stakePower + (reputationPower / 2); // Simple combination
    }

    /// @dev Internal function to update reward calculation for a user or globally.
    /// @param _user The address of the user to update rewards for. `address(0)` for global update.
    function _updateReward(address _user) internal {
        uint256 currentEpoch = _getCurrentEpoch();
        if (currentEpoch > lastRewardUpdateEpoch && totalStaked > 0 && totalRewardPool > 0) {
            uint256 epochsPassed = currentEpoch - lastRewardUpdateEpoch;
            // Calculate new rewards. Scale by 10000 for percentage (stakingRewardRate is e.g., 10 for 0.1%)
            // and by 10**18 to maintain high precision for rewardPerTokenAccumulated.
            uint256 newRewards = (totalStaked * stakingRewardRate * epochsPassed) / 10000;
            if (newRewards > totalRewardPool) {
                newRewards = totalRewardPool; // Cap new rewards at available pool
            }
            rewardPerTokenAccumulated += (newRewards * (10 ** 18)) / totalStaked;
            lastRewardUpdateEpoch = currentEpoch;
        }

        if (_user != address(0) && stakedTokens[_user] > 0) {
            // Calculate rewards due to user since last update
            rewardsClaimable[_user] += (stakedTokens[_user] * (rewardPerTokenAccumulated - userRewardPerTokenPaid[_user])) / (10 ** 18);
            userRewardPerTokenPaid[_user] = rewardPerTokenAccumulated;
        }
    }

    /// @dev Internal function to get the total voting power in the DAO (sum of all staked tokens + reputations).
    ///      This is a simplified estimate for quorum calculation. In a real system, tracking all reputations
    ///      on-chain can be gas-intensive, so a snapshot or a capped value might be used.
    ///      For this example, we'll approximate with totalStaked as the dominant factor.
    function _getTotalVotingPowerInDAO() internal view returns (uint256) {
        // A more robust implementation would need to track global reputation or use snapshots.
        // For simplicity, we'll approximate with total staked tokens as a base.
        // If reputation is significant, a mechanism to calculate/snapshot total reputation would be needed.
        return totalStaked;
    }

    /// @dev Internal function to execute DAO parameter changes based on a passed proposal.
    function _executeChangeDAOParameter(Proposal storage _proposal) internal {
        bytes32 paramHash = _proposal.targetParamHash;
        uint256 newValue = _proposal.newParamValue;

        if (paramHash == keccak256("epochDuration")) {
            setEpochDuration(newValue);
        } else if (paramHash == keccak256("proposalQuorumThreshold")) {
            require(newValue <= 10000, "RealityForgeDAO: Quorum threshold must be <= 100%");
            proposalQuorumThreshold = newValue;
        } else if (paramHash == keccak256("proposalPassThreshold")) {
            require(newValue <= 10000, "RealityForgeDAO: Pass threshold must be <= 100%");
            proposalPassThreshold = newValue;
        } else if (paramHash == keccak256("proposalMinStakedTokens")) {
            proposalMinStakedTokens = newValue;
        } else if (paramHash == keccak256("stakingRewardRate")) {
            setStakingRewardRate(newValue);
        } else {
            revert("RealityForgeDAO: Unknown DAO parameter for change");
        }
    }
}
```