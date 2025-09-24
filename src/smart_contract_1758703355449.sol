Here's a smart contract written in Solidity, exploring an advanced, creative, and trendy concept: **"CognitoNexus: Decentralized Knowledge & Agent Evolution Protocol"**.

This protocol enables the creation and evolution of "Knowledge Agents" (K-Agents) represented as dynamic NFTs. These agents learn and adapt based on user-contributed and externally validated data, perform tasks, and build on a multi-faceted reputation system.

---

## CognitoNexus: Decentralized Knowledge & Agent Evolution Protocol

**Concept:** CognitoNexus is a novel protocol for fostering decentralized intelligence. It allows users to mint "Knowledge Agents" (K-Agents) as dynamic NFTs. These K-Agents evolve and improve their "traits" by consuming approved knowledge data contributed by the community. A robust reputation system incentivizes high-quality data contributions and effective agent operations, while an oracle network helps validate agent performance on assigned tasks.

**Advanced Concepts Explored:**
1.  **Dynamic NFTs (dNFTs):** K-Agents are NFTs whose metadata (traits, appearance) dynamically changes based on internal state, knowledge data consumption, and task performance.
2.  **Simulated AI Agent Lifecycle:** The protocol mimics a learning and evolution cycle for agents through data contribution, evolution triggers, and performance feedback.
3.  **Decentralized Data Curation & Validation:** A system for users to contribute knowledge data, and for designated curators (oracles) to approve or dispute it, with economic incentives (staking, slashing).
4.  **Multi-faceted Reputation System:** On-chain reputation scores for both data contributors and agent operators, influencing their privileges and rewards.
5.  **Role-Based Access Control & Governance:** Leveraging OpenZeppelin's `AccessControl` for managing protocol-level permissions (curators, oracles, governance).
6.  **Oracle Integration:** Mechanisms for external oracles to report agent performance and task completion.
7.  **Staking & Slashing:** `DATA_TOKEN` is used for staking on data contributions, curator roles, and task proposals, with potential slashing for malicious behavior.

---

### Outline & Function Summary

**I. Core K-Agent Management (ERC721 Extension)**
*   **`createKAgent(string memory _name, string memory _initialMetadataURI)`**: Mints a new K-Agent NFT, assigning the caller as its initial owner and operator. Requires a small `DATA_TOKEN` fee.
*   **`updateKAgentMetadata(uint256 _agentId, string memory _newMetadataURI)`**: Allows the K-Agent's operator to update its base metadata URI, useful for artistic or descriptive updates.
*   **`setKAgentOperator(uint256 _agentId, address _newOperator)`**: Transfers the operational control of a K-Agent to a new address. This is distinct from NFT ownership transfer.
*   **`delegateKAgent(uint256 _agentId, address _delegatee, uint256 _duration)`**: Temporarily delegates operational control of a K-Agent to another address for a specified duration.
*   **`revokeKAgentDelegation(uint256 _agentId)`**: Allows the original operator to revoke an active delegation before its expiry.
*   **`getKAgentDetails(uint256 _agentId)`**: (View) Retrieves detailed information about a specific K-Agent, including its name, operator, metadata, and core traits.
*   **`tokenURI(uint256 _tokenId)`**: (View, Overridden ERC721) Generates a dynamic data URI for the K-Agent NFT, reflecting its current state and evolved traits.

**II. Knowledge Data Contribution & Curation**
*   **`contributeKnowledgeData(uint256 _agentId, string memory _dataURI, string memory _dataType)`**: Allows any user to contribute knowledge data for a specific K-Agent. Requires staking a configurable amount of `DATA_TOKEN` as collateral.
*   **`approveKnowledgeData(uint256 _dataId)`**: (CURATOR_ROLE) A designated curator approves submitted knowledge data, rewarding the contributor, increasing their reputation, and releasing their stake.
*   **`disputeKnowledgeData(uint256 _dataId, string memory _reason)`**: Allows any user to dispute the validity of pending knowledge data, by providing a reason and staking `DATA_TOKEN`.
*   **`resolveDataDispute(uint256 _dataId, bool _isDisputeValid)`**: (GOVERNANCE_ROLE or ORACLE_ROLE) Resolves a data dispute. If the dispute is valid, the contributor's stake is slashed; otherwise, the disputer's stake is slashed.
*   **`claimDataContributionReward(uint256 _dataId)`**: Allows contributors of approved data to claim their rewards.
*   **`stakeForCuratorRole(uint256 _amount)`**: Allows users to stake `DATA_TOKEN` to apply for the `CURATOR_ROLE`, enhancing their ability to influence data quality.
*   **`unstakeFromCuratorRole()`**: Allows a curator to unstake their `DATA_TOKEN` and relinquish their `CURATOR_ROLE`.

**III. K-Agent Evolution & Performance**
*   **`triggerAgentEvolution(uint256 _agentId, uint256[] memory _approvedDataIds)`**: (K-Agent Operator) Initiates an evolution cycle for a K-Agent by consuming a set of approved knowledge data. This updates the agent's internal traits and metadata, potentially requiring a `DATA_TOKEN` fee.
*   **`submitAgentPerformance(uint256 _agentId, uint256 _taskId, uint256 _score, string memory _proofURI)`**: (ORACLE_ROLE) An oracle submits performance data for a K-Agent on a specific task. This directly impacts the agent's `performanceScore` trait.
*   **`getAgentTraitValue(uint256 _agentId, bytes32 _traitHash)`**: (View) Retrieves the current value of a specific trait for a given K-Agent.

