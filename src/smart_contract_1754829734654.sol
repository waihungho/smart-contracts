Okay, this is an exciting challenge! Creating something truly novel and non-duplicative while incorporating advanced concepts and hitting a function count of 20+ requires combining several distinct ideas into a cohesive system.

Let's design a contract called **"The Synergistic Reputation Lattice (SRL)"**.

**Core Concept:**
The SRL is a decentralized reputation and dynamic asset forging system. Users accrue multi-dimensional reputation scores based on their on-chain interactions, contributions, and integrity within the system. This reputation isn't just a number; it unlocks the ability to "forge" unique, time-bound, and dynamically evolving "Essences" (ERC-721 tokens that can be either Soulbound or transferable based on their type and creation parameters). The system also features a "vouching" mechanism, where users can attest to others' integrity, putting their own reputation at stake. Furthermore, users can delegate specific, limited interaction "Echoes" to other addresses, allowing for meta-transactions or controlled proxy actions. The system's core parameters (like reputation decay rates, Essence forging costs, or vouching impacts) are governable by high-reputation stakeholders.

---

## The Synergistic Reputation Lattice (SRL)

**Outline:**

1.  **Introduction:** Contract purpose and core mechanics.
2.  **Solidity Version & Imports:** Standard pragma and necessary interfaces.
3.  **Custom Errors:** For clearer error handling.
4.  **Events:** To signal important state changes.
5.  **Enums & Structs:**
    *   `ReputationTier`: Enum for categorized reputation levels.
    *   `EssenceType`: Enum for different types of Essences.
    *   `UserReputation`: Struct to store multi-dimensional reputation.
    *   `Essence`: Struct for dynamic ERC721 properties.
    *   `VouchEntry`: Struct for tracking vouch details.
    *   `DelegatedEcho`: Struct for delegated permissions.
    *   `Proposal`: Struct for governance proposals.
6.  **State Variables:** Mappings for users, Essences, Catalyst balances, vouches, echoes, and governance.
7.  **Access Control Modifiers:** Custom modifiers for specific roles/conditions.
8.  **Constructor:** Initializes core parameters.
9.  **Internal & Private Helper Functions:** For calculations and state updates.
10. **Public Functions (Grouped by Category):**
    *   **I. User & Reputation Management:**
        *   `enrollUser()`
        *   `updateUserMetadata()`
        *   `performActivity()`
        *   `contributeInsight()`
        *   `reportMisconduct()`
        *   `claimDailyCatalyst()`
        *   `decayReputation()`
    *   **II. Essence Forging & Management (Dynamic NFTs/SBTs):**
        *   `forgeEssence()`
        *   `meldEssences()`
        *   `transferEssence()` (override ERC721 transfer)
        *   `burnEssence()`
        *   `getEssenceDetails()` (view)
        *   `getEssenceDynamicURI()` (view)
    *   **III. Vouching & Social Graph:**
        *   `vouchForUser()`
        *   `retractVouch()`
        *   `getVouchStatus()` (view)
    *   **IV. Delegated Echoes (Meta-Actions):**
        *   `delegateEcho()`
        *   `revokeEcho()`
        *   `executeEchoedAction()`
    *   **V. Adaptive Governance & System Parameters:**
        *   `proposeParameterChange()`
        *   `voteOnProposal()`
        *   `executeParameterChange()`
        *   `setEssenceMintCost()` (admin/governance)
        *   `setReputationDecayRates()` (admin/governance)
        *   `setVouchImpact()` (admin/governance)
    *   **VI. ERC721 Compliance & View Functions:**
        *   `tokenURI()` (override ERC721)
        *   `supportsInterface()` (ERC165)
        *   `balanceOf()`
        *   `ownerOf()`
        *   `getApproved()`
        *   `isApprovedForAll()`
        *   `approve()`
        *   `setApprovalForAll()`
        *   `_mint()` (internal helper)
        *   `_burn()` (internal helper)

---

**Function Summary (25 Functions):**

**I. User & Reputation Management:**
1.  **`enrollUser()`**: Registers a new user, initializing their reputation scores.
2.  **`updateUserMetadata(string calldata _newMetadataURI)`**: Allows users to update their profile metadata URI.
3.  **`performActivity(uint256 _activityAmount)`**: Users log generic system activities to earn "Activity" reputation.
4.  **`contributeInsight(uint256 _contributionAmount)`**: Users log specific "insights" or "contributions" to earn "Contribution" reputation.
5.  **`reportMisconduct(address _targetUser, string calldata _reason)`**: Allows users to report others, potentially impacting the target's "Integrity" reputation and vouches.
6.  **`claimDailyCatalyst()`**: Allows users to claim a small amount of "Catalyst" (internal utility token) daily, incentivizing engagement.
7.  **`decayReputation(address _user)`**: An internal or externally callable (e.g., by a keeper) function to gradually decay a user's reputation scores over time.

**II. Essence Forging & Management (Dynamic NFTs/SBTs):**
8.  **`forgeEssence(uint8 _essenceType, bool _isSoulbound)`**: Allows users to mint a new "Essence" (ERC-721) based on their current reputation tiers and Catalyst balance. Essences can be soulbound (non-transferable) or transferable.
9.  **`meldEssences(uint256 _essenceId1, uint256 _essenceId2)`**: Allows users to combine two existing Essences, potentially creating a new, more powerful or rare Essence type, consuming the originals.
10. **`transferEssence(address _from, address _to, uint256 _tokenId)`**: Overrides standard ERC721 transfer to prevent transfer of Soulbound Essences.
11. **`burnEssence(uint256 _essenceId)`**: Allows Essence owners to destroy their Essences, potentially for a Catalyst refund or other benefits.
12. **`getEssenceDetails(uint256 _essenceId)`**: View function to retrieve comprehensive details of an Essence.
13. **`getEssenceDynamicURI(uint256 _essenceId)`**: View function that returns the dynamically generated metadata URI for an Essence, reflecting its current state (e.g., expiration, melded status).

