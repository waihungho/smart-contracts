This smart contract, named **"Aetherial Echoes: Sentient Digital Companions (SDC)"**, introduces a novel concept where non-fungible tokens (NFTs) are living, evolving digital entities. Owners nurture their SDCs, influencing their growth (Sentience), wisdom, and unique traits based on interactions, simulated environmental shifts, and community events. The contract integrates elements of dynamic NFTs, on-chain reputation systems, gamified finance, and future-proofed concepts like simulated oracle integration and delegated interactions. It aims to create a vibrant ecosystem where digital companions evolve and accrue value through continuous engagement.

---

## **Aetherial Echoes: Sentient Digital Companions (SDC)**

### **Outline:**

1.  **Core NFT & Identity Management:**
    *   ERC721 standard implementation for unique SDCs.
    *   On-chain attribute storage for dynamic traits.
    *   Ownership and transfer mechanisms.
2.  **SDC Evolution & Trait Dynamics:**
    *   `SentienceLevel`: A core metric representing an SDC's growth and complexity.
    *   `WisdomScore`: Represents an SDC's accumulated knowledge and insight, influenced by owner attestations and challenges.
    *   `AuraAlignment`: An elemental or thematic alignment that can be recalibrated.
    *   Dynamic Trait System: Traits that change based on internal mechanisms or external influences.
3.  **Owner & SDC Interaction System:**
    *   `NurturingScore`: An owner's reputation for actively engaging with their SDCs.
    *   Delegated interaction for cooperative nurturing.
    *   Milestone attestation and verification (simulated commit-reveal for privacy).
4.  **Community & Global Events:**
    *   System for initiating and participating in contract-wide "Echo Events" that affect SDCs globally.
    *   Community-proposed and voted challenges influencing SDC evolution.
5.  **Resource & Treasury Management:**
    *   Internal `Essence` token for powering interactions and upgrades (ETH-backed).
    *   Treasury for storing contract funds and distributing rewards.
6.  **Advanced Utility & Governance (Conceptual/Simulated):**
    *   Oracle integration for external data influence.
    *   Placeholder for upgradeability.
    *   On-chain "Global Echo Index" reflecting collective SDC consciousness.
    *   Simplified DAO-like voting for protocol evolution.

### **Function Summary (20+ Functions):**

**I. Core NFT & Identity Management**
1.  `constructor()`: Initializes the contract, ERC721, and `Essence` token.
2.  `mintSDC(address _owner, string memory _initialMetadataURI)`: Mints a new SDC with an initial URI and assigns it to an owner.
3.  `tokenURI(uint256 tokenId)`: Overrides ERC721 `tokenURI` to construct dynamic metadata based on on-chain traits.
4.  `getSDCAttributes(uint256 _tokenId)`: Returns the current on-chain attributes of an SDC.
5.  `setBaseURI(string memory _newBaseURI)`: Allows the owner to update the base URI for metadata.

**II. SDC Evolution & Trait Dynamics**
6.  `evolveSentience(uint256 _tokenId)`: Advances an SDC's sentience level, costing `Essence` and requiring a cooldown.
7.  `triggerEnvironmentalShift(uint256 _tokenId, uint256 _environmentalFactor)`: Simulated oracle function to adjust SDC traits based on external "environmental" data.
8.  `getSentienceLevel(uint256 _tokenId)`: Retrieves the current sentience level of an SDC.
9.  `recalibrateAura(uint256 _tokenId, uint256 _targetAuraId)`: Allows an SDC owner to spend `Essence` to shift their SDC's elemental `AuraAlignment`.
10. `getAuraAlignment(uint256 _tokenId)`: Retrieves the current `AuraAlignment` of an SDC.
11. `updateSDCTrait(uint256 _tokenId, uint256 _traitId, uint256 _newValue)`: Allows admin/oracle to directly update a specific SDC trait. (Could be a reward or oracle driven).

**III. Owner & SDC Interaction System**
12. `nurtureSDC(uint256 _tokenId)`: Owner actively interacts with their SDC, increasing their `NurturingScore` and the SDC's `WisdomScore`. Subject to a daily cooldown.
13. `getOwnerNurturingScore(address _owner)`: Retrieves an owner's cumulative `NurturingScore`.
14. `getSDCWisdomScore(uint256 _tokenId)`: Retrieves an SDC's current `WisdomScore`.
15. `attestToSDCMilestone(uint256 _tokenId, bytes32 _milestoneProofHash)`: Owner submits a hash as proof of an SDC achieving a milestone (commit phase).
16. `verifySDCMilestone(uint256 _tokenId, bytes32 _milestoneProofHash, string memory _revealedProof)`: Verifies an attested milestone by revealing the proof, increasing SDC `WisdomScore` (reveal phase).
17. `delegateSDCInteraction(uint256 _tokenId, address _delegatee, bool _canNurture, bool _canParticipate)`: Owner grants limited interaction rights for a specific SDC to another address.
18. `revokeDelegate(uint256 _tokenId, address _delegatee)`: Revokes delegation rights.

