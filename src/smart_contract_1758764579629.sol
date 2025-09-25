This smart contract, named `MetaVerseForge`, introduces a novel paradigm for "living" digital assets called **Glimmers**. Unlike static NFTs, Glimmers are highly dynamic entities whose properties evolve over time, react to resource injections, and can be enhanced through community-governed modules. The protocol also features an adaptive governance system powered by a `Spark` token, allowing stakers to shape the evolution of both the protocol and the Glimmers themselves.

The core idea is to move beyond simple digital collectibles to create a dynamic, interconnected digital ecosystem where assets have complex internal states and interactions.

---

## **Contract: `MetaVerseForge`**

A highly dynamic and generative digital asset protocol, enabling the creation and evolution of "Glimmers" – living digital entities whose properties and value are shaped by community interaction, resource injection, and adaptive on-chain rules.

### **Outline:**

1.  **Core Infrastructure:** ERC721-like structure for Glimmers, ERC20-like for Spark (governance token), ownership, fees.
2.  **Glimmer Genesis & Management:** Minting, transferring, burning, and querying Glimmer state.
3.  **Dynamic Property Engine:** Mechanisms for Glimmer properties to evolve, decay, and be influenced.
4.  **Resource & Interaction System:** Virtual resources that Glimmers consume/produce, and ways Glimmers interact.
5.  **Co-creation & Enhancement Modules:** Allowing the community to propose and attach functionalities to Glimmers.
6.  **Adaptive Governance & Reputation:** On-chain decision-making, staking, and reputation tracking for protocol evolution.
7.  **External Catalysts & Global Events (Simulated):** Hooks for external influence and large-scale state changes.

---

### **Function Summary (30 Functions):**

1.  **`constructor(string memory _glimmerName, string memory _glimmerSymbol, string memory _sparkName, string memory _sparkSymbol)`**:
    *   **Concept**: Protocol Initialization.
    *   **Description**: Deploys the protocol and its associated `Spark` governance token, setting initial owner and names.
    *   **Advanced Concept**: Initializes a multi-component system with an internally deployed governance token.

2.  **`mintGlimmer(address _to, uint256[] memory _initialPropertyValues)`**:
    *   **Concept**: Glimmer Genesis.
    *   **Description**: Mints a new Glimmer NFT to an address, assigning an initial set of dynamic property values.
    *   **Advanced Concept**: Assets minted with a pre-defined dynamic state array, not fixed attributes.

3.  **`transferGlimmer(address _from, address _to, uint256 _glimmerId)`**:
    *   **Concept**: Ownership Transfer.
    *   **Description**: Standard NFT transfer function (simplified ERC721 `_transfer` logic).

4.  **`burnGlimmer(uint256 _glimmerId)`**:
    *   **Concept**: Asset Destruction.
    *   **Description**: Permanently removes a Glimmer from existence.

5.  **`getGlimmerProperties(uint256 _glimmerId) view returns (uint256[] memory)`**:
    *   **Concept**: State Query.
    *   **Description**: Retrieves the current dynamic property values of a specific Glimmer.

6.  **`getTokenURI(uint256 _glimmerId) view returns (string memory)`**:
    *   **Concept**: Dynamic Metadata.
    *   **Description**: Generates a dynamic metadata URI that reflects the Glimmer's *current* evolving properties.
    *   **Advanced Concept**: On-chain, state-dependent metadata generation, not static IPFS link.

7.  **`registerPropertyDefinition(string memory _name, PropertyType _type, uint256 _minValue, uint256 _maxValue, uint256 _decayRate)`**:
    *   **Concept**: Extensible Asset Schema.
    *   **Description**: Defines a new global property type (e.g., "Energy", "Rarity") with its characteristics (min/max, decay rate).
    *   **Advanced Concept**: Protocol allows for the dynamic addition of new attribute types for its NFTs.

8.  **`updateGlimmerProperty(uint256 _glimmerId, uint256 _propertyIndex, uint256 _newValue)`**:
    *   **Concept**: Direct Property Manipulation (privileged).
    *   **Description**: Allows the owner or an approved module to directly set a Glimmer's property value.
    *   **Advanced Concept**: Fine-grained control over specific asset attributes.

9.  **`evolveGlimmer(uint256 _glimmerId)`**:
    *   **Concept**: Internal State Evolution.
    *   **Description**: Triggers the Glimmer's internal evolution logic, updating its properties based on time elapsed, decay rates, and attached enhancement modules.
    *   **Advanced Concept**: Built-in, deterministic state machine for asset evolution.

10. **`registerResourceDefinition(string memory _name, string memory _symbol, uint256 _maxSupply)`**:
    *   **Concept**: Internal Resource Economy.
    *   **Description**: Defines a new type of virtual resource that Glimmers can consume or produce.
    *   **Advanced Concept**: Introduces an internal resource system within the contract, not external ERC20s.

11. **`injectResource(uint256 _glimmerId, uint256 _resourceTypeId, uint256 _amount)`**:
    *   **Concept**: Resource-Driven Property Modification.
    *   **Description**: Adds a specified amount of virtual resource into a Glimmer, directly influencing its properties or growth.
    *   **Advanced Concept**: User interaction (resource injection) directly affects the state of a dynamic NFT.

12. **`extractResource(uint256 _glimmerId, uint256 _resourceTypeId, uint256 _amount)`**:
    *   **Concept**: Resource Extraction.
    *   **Description**: Allows harvesting virtual resources from a Glimmer, potentially depleting its properties or energy.

13. **`fuseGlimmers(uint256 _glimmerIdA, uint256 _glimmerIdB)`**:
    *   **Concept**: Algorithmic NFT Composition.
    *   **Description**: Combines two existing Glimmers into a new one, blending their properties according to defined fusion rules. Original Glimmers might be consumed.
    *   **Advanced Concept**: Complex, rule-based merging of dynamic NFTs, creating new assets with inherited traits.

14. **`shatterGlimmer(uint256 _glimmerId)`**:
    *   **Concept**: Algorithmic NFT Decomposition.
    *   **Description**: Breaks a Glimmer into its constituent virtual resources or sub-fragments, effectively burning the original Glimmer.
    *   **Advanced Concept**: Reversible asset creation/destruction, yielding resources based on the Glimmer's properties.

