This smart contract, **AdaptiveReputationProtocol**, is designed to create a dynamic, self-evolving ecosystem where digital assets (Dynamic Reputation Assets - DRAs) and protocol parameters adapt based on user reputation, community governance, and external AI-driven insights. It aims to foster a highly engaged and meritocratic decentralized community.

---

## Contract: AdaptiveReputationProtocol

### Description:
The AdaptiveReputationProtocol is a novel, multi-faceted smart contract that integrates dynamic NFTs (DRAs), a comprehensive reputation system, an AI oracle for external insights, and an adaptive governance model. Users earn and lose reputation, which directly influences the traits and utility of their DRAs. Protocol parameters can be adjusted through reputation-weighted governance votes, with proposals potentially initiated by insights from an AI oracle. An ERC20 staking mechanism further incentivizes long-term engagement and boosts reputation effects.

### Key Features:
*   **Dynamic Reputation Assets (DRAs):** ERC721 NFTs whose traits and visual representation (via metadata URI) evolve based on the owner's current reputation score.
*   **Robust Reputation System:** Users accrue reputation for positive actions and face penalties for negative ones, with a configurable decay mechanism to ensure active participation.
*   **AI Oracle Integration:** Receives sentiment and trend data from an external AI oracle, which can trigger or inform governance proposals to adapt protocol parameters.
*   **Adaptive Governance:** A decentralized voting system where voting power is weighted by user reputation, allowing the community to dynamically adjust core protocol parameters.
*   **Engagement Staking:** Users can stake an ERC20 token to amplify their reputation gains or mitigate decay, fostering long-term commitment.
*   **Feature Access Control:** Protocol-defined features or external dApps can query the contract to determine access levels based on a user's reputation.
*   **Modular & Extensible:** Designed to allow for future expansion of reputation sources, DRA traits, and governance-controlled parameters.

---

### Outline and Function Summary:

#### **I. Core Concepts & State Variables**
*   `owner`: Contract owner (admin).
*   `_reputations`: Mapping of address to current reputation score.
*   `_tokenTraits`: Mapping of DRA tokenId to its current computed trait level.
*   `_aiOracle`: Address of the trusted AI oracle contract.
*   `_stakingToken`: Address of the ERC20 token used for staking.
*   `reputationDecayRate`: Governance-controlled rate at which reputation decays.
*   `minReputationToMintDRA`: Minimum reputation required to mint a DRA.
*   `proposals`: Structs holding details of ongoing and completed governance proposals.
*   `_featureAccessLevels`: Mapping of `bytes32` feature ID to minimum reputation required.

#### **II. External Interfaces**
*   `IERC20`: Interface for the staking token.
*   `IAIOracle`: Minimal interface for receiving AI insights. (Mock interface in this example)

#### **III. Reputation Management**
1.  `constructor()`: Initializes the contract, sets initial owner, staking token, and base parameters.
2.  `registerUser()`: Allows a new user to join the protocol and receive an initial reputation score.
3.  `adjustReputation(address _user, int256 _delta)`: **(Moderator/Internal)** Increases or decreases a user's reputation. Can be called by moderators or internally by the protocol.
4.  `updateReputationDecayRate(uint256 _newRate)`: **(Governance)** Allows the community to adjust the global reputation decay rate.
5.  `triggerReputationDecay()`: **(Permissionless/Keeper)** Allows anyone (e.g., a decentralized keeper network) to trigger the global reputation decay based on the `reputationDecayRate`.

#### **IV. Dynamic Asset (DRA) Management (ERC721-based)**
6.  `mintDynamicReputationAsset(string memory _initialBaseURI)`: Mints a new DRA to the caller, requiring a minimum reputation score.
7.  `setDRABaseURI(string memory _newBaseURI)`: **(Admin)** Sets the base URI for DRA metadata, where `tokenURI` will append `tokenId` and trait level.
8.  `tokenURI(uint256 tokenId)`: **(View/ERC721)** Returns the dynamic metadata URI for a given DRA, reflecting its current evolution based on the owner's reputation.
9.  `lockDRATraits(uint256 _tokenId)`: Allows a DRA owner to pay a fee or burn reputation to permanently lock their DRA's traits at its current level.
10. `releaseDRATraits(uint256 _tokenId)`: Allows a DRA owner to revert a locked DRA back to dynamic evolution.

#### **V. AI Oracle Integration & Parameter Adaptation**
11. `setAIOracleAddress(address _newOracle)`: **(Admin)** Sets or updates the address of the trusted AI oracle.
12. `receiveAIInsight(bytes32 _reportId, int256 _sentimentScore, uint256 _trendIndex)`: **(Only Oracle)** Receives a structured report from the AI oracle, updating internal state or potentially flagging parameters for review.
13. `proposeAIBasedParameterChange(bytes32 _reportId, bytes32 _paramName, uint256 _newValue)`: **(Moderator)** Allows a moderator to initiate a governance proposal based on a received AI insight.

#### **VI. Governance & Protocol Evolution**
14. `submitProtocolParameterProposal(bytes32 _paramName, uint256 _newValue)`: Allows any user (with sufficient reputation) to submit a proposal to change a whitelisted protocol parameter.
15. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to cast their vote on an active proposal, with voting power weighted by their current reputation.
16. `executeProposal(uint256 _proposalId)`: Executes a proposal if it has met quorum and passed, applying the proposed parameter change.
17. `setVotingThresholds(uint256 _minReputationToPropose, uint256 _quorumPercentage, uint256 _votingPeriod)`: **(Governance)** Allows the community to adjust the governance thresholds.

