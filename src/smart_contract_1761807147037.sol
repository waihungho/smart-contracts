This smart contract, `EvoAgentProtocol`, introduces a novel concept of **Adaptive Protocol Agents (EvoAgents)**. These are dynamic NFTs that represent autonomous, evolving entities within a decentralized ecosystem. EvoAgents possess mutable on-chain parameters (their "strategy" or "knowledge"), can be equipped with modular capabilities, and adapt their behavior based on community governance and reported performance outcomes. A native token (EVO) facilitates staking, rewards, and participation in the protocol's governance.

The design aims to be advanced, creative, and trendy by blending elements of:
*   **Dynamic NFTs:** EvoAgents are not static JPEGs but data-rich entities whose on-chain state can change.
*   **Decentralized Autonomous Agents (DAAs):** While not running AI on-chain, their "strategy" parameters evolve through a consensus mechanism and external oracle feedback, mimicking an adaptive learning process.
*   **Modular Architecture:** Agents can be assigned specific "modules" (e.g., for DeFi interaction, data aggregation, governance participation), allowing for extensible functionalities.
*   **Community-Driven Evolution:** Agent strategies and protocol parameters are governed by proposals and votes.
*   **Performance-Based Adaptation:** Agents' internal "efficacy scores" (impacting rewards and influence) dynamically adjust based on real-world outcomes reported by trusted oracles.

---

## EvoAgentProtocol: Outline and Function Summary

**Contract Name:** `EvoAgentProtocol`

**Core Concept:** A decentralized protocol for managing and evolving "EvoAgents" – dynamic NFTs that represent autonomous on-chain entities with mutable strategies, adaptable behaviors, and modular capabilities. Agents evolve through community proposals, votes, and performance-based adjustments, participating in various on-chain activities and earning rewards in a native token (EVO).

**Key Features:**
*   **Dynamic NFTs (EvoAgents):** ERC721-compliant NFTs with mutable on-chain parameters (`strategyParameters`) and an `efficacyScore` that adapts based on performance.
*   **Modular Capabilities:** EvoAgents can be assigned different "modules" representing specific skills or functionalities, registered and managed by the protocol.
*   **Community Governance:** A robust proposal and voting system allows the community to collectively evolve agent strategies and govern protocol-wide parameters.
*   **Adaptive Behavior:** Agents' `efficacyScore` automatically adjusts based on outcomes reported by a trusted `ORACLE_ROLE`, influencing their reward potential and potentially future actions.
*   **Native Token (EVO):** An ERC20 token used for staking, earning rewards, and participating in governance votes.
*   **Role-Based Access Control & Pausability:** Standard security measures leveraging OpenZeppelin's `AccessControl` and `Pausable` for managing permissions and mitigating risks.

---

### Function Summary:

**I. Core Protocol Management (Access Control & Pausability):**

1.  **`constructor(string memory name, string memory symbol, address initialAdmin)`:** Initializes the contract, sets up ERC721 and ERC20 tokens, and grants initial roles.
2.  **`pause()`:** Pauses all critical contract functionalities (requires `PAUSER_ROLE`).
3.  **`unpause()`:** Unpauses all critical contract functionalities (requires `PAUSER_ROLE`).
4.  **`setOracleAddress(address newOracle)`:** Updates the address of the trusted oracle (requires `DEFAULT_ADMIN_ROLE`).
5.  **`grantRole(bytes32 role, address account)`:** Grants a specified role to an account (requires `DEFAULT_ADMIN_ROLE`).
6.  **`revokeRole(bytes32 role, address account)`:** Revokes a specified role from an account (requires `DEFAULT_ADMIN_ROLE`).
7.  **`renounceRole(bytes32 role, address account)`:** Allows an account to renounce its own role.

**II. EvoAgent Management (Dynamic NFTs):**

8.  **`mintEvoAgent(address to, string memory tokenURI)`:** Mints a new EvoAgent NFT to a specified address (requires `DEFAULT_ADMIN_ROLE` or `MODULE_MANAGER_ROLE`).
9.  **`getEvoAgentDetails(uint256 agentId)`:** Retrieves all detailed information about a specific EvoAgent.
10. **`updateEvoAgentMetadataURI(uint256 agentId, string memory newTokenURI)`:** Allows the agent owner or approved operator to update the EvoAgent's metadata URI.
11. **`addAgentModule(string memory name, string memory description)`:** Registers a new type of capability module within the protocol (requires `MODULE_MANAGER_ROLE`).
12. **`removeAgentModule(uint256 moduleId)`:** Deactivates an existing agent module (requires `MODULE_MANAGER_ROLE`).
13. **`assignModuleToAgent(uint256 agentId, uint256 moduleId)`:** Assigns a registered module to an EvoAgent (requires agent owner/approved or `MODULE_MANAGER_ROLE`).
14. **`unassignModuleFromAgent(uint256 agentId, uint256 moduleId)`:** Removes an assigned module from an EvoAgent (requires agent owner/approved or `MODULE_MANAGER_ROLE`).

