This smart contract, `EtherealChimeras`, introduces a sophisticated ecosystem around dynamic NFTs. It envisions a world where digital creatures, "Chimeras," evolve based on a blend of on-chain activity, "AI-driven" rarity influence (simulated via an oracle), and direct community governance. Owners can guide their Chimera's development through various actions, engage in a staking-based voting system, and even contribute to the shared lore of the Ethereal Chimeras universe.

The contract implements a custom ERC721 token that stores several mutable attributes on-chain. It incorporates an epoch system to introduce global state changes, a proposal mechanism for community-driven attribute evolution, and a unique lore submission and approval system.

---

## EtherealChimeras Smart Contract

**Outline:**

The contract is structured into several logical sections:

1.  **Core NFT & Access Control:** Handles basic ERC721 functionality, token ownership, and defines roles for privileged actions (Admin, Minter, Oracle, Game Master).
2.  **Dynamic Chimera Attributes:** Defines the `Chimera` struct, which holds several mutable attributes like `power`, `intellect`, `spirit`, `genesisScore`, `alignment`, `xp`, and `evolutionStage`.
3.  **AI-Augmented Evolution (Simulated):** Incorporates an `ORACLE_ROLE` that can influence a Chimera's potential and development path by setting its `genesisScore`.
4.  **Community-Driven Evolution & Governance:** Implements a proposal system where Chimera holders can suggest attribute changes for their NFTs. A staking mechanism allows other holders to vote on these proposals, granting power based on staked Chimeras.
5.  **Lore & Narrative System:** Allows owners to submit unique lore snippets for their Chimeras, which can be approved by Game Masters to enrich the NFT's metadata and project's narrative.
6.  **Epoch System:** Introduces a global `epoch` counter that can trigger changes in game mechanics, attribute weightings, or evolution costs, simulating an evolving game world.
7.  **Pausable & Withdraw:** Standard utilities for contract security and fund management.

---

**Function Summary (25+ Custom Functions):**

**I. Core NFT & Access Control**
1.  `constructor()`: Initializes the contract with an admin, sets initial roles, and deploys the first epoch.
2.  `mintChimera(address to, uint256 genesisScoreSeed)`: Allows `MINTER_ROLE` to mint a new Chimera to an address with an initial `genesisScoreSeed`.
3.  `tokenURI(uint256 tokenId)`: Returns a dynamic metadata URI for a Chimera, reflecting its current attributes and approved lore.
4.  `setBaseURI(string memory newBaseURI)`: Allows `DEFAULT_ADMIN_ROLE` to update the base URL for metadata.
5.  `addMinter(address minter)`: Grants the `MINTER_ROLE` to a specified address.
6.  `removeMinter(address minter)`: Revokes the `MINTER_ROLE` from an address.
7.  `setOracleAddress(address oracle)`: Sets the address for the `ORACLE_ROLE`.
8.  `setGameMasterAddress(address gameMaster)`: Sets the address for the `GAME_MASTER_ROLE`.

**II. Dynamic Chimera Attributes & Evolution**
9.  `getChimera(uint256 tokenId)`: Public getter to retrieve all current attributes of a specific Chimera.
10. `updateGenesisScore(uint256 tokenId, uint256 newGenesisScore)`: `ORACLE_ROLE` only. Updates a Chimera's `genesisScore`, which influences its potential and evolution paths.
11. `evolveChimera(uint256 tokenId)`: Allows a Chimera owner to trigger an evolution, consuming ETH and modifying attributes based on `genesisScore` and `xp`.
12. `mutateChimera(uint256 tokenId, uint256 mutationSeed)`: Allows an owner to "mutate" their Chimera, potentially using a "Catalyst" (simulated by `mutationSeed`) to randomly alter an attribute.
13. `setChimeraAlignment(uint256 tokenId, ChimeraAlignment newAlignment)`: Owner can choose an `alignment` for their Chimera, affecting future interactions or attribute bonuses.
14. `addChimeraXP(uint256 tokenId, uint256 amount)`: `GAME_MASTER_ROLE` only. Adds experience points to a Chimera, crucial for evolution.

**III. Community-Driven Governance**
15. `proposeAttributeChange(uint256 tokenId, AttributeType attributeType, int256 changeValue)`: A Chimera owner can propose an attribute change for their Chimera (e.g., +10 Power, -5 Intellect).
16. `voteOnProposal(uint256 proposalId, bool support)`: Allows owners of staked Chimeras to vote for or against a proposal. Voting power is proportional to the number of Chimeras staked.
17. `executeProposal(uint256 proposalId)`: After a proposal's voting period ends and it passes, the owner of the target Chimera can execute it to apply the attribute changes.
18. `stakeChimeraForVoting(uint256 tokenId)`: Locks a Chimera, granting its owner voting power for proposals.
19. `unstakeChimeraFromVoting(uint256 tokenId)`: Unlocks a staked Chimera, removing its voting power.
20. `getProposal(uint256 proposalId)`: Public getter for details of a specific proposal.

