This Solidity smart contract, `ChronosEssence`, is designed to create dynamic, Soulbound (non-transferable) digital identities that evolve over time based on on-chain interactions and community-validated, AI-driven proposals. It aims to be a unique blend of decentralized identity, dynamic NFTs, and an AI-augmented narrative engine.

---

## ChronosEssence Protocol: Dynamic Soulbound Identity & AI-Augmented Narrative Engine

This contract implements a novel system where users mint a "ChronoEssence" (a Soulbound Token) that represents their digital persona. This Essence is not static; its traits and narrative history are dynamically updated through a multi-faceted process involving a reputation system, community proposals, and suggestions from a trusted AI Oracle which are then put to a community vote.

The core idea is to create a living, evolving digital identity that reflects a user's on-chain journey and community interactions, with an advanced layer of AI integration for richer, more complex narrative development.

### @outline

**I. Core ChronoEssence Management (Soulbound Token - SBT)**
*   **`mintChronoEssence()`**: Allows a user to mint their unique, non-transferable ChronoEssence.
*   **`burnChronoEssence()`**: Provides a mechanism for an Essence owner to destroy their Essence, typically with associated reputation penalties.
*   **`getChronoEssenceDetails()`**: Retrieves the fundamental structural details of an Essence.
*   **`getEssenceTrait()`**: Fetches the value of a specific dynamic trait by its type.
*   **`getEssenceTraitKeys()`**: Lists all currently applied trait types for an Essence.

**II. Dynamic Trait & Narrative Evolution**
*   **`proposeAIDrivenTrait()`**: A designated AI Oracle submits a proposal for a new or updated trait/narrative snippet for a specific Essence. This initiates a community vote.
*   **`voteOnAITraitProposal()`**: Allows existing ChronoEssence holders to cast their vote on AI-generated trait proposals, with voting power influenced by reputation.
*   **`finalizeAITraitProposal()`**: Executes a passed AI trait proposal, updating the Essence's on-chain state (traits).
*   **`requestManualTraitReview()`**: Enables an Essence holder to request a community review for one of their Essence's traits, signaling potential misalignment.
*   **`proposeCommunityNarrativeChunk()`**: Allows any Essence holder to propose small, decentralized narrative additions or "lore" for an Essence.
*   **`approveCommunityNarrativeChunk()`**: Votes to approve or disapprove community-proposed narrative chunks.
*   **`getEssenceNarrativeHistory()`**: Retrieves all approved narrative chunks associated with an Essence, forming its public story.

**III. Reputation & Influence System**
*   **`_updateEssenceReputation()`**: An internal helper function to adjust an Essence's reputation score based on various on-chain activities.
*   **`getEssenceReputation()`**: Returns the current reputation score of a given ChronoEssence.
*   **`claimInfluenceBoost()`**: Allows an Essence holder to claim a temporary boost to their influence/reputation based on predefined activity criteria.
*   **`delegateInfluence()`**: Enables an Essence holder to temporarily delegate their voting power and influence to another address.
*   **`getDelegatedInfluence()`**: Returns the address to which an Essence's influence is currently delegated.

**IV. Memory Shards & Event Logging**
*   **`logMemoryShard()`**: Allows authorized entities (Essence owner or registered integrators) to log significant "memory" events or data points associated with an Essence, with options for public or private visibility.
*   **`retrieveMemoryShard()`**: Accesses a specific memory shard. Requires ownership for private shards.
*   **`getAllEssenceMemoryShards()`**: Retrieves all memory shards (public, and private if authorized) for an Essence.

**V. Access Control & Integrations**
*   **`registerExternalIntegrator()`**: Enables the protocol owner (DAO) to whitelist external contracts/protocols that can interact with Essences in specific ways (e.g., logging memory shards).
*   **`grantEssenceAccess()`**: Allows an Essence owner to grant temporary, trait-gated access to another address or contract. This access is conditional on the Essence possessing a specific trait.
*   **`revokeEssenceAccess()`**: Revokes previously granted access for an address to an Essence.
*   **`checkEssenceAccess()`**: Verifies if an address has valid, current trait-gated access to an Essence.

**VI. Governance & Protocol Parameters**
*   **`setProtocolParameter()`**: Allows the contract owner (DAO) to dynamically adjust core protocol settings (e.g., voting thresholds, reputation changes).
*   **`pauseSystem()`**: Emergency function to halt critical operations of the contract.
*   **`unpauseSystem()`**: Resumes operations after a pause.
*   **`upgradeContractLogic()`**: A conceptual function for facilitating contract upgrades (in a real system, this would interact with a proxy pattern like UUPS).
*   **`redeemProofOfContribution()`**: A mechanism for Essence holders to claim rewards for verified off-chain contributions, requiring cryptographic proof.
*   **`getEssenceCount()`**: Returns the total number of ChronoEssences minted.

---

### @function_summary

