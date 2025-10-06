This smart contract, named **AuraGraph**, envisions a decentralized platform that combines dynamic, soul-bound reputation with a marketplace for AI agents and task orchestration. It aims to create a self-sustaining ecosystem where AI agents and human participants build trust through verifiable actions and attestations, impacting their on-chain "AuraScore" which, in turn, influences their access, pricing, and governance power within the network.

---

### **AuraGraph: Decentralized AI Agent & Reputation Protocol**

**Core Idea:**
AuraGraph is a protocol for building dynamic, multi-faceted reputation ("AuraScore") through non-transferable "AuraBonds" (soul-bound tokens) and on-chain interactions. This reputation system underpins a decentralized marketplace for AI agents to register, offer services, and complete tasks, fostering a trustless environment for AI-driven automation and collaboration.

**Key Components:**
1.  **AuraBonds (Soul-Bound Attestations):** Non-transferable tokens representing skills, achievements, commitments, or verified roles. They are the building blocks of reputation.
2.  **Dynamic AuraScores:** A complex, weighted score calculated based on owned AuraBonds, task completion history, interaction patterns, and performance metrics of AI agents. Scores can decay or grow.
3.  **AI Agent Registry & Orchestration:** A decentralized registry where AI models/agents can register, stake collateral, and expose their capabilities for specific tasks.
4.  **Decentralized Task & Reward System:** Users can define tasks, specify requirements (e.g., minimum AuraScore for agents), and lock rewards. AI agents (or designated human "AuraNodes") can accept, complete, and get verified for these tasks.
5.  **Adaptive Governance (AuraCouncil):** A future-proofed governance structure where voting power is highly influenced by AuraScores and specific AuraBonds, enabling more nuanced and meritocratic decision-making.

**High-Level Architecture:**
The contract manages the lifecycle of AuraBonds, calculates and updates AuraScores, facilitates AI agent registration, task creation, acceptance, completion, and verification. It uses a token (`AuraToken`) for internal rewards and fees, and integrates with a potentially external oracle for complex off-chain data verification (e.g., ZK proofs of AI computation, external data feeds).

---

### **Function Summary (25 Functions):**

**I. AuraBonds (Soul-Bound Attestations - SBT-like)**
1.  `mintAuraBond(address recipient, uint256 bondTypeId, string metadataURI)`: Mints a new non-transferable AuraBond to a recipient.
2.  `updateAuraBondMetadata(uint256 bondId, string newURI)`: Allows the bond issuer or current owner (if permitted by bond type) to update its metadata.
3.  `revokeAuraBond(uint256 bondId)`: Allows the original issuer to revoke a specific AuraBond.
4.  `setBondTypeAttributes(uint256 bondTypeId, address issuer, bool transferable, uint256 decayRate, string name)`: Defines or updates global attributes for a specific type of AuraBond. (Note: for SBTs, `transferable` would be false by default/design, but this allows for flexibility for *some* "bound" attestations).
5.  `getAuraBondDetails(uint256 bondId)`: Retrieves comprehensive details about a specific AuraBond.
6.  `getAuraBondsOf(address account)`: Returns an array of bond IDs owned by a specific account.

**II. Dynamic AuraScores (Reputation System)**
7.  `calculateAuraScore(address user)`: Triggers an on-chain recalculation of a user's AuraScore based on their bonds, interactions, and performance.
8.  `getAuraScore(address user)`: Retrieves the currently stored AuraScore for a user.
9.  `recordInteraction(address participantA, address participantB, uint256 interactionWeight, string interactionType)`: Records a significant interaction between two addresses, influencing their AuraScores.
10. `proposeScoreAdjustment(address user, int256 adjustmentValue, string reasonURI)`: Allows privileged entities (e.g., multi-sig, DAO) to propose direct adjustments to an AuraScore.
11. `decayAuraScores(address[] users)`: Allows a scheduled service or governance to trigger decay for multiple users' AuraScores based on bond types' decay rates.

**III. AI Agent Registry & Orchestration**
12. `registerAIAgent(string agentName, string descriptionURI, address agentExecutor, uint256 stakeAmount)`: Registers a new AI agent, providing its public profile, the address of its on-chain executor/proxy, and an initial collateral stake.
13. `updateAIAgentProfile(uint256 agentId, string newDescriptionURI)`: Allows an AI agent to update its public description URI.
14. `deregisterAIAgent(uint256 agentId)`: Allows an AI agent to initiate deregistration and withdraw its stake after a cool-down period.
15. `submitAIAgentPerformance(uint256 agentId, uint256 taskId, uint256 performanceScore, string verificationURI)`: An AI agent submits a proof of work/performance for a completed task, potentially referencing ZK-proofs or verifiable computation.
16. `getAIAgentDetails(uint256 agentId)`: Retrieves all registered details for a specific AI agent.
17. `getAIAgentsByCapability(string capabilityTag, uint256 minAuraScore)`: Returns a list of AI agents matching a capability tag and meeting a minimum AuraScore.

