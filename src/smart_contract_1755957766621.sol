Here's an advanced, creative, and trendy smart contract concept in Solidity, designed to avoid direct duplication of existing open-source projects. This contract, named "EvolveVerse", introduces dynamic NFTs that evolve based on user interaction, an off-chain AI (simulated via an oracle), and community governance. It also features a unique mechanism for external contracts to influence NFT traits, promoting composability across different dApps.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint256 to string conversion

/*
*   EvolveVerse: Dynamic NFT Ecosystem with AI-Driven Evolution & Community Governance
*
*   This contract creates a dynamic NFT ecosystem where unique digital entities (EvolveVerse Entities)
*   can evolve, gain traits, and interact with the environment. Key features include:
*   -   **Dynamic NFTs:** Entities possess mutable traits that change over time, through user actions,
*       or external (oracle-fed) influences.
*   -   **AI-Driven Evolution (simulated):** An external "Trusted Oracle" can submit environmental
*       stimuli or trigger global events, simulating the impact of an off-chain AI on the ecosystem.
*   -   **Community Governance (DAO):** Holders of the native EVO_GOV token can propose and vote on
*       system parameter changes, guiding the evolution of the entire EvolveVerse.
*   -   **Composability & External Interaction:** A novel mechanism allows the DAO to whitelist
*       external smart contracts that can directly influence specific traits of EvolveVerse Entities,
*       making these NFTs more versatile and integrable into other dApps (e.g., games, metaverses).
*
*   Outline:
*   I. Core Entity Management (ERC721-like & Novel)
*   II. Trait & Evolution Mechanics
*   III. Catalyst & Fuel Token Management
*   IV. Oracle & AI Integration
*   V. Governance (DAO) Mechanics
*   VI. Cross-Contract & External Interaction
*
*   Function Summary:
*   I. Core Entity Management:
*      1.  `mintGenesisEntity(uint256 dnaSeed)`: Mints the very first entities in the ecosystem. Restricted to contract owner initially, then potentially DAO-controlled.
*      2.  `breedEntities(uint256 parent1Id, uint256 parent2Id, uint256 dnaSeed)`: Allows two entities owned by the caller to breed, creating a new entity, consuming EVO_FUEL. Incorporates a generation gap check.
*      3.  `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 transfer function.
*      4.  `approve(address to, uint256 tokenId)`: Standard ERC721 approval function for single tokens.
*      5.  `setApprovalForAll(address operator, bool approved)`: Standard ERC721 function to approve or revoke an operator for all tokens.
*      6.  `burnEntity(uint256 tokenId)`: Allows the owner of an entity to permanently destroy it.
*
*   II. Trait & Evolution Mechanics:
*      7.  `nurtureEntity(uint256 tokenId, bytes32 traitNameHash, uint256 nurtureAmount)`: Allows entity owners to invest EVO_FUEL to boost specific traits, influencing growth.
*      8.  `applyCatalyst(uint256 tokenId, uint256 catalystTypeId, uint256 amount)`: Consumes a specific catalyst token to apply a powerful, defined effect (e.g., a rapid trait boost or evolution trigger) on an entity.
*      9.  `getTraitValue(uint256 tokenId, bytes32 traitNameHash)`: Retrieves the current numerical value of a specified trait for an entity.
*      10. `getEvolutionStage(uint256 tokenId)`: Returns the current evolution stage (e.g., Larva, Chrysalis, Apex) of an entity.
*      11. `queryEvolutionReadiness(uint256 tokenId)`: Checks and returns whether an entity meets the defined criteria (e.g., total trait sum) to advance to its next evolution stage.
*      12. `forceEvolveEntity(uint256 tokenId)`: Allows the Trusted Oracle to trigger an evolution for an entity if it meets readiness criteria or other specific conditions dictated by the off-chain AI.
*
*   III. Catalyst & Fuel Token Management:
*      13. `mintEvoFuel(address to, uint256 amount)`: Mints new EVO_FUEL tokens to a specified address. Callable by DAO or authorized minters (initially owner).
*      14. `mintCatalystToken(uint256 catalystTypeId, address to, uint256 amount)`: Mints new catalyst tokens of a specific type to an address. Callable by DAO or authorized minters (initially owner).
*      15. `registerNewCatalystType(bytes32 catalystNameHash, string calldata metadataURI, bytes32 influencedTrait, int256 baseInfluence)`: A DAO-governed function to define a new type of catalyst, its properties, and its primary effects on entities.
*
*   IV. Oracle & AI Integration:
*      16. `submitEnvironmentalStimulus(uint256 tokenId, bytes32 traitNameHash, int256 stimulusEffect)`: The Trusted Oracle reports an external, AI-driven influence (positive or negative) on a specific entity's trait.
*      17. `triggerGlobalEvent(bytes32 eventNameHash, uint256 eventValue)`: The Trusted Oracle can trigger a global event (e.g., "Solar Flare" boosts Fire traits) that influences all or a subset of entities.
*      18. `updateTrustedOracle(address newOracle)`: A DAO-governed function to update the address of the trusted oracle, ensuring decentralized control over the AI's influence.
*
*   V. Governance (DAO) Mechanics:
*      19. `proposeSystemParameterChange(bytes32 parameterNameHash, uint256 newValue)`: Allows users with staked EVO_GOV tokens to create proposals to change key system parameters (e.g., breeding cost, nurture efficiency, evolution thresholds).
*      20. `voteOnProposal(uint256 proposalId, bool support)`: Allows staked EVO_GOV holders to cast a vote (for or against) on an active proposal.
*      21. `executeProposal(uint256 proposalId)`: Executes a proposal that has successfully met its voting quorum and passed, applying the proposed changes to the contract's state.
*      22. `stakeGovernanceToken(uint256 amount)`: Users can stake their liquid EVO_GOV tokens to gain voting power within the DAO.
*      23. `unstakeGovernanceToken(uint256 amount)`: Users can unstake their EVO_GOV tokens, returning them to their liquid balance and removing their voting power.
*      24. `delegateVote(address delegatee)`: Allows a user to delegate their voting power to another address, enabling more active participation or expert representation.
*
*   VI. Cross-Contract & External Interaction:
*      25. `registerExternalTraitProvider(bytes32 traitNameHash, address providerContract)`: A DAO-governed function to authorize an external contract as a legitimate source for influencing a specific trait. This is crucial for composability, allowing other dApps (e.g., a game) to directly interact with and update EvolveVerse NFT traits.
*      26. `syncExternalTrait(uint256 tokenId, bytes32 traitNameHash)`: Allows an entity owner to pull and update a specific trait value from a registered external provider contract, reflecting real-time changes from integrated dApps.
*/