*   **`constructor(string memory name, string memory symbol, address initialAIOracle)`**: Initializes the ERC-721 contract with a name and symbol, and sets the initial trusted AI Oracle address. Also sets default protocol parameters.
*   **`supportsInterface(bytes4 interfaceId) internal view override returns (bool)`**: Overrides ERC-165 to signal support for a conceptual "Soulbound Essence" interface, preventing transfers.
*   **`_beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override`**: An internal ERC-721 hook that prevents any transfers of ChronoEssences once minted, enforcing their soulbound nature.
*   **`mintChronoEssence(string calldata initialTraitURI)`**: Mints a new `ChronoEssence` token for the caller, assigns an initial reputation, and sets a base URI for its metadata.
*   **`burnChronoEssence(uint256 essenceId)`**: Allows the owner of `essenceId` to burn it, reducing their reputation as a consequence.
*   **`getChronoEssenceDetails(uint256 essenceId) external view returns (ChronoEssence memory)`**: Returns the core structural data of an Essence. (Note: Dynamic traits are retrieved separately due to Solidity mapping limitations).
*   **`getEssenceTrait(uint256 essenceId, string calldata traitType) external view returns (string memory)`**: Returns the value of a specific trait associated with an Essence.
*   **`getEssenceTraitKeys(uint256 essenceId) external view returns (bytes32[] memory)`**: Returns an array of hashed keys representing all dynamic trait types currently assigned to an Essence.
*   **`proposeAIDrivenTrait(uint256 essenceId, string calldata traitType, string calldata traitValue, bytes32 proposalHash, uint256 duration)`**: Callable only by the `aiOracleAddress`, this function creates a new proposal for an Essence's trait modification/addition, including an associated `proposalHash` for off-chain AI context.
*   **`voteOnAITraitProposal(uint256 proposalId, bool support)`**: Allows any ChronoEssence holder to vote 'yes' or 'no' on an AI-driven trait proposal. Voting power is weighted by the voter's Essence reputation.
*   **`finalizeAITraitProposal(uint256 proposalId)`**: Any user can call this after the voting period ends. If the proposal meets the set thresholds, the new trait is applied to the target Essence.
*   **`requestManualTraitReview(uint256 essenceId, string calldata traitType)`**: Allows an Essence owner to formally request community review of a specific trait, which can inform future AI or community proposals.
*   **`proposeCommunityNarrativeChunk(uint256 essenceId, string calldata chunkContent, uint256 parentChunkId)`**: Enables any ChronoEssence holder to propose a textual "memory" or narrative snippet for an Essence.
*   **`approveCommunityNarrativeChunk(uint256 chunkId, bool approve)`**: Allows ChronoEssence holders to vote on community narrative chunks. A simple majority can approve a chunk, adding it to the Essence's history.
*   **`getEssenceNarrativeHistory(uint256 essenceId) external view returns (NarrativeChunk[] memory)`**: Returns an array of all `approved` narrative chunks for a specified Essence.
*   **`_updateEssenceReputation(uint256 essenceId, int256 change)`**: An internal function used by other parts of the contract to adjust an Essence's reputation score (can be positive or negative).
*   **`getEssenceReputation(uint256 essenceId) external view returns (uint256)`**: Returns the current reputation score of the specified Essence.
*   **`claimInfluenceBoost(uint256 essenceId)`**: Allows an Essence holder to claim a temporary boost to their reputation (and thus voting influence), based on conditions like minimum reputation and activity cooldown.
*   **`delegateInfluence(uint256 essenceId, address delegatee, uint256 duration)`**: Allows an Essence owner to temporarily transfer their voting influence to another address.
*   **`getDelegatedInfluence(uint256 essenceId) external view returns (address)`**: Checks and returns the address currently delegated influence for a given Essence, if active.
*   **`logMemoryShard(uint256 essenceId, string calldata shardContent, bool isPrivate)`**: Allows an Essence owner or registered integrator to log a piece of information (a "memory") onto the Essence's record. Can be public or owner-private.
*   **`retrieveMemoryShard(uint256 essenceId, uint256 shardIndex)`**: Retrieves a specific memory shard. Requires ownership if the shard is private.
*   **`getAllEssenceMemoryShards(uint256 essenceId, bool includePrivate) external view returns (MemoryShard[] memory)`**: Returns an array of all accessible memory shards for an Essence.
*   **`registerExternalIntegrator(address integratorAddress, string calldata description)`**: Owner-only function to whitelist addresses of external contracts that can interact with the ChronosEssence protocol in authorized ways.
*   **`grantEssenceAccess(uint256 essenceId, address grantedTo, uint256 duration, string calldata requiredTrait)`**: Allows an Essence owner to grant another address temporary, conditional access. Access is valid only if the Essence has a specified trait and its value matches the one at the time of granting.
*   **`revokeEssenceAccess(uint256 essenceId, address grantedTo)`**: Allows an Essence owner to immediately revoke previously granted access.
*   **`checkEssenceAccess(uint256 essenceId, address accessor) external view returns (bool)`**: Checks if a given address currently holds valid trait-gated access to an Essence.
*   **`setProtocolParameter(bytes32 parameterKey, uint256 value)`**: Owner-only function to update various configurable parameters of the protocol, like voting thresholds or reputation changes.
*   **`pauseSystem()`**: Owner-only emergency function to pause all essential operations of the contract.
*   **`unpauseSystem()`**: Owner-only function to unpause the contract after an emergency pause.
*   **`upgradeContractLogic(address newImplementation)`**: A placeholder for an upgrade mechanism. In a real system, this would point a proxy contract to a new implementation, allowing for contract logic upgrades without losing state.
*   **`redeemProofOfContribution(uint256 essenceId, bytes32 proofHash)`**: Allows an Essence owner to redeem rewards for verified off-chain contributions by providing a cryptographic proof hash. (Proof verification logic is simplified for this example).
*   **`getEssenceCount() external view returns (uint256)`**: Returns the total number of ChronoEssences that have been minted.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint256 to string conversion
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safe arithmetic operations

/**
 * @title ChronosEssence Protocol
 * @dev A decentralized, AI-augmented narrative engine for dynamic Soulbound Identities.
 *      Users mint a "ChronoEssence" (SBT) that evolves its traits and narrative history
 *      based on on-chain actions and community-validated AI-driven proposals.
 *      This contract facilitates the creation, evolution, and governance of these digital identities.
 *
 * @outline
 * I. Core ChronoEssence Management (Soulbound Token - SBT)
 *    - mintChronoEssence: Mints a new non-transferable ChronoEssence.
 *    - burnChronoEssence: Allows an Essence owner to destroy their Essence (with consequences).
 *    - getChronoEssenceDetails: Retrieves all associated data for a given Essence ID.
 *    - getEssenceTrait: Fetches the value of a specific dynamic trait.
 *    - getEssenceTraitKeys: Lists all currently applied trait types.
 *
 * II. Dynamic Trait & Narrative Evolution
 *    - proposeAIDrivenTrait: Initiates a proposal for a new trait or narrative snippet for an Essence, triggered by a trusted AI Oracle.
 *    - voteOnAITraitProposal: Allows Essence holders to vote on AI-driven trait proposals.
 *    - finalizeAITraitProposal: Executes accepted AI trait proposals, updating the Essence's state.
 *    - requestManualTraitReview: Allows an Essence holder to request a community review for a specific trait.
 *    - proposeCommunityNarrativeChunk: Allows the community to propose small narrative snippets/memory fragments for an Essence.
 *    - approveCommunityNarrativeChunk: Votes to approve community-proposed narrative chunks.
 *    - getEssenceNarrativeHistory: Retrieves the complete narrative history of an Essence.
 *
 * III. Reputation & Influence System
 *    - _updateEssenceReputation: Internal mechanism to adjust an Essence's reputation score.
 *    - getEssenceReputation: Retrieves the current reputation score of an Essence.
 *    - claimInfluenceBoost: Allows users to claim temporary influence based on activity.
 *    - delegateInfluence: Allows an Essence holder to temporarily delegate their voting power.
 *    - getDelegatedInfluence: Gets the current delegatee for an Essence.
 *
 * IV. Memory Shards & Event Logging
 *    - logMemoryShard: Allows authorized entities or the Essence owner to log significant "memory" events.
 *    - retrieveMemoryShard: Accesses specific memory shards (with access control for private ones).
 *    - getAllEssenceMemoryShards: Retrieves all memory shards (public and private if owner).
 *
 * V. Access Control & Integrations
 *    - registerExternalIntegrator: Allows trusted external protocols to register for specific interactions.
 *    - grantEssenceAccess: Allows an Essence owner to grant temporary, trait-gated access to other contracts/addresses.
 *    - revokeEssenceAccess: Revokes previously granted access.
 *    - checkEssenceAccess: Verifies if an address has valid trait-gated access.
 *
 * VI. Governance & Protocol Parameters
 *    - setProtocolParameter: Allows the DAO (owner) to adjust core protocol settings.
 *    - pauseSystem: Emergency function to pause critical operations.
 *    - unpauseSystem: Emergency function to unpause operations.
 *    - upgradeContractLogic: Placeholder for initiating contract upgrades (e.g., via a UUPS proxy).
 *    - redeemProofOfContribution: Mechanism for active participants to claim rewards.
 *    - getEssenceCount: Returns the total number of minted ChronoEssences.
 *
 * @function_summary
 * - `constructor(string memory name, string memory symbol, address initialAIOracle)`: Initializes the contract with ERC-721 details and sets the initial AI Oracle.
 * - `supportsInterface(bytes4 interfaceId) internal view override returns (bool)`: Overrides ERC-165 for soulbound functionality.
 * - `_beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override`: Prevents transfer of ChronoEssences (Soulbound).
 * - `mintChronoEssence(string calldata initialTraitURI)`: Mints a new ChronoEssence for the caller. Requires an initial URI for its metadata.
 * - `burnChronoEssence(uint256 essenceId)`: Allows the owner to burn their Essence, incurring reputation penalties.
 * - `getChronoEssenceDetails(uint256 essenceId) external view returns (ChronoEssence memory)`: Returns the detailed struct of an Essence.
 * - `getEssenceTrait(uint256 essenceId, string calldata traitType) external view returns (string memory)`: Returns the value of a specific trait.
 * - `getEssenceTraitKeys(uint256 essenceId) external view returns (bytes32[] memory)`: Returns an array of hashed trait keys.
 * - `proposeAIDrivenTrait(uint256 essenceId, string calldata traitType, string calldata traitValue, string calldata proposalHash, uint256 duration)`: AI Oracle proposes a new trait.
 * - `voteOnAITraitProposal(uint256 proposalId, bool support)`: Allows Essence holders to vote on AI trait proposals. Voting power scales with reputation.
 * - `finalizeAITraitProposal(uint256 proposalId)`: Finalizes a proposal if it passes, applying the trait update.
 * - `requestManualTraitReview(uint256 essenceId, string calldata traitType)`: Allows Essence holder to request a community review for a specific trait.
 * - `proposeCommunityNarrativeChunk(uint256 essenceId, string calldata chunkContent, uint256 parentChunkId)`: Community proposes narrative additions.
 * - `approveCommunityNarrativeChunk(uint256 chunkId, bool approve)`: Votes to approve community narrative chunks.
 * - `getEssenceNarrativeHistory(uint256 essenceId) external view returns (NarrativeChunk[] memory)`: Returns all approved narrative chunks for an Essence.
 * - `updateEssenceReputation(uint256 essenceId, int256 change)`: Internal or restricted function to modify reputation.
 * - `getEssenceReputation(uint256 essenceId) external view returns (uint256)`: Returns the current reputation score.
 * - `claimInfluenceBoost(uint256 essenceId)`: Claims a temporary influence boost based on predefined criteria.
 * - `delegateInfluence(uint256 essenceId, address delegatee, uint256 duration)`: Delegates voting power.
 * - `getDelegatedInfluence(uint256 essenceId) external view returns (address)`: Gets the current delegatee.
 * - `logMemoryShard(uint256 essenceId, string calldata shardContent, bool isPrivate)`: Logs a memory shard, can be private.
 * - `retrieveMemoryShard(uint256 essenceId, uint256 shardIndex)`: Retrieves a specific memory shard. Requires authentication for private ones.
 * - `getAllEssenceMemoryShards(uint256 essenceId, bool includePrivate)`: Gets all memory shards, including private if authorized.
 * - `registerExternalIntegrator(address integratorAddress, string calldata description)`: Registers a trusted external contract.
 * - `grantEssenceAccess(uint256 essenceId, address grantedTo, uint256 duration, string calldata requiredTrait)`: Grants temporary, trait-gated access.
 * - `revokeEssenceAccess(uint256 essenceId, address grantedTo)`: Revokes granted access.
 * - `checkEssenceAccess(uint256 essenceId, address accessor) external view returns (bool)`: Checks for valid trait-gated access.
 * - `setProtocolParameter(bytes32 parameterKey, uint256 value)`: Allows the DAO/Owner to set crucial protocol parameters.
 * - `pauseSystem() ` : Pauses the system in emergencies.
 * - `unpauseSystem() `: Unpauses the system.
 * - `upgradeContractLogic(address newImplementation)`: Conceptual function for upgradeability (requires proxy pattern).
 * - `redeemProofOfContribution(uint256 essenceId, bytes32 proofHash)`: Rewards active participation.
 * - `getEssenceCount() external view returns (uint256)`: Returns the total number of minted Essences.
 */