**IV. Decentralized Task & Reward System**
18. `createTask(string taskDescriptionURI, uint256 rewardAmount, uint256 deadline, string requiredCapability, uint256 minAgentAuraScore, address designatedVerifier)`: Creates a new task, locking the reward and specifying requirements for AI agents.
19. `acceptTask(uint256 taskId, uint256 agentId)`: Allows an eligible AI agent to accept a pending task.
20. `completeTask(uint256 taskId, uint256 agentId, string resultURI)`: An AI agent marks a task as complete and provides a URI to the results (e.g., IPFS hash).
21. `verifyTaskCompletion(uint256 taskId, uint256 agentId, bool success, string verificationURI)`: A designated verifier (or an approved oracle) confirms task success or failure, releasing rewards and updating AuraScores/agent performance.
22. `disputeTaskOutcome(uint256 taskId, uint256 agentId, string reasonURI)`: Allows either the task creator or the agent to dispute the outcome of a task, initiating an arbitration process.

**V. System & Governance Utilities**
23. `setOracleAddress(address _oracleAddress)`: Sets the address for a trusted oracle that can provide off-chain data or ZK-proof verification results.
24. `setAuraScoreWeights(string element, uint256 weight)`: Allows governance to dynamically adjust the weighting of different elements (e.g., bond types, interaction types, performance scores) in the AuraScore calculation.
25. `pauseContract()`: An emergency function to pause critical contract functionalities (e.g., for upgrades or security incidents), only callable by the owner/governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety, though Solidity 0.8+ handles overflows/underflows

/**
 * @title AuraGraph - Decentralized AI Agent & Reputation Protocol
 * @dev This contract orchestrates a dynamic reputation system based on soul-bound attestations (AuraBonds)
 *      and facilitates a marketplace for AI agents to register, perform tasks, and earn rewards.
 *      Reputation (AuraScore) is dynamically calculated and influences agent eligibility and trust.
 *      It integrates concepts of SBTs, on-chain AI agent registry, and a task-based reward system.
 */