15. **`proposeEnhancementModule(address _moduleContract, string memory _description)`**:
    *   **Concept**: Pluggable NFT Functionality.
    *   **Description**: Allows Spark stakers to propose a new external contract (implementing `IEnhancementModule`) to be an approved module for Glimmers.
    *   **Advanced Concept**: Decentralized, community-driven extensibility of NFT behaviors via external contracts.

16. **`voteOnModuleProposal(uint256 _proposalId, bool _approve)`**:
    *   **Concept**: Decentralized Module Approval.
    *   **Description**: Staked Spark token holders vote on whether to approve a proposed Enhancement Module.

17. **`attachEnhancementModule(uint256 _glimmerId, uint256 _moduleId)`**:
    *   **Concept**: Dynamic NFT Feature Attachment.
    *   **Description**: Attaches an approved Enhancement Module to a specific Glimmer, modifying its behavior or properties.
    *   **Advanced Concept**: NFTs can have dynamic, plug-and-play functionalities added or removed.

18. **`detachEnhancementModule(uint256 _glimmerId, uint256 _moduleId)`**:
    *   **Concept**: Dynamic NFT Feature Removal.
    *   **Description**: Detaches an Enhancement Module from a Glimmer.

19. **`stakeSpark(uint256 _amount)`**:
    *   **Concept**: Governance Participation.
    *   **Description**: Stakes `Spark` tokens to gain voting power and earn reputation within the protocol.

20. **`unstakeSpark(uint256 _amount)`**:
    *   **Concept**: Governance Withdrawal.
    *   **Description**: Unstakes `Spark` tokens, potentially after a lock-up period.

21. **`delegateVotingPower(address _delegatee)`**:
    *   **Concept**: Delegated Governance.
    *   **Description**: Allows a staker to delegate their voting power to another address.

22. **`proposeProtocolParameterChange(string memory _description, bytes memory _calldata, address _target)`**:
    *   **Concept**: Self-Amending Protocol.
    *   **Description**: Allows Spark stakers to propose changes to the core contract's parameters or logic.
    *   **Advanced Concept**: Meta-governance; the contract can evolve its own rules through community vote.

23. **`voteOnProtocolChange(uint256 _proposalId, bool _approve)`**:
    *   **Concept**: Protocol Evolution Voting.
    *   **Description**: Staked Spark token holders vote on proposed protocol changes.

24. **`executeProtocolChange(uint256 _proposalId)`**:
    *   **Concept**: Protocol Execution.
    *   **Description**: Executes an approved protocol change proposal, updating contract state or logic.

25. **`updateReputation(address _user, int256 _delta)`**:
    *   **Concept**: On-chain Reputation System.
    *   **Description**: An internal or admin-controlled function to adjust a user's on-chain reputation score based on positive or negative contributions.
    *   **Advanced Concept**: Tracks a dynamic, quantifiable reputation for users within the ecosystem.

26. **`triggerGlobalCatalyst(CatalystType _type, bytes memory _data)`**:
    *   **Concept**: Global External Influence Simulation.
    *   **Description**: Simulates a network-wide event (e.g., "Cosmic Shift", "Economic Boom") that deterministically affects *all* Glimmers based on the catalyst type and data.
    *   **Advanced Concept**: A mechanism for "meta-events" that influence the entire asset ecosystem.

27. **`settleInterGlimmerAffinity(uint256 _glimmerIdA, uint256 _glimmerIdB, int256 _affinityChange)`**:
    *   **Concept**: Simulated Relational Dynamics.
    *   **Description**: Records or updates a simulated "affinity" or relationship score between two Glimmers, potentially affecting future interactions or fusion outcomes.
    *   **Advanced Concept**: Introduces complex, simulated social/ecological interactions between NFTs.

28. **`withdrawFees()`**:
    *   **Concept**: Fee Management.
    *   **Description**: Allows the contract owner to withdraw accumulated protocol fees.

29. **`setBaseURI(string memory _newBaseURI)`**:
    *   **Concept**: Metadata Management.
    *   **Description**: Sets a base URI for Glimmer metadata, used in `getTokenURI`.

30. **`getGlimmerOwner(uint256 _glimmerId) view returns (address)`**:
    *   **Concept**: Basic Ownership Query.
    *   **Description**: Returns the owner of a specific Glimmer.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces ---

/**
 * @title ISparkToken
 * @dev Minimal interface for the Spark governance token.
 * This is a placeholder; in a real scenario, this would be a full ERC20.
 */
interface ISparkToken is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
}

/**
 * @title IEnhancementModule
 * @dev Interface for external contracts that can modify Glimmer properties or trigger actions.
 */
interface IEnhancementModule {
    function applyEffect(uint256 _glimmerId, address _caller, bytes memory _effectData) external returns (bool);
}

/**
 * @title IMetaVerseForge
 * @dev Interface for MetaVerseForge to allow modules to call back.
 */
interface IMetaVerseForge {
    function updateGlimmerProperty(uint256 _glimmerId, uint256 _propertyIndex, uint256 _newValue) external;
    function injectResource(uint256 _glimmerId, uint256 _resourceTypeId, uint256 _amount) external;
    function extractResource(uint256 _glimmerId, uint256 _resourceTypeId, uint256 _amount) external;
    function getGlimmerProperties(uint256 _glimmerId) external view returns (uint256[] memory);
    function getPropertyDefinition(uint256 _propertyIndex) external view returns (string memory name, MetaVerseForge.PropertyType pType, uint256 minValue, uint256 maxValue, uint256 decayRate);
}


// --- Main Contract ---

/**
 * @title MetaVerseForge
 * @dev A highly dynamic and generative digital asset protocol for "Glimmers".
 * Glimmers are living digital entities whose properties evolve over time,
 * react to resource injections, and can be enhanced through community-governed modules.
 * Features an adaptive governance system powered by a 'Spark' token.
 */