**III. Agent Strategy & Evolution:**

15. **`proposeAgentStrategyUpdate(uint256 agentId, bytes32[] memory paramKeys, uint256[] memory paramValues, string memory description)`:** Allows any staker of EVO tokens to propose new strategy parameters for a specific EvoAgent.
16. **`voteOnAgentStrategyUpdate(uint256 proposalId, bool support)`:** Allows EVO stakers to vote on an active agent strategy update proposal.
17. **`executeAgentStrategyUpdate(uint256 proposalId)`:** Executes the proposed strategy update if it has passed and the voting period is over (callable by anyone).
18. **`recordAgentOutcome(uint256 agentId, int256 outcomeImpact)`:** A trusted oracle reports the success or failure of an agent's action, impacting its `efficacyScore` (requires `ORACLE_ROLE`).

**IV. Native Token (EVO) & Rewards:**

19. **`_mintEVOToken(address account, uint256 amount)`:** Internal function to mint new EVO tokens (used for rewards or by admin).
20. **`claimAgentRewards(uint256 agentId)`:** Allows an EvoAgent owner to claim accumulated EVO token rewards based on the agent's efficacy.
21. **`stakeEVOToken(uint256 amount)`:** Allows users to stake EVO tokens to gain voting power and potentially earn yield.
22. **`unstakeEVOToken(uint256 amount)`:** Allows users to unstake their EVO tokens.

**V. Governance (Protocol-level):**

23. **`proposeProtocolParameterChange(bytes32 parameterKey, uint256 parameterValue, string memory description)`:** Allows any staker of EVO tokens to propose changes to core protocol parameters.
24. **`voteOnProtocolParameterChange(uint256 proposalId, bool support)`:** Allows EVO stakers to vote on an active protocol parameter change proposal.
25. **`executeProtocolParameterChange(uint256 proposalId)`:** Executes a protocol parameter change if the proposal has passed and the voting period is over (callable by anyone).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title EvoAgentProtocol: Adaptive Protocol Agents Factory
/// @author Your Name / AI Assistant
/// @notice This contract introduces a novel concept of "Adaptive Protocol Agents" (EvoAgents).
///         These are dynamic NFTs that represent autonomous, evolving entities within a decentralized ecosystem.
///         EvoAgents possess mutable on-chain parameters (their "strategy" or "knowledge"),
///         can be equipped with modular capabilities, and adapt their behavior based on community governance
///         and reported performance outcomes. A native token (EVO) facilitates staking, rewards, and
///         participation in the protocol's governance.
///
///         The design blends elements of:
///         - Dynamic NFTs: EvoAgents are not static JPEGs but data-rich entities whose on-chain state can change.
///         - Decentralized Autonomous Agents (DAAs): Their "strategy" parameters evolve through consensus and oracle feedback.
///         - Modular Architecture: Agents can be assigned specific "modules" for extensible functionalities.
///         - Community-Driven Evolution: Agent strategies and protocol parameters are governed by proposals and votes.
///         - Performance-Based Adaptation: Agents' internal "efficacy scores" adjust based on real-world outcomes.