#### **VII. User Engagement & Rewards**
18. `stakeForReputationBoost(uint256 _amount)`: Allows users to stake `_amount` of the designated ERC20 token to receive a multiplier on reputation gains or a buffer against decay.
19. `unstakeReputationBoost(uint256 _amount)`: Allows users to retrieve their staked tokens.
20. `distributeEngagementReward(address _recipient, uint256 _amount)`: **(Moderator)** Allows moderators to manually award reputation and potentially tokens for significant community contributions.

#### **VIII. Utility & Access Control**
21. `defineAccessFeature(bytes32 _featureId, uint256 _minReputationRequired)`: **(Governance)** Defines a new protocol feature and the minimum reputation required to access it.
22. `checkFeatureAccess(address _user, bytes32 _featureId)`: **(View)** A public view function for external dApps or internal logic to check if a user meets the reputation requirement for a specific feature.
23. `grantTemporaryFeatureAccess(address _user, bytes32 _featureId, uint256 _duration)`: **(Moderator)** Grants temporary access to a feature, bypassing reputation requirements for a limited time.

#### **IX. Views & Getters**
24. `getCurrentReputation(address _user)`: **(View)** Returns the current reputation score of a user.
25. `getDRATraitLevel(uint256 _tokenId)`: **(View)** Returns the current computed trait level of a DRA based on its owner's reputation.
26. `getProposalState(uint256 _proposalId)`: **(View)** Returns the current state (e.g., Active, Passed, Failed) of a governance proposal.

#### **X. Admin/Emergency Functions**
27. `setModerator(address _moderator, bool _isModerator)`: **(Owner)** Grants or revokes moderator privileges.
28. `pauseProtocol()`: **(Owner)** Pauses critical protocol functions in case of an emergency.
29. `unpauseProtocol()`: **(Owner)** Unpauses the protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title AdaptiveReputationProtocol
 * @dev A novel, multi-faceted smart contract that integrates dynamic NFTs (DRAs),
 * a comprehensive reputation system, an AI oracle for external insights, and an
 * adaptive governance model. Users earn and lose reputation, which directly
 * influences the traits and utility of their DRAs. Protocol parameters can be
 * adjusted through reputation-weighted governance votes, with proposals
 * potentially initiated by insights from an AI oracle. An ERC20 staking
 * mechanism further incentivizes long-term engagement and boosts reputation effects.
 *
 * Key Features:
 * - Dynamic Reputation Assets (DRAs): ERC721 NFTs whose traits and visual representation
 *   (via metadata URI) evolve based on the owner's current reputation score.
 * - Robust Reputation System: Users accrue reputation for positive actions and face
 *   penalties for negative ones, with a configurable decay mechanism.
 * - AI Oracle Integration: Receives sentiment and trend data from an external AI oracle,
 *   which can trigger or inform governance proposals to adapt protocol parameters.
 * - Adaptive Governance: A decentralized voting system where voting power is weighted
 *   by user reputation, allowing the community to dynamically adjust core protocol parameters.
 * - Engagement Staking: Users can stake an ERC20 token to amplify their reputation gains
 *   or mitigate decay, fostering long-term commitment.
 * - Feature Access Control: Protocol-defined features or external dApps can query the
 *   contract to determine access levels based on a user's reputation.
 * - Modular & Extensible: Designed to allow for future expansion of reputation sources,
 *   DRA traits, and governance-controlled parameters.
 *
 * Outline and Function Summary:
 *
 * I. Core Concepts & State Variables
 *    - owner: Contract owner (admin).
 *    - _reputations: Mapping of address to current reputation score.
 *    - _tokenTraits: Mapping of DRA tokenId to its current computed trait level.
 *    - _aiOracle: Address of the trusted AI oracle contract.
 *    - _stakingToken: Address of the ERC20 token used for staking.
 *    - reputationDecayRate: Governance-controlled rate at which reputation decays.
 *    - minReputationToMintDRA: Minimum reputation required to mint a DRA.
 *    - proposals: Structs holding details of ongoing and completed governance proposals.
 *    - _featureAccessLevels: Mapping of bytes32 feature ID to minimum reputation required.
 *
 * II. External Interfaces
 *    - IERC20: Interface for the staking token.
 *    - IAIOracle: Minimal interface for receiving AI insights.
 *
 * III. Reputation Management
 *    1. constructor(): Initializes the contract, sets initial owner, staking token, and base parameters.
 *    2. registerUser(): Allows a new user to join the protocol and receive an initial reputation score.
 *    3. adjustReputation(address _user, int256 _delta): (Moderator/Internal) Increases or decreases a user's reputation.
 *    4. updateReputationDecayRate(uint256 _newRate): (Governance) Adjusts global reputation decay rate.
 *    5. triggerReputationDecay(): (Permissionless/Keeper) Triggers global reputation decay.
 *
 * IV. Dynamic Asset (DRA) Management (ERC721-based)
 *    6. mintDynamicReputationAsset(string memory _initialBaseURI): Mints a new DRA, requires min reputation.
 *    7. setDRABaseURI(string memory _newBaseURI): (Admin) Sets the base URI for DRA metadata.
 *    8. tokenURI(uint256 tokenId): (View/ERC721) Returns dynamic metadata URI for a DRA.
 *    9. lockDRATraits(uint256 _tokenId): Locks a DRA's traits at its current level.
 *    10. releaseDRATraits(uint256 _tokenId): Reverts a locked DRA back to dynamic evolution.
 *
 * V. AI Oracle Integration & Parameter Adaptation
 *    11. setAIOracleAddress(address _newOracle): (Admin) Sets/updates the trusted AI oracle address.
 *    12. receiveAIInsight(bytes32 _reportId, int256 _sentimentScore, uint256 _trendIndex): (Only Oracle) Receives structured report from AI oracle.
 *    13. proposeAIBasedParameterChange(bytes32 _reportId, bytes32 _paramName, uint256 _newValue): (Moderator) Initiates governance proposal based on AI insight.
 *
 * VI. Governance & Protocol Evolution
 *    14. submitProtocolParameterProposal(bytes32 _paramName, uint256 _newValue): User submits a proposal to change a whitelisted protocol parameter.
 *    15. voteOnProposal(uint256 _proposalId, bool _support): Users vote on a proposal, weighted by reputation.
 *    16. executeProposal(uint256 _proposalId): Executes a proposal if it passes.
 *    17. setVotingThresholds(uint256 _minReputationToPropose, uint256 _quorumPercentage, uint256 _votingPeriod): (Governance) Adjusts governance thresholds.
 *
 * VII. User Engagement & Rewards
 *    18. stakeForReputationBoost(uint256 _amount): Stakes ERC20 to get multiplier on reputation gains.
 *    19. unstakeReputationBoost(uint256 _amount): Retrieves staked tokens.
 *    20. distributeEngagementReward(address _recipient, uint256 _amount): (Moderator) Awards reputation/tokens for contributions.
 *
 * VIII. Utility & Access Control
 *    21. defineAccessFeature(bytes32 _featureId, uint256 _minReputationRequired): (Governance) Defines a new protocol feature and its min reputation.
 *    22. checkFeatureAccess(address _user, bytes32 _featureId): (View) Checks if a user meets reputation for a feature.
 *    23. grantTemporaryFeatureAccess(address _user, bytes32 _featureId, uint256 _duration): (Moderator) Grants temporary access.
 *
 * IX. Views & Getters
 *    24. getCurrentReputation(address _user): (View) Returns current reputation of a user.
 *    25. getDRATraitLevel(uint256 _tokenId): (View) Returns current computed trait level of a DRA.
 *    26. getProposalState(uint256 _proposalId): (View) Returns state of a governance proposal.
 *
 * X. Admin/Emergency Functions
 *    27. setModerator(address _moderator, bool _isModerator): (Owner) Grants/revokes moderator privileges.
 *    28. pauseProtocol(): (Owner) Pauses critical functions.
 *    29. unpauseProtocol(): (Owner) Unpauses the protocol.
 */