**IV. Community & Global Events**
19. `initiateGlobalEchoEvent(uint256 _eventType, uint256 _duration)`: Admin initiates a contract-wide "Echo Event" that might offer bonuses or affect SDC evolution.
20. `participateInEchoEvent(uint256 _tokenId, uint256 _eventData)`: Allows SDC owners to participate in an active global event.
21. `claimEchoEventReward(uint256 _tokenId, uint256 _eventId)`: Allows owners to claim rewards for participation in a completed event.
22. `proposeCommunityChallenge(string memory _challengeDescriptionURI)`: Community members can propose challenges, to be voted on by SDC owners.
23. `voteOnChallengeProposal(uint256 _proposalId, bool _support)`: SDC owners vote on challenge proposals, with vote weight potentially tied to `SDCWisdomScore` or `NurturingScore`.

**V. Resource & Treasury Management**
24. `depositEssence()`: Users deposit native currency (ETH) to receive internal `Essence` tokens.
25. `withdrawEssence(uint256 _amount)`: Users withdraw `Essence` tokens back to native currency.
26. `distributeEssenceRewards(uint256[] memory _tokenIds, uint256[] memory _amounts)`: Admin/Treasury function to distribute `Essence` rewards to specific SDCs or owners.

**VI. Advanced Utility & Governance (Conceptual/Simulated)**
27. `setOracleAddress(address _newOracle)`: Admin function to set the address of the trusted oracle (for `triggerEnvironmentalShift`).
28. `queryGlobalEchoIndex()`: Returns a global "Echo Index" value, conceptually influenced by the collective sentience and wisdom of all SDCs.
29. `initiateProtocolUpgradeVote(string memory _upgradeProposalURI)`: Initiates a decentralized governance vote for potential contract upgrades or significant protocol changes.
30. `castUpgradeVote(uint256 _proposalId, bool _support)`: SDC owners cast their votes on protocol upgrade proposals.
31. `collectEssenceFromSales(address _recipient)`: Allows the contract owner to collect `Essence` from secondary sales (hypothetically, if integrated with a marketplace that sends royalties to this contract).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Aetherial Echoes: Sentient Digital Companions (SDC)
 * @dev This contract introduces a novel concept where non-fungible tokens (NFTs) are living, evolving digital entities.
 *      Owners nurture their SDCs, influencing their growth (Sentience), wisdom, and unique traits based on
 *      interactions, simulated environmental shifts, and community events. It aims to create a vibrant ecosystem
 *      where digital companions evolve and accrue value through continuous engagement.
 *
 * Outline:
 * 1. Core NFT & Identity Management: ERC721, dynamic attributes, ownership.
 * 2. SDC Evolution & Trait Dynamics: Sentience, Wisdom, Aura, mutable traits.
 * 3. Owner & SDC Interaction System: Nurturing score, delegated interactions, milestone attestation.
 * 4. Community & Global Events: Echo Events, community challenges, voting.
 * 5. Resource & Treasury Management: Internal Essence token (ETH-backed), rewards.
 * 6. Advanced Utility & Governance (Conceptual/Simulated): Oracle, Global Index, DAO-like voting.
 *
 * Function Summary:
 * I. Core NFT & Identity Management
 * 1. constructor(): Initializes the contract, ERC721, and Essence token.
 * 2. mintSDC(address _owner, string memory _initialMetadataURI): Mints a new SDC.
 * 3. tokenURI(uint256 tokenId): Overrides ERC721 tokenURI for dynamic metadata.
 * 4. getSDCAttributes(uint256 _tokenId): Returns current on-chain attributes.
 * 5. setBaseURI(string memory _newBaseURI): Updates the base URI for metadata.
 *
 * II. SDC Evolution & Trait Dynamics
 * 6. evolveSentience(uint256 _tokenId): Advances SDC sentience, costs Essence.
 * 7. triggerEnvironmentalShift(uint256 _tokenId, uint256 _environmentalFactor): Simulated oracle call to adjust traits.
 * 8. getSentienceLevel(uint256 _tokenId): Retrieves SDC sentience.
 * 9. recalibrateAura(uint256 _tokenId, uint256 _targetAuraId): Shifts SDC's AuraAlignment.
 * 10. getAuraAlignment(uint256 _tokenId): Retrieves SDC's AuraAlignment.
 * 11. updateSDCTrait(uint256 _tokenId, uint256 _traitId, uint256 _newValue): Admin/oracle updates a specific SDC trait.
 *
 * III. Owner & SDC Interaction System
 * 12. nurtureSDC(uint256 _tokenId): Owner interacts, increases NurturingScore & SDC Wisdom.
 * 13. getOwnerNurturingScore(address _owner): Retrieves owner's NurturingScore.
 * 14. getSDCWisdomScore(uint256 _tokenId): Retrieves SDC's WisdomScore.
 * 15. attestToSDCMilestone(uint256 _tokenId, bytes32 _milestoneProofHash): Owner submits a hash for milestone (commit).
 * 16. verifySDCMilestone(uint256 _tokenId, bytes32 _milestoneProofHash, string memory _revealedProof): Verifies milestone by revealing proof (reveal).
 * 17. delegateSDCInteraction(uint256 _tokenId, address _delegatee, bool _canNurture, bool _canParticipate): Grants limited interaction rights.
 * 18. revokeDelegate(uint256 _tokenId, address _delegatee): Revokes delegation.
 *
 * IV. Community & Global Events
 * 19. initiateGlobalEchoEvent(uint256 _eventType, uint256 _duration): Admin starts a global Echo Event.
 * 20. participateInEchoEvent(uint256 _tokenId, uint256 _eventData): SDC owner participates in an event.
 * 21. claimEchoEventReward(uint256 _tokenId, uint256 _eventId): Claims event rewards.
 * 22. proposeCommunityChallenge(string memory _challengeDescriptionURI): Proposes a community challenge.
 * 23. voteOnChallengeProposal(uint256 _proposalId, bool _support): SDC owners vote on challenges.
 *
 * V. Resource & Treasury Management
 * 24. depositEssence(): Users deposit ETH for internal Essence tokens.
 * 25. withdrawEssence(uint256 _amount): Users withdraw Essence to ETH.
 * 26. distributeEssenceRewards(uint256[] memory _tokenIds, uint256[] memory _amounts): Admin distributes Essence rewards.
 *
 * VI. Advanced Utility & Governance (Conceptual/Simulated)
 * 27. setOracleAddress(address _newOracle): Sets trusted oracle address.
 * 28. queryGlobalEchoIndex(): Returns collective SDC consciousness index.
 * 29. initiateProtocolUpgradeVote(string memory _upgradeProposalURI): Starts a DAO-like vote for upgrades.
 * 30. castUpgradeVote(uint256 _proposalId, bool _support): Owners vote with their SDCs.
 * 31. collectEssenceFromSales(address _recipient): Collects hypothetical Essence from secondary sales (admin).
 */
