This smart contract, `EtherealGlyphNexus`, introduces a novel concept for **Adaptive Identity NFTs (Glyphs)** combined with a **Self-Evolving Protocol Framework**. It aims to create a dynamic, reputation-driven identity system where NFTs change their properties based on on-chain activities, attested skills, and community governance. The protocol itself can evolve by registering new modules and updating parameters through a decentralized voting mechanism, leveraging simulated AI-driven insights via oracle integration for advanced features.

---

### **Contract Name: `EtherealGlyphNexus`**

### **Outline:**

1.  **Core Glyphs & Dynamic Properties (ERC-721)**
    *   Minting, burning, and retrieving glyph data.
    *   Mechanisms for dynamic property updates and evolution based on on-chain triggers.
    *   Conditional transferability.

2.  **Attestation & Reputation System**
    *   Authorized entities can attest to user skills or achievements.
    *   Revocation and querying of attestations.
    *   Proposing and voting for new attester roles.

3.  **Protocol Governance & Modularity**
    *   A robust governance system for proposing and executing changes to protocol parameters.
    *   Ability to register and unregister external functional modules (e.g., mini-games, specialized tools).
    *   Delegated voting for enhanced participation.

4.  **Oracle Integration & AI-Driven Traits (Simulated)**
    *   Functions for requesting and fulfilling AI-driven trait suggestions or complex data via an oracle.
    *   Integration of external data for dynamic NFT metadata.

5.  **Emergency & Utility Functions**
    *   Pause/unpause functionality for security.
    *   Configuration settings (base URI).
    *   Fee management.

### **Function Summary:**

**I. Glyph Management (ERC-721 Base & Dynamics)**
1.  `mintGlyph(address _to, string calldata _baseMetadataURI)`: Mints a new Glyph NFT for an address, providing an initial metadata URI.
2.  `burnGlyph(uint256 _tokenId)`: Allows the owner or an authorized entity to burn a Glyph, potentially with conditions.
3.  `updateGlyphBaseMetadata(uint256 _tokenId, string calldata _newURI)`: Updates the static base metadata URI of a specific Glyph.
4.  `getGlyphDynamicProperties(uint256 _tokenId)`: Retrieves a hash representing the current dynamic properties (traits, levels) of a Glyph.
5.  `triggerGlyphEvolution(uint256 _tokenId, bytes32 _evolutionTriggerHash)`: Initiates a Glyph's evolutionary process based on a verified on-chain or oracle-attested trigger.
6.  `isGlyphEvolving(uint256 _tokenId)`: Checks if a Glyph is currently undergoing an active evolution process.
7.  `revokeGlyphTrait(uint256 _tokenId, uint256 _traitId)`: Revokes a specific dynamically added trait from a Glyph, potentially as a penalty or expiration.
8.  `transferFrom(address from, address to, uint256 tokenId)`: Overrides standard ERC-721 transfer to include conditional checks (e.g., if soulbound).

**II. Attestation & Reputation System**
9.  `attestSkill(address _subject, bytes32 _skillHash, uint256 _level, uint256 _expirationTimestamp)`: An authorized attester vouches for a skill or achievement of a user (linked to their Glyph).
10. `revokeAttestation(bytes32 _attestationId)`: Revokes an existing attestation, potentially decreasing the subject's reputation.
11. `getAttestationsForGlyphOwner(address _owner)`: Retrieves all active attestations associated with a Glyph owner.
12. `querySkillLevel(address _subject, bytes32 _skillHash)`: Returns the current attested skill level for a subject.
13. `proposeNewAttester(address _newAttester)`: Initiates a governance proposal to add a new authorized attester role.
14. `voteForAttesterProposal(bytes32 _proposalId, bool _approve)`: Allows users with voting power to vote on attester proposals.

**III. Protocol Governance & Modularity**
15. `registerModule(address _moduleAddress, bytes32 _moduleNameHash, uint256 _requiredQuorum)`: Registers a new functional module (an external contract) into the Nexus, making it recognized by the protocol.
16. `unregisterModule(bytes32 _moduleNameHash)`: Unregisters an existing module from the Nexus.
17. `proposeParameterChange(bytes32 _parameterKey, bytes _newValue)`: Proposes a change to a core protocol parameter (e.g., evolution cost, grace period, fee structure).
18. `voteOnProposal(bytes32 _proposalId, bool _approve)`: Casts a vote on any active governance proposal (parameter change, module registration, etc.).
19. `executeProposal(bytes32 _proposalId)`: Executes a governance proposal that has passed and met its timelock requirements.
20. `delegateVote(address _delegatee)`: Allows users to delegate their voting power to another address.

