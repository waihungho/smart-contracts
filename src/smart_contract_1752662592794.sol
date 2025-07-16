The "GenesisNexus" protocol is designed as a decentralized platform for managing intellectual property (IP) and fostering collaborative content creation. It blends several advanced blockchain concepts: Soulbound Tokens (SBTs) for non-transferable IP and reputation, Dynamic NFTs (dNFTs) for evolving derivative works, simulated AI oracle integration for creative assistance, and programmable multi-party royalty distribution.

---

**Outline and Function Summary**

**Contract Name:** `GenesisNexus: Protocol for Decentralized Intellectual Property & Dynamic Content Rights`

**Description:**
This contract establishes a novel ecosystem for decentralized intellectual property (IP) management and collaborative content creation. It integrates concepts of Soulbound Tokens (SBTs) for reputation and initial IP ownership, dynamic Non-Fungible Tokens (NFTs) for derivative works, AI oracle integration for creative assistance, and programmable, multi-party royalty distribution.

**Core Features:**
1.  **Genesis Ideas (SBTs):** Initial, non-transferable IP proposals, represented as Soulbound ERC-721 NFTs. They are the foundational concepts upon which derivative works can be built.
2.  **Collaboration & Attestation:** A reputation system built on SBTs, allowing users to attest to skills and record contributions to Genesis Ideas, influencing a user's on-chain reputation score.
3.  **Derivative Works (dNFTs):** Tradeable ERC-721 NFTs linked to Genesis Ideas, with the potential for dynamic traits and metadata updates via AI or authorized parties.
4.  **Dynamic Royalties:** Flexible, multi-party royalty splits that can be adjusted by the derivative work's owner/creator, and a mechanism for dispute resolution.
5.  **AI Oracle Integration (Simulated):** An interface to a simulated off-chain AI service for creative input, such as generating traits or evaluating content, with a consensus mechanism for adopting AI suggestions.
6.  **Time-Locked IP:** Mechanisms to vest or time-lock IP rights for both Genesis Ideas and Derivative Works, preventing transfer or certain modifications until a specified time.

---

**Function Summary:**

**I. Core Infrastructure & Configuration**
1.  `constructor(address _aiOracleAddress)`: Initializes the contract, setting the AI oracle address and the deployer as the admin.
2.  `setAIOracleAddress(address _newOracleAddress)`: Updates the address of the trusted AI oracle. (Admin-only)
3.  `pauseContract()`: Pauses contract operations in an emergency, preventing most state-changing functions. (Admin-only)
4.  `unpauseContract()`: Unpauses contract operations. (Admin-only)
5.  `setDefaultRoyaltyRecipient(address _recipient)`: Sets a default recipient for collected royalties, useful for unallocated funds or as a fallback. (Admin-only)

**II. Genesis Idea Management (Soulbound ERC-721 based)**
6.  `proposeGenesisIdea(string memory _ideaURI)`: Mints a new Soulbound Genesis Idea NFT, representing a core IP concept. These tokens are initially non-transferable (Soulbound) to ensure creator ownership and foster organic development.
7.  `retireGenesisIdea(uint256 _tokenId)`: Allows the original creator to burn a Genesis Idea, subject to conditions (e.g., no derivative works linked, not time-locked).
8.  `delegateIdeaDevelopment(uint256 _tokenId, address _delegate)`: Assigns a primary developer for a Genesis Idea, enabling the delegate to manage collaborators and AI requests. (Creator-only)
9.  `revokeIdeaDevelopmentDelegation(uint256 _tokenId)`: Revokes the primary development delegation for a Genesis Idea. (Creator-only)
10. `getGenesisIdeaDetails(uint256 _tokenId)`: Retrieves comprehensive details about a Genesis Idea, including its creator, URI, delegate, and time-lock status.

**III. Collaboration & Attestation System (SBTs / Reputation)**
11. `attestSkill(address _user, string memory _skillURI)`: Mints a Soulbound Token (SBT) as a skill attestation for a user. These attestations are non-transferable and contribute to a user's reputation score.
12. `revokeAttestation(address _user, uint256 _attestationId)`: Allows an attester to revoke a previously issued skill attestation, impacting the attested user's reputation.
13. `contributeToIdea(uint256 _genesisId, string memory _contributionURI)`: Records a contribution made by `msg.sender` to a specific Genesis Idea, potentially boosting the contributor's reputation.
14. `getAttestationsForUser(address _user)`: Retrieves all skill attestations issued to a specific user.
15. `getUserReputationScore(address _user)`: Calculates and returns a dynamic reputation score for a user based on the number of attestations received and contributions made.

**IV. Derivative Work Creation & Dynamic Rights (ERC-721 based)**
16. `requestAIDrivenTraitGeneration(uint256 _genesisId, string memory _promptURI, uint256 _requestId)`: Requests the AI oracle to generate potential traits/metadata for a new Derivative Work. (Genesis Idea Creator/Delegate only)
17. `submitAIConsensusVote(uint256 _genesisId, uint256 _requestId, uint256 _aiResultIndex, bool _approve)`: Allows users to cast a reputation-weighted vote on proposed AI-generated traits from a specific request.
18. `mintDerivativeWork(uint256 _genesisId, string memory _baseURI, uint256 _aiApprovedResultIndex, address[] memory _initialRoyaltyRecipients, uint256[] memory _initialRoyaltyBps)`: Mints a new Derivative Work NFT, potentially using AI-approved traits, and sets the initial multi-party royalty distribution.
19. `setDynamicRoyaltySplit(uint256 _derivativeId, address[] memory _recipients, uint256[] memory _bps)`: Adjusts the multi-party, dynamically adjusted royalty split for a Derivative Work. (Derivative Work Owner/Creator only)
20. `claimRoyalties(uint256 _derivativeId, address _recipient)`: Allows an authorized recipient to claim their share of accrued royalties from a Derivative Work. (Placeholder for actual revenue distribution)
21. `updateDerivativeWorkMetadata(uint256 _derivativeId, string memory _newURI)`: Allows authorized parties (e.g., original creator, delegate, or current owner) to update the metadata URI for a Derivative Work, enabling dynamic NFT (dNFT) functionality.
22. `transferDerivativeWorkOwnership(address _from, address _to, uint256 _derivativeId)`: Transfers ownership of a Derivative Work NFT, adhering to ERC721 standards while respecting time-locks.