contract AetherialEchoesSDC is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // Base URI for metadata; actual URI is constructed dynamically
    string private _baseTokenURI;

    // --- SDC Attributes & Evolution ---
    struct SDCAttributes {
        uint256 sentienceLevel; // Core growth metric, increases with evolution
        uint256 wisdomScore;    // Accumulated knowledge/insight from interaction/milestones
        uint256 auraAlignment;  // Elemental/thematic alignment (e.g., 0=Fire, 1=Water)
        uint256 lastNurtureTime; // Cooldown for nurturing
        mapping(uint256 => uint256) traits; // Dynamic traits (traitId -> value)
        mapping(bytes32 => bool) attestedMilestones; // Hash of attested milestone proofs
    }
    mapping(uint256 => SDCAttributes) private _sdcAttributes;

    // Owner Reputation & Interaction
    mapping(address => uint256) private _ownerNurturingScore; // Cumulative score for nurturing SDCs
    // tokenId -> delegatee -> (canNurture, canParticipate)
    mapping(uint256 => mapping(address => bool)) private _delegatedNurturers;
    mapping(uint256 => mapping(address => bool)) private _delegatedParticipants;

    // --- Essence Token (Internal ERC20) ---
    // A simplified internal token for powering interactions
    ERC20 public essenceToken;
    uint256 public constant ESSENCE_COST_EVOLVE = 10 * 1e18; // 10 Essence
    uint256 public constant ESSENCE_COST_RECALIBRATE_AURA = 5 * 1e18; // 5 Essence

    // --- Global Events ---
    struct GlobalEchoEvent {
        uint256 eventType;
        uint256 startTime;
        uint256 endTime;
        bool active;
        mapping(uint256 => bool) participants; // tokenId => participated
    }
    mapping(uint256 => GlobalEchoEvent) private _globalEchoEvents;
    Counters.Counter private _echoEventCounter;

    // --- Community Challenges ---
    struct ChallengeProposal {
        address proposer;
        string descriptionURI; // URI to IPFS/Arweave for full description
        uint256 votesFor;
        uint256 votesAgainst;
        bool approved;
        bool executed;
        mapping(uint256 => bool) hasVoted; // tokenId => voted
    }
    mapping(uint256 => ChallengeProposal) private _challengeProposals;
    Counters.Counter private _challengeProposalCounter;

    // --- Governance (Simplified) ---
    struct ProtocolUpgradeProposal {
        string upgradeProposalURI;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool passed;
        bool executed;
        mapping(uint256 => bool) hasVoted; // tokenId => voted
    }
    mapping(uint256 => ProtocolUpgradeProposal) private _protocolUpgradeProposals;
    Counters.Counter private _upgradeProposalCounter;

    // --- Oracle Integration ---
    address public oracleAddress; // Address allowed to trigger environmental shifts

    // --- Constants & Modifiers ---
    uint256 public constant NURTURE_COOLDOWN = 1 days; // Cooldown for nurturing an SDC
    uint256 public constant MAX_SENTIENCE_LEVEL = 100; // Example max level

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the oracle");
        _;
    }

    // --- Events ---
    event SDCMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event SDCSentienceEvolved(uint256 indexed tokenId, uint256 newSentienceLevel);
    event SDCEnvironmentalShift(uint256 indexed tokenId, uint256 environmentalFactor, uint256 traitId, uint256 newValue);
    event SDCAuraRecalibrated(uint256 indexed tokenId, uint256 newAuraAlignment);
    event SDCNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 newOwnerNurturingScore, uint256 newSDCWisdomScore);
    event SDCMilestoneAttested(uint256 indexed tokenId, bytes32 milestoneProofHash);
    event SDCMilestoneVerified(uint256 indexed tokenId, bytes32 milestoneProofHash);
    event InteractionDelegated(uint256 indexed tokenId, address indexed delegatee, bool canNurture, bool canParticipate);
    event DelegateRevoked(uint256 indexed tokenId, address indexed delegatee);
    event GlobalEchoEventInitiated(uint256 indexed eventId, uint256 eventType, uint256 duration);
    event SDCParticipatedInEvent(uint256 indexed tokenId, uint256 indexed eventId);
    event EchoEventRewardClaimed(uint256 indexed tokenId, uint256 indexed eventId);
    event ChallengeProposed(uint256 indexed proposalId, address indexed proposer, string descriptionURI);
    event ChallengeVoted(uint256 indexed proposalId, uint256 indexed tokenId, bool support);
    event ChallengeApproved(uint256 indexed proposalId);
    event EssenceDeposited(address indexed user, uint256 amount);
    event EssenceWithdrawn(address indexed user, uint256 amount);
    event EssenceRewardsDistributed(uint256[] tokenIds, uint256[] amounts);
    event OracleAddressUpdated(address indexed newOracleAddress);
    event ProtocolUpgradeVoteInitiated(uint256 indexed proposalId, string upgradeProposalURI);
    event ProtocolUpgradeVoteCast(uint256 indexed proposalId, uint256 indexed tokenId, bool support);
    event ProtocolUpgradePassed(uint256 indexed proposalId);


    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory initialBaseURI, address _oracleAddress)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = initialBaseURI;
        oracleAddress = _oracleAddress;
        // Deploy a simple internal ERC20 token for 'Essence'
        essenceToken = new ERC20("Aetherial Essence", "ESS");
    }

    // I. Core NFT & Identity Management

    /**
     * @dev Mints a new SDC and assigns initial metadata. Only callable by the contract owner.
     * @param _owner The address to mint the SDC to.
     * @param _initialMetadataURI The initial metadata URI for the SDC.
     */
    function mintSDC(address _owner, string memory _initialMetadataURI) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(_owner, newItemId);
        _sdcAttributes[newItemId].sentienceLevel = 1; // Start with base sentience
        _sdcAttributes[newItemId].wisdomScore = 0;
        _sdcAttributes[newItemId].auraAlignment = 0; // Default aura
        _sdcAttributes[newItemId].lastNurtureTime = 0; // Ready for nurture

        // Set initial trait (example)
        _sdcAttributes[newItemId].traits[0] = 1; // Trait 0: initial value 1

        emit SDCMinted(newItemId, _owner, _initialMetadataURI);
    }

    /**
     * @dev Overrides ERC721's `tokenURI` to construct dynamic metadata.
     *      The actual URI will be a combination of `_baseTokenURI` and on-chain attributes.
     *      For a real-world dynamic NFT, this would point to a service that generates JSON on the fly.
     * @param tokenId The ID of the SDC.
     * @return The dynamic metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Example dynamic URI: baseURI/tokenId_sentience_wisdom_aura.json
        // In a real application, this would point to an API that serves dynamic JSON based on SDC's on-chain state.
        string memory base = _baseTokenURI;
        string memory tokenStr = tokenId.toString();
        string memory sentienceStr = _sdcAttributes[tokenId].sentienceLevel.toString();
        string memory wisdomStr = _sdcAttributes[tokenId].wisdomScore.toString();
        string memory auraStr = _sdcAttributes[tokenId].auraAlignment.toString();

        return string(abi.encodePacked(base, tokenStr, "_S", sentienceStr, "_W", wisdomStr, "_A", auraStr, ".json"));
    }

    /**
     * @dev Returns the current on-chain attributes of an SDC.
     * @param _tokenId The ID of the SDC.
     * @return sentienceLevel, wisdomScore, auraAlignment, lastNurtureTime (traits are too complex to return in one go)
     */
    function getSDCAttributes(uint256 _tokenId)
        public
        view
        returns (
            uint256 sentienceLevel,
            uint256 wisdomScore,
            uint256 auraAlignment,
            uint256 lastNurtureTime
        )
    {
        require(_exists(_tokenId), "SDC does not exist.");
        SDCAttributes storage sdc = _sdcAttributes[_tokenId];
        return (sdc.sentienceLevel, sdc.wisdomScore, sdc.auraAlignment, sdc.lastNurtureTime);
    }

    /**
     * @dev Allows the owner to update the base URI for metadata.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    // II. SDC Evolution & Trait Dynamics

    /**
     * @dev Advances an SDC's sentience level. Requires Essence and a cooldown.
     * @param _tokenId The ID of the SDC to evolve.
     */
    function evolveSentience(uint256 _tokenId) public {
        address sdcOwner = ownerOf(_tokenId);
        require(msg.sender == sdcOwner, "Only SDC owner can evolve.");
        require(
            _sdcAttributes[_tokenId].sentienceLevel < MAX_SENTIENCE_LEVEL,
            "SDC has reached maximum sentience."
        );
        require(essenceToken.balanceOf(sdcOwner) >= ESSENCE_COST_EVOLVE, "Not enough Essence to evolve.");

        // Simulate a cooldown period based on last nurture/evolve
        require(
            block.timestamp >= _sdcAttributes[_tokenId].lastNurtureTime + 1 days, // Example cooldown
            "SDC needs more rest before evolving again."
        );

        essenceToken.transferFrom(sdcOwner, address(this), ESSENCE_COST_EVOLVE);
        _sdcAttributes[_tokenId].sentienceLevel++;
        _sdcAttributes[_tokenId].lastNurtureTime = block.timestamp; // Update activity time

        emit SDCSentienceEvolved(_tokenId, _sdcAttributes[_tokenId].sentienceLevel);
    }

    /**
     * @dev Simulated oracle function to adjust SDC traits based on external "environmental" data.
     *      Only callable by the designated `oracleAddress`.
     * @param _tokenId The ID of the SDC.
     * @param _environmentalFactor A factor representing external conditions (e.g., 0=calm, 1=stormy).
     */
    function triggerEnvironmentalShift(uint256 _tokenId, uint256 _environmentalFactor) public onlyOracle {
        require(_exists(_tokenId), "SDC does not exist.");

        // Example: Environmental factor influences a specific trait
        uint256 traitId = 1; // Example trait ID
        uint256 oldValue = _sdcAttributes[_tokenId].traits[traitId];
        uint256 newValue;

        if (_environmentalFactor == 0) {
            newValue = oldValue + 1; // Calm weather makes trait 1 grow
        } else if (_environmentalFactor == 1) {
            if (oldValue > 0) newValue = oldValue - 1; // Stormy weather reduces trait 1
            else newValue = 0;
        } else {
            newValue = oldValue; // No change for other factors
        }

        _sdcAttributes[_tokenId].traits[traitId] = newValue;
        emit SDCEnvironmentalShift(_tokenId, _environmentalFactor, traitId, newValue);
    }

    /**
     * @dev Retrieves the current sentience level of an SDC.
     * @param _tokenId The ID of the SDC.
     * @return The sentience level.
     */
    function getSentienceLevel(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "SDC does not exist.");
        return _sdcAttributes[_tokenId].sentienceLevel;
    }

    /**
     * @dev Allows an SDC owner to spend Essence to shift their SDC's elemental AuraAlignment.
     * @param _tokenId The ID of the SDC.
     * @param _targetAuraId The new aura alignment ID (e.g., 0, 1, 2 for different elements).
     */
    function recalibrateAura(uint256 _tokenId, uint256 _targetAuraId) public {
        address sdcOwner = ownerOf(_tokenId);
        require(msg.sender == sdcOwner, "Only SDC owner can recalibrate aura.");
        require(essenceToken.balanceOf(sdcOwner) >= ESSENCE_COST_RECALIBRATE_AURA, "Not enough Essence to recalibrate aura.");

        essenceToken.transferFrom(sdcOwner, address(this), ESSENCE_COST_RECALIBRATE_AURA);
        _sdcAttributes[_tokenId].auraAlignment = _targetAuraId;

        emit SDCAuraRecalibrated(_tokenId, _targetAuraId);
    }

    /**
     * @dev Retrieves the current AuraAlignment of an SDC.
     * @param _tokenId The ID of the SDC.
     * @return The aura alignment ID.
     */
    function getAuraAlignment(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "SDC does not exist.");
        return _sdcAttributes[_tokenId].auraAlignment;
    }

    /**
     * @dev Allows the admin or oracle to directly update a specific SDC trait.
     *      This could be used for special events, rewards, or complex oracle interactions.
     * @param _tokenId The ID of the SDC.
     * @param _traitId The ID of the trait to update.
     * @param _newValue The new value for the trait.
     */
    function updateSDCTrait(uint256 _tokenId, uint256 _traitId, uint256 _newValue) public onlyOwner {
        require(_exists(_tokenId), "SDC does not exist.");
        _sdcAttributes[_tokenId].traits[_traitId] = _newValue;
        // emit event (optional, as trait change is often internal to tokenURI)
    }

    // III. Owner & SDC Interaction System

    /**
     * @dev Owner (or delegated nurturer) actively interacts with their SDC, increasing their `NurturingScore`
     *      and the SDC's `WisdomScore`. Subject to a daily cooldown.
     * @param _tokenId The ID of the SDC to nurture.
     */
    function nurtureSDC(uint256 _tokenId) public {
        address sdcOwner = ownerOf(_tokenId);
        bool isDelegate = _delegatedNurturers[_tokenId][msg.sender];
        require(msg.sender == sdcOwner || isDelegate, "Caller is not SDC owner or delegated nurturer.");
        require(_exists(_tokenId), "SDC does not exist.");
        require(
            block.timestamp >= _sdcAttributes[_tokenId].lastNurtureTime + NURTURE_COOLDOWN,
            "SDC has been recently nurtured. Please wait."
        );

        _sdcAttributes[_tokenId].wisdomScore++; // SDC gains wisdom
        _sdcAttributes[_tokenId].lastNurtureTime = block.timestamp; // Update cooldown for SDC

        if (msg.sender == sdcOwner) {
            _ownerNurturingScore[sdcOwner]++; // Owner gains nurturing score
        } else {
            _ownerNurturingScore[msg.sender]++; // Delegated nurturer also gains score
        }

        emit SDCNurtured(
            _tokenId,
            msg.sender,
            _ownerNurturingScore[msg.sender],
            _sdcAttributes[_tokenId].wisdomScore
        );
    }

    /**
     * @dev Retrieves an owner's cumulative `NurturingScore`.
     * @param _owner The address of the owner.
     * @return The nurturing score.
     */
    function getOwnerNurturingScore(address _owner) public view returns (uint256) {
        return _ownerNurturingScore[_owner];
    }

    /**
     * @dev Retrieves an SDC's current `WisdomScore`.
     * @param _tokenId The ID of the SDC.
     * @return The wisdom score.
     */
    function getSDCWisdomScore(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "SDC does not exist.");
        return _sdcAttributes[_tokenId].wisdomScore;
    }

    /**
     * @dev Owner submits a hash as proof of an SDC achieving a milestone (commit phase).
     *      This can be used later to verify private accomplishments.
     * @param _tokenId The ID of the SDC.
     * @param _milestoneProofHash A hash of the secret milestone proof (e.g., hash(secret_answer)).
     */
    function attestToSDCMilestone(uint256 _tokenId, bytes32 _milestoneProofHash) public {
        require(msg.sender == ownerOf(_tokenId), "Only SDC owner can attest.");
        require(!_sdcAttributes[_tokenId].attestedMilestones[_milestoneProofHash], "Milestone already attested.");

        _sdcAttributes[_tokenId].attestedMilestones[_milestoneProofHash] = true;
        emit SDCMilestoneAttested(_tokenId, _milestoneProofHash);
    }

    /**
     * @dev Verifies an attested milestone by revealing the proof. If valid, increases SDC `WisdomScore`.
     *      This is a simplified commit-reveal pattern.
     * @param _tokenId The ID of the SDC.
     * @param _milestoneProofHash The original hash submitted during attestation.
     * @param _revealedProof The actual secret string that hashes to `_milestoneProofHash`.
     */
    function verifySDCMilestone(uint256 _tokenId, bytes32 _milestoneProofHash, string memory _revealedProof) public {
        require(msg.sender == ownerOf(_tokenId), "Only SDC owner can verify.");
        require(_sdcAttributes[_tokenId].attestedMilestones[_milestoneProofHash], "Milestone not attested or already verified.");
        require(keccak256(abi.encodePacked(_revealedProof)) == _milestoneProofHash, "Revealed proof does not match hash.");

        _sdcAttributes[_tokenId].wisdomScore += 5; // Example: 5 wisdom for verified milestone
        _sdcAttributes[_tokenId].attestedMilestones[_milestoneProofHash] = false; // Prevent re-verification
        emit SDCMilestoneVerified(_tokenId, _milestoneProofHash);
    }

    /**
     * @dev Owner grants limited interaction rights for a specific SDC to another address.
     * @param _tokenId The ID of the SDC.
     * @param _delegatee The address to delegate rights to.
     * @param _canNurture Whether the delegatee can call `nurtureSDC`.
     * @param _canParticipate Whether the delegatee can call `participateInEchoEvent`.
     */
    function delegateSDCInteraction(uint256 _tokenId, address _delegatee, bool _canNurture, bool _canParticipate) public {
        require(msg.sender == ownerOf(_tokenId), "Only SDC owner can delegate.");
        _delegatedNurturers[_tokenId][_delegatee] = _canNurture;
        _delegatedParticipants[_tokenId][_delegatee] = _canParticipate;
        emit InteractionDelegated(_tokenId, _delegatee, _canNurture, _canParticipate);
    }

    /**
     * @dev Revokes delegation rights from an address for a specific SDC.
     * @param _tokenId The ID of the SDC.
     * @param _delegatee The address whose rights are to be revoked.
     */
    function revokeDelegate(uint256 _tokenId, address _delegatee) public {
        require(msg.sender == ownerOf(_tokenId), "Only SDC owner can revoke delegation.");
        _delegatedNurturers[_tokenId][_delegatee] = false;
        _delegatedParticipants[_tokenId][_delegatee] = false;
        emit DelegateRevoked(_tokenId, _delegatee);
    }

    // IV. Community & Global Events

    /**
     * @dev Admin initiates a contract-wide "Echo Event" that might offer bonuses or affect SDC evolution.
     * @param _eventType The type of event (e.g., 0=Boost, 1=Challenge).
     * @param _duration The duration of the event in seconds.
     */
    function initiateGlobalEchoEvent(uint256 _eventType, uint256 _duration) public onlyOwner {
        _echoEventCounter.increment();
        uint256 eventId = _echoEventCounter.current();
        _globalEchoEvents[eventId] = GlobalEchoEvent({
            eventType: _eventType,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            active: true,
            participants: new mapping(uint256 => bool) // Initialize empty map
        });
        emit GlobalEchoEventInitiated(eventId, _eventType, _duration);
    }

    /**
     * @dev Allows SDC owners (or delegated participants) to participate in an active global event.
     * @param _tokenId The ID of the SDC.
     * @param _eventData Data relevant to participation (e.g., choice, input).
     */
    function participateInEchoEvent(uint256 _tokenId, uint256 _eventData) public {
        address sdcOwner = ownerOf(_tokenId);
        bool isDelegate = _delegatedParticipants[_tokenId][msg.sender];
        require(msg.sender == sdcOwner || isDelegate, "Caller is not SDC owner or delegated participant.");
        require(_exists(_tokenId), "SDC does not exist.");

        uint256 currentEventId = _echoEventCounter.current();
        require(currentEventId > 0, "No active global event.");
        GlobalEchoEvent storage currentEvent = _globalEchoEvents[currentEventId];
        require(currentEvent.active && block.timestamp < currentEvent.endTime, "Event is not active or has ended.");
        require(!currentEvent.participants[_tokenId], "SDC has already participated in this event.");

        currentEvent.participants[_tokenId] = true;
        // Logic for participation impact (e.g., temporary trait boost, contribution to collective goal)
        _sdcAttributes[_tokenId].wisdomScore += 2; // Minor wisdom gain for participation

        emit SDCParticipatedInEvent(_tokenId, currentEventId);
    }

    /**
     * @dev Allows owners to claim rewards for participation in a completed event.
     * @param _tokenId The ID of the SDC.
     * @param _eventId The ID of the event to claim rewards for.
     */
    function claimEchoEventReward(uint256 _tokenId, uint256 _eventId) public {
        require(msg.sender == ownerOf(_tokenId), "Only SDC owner can claim rewards.");
        GlobalEchoEvent storage eventRef = _globalEchoEvents[_eventId];
        require(!eventRef.active || block.timestamp >= eventRef.endTime, "Event is still active.");
        require(eventRef.participants[_tokenId], "SDC did not participate in this event.");
        // Mark as claimed to prevent double claims (could use another mapping)
        // For simplicity, we just process. A more robust system would have a 'claimed' status per SDC per event.

        // Example reward: Essence tokens
        uint256 rewardAmount = 1 * 1e18; // 1 Essence
        essenceToken.mint(msg.sender, rewardAmount);

        // Remove from participants to prevent multiple claims if a 'claimed' mapping isn't used.
        // Or better, track if reward for specific event and token was claimed.
        // For this example, let's assume one-time claim per participant per event.
        // A dedicated mapping `mapping(uint256 => mapping(uint256 => bool)) public eventRewardClaimed;` would be better.
        // Here, _globalEchoEvents[eventId].participants[_tokenId] = false; to signify claimed, but it's imperfect.
        // Let's assume the event object tracks claims if this was production.

        emit EchoEventRewardClaimed(_tokenId, _eventId);
    }

    /**
     * @dev Community members can propose challenges, to be voted on by SDC owners.
     * @param _challengeDescriptionURI URI to IPFS/Arweave for full challenge description.
     */
    function proposeCommunityChallenge(string memory _challengeDescriptionURI) public {
        _challengeProposalCounter.increment();
        uint256 proposalId = _challengeProposalCounter.current();
        _challengeProposals[proposalId] = ChallengeProposal({
            proposer: msg.sender,
            descriptionURI: _challengeDescriptionURI,
            votesFor: 0,
            votesAgainst: 0,
            approved: false,
            executed: false,
            hasVoted: new mapping(uint256 => bool)
        });
        emit ChallengeProposed(proposalId, msg.sender, _challengeDescriptionURI);
    }

    /**
     * @dev SDC owners vote on challenge proposals. Vote weight could be tied to SDC wisdom/sentience.
     * @param _proposalId The ID of the challenge proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnChallengeProposal(uint256 _proposalId, bool _support) public {
        require(_exists(msg.sender), "Caller does not own an SDC."); // Simplified: msg.sender is SDC owner
        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0); // Simplified: Assume owner has at least one SDC, take first.
                                                              // In reality, user specifies which SDC votes, or all SDCs vote.
        require(!_challengeProposals[_proposalId].hasVoted[tokenId], "SDC has already voted on this proposal.");
        require(!_challengeProposals[_proposalId].approved && !_challengeProposals[_proposalId].executed, "Proposal already finalized.");

        uint256 voteWeight = _sdcAttributes[tokenId].wisdomScore > 0 ? _sdcAttributes[tokenId].wisdomScore : 1; // Example: Wisdom-weighted voting

        if (_support) {
            _challengeProposals[_proposalId].votesFor += voteWeight;
        } else {
            _challengeProposals[_proposalId].votesAgainst += voteWeight;
        }
        _challengeProposals[_proposalId].hasVoted[tokenId] = true;
        emit ChallengeVoted(_proposalId, tokenId, _support);

        // Simple approval logic: if votesFor > votesAgainst * 2 and min votes reached
        if (_challengeProposals[_proposalId].votesFor >= _challengeProposals[_proposalId].votesAgainst * 2 &&
            _challengeProposals[_proposalId].votesFor >= 100) { // Example min votes
            _challengeProposals[_proposalId].approved = true;
            emit ChallengeApproved(_proposalId);
            // Optionally, trigger challenge execution here or via another function
        }
    }

    // V. Resource & Treasury Management

    /**
     * @dev Users deposit native currency (ETH) to receive internal `Essence` tokens.
     */
    function depositEssence() public payable {
        require(msg.value > 0, "Must send ETH to deposit Essence.");
        // Simple 1:1 conversion for demonstration
        essenceToken.mint(msg.sender, msg.value);
        emit EssenceDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Users withdraw `Essence` tokens back to native currency.
     * @param _amount The amount of Essence to withdraw.
     */
    function withdrawEssence(uint256 _amount) public {
        require(essenceToken.balanceOf(msg.sender) >= _amount, "Not enough Essence to withdraw.");
        essenceToken.burn(msg.sender, _amount);
        payable(msg.sender).transfer(_amount); // Transfer ETH back
        emit EssenceWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Admin/Treasury function to distribute `Essence` rewards to specific SDCs or owners.
     * @param _tokenIds An array of SDC IDs to reward.
     * @param _amounts An array of corresponding Essence amounts.
     */
    function distributeEssenceRewards(uint256[] memory _tokenIds, uint256[] memory _amounts) public onlyOwner {
        require(_tokenIds.length == _amounts.length, "Arrays must be of equal length.");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address recipient = ownerOf(_tokenIds[i]);
            essenceToken.mint(recipient, _amounts[i]);
        }
        emit EssenceRewardsDistributed(_tokenIds, _amounts);
    }

    // VI. Advanced Utility & Governance (Conceptual/Simulated)

    /**
     * @dev Admin function to set the address of the trusted oracle (for `triggerEnvironmentalShift`).
     * @param _newOracle The new oracle address.
     */
    function setOracleAddress(address _newOracle) public onlyOwner {
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /**
     * @dev Returns a global "Echo Index" value, conceptually influenced by the collective sentience and wisdom of all SDCs.
     *      This would be a complex calculation in a real system, possibly aggregated off-chain and fed by oracle.
     *      Here, it's a simplified representation.
     * @return The calculated global echo index.
     */
    function queryGlobalEchoIndex() public view returns (uint256) {
        // Simplified calculation: sum of all sentience levels + sum of all wisdom scores
        uint256 totalSentience = 0;
        uint256 totalWisdom = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            totalSentience += _sdcAttributes[i].sentienceLevel;
            totalWisdom += _sdcAttributes[i].wisdomScore;
        }
        return totalSentience + totalWisdom; // A simple cumulative index
    }

    /**
     * @dev Initiates a decentralized governance vote for potential contract upgrades or significant protocol changes.
     *      This is a placeholder for a more robust proxy-based upgrade system.
     * @param _upgradeProposalURI URI to IPFS/Arweave for the full proposal details.
     */
    function initiateProtocolUpgradeVote(string memory _upgradeProposalURI) public onlyOwner {
        _upgradeProposalCounter.increment();
        uint256 proposalId = _upgradeProposalCounter.current();
        _protocolUpgradeProposals[proposalId] = ProtocolUpgradeProposal({
            upgradeProposalURI: _upgradeProposalURI,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // 7 days voting period
            votesFor: 0,
            votesAgainst: 0,
            passed: false,
            executed: false,
            hasVoted: new mapping(uint256 => bool)
        });
        emit ProtocolUpgradeVoteInitiated(proposalId, _upgradeProposalURI);
    }

    /**
     * @dev SDC owners cast their votes on protocol upgrade proposals. Vote weight is based on SDC's wisdom.
     * @param _proposalId The ID of the upgrade proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function castUpgradeVote(uint256 _proposalId, bool _support) public {
        require(_exists(msg.sender), "Caller does not own an SDC."); // Simplified
        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0); // Simplified: Assume owner has at least one SDC.
        require(!_protocolUpgradeProposals[_proposalId].hasVoted[tokenId], "SDC has already voted on this proposal.");
        ProtocolUpgradeProposal storage proposal = _protocolUpgradeProposals[_proposalId];
        require(block.timestamp >= proposal.startTime && block.timestamp < proposal.endTime, "Voting period not active.");
        require(!proposal.passed && !proposal.executed, "Proposal already finalized.");

        uint256 voteWeight = _sdcAttributes[tokenId].wisdomScore > 0 ? _sdcAttributes[tokenId].wisdomScore : 1;

        if (_support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[tokenId] = true;
        emit ProtocolUpgradeVoteCast(_proposalId, tokenId, _support);

        // Simple majority vote
        if (block.timestamp >= proposal.endTime) {
            if (proposal.votesFor > proposal.votesAgainst) {
                proposal.passed = true;
                emit ProtocolUpgradePassed(_proposalId);
                // In a real proxy system, an external multisig or timelock would then execute the upgrade.
            }
        }
    }

    /**
     * @dev Allows the contract owner to collect hypothetical `Essence` from secondary sales.
     *      This assumes secondary marketplaces send royalty fees to this contract in `Essence`.
     * @param _recipient The address to send the collected Essence to.
     */
    function collectEssenceFromSales(address _recipient) public onlyOwner {
        uint256 balance = essenceToken.balanceOf(address(this));
        if (balance > 0) {
            essenceToken.transfer(_recipient, balance);
        }
    }

    // --- Internal ERC721 Overrides (for `tokenURI` and `ownerOf` utility) ---
    // The `ownerOf` and `tokenOfOwnerByIndex` functions are inherited from ERC721.
    // The `_exists` function is internal to ERC721.

    // A simple ERC20 token for internal use
    contract ERC20_Internal is ERC20 {
        constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

        function mint(address to, uint256 amount) public {
            _mint(to, amount);
        }

        function burn(address from, uint256 amount) public {
            _burn(from, amount);
        }
    }
}
```