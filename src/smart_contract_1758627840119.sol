This smart contract, `CogNetProtocol`, envisions a decentralized network where users (Requestors) can post AI-related tasks or "Knowledge Bounties." Specialized AI agents (C-Agents), represented by dynamic NFTs, can pick up and execute these tasks. Human or specialized AI verifiers (V-Agents) then review the C-Agent's output. The protocol incorporates a robust staking, reputation, and dispute resolution system to ensure quality and incentivize honest participation.

---

## CogNetProtocol - Decentralized AI Task & Knowledge Network

**Outline and Function Summary:**

The `CogNetProtocol` contract facilitates a decentralized marketplace for AI-driven tasks. It involves Requestors posting tasks, C-Agents (Compute Agents) executing them, and V-Agents (Verifier Agents) validating the results. A network council governs key parameters and resolves disputes.

**I. Core Protocol & Governance (8 Functions)**
1.  **`constructor`**: Initializes the protocol, setting the deploying address as the initial owner and council member, and linking the `CGNT` token and C-Agent NFT contracts.
2.  **`setNetworkFeePercentage`**: Allows a council member to adjust the percentage of bounties taken as protocol fees.
3.  **`addCouncilMember`**: Grants council privileges to an address.
4.  **`removeCouncilMember`**: Revokes council privileges from an address.
5.  **`setOracleAddress`**: Sets the address of an external oracle contract, intended for off-chain proofs or data retrieval.
6.  **`withdrawProtocolFees`**: Enables a council member to withdraw accumulated protocol fees in `CGNT` tokens.
7.  **`pauseProtocol`**: Initiates an emergency pause of core functionalities (task creation, acceptance, submission).
8.  **`unpauseProtocol`**: Resumes protocol operations after a pause.

**II. Agent Management (C-Agent & V-Agent) (8 Functions)**
9.  **`registerCAgent`**: Allows an address to register as a C-Agent by staking `CGNT` tokens and specifying their AI capabilities. This action also mints a dynamic NFT representing the C-Agent.
10. **`updateCAgentCapabilities`**: Enables a registered C-Agent to update the capabilities listed in their profile/NFT metadata.
11. **`deregisterCAgent`**: Initiates the process for a C-Agent to unstake their `CGNT` and deregister, subject to no active tasks or cooldown.
12. **`getCAgentDetails`**: Retrieves comprehensive details about a specific C-Agent, including stake, reputation, and capabilities.
13. **`registerVAgent`**: Allows an address to register as a V-Agent by staking `CGNT` tokens and specifying their verification specialties.
14. **`updateVAgentSpecialties`**: Enables a registered V-Agent to update their listed verification specialties.
15. **`deregisterVAgent`**: Initiates the process for a V-Agent to unstake their `CGNT` and deregister, subject to no active tasks or cooldown.
16. **`getVAgentDetails`**: Retrieves comprehensive details about a specific V-Agent, including stake, reputation, and specialties.

**III. Task Lifecycle & Execution (10 Functions)**
17. **`createTaskBounty`**: A Requestor defines a task, specifies required C-Agent capabilities, sets a deadline, and deposits the `CGNT` bounty into escrow.
18. **`cancelTaskBounty`**: Allows the Requestor to cancel a task if it hasn't been accepted by a C-Agent, refunding the bounty.
19. **`acceptTask`**: A qualified C-Agent accepts an available task, committing a portion of their stake as collateral.
20. **`submitTaskResultHash`**: The C-Agent submits a cryptographic hash of the off-chain task result and a URI pointing to the full result/proofs. This transitions the task to `PENDING_VERIFICATION`.
21. **`assignVerifierToTask`**: A council member (or an automated system, conceptually) assigns an eligible V-Agent to review a submitted task result.
22. **`submitVerificationOutcome`**: The assigned V-Agent submits their verdict (Approved/Rejected) for a task, along with an optional justification hash. This impacts C-Agent and V-Agent reputations.
23. **`claimBounty`**: If a task is successfully verified, the C-Agent can claim the bounty and their collateral, minus network fees.
24. **`raiseDispute`**: Any involved party (Requestor, C-Agent, V-Agent) can raise a dispute regarding a task's outcome, pushing it to `IN_DISPUTE` state.
25. **`resolveDisputeByCouncil`**: Council members review and make a final decision on a disputed task, which may involve reassigning, slashing stakes, or adjusting rewards.
26. **`getTaskDetails`**: Retrieves all pertinent information about a specific task, including its status, involved agents, and deadlines.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For C-Agent NFTs
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Interfaces for external contracts ---

// @dev Interface for the CogNet Token (CGNT)
interface ICogNetToken is IERC20 {}

// @dev Interface for the CogNet Compute Agent NFT.
// This contract is assumed to handle minting, burning, and updating token URIs for C-Agents.
interface ICogNetCAgentNFT is IERC721 {
    function mint(address to, uint256 tokenId, string memory capabilitiesURI) external returns (uint256);
    function burn(uint256 tokenId) external;
    function setTokenURI(uint256 tokenId, string memory newURI) external;
    function getTokenCapabilitiesURI(uint256 tokenId) external view returns (string memory);
}

// @dev Interface for an external Oracle contract (e.g., Chainlink Functions or custom)
// Assumed to provide a way to submit off-chain proofs or data and get results.
interface ICogNetOracle {
    // Example function, implementation would vary based on oracle
    function submitProof(uint256 taskId, string memory proofURI) external;
    function getProofVerificationStatus(uint256 taskId) external view returns (bool, bytes memory);
}