/// EvoAgentProtocol: Outline and Function Summary
///
/// Contract Name: EvoAgentProtocol
///
/// Core Concept: A decentralized protocol for managing and evolving "EvoAgents" – dynamic NFTs that represent
/// autonomous on-chain entities with mutable strategies, adaptable behaviors, and modular capabilities.
/// Agents evolve through community proposals, votes, and performance-based adjustments, participating in various
/// on-chain activities and earning rewards in a native token (EVO).
///
/// Key Features:
/// - Dynamic NFTs (EvoAgents): ERC721-compliant NFTs with mutable on-chain parameters (`strategyParameters`)
///   and an `efficacyScore` that adapts based on performance.
/// - Modular Capabilities: EvoAgents can be assigned different "modules" representing specific skills or functionalities,
///   registered and managed by the protocol.
/// - Community Governance: A robust proposal and voting system allows the community to collectively evolve
///   agent strategies and govern protocol-wide parameters.
/// - Adaptive Behavior: Agents' `efficacyScore` automatically adjusts based on outcomes reported by a trusted `ORACLE_ROLE`,
///   influencing their reward potential and potentially future actions.
/// - Native Token (EVO): An ERC20 token used for staking, earning rewards, and participating in governance votes.
/// - Role-Based Access Control & Pausability: Standard security measures leveraging OpenZeppelin's `AccessControl`
///   and `Pausable` for managing permissions and mitigating risks.
///
/// ---
///
/// Function Summary:
///
/// I. Core Protocol Management (Access Control & Pausability):
/// 1.  constructor(string memory name, string memory symbol, address initialAdmin)
/// 2.  pause()
/// 3.  unpause()
/// 4.  setOracleAddress(address newOracle)
/// 5.  grantRole(bytes32 role, address account)
/// 6.  revokeRole(bytes32 role, address account)
/// 7.  renounceRole(bytes32 role, address account)
///
/// II. EvoAgent Management (Dynamic NFTs):
/// 8.  mintEvoAgent(address to, string memory tokenURI)
/// 9.  getEvoAgentDetails(uint256 agentId)
/// 10. updateEvoAgentMetadataURI(uint256 agentId, string memory newTokenURI)
/// 11. addAgentModule(string memory name, string memory description)
/// 12. removeAgentModule(uint256 moduleId)
/// 13. assignModuleToAgent(uint256 agentId, uint256 moduleId)
/// 14. unassignModuleFromAgent(uint256 agentId, uint256 moduleId)
///
/// III. Agent Strategy & Evolution:
/// 15. proposeAgentStrategyUpdate(uint256 agentId, bytes32[] memory paramKeys, uint256[] memory paramValues, string memory description)
/// 16. voteOnAgentStrategyUpdate(uint256 proposalId, bool support)
/// 17. executeAgentStrategyUpdate(uint256 proposalId)
/// 18. recordAgentOutcome(uint256 agentId, int256 outcomeImpact)
///
/// IV. Native Token (EVO) & Rewards:
/// 19. _mintEVOToken(address account, uint256 amount) - Internal
/// 20. claimAgentRewards(uint256 agentId)
/// 21. stakeEVOToken(uint256 amount)
/// 22. unstakeEVOToken(uint256 amount)
///
/// V. Governance (Protocol-level):
/// 23. proposeProtocolParameterChange(bytes32 parameterKey, uint256 parameterValue, string memory description)
/// 24. voteOnProtocolParameterChange(uint256 proposalId, bool support)
/// 25. executeProtocolParameterChange(uint256 proposalId)

