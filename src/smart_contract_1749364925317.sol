Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts like dynamic properties, on-chain evolution, community-driven lore, merging mechanics, pseudo-randomness for attributes, and a simple internal governance system based on user interaction ("Contribution Points").

It aims to be a creative take on programmable digital assets (Artefacts) that can change and gain history over time, guided partly by their owners and partly by a community.

**Important Considerations & Warnings:**

*   **Gas Costs:** Storing strings on-chain (like lore) is expensive. This example uses it for simplicity, but in a real application, you might store hashes pointing to off-chain data (IPFS, Arweave).
*   **Randomness:** On-chain pseudo-randomness (`block.timestamp`, `block.difficulty`, `keccak256`) is *not* truly random and can be manipulated by miners/validators. For critical applications, use Chainlink VRF or similar verifiable randomness solutions. This example uses a simple method for demonstration.
*   **Governance:** The governance system here is a *very* basic example. Real DAO implementations are significantly more complex (voting strategies, proposal types, execution safety, token weighting, etc.).
*   **Security:** This is a conceptual example. A production-ready contract requires rigorous security audits, reentrancy checks (especially with the `call` in `executeProposal`), access control carefulness, and overflow/underflow checks (though modern Solidity helps).
*   **Scalability:** Large amounts of on-chain data (many lore entries, complex property mappings) can become expensive and hit block gas limits.
*   **ERC721 Compatibility:** This contract does *not* fully implement the ERC721 standard interface to avoid being a direct copy. It implements similar core concepts (minting, transfer, ownership tracking) but adds custom mechanics. You could wrap this logic with an ERC721 interface if needed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronicleArtefacts
 * @dev A smart contract for managing dynamic, evolving digital artefacts with community lore and governance.
 *      Artefacts are unique digital items with mutable properties, a narrative history
 *      added by owners, and the ability to evolve based on conditions.
 *      A simple governance system based on "Contribution Points" allows the community
 *      to propose and vote on parameter changes or lore suggestions (simplified).
 *
 * Outline:
 * 1. Basic Artefact Management (Minting, Transfer, Ownership)
 * 2. Dynamic Properties & Attributes (Setting, Incrementing)
 * 3. Artefact Evolution (Defining requirements/outcomes, Triggering evolution)
 * 4. Community Lore & Narrative (Adding, Retrieving, Contribution Points)
 * 5. Artefact Interaction Mechanics (Merging, Attunement)
 * 6. Pseudo-Random Attribute Generation (Basic on-chain randomness)
 * 7. Internal Governance System (Contribution Points, Proposals, Voting, Execution)
 * 8. Parameter Setting (Admin/Governance controlled)
 * 9. View/Helper Functions
 *
 * Function Summary (at least 20 functions):
 * - mintArtefact(address recipient, string memory initialName): Mints a new artefact.
 * - transferArtefact(address from, address to, uint256 artefactId): Transfers artefact ownership.
 * - getArtefactOwner(uint256 artefactId): Gets owner of an artefact.
 * - getArtefactBalance(address owner): Gets number of artefacts owned by an address.
 * - getArtefactDetails(uint256 artefactId): Gets core artefact details.
 * - setArtefactAttribute(uint256 artefactId, string memory propertyName, uint256 value): Sets a numerical attribute.
 * - incrementArtefactAttribute(uint256 artefactId, string memory propertyName, uint256 amount): Increments a numerical attribute.
 * - updateArtefactStringProperty(uint256 artefactId, string memory propertyName, string memory value): Updates a string property.
 * - getArtefactAttribute(uint256 artefactId, string memory propertyName): Gets a numerical attribute value.
 * - getArtefactStringProperty(uint256 artefactId, string memory propertyName): Gets a string property value.
 * - addLoreEntry(uint256 artefactId, string memory loreEntry): Adds a lore entry to an artefact. Grants contribution points.
 * - getLoreEntries(uint256 artefactId): Gets all lore entries for an artefact.
 * - getContributionPoints(address user): Gets contribution points for a user.
 * - evolveArtefact(uint256 artefactId): Triggers evolution logic for an artefact.
 * - canArtefactEvolve(uint256 artefactId): Checks if an artefact meets evolution requirements.
 * - mergeArtefacts(uint256 artefact1Id, uint256 artefact2Id): Merges two artefacts (burns one, enhances the other).
 * - attuneArtefact(uint256 artefactId, uint256 durationInSeconds): Locks an artefact for attunement.
 * - isArtefactAttuned(uint256 artefactId): Checks if an artefact is currently attuned.
 * - claimAttunementBonus(uint256 artefactId): Allows claiming a bonus after attunement period ends.
 * - setupInitialRandomAttributes(uint256 artefactId): Sets initial pseudo-random attributes upon minting. (Internal helper)
 * - createProposal(string memory description, address targetContract, bytes memory callData, uint256 votingPeriodSeconds): Creates a governance proposal.
 * - voteOnProposal(uint256 proposalId, bool support): Votes on a governance proposal.
 * - executeProposal(uint256 proposalId): Executes a successful governance proposal.
 * - cancelProposal(uint256 proposalId): Cancels an active proposal (creator/admin).
 * - getProposalDetails(uint256 proposalId): Gets details of a proposal.
 * - setEvolutionRequirement(string memory propertyName, string memory requiredProperty, uint256 requiredValue): Sets a requirement for evolution (Admin/Governance).
 * - setEvolutionOutcome(string memory propertyName, string memory outcomeProperty, uint256 outcomeAmount): Sets an outcome of evolution (Admin/Governance).
 * - setAttunementBonus(string memory propertyName, uint256 bonusAmount): Defines the attunement bonus (Admin/Governance).
 * - setLoreContributionPoints(uint256 points): Sets points granted for adding lore (Admin/Governance).
 * - setProposalThreshold(uint256 pointsRequired): Sets points needed to create a proposal (Admin/Governance).
 */