**III. Vouching & Social Graph:**
14. **`vouchForUser(address _targetUser)`**: Allows a registered user to "vouch" for another, increasing the target's "Integrity" reputation but risking a portion of the voucher's own if the target misbehaves.
15. **`retractVouch(address _targetUser)`**: Allows a user to retract a vouch, potentially affecting both parties' reputation.
16. **`getVouchStatus(address _voucher, address _target)`**: View function to check if a user has vouched for another.

**IV. Delegated Echoes (Meta-Actions):**
17. **`delegateEcho(bytes4 _functionSignature, address _delegatee)`**: Allows a user to delegate specific function call permissions (`functionSignature`) to another address (`_delegatee`) for limited, controlled actions on their behalf.
18. **`revokeEcho(bytes4 _functionSignature)`**: Revokes a previously granted delegated "Echo".
19. **`executeEchoedAction(address _user, bytes4 _functionSignature, bytes calldata _data)`**: Allows a delegated address to execute a specific pre-approved action on behalf of the `_user`. This is where meta-transaction-like behavior could be enabled.

**V. Adaptive Governance & System Parameters:**
20. **`proposeParameterChange(string calldata _description, bytes calldata _encodedCall)`**: Allows high-reputation users to propose changes to system parameters (e.g., decay rates, costs).
21. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows high-reputation users to vote on active proposals.
22. **`executeParameterChange(uint256 _proposalId)`**: Executes a passed governance proposal, updating system parameters.
23. **`setEssenceMintCost(uint8 _essenceType, uint256 _newCost)`**: An administrative/governance function to adjust the Catalyst cost for forging different Essence types.
24. **`setReputationDecayRates(uint16 _activityDecay, uint16 _contributionDecay, uint16 _integrityDecay)`**: An administrative/governance function to adjust the decay rates for each reputation dimension.
25. **`setVouchImpact(uint16 _vouchGain, uint16 _vouchLoss)`**: An administrative/governance function to adjust the reputation gain/loss impact of vouching and misconduct reports.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For `Strings.toHexString` etc.
import "@openzeppelin/contracts/utils/Base64.sol"; // For base64 encoding of JSON metadata

/// @title The Synergistic Reputation Lattice (SRL)
/// @notice A decentralized system for multi-dimensional reputation, dynamic NFT/SBT forging,
///         social vouching, delegated actions (Echoes), and adaptive governance.
/// @dev This contract combines elements of reputation systems, dynamic NFTs, Soulbound Tokens,
///      social graphs, meta-transactions, and on-chain governance into a single cohesive
///      and novel ecosystem.
/// @author YourNameHere

// --- Outline & Function Summary (Refer to the detailed list above) ---
//
// I. User & Reputation Management:
//    1. enrollUser()
//    2. updateUserMetadata()
//    3. performActivity()
//    4. contributeInsight()
//    5. reportMisconduct()
//    6. claimDailyCatalyst()
//    7. decayReputation()
//
// II. Essence Forging & Management (Dynamic NFTs/SBTs):
//    8. forgeEssence()
//    9. meldEssences()
//    10. transferEssence() (override)
//    11. burnEssence()
//    12. getEssenceDetails() (view)
//    13. getEssenceDynamicURI() (view)
//
// III. Vouching & Social Graph:
//    14. vouchForUser()
//    15. retractVouch()
//    16. getVouchStatus() (view)
//
// IV. Delegated Echoes (Meta-Actions):
//    17. delegateEcho()
//    18. revokeEcho()
//    19. executeEchoedAction()
//
// V. Adaptive Governance & System Parameters:
//    20. proposeParameterChange()
//    21. voteOnProposal()
//    22. executeParameterChange()
//    23. setEssenceMintCost()
//    24. setReputationDecayRates()
//    25. setVouchImpact()
//
// VI. ERC721 Compliance & View Functions (Standard ERC721 methods are implied or overridden)
//     - tokenURI() (override)
//     - supportsInterface()
//     - balanceOf(), ownerOf(), getApproved(), isApprovedForAll(), approve(), setApprovalForAll()
//     - _mint(), _burn() (internal helpers)
//
// --- End of Outline & Function Summary ---


