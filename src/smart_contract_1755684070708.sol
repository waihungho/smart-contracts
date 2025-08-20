Okay, this is an exciting challenge! I'll create a smart contract called **ChronoForge** that aims to fuse concepts of time-weighted reputation, dynamic asset creation, and decentralized orchestration, without directly replicating existing open-source projects.

The core idea is: Users lock tokens for varying durations to accrue "Chrono-Power" (CP). This CP acts as a reputation and utility score, enabling users to "forge" unique, programmable "Artifacts" (NFT-like assets) and participate in "Chrono-Quests" – decentralized tasks or challenges that might involve oracle interaction and community voting.

---

## ChronoForge Smart Contract

**Concept:** ChronoForge is a decentralized protocol where users lock utility tokens to accumulate time-weighted "Chrono-Power" (CP). This CP unlocks advanced functionalities:
1.  **Artifact Forging:** Users can mint unique, programmable "Artifacts" (NFT-like assets) whose properties can dynamically evolve based on external data or owner actions.
2.  **Chrono-Quests:** A system for proposing, voting on, and executing decentralized tasks or challenges, potentially requiring off-chain verification via oracles. Successful quest completion grants rewards and CP.
3.  **Dynamic Governance:** Key protocol parameters are adjustable through a time-weighted voting mechanism.

**Advanced Concepts & Features:**

*   **Time-Weighted Staking/Reputation (Chrono-Power):** CP accrual is based on both amount and duration of locked tokens, encouraging long-term commitment.
*   **Dynamic, Programmable NFTs (Artifacts):** Artifacts aren't static JPEGs. They have mutable, on-chain properties that can be updated, potentially by oracle data, user actions, or quest outcomes. They behave like an internal ERC-721 but with programmable attributes.
*   **Decentralized Orchestration (Chrono-Quests):** A mini-DAO for proposing and executing verifiable tasks, bridging on-chain governance with potential off-chain actions.
*   **Oracle Integration (Conceptual):** The contract structure allows for an Oracle to verify quest outcomes, providing a pathway for real-world data interaction (though the oracle logic itself is simplified for this contract).
*   **Tiered Access/Utility:** CP gates access to forging and quest participation.
*   **Custom Errors:** Using `error` for efficient and clear revert messages.
*   **Pausable & ReentrancyGuard:** Essential security patterns.
*   **Event-Driven:** Comprehensive event emissions for off-chain monitoring.

---

### **Outline and Function Summary:**

**I. Core Infrastructure & Configuration**
1.  `constructor()`: Initializes token, oracle, and admin addresses.
2.  `setApprovedToken(address _tokenAddress, bool _isApproved)`: Whitelists/blacklists tokens for locking.
3.  `setOracleAddress(address _newOracle)`: Sets the trusted oracle address (admin only).
4.  `pause()`: Pauses contract operations (admin only, emergency).
5.  `unpause()`: Unpauses contract operations (admin only).
6.  `withdrawFees(address _to, uint256 _amount)`: Allows admin to withdraw collected fees.
7.  `getContractBalance()`: Returns the contract's token balance.

**II. Chrono-Power (CP) Mechanics**
8.  `lockTokens(uint256 _amount, uint256 _durationInDays)`: Locks approved tokens for a duration, accruing CP.
9.  `extendLock(uint256 _lockIndex, uint256 _additionalDurationInDays)`: Extends an existing token lock.
10. `unlockTokens(uint256 _lockIndex)`: Unlocks tokens after their duration expires.
11. `getChronoPower(address _user)`: Calculates and returns a user's total active Chrono-Power.
12. `calculateChronoPower(uint256 _amount, uint256 _durationInDays)`: Internal helper to determine CP for a lock.

**III. Artifact Forging & Management (Dynamic NFTs)**
13. `forgeArtifact(string memory _initialMetadataURI)`: Mints a new Artifact, requiring sufficient CP and a forging fee.
14. `updateArtifactDynamicProperty(uint256 _artifactId, string memory _key, uint256 _value)`: Allows Artifact owner to update its dynamic properties.
15. `transferArtifact(address _from, address _to, uint256 _artifactId)`: Standard ERC721-like transfer for an Artifact.
16. `burnArtifact(uint256 _artifactId)`: Allows Artifact owner to destroy their Artifact.
17. `getArtifactDetails(uint256 _artifactId)`: Retrieves full details of an Artifact.
18. `getUserArtifacts(address _user)`: Returns all Artifact IDs owned by a user.
19. `getTotalArtifacts()`: Returns the total number of Artifacts minted.