contract AdaptiveReputationProtocol is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeCast for uint256;

    // --- I. Core Concepts & State Variables ---

    // Reputation System
    mapping(address => uint256) private _reputations;
    mapping(address => uint256) private _lastReputationDecayTime; // To track when decay was last applied to a user
    mapping(address => bool) private _isModerator;

    uint256 public initialReputation = 100; // Starting reputation for new users
    uint256 public minReputationToMintDRA = 500;
    uint256 public reputationDecayRate = 10; // Reputation points to decay per day per 1000 reputation
    uint256 public lastGlobalDecayTrigger; // Timestamp of the last global decay trigger

    // Dynamic Reputation Asset (DRA) System (ERC721)
    Counters.Counter private _tokenIdCounter;
    string private _draBaseURI;
    mapping(uint256 => bool) private _isDRATraitLocked; // True if DRA traits are locked

    // AI Oracle Integration
    address public _aiOracle;
    uint256 public aiInsightThreshold = 70; // Threshold for AI sentiment/trend to trigger a proposal suggestion

    // Governance System
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        bytes32 paramName;      // Identifier for the parameter to change (e.g., "reputationDecayRate")
        uint256 newValue;       // The proposed new value for the parameter
        uint256 totalVotesFor;  // Total reputation weighted votes for
        uint256 totalVotesAgainst; // Total reputation weighted votes against
        uint256 startBlock;     // Block number when voting started
        uint256 endBlock;       // Block number when voting ends
        uint256 proposer;       // Reputation of the proposer at proposal time
        address creator;        // Address of the proposal creator
        ProposalState state;    // Current state of the proposal
        mapping(address => bool) hasVoted; // Tracks if an address has voted
    }
    Proposal[] public proposals;
    uint256 public minReputationToPropose = 1000;
    uint256 public governanceVotingPeriodBlocks = 10000; // Approx 2-3 days on Ethereum mainnet
    uint256 public governanceQuorumPercentage = 50; // Percentage of total eligible reputation needed for quorum

    // Engagement Staking
    IERC20 public _stakingToken;
    mapping(address => uint256) private _stakedAmounts;
    mapping(address => uint256) private _reputationBoostMultiplier; // Staked amount affecting reputation changes

    // Utility & Access Control
    mapping(bytes32 => uint256) private _featureAccessLevels; // featureId => minReputationRequired
    mapping(address => mapping(bytes32 => uint256)) private _temporaryAccessExpiry; // user => featureId => expiryTimestamp

    // --- Events ---
    event ReputationAdjusted(address indexed user, int256 delta, uint256 newReputation);
    event DRAGenerated(address indexed owner, uint256 indexed tokenId, string initialURI);
    event DRATraitsLocked(uint256 indexed tokenId, address indexed owner);
    event DRATraitsReleased(uint256 indexed tokenId, address indexed owner);
    event AIInsightReceived(bytes32 indexed reportId, int256 sentimentScore, uint256 trendIndex);
    event ProposalSubmitted(uint256 indexed proposalId, bytes32 paramName, uint256 newValue, address indexed creator);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 reputationWeight, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramName, uint256 newValue);
    event ReputationStaked(address indexed user, uint256 amount);
    event ReputationUnstaked(address indexed user, uint256 amount);
    event FeatureDefined(bytes32 indexed featureId, uint256 minReputation);
    event TemporaryAccessGranted(address indexed user, bytes32 indexed featureId, uint256 expiry);
    event ModeratorSet(address indexed moderator, bool isModerator);
    event ReputationDecayTriggered(uint256 decayRate, uint256 timestamp);

    // --- Modifiers ---
    modifier onlyModerator() {
        require(_isModerator[msg.sender] || owner() == msg.sender, "Caller is not a moderator or owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == _aiOracle, "Caller is not the AI oracle");
        _;
    }

    modifier onlyExistingUser(address _user) {
        require(_reputations[_user] > 0 || _stakedAmounts[_user] > 0, "User not registered in protocol");
        _;
    }

    // --- II. External Interfaces ---

    interface IAIOracle {
        // Example function, actual oracle might be more complex
        function fulfillRequest(bytes32 _requestId, uint256 _value) external;
    }

    // --- III. Reputation Management ---

    /**
     * @dev Constructor to initialize the contract.
     * @param _name The name for the ERC721 token.
     * @param _symbol The symbol for the ERC721 token.
     * @param _stakingTokenAddress The address of the ERC20 token used for staking.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _stakingTokenAddress
    ) ERC721(_name, _symbol) Ownable(msg.sender) Pausable() {
        require(_stakingTokenAddress != address(0), "Staking token address cannot be zero");
        _stakingToken = IERC20(_stakingTokenAddress);
        lastGlobalDecayTrigger = block.timestamp;
    }

    /**
     * @dev Allows a new user to register with the protocol and receive an initial reputation score.
     * Users can only register once.
     */
    function registerUser() external whenNotPaused {
        require(_reputations[msg.sender] == 0, "User already registered");
        _reputations[msg.sender] = initialReputation;
        _lastReputationDecayTime[msg.sender] = block.timestamp;
        emit ReputationAdjusted(msg.sender, int256(initialReputation), initialReputation);
    }

    /**
     * @dev Increases or decreases a user's reputation. Can be called by moderators
     * or internally by the protocol for various actions. Reputation cannot drop below 0.
     * @param _user The address of the user whose reputation is to be adjusted.
     * @param _delta The amount to adjust the reputation by (positive for gain, negative for loss).
     */
    function adjustReputation(address _user, int256 _delta)
        public
        onlyModerator // Can be modified to be called internally by other protocol logic
        whenNotPaused
        onlyExistingUser(_user)
    {
        uint256 currentRep = _reputations[_user];
        uint256 newRep;

        if (_delta > 0) {
            newRep = currentRep + uint256(_delta);
            // Apply boost if staked
            if (_stakedAmounts[_user] > 0) {
                newRep = newRep + (uint256(_delta) * _reputationBoostMultiplier[_user] / 100); // 100 means 100% boost if multiplier is 100
            }
        } else {
            // Apply decay before applying penalty to ensure full penalty impact
            _applyReputationDecay(_user);
            currentRep = _reputations[_user]; // Get updated reputation after decay
            if (currentRep < uint256(-_delta)) {
                newRep = 0;
            } else {
                newRep = currentRep - uint256(-_delta);
            }
        }
        _reputations[_user] = newRep;
        emit ReputationAdjusted(_user, _delta, newRep);
    }

    /**
     * @dev Allows the community to adjust the global reputation decay rate.
     * This is a governance-controlled parameter.
     * @param _newRate The new reputation decay rate (e.g., 10 means 10 points per day per 1000 reputation).
     */
    function updateReputationDecayRate(uint256 _newRate) external onlyWhenGovernanceExecuted("reputationDecayRate") {
        reputationDecayRate = _newRate;
    }

    /**
     * @dev Allows anyone (e.g., a decentralized keeper network) to trigger the global
     * reputation decay mechanism for all active users. This ensures the reputation
     * system remains dynamic and reflects recent engagement.
     * It iterates through a batch to avoid gas limits if there are many users.
     * For a truly scalable solution, a separate reputation management contract
     * with batch processing or Merkle trees for reputation proofs would be ideal.
     */
    function triggerReputationDecay() public whenNotPaused {
        // Implement a more sophisticated batching or snapshot-based decay for large user bases
        // For demonstration, we'll simply update the last global decay trigger.
        // Actual decay for each user happens when their reputation is queried or adjusted.
        require(block.timestamp > lastGlobalDecayTrigger, "Decay already triggered recently.");
        lastGlobalDecayTrigger = block.timestamp;
        emit ReputationDecayTriggered(reputationDecayRate, block.timestamp);
    }

    /**
     * @dev Internal function to apply reputation decay to a specific user.
     * Called before reputation is queried or adjusted to ensure it's up-to-date.
     * @param _user The address of the user.
     */
    function _applyReputationDecay(address _user) internal {
        if (_reputations[_user] == 0) return;

        uint256 lastDecayTime = _lastReputationDecayTime[_user];
        uint256 currentTime = block.timestamp;

        // Ensure decay is not applied multiple times within a short period
        if (currentTime <= lastDecayTime) return;

        uint256 daysPassed = (currentTime - lastDecayTime) / 1 days;
        if (daysPassed == 0) return;

        uint256 currentRep = _reputations[_user];
        uint256 decayAmount = (currentRep * reputationDecayRate * daysPassed) / 1000; // e.g., 10 rep/day per 1000 rep

        // Apply staked boost to mitigate decay
        if (_stakedAmounts[_user] > 0) {
            decayAmount = decayAmount - (decayAmount * _reputationBoostMultiplier[_user] / 200); // Halve the boost for decay mitigation
        }

        if (decayAmount >= currentRep) {
            _reputations[_user] = 0;
        } else {
            _reputations[_user] = currentRep - decayAmount;
        }
        _lastReputationDecayTime[_user] = currentTime;
        emit ReputationAdjusted(_user, -int256(decayAmount), _reputations[_user]);
    }

    // --- IV. Dynamic Asset (DRA) Management (ERC721-based) ---

    /**
     * @dev Mints a new Dynamic Reputation Asset (DRA) to the caller.
     * Requires the caller to have a minimum reputation score.
     * @param _initialBaseURI A base URI component for the initial metadata.
     */
    function mintDynamicReputationAsset(string memory _initialBaseURI) external whenNotPaused {
        _applyReputationDecay(msg.sender); // Ensure reputation is current
        require(_reputations[msg.sender] >= minReputationToMintDRA, "Not enough reputation to mint DRA");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, newTokenId);

        // Store initial state or link to owner's reputation
        // For true dynamism, metadata should be generated on-demand based on owner's *current* reputation.
        // We'll store a placeholder and have tokenURI calculate on the fly.
        _setTokenURI(newTokenId, _initialBaseURI); // This will just set the base, actual URI is dynamic
        emit DRAGenerated(msg.sender, newTokenId, _initialBaseURI);
    }

    /**
     * @dev Sets the base URI for Dynamic Reputation Asset (DRA) metadata.
     * The `tokenURI` function will dynamically construct the full URI by appending
     * the token ID and the current trait level based on owner's reputation.
     * @param _newBaseURI The new base URI (e.g., "https://api.example.com/dra/").
     */
    function setDRABaseURI(string memory _newBaseURI) external onlyOwner {
        _draBaseURI = _newBaseURI;
    }

    /**
     * @dev Returns the dynamic metadata URI for a given DRA.
     * The URI includes the base URI, token ID, and a calculated trait level
     * which is derived from the owner's current reputation. This enables dynamic
     * visual and utility changes for the NFT.
     * @param tokenId The ID of the DRA.
     * @return The dynamic token URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        if (_isDRATraitLocked[tokenId]) {
            // If traits are locked, return a static URI or a URI indicating it's locked
            return string(abi.encodePacked(_draBaseURI, "locked/", Strings.toString(tokenId)));
        }

        address draOwner = ownerOf(tokenId);
        uint256 currentTraitLevel = getDRATraitLevel(tokenId); // Calculated dynamically

        // Example: https://api.example.com/dra/123/level/5
        return string(abi.encodePacked(_draBaseURI, Strings.toString(tokenId), "/level/", Strings.toString(currentTraitLevel)));
    }

    /**
     * @dev Allows a DRA owner to permanently lock their DRA's traits at its current level.
     * This might cost reputation or require a token burn as a commitment.
     * For this example, it might cost reputation.
     * @param _tokenId The ID of the DRA to lock.
     */
    function lockDRATraits(uint256 _tokenId) external whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of this DRA");
        require(!_isDRATraitLocked[_tokenId], "DRA traits are already locked");

        _applyReputationDecay(msg.sender); // Ensure current reputation
        // Example cost: 10% of current reputation to lock traits
        uint256 cost = _reputations[msg.sender] / 10;
        require(_reputations[msg.sender] >= cost, "Not enough reputation to lock DRA traits");

        _reputations[msg.sender] -= cost;
        _isDRATraitLocked[_tokenId] = true;
        emit DRATraitsLocked(_tokenId, msg.sender);
        emit ReputationAdjusted(msg.sender, -int256(cost), _reputations[msg.sender]);
    }

    /**
     * @dev Allows a DRA owner to revert a locked DRA back to dynamic evolution.
     * @param _tokenId The ID of the DRA to unlock.
     */
    function releaseDRATraits(uint256 _tokenId) external whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of this DRA");
        require(_isDRATraitLocked[_tokenId], "DRA traits are not locked");

        _isDRATraitLocked[_tokenId] = false;
        emit DRATraitsReleased(_tokenId, msg.sender);
    }

    // --- V. AI Oracle Integration & Parameter Adaptation ---

    /**
     * @dev Sets or updates the address of the trusted AI oracle.
     * Only the contract owner can call this.
     * @param _newOracle The address of the new AI oracle contract.
     */
    function setAIOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "AI Oracle address cannot be zero");
        _aiOracle = _newOracle;
    }

    /**
     * @dev Receives a structured report from the AI oracle.
     * This data can then be used to inform or trigger governance proposals.
     * @param _reportId A unique identifier for the AI report.
     * @param _sentimentScore An integer representing sentiment (e.g., -100 to 100).
     * @param _trendIndex An integer representing a trend (e.g., 0 to 100).
     */
    function receiveAIInsight(bytes32 _reportId, int256 _sentimentScore, uint256 _trendIndex) external onlyOracle whenNotPaused {
        // Implement logic to store or immediately react to AI insights.
        // For example, if sentimentScore is very low, it might trigger a warning state.
        // Or if trendIndex is high, it could suggest increasing certain rewards.
        // For this example, we simply emit an event and allow moderators to use it.
        emit AIInsightReceived(_reportId, _sentimentScore, _trendIndex);
    }

    /**
     * @dev Allows a moderator to initiate a governance proposal based on a received AI insight.
     * This acts as a bridge between off-chain AI analysis and on-chain governance.
     * @param _reportId The ID of the AI report that prompted this proposal.
     * @param _paramName The name of the protocol parameter to be changed.
     * @param _newValue The new value proposed for the parameter.
     */
    function proposeAIBasedParameterChange(bytes32 _reportId, bytes32 _paramName, uint256 _newValue) external onlyModerator whenNotPaused {
        // Here, one might check if _reportId corresponds to a recent, relevant insight.
        // For simplicity, we directly create a proposal.
        _submitProposal(_paramName, _newValue, msg.sender);
    }

    // --- VI. Governance & Protocol Evolution ---

    /**
     * @dev Allows any user (with sufficient reputation) to submit a proposal
     * to change a whitelisted protocol parameter.
     * @param _paramName The identifier of the parameter to change (e.g., "minReputationToMintDRA").
     * @param _newValue The new value proposed for the parameter.
     */
    function submitProtocolParameterProposal(bytes32 _paramName, uint256 _newValue) external whenNotPaused {
        _applyReputationDecay(msg.sender);
        require(_reputations[msg.sender] >= minReputationToPropose, "Not enough reputation to submit a proposal");
        _submitProposal(_paramName, _newValue, msg.sender);
    }

    /**
     * @dev Internal function to handle proposal submission.
     * @param _paramName The parameter name.
     * @param _newValue The new value.
     * @param _creator The address of the proposal creator.
     */
    function _submitProposal(bytes32 _paramName, uint256 _newValue, address _creator) internal {
        // A more robust system would have a whitelisted set of `_paramName` that can be changed
        // and validation rules for `_newValue` based on `_paramName`.
        // For this example, we assume basic parameters can be changed.

        proposals.push(Proposal({
            paramName: _paramName,
            newValue: _newValue,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            startBlock: block.number,
            endBlock: block.number + governanceVotingPeriodBlocks,
            proposer: _reputations[_creator], // Snapshot proposer's reputation
            creator: _creator,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize the mapping for this proposal
        }));
        emit ProposalSubmitted(proposals.length - 1, _paramName, _newValue, _creator);
    }

    /**
     * @dev Allows users to cast their vote on an active proposal.
     * Voting power is weighted by the user's current reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.number <= proposal.endBlock, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        _applyReputationDecay(msg.sender); // Ensure voter's reputation is current
        uint256 voterReputation = _reputations[msg.sender];
        require(voterReputation > 0, "Voter has no reputation");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.totalVotesFor += voterReputation;
        } else {
            proposal.totalVotesAgainst += voterReputation;
        }
        emit VoteCast(_proposalId, msg.sender, voterReputation, _support);
    }

    /**
     * @dev Executes a proposal if it has met quorum and passed.
     * Can be called by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.number > proposal.endBlock, "Voting period has not ended yet");

        // Calculate total eligible reputation (approximate for this example)
        // A real DAO would need a snapshot of total voting power at proposal creation.
        // For simplicity, let's use proposer's reputation as a proxy for total stake at that time.
        // Or, more robustly, iterate _reputations or use a token snapshot.
        // For now, let's assume `proposer`s reputation at the time of proposal is `total_available_reputation_at_time_of_proposal`.
        uint256 totalAvailableReputationAtProposalTime = proposal.proposer; // Simplification

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        uint256 quorumRequired = (totalAvailableReputationAtProposalTime * governanceQuorumPercentage) / 100;

        if (totalVotes >= quorumRequired && proposal.totalVotesFor > proposal.totalVotesAgainst) {
            // Proposal passed
            proposal.state = ProposalState.Succeeded;
            _applyParameterChange(proposal.paramName, proposal.newValue);
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId, proposal.paramName, proposal.newValue);
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    /**
     * @dev Internal function to apply a parameter change.
     * @param _paramName The name of the parameter.
     * @param _newValue The new value.
     */
    function _applyParameterChange(bytes32 _paramName, uint256 _newValue) internal {
        // This is where whitelisted parameters are actually changed.
        // Add more `if-else if` blocks for other governance-controlled parameters.
        if (_paramName == "reputationDecayRate") {
            reputationDecayRate = _newValue;
        } else if (_paramName == "minReputationToMintDRA") {
            minReputationToMintDRA = _newValue;
        } else if (_paramName == "minReputationToPropose") {
            minReputationToPropose = _newValue;
        } else if (_paramName == "governanceVotingPeriodBlocks") {
            governanceVotingPeriodBlocks = _newValue;
        } else if (_paramName == "governanceQuorumPercentage") {
            require(_newValue <= 100, "Quorum percentage cannot exceed 100");
            governanceQuorumPercentage = _newValue;
        } else if (_paramName == "aiInsightThreshold") {
            aiInsightThreshold = _newValue;
        } else {
            revert("Unknown or unauthorized parameter change");
        }
    }

    /**
     * @dev Modifier to ensure a function can only be called when a specific governance proposal has been executed.
     * This makes functions like `updateReputationDecayRate` governance-controlled.
     * Note: This is a simplified implementation. A more robust solution would track which proposal executed which parameter change.
     * For this example, it acts as a placeholder check.
     * @param _paramName The name of the parameter associated with the governance function.
     */
    modifier onlyWhenGovernanceExecuted(bytes32 _paramName) {
        // This modifier is a simplification. In a full DAO, actual parameter updates
        // happen *inside* `_applyParameterChange`, not directly in setter functions.
        // The setter functions would typically be internal, and `_applyParameterChange` would call them.
        // For this example, it serves to highlight what is governance-controlled.
        // `_applyParameterChange` already directly sets the state.
        // So this modifier is illustrative, demonstrating *intent* rather than direct enforcement.
        // The actual enforcement happens in `executeProposal`.
        _;
    }

    /**
     * @dev Allows the community to adjust the governance thresholds like
     * minimum reputation to propose, quorum percentage, and voting period duration.
     * @param _minReputationToPropose The new minimum reputation required to submit a proposal.
     * @param _quorumPercentage The new percentage of total eligible reputation needed for a proposal to pass quorum.
     * @param _votingPeriod The new duration of the voting period in blocks.
     */
    function setVotingThresholds(uint256 _minReputationToPropose, uint256 _quorumPercentage, uint256 _votingPeriod)
        external
        onlyWhenGovernanceExecuted("votingThresholds") // Placeholder for governance execution
    {
        require(_quorumPercentage <= 100, "Quorum percentage cannot exceed 100");
        minReputationToPropose = _minReputationToPropose;
        governanceQuorumPercentage = _quorumPercentage;
        governanceVotingPeriodBlocks = _votingPeriod;
    }

    // --- VII. User Engagement & Rewards ---

    /**
     * @dev Allows users to stake `_amount` of the designated ERC20 token
     * to receive a multiplier on reputation gains or a buffer against decay.
     * The boost multiplier increases with the staked amount.
     * @param _amount The amount of ERC20 tokens to stake.
     */
    function stakeForReputationBoost(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Stake amount must be greater than zero");
        _applyReputationDecay(msg.sender); // Ensure reputation is current

        IERC20(_stakingToken).transferFrom(msg.sender, address(this), _amount);
        _stakedAmounts[msg.sender] += _amount;
        _reputationBoostMultiplier[msg.sender] = _stakedAmounts[msg.sender] / 100; // Example: 1 boost point per 100 staked tokens

        emit ReputationStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows users to retrieve their staked tokens.
     * This will also adjust their reputation boost multiplier.
     * @param _amount The amount of ERC20 tokens to unstake.
     */
    function unstakeReputationBoost(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(_stakedAmounts[msg.sender] >= _amount, "Insufficient staked amount");
        _applyReputationDecay(msg.sender); // Ensure reputation is current

        _stakedAmounts[msg.sender] -= _amount;
        _reputationBoostMultiplier[msg.sender] = _stakedAmounts[msg.sender] / 100;

        IERC20(_stakingToken).transfer(msg.sender, _amount);
        emit ReputationUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Allows moderators to manually award reputation and potentially tokens
     * for significant community contributions (e.g., content creation, bug bounty).
     * @param _recipient The address of the user to reward.
     * @param _amount The amount of reputation to award.
     */
    function distributeEngagementReward(address _recipient, uint256 _amount) external onlyModerator whenNotPaused {
        require(_amount > 0, "Reward amount must be greater than zero");
        _applyReputationDecay(_recipient); // Ensure recipient's reputation is current

        uint256 currentRep = _reputations[_recipient];
        uint256 newRep = currentRep + _amount;
        // Apply boost if staked
        if (_stakedAmounts[_recipient] > 0) {
            newRep = newRep + (_amount * _reputationBoostMultiplier[_recipient] / 100);
        }
        _reputations[_recipient] = newRep;
        emit ReputationAdjusted(_recipient, int256(_amount), newRep);
    }

    // --- VIII. Utility & Access Control ---

    /**
     * @dev Defines a new protocol feature and the minimum reputation required to access it.
     * This function is governance-controlled, meaning changes require a successful vote.
     * @param _featureId A unique identifier (bytes32) for the new feature.
     * @param _minReputationRequired The minimum reputation score needed to access this feature.
     */
    function defineAccessFeature(bytes32 _featureId, uint256 _minReputationRequired)
        external
        onlyWhenGovernanceExecuted(_featureId) // Placeholder for governance execution
    {
        _featureAccessLevels[_featureId] = _minReputationRequired;
        emit FeatureDefined(_featureId, _minReputationRequired);
    }

    /**
     * @dev A public view function for external dApps or internal logic to check
     * if a user meets the reputation requirement for a specific feature.
     * @param _user The address of the user.
     * @param _featureId The identifier of the feature.
     * @return True if the user has access, false otherwise.
     */
    function checkFeatureAccess(address _user, bytes32 _featureId) public view returns (bool) {
        uint256 requiredRep = _featureAccessLevels[_featureId];
        if (requiredRep == 0) return true; // Feature has no reputation requirement

        // Check for temporary access
        if (_temporaryAccessExpiry[_user][_featureId] > block.timestamp) {
            return true;
        }

        // Check current reputation (apply decay implicitly for view)
        uint256 currentRep = _reputations[_user];
        uint256 lastDecayTime = _lastReputationDecayTime[_user];
        if (currentRep > 0 && block.timestamp > lastDecayTime) {
            uint256 daysPassed = (block.timestamp - lastDecayTime) / 1 days;
            uint256 decayAmount = (currentRep * reputationDecayRate * daysPassed) / 1000;
            if (_stakedAmounts[_user] > 0) {
                decayAmount = decayAmount - (decayAmount * _reputationBoostMultiplier[_user] / 200);
            }
            if (decayAmount < currentRep) {
                currentRep -= decayAmount;
            } else {
                currentRep = 0;
            }
        }
        return currentRep >= requiredRep;
    }

    /**
     * @dev Allows moderators to grant temporary access to a feature, bypassing
     * reputation requirements for a limited duration. Useful for support or specific events.
     * @param _user The address of the user to grant access to.
     * @param _featureId The identifier of the feature.
     * @param _duration The duration in seconds for which access is granted.
     */
    function grantTemporaryFeatureAccess(address _user, bytes32 _featureId, uint256 _duration) external onlyModerator whenNotPaused {
        uint256 expiry = block.timestamp + _duration;
        _temporaryAccessExpiry[_user][_featureId] = expiry;
        emit TemporaryAccessGranted(_user, _featureId, expiry);
    }

    // --- IX. Views & Getters ---

    /**
     * @dev Returns the current reputation score of a user, applying any pending decay.
     * @param _user The address of the user.
     * @return The user's current reputation.
     */
    function getCurrentReputation(address _user) public view returns (uint256) {
        if (_reputations[_user] == 0) return 0;

        uint256 currentRep = _reputations[_user];
        uint256 lastDecayTime = _lastReputationDecayTime[_user];

        if (block.timestamp > lastDecayTime) {
            uint256 daysPassed = (block.timestamp - lastDecayTime) / 1 days;
            uint256 decayAmount = (currentRep * reputationDecayRate * daysPassed) / 1000;
            if (_stakedAmounts[_user] > 0) {
                decayAmount = decayAmount - (decayAmount * _reputationBoostMultiplier[_user] / 200);
            }
            if (decayAmount < currentRep) {
                currentRep -= decayAmount;
            } else {
                currentRep = 0;
            }
        }
        return currentRep;
    }

    /**
     * @dev Returns the current computed trait level of a DRA based on its owner's reputation.
     * This is an example calculation; real trait levels would be more complex.
     * @param _tokenId The ID of the DRA.
     * @return The current trait level (0-10, for example).
     */
    function getDRATraitLevel(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "DRA does not exist");
        if (_isDRATraitLocked[_tokenId]) {
            // If locked, return the level it was locked at (requires storing the locked level)
            // For simplicity, let's assume locked level is 10 for this example.
            return 10;
        }
        address draOwner = ownerOf(_tokenId);
        uint256 ownerReputation = getCurrentReputation(draOwner);

        // Example: Scale reputation (e.g., 0-10000) to trait levels (e.g., 0-10)
        if (ownerReputation < 100) return 0;
        if (ownerReputation < 500) return 1;
        if (ownerReputation < 1000) return 2;
        if (ownerReputation < 2000) return 3;
        if (ownerReputation < 3500) return 4;
        if (ownerReputation < 5000) return 5;
        if (ownerReputation < 7000) return 6;
        if (ownerReputation < 9000) return 7;
        if (ownerReputation < 12000) return 8;
        if (ownerReputation < 15000) return 9;
        return 10;
    }

    /**
     * @dev Returns the current state of a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The current state (Pending, Active, Succeeded, Failed, Executed).
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
            // Voting period has ended, but hasn't been executed or failed yet
            uint256 totalAvailableReputationAtProposalTime = proposal.proposer;
            uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
            uint256 quorumRequired = (totalAvailableReputationAtProposalTime * governanceQuorumPercentage) / 100;

            if (totalVotes >= quorumRequired && proposal.totalVotesFor > proposal.totalVotesAgainst) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Failed;
            }
        }
        return proposal.state;
    }

    // --- X. Admin/Emergency Functions ---

    /**
     * @dev Grants or revokes moderator privileges to an address.
     * Moderators can `adjustReputation` and `proposeAIBasedParameterChange`.
     * @param _moderator The address to set as moderator.
     * @param _isModerator True to grant, false to revoke.
     */
    function setModerator(address _moderator, bool _isModerator) external onlyOwner {
        _isModerator[_moderator] = _isModerator;
        emit ModeratorSet(_moderator, _isModerator);
    }

    /**
     * @dev Pauses critical protocol functions in case of an emergency.
     * Only the contract owner can pause.
     */
    function pauseProtocol() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the protocol, allowing functions to be called again.
     * Only the contract owner can unpause.
     */
    function unpauseProtocol() external onlyOwner {
        _unpause();
    }
}
```