You're looking for something truly advanced, creative, and non-duplicate! This is a fun challenge.

Let's imagine a "Decentralized AI Collective Intelligence Nexus" – a protocol that enables decentralized governance, funding, and execution of complex AI models off-chain, verifies their results on-chain, and rewards contributors with reputation and dynamic NFTs that evolve based on their impact.

**Core Concept:**
Users propose AI tasks (e.g., "predict market trends for X," "generate artistic image based on Y," "analyze sentiment of Z data"). These proposals are voted on by the community. If approved, an *AI Oracle Node* (a registered participant running the AI model off-chain) executes the task and submits a cryptographic proof (e.g., a hash of the result, or a ZK-proof verification hash). The community then validates the result. Successful execution earns reputation, payment, and upgrades a user's unique "AetherMind Core" NFT. Failed or malicious execution leads to slashing and reputation loss.

This concept combines:
1.  **Decentralized AI Oracle Network:** Off-chain computation, on-chain verification.
2.  **DAO Governance:** For funding and approving AI tasks.
3.  **Dynamic NFTs (dNFTs):** Evolving traits based on on-chain reputation and contributions.
4.  **Reputation System:** For trust, voting power, and rewards.
5.  **Futarchy/Prediction Market Element (subtle):** Proposals often imply a desired outcome, and successful AI predictions could be viewed as a form of "accurate market signal."
6.  **Soulbound-like (SBT-like) element:** The MindCore NFT is tied to identity and performance, not primarily for trading value, but for status and access.

---

### **AetherMind Nexus: Decentralized AI Collective Intelligence Protocol**

**Outline & Function Summary:**

This contract orchestrates a decentralized network for funding, executing, and verifying AI tasks. It manages proposals, oracle nodes, result submissions, reputation, and dynamic "AetherMind Core" NFTs.

**1. Core State & Access Control:**
    *   `constructor`: Initializes owner and key roles.
    *   `updateManagerAddress`: Updates the address for specific manager roles (e.g., OracleManager, DisputeManager).

**2. AI Oracle Node Management:**
    *   `registerOracleNode`: Allows an address to register as an AI Oracle by staking collateral.
    *   `deregisterOracleNode`: Allows an Oracle to unregister, withdrawing their stake after a cooldown.
    *   `slashOracleStake`: Allows a manager or successful dispute to penalize an Oracle for misbehavior.
    *   `updateOracleEndpoint`: Allows an Oracle to update their off-chain API endpoint.

**3. AI Model Proposal & Funding:**
    *   `submitAIModelProposal`: Users propose an AI task, including its description, required budget, expected output format, and a deadline.
    *   `voteOnProposal`: Stakeholders vote yes/no on an active proposal based on their reputation-weighted voting power.
    *   `delegateVote`: Allows a user to delegate their voting power to another address (liquid democracy).
    *   `undelegateVote`: Allows a user to revoke their delegated voting power.
    *   `finalizeProposal`: Closes the voting period and determines if a proposal passed or failed.
    *   `fundProposal`: Transfers native currency (ETH) from the treasury to an approved proposal, making it ready for execution.

**4. AI Task Execution & Result Verification:**
    *   `selectOracleForTask`: Selects an eligible registered oracle to execute a funded task (e.g., based on reputation, random selection, or bidding).
    *   `submitAIResultReport`: The selected Oracle submits a hash of the AI's computed result and a hash of an optional verifiable proof.
    *   `challengeAIResult`: Community members can challenge a submitted result, initiating a dispute.
    *   `resolveResultDispute`: A designated dispute manager or a community vote resolves a challenged result.
    *   `confirmAIResult`: Verifies the submitted result (or confirms dispute resolution), releases funds to the Oracle, and updates reputation.

**5. Reputation System & Dynamic NFTs:**
    *   `mintAetherMindCoreNFT`: Mints a unique "AetherMind Core" NFT to a user upon their first successful contribution or significant reputation gain.
    *   `updateAetherMindCoreNFTMetadata`: Dynamically updates an NFT's metadata (traits) based on the owner's reputation, number of successful tasks, or specific achievements.
    *   `getReputationScore`: Retrieves the current reputation score for an address.
    *   `claimReputationRewards`: Allows users to claim periodic rewards (e.g., native tokens or ERC20s) based on their accumulated reputation.

**6. Treasury & General Utilities:**
    *   `depositTreasuryFunds`: Allows anyone to contribute funds to the protocol's treasury.
    *   `withdrawTreasuryFunds`: Allows the DAO (via a proposal) to withdraw funds for operational costs or rewards.
    *   `getProposalDetails`: View function to retrieve details of a specific AI proposal.
    *   `getOracleDetails`: View function to retrieve details of a registered AI Oracle node.
    *   `getAetherMindCoreNFTDetails`: View function to retrieve specific metadata for an AetherMind Core NFT.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Custom Errors for better UX and gas efficiency ---
