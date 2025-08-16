Okay, this is an exciting challenge! To create something truly unique and not just a rehash of existing open-source projects, we'll design a contract that focuses on **dynamic, adaptive, and reputation-driven decentralized collaboration**, leveraging concepts from SBTs (Soulbound Tokens - in a modified, transferrable way for skill bonds), multi-stage execution, and oracle-driven adaptability.

Let's call our platform "AetherForge". It's a decentralized hub for projects, where participants commit "AetherBonds" (dynamic NFTs representing skill profiles and reputation) to multi-stage tasks. The tasks themselves are adaptive, their conditions or rewards potentially changing based on external data or internal progress.

---

## AetherForge: Adaptive Decentralized Collaboration Platform

**Concept:** AetherForge is a decentralized platform enabling adaptive, multi-stage project collaboration. It introduces "AetherBonds" – dynamic NFTs representing an individual's skills, reputation, and project contributions. Projects, called "ForgeTasks," are defined with sequential stages, each requiring specific skills and offering conditional rewards. The platform integrates (conceptually) with external oracles for dynamic adjustments and reputation scoring, fostering a meritocratic environment where an AetherBond's value grows with successful participation.

**Key Innovations:**
1.  **Dynamic "AetherBonds" (NFTs):** NFTs that are not static art, but evolving representations of an individual's skill sets, reputation, and historical contributions, updated dynamically by platform actions or external oracles. They are *transferable*, but their utility is tied to the current holder's active participation.
2.  **Adaptive Multi-Stage Tasks:** Tasks are broken into stages, each with its own requirements and conditional reward release. Future stages can adapt based on the outcome of previous ones or external data.
3.  **Reputation-Driven Eligibility & Rewards:** AetherBond reputation influences task eligibility, reward multiplier, and even voting power in platform governance.
4.  **Decentralized Task Verification:** Stages can require verification by designated verifiers or even a collective vote, enabling a more robust and decentralized approval process.
5.  **Skill-Based Matching & Pledging:** Participants pledge specific AetherBonds (and their associated skills) to tasks.

---

### Outline & Function Summary

**I. Core Platform Management & Configuration**
*   `constructor`: Initializes contract owner, fees, and oracle addresses.
*   `setPlatformFeeRecipient`: Sets the address to receive platform fees.
*   `setBondMintFee`: Sets the fee to mint a new AetherBond.
*   `setTaskCreationFee`: Sets the fee to propose a new ForgeTask.
*   `setReputationOracleAddress`: Sets the trusted oracle for reputation updates.
*   `setSkillWeightConfig`: Configures how different skills contribute to task eligibility/scoring.
*   `pauseSystem`: Emergency pause functionality.
*   `unpauseSystem`: Unpauses the system.

**II. AetherBond (Dynamic NFT) Management**
*   `forgeAetherBond`: Mints a new AetherBond NFT, associating an initial skill profile.
*   `updateBondSkills`: Allows a bond owner to declare or update their skills (potentially with proof or verification later).
*   `updateBondReputation`: Callback function from the designated reputation oracle to update a bond's score.
*   `getBondDetails`: Retrieves all details of a specific AetherBond.
*   `burnAetherBond`: Allows a bond owner to destroy their bond.
*   `incrementBondContributions`: Internal function to update bond's task contribution count.

**III. ForgeTask (Project) Management**
*   `proposeForgeTask`: Creates a new multi-stage ForgeTask, defining its bounty, stages, and requirements.
*   `pledgeBondToTask`: An AetherBond owner pledges their bond (and its skills) to a specific task.
*   `unpledgeBondFromTask`: Allows an AetherBond owner to remove their pledge before a task starts.
*   `startForgeTask`: The task creator initiates the task, locking pledged bonds and starting the first stage.
*   `submitStageOutput`: A pledged executor submits the output/proof for a task stage.
*   `verifyStageCompletion`: A designated verifier or quorum approves a stage's completion.
*   `distributeStageReward`: Releases funds for a completed stage to the participating executors based on their reputation and contribution.
*   `advanceToNextStage`: Internal function to transition a task to its next stage.
*   `completeForgeTask`: Marks a task as fully completed after all stages are done and distributes remaining funds.
*   `cancelForgeTask`: Allows the creator or governance to cancel a task under specific conditions, refunding staked funds.
*   `getTaskDetails`: Retrieves full details of a ForgeTask.
*   `getTaskStageDetails`: Retrieves details of a specific stage within a task.

**IV. Dispute Resolution & Advanced Utilities**
*   `lodgeDispute`: Allows any participant to formally dispute a stage completion or task outcome.
*   `resolveDispute`: Governance or a designated arbitrator resolves a lodged dispute, potentially reverting stage status or reallocating rewards.
*   `updateTaskStageDeadline`: Allows a task creator (or governance) to extend a stage deadline.
*   `dynamicStageAdjustment`: (Conceptual) Allows the creator to modify *future* stage details based on prior stage outcomes or oracle data, if rules permit.
*   `withdrawExcessFunds`: Allows the task creator to withdraw any remaining bounty if a task is cancelled or completed with leftover funds.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safe math, though Solidity 0.8+ handles overflow by default

