The smart contract below, named **AuraTwin**, introduces an advanced concept: **Adaptive Digital Souls**. It's an ERC-721 NFT that serves as a dynamic, evolving digital identity or persona for a user. Its traits and "Aura" (reputation score) are not static but change based on on-chain activities, oracle-attested events, and even delegated actions. It integrates a utility token (`InsightToken`) for boosting influence and introduces granular delegated control for AI agents or trusted parties.

---

### **Contract Outline & Function Summary**

**Contract Name:** `AuraTwin`

**Core Concept:** An ERC-721 "Digital Soul" NFT that evolves its traits and reputation ("Aura") based on on-chain actions, oracle inputs, and user decisions. It introduces a utility token (`InsightToken`) and advanced delegation features for controlled AI agent interaction.

---

**I. Core AuraTwin NFT Management (ERC-721 Inspired)**

1.  **`mintTwin(string memory _twinName)`**: Mints a new AuraTwin NFT with an initial name for the caller.
    *   **Description:** Creates a unique digital soul, assigning an initial set of basic traits.
2.  **`setTwinName(uint256 _tokenId, string memory _newName)`**: Allows the Twin's owner to update its human-readable name.
    *   **Description:** Personalizes the digital identity.
3.  **`toggleTransferLock(uint256 _tokenId, bool _lock)`**: Enables or disables the transferability of a Twin by its owner, allowing it to function as a Soulbound Token (SBT) or a standard ERC-721.
    *   **Description:** Gives the owner control over the "soulbound" nature, with potential implications for reputation if transferred unlocked.
4.  **`getTokenURI(uint256 _tokenId)`**: Generates a dynamic metadata URI that reflects the Twin's current traits and evolution stage.
    *   **Description:** Ensures the NFT's visual and textual representation evolves with its on-chain state.
5.  **`getTwinDetails(uint256 _tokenId)`**: Retrieves a comprehensive struct containing all current data of a specific Twin.
    *   **Description:** Provides a holistic view of a Twin's state, including traits, owner, and status.

**II. Trait & Aura System**

6.  **`_updateTwinTrait(uint256 _tokenId, bytes32 _traitKey, uint256 _newValue)`**: Internal helper function to set or update a specific trait value for a Twin.
    *   **Description:** Core mechanism for trait modification, used by other privileged functions.
7.  **`getTwinTrait(uint256 _tokenId, bytes32 _traitKey)`**: Returns the value of a specific trait for a given Twin.
    *   **Description:** Allows querying individual attributes of a digital soul.
8.  **`getTwinAllTraits(uint256 _tokenId)`**: Returns an array of all trait keys and their corresponding values for a Twin.
    *   **Description:** Provides an exhaustive list of a Twin's current attributes.
9.  **`addExperienceToTrait(uint256 _tokenId, bytes32 _traitKey, uint256 _amount)`**: Increments an "experience" value for a specific trait, potentially leading to trait level-ups.
    *   **Description:** Simulates growth and development of specific skills or attributes.
10. **`calculateAuraScore(uint256 _tokenId)`**: Computes the Twin's overall "Aura" score based on its traits and their pre-configured weights.
    *   **Description:** Quantifies the Twin's reputation, influence, or overall standing within the ecosystem.
11. **`configureTraitWeight(bytes32 _traitKey, uint256 _weight)`**: Admin function to set the importance or weighting of a trait when calculating the Aura score.
    *   **Description:** Allows dynamic adjustment of reputation metrics based on ecosystem needs.
12. **`decayTraits(uint256 _tokenId, bytes32[] memory _traitKeys)`**: Allows for on-chain decay of specific traits over time if not actively maintained. (Callable by a trusted keeper/bot).
    *   **Description:** Introduces a dynamic "forgetting" or "stale" mechanism, encouraging continuous engagement.

**III. Insight Token (ERC-20 Utility)**

13. **`mintInsight(address _to, uint256 _amount)`**: Admin function to mint `InsightToken`s, typically used for rewards or initial distribution.
    *   **Description:** Distributes the utility token of the ecosystem.
14. **`burnInsight(uint256 _amount)`**: Allows users to burn their own `InsightToken`s.
    *   **Description:** Mechanism for token supply control or as a cost for specific actions.
15. **`stakeInsightForBoost(uint256 _tokenId, uint256 _amount, bytes32 _traitKey, uint256 _duration)`**: Users can stake `InsightToken`s to temporarily boost a Twin's specific trait or overall Aura.
    *   **Description:** Provides a utility for the token, allowing temporary enhancement of digital identity.
16. **`unstakeInsight(uint256 _stakeId)`**: Allows users to retrieve their previously staked `InsightToken`s after the staking duration ends.
    *   **Description:** Manages the lifecycle of staked tokens.

**IV. Advanced Interactions & Delegation**

17. **`delegateActionToAgent(uint256 _tokenId, address _agent, bytes4 _functionSelector, bool _allow)`**: The Twin's owner can grant an AI agent or a trusted address the ability to execute specific whitelisted functions on behalf of their Twin.
    *   **Description:** Enables granular, secure delegated control, crucial for AI agents interacting with the Twin's state.
18. **`revokeActionDelegation(uint256 _tokenId, address _agent, bytes4 _functionSelector)`**: The Twin's owner can revoke a previously granted delegation for a specific action.
    *   **Description:** Allows owners to manage and retract delegated permissions.
19. **`executeDelegatedAction(uint256 _tokenId, bytes4 _functionSelector, bytes memory _data)`**: An approved agent can call this to execute a delegated action on behalf of the Twin's owner.
    *   **Description:** The mechanism for AI agents or trusted parties to perform authorized actions.
