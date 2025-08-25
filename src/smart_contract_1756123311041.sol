Here's a Solidity smart contract named `QuantumCanvasProtocol` that embodies interesting, advanced, creative, and trendy concepts like Decentralized Autonomous Agents (DAAs), Soulbound Attributes (SBAs), a dynamic reputation system, and on-chain identity management.

It avoids direct duplication of popular open-source contracts by integrating these concepts uniquely into a single, cohesive protocol. For instance, while it has SBA functionality, it doesn't strictly adhere to an ERC-721 interface but implements the core non-transferable logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
// Note: IERC721Receiver is generally used for contracts that *receive* ERC721 tokens.
// Since SBAs are non-transferable, this specific import is not strictly necessary for SBAs themselves.
// It might be useful if the protocol were to interact with *other* ERC721 tokens,
// but for the scope of this contract, we'll omit it to keep it focused on the unique aspects.

/**
 * @title QuantumCanvasProtocol
 * @author [Your Name/Alias]
 * @notice A decentralized autonomous agent (DAA) framework for dynamic digital identity and on-chain action orchestration.
 *         This protocol enables the creation of unique Decentralized Identifiers (DIDs), the issuance of
 *         non-transferable Soulbound Attributes (SBAs) representing reputation and achievements, and the
 *         deployment of automated agents (DAAs) that perform on-chain actions based on predefined rules.
 *         It also includes a foundational reputation system and a light governance mechanism, influenced by DIDs and SBAs.
 *
 * @dev This contract demonstrates advanced concepts by combining identity, reputation, and on-chain automation.
 *      Key features include:
 *      - **Decentralized Identifiers (DIDs):** Unique on-chain profiles for addresses.
 *      - **Soulbound Attributes (SBAs):** Non-transferable tokens (similar in spirit to Soulbound Tokens) that
 *        represent verifiable credentials, achievements, or contributions, tied directly to a DID.
 *      - **Decentralized Autonomous Agents (DAAs):** User-defined, rule-based automated on-chain executors.
 *        These agents can be funded and configured to perform specific actions on whitelisted external modules
 *        when predefined on-chain conditions are met.
 *      - **Reputation System:** Quantifies user standing based on their accumulated SBAs and DAA activity,
 *        influencing governance power.
 *      - **Adaptive Governance:** A simple proposal and voting system where vote weight is determined by a user's
 *        reputation score derived from their DIDs and SBAs.
 */