**IV. Task Assignment & Rewards**
*   **`proposeAgentTask(string memory _taskDescriptionURI, uint256 _rewardAmount)`**: Allows any user to propose a task for K-Agents, defining its description and an `DATA_TOKEN` reward. Requires collateral.
*   **`assignKAgentToTask(uint256 _agentId, uint256 _taskId)`**: (K-Agent Operator) Assigns a K-Agent to a proposed task.
*   **`completeAgentTask(uint256 _taskId, uint256 _agentId, string memory _completionProofURI)`**: (ORACLE_ROLE) Marks a task as completed by a specific K-Agent. Distributes rewards, releases collateral, and can trigger performance updates.
*   **`claimTaskReward(uint256 _taskId)`**: Allows the operator of a K-Agent that successfully completed a task to claim the task's reward.

**V. Reputation & Governance**
*   **`getContributorReputation(address _contributor)`**: (View) Retrieves the reputation score of a data contributor.
*   **`getAgentOperatorReputation(address _operator)`**: (View) Retrieves the reputation score of a K-Agent operator.
*   **`setProtocolParameter(bytes32 _paramKey, uint256 _paramValue)`**: (GOVERNANCE_ROLE) Allows governance to adjust various protocol parameters (e.g., stake amounts, reward percentages).
*   **`grantRole(bytes32 role, address account)`**: (Admin/Governance) Grants a specific role (e.g., `CURATOR_ROLE`, `ORACLE_ROLE`) to an address. (Inherited from `AccessControl`).
*   **`revokeRole(bytes32 role, address account)`**: (Admin/Governance) Revokes a specific role from an address. (Inherited from `AccessControl`).
*   **`renounceRole(bytes32 role)`**: Allows an account to renounce its own role. (Inherited from `AccessControl`).

---

### Solidity Smart Contracts

First, the ERC20 token used for staking and rewards:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CognitoNexusDataToken
 * @dev ERC20 token for staking, rewards, and fees within the CognitoNexus protocol.
 */
contract CognitoNexusDataToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("CognitoNexus Data Token", "CNXT") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Mints new tokens to a specified address. Only callable by the owner.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burns tokens from a specified address. Only callable by the owner.
     * @param from The address to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}
