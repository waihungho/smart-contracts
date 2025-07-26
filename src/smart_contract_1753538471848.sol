This smart contract, "AetherMind Nexus," envisions a decentralized ecosystem where "Sentient Data Agents" (SDAs) powered by off-chain AI models actively curate, analyze, and predict real-world data. These agents are dynamic NFTs whose traits evolve based on their performance and interaction. Their validated insights then influence the "Catalyst Spheres," which are also dynamic NFTs, representing aggregated knowledge and potential. The entire system is governed by a robust DAO, funded by a native utility token.

**Core Concepts & Advanced Features:**

1.  **Sentient Data Agents (SDAs):**
    *   **Dynamic NFTs (ERC721):** Agents possess evolving `traits` (e.g., analytical prowess, prediction accuracy) that change based on their performance and upgrades.
    *   **Resource Management:** Agents consume `energy` to perform actions (submit insights) and can be recharged.
    *   **Reputation System:** A `reputation` score tracks an agent's historical accuracy and contributes to its influence and rewards.
    *   **AI-Augmented Data Processing (Off-chain/On-chain Validation):** Agents submit data insights (derived from off-chain AI), which are then verified by a decentralized oracle network. Accurate insights earn rewards and boost reputation.
    *   **Delegation:** Agent owners can delegate their agents to "operators" for active participation, sharing rewards.

2.  **Catalyst Spheres:**
    *   **Dynamic NFTs (ERC721):** Represent the distilled wisdom or predictive output derived from validated SDA insights. Their metadata (visuals, statistics) change over time based on the quality and quantity of insights they're associated with.
    *   **Insight Influence:** New, high-reputation insights can "charge" or "update" Catalyst Spheres, influencing their properties.
    *   **Fusion & Dissolution:** Spheres can be combined (fused) to create more powerful ones, or dissolved to recover some resources.
    *   **Staking:** Catalyst Spheres can be staked to earn passive rewards or gain governance power.

3.  **AETHER Token (ERC20):**
    *   The native utility token for the ecosystem.
    *   Used to mint agents, recharge energy, upgrade traits, fuse spheres, and pay for oracle services.
    *   Distributed as rewards for accurate insights and staking.

4.  **Decentralized Autonomous Organization (DAO):**
    *   Governs core protocol parameters, upgrades, and treasury management.
    *   Proposals, voting, and execution phases.

5.  **Decentralized Oracle Integration:**
    *   A conceptual `IOracle` interface is used for external services to verify SDA insights, acting as the bridge for off-chain AI computations to influence on-chain state.

---

## Contract Outline & Function Summary

**Contract Name:** `AetherMindNexus`

**Core Components:**
*   `IAETHER`: Interface for the AETHER ERC20 token.
*   `IOracle`: Interface for the decentralized insight verification oracle.
*   `SentientAgent`: Struct for SDA details.
*   `CatalystSphere`: Struct for Catalyst Sphere details.
*   `InsightSubmission`: Struct for pending insight validations.
*   `Proposal`: Struct for DAO proposals.

**Access Control:**
*   `Ownable` (for initial deployment and critical admin functions before full DAO handover).
*   `Pausable`.
*   DAO for most configuration changes.

---

### Function Summary (Total: 25 Functions)

**I. Core Infrastructure & Configuration (Admin/DAO controlled)**
1.  `constructor()`: Initializes the contract with AETHER token and initial oracle addresses.
2.  `setAetherTokenAddress(address _aetherToken)`: Sets the address of the AETHER ERC20 token.
3.  `setOracleAddress(address _oracleAddress)`: Sets the address of the trusted oracle network.
4.  `pause()`: Pauses core contract functionalities in emergencies.
5.  `unpause()`: Unpauses the contract.
6.  `emergencyWithdraw(address _tokenAddress)`: Allows owner to withdraw stuck tokens in emergencies.
7.  `setAgentConfig(uint256 _mintCost, uint256 _baseEnergyCost, uint256 _maxTraits)`: Updates configuration parameters for Sentient Agents.

**II. Sentient Data Agent (SDA) Management (ERC721 Logic)**
8.  `mintSentientAgent(string calldata _initialTraitsURI)`: Mints a new Sentient Data Agent NFT for the caller, consuming AETHER.
9.  `submitDataInsight(uint256 _agentId, string calldata _dataHash, uint256 _predictionValue)`: An agent submits a data insight, consuming energy. Triggers off-chain verification.
10. `verifyInsightResult(uint256 _agentId, uint256 _insightId, bool _isAccurate, uint256 _insightInfluenceFactor)`: Called by the oracle to validate an insight, awarding reputation and energy, and influencing Catalyst Spheres.
11. `upgradeAgentTrait(uint256 _agentId, uint8 _traitIndex, uint256 _costMultiplier)`: Upgrades a specific trait of an agent, consuming AETHER and agent energy.
12. `rechargeAgentEnergy(uint256 _agentId, uint256 _amount)`: Allows an agent owner to recharge its energy using AETHER.
13. `delegateAgent(uint256 _agentId, address _delegatee)`: Delegates operational control of an agent to another address.
14. `recallDelegatedAgent(uint256 _agentId)`: Recalls delegation of an agent.
15. `burnAgent(uint256 _agentId)`: Allows an owner to burn their agent, potentially recovering some resources or for network health.

