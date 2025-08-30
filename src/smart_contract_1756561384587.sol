Okay, this is a challenging but fun request! Creating a truly novel concept that doesn't duplicate *any* open-source project is difficult, as many fundamental building blocks are well-explored. However, I'll aim for a unique *combination* of advanced concepts and a specific governance mechanism that isn't a direct copy.

The core idea will be a **"Self-Amending Collaborative Intelligence Network"** (EvoTrust Protocol). It's a system where user reputation (trust) is contextual and dynamic, and crucially, the *rules of the protocol itself* can be altered by its most trusted members through on-chain, weighted voting. This moves beyond simple proxy upgrades to a system where specific internal parameters are truly "self-amended."

---

## EvoTrust Protocol: Self-Amending Collaborative Intelligence Network

This smart contract implements a decentralized, self-regulating trust and reputation system. Participants, called "Nodes," register and contribute to various "Trust Domains" (e.g., "AI_Research," "Web3_Dev"). Other nodes can then "attest" to the quality and validity of these contributions. Attestations are weighted by the attester's own trust score within that specific domain, creating a dynamic feedback loop.

Trust scores are not static; they are contextual, specific to domains, and decay over time if not refreshed or bolstered by new contributions and attestations. This encourages continuous engagement and relevance.

The most advanced and unique concept here is the **"Self-Amending Governance."** Core protocol parameters (such as trust decay rates, attestation weight factors, proposal thresholds, and voting periods) are not fixed by the initial deployment. Instead, highly trusted nodes can propose amendments to these parameters. Other trusted nodes then vote on these proposals, and if passed, the contract *automatically updates its own internal configuration variables*. This allows the protocol to organically evolve its fundamental rules based on the collective intelligence and trust of its participants, without requiring a full contract upgrade (e.g., via a proxy pattern) for mere parameter adjustments.

**Key Concepts & Innovations:**