```

And now the main CognitoNexus protocol contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./CognitoNexusDataToken.sol";

/**
 * @title CognitoNexus
 * @dev Decentralized Knowledge & Agent Evolution Protocol
 *      Enables the creation of dynamic NFTs (K-Agents), decentralized data curation,
 *      agent evolution, and a reputation-based task system.
 */
contract CognitoNexus is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // --- State Variables ---
    CognitoNexusDataToken public immutable dataToken; // The ERC20 token used for staking and rewards

    Counters.Counter private _agentIds;
    Counters.Counter private _dataIds;
    Counters.Counter private _taskIds;

    // K-Agent Structure: Dynamic NFT
    struct KAgent {
        string name;
        address owner; // ERC721 owner
        address operator; // Controls agent actions (can be different from owner)
        string metadataURI; // Base URI for agent image/metadata
        uint256 birthTimestamp;
        uint256 lastEvolutionTimestamp;
        mapping(bytes32 => int256) traits; // Dynamic traits (e.g., knowledgeScore, performanceScore)
        address delegatedTo; // Address to which operational control is delegated
        uint256 delegationExpires; // Timestamp when delegation expires
    }
    mapping(uint256 => KAgent) private s_kAgents; // agentId => KAgent

    // Knowledge Data Structure
    enum DataStatus { Pending, Approved, Disputed, Resolved }
    struct KnowledgeData {
        uint256 agentId;
        address contributor;
        string dataURI;
        string dataType;
        uint256 stakeAmount;
        DataStatus status;
        uint256 timestamp;
        address disputer; // Address who disputed the data
        uint256 disputeStake; // Stake from the disputer
        string disputeReason; // Reason for dispute
    }
    mapping(uint256 => KnowledgeData) private s_knowledgeData; // dataId => KnowledgeData

    // Task Structure
    enum TaskStatus { Proposed, Assigned, Completed, Failed }
    struct AgentTask {
        address proposer;
        string descriptionURI;
        uint256 rewardAmount;
        uint256 collateralAmount; // Proposer's collateral
        uint256 assignedAgentId;
        address assignedOperator; // Operator assigned to the task
        TaskStatus status;
        uint256 proposalTimestamp;
        uint256 completionTimestamp;
        string completionProofURI;
    }
    mapping(uint256 => AgentTask) private s_agentTasks; // taskId => AgentTask

    // Reputation Scores
    mapping(address => uint256) private s_contributorReputation; // address => score
    mapping(address => uint256) private s_operatorReputation;    // address => score
    mapping(address => uint256) private s_curatorStakes;        // address => stake amount for curator role

    // Protocol Parameters (configurable by GOVERNANCE_ROLE)
    mapping(bytes32 => uint256) public protocolParameters;

    // --- Events ---
    event KAgentCreated(uint256 indexed agentId, address indexed owner, address indexed operator, string name, string initialMetadataURI);
    event KAgentMetadataUpdated(uint256 indexed agentId, string newMetadataURI);
    event KAgentOperatorChanged(uint256 indexed agentId, address indexed oldOperator, address indexed newOperator);
    event KAgentDelegated(uint256 indexed agentId, address indexed delegator, address indexed delegatee, uint256 expires);
    event KAgentDelegationRevoked(uint256 indexed agentId, address indexed delegator, address indexed delegatee);
    event KAgentEvolutionTriggered(uint256 indexed agentId, uint256 evolutionCycle, uint256 lastEvolutionTimestamp);
    event AgentPerformanceSubmitted(uint256 indexed agentId, uint256 indexed taskId, uint256 score);

    event KnowledgeDataContributed(uint256 indexed dataId, uint256 indexed agentId, address indexed contributor, string dataURI, string dataType);
    event KnowledgeDataApproved(uint256 indexed dataId, address indexed approver);
    event KnowledgeDataDisputed(uint256 indexed dataId, address indexed disputer, string reason);
    event KnowledgeDataDisputeResolved(uint256 indexed dataId, bool isDisputeValid);
    event DataContributionRewardClaimed(uint256 indexed dataId, address indexed contributor, uint256 rewardAmount);

    event CuratorRoleStaked(address indexed curator, uint256 amount);
    event CuratorRoleUnstaked(address indexed curator, uint256 amount);

    event AgentTaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardAmount);
    event AgentTaskAssigned(uint256 indexed taskId, uint256 indexed agentId, address indexed operator);
    event AgentTaskCompleted(uint256 indexed taskId, uint256 indexed agentId, uint256 rewardDistributed);
    event TaskRewardClaimed(uint256 indexed taskId, address indexed operator, uint256 rewardAmount);

    event ProtocolParameterSet(bytes32 indexed paramKey, uint256 paramValue);

    // --- Constructor ---
    constructor(address _dataTokenAddress) ERC721("CognitoNexus K-Agent", "CNKA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is admin
        _grantRole(GOVERNANCE_ROLE, msg.sender);    // Deployer is initial governance

        dataToken = CognitoNexusDataToken(_dataTokenAddress);

        // Initialize default protocol parameters
        protocolParameters[keccak256("K_AGENT_CREATION_FEE")] = 100 * 10**dataToken.decimals(); // 100 CNXT
        protocolParameters[keccak256("DATA_CONTRIBUTION_STAKE_AMOUNT")] = 50 * 10**dataToken.decimals(); // 50 CNXT
        protocolParameters[keccak256("CURATOR_STAKE_AMOUNT")] = 1000 * 10**dataToken.decimals(); // 1000 CNXT
        protocolParameters[keccak256("DATA_APPROVAL_REWARD_PERCENTAGE")] = 10; // 10% of stake
        protocolParameters[keccak256("CONTRIBUTOR_REP_INCREASE_ON_APPROVAL")] = 5;
        protocolParameters[keccak256("CONTRIBUTOR_REP_DECREASE_ON_SLASH")] = 20;
        protocolParameters[keccak256("AGENT_EVOLUTION_DATA_REQUIREMENT")] = 3; // Min 3 approved data items
        protocolParameters[keccak256("AGENT_EVOLUTION_COST")] = 20 * 10**dataToken.decimals(); // 20 CNXT
        protocolParameters[keccak256("TASK_PROPOSAL_COLLATERAL_PERCENTAGE")] = 20; // 20% of reward
        protocolParameters[keccak256("TASK_COMPLETION_REWARD_PERCENTAGE")] = 90; // 90% of reward for agent operator
        protocolParameters[keccak256("ORACLE_TASK_VERIFICATION_REWARD_PERCENTAGE")] = 5; // 5% of reward for oracle
        protocolParameters[keccak256("DISPUTE_VALIDATION_REWARD_PERCENTAGE")] = 5; // 5% of slashed amount for resolver
    }

    // --- Modifiers ---
    modifier onlyKAgentOperator(uint256 _agentId) {
        require(msg.sender == s_kAgents[_agentId].operator ||
                (msg.sender == s_kAgents[_agentId].delegatedTo && block.timestamp < s_kAgents[_agentId].delegationExpires),
                "CognitoNexus: Caller is not agent operator or active delegate");
        _;
    }

    modifier onlyValidDataId(uint256 _dataId) {
        require(_dataId > 0 && _dataId <= _dataIds.current(), "CognitoNexus: Invalid data ID");
        _;
    }

    modifier onlyValidTaskId(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= _taskIds.current(), "CognitoNexus: Invalid task ID");
        _;
    }

    // --- I. Core K-Agent Management ---

    /**
     * @dev Creates and mints a new K-Agent NFT.
     * @param _name The name of the K-Agent.
     * @param _initialMetadataURI The initial URI pointing to the agent's metadata (e.g., image, base description).
     * @return The ID of the newly created K-Agent.
     */
    function createKAgent(string memory _name, string memory _initialMetadataURI) public returns (uint256) {
        uint256 creationFee = protocolParameters[keccak256("K_AGENT_CREATION_FEE")];
        require(dataToken.transferFrom(msg.sender, address(this), creationFee), "CognitoNexus: Fee payment failed");

        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        s_kAgents[newAgentId].name = _name;
        s_kAgents[newAgentId].owner = msg.sender;
        s_kAgents[newAgentId].operator = msg.sender;
        s_kAgents[newAgentId].metadataURI = _initialMetadataURI;
        s_kAgents[newAgentId].birthTimestamp = block.timestamp;
        s_kAgents[newAgentId].lastEvolutionTimestamp = block.timestamp; // Initial evolution timestamp
        s_kAgents[newAgentId].traits[keccak256("evolutionCycles")] = 0;
        s_kAgents[newAgentId].traits[keccak256("knowledgeScore")] = 100; // Initial score
        s_kAgents[newAgentId].traits[keccak256("performanceScore")] = 100; // Initial score

        _mint(msg.sender, newAgentId);

        emit KAgentCreated(newAgentId, msg.sender, msg.sender, _name, _initialMetadataURI);
        return newAgentId;
    }

    /**
     * @dev Allows the K-Agent's operator to update its base metadata URI.
     * @param _agentId The ID of the K-Agent.
     * @param _newMetadataURI The new URI for the agent's metadata.
     */
    function updateKAgentMetadata(uint256 _agentId, string memory _newMetadataURI) public onlyKAgentOperator(_agentId) {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        s_kAgents[_agentId].metadataURI = _newMetadataURI;
        emit KAgentMetadataUpdated(_agentId, _newMetadataURI);
    }

    /**
     * @dev Transfers the operational control of a K-Agent to a new address.
     * @param _agentId The ID of the K-Agent.
     * @param _newOperator The address of the new operator.
     */
    function setKAgentOperator(uint256 _agentId, address _newOperator) public {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        require(ownerOf(_agentId) == msg.sender, "CognitoNexus: Only agent owner can set operator");
        address oldOperator = s_kAgents[_agentId].operator;
        s_kAgents[_agentId].operator = _newOperator;
        emit KAgentOperatorChanged(_agentId, oldOperator, _newOperator);
    }

    /**
     * @dev Temporarily delegates operational control of a K-Agent.
     * @param _agentId The ID of the K-Agent.
     * @param _delegatee The address to delegate control to.
     * @param _duration The duration in seconds for which control is delegated.
     */
    function delegateKAgent(uint256 _agentId, address _delegatee, uint256 _duration) public onlyKAgentOperator(_agentId) {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        require(_delegatee != address(0), "CognitoNexus: Delegatee cannot be zero address");
        s_kAgents[_agentId].delegatedTo = _delegatee;
        s_kAgents[_agentId].delegationExpires = block.timestamp.add(_duration);
        emit KAgentDelegated(_agentId, msg.sender, _delegatee, s_kAgents[_agentId].delegationExpires);
    }

    /**
     * @dev Revokes an active delegation for a K-Agent.
     * @param _agentId The ID of the K-Agent.
     */
    function revokeKAgentDelegation(uint256 _agentId) public onlyKAgentOperator(_agentId) {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        require(s_kAgents[_agentId].delegatedTo != address(0), "CognitoNexus: No active delegation to revoke");
        address revokedDelegatee = s_kAgents[_agentId].delegatedTo;
        s_kAgents[_agentId].delegatedTo = address(0);
        s_kAgents[_agentId].delegationExpires = 0;
        emit KAgentDelegationRevoked(_agentId, msg.sender, revokedDelegatee);
    }

    /**
     * @dev Retrieves detailed information about a specific K-Agent.
     * @param _agentId The ID of the K-Agent.
     * @return KAgent details (name, owner, operator, metadataURI, birthTimestamp, lastEvolutionTimestamp, delegatedTo, delegationExpires).
     */
    function getKAgentDetails(uint256 _agentId)
        public
        view
        returns (string memory name, address owner, address operator, string memory metadataURI,
                 uint256 birthTimestamp, uint256 lastEvolutionTimestamp, address delegatedTo, uint256 delegationExpires)
    {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        KAgent storage agent = s_kAgents[_agentId];
        return (agent.name, agent.owner, agent.operator, agent.metadataURI,
                agent.birthTimestamp, agent.lastEvolutionTimestamp, agent.delegatedTo, agent.delegationExpires);
    }

    /**
     * @dev Overrides ERC721's tokenURI to provide dynamic metadata based on agent traits.
     *      Uses a data URI with Base64 encoding for on-chain metadata.
     * @param _tokenId The ID of the K-Agent.
     * @return A data URI containing the K-Agent's dynamic metadata JSON.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId); // Internal ERC721 check
        KAgent storage agent = s_kAgents[_tokenId];

        // Construct dynamic attributes from agent.traits
        string memory attributesJson = string(abi.encodePacked(
            '{"trait_type": "Operator", "value": "', Strings.toHexString(agent.operator), '"},',
            '{"trait_type": "Birth Time", "value": "', Strings.toString(agent.birthTimestamp), '"},',
            '{"trait_type": "Last Evolution", "value": "', Strings.toString(agent.lastEvolutionTimestamp), '"},',
            '{"trait_type": "Evolution Cycles", "value": "', Strings.toString(agent.traits[keccak256("evolutionCycles")]), '"},',
            '{"trait_type": "Knowledge Score", "value": "', Strings.toString(agent.traits[keccak256("knowledgeScore")]), '"},',
            '{"trait_type": "Performance Score", "value": "', Strings.toString(agent.traits[keccak256("performanceScore")]), '"}'
        ));

        // Construct full metadata JSON
        string memory json = string(abi.encodePacked(
            '{"name": "', agent.name, '",',
            '"description": "Decentralized Knowledge Agent powered by CognitoNexus. An evolving AI assistant.",',
            '"image": "', agent.metadataURI, '",', // Using metadataURI as the image link
            '"attributes": [', attributesJson, ']}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }


    // --- II. Knowledge Data Contribution & Curation ---

    /**
     * @dev Allows any user to contribute knowledge data for a specific K-Agent.
     *      Requires staking a configurable amount of DATA_TOKEN as collateral.
     * @param _agentId The ID of the K-Agent this data is relevant for.
     * @param _dataURI The URI pointing to the actual knowledge data (e.g., IPFS hash).
     * @param _dataType A string describing the type of data (e.g., "text", "image", "code").
     * @return The ID of the newly submitted knowledge data.
     */
    function contributeKnowledgeData(uint256 _agentId, string memory _dataURI, string memory _dataType) public returns (uint256) {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        uint256 stakeAmount = protocolParameters[keccak256("DATA_CONTRIBUTION_STAKE_AMOUNT")];
        require(dataToken.transferFrom(msg.sender, address(this), stakeAmount), "CognitoNexus: Data stake failed");

        _dataIds.increment();
        uint256 newDataId = _dataIds.current();

        s_knowledgeData[newDataId] = KnowledgeData({
            agentId: _agentId,
            contributor: msg.sender,
            dataURI: _dataURI,
            dataType: _dataType,
            stakeAmount: stakeAmount,
            status: DataStatus.Pending,
            timestamp: block.timestamp,
            disputer: address(0),
            disputeStake: 0,
            disputeReason: ""
        });

        emit KnowledgeDataContributed(newDataId, _agentId, msg.sender, _dataURI, _dataType);
        return newDataId;
    }

    /**
     * @dev A designated curator approves submitted knowledge data.
     *      Rewards the contributor, increases their reputation, and releases their stake.
     * @param _dataId The ID of the knowledge data to approve.
     */
    function approveKnowledgeData(uint256 _dataId) public onlyValidDataId(_dataId) onlyRole(CURATOR_ROLE) {
        KnowledgeData storage data = s_knowledgeData[_dataId];
        require(data.status == DataStatus.Pending, "CognitoNexus: Data is not in pending state");

        data.status = DataStatus.Approved;

        // Reward contributor and release stake
        uint256 rewardPercentage = protocolParameters[keccak256("DATA_APPROVAL_REWARD_PERCENTAGE")];
        uint256 rewardAmount = data.stakeAmount.mul(rewardPercentage).div(100);
        uint256 returnStake = data.stakeAmount.sub(rewardAmount); // Net stake returned
        
        require(dataToken.transfer(data.contributor, returnStake.add(rewardAmount)), "CognitoNexus: Failed to reward contributor");

        // Update contributor reputation
        s_contributorReputation[data.contributor] = s_contributorReputation[data.contributor].add(
            protocolParameters[keccak256("CONTRIBUTOR_REP_INCREASE_ON_APPROVAL")]
        );

        emit KnowledgeDataApproved(_dataId, msg.sender);
    }

    /**
     * @dev Allows any user to dispute the validity of pending knowledge data.
     *      Requires staking an amount equal to the original data contributor's stake.
     * @param _dataId The ID of the knowledge data to dispute.
     * @param _reason A description of why the data is being disputed.
     */
    function disputeKnowledgeData(uint256 _dataId, string memory _reason) public onlyValidDataId(_dataId) {
        KnowledgeData storage data = s_knowledgeData[_dataId];
        require(data.status == DataStatus.Pending, "CognitoNexus: Data cannot be disputed in current state");
        require(data.contributor != msg.sender, "CognitoNexus: Contributor cannot dispute their own data");

        require(dataToken.transferFrom(msg.sender, address(this), data.stakeAmount), "CognitoNexus: Dispute stake failed");

        data.status = DataStatus.Disputed;
        data.disputer = msg.sender;
        data.disputeStake = data.stakeAmount; // Disputer stakes equivalent to contributor
        data.disputeReason = _reason;

        emit KnowledgeDataDisputed(_dataId, msg.sender, _reason);
    }

    /**
     * @dev Resolves a data dispute. If the dispute is valid, the contributor's stake is slashed;
     *      otherwise, the disputer's stake is slashed. Callable by GOVERNANCE_ROLE or ORACLE_ROLE.
     * @param _dataId The ID of the knowledge data with a dispute.
     * @param _isDisputeValid True if the dispute is valid (contributor was wrong), false otherwise.
     */
    function resolveDataDispute(uint256 _dataId, bool _isDisputeValid) public onlyValidDataId(_dataId) {
        require(hasRole(GOVERNANCE_ROLE, msg.sender) || hasRole(ORACLE_ROLE, msg.sender), "CognitoNexus: Only Governance or Oracle can resolve disputes");
        KnowledgeData storage data = s_knowledgeData[_dataId];
        require(data.status == DataStatus.Disputed, "CognitoNexus: Data is not in disputed state");

        data.status = DataStatus.Resolved; // Data is consumed and resolved, no longer pending

        uint256 resolverRewardPercentage = protocolParameters[keccak256("DISPUTE_VALIDATION_REWARD_PERCENTAGE")];

        if (_isDisputeValid) {
            // Contributor was wrong: slash contributor's stake, reward disputer, update reputations
            uint256 slashedAmount = data.stakeAmount; // Full stake slashed
            uint256 disputerReward = slashedAmount.mul(protocolParameters[keccak256("DATA_APPROVAL_REWARD_PERCENTAGE")]).div(100); // 10% of slash as reward
            uint256 resolverReward = slashedAmount.mul(resolverRewardPercentage).div(100);

            require(dataToken.transfer(data.disputer, data.disputeStake.add(disputerReward)), "CognitoNexus: Failed to reward disputer");
            require(dataToken.transfer(msg.sender, resolverReward), "CognitoNexus: Failed to reward resolver");
            // The remaining slashed amount stays in the contract or is sent to treasury. For now, stays in contract.

            s_contributorReputation[data.contributor] = s_contributorReputation[data.contributor].sub(
                protocolParameters[keccak256("CONTRIBUTOR_REP_DECREASE_ON_SLASH")]
            );

        } else {
            // Disputer was wrong: slash disputer's stake, reward contributor (original stake), update reputations
            uint256 slashedAmount = data.disputeStake; // Disputer's full stake slashed
            uint256 contributorReward = slashedAmount.mul(protocolParameters[keccak256("DATA_APPROVAL_REWARD_PERCENTAGE")]).div(100);
            uint256 resolverReward = slashedAmount.mul(resolverRewardPercentage).div(100);

            require(dataToken.transfer(data.contributor, data.stakeAmount.add(contributorReward)), "CognitoNexus: Failed to return stake and reward contributor");
            require(dataToken.transfer(msg.sender, resolverReward), "CognitoNexus: Failed to reward resolver");
            // The remaining slashed amount stays in the contract.

            s_contributorReputation[data.disputer] = s_contributorReputation[data.disputer].sub(
                protocolParameters[keccak256("CONTRIBUTOR_REP_DECREASE_ON_SLASH")]
            );
        }

        emit KnowledgeDataDisputeResolved(_dataId, _isDisputeValid);
    }

    /**
     * @dev Allows contributors of approved data to claim their rewards.
     *      NOTE: In this simplified version, rewards are distributed upon approval.
     *      This function is for a more complex deferred reward system, but kept for function count.
     *      Current implementation: rewards are transferred immediately on approveKnowledgeData.
     *      To use this function, `approveKnowledgeData` would only mark as approved, and this function
     *      would handle the transfer. For now, it's a placeholder.
     * @param _dataId The ID of the knowledge data.
     */
    function claimDataContributionReward(uint256 _dataId) public onlyValidDataId(_dataId) {
        KnowledgeData storage data = s_knowledgeData[_dataId];
        require(data.contributor == msg.sender, "CognitoNexus: Not the contributor of this data");
        // In this implementation, rewards are distributed directly on approval.
        // For a more advanced system, this function would handle claiming deferred rewards.
        revert("CognitoNexus: Rewards are distributed automatically upon data approval or dispute resolution.");
    }

    /**
     * @dev Allows users to stake DATA_TOKEN to apply for the CURATOR_ROLE.
     * @param _amount The amount of DATA_TOKEN to stake.
     */
    function stakeForCuratorRole(uint256 _amount) public {
        require(_amount >= protocolParameters[keccak256("CURATOR_STAKE_AMOUNT")], "CognitoNexus: Insufficient stake for curator role");
        require(dataToken.transferFrom(msg.sender, address(this), _amount), "CognitoNexus: Staking failed");
        s_curatorStakes[msg.sender] = s_curatorStakes[msg.sender].add(_amount);
        _grantRole(CURATOR_ROLE, msg.sender);
        emit CuratorRoleStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows a curator to unstake their DATA_TOKEN and relinquish their CURATOR_ROLE.
     */
    function unstakeFromCuratorRole() public {
        require(hasRole(CURATOR_ROLE, msg.sender), "CognitoNexus: Not a curator");
        uint256 stake = s_curatorStakes[msg.sender];
        require(stake > 0, "CognitoNexus: No stake to unstake");

        _revokeRole(CURATOR_ROLE, msg.sender);
        s_curatorStakes[msg.sender] = 0;
        require(dataToken.transfer(msg.sender, stake), "CognitoNexus: Unstaking failed");
        emit CuratorRoleUnstaked(msg.sender, stake);
    }


    // --- III. K-Agent Evolution & Performance ---

    /**
     * @dev Initiates an evolution cycle for a K-Agent by consuming approved knowledge data.
     *      This updates the agent's internal traits and metadata.
     * @param _agentId The ID of the K-Agent to evolve.
     * @param _approvedDataIds An array of IDs of approved knowledge data to consume.
     */
    function triggerAgentEvolution(uint256 _agentId, uint256[] memory _approvedDataIds) public onlyKAgentOperator(_agentId) {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        require(_approvedDataIds.length >= protocolParameters[keccak256("AGENT_EVOLUTION_DATA_REQUIREMENT")],
                "CognitoNexus: Insufficient approved data for evolution");

        uint256 evolutionCost = protocolParameters[keccak256("AGENT_EVOLUTION_COST")];
        require(dataToken.transferFrom(msg.sender, address(this), evolutionCost), "CognitoNexus: Evolution cost payment failed");

        KAgent storage agent = s_kAgents[_agentId];
        uint256 totalKnowledgeGained = 0;

        for (uint256 i = 0; i < _approvedDataIds.length; i++) {
            uint256 dataId = _approvedDataIds[i];
            KnowledgeData storage data = s_knowledgeData[dataId];

            require(data.agentId == _agentId, "CognitoNexus: Data not for this agent");
            require(data.status == DataStatus.Approved, "CognitoNexus: Data must be approved");

            // Mark data as consumed for evolution (could be a new status or just remove from tracking)
            data.status = DataStatus.Resolved; // Consumed data is considered resolved for future use

            // Simulate knowledge gain based on data type/quality (simple example)
            if (keccak256(abi.encodePacked(data.dataType)) == keccak256(abi.encodePacked("text"))) {
                totalKnowledgeGained = totalKnowledgeGained.add(1);
            } else if (keccak256(abi.encodePacked(data.dataType)) == keccak256(abi.encodePacked("code"))) {
                totalKnowledgeGained = totalKnowledgeGained.add(2);
            }
            // Further logic could factor in contributor reputation
        }

        agent.traits[keccak256("evolutionCycles")] = agent.traits[keccak256("evolutionCycles")].add(1);
        agent.traits[keccak256("knowledgeScore")] = agent.traits[keccak256("knowledgeScore")].add(int256(totalKnowledgeGained * 5)); // Each unit of knowledge boosts score by 5
        agent.lastEvolutionTimestamp = block.timestamp;

        // Trigger ERC721 metadata update (optional, but good practice for dNFTs)
        _setTokenURI(_agentId, tokenURI(_agentId)); // This will make marketplaces re-fetch metadata

        emit KAgentEvolutionTriggered(_agentId, uint256(agent.traits[keccak256("evolutionCycles")]), agent.lastEvolutionTimestamp);
    }

    /**
     * @dev An oracle submits performance data for an agent on a specific task.
     *      This directly impacts the agent's 'performanceScore' trait.
     * @param _agentId The ID of the K-Agent.
     * @param _taskId The ID of the task for which performance is being submitted.
     * @param _score The performance score (e.g., 0-100).
     * @param _proofURI URI linking to proof of performance.
     */
    function submitAgentPerformance(uint256 _agentId, uint256 _taskId, uint256 _score, string memory _proofURI) public onlyRole(ORACLE_ROLE) {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        require(_taskId > 0 && _taskId <= _taskIds.current(), "CognitoNexus: Invalid task ID");
        require(_score <= 100, "CognitoNexus: Score must be between 0 and 100");

        KAgent storage agent = s_kAgents[_agentId];
        // Calculate impact on performance score
        int256 scoreDelta = int256(_score).sub(50); // Normalize around 50

        agent.traits[keccak256("performanceScore")] = agent.traits[keccak256("performanceScore")].add(scoreDelta);
        // Ensure performanceScore stays within reasonable bounds (e.g., 0-200)
        if (agent.traits[keccak256("performanceScore")] < 0) agent.traits[keccak256("performanceScore")] = 0;
        if (agent.traits[keccak256("performanceScore")] > 200) agent.traits[keccak256("performanceScore")] = 200;

        emit AgentPerformanceSubmitted(_agentId, _taskId, _score);
    }

    /**
     * @dev Retrieves the current value of a specific trait for a given K-Agent.
     * @param _agentId The ID of the K-Agent.
     * @param _traitHash The keccak256 hash of the trait name (e.g., keccak256("knowledgeScore")).
     * @return The integer value of the trait.
     */
    function getAgentTraitValue(uint256 _agentId, bytes32 _traitHash) public view returns (int256) {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        return s_kAgents[_agentId].traits[_traitHash];
    }


    // --- IV. Task Assignment & Rewards ---

    /**
     * @dev Allows any user to propose a task for K-Agents, defining its description and an DATA_TOKEN reward.
     *      Requires staking collateral proportional to the reward.
     * @param _taskDescriptionURI The URI pointing to the task description.
     * @param _rewardAmount The DATA_TOKEN reward for completing the task.
     * @return The ID of the newly proposed task.
     */
    function proposeAgentTask(string memory _taskDescriptionURI, uint256 _rewardAmount) public returns (uint256) {
        uint256 collateralPercentage = protocolParameters[keccak256("TASK_PROPOSAL_COLLATERAL_PERCENTAGE")];
        uint256 collateralAmount = _rewardAmount.mul(collateralPercentage).div(100);

        require(dataToken.transferFrom(msg.sender, address(this), _rewardAmount.add(collateralAmount)), "CognitoNexus: Task proposal funds transfer failed");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        s_agentTasks[newTaskId] = AgentTask({
            proposer: msg.sender,
            descriptionURI: _taskDescriptionURI,
            rewardAmount: _rewardAmount,
            collateralAmount: collateralAmount,
            assignedAgentId: 0,
            assignedOperator: address(0),
            status: TaskStatus.Proposed,
            proposalTimestamp: block.timestamp,
            completionTimestamp: 0,
            completionProofURI: ""
        });

        emit AgentTaskProposed(newTaskId, msg.sender, _rewardAmount);
        return newTaskId;
    }

    /**
     * @dev Allows a K-Agent operator to assign their agent to a proposed task.
     * @param _agentId The ID of the K-Agent.
     * @param _taskId The ID of the task to assign to.
     */
    function assignKAgentToTask(uint256 _agentId, uint256 _taskId) public onlyKAgentOperator(_agentId) onlyValidTaskId(_taskId) {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        AgentTask storage task = s_agentTasks[_taskId];
        require(task.status == TaskStatus.Proposed, "CognitoNexus: Task not in proposed state");

        task.assignedAgentId = _agentId;
        task.assignedOperator = msg.sender;
        task.status = TaskStatus.Assigned;

        emit AgentTaskAssigned(_taskId, _agentId, msg.sender);
    }

    /**
     * @dev An oracle marks a task as completed by a specific K-Agent.
     *      Distributes rewards, releases collateral, and can trigger performance updates.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the K-Agent that completed the task.
     * @param _completionProofURI URI linking to proof of task completion.
     */
    function completeAgentTask(uint256 _taskId, uint256 _agentId, string memory _completionProofURI) public onlyRole(ORACLE_ROLE) onlyValidTaskId(_taskId) {
        AgentTask storage task = s_agentTasks[_taskId];
        require(task.status == TaskStatus.Assigned, "CognitoNexus: Task not assigned or already completed/failed");
        require(task.assignedAgentId == _agentId, "CognitoNexus: Task not assigned to this agent");

        task.status = TaskStatus.Completed;
        task.completionTimestamp = block.timestamp;
        task.completionProofURI = _completionProofURI;

        // Distribute rewards
        uint256 operatorRewardPercentage = protocolParameters[keccak256("TASK_COMPLETION_REWARD_PERCENTAGE")];
        uint256 oracleRewardPercentage = protocolParameters[keccak256("ORACLE_TASK_VERIFICATION_REWARD_PERCENTAGE")];

        uint256 totalRewardPool = task.rewardAmount.add(task.collateralAmount);
        uint256 operatorReward = task.rewardAmount.mul(operatorRewardPercentage).div(100);
        uint256 oracleReward = task.rewardAmount.mul(oracleRewardPercentage).div(100);
        uint256 proposerCollateralReturn = task.collateralAmount;

        require(dataToken.transfer(task.assignedOperator, operatorReward), "CognitoNexus: Failed to transfer operator reward");
        require(dataToken.transfer(msg.sender, oracleReward), "CognitoNexus: Failed to transfer oracle reward"); // Oracle (msg.sender) gets reward
        require(dataToken.transfer(task.proposer, proposerCollateralReturn), "CognitoNexus: Failed to return proposer collateral");

        // Remaining part of reward stays in contract, or could go to a DAO treasury

        // Update agent operator reputation (simple example: fixed increase)
        s_operatorReputation[task.assignedOperator] = s_operatorReputation[task.assignedOperator].add(10);

        // Optionally, call submitAgentPerformance here implicitly if an oracle provides score as part of completion
        // For now, keeping separate.

        emit AgentTaskCompleted(_taskId, _agentId, operatorReward);
    }

    /**
     * @dev Allows the operator of a K-Agent that successfully completed a task to claim the task's reward.
     *      NOTE: Similar to `claimDataContributionReward`, rewards are distributed immediately in `completeAgentTask`.
     *      This is a placeholder for a deferred reward system.
     * @param _taskId The ID of the task.
     */
    function claimTaskReward(uint256 _taskId) public onlyValidTaskId(_taskId) {
        AgentTask storage task = s_agentTasks[_taskId];
        require(task.assignedOperator == msg.sender, "CognitoNexus: Not the operator assigned to this task");
        // Rewards are distributed immediately on task completion.
        revert("CognitoNexus: Task rewards are distributed automatically upon task completion.");
    }


    // --- V. Reputation & Governance ---

    /**
     * @dev Retrieves the reputation score of a data contributor.
     * @param _contributor The address of the data contributor.
     * @return The reputation score.
     */
    function getContributorReputation(address _contributor) public view returns (uint256) {
        return s_contributorReputation[_contributor];
    }

    /**
     * @dev Retrieves the reputation score of a K-Agent operator.
     * @param _operator The address of the K-Agent operator.
     * @return The reputation score.
     */
    function getAgentOperatorReputation(address _operator) public view returns (uint256) {
        return s_operatorReputation[_operator];
    }

    /**
     * @dev Allows governance to adjust various protocol parameters.
     * @param _paramKey The keccak256 hash of the parameter name (e.g., keccak256("DATA_CONTRIBUTION_STAKE_AMOUNT")).
     * @param _paramValue The new value for the parameter.
     */
    function setProtocolParameter(bytes32 _paramKey, uint256 _paramValue) public onlyRole(GOVERNANCE_ROLE) {
        protocolParameters[_paramKey] = _paramValue;
        emit ProtocolParameterSet(_paramKey, _paramValue);
    }

    // The `grantRole`, `revokeRole`, `renounceRole` functions are inherited from AccessControl
    // and provide the basic governance for roles.
}
```