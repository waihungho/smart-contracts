Okay, here is a smart contract concept called the "Synergy Nexus Protocol". It's a decentralized system focused on collaborative skill-building, reputation earning, and resource staking. It combines elements of reputation systems, NFT utility, delegation, and dynamic parameters, all interacting within a project-based framework.

This design aims to be complex and creative by:
1.  **Integrating FT (ERC20) and NFT (ERC721) staking.**
2.  **Implementing a non-transferable Reputation (REP) score.**
3.  **Using REP and staked NFTs to unlock on-chain Capabilities/Roles.**
4.  **Allowing delegation of Capabilities.**
5.  **Featuring a basic, dynamic Project/Challenge system** where participants collaborate, earn REP and rewards upon completion.
6.  **Including dynamic parameters** adjustable by high-REP participants or via a specific capability.

It attempts to avoid direct duplication of standard templates by weaving these concepts together into a specific protocol flow, rather than just being a basic token, NFT, or single-purpose DAO contract.

---

**Outline and Function Summary: Synergy Nexus Protocol**

This contract manages participant reputation, staked assets (ERC20 and ERC721), capability delegation, and a project lifecycle system.

**I. State Variables:**
*   Addresses for the core ERC20 (NEXUS) and ERC721 (SynergyNFT) tokens.
*   Mapping: participant address -> Reputation score (uint256).
*   Mapping: participant address -> Staked NEXUS amount (uint256).
*   Mapping: participant address -> List of Staked SynergyNFT IDs (uint256[]).
*   Mapping: participant address -> address delegated capability to (address).
*   Dynamic parameters (REP thresholds for capabilities, staking rewards per REP/time, project creation/approval thresholds, project rewards).
*   Project data structure: ID, proposer, status, required REP to join, participants, completion details, rewards.
*   Mapping: project ID -> Project details.
*   Counter for unique project IDs.
*   Pausable state variable.

**II. Modifiers:**
*   `onlyHighRep(uint256 _requiredRep)`: Restricts access to addresses with at least `_requiredRep`.
*   `onlyCapability(bytes32 _capabilityId)`: Restricts access to addresses possessing a specific capability (derived from REP/NFTs/Delegation).
*   `onlyProjectParticipant(uint256 _projectId)`: Restricts access to addresses participating in a specific project.
*   `onlyProjectProposer(uint256 _projectId)`: Restricts access to the proposer of a specific project.
*   `whenNotPaused` & `whenPaused`: Standard OpenZeppelin modifiers.

**III. Events:**
*   `ReputationGained(address indexed participant, uint256 amount, string reason)`
*   `NexusStaked(address indexed participant, uint256 amount)`
*   `NexusUnstaked(address indexed participant, uint256 amount)`
*   `SynergyNFTStaked(address indexed participant, uint256 indexed tokenId)`
*   `SynergyNFTUnstaked(address indexed participant, uint256 indexed tokenId)`
*   `CapabilityDelegated(address indexed delegator, address indexed delegatee, bytes32 indexed capabilityId)` (Simplification: Delegate *all* capabilities for this example)
*   `CapabilityUndelegated(address indexed delegator)`
*   `ProjectProposalCreated(uint256 indexed projectId, address indexed proposer, uint256 requiredRep)`
*   `ProjectApproved(uint256 indexed projectId, address indexed approver)`
*   `ProjectRejected(uint256 indexed projectId, address indexed approver)`
*   `ProjectJoined(uint256 indexed projectId, address indexed participant)`
*   `ProjectWorkSubmitted(uint256 indexed projectId, address indexed participant)`
*   `ProjectCompleted(uint256 indexed projectId, address indexed completer, uint256 totalRepDistributed, uint256 totalTokenDistributed)`
*   `ProjectRewardsClaimed(uint256 indexed projectId, address indexed participant, uint256 repEarned, uint256 tokensEarned)`
*   `ParameterUpdated(bytes32 indexed parameterKey, uint256 oldValue, uint256 newValue)`
*   `ContractPaused(address indexed account)`
*   `ContractUnpaused(address indexed account)`

**IV. Functions (29 Functions):**

