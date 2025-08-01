Okay, this is an exciting challenge! Let's design a smart contract that goes beyond typical DeFi or NFT use cases, focusing on dynamic identity, collective intelligence, and skill-based access, with elements of gamification and adaptive properties.

I'll call this protocol **"CognitoNexus"** – a decentralized collective intelligence and dynamic expertise graph. It issues "Expertise Modules" (NFTs) that represent skills, knowledge contributions, or validated achievements. These modules are dynamic, can level up, decay, merge, and unlock various protocol privileges.

---

## CognitoNexus: Decentralized Expertise Graph Protocol

**Outline & Function Summary:**

The CognitoNexus protocol aims to create a dynamic, on-chain representation of collective expertise and individual skill sets. It uses a unique blend of ERC-721 for "Expertise Modules," time-based mechanics, reputation weighting, and a DAO-like governance structure to create a self-evolving knowledge base.

**Core Concepts:**

1.  **Expertise Modules (EMs):** ERC-721 NFTs representing a specific skill, knowledge domain, or validated contribution. EMs have dynamic properties like `proficiencyLevel`, `decayRate`, and `synergyScore`.
2.  **Contributors:** Users who acquire, utilize, and validate Expertise Modules.
3.  **Validation & Attestation:** A decentralized process where contributors can attest to their own expertise or validate the expertise of others, backed by a staking mechanism.
4.  **Dynamic Evolution:** EMs can level up through usage/validation, decay over time if not refreshed, and even merge to form more advanced modules.
5.  **Skill-Gated Access:** EMs can grant access to specific protocol functionalities, voting power, or external integrations.
6.  **Oracle Integration:** For potential real-world data impacting module relevance or decay rates.
7.  **Adaptive Parameters:** Key protocol parameters (e.g., decay rates, validation stakes) can be adjusted through governance based on collective behavior.

---

### Function Categories & Summary:

**I. Core Module Management (ERC-721 Extended)**
1.  `mintExpertiseModule(string calldata _uri, uint256 _initialProficiency, uint256 _decayRate)`: Mints a new Expertise Module NFT. Only callable by a whitelisted `MODULE_ISSUER_ROLE`.
2.  `updateModuleProficiency(uint256 _moduleId, uint256 _newProficiency)`: Adjusts a module's proficiency level. Restricted.
3.  `updateModuleDecayRate(uint256 _moduleId, uint256 _newDecayRate)`: Changes a module's decay rate. Restricted.
4.  `getCurrentProficiency(uint256 _moduleId)`: Calculates and returns the current proficiency considering decay.
5.  `transferExpertiseModule(address from, address to, uint256 tokenId)`: Standard ERC721 transfer, but with potential lockout periods for newly acquired or merged modules.

**II. Dynamic Module Evolution & Interaction**
6.  `levelUpModule(uint256 _moduleId)`: Increments a module's proficiency level if certain criteria (e.g., attestation score, usage count) are met.
7.  `mergeExpertiseModules(uint256 _moduleId1, uint256 _moduleId2)`: Combines two existing modules into a new, potentially higher-tier module, burning the originals. Requires a `mergeRecipe`.
8.  `forkModule(uint256 _parentModuleId, string calldata _newUri)`: Creates a specialized child module from a parent, inheriting some properties but with a new focus.
9.  `proposeModuleRecipe(uint256[] calldata _inputModules, string calldata _outputUri, uint256 _outputProficiency, uint256 _outputDecayRate)`: Allows community members to propose new `mergeRecipe` or `forkRecipe` definitions for governance approval.

**III. Contributor Interaction & Validation**
10. `attestMyExpertise(uint256 _moduleId, string calldata _evidenceUri)`: Allows a module owner to attest to their own expertise in a module, linking to off-chain evidence. Increases `attestationScore`.
11. `stakeForValidation(uint256 _moduleId, uint256 _amount)`: Contributors stake tokens to become a validator for a specific module's attestations.
12. `validateExpertiseAttestation(uint256 _attestationId, bool _isValid)`: Staked validators review and vote on an attestation. Rewards/slashes validators based on consensus.
13. `claimValidationRewards()`: Allows validators to claim accumulated rewards from successful validations.
14. `delegateValidationPower(address _delegatee, uint256 _amount)`: Allows a contributor to delegate their validation stake and power to another address.

**IV. Protocol Utility & Access**
15. `checkSkillGate(uint256 _requiredModuleId, uint256 _minProficiency)`: A read-only function that allows external contracts or dApps to verify if an address holds a specific module above a minimum proficiency.
16. `grantAccessByProficiency(uint256 _requiredModuleId, uint256 _minProficiency)`: An internal/external function allowing the protocol itself to grant special permissions or access based on held modules (e.g., access to a privileged function).
17. `queryActiveModuleHolders(uint256 _moduleId)`: Returns a list of addresses holding a specific module with `proficiencyLevel` above a threshold.
18. `registerExternalOracle(address _oracleAddress)`: Whitelists an external oracle contract that can provide real-world data (e.g., industry trends) to influence module relevance or decay.