contract QuantumCanvasProtocol is Ownable {

    // --- Outline and Function Summary ---
    // This section provides a high-level overview of the contract's structure and the purpose of each public/external function.

    // I. Core Protocol Management (Owner/Trusted Roles)
    //    Functions primarily for the contract owner or explicitly trusted entities to manage core protocol settings.
    //    These ensure the integrity and evolution of the QuantumCanvas ecosystem.
    // 1. setTrustedIssuer(address issuerAddress, bool isTrusted):
    //    Grants or revokes the permission for an address to issue Soulbound Attributes (SBAs). Only callable by the contract owner.
    // 2. getTrustedIssuers():
    //    (Conceptual, for a real dapp; in Solidity, iterating through all mapping keys is not efficient.
    //    A helper function to check specific address's trusted status is usually used.)
    // 3. registerAgentModule(string calldata moduleName, address moduleAddress):
    //    Whitelists external contracts (modules) that Decentralized Autonomous Agents (DAAs) are allowed to interact with.
    //    This is a critical security measure to prevent agents from calling malicious contracts.
    // 4. deregisterAgentModule(string calldata moduleName):
    //    Removes an agent module from the whitelist.
    // 5. renounceOwnership():
    //    Inherited from OpenZeppelin's Ownable. Transfers ownership of the contract to the zero address, making it unowned.
    // 6. transferOwnership(address newOwner):
    //    Inherited from OpenZeppelin's Ownable. Transfers ownership of the contract to a new address.

    // II. Decentralized Identity (DID) & Profile Management
    //     Functions for users to create and manage their on-chain decentralized identities.
    // 7. registerDID():
    //    Allows the caller to register a new, unique Decentralized Identifier for their address.
    // 8. updateDIDProfile(string calldata profileIPFSHash):
    //    Updates the metadata (e.g., an IPFS hash pointing to a richer profile document) associated with the caller's DID.
    // 9. getDIDProfile(address owner):
    //    Retrieves the IPFS hash of the profile document for a given DID owner's address.
    // 10. getDIDId(address owner):
    //     Retrieves the unique numerical DID ID assigned to a specific address.

    // III. Soulbound Attributes (SBAs) - Non-Transferable Tokens
    //      Functions for issuing, managing, and querying non-transferable on-chain attributes (SBAs).
    // 11. issueSBA(address recipient, string calldata attributeType, uint256 value, string calldata uri):
    //     Issues a new Soulbound Attribute (SBA) to a specified recipient. Only callable by trusted issuers.
    // 12. revokeSBA(uint256 attributeId):
    //     Revokes an existing Soulbound Attribute. Can be called by the original issuer or the SBA owner.
    // 13. querySBAs(address owner):
    //     Returns an array of all SBA IDs held by a specific DID owner.
    // 14. getSBADetails(uint256 attributeId):
    //     Retrieves detailed information (owner, type, value, URI, issuer, revocation status) about a specific SBA.

    // IV. Decentralized Autonomous Agents (DAAs)
    //     Functions allowing users to create, configure, fund, and manage automated agents that perform on-chain actions.
    // 15. createAgent(string calldata agentName):
    //     Creates a new Decentralized Autonomous Agent (DAA) for the caller, with an initial Ether deposit provided in `msg.value`.
    // 16. addAgentRule(uint256 agentId, address targetModule, bytes calldata callData, string calldata conditionType, bytes calldata conditionParams):
    //     Adds a new rule to an existing DAA. Rules define specific on-chain conditions and the action (target module + calldata)
    //     to be executed when those conditions are met.
    // 17. removeAgentRule(uint256 agentId, uint256 ruleId):
    //     Removes a specific rule from an existing DAA.
    // 18. fundAgent(uint256 agentId):
    //     Deposits more Ether into an agent's balance to cover future execution costs.
    // 19. withdrawAgentFunds(uint256 agentId, uint256 amount):
    //     Allows the agent owner to withdraw unspent Ether from their agent's balance.
    // 20. updateAgentRule(uint256 agentId, uint256 ruleId, address newTargetModule, bytes calldata newCallData, string calldata newConditionType, bytes calldata newConditionParams):
    //     Modifies the parameters of an existing rule for a DAA.
    // 21. pauseAgent(uint256 agentId):
    //     Temporarily suspends an agent, preventing any of its rules from being triggered.
    // 22. resumeAgent(uint256 agentId):
    //     Resumes a paused agent, allowing its rules to be triggered again.
    // 23. triggerAgentRule(uint256 agentId, uint256 ruleId):
    //     Publicly callable function that attempts to execute a *specific rule* of an agent. It checks if the rule's
    //     conditions are met and, if so, executes the defined action, potentially consuming agent funds.
    // 24. getAgentStatus(uint256 agentId):
    //     Retrieves the current status and detailed information (owner, name, balance, paused status, associated rule IDs, creation time)
    //     of a specific agent.

    // V. Reputation & Governance
    //    Functions for calculating on-chain reputation and participating in protocol-level governance.
    // 25. calculateReputation(address owner):
    //     Calculates an on-chain reputation score for a DID owner. This score is derived from their accumulated SBAs
    //     (e.g., by type and value) and potentially their DAA activity.
    // 26. proposeProtocolUpgrade(string calldata proposalIPFSHash):
    //     Allows eligible DID owners (those with sufficient reputation) to create a new governance proposal.
    //     The proposal details are stored off-chain via an IPFS hash.
    // 27. voteOnProposal(uint256 proposalId, bool support):
    //     Allows DID owners to cast a vote on an active proposal. The weight of their vote is directly
    //     influenced by their calculated on-chain reputation.
    // 28. executeProposal(uint256 proposalId):
    //     Can be called after the voting period ends. If the proposal has passed (more 'for' than 'against' votes),
    //     it marks the proposal as executed. (Actual on-chain logic modification would typically involve
    //     a separate upgradeable proxy pattern or specific ABI-encoded instructions in the proposal itself).
    // 29. getProposalDetails(uint256 proposalId):
    //     Retrieves all relevant information about a specific governance proposal, including vote counts and status.

    // --- Events ---
    event DIDRegistered(address indexed owner, uint256 didId, string profileIPFSHash);
    event DIDProfileUpdated(address indexed owner, uint256 didId, string newProfileIPFSHash);
    event SBDIssued(address indexed recipient, uint256 indexed sbaId, string attributeType, uint256 value, string uri);
    event SBDRevoked(uint256 indexed sbaId, address indexed owner);
    event AgentCreated(address indexed owner, uint256 indexed agentId, string agentName, uint256 initialDeposit);
    event AgentFunded(uint256 indexed agentId, address indexed funder, uint256 amount);
    event AgentFundsWithdrawn(uint256 indexed agentId, address indexed owner, uint256 amount);
    event AgentRuleAdded(uint256 indexed agentId, uint256 indexed ruleId, string conditionType);
    event AgentRuleRemoved(uint256 indexed agentId, uint256 indexed ruleId);
    event AgentRuleUpdated(uint256 indexed agentId, uint256 indexed ruleId);
    event AgentPaused(uint256 indexed agentId);
    event AgentResumed(uint256 indexed agentId);
    event AgentRuleTriggered(uint256 indexed agentId, uint256 indexed ruleId, address indexed executor);
    event TrustedIssuerSet(address indexed issuer, bool isTrusted);
    event AgentModuleRegistered(string moduleName, address indexed moduleAddress);
    event AgentModuleDeregistered(string moduleName, address indexed moduleAddress);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string proposalIPFSHash);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- State Variables ---

    // DID Management
    uint256 private nextDidId; // Counter for next DID ID
    mapping(address => uint256) public dids; // address -> didId (0 if no DID)
    mapping(uint256 => address) public didOwners; // didId -> address
    mapping(uint256 => string) public didProfiles; // didId -> IPFS hash of profile metadata

    // SBA Management (Soulbound Attributes - non-transferable)
    struct SBA {
        address owner; // Address of the DID owner
        string attributeType; // e.g., "VerifiedContributor", "CommunityMember", "Developer"
        uint256 value; // A quantitative score or weight for the attribute
        string uri; // IPFS URI for extended metadata or badge image
        uint256 issuerDidId; // DID ID of the issuer
        bool revoked; // True if the SBA has been revoked
    }
    uint256 private nextSbaId; // Counter for next SBA ID
    mapping(uint256 => SBA) public sbas; // sbaId -> SBA struct
    mapping(address => uint256[]) public ownerSBAs; // owner address -> list of SBA IDs
    mapping(address => bool) public trustedIssuers; // address -> true if authorized to issue SBAs

    // Agent Management
    struct Agent {
        address owner; // Address of the agent creator/owner
        string name; // User-defined name for the agent
        uint256 balance; // Ether balance available for agent operations
        bool paused; // If true, agent rules cannot be triggered
        uint256[] ruleIds; // List of rule IDs associated with this agent
        uint256 createdAt; // Timestamp of agent creation
    }
    struct AgentRule {
        address targetModule; // Whitelisted contract address for the action
        bytes callData;       // ABI-encoded function call (function selector + arguments)
        string conditionType; // Identifier for the condition logic (e.g., "isTimeElapsed", "isBalanceAbove", "isSBAOwner")
        bytes conditionParams; // ABI-encoded parameters for the condition check function
        uint256 lastExecution; // Timestamp of the last successful execution of this rule
        bool active;           // Whether the rule is currently active within the agent
    }
    uint256 private nextAgentId; // Counter for next Agent ID
    mapping(uint256 => Agent) public agents; // agentId -> Agent struct
    mapping(address => uint256[]) public ownerAgents; // owner address -> list of Agent IDs
    uint256 private nextAgentRuleId; // Counter for next AgentRule ID
    mapping(uint256 => AgentRule) public agentRules; // ruleId -> AgentRule struct
    mapping(string => address) public agentModules; // moduleName -> moduleAddress (Whitelisted modules)
    mapping(address => string) public agentModuleNames; // moduleAddress -> moduleName (Reverse lookup for validation)

    // Governance
    struct Proposal {
        address proposer; // DID owner who submitted the proposal
        string proposalIPFSHash; // IPFS hash for detailed proposal document
        uint256 votingStartTime; // Timestamp when voting begins
        uint256 votingEndTime; // Timestamp when voting ends
        uint256 forVotes; // Total reputation-weighted votes in favor
        uint256 againstVotes; // Total reputation-weighted votes against
        bool executed; // True if the proposal has been processed (regardless of outcome)
        bool passed; // True if forVotes > againstVotes after voting ends
        mapping(address => bool) hasVoted; // voter address -> true if they have voted on this proposal
    }
    uint256 private nextProposalId; // Counter for next Proposal ID
    mapping(uint256 => Proposal) public proposals; // proposalId -> Proposal struct
    uint256 public constant VOTING_PERIOD = 7 days; // Example: Proposals are open for 7 days
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 1000; // Example: Minimum reputation score to submit a proposal

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Modifiers ---
    modifier onlyTrustedIssuer() {
        require(trustedIssuers[msg.sender], "QCP: Caller is not a trusted issuer");
        _;
    }

    modifier onlyDIDOwner(uint256 didId_) {
        require(dids[msg.sender] == didId_, "QCP: Not the DID owner");
        _;
    }

    modifier onlyAgentOwner(uint256 agentId_) {
        require(agents[agentId_].owner == msg.sender, "QCP: Not the agent owner");
        _;
    }

    // --- I. Core Protocol Management ---

    /**
     * @notice Grants or revokes the permission for an address to issue Soulbound Attributes (SBAs).
     * @dev Only callable by the contract owner.
     * @param issuerAddress The address to grant or revoke trusted issuer status.
     * @param isTrusted True to grant, false to revoke.
     */
    function setTrustedIssuer(address issuerAddress, bool isTrusted) public onlyOwner {
        trustedIssuers[issuerAddress] = isTrusted;
        emit TrustedIssuerSet(issuerAddress, isTrusted);
    }

    /**
     * @notice This function is a conceptual placeholder. In Solidity, directly returning all keys from a mapping is not efficient or possible.
     * @dev For practical use, you'd check `trustedIssuers[address]` directly or maintain an iterable list off-chain.
     * @return A placeholder empty array.
     */
    function getTrustedIssuers() public pure returns (address[] memory) {
        // In a real application, you might use an iterable mapping (e.g., from OpenZeppelin)
        // or query individual addresses. For this example, we return an empty array.
        return new address[](0);
    }

    /**
     * @notice Whitelists an external contract module that DAAs can interact with.
     * @dev Ensures that agents only interact with approved, safe contracts. Only callable by the contract owner.
     * @param moduleName A unique identifier name for the module (e.g., "DEXModule", "LendingPool").
     * @param moduleAddress The address of the external contract to whitelist.
     */
    function registerAgentModule(string calldata moduleName, address moduleAddress) public onlyOwner {
        require(moduleAddress != address(0), "QCP: Module address cannot be zero");
        require(agentModules[moduleName] == address(0), "QCP: Module name already registered");
        require(bytes(agentModuleNames[moduleAddress]).length == 0, "QCP: Module address already registered"); // Check reverse mapping too

        agentModules[moduleName] = moduleAddress;
        agentModuleNames[moduleAddress] = moduleName;
        emit AgentModuleRegistered(moduleName, moduleAddress);
    }

    /**
     * @notice Removes a whitelisted agent module.
     * @dev Only callable by the contract owner.
     * @param moduleName The name of the module to deregister.
     */
    function deregisterAgentModule(string calldata moduleName) public onlyOwner {
        address moduleAddress = agentModules[moduleName];
        require(moduleAddress != address(0), "QCP: Module name not registered");

        delete agentModules[moduleName];
        delete agentModuleNames[moduleAddress];
        emit AgentModuleDeregistered(moduleName, moduleAddress);
    }

    // --- II. Decentralized Identity (DID) & Profile Management ---

    /**
     * @notice Registers a new unique Decentralized Identifier (DID) for the caller's address.
     * @dev An address can only register one DID.
     */
    function registerDID() public {
        require(dids[msg.sender] == 0, "QCP: Address already has a DID");

        uint256 didId = ++nextDidId;
        dids[msg.sender] = didId;
        didOwners[didId] = msg.sender;
        emit DIDRegistered(msg.sender, didId, ""); // Initial profile is empty
    }

    /**
     * @notice Updates the metadata (e.g., an IPFS hash of a profile document) associated with the caller's DID.
     * @param profileIPFSHash The IPFS hash pointing to the DID's profile document.
     */
    function updateDIDProfile(string calldata profileIPFSHash) public {
        uint256 didId = dids[msg.sender];
        require(didId != 0, "QCP: Address does not have a DID");

        didProfiles[didId] = profileIPFSHash;
        emit DIDProfileUpdated(msg.sender, didId, profileIPFSHash);
    }

    /**
     * @notice Retrieves the profile IPFS hash for a given DID owner's address.
     * @param owner The address of the DID owner.
     * @return The IPFS hash of the profile document.
     */
    function getDIDProfile(address owner) public view returns (string memory) {
        uint256 didId = dids[owner];
        require(didId != 0, "QCP: Address does not have a DID");
        return didProfiles[didId];
    }

    /**
     * @notice Retrieves the unique numerical DID ID for a given address.
     * @param owner The address of the DID owner.
     * @return The DID ID. Returns 0 if no DID is registered for the address.
     */
    function getDIDId(address owner) public view returns (uint256) {
        return dids[owner];
    }

    // --- III. Soulbound Attributes (SBAs) ---

    /**
     * @notice Issues a new Soulbound Attribute (SBA) to a recipient.
     * @dev SBAs are non-transferable and tied to the recipient's DID. Only callable by trusted issuers.
     * @param recipient The address that will own the SBA. Must have a registered DID.
     * @param attributeType A string describing the type of attribute (e.g., "VerifiedContributor").
     * @param value A numerical value associated with the attribute (e.g., contribution score).
     * @param uri IPFS URI for extended metadata or visual representation of the SBA.
     * @return The unique ID of the newly issued SBA.
     */
    function issueSBA(address recipient, string calldata attributeType, uint256 value, string calldata uri)
        public
        onlyTrustedIssuer
        returns (uint256)
    {
        require(dids[recipient] != 0, "QCP: Recipient does not have a DID");
        uint256 issuerDidId = dids[msg.sender];
        require(issuerDidId != 0, "QCP: Issuer does not have a DID");

        uint256 sbaId = ++nextSbaId;
        sbas[sbaId] = SBA({
            owner: recipient,
            attributeType: attributeType,
            value: value,
            uri: uri,
            issuerId: issuerDidId,
            revoked: false
        });
        ownerSBAs[recipient].push(sbaId);

        emit SBDIssued(recipient, sbaId, attributeType, value, uri);
        return sbaId;
    }

    /**
     * @notice Revokes an existing Soulbound Attribute (SBA).
     * @dev Can be called by the original issuer or the SBA owner. Revoked SBAs cannot be used for reputation or other purposes.
     * @param attributeId The unique ID of the SBA to revoke.
     */
    function revokeSBA(uint256 attributeId) public {
        SBA storage sba = sbas[attributeId];
        require(sba.owner != address(0), "QCP: SBA does not exist");
        require(!sba.revoked, "QCP: SBA already revoked");

        // Only the original issuer (via their DID) or the SBA owner can revoke
        require(dids[msg.sender] == sba.issuerId || msg.sender == sba.owner, "QCP: Not authorized to revoke SBA");

        sba.revoked = true;
        emit SBDRevoked(attributeId, sba.owner);
    }

    /**
     * @notice Returns a list of all non-revoked Soulbound Attributes (SBAs) held by a specific DID owner.
     * @param owner The address of the DID owner.
     * @return An array of SBA IDs.
     */
    function querySBAs(address owner) public view returns (uint256[] memory) {
        // This returns all SBA IDs, including revoked ones.
        // The DApp or `calculateReputation` should filter for `!sbas[sbaId].revoked`.
        return ownerSBAs[owner];
    }

    /**
     * @notice Retrieves detailed information about a specific Soulbound Attribute (SBA).
     * @param attributeId The unique ID of the SBA.
     * @return The owner, attribute type, value, URI, issuer's DID ID, and revocation status of the SBA.
     */
    function getSBADetails(uint256 attributeId)
        public
        view
        returns (
            address owner,
            string memory attributeType,
            uint256 value,
            string memory uri,
            uint256 issuerDidId,
            bool revoked
        )
    {
        SBA storage sba = sbas[attributeId];
        require(sba.owner != address(0), "QCP: SBA does not exist"); // Check if SBA exists
        return (sba.owner, sba.attributeType, sba.value, sba.uri, sba.issuerDidId, sba.revoked);
    }

    // --- IV. Decentralized Autonomous Agents (DAAs) ---

    /**
     * @notice Creates a new Decentralized Autonomous Agent (DAA) for the caller.
     * @dev The agent is created with an initial Ether deposit from `msg.value`, which will be used to cover execution costs.
     *      The caller must have a registered DID.
     * @param agentName A user-defined name for the agent.
     * @return The unique ID of the newly created agent.
     */
    function createAgent(string calldata agentName) public payable returns (uint256) {
        require(dids[msg.sender] != 0, "QCP: Agent owner must have a DID");
        require(msg.value > 0, "QCP: Initial deposit must be greater than zero");

        uint256 agentId = ++nextAgentId;
        agents[agentId] = Agent({
            owner: msg.sender,
            name: agentName,
            balance: msg.value,
            paused: false,
            ruleIds: new uint256[](0), // No rules initially
            createdAt: block.timestamp
        });
        ownerAgents[msg.sender].push(agentId);

        emit AgentCreated(msg.sender, agentId, agentName, msg.value);
        return agentId;
    }

    /**
     * @notice Adds a new rule to an existing DAA.
     * @dev Rules define conditions for execution and the target action. Only callable by the agent owner.
     * @param agentId The ID of the agent to add the rule to.
     * @param targetModule The address of the whitelisted external module the rule will interact with.
     * @param callData ABI-encoded function call for the `targetModule`.
     * @param conditionType A string identifying the type of condition to check (e.g., "isTimeElapsed", "isBalanceAbove").
     * @param conditionParams ABI-encoded parameters for the `conditionType` (e.g., interval for time, address/threshold for balance).
     * @return The unique ID of the newly added rule.
     */
    function addAgentRule(
        uint256 agentId,
        address targetModule,
        bytes calldata callData,
        string calldata conditionType,
        bytes calldata conditionParams
    ) public onlyAgentOwner(agentId) returns (uint256) {
        require(targetModule != address(0), "QCP: Target module cannot be zero address");
        // Ensure module is whitelisted for security
        require(bytes(agentModuleNames[targetModule]).length > 0, "QCP: Target module is not whitelisted");
        
        // Basic check for common condition types, can be expanded to a registry or enum
        bytes32 conditionTypeHash = keccak256(abi.encodePacked(conditionType));
        require(
            conditionTypeHash == keccak256(abi.encodePacked("isTimeElapsed")) ||
            conditionTypeHash == keccak256(abi.encodePacked("isBalanceAbove")) ||
            conditionTypeHash == keccak256(abi.encodePacked("isSBAOwner")),
            "QCP: Invalid or unsupported condition type"
        );

        uint256 ruleId = ++nextAgentRuleId;
        agentRules[ruleId] = AgentRule({
            targetModule: targetModule,
            callData: callData,
            conditionType: conditionType,
            conditionParams: conditionParams,
            lastExecution: 0, // Never executed initially
            active: true
        });
        agents[agentId].ruleIds.push(ruleId);

        emit AgentRuleAdded(agentId, ruleId, conditionType);
        return ruleId;
    }

    /**
     * @notice Removes a specific rule from an existing DAA.
     * @dev Only callable by the agent owner.
     * @param agentId The ID of the agent.
     * @param ruleId The ID of the rule to remove.
     */
    function removeAgentRule(uint256 agentId, uint256 ruleId) public onlyAgentOwner(agentId) {
        Agent storage agent = agents[agentId];
        bool found = false;
        for (uint256 i = 0; i < agent.ruleIds.length; i++) {
            if (agent.ruleIds[i] == ruleId) {
                // Remove ruleId from the array by swapping with the last element and popping
                agent.ruleIds[i] = agent.ruleIds[agent.ruleIds.length - 1];
                agent.ruleIds.pop();
                found = true;
                break;
            }
        }
        require(found, "QCP: Rule not found in agent");
        delete agentRules[ruleId]; // Completely delete the rule data from storage

        emit AgentRuleRemoved(agentId, ruleId);
    }

    /**
     * @notice Deposits more Ether into an agent's balance.
     * @dev Any address can fund an agent.
     * @param agentId The ID of the agent to fund.
     */
    function fundAgent(uint256 agentId) public payable {
        Agent storage agent = agents[agentId];
        require(agent.owner != address(0), "QCP: Agent does not exist");
        require(msg.value > 0, "QCP: Must send value to fund agent");

        agent.balance += msg.value;
        emit AgentFunded(agentId, msg.sender, msg.value);
    }

    /**
     * @notice Allows the agent owner to withdraw unspent Ether from their agent's balance.
     * @dev Only callable by the agent owner.
     * @param agentId The ID of the agent.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawAgentFunds(uint256 agentId, uint256 amount) public onlyAgentOwner(agentId) {
        Agent storage agent = agents[agentId];
        require(agent.balance >= amount, "QCP: Insufficient agent balance");

        agent.balance -= amount;
        payable(msg.sender).transfer(amount); // Transfer Ether to the owner
        emit AgentFundsWithdrawn(agentId, msg.sender, amount);
    }

    /**
     * @notice Modifies the parameters of an existing rule for a DAA.
     * @dev Only callable by the agent owner.
     * @param agentId The ID of the agent.
     * @param ruleId The ID of the rule to update.
     * @param newTargetModule The new address of the whitelisted external module.
     * @param newCallData The new ABI-encoded function call.
     * @param newConditionType The new condition type string.
     * @param newConditionParams The new ABI-encoded parameters for the condition.
     */
    function updateAgentRule(
        uint256 agentId,
        uint256 ruleId,
        address newTargetModule,
        bytes calldata newCallData,
        string calldata newConditionType,
        bytes calldata newConditionParams
    ) public onlyAgentOwner(agentId) {
        AgentRule storage rule = agentRules[ruleId];
        require(rule.active, "QCP: Rule is not active or does not exist");
        
        // Ensure new target module is whitelisted
        require(bytes(agentModuleNames[newTargetModule]).length > 0, "QCP: New target module is not whitelisted");

        // Basic check for new condition type
        bytes32 newConditionTypeHash = keccak256(abi.encodePacked(newConditionType));
        require(
            newConditionTypeHash == keccak256(abi.encodePacked("isTimeElapsed")) ||
            newConditionTypeHash == keccak256(abi.encodePacked("isBalanceAbove")) ||
            newConditionTypeHash == keccak256(abi.encodePacked("isSBAOwner")),
            "QCP: Invalid or unsupported new condition type"
        );

        rule.targetModule = newTargetModule;
        rule.callData = newCallData;
        rule.conditionType = newConditionType;
        rule.conditionParams = newConditionParams;

        emit AgentRuleUpdated(agentId, ruleId);
    }

    /**
     * @notice Temporarily suspends an agent, preventing any of its rules from being triggered.
     * @dev Only callable by the agent owner.
     * @param agentId The ID of the agent to pause.
     */
    function pauseAgent(uint256 agentId) public onlyAgentOwner(agentId) {
        agents[agentId].paused = true;
        emit AgentPaused(agentId);
    }

    /**
     * @notice Resumes a paused agent, allowing its rules to be triggered again.
     * @dev Only callable by the agent owner.
     * @param agentId The ID of the agent to resume.
     */
    function resumeAgent(uint256 agentId) public onlyAgentOwner(agentId) {
        agents[agentId].paused = false;
        emit AgentResumed(agentId);
    }

    /**
     * @dev Internal helper function to check various types of rule conditions.
     *      This function can be extended to support more complex on-chain conditions or oracle integrations.
     * @param agentId The ID of the agent (used for context in conditions like agent balance).
     * @param ruleId The ID of the rule.
     * @param rule The `AgentRule` struct containing the condition details.
     * @return True if the condition is met, false otherwise.
     */
    function _checkCondition(
        uint256 agentId, // Not explicitly used for all current conditions but useful for agent-specific checks
        uint256 ruleId, // Not explicitly used for all current conditions but useful for rule-specific state.
        AgentRule storage rule
    ) internal view returns (bool) {
        bytes32 conditionTypeHash = keccak256(abi.encodePacked(rule.conditionType));

        if (conditionTypeHash == keccak256(abi.encodePacked("isTimeElapsed"))) {
            // conditionParams: uint256 interval (seconds)
            (uint256 interval) = abi.decode(rule.conditionParams, (uint256));
            return block.timestamp >= rule.lastExecution + interval;
        } else if (conditionTypeHash == keccak256(abi.encodePacked("isBalanceAbove"))) {
            // conditionParams: address targetAddress, uint256 threshold
            (address targetAddress, uint256 threshold) = abi.decode(rule.conditionParams, (address, uint256));
            return targetAddress.balance > threshold;
        } else if (conditionTypeHash == keccak256(abi.encodePacked("isSBAOwner"))) {
            // conditionParams: address targetOwner, uint256 sbaAttributeId
            (address targetOwner, uint256 sbaAttributeId) = abi.decode(rule.conditionParams, (address, uint256));
            SBA storage sba = sbas[sbaAttributeId];
            return sba.owner == targetOwner && !sba.revoked;
        }
        // TODO: Implement more complex conditions here, e.g., price feeds from whitelisted oracle modules,
        // specific state checks in other whitelisted contracts, etc.
        return false; // Unknown or unsupported condition type
    }

    /**
     * @notice Publicly callable function to attempt to execute a *specific rule* of an agent.
     * @dev This function is intended to be called by external keeper networks or anyone monitoring on-chain conditions.
     *      It verifies that the agent is active, the rule belongs to the agent, the rule's conditions are met,
     *      and then attempts to execute the rule's defined action.
     * @param agentId The ID of the agent whose rule is to be triggered.
     * @param ruleId The ID of the specific rule to attempt to trigger.
     */
    function triggerAgentRule(uint256 agentId, uint256 ruleId) public {
        Agent storage agent = agents[agentId];
        require(agent.owner != address(0), "QCP: Agent does not exist");
        require(!agent.paused, "QCP: Agent is paused");

        AgentRule storage rule = agentRules[ruleId];
        require(rule.active, "QCP: Rule is not active or does not exist");

        // Verify that the rule actually belongs to this agent
        bool ruleFoundInAgent = false;
        for (uint256 i = 0; i < agent.ruleIds.length; i++) {
            if (agent.ruleIds[i] == ruleId) {
                ruleFoundInAgent = true;
                break;
            }
        }
        require(ruleFoundInAgent, "QCP: Rule does not belong to this agent");

        // Check if the rule's condition is met
        require(_checkCondition(agentId, ruleId, rule), "QCP: Rule condition not met");

        // Execute the defined action on the target module
        // A real system might:
        // 1. Charge gas from agent.balance for keeper reward.
        // 2. Pass value to the targetModule if the action requires it (e.g., token swap).
        // For simplicity, we assume the action is a non-payable call and gas is covered by the caller.
        (bool success, bytes memory result) = rule.targetModule.call(rule.callData); 
        
        // Revert if the external call fails
        require(success, string(abi.encodePacked("QCP: Agent rule execution failed: ", result)));

        rule.lastExecution = block.timestamp; // Update last execution time to prevent re-triggering within interval
        emit AgentRuleTriggered(agentId, ruleId, msg.sender);
    }

    /**
     * @notice Retrieves the current status and details of a specific agent.
     * @param agentId The ID of the agent.
     * @return The owner, name, balance, paused status, associated rule IDs, and creation timestamp of the agent.
     */
    function getAgentStatus(uint256 agentId)
        public
        view
        returns (
            address owner,
            string memory name,
            uint256 balance,
            bool paused,
            uint256[] memory ruleIds,
            uint256 createdAt
        )
    {
        Agent storage agent = agents[agentId];
        require(agent.owner != address(0), "QCP: Agent does not exist");
        return (agent.owner, agent.name, agent.balance, agent.paused, agent.ruleIds, agent.createdAt);
    }

    // --- V. Reputation & Governance ---

    /**
     * @notice Calculates an on-chain reputation score for a DID owner.
     * @dev The score is a weighted sum based on the owner's non-revoked Soulbound Attributes (SBAs)
     *      and their active Decentralized Autonomous Agents (DAAs).
     * @param owner The address of the DID owner.
     * @return The calculated reputation score. Returns 0 if no DID is registered for the address.
     */
    function calculateReputation(address owner) public view returns (uint256) {
        uint256 totalReputation = 0;
        uint256 didId = dids[owner];

        if (didId == 0) {
            return 0; // No DID, no reputation
        }

        // Reputation from SBAs
        uint256[] memory sbaIds = ownerSBAs[owner];
        for (uint256 i = 0; i < sbaIds.length; i++) {
            SBA storage sba = sbas[sbaIds[i]];
            if (!sba.revoked) {
                // Example weighting: Different SBA types contribute differently
                bytes32 attributeTypeHash = keccak256(abi.encodePacked(sba.attributeType));
                if (attributeTypeHash == keccak256(abi.encodePacked("VerifiedContributor"))) {
                    totalReputation += sba.value * 2; // Higher weight for core contributors
                } else if (attributeTypeHash == keccak256(abi.encodePacked("CommunityMember"))) {
                    totalReputation += sba.value; // Standard weight for community members
                } else {
                    totalReputation += sba.value / 2; // Default lower weight for other types
                }
            }
        }

        // Reputation from Agent activity (e.g., each active agent adds a base score)
        // A more advanced system could track agent uptime, successful executions, or funds managed.
        for(uint256 i = 0; i < ownerAgents[owner].length; i++){
            Agent storage agent = agents[ownerAgents[owner][i]];
            if(!agent.paused) {
                totalReputation += 100; // 100 points for each active agent
            }
        }

        return totalReputation;
    }

    /**
     * @notice Allows eligible DID owners to propose changes to protocol parameters or modules.
     * @dev Requires the proposer to have a minimum reputation score.
     *      Proposal details are stored off-chain and referenced by an IPFS hash.
     * @param proposalIPFSHash The IPFS hash pointing to the detailed proposal document.
     * @return The unique ID of the newly created proposal.
     */
    function proposeProtocolUpgrade(string calldata proposalIPFSHash) public returns (uint256) {
        require(dids[msg.sender] != 0, "QCP: Proposer must have a DID");
        require(
            calculateReputation(msg.sender) >= MIN_REPUTATION_FOR_PROPOSAL,
            "QCP: Insufficient reputation to propose"
        );

        uint256 proposalId = ++nextProposalId;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            proposalIPFSHash: proposalIPFSHash,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + VOTING_PERIOD,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            passed: false,
            // hasVoted mapping is implicitly empty for new struct
            hasVoted: new mapping(address => bool) // Initialize mapping to prevent storage collision warnings in older compilers
        });

        emit ProposalCreated(proposalId, msg.sender, proposalIPFSHash);
        return proposalId;
    }

    /**
     * @notice Allows DID owners to cast a vote on an active governance proposal.
     * @dev The weight of the vote is determined by the voter's current reputation score.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "QCP: Proposal does not exist");
        require(block.timestamp >= proposal.votingStartTime, "QCP: Voting has not started");
        require(block.timestamp <= proposal.votingEndTime, "QCP: Voting has ended");
        require(!proposal.hasVoted[msg.sender], "QCP: Already voted on this proposal");
        require(dids[msg.sender] != 0, "QCP: Voter must have a DID");

        uint256 voteWeight = calculateReputation(msg.sender);
        require(voteWeight > 0, "QCP: Voter must have reputation to vote"); // Prevent zero-reputation votes

        if (support) {
            proposal.forVotes += voteWeight;
        } else {
            proposal.againstVotes += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, voteWeight);
    }

    /**
     * @notice Executes a successfully passed governance proposal.
     * @dev Can be called by anyone after the voting period has ended. If `forVotes` > `againstVotes`,
     *      the proposal is marked as passed and executed.
     *      Actual on-chain logic modification would require more advanced patterns (e.g., upgradeable proxies
     *      or a specific executor contract that interprets proposal content). For this example, it only updates status.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "QCP: Proposal does not exist");
        require(block.timestamp > proposal.votingEndTime, "QCP: Voting period has not ended");
        require(!proposal.executed, "QCP: Proposal already executed");

        proposal.passed = proposal.forVotes > proposal.againstVotes;
        proposal.executed = true; // Mark as executed regardless of passing to prevent re-attempts

        if (proposal.passed) {
            // TODO: Here, in a full-fledged system, the proposalIPFSHash would contain
            // ABI-encoded instructions (e.g., target contract, function selector, parameters)
            // that this contract would then call to effect the "upgrade" or change.
            // For this example, we only update the internal state.
            emit ProposalExecuted(proposalId);
        } else {
            // Proposal failed
        }
    }

    /**
     * @notice Retrieves detailed information about a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return The proposer's address, IPFS hash, voting start/end times, vote counts, and execution status.
     */
    function getProposalDetails(uint256 proposalId)
        public
        view
        returns (
            address proposer,
            string memory proposalIPFSHash,
            uint256 votingStartTime,
            uint256 votingEndTime,
            uint256 forVotes,
            uint256 againstVotes,
            bool executed,
            bool passed
        )
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "QCP: Proposal does not exist");
        return (
            proposal.proposer,
            proposal.proposalIPFSHash,
            proposal.votingStartTime,
            proposal.votingEndTime,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.executed,
            proposal.passed
        );
    }

    /**
     * @dev Fallback function to receive Ether.
     * @notice This function allows the contract to receive raw Ether. It's not explicitly tied to an agent.
     *         For explicit agent funding, `fundAgent` should be used.
     */
    receive() external payable {
        // If Ether is sent directly to the contract without calling a specific function,
        // it increases the contract's overall balance.
        // A more robust system might revert or require an agentId to prevent accidental sends.
    }
}

```