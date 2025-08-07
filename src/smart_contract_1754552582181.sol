This smart contract, `AetherForge`, is designed as a decentralized protocol for AI-curated content, reputation management, and community governance. It introduces several advanced concepts:

*   **Soul-Bound Tokens (SBTs):** Non-transferable ERC721 tokens representing a user's `ReputationScore` and `ExperiencePoints`. These are bound to the user's address, serving as a decentralized identity and proof of on-chain activity and contribution.
*   **Dynamic Reputation Decay:** To prevent "whale stagnation" and encourage continuous engagement, a user's `ReputationScore` slowly decays over time if they remain inactive. Active participation (submissions, votes, claims) resets their activity timer.
*   **AI Oracle Integration (Mocked):** A designated `AI_ORACLE_ROLE` simulates an AI oracle that evaluates submitted creative "artifacts" (e.g., AI prompts, art ideas). This evaluation contributes to the artifact's overall score.
*   **Reputation-Weighted Curation & Governance:** Both community voting on artifacts and governance proposals are weighted by a user's `ReputationScore`, giving more influence to proven, active contributors.
*   **DAO-like Governance:** A simplified governance module allows high-reputation users to propose changes to protocol parameters or manage a `CatalystFund` treasury, with time-locked execution for security.
*   **Layered Incentives:** Users earn `ReputationScore` and `ExperiencePoints` for contributing, curating, and staying active, unlocking various protocol features and influence.

---

### Outline: AetherForge - Decentralized AI-Curated Experience & Reputation Protocol

**I. Core Identity & Soul-Bound Tokens (SBTs)**
   - Manages unique, non-transferable ERC721 tokens representing a user's `Reputation Score` (RepScore) and `Experience Points` (XP).
   - Tracks user activity timestamps for the reputation decay mechanism.

**II. Content & Artifact Management**
   - Enables users to submit creative "artifacts" (e.g., IPFS CIDs pointing to AI prompts, art concepts, or other digital creations).
   - Integrates with a mock AI Oracle (via a designated role) for an initial, objective evaluation of submitted content.
   - Stores comprehensive details of each artifact, including its author, content identifiers, submission time, and evaluation status.

**III. Community Curation & Voting**
   - Facilitates a decentralized curation process where users can cast reputation-weighted votes for or against submitted artifacts.
   - Implements a mechanism to finalize the curation phase, calculating a composite score based on both AI evaluation and community sentiment, and distributing rewards (RepScore, XP) to authors and voters.

**IV. Reputation & XP Mechanics**
   - Introduces a dynamic reputation decay system: a user's RepScore gradually diminishes if they remain inactive over time, promoting continuous engagement and contribution.
   - Allows users to claim a daily `Experience Point` bonus, further incentivizing regular interaction with the protocol.
   - Provides functions to query the current reputation decay rate, which can be adjusted via governance.

**V. Governance & Parameter Management (DAO-like)**
   - Establishes a simplified Decentralized Autonomous Organization (DAO) structure.
   - Users with a sufficient `ReputationScore` can submit on-chain proposals for protocol upgrades, parameter changes (e.g., decay rates, minimum reputation thresholds), or treasury management.
   - Implements reputation-weighted voting on these proposals, along with a time-locked execution mechanism for approved proposals, ensuring security and community consensus.

**VI. Catalyst Fund & Treasury**
   - Manages a community-governed treasury, the "Catalyst Fund," designed to support the protocol's development, fund grants for contributors, or create reward pools.
   - Allows any user to contribute Ether to this fund, which can then be disbursed via successful DAO proposals.

---

### Function Summary:

**I. Core Identity & Soul-Bound Tokens (SBTs)**
   1.  `registerProfile()`: Allows a new user to register with the protocol, minting their unique, non-transferable `ReputationSBT` and `ExperienceSBT` tokens and initializing their scores.
   2.  `getReputation(address user)`: A view function that returns the current effective `Reputation Score` of a given user, dynamically applying any due decay based on their inactivity.
   3.  `getExperience(address user)`: A view function that returns the current `Experience Points` of a given user.
   4.  `updateLastActivityTime(address user)`: An internal helper function used to update a user's last activity timestamp, which is crucial for the reputation decay calculation.

**II. Content & Artifact Management**
   5.  `submitArtifact(string memory _cid, string memory _metadataURI)`: Enables users who meet the `minReputationForSubmission` threshold to submit a new creative artifact by providing an IPFS CID and an optional metadata URI.
   6.  `requestAIEvaluation(uint256 _artifactId)`: Initiates a request for the designated AI Oracle to evaluate a specific artifact. Can be called by the artifact's author or an account with the `AI_ORACLE_ROLE`.
   7.  `fulfillAIEvaluation(uint256 _artifactId, uint256 _aiScore, string memory _aiInsights, string memory _proof)`: Callable exclusively by an account holding the `AI_ORACLE_ROLE`. This function records the AI's evaluation score and insights for an artifact, including a mock proof for conceptual verification.
   8.  `getArtifactDetails(uint256 _artifactId)`: A view function that provides all stored details about a specific artifact, including its author, content, and evaluation status.
   9.  `getArtifactCount()`: A view function that returns the total number of artifacts that have been submitted to the protocol.