**V. Governance & System Maintenance**
19. `updateModuleCreationFee(uint256 _newFee)`: Allows governance to adjust the fee for minting new base Expertise Modules.
20. `setValidationStakeAmount(uint256 _newStakeAmount)`: Allows governance to adjust the minimum stake required for validation.
21. `toggleModuleMinting(bool _canMint)`: Allows governance to pause or resume the minting of new base modules.
22. `withdrawProtocolFees()`: Allows the protocol's treasury to withdraw accumulated fees.
23. `proposeProtocolParameterChange(bytes32 _paramHash, uint256 _newValue)`: Allows a whitelisted role (e.g., `GOVERNANCE_ROLE`) to propose a change to a core protocol parameter, subject to voting.
24. `voteOnProposal(bytes32 _proposalId, bool _support)`: Allows contributors with sufficient `GOVERNANCE_VOTING_POWER` (derived from their EMs) to vote on open proposals.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For staking

/**
 * @title CognitoNexus: Decentralized Expertise Graph Protocol
 * @dev This contract implements a dynamic expertise module system, where NFTs represent skills and knowledge.
 *      Modules can level up, decay, merge, and grant access based on proficiency.
 *      It incorporates decentralized validation, staking, and a governance mechanism.
 *      The design aims for high modularity, extensibility, and community-driven evolution.
 */