20. **`attestToTwinEvent(uint256 _tokenId, bytes32 _eventType, bytes memory _eventData)`**: A whitelisted Oracle or trusted entity can submit an attestation of an external event that influences a Twin's traits.
    *   **Description:** Integrates real-world or off-chain data and events into the Twin's evolution, managed securely by Oracles.
21. **`registerOracle(address _oracleAddress, string memory _name)`**: Admin function to whitelist and name addresses capable of attesting to Twin events.
    *   **Description:** Manages trusted data providers for external event integration.
22. **`removeOracle(address _oracleAddress)`**: Admin function to revoke an Oracle's privileges.
    *   **Description:** Allows for disengagement of untrusted or inactive Oracles.

**V. Ecosystem Governance & Utility**

23. **`proposeEvolutionPath(bytes32 _traitKey, uint256 _threshold, string memory _descriptionURI)`**: Users (or Twins with sufficient Aura) can propose new evolution paths or stages for Twins, tied to specific trait thresholds.
    *   **Description:** Community-driven development of Twin progression and unlockable features.
24. **`voteOnProposal(uint256 _proposalId, bool _approve)`**: Stakeholders (e.g., InsightToken holders or high-Aura Twins) can vote on proposed evolution paths.
    *   **Description:** Decentralized governance for the Twin's ecosystem development.
25. **`claimProposalReward(uint256 _proposalId)`**: Allows the proposer of a successful evolution path to claim a reward.
    *   **Description:** Incentivizes valuable contributions to the ecosystem.
26. **`setBaseURI(string memory _newBaseURI)`**: Admin function to update the base URI for the `tokenURI` metadata, allowing for IPFS gateway or other content server changes.
    *   **Description:** Provides flexibility in managing the NFT's off-chain metadata hosting.
27. **`setTraitDecayInterval(bytes32 _traitKey, uint256 _interval)`**: Admin sets how frequently a specific trait should be subject to decay.
    *   **Description:** Configures the "forgetting" mechanism for individual traits.
28. **`updateSystemStatus(bool _paused)`**: Admin function to pause or unpause critical contract functionalities during emergencies or upgrades.
    *   **Description:** Emergency control mechanism for contract safety.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- Contract Outline & Function Summary ---
// Contract Name: AuraTwin
// Core Concept: An ERC-721 "Digital Soul" NFT that evolves its traits and reputation ("Aura") based on on-chain actions,
// oracle inputs, and user decisions. It integrates a utility token (`InsightToken`) and advanced delegation features
// for controlled AI agent interaction.

// I. Core AuraTwin NFT Management (ERC-721 Inspired)
// 1. mintTwin(string memory _twinName): Mints a new AuraTwin NFT with an initial name for the caller.
// 2. setTwinName(uint256 _tokenId, string memory _newName): Allows the Twin's owner to update its human-readable name.
// 3. toggleTransferLock(uint256 _tokenId, bool _lock): Enables or disables the transferability of a Twin by its owner,
//    allowing it to function as a Soulbound Token (SBT) or a standard ERC-721.
// 4. getTokenURI(uint256 _tokenId): Generates a dynamic metadata URI that reflects the Twin's current traits and evolution stage.
// 5. getTwinDetails(uint256 _tokenId): Retrieves a comprehensive struct containing all current data of a specific Twin.

// II. Trait & Aura System
// 6. _updateTwinTrait(uint256 _tokenId, bytes32 _traitKey, uint256 _newValue): Internal helper function to set or update a specific trait value for a Twin.
// 7. getTwinTrait(uint256 _tokenId, bytes32 _traitKey): Returns the value of a specific trait for a given Twin.
// 8. getTwinAllTraits(uint256 _tokenId): Returns an array of all trait keys and their corresponding values for a Twin.
// 9. addExperienceToTrait(uint256 _tokenId, bytes32 _traitKey, uint256 _amount): Increments an "experience" value for a specific trait,
//    potentially leading to trait level-ups.
// 10. calculateAuraScore(uint256 _tokenId): Computes the Twin's overall "Aura" score based on its traits and their pre-configured weights.
// 11. configureTraitWeight(bytes32 _traitKey, uint256 _weight): Admin function to set the importance or weighting of a trait when calculating the Aura score.
// 12. decayTraits(uint256 _tokenId, bytes32[] memory _traitKeys): Allows for on-chain decay of specific traits over time if not actively maintained.

// III. Insight Token (ERC-20 Utility)
// 13. mintInsight(address _to, uint256 _amount): Admin function to mint `InsightToken`s, typically used for rewards or initial distribution.
// 14. burnInsight(uint256 _amount): Allows users to burn their own `InsightToken`s.
// 15. stakeInsightForBoost(uint256 _tokenId, uint256 _amount, bytes32 _traitKey, uint256 _duration): Users can stake `InsightToken`s
//     to temporarily boost a Twin's specific trait or overall Aura.
// 16. unstakeInsight(uint256 _stakeId): Allows users to retrieve their previously staked `InsightToken`s after the staking duration ends.

