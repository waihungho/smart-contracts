This smart contract, named **AetheriaNexus**, is designed to be a decentralized marketplace for "AI Intents" (tasks). Requesters can post AI-related tasks with bounties, and "Agents" (off-chain AI models or human-powered services) can claim, execute, and submit verifiable outputs.

It integrates several advanced and creative concepts:
*   **Decentralized AI Intent Market**: A core marketplace for task delegation.
*   **Soulbound Attestations**: A reputation system where trusted entities can issue non-transferable attestations to agents, influencing their standing and potential rewards.
*   **Verifiable Output Commitments**: Agents submit cryptographic commitments (hashes) of their work, allowing for eventual on-chain or off-chain verification.
*   **Delegated Agent Autonomy**: Requesters can delegate specific intent-claiming authority to other agents, enabling automated task acquisition.
*   **Dynamic Protocol Parameters**: Key contract parameters can be adjusted via a simplified governance mechanism.
*   **Conditional & Dynamic Rewards**: Bounty multipliers can be applied to agents based on performance or attestations.
*   **Modular Verification Logic**: Allows for swapping out the underlying verification mechanism (e.g., integrating ZK proof verifiers or multi-party oracle networks).

The design aims to combine these features in a novel way, going beyond standard ERC implementations to create a unique and comprehensive protocol for trustless AI task execution.

---

**AetheriaNexus: Decentralized AI Intent Market & Reputation Protocol**

**Outline:**
The Aetheria Nexus protocol facilitates a decentralized marketplace where "Requesters" can post "AI Intents" (tasks) and "Agents" can claim, execute, and submit verifiable outputs. It integrates a sophisticated reputation system using Soulbound Attestations, allows for delegated autonomy for agents, and introduces dynamic task parameters and conditional rewards.

**Function Summary:**

**I. Core AI Intent Lifecycle (Requester-focused)**
1.  `createAIIntent(bytes32 _intentId, bytes calldata _parametersURI, address _bountyToken, uint256 _bountyAmount, uint256 _expirationBlock)`: Allows a requester to define and fund an AI task.
2.  `updateAIIntentParameters(bytes32 _intentId, bytes calldata _newParametersURI)`: Modifies intent parameters before it's claimed or after specific conditions.
3.  `cancelAIIntent(bytes32 _intentId)`: Cancels an unclaimed or unfulfilled intent, returning bounty.
4.  `requestVerification(bytes32 _intentId, bytes32 _agentOutputCommitment)`: Initiates the verification process for an agent's submitted output. This could trigger an internal verification logic or signal for an oracle.
5.  `finalizeIntentOutcome(bytes32 _intentId, bool _isOutputValid)`: Owner/governance finalizes an intent, distributing bounty or returning it.
6.  `withdrawUnusedBounty(address _tokenAddress)`: **(Deprecated)** Replaced by direct transfers in `cancelAIIntent` and `finalizeIntentOutcome`, and agent-specific `withdrawAgentEarnings`.

**II. Agent Interaction & Execution**
7.  `registerAgentProfile(bytes32 _profileHash)`: Allows an address to register as an Agent.
8.  `claimAIIntent(bytes32 _intentId)`: An Agent claims an intent for execution.
9.  `submitAIOutputCommitment(bytes32 _intentId, bytes32 _outputCommitment)`: Agent submits a cryptographic hash/commitment of their off-chain work.
10. `reportMaliciousAgent(address _agentAddress, bytes32 _evidenceHash)`: Allows anyone to report an agent for misconduct, potentially leading to reputation loss (primarily a signal).
11. `withdrawAgentEarnings(address _tokenAddress)`: Agent withdraws their earned bounty funds accumulated in their contract balance.

**III. Reputation & Attestation System (Soulbound-like)**
12. `issueAttestation(address _agentAddress, bytes32 _attestationType, bytes32 _attestationDataHash, uint256 _expirationBlock)`: Trusted issuers (e.g., governance, specific entities) can issue non-transferable attestations to agents.
13. `revokeAttestation(address _agentAddress, bytes32 _attestationType)`: Revokes an issued attestation.
14. `getAgentAttestationStatus(address _agentAddress, bytes32 _attestationType)`: Checks if an agent holds a valid attestation of a specific type.
15. `getAgentReputationScore(address _agentAddress)`: Calculates a dynamic, weighted score based on successful tasks and attestations.

**IV. Delegated Agent Autonomy**
16. `delegateIntentClaim(address _delegatedAgent, bytes32 _intentCriteriaHash, uint256 _maxBounty)`: Requester authorizes another agent to claim intents on their behalf based on certain criteria.
17. `revokeIntentClaimDelegation(address _delegatedAgent)`: Revokes the delegation.
18. `claimAIIntentDelegated(bytes32 _intentId, address _requester)`: A delegated agent claims an intent on behalf of a requester.

**V. Dynamic Protocol Parameters & Governance**
19. `proposeProtocolParameterChange(bytes32 _paramKey, uint256 _newValue, uint256 _votingDuration)`: Initiates a governance proposal to change a core protocol parameter.
20. `voteOnParameterChange(bytes32 _paramKey, bool _support)`: Allows registered agents to vote on active proposals.
21. `executeParameterChange(bytes32 _paramKey)`: Executes a successfully voted-in parameter change.
22. `setVerificationLogicContract(address _newVerificationLogic)`: Sets the address of an external contract responsible for complex verification.
23. `setAttestationIssuerAddress(address _newAttestationIssuer)`: Sets the address of the entity designated to issue attestations.