**III. Catalyst Sphere Management (ERC721 Logic)**
16. `mintCatalystSphere(uint256[] calldata _contributingAgentIds, string calldata _initialMetadataURI)`: Mints a new Catalyst Sphere based on contributions from validated agents.
17. `updateCatalystMetadata(uint256 _sphereId, string calldata _newMetadataURI)`: Allows the oracle (or a high-reputation agent) to update a Catalyst Sphere's metadata based on new insights.
18. `fuseCatalystSpheres(uint256 _sphere1Id, uint256 _sphere2Id, string calldata _fusedMetadataURI)`: Combines two Catalyst Spheres into a new, potentially more powerful one, consuming AETHER.
19. `stakeCatalystSphere(uint256 _sphereId)`: Stakes a Catalyst Sphere to earn passive rewards and potential governance weight.
20. `unstakeCatalystSphere(uint256 _sphereId)`: Unstakes a Catalyst Sphere.
21. `dissolveCatalystSphere(uint256 _sphereId)`: Dissolves a Catalyst Sphere, potentially recovering some resources or for burning.

**IV. Tokenomics & Rewards**
22. `claimAgentRewards(uint256 _agentId)`: Allows an agent owner (or delegatee) to claim accumulated AETHER rewards for validated insights.
23. `claimStakingRewards(uint256 _sphereId)`: Allows a Catalyst Sphere staker to claim AETHER rewards.

**V. DAO Governance**
24. `proposeConfigChange(string calldata _description, address _target, bytes calldata _callData)`: Allows AETHER token holders to propose a configuration change or action.
25. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows AETHER token holders to vote on an active proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Interfaces ---

/// @title IAETHER Token Interface
/// @notice Defines the necessary functions for interaction with the AETHER ERC20 token.
interface IAETHER is IERC20 {
    // Aether token specific functions can be added here if needed, beyond basic ERC20
}

/// @title IOracle Interface
/// @notice Defines the interface for the decentralized oracle network responsible for verifying data insights.
interface IOracle {
    /// @notice A function the oracle would call back to the AetherMindNexus to verify an insight.
    /// @param _agentId The ID of the Sentient Data Agent.
    /// @param _insightId The specific ID of the submitted insight.
    /// @param _isAccurate True if the insight was verified as accurate, false otherwise.
    /// @param _insightInfluenceFactor A factor indicating the quality/impact of the insight (e.g., 0-100).
    function verifyInsightResult(
        uint256 _agentId,
        uint256 _insightId,
        bool _isAccurate,
        uint256 _insightInfluenceFactor
    ) external;
}

