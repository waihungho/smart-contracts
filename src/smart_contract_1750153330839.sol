Okay, let's design a smart contract centered around a concept we can call "SyntheAgent Protocol". This protocol manages on-chain digital personas ("Agents") that can earn reputation, track skills through verifiable attestations from other Agents/users, unlock achievements based on on-chain activity and attestations, and utilize an internal utility currency ("Essence") earned by staking ETH. It incorporates concepts like structured on-chain data, reputation systems, conditional state changes (achievements), a simple staking mechanism for utility, and a form of delegated authority.

This isn't a standard token, a typical DAO, or a simple multisig. It combines elements of identity, reputation, gamification, and DeFi utility staking in a potentially novel way.

Here's the contract outline and code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SyntheAgent Protocol
 * @dev A protocol for managing on-chain digital personas (Agents), reputation,
 *      attestations, achievements, and a utility currency (Essence).
 *      Agents can receive attestations about skills/attributes from others,
 *      gain reputation, and unlock achievements. Essence is earned by staking
 *      ETH and is used to pay for actions like issuing attestations.
 *      Includes concepts like on-chain structured data, programmable achievements,
 *      utility staking, and delegated attestation authority.
 *
 * Outline:
 * 1. State Variables & Structs: Define data structures for Agents, Attestations, Achievements, etc.
 * 2. Events: Announce key actions and state changes.
 * 3. Modifiers: Implement access control logic.
 * 4. Core Agent Management: Creation, transfer, burning, metadata.
 * 5. Attestation System: Issuing, revoking, retrieving attestations. Links to Agents.
 * 6. Reputation System: Calculation or updating based on attestations.
 * 7. Essence Utility Token (Internal): Staking ETH to earn Essence, managing balances, payments.
 * 8. Achievement System: Defining achievements, checking conditions, unlocking for Agents.
 * 9. Delegation: Allowing users to delegate their attestation issuing rights.
 * 10. Dynamic Properties: Calculating derived values like 'dynamic skill'.
 * 11. Protocol Configuration: Admin functions for setting parameters.
 * 12. View Functions: Read protocol data.
 *
 * Function Summary (29 functions):
 *
 * // --- Core Agent Management (5 functions) ---
 * 1.  createAgent(): Creates a new Agent, assigns unique ID and ownership.
 * 2.  transferAgentOwnership(uint256 _agentId, address _newOwner): Transfers ownership of an Agent.
 * 3.  burnAgent(uint256 _agentId): Destroys an Agent (owner only).
 * 4.  updateAgentMetadataUri(uint256 _agentId, string calldata _metadataUri): Sets external metadata URI for an Agent.
 * 5.  getAgentDetails(uint256 _agentId): View: Retrieve details about an Agent.
 *
 * // --- Attestation System (6 functions) ---
 * 6.  issueAttestation(uint256 _subjectAgentId, string calldata _skillKey, string calldata _value, uint256 _weight): Creates an on-chain attestation about an Agent's skill/attribute. Requires Essence payment.
 * 7.  revokeAttestation(bytes32 _attestationHash): Revokes a previously issued attestation (issuer only).
 * 8.  getAttestationDetails(bytes32 _attestationHash): View: Retrieve details of a specific attestation.
 * 9.  getAgentAttestations(uint256 _agentId): View: Retrieve all attestations for a given Agent.
 * 10. getAttestationsByAttester(address _attester): View: Retrieve all attestations issued by an address.
 * 11. issueAttestationAsDelegate(address _delegator, uint256 _subjectAgentId, string calldata _skillKey, string calldata _value, uint256 _weight): Allows a delegate to issue an attestation on behalf of a delegator.
 *
 * // --- Reputation System (1 function) ---
 * 12. getAgentReputation(uint256 _agentId): View: Retrieve an Agent's calculated reputation score.
 *
 * // --- Essence Utility Token & Staking (6 functions) ---
 * 13. stakeETHForEssence(): Stake ETH to earn Essence over time.
 * 14. claimStakedETH(uint256 _amount): Claim previously staked ETH.
 * 15. getEssenceBalance(address _user): View: Get a user's current Essence balance.
 * 16. getStakedETH(address _user): View: Get a user's current staked ETH amount.
 * 17. calculatePendingEssence(address _user): View: Calculate Essence earned since last claim/stake.
 * 18. claimEssence(): Claim accumulated Essence from staking.
 *
 * // --- Achievement System (4 functions) ---
 * 19. defineAchievement(string calldata _achievementId, uint256 _requiredReputation, uint256 _requiredAttestationCount, string calldata _requiredSkillKey): Defines a new achievement and its unlock conditions (protocol owner only).
 * 20. checkAndUnlockAchievements(uint256 _agentId): Checks unlock conditions for all undefined achievements and unlocks them if met.
 * 21. getAchievementDefinition(string calldata _achievementId): View: Retrieve the definition of an achievement.
 * 22. getAgentAchievements(uint256 _agentId): View: Retrieve the list of achievements unlocked by an Agent.
 *
 * // --- Delegation (3 functions) ---
 * 23. grantAttestationDelegation(address _delegatee): Grants attestation issuing rights on behalf of the caller.
 * 24. revokeAttestationDelegation(address _delegatee): Revokes attestation issuing rights previously granted.
 * 25. isAttestationDelegate(address _delegator, address _delegatee): View: Check if an address is a delegate for another.
 *
 * // --- Dynamic Properties (1 function) ---
 * 26. calculateDynamicSkillScore(uint256 _agentId, string calldata _skillKey): View: Calculate a dynamic score for a specific skill based on recent attestations.
 *
 * // --- Protocol Configuration & Admin (3 functions) ---
 * 27. setAttestationCost(uint256 _newCost): Sets the Essence cost for issuing an attestation (protocol owner only).
 * 28. setEssencePerETHPerSecond(uint256 _rate): Sets the rate at which Essence is generated per staked ETH (protocol owner only).
 * 29. withdrawProtocolEssenceFees(): Withdraws accumulated Essence fees to the protocol owner (protocol owner only).
 */