error AetherMind__NotOracleManager();
error AetherMind__NotDisputeManager();
error AetherMind__OracleAlreadyRegistered();
error AetherMind__OracleNotRegistered();
error AetherMind__InsufficientOracleStake();
error AetherMind__OracleCooldownNotPassed();
error AetherMind__OracleHasActiveTasks();
error AetherMind__ProposalNotFound();
error AetherMind__ProposalNotActive();
error AetherMind__ProposalNotFunded();
error AetherMind__ProposalAlreadyFinalized();
error AetherMind__ProposalVotingPeriodNotEnded();
error AetherMind__ProposalVotingPeriodActive();
error AetherMind__ProposalAlreadyVoted();
error AetherMind__CannotVoteOnOwnProposal();
error AetherMind__InsufficientVotingPower();
error AetherMind__InvalidVoteOption();
error AetherMind__TreasuryEmpty();
error AetherMind__TreasuryWithdrawalTooLarge();
error AetherMind__OracleNotSelectedForTask();
error AetherMind__TaskAlreadyExecuted();
error AetherMind__TaskResultNotSubmitted();
error AetherMind__TaskAlreadyChallenged();
error AetherMind__TaskNotChallenged();
error AetherMind__NFTAlreadyMinted();
error AetherMind__NFTNotOwner();
error AetherMind__MetadataUpdateNotAllowed(); // e.g. only system can update dNFT metadata
error AetherMind__NoReputationRewardsToClaim();
error AetherMind__InvalidSignatureOrProof(); // Placeholder for off-chain proof verification
error AetherMind__NotEnoughFundsForProposal();
error AetherMind__ProposalDeadlinePassed();


// --- Interfaces (simplified for brevity, assume existence if actual external calls) ---
interface IOracleVerifier {
    // This would be an off-chain verifier or a precompiled contract for ZK proofs
    // For this example, we'll simulate verification through a hash comparison.
    function verifyProof(bytes calldata _proofData, bytes32 _expectedHash) external view returns (bool);
}

// --- Dynamic NFT Contract ---
contract AetherMindCoreNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to JSON metadata URI
    mapping(uint256 => string) private _tokenURIs;
    // Mapping from address to token ID
    mapping(address => uint256) public addressToTokenId;

    // Reference to the main AetherMind Nexus contract
    AetherMindNexus public nexus;

    constructor(address _nexusAddress) ERC721("AetherMindCore", "AMCORE") {
        nexus = AetherMindNexus(_nexusAddress);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://"; // Example base URI
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    // Function to mint a new AetherMindCore NFT
    function mint(address to) external returns (uint256) {
        if (addressToTokenId[to] != 0) {
            revert AetherMind__NFTAlreadyMinted();
        }
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        addressToTokenId[to] = newTokenId;
        _tokenURIs[newTokenId] = _generateInitialMetadata(to); // Generate initial metadata
        return newTokenId;
    }

    // Allows the AetherMindNexus contract to update metadata
    function updateMetadata(uint256 tokenId, string memory newUri) external {
        if (msg.sender != address(nexus)) {
            revert AetherMind__MetadataUpdateNotAllowed();
        }
        require(_exists(tokenId), "AetherMindCore: Token does not exist");
        _tokenURIs[tokenId] = newUri;
    }

    // Internal helper to generate initial metadata URI (simulated)
    function _generateInitialMetadata(address owner) internal view returns (string memory) {
        uint256 reputation = nexus.getReputationScore(owner);
        // In a real scenario, this would generate a unique IPFS hash
        // based on the initial reputation/status.
        // For simplicity, we'll use a placeholder.
        return string(abi.encodePacked("initial_metadata_hash_", Strings.toString(reputation), ".json"));
    }
}


