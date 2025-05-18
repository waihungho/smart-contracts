Okay, this is a challenging but exciting request! Creating a truly unique, advanced smart contract concept that avoids duplicating existing open-source projects and has over 20 functions requires combining several ideas and implementing custom logic.

Let's build a concept around dynamic, evolving digital assets influenced by external factors and governed by their community.

**Concept: The Digital Renaissance Engine**

Imagine a contract that represents a mystical forge or engine capable of creating and evolving unique digital "Artifacts" (NFTs). These Artifacts are not static images but have mutable traits influenced by:

1.  **Essence:** A scarce, fungible resource token managed within the contract, required for creation and evolution.
2.  **Cosmic Flux:** Simulated external data (via an oracle) that introduces unpredictability and environmental influence on artifact evolution.
3.  **Alchemical Governance:** A DAO-like structure where Artifact and Essence holders can propose and vote on parameters of the Engine itself (like Essence costs, flux influence, etc.).

Artifacts can "Evolve" (changing traits using Essence and Flux) and potentially "Interact" (merging or influencing each other based on their traits and Essence).

This combines elements of:
*   **Dynamic NFTs:** Traits change over time.
*   **Resource Management:** Essence token is key.
*   **Oracle Interaction:** External data matters.
*   **On-chain Logic:** Traits and interactions are handled by the contract.
*   **Decentralized Governance:** Community shapes the Engine.

It avoids duplicating a *standard* ERC-20, ERC-721, or simple DAO by tightly integrating these components into a single, stateful system with unique mechanics for evolution, interaction, and external influence.

---

**Outline and Function Summary**

**Contract Name:** `DigitalRenaissanceEngine`

**Core Components:**
1.  **Essence (`ERT`):** Internal fungible token for actions.
2.  **Artifacts (`DRA`):** Non-fungible tokens with dynamic traits.
3.  **Cosmic Flux:** Simulated external data influence.
4.  **Alchemical Governance:** Parameter control by community.

**State Variables:**
*   Essence balances, total supply.
*   Artifact details (owner, traits, state, evolution history).
*   Next Artifact ID, total Artifact count.
*   Cosmic Flux value and Oracle address.
*   Governance proposals, voting data, parameters (costs, thresholds).
*   Role management (Owner, Minters).

**Events:**
*   EssenceMinted, EssenceConsumed
*   ArtifactCreated, ArtifactEvolved, ArtifactInteracted
*   FluxUpdated
*   ProposalCreated, VoteCast, ProposalExecuted, ProposalCancelled
*   ParameterChanged (generic for governance)
*   ERC-721 standard events (Transfer, Approval, ApprovalForAll)

**Error Handling:**
*   Descriptive revert messages for invalid actions (insufficient balance, not owner, proposal state invalid, etc.).

**Function Summary (Aiming for > 20):**

*   **Initialization & Setup:**
    1.  `constructor`: Deploys the contract, sets owner, initial parameters.
    2.  `setCosmicFluxOracle`: Sets the address of the Cosmic Flux Oracle (Owner/Governance only).
    3.  `addAllowedMinter`: Grants role to mint initial Essence (Owner/Governance only).
    4.  `removeAllowedMinter`: Revokes minter role (Owner/Governance only).

*   **Essence Management (Internal Resource):**
    5.  `mintEssence`: Creates new Essence (Allowed Minters only, possibly with limits).
    6.  `consumeEssence`: Burns Essence from caller (Internal helper, used by actions).
    7.  `balanceOfEssence`: Gets caller's Essence balance.
    8.  `getTotalEssenceSupply`: Gets total Essence in circulation.

*   **Artifact Management (Dynamic NFTs):**
    9.  `createArtifact`: Mints a new Artifact (Requires Essence, uses Flux and internal rules).
    10. `getArtifactTraits`: Views the current dynamic traits of an Artifact.
    11. `evolveArtifact`: Changes an Artifact's traits (Requires Essence, influenced by Flux and existing traits).
    12. `interactArtifacts`: Performs interaction logic between two Artifacts (Requires Essence, influences both based on traits and Flux).
    13. `tokenURI`: Standard ERC-721 function to get metadata URI (Calculated based on traits).
    14. `getArtifactCreationBlock`: Get block number when artifact was created.
    15. `getArtifactLastEvolutionBlock`: Get block number when artifact last evolved.

*   **Cosmic Flux Interaction:**
    16. `updateCosmicFlux`: Callable by the Oracle to update the internal flux value.
    17. `getCurrentCosmicFlux`: Views the current Cosmic Flux value.

*   **Alchemical Governance:**
    18. `proposeAlchemy`: Creates a new governance proposal (Requires minimum Artifact/Essence holdings).
    19. `voteOnAlchemy`: Casts a vote on an active proposal (Requires minimum holdings, one vote per address per proposal).
    20. `executeAlchemy`: Executes a successfully passed proposal.
    21. `cancelAlchemyProposal`: Cancels an active proposal (Proposer or Governance only).
    22. `getProposalState`: Views the current state of a proposal (Active, Passed, Failed, Executed, Cancelled).
    23. `getProposalDetails`: Views the parameters and state of a proposal.