**IV. Lore & Narrative System**
21. `submitLoreSnippet(uint256 tokenId, string memory snippet)`: Allows a Chimera owner to submit a short lore snippet for their NFT.
22. `approveLoreSnippet(uint256 snippetId)`: `GAME_MASTER_ROLE` only. Approves a submitted lore snippet, linking it permanently to the Chimera's metadata.
23. `getApprovedLoreSnippet(uint256 tokenId)`: Public getter to retrieve the approved lore for a Chimera.

**V. Epoch & Global State Management**
24. `advanceEpoch()`: `DEFAULT_ADMIN_ROLE` or time-based. Moves the contract to the next epoch, potentially changing game rules or attribute influences.
25. `setEpochConfig(uint256 epochNum, uint256 proposalVoteDuration, uint256 evolutionEssenceCost, uint256 minXpForEvolution, uint256 minEvolutionStageInterval)`: `DEFAULT_ADMIN_ROLE` only. Configures parameters for a specific epoch.
26. `getEpochConfig(uint256 epochNum)`: Public getter for epoch configuration details.

**VI. Utilities**
27. `pause()`: `DEFAULT_ADMIN_ROLE` only. Pauses critical contract functions for maintenance or emergency.
28. `unpause()`: `DEFAULT_ADMIN_ROLE` only. Unpauses the contract.
29. `withdrawFunds()`: `DEFAULT_ADMIN_ROLE` only. Allows the admin to withdraw collected ETH (from evolution costs).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title EtherealChimeras
 * @dev A dynamic NFT ecosystem where Chimeras evolve based on AI-influenced rarity,
 *      community governance, and an epoch-driven game state.
 *
 * Outline:
 * I. Core NFT & Access Control: ERC721 compliance, role management (Admin, Minter, Oracle, Game Master).
 * II. Dynamic Chimera Attributes: Structs for mutable NFT attributes (power, intellect, spirit, genesisScore, alignment, xp, evolutionStage).
 * III. AI-Augmented Evolution (Simulated): Oracle role influences Chimera potential via 'genesisScore'.
 * IV. Community-Driven Evolution & Governance: Staking-based voting system for attribute change proposals.
 * V. Lore & Narrative System: Owners submit lore, Game Masters approve to enrich metadata.
 * VI. Epoch System: Global state changes based on 'epochs' affecting game mechanics.
 * VII. Pausable & Withdraw: Standard utilities for contract security and fund management.
 *
 * Function Summary (25+ Custom Functions):
 * I. Core NFT & Access Control
 *    1. constructor(): Initializes roles, first epoch.
 *    2. mintChimera(address to, uint256 genesisScoreSeed): Mints a new Chimera.
 *    3. tokenURI(uint256 tokenId): Dynamic metadata URI.
 *    4. setBaseURI(string memory newBaseURI): Updates metadata base URI.
 *    5. addMinter(address minter): Grants MINTER_ROLE.
 *    6. removeMinter(address minter): Revokes MINTER_ROLE.
 *    7. setOracleAddress(address oracle): Sets ORACLE_ROLE.
 *    8. setGameMasterAddress(address gameMaster): Sets GAME_MASTER_ROLE.
 * II. Dynamic Chimera Attributes & Evolution
 *    9. getChimera(uint256 tokenId): Retrieves all Chimera attributes.
 *    10. updateGenesisScore(uint256 tokenId, uint256 newGenesisScore): Oracle updates AI-influenced score.
 *    11. evolveChimera(uint256 tokenId): Triggers Chimera evolution.
 *    12. mutateChimera(uint256 tokenId, uint256 mutationSeed): Mutates a Chimera's attribute.
 *    13. setChimeraAlignment(uint256 tokenId, ChimeraAlignment newAlignment): Sets Chimera's alignment.
 *    14. addChimeraXP(uint256 tokenId, uint256 amount): Game Master adds XP.
 * III. Community-Driven Governance
 *    15. proposeAttributeChange(uint256 tokenId, AttributeType attributeType, int256 changeValue): Proposes an attribute change.
 *    16. voteOnProposal(uint256 proposalId, bool support): Casts a vote on a proposal.
 *    17. executeProposal(uint256 proposalId): Executes a passed proposal.
 *    18. stakeChimeraForVoting(uint256 tokenId): Stakes a Chimera for voting.
 *    19. unstakeChimeraFromVoting(uint256 tokenId): Unstakes a Chimera.
 *    20. getProposal(uint256 proposalId): Retrieves proposal details.
 * IV. Lore & Narrative System
 *    21. submitLoreSnippet(uint256 tokenId, string memory snippet): Submits lore for a Chimera.
 *    22. approveLoreSnippet(uint256 snippetId): Game Master approves lore.
 *    23. getApprovedLoreSnippet(uint256 tokenId): Retrieves approved lore.
 * V. Epoch & Global State Management
 *    24. advanceEpoch(): Advances to the next epoch.
 *    25. setEpochConfig(uint256 epochNum, ...): Configures epoch parameters.
 *    26. getEpochConfig(uint256 epochNum): Retrieves epoch configuration.
 * VI. Utilities
 *    27. pause(): Pauses contract.
 *    28. unpause(): Unpauses contract.
 *    29. withdrawFunds(): Admin withdraws ETH.
 */