contract SyntheAgentProtocol {

    // --- State Variables & Structs ---

    struct Agent {
        uint256 id;
        address owner;
        string metadataUri; // Link to off-chain metadata (e.g., JSON, image)
        uint256 reputation; // Simple cumulative reputation score
        uint256 creationTimestamp;
    }

    struct Attestation {
        bytes32 hash; // Unique identifier for the attestation
        address attester; // Address issuing the attestation
        uint256 subjectAgentId; // Agent being attested about
        string skillKey; // e.g., "Solidity Coding", "Community Management"
        string value; // e.g., "Expert", "Excellent", "Certified" (can be arbitrary string)
        uint256 weight; // Numerical weight/score given by the attester (e.g., 1-100)
        uint256 timestamp;
        bool revoked; // Flag to mark attestation as invalid
    }

    struct AchievementDefinition {
        string id; // Unique identifier for the achievement
        uint256 requiredReputation; // Minimum reputation to unlock
        uint256 requiredAttestationCount; // Minimum number of attestations to unlock
        string requiredSkillKey; // Specific skill key required (empty string if any skill counts)
        bool defined; // Helper flag to check if definition exists
    }

    uint256 private _nextTokenId; // Counter for unique Agent IDs
    address public protocolOwner;

    // Agent Data
    mapping(uint256 => Agent) public agents;
    mapping(address => uint256[]) public ownerAgents; // List of agent IDs owned by an address
    mapping(uint256 => address) public agentOwners; // Agent ID to owner mapping

    // Attestation Data
    mapping(bytes32 => Attestation) public attestations;
    mapping(uint256 => bytes32[]) public agentAttestations; // List of attestation hashes for an agent
    mapping(address => bytes32[]) public attesterAttestations; // List of attestation hashes by an attester

    // Delegation Data (Attester role delegation)
    mapping(address => mapping(address => bool)) public isAttestationDelegate; // delegator => delegatee => granted

    // Essence Utility Token & Staking Data
    uint256 public essencePerETHPerSecond; // Rate of Essence generation (scaled, e.g., 1e18 per ETH per sec)
    uint256 public attestationCost; // Cost to issue an attestation in Essence (scaled)
    mapping(address => uint256) private _essenceBalances; // User Essence balance
    mapping(address => uint256) private _stakedETH; // User staked ETH amount
    mapping(address => uint256) private _lastEssenceClaimTimestamp; // Timestamp of last claim/stake update

    uint256 public totalProtocolEssenceFees; // Accumulated Essence from attestation fees

    // Achievement Data
    mapping(string => AchievementDefinition) public achievementDefinitions; // Definition by achievement ID
    mapping(uint256 => mapping(string => bool)) public agentUnlockedAchievements; // agentId => achievementId => unlocked

    // --- Events ---

    event AgentCreated(uint256 indexed agentId, address indexed owner, string metadataUri);
    event AgentTransferred(uint256 indexed agentId, address indexed from, address indexed to);
    event AgentBurned(uint256 indexed agentId, address indexed owner);
    event AgentMetadataUpdated(uint256 indexed agentId, string metadataUri);

    event AttestationIssued(bytes32 indexed attestationHash, address indexed attester, uint256 indexed subjectAgentId, string skillKey, string value, uint256 weight);
    event AttestationRevoked(bytes32 indexed attestationHash, address indexed revoker, uint256 indexed subjectAgentId);

    event ReputationUpdated(uint256 indexed agentId, uint256 newReputation);

    event EssenceStaked(address indexed user, uint256 amountETH, uint256 newStakedBalance);
    event EssenceClaimed(address indexed user, uint256 amountEssence, uint256 newEssenceBalance);
    event EssenceBalanceUpdated(address indexed user, uint256 newBalance);

    event AttestationDelegationGranted(address indexed delegator, address indexed delegatee);
    event AttestationDelegationRevoked(address indexed delegator, address indexed delegatee);

    event AchievementDefined(string indexed achievementId, uint256 requiredReputation, uint256 requiredAttestationCount);
    event AchievementUnlocked(uint256 indexed agentId, string indexed achievementId);

    event ParameterUpdated(string parameterName, uint256 newValue);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == protocolOwner, "Only protocol owner can call this function");
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        require(agentOwners[_agentId] == msg.sender, "Only agent owner can call this function");
        _;
    }

    modifier onlyAttestationIssuer(bytes32 _attestationHash) {
        require(attestations[_attestationHash].attester == msg.sender, "Only attestation issuer can call this function");
        _;
    }

    modifier onlyDelegatorOrDelegate(address _delegator) {
        require(msg.sender == _delegator || isAttestationDelegate[_delegator][msg.sender], "Caller must be delegator or delegate");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _initialEssenceRate, uint256 _initialAttestationCost) {
        protocolOwner = msg.sender;
        essencePerETHPerSecond = _initialEssenceRate; // e.g., 1000000000000000000000000 (1000 Essence per ETH per sec, assuming 1e18 scaling for Essence)
        attestationCost = _initialAttestationCost;   // e.g., 500000000000000000000 (500 Essence)
    }

    // --- Core Agent Management ---

    /**
     * @dev Creates a new Agent and assigns it to the caller.
     * @param _metadataUri URI pointing to off-chain metadata for the agent.
     * @return The ID of the newly created agent.
     */
    function createAgent(string calldata _metadataUri) external returns (uint256) {
        uint256 agentId = _nextTokenId++;
        require(agentOwners[agentId] == address(0), "Agent ID already exists"); // Should not happen with counter

        agents[agentId] = Agent(
            agentId,
            msg.sender,
            _metadataUri,
            0, // Initial reputation
            block.timestamp
        );
        agentOwners[agentId] = msg.sender;
        ownerAgents[msg.sender].push(agentId);

        emit AgentCreated(agentId, msg.sender, _metadataUri);
        return agentId;
    }

    /**
     * @dev Transfers ownership of an Agent to a new address.
     * @param _agentId The ID of the Agent to transfer.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferAgentOwnership(uint256 _agentId, address _newOwner) external onlyAgentOwner(_agentId) {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = agentOwners[_agentId];

        // Remove from old owner's list (basic implementation, can be optimized)
        uint256[] storage oldOwnerAgents = ownerAgents[oldOwner];
        for (uint i = 0; i < oldOwnerAgents.length; i++) {
            if (oldOwnerAgents[i] == _agentId) {
                oldOwnerAgents[i] = oldOwnerAgents[oldOwnerAgents.length - 1];
                oldOwnerAgents.pop();
                break;
            }
        }

        // Add to new owner's list
        ownerAgents[_newOwner].push(_agentId);
        agentOwners[_agentId] = _newOwner;
        agents[_agentId].owner = _newOwner; // Update owner in the Agent struct itself

        emit AgentTransferred(_agentId, oldOwner, _newOwner);
    }

    /**
     * @dev Destroys an Agent and associated data (excluding attestations issued/received,
     *      which remain for historical record but linked agent is burned).
     * @param _agentId The ID of the Agent to burn.
     */
    function burnAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
         address owner = agentOwners[_agentId];

        // Basic removal from ownerAgents list
        uint256[] storage currentOwnerAgents = ownerAgents[owner];
        for (uint i = 0; i < currentOwnerAgents.length; i++) {
            if (currentOwnerAgents[i] == _agentId) {
                currentOwnerAgents[i] = currentOwnerAgents[currentOwnerAgents.length - 1];
                currentOwnerAgents.pop();
                break;
            }
        }

        delete agents[_agentId]; // Removes agent data
        delete agentOwners[_agentId]; // Removes owner mapping

        // Attestations issued by or about this agent remain, but linkage is broken

        emit AgentBurned(_agentId, owner);
    }

    /**
     * @dev Updates the metadata URI for an Agent.
     * @param _agentId The ID of the Agent.
     * @param _metadataUri The new metadata URI.
     */
    function updateAgentMetadataUri(uint256 _agentId, string calldata _metadataUri) external onlyAgentOwner(_agentId) {
        agents[_agentId].metadataUri = _metadataUri;
        emit AgentMetadataUpdated(_agentId, _metadataUri);
    }

    /**
     * @dev Retrieves the details of a specific Agent.
     * @param _agentId The ID of the Agent.
     * @return Agent struct containing details.
     */
    function getAgentDetails(uint256 _agentId) external view returns (Agent memory) {
        require(agentOwners[_agentId] != address(0), "Agent does not exist");
        return agents[_agentId];
    }

    // --- Attestation System ---

    /**
     * @dev Creates a new attestation about an Agent's skill or attribute.
     * Requires payment in Essence. Automatically updates reputation.
     * Cannot attest for self.
     * @param _subjectAgentId The ID of the Agent being attested about.
     * @param _skillKey The category of the skill/attribute (e.g., "Leadership").
     * @param _value The specific value or description (e.g., "Excellent").
     * @param _weight A numerical weight or score (e.g., 1-100).
     */
    function issueAttestation(uint256 _subjectAgentId, string calldata _skillKey, string calldata _value, uint256 _weight) external {
        // Check if subject agent exists
        require(agentOwners[_subjectAgentId] != address(0), "Subject Agent does not exist");
        // Prevent self-attestation
        require(msg.sender != agentOwners[_subjectAgentId], "Cannot attest for your own agent");

        // Pay Essence cost
        require(_essenceBalances[msg.sender] >= attestationCost, "Insufficient Essence to issue attestation");
        _essenceBalances[msg.sender] -= attestationCost;
        totalProtocolEssenceFees += attestationCost;
        emit EssenceBalanceUpdated(msg.sender, _essenceBalances[msg.sender]);

        // Create attestation hash
        bytes32 attestationHash = keccak256(abi.encodePacked(msg.sender, _subjectAgentId, _skillKey, _value, _weight, block.timestamp));

        // Store attestation data
        attestations[attestationHash] = Attestation(
            attestationHash,
            msg.sender,
            _subjectAgentId,
            _skillKey,
            _value,
            _weight,
            block.timestamp,
            false // Not revoked initially
        );

        // Link attestation to agent and attester
        agentAttestations[_subjectAgentId].push(attestationHash);
        attesterAttestations[msg.sender].push(attestationHash);

        // Update subject agent's reputation (simple cumulative sum of weights)
        agents[_subjectAgentId].reputation += _weight;
        emit ReputationUpdated(_subjectAgentId, agents[_subjectAgentId].reputation);

        emit AttestationIssued(attestationHash, msg.sender, _subjectAgentId, _skillKey, _value, _weight);
    }

    /**
     * @dev Allows an attester to revoke an attestation they previously issued.
     * Does NOT refund Essence.
     * Does NOT automatically revert reputation change (can be complex, leaving simple for now).
     * @param _attestationHash The hash of the attestation to revoke.
     */
    function revokeAttestation(bytes32 _attestationHash) external onlyAttestationIssuer(_attestationHash) {
        Attestation storage att = attestations[_attestationHash];
        require(!att.revoked, "Attestation already revoked");

        att.revoked = true;
        // Note: Reputation is NOT automatically decreased here for simplicity.
        // A more complex system might require specific logic to handle this.

        emit AttestationRevoked(_attestationHash, msg.sender, att.subjectAgentId);
    }

    /**
     * @dev Retrieves the details of a specific attestation by its hash.
     * @param _attestationHash The hash of the attestation.
     * @return Attestation struct containing details.
     */
    function getAttestationDetails(bytes32 _attestationHash) external view returns (Attestation memory) {
        require(attestations[_attestationHash].attester != address(0), "Attestation does not exist"); // Check if hash maps to data
        return attestations[_attestationHash];
    }

    /**
     * @dev Retrieves all attestation hashes associated with an Agent.
     * @param _agentId The ID of the Agent.
     * @return An array of attestation hashes.
     */
    function getAgentAttestations(uint256 _agentId) external view returns (bytes32[] memory) {
         require(agentOwners[_agentId] != address(0), "Agent does not exist");
        return agentAttestations[_agentId];
    }

     /**
     * @dev Retrieves all attestation hashes issued by a specific address.
     * @param _attester The address of the attester.
     * @return An array of attestation hashes.
     */
    function getAttestationsByAttester(address _attester) external view returns (bytes32[] memory) {
        return attesterAttestations[_attester];
    }

    /**
     * @dev Allows a delegate to issue an attestation on behalf of a delegator.
     * Delegate pays the Essence cost.
     * @param _delegator The address whose attestation rights were delegated.
     * @param _subjectAgentId The ID of the Agent being attested about.
     * @param _skillKey The category of the skill/attribute.
     * @param _value The specific value or description.
     * @param _weight A numerical weight or score.
     */
    function issueAttestationAsDelegate(address _delegator, uint256 _subjectAgentId, string calldata _skillKey, string calldata _value, uint256 _weight) external onlyDelegatorOrDelegate(_delegator) {
        require(msg.sender != _delegator, "Cannot issue as delegate for yourself if you are the delegator");
        // The rest of the logic is identical to issueAttestation, but uses _delegator as the attester
        // Check if subject agent exists
        require(agentOwners[_subjectAgentId] != address(0), "Subject Agent does not exist");
        // Prevent delegate attesting for delegator's own agent (unless specifically allowed, but simplified here)
         require(_delegator != agentOwners[_subjectAgentId], "Delegator cannot attest for their own agent via delegate"); // Prevents delegator using delegate to bypass self-attestation rule

        // Delegate pays Essence cost
        require(_essenceBalances[msg.sender] >= attestationCost, "Insufficient Essence for delegate to issue attestation");
        _essenceBalances[msg.sender] -= attestationCost;
        totalProtocolEssenceFees += attestationCost; // Fees still go to protocol
        emit EssenceBalanceUpdated(msg.sender, _essenceBalances[msg.sender]);

        // Create attestation hash (uses _delegator as the effective attester)
        bytes32 attestationHash = keccak256(abi.encodePacked(_delegator, _subjectAgentId, _skillKey, _value, _weight, block.timestamp, msg.sender)); // Include delegatee in hash to prevent hash collision if same attestation issued by delegate vs delegator

        // Store attestation data (attester is _delegator, recordedBy is msg.sender - optional field, omitting for simplicity)
        attestations[attestationHash] = Attestation(
            attestationHash,
            _delegator, // The delegator is the effective attester
            _subjectAgentId,
            _skillKey,
            _value,
            _weight,
            block.timestamp,
            false
        );

        // Link attestation to agent and attester (_delegator)
        agentAttestations[_subjectAgentId].push(attestationHash);
        attesterAttestations[_delegator].push(attestationHash); // Attestation linked to the delegator's history

        // Update subject agent's reputation
        agents[_subjectAgentId].reputation += _weight;
        emit ReputationUpdated(_subjectAgentId, agents[_subjectAgentId].reputation);

        // Log event reflecting delegation
         emit AttestationIssued(attestationHash, _delegator, _subjectAgentId, _skillKey, _value, _weight); // Log with delegator as attester
         // Could add a separate event for delegation usage if needed
    }


    // --- Reputation System ---

    /**
     * @dev Retrieves the current reputation score of an Agent.
     * Note: Simple sum of attestation weights. Revoked attestations don't decrease it in this version.
     * @param _agentId The ID of the Agent.
     * @return The Agent's current reputation score.
     */
    function getAgentReputation(uint256 _agentId) external view returns (uint256) {
         require(agentOwners[_agentId] != address(0), "Agent does not exist");
        return agents[_agentId].reputation;
    }

    // --- Essence Utility Token & Staking ---

    /**
     * @dev Calculates the amount of Essence a user has earned based on their staked ETH.
     * This is a view function and does not claim the Essence.
     * @param _user The address of the user.
     * @return The amount of pending Essence.
     */
    function calculatePendingEssence(address _user) public view returns (uint256) {
        uint256 staked = _stakedETH[_user];
        if (staked == 0 || essencePerETHPerSecond == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - _lastEssenceClaimTimestamp[_user];
        // Calculate earned Essence: staked_in_wei * essence_rate_scaled * time_elapsed / 1e18 (for ETH) / 1e18 (for scaled rate)
        // Simplifying: staked * essencePerETHPerSecond * timeElapsed / 1e36
         return (staked * essencePerETHPerSecond * timeElapsed) / (1e18 * 1e18); // Assumes Essence is 1e18 scaled
    }


    /**
     * @dev Stakes ETH to start earning Essence.
     * Automatically claims any pending Essence before staking.
     */
    function stakeETHForEssence() external payable {
        require(msg.value > 0, "Must stake more than 0 ETH");

        // Claim pending Essence before updating stake
        uint256 pendingEssence = calculatePendingEssence(msg.sender);
        _essenceBalances[msg.sender] += pendingEssence;
         _lastEssenceClaimTimestamp[msg.sender] = block.timestamp; // Update timestamp NOW before adding stake
        if (pendingEssence > 0) {
             emit EssenceClaimed(msg.sender, pendingEssence, _essenceBalances[msg.sender]);
        }

        _stakedETH[msg.sender] += msg.value;

        emit EssenceStaked(msg.sender, msg.value, _stakedETH[msg.sender]);
         emit EssenceBalanceUpdated(msg.sender, _essenceBalances[msg.sender]); // Also signal balance change
    }

    /**
     * @dev Allows a user to claim earned Essence from their staked ETH.
     */
    function claimEssence() external {
        uint256 pendingEssence = calculatePendingEssence(msg.sender);
        require(pendingEssence > 0, "No Essence earned yet");

        _essenceBalances[msg.sender] += pendingEssence;
        _lastEssenceClaimTimestamp[msg.sender] = block.timestamp;

        emit EssenceClaimed(msg.sender, pendingEssence, _essenceBalances[msg.sender]);
        emit EssenceBalanceUpdated(msg.sender, _essenceBalances[msg.sender]);
    }

    /**
     * @dev Allows a user to claim a portion of their staked ETH back.
     * Automatically claims any pending Essence before withdrawal.
     * @param _amount The amount of ETH to claim (in Wei).
     */
    function claimStakedETH(uint256 _amount) external {
        require(_stakedETH[msg.sender] >= _amount, "Insufficient staked ETH");

        // Claim pending Essence before withdrawal
        uint256 pendingEssence = calculatePendingEssence(msg.sender);
        _essenceBalances[msg.sender] += pendingEssence;
         _lastEssenceClaimTimestamp[msg.sender] = block.timestamp; // Update timestamp NOW before reducing stake
        if (pendingEssence > 0) {
             emit EssenceClaimed(msg.sender, pendingEssence, _essenceBalances[msg.sender]);
        }
        emit EssenceBalanceUpdated(msg.sender, _essenceBalances[msg.sender]); // Also signal balance change

        _stakedETH[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "ETH transfer failed");

        // No specific event for claimStakedETH, EssenceStaked event with reduced balance implies claim
    }

    /**
     * @dev Gets a user's current Essence balance.
     * Includes pending, unclaimed Essence.
     * @param _user The address of the user.
     * @return The total Essence balance (claimed + pending).
     */
    function getEssenceBalance(address _user) external view returns (uint256) {
        return _essenceBalances[_user] + calculatePendingEssence(_user);
    }

    /**
     * @dev Gets a user's current staked ETH amount.
     * @param _user The address of the user.
     * @return The amount of ETH staked (in Wei).
     */
    function getStakedETH(address _user) external view returns (uint256) {
        return _stakedETH[_user];
    }


    // --- Achievement System ---

    /**
     * @dev Defines a new achievement and its unlock criteria.
     * Only the protocol owner can define achievements.
     * Achievement ID must be unique.
     * @param _achievementId A unique identifier for the achievement.
     * @param _requiredReputation Minimum reputation needed.
     * @param _requiredAttestationCount Minimum total valid attestations needed.
     * @param _requiredSkillKey Specific skill key required in at least one attestation (empty for any).
     */
    function defineAchievement(string calldata _achievementId, uint256 _requiredReputation, uint256 _requiredAttestationCount, string calldata _requiredSkillKey) external onlyOwner {
        require(!achievementDefinitions[_achievementId].defined, "Achievement ID already defined");

        achievementDefinitions[_achievementId] = AchievementDefinition(
            _achievementId,
            _requiredReputation,
            _requiredAttestationCount,
            _requiredSkillKey,
            true
        );

        emit AchievementDefined(_achievementId, _requiredReputation, _requiredAttestationCount);
    }

     /**
     * @dev Checks an Agent's current state against all defined achievements
     * and unlocks any whose conditions are met but are not yet unlocked for this agent.
     * Can be called by anyone, but typically triggered by Agent owner or protocol.
     * @param _agentId The ID of the Agent to check.
     */
    function checkAndUnlockAchievements(uint256 _agentId) external {
        require(agentOwners[_agentId] != address(0), "Agent does not exist");

        Agent storage agent = agents[_agentId];
        uint256 currentReputation = agent.reputation;
        bytes32[] storage agentAtts = agentAttestations[_agentId];
        uint256 validAttestationCount = 0;
        // Count valid attestations and check for specific skill key
        bool hasRequiredSkillAttestation = false;
        string memory requiredSkillForCurrentCheck = ""; // Placeholder, need to loop through achievement defs
        // This requires iterating over all defined achievements to get their requirements.
        // A more efficient design might check specific achievement IDs or use a list of IDs.
        // For demonstration, we'll iterate over definitions (less gas efficient if many defs).

        // First, calculate current valid attestation count and check for required skill existence for *any* definition
        for(uint i = 0; i < agentAtts.length; i++) {
            if (!attestations[agentAtts[i]].revoked) {
                validAttestationCount++;
            }
        }

        // Now, iterate through *all* achievement definitions to check unlock conditions
        // NOTE: This approach is gas-intensive if there are many defined achievements.
        // A production system might require a mapping of achievement IDs or a linked list.
        // We'll use a simplified loop over potential string IDs for demonstration.
        // This requires knowing all possible achievement IDs, which is impractical on-chain.
        // A better approach needs a way to iterate defined keys, e.g., storing IDs in an array.

        // Let's assume for this example, we have a simple mapping and check a few known IDs.
        // In a real system, you'd need a way to iterate `achievementDefinitions` keys.
        // For demonstration, we'll just check against *all* definitions in the map
        // (this is not truly possible efficiently on-chain without iterating keys).
        // A practical approach stores achievement IDs in an array: `string[] public definedAchievementIds;`
        // Let's add that array.

        // (Self-correction: Add `definedAchievementIds` array and push to it in `defineAchievement`)

        // Add `string[] public definedAchievementIds;` as a state variable.
        // Modify `defineAchievement` to push the ID to this array.

        // Re-evaluate `checkAndUnlockAchievements` logic using the array:
        for (uint i = 0; i < definedAchievementIds.length; i++) {
            string memory achId = definedAchievementIds[i];
            AchievementDefinition memory def = achievementDefinitions[achId];

            // Check if already unlocked
            if (agentUnlockedAchievements[_agentId][achId]) {
                continue; // Skip if already unlocked
            }

            bool conditionsMet = true;

            // Check required reputation
            if (currentReputation < def.requiredReputation) {
                conditionsMet = false;
            }

            // Check required attestation count
            if (validAttestationCount < def.requiredAttestationCount) {
                conditionsMet = false;
            }

            // Check required skill key (if specified)
            if (bytes(def.requiredSkillKey).length > 0) {
                 hasRequiredSkillAttestation = false; // Reset for this definition check
                 for(uint j = 0; j < agentAtts.length; j++) {
                    if (!attestations[agentAtts[j]].revoked &&
                        keccak256(abi.encodePacked(attestations[agentAtts[j]].skillKey)) == keccak256(abi.encodePacked(def.requiredSkillKey))) {
                        hasRequiredSkillAttestation = true;
                        break; // Found required skill attestation
                    }
                 }
                 if (!hasRequiredSkillAttestation) {
                    conditionsMet = false;
                 }
            }

            // Unlock if all conditions are met
            if (conditionsMet) {
                agentUnlockedAchievements[_agentId][achId] = true;
                emit AchievementUnlocked(_agentId, achId);
            }
        }
    }

    /**
     * @dev Retrieves the definition details for a specific achievement.
     * @param _achievementId The ID of the achievement.
     * @return AchievementDefinition struct.
     */
    function getAchievementDefinition(string calldata _achievementId) external view returns (AchievementDefinition memory) {
        require(achievementDefinitions[_achievementId].defined, "Achievement not defined");
        return achievementDefinitions[_achievementId];
    }

     /**
     * @dev Retrieves the list of achievement IDs unlocked by an Agent.
     * NOTE: This requires iterating over all defined achievements to check the mapping.
     * A more efficient design might store unlocked achievement IDs in an array per agent.
     * For demonstration, we'll iterate defined achievements.
     * @param _agentId The ID of the Agent.
     * @return An array of unlocked achievement IDs.
     */
    function getAgentAchievements(uint256 _agentId) external view returns (string[] memory) {
         require(agentOwners[_agentId] != address(0), "Agent does not exist");

        string[] memory unlockedList = new string[](definedAchievementIds.length); // Max possible unlocked
        uint256 unlockedCount = 0;

        for (uint i = 0; i < definedAchievementIds.length; i++) {
            string memory achId = definedAchievementIds[i];
            if (agentUnlockedAchievements[_agentId][achId]) {
                unlockedList[unlockedCount] = achId;
                unlockedCount++;
            }
        }

        // Trim the array to the actual count
        string[] memory result = new string[](unlockedCount);
        for (uint i = 0; i < unlockedCount; i++) {
            result[i] = unlockedList[i];
        }
        return result;
    }

     string[] public definedAchievementIds; // <<-- Added this state variable

    // --- Delegation ---

    /**
     * @dev Grants the right to issue attestations on behalf of the caller to _delegatee.
     * Caller is the delegator.
     * @param _delegatee The address to grant delegation rights to.
     */
    function grantAttestationDelegation(address _delegatee) external {
        require(_delegatee != address(0), "Delegatee cannot be the zero address");
        require(_delegatee != msg.sender, "Cannot delegate to yourself");
        require(!isAttestationDelegate[msg.sender][_delegatee], "Delegation already granted");

        isAttestationDelegate[msg.sender][_delegatee] = true;
        emit AttestationDelegationGranted(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes the right to issue attestations on behalf of the caller from _delegatee.
     * Caller is the delegator.
     * @param _delegatee The address to revoke delegation rights from.
     */
    function revokeAttestationDelegation(address _delegatee) external {
        require(_delegatee != address(0), "Delegatee cannot be the zero address");
        require(isAttestationDelegate[msg.sender][_delegatee], "Delegation not granted to this address");

        isAttestationDelegate[msg.sender][_delegatee] = false;
        emit AttestationDelegationRevoked(msg.sender, _delegatee);
    }

     /**
     * @dev Checks if an address is a valid attestation delegate for another address.
     * @param _delegator The potential delegator.
     * @param _delegatee The potential delegatee.
     * @return True if _delegatee is a delegate for _delegator, false otherwise.
     */
    function isAttestationDelegate(address _delegator, address _delegatee) public view returns (bool) {
        return isAttestationDelegate[_delegator][_delegatee];
    }

    // --- Dynamic Properties ---

    /**
     * @dev Calculates a dynamic score for a specific skill key for an Agent.
     * Example implementation: Averages the weights of valid, non-revoked attestations for that skill.
     * Could be extended with recency bias, attester reputation weight, etc.
     * @param _agentId The ID of the Agent.
     * @param _skillKey The skill key to calculate the score for.
     * @return The calculated dynamic skill score.
     */
    function calculateDynamicSkillScore(uint256 _agentId, string calldata _skillKey) external view returns (uint256) {
        require(agentOwners[_agentId] != address(0), "Agent does not exist");
        bytes32[] memory agentAtts = agentAttestations[_agentId];
        uint256 totalWeight = 0;
        uint256 relevantAttestationCount = 0;

        bytes32 skillKeyHash = keccak256(abi.encodePacked(_skillKey));

        for(uint i = 0; i < agentAtts.length; i++) {
            Attestation memory att = attestations[agentAtts[i]];
            // Check if valid, non-revoked, and matches the skill key
            if (!att.revoked && keccak256(abi.encodePacked(att.skillKey)) == skillKeyHash) {
                totalWeight += att.weight;
                relevantAttestationCount++;
            }
        }

        if (relevantAttestationCount == 0) {
            return 0; // No attestations for this skill
        }

        return totalWeight / relevantAttestationCount; // Simple average
        // Potential enhancements: weighted average by attester reputation, time decay, etc.
    }


    // --- Protocol Configuration & Admin ---

    /**
     * @dev Sets the Essence cost required to issue a new attestation.
     * Only the protocol owner can call this.
     * @param _newCost The new attestation cost in Essence (scaled).
     */
    function setAttestationCost(uint256 _newCost) external onlyOwner {
        attestationCost = _newCost;
        emit ParameterUpdated("attestationCost", _newCost);
    }

    /**
     * @dev Sets the rate at which Essence is generated per staked ETH.
     * Only the protocol owner can call this.
     * Rate is scaled (e.g., 1e18 Essence per 1e18 Wei ETH per second).
     * @param _rate The new Essence per ETH per second rate.
     */
    function setEssencePerETHPerSecond(uint256 _rate) external onlyOwner {
         essencePerETHPerSecond = _rate;
         // Update last claim timestamp for all users to apply new rate correctly from now on
         // NOTE: Iterating all users is not feasible on-chain.
         // A practical system would calculate pending Essence with the *old* rate up to NOW,
         // then update timestamp, then apply the *new* rate for future.
         // The current `calculatePendingEssence` handles this implicitly by using the *current* rate.
         // Stakers need to `claimEssence()` before the rate change to lock in earnings at the old rate.
         // A more robust system might track timestamps per stake/rate change.
         // For simplicity here, we just update the rate.
         emit ParameterUpdated("essencePerETHPerSecond", _rate);
    }

    /**
     * @dev Allows the protocol owner to withdraw accumulated Essence fees.
     * @return The amount of Essence withdrawn.
     */
    function withdrawProtocolEssenceFees() external onlyOwner returns (uint256) {
        uint256 fees = totalProtocolEssenceFees;
        require(fees > 0, "No Essence fees accumulated");

        _essenceBalances[protocolOwner] += fees; // Transfer fees to owner's balance
        totalProtocolEssenceFees = 0;

        emit EssenceBalanceUpdated(protocolOwner, _essenceBalances[protocolOwner]);
        // Could add a specific event for fee withdrawal if needed
        return fees;
    }

    // --- View Functions ---

     /**
     * @dev Returns the total number of Agents created.
     * @return The total count of Agents.
     */
    function getTotalAgents() external view returns (uint256) {
        return _nextTokenId; // Counter indicates total minted (even if burned)
    }

    /**
     * @dev Retrieves the list of Agent IDs owned by a specific address.
     * @param _owner The address to check.
     * @return An array of Agent IDs.
     */
    function getAgentsByOwner(address _owner) external view returns (uint256[] memory) {
        return ownerAgents[_owner];
    }


     /**
     * @dev Gets the current protocol parameters.
     * @return attestationCost The current cost to issue an attestation in Essence.
     * @return essencePerETHPerSecond The rate of Essence generation per staked ETH per second.
     * @return totalProtocolEssenceFees The total accumulated Essence fees.
     */
    function getProtocolParameters() external view returns (uint256, uint256, uint256) {
        return (attestationCost, essencePerETHPerSecond, totalProtocolEssenceFees);
    }

    // Fallback function to allow receiving ETH for staking
    receive() external payable {
        stakeETHForEssence();
    }
}
```