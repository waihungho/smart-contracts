Here's a Solidity smart contract named "Echoes of the Metamind," designed with advanced, creative, and trendy concepts, focusing on dynamic NFTs (Echoes), self-evolving rule sets, and a decentralized governance mechanism. It aims to create a unique, reputation-based digital identity system where digital entities adapt and grow based on on-chain actions and community consensus.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit math safety
// Removed ECDSA for brevity as oracle verification is mocked by a boolean return

// Interface for a dummy oracle
// In a real scenario, this would be a more sophisticated Chainlink or similar oracle contract,
// potentially involving cryptographic proofs or signed data for off-chain verification.
interface IOracle {
    // A simple function to retrieve a value for a key, representing some external data point.
    function getLatestData(bytes32 _key) external view returns (uint256 _value);
    // A function to verify a complex context, e.g., if a user performed a specific action off-chain
    // or met certain criteria, possibly involving signed data and a proof.
    function verifyContext(bytes32 _contextType, bytes calldata _contextData) external view returns (bool);
}

/**
 * @title Echoes of the Metamind
 * @dev A novel smart contract implementing dynamic, non-transferable digital entities called "Echoes."
 *      Echoes are Soulbound Token (SBT)-like NFTs that represent a user's on-chain presence.
 *      They evolve, gain traits, and build "Affinities" based on user actions, verifiable
 *      external data (via an Oracle), and interactions with other Echoes.
 *      The contract introduces a "Metamind" governance system, allowing the community to
 *      propose and enact new "Evolution Rule Sets" – dynamically changing how Echoes evolve.
 *      This creates a self-evolving, reputation-based digital identity system.
 */