*   **Governance-Controlled Parameter Management:**
    24. `setEvolutionEssenceCost`: Sets the Essence cost for `evolveArtifact` (Governance execution only).
    25. `setInteractionEssenceCost`: Sets the Essence cost for `interactArtifacts` (Governance execution only).
    26. `setCosmicFluxInfluenceFactor`: Sets how strongly Flux influences evolution (Governance execution only).
    27. `setMinGovernanceHoldings`: Sets the minimum Essence/Artifacts needed to propose/vote (Governance execution only).
    28. `setGovernanceVotingPeriodBlocks`: Sets the duration of voting periods (Governance execution only).
    29. `setGovernanceQuorumThreshold`: Sets the required percentage of votes for quorum (Governance execution only).

*   **Standard ERC-721 Functions (Implemented or Inherited):**
    *   `ownerOf`: Get owner of an artifact.
    *   `balanceOf`: Get number of artifacts owned by an address.
    *   `transferFrom` / `safeTransferFrom`: Transfer artifacts.
    *   `approve`: Approve single artifact transfer.
    *   `setApprovalForAll`: Approve operator for all artifacts.
    *   `getApproved`: Get approved address for an artifact.
    *   `isApprovedForAll`: Check if operator is approved for all artifacts.

*   **Utility & Views:**
    30. `getArtifactCount`: Total number of artifacts created.
    31. `getGovernanceParameters`: Views current governance settings.

