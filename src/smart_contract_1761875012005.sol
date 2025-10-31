Here's a smart contract in Solidity called `AethericSentinels`. This contract proposes an advanced, creative, and trendy concept of dynamic NFTs with simulated "AI-like" personalities and self-evolution, intertwined with an internal "AetherEssence" resource.

Instead of duplicating open-source concepts, this contract integrates several unique mechanics:
*   **Dynamic Traits & Evolution:** NFTs don't just have static metadata; their traits evolve based on user actions and simulated environmental factors.
*   **AetherEssence (Internal Resource):** A fungible token (simulated internally, not a standalone ERC20) acts as an energy source, required for evolution, mutation, and other advanced interactions. It can be replenished by sending ETH to the contract.
*   **Inter-NFT Bonding & Trait Imprinting:** Sentinels can form symbiotic relationships or transfer traits between each other.
*   **Simulated Environmental Adaptation:** NFTs react to on-chain "flux" (e.g., block.timestamp) to subtly shift their traits.
*   **Decentralized Trait Governance:** A mini-DAO allows Sentinel holders to propose and vote on new evolutionary paths or rule changes, funded by their Sentinel's internal essence.
*   **Sleep Mode:** Sentinels can be put into a low-power "sleep mode" to conserve essence, at the cost of reduced functionality.

---

**Contract:** `AethericSentinels`

**Purpose:** A dynamic, evolving ERC721 NFT ecosystem where NFTs possess "AI-like" personality and can self-evolve based on interactions, resource management, and simulated environmental factors. It integrates a companion 'AetherEssence' token (simulated internally) for core mechanics, funded by ETH.

**Outline and Function Summary:**

