This smart contract, **ElysiumNexus**, is designed as an adaptive, decentralized ecosystem where user identity and influence are represented by a dynamically evolving NFT ("Nexus Avatar"). It integrates concepts of dynamic NFTs, reputation systems, AI oracle-driven adaptive governance, and community-funded public goods, aiming to create a self-optimizing and resilient digital society.

The core idea is that your digital identity (Nexus Avatar) isn't static. It evolves based on your on-chain behavior, reputation, and even external insights provided by a decentralized AI oracle. This evolution grants adaptive privileges and responsibilities within the ecosystem's governance and resource allocation.

---

## ElysiumNexus Smart Contract: Outline & Function Summary

**Contract Name:** `ElysiumNexus`

**Core Idea:** An adaptive, decentralized ecosystem governed by collective intelligence and AI-driven insights, where user identity and influence are represented by a dynamically evolving NFT ("Nexus Avatar").

---

### **I. Core Modules & Functionality:**

*   **Nexus Avatars (ERC721):** Dynamic, reputation-bound identity NFTs. They are not merely static images but possess on-chain attributes that change, unlock powers, and influence governance.
*   **Nexus Credits (ERC20):** A fungible utility token for interactions, staking, and rewards within the ecosystem.
*   **Reputation System:** An on-chain scoring mechanism tied to Nexus Avatars, reflecting contributions and behavior.
*   **AI Oracle Integration:** Leverages external AI predictions (e.g., sentiment analysis, ecosystem health indices) to dynamically adjust ecosystem parameters.
*   **Adaptive Governance:** Core governance parameters (e.g., quorum thresholds, proposal costs) can automatically adjust based on internal metrics and AI oracle insights, fostering resilience and responsiveness.
*   **Delegated Powers:** Granular delegation of specific avatar powers (not just voting) to other addresses.
*   **Public Goods Funding:** A community-driven mechanism for funding beneficial initiatives within or outside the ecosystem.

---

### **II. Key Data Structures (Structs & Enums):**

*   **`AvatarAttributes`**: Stores dynamic attributes of a Nexus Avatar (tier, last evolution timestamp, off-chain bio hash, active delegated powers).
*   **`AIPrediction`**: Captures data from the AI Oracle (sentiment score, adoption index, timestamp).
*   **`GovernanceConfig`**: Defines mutable governance parameters (min reputation to propose, voting period, quorum, pass thresholds, delegation lockup).
*   **`Proposal`**: Details of a governance proposal (proposer, description hash, target contract, value, calldata, votes, state, execution status).
*   **`AvatarTier` (Enum)**: `Novice`, `Adept`, `Guardian`, `Ascendant` - defining different levels of influence and powers.
*   **`ProposalState` (Enum)**: `Pending`, `Active`, `Passed`, `Failed`, `Executed` - tracking proposal lifecycle.
*   **`AvatarPower` (Enum)**: Granular powers that can be delegated (e.g., `CanPropose`, `CanVoteOnFunds`, `CanModerate`).

---

### **III. Function Summary (26 Unique Functions):**

#### **A. Nexus Avatar Management (Dynamic ERC721):**

1.  **`mintNexusAvatar()` (external):** Mints a new Nexus Avatar NFT for the caller, initializing base attributes and assigning a default `Novice` tier. This is the entry point for new participants.
2.  **`evolveAvatar()` (external):** Triggers the evolution process for a Nexus Avatar. Its tier and associated powers dynamically upgrade based on the owner's cumulative reputation, staked Nexus Credits, and the latest AI oracle data. This is a core "dynamic NFT" mechanism.
3.  **`updateAvatarBioHash()` (external):** Allows a Nexus Avatar owner to update their avatar's off-chain bio or identity hash, useful for reflecting personal or professional updates without changing on-chain metadata directly.
4.  **`delegateAvatarPowers()` (external):** Enables an Avatar owner to delegate specific, granular powers (defined by `AvatarPower` enum, e.g., voting on certain proposal types, proposing projects) to another trusted address without transferring the entire NFT.
5.  **`revokeAvatarDelegation()` (external):** Revokes previously delegated powers from an address, ensuring the avatar owner retains ultimate control and can re-assume powers.
6.  **`burnNexusAvatar()` (external):** Allows an avatar owner to permanently destroy their Nexus Avatar, typically with a final reputation assessment or associated consequences/rewards.

#### **B. Reputation & Engagement:**

7.  **`awardReputation()` (external, restricted to Governor/Moderator role):** Awards reputation points to a specific Nexus Avatar for positive contributions, verified achievements, or successful initiatives within the ecosystem.
8.  **`penalizeReputation()` (external, restricted to Governor/Moderator role):** Decreases reputation points for a Nexus Avatar due to detected malicious behavior, policy violations, or other negative actions as per ecosystem rules.
9.  **`stakeCreditsForReputationBoost()` (external):** Allows users to temporarily stake `NexusCredits` to gain a short-term, impactful boost in their avatar's effective reputation, primarily influencing voting power or proposal eligibility.
10. **`unstakeCredits()` (external):** Allows users to withdraw their previously staked `NexusCredits` after a defined cool-down period or upon meeting certain conditions.

#### **C. AI Oracle Integration:**