contract EvoAgentProtocol is ERC721Enumerable, ERC20, AccessControl, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables & Constants ---

    // Roles
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant MODULE_MANAGER_ROLE = keccak256("MODULE_MANAGER_ROLE");

    // EvoAgent Data Structure
    struct EvoAgent {
        address owner;
        string uri; // Metadata URI for the NFT
        uint256 creationBlock;
        int256 efficacyScore; // Reflects performance, affects rewards and potential influence
        mapping(bytes32 => uint256) strategyParameters; // Dynamic on-chain strategy parameters
        mapping(uint256 => bool) assignedModules; // Module ID => assigned status
        uint256 accumulatedRewards; // EVO tokens accumulated for this agent
    }

    // Agent Module Data Structure
    struct AgentModule {
        string name;
        string description;
        bool active;
    }

    // Governance Proposal Data Structure
    enum ProposalType { AgentStrategy, ProtocolParameter }

    struct Proposal {
        uint256 id;
        ProposalType pType;
        address proposer;
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        // Target specific data for agent strategy proposals
        uint256 targetAgentId;
        bytes32[] paramKeys;
        uint256[] paramValues;
        // Target specific data for protocol parameter proposals
        bytes32 targetParameterKey;
        uint256 targetParameterValue;
    }

    // Counters for unique IDs
    Counters.Counter private _agentIds;
    Counters.Counter private _moduleIds;
    Counters.Counter private _proposalIds;

    // Mappings for storing data
    mapping(uint256 => EvoAgent) public evoAgents;
    mapping(uint256 => AgentModule) public agentModules;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public stakedEVOTokens;
    mapping(uint256 => mapping(address => bool)) public proposalVoters; // proposalId => voter => hasVoted

    // Protocol configuration parameters (can be changed via governance proposals)
    mapping(bytes32 => uint256) public protocolParameters;
    bytes32 public constant MIN_VOTING_POWER_FOR_PROPOSAL_KEY = keccak256("MIN_VOTING_POWER_FOR_PROPOSAL");
    bytes32 public constant VOTING_PERIOD_BLOCKS_KEY = keccak256("VOTING_PERIOD_BLOCKS");
    bytes32 public constant EVO_REWARD_PER_POINT_KEY = keccak256("EVO_REWARD_PER_POINT");
    bytes32 public constant EVO_MINT_CAP_PER_YEAR_KEY = keccak256("EVO_MINT_CAP_PER_YEAR");

    // Trusted oracle address
    address public oracleAddress;

    // EVO Token specific details
    string private _evoTokenName;
    string private _evoTokenSymbol;

    // --- Events ---

    event AgentMinted(uint256 indexed agentId, address indexed owner, string tokenURI);
    event AgentMetadataUpdated(uint256 indexed agentId, string newTokenURI);
    event ModuleAdded(uint256 indexed moduleId, string name, string description);
    event ModuleRemoved(uint256 indexed moduleId, string name);
    event ModuleAssigned(uint256 indexed agentId, uint256 indexed moduleId);
    event ModuleUnassigned(uint256 indexed agentId, uint256 indexed moduleId);
    event AgentEfficacyUpdated(uint256 indexed agentId, int256 oldScore, int256 newScore, int256 impact);

    event ProposalCreated(uint256 indexed proposalId, ProposalType pType, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    event RewardsClaimed(uint256 indexed agentId, address indexed owner, uint256 amount);
    event TokenStaked(address indexed staker, uint256 amount);
    event TokenUnstaked(address indexed staker, uint256 amount);

    // --- Errors ---

    error InvalidAgentId(uint256 agentId);
    error Unauthorized(address caller);
    error NotAgentOwnerOrApproved(address caller, uint256 agentId);
    error ModuleNotFound(uint256 moduleId);
    error ModuleNotAssigned(uint256 agentId, uint256 moduleId);
    error ModuleAlreadyAssigned(uint256 agentId, uint256 moduleId);
    error ProposalVotingPeriodNotActive(uint256 proposalId);
    error ProposalVotingPeriodExpired(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalNotApproved(uint256 proposalId);
    error AlreadyVoted(address voter, uint256 proposalId);
    error InsufficientVotingPower(address voter, uint256 required, uint256 available);
    error InvalidProposalParams();
    error ZeroAmount();
    error NotEnoughStakedTokens(address staker, uint256 requested, uint256 available);
    error MaxEvoMintReached();

    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        address initialAdmin
    )
        ERC721(name, symbol)
        ERC20("EvoToken", "EVO") // Native token for governance and rewards
        Pausable()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(PAUSER_ROLE, initialAdmin);
        _grantRole(MODULE_MANAGER_ROLE, initialAdmin); // Admin also manages modules initially
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ORACLE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MODULE_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);

        // Initialize default protocol parameters
        protocolParameters[MIN_VOTING_POWER_FOR_PROPOSAL_KEY] = 1000 ether; // 1000 EVO to propose
        protocolParameters[VOTING_PERIOD_BLOCKS_KEY] = 10000; // Approx 1.5 days on Ethereum
        protocolParameters[EVO_REWARD_PER_POINT_KEY] = 1 ether; // 1 EVO per efficacy point
        protocolParameters[EVO_MINT_CAP_PER_YEAR_KEY] = 1_000_000 ether; // 1M EVO per year cap
    }

    // --- I. Core Protocol Management (Access Control & Pausability) ---

    /// @dev Pauses all critical contract functionalities.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @dev Unpauses all critical contract functionalities.
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @dev Sets the address of the trusted oracle. Only callable by DEFAULT_ADMIN_ROLE.
    /// @param newOracle The address of the new oracle.
    function setOracleAddress(address newOracle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        oracleAddress = newOracle;
    }

    /// @dev Grants a role to an account. Only callable by DEFAULT_ADMIN_ROLE.
    /// @param role The role to grant.
    /// @param account The address to grant the role to.
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.grantRole(role, account);
    }

    /// @dev Revokes a role from an account. Only callable by DEFAULT_ADMIN_ROLE.
    /// @param role The role to revoke.
    /// @param account The address to revoke the role from.
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.revokeRole(role, account);
    }

    /// @dev Allows an account to renounce its own role.
    /// @param role The role to renounce.
    /// @param account The address renouncing the role (must be msg.sender).
    function renounceRole(bytes32 role, address account) public override {
        super.renounceRole(role, account);
    }

    // --- II. EvoAgent Management (Dynamic NFTs) ---

    /// @dev Mints a new EvoAgent NFT to a specified address.
    /// @param to The recipient of the new EvoAgent.
    /// @param tokenURI The metadata URI for the EvoAgent.
    /// @return The ID of the newly minted EvoAgent.
    function mintEvoAgent(address to, string memory tokenURI)
        public
        whenNotPaused
        onlyRole(MODULE_MANAGER_ROLE) // Only a dedicated manager or admin can mint new agents
        returns (uint256)
    {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        _safeMint(to, newAgentId);
        _setTokenURI(newAgentId, tokenURI);

        EvoAgent storage newAgent = evoAgents[newAgentId];
        newAgent.owner = to;
        newAgent.uri = tokenURI;
        newAgent.creationBlock = block.number;
        newAgent.efficacyScore = 0; // Start with neutral efficacy
        newAgent.accumulatedRewards = 0;

        emit AgentMinted(newAgentId, to, tokenURI);
        return newAgentId;
    }

    /// @dev Retrieves all detailed information about a specific EvoAgent.
    /// @param agentId The ID of the EvoAgent.
    /// @return owner The owner's address.
    /// @return uri The metadata URI.
    /// @return creationBlock The block number when it was created.
    /// @return efficacyScore The current efficacy score.
    /// @return accumulatedRewards The rewards accumulated.
    /// @dev Note: `strategyParameters` and `assignedModules` are mappings and cannot be returned directly.
    ///      Individual getters would be needed for specific parameters/modules.
    function getEvoAgentDetails(uint256 agentId)
        public
        view
        returns (
            address owner,
            string memory uri,
            uint256 creationBlock,
            int256 efficacyScore,
            uint256 accumulatedRewards
        )
    {
        if (ownerOf(agentId) == address(0)) {
            revert InvalidAgentId(agentId);
        }
        EvoAgent storage agent = evoAgents[agentId];
        return (agent.owner, agent.uri, agent.creationBlock, agent.efficacyScore, agent.accumulatedRewards);
    }

    /// @dev Allows the EvoAgent owner or approved operator to update the agent's metadata URI.
    /// @param agentId The ID of the EvoAgent.
    /// @param newTokenURI The new metadata URI.
    function updateEvoAgentMetadataURI(uint256 agentId, string memory newTokenURI) public whenNotPaused {
        if (ownerOf(agentId) != _msgSender() && !isApprovedForAll(ownerOf(agentId), _msgSender())) {
            revert NotAgentOwnerOrApproved(_msgSender(), agentId);
        }
        if (ownerOf(agentId) == address(0)) {
            revert InvalidAgentId(agentId);
        }

        evoAgents[agentId].uri = newTokenURI;
        _setTokenURI(agentId, newTokenURI); // Update ERC721 internal URI as well
        emit AgentMetadataUpdated(agentId, newTokenURI);
    }

    /// @dev Registers a new type of capability module within the protocol.
    ///      Only callable by MODULE_MANAGER_ROLE.
    /// @param name The name of the module (e.g., "DeFi Trader", "Data Collector").
    /// @param description A brief description of the module's function.
    /// @return The ID of the newly added module.
    function addAgentModule(string memory name, string memory description)
        public
        whenNotPaused
        onlyRole(MODULE_MANAGER_ROLE)
        returns (uint256)
    {
        _moduleIds.increment();
        uint256 newModuleId = _moduleIds.current();

        agentModules[newModuleId] = AgentModule({name: name, description: description, active: true});
        emit ModuleAdded(newModuleId, name, description);
        return newModuleId;
    }

    /// @dev Deactivates an existing agent module, preventing it from being assigned to new agents.
    ///      Agents already assigned this module will retain it unless unassigned.
    /// @param moduleId The ID of the module to remove.
    function removeAgentModule(uint256 moduleId) public whenNotPaused onlyRole(MODULE_MANAGER_ROLE) {
        if (agentModules[moduleId].active == false) {
            revert ModuleNotFound(moduleId); // Assuming inactive is equivalent to not found for removal intent
        }
        agentModules[moduleId].active = false;
        emit ModuleRemoved(moduleId, agentModules[moduleId].name);
    }

    /// @dev Assigns a registered module to an EvoAgent.
    /// @param agentId The ID of the EvoAgent.
    /// @param moduleId The ID of the module to assign.
    function assignModuleToAgent(uint256 agentId, uint256 moduleId) public whenNotPaused {
        if (ownerOf(agentId) == address(0)) {
            revert InvalidAgentId(agentId);
        }
        if (!hasRole(MODULE_MANAGER_ROLE, _msgSender()) && ownerOf(agentId) != _msgSender() && !isApprovedForAll(ownerOf(agentId), _msgSender())) {
            revert NotAgentOwnerOrApproved(_msgSender(), agentId);
        }
        if (agentModules[moduleId].active == false) {
            revert ModuleNotFound(moduleId);
        }
        if (evoAgents[agentId].assignedModules[moduleId]) {
            revert ModuleAlreadyAssigned(agentId, moduleId);
        }

        evoAgents[agentId].assignedModules[moduleId] = true;
        emit ModuleAssigned(agentId, moduleId);
    }

    /// @dev Removes an assigned module from an EvoAgent.
    /// @param agentId The ID of the EvoAgent.
    /// @param moduleId The ID of the module to unassign.
    function unassignModuleFromAgent(uint256 agentId, uint256 moduleId) public whenNotPaused {
        if (ownerOf(agentId) == address(0)) {
            revert InvalidAgentId(agentId);
        }
        if (!hasRole(MODULE_MANAGER_ROLE, _msgSender()) && ownerOf(agentId) != _msgSender() && !isApprovedForAll(ownerOf(agentId), _msgSender())) {
            revert NotAgentOwnerOrApproved(_msgSender(), agentId);
        }
        if (agentModules[moduleId].active == false) {
            revert ModuleNotFound(moduleId); // Should check if it was ever active/existed
        }
        if (!evoAgents[agentId].assignedModules[moduleId]) {
            revert ModuleNotAssigned(agentId, moduleId);
        }

        evoAgents[agentId].assignedModules[moduleId] = false;
        emit ModuleUnassigned(agentId, moduleId);
    }

    // --- III. Agent Strategy & Evolution ---

    /// @dev Allows any staker of EVO tokens to propose new strategy parameters for a specific EvoAgent.
    /// @param agentId The ID of the EvoAgent to update.
    /// @param paramKeys An array of keys for the strategy parameters.
    /// @param paramValues An array of values for the strategy parameters (must match keys in length).
    /// @param description A brief description of the proposed strategy update.
    /// @return The ID of the newly created proposal.
    function proposeAgentStrategyUpdate(
        uint256 agentId,
        bytes32[] memory paramKeys,
        uint256[] memory paramValues,
        string memory description
    ) public whenNotPaused returns (uint256) {
        if (stakedEVOTokens[_msgSender()] < protocolParameters[MIN_VOTING_POWER_FOR_PROPOSAL_KEY]) {
            revert InsufficientVotingPower(_msgSender(), protocolParameters[MIN_VOTING_POWER_FOR_PROPOSAL_KEY], stakedEVOTokens[_msgSender()]);
        }
        if (ownerOf(agentId) == address(0)) {
            revert InvalidAgentId(agentId);
        }
        if (paramKeys.length == 0 || paramKeys.length != paramValues.length) {
            revert InvalidProposalParams();
        }

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            pType: ProposalType.AgentStrategy,
            proposer: _msgSender(),
            description: description,
            startBlock: block.number,
            endBlock: block.number + protocolParameters[VOTING_PERIOD_BLOCKS_KEY],
            yayVotes: 0,
            nayVotes: 0,
            executed: false,
            targetAgentId: agentId,
            paramKeys: paramKeys,
            paramValues: paramValues,
            targetParameterKey: bytes32(0), // Not applicable for agent strategy
            targetParameterValue: 0 // Not applicable for agent strategy
        });

        emit ProposalCreated(newProposalId, ProposalType.AgentStrategy, _msgSender(), description);
        return newProposalId;
    }

    /// @dev Allows EVO stakers to vote on an active agent strategy update proposal.
    /// @param proposalId The ID of the proposal.
    /// @param support True for "yay" vote, false for "nay" vote.
    function voteOnAgentStrategyUpdate(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.pType != ProposalType.AgentStrategy) {
            revert InvalidProposalParams(); // Only for agent strategy proposals
        }
        if (proposal.startBlock == 0 || proposal.executed) { // Check if proposal exists and is not executed
            revert ProposalVotingPeriodNotActive(proposalId);
        }
        if (block.number > proposal.endBlock) {
            revert ProposalVotingPeriodExpired(proposalId);
        }
        if (proposalVoters[proposalId][_msgSender()]) {
            revert AlreadyVoted(_msgSender(), proposalId);
        }

        uint256 votingPower = stakedEVOTokens[_msgSender()];
        if (votingPower == 0) {
            revert InsufficientVotingPower(_msgSender(), 1, 0); // Need at least 1 staked EVO to vote
        }

        if (support) {
            proposal.yayVotes = proposal.yayVotes.add(votingPower);
        } else {
            proposal.nayVotes = proposal.nayVotes.add(votingPower);
        }
        proposalVoters[proposalId][_msgSender()] = true;

        emit VoteCast(proposalId, _msgSender(), support, votingPower);
    }

    /// @dev Executes the proposed agent strategy update if it has passed and the voting period is over.
    ///      Anyone can call this function.
    /// @param proposalId The ID of the proposal to execute.
    function executeAgentStrategyUpdate(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.pType != ProposalType.AgentStrategy) {
            revert InvalidProposalParams();
        }
        if (proposal.executed) {
            revert ProposalAlreadyExecuted(proposalId);
        }
        if (block.number <= proposal.endBlock) {
            revert ProposalVotingPeriodNotActive(proposalId); // Voting period must be over
        }
        if (proposal.yayVotes <= proposal.nayVotes) { // Simple majority rule
            revert ProposalNotApproved(proposalId);
        }
        if (ownerOf(proposal.targetAgentId) == address(0)) {
            revert InvalidAgentId(proposal.targetAgentId); // Target agent might have been burned
        }

        EvoAgent storage agent = evoAgents[proposal.targetAgentId];
        for (uint256 i = 0; i < proposal.paramKeys.length; i++) {
            agent.strategyParameters[proposal.paramKeys[i]] = proposal.paramValues[i];
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId, true);
    }

    /// @dev A trusted oracle reports the success or failure of an agent's action, impacting its efficacyScore.
    ///      Only callable by the ORACLE_ROLE.
    /// @param agentId The ID of the EvoAgent whose outcome is being reported.
    /// @param outcomeImpact The integer value representing the impact on efficacy (e.g., +10 for success, -5 for failure).
    function recordAgentOutcome(uint256 agentId, int256 outcomeImpact) public whenNotPaused onlyRole(ORACLE_ROLE) {
        if (ownerOf(agentId) == address(0)) {
            revert InvalidAgentId(agentId);
        }
        EvoAgent storage agent = evoAgents[agentId];
        int256 oldScore = agent.efficacyScore;
        agent.efficacyScore = agent.efficacyScore + outcomeImpact;

        // Rewards accrue based on current efficacy score
        if (outcomeImpact > 0) {
            agent.accumulatedRewards = agent.accumulatedRewards.add(uint256(outcomeImpact).mul(protocolParameters[EVO_REWARD_PER_POINT_KEY]));
        }

        emit AgentEfficacyUpdated(agentId, oldScore, agent.efficacyScore, outcomeImpact);
    }

    // --- IV. Native Token (EVO) & Rewards ---

    /// @dev Internal function to mint new EVO tokens.
    ///      Can only be called by functions within this contract, typically for rewards or by admin.
    /// @param account The recipient of the new EVO tokens.
    /// @param amount The amount of EVO tokens to mint.
    function _mintEVOToken(address account, uint256 amount) internal {
        if (amount == 0) {
            revert ZeroAmount();
        }
        // Basic cap check (more sophisticated cap mechanism needed for production)
        if (totalSupply().add(amount) > protocolParameters[EVO_MINT_CAP_PER_YEAR_KEY]) {
            revert MaxEvoMintReached();
        }
        _mint(account, amount);
    }

    /// @dev Allows an EvoAgent owner to claim accumulated EVO token rewards based on the agent's efficacy.
    /// @param agentId The ID of the EvoAgent.
    function claimAgentRewards(uint256 agentId) public whenNotPaused {
        if (ownerOf(agentId) != _msgSender()) {
            revert NotAgentOwnerOrApproved(_msgSender(), agentId);
        }
        EvoAgent storage agent = evoAgents[agentId];
        uint256 rewards = agent.accumulatedRewards;

        if (rewards == 0) {
            revert ZeroAmount();
        }

        agent.accumulatedRewards = 0; // Reset rewards
        _mintEVOToken(_msgSender(), rewards); // Mint rewards to agent owner

        emit RewardsClaimed(agentId, _msgSender(), rewards);
    }

    /// @dev Allows users to stake EVO tokens to gain voting power and potentially earn yield.
    /// @param amount The amount of EVO tokens to stake.
    function stakeEVOToken(uint256 amount) public whenNotPaused {
        if (amount == 0) {
            revert ZeroAmount();
        }
        _transfer(_msgSender(), address(this), amount); // Transfer EVO to contract
        stakedEVOTokens[_msgSender()] = stakedEVOTokens[_msgSender()].add(amount);
        emit TokenStaked(_msgSender(), amount);
    }

    /// @dev Allows users to unstake their EVO tokens.
    /// @param amount The amount of EVO tokens to unstake.
    function unstakeEVOToken(uint256 amount) public whenNotPaused {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (stakedEVOTokens[_msgSender()] < amount) {
            revert NotEnoughStakedTokens(_msgSender(), amount, stakedEVOTokens[_msgSender()]);
        }
        stakedEVOTokens[_msgSender()] = stakedEVOTokens[_msgSender()].sub(amount);
        _transfer(address(this), _msgSender(), amount); // Transfer EVO back to staker
        emit TokenUnstaked(_msgSender(), amount);
    }

    // --- V. Governance (Protocol-level) ---

    /// @dev Allows any staker of EVO tokens to propose changes to core protocol parameters.
    /// @param parameterKey The keccak256 hash of the parameter name (e.g., MIN_VOTING_POWER_FOR_PROPOSAL_KEY).
    /// @param parameterValue The new value for the parameter.
    /// @param description A brief description of the proposed parameter change.
    /// @return The ID of the newly created proposal.
    function proposeProtocolParameterChange(
        bytes32 parameterKey,
        uint256 parameterValue,
        string memory description
    ) public whenNotPaused returns (uint256) {
        if (stakedEVOTokens[_msgSender()] < protocolParameters[MIN_VOTING_POWER_FOR_PROPOSAL_KEY]) {
            revert InsufficientVotingPower(_msgSender(), protocolParameters[MIN_VOTING_POWER_FOR_PROPOSAL_KEY], stakedEVOTokens[_msgSender()]);
        }
        // Basic validation for critical parameters
        if (parameterKey == VOTING_PERIOD_BLOCKS_KEY && parameterValue == 0) {
            revert InvalidProposalParams();
        }

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            pType: ProposalType.ProtocolParameter,
            proposer: _msgSender(),
            description: description,
            startBlock: block.number,
            endBlock: block.number + protocolParameters[VOTING_PERIOD_BLOCKS_KEY],
            yayVotes: 0,
            nayVotes: 0,
            executed: false,
            targetAgentId: 0, // Not applicable for protocol parameter
            paramKeys: new bytes32[](0), // Not applicable
            paramValues: new uint256[](0), // Not applicable
            targetParameterKey: parameterKey,
            targetParameterValue: parameterValue
        });

        emit ProposalCreated(newProposalId, ProposalType.ProtocolParameter, _msgSender(), description);
        return newProposalId;
    }

    /// @dev Allows EVO stakers to vote on an active protocol parameter change proposal.
    /// @param proposalId The ID of the proposal.
    /// @param support True for "yay" vote, false for "nay" vote.
    function voteOnProtocolParameterChange(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.pType != ProposalType.ProtocolParameter) {
            revert InvalidProposalParams(); // Only for protocol parameter proposals
        }
        if (proposal.startBlock == 0 || proposal.executed) {
            revert ProposalVotingPeriodNotActive(proposalId);
        }
        if (block.number > proposal.endBlock) {
            revert ProposalVotingPeriodExpired(proposalId);
        }
        if (proposalVoters[proposalId][_msgSender()]) {
            revert AlreadyVoted(_msgSender(), proposalId);
        }

        uint256 votingPower = stakedEVOTokens[_msgSender()];
        if (votingPower == 0) {
            revert InsufficientVotingPower(_msgSender(), 1, 0);
        }

        if (support) {
            proposal.yayVotes = proposal.yayVotes.add(votingPower);
        } else {
            proposal.nayVotes = proposal.nayVotes.sub(votingPower);
        }
        proposalVoters[proposalId][_msgSender()] = true;

        emit VoteCast(proposalId, _msgSender(), support, votingPower);
    }

    /// @dev Executes a protocol parameter change if the proposal has passed and the voting period is over.
    ///      Anyone can call this function.
    /// @param proposalId The ID of the proposal to execute.
    function executeProtocolParameterChange(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.pType != ProposalType.ProtocolParameter) {
            revert InvalidProposalParams();
        }
        if (proposal.executed) {
            revert ProposalAlreadyExecuted(proposalId);
        }
        if (block.number <= proposal.endBlock) {
            revert ProposalVotingPeriodNotActive(proposalId);
        }
        if (proposal.yayVotes <= proposal.nayVotes) {
            revert ProposalNotApproved(proposalId);
        }

        protocolParameters[proposal.targetParameterKey] = proposal.targetParameterValue;

        proposal.executed = true;
        emit ProposalExecuted(proposalId, true);
    }

    // --- ERC721 & ERC20 Overrides ---

    function _approve(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._approve(to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._burn(tokenId);
        // Optional: clear agent data or re-assign
        // delete evoAgents[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override(ERC721, ERC721Enumerable) {
        super._setTokenURI(tokenId, _tokenURI);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from == address(0)) { // Mint
            evoAgents[tokenId].owner = to;
        } else if (to == address(0)) { // Burn
            // Optional: Handle logic for burning (e.g., clear rewards, remove from mappings)
        } else { // Transfer
            evoAgents[tokenId].owner = to;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ERC20 overrides (not strictly necessary as inherited, but good for clarity if custom logic was added)
    function _transfer(address from, address to, uint256 amount) internal override(ERC20) {
        super._transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal override(ERC20) {
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20) {
        super._burn(account, amount);
    }

    // Custom getters for specific EvoAgent strategy parameters and assigned modules
    function getAgentStrategyParameter(uint256 agentId, bytes32 paramKey) public view returns (uint256) {
        if (ownerOf(agentId) == address(0)) {
            revert InvalidAgentId(agentId);
        }
        return evoAgents[agentId].strategyParameters[paramKey];
    }

    function isModuleAssignedToAgent(uint256 agentId, uint256 moduleId) public view returns (bool) {
        if (ownerOf(agentId) == address(0)) {
            revert InvalidAgentId(agentId);
        }
        if (agentModules[moduleId].active == false) { // Module might not exist or be inactive
            return false;
        }
        return evoAgents[agentId].assignedModules[moduleId];
    }

    function getModuleDetails(uint256 moduleId) public view returns (string memory name, string memory description, bool active) {
        if (agentModules[moduleId].active == false && bytes(agentModules[moduleId].name).length == 0) { // Check for non-existent module
             revert ModuleNotFound(moduleId);
        }
        AgentModule storage module = agentModules[moduleId];
        return (module.name, module.description, module.active);
    }
}
```