contract MetaVerseForge is Context, Ownable {
    using Strings for uint256;

    // --- Enums ---
    enum PropertyType { Numeric, Boolean, Categorical }
    enum CatalystType { GlobalShift, ResourceBoom, DecayAcceleration, RandomEvent }
    enum InteractionType { AffinityBoost, AffinityDrain, PropertyExchange }

    // --- Structs ---

    struct PropertyDefinition {
        string name;
        PropertyType pType;
        uint256 minValue;
        uint256 maxValue;
        uint256 decayRate; // per unit of time (e.g., block, second)
    }

    struct ResourceDefinition {
        string name;
        string symbol;
        uint256 maxSupply; // Max amount of this resource that can exist globally
        uint256 currentSupply;
    }

    struct Glimmer {
        address owner;
        uint256[] propertyValues; // Dynamic array of property values, indexed by propertyId
        uint256 lastEvolvedTimestamp;
        uint256[] attachedModules; // List of module IDs attached to this Glimmer
        mapping(uint256 => uint256) resourceBalances; // Balances of internal resources held by this Glimmer
        mapping(uint256 => int256) glimmerAffinities; // Affinity scores with other Glimmers
    }

    struct ModuleProposal {
        address moduleContract;
        string description;
        bool approved;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // For simple voting, prevent double vote
    }

    struct ProtocolChangeProposal {
        string description;
        bytes calldataPayload; // calldata for the function to be called
        address targetContract; // The contract to call (e.g., this contract)
        bool executed;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
    }

    // --- State Variables ---

    // Glimmer (NFT-like) data
    uint256 private _glimmerCounter;
    string private _glimmerName;
    string private _glimmerSymbol;
    string private _baseTokenURI;
    mapping(uint256 => Glimmer) public glimmers;
    mapping(address => uint256) private _glimmerBalances;

    // Spark (Governance Token)
    ISparkToken public sparkToken;
    uint256 public constant SPARK_MINT_AMOUNT_INITIAL = 1_000_000 * 10**18; // 1M Spark tokens
    uint256 public constant SPARK_FOR_VOTING_LOCKUP_PERIOD = 7 days; // Example lockup

    // Governance
    uint256 public minSparkStakeForProposal; // Min Spark required to propose
    mapping(address => uint256) public stakedSpark;
    mapping(address => address) public votingDelegates; // Delegatee => Delegatee
    mapping(address => uint256) public unstakeLockupEnd; // User => Timestamp of unstake unlock

    // Reputation
    mapping(address => int256) public reputationScores; // Reputation for users

    // Dynamic Properties
    PropertyDefinition[] public propertyDefinitions;
    mapping(string => uint256) public propertyNameToId; // Map name to index in propertyDefinitions

    // Virtual Resources
    ResourceDefinition[] public resourceDefinitions;
    mapping(string => uint256) public resourceNameToId; // Map name to index in resourceDefinitions

    // Enhancement Modules
    ModuleProposal[] public moduleProposals;
    mapping(address => uint256) public moduleContractToId; // Map module contract address to ID (index + 1)
    uint256[] public approvedModules; // List of IDs of approved modules

    // Protocol Changes
    ProtocolChangeProposal[] public protocolChangeProposals;

    // Fees
    uint256 public mintFee = 0.01 ether; // Example mint fee
    uint256 public protocolFeesCollected;

    // --- Events ---
    event GlimmerMinted(uint256 glimmerId, address owner, uint256[] initialProperties);
    event GlimmerTransferred(uint256 glimmerId, address from, address to);
    event GlimmerBurned(uint252 glimmerId);
    event GlimmerEvolved(uint256 glimmerId, uint256[] newProperties, uint256 timestamp);
    event PropertyDefinitionRegistered(uint256 propertyId, string name, PropertyType pType);
    event GlimmerPropertyUpdated(uint256 glimmerId, uint256 propertyIndex, uint256 oldValue, uint256 newValue);
    event ResourceDefinitionRegistered(uint256 resourceId, string name, string symbol);
    event ResourceInjected(uint256 glimmerId, uint256 resourceTypeId, uint256 amount);
    event ResourceExtracted(uint256 glimmerId, uint256 resourceTypeId, uint256 amount);
    event GlimmerFused(uint256 parentA, uint256 parentB, uint256 newGlimmerId);
    event GlimmerShattered(uint256 glimmerId, uint256[] releasedResources);
    event ModuleProposalSubmitted(uint256 proposalId, address moduleContract, string description, address proposer);
    event ModuleProposalVoted(uint256 proposalId, address voter, bool approved);
    event ModuleApproved(uint256 moduleId, address moduleContract);
    event ModuleAttached(uint256 glimmerId, uint256 moduleId);
    event ModuleDetached(uint256 glimmerId, uint256 moduleId);
    event SparkStaked(address staker, uint256 amount);
    event SparkUnstaked(address staker, uint256 amount);
    event VotingPowerDelegated(address delegator, address delegatee);
    event ProtocolChangeProposed(uint256 proposalId, string description, address proposer);
    event ProtocolChangeVoted(uint256 proposalId, address voter, bool approved);
    event ProtocolChangeExecuted(uint256 proposalId);
    event ReputationUpdated(address user, int256 delta, int256 newScore);
    event GlobalCatalystTriggered(CatalystType cType, bytes data);
    event InterGlimmerAffinitySettled(uint256 glimmerIdA, uint256 glimmerIdB, int256 affinityChange);
    event FeesWithdrawn(address recipient, uint256 amount);
    event BaseURISet(string newURI);

    // --- Modifiers ---

    modifier onlySparkStaker() {
        require(stakedSpark[_msgSender()] > 0, "MetaVerseForge: Must be a Spark staker");
        _;
    }

    modifier onlyGlimmerOwner(uint256 _glimmerId) {
        require(glimmers[_glimmerId].owner == _msgSender(), "MetaVerseForge: Not Glimmer owner");
        _;
    }

    modifier onlyApprovedModule(address _moduleContract) {
        bool isApproved = false;
        for(uint256 i = 0; i < approvedModules.length; i++) {
            if (moduleProposals[approvedModules[i] - 1].moduleContract == _moduleContract) { // -1 because module ID is index + 1
                isApproved = true;
                break;
            }
        }
        require(isApproved, "MetaVerseForge: Caller is not an approved module");
        _;
    }

    // --- Constructor ---

    /**
     * @dev Constructor initializes the protocol, deploys the Spark governance token,
     * and sets the initial owner and names.
     * @param _glimmerName The name for the Glimmer tokens.
     * @param _glimmerSymbol The symbol for the Glimmer tokens.
     * @param _sparkName The name for the Spark governance token.
     * @param _sparkSymbol The symbol for the Spark governance token.
     */
    constructor(
        string memory _glimmerName,
        string memory _glimmerSymbol,
        string memory _sparkName,
        string memory _sparkSymbol
    ) Ownable(_msgSender()) {
        _glimmerName = _glimmerName;
        _glimmerSymbol = _glimmerSymbol;
        _glimmerCounter = 0;
        _baseTokenURI = "ipfs://QmbwFzC2g2F4Z4x6v5y5s4d4e4t4h6u7j8k9l/"; // Example base URI

        // Deploy Spark token
        sparkToken = new SparkToken(_sparkName, _sparkSymbol, address(this), SPARK_MINT_AMOUNT_INITIAL);
        minSparkStakeForProposal = 100 * 10**18; // 100 Spark tokens
    }

    // --- Glimmer Genesis & Management (1-6) ---

    /**
     * @dev Mints a new Glimmer NFT to an address with initial dynamic property values.
     * @param _to The address to mint the Glimmer to.
     * @param _initialPropertyValues An array of initial values for the Glimmer's properties.
     * @return The ID of the newly minted Glimmer.
     */
    function mintGlimmer(address _to, uint256[] memory _initialPropertyValues) public payable returns (uint256) {
        require(msg.value >= mintFee, "MetaVerseForge: Insufficient mint fee");
        protocolFeesCollected += msg.value;

        _glimmerCounter++;
        uint256 newGlimmerId = _glimmerCounter;

        require(_initialPropertyValues.length == propertyDefinitions.length, "MetaVerseForge: Initial properties mismatch definition count");

        Glimmer storage newGlimmer = glimmers[newGlimmerId];
        newGlimmer.owner = _to;
        newGlimmer.propertyValues = _initialPropertyValues;
        newGlimmer.lastEvolvedTimestamp = block.timestamp;

        _glimmerBalances[_to]++;

        emit GlimmerMinted(newGlimmerId, _to, _initialPropertyValues);
        return newGlimmerId;
    }

    /**
     * @dev Transfers Glimmer ownership.
     * @param _from The current owner of the Glimmer.
     * @param _to The new owner of the Glimmer.
     * @param _glimmerId The ID of the Glimmer to transfer.
     */
    function transferGlimmer(address _from, address _to, uint256 _glimmerId) public {
        require(glimmers[_glimmerId].owner == _from, "MetaVerseForge: Caller is not the owner or approved");
        require(_to != address(0), "MetaVerseForge: Transfer to the zero address");
        require(_from != address(0), "MetaVerseForge: Transfer from the zero address");

        // Simplified NFT transfer logic (no approvals for brevity, focus on custom logic)
        _glimmerBalances[_from]--;
        glimmers[_glimmerId].owner = _to;
        _glimmerBalances[_to]++;

        emit GlimmerTransferred(_glimmerId, _from, _to);
    }

    /**
     * @dev Burns (destroys) a Glimmer.
     * @param _glimmerId The ID of the Glimmer to burn.
     */
    function burnGlimmer(uint256 _glimmerId) public onlyGlimmerOwner(_glimmerId) {
        address owner = glimmers[_glimmerId].owner;
        delete glimmers[_glimmerId]; // Remove from storage
        _glimmerBalances[owner]--;

        emit GlimmerBurned(_glimmerId);
    }

    /**
     * @dev Retrieves the current dynamic property values of a specific Glimmer.
     * @param _glimmerId The ID of the Glimmer.
     * @return An array of the Glimmer's current property values.
     */
    function getGlimmerProperties(uint256 _glimmerId) public view returns (uint256[] memory) {
        return glimmers[_glimmerId].propertyValues;
    }

    /**
     * @dev Generates a dynamic metadata URI based on the Glimmer's current properties.
     * This would typically point to a service that renders JSON based on on-chain data.
     * @param _glimmerId The ID of the Glimmer.
     * @return A string representing the dynamic token URI.
     */
    function getTokenURI(uint256 _glimmerId) public view returns (string memory) {
        require(_glimmerId <= _glimmerCounter && glimmers[_glimmerId].owner != address(0), "MetaVerseForge: Glimmer does not exist");
        // In a real scenario, this would generate a base64 encoded JSON or point to an API endpoint
        // that fetches the on-chain properties and renders dynamic JSON metadata.
        // For this example, we'll just append the Glimmer ID to a base URI.
        return string(abi.encodePacked(_baseTokenURI, _glimmerId.toString(), ".json"));
    }

    /**
     * @dev Returns the owner of a specific Glimmer.
     * @param _glimmerId The ID of the Glimmer.
     * @return The address of the Glimmer's owner.
     */
    function getGlimmerOwner(uint256 _glimmerId) public view returns (address) {
        return glimmers[_glimmerId].owner;
    }

    // --- Dynamic Property Engine (7-9) ---

    /**
     * @dev Defines a new global property type with its characteristics.
     * @param _name The name of the property (e.g., "Energy", "Maturity").
     * @param _type The type of the property (Numeric, Boolean, Categorical).
     * @param _minValue The minimum allowed value for this property.
     * @param _maxValue The maximum allowed value for this property.
     * @param _decayRate The rate at which this property decays over time (per second).
     * @return The ID (index) of the newly registered property.
     */
    function registerPropertyDefinition(
        string memory _name,
        PropertyType _type,
        uint256 _minValue,
        uint256 _maxValue,
        uint256 _decayRate
    ) public onlyOwner returns (uint256) {
        require(propertyNameToId[_name] == 0, "MetaVerseForge: Property with this name already exists"); // Assuming ID 0 is invalid
        uint256 newPropertyId = propertyDefinitions.length;
        propertyDefinitions.push(PropertyDefinition(_name, _type, _minValue, _maxValue, _decayRate));
        propertyNameToId[_name] = newPropertyId + 1; // Store 1-indexed ID

        emit PropertyDefinitionRegistered(newPropertyId, _name, _type);
        return newPropertyId;
    }

    /**
     * @dev Allows the owner or an approved module to directly set a Glimmer's property value.
     * This is an internal function that can be called by other functions like `evolveGlimmer` or modules.
     * @param _glimmerId The ID of the Glimmer to update.
     * @param _propertyIndex The index of the property to update.
     * @param _newValue The new value for the property.
     */
    function updateGlimmerProperty(uint256 _glimmerId, uint256 _propertyIndex, uint256 _newValue) public {
        require(glimmers[_glimmerId].owner != address(0), "MetaVerseForge: Glimmer does not exist");
        require(_propertyIndex < propertyDefinitions.length, "MetaVerseForge: Invalid property index");

        // Ensure this call is from an authorized source (owner or approved module)
        require(_msgSender() == owner() || isModuleApproved(_msgSender()), "MetaVerseForge: Unauthorized property update");

        uint256 oldValue = glimmers[_glimmerId].propertyValues[_propertyIndex];
        glimmers[_glimmerId].propertyValues[_propertyIndex] = _newValue;

        // Apply min/max constraints
        if (_newValue < propertyDefinitions[_propertyIndex].minValue) {
            glimmers[_glimmerId].propertyValues[_propertyIndex] = propertyDefinitions[_propertyIndex].minValue;
        } else if (_newValue > propertyDefinitions[_propertyIndex].maxValue) {
            glimmers[_glimmerId].propertyValues[_propertyIndex] = propertyDefinitions[_propertyIndex].maxValue;
        }

        emit GlimmerPropertyUpdated(_glimmerId, _propertyIndex, oldValue, glimmers[_glimmerId].propertyValues[_propertyIndex]);
    }

    /**
     * @dev Triggers the Glimmer's internal evolution logic. Updates properties based on time, decay,
     * and attached modules. Anyone can call this to trigger evolution for a Glimmer.
     * @param _glimmerId The ID of the Glimmer to evolve.
     */
    function evolveGlimmer(uint256 _glimmerId) public {
        Glimmer storage glimmer = glimmers[_glimmerId];
        require(glimmer.owner != address(0), "MetaVerseForge: Glimmer does not exist");

        uint256 timeElapsed = block.timestamp - glimmer.lastEvolvedTimestamp;
        if (timeElapsed == 0) return; // No time elapsed, no evolution needed

        for (uint256 i = 0; i < glimmer.propertyValues.length; i++) {
            PropertyDefinition storage propDef = propertyDefinitions[i];
            uint256 currentValue = glimmer.propertyValues[i];

            // Apply decay
            if (propDef.decayRate > 0 && currentValue > propDef.minValue) {
                uint256 decayAmount = (timeElapsed * propDef.decayRate) / 10**18; // Assuming decayRate is fixed-point 18 decimals
                if (currentValue > decayAmount) {
                    currentValue -= decayAmount;
                } else {
                    currentValue = propDef.minValue;
                }
            }

            // Apply min/max constraints
            if (currentValue < propDef.minValue) currentValue = propDef.minValue;
            if (currentValue > propDef.maxValue) currentValue = propDef.maxValue;

            glimmer.propertyValues[i] = currentValue;
        }

        // Trigger attached modules' evolution logic (if any)
        for (uint256 i = 0; i < glimmer.attachedModules.length; i++) {
            uint256 moduleId = glimmer.attachedModules[i];
            address moduleContract = moduleProposals[moduleId - 1].moduleContract;
            // The module's applyEffect might take _effectData. For evolution, it could be empty or a specific enum.
            // A more complex design would have module-specific evolution functions.
            // For now, it simply signals an effect has been applied.
            IEnhancementModule(moduleContract).applyEffect(_glimmerId, address(this), new bytes(0));
        }

        glimmer.lastEvolvedTimestamp = block.timestamp;
        emit GlimmerEvolved(_glimmerId, glimmer.propertyValues, block.timestamp);
    }

    // Helper to check if a module is approved
    function isModuleApproved(address _moduleContract) internal view returns (bool) {
        if (moduleContractToId[_moduleContract] > 0) {
            uint256 moduleId = moduleContractToId[_moduleContract];
            return moduleProposals[moduleId - 1].approved;
        }
        return false;
    }


    // --- Resource & Interaction System (10-14) ---

    /**
     * @dev Defines a new internal virtual resource type.
     * @param _name The name of the resource (e.g., "Essence", "Spark").
     * @param _symbol The symbol for the resource.
     * @param _maxSupply The maximum global supply of this resource.
     * @return The ID (index) of the newly registered resource.
     */
    function registerResourceDefinition(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) public onlyOwner returns (uint256) {
        require(resourceNameToId[_name] == 0, "MetaVerseForge: Resource with this name already exists");
        uint256 newResourceId = resourceDefinitions.length;
        resourceDefinitions.push(ResourceDefinition(_name, _symbol, _maxSupply, 0));
        resourceNameToId[_name] = newResourceId + 1; // Store 1-indexed ID

        emit ResourceDefinitionRegistered(newResourceId, _name, _symbol);
        return newResourceId;
    }

    /**
     * @dev Injects a specified amount of virtual resource into a Glimmer, affecting its state.
     * This function's exact effect on properties would be hardcoded or managed by an attached module.
     * For this example, it just updates the Glimmer's resource balance.
     * @param _glimmerId The ID of the Glimmer.
     * @param _resourceTypeId The ID of the resource to inject.
     * @param _amount The amount of resource to inject.
     */
    function injectResource(uint256 _glimmerId, uint256 _resourceTypeId, uint256 _amount) public {
        Glimmer storage glimmer = glimmers[_glimmerId];
        require(glimmer.owner != address(0), "MetaVerseForge: Glimmer does not exist");
        require(_resourceTypeId < resourceDefinitions.length, "MetaVerseForge: Invalid resource type");
        require(_msgSender() == owner() || glimmer.owner == _msgSender() || isModuleApproved(_msgSender()), "MetaVerseForge: Unauthorized resource injection");

        ResourceDefinition storage resourceDef = resourceDefinitions[_resourceTypeId];
        require(resourceDef.currentSupply + _amount <= resourceDef.maxSupply, "MetaVerseForge: Exceeds max resource supply");

        glimmer.resourceBalances[_resourceTypeId] += _amount;
        resourceDef.currentSupply += _amount;

        // Example: injecting a resource could boost a property
        // updateGlimmerProperty(_glimmerId, somePropertyIndex, someNewValue);

        emit ResourceInjected(_glimmerId, _resourceTypeId, _amount);
    }

    /**
     * @dev Extracts virtual resources from a Glimmer, potentially depleting its properties.
     * @param _glimmerId The ID of the Glimmer.
     * @param _resourceTypeId The ID of the resource to extract.
     * @param _amount The amount of resource to extract.
     */
    function extractResource(uint256 _glimmerId, uint256 _resourceTypeId, uint256 _amount) public {
        Glimmer storage glimmer = glimmers[_glimmerId];
        require(glimmer.owner != address(0), "MetaVerseForge: Glimmer does not exist");
        require(_resourceTypeId < resourceDefinitions.length, "MetaVerseForge: Invalid resource type");
        require(glimmer.resourceBalances[_resourceTypeId] >= _amount, "MetaVerseForge: Insufficient resource balance in Glimmer");
        require(_msgSender() == owner() || glimmer.owner == _msgSender() || isModuleApproved(_msgSender()), "MetaVerseForge: Unauthorized resource extraction");


        ResourceDefinition storage resourceDef = resourceDefinitions[_resourceTypeId];
        glimmer.resourceBalances[_resourceTypeId] -= _amount;
        resourceDef.currentSupply -= _amount; // Reduce global supply

        // Example: extracting a resource could reduce a property
        // updateGlimmerProperty(_glimmerId, somePropertyIndex, someNewValue);

        emit ResourceExtracted(_glimmerId, _resourceTypeId, _amount);
    }

    /**
     * @dev Combines two Glimmers into a new one, blending their properties.
     * The original Glimmers are burned in the process.
     * @param _glimmerIdA The ID of the first Glimmer.
     * @param _glimmerIdB The ID of the second Glimmer.
     * @return The ID of the newly created fused Glimmer.
     */
    function fuseGlimmers(uint256 _glimmerIdA, uint256 _glimmerIdB) public returns (uint256) {
        Glimmer storage glimmerA = glimmers[_glimmerIdA];
        Glimmer storage glimmerB = glimmers[_glimmerIdB];

        require(glimmerA.owner != address(0) && glimmerB.owner != address(0), "MetaVerseForge: One or both Glimmers do not exist");
        require(glimmerA.owner == _msgSender() || glimmerB.owner == _msgSender(), "MetaVerseForge: Caller must own at least one Glimmer");
        require(_glimmerIdA != _glimmerIdB, "MetaVerseForge: Cannot fuse a Glimmer with itself");

        // Simple fusion logic: average properties, new owner is the caller
        uint256[] memory newPropertyValues = new uint256[](propertyDefinitions.length);
        for (uint256 i = 0; i < propertyDefinitions.length; i++) {
            newPropertyValues[i] = (glimmerA.propertyValues[i] + glimmerB.propertyValues[i]) / 2;
        }

        // Burn original Glimmers
        burnGlimmer(_glimmerIdA);
        burnGlimmer(_glimmerIdB);

        uint256 newGlimmerId = mintGlimmer(_msgSender(), newPropertyValues);
        emit GlimmerFused(_glimmerIdA, _glimmerIdB, newGlimmerId);
        return newGlimmerId;
    }

    /**
     * @dev Deconstructs a Glimmer, potentially releasing its constituent virtual resources
     * or sub-fragments. The original Glimmer is burned.
     * @param _glimmerId The ID of the Glimmer to shatter.
     * @return An array of resource IDs released (simplified for example).
     */
    function shatterGlimmer(uint256 _glimmerId) public onlyGlimmerOwner(_glimmerId) returns (uint256[] memory) {
        Glimmer storage glimmer = glimmers[_glimmerId];
        require(glimmer.owner != address(0), "MetaVerseForge: Glimmer does not exist");

        uint256[] memory releasedResources = new uint256[](resourceDefinitions.length); // Placeholder for actual resource IDs

        // Example: release resources based on Glimmer's properties or resource balances
        for (uint256 i = 0; i < resourceDefinitions.length; i++) {
            uint256 amountToRelease = glimmer.resourceBalances[i]; // Release all internal resources
            if (amountToRelease > 0) {
                // In a real system, these would be transferred to the owner or a pool.
                // For this example, we just decrement global supply and clear Glimmer's balance.
                resourceDefinitions[i].currentSupply -= amountToRelease;
                glimmer.resourceBalances[i] = 0;
                releasedResources[i] = i; // Store resource ID as released
            }
        }

        burnGlimmer(_glimmerId); // Burn the Glimmer
        emit GlimmerShattered(_glimmerId, releasedResources);
        return releasedResources;
    }

    // --- Co-creation & Enhancement Modules (15-18) ---

    /**
     * @dev Allows Spark stakers to propose a new external contract to be an approved Enhancement Module.
     * @param _moduleContract The address of the external module contract.
     * @param _description A description of what the module does.
     * @return The ID of the new module proposal.
     */
    function proposeEnhancementModule(address _moduleContract, string memory _description) public onlySparkStaker returns (uint256) {
        require(moduleContractToId[_moduleContract] == 0, "MetaVerseForge: This module contract has already been proposed or approved");
        
        uint256 proposalId = moduleProposals.length;
        moduleProposals.push(ModuleProposal(_moduleContract, _description, false, 0, 0, new mapping(address => bool)()));
        moduleContractToId[_moduleContract] = proposalId + 1; // 1-indexed for lookup

        emit ModuleProposalSubmitted(proposalId, _moduleContract, _description, _msgSender());
        return proposalId;
    }

    /**
     * @dev Staked Spark token holders vote on whether to approve a proposed Enhancement Module.
     * @param _proposalId The ID of the module proposal.
     * @param _approve True for 'yes', false for 'no'.
     */
    function voteOnModuleProposal(uint256 _proposalId, bool _approve) public onlySparkStaker {
        require(_proposalId < moduleProposals.length, "MetaVerseForge: Invalid module proposal ID");
        ModuleProposal storage proposal = moduleProposals[_proposalId];
        require(!proposal.hasVoted[_msgSender()], "MetaVerseForge: Already voted on this proposal");
        require(!proposal.approved, "MetaVerseForge: Module already approved"); // Cannot vote after approval

        uint256 votingPower = stakedSpark[_msgSender()];
        require(votingPower > 0, "MetaVerseForge: No staked Spark to vote with");

        if (_approve) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[_msgSender()] = true;

        // Simple majority vote for approval threshold
        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= minSparkStakeForProposal) { // minSparkStakeForProposal serves as a quorum here
            proposal.approved = true;
            approvedModules.push(_proposalId + 1); // Store 1-indexed module ID
            emit ModuleApproved(_proposalId + 1, proposal.moduleContract);
        }

        emit ModuleProposalVoted(_proposalId, _msgSender(), _approve);
    }

    /**
     * @dev Attaches an approved Enhancement Module to a specific Glimmer.
     * @param _glimmerId The ID of the Glimmer.
     * @param _moduleId The 1-indexed ID of the approved module.
     */
    function attachEnhancementModule(uint256 _glimmerId, uint256 _moduleId) public onlyGlimmerOwner(_glimmerId) {
        require(_moduleId > 0 && _moduleId <= moduleProposals.length, "MetaVerseForge: Invalid module ID");
        require(moduleProposals[_moduleId - 1].approved, "MetaVerseForge: Module is not approved");

        Glimmer storage glimmer = glimmers[_glimmerId];
        for (uint256 i = 0; i < glimmer.attachedModules.length; i++) {
            require(glimmer.attachedModules[i] != _moduleId, "MetaVerseForge: Module already attached");
        }

        glimmer.attachedModules.push(_moduleId);
        emit ModuleAttached(_glimmerId, _moduleId);
    }

    /**
     * @dev Detaches an Enhancement Module from a Glimmer.
     * @param _glimmerId The ID of the Glimmer.
     * @param _moduleId The 1-indexed ID of the module to detach.
     */
    function detachEnhancementModule(uint256 _glimmerId, uint256 _moduleId) public onlyGlimmerOwner(_glimmerId) {
        Glimmer storage glimmer = glimmers[_glimmerId];
        bool found = false;
        for (uint256 i = 0; i < glimmer.attachedModules.length; i++) {
            if (glimmer.attachedModules[i] == _moduleId) {
                glimmer.attachedModules[i] = glimmer.attachedModules[glimmer.attachedModules.length - 1]; // Swap with last
                glimmer.attachedModules.pop(); // Remove last
                found = true;
                break;
            }
        }
        require(found, "MetaVerseForge: Module not attached to Glimmer");
        emit ModuleDetached(_glimmerId, _moduleId);
    }

    // --- Adaptive Governance & Reputation (19-25) ---

    /**
     * @dev Stakes Spark tokens to gain voting power and potentially earn reputation.
     * @param _amount The amount of Spark tokens to stake.
     */
    function stakeSpark(uint256 _amount) public {
        require(_amount > 0, "MetaVerseForge: Must stake a positive amount");
        sparkToken.transferFrom(_msgSender(), address(this), _amount);
        stakedSpark[_msgSender()] += _amount;
        emit SparkStaked(_msgSender(), _amount);
    }

    /**
     * @dev Unstakes Spark tokens. Funds are locked for a period.
     * @param _amount The amount of Spark tokens to unstake.
     */
    function unstakeSpark(uint256 _amount) public {
        require(stakedSpark[_msgSender()] >= _amount, "MetaVerseForge: Insufficient staked Spark");
        require(unstakeLockupEnd[_msgSender()] < block.timestamp, "MetaVerseForge: Unstake lockup period active");

        stakedSpark[_msgSender()] -= _amount;
        sparkToken.transfer(address(_msgSender()), _amount);
        unstakeLockupEnd[_msgSender()] = block.timestamp + SPARK_FOR_VOTING_LOCKUP_PERIOD; // Start lockup for *next* unstake
        emit SparkUnstaked(_msgSender(), _amount);
    }

    /**
     * @dev Allows a staker to delegate their voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) public onlySparkStaker {
        require(_delegatee != address(0), "MetaVerseForge: Cannot delegate to zero address");
        require(_delegatee != _msgSender(), "MetaVerseForge: Cannot delegate to self");
        votingDelegates[_msgSender()] = _delegatee;
        emit VotingPowerDelegated(_msgSender(), _delegatee);
    }

    /**
     * @dev Allows stakers to propose changes to the core contract's parameters or logic.
     * The `_calldata` must be carefully crafted for the target function.
     * @param _description A description of the proposed change.
     * @param _calldataPayload The ABI-encoded calldata for the function to be called on `_targetContract`.
     * @param _targetContract The address of the contract to call (e.g., this contract).
     * @return The ID of the new protocol change proposal.
     */
    function proposeProtocolParameterChange(
        string memory _description,
        bytes memory _calldataPayload,
        address _targetContract
    ) public onlySparkStaker returns (uint256) {
        require(stakedSpark[_msgSender()] >= minSparkStakeForProposal, "MetaVerseForge: Insufficient staked Spark to propose");

        uint256 proposalId = protocolChangeProposals.length;
        protocolChangeProposals.push(ProtocolChangeProposal(_description, _calldataPayload, _targetContract, false, 0, 0, new mapping(address => bool)()));

        emit ProtocolChangeProposed(proposalId, _description, _msgSender());
        return proposalId;
    }

    /**
     * @dev Staked Spark token holders vote on proposed protocol changes.
     * @param _proposalId The ID of the protocol change proposal.
     * @param _approve True for 'yes', false for 'no'.
     */
    function voteOnProtocolChange(uint256 _proposalId, bool _approve) public onlySparkStaker {
        require(_proposalId < protocolChangeProposals.length, "MetaVerseForge: Invalid protocol change proposal ID");
        ProtocolChangeProposal storage proposal = protocolChangeProposals[_proposalId];
        require(!proposal.hasVoted[_msgSender()], "MetaVerseForge: Already voted on this proposal");
        require(!proposal.executed, "MetaVerseForge: Proposal already executed");

        address voter = _msgSender();
        if (votingDelegates[voter] != address(0)) {
            voter = votingDelegates[voter]; // Use delegate's address for voting power
        }
        uint256 votingPower = stakedSpark[voter];
        require(votingPower > 0, "MetaVerseForge: No staked Spark or delegated power to vote with");

        if (_approve) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[_msgSender()] = true; // Mark original voter as voted

        emit ProtocolChangeVoted(_proposalId, _msgSender(), _approve);
    }

    /**
     * @dev Executes an approved protocol change proposal. Can only be called once.
     * @param _proposalId The ID of the protocol change proposal.
     */
    function executeProtocolChange(uint256 _proposalId) public onlyOwner {
        require(_proposalId < protocolChangeProposals.length, "MetaVerseForge: Invalid proposal ID");
        ProtocolChangeProposal storage proposal = protocolChangeProposals[_proposalId];
        require(!proposal.executed, "MetaVerseForge: Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "MetaVerseForge: Proposal not approved by majority");
        // Add a quorum check if needed: require(proposal.votesFor + proposal.votesAgainst >= totalStakedSpark * quorumPercentage)

        (bool success, ) = proposal.targetContract.call(proposal.calldataPayload);
        require(success, "MetaVerseForge: Protocol change execution failed");

        proposal.executed = true;
        emit ProtocolChangeExecuted(_proposalId);
    }

    /**
     * @dev Internal function to adjust a user's on-chain reputation score.
     * Can be called by owner or other privileged functions/modules for contribution/penalty.
     * @param _user The address whose reputation to update.
     * @param _delta The amount to change the reputation by (positive for gain, negative for loss).
     */
    function updateReputation(address _user, int256 _delta) public {
        require(_msgSender() == owner() || isModuleApproved(_msgSender()), "MetaVerseForge: Unauthorized reputation update");

        int256 oldScore = reputationScores[_user];
        reputationScores[_user] += _delta;
        emit ReputationUpdated(_user, _delta, reputationScores[_user]);
    }

    // --- External Catalysts & Global Events (26-27) ---

    /**
     * @dev Simulates a network-wide event (e.g., "Cosmic Alignment") that affects
     * all Glimmers based on the catalyst type and data.
     * Only callable by the contract owner.
     * @param _type The type of global catalyst event.
     * @param _data Additional data specific to the event type.
     */
    function triggerGlobalCatalyst(CatalystType _type, bytes memory _data) public onlyOwner {
        // This function would iterate through all existing glimmers and apply an effect.
        // For a large number of glimmers, this would be gas-prohibitive.
        // In a real system, this would trigger an off-chain process or a batched, permissioned update.
        // For demonstration, we simply emit the event.
        emit GlobalCatalystTriggered(_type, _data);

        // Example logic (not executed for gas):
        // for (uint256 i = 1; i <= _glimmerCounter; i++) {
        //     if (glimmers[i].owner != address(0)) { // Check if Glimmer exists
        //         // Apply specific effects based on _type and _data
        //         // e.g., reduce all 'Energy' properties by X%
        //         // evolveGlimmer(i); // force evolution on all
        //     }
        // }
    }

    /**
     * @dev Records or updates a simulated "affinity" or relationship score between two Glimmers.
     * This can influence future interactions (e.g., fusion success rates, special effects).
     * @param _glimmerIdA The ID of the first Glimmer.
     * @param _glimmerIdB The ID of the second Glimmer.
     * @param _affinityChange The amount to change the affinity by (positive for boost, negative for drain).
     */
    function settleInterGlimmerAffinity(uint256 _glimmerIdA, uint256 _glimmerIdB, int256 _affinityChange) public {
        require(glimmers[_glimmerIdA].owner != address(0) && glimmers[_glimmerIdB].owner != address(0), "MetaVerseForge: One or both Glimmers do not exist");
        require(_glimmerIdA != _glimmerIdB, "MetaVerseForge: Cannot settle affinity with itself");
        require(_msgSender() == owner() || isModuleApproved(_msgSender()), "MetaVerseForge: Unauthorized affinity settlement");

        Glimmer storage glimmerA = glimmers[_glimmerIdA];
        // Note: affinity is stored on glimmerA, could be symmetrical or one-sided
        glimmerA.glimmerAffinities[_glimmerIdB] += _affinityChange;

        // A more advanced system might store bidirectional or an aggregated score.
        // glimmers[_glimmerIdB].glimmerAffinities[_glimmerIdA] += _affinityChange;

        emit InterGlimmerAffinitySettled(_glimmerIdA, _glimmerIdB, _affinityChange);
    }

    // --- Fee Management (28) ---

    /**
     * @dev Allows the contract owner to withdraw accumulated protocol fees.
     */
    function withdrawFees() public onlyOwner {
        uint256 amount = protocolFeesCollected;
        protocolFeesCollected = 0;
        payable(owner()).transfer(amount);
        emit FeesWithdrawn(owner(), amount);
    }

    // --- Metadata and Getters (29-30) ---

    /**
     * @dev Sets a base URI for Glimmer metadata.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
        emit BaseURISet(_newBaseURI);
    }

    // --- Internal Helpers & Getters (for interfaces/modules) ---

    function getPropertyDefinition(uint256 _propertyIndex) public view returns (string memory name, PropertyType pType, uint256 minValue, uint256 maxValue, uint256 decayRate) {
        require(_propertyIndex < propertyDefinitions.length, "MetaVerseForge: Invalid property index");
        PropertyDefinition storage prop = propertyDefinitions[_propertyIndex];
        return (prop.name, prop.pType, prop.minValue, prop.maxValue, prop.decayRate);
    }

    function getResourceDefinition(uint256 _resourceIndex) public view returns (string memory name, string memory symbol, uint256 maxSupply, uint256 currentSupply) {
        require(_resourceIndex < resourceDefinitions.length, "MetaVerseForge: Invalid resource index");
        ResourceDefinition storage res = resourceDefinitions[_resourceIndex];
        return (res.name, res.symbol, res.maxSupply, res.currentSupply);
    }

    function getGlimmerBalance(address _owner) public view returns (uint256) {
        return _glimmerBalances[_owner];
    }
}


// --- Minimal Spark Token (for internal deployment) ---

/**
 * @title SparkToken
 * @dev A minimal ERC20-like token for governance.
 * Deployed internally by MetaVerseForge. Not a full ERC20 implementation for brevity.
 */
contract SparkToken is Context, ISparkToken {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    address public minter; // The MetaVerseForge contract is the minter

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory name_, string memory symbol_, address _minter, uint256 _initialSupply) {
        _name = name_;
        _symbol = symbol_;
        minter = _minter;
        _mint(_minter, _initialSupply); // Initial supply owned by the minter (MetaVerseForge)
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _transfer(from, to, amount);
        uint256 currentAllowance = _allowances[from][_msgSender()];
        require(currentAllowance >= amount, "SparkToken: transfer amount exceeds allowance");
        unchecked {
            _approve(from, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        unchecked {
            uint256 currentAllowance = _allowances[_msgSender()][spender];
            require(currentAllowance >= subtractedValue, "SparkToken: decreased allowance below zero");
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function mint(address _to, uint256 _amount) public override {
        require(_msgSender() == minter, "SparkToken: Only minter can mint");
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public override {
        require(_msgSender() == minter, "SparkToken: Only minter can burn");
        _burn(_from, _amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "SparkToken: transfer from the zero address");
        require(to != address(0), "SparkToken: transfer to the zero address");
        require(_balances[from] >= amount, "SparkToken: transfer amount exceeds balance");

        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "SparkToken: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "SparkToken: burn from the zero address");
        require(_balances[account] >= amount, "SparkToken: burn amount exceeds balance");

        unchecked {
            _balances[account] -= amount;
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "SparkToken: approve from the zero address");
        require(spender != address(0), "SparkToken: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
```