**III. Community Curation & Voting**
   10. `voteOnArtifact(uint256 _artifactId, bool _isPositive)`: Allows a user to cast a vote for (positive) or against (negative) an artifact. The weight of their vote is determined by their current `Reputation Score`.
   11. `finalizeArtifactCuration(uint256 _artifactId)`: Concludes the voting phase for an artifact after a set period. It calculates a final composite score and distributes `Reputation Score` and `Experience Points` rewards to the author and participating voters.
   12. `getArtifactVoteCounts(uint256 _artifactId)`: A view function that displays the current reputation-weighted positive and negative vote totals for a specific artifact.

**IV. Reputation & XP Mechanics**
   13. `applyReputationDecay(address _user)`: A publicly callable function that triggers the reputation decay calculation for an inactive user. This incentivizes community members to help maintain the accuracy of reputation scores.
   14. `claimDailyActivityBonus()`: Allows a registered user to claim a small `Experience Point` bonus once every 24 hours, encouraging consistent engagement with the protocol.
   15. `getDecayRate()`: A view function that returns the currently configured daily reputation decay rate.

**V. Governance & Parameter Management (DAO-like)**
   16. `submitProposal(string memory _proposalURI, bytes memory _calldata, address _target, uint256 _value)`: Enables users with sufficient `Reputation Score` to submit a new governance proposal, specifying a target contract, a calldata payload, and an optional Ether value for execution.
   17. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to cast their reputation-weighted vote for or against an active governance proposal.
   18. `queueProposal(uint256 _proposalId)`: Moves a successfully voted-on proposal into a time-locked queue, making it eligible for execution after a predefined delay. Only accounts with the `GOVERNOR_ROLE` can queue proposals.
   19. `executeProposal(uint256 _proposalId)`: Executes a proposal that has successfully passed its voting period and time-locked queue. This function performs the on-chain actions defined in the proposal's calldata.
   20. `setMinimumReputationForSubmission(uint256 _newMinRep)`: A governance function (callable by `GOVERNOR_ROLE`) to update the minimum `Reputation Score` required for users to submit new artifacts.
   21. `setMinimumReputationForProposal(uint256 _newMinRep)`: A governance function (callable by `GOVERNOR_ROLE`) to update the minimum `Reputation Score` required for users to submit new governance proposals.
   22. `grantRole(bytes32 role, address account)`: An administrative function (callable by `DEFAULT_ADMIN_ROLE`) to assign specific roles (e.g., `AI_ORACLE_ROLE`, `GOVERNOR_ROLE`) to accounts.
   23. `revokeRole(bytes32 role, address account)`: An administrative function (callable by `DEFAULT_ADMIN_ROLE`) to remove specific roles from accounts.
   24. `withdrawFunds(address _recipient, uint256 _amount)`: A function intended to be called via a successful DAO proposal, allowing the `GOVERNOR_ROLE` to withdraw funds from the contract's treasury to a specified recipient.

**VI. Catalyst Fund & Treasury**
   25. `contributeToCatalystFund()`: A payable function that allows any user to send Ether to the `AetherForge` contract, contributing to its internal `Catalyst Fund` treasury.

---
### Smart Contract Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint to string for tokenURI


// Custom Soul-Bound ERC721 for Reputation Scores
contract ReputationSBT is ERC721URIStorage {
    address private _aetherForgeContract;

    constructor(address aetherForgeContract_) ERC721("AetherForge Reputation Score", "AF_REP") {
        _aetherForgeContract = aetherForgeContract_;
    }

    // Prevents direct transfers of the SBT. Only the AetherForge contract can manage these.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal view override {
        // Allow minting (from address(0)) and burning (to address(0)) by AetherForge contract
        if (from != address(0) && to != address(0)) {
            revert("ReputationSBT: Token is non-transferable");
        }
        // Only the AetherForge contract itself is authorized to mint/burn these tokens
        require(msg.sender == _aetherForgeContract, "ReputationSBT: Unauthorized caller for token operations");
    }

    // Allows the AetherForge contract to dynamically update the tokenURI to reflect current scores.
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        require(msg.sender == _aetherForgeContract, "ReputationSBT: Unauthorized caller");
        _setTokenURI(tokenId, _tokenURI);
    }
}

// Custom Soul-Bound ERC721 for Experience Points
contract ExperienceSBT is ERC721URIStorage {
    address private _aetherForgeContract;

    constructor(address aetherForgeContract_) ERC721("AetherForge Experience Points", "AF_XP") {
        _aetherForgeContract = aetherForgeContract_;
    }

    // Prevents direct transfers of the SBT. Only the AetherForge contract can manage these.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal view override {
        // Allow minting (from address(0)) and burning (to address(0)) by AetherForge contract
        if (from != address(0) && to != address(0)) {
            revert("ExperienceSBT: Token is non-transferable");
        }
        // Only the AetherForge contract itself is authorized to mint/burn these tokens
        require(msg.sender == _aetherForgeContract, "ExperienceSBT: Unauthorized caller for token operations");
    }

    // Allows the AetherForge contract to dynamically update the tokenURI to reflect current scores.
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        require(msg.sender == _aetherForgeContract, "ExperienceSBT: Unauthorized caller");
        _setTokenURI(tokenId, _tokenURI);
    }
}