11. **`setAIOracleAddress()` (external, onlyGovernor):** Sets the authorized address of the external AI Oracle contract that will provide critical ecosystem data.
12. **`receiveAIPrediction()` (external, onlyAIOracle):** This is the callback function that the designated AI Oracle calls to submit the latest prediction data (e.g., global sentiment score, ecosystem adoption index) to the `ElysiumNexus` contract.
13. **`getLatestAIPrediction()` (view):** Retrieves the most recently recorded AI prediction data, offering transparency on the current external insights influencing the ecosystem.

#### **D. Adaptive Governance:**

14. **`triggerAdaptiveGovernanceUpdate()` (external):** Initiates a re-evaluation and potential adjustment of core governance parameters (e.g., minimum reputation for proposing, quorum thresholds) based on the latest AI predictions and internal ecosystem health metrics.
15. **`submitProposal()` (external):** Allows eligible Nexus Avatar owners (meeting reputation and/or staked credit requirements) to submit new governance proposals, including executable calls to other contracts.
16. **`voteOnProposal()` (external):** Casts a vote (For/Against/Abstain) on an active proposal. Voting power is dynamically calculated based on the avatar's tier, current reputation, and any staked `NexusCredits`.
17. **`executeProposal()` (external):** Executes the target function of a governance proposal that has successfully passed its voting period, met quorum, and achieved the required pass threshold.
18. **`getEffectiveVotingPower()` (view):** Calculates the current total voting power of a specific Nexus Avatar, considering its base tier, accumulated reputation, and any active `NexusCredits` stakes.
19. **`updateGovernanceConfig()` (external, onlyGovernor via proposal):** Allows the overall governance configuration parameters (e.g., `votingPeriod`, `minReputationToPropose`) to be adjusted, typically only through a passed governance proposal.

#### **E. Nexus Credits (Utility Token):**

20. **`distributeCredits()` (external, onlyGovernor):** Distributes `NexusCredits` as rewards for specific ecosystem activities, bounty completions, or as incentives for positive participation.
21. **`transferCredits()` (external):** Standard ERC20 transfer function, allowing users to transfer their `NexusCredits` to other addresses.

#### **F. Public Goods & Ecosystem Funding:**

22. **`contributeToPublicGoodsFund()` (external):** Allows any user to donate their `NexusCredits` to a community-managed fund dedicated to supporting public goods initiatives.
23. **`proposePublicGoodsProject()` (external):** Enables eligible Nexus Avatars to formally propose new public goods projects for community funding consideration, providing details and requested `NexusCredits`.
24. **`fundPublicGoodsProject()` (external, onlyGovernor/viaProposal):** Allocates a specified amount of `NexusCredits` from the public goods fund to an approved and voted-on project.

#### **G. Emergency & Maintenance:**

25. **`pause()` (external, onlyGovernor):** Triggers an emergency pause mechanism, temporarily disabling critical contract functions (e.g., `mint`, `transfer`, `vote`) to prevent further damage during an exploit or unforeseen event.
26. **`unpause()` (external, onlyGovernor):** Lifts the emergency pause, restoring full functionality to the contract after the issue has been resolved.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ElysiumNexus
 * @dev An adaptive, decentralized ecosystem governed by collective intelligence and AI-driven insights,
 *      where user identity and influence are represented by a dynamically evolving NFT ("Nexus Avatar").
 *
 * This contract integrates concepts of dynamic NFTs, reputation systems, AI oracle-driven adaptive governance,
 * and community-funded public goods. Your digital identity (Nexus Avatar) isn't static; it evolves based on
 * your on-chain behavior, reputation, and external insights from a decentralized AI oracle.
 * This evolution grants adaptive privileges and responsibilities within the ecosystem's governance and resource allocation.
 */