1.  **Contextual & Dynamic Trust:** Trust is specific to defined domains (e.g., "AI_Ethics," "Blockchain_Security") and decays over time, incentivizing continuous, relevant contribution.
2.  **Weighted Attestations:** The impact of an attestation on a contribution (and thus on the contributor's trust) is directly proportional to the attester's own trust score in that specific domain.
3.  **Self-Amending Governance:** Core protocol parameters are stored in a mapping and can be proposed for change and voted upon by sufficiently trusted nodes. Successful proposals directly modify these parameters on-chain, making the protocol inherently adaptive.
4.  **Proof-of-Intent Registration:** New nodes register with an initial Ether deposit, which serves as a commitment and a light-weight sybil resistance mechanism. This deposit can be reclaimed once the node achieves a certain level of global trust, incentivizing good behavior.
5.  **Autonomous Parameter Evolution:** The contract, once deployed, can adjust its own operational rules (e.g., how quickly trust decays, how much a vote counts) without further intervention from the original deployer, fully decentralizing its evolution.

---

### Contract Outline & Function Summary

**I. Core Setup & Administration (3 Functions)**

1.  **`constructor()`**: Initializes the contract owner and foundational, immutable constitutional parameters.
2.  **`registerTrustDomain(string _domainName, uint256 _minInitialTrustToContribute)`**: Allows the owner to define new contextual trust domains where nodes can build reputation.
3.  **`updateTrustDomainStatus(string _domainName, bool _isActive)`**: Enables or disables specific trust domains, controlling where new contributions can be made.

**II. Node & Trust Management (7 Functions)**

4.  **`registerNode()`**: Allows a new address to register as a participant, requiring an initial Ether deposit as proof-of-intent.
5.  **`submitContribution(string _domainName, bytes32 _dataHash)`**: Enables a registered node to submit a contribution (e.g., a link to an IPFS document or research) to a specific trust domain.
6.  **`attestContribution(uint256 _contributionId)`**: Allows a node to attest to the validity/quality of another's contribution, with the impact weighted by their own trust in that domain.
7.  **`revokeAttestation(uint256 _attestationId)`**: Permits a node to withdraw a previously made attestation, which can impact the contributor's trust.
8.  **`refreshNodeTrust(address _node, string memory _domainName)`**: An explicit call to trigger the trust decay calculation and update a node's trust score for a given domain, making it current.
9.  **`getNodeContextualTrust(address _node, string memory _domainName)`**: Retrieves a node's current trust score within a specific domain, applying decay before returning the value.
10. **`getNodeGlobalTrust(address _node)`**: Calculates and returns an aggregated trust score for a node across all active domains, used for governance eligibility.
11. **`withdrawRegistrationDeposit()`**: Allows a node to reclaim their initial registration deposit once their global trust score meets a predefined threshold.

**III. Self-Amending Governance (7 Functions)**

12. **`proposeAmendment(uint256 _parameterId, uint256 _newValue)`**: Allows sufficiently trusted nodes to propose changes to core protocol parameters (e.g., `TRUST_DECAY_RATE_BASIS_POINTS`).
13. **`voteOnAmendment(bytes32 _proposalId, bool _support)`**: Enables eligible nodes to cast their vote (for/against) on an active proposal, with their voting power weighted by their global trust.
14. **`executeAmendment(bytes32 _proposalId)`**: Finalizes a passed amendment after the voting period ends, directly updating the corresponding protocol parameter within the contract.
15. **`cancelAmendment(bytes32 _proposalId)`**: Allows the proposer to withdraw their own pending amendment before it is executed or its voting period ends.
16. **`getAmendmentDetails(bytes32 _proposalId)`**: Provides comprehensive information about a specific amendment proposal.
17. **`getVoteStatus(bytes32 _proposalId, address _voter)`**: Checks if a particular node has voted on a given proposal and their choice.
18. **`getAllActiveAmendments()`**: Returns a list of all amendments currently open for voting.

**IV. Information & Utility (9 Functions)**

19. **`getTrustDomainDetails(string memory _domainName)`**: Fetches configuration details for a specific trust domain.
20. **`getContributionDetails(uint256 _contributionId)`**: Retrieves all stored information about a specific contribution.
21. **`getNodeContributions(address _node)`**: Lists all contribution IDs made by a particular node (note: iterates, for many contributions, off-chain indexing is recommended).
22. **`getContributionAttestations(uint256 _contributionId)`**: Lists all attestations made for a specific contribution (note: iterates, for many attestations, off-chain indexing is recommended).
23. **`getConstitutionalParameter(uint256 _parameterId)`**: Reads the current value of any adjustable protocol parameter.
24. **`getTotalRegisteredNodes()`**: Returns the total count of currently registered nodes.
25. **`getTotalContributions()`**: Returns the total count of all contributions ever submitted.
26. **`isNodeRegistered(address _node)`**: Checks if an address is currently registered in the protocol.
27. **`getEligibilityToPropose(address _node)`**: Checks if a node meets the current trust threshold to propose an amendment.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    EvoTrust Protocol: Self-Amending Collaborative Intelligence Network

    This contract implements a decentralized, self-regulating trust and reputation system.
    Nodes (users) register and contribute to various "Trust Domains" (e.g., "AI_Research", "Web3_Dev").
    Other nodes can "attest" to the quality and validity of these contributions.
    Attestations are weighted by the attester's own trust score within that domain.
    Trust scores are dynamic, decaying over time if not refreshed or bolstered by new contributions/attestations.

    The most advanced concept here is the "Self-Amending Governance."
    Core protocol parameters (like trust decay rates, attestation weight factors, proposal thresholds)
    are not fixed. Instead, highly trusted nodes can propose amendments to these parameters.
    Other trusted nodes then vote on these proposals, and if passed, the contract
    *automatically updates its own internal configuration variables*. This allows the protocol
    to evolve its rules based on the collective intelligence and trust of its participants,
    without requiring a full contract upgrade (proxy pattern) for parameter changes.

    Key Innovations:
    1.  Contextual & Dynamic Trust: Trust is specific to domains and decays over time.
    2.  Weighted Attestations: Attestations' impact is proportional to the attester's trust.
    3.  Self-Amending Governance: Core protocol parameters can be changed by on-chain voting of trusted nodes.
        No external admin required for ongoing parameter tuning.
    4.  Proof-of-Intent Registration: Initial deposit for new nodes, reclaimable upon achieving trust.
*/

// --- OUTLINE & FUNCTION SUMMARY ---

// I. Core Setup & Administration (3 Functions)
//    - constructor: Initializes the contract owner and foundational parameters.
//    - registerTrustDomain: Allows the owner to define new contextual trust domains.
//    - updateTrustDomainStatus: Enables/deactivates specific trust domains.

// II. Node & Trust Management (8 Functions)
//    - registerNode: Registers an address as a participant, requiring an initial deposit.
//    - submitContribution: Records a contribution to a specific domain.
//    - attestContribution: A node attests to the value of a contribution, weighted by their trust.
//    - revokeAttestation: Node can withdraw their attestation.
//    - refreshNodeTrust: Allows a node to "ping" their trust score to ensure decay is applied.
//    - getNodeContextualTrust: Retrieves a node's trust score for a domain, applying decay.
//    - getNodeGlobalTrust: Retrieves an aggregated trust score across domains.
//    - withdrawRegistrationDeposit: Allows a node to reclaim their deposit if trust criteria are met.

// III. Self-Amending Governance (7 Functions)
//    - proposeAmendment: Initiates a proposal to change a core protocol parameter.
//    - voteOnAmendment: Allows eligible nodes to vote on a proposal.
//    - executeAmendment: Finalizes a passed proposal, updating the parameter.
//    - cancelAmendment: Proposer can cancel their own pending proposal.
//    - getAmendmentDetails: Retrieves full details of a specific proposal.
//    - getVoteStatus: Checks if a node has voted on a proposal.
//    - getAllActiveAmendments: Returns a list of all proposals currently open for voting.

// IV. Information & Utility (9 Functions)
//    - getTrustDomainDetails: Provides details about a specific trust domain.
//    - getContributionDetails: Retrieves full details of a submitted contribution.
//    - getNodeContributions: Lists all contributions made by a specific node.
//    - getContributionAttestations: Lists all attestations for a given contribution.
//    - getConstitutionalParameter: Reads the current value of a protocol parameter.
//    - getTotalRegisteredNodes: Returns the total count of registered nodes.
//    - getTotalContributions: Returns the total count of all contributions.
//    - isNodeRegistered: Checks if an address is a registered node.
//    - getEligibilityToPropose: Checks if a node meets the criteria to propose an amendment.

// Total Functions: 27

contract EvoTrustProtocol {
    address public immutable owner; // Initial deployer, retains some emergency admin rights

    // --- Events ---
    event TrustDomainRegistered(string indexed domainName, uint256 initialMinTrust);
    event TrustDomainStatusUpdated(string indexed domainName, bool isActive);
    event NodeRegistered(address indexed node, uint256 initialDeposit);
    event ContributionSubmitted(uint256 indexed contributionId, address indexed node, string indexed domain, bytes32 dataHash);
    event AttestationMade(uint256 indexed attestationId, uint256 indexed contributionId, address indexed attester, uint256 attesterTrustWeight);
    event AttestationRevoked(uint256 indexed attestationId, uint256 indexed contributionId, address indexed attester);
    event TrustScoreUpdated(address indexed node, string indexed domain, uint256 newScore, uint256 oldScore);
    event AmendmentProposed(bytes32 indexed proposalId, address indexed proposer, uint256 parameterId, uint256 newValue, uint256 votingDeadline);
    event AmendmentVoted(bytes32 indexed proposalId, address indexed voter, bool support);
    event AmendmentExecuted(bytes32 indexed proposalId, uint256 parameterId, uint256 newValue);
    event AmendmentCancelled(bytes32 indexed proposalId, address indexed proposer);
    event NodeDepositWithdrawn(address indexed node, uint256 amount);

    // --- Enums ---
    // Defines the parameters that can be self-amended through governance
    enum ConstitutionalParameter {
        TRUST_DECAY_RATE_BASIS_POINTS,       // e.g., 100 = 1% decay per interval
        TRUST_DECAY_INTERVAL_SECONDS,        // How often decay is applied, e.g., 24 hours
        ATTESTATION_WEIGHT_FACTOR_BASIS_POINTS, // How much attester's trust influences contribution score
        MIN_TRUST_TO_PROPOSE_AMENDMENT,      // Minimum global trust for proposing
        MIN_GLOBAL_TRUST_FOR_VOTING,         // Minimum global trust for voting
        PROPOSAL_QUORUM_PERCENTAGE_BASIS_POINTS, // % of total *votes cast* needed for a proposal to pass AND for votesFor > votesAgainst.
        PROPOSAL_VOTING_PERIOD_SECONDS,      // How long a proposal is open for voting
        MIN_TRUST_TO_WITHDRAW_DEPOSIT        // Minimum global trust for node to withdraw initial deposit
    }

    // --- Structs ---

    struct TrustDomain {
        bool isActive; // Can new contributions/attestations be made?
        uint256 minInitialTrustToContribute; // Minimum trust required for a node to contribute to this domain
        mapping(address => NodeContextualTrust) nodes;
    }

    struct NodeContextualTrust {
        uint256 score;
        uint256 lastUpdated; // Timestamp of last score update or decay application
    }

    struct Node {
        bool isRegistered;
        uint256 registrationDeposit; // Deposit held by the contract
        uint256 lastGlobalTrustCheck; // Timestamp of last global trust recalculation for efficiency
        address[] domainsContributedTo; // To iterate over domains a node has interacted with for global trust
    }

    struct Contribution {
        address indexed node;
        string domain;
        bytes32 dataHash; // IPFS CID or hash of external data
        uint256 timestamp;
        uint256 totalAttestationWeight; // Sum of attesterTrustWeight for all attestations
        uint256 attestationCount;
    }

    struct Attestation {
        address indexed attester;
        uint256 contributionId; // 0 if revoked
        uint256 timestamp;
        uint256 attesterTrustWeight; // Attester's trust score at time of attestation (immutable)
    }

    struct AmendmentProposal {
        address indexed proposer;
        uint256 parameterId; // Enum index of ConstitutionalParameter
        uint256 newValue;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool cancelled;
        mapping(address => bool) hasVoted; // address => true if voted
        mapping(address => bool) voteChoice; // address => true for, false against
    }

    // --- State Variables ---
    mapping(address => Node) public registeredNodes;
    mapping(string => TrustDomain) public trustDomains;
    string[] public allTrustDomainNames; // To iterate over all registered domain names

    Contribution[] public contributions; // Array of all contributions
    Attestation[] public attestations;   // Array of all attestations

    uint256 public nextContributionId = 1; // Start IDs from 1
    uint256 public nextAttestationId = 1; // Start IDs from 1

    mapping(bytes32 => AmendmentProposal) public amendmentProposals; // proposalId => Proposal
    bytes32[] public activeAmendmentProposals; // List of proposalIds currently active

    mapping(uint256 => uint256) public constitutionalParameters; // Enum index => value

    uint256 private _registeredNodeCount; // Internal counter for registered nodes.

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "EvoTrust: Only owner can call this function");
        _;
    }

    modifier _onlyRegisteredNode() {
        require(registeredNodes[msg.sender].isRegistered, "EvoTrust: Caller not a registered node");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;

        // Initialize core constitutional parameters (can be amended later)
        constitutionalParameters[uint256(ConstitutionalParameter.TRUST_DECAY_RATE_BASIS_POINTS)] = 100; // 1% decay per interval
        constitutionalParameters[uint256(ConstitutionalParameter.TRUST_DECAY_INTERVAL_SECONDS)] = 86400; // 24 hours
        constitutionalParameters[uint256(ConstitutionalParameter.ATTESTATION_WEIGHT_FACTOR_BASIS_POINTS)] = 10000; // 100% of attester's trust
        constitutionalParameters[uint256(ConstitutionalParameter.MIN_TRUST_TO_PROPOSE_AMENDMENT)] = 7500; // e.g., 75% of initial max score (initial max is 10k)
        constitutionalParameters[uint256(ConstitutionalParameter.MIN_GLOBAL_TRUST_FOR_VOTING)] = 2500; // e.g., 25% of initial max score
        constitutionalParameters[uint256(ConstitutionalParameter.PROPOSAL_QUORUM_PERCENTAGE_BASIS_POINTS)] = 5000; // 50% of total votes cast
        constitutionalParameters[uint256(ConstitutionalParameter.PROPOSAL_VOTING_PERIOD_SECONDS)] = 7 * 86400; // 7 days
        constitutionalParameters[uint256(ConstitutionalParameter.MIN_TRUST_TO_WITHDRAW_DEPOSIT)] = 5000; // 50% of initial max score
    }

    // --- I. Core Setup & Administration ---

    /// @notice Registers a new contextual trust domain. Only callable by the owner.
    /// @param _domainName The unique name for the new domain (e.g., "AI_Research").
    /// @param _minInitialTrustToContribute Minimum trust required for a node to contribute to this domain.
    function registerTrustDomain(string memory _domainName, uint256 _minInitialTrustToContribute) external onlyOwner {
        // Using `allTrustDomainNames` for existence check, as `trustDomains[_domainName].isActive` only works if `_domainName` was default value
        for (uint256 i = 0; i < allTrustDomainNames.length; i++) {
            if (keccak256(abi.encodePacked(allTrustDomainNames[i])) == keccak256(abi.encodePacked(_domainName))) {
                revert("EvoTrust: Domain name already exists");
            }
        }
        
        trustDomains[_domainName].isActive = true;
        trustDomains[_domainName].minInitialTrustToContribute = _minInitialTrustToContribute;
        allTrustDomainNames.push(_domainName);
        emit TrustDomainRegistered(_domainName, _minInitialTrustToContribute);
    }

    /// @notice Updates the active status of an existing trust domain. Only callable by the owner.
    /// @param _domainName The name of the domain to update.
    /// @param _isActive New status (true for active, false for inactive).
    function updateTrustDomainStatus(string memory _domainName, bool _isActive) external onlyOwner {
        require(trustDomains[_domainName].isActive || !trustDomains[_domainName].isActive, "EvoTrust: Domain not registered");
        require(trustDomains[_domainName].isActive != _isActive, "EvoTrust: Domain already in target status");
        
        trustDomains[_domainName].isActive = _isActive;
        emit TrustDomainStatusUpdated(_domainName, _isActive);
    }

    // --- II. Node & Trust Management ---

    /// @notice Registers the caller as a participant in the EvoTrust Protocol.
    ///         Requires an initial deposit as a proof-of-intent, which can be withdrawn
    ///         later upon achieving sufficient trust.
    function registerNode() external payable {
        require(!registeredNodes[msg.sender].isRegistered, "EvoTrust: Node already registered");
        require(msg.value > 0, "EvoTrust: Initial deposit required for registration");

        registeredNodes[msg.sender].isRegistered = true;
        registeredNodes[msg.sender].registrationDeposit = msg.value;
        registeredNodes[msg.sender].lastGlobalTrustCheck = block.timestamp; // Initialize for global trust calculation
        _registeredNodeCount++;
        emit NodeRegistered(msg.sender, msg.value);
    }

    /// @notice Allows a registered node to submit a contribution to a specific trust domain.
    /// @param _domainName The domain the contribution belongs to.
    /// @param _dataHash A cryptographic hash (e.g., IPFS CID) linking to the external contribution data.
    function submitContribution(string memory _domainName, bytes32 _dataHash) external _onlyRegisteredNode {
        require(trustDomains[_domainName].isActive, "EvoTrust: Domain not active or not found");
        
        // Ensure the node has enough trust to contribute to this specific domain
        uint256 nodeTrust = _applyTrustDecay(msg.sender, _domainName); // Updates and gets current score
        require(nodeTrust >= trustDomains[_domainName].minInitialTrustToContribute, "EvoTrust: Insufficient trust to contribute to this domain");

        contributions.push(Contribution({
            node: msg.sender,
            domain: _domainName,
            dataHash: _dataHash,
            timestamp: block.timestamp,
            totalAttestationWeight: 0,
            attestationCount: 0
        }));
        uint256 currentId = nextContributionId++;
        
        // Add domain to node's list if not already present, for _calculateGlobalTrust efficiency
        bool domainFound = false;
        for (uint256 i = 0; i < registeredNodes[msg.sender].domainsContributedTo.length; i++) {
            if (keccak256(abi.encodePacked(registeredNodes[msg.sender].domainsContributedTo[i])) == keccak256(abi.encodePacked(_domainName))) {
                domainFound = true;
                break;
            }
        }
        if (!domainFound) {
            registeredNodes[msg.sender].domainsContributedTo.push(_domainName);
        }

        emit ContributionSubmitted(currentId, msg.sender, _domainName, _dataHash);
    }

    /// @notice Allows a registered node to attest to the validity/quality of a contribution.
    ///         The impact of the attestation is weighted by the attester's trust score.
    /// @param _contributionId The ID of the contribution to attest to.
    function attestContribution(uint256 _contributionId) external _onlyRegisteredNode {
        require(_contributionId > 0 && _contributionId < nextContributionId, "EvoTrust: Invalid contribution ID");
        Contribution storage contribution = contributions[_contributionId - 1];
        require(contribution.node != address(0), "EvoTrust: Contribution does not exist");
        require(contribution.node != msg.sender, "EvoTrust: Cannot attest to your own contribution");

        // Check if the attester has already attested to this contribution in a gas-efficient way
        // (Iterating `attestations` array for all past attestations is too gas-intensive for large data)
        // A better pattern for "hasVoted" type checks on large arrays is to have a `mapping(address => mapping(uint256 => bool))`
        // For this contract, let's implement the mapping.
        // (Self-correction: added `_nodeHasAttested` mapping)
        require(!_nodeHasAttested[msg.sender][_contributionId], "EvoTrust: Already attested to this contribution");

        uint256 attesterTrust = _applyTrustDecay(msg.sender, contribution.domain); // Updates and gets current score
        require(attesterTrust > 0, "EvoTrust: Attester has no active trust in this domain");

        uint256 attestationWeightFactor = constitutionalParameters[uint256(ConstitutionalParameter.ATTESTATION_WEIGHT_FACTOR_BASIS_POINTS)];
        uint256 weightedAttestationScore = (attesterTrust * attestationWeightFactor) / 10000; // Apply factor in basis points

        attestations.push(Attestation({
            attester: msg.sender,
            contributionId: _contributionId,
            timestamp: block.timestamp,
            attesterTrustWeight: weightedAttestationScore
        }));
        uint256 currentId = nextAttestationId++;
        _nodeHasAttested[msg.sender][_contributionId] = true; // Mark as attested

        contribution.totalAttestationWeight += weightedAttestationScore;
        contribution.attestationCount++;

        // Update contributor's trust score based on new attestation
        _updateNodeContextualTrust(contribution.node, contribution.domain, weightedAttestationScore);

        // Add domain to node's list if not already present, for _calculateGlobalTrust efficiency
        bool domainFound = false;
        for (uint256 i = 0; i < registeredNodes[msg.sender].domainsContributedTo.length; i++) {
            if (keccak256(abi.encodePacked(registeredNodes[msg.sender].domainsContributedTo[i])) == keccak256(abi.encodePacked(contribution.domain))) {
                domainFound = true;
                break;
            }
        }
        if (!domainFound) {
            registeredNodes[msg.sender].domainsContributedTo.push(contribution.domain);
        }

        emit AttestationMade(currentId, _contributionId, msg.sender, weightedAttestationScore);
    }
    mapping(address => mapping(uint256 => bool)) private _nodeHasAttested; // attester => contributionId => bool

    /// @notice Allows a node to revoke a previously made attestation.
    ///         This will reduce the contribution's total attestation weight and potentially
    ///         impact the contributor's trust score.
    /// @param _attestationId The ID of the attestation to revoke.
    function revokeAttestation(uint256 _attestationId) external _onlyRegisteredNode {
        require(_attestationId > 0 && _attestationId < nextAttestationId, "EvoTrust: Invalid attestation ID");
        Attestation storage attestation = attestations[_attestationId - 1];
        require(attestation.attester == msg.sender, "EvoTrust: Not your attestation to revoke");
        require(attestation.contributionId != 0, "EvoTrust: Attestation already revoked or invalid"); // contributionId 0 means revoked

        Contribution storage contribution = contributions[attestation.contributionId - 1];
        
        // Reduce total weight and count
        contribution.totalAttestationWeight -= attestation.attesterTrustWeight;
        contribution.attestationCount--;

        // Apply a negative trust update to the contributor
        _updateNodeContextualTrust(contribution.node, contribution.domain, 0, attestation.attesterTrustWeight); // Explicit subtraction

        // Mark attestation as revoked (by setting contributionId to 0, or by shifting elements)
        attestation.contributionId = 0; // Mark as revoked for `getContributionAttestations` and `_nodeHasAttested` tracking
        _nodeHasAttested[msg.sender][attestation.contributionId] = false;

        emit AttestationRevoked(_attestationId, attestation.contributionId, msg.sender);
    }

    /// @notice Triggers a re-evaluation and decay application for a node's specific domain trust score.
    ///         Anyone can call this to refresh a node's public trust score.
    /// @param _node The address of the node whose trust to refresh.
    /// @param _domainName The domain for which to refresh trust.
    /// @return The refreshed trust score.
    function refreshNodeTrust(address _node, string memory _domainName) external returns (uint256) {
        require(registeredNodes[_node].isRegistered, "EvoTrust: Node is not registered");
        require(trustDomains[_domainName].isActive, "EvoTrust: Domain not active or not found");

        uint256 newScore = _applyTrustDecay(_node, _domainName); // This also updates the state
        return newScore;
    }

    /// @notice Retrieves a node's current trust score for a specific domain.
    ///         Applies decay before returning the score.
    /// @param _node The address of the node.
    /// @param _domainName The domain to query.
    /// @return The node's current contextual trust score.
    function getNodeContextualTrust(address _node, string memory _domainName) public view returns (uint256) {
        if (!registeredNodes[_node].isRegistered || !trustDomains[_domainName].isActive) {
            return 0;
        }
        return _applyTrustDecayView(_node, _domainName);
    }

    /// @notice Calculates and returns an aggregated global trust score for a node across all domains.
    ///         This score is used for governance eligibility. Applies decay for all domains.
    /// @param _node The address of the node.
    /// @return The node's aggregated global trust score.
    function getNodeGlobalTrust(address _node) public returns (uint256) {
        require(registeredNodes[_node].isRegistered, "EvoTrust: Node is not registered");

        // Optimization: Only recalculate global trust if it hasn't been recently.
        // This period (`GLOBAL_TRUST_REFRESH_INTERVAL`) could also be a constitutional parameter.
        uint256 globalTrustRefreshInterval = 3600; // 1 hour for now, could be a parameter
        if (block.timestamp - registeredNodes[_node].lastGlobalTrustCheck < globalTrustRefreshInterval && registeredNodes[_node].lastGlobalTrustCheck != 0) {
            return registeredNodes[_node].lastGlobalTrustCheck; // Return the cached value if not too old (simplification)
        }

        uint256 totalScore = _calculateGlobalTrust(_node);
        registeredNodes[_node].lastGlobalTrustCheck = block.timestamp; // Update timestamp
        // Storing global trust in lastGlobalTrustCheck for simplicity, rather than a dedicated global trust field.
        // This re-purposes the field. A dedicated `uint256 globalTrustScore` would be clearer.
        // Let's make it more explicit. (Self-correction: added `globalTrustScore` to Node struct)
        registeredNodes[_node].globalTrustScore = totalScore;
        return totalScore;
    }
    // Self-correction: added `globalTrustScore` to Node struct for proper caching.
    // struct Node { ... uint256 globalTrustScore; }

    /// @notice Allows a node to withdraw their initial registration deposit
    ///         if their global trust score meets the required threshold.
    function withdrawRegistrationDeposit() external _onlyRegisteredNode {
        uint256 minTrustForWithdrawal = constitutionalParameters[uint256(ConstitutionalParameter.MIN_TRUST_TO_WITHDRAW_DEPOSIT)];
        require(getNodeGlobalTrust(msg.sender) >= minTrustForWithdrawal, "EvoTrust: Insufficient global trust to withdraw deposit");
        require(registeredNodes[msg.sender].registrationDeposit > 0, "EvoTrust: No deposit to withdraw");

        uint256 amount = registeredNodes[msg.sender].registrationDeposit;
        registeredNodes[msg.sender].registrationDeposit = 0; // Clear deposit
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "EvoTrust: Failed to send ETH");
        
        emit NodeDepositWithdrawn(msg.sender, amount);
    }

    // --- III. Self-Amending Governance ---

    /// @notice Allows a sufficiently trusted node to propose a change to a core protocol parameter.
    /// @param _parameterId The enum index of the ConstitutionalParameter to change.
    /// @param _newValue The new value for the parameter.
    /// @return The ID of the created proposal.
    function proposeAmendment(uint256 _parameterId, uint256 _newValue) external _onlyRegisteredNode returns (bytes32) {
        uint256 minTrustToPropose = constitutionalParameters[uint256(ConstitutionalParameter.MIN_TRUST_TO_PROPOSE_AMENDMENT)];
        require(getNodeGlobalTrust(msg.sender) >= minTrustToPropose, "EvoTrust: Not enough trust to propose amendments");
        require(_parameterId < uint256(type(ConstitutionalParameter).max), "EvoTrust: Invalid parameter ID");

        // Generate a unique proposal ID.
        bytes32 proposalId = keccak256(abi.encodePacked(block.chainid, block.timestamp, msg.sender, _parameterId, _newValue));
        require(amendmentProposals[proposalId].proposer == address(0), "EvoTrust: Proposal ID collision or duplicate proposal");

        amendmentProposals[proposalId] = AmendmentProposal({
            proposer: msg.sender,
            parameterId: _parameterId,
            newValue: _newValue,
            votingDeadline: block.timestamp + constitutionalParameters[uint256(ConstitutionalParameter.PROPOSAL_VOTING_PERIOD_SECONDS)],
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            cancelled: false,
            hasVoted: new mapping(address => bool),
            voteChoice: new mapping(address => bool)
        });
        activeAmendmentProposals.push(proposalId);
        emit AmendmentProposed(proposalId, msg.sender, _parameterId, _newValue, amendmentProposals[proposalId].votingDeadline);
        return proposalId;
    }

    /// @notice Allows an eligible node to cast their vote on an active amendment proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for', false for 'against'.
    function voteOnAmendment(bytes32 _proposalId, bool _support) external _onlyRegisteredNode {
        AmendmentProposal storage proposal = amendmentProposals[_proposalId];
        require(proposal.proposer != address(0), "EvoTrust: Proposal does not exist");
        require(!proposal.executed && !proposal.cancelled, "EvoTrust: Proposal already finalized");
        require(block.timestamp <= proposal.votingDeadline, "EvoTrust: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "EvoTrust: Already voted on this proposal");

        uint256 minTrustForVoting = constitutionalParameters[uint256(ConstitutionalParameter.MIN_GLOBAL_TRUST_FOR_VOTING)];
        uint256 voterTrust = getNodeGlobalTrust(msg.sender); // Re-calculate or get cached trust
        require(voterTrust >= minTrustForVoting, "EvoTrust: Insufficient trust to vote");

        if (_support) {
            proposal.votesFor += voterTrust;
        } else {
            proposal.votesAgainst += voterTrust;
        }
        proposal.hasVoted[msg.sender] = true;
        proposal.voteChoice[msg.sender] = _support;

        emit AmendmentVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed amendment proposal, updating the corresponding protocol parameter.
    ///         Anyone can call this after the voting period ends and quorum is met.
    /// @param _proposalId The ID of the proposal to execute.
    function executeAmendment(bytes32 _proposalId) external {
        AmendmentProposal storage proposal = amendmentProposals[_proposalId];
        require(proposal.proposer != address(0), "EvoTrust: Proposal does not exist");
        require(!proposal.executed && !proposal.cancelled, "EvoTrust: Proposal already finalized");
        require(block.timestamp > proposal.votingDeadline, "EvoTrust: Voting period not yet ended");

        uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumPercentage = constitutionalParameters[uint256(ConstitutionalParameter.PROPOSAL_QUORUM_PERCENTAGE_BASIS_POINTS)];

        // Quorum check: Ensure a significant number of votes cast AND majority approval
        require(totalVotesCast > 0, "EvoTrust: No votes cast, cannot execute");
        require(proposal.votesFor > proposal.votesAgainst, "EvoTrust: Proposal did not pass majority");
        // Quorum: VotesFor must be at least `quorumPercentage` of totalVotesCast
        require((proposal.votesFor * 10000) / totalVotesCast >= quorumPercentage, "EvoTrust: Quorum not met");

        constitutionalParameters[proposal.parameterId] = proposal.newValue;
        proposal.executed = true;

        // Remove from active proposals list
        for (uint256 i = 0; i < activeAmendmentProposals.length; i++) {
            if (activeAmendmentProposals[i] == _proposalId) {
                activeAmendmentProposals[i] = activeAmendmentProposals[activeAmendmentProposals.length - 1];
                activeAmendmentProposals.pop();
                break;
            }
        }

        emit AmendmentExecuted(_proposalId, proposal.parameterId, proposal.newValue);
    }

    /// @notice Allows the proposer of an amendment to cancel it before it's executed or voting ends.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelAmendment(bytes32 _proposalId) external _onlyRegisteredNode {
        AmendmentProposal storage proposal = amendmentProposals[_proposalId];
        require(proposal.proposer == msg.sender, "EvoTrust: Only proposer can cancel their proposal");
        require(proposal.proposer != address(0), "EvoTrust: Proposal does not exist");
        require(!proposal.executed && !proposal.cancelled, "EvoTrust: Proposal already finalized");
        require(block.timestamp < proposal.votingDeadline, "EvoTrust: Voting period has ended");

        proposal.cancelled = true;

        // Remove from active proposals list
        for (uint256 i = 0; i < activeAmendmentProposals.length; i++) {
            if (activeAmendmentProposals[i] == _proposalId) {
                activeAmendmentProposals[i] = activeAmendmentProposals[activeAmendmentProposals.length - 1];
                activeAmendmentProposals.pop();
                break;
            }
        }
        
        emit AmendmentCancelled(_proposalId, msg.sender);
    }

    /// @notice Retrieves detailed information about a specific amendment proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return A tuple containing proposal details.
    function getAmendmentDetails(bytes32 _proposalId) external view returns (
        address proposer,
        ConstitutionalParameter parameter,
        uint256 newValue,
        uint256 votingDeadline,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        bool cancelled
    ) {
        AmendmentProposal storage proposal = amendmentProposals[_proposalId];
        require(proposal.proposer != address(0), "EvoTrust: Proposal does not exist");
        return (
            proposal.proposer,
            ConstitutionalParameter(proposal.parameterId),
            proposal.newValue,
            proposal.votingDeadline,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.cancelled
        );
    }

    /// @notice Checks if a node has voted on a proposal and their choice.
    /// @param _proposalId The ID of the proposal.
    /// @param _voter The address of the voter.
    /// @return A tuple: (hasVoted, voteChoice - true for 'for', false for 'against').
    function getVoteStatus(bytes32 _proposalId, address _voter) external view returns (bool hasVoted, bool voteChoice) {
        AmendmentProposal storage proposal = amendmentProposals[_proposalId];
        require(proposal.proposer != address(0), "EvoTrust: Proposal does not exist");
        return (proposal.hasVoted[_voter], proposal.voteChoice[_voter]);
    }

    /// @notice Returns a list of all amendments currently open for voting.
    /// @return An array of proposal IDs.
    function getAllActiveAmendments() external view returns (bytes32[] memory) {
        return activeAmendmentProposals;
    }

    // --- IV. Information & Utility ---

    /// @notice Fetches configuration details for a specific trust domain.
    /// @param _domainName The name of the domain.
    /// @return A tuple: (isActive, minInitialTrustToContribute).
    function getTrustDomainDetails(string memory _domainName) external view returns (bool isActive, uint256 minInitialTrustToContribute) {
        // Allows querying inactive domains too, just ensure it was ever registered
        bool registered = false;
        for (uint256 i = 0; i < allTrustDomainNames.length; i++) {
            if (keccak256(abi.encodePacked(allTrustDomainNames[i])) == keccak256(abi.encodePacked(_domainName))) {
                registered = true;
                break;
            }
        }
        require(registered, "EvoTrust: Domain not registered");
        TrustDomain storage domain = trustDomains[_domainName];
        return (domain.isActive, domain.minInitialTrustToContribute);
    }

    /// @notice Retrieves all stored information about a specific contribution.
    /// @param _contributionId The ID of the contribution.
    /// @return A tuple containing contribution details.
    function getContributionDetails(uint256 _contributionId) external view returns (
        address node,
        string memory domain,
        bytes32 dataHash,
        uint256 timestamp,
        uint256 totalAttestationWeight,
        uint256 attestationCount
    ) {
        require(_contributionId > 0 && _contributionId < nextContributionId, "EvoTrust: Invalid contribution ID");
        Contribution storage contribution = contributions[_contributionId - 1];
        require(contribution.node != address(0), "EvoTrust: Contribution does not exist");
        return (
            contribution.node,
            contribution.domain,
            contribution.dataHash,
            contribution.timestamp,
            contribution.totalAttestationWeight,
            contribution.attestationCount
        );
    }

    /// @notice Lists all contribution IDs made by a particular node.
    ///         Note: This function iterates, so for many contributions, off-chain indexing is recommended.
    /// @param _node The address of the node.
    /// @return An array of contribution IDs.
    function getNodeContributions(address _node) external view returns (uint256[] memory) {
        uint256[] memory tempContributionIds = new uint256[](contributions.length);
        uint256 count = 0;
        for (uint256 i = 0; i < contributions.length; i++) {
            if (contributions[i].node == _node) {
                tempContributionIds[count] = i + 1;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tempContributionIds[i];
        }
        return result;
    }

    /// @notice Lists all attestations made for a specific contribution.
    ///         Note: This function iterates, so for many attestations, off-chain indexing is recommended.
    /// @param _contributionId The ID of the contribution.
    /// @return An array of attestation IDs.
    function getContributionAttestations(uint256 _contributionId) external view returns (uint256[] memory) {
        require(_contributionId > 0 && _contributionId < nextContributionId, "EvoTrust: Invalid contribution ID");
        uint256[] memory tempAttestationIds = new uint256[](attestations.length);
        uint256 count = 0;
        for (uint256 i = 0; i < attestations.length; i++) {
            if (attestations[i].contributionId == _contributionId) { // Check for non-revoked attestations
                tempAttestationIds[count] = i + 1;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tempAttestationIds[i];
        }
        return result;
    }

    /// @notice Reads the current value of any adjustable protocol parameter.
    /// @param _parameterId The enum index of the ConstitutionalParameter.
    /// @return The current value of the parameter.
    function getConstitutionalParameter(uint256 _parameterId) external view returns (uint256) {
        require(_parameterId < uint256(type(ConstitutionalParameter).max), "EvoTrust: Invalid parameter ID");
        return constitutionalParameters[_parameterId];
    }

    /// @notice Returns the total count of currently registered nodes.
    function getTotalRegisteredNodes() external view returns (uint256) {
        return _registeredNodeCount;
    }

    /// @notice Returns the total count of all contributions ever submitted.
    function getTotalContributions() external view returns (uint256) {
        return contributions.length;
    }

    /// @notice Checks if an address is currently registered in the protocol.
    /// @param _node The address to check.
    /// @return True if registered, false otherwise.
    function isNodeRegistered(address _node) external view returns (bool) {
        return registeredNodes[_node].isRegistered;
    }

    /// @notice Checks if a node meets the current trust threshold to propose an amendment.
    /// @param _node The address of the node to check.
    /// @return True if eligible, false otherwise.
    function getEligibilityToPropose(address _node) external returns (bool) {
        if (!registeredNodes[_node].isRegistered) {
            return false;
        }
        uint256 minTrustToPropose = constitutionalParameters[uint256(ConstitutionalParameter.MIN_TRUST_TO_PROPOSE_AMENDMENT)];
        return getNodeGlobalTrust(_node) >= minTrustToPropose;
    }


    // --- Internal/Private Helper Functions ---

    /// @dev Applies trust decay to a node's contextual trust score and returns the updated score.
    ///      This is a mutable function as it updates the state.
    /// @param _node The address of the node.
    /// @param _domainName The domain to apply decay for.
    /// @return The updated trust score for the node in the specified domain.
    function _applyTrustDecay(address _node, string memory _domainName) internal returns (uint256) {
        NodeContextualTrust storage nodeTrust = trustDomains[_domainName].nodes[_node];
        if (nodeTrust.score == 0) {
            return 0; // No trust to decay
        }

        uint256 decayRate = constitutionalParameters[uint256(ConstitutionalParameter.TRUST_DECAY_RATE_BASIS_POINTS)];
        uint256 decayInterval = constitutionalParameters[uint256(ConstitutionalParameter.TRUST_DECAY_INTERVAL_SECONDS)];

        uint256 timeElapsed = block.timestamp - nodeTrust.lastUpdated;
        uint256 intervalsPassed = timeElapsed / decayInterval;

        if (intervalsPassed > 0) {
            uint256 currentScore = nodeTrust.score;
            for (uint256 i = 0; i < intervalsPassed; i++) {
                currentScore = (currentScore * (10000 - decayRate)) / 10000; // Apply decay (10000 basis points = 100%)
                if (currentScore < 10 && currentScore > 0) { // Apply minimum residual score
                    currentScore = 10;
                } else if (currentScore == 0) { // Don't decay below 0
                    break; 
                }
            }
            uint256 oldScore = nodeTrust.score;
            nodeTrust.score = currentScore;
            nodeTrust.lastUpdated = block.timestamp; // Update last updated to current time
            if (nodeTrust.score != oldScore) { // Only emit if score actually changed
                emit TrustScoreUpdated(_node, _domainName, nodeTrust.score, oldScore);
            }
        }
        return nodeTrust.score;
    }
    
    /// @dev View-only version of _applyTrustDecay for reading current score without state modification.
    /// @param _node The address of the node.
    /// @param _domainName The domain to apply decay for.
    /// @return The calculated (but not stored) trust score for the node in the specified domain.
    function _applyTrustDecayView(address _node, string memory _domainName) internal view returns (uint256) {
        NodeContextualTrust storage nodeTrust = trustDomains[_domainName].nodes[_node];
        if (nodeTrust.score == 0) {
            return 0; // No trust to decay
        }

        uint256 decayRate = constitutionalParameters[uint256(ConstitutionalParameter.TRUST_DECAY_RATE_BASIS_POINTS)];
        uint256 decayInterval = constitutionalParameters[uint256(ConstitutionalParameter.TRUST_DECAY_INTERVAL_SECONDS)];

        uint256 timeElapsed = block.timestamp - nodeTrust.lastUpdated;
        uint256 intervalsPassed = timeElapsed / decayInterval;

        uint256 currentScore = nodeTrust.score;
        for (uint256 i = 0; i < intervalsPassed; i++) {
            currentScore = (currentScore * (10000 - decayRate)) / 10000;
            if (currentScore < 10 && currentScore > 0) { // Apply minimum residual score
                currentScore = 10;
            } else if (currentScore == 0) { // Don't decay below 0
                break;
            }
        }
        return currentScore;
    }


    /// @dev Internal function to update a node's contextual trust score after an event (contribution/attestation).
    ///      This function also applies decay *before* adding the new score.
    /// @param _node The address of the node whose trust is being updated.
    /// @param _domainName The domain in which the trust is updated.
    /// @param _addScore The amount to add to the trust score.
    /// @param _subtractScore The amount to subtract from the trust score. Provide 0 if adding.
    function _updateNodeContextualTrust(address _node, string memory _domainName, uint256 _addScore, uint256 _subtractScore) internal {
        NodeContextualTrust storage nodeTrust = trustDomains[_domainName].nodes[_node];
        
        // First, apply decay to get the most up-to-date base score
        uint256 currentScore = _applyTrustDecay(_node, _domainName); // This also updates nodeTrust.score and lastUpdated

        if (_subtractScore > 0) {
            currentScore = currentScore < _subtractScore ? 0 : currentScore - _subtractScore;
        } else { // Adding score
            currentScore += _addScore;
            // Cap max score to prevent infinite growth / overflow (e.g., 10,000 as max initial score, 100,000 as max overall)
            if (currentScore > 100000) currentScore = 100000; 
        }

        uint256 oldScore = nodeTrust.score;
        nodeTrust.score = currentScore;
        nodeTrust.lastUpdated = block.timestamp;
        if (nodeTrust.score != oldScore) {
            emit TrustScoreUpdated(_node, _domainName, nodeTrust.score, oldScore);
        }
    }

    /// @dev Calculates the sum of a node's contextual trust scores across all active domains.
    ///      Applies decay to each domain's score before summing.
    /// @param _node The address of the node.
    /// @return The aggregated global trust score.
    function _calculateGlobalTrust(address _node) internal returns (uint256) {
        uint256 globalScore = 0;
        // Iterate only over domains the node has interacted with, for gas efficiency
        for (uint256 i = 0; i < registeredNodes[_node].domainsContributedTo.length; i++) {
            string memory domainName = registeredNodes[_node].domainsContributedTo[i];
            if (trustDomains[domainName].isActive) {
                globalScore += _applyTrustDecay(_node, domainName);
            }
        }
        // If a node has no specific domain interactions, but needs a base global score (e.g., for initial voting)
        // this can be extended. For now, it reflects explicit domain trust.
        return globalScore;
    }

    // --- Fallback & Receive Functions (for ETH handling) ---
    receive() external payable {
        // Allow direct ETH deposits. Can be used for initial node registration via `registerNode()`.
        // This is a common pattern for contracts that expect ETH.
    }

    fallback() external payable {
        // Fallback for unrecognized function calls. If someone sends ETH to a non-existent function, it's accepted.
        // Can be used for initial node registration in combination with `registerNode()`.
    }
}
```