Here's a smart contract written in Solidity, incorporating advanced concepts like dynamic NFTs (Soulbound Tokens), an on-chain AI task market, a reputation system, oracle integration, and a challenge mechanism. It avoids directly duplicating common open-source patterns by creating a novel interplay between these elements.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline:
// 1. Contract Overview: CognitoNexus Protocol for Decentralized AI Tasks & Agent Reputation.
// 2. State Variables & Mappings: Global protocol configurations, task storage, agent storage.
// 3. Enums & Structs: Defines states for tasks, and data structures for agents and tasks.
// 4. Events: Signals for significant on-chain actions (e.g., TaskPosted, AgentMinted).
// 5. Modifiers: Custom access control and state-checking logic.
// 6. Access Control & System Management (Owner/Admin functions): Core protocol settings, pausing.
// 7. CognitoCore (AI Agent NFT) Management: Minting, updating, and querying agent details.
// 8. Task Management: Posting, claiming, submitting proofs, challenging, and resolving AI tasks.
// 9. Reputation System: Internal and external functions for managing and querying agent reputation.
// 10. Token Interaction: Handling of the bounty token (e.g., deposits, withdrawals).
// 11. View Functions: Read-only functions for querying protocol state.

// Function Summary:
// 1.  constructor(address _cognitoTokenAddress): Initializes contract, sets owner, links to the CognitoToken (ERC20) address.
// 2.  pause(): Pauses all mutable contract functionalities in emergencies (Owner-only).
// 3.  unpause(): Unpauses the contract functionalities (Owner-only).
// 4.  setOracleAddress(address _oracle): Sets the trusted oracle address for external data verification, typically for challenging proof validity (Owner-only).
// 5.  setVerifierDAOAddress(address _dao): Sets the address of a Decentralized Autonomous Organization (DAO) responsible for verifying challenged proofs (Owner-only).
// 6.  addAuthorizedVerifier(address _verifier): Adds an address to a whitelist of authorized verifiers for challenges (Owner-only, fallback if no DAO).
// 7.  removeAuthorizedVerifier(address _verifier): Removes an address from the whitelist of authorized verifiers (Owner-only).
// 8.  mintCognitoCore(string memory _initialMetadataURI, bytes32 _proofOfIntegrityHash): Mints a new Soulbound AI Agent NFT (CognitoCore) for the caller.
// 9.  updateCognitoCoreProofOfIntegrity(uint256 _tokenId, bytes32 _newProofOfIntegrityHash): Allows a CognitoCore owner to update its internal integrity hash, reflecting model updates.
// 10. getCognitoCoreDetails(uint256 _tokenId): Retrieves comprehensive information about a specific CognitoCore NFT.
// 11. getAgentReputation(uint256 _tokenId): Returns the current reputation score of a CognitoCore.
// 12. getAgentLevel(uint256 _tokenId): Calculates and returns the current "level" of a CognitoCore based on its reputation score.
// 13. evolveCognitoCoreMetadata(uint256 _tokenId, string memory _newMetadataURI): Allows the owner of a CognitoCore to update its metadata URI, reflecting its on-chain evolution.
// 14. postTask(string memory _taskDescription, uint256 _bountyAmount, uint256 _challengePeriod, uint256 _resolutionDeadline): Allows users to post new AI tasks with a specified bounty, challenge window, and final resolution deadline. Requires pre-approval of `_bountyAmount` from `CognitoToken`.
// 15. claimTask(uint256 _taskId, uint256 _agentId): Allows a registered CognitoCore agent to claim an available task, locking the task to that agent.
// 16. submitTaskProof(uint256 _taskId, bytes32 _proofHash, string memory _resultUri): The claiming AI agent submits cryptographic proof (hash) of their off-chain AI execution and a URI to the detailed result.
// 17. challengeTaskProof(uint256 _taskId, string memory _reason): Anyone can challenge a submitted task proof if they believe it's incorrect or fraudulent.
// 18. verifyChallengeResult(uint256 _taskId, bool _isProofValid): An authorized Oracle or Verifier DAO submits the definitive decision on a challenged proof's validity. This function is permissioned.
// 19. resolveTask(uint256 _taskId): Finalizes a task, distributes the bounty, and updates the AI agent's reputation based on the task's outcome (success or failure).
// 20. cancelTask(uint256 _taskId): The original task creator can cancel their task if it hasn't been claimed or if a challenge hasn't been resolved within the deadline.
// 21. getTaskDetails(uint256 _taskId): Retrieves comprehensive information about a specific task.
// 22. getOpenTasks(): Returns an array of IDs for all tasks currently in the `Posted` state.
// 23. _updateReputation(uint256 _agentId, bool _success): Internal function to adjust an agent's reputation score based on task outcomes.
// 24. getReputationTier(uint256 _reputation): Converts a raw reputation score into a conceptual tier (e.g., Novice, Journeyman, Master).
// 25. depositBounty(uint256 _amount): Allows users to deposit the native CognitoToken (COG) into the contract, intended for future task bounties.
// 26. withdrawBounty(uint256 _amount): Allows a user to withdraw their deposited COG funds from the contract's balance.
// 27. getTotalTasksPosted(): Returns the cumulative count of all tasks ever posted on the protocol.
// 28. getTotalAgentsMinted(): Returns the total number of CognitoCore NFTs minted.
// 29. getPendingTasksForAgent(uint256 _agentId): Returns a list of task IDs that a specific agent has claimed or submitted but are not yet resolved.
// 30. getReputationRequiredForLevel(uint256 _level): Returns the minimum reputation points required to reach a certain agent level.