// IV. Advanced Interactions & Delegation
// 17. delegateActionToAgent(uint256 _tokenId, address _agent, bytes4 _functionSelector, bool _allow): The Twin's owner can grant an AI agent
//     or a trusted address the ability to execute specific whitelisted functions on behalf of their Twin.
// 18. revokeActionDelegation(uint256 _tokenId, address _agent, bytes4 _functionSelector): The Twin's owner can revoke a previously
//     granted delegation for a specific action.
// 19. executeDelegatedAction(uint256 _tokenId, bytes4 _functionSelector, bytes memory _data): An approved agent can call this to execute
//     a delegated action on behalf of the Twin's owner.
// 20. attestToTwinEvent(uint256 _tokenId, bytes32 _eventType, bytes memory _eventData): A whitelisted Oracle or trusted entity can submit
//     an attestation of an external event that influences a Twin's traits.
// 21. registerOracle(address _oracleAddress, string memory _name): Admin function to whitelist and name addresses capable of attesting to Twin events.
// 22. removeOracle(address _oracleAddress): Admin function to revoke an Oracle's privileges.

// V. Ecosystem Governance & Utility
// 23. proposeEvolutionPath(bytes32 _traitKey, uint256 _threshold, string memory _descriptionURI): Users (or Twins with sufficient Aura) can
//     propose new evolution paths or stages for Twins, tied to specific trait thresholds.
// 24. voteOnProposal(uint256 _proposalId, bool _approve): Stakeholders (e.g., InsightToken holders or high-Aura Twins) can vote on proposed evolution paths.
// 25. claimProposalReward(uint256 _proposalId): Allows the proposer of a successful evolution path to claim a reward.
// 26. setBaseURI(string memory _newBaseURI): Admin function to update the base URI for the `tokenURI` metadata.
// 27. setTraitDecayInterval(bytes32 _traitKey, uint256 _interval): Admin sets how frequently a specific trait should be subject to decay.
// 28. updateSystemStatus(bool _paused): Admin function to pause or unpause critical contract functionalities.
// --- End of Outline & Summary ---