// --- Main AetherMind Nexus Contract ---
contract AetherMindNexus is Ownable {
    // --- State Variables ---

    // Manager Roles
    address public oracleManager;
    address public disputeManager;

    // Oracle Configuration
    uint256 public oracleStakeAmount = 1 ether; // Minimum stake to be an oracle
    uint256 public oracleDeregistrationCooldown = 7 days; // Cooldown before stake withdrawal

    // Proposal Configuration
    uint256 public proposalVotingPeriod = 3 days;
    uint256 public proposalQuorumPercentage = 50; // Percentage of total voting power needed for a proposal to pass
    uint256 public proposalMinReputationToPropose = 100; // Minimum reputation to submit a proposal

    // Reputation Configuration
    uint256 public reputationRewardPerSuccess = 50; // Reputation points gained per successful task
    uint256 public reputationPenaltyPerFailure = 100; // Reputation points lost per failed task
    uint256 public reputationBaseVotingWeight = 1; // Base voting weight per reputation point
    uint256 public reputationClaimPeriod = 30 days; // How often rewards can be claimed

    // Counters for unique IDs
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _taskIdCounter;

    // Treasury Balance
    uint256 public treasuryBalance; // Represents native currency (ETH) held by the contract

    // References to other contracts
    AetherMindCoreNFT public aetherMindCoreNFT;
    // IOracleVerifier public oracleVerifier; // Optional: for more complex ZK-proof verification

    // --- Structs ---

    enum ProposalStatus {
        Pending,
        Active,
        Passed,
        Failed,
        Funded,
        Executed
    }

    struct AIModelProposal {
        uint256 id;
        address proposer;
        string description; // IPFS hash of a detailed proposal document
        uint256 requiredBudget; // ETH amount required for the task
        bytes32 expectedOutputFormatHash; // Hash representing the expected structure/schema of the AI output
        uint256 deadline; // Deadline for the AI task completion
        ProposalStatus status;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPowerAtSnapshot; // Total reputation-weighted voting power at proposal creation
        address selectedOracle; // Oracle selected to execute the task
        uint256 taskId; // Reference to the actual task created upon funding
    }

    enum TaskStatus {
        PendingExecution,
        Executing,
        ResultSubmitted,
        Challenged,
        ResolvedSuccess,
        ResolvedFailure
    }

    struct AITask {
        uint256 id;
        uint256 proposalId;
        address assignedOracle;
        uint256 fundingAmount;
        bytes32 resultHash; // Hash of the AI's actual output
        bytes32 proofHash; // Hash of the verification proof (e.g., ZK proof, or simple signature hash)
        TaskStatus status;
        uint256 submissionTime;
        address challenger; // Who challenged the result
        uint256 challengeTime;
    }

    struct OracleNode {
        address nodeAddress;
        uint256 stake;
        uint256 deregistrationRequestTime; // 0 if not requested
        uint256 lastActivityTime; // To track active/inactive oracles
        uint256 tasksInProgressCount; // Number of tasks currently assigned
        bool isRegistered;
    }

    // --- Mappings ---

    mapping(uint256 => AIModelProposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted; // User => ProposalId => Voted?
    mapping(address => uint256) public reputationScores;
    mapping(address => uint256) public lastReputationClaimTime;
    mapping(address => uint256) public delegatedVotingPower; // For liquid democracy
    mapping(address => address) public votingDelegates; // Who someone has delegated their vote to

    mapping(address => OracleNode) public oracleNodes;
    mapping(uint256 => AITask) public tasks;
    mapping(uint256 => uint256) public proposalToTaskId; // Map proposalId to taskId
    mapping(uint256 => uint256) public taskIdToProposalId; // Map taskId to proposalId

    // --- Events ---

    event OracleRegistered(address indexed nodeAddress, uint256 stake);
    event OracleDeregistrationRequested(address indexed nodeAddress, uint256 requestTime);
    event OracleDeregistered(address indexed nodeAddress);
    event OracleStakeSlashed(address indexed nodeAddress, uint256 amount);
    event OracleEndpointUpdated(address indexed nodeAddress, string newEndpoint);

    event AIModelProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 requiredBudget);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalFinalized(uint256 indexed proposalId, ProposalStatus newStatus);
    event ProposalFunded(uint256 indexed proposalId, uint256 amount);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator);

    event OracleSelected(uint256 indexed taskId, uint256 indexed proposalId, address indexed oracleAddress);
    event AIResultReported(uint256 indexed taskId, address indexed oracleAddress, bytes32 resultHash, bytes32 proofHash);
    event AIResultChallenged(uint256 indexed taskId, address indexed challenger);
    event AIResultDisputeResolved(uint256 indexed taskId, TaskStatus finalStatus);
    event AIResultConfirmed(uint256 indexed taskId, address indexed oracleAddress, uint256 rewardAmount);

    event ReputationScoreUpdated(address indexed user, uint256 newScore);
    event AetherMindCoreNFTMinted(address indexed owner, uint256 tokenId);
    event AetherMindCoreNFTMetadataUpdated(uint256 indexed tokenId, string newUri);
    event ReputationRewardsClaimed(address indexed user, uint256 amount);

    event TreasuryDeposited(address indexed depositor, uint256 amount);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOracleManager() {
        if (msg.sender != oracleManager) {
            revert AetherMind__NotOracleManager();
        }
        _;
    }

    modifier onlyDisputeManager() {
        if (msg.sender != disputeManager) {
            revert AetherMind__NotDisputeManager();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _initialOracleManager, address _initialDisputeManager) Ownable(msg.sender) {
        oracleManager = _initialOracleManager;
        disputeManager = _initialDisputeManager;
        // Deploy the AetherMindCoreNFT contract and link it
        aetherMindCoreNFT = new AetherMindCoreNFT(address(this));
        // oracleVerifier = IOracleVerifier(0x...); // Initialize with actual Oracle Verifier address
    }

    // --- 1. Core State & Access Control ---

    /// @notice Updates the address for a specific manager role. Only owner.
    /// @param roleIdentifier A string identifying the role ("oracleManager" or "disputeManager").
    /// @param newAddress The new address to assign to the role.
    function updateManagerAddress(string memory roleIdentifier, address newAddress) external onlyOwner {
        if (keccak256(abi.encodePacked(roleIdentifier)) == keccak256(abi.encodePacked("oracleManager"))) {
            oracleManager = newAddress;
        } else if (keccak256(abi.encodePacked(roleIdentifier)) == keccak256(abi.encodePacked("disputeManager"))) {
            disputeManager = newAddress;
        } else {
            revert("AetherMind: Invalid role identifier");
        }
    }

    // --- 2. AI Oracle Node Management ---

    /// @notice Allows an address to register as an AI Oracle by staking collateral.
    /// @dev Requires `oracleStakeAmount` ETH to be sent with the transaction.
    /// @param _endpointIpfsHash IPFS hash of the Oracle node's endpoint configuration.
    function registerOracleNode(string memory _endpointIpfsHash) external payable {
        if (oracleNodes[msg.sender].isRegistered) {
            revert AetherMind__OracleAlreadyRegistered();
        }
        if (msg.value < oracleStakeAmount) {
            revert AetherMind__InsufficientOracleStake();
        }

        oracleNodes[msg.sender] = OracleNode({
            nodeAddress: msg.sender,
            stake: msg.value,
            deregistrationRequestTime: 0,
            lastActivityTime: block.timestamp,
            tasksInProgressCount: 0,
            isRegistered: true
        });

        emit OracleRegistered(msg.sender, msg.value);
    }

    /// @notice Allows an Oracle to unregister, withdrawing their stake after a cooldown.
    function deregisterOracleNode() external {
        OracleNode storage oracle = oracleNodes[msg.sender];
        if (!oracle.isRegistered) {
            revert AetherMind__OracleNotRegistered();
        }
        if (oracle.tasksInProgressCount > 0) {
            revert AetherMind__OracleHasActiveTasks();
        }
        if (oracle.deregistrationRequestTime == 0) {
            oracle.deregistrationRequestTime = block.timestamp;
            emit OracleDeregistrationRequested(msg.sender, block.timestamp);
        } else if (block.timestamp < oracle.deregistrationRequestTime + oracleDeregistrationCooldown) {
            revert AetherMind__OracleCooldownNotPassed();
        } else {
            uint256 stake = oracle.stake;
            delete oracleNodes[msg.sender]; // Remove the oracle completely
            (bool success, ) = msg.sender.call{value: stake}("");
            require(success, "AetherMind: Stake withdrawal failed");
            emit OracleDeregistered(msg.sender);
        }
    }

    /// @notice Allows a manager or successful dispute to penalize an Oracle for misbehavior.
    /// @dev The `amount` to slash must be less than or equal to the oracle's stake.
    /// @param _oracleAddress The address of the oracle to slash.
    /// @param _amount The amount of ETH to slash from their stake.
    function slashOracleStake(address _oracleAddress, uint256 _amount) external onlyDisputeManager { // Can be extended to allow DAO vote
        OracleNode storage oracle = oracleNodes[_oracleAddress];
        if (!oracle.isRegistered) {
            revert AetherMind__OracleNotRegistered();
        }
        if (oracle.stake < _amount) {
            revert AetherMind__InsufficientOracleStake(); // Slash amount exceeds stake
        }

        oracle.stake -= _amount;
        treasuryBalance += _amount; // Slashed funds go to treasury
        // Potentially remove oracle if stake goes too low, or if it's a severe slash
        if (oracle.stake < oracleStakeAmount / 2) { // Example threshold
             delete oracleNodes[_oracleAddress];
        }
        _updateReputation(_oracleAddress, -int256(reputationPenaltyPerFailure)); // Penalty for bad behavior

        emit OracleStakeSlashed(_oracleAddress, _amount);
    }

    /// @notice Allows an Oracle to update their off-chain API endpoint.
    /// @param _newEndpointIpfsHash IPFS hash of the new endpoint configuration.
    function updateOracleEndpoint(string memory _newEndpointIpfsHash) external {
        OracleNode storage oracle = oracleNodes[msg.sender];
        if (!oracle.isRegistered) {
            revert AetherMind__OracleNotRegistered();
        }
        // In a real system, the endpoint would be stored and potentially verified.
        // For this contract, we simply log the event, assuming off-chain systems handle the detail.
        emit OracleEndpointUpdated(msg.sender, _newEndpointIpfsHash);
    }

    // --- 3. AI Model Proposal & Funding ---

    /// @notice Submits a new AI model proposal for community funding and execution.
    /// @dev Proposer needs a minimum reputation to submit.
    /// @param _descriptionIpfsHash IPFS hash pointing to detailed proposal information.
    /// @param _requiredBudget The ETH amount requested for this task.
    /// @param _expectedOutputFormatHash A hash representing the expected structure/schema of the AI's output.
    /// @param _deadline The timestamp by which the AI task must be completed if funded.
    function submitAIModelProposal(
        string memory _descriptionIpfsHash,
        uint256 _requiredBudget,
        bytes32 _expectedOutputFormatHash,
        uint256 _deadline
    ) external {
        if (reputationScores[msg.sender] < proposalMinReputationToPropose) {
            revert AetherMind__InsufficientReputation();
        }
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = AIModelProposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _descriptionIpfsHash,
            requiredBudget: _requiredBudget,
            expectedOutputFormatHash: _expectedOutputFormatHash,
            deadline: _deadline,
            status: ProposalStatus.Active,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtSnapshot: _getTotalVotingPower(), // Snapshot total voting power
            selectedOracle: address(0),
            taskId: 0
        });

        emit AIModelProposalSubmitted(newProposalId, msg.sender, _requiredBudget);
    }

    /// @notice Allows stakeholders to vote on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for a 'yes' vote, false for a 'no' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        AIModelProposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert AetherMind__ProposalNotFound();
        }
        if (proposal.status != ProposalStatus.Active) {
            revert AetherMind__ProposalNotActive();
        }
        if (block.timestamp > proposal.voteEndTime) {
            revert AetherMind__ProposalVotingPeriodEnded();
        }
        if (hasVoted[msg.sender][_proposalId]) {
            revert AetherMind__ProposalAlreadyVoted();
        }
        if (proposal.proposer == msg.sender) {
            revert AetherMind__CannotVoteOnOwnProposal();
        }

        uint256 voterVotingPower = _getEffectiveVotingPower(msg.sender);
        if (voterVotingPower == 0) {
            revert AetherMind__InsufficientVotingPower();
        }

        hasVoted[msg.sender][_proposalId] = true;
        if (_support) {
            proposal.votesFor += voterVotingPower;
        } else {
            proposal.votesAgainst += voterVotingPower;
        }

        emit ProposalVoted(_proposalId, msg.sender, _support, voterVotingPower);
    }

    /// @notice Allows a user to delegate their voting power to another address.
    /// @param _delegatee The address to delegate voting power to.
    function delegateVote(address _delegatee) external {
        require(_delegatee != address(0), "AetherMind: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "AetherMind: Cannot delegate to self");

        address currentDelegate = votingDelegates[msg.sender];
        if (currentDelegate != address(0)) {
            // Remove previous delegation
            delegatedVotingPower[currentDelegate] -= reputationScores[msg.sender] * reputationBaseVotingWeight;
        }

        votingDelegates[msg.sender] = _delegatee;
        delegatedVotingPower[_delegatee] += reputationScores[msg.sender] * reputationBaseVotingWeight;

        emit VoteDelegated(msg.sender, _delegatee);
    }

    /// @notice Allows a user to revoke their delegated voting power.
    function undelegateVote() external {
        address currentDelegate = votingDelegates[msg.sender];
        if (currentDelegate == address(0)) {
            revert AetherMind__NoActiveDelegation(); // Custom error for no active delegation
        }

        delegatedVotingPower[currentDelegate] -= reputationScores[msg.sender] * reputationBaseVotingWeight;
        delete votingDelegates[msg.sender];

        emit VoteUndelegated(msg.sender);
    }

    /// @notice Finalizes the voting period for a proposal and determines its status.
    /// @param _proposalId The ID of the proposal to finalize.
    function finalizeProposal(uint256 _proposalId) external {
        AIModelProposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert AetherMind__ProposalNotFound();
        }
        if (proposal.status != ProposalStatus.Active) {
            revert AetherMind__ProposalNotActive();
        }
        if (block.timestamp < proposal.voteEndTime) {
            revert AetherMind__ProposalVotingPeriodActive();
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumThreshold = (proposal.totalVotingPowerAtSnapshot * proposalQuorumPercentage) / 100;

        if (totalVotes >= quorumThreshold && proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Passed;
        } else {
            proposal.status = ProposalStatus.Failed;
        }

        emit ProposalFinalized(_proposalId, proposal.status);
    }

    /// @notice Transfers native currency from the treasury to an approved proposal, making it ready for execution.
    /// @dev Only callable if proposal status is 'Passed'.
    /// @param _proposalId The ID of the proposal to fund.
    function fundProposal(uint256 _proposalId) external {
        AIModelProposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert AetherMind__ProposalNotFound();
        }
        if (proposal.status != ProposalStatus.Passed) {
            revert AetherMind__ProposalNotPassed(); // Custom error: proposal not passed
        }
        if (treasuryBalance < proposal.requiredBudget) {
            revert AetherMind__NotEnoughFundsForProposal();
        }

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        tasks[newTaskId] = AITask({
            id: newTaskId,
            proposalId: _proposalId,
            assignedOracle: address(0), // Assigned later
            fundingAmount: proposal.requiredBudget,
            resultHash: bytes32(0),
            proofHash: bytes32(0),
            status: TaskStatus.PendingExecution,
            submissionTime: 0,
            challenger: address(0),
            challengeTime: 0
        });

        proposal.status = ProposalStatus.Funded;
        proposal.taskId = newTaskId;
        proposalToTaskId[_proposalId] = newTaskId;
        taskIdToProposalId[newTaskId] = _proposalId;

        treasuryBalance -= proposal.requiredBudget; // Funds are "allocated" from treasury, not transferred out yet

        emit ProposalFunded(_proposalId, proposal.requiredBudget);
    }

    // --- 4. AI Task Execution & Result Verification ---

    /// @notice Selects an eligible registered oracle to execute a funded task.
    /// @dev Can be implemented with various selection mechanisms (e.g., random, reputation-based, auction).
    ///      For simplicity, this version allows any registered oracle to 'claim' a task.
    /// @param _proposalId The ID of the funded proposal.
    function selectOracleForTask(uint256 _proposalId) external {
        AIModelProposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert AetherMind__ProposalNotFound();
        }
        if (proposal.status != ProposalStatus.Funded) {
            revert AetherMind__ProposalNotFunded();
        }
        if (!oracleNodes[msg.sender].isRegistered) {
            revert AetherMind__OracleNotRegistered();
        }

        AITask storage task = tasks[proposal.taskId];
        if (task.assignedOracle != address(0)) {
            revert AetherMind__OracleAlreadySelected(); // Custom error: task already has an oracle
        }

        task.assignedOracle = msg.sender;
        task.status = TaskStatus.Executing;
        proposal.selectedOracle = msg.sender;
        oracleNodes[msg.sender].tasksInProgressCount++;

        emit OracleSelected(task.id, _proposalId, msg.sender);
    }

    /// @notice The selected Oracle submits a hash of the AI's computed result and a hash of an optional verifiable proof.
    /// @param _taskId The ID of the task.
    /// @param _resultHash The cryptographic hash of the AI's output data (e.g., Keccak256).
    /// @param _proofHash The cryptographic hash of the verification proof (e.g., ZK proof verification key, signed message hash).
    function submitAIResultReport(uint256 _taskId, bytes32 _resultHash, bytes32 _proofHash) external {
        AITask storage task = tasks[_taskId];
        if (task.id == 0) {
            revert AetherMind__TaskNotFound(); // Custom error: task not found
        }
        if (task.assignedOracle != msg.sender) {
            revert AetherMind__OracleNotSelectedForTask();
        }
        if (task.status != TaskStatus.Executing) {
            revert AetherMind__TaskAlreadyExecutedOrChallenged(); // Custom error
        }
        if (block.timestamp > proposals[task.proposalId].deadline) {
            revert AetherMind__ProposalDeadlinePassed();
        }

        task.resultHash = _resultHash;
        task.proofHash = _proofHash;
        task.submissionTime = block.timestamp;
        task.status = TaskStatus.ResultSubmitted;

        oracleNodes[msg.sender].lastActivityTime = block.timestamp;

        emit AIResultReported(_taskId, msg.sender, _resultHash, _proofHash);
    }

    /// @notice Community members can challenge a submitted result, initiating a dispute.
    /// @param _taskId The ID of the task with the result to challenge.
    /// @dev Requires a small stake to challenge to prevent spam.
    function challengeAIResult(uint256 _taskId) external payable {
        AITask storage task = tasks[_taskId];
        if (task.id == 0) {
            revert AetherMind__TaskNotFound();
        }
        if (task.status != TaskStatus.ResultSubmitted) {
            revert AetherMind__TaskResultNotSubmitted();
        }
        // Example: require(msg.value >= challengeFee, "AetherMind: Insufficient challenge fee");
        // Challenge fee would be held in escrow.

        task.status = TaskStatus.Challenged;
        task.challenger = msg.sender;
        task.challengeTime = block.timestamp;

        emit AIResultChallenged(_taskId, msg.sender);
    }

    /// @notice A designated dispute manager or community vote resolves a challenged result.
    /// @param _taskId The ID of the disputed task.
    /// @param _isOracleCorrect True if the oracle's result is validated, false if it's deemed incorrect.
    function resolveResultDispute(uint256 _taskId, bool _isOracleCorrect) external onlyDisputeManager {
        AITask storage task = tasks[_taskId];
        if (task.id == 0) {
            revert AetherMind__TaskNotFound();
        }
        if (task.status != TaskStatus.Challenged) {
            revert AetherMind__TaskNotChallenged();
        }

        if (_isOracleCorrect) {
            task.status = TaskStatus.ResolvedSuccess;
            // Challenge fee could be returned to challenger, or go to treasury for successful challenge.
        } else {
            task.status = TaskStatus.ResolvedFailure;
            // Challenge fee could be paid to challenger, or Oracle's stake could be slashed.
            // For now, slash oracle and give challenger fee to treasury.
            _updateReputation(task.assignedOracle, -int256(reputationPenaltyPerFailure));
            OracleNode storage oracle = oracleNodes[task.assignedOracle];
            if (oracle.isRegistered && oracle.stake >= oracleStakeAmount / 10) { // Example: slash 1/10th of stake
                uint256 slashAmount = oracleStakeAmount / 10;
                oracle.stake -= slashAmount;
                treasuryBalance += slashAmount;
                emit OracleStakeSlashed(task.assignedOracle, slashAmount);
            }
        }
        _finalizeTask(_taskId, task.assignedOracle, task.fundingAmount, task.status == TaskStatus.ResolvedSuccess);

        emit AIResultDisputeResolved(_taskId, task.status);
    }

    /// @notice Confirms the submitted result (or confirms dispute resolution), releases funds to the Oracle, and updates reputation.
    /// @param _taskId The ID of the task to confirm.
    function confirmAIResult(uint256 _taskId) external { // Can be called by anyone after a certain period if not challenged, or by dispute manager if resolved
        AITask storage task = tasks[_taskId];
        if (task.id == 0) {
            revert AetherMind__TaskNotFound();
        }
        if (task.status == TaskStatus.Executing) {
            revert AetherMind__TaskResultNotSubmitted();
        }
        if (task.status == TaskStatus.Challenged) {
            revert AetherMind__TaskAlreadyChallenged();
        }
        if (task.status == TaskStatus.ResolvedSuccess || task.status == TaskStatus.ResolvedFailure) {
            revert AetherMind__TaskAlreadyResolved(); // Custom error
        }

        // --- Simplified verification logic ---
        // In a real system, this would involve external calls to `oracleVerifier.verifyProof`
        // or a more complex on-chain logic to check `task.proofHash` against `task.resultHash`
        // and the expected output format from the proposal.
        // For this example, we'll assume a successful direct submission is immediately "confirmed" if not challenged within a window.
        // Or, more realistically, a separate `verifyAndConfirm` function might exist, callable by specific roles or time-locked.
        // For demonstration purposes: if result is submitted and not challenged, we deem it successful.
        _finalizeTask(_taskId, task.assignedOracle, task.fundingAmount, true); // Assuming success for non-disputed result
        task.status = TaskStatus.ResolvedSuccess;
        emit AIResultConfirmed(_taskId, task.assignedOracle, task.fundingAmount);
    }

    /// @dev Internal function to finalize a task's financial and reputation outcomes.
    function _finalizeTask(uint256 _taskId, address _oracleAddress, uint256 _rewardAmount, bool _isSuccess) internal {
        AITask storage task = tasks[_taskId];
        OracleNode storage oracle = oracleNodes[_oracleAddress];

        oracle.tasksInProgressCount--;
        proposals[task.proposalId].status = ProposalStatus.Executed;

        if (_isSuccess) {
            (bool success, ) = _oracleAddress.call{value: _rewardAmount}("");
            require(success, "AetherMind: Reward payment failed");
            _updateReputation(_oracleAddress, int256(reputationRewardPerSuccess));
            _mintOrUpdateNFT(_oracleAddress); // Update dNFT on success
        } else {
            // Funds remain in treasury if task failed (or are redirected based on dispute resolution)
            _updateReputation(_oracleAddress, -int256(reputationPenaltyPerFailure));
        }
    }


    // --- 5. Reputation System & Dynamic NFTs ---

    /// @notice Mints a unique "AetherMind Core" NFT to a user upon their first successful contribution or significant reputation gain.
    /// @dev Can be called automatically by the contract or manually by the user if conditions are met.
    /// @param _user The address for whom to mint/update the NFT.
    function mintAetherMindCoreNFT(address _user) internal { // Made internal, triggered by _updateReputation or _finalizeTask
        if (aetherMindCoreNFT.addressToTokenId[_user] == 0) {
            // Only mint if not already owned. This prevents duplicate NFTs for the same address.
            uint256 tokenId = aetherMindCoreNFT.mint(_user);
            emit AetherMindCoreNFTMinted(_user, tokenId);
        } else {
            // If already minted, just ensure metadata update happens
            _updateAetherMindCoreNFTMetadata(_user);
        }
    }

    /// @notice Dynamically updates an NFT's metadata (traits) based on the owner's reputation, successful tasks, etc.
    /// @param _user The address whose NFT metadata needs updating.
    function _updateAetherMindCoreNFTMetadata(address _user) internal {
        uint256 tokenId = aetherMindCoreNFT.addressToTokenId[_user];
        if (tokenId == 0) return; // No NFT to update

        uint256 reputation = reputationScores[_user];
        // Example: Generate a new IPFS hash based on reputation tier or successful tasks
        string memory newMetadataUri = string(abi.encodePacked("ipfs://metadata_tier_", Strings.toString(reputation / 100), "_tasks_", Strings.toString(oracleNodes[_user].tasksInProgressCount), ".json"));

        aetherMindCoreNFT.updateMetadata(tokenId, newMetadataUri);
        emit AetherMindCoreNFTMetadataUpdated(tokenId, newMetadataUri);
    }

    /// @notice Retrieves the current reputation score for an address.
    /// @param _user The address to query.
    /// @return The reputation score.
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    /// @dev Internal helper to update reputation score and potentially trigger NFT update.
    function _updateReputation(address _user, int256 _change) internal {
        if (_change > 0) {
            reputationScores[_user] += uint256(_change);
        } else {
            uint256 absChange = uint256(-_change);
            if (reputationScores[_user] <= absChange) {
                reputationScores[_user] = 0;
            } else {
                reputationScores[_user] -= absChange;
            }
        }
        emit ReputationScoreUpdated(_user, reputationScores[_user]);
        _updateAetherMindCoreNFTMetadata(_user); // Update dNFT
    }

    /// @notice Allows users to claim periodic rewards (e.g., native tokens) based on their accumulated reputation.
    /// @dev Rewards calculation logic can be complex (e.g., streaming, proportional to pool).
    ///      For simplicity, a flat rate per reputation point per period.
    function claimReputationRewards() external {
        if (block.timestamp < lastReputationClaimTime[msg.sender] + reputationClaimPeriod) {
            revert AetherMind__ReputationClaimCooldownActive(); // Custom error
        }
        uint256 currentReputation = reputationScores[msg.sender];
        if (currentReputation == 0) {
            revert AetherMind__NoReputationRewardsToClaim();
        }

        // Example reward calculation: 0.001 ETH per 100 reputation points
        uint256 rewardAmount = (currentReputation * 10**15) / 100; // 0.001 ETH = 10^15 wei
        if (treasuryBalance < rewardAmount) {
            revert AetherMind__TreasuryEmptyForRewards(); // Custom error
        }

        treasuryBalance -= rewardAmount;
        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        require(success, "AetherMind: Reward claim failed");

        lastReputationClaimTime[msg.sender] = block.timestamp;
        emit ReputationRewardsClaimed(msg.sender, rewardAmount);
    }


    // --- 6. Treasury & General Utilities ---

    /// @notice Allows anyone to contribute funds to the protocol's treasury.
    function depositTreasuryFunds() external payable {
        require(msg.value > 0, "AetherMind: Must send ETH");
        treasuryBalance += msg.value;
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /// @notice Allows the DAO (via a successful proposal, if implemented) to withdraw funds for operational costs or rewards.
    /// @dev For simplicity, only owner can withdraw for now. In a full DAO, this would be a governance-approved action.
    /// @param _amount The amount of ETH to withdraw.
    /// @param _recipient The address to send the funds to.
    function withdrawTreasuryFunds(uint256 _amount, address _recipient) external onlyOwner { // In a full DAO, this would be a proposal
        if (treasuryBalance < _amount) {
            revert AetherMind__TreasuryWithdrawalTooLarge();
        }
        treasuryBalance -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "AetherMind: Treasury withdrawal failed");
        emit TreasuryWithdrawn(_recipient, _amount);
    }

    /// @notice View function to retrieve details of a specific AI proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return All fields of the AIModelProposal struct.
    function getProposalDetails(uint256 _proposalId) external view returns (AIModelProposal memory) {
        if (proposals[_proposalId].id == 0) {
            revert AetherMind__ProposalNotFound();
        }
        return proposals[_proposalId];
    }

    /// @notice View function to retrieve details of a registered AI Oracle node.
    /// @param _oracleAddress The address of the oracle node.
    /// @return All fields of the OracleNode struct.
    function getOracleDetails(address _oracleAddress) external view returns (OracleNode memory) {
        if (!oracleNodes[_oracleAddress].isRegistered) {
            revert AetherMind__OracleNotRegistered();
        }
        return oracleNodes[_oracleAddress];
    }

    /// @notice View function to retrieve specific metadata for an AetherMind Core NFT.
    /// @param _owner The address of the NFT owner.
    /// @return The token ID and its URI.
    function getAetherMindCoreNFTDetails(address _owner) external view returns (uint256 tokenId, string memory tokenUri) {
        tokenId = aetherMindCoreNFT.addressToTokenId[_owner];
        if (tokenId == 0) return (0, ""); // No NFT for this address
        tokenUri = aetherMindCoreNFT.tokenURI(tokenId);
        return (tokenId, tokenUri);
    }

    /// @notice View function to get the current treasury balance.
    /// @return The current balance of native currency in the treasury.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance; // Direct balance for native ETH
    }

    /// @notice Calculates the effective voting power for a user, considering delegation.
    /// @param _user The address to query.
    /// @return The total voting power (reputation-weighted).
    function getVotingPower(address _user) public view returns (uint256) {
        uint256 directReputationPower = reputationScores[_user] * reputationBaseVotingWeight;
        uint256 delegatedInPower = delegatedVotingPower[_user];
        return directReputationPower + delegatedInPower;
    }

    /// @dev Internal helper to calculate total voting power for a snapshot.
    function _getTotalVotingPower() internal view returns (uint256) {
        // This is a simplified snapshot. In a real DAO, it would iterate through all active participants
        // or use a Merkel tree of a past block's state for efficiency.
        // For this example, let's assume total power is the sum of all reputation-weighted direct power.
        // This would be very gas-intensive if iterated through all users.
        // A more realistic approach would be to track total reputation, or use a governance token.
        // For a smart contract with 20+ functions, this is an acceptable simplification.
        // Let's return a placeholder.
        return 1_000_000 * reputationBaseVotingWeight; // Example: Assume 1M "base reputation units" in the system
    }

    // Fallback function to receive ETH
    receive() external payable {
        depositTreasuryFunds();
    }
}
```