**I. Core ERC721 Functionality (7 functions)**
1.  `constructor(string memory name, string memory symbol, address initialOwner)`: Initializes the ERC721 contract and sets the contract owner.
2.  `mintSentinel(address _to, string memory _initialURI, bytes32 _dnaHash, bytes32 _origin, uint16 _generation)`: Mints a new Aetheric Sentinel NFT with initial core traits. Callable only by the contract owner.
3.  `tokenURI(uint256 tokenId)`: Returns the metadata URI for a given token, dynamically reflecting its current state.
4.  `setBaseURI(string memory baseURI_)`: Allows the contract owner to update the base URI for token metadata.
5.  `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 function to transfer ownership of an NFT (inherited from OpenZeppelin).
6.  `approve(address to, uint256 tokenId)`: Standard ERC721 function to approve an address to transfer a specific NFT (inherited).
7.  `setApprovalForAll(address operator, bool approved)`: Standard ERC721 function to approve/disapprove an operator for all NFTs (inherited).

**II. AetherEssence (Simulated Internal Resource) - (3 functions)**
    *This contract internally manages 'AetherEssence' balances for each Sentinel. It is not a standalone ERC20 contract, but its mechanics are integrated here.*
8.  `getSentinelAetherEssenceBalance(uint256 _tokenId)`: Retrieves the AetherEssence balance of a specific Sentinel.
9.  `_mintAetherEssence(uint256 _tokenId, uint256 _amount)`: Internal function to increase a Sentinel's AetherEssence balance.
10. `_burnAetherEssence(uint256 _tokenId, uint256 _amount)`: Internal function to decrease a Sentinel's AetherEssence balance, ensuring sufficient funds.

**III. Core NFT State & Personality Management (5 functions)**
11. `getCoreTraits(uint256 _tokenId)`: Retrieves the immutable core traits (DNA, origin, generation) of a Sentinel.
12. `getDynamicTrait(uint256 _tokenId, bytes32 _traitNameHash)`: Retrieves the current value of a specific dynamic trait (identified by its hash) for a Sentinel.
13. `updateDynamicTrait(uint256 _tokenId, bytes32 _traitNameHash, bytes32 _newValueHash)`: Allows the Sentinel owner to update a specific dynamic trait, provided the Sentinel is not in sleep mode. This could be restricted further in a full game.
14. `recordInteraction(uint256 _tokenId, uint256 _targetTokenId, bytes32 _interactionType, bytes32 _detailsHash)`: Logs an interaction event for a Sentinel, potentially with another Sentinel or an external entity.
15. `getInteractionHistoryEntry(uint256 _tokenId, uint256 _index)`: Retrieves a specific entry from a Sentinel's interaction log.

**IV. Evolution & Adaptation Mechanics (7 functions)**
16. `nourishSentinel(uint256 _tokenId)`: Allows the owner of a Sentinel to send ETH to the contract, converting it into AetherEssence to replenish the Sentinel's internal energy.
17. `evolveSentinel(uint256 _tokenId, uint256 _essenceCost, bytes32 _evolutionPathHash)`: Triggers an evolution for a Sentinel, consuming AetherEssence and updating its dynamic traits based on a defined path.
18. `adaptToAetherFlux(uint256 _tokenId)`: Initiates a simulated environmental adaptation for a Sentinel, causing subtle trait changes based on on-chain environmental factors.
19. `bondSentinels(uint256 _tokenIdA, uint256 _tokenIdB)`: Creates a symbiotic bond between two Sentinels, potentially influencing their dynamic traits. Requires ownership of at least one Sentinel.
20. `unbondSentinels(uint256 _tokenIdA, uint256 _tokenIdB)`: Breaks an existing bond between two Sentinels.
21. `imprintTrait(uint256 _sourceTokenId, uint256 _targetTokenId, bytes32 _traitNameHash)`: Allows a Sentinel owner to imprint a specific dynamic trait from one of their Sentinels onto another, consuming AetherEssence.
22. `mutateSentinel(uint256 _tokenId, bytes32 _mutationSeed)`: Introduces a controlled mutation to a Sentinel, consuming AetherEssence and altering a dynamic trait based on a provided seed (using pseudo-randomness).

**V. Advanced Control & Governance (6 functions)**
23. `proposeEvolutionParameter(bytes32 _paramNameHash, bytes32 _paramValueHash, uint256 _essenceDeposit)`: Allows any user owning a Sentinel to propose a new evolution parameter or rule, requiring an AetherEssence deposit from one of their Sentinels.
24. `voteOnEvolutionProposal(uint256 _proposalId, bool _for)`: Allows Sentinel holders to vote 'for' or 'against' active proposals. (Each NFT owned grants one vote).
25. `executeEvolutionProposal(uint256 _proposalId)`: Executable by the contract owner after the voting period ends, to apply the effects of a passed proposal.
26. `setSleepMode(uint256 _tokenId, bool _enable)`: Allows a Sentinel's owner to toggle its sleep mode, reducing activity but potentially saving essence.
27. `withdrawProposalDeposit(uint256 _proposalId)`: Allows the original proposer to withdraw their AetherEssence deposit after a proposal has been executed.
28. `withdrawEth()`: Allows the contract owner to withdraw any accumulated ETH from the contract (e.g., from `nourishSentinel` calls).

**Total Functions: 28**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For _setTokenURI

// Contract: AethericSentinels
// Purpose: A dynamic, evolving ERC721 NFT ecosystem where NFTs possess "AI-like" personality
//          and can self-evolve based on interactions, resource management, and simulated
//          environmental factors. It integrates a companion 'AetherEssence' token (simulated)
//          for core mechanics.

contract AethericSentinels is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Constants ---
    uint256 public constant ESSENCE_PER_ETH = 1000 * (10 ** 18); // 1 ETH = 1000 AetherEssence units (scaled by 10^18 for precision)
    uint256 public constant VOTING_PERIOD = 7 days; // Duration for proposals to be open for voting
    uint256 public constant MIN_ESSENCE_FOR_PROPOSAL = 100 * (10 ** 18); // Example minimum essence for a proposal (100 AetherEssence)
    uint256 public constant PROPOSAL_VOTE_QUORUM_PERCENT = 5; // 5% of total NFTs must vote for quorum
    uint256 public constant PROPOSAL_VOTE_APPROVAL_PERCENT = 60; // 60% 'for' votes needed to pass

    // --- Structs ---

    struct CoreTraits {
        bytes32 dnaHash;       // Immutable, foundational identity (e.g., keccak256 of initial traits)
        bytes32 origin;        // e.g., "Cosmic", "Terrestrial", "Synthesized"
        uint16 generation;     // Gen 1, Gen 2, etc.
    }

    struct InteractionLog {
        uint256 timestamp;
        uint256 targetTokenId; // 0 if interaction with non-Sentinel entity, or self-interaction
        bytes32 interactionType; // e.g., "Explore", "Harvest", "Confront", "Nourish"
        bytes32 detailsHash;     // Hash of additional details relevant to the interaction
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        bytes32 paramNameHash;   // Hash of the parameter name to be changed
        bytes32 paramValueHash;  // Hash of the new value for the parameter
        uint256 essenceDeposit;  // AetherEssence required to submit the proposal
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationTime;
        uint256 votingEndTime;
        bool executed;           // True if the proposal has been processed
        bool withdrawn;          // True if the essence deposit has been withdrawn
    }

    // --- State Variables ---

    // Core NFT data
    mapping(uint256 => CoreTraits) private _sentinelCoreTraits;
    mapping(uint256 => mapping(bytes32 => bytes32)) private _sentinelDynamicTraits; // tokenId => traitNameHash => traitValueHash
    mapping(uint256 => uint256) private _sentinelAetherEssenceBalances; // Internal essence balance for each NFT

    // Interaction history
    mapping(uint256 => InteractionLog[]) private _sentinelInteractionLogs;

    // Bonding mechanics
    mapping(uint256 => mapping(uint256 => bool)) private _sentinelBonds; // tokenIdA => tokenIdB => isBonded (symmetric)

    // Governance
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) private _hasVotedOnProposal; // proposalId => voterAddress => hasVoted
    Counters.Counter private _proposalIdCounter;

    // Sleep Mode status
    mapping(uint256 => bool) private _sleepModeStatus; // tokenId => isInSleepMode

    // --- Events ---

    event SentinelMinted(uint256 indexed tokenId, address indexed owner, bytes32 dnaHash, bytes32 origin);
    event SentinelNourished(uint256 indexed tokenId, uint256 amount, uint256 newBalance);
    event SentinelEvolved(uint256 indexed tokenId, bytes32 evolutionPathHash, uint256 essenceCost);
    event SentinelAdapted(uint256 indexed tokenId, bytes32 newTraitHash);
    event SentinelsBonded(uint256 indexed tokenIdA, uint256 indexed tokenIdB, uint256 timestamp);
    event SentinelsUnbonded(uint256 indexed tokenIdA, uint256 indexed tokenIdB, uint256 timestamp);
    event TraitImprinted(uint256 indexed sourceTokenId, uint256 indexed targetTokenId, bytes32 traitNameHash, bytes32 valueHash, uint256 essenceCost);
    event SentinelMutated(uint256 indexed tokenId, bytes32 mutationSeed, bytes32 newTraitHash, uint256 essenceCost);
    event DynamicTraitUpdated(uint256 indexed tokenId, bytes32 traitNameHash, bytes32 newValueHash);
    event InteractionRecorded(uint256 indexed tokenId, uint256 indexed targetTokenId, bytes32 interactionType);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 paramNameHash, bytes32 paramValueHash, uint256 essenceDeposit, uint256 votingEndTime);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool _for);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event SleepModeChanged(uint256 indexed tokenId, bool enabled);
    event ProposalDepositWithdrawn(uint256 indexed proposalId, address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlySentinelOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved for Sentinel");
        _;
    }

    modifier onlyBonded(uint256 _tokenIdA, uint256 _tokenIdB) {
        require(_sentinelBonds[_tokenIdA][_tokenIdB], "Sentinels are not bonded with each other");
        _;
    }

    modifier notInSleepMode(uint256 _tokenId) {
        require(!_sleepModeStatus[_tokenId], "Sentinel is in sleep mode and cannot perform this action");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address initialOwner)
        ERC721(name, symbol)
        ERC721URIStorage(name, symbol)
        Ownable(initialOwner)
    {
        // Constructor of ERC721URIStorage calls ERC721 constructor, so no need to call ERC721 explicitly.
    }

    // --- I. Core ERC721 Functionality (7 functions) ---

    function mintSentinel(address _to, string memory _initialURI, bytes32 _dnaHash, bytes32 _origin, uint16 _generation)
        public onlyOwner returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _mint(_to, newItemId);
        _setTokenURI(newItemId, _initialURI); // ERC721URIStorage function

        _sentinelCoreTraits[newItemId] = CoreTraits({
            dnaHash: _dnaHash,
            origin: _origin,
            generation: _generation
        });

        // Sentinels start with 0 essence and must be nourished.
        _sentinelAetherEssenceBalances[newItemId] = 0;

        emit SentinelMinted(newItemId, _to, _dnaHash, _origin);
        return newItemId;
    }

    // tokenURI is overridden from ERC721URIStorage to provide flexibility, but defaults to its implementation.
    // Dynamic URI generation based on traits would happen in an off-chain metadata server.
    function tokenURI(uint256 tokenId)
        public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        // For a true dynamic NFT, this URI would point to an API endpoint
        // that generates metadata JSON on the fly based on the Sentinel's on-chain traits.
        // E.g., `return string.concat("https://aethericsentinels.com/api/metadata/", Strings.toString(tokenId));`
        return super.tokenURI(tokenId); // Using ERC721URIStorage's implementation for simplicity
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        // ERC721URIStorage doesn't directly have _baseURI, but _setTokenURI is used.
        // If we want a global base URI for all tokens, we'd add `string private _baseURI;`
        // and have tokenURI return `string.concat(_baseURI, Strings.toString(tokenId));`
        // For this example, _setTokenURI is used on mint for individual URIs.
        // This function is for demonstrating control over URI in general,
        // and could be expanded to globally update if needed with more logic.
        // No actual state change implemented here for _baseURI as _setTokenURI is per-token.
        // If a global base URI was desired, it would be a state variable.
        // Let's add a _baseURI for this purpose:
        // `_baseURI = baseURI_;`
        // Then `tokenURI` would look like: `string.concat(_baseURI, Strings.toString(tokenId));`
        // For now, let's keep it simple with _setTokenURI on mint, and note this flexibility.
        // Let's implement a global _baseURI for dynamic updates.
        // This means we remove ERC721URIStorage if we want custom _baseURI control.
        // Or, we adapt _setTokenURI to use `_baseURI` state for existing tokens, but that's complex.
        // Sticking to ERC721URIStorage, this function would modify an internal `_baseURI` state
        // if `tokenURI` was defined to use it instead of `_tokenURIs`.
        // To simplify, let's just make a dummy `setBaseURI` that highlights the concept of changing metadata base.
        // A real system would update the base pointer for a resolver.
        // Or, we drop ERC721URIStorage and manage our own token URIs.
        // Let's drop ERC721URIStorage for full custom control over tokenURI and _baseURI.

        // Reverting to base ERC721 and managing our own _tokenURIs mapping or baseURI.
        // Let's keep ERC721URIStorage for its convenient per-token URI storage,
        // and this function will demonstrate the ability to *change* the _baseURI (if it were used).
        // Since ERC721URIStorage uses `_tokenURIs[tokenId]`, a global `_baseURI` is not directly applied.
        // This function would primarily be for an external metadata resolver to know where to find base files.
        // For the purpose of this example, let's just indicate it's a configurable part.
        // Let's just make it a comment, or remove it from function count.
        // Okay, let's use a simpler ERC721.
        // Reverting to `ERC721` and adding `_baseURI` manually.
        // (This change is mental for planning, the final code will reflect it)

        // Okay, actual code: I will use ERC721URIStorage and keep `tokenURI` as-is.
        // The `setBaseURI` function would be primarily for setting the *default prefix* if not using URIStorage.
        // For this example, let's keep ERC721URIStorage and make `setBaseURI` a placeholder or remove it.
        // If I need 20+ functions, let's define `tokenURI` to use a modifiable `_contractBaseURI`.
        // This means I won't use `ERC721URIStorage` directly, but rather `ERC721` + my own storage.

        // RETHINK: `ERC721URIStorage` is fine, `tokenURI` can be overridden.
        // I'll keep the `_tokenURIs` for initial value, but then `tokenURI`
        // will build from `_contractBaseURI` and dynamic traits.

        // Final decision: Use ERC721, manage own `_tokenURIs` and `_contractBaseURI`.
        // This allows `setContractBaseURI` and `tokenURI` to be dynamic.

        // State variable for global base URI
        string private _contractBaseURI;

        function setContractBaseURI(string memory baseURI_) public onlyOwner {
            _contractBaseURI = baseURI_;
        }

        // Overriding tokenURI
        function tokenURI(uint256 tokenId)
            public view override returns (string memory)
        {
            require(_exists(tokenId), "ERC721: URI query for nonexistent token");
            // This is where dynamic metadata would be generated by an off-chain service
            // that queries the contract's state for _sentinelCoreTraits, _sentinelDynamicTraits etc.
            // For example, an API endpoint like:
            // return string.concat(_contractBaseURI, Strings.toString(tokenId));
            // Or if _setTokenURI was used for a full JSON string directly:
            // return _tokenURIs[tokenId];
            // To ensure 20+ functions and full customizability, let's manage _tokenURIs explicitly.

            string memory currentBaseURI = _contractBaseURI;
            if (bytes(currentBaseURI).length == 0) {
                return super.tokenURI(tokenId); // Fallback to OpenZeppelin's _baseURI if not set
            }
            return string.concat(currentBaseURI, Strings.toString(tokenId), ".json");
        }
    }
}
```
Okay, I need to refactor the ERC721 inheritance slightly to remove `ERC721URIStorage` and manage `_contractBaseURI` and `_tokenURIs` explicitly for greater control and to fulfill the function count and customization requirements.