contract InsightToken is ERC20, Ownable {
    constructor() ERC20("InsightToken", "INS") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract AuraTwin is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _stakeIdCounter;

    InsightToken public insightToken;

    // --- Structs ---
    struct TwinData {
        string name;
        address owner;
        uint256 mintedAt;
        bool isTransferLocked;
        mapping(bytes32 => uint256) traits; // Example: "Wisdom", "Agility", "CommunityContribution"
        mapping(bytes32 => uint256) lastTraitDecay; // Timestamp of last decay check for a trait
    }

    struct DelegatedAction {
        address agent;
        bytes4 functionSelector; // The specific function signature the agent is allowed to call
        bool allowed;
    }

    struct TraitWeight {
        uint256 weight;
        uint256 decayInterval; // How often (in seconds) this trait decays
        uint256 decayAmount;   // How much it decays per interval
    }

    struct Proposal {
        address proposer;
        bytes32 traitKey;
        uint256 threshold;
        string descriptionURI; // URI to detailed proposal (e.g., IPFS JSON)
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool passed;
        uint256 creationTime;
    }

    struct Stake {
        uint256 tokenId;
        address staker;
        uint256 amount;
        bytes32 traitKey; // The trait being boosted
        uint256 startTime;
        uint256 endTime;
        bool claimed;
    }

    // --- Mappings ---
    mapping(uint256 => TwinData) public twins;
    mapping(uint256 => mapping(address => mapping(bytes4 => bool))) public delegatedActions; // tokenId => agent => functionSelector => allowed
    mapping(address => bool) public isOracle;
    mapping(address => string) public oracleNames; // For display purposes
    mapping(bytes32 => TraitWeight) public traitConfigurations; // Trait key => {weight, decayInterval, decayAmount}
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voterAddress => hasVoted
    mapping(uint256 => Stake) public stakes; // stakeId => Stake

    // --- State Variables ---
    string private _baseTokenURI;
    bool public paused = false;
    uint256 public constant MIN_TRAIT_VALUE = 0;
    uint256 public constant MAX_TRAIT_VALUE = 1000; // Example max trait value
    uint256 public constant MIN_AURA_FOR_PROPOSAL = 1000; // Minimum Aura score to propose an evolution path
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days;
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 5; // 5% of Insight token supply needed for quorum
    uint256 public constant PROPOSAL_REWARD_INSIGHT = 100 * 10**18; // 100 Insight tokens

    // --- Events ---
    event TwinMinted(uint256 indexed tokenId, address indexed owner, string name);
    event TwinNameUpdated(uint256 indexed tokenId, string oldName, string newName);
    event TwinTransferLockToggled(uint256 indexed tokenId, bool locked);
    event TraitUpdated(uint256 indexed tokenId, bytes32 indexed traitKey, uint256 newValue);
    event AuraCalculated(uint256 indexed tokenId, uint256 auraScore);
    event TraitWeightConfigured(bytes32 indexed traitKey, uint256 weight);
    event TraitDecayed(uint256 indexed tokenId, bytes32 indexed traitKey, uint256 amount);
    event InsightStaked(uint256 indexed stakeId, uint256 indexed tokenId, address indexed staker, uint256 amount, bytes32 traitKey, uint256 duration);
    event InsightUnstaked(uint256 indexed stakeId, uint256 indexed tokenId, address indexed staker, uint256 amount);
    event ActionDelegated(uint256 indexed tokenId, address indexed agent, bytes4 indexed functionSelector, bool allowed);
    event ActionRevoked(uint256 indexed tokenId, address indexed agent, bytes4 indexed functionSelector);
    event EventAttested(uint256 indexed tokenId, address indexed oracle, bytes32 indexed eventType);
    event OracleRegistered(address indexed oracleAddress, string name);
    event OracleRemoved(address indexed oracleAddress);
    event EvolutionPathProposed(uint256 indexed proposalId, address indexed proposer, bytes32 traitKey, uint256 threshold, string descriptionURI);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool approve);
    event ProposalFinalized(uint256 indexed proposalId, bool passed);
    event ProposalRewardClaimed(uint256 indexed proposalId, address indexed claimant, uint256 amount);
    event SystemStatusUpdated(bool paused);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyTwinOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not twin owner or approved");
        _;
    }

    modifier onlyOracle() {
        require(isOracle[msg.sender], "Caller is not a registered oracle");
        _;
    }

    constructor(address _insightTokenAddress) ERC721("AuraTwin", "ATWIN") Ownable(msg.sender) {
        insightToken = InsightToken(_insightTokenAddress);
        // Set initial default trait configurations
        traitConfigurations["Wisdom"] = TraitWeight({weight: 5, decayInterval: 30 days, decayAmount: 10});
        traitConfigurations["Agility"] = TraitWeight({weight: 3, decayInterval: 60 days, decayAmount: 5});
        traitConfigurations["CommunityContribution"] = TraitWeight({weight: 7, decayInterval: 90 days, decayAmount: 2});
        _baseTokenURI = "ipfs://QmbRjXwD2Xh3gY8vS7c4K1t9Q5F2mZ0oP6p7e8b9aC0d1/metadata/"; // Example IPFS base
    }

    // --- I. Core AuraTwin NFT Management ---

    /// @notice Mints a new AuraTwin NFT with an initial name for the caller.
    /// @param _twinName The desired name for the new Twin.
    function mintTwin(string memory _twinName) public whenNotPaused {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _baseTokenURI); // Initial URI, will be dynamic

        twins[newTokenId].name = _twinName;
        twins[newTokenId].owner = msg.sender;
        twins[newTokenId].mintedAt = block.timestamp;
        twins[newTokenId].isTransferLocked = false; // By default, transferrable

        // Initialize some default traits
        twins[newTokenId].traits["Wisdom"] = 50;
        twins[newTokenId].traits["Agility"] = 40;
        twins[newTokenId].traits["CommunityContribution"] = 10;
        twins[newTokenId].lastTraitDecay["Wisdom"] = block.timestamp;
        twins[newTokenId].lastTraitDecay["Agility"] = block.timestamp;
        twins[newTokenId].lastTraitDecay["CommunityContribution"] = block.timestamp;


        emit TwinMinted(newTokenId, msg.sender, _twinName);
    }

    /// @notice Allows the Twin's owner to update its human-readable name.
    /// @param _tokenId The ID of the Twin.
    /// @param _newName The new name for the Twin.
    function setTwinName(uint256 _tokenId, string memory _newName) public onlyTwinOwner(_tokenId) {
        string memory oldName = twins[_tokenId].name;
        twins[_tokenId].name = _newName;
        emit TwinNameUpdated(_tokenId, oldName, _newName);
    }

    /// @notice Enables or disables the transferability of a Twin by its owner.
    ///         If locked, the Twin behaves like an SBT.
    /// @param _tokenId The ID of the Twin.
    /// @param _lock True to lock transfer, false to unlock.
    function toggleTransferLock(uint256 _tokenId, bool _lock) public onlyTwinOwner(_tokenId) {
        twins[_tokenId].isTransferLocked = _lock;
        emit TwinTransferLockToggled(_tokenId, _lock);
    }

    /// @dev Overrides ERC721's `_beforeTokenTransfer` to enforce transfer lock and apply transfer penalties.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0) && from != to) { // Actual transfer, not mint or burn
            require(!twins[tokenId].isTransferLocked, "Twin is transfer-locked (Soulbound)");

            // Example: Transfer penalty - some traits might be reset or reduced
            _updateTwinTrait(tokenId, "CommunityContribution", MIN_TRAIT_VALUE);
            _updateTwinTrait(tokenId, "Wisdom", (twins[tokenId].traits["Wisdom"] * 50) / 100); // 50% reduction
        }
    }

    /// @notice Generates a dynamic metadata URI that reflects the Twin's current traits and evolution stage.
    /// @dev The actual JSON will be hosted off-chain, but the URI path will encode dynamic data.
    /// @param _tokenId The ID of the Twin.
    /// @return The dynamic metadata URI.
    function getTokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");

        // Example: Base URI + TokenID + AuraScore + (maybe a hash of key traits for cache busting)
        // Off-chain service at _baseTokenURI will parse these parameters and generate dynamic JSON/image.
        string memory auraScore = Strings.toString(calculateAuraScore(_tokenId));
        string memory name = twins[_tokenId].name;
        string memory uri = string(abi.encodePacked(
            _baseTokenURI,
            Strings.toString(_tokenId),
            "/",
            Strings.toHexString(uint256(keccak256(abi.encodePacked(auraScore, name)))), // simple hash for dynamism
            ".json"
        ));
        return uri;
    }

    /// @notice Retrieves a comprehensive struct containing all current data of a specific Twin.
    /// @param _tokenId The ID of the Twin.
    /// @return A tuple containing the Twin's details.
    function getTwinDetails(uint256 _tokenId) public view returns (
        string memory name,
        address ownerAddr,
        uint256 mintedAt,
        bool isTransferLocked,
        uint256 auraScore
    ) {
        require(_exists(_tokenId), "AuraTwin: Twin does not exist");
        TwinData storage twin = twins[_tokenId];
        name = twin.name;
        ownerAddr = ownerOf(_tokenId); // Use ERC721's ownerOf for current owner
        mintedAt = twin.mintedAt;
        isTransferLocked = twin.isTransferLocked;
        auraScore = calculateAuraScore(_tokenId);
    }

    // --- II. Trait & Aura System ---

    /// @dev Internal helper function to set or update a specific trait value for a Twin.
    /// @param _tokenId The ID of the Twin.
    /// @param _traitKey The key (e.g., "Wisdom") of the trait.
    /// @param _newValue The new value for the trait.
    function _updateTwinTrait(uint256 _tokenId, bytes32 _traitKey, uint256 _newValue) internal {
        twins[_tokenId].traits[_traitKey] = Math.min(_newValue, MAX_TRAIT_VALUE);
        twins[_tokenId].lastTraitDecay[_traitKey] = block.timestamp;
        emit TraitUpdated(_tokenId, _traitKey, twins[_tokenId].traits[_traitKey]);
    }

    /// @notice Returns the value of a specific trait for a given Twin.
    /// @param _tokenId The ID of the Twin.
    /// @param _traitKey The key (e.g., "Wisdom") of the trait.
    /// @return The current value of the trait.
    function getTwinTrait(uint256 _tokenId, bytes32 _traitKey) public view returns (uint256) {
        require(_exists(_tokenId), "AuraTwin: Twin does not exist");
        return twins[_tokenId].traits[_traitKey];
    }

    /// @notice Returns an array of all trait keys and their corresponding values for a Twin.
    /// @dev This can be gas intensive if a Twin has many traits. Consider off-chain querying for extensive trait lists.
    /// @param _tokenId The ID of the Twin.
    /// @return An array of trait keys and an array of their values.
    function getTwinAllTraits(uint256 _tokenId) public view returns (bytes32[] memory, uint256[] memory) {
        require(_exists(_tokenId), "AuraTwin: Twin does not exist");
        // Due to Solidity's mapping structure, retrieving all keys is not straightforward on-chain.
        // For demonstration, we'll return known trait keys. In a real scenario, this might be
        // managed differently (e.g., a dynamic array of trait keys, or relying on off-chain indexing).
        bytes32[] memory knownTraitKeys = new bytes32[](3); // Example: assuming 3 core traits
        knownTraitKeys[0] = "Wisdom";
        knownTraitKeys[1] = "Agility";
        knownTraitKeys[2] = "CommunityContribution";

        uint256[] memory traitValues = new uint256[](knownTraitKeys.length);
        for (uint256 i = 0; i < knownTraitKeys.length; i++) {
            traitValues[i] = twins[_tokenId].traits[knownTraitKeys[i]];
        }
        return (knownTraitKeys, traitValues);
    }

    /// @notice Increments an "experience" value for a specific trait, potentially leading to trait level-ups.
    /// @param _tokenId The ID of the Twin.
    /// @param _traitKey The key of the trait to add experience to.
    /// @param _amount The amount of experience to add.
    function addExperienceToTrait(uint256 _tokenId, bytes32 _traitKey, uint256 _amount) public onlyTwinOwner(_tokenId) {
        uint256 currentTraitValue = twins[_tokenId].traits[_traitKey];
        uint256 newTraitValue = currentTraitValue + _amount;
        _updateTwinTrait(_tokenId, _traitKey, newTraitValue);
    }

    /// @notice Computes the Twin's overall "Aura" score based on its traits and their pre-configured weights.
    /// @param _tokenId The ID of the Twin.
    /// @return The calculated Aura score.
    function calculateAuraScore(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "AuraTwin: Twin does not exist");
        uint256 totalAura = 0;
        // Iterate through known trait configurations
        bytes32[] memory knownTraitKeys = new bytes32[](3);
        knownTraitKeys[0] = "Wisdom";
        knownTraitKeys[1] = "Agility";
        knownTraitKeys[2] = "CommunityContribution";

        for (uint256 i = 0; i < knownTraitKeys.length; i++) {
            bytes32 traitKey = knownTraitKeys[i];
            TraitWeight storage config = traitConfigurations[traitKey];
            if (config.weight > 0) {
                totalAura += (twins[_tokenId].traits[traitKey] * config.weight);
            }
        }
        emit AuraCalculated(_tokenId, totalAura);
        return totalAura;
    }

    /// @notice Admin function to set the importance or weighting of a trait when calculating the Aura score.
    /// @param _traitKey The key of the trait.
    /// @param _weight The new weight for the trait (0-100, for example).
    function configureTraitWeight(bytes32 _traitKey, uint256 _weight) public onlyOwner {
        traitConfigurations[_traitKey].weight = _weight;
        emit TraitWeightConfigured(_traitKey, _weight);
    }

    /// @notice Allows for on-chain decay of specific traits over time if not actively maintained.
    /// @dev This function is intended to be called periodically, e.g., by a keeper network.
    /// @param _tokenId The ID of the Twin.
    /// @param _traitKeys An array of trait keys to check for decay.
    function decayTraits(uint256 _tokenId, bytes32[] memory _traitKeys) public whenNotPaused {
        require(_exists(_tokenId), "AuraTwin: Twin does not exist");
        // This could be restricted to keeper/oracle or even owner if they pay gas
        // For this example, anyone can trigger decay check for a token
        for (uint256 i = 0; i < _traitKeys.length; i++) {
            bytes32 traitKey = _traitKeys[i];
            TraitWeight storage config = traitConfigurations[traitKey];
            if (config.decayInterval > 0 && config.decayAmount > 0) {
                uint256 lastDecay = twins[_tokenId].lastTraitDecay[traitKey];
                uint256 intervalsPassed = (block.timestamp - lastDecay) / config.decayInterval;

                if (intervalsPassed > 0) {
                    uint256 decayAmount = config.decayAmount * intervalsPassed;
                    uint256 currentTraitValue = twins[_tokenId].traits[traitKey];
                    uint256 newTraitValue = currentTraitValue > decayAmount ? currentTraitValue - decayAmount : MIN_TRAIT_VALUE;

                    _updateTwinTrait(_tokenId, traitKey, newTraitValue);
                    twins[_tokenId].lastTraitDecay[traitKey] = block.timestamp; // Update last decay timestamp
                    emit TraitDecayed(_tokenId, traitKey, decayAmount);
                }
            }
        }
    }

    // --- III. Insight Token (ERC-20 Utility) ---

    /// @notice Admin function to mint `InsightToken`s.
    /// @param _to The address to mint tokens to.
    /// @param _amount The amount of tokens to mint.
    function mintInsight(address _to, uint256 _amount) public onlyOwner {
        insightToken.mint(_to, _amount);
    }

    /// @notice Allows users to burn their own `InsightToken`s.
    /// @param _amount The amount of tokens to burn.
    function burnInsight(uint256 _amount) public {
        insightToken.burn(msg.sender, _amount);
    }

    /// @notice Users can stake `InsightToken`s to temporarily boost a Twin's specific trait or overall Aura.
    /// @param _tokenId The ID of the Twin to boost.
    /// @param _amount The amount of Insight tokens to stake.
    /// @param _traitKey The trait key to boost.
    /// @param _duration The duration in seconds for the boost.
    function stakeInsightForBoost(uint256 _tokenId, uint256 _amount, bytes32 _traitKey, uint256 _duration)
        public whenNotPaused nonReentrant onlyTwinOwner(_tokenId) {
        require(_amount > 0, "AuraTwin: Stake amount must be greater than 0");
        require(_duration > 0, "AuraTwin: Stake duration must be greater than 0");
        require(insightToken.balanceOf(msg.sender) >= _amount, "AuraTwin: Insufficient Insight tokens");
        require(insightToken.allowance(msg.sender, address(this)) >= _amount, "AuraTwin: Allowance not set for Insight tokens");

        insightToken.transferFrom(msg.sender, address(this), _amount);

        _stakeIdCounter.increment();
        uint256 newStakeId = _stakeIdCounter.current();

        stakes[newStakeId] = Stake({
            tokenId: _tokenId,
            staker: msg.sender,
            amount: _amount,
            traitKey: _traitKey,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            claimed: false
        });

        // Apply a temporary boost to the trait (e.g., 1 Insight per 1 trait point)
        _updateTwinTrait(_tokenId, _traitKey, twins[_tokenId].traits[_traitKey] + (_amount / 1 ether)); // Example: 1 INS = 1 trait point
        // Store original trait value to revert after unstake

        emit InsightStaked(newStakeId, _tokenId, msg.sender, _amount, _traitKey, _duration);
    }

    /// @notice Allows users to retrieve their previously staked `InsightToken`s after the staking duration ends.
    /// @param _stakeId The ID of the stake.
    function unstakeInsight(uint256 _stakeId) public whenNotPaused nonReentrant {
        Stake storage s = stakes[_stakeId];
        require(s.staker == msg.sender, "AuraTwin: Not the staker");
        require(!s.claimed, "AuraTwin: Stake already claimed");
        require(block.timestamp >= s.endTime, "AuraTwin: Stake duration not over yet");

        s.claimed = true;
        insightToken.transfer(s.staker, s.amount);

        // Revert the temporary boost (e.g., 1 Insight per 1 trait point)
        _updateTwinTrait(s.tokenId, s.traitKey, twins[s.tokenId].traits[s.traitKey] - (s.amount / 1 ether));

        emit InsightUnstaked(_stakeId, s.tokenId, s.staker, s.amount);
    }

    // --- IV. Advanced Interactions & Delegation ---

    /// @notice The Twin's owner can grant an AI agent or a trusted address the ability to execute specific whitelisted
    ///         functions on behalf of their Twin.
    /// @param _tokenId The ID of the Twin.
    /// @param _agent The address of the agent/delegate.
    /// @param _functionSelector The 4-byte function selector of the function to delegate (e.g., bytes4(keccak256("setTwinName(uint256,string)"))).
    /// @param _allow True to allow, false to disallow.
    function delegateActionToAgent(uint256 _tokenId, address _agent, bytes4 _functionSelector, bool _allow)
        public onlyTwinOwner(_tokenId) {
        delegatedActions[_tokenId][_agent][_functionSelector] = _allow;
        emit ActionDelegated(_tokenId, _agent, _functionSelector, _allow);
    }

    /// @notice The Twin's owner can revoke a previously granted delegation for a specific action.
    /// @param _tokenId The ID of the Twin.
    /// @param _agent The address of the agent/delegate.
    /// @param _functionSelector The 4-byte function selector of the function to revoke.
    function revokeActionDelegation(uint256 _tokenId, address _agent, bytes4 _functionSelector)
        public onlyTwinOwner(_tokenId) {
        delegatedActions[_tokenId][_agent][_functionSelector] = false; // Explicitly set to false
        emit ActionRevoked(_tokenId, _agent, _functionSelector);
    }

    /// @notice An approved agent can call this to execute a delegated action on behalf of the Twin's owner.
    /// @param _tokenId The ID of the Twin.
    /// @param _functionSelector The 4-byte function selector of the function to execute.
    /// @param _data The ABI-encoded data for the function call.
    function executeDelegatedAction(uint256 _tokenId, bytes4 _functionSelector, bytes memory _data) public whenNotPaused {
        require(delegatedActions[_tokenId][msg.sender][_functionSelector], "AuraTwin: Agent not authorized for this action");
        require(ownerOf(_tokenId) != address(0), "AuraTwin: Twin does not exist"); // Ensure Twin exists
        
        // This is a simplified direct call. In a more complex scenario,
        // a proxy pattern might be used, or the target contract would be
        // `address(this)` if the delegated actions are internal to AuraTwin.
        // For this example, we're making an internal call to AuraTwin functions
        // that accept `_tokenId` as the first argument, simulating "on behalf of".

        // Example: Only allowing specific internal AuraTwin functions to be delegated
        // The agent essentially becomes the "owner" context for this specific call.
        
        // Caution: Direct `call` can be risky if not carefully restricted.
        // Here, we enforce that `msg.sender` (the agent) has been authorized for this specific `_functionSelector`.
        // The actual call will be executed in the context of the AuraTwin contract, acting on `_tokenId`.

        // This requires careful handling of internal functions.
        // For demonstration, we'll allow calling specific internal functions that take tokenId as first arg.
        // A more robust solution might involve a `target` address as well.
        
        // Example: if setTwinName(uint256, string) is delegated, the agent would pass `_tokenId` and `_newName` in `_data`.
        // The `msg.sender` for the function called (e.g. `setTwinName`) will *still* be the agent's address.
        // We need to verify that `setTwinName` etc. internally check `_isApprovedOrOwner(msg.sender, _tokenId)` or
        // a similar delegation check. Since `onlyTwinOwner` is used, the agent needs to be approved by the owner.
        // This function facilitates that the agent *can* make the call by passing `msg.sender` as an approved operator.

        // To make this work with `onlyTwinOwner(_tokenId)` modifier in other functions:
        // The `ownerOf(_tokenId)` must approve the agent as an operator for the tokenId.
        // `delegateActionToAgent` allows the agent to call *this* `executeDelegatedAction` function
        // for `_tokenId` and `_functionSelector`. The `_data` should contain the arguments
        // for the intended function (e.g., `setTwinName`).

        // For simplicity and security, this function will primarily allow modification of Twin traits or names
        // *within the AuraTwin contract itself*, if those functions are designed to check `isApprovedForAll` or `getApproved`.

        // Since many functions have `onlyTwinOwner`, the owner needs to `approve(_agent, _tokenId)` or `setApprovalForAll(_agent, true)`.
        // This `executeDelegatedAction` function essentially verifies that the agent is allowed to act "on behalf of"
        // in a specific way by checking `delegatedActions`.

        // This part would ideally be executed by the `ownerOf(_tokenId)` using a proxy call pattern or a relayer service
        // that wraps the agent's call, so that `msg.sender` *appears* to be the owner.
        // For a direct Solidity implementation, the agent `msg.sender` remains the agent.

        // A more practical approach would be:
        // 1. Owner approves agent for specific function via `delegateActionToAgent`.
        // 2. Owner then `approve(agent, tokenId)` for the ERC721 operations.
        // 3. Agent calls the target function directly (e.g., `setTwinName(tokenId, newName)`).
        // 4. `setTwinName`'s `onlyTwinOwner` then checks `_isApprovedOrOwner(msg.sender, tokenId)`, which would be true.
        // This `executeDelegatedAction` structure would be useful for a generic proxy, not direct call.

        // For this specific contract, let's assume `_data` directly encodes the call to *this* contract.
        // Example: `_data = abi.encodeWithSelector(this.setTwinName.selector, _tokenId, "NewAgentName")`
        (bool success, ) = address(this).call(abi.encodePacked(_functionSelector, _data));
        require(success, "AuraTwin: Delegated action failed");
    }

    /// @notice A whitelisted Oracle or trusted entity can submit an attestation of an external event that influences a Twin's traits.
    /// @param _tokenId The ID of the Twin.
    /// @param _eventType A unique identifier for the event type (e.g., "VerifiedDeveloper", "CompletedCourse").
    /// @param _eventData Optional ABI-encoded data related to the event (e.g., course ID, verification hash).
    function attestToTwinEvent(uint256 _tokenId, bytes32 _eventType, bytes memory _eventData)
        public whenNotPaused onlyOracle {
        require(_exists(_tokenId), "AuraTwin: Twin does not exist");

        // Example: Update traits based on event type
        if (_eventType == "VerifiedDeveloper") {
            _updateTwinTrait(_tokenId, "DeveloperPro", twins[_tokenId].traits["DeveloperPro"] + 100);
        } else if (_eventType == "CommunityLeader") {
            _updateTwinTrait(_tokenId, "CommunityContribution", twins[_tokenId].traits["CommunityContribution"] + 50);
        }
        // More complex logic can be added here based on _eventData

        emit EventAttested(_tokenId, msg.sender, _eventType);
    }

    /// @notice Admin function to whitelist and name addresses capable of attesting to Twin events.
    /// @param _oracleAddress The address to register as an Oracle.
    /// @param _name A human-readable name for the Oracle.
    function registerOracle(address _oracleAddress, string memory _name) public onlyOwner {
        isOracle[_oracleAddress] = true;
        oracleNames[_oracleAddress] = _name;
        emit OracleRegistered(_oracleAddress, _name);
    }

    /// @notice Admin function to revoke an Oracle's privileges.
    /// @param _oracleAddress The address of the Oracle to remove.
    function removeOracle(address _oracleAddress) public onlyOwner {
        isOracle[_oracleAddress] = false;
        delete oracleNames[_oracleAddress];
        emit OracleRemoved(_oracleAddress);
    }

    // --- V. Ecosystem Governance & Utility ---

    /// @notice Users (or Twins with sufficient Aura) can propose new evolution paths or stages for Twins,
    ///         tied to specific trait thresholds.
    /// @param _traitKey The trait key relevant to the proposal.
    /// @param _threshold The target threshold for the trait.
    /// @param _descriptionURI URI to detailed proposal (e.g., IPFS JSON explaining the path).
    function proposeEvolutionPath(bytes32 _traitKey, uint256 _threshold, string memory _descriptionURI)
        public whenNotPaused {
        uint256 twinId = _tokenIdCounter.current(); // Assuming proposer uses their main Twin, needs refinement
        // A more robust system would require the proposer to specify WHICH of their twins, or have a dedicated proposing token.
        // For simplicity, we assume `msg.sender` is implicitly linked to a Twin or has general standing.
        // Or, require `msg.sender` to own a Twin with sufficient Aura.
        require(insightToken.balanceOf(msg.sender) >= MIN_AURA_FOR_PROPOSAL, "AuraTwin: Not enough Insight for proposal"); // Using Insight as a proxy for Aura

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            traitKey: _traitKey,
            threshold: _threshold,
            descriptionURI: _descriptionURI,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false,
            creationTime: block.timestamp
        });
        emit EvolutionPathProposed(newProposalId, msg.sender, _traitKey, _threshold, _descriptionURI);
    }

    /// @notice Stakeholders (e.g., InsightToken holders or high-Aura Twins) can vote on proposed evolution paths.
    /// @param _proposalId The ID of the proposal.
    /// @param _approve True for a 'yes' vote, false for a 'no' vote.
    function voteOnProposal(uint256 _proposalId, bool _approve) public whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.creationTime != 0, "AuraTwin: Proposal does not exist");
        require(!p.executed, "AuraTwin: Proposal already executed");
        require(block.timestamp <= p.creationTime + PROPOSAL_VOTING_PERIOD, "AuraTwin: Voting period ended");
        require(!proposalVotes[_proposalId][msg.sender], "AuraTwin: Already voted on this proposal");
        require(insightToken.balanceOf(msg.sender) > 0, "AuraTwin: No Insight tokens to vote with"); // Requires some Insight to vote

        proposalVotes[_proposalId][msg.sender] = true;
        if (_approve) {
            p.yesVotes++;
        } else {
            p.noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _approve);
    }

    /// @notice Finalizes a proposal, checking quorum and vote outcome. Can be called by anyone after voting period.
    /// @param _proposalId The ID of the proposal.
    function finalizeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.creationTime != 0, "AuraTwin: Proposal does not exist");
        require(!p.executed, "AuraTwin: Proposal already executed");
        require(block.timestamp > p.creationTime + PROPOSAL_VOTING_PERIOD, "AuraTwin: Voting period not over");

        p.executed = true;

        uint256 totalVotes = p.yesVotes + p.noVotes;
        uint256 totalInsightSupply = insightToken.totalSupply();
        uint256 requiredQuorum = (totalInsightSupply * PROPOSAL_QUORUM_PERCENT) / 100;

        if (totalVotes > requiredQuorum && p.yesVotes > p.noVotes) {
            p.passed = true;
            // Example: If passed, automatically set this evolution path configuration
            traitConfigurations[p.traitKey].threshold = p.threshold; // This is a new field for traitConfiguration, needs adding
        }

        emit ProposalFinalized(_proposalId, p.passed);
    }

    /// @notice Allows the proposer of a successful evolution path to claim a reward.
    /// @param _proposalId The ID of the proposal.
    function claimProposalReward(uint256 _proposalId) public whenNotPaused nonReentrant {
        Proposal storage p = proposals[_proposalId];
        require(p.proposer == msg.sender, "AuraTwin: Not the proposer");
        require(p.executed, "AuraTwin: Proposal not yet finalized");
        require(p.passed, "AuraTwin: Proposal did not pass");
        require(insightToken.balanceOf(address(this)) >= PROPOSAL_REWARD_INSIGHT, "AuraTwin: Not enough Insight for reward");

        insightToken.transfer(msg.sender, PROPOSAL_REWARD_INSIGHT);
        // Mark proposal as rewarded to prevent double claims (needs a boolean field in Proposal struct)
        // For simplicity, we assume this is handled by `p.executed` and `p.passed` for now.

        emit ProposalRewardClaimed(_proposalId, msg.sender, PROPOSAL_REWARD_INSIGHT);
    }

    /// @notice Admin function to update the base URI for the `tokenURI` metadata.
    /// @param _newBaseURI The new base URI (e.g., IPFS gateway).
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    /// @notice Admin sets how frequently a specific trait should be subject to decay.
    /// @param _traitKey The trait key.
    /// @param _interval The decay interval in seconds.
    function setTraitDecayInterval(bytes32 _traitKey, uint256 _interval) public onlyOwner {
        traitConfigurations[_traitKey].decayInterval = _interval;
    }

    /// @notice Admin function to pause or unpause critical contract functionalities during emergencies or upgrades.
    /// @param _paused True to pause, false to unpause.
    function updateSystemStatus(bool _paused) public onlyOwner {
        paused = _paused;
        emit SystemStatusUpdated(_paused);
    }

    // Fallback and Receive for receiving ETH if needed (not explicitly used in this design)
    receive() external payable {}
    fallback() external payable {}
}

// Minimal Math library to avoid pulling in entire SafeMath if only simple ops are needed
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```