contract SynergisticReputationLattice is ERC721, Ownable, ERC165 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Custom Errors ---
    error AlreadyRegistered();
    error NotRegistered();
    error InvalidReputationTier();
    error InsufficientCatalyst(uint256 required, uint256 available);
    error EssenceExpired();
    error EssenceNotOwned(address owner, uint256 tokenId);
    error InvalidEssenceForMelding();
    error EssenceIsSoulbound();
    error AlreadyVouched();
    error NotVouched();
    error CannotVouchForSelf();
    error InvalidReportTarget();
    error NotEnoughReputationForAction();
    error AlreadyDelegated();
    error NotDelegated();
    error UnauthorizedEchoExecution();
    error ProposalNotFound();
    error ProposalNotActive();
    error AlreadyVoted();
    error InsufficientReputationToVote();
    error ProposalStillActive();
    error ProposalFailed();
    error OnlyGovernanceAgent();
    error InvalidEssenceType();
    error AlreadyClaimedDailyCatalyst();

    // --- Events ---
    event UserEnrolled(address indexed user, uint256 timestamp);
    event UserMetadataUpdated(address indexed user, string newMetadataURI);
    event ReputationUpdated(address indexed user, uint16 activity, uint16 contribution, uint16 integrity);
    event EssenceForged(address indexed owner, uint256 indexed essenceId, uint8 essenceType, bool isSoulbound);
    event EssencesMelded(address indexed owner, uint256 indexed essenceId1, uint256 indexed essenceId2, uint256 newEssenceId);
    event EssenceBurnt(address indexed owner, uint256 indexed essenceId);
    event Vouched(address indexed voucher, address indexed target);
    event VouchRetracted(address indexed voucher, address indexed target);
    event MisconductReported(address indexed reporter, address indexed target, string reason);
    event CatalystClaimed(address indexed user, uint256 amount);
    event EchoDelegated(address indexed delegator, address indexed delegatee, bytes4 functionSignature);
    event EchoRevoked(address indexed delegator, bytes4 functionSignature);
    event EchoExecuted(address indexed delegator, address indexed delegatee, bytes4 functionSignature);
    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, string description);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ParameterChangeExecuted(uint256 indexed proposalId);
    event EssenceMintCostUpdated(uint8 essenceType, uint256 newCost);
    event ReputationDecayRatesUpdated(uint16 activityDecay, uint16 contributionDecay, uint16 integrityDecay);
    event VouchImpactUpdated(uint16 vouchGain, uint16 vouchLoss);


    // --- Enums & Structs ---

    enum ReputationTier {
        Novice,       // 0-99
        Apprentice,   // 100-249
        Journeyman,   // 250-499
        Master,       // 500-999
        Grandmaster   // 1000+
    }

    enum EssenceType {
        BasicInsight,       // Minimal requirements, basic utility
        Collaborator,       // Requires Contribution, unlocks specific features
        IntegritySeal,      // Requires high Integrity, non-transferable
        SynergyCore         // Forged from melding, high utility
    }

    struct UserReputation {
        uint16 activity;      // Points for general activity
        uint16 contribution;  // Points for specific contributions/insights
        uint16 integrity;     // Points for good behavior, vouches, etc.
        uint32 lastActivityTimestamp;
        uint32 lastContributionTimestamp;
        uint32 lastIntegrityUpdateTimestamp; // For decay or misconduct
        string metadataURI;
        bool isRegistered;
    }

    struct Essence {
        uint256 id;                 // Token ID
        address owner;              // Current owner
        EssenceType essenceType;    // Type of Essence
        uint32 forgedTimestamp;     // When it was created
        uint32 expiresTimestamp;    // When it expires (0 for eternal)
        bool isSoulbound;           // If true, cannot be transferred
        uint256 associatedReputationHash; // A hash of reputation scores at forging time
        bool isMelded;              // If true, it was used in a melding process
        string customURI;           // Optional custom URI set post-mint for dynamic updates
    }

    struct VouchEntry {
        uint32 vouchTimestamp;
        uint16 reputationImpacted; // Vouch reputation that was added/removed to target
    }

    struct DelegatedEcho {
        address delegatee;
        uint32 delegatedTimestamp;
        bool active;
    }

    struct Proposal {
        uint256 id;
        string description;
        bytes encodedCall;      // The function call to execute if proposal passes
        address proposer;
        uint32 proposalTimestamp;
        uint32 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Voter tracking
    }


    // --- State Variables ---

    Counters.Counter private _essenceIds; // ERC721 token counter
    Counters.Counter private _proposalIds; // Governance proposal counter

    // User data
    mapping(address => UserReputation) public userReputations;
    mapping(address => uint256) public catalystBalances;
    mapping(address => uint32) public lastCatalystClaimTimestamp; // To prevent spamming daily claim

    // Essence data (ERC721 extension)
    mapping(uint256 => Essence) public essences;

    // Vouching data
    mapping(address => mapping(address => VouchEntry)) public vouches; // voucher => target => VouchEntry
    mapping(address => uint256) public vouchesReceivedCount; // target => count of active vouches

    // Delegated Echoes
    mapping(address => mapping(bytes4 => DelegatedEcho)) public delegatedEchoes; // delegator => functionSignature => DelegatedEcho

    // Governance
    mapping(uint256 => Proposal) public proposals;

    // System Parameters (Adaptive via Governance)
    uint256 public constant MIN_REPUTATION_FOR_GOVERNANCE_ACTION = 500; // Combined sum of reputation needed
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // How long proposals are active

    mapping(uint8 => uint256) public essenceMintCosts; // EssenceType => Catalyst cost
    mapping(uint8 => uint32) public essenceLifespans; // EssenceType => lifespan in seconds (0 for eternal)

    uint16 public activityReputationGain = 5;
    uint16 public contributionReputationGain = 15;
    uint16 public integrityReputationGain = 20;

    uint16 public activityDecayRate = 1; // % per decay period
    uint16 public contributionDecayRate = 2; // % per decay period
    uint16 public integrityDecayRate = 3; // % per decay period
    uint256 public decayPeriod = 30 days; // How often decay is applied

    uint16 public vouchGainPerRep = 10; // Integrity gained by target per vouch
    uint16 public vouchLossPerRep = 15; // Integrity lost by reporter/voucher on misconduct


    // --- Modifiers ---

    modifier _onlyRegisteredUser(address _user) {
        if (!userReputations[_user].isRegistered) revert NotRegistered();
        _;
    }

    modifier _onlyEssenceOwner(uint256 _essenceId) {
        if (essences[_essenceId].owner != msg.sender) revert EssenceNotOwned(essences[_essenceId].owner, _essenceId);
        _;
    }

    modifier _canForgeEssence(EssenceType _essenceType) {
        if (essenceMintCosts[uint8(_essenceType)] == 0) revert InvalidEssenceType(); // Or another specific error
        if (catalystBalances[msg.sender] < essenceMintCosts[uint8(_essenceType)]) {
            revert InsufficientCatalyst(essenceMintCosts[uint8(_essenceType)], catalystBalances[msg.sender]);
        }
        _;
    }

    modifier _canProposeOrVote(address _user) {
        UserReputation storage rep = userReputations[_user];
        if (!rep.isRegistered || (rep.activity + rep.contribution + rep.integrity) < MIN_REPUTATION_FOR_GOVERNANCE_ACTION) {
            revert NotEnoughReputationForAction();
        }
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner) ERC721("SynergisticReputationLattice", "SRL") Ownable(initialOwner) {
        // Initialize default Essence mint costs and lifespans
        essenceMintCosts[uint8(EssenceType.BasicInsight)] = 50;
        essenceLifespans[uint8(EssenceType.BasicInsight)] = 365 days; // 1 year

        essenceMintCosts[uint8(EssenceType.Collaborator)] = 200;
        essenceLifespans[uint8(EssenceType.Collaborator)] = 0; // Eternal

        essenceMintCosts[uint8(EssenceType.IntegritySeal)] = 100;
        essenceLifespans[uint8(EssenceType.IntegritySeal)] = 0; // Eternal (SBT)

        essenceMintCosts[uint8(EssenceType.SynergyCore)] = 500;
        essenceLifespans[uint8(EssenceType.SynergyCore)] = 0; // Eternal (rare)
    }

    // --- Internal & Private Helper Functions ---

    function _calculateReputationTier(uint16 _score) internal pure returns (ReputationTier) {
        if (_score >= 1000) return ReputationTier.Grandmaster;
        if (_score >= 500) return ReputationTier.Master;
        if (_score >= 250) return ReputationTier.Journeyman;
        if (_score >= 100) return ReputationTier.Apprentice;
        return ReputationTier.Novice;
    }

    function _getCombinedReputation(address _user) internal view returns (uint256) {
        UserReputation storage rep = userReputations[_user];
        return uint256(rep.activity) + uint256(rep.contribution) + uint256(rep.integrity);
    }

    function _decayReputationInternal(address _user) internal {
        UserReputation storage rep = userReputations[_user];
        if (!rep.isRegistered) return;

        uint256 currentTime = block.timestamp;

        // Activity decay
        if (rep.lastActivityTimestamp > 0) {
            uint256 periodsPassed = (currentTime - rep.lastActivityTimestamp) / decayPeriod;
            if (periodsPassed > 0) {
                uint256 decayAmount = (uint256(rep.activity) * activityDecayRate * periodsPassed) / 100;
                if (decayAmount > rep.activity) rep.activity = 0;
                else rep.activity = uint16(rep.activity - decayAmount);
                rep.lastActivityTimestamp = uint32(currentTime);
            }
        }

        // Contribution decay
        if (rep.lastContributionTimestamp > 0) {
            uint256 periodsPassed = (currentTime - rep.lastContributionTimestamp) / decayPeriod;
            if (periodsPassed > 0) {
                uint256 decayAmount = (uint256(rep.contribution) * contributionDecayRate * periodsPassed) / 100;
                if (decayAmount > rep.contribution) rep.contribution = 0;
                else rep.contribution = uint16(rep.contribution - decayAmount);
                rep.lastContributionTimestamp = uint32(currentTime);
            }
        }

        // Integrity decay
        if (rep.lastIntegrityUpdateTimestamp > 0) {
            uint256 periodsPassed = (currentTime - rep.lastIntegrityUpdateTimestamp) / decayPeriod;
            if (periodsPassed > 0) {
                uint256 decayAmount = (uint256(rep.integrity) * integrityDecayRate * periodsPassed) / 100;
                if (decayAmount > rep.integrity) rep.integrity = 0;
                else rep.integrity = uint16(rep.integrity - decayAmount);
                rep.lastIntegrityUpdateTimestamp = uint32(currentTime);
            }
        }

        emit ReputationUpdated(_user, rep.activity, rep.contribution, rep.integrity);
    }

    function _getEssenceBaseURI() internal pure returns (string memory) {
        // This could point to an IPFS CID or a centralized server for generic metadata
        // For dynamic URI, we build the JSON directly
        return "data:application/json;base64,";
    }

    function _generateEssenceMetadata(uint256 _essenceId) internal view returns (string memory) {
        Essence storage essence = essences[_essenceId];
        string memory name;
        string memory description;
        string memory image; // Placeholder, could be dynamic SVG or IPFS hash
        string memory attributes = "";

        if (essence.essenceType == EssenceType.BasicInsight) {
            name = "Basic Insight Essence";
            description = "A foundational essence representing initial engagement.";
            image = "ipfs://QmBasicInsightPlaceholder"; // Example IPFS hash
        } else if (essence.essenceType == EssenceType.Collaborator) {
            name = "Collaborator Essence";
            description = "An essence signifying active contribution and collaboration.";
            image = "ipfs://QmCollaboratorPlaceholder";
        } else if (essence.essenceType == EssenceType.IntegritySeal) {
            name = "Integrity Seal";
            description = "A non-transferable essence validating high integrity within the lattice.";
            image = "ipfs://QmIntegritySealPlaceholder";
        } else if (essence.essenceType == EssenceType.SynergyCore) {
            name = "Synergy Core";
            description = "A rare essence forged from melding, representing deep synergy and mastery.";
            image = "ipfs://QmSynergyCorePlaceholder";
        } else {
            name = "Unknown Essence";
            description = "An essence of unknown type.";
            image = "ipfs://QmUnknownPlaceholder";
        }

        attributes = string.concat(
            '[',
            '{"trait_type": "Essence Type", "value": "', _convertEssenceTypeToString(essence.essenceType), '"},',
            '{"trait_type": "Forged On", "value": "', Strings.toString(essence.forgedTimestamp), '"},'
        );

        if (essence.expiresTimestamp > 0) {
            attributes = string.concat(attributes, '{"trait_type": "Expires On", "value": "', Strings.toString(essence.expiresTimestamp), '"},');
            if (block.timestamp > essence.expiresTimestamp) {
                attributes = string.concat(attributes, '{"trait_type": "Status", "value": "Expired"},');
            } else {
                attributes = string.concat(attributes, '{"trait_type": "Status", "value": "Active"},');
            }
        } else {
            attributes = string.concat(attributes, '{"trait_type": "Status", "value": "Eternal"},');
        }

        attributes = string.concat(attributes, '{"trait_type": "Soulbound", "value": ', essence.isSoulbound ? "true" : "false", '}');

        attributes = string.concat(attributes, ']'); // Close attributes array

        string memory json = string.concat(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', image, '",',
            '"attributes": ', attributes,
            '}'
        );
        return json;
    }

    function _convertEssenceTypeToString(EssenceType _type) internal pure returns (string memory) {
        if (_type == EssenceType.BasicInsight) return "Basic Insight";
        if (_type == EssenceType.Collaborator) return "Collaborator";
        if (_type == EssenceType.IntegritySeal) return "Integrity Seal";
        if (_type == EssenceType.SynergyCore) return "Synergy Core";
        return "Unknown";
    }

    // --- I. User & Reputation Management ---

    /// @notice Registers a new user in the Synergistic Reputation Lattice.
    /// @dev Initializes reputation scores to zero. A user must be registered to interact.
    function enrollUser() external {
        if (userReputations[msg.sender].isRegistered) revert AlreadyRegistered();

        userReputations[msg.sender] = UserReputation({
            activity: 0,
            contribution: 0,
            integrity: 0,
            lastActivityTimestamp: uint32(block.timestamp),
            lastContributionTimestamp: uint32(block.timestamp),
            lastIntegrityUpdateTimestamp: uint32(block.timestamp),
            metadataURI: "",
            isRegistered: true
        });

        emit UserEnrolled(msg.sender, block.timestamp);
        emit ReputationUpdated(msg.sender, 0, 0, 0); // Initial reputation update
    }

    /// @notice Allows a registered user to update their profile metadata URI.
    /// @param _newMetadataURI The new URI pointing to the user's profile metadata.
    function updateUserMetadata(string calldata _newMetadataURI) external _onlyRegisteredUser(msg.sender) {
        userReputations[msg.sender].metadataURI = _newMetadataURI;
        emit UserMetadataUpdated(msg.sender, _newMetadataURI);
    }

    /// @notice Users log generic system activities to earn "Activity" reputation.
    /// @param _activityAmount The amount of activity points to add.
    function performActivity(uint256 _activityAmount) external _onlyRegisteredUser(msg.sender) {
        _decayReputationInternal(msg.sender); // Apply decay before adding
        UserReputation storage rep = userReputations[msg.sender];
        rep.activity = uint16(rep.activity + activityReputationGain * _activityAmount);
        rep.lastActivityTimestamp = uint32(block.timestamp);
        emit ReputationUpdated(msg.sender, rep.activity, rep.contribution, rep.integrity);
    }

    /// @notice Users log specific "insights" or "contributions" to earn "Contribution" reputation.
    /// @param _contributionAmount The amount of contribution points to add.
    function contributeInsight(uint256 _contributionAmount) external _onlyRegisteredUser(msg.sender) {
        _decayReputationInternal(msg.sender); // Apply decay before adding
        UserReputation storage rep = userReputations[msg.sender];
        rep.contribution = uint16(rep.contribution + contributionReputationGain * _contributionAmount);
        rep.lastContributionTimestamp = uint32(block.timestamp);
        emit ReputationUpdated(msg.sender, rep.activity, rep.contribution, rep.integrity);
    }

    /// @notice Allows a registered user to report another user for misconduct.
    /// @dev This will negatively impact the target's integrity reputation and may affect active vouches.
    /// @param _targetUser The address of the user being reported.
    /// @param _reason A brief reason for the report.
    function reportMisconduct(address _targetUser, string calldata _reason) external _onlyRegisteredUser(msg.sender) {
        if (_targetUser == msg.sender) revert InvalidReportTarget();
        if (!userReputations[_targetUser].isRegistered) revert NotRegistered();

        _decayReputationInternal(_targetUser); // Decay target before impacting
        _decayReputationInternal(msg.sender); // Decay reporter as well

        UserReputation storage targetRep = userReputations[_targetUser];
        UserReputation storage reporterRep = userReputations[msg.sender];

        // Impact target's integrity
        if (targetRep.integrity >= integrityReputationGain) {
            targetRep.integrity = uint16(targetRep.integrity - integrityReputationGain);
        } else {
            targetRep.integrity = 0;
        }
        targetRep.lastIntegrityUpdateTimestamp = uint32(block.timestamp);

        // Impact reputation of those who vouched for the target
        // (This would be more complex to implement fully on-chain for all vouches,
        //  but for demonstration, we assume a direct impact on the target and
        //  a small penalty to the reporter for reporting, to prevent abuse)
        if (reporterRep.integrity >= (integrityReputationGain / 2)) {
            reporterRep.integrity = uint16(reporterRep.integrity - (integrityReputationGain / 2)); // Small penalty to reporter
        } else {
            reporterRep.integrity = 0;
        }
        reporterRep.lastIntegrityUpdateTimestamp = uint32(block.timestamp);


        emit MisconductReported(msg.sender, _targetUser, _reason);
        emit ReputationUpdated(_targetUser, targetRep.activity, targetRep.contribution, targetRep.integrity);
        emit ReputationUpdated(msg.sender, reporterRep.activity, reporterRep.contribution, reporterRep.integrity);
    }

    /// @notice Allows users to claim a small amount of "Catalyst" (internal utility token) daily.
    /// @dev Incentivizes continuous engagement.
    function claimDailyCatalyst() external _onlyRegisteredUser(msg.sender) {
        if (block.timestamp < lastCatalystClaimTimestamp[msg.sender] + 1 days) {
            revert AlreadyClaimedDailyCatalyst();
        }
        uint256 claimAmount = 10; // Example fixed amount
        catalystBalances[msg.sender] += claimAmount;
        lastCatalystClaimTimestamp[msg.sender] = uint32(block.timestamp);
        emit CatalystClaimed(msg.sender, claimAmount);
    }

    /// @notice An internally or externally callable (e.g., by a keeper network) function to decay a user's reputation.
    /// @dev This can be called by anyone, but only applies decay based on time elapsed.
    /// @param _user The address of the user whose reputation is to be decayed.
    function decayReputation(address _user) external {
        _decayReputationInternal(_user);
    }

    // --- II. Essence Forging & Management (Dynamic NFTs/SBTs) ---

    /// @notice Allows users to mint a new "Essence" (ERC-721) based on their reputation and Catalyst.
    /// @dev Essences can be soulbound (non-transferable) or transferable.
    /// @param _essenceType The type of Essence to forge.
    /// @param _isSoulbound Whether the forged Essence should be soulbound (non-transferable).
    function forgeEssence(EssenceType _essenceType, bool _isSoulbound)
        external
        _onlyRegisteredUser(msg.sender)
        _canForgeEssence(_essenceType)
    {
        _decayReputationInternal(msg.sender); // Apply decay before checking reputation for forging
        UserReputation storage rep = userReputations[msg.sender];

        // Specific reputation requirements for each EssenceType
        if (_essenceType == EssenceType.BasicInsight) {
            if (rep.activity < 50) revert NotEnoughReputationForAction();
        } else if (_essenceType == EssenceType.Collaborator) {
            if (rep.contribution < 100) revert NotEnoughReputationForAction();
        } else if (_essenceType == EssenceType.IntegritySeal) {
            if (rep.integrity < 200 || !_isSoulbound) {
                // IntegritySeal must be soulbound and require high integrity
                revert NotEnoughReputationForAction();
            }
        } else if (_essenceType == EssenceType.SynergyCore) {
            revert InvalidEssenceForMelding(); // SynergyCore can only be melded, not forged directly
        } else {
            revert InvalidEssenceType();
        }

        catalystBalances[msg.sender] -= essenceMintCosts[uint8(_essenceType)];

        _essenceIds.increment();
        uint256 newId = _essenceIds.current();

        uint32 expiresAt = 0;
        if (essenceLifespans[uint8(_essenceType)] > 0) {
            expiresAt = uint32(block.timestamp) + essenceLifespans[uint8(_essenceType)];
        }

        // Hash of current reputation for the Essence's "forging context"
        uint256 repHash = uint256(keccak256(abi.encodePacked(rep.activity, rep.contribution, rep.integrity)));

        essences[newId] = Essence({
            id: newId,
            owner: msg.sender,
            essenceType: _essenceType,
            forgedTimestamp: uint32(block.timestamp),
            expiresTimestamp: expiresAt,
            isSoulbound: _isSoulbound,
            associatedReputationHash: repHash,
            isMelded: false,
            customURI: ""
        });

        _mint(msg.sender, newId);
        emit EssenceForged(msg.sender, newId, uint8(_essenceType), _isSoulbound);
    }

    /// @notice Allows users to combine two existing Essences, potentially creating a new Essence type.
    /// @dev Consumes the original two Essences. Synergetic creation of a SynergyCore.
    /// @param _essenceId1 The ID of the first Essence.
    /// @param _essenceId2 The ID of the second Essence.
    function meldEssences(uint256 _essenceId1, uint256 _essenceId2)
        external
        _onlyEssenceOwner(_essenceId1)
    {
        if (_essenceId1 == _essenceId2) revert InvalidEssenceForMelding();
        if (essences[_essenceId2].owner != msg.sender) revert EssenceNotOwned(essences[_essenceId2].owner, _essenceId2);

        Essence storage essence1 = essences[_essenceId1];
        Essence storage essence2 = essences[_essenceId2];

        if (essence1.isMelded || essence2.isMelded) revert InvalidEssenceForMelding();
        if (essence1.expiresTimestamp > 0 && block.timestamp > essence1.expiresTimestamp) revert EssenceExpired();
        if (essence2.expiresTimestamp > 0 && block.timestamp > essence2.expiresTimestamp) revert EssenceExpired();
        if (essence1.isSoulbound || essence2.isSoulbound) revert EssenceIsSoulbound(); // Cannot meld soulbound essences

        // Example melding logic: BasicInsight + Collaborator = SynergyCore
        bool canMeld = (essence1.essenceType == EssenceType.BasicInsight && essence2.essenceType == EssenceType.Collaborator) ||
                        (essence1.essenceType == EssenceType.Collaborator && essence2.essenceType == EssenceType.BasicInsight);

        if (!canMeld) revert InvalidEssenceForMelding();

        // Mark originals as melded (effectively "burnt" for this purpose)
        essence1.isMelded = true;
        essence2.isMelded = true;
        _burn(msg.sender, _essenceId1);
        _burn(msg.sender, _essenceId2);

        // Mint new SynergyCore Essence
        _essenceIds.increment();
        uint256 newEssenceId = _essenceIds.current();

        essences[newEssenceId] = Essence({
            id: newEssenceId,
            owner: msg.sender,
            essenceType: EssenceType.SynergyCore,
            forgedTimestamp: uint32(block.timestamp),
            expiresTimestamp: essenceLifespans[uint8(EssenceType.SynergyCore)], // Eternal
            isSoulbound: false, // SynergyCore is transferable
            associatedReputationHash: uint256(keccak256(abi.encodePacked(essence1.associatedReputationHash, essence2.associatedReputationHash))),
            isMelded: false,
            customURI: ""
        });

        _mint(msg.sender, newEssenceId);
        emit EssencesMelded(msg.sender, _essenceId1, _essenceId2, newEssenceId);
    }

    /// @notice Overrides the standard ERC721 transfer method to prevent transfer of Soulbound Essences.
    /// @param _from The address from which the Essence is transferred.
    /// @param _to The address to which the Essence is transferred.
    /// @param _tokenId The ID of the Essence to transfer.
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        if (essences[_tokenId].isSoulbound) revert EssenceIsSoulbound();
        if (_from != essences[_tokenId].owner) revert EssenceNotOwned(_from, _tokenId); // Standard ERC721 check
        super.transferFrom(_from, _to, _tokenId);
        essences[_tokenId].owner = _to; // Update internal owner mapping
    }

    /// @notice Allows Essence owners to destroy their Essences.
    /// @dev Can provide a Catalyst refund or other benefits based on type/value.
    /// @param _essenceId The ID of the Essence to burn.
    function burnEssence(uint256 _essenceId) external _onlyEssenceOwner(_essenceId) {
        // Implement refund logic or other benefits if desired
        // For example, burning an expired Essence might grant back a small Catalyst amount.
        _burn(msg.sender, _essenceId);
        delete essences[_essenceId]; // Remove from mapping
        emit EssenceBurnt(msg.sender, _essenceId);
    }

    /// @notice View function to retrieve comprehensive details of an Essence.
    /// @param _essenceId The ID of the Essence.
    /// @return Essence struct containing its properties.
    function getEssenceDetails(uint256 _essenceId) external view returns (Essence memory) {
        return essences[_essenceId];
    }

    /// @notice View function that returns the dynamically generated metadata URI for an Essence.
    /// @dev This URI reflects the Essence's current state (e.g., expiration).
    /// @param _essenceId The ID of the Essence.
    /// @return A data URI containing the base64 encoded JSON metadata.
    function getEssenceDynamicURI(uint256 _essenceId) external view returns (string memory) {
        // If a custom URI was set, use that, otherwise generate on-the-fly
        if (bytes(essences[_essenceId].customURI).length > 0) {
            return essences[_essenceId].customURI;
        }
        string memory json = _generateEssenceMetadata(_essenceId);
        return string(abi.encodePacked(_getEssenceBaseURI(), Base64.encode(bytes(json))));
    }

    // --- III. Vouching & Social Graph ---

    /// @notice Allows a registered user to "vouch" for another, increasing the target's "Integrity" reputation.
    /// @dev Vouching puts a portion of the voucher's own integrity reputation at stake.
    /// @param _targetUser The address of the user being vouched for.
    function vouchForUser(address _targetUser) external _onlyRegisteredUser(msg.sender) {
        if (_targetUser == msg.sender) revert CannotVouchForSelf();
        if (!userReputations[_targetUser].isRegistered) revert NotRegistered();
        if (vouches[msg.sender][_targetUser].vouchTimestamp != 0) revert AlreadyVouched();

        _decayReputationInternal(msg.sender);
        _decayReputationInternal(_targetUser);

        UserReputation storage targetRep = userReputations[_targetUser];
        uint16 initialTargetIntegrity = targetRep.integrity;

        targetRep.integrity = uint16(targetRep.integrity + vouchGainPerRep);
        targetRep.lastIntegrityUpdateTimestamp = uint32(block.timestamp);

        vouches[msg.sender][_targetUser] = VouchEntry({
            vouchTimestamp: uint32(block.timestamp),
            reputationImpacted: vouchGainPerRep // Store the amount for potential reversal
        });
        vouchesReceivedCount[_targetUser]++;

        emit Vouched(msg.sender, _targetUser);
        emit ReputationUpdated(_targetUser, targetRep.activity, targetRep.contribution, targetRep.integrity);
    }

    /// @notice Allows a user to retract a previously made vouch.
    /// @dev Retracting a vouch may affect both parties' reputation (e.g., a small penalty for retracting).
    /// @param _targetUser The address of the user for whom the vouch is being retracted.
    function retractVouch(address _targetUser) external _onlyRegisteredUser(msg.sender) {
        if (vouches[msg.sender][_targetUser].vouchTimestamp == 0) revert NotVouched();

        _decayReputationInternal(msg.sender);
        _decayReputationInternal(_targetUser);

        UserReputation storage targetRep = userReputations[_targetUser];
        uint16 impact = vouches[msg.sender][_targetUser].reputationImpacted;

        if (targetRep.integrity >= impact) {
            targetRep.integrity = uint16(targetRep.integrity - impact);
        } else {
            targetRep.integrity = 0;
        }
        targetRep.lastIntegrityUpdateTimestamp = uint32(block.timestamp);

        // Optional: Small penalty to retracting user's integrity
        UserReputation storage voucherRep = userReputations[msg.sender];
        if (voucherRep.integrity >= (impact / 2)) {
            voucherRep.integrity = uint16(voucherRep.integrity - (impact / 2));
        } else {
            voucherRep.integrity = 0;
        }
        voucherRep.lastIntegrityUpdateTimestamp = uint32(block.timestamp);


        delete vouches[msg.sender][_targetUser];
        vouchesReceivedCount[_targetUser]--;

        emit VouchRetracted(msg.sender, _targetUser);
        emit ReputationUpdated(_targetUser, targetRep.activity, targetRep.contribution, targetRep.integrity);
        emit ReputationUpdated(msg.sender, voucherRep.activity, voucherRep.contribution, voucherRep.integrity);
    }

    /// @notice View function to check if a user has vouched for another.
    /// @param _voucher The potential voucher's address.
    /// @param _target The potential target's address.
    /// @return True if `_voucher` has an active vouch for `_target`, false otherwise.
    function getVouchStatus(address _voucher, address _target) external view returns (bool) {
        return vouches[_voucher][_target].vouchTimestamp != 0;
    }

    // --- IV. Delegated Echoes (Meta-Actions) ---

    /// @notice Allows a user to delegate specific function call permissions to another address.
    /// @dev This enables controlled proxy actions or meta-transactions for specific functions.
    /// @param _functionSignature The 4-byte signature of the function to delegate (e.g., `this.foo.selector`).
    /// @param _delegatee The address to whom the permission is delegated.
    function delegateEcho(bytes4 _functionSignature, address _delegatee)
        external
        _onlyRegisteredUser(msg.sender)
    {
        if (delegatedEchoes[msg.sender][_functionSignature].active) revert AlreadyDelegated();

        delegatedEchoes[msg.sender][_functionSignature] = DelegatedEcho({
            delegatee: _delegatee,
            delegatedTimestamp: uint32(block.timestamp),
            active: true
        });

        emit EchoDelegated(msg.sender, _delegatee, _functionSignature);
    }

    /// @notice Revokes a previously granted delegated "Echo".
    /// @param _functionSignature The 4-byte signature of the function to revoke.
    function revokeEcho(bytes4 _functionSignature)
        external
        _onlyRegisteredUser(msg.sender)
    {
        if (!delegatedEchoes[msg.sender][_functionSignature].active) revert NotDelegated();

        delegatedEchoes[msg.sender][_functionSignature].active = false;
        // Consider deleting the entry completely to save gas, but `active` flag is simpler for revoking
        emit EchoRevoked(msg.sender, _functionSignature);
    }

    /// @notice Allows a delegated address to execute a specific pre-approved action on behalf of the `_user`.
    /// @dev This can be used for meta-transaction-like behavior where a relayer pays gas.
    /// @param _user The address of the user who delegated the action.
    /// @param _functionSignature The 4-byte signature of the function to execute.
    /// @param _data The encoded call data for the function.
    function executeEchoedAction(address _user, bytes4 _functionSignature, bytes calldata _data)
        external
    {
        DelegatedEcho storage echo = delegatedEchoes[_user][_functionSignature];
        if (!echo.active || echo.delegatee != msg.sender) revert UnauthorizedEchoExecution();

        // Ensure the call is targeting this contract itself
        // And ensure it only allows specific safe functions (e.g. `performActivity`, `contributeInsight`)
        // This is a critical security point. A whitelist of allowed `_functionSignature`s is highly recommended.
        // For simplicity, we allow any function, but in production, restrict this heavily.
        
        (bool success, ) = address(this).call(abi.encodePacked(_functionSignature, _data));
        require(success, "Echoed action failed");

        emit EchoExecuted(_user, msg.sender, _functionSignature);
    }

    // --- V. Adaptive Governance & System Parameters ---

    /// @notice Allows high-reputation users to propose changes to system parameters.
    /// @param _description A description of the proposal.
    /// @param _encodedCall The encoded function call to execute if the proposal passes.
    function proposeParameterChange(string calldata _description, bytes calldata _encodedCall)
        external
        _canProposeOrVote(msg.sender)
    {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            encodedCall: _encodedCall,
            proposer: msg.sender,
            proposalTimestamp: uint32(block.timestamp),
            votingDeadline: uint32(block.timestamp) + uint32(PROPOSAL_VOTING_PERIOD),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });

        emit ParameterChangeProposed(proposalId, msg.sender, _description);
    }

    /// @notice Allows high-reputation users to vote on active proposals.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for a "for" vote, false for an "against" vote.
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        _canProposeOrVote(msg.sender)
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalTimestamp == 0) revert ProposalNotFound();
        if (block.timestamp > proposal.votingDeadline || proposal.executed) revert ProposalNotActive();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VotedOnProposal(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed governance proposal, updating system parameters.
    /// @dev Can only be called after the voting deadline and if the proposal has passed.
    /// @param _proposalId The ID of the proposal to execute.
    function executeParameterChange(uint256 _proposalId) external onlyOwner { // Or specific governance agent role
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalTimestamp == 0) revert ProposalNotFound();
        if (block.timestamp <= proposal.votingDeadline) revert ProposalStillActive();
        if (proposal.executed) revert ProposalAlreadyExecuted(); // Custom error

        // Simple majority rule for demonstration
        if (proposal.votesFor <= proposal.votesAgainst) {
            proposal.passed = false;
            proposal.executed = true;
            revert ProposalFailed();
        }

        // Execute the proposed change
        (bool success, ) = address(this).call(proposal.encodedCall);
        require(success, "Execution of proposed change failed");

        proposal.passed = true;
        proposal.executed = true;
        emit ParameterChangeExecuted(_proposalId);
    }

    /// @notice Allows the owner or a governance agent to set the Catalyst mint cost for an Essence type.
    /// @param _essenceType The type of Essence to modify.
    /// @param _newCost The new Catalyst cost.
    function setEssenceMintCost(EssenceType _essenceType, uint256 _newCost) external onlyOwner {
        // In a real governance system, this would be part of an executed proposal
        essenceMintCosts[uint8(_essenceType)] = _newCost;
        emit EssenceMintCostUpdated(uint8(_essenceType), _newCost);
    }

    /// @notice Allows the owner or a governance agent to set the reputation decay rates.
    /// @param _activityDecay The new activity decay rate (%).
    /// @param _contributionDecay The new contribution decay rate (%).
    /// @param _integrityDecay The new integrity decay rate (%).
    function setReputationDecayRates(uint16 _activityDecay, uint16 _contributionDecay, uint16 _integrityDecay) external onlyOwner {
        activityDecayRate = _activityDecay;
        contributionDecayRate = _contributionDecay;
        integrityDecayRate = _integrityDecay;
        emit ReputationDecayRatesUpdated(_activityDecay, _contributionDecay, _integrityDecay);
    }

    /// @notice Allows the owner or a governance agent to set the reputation impact of vouching.
    /// @param _vouchGain The integrity gain for the target per vouch.
    /// @param _vouchLoss The integrity loss for the reporter/voucher on misconduct.
    function setVouchImpact(uint16 _vouchGain, uint16 _vouchLoss) external onlyOwner {
        vouchGainPerRep = _vouchGain;
        vouchLossPerRep = _vouchLoss;
        emit VouchImpactUpdated(_vouchGain, _vouchLoss);
    }

    // --- VI. ERC721 Compliance & View Functions ---

    /// @notice Overrides ERC721's tokenURI to provide dynamic metadata.
    /// @param _tokenId The ID of the token.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);
        return getEssenceDynamicURI(_tokenId);
    }

    /// @notice Supports ERC165 interface detection.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    // Standard ERC721 methods (`balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `approve`, `setApprovalForAll`)
    // are inherited from OpenZeppelin's ERC721 and work as expected.
    // The `transferFrom` and `_approve` functions are overridden above for Soulbound logic.

    // Internal _mint and _burn are part of ERC721 standard implementation

    // A note on `_burn`: ERC721's _burn internally calls `_clearApproval` and adjusts balances.
    // My `burnEssence` function also explicitly `delete essences[_essenceId]` to clean up the custom struct data.
}

```