contract EtherealChimeras is ERC721, AccessControl, Pausable {
    using Counters for Counters.Counter;

    // --- Access Control Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant GAME_MASTER_ROLE = keccak256("GAME_MASTER_ROLE");

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _loreSnippetIdCounter;

    string private _baseTokenURI;

    // Current epoch number
    uint256 public currentEpoch;

    // --- Enums ---
    enum ChimeraAlignment {
        Neutral,
        Order,
        Chaos,
        Balance
    }

    enum AttributeType {
        Power,
        Intellect,
        Spirit,
        Agility
    }

    // --- Structs ---

    struct Chimera {
        uint256 genesisScore; // Influences potential and evolution paths
        uint256 power;
        uint256 intellect;
        uint256 spirit;
        uint256 agility;
        ChimeraAlignment alignment;
        uint256 xp; // Experience points, crucial for evolution
        uint256 evolutionStage; // 0 for base, increments with evolution
        uint256 lastEvolutionTime; // Timestamp of last evolution
        uint256 lastLoreSnippetId; // Reference to the last approved lore update
    }

    struct Proposal {
        uint256 tokenId; // The Chimera target for the proposal
        AttributeType attributeType; // The attribute to be changed
        int256 changeValue; // The value to add/subtract to the attribute
        address proposer; // Address that created the proposal
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed; // True if the proposal has been applied
    }

    struct EpochConfig {
        uint256 proposalVoteDuration; // How long a proposal vote lasts (in seconds)
        uint256 evolutionEssenceCost; // ETH cost for evolution
        uint256 minXpForEvolution; // Minimum XP required for an evolution
        uint256 minEvolutionStageInterval; // Minimum time between evolutions (in seconds)
        // Future: could add attribute weighting factors here
    }

    struct LoreSnippet {
        uint256 tokenId;
        address submitter;
        string snippet;
        bool approved;
    }

    // --- Mappings ---
    mapping(uint256 => Chimera) public chimeras;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted
    mapping(uint256 => bool) public isChimeraStaked; // tokenId => isStaked
    mapping(address => uint256[]) public stakedChimeras; // owner => list of staked tokenIds

    mapping(uint256 => EpochConfig) public epochConfigs; // epochNum => config
    mapping(uint256 => LoreSnippet) public loreSnippets;

    // --- Events ---
    event ChimeraMinted(uint256 indexed tokenId, address indexed owner, uint256 genesisScore);
    event GenesisScoreUpdated(uint256 indexed tokenId, uint256 newGenesisScore);
    event ChimeraEvolved(uint256 indexed tokenId, address indexed owner, uint256 newEvolutionStage);
    event ChimeraMutated(uint256 indexed tokenId, address indexed owner, AttributeType indexed attribute, int256 changeValue);
    event AlignmentChanged(uint256 indexed tokenId, ChimeraAlignment newAlignment);
    event XPAdded(uint256 indexed tokenId, uint256 amount, uint256 newXP);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed tokenId, AttributeType indexed attribute, int256 changeValue, address proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, uint256 indexed tokenId);
    event ChimeraStaked(uint256 indexed tokenId, address indexed owner);
    event ChimeraUnstaked(uint256 indexed tokenId, address indexed owner);
    event LoreSubmitted(uint256 indexed snippetId, uint256 indexed tokenId, address indexed submitter);
    event LoreApproved(uint256 indexed snippetId, uint256 indexed tokenId, address indexed approver);
    event EpochAdvanced(uint256 newEpoch);
    event EpochConfigUpdated(uint256 indexed epochNum);

    // --- Custom Errors ---
    error NotMinter();
    error NotOracle();
    error NotGameMaster();
    error NotOwner();
    error InvalidTokenId();
    error InvalidAlignment();
    error EvolutionTooSoon();
    error NotEnoughXPForEvolution();
    error EvolutionFailed();
    error NotEnoughEssence();
    error NotEnoughVotingPower();
    error AlreadyStaked();
    error NotStaked();
    error ProposalNotFound();
    error ProposalAlreadyExecuted();
    error VotingPeriodActive();
    error VotingPeriodOver();
    error AlreadyVoted();
    error ProposalFailedToPass();
    error LoreSnippetNotFound();
    error LoreSnippetAlreadyApproved();

    /**
     * @dev Constructor to initialize the contract.
     * @param admin The address to be granted DEFAULT_ADMIN_ROLE.
     * @param minter The address to be granted MINTER_ROLE.
     * @param oracle The address to be granted ORACLE_ROLE.
     * @param gameMaster The address to be granted GAME_MASTER_ROLE.
     */
    constructor(
        address admin,
        address minter,
        address oracle,
        address gameMaster
    ) ERC721("Ethereal Chimeras", "ECHIM") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(ORACLE_ROLE, oracle);
        _grantRole(GAME_MASTER_ROLE, gameMaster);

        currentEpoch = 1;
        // Set initial epoch configuration
        epochConfigs[currentEpoch] = EpochConfig({
            proposalVoteDuration: 3 days,
            evolutionEssenceCost: 0.05 ether, // 0.05 ETH
            minXpForEvolution: 100,
            minEvolutionStageInterval: 7 days // 1 week
        });
        emit EpochConfigUpdated(currentEpoch);
    }

    // --- I. Core NFT & Access Control ---

    /**
     * @dev See {ERC721-_baseURI}. This contract uses a configurable base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Sets the base URI for all token URIs.
     *      Can only be called by an account with the `DEFAULT_ADMIN_ROLE`.
     * @param newBaseURI The new base URI to set.
     */
    function setBaseURI(string memory newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @dev Mints a new Chimera token.
     *      Initial attributes are set, `genesisScore` is provided by minter/oracle.
     *      Can only be called by an account with the `MINTER_ROLE`.
     * @param to The address to mint the token to.
     * @param genesisScoreSeed An initial score from external 'AI' or a random seed.
     */
    function mintChimera(address to, uint256 genesisScoreSeed) public onlyRole(MINTER_ROLE) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId);

        chimeras[newTokenId] = Chimera({
            genesisScore: genesisScoreSeed,
            power: (genesisScoreSeed % 100) + 50, // Base stats, somewhat random
            intellect: (genesisScoreSeed % 100) + 50,
            spirit: (genesisScoreSeed % 100) + 50,
            agility: (genesisScoreSeed % 100) + 50,
            alignment: ChimeraAlignment.Neutral,
            xp: 0,
            evolutionStage: 0,
            lastEvolutionTime: block.timestamp,
            lastLoreSnippetId: 0
        });

        emit ChimeraMinted(newTokenId, to, genesisScoreSeed);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *      This URI is dynamic, reflecting the Chimera's current attributes and approved lore.
     * @param tokenId The ID of the token to query.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        // Construct a dynamic JSON object that includes all Chimera attributes
        // This relies on an off-chain service to interpret the JSON and render the image/metadata.
        // Example: https://base_uri/tokenId.json
        // The JSON content could be generated here or off-chain.
        // For on-chain generation:
        // Concatenate string parts for JSON (highly gas intensive for complex JSON)
        // A more practical approach for complex JSON is to return a URI pointing to a server
        // that queries the contract's state for this tokenId and builds the JSON.
        // For this example, we'll return a simple URI with base data, assuming off-chain rendering handles the rest.

        string memory json = string(
            abi.encodePacked(
                '{"name": "Chimera #', Strings.toString(tokenId), '",',
                '"description": "An Ethereal Chimera with dynamic attributes and evolving lore.",',
                '"image": "', _baseTokenURI, 'images/', Strings.toString(tokenId), '.png",',
                '"attributes": [',
                '{"trait_type": "Power", "value": ', Strings.toString(chimeras[tokenId].power), '},',
                '{"trait_type": "Intellect", "value": ', Strings.toString(chimeras[tokenId].intellect), '},',
                '{"trait_type": "Spirit", "value": ', Strings.toString(chimeras[tokenId].spirit), '},',
                '{"trait_type": "Agility", "value": ', Strings.toString(chimeras[tokenId].agility), '},',
                '{"trait_type": "Genesis Score", "value": ', Strings.toString(chimeras[tokenId].genesisScore), '},',
                '{"trait_type": "Alignment", "value": "', _getAlignmentString(chimeras[tokenId].alignment), '"},',
                '{"trait_type": "XP", "value": ', Strings.toString(chimeras[tokenId].xp), '},',
                '{"trait_type": "Evolution Stage", "value": ', Strings.toString(chimeras[tokenId].evolutionStage), '}',
                _getApprovedLoreSnippetJson(tokenId), // Append lore if available
                ']}'
            )
        );

        // Encode the JSON string to base64 and prepend data URI scheme
        // This is gas-intensive and usually avoided for large JSONs, but demonstrates on-chain metadata.
        // In practice, _baseTokenURI would point to a metadata server, e.g., "https://api.chimeras.com/metadata/"
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function _getAlignmentString(ChimeraAlignment alignment) internal pure returns (string memory) {
        if (alignment == ChimeraAlignment.Order) return "Order";
        if (alignment == ChimeraAlignment.Chaos) return "Chaos";
        if (alignment == ChimeraAlignment.Balance) return "Balance";
        return "Neutral";
    }

    function _getApprovedLoreSnippetJson(uint256 tokenId) internal view returns (string memory) {
        uint256 snippetId = chimeras[tokenId].lastLoreSnippetId;
        if (snippetId > 0 && loreSnippets[snippetId].approved) {
            return string(abi.encodePacked(
                ',{"trait_type": "Lore", "value": "', loreSnippets[snippetId].snippet, '"}'
            ));
        }
        return "";
    }

    /**
     * @dev Grants the MINTER_ROLE to a specified address.
     *      Can only be called by an account with the `DEFAULT_ADMIN_ROLE`.
     * @param minter The address to grant the role to.
     */
    function addMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, minter);
    }

    /**
     * @dev Revokes the MINTER_ROLE from a specified address.
     *      Can only be called by an account with the `DEFAULT_ADMIN_ROLE`.
     * @param minter The address to revoke the role from.
     */
    function removeMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
    }

    /**
     * @dev Sets the address for the ORACLE_ROLE.
     *      Can only be called by an account with the `DEFAULT_ADMIN_ROLE`.
     * @param oracle The address to set as the oracle.
     */
    function setOracleAddress(address oracle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ORACLE_ROLE, oracle);
    }

    /**
     * @dev Sets the address for the GAME_MASTER_ROLE.
     *      Can only be called by an account with the `DEFAULT_ADMIN_ROLE`.
     * @param gameMaster The address to set as the game master.
     */
    function setGameMasterAddress(address gameMaster) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(GAME_MASTER_ROLE, gameMaster);
    }

    // --- II. Dynamic Chimera Attributes & Evolution ---

    /**
     * @dev Retrieves all current dynamic attributes of a Chimera.
     * @param tokenId The ID of the Chimera.
     * @return Chimera struct containing all attributes.
     */
    function getChimera(uint256 tokenId) public view returns (Chimera memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return chimeras[tokenId];
    }

    /**
     * @dev Oracle-only function to update a Chimera's `genesisScore`.
     *      This simulates an "AI" influence on the Chimera's base potential.
     *      Can only be called by an account with the `ORACLE_ROLE`.
     * @param tokenId The ID of the Chimera to update.
     * @param newGenesisScore The new genesis score.
     */
    function updateGenesisScore(uint256 tokenId, uint256 newGenesisScore) public onlyRole(ORACLE_ROLE) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        chimeras[tokenId].genesisScore = newGenesisScore;
        emit GenesisScoreUpdated(tokenId, newGenesisScore);
    }

    /**
     * @dev Allows a Chimera owner to trigger an evolution.
     *      Requires a certain amount of ETH (`evolutionEssenceCost`) and `minXpForEvolution`.
     *      Evolution advances the `evolutionStage` and potentially buffs attributes.
     *      Cannot evolve if `minEvolutionStageInterval` has not passed since last evolution.
     * @param tokenId The ID of the Chimera to evolve.
     */
    function evolveChimera(uint256 tokenId) public payable whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert NotOwner();

        EpochConfig memory config = epochConfigs[currentEpoch];
        if (msg.value < config.evolutionEssenceCost) revert NotEnoughEssence();
        if (chimeras[tokenId].xp < config.minXpForEvolution) revert NotEnoughXPForEvolution();
        if (block.timestamp < chimeras[tokenId].lastEvolutionTime + config.minEvolutionStageInterval) revert EvolutionTooSoon();

        Chimera storage chimera = chimeras[tokenId];

        // Consume XP
        chimera.xp -= config.minXpForEvolution;

        // Apply evolution changes
        chimera.evolutionStage += 1;
        chimera.power += 5 + (chimera.genesisScore % 5); // Example: Buffs based on genesisScore
        chimera.intellect += 5 + (chimera.genesisScore % 5);
        chimera.spirit += 5 + (chimera.genesisScore % 5);
        chimera.agility += 5 + (chimera.genesisScore % 5);
        chimera.lastEvolutionTime = block.timestamp;

        emit ChimeraEvolved(tokenId, msg.sender, chimera.evolutionStage);
    }

    /**
     * @dev Allows an owner to "mutate" their Chimera, potentially using a "Catalyst" (simulated by `mutationSeed`).
     *      A random attribute is selected and changed based on the `mutationSeed`.
     *      This could be tied to an ERC1155 "Catalyst" token in a full implementation.
     * @param tokenId The ID of the Chimera to mutate.
     * @param mutationSeed A seed value influencing the mutation outcome (e.g., from an external source or RNG).
     */
    function mutateChimera(uint256 tokenId, uint256 mutationSeed) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert NotOwner();

        Chimera storage chimera = chimeras[tokenId];

        // Determine which attribute to mutate based on mutationSeed
        uint256 attributeIndex = mutationSeed % 4; // 0=Power, 1=Intellect, 2=Spirit, 3=Agility
        int256 changeValue = (int256(mutationSeed % 21) - 10); // Change between -10 and +10

        AttributeType mutatedAttribute;

        if (attributeIndex == 0) {
            chimera.power = uint256(int256(chimera.power) + changeValue);
            mutatedAttribute = AttributeType.Power;
        } else if (attributeIndex == 1) {
            chimera.intellect = uint256(int256(chimera.intellect) + changeValue);
            mutatedAttribute = AttributeType.Intellect;
        } else if (attributeIndex == 2) {
            chimera.spirit = uint256(int256(chimera.spirit) + changeValue);
            mutatedAttribute = AttributeType.Spirit;
        } else { // attributeIndex == 3
            chimera.agility = uint256(int256(chimera.agility) + changeValue);
            mutatedAttribute = AttributeType.Agility;
        }

        emit ChimeraMutated(tokenId, msg.sender, mutatedAttribute, changeValue);
    }

    /**
     * @dev Allows an owner to set their Chimera's alignment.
     *      Alignment could influence future interactions, special bonuses, or trait changes.
     * @param tokenId The ID of the Chimera.
     * @param newAlignment The desired new alignment.
     */
    function setChimeraAlignment(uint256 tokenId, ChimeraAlignment newAlignment) public {
        if (ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (newAlignment == ChimeraAlignment.Neutral && chimeras[tokenId].alignment != ChimeraAlignment.Neutral) {
            // Logic to prevent going back to Neutral easily, or maybe it costs something.
            // For now, allow it.
        }
        chimeras[tokenId].alignment = newAlignment;
        emit AlignmentChanged(tokenId, newAlignment);
    }

    /**
     * @dev Game Master-only function to add experience points to a Chimera.
     *      XP is crucial for evolution and other in-game progression.
     *      Can only be called by an account with the `GAME_MASTER_ROLE`.
     * @param tokenId The ID of the Chimera to add XP to.
     * @param amount The amount of XP to add.
     */
    function addChimeraXP(uint256 tokenId, uint256 amount) public onlyRole(GAME_MASTER_ROLE) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        chimeras[tokenId].xp += amount;
        emit XPAdded(tokenId, amount, chimeras[tokenId].xp);
    }

    // --- III. Community-Driven Governance ---

    /**
     * @dev Allows a Chimera holder to propose a specific attribute change for *their* Chimera.
     *      Proposals are then voted upon by other staked Chimera holders.
     * @param tokenId The ID of the Chimera for which the change is proposed.
     * @param attributeType The type of attribute to change (e.g., Power, Intellect).
     * @param changeValue The value to add or subtract from the attribute (can be negative).
     */
    function proposeAttributeChange(
        uint256 tokenId,
        AttributeType attributeType,
        int256 changeValue
    ) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert NotOwner();

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        EpochConfig memory config = epochConfigs[currentEpoch];

        proposals[newProposalId] = Proposal({
            tokenId: tokenId,
            attributeType: attributeType,
            changeValue: changeValue,
            proposer: msg.sender,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + config.proposalVoteDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });

        emit ProposalCreated(newProposalId, tokenId, attributeType, changeValue, msg.sender);
    }

    /**
     * @dev Allows owners of staked Chimeras to vote on a proposal.
     *      Voting power is proportional to the number of Chimeras staked by the voter.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'for' vote, false for 'against'.
     */
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (block.timestamp < proposal.voteStartTime || block.timestamp > proposal.voteEndTime) revert VotingPeriodOver();
        if (hasVoted[proposalId][msg.sender]) revert AlreadyVoted();

        uint256 votingPower = stakedChimeras[msg.sender].length;
        if (votingPower == 0) revert NotEnoughVotingPower();

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        hasVoted[proposalId][msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }

    /**
     * @dev Executes a proposal if its voting period has ended and it passed.
     *      Can only be called by the owner of the target Chimera.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (block.timestamp <= proposal.voteEndTime) revert VotingPeriodActive(); // Voting period must be over
        if (ownerOf(proposal.tokenId) != msg.sender) revert NotOwner(); // Only owner of target Chimera can execute

        // Check if proposal passed (e.g., more 'for' votes than 'against')
        if (proposal.votesFor <= proposal.votesAgainst) revert ProposalFailedToPass();

        Chimera storage chimera = chimeras[proposal.tokenId];

        if (proposal.attributeType == AttributeType.Power) {
            chimera.power = uint256(int256(chimera.power) + proposal.changeValue);
        } else if (proposal.attributeType == AttributeType.Intellect) {
            chimera.intellect = uint256(int256(chimera.intellect) + proposal.changeValue);
        } else if (proposal.attributeType == AttributeType.Spirit) {
            chimera.spirit = uint256(int256(chimera.spirit) + proposal.changeValue);
        } else if (proposal.attributeType == AttributeType.Agility) {
            chimera.agility = uint256(int255(chimera.agility) + proposal.changeValue);
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId, proposal.tokenId);
    }

    /**
     * @dev Allows a Chimera owner to stake their token for voting power.
     *      Staked tokens cannot be transferred.
     * @param tokenId The ID of the Chimera to stake.
     */
    function stakeChimeraForVoting(uint256 tokenId) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (isChimeraStaked[tokenId]) revert AlreadyStaked();

        isChimeraStaked[tokenId] = true;
        stakedChimeras[msg.sender].push(tokenId); // Add to the owner's list of staked tokens

        emit ChimeraStaked(tokenId, msg.sender);
    }

    /**
     * @dev Allows a Chimera owner to unstake their token, removing its voting power.
     * @param tokenId The ID of the Chimera to unstake.
     */
    function unstakeChimeraFromVoting(uint256 tokenId) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (!isChimeraStaked[tokenId]) revert NotStaked();

        isChimeraStaked[tokenId] = false;

        // Remove from the owner's list of staked tokens
        uint256[] storage ownerStaked = stakedChimeras[msg.sender];
        for (uint256 i = 0; i < ownerStaked.length; i++) {
            if (ownerStaked[i] == tokenId) {
                ownerStaked[i] = ownerStaked[ownerStaked.length - 1]; // Swap with last element
                ownerStaked.pop(); // Remove last element
                break;
            }
        }
        emit ChimeraUnstaked(tokenId, msg.sender);
    }

    /**
     * @dev Retrieves the details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return Proposal struct containing all details.
     */
    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
        if (proposals[proposalId].proposer == address(0)) revert ProposalNotFound();
        return proposals[proposalId];
    }

    // --- IV. Lore & Narrative System ---

    /**
     * @dev Allows a Chimera owner to submit a short lore snippet for their NFT.
     *      The snippet needs `GAME_MASTER_ROLE` approval to be linked to the NFT metadata.
     * @param tokenId The ID of the Chimera the lore is for.
     * @param snippet The lore text.
     */
    function submitLoreSnippet(uint256 tokenId, string memory snippet) public {
        if (ownerOf(tokenId) != msg.sender) revert NotOwner();
        _loreSnippetIdCounter.increment();
        uint256 newSnippetId = _loreSnippetIdCounter.current();

        loreSnippets[newSnippetId] = LoreSnippet({
            tokenId: tokenId,
            submitter: msg.sender,
            snippet: snippet,
            approved: false
        });

        emit LoreSubmitted(newSnippetId, tokenId, msg.sender);
    }

    /**
     * @dev Game Master-only function to approve a submitted lore snippet.
     *      Approved lore snippets will be included in the Chimera's `tokenURI` metadata.
     *      Can only be called by an account with the `GAME_MASTER_ROLE`.
     * @param snippetId The ID of the lore snippet to approve.
     */
    function approveLoreSnippet(uint256 snippetId) public onlyRole(GAME_MASTER_ROLE) {
        LoreSnippet storage lore = loreSnippets[snippetId];
        if (lore.submitter == address(0)) revert LoreSnippetNotFound();
        if (lore.approved) revert LoreSnippetAlreadyApproved();

        lore.approved = true;
        chimeras[lore.tokenId].lastLoreSnippetId = snippetId; // Link approved lore to the Chimera

        emit LoreApproved(snippetId, lore.tokenId, msg.sender);
    }

    /**
     * @dev Retrieves the last approved lore snippet for a Chimera.
     * @param tokenId The ID of the Chimera.
     * @return The lore snippet string.
     */
    function getApprovedLoreSnippet(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        uint256 snippetId = chimeras[tokenId].lastLoreSnippetId;
        if (snippetId > 0 && loreSnippets[snippetId].approved) {
            return loreSnippets[snippetId].snippet;
        }
        return ""; // Return empty string if no approved lore
    }

    // --- V. Epoch & Global State Management ---

    /**
     * @dev Advances the contract to the next epoch.
     *      Can only be called by `DEFAULT_ADMIN_ROLE` or based on time.
     *      This could trigger global rule changes, attribute shifts, etc.
     */
    function advanceEpoch() public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        currentEpoch += 1;
        // Optionally copy previous epoch config or set a default new one if not explicitly configured
        if (epochConfigs[currentEpoch].proposalVoteDuration == 0) {
            epochConfigs[currentEpoch] = EpochConfig({
                proposalVoteDuration: 3 days,
                evolutionEssenceCost: 0.05 ether,
                minXpForEvolution: 100 + (currentEpoch * 10), // Increase XP requirement over epochs
                minEvolutionStageInterval: 7 days
            });
        }
        emit EpochAdvanced(currentEpoch);
        emit EpochConfigUpdated(currentEpoch);
    }

    /**
     * @dev Allows `DEFAULT_ADMIN_ROLE` to update the configuration for a specific epoch.
     * @param epochNum The epoch number to configure.
     * @param proposalVoteDuration Duration for voting in seconds.
     * @param evolutionEssenceCost ETH cost for evolution.
     * @param minXpForEvolution Minimum XP for evolution.
     * @param minEvolutionStageInterval Minimum time between evolutions in seconds.
     */
    function setEpochConfig(
        uint256 epochNum,
        uint256 proposalVoteDuration,
        uint256 evolutionEssenceCost,
        uint256 minXpForEvolution,
        uint256 minEvolutionStageInterval
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        epochConfigs[epochNum] = EpochConfig({
            proposalVoteDuration: proposalVoteDuration,
            evolutionEssenceCost: evolutionEssenceCost,
            minXpForEvolution: minXpForEvolution,
            minEvolutionStageInterval: minEvolutionStageInterval
        });
        emit EpochConfigUpdated(epochNum);
    }

    /**
     * @dev Retrieves the configuration for a specific epoch.
     * @param epochNum The epoch number.
     * @return EpochConfig struct.
     */
    function getEpochConfig(uint256 epochNum) public view returns (EpochConfig memory) {
        return epochConfigs[epochNum];
    }

    // --- VI. Utilities ---

    /**
     * @dev Pauses the contract, preventing certain critical functions from being called.
     *      Can only be called by an account with the `DEFAULT_ADMIN_ROLE`.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing previously paused functions to be called again.
     *      Can only be called by an account with the `DEFAULT_ADMIN_ROLE`.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Allows the `DEFAULT_ADMIN_ROLE` to withdraw any collected ETH (e.g., from evolution costs).
     */
    function withdrawFunds() public onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Failed to withdraw Ether");
    }

    /**
     * @dev See {IERC721-onERC721Received}.
     *      This function ensures that staked tokens cannot be transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (isChimeraStaked[tokenId]) {
            revert("Staked tokens cannot be transferred");
        }
    }

    /**
     * @dev Fallback function to prevent accidental ETH transfers to the contract
     *      unless it's for `evolveChimera`.
     */
    receive() external payable {
        // Allow ETH for evolveChimera specifically, otherwise revert
        if (msg.sender != address(0) && msg.data.length == 0) {
            revert NotEnoughEssence(); // Or a more specific error
        }
    }
}

// Minimal Base64 encoder for data URIs
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load not more than 96 bytes at a time into the stack
        bytes memory buffer = new bytes(data.length * 4 / 3 + 3);
        uint256 count = 0;
        uint256 i = 0;
        while (i < data.length - 2) {
            uint256 input = (uint256(data[i]) << 16) | (uint256(data[i + 1]) << 8) | uint256(data[i + 2]);
            buffer[count] = TABLE[(input >> 18) & 0x3F];
            buffer[count + 1] = TABLE[(input >> 12) & 0x3F];
            buffer[count + 2] = TABLE[(input >> 6) & 0x3F];
            buffer[count + 3] = TABLE[input & 0x3F];
            count += 4;
            i += 3;
        }

        if (i == data.length - 1) {
            uint256 input = uint256(data[i]);
            buffer[count] = TABLE[(input >> 2) & 0x3F];
            buffer[count + 1] = TABLE[(input << 4) & 0x3F];
            buffer[count + 2] = "=";
            buffer[count + 3] = "=";
            count += 4;
        } else if (i == data.length - 2) {
            uint256 input = (uint256(data[i]) << 8) | uint256(data[i + 1]);
            buffer[count] = TABLE[(input >> 10) & 0x3F];
            buffer[count + 1] = TABLE[(input >> 4) & 0x3F];
            buffer[count + 2] = TABLE[(input << 2) & 0x3F];
            buffer[count + 3] = "=";
            count += 4;
        }

        assembly {
            mstore(buffer, count)
        }
        return string(buffer);
    }
}
```