**IV. Chrono-Quests System**
20. `proposeChronoQuest(string memory _description, uint256 _rewardAmount, uint256 _votingDurationDays, uint256 _executionDurationDays)`: Proposes a new quest, requiring CP and a bond.
21. `voteOnChronoQuest(uint256 _questId, bool _support)`: Allows CP holders to vote on quest proposals.
22. `cancelChronoQuestProposal(uint256 _questId)`: Proposer can cancel their own quest if not yet approved/rejected.
23. `oracleReportQuestOutcome(uint256 _questId, bool _success, string memory _proofDetails)`: Callable only by the designated oracle to report a quest's external outcome.
24. `claimQuestReward(uint256 _questId)`: Allows the proposer to claim rewards if the quest was successful and verified.
25. `getQuestDetails(uint256 _questId)`: Retrieves details for a specific quest.

**V. Dynamic Protocol Parameters (Simple Governance)**
26. `proposeParameterChange(string memory _paramName, uint256 _newValue, uint256 _votingDurationDays)`: Proposes a change to a key contract parameter.
27. `voteOnParameterChange(uint256 _proposalId, bool _support)`: CP holders vote on parameter change proposals.
28. `executeParameterChange(uint256 _proposalId)`: Executes the parameter change if the proposal passes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Custom Errors ---
error InvalidAmount();
error InvalidDuration();
error LockNotFound();
error LockNotExpired();
error NotEnoughChronoPower(uint256 required, uint256 current);
error AlreadyVoted();
error VotingPeriodNotActive();
error VotingPeriodExpired();
error ProposalAlreadyExecuted();
error ProposalNotPassed();
error QuestNotFound();
error QuestNotProposable();
error QuestNotYetExecuted();
error QuestAlreadyClaimed();
error QuestOutcomeNotReported();
error NotAuthorized();
error ArtifactNotFound();
error NotArtifactOwner();
error ForgingFeeNotSet();
error OracleNotSet();
error InvalidToken();
error TokenNotApproved();
error ParameterNotFound();
error CannotVoteOnOwnProposal();
error InvalidQuestStatus();
error NotEnoughBalance(uint256 required, uint256 current);
error QuestBondRequired(uint256 required);

// --- Interfaces (Simplified for conceptual Oracle) ---
interface IOracle {
    function getQuestStatus(uint256 _questId) external view returns (bool, string memory);
}