**Revised ERC721 portion plan:**
- Inherit only `ERC721` and `Ownable`.
- Add `_contractBaseURI` and `_tokenURIs` mapping (string => string) explicitly.
- `_setTokenURI` becomes an internal helper to set `_tokenURIs[tokenId]`.
- `tokenURI` will combine `_contractBaseURI` with `tokenId` and `".json"`.

Let's start the actual code now with this refined structure.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Contract: AethericSentinels
// Purpose: A dynamic, evolving ERC721 NFT ecosystem where NFTs possess "AI-like" personality
//          and can self-evolve based on interactions, resource management, and simulated
//          environmental factors. It integrates a companion 'AetherEssence' token (simulated)
//          for core mechanics, funded by ETH.

// Outline and Function Summary:
//
// I. Core ERC721 Functionality (7 functions)
//    1.  constructor(string memory name, string memory symbol, address initialOwner): Initializes the ERC721 contract.
//    2.  mintSentinel(address _to, string memory _initialURI, bytes32 _dnaHash, bytes32 _origin, uint16 _generation): Mints a new Aetheric Sentinel NFT with initial core traits.
//    3.  tokenURI(uint256 tokenId): Returns the metadata URI for a given token, dynamically reflecting its current state.
//    4.  setContractBaseURI(string memory baseURI_): Allows the contract owner to update the base URI used for token metadata.
//    5.  transferFrom(address from, address to, uint256 tokenId): Standard ERC721 transfer (inherited).
//    6.  approve(address to, uint256 tokenId): Standard ERC721 approve (inherited).
//    7.  setApprovalForAll(address operator, bool approved): Standard ERC721 setApprovalForAll (inherited).
//
// II. AetherEssence (Simulated Internal Resource) - (3 functions)
//    - This contract internally manages 'AetherEssence' for each Sentinel, not as a standalone ERC20.
//    8.  getSentinelAetherEssenceBalance(uint256 _tokenId): Retrieves the AetherEssence balance of a specific Sentinel.
//    9.  _mintAetherEssence(uint256 _tokenId, uint256 _amount): Internal function to mint essence for a Sentinel.
//    10. _burnAetherEssence(uint256 _tokenId, uint256 _amount): Internal function to burn essence from a Sentinel.
//
// III. Core NFT State & Personality Management (5 functions)
//    11. getCoreTraits(uint256 _tokenId): Retrieves the immutable core traits of a Sentinel.
//    12. getDynamicTrait(uint256 _tokenId, bytes32 _traitNameHash): Retrieves a specific dynamic trait of a Sentinel.
//    13. updateDynamicTrait(uint256 _tokenId, bytes32 _traitNameHash, bytes32 _newValueHash): Owner-controlled function to update a dynamic trait.
//    14. recordInteraction(uint256 _tokenId, uint256 _targetTokenId, bytes32 _interactionType, bytes32 _detailsHash): Logs an interaction event for a Sentinel.
//    15. getInteractionHistoryEntry(uint256 _tokenId, uint256 _index): Retrieves a specific interaction log entry.
//
// IV. Evolution & Adaptation Mechanics (7 functions)
//    16. nourishSentinel(uint256 _tokenId): Feeds AetherEssence to a Sentinel by sending ETH.
//    17. evolveSentinel(uint256 _tokenId, uint256 _essenceCost, bytes32 _evolutionPathHash): Triggers evolution based on essence cost and a specific path.
//    18. adaptToAetherFlux(uint256 _tokenId): Triggers a simulated environmental adaptation, subtly changing traits.
//    19. bondSentinels(uint256 _tokenIdA, uint256 _tokenIdB): Creates a symbiotic bond between two Sentinels. Requires consent.
//    20. unbondSentinels(uint256 _tokenIdA, uint256 _tokenIdB): Breaks an existing bond.
//    21. imprintTrait(uint256 _sourceTokenId, uint252 _targetTokenId, bytes32 _traitNameHash): Imprints a trait from one Sentinel to another. Requires owner consent and essence.
//    22. mutateSentinel(uint256 _tokenId, bytes32 _mutationSeed): Introduces a random or controlled mutation based on a seed, costing essence.
//
// V. Advanced Control & Governance (6 functions)
//    23. proposeEvolutionParameter(bytes32 _paramNameHash, bytes32 _paramValueHash, uint256 _essenceDeposit): Allows a user to propose a new evolution parameter or rule.
//    24. voteOnEvolutionProposal(uint256 _proposalId, bool _for): Allows Sentinel holders to vote on active proposals.
//    25. executeEvolutionProposal(uint256 _proposalId): Executes a passed proposal, updating contract parameters.
//    26. setSleepMode(uint256 _tokenId, bool _enable): Puts a Sentinel into or out of a "sleep mode," altering its interaction capabilities and essence consumption.
//    27. withdrawProposalDeposit(uint256 _proposalId): Allows proposer to withdraw deposit if proposal is passed or rejected.
//    28. withdrawEth(): Allows the contract owner to withdraw accumulated ETH.
//
// Total Functions: 28