**VI. Advanced Utility & Incentives**
24. `setDynamicBountyMultiplier(address _agentAddress, bytes32 _multiplierType, uint256 _multiplierBasisPoints)`: Allows governance/trusted entities to apply a dynamic bounty multiplier to specific agents.
25. `getEstimatedBounty(bytes32 _intentId)`: Returns the current estimated bounty for an intent, considering multipliers for the claimed agent.
26. `challengeAgentPerformance(address _agentAddress, uint256 _challengeWeight)`: Allows designated entities to place a "performance challenge" on an agent, distinct from malicious reporting.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Minimalistic SafeMath library for clarity, though Solidity 0.8+ handles overflow/underflow
library SafeMathForUint {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}


/**
 * @title AetheriaNexus: Decentralized AI Intent Market & Reputation Protocol
 * @dev This contract creates a decentralized marketplace for AI tasks ("AI Intents").
 *      Requesters post tasks with bounties, and Agents claim, execute, and submit verifiable outputs.
 *      It integrates a sophisticated, soulbound-like reputation system via Attestations,
 *      allows for delegated autonomy for agents, and introduces dynamic task parameters and conditional rewards.
 *      The design aims for novel combinations of existing concepts to avoid direct duplication of open-source projects.
 */
contract AetheriaNexus is Ownable {
    using SafeMathForUint for uint256; // Using local SafeMath library

    // --- Data Structures ---

    enum IntentStatus {
        Open,                 // Intent is live and can be claimed
        Claimed,              // Intent has been claimed by an agent
        OutputSubmitted,      // Agent has submitted a commitment of their output
        VerificationRequested, // Requester has requested verification of the output
        Resolved,             // Intent has been finalized (bounty distributed or returned)
        Canceled              // Intent was canceled by the requester
    }

    struct AIIntent {
        address requester;
        bytes32 intentId; // Unique ID for the intent
        bytes parametersURI; // URI pointing to detailed task parameters (e.g., IPFS hash)
        address bountyToken;
        uint256 bountyAmount;
        uint256 creationBlock;
        uint256 expirationBlock; // Block number by which the intent must be claimed
        address claimedByAgent; // Address of the agent who claimed the intent
        uint256 claimBlock;
        bytes32 outputCommitment; // Hash/commitment of the agent's output
        uint256 outputSubmissionBlock;
        IntentStatus status;
        bytes32 currentChallengeHash; // For tracking ongoing disputes/challenges, if applicable
    }

    struct AgentProfile {
        bool exists;
        bytes32 profileHash; // URI to agent's off-chain profile/metadata
        uint256 successfulTasks;
        uint256 failedTasks;
        uint256 disputesWon; // Conceptual: requires a dispute system
        uint256 disputesLost; // Conceptual: requires a dispute system
        uint256 reputationScore; // A dynamically calculated score
        mapping(bytes32 => Attestation) attestations; // Soulbound attestations
    }

    struct Attestation {
        bool exists;
        address issuer;
        bytes32 attestationDataHash; // Hash of the specific attestation data/context
        uint256 issueBlock;
        uint256 expirationBlock; // 0 for perpetual attestation
    }

    // A requester can delegate an agent to claim intents on their behalf
    struct Delegation {
        bool isActive;
        bytes32 intentCriteriaHash; // Hash representing criteria for intents that can be claimed
        uint256 maxBounty; // Max bounty the delegated agent can claim on behalf of requester
    }

    // For governance proposals to change protocol parameters
    struct ProtocolParameterProposal {
        bytes32 paramKey;
        uint256 newValue;
        uint256 votingStartBlock;
        uint256 votingEndBlock;
        uint256 yeas;
        uint256 nays;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        bool executed;
    }

    // --- State Variables ---
    mapping(bytes32 => AIIntent) public intents;
    mapping(address => AgentProfile) public agents;
    mapping(address => mapping(address => Delegation)) public intentClaimDelegations; // requester => delegatedAgent => Delegation

    // Global protocol parameters, configurable via governance
    mapping(bytes32 => uint256) public protocolParameters; // e.g., "MIN_BOUNTY", "DEFAULT_CLAIM_WINDOW", "VERIFICATION_FEE_BP"

    // Dynamic bounty multipliers for agents (e.g., for premium agents, performance bonuses)
    mapping(address => mapping(bytes32 => uint256)) public agentBountyMultipliers; // agent => multiplierType => basisPoints (e.g., 10000 for 1x, 10500 for 1.05x)

    // Current proposals for parameter changes
    mapping(bytes32 => ProtocolParameterProposal) public activeProposals; // paramKey => proposal

    // External contract for complex verification logic (e.g., ZK proof verifier, multi-party computation)
    address public verificationLogicContract;
    // Address of the trusted Attestation Issuer (can be the owner or a separate DAO governance contract)
    address public attestationIssuerAddress;

    // Agent earnings accumulated in the contract, withdrawable by agents
    mapping(address => mapping(address => uint256)) public agentEarnings; // agentAddress => tokenAddress => amount

    // --- Events ---
    event AIIntentCreated(bytes32 indexed intentId, address indexed requester, address bountyToken, uint256 bountyAmount, uint256 expirationBlock);
    event AIIntentUpdated(bytes32 indexed intentId, bytes newParametersURI);
    event AIIntentCanceled(bytes32 indexed intentId, address indexed requester);
    event AIIntentClaimed(bytes32 indexed intentId, address indexed agent, uint256 claimBlock);
    event AIOutputSubmitted(bytes32 indexed intentId, address indexed agent, bytes32 outputCommitment);
    event VerificationRequested(bytes32 indexed intentId, address indexed requester, bytes32 outputCommitment);
    event IntentOutcomeFinalized(bytes32 indexed intentId, address indexed agent, bool isOutputValid, uint256 distributedAmount);
    event AgentRegistered(address indexed agentAddress, bytes32 profileHash);
    event AttestationIssued(address indexed agentAddress, bytes32 indexed attestationType, address indexed issuer, uint256 expirationBlock);
    event AttestationRevoked(bytes32 indexed attestationType, address indexed agentAddress, address indexed revoker);
    event DelegationCreated(address indexed requester, address indexed delegatedAgent, bytes32 intentCriteriaHash, uint256 maxBounty);
    event DelegationRevoked(address indexed requester, address indexed delegatedAgent);
    event ProtocolParameterProposed(bytes32 indexed paramKey, uint256 newValue, uint256 votingEndBlock);
    event VoteCast(bytes32 indexed paramKey, address indexed voter, bool support);
    event ProtocolParameterChanged(bytes32 indexed paramKey, uint256 oldValue, uint256 newValue);
    event VerificationLogicContractSet(address indexed oldAddress, address indexed newAddress);
    event AgentPerformanceChallenged(address indexed agentAddress, address indexed challenger, uint256 challengeWeight);
    event AttestationIssuerAddressSet(address indexed oldAddress, address indexed newAddress);
    event AgentEarningsWithdrawn(address indexed agentAddress, address indexed tokenAddress, uint256 amount);


    // --- Constructor ---
    constructor(address _attestationIssuer) Ownable(msg.sender) {
        // Initialize default protocol parameters
        protocolParameters["DEFAULT_CLAIM_WINDOW_BLOCKS"] = 1000; // approx 4 hours at 14s/block
        protocolParameters["DEFAULT_VERIFICATION_WINDOW_BLOCKS"] = 2000; // approx 8 hours
        protocolParameters["MIN_BOUNTY_TOKEN_AMOUNT"] = 1 ether; // Example, depends on specific token decimals
        protocolParameters["VERIFICATION_FEE_BP"] = 500; // 5% fee basis points (conceptual, not implemented in this version)
        protocolParameters["GOVERNANCE_VOTING_DURATION_BLOCKS"] = 2000; // 8 hours for voting
        protocolParameters["REPUTATION_SUCCESS_POINTS"] = 10; // Points awarded for successful task completion
        protocolParameters["REPUTATION_FAILURE_POINTS"] = 5;  // Points deducted for failed tasks
        
        attestationIssuerAddress = _attestationIssuer; // Can be owner initially, or a separate DAO contract
    }

    // --- Modifiers ---
    modifier onlyAgent(address _agent) {
        require(agents[_agent].exists, "AetheriaNexus: Address is not a registered agent.");
        _;
    }

    modifier onlyAttestationIssuer() {
        require(msg.sender == attestationIssuerAddress || msg.sender == owner(), "AetheriaNexus: Caller is not the designated attestation issuer or owner.");
        _;
    }

    modifier intentExists(bytes32 _intentId) {
        require(intents[_intentId].requester != address(0), "AetheriaNexus: Intent does not exist.");
        _;
    }

    modifier intentNotCanceled(bytes32 _intentId) {
        require(intents[_intentId].status != IntentStatus.Canceled, "AetheriaNexus: Intent is canceled.");
        _;
    }

    modifier intentOpen(bytes32 _intentId) {
        require(intents[_intentId].status == IntentStatus.Open, "AetheriaNexus: Intent is not open.");
        require(block.number <= intents[_intentId].expirationBlock, "AetheriaNexus: Intent has expired.");
        _;
    }

    modifier intentClaimedByAgent(bytes32 _intentId, address _agent) {
        require(intents[_intentId].claimedByAgent == _agent, "AetheriaNexus: Not claimed by this agent.");
        require(intents[_intentId].status == IntentStatus.Claimed || 
                intents[_intentId].status == IntentStatus.OutputSubmitted || 
                intents[_intentId].status == IntentStatus.VerificationRequested, 
                "AetheriaNexus: Intent not in an active claimed state.");
        _;
    }

    // --- I. Core AI Intent Lifecycle (Requester-focused) ---

    /**
     * @dev Creates a new AI Intent (task) with specified parameters and bounty.
     *      Requires requester to approve bountyToken transfer to this contract first.
     * @param _intentId A unique identifier for the intent. Requesters are responsible for generating unique IDs.
     * @param _parametersURI URI pointing to the detailed task parameters (e.g., IPFS hash).
     * @param _bountyToken The ERC-20 token address for the bounty.
     * @param _bountyAmount The amount of bounty token.
     * @param _expirationBlock The block number by which the intent must be claimed. If 0, uses default.
     */
    function createAIIntent(
        bytes32 _intentId,
        bytes calldata _parametersURI,
        address _bountyToken,
        uint256 _bountyAmount,
        uint256 _expirationBlock
    ) external {
        require(intents[_intentId].requester == address(0), "AetheriaNexus: Intent ID already exists.");
        require(_bountyAmount >= protocolParameters["MIN_BOUNTY_TOKEN_AMOUNT"], "AetheriaNexus: Bounty amount too low.");
        require(_bountyToken != address(0), "AetheriaNexus: Invalid bounty token address.");
        
        uint256 finalExpirationBlock = _expirationBlock > 0 ? _expirationBlock : block.number.add(protocolParameters["DEFAULT_CLAIM_WINDOW_BLOCKS"]);
        require(finalExpirationBlock > block.number, "AetheriaNexus: Expiration block must be in the future.");

        // Transfer bounty from requester to this contract
        IERC20(_bountyToken).transferFrom(msg.sender, address(this), _bountyAmount);

        intents[_intentId] = AIIntent({
            requester: msg.sender,
            intentId: _intentId,
            parametersURI: _parametersURI,
            bountyToken: _bountyToken,
            bountyAmount: _bountyAmount,
            creationBlock: block.number,
            expirationBlock: finalExpirationBlock,
            claimedByAgent: address(0),
            claimBlock: 0,
            outputCommitment: bytes32(0),
            outputSubmissionBlock: 0,
            status: IntentStatus.Open,
            currentChallengeHash: bytes32(0)
        });

        emit AIIntentCreated(_intentId, msg.sender, _bountyToken, _bountyAmount, finalExpirationBlock);
    }

    /**
     * @dev Allows the requester to update the URI for task parameters.
     *      Can only be done if the intent is Open and not yet claimed.
     * @param _intentId The ID of the intent.
     * @param _newParametersURI The new URI pointing to updated parameters.
     */
    function updateAIIntentParameters(
        bytes32 _intentId,
        bytes calldata _newParametersURI
    ) external intentExists(_intentId) {
        AIIntent storage intent = intents[_intentId];
        require(intent.requester == msg.sender, "AetheriaNexus: Only requester can update intent parameters.");
        require(intent.status == IntentStatus.Open, "AetheriaNexus: Intent cannot be updated in its current state.");
        require(block.number <= intent.expirationBlock, "AetheriaNexus: Intent has expired and cannot be updated.");

        intent.parametersURI = _newParametersURI;
        emit AIIntentUpdated(_intentId, _newParametersURI);
    }

    /**
     * @dev Cancels an intent if it's still open and unclaimed.
     *      Returns the bounty amount to the requester.
     * @param _intentId The ID of the intent to cancel.
     */
    function cancelAIIntent(bytes32 _intentId) external intentExists(_intentId) intentNotCanceled(_intentId) {
        AIIntent storage intent = intents[_intentId];
        require(intent.requester == msg.sender, "AetheriaNexus: Only requester can cancel intent.");
        require(intent.status == IntentStatus.Open, "AetheriaNexus: Intent cannot be canceled if not in 'Open' state.");
        require(block.number <= intent.expirationBlock, "AetheriaNexus: Cannot cancel an expired intent unless it was never claimed.");


        intent.status = IntentStatus.Canceled;
        // Transfer bounty back to requester
        IERC20(intent.bountyToken).transfer(intent.requester, intent.bountyAmount);

        emit AIIntentCanceled(_intentId, msg.sender);
    }

    /**
     * @dev Requester requests verification of the agent's submitted output.
     *      This function triggers the internal or external verification mechanism.
     *      Can involve a fee for complex verification (e.g., calling an oracle).
     * @param _intentId The ID of the intent.
     * @param _agentOutputCommitment The commitment submitted by the agent.
     */
    function requestVerification(
        bytes32 _intentId,
        bytes32 _agentOutputCommitment
    ) external intentExists(_intentId) intentNotCanceled(_intentId) {
        AIIntent storage intent = intents[_intentId];
        require(intent.requester == msg.sender, "AetheriaNexus: Only requester can request verification.");
        require(intent.status == IntentStatus.OutputSubmitted, "AetheriaNexus: Output not submitted for this intent.");
        require(intent.outputCommitment == _agentOutputCommitment, "AetheriaNexus: Submitted commitment does not match.");
        
        // Optional: Charge a verification fee (e.g., from requester) - not implemented in this example
        // uint256 verificationFee = intent.bountyAmount.mul(protocolParameters["VERIFICATION_FEE_BP"]).div(10000);
        // IERC20(intent.bountyToken).transferFrom(msg.sender, address(this), verificationFee); // Requires approval

        intent.status = IntentStatus.VerificationRequested;

        // If an external verification logic contract is set, it would be called here.
        // IVerificationLogic(verificationLogicContract).initiateVerification(_intentId, ...);
        // This is a placeholder for a complex interaction with an external verification system.

        emit VerificationRequested(_intentId, msg.sender, _agentOutputCommitment);
    }

    /**
     * @dev Finalizes an intent, distributing bounty or returning it.
     *      This function is typically called by a governance entity or owner after off-chain verification.
     * @param _intentId The ID of the intent.
     * @param _isOutputValid True if the agent's output was valid, false otherwise.
     */
    function finalizeIntentOutcome(
        bytes32 _intentId,
        bool _isOutputValid
    ) external onlyOwner intentExists(_intentId) intentNotCanceled(_intentId) {
        AIIntent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.VerificationRequested || intent.status == IntentStatus.OutputSubmitted, "AetheriaNexus: Intent not in a state ready for finalization (must be OutputSubmitted or VerificationRequested).");
        require(intent.claimedByAgent != address(0), "AetheriaNexus: Intent was not claimed by an agent.");

        intent.status = IntentStatus.Resolved;
        uint256 distributedAmount = 0;

        if (_isOutputValid) {
            uint256 finalBounty = getEstimatedBounty(_intentId); // Calculate with dynamic multipliers
            agentEarnings[intent.claimedByAgent][intent.bountyToken] = agentEarnings[intent.claimedByAgent][intent.bountyToken].add(finalBounty);
            
            agents[intent.claimedByAgent].successfulTasks = agents[intent.claimedByAgent].successfulTasks.add(1);
            agents[intent.claimedByAgent].reputationScore = agents[intent.claimedByAgent].reputationScore.add(protocolParameters["REPUTATION_SUCCESS_POINTS"]);
            distributedAmount = finalBounty;

            // If there's any remaining bounty (e.g., if multiplier was less than 1x or due to fees)
            if (intent.bountyAmount > finalBounty) {
                 IERC20(intent.bountyToken).transfer(intent.requester, intent.bountyAmount.sub(finalBounty));
            }

        } else {
            // Output invalid, return full bounty to requester
            IERC20(intent.bountyToken).transfer(intent.requester, intent.bountyAmount);
            agents[intent.claimedByAgent].failedTasks = agents[intent.claimedByAgent].failedTasks.add(1);
            agents[intent.claimedByAgent].reputationScore = agents[intent.claimedByAgent].reputationScore > protocolParameters["REPUTATION_FAILURE_POINTS"] ?
                agents[intent.claimedByAgent].reputationScore.sub(protocolParameters["REPUTATION_FAILURE_POINTS"]) : 0;
            distributedAmount = 0; // No distribution to agent
        }

        emit IntentOutcomeFinalized(_intentId, intent.claimedByAgent, _isOutputValid, distributedAmount);
    }

    /**
     * @dev This function is marked as deprecated for requesters.
     *      Unused bounty funds are handled directly by `cancelAIIntent` and `finalizeIntentOutcome`.
     *      A more complex system would require a `withdrawableBalances` mapping per requester.
     */
    function withdrawUnusedBounty(address _tokenAddress) external pure {
        revert("AetheriaNexus: Function deprecated. Unused bounty handled on intent resolution. Agents use withdrawAgentEarnings.");
    }


    // --- II. Agent Interaction & Execution ---

    /**
     * @dev Registers an address as an Agent in the protocol.
     * @param _profileHash URI pointing to the agent's off-chain profile/metadata.
     */
    function registerAgentProfile(bytes32 _profileHash) external {
        require(!agents[msg.sender].exists, "AetheriaNexus: Agent already registered.");
        agents[msg.sender] = AgentProfile({
            exists: true,
            profileHash: _profileHash,
            successfulTasks: 0,
            failedTasks: 0,
            disputesWon: 0,
            disputesLost: 0,
            reputationScore: 0
        });
        emit AgentRegistered(msg.sender, _profileHash);
    }

    /**
     * @dev Allows a registered Agent to claim an open AI Intent.
     * @param _intentId The ID of the intent to claim.
     */
    function claimAIIntent(bytes32 _intentId) external onlyAgent(msg.sender) intentOpen(_intentId) {
        AIIntent storage intent = intents[_intentId];
        require(intent.claimedByAgent == address(0), "AetheriaNexus: Intent already claimed.");

        intent.claimedByAgent = msg.sender;
        intent.claimBlock = block.number;
        intent.status = IntentStatus.Claimed;

        emit AIIntentClaimed(_intentId, msg.sender, block.number);
    }

    /**
     * @dev Agent submits a cryptographic commitment (hash) of their off-chain work.
     *      This commitment will later be used for verification.
     * @param _intentId The ID of the intent.
     * @param _outputCommitment The cryptographic hash of the generated output.
     */
    function submitAIOutputCommitment(
        bytes32 _intentId,
        bytes32 _outputCommitment
    ) external onlyAgent(msg.sender) intentClaimedByAgent(_intentId, msg.sender) {
        AIIntent storage intent = intents[_intentId];
        require(intent.outputCommitment == bytes32(0), "AetheriaNexus: Output commitment already submitted.");
        require(intent.status == IntentStatus.Claimed, "AetheriaNexus: Intent not in 'Claimed' state, or already processed.");

        intent.outputCommitment = _outputCommitment;
        intent.outputSubmissionBlock = block.number;
        intent.status = IntentStatus.OutputSubmitted;

        emit AIOutputSubmitted(_intentId, msg.sender, _outputCommitment);
    }

    /**
     * @dev Allows anyone to report a malicious agent with evidence.
     *      This function primarily serves as a signal, further action would be off-chain or via governance.
     * @param _agentAddress The address of the agent being reported.
     * @param _evidenceHash A hash or URI pointing to the evidence of misconduct.
     */
    function reportMaliciousAgent(address _agentAddress, bytes32 _evidenceHash) external onlyAgent(_agentAddress) {
        // This function mainly serves as a signal. Actual penalties would be applied by
        // `finalizeIntentOutcome` if a task is failed, or by owner/governance through `revokeAttestation` or direct reputation adjustment.
        // For a more advanced system, this could trigger a dedicated dispute mechanism.
        // For now, it's a social signaling mechanism, recorded as a performance challenge.
        emit AgentPerformanceChallenged(_agentAddress, msg.sender, 0); // Reusing event for a general challenge/report
        // The _evidenceHash can be used off-chain by verifiers or governance.
    }

    /**
     * @dev Allows an Agent to withdraw their accumulated earnings for a specific token.
     *      Earnings are deposited into `agentEarnings` by `finalizeIntentOutcome`.
     * @param _tokenAddress The address of the ERC-20 token to withdraw.
     */
    function withdrawAgentEarnings(address _tokenAddress) external onlyAgent(msg.sender) {
        uint256 amount = agentEarnings[msg.sender][_tokenAddress];
        require(amount > 0, "AetheriaNexus: No earnings to withdraw for this token.");

        agentEarnings[msg.sender][_tokenAddress] = 0; // Reset balance before transfer to prevent re-entrancy
        IERC20(_tokenAddress).transfer(msg.sender, amount);

        emit AgentEarningsWithdrawn(msg.sender, _tokenAddress, amount);
    }


    // --- III. Reputation & Attestation System (Soulbound-like) ---

    /**
     * @dev Allows a designated attestation issuer to issue non-transferable attestations to agents.
     *      These are "soulbound" in the sense they are tied to the agent's address and managed by the issuer.
     * @param _agentAddress The address of the agent to issue the attestation to.
     * @param _attestationType A unique identifier for the type of attestation (e.g., "VERIFIED_ML_EXPERT").
     * @param _attestationDataHash Hash of off-chain data detailing the attestation.
     * @param _expirationBlock The block number when the attestation expires (0 for perpetual).
     */
    function issueAttestation(
        address _agentAddress,
        bytes32 _attestationType,
        bytes32 _attestationDataHash,
        uint256 _expirationBlock
    ) external onlyAttestationIssuer onlyAgent(_agentAddress) {
        AgentProfile storage agent = agents[_agentAddress];
        require(!agent.attestations[_attestationType].exists, "AetheriaNexus: Attestation of this type already exists for agent.");

        agent.attestations[_attestationType] = Attestation({
            exists: true,
            issuer: msg.sender,
            attestationDataHash: _attestationDataHash,
            issueBlock: block.number,
            expirationBlock: _expirationBlock
        });

        // Optionally, update reputation score based on attestation
        // agent.reputationScore = agent.reputationScore.add(SOME_ATTESTATION_POINTS);

        emit AttestationIssued(_agentAddress, _attestationType, msg.sender, _expirationBlock);
    }

    /**
     * @dev Allows the attestation issuer or the owner to revoke an existing attestation.
     * @param _agentAddress The agent whose attestation is being revoked.
     * @param _attestationType The type of attestation to revoke.
     */
    function revokeAttestation(address _agentAddress, bytes32 _attestationType) external onlyAttestationIssuer onlyAgent(_agentAddress) {
        AgentProfile storage agent = agents[_agentAddress];
        require(agent.attestations[_attestationType].exists, "AetheriaNexus: Attestation does not exist for agent.");

        delete agent.attestations[_attestationType];

        // Optionally, update reputation score
        // agent.reputationScore = agent.reputationScore.sub(SOME_ATTESTATION_POINTS);

        emit AttestationRevoked(_attestationType, _agentAddress, msg.sender);
    }

    /**
     * @dev Checks the status of a specific attestation for an agent.
     * @param _agentAddress The agent's address.
     * @param _attestationType The type of attestation to check.
     * @return bool True if the attestation exists and is not expired, false otherwise.
     */
    function getAgentAttestationStatus(address _agentAddress, bytes32 _attestationType) public view returns (bool) {
        AgentProfile storage agent = agents[_agentAddress];
        Attestation storage attestation = agent.attestations[_attestationType];
        return attestation.exists && (attestation.expirationBlock == 0 || block.number <= attestation.expirationBlock);
    }

    /**
     * @dev Calculates and returns a dynamic reputation score for an agent.
     *      This score is based on successful tasks, disputes, and active attestations.
     *      This is a simplified calculation for demonstration.
     * @param _agentAddress The agent's address.
     * @return uint256 The calculated reputation score.
     */
    function getAgentReputationScore(address _agentAddress) public view returns (uint256) {
        AgentProfile storage agent = agents[_agentAddress];
        if (!agent.exists) return 0;

        uint256 baseScore = agent.reputationScore; // Score updated on task resolution
        
        // Add points for specific, active attestations
        // Example: if "VERIFIED_ML_EXPERT" attestation adds 50 points
        if (getAgentAttestationStatus(_agentAddress, "VERIFIED_ML_EXPERT")) {
            baseScore = baseScore.add(50);
        }
        // Could iterate through all attestation types if a dynamic lookup is needed

        // Penalize for active challenges (if agent profile included a challenge weight)
        // if (agent.currentChallengeWeight > 0) {
        //     baseScore = baseScore.sub(agent.currentChallengeWeight);
        // }

        return baseScore;
    }

    // --- IV. Delegated Agent Autonomy ---

    /**
     * @dev A Requester authorizes another agent to claim intents on their behalf.
     *      The delegation is constrained by criteria and a maximum bounty.
     * @param _delegatedAgent The address of the agent being delegated.
     * @param _intentCriteriaHash A hash representing the specific criteria (e.g., parametersURI, bountyToken) for intents this agent can claim.
     * @param _maxBounty The maximum bounty amount for an intent the delegated agent can claim.
     */
    function delegateIntentClaim(
        address _delegatedAgent,
        bytes32 _intentCriteriaHash,
        uint256 _maxBounty
    ) external {
        require(msg.sender != _delegatedAgent, "AetheriaNexus: Cannot delegate to self.");
        require(agents[_delegatedAgent].exists, "AetheriaNexus: Delegated address is not a registered agent.");
        
        intentClaimDelegations[msg.sender][_delegatedAgent] = Delegation({
            isActive: true,
            intentCriteriaHash: _intentCriteriaHash,
            maxBounty: _maxBounty
        });

        emit DelegationCreated(msg.sender, _delegatedAgent, _intentCriteriaHash, _maxBounty);
    }

    /**
     * @dev Revokes a previously granted intent claim delegation.
     * @param _delegatedAgent The address of the agent whose delegation is being revoked.
     */
    function revokeIntentClaimDelegation(address _delegatedAgent) external {
        require(intentClaimDelegations[msg.sender][_delegatedAgent].isActive, "AetheriaNexus: No active delegation to revoke from this agent.");
        intentClaimDelegations[msg.sender][_delegatedAgent].isActive = false;
        emit DelegationRevoked(msg.sender, _delegatedAgent);
    }

    /**
     * @dev Allows a delegated agent to claim an intent on behalf of a requester.
     *      The intent must match the delegation criteria.
     * @param _intentId The ID of the intent to claim.
     * @param _requester The address of the requester who delegated the action.
     */
    function claimAIIntentDelegated(bytes32 _intentId, address _requester) external onlyAgent(msg.sender) intentOpen(_intentId) {
        AIIntent storage intent = intents[_intentId];
        Delegation storage delegation = intentClaimDelegations[_requester][msg.sender];

        require(delegation.isActive, "AetheriaNexus: Delegation is not active for this agent from this requester.");
        require(intent.requester == _requester, "AetheriaNexus: Intent not posted by specified requester for delegation.");
        require(intent.bountyAmount <= delegation.maxBounty, "AetheriaNexus: Intent bounty exceeds delegated max bounty.");
        
        // For simplicity, we skip complex hash matching. In a real system, the criteria hash would be critical:
        // require(delegation.intentCriteriaHash == calculateIntentCriteriaHash(intent.parametersURI, intent.bountyToken), "AetheriaNexus: Intent criteria mismatch.");

        require(intent.claimedByAgent == address(0), "AetheriaNexus: Intent already claimed.");

        intent.claimedByAgent = msg.sender;
        intent.claimBlock = block.number;
        intent.status = IntentStatus.Claimed;

        emit AIIntentClaimed(_intentId, msg.sender, block.number); // Emit the same event as direct claim
    }

    // --- V. Dynamic Protocol Parameters & Governance ---

    /**
     * @dev Initiates a governance proposal to change a core protocol parameter.
     *      Only the owner can propose changes for simplicity in this example.
     *      In a full DAO, this would be a more complex system open to token holders.
     * @param _paramKey The key identifying the protocol parameter (e.g., "MIN_BOUNTY_TOKEN_AMOUNT").
     * @param _newValue The new value for the parameter.
     * @param _votingDuration The duration of the voting period in blocks.
     */
    function proposeProtocolParameterChange(
        bytes32 _paramKey,
        uint256 _newValue,
        uint256 _votingDuration
    ) external onlyOwner {
        require(activeProposals[_paramKey].votingStartBlock == 0 || activeProposals[_paramKey].executed, "AetheriaNexus: A proposal for this parameter is already active or unexecuted.");
        require(_votingDuration > 0, "AetheriaNexus: Voting duration must be greater than zero.");

        activeProposals[_paramKey] = ProtocolParameterProposal({
            paramKey: _paramKey,
            newValue: _newValue,
            votingStartBlock: block.number,
            votingEndBlock: block.number.add(_votingDuration),
            yeas: 0,
            nays: 0,
            hasVoted: new mapping(address => bool), // Initialize new mapping for votes
            executed: false
        });

        emit ProtocolParameterProposed(_paramKey, _newValue, block.number.add(_votingDuration));
    }

    /**
     * @dev Allows stakeholders (e.g., registered agents) to vote on active proposals.
     * @param _paramKey The key of the parameter proposal.
     * @param _support True for 'yea' vote, false for 'nay' vote.
     */
    function voteOnParameterChange(bytes32 _paramKey, bool _support) external onlyAgent(msg.sender) {
        ProtocolParameterProposal storage proposal = activeProposals[_paramKey];
        require(proposal.votingStartBlock > 0, "AetheriaNexus: No active proposal for this parameter.");
        require(block.number >= proposal.votingStartBlock && block.number <= proposal.votingEndBlock, "AetheriaNexus: Voting period is not active.");
        require(!proposal.hasVoted[msg.sender], "AetheriaNexus: Already voted on this proposal.");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yeas = proposal.yeas.add(1);
        } else {
            proposal.nays = proposal.nays.add(1);
        }

        emit VoteCast(_paramKey, msg.sender, _support);
    }

    /**
     * @dev Executes a successfully voted-in parameter change.
     *      Requires a majority of votes and the voting period to be over.
     * @param _paramKey The key of the parameter to execute the change for.
     */
    function executeParameterChange(bytes32 _paramKey) external onlyOwner { // Can be made permissionless if proposal passes a threshold
        ProtocolParameterProposal storage proposal = activeProposals[_paramKey];
        require(proposal.votingStartBlock > 0, "AetheriaNexus: No active proposal for this parameter.");
        require(block.number > proposal.votingEndBlock, "AetheriaNexus: Voting period is not over yet.");
        require(!proposal.executed, "AetheriaNexus: Proposal already executed.");
        
        // Simple majority rule for demonstration. Can be extended to quadratic voting, token-weighted, etc.
        require(proposal.yeas > proposal.nays, "AetheriaNexus: Proposal did not pass.");

        uint256 oldValue = protocolParameters[_paramKey];
        protocolParameters[_paramKey] = proposal.newValue;
        proposal.executed = true;

        emit ProtocolParameterChanged(_paramKey, oldValue, proposal.newValue);
    }

    /**
     * @dev Sets the address of an external contract responsible for complex verification logic.
     *      This allows for upgradeability and separation of concerns.
     * @param _newVerificationLogic The address of the new verification logic contract.
     */
    function setVerificationLogicContract(address _newVerificationLogic) external onlyOwner {
        require(_newVerificationLogic != address(0), "AetheriaNexus: Verification logic contract cannot be zero address.");
        address oldAddress = verificationLogicContract;
        verificationLogicContract = _newVerificationLogic;
        emit VerificationLogicContractSet(oldAddress, _newVerificationLogic);
    }

    /**
     * @dev Sets the address of the entity designated to issue attestations.
     *      Can be the owner, a DAO, or a specific trusted oracle.
     * @param _newAttestationIssuer The address of the new attestation issuer.
     */
    function setAttestationIssuerAddress(address _newAttestationIssuer) external onlyOwner {
        require(_newAttestationIssuer != address(0), "AetheriaNexus: Attestation issuer cannot be zero address.");
        address oldAddress = attestationIssuerAddress;
        attestationIssuerAddress = _newAttestationIssuer;
        emit AttestationIssuerAddressSet(oldAddress, _newAttestationIssuer);
    }

    // --- VI. Advanced Utility & Incentives ---

    /**
     * @dev Allows governance/trusted entities to apply a dynamic bounty multiplier to specific agents.
     *      This can be used for premium agents, performance bonuses, or special programs.
     * @param _agentAddress The agent to apply the multiplier to.
     * @param _multiplierType A string identifier for the multiplier type (e.g., "PREMIUM_TIER", "PERFORMANCE_BONUS").
     * @param _multiplierBasisPoints The multiplier value in basis points (e.g., 10000 for 1x, 10500 for 1.05x).
     */
    function setDynamicBountyMultiplier(
        address _agentAddress,
        bytes32 _multiplierType,
        uint256 _multiplierBasisPoints
    ) external onlyOwner onlyAgent(_agentAddress) {
        require(_multiplierBasisPoints > 0, "AetheriaNexus: Multiplier must be greater than 0.");
        agentBountyMultipliers[_agentAddress][_multiplierType] = _multiplierBasisPoints;
        // Event for multiplier change could be added: emit BountyMultiplierSet(_agentAddress, _multiplierType, _multiplierBasisPoints);
    }

    /**
     * @dev Calculates the estimated bounty for an intent, considering all active dynamic multipliers for the claimed agent.
     * @param _intentId The ID of the intent.
     * @return uint256 The estimated bounty amount.
     */
    function getEstimatedBounty(bytes32 _intentId) public view intentExists(_intentId) returns (uint256) {
        AIIntent storage intent = intents[_intentId];
        uint256 baseBounty = intent.bountyAmount;

        if (intent.claimedByAgent == address(0)) {
            return baseBounty; // No agent claimed, no multipliers apply yet
        }

        uint256 totalMultiplierBasisPoints = 10000; // Start with 1x (10000 basis points)

        // Iterate through all possible multiplier types. This is a simplification.
        // A real system would need to store active multiplier types or dynamically add them via governance.
        // For demonstration, let's hardcode a few known types.
        bytes32[] memory knownMultiplierTypes = new bytes32[](2); 
        knownMultiplierTypes[0] = "PREMIUM_TIER";
        knownMultiplierTypes[1] = "PERFORMANCE_BONUS";

        for (uint i = 0; i < knownMultiplierTypes.length; i++) {
            uint256 multiplier = agentBountyMultipliers[intent.claimedByAgent][knownMultiplierTypes[i]];
            if (multiplier > 0) {
                // Apply cumulatively. Simple additive to the basis points for example.
                // e.g., if PREMIUM_TIER is 10200 (1.02x) and PERFORMANCE_BONUS is 10300 (1.03x)
                // totalMultiplierBasisPoints = 10000 + (10200-10000) + (10300-10000) = 10000 + 200 + 300 = 10500 (1.05x)
                totalMultiplierBasisPoints = totalMultiplierBasisPoints.add(multiplier.sub(10000)); 
            }
        }
        
        // Ensure total multiplier is at least 1x (10000 basis points)
        if (totalMultiplierBasisPoints < 10000) totalMultiplierBasisPoints = 10000;

        return baseBounty.mul(totalMultiplierBasisPoints).div(10000);
    }

    /**
     * @dev Allows designated entities to place a "performance challenge" on an agent.
     *      This is distinct from reporting malicious behavior and focuses on quality/performance concerns.
     *      Could affect reputation score or trigger specific reviews.
     * @param _agentAddress The agent whose performance is being challenged.
     * @param _challengeWeight An arbitrary weight/severity of the challenge.
     */
    function challengeAgentPerformance(address _agentAddress, uint256 _challengeWeight) external onlyOwner onlyAgent(_agentAddress) {
        // This function would primarily act as a signal. Its effects (e.g., temporary reputation penalty, 
        // triggering a review process) would be handled off-chain or by further governance actions.
        // For example, this could set a flag on the AgentProfile that a verification committee would consider.
        require(_challengeWeight > 0, "AetheriaNexus: Challenge weight must be positive.");
        // Example: agents[_agentAddress].activeChallenges.push(ChallengeInfo(...));
        emit AgentPerformanceChallenged(_agentAddress, msg.sender, _challengeWeight);
    }

    // --- Helper / View Functions ---

    /**
     * @dev Helper function to check if a specific proposal is active.
     */
    function isProposalActive(bytes32 _paramKey) external view returns (bool) {
        ProtocolParameterProposal storage proposal = activeProposals[_paramKey];
        return proposal.votingStartBlock > 0 && block.number >= proposal.votingStartBlock && block.number <= proposal.votingEndBlock && !proposal.executed;
    }

    /**
     * @dev Calculates a hash for delegation criteria.
     *      (Placeholder: In a real implementation, this would involve hashing actual criteria parameters.)
     * @param _parametersURI The URI for task parameters.
     * @param _bountyToken The bounty token address.
     * @return bytes32 A hash representing the intent criteria.
     */
    function calculateIntentCriteriaHash(bytes calldata _parametersURI, address _bountyToken) public pure returns (bytes32) {
        // This is a simplified example. A real implementation would parse _parametersURI if it's structured data
        // and hash relevant fields, along with other on-chain criteria (e.g., min reputation, attestation requirements).
        return keccak256(abi.encodePacked(_parametersURI, _bountyToken));
    }
}
```