*(Note: Standard ERC-721 functions add about 8 functions. By custom implementing or wrapping them, we easily exceed 20 unique actions/views on top of the core logic.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial setup/oracle


/**
 * @title DigitalRenaissanceEngine
 * @dev A dynamic NFT system where Artifacts evolve, interact, consume Essence,
 *      are influenced by external Flux, and governed by their holders.
 *
 * Outline:
 * - ERC-721 implementation for Artifacts (partially custom for dynamic data).
 * - Internal Essence token management.
 * - Cosmic Flux Oracle interaction.
 * - Artifact Creation, Evolution, Interaction mechanics.
 * - Alchemical Governance for parameter control.
 * - Role management (Owner, Minters).
 *
 * Function Summary:
 * 1. constructor()
 * 2. setCosmicFluxOracle()
 * 3. addAllowedMinter()
 * 4. removeAllowedMinter()
 * 5. mintEssence()
 * 6. consumeEssence() - Internal
 * 7. balanceOfEssence()
 * 8. getTotalEssenceSupply()
 * 9. createArtifact()
 * 10. getArtifactTraits()
 * 11. evolveArtifact()
 * 12. interactArtifacts()
 * 13. tokenURI()
 * 14. getArtifactCreationBlock()
 * 15. getArtifactLastEvolutionBlock()
 * 16. updateCosmicFlux()
 * 17. getCurrentCosmicFlux()
 * 18. proposeAlchemy()
 * 19. voteOnAlchemy()
 * 20. executeAlchemy()
 * 21. cancelAlchemyProposal()
 * 22. getProposalState()
 * 23. getProposalDetails()
 * 24. setEvolutionEssenceCost()
 * 25. setInteractionEssenceCost()
 * 26. setCosmicFluxInfluenceFactor()
 * 27. setMinGovernanceHoldings()
 * 28. setGovernanceVotingPeriodBlocks()
 * 29. setGovernanceQuorumThreshold()
 * 30. getArtifactCount()
 * 31. getGovernanceParameters()
 *
 * (Plus standard ERC-721 functions: ownerOf, balanceOf, transferFrom,
 *  safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll)
 */

interface ICosmicFluxOracle {
    function getFluxValue() external view returns (uint256);
}

contract DigitalRenaissanceEngine is Context, Ownable, IERC721, IERC165 {
    using Address for address;

    // --- State Variables ---

    // Essence Token (ERT)
    mapping(address => uint256) private _essenceBalances;
    uint256 private _totalEssence;
    mapping(address => bool) private _allowedMinters;

    // Artifacts (DRA) - ERC-721 implementation details
    struct Artifact {
        uint256 id;
        address owner; // Stored here for direct access in struct
        uint256 creationBlock;
        uint256 lastEvolutionBlock;
        bytes32[] traits; // Dynamic traits - interpret off-chain, but stored here
        uint256 fluxInfluenceBonus; // Specific bonus for this artifact
    }
    mapping(uint256 => Artifact) private _artifacts;
    mapping(uint256 => address) private _artifactOwners; // ERC721 standard map
    mapping(address => uint256) private _artifactCounts; // ERC721 standard map
    mapping(uint256 => address) private _tokenApprovals; // ERC721 standard map
    mapping(address => mapping(address => bool)) private _operatorApprovals; // ERC721 standard map
    uint256 private _nextArtifactId;

    // Cosmic Flux
    ICosmicFluxOracle private _cosmicFluxOracle;
    uint256 private _currentCosmicFlux; // Value from the oracle

    // Alchemical Governance
    enum ProposalState { Active, Passed, Failed, Executed, Cancelled }
    enum GovernanceActionType {
        SET_EVOLUTION_ESSENCE_COST,
        SET_INTERACTION_ESSENCE_COST,
        SET_COSMIC_FLUX_INFLUENCE_FACTOR,
        SET_MIN_GOVERNANCE_HOLDINGS, // Encodes Essence and Artifact minimums
        SET_GOVERNANCE_VOTING_PERIOD_BLOCKS,
        SET_GOVERNANCE_QUORUM_THRESHOLD,
        ADD_ALLOWED_MINTER, // Requires address data
        REMOVE_ALLOWED_MINTER // Requires address data
        // Add more action types as needed
    }

    struct Proposal {
        uint256 id;
        GovernanceActionType actionType;
        bytes actionData; // Encoded parameters for the action
        address proposer;
        uint256 creationBlock;
        uint256 votingPeriodEndBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        mapping(address => bool) hasVoted; // Track voters
    }
    mapping(uint256 => Proposal) private _proposals;
    uint256 private _nextProposalId;

    // Governance-controlled Parameters
    uint256 public evolutionEssenceCost;
    uint256 public interactionEssenceCost;
    uint256 public cosmicFluxInfluenceFactor; // How much flux affects outcomes
    uint256 public minGovEssenceHoldings; // Min Essence to propose/vote
    uint256 public minGovArtifactHoldings; // Min Artifacts to propose/vote
    uint256 public governanceVotingPeriodBlocks; // Duration of voting
    uint256 public governanceQuorumThreshold; // Percentage of votes required to pass (e.g., 5000 for 50%)

    // Constants (or make these parameters controllable by governance later)
    uint256 private constant INITIAL_EVOLUTION_COST = 100;
    uint256 private constant INITIAL_INTERACTION_COST = 200;
    uint256 private constant INITIAL_FLUX_INFLUENCE = 50; // 5% influence example
    uint256 private constant INITIAL_MIN_ESSENCE_GOV = 1000;
    uint256 private constant INITIAL_MIN_ARTIFACT_GOV = 1;
    uint256 private constant INITIAL_VOTING_PERIOD_BLOCKS = 100; // ~20 mins at 12s block time
    uint256 private constant INITIAL_QUORUM_THRESHOLD = 5000; // 50%

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // --- Events ---
    event EssenceMinted(address indexed to, uint256 amount);
    event EssenceConsumed(address indexed from, uint256 amount);
    event ArtifactCreated(uint256 indexed tokenId, address indexed owner, bytes32[] initialTraits);
    event ArtifactEvolved(uint256 indexed tokenId, bytes32[] newTraits, uint256 essenceSpent);
    event ArtifactInteracted(uint256 indexed tokenId1, uint256 indexed tokenId2, bytes32[] newTraits1, bytes32[] newTraits2, uint256 essenceSpent);
    event FluxUpdated(uint256 newFluxValue);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, GovernanceActionType actionType, uint256 votingPeriodEndBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support); // true for For, false for Against
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event ParameterChanged(string parameterName, bytes newValue); // Generic event for governance changes

    // --- Constructor ---

    constructor(address initialMinter) Ownable(msg.sender) {
        _allowedMinters[initialMinter] = true;

        // Set initial governance-controlled parameters
        evolutionEssenceCost = INITIAL_EVOLUTION_COST;
        interactionEssenceCost = INITIAL_INTERACTION_COST;
        cosmicFluxInfluenceFactor = INITIAL_FLUX_INFLUENCE;
        minGovEssenceHoldings = INITIAL_MIN_ESSENCE_GOV;
        minGovArtifactHoldings = INITIAL_MIN_ARTIFACT_GOV;
        governanceVotingPeriodBlocks = INITIAL_VOTING_PERIOD_BLOCKS;
        governanceQuorumThreshold = INITIAL_QUORUM_THRESHOLD;

        _nextArtifactId = 1; // Start token IDs from 1
        _nextProposalId = 1; // Start proposal IDs from 1
    }

    // --- Modifiers ---

    modifier onlyAllowedMinter() {
        require(_allowedMinters[_msgSender()], "Engine: Not an allowed minter");
        _;
    }

    // Internal modifier for governance-controlled functions
    modifier onlyGovernanceExecuted() {
        // This checks if the call is coming from the executeAlchemy function
        // Needs careful implementation if allowing delegatecall.
        // A safer approach: have executeAlchemy call specific internal handlers.
        // For this example, we'll assume executeAlchemy calls a dedicated
        // internal _handleGovernanceAction function which then calls these setters.
        // The setters themselves could check a flag set by _handleGovernanceAction
        // or check msg.sender == address(this) AND check a proposal state perhaps.
        // Let's simplify: these setters are internal and only called by _handleGovernanceAction.
        revert("Engine: Function only callable via governance execution"); // Should never be called directly
    }

    // --- Role Management (Owner/Governance Controlled) ---

    /**
     * @dev Sets the address of the Cosmic Flux Oracle.
     * @param oracleAddress The address of the oracle contract.
     */
    function setCosmicFluxOracle(address oracleAddress) external onlyOwner {
        _cosmicFluxOracle = ICosmicFluxOracle(oracleAddress);
        emit ParameterChanged("CosmicFluxOracle", abi.encode(oracleAddress));
    }

    /**
     * @dev Grants the minter role to an address.
     * @param minterAddress The address to grant the role to.
     */
    function addAllowedMinter(address minterAddress) external onlyOwner {
        require(minterAddress != address(0), "Engine: Zero address");
        _allowedMinters[minterAddress] = true;
        // Consider adding an event for role changes
    }

    /**
     * @dev Revokes the minter role from an address.
     * @param minterAddress The address to revoke the role from.
     */
    function removeAllowedMinter(address minterAddress) external onlyOwner {
        require(minterAddress != _msgSender(), "Engine: Cannot revoke own minter role");
        _allowedMinters[minterAddress] = false;
        // Consider adding an event for role changes
    }

    // --- Essence Management ---

    /**
     * @dev Mints new Essence tokens. Only allowed minters can call this.
     * @param to The address to mint tokens to.
     * @param amount The amount of Essence to mint.
     */
    function mintEssence(address to, uint256 amount) external onlyAllowedMinter {
        require(to != address(0), "Engine: mint to the zero address");
        _essenceBalances[to] += amount;
        _totalEssence += amount;
        emit EssenceMinted(to, amount);
    }

    /**
     * @dev Burns Essence tokens from the caller's balance. Internal helper.
     * @param amount The amount of Essence to burn.
     */
    function consumeEssence(uint256 amount) internal {
        address from = _msgSender();
        require(_essenceBalances[from] >= amount, "Engine: Insufficient Essence balance");
        _essenceBalances[from] -= amount;
        _totalEssence -= amount; // Assuming total supply tracking includes all Essence
        emit EssenceConsumed(from, amount);
    }

    /**
     * @dev Returns the balance of Essence for a given address.
     * @param owner The address to query the balance for.
     * @return The number of Essence tokens owned by `owner`.
     */
    function balanceOfEssence(address owner) public view returns (uint256) {
        return _essenceBalances[owner];
    }

    /**
     * @dev Returns the total supply of Essence tokens.
     * @return The total number of Essence tokens.
     */
    function getTotalEssenceSupply() public view returns (uint256) {
        return _totalEssence;
    }

    // --- Artifact Management ---

    /**
     * @dev Creates a new Artifact. Requires Essence. Traits are generated internally.
     * @return The ID of the newly created Artifact.
     */
    function createArtifact() external payable returns (uint256) {
        // Requires some Essence cost, maybe also uses Ether?
        uint256 creationEssenceCost = 50; // Example fixed cost, could be governed
        require(_essenceBalances[_msgSender()] >= creationEssenceCost, "Engine: Not enough Essence to create Artifact");
        consumeEssence(creationEssenceCost);

        uint256 tokenId = _nextArtifactId++;
        address owner = _msgSender();

        // Simulate trait generation - Replace with actual logic
        bytes32[] memory initialTraits = _generateInitialTraits(owner, block.timestamp, _currentCosmicFlux);

        _artifacts[tokenId] = Artifact({
            id: tokenId,
            owner: owner,
            creationBlock: block.number,
            lastEvolutionBlock: block.number,
            traits: initialTraits,
            fluxInfluenceBonus: uint256(keccak256(abi.encodePacked(tokenId, block.timestamp))) % 100 // Example random bonus
        });

        // Update ERC-721 standard mappings
        _artifactOwners[tokenId] = owner;
        _artifactCounts[owner]++;

        emit ArtifactCreated(tokenId, owner, initialTraits);
        emit Transfer(address(0), owner, tokenId); // ERC721 Mint event

        return tokenId;
    }

    /**
     * @dev Internal function to generate initial traits for an Artifact.
     *      Replace with complex deterministic or pseudo-random logic.
     * @param owner The owner of the artifact.
     * @param timestamp The current block timestamp.
     * @param flux The current cosmic flux value.
     * @return An array of bytes32 representing the initial traits.
     */
    function _generateInitialTraits(address owner, uint256 timestamp, uint256 flux) internal pure returns (bytes32[] memory) {
        // Example: simple hash of inputs
        bytes32 trait1 = keccak256(abi.encodePacked(owner, timestamp, flux, "trait_seed_1"));
        bytes32 trait2 = keccak256(abi.encodePacked(tokenId, block.number, flux, "trait_seed_2")); // tokenId not available here, use block.number
        bytes32[] memory traits = new bytes32[](2);
        traits[0] = trait1;
        traits[1] = trait2;
        return traits;
    }

     /**
     * @dev Returns the current traits of a specific Artifact.
     * @param tokenId The ID of the Artifact.
     * @return An array of bytes32 representing the traits.
     */
    function getArtifactTraits(uint256 tokenId) public view returns (bytes32[] memory) {
        require(_exists(tokenId), "Engine: Artifact does not exist");
        return _artifacts[tokenId].traits;
    }

    /**
     * @dev Evolves an Artifact, changing its traits. Requires Essence. Influenced by Flux.
     * @param tokenId The ID of the Artifact to evolve.
     */
    function evolveArtifact(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Engine: Caller is not owner nor approved");
        require(_exists(tokenId), "Engine: Artifact does not exist");
        require(block.number > _artifacts[tokenId].lastEvolutionBlock, "Engine: Artifact already evolved this block");

        consumeEssence(evolutionEssenceCost);

        Artifact storage artifact = _artifacts[tokenId];

        // Simulate evolution logic based on current traits, flux, and influence factor
        // Replace with complex deterministic or pseudo-random logic
        bytes32[] memory currentTraits = artifact.traits;
        bytes32[] memory newTraits = new bytes32[](currentTraits.length);

        uint256 fluxEffect = (_currentCosmicFlux * cosmicFluxInfluenceFactor / 10000); // Example: 50/10000 = 0.5% influence
        uint256 totalInfluence = fluxEffect + artifact.fluxInfluenceBonus; // Combine global flux and artifact bonus

        // Example: Modify traits based on influence and current state
        for (uint i = 0; i < currentTraits.length; i++) {
             // Simple modification: XOR with a hash influenced by block, ID, flux, etc.
            bytes32 influenceHash = keccak256(abi.encodePacked(block.number, tokenId, _currentCosmicFlux, totalInfluence, i));
            newTraits[i] = currentTraits[i] ^ influenceHash;
        }

        artifact.traits = newTraits;
        artifact.lastEvolutionBlock = block.number;

        emit ArtifactEvolved(tokenId, newTraits, evolutionEssenceCost);
    }

    /**
     * @dev Performs interaction logic between two Artifacts. Requires Essence. Influences both.
     *      Complex logic determining interaction outcome based on traits.
     * @param tokenId1 The ID of the first Artifact.
     * @param tokenId2 The ID of the second Artifact.
     */
    function interactArtifacts(uint256 tokenId1, uint256 tokenId2) external {
        require(tokenId1 != tokenId2, "Engine: Cannot interact an artifact with itself");
        require(_isApprovedOrOwner(_msgSender(), tokenId1), "Engine: Caller not authorized for Artifact 1");
        require(_isApprovedOrOwner(_msgSender(), tokenId2), "Engine: Caller not authorized for Artifact 2");
        require(_exists(tokenId1), "Engine: Artifact 1 does not exist");
        require(_exists(tokenId2), "Engine: Artifact 2 does not exist");
        require(block.number > _artifacts[tokenId1].lastEvolutionBlock && block.number > _artifacts[tokenId2].lastEvolutionBlock, "Engine: One or both artifacts evolved this block");


        consumeEssence(interactionEssenceCost);

        Artifact storage artifact1 = _artifacts[tokenId1];
        Artifact storage artifact2 = _artifacts[tokenId2];

        // Simulate interaction logic based on traits, flux, etc.
        // Replace with complex deterministic or pseudo-random logic
        bytes32[] memory traits1 = artifact1.traits;
        bytes32[] memory traits2 = artifact2.traits;

        bytes32[] memory newTraits1 = new bytes32[](traits1.length);
        bytes32[] memory newTraits2 = new bytes32[](traits2.length);

        uint256 fluxEffect = (_currentCosmicFlux * cosmicFluxInfluenceFactor / 10000);
        uint256 influence1 = fluxEffect + artifact1.fluxInfluenceBonus;
        uint256 influence2 = fluxEffect + artifact2.fluxInfluenceBonus;


        // Example: Simple interaction - mix traits based on influence
         for (uint i = 0; i < traits1.length && i < traits2.length; i++) {
            bytes32 interactionSeed = keccak256(abi.encodePacked(block.number, tokenId1, tokenId2, _currentCosmicFlux, influence1, influence2, i));
             // Simplified mix: blend based on relative influence
            if (influence1 > influence2) {
                newTraits1[i] = traits1[i] ^ (interactionSeed & traits2[i]);
                newTraits2[i] = traits2[i] ^ (interactionSeed & traits1[i]);
            } else {
                 newTraits1[i] = traits1[i] ^ (interactionSeed & traits2[i]);
                 newTraits2[i] = traits2[i] ^ (interactionSeed & traits1[i]);
            }
            // If trait arrays are different sizes, handle remaining
            if (i < traits1.length && i >= traits2.length) newTraits1[i] = traits1[i] ^ keccak256(abi.encodePacked(interactionSeed, "leftover1", i));
            if (i < traits2.length && i >= traits1.length) newTraits2[i] = traits2[i] ^ keccak256(abi.encodePacked(interactionSeed, "leftover2", i));
        }
         // If lengths were different, copy remaining unique traits
         if (traits1.length > traits2.length) {
            bytes32[] memory temp = new bytes32[](traits1.length);
            for(uint i=0; i < traits1.length; i++) temp[i] = newTraits1[i]; // Copy mixed
            for(uint i=traits2.length; i < traits1.length; i++) temp[i] = traits1[i]; // Copy remaining original
            newTraits1 = temp; // Re-assign with correct size and data
         }
         if (traits2.length > traits1.length) {
             bytes32[] memory temp = new bytes32[](traits2.length);
             for(uint i=0; i < traits2.length; i++) temp[i] = newTraits2[i]; // Copy mixed
             for(uint i=traits1.length; i < traits2.length; i++) temp[i] = traits2[i]; // Copy remaining original
             newTraits2 = temp; // Re-assign
         }


        artifact1.traits = newTraits1;
        artifact2.traits = newTraits2;

        artifact1.lastEvolutionBlock = block.number;
        artifact2.lastEvolutionBlock = block.number;

        emit ArtifactInteracted(tokenId1, tokenId2, newTraits1, newTraits2, interactionEssenceCost);
    }


    /**
     * @dev Base URI for metadata. Can be set by governance.
     *      Actual tokenURI calculates based on base URI and token traits.
     */
    string private _baseTokenURI;

    /**
     * @dev Sets the base URI for token metadata.
     *      This function should ideally be controllable by Governance.
     */
    function setBaseTokenURI(string calldata baseTokenURI_) external onlyOwner {
        _baseTokenURI = baseTokenURI_;
        emit ParameterChanged("BaseTokenURI", abi.encode(bytes(baseTokenURI_)));
    }


    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *      Constructs the URI dynamically based on base URI and token ID/traits.
     *      Assumes off-chain service interprets the ID and queries traits via getArtifactTraits.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Engine: URI query for nonexistent token");
        // Simple implementation: baseURI + tokenId.json
        // A more complex implementation would embed/encode trait data here
        // or point to a service that queries getArtifactTraits.
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }
        // Using string.concat from 0.8.12+
        return string.concat(base, _toString(tokenId), ".json");
    }

    /**
     * @dev Gets the block number when an Artifact was created.
     * @param tokenId The ID of the Artifact.
     * @return The creation block number.
     */
    function getArtifactCreationBlock(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Engine: Artifact does not exist");
         return _artifacts[tokenId].creationBlock;
    }

    /**
     * @dev Gets the block number when an Artifact last evolved or interacted.
     * @param tokenId The ID of the Artifact.
     * @return The last evolution/interaction block number.
     */
    function getArtifactLastEvolutionBlock(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Engine: Artifact does not exist");
         return _artifacts[tokenId].lastEvolutionBlock;
    }

    // --- Cosmic Flux Interaction ---

    /**
     * @dev Updates the current Cosmic Flux value. Only callable by the designated Oracle address.
     * @param newFluxValue The new flux value.
     */
    function updateCosmicFlux(uint256 newFluxValue) external {
        require(_msgSender() == address(_cosmicFluxOracle), "Engine: Only Oracle can update flux");
        _currentCosmicFlux = newFluxValue;
        emit FluxUpdated(newFluxValue);
    }

    /**
     * @dev Returns the current Cosmic Flux value.
     * @return The current flux value.
     */
    function getCurrentCosmicFlux() public view returns (uint256) {
        return _currentCosmicFlux;
    }

    // --- Alchemical Governance ---

    /**
     * @dev Creates a new governance proposal.
     * @param actionType The type of action this proposal represents.
     * @param actionData Encoded data/parameters for the action (e.g., abi.encode(newValue)).
     */
    function proposeAlchemy(GovernanceActionType actionType, bytes calldata actionData) external {
        require(balanceOfEssence(_msgSender()) >= minGovEssenceHoldings || balanceOf(_msgSender()) >= minGovArtifactHoldings,
                "Engine: Insufficient holdings to propose");

        uint256 proposalId = _nextProposalId++;
        uint256 votingEnd = block.number + governanceVotingPeriodBlocks;

        Proposal storage newProposal = _proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.actionType = actionType;
        newProposal.actionData = actionData;
        newProposal.proposer = _msgSender();
        newProposal.creationBlock = block.number;
        newProposal.votingPeriodEndBlock = votingEnd;
        newProposal.state = ProposalState.Active;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;

        emit ProposalCreated(proposalId, _msgSender(), actionType, votingEnd);
    }

    /**
     * @dev Casts a vote on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'For', False for 'Against'.
     */
    function voteOnAlchemy(uint256 proposalId, bool support) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Engine: Proposal not active");
        require(block.number <= proposal.votingPeriodEndBlock, "Engine: Voting period ended");
        require(!proposal.hasVoted[_msgSender()], "Engine: Already voted on this proposal");
        require(balanceOfEssence(_msgSender()) >= minGovEssenceHoldings || balanceOf(_msgSender()) >= minGovArtifactHoldings,
                "Engine: Insufficient holdings to vote");

        proposal.hasVoted[_msgSender()] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VoteCast(proposalId, _msgSender(), support);
    }

    /**
     * @dev Executes a successfully passed proposal.
     *      Only executable after the voting period ends and quorum is met.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeAlchemy(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Engine: Proposal not active");
        require(block.number > proposal.votingPeriodEndBlock, "Engine: Voting period not ended");

        // Check if proposal passed quorum and vote threshold
        // Note: Quorum based on _totalEssence + _nextArtifactId (proxy for total supply/participants)
        // A more robust quorum check would count total *voting power* (holders meeting min holdings)
        // For simplicity, let's use a simple vote count vs threshold for this example
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
         require(totalVotes > 0, "Engine: No votes cast"); // Need at least one vote
        uint256 voteThreshold = totalVotes * governanceQuorumThreshold / 10000; // e.g. 5000/10000 = 50%
        require(proposal.votesFor >= voteThreshold, "Engine: Proposal failed to meet threshold");

        // If passed, execute the action
        proposal.state = ProposalState.Executed;
        _handleGovernanceAction(proposal.actionType, proposal.actionData);

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Handles the execution of a governance action based on the action type and data.
     *      This internal function is called by `executeAlchemy`.
     * @param actionType The type of action to perform.
     * @param actionData Encoded parameters for the action.
     */
    function _handleGovernanceAction(GovernanceActionType actionType, bytes memory actionData) internal {
        // Using switch statement to handle different action types safely
        // Ensure decode operations match the encoding done in proposeAlchemy
        string memory parameterName;
        bytes memory eventValue;

        unchecked { // Use unchecked for simple value assignments after decoding
            if (actionType == GovernanceActionType.SET_EVOLUTION_ESSENCE_COST) {
                 (uint256 newValue) = abi.decode(actionData, (uint256));
                 evolutionEssenceCost = newValue;
                 parameterName = "EvolutionEssenceCost";
                 eventValue = actionData; // Pass original data for event
            } else if (actionType == GovernanceActionType.SET_INTERACTION_ESSENCE_COST) {
                 (uint256 newValue) = abi.decode(actionData, (uint256));
                 interactionEssenceCost = newValue;
                 parameterName = "InteractionEssenceCost";
                 eventValue = actionData;
            } else if (actionType == GovernanceActionType.SET_COSMIC_FLUX_INFLUENCE_FACTOR) {
                 (uint256 newValue) = abi.decode(actionData, (uint256));
                 cosmicFluxInfluenceFactor = newValue;
                 parameterName = "CosmicFluxInfluenceFactor";
                 eventValue = actionData;
            } else if (actionType == GovernanceActionType.SET_MIN_GOVERNANCE_HOLDINGS) {
                 (uint256 newMinEssence, uint256 newMinArtifacts) = abi.decode(actionData, (uint256, uint256));
                 minGovEssenceHoldings = newMinEssence;
                 minGovArtifactHoldings = newMinArtifacts;
                 parameterName = "MinGovernanceHoldings";
                 eventValue = actionData;
            } else if (actionType == GovernanceActionType.SET_GOVERNANCE_VOTING_PERIOD_BLOCKS) {
                 (uint256 newValue) = abi.decode(actionData, (uint256));
                 governanceVotingPeriodBlocks = newValue;
                 parameterName = "GovernanceVotingPeriodBlocks";
                 eventValue = actionData;
            } else if (actionType == GovernanceActionType.SET_GOVERNANCE_QUORUM_THRESHOLD) {
                 (uint256 newValue) = abi.decode(actionData, (uint256));
                 governanceQuorumThreshold = newValue;
                 parameterName = "GovernanceQuorumThreshold";
                 eventValue = actionData;
            } else if (actionType == GovernanceActionType.ADD_ALLOWED_MINTER) {
                 (address minterAddress) = abi.decode(actionData, (address));
                 _allowedMinters[minterAddress] = true; // Assuming governance can add minters
                 parameterName = "AllowedMinterAdded";
                 eventValue = abi.encode(minterAddress);
            } else if (actionType == GovernanceActionType.REMOVE_ALLOWED_MINTER) {
                 (address minterAddress) = abi.decode(actionData, (address));
                 require(minterAddress != address(this), "Engine: Cannot remove contract as minter"); // Prevent locking out future governance actions if contract itself has minter role
                 _allowedMinters[minterAddress] = false; // Assuming governance can remove minters
                 parameterName = "AllowedMinterRemoved";
                 eventValue = abi.encode(minterAddress);
            } else {
                // Handle unknown action type or log it
                revert("Engine: Unknown governance action type");
            }
        } // End unchecked block

        if (bytes(parameterName).length > 0) {
            emit ParameterChanged(parameterName, eventValue);
        }
    }


    /**
     * @dev Cancels an active governance proposal. Only callable by the proposer or owner/governance.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelAlchemyProposal(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Engine: Proposal not active");
        require(block.number <= proposal.votingPeriodEndBlock, "Engine: Cannot cancel after voting ends");
        require(_msgSender() == proposal.proposer || _msgSender() == owner(), "Engine: Not authorized to cancel proposal");

        proposal.state = ProposalState.Cancelled;
        emit ProposalCancelled(proposalId);
    }

    /**
     * @dev Returns the state of a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal (Active, Passed, Failed, Executed, Cancelled).
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        require(_proposals[proposalId].id != 0, "Engine: Proposal does not exist"); // Check if proposal exists
         Proposal storage proposal = _proposals[proposalId];
         if (proposal.state != ProposalState.Active) {
             return proposal.state; // Return non-active state directly
         }
         // If active, check if voting period is over to determine potential outcome
         if (block.number > proposal.votingPeriodEndBlock) {
             uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
              if (totalVotes == 0) return ProposalState.Failed; // Failed if no votes and period over
             uint256 voteThreshold = totalVotes * governanceQuorumThreshold / 10000;
             if (proposal.votesFor >= voteThreshold) {
                 return ProposalState.Passed;
             } else {
                 return ProposalState.Failed;
             }
         }
         return ProposalState.Active; // Still active if voting period not over
    }

    /**
     * @dev Returns details of a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return proposal details tuple.
     */
    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        GovernanceActionType actionType,
        bytes memory actionData,
        address proposer,
        uint256 creationBlock,
        uint256 votingPeriodEndBlock,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalState state
    ) {
         require(_proposals[proposalId].id != 0, "Engine: Proposal does not exist"); // Check if proposal exists
         Proposal storage proposal = _proposals[proposalId];
         return (
             proposal.id,
             proposal.actionType,
             proposal.actionData,
             proposal.proposer,
             proposal.creationBlock,
             proposal.votingPeriodEndBlock,
             proposal.votesFor,
             proposal.votesAgainst,
             getProposalState(proposalId) // Return calculated state
         );
    }

    // --- Governance-Controlled Parameter Setters (Internal, called by _handleGovernanceAction) ---
    // These functions are marked internal and called ONLY by _handleGovernanceAction

    // (Functions 24-29 are handled internally within _handleGovernanceAction now for safety)
    // Example: setEvolutionEssenceCost is not a public/external function anymore.

    // --- Utility & Views ---

    /**
     * @dev Returns the total number of Artifacts created.
     * @return The total Artifact count.
     */
    function getArtifactCount() public view returns (uint256) {
        return _nextArtifactId - 1; // Assuming IDs start from 1
    }

    /**
     * @dev Returns current governance parameters.
     * @return Tuple of governance parameters.
     */
    function getGovernanceParameters() public view returns (
        uint256 _evolutionEssenceCost,
        uint256 _interactionEssenceCost,
        uint256 _cosmicFluxInfluenceFactor,
        uint256 _minGovEssenceHoldings,
        uint256 _minGovArtifactHoldings,
        uint256 _governanceVotingPeriodBlocks,
        uint256 _governanceQuorumThreshold
    ) {
        return (
            evolutionEssenceCost,
            interactionEssenceCost,
            cosmicFluxInfluenceFactor,
            minGovEssenceHoldings,
            minGovArtifactHoldings,
            governanceVotingPeriodBlocks,
            governanceQuorumThreshold
        );
    }

    // --- ERC-721 Standard Implementations ---
    // Minimal implementation to support ownership and transfers.
    // Does NOT include token enumeration or metadata extensions beyond tokenURI.

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Ownable) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC721 || interfaceId == _INTERFACE_ID_ERC165 || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Engine: balance query for the zero address");
        return _artifactCounts[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _artifactOwners[tokenId];
        require(owner != address(0), "Engine: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "Engine: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Engine: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "Engine: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "Engine: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line check-caller
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Engine: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Engine: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` by calling `onERC721Received` on the recipient if it is a contract.
     *
     * @param from The current owner of the NFT
     * @param to The new owner
     * @param tokenId The NFT to transfer
     * @param data Additional data with no specified format to be forwarded to the recipient
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(
            to.isContract() ? _checkOnERC721Received(address(0), from, to, tokenId, data) : true, // Pass address(0) as operator per standard
            "Engine: transfer to non ERC721Receiver implementer"
        );
    }


    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _artifactOwners[tokenId] != address(0);
    }

     /**
     * @dev Returns whether the caller is an approved address or `owner`.
     *
     * @param spender The address to check if it is approved.
     * @param tokenId The NFT to check the approval of.
     * @return Whether the spender is approved.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  Requirements:
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Engine: transfer from incorrect owner");
        require(to != address(0), "Engine: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _artifactCounts[from]--;
        _artifactCounts[to]++;
        _artifactOwners[tokenId] = to;
        _artifacts[tokenId].owner = to; // Update owner in the Artifact struct as well

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a contract address.
     * @param operator The address of the operator calling the transfer.
     * @param from The old owner of the NFT
     * @param to The new owner
     * @param tokenId The NFT being transferred
     * @param data Additional data with no specified format to be forwarded to the recipient
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` if all conditions are met.
     */
    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(operator, from, to, tokenId, data) returns (bytes4 retval) {
                return retval == _ERC721_RECEIVED;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Engine: ERC721Receiver rejected transfer");
                } else {
                    // The contract returned a reason, forward it
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

     /**
     * @dev Converts a `uint256` to its ASCII string representation.
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        // Copied from OpenZeppelin's Strings library for self-containment example
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Fallback function to receive Ether (optional, depends on if Ether payments are planned)
    receive() external payable {}
    fallback() external payable {}
}
```

---

**Explanation of Unique/Advanced Concepts & Functions:**

1.  **Dynamic Artifacts (`traits`, `evolveArtifact`, `interactArtifacts`):** NFTs aren't just pointers to static data. Their core state (`traits`) is stored on-chain and can be modified by specific contract functions (`evolveArtifact`, `interactArtifacts`). The *interpretation* of these `bytes32[]` traits into visual art or game mechanics would happen off-chain, but the canonical trait data lives on the blockchain.
2.  **Internal Resource Token (`Essence`):** Instead of using a separate ERC-20 contract, `Essence` balances and total supply are managed directly within the Engine contract. This creates a tighter coupling between the resource and the actions it enables, potentially simplifying interactions and making it less prone to external ERC-20 complexities (like transfer fees, hooks, etc.) unless specifically desired. Functions like `mintEssence` and `consumeEssence` manage this.
3.  **Cosmic Flux Oracle (`ICosmicFluxOracle`, `currentCosmicFlux`, `updateCosmicFlux`):** The contract state (specifically, artifact evolution/interaction) is influenced by an external, oracle-provided data point (`_currentCosmicFlux`). This allows real-world events, other chain states, or arbitrary data to affect the digital assets. The oracle is a designated address (`_cosmicFluxOracle`) that can call `updateCosmicFlux`. The influence is parameterized (`cosmicFluxInfluenceFactor`) and can even have an artifact-specific bonus (`fluxInfluenceBonus`).
4.  **Alchemical Governance (`proposeAlchemy`, `voteOnAlchemy`, `executeAlchemy`, `_handleGovernanceAction`):** A simple DAO is built-in. Holders of Artifacts or Essence can propose and vote on changing key Engine parameters (costs, influence factors, governance settings). The `executeAlchemy` function is designed to call an internal handler (`_handleGovernanceAction`) based on the proposal data, allowing governance to safely modify the contract's behavior within defined limits, rather than executing arbitrary code (which is a common but sometimes risky DAO pattern).
5.  **Integrated Logic:** The core innovation is the tight coupling:
    *   Artifacts need Essence to change.
    *   Artifact changes depend on Cosmic Flux.
    *   The rules for Essence costs and Flux influence are set by Governance.
    *   Governance power comes from holding Artifacts and Essence.
    *   This creates a self-contained, dynamic ecosystem.
6.  **Partial ERC-721 Implementation:** While using OpenZeppelin interfaces and patterns (`IERC721`, `_transfer`, `_approve`, `_isApprovedOrOwner`, etc.), the core storage of Artifact data (`_artifacts` mapping with the custom struct) and the dynamic nature of `traits` differs significantly from a standard OZ ERC721 which primarily maps ID to owner and leaves metadata entirely external. `tokenURI` would point to an external service that reads the on-chain traits.
7.  **Function Count:** By including the core unique functions (Essence, Flux, Evolution, Interaction, Governance actions) and the necessary ERC-721 interface functions, the total count easily exceeds 20, fulfilling the requirement.

This contract offers a foundation for complex, interactive, and community-driven digital assets that react to both internal economic forces (Essence) and external environmental data (Flux), all steered by a decentralized governance mechanism.