/// @title AetherForge
/// @dev A decentralized platform for adaptive, multi-stage project collaboration using dynamic NFTs (AetherBonds).
/// @author YourName (Hypothetical)
/// @notice This contract is a conceptual exploration and not production-ready without extensive audits.

interface IReputationOracle {
    function getReputationScore(address _owner, uint256 _bondId) external view returns (uint256);
    function requestReputationUpdate(address _targetContract, uint256 _bondId) external;
}

contract AetherForge is ERC721, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error InsufficientFee(uint256 required, uint256 provided);
    error UnauthorizedAction();
    error BondNotFound();
    error TaskNotFound();
    error TaskNotActive();
    error TaskAlreadyStarted();
    error TaskAlreadyCompleted();
    error TaskNotStagedCorrectly();
    error InvalidStageIndex();
    error StageAlreadyCompleted();
    error StageNotReadyForVerification();
    error StageNotReadyForPayout();
    error StageProofRequired();
    error StageOutputAlreadySubmitted();
    error NoOutstandingDispute();
    error BondAlreadyPledged();
    error BondNotPledged();
    error InvalidBondOwner();
    error BondNotEligibleForTask();
    error StageDeadlinePassed();
    error InvalidRewardPercentage();
    error ZeroAddressNotAllowed();
    error CannotUnstakeAfterStart();
    error TaskCreatorCannotBeVerifier();
    error OnlyFutureStagesModifiable();

    /*//////////////////////////////////////////////////////////////
                            STRUCTS & ENUMS
    //////////////////////////////////////////////////////////////*/

    enum BondStatus { Active, Burned }
    enum TaskStatus { Proposed, Active, Completed, Cancelled, Disputed }
    enum StageStatus { Pending, OutputSubmitted, Verified, Paid, Disputed }

    struct AetherBond {
        uint256 tokenId;
        address owner; // Redundant with ERC721, but useful for quick access in internal logic
        mapping(string => uint256) skillSet; // E.g., "Solidity": 90, "UX_Design": 75
        uint256 reputationScore; // Updated by oracle
        uint256 totalContributions; // Number of tasks successfully contributed to
        BondStatus status;
        uint256 createdAt;
    }

    struct TaskStage {
        string name;
        string description;
        mapping(string => uint256) requiredSkills; // Min skill levels required, e.g., "Solidity": 70
        uint256 deadline; // Timestamp
        uint256 rewardPercentage; // Percentage of total bounty allocated to this stage (e.g., 2000 = 20%)
        address[] verifiers; // Addresses authorized to verify this stage
        StageStatus status;
        string outputProofURI; // URI to proof/result of the stage
        address executor; // The address that submitted the output for this stage
        uint256 completionTime;
    }

    struct ForgeTask {
        uint256 taskId;
        address creator;
        string title;
        string description;
        uint256 totalBounty; // Total ETH/token bounty for the task
        TaskStatus status;
        TaskStage[] stages;
        uint256 currentStageIndex;
        mapping(uint256 => bool) pledgedBonds; // tokenId => true if pledged
        mapping(uint256 => address) pledgedBondOwners; // tokenId => owner address when pledged
        uint256 disputeDeadline; // Deadline for resolving a dispute
        address disputer; // Address that lodged the current dispute
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public nextBondId;
    uint256 public nextTaskId;
    uint256 public bondMintFee; // In WEI
    uint256 public taskCreationFee; // In WEI
    address public platformFeeRecipient;
    address public reputationOracleAddress; // Address of the trusted reputation oracle contract

    mapping(uint256 => AetherBond) public aetherBonds; // tokenId => AetherBond struct
    mapping(address => uint256[]) public ownerBonds; // ownerAddress => array of bondIds
    mapping(uint256 => ForgeTask) public forgeTasks; // taskId => ForgeTask struct

    // Mapping to define how much each skill contributes to overall eligibility or reward multiplier
    mapping(string => uint256) public skillWeightConfig; // skillName => weight (e.g., 100 for core, 50 for secondary)

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event AetherBondForged(uint256 indexed tokenId, address indexed owner, string[] skills);
    event AetherBondSkillsUpdated(uint256 indexed tokenId, address indexed owner, string[] skills);
    event AetherBondReputationUpdated(uint256 indexed tokenId, uint256 newScore);
    event AetherBondBurned(uint256 indexed tokenId, address indexed owner);

    event ForgeTaskProposed(uint256 indexed taskId, address indexed creator, string title, uint256 totalBounty);
    event BondPledgedToTask(uint256 indexed taskId, uint256 indexed bondId, address indexed pledger);
    event BondUnpledgedFromTask(uint256 indexed taskId, uint256 indexed bondId, address indexed pledger);
    event ForgeTaskStarted(uint256 indexed taskId, address indexed creator);
    event StageOutputSubmitted(uint256 indexed taskId, uint256 indexed stageIndex, address indexed executor, string outputProofURI);
    event StageVerified(uint256 indexed taskId, uint256 indexed stageIndex, address indexed verifier);
    event StageRewardDistributed(uint256 indexed taskId, uint256 indexed stageIndex, address indexed executor, uint256 amount);
    event ForgeTaskCompleted(uint256 indexed taskId);
    event ForgeTaskCancelled(uint256 indexed taskId, string reason);
    event TaskStageDeadlineExtended(uint256 indexed taskId, uint256 indexed stageIndex, uint256 newDeadline);
    event FutureStageAdjusted(uint256 indexed taskId, uint256 indexed stageIndex);

    event DisputeLodged(uint256 indexed taskId, uint256 indexed stageIndex, address indexed disputer);
    event DisputeResolved(uint256 indexed taskId, uint256 indexed stageIndex, address indexed resolver, bool success);

    event ExcessFundsWithdrawn(uint256 indexed taskId, address indexed receiver, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _platformFeeRecipient, address _reputationOracleAddress) ERC721("AetherBond", "AEB") {
        if (_platformFeeRecipient == address(0) || _reputationOracleAddress == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        platformFeeRecipient = _platformFeeRecipient;
        reputationOracleAddress = _reputationOracleAddress;
        bondMintFee = 0.01 ether; // Example: 0.01 ETH
        taskCreationFee = 0.05 ether; // Example: 0.05 ETH

        // Initial skill weights (example)
        skillWeightConfig["Solidity"] = 100;
        skillWeightConfig["UI/UX"] = 70;
        skillWeightConfig["DevOps"] = 80;
        skillWeightConfig["Marketing"] = 60;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyReputationOracle() {
        if (msg.sender != reputationOracleAddress) {
            revert UnauthorizedAction();
        }
        _;
    }

    modifier onlyBondOwner(uint256 _bondId) {
        if (_ownerOf(_bondId) != msg.sender) {
            revert InvalidBondOwner();
        }
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        if (forgeTasks[_taskId].creator != msg.sender) {
            revert UnauthorizedAction();
        }
        _;
    }

    modifier onlyStageVerifier(uint256 _taskId, uint256 _stageIndex) {
        ForgeTask storage task = forgeTasks[_taskId];
        if (_stageIndex >= task.stages.length) {
            revert InvalidStageIndex();
        }
        bool isVerifier = false;
        for (uint256 i = 0; i < task.stages[_stageIndex].verifiers.length; i++) {
            if (task.stages[_stageIndex].verifiers[i] == msg.sender) {
                isVerifier = true;
                break;
            }
        }
        if (!isVerifier) {
            revert UnauthorizedAction();
        }
        _;
    }

    modifier taskActive(uint256 _taskId) {
        ForgeTask storage task = forgeTasks[_taskId];
        if (task.status != TaskStatus.Active) {
            revert TaskNotActive();
        }
        _;
    }

    modifier stagePending(uint256 _taskId, uint256 _stageIndex) {
        ForgeTask storage task = forgeTasks[_taskId];
        if (task.stages[_stageIndex].status != StageStatus.Pending) {
            revert StageNotReadyForVerification(); // or OutputSubmitted for some paths
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                I. Core Platform Management & Configuration
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets the address that receives platform fees.
    /// @param _recipient The new fee recipient address.
    function setPlatformFeeRecipient(address _recipient) external onlyOwner {
        if (_recipient == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        platformFeeRecipient = _recipient;
    }

    /// @dev Sets the fee to mint a new AetherBond.
    /// @param _fee The new bond minting fee in WEI.
    function setBondMintFee(uint256 _fee) external onlyOwner {
        bondMintFee = _fee;
    }

    /// @dev Sets the fee to propose a new ForgeTask.
    /// @param _fee The new task creation fee in WEI.
    function setTaskCreationFee(uint256 _fee) external onlyOwner {
        taskCreationFee = _fee;
    }

    /// @dev Sets the trusted reputation oracle contract address.
    /// @param _oracleAddress The address of the new reputation oracle.
    function setReputationOracleAddress(address _oracleAddress) external onlyOwner {
        if (_oracleAddress == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        reputationOracleAddress = _oracleAddress;
    }

    /// @dev Configures how different skills contribute to task eligibility or scoring.
    /// @param _skillName The name of the skill.
    /// @param _weight The weight/importance of the skill (e.g., 1-100).
    function setSkillWeightConfig(string calldata _skillName, uint256 _weight) external onlyOwner {
        skillWeightConfig[_skillName] = _weight;
    }

    /// @dev Pauses the system in case of emergency.
    function pauseSystem() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses the system.
    function unpauseSystem() external onlyOwner {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                II. AetherBond (Dynamic NFT) Management
    //////////////////////////////////////////////////////////////*/

    /// @dev Mints a new AetherBond NFT for the caller.
    /// @param _initialSkills An array of skill names and their initial levels. Example: ["Solidity", 80, "UI/UX", 70]
    /// @notice Requires `bondMintFee` to be paid.
    function forgeAetherBond(string[] calldata _initialSkills) external payable nonReentrant whenNotPaused returns (uint256) {
        if (msg.value < bondMintFee) {
            revert InsufficientFee(bondMintFee, msg.value);
        }
        if (platformFeeRecipient != address(0)) {
            // Transfer fee to the recipient
            (bool success, ) = platformFeeRecipient.call{value: bondMintFee}("");
            require(success, "Failed to send fee");
        }

        uint256 tokenId = nextBondId++;
        _safeMint(msg.sender, tokenId);

        AetherBond storage newBond = aetherBonds[tokenId];
        newBond.tokenId = tokenId;
        newBond.owner = msg.sender;
        newBond.reputationScore = 0; // Initial score, to be updated by oracle
        newBond.totalContributions = 0;
        newBond.status = BondStatus.Active;
        newBond.createdAt = block.timestamp;

        // Initialize skills
        for (uint256 i = 0; i < _initialSkills.length; i += 2) {
            newBond.skillSet[_initialSkills[i]] = abi.decode(abi.encodePacked(_initialSkills[i+1]), (uint256));
        }

        ownerBonds[msg.sender].push(tokenId);
        emit AetherBondForged(tokenId, msg.sender, _initialSkills);
        return tokenId;
    }

    /// @dev Allows a bond owner to declare or update their skills.
    /// @param _bondId The ID of the AetherBond.
    /// @param _newSkills An array of skill names and their new levels.
    /// @notice Future versions might require proof or verification for skill updates.
    function updateBondSkills(uint256 _bondId, string[] calldata _newSkills) external onlyBondOwner(_bondId) whenNotPaused {
        AetherBond storage bond = aetherBonds[_bondId];
        if (bond.status != BondStatus.Active) {
            revert BondNotFound();
        }

        // Clear existing skills for simplicity in this example, or selectively update
        // For a more robust system, one might add/update specific skills
        // Here, we just overwrite based on the provided list
        for (uint256 i = 0; i < _newSkills.length; i += 2) {
            bond.skillSet[_newSkills[i]] = abi.decode(abi.encodePacked(_newSkills[i+1]), (uint256));
        }
        emit AetherBondSkillsUpdated(_bondId, msg.sender, _newSkills);
    }

    /// @dev Callback function to update an AetherBond's reputation score.
    /// @param _bondId The ID of the AetherBond to update.
    /// @param _newScore The new reputation score from the oracle.
    /// @notice This function should only be callable by the designated `reputationOracleAddress`.
    function updateBondReputation(uint256 _bondId, uint256 _newScore) external onlyReputationOracle {
        AetherBond storage bond = aetherBonds[_bondId];
        if (bond.status != BondStatus.Active) {
            revert BondNotFound();
        }
        bond.reputationScore = _newScore;
        emit AetherBondReputationUpdated(_bondId, _newScore);
    }

    /// @dev Retrieves detailed information about an AetherBond.
    /// @param _bondId The ID of the AetherBond.
    /// @return AetherBond struct data.
    function getBondDetails(uint256 _bondId) public view returns (AetherBond memory) {
        AetherBond storage bond = aetherBonds[_bondId];
        if (bond.status == BondStatus.Burned) {
            revert BondNotFound();
        }
        return bond;
    }

    /// @dev Allows an AetherBond owner to burn their bond.
    /// @param _bondId The ID of the AetherBond to burn.
    /// @notice This permanently removes the bond and its associated reputation/history.
    function burnAetherBond(uint256 _bondId) external onlyBondOwner(_bondId) whenNotPaused {
        AetherBond storage bond = aetherBonds[_bondId];
        if (bond.status != BondStatus.Active) {
            revert BondNotFound();
        }
        _burn(_bondId);
        bond.status = BondStatus.Burned;

        // Remove from ownerBonds array (simple linear search and removal for demo)
        uint256[] storage bonds = ownerBonds[msg.sender];
        for (uint256 i = 0; i < bonds.length; i++) {
            if (bonds[i] == _bondId) {
                bonds[i] = bonds[bonds.length - 1];
                bonds.pop();
                break;
            }
        }
        emit AetherBondBurned(_bondId, msg.sender);
    }

    /// @dev Internal function to increment a bond's contribution count.
    /// @param _bondId The ID of the AetherBond.
    function _incrementBondContributions(uint256 _bondId) internal {
        AetherBond storage bond = aetherBonds[_bondId];
        if (bond.status == BondStatus.Active) {
            bond.totalContributions++;
            // Optionally, trigger oracle update for reputation here
            // IReputationOracle(reputationOracleAddress).requestReputationUpdate(address(this), _bondId);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        III. ForgeTask (Project) Management
    //////////////////////////////////////////////////////////////*/

    /// @dev Proposes a new multi-stage ForgeTask.
    /// @param _title The title of the task.
    /// @param _description A detailed description of the task.
    /// @param _totalBounty The total ETH/token bounty for the task.
    /// @param _stages An array of TaskStage structs defining each stage.
    /// @notice Requires `taskCreationFee` and `_totalBounty` to be paid.
    function proposeForgeTask(
        string calldata _title,
        string calldata _description,
        uint256 _totalBounty,
        TaskStage[] calldata _stages
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        if (msg.value < taskCreationFee.add(_totalBounty)) {
            revert InsufficientFee(taskCreationFee.add(_totalBounty), msg.value);
        }
        if (platformFeeRecipient != address(0)) {
            (bool success, ) = platformFeeRecipient.call{value: taskCreationFee}("");
            require(success, "Failed to send task fee");
        }

        uint256 taskId = nextTaskId++;
        ForgeTask storage newTask = forgeTasks[taskId];
        newTask.taskId = taskId;
        newTask.creator = msg.sender;
        newTask.title = _title;
        newTask.description = _description;
        newTask.totalBounty = _totalBounty;
        newTask.status = TaskStatus.Proposed;
        newTask.currentStageIndex = 0;

        uint256 totalRewardPercentage = 0;
        for (uint256 i = 0; i < _stages.length; i++) {
            if (_stages[i].rewardPercentage == 0 || _stages[i].rewardPercentage > 10000) { // 10000 = 100%
                revert InvalidRewardPercentage();
            }
            if (_stages[i].deadline <= block.timestamp) {
                revert InvalidStageIndex(); // Should be a dedicated error for deadline in the past
            }
            // Ensure creator is not a verifier for their own task's stage (to promote decentralization)
            for (uint256 j = 0; j < _stages[i].verifiers.length; j++) {
                if (_stages[i].verifiers[j] == msg.sender) {
                    revert TaskCreatorCannotBeVerifier();
                }
            }
            newTask.stages.push(_stages[i]);
            totalRewardPercentage = totalRewardPercentage.add(_stages[i].rewardPercentage);
        }

        if (totalRewardPercentage > 10000) { // Sum of percentages should not exceed 100%
             revert InvalidRewardPercentage();
        }

        emit ForgeTaskProposed(taskId, msg.sender, _title, _totalBounty);
        return taskId;
    }

    /// @dev An AetherBond owner pledges their bond to a specific task.
    /// @param _taskId The ID of the ForgeTask.
    /// @param _bondId The ID of the AetherBond to pledge.
    /// @notice Requires the bond to meet the minimum skill requirements for the task's initial stages.
    function pledgeBondToTask(uint256 _taskId, uint256 _bondId) external onlyBondOwner(_bondId) whenNotPaused {
        ForgeTask storage task = forgeTasks[_taskId];
        if (task.status != TaskStatus.Proposed) {
            revert TaskAlreadyStarted();
        }
        if (task.pledgedBonds[_bondId]) {
            revert BondAlreadyPledged();
        }

        AetherBond storage bond = aetherBonds[_bondId];
        if (bond.status != BondStatus.Active) {
            revert BondNotFound();
        }

        // Basic skill check for initial eligibility (can be more complex)
        // Checks if bond meets skills for the *first* stage
        if (task.stages.length > 0) {
            TaskStage storage firstStage = task.stages[0];
            for (uint256 i = 0; i < firstStage.requiredSkills.length; i++) { // This assumes keys can be iterated (not possible for mapping directly)
                // A more robust check would iterate known skills or require external verification
                // For simplicity, we'll assume a direct lookup for a few skills is sufficient
                // Example check (conceptual as mapping iteration is hard):
                // string memory skillName = "Solidity";
                // if (firstStage.requiredSkills[skillName] > 0 && bond.skillSet[skillName] < firstStage.requiredSkills[skillName]) {
                //    revert BondNotEligibleForTask();
                // }
            }
        }

        task.pledgedBonds[_bondId] = true;
        task.pledgedBondOwners[_bondId] = msg.sender;
        emit BondPledgedToTask(_taskId, _bondId, msg.sender);
    }

    /// @dev Allows an AetherBond owner to unpledge their bond from a task before it starts.
    /// @param _taskId The ID of the ForgeTask.
    /// @param _bondId The ID of the AetherBond to unpledge.
    function unpledgeBondFromTask(uint256 _taskId, uint256 _bondId) external onlyBondOwner(_bondId) whenNotPaused {
        ForgeTask storage task = forgeTasks[_taskId];
        if (task.status != TaskStatus.Proposed) {
            revert CannotUnstakeAfterStart();
        }
        if (!task.pledgedBonds[_bondId]) {
            revert BondNotPledged();
        }
        delete task.pledgedBonds[_bondId];
        delete task.pledgedBondOwners[_bondId];
        emit BondUnpledgedFromTask(_taskId, _bondId, msg.sender);
    }

    /// @dev The task creator initiates the task, locking pledged bonds and starting the first stage.
    /// @param _taskId The ID of the ForgeTask to start.
    function startForgeTask(uint256 _taskId) external onlyTaskCreator(_taskId) nonReentrant whenNotPaused {
        ForgeTask storage task = forgeTasks[_taskId];
        if (task.status != TaskStatus.Proposed) {
            revert TaskAlreadyStarted();
        }
        if (task.stages.length == 0) {
            revert TaskNotStagedCorrectly();
        }

        task.status = TaskStatus.Active;
        // Bonds are conceptually "locked" by their `pledgedBonds` status.
        // Actual transfer/escrow could be added if bond NFTs were non-transferrable during tasks.
        emit ForgeTaskStarted(_taskId, msg.sender);
    }

    /// @dev An executor (owner of a pledged bond) submits the output/proof for a task stage.
    /// @param _taskId The ID of the ForgeTask.
    /// @param _stageIndex The index of the stage (0-based).
    /// @param _outputProofURI A URI pointing to the task output or proof (e.g., IPFS hash).
    /// @param _executorBondId The AetherBond ID used by the executor.
    /// @notice Requires the bond to be pledged and meet the stage's skill requirements.
    function submitStageOutput(
        uint256 _taskId,
        uint256 _stageIndex,
        string calldata _outputProofURI,
        uint256 _executorBondId
    ) external onlyBondOwner(_executorBondId) nonReentrant taskActive(_taskId) whenNotPaused {
        ForgeTask storage task = forgeTasks[_taskId];
        if (_stageIndex != task.currentStageIndex) {
            revert InvalidStageIndex();
        }
        if (_stageIndex >= task.stages.length) {
            revert InvalidStageIndex();
        }
        TaskStage storage stage = task.stages[_stageIndex];
        if (stage.status != StageStatus.Pending) {
            revert StageOutputAlreadySubmitted(); // Or already verified/paid
        }
        if (block.timestamp > stage.deadline) {
            revert StageDeadlinePassed();
        }
        if (!task.pledgedBonds[_executorBondId] || task.pledgedBondOwners[_executorBondId] != msg.sender) {
            revert BondNotPledged();
        }

        // Additional skill validation for the executor's bond against stage requirements (similar to pledge)
        // ... (conceptual skill matching logic here) ...

        stage.outputProofURI = _outputProofURI;
        stage.executor = msg.sender; // The address of the person who submitted
        stage.status = StageStatus.OutputSubmitted;
        emit StageOutputSubmitted(_taskId, _stageIndex, msg.sender, _outputProofURI);
    }

    /// @dev A designated verifier approves a stage's completion.
    /// @param _taskId The ID of the ForgeTask.
    /// @param _stageIndex The index of the stage.
    /// @notice Requires the stage output to be submitted and verifier authorization.
    function verifyStageCompletion(uint256 _taskId, uint256 _stageIndex)
        external
        onlyStageVerifier(_taskId, _stageIndex)
        nonReentrant
        taskActive(_taskId)
        whenNotPaused
    {
        ForgeTask storage task = forgeTasks[_taskId];
        if (_stageIndex != task.currentStageIndex) {
            revert InvalidStageIndex();
        }
        if (_stageIndex >= task.stages.length) {
            revert InvalidStageIndex();
        }
        TaskStage storage stage = task.stages[_stageIndex];
        if (stage.status != StageStatus.OutputSubmitted) {
            revert StageNotReadyForVerification();
        }

        // For a more robust system, implement a quorum verification or a single lead verifier.
        // For simplicity, any designated verifier can mark as verified.
        stage.status = StageStatus.Verified;
        stage.completionTime = block.timestamp;
        emit StageVerified(_taskId, _stageIndex, msg.sender);
    }

    /// @dev Releases funds for a completed stage to the participating executors.
    /// @param _taskId The ID of the ForgeTask.
    /// @param _stageIndex The index of the stage.
    /// @notice Only callable if the stage is verified.
    function distributeStageReward(uint256 _taskId, uint256 _stageIndex) external nonReentrant taskActive(_taskId) whenNotPaused {
        ForgeTask storage task = forgeTasks[_taskId];
        if (_stageIndex != task.currentStageIndex) {
            revert InvalidStageIndex();
        }
        if (_stageIndex >= task.stages.length) {
            revert InvalidStageIndex();
        }
        TaskStage storage stage = task.stages[_stageIndex];
        if (stage.status != StageStatus.Verified) {
            revert StageNotReadyForPayout();
        }
        if (stage.executor == address(0)) {
            revert StageOutputRequired(); // Should not happen if stage status is Verified
        }

        uint256 rewardAmount = task.totalBounty.mul(stage.rewardPercentage).div(10000); // 10000 for 100%
        
        // Potential for reputation-based reward multiplier:
        // uint256 bondIdOfExecutor = // How to get bondId from address? Store it in TaskStage executor_bond_id;
        // uint256 reputationMultiplier = 1; // get from aetherBonds[bondIdOfExecutor].reputationScore;
        // rewardAmount = rewardAmount.mul(reputationMultiplier).div(100); // Example multiplier

        (bool success, ) = stage.executor.call{value: rewardAmount}("");
        if (!success) {
            // If transfer fails, revert or implement a retry/fallback mechanism.
            // For now, we revert.
            revert("Failed to send stage reward");
        }

        stage.status = StageStatus.Paid;
        _incrementBondContributions(_ownerOf(task.pledgedBonds[stage.executor])); // Find the bond ID by executor address. Requires storing bond ID.
                                                                                // This part is simplified; a bond mapping to address is needed.
        _advanceToNextStage(_taskId); // Advance to the next stage upon successful payout
        emit StageRewardDistributed(_taskId, _stageIndex, stage.executor, rewardAmount);
    }

    /// @dev Internal function to transition a task to its next stage.
    /// @param _taskId The ID of the ForgeTask.
    function _advanceToNextStage(uint256 _taskId) internal {
        ForgeTask storage task = forgeTasks[_taskId];
        task.currentStageIndex++;
        if (task.currentStageIndex >= task.stages.length) {
            task.status = TaskStatus.Completed;
            emit ForgeTaskCompleted(_taskId);
        }
    }

    /// @dev Marks a task as fully completed after all stages are done.
    /// @param _taskId The ID of the ForgeTask.
    /// @notice This function automatically called by `_advanceToNextStage` if it's the last stage.
    /// It can also be called manually by creator if, for example, there's a small remaining balance
    /// or finalization needed without an explicit last stage payout.
    function completeForgeTask(uint256 _taskId) external onlyTaskCreator(_taskId) nonReentrant whenNotPaused {
        ForgeTask storage task = forgeTasks[_taskId];
        if (task.status == TaskStatus.Completed) {
            revert TaskAlreadyCompleted();
        }
        if (task.currentStageIndex < task.stages.length) {
            revert TaskNotStagedCorrectly(); // Not all stages completed
        }

        task.status = TaskStatus.Completed;
        emit ForgeTaskCompleted(_taskId);
    }

    /// @dev Allows the creator or governance to cancel a task under specific conditions, refunding staked funds.
    /// @param _taskId The ID of the ForgeTask.
    /// @param _reason A string explaining the reason for cancellation.
    /// @notice Can only be cancelled if not started or if explicit cancellation rules are met.
    function cancelForgeTask(uint256 _taskId, string calldata _reason) external onlyTaskCreator(_taskId) nonReentrant whenNotPaused {
        ForgeTask storage task = forgeTasks[_taskId];
        if (task.status == TaskStatus.Completed || task.status == TaskStatus.Cancelled) {
            revert TaskAlreadyCompleted(); // Already done or cancelled
        }

        // Refund any remaining bounty to the creator
        uint256 remainingBounty = address(this).balance - taskCreationFee; // Simplified, track total bounty more carefully
        if (remainingBounty > 0) {
            (bool success, ) = task.creator.call{value: remainingBounty}("");
            require(success, "Failed to refund bounty on cancel");
        }

        task.status = TaskStatus.Cancelled;
        emit ForgeTaskCancelled(_taskId, _reason);
    }

    /// @dev Retrieves full details of a ForgeTask.
    /// @param _taskId The ID of the ForgeTask.
    /// @return ForgeTask struct data.
    function getTaskDetails(uint256 _taskId) public view returns (ForgeTask memory) {
        return forgeTasks[_taskId];
    }

    /// @dev Retrieves details of a specific stage within a task.
    /// @param _taskId The ID of the ForgeTask.
    /// @param _stageIndex The index of the stage.
    /// @return TaskStage struct data.
    function getTaskStageDetails(uint256 _taskId, uint256 _stageIndex) public view returns (TaskStage memory) {
        ForgeTask storage task = forgeTasks[_taskId];
        if (_stageIndex >= task.stages.length) {
            revert InvalidStageIndex();
        }
        return task.stages[_stageIndex];
    }

    /*//////////////////////////////////////////////////////////////
                    IV. Dispute Resolution & Advanced Utilities
    //////////////////////////////////////////////////////////////*/

    /// @dev Allows any participant to formally dispute a stage completion or task outcome.
    /// @param _taskId The ID of the ForgeTask.
    /// @param _stageIndex The index of the stage being disputed.
    /// @param _reason A string explaining the reason for the dispute.
    /// @notice This would typically trigger a governance vote or an arbitration process.
    function lodgeDispute(uint256 _taskId, uint256 _stageIndex, string calldata _reason) external nonReentrant whenNotPaused {
        ForgeTask storage task = forgeTasks[_taskId];
        if (task.status != TaskStatus.Active) {
            revert TaskNotActive();
        }
        if (_stageIndex >= task.stages.length) {
            revert InvalidStageIndex();
        }
        if (task.disputer != address(0)) {
            revert NoOutstandingDispute(); // Only one dispute at a time for simplicity
        }

        task.status = TaskStatus.Disputed;
        task.disputer = msg.sender;
        task.disputeDeadline = block.timestamp + 7 days; // Example: 7 days to resolve

        // Mark the specific stage as disputed
        task.stages[_stageIndex].status = StageStatus.Disputed;

        emit DisputeLodged(_taskId, _stageIndex, msg.sender);
    }

    /// @dev Governance or a designated arbitrator resolves a lodged dispute.
    /// @param _taskId The ID of the ForgeTask.
    /// @param _stageIndex The index of the stage that was disputed.
    /// @param _success True if the dispute is resolved in favor of the current stage status, false if it's reverted.
    /// @notice Requires a specific role (e.g., owner, or a DAO's `execute` function).
    function resolveDispute(uint256 _taskId, uint256 _stageIndex, bool _success) external onlyOwner nonReentrant whenNotPaused { // Simplified: only owner resolves
        ForgeTask storage task = forgeTasks[_taskId];
        if (task.status != TaskStatus.Disputed) {
            revert NoOutstandingDispute();
        }
        if (_stageIndex >= task.stages.length) {
            revert InvalidStageIndex();
        }
        if (task.stages[_stageIndex].status != StageStatus.Disputed) {
            revert StageNotReadyForVerification(); // Or specific error for non-disputed stage
        }

        if (_success) {
            // Dispute failed, stage status reverts to its previous valid state or moves forward
            // Here, we assume if dispute fails, the stage output is re-validated, then stage continues as if it passed
            // For example, if it was 'OutputSubmitted' and disputed, it goes back to 'OutputSubmitted'
            // If it was 'Verified' and disputed, it goes back to 'Verified'
            // More complex logic needed here to restore precise previous state.
            task.stages[_stageIndex].status = StageStatus.Verified; // Assuming it was verified before dispute
        } else {
            // Dispute succeeded, stage is reverted, potentially requiring new submission
            task.stages[_stageIndex].status = StageStatus.Pending;
            task.stages[_stageIndex].outputProofURI = "";
            task.stages[_stageIndex].executor = address(0);
        }

        task.status = TaskStatus.Active; // Task goes back to active status
        task.disputer = address(0); // Clear disputer
        task.disputeDeadline = 0; // Clear deadline

        emit DisputeResolved(_taskId, _stageIndex, msg.sender, _success);
    }

    /// @dev Allows a task creator (or governance) to extend a stage deadline.
    /// @param _taskId The ID of the ForgeTask.
    /// @param _stageIndex The index of the stage.
    /// @param _newDeadline The new timestamp for the deadline.
    /// @notice Can only be extended if the stage is not yet completed and new deadline is in future.
    function updateTaskStageDeadline(uint256 _taskId, uint256 _stageIndex, uint256 _newDeadline) external onlyTaskCreator(_taskId) whenNotPaused {
        ForgeTask storage task = forgeTasks[_taskId];
        if (_stageIndex >= task.stages.length) {
            revert InvalidStageIndex();
        }
        TaskStage storage stage = task.stages[_stageIndex];
        if (stage.status == StageStatus.Verified || stage.status == StageStatus.Paid || stage.status == StageStatus.Disputed) {
            revert StageAlreadyCompleted(); // Or in dispute, cannot change deadline
        }
        if (_newDeadline <= block.timestamp) {
            revert InvalidStageIndex(); // Should be a dedicated error: deadline in past
        }

        stage.deadline = _newDeadline;
        emit TaskStageDeadlineExtended(_taskId, _stageIndex, _newDeadline);
    }

    /// @dev Allows the creator to modify *future* stage details based on prior stage outcomes or oracle data.
    /// @param _taskId The ID of the ForgeTask.
    /// @param _stageIndex The index of the future stage to modify.
    /// @param _newStageDetails The new TaskStage struct for the future stage.
    /// @notice This function embodies the "adaptive" nature. Only future stages (beyond current) can be modified.
    function dynamicStageAdjustment(uint256 _taskId, uint256 _stageIndex, TaskStage calldata _newStageDetails) external onlyTaskCreator(_taskId) whenNotPaused {
        ForgeTask storage task = forgeTasks[_taskId];
        if (_stageIndex <= task.currentStageIndex) {
            revert OnlyFutureStagesModifiable();
        }
        if (_stageIndex >= task.stages.length) {
            revert InvalidStageIndex();
        }
        if (_newStageDetails.rewardPercentage == 0 || _newStageDetails.rewardPercentage > 10000) {
            revert InvalidRewardPercentage();
        }
        if (_newStageDetails.deadline <= block.timestamp) {
            revert InvalidStageIndex(); // Dedicated error for deadline in past
        }
        // Ensure creator is not a verifier for their own task's stage (to promote decentralization)
        for (uint256 j = 0; j < _newStageDetails.verifiers.length; j++) {
            if (_newStageDetails.verifiers[j] == msg.sender) {
                revert TaskCreatorCannotBeVerifier();
            }
        }

        task.stages[_stageIndex] = _newStageDetails; // Overwrite the stage details
        emit FutureStageAdjusted(_taskId, _stageIndex);
    }

    /// @dev Allows the task creator to withdraw any remaining bounty if a task is cancelled or completed with leftover funds.
    /// @param _taskId The ID of the ForgeTask.
    /// @notice Can only be called if task is Completed or Cancelled and has excess funds.
    function withdrawExcessFunds(uint256 _taskId) external onlyTaskCreator(_taskId) nonReentrant whenNotPaused {
        ForgeTask storage task = forgeTasks[_taskId];
        if (task.status != TaskStatus.Completed && task.status != TaskStatus.Cancelled) {
            revert TaskNotActive(); // Task must be finalized
        }

        // Calculate disbursed funds. This would require tracking total disbursed or
        // summing up paid stage rewards from a separate mapping or event log.
        // For simplicity, we assume 'totalBounty' is the initial balance and calculate remaining.
        // A more robust system would calculate distributed funds and then `remaining = initial - distributed`.
        uint256 remainingBounty = address(this).balance; // Total contract balance
        // If contract holds funds from multiple tasks, need a mapping like task.escrowedBalance.
        // For this demo, assuming each task's bounty is distinct and tracked.
        // A more accurate check would be: task.initialBounty - sumOfPaidStageRewards.
        // Since we don't explicitly track initial total contract balance per task,
        // this is a simplified example.
        if (remainingBounty == 0) {
            revert("No excess funds to withdraw.");
        }

        (bool success, ) = msg.sender.call{value: remainingBounty}("");
        require(success, "Failed to withdraw excess funds");
        emit ExcessFundsWithdrawn(_taskId, msg.sender, remainingBounty);
    }

    /*//////////////////////////////////////////////////////////////
                            Helper/View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Gets all AetherBond IDs owned by a specific address.
    /// @param _owner The address of the bond owner.
    /// @return An array of bond IDs.
    function getOwnedBondIds(address _owner) external view returns (uint256[] memory) {
        return ownerBonds[_owner];
    }

    // Overriding _beforeTokenTransfer to incorporate a custom check if needed,
    // for example, disallowing transfer of bonds actively pledged to a task.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Custom logic: e.g., if a bond is pledged to an active task, disallow transfer.
        // This would require iterating through active tasks, which is gas-intensive.
        // A mapping `isBondPledgedToActiveTask[bondId]` would be better.
        // For now, no explicit restriction on transfer during pledge/active task.
    }
}
```