contract EvolveVerse is Ownable, IERC721, IERC721Metadata, IERC721Receiver {
    using Counters for Counters.Counter;

    // --- Events ---
    event EntityMinted(uint256 indexed tokenId, address indexed owner, uint256 dnaSeed, uint256 parent1Id, uint256 parent2Id);
    event EntityNurtured(uint256 indexed tokenId, address indexed nurturer, bytes32 indexed traitNameHash, uint256 amount);
    event EntityEvolutionStageChanged(uint256 indexed tokenId, uint8 newStage);
    event CatalystApplied(uint256 indexed tokenId, uint256 indexed catalystTypeId, uint256 amount);
    event EnvironmentalStimulusApplied(uint256 indexed tokenId, bytes32 indexed traitNameHash, int256 effect);
    event GlobalEventTriggered(bytes32 indexed eventNameHash, uint256 eventValue);
    event OracleUpdated(address indexed oldOracle, address indexed newOracle);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 indexed parameterNameHash, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ExternalTraitProviderRegistered(bytes32 indexed traitNameHash, address indexed providerContract);
    event ExternalTraitSynced(uint256 indexed tokenId, bytes32 indexed traitNameHash, int256 newValue);
    event CatalystTypeRegistered(uint256 indexed catalystTypeId, bytes32 indexed nameHash, bytes32 influencedTrait);

    // --- State Variables ---

    // --- ERC721 Core ---
    string private _name;
    string private _symbol;
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => address) private _owners; // tokenId => owner address
    mapping(address => uint256) private _balances; // owner address => count of tokens
    mapping(uint256 => address) private _tokenApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // --- Entity Data ---
    struct Entity {
        uint256 id;
        address owner; // Redundant with _owners mapping but convenient for struct access
        uint8 evolutionStage; // 0: Larva, 1: Chrysalis, 2: Apex, etc.
        uint256 lastNurtureTime;
        uint256 parent1Id;
        uint256 parent2Id;
        mapping(bytes32 => int256) traits; // Dynamic traits by hash (e.g., keccak256("Strength"))
        string tokenURI; // Metadata URI for the entity
    }
    mapping(uint256 => Entity) public entities; // All entities by tokenId

    // --- Catalyst Definitions ---
    Counters.Counter private _catalystTypeCounter;
    struct CatalystType {
        bytes32 nameHash;
        string metadataURI;
        bytes32 influencedTrait; // Trait this catalyst primarily affects
        int256 baseInfluence;    // Base value added to trait when applied
        uint256 costMultiplier;  // How much more effective it is. (Future use, for now set to 1)
    }
    mapping(uint256 => CatalystType) public catalystTypes; // Catalyst types by ID
    mapping(uint256 => mapping(address => uint256)) public catalystBalances; // catalystTypeId => owner => balance

    // --- Internal Tokens (Simplified ERC20-like within this contract for demo) ---
    // EvoFuel: Used for nurturing, breeding.
    string public constant EVO_FUEL_NAME = "EvolveFuel";
    string public constant EVO_FUEL_SYMBOL = "EVOFUEL";
    mapping(address => uint256) public evoFuelBalances;
    uint256 public totalEvoFuelSupply;

    // EvoGov: Governance token for DAO.
    string public constant EVO_GOV_NAME = "EvolveGov";
    string public constant EVO_GOV_SYMBOL = "EVOGOV";
    mapping(address => uint256) public evoGovBalances;
    uint256 public totalEvoGovSupply;

    // --- Oracle & AI Integration ---
    address public trustedOracle;

    // --- Governance (DAO) ---
    struct Proposal {
        address proposer;
        bytes32 parameterNameHash; // Key for the systemParameter or special action hash (e.g., keccak256("UpdateTrustedOracle"))
        uint256 newValue;          // New value for the parameter or address for special actions (e.g., new oracle address)
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
        mapping(address => bool) hasVoted; // Voter => hasVoted (only checks direct voter)
    }
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals; // proposalId is uint256
    uint256 public constant MIN_VOTING_DELAY_BLOCKS = 10; // Minimum blocks a proposal must exist before voting starts
    uint256 public constant VOTING_PERIOD_BLOCKS = 100; // Duration of the voting period in blocks
    uint256 public constant PROPOSAL_THRESHOLD_GOV = 1000 * 10**18; // Amount of EVO_GOV needed to create a proposal
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4% of total EVO_GOV supply must vote 'for' for a proposal to pass

    mapping(address => uint256) public stakedGovTokens; // Tracks actual voting power (direct or delegated to msg.sender)
    mapping(address => address) public votingDelegates; // delegator => delegatee

    // --- System Parameters (DAO-governed) ---
    mapping(bytes32 => uint256) public systemParameters;
    bytes32 constant public PARAM_BREEDING_COST_FUEL = keccak256("BreedingCostFuel");
    bytes32 constant public PARAM_NURTURE_COST_FUEL_PER_POINT = keccak256("NurtureCostFuelPerPoint");
    bytes32 constant public PARAM_MIN_EVOLUTION_THRESHOLD_SUM = keccak256("MinEvolutionThresholdSum");
    bytes32 constant public PARAM_MAX_GENERATION_GAP = keccak256("MaxGenerationGap"); // For breeding compatibility

    // --- External Trait Providers ---
    mapping(bytes32 => address) public externalTraitProviders; // traitNameHash => contractAddress
    // `syncExternalTrait` assumes `providerContract` implements a getter function like `getTraitValue(uint256 tokenId)` returning an `int256`.

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "EvolveVerse: Not the trusted oracle");
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_, address initialOracle) Ownable(msg.sender) {
        _name = name_;
        _symbol = symbol_;
        trustedOracle = initialOracle;

        // Initialize system parameters with default values
        systemParameters[PARAM_BREEDING_COST_FUEL] = 500 * 10**18; // 500 EVO_FUEL
        systemParameters[PARAM_NURTURE_COST_FUEL_PER_POINT] = 1 * 10**18; // 1 EVO_FUEL per trait point
        systemParameters[PARAM_MIN_EVOLUTION_THRESHOLD_SUM] = 1000; // Sum of trait values to evolve
        systemParameters[PARAM_MAX_GENERATION_GAP] = 2; // Max generation difference for breeding

        // Mint initial EVO_GOV for deployer for DAO operations
        _mintEvoGov(msg.sender, 1_000_000 * 10**18); // 1 Million EVO_GOV
        _stakeGovTokens(msg.sender, 1_000_000 * 10**18); // Auto-stake deployer's tokens

        emit OracleUpdated(address(0), initialOracle);
    }

    // --- ERC721 Core Implementations ---

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function balanceOf(address owner_) public view override returns (uint256) {
        require(owner_ != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "ERC721: owner query for nonexistent token");
        return owner_;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId);
        require(to != owner_, "ERC721: approval to current owner");
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner_, address operator) public view override returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = ownerOf(tokenId);
        return (spender == owner_ || getApproved(tokenId) == spender || isApprovedForAll(owner_, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        _tokenApprovals[tokenId] = address(0); // Clear approvals
        entities[tokenId].owner = to; // Update owner in Entity struct

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId, uint256 parent1Id, uint256 parent2Id, uint256 dnaSeed) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to]++;
        _owners[tokenId] = to;

        entities[tokenId] = Entity({
            id: tokenId,
            owner: to,
            evolutionStage: 0, // Initial stage
            lastNurtureTime: block.timestamp,
            parent1Id: parent1Id,
            parent2Id: parent2Id,
            tokenURI: "" // To be set later or dynamically
        });

        // Initialize dynamic traits mapping for the new entity
        _initializeTraits(tokenId, dnaSeed);

        emit EntityMinted(tokenId, to, dnaSeed, parent1Id, parent2Id);
    }

    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf(tokenId);

        _tokenApprovals[tokenId] = address(0); // Clear approvals
        _balances[owner_]--;
        delete _owners[tokenId];
        delete entities[tokenId]; // Delete the entity struct

        emit Transfer(owner_, address(0), tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) { // Check if 'to' is a contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (unknown reason)");
                } else {
                    /// @solidity using `Error(string)` for the custom error string
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true; // EOA can always receive
        }
    }

    // --- IERC721Metadata ---
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return entities[tokenId].tokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set for nonexistent token");
        entities[tokenId].tokenURI = uri;
    }

    // --- I. Core Entity Management ---

    function mintGenesisEntity(uint256 dnaSeed) public onlyOwner returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _mint(msg.sender, tokenId, 0, 0, dnaSeed); // Genesis entities have no parents
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://genesis/", Strings.toString(tokenId), ".json"))); // Example URI
        return tokenId;
    }

    function breedEntities(uint256 parent1Id, uint256 parent2Id, uint256 dnaSeed) public returns (uint256 tokenId) {
        require(_exists(parent1Id) && _exists(parent2Id), "EvolveVerse: Parents do not exist");
        require(ownerOf(parent1Id) == msg.sender && ownerOf(parent2Id) == msg.sender, "EvolveVerse: Caller must own both parents");
        require(entities[parent1Id].evolutionStage > 0 && entities[parent2Id].evolutionStage > 0, "EvolveVerse: Parents must be past larval stage to breed");

        // Breeding cost
        uint256 breedingCost = systemParameters[PARAM_BREEDING_COST_FUEL];
        require(evoFuelBalances[msg.sender] >= breedingCost, "EvolveVerse: Not enough EVO_FUEL for breeding");
        _burnEvoFuel(msg.sender, breedingCost);

        // Check generation gap (simplified proxy for generation)
        uint8 stage1 = entities[parent1Id].evolutionStage;
        uint8 stage2 = entities[parent2Id].evolutionStage;
        uint256 maxGenGap = systemParameters[PARAM_MAX_GENERATION_GAP];
        require(stage1 >= stage2 ? (stage1 - stage2 <= maxGenGap) : (stage2 - stage1 <= maxGenGap), "EvolveVerse: Parents have too wide a generation gap");

        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _mint(msg.sender, tokenId, parent1Id, parent2Id, dnaSeed);
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://child/", Strings.toString(tokenId), ".json")));

        // Child inherits some traits from parents, influenced by DNA seed
        _inheritTraits(tokenId, parent1Id, parent2Id, dnaSeed);

        return tokenId;
    }

    function burnEntity(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "EvolveVerse: Caller is not the owner of the entity");
        _burn(tokenId);
    }

    // --- II. Trait & Evolution Mechanics ---

    function _initializeTraits(uint256 tokenId, uint256 dnaSeed) internal {
        // Simple trait initialization based on DNA seed for demo purposes.
        // In a real system, this could involve more complex hashing or pseudo-randomness.
        Entity storage entity_ = entities[tokenId];
        entity_.traits[keccak256("Strength")] = int256(dnaSeed % 100) + 10;
        entity_.traits[keccak256("Intelligence")] = int256((dnaSeed / 100) % 100) + 10;
        entity_.traits[keccak256("Agility")] = int256((dnaSeed / 10000) % 100) + 10;
        entity_.traits[keccak256("Resilience")] = int256((dnaSeed / 1000000) % 100) + 10;
        entity_.traits[keccak256("Charm")] = int256((dnaSeed / 100000000) % 100) + 10;
    }

    function _inheritTraits(uint256 childId, uint256 parent1Id, uint256 parent2Id, uint256 dnaSeed) internal {
        Entity storage child = entities[childId];
        Entity storage p1 = entities[parent1Id];
        Entity storage p2 = entities[parent2Id];

        bytes32[] memory allTraitHashes = new bytes32[](5); // Define traits to inherit
        allTraitHashes[0] = keccak256("Strength");
        allTraitHashes[1] = keccak256("Intelligence");
        allTraitHashes[2] = keccak256("Agility");
        allTraitHashes[3] = keccak256("Resilience");
        allTraitHashes[4] = keccak256("Charm");

        for (uint256 i = 0; i < allTraitHashes.length; i++) {
            bytes32 trait = allTraitHashes[i];
            // Simple averaging, with a slight deviation based on dnaSeed
            int256 avgTrait = (p1.traits[trait] + p2.traits[trait]) / 2;
            int256 deviation = int256(dnaSeed % 11) - 5; // -5 to +5 deviation
            child.traits[trait] = avgTrait + deviation;
            // Ensure trait values don't go below minimum (e.g., 1)
            if (child.traits[trait] < 1) {
                child.traits[trait] = 1;
            }
        }
    }


    function nurtureEntity(uint256 tokenId, bytes32 traitNameHash, uint256 nurtureAmount) public {
        require(ownerOf(tokenId) == msg.sender, "EvolveVerse: Caller is not the owner of the entity");
        require(entities[tokenId].evolutionStage < 255, "EvolveVerse: Entity has reached max evolution stage."); // Assuming 255 is max stages

        uint256 cost = nurtureAmount * systemParameters[PARAM_NURTURE_COST_FUEL_PER_POINT];
        require(evoFuelBalances[msg.sender] >= cost, "EvolveVerse: Not enough EVO_FUEL to nurture");

        _burnEvoFuel(msg.sender, cost);
        entities[tokenId].traits[traitNameHash] += int256(nurtureAmount);
        entities[tokenId].lastNurtureTime = block.timestamp;

        emit EntityNurtured(tokenId, msg.sender, traitNameHash, nurtureAmount);
    }

    function applyCatalyst(uint256 tokenId, uint256 catalystTypeId, uint256 amount) public {
        require(ownerOf(tokenId) == msg.sender, "EvolveVerse: Caller is not the owner of the entity");
        require(_existsCatalystType(catalystTypeId), "EvolveVerse: Invalid catalyst type");
        require(catalystBalances[catalystTypeId][msg.sender] >= amount, "EvolveVerse: Not enough catalyst tokens");

        _burnCatalystToken(catalystTypeId, msg.sender, amount);

        CatalystType storage catType = catalystTypes[catalystTypeId];
        // Apply effect of catalyst to the influenced trait
        entities[tokenId].traits[catType.influencedTrait] += catType.baseInfluence * int256(amount);

        emit CatalystApplied(tokenId, catalystTypeId, amount);
    }

    function getTraitValue(uint256 tokenId, bytes32 traitNameHash) public view returns (int256) {
        require(_exists(tokenId), "EvolveVerse: Entity does not exist");
        return entities[tokenId].traits[traitNameHash];
    }

    function getEvolutionStage(uint256 tokenId) public view returns (uint8) {
        require(_exists(tokenId), "EvolveVerse: Entity does not exist");
        return entities[tokenId].evolutionStage;
    }

    function queryEvolutionReadiness(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "EvolveVerse: Entity does not exist");

        // Example condition: Sum of all major traits must exceed a threshold
        int256 totalTraitSum = entities[tokenId].traits[keccak256("Strength")]
                              + entities[tokenId].traits[keccak256("Intelligence")]
                              + entities[tokenId].traits[keccak256("Agility")]
                              + entities[tokenId].traits[keccak256("Resilience")]
                              + entities[tokenId].traits[keccak256("Charm")];

        // Entity can only evolve if its current stage is less than a certain limit (e.g., max stage 2)
        // and its total traits sum meets the minimum threshold.
        return totalTraitSum >= int256(systemParameters[PARAM_MIN_EVOLUTION_THRESHOLD_SUM])
               && entities[tokenId].evolutionStage < 2;
    }

    function forceEvolveEntity(uint256 tokenId) public onlyOracle {
        require(_exists(tokenId), "EvolveVerse: Entity does not exist");
        require(queryEvolutionReadiness(tokenId), "EvolveVerse: Entity not ready for evolution or external conditions not met");

        entities[tokenId].evolutionStage++;
        // Additional logic could be added here, e.g., reset certain traits, gain new abilities.

        emit EntityEvolutionStageChanged(tokenId, entities[tokenId].evolutionStage);
    }

    // --- III. Catalyst & Fuel Token Management ---

    // Internal mint for EvoFuel
    function _mintEvoFuel(address to, uint256 amount) internal {
        evoFuelBalances[to] += amount;
        totalEvoFuelSupply += amount;
    }

    // Internal burn for EvoFuel
    function _burnEvoFuel(address from, uint256 amount) internal {
        require(evoFuelBalances[from] >= amount, "EvolveVerse: Not enough EVO_FUEL");
        evoFuelBalances[from] -= amount;
        totalEvoFuelSupply -= amount;
    }

    // Public callable mint for EvoFuel (initially owner, then via DAO proposal)
    function mintEvoFuel(address to, uint256 amount) public {
        require(msg.sender == owner(), "EvolveVerse: Not authorized to mint EVO_FUEL (needs DAO proposal)");
        _mintEvoFuel(to, amount);
    }

    function _existsCatalystType(uint256 catalystTypeId) internal view returns (bool) {
        return catalystTypes[catalystTypeId].nameHash != 0;
    }

    // Internal mint for Catalyst tokens
    function _mintCatalystToken(uint256 catalystTypeId, address to, uint256 amount) internal {
        require(_existsCatalystType(catalystTypeId), "EvolveVerse: Invalid catalyst type for minting");
        catalystBalances[catalystTypeId][to] += amount;
    }

    // Internal burn for Catalyst tokens
    function _burnCatalystToken(uint256 catalystTypeId, address from, uint256 amount) internal {
        require(catalystBalances[catalystTypeId][from] >= amount, "EvolveVerse: Not enough catalyst tokens");
        catalystBalances[catalystTypeId][from] -= amount;
    }

    // Public callable mint for Catalyst tokens (initially owner, then via DAO proposal)
    function mintCatalystToken(uint256 catalystTypeId, address to, uint256 amount) public {
        require(msg.sender == owner(), "EvolveVerse: Not authorized to mint Catalyst Tokens (needs DAO proposal)");
        _mintCatalystToken(catalystTypeId, to, amount);
    }

    function registerNewCatalystType(
        bytes32 catalystNameHash,
        string calldata metadataURI,
        bytes32 influencedTrait,
        int256 baseInfluence
    ) public {
        // This function must be called as part of a successful DAO proposal execution, not directly by an EOA.
        require(msg.sender == address(this), "EvolveVerse: Callable only via DAO proposal execution");

        _catalystTypeCounter.increment();
        uint256 newTypeId = _catalystTypeCounter.current();
        catalystTypes[newTypeId] = CatalystType({
            nameHash: catalystNameHash,
            metadataURI: metadataURI,
            influencedTrait: influencedTrait,
            baseInfluence: baseInfluence,
            costMultiplier: 1 // Default, can be DAO-governed later if complexity increases
        });
        emit CatalystTypeRegistered(newTypeId, catalystNameHash, influencedTrait);
    }

    // --- IV. Oracle & AI Integration ---

    function submitEnvironmentalStimulus(uint256 tokenId, bytes32 traitNameHash, int256 stimulusEffect) public onlyOracle {
        require(_exists(tokenId), "EvolveVerse: Entity does not exist");
        entities[tokenId].traits[traitNameHash] += stimulusEffect;
        emit EnvironmentalStimulusApplied(tokenId, traitNameHash, stimulusEffect);
    }

    function triggerGlobalEvent(bytes32 eventNameHash, uint256 eventValue) public onlyOracle {
        // This function would typically trigger a system-wide effect (e.g., affecting all entities).
        // For demonstration, we just emit the event. A real implementation would include logic
        // to iterate over entities or update global parameters based on the eventNameHash and eventValue.
        emit GlobalEventTriggered(eventNameHash, eventValue);
    }

    function updateTrustedOracle(address newOracle) public {
        // This function must be called as part of a successful DAO proposal execution.
        require(msg.sender == address(this), "EvolveVerse: Callable only via DAO proposal execution");

        require(newOracle != address(0), "EvolveVerse: New oracle cannot be zero address");
        address oldOracle = trustedOracle;
        trustedOracle = newOracle;
        emit OracleUpdated(oldOracle, newOracle);
    }

    // --- V. Governance (DAO) Mechanics ---

    // Internal mint for EvoGov
    function _mintEvoGov(address to, uint256 amount) internal {
        evoGovBalances[to] += amount;
        totalEvoGovSupply += amount;
    }

    // Internal burn for EvoGov
    function _burnEvoGov(address from, uint256 amount) internal {
        require(evoGovBalances[from] >= amount, "EvolveVerse: Not enough EVO_GOV");
        evoGovBalances[from] -= amount;
        totalEvoGovSupply -= amount;
    }

    function stakeGovernanceToken(uint256 amount) public {
        require(evoGovBalances[msg.sender] >= amount, "EvolveVerse: Not enough EVO_GOV to stake");
        _burnEvoGov(msg.sender, amount); // Move from liquid balance to staked
        _stakeGovTokens(msg.sender, amount);
    }

    function _stakeGovTokens(address staker, uint256 amount) internal {
        stakedGovTokens[staker] += amount;
        address delegatee = votingDelegates[staker];
        if (delegatee == address(0)) { // If no explicit delegation, assume self-delegated
            delegatee = staker;
        }
        if (delegatee != staker) { // If delegated to someone else, update their voting power
             stakedGovTokens[delegatee] += amount;
        }
    }

    function unstakeGovernanceToken(uint256 amount) public {
        require(stakedGovTokens[msg.sender] >= amount, "EvolveVerse: Not enough staked EVO_GOV");
        _unstakeGovTokens(msg.sender, amount);
        _mintEvoGov(msg.sender, amount); // Return to liquid balance
    }

    function _unstakeGovTokens(address staker, uint256 amount) internal {
        stakedGovTokens[staker] -= amount;
        address delegatee = votingDelegates[staker];
        if (delegatee == address(0)) { // If no explicit delegation, assume self-delegated
            delegatee = staker;
        }
        if (delegatee != staker) { // If delegated to someone else, update their voting power
            stakedGovTokens[delegatee] -= amount;
        }
    }

    function delegateVote(address delegatee) public {
        require(delegatee != address(0), "EvolveVerse: Cannot delegate to zero address");
        require(delegatee != msg.sender, "EvolveVerse: Cannot delegate to self explicitly, happens by default if not delegated");

        uint256 currentStaked = stakedGovTokens[msg.sender];

        // Remove prior delegation's voting power if exists
        address currentDelegatee = votingDelegates[msg.sender];
        if (currentDelegatee != address(0) && currentDelegatee != msg.sender) {
            stakedGovTokens[currentDelegatee] -= currentStaked;
        }

        // Set new delegate
        votingDelegates[msg.sender] = delegatee;

        // Add voting power to new delegate
        stakedGovTokens[delegatee] += currentStaked;
    }

    function getVotes(address account) public view returns (uint256) {
        // Returns the effective voting power of an account (either their own staked or delegated to them)
        // If an account has delegated their votes, their `stakedGovTokens` will be 0.
        // If an account is a delegatee, their `stakedGovTokens` will accumulate votes.
        return stakedGovTokens[account];
    }


    function proposeSystemParameterChange(bytes32 parameterNameHash, uint256 newValue) public returns (uint256 proposalId) {
        require(getVotes(msg.sender) >= PROPOSAL_THRESHOLD_GOV, "EvolveVerse: Not enough staked EVO_GOV to propose");

        _proposalIdCounter.increment();
        proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            parameterNameHash: parameterNameHash,
            newValue: newValue,
            forVotes: 0,
            againstVotes: 0,
            startBlock: block.number,
            endBlock: block.number + VOTING_PERIOD_BLOCKS,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize
        });

        emit ProposalCreated(proposalId, msg.sender, parameterNameHash, newValue);
        return proposalId;
    }

    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "EvolveVerse: Proposal does not exist");
        require(block.number >= proposal.startBlock + MIN_VOTING_DELAY_BLOCKS, "EvolveVerse: Voting not yet started");
        require(block.number <= proposal.endBlock, "EvolveVerse: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "EvolveVerse: Already voted on this proposal");

        uint256 voterVotes = getVotes(msg.sender);
        require(voterVotes > 0, "EvolveVerse: You have no voting power");

        if (support) {
            proposal.forVotes += voterVotes;
        } else {
            proposal.againstVotes += voterVotes;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, voterVotes);
    }

    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "EvolveVerse: Proposal does not exist");
        require(block.number > proposal.endBlock, "EvolveVerse: Voting period not yet ended");
        require(!proposal.executed, "EvolveVerse: Proposal already executed");

        uint256 totalForVotes = proposal.forVotes;
        uint256 totalGovSupply = totalEvoGovSupply; // Quorum is based on total supply, not just staked
        uint256 quorumThreshold = totalGovSupply * QUORUM_PERCENTAGE / 100;

        require(totalForVotes >= quorumThreshold, "EvolveVerse: Proposal did not meet quorum");
        require(proposal.forVotes > proposal.againstVotes, "EvolveVerse: Proposal did not pass (more 'for' votes needed)");

        proposal.executed = true;

        // Execute the change based on parameterNameHash
        if (proposal.parameterNameHash == PARAM_BREEDING_COST_FUEL ||
            proposal.parameterNameHash == PARAM_NURTURE_COST_FUEL_PER_POINT ||
            proposal.parameterNameHash == PARAM_MIN_EVOLUTION_THRESHOLD_SUM ||
            proposal.parameterNameHash == PARAM_MAX_GENERATION_GAP) {
            systemParameters[proposal.parameterNameHash] = proposal.newValue;
        } else if (proposal.parameterNameHash == keccak256("UpdateTrustedOracle")) {
             // For updating oracle, newValue should be the new oracle address (uint160 to address)
            updateTrustedOracle(address(uint160(proposal.newValue)));
        } else if (proposal.parameterNameHash == keccak256("RegisterCatalystType")) {
            // This action is complex and would require multiple parameters (name, URI, influencedTrait, baseInfluence).
            // A simple uint256 is insufficient. In a real DAO, proposals for complex actions might store
            // ABI-encoded calldata or refer to an off-chain IPFS hash containing the parameters.
            revert("EvolveVerse: Catalyst type registration needs complex data, use a custom proposal type");
        } else if (proposal.parameterNameHash == keccak256("RegisterExternalTraitProvider")) {
             // Similar to catalyst registration, this needs two parameters (traitNameHash, providerContract).
             revert("EvolveVerse: External trait provider registration needs complex data, use a custom proposal type");
        }
        // Additional parameter types and actions can be integrated here.

        emit ProposalExecuted(proposalId);
    }

    // --- VI. Cross-Contract & External Interaction ---

    function registerExternalTraitProvider(bytes32 traitNameHash, address providerContract) public {
        // This function must be called as part of a successful DAO proposal execution.
        require(msg.sender == address(this), "EvolveVerse: Callable only via DAO proposal execution");

        require(providerContract != address(0), "EvolveVerse: Provider contract cannot be zero address");
        externalTraitProviders[traitNameHash] = providerContract;
        emit ExternalTraitProviderRegistered(traitNameHash, providerContract);
    }

    // Interface for external trait providers to ensure type safety for `syncExternalTrait`
    interface IExternalTraitProvider {
        function getTraitValue(uint256 tokenId) external view returns (int256);
        // Add other relevant functions if external contract provides more data or has specific interaction methods
    }

    function syncExternalTrait(uint256 tokenId, bytes32 traitNameHash) public {
        require(ownerOf(tokenId) == msg.sender, "EvolveVerse: Caller is not the owner of the entity");
        address providerAddress = externalTraitProviders[traitNameHash];
        require(providerAddress != address(0), "EvolveVerse: No external provider registered for this trait");

        // Call the external contract to get the trait value
        IExternalTraitProvider provider = IExternalTraitProvider(providerAddress);
        int256 externalValue = provider.getTraitValue(tokenId);

        entities[tokenId].traits[traitNameHash] = externalValue;
        emit ExternalTraitSynced(tokenId, traitNameHash, externalValue);
    }

    // --- Fallback & Receive Functions (Best practice for contracts that might receive ETH) ---
    receive() external payable {}
    fallback() external payable {}
}
```