1.  `constructor(address _nexusToken, address _synergyNFTContract)`: Initializes the contract with token addresses.
2.  `stakeNexus(uint256 _amount)`: Allows a participant to stake NEXUS tokens. Requires prior approval.
3.  `unstakeNexus(uint256 _amount)`: Allows a participant to unstake NEXUS tokens. Subject to potential lock-up rules (not fully implemented here for brevity).
4.  `stakeSynergyNFT(uint256 _tokenId)`: Allows a participant to stake a specific Synergy NFT. Requires prior approval or ownership transfer.
5.  `unstakeSynergyNFT(uint256 _tokenId)`: Allows a participant to unstake a previously staked Synergy NFT.
6.  `getReputation(address _participant)`: View function to check a participant's current REP score.
7.  `getNexusStaked(address _participant)`: View function to check a participant's staked NEXUS amount.
8.  `getSynergyNFTsStaked(address _participant)`: View function to check the list of Synergy NFT IDs staked by a participant.
9.  `checkCapability(address _participant, bytes32 _capabilityId)`: View function to check if a participant (or their delegate) possesses a specific capability based on REP, staked NFTs, or roles.
10. `delegateCapability(address _delegatee)`: Allows a participant to delegate their capabilities (derived from REP/NFTs) to another address.
11. `undelegateCapability()`: Allows a participant to remove their delegation.
12. `getDelegate(address _participant)`: View function to see who a participant has delegated their capabilities to.
13. `getDelegator(address _delegatee)`: View function to see who has delegated capabilities *to* this delegatee (simplified: maybe just returns the first one found or requires indexing). For this example, let's simplify and not track delegators easily via mapping. (Let's skip this one to keep it simpler based on the delegation model).
14. `createProjectProposal(uint256 _requiredRepToJoin, string memory _ipfsHash)`: Allows a participant (with sufficient REP) to propose a new project.
15. `approveProjectProposal(uint256 _projectId)`: Allows participants with a specific capability (e.g., high REP or "Curator" role) to approve a project proposal.
16. `rejectProjectProposal(uint256 _projectId)`: Allows participants with the approval capability to reject a project proposal.
17. `joinProject(uint256 _projectId)`: Allows a participant meeting the project's `requiredRepToJoin` to join an approved project.
18. `submitProjectWork(uint256 _projectId, string memory _workHash)`: Allows a project participant to mark their work as submitted for a project. (Simplified state update).
19. `completeProject(uint256 _projectId)`: Allows a participant with a specific capability (e.g., high REP or "Validator" role) to mark a project as completed. Triggers REP/token distribution to participants.
20. `claimProjectRewards(uint256 _projectId)`: Allows a participant in a completed project to claim their earned REP and tokens.
21. `updateReputationThresholds(bytes32 _capabilityId, uint256 _newThreshold)`: Allows participants with a specific "Protocol Admin" capability (very high REP/specific NFT) to adjust the REP required for capabilities.
22. `updateStakingYieldRate(uint256 _newRatePerRepPerSecond)`: Allows Protocol Admins to adjust the REP earning rate from staking (simplified calculation).
23. `updateProjectApprovalThreshold(uint256 _newThreshold)`: Allows Protocol Admins to adjust the REP needed to approve projects.
24. `updateProjectCompletionRewards(uint256 _projectId, uint256 _repReward, uint256 _tokenReward)`: Allows Protocol Admins to adjust rewards for a *specific* project (before completion).
25. `pauseContract()`: Allows the owner or a specific admin role to pause the contract in emergencies.
26. `unpauseContract()`: Allows the owner or admin role to unpause the contract.
27. `withdrawAccidentalTokens(address _tokenAddress, uint256 _amount)`: Allows the owner to withdraw tokens accidentally sent to the contract address (excluding protocol tokens).
28. `setNexusToken(address _newAddress)`: Allows the owner to update the NEXUS token address (carefully).
29. `setSynergyNFTContract(address _newAddress)`: Allows the owner to update the Synergy NFT contract address (carefully).
30. `getProjectDetails(uint256 _projectId)`: View function to retrieve details about a specific project.
31. `getProjectsByStatus(uint256 _status)`: View function to list projects matching a given status (e.g., Proposed, Approved, Completed). (Requires iterating, gas warning).
32. `getParticipantProjects(address _participant)`: View function to list projects a specific participant is involved in. (Requires iterating, gas warning).

Total functions: 32 (more than 20).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for high-level admin

/**
 * @title SynergyNexusProtocol
 * @dev A decentralized protocol for collaborative projects, reputation building,
 * and resource staking based on participant reputation, staked tokens/NFTs,
 * and dynamic parameters.
 *
 * --- Outline ---
 * I. State Variables:
 *    - Token addresses (NEXUS, SynergyNFT)
 *    - Participant data: reputation, staked NEXUS, staked NFT IDs, delegation target
 *    - Dynamic parameters (REP thresholds, staking rates, project parameters)
 *    - Project data structure and storage
 *    - Project ID counter
 *    - Pausable state
 *
 * II. Modifiers:
 *    - onlyHighRep: Requires minimum reputation
 *    - onlyCapability: Requires a specific capability ID
 *    - onlyProjectParticipant: Requires participant in a project
 *    - onlyProjectProposer: Requires proposer of a project
 *    - whenNotPaused, whenPaused: Standard pausable checks
 *
 * III. Events:
 *    - ReputationGained, NexusStaked/Unstaked, SynergyNFTStaked/Unstaked,
 *    - CapabilityDelegated/Undelegated, ProjectProposalCreated/Approved/Rejected,
 *    - ProjectJoined, ProjectWorkSubmitted, ProjectCompleted, ProjectRewardsClaimed,
 *    - ParameterUpdated, ContractPaused/Unpaused, WithdrawAccidentalTokens, SetTokenAddress
 *
 * IV. Functions (32 Functions Total):
 *    - Constructor: Initializes contract with token addresses.
 *    - Staking (ERC20 & ERC721): stakeNexus, unstakeNexus, stakeSynergyNFT, unstakeSynergyNFT, getNexusStaked, getSynergyNFTsStaked.
 *    - Reputation: getReputation (gainReputation is internal).
 *    - Capabilities & Delegation: checkCapability, delegateCapability, undelegateCapability, getDelegate.
 *    - Project System: createProjectProposal, approveProjectProposal, rejectProjectProposal, joinProject, submitProjectWork, completeProject, claimProjectRewards, getProjectDetails, getProjectsByStatus, getParticipantProjects.
 *    - Dynamic Parameters: updateReputationThresholds, updateStakingYieldRate, updateProjectApprovalThreshold, updateProjectCompletionRewards.
 *    - Admin & Utility: pauseContract, unpauseContract, withdrawAccidentalTokens, setNexusToken, setSynergyNFTContract.
 */