**V. Advanced Governance & IP Control**
23. `timeLockIntellectualProperty(uint256 _tokenId, uint256 _lockEndTime, bool _isGenesisIdea)`: Places a Genesis Idea or Derivative Work under a time-lock, preventing transfer or certain modifications until the lock expires. (Creator/Owner only)
24. `extendTimeLock(uint256 _tokenId, uint256 _newLockEndTime, bool _isGenesisIdea)`: Extends an existing time-lock period for an IP asset. (Creator/Owner only, new time must be later than current)
25. `resolveRoyaltyDispute(uint256 _derivativeId, address _disputedRecipient, uint256 _newBps)`: Allows a designated dispute resolver (currently admin) to adjust a specific royalty share for a Derivative Work in cases of disagreement or dispute.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721, IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // Using interface for metadata
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
// import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // Not used directly in this example for simplicity
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Not used directly in this example for simplicity

// Custom utility for simple non-reverting counter
library Counters {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// Interface for a simulated AI Oracle
interface IAIOracle {
    enum AIResultStatus { Pending, Approved, Rejected, Disputed }

    struct AIResult {
        string uri; // URI to AI generated content/traits
        uint256 votesFor;
        uint256 votesAgainst;
        AIResultStatus status;
        // In a real oracle, this might be a mapping or just an external query.
        // mapping(address => bool) hasVoted; // internal tracking specific to the oracle
    }

    // Requests generation and emits an event for the results
    function requestGeneration(uint256 _genesisId, string calldata _promptURI, uint256 _requestId) external;
    
    // Allows GenesisNexus to query the status and content of results
    function getResult(uint256 _requestId, uint256 _resultIndex) external view returns (AIResult memory);
    function getResultsCount(uint256 _requestId) external view returns (uint256);

    // Allows users (or GenesisNexus on their behalf) to submit reputation-weighted votes
    function submitVote(uint256 _requestId, uint256 _resultIndex, bool _approve) external; 
}

contract GenesisNexus is IERC721, IERC721Metadata, IERC165 {
    using Counters for Counters.Counter;
    using Address for address payable; // For sending native currency

    // --- State Variables ---

    // Admin & Pausability
    address private _admin;
    bool private _paused;

    // AI Oracle
    IAIOracle private _aiOracle;

    // Default Royalty Recipient
    address public defaultRoyaltyRecipient;

    // Counters for NFTs and Attestations
    Counters.Counter private _genesisIdeaTokenIdCounter;
    Counters.Counter private _derivativeWorkTokenIdCounter;
    Counters.Counter private _attestationIdCounter;

    // --- Data Structures ---

    // Genesis Idea (Soulbound NFT initially)
    struct GenesisIdea {
        uint256 tokenId;
        address creator;
        string uri;
        address developmentDelegate; // Can be delegated to another address
        bool isSoulbound; // True initially, can change under certain conditions (not implemented here)
        uint256 timeLockEnd; // For time-locking IP, 0 if not locked
    }

    // Derivative Work (Tradeable ERC721 NFT)
    struct DerivativeWork {
        uint256 tokenId;
        uint256 genesisIdeaId; // Link to the parent Genesis Idea
        address creator; // Who minted it
        string uri; // Current metadata URI (dynamic)
        mapping(address => uint256) royaltyBps; // Recipient => Basis Points (e.g., 100 = 1%)
        uint256 totalRoyaltyBps; // Sum of all royaltyBps for validation (max 10000)
        mapping(address => uint256) accruedRoyalties; // Placeholder for ERC20 token => amount pending claim
        uint256 timeLockEnd; // For time-locking IP, 0 if not locked
    }

    // Skill Attestation (Soulbound Token - SBT)
    struct Attestation {
        uint256 id;
        address attester; // Who attested
        address attestedUser; // Who was attested
        string uri; // URI describing the skill/attestation
        uint256 timestamp;
    }

    // Contribution to a Genesis Idea
    struct Contribution {
        uint256 id;
        uint256 genesisId;
        address contributor;
        string uri; // URI describing the contribution
        uint256 timestamp;
    }

    // Mappings for storing data
    mapping(uint256 => GenesisIdea) private _genesisIdeas;
    mapping(uint256 => address) private _genesisIdeaOwners; // Explicitly track owner for ERC721 for GenesisIdea (even if SBT)
    mapping(address => uint256[]) private _genesisIdeaOwnedTokens; // For balanceOf/tokensOfOwner lookup for Genesis Ideas

    mapping(uint256 => DerivativeWork) private _derivativeWorks;
    mapping(uint256 => address) private _derivativeWorkOwners; // Explicitly track owner for ERC721 for DerivativeWork
    mapping(address => uint256[]) private _derivativeWorkOwnedTokens; // For balanceOf/tokensOfOwner lookup for Derivative Works

    mapping(uint256 => Attestation) private _attestations;
    mapping(address => uint256[]) private _attestationsIssuedBy; // Attestations initiated by this user
    mapping(address => uint256[]) private _attestationsForUser; // Attestations received by this user

    mapping(uint256 => Contribution[]) private _contributionsToIdea; // Contributions grouped by Genesis Idea
    mapping(address => Contribution[]) private _contributionsByUser; // Contributions grouped by User

    // Caches for ERC721 Metadata
    mapping(uint256 => string) private _genesisIdeaTokenURIs;
    mapping(uint256 => string) private _derivativeWorkTokenURIs;

    // --- ERC721 Approvals ---
    mapping(uint256 => address) private _tokenApprovals; // Approved address for tokenId
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Operator approval for all tokens of an owner

    // --- Events ---
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event ContractPaused(address account);
    event ContractUnpaused(address account);
    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event DefaultRoyaltyRecipientSet(address indexed recipient);

    event GenesisIdeaProposed(uint256 indexed tokenId, address indexed creator, string uri);
    event GenesisIdeaRetired(uint256 indexed tokenId);
    event IdeaDevelopmentDelegated(uint256 indexed tokenId, address indexed delegate);
    event IdeaDevelopmentDelegationRevoked(uint256 indexed tokenId, address indexed delegate);
    event GenesisIdeaIPTimeLocked(uint256 indexed tokenId, uint256 lockEndTime);

    event SkillAttested(uint256 indexed attestationId, address indexed attester, address indexed attestedUser, string uri);
    event AttestationRevoked(uint256 indexed attestationId);
    event ContributionRecorded(uint256 indexed genesisId, uint256 indexed contributionId, address indexed contributor);

    event DerivativeWorkMinted(uint256 indexed tokenId, uint256 indexed genesisIdeaId, address indexed creator, string uri);
    event DynamicRoyaltySplitSet(uint256 indexed derivativeId, address[] recipients, uint256[] bps);
    event RoyaltiesClaimed(uint256 indexed derivativeId, address indexed recipient, uint256 amount);
    event DerivativeWorkMetadataUpdated(uint256 indexed derivativeId, string newUri);
    event DerivativeWorkIPTimeLocked(uint256 indexed tokenId, uint256 lockEndTime);
    event RoyaltyDisputeResolved(uint256 indexed derivativeId, address indexed recipient, uint256 newBps);

    // ERC721 Events (re-declared to avoid importing full OZ contract)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == _admin, "GenesisNexus: Caller is not the admin");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "GenesisNexus: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "GenesisNexus: Contract is not paused");
        _;
    }

    modifier onlyGenesisIdeaCreatorOrDelegate(uint256 _tokenId) {
        GenesisIdea storage idea = _genesisIdeas[_tokenId];
        require(idea.tokenId != 0, "GenesisNexus: Genesis Idea does not exist");
        require(idea.creator == msg.sender || idea.developmentDelegate == msg.sender, "GenesisNexus: Not creator or delegate");
        _;
    }

    modifier onlyDerivativeWorkOwnerOrCreator(uint256 _tokenId) {
        DerivativeWork storage work = _derivativeWorks[_tokenId];
        require(work.tokenId != 0, "GenesisNexus: Derivative Work does not exist");
        require(_derivativeWorkOwners[_tokenId] == msg.sender || work.creator == msg.sender, "GenesisNexus: Not owner or creator");
        _;
    }

    // --- Constructor ---
    constructor(address _aiOracleAddress) {
        require(_aiOracleAddress != address(0), "GenesisNexus: AI Oracle address cannot be zero");
        _admin = msg.sender;
        _aiOracle = IAIOracle(_aiOracleAddress);
        defaultRoyaltyRecipient = msg.sender; // Set initial default
        emit AdminTransferred(address(0), _admin);
    }

    // --- I. Core Infrastructure & Configuration ---

    /// @notice Updates the address of the trusted AI oracle.
    /// @param _newOracleAddress The new address for the AI oracle.
    function setAIOracleAddress(address _newOracleAddress) external onlyAdmin {
        require(_newOracleAddress != address(0), "GenesisNexus: New AI Oracle address cannot be zero");
        emit AIOracleAddressUpdated(address(_aiOracle), _newOracleAddress);
        _aiOracle = IAIOracle(_newOracleAddress);
    }

    /// @notice Pauses contract operations in an emergency.
    function pauseContract() external onlyAdmin whenNotPaused {
        _paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses contract operations.
    function unpauseContract() external onlyAdmin whenPaused {
        _paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Sets a default recipient for collected royalties.
    /// @param _recipient The address to set as the default royalty recipient.
    function setDefaultRoyaltyRecipient(address _recipient) external onlyAdmin {
        require(_recipient != address(0), "GenesisNexus: Recipient cannot be zero address");
        defaultRoyaltyRecipient = _recipient;
        emit DefaultRoyaltyRecipientSet(_recipient);
    }

    // --- II. Genesis Idea Management (Soulbound ERC-721 based) ---

    /// @notice Mints a new Soulbound Genesis Idea NFT, representing a core IP concept.
    ///         These tokens are initially non-transferable (Soulbound) to ensure creator ownership
    ///         and foster organic development.
    /// @param _ideaURI The URI pointing to the metadata of the Genesis Idea.
    /// @return The tokenId of the newly minted Genesis Idea.
    function proposeGenesisIdea(string memory _ideaURI) external whenNotPaused returns (uint256) {
        _genesisIdeaTokenIdCounter.increment();
        uint256 newId = _genesisIdeaTokenIdCounter.current();

        _genesisIdeas[newId] = GenesisIdea({
            tokenId: newId,
            creator: msg.sender,
            uri: _ideaURI,
            developmentDelegate: address(0), // No delegate initially
            isSoulbound: true,
            timeLockEnd: 0
        });

        _genesisIdeaOwners[newId] = msg.sender;
        _genesisIdeaOwnedTokens[msg.sender].push(newId);
        _genesisIdeaTokenURIs[newId] = _ideaURI;

        emit Transfer(address(0), msg.sender, newId); // ERC721 Mint Event
        emit GenesisIdeaProposed(newId, msg.sender, _ideaURI);
        return newId;
    }

    /// @notice Allows the original creator to burn a Genesis Idea.
    ///         Only possible if no derivative works are linked to it and it's not time-locked.
    /// @param _tokenId The ID of the Genesis Idea to retire.
    function retireGenesisIdea(uint256 _tokenId) external whenNotPaused {
        GenesisIdea storage idea = _genesisIdeas[_tokenId];
        require(idea.creator == msg.sender, "GenesisNexus: Only creator can retire idea");
        require(idea.tokenId != 0, "GenesisNexus: Genesis Idea does not exist");
        require(idea.timeLockEnd < block.timestamp, "GenesisNexus: Idea is time-locked");

        // Check for linked derivative works. This is a simplification.
        // A robust system would require iterating through a mapping of genesisId -> derivativeIds.
        // For simplicity, we assume if `derivativeWorks[_tokenId]` exists, it implies a linked derivative.
        // If a derivative work references this GenesisIdea, it cannot be retired.
        for (uint256 i = 1; i <= _derivativeWorkTokenIdCounter.current(); i++) {
            if (_derivativeWorks[i].genesisIdeaId == _tokenId) {
                revert("GenesisNexus: Cannot retire idea with linked derivative works");
            }
        }
        
        // Mark as burnt by deleting relevant data. ERC721 requires `_owners` to be cleared.
        // Ownership record for Genesis Idea NFTs are primarily for creator tracking, not transfer.
        delete _genesisIdeaOwners[_tokenId];
        delete _genesisIdeaTokenURIs[_tokenId];
        delete _genesisIdeas[_tokenId]; // Remove the struct

        // For arrays like _genesisIdeaOwnedTokens, removing elements is gas-intensive.
        // For a production contract, consider linked lists or re-indexing strategies.
        // For this example, we assume occasional use or accept the gas cost.
        uint256[] storage creatorOwned = _genesisIdeaOwnedTokens[msg.sender];
        for (uint255 i = 0; i < creatorOwned.length; i++) {
            if (creatorOwned[i] == _tokenId) {
                creatorOwned[i] = creatorOwned[creatorOwned.length - 1];
                creatorOwned.pop();
                break;
            }
        }

        emit Transfer(msg.sender, address(0), _tokenId); // ERC721 Burn Event (from msg.sender to 0x0)
        emit GenesisIdeaRetired(_tokenId);
    }

    /// @notice Delegates the primary development responsibility for a Genesis Idea to another address.
    ///         Only the original creator can delegate.
    /// @param _tokenId The ID of the Genesis Idea.
    /// @param _delegate The address of the new development delegate.
    function delegateIdeaDevelopment(uint256 _tokenId, address _delegate) external whenNotPaused {
        GenesisIdea storage idea = _genesisIdeas[_tokenId];
        require(idea.creator == msg.sender, "GenesisNexus: Only creator can delegate development");
        require(idea.tokenId != 0, "GenesisNexus: Genesis Idea does not exist");
        require(_delegate != address(0), "GenesisNexus: Delegate cannot be zero address");
        require(idea.timeLockEnd < block.timestamp, "GenesisNexus: Idea is time-locked");

        idea.developmentDelegate = _delegate;
        emit IdeaDevelopmentDelegated(_tokenId, _delegate);
    }

    /// @notice Revokes the primary development delegation for a Genesis Idea.
    ///         Only the original creator can revoke.
    /// @param _tokenId The ID of the Genesis Idea.
    function revokeIdeaDevelopmentDelegation(uint256 _tokenId) external whenNotPaused {
        GenesisIdea storage idea = _genesisIdeas[_tokenId];
        require(idea.creator == msg.sender, "GenesisNexus: Only creator can revoke delegation");
        require(idea.tokenId != 0, "GenesisNexus: Genesis Idea does not exist");
        require(idea.developmentDelegate != address(0), "GenesisNexus: No active delegation to revoke");
        require(idea.timeLockEnd < block.timestamp, "GenesisNexus: Idea is time-locked");

        address revokedDelegate = idea.developmentDelegate;
        idea.developmentDelegate = address(0);
        emit IdeaDevelopmentDelegationRevoked(_tokenId, revokedDelegate);
    }

    /// @notice Retrieves comprehensive details about a Genesis Idea.
    /// @param _tokenId The ID of the Genesis Idea.
    /// @return A tuple containing all relevant details.
    function getGenesisIdeaDetails(uint256 _tokenId)
        external
        view
        returns (uint256 id, address creator, string memory uri, address delegate, bool isSoulbound, uint256 timeLockEnd)
    {
        GenesisIdea storage idea = _genesisIdeas[_tokenId];
        require(idea.tokenId != 0, "GenesisNexus: Genesis Idea does not exist");
        return (idea.tokenId, idea.creator, idea.uri, idea.developmentDelegate, idea.isSoulbound, idea.timeLockEnd);
    }

    // --- III. Collaboration & Attestation System (SBTs / Reputation) ---

    /// @notice Mints a Soulbound Token (SBT) representing a skill attestation for a user.
    ///         These attestations are non-transferable and contribute to a user's reputation score.
    /// @param _user The address of the user being attested.
    /// @param _skillURI The URI pointing to the metadata describing the attested skill.
    /// @return The ID of the newly minted attestation.
    function attestSkill(address _user, string memory _skillURI) external whenNotPaused returns (uint256) {
        require(_user != address(0), "GenesisNexus: Cannot attest to zero address");
        require(msg.sender != _user, "GenesisNexus: Cannot self-attest skills"); // Prevent easy self-inflation

        _attestationIdCounter.increment();
        uint256 newId = _attestationIdCounter.current();

        _attestations[newId] = Attestation({
            id: newId,
            attester: msg.sender,
            attestedUser: _user,
            uri: _skillURI,
            timestamp: block.timestamp
        });

        _attestationsIssuedBy[msg.sender].push(newId);
        _attestationsForUser[_user].push(newId);

        emit SkillAttested(newId, msg.sender, _user, _skillURI);
        return newId;
    }

    /// @notice Allows an attester to revoke a previously issued skill attestation.
    /// @param _user The user whose attestation is being revoked.
    /// @param _attestationId The ID of the attestation to revoke.
    function revokeAttestation(address _user, uint256 _attestationId) external whenNotPaused {
        Attestation storage att = _attestations[_attestationId];
        require(att.id != 0, "GenesisNexus: Attestation does not exist");
        require(att.attester == msg.sender, "GenesisNexus: Only original attester can revoke");
        require(att.attestedUser == _user, "GenesisNexus: Attestation ID does not match user");

        // "Burn" the attestation by clearing its data
        delete _attestations[_attestationId];

        // Removing from arrays (costly for large arrays, for example, would use linked lists or similar)
        // For demonstration, direct array manipulation, but be aware of gas costs for production.
        uint256[] storage attestationsForUserArr = _attestationsForUser[_user];
        for (uint256 i = 0; i < attestationsForUserArr.length; i++) {
            if (attestationsForUserArr[i] == _attestationId) {
                attestationsForUserArr[i] = attestationsForUserArr[attestationsForuserArr.length - 1];
                attestationsForUserArr.pop();
                break;
            }
        }
        uint256[] storage attestationsIssuedByArr = _attestationsIssuedBy[msg.sender];
        for (uint256 i = 0; i < attestationsIssuedByArr.length; i++) {
            if (attestationsIssuedByArr[i] == _attestationId) {
                attestationsIssuedByArr[i] = attestationsIssuedByArr[attestationsIssuedByArr.length - 1];
                attestationsIssuedByArr.pop();
                break;
            }
        }

        emit AttestationRevoked(_attestationId);
    }

    /// @notice Records a contribution to a Genesis Idea, potentially boosting contributor's reputation.
    ///         Can be called by anyone contributing to an open idea.
    /// @param _genesisId The ID of the Genesis Idea being contributed to.
    /// @param _contributionURI The URI pointing to the metadata describing the contribution.
    function contributeToIdea(uint256 _genesisId, string memory _contributionURI) external whenNotPaused {
        GenesisIdea storage idea = _genesisIdeas[_genesisId];
        require(idea.tokenId != 0, "GenesisNexus: Genesis Idea does not exist");
        require(idea.timeLockEnd < block.timestamp, "GenesisNexus: Idea is time-locked");

        uint256 contributionId = _contributionsToIdea[_genesisId].length; // Simple counter for this idea's contributions

        Contribution memory newContribution = Contribution({
            id: contributionId,
            genesisId: _genesisId,
            contributor: msg.sender,
            uri: _contributionURI,
            timestamp: block.timestamp
        });

        _contributionsToIdea[_genesisId].push(newContribution);
        _contributionsByUser[msg.sender].push(newContribution);

        emit ContributionRecorded(_genesisId, contributionId, msg.sender);
    }

    /// @notice Retrieves all skill attestations issued to a specific user.
    /// @param _user The address of the user.
    /// @return An array of attestation IDs.
    function getAttestationsForUser(address _user) external view returns (uint256[] memory) {
        return _attestationsForUser[_user];
    }

    /// @notice Calculates and returns a dynamic reputation score for a user.
    ///         Score is based on number of attestations received and contributions made.
    ///         (Simplified calculation for demonstration: count of attestations + count of contributions)
    /// @param _user The address of the user.
    /// @return The calculated reputation score.
    function getUserReputationScore(address _user) public view returns (uint256) {
        uint256 attestationsCount = _attestationsForUser[_user].length;
        uint256 contributionsCount = _contributionsByUser[_user].length;
        // Future: could add decaying scores, attester reputation weighting, successful derivative work links, etc.
        return (attestationsCount * 10) + contributionsCount; // Arbitrary weighting
    }

    // --- IV. Derivative Work Creation & Dynamic Rights (ERC-721 based) ---

    /// @notice Requests the AI oracle to generate potential traits/metadata for a new Derivative Work.
    ///         Only the Genesis Idea creator or its delegate can make this request.
    /// @param _genesisId The ID of the Genesis Idea.
    /// @param _promptURI The URI for the prompt given to the AI.
    /// @param _requestId A unique request ID for tracking the AI's response (managed by calling client).
    function requestAIDrivenTraitGeneration(uint256 _genesisId, string memory _promptURI, uint256 _requestId)
        external
        whenNotPaused
        onlyGenesisIdeaCreatorOrDelegate(_genesisId)
    {
        GenesisIdea storage idea = _genesisIdeas[_genesisId];
        require(idea.timeLockEnd < block.timestamp, "GenesisNexus: Idea is time-locked");
        _aiOracle.requestGeneration(_genesisId, _promptURI, _requestId);
        // The AI oracle contract is expected to emit an event when results are ready.
    }

    /// @notice Allows reputation-weighted voting on proposed AI-generated traits.
    ///         Users with higher reputation have a stronger vote.
    ///         Votes are cast on a specific AI result for a given request.
    /// @param _genesisId The ID of the Genesis Idea (for context/validation).
    /// @param _requestId The ID of the AI generation request.
    /// @param _aiResultIndex The index of the specific AI result to vote on.
    /// @param _approve True to approve, false to reject.
    function submitAIConsensusVote(uint256 _genesisId, uint256 _requestId, uint256 _aiResultIndex, bool _approve)
        external
        whenNotPaused
    {
        require(_genesisIdeas[_genesisId].tokenId != 0, "GenesisNexus: Genesis Idea does not exist");
        
        // This call goes to the IAIOracle contract.
        // The IAIOracle contract is responsible for applying reputation weighting (e.g., by calling
        // GenesisNexus.getUserReputationScore(msg.sender)) and recording the vote.
        _aiOracle.submitVote(_requestId, _aiResultIndex, _approve);
    }

    /// @notice Mints a new Derivative Work NFT, potentially using AI-approved traits,
    ///         and sets initial royalty distribution.
    /// @param _genesisId The ID of the Genesis Idea this work is derived from.
    /// @param _baseURI The base URI for the derivative work's metadata.
    /// @param _aiApprovedResultIndex The index of the AI result approved for this work (0 if not AI-driven).
    ///        This index refers to a result within a specific AI request that would have been approved.
    /// @param _initialRoyaltyRecipients An array of addresses to receive royalties.
    /// @param _initialRoyaltyBps An array of basis points (sum should be <= 10000) for each recipient.
    /// @return The tokenId of the newly minted Derivative Work.
    function mintDerivativeWork(
        uint256 _genesisId,
        string memory _baseURI,
        uint256 _aiApprovedResultIndex, // Assuming a specific request ID is handled off-chain or implied
        address[] memory _initialRoyaltyRecipients,
        uint256[] memory _initialRoyaltyBps
    ) external whenNotPaused returns (uint256) {
        GenesisIdea storage idea = _genesisIdeas[_genesisId];
        require(idea.tokenId != 0, "GenesisNexus: Genesis Idea does not exist");
        require(idea.timeLockEnd < block.timestamp, "GenesisNexus: Genesis Idea is time-locked");
        require(_initialRoyaltyRecipients.length == _initialRoyaltyBps.length, "GenesisNexus: Mismatched royalty arrays");

        string memory finalURI = _baseURI;
        // In a real system, you'd fetch the AI result from the oracle if _aiApprovedResultIndex > 0
        // Example: IAIOracle.AIResult memory aiResult = _aiOracle.getResult(someRequestId, _aiApprovedResultIndex);
        // require(aiResult.status == IAIOracle.AIResultStatus.Approved, "GenesisNexus: AI result not approved");
        // finalURI = string(abi.encodePacked(_baseURI, "/", aiResult.uri)); // Combine base URI with AI-generated part

        _derivativeWorkTokenIdCounter.increment();
        uint256 newId = _derivativeWorkTokenIdCounter.current();

        _derivativeWorks[newId] = DerivativeWork({
            tokenId: newId,
            genesisIdeaId: _genesisId,
            creator: msg.sender,
            uri: finalURI,
            totalRoyaltyBps: 0, // Will be set by setDynamicRoyaltySplit
            accruedRoyalties: new mapping(address => uint256), // Initialize mapping
            timeLockEnd: 0
        });
        _derivativeWorkOwners[newId] = msg.sender;
        _derivativeWorkOwnedTokens[msg.sender].push(newId);
        _derivativeWorkTokenURIs[newId] = finalURI;

        // Set initial royalties (uses a public function to reuse validation logic)
        setDynamicRoyaltySplit(newId, _initialRoyaltyRecipients, _initialRoyaltyBps);

        emit Transfer(address(0), msg.sender, newId); // ERC721 Mint Event (from 0x0 to msg.sender)
        emit DerivativeWorkMinted(newId, _genesisId, msg.sender, finalURI);
        return newId;
    }

    /// @notice Adjusts the multi-party, dynamically adjusted royalty split for a Derivative Work.
    ///         Only the owner or creator of the Derivative Work can set this.
    /// @param _derivativeId The ID of the Derivative Work.
    /// @param _recipients An array of addresses to receive royalties.
    /// @param _bps An array of basis points (sum should be <= 10000) for each recipient.
    function setDynamicRoyaltySplit(uint256 _derivativeId, address[] memory _recipients, uint256[] memory _bps)
        public // Made public for initial setting by mintDerivativeWork, but protected by modifier
        whenNotPaused
        onlyDerivativeWorkOwnerOrCreator(_derivativeId)
    {
        DerivativeWork storage work = _derivativeWorks[_derivativeId];
        require(work.tokenId != 0, "GenesisNexus: Derivative Work does not exist");
        require(work.timeLockEnd < block.timestamp, "GenesisNexus: Derivative Work is time-locked");
        require(_recipients.length == _bps.length, "GenesisNexus: Mismatched array lengths");

        uint256 newTotalBps = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "GenesisNexus: Royalty recipient cannot be zero");
            newTotalBps += _bps[i];
        }
        require(newTotalBps <= 10000, "GenesisNexus: Total royalty basis points exceed 10000 (100%)");

        // A simple way to "clear" previous royalty settings for recipients not in the new list
        // would be to iterate over existing keys and set them to 0 if not present in _recipients.
        // For simplicity in this example, new entries overwrite, and old ones persist at 0 if not updated.
        // This is not fully clearing, but effectively sets new percentages.
        work.totalRoyaltyBps = 0; // Reset total for recalculation

        for (uint256 i = 0; i < _recipients.length; i++) {
            work.royaltyBps[_recipients[i]] = _bps[i];
            work.totalRoyaltyBps += _bps[i];
        }

        emit DynamicRoyaltySplitSet(_derivativeId, _recipients, _bps);
    }

    /// @notice Allows a royalty recipient to claim their share of accrued royalties.
    ///         Assumes royalties are collected in the native currency (ETH) or a specified ERC20.
    ///         For simplicity, this example will assume native currency and a placeholder amount.
    ///         In a real system, funds would accumulate in the contract and then be disbursed.
    /// @param _derivativeId The ID of the Derivative Work.
    /// @param _recipient The address claiming royalties.
    function claimRoyalties(uint256 _derivativeId, address _recipient) external whenNotPaused {
        DerivativeWork storage work = _derivativeWorks[_derivativeId];
        require(work.tokenId != 0, "GenesisNexus: Derivative Work does not exist");
        require(work.royaltyBps[_recipient] > 0, "GenesisNexus: Recipient has no royalty share configured");

        // Placeholder for actual revenue distribution logic
        // Example for ETH:
        // uint256 amountToClaim = work.accruedRoyalties[_recipient]; // Assuming _accruedRoyalties maps addr -> ETH amount
        // require(amountToClaim > 0, "GenesisNexus: No royalties accrued for recipient");
        // work.accruedRoyalties[_recipient] = 0; // Reset
        // payable(_recipient).transfer(amountToClaim); // Transfer ETH

        emit RoyaltiesClaimed(_derivativeId, _recipient, 0); // Amount 0 for demo, replace with actual amount
    }

    /// @notice Allows authorized parties to update the metadata URI for a Derivative Work.
    ///         This enables dynamic NFT (dNFT) functionality.
    /// @param _derivativeId The ID of the Derivative Work.
    /// @param _newURI The new URI pointing to updated metadata.
    function updateDerivativeWorkMetadata(uint256 _derivativeId, string memory _newURI)
        external
        whenNotPaused
        onlyDerivativeWorkOwnerOrCreator(_derivativeId)
    {
        DerivativeWork storage work = _derivativeWorks[_derivativeId];
        require(work.tokenId != 0, "GenesisNexus: Derivative Work does not exist");
        require(work.timeLockEnd < block.timestamp, "GenesisNexus: Derivative Work is time-locked");

        work.uri = _newURI;
        _derivativeWorkTokenURIs[_derivativeId] = _newURI; // Update ERC721 URI mapping for compatibility
        emit DerivativeWorkMetadataUpdated(_derivativeId, _newURI);
    }

    /// @notice Transfers ownership of a Derivative Work NFT.
    ///         Adheres to ERC721 standards but with added internal checks (like time-lock).
    /// @param _from The current owner.
    /// @param _to The new owner.
    /// @param _derivativeId The ID of the Derivative Work to transfer.
    function transferDerivativeWorkOwnership(address _from, address _to, uint256 _derivativeId)
        public // Public so ERC721 `transferFrom` can call it.
        whenNotPaused
    {
        // Internal check for owner and approval, as per ERC721 standard
        require(_derivativeWorkOwners[_derivativeId] == _from, "ERC721: transfer from incorrect owner");
        require(_to != address(0), "ERC721: transfer to the zero address");
        require(_derivativeWorks[_derivativeId].tokenId != 0, "GenesisNexus: Derivative Work does not exist");
        require(_derivativeWorks[_derivativeId].timeLockEnd < block.timestamp, "GenesisNexus: Derivative Work is time-locked");

        _transfer(_from, _to, _derivativeId);
    }

    // --- V. Advanced Governance & IP Control ---

    /// @notice Places a Genesis Idea or Derivative Work under a time-lock.
    ///         During the time-lock, the asset cannot be transferred or certain modifications made.
    ///         Only the creator/owner can initiate a time-lock.
    /// @param _tokenId The ID of the Genesis Idea or Derivative Work.
    /// @param _lockEndTime The timestamp (Unix epoch) when the lock expires.
    /// @param _isGenesisIdea True if the token is a Genesis Idea, false if a Derivative Work.
    function timeLockIntellectualProperty(uint256 _tokenId, uint256 _lockEndTime, bool _isGenesisIdea) external whenNotPaused {
        require(_lockEndTime > block.timestamp, "GenesisNexus: Lock end time must be in the future");

        if (_isGenesisIdea) {
            GenesisIdea storage idea = _genesisIdeas[_tokenId];
            require(idea.tokenId != 0, "GenesisNexus: Genesis Idea does not exist");
            require(idea.creator == msg.sender, "GenesisNexus: Only creator can time-lock Genesis Idea");
            require(idea.timeLockEnd < block.timestamp, "GenesisNexus: Genesis Idea already time-locked"); // Cannot re-lock if already locked
            idea.timeLockEnd = _lockEndTime;
            emit GenesisIdeaIPTimeLocked(_tokenId, _lockEndTime);
        } else {
            DerivativeWork storage work = _derivativeWorks[_tokenId];
            require(work.tokenId != 0, "GenesisNexus: Derivative Work does not exist");
            require(_derivativeWorkOwners[_tokenId] == msg.sender, "GenesisNexus: Only owner can time-lock Derivative Work");
            require(work.timeLockEnd < block.timestamp, "GenesisNexus: Derivative Work already time-locked"); // Cannot re-lock if already locked
            work.timeLockEnd = _lockEndTime;
            emit DerivativeWorkIPTimeLocked(_tokenId, _lockEndTime);
        }
    }

    /// @notice Extends an existing time-lock period for an IP asset.
    ///         Only the creator/owner can extend, and the new lock end time must be later than the current one.
    /// @param _tokenId The ID of the Genesis Idea or Derivative Work.
    /// @param _newLockEndTime The new timestamp (Unix epoch) when the lock expires.
    /// @param _isGenesisIdea True if the token is a Genesis Idea, false if a Derivative Work.
    function extendTimeLock(uint256 _tokenId, uint256 _newLockEndTime, bool _isGenesisIdea) external whenNotPaused {
        require(_newLockEndTime > block.timestamp, "GenesisNexus: New lock end time must be in the future");

        if (_isGenesisIdea) {
            GenesisIdea storage idea = _genesisIdeas[_tokenId];
            require(idea.tokenId != 0, "GenesisNexus: Genesis Idea does not exist");
            require(idea.creator == msg.sender, "GenesisNexus: Only creator can extend Genesis Idea time-lock");
            require(idea.timeLockEnd > block.timestamp, "GenesisNexus: Genesis Idea is not currently time-locked"); // Must be currently locked
            require(_newLockEndTime > idea.timeLockEnd, "GenesisNexus: New lock time must be later than current");
            idea.timeLockEnd = _newLockEndTime;
            emit GenesisIdeaIPTimeLocked(_tokenId, _newLockEndTime);
        } else {
            DerivativeWork storage work = _derivativeWorks[_tokenId];
            require(work.tokenId != 0, "GenesisNexus: Derivative Work does not exist");
            require(_derivativeWorkOwners[_tokenId] == msg.sender, "GenesisNexus: Only owner can extend Derivative Work time-lock");
            require(work.timeLockEnd > block.timestamp, "GenesisNexus: Derivative Work is not currently time-locked"); // Must be currently locked
            require(_newLockEndTime > work.timeLockEnd, "GenesisNexus: New lock time must be later than current");
            work.timeLockEnd = _newLockEndTime;
            emit DerivativeWorkIPTimeLocked(_tokenId, _newLockEndTime);
        }
    }

    /// @notice Allows a designated dispute resolver (e.g., the admin) to adjust a specific royalty share
    ///         for a Derivative Work in cases of dispute.
    ///         This introduces a centralized point for dispute resolution, which could be replaced
    ///         by a DAO-based voting mechanism in a fully decentralized setup.
    /// @param _derivativeId The ID of the Derivative Work.
    /// @param _disputedRecipient The recipient whose royalty share is being adjusted.
    /// @param _newBps The new basis points for the disputed recipient.
    function resolveRoyaltyDispute(uint256 _derivativeId, address _disputedRecipient, uint256 _newBps) external onlyAdmin whenNotPaused {
        DerivativeWork storage work = _derivativeWorks[_derivativeId];
        require(work.tokenId != 0, "GenesisNexus: Derivative Work does not exist");
        require(_disputedRecipient != address(0), "GenesisNexus: Disputed recipient cannot be zero");
        require(_newBps <= 10000, "GenesisNexus: New BPS too high");

        uint256 oldBps = work.royaltyBps[_disputedRecipient];
        require(oldBps != _newBps, "GenesisNexus: New BPS is same as current");

        work.totalRoyaltyBps = work.totalRoyaltyBps - oldBps + _newBps;
        require(work.totalRoyaltyBps <= 10000, "GenesisNexus: Adjusted total royalty basis points exceed 100%");

        work.royaltyBps[_disputedRecipient] = _newBps;
        emit RoyaltyDisputeResolved(_derivativeId, _disputedRecipient, _newBps);
    }

    // --- ERC721 Standard Functions (Custom Implementation for Soulbound and Transferable NFTs) ---
    // Note: These implementations are custom and minimal to avoid direct OpenZeppelin duplication
    // while still adhering to the ERC721 interface where applicable.

    /// @dev See {IERC721-balanceOf}.
    /// Returns the number of Derivative Works owned by `owner`. Genesis Ideas are Soulbound and not counted here.
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _derivativeWorkOwnedTokens[owner].length;
    }

    /// @dev See {IERC721-ownerOf}.
    /// Returns the owner of the `tokenId`. Only applicable for transferable Derivative Works.
    /// Reverts if `tokenId` is a Genesis Idea (Soulbound) or does not exist as a Derivative Work.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _derivativeWorkOwners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token or Soulbound Genesis Idea");
        return owner;
    }

    /// @dev See {IERC721Metadata-name}.
    function name() public view override returns (string memory) {
        return "GenesisNexus IP";
    }

    /// @dev See {IERC721Metadata-symbol}.
    function symbol() public view override returns (string memory) {
        return "GENNEX";
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        // Prioritize Derivative Work URI for transferable tokens
        if (_derivativeWorks[tokenId].tokenId != 0 && _derivativeWorkOwners[tokenId] != address(0)) {
            return _derivativeWorkTokenURIs[tokenId];
        } 
        // If not a transferable Derivative Work, check if it's a Genesis Idea
        else if (_genesisIdeas[tokenId].tokenId != 0 && _genesisIdeaOwners[tokenId] != address(0)) {
            return _genesisIdeaTokenURIs[tokenId];
        }
        revert("ERC721Metadata: URI query for unknown token type or burnt token");
    }

    /// @dev See {IERC721-approve}.
    /// Only applicable to transferable Derivative Works.
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId); // Will revert if not a transferable Derivative Work
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        require(_derivativeWorks[tokenId].timeLockEnd < block.timestamp, "GenesisNexus: Derivative Work is time-locked");

        _approve(to, tokenId);
    }

    /// @dev See {IERC721-getApproved}.
    /// Only applicable to transferable Derivative Works.
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        require(_derivativeWorks[tokenId].tokenId != 0 && _derivativeWorkOwners[tokenId] != address(0), "GenesisNexus: Token is not a transferable Derivative Work");
        return _tokenApprovals[tokenId];
    }

    /// @dev See {IERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev See {IERC721-isApprovedForAll}.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @dev See {IERC721-transferFrom}.
    /// Only applicable to transferable Derivative Works.
    function transferFrom(address from, address to, uint256 tokenId) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_derivativeWorks[tokenId].timeLockEnd < block.timestamp, "GenesisNexus: Derivative Work is time-locked");

        _transfer(from, to, tokenId);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    /// Only applicable to transferable Derivative Works.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @dev See {IERC721-safeTransferFrom}.
    /// Only applicable to transferable Derivative Works.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_derivativeWorks[tokenId].timeLockEnd < block.timestamp, "GenesisNexus: Derivative Work is time-locked");
        _safeTransfer(from, to, tokenId, data);
    }

    /// @dev Safely transfers `tokenId` from `from` to `to`, checking first that `to` is a contract
    ///  and that it accepts ERC721 tokens.
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /// @dev Internal function to transfer ownership of a given token ID to another address.
    /// This custom implementation enforces Soulbound rules for Genesis Ideas
    /// and performs transfer for Derivative Works.
    function _transfer(address from, address to, uint256 tokenId) internal {
        // This checks if the `tokenId` belongs to `from` and whether `tokenId` is a transferable Derivative Work.
        // `ownerOf(tokenId)` call within `_isApprovedOrOwner` already asserts it's a Derivative Work.
        require(_derivativeWorkOwners[tokenId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        
        // This is the core custom logic for Genesis Ideas (Soulbound)
        GenesisIdea storage genesisIdea = _genesisIdeas[tokenId];
        if (genesisIdea.tokenId != 0 && genesisIdea.isSoulbound) {
            revert("GenesisNexus: Genesis Ideas are soulbound and cannot be transferred");
        }

        // Clear any prior approvals for the token being transferred
        _approve(address(0), tokenId); 
        
        // Update _derivativeWorkOwnedTokens array for 'from' (remove tokenId)
        uint256[] storage fromTokens = _derivativeWorkOwnedTokens[from];
        for (uint256 i = 0; i < fromTokens.length; i++) {
            if (fromTokens[i] == tokenId) {
                fromTokens[i] = fromTokens[fromTokens.length - 1];
                fromTokens.pop(); // Remove last element and reduce array size
                break;
            }
        }

        _derivativeWorkOwners[tokenId] = to; // Update owner
        _derivativeWorkOwnedTokens[to].push(tokenId); // Add to new owner's list

        emit Transfer(from, to, tokenId);
    }

    /// @dev Internal function to approve `to` to operate on `tokenId`
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // `ownerOf` ensures it's a transferable token
    }

    /// @dev Returns whether `spender` is allowed to manage `tokenId`.
    /// This is an internal helper for `transferFrom` and `safeTransferFrom`.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // This will revert if tokenId is not a transferable Derivative Work
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /// @dev Returns whether `tokenId` exists in either Genesis Ideas or Derivative Works.
    function _exists(uint256 tokenId) internal view returns (bool) {
        // Check if it's a Genesis Idea (even if Soulbound) or a Derivative Work
        return (_genesisIdeas[tokenId].tokenId != 0 || _derivativeWorks[tokenId].tokenId != 0);
    }

    /// @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
    /// @param from address The calling address which initiated the transfer.
    /// @param to address The actual recipient address.
    /// @param tokenId uint256 Id of the token being transferred.
    /// @param _data bytes Optional data with no specified format.
    /// @return `true` if the transfer is accepted, `false` otherwise.
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (no reason)");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    // --- IERC165 (ERC-165) Implementation ---
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId || 
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == _INTERFACE_ID_ERC721 || // Directly comparing to interface ID (redundant if using type(IERC721).interfaceId)
            _INTERFACE_ID_ERC721_METADATA; // Directly comparing to interface ID (redundant if using type(IERC721Metadata).interfaceId)
    }

    // Fallback function for receiving native currency (ETH) for royalties
    receive() external payable whenNotPaused {}
}

```