contract AuraGraph is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // 1. AuraBonds (Soul-Bound Attestations)
    struct AuraBond {
        uint256 bondId;
        uint256 bondTypeId;
        address owner; // The "soul" to which the bond is bound
        address issuer; // The entity that issued the bond
        string metadataURI; // IPFS hash or URL to bond details
        uint256 mintTimestamp;
        bool revoked;
    }
    Counters.Counter private _bondIdCounter;
    mapping(uint256 => AuraBond) public auraBonds;
    mapping(address => uint256[]) public userAuraBonds; // List of bond IDs owned by an address

    struct AuraBondType {
        string name;
        address issuer; // Default or designated issuer for this type
        bool transferable; // Should be false for true SBTs, but configurable for flexibility
        uint256 decayRatePermille; // Rate per 1000 per period (e.g., year) for score impact
        uint256 scoreWeight; // How much this bond type contributes to AuraScore
    }
    mapping(uint256 => AuraBondType) public auraBondTypes;
    Counters.Counter private _bondTypeIdCounter;

    // 2. Dynamic AuraScores
    mapping(address => uint256) public auraScores;
    mapping(address => uint256) public lastScoreUpdateTimestamp;
    mapping(string => uint256) public auraScoreWeights; // Weights for different elements (e.g., "bondType_X", "interaction_Y", "performance")

    // 3. AI Agent Registry
    struct AIAgent {
        uint256 agentId;
        address owner; // The address controlling the AI agent
        string name;
        string descriptionURI; // IPFS hash or URL to agent capabilities/profile
        address agentExecutor; // Contract/address that the AI agent uses to perform actions or receive calls
        uint256 collateralStake; // Amount of collateral staked by the agent
        bool registered;
        uint256 registrationTimestamp;
        uint256 lastPerformanceScore; // Latest submitted performance score
        uint256 totalTasksCompleted;
    }
    Counters.Counter private _agentIdCounter;
    mapping(uint256 => AIAgent) public aiAgents;
    mapping(address => uint256) public ownerToAgentId; // Only one agent per owner for simplicity

    // 4. Decentralized Task & Reward System
    struct Task {
        uint256 taskId;
        address creator;
        string descriptionURI;
        uint256 rewardAmount;
        uint256 deadline;
        string requiredCapability;
        uint256 minAgentAuraScore;
        uint256 assignedAgentId; // 0 if not assigned
        address designatedVerifier; // Can be a specific address or 0 for community verification
        bool completed;
        bool verified;
        bool disputed;
        uint256 creationTimestamp;
        string resultURI; // URI to the task outcome
        string verificationURI; // URI to verification details
    }
    Counters.Counter private _taskIdCounter;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => address) public taskRewards; // mapping taskId to actual reward token address
    mapping(uint256 => uint256) public taskEscrow; // mapping taskId to amount in escrow

    // 5. System & Governance Utilities
    address public trustedOracleAddress; // For external data verification, ZK-proofs etc.
    bool public paused;
    IERC20 public immutable AuraToken; // The utility token for rewards/fees

    // --- Events ---
    event AuraBondMinted(uint256 indexed bondId, uint256 indexed bondTypeId, address indexed owner, address issuer, string metadataURI);
    event AuraBondMetadataUpdated(uint256 indexed bondId, string newURI);
    event AuraBondRevoked(uint256 indexed bondId, address indexed owner, address indexed revoker);
    event AuraBondTypeDefined(uint256 indexed bondTypeId, string name, address indexed issuer, bool transferable, uint256 decayRatePermille, uint256 scoreWeight);

    event AuraScoreCalculated(address indexed user, uint256 newScore, uint256 oldScore);
    event InteractionRecorded(address indexed participantA, address indexed participantB, uint256 interactionWeight, string interactionType);
    event AuraScoreAdjusted(address indexed user, int256 adjustmentValue, string reasonURI);

    event AIAgentRegistered(uint256 indexed agentId, address indexed owner, string name, address agentExecutor, uint256 stakeAmount);
    event AIAgentProfileUpdated(uint256 indexed agentId, string newDescriptionURI);
    event AIAgentDeregistered(uint256 indexed agentId, address indexed owner);
    event AIAgentPerformanceSubmitted(uint256 indexed agentId, uint256 indexed taskId, uint256 performanceScore, string verificationURI);

    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 rewardAmount, string requiredCapability, uint256 minAgentAuraScore);
    event TaskAccepted(uint256 indexed taskId, uint256 indexed agentId);
    event TaskCompleted(uint256 indexed taskId, uint256 indexed agentId, string resultURI);
    event TaskVerified(uint256 indexed taskId, uint256 indexed agentId, bool success, string verificationURI);
    event TaskDisputed(uint256 indexed taskId, uint256 indexed agentId, string reasonURI);

    event OracleAddressSet(address indexed newOracleAddress);
    event AuraScoreWeightsSet(string indexed element, uint256 weight);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyAuraBondIssuer(uint256 bondId) {
        require(msg.sender == auraBonds[bondId].issuer, "Not the bond issuer");
        _;
    }

    modifier onlyAIAgentOwner(uint256 agentId) {
        require(aiAgents[agentId].owner == msg.sender, "Not the AI agent owner");
        _;
    }

    modifier onlyTaskCreator(uint256 taskId) {
        require(tasks[taskId].creator == msg.sender, "Not the task creator");
        _;
    }

    modifier onlyDesignatedVerifier(uint256 taskId) {
        require(tasks[taskId].designatedVerifier != address(0), "No designated verifier set");
        require(msg.sender == tasks[taskId].designatedVerifier, "Not the designated verifier");
        _;
    }

    // --- Constructor ---
    constructor(address _auraTokenAddress) Ownable(msg.sender) {
        require(_auraTokenAddress != address(0), "AuraToken address cannot be zero");
        AuraToken = IERC20(_auraTokenAddress);

        paused = false;

        // Initialize default AuraScore weights (can be adjusted by governance)
        auraScoreWeights["base"] = 100; // Base score multiplier
        auraScoreWeights["interaction"] = 5; // Weight per interaction
        auraScoreWeights["performance"] = 10; // Weight for AI agent performance
    }

    // --- I. AuraBonds (Soul-Bound Attestations - SBT-like) ---

    /**
     * @dev Defines or updates a new type of AuraBond. Only owner can do this.
     * @param bondTypeId The ID for the bond type. 0 for new type.
     * @param name The name of the bond type (e.g., "Verified Developer", "Task Master").
     * @param issuer The address designated to issue bonds of this type.
     * @param transferable If true, bonds of this type can be transferred (not an SBT). False for SBT.
     * @param decayRatePermille The rate at which the bond's score contribution decays per period (per 1000).
     * @param scoreWeight The base weight this bond type contributes to AuraScore.
     */
    function setBondTypeAttributes(uint256 bondTypeId, string calldata name, address issuer, bool transferable, uint256 decayRatePermille, uint256 scoreWeight) external onlyOwner {
        if (bondTypeId == 0) {
            bondTypeId = _bondTypeIdCounter.current().add(1);
            _bondTypeIdCounter.increment();
        }
        require(issuer != address(0), "Issuer cannot be zero address");
        auraBondTypes[bondTypeId] = AuraBondType(name, issuer, transferable, decayRatePermille, scoreWeight);
        emit AuraBondTypeDefined(bondTypeId, name, issuer, transferable, decayRatePermille, scoreWeight);
    }

    /**
     * @dev Mints a new non-transferable AuraBond to a recipient.
     *      Only the designated issuer for the bondType or contract owner can mint.
     * @param recipient The address to which the bond is bound.
     * @param bondTypeId The ID of the AuraBond type to mint.
     * @param metadataURI IPFS hash or URL pointing to the bond's metadata.
     */
    function mintAuraBond(address recipient, uint256 bondTypeId, string calldata metadataURI) external whenNotPaused {
        AuraBondType storage bondType = auraBondTypes[bondTypeId];
        require(bondType.issuer != address(0), "Bond type not defined");
        require(msg.sender == bondType.issuer || msg.sender == owner(), "Not authorized to mint this bond type");
        require(recipient != address(0), "Recipient cannot be zero address");

        _bondIdCounter.increment();
        uint256 newBondId = _bondIdCounter.current();

        auraBonds[newBondId] = AuraBond({
            bondId: newBondId,
            bondTypeId: bondTypeId,
            owner: recipient,
            issuer: msg.sender,
            metadataURI: metadataURI,
            mintTimestamp: block.timestamp,
            revoked: false
        });
        userAuraBonds[recipient].push(newBondId);

        // Immediately recalculate score or mark for recalculation
        calculateAuraScore(recipient);

        emit AuraBondMinted(newBondId, bondTypeId, recipient, msg.sender, metadataURI);
    }

    /**
     * @dev Allows the bond issuer or (if transferable) the owner to update its metadata.
     *      For true SBTs, only the issuer can update.
     * @param bondId The ID of the AuraBond to update.
     * @param newURI The new metadata URI.
     */
    function updateAuraBondMetadata(uint256 bondId, string calldata newURI) external whenNotPaused {
        AuraBond storage bond = auraBonds[bondId];
        require(bond.bondId != 0, "Bond does not exist");
        require(!bond.revoked, "Bond has been revoked");
        require(msg.sender == bond.issuer || (auraBondTypes[bond.bondTypeId].transferable && msg.sender == bond.owner), "Not authorized to update bond metadata");

        bond.metadataURI = newURI;
        emit AuraBondMetadataUpdated(bondId, newURI);
    }

    /**
     * @dev Allows the original issuer to revoke a specific AuraBond.
     * @param bondId The ID of the AuraBond to revoke.
     */
    function revokeAuraBond(uint256 bondId) external whenNotPaused onlyAuraBondIssuer(bondId) {
        AuraBond storage bond = auraBonds[bondId];
        require(bond.bondId != 0, "Bond does not exist");
        require(!bond.revoked, "Bond already revoked");

        bond.revoked = true;
        // Optionally, remove from userAuraBonds array (gas intensive, consider on-chain list vs filtered view)
        // For simplicity, we'll keep it in the array and filter via view function.

        // Mark for recalculation
        calculateAuraScore(bond.owner);

        emit AuraBondRevoked(bondId, bond.owner, msg.sender);
    }

    /**
     * @dev Retrieves comprehensive details about a specific AuraBond.
     * @param bondId The ID of the AuraBond.
     * @return bondTypeId, owner, issuer, metadataURI, mintTimestamp, revoked, bondTypeName, scoreWeight, decayRatePermille
     */
    function getAuraBondDetails(uint256 bondId)
        external
        view
        returns (
            uint256 bondTypeId,
            address owner,
            address issuer,
            string memory metadataURI,
            uint256 mintTimestamp,
            bool revoked,
            string memory bondTypeName,
            uint256 bondScoreWeight,
            uint256 bondDecayRatePermille
        )
    {
        AuraBond storage bond = auraBonds[bondId];
        require(bond.bondId != 0, "Bond does not exist");
        AuraBondType storage bondType = auraBondTypes[bond.bondTypeId];

        return (
            bond.bondTypeId,
            bond.owner,
            bond.issuer,
            bond.metadataURI,
            bond.mintTimestamp,
            bond.revoked,
            bondType.name,
            bondType.scoreWeight,
            bondType.decayRatePermille
        );
    }

    /**
     * @dev Returns an array of active AuraBond IDs owned by a specific account.
     * @param account The address of the user.
     * @return An array of active AuraBond IDs.
     */
    function getAuraBondsOf(address account) external view returns (uint256[] memory) {
        uint256[] memory allBonds = userAuraBonds[account];
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allBonds.length; i++) {
            if (auraBonds[allBonds[i]].bondId != 0 && !auraBonds[allBonds[i]].revoked) {
                activeCount++;
            }
        }

        uint256[] memory activeBonds = new uint256[](activeCount);
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < allBonds.length; i++) {
            if (auraBonds[allBonds[i]].bondId != 0 && !auraBonds[allBonds[i]].revoked) {
                activeBonds[currentIdx] = allBonds[i];
                currentIdx++;
            }
        }
        return activeBonds;
    }

    // --- II. Dynamic AuraScores (Reputation System) ---

    /**
     * @dev Triggers an on-chain recalculation of a user's AuraScore.
     *      This is a more gas-intensive operation, designed to be called when significant changes occur.
     *      It can be called by anyone, encouraging decentralized score updates.
     * @param user The address of the user whose score is to be recalculated.
     */
    function calculateAuraScore(address user) public whenNotPaused {
        uint256 oldScore = auraScores[user];
        uint256 newScore = 0;

        // Start with a base score
        newScore = auraScoreWeights["base"];

        // Add scores from active AuraBonds
        uint256[] memory bonds = getAuraBondsOf(user);
        for (uint256 i = 0; i < bonds.length; i++) {
            AuraBond storage bond = auraBonds[bonds[i]];
            AuraBondType storage bondType = auraBondTypes[bond.bondTypeId];

            if (!bond.revoked) {
                uint256 bondValue = bondType.scoreWeight;
                // Apply decay based on time elapsed since minting
                uint256 periodsElapsed = (block.timestamp - bond.mintTimestamp) / (365 days); // Example: yearly decay
                if (bondType.decayRatePermille > 0 && periodsElapsed > 0) {
                    uint256 decayedValue = bondValue.mul(1000 - bondType.decayRatePermille).div(1000);
                    for (uint256 j = 1; j < periodsElapsed; j++) { // Apply decay multiplicatively for multiple periods
                         decayedValue = decayedValue.mul(1000 - bondType.decayRatePermille).div(1000);
                    }
                    bondValue = decayedValue;
                }
                newScore = newScore.add(bondValue);
            }
        }

        // Add performance scores (for AI agents)
        uint256 agentId = ownerToAgentId[user];
        if (agentId != 0 && aiAgents[agentId].registered) {
            newScore = newScore.add(aiAgents[agentId].lastPerformanceScore.mul(auraScoreWeights["performance"]).div(100)); // Normalize performance contribution
        }

        // (Future enhancement: incorporate interaction history, external oracle data for more complex factors)

        auraScores[user] = newScore;
        lastScoreUpdateTimestamp[user] = block.timestamp;
        emit AuraScoreCalculated(user, newScore, oldScore);
    }

    /**
     * @dev Retrieves the currently stored AuraScore for a user.
     *      Does not trigger recalculation; returns the last calculated value.
     * @param user The address of the user.
     * @return The current AuraScore.
     */
    function getAuraScore(address user) external view returns (uint256) {
        return auraScores[user];
    }

    /**
     * @dev Records a significant interaction between two participants.
     *      This can be called by a trusted third party, a task verifier, or the participants themselves.
     *      Influences AuraScores through the `calculateAuraScore` function.
     * @param participantA The first participant.
     * @param participantB The second participant.
     * @param interactionWeight The weight of this interaction (e.g., 1 for simple interaction, higher for significant one).
     * @param interactionType A string describing the type of interaction (e.g., "collaboration", "dispute").
     */
    function recordInteraction(address participantA, address participantB, uint256 interactionWeight, string calldata interactionType) external whenNotPaused {
        require(participantA != address(0) && participantB != address(0), "Participants cannot be zero address");
        require(participantA != participantB, "Cannot interact with self in this context");

        // Simple direct score adjustment for interaction, can be made more complex in calculateAuraScore
        auraScores[participantA] = auraScores[participantA].add(interactionWeight.mul(auraScoreWeights["interaction"]));
        auraScores[participantB] = auraScores[participantB].add(interactionWeight.mul(auraScoreWeights["interaction"]));

        lastScoreUpdateTimestamp[participantA] = block.timestamp;
        lastScoreUpdateTimestamp[participantB] = block.timestamp;

        emit InteractionRecorded(participantA, participantB, interactionWeight, interactionType);
    }

    /**
     * @dev Allows privileged entities (e.g., owner or future governance) to propose direct adjustments to an AuraScore.
     *      This is an override for exceptional circumstances.
     * @param user The address of the user whose score is to be adjusted.
     * @param adjustmentValue The value to add or subtract from the current score (can be negative).
     * @param reasonURI IPFS hash or URL explaining the reason for adjustment.
     */
    function proposeScoreAdjustment(address user, int256 adjustmentValue, string calldata reasonURI) external onlyOwner whenNotPaused {
        require(user != address(0), "User cannot be zero address");

        uint256 currentScore = auraScores[user];
        if (adjustmentValue > 0) {
            auraScores[user] = currentScore.add(uint256(adjustmentValue));
        } else {
            uint256 absAdjustment = uint256(-adjustmentValue);
            auraScores[user] = currentScore > absAdjustment ? currentScore.sub(absAdjustment) : 0;
        }

        lastScoreUpdateTimestamp[user] = block.timestamp;
        emit AuraScoreAdjusted(user, adjustmentValue, reasonURI);
    }

    /**
     * @dev Allows a scheduled service or governance to trigger decay for multiple users' AuraScores.
     *      This function can be called periodically to ensure scores reflect recent activity and decay.
     * @param users An array of addresses whose scores should be decayed.
     */
    function decayAuraScores(address[] calldata users) external onlyOwner whenNotPaused {
        uint256 decayInterval = 30 days; // Example: monthly decay period
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (lastScoreUpdateTimestamp[user] + decayInterval < block.timestamp) {
                calculateAuraScore(user); // Recalculate to apply current bond decays
            }
        }
    }


    // --- III. AI Agent Registry & Orchestration ---

    /**
     * @dev Registers a new AI agent with the protocol.
     * @param agentName The human-readable name of the AI agent.
     * @param descriptionURI IPFS hash or URL to the agent's detailed profile and capabilities.
     * @param agentExecutor The address of the on-chain contract/proxy that the AI agent uses for operations.
     * @param stakeAmount The amount of AuraToken to stake as collateral.
     */
    function registerAIAgent(string calldata agentName, string calldata descriptionURI, address agentExecutor, uint256 stakeAmount) external whenNotPaused {
        require(ownerToAgentId[msg.sender] == 0, "Address already owns an AI agent");
        require(agentExecutor != address(0), "Agent executor cannot be zero address");
        require(stakeAmount > 0, "Stake amount must be greater than zero");
        require(AuraToken.transferFrom(msg.sender, address(this), stakeAmount), "AuraToken transfer failed for stake");

        _agentIdCounter.increment();
        uint256 newAgentId = _agentIdCounter.current();

        aiAgents[newAgentId] = AIAgent({
            agentId: newAgentId,
            owner: msg.sender,
            name: agentName,
            descriptionURI: descriptionURI,
            agentExecutor: agentExecutor,
            collateralStake: stakeAmount,
            registered: true,
            registrationTimestamp: block.timestamp,
            lastPerformanceScore: 0,
            totalTasksCompleted: 0
        });
        ownerToAgentId[msg.sender] = newAgentId;

        // Recalculate owner's AuraScore now that they are an agent
        calculateAuraScore(msg.sender);

        emit AIAgentRegistered(newAgentId, msg.sender, agentName, agentExecutor, stakeAmount);
    }

    /**
     * @dev Allows an AI agent owner to update their agent's public description URI.
     * @param agentId The ID of the AI agent.
     * @param newDescriptionURI The new IPFS hash or URL.
     */
    function updateAIAgentProfile(uint256 agentId, string calldata newDescriptionURI) external whenNotPaused onlyAIAgentOwner(agentId) {
        AIAgent storage agent = aiAgents[agentId];
        require(agent.registered, "AI agent not registered");
        agent.descriptionURI = newDescriptionURI;
        emit AIAgentProfileUpdated(agentId, newDescriptionURI);
    }

    /**
     * @dev Allows an AI agent to initiate deregistration and withdraw its stake after a cool-down period.
     *      Stake withdrawal logic could be complex (e.g., cool-down, pending tasks, disputes).
     *      For simplicity, immediate withdrawal here, but in production, would need proper cool-down/checks.
     * @param agentId The ID of the AI agent to deregister.
     */
    function deregisterAIAgent(uint256 agentId) external whenNotPaused onlyAIAgentOwner(agentId) {
        AIAgent storage agent = aiAgents[agentId];
        require(agent.registered, "AI agent not registered");
        // In a real system, would check for pending tasks, cool-down, etc.

        uint256 stake = agent.collateralStake;
        agent.registered = false;
        agent.collateralStake = 0;
        delete ownerToAgentId[msg.sender];
        // Note: The agent struct still exists to preserve history but is marked as deregistered.

        require(AuraToken.transfer(msg.sender, stake), "Failed to return stake");

        // Recalculate AuraScore as agent status changed
        calculateAuraScore(msg.sender);

        emit AIAgentDeregistered(agentId, msg.sender);
    }

    /**
     * @dev An AI agent submits a proof of work/performance for a completed task.
     *      This could reference ZK-proofs or verifiable computation in `verificationURI`.
     * @param agentId The ID of the AI agent submitting performance.
     * @param taskId The ID of the task for which performance is being submitted.
     * @param performanceScore A score (e.g., 0-1000) indicating the quality/efficiency of work.
     * @param verificationURI IPFS hash or URL to the proof of performance.
     */
    function submitAIAgentPerformance(uint256 agentId, uint256 taskId, uint256 performanceScore, string calldata verificationURI) external whenNotPaused onlyAIAgentOwner(agentId) {
        require(aiAgents[agentId].registered, "AI agent not registered");
        require(tasks[taskId].taskId != 0, "Task does not exist");
        require(tasks[taskId].assignedAgentId == agentId, "Task not assigned to this agent");
        require(tasks[taskId].completed, "Task not marked as completed yet");
        require(!tasks[taskId].verified, "Task already verified"); // Performance linked to verification

        // Store performance for later verification and score calculation
        aiAgents[agentId].lastPerformanceScore = performanceScore;
        // The actual score impact will happen in `verifyTaskCompletion`
        emit AIAgentPerformanceSubmitted(agentId, taskId, performanceScore, verificationURI);
    }

    /**
     * @dev Retrieves all registered details for a specific AI agent.
     * @param agentId The ID of the AI agent.
     * @return owner, name, descriptionURI, agentExecutor, collateralStake, registered, registrationTimestamp, lastPerformanceScore, totalTasksCompleted
     */
    function getAIAgentDetails(uint256 agentId)
        external
        view
        returns (
            address owner,
            string memory name,
            string memory descriptionURI,
            address agentExecutor,
            uint256 collateralStake,
            bool registered,
            uint256 registrationTimestamp,
            uint256 lastPerformanceScore,
            uint256 totalTasksCompleted
        )
    {
        AIAgent storage agent = aiAgents[agentId];
        require(agent.agentId != 0, "AI agent does not exist");

        return (
            agent.owner,
            agent.name,
            agent.descriptionURI,
            agent.agentExecutor,
            agent.collateralStake,
            agent.registered,
            agent.registrationTimestamp,
            agent.lastPerformanceScore,
            agent.totalTasksCompleted
        );
    }

    /**
     * @dev Returns a list of AI agents that are registered, active, match a capability tag (simple string match),
     *      and meet a minimum AuraScore.
     * @param capabilityTag A simple string tag for filtering (e.g., "data_analysis", "image_generation").
     * @param minAuraScore The minimum AuraScore required for the agent.
     * @return An array of eligible AI agent IDs.
     */
    function getAIAgentsByCapability(string calldata capabilityTag, uint256 minAuraScore) external view returns (uint256[] memory) {
        uint256[] memory eligibleAgents = new uint256[](_agentIdCounter.current()); // Max possible size
        uint256 count = 0;

        for (uint256 i = 1; i <= _agentIdCounter.current(); i++) {
            AIAgent storage agent = aiAgents[i];
            if (agent.registered && auraScores[agent.owner] >= minAuraScore) {
                // Simplified capability matching: check if tag is in descriptionURI or a dedicated field (future enhancement)
                // For a real system, this would involve a dedicated mapping or an off-chain indexer.
                // Assuming descriptionURI contains capability tags for this example.
                // string memory desc = agent.descriptionURI;
                // if (bytes(desc).length == 0 || Strings.indexOf(desc, capabilityTag) != -1) { // Pseudo-code for string contains
                // This is too complex for on-chain, relying on off-chain indexing or a very simple exact match
                // For on-chain, would need specific capability `mapping(uint256 => mapping(string => bool))`
                // For now, return all agents meeting score if capabilityTag is empty, or placeholder for future.
                if (bytes(capabilityTag).length == 0 || keccak256(abi.encodePacked(capabilityTag)) == keccak256(abi.encodePacked("any"))) { // simplified for demo
                     eligibleAgents[count] = i;
                     count++;
                } else {
                    // Placeholder for actual capability matching logic.
                    // A real solution would involve a dedicated `agentCapabilities` mapping or off-chain index.
                    // For this example, let's just assume an empty tag or "any" matches all.
                }

            }
        }

        // Resize the array to actual count
        uint256[] memory finalAgents = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalAgents[i] = eligibleAgents[i];
        }
        return finalAgents;
    }


    // --- IV. Decentralized Task & Reward System ---

    /**
     * @dev Creates a new task, locking the reward and specifying requirements for AI agents.
     *      Requires `msg.sender` to approve AuraToken transfer to this contract first.
     * @param taskDescriptionURI IPFS hash or URL to the detailed task description.
     * @param rewardAmount The amount of AuraToken offered as reward.
     * @param deadline The timestamp by which the task must be completed.
     * @param requiredCapability A string indicating the required capability for agents.
     * @param minAgentAuraScore The minimum AuraScore an agent must have to accept the task.
     * @param designatedVerifier An optional address to specifically verify this task. If zero, requires owner/oracle.
     */
    function createTask(
        string calldata taskDescriptionURI,
        uint256 rewardAmount,
        uint256 deadline,
        string calldata requiredCapability,
        uint256 minAgentAuraScore,
        address designatedVerifier
    ) external whenNotPaused {
        require(rewardAmount > 0, "Reward amount must be greater than zero");
        require(deadline > block.timestamp, "Deadline must be in the future");
        require(AuraToken.transferFrom(msg.sender, address(this), rewardAmount), "AuraToken transfer failed for task reward");

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        tasks[newTaskId] = Task({
            taskId: newTaskId,
            creator: msg.sender,
            descriptionURI: taskDescriptionURI,
            rewardAmount: rewardAmount,
            deadline: deadline,
            requiredCapability: requiredCapability,
            minAgentAuraScore: minAgentAuraScore,
            assignedAgentId: 0,
            designatedVerifier: designatedVerifier,
            completed: false,
            verified: false,
            disputed: false,
            creationTimestamp: block.timestamp,
            resultURI: "",
            verificationURI: ""
        });
        taskRewards[newTaskId] = address(AuraToken);
        taskEscrow[newTaskId] = rewardAmount;

        emit TaskCreated(newTaskId, msg.sender, rewardAmount, requiredCapability, minAgentAuraScore);
    }

    /**
     * @dev Allows an eligible AI agent to accept a pending task.
     * @param taskId The ID of the task to accept.
     * @param agentId The ID of the AI agent accepting the task.
     */
    function acceptTask(uint256 taskId, uint256 agentId) external whenNotPaused onlyAIAgentOwner(agentId) {
        Task storage task = tasks[taskId];
        AIAgent storage agent = aiAgents[agentId];

        require(task.taskId != 0, "Task does not exist");
        require(task.assignedAgentId == 0, "Task already assigned");
        require(block.timestamp < task.deadline, "Task deadline passed");
        require(agent.registered, "AI agent not registered");
        require(auraScores[agent.owner] >= task.minAgentAuraScore, "AI agent does not meet minimum AuraScore");
        // (Future: check for requiredCapability match with agent's capabilities)

        task.assignedAgentId = agentId;

        // Optionally, agent could stake a small amount for accepting
        // require(AuraToken.transferFrom(msg.sender, address(this), agentCommitmentStake), "Agent commitment stake failed");

        emit TaskAccepted(taskId, agentId);
    }

    /**
     * @dev An AI agent marks a task as complete and provides a URI to the results.
     * @param taskId The ID of the task.
     * @param agentId The ID of the AI agent completing the task.
     * @param resultURI IPFS hash or URL to the task results.
     */
    function completeTask(uint256 taskId, uint256 agentId, string calldata resultURI) external whenNotPaused onlyAIAgentOwner(agentId) {
        Task storage task = tasks[taskId];
        require(task.taskId != 0, "Task does not exist");
        require(task.assignedAgentId == agentId, "Task not assigned to this agent");
        require(block.timestamp < task.deadline, "Task deadline passed, cannot complete");
        require(!task.completed, "Task already marked as complete");

        task.completed = true;
        task.resultURI = resultURI;

        emit TaskCompleted(taskId, agentId, resultURI);
    }

    /**
     * @dev A designated verifier or the trusted oracle confirms task success or failure,
     *      releasing rewards, updating AuraScores, and agent performance.
     * @param taskId The ID of the task.
     * @param agentId The ID of the AI agent that completed the task.
     * @param success True if the task was successfully completed, false otherwise.
     * @param verificationURI IPFS hash or URL to verification details/proof.
     */
    function verifyTaskCompletion(uint256 taskId, uint256 agentId, bool success, string calldata verificationURI) external whenNotPaused {
        Task storage task = tasks[taskId];
        AIAgent storage agent = aiAgents[agentId];

        require(task.taskId != 0, "Task does not exist");
        require(task.assignedAgentId == agentId, "Task not assigned to this agent");
        require(task.completed, "Task not marked as completed");
        require(!task.verified, "Task already verified");
        require(!task.disputed, "Task is currently disputed");

        // Verifier check: Can be owner, designated verifier, or trusted oracle
        bool isAuthorizedVerifier = (msg.sender == owner()) ||
                                    (task.designatedVerifier != address(0) && msg.sender == task.designatedVerifier) ||
                                    (trustedOracleAddress != address(0) && msg.sender == trustedOracleAddress);

        require(isAuthorizedVerifier, "Not authorized to verify this task");

        task.verified = true;
        task.verificationURI = verificationURI;

        if (success) {
            // Reward the agent
            require(taskEscrow[taskId] > 0, "No reward in escrow for task");
            require(AuraToken.transfer(agent.owner, taskEscrow[taskId]), "Failed to transfer reward to agent");
            taskEscrow[taskId] = 0;

            // Update agent performance and AuraScore
            agent.totalTasksCompleted = agent.totalTasksCompleted.add(1);
            // Re-calculate agent's AuraScore, incorporating new performance (lastPerformanceScore is from submitAIAgentPerformance)
            calculateAuraScore(agent.owner);
            // Also, a positive interaction with the task creator
            recordInteraction(agent.owner, task.creator, 50, "task_completion"); // Example weight
        } else {
            // Penalize agent (optional: slash stake, reduce score)
            // For now, just recalculate score without reward, optionally slash a % of stake
            // Example: 10% stake slash on failure
            uint256 penalty = agent.collateralStake.div(10);
            if (penalty > 0) {
                 require(AuraToken.transfer(task.creator, penalty), "Failed to transfer penalty to creator");
                 agent.collateralStake = agent.collateralStake.sub(penalty);
            }

            calculateAuraScore(agent.owner); // Score will reflect non-performance
            // Return remaining escrow to task creator
            if (taskEscrow[taskId] > 0) {
                 require(AuraToken.transfer(task.creator, taskEscrow[taskId]), "Failed to return escrow to creator");
                 taskEscrow[taskId] = 0;
            }
        }
        emit TaskVerified(taskId, agentId, success, verificationURI);
    }

    /**
     * @dev Allows either the task creator or the assigned agent to dispute the outcome of a task.
     *      Initiates an arbitration process (off-chain or simplified on-chain here).
     * @param taskId The ID of the task.
     * @param agentId The ID of the AI agent.
     * @param reasonURI IPFS hash or URL detailing the reason for the dispute.
     */
    function disputeTaskOutcome(uint256 taskId, uint256 agentId, string calldata reasonURI) external whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.taskId != 0, "Task does not exist");
        require(task.assignedAgentId == agentId, "Task not assigned to this agent");
        require(msg.sender == task.creator || msg.sender == aiAgents[agentId].owner, "Only task creator or agent owner can dispute");
        require(task.completed, "Task not completed yet");
        require(!task.verified, "Task already verified, cannot dispute (unless new evidence allows specific override)");
        require(!task.disputed, "Task already under dispute");

        task.disputed = true;
        // In a real system, this would trigger an arbitration process (e.g., Kleros, or specific governance vote).
        // For simplicity, this simply flags the task and prevents further actions until resolved.
        emit TaskDisputed(taskId, agentId, reasonURI);
    }

    // --- V. System & Governance Utilities ---

    /**
     * @dev Sets the address for a trusted oracle that can provide off-chain data or ZK-proof verification results.
     * @param _oracleAddress The address of the trusted oracle.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner whenNotPaused {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        trustedOracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    /**
     * @dev Allows governance (owner for now) to dynamically adjust the weighting of different elements
     *      in the AuraScore calculation (e.g., bond types, interaction types, performance scores).
     * @param element The string identifier for the element (e.g., "base", "interaction", "performance", "bondType_X").
     * @param weight The new weight value.
     */
    function setAuraScoreWeights(string calldata element, uint256 weight) external onlyOwner whenNotPaused {
        require(bytes(element).length > 0, "Element string cannot be empty");
        auraScoreWeights[element] = weight;
        emit AuraScoreWeightsSet(element, weight);
    }

    /**
     * @dev Emergency function to pause critical contract functionalities.
     *      Only callable by the owner (or designated governance).
     */
    function pauseContract() external onlyOwner {
        require(!paused, "Contract is already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Emergency function to unpause the contract.
     *      Only callable by the owner (or designated governance).
     */
    function unpauseContract() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Fallback & Receive ---
    receive() external payable {
        // Option to handle direct ETH deposits if needed, though this contract primarily uses AuraToken.
        // Revert by default or log for unexpected ETH.
        revert("AuraGraph: ETH receive not supported directly, use specific functions for tokens.");
    }

    fallback() external payable {
        revert("AuraGraph: Call to non-existent function or unexpected ETH.");
    }
}
```