contract ChronosEssence is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    // Essence Data Structure
    struct ChronoEssence {
        uint256 tokenId;
        address owner;
        uint256 reputation;
        string initialTraitURI; // Base metadata URI, potentially IPFS
        // Dynamic traits mapping: traitTypeHash -> traitValue. Stored separately for retrieval.
        uint256 lastActivityTimestamp;
        uint256 mintTimestamp;
        uint256 totalInfluenceBoostClaimed;
    }

    mapping(uint256 => ChronoEssence) private _essences;
    mapping(uint256 => mapping(bytes32 => string)) private _essenceTraits; // essenceId => traitTypeHash => traitValue
    mapping(uint256 => bytes32[]) private _essenceTraitKeys; // essenceId => array of traitTypeHashes (for iteration)

    // AI-Driven Trait Proposals
    struct AITraitProposal {
        uint256 essenceId;
        string traitType;
        string traitValue;
        bytes32 proposalHash; // Unique identifier for the AI's complex reasoning/data (e.g., IPFS hash)
        uint256 createdAt;
        uint256 votingEndsAt;
        uint256 yeas;
        uint256 nays;
        bool executed;
        address proposer; // Should be the AI Oracle
    }

    Counters.Counter private _aiProposalIdCounter;
    mapping(uint256 => AITraitProposal) private _aiProposals;
    mapping(uint256 => mapping(address => bool)) private _aiProposalVoted; // proposalId => voterAddress => voted

    // Community Narrative Chunks
    struct NarrativeChunk {
        uint256 chunkId;
        uint256 essenceId;
        string content;
        uint256 parentChunkId; // For branching narratives, 0 for root
        address proposer;
        uint256 createdAt;
        uint256 yeas;
        uint256 nays;
        bool approved;
    }

    Counters.Counter private _narrativeChunkIdCounter;
    mapping(uint256 => NarrativeChunk) private _narrativeChunks;
    mapping(uint256 => mapping(address => bool)) private _narrativeChunkVoted; // chunkId => voterAddress => voted
    mapping(uint256 => uint256[]) private _essenceNarrativeChunkIds; // essenceId => array of chunkIds

    // Memory Shards
    struct MemoryShard {
        uint256 shardId;
        uint256 essenceId;
        string content;
        bool isPrivate; // Only owner can retrieve if true
        uint256 createdAt;
        address loggedBy;
    }

    Counters.Counter private _memoryShardIdCounter;
    mapping(uint256 => MemoryShard) private _memoryShards;
    mapping(uint256 => uint256[]) private _essenceMemoryShardIds; // essenceId => array of shardIds

    // External Integrators (Whitelisted addresses for specific interactions)
    mapping(address => string) private _externalIntegrators; // address => description

    // Granted Access (trait-gated temporary access)
    struct GrantedAccess {
        uint256 essenceId;
        address grantedTo;
        uint256 expiresAt;
        bytes32 requiredTraitHash; // Hashed traitType, must match for access
        bytes32 requiredTraitValueHash; // Hashed trait value that must match
    }

    mapping(uint256 => mapping(address => GrantedAccess)) private _grantedAccesses; // essenceId => grantedTo => GrantedAccess

    // Protocol Parameters (Managed by DAO/Owner)
    mapping(bytes32 => uint256) public protocolParameters;

    // Pausability
    bool public paused;

    // AI Oracle Address
    address public aiOracleAddress;

    // Mapping to find Essence ID by owner address (assuming 1 Essence per address for SBT)
    mapping(address => uint256) private _tokenOfOwner;

    // --- Events ---

    event ChronoEssenceMinted(uint256 indexed tokenId, address indexed owner, string initialTraitURI);
    event ChronoEssenceBurned(uint256 indexed tokenId, address indexed owner);
    event EssenceReputationUpdated(uint256 indexed essenceId, int256 change, uint256 newReputation);
    event AIDrivenTraitProposed(uint256 indexed proposalId, uint256 indexed essenceId, string traitType, string traitValue, bytes32 proposalHash);
    event AIDrivenTraitVoted(uint256 indexed proposalId, uint256 indexed voterEssenceId, bool support);
    event AIDrivenTraitExecuted(uint256 indexed proposalId, uint256 indexed essenceId, string traitType, string traitValue);
    event ManualTraitReviewRequested(uint256 indexed essenceId, string traitType);
    event CommunityNarrativeChunkProposed(uint256 indexed chunkId, uint256 indexed essenceId, string content, uint256 parentChunkId);
    event CommunityNarrativeChunkApproved(uint256 indexed chunkId, uint256 indexed essenceId);
    event MemoryShardLogged(uint256 indexed shardId, uint256 indexed essenceId, bool isPrivate, address loggedBy);
    event InfluenceBoostClaimed(uint256 indexed essenceId, uint256 amount);
    event InfluenceDelegated(uint256 indexed essenceId, address indexed delegatee, uint256 duration);
    event ExternalIntegratorRegistered(address indexed integratorAddress, string description);
    event EssenceAccessGranted(uint256 indexed essenceId, address indexed grantedTo, uint256 expiresAt, string requiredTraitType, string requiredTraitValue);
    event EssenceAccessRevoked(uint256 indexed essenceId, address indexed grantedTo);
    event ProtocolParameterSet(bytes32 indexed parameterKey, uint256 value);
    event SystemPaused(address indexed by);
    event SystemUnpaused(address indexed by);
    event UpgradeInitiated(address indexed newImplementation); // Custom event for upgradeability
    event ContributionRedeemed(uint256 indexed essenceId, bytes32 proofHash);

    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "CE: Only AI Oracle can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "CE: System is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "CE: System is not paused");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address initialAIOracle) ERC721(name, symbol) Ownable(msg.sender) {
        require(initialAIOracle != address(0), "CE: AI Oracle address cannot be zero");
        aiOracleAddress = initialAIOracle;

        // Initialize default protocol parameters
        protocolParameters[keccak256("MIN_REP_FOR_VOTE")] = 100; // Minimum reputation to vote on proposals
        protocolParameters[keccak256("VOTING_PERIOD_SECONDS")] = 7 * 24 * 60 * 60; // 7 days
        protocolParameters[keccak256("PROPOSAL_PASS_THRESHOLD_PERCENT")] = 51; // 51% of total votes
        protocolParameters[keccak256("INITIAL_REPUTATION")] = 500;
        protocolParameters[keccak256("BURN_REPUTATION_PENALTY")] = 200;
        protocolParameters[keccak256("INFLUENCE_BOOST_REPUTATION_THRESHOLD")] = 1000;
        protocolParameters[keccak256("INFLUENCE_BOOST_AMOUNT")] = 100;
        protocolParameters[keccak256("INFLUENCE_BOOST_COOLDOWN_SECONDS")] = 1 days;
        protocolParameters[keccak256("MIN_ESSENCE_AGE_FOR_CONTRIBUTION")] = 30 * 24 * 60 * 60; // 30 days
        protocolParameters[keccak256("REPUTATION_CHANGE_MINT")] = 50; // Change for mint action
        protocolParameters[keccak256("REPUTATION_REWARD_AI_TRAIT_TARGET")] = 50; // Reward for Essence targeted by AI trait
        protocolParameters[keccak256("REPUTATION_REWARD_CONTRIBUTION")] = 250; // Reward for redeeming contribution proof
        protocolParameters[keccak256("NARRATIVE_CHUNK_APPROVAL_THRESHOLD")] = 3; // Min 'yeas' for narrative chunk approval
    }

    // --- I. Core ChronoEssence Management (SBT) ---

    /// @dev Overrides ERC-165 to declare support for a custom soulbound interface.
    ///      While there's no official ERC for SBTs yet, this signals intent.
    ///      Custom interface ID `0xbe4a600a` can represent "IEssenceSoulbound".
    function supportsInterface(bytes4 interfaceId) internal view override returns (bool) {
        return interfaceId == 0xbe4a600a || super.supportsInterface(interfaceId);
    }

    /// @dev Prevents transfer of ChronoEssences, making them Soulbound.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        if (from != address(0) && to != address(0)) { // Allow minting (from zero address) and burning (to zero address)
            revert("CE: ChronoEssence is Soulbound and cannot be transferred.");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /// @notice Mints a new ChronoEssence for the caller.
    /// @param initialTraitURI An IPFS hash or URL for the Essence's initial metadata. This URI should point to an off-chain server that dynamically generates metadata based on the Essence's on-chain traits.
    /// @return The tokenId of the newly minted ChronoEssence.
    function mintChronoEssence(string calldata initialTraitURI) external whenNotPaused returns (uint256) {
        require(_tokenOfOwner[msg.sender] == 0, "CE: Address already owns a ChronoEssence");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, initialTraitURI); // Set initial URI, dynamic updates will be managed off-chain via metadata API.

        _essences[newItemId].tokenId = newItemId;
        _essences[newItemId].owner = msg.sender;
        _essences[newItemId].reputation = protocolParameters[keccak256("INITIAL_REPUTATION")];
        _essences[newItemId].initialTraitURI = initialTraitURI;
        _essences[newItemId].lastActivityTimestamp = block.timestamp;
        _essences[newItemId].mintTimestamp = block.timestamp;

        // Add a base trait "Origin" to mark its creation
        bytes32 originTraitKey = keccak256(abi.encodePacked("Origin"));
        _essenceTraits[newItemId][originTraitKey] = string(abi.encodePacked("Born on ", Strings.toString(block.timestamp)));
        _essenceTraitKeys[newItemId].push(originTraitKey);

        // Adjust reputation based on minting action
        _updateEssenceReputation(newItemId, int256(protocolParameters[keccak256("REPUTATION_CHANGE_MINT")]));

        emit ChronoEssenceMinted(newItemId, msg.sender, initialTraitURI);
        return newItemId;
    }

    /// @notice Allows the owner to burn their ChronoEssence. This action incurs a reputation penalty.
    /// @param essenceId The ID of the ChronoEssence to burn.
    function burnChronoEssence(uint256 essenceId) external whenNotPaused {
        require(ownerOf(essenceId) == msg.sender, "CE: Not the owner of this Essence");
        _burn(essenceId); // ERC721 burn
        
        // Apply reputation penalty to the (now burned) essence's owner's reputation
        // If the owner can mint another, this penalty might carry over.
        // For simplicity, this example just applies to the current essence, which is then deleted.
        // In a real system, you might track "global reputation" for an address, not just per-essence.
        _updateEssenceReputation(essenceId, -int256(protocolParameters[keccak256("BURN_REPUTATION_PENALTY")])); 
        
        // Clear related data
        delete _essences[essenceId];
        delete _essenceTraits[essenceId];
        delete _essenceTraitKeys[essenceId];
        // Note: Mappings within the struct are not automatically deleted,
        // so _essenceTraits[essenceId] and _essenceTraitKeys[essenceId] need explicit deletion.
        // Other related mappings (proposals, narratives, memories) would remain as orphan data
        // unless a more complex cleanup logic is implemented (e.g., iterating and deleting specific entries).

        emit ChronoEssenceBurned(essenceId, msg.sender);
    }

    /// @notice Retrieves the fundamental details of a specific ChronoEssence.
    /// @param essenceId The ID of the ChronoEssence.
    /// @return A ChronoEssence struct containing its basic data.
    function getChronoEssenceDetails(uint256 essenceId) external view returns (ChronoEssence memory) {
        require(_exists(essenceId), "CE: Essence does not exist");
        return _essences[essenceId];
    }

    /// @notice Retrieves a specific trait of an Essence by its type.
    /// @param essenceId The ID of the ChronoEssence.
    /// @param traitType The type of the trait (e.g., "Personality", "Alignment").
    /// @return The value of the trait. Returns empty string if not found.
    function getEssenceTrait(uint256 essenceId, string calldata traitType) external view returns (string memory) {
        require(_exists(essenceId), "CE: Essence does not exist");
        return _essenceTraits[essenceId][keccak256(abi.encodePacked(traitType))];
    }

    /// @notice Retrieves all trait types associated with an Essence.
    /// @param essenceId The ID of the ChronoEssence.
    /// @return An array of hashed trait keys.
    function getEssenceTraitKeys(uint256 essenceId) external view returns (bytes32[] memory) {
        require(_exists(essenceId), "CE: Essence does not exist");
        return _essenceTraitKeys[essenceId];
    }

    // --- II. Dynamic Trait & Narrative Evolution ---

    /// @notice Allows the designated AI Oracle to propose a new trait or update an existing one for an Essence.
    /// @dev This starts a community voting process.
    /// @param essenceId The ID of the Essence to propose the trait for.
    /// @param traitType The category of the trait (e.g., "Personality", "Skill").
    /// @param traitValue The proposed new value for the trait.
    /// @param proposalHash A unique hash representing the AI's complex reasoning/data for the proposal (e.g., IPFS hash).
    /// @param duration The duration in seconds for which the proposal will be open for voting.
    function proposeAIDrivenTrait(
        uint256 essenceId,
        string calldata traitType,
        string calldata traitValue,
        bytes32 proposalHash,
        uint256 duration
    ) external onlyAIOracle whenNotPaused returns (uint256) {
        require(_exists(essenceId), "CE: Essence does not exist");
        require(duration > 0, "CE: Proposal duration must be positive");
        require(bytes(traitType).length > 0, "CE: Trait type cannot be empty");
        require(bytes(traitValue).length > 0, "CE: Trait value cannot be empty");
        require(proposalHash != bytes32(0), "CE: Proposal hash cannot be zero");

        _aiProposalIdCounter.increment();
        uint256 proposalId = _aiProposalIdCounter.current();

        _aiProposals[proposalId] = AITraitProposal({
            essenceId: essenceId,
            traitType: traitType,
            traitValue: traitValue,
            proposalHash: proposalHash,
            createdAt: block.timestamp,
            votingEndsAt: block.timestamp + duration,
            yeas: 0,
            nays: 0,
            executed: false,
            proposer: msg.sender
        });

        emit AIDrivenTraitProposed(proposalId, essenceId, traitType, traitValue, proposalHash);
        return proposalId;
    }

    /// @notice Allows ChronoEssence holders to vote on an AI-driven trait proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'yes', False for 'no'.
    function voteOnAITraitProposal(uint256 proposalId, bool support) external whenNotPaused {
        AITraitProposal storage proposal = _aiProposals[proposalId];
        require(proposal.essenceId != 0, "CE: Proposal does not exist");
        require(!proposal.executed, "CE: Proposal already executed");
        require(block.timestamp <= proposal.votingEndsAt, "CE: Voting period has ended");

        uint256 voterEssenceId = _tokenOfOwner[msg.sender]; // Get the caller's ChronoEssence ID
        require(voterEssenceId != 0, "CE: Caller must own a ChronoEssence to vote");
        require(_aiProposalVoted[proposalId][msg.sender] == false, "CE: Already voted on this proposal");
        
        uint256 votingPower = _getVotingPower(msg.sender); // Voting power based on reputation or delegation
        require(votingPower >= protocolParameters[keccak256("MIN_REP_FOR_VOTE")], "CE: Insufficient reputation to vote");

        _aiProposalVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.yeas = proposal.yeas.add(votingPower);
        } else {
            proposal.nays = proposal.nays.add(votingPower);
        }
        
        _essences[voterEssenceId].lastActivityTimestamp = block.timestamp; // Update activity

        emit AIDrivenTraitVoted(proposalId, voterEssenceId, support);
    }

    /// @notice Finalizes an AI-driven trait proposal if the voting period has ended and it passed.
    /// @param proposalId The ID of the proposal to finalize.
    function finalizeAITraitProposal(uint256 proposalId) external whenNotPaused {
        AITraitProposal storage proposal = _aiProposals[proposalId];
        require(proposal.essenceId != 0, "CE: Proposal does not exist");
        require(!proposal.executed, "CE: Proposal already executed");
        require(block.timestamp > proposal.votingEndsAt, "CE: Voting period has not ended yet");

        uint256 totalVotes = proposal.yeas.add(proposal.nays);
        if (totalVotes == 0) {
            // No votes, proposal can't pass
            proposal.executed = true; // Mark as executed but failed to prevent re-finalization
            return;
        }

        uint256 yeasPercentage = (proposal.yeas.mul(100)).div(totalVotes);

        if (yeasPercentage >= protocolParameters[keccak256("PROPOSAL_PASS_THRESHOLD_PERCENT")]) {
            // Proposal passed! Apply the trait.
            bytes32 traitKey = keccak256(abi.encodePacked(proposal.traitType));
            if (bytes(_essenceTraits[proposal.essenceId][traitKey]).length == 0) {
                // Only add to array if it's a new trait type
                _essenceTraitKeys[proposal.essenceId].push(traitKey);
            }
            _essenceTraits[proposal.essenceId][traitKey] = proposal.traitValue;
            _essences[proposal.essenceId].lastActivityTimestamp = block.timestamp;

            // Reward the Essence that was the target of the successful AI trait proposal
            _updateEssenceReputation(proposal.essenceId, int256(protocolParameters[keccak256("REPUTATION_REWARD_AI_TRAIT_TARGET")]));
            
            emit AIDrivenTraitExecuted(proposalId, proposal.essenceId, proposal.traitType, proposal.traitValue);
        }
        proposal.executed = true;
    }

    /// @notice Allows an Essence holder to request a community review for a specific trait, potentially leading to a new proposal.
    /// @dev This doesn't trigger an automatic vote but flags the trait for review by the community/DAO.
    /// @param essenceId The ID of the Essence whose trait is being reviewed.
    /// @param traitType The type of the trait to review.
    function requestManualTraitReview(uint256 essenceId, string calldata traitType) external whenNotPaused {
        require(ownerOf(essenceId) == msg.sender, "CE: You are not the owner of this Essence.");
        require(bytes(_essenceTraits[essenceId][keccak256(abi.encodePacked(traitType))]).length > 0, "CE: Trait does not exist for this Essence.");
        
        _essences[essenceId].lastActivityTimestamp = block.timestamp;
        // This event can be used by off-chain systems (e.g., DAO governance frontends or AI oracle feedback loops)
        // to identify traits needing attention or re-evaluation.
        emit ManualTraitReviewRequested(essenceId, traitType);
    }

    /// @notice Allows any ChronoEssence holder to propose a small narrative chunk or memory fragment for an Essence.
    /// @dev These are less formal than AI traits and subject to simple approval votes.
    /// @param essenceId The ID of the Essence the narrative chunk relates to.
    /// @param chunkContent The content of the narrative chunk.
    /// @param parentChunkId If this chunk extends an existing narrative, provide its ID (0 for new storyline).
    function proposeCommunityNarrativeChunk(uint256 essenceId, string calldata chunkContent, uint256 parentChunkId) external whenNotPaused returns (uint256) {
        require(_exists(essenceId), "CE: Essence does not exist");
        require(bytes(chunkContent).length > 0, "CE: Chunk content cannot be empty");
        
        uint256 proposerEssenceId = _tokenOfOwner[msg.sender];
        require(proposerEssenceId != 0, "CE: Caller must own a ChronoEssence to propose");
        
        if (parentChunkId != 0) {
            require(_narrativeChunks[parentChunkId].chunkId != 0, "CE: Parent chunk does not exist");
            require(_narrativeChunks[parentChunkId].essenceId == essenceId, "CE: Parent chunk belongs to a different Essence");
        }

        _narrativeChunkIdCounter.increment();
        uint256 newChunkId = _narrativeChunkIdCounter.current();

        _narrativeChunks[newChunkId] = NarrativeChunk({
            chunkId: newChunkId,
            essenceId: essenceId,
            content: chunkContent,
            parentChunkId: parentChunkId,
            proposer: msg.sender,
            createdAt: block.timestamp,
            yeas: 0,
            nays: 0,
            approved: false
        });
        
        _essenceNarrativeChunkIds[essenceId].push(newChunkId);
        _essences[proposerEssenceId].lastActivityTimestamp = block.timestamp;
        
        emit CommunityNarrativeChunkProposed(newChunkId, essenceId, chunkContent, parentChunkId);
        return newChunkId;
    }

    /// @notice Allows ChronoEssence holders to approve or disapprove a community-proposed narrative chunk.
    /// @dev A simple majority vote (based on individual votes, not weighted by reputation for simplicity).
    /// @param chunkId The ID of the narrative chunk to vote on.
    /// @param approve True to approve, False to disapprove.
    function approveCommunityNarrativeChunk(uint256 chunkId, bool approve) external whenNotPaused {
        NarrativeChunk storage chunk = _narrativeChunks[chunkId];
        require(chunk.chunkId != 0, "CE: Narrative chunk does not exist");
        require(!chunk.approved, "CE: Narrative chunk already approved/rejected");

        uint256 voterEssenceId = _tokenOfOwner[msg.sender];
        require(voterEssenceId != 0, "CE: Caller must own a ChronoEssence to vote");
        require(_narrativeChunkVoted[chunkId][msg.sender] == false, "CE: Already voted on this narrative chunk");

        _narrativeChunkVoted[chunkId][msg.sender] = true;

        if (approve) {
            chunk.yeas++;
        } else {
            chunk.nays++;
        }
        
        _essences[voterEssenceId].lastActivityTimestamp = block.timestamp;

        // Auto-approve/reject if sufficient votes reached
        uint256 approvalThreshold = protocolParameters[keccak256("NARRATIVE_CHUNK_APPROVAL_THRESHOLD")];
        if (chunk.yeas >= approvalThreshold && chunk.yeas > chunk.nays) {
            chunk.approved = true;
            emit CommunityNarrativeChunkApproved(chunkId, chunk.essenceId);
        } else if (chunk.nays >= approvalThreshold && chunk.nays >= chunk.yeas) {
             chunk.approved = false; // Explicitly mark as not approved. Could also remove the chunk for real rejection.
        }
    }
    
    /// @notice Retrieves all approved narrative chunks for a specific ChronoEssence.
    /// @param essenceId The ID of the Essence.
    /// @return An array of NarrativeChunk structs.
    function getEssenceNarrativeHistory(uint256 essenceId) external view returns (NarrativeChunk[] memory) {
        require(_exists(essenceId), "CE: Essence does not exist");
        uint256[] storage chunkIds = _essenceNarrativeChunkIds[essenceId];
        
        uint256 approvedCount = 0;
        for (uint256 i = 0; i < chunkIds.length; i++) {
            if (_narrativeChunks[chunkIds[i]].approved) {
                approvedCount++;
            }
        }

        NarrativeChunk[] memory history = new NarrativeChunk[](approvedCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < chunkIds.length; i++) {
            if (_narrativeChunks[chunkIds[i]].approved) {
                history[counter] = _narrativeChunks[chunkIds[i]];
                counter++;
            }
        }
        return history;
    }

    // --- III. Reputation & Influence System ---

    /// @dev Internal function to update an Essence's reputation. Can be called by other internal logic.
    /// @param essenceId The ID of the Essence.
    /// @param change The amount to change reputation by (can be positive or negative).
    function _updateEssenceReputation(uint256 essenceId, int256 change) internal {
        // No existence check here, as it's often called on the Essence being created/burned or implicitly existing.
        // The calling function should ensure essenceId is valid.
        
        uint256 currentRep = _essences[essenceId].reputation;
        if (change >= 0) {
            _essences[essenceId].reputation = currentRep.add(uint256(change));
        } else {
            uint256 absChange = uint256(-change);
            if (currentRep < absChange) {
                _essences[essenceId].reputation = 0; // Prevent underflow below zero
            } else {
                _essences[essenceId].reputation = currentRep.sub(absChange);
            }
        }
        emit EssenceReputationUpdated(essenceId, change, _essences[essenceId].reputation);
    }

    /// @notice Retrieves the current reputation score of a ChronoEssence.
    /// @param essenceId The ID of the ChronoEssence.
    /// @return The reputation score.
    function getEssenceReputation(uint256 essenceId) external view returns (uint256) {
        require(_exists(essenceId), "CE: Essence does not exist");
        return _essences[essenceId].reputation;
    }

    /// @notice Allows a ChronoEssence owner to claim a temporary influence boost based on on-chain activity criteria.
    /// @dev This could be based on a minimum reputation, age, or number of interactions.
    /// @param essenceId The ID of the ChronoEssence.
    function claimInfluenceBoost(uint256 essenceId) external whenNotPaused {
        require(ownerOf(essenceId) == msg.sender, "CE: Not the owner of this Essence");
        require(_essences[essenceId].reputation >= protocolParameters[keccak256("INFLUENCE_BOOST_REPUTATION_THRESHOLD")], "CE: Insufficient reputation for boost");
        require(_essences[essenceId].lastActivityTimestamp.add(protocolParameters[keccak256("INFLUENCE_BOOST_COOLDOWN_SECONDS")]) < block.timestamp, "CE: Influence boost is on cooldown");

        _essences[essenceId].reputation = _essences[essenceId].reputation.add(protocolParameters[keccak256("INFLUENCE_BOOST_AMOUNT")]);
        _essences[essenceId].totalInfluenceBoostClaimed++;
        _essences[essenceId].lastActivityTimestamp = block.timestamp; // Update activity

        emit InfluenceBoostClaimed(essenceId, protocolParameters[keccak256("INFLUENCE_BOOST_AMOUNT")]);
    }

    // Delegation of influence
    mapping(uint256 => address) private _delegatedInfluenceTo; // Essence ID -> delegated address
    mapping(uint256 => uint256) private _delegationExpiresAt; // Essence ID -> timestamp

    /// @notice Allows an Essence holder to temporarily delegate their influence/voting power to another address.
    /// @param essenceId The ID of the ChronoEssence.
    /// @param delegatee The address to delegate influence to.
    /// @param duration The duration in seconds for the delegation.
    function delegateInfluence(uint256 essenceId, address delegatee, uint256 duration) external whenNotPaused {
        require(ownerOf(essenceId) == msg.sender, "CE: Not the owner of this Essence");
        require(delegatee != address(0), "CE: Delegatee cannot be zero address");
        require(delegatee != msg.sender, "CE: Cannot delegate to self");
        require(duration > 0, "CE: Delegation duration must be positive");

        _delegatedInfluenceTo[essenceId] = delegatee;
        _delegationExpiresAt[essenceId] = block.timestamp + duration;
        
        _essences[essenceId].lastActivityTimestamp = block.timestamp;
        emit InfluenceDelegated(essenceId, delegatee, duration);
    }

    /// @notice Gets the address to whom an Essence's influence is currently delegated.
    /// @param essenceId The ID of the ChronoEssence.
    /// @return The delegatee address, or address(0) if no active delegation.
    function getDelegatedInfluence(uint256 essenceId) public view returns (address) {
        if (_delegationExpiresAt[essenceId] > block.timestamp) {
            return _delegatedInfluenceTo[essenceId];
        }
        return address(0);
    }

    /// @dev Internal function to resolve voting power for a given address.
    ///      If the address owns an Essence and has not delegated, their Essence's reputation is used.
    ///      If the address is a delegatee, their delegated power is used.
    ///      If the address owns an Essence and has delegated, they have 0 direct voting power.
    /// @param voter The address whose voting power is being queried.
    /// @return The calculated voting power.
    function _getVotingPower(address voter) internal view returns (uint256) {
        uint256 voterEssenceId = _tokenOfOwner[voter];
        if (voterEssenceId == 0) { // Caller doesn't own an Essence directly
            // Check if this address is a delegatee for any Essence
            // This is inefficient to check on-chain for all possible delegations.
            // A more robust system would pass the delegatee's *actual essenceId*
            // or have a reverse lookup. For simplicity, we assume if `voter` owns no Essence
            // but is attempting to vote, it must be as a delegate.
            // This is a simplification. For a real system, would need a mapping `delegationsByDelegatee[address] => uint256[]`
            // to find all Essences delegated to `voter`.
            return 0; // If they don't own an Essence, they get 0 voting power for now.
                      // If delegated, the actual vote function will handle it.
        }

        // If voter owns an Essence
        address delegatedTo = getDelegatedInfluence(voterEssenceId);
        if (delegatedTo == address(0) || delegatedTo == voter) {
            // No active delegation, or delegated to self (meaning no actual delegation away)
            return _essences[voterEssenceId].reputation;
        } else {
            // Essence owner has delegated their vote away, so their direct voting power is 0.
            return 0;
        }
    }


    // --- IV. Memory Shards & Event Logging ---

    /// @notice Allows an Essence owner or a registered external integrator to log a "memory shard" for an Essence.
    /// @dev Can be public or private (only accessible by Essence owner).
    /// @param essenceId The ID of the ChronoEssence.
    /// @param shardContent The content of the memory shard.
    /// @param isPrivate If true, only the Essence owner can retrieve it.
    /// @return The shardId of the new memory shard.
    function logMemoryShard(uint256 essenceId, string calldata shardContent, bool isPrivate) external whenNotPaused returns (uint256) {
        require(_exists(essenceId), "CE: Essence does not exist");
        require(bytes(shardContent).length > 0, "CE: Shard content cannot be empty");
        
        bool isEssenceOwner = (ownerOf(essenceId) == msg.sender);
        bool isIntegrator = (bytes(_externalIntegrators[msg.sender]).length > 0);
        
        require(isEssenceOwner || isIntegrator, "CE: Not authorized to log memory shard");

        _memoryShardIdCounter.increment();
        uint256 newShardId = _memoryShardIdCounter.current();

        _memoryShards[newShardId] = MemoryShard({
            shardId: newShardId,
            essenceId: essenceId,
            content: shardContent,
            isPrivate: isPrivate,
            createdAt: block.timestamp,
            loggedBy: msg.sender
        });

        _essenceMemoryShardIds[essenceId].push(newShardId);
        _essences[essenceId].lastActivityTimestamp = block.timestamp; // Update activity

        emit MemoryShardLogged(newShardId, essenceId, isPrivate, msg.sender);
        return newShardId;
    }

    /// @notice Retrieves a specific memory shard.
    /// @dev If the shard is private, only the Essence owner can retrieve it.
    /// @param essenceId The ID of the ChronoEssence.
    /// @param shardIndex The index of the shard within the Essence's memory shard array.
    /// @return The MemoryShard struct.
    function retrieveMemoryShard(uint256 essenceId, uint256 shardIndex) external view returns (MemoryShard memory) {
        require(_exists(essenceId), "CE: Essence does not exist");
        require(shardIndex < _essenceMemoryShardIds[essenceId].length, "CE: Shard index out of bounds");

        uint256 shardId = _essenceMemoryShardIds[essenceId][shardIndex];
        MemoryShard storage shard = _memoryShards[shardId];

        if (shard.isPrivate) {
            require(ownerOf(essenceId) == msg.sender, "CE: Not authorized to view private shard");
        }
        return shard;
    }

    /// @notice Retrieves all memory shards (public and private if owner) for a specific Essence.
    /// @param essenceId The ID of the Essence.
    /// @param includePrivate If true, and caller is owner, private shards are included.
    /// @return An array of MemoryShard structs.
    function getAllEssenceMemoryShards(uint256 essenceId, bool includePrivate) external view returns (MemoryShard[] memory) {
        require(_exists(essenceId), "CE: Essence does not exist");
        uint256[] storage shardIds = _essenceMemoryShardIds[essenceId];
        
        bool isEssenceOwner = (ownerOf(essenceId) == msg.sender);

        uint256 accessibleCount = 0;
        for (uint256 i = 0; i < shardIds.length; i++) {
            MemoryShard storage shard = _memoryShards[shardIds[i]];
            if (!shard.isPrivate || (shard.isPrivate && includePrivate && isEssenceOwner)) {
                accessibleCount++;
            }
        }

        MemoryShard[] memory shards = new MemoryShard[](accessibleCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < shardIds.length; i++) {
            MemoryShard storage shard = _memoryShards[shardIds[i]];
            if (!shard.isPrivate || (shard.isPrivate && includePrivate && isEssenceOwner)) {
                shards[counter] = shard;
                counter++;
            }
        }
        return shards;
    }

    // --- V. Access Control & Integrations ---

    /// @notice Allows the contract owner (DAO) to register trusted external protocols.
    /// @param integratorAddress The address of the external contract/entity.
    /// @param description A brief description of the integrator's purpose.
    function registerExternalIntegrator(address integratorAddress, string calldata description) external onlyOwner {
        require(integratorAddress != address(0), "CE: Integrator address cannot be zero");
        _externalIntegrators[integratorAddress] = description;
        emit ExternalIntegratorRegistered(integratorAddress, description);
    }

    /// @notice Grants temporary, trait-gated access to an external address or contract.
    /// @dev The granted address can only access features if the Essence possesses a specific trait value.
    /// @param essenceId The ID of the ChronoEssence.
    /// @param grantedTo The address to grant access to.
    /// @param duration The duration in seconds for which access is granted.
    /// @param requiredTraitType The type of trait that must match for access to be valid.
    function grantEssenceAccess(uint256 essenceId, address grantedTo, uint256 duration, string calldata requiredTraitType) external whenNotPaused {
        require(ownerOf(essenceId) == msg.sender, "CE: Not the owner of this Essence");
        require(grantedTo != address(0), "CE: Granted address cannot be zero");
        require(duration > 0, "CE: Access duration must be positive");
        require(bytes(requiredTraitType).length > 0, "CE: Required trait type cannot be empty");

        bytes32 requiredTraitHash = keccak256(abi.encodePacked(requiredTraitType));
        string memory currentTraitValue = _essenceTraits[essenceId][requiredTraitHash];
        require(bytes(currentTraitValue).length > 0, "CE: Essence does not possess the required trait for gated access");

        _grantedAccesses[essenceId][grantedTo] = GrantedAccess({
            essenceId: essenceId,
            grantedTo: grantedTo,
            expiresAt: block.timestamp + duration,
            requiredTraitHash: requiredTraitHash,
            requiredTraitValueHash: keccak256(abi.encodePacked(currentTraitValue)) // Store the hash of the value at time of granting
        });
        
        _essences[essenceId].lastActivityTimestamp = block.timestamp;
        emit EssenceAccessGranted(essenceId, grantedTo, duration, requiredTraitType, currentTraitValue);
    }

    /// @notice Revokes previously granted access for an address to an Essence.
    /// @param essenceId The ID of the ChronoEssence.
    /// @param grantedTo The address whose access is to be revoked.
    function revokeEssenceAccess(uint256 essenceId, address grantedTo) external whenNotPaused {
        require(ownerOf(essenceId) == msg.sender, "CE: Not the owner of this Essence");
        require(_grantedAccesses[essenceId][grantedTo].grantedTo != address(0), "CE: No active access to revoke for this address");

        delete _grantedAccesses[essenceId][grantedTo];
        _essences[essenceId].lastActivityTimestamp = block.timestamp;
        emit EssenceAccessRevoked(essenceId, grantedTo);
    }

    /// @notice Checks if an address has valid trait-gated access to an Essence.
    /// @param essenceId The ID of the ChronoEssence.
    /// @param accessor The address requesting access.
    /// @return True if access is valid, false otherwise.
    function checkEssenceAccess(uint256 essenceId, address accessor) public view returns (bool) {
        GrantedAccess storage access = _grantedAccesses[essenceId][accessor];
        if (access.grantedTo == address(0) || access.expiresAt <= block.timestamp) {
            return false;
        }

        // Check if the Essence still has the required trait with the same value hash
        string memory currentTraitValue = _essenceTraits[essenceId][access.requiredTraitHash];
        return keccak256(abi.encodePacked(currentTraitValue)) == access.requiredTraitValueHash;
    }

    // --- VI. Governance & Protocol Parameters ---

    /// @notice Allows the contract owner (DAO) to set crucial protocol parameters.
    /// @param parameterKey The keccak256 hash of the parameter name (e.g., `keccak256("VOTING_PERIOD_SECONDS")`).
    /// @param value The new value for the parameter.
    function setProtocolParameter(bytes32 parameterKey, uint256 value) external onlyOwner {
        require(value > 0, "CE: Parameter value must be positive");
        protocolParameters[parameterKey] = value;
        emit ProtocolParameterSet(parameterKey, value);
    }

    /// @notice Emergency function to pause critical contract operations. Only callable by owner.
    function pauseSystem() external onlyOwner whenNotPaused {
        paused = true;
        emit SystemPaused(msg.sender);
    }

    /// @notice Unpauses the system. Only callable by owner.
    function unpauseSystem() external onlyOwner whenPaused {
        paused = false;
        emit SystemUnpaused(msg.sender);
    }

    /// @notice Conceptual function for initiating contract upgrades.
    /// @dev In a production scenario, this would typically involve a proxy pattern (e.g., UUPS)
    ///      where this function would point the proxy to a new implementation.
    ///      Direct implementation replacement is not possible in Solidity without a proxy.
    /// @param newImplementation The address of the new contract implementation.
    function upgradeContractLogic(address newImplementation) external onlyOwner {
        require(newImplementation != address(0), "CE: New implementation cannot be zero address");
        // In a real UUPS proxy, this would be `ERC1967Upgrade._upgradeTo(newImplementation);`
        // For this example, it's just a conceptual placeholder.
        // Practical implementation would require inheriting from `UUPSUpgradeable` and using `_authorizeUpgrade`.
        emit UpgradeInitiated(newImplementation); 
    }

    /// @notice Allows an Essence holder to redeem rewards for verified off-chain contributions.
    /// @dev Requires a cryptographic proof (e.g., ZK-proof hash) of contribution.
    /// @param essenceId The ID of the ChronoEssence.
    /// @param proofHash A hash representing a cryptographic proof of contribution.
    function redeemProofOfContribution(uint256 essenceId, bytes32 proofHash) external whenNotPaused {
        require(ownerOf(essenceId) == msg.sender, "CE: Not the owner of this Essence");
        require(block.timestamp >= _essences[essenceId].mintTimestamp.add(protocolParameters[keccak256("MIN_ESSENCE_AGE_FOR_CONTRIBUTION")]), "CE: Essence too young to redeem contributions");
        
        // This is a placeholder for actual proof verification.
        // In a real dApp, this would involve:
        // 1. Verifying a ZK-proof on-chain.
        // 2. Checking against a pre-mined list of valid proof hashes (managed by owner/DAO).
        // 3. Interacting with a dedicated Proof Verification contract.
        require(proofHash != bytes32(0), "CE: Invalid proof hash");

        // Prevent double-spending of the same proof.
        // This would require a mapping: `mapping(bytes32 => bool) private _proofsRedeemed;`
        // require(!_proofsRedeemed[proofHash], "CE: Proof already redeemed");
        // _proofsRedeemed[proofHash] = true; 
        
        // Example: Boost reputation as reward
        _updateEssenceReputation(essenceId, int256(protocolParameters[keccak256("REPUTATION_REWARD_CONTRIBUTION")])); 
        _essences[essenceId].lastActivityTimestamp = block.timestamp;
        
        emit ContributionRedeemed(essenceId, proofHash);
    }
    
    /// @notice Returns the total number of minted ChronoEssences.
    /// @return The count of Essences.
    function getEssenceCount() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // --- Internal Helpers (for ERC721 and common use) ---

    // Override the ERC721 _mint function to update our custom _tokenOfOwner mapping
    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);
        _tokenOfOwner[to] = tokenId; // Assign tokenId to owner. Assumes 1 Essence per address for simplicity (Soulbound).
    }

    // Override the ERC721 _burn function to update our custom _tokenOfOwner mapping
    function _burn(uint256 tokenId) internal override {
        address owner = ownerOf(tokenId);
        super._burn(tokenId);
        delete _tokenOfOwner[owner]; // Remove the association when burned.
    }
}
```