contract ChronicleArtefacts {

    // --- Events ---
    event ArtefactMinted(uint256 indexed artefactId, address indexed owner, string initialName);
    event ArtefactTransferred(uint256 indexed artefactId, address indexed from, address indexed to);
    event AttributeUpdated(uint256 indexed artefactId, string propertyName, uint256 value);
    event StringPropertyUpdated(uint256 indexed artefactId, string propertyName, string value);
    event LoreAdded(uint256 indexed artefactId, address indexed contributor, string loreEntry);
    event ArtefactEvolved(uint256 indexed artefactId, string evolutionOutcome);
    event ArtefactsMerged(uint256 indexed artefact1Id, uint256 indexed artefact2Id, uint256 resultingArtefactId);
    event ArtefactAttuned(uint256 indexed artefactId, uint256 attunementUntil);
    event AttunementBonusClaimed(uint256 indexed artefactId, string bonusProperty, uint256 bonusAmount);
    event ContributionPointsAwarded(address indexed user, uint256 points);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event EvolutionRequirementSet(string propertyName, string requiredProperty, uint256 requiredValue);
    event EvolutionOutcomeSet(string propertyName, string outcomeProperty, uint256 outcomeAmount);

    // --- Errors ---
    error ArtefactDoesNotExist();
    error NotArtefactOwner();
    error InvalidRecipient();
    error CannotTransferToZeroAddress();
    error CannotSelfMerge();
    error ArtefactsAlreadyMerged();
    error NotAttuned();
    error AttunementPeriodNotEnded();
    error AttunementBonusAlreadyClaimed();
    error NotEnoughContributionPoints(uint256 requiredPoints, uint256 userPoints);
    error ProposalDoesNotExist();
    error VotingPeriodEnded();
    error AlreadyVoted();
    error ProposalNotYetEnded();
    error ProposalDidNotPass();
    error ProposalAlreadyExecutedOrCanceled();
    error ProposalExecutionFailed();
    error NotProposalCreatorOrAdmin();

    // --- Structs ---
    struct Artefact {
        uint256 id;
        uint256 creationTimestamp;
        mapping(string => uint256) attributes; // Dynamic numerical properties
        mapping(string => string) stringProperties; // Dynamic string properties (e.g., Title, Description)
        string[] loreEntries; // Array of lore strings
        uint256 attunementUntil; // Timestamp until which the artefact is attuned
        bool attunementBonusClaimed; // Flag to check if bonus for current attunement is claimed
    }

    struct Proposal {
        uint256 id;
        address creator;
        string description;
        address targetContract; // Contract to call if proposal passes (can be this contract's address)
        bytes callData;       // The data to send with the call
        uint256 createdTimestamp;
        uint256 votingPeriodSeconds;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
        bool canceled;
    }

    // --- State Variables ---
    uint256 private _artefactCounter;
    mapping(uint256 => Artefact) private _artefacts;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    address public owner; // Contract admin (can be replaced by governance later)

    // Evolution Configuration:
    // Mapping: PropertyName => RequiredProperty => RequiredValue
    mapping(string => mapping(string => uint256)) public evolutionRequirements;
    // Mapping: PropertyName => OutcomeProperty => OutcomeAmount (increase)
    mapping(string => mapping(string => uint256)) public evolutionOutcomes;

    // Attunement Configuration:
    mapping(string => uint256) public attunementBonus; // PropertyName => BonusAmount

    // Community & Governance:
    mapping(address => uint256) public contributionPoints;
    uint256 public loreContributionPoints = 10; // Points gained per lore entry
    uint256 public proposalThreshold = 50; // Points required to create a proposal
    uint256 public voteThreshold = 1; // Points required to vote

    uint256 private _proposalCounter;
    mapping(uint256 => Proposal) private _proposals;

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier artefactExists(uint256 artefactId) {
        if (_owners[artefactId] == address(0)) {
            revert ArtefactDoesNotExist();
        }
        _;
    }

    modifier onlyArtefactOwner(uint256 artefactId) {
        artefactExists(artefactId);
        if (_owners[artefactId] != msg.sender) {
            revert NotArtefactOwner();
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        _artefactCounter = 0;
        _proposalCounter = 0;

        // Set some initial evolution requirements/outcomes (example)
        evolutionRequirements["Power"]["TimeCreated"] = 3600; // Must be at least 1 hour old to evolve Power
        evolutionRequirements["Power"]["Mystique"] = 10;      // Must have Mystique >= 10 to evolve Power
        evolutionOutcomes["Power"]["Power"] = 5;             // Evolving Power increases Power by 5
        evolutionOutcomes["Power"]["Mystique"] = 1;          // Evolving Power also increases Mystique by 1

        // Set some initial attunement bonus (example)
        attunementBonus["Mystique"] = 3; // Attuning gives +3 Mystique
    }

    // --- Basic Artefact Management (Functions 1-5) ---

    /**
     * @dev Mints a new Artefact and assigns it to the recipient.
     * @param recipient The address to receive the new Artefact.
     * @param initialName The initial name for the Artefact.
     */
    function mintArtefact(address recipient, string memory initialName) public onlyOwner returns (uint256) {
        if (recipient == address(0)) revert InvalidRecipient();

        _artefactCounter++;
        uint256 newArtefactId = _artefactCounter;

        // Initialize Artefact struct - Note: mappings inside structs are special, only exist *in storage*
        // when the struct instance exists. We don't need to explicitly create the inner mappings.
        _artefacts[newArtefactId].id = newArtefactId;
        _artefacts[newArtefactId].creationTimestamp = block.timestamp;
        _artefacts[newArtefactId].stringProperties["Name"] = initialName;

        // Assign owner and update balance
        _transfer(address(0), recipient, newArtefactId);

        // Setup initial random attributes
        setupInitialRandomAttributes(newArtefactId);

        emit ArtefactMinted(newArtefactId, recipient, initialName);
        return newArtefactId;
    }

    /**
     * @dev Transfers ownership of an Artefact.
     * @param from The current owner of the Artefact.
     * @param to The address to transfer the Artefact to.
     * @param artefactId The ID of the Artefact to transfer.
     */
    function transferArtefact(address from, address to, uint255 artefactId) public artefactExists(artefactId) {
        // Basic ownership check (more complex with approve/transferFrom, but keeping simple)
        if (_owners[artefactId] != msg.sender && from != msg.sender) revert NotArtefactOwner(); // Either owner or approved (if we added approval)
        if (_owners[artefactId] != from) revert NotArtefactOwner(); // Ensure `from` is correct
        if (to == address(0)) revert CannotTransferToZeroAddress();

        _transfer(from, to, artefactId);
    }

    /**
     * @dev Internal function to handle artefact transfers.
     */
    function _transfer(address from, address to, uint256 artefactId) internal {
        if (from != address(0)) {
            _balances[from]--;
        }
        _owners[artefactId] = to;
        _balances[to]++;

        emit ArtefactTransferred(artefactId, from, to);
    }

    /**
     * @dev Gets the owner of an Artefact.
     * @param artefactId The ID of the Artefact.
     * @return The address of the owner.
     */
    function getArtefactOwner(uint256 artefactId) public view artefactExists(artefactId) returns (address) {
        return _owners[artefactId];
    }

    /**
     * @dev Gets the number of Artefacts owned by an address.
     * @param owner The address to check.
     * @return The balance of Artefacts.
     */
    function getArtefactBalance(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Gets core details of an Artefact.
     * @param artefactId The ID of the Artefact.
     * @return Tuple containing id, creation timestamp, and owner.
     */
    function getArtefactDetails(uint256 artefactId) public view artefactExists(artefactId) returns (uint256, uint256, address) {
        Artefact storage artefact = _artefacts[artefactId];
        return (artefact.id, artefact.creationTimestamp, _owners[artefactId]);
    }

    // --- Dynamic Properties & Attributes (Functions 6-9) ---

    /**
     * @dev Sets a numerical attribute for an Artefact (owner only).
     * @param artefactId The ID of the Artefact.
     * @param propertyName The name of the attribute (e.g., "Power", "Mystique").
     * @param value The value to set.
     */
    function setArtefactAttribute(uint256 artefactId, string memory propertyName, uint256 value) public onlyArtefactOwner(artefactId) {
        _artefacts[artefactId].attributes[propertyName] = value;
        emit AttributeUpdated(artefactId, propertyName, value);
    }

    /**
     * @dev Increments a numerical attribute for an Artefact (owner only).
     * @param artefactId The ID of the Artefact.
     * @param propertyName The name of the attribute.
     * @param amount The amount to add.
     */
    function incrementArtefactAttribute(uint255 artefactId, string memory propertyName, uint256 amount) public onlyArtefactOwner(artefactId) {
        _artefacts[artefactId].attributes[propertyName] += amount;
        emit AttributeUpdated(artefactId, propertyName, _artefacts[artefactId].attributes[propertyName]);
    }

     /**
     * @dev Updates a string property for an Artefact (owner only).
     * @param artefactId The ID of the Artefact.
     * @param propertyName The name of the string property (e.g., "Title", "Description").
     * @param value The string value to set.
     */
    function updateArtefactStringProperty(uint256 artefactId, string memory propertyName, string memory value) public onlyArtefactOwner(artefactId) {
        _artefacts[artefactId].stringProperties[propertyName] = value;
        emit StringPropertyUpdated(artefactId, propertyName, value);
    }

    /**
     * @dev Gets the value of a numerical attribute for an Artefact.
     * @param artefactId The ID of the Artefact.
     * @param propertyName The name of the attribute.
     * @return The value of the attribute. Returns 0 if not set.
     */
    function getArtefactAttribute(uint256 artefactId, string memory propertyName) public view artefactExists(artefactId) returns (uint256) {
        return _artefacts[artefactId].attributes[propertyName];
    }

    /**
     * @dev Gets the value of a string property for an Artefact.
     * @param artefactId The ID of the Artefact.
     * @param propertyName The name of the string property.
     * @return The value of the string property. Returns empty string if not set.
     */
    function getArtefactStringProperty(uint255 artefactId, string memory propertyName) public view artefactExists(artefactId) returns (string memory) {
        return _artefacts[artefactId].stringProperties[propertyName];
    }

    // --- Community Lore & Narrative (Functions 10-12) ---

    /**
     * @dev Adds a lore entry to an Artefact's history (owner only).
     *      Awards contribution points to the owner.
     *      NOTE: Storing strings on-chain is expensive.
     * @param artefactId The ID of the Artefact.
     * @param loreEntry The lore string to add.
     */
    function addLoreEntry(uint256 artefactId, string memory loreEntry) public onlyArtefactOwner(artefactId) {
        Artefact storage artefact = _artefacts[artefactId];
        artefact.loreEntries.push(loreEntry);
        _awardContributionPoints(msg.sender, loreContributionPoints);
        emit LoreAdded(artefactId, msg.sender, loreEntry);
    }

    /**
     * @dev Gets all lore entries for an Artefact.
     * @param artefactId The ID of the Artefact.
     * @return An array of lore strings.
     */
    function getLoreEntries(uint256 artefactId) public view artefactExists(artefactId) returns (string[] memory) {
        return _artefacts[artefactId].loreEntries;
    }

    /**
     * @dev Gets the contribution points of a user.
     * @param user The address to check.
     * @return The number of contribution points.
     */
    function getContributionPoints(address user) public view returns (uint256) {
        return contributionPoints[user];
    }

    // --- Artefact Evolution (Functions 13-15) ---

    /**
     * @dev Triggers the evolution logic for an Artefact (owner only).
     *      Applies evolution outcomes if requirements are met for any property.
     *      An artefact can potentially evolve multiple properties at once if conditions are met.
     * @param artefactId The ID of the Artefact.
     */
    function evolveArtefact(uint256 artefactId) public onlyArtefactOwner(artefactId) {
        Artefact storage artefact = _artefacts[artefactId];
        bool evolvedAny = false;

        // Iterate through potential evolution outcomes defined by admin/governance
        // Note: Iterating mappings is not possible directly, need to track keys or predefine.
        // For simplicity, let's assume we iterate over the *defined* evolution *outcomes*.
        // A real implementation might iterate over known mutable properties.
        // Let's check outcomes defined in `evolutionOutcomes` mapping keys.
        // Simpler approach: Just check specific expected properties like "Power".
        // We'll check if "Power" can evolve based on defined requirements.

        // Check for "Power" evolution requirements
        if (canArtefactEvolve(artefactId, "Power")) {
            // Apply "Power" evolution outcomes
            uint256 outcomeAmount = evolutionOutcomes["Power"]["Power"];
            if (outcomeAmount > 0) {
                 artefact.attributes["Power"] += outcomeAmount;
                 emit AttributeUpdated(artefactId, "Power", artefact.attributes["Power"]);
                 evolvedAny = true;
            }
            outcomeAmount = evolutionOutcomes["Power"]["Mystique"];
             if (outcomeAmount > 0) {
                 artefact.attributes["Mystique"] += outcomeAmount;
                 emit AttributeUpdated(artefactId, "Mystique", artefact.attributes["Mystique"]);
                 evolvedAny = true;
            }
            // Add more specific outcome checks here if needed for other properties
             emit ArtefactEvolved(artefactId, "Power");
        }

        // Could add checks for other properties here:
        // if (canArtefactEvolve(artefactId, "AnotherProperty")) { ... apply outcomes ... }

        if (!evolvedAny) {
             // Revert or silently do nothing? Let's silently do nothing for now.
             // require(false, "Artefact does not meet evolution requirements"); // Or this
        }
    }

    /**
     * @dev Checks if an Artefact meets the requirements for evolving a specific property.
     * @param artefactId The ID of the Artefact.
     * @param propertyToEvolve The name of the property being checked for evolution requirements (e.g., "Power").
     * @return True if all requirements for the property are met, false otherwise.
     */
    function canArtefactEvolve(uint256 artefactId, string memory propertyToEvolve) public view artefactExists(artefactId) returns (bool) {
        Artefact storage artefact = _artefacts[artefactId];

        // Check generic time requirement if defined
        uint256 timeRequirement = evolutionRequirements[propertyToEvolve]["TimeCreated"];
        if (timeRequirement > 0 && block.timestamp < artefact.creationTimestamp + timeRequirement) {
            return false; // Not old enough
        }

        // Check specific attribute requirements defined in `evolutionRequirements`
        // Note: This requires iterating over mapping keys, which is complex.
        // A simpler approach for demonstration is to check a few known requirement types.
        // Let's check for a "Mystique" requirement as defined in constructor example.
        uint256 mystiqueRequirement = evolutionRequirements[propertyToEvolve]["Mystique"];
        if (mystiqueRequirement > 0 && artefact.attributes["Mystique"] < mystiqueRequirement) {
             return false; // Doesn't have enough Mystique
        }

        // Add checks for other specific required properties here based on your config

        // If all checked requirements are met, allow evolution for this property type
        return true;
    }


    // --- Artefact Interaction Mechanics (Functions 16-18) ---

    /**
     * @dev Merges two Artefacts into one (owner only).
     *      Artefact2 is 'consumed' and its properties are added to Artefact1.
     *      Artefact2 is effectively burned.
     * @param artefact1Id The ID of the primary Artefact (will be kept).
     * @param artefact2Id The ID of the secondary Artefact (will be burned).
     */
    function mergeArtefacts(uint256 artefact1Id, uint256 artefact2Id) public onlyArtefactOwner(artefact1Id) artefactExists(artefact2Id) {
        if (artefact1Id == artefact2Id) revert CannotSelfMerge();
        if (_owners[artefact2Id] != msg.sender) revert NotArtefactOwner(); // Must own both

        Artefact storage artefact1 = _artefacts[artefact1Id];
        Artefact storage artefact2 = _artefacts[artefact2Id];

        // Simple property merging: Add numerical attributes
        // NOTE: This is a basic example. Complex merging requires careful rules.
        artefact1.attributes["Power"] += artefact2.attributes["Power"];
        artefact1.attributes["Mystique"] += artefact2.attributes["Mystique"];
        // Add more attribute merging logic here

        // Simple lore merging: Add lore entries from artefact2 to artefact1
        for(uint i = 0; i < artefact2.loreEntries.length; i++) {
             artefact1.loreEntries.push(artefact2.loreEntries[i]);
        }

        // Burn Artefact2
        _transfer(msg.sender, address(0), artefact2Id);
        // Clean up storage for Artefact2 (optional, but good practice if possible)
        delete _artefacts[artefact2Id]; // Frees storage slot associated with artefact2Id

        emit ArtefactsMerged(artefact1Id, artefact2Id, artefact1Id); // Resulting ID is artefact1Id
    }

     /**
     * @dev Initiates attunement for an Artefact (owner only). Locks the artefact temporarily.
     * @param artefactId The ID of the Artefact.
     * @param durationInSeconds The duration of the attunement period.
     */
    function attuneArtefact(uint256 artefactId, uint256 durationInSeconds) public onlyArtefactOwner(artefactId) {
        _artefacts[artefactId].attunementUntil = block.timestamp + durationInSeconds;
        _artefacts[artefactId].attunementBonusClaimed = false; // Reset claim status
        emit ArtefactAttuned(artefactId, _artefacts[artefactId].attunementUntil);
    }

    /**
     * @dev Checks if an Artefact is currently attuned.
     * @param artefactId The ID of the Artefact.
     * @return True if attuned and period not ended, false otherwise.
     */
    function isArtefactAttuned(uint256 artefactId) public view artefactExists(artefactId) returns (bool) {
        return _artefacts[artefactId].attunementUntil > block.timestamp;
    }

    /**
     * @dev Allows claiming a bonus after the attunement period has ended (owner only).
     * @param artefactId The ID of the Artefact.
     */
    function claimAttunementBonus(uint256 artefactId) public onlyArtefactOwner(artefactId) {
        Artefact storage artefact = _artefacts[artefactId];
        if (artefact.attunementUntil == 0) revert NotAttuned();
        if (block.timestamp < artefact.attunementUntil) revert AttunementPeriodNotEnded();
        if (artefact.attunementBonusClaimed) revert AttunementBonusAlreadyClaimed();

        // Apply bonuses defined in `attunementBonus` mapping
        // Iterate over expected bonus types or check specific ones
        uint256 mystiqueBonus = attunementBonus["Mystique"]; // Check for Mystique bonus
        if (mystiqueBonus > 0) {
             artefact.attributes["Mystique"] += mystiqueBonus;
             emit AttributeUpdated(artefactId, "Mystique", artefact.attributes["Mystique"]);
             emit AttunementBonusClaimed(artefactId, "Mystique", mystiqueBonus);
        }

        // Add checks for other potential bonuses here

        artefact.attunementBonusClaimed = true; // Mark bonus as claimed
        artefact.attunementUntil = 0; // Reset attunement status after claiming
    }

    // --- Pseudo-Random Attribute Generation (Function 19 - Internal) ---

     /**
     * @dev Sets initial pseudo-random attributes for a new Artefact.
     *      NOTE: This is not cryptographically secure randomness on-chain.
     * @param artefactId The ID of the Artefact.
     */
    function setupInitialRandomAttributes(uint255 artefactId) internal {
        // Simple pseudo-random seed from block data and artefact ID
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.number, tx.origin, artefactId, _artefacts[artefactId].creationTimestamp));

        // Generate some attributes using the seed
        // Example: Power between 1 and 10
        uint256 power = (uint256(keccak256(abi.encodePacked(seed, "power"))) % 10) + 1;
        _artefacts[artefactId].attributes["Power"] = power;
        emit AttributeUpdated(artefactId, "Power", power);

        // Example: Mystique between 5 and 15
        uint256 mystique = (uint256(keccak256(abi.encodePacked(seed, "mystique"))) % 11) + 5;
         _artefacts[artefactId].attributes["Mystique"] = mystique;
        emit AttributeUpdated(artefactId, "Mystique", mystique);

        // Add more random attribute generation here
    }

    // --- Internal Governance System (Functions 20-25) ---

    /**
     * @dev Internal function to award contribution points.
     * @param user The address to award points to.
     * @param points The amount of points to award.
     */
    function _awardContributionPoints(address user, uint256 points) internal {
        contributionPoints[user] += points;
        emit ContributionPointsAwarded(user, points);
    }

    /**
     * @dev Creates a new governance proposal. Requires sufficient contribution points.
     * @param description A description of the proposal.
     * @param targetContract The address of the contract the proposal will interact with.
     * @param callData The ABI-encoded data for the function call.
     * @param votingPeriodSeconds The duration of the voting period.
     */
    function createProposal(string memory description, address targetContract, bytes memory callData, uint256 votingPeriodSeconds) public {
        if (contributionPoints[msg.sender] < proposalThreshold) {
            revert NotEnoughContributionPoints(proposalThreshold, contributionPoints[msg.sender]);
        }

        _proposalCounter++;
        uint256 proposalId = _proposalCounter;

        Proposal storage proposal = _proposals[proposalId];
        proposal.id = proposalId;
        proposal.creator = msg.sender;
        proposal.description = description;
        proposal.targetContract = targetContract;
        proposal.callData = callData;
        proposal.createdTimestamp = block.timestamp;
        proposal.votingPeriodSeconds = votingPeriodSeconds;
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        proposal.executed = false;
        proposal.canceled = false;

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /**
     * @dev Votes on a governance proposal. Requires sufficient contribution points and must be within the voting period.
     * @param proposalId The ID of the proposal.
     * @param support True for yes, false for no.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.creator == address(0)) revert ProposalDoesNotExist(); // Check existence
        if (block.timestamp > proposal.createdTimestamp + proposal.votingPeriodSeconds) revert VotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();
        if (contributionPoints[msg.sender] < voteThreshold) {
             revert NotEnoughContributionPoints(voteThreshold, contributionPoints[msg.sender]);
        }

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor += contributionPoints[msg.sender]; // Weight vote by points
        } else {
            proposal.votesAgainst += contributionPoints[msg.sender]; // Weight vote by points
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a successful governance proposal after the voting period has ended.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.creator == address(0)) revert ProposalDoesNotExist();
        if (block.timestamp <= proposal.createdTimestamp + proposal.votingPeriodSeconds) revert ProposalNotYetEnded();
        if (proposal.executed || proposal.canceled) revert ProposalAlreadyExecutedOrCanceled();

        // Simple majority threshold (can be more complex, e.g., quorum)
        if (proposal.votesFor <= proposal.votesAgainst) revert ProposalDidNotPass();

        // Execute the call
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        if (!success) {
            // Mark as executed despite failure, or allow retry? Marking for simplicity.
            proposal.executed = true;
            revert ProposalExecutionFailed();
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

     /**
     * @dev Cancels a governance proposal if it's active (creator or admin only).
     * @param proposalId The ID of the proposal.
     */
    function cancelProposal(uint256 proposalId) public {
         Proposal storage proposal = _proposals[proposalId];
         if (proposal.creator == address(0)) revert ProposalDoesNotExist();
         if (proposal.executed || proposal.canceled) revert ProposalAlreadyExecutedOrCanceled();
         if (msg.sender != proposal.creator && msg.sender != owner) revert NotProposalCreatorOrAdmin();

         proposal.canceled = true;
         emit ProposalCanceled(proposalId);
    }

    /**
     * @dev Gets details of a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return Tuple containing proposal details.
     */
    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        address creator,
        string memory description,
        address targetContract,
        bytes memory callData,
        uint256 createdTimestamp,
        uint256 votingPeriodSeconds,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        bool canceled
    ) {
         Proposal storage proposal = _proposals[proposalId];
         if (proposal.creator == address(0)) revert ProposalDoesNotExist(); // Check existence

         return (
             proposal.id,
             proposal.creator,
             proposal.description,
             proposal.targetContract,
             proposal.callData,
             proposal.createdTimestamp,
             proposal.votingPeriodSeconds,
             proposal.votesFor,
             proposal.votesAgainst,
             proposal.executed,
             proposal.canceled
         );
    }


    // --- Parameter Setting (Functions 26-30) ---
    // These should ideally be callable only by the contract owner or via governance proposals

    /**
     * @dev Sets an evolution requirement for a specific property (Owner/Governance).
     *      E.g., require "Mystique" >= 10 to evolve "Power".
     * @param propertyName The property that *can* evolve (e.g., "Power").
     * @param requiredProperty The property/condition needed (e.g., "Mystique", "TimeCreated").
     * @param requiredValue The minimum value for the required property.
     */
    function setEvolutionRequirement(string memory propertyName, string memory requiredProperty, uint256 requiredValue) public onlyOwner { // Or add governance check
        evolutionRequirements[propertyName][requiredProperty] = requiredValue;
        emit EvolutionRequirementSet(propertyName, requiredProperty, requiredValue);
    }

    /**
     * @dev Sets an evolution outcome for a specific property evolution (Owner/Governance).
     *      E.g., evolving "Power" increases "Power" by 5.
     * @param propertyName The property that is evolving (e.g., "Power").
     * @param outcomeProperty The property that is affected (e.g., "Power", "Mystique").
     * @param outcomeAmount The amount to add to the outcome property.
     */
    function setEvolutionOutcome(string memory propertyName, string memory outcomeProperty, uint256 outcomeAmount) public onlyOwner { // Or add governance check
        evolutionOutcomes[propertyName][outcomeProperty] = outcomeAmount;
        emit EvolutionOutcomeSet(propertyName, outcomeProperty, outcomeAmount);
    }

    /**
     * @dev Sets the bonus amounts received after attunement (Owner/Governance).
     *      E.g., attuning gives +3 Mystique.
     * @param propertyName The property that receives a bonus (e.g., "Mystique").
     * @param bonusAmount The amount added to the property after successful attunement claim.
     */
    function setAttunementBonus(string memory propertyName, uint256 bonusAmount) public onlyOwner { // Or add governance check
        attunementBonus[propertyName] = bonusAmount;
    }

    /**
     * @dev Sets the number of contribution points awarded for adding a lore entry (Owner/Governance).
     * @param points The number of points per lore entry.
     */
    function setLoreContributionPoints(uint256 points) public onlyOwner { // Or add governance check
        loreContributionPoints = points;
    }

    /**
     * @dev Sets the minimum contribution points required to create a governance proposal (Owner/Governance).
     * @param pointsRequired The threshold value.
     */
    function setProposalThreshold(uint256 pointsRequired) public onlyOwner { // Or add governance check
        proposalThreshold = pointsRequired;
    }

    /**
     * @dev Sets the minimum contribution points required to vote on a governance proposal (Owner/Governance).
     * @param pointsRequired The threshold value.
     */
    function setVoteThreshold(uint256 pointsRequired) public onlyOwner { // Or add governance check
        voteThreshold = pointsRequired;
    }

    // --- View/Helper Functions (Functions > 30 if counting helpers) ---
    // Counting the main public/external functions defined above already meets the > 20 requirement.
    // Adding more view functions can easily push the count further.

    // Example of more helper/view functions (not explicitly numbered in the main list to keep focus):

    // function getArtefactAttunementEndTime(uint256 artefactId) public view artefactExists(artefactId) returns (uint256) {
    //     return _artefacts[artefactId].attunementUntil;
    // }

    // function getTotalArtefactsMinted() public view returns (uint256) {
    //     return _artefactCounter;
    // }

    // function getProposalCount() public view returns (uint256) {
    //     return _proposalCounter;
    // }

    // etc.

}
```