**IV. Oracle Integration & AI-Driven Traits (Simulated)**
21. `requestAIDrivenTraitSuggestion(uint256 _tokenId, bytes32 _requestId)`: Simulates a request to an off-chain AI oracle for dynamic trait suggestions based on a Glyph's history and attestations.
22. `fulfillAIDrivenTraitSuggestion(uint256 _tokenId, string calldata _suggestedTraitURI, bytes32 _requestId, bytes calldata _oracleSignature)`: The authorized oracle fulfills a trait suggestion request, updating the Glyph's dynamic metadata.
23. `claimAchievementReward(uint256 _tokenId, bytes32 _achievementHash)`: Allows a Glyph owner to claim a specific reward if predefined conditions (attestations, interactions) are met, potentially triggering a trait update.

**V. Emergency & Utility Functions**
24. `pauseProtocol()`: Pauses certain critical functions of the protocol in an emergency (ADMIN role).
25. `unpauseProtocol()`: Unpauses the protocol (ADMIN role).
26. `setBaseURI(string calldata _newBaseURI)`: Sets the base URI for ERC-721 metadata.
27. `withdrawProtocolFees(address _to, uint256 _amount)`: Allows the treasury or governance to withdraw collected protocol fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note: This contract leverages standard OpenZeppelin contracts for foundational components
// like ERC721, AccessControl, Pausable. The novelty lies in the *composition* of these
// elements with dynamic NFT properties, a modular governance system, a unique attestation
// mechanism, and simulated oracle-driven AI integration, creating a distinctive protocol.