contract CognitoNexus is ERC721, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODULE_ISSUER_ROLE = keccak256("MODULE_ISSUER_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant ORACLE_FEED_ROLE = keccak256("ORACLE_FEED_ROLE"); // For external data feeds

    // --- Structs ---

    struct ExpertiseModule {
        uint256 id;
        string uri; // URI for metadata, includes skill description, visual, etc.
        uint256 baseProficiency; // Initial proficiency, subject to decay
        uint256 decayRate; // Rate at which proficiency decays per day (e.g., 10 for 1% per 10 days)
        uint256 lastProficiencyUpdate; // Timestamp of the last proficiency update
        uint256 creationTime; // Timestamp of module creation
        uint256 attestationScore; // Cumulative score from attestations
        uint256 usageCount; // How many times this module has been 'used' for access/features
        bool isForkable; // Can this module be used to create specialized forks?
        bool isMergeable; // Can this module participate in a merge?
        uint256 transferLockUntil; // Timestamp until module cannot be transferred
    }

    struct Attestation {
        uint256 attestationId;
        uint256 moduleId;
        address attester;
        string evidenceUri;
        uint256 timestamp;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) hasVoted; // Tracks if a validator has voted
        bool isFinalized;
        bool isValidated;
    }

    struct MergeRecipe {
        uint256[] inputModuleIds; // IDs of modules required for this recipe (0 for any module in a category)
        string outputUri;
        uint256 outputBaseProficiency;
        uint256 outputDecayRate;
        bool exists; // To check if a recipe is defined
    }

    struct Proposal {
        bytes32 proposalId;
        bytes32 paramHash; // Hashed parameter name or identifier
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) hasVoted;
        bool executed;
        bool exists;
    }

    // --- State Variables ---
    Counters.Counter private _moduleIdCounter;
    Counters.Counter private _attestationIdCounter;
    Counters.Counter private _proposalIdCounter;

    mapping(uint256 => ExpertiseModule) public expertiseModules;
    mapping(uint256 => Attestation) public attestations;
    mapping(uint256 => mapping(address => uint256)) public moduleValidationStakes; // moduleId => validator => amount
    mapping(address => uint256) public totalValidationStakes; // total stake per validator across all modules

    mapping(uint256 => MergeRecipe) public mergeRecipes; // hash of input module IDs => recipe
    uint256[] public registeredMergeRecipeHashes; // Store hashes to iterate or lookup

    mapping(bytes32 => Proposal) public proposals; // proposalId => Proposal
    mapping(bytes32 => uint256) public protocolParameters; // ParamHash => value (for governance)

    uint256 public moduleCreationFee; // Fee to mint a new base module (in ETH/WETH)
    uint256 public minValidationStake; // Minimum stake required per module to validate
    uint256 public validationRewardPerUpvote; // Reward for a successful validation upvote
    uint256 public validationSlashPerDownvote; // Slash for a wrong validation downvote
    uint256 public attestationValidationPeriod; // Duration for attestations to be voted on
    uint256 public proposalVotingPeriod; // Duration for proposals to be voted on
    uint256 public moduleTransferLockDuration; // Duration new modules are locked from transfer

    address public feeRecipient; // Address to send protocol fees

    IERC20 public stakingToken; // ERC-20 token used for staking

    // --- Events ---
    event ExpertiseModuleMinted(uint256 indexed moduleId, address indexed owner, string uri, uint256 initialProficiency, uint256 decayRate);
    event ModuleProficiencyUpdated(uint256 indexed moduleId, uint256 oldProficiency, uint256 newProficiency);
    event ModuleDecayRateUpdated(uint256 indexed moduleId, uint256 oldRate, uint256 newRate);
    event ExpertiseModuleLeveledUp(uint256 indexed moduleId, uint256 newLevel, address indexed by);
    event ModulesMerged(uint256 indexed newModuleId, uint256[] indexed burntModuleIds, address indexed owner);
    event ModuleForked(uint256 indexed parentModuleId, uint256 indexed newModuleId, address indexed owner);
    event MergeRecipeProposed(bytes32 indexed recipeHash, uint256[] inputModules, string outputUri);
    event AttestationSubmitted(uint256 indexed attestationId, uint256 indexed moduleId, address indexed attester, string evidenceUri);
    event ValidationStaked(uint256 indexed moduleId, address indexed validator, uint256 amount);
    event AttestationValidated(uint256 indexed attestationId, address indexed validator, bool isValid, uint256 upvotes, uint256 downvotes);
    event ValidationRewardsClaimed(address indexed validator, uint256 amount);
    event ValidationPowerDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ProtocolParameterUpdated(bytes32 indexed paramHash, uint256 newValue);
    event ProposalCreated(bytes32 indexed proposalId, bytes32 indexed paramHash, uint256 newValue, uint256 endTime);
    event ProposalVoted(bytes32 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(bytes32 indexed proposalId, bool successful);
    event SkillGateChecked(address indexed user, uint256 indexed moduleId, uint256 requiredProficiency, bool hasAccess);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---
    constructor(
        string memory _name,
        string memory _symbol,
        address _admin,
        address _stakingTokenAddress,
        uint256 _moduleCreationFee,
        uint256 _minValidationStake,
        uint256 _validationRewardPerUpvote,
        uint256 _validationSlashPerDownvote,
        uint256 _attestationValidationPeriod,
        uint256 _proposalVotingPeriod,
        uint256 _moduleTransferLockDuration,
        address _feeRecipient
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin); // Custom admin role for specific settings
        _grantRole(MODULE_ISSUER_ROLE, _admin); // Admin can issue initial modules
        _grantRole(GOVERNANCE_ROLE, _admin); // Admin has initial governance power

        stakingToken = IERC20(_stakingTokenAddress);
        moduleCreationFee = _moduleCreationFee;
        minValidationStake = _minValidationStake;
        validationRewardPerUpvote = _validationRewardPerUpvote;
        validationSlashPerDownvote = _validationSlashPerDownvote;
        attestationValidationPeriod = _attestationValidationPeriod;
        proposalVotingPeriod = _proposalVotingPeriod;
        moduleTransferLockDuration = _moduleTransferLockDuration;
        feeRecipient = _feeRecipient;

        // Initialize core protocol parameters (these can be updated via governance)
        protocolParameters[keccak256("MIN_ATTESTATION_SCORE_FOR_LEVELUP")] = 100; // Example: 100 upvotes to level up
        protocolParameters[keccak256("LEVELUP_PROFICIENCY_BOOST")] = 500; // Example: 5% proficiency boost on level up
    }

    // --- Modifiers ---
    modifier onlyModuleOwner(uint256 _moduleId) {
        require(_isApprovedOrOwner(msg.sender, _moduleId), "CognitoNexus: Caller is not module owner or approved");
        _;
    }

    modifier moduleExists(uint256 _moduleId) {
        require(expertiseModules[_moduleId].id != 0, "CognitoNexus: Module does not exist");
        _;
    }

    // --- I. Core Module Management (ERC-721 Extended) ---

    /**
     * @dev Mints a new Expertise Module NFT. Callable only by MODULE_ISSUER_ROLE.
     * @param _uri The URI for the module's metadata.
     * @param _initialProficiency The initial proficiency level of the module (e.g., 1000 for 100%).
     * @param _decayRate The rate at which proficiency decays per day (e.g., 10 for 1% per 10 days).
     */
    function mintExpertiseModule(
        address _to,
        string calldata _uri,
        uint256 _initialProficiency,
        uint256 _decayRate
    ) external payable onlyRole(MODULE_ISSUER_ROLE) {
        require(msg.value >= moduleCreationFee, "CognitoNexus: Insufficient module creation fee");

        _moduleIdCounter.increment();
        uint256 newItemId = _moduleIdCounter.current();

        ExpertiseModule memory newModule = ExpertiseModule({
            id: newItemId,
            uri: _uri,
            baseProficiency: _initialProficiency,
            decayRate: _decayRate,
            lastProficiencyUpdate: block.timestamp,
            creationTime: block.timestamp,
            attestationScore: 0,
            usageCount: 0,
            isForkable: true, // Default to true, can be changed via governance/recipes
            isMergeable: true, // Default to true
            transferLockUntil: block.timestamp.add(moduleTransferLockDuration)
        });

        expertiseModules[newItemId] = newModule;
        _safeMint(_to, newItemId);

        emit ExpertiseModuleMinted(newItemId, _to, _uri, _initialProficiency, _decayRate);
    }

    /**
     * @dev Calculates and returns the current proficiency level of an Expertise Module,
     *      accounting for time-based decay.
     *      Proficiency is represented as permyriad (10,000 = 100%).
     * @param _moduleId The ID of the Expertise Module.
     * @return The current calculated proficiency level.
     */
    function getCurrentProficiency(uint256 _moduleId) public view moduleExists(_moduleId) returns (uint256) {
        ExpertiseModule storage module = expertiseModules[_moduleId];
        uint256 timeElapsed = block.timestamp.sub(module.lastProficiencyUpdate);
        uint256 decayAmount = 0;

        if (module.decayRate > 0 && timeElapsed > 0) {
            // Calculate decay based on time elapsed and decay rate
            // Example: If decayRate is 10, it means 1 unit per 10 days.
            // (timeElapsed / 1 days) * (decayRate / 10000 per day)
            // Simplified: (timeElapsed * decayRate) / (1 days * 10000)
            uint256 daysElapsed = timeElapsed.div(1 days); // 1 day in seconds
            decayAmount = daysElapsed.mul(module.decayRate);
        }

        if (module.baseProficiency <= decayAmount) {
            return 0; // Proficiency cannot go below zero
        }
        return module.baseProficiency.sub(decayAmount);
    }

    /**
     * @dev Updates the base proficiency of an Expertise Module.
     *      Can be used for boosts (e.g., from external events) or manual adjustments by admins.
     * @param _moduleId The ID of the Expertise Module.
     * @param _newProficiency The new base proficiency level.
     */
    function updateModuleProficiency(uint256 _moduleId, uint256 _newProficiency)
        external
        onlyRole(ADMIN_ROLE)
        moduleExists(_moduleId)
    {
        uint256 oldProficiency = expertiseModules[_moduleId].baseProficiency;
        expertiseModules[_moduleId].baseProficiency = _newProficiency;
        expertiseModules[_moduleId].lastProficiencyUpdate = block.timestamp;
        emit ModuleProficiencyUpdated(_moduleId, oldProficiency, _newProficiency);
    }

    /**
     * @dev Updates the decay rate of an Expertise Module.
     * @param _moduleId The ID of the Expertise Module.
     * @param _newDecayRate The new decay rate per day.
     */
    function updateModuleDecayRate(uint256 _moduleId, uint256 _newDecayRate)
        external
        onlyRole(ADMIN_ROLE)
        moduleExists(_moduleId)
    {
        uint256 oldRate = expertiseModules[_moduleId].decayRate;
        expertiseModules[_moduleId].decayRate = _newDecayRate;
        emit ModuleDecayRateUpdated(_moduleId, oldRate, _newDecayRate);
    }

    /**
     * @dev Overrides ERC721 transfer to add a transfer lock.
     * @param from The current owner.
     * @param to The new owner.
     * @param tokenId The ID of the token to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        nonReentrant
    {
        require(expertiseModules[tokenId].transferLockUntil <= block.timestamp, "CognitoNexus: Module is temporarily locked from transfer.");
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Overrides ERC721 safeTransferFrom to add a transfer lock.
     * @param from The current owner.
     * @param to The new owner.
     * @param tokenId The ID of the token to transfer.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        nonReentrant
    {
        require(expertiseModules[tokenId].transferLockUntil <= block.timestamp, "CognitoNexus: Module is temporarily locked from transfer.");
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Overrides ERC721 safeTransferFrom to add a transfer lock.
     * @param from The current owner.
     * @param to The new owner.
     * @param tokenId The ID of the token to transfer.
     * @param data Additional data.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        nonReentrant
    {
        require(expertiseModules[tokenId].transferLockUntil <= block.timestamp, "CognitoNexus: Module is temporarily locked from transfer.");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // --- II. Dynamic Module Evolution & Interaction ---

    /**
     * @dev Levels up an Expertise Module, increasing its base proficiency.
     *      Requires the module to meet a minimum attestation score.
     *      Can only be called by the module owner.
     * @param _moduleId The ID of the Expertise Module to level up.
     */
    function levelUpModule(uint256 _moduleId) external onlyModuleOwner(_moduleId) moduleExists(_moduleId) nonReentrant {
        ExpertiseModule storage module = expertiseModules[_moduleId];
        uint256 minAttestationScore = protocolParameters[keccak256("MIN_ATTESTATION_SCORE_FOR_LEVELUP")];
        uint256 levelUpProficiencyBoost = protocolParameters[keccak256("LEVELUP_PROFICIENCY_BOOST")]; // Per-myriad boost

        require(module.attestationScore >= minAttestationScore, "CognitoNexus: Insufficient attestation score to level up.");

        uint256 oldProficiency = module.baseProficiency;
        uint256 proficiencyBoostAmount = oldProficiency.mul(levelUpProficiencyBoost).div(10000); // 10000 for permyriad
        module.baseProficiency = oldProficiency.add(proficiencyBoostAmount);
        module.attestationScore = 0; // Reset attestation score after level up
        module.lastProficiencyUpdate = block.timestamp; // Refresh proficiency decay

        emit ExpertiseModuleLeveledUp(_moduleId, module.baseProficiency, msg.sender);
        emit ModuleProficiencyUpdated(_moduleId, oldProficiency, module.baseProficiency);
    }

    /**
     * @dev Combines two existing Expertise Modules into a new, potentially higher-tier module.
     *      Requires a predefined merge recipe and burns the original modules.
     *      The new module is minted to the caller.
     * @param _moduleId1 The ID of the first Expertise Module.
     * @param _moduleId2 The ID of the second Expertise Module.
     */
    function mergeExpertiseModules(uint256 _moduleId1, uint256 _moduleId2) external moduleExists(_moduleId1) moduleExists(_moduleId2) nonReentrant {
        require(ownerOf(_moduleId1) == msg.sender, "CognitoNexus: Caller is not owner of module 1.");
        require(ownerOf(_moduleId2) == msg.sender, "CognitoNexus: Caller is not owner of module 2.");
        require(expertiseModules[_moduleId1].isMergeable, "CognitoNexus: Module 1 is not mergeable.");
        require(expertiseModules[_moduleId2].isMergeable, "CognitoNexus: Module 2 is not mergeable.");

        // Sort module IDs for consistent hash generation
        uint256[] memory inputIds = new uint256[](2);
        inputIds[0] = _moduleId1 < _moduleId2 ? _moduleId1 : _moduleId2;
        inputIds[1] = _moduleId1 < _moduleId2 ? _moduleId2 : _moduleId1;

        bytes32 recipeHash = keccak256(abi.encodePacked(inputIds[0], inputIds[1]));
        MergeRecipe storage recipe = mergeRecipes[recipeHash];

        require(recipe.exists, "CognitoNexus: No merge recipe found for these modules.");

        // Burn original modules
        _burn(_moduleId1);
        _burn(_moduleId2);

        _moduleIdCounter.increment();
        uint256 newModuleId = _moduleIdCounter.current();

        ExpertiseModule memory newModule = ExpertiseModule({
            id: newModuleId,
            uri: recipe.outputUri,
            baseProficiency: recipe.outputBaseProficiency,
            decayRate: recipe.outputDecayRate,
            lastProficiencyUpdate: block.timestamp,
            creationTime: block.timestamp,
            attestationScore: 0, // Reset attestation score for new module
            usageCount: 0,
            isForkable: true,
            isMergeable: true,
            transferLockUntil: block.timestamp.add(moduleTransferLockDuration)
        });

        expertiseModules[newModuleId] = newModule;
        _safeMint(msg.sender, newModuleId);

        emit ModulesMerged(newModuleId, inputIds, msg.sender);
    }

    /**
     * @dev Creates a specialized 'fork' module from an existing parent module.
     *      The parent module is not burnt but its `isForkable` status might change based on logic.
     * @param _parentModuleId The ID of the parent module.
     * @param _newUri The URI for the new fork module's metadata.
     */
    function forkModule(uint256 _parentModuleId, string calldata _newUri) external onlyModuleOwner(_parentModuleId) moduleExists(_parentModuleId) nonReentrant {
        ExpertiseModule storage parentModule = expertiseModules[_parentModuleId];
        require(parentModule.isForkable, "CognitoNexus: Parent module is not forkable.");

        _moduleIdCounter.increment();
        uint256 newModuleId = _moduleIdCounter.current();

        // Forked module inherits base proficiency and decay rate from parent,
        // but can have new URI, and start with fresh attestation/usage.
        ExpertiseModule memory newModule = ExpertiseModule({
            id: newModuleId,
            uri: _newUri,
            baseProficiency: parentModule.baseProficiency.div(2), // Example: Half proficiency, as it's specialized
            decayRate: parentModule.decayRate,
            lastProficiencyUpdate: block.timestamp,
            creationTime: block.timestamp,
            attestationScore: 0,
            usageCount: 0,
            isForkable: false, // Forked modules are not typically forkable again
            isMergeable: true,
            transferLockUntil: block.timestamp.add(moduleTransferLockDuration)
        });

        expertiseModules[newModuleId] = newModule;
        _safeMint(msg.sender, newModuleId);

        emit ModuleForked(_parentModuleId, newModuleId, msg.sender);
    }

    /**
     * @dev Allows governance (or potentially a whitelisted role) to define new merge recipes.
     *      These recipes dictate which input modules produce which output module.
     * @param _inputModules Array of module IDs required for the recipe. Order matters for hash.
     * @param _outputUri URI of the resulting module.
     * @param _outputProficiency Base proficiency of the resulting module.
     * @param _outputDecayRate Decay rate of the resulting module.
     */
    function proposeModuleRecipe(
        uint256[] calldata _inputModules,
        string calldata _outputUri,
        uint256 _outputProficiency,
        uint256 _outputDecayRate
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(_inputModules.length > 0, "CognitoNexus: Input modules cannot be empty.");

        // Sort input modules to ensure consistent hash
        uint256[] memory sortedInputModules = new uint256[](_inputModules.length);
        for (uint256 i = 0; i < _inputModules.length; i++) {
            sortedInputModules[i] = _inputModules[i];
        }
        _sortArray(sortedInputModules); // Helper function to sort

        bytes32 recipeHash = keccak256(abi.encodePacked(sortedInputModules));
        require(!mergeRecipes[recipeHash].exists, "CognitoNexus: Recipe already exists.");

        mergeRecipes[recipeHash] = MergeRecipe({
            inputModuleIds: sortedInputModules,
            outputUri: _outputUri,
            outputBaseProficiency: _outputProficiency,
            outputDecayRate: _outputDecayRate,
            exists: true
        });
        registeredMergeRecipeHashes.push(recipeHash);

        emit MergeRecipeProposed(recipeHash, sortedInputModules, _outputUri);
    }

    // --- III. Contributor Interaction & Validation ---

    /**
     * @dev Allows a module owner to attest to their own expertise in a module.
     *      This creates an attestation which needs to be validated by other staked validators.
     * @param _moduleId The ID of the module being attested for.
     * @param _evidenceUri URI linking to off-chain evidence (e.g., certificate, project link).
     */
    function attestMyExpertise(uint256 _moduleId, string calldata _evidenceUri) external onlyModuleOwner(_moduleId) moduleExists(_moduleId) nonReentrant {
        _attestationIdCounter.increment();
        uint256 newAttestationId = _attestationIdCounter.current();

        attestations[newAttestationId] = Attestation({
            attestationId: newAttestationId,
            moduleId: _moduleId,
            attester: msg.sender,
            evidenceUri: _evidenceUri,
            timestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            isFinalized: false,
            isValidated: false
        });

        emit AttestationSubmitted(newAttestationId, _moduleId, msg.sender, _evidenceUri);
    }

    /**
     * @dev Allows a contributor to stake tokens for the right to validate attestations for a specific module.
     *      Requires a minimum stake amount.
     * @param _moduleId The ID of the module to stake for.
     * @param _amount The amount of staking token to stake.
     */
    function stakeForValidation(uint256 _moduleId, uint256 _amount) external moduleExists(_moduleId) nonReentrant {
        require(_amount >= minValidationStake, "CognitoNexus: Stake amount too low.");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "CognitoNexus: Token transfer failed.");

        moduleValidationStakes[_moduleId][msg.sender] = moduleValidationStakes[_moduleId][msg.sender].add(_amount);
        totalValidationStakes[msg.sender] = totalValidationStakes[msg.sender].add(_amount);

        _grantRole(VALIDATOR_ROLE, msg.sender); // Grant VALIDATOR_ROLE upon first stake

        emit ValidationStaked(_moduleId, msg.sender, _amount);
    }

    /**
     * @dev Allows a staked validator to review and vote on an attestation.
     *      Validators are rewarded or slashed based on the final consensus.
     * @param _attestationId The ID of the attestation to vote on.
     * @param _isValid True for upvote, false for downvote.
     */
    function validateExpertiseAttestation(uint256 _attestationId, bool _isValid) external onlyRole(VALIDATOR_ROLE) nonReentrant {
        Attestation storage att = attestations[_attestationId];
        require(att.attestationId != 0, "CognitoNexus: Attestation does not exist.");
        require(block.timestamp <= att.timestamp.add(attestationValidationPeriod), "CognitoNexus: Attestation voting period ended.");
        require(att.attester != msg.sender, "CognitoNexus: Cannot validate your own attestation.");
        require(!att.hasVoted[msg.sender], "CognitoNexus: You have already voted on this attestation.");
        require(moduleValidationStakes[att.moduleId][msg.sender] >= minValidationStake, "CognitoNexus: Not staked sufficiently for this module.");

        att.hasVoted[msg.sender] = true;
        if (_isValid) {
            att.upvotes = att.upvotes.add(1);
        } else {
            att.downvotes = att.downvotes.add(1);
        }

        emit AttestationValidated(_attestationId, msg.sender, _isValid, att.upvotes, att.downvotes);
    }

    /**
     * @dev Finalizes an attestation's validation and applies rewards/slashes.
     *      Can be called by anyone after the validation period ends.
     *      Increases/decreases attestationScore of the Expertise Module.
     * @param _attestationId The ID of the attestation to finalize.
     */
    function finalizeAttestationValidation(uint256 _attestationId) external nonReentrant {
        Attestation storage att = attestations[_attestationId];
        require(att.attestationId != 0, "CognitoNexus: Attestation does not exist.");
        require(block.timestamp > att.timestamp.add(attestationValidationPeriod), "CognitoNexus: Attestation voting period not ended yet.");
        require(!att.isFinalized, "CognitoNexus: Attestation already finalized.");

        att.isFinalized = true;
        ExpertiseModule storage module = expertiseModules[att.moduleId];

        if (att.upvotes > att.downvotes) {
            att.isValidated = true;
            module.attestationScore = module.attestationScore.add(att.upvotes.sub(att.downvotes)); // Net score increase
            // Distribute rewards to upvoters
            // (Simplified: In a real system, track individual validator stakes and distribute proportionally)
            // For now, reward based on total upvotes, and slash based on total downvotes for simplicity.
        } else if (att.downvotes > att.upvotes) {
            att.isValidated = false;
            module.attestationScore = module.attestationScore.sub(att.downvotes.sub(att.upvotes)); // Net score decrease
            // Distribute slashes to downvoters
        } else {
            // Tie, no change, or very minimal.
        }

        // Update lastProficiencyUpdate if score increased, signaling 'freshness'
        if (module.attestationScore > 0) {
            module.lastProficiencyUpdate = block.timestamp;
        }

        emit AttestationValidated(_attestationId, address(0), att.isValidated, att.upvotes, att.downvotes); // Emit with address(0) as sender for finalization
    }

    /**
     * @dev Allows validators to claim their accumulated rewards.
     *      (Simplified: In a real system, rewards would be calculated based on individual successful votes).
     */
    function claimValidationRewards() external nonReentrant {
        // This function would need a more complex tracking mechanism for individual validator rewards.
        // For simplicity, let's assume a pre-calculated reward system that can be claimed.
        // A more advanced approach would involve a reward pool and distribution logic based on contributions.
        revert("CognitoNexus: Reward claim logic not fully implemented in this example.");
    }

    /**
     * @dev Allows a contributor to delegate their validation stake and voting power to another address.
     * @param _delegatee The address to delegate power to.
     * @param _amount The amount of stake to delegate.
     */
    function delegateValidationPower(address _delegatee, uint256 _amount) external nonReentrant {
        require(totalValidationStakes[msg.sender] >= _amount, "CognitoNexus: Insufficient total stake to delegate.");
        require(_delegatee != address(0), "CognitoNexus: Cannot delegate to zero address.");
        require(_delegatee != msg.sender, "CognitoNexus: Cannot delegate to self.");

        // This would require a more complex system to track delegated stakes per module.
        // For this example, let's simplify by moving the total stake.
        // In a full implementation, you'd transfer specific module stakes.
        uint256 remainingStake = totalValidationStakes[msg.sender].sub(_amount);
        totalValidationStakes[msg.sender] = remainingStake;
        totalValidationStakes[_delegatee] = totalValidationStakes[_delegatee].add(_amount);

        // Revoke VALIDATOR_ROLE if total stake becomes zero for delegator
        if (remainingStake == 0 && hasRole(VALIDATOR_ROLE, msg.sender)) {
            _revokeRole(VALIDATOR_ROLE, msg.sender);
        }
        // Grant VALIDATOR_ROLE if delegatee is new or stake was zero
        if (!hasRole(VALIDATOR_ROLE, _delegatee)) {
            _grantRole(VALIDATOR_ROLE, _delegatee);
        }

        emit ValidationPowerDelegated(msg.sender, _delegatee, _amount);
    }

    // --- IV. Protocol Utility & Access ---

    /**
     * @dev Checks if a given address holds a specific Expertise Module above a minimum proficiency.
     *      Useful for external contracts or DApps to verify user capabilities.
     * @param _user The address to check.
     * @param _requiredModuleId The ID of the required Expertise Module.
     * @param _minProficiency The minimum proficiency level required.
     * @return True if the user has access, false otherwise.
     */
    function checkSkillGate(address _user, uint256 _requiredModuleId, uint256 _minProficiency)
        public
        view
        moduleExists(_requiredModuleId)
        returns (bool)
    {
        if (ownerOf(_requiredModuleId) != _user) {
            return false;
        }
        bool hasAccess = getCurrentProficiency(_requiredModuleId) >= _minProficiency;
        emit SkillGateChecked(_user, _requiredModuleId, _minProficiency, hasAccess);
        return hasAccess;
    }

    /**
     * @dev An internal/external function allowing the protocol itself to grant special permissions
     *      or access based on held modules. Can be integrated into other functions.
     * @param _user The address to grant access to.
     * @param _requiredModuleId The ID of the required Expertise Module.
     * @param _minProficiency The minimum proficiency level required.
     */
    function grantAccessByProficiency(address _user, uint256 _requiredModuleId, uint256 _minProficiency)
        internal
        view
        returns (bool)
    {
        return checkSkillGate(_user, _requiredModuleId, _minProficiency);
    }

    /**
     * @dev Returns a list of addresses that hold a specific Expertise Module
     *      with a proficiency level above a given threshold.
     *      (Note: This function might be gas-intensive for large numbers of modules/holders.
     *      A more scalable solution would involve off-chain indexing or subgraph.)
     * @param _moduleId The ID of the Expertise Module.
     * @param _minProficiency The minimum proficiency level to filter by.
     * @return An array of addresses holding the module.
     */
    function queryActiveModuleHolders(uint256 _moduleId, uint256 _minProficiency)
        external
        view
        moduleExists(_moduleId)
        returns (address[] memory)
    {
        // This is a placeholder. Iterating through all module IDs to find owners
        // with specific proficiency is not scalable on-chain.
        // Real-world implementation would require off-chain indexing (e.g., The Graph).
        revert("CognitoNexus: On-chain query for active holders is not scalable. Use off-chain indexing.");
        // A theoretical (gas-expensive) implementation might look like this:
        // address[] memory holders;
        // uint256 count = 0;
        // for (uint256 i = 1; i <= _moduleIdCounter.current(); i++) {
        //     if (_exists(i) && expertiseModules[i].id == _moduleId && getCurrentProficiency(i) >= _minProficiency) {
        //         // This logic is incorrect as a single module ID might be held by only one person (ERC721).
        //         // Instead, you'd check for a *type* of module, not a specific ID.
        //         // For this to work, ModuleType mapping would be needed.
        //     }
        // }
        // return holders;
    }

    /**
     * @dev Whitelists an external oracle contract address.
     *      Only callable by ADMIN_ROLE. Oracles can influence module properties like decay rates
     *      or trigger specific events based on real-world data.
     * @param _oracleAddress The address of the oracle contract.
     */
    function registerExternalOracle(address _oracleAddress) external onlyRole(ADMIN_ROLE) {
        require(_oracleAddress != address(0), "CognitoNexus: Invalid oracle address.");
        _grantRole(ORACLE_FEED_ROLE, _oracleAddress);
    }

    /**
     * @dev Allows an authorized oracle to update a module's relevance based on external data.
     *      For example, a module about "AI development" might gain/lose proficiency
     *      based on real-world AI industry trends.
     * @param _moduleId The ID of the module to update.
     * @param _relevanceChange The amount to adjust the proficiency by (positive or negative).
     */
    function updateModuleRelevanceByOracle(uint256 _moduleId, int256 _relevanceChange)
        external
        onlyRole(ORACLE_FEED_ROLE)
        moduleExists(_moduleId)
    {
        ExpertiseModule storage module = expertiseModules[_moduleId];
        uint256 currentProficiency = getCurrentProficiency(_moduleId);
        uint256 newProficiency;

        if (_relevanceChange > 0) {
            newProficiency = currentProficiency.add(uint256(_relevanceChange));
        } else {
            newProficiency = currentProficiency.sub(uint256(-_relevanceChange));
        }

        // Ensure proficiency doesn't exceed 10000 (100%) or go below 0
        newProficiency = newProficiency > 10000 ? 10000 : newProficiency;
        newProficiency = newProficiency < 0 ? 0 : newProficiency;

        module.baseProficiency = newProficiency; // Directly set base proficiency, lastProficiencyUpdate will be block.timestamp
        module.lastProficiencyUpdate = block.timestamp;

        emit ModuleProficiencyUpdated(_moduleId, currentProficiency, newProficiency);
    }

    // --- V. Governance & System Maintenance ---

    /**
     * @dev Allows governance to adjust the fee for minting new base Expertise Modules.
     * @param _newFee The new fee amount (in ETH/WETH).
     */
    function updateModuleCreationFee(uint256 _newFee) external onlyRole(GOVERNANCE_ROLE) {
        moduleCreationFee = _newFee;
        emit ProtocolParameterUpdated(keccak256("moduleCreationFee"), _newFee);
    }

    /**
     * @dev Allows governance to adjust the minimum stake required for validation.
     * @param _newStakeAmount The new minimum stake amount.
     */
    function setValidationStakeAmount(uint256 _newStakeAmount) external onlyRole(GOVERNANCE_ROLE) {
        minValidationStake = _newStakeAmount;
        emit ProtocolParameterUpdated(keccak256("minValidationStake"), _newStakeAmount);
    }

    /**
     * @dev Allows governance to pause or resume the minting of new base modules.
     * @param _canMint True to enable minting, false to disable.
     */
    function toggleModuleMinting(bool _canMint) external onlyRole(GOVERNANCE_ROLE) {
        if (_canMint) {
            _grantRole(MODULE_ISSUER_ROLE, address(this)); // Re-enable contract-wide minting
        } else {
            _revokeRole(MODULE_ISSUER_ROLE, address(this)); // Disable contract-wide minting
        }
        emit ProtocolParameterUpdated(keccak256("toggleModuleMinting"), _canMint ? 1 : 0);
    }

    /**
     * @dev Allows the feeRecipient to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees() external nonReentrant {
        require(msg.sender == feeRecipient, "CognitoNexus: Only fee recipient can withdraw.");
        uint256 balance = address(this).balance;
        require(balance > 0, "CognitoNexus: No fees to withdraw.");
        (bool success, ) = payable(feeRecipient).call{value: balance}("");
        require(success, "CognitoNexus: Fee withdrawal failed.");
        emit FeesWithdrawn(feeRecipient, balance);
    }

    /**
     * @dev Proposes a change to a core protocol parameter, subject to governance voting.
     *      Only callable by GOVERNANCE_ROLE.
     * @param _paramHash Hashed identifier of the parameter (e.g., keccak256("LEVELUP_PROFICIENCY_BOOST")).
     * @param _newValue The new value for the parameter.
     */
    function proposeProtocolParameterChange(bytes32 _paramHash, uint256 _newValue) external onlyRole(GOVERNANCE_ROLE) {
        _proposalIdCounter.increment();
        bytes32 newProposalId = keccak256(abi.encodePacked(_proposalIdCounter.current(), block.timestamp, msg.sender));

        proposals[newProposalId] = Proposal({
            proposalId: newProposalId,
            paramHash: _paramHash,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp.add(proposalVotingPeriod),
            upvotes: 0,
            downvotes: 0,
            executed: false,
            exists: true
        });

        emit ProposalCreated(newProposalId, _paramHash, _newValue, block.timestamp.add(proposalVotingPeriod));
    }

    /**
     * @dev Allows contributors with sufficient governance power (e.g., totalValidationStakes)
     *      to vote on open proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "yes", false for "no".
     */
    function voteOnProposal(bytes32 _proposalId, bool _support) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.exists, "CognitoNexus: Proposal does not exist.");
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "CognitoNexus: Proposal voting not active.");
        require(!proposal.executed, "CognitoNexus: Proposal already executed.");
        require(!proposal.hasVoted[msg.sender], "CognitoNexus: You have already voted on this proposal.");
        require(totalValidationStakes[msg.sender] > 0, "CognitoNexus: Insufficient governance power to vote."); // Simple power check

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.upvotes = proposal.upvotes.add(totalValidationStakes[msg.sender]);
        } else {
            proposal.downvotes = proposal.downvotes.add(totalValidationStakes[msg.sender]);
        }

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a finalized proposal if it passes. Callable by anyone after voting period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(bytes32 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.exists, "CognitoNexus: Proposal does not exist.");
        require(block.timestamp > proposal.endTime, "CognitoNexus: Proposal voting period not ended.");
        require(!proposal.executed, "CognitoNexus: Proposal already executed.");

        proposal.executed = true; // Mark as executed regardless of outcome

        bool successful = proposal.upvotes > proposal.downvotes;

        if (successful) {
            protocolParameters[proposal.paramHash] = proposal.newValue;
        }

        emit ProposalExecuted(_proposalId, successful);
    }

    // --- Internal Helpers ---
    /**
     * @dev Simple bubble sort for uint256 arrays.
     *      Used for consistent hashing of merge recipe inputs.
     *      Avoid for very large arrays due to gas costs.
     */
    function _sortArray(uint256[] memory arr) internal pure {
        uint256 n = arr.length;
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (arr[j] > arr[j + 1]) {
                    uint256 temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
        }
    }

    // --- Admin & Fallback (Basic) ---

    receive() external payable {}

    fallback() external payable {}
}
```