contract AetherForge is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Roles ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE"); // Manages all other roles
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE");       // Authorized to fulfill AI evaluations
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");         // Can queue/execute proposals & manage core parameters

    // --- SBT Contract Instances ---
    ReputationSBT public reputationSBT;
    ExperienceSBT public experienceSBT;

    // --- User Data Mappings ---
    // Maps user address to their unique SBT tokenId for quick lookup.
    mapping(address => uint256) private sbtTokenIdReputation;
    mapping(address => uint256) private sbtTokenIdExperience;
    // Stores the actual, mutable scores (SBT tokenURI is updated conceptually).
    mapping(address => uint256) public userReputationScore;
    mapping(address => uint256) public userExperiencePoints;
    // Tracks user's last significant interaction time for decay calculations.
    mapping(address => uint256) public lastActivityTime;
    // Tracks the last time a user claimed their daily XP bonus.
    mapping(address => uint256) public lastDailyBonusClaim;

    // --- Artifacts Structure & Storage ---
    struct Artifact {
        address author;
        string cid;             // IPFS Content ID for the artifact's core data
        string metadataURI;     // URI for additional, descriptive metadata
        uint256 submissionTime;
        bool isAIEvaluated;     // True if AI evaluation has been completed
        uint256 aiScore;        // AI's evaluation score (e.g., 0-1000 scale)
        string aiInsights;      // Textual insights or reasoning from the AI
        bool isFinalized;       // True if community curation is complete
        uint256 positiveVotes;  // Sum of reputation-weighted positive votes
        uint256 negativeVotes;  // Sum of reputation-weighted negative votes
        EnumerableSet.AddressSet voters; // Set of unique addresses that have voted on this artifact
    }
    Counters.Counter private _artifactIds; // Counter for assigning unique artifact IDs
    mapping(uint256 => Artifact) public artifacts; // Stores all submitted artifacts by ID

    // --- DAO Proposals Structure & Storage ---
    struct Proposal {
        uint256 id;
        string proposalURI;     // URI for detailed proposal text (e.g., IPFS)
        bytes calldataPayload;  // The calldata to execute if the proposal passes
        address targetAddress;  // The target contract address for the execution
        uint256 value;          // Ether value to send with the execution call
        uint256 submissionTime;
        uint256 votesFor;       // Sum of reputation-weighted votes FOR the proposal
        uint256 votesAgainst;   // Sum of reputation-weighted votes AGAINST the proposal
        bool executed;          // True if the proposal has been executed
        bool queued;            // True if the proposal is queued for timelock execution
        EnumerableSet.AddressSet voters; // Set of unique addresses that have voted on this proposal
        uint256 eta;            // Estimated time of arrival (execution time) after timelock
    }
    Counters.Counter private _proposalIds; // Counter for assigning unique proposal IDs
    mapping(uint256 => Proposal) public proposals; // Stores all governance proposals by ID
    mapping(address => mapping(uint256 => bool)) public hasVotedOnProposal; // Tracks if a user has voted on a specific proposal

    // --- Configurable Parameters (Governance-controlled) ---
    uint256 public minReputationForSubmission;  // Minimum reputation required to submit an artifact
    uint256 public minReputationForProposal;    // Minimum reputation required to submit a governance proposal
    uint256 public reputationDecayRatePerDay;   // Amount of reputation points decayed per day of inactivity
    uint256 public dailyActivityBonusXP;        // XP granted for claiming daily bonus
    uint256 public initialReputation;           // Starting reputation score for new profiles
    uint256 public initialExperience;           // Starting experience points for new profiles
    uint256 public artifactVotingPeriod;        // Duration in seconds for artifact voting
    uint256 public proposalVotingPeriod;        // Duration in seconds for governance proposal voting
    uint256 public proposalExecutionTimelock;   // Delay in seconds before a successful proposal can be executed

    // --- Events for off-chain monitoring ---
    event ProfileRegistered(address indexed user, uint256 repTokenId, uint256 xpTokenId);
    event ArtifactSubmitted(uint256 indexed artifactId, address indexed author, string cid, string metadataURI);
    event AIEvaluationRequested(uint256 indexed artifactId, address requester);
    event AIEvaluationFulfilled(uint256 indexed artifactId, uint256 aiScore, string aiInsights);
    event ArtifactVoted(uint256 indexed artifactId, address indexed voter, bool isPositive, uint256 voteWeight);
    event ArtifactCurationFinalized(uint256 indexed artifactId, address indexed author, int256 finalScore, uint256 authorReputationReward, uint256 authorXPReward);
    event ReputationDecayed(address indexed user, uint256 oldReputation, uint256 newReputation);
    event DailyBonusClaimed(address indexed user, uint256 xpGained);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string proposalURI);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalQueued(uint256 indexed proposalId, uint256 eta);
    event ProposalExecuted(uint256 indexed proposalId);
    event CatalystFundContributed(address indexed contributor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    constructor(
        uint256 _initialReputation,
        uint256 _initialExperience,
        uint256 _minRepForSubmission,
        uint256 _minRepForProposal,
        uint256 _reputationDecayRatePerDay,
        uint256 _dailyActivityBonusXP,
        uint256 _artifactVotingPeriod,
        uint256 _proposalVotingPeriod,
        uint256 _proposalExecutionTimelock
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is the initial admin
        _grantRole(GOVERNOR_ROLE, msg.sender);      // Deployer is also initial governor

        // Deploy and link SBT contracts, passing 'this' contract's address for authorization
        reputationSBT = new ReputationSBT(address(this));
        experienceSBT = new ExperienceSBT(address(this));

        // Set initial configurable parameters
        initialReputation = _initialReputation;
        initialExperience = _initialExperience;
        minReputationForSubmission = _minRepForSubmission;
        minReputationForProposal = _minRepForProposal;
        reputationDecayRatePerDay = _reputationDecayRatePerDay;
        dailyActivityBonusXP = _dailyActivityBonusXP;
        artifactVotingPeriod = _artifactVotingPeriod;
        proposalVotingPeriod = _proposalVotingPeriod;
        proposalExecutionTimelock = _proposalExecutionTimelock;
    }

    // Fallback function to allow direct ETH contributions to the Catalyst Fund
    receive() external payable {
        emit CatalystFundContributed(msg.sender, msg.value);
    }

    // --- I. Core Identity & Soul-Bound Tokens (SBTs) ---

    /// @notice Registers a new user profile by minting their non-transferable Reputation and Experience SBTs.
    /// @dev A user can only register once. Initializes scores and activity time.
    function registerProfile() external {
        require(sbtTokenIdReputation[msg.sender] == 0, "AetherForge: Profile already registered");

        // Mint Reputation SBT
        uint256 repTokenId = reputationSBT.totalSupply().add(1);
        reputationSBT.mint(msg.sender, repTokenId);
        sbtTokenIdReputation[msg.sender] = repTokenId;
        userReputationScore[msg.sender] = initialReputation;
        reputationSBT.setTokenURI(repTokenId, string(abi.encodePacked("ipfs://aetherforge_rep_sbt/", Strings.toString(initialReputation))));

        // Mint Experience SBT
        uint256 xpTokenId = experienceSBT.totalSupply().add(1);
        experienceSBT.mint(msg.sender, xpTokenId);
        sbtTokenIdExperience[msg.sender] = xpTokenId;
        userExperiencePoints[msg.sender] = initialExperience;
        experienceSBT.setTokenURI(xpTokenId, string(abi.encodePacked("ipfs://aetherforge_xp_sbt/", Strings.toString(initialExperience))));

        updateLastActivityTime(msg.sender); // Record initial activity
        emit ProfileRegistered(msg.sender, repTokenId, xpTokenId);
    }

    /// @notice Retrieves the current, effective reputation score for a user.
    /// @dev Applies reputation decay calculation for inactivity without modifying state.
    /// @param user The address of the user.
    /// @return The user's current reputation score.
    function getReputation(address user) public view returns (uint256) {
        if (sbtTokenIdReputation[user] == 0) return 0; // Not a registered user

        uint256 currentRep = userReputationScore[user];
        uint256 lastActive = lastActivityTime[user];

        if (lastActive == 0) return currentRep; // Should not happen for registered users, but as a safeguard

        uint256 timeElapsed = block.timestamp.sub(lastActive);
        uint256 daysElapsed = timeElapsed.div(1 days);

        if (daysElapsed > 0) {
            uint256 decayAmount = daysElapsed.mul(reputationDecayRatePerDay);
            return currentRep > decayAmount ? currentRep.sub(decayAmount) : 0;
        }
        return currentRep;
    }

    /// @notice Retrieves the current experience points for a user.
    /// @param user The address of the user.
    /// @return The user's current experience points.
    function getExperience(address user) public view returns (uint256) {
        return userExperiencePoints[user];
    }

    /// @dev Internal helper function to update a user's last activity timestamp.
    ///      Crucially, it applies any pending reputation decay before updating the timestamp.
    /// @param user The address of the user whose activity time is being updated.
    function updateLastActivityTime(address user) internal {
        // Apply decay first, then update the activity timestamp
        _applyReputationDecayInternal(user);
        lastActivityTime[user] = block.timestamp;
    }

    /// @dev Internal function to safely update a user's reputation score.
    /// @param user The address of the user.
    /// @param delta The amount to change reputation by (can be negative).
    function _updateReputation(address user, int256 delta) internal {
        require(sbtTokenIdReputation[user] != 0, "AetherForge: User not registered to update reputation.");

        uint256 currentRep = userReputationScore[user];
        if (delta > 0) {
            userReputationScore[user] = currentRep.add(uint256(delta));
        } else {
            userReputationScore[user] = currentRep > uint256(-delta) ? currentRep.sub(uint256(-delta)) : 0;
        }
        // Update SBT tokenURI (conceptually, in a real dApp, this might trigger a dynamic URI service)
        reputationSBT.setTokenURI(sbtTokenIdReputation[user], string(abi.encodePacked("ipfs://aetherforge_rep_sbt/", Strings.toString(userReputationScore[user]))));
        updateLastActivityTime(user);
    }

    /// @dev Internal function to safely update a user's experience points.
    /// @param user The address of the user.
    /// @param delta The amount to add to XP.
    function _updateExperience(address user, uint256 delta) internal {
        require(sbtTokenIdExperience[user] != 0, "AetherForge: User not registered to update experience.");

        userExperiencePoints[user] = userExperiencePoints[user].add(delta);
        // Update SBT tokenURI (conceptually)
        experienceSBT.setTokenURI(sbtTokenIdExperience[user], string(abi.encodePacked("ipfs://aetherforge_xp_sbt/", Strings.toString(userExperiencePoints[user]))));
        updateLastActivityTime(user);
    }

    // --- II. Content & Artifact Management ---

    /// @notice Allows a user to submit a new creative artifact to the protocol.
    /// @dev Requires the submitting user to have a minimum reputation score.
    /// @param _cid The IPFS Content ID pointing to the artifact's primary data.
    /// @param _metadataURI A URI pointing to additional metadata (e.g., JSON schema, description).
    function submitArtifact(string memory _cid, string memory _metadataURI) external {
        require(sbtTokenIdReputation[msg.sender] != 0, "AetherForge: User not registered.");
        require(getReputation(msg.sender) >= minReputationForSubmission, "AetherForge: Insufficient reputation to submit artifact.");

        _artifactIds.increment();
        uint256 newId = _artifactIds.current();
        artifacts[newId] = Artifact({
            author: msg.sender,
            cid: _cid,
            metadataURI: _metadataURI,
            submissionTime: block.timestamp,
            isAIEvaluated: false,
            aiScore: 0,
            aiInsights: "",
            isFinalized: false,
            positiveVotes: 0,
            negativeVotes: 0,
            voters: EnumerableSet.AddressSet(0)
        });
        updateLastActivityTime(msg.sender);
        emit ArtifactSubmitted(newId, msg.sender, _cid, _metadataURI);
    }

    /// @notice Initiates a request for AI evaluation for a specific artifact.
    /// @dev Can be called by the artifact's author or an authorized AI_ORACLE_ROLE.
    /// @param _artifactId The ID of the artifact to be evaluated.
    function requestAIEvaluation(uint256 _artifactId) external {
        require(_artifactId <= _artifactIds.current() && _artifactId > 0, "AetherForge: Invalid artifact ID.");
        require(artifacts[_artifactId].author == msg.sender || hasRole(AI_ORACLE_ROLE, msg.sender), "AetherForge: Not authorized to request AI evaluation.");
        require(!artifacts[_artifactId].isAIEvaluated, "AetherForge: Artifact already AI evaluated.");

        // In a real scenario, this would likely dispatch a request to a Chainlink Oracle network
        // for off-chain AI computation. For this contract, it merely logs the request.
        updateLastActivityTime(msg.sender);
        emit AIEvaluationRequested(_artifactId, msg.sender);
    }

    /// @notice Callable by the AI Oracle to fulfill an AI evaluation request.
    /// @dev Only accounts with the `AI_ORACLE_ROLE` can call this.
    /// @param _artifactId The ID of the artifact that was evaluated.
    /// @param _aiScore The AI's numerical evaluation score (0-1000).
    /// @param _aiInsights Textual insights or reasoning provided by the AI.
    /// @param _proof A mock parameter for conceptual proof verification (e.g., ZK proof, signed message).
    function fulfillAIEvaluation(uint256 _artifactId, uint256 _aiScore, string memory _aiInsights, string memory _proof) external onlyRole(AI_ORACLE_ROLE) {
        require(_artifactId <= _artifactIds.current() && _artifactId > 0, "AetherForge: Invalid artifact ID.");
        require(!artifacts[_artifactId].isAIEvaluated, "AetherForge: Artifact already AI evaluated.");
        require(_aiScore <= 1000, "AetherForge: AI Score must be <= 1000."); // Example score range validation
        require(bytes(_proof).length > 0, "AetherForge: AI proof cannot be empty."); // Mock verification

        Artifact storage artifact = artifacts[_artifactId];
        artifact.isAIEvaluated = true;
        artifact.aiScore = _aiScore;
        artifact.aiInsights = _aiInsights;

        // Optionally, initial XP grant to author for getting AI evaluation (e.g., small bonus for valid submissions)
        // _updateExperience(artifact.author, _aiScore.div(10));
        updateLastActivityTime(artifact.author); // Author gets activity credit for AI eval
        emit AIEvaluationFulfilled(_artifactId, _aiScore, _aiInsights);
    }

    /// @notice Retrieves the full details of a specific artifact.
    /// @param _artifactId The ID of the artifact.
    /// @return A struct containing all artifact details.
    function getArtifactDetails(uint256 _artifactId) public view returns (Artifact memory) {
        require(_artifactId <= _artifactIds.current() && _artifactId > 0, "AetherForge: Invalid artifact ID.");
        return artifacts[_artifactId];
    }

    /// @notice Returns the total count of artifacts submitted to the protocol.
    /// @return The total number of artifacts.
    function getArtifactCount() public view returns (uint256) {
        return _artifactIds.current();
    }

    // --- III. Community Curation & Voting ---

    /// @notice Allows a registered user to cast a reputation-weighted vote on an artifact.
    /// @dev A user can only vote once per artifact. Vote weight is based on current reputation.
    /// @param _artifactId The ID of the artifact to vote on.
    /// @param _isPositive True for a positive vote, false for a negative vote.
    function voteOnArtifact(uint256 _artifactId, bool _isPositive) external {
        require(sbtTokenIdReputation[msg.sender] != 0, "AetherForge: User not registered.");
        require(_artifactId <= _artifactIds.current() && _artifactId > 0, "AetherForge: Invalid artifact ID.");
        Artifact storage artifact = artifacts[_artifactId];
        require(!artifact.isFinalized, "AetherForge: Voting for this artifact is closed.");
        
        uint256 voterReputation = getReputation(msg.sender);
        require(voterReputation > 0, "AetherForge: Voter must have a positive reputation.");
        require(artifact.voters.add(msg.sender), "AetherForge: Already voted on this artifact."); // Adds voter to unique set, reverts if already present

        if (_isPositive) {
            artifact.positiveVotes = artifact.positiveVotes.add(voterReputation);
        } else {
            artifact.negativeVotes = artifact.negativeVotes.add(voterReputation);
        }
        updateLastActivityTime(msg.sender);
        emit ArtifactVoted(_artifactId, msg.sender, _isPositive, voterReputation);
    }

    /// @notice Finalizes the community curation process for a specific artifact.
    /// @dev Calculates a final score based on AI evaluation and community votes, then distributes rewards.
    /// @param _artifactId The ID of the artifact to finalize.
    function finalizeArtifactCuration(uint256 _artifactId) external nonReentrant {
        require(_artifactId <= _artifactIds.current() && _artifactId > 0, "AetherForge: Invalid artifact ID.");
        Artifact storage artifact = artifacts[_artifactId];
        require(!artifact.isFinalized, "AetherForge: Artifact already finalized.");
        require(artifact.isAIEvaluated, "AetherForge: Artifact must be AI evaluated first.");
        require(block.timestamp >= artifact.submissionTime.add(artifactVotingPeriod), "AetherForge: Voting period not over yet.");
        require(artifact.voters.length() >= 3, "AetherForge: Not enough unique voters to finalize (min 3 required)."); // Ensures some level of decentralization

        artifact.isFinalized = true;

        // Calculate community sentiment score (0-1000 scale)
        int256 totalCommunityVotes = int256(artifact.positiveVotes.add(artifact.negativeVotes));
        int256 communityScore = 0;
        if (totalCommunityVotes > 0) {
            communityScore = int256(artifact.positiveVotes).mul(1000).div(totalCommunityVotes);
        }

        // Combine AI score and community score with predefined weights (e.g., 30% AI, 70% community)
        int256 finalScore = (int256(artifact.aiScore).mul(3)).add(communityScore.mul(7)).div(10);

        uint256 authorRepReward = 0;
        uint256 authorXPReward = 0;

        // Reward logic based on final score
        if (finalScore >= 750) { // Excellent
            authorRepReward = 75;
            authorXPReward = 300;
        } else if (finalScore >= 600) { // Good
            authorRepReward = 30;
            authorXPReward = 150;
        } else if (finalScore >= 400) { // Average
            authorRepReward = 10;
            authorXPReward = 50;
        } else { // Below average
            // Optional: Implement a reputation penalty for very low scores
            // if (finalScore < 200) _updateReputation(artifact.author, -50);
            authorRepReward = 0; // No reputation reward for low scores
            authorXPReward = 20; // Small XP for participation
        }

        _updateReputation(artifact.author, int256(authorRepReward));
        _updateExperience(artifact.author, authorXPReward);

        // Reward all unique voters for participation
        address[] memory uniqueVoters = artifact.voters.values();
        for (uint256 i = 0; i < uniqueVoters.length; i++) {
             _updateExperience(uniqueVoters[i], 10); // Small XP for participation in curation
        }

        updateLastActivityTime(msg.sender); // The finalizer gets activity credit
        emit ArtifactCurationFinalized(_artifactId, artifact.author, finalScore, authorRepReward, authorXPReward);
    }

    /// @notice Displays the current reputation-weighted positive and negative vote totals for an artifact.
    /// @param _artifactId The ID of the artifact.
    /// @return posVotes The total positive vote weight.
    /// @return negVotes The total negative vote weight.
    function getArtifactVoteCounts(uint256 _artifactId) public view returns (uint256 posVotes, uint256 negVotes) {
        require(_artifactId <= _artifactIds.current() && _artifactId > 0, "AetherForge: Invalid artifact ID.");
        Artifact storage artifact = artifacts[_artifactId];
        return (artifact.positiveVotes, artifact.negativeVotes);
    }

    // --- IV. Reputation & XP Mechanics ---

    /// @dev Internal function to apply reputation decay based on inactivity.
    ///      This function directly modifies the `userReputationScore` state.
    /// @param _user The address of the user whose reputation might decay.
    function _applyReputationDecayInternal(address _user) internal {
        if (sbtTokenIdReputation[_user] == 0) return; // Not a registered user

        uint256 currentRep = userReputationScore[_user];
        uint256 lastActive = lastActivityTime[_user];

        if (lastActive == 0) return; // Should not happen for registered users, if so, no decay applied.

        uint256 timeElapsed = block.timestamp.sub(lastActive);
        uint256 daysElapsed = timeElapsed.div(1 days);

        if (daysElapsed > 0) {
            uint256 decayAmount = daysElapsed.mul(reputationDecayRatePerDay);
            uint256 newRep = currentRep > decayAmount ? currentRep.sub(decayAmount) : 0;
            if (newRep != currentRep) {
                userReputationScore[_user] = newRep;
                reputationSBT.setTokenURI(sbtTokenIdReputation[_user], string(abi.encodePacked("ipfs://aetherforge_rep_sbt/", Strings.toString(newRep))));
                emit ReputationDecayed(_user, currentRep, newRep);
            }
        }
    }

    /// @notice Allows any user to trigger the reputation decay calculation for a specified user.
    /// @dev This can be incentivized in a more complex system (e.g., small ETH reward for gas).
    /// @param _user The address of the user for whom to apply decay.
    function applyReputationDecay(address _user) external nonReentrant {
        require(sbtTokenIdReputation[_user] != 0, "AetherForge: User not registered.");
        _applyReputationDecayInternal(_user);
        updateLastActivityTime(msg.sender); // Caller gets activity credit
    }

    /// @notice Allows a registered user to claim a small daily Experience Points bonus.
    /// @dev Can only be claimed once every 24 hours.
    function claimDailyActivityBonus() external {
        require(sbtTokenIdExperience[msg.sender] != 0, "AetherForge: User not registered.");
        require(block.timestamp >= lastDailyBonusClaim[msg.sender].add(1 days), "AetherForge: Can only claim once per day.");

        _updateExperience(msg.sender, dailyActivityBonusXP);
        lastDailyBonusClaim[msg.sender] = block.timestamp;
        updateLastActivityTime(msg.sender);
        emit DailyBonusClaimed(msg.sender, dailyActivityBonusXP);
    }

    /// @notice Returns the currently configured daily reputation decay rate.
    /// @return The reputation decay rate per day.
    function getDecayRate() public view returns (uint256) {
        return reputationDecayRatePerDay;
    }

    // --- V. Governance & Parameter Management (DAO-like) ---

    /// @notice Allows users with sufficient reputation to submit a new governance proposal.
    /// @param _proposalURI URI pointing to detailed proposal text (e.g., IPFS).
    /// @param _calldata The `calldata` to execute if the proposal passes.
    /// @param _target The target contract address for the execution.
    /// @param _value The Ether value to send with the execution call.
    function submitProposal(string memory _proposalURI, bytes memory _calldata, address _target, uint256 _value) external {
        require(sbtTokenIdReputation[msg.sender] != 0, "AetherForge: User not registered.");
        require(getReputation(msg.sender) >= minReputationForProposal, "AetherForge: Insufficient reputation to submit proposal.");
        require(_target != address(0), "AetherForge: Target address cannot be zero.");

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        proposals[newId] = Proposal({
            id: newId,
            proposalURI: _proposalURI,
            calldataPayload: _calldata,
            targetAddress: _target,
            value: _value,
            submissionTime: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            queued: false,
            voters: EnumerableSet.AddressSet(0), // Initialize empty set
            eta: 0
        });
        updateLastActivityTime(msg.sender);
        emit ProposalSubmitted(newId, msg.sender, _proposalURI);
    }

    /// @notice Allows registered users to cast their reputation-weighted vote on an active proposal.
    /// @dev A user can only vote once per proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote for the proposal, false to vote against.
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        require(sbtTokenIdReputation[msg.sender] != 0, "AetherForge: User not registered.");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime > 0, "AetherForge: Invalid proposal ID.");
        require(block.timestamp < proposal.submissionTime.add(proposalVotingPeriod), "AetherForge: Voting period for this proposal has ended.");
        require(hasVotedOnProposal[msg.sender][_proposalId] == false, "AetherForge: Already voted on this proposal.");
        require(!proposal.executed, "AetherForge: Proposal already executed.");
        
        uint256 voterReputation = getReputation(msg.sender);
        require(voterReputation > 0, "AetherForge: Voter must have a positive reputation.");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterReputation);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterReputation);
        }
        proposal.voters.add(msg.sender); // Add to set of unique voters
        hasVotedOnProposal[msg.sender][_proposalId] = true;
        updateLastActivityTime(msg.sender);
        emit ProposalVoted(_proposalId, msg.sender, _support, voterReputation);
    }

    /// @notice Queues a successful proposal for execution after a timelock period.
    /// @dev Only accounts with the `GOVERNOR_ROLE` can queue proposals. Requires voting period to be over and proposal to pass.
    /// @param _proposalId The ID of the proposal to queue.
    function queueProposal(uint256 _proposalId) external onlyRole(GOVERNOR_ROLE) nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime > 0, "AetherForge: Invalid proposal ID.");
        require(block.timestamp >= proposal.submissionTime.add(proposalVotingPeriod), "AetherForge: Voting period not over yet.");
        require(!proposal.executed, "AetherForge: Proposal already executed.");
        require(!proposal.queued, "AetherForge: Proposal already queued.");
        
        // Simple majority check: Votes For must strictly exceed Votes Against
        // In a more complex DAO, a quorum (e.g., min % of total circulating reputation) would be checked.
        require(proposal.votesFor > proposal.votesAgainst, "AetherForge: Proposal did not pass majority vote.");

        proposal.queued = true;
        proposal.eta = block.timestamp.add(proposalExecutionTimelock);
        emit ProposalQueued(_proposalId, proposal.eta);
    }

    /// @notice Executes a successfully voted-on and time-locked proposal.
    /// @dev Can be called by anyone once the timelock has expired.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external payable nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.queued, "AetherForge: Proposal not queued.");
        require(!proposal.executed, "AetherForge: Proposal already executed.");
        require(block.timestamp >= proposal.eta, "AetherForge: Timelock not expired.");

        proposal.executed = true;

        // Execute the call to the target address with the specified calldata and value
        (bool success, ) = proposal.targetAddress.call{value: proposal.value}(proposal.calldataPayload);
        require(success, "AetherForge: Proposal execution failed.");

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows the `GOVERNOR_ROLE` to set the minimum reputation required for artifact submission.
    /// @param _newMinRep The new minimum reputation score.
    function setMinimumReputationForSubmission(uint256 _newMinRep) external onlyRole(GOVERNOR_ROLE) {
        minReputationForSubmission = _newMinRep;
    }

    /// @notice Allows the `GOVERNOR_ROLE` to set the minimum reputation required for proposal submission.
    /// @param _newMinRep The new minimum reputation score.
    function setMinimumReputationForProposal(uint256 _newMinRep) external onlyRole(GOVERNOR_ROLE) {
        minReputationForProposal = _newMinRep;
    }

    /// @notice Grants a specified role to an account.
    /// @dev Only accounts with the `DEFAULT_ADMIN_ROLE` can call this.
    /// @param role The role hash to grant.
    /// @param account The address to grant the role to.
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.grantRole(role, account);
    }

    /// @notice Revokes a specified role from an account.
    /// @dev Only accounts with the `DEFAULT_ADMIN_ROLE` can call this.
    /// @param role The role hash to revoke.
    /// @param account The address to revoke the role from.
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.revokeRole(role, account);
    }

    /// @notice Allows a successful DAO proposal to withdraw funds from the contract treasury.
    /// @dev This function is intended to be called by the `executeProposal` function via `calldataPayload`.
    ///      Direct calls are restricted to the `GOVERNOR_ROLE` for initial setup or emergency.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of Ether to withdraw.
    function withdrawFunds(address _recipient, uint256 _amount) external nonReentrant {
        // This function is designed to be called by `executeProposal` after a DAO vote.
        // It's secured by `onlyRole(GOVERNOR_ROLE)` because the `GOVERNOR_ROLE` itself would be controlled
        // by the DAO's proposal/timelock mechanism in a complete implementation.
        require(hasRole(GOVERNOR_ROLE, msg.sender), "AetherForge: Only DAO-controlled Governor can withdraw funds.");
        require(address(this).balance >= _amount, "AetherForge: Insufficient balance in Catalyst Fund.");
        require(_recipient != address(0), "AetherForge: Recipient cannot be zero address.");
        
        payable(_recipient).transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    // --- VI. Catalyst Fund & Treasury ---

    /// @notice Allows any user to contribute Ether to the protocol's Catalyst Fund.
    /// @dev Received Ether is held in the contract's balance and can be disbursed via DAO proposals.
    function contributeToCatalystFund() external payable {
        require(msg.value > 0, "AetherForge: Must send positive ETH to contribute.");
        emit CatalystFundContributed(msg.sender, msg.value);
    }
}
```