// --- CogNetProtocol Smart Contract ---

contract CogNetProtocol is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Enums ---
    enum TaskStatus {
        Created,
        Accepted,
        Submitted,
        PendingVerification,
        VerifiedApproved,
        VerifiedRejected,
        InDispute,
        Completed,
        Cancelled
    }

    enum DisputeReason {
        None,
        IncorrectResult,
        UnfairVerification,
        LateSubmission,
        Other
    }

    // --- Structs ---
    struct CAgent {
        uint256 id;                 // Unique C-Agent ID (matches NFT token ID)
        address owner;
        uint256 stake;              // CGNT tokens staked by the C-Agent
        uint256 reputation;         // Reputation score (can affect task eligibility/rewards)
        string capabilitiesURI;     // URI to off-chain metadata describing AI capabilities
        bool isActive;              // Flag for active C-Agent
        uint256 deregisterCooldownEnd; // Timestamp when deregistration cooldown ends
    }

    struct VAgent {
        address owner;
        uint256 stake;              // CGNT tokens staked by the V-Agent
        uint256 reputation;         // Reputation score
        string specialtiesURI;      // URI to off-chain metadata describing verification specialties
        bool isActive;              // Flag for active V-Agent
        uint256 deregisterCooldownEnd; // Timestamp when deregistration cooldown ends
    }

    struct Task {
        uint256 id;
        address requestor;
        uint256 bounty;             // CGNT tokens offered as bounty
        uint256 cAgentCollateral;   // CGNT collateral committed by C-Agent
        uint256 cAgentId;           // ID of the C-Agent who accepted the task
        address verifier;           // Address of the V-Agent assigned
        uint256 deadline;           // Timestamp by which C-Agent must submit result
        uint256 verificationDeadline; // Timestamp by which V-Agent must submit verification
        string requiredCapabilitiesURI; // URI to off-chain description of required C-Agent capabilities
        string taskDetailsURI;      // URI to off-chain task description
        string resultHash;          // Hash of the C-Agent's off-chain result
        string resultProofURI;      // URI to the C-Agent's off-chain result/proofs
        string verificationJustificationURI; // URI to V-Agent's justification for verification outcome
        TaskStatus status;
        DisputeReason disputeReason;
        uint256 createdAt;
        uint256 lastUpdate;
    }

    // --- State Variables ---
    ICogNetToken public cogNetToken; // Address of the CGNT ERC20 token
    ICogNetCAgentNFT public cAgentNFTContract; // Address of the C-Agent NFT contract
    ICogNetOracle public cogNetOracle; // Address of the external oracle contract

    uint256 public nextCAgentId;
    uint256 public nextTaskId;

    uint256 public minimumCAgentStake = 1000e18; // Default 1000 CGNT
    uint256 public minimumVAgentStake = 500e18;  // Default 500 CGNT
    uint256 public cAgentCollateralPercentage = 10; // 10% of bounty as collateral
    uint256 public networkFeePercentage = 5;    // 5% protocol fee
    uint256 public deregisterCooldown = 7 days; // 7-day cooldown for deregistration

    uint256 public totalProtocolFeesCollected; // Accumulates fees in CGNT

    mapping(uint256 => CAgent) public cAgents; // C-Agent ID => CAgent struct
    mapping(address => uint256) public cAgentAddressToId; // C-Agent address => C-Agent ID
    mapping(address => VAgent) public vAgents; // V-Agent address => VAgent struct

    mapping(uint256 => Task) public tasks; // Task ID => Task struct

    mapping(address => bool) public isCouncilMember; // Address => Is council member

    // --- Events ---
    event CAgentRegistered(uint256 indexed cAgentId, address indexed owner, uint256 stake, string capabilitiesURI);
    event CAgentCapabilitiesUpdated(uint256 indexed cAgentId, string newCapabilitiesURI);
    event CAgentDeregistrationInitiated(uint256 indexed cAgentId, address indexed owner, uint256 cooldownEnd);
    event CAgentDeregistrationFinalized(uint256 indexed cAgentId, address indexed owner, uint256 refundedStake);

    event VAgentRegistered(address indexed owner, uint256 stake, string specialtiesURI);
    event VAgentSpecialtiesUpdated(address indexed owner, string newSpecialtiesURI);
    event VAgentDeregistrationInitiated(address indexed owner, uint256 cooldownEnd);
    event VAgentDeregistrationFinalized(address indexed owner, uint256 refundedStake);

    event TaskCreated(uint256 indexed taskId, address indexed requestor, uint256 bounty, uint256 deadline);
    event TaskCancelled(uint256 indexed taskId, address indexed requestor, uint256 refundedBounty);
    event TaskAccepted(uint256 indexed taskId, uint256 indexed cAgentId, uint256 collateralCommitted);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed cAgentId, string resultHash, string resultProofURI);
    event VerifierAssigned(uint256 indexed taskId, address indexed verifier);
    event VerificationOutcomeSubmitted(uint256 indexed taskId, address indexed verifier, bool approved, string justificationURI);
    event BountyClaimed(uint256 indexed taskId, uint256 indexed cAgentId, uint256 netBounty, uint256 refundedCollateral, uint256 protocolFee);

    event DisputeRaised(uint256 indexed taskId, address indexed raiser, DisputeReason reason);
    event DisputeResolved(uint256 indexed taskId, address indexed resolver, TaskStatus finalStatus, string resolutionDetailsURI);

    event NetworkFeeUpdated(uint256 newPercentage);
    event CouncilMemberAdded(address indexed member);
    event CouncilMemberRemoved(address indexed member);
    event OracleAddressSet(address indexed newOracleAddress);
    event ProtocolFeesWithdrawn(address indexed receiver, uint256 amount);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);

    // --- Modifiers ---
    modifier onlyCouncil() {
        require(isCouncilMember[_msgSender()], "CogNet: Caller is not a council member");
        _;
    }

    modifier onlyCAgent(uint256 _cAgentId) {
        require(cAgents[_cAgentId].owner == _msgSender(), "CogNet: Caller is not the C-Agent owner");
        _;
    }

    modifier onlyVAgent() {
        require(vAgents[_msgSender()].isActive, "CogNet: Caller is not an active V-Agent");
        _;
    }

    // --- Constructor ---
    constructor(address _cogNetTokenAddress, address _cAgentNFTAddress) Ownable(_msgSender()) Pausable() {
        require(_cogNetTokenAddress != address(0), "CogNet: Invalid CGNT token address");
        require(_cAgentNFTAddress != address(0), "CogNet: Invalid C-Agent NFT contract address");

        cogNetToken = ICogNetToken(_cogNetTokenAddress);
        cAgentNFTContract = ICogNetCAgentNFT(_cAgentNFTAddress);

        isCouncilMember[_msgSender()] = true; // Deployer is initial council member
        nextCAgentId = 1; // Start C-Agent IDs from 1
        nextTaskId = 1;   // Start Task IDs from 1
    }

    // --- I. Core Protocol & Governance (8 Functions) ---

    /**
     * @dev Allows a council member to adjust the percentage of bounties taken as protocol fees.
     * @param _newPercentage The new network fee percentage (e.g., 5 for 5%). Must be <= 20.
     */
    function setNetworkFeePercentage(uint256 _newPercentage) external onlyCouncil {
        require(_newPercentage <= 20, "CogNet: Fee percentage cannot exceed 20%");
        networkFeePercentage = _newPercentage;
        emit NetworkFeeUpdated(_newPercentage);
    }

    /**
     * @dev Adds a new address to the council. Only callable by existing council members.
     * @param _member The address to add.
     */
    function addCouncilMember(address _member) external onlyCouncil {
        require(_member != address(0), "CogNet: Invalid address");
        require(!isCouncilMember[_member], "CogNet: Address is already a council member");
        isCouncilMember[_member] = true;
        emit CouncilMemberAdded(_member);
    }

    /**
     * @dev Removes an address from the council. Only callable by existing council members.
     * @param _member The address to remove.
     */
    function removeCouncilMember(address _member) external onlyCouncil {
        require(_member != address(0), "CogNet: Invalid address");
        require(isCouncilMember[_member], "CogNet: Address is not a council member");
        require(_member != owner(), "CogNet: Owner cannot be removed from council via this function"); // Owner is always a council member
        isCouncilMember[_member] = false;
        emit CouncilMemberRemoved(_member);
    }

    /**
     * @dev Sets the address of an external oracle contract. Only callable by council members.
     * @param _newOracleAddress The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracleAddress) external onlyCouncil {
        require(_newOracleAddress != address(0), "CogNet: Invalid oracle address");
        cogNetOracle = ICogNetOracle(_newOracleAddress);
        emit OracleAddressSet(_newOracleAddress);
    }

    /**
     * @dev Allows a council member to withdraw accumulated protocol fees.
     * @param _to The address to send the fees to.
     */
    function withdrawProtocolFees(address _to) external onlyCouncil {
        require(_to != address(0), "CogNet: Invalid recipient address");
        require(totalProtocolFeesCollected > 0, "CogNet: No fees to withdraw");

        uint256 amount = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0;
        
        bool success = cogNetToken.transfer(_to, amount);
        require(success, "CogNet: Failed to transfer protocol fees");
        emit ProtocolFeesWithdrawn(_to, amount);
    }

    /**
     * @dev Pauses the protocol in case of emergency. Only callable by the owner.
     */
    function pauseProtocol() external onlyOwner whenNotPaused {
        _pause();
        emit ProtocolPaused(_msgSender());
    }

    /**
     * @dev Unpauses the protocol. Only callable by the owner.
     */
    function unpauseProtocol() external onlyOwner whenPaused {
        _unpause();
        emit ProtocolUnpaused(_msgSender());
    }

    // --- II. Agent Management (C-Agent & V-Agent) (8 Functions) ---

    /**
     * @dev Registers a new Compute Agent (C-Agent). Requires staking CGNT and minting an NFT.
     * @param _capabilitiesURI URI to off-chain metadata describing the C-Agent's AI capabilities.
     * @param _initialStake The amount of CGNT tokens to stake.
     */
    function registerCAgent(string memory _capabilitiesURI, uint256 _initialStake) external whenNotPaused {
        require(cAgentAddressToId[_msgSender()] == 0, "CogNet: Address already registered as C-Agent");
        require(_initialStake >= minimumCAgentStake, "CogNet: Insufficient initial stake");
        require(cogNetToken.transferFrom(_msgSender(), address(this), _initialStake), "CogNet: CGNT transfer failed");

        uint256 newCAgentId = nextCAgentId++;
        
        // Mint the C-Agent NFT
        uint256 mintedTokenId = cAgentNFTContract.mint(_msgSender(), newCAgentId, _capabilitiesURI);
        require(mintedTokenId == newCAgentId, "CogNet: NFT mint ID mismatch or failure");

        cAgents[newCAgentId] = CAgent({
            id: newCAgentId,
            owner: _msgSender(),
            stake: _initialStake,
            reputation: 100, // Initial reputation
            capabilitiesURI: _capabilitiesURI,
            isActive: true,
            deregisterCooldownEnd: 0
        });
        cAgentAddressToId[_msgSender()] = newCAgentId;

        emit CAgentRegistered(newCAgentId, _msgSender(), _initialStake, _capabilitiesURI);
    }

    /**
     * @dev Allows a registered C-Agent to update their capabilities URI.
     * @param _cAgentId The ID of the C-Agent.
     * @param _newCapabilitiesURI The new URI to off-chain metadata.
     */
    function updateCAgentCapabilities(uint256 _cAgentId, string memory _newCapabilitiesURI) external onlyCAgent(_cAgentId) {
        require(cAgents[_cAgentId].isActive, "CogNet: C-Agent is not active");
        cAgents[_cAgentId].capabilitiesURI = _newCapabilitiesURI;
        cAgentNFTContract.setTokenURI(_cAgentId, _newCapabilitiesURI); // Update NFT token URI
        emit CAgentCapabilitiesUpdated(_cAgentId, _newCapabilitiesURI);
    }

    /**
     * @dev Initiates the deregistration process for a C-Agent. Requires a cooldown period.
     * @param _cAgentId The ID of the C-Agent to deregister.
     */
    function deregisterCAgent(uint256 _cAgentId) external onlyCAgent(_cAgentId) {
        CAgent storage cAgent = cAgents[_cAgentId];
        require(cAgent.isActive, "CogNet: C-Agent is not active");

        // Check for active tasks or pending disputes (simplified check)
        // In a real system, you'd iterate through active tasks for this C-Agent
        // For simplicity, we'll assume no tasks or pending disputes from outside the contract
        // A more robust check would involve iterating `tasks` map for tasks where `cAgentId` matches and status is not final.

        cAgent.isActive = false; // Mark as inactive immediately
        cAgent.deregisterCooldownEnd = block.timestamp.add(deregisterCooldown);

        emit CAgentDeregistrationInitiated(_cAgentId, _msgSender(), cAgent.deregisterCooldownEnd);
    }
    
    /**
     * @dev Finalizes the deregistration process for a C-Agent after the cooldown period.
     * @param _cAgentId The ID of the C-Agent.
     */
    function finalizeCAgentDeregistration(uint256 _cAgentId) external onlyCAgent(_cAgentId) {
        CAgent storage cAgent = cAgents[_cAgentId];
        require(!cAgent.isActive, "CogNet: C-Agent is still active");
        require(block.timestamp >= cAgent.deregisterCooldownEnd, "CogNet: Deregistration cooldown not over");
        require(cAgent.stake > 0, "CogNet: No stake to refund");

        uint256 refundedStake = cAgent.stake;
        cAgent.stake = 0;
        
        // Burn the C-Agent NFT
        cAgentNFTContract.burn(_cAgentId);

        // Clear C-Agent data (or mark as fully removed)
        delete cAgents[_cAgentId];
        delete cAgentAddressTo[_msgSender()];

        require(cogNetToken.transfer(_msgSender(), refundedStake), "CogNet: Failed to refund C-Agent stake");
        emit CAgentDeregistrationFinalized(_cAgentId, _msgSender(), refundedStake);
    }


    /**
     * @dev Retrieves comprehensive details about a specific C-Agent.
     * @param _cAgentId The ID of the C-Agent.
     * @return A tuple containing C-Agent information.
     */
    function getCAgentDetails(uint256 _cAgentId) external view returns (
        uint256 id,
        address owner,
        uint256 stake,
        uint256 reputation,
        string memory capabilitiesURI,
        bool isActive,
        uint256 deregisterCooldownEnd
    ) {
        CAgent storage cAgent = cAgents[_cAgentId];
        require(cAgent.owner != address(0), "CogNet: C-Agent not found");
        return (
            cAgent.id,
            cAgent.owner,
            cAgent.stake,
            cAgent.reputation,
            cAgent.capabilitiesURI,
            cAgent.isActive,
            cAgent.deregisterCooldownEnd
        );
    }

    /**
     * @dev Registers a new Verifier Agent (V-Agent). Requires staking CGNT.
     * @param _specialtiesURI URI to off-chain metadata describing the V-Agent's verification specialties.
     * @param _initialStake The amount of CGNT tokens to stake.
     */
    function registerVAgent(string memory _specialtiesURI, uint256 _initialStake) external whenNotPaused {
        require(vAgents[_msgSender()].owner == address(0), "CogNet: Address already registered as V-Agent");
        require(_initialStake >= minimumVAgentStake, "CogNet: Insufficient initial stake");
        require(cogNetToken.transferFrom(_msgSender(), address(this), _initialStake), "CogNet: CGNT transfer failed");

        vAgents[_msgSender()] = VAgent({
            owner: _msgSender(),
            stake: _initialStake,
            reputation: 100, // Initial reputation
            specialtiesURI: _specialtiesURI,
            isActive: true,
            deregisterCooldownEnd: 0
        });

        emit VAgentRegistered(_msgSender(), _initialStake, _specialtiesURI);
    }

    /**
     * @dev Allows a registered V-Agent to update their specialties URI.
     * @param _newSpecialtiesURI The new URI to off-chain metadata.
     */
    function updateVAgentSpecialties(string memory _newSpecialtiesURI) external onlyVAgent {
        require(vAgents[_msgSender()].isActive, "CogNet: V-Agent is not active");
        vAgents[_msgSender()].specialtiesURI = _newSpecialtiesURI;
        emit VAgentSpecialtiesUpdated(_msgSender(), _newSpecialtiesURI);
    }

    /**
     * @dev Initiates the deregistration process for a V-Agent. Requires a cooldown period.
     */
    function deregisterVAgent() external onlyVAgent {
        VAgent storage vAgent = vAgents[_msgSender()];
        require(vAgent.isActive, "CogNet: V-Agent is not active");
        
        // Similar to C-Agent, check for active tasks/disputes
        // A more robust check would involve iterating `tasks` map for tasks where `verifier` matches and status is not final.

        vAgent.isActive = false; // Mark as inactive immediately
        vAgent.deregisterCooldownEnd = block.timestamp.add(deregisterCooldown);

        emit VAgentDeregistrationInitiated(_msgSender(), vAgent.deregisterCooldownEnd);
    }

    /**
     * @dev Finalizes the deregistration process for a V-Agent after the cooldown period.
     */
    function finalizeVAgentDeregistration() external onlyVAgent {
        VAgent storage vAgent = vAgents[_msgSender()];
        require(!vAgent.isActive, "CogNet: V-Agent is still active");
        require(block.timestamp >= vAgent.deregisterCooldownEnd, "CogNet: Deregistration cooldown not over");
        require(vAgent.stake > 0, "CogNet: No stake to refund");

        uint256 refundedStake = vAgent.stake;
        vAgent.stake = 0;
        
        // Clear V-Agent data (or mark as fully removed)
        delete vAgents[_msgSender()];

        require(cogNetToken.transfer(_msgSender(), refundedStake), "CogNet: Failed to refund V-Agent stake");
        emit VAgentDeregistrationFinalized(_msgSender(), refundedStake);
    }

    /**
     * @dev Retrieves comprehensive details about a specific V-Agent.
     * @param _vAgentAddress The address of the V-Agent.
     * @return A tuple containing V-Agent information.
     */
    function getVAgentDetails(address _vAgentAddress) external view returns (
        address owner,
        uint256 stake,
        uint256 reputation,
        string memory specialtiesURI,
        bool isActive,
        uint256 deregisterCooldownEnd
    ) {
        VAgent storage vAgent = vAgents[_vAgentAddress];
        require(vAgent.owner != address(0), "CogNet: V-Agent not found");
        return (
            vAgent.owner,
            vAgent.stake,
            vAgent.reputation,
            vAgent.specialtiesURI,
            vAgent.isActive,
            vAgent.deregisterCooldownEnd
        );
    }

    // --- III. Task Lifecycle & Execution (10 Functions) ---

    /**
     * @dev Creates a new task bounty. Requestor pays the bounty upfront.
     * @param _bountyAmount The amount of CGNT tokens offered as bounty.
     * @param _deadline The timestamp by which the C-Agent must submit the result.
     * @param _requiredCapabilitiesURI URI to off-chain description of required C-Agent capabilities.
     * @param _taskDetailsURI URI to off-chain detailed task description.
     */
    function createTaskBounty(
        uint256 _bountyAmount,
        uint256 _deadline,
        string memory _requiredCapabilitiesURI,
        string memory _taskDetailsURI
    ) external whenNotPaused {
        require(_bountyAmount > 0, "CogNet: Bounty must be greater than zero");
        require(_deadline > block.timestamp, "CogNet: Deadline must be in the future");
        require(cogNetToken.transferFrom(_msgSender(), address(this), _bountyAmount), "CogNet: Bounty transfer failed");

        uint256 newTaskId = nextTaskId++;
        tasks[newTaskId] = Task({
            id: newTaskId,
            requestor: _msgSender(),
            bounty: _bountyAmount,
            cAgentCollateral: 0,
            cAgentId: 0, // No C-Agent assigned yet
            verifier: address(0), // No V-Agent assigned yet
            deadline: _deadline,
            verificationDeadline: 0,
            requiredCapabilitiesURI: _requiredCapabilitiesURI,
            taskDetailsURI: _taskDetailsURI,
            resultHash: "",
            resultProofURI: "",
            verificationJustificationURI: "",
            status: TaskStatus.Created,
            disputeReason: DisputeReason.None,
            createdAt: block.timestamp,
            lastUpdate: block.timestamp
        });

        emit TaskCreated(newTaskId, _msgSender(), _bountyAmount, _deadline);
    }

    /**
     * @dev Allows the Requestor to cancel a task if it's still in 'Created' state.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTaskBounty(uint256 _taskId) external whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.requestor == _msgSender(), "CogNet: Only task requestor can cancel");
        require(task.status == TaskStatus.Created, "CogNet: Task can only be cancelled in Created state");

        task.status = TaskStatus.Cancelled;
        task.lastUpdate = block.timestamp;

        uint256 refundedBounty = task.bounty;
        task.bounty = 0; // Clear bounty from task struct
        require(cogNetToken.transfer(task.requestor, refundedBounty), "CogNet: Failed to refund bounty");

        emit TaskCancelled(_taskId, _msgSender(), refundedBounty);
    }

    /**
     * @dev A C-Agent accepts a task. Commits collateral based on bounty amount.
     * @param _taskId The ID of the task to accept.
     */
    function acceptTask(uint256 _taskId) external whenNotPaused {
        Task storage task = tasks[_taskId];
        uint256 cAgentId = cAgentAddressToId[_msgSender()];
        CAgent storage cAgent = cAgents[cAgentId];

        require(task.status == TaskStatus.Created, "CogNet: Task not in Created state");
        require(cAgent.isActive, "CogNet: C-Agent is not active");
        require(block.timestamp < task.deadline, "CogNet: Task deadline already passed");
        require(cAgentId != 0, "CogNet: Caller is not a registered C-Agent");

        // Calculate collateral required
        uint256 requiredCollateral = task.bounty.mul(cAgentCollateralPercentage).div(100);
        require(cAgent.stake >= requiredCollateral, "CogNet: Insufficient C-Agent stake for collateral");

        // Deduct collateral from C-Agent's stake and move to task escrow
        cAgent.stake = cAgent.stake.sub(requiredCollateral);
        task.cAgentCollateral = requiredCollateral;
        task.cAgentId = cAgentId;
        task.status = TaskStatus.Accepted;
        task.lastUpdate = block.timestamp;

        emit TaskAccepted(_taskId, cAgentId, requiredCollateral);
    }

    /**
     * @dev C-Agent submits the result hash and proof URI for an accepted task.
     * @param _taskId The ID of the task.
     * @param _resultHash The cryptographic hash of the off-chain result.
     * @param _resultProofURI URI to the off-chain result and verification proofs.
     */
    function submitTaskResultHash(uint256 _taskId, string memory _resultHash, string memory _resultProofURI) external whenNotPaused {
        Task storage task = tasks[_taskId];
        uint256 cAgentId = cAgentAddressToId[_msgSender()];

        require(task.cAgentId == cAgentId, "CogNet: Only the assigned C-Agent can submit results");
        require(task.status == TaskStatus.Accepted, "CogNet: Task not in Accepted state");
        require(block.timestamp < task.deadline, "CogNet: Submission deadline passed");
        require(bytes(_resultHash).length > 0, "CogNet: Result hash cannot be empty");
        require(bytes(_resultProofURI).length > 0, "CogNet: Result proof URI cannot be empty");

        task.resultHash = _resultHash;
        task.resultProofURI = _resultProofURI;
        task.status = TaskStatus.Submitted;
        task.verificationDeadline = block.timestamp.add(2 days); // Example: 2 days for verification
        task.lastUpdate = block.timestamp;

        // Optionally, call the oracle contract to submit the proof for off-chain verification
        // require(address(cogNetOracle) != address(0), "CogNet: Oracle not set for off-chain proofs");
        // cogNetOracle.submitProof(_taskId, _resultProofURI);

        emit TaskResultSubmitted(_taskId, cAgentId, _resultHash, _resultProofURI);
    }

    /**
     * @dev Council assigns a V-Agent to a submitted task for verification.
     * @param _taskId The ID of the task.
     * @param _verifierAddress The address of the V-Agent to assign.
     */
    function assignVerifierToTask(uint256 _taskId, address _verifierAddress) external onlyCouncil whenNotPaused {
        Task storage task = tasks[_taskId];
        VAgent storage vAgent = vAgents[_verifierAddress];

        require(task.status == TaskStatus.Submitted, "CogNet: Task not in Submitted state");
        require(vAgent.isActive, "CogNet: Assigned verifier is not active");
        require(_verifierAddress != address(0), "CogNet: Invalid verifier address");

        task.verifier = _verifierAddress;
        task.status = TaskStatus.PendingVerification;
        task.lastUpdate = block.timestamp;

        emit VerifierAssigned(_taskId, _verifierAddress);
    }

    /**
     * @dev V-Agent submits the verification outcome for a task.
     * @param _taskId The ID of the task.
     * @param _approved True if approved, false if rejected.
     * @param _justificationURI URI to off-chain justification for the outcome.
     */
    function submitVerificationOutcome(uint256 _taskId, bool _approved, string memory _justificationURI) external onlyVAgent whenNotPaused {
        Task storage task = tasks[_taskId];
        VAgent storage vAgent = vAgents[_msgSender()];
        CAgent storage cAgent = cAgents[task.cAgentId];

        require(task.verifier == _msgSender(), "CogNet: Caller is not the assigned verifier");
        require(task.status == TaskStatus.PendingVerification, "CogNet: Task not in Pending Verification state");
        require(block.timestamp < task.verificationDeadline, "CogNet: Verification deadline passed");
        require(bytes(_justificationURI).length > 0, "CogNet: Justification URI cannot be empty");

        task.verificationJustificationURI = _justificationURI;
        task.lastUpdate = block.timestamp;

        if (_approved) {
            task.status = TaskStatus.VerifiedApproved;
            cAgent.reputation = cAgent.reputation.add(5); // Example: increase reputation
            vAgent.reputation = vAgent.reputation.add(2); // Example: increase reputation
        } else {
            task.status = TaskStatus.VerifiedRejected;
            cAgent.reputation = cAgent.reputation.sub(10); // Example: decrease reputation
            vAgent.reputation = vAgent.reputation.add(1); // Example: small reward for correct rejection
            // Slash C-Agent collateral on rejection (partial or full)
            uint256 slashingAmount = task.cAgentCollateral.div(2); // Example: 50% slash
            // Transfer slashed collateral to protocol fees or V-Agent as bonus
            totalProtocolFeesCollected = totalProtocolFeesCollected.add(slashingAmount); 
            task.cAgentCollateral = task.cAgentCollateral.sub(slashingAmount); // Remaining collateral for C-Agent
        }

        emit VerificationOutcomeSubmitted(_taskId, _msgSender(), _approved, _justificationURI);
    }

    /**
     * @dev C-Agent claims bounty and collateral after successful verification.
     * @param _taskId The ID of the task.
     */
    function claimBounty(uint256 _taskId) external whenNotPaused {
        Task storage task = tasks[_taskId];
        CAgent storage cAgent = cAgents[task.cAgentId];

        require(task.cAgentId == cAgentAddressToId[_msgSender()], "CogNet: Only the assigned C-Agent can claim bounty");
        require(task.status == TaskStatus.VerifiedApproved, "CogNet: Task not in Verified Approved state");

        uint256 protocolFee = task.bounty.mul(networkFeePercentage).div(100);
        uint256 netBounty = task.bounty.sub(protocolFee);

        totalProtocolFeesCollected = totalProtocolFeesCollected.add(protocolFee);

        // Refund C-Agent's collateral back to their stake
        cAgent.stake = cAgent.stake.add(task.cAgentCollateral);

        // Transfer net bounty to C-Agent (from protocol escrow)
        require(cogNetToken.transfer(_msgSender(), netBounty), "CogNet: Failed to transfer bounty");

        task.bounty = 0;
        task.cAgentCollateral = 0;
        task.status = TaskStatus.Completed;
        task.lastUpdate = block.timestamp;

        emit BountyClaimed(_taskId, cAgent.id, netBounty, task.cAgentCollateral, protocolFee);
    }

    /**
     * @dev Any involved party (Requestor, C-Agent, V-Agent) can raise a dispute.
     * @param _taskId The ID of the task.
     * @param _reason The reason for the dispute.
     */
    function raiseDispute(uint256 _taskId, DisputeReason _reason) external whenNotPaused {
        Task storage task = tasks[_taskId];
        require(
            _msgSender() == task.requestor || 
            cAgentAddressToId[_msgSender()] == task.cAgentId || 
            _msgSender() == task.verifier,
            "CogNet: Only involved parties can raise a dispute"
        );
        require(task.status != TaskStatus.Created && task.status != TaskStatus.Cancelled && task.status != TaskStatus.Completed, "CogNet: Cannot dispute in current state");
        require(task.status != TaskStatus.InDispute, "CogNet: Task is already in dispute");
        require(_reason != DisputeReason.None, "CogNet: Invalid dispute reason");

        task.status = TaskStatus.InDispute;
        task.disputeReason = _reason;
        task.lastUpdate = block.timestamp;

        emit DisputeRaised(_taskId, _msgSender(), _reason);
    }

    /**
     * @dev Council resolves a dispute and sets the final status for a task.
     * Can involve slashing, reassigning, or adjusting rewards.
     * @param _taskId The ID of the disputed task.
     * @param _finalStatus The final status determined by the council (e.g., VerifiedApproved, VerifiedRejected, Cancelled).
     * @param _resolutionDetailsURI URI to off-chain details of the council's decision.
     * @param _slashedCAgentStake Optional amount of C-Agent stake to slash.
     * @param _slashedVAgentStake Optional amount of V-Agent stake to slash.
     * @param _payoutToCAgent Optional payout to C-Agent (e.g., if re-approved after dispute).
     * @param _payoutToVAgent Optional payout to V-Agent.
     * @param _refundToRequestor Optional refund to Requestor.
     */
    function resolveDisputeByCouncil(
        uint256 _taskId,
        TaskStatus _finalStatus,
        string memory _resolutionDetailsURI,
        uint256 _slashedCAgentStake,
        uint256 _slashedVAgentStake,
        uint256 _payoutToCAgent,
        uint256 _payoutToVAgent,
        uint256 _refundToRequestor
    ) external onlyCouncil whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.InDispute, "CogNet: Task is not in dispute");
        require(bytes(_resolutionDetailsURI).length > 0, "CogNet: Resolution details URI cannot be empty");

        CAgent storage cAgent = cAgents[task.cAgentId];
        VAgent storage vAgent = vAgents[task.verifier];

        // Apply slashes
        if (_slashedCAgentStake > 0) {
            require(cAgent.stake >= _slashedCAgentStake, "CogNet: C-Agent stake insufficient for slash");
            cAgent.stake = cAgent.stake.sub(_slashedCAgentStake);
            totalProtocolFeesCollected = totalProtocolFeesCollected.add(_slashedCAgentStake);
            cAgent.reputation = cAgent.reputation.sub(20); // Significant reputation hit
        }
        if (_slashedVAgentStake > 0) {
            require(vAgent.stake >= _slashedVAgentStake, "CogNet: V-Agent stake insufficient for slash");
            vAgent.stake = vAgent.stake.sub(_slashedVAgentStake);
            totalProtocolFeesCollected = totalProtocolFeesCollected.add(_slashedVAgentStake);
            vAgent.reputation = vAgent.reputation.sub(20); // Significant reputation hit
        }

        // Handle payouts
        if (_payoutToCAgent > 0) {
            // This payout could be from original bounty, or additional funds by council if needed.
            // For simplicity, let's assume it's part of the original bounty if applicable or from fees.
            // A more complex system might allow council to inject funds.
            // Here we assume it comes from the task.bounty or protocol fees if task.bounty is depleted.
            if (_payoutToCAgent > task.bounty) {
                 // Try to take from protocol fees if not enough in bounty
                require(totalProtocolFeesCollected >= _payoutToCAgent.sub(task.bounty), "CogNet: Insufficient funds for C-Agent payout");
                totalProtocolFeesCollected = totalProtocolFeesCollected.sub(_payoutToCAgent.sub(task.bounty));
                _payoutToCAgent = _payoutToCAgent.sub(task.bounty); // Adjust for what's left
                task.bounty = 0;
            }
            if (_payoutToCAgent > 0 && task.bounty >= _payoutToCAgent) {
                task.bounty = task.bounty.sub(_payoutToCAgent);
            }
            cAgent.stake = cAgent.stake.add(task.cAgentCollateral); // Refund collateral regardless
            task.cAgentCollateral = 0;
            require(cogNetToken.transfer(cAgent.owner, _payoutToCAgent), "CogNet: C-Agent payout failed");
        } else {
             // If no explicit payout, refund collateral back to C-Agent if not slashed fully
            cAgent.stake = cAgent.stake.add(task.cAgentCollateral);
            task.cAgentCollateral = 0;
        }

        if (_payoutToVAgent > 0) {
            if (_payoutToVAgent > task.bounty) { // If V-Agent payout exceeds remaining bounty
                 require(totalProtocolFeesCollected >= _payoutToVAgent.sub(task.bounty), "CogNet: Insufficient funds for V-Agent payout");
                totalProtocolFeesCollected = totalProtocolFeesCollected.sub(_payoutToVAgent.sub(task.bounty));
                _payoutToVAgent = _payoutToVAgent.sub(task.bounty); // Adjust for what's left
                task.bounty = 0;
            }
            if (_payoutToVAgent > 0 && task.bounty >= _payoutToVAgent) {
                task.bounty = task.bounty.sub(_payoutToVAgent);
            }
            require(cogNetToken.transfer(vAgent.owner, _payoutToVAgent), "CogNet: V-Agent payout failed");
        }
        
        if (_refundToRequestor > 0) {
            require(task.bounty >= _refundToRequestor, "CogNet: Insufficient bounty for refund");
            task.bounty = task.bounty.sub(_refundToRequestor);
            require(cogNetToken.transfer(task.requestor, _refundToRequestor), "CogNet: Requestor refund failed");
        }

        // Any remaining bounty goes to protocol fees if not otherwise allocated
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(task.bounty);
        task.bounty = 0;

        task.status = _finalStatus;
        task.disputeReason = DisputeReason.None; // Reset dispute reason
        task.lastUpdate = block.timestamp;

        emit DisputeResolved(_taskId, _msgSender(), _finalStatus, _resolutionDetailsURI);
    }

    /**
     * @dev Retrieves all pertinent information about a specific task.
     * @param _taskId The ID of the task.
     * @return A tuple containing task information.
     */
    function getTaskDetails(uint256 _taskId) external view returns (
        uint256 id,
        address requestor,
        uint256 bounty,
        uint256 cAgentCollateral,
        uint256 cAgentId,
        address verifier,
        uint256 deadline,
        uint256 verificationDeadline,
        string memory requiredCapabilitiesURI,
        string memory taskDetailsURI,
        string memory resultHash,
        string memory resultProofURI,
        string memory verificationJustificationURI,
        TaskStatus status,
        DisputeReason disputeReason,
        uint256 createdAt,
        uint256 lastUpdate
    ) {
        Task storage task = tasks[_taskId];
        require(task.requestor != address(0), "CogNet: Task not found"); // Check if task exists

        return (
            task.id,
            task.requestor,
            task.bounty,
            task.cAgentCollateral,
            task.cAgentId,
            task.verifier,
            task.deadline,
            task.verificationDeadline,
            task.requiredCapabilitiesURI,
            task.taskDetailsURI,
            task.resultHash,
            task.resultProofURI,
            task.verificationJustificationURI,
            task.status,
            task.disputeReason,
            task.createdAt,
            task.lastUpdate
        );
    }

    // --- Internal Helpers (Optional, could be made public if useful for external monitoring) ---

    /**
     * @dev Retrieves the current reputation score for a C-Agent.
     * @param _cAgentId The ID of the C-Agent.
     * @return The reputation score.
     */
    function getCAgentReputation(uint256 _cAgentId) public view returns (uint256) {
        require(cAgents[_cAgentId].owner != address(0), "CogNet: C-Agent not found");
        return cAgents[_cAgentId].reputation;
    }

    /**
     * @dev Retrieves the current reputation score for a V-Agent.
     * @param _vAgentAddress The address of the V-Agent.
     * @return The reputation score.
     */
    function getVAgentReputation(address _vAgentAddress) public view returns (uint256) {
        require(vAgents[_vAgentAddress].owner != address(0), "CogNet: V-Agent not found");
        return vAgents[_vAgentAddress].reputation;
    }
}
```