contract CognitoNexus is Ownable, Pausable, ReentrancyGuard, ERC721 {
    using Counters for Counters.Counter;

    // --- 2. State Variables & Mappings ---
    IERC20 public immutable COGNITO_TOKEN; // The ERC20 token used for bounties and rewards

    address public oracleAddress; // Address of the trusted oracle for external data (e.g., challenging proofs)
    address public verifierDAOAddress; // Address of the Verifier DAO (can replace oracle for decentralized verification)

    // Authorized verifiers for challenges (can be used as a fallback if no DAO is set, or for specific roles)
    mapping(address => bool) public authorizedVerifiers;

    // CognitoCore Agent (NFT) Details
    struct CognitoCore {
        address owner;
        bytes32 proofOfIntegrityHash; // IPFS hash or similar reference to certified model code/integrity check
        uint256 reputation; // Accumulated reputation score
        uint256 lastActivityTime; // Timestamp of last significant activity (e.g., task submission, resolution)
    }
    mapping(uint256 => CognitoCore) public cognitoCores;
    Counters.Counter private _cognitoCoreIds;

    // Task Details
    enum TaskStatus {
        Posted,
        Claimed,
        ProofSubmitted,
        Challenged,
        Resolved,
        Canceled
    }

    struct Task {
        address creator;
        string description;
        uint256 bountyAmount;
        uint256 postedTime;
        uint256 challengePeriod; // Duration in seconds after proof submission during which it can be challenged
        uint256 resolutionDeadline; // Absolute timestamp by which a challenged task must be resolved
        TaskStatus status;
        uint256 claimedByAgentId; // 0 if not claimed
        uint256 claimTime;
        bytes32 submittedProofHash;
        string resultUri; // URI to detailed off-chain result data (e.g., IPFS)
        address challenger; // Address that challenged the proof
        string challengeReason;
        uint256 challengeTime;
        bool proofWasValid; // Result of the challenge (true if submitted proof was valid)
    }
    mapping(uint256 => Task) public tasks;
    Counters.Counter private _taskIds;
    uint256[] public openTaskIds; // Array to keep track of tasks in 'Posted' state

    // User deposited balances for bounties
    mapping(address => uint256) public userBountyBalances;

    // --- 3. Enums & Structs (Defined above) ---

    // --- 4. Events ---
    event CognitoCoreMinted(uint256 indexed tokenId, address indexed owner, bytes32 proofOfIntegrityHash);
    event CognitoCoreIntegrityUpdated(uint256 indexed tokenId, bytes32 oldHash, bytes32 newHash);
    event CognitoCoreMetadataEvolved(uint256 indexed tokenId, string newMetadataURI);

    event TaskPosted(uint256 indexed taskId, address indexed creator, uint256 bountyAmount, string description);
    event TaskClaimed(uint256 indexed taskId, uint256 indexed agentId, address indexed claimant);
    event TaskProofSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 proofHash, string resultUri);
    event TaskChallenged(uint256 indexed taskId, address indexed challenger, string reason);
    event ChallengeVerified(uint256 indexed taskId, bool isProofValid, address indexed verifier);
    event TaskResolved(uint256 indexed taskId, TaskStatus finalStatus, uint256 indexed agentId, uint256 bountyPaid);
    event TaskCanceled(uint256 indexed taskId, address indexed canceller);

    event OracleAddressSet(address indexed newOracleAddress);
    event VerifierDAOAddressSet(address indexed newVerifierDAOAddress);
    event AuthorizedVerifierAdded(address indexed verifier);
    event AuthorizedVerifierRemoved(address indexed verifier);

    // --- 5. Modifiers ---
    modifier onlyOracleOrDAOOrAuthorizedVerifier() {
        require(msg.sender == oracleAddress || msg.sender == verifierDAOAddress || authorizedVerifiers[msg.sender], "CognitoNexus: Not authorized to verify challenges");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= _taskIds.current(), "CognitoNexus: Task does not exist");
        _;
    }

    modifier isCognitoCoreOwner(uint256 _agentId) {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        require(ownerOf(_agentId) == msg.sender, "CognitoNexus: Not the owner of this CognitoCore");
        _;
    }

    // --- 6. Access Control & System Management ---

    constructor(address _cognitoTokenAddress) ERC721("CognitoCore", "COGCORE") Ownable(msg.sender) {
        require(_cognitoTokenAddress != address(0), "CognitoNexus: CognitoToken address cannot be zero");
        COGNITO_TOKEN = IERC20(_cognitoTokenAddress);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "CognitoNexus: Oracle address cannot be zero");
        oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    function setVerifierDAOAddress(address _dao) public onlyOwner {
        require(_dao != address(0), "CognitoNexus: Verifier DAO address cannot be zero");
        verifierDAOAddress = _dao;
        emit VerifierDAOAddressSet(_dao);
    }

    function addAuthorizedVerifier(address _verifier) public onlyOwner {
        require(_verifier != address(0), "CognitoNexus: Verifier address cannot be zero");
        require(!authorizedVerifiers[_verifier], "CognitoNexus: Verifier already authorized");
        authorizedVerifiers[_verifier] = true;
        emit AuthorizedVerifierAdded(_verifier);
    }

    function removeAuthorizedVerifier(address _verifier) public onlyOwner {
        require(authorizedVerifiers[_verifier], "CognitoNexus: Verifier not authorized");
        authorizedVerifiers[_verifier] = false;
        emit AuthorizedVerifierRemoved(_verifier);
    }

    // --- 7. CognitoCore (AI Agent NFT) Management ---

    function mintCognitoCore(string memory _initialMetadataURI, bytes32 _proofOfIntegrityHash) public whenNotPaused nonReentrant returns (uint256) {
        _cognitoCoreIds.increment();
        uint256 newItemId = _cognitoCoreIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _initialMetadataURI);

        cognitoCores[newItemId] = CognitoCore({
            owner: msg.sender,
            proofOfIntegrityHash: _proofOfIntegrityHash,
            reputation: 0,
            lastActivityTime: block.timestamp
        });

        emit CognitoCoreMinted(newItemId, msg.sender, _proofOfIntegrityHash);
        return newItemId;
    }

    // Override _beforeTokenTransfer to make it Soulbound after initial mint
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Allow transfer only during initial mint (from address(0) to actual owner)
        // Or disallow all transfers to make it strictly Soulbound from creation
        require(from == address(0), "CognitoNexus: CognitoCore NFTs are non-transferable (Soulbound)");
    }

    function updateCognitoCoreProofOfIntegrity(uint256 _tokenId, bytes32 _newProofOfIntegrityHash) public whenNotPaused isCognitoCoreOwner(_tokenId) {
        bytes32 oldHash = cognitoCores[_tokenId].proofOfIntegrityHash;
        cognitoCores[_tokenId].proofOfIntegrityHash = _newProofOfIntegrityHash;
        emit CognitoCoreIntegrityUpdated(_tokenId, oldHash, _newProofOfIntegrityHash);
    }

    function getCognitoCoreDetails(uint256 _tokenId) public view isCognitoCoreOwner(_tokenId) returns (address, bytes32, uint256, uint256) {
        CognitoCore storage core = cognitoCores[_tokenId];
        return (core.owner, core.proofOfIntegrityHash, core.reputation, core.lastActivityTime);
    }

    function getAgentReputation(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "CognitoNexus: Agent does not exist");
        return cognitoCores[_tokenId].reputation;
    }

    function getAgentLevel(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "CognitoNexus: Agent does not exist");
        uint256 reputation = cognitoCores[_tokenId].reputation;
        // Simple logarithmic scale for levels, adjust as needed
        if (reputation < 100) return 0; // Novice
        if (reputation < 500) return 1; // Apprentice
        if (reputation < 2000) return 2; // Journeyman
        if (reputation < 10000) return 3; // Expert
        return 4; // Master
    }

    function getReputationRequiredForLevel(uint256 _level) public pure returns (uint256) {
        // Inverse of getAgentLevel logic
        if (_level == 0) return 0;
        if (_level == 1) return 100;
        if (_level == 2) return 500;
        if (_level == 3) return 2000;
        if (_level == 4) return 10000;
        return type(uint256).max; // For levels beyond defined tiers
    }

    function evolveCognitoCoreMetadata(uint256 _tokenId, string memory _newMetadataURI) public whenNotPaused isCognitoCoreOwner(_tokenId) {
        // This function allows the agent owner to update the NFT's metadata URI.
        // The dApp/frontend would typically generate this URI based on the agent's on-chain
        // stats (reputation, level) and point to new dynamic content.
        _setTokenURI(_tokenId, _newMetadataURI);
        emit CognitoCoreMetadataEvolved(_tokenId, _newMetadataURI);
    }

    // --- 8. Task Management ---

    function postTask(string memory _taskDescription, uint256 _bountyAmount, uint256 _challengePeriod, uint256 _resolutionDeadline) public whenNotPaused nonReentrant {
        require(_bountyAmount > 0, "CognitoNexus: Bounty must be greater than zero");
        require(_challengePeriod > 0, "CognitoNexus: Challenge period must be positive");
        require(_resolutionDeadline > block.timestamp, "CognitoNexus: Resolution deadline must be in the future");
        require(COGNITO_TOKEN.transferFrom(msg.sender, address(this), _bountyAmount), "CognitoNexus: Token transfer failed for bounty");

        _taskIds.increment();
        uint256 newItemId = _taskIds.current();

        tasks[newItemId] = Task({
            creator: msg.sender,
            description: _taskDescription,
            bountyAmount: _bountyAmount,
            postedTime: block.timestamp,
            challengePeriod: _challengePeriod,
            resolutionDeadline: _resolutionDeadline,
            status: TaskStatus.Posted,
            claimedByAgentId: 0,
            claimTime: 0,
            submittedProofHash: bytes32(0),
            resultUri: "",
            challenger: address(0),
            challengeReason: "",
            challengeTime: 0,
            proofWasValid: false
        });

        openTaskIds.push(newItemId); // Add to open tasks list

        emit TaskPosted(newItemId, msg.sender, _bountyAmount, _taskDescription);
    }

    function claimTask(uint256 _taskId, uint256 _agentId) public whenNotPaused nonReentrant taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Posted, "CognitoNexus: Task is not available for claiming");
        require(ownerOf(_agentId) == msg.sender, "CognitoNexus: Agent must be owned by caller to claim task");
        require(cognitoCores[_agentId].reputation >= getReputationRequiredForLevel(getAgentLevel(_agentId)), "CognitoNexus: Agent reputation too low for this task tier"); // Example: require minimum level

        task.claimedByAgentId = _agentId;
        task.claimTime = block.timestamp;
        task.status = TaskStatus.Claimed;

        // Remove from open tasks array
        for (uint i = 0; i < openTaskIds.length; i++) {
            if (openTaskIds[i] == _taskId) {
                openTaskIds[i] = openTaskIds[openTaskIds.length - 1];
                openTaskIds.pop();
                break;
            }
        }

        emit TaskClaimed(_taskId, _agentId, msg.sender);
    }

    function submitTaskProof(uint256 _taskId, bytes32 _proofHash, string memory _resultUri) public whenNotPaused nonReentrant taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Claimed, "CognitoNexus: Task not in claimed state");
        require(task.claimedByAgentId != 0, "CognitoNexus: Task not claimed");
        require(ownerOf(task.claimedByAgentId) == msg.sender, "CognitoNexus: Only the claiming agent's owner can submit proof");
        require(block.timestamp <= task.claimTime + task.resolutionDeadline, "CognitoNexus: Submission deadline passed for claimed task"); // Added deadline for submission

        task.submittedProofHash = _proofHash;
        task.resultUri = _resultUri;
        task.status = TaskStatus.ProofSubmitted;
        cognitoCores[task.claimedByAgentId].lastActivityTime = block.timestamp; // Update agent activity

        emit TaskProofSubmitted(_taskId, task.claimedByAgentId, _proofHash, _resultUri);
    }

    function challengeTaskProof(uint256 _taskId, string memory _reason) public whenNotPaused nonReentrant taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ProofSubmitted, "CognitoNexus: Task not in proof submitted state");
        require(block.timestamp <= task.claimTime + task.challengePeriod, "CognitoNexus: Challenge period has expired");
        require(msg.sender != ownerOf(task.claimedByAgentId), "CognitoNexus: Agent owner cannot challenge their own proof");

        task.status = TaskStatus.Challenged;
        task.challenger = msg.sender;
        task.challengeReason = _reason;
        task.challengeTime = block.timestamp;

        emit TaskChallenged(_taskId, msg.sender, _reason);
    }

    function verifyChallengeResult(uint256 _taskId, bool _isProofValid) public whenNotPaused nonReentrant taskExists(_taskId) onlyOracleOrDAOOrAuthorizedVerifier {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Challenged, "CognitoNexus: Task not in challenged state");
        require(block.timestamp <= task.resolutionDeadline, "CognitoNexus: Resolution deadline has passed for this challenge");

        task.proofWasValid = _isProofValid;
        // Move to resolved state immediately after verification, or allow separate resolve call
        // For simplicity, let's allow `resolveTask` to be called after this.
        // Or, we could transition it directly to Resolved_FailedChallenge / Resolved_PassedChallenge states.
        // For now, let's keep it in Challenged state until resolved.
        emit ChallengeVerified(_taskId, _isProofValid, msg.sender);
    }

    function resolveTask(uint256 _taskId) public whenNotPaused nonReentrant taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ProofSubmitted || task.status == TaskStatus.Challenged, "CognitoNexus: Task not in a resolvable state (Submitted or Challenged)");
        require(msg.sender == task.creator || msg.sender == ownerOf(task.claimedByAgentId) || msg.sender == owner() || authorizedVerifiers[msg.sender], "CognitoNexus: Not authorized to resolve this task");

        uint256 agentId = task.claimedByAgentId;
        bool success = false;
        uint256 bountyToPay = 0;

        if (task.status == TaskStatus.ProofSubmitted) {
            // No challenge, consider it successful
            success = true;
            bountyToPay = task.bountyAmount;
        } else if (task.status == TaskStatus.Challenged) {
            require(task.challengeTime > 0, "CognitoNexus: Challenge details missing for challenged task");
            // If resolution deadline passed and no verification, or if verified
            if (task.proofWasValid) {
                // Proof was valid, agent wins
                success = true;
                bountyToPay = task.bountyAmount;
            } else {
                // Proof was invalid, agent fails
                success = false;
                bountyToPay = 0; // Bounty might be returned to creator or burned
            }
            // Check if deadline passed and it's still challenged
            require(block.timestamp > task.resolutionDeadline, "CognitoNexus: Challenge not yet resolved or deadline not passed");
            require(task.challengeTime > 0, "CognitoNexus: Challenge must have been initiated");
        } else {
            revert("CognitoNexus: Task cannot be resolved in its current state.");
        }

        task.status = TaskStatus.Resolved;
        _updateReputation(agentId, success);

        if (success) {
            require(COGNITO_TOKEN.transfer(ownerOf(agentId), bountyToPay), "CognitoNexus: Failed to transfer bounty to agent");
        } else {
            // Optionally, return bounty to creator or send to a fund
            require(COGNITO_TOKEN.transfer(task.creator, task.bountyAmount), "CognitoNexus: Failed to return bounty to creator");
        }

        emit TaskResolved(_taskId, task.status, agentId, bountyToPay);
    }

    function cancelTask(uint256 _taskId) public whenNotPaused nonReentrant taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(msg.sender == task.creator, "CognitoNexus: Only the task creator can cancel");
        require(task.status == TaskStatus.Posted ||
                (task.status == TaskStatus.Claimed && block.timestamp > task.claimTime + task.resolutionDeadline) ||
                (task.status == TaskStatus.ProofSubmitted && block.timestamp > task.claimTime + task.challengePeriod && task.challengeTime == 0), // Allow cancel if proof submitted but challenge period passed without challenge
                "CognitoNexus: Task cannot be cancelled in its current state or by this caller");

        task.status = TaskStatus.Canceled;
        require(COGNITO_TOKEN.transfer(task.creator, task.bountyAmount), "CognitoNexus: Failed to return bounty to creator on cancel");

        // Remove from open tasks if it was posted
        if (task.status == TaskStatus.Posted) {
            for (uint i = 0; i < openTaskIds.length; i++) {
                if (openTaskIds[i] == _taskId) {
                    openTaskIds[i] = openTaskIds[openTaskIds.length - 1];
                    openTaskIds.pop();
                    break;
                }
            }
        }
        emit TaskCanceled(_taskId, msg.sender);
    }

    // --- 9. Reputation System ---

    function _updateReputation(uint256 _agentId, bool _success) internal {
        CognitoCore storage agent = cognitoCores[_agentId];
        if (_success) {
            agent.reputation += 100; // Example: 100 points for success
        } else {
            // Deduct more for failed challenges/malicious activity
            agent.reputation = agent.reputation >= 50 ? agent.reputation - 50 : 0; // Example: 50 points deduction, with floor at 0
        }
        agent.lastActivityTime = block.timestamp;
    }

    function getReputationTier(uint256 _reputation) public pure returns (string memory) {
        if (_reputation < 100) return "Novice";
        if (_reputation < 500) return "Apprentice";
        if (_reputation < 2000) return "Journeyman";
        if (_reputation < 10000) return "Expert";
        return "Master";
    }

    // --- 10. Token Interaction ---

    function depositBounty(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "CognitoNexus: Deposit amount must be greater than zero");
        require(COGNITO_TOKEN.transferFrom(msg.sender, address(this), _amount), "CognitoNexus: Token deposit failed");
        userBountyBalances[msg.sender] += _amount;
    }

    function withdrawBounty(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "CognitoNexus: Withdraw amount must be greater than zero");
        require(userBountyBalances[msg.sender] >= _amount, "CognitoNexus: Insufficient balance to withdraw");
        userBountyBalances[msg.sender] -= _amount;
        require(COGNITO_TOKEN.transfer(msg.sender, _amount), "CognitoNexus: Token withdrawal failed");
    }

    // --- 11. View Functions ---

    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getOpenTasks() public view returns (uint256[] memory) {
        return openTaskIds;
    }

    function getTotalTasksPosted() public view returns (uint256) {
        return _taskIds.current();
    }

    function getTotalAgentsMinted() public view returns (uint256) {
        return _cognitoCoreIds.current();
    }

    function getPendingTasksForAgent(uint256 _agentId) public view returns (uint256[] memory) {
        require(_exists(_agentId), "CognitoNexus: Agent does not exist");
        uint256[] memory agentTasks = new uint256[](_taskIds.current()); // Max possible size
        uint256 counter = 0;
        for (uint256 i = 1; i <= _taskIds.current(); i++) {
            if (tasks[i].claimedByAgentId == _agentId &&
                (tasks[i].status == TaskStatus.Claimed ||
                 tasks[i].status == TaskStatus.ProofSubmitted ||
                 tasks[i].status == TaskStatus.Challenged)) {
                agentTasks[counter] = i;
                counter++;
            }
        }
        uint224[] memory result = new uint256[](counter);
        for (uint i = 0; i < counter; i++) {
            result[i] = agentTasks[i];
        }
        return result;
    }
}
```