contract ChronoForge is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    IERC20 public immutable forgeToken; // The primary utility token for locking and fees
    address public oracleAddress; // Address of the trusted oracle
    
    // Configurable Parameters (can be changed via governance)
    uint256 public forgingFeeCP; // CP required to forge an Artifact
    uint256 public forgingFeeTokens; // Tokens required to forge an Artifact
    uint256 public questProposalCP; // CP required to propose a Quest
    uint256 public questProposalBond; // Tokens required as bond for a Quest proposal
    uint256 public constant MIN_LOCK_DURATION_DAYS = 7; // Minimum 7 days
    uint256 public constant MAX_LOCK_DURATION_DAYS = 365 * 5; // Max 5 years
    uint256 public constant CHRONO_POWER_MULTIPLIER = 1000; // Multiplier for CP calculation

    mapping(address => bool) public approvedTokens; // Tokens allowed for locking
    mapping(address => Lock[]) public userLocks; // User's active token locks
    
    Counters.Counter private _artifactIds;
    mapping(uint256 => Artifact) public artifacts; // All minted artifacts
    mapping(address => uint256[]) public ownerArtifacts; // Artifacts owned by an address

    Counters.Counter private _questIds;
    mapping(uint256 => ChronoQuest) public chronoQuests; // All proposed quests

    Counters.Counter private _paramProposalIds;
    mapping(uint256 => ParameterChangeProposal) public paramProposals; // All parameter change proposals

    // --- Structs ---

    struct Lock {
        uint256 amount;
        uint256 unlockTime;
        uint256 chronoPowerBoost; // CP generated by this specific lock
        bool active; // True if the lock is active
    }

    enum ArtifactStatus { Exists, Burned }

    struct Artifact {
        uint256 id;
        address owner;
        uint256 creationTime;
        string metadataURI; // Base URI for ERC721 metadata
        mapping(string => uint256) dynamicProperties; // Mutable, programmable attributes
        ArtifactStatus status;
    }

    enum QuestStatus { Proposed, Voting, Approved, Rejected, Executing, Success, Failed, Claimed, Cancelled }

    struct ChronoQuest {
        uint256 id;
        address proposer;
        string description;
        uint256 rewardAmount; // Amount of forgeToken to be rewarded
        uint256 bondAmount; // Amount of forgeToken deposited as bond
        uint256 votingDeadline; // Timestamp when voting ends
        uint256 executionDeadline; // Timestamp when execution (oracle report) must happen
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        uint256 yesVotes;
        uint256 noVotes;
        bool oracleVerifiedSuccess; // True if oracle reported success
        string oracleProofDetails; // Details from oracle report
        QuestStatus status;
    }

    enum ProposalStatus { Proposed, Voting, Approved, Rejected, Executed }

    struct ParameterChangeProposal {
        uint256 id;
        string paramName; // Name of the parameter to change (e.g., "forgingFeeCP")
        uint256 newValue; // New value for the parameter
        address proposer;
        uint256 votingDeadline;
        mapping(address => bool) hasVoted;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
    }

    // --- Events ---
    event TokenLocked(address indexed user, uint256 lockIndex, uint256 amount, uint256 durationDays, uint256 unlockTime, uint256 chronoPower);
    event LockExtended(address indexed user, uint256 lockIndex, uint256 newUnlockTime, uint256 newChronoPower);
    event TokenUnlocked(address indexed user, uint256 lockIndex, uint256 amount);
    event ChronoPowerUpdated(address indexed user, uint256 newChronoPower);

    event ArtifactForged(address indexed owner, uint256 indexed artifactId, string initialMetadataURI, uint256 creationTime);
    event ArtifactPropertyUpdated(uint256 indexed artifactId, string key, uint256 value);
    event ArtifactTransferred(address indexed from, address indexed to, uint256 indexed artifactId);
    event ArtifactBurned(address indexed artifactId);

    event ChronoQuestProposed(address indexed proposer, uint256 indexed questId, string description, uint256 rewardAmount, uint256 votingDeadline, uint256 executionDeadline);
    event ChronoQuestVoted(address indexed voter, uint256 indexed questId, bool support, uint256 yesVotes, uint256 noVotes);
    event ChronoQuestStatusChanged(uint256 indexed questId, QuestStatus oldStatus, QuestStatus newStatus);
    event ChronoQuestOutcomeReported(uint256 indexed questId, bool success, string proofDetails);
    event ChronoQuestRewardClaimed(uint256 indexed questId, address indexed claimant, uint256 rewardAmount);

    event ParameterChangeProposed(address indexed proposer, uint256 indexed proposalId, string paramName, uint256 newValue, uint256 votingDeadline);
    event ParameterChangeVoted(address indexed voter, uint256 indexed proposalId, bool support, uint256 yesVotes, uint256 noVotes);
    event ParameterChangeExecuted(uint256 indexed proposalId, string paramName, uint256 newValue);

    event ApprovedTokenSet(address indexed tokenAddress, bool isApproved);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event FeesWithdrawn(address indexed to, uint256 amount);

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert NotAuthorized();
        }
        _;
    }

    // --- I. Core Infrastructure & Configuration ---

    constructor(address _forgeTokenAddress, address _initialOracleAddress) Ownable(msg.sender) {
        if (_forgeTokenAddress == address(0)) revert InvalidToken();
        if (_initialOracleAddress == address(0)) revert OracleNotSet(); // For a real system, you might allow 0 and set later.

        forgeToken = IERC20(_forgeTokenAddress);
        oracleAddress = _initialOracleAddress;

        // Set initial configurable parameters
        forgingFeeCP = 1000;
        forgingFeeTokens = 1 * 10 ** forgeToken.decimals(); // 1 token
        questProposalCP = 500;
        questProposalBond = 0.1 * 10 ** forgeToken.decimals(); // 0.1 tokens

        // Approve the primary forgeToken by default
        approvedTokens[_forgeTokenAddress] = true;
        emit ApprovedTokenSet(_forgeTokenAddress, true);
    }

    /**
     * @dev Allows the owner to whitelist or blacklist tokens that can be locked.
     * @param _tokenAddress The address of the token to approve or disapprove.
     * @param _isApproved True to approve, false to disapprove.
     */
    function setApprovedToken(address _tokenAddress, bool _isApproved) external onlyOwner {
        if (_tokenAddress == address(0)) revert InvalidToken();
        approvedTokens[_tokenAddress] = _isApproved;
        emit ApprovedTokenSet(_tokenAddress, _isApproved);
    }

    /**
     * @dev Sets the address of the trusted oracle. Only callable by the owner.
     * @param _newOracle The new oracle address.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) revert OracleNotSet();
        address oldOracle = oracleAddress;
        oracleAddress = _newOracle;
        emit OracleAddressSet(oldOracle, _newOracle);
    }

    /**
     * @dev Pauses the contract in case of emergency. Only callable by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw collected fees from the contract.
     * @param _to The address to send the fees to.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawFees(address _to, uint256 _amount) external onlyOwner nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        if (forgeToken.balanceOf(address(this)) < _amount) revert NotEnoughBalance(_amount, forgeToken.balanceOf(address(this)));
        
        forgeToken.transfer(_to, _amount);
        emit FeesWithdrawn(_to, _amount);
    }

    /**
     * @dev Returns the contract's balance of the forgeToken.
     */
    function getContractBalance() public view returns (uint256) {
        return forgeToken.balanceOf(address(this));
    }

    // --- II. Chrono-Power (CP) Mechanics ---

    /**
     * @dev Locks approved tokens for a specified duration to accrue Chrono-Power.
     * @param _amount The amount of tokens to lock.
     * @param _durationInDays The duration in days for which to lock the tokens.
     */
    function lockTokens(uint256 _amount, uint256 _durationInDays) external payable nonReentrant whenNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (_durationInDays < MIN_LOCK_DURATION_DAYS || _durationInDays > MAX_LOCK_DURATION_DAYS) {
            revert InvalidDuration();
        }
        if (!approvedTokens[address(forgeToken)]) revert TokenNotApproved(); // Only primary token for simplicity

        forgeToken.transferFrom(msg.sender, address(this), _amount);

        uint256 cpBoost = calculateChronoPower(_amount, _durationInDays);
        uint256 unlockAt = block.timestamp + (_durationInDays * 1 days);

        userLocks[msg.sender].push(Lock({
            amount: _amount,
            unlockTime: unlockAt,
            chronoPowerBoost: cpBoost,
            active: true
        }));

        emit TokenLocked(msg.sender, userLocks[msg.sender].length - 1, _amount, _durationInDays, unlockAt, cpBoost);
        emit ChronoPowerUpdated(msg.sender, getChronoPower(msg.sender));
    }

    /**
     * @dev Extends the duration of an existing token lock.
     * @param _lockIndex The index of the lock in the user's `userLocks` array.
     * @param _additionalDurationInDays The additional duration in days to extend the lock.
     */
    function extendLock(uint256 _lockIndex, uint256 _additionalDurationInDays) external nonReentrant whenNotPaused {
        if (_lockIndex >= userLocks[msg.sender].length || !userLocks[msg.sender][_lockIndex].active) {
            revert LockNotFound();
        }
        if (_additionalDurationInDays == 0) revert InvalidDuration();

        Lock storage lock = userLocks[msg.sender][_lockIndex];
        uint256 newUnlockTime = lock.unlockTime + (_additionalDurationInDays * 1 days);
        uint256 newTotalDurationDays = (newUnlockTime - block.timestamp) / 1 days;

        if (newTotalDurationDays > MAX_LOCK_DURATION_DAYS) {
            revert InvalidDuration();
        }

        lock.unlockTime = newUnlockTime;
        lock.chronoPowerBoost = calculateChronoPower(lock.amount, newTotalDurationDays);

        emit LockExtended(msg.sender, _lockIndex, newUnlockTime, lock.chronoPowerBoost);
        emit ChronoPowerUpdated(msg.sender, getChronoPower(msg.sender));
    }

    /**
     * @dev Unlocks tokens after their lock duration has expired.
     * @param _lockIndex The index of the lock in the user's `userLocks` array.
     */
    function unlockTokens(uint256 _lockIndex) external nonReentrant whenNotPaused {
        if (_lockIndex >= userLocks[msg.sender].length || !userLocks[msg.sender][_lockIndex].active) {
            revert LockNotFound();
        }

        Lock storage lock = userLocks[msg.sender][_lockIndex];
        if (block.timestamp < lock.unlockTime) {
            revert LockNotExpired();
        }

        lock.active = false; // Mark as inactive
        forgeToken.transfer(msg.sender, lock.amount);

        emit TokenUnlocked(msg.sender, _lockIndex, lock.amount);
        emit ChronoPowerUpdated(msg.sender, getChronoPower(msg.sender));
    }

    /**
     * @dev Calculates a user's total active Chrono-Power from all their locks.
     * @param _user The address of the user.
     * @return The total Chrono-Power of the user.
     */
    function getChronoPower(address _user) public view returns (uint256) {
        uint256 totalCP = 0;
        for (uint256 i = 0; i < userLocks[_user].length; i++) {
            if (userLocks[_user][i].active && block.timestamp < userLocks[_user][i].unlockTime) {
                totalCP += userLocks[_user][i].chronoPowerBoost;
            }
        }
        return totalCP;
    }

    /**
     * @dev Internal helper function to calculate Chrono-Power based on amount and duration.
     *      CP = (amount * duration_in_days * CHRONO_POWER_MULTIPLIER) / 1e18 (to normalize against token decimals)
     * @param _amount The amount of tokens.
     * @param _durationInDays The duration in days.
     * @return The calculated Chrono-Power boost.
     */
    function calculateChronoPower(uint256 _amount, uint256 _durationInDays) internal view returns (uint256) {
        // Simple linear calculation. Can be made more complex (e.g., logarithmic, diminishing returns).
        // Using `forgeToken.decimals()` to normalize the amount to 18 decimals for consistent CP calculation
        // This prevents different token decimal counts from affecting CP generation disproportionately.
        uint256 normalizedAmount = _amount * (10 ** (18 - forgeToken.decimals()));
        return (normalizedAmount * _durationInDays * CHRONO_POWER_MULTIPLIER) / (10**18);
    }

    // --- III. Artifact Forging & Management (Dynamic NFTs) ---

    /**
     * @dev Mints a new Artifact, requiring sufficient Chrono-Power and a token fee.
     * @param _initialMetadataURI The initial URI pointing to the Artifact's metadata.
     */
    function forgeArtifact(string memory _initialMetadataURI) external nonReentrant whenNotPaused {
        if (getChronoPower(msg.sender) < forgingFeeCP) {
            revert NotEnoughChronoPower(forgingFeeCP, getChronoPower(msg.sender));
        }
        if (forgingFeeTokens == 0) revert ForgingFeeNotSet();
        
        forgeToken.transferFrom(msg.sender, address(this), forgingFeeTokens);

        _artifactIds.increment();
        uint256 newArtifactId = _artifactIds.current();

        artifacts[newArtifactId] = Artifact({
            id: newArtifactId,
            owner: msg.sender,
            creationTime: block.timestamp,
            metadataURI: _initialMetadataURI,
            status: ArtifactStatus.Exists
        });
        // Add to owner's list of artifacts
        ownerArtifacts[msg.sender].push(newArtifactId);

        emit ArtifactForged(msg.sender, newArtifactId, _initialMetadataURI, block.timestamp);
    }

    /**
     * @dev Allows the owner of an Artifact to update one of its dynamic properties.
     * @param _artifactId The ID of the Artifact to update.
     * @param _key The key (name) of the property to update.
     * @param _value The new value for the property.
     */
    function updateArtifactDynamicProperty(uint256 _artifactId, string memory _key, uint256 _value) external whenNotPaused {
        Artifact storage artifact = artifacts[_artifactId];
        if (artifact.status != ArtifactStatus.Exists) revert ArtifactNotFound();
        if (artifact.owner != msg.sender) revert NotArtifactOwner();

        artifact.dynamicProperties[_key] = _value;
        emit ArtifactPropertyUpdated(_artifactId, _key, _value);
    }
    
    /**
     * @dev Transfers an Artifact to a new owner. Behaves like ERC721 `transferFrom`.
     * @param _from The current owner of the Artifact.
     * @param _to The address to transfer the Artifact to.
     * @param _artifactId The ID of the Artifact to transfer.
     */
    function transferArtifact(address _from, address _to, uint256 _artifactId) external nonReentrant whenNotPaused {
        // Basic ERC721-like checks
        if (_from == address(0) || _to == address(0)) revert InvalidAmount(); // Reuse InvalidAmount for invalid address
        if (artifacts[_artifactId].status != ArtifactStatus.Exists || artifacts[_artifactId].owner != _from) {
            revert ArtifactNotFound();
        }
        if (_from != msg.sender && !isApprovedForAll(_from, msg.sender)) { // Simplified approval, only owner or approved all
            revert NotAuthorized();
        }
        if (artifacts[_artifactId].owner != _from) revert NotArtifactOwner(); // _from must be actual owner

        // Remove from old owner's list (simple linear search for now, consider mapping(address => mapping(uint256 => bool)) for larger scale)
        uint256[] storage fromArtifacts = ownerArtifacts[_from];
        for (uint256 i = 0; i < fromArtifacts.length; i++) {
            if (fromArtifacts[i] == _artifactId) {
                fromArtifacts[i] = fromArtifacts[fromArtifacts.length - 1]; // Swap with last
                fromArtifacts.pop(); // Remove last element
                break;
            }
        }
        
        artifacts[_artifactId].owner = _to;
        ownerArtifacts[_to].push(_artifactId);

        emit ArtifactTransferred(_from, _to, _artifactId);
    }

    /**
     * @dev Allows the owner of an Artifact to destroy it.
     * @param _artifactId The ID of the Artifact to burn.
     */
    function burnArtifact(uint256 _artifactId) external nonReentrant whenNotPaused {
        Artifact storage artifact = artifacts[_artifactId];
        if (artifact.status != ArtifactStatus.Exists) revert ArtifactNotFound();
        if (artifact.owner != msg.sender) revert NotArtifactOwner();

        artifact.status = ArtifactStatus.Burned; // Mark as burned
        // Remove from owner's list
        uint256[] storage userArts = ownerArtifacts[msg.sender];
        for (uint256 i = 0; i < userArts.length; i++) {
            if (userArts[i] == _artifactId) {
                userArts[i] = userArts[userArts.length - 1];
                userArts.pop();
                break;
            }
        }

        emit ArtifactBurned(_artifactId);
    }

    /**
     * @dev Retrieves the full details of a specific Artifact.
     * @param _artifactId The ID of the Artifact.
     * @return An `Artifact` struct containing its details.
     */
    function getArtifactDetails(uint256 _artifactId) public view returns (Artifact memory) {
        if (artifacts[_artifactId].status != ArtifactStatus.Exists) revert ArtifactNotFound();
        return artifacts[_artifactId];
    }
    
    /**
     * @dev Returns an array of all Artifact IDs owned by a specific user.
     * @param _user The address of the user.
     * @return An array of Artifact IDs.
     */
    function getUserArtifacts(address _user) public view returns (uint256[] memory) {
        return ownerArtifacts[_user];
    }

    /**
     * @dev Returns the total number of Artifacts that have been minted (including burned ones, but their status will be 'Burned').
     * @return The total number of artifacts.
     */
    function getTotalArtifacts() public view returns (uint256) {
        return _artifactIds.current();
    }

    // Simplified for this example, would use a proper ERC721 `isApprovedForAll` for a full NFT implementation
    function isApprovedForAll(address _owner, address _operator) internal pure returns (bool) {
        // For simplicity, only owner can transfer. Extend with a proper approval system if needed.
        return _owner == _operator;
    }


    // --- IV. Chrono-Quests System ---

    /**
     * @dev Proposes a new Chrono-Quest. Requires sufficient CP and a token bond.
     * @param _description A description of the quest.
     * @param _rewardAmount The amount of tokens to reward if the quest succeeds.
     * @param _votingDurationDays The duration in days for voting on the quest.
     * @param _executionDurationDays The duration in days for quest execution/oracle verification after voting ends.
     */
    function proposeChronoQuest(
        string memory _description,
        uint256 _rewardAmount,
        uint256 _votingDurationDays,
        uint256 _executionDurationDays
    ) external nonReentrant whenNotPaused {
        if (getChronoPower(msg.sender) < questProposalCP) {
            revert NotEnoughChronoPower(questProposalCP, getChronoPower(msg.sender));
        }
        if (_rewardAmount == 0) revert InvalidAmount();
        if (questProposalBond == 0) revert QuestBondRequired(0); // Make sure bond is set
        if (_votingDurationDays == 0 || _executionDurationDays == 0) revert InvalidDuration();

        // Transfer the bond from the proposer
        forgeToken.transferFrom(msg.sender, address(this), questProposalBond);

        _questIds.increment();
        uint256 newQuestId = _questIds.current();

        chronoQuests[newQuestId] = ChronoQuest({
            id: newQuestId,
            proposer: msg.sender,
            description: _description,
            rewardAmount: _rewardAmount,
            bondAmount: questProposalBond,
            votingDeadline: block.timestamp + (_votingDurationDays * 1 days),
            executionDeadline: 0, // Set after voting for flexibility
            hasVoted: new mapping(address => bool)(),
            yesVotes: 0,
            noVotes: 0,
            oracleVerifiedSuccess: false,
            oracleProofDetails: "",
            status: QuestStatus.Proposed
        });

        emit ChronoQuestProposed(msg.sender, newQuestId, _description, _rewardAmount, chronoQuests[newQuestId].votingDeadline, _executionDurationDays);
        emit ChronoQuestStatusChanged(newQuestId, QuestStatus.Proposed, QuestStatus.Voting);
    }

    /**
     * @dev Allows CP holders to vote on a Chrono-Quest proposal.
     * @param _questId The ID of the quest to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnChronoQuest(uint256 _questId, bool _support) external whenNotPaused {
        ChronoQuest storage quest = chronoQuests[_questId];
        if (quest.status != QuestStatus.Proposed && quest.status != QuestStatus.Voting) revert InvalidQuestStatus();
        if (quest.proposer == msg.sender) revert CannotVoteOnOwnProposal(); // Proposer cannot vote on own quest

        uint256 userCP = getChronoPower(msg.sender);
        if (userCP == 0) revert NotEnoughChronoPower(1, 0); // Must have some CP to vote
        if (quest.hasVoted[msg.sender]) revert AlreadyVoted();
        if (block.timestamp > quest.votingDeadline) {
            // If voting deadline has passed, resolve the quest
            _resolveChronoQuestProposal(_questId);
            revert VotingPeriodExpired();
        }

        quest.hasVoted[msg.sender] = true;
        if (_support) {
            quest.yesVotes += userCP; // Time-weighted vote
        } else {
            quest.noVotes += userCP; // Time-weighted vote
        }

        emit ChronoQuestVoted(msg.sender, _questId, _support, quest.yesVotes, quest.noVotes);
    }

    /**
     * @dev Proposer can cancel their own quest if it's still in 'Proposed' or 'Voting' phase and not approved/rejected.
     *      Bond is refunded.
     * @param _questId The ID of the quest to cancel.
     */
    function cancelChronoQuestProposal(uint256 _questId) external nonReentrant whenNotPaused {
        ChronoQuest storage quest = chronoQuests[_questId];
        if (quest.proposer != msg.sender) revert NotAuthorized();
        if (quest.status == QuestStatus.Approved || quest.status == QuestStatus.Rejected || quest.status == QuestStatus.Executing ||
            quest.status == QuestStatus.Success || quest.status == QuestStatus.Failed || quest.status == QuestStatus.Claimed ||
            quest.status == QuestStatus.Cancelled) {
            revert InvalidQuestStatus();
        }

        // Finalize voting if still in progress
        if (block.timestamp < quest.votingDeadline) {
            // Allow cancellation even if voting is active but before deadline
            quest.votingDeadline = block.timestamp - 1; // Effectively end voting immediately
            _resolveChronoQuestProposal(_questId);
        }

        quest.status = QuestStatus.Cancelled;
        forgeToken.transfer(quest.proposer, quest.bondAmount); // Refund bond
        emit ChronoQuestStatusChanged(_questId, quest.status, QuestStatus.Cancelled);
    }

    /**
     * @dev Internal function to resolve a quest proposal based on votes.
     *      Called by voteOnChronoQuest if deadline passed, or by anyone after deadline.
     * @param _questId The ID of the quest to resolve.
     */
    function _resolveChronoQuestProposal(uint256 _questId) internal {
        ChronoQuest storage quest = chronoQuests[_questId];
        if (quest.status != QuestStatus.Proposed && quest.status != QuestStatus.Voting) revert InvalidQuestStatus();
        if (block.timestamp < quest.votingDeadline) revert VotingPeriodNotActive();

        QuestStatus oldStatus = quest.status;
        if (quest.yesVotes > quest.noVotes) {
            quest.status = QuestStatus.Approved;
            // Set execution deadline only if approved
            quest.executionDeadline = block.timestamp + ((quest.votingDeadline - (block.timestamp - ((quest.votingDeadline - block.timestamp) / 1 days * 1 days))) / 1 days * 1 days); // This is complex, just add default days
            quest.executionDeadline = block.timestamp + 30 * 1 days; // Example: 30 days for execution
        } else {
            quest.status = QuestStatus.Rejected;
            // Refund bond if rejected
            forgeToken.transfer(quest.proposer, quest.bondAmount);
        }
        emit ChronoQuestStatusChanged(_questId, oldStatus, quest.status);
    }


    /**
     * @dev Only the designated oracle can report the outcome of an approved quest.
     * @param _questId The ID of the quest.
     * @param _success True if the quest was successful, false otherwise.
     * @param _proofDetails Optional string for proof details.
     */
    function oracleReportQuestOutcome(uint256 _questId, bool _success, string memory _proofDetails) external onlyOracle nonReentrant whenNotPaused {
        ChronoQuest storage quest = chronoQuests[_questId];
        if (quest.status != QuestStatus.Approved && quest.status != QuestStatus.Executing) revert InvalidQuestStatus();
        if (block.timestamp > quest.executionDeadline) revert VotingPeriodExpired(); // Reusing error for execution deadline

        quest.oracleVerifiedSuccess = _success;
        quest.oracleProofDetails = _proofDetails;
        QuestStatus oldStatus = quest.status;
        quest.status = _success ? QuestStatus.Success : QuestStatus.Failed;

        emit ChronoQuestOutcomeReported(_questId, _success, _proofDetails);
        emit ChronoQuestStatusChanged(_questId, oldStatus, quest.status);

        // If failed, refund bond
        if (!success) {
            forgeToken.transfer(quest.proposer, quest.bondAmount);
        }
    }

    /**
     * @dev Allows the quest proposer to claim rewards if the quest was successful and verified.
     *      Bond is returned along with rewards.
     * @param _questId The ID of the quest.
     */
    function claimQuestReward(uint256 _questId) external nonReentrant whenNotPaused {
        ChronoQuest storage quest = chronoQuests[_questId];
        if (quest.proposer != msg.sender) revert NotAuthorized();
        if (quest.status != QuestStatus.Success) revert InvalidQuestStatus();
        if (!quest.oracleVerifiedSuccess) revert QuestOutcomeNotReported();
        if (quest.status == QuestStatus.Claimed) revert QuestAlreadyClaimed();

        quest.status = QuestStatus.Claimed;
        uint256 totalPayout = quest.rewardAmount + quest.bondAmount;
        if (forgeToken.balanceOf(address(this)) < totalPayout) {
            revert NotEnoughBalance(totalPayout, forgeToken.balanceOf(address(this)));
        }
        forgeToken.transfer(msg.sender, totalPayout);

        emit ChronoQuestRewardClaimed(_questId, msg.sender, quest.rewardAmount);
        emit ChronoQuestStatusChanged(_questId, QuestStatus.Success, QuestStatus.Claimed);
    }

    /**
     * @dev Retrieves the full details of a specific Chrono-Quest.
     * @param _questId The ID of the quest.
     * @return A `ChronoQuest` struct containing its details.
     */
    function getQuestDetails(uint256 _questId) public view returns (ChronoQuest memory) {
        if (_questId == 0 || _questId > _questIds.current()) revert QuestNotFound();
        return chronoQuests[_questId];
    }
    
    // --- V. Dynamic Protocol Parameters (Simple Governance) ---

    /**
     * @dev Proposes a change to a key contract parameter. Requires CP.
     * @param _paramName The name of the parameter to change (e.g., "forgingFeeCP", "forgingFeeTokens").
     * @param _newValue The new value for the parameter.
     * @param _votingDurationDays The duration in days for voting on this proposal.
     */
    function proposeParameterChange(
        string memory _paramName,
        uint256 _newValue,
        uint256 _votingDurationDays
    ) external whenNotPaused {
        if (getChronoPower(msg.sender) < questProposalCP) { // Reuse quest CP requirement for simplicity
            revert NotEnoughChronoPower(questProposalCP, getChronoPower(msg.sender));
        }
        if (_votingDurationDays == 0) revert InvalidDuration();
        
        // Basic check for valid parameter name
        if (keccak256(abi.encodePacked(_paramName)) != keccak256(abi.encodePacked("forgingFeeCP")) &&
            keccak256(abi.encodePacked(_paramName)) != keccak256(abi.encodePacked("forgingFeeTokens")) &&
            keccak256(abi.encodePacked(_paramName)) != keccak256(abi.encodePacked("questProposalCP")) &&
            keccak256(abi.encodePacked(_paramName)) != keccak256(abi.encodePacked("questProposalBond"))) {
            revert ParameterNotFound();
        }

        _paramProposalIds.increment();
        uint256 newProposalId = _paramProposalIds.current();

        paramProposals[newProposalId] = ParameterChangeProposal({
            id: newProposalId,
            paramName: _paramName,
            newValue: _newValue,
            proposer: msg.sender,
            votingDeadline: block.timestamp + (_votingDurationDays * 1 days),
            hasVoted: new mapping(address => bool)(),
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Proposed
        });

        emit ParameterChangeProposed(msg.sender, newProposalId, _paramName, _newValue, paramProposals[newProposalId].votingDeadline);
    }

    /**
     * @dev Allows CP holders to vote on a parameter change proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) external whenNotPaused {
        ParameterChangeProposal storage proposal = paramProposals[_proposalId];
        if (proposal.status != ProposalStatus.Proposed && proposal.status != ProposalStatus.Voting) revert ProposalAlreadyExecuted();
        if (proposal.proposer == msg.sender) revert CannotVoteOnOwnProposal();

        uint256 userCP = getChronoPower(msg.sender);
        if (userCP == 0) revert NotEnoughChronoPower(1, 0);
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();
        if (block.timestamp > proposal.votingDeadline) {
            _resolveParameterProposal(_proposalId);
            revert VotingPeriodExpired();
        }

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yesVotes += userCP;
        } else {
            proposal.noVotes += userCP;
        }

        emit ParameterChangeVoted(msg.sender, _proposalId, _support, proposal.yesVotes, proposal.noVotes);
    }
    
    /**
     * @dev Internal function to resolve a parameter change proposal based on votes.
     *      Called by voteOnParameterChange if deadline passed, or by anyone after deadline.
     * @param _proposalId The ID of the proposal to resolve.
     */
    function _resolveParameterProposal(uint256 _proposalId) internal {
        ParameterChangeProposal storage proposal = paramProposals[_proposalId];
        if (proposal.status != ProposalStatus.Proposed && proposal.status != ProposalStatus.Voting) revert ProposalAlreadyExecuted();
        if (block.timestamp < proposal.votingDeadline) revert VotingPeriodNotActive();

        ProposalStatus oldStatus = proposal.status;
        if (proposal.yesVotes > proposal.noVotes) {
            proposal.status = ProposalStatus.Approved;
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        // No event for status change, it will be handled by execute if approved.
    }


    /**
     * @dev Executes a parameter change if the proposal has passed. Any CP holder can call this after voting ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 _proposalId) external whenNotPaused {
        ParameterChangeProposal storage proposal = paramProposals[_proposalId];
        if (proposal.status == ProposalStatus.Executed) revert ProposalAlreadyExecuted();

        // Ensure voting period is over and resolve if not already
        if (block.timestamp >= proposal.votingDeadline && (proposal.status == ProposalStatus.Proposed || proposal.status == ProposalStatus.Voting)) {
            _resolveParameterProposal(_proposalId);
        }

        if (proposal.status != ProposalStatus.Approved) revert ProposalNotPassed();

        // Apply the change
        if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("forgingFeeCP"))) {
            forgingFeeCP = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("forgingFeeTokens"))) {
            forgingFeeTokens = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("questProposalCP"))) {
            questProposalCP = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.paramName)) == keccak256(abi.encodePacked("questProposalBond"))) {
            questProposalBond = proposal.newValue;
        } else {
            revert ParameterNotFound(); // Should not happen if `proposeParameterChange` filters correctly
        }

        proposal.status = ProposalStatus.Executed;
        emit ParameterChangeExecuted(_proposalId, proposal.paramName, proposal.newValue);
    }
}
```