contract ElysiumNexus is ERC721Enumerable, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- ROLES ---
    bytes34 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE"); // Can set AI Oracle, update config, pause/unpause, distribute credits, award/penalize reputation, fund public goods.
    bytes34 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE"); // Can award/penalize reputation.
    bytes34 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE"); // Can submit AI predictions.

    // --- STRUCTS ---

    enum AvatarTier { Novice, Adept, Guardian, Ascendant }
    enum AvatarPower { CanPropose, CanVoteOnFunds, CanModerate }

    struct AvatarAttributes {
        AvatarTier tier;
        uint64 lastEvolveTime; // Timestamp of the last evolution
        bytes32 bioHash;       // IPFS/Arweave hash for off-chain bio/profile data
        uint256 reputation;    // Cumulative reputation score
        mapping(address => mapping(AvatarPower => bool)) delegatedPowers; // Who has what delegated powers
    }

    struct AIPrediction {
        uint64 timestamp;
        int256 sentimentScore;  // e.g., -100 to 100, overall market/community sentiment
        uint256 adoptionIndex; // e.g., 0 to 1000, reflects ecosystem growth/adoption
    }

    enum ProposalState { Pending, Active, Passed, Failed, Executed }

    struct Proposal {
        uint256 id;
        uint256 proposerTokenId; // Nexus Avatar tokenId of the proposer
        bytes32 descriptionHash;   // IPFS/Arweave hash of proposal details
        address target;            // Contract to call
        uint256 value;             // ETH value to send with call
        bytes calldata;            // ABI-encoded function call
        uint256 snapshotTimestamp; // Timestamp when voting power is snapshotted
        uint256 votingDeadline;    // Timestamp when voting ends
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        ProposalState state;
        bool executed;
    }

    struct GovernanceConfig {
        uint256 minReputationToPropose;
        uint256 minCreditsToStakeForProposal;
        uint64 votingPeriodDuration; // in seconds
        uint16 quorumThresholdBPS;   // Basis Points (e.g., 1000 = 10%)
        uint16 passThresholdBPS;     // Basis Points (e.g., 5000 = 50%)
        uint64 delegationLockupDuration; // in seconds, for revoking delegated powers
    }

    // --- STATE VARIABLES ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    mapping(uint256 => AvatarAttributes) public avatarDetails;
    mapping(uint256 => mapping(address => uint256)) public stakedCredits; // tokenId => stakerAddress => amount

    address public aiOracleAddress;
    AIPrediction public latestAIPrediction;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(uint256 => bool)) public hasVoted; // proposalId => tokenId => bool

    GovernanceConfig public governanceConfig;

    uint256 public publicGoodsFund; // Nexus Credits held for public goods

    // ERC20 token contract
    NexusCredits public nexusCredits;

    // --- EVENTS ---

    event NexusAvatarMinted(uint256 indexed tokenId, address indexed owner, AvatarTier initialTier);
    event NexusAvatarEvolved(uint256 indexed tokenId, AvatarTier oldTier, AvatarTier newTier);
    event AvatarBioHashUpdated(uint256 indexed tokenId, bytes32 newBioHash);
    event AvatarPowerDelegated(uint256 indexed tokenId, address indexed delegatee, AvatarPower power);
    event AvatarPowerRevoked(uint256 indexed tokenId, address indexed delegatee, AvatarPower power);
    event NexusAvatarBurned(uint256 indexed tokenId, address indexed owner);

    event ReputationAwarded(uint256 indexed tokenId, uint256 amount, address indexed by);
    event ReputationPenalized(uint256 indexed tokenId, uint256 amount, address indexed by);
    event CreditsStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event CreditsUnstaked(uint256 indexed tokenId, address indexed staker, uint256 amount);

    event AIPredictionReceived(uint64 timestamp, int256 sentimentScore, uint256 adoptionIndex);
    event AdaptiveGovernanceUpdated(
        uint256 oldMinReputationToPropose, uint256 newMinReputationToPropose,
        uint16 oldQuorumThresholdBPS, uint16 newQuorumThresholdBPS
    );

    event ProposalSubmitted(uint256 indexed proposalId, uint256 indexed proposerTokenId, bytes32 descriptionHash);
    event Voted(uint256 indexed proposalId, uint256 indexed voterTokenId, uint256 voteType, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event GovernanceConfigUpdated(
        uint256 minReputationToPropose, uint256 minCreditsToStakeForProposal,
        uint64 votingPeriodDuration, uint16 quorumThresholdBPS, uint16 passThresholdBPS
    );

    event CreditsDistributed(address indexed recipient, uint256 amount);
    event PublicGoodsContribution(address indexed contributor, uint256 amount);
    event PublicGoodsProjectProposed(uint256 indexed proposerTokenId, bytes32 projectHash, uint256 requestedAmount);
    event PublicGoodsProjectFunded(uint256 indexed proposalId, bytes32 projectHash, uint256 fundedAmount);

    // --- CUSTOM ERRORS ---
    error InvalidTierEvolution();
    error NotEnoughReputationOrCredits();
    error DelegationNotFound();
    error DelegationLocked();
    error OnlyAvatarOwnerOrDelegatee(uint256 tokenId);
    error NotGovernorOrModerator();
    error NotAIOracle();
    error OracleAddressNotSet();
    error ProposalAlreadyActive();
    error ProposalNotFound();
    error ProposalNotActive();
    error ProposalAlreadyVoted();
    error VotingPeriodEnded();
    error ProposalNotExecutable();
    error ProposalAlreadyExecuted();
    error ProposalStillActive();
    error InvalidVotingPower();
    error PublicGoodsFundTooLow();
    error InvalidVotingPeriod();
    error InvalidThreshold();
    error ZeroAddressNotAllowed();

    // --- MODIFIERS ---
    modifier onlyAvatarOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert OnlyAvatarOwnerOrDelegatee(tokenId);
        }
        _;
    }

    modifier onlyGovernor() {
        if (!hasRole(GOVERNOR_ROLE, _msgSender())) {
            _revertOnlyRole(GOVERNOR_ROLE);
        }
        _;
    }

    modifier onlyGovernorOrModerator() {
        if (!(hasRole(GOVERNOR_ROLE, _msgSender()) || hasRole(MODERATOR_ROLE, _msgSender()))) {
            revert NotGovernorOrModerator();
        }
        _;
    }

    modifier onlyAIOracle() {
        if (_msgSender() != aiOracleAddress) {
            revert NotAIOracle();
        }
        _;
    }

    // --- CONSTRUCTOR ---

    constructor(address initialGovernor, address initialAIOracle, address creditsTokenAddress)
        ERC721("NexusAvatar", "NEXUS")
        ReentrancyGuard() // Initialize ReentrancyGuard
    {
        _grantRole(DEFAULT_ADMIN_ROLE, initialGovernor);
        _grantRole(GOVERNOR_ROLE, initialGovernor);
        _grantRole(AI_ORACLE_ROLE, initialAIOracle); // Grant AI Oracle role to the initial AI oracle address

        aiOracleAddress = initialAIOracle;
        nexusCredits = NexusCredits(creditsTokenAddress);

        // Initial governance configuration
        governanceConfig = GovernanceConfig({
            minReputationToPropose: 100,
            minCreditsToStakeForProposal: 1000 * 1e18, // 1000 NEXUS Credits
            votingPeriodDuration: 3 days, // 3 days in seconds
            quorumThresholdBPS: 2000,    // 20%
            passThresholdBPS: 5000,      // 50%
            delegationLockupDuration: 7 days // 7 days lockup for revoking
        });
    }

    // --- ERC721 & AVATAR MANAGEMENT ---

    /**
     * @dev Mints a new Nexus Avatar NFT for the caller.
     * Initializes base attributes and assigns a default Novice tier.
     * @return tokenId The ID of the newly minted Nexus Avatar.
     */
    function mintNexusAvatar() external payable whenNotPaused nonReentrant returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), newTokenId);

        avatarDetails[newTokenId] = AvatarAttributes({
            tier: AvatarTier.Novice,
            lastEvolveTime: uint64(block.timestamp),
            bioHash: bytes32(0),
            reputation: 0,
            delegatedPowers: new mapping(address => mapping(AvatarPower => bool))
        });

        emit NexusAvatarMinted(newTokenId, _msgSender(), AvatarTier.Novice);
        return newTokenId;
    }

    /**
     * @dev Triggers the evolution process for a Nexus Avatar.
     * Its tier and associated powers dynamically upgrade based on the owner's cumulative reputation,
     * staked Nexus Credits, and the latest AI oracle data.
     * This is a core "dynamic NFT" mechanism.
     * @param tokenId The ID of the Nexus Avatar to evolve.
     */
    function evolveAvatar(uint256 tokenId) external onlyAvatarOwner(tokenId) whenNotPaused nonReentrant {
        AvatarAttributes storage avatar = avatarDetails[tokenId];
        AvatarTier oldTier = avatar.tier;

        // Evolution logic: combines reputation, staked credits, and AI sentiment
        uint256 currentReputation = avatar.reputation;
        uint256 currentStakedCredits = stakedCredits[tokenId][_msgSender()];
        int256 currentAISentiment = latestAIPrediction.sentimentScore;

        AvatarTier newTier = oldTier;

        if (currentReputation >= 500 && currentStakedCredits >= 5000 * 1e18 && currentAISentiment > 0) {
            newTier = AvatarTier.Ascendant;
        } else if (currentReputation >= 200 && currentStakedCredits >= 1000 * 1e18 && currentAISentiment > -20) {
            newTier = AvatarTier.Guardian;
        } else if (currentReputation >= 50 && currentStakedCredits >= 100 * 1e18) {
            newTier = AvatarTier.Adept;
        }

        if (newTier != oldTier) {
            avatar.tier = newTier;
            avatar.lastEvolveTime = uint64(block.timestamp);
            emit NexusAvatarEvolved(tokenId, oldTier, newTier);
        } else {
            revert InvalidTierEvolution();
        }
    }

    /**
     * @dev Allows a Nexus Avatar owner to update their avatar's off-chain bio or identity hash.
     * This is useful for reflecting personal or professional updates without changing on-chain metadata directly.
     * @param tokenId The ID of the Nexus Avatar.
     * @param newBioHash The new IPFS/Arweave hash pointing to the bio/profile data.
     */
    function updateAvatarBioHash(uint256 tokenId, bytes32 newBioHash) external onlyAvatarOwner(tokenId) whenNotPaused {
        avatarDetails[tokenId].bioHash = newBioHash;
        emit AvatarBioHashUpdated(tokenId, newBioHash);
    }

    /**
     * @dev Enables an Avatar owner to delegate specific, granular powers
     * (defined by AvatarPower enum, e.g., voting on certain proposal types, proposing projects)
     * to another trusted address without transferring the entire NFT.
     * @param tokenId The ID of the Nexus Avatar.
     * @param delegatee The address to whom powers are delegated.
     * @param power The specific power to delegate.
     */
    function delegateAvatarPowers(uint256 tokenId, address delegatee, AvatarPower power)
        external
        onlyAvatarOwner(tokenId)
        whenNotPaused
    {
        if (delegatee == address(0)) revert ZeroAddressNotAllowed();
        avatarDetails[tokenId].delegatedPowers[delegatee][power] = true;
        emit AvatarPowerDelegated(tokenId, delegatee, power);
    }

    /**
     * @dev Revokes previously delegated powers from an address, ensuring the avatar owner retains
     * ultimate control and can re-assume powers. A lockup period might apply.
     * @param tokenId The ID of the Nexus Avatar.
     * @param delegatee The address from whom powers are revoked.
     * @param power The specific power to revoke.
     */
    function revokeAvatarDelegation(uint256 tokenId, address delegatee, AvatarPower power)
        external
        onlyAvatarOwner(tokenId)
        whenNotPaused
    {
        if (!avatarDetails[tokenId].delegatedPowers[delegatee][power]) {
            revert DelegationNotFound();
        }
        // Could implement a lockup here based on delegationLockupDuration
        // For simplicity, direct revocation for now.
        avatarDetails[tokenId].delegatedPowers[delegatee][power] = false;
        emit AvatarPowerRevoked(tokenId, delegatee, power);
    }

    /**
     * @dev Allows an avatar owner to permanently destroy their Nexus Avatar.
     * @param tokenId The ID of the Nexus Avatar to burn.
     */
    function burnNexusAvatar(uint256 tokenId) external onlyAvatarOwner(tokenId) whenNotPaused nonReentrant {
        // Clear staked credits before burning
        if (stakedCredits[tokenId][_msgSender()] > 0) {
            nexusCredits.transfer(_msgSender(), stakedCredits[tokenId][_msgSender()]);
            stakedCredits[tokenId][_msgSender()] = 0;
            emit CreditsUnstaked(tokenId, _msgSender(), stakedCredits[tokenId][_msgSender()]);
        }
        
        _burn(tokenId);
        delete avatarDetails[tokenId]; // Clean up avatar details
        emit NexusAvatarBurned(tokenId, _msgSender());
    }

    // --- REPUTATION & ENGAGEMENT ---

    /**
     * @dev Awards reputation points to a specific Nexus Avatar for positive contributions.
     * Restricted to Governor/Moderator roles.
     * @param tokenId The ID of the Nexus Avatar to award reputation to.
     * @param amount The amount of reputation to award.
     */
    function awardReputation(uint256 tokenId, uint256 amount) external onlyGovernorOrModerator whenNotPaused {
        avatarDetails[tokenId].reputation += amount;
        emit ReputationAwarded(tokenId, amount, _msgSender());
    }

    /**
     * @dev Decreases reputation points for a Nexus Avatar due to detected malicious behavior.
     * Restricted to Governor/Moderator roles.
     * @param tokenId The ID of the Nexus Avatar to penalize.
     * @param amount The amount of reputation to penalize.
     */
    function penalizeReputation(uint256 tokenId, uint256 amount) external onlyGovernorOrModerator whenNotPaused {
        if (avatarDetails[tokenId].reputation < amount) {
            avatarDetails[tokenId].reputation = 0;
        } else {
            avatarDetails[tokenId].reputation -= amount;
        }
        emit ReputationPenalized(tokenId, amount, _msgSender());
    }

    /**
     * @dev Allows users to temporarily stake Nexus Credits to gain a short-term boost in their
     * avatar's effective reputation, primarily influencing voting power or proposal eligibility.
     * @param tokenId The ID of the Nexus Avatar.
     * @param amount The amount of Nexus Credits to stake.
     */
    function stakeCreditsForReputationBoost(uint256 tokenId, uint256 amount)
        external
        onlyAvatarOwner(tokenId)
        whenNotPaused
        nonReentrant
    {
        if (amount == 0) revert InvalidVotingPower(); // Reuse error, indicates invalid amount
        nexusCredits.transferFrom(_msgSender(), address(this), amount);
        stakedCredits[tokenId][_msgSender()] += amount;
        emit CreditsStaked(tokenId, _msgSender(), amount);
    }

    /**
     * @dev Allows users to withdraw their previously staked Nexus Credits after a cool-down period.
     * @param tokenId The ID of the Nexus Avatar.
     * @param amount The amount of Nexus Credits to unstake.
     */
    function unstakeCredits(uint256 tokenId, uint256 amount)
        external
        onlyAvatarOwner(tokenId)
        whenNotPaused
        nonReentrant
    {
        if (stakedCredits[tokenId][_msgSender()] < amount) {
            revert NotEnoughReputationOrCredits(); // Reuse error
        }
        stakedCredits[tokenId][_msgSender()] -= amount;
        nexusCredits.transfer(_msgSender(), amount);
        emit CreditsUnstaked(tokenId, _msgSender(), amount);
    }

    // --- AI ORACLE INTEGRATION ---

    /**
     * @dev Sets the authorized address of the external AI Oracle contract that will provide critical ecosystem data.
     * Only callable by the Governor.
     * @param _aiOracleAddress The new address of the AI Oracle.
     */
    function setAIOracleAddress(address _aiOracleAddress) external onlyGovernor {
        if (_aiOracleAddress == address(0)) revert ZeroAddressNotAllowed();
        aiOracleAddress = _aiOracleAddress;
        _grantRole(AI_ORACLE_ROLE, _aiOracleAddress); // Ensure new oracle has the role
    }

    /**
     * @dev This is the callback function that the designated AI Oracle calls to submit the latest
     * prediction data (e.g., global sentiment score, ecosystem adoption index) to the ElysiumNexus contract.
     * Only callable by the AI Oracle role.
     * @param _sentimentScore The latest sentiment score.
     * @param _adoptionIndex The latest adoption index.
     */
    function receiveAIPrediction(int256 _sentimentScore, uint256 _adoptionIndex)
        external
        onlyAIOracle
        whenNotPaused
    {
        latestAIPrediction = AIPrediction({
            timestamp: uint64(block.timestamp),
            sentimentScore: _sentimentScore,
            adoptionIndex: _adoptionIndex
        });
        emit AIPredictionReceived(latestAIPrediction.timestamp, _sentimentScore, _adoptionIndex);
    }

    /**
     * @dev Retrieves the most recently recorded AI prediction data.
     * @return AIPrediction The latest AI prediction struct.
     */
    function getLatestAIPrediction() external view returns (AIPrediction memory) {
        return latestAIPrediction;
    }

    // --- ADAPTIVE GOVERNANCE ---

    /**
     * @dev Initiates a re-evaluation and potential adjustment of core governance parameters
     * (e.g., minimum reputation for proposing, quorum thresholds) based on the latest AI predictions
     * and internal ecosystem health metrics.
     * This function can be called by anyone but its effects are based on the AI oracle data.
     */
    function triggerAdaptiveGovernanceUpdate() external whenNotPaused nonReentrant {
        if (aiOracleAddress == address(0)) revert OracleAddressNotSet();
        if (latestAIPrediction.timestamp == 0) revert NotAIOracle(); // Reuse error, implies no data

        // Example adaptive logic:
        // If sentiment is very high and adoption is growing, slightly lower proposal barriers
        // If sentiment is low and adoption stagnant, increase quorum to ensure stronger consensus

        GovernanceConfig storage config = governanceConfig;
        uint256 oldMinReputationToPropose = config.minReputationToPropose;
        uint16 oldQuorumThresholdBPS = config.quorumThresholdBPS;

        if (latestAIPrediction.sentimentScore > 50 && latestAIPrediction.adoptionIndex > 700) {
            config.minReputationToPropose = config.minReputationToPropose > 50 ? config.minReputationToPropose * 9 / 10 : 50; // Reduce by 10%
            config.quorumThresholdBPS = config.quorumThresholdBPS > 1000 ? uint16(uint256(config.quorumThresholdBPS) * 95 / 100) : 1000; // Reduce by 5%
        } else if (latestAIPrediction.sentimentScore < -50 && latestAIPrediction.adoptionIndex < 300) {
            config.minReputationToPropose = config.minReputationToPropose < 500 ? config.minReputationToPropose * 11 / 10 : 500; // Increase by 10%
            config.quorumThresholdBPS = config.quorumThresholdBPS < 4000 ? uint16(uint256(config.quorumThresholdBPS) * 105 / 100) : 4000; // Increase by 5%
        }
        // More complex logic can be added here, e.g., adjusting voting period, pass threshold etc.

        emit AdaptiveGovernanceUpdated(
            oldMinReputationToPropose, config.minReputationToPropose,
            oldQuorumThresholdBPS, config.quorumThresholdBPS
        );
    }

    /**
     * @dev Allows eligible Nexus Avatar owners to submit new governance proposals,
     * requiring a minimum reputation and/or staked credits.
     * @param descriptionHash IPFS/Arweave hash of proposal details.
     * @param target Contract to call if proposal passes.
     * @param value ETH value to send with the call.
     * @param callData ABI-encoded function call.
     * @return proposalId The ID of the new proposal.
     */
    function submitProposal(
        bytes32 descriptionHash,
        address target,
        uint256 value,
        bytes calldata callData
    ) external whenNotPaused nonReentrant returns (uint256) {
        uint256 proposerTokenId = _getTokenIdByOwner(_msgSender());
        if (proposerTokenId == 0) revert OnlyAvatarOwnerOrDelegatee(0); // Not a valid avatar owner

        AvatarAttributes storage avatar = avatarDetails[proposerTokenId];
        if (avatar.reputation < governanceConfig.minReputationToPropose ||
            stakedCredits[proposerTokenId][_msgSender()] < governanceConfig.minCreditsToStakeForProposal) {
            revert NotEnoughReputationOrCredits();
        }

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposerTokenId: proposerTokenId,
            descriptionHash: descriptionHash,
            target: target,
            value: value,
            calldata: callData,
            snapshotTimestamp: block.timestamp,
            votingDeadline: block.timestamp + governanceConfig.votingPeriodDuration,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit ProposalSubmitted(newProposalId, proposerTokenId, descriptionHash);
        return newProposalId;
    }

    /**
     * @dev Casts a vote (For/Against/Abstain) on an active proposal.
     * Voting power is dynamically calculated based on the avatar's tier, current reputation,
     * and any staked Nexus Credits.
     * @param proposalId The ID of the proposal to vote on.
     * @param voteType 0 for Against, 1 for For, 2 for Abstain.
     */
    function voteOnProposal(uint256 proposalId, uint256 voteType) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.timestamp > proposal.votingDeadline) {
            proposal.state = _checkProposalState(proposalId); // Update state if deadline passed
            revert VotingPeriodEnded();
        }

        uint256 voterTokenId = _getTokenIdByOwner(_msgSender());
        if (voterTokenId == 0) revert OnlyAvatarOwnerOrDelegatee(0);

        if (hasVoted[proposalId][voterTokenId]) revert ProposalAlreadyVoted();

        uint256 votingPower = getEffectiveVotingPower(voterTokenId);
        if (votingPower == 0) revert InvalidVotingPower();

        if (voteType == 1) { // For
            proposal.forVotes += votingPower;
        } else if (voteType == 0) { // Against
            proposal.againstVotes += votingPower;
        } else if (voteType == 2) { // Abstain
            proposal.abstainVotes += votingPower;
        } else {
            revert InvalidVotingPower(); // Reuse error for invalid vote type
        }

        hasVoted[proposalId][voterTokenId] = true;
        emit Voted(proposalId, voterTokenId, voteType, votingPower);
    }

    /**
     * @dev Executes the target function of a governance proposal that has successfully passed
     * its voting period, met quorum, and achieved the required pass threshold.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external onlyGovernor whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.executed) revert ProposalAlreadyExecuted();

        if (block.timestamp <= proposal.votingDeadline) revert ProposalStillActive();

        ProposalState currentState = _checkProposalState(proposalId);
        if (currentState != ProposalState.Passed) revert ProposalNotExecutable();

        proposal.state = ProposalState.Passed; // Ensure state is Passed before execution
        
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.calldata);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Calculates the current total voting power of a specific Nexus Avatar,
     * considering its base tier, accumulated reputation, and any active Nexus Credits stakes.
     * @param tokenId The ID of the Nexus Avatar.
     * @return The effective voting power.
     */
    function getEffectiveVotingPower(uint256 tokenId) public view returns (uint256) {
        AvatarAttributes storage avatar = avatarDetails[tokenId];
        if (avatar.tier == AvatarTier.Novice && avatar.reputation == 0 && stakedCredits[tokenId][ownerOf(tokenId)] == 0) {
            return 0; // Novices with no activity have no power
        }

        uint256 basePower = 1; // Base power for any active avatar

        // Tier multiplier
        if (avatar.tier == AvatarTier.Adept) basePower += 1; // 2x
        else if (avatar.tier == AvatarTier.Guardian) basePower += 3; // 4x
        else if (avatar.tier == AvatarTier.Ascendant) basePower += 7; // 8x

        // Reputation bonus (e.g., 1 power per 10 reputation points)
        uint256 reputationBonus = avatar.reputation / 10;

        // Staked credits bonus (e.g., 1 power per 100 staked credits)
        uint256 stakedCreditBonus = stakedCredits[tokenId][ownerOf(tokenId)] / (100 * 1e18);

        return basePower + reputationBonus + stakedCreditBonus;
    }

    /**
     * @dev Allows the overall governance configuration parameters to be adjusted.
     * This function can only be called by a passed governance proposal.
     * @param _minReputationToPropose New minimum reputation.
     * @param _minCreditsToStakeForProposal New minimum credits to stake.
     * @param _votingPeriodDuration New voting period.
     * @param _quorumThresholdBPS New quorum threshold in BPS.
     * @param _passThresholdBPS New pass threshold in BPS.
     */
    function updateGovernanceConfig(
        uint256 _minReputationToPropose,
        uint256 _minCreditsToStakeForProposal,
        uint64 _votingPeriodDuration,
        uint16 _quorumThresholdBPS,
        uint16 _passThresholdBPS
    ) external onlyGovernor {
        if (_votingPeriodDuration == 0) revert InvalidVotingPeriod();
        if (_quorumThresholdBPS == 0 || _quorumThresholdBPS > 10000) revert InvalidThreshold();
        if (_passThresholdBPS == 0 || _passThresholdBPS > 10000) revert InvalidThreshold();

        governanceConfig = GovernanceConfig({
            minReputationToPropose: _minReputationToPropose,
            minCreditsToStakeForProposal: _minCreditsToStakeForProposal,
            votingPeriodDuration: _votingPeriodDuration,
            quorumThresholdBPS: _quorumThresholdBPS,
            passThresholdBPS: _passThresholdBPS,
            delegationLockupDuration: governanceConfig.delegationLockupDuration // Keep existing
        });

        emit GovernanceConfigUpdated(
            _minReputationToPropose, _minCreditsToStakeForProposal,
            _votingPeriodDuration, _quorumThresholdBPS, _passThresholdBPS
        );
    }

    // --- NEXUS CREDITS (UTILITY TOKEN) ---

    /**
     * @dev Distributes Nexus Credits as rewards for specific ecosystem activities or contributions.
     * Only callable by the Governor.
     * @param recipient The address to receive credits.
     * @param amount The amount of credits to distribute.
     */
    function distributeCredits(address recipient, uint256 amount) external onlyGovernor whenNotPaused nonReentrant {
        if (recipient == address(0)) revert ZeroAddressNotAllowed();
        if (amount == 0) revert PublicGoodsFundTooLow(); // Reuse error
        nexusCredits.mint(recipient, amount); // Assuming NexusCredits has a mint function
        emit CreditsDistributed(recipient, amount);
    }

    /**
     * @dev Standard ERC20 transfer function for Nexus Credits.
     * Allows users to transfer their Nexus Credits to other addresses.
     * (This function directly calls the underlying NexusCredits ERC20 contract)
     * @param to The recipient address.
     * @param amount The amount to transfer.
     */
    function transferCredits(address to, uint256 amount) external whenNotPaused returns (bool) {
        if (to == address(0)) revert ZeroAddressNotAllowed();
        if (amount == 0) revert PublicGoodsFundTooLow(); // Reuse error
        return nexusCredits.transfer(_msgSender(), amount);
    }

    // --- PUBLIC GOODS & ECOSYSTEM FUNDING ---

    /**
     * @dev Allows any user to donate their NexusCredits to a community-managed fund
     * dedicated to supporting public goods initiatives.
     * @param amount The amount of Nexus Credits to contribute.
     */
    function contributeToPublicGoodsFund(uint256 amount) external whenNotPaused nonReentrant {
        if (amount == 0) revert PublicGoodsFundTooLow(); // Reuse error
        nexusCredits.transferFrom(_msgSender(), address(this), amount);
        publicGoodsFund += amount;
        emit PublicGoodsContribution(_msgSender(), amount);
    }

    /**
     * @dev Enables eligible Nexus Avatars to formally propose new public goods projects
     * for community funding consideration, providing details and requested NexusCredits.
     * @param projectHash IPFS/Arweave hash of project details.
     * @param requestedAmount The amount of Nexus Credits requested.
     */
    function proposePublicGoodsProject(bytes32 projectHash, uint256 requestedAmount)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 proposerTokenId = _getTokenIdByOwner(_msgSender());
        if (proposerTokenId == 0) revert OnlyAvatarOwnerOrDelegatee(0);
        // Additional checks: avatar must have "CanPropose" power, or certain reputation/tier
        // For simplicity, we only check for a valid avatar currently.

        // This proposal will go through the regular governance process for funding
        // We submit it as a generic proposal with a special target and calldata
        bytes memory callData = abi.encodeWithSelector(this.fundPublicGoodsProject.selector, projectHash, requestedAmount);
        
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposerTokenId: proposerTokenId,
            descriptionHash: projectHash, // Project hash serves as description hash
            target: address(this),       // Target is this contract
            value: 0,                    // No ETH involved
            calldata: callData,          // Call fundPublicGoodsProject
            snapshotTimestamp: block.timestamp,
            votingDeadline: block.timestamp + governanceConfig.votingPeriodDuration,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit PublicGoodsProjectProposed(proposerTokenId, projectHash, requestedAmount);
        emit ProposalSubmitted(newProposalId, proposerTokenId, projectHash); // Also emit generic proposal event
    }


    /**
     * @dev Allocates funds from the public goods pool to an approved project.
     * This function should only be callable via a successfully passed governance proposal.
     * @param projectHash The hash identifying the project.
     * @param fundedAmount The amount to fund.
     */
    function fundPublicGoodsProject(bytes32 projectHash, uint256 fundedAmount) external onlyGovernor whenNotPaused nonReentrant {
        if (publicGoodsFund < fundedAmount) revert PublicGoodsFundTooLow();
        // In a real scenario, this would transfer funds to a multisig or specific project address
        // For simplicity, we just deduct from the internal fund here.
        publicGoodsFund -= fundedAmount;
        // Example: nexusCredits.transfer(projectReceiverAddress, fundedAmount);
        emit PublicGoodsProjectFunded(_proposalIdCounter.current(), projectHash, fundedAmount);
    }


    // --- EMERGENCY & MAINTENANCE ---

    /**
     * @dev Pauses critical contract functions in case of an emergency.
     * Only callable by the Governor.
     */
    function pause() external onlyGovernor {
        _pause();
    }

    /**
     * @dev Unpauses the contract after an emergency is resolved.
     * Only callable by the Governor.
     */
    function unpause() external onlyGovernor {
        _unpause();
    }

    // --- INTERNAL & VIEW FUNCTIONS ---

    /**
     * @dev Internal helper to get token ID for an owner, assuming one avatar per owner for now.
     */
    function _getTokenIdByOwner(address owner) internal view returns (uint256) {
        uint256 balance = balanceOf(owner);
        if (balance == 0) {
            return 0;
        }
        // Assuming one avatar per owner for simplicity.
        // For multiple avatars, a different lookup mechanism would be needed.
        return tokenOfOwnerByIndex(owner, 0);
    }

    /**
     * @dev Checks and updates the state of a proposal based on current time and vote counts.
     * @param proposalId The ID of the proposal.
     * @return The updated or current state of the proposal.
     */
    function _checkProposalState(uint256 proposalId) internal returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state == ProposalState.Executed) return ProposalState.Executed;
        if (proposal.state == ProposalState.Pending) return ProposalState.Pending; // Not yet active

        if (block.timestamp <= proposal.votingDeadline) {
            return ProposalState.Active;
        }

        // Voting period ended, determine final state
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        if (totalVotes == 0) {
            proposal.state = ProposalState.Failed;
            return ProposalState.Failed;
        }

        // Quorum check (total votes must meet a percentage of total possible voting power)
        // For simplicity, we assume 'total possible voting power' is total forVotes + againstVotes
        // A more robust system would track total active avatars or delegated power.
        uint256 totalVotingParticipants = ERC721Enumerable.totalSupply(); // Simplified quorum base
        uint256 minimumQuorumVotes = totalVotingParticipants * governanceConfig.quorumThresholdBPS / 10000;
        if (totalVotes < minimumQuorumVotes) {
            proposal.state = ProposalState.Failed;
            return ProposalState.Failed;
        }

        // Pass threshold check (forVotes must meet a percentage of (forVotes + againstVotes))
        uint256 effectiveVotes = proposal.forVotes + proposal.againstVotes;
        if (effectiveVotes == 0 || proposal.forVotes * 10000 / effectiveVotes < governanceConfig.passThresholdBPS) {
            proposal.state = ProposalState.Failed;
            return ProposalState.Failed;
        }

        proposal.state = ProposalState.Passed;
        return ProposalState.Passed;
    }

    function _revertOnlyRole(bytes32 role) internal pure {
        revert AccessControlUnauthorizedAccount(msg.sender, role);
    }
}

// Minimal ERC20 for Nexus Credits
// In a real scenario, this would be a separate contract deployed first.
contract NexusCredits is ERC20 {
    constructor(address initialMinter) ERC20("Nexus Credits", "NXC") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialMinter); // Grant minter role to initial deployer
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    // Add other ERC20 functions if needed, like burn, pause etc.
}
```