contract EtherealGlyphNexus is ERC721, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    // --- Access Control Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ATTESTER_ROLE = keccak256("ATTESTER_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // For AI-driven features

    // --- Glyph Data Structures ---
    struct Glyph {
        address owner;
        string baseMetadataURI; // Static part of metadata
        bytes32 dynamicPropertiesHash; // Hash representing the current state of dynamic traits
        uint256 lastEvolutionTimestamp;
        bool isSoulbound; // If true, cannot be transferred
        EnumerableSet.UintSet activeTraits; // IDs of dynamically added traits
    }

    struct DynamicTrait {
        uint256 traitId;
        string uriFragment; // Part of the URI that represents this trait
        bytes32 categoryHash;
        uint256 expirationTimestamp; // 0 if permanent
    }

    // --- Attestation Data Structures ---
    struct Attestation {
        address attester;
        address subject;
        bytes32 skillHash; // Unique identifier for the skill/achievement
        uint256 level;
        uint256 expirationTimestamp; // 0 if permanent
        uint256 timestamp;
        bool revoked;
    }

    // --- Governance Data Structures ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        bytes32 proposalId;
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        bytes data; // Callable data for execution (e.g., to set a parameter)
        address target; // Target contract for execution (this contract or a module)
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 quorum; // Required votes for success (can be dynamic)
        bool executed;
        ProposalState state;
        mapping(address => bool) hasVoted;
    }

    struct Module {
        address moduleAddress;
        uint256 requiredQuorum; // Quorum specific to proposals affecting this module
        bool registered;
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _attestationIdCounter;
    Counters.Counter private _traitIdCounter;
    Counters.Counter private _proposalIdCounter;

    mapping(uint256 => Glyph) public glyphs;
    mapping(address => EnumerableSet.UintSet) private _ownerGlyphs; // For quick lookup of glyphs by owner

    mapping(bytes32 => Attestation) public attestations; // attestationId => Attestation
    mapping(address => EnumerableSet.Bytes32Set) private _subjectAttestations; // subjectAddress => Set of attestationIds

    mapping(bytes32 => DynamicTrait) public dynamicTraits; // traitId => DynamicTrait

    // Governance related
    mapping(bytes32 => Proposal) public proposals;
    mapping(address => uint256) public votingPower; // User's voting power (can be based on staked tokens, glyph attributes, etc.)
    mapping(address => address) public delegates; // Delegatee for voting power
    mapping(bytes32 => Module) public modules; // moduleNameHash => Module details

    // Protocol parameters (governance configurable)
    uint256 public constant MIN_VOTING_DELAY = 100; // Blocks
    uint256 public constant VOTING_PERIOD = 5000; // Blocks
    uint256 public constant PROPOSAL_THRESHOLD = 1; // Minimum voting power to propose
    uint256 public constant DEFAULT_QUORUM = 1000; // Default quorum for proposals
    string private _baseURI; // Default base URI for token metadata

    // --- Events ---
    event GlyphMinted(uint256 indexed tokenId, address indexed owner, string baseURI);
    event GlyphBurned(uint256 indexed tokenId);
    event GlyphBaseMetadataUpdated(uint256 indexed tokenId, string newURI);
    event GlyphEvolutionTriggered(uint256 indexed tokenId, bytes32 indexed triggerHash, bytes32 newDynamicPropertiesHash);
    event GlyphTraitAdded(uint256 indexed tokenId, uint256 indexed traitId, bytes32 categoryHash);
    event GlyphTraitRevoked(uint256 indexed tokenId, uint256 indexed traitId);

    event AttestationMade(bytes32 indexed attestationId, address indexed subject, bytes32 skillHash, uint256 level);
    event AttestationRevoked(bytes32 indexed attestationId);

    event ProposalCreated(bytes32 indexed proposalId, address indexed proposer, string description);
    event VoteCast(bytes32 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(bytes32 indexed proposalId);
    event DelegateVote(address indexed delegator, address indexed delegatee);

    event ModuleRegistered(bytes32 indexed moduleNameHash, address indexed moduleAddress);
    event ModuleUnregistered(bytes32 indexed moduleNameHash);

    event AIDrivenTraitSuggestionRequested(uint256 indexed tokenId, bytes32 indexed requestId);
    event AIDrivenTraitSuggestionFulfilled(uint256 indexed tokenId, bytes32 indexed requestId, string suggestedTraitURI);

    event ProtocolParameterChanged(bytes32 indexed key, bytes newValue);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); // Admin has highest privileges
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ATTESTER_ROLE, msg.sender);
        _grantRole(GOVERNOR_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
        _baseURI = "ipfs://Qmbd.../"; // Example base URI
    }

    // --- Modifier for governance execution ---
    modifier onlyGovernor() {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "EGN: Must have GOVERNOR_ROLE");
        _;
    }

    // --- I. Glyph Management (ERC-721 Base & Dynamics) ---

    /// @notice Mints a new Glyph NFT for an address, providing an initial base metadata URI.
    /// @param _to The address to mint the Glyph to.
    /// @param _baseMetadataURI The initial static metadata URI for the Glyph.
    function mintGlyph(address _to, string calldata _baseMetadataURI)
        public
        virtual
        onlyRole(MINTER_ROLE)
        whenNotPaused
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(_to, newItemId);
        glyphs[newItemId].owner = _to;
        glyphs[newItemId].baseMetadataURI = _baseMetadataURI;
        glyphs[newItemId].lastEvolutionTimestamp = block.timestamp;
        // Glyphs are soulbound by default, can be changed by governance
        glyphs[newItemId].isSoulbound = true;
        _ownerGlyphs[_to].add(newItemId);

        emit GlyphMinted(newItemId, _to, _baseMetadataURI);
        return newItemId;
    }

    /// @notice Allows the owner or an authorized entity to burn a Glyph.
    /// @dev May include conditions like not having active attestations or being soulbound.
    /// @param _tokenId The ID of the Glyph to burn.
    function burnGlyph(uint256 _tokenId) public virtual onlyRole(MINTER_ROLE) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "EGN: Caller is not owner nor approved");
        require(getAttestationsForGlyphOwner(ownerOf(_tokenId)).length() == 0, "EGN: Cannot burn Glyph with active attestations.");

        address owner = glyphs[_tokenId].owner;
        _ownerGlyphs[owner].remove(_tokenId);
        delete glyphs[_tokenId];
        _burn(_tokenId);

        emit GlyphBurned(_tokenId);
    }

    /// @notice Updates the static base metadata URI of a specific Glyph.
    /// @param _tokenId The ID of the Glyph to update.
    /// @param _newURI The new base metadata URI.
    function updateGlyphBaseMetadata(uint256 _tokenId, string calldata _newURI)
        public
        virtual
        onlyRole(MINTER_ROLE) // Or a specific metadata updater role
        whenNotPaused
    {
        require(bytes(_newURI).length > 0, "EGN: New URI cannot be empty");
        glyphs[_tokenId].baseMetadataURI = _newURI;
        emit GlyphBaseMetadataUpdated(_tokenId, _newURI);
    }

    /// @notice Returns a hash representing the current dynamic properties (traits, levels) of a Glyph.
    /// @dev This hash is an abstraction; a full metadata service would interpret this to build the final URI.
    /// @param _tokenId The ID of the Glyph.
    /// @return A bytes32 hash representing the current dynamic state.
    function getGlyphDynamicProperties(uint256 _tokenId) public view returns (bytes32) {
        return glyphs[_tokenId].dynamicPropertiesHash;
    }

    /// @notice Initiates a Glyph's evolutionary process based on a verified on-chain or oracle-attested trigger.
    /// @dev This could be a complex process updating multiple traits.
    /// @param _tokenId The ID of the Glyph to evolve.
    /// @param _evolutionTriggerHash A hash representing the verified trigger for evolution (e.g., specific achievement, time, oracle data).
    function triggerGlyphEvolution(uint256 _tokenId, bytes32 _evolutionTriggerHash)
        public
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "EGN: Caller is not owner nor approved");
        // Example: Only allow evolution after a certain cool-down period
        require(block.timestamp >= glyphs[_tokenId].lastEvolutionTimestamp + 1 days, "EGN: Glyph cooldown in effect.");

        // Simulate complex logic here: based on _evolutionTriggerHash and owner's attestations,
        // new traits might be added, existing ones updated, leading to a new dynamicPropertiesHash.
        // For simplicity, we just generate a new hash. In a real system, this would involve
        // querying attestations, external data, and applying specific evolution rules.

        bytes32 oldHash = glyphs[_tokenId].dynamicPropertiesHash;
        bytes32 newDynamicHash = keccak256(abi.encodePacked(oldHash, _evolutionTriggerHash, block.timestamp));
        glyphs[_tokenId].dynamicPropertiesHash = newDynamicHash;
        glyphs[_tokenId].lastEvolutionTimestamp = block.timestamp;

        // Example: Add a new trait upon evolution
        _traitIdCounter.increment();
        uint256 newTraitId = _traitIdCounter.current();
        bytes32 newCategoryHash = keccak256(abi.encodePacked("EvolutionaryTrait-", newDynamicHash));
        dynamicTraits[newTraitId] = DynamicTrait(newTraitId, "evolution-stage-2.json", newCategoryHash, 0); // Permanent
        glyphs[_tokenId].activeTraits.add(newTraitId);
        emit GlyphTraitAdded(_tokenId, newTraitId, newCategoryHash);

        emit GlyphEvolutionTriggered(_tokenId, _evolutionTriggerHash, newDynamicHash);
    }

    /// @notice Checks if a Glyph is currently undergoing an active evolution process (e.g., in a multi-step process).
    /// @dev Placeholder for more complex state management.
    /// @param _tokenId The ID of the Glyph.
    /// @return True if the Glyph is evolving, false otherwise.
    function isGlyphEvolving(uint256 _tokenId) public view returns (bool) {
        // In a real system, this could check for a pending state,
        // or a multi-day evolutionary cooldown. For now, it's always false after trigger.
        return false;
    }

    /// @notice Revokes a specific dynamically added trait from a Glyph.
    /// @dev This could be based on expiration, negative actions, or governance decision.
    /// @param _tokenId The ID of the Glyph.
    /// @param _traitId The ID of the trait to revoke.
    function revokeGlyphTrait(uint256 _tokenId, uint256 _traitId) public onlyRole(ADMIN_ROLE) whenNotPaused {
        require(glyphs[_tokenId].activeTraits.contains(_traitId), "EGN: Glyph does not have this trait.");

        glyphs[_tokenId].activeTraits.remove(_traitId);
        // Optionally update dynamicPropertiesHash after trait removal
        // For simplicity, not updating hash automatically here. A metadata service would handle this.
        delete dynamicTraits[_traitId]; // Remove the trait definition itself

        emit GlyphTraitRevoked(_tokenId, _traitId);
    }

    /// @notice Overrides standard ERC-721 transfer to include conditional checks (e.g., if soulbound).
    /// @param from The address from which to transfer.
    /// @param to The address to which to transfer.
    /// @param tokenId The ID of the Glyph to transfer.
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        require(!glyphs[tokenId].isSoulbound, "EGN: Soulbound Glyphs cannot be transferred.");
        super.transferFrom(from, to, tokenId);
    }

    /// @dev Overrides safeTransferFrom for similar soulbound checks.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        require(!glyphs[tokenId].isSoulbound, "EGN: Soulbound Glyphs cannot be transferred.");
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev Overrides safeTransferFrom with data for similar soulbound checks.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override(ERC721) {
        require(!glyphs[tokenId].isSoulbound, "EGN: Soulbound Glyphs cannot be transferred.");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // --- II. Attestation & Reputation System ---

    /// @notice An authorized attester vouches for a skill or achievement of a user (linked to their Glyph).
    /// @param _subject The address of the user receiving the attestation.
    /// @param _skillHash A unique identifier for the skill/achievement.
    /// @param _level The level or score associated with the skill.
    /// @param _expirationTimestamp The timestamp when the attestation expires (0 for permanent).
    function attestSkill(address _subject, bytes32 _skillHash, uint256 _level, uint256 _expirationTimestamp)
        public
        onlyRole(ATTESTER_ROLE)
        whenNotPaused
        nonReentrant
    {
        // Require _subject to own a Glyph to receive attestation
        require(_ownerGlyphs[_subject].length() > 0, "EGN: Subject must own a Glyph to receive attestation.");

        _attestationIdCounter.increment();
        bytes32 attestationId = keccak256(abi.encodePacked(_subject, _skillHash, _attestationIdCounter.current()));

        attestations[attestationId] = Attestation({
            attester: _msgSender(),
            subject: _subject,
            skillHash: _skillHash,
            level: _level,
            expirationTimestamp: _expirationTimestamp,
            timestamp: block.timestamp,
            revoked: false
        });

        _subjectAttestations[_subject].add(attestationId);

        // Optionally, trigger Glyph's dynamicPropertiesHash update based on new attestation
        uint256 glyphId = _ownerGlyphs[_subject].at(0); // Assuming one primary Glyph per user for simplicity
        glyphs[glyphId].dynamicPropertiesHash = keccak256(abi.encodePacked(
            glyphs[glyphId].dynamicPropertiesHash, attestationId, block.timestamp
        ));

        emit AttestationMade(attestationId, _subject, _skillHash, _level);
    }

    /// @notice Revokes an existing attestation.
    /// @dev Can only be done by the original attester or an ADMIN.
    /// @param _attestationId The ID of the attestation to revoke.
    function revokeAttestation(bytes32 _attestationId) public whenNotPaused {
        Attestation storage attestation = attestations[_attestationId];
        require(attestation.attester != address(0), "EGN: Attestation does not exist.");
        require(
            _msgSender() == attestation.attester || hasRole(ADMIN_ROLE, _msgSender()),
            "EGN: Only original attester or ADMIN can revoke."
        );
        require(!attestation.revoked, "EGN: Attestation already revoked.");

        attestation.revoked = true;
        _subjectAttestations[attestation.subject].remove(_attestationId);

        // Re-calculate dynamicPropertiesHash for the associated Glyph, if needed.
        // This is a complex operation and typically done off-chain or via a dedicated trait module.
        // For simplicity here, we only remove the attestation record.

        emit AttestationRevoked(_attestationId);
    }

    /// @notice Retrieves all active attestations associated with a Glyph owner.
    /// @param _owner The address of the Glyph owner.
    /// @return An array of active Attestation IDs.
    function getAttestationsForGlyphOwner(address _owner) public view returns (bytes32[] memory) {
        bytes32[] memory activeAttestations = new bytes32[](_subjectAttestations[_owner].length());
        uint256 count = 0;
        for (uint256 i = 0; i < _subjectAttestations[_owner].length(); i++) {
            bytes32 attId = _subjectAttestations[_owner].at(i);
            if (!attestations[attId].revoked && (attestations[attId].expirationTimestamp == 0 || attestations[attId].expirationTimestamp > block.timestamp)) {
                activeAttestations[count] = attId;
                count++;
            }
        }
        bytes32[] memory resized = new bytes32[](count);
        for(uint256 i = 0; i < count; i++){
            resized[i] = activeAttestations[i];
        }
        return resized;
    }

    /// @notice Returns the current attested skill level for a subject.
    /// @dev If multiple attestations exist for the same skill, the highest active level is returned.
    /// @param _subject The address of the subject.
    /// @param _skillHash The hash of the skill.
    /// @return The highest active skill level found, or 0 if none.
    function querySkillLevel(address _subject, bytes32 _skillHash) public view returns (uint256) {
        uint256 highestLevel = 0;
        for (uint256 i = 0; i < _subjectAttestations[_subject].length(); i++) {
            bytes32 attId = _subjectAttestations[_subject].at(i);
            Attestation storage att = attestations[attId];
            if (!att.revoked && att.skillHash == _skillHash && (att.expirationTimestamp == 0 || att.expirationTimestamp > block.timestamp)) {
                if (att.level > highestLevel) {
                    highestLevel = att.level;
                }
            }
        }
        return highestLevel;
    }

    /// @notice Initiates a governance proposal to add a new authorized attester role.
    /// @param _newAttester The address to be proposed as a new attester.
    /// @return The ID of the created proposal.
    function proposeNewAttester(address _newAttester) public onlyGovernor returns (bytes32) {
        require(_msgSender() == address(this) || votingPower[_msgSender()] >= PROPOSAL_THRESHOLD, "EGN: Not enough voting power to propose.");

        _proposalIdCounter.increment();
        bytes32 proposalId = keccak256(abi.encodePacked("AttesterProposal", _newAttester, _proposalIdCounter.current()));

        // Encode the grantRole call for the new attester
        bytes memory callData = abi.encodeWithSelector(
            this.grantRole.selector,
            ATTESTER_ROLE,
            _newAttester
        );

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            startBlock: block.number + MIN_VOTING_DELAY,
            endBlock: block.number + MIN_VOTING_DELAY + VOTING_PERIOD,
            data: callData,
            target: address(this), // The target for execution is this contract
            description: string(abi.encodePacked("Grant ATTESTER_ROLE to ", Strings.toHexString(uint160(_newAttester), 20))),
            votesFor: 0,
            votesAgainst: 0,
            quorum: DEFAULT_QUORUM,
            executed: false,
            state: ProposalState.Pending
        });

        emit ProposalCreated(proposalId, _msgSender(), proposals[proposalId].description);
        return proposalId;
    }

    /// @notice Allows users with voting power to vote on attester proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _approve True for 'yes', false for 'no'.
    function voteForAttesterProposal(bytes32 _proposalId, bool _approve) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "EGN: Proposal does not exist.");
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "EGN: Proposal not in active voting state.");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "EGN: Voting is not open or has ended.");
        require(!proposal.hasVoted[_msgSender()], "EGN: Already voted on this proposal.");

        uint256 voterPower = getVotingPower(_msgSender());
        require(voterPower > 0, "EGN: Caller has no voting power.");

        proposal.hasVoted[_msgSender()] = true;
        if (_approve) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }

        emit VoteCast(_proposalId, _msgSender(), _approve, voterPower);
    }

    // --- III. Protocol Governance & Modularity ---

    /// @notice Registers a new functional module (an external contract) into the Nexus.
    /// @dev This allows the governance to manage or interact with external contracts.
    /// @param _moduleAddress The address of the module contract.
    /// @param _moduleNameHash A unique hash identifier for the module.
    /// @param _requiredQuorum Specific quorum for proposals targeting this module (0 for default).
    function registerModule(address _moduleAddress, bytes32 _moduleNameHash, uint256 _requiredQuorum)
        public
        onlyGovernor // Should be through a governance proposal typically
        whenNotPaused
    {
        require(_moduleAddress != address(0), "EGN: Invalid module address.");
        require(!modules[_moduleNameHash].registered, "EGN: Module already registered.");

        modules[_moduleNameHash] = Module({
            moduleAddress: _moduleAddress,
            requiredQuorum: _requiredQuorum == 0 ? DEFAULT_QUORUM : _requiredQuorum,
            registered: true
        });

        emit ModuleRegistered(_moduleNameHash, _moduleAddress);
    }

    /// @notice Unregisters an existing module from the Nexus.
    /// @dev Should typically be done via a governance proposal.
    /// @param _moduleNameHash The hash identifier of the module to unregister.
    function unregisterModule(bytes32 _moduleNameHash) public onlyGovernor whenNotPaused {
        require(modules[_moduleNameHash].registered, "EGN: Module not registered.");

        modules[_moduleNameHash].registered = false;
        delete modules[_moduleNameHash]; // Clear storage

        emit ModuleUnregistered(_moduleNameHash);
    }

    /// @notice Proposes a change to a core protocol parameter.
    /// @param _parameterKey A unique key identifying the parameter (e.g., keccak256("VOTING_PERIOD")).
    /// @param _newValue The new value for the parameter, encoded as bytes.
    /// @return The ID of the created proposal.
    function proposeParameterChange(bytes32 _parameterKey, bytes _newValue) public onlyGovernor returns (bytes32) {
        require(votingPower[_msgSender()] >= PROPOSAL_THRESHOLD, "EGN: Not enough voting power to propose.");

        _proposalIdCounter.increment();
        bytes32 proposalId = keccak256(abi.encodePacked("ParameterChange", _parameterKey, _newValue, _proposalIdCounter.current()));

        // In a real system, you'd have a specific `_setParameter(bytes32, bytes)` function
        // that this `data` calls to update the internal state based on `_parameterKey`.
        // For simplicity, we just store the data. The `executeProposal` would need to interpret this.
        string memory description = string(abi.encodePacked("Change parameter ", Strings.toHexString(uint256(_parameterKey)), " to new value."));

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            startBlock: block.number + MIN_VOTING_DELAY,
            endBlock: block.number + MIN_VOTING_DELAY + VOTING_PERIOD,
            data: _newValue, // Store the new value directly for internal parameter changes
            target: address(this), // Target is this contract
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            quorum: DEFAULT_QUORUM,
            executed: false,
            state: ProposalState.Pending
        });

        emit ProposalCreated(proposalId, _msgSender(), description);
        return proposalId;
    }

    /// @notice Casts a vote on any active governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _approve True for 'yes', false for 'no'.
    function voteOnProposal(bytes32 _proposalId, bool _approve) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "EGN: Proposal does not exist.");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "EGN: Voting is not open or has ended.");
        require(!proposal.hasVoted[_msgSender()], "EGN: Already voted on this proposal.");

        uint256 voterPower = getVotingPower(_msgSender());
        require(voterPower > 0, "EGN: Caller has no voting power.");

        proposal.hasVoted[_msgSender()] = true;
        if (_approve) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }

        // Update proposal state dynamically
        _updateProposalState(_proposalId);

        emit VoteCast(_proposalId, _msgSender(), _approve, voterPower);
    }

    /// @notice Executes a passed governance proposal after a time lock.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(bytes32 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "EGN: Proposal does not exist.");
        require(!proposal.executed, "EGN: Proposal already executed.");

        // Ensure voting period has ended and it succeeded
        _updateProposalState(_proposalId);
        require(proposal.state == ProposalState.Succeeded, "EGN: Proposal has not succeeded.");
        // A timelock mechanism would typically be here (e.g., proposal.endBlock + EXECUTION_DELAY)

        proposal.executed = true;

        // Execute the proposal's intended action
        // For parameter changes, this would be `_setParameter(_parameterKey, _newValue)`
        // For module registration/unregistration, it would call those internal functions.
        (bool success, ) = proposal.target.call(proposal.data);
        require(success, "EGN: Proposal execution failed.");

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows users to delegate their voting power to another address.
    /// @param _delegatee The address to delegate voting power to.
    function delegateVote(address _delegatee) public {
        require(_delegatee != address(0), "EGN: Delegatee cannot be zero address.");
        require(_delegatee != _msgSender(), "EGN: Cannot delegate to self.");

        address oldDelegatee = delegates[_msgSender()];
        if (oldDelegatee != address(0)) {
            votingPower[oldDelegatee] -= votingPower[_msgSender()];
        }

        delegates[_msgSender()] = _delegatee;
        votingPower[_delegatee] += votingPower[_msgSender()]; // Add delegator's power to delegatee

        emit DelegateVote(_msgSender(), _delegatee);
    }

    /// @dev Internal function to update a proposal's state based on current block and vote counts.
    function _updateProposalState(bytes32 _proposalId) internal view {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.executed) {
            proposal.state = ProposalState.Executed;
        } else if (block.number < proposal.startBlock) {
            proposal.state = ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            proposal.state = ProposalState.Active;
        } else { // Voting period has ended
            if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= proposal.quorum) {
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Failed;
            }
        }
    }

    /// @notice Returns the current voting power of an address.
    /// @dev This can be based on owned Glyphs, staked tokens, or other factors.
    ///      For simplicity, it's a fixed value or based on a token balance.
    ///      Here, we just return a base value.
    function getVotingPower(address _voter) public view returns (uint256) {
        if (delegates[_voter] != address(0)) {
            return votingPower[delegates[_voter]]; // Delegatee's accumulated power
        }
        // Example: 1 voting power per Glyph owned (simplistic)
        return _ownerGlyphs[_voter].length() > 0 ? 100 : 0; // Each Glyph might give 100 voting power.
    }

    // --- IV. Oracle Integration & AI-Driven Traits (Simulated) ---

    /// @notice Simulates a request to an off-chain AI oracle for dynamic trait suggestions.
    /// @param _tokenId The ID of the Glyph for which suggestions are requested.
    /// @param _requestId A unique ID for this oracle request (generated off-chain or by a helper).
    function requestAIDrivenTraitSuggestion(uint256 _tokenId, bytes32 _requestId)
        public
        _ownerOf(_tokenId) // Only Glyph owner can request
        whenNotPaused
    {
        // In a real system, this would interact with an oracle contract (e.g., Chainlink)
        // that handles external requests and callbacks.
        // For this contract, we simply log the request.
        emit AIDrivenTraitSuggestionRequested(_tokenId, _requestId);
    }

    /// @notice The authorized oracle fulfills a trait suggestion request, updating the Glyph's dynamic metadata.
    /// @param _tokenId The ID of the Glyph.
    /// @param _suggestedTraitURI The URI fragment for the new AI-driven trait.
    /// @param _requestId The ID of the original oracle request.
    /// @param _oracleSignature A cryptographic signature verifying the oracle's authenticity.
    function fulfillAIDrivenTraitSuggestion(uint256 _tokenId, string calldata _suggestedTraitURI, bytes32 _requestId, bytes calldata _oracleSignature)
        public
        onlyRole(ORACLE_ROLE) // Only a trusted oracle can fulfill
        whenNotPaused
    {
        // Simulate signature verification for robustness in a real system
        // require(_verifyOracleSignature(_requestId, _suggestedTraitURI, _oracleSignature), "EGN: Invalid oracle signature.");

        // Add the new trait to the Glyph
        _traitIdCounter.increment();
        uint256 newTraitId = _traitIdCounter.current();
        bytes32 categoryHash = keccak256(abi.encodePacked("AI-Driven-Trait-", _requestId));
        dynamicTraits[newTraitId] = DynamicTrait(newTraitId, _suggestedTraitURI, categoryHash, block.timestamp + 365 days); // Expires in 1 year
        glyphs[_tokenId].activeTraits.add(newTraitId);

        // Update the Glyph's dynamic properties hash
        glyphs[_tokenId].dynamicPropertiesHash = keccak256(abi.encodePacked(
            glyphs[_tokenId].dynamicPropertiesHash, newTraitId, _suggestedTraitURI, block.timestamp
        ));

        emit GlyphTraitAdded(_tokenId, newTraitId, categoryHash);
        emit AIDrivenTraitSuggestionFulfilled(_tokenId, _requestId, _suggestedTraitURI);
    }

    /// @notice Allows a Glyph owner to claim a specific reward if predefined conditions are met.
    /// @dev Conditions could be specific attestations, module interactions, or time-based.
    /// @param _tokenId The ID of the Glyph.
    /// @param _achievementHash A hash representing the achievement being claimed.
    function claimAchievementReward(uint256 _tokenId, bytes32 _achievementHash)
        public
        _ownerOf(_tokenId)
        whenNotPaused
        nonReentrant
    {
        // Example condition: Must have a specific skill level
        require(querySkillLevel(_msgSender(), keccak256("MasterySkill")) >= 5, "EGN: Requires MasterySkill Level 5.");
        // Check if achievement already claimed or other conditions
        // In a real system, this would involve a mapping of claimed achievements.
        // For simplicity, we just trigger a trait addition.

        _traitIdCounter.increment();
        uint256 newTraitId = _traitIdCounter.current();
        bytes32 categoryHash = keccak256(abi.encodePacked("Achievement-", _achievementHash));
        dynamicTraits[newTraitId] = DynamicTrait(newTraitId, "achievement-badge.json", categoryHash, 0); // Permanent
        glyphs[_tokenId].activeTraits.add(newTraitId);

        // Update the Glyph's dynamic properties hash
        glyphs[_tokenId].dynamicPropertiesHash = keccak256(abi.encodePacked(
            glyphs[_tokenId].dynamicPropertiesHash, newTraitId, _achievementHash, block.timestamp
        ));

        emit GlyphTraitAdded(_tokenId, newTraitId, categoryHash);
    }

    /// @dev Internal helper for oracle signature verification (simulated).
    function _verifyOracleSignature(bytes32 _requestId, string calldata _suggestedTraitURI, bytes calldata _signature)
        internal pure returns (bool)
    {
        // In a production system, this would involve actual cryptographic verification
        // against a known oracle public key. For simulation, it always returns true.
        return true;
    }

    // --- V. Emergency & Utility Functions ---

    /// @notice Pauses certain critical functions of the protocol in an emergency.
    function pauseProtocol() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the protocol.
    function unpauseProtocol() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Sets the base URI for ERC-721 metadata.
    function setBaseURI(string calldata _newBaseURI) public onlyRole(ADMIN_ROLE) {
        _baseURI = _newBaseURI;
    }

    /// @notice Allows the treasury or governance to withdraw collected protocol fees.
    /// @dev This contract itself doesn't explicitly collect fees in this example, but it's a common pattern.
    ///      A fee collection mechanism would need to be implemented (e.g., on mint, on evolution).
    /// @param _to The address to send the fees to.
    /// @param _amount The amount of fees to withdraw.
    function withdrawProtocolFees(address _to, uint256 _amount) public onlyRole(ADMIN_ROLE) {
        require(address(this).balance >= _amount, "EGN: Insufficient contract balance.");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "EGN: Fee withdrawal failed.");
    }

    // --- Internal & View Helpers ---

    /// @dev See {ERC721-_baseURI}.
    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    /// @dev Custom `_ownerOf` check for `requestAIDrivenTraitSuggestion` and `claimAchievementReward`
    modifier _ownerOf(uint256 tokenId) {
        require(ERC721.ownerOf(tokenId) == _msgSender(), "EGN: Caller is not Glyph owner");
        _;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
```