contract EchoesOfTheMetamind is ERC721Enumerable, Ownable, Pausable {

    using Strings for uint256;
    using SafeMath for uint256;

    // --- Outline and Function Summary ---
    // The contract orchestrates the lifecycle and evolution of "Echoes," which are dynamic, non-transferable NFTs.
    // It features a decentralized governance mechanism ("Metamind Consensus") to adapt the rules by which Echoes evolve.

    // I. Core Echo Management & Information Retrieval
    //    1. constructor: Initializes the contract with basic ERC721 parameters, oracle address, and base URI.
    //    2. mintEcho: Creates a new, non-transferable Echo for a user, assigning initial traits based on a seed.
    //    3. getEchoDetails: Retrieves comprehensive data for a given Echo (traits, affinities, status, transient boosts).
    //    4. getEchoTraitValue: Fetches the value of a specific trait for an Echo, accounting for active transient boosts.
    //    5. getEchoAffinityValue: Fetches the value of a specific affinity for an Echo.
    //    6. getEchoCount: Returns the total number of Echoes minted.
    //    7. tokenURI: Provides the metadata URI for a specific Echo, dynamically reflecting its current on-chain state.

    // II. Echo Evolution & Interaction Mechanisms
    //    8. triggerContextualEvolution: Evolves an Echo based on external context data (e.g., verifiable on-chain activity, oracle input)
    //                                   and the currently active evolution rule set. Requires 'Essence' payment.
    //    9. applyTransientBoost: Applies a temporary, time-limited boost to an Echo's trait, reflecting ephemeral states.
    //    10. mergeEchoes: Combines two existing Echoes into a new, unique Echo, burning the originals. This simulates a more complex
    //                     "breeding" or "fusion" mechanism with potential for novel trait generation. Requires an ETH fee.
    //    11. mutateEcho: Introduces a randomized mutation to an Echo's traits, potentially increasing or decreasing them. Requires 'Essence' payment.
    //    12. attuneEcho: Allows a user to manually influence an Echo's affinity, requiring a deposit of "Essence."

    // III. Resource & Economy Management
    //    13. depositEssence: Users deposit native currency (ETH) into the contract, converting it to "Essence" for actions.
    //    14. withdrawEssence: Users can withdraw their deposited native currency (Essence).
    //    15. getEssenceBalance: Returns the Essence balance of a specified user.

    // IV. Metamind Governance & Rule Set Adaptation
    //    16. proposeEvolutionRuleSet: Allows eligible participants (based on Attunement Score) to propose a new set of rules
    //                                 that dictate how Echoes evolve. Proposals include executable `callData`.
    //    17. voteOnProposal: Participants cast votes (for or against) on active Metamind proposals. Voting power is derived from their cumulative Echo 'Attunement'.
    //    18. executeProposal: Executes a successfully voted-on proposal, for example, activating a new evolution rule set.
    //    19. getCurrentEvolutionRuleSetId: Returns the ID of the currently active and enforced evolution rule set.
    //    20. getProposalDetails: Provides all information regarding a specific Metamind proposal.
    //    21. enactEvolutionRuleSet: An internal-facing function called by `executeProposal` to activate a new rule set.

    // V. System Configuration & Access Control
    //    22. setBaseURI: Owner/DAO sets the base URI for Echo metadata, crucial for dynamic rendering by an off-chain service.
    //    23. setOracleAddress: Owner/DAO updates the address of the external oracle used for contextual data verification.
    //    24. pause: Emergency function to pause critical contract operations.
    //    25. unpause: Unpauses the contract after an emergency pause.
    //    26. calculateAttunementScore: Calculates a user's aggregate "Attunement Score" based on all their Echoes' affinities and traits.
    //                                  This score dynamically grants governance power or unlocks special features.

    // VI. Soulbound Token (SBT) Mechanism
    //    - The `_beforeTokenTransfer` hook is overridden to prevent any transfers, making Echoes non-transferable by design.

    // VII. Events
    //    - EchoMinted, EchoEvolved, EchoMerged, EchoMutated, EchoAttuned, EssenceDeposited, EssenceWithdrawn,
    //      ProposalCreated, VoteCast, ProposalExecuted, RuleSetActivated, OracleAddressUpdated, BaseURIUpdated, Paused, Unpaused.

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for new Echoes
    address private _oracleAddress;
    string private _baseURI;

    // --- Data Structures ---

    // Represents a single Echo (dynamic NFT)
    struct Echo {
        uint256 tokenId;
        address owner;
        mapping(bytes32 => uint256) traits; // e.g., keccak256("Insight") => 100
        mapping(bytes32 => uint256) affinities; // e.g., keccak256("DeFi") => 50
        uint256 lastEvolvedBlock;
        uint256 genesisBlock;
        mapping(bytes32 => bool) statusFlags; // e.g., keccak256("Merged") => true, keccak256("MutatedRecently") => true
        mapping(bytes32 => uint256) transientBoostsEndBlock; // traitHash => endBlock for a temporary boost
        mapping(bytes32 => uint256) transientBoostValues; // traitHash => value of the temporary boost
    }
    mapping(uint256 => Echo) private _echoes; // tokenId => Echo data

    // Defines how a trait is modified by an evolution rule
    struct RuleModification {
        bytes32 traitName;
        int256 change; // Can be positive (increase) or negative (decrease)
    }

    // Defines how an affinity is modified by an evolution rule
    struct AffinityModification {
        bytes32 affinityName;
        uint256 boost;
    }

    // A single rule within an EvolutionRuleSet, triggered by a specific context
    struct EvolutionRule {
        bytes32 contextType; // e.g., keccak256("DeFiActivity"), keccak256("GovernanceParticipation")
        bytes32 requiredConditionHash; // Hash of specific data the oracle needs to verify (can be keccak256(_contextData))
        uint256 essenceCost;
        RuleModification[] traitChanges;
        AffinityModification[] affinityBoosts;
    }

    // A collection of EvolutionRules, representing a version of how Echoes can evolve
    struct EvolutionRuleSet {
        uint256 id;
        EvolutionRule[] rules; // Array of rules for different contexts
        bool isActive; // Only one rule set is active at a time
        address proposedBy;
        uint256 activationBlock;
        uint256 expirationBlock; // A rule set can have a limited validity period (type(uint256).max for never expires)
    }
    mapping(uint256 => EvolutionRuleSet) private _evolutionRuleSets;
    uint256 private _nextRuleSetId;
    uint256 private _activeRuleSetId;

    // Status for governance proposals
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    // Structure for a Metamind Governance Proposal
    struct MetamindProposal {
        uint256 proposalId;
        address proposer;
        string description;
        uint256 startTimestamp;
        uint256 endTimestamp; // When voting period ends
        uint256 requiredAttunementThreshold; // Minimum attunement score to propose
        uint256 minVotingPowerPercentage; // e.g., 5% of snapshotTotalAttunement needed for quorum
        uint256 forVotes;
        uint256 againstVotes;
        uint256 snapshotTotalAttunement; // Total attunement score at proposal creation for calculating quorum
        ProposalStatus status;
        bytes callData; // Encoded function call for execution (e.g., calling enactEvolutionRuleSet)
        address targetContract; // Address of contract to call (can be `address(this)`)
        mapping(address => bool) hasVoted; // Prevents double voting
    }
    mapping(uint256 => MetamindProposal) private _metamindProposals;
    uint256 private _nextProposalId;

    mapping(address => uint256) private _essenceBalances; // User's deposited native token balance, used as "Essence"

    // --- Events ---
    event EchoMinted(address indexed owner, uint256 indexed tokenId, string initialTraitSeed);
    event EchoEvolved(uint256 indexed tokenId, bytes32 indexed contextType, uint256 ruleSetId, uint256 essenceCost);
    event EchoMerged(address indexed owner, uint256 indexed parent1, uint256 indexed parent2, uint256 newEchoId, uint256 ethFee);
    event EchoMutated(uint256 indexed tokenId, bytes32 mutationType, uint256 essenceCost);
    event EchoAttuned(uint256 indexed tokenId, bytes32 affinityName, uint256 essenceCost);
    event TransientBoostApplied(uint256 indexed tokenId, bytes32 traitName, uint256 boostAmount, uint256 durationBlocks);

    event EssenceDeposited(address indexed user, uint256 amount);
    event EssenceWithdrawn(address indexed user, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startTimestamp, uint256 endTimestamp);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool _forVote, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);

    event RuleSetActivated(uint256 indexed ruleSetId, uint256 activationBlock);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event BaseURIUpdated(string oldBaseURI, string newBaseURI);

    // --- Constructor ---

    /**
     * @dev Initializes the Echoes of the Metamind contract.
     * @param name_ The name for the ERC721 token collection.
     * @param symbol_ The symbol for the ERC721 token collection.
     * @param initialOracle The address of the initial oracle contract.
     * @param initialBaseURI The base URI for dynamic Echo metadata.
     */
    constructor(string memory name_, string memory symbol_, address initialOracle, string memory initialBaseURI)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        require(initialOracle != address(0), "Echoes: Initial oracle address cannot be zero");
        _oracleAddress = initialOracle;
        _baseURI = initialBaseURI;
        _nextTokenId = 1;
        _nextRuleSetId = 1;
        _nextProposalId = 1;

        // Initialize a default, empty rule set as active, to be replaced by governance
        _evolutionRuleSets[0] = EvolutionRuleSet({
            id: 0,
            rules: new EvolutionRule[](0),
            isActive: true,
            proposedBy: address(this),
            activationBlock: block.number,
            expirationBlock: type(uint256).max // Never expires
        });
        _activeRuleSetId = 0;
    }

    // --- Access Control Overrides ---

    /**
     * @dev Overrides the ERC721 `_beforeTokenTransfer` hook to prevent any transfers,
     *      making Echoes non-transferable (Soulbound Token-like).
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Allow minting (from == address(0)) and burning (to == address(0)), but no other transfers.
        require(from == address(0) || to == address(0), "Echoes: Non-transferable token (SBT)");
    }

    // --- I. Core Echo Management & Information Retrieval ---

    /**
     * @dev Mints a new Echo (SBT-like) for `_to` with initial traits.
     *      Initial traits are simple and can be refined by evolution.
     * @param _to The address to mint the Echo to.
     * @param _initialTraitSeed A string seed used to initialize some traits (e.g., a username or passphrase).
     * @return The tokenId of the newly minted Echo.
     */
    function mintEcho(address _to, string memory _initialTraitSeed) public whenNotPaused returns (uint256) {
        require(_to != address(0), "Echoes: Mint to the zero address");

        uint256 tokenId = _nextTokenId++;
        _mint(_to, tokenId);

        // Initialize Echo structure
        Echo storage newEcho = _echoes[tokenId];
        newEcho.tokenId = tokenId;
        newEcho.owner = _to;
        newEcho.genesisBlock = block.number;
        newEcho.lastEvolvedBlock = block.number;

        // Apply a simple initial trait based on the seed
        uint256 seedHash = uint256(keccak256(abi.encodePacked(_initialTraitSeed)));
        newEcho.traits[keccak256("Resilience")] = 50 + (seedHash % 50);
        newEcho.traits[keccak256("Insight")] = 25 + (seedHash % 25);
        newEcho.traits[keccak256("Creativity")] = 10 + (seedHash % 10); // Example initial trait
        newEcho.affinities[keccak256("General")] = 10;
        newEcho.affinities[keccak256("Discovery")] = 5; // Example initial affinity

        emit EchoMinted(_to, tokenId, _initialTraitSeed);
        return tokenId;
    }

    /**
     * @dev Retrieves all core details of an Echo.
     *      Note: Due to Solidity's limitations on iterating mappings, this function returns
     *      a limited set of common traits/affinities. A frontend would typically query specific
     *      traits/affinities as needed.
     * @param _tokenId The ID of the Echo.
     * @return owner The owner's address.
     * @return genesisBlock The block number when the Echo was minted.
     * @return lastEvolvedBlock The block number when the Echo last evolved.
     * @return traitNames An array of common trait names (bytes32).
     * @return traitValues An array of corresponding trait values.
     * @return affinityNames An array of common affinity names (bytes32).
     * @return affinityValues An array of corresponding affinity values.
     * @return statusFlags An array of active status flags (e.g., "Merged").
     * @return transientBoostedTraits An array of traits currently receiving a transient boost.
     * @return transientBoostEndBlocks An array of corresponding end blocks for transient boosts.
     * @return transientBoostValues An array of corresponding values for transient boosts.
     */
    function getEchoDetails(uint256 _tokenId)
        public
        view
        returns (
            address owner,
            uint256 genesisBlock,
            uint256 lastEvolvedBlock,
            bytes32[] memory traitNames,
            uint256[] memory traitValues,
            bytes32[] memory affinityNames,
            uint256[] memory affinityValues,
            bytes32[] memory statusFlags,
            bytes32[] memory transientBoostedTraits,
            uint256[] memory transientBoostEndBlocks,
            uint256[] memory transientBoostValues
        )
    {
        require(_exists(_tokenId), "Echoes: Token does not exist");
        Echo storage echo = _echoes[_tokenId];

        owner = echo.owner;
        genesisBlock = echo.genesisBlock;
        lastEvolvedBlock = echo.lastEvolvedBlock;

        // Populate common traits. In a real dApp, a dynamic trait list or direct queries would be more scalable.
        bytes32[] memory _traitNames = new bytes32[](3);
        uint256[] memory _traitValues = new uint256[](3);
        _traitNames[0] = keccak256("Resilience");
        _traitValues[0] = getEchoTraitValue(_tokenId, keccak256("Resilience"));
        _traitNames[1] = keccak256("Insight");
        _traitValues[1] = getEchoTraitValue(_tokenId, keccak256("Insight"));
        _traitNames[2] = keccak256("Creativity");
        _traitValues[2] = getEchoTraitValue(_tokenId, keccak256("Creativity"));
        traitNames = _traitNames;
        traitValues = _traitValues;

        // Populate common affinities
        bytes32[] memory _affinityNames = new bytes32[](2);
        uint256[] memory _affinityValues = new uint256[](2);
        _affinityNames[0] = keccak256("General");
        _affinityValues[0] = echo.affinities[keccak256("General")];
        _affinityNames[1] = keccak256("Discovery");
        _affinityValues[1] = echo.affinities[keccak256("Discovery")];
        affinityNames = _affinityNames;
        affinityValues = _affinityValues;

        // Populate status flags (e.g., "Merged", "MutatedRecently").
        // This is a simplified approach; dynamic array resizing is costly.
        bytes32[] memory _statusFlags = new bytes32[](0);
        if (echo.statusFlags[keccak256("Merged")]) {
            _statusFlags = new bytes32[](1);
            _statusFlags[0] = keccak256("Merged");
        }
        statusFlags = _statusFlags; // Add more conditions for other flags

        // Populate transient boosts
        bytes32[] memory _boostedTraits = new bytes32[](0);
        uint256[] memory _boostEndBlocks = new uint256[](0);
        uint256[] memory _boostValues = new uint256[](0);

        // Example for a known transient boost type (e.g., a 'Creativity' boost)
        if (echo.transientBoostsEndBlock[keccak256("CreativityBoost")] > block.number) {
            _boostedTraits = new bytes32[](1);
            _boostEndBlocks = new uint256[](1);
            _boostValues = new uint256[](1);
            _boostedTraits[0] = keccak256("Creativity"); // The trait that is boosted
            _boostEndBlocks[0] = echo.transientBoostsEndBlock[keccak256("CreativityBoost")];
            _boostValues[0] = echo.transientBoostsEndBlock[keccak256("CreativityBoost")]; // The actual boost value
        }
        transientBoostedTraits = _boostedTraits;
        transientBoostEndBlocks = _boostEndBlocks;
        transientBoostValues = _boostValues;
    }


    /**
     * @dev Gets the value of a specific trait for an Echo, considering transient boosts.
     * @param _tokenId The ID of the Echo.
     * @param _traitName The name of the trait (e.g., keccak256("Insight")).
     * @return The current value of the trait, including any active temporary boosts.
     */
    function getEchoTraitValue(uint256 _tokenId, bytes32 _traitName) public view returns (uint256) {
        require(_exists(_tokenId), "Echoes: Token does not exist");
        uint256 baseValue = _echoes[_tokenId].traits[_traitName];

        // Apply transient boost if active and associated with this trait
        // This assumes a convention like "CreativityBoost" affecting "Creativity" trait.
        bytes32 boostKey = keccak256(abi.encodePacked(_traitName, "Boost"));
        if (_echoes[_tokenId].transientBoostsEndBlock[boostKey] > block.number) {
             return baseValue.add(_echoes[_tokenId].transientBoostValues[boostKey]);
        }
        return baseValue;
    }

    /**
     * @dev Gets the value of a specific affinity for an Echo.
     * @param _tokenId The ID of the Echo.
     * @param _affinityName The name of the affinity (e.g., keccak256("DeFi")).
     * @return The current value of the affinity.
     */
    function getEchoAffinityValue(uint256 _tokenId, bytes32 _affinityName) public view returns (uint256) {
        require(_exists(_tokenId), "Echoes: Token does not exist");
        return _echoes[_tokenId].affinities[_affinityName];
    }

    /**
     * @dev Returns the total number of Echoes minted.
     * @return The total supply of Echoes, including those marked as 'Merged' but still tracked for historical purposes.
     */
    function getEchoCount() public view returns (uint256) {
        return _nextTokenId.sub(1); // Since token IDs start from 1
    }

    /**
     * @dev Returns the URI for a given Echo's metadata.
     *      This URI should point to an API endpoint that dynamically generates JSON metadata
     *      based on the Echo's current on-chain state (traits, affinities, status).
     * @param _tokenId The ID of the Echo.
     * @return The metadata URI.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Echoes: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI, _tokenId.toString(), ".json"));
    }

    // --- II. Echo Evolution & Interaction Mechanisms ---

    /**
     * @dev Evolves an Echo based on external context data and the currently active rule set.
     *      Requires verification by an oracle for external contexts.
     *      Must be called by the Echo's owner.
     * @param _tokenId The ID of the Echo to evolve.
     * @param _contextType The type of context (e.g., keccak256("DeFiActivity")).
     * @param _contextData Arbitrary data relevant to the context, potentially for oracle verification.
     */
    function triggerContextualEvolution(uint256 _tokenId, bytes32 _contextType, bytes memory _contextData) public payable whenNotPaused {
        require(_exists(_tokenId), "Echoes: Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Echoes: Not the owner of this Echo");
        require(_oracleAddress != address(0), "Echoes: Oracle address not set");

        EvolutionRuleSet storage currentRuleSet = _evolutionRuleSets[_activeRuleSetId];
        require(currentRuleSet.isActive, "Echoes: No active evolution rule set");
        require(currentRuleSet.expirationBlock == type(uint256).max || block.number <= currentRuleSet.expirationBlock, "Echoes: Active rule set has expired");

        bool ruleFound = false;
        uint256 appliedEssenceCost = 0;

        for (uint i = 0; i < currentRuleSet.rules.length; i++) {
            EvolutionRule storage rule = currentRuleSet.rules[i];
            if (rule.contextType == _contextType) {
                // Verify condition via oracle
                require(IOracle(_oracleAddress).verifyContext(rule.contextType, _contextData), "Echoes: Oracle context verification failed");
                require(_essenceBalances[msg.sender] >= rule.essenceCost, "Echoes: Insufficient Essence for evolution");

                _essenceBalances[msg.sender] = _essenceBalances[msg.sender].sub(rule.essenceCost);
                appliedEssenceCost = rule.essenceCost;
                _echoes[_tokenId].lastEvolvedBlock = block.number;

                // Apply trait changes
                for (uint j = 0; j < rule.traitChanges.length; j++) {
                    RuleModification storage mod = rule.traitChanges[j];
                    if (mod.change > 0) {
                        _echoes[_tokenId].traits[mod.traitName] = _echoes[_tokenId].traits[mod.traitName].add(uint256(mod.change));
                    } else { // Handle negative changes (decreases)
                        _echoes[_tokenId].traits[mod.traitName] = _echoes[_tokenId].traits[mod.traitName].sub(uint256(mod.change * -1));
                    }
                }
                // Apply affinity boosts
                for (uint j = 0; j < rule.affinityBoosts.length; j++) {
                    AffinityModification storage affMod = rule.affinityBoosts[j];
                    _echoes[_tokenId].affinities[affMod.affinityName] = _echoes[_tokenId].affinities[affMod.affinityName].add(affMod.boost);
                }
                ruleFound = true;
                break; // Rule applied, exit loop
            }
        }
        require(ruleFound, "Echoes: No matching evolution rule found for this context");
        emit EchoEvolved(_tokenId, _contextType, _activeRuleSetId, appliedEssenceCost);
    }

    /**
     * @dev Applies a temporary, time-limited boost to an Echo's trait.
     *      The boost value is stored separately and added to the base trait value
     *      only when `getEchoTraitValue` is called and the boost is active.
     * @param _tokenId The ID of the Echo.
     * @param _traitName The name of the trait to boost.
     * @param _boostAmount The amount to boost the trait by.
     * @param _durationBlocks The number of blocks the boost will last.
     */
    function applyTransientBoost(uint256 _tokenId, bytes32 _traitName, uint256 _boostAmount, uint256 _durationBlocks) public whenNotPaused {
        require(_exists(_tokenId), "Echoes: Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Echoes: Not the owner of this Echo");
        require(_boostAmount > 0, "Echoes: Boost amount must be positive");
        require(_durationBlocks > 0, "Echoes: Boost duration must be positive");

        Echo storage echo = _echoes[_tokenId];
        bytes32 boostKey = keccak256(abi.encodePacked(_traitName, "Boost")); // Unique key for this specific boost

        // If a boost for this trait already exists and is active, potentially combine or replace it.
        // For simplicity, we'll overwrite or extend.
        echo.transientBoostsEndBlock[boostKey] = block.number.add(_durationBlocks);
        echo.transientBoostValues[boostKey] = _boostAmount;

        emit TransientBoostApplied(_tokenId, _traitName, _boostAmount, _durationBlocks);
    }

    /**
     * @dev Combines two existing Echoes into a new one, burning the originals.
     *      The new Echo inherits characteristics and potentially gains novel traits.
     *      Requires ownership of both parent Echoes and an ETH fee.
     * @param _tokenIdA The ID of the first Echo.
     * @param _tokenIdB The ID of the second Echo.
     * @return newEchoId The tokenId of the newly created merged Echo.
     */
    function mergeEchoes(uint256 _tokenIdA, uint256 _tokenIdB) public payable whenNotPaused returns (uint256 newEchoId) {
        require(msg.sender == ownerOf(_tokenIdA), "Echoes: Sender must own Echo A");
        require(msg.sender == ownerOf(_tokenIdB), "Echoes: Sender must own Echo B");
        require(_tokenIdA != _tokenIdB, "Echoes: Cannot merge an Echo with itself");
        require(!_echoes[_tokenIdA].statusFlags[keccak256("Merged")], "Echoes: Echo A already merged or invalid");
        require(!_echoes[_tokenIdB].statusFlags[keccak256("Merged")], "Echoes: Echo B already merged or invalid");

        uint256 mergeFee = 0.01 ether; // Example ETH fee
        require(msg.value >= mergeFee, "Echoes: Merging requires 0.01 ETH fee");

        Echo storage echoA = _echoes[_tokenIdA];
        Echo storage echoB = _echoes[_tokenIdB];

        // Mark parents as merged (effectively "burning" their active status)
        echoA.statusFlags[keccak256("Merged")] = true;
        echoB.statusFlags[keccak256("Merged")] = true;
        // The ERC721 `_burn` function removes them from ownership tracking.
        _burn(_tokenIdA);
        _burn(_tokenIdB);

        // Mint a new Echo
        newEchoId = _nextTokenId++;
        _mint(msg.sender, newEchoId);

        Echo storage newEcho = _echoes[newEchoId];
        newEcho.tokenId = newEchoId;
        newEcho.owner = msg.sender;
        newEcho.genesisBlock = block.number;
        newEcho.lastEvolvedBlock = block.number;

        // Inherit and combine traits/affinities (example logic)
        // Traits: Simple average, but could be weighted, or allow for dominant traits
        newEcho.traits[keccak256("Resilience")] = (echoA.traits[keccak256("Resilience")].add(echoB.traits[keccak256("Resilience")])).div(2);
        newEcho.traits[keccak256("Insight")] = (echoA.traits[keccak256("Insight")].add(echoB.traits[keccak256("Insight")])).div(2);
        newEcho.traits[keccak256("Creativity")] = (echoA.traits[keccak256("Creativity")].add(echoB.traits[keccak256("Creativity")])).div(2);

        // Introduce a new trait or boost an existing one based on merge.
        // Pseudo-random generation for novelty.
        uint256 randSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenIdA, _tokenIdB)));
        newEcho.traits[keccak256("Synergy")] = 50 + (randSeed % 50); // A newly gained trait

        // Affinities: Sum them up for combined strength
        newEcho.affinities[keccak256("General")] = echoA.affinities[keccak256("General")].add(echoB.affinities[keccak256("General")]);
        newEcho.affinities[keccak256("Discovery")] = echoA.affinities[keccak256("Discovery")].add(echoB.affinities[keccak256("Discovery")]);
        newEcho.affinities[keccak256("MergedLegacy")] = 20; // A new affinity reflecting its origin

        emit EchoMerged(msg.sender, _tokenIdA, _tokenIdB, newEchoId, mergeFee);
        return newEchoId;
    }

    /**
     * @dev Introduces a randomized mutation to an Echo's traits.
     *      Requires a certain amount of Essence and has a cooldown.
     * @param _tokenId The ID of the Echo to mutate.
     * @param _mutationType A seed string to influence the mutation (e.g., "Fire", "Ice").
     */
    function mutateEcho(uint256 _tokenId, bytes32 _mutationType) public whenNotPaused {
        require(_exists(_tokenId), "Echoes: Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Echoes: Not the owner of this Echo");
        require(!_echoes[_tokenId].statusFlags[keccak256("Merged")], "Echoes: Merged Echoes cannot mutate");

        // Implement a cooldown for mutation to prevent spamming
        bytes32 cooldownFlag = keccak256("MutatedRecently");
        require(!_echoes[_tokenId].statusFlags[cooldownFlag], "Echoes: Echo mutated too recently (cooldown active)");

        uint256 mutationCost = 0.005 ether; // Example cost in Essence
        require(_essenceBalances[msg.sender] >= mutationCost, "Echoes: Insufficient Essence for mutation");
        _essenceBalances[msg.sender] = _essenceBalances[msg.sender].sub(mutationCost);

        // Simple pseudo-randomness for mutation magnitude and target trait
        uint256 randSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenId, _mutationType)));
        uint256 mutationFactor = (randSeed % 20) + 1; // 1 to 20% mutation magnitude

        // Select a trait to mutate (simplified: pick from a few known traits)
        bytes32[] memory potentialTraits = new bytes32[](3);
        potentialTraits[0] = keccak256("Resilience");
        potentialTraits[1] = keccak256("Insight");
        potentialTraits[2] = keccak256("Creativity");
        bytes32 targetTrait = potentialTraits[randSeed % potentialTraits.length];

        // Apply mutation: 50% chance to increase, 50% chance to decrease
        if ((randSeed % 2) == 0) { // Increase
            _echoes[_tokenId].traits[targetTrait] = _echoes[_tokenId].traits[targetTrait].add(_echoes[_tokenId].traits[targetTrait].mul(mutationFactor).div(100));
        } else { // Decrease
            _echoes[_tokenId].traits[targetTrait] = _echoes[_tokenId].traits[targetTrait].sub(_echoes[_tokenId].traits[targetTrait].mul(mutationFactor).div(100));
        }

        // Set cooldown: A more robust system would store `cooldownEndBlock`
        _echoes[_tokenId].statusFlags[cooldownFlag] = true;
        // You'd need a mechanism to clear this flag after some blocks/time. (e.g., a function `clearMutationCooldown` callable after `block.number > cooldownEndBlock`)

        emit EchoMutated(_tokenId, _mutationType, mutationCost);
    }

    /**
     * @dev Allows a user to manually boost an Echo's affinity by paying Essence.
     * @param _tokenId The ID of the Echo.
     * @param _affinityName The name of the affinity to boost.
     */
    function attuneEcho(uint256 _tokenId, bytes32 _affinityName) public whenNotPaused {
        require(_exists(_tokenId), "Echoes: Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Echoes: Not the owner of this Echo");

        uint256 attunementCost = 0.001 ether; // Example cost in Essence
        require(_essenceBalances[msg.sender] >= attunementCost, "Echoes: Insufficient Essence for attunement");
        _essenceBalances[msg.sender] = _essenceBalances[msg.sender].sub(attunementCost);

        _echoes[_tokenId].affinities[_affinityName] = _echoes[_tokenId].affinities[_affinityName].add(10); // Boost by 10

        emit EchoAttuned(_tokenId, _affinityName, attunementCost);
    }

    // --- III. Resource & Economy Management ---

    /**
     * @dev Allows users to deposit native currency (ETH) into the contract, which is converted to "Essence"
     *      and tracked in their internal balance. Essence is used to fund various Echo actions.
     */
    function depositEssence() public payable {
        require(msg.value > 0, "Essence: Deposit amount must be greater than zero");
        _essenceBalances[msg.sender] = _essenceBalances[msg.sender].add(msg.value);
        emit EssenceDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to withdraw their deposited native currency (Essence) from the contract.
     * @param _amount The amount of Essence (ETH) to withdraw.
     */
    function withdrawEssence(uint256 _amount) public {
        require(_essenceBalances[msg.sender] >= _amount, "Essence: Insufficient balance");
        _essenceBalances[msg.sender] = _essenceBalances[msg.sender].sub(_amount);
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "Essence: ETH transfer failed");
        emit EssenceWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Returns the Essence balance of a specified user.
     * @param _user The address of the user.
     * @return The Essence balance.
     */
    function getEssenceBalance(address _user) public view returns (uint256) {
        return _essenceBalances[_user];
    }

    // --- IV. Metamind Governance & Rule Set Adaptation ---

    /**
     * @dev Proposes a new set of evolution rules or other governance actions. Requires a minimum Attunement Score.
     *      The proposal must then be voted on by the community.
     * @param _newRules An array of new EvolutionRule definitions. If the proposal is for a new rule set, this is populated.
     *                  If it's for a different action, this can be an empty array.
     * @param _description A detailed description of the proposal.
     * @param _durationBlocks The duration (in blocks) for which the proposal will be active for voting.
     * @param _minVotingPowerPercentage The minimum percentage of the total snapshot attunement score needed for quorum.
     * @param _requiredAttunementThreshold Minimum Attunement Score required for a user to create this proposal.
     * @param _targetContract The address of the contract to call if the proposal passes (e.g., `address(this)` to call `enactEvolutionRuleSet`).
     * @param _callData The encoded call data for the target function to be executed upon successful proposal.
     *                  Example: `abi.encodeWithSelector(this.enactEvolutionRuleSet.selector, newRuleSetId)`
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeEvolutionRuleSet(
        EvolutionRule[] memory _newRules,
        string memory _description,
        uint256 _durationBlocks,
        uint256 _minVotingPowerPercentage,
        uint256 _requiredAttunementThreshold,
        address _targetContract,
        bytes memory _callData
    ) public whenNotPaused returns (uint256 proposalId) {
        require(calculateAttunementScore(msg.sender) >= _requiredAttunementThreshold, "Metamind: Insufficient Attunement to propose");
        require(_durationBlocks > 0, "Metamind: Proposal duration must be positive");
        require(_minVotingPowerPercentage > 0 && _minVotingPowerPercentage <= 100, "Metamind: Quorum percentage must be between 1 and 100");
        require(_targetContract != address(0), "Metamind: Target contract cannot be zero address");

        proposalId = _nextProposalId++;

        // If rules are provided, create a new (inactive) rule set that this proposal aims to activate.
        uint256 newRuleSetId = 0; // Default to 0 if not proposing a new rule set
        if (_newRules.length > 0) {
            newRuleSetId = _nextRuleSetId++;
            _evolutionRuleSets[newRuleSetId] = EvolutionRuleSet({
                id: newRuleSetId,
                rules: _newRules,
                isActive: false, // Not active until executed by governance
                proposedBy: msg.sender,
                activationBlock: 0, // Set on execution
                expirationBlock: type(uint256).max // Can be set in `_callData` if needed
            });
            // The _callData should target `enactEvolutionRuleSet(newRuleSetId)` in this case.
        }

        _metamindProposals[proposalId] = MetamindProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _description,
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp.add(_durationBlocks.mul(1 seconds)), // Convert blocks to approximate seconds
            requiredAttunementThreshold: _requiredAttunementThreshold,
            minVotingPowerPercentage: _minVotingPowerPercentage,
            forVotes: 0,
            againstVotes: 0,
            snapshotTotalAttunement: _calculateTotalAttunementSnapshot(), // Snapshot total voting power at proposal creation
            status: ProposalStatus.Active,
            callData: _callData,
            targetContract: _targetContract,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit ProposalCreated(proposalId, msg.sender, _description, block.timestamp, _metamindProposals[proposalId].endTimestamp);
        return proposalId;
    }

    /**
     * @dev Allows participants to vote on a Metamind proposal.
     *      Voting power is based on the user's current `Attunement Score`.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _forVote True for a "for" vote, false for an "against" vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _forVote) public whenNotPaused {
        MetamindProposal storage proposal = _metamindProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Metamind: Proposal is not active or has ended");
        require(block.timestamp <= proposal.endTimestamp, "Metamind: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Metamind: Already voted on this proposal");

        uint256 voterAttunement = calculateAttunementScore(msg.sender);
        require(voterAttunement > 0, "Metamind: Voter has no Attunement Score or not enough to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_forVote) {
            proposal.forVotes = proposal.forVotes.add(voterAttunement);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voterAttunement);
        }

        emit VoteCast(_proposalId, msg.sender, _forVote, voterAttunement);

        // Check and potentially update proposal status if voting period has just ended, or if quorum reached early
        _checkAndSetProposalStatus(_proposalId);
    }

    /**
     * @dev Executes a successful Metamind proposal. Can only be called once, after the voting period ends and criteria are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        MetamindProposal storage proposal = _metamindProposals[_proposalId];
        require(proposal.status != ProposalStatus.Executed, "Metamind: Proposal already executed");

        // Ensure voting period has ended and status is finalized
        _checkAndSetProposalStatus(_proposalId);
        require(proposal.status == ProposalStatus.Succeeded, "Metamind: Proposal not in 'Succeeded' status");

        proposal.status = ProposalStatus.Executed; // Mark as executed
        proposal.executed = true; // For external query

        // Execute the call data against the target contract
        (bool success, bytes memory result) = proposal.targetContract.call(proposal.callData);
        require(success, string(abi.encodePacked("Metamind: Proposal execution failed: ", result)));

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Internal function to check and update a proposal's status based on current time and votes.
     *      This function ensures the proposal's state is accurate when queried or executed.
     * @param _proposalId The ID of the proposal.
     */
    function _checkAndSetProposalStatus(uint256 _proposalId) internal {
        MetamindProposal storage proposal = _metamindProposals[_proposalId];

        if (proposal.status != ProposalStatus.Active) return; // Only check active proposals

        if (block.timestamp >= proposal.endTimestamp) {
            uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
            uint256 requiredQuorum = proposal.snapshotTotalAttunement.mul(proposal.minVotingPowerPercentage).div(100);

            if (totalVotes >= requiredQuorum && proposal.forVotes > proposal.againstVotes) {
                proposal.status = ProposalStatus.Succeeded;
            } else {
                proposal.status = ProposalStatus.Failed;
            }
            emit ProposalStatusChanged(_proposalId, proposal.status);
        }
    }

    /**
     * @dev This function is intended to be called by the `executeProposal` mechanism
     *      to activate a new rule set after it has passed governance.
     *      It's `onlyOwner` to ensure it's called by a trusted source (the contract itself via `call`).
     * @param _ruleSetId The ID of the rule set to activate.
     */
    function enactEvolutionRuleSet(uint256 _ruleSetId) public onlyOwner {
        require(_evolutionRuleSets[_ruleSetId].proposedBy != address(0), "Metamind: Rule set does not exist");
        require(!_evolutionRuleSets[_ruleSetId].isActive, "Metamind: Rule set already active");

        _evolutionRuleSets[_activeRuleSetId].isActive = false; // Deactivate current rule set
        _activeRuleSetId = _ruleSetId;
        _evolutionRuleSets[_ruleSetId].isActive = true;
        _evolutionRuleSets[_ruleSetId].activationBlock = block.number; // Record activation block

        emit RuleSetActivated(_ruleSetId, block.number);
    }

    /**
     * @dev Returns the ID of the currently active evolution rule set.
     * @return The ID of the active rule set.
     */
    function getCurrentEvolutionRuleSetId() public view returns (uint256) {
        return _activeRuleSetId;
    }

    /**
     * @dev Retrieves details about a Metamind proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing comprehensive details of the proposal.
     */
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            uint256 proposalId,
            address proposer,
            string memory description,
            uint256 startTimestamp,
            uint256 endTimestamp,
            uint256 forVotes,
            uint256 againstVotes,
            ProposalStatus status,
            bool executed,
            uint256 snapshotTotalAttunement,
            uint256 minVotingPowerPercentage,
            bytes memory callData,
            address targetContract
        )
    {
        MetamindProposal storage proposal = _metamindProposals[_proposalId];

        // Note: For a true `view` function, we avoid state modifications like `_checkAndSetProposalStatus`.
        // The client-side application is expected to call `executeProposal` when the conditions are met.
        // The `status` returned here reflects the stored state.

        return (
            proposal.proposalId,
            proposal.proposer,
            proposal.description,
            proposal.startTimestamp,
            proposal.endTimestamp,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.status,
            proposal.executed,
            proposal.snapshotTotalAttunement,
            proposal.minVotingPowerPercentage,
            proposal.callData,
            proposal.targetContract
        );
    }


    // --- V. System Configuration & Access Control ---

    /**
     * @dev Sets the base URI for Echo metadata. This is typically managed by the owner or DAO.
     *      The `tokenURI` function concatenates this base URI with the token ID and ".json".
     * @param _newBaseURI The new base URI (e.g., "https://api.metamind.xyz/echoes/").
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        string memory oldBaseURI = _baseURI;
        _baseURI = _newBaseURI;
        emit BaseURIUpdated(oldBaseURI, _newBaseURI);
    }

    /**
     * @dev Sets the address of the external oracle contract. Only callable by the owner (or DAO).
     * @param _newOracleAddress The new oracle contract address.
     */
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "Echoes: Oracle address cannot be zero");
        address oldOracleAddress = _oracleAddress;
        _oracleAddress = _newOracleAddress;
        emit OracleAddressUpdated(oldOracleAddress, _newOracleAddress);
    }

    /**
     * @dev Pauses the contract, preventing critical state-changing functions from being called.
     *      This is an emergency stop mechanism, callable only by the owner.
     */
    function pause() public onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing normal operation to resume.
     *      Callable only by the owner after a pause.
     */
    function unpause() public onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Calculates a user's cumulative "Attunement Score" based on all their Echoes' affinities and traits.
     *      This score is dynamic and serves as a form of reputation, granting governance power or unlocking features.
     *      (Example logic: a weighted sum of Insight, Resilience, Creativity traits, and General/Discovery affinities
     *      across all owned, non-merged Echoes).
     * @param _user The address of the user.
     * @return The calculated Attunement Score.
     */
    function calculateAttunementScore(address _user) public view returns (uint256) {
        uint256 totalAttunement = 0;
        uint256 echoCount = balanceOf(_user); // Number of Echoes owned by _user

        for (uint256 i = 0; i < echoCount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_user, i);
            Echo storage echo = _echoes[tokenId];

            // Only count non-merged Echoes for active attunement
            if (echo.statusFlags[keccak256("Merged")]) continue;

            // Apply weighting to different traits and affinities
            totalAttunement = totalAttunement.add(getEchoTraitValue(tokenId, keccak256("Insight")).mul(2));
            totalAttunement = totalAttunement.add(getEchoTraitValue(tokenId, keccak256("Resilience")).mul(1));
            totalAttunement = totalAttunement.add(getEchoTraitValue(tokenId, keccak256("Creativity")).mul(1));
            totalAttunement = totalAttunement.add(echo.affinities[keccak256("General")].mul(1));
            totalAttunement = totalAttunement.add(echo.affinities[keccak256("Discovery")].mul(1));
            // You can add more complex logic, e.g., decaying scores over time, bonuses for specific combinations.
        }
        return totalAttunement;
    }

    /**
     * @dev Internal helper function to calculate the total snapshot attunement of all active Echoes.
     *      This value is used to determine quorum and voting power for proposals at the time of creation.
     */
    function _calculateTotalAttunementSnapshot() internal view returns (uint256) {
        uint256 totalSnapshotAttunement = 0;
        uint256 mintedEchoCount = getEchoCount(); // Total tokens ever minted

        // Iterating through all tokens is gas-intensive for large supplies.
        // For very large systems, a global counter or a more advanced voting token system would be preferred.
        for (uint256 i = 0; i < mintedEchoCount; i++) {
            uint256 tokenId = i + 1; // Assuming token IDs are sequential from 1
            if (_exists(tokenId)) { // Check if the token still exists and isn't burnt
                Echo storage echo = _echoes[tokenId];
                if (echo.owner != address(0) && !echo.statusFlags[keccak256("Merged")]) { // Ensure it's active and not merged
                    totalSnapshotAttunement = totalSnapshotAttunement.add(getEchoTraitValue(tokenId, keccak256("Insight")).mul(2));
                    totalSnapshotAttunement = totalSnapshotAttunement.add(getEchoTraitValue(tokenId, keccak256("Resilience")).mul(1));
                    totalSnapshotAttunement = totalSnapshotAttunement.add(echo.affinities[keccak256("General")].mul(1));
                }
            }
        }
        return totalSnapshotAttunement;
    }

    // --- Fallback Function ---
    /**
     * @dev Allows the contract to receive native currency (ETH) directly,
     *      automatically treating it as a deposit for "Essence."
     */
    receive() external payable {
        depositEssence();
    }
}
```