contract SynergyNexusProtocol is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    IERC20 public nexusToken;
    IERC721 public synergyNFTContract;

    // Participant Data
    mapping(address => uint256) public reputation; // Non-transferable reputation score
    mapping(address => uint256) public stakedNexus;
    mapping(address => uint256[]) private _stakedSynergyNFTs; // Store IDs of staked NFTs per user
    mapping(address => address) public delegates; // Address delegated capabilities to

    // Dynamic Parameters (Simplified example parameters)
    uint256 public projectCreationRepThreshold = 100;
    uint256 public projectApprovalRepThreshold = 500;
    uint256 public projectCompletionRepReward = 50;
    uint256 public projectCompletionTokenReward = 100; // Amount per participant
    uint256 public stakingYieldRatePerRepPerSecond = 1 wei; // Example: earns 1 wei REP per staked NEXUS per second

    // Capability Thresholds (Mapping capability ID hash to required REP)
    mapping(bytes32 => uint256) public capabilityRepThresholds;

    // Project System
    enum ProjectStatus { Proposed, Approved, Rejected, Active, Completed }

    struct Project {
        uint256 id;
        address proposer;
        ProjectStatus status;
        uint256 requiredRepToJoin;
        string ipfsHash; // Link to project details off-chain
        address[] participants;
        mapping(address => bool) hasSubmittedWork; // Simplified: Did participant submit?
        bool rewardsClaimed; // Flag if project rewards have been distributed internally/claimed
        uint256 totalRepDistributed; // Sum of REP distributed upon completion
        uint256 totalTokenDistributed; // Sum of Tokens distributed upon completion
    }

    mapping(uint256 => Project) public projects;
    uint256 private _nextProjectId = 1;

    // --- Events ---

    event ReputationGained(address indexed participant, uint256 amount, string reason);
    event NexusStaked(address indexed participant, uint256 amount);
    event NexusUnstaked(address indexed participant, uint256 amount);
    event SynergyNFTStaked(address indexed participant, uint256 indexed tokenId);
    event SynergyNFTUnstaked(address indexed participant, uint256 indexed tokenId);
    event CapabilityDelegated(address indexed delegator, address indexed delegatee); // Simplified: delegates all capabilities
    event CapabilityUndelegated(address indexed delegator);
    event ProjectProposalCreated(uint256 indexed projectId, address indexed proposer, uint256 requiredRep);
    event ProjectApproved(uint256 indexed projectId, address indexed approver);
    event ProjectRejected(uint256 indexed projectId, address indexed approver);
    event ProjectJoined(uint256 indexed projectId, address indexed participant);
    event ProjectWorkSubmitted(uint256 indexed projectId, address indexed participant);
    event ProjectCompleted(uint256 indexed projectId, address indexed completer, uint256 totalRepDistributed, uint256 totalTokenDistributed);
    event ProjectRewardsClaimed(uint256 indexed projectId, address indexed participant, uint256 repEarned, uint256 tokensEarned);
    event ParameterUpdated(bytes32 indexed parameterKey, uint256 oldValue, uint256 newValue);
    event SetTokenAddress(address indexed oldAddress, address indexed newAddress, string tokenName);
    event WithdrawAccidentalTokens(address indexed tokenAddress, address indexed recipient, uint256 amount);

    // --- Errors ---

    error ZeroAddress();
    error InvalidAmount();
    error InsufficientReputation(uint256 required, uint256 current);
    error NexusStakeFailed();
    error NexusUnstakeFailed();
    error InsufficientStakedNexus(uint256 required, uint256 current);
    error NFTStakeFailed();
    error NFTUnstakeFailed();
    error NFTNotStaked(uint256 tokenId);
    error NotStakedByCaller(uint256 tokenId);
    error AlreadyDelegated();
    error NotDelegating();
    error ProjectNotFound();
    error ProjectNotInStatus(ProjectStatus requiredStatus);
    error ProjectStatusMismatch(ProjectStatus requiredStatus, ProjectStatus currentStatus);
    error AlreadyParticipant();
    error NotProjectParticipant();
    error WorkAlreadySubmitted();
    error ProjectNotCompleted();
    error RewardsAlreadyClaimed();
    error InvalidParameter();
    error TokenIsProtocolToken();
    error Unauthorized(); // Custom error for modifier failures

    // --- Constructor ---

    constructor(address _nexusToken, address _synergyNFTContract) Ownable(msg.sender) Pausable(false) {
        if (_nexusToken == address(0) || _synergyNFTContract == address(0)) revert ZeroAddress();
        nexusToken = IERC20(_nexusToken);
        synergyNFTContract = IERC721(_synergyNFTContract);

        // Set initial default capability thresholds
        capabilityRepThresholds[keccak256("ProjectProposer")] = projectCreationRepThreshold;
        capabilityRepThresholds[keccak256("ProjectApprover")] = projectApprovalRepThreshold;
        capabilityRepThresholds[keccak256("ProjectCompleter")] = projectApprovalRepThreshold; // Reusing threshold for simplicity
        capabilityRepThresholds[keccak256("ProtocolAdmin")] = 10000; // Very high REP for admin actions
    }

    // --- Modifiers ---

    modifier onlyHighRep(uint256 _requiredRep) {
        if (reputation[msg.sender] < _requiredRep) {
            revert InsufficientReputation(_requiredRep, reputation[msg.sender]);
        }
        _;
    }

    // Note: This capability check includes delegation
    modifier onlyCapability(bytes32 _capabilityId) {
        if (!checkCapability(msg.sender, _capabilityId)) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyProjectParticipant(uint256 _projectId) {
        bool isParticipant = false;
        Project storage project = projects[_projectId];
        for (uint i = 0; i < project.participants.length; i++) {
            if (project.participants[i] == msg.sender) {
                isParticipant = true;
                break;
            }
        }
        if (!isParticipant) revert NotProjectParticipant();
        _;
    }

    modifier onlyProjectProposer(uint256 _projectId) {
        if (projects[_projectId].proposer != msg.sender) revert OnlyProjectProposer(_projectId);
        _;
    }

    // --- Internal Functions ---

    /**
     * @dev Internal function to add reputation. Can be called by staking logic,
     * project completion, etc.
     * @param _participant The address to add reputation to.
     * @param _amount The amount of reputation to add.
     * @param _reason A string indicating why reputation was gained.
     */
    function _gainReputation(address _participant, uint256 _amount, string memory _reason) internal {
        if (_amount == 0) return; // No-op if amount is zero
        uint256 oldRep = reputation[_participant];
        reputation[_participant] += _amount;
        // Note: Could add checks here for leveling up or unlocking thresholds
        emit ReputationGained(_participant, _amount, _reason);
    }

    /**
     * @dev Helper to find index of NFT ID in an array.
     */
    function _findNFTIndex(uint256[] storage arr, uint256 value) private view returns (int256) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                return int256(i);
            }
        }
        return -1; // Not found
    }

    /**
     * @dev Helper to remove element from dynamic array (order doesn't matter).
     */
    function _removeNFTAtIndex(uint256[] storage arr, uint256 index) private {
        require(index < arr.length, "Index out of bounds");
        arr[index] = arr[arr.length - 1]; // Replace with last element
        arr.pop(); // Remove last element
    }


    // --- External Functions ---

    // --- Staking Functions ---

    /**
     * @dev Stakes NEXUS tokens. Requires the caller to have approved the contract
     * to spend the tokens beforehand.
     * @param _amount The amount of NEXUS tokens to stake.
     */
    function stakeNexus(uint256 _amount) external nonReentrant whenNotPaused {
        if (_amount == 0) revert InvalidAmount();

        nexusToken.safeTransferFrom(msg.sender, address(this), _amount);
        stakedNexus[msg.sender] += _amount;

        // Potential future logic: Award initial REP for staking, or start timer for yield
        _gainReputation(msg.sender, _amount / 100, "Initial NEXUS Stake"); // Example: 1 REP per 100 NEXUS

        emit NexusStaked(msg.sender, _amount);
    }

    /**
     * @dev Unstakes NEXUS tokens.
     * @param _amount The amount of NEXUS tokens to unstake.
     */
    function unstakeNexus(uint256 _amount) external nonReentrant whenNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (stakedNexus[msg.sender] < _amount) revert InsufficientStakedNexus(_amount, stakedNexus[msg.sender]);

        stakedNexus[msg.sender] -= _amount;
        nexusToken.safeTransfer(msg.sender, _amount);

        // Potential future logic: Deduct REP for unstaking, or calculate staking yield here
        // _gainReputation(msg.sender, calculateStakingYield(msg.sender), "Staking Yield"); // Example yield logic

        emit NexusUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Stakes a Synergy NFT. Requires the caller to own the NFT
     * and have approved the contract to transfer it, or the NFT to be sent
     * to the contract with onERC721Received callback handling.
     * This implementation requires prior approval.
     * @param _tokenId The ID of the Synergy NFT to stake.
     */
    function stakeSynergyNFT(uint256 _tokenId) external nonReentrant whenNotPaused {
        address owner = synergyNFTContract.ownerOf(_tokenId);
        if (owner != msg.sender) revert Unauthorized(); // Must own the NFT

        synergyNFTContract.transferFrom(msg.sender, address(this), _tokenId);

        _stakedSynergyNFTs[msg.sender].push(_tokenId);

        // Potential future logic: Award REP for staking specific NFTs or types
        _gainReputation(msg.sender, 20, "Staked Synergy NFT"); // Example REP reward

        emit SynergyNFTStaked(msg.sender, _tokenId);
    }

    /**
     * @dev Unstakes a Synergy NFT.
     * @param _tokenId The ID of the Synergy NFT to unstake.
     */
    function unstakeSynergyNFT(uint256 _tokenId) external nonReentrant whenNotPaused {
        int256 index = _findNFTIndex(_stakedSynergyNFTs[msg.sender], _tokenId);
        if (index == -1) revert NFTNotStaked(_tokenId);

        _removeNFTAtIndex(_stakedSynergyNFTs[msg.sender], uint256(index));

        synergyNFTContract.safeTransferFrom(address(this), msg.sender, _tokenId);

        // Potential future logic: Deduct REP or remove capability linked to NFT
        // No REP deduction for simplicity here

        emit SynergyNFTUnstaked(msg.sender, _tokenId);
    }

    // --- Reputation & Capability Functions ---

    /**
     * @dev Gets the reputation score for a participant.
     * @param _participant The address to check.
     * @return uint256 The reputation score.
     */
    function getReputation(address _participant) external view returns (uint256) {
        return reputation[_participant];
    }

    /**
     * @dev Gets the amount of NEXUS tokens staked by a participant.
     * @param _participant The address to check.
     * @return uint256 The staked NEXUS amount.
     */
    function getNexusStaked(address _participant) external view returns (uint256) {
        return stakedNexus[_participant];
    }

    /**
     * @dev Gets the list of Synergy NFT IDs staked by a participant.
     * @param _participant The address to check.
     * @return uint256[] The array of staked NFT IDs.
     */
    function getSynergyNFTsStaked(address _participant) external view returns (uint256[] memory) {
        return _stakedSynergyNFTs[_participant];
    }

    /**
     * @dev Checks if an address (or their delegate) meets the requirements for a capability.
     * Capabilities are defined by string IDs (e.g., "ProjectProposer", "ProtocolAdmin").
     * Requirements are primarily based on REP threshold or potentially specific staked NFTs.
     * This simplified implementation checks only REP threshold based on a mapping.
     * Delegation allows the delegatee to act *as if* they had the delegator's REP/capabilities.
     * @param _participant The address whose capability to check.
     * @param _capabilityId The hash of the capability string ID (e.g., keccak256("ProjectProposer")).
     * @return bool True if the participant or their delegate has the capability.
     */
    function checkCapability(address _participant, bytes32 _capabilityId) public view returns (bool) {
        address effectiveParticipant = delegates[_participant] == address(0) ? _participant : delegates[_participant];

        uint256 requiredRep = capabilityRepThresholds[_capabilityId];

        // Basic capability check: Meets REP threshold
        if (reputation[effectiveParticipant] >= requiredRep) {
            return true;
        }

        // Future: Add checks for specific staked NFTs or roles here

        return false;
    }

    /**
     * @dev Allows a participant to delegate their capabilities to another address.
     * The delegatee can then perform actions requiring the delegator's capabilities
     * (e.g., proposing/approving projects).
     * @param _delegatee The address to delegate capabilities to. Must not be self or zero address.
     */
    function delegateCapability(address _delegatee) external whenNotPaused {
        if (_delegatee == msg.sender || _delegatee == address(0)) revert InvalidAmount(); // Use InvalidAmount for semantic error
        if (delegates[msg.sender] != address(0)) revert AlreadyDelegated();

        delegates[msg.sender] = _delegatee;
        emit CapabilityDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Allows a participant to remove their delegation.
     */
    function undelegateCapability() external whenNotPaused {
        if (delegates[msg.sender] == address(0)) revert NotDelegating();

        delete delegates[msg.sender];
        emit CapabilityUndelegated(msg.sender);
    }

    /**
     * @dev Gets the address to which a participant has delegated their capabilities.
     * @param _participant The address to check.
     * @return address The delegatee address, or address(0) if no delegation.
     */
    function getDelegate(address _participant) external view returns (address) {
        return delegates[_participant];
    }

    // --- Project System Functions ---

    /**
     * @dev Allows a participant with sufficient REP to propose a new project.
     * @param _requiredRepToJoin The minimum REP participants need to join this project.
     * @param _ipfsHash IPFS hash or URL pointing to project details.
     */
    function createProjectProposal(uint256 _requiredRepToJoin, string memory _ipfsHash) external onlyCapability(keccak256("ProjectProposer")) whenNotPaused {
        uint256 projectId = _nextProjectId++;
        Project storage newProject = projects[projectId];

        newProject.id = projectId;
        newProject.proposer = msg.sender;
        newProject.status = ProjectStatus.Proposed;
        newProject.requiredRepToJoin = _requiredRepToJoin;
        newProject.ipfsHash = _ipfsHash;
        // participants mapping and hasSubmittedWork mapping are initialized empty

        emit ProjectProposalCreated(projectId, msg.sender, _requiredRepToJoin);
    }

    /**
     * @dev Allows a participant with the Project Approver capability to approve a project proposal.
     * Moves the project status from Proposed to Active.
     * @param _projectId The ID of the project proposal to approve.
     */
    function approveProjectProposal(uint256 _projectId) external onlyCapability(keccak256("ProjectApprover")) whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Proposed) revert ProjectStatusMismatch(ProjectStatus.Proposed, project.status);

        project.status = ProjectStatus.Active;
        emit ProjectApproved(_projectId, msg.sender);
    }

    /**
     * @dev Allows a participant with the Project Approver capability to reject a project proposal.
     * Moves the project status from Proposed to Rejected.
     * @param _projectId The ID of the project proposal to reject.
     */
    function rejectProjectProposal(uint256 _projectId) external onlyCapability(keccak256("ProjectApprover")) whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Proposed) revert ProjectStatusMismatch(ProjectStatus.Proposed, project.status);

        project.status = ProjectStatus.Rejected;
        emit ProjectRejected(_projectId, msg.sender);
    }

    /**
     * @dev Allows a participant meeting the project's REP requirement to join an Active project.
     * @param _projectId The ID of the project to join.
     */
    function joinProject(uint256 _projectId) external nonReentrant whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active) revert ProjectStatusMismatch(ProjectStatus.Active, project.status);
        if (reputation[msg.sender] < project.requiredRepToJoin) revert InsufficientReputation(project.requiredRepToJoin, reputation[msg.sender]);

        // Check if already participant
        for (uint i = 0; i < project.participants.length; i++) {
            if (project.participants[i] == msg.sender) revert AlreadyParticipant();
        }

        project.participants.push(msg.sender);
        emit ProjectJoined(_projectId, msg.sender);
    }

    /**
     * @dev Allows a project participant to mark their work as submitted for an Active project.
     * This is a simplified state update for the example.
     * @param _projectId The ID of the project.
     * @param _workHash IPFS hash or link to the submitted work.
     */
    function submitProjectWork(uint256 _projectId, string memory _workHash) external onlyProjectParticipant(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active) revert ProjectStatusMismatch(ProjectStatus.Active, project.status);
        if (project.hasSubmittedWork[msg.sender]) revert WorkAlreadySubmitted();

        project.hasSubmittedWork[msg.sender] = true;
        // Note: _workHash is not stored on-chain for gas efficiency, only the fact of submission
        emit ProjectWorkSubmitted(_projectId, msg.sender);
    }

    /**
     * @dev Allows a participant with the Project Completer capability to mark an Active project as completed.
     * This distributes REP and prepares tokens for claiming by participants who submitted work.
     * @param _projectId The ID of the project to complete.
     */
    function completeProject(uint256 _projectId) external onlyCapability(keccak256("ProjectCompleter")) nonReentrant whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Active) revert ProjectStatusMismatch(ProjectStatus.Active, project.status);

        project.status = ProjectStatus.Completed;
        project.totalRepDistributed = 0;
        project.totalTokenDistributed = 0;

        // Distribute rewards to participants who submitted work
        for (uint i = 0; i < project.participants.length; i++) {
            address participant = project.participants[i];
            if (project.hasSubmittedWork[participant]) {
                // Calculate individual rewards (can be more complex)
                uint256 repEarned = projectCompletionRepReward;
                uint256 tokensEarned = projectCompletionTokenReward;

                _gainReputation(participant, repEarned, string(abi.encodePacked("Project Completion: ", uint256(projectId))));
                // Tokens are claimable later, not transferred immediately
                // Store earned tokens per participant if needed for claiming (not done in this simplified model)
                // For this example, they claim the *base* project reward, complex per-user reward requires more state

                project.totalRepDistributed += repEarned;
                project.totalTokenDistributed += tokensEarned; // Summing the *potential* token rewards
            }
        }

        // Reward proposer too?
        _gainReputation(project.proposer, projectCompletionRepReward / 2, string(abi.encodePacked("Project Proposer Reward: ", uint256(projectId))));
        project.totalRepDistributed += projectCompletionRepReward / 2; // Add proposer's REP to total

        emit ProjectCompleted(_projectId, msg.sender, project.totalRepDistributed, project.totalTokenDistributed);
    }

    /**
     * @dev Allows a participant in a Completed project to claim their earned tokens.
     * Assumes a fixed reward per participant who submitted work.
     * In a real scenario, this would need mapping to store per-participant earned rewards.
     * This simplified version lets any participant in the *completed* project claim the base reward once.
     * @param _projectId The ID of the project.
     */
    function claimProjectRewards(uint256 _projectId) external nonReentrant whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.status != ProjectStatus.Completed) revert ProjectNotInStatus(ProjectStatus.Completed);
        // Ensure caller was a participant (or simplify and allow anyone to trigger transfer for a participant)
        bool isParticipant = false;
         for (uint i = 0; i < project.participants.length; i++) {
            if (project.participants[i] == msg.sender) {
                isParticipant = true;
                break;
            }
        }
        if (!isParticipant) revert NotProjectParticipant(); // Only participants can claim

        // Simplified: This check prevents double claiming the *project's total pool*,
        // not per-user claiming. A real system needs per-user claim status.
        // Let's add a per-user claimed status mapping instead.
        mapping(uint256 => mapping(address => bool)) public projectRewardsClaimed;

        if (projectRewardsClaimed[_projectId][msg.sender]) revert RewardsAlreadyClaimed();
        if (!project.hasSubmittedWork[msg.sender]) revert NotProjectParticipant(); // Only claim if work submitted

        // Transfer the reward tokens
        uint256 tokensToClaim = projectCompletionTokenReward; // Simplified: Fixed reward per participant
        // Ensure contract has enough tokens (they should have been sent/earned previously)
        if (nexusToken.balanceOf(address(this)) < tokensToClaim) {
             // This indicates a bug in reward funding or calculation
             revert NexusUnstakeFailed(); // Reusing error, need specific one
        }

        nexusToken.safeTransfer(msg.sender, tokensToClaim);
        projectRewardsClaimed[_projectId][msg.sender] = true;

        // Note: REP was already distributed in completeProject

        emit ProjectRewardsClaimed(_projectId, msg.sender, projectCompletionRepReward, tokensToClaim);
    }

    // --- Dynamic Parameter Functions ---

    /**
     * @dev Allows Protocol Admins to update the REP thresholds required for specific capabilities.
     * @param _capabilityId The hash of the capability string ID to update.
     * @param _newThreshold The new required REP amount.
     */
    function updateReputationThresholds(bytes32 _capabilityId, uint256 _newThreshold) external onlyCapability(keccak256("ProtocolAdmin")) whenNotPaused {
        uint256 oldThreshold = capabilityRepThresholds[_capabilityId];
        capabilityRepThresholds[_capabilityId] = _newThreshold;
        emit ParameterUpdated(_capabilityId, oldThreshold, _newThreshold);
    }

    /**
     * @dev Allows Protocol Admins to update the base REP yield rate from staking.
     * (Simplified: This rate isn't used in the current staking implementation but shows the concept).
     * @param _newRatePerRepPerSecond The new rate.
     */
    function updateStakingYieldRate(uint256 _newRatePerRepPerSecond) external onlyCapability(keccak256("ProtocolAdmin")) whenNotPaused {
        uint256 oldRate = stakingYieldRatePerRepPerSecond;
        stakingYieldRatePerRepPerSecond = _newRatePerRepPerSecond;
        emit ParameterUpdated(keccak256("stakingYieldRatePerRepPerSecond"), oldRate, _newRatePerRepPerSecond);
    }

    /**
     * @dev Allows Protocol Admins to update the REP threshold required to approve/complete projects.
     * @param _newThreshold The new required REP amount.
     */
    function updateProjectApprovalThreshold(uint256 _newThreshold) external onlyCapability(keccak256("ProtocolAdmin")) whenNotPaused {
        uint256 oldThreshold = projectApprovalRepThreshold;
        projectApprovalRepThreshold = _newThreshold;
         // Update both approver and completer capabilities for consistency
        capabilityRepThresholds[keccak256("ProjectApprover")] = _newThreshold;
        capabilityRepThresholds[keccak256("ProjectCompleter")] = _newThreshold;
        emit ParameterUpdated(keccak256("projectApprovalRepThreshold"), oldThreshold, _newThreshold);
    }

    /**
     * @dev Allows Protocol Admins to update the base REP and Token rewards for projects *before* completion.
     * Note: This updates the *default* rewards for *all* future project completions,
     * or could be modified to update a specific project's rewards if needed (more complex state).
     * Let's update the global default for simplicity.
     * @param _repReward The new REP reward per participant.
     * @param _tokenReward The new Token reward per participant.
     */
    function updateProjectCompletionRewards(uint256 _repReward, uint256 _tokenReward) external onlyCapability(keccak256("ProtocolAdmin")) whenNotPaused {
        uint256 oldRepReward = projectCompletionRepReward;
        uint256 oldTokenReward = projectCompletionTokenReward;
        projectCompletionRepReward = _repReward;
        projectCompletionTokenReward = _tokenReward;
        emit ParameterUpdated(keccak256("projectCompletionRepReward"), oldRepReward, _repReward);
        emit ParameterUpdated(keccak256("projectCompletionTokenReward"), oldTokenReward, _tokenReward);
    }


    // --- Admin & Utility Functions ---

    /**
     * @dev Pauses the contract, preventing most interactions. Only callable by owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only callable by owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to withdraw any non-protocol tokens accidentally sent
     * to the contract. Prevents withdrawing NEXUS or SynergyNFT.
     * @param _tokenAddress The address of the token to withdraw.
     * @param _amount The amount to withdraw.
     */
    function withdrawAccidentalTokens(address _tokenAddress, uint256 _amount) external onlyOwner nonReentrant {
        if (_tokenAddress == address(nexusToken) || _tokenAddress == address(synergyNFTContract)) {
            revert TokenIsProtocolToken();
        }
        IERC20 accidentalToken = IERC20(_tokenAddress);
        if (accidentalToken.balanceOf(address(this)) < _amount) revert InvalidAmount(); // Not enough balance

        accidentalToken.safeTransfer(owner(), _amount);
        emit WithdrawAccidentalTokens(_tokenAddress, owner(), _amount);
    }

    /**
     * @dev Allows the owner to update the address of the NEXUS token contract. Use with extreme caution.
     * @param _newAddress The new address for the NEXUS token contract.
     */
    function setNexusToken(address _newAddress) external onlyOwner {
        if (_newAddress == address(0)) revert ZeroAddress();
        address oldAddress = address(nexusToken);
        nexusToken = IERC20(_newAddress);
        emit SetTokenAddress(oldAddress, _newAddress, "NEXUS");
    }

    /**
     * @dev Allows the owner to update the address of the Synergy NFT contract. Use with extreme caution.
     * @param _newAddress The new address for the Synergy NFT contract.
     */
    function setSynergyNFTContract(address _newAddress) external onlyOwner {
         if (_newAddress == address(0)) revert ZeroAddress();
        address oldAddress = address(synergyNFTContract);
        synergyNFTContract = IERC721(_newAddress);
        emit SetTokenAddress(oldAddress, _newAddress, "SynergyNFT");
    }

    // --- View Functions ---

    /**
     * @dev Gets the details of a specific project.
     * @param _projectId The ID of the project.
     * @return Project The project struct details.
     */
    function getProjectDetails(uint256 _projectId) external view returns (Project memory) {
        Project memory project = projects[_projectId];
        if (project.id == 0) revert ProjectNotFound(); // Check if project exists
        return project;
    }

    /**
     * @dev Gets the current number of projects created.
     * @return uint256 The next project ID (equivalent to total projects + 1).
     */
    function getNextProjectId() external view returns (uint256) {
        return _nextProjectId;
    }

    // Note: Iterating over mappings is not directly possible or gas efficient.
    // These functions demonstrate intent but would likely require off-chain indexing
    // or different storage patterns (e.g., linked lists, iterating over an array of IDs)
    // for practical use with many projects/participants. The implementations here are basic
    // and might exceed block gas limits in a real scenario.

    /**
     * @dev Gets a list of project IDs based on their status. (Potentially high gas)
     * @param _status The status to filter by.
     * @return uint256[] An array of project IDs with the given status.
     */
    function getProjectsByStatus(uint256 _status) external view returns (uint256[] memory) {
        ProjectStatus statusEnum = ProjectStatus(_status);
        uint256[] memory projectIds = new uint256[](_nextProjectId - 1); // Max possible size
        uint256 count = 0;
        for (uint i = 1; i < _nextProjectId; i++) {
            if (projects[i].status == statusEnum) {
                projectIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = projectIds[i];
        }
        return result;
    }

    /**
     * @dev Gets a list of project IDs that a participant is involved in. (Potentially high gas)
     * This implementation checks *all* projects. A better approach would be tracking participant -> project mapping.
     * @param _participant The address of the participant.
     * @return uint256[] An array of project IDs the participant is in.
     */
    function getParticipantProjects(address _participant) external view returns (uint256[] memory) {
         uint256[] memory projectIds = new uint256[](_nextProjectId - 1); // Max possible size
         uint256 count = 0;
         for (uint i = 1; i < _nextProjectId; i++) {
             Project memory project = projects[i];
             if (project.id > 0) { // Check if project exists
                 for(uint j = 0; j < project.participants.length; j++) {
                     if(project.participants[j] == _participant) {
                         projectIds[count] = i;
                         count++;
                         break; // Participant found in this project, move to next project
                     }
                 }
             }
         }
         uint256[] memory result = new uint256[](count);
         for(uint i = 0; i < count; i++) {
             result[i] = projectIds[i];
         }
         return result;
    }
}
```