/// @title AetherMindNexus
/// @notice A decentralized protocol for Sentient Data Agents (SDAs) and Dynamic Catalyst Spheres.
///         SDAs are AI-augmented NFTs that process data, and their validated insights
///         influence dynamic Catalyst Spheres (also NFTs). The ecosystem is governed by a DAO
///         and fueled by the AETHER utility token.
contract AetherMindNexus is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _agentTokenIds;
    Counters.Counter private _catalystTokenIds;
    Counters.Counter private _insightIds;
    Counters.Counter private _proposalIds;

    IAETHER public aetherToken;
    IOracle public oracle;

    // Agent Configurations
    struct AgentConfig {
        uint256 mintCost;          // AETHER cost to mint a new agent
        uint256 baseEnergyCost;    // Base energy consumed per insight submission
        uint256 maxTraits;         // Maximum number of upgradable traits per agent
        uint256 energyRechargeRate; // AETHER per energy unit
        uint256 traitUpgradeCostMultiplier; // Multiplier for trait upgrades
    }
    AgentConfig public agentConfig;

    // Catalyst Sphere Configurations
    struct CatalystConfig {
        uint256 fusionCost;         // AETHER cost to fuse spheres
        uint256 stakingRewardRate;  // AETHER per block/day for staking
        uint256 dissolutionRefundRate; // Percentage of mint cost refunded on dissolution
    }
    CatalystConfig public catalystConfig;

    // Sentient Data Agent (SDA) Details
    struct SentientAgent {
        uint256 id;
        address owner;
        address delegatedTo; // Address to whom operational control is delegated
        uint256 reputation;  // Accumulative score based on accurate insights
        uint256 energy;      // Resource consumed for operations
        uint256 lastEnergyRechargeBlock; // Last block energy was recharged
        uint256[] traits;    // Represents evolving AI capabilities (e.g., [accuracy, speed, coverage])
        uint256 rewardsAccumulated; // AETHER rewards pending claim
        string currentTraitsURI; // URI pointing to dynamic traits metadata
        uint256 lastInsightId; // Last insight submitted by this agent
    }
    mapping(uint256 => SentientAgent) public agents;
    mapping(address => uint256[]) public ownerAgents; // To quickly get all agents of an owner
    mapping(uint256 => address) public agentIdToOwner; // To quickly get owner from agent ID

    // Catalyst Sphere Details
    struct CatalystSphere {
        uint256 id;
        address owner;
        uint256 lastUpdatedBlock;
        uint256 creationBlock;
        uint256 stakeStartTime; // 0 if not staked
        uint256 accumulatedStakingRewards; // AETHER rewards pending claim
        uint256[] contributingAgents; // IDs of agents that contributed insights
        string metadataURI; // URI pointing to dynamic metadata (e.g., visual representation)
    }
    mapping(uint256 => CatalystSphere) public catalystSpheres;
    mapping(address => uint256[]) public ownerCatalystSpheres; // To quickly get all spheres of an owner
    mapping(uint256 => address) public catalystIdToOwner; // To quickly get owner from catalyst ID


    // Insight Submission Tracking
    struct InsightSubmission {
        uint256 agentId;
        address submitter; // The agent owner or delegatee who initiated submission
        string dataHash;
        uint256 predictionValue;
        uint256 submissionBlock;
        bool isVerified;
        bool isAccurate;
        uint256 insightInfluenceFactor; // How much this insight influenced others/rewards
    }
    mapping(uint256 => InsightSubmission) public insightSubmissions; // Map insightId to submission details
    mapping(uint256 => uint256[]) public agentInsights; // Map agentId to array of its insights IDs


    // DAO Governance
    struct Proposal {
        uint256 id;
        string description;
        address target;       // Address of the contract to call
        bytes callData;       // Encoded function call
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Voter tracking
    }
    mapping(uint256 => Proposal) public proposals;

    // --- Events ---

    event AetherTokenSet(address indexed _aetherToken);
    event OracleAddressSet(address indexed _oracleAddress);
    event AgentMinted(uint256 indexed agentId, address indexed owner, string initialTraitsURI);
    event DataInsightSubmitted(uint256 indexed agentId, uint256 indexed insightId, string dataHash, uint256 predictionValue);
    event InsightVerified(uint256 indexed insightId, uint256 indexed agentId, bool isAccurate, uint256 influenceFactor);
    event AgentTraitUpgraded(uint256 indexed agentId, uint8 traitIndex, uint256 newTraitValue);
    event AgentEnergyRecharged(uint256 indexed agentId, uint256 amount);
    event AgentDelegated(uint256 indexed agentId, address indexed delegatee);
    event AgentRecalled(uint256 indexed agentId);
    event AgentBurned(uint256 indexed agentId);

    event CatalystSphereMinted(uint256 indexed sphereId, address indexed owner, uint256[] contributingAgentIds, string metadataURI);
    event CatalystMetadataUpdated(uint256 indexed sphereId, string newMetadataURI);
    event CatalystSpheresFused(uint256 indexed sphere1Id, uint256 indexed sphere2Id, uint256 indexed newSphereId);
    event CatalystSphereStaked(uint256 indexed sphereId, address indexed staker);
    event CatalystSphereUnstaked(uint256 indexed sphereId, address indexed unstaker);
    event CatalystSphereDissolved(uint256 indexed sphereId);

    event AgentRewardsClaimed(uint256 indexed agentId, address indexed claimant, uint256 amount);
    event StakingRewardsClaimed(uint256 indexed sphereId, address indexed claimant, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, string description, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == address(oracle), "AMN: Only callable by the designated oracle");
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        require(_exists(_agentId), "AMN: Agent does not exist");
        require(_ownerOf(_agentId) == msg.sender, "AMN: Not agent owner");
        _;
    }

    modifier onlyAgentOwnerOrDelegatee(uint256 _agentId) {
        require(_exists(_agentId), "AMN: Agent does not exist");
        address owner = _ownerOf(_agentId);
        address delegatee = agents[_agentId].delegatedTo;
        require(msg.sender == owner || msg.sender == delegatee, "AMN: Not agent owner or delegatee");
        _;
    }

    modifier onlyCatalystOwner(uint256 _sphereId) {
        require(catalystIdToOwner[_sphereId] == msg.sender, "AMN: Not catalyst owner");
        _;
    }

    // --- Constructor & Initial Configuration ---

    /// @notice Initializes the contract, sets the AETHER token and initial oracle addresses.
    /// @param _aetherTokenAddress The address of the AETHER ERC20 token.
    /// @param _initialOracleAddress The initial address of the decentralized oracle network.
    constructor(address _aetherTokenAddress, address _initialOracleAddress)
        ERC721("AetherMindNexusAgent", "AMNA")
        Ownable(msg.sender) // Owner is deployer for initial setup
        Pausable()
    {
        aetherToken = IAETHER(_aetherTokenAddress);
        oracle = IOracle(_initialOracleAddress);

        // Set initial default configurations
        agentConfig = AgentConfig({
            mintCost: 100 ether,       // Example: 100 AETHER
            baseEnergyCost: 5,         // Example: 5 energy units
            maxTraits: 5,              // Example: Max 5 traits
            energyRechargeRate: 1 ether / 10, // Example: 0.1 AETHER per energy unit
            traitUpgradeCostMultiplier: 10 ether // Example: 10 AETHER per trait level
        });

        catalystConfig = CatalystConfig({
            fusionCost: 200 ether,     // Example: 200 AETHER
            stakingRewardRate: 10 ether / 1 days, // Example: 10 AETHER per day
            dissolutionRefundRate: 50 // Example: 50% refund
        });

        emit AetherTokenSet(_aetherTokenAddress);
        emit OracleAddressSet(_initialOracleAddress);
    }

    // --- I. Core Infrastructure & Configuration ---

    /// @notice Sets the address of the AETHER ERC20 token contract.
    /// @dev Can only be called by the contract owner.
    /// @param _aetherToken The new address for the AETHER token.
    function setAetherTokenAddress(address _aetherToken) public onlyOwner {
        require(_aetherToken != address(0), "AMN: Zero address not allowed");
        aetherToken = IAETHER(_aetherToken);
        emit AetherTokenSet(_aetherToken);
    }

    /// @notice Sets the address of the decentralized oracle network.
    /// @dev Can only be called by the contract owner.
    /// @param _oracleAddress The new address for the oracle.
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "AMN: Zero address not allowed");
        oracle = IOracle(_oracleAddress);
        emit OracleAddressSet(_oracleAddress);
    }

    /// @notice Pauses the contract, disabling sensitive operations.
    /// @dev Only callable by the owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, enabling operations again.
    /// @dev Only callable by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw accidentally sent tokens.
    /// @dev This is an emergency function and should be used cautiously.
    /// @param _tokenAddress The address of the ERC20 token to withdraw.
    function emergencyWithdraw(address _tokenAddress) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    /// @notice Updates the configuration parameters for Sentient Data Agents.
    /// @dev This function should ideally be controlled by the DAO in a production environment.
    /// @param _mintCost The new AETHER cost to mint an agent.
    /// @param _baseEnergyCost The new base energy consumed per insight submission.
    /// @param _maxTraits The new maximum number of upgradable traits.
    function setAgentConfig(
        uint256 _mintCost,
        uint256 _baseEnergyCost,
        uint256 _maxTraits
    ) public onlyOwner { // In production, this would be a DAO-controlled function
        agentConfig.mintCost = _mintCost;
        agentConfig.baseEnergyCost = _baseEnergyCost;
        agentConfig.maxTraits = _maxTraits;
        // Optionally emit an event
    }

    // --- II. Sentient Data Agent (SDA) Management ---

    /// @notice Mints a new Sentient Data Agent NFT for the caller.
    /// @dev Requires the caller to approve `agentConfig.mintCost` AETHER to the contract.
    /// @param _initialTraitsURI The initial URI for the agent's dynamic traits metadata.
    /// @return The ID of the newly minted agent.
    function mintSentientAgent(string calldata _initialTraitsURI)
        public
        whenNotPaused
        returns (uint256)
    {
        require(aetherToken.transferFrom(msg.sender, address(this), agentConfig.mintCost), "AMN: AETHER transfer failed or insufficient allowance");

        _agentTokenIds.increment();
        uint256 newItemId = _agentTokenIds.current();

        agents[newItemId] = SentientAgent({
            id: newItemId,
            owner: msg.sender,
            delegatedTo: address(0),
            reputation: 0,
            energy: 100, // Initial energy
            lastEnergyRechargeBlock: block.number,
            traits: new uint256[](agentConfig.maxTraits), // Initialize empty traits
            rewardsAccumulated: 0,
            currentTraitsURI: _initialTraitsURI,
            lastInsightId: 0
        });

        for(uint8 i = 0; i < agentConfig.maxTraits; i++) {
            agents[newItemId].traits[i] = 1; // Base trait level
        }

        _safeMint(msg.sender, newItemId);
        ownerAgents[msg.sender].push(newItemId);
        agentIdToOwner[newItemId] = msg.sender;

        emit AgentMinted(newItemId, msg.sender, _initialTraitsURI);
        return newItemId;
    }

    /// @notice Allows a Sentient Data Agent to submit a new data insight for verification.
    /// @dev Consumes agent energy. The actual AI computation happens off-chain.
    /// @param _agentId The ID of the agent submitting the insight.
    /// @param _dataHash A cryptographic hash of the raw data analyzed (for verifiability).
    /// @param _predictionValue The key predictive output/value from the agent's analysis.
    function submitDataInsight(
        uint256 _agentId,
        string calldata _dataHash,
        uint256 _predictionValue
    ) public whenNotPaused onlyAgentOwnerOrDelegatee(_agentId) {
        SentientAgent storage agent = agents[_agentId];
        require(agent.energy >= agentConfig.baseEnergyCost, "AMN: Insufficient agent energy");

        agent.energy -= agentConfig.baseEnergyCost;
        _insightIds.increment();
        uint256 currentInsightId = _insightIds.current();

        insightSubmissions[currentInsightId] = InsightSubmission({
            agentId: _agentId,
            submitter: msg.sender,
            dataHash: _dataHash,
            predictionValue: _predictionValue,
            submissionBlock: block.number,
            isVerified: false,
            isAccurate: false,
            insightInfluenceFactor: 0
        });
        agentInsights[_agentId].push(currentInsightId);
        agent.lastInsightId = currentInsightId;

        emit DataInsightSubmitted(_agentId, currentInsightId, _dataHash, _predictionValue);
        // Off-chain oracle picks up DataInsightSubmitted event to verify
    }

    /// @notice Callback function for the oracle to verify a submitted data insight.
    /// @dev Only callable by the designated oracle address.
    /// @param _agentId The ID of the agent whose insight is being verified.
    /// @param _insightId The ID of the specific insight submission.
    /// @param _isAccurate True if the insight was accurate, false otherwise.
    /// @param _insightInfluenceFactor A factor indicating the quality/impact (0-100).
    function verifyInsightResult(
        uint256 _agentId,
        uint256 _insightId,
        bool _isAccurate,
        uint256 _insightInfluenceFactor
    ) public onlyOracle {
        InsightSubmission storage submission = insightSubmissions[_insightId];
        require(!submission.isVerified, "AMN: Insight already verified");
        require(submission.agentId == _agentId, "AMN: Insight ID does not match agent ID");

        submission.isVerified = true;
        submission.isAccurate = _isAccurate;
        submission.insightInfluenceFactor = _insightInfluenceFactor;

        SentientAgent storage agent = agents[_agentId];
        if (_isAccurate) {
            agent.reputation += (_insightInfluenceFactor / 10); // Reputation grows with influence
            agent.energy += (_insightInfluenceFactor / 20); // Small energy boost for good work
            agent.rewardsAccumulated += (_insightInfluenceFactor * 1 ether / 100); // Base reward in AETHER
        } else {
            // Optional: Penalize reputation or energy for inaccurate insights
            if (agent.reputation > 0) agent.reputation -= 1;
        }

        emit InsightVerified(_insightId, _agentId, _isAccurate, _insightInfluenceFactor);
    }

    /// @notice Upgrades a specific trait of a Sentient Data Agent.
    /// @dev Consumes AETHER and agent energy. The cost increases with trait level.
    /// @param _agentId The ID of the agent to upgrade.
    /// @param _traitIndex The index of the trait to upgrade (0 to maxTraits-1).
    /// @param _costMultiplier A dynamic cost multiplier based on desired level.
    function upgradeAgentTrait(uint256 _agentId, uint8 _traitIndex, uint256 _costMultiplier)
        public
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        SentientAgent storage agent = agents[_agentId];
        require(_traitIndex < agentConfig.maxTraits, "AMN: Invalid trait index");
        
        uint256 upgradeCost = agentConfig.traitUpgradeCostMultiplier * _costMultiplier; // Dynamic cost
        require(aetherToken.transferFrom(msg.sender, address(this), upgradeCost), "AMN: AETHER transfer failed for upgrade");
        
        uint256 energyConsumed = upgradeCost / agentConfig.energyRechargeRate; // Simulate energy cost
        require(agent.energy >= energyConsumed, "AMN: Insufficient agent energy for upgrade");
        agent.energy -= energyConsumed;

        agent.traits[_traitIndex]++; // Increment trait level
        // Update URI (off-chain service will listen for this event and update NFT metadata)
        emit AgentTraitUpgraded(_agentId, _traitIndex, agent.traits[_traitIndex]);
    }

    /// @notice Allows the owner to recharge an agent's energy using AETHER.
    /// @dev AETHER is transferred to the contract.
    /// @param _agentId The ID of the agent to recharge.
    /// @param _amount The amount of energy to recharge.
    function rechargeAgentEnergy(uint256 _agentId, uint256 _amount)
        public
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        SentientAgent storage agent = agents[_agentId];
        uint256 aetherCost = _amount * agentConfig.energyRechargeRate;
        require(aetherToken.transferFrom(msg.sender, address(this), aetherCost), "AMN: AETHER transfer failed for energy recharge");
        agent.energy += _amount;
        agent.lastEnergyRechargeBlock = block.number;
        emit AgentEnergyRecharged(_agentId, _amount);
    }

    /// @notice Delegates operational control of an agent to another address.
    /// @dev The delegatee can submit insights and claim rewards for the owner.
    /// @param _agentId The ID of the agent to delegate.
    /// @param _delegatee The address to delegate to. Set to address(0) to remove delegation.
    function delegateAgent(uint256 _agentId, address _delegatee)
        public
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(_delegatee != msg.sender, "AMN: Cannot delegate to self");
        agents[_agentId].delegatedTo = _delegatee;
        emit AgentDelegated(_agentId, _delegatee);
    }

    /// @notice Recalls operational control of a delegated agent.
    /// @dev Only the agent owner can recall delegation.
    /// @param _agentId The ID of the agent to recall.
    function recallDelegatedAgent(uint256 _agentId)
        public
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(agents[_agentId].delegatedTo != address(0), "AMN: Agent not delegated");
        agents[_agentId].delegatedTo = address(0);
        emit AgentRecalled(_agentId);
    }

    /// @notice Allows an owner to burn their Sentient Data Agent NFT.
    /// @dev This removes the agent from the ecosystem. No AETHER refund by default.
    /// @param _agentId The ID of the agent to burn.
    function burnAgent(uint256 _agentId) public whenNotPaused onlyAgentOwner(_agentId) {
        _burn(_agentId);
        // Clean up mappings if necessary to save gas, though not strictly required by ERC721
        delete agents[_agentId];
        // Note: ownerAgents mapping would need manual removal or filtering
        emit AgentBurned(_agentId);
    }


    // --- III. Catalyst Sphere Management ---

    /// @notice Mints a new Catalyst Sphere NFT.
    /// @dev Requires a minimum number of contributing agents and their validated insights.
    /// @param _contributingAgentIds An array of agent IDs whose insights contribute to this sphere.
    /// @param _initialMetadataURI The initial URI for the sphere's dynamic metadata.
    /// @return The ID of the newly minted Catalyst Sphere.
    function mintCatalystSphere(
        uint256[] calldata _contributingAgentIds,
        string calldata _initialMetadataURI
    ) public whenNotPaused returns (uint256) {
        require(_contributingAgentIds.length > 0, "AMN: Must have contributing agents");
        // Further checks: e.g., ensure contributing agents have recent, high-reputation insights
        // For simplicity, we skip complex validation here, assuming off-chain logic ensures validity

        _catalystTokenIds.increment();
        uint256 newSphereId = _catalystTokenIds.current();

        catalystSpheres[newSphereId] = CatalystSphere({
            id: newSphereId,
            owner: msg.sender,
            lastUpdatedBlock: block.number,
            creationBlock: block.number,
            stakeStartTime: 0,
            accumulatedStakingRewards: 0,
            contributingAgents: _contributingAgentIds,
            metadataURI: _initialMetadataURI
        });

        _safeMint(msg.sender, newSphereId);
        ownerCatalystSpheres[msg.sender].push(newSphereId);
        catalystIdToOwner[newSphereId] = msg.sender;

        emit CatalystSphereMinted(newSphereId, msg.sender, _contributingAgentIds, _initialMetadataURI);
        return newSphereId;
    }

    /// @notice Updates the metadata URI of a Catalyst Sphere.
    /// @dev Can be called by the oracle based on new significant insights, or by DAO for major changes.
    /// @param _sphereId The ID of the Catalyst Sphere to update.
    /// @param _newMetadataURI The new URI pointing to updated metadata (e.g., new visuals, stats).
    function updateCatalystMetadata(uint256 _sphereId, string calldata _newMetadataURI)
        public
        whenNotPaused
    {
        // This function would typically be called by the oracle based on aggregated insights
        // For demonstration, we allow owner/delegatee, but a more robust system would involve
        // off-chain aggregation of verified insights leading to an on-chain update call.
        require(catalystIdToOwner[_sphereId] == msg.sender || address(oracle) == msg.sender, "AMN: Not authorized to update metadata");
        
        CatalystSphere storage sphere = catalystSpheres[_sphereId];
        sphere.metadataURI = _newMetadataURI;
        sphere.lastUpdatedBlock = block.number;
        emit CatalystMetadataUpdated(_sphereId, _newMetadataURI);
    }

    /// @notice Fuses two Catalyst Spheres into a new, potentially more powerful one.
    /// @dev Both input spheres are burned, and a new one is minted. Requires AETHER.
    /// @param _sphere1Id The ID of the first sphere to fuse.
    /// @param _sphere2Id The ID of the second sphere to fuse.
    /// @param _fusedMetadataURI The metadata URI for the resulting fused sphere.
    /// @return The ID of the newly created fused sphere.
    function fuseCatalystSpheres(
        uint256 _sphere1Id,
        uint256 _sphere2Id,
        string calldata _fusedMetadataURI
    ) public whenNotPaused returns (uint256) {
        require(_sphere1Id != _sphere2Id, "AMN: Cannot fuse a sphere with itself");
        require(catalystIdToOwner[_sphere1Id] == msg.sender, "AMN: Not owner of sphere 1");
        require(catalystIdToOwner[_sphere2Id] == msg.sender, "AMN: Not owner of sphere 2");

        require(aetherToken.transferFrom(msg.sender, address(this), catalystConfig.fusionCost), "AMN: AETHER transfer failed for fusion");

        // Burn the original spheres
        _burn(_sphere1Id);
        _burn(_sphere2Id);
        delete catalystSpheres[_sphere1Id];
        delete catalystSpheres[_sphere2Id];

        // Create a new fused sphere
        _catalystTokenIds.increment();
        uint256 newFusedSphereId = _catalystTokenIds.current();

        // Combine contributing agents (simple concatenation for demo)
        uint256[] memory combinedAgents = new uint256[](
            catalystSpheres[_sphere1Id].contributingAgents.length + catalystSpheres[_sphere2Id].contributingAgents.length
        );
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < catalystSpheres[_sphere1Id].contributingAgents.length; i++) {
            combinedAgents[currentIdx++] = catalystSpheres[_sphere1Id].contributingAgents[i];
        }
        for (uint256 i = 0; i < catalystSpheres[_sphere2Id].contributingAgents.length; i++) {
            combinedAgents[currentIdx++] = catalystSpheres[_sphere2Id].contributingAgents[i];
        }

        catalystSpheres[newFusedSphereId] = CatalystSphere({
            id: newFusedSphereId,
            owner: msg.sender,
            lastUpdatedBlock: block.number,
            creationBlock: block.number,
            stakeStartTime: 0,
            accumulatedStakingRewards: 0,
            contributingAgents: combinedAgents,
            metadataURI: _fusedMetadataURI
        });

        _safeMint(msg.sender, newFusedSphereId);
        ownerCatalystSpheres[msg.sender].push(newFusedSphereId);
        catalystIdToOwner[newFusedSphereId] = msg.sender;

        emit CatalystSpheresFused(_sphere1Id, _sphere2Id, newFusedSphereId);
        return newFusedSphereId;
    }

    /// @notice Stakes a Catalyst Sphere to earn passive rewards.
    /// @param _sphereId The ID of the sphere to stake.
    function stakeCatalystSphere(uint256 _sphereId) public whenNotPaused onlyCatalystOwner(_sphereId) {
        CatalystSphere storage sphere = catalystSpheres[_sphereId];
        require(sphere.stakeStartTime == 0, "AMN: Sphere already staked");

        sphere.stakeStartTime = block.timestamp;
        emit CatalystSphereStaked(_sphereId, msg.sender);
    }

    /// @notice Unstakes a Catalyst Sphere.
    /// @param _sphereId The ID of the sphere to unstake.
    function unstakeCatalystSphere(uint256 _sphereId) public whenNotPaused onlyCatalystOwner(_sphereId) {
        CatalystSphere storage sphere = catalystSpheres[_sphereId];
        require(sphere.stakeStartTime != 0, "AMN: Sphere not staked");

        // Calculate pending rewards before unstaking
        uint256 rewardDuration = block.timestamp - sphere.stakeStartTime;
        uint256 rewards = (rewardDuration * catalystConfig.stakingRewardRate) / 1 days; // Assuming per day rate

        sphere.accumulatedStakingRewards += rewards;
        sphere.stakeStartTime = 0; // Reset stake status

        emit CatalystSphereUnstaked(_sphereId, msg.sender);
    }

    /// @notice Dissolves a Catalyst Sphere, removing it from existence.
    /// @dev May refund a portion of its perceived value in AETHER.
    /// @param _sphereId The ID of the sphere to dissolve.
    function dissolveCatalystSphere(uint256 _sphereId) public whenNotPaused onlyCatalystOwner(_sphereId) {
        CatalystSphere storage sphere = catalystSpheres[_sphereId];
        require(sphere.stakeStartTime == 0, "AMN: Cannot dissolve staked sphere");

        // Calculate refund based on initial cost or accumulated value (simplified for demo)
        uint256 refundAmount = (agentConfig.mintCost * catalystConfig.dissolutionRefundRate) / 100;
        if (refundAmount > 0) {
            require(aetherToken.transfer(msg.sender, refundAmount), "AMN: Refund transfer failed");
        }

        _burn(_sphereId);
        delete catalystSpheres[_sphereId];

        emit CatalystSphereDissolved(_sphereId);
    }

    // --- IV. Tokenomics & Rewards ---

    /// @notice Allows an agent owner or delegatee to claim accumulated AETHER rewards.
    /// @param _agentId The ID of the agent whose rewards are being claimed.
    function claimAgentRewards(uint256 _agentId) public whenNotPaused onlyAgentOwnerOrDelegatee(_agentId) {
        SentientAgent storage agent = agents[_agentId];
        uint256 amount = agent.rewardsAccumulated;
        require(amount > 0, "AMN: No rewards to claim for this agent");
        
        agent.rewardsAccumulated = 0; // Reset
        require(aetherToken.transfer(msg.sender, amount), "AMN: AETHER reward transfer failed");

        emit AgentRewardsClaimed(_agentId, msg.sender, amount);
    }

    /// @notice Allows a Catalyst Sphere staker to claim accumulated AETHER rewards.
    /// @param _sphereId The ID of the staked sphere.
    function claimStakingRewards(uint256 _sphereId) public whenNotPaused onlyCatalystOwner(_sphereId) {
        CatalystSphere storage sphere = catalystSpheres[_sphereId];
        
        // If currently staked, calculate pending rewards
        if (sphere.stakeStartTime != 0) {
            uint256 rewardDuration = block.timestamp - sphere.stakeStartTime;
            uint256 pendingRewards = (rewardDuration * catalystConfig.stakingRewardRate) / 1 days;
            sphere.accumulatedStakingRewards += pendingRewards;
            sphere.stakeStartTime = block.timestamp; // Reset stake timer
        }

        uint256 amount = sphere.accumulatedStakingRewards;
        require(amount > 0, "AMN: No staking rewards to claim for this sphere");

        sphere.accumulatedStakingRewards = 0; // Reset
        require(aetherToken.transfer(msg.sender, amount), "AMN: AETHER staking reward transfer failed");

        emit StakingRewardsClaimed(_sphereId, msg.sender, amount);
    }

    // --- V. DAO Governance ---
    // Note: A full DAO implementation would require a separate governance token,
    // voting power based on stake/token balance, and more complex timelocks.
    // This is a simplified example.

    /// @notice Allows AETHER token holders to propose a configuration change or action.
    /// @dev A minimum AETHER balance might be required in a full DAO.
    /// @param _description A description of the proposal.
    /// @param _target The address of the contract to call for execution.
    /// @param _callData The encoded function call (e.g., `abi.encodeWithSignature("setAgentConfig(uint256,uint256,uint256)", cost, energy, traits)`).
    /// @return The ID of the newly created proposal.
    function proposeConfigChange(
        string calldata _description,
        address _target,
        bytes calldata _callData
    ) public whenNotPaused returns (uint256) {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            target: _target,
            callData: _callData,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // 7-day voting period
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false
        });

        emit ProposalCreated(proposalId, _description, msg.sender);
        return proposalId;
    }

    /// @notice Allows AETHER token holders to vote on an active proposal.
    /// @dev Voting power should be based on AETHER balance at time of voting or proposal creation.
    ///      For simplicity, current balance is used.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for Yes, False for No.
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startTime > 0, "AMN: Proposal does not exist");
        require(block.timestamp >= proposal.startTime, "AMN: Voting has not started");
        require(block.timestamp < proposal.endTime, "AMN: Voting has ended");
        require(!proposal.hasVoted[msg.sender], "AMN: Already voted on this proposal");

        uint256 voterAetherBalance = aetherToken.balanceOf(msg.sender);
        require(voterAetherBalance > 0, "AMN: No AETHER balance to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yesVotes += voterAetherBalance;
        } else {
            proposal.noVotes += voterAetherBalance;
        }

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed proposal.
    /// @dev Requires the voting period to be over and 'Yes' votes to exceed 'No' votes by a threshold.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startTime > 0, "AMN: Proposal does not exist");
        require(block.timestamp >= proposal.endTime, "AMN: Voting period not over");
        require(!proposal.executed, "AMN: Proposal already executed");

        uint256 requiredVotesForPass = (proposal.yesVotes + proposal.noVotes) / 2 + 1; // Simple majority
        if (proposal.yesVotes > requiredVotesForPass) {
             proposal.passed = true;
             (bool success, ) = proposal.target.call(proposal.callData);
             require(success, "AMN: Proposal execution failed");
        } else {
            proposal.passed = false; // Proposal failed
        }
        
        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    // --- View Functions (Getters) ---

    /// @notice Returns the details of a specific Sentient Data Agent.
    /// @param _agentId The ID of the agent.
    /// @return A tuple containing all agent details.
    function getAgentDetails(uint256 _agentId)
        public
        view
        returns (
            uint256 id,
            address owner,
            address delegatedTo,
            uint256 reputation,
            uint256 energy,
            uint256 lastEnergyRechargeBlock,
            uint256[] memory traits,
            uint256 rewardsAccumulated,
            string memory currentTraitsURI,
            uint256 lastInsightId
        )
    {
        SentientAgent storage agent = agents[_agentId];
        return (
            agent.id,
            agent.owner,
            agent.delegatedTo,
            agent.reputation,
            agent.energy,
            agent.lastEnergyRechargeBlock,
            agent.traits,
            agent.rewardsAccumulated,
            agent.currentTraitsURI,
            agent.lastInsightId
        );
    }

    /// @notice Returns the details of a specific Catalyst Sphere.
    /// @param _sphereId The ID of the sphere.
    /// @return A tuple containing all sphere details.
    function getCatalystSphereDetails(uint256 _sphereId)
        public
        view
        returns (
            uint256 id,
            address owner,
            uint256 lastUpdatedBlock,
            uint256 creationBlock,
            uint256 stakeStartTime,
            uint256 accumulatedStakingRewards,
            uint256[] memory contributingAgents,
            string memory metadataURI
        )
    {
        CatalystSphere storage sphere = catalystSpheres[_sphereId];
        return (
            sphere.id,
            sphere.owner,
            sphere.lastUpdatedBlock,
            sphere.creationBlock,
            sphere.stakeStartTime,
            sphere.accumulatedStakingRewards,
            sphere.contributingAgents,
            sphere.metadataURI
        );
    }

    /// @notice Returns the details of a specific insight submission.
    /// @param _insightId The ID of the insight.
    /// @return A tuple containing all insight submission details.
    function getInsightSubmissionDetails(uint256 _insightId)
        public
        view
        returns (
            uint256 agentId,
            address submitter,
            string memory dataHash,
            uint256 predictionValue,
            uint256 submissionBlock,
            bool isVerified,
            bool isAccurate,
            uint256 insightInfluenceFactor
        )
    {
        InsightSubmission storage submission = insightSubmissions[_insightId];
        return (
            submission.agentId,
            submission.submitter,
            submission.dataHash,
            submission.predictionValue,
            submission.submissionBlock,
            submission.isVerified,
            submission.isAccurate,
            submission.insightInfluenceFactor
        );
    }

    /// @notice Returns the details of a specific DAO proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return A tuple containing all proposal details.
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            uint256 id,
            string memory description,
            address target,
            bytes memory callData,
            uint256 startTime,
            uint256 endTime,
            uint256 yesVotes,
            uint256 noVotes,
            bool executed,
            bool passed
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.description,
            proposal.target,
            proposal.callData,
            proposal.startTime,
            proposal.endTime,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.executed,
            proposal.passed
        );
    }

    /// @notice Returns the number of currently existing Sentient Data Agents.
    function getTotalAgents() public view returns (uint256) {
        return _agentTokenIds.current();
    }

    /// @notice Returns the number of currently existing Catalyst Spheres.
    function getTotalCatalystSpheres() public view returns (uint256) {
        return _catalystTokenIds.current();
    }

    /// @notice Returns the number of all submitted insights.
    function getTotalInsightsSubmitted() public view returns (uint256) {
        return _insightIds.current();
    }

    /// @notice Returns the number of all created DAO proposals.
    function getTotalProposals() public view returns (uint256) {
        return _proposalIds.current();
    }
}
```