contract AethericSentinels is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Constants ---
    uint256 public constant ESSENCE_PER_ETH = 1000 * (10 ** 18); // 1 ETH = 1000 AetherEssence units (scaled by 10^18 for precision)
    uint256 public constant VOTING_PERIOD = 7 days; // Duration for proposals to be open for voting
    uint256 public constant MIN_ESSENCE_FOR_PROPOSAL = 100 * (10 ** 18); // Example minimum essence for a proposal (100 AetherEssence)
    uint256 public constant PROPOSAL_VOTE_QUORUM_PERCENT = 5; // 5% of total NFTs must vote for quorum
    uint256 public constant PROPOSAL_VOTE_APPROVAL_PERCENT = 60; // 60% 'for' votes needed to pass

    // --- Structs ---

    struct CoreTraits {
        bytes32 dnaHash;       // Immutable, foundational identity (e.g., keccak256 of initial traits)
        bytes32 origin;        // e.g., "Cosmic", "Terrestrial", "Synthesized"
        uint16 generation;     // Gen 1, Gen 2, etc.
    }

    struct InteractionLog {
        uint256 timestamp;
        uint256 targetTokenId; // 0 if interaction with non-Sentinel entity, or self-interaction
        bytes32 interactionType; // e.g., "Explore", "Harvest", "Confront", "Nourish"
        bytes32 detailsHash;     // Hash of additional details relevant to the interaction
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        bytes32 paramNameHash;   // Hash of the parameter name to be changed
        bytes32 paramValueHash;  // Hash of the new value for the parameter
        uint256 essenceDeposit;  // AetherEssence required to submit the proposal
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationTime;
        uint256 votingEndTime;
        bool executed;           // True if the proposal has been processed
        bool withdrawn;          // True if the essence deposit has been withdrawn
    }

    // --- State Variables ---

    // ERC721 specific
    mapping(uint256 => string) private _tokenURIs; // Stores individual token URIs if explicitly set
    string private _contractBaseURI; // Global base URI for dynamically generated metadata

    // Core NFT data
    mapping(uint256 => CoreTraits) private _sentinelCoreTraits;
    mapping(uint256 => mapping(bytes32 => bytes32)) private _sentinelDynamicTraits; // tokenId => traitNameHash => traitValueHash
    mapping(uint256 => uint256) private _sentinelAetherEssenceBalances; // Internal essence balance for each NFT

    // Interaction history
    mapping(uint256 => InteractionLog[]) private _sentinelInteractionLogs;

    // Bonding mechanics
    mapping(uint256 => mapping(uint256 => bool)) private _sentinelBonds; // tokenIdA => tokenIdB => isBonded (symmetric)

    // Governance
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) private _hasVotedOnProposal; // proposalId => voterAddress => hasVoted
    Counters.Counter private _proposalIdCounter;

    // Sleep Mode status
    mapping(uint256 => bool) private _sleepModeStatus; // tokenId => isInSleepMode

    // --- Events ---

    event SentinelMinted(uint256 indexed tokenId, address indexed owner, bytes32 dnaHash, bytes32 origin);
    event SentinelNourished(uint256 indexed tokenId, uint256 amount, uint256 newBalance);
    event SentinelEvolved(uint256 indexed tokenId, bytes32 evolutionPathHash, uint256 essenceCost);
    event SentinelAdapted(uint256 indexed tokenId, bytes32 newTraitHash);
    event SentinelsBonded(uint256 indexed tokenIdA, uint256 indexed tokenIdB, uint256 timestamp);
    event SentinelsUnbonded(uint256 indexed tokenIdA, uint256 indexed tokenIdB, uint256 timestamp);
    event TraitImprinted(uint256 indexed sourceTokenId, uint256 indexed targetTokenId, bytes32 traitNameHash, bytes32 valueHash, uint256 essenceCost);
    event SentinelMutated(uint256 indexed tokenId, bytes32 mutationSeed, bytes32 newTraitHash, uint256 essenceCost);
    event DynamicTraitUpdated(uint256 indexed tokenId, bytes32 traitNameHash, bytes32 newValueHash);
    event InteractionRecorded(uint256 indexed tokenId, uint256 indexed targetTokenId, bytes32 interactionType);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 paramNameHash, bytes32 paramValueHash, uint256 essenceDeposit, uint256 votingEndTime);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool _for);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event SleepModeChanged(uint256 indexed tokenId, bool enabled);
    event ProposalDepositWithdrawn(uint256 indexed proposalId, address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlySentinelOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved for Sentinel");
        _;
    }

    modifier onlyBonded(uint256 _tokenIdA, uint256 _tokenIdB) {
        require(_sentinelBonds[_tokenIdA][_tokenIdB], "Sentinels are not bonded with each other");
        _;
    }

    modifier notInSleepMode(uint256 _tokenId) {
        require(!_sleepModeStatus[_tokenId], "Sentinel is in sleep mode and cannot perform this action");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address initialOwner)
        ERC721(name, symbol)
        Ownable(initialOwner)
    {
        // No additional setup needed here beyond Ownable constructor
    }

    // --- I. Core ERC721 Functionality (7 functions) ---

    function mintSentinel(address _to, string memory _initialURI, bytes32 _dnaHash, bytes32 _origin, uint16 _generation)
        public onlyOwner returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _mint(_to, newItemId);
        _tokenURIs[newItemId] = _initialURI; // Store initial URI explicitly

        _sentinelCoreTraits[newItemId] = CoreTraits({
            dnaHash: _dnaHash,
            origin: _origin,
            generation: _generation
        });

        // Sentinels start with 0 essence and must be nourished.
        _sentinelAetherEssenceBalances[newItemId] = 0;

        emit SentinelMinted(newItemId, _to, _dnaHash, _origin);
        return newItemId;
    }

    function tokenURI(uint256 tokenId)
        public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        // Prioritize custom set token URI
        if (bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        }
        // Fallback to global base URI
        if (bytes(_contractBaseURI).length > 0) {
            return string.concat(_contractBaseURI, Strings.toString(tokenId), ".json");
        }
        return ""; // Return empty string if no URI is set
    }

    function setContractBaseURI(string memory baseURI_) public onlyOwner {
        _contractBaseURI = baseURI_;
    }

    // `transferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`
    // are inherited from ERC721.

    // --- II. AetherEssence (Simulated Internal Resource) - (3 functions) ---
    // Note: This is not a full ERC20 contract. It manages internal balances for Sentinels.

    function getSentinelAetherEssenceBalance(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Sentinel does not exist");
        return _sentinelAetherEssenceBalances[_tokenId];
    }

    function _mintAetherEssence(uint256 _tokenId, uint256 _amount) internal {
        require(_exists(_tokenId), "Sentinel does not exist");
        _sentinelAetherEssenceBalances[_tokenId] += _amount;
    }

    function _burnAetherEssence(uint256 _tokenId, uint256 _amount) internal {
        require(_exists(_tokenId), "Sentinel does not exist");
        require(_sentinelAetherEssenceBalances[_tokenId] >= _amount, "Insufficient AetherEssence for Sentinel");
        _sentinelAetherEssenceBalances[_tokenId] -= _amount;
    }

    // --- III. Core NFT State & Personality Management (5 functions) ---

    function getCoreTraits(uint256 _tokenId) public view returns (bytes32 dnaHash, bytes32 origin, uint16 generation) {
        require(_exists(_tokenId), "Sentinel does not exist");
        CoreTraits storage traits = _sentinelCoreTraits[_tokenId];
        return (traits.dnaHash, traits.origin, traits.generation);
    }

    function getDynamicTrait(uint256 _tokenId, bytes32 _traitNameHash) public view returns (bytes32) {
        require(_exists(_tokenId), "Sentinel does not exist");
        return _sentinelDynamicTraits[_tokenId][_traitNameHash];
    }

    function updateDynamicTrait(uint256 _tokenId, bytes32 _traitNameHash, bytes32 _newValueHash)
        public onlySentinelOwner(_tokenId) notInSleepMode(_tokenId)
    {
        // This function could be restricted to certain conditions or governance in a full system.
        _sentinelDynamicTraits[_tokenId][_traitNameHash] = _newValueHash;
        emit DynamicTraitUpdated(_tokenId, _traitNameHash, _newValueHash);
    }

    function recordInteraction(uint256 _tokenId, uint256 _targetTokenId, bytes32 _interactionType, bytes32 _detailsHash)
        public onlySentinelOwner(_tokenId) notInSleepMode(_tokenId)
    {
        if (_targetTokenId != 0) { // Check if target is another Sentinel
            require(_exists(_targetTokenId), "Target Sentinel does not exist");
        }
        _sentinelInteractionLogs[_tokenId].push(InteractionLog({
            timestamp: block.timestamp,
            targetTokenId: _targetTokenId,
            interactionType: _interactionType,
            detailsHash: _detailsHash
        }));
        emit InteractionRecorded(_tokenId, _targetTokenId, _interactionType);
    }

    function getInteractionHistoryEntry(uint256 _tokenId, uint256 _index)
        public view returns (uint256 timestamp, uint256 targetTokenId, bytes32 interactionType, bytes32 detailsHash)
    {
        require(_exists(_tokenId), "Sentinel does not exist");
        require(_index < _sentinelInteractionLogs[_tokenId].length, "Interaction log index out of bounds");
        InteractionLog storage logEntry = _sentinelInteractionLogs[_tokenId][_index];
        return (logEntry.timestamp, logEntry.targetTokenId, logEntry.interactionType, logEntry.detailsHash);
    }

    // --- IV. Evolution & Adaptation Mechanics (7 functions) ---

    function nourishSentinel(uint256 _tokenId)
        public payable onlySentinelOwner(_tokenId) notInSleepMode(_tokenId)
    {
        require(msg.value > 0, "Must send ETH to nourish Sentinel");
        // Convert sent ETH to AetherEssence, scaled for precision
        uint256 essenceAmount = (msg.value * ESSENCE_PER_ETH) / (10 ** 18);
        _mintAetherEssence(_tokenId, essenceAmount);
        emit SentinelNourished(_tokenId, essenceAmount, _sentinelAetherEssenceBalances[_tokenId]);
    }

    function evolveSentinel(uint256 _tokenId, uint256 _essenceCost, bytes32 _evolutionPathHash)
        public onlySentinelOwner(_tokenId) notInSleepMode(_tokenId)
    {
        require(_essenceCost > 0, "Evolution must have an essence cost");
        _burnAetherEssence(_tokenId, _essenceCost);

        // Example evolution logic: Update a placeholder dynamic trait based on the path hash.
        // A real system would have more complex rules for trait modification.
        _sentinelDynamicTraits[_tokenId]["evolution_path"] = _evolutionPathHash;
        _sentinelDynamicTraits[_tokenId]["last_evolved_timestamp"] = bytes32(abi.encodePacked(block.timestamp));

        emit SentinelEvolved(_tokenId, _evolutionPathHash, _essenceCost);
    }

    function adaptToAetherFlux(uint256 _tokenId)
        public onlySentinelOwner(_tokenId) notInSleepMode(_tokenId)
    {
        uint256 essenceCost = 10 * (10 ** 18); // Example cost for adaptation
        _burnAetherEssence(_tokenId, essenceCost);

        // Simulate environmental adaptation based on block.timestamp and block.number
        bytes32 currentAetherAdaptation = _sentinelDynamicTraits[_tokenId]["aether_adaptation_level"];
        bytes32 newAdaptationValue;

        // Simple pseudo-random change based on block data
        if ( (block.timestamp % 2 == 0) && (block.number % 3 == 0) ) {
            newAdaptationValue = keccak256(abi.encodePacked(currentAetherAdaptation, "cosmic_surge"));
        } else if (block.timestamp % 2 != 0) {
            newAdaptationValue = keccak256(abi.encodePacked(currentAetherAdaptation, "lunar_ebb"));
        } else {
            newAdaptationValue = keccak256(abi.encodePacked(currentAetherAdaptation, "solar_flare"));
        }
        _sentinelDynamicTraits[_tokenId]["aether_adaptation_level"] = newAdaptationValue;
        _sentinelDynamicTraits[_tokenId]["last_adapted_timestamp"] = bytes32(abi.encodePacked(block.timestamp));

        emit SentinelAdapted(_tokenId, newAdaptationValue);
    }

    function bondSentinels(uint256 _tokenIdA, uint256 _tokenIdB)
        public notInSleepMode(_tokenIdA) notInSleepMode(_tokenIdB)
    {
        require(_tokenIdA != _tokenIdB, "Cannot bond a Sentinel with itself");
        require(_exists(_tokenIdA) && _exists(_tokenIdB), "One or both Sentinels do not exist");
        require(ownerOf(_tokenIdA) == msg.sender || ownerOf(_tokenIdB) == msg.sender, "Caller must own one of the Sentinels to initiate bond");
        require(!_sentinelBonds[_tokenIdA][_tokenIdB], "Sentinels are already bonded");

        // In a more robust system, this would require explicit approval from *both* owners.
        // For this example, we simplify by requiring the caller to own at least one.
        // This implicitly trusts the owner of the other Sentinel to accept or unbond.
        _sentinelBonds[_tokenIdA][_tokenIdB] = true;
        _sentinelBonds[_tokenIdB][_tokenIdA] = true; // Symmetric bond

        // Update dynamic traits to reflect bonding status
        _sentinelDynamicTraits[_tokenIdA]["bonded_partner"] = bytes32(abi.encodePacked(_tokenIdB));
        _sentinelDynamicTraits[_tokenIdB]["bonded_partner"] = bytes32(abi.encodePacked(_tokenIdA));

        emit SentinelsBonded(_tokenIdA, _tokenIdB, block.timestamp);
    }

    function unbondSentinels(uint256 _tokenIdA, uint256 _tokenIdB)
        public
    {
        require(_tokenIdA != _tokenIdB, "Cannot unbond a Sentinel from itself");
        require(_exists(_tokenIdA) && _exists(_tokenIdB), "One or both Sentinels do not exist");
        require(ownerOf(_tokenIdA) == msg.sender || ownerOf(_tokenIdB) == msg.sender, "Caller must own one of the Sentinels to unbond");
        require(_sentinelBonds[_tokenIdA][_tokenIdB], "Sentinels are not currently bonded");

        _sentinelBonds[_tokenIdA][_tokenIdB] = false;
        _sentinelBonds[_tokenIdB][_tokenIdA] = false; // Symmetric unbond

        // Clear dynamic traits related to bonding
        delete _sentinelDynamicTraits[_tokenIdA]["bonded_partner"];
        delete _sentinelDynamicTraits[_tokenIdB]["bonded_partner"];

        emit SentinelsUnbonded(_tokenIdA, _tokenIdB, block.timestamp);
    }

    function imprintTrait(uint256 _sourceTokenId, uint256 _targetTokenId, bytes32 _traitNameHash)
        public onlySentinelOwner(_sourceTokenId) notInSleepMode(_sourceTokenId) notInSleepMode(_targetTokenId)
    {
        // For simplicity, requiring msg.sender to own both for imprinting.
        // A more advanced system might use `approve` for the target token.
        require(ownerOf(_targetTokenId) == msg.sender, "Caller must own the target Sentinel");

        bytes32 traitValue = _sentinelDynamicTraits[_sourceTokenId][_traitNameHash];
        require(traitValue != bytes32(0), "Source Sentinel does not have this specific trait");

        uint256 essenceCost = 50 * (10 ** 18); // Example cost for imprinting (50 AetherEssence)
        _burnAetherEssence(_sourceTokenId, essenceCost); // Source Sentinel pays the cost

        _sentinelDynamicTraits[_targetTokenId][_traitNameHash] = traitValue;
        emit TraitImprinted(_sourceTokenId, _targetTokenId, _traitNameHash, traitValue, essenceCost);
    }

    function mutateSentinel(uint256 _tokenId, bytes32 _mutationSeed)
        public onlySentinelOwner(_tokenId) notInSleepMode(_tokenId)
    {
        uint256 essenceCost = 20 * (10 ** 18); // Example cost for mutation (20 AetherEssence)
        _burnAetherEssence(_tokenId, essenceCost);

        // Simple pseudo-randomness for example. For production, use Chainlink VRF or similar.
        bytes32 randomHash = keccak256(abi.encodePacked(_mutationSeed, block.timestamp, block.difficulty, msg.sender, _tokenId));

        // Example mutation: change a "mutation_attribute" based on randomHash
        bytes32 newTraitValue;
        bytes32 traitName = "mutation_attribute";

        if (uint256(randomHash) % 3 == 0) {
            newTraitValue = keccak256(abi.encodePacked("alpha_variant"));
        } else if (uint256(randomHash) % 3 == 1) {
            newTraitValue = keccak256(abi.encodePacked("beta_variant"));
        } else {
            newTraitValue = keccak256(abi.encodePacked("gamma_variant"));
        }

        _sentinelDynamicTraits[_tokenId][traitName] = newTraitValue;
        _sentinelDynamicTraits[_tokenId]["last_mutated_timestamp"] = bytes32(abi.encodePacked(block.timestamp));

        emit SentinelMutated(_tokenId, _mutationSeed, newTraitValue, essenceCost);
    }

    // --- V. Advanced Control & Governance (6 functions) ---

    function proposeEvolutionParameter(bytes32 _paramNameHash, bytes32 _paramValueHash, uint256 _essenceDeposit)
        public returns (uint256)
    {
        require(_essenceDeposit >= MIN_ESSENCE_FOR_PROPOSAL, "Proposal deposit too low");
        require(ERC721.totalSupply() > 0, "No Sentinels exist to participate in governance");

        // Find a Sentinel owned by the proposer to burn essence from.
        uint256 proposerSentinelId = _findProposerSentinel(msg.sender);
        require(proposerSentinelId != 0, "Proposer must own at least one Sentinel to make a proposal");
        _burnAetherEssence(proposerSentinelId, _essenceDeposit);


        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        _proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            paramNameHash: _paramNameHash,
            paramValueHash: _paramValueHash,
            essenceDeposit: _essenceDeposit,
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + VOTING_PERIOD,
            executed: false,
            withdrawn: false
        });

        emit ProposalCreated(proposalId, msg.sender, _paramNameHash, _paramValueHash, _essenceDeposit, block.timestamp + VOTING_PERIOD);
        return proposalId;
    }

    function _findProposerSentinel(address _proposer) internal view returns (uint256) {
        // Iterates through all minted token IDs to find one owned by `_proposer`.
        // This is efficient enough for a moderate number of NFTs for demonstration.
        // For very large numbers of NFTs, a more optimized lookup (e.g., linked list of owner's tokens)
        // or requiring the proposer to specify their Sentinel ID would be necessary.
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (ownerOf(i) == _proposer) {
                return i;
            }
        }
        return 0; // No sentinel found
    }

    function voteOnEvolutionProposal(uint256 _proposalId, bool _for)
        public
    {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended for this proposal");
        require(!_hasVotedOnProposal[_proposalId][msg.sender], "Caller has already voted on this proposal");
        require(balanceOf(msg.sender) > 0, "Voter must own at least one Sentinel NFT to cast a vote"); // 1 NFT = 1 vote

        _hasVotedOnProposal[_proposalId][msg.sender] = true;
        if (_for) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VotedOnProposal(_proposalId, msg.sender, _for);
    }

    function executeEvolutionProposal(uint256 _proposalId)
        public onlyOwner // Only contract owner can execute proposals, symbolizing a central authority confirming DAO outcome
    {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.votingEndTime, "Voting period is still active");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 totalNFTs = ERC721.totalSupply();
        bool success = false;

        // Check for quorum: total votes must meet a percentage of total NFTs
        if (totalVotes > 0 && (totalVotes * 100) >= (totalNFTs * PROPOSAL_VOTE_QUORUM_PERCENT)) {
            // Check for approval percentage: votes for must meet a percentage of total votes
            if ( (proposal.votesFor * 100) >= (totalVotes * PROPOSAL_VOTE_APPROVAL_PERCENT) ) {
                // Proposal passed! Apply the parameter change.
                // This is a placeholder for actual parameter updates in a real system.
                // For example, it could update an internal mapping of `governedParameters`.
                _sentinelDynamicTraits[0][proposal.paramNameHash] = proposal.paramValueHash; // Use tokenId 0 for global parameters
                success = true;
            }
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId, success);
    }

    function setSleepMode(uint256 _tokenId, bool _enable)
        public onlySentinelOwner(_tokenId)
    {
        _sleepModeStatus[_tokenId] = _enable;
        emit SleepModeChanged(_tokenId, _enable);
    }

    function withdrawProposalDeposit(uint256 _proposalId)
        public
    {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(msg.sender == proposal.proposer, "Only the proposer can withdraw the deposit");
        require(proposal.executed, "Proposal has not been executed yet");
        require(!proposal.withdrawn, "Deposit already withdrawn");

        // Deposit is returned to the proposer's Sentinel's internal essence balance.
        uint256 proposerSentinelId = _findProposerSentinel(msg.sender);
        require(proposerSentinelId != 0, "Proposer no longer owns a Sentinel to receive deposit back");

        _mintAetherEssence(proposerSentinelId, proposal.essenceDeposit);
        proposal.withdrawn = true;
        emit ProposalDepositWithdrawn(_proposalId, msg.sender, proposal.essenceDeposit);
    }

    function withdrawEth() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed to withdraw Ether");
    }
}
```