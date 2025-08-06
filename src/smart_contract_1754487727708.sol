This smart contract, "QuantumLeap Protocol," is designed to simulate a decentralized, evolving research and discovery ecosystem. Pioneers (NFTs) explore a Cosmic Network, discovering Exotic Matter (dynamic NFTs), and collectively contributing to a global Knowledge pool. This Knowledge unlocks new Technological Eras, each potentially changing game mechanics or opening new possibilities. The protocol incorporates reputation mechanics, probabilistic outcomes, and a simplified on-chain governance model.

---

## QuantumLeap Protocol: Outline & Function Summary

**Contract Name:** `QuantumLeap`

**Core Concept:** A gamified, evolving, on-chain research and discovery simulation. Users mint "Pioneer" NFTs, which they use to "discover" "Exotic Matter" NFTs. These discoveries contribute to a global "Knowledge" pool, which, upon reaching thresholds, advances the protocol into new "Technological Eras." Exotic Matter NFTs are dynamic, evolving based on global parameters and the current era. Pioneers accumulate "Quantum Alignment" (reputation) based on their contributions.

---

### **Outline**

1.  **State Variables & Constants:**
    *   Contract ownership (`Ownable`)
    *   ERC721 interfaces for Pioneers and Exotic Matter NFTs
    *   Global Counters (Epoch, Era, Knowledge)
    *   Data Structures (Pioneer, ExoticMatter, EraConfig, Proposal)
    *   Mappings for storing data (Pioneers, Exotic Matter, Era thresholds, Proposals)
    *   Configuration parameters (discovery probabilities, research rates, synthesis costs)

2.  **Events:**
    *   Key actions (PioneerMinted, ExoticMatterDiscovered, EraAdvanced, EpochAdvanced, ProposalCreated, VoteCast, ProposalExecuted, etc.)

3.  **Modifiers:**
    *   `onlyPioneerOwner`
    *   `onlyActiveEra`
    *   `proposalExistsAndActive`
    *   `hasVoted`

4.  **Enums:**
    *   `ResearchFocus` (for Pioneers)
    *   `Era` (for protocol stages)
    *   `ProposalState`

5.  **Functions:**

    *   **Initialization & Core Setup:**
        *   `constructor()`
        *   `initializeEraConfig()` (Admin)
        *   `initializeBaseParameters()` (Admin)

    *   **Pioneer Management (ERC721):**
        *   `mintPioneer()`
        *   `setPioneerResearchFocus()`
        *   `getPioneerDetails()`
        *   `getQuantumAlignment()` (View)

    *   **Exotic Matter Management (Dynamic ERC721):**
        *   `discoverExoticMatter()`
        *   `synthesizeExoticMatter()`
        *   `evolveExoticMatter()`
        *   `getExoticMatterDetails()` (View)

    *   **Research & Knowledge Progression:**
        *   `stakeForResearch()`
        *   `claimResearchOutput()`
        *   `getGlobalKnowledge()` (View)
        *   `getCurrentEpochKnowledge()` (View)
        *   `calculateResearchYield()` (View)

    *   **Epoch & Era Progression:**
        *   `advanceEpoch()`
        *   `advanceEra()`
        *   `getCurrentEpoch()` (View)
        *   `getCurrentEra()` (View)
        *   `getEraThreshold()` (View)
        *   `getTimeUntilNextEpoch()` (View)

    *   **On-Chain Oracle/External Data Simulation:**
        *   `setCosmicFluxData()` (Admin)
        *   `getCosmicFluxData()` (View)

    *   **Decentralized Governance (Simplified):**
        *   `proposeParameterChange()`
        *   `voteOnProposal()`
        *   `executeProposal()`
        *   `getProposalDetails()` (View)
        *   `hasVotedOnProposal()` (View)

    *   **Protocol Configuration (Admin/Governance):**
        *   `setEraThreshold()`
        *   `setDiscoveryProbability()`
        *   `setResearchRate()`
        *   `setSynthesisCost()`

---

### **Function Summary (25 Functions)**

1.  **`constructor()`**: Initializes the contract, sets the deployer as the owner, and mints the initial supply of `Pioneer` and `ExoticMatter` (if any pre-mint is desired, else starts empty).
2.  **`initializeEraConfig(uint256[] calldata _thresholds)`**: **(Admin)** Sets the knowledge thresholds required to advance to each new era.
3.  **`initializeBaseParameters(uint256 _baseDiscoveryProb, uint256 _baseResearchRate, uint256 _baseSynthesisCost)`**: **(Admin)** Sets initial discovery success probability, base research knowledge rate, and synthesis cost.
4.  **`mintPioneer(string calldata _tokenURI)`**: Allows users to mint a new "Pioneer" NFT. Each Pioneer has a unique ID and a starting `quantumAlignment`.
5.  **`setPioneerResearchFocus(uint256 _pioneerId, ResearchFocus _focus)`**: Allows a Pioneer owner to set or change their Pioneer's `researchFocus`, which can influence discovery probabilities or research output.
6.  **`getPioneerDetails(uint256 _pioneerId)`**: **(View)** Retrieves the full details of a specific Pioneer NFT.
7.  **`getQuantumAlignment(uint256 _pioneerId)`**: **(View)** Returns the `quantumAlignment` (reputation score) of a given Pioneer.
8.  **`discoverExoticMatter(uint256 _pioneerId, string calldata _tokenURI)`**: The core discovery function. A Pioneer attempts to discover new "Exotic Matter." Success is probabilistic, influenced by Pioneer's `quantumAlignment` and `researchFocus`. If successful, a new `ExoticMatter` NFT is minted with initial dynamic properties. Increases Pioneer's `quantumAlignment`.
9.  **`synthesizeExoticMatter(uint256 _pioneerId, uint256[] calldata _matterIdsToBurn, string calldata _newTokenURI)`**: Allows a Pioneer to combine (burn) multiple `ExoticMatter` NFTs to synthesize a new, potentially rarer or more powerful `ExoticMatter` NFT. The new NFT's properties are derived from the burnt ones.
10. **`evolveExoticMatter(uint256 _matterId)`**: Triggers the dynamic evolution of an `ExoticMatter` NFT. Its properties hash is re-calculated based on the current `epoch`, `cosmicFluxData`, and the `ExoticMatter`'s `discoveryEpoch`, simulating external influence and on-chain change.
11. **`getExoticMatterDetails(uint256 _matterId)`**: **(View)** Retrieves the full details of a specific Exotic Matter NFT, including its dynamic properties.
12. **`stakeForResearch(uint256 _pioneerId)`**: A Pioneer commits to active research, enabling them to accumulate Knowledge over time.
13. **`claimResearchOutput(uint256 _pioneerId)`**: Allows a Pioneer to claim accumulated Knowledge points since their last claim. These points contribute to the `globalKnowledge` pool. Updates Pioneer's `quantumAlignment` based on consistent contribution.
14. **`getGlobalKnowledge()`**: **(View)** Returns the total accumulated knowledge across the entire protocol.
15. **`getCurrentEpochKnowledge()`**: **(View)** Returns the knowledge accumulated *within the current epoch*.
16. **`calculateResearchYield(uint256 _pioneerId)`**: **(View)** Estimates the amount of Knowledge a Pioneer would yield based on its `quantumAlignment` and `researchFocus` per epoch.
17. **`advanceEpoch()`**: **(Permissioned/Time-based)** Advances the protocol to the next `epoch`. This can trigger global parameter shifts, reset epoch-specific counters, or open new discovery opportunities. In a production system, this could be permissioned by a DAO or triggered by time.
18. **`advanceEra()`**: **(Permissioned/Knowledge-based)** Checks if `globalKnowledge` has surpassed the threshold for the next `Era`. If so, it advances the protocol to the new era, potentially unlocking new features or modifying existing mechanics.
19. **`getCurrentEpoch()`**: **(View)** Returns the current epoch number.
20. **`getCurrentEra()`**: **(View)** Returns the current technological era of the protocol.
21. **`getEraThreshold(Era _era)`**: **(View)** Returns the knowledge points required to reach a specific era.
22. **`getTimeUntilNextEpoch()`**: **(View)** Calculates the time remaining until the next epoch can be advanced (if time-based).
23. **`setCosmicFluxData(bytes32 _fluxData)`**: **(Admin)** Simulates an on-chain oracle feed providing "cosmic flux data." This data influences the `evolveExoticMatter` function, making properties truly dynamic.
24. **`proposeParameterChange(bytes _callData, string calldata _description, uint256 _votingPeriod)`**: Allows a Pioneer to propose a change to a protocol parameter (e.g., `setDiscoveryProbability`, `setResearchRate`). Proposals have a voting period.
25. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows a Pioneer owner to cast a vote (for or against) on an active proposal. Voting power could be weighted by `quantumAlignment`.
26. **`executeProposal(uint256 _proposalId)`**: Executes a successful proposal after its voting period has ended and enough votes have been cast.
27. **`getProposalDetails(uint256 _proposalId)`**: **(View)** Retrieves the full details of a specific proposal.
28. **`hasVotedOnProposal(uint256 _proposalId, address _voter)`**: **(View)** Checks if a specific address has already voted on a given proposal.

---

This structure provides a rich, dynamic, and community-driven experience beyond standard token or NFT contracts. It focuses on collective progress, on-chain evolution, and strategic decision-making.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom error for better readability and gas efficiency
error NotPioneerOwner(uint256 pioneerId);
error PioneerAlreadyStaked(uint256 pioneerId);
error PioneerNotStaked(uint256 pioneerId);
error PioneerDoesNotExist(uint256 pioneerId);
error ExoticMatterDoesNotExist(uint256 matterId);
error NotExoticMatterOwner(uint256 matterId);
error InsufficientKnowledgeForEra();
error InvalidProposalState();
error VotingPeriodNotEnded();
error ProposalNotExecutable();
error AlreadyVoted();
error ProposalNotFound();
error NotEnoughMatterToSynthesize();
error DiscoveryFailed();
error UnauthorizedCall(); // For admin functions callable only by owner/DAO

contract QuantumLeap is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- ENUMS ---
    enum ResearchFocus { Astrobiology, QuantumPhysics, XenoEngineering, CosmicCartography }
    enum Era { Genesis, DawnOfExploration, GalacticExpansion, InterstellarCommunion, Singularity }
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed }

    // --- DATA STRUCTURES ---

    struct Pioneer {
        uint256 id;
        address owner;
        ResearchFocus researchFocus;
        uint256 quantumAlignment; // Reputation score, non-transferable
        uint256 lastResearchClaimEpoch;
        bool isStakedForResearch;
    }

    struct ExoticMatter {
        uint256 id;
        address owner;
        bytes32 propertiesHash; // Dynamic property, changes over time/events
        uint256 discoveryEpoch;
        uint256 evolutionLevel; // Can increase with synthesis or time
    }

    struct EraConfig {
        uint256 knowledgeThreshold;
        // Future: could include global multipliers for discovery, research, etc.
    }

    struct Proposal {
        uint256 id;
        address proposer;
        bytes callData; // Encoded function call to execute if proposal passes
        string description;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks unique voters
        ProposalState state;
    }

    // --- STATE VARIABLES ---

    // Global Counters
    Counters.Counter private _pioneerIdCounter;
    Counters.Counter private _exoticMatterIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Protocol State
    uint256 public globalKnowledge;
    uint256 public currentEpoch;
    Era public currentEra;
    bytes32 public cosmicFluxData; // Simulates external, dynamic data (e.g., from an oracle)

    // Configuration Parameters (adjustable via governance)
    uint256 public baseDiscoveryProbability; // Out of 1000 (e.g., 500 = 50% chance)
    uint256 public baseResearchRate; // Knowledge points per epoch per staked pioneer
    uint256 public baseSynthesisCost; // Amount of Exotic Matter NFTs required for synthesis

    // Mappings for Data Storage
    mapping(uint256 => Pioneer) public pioneers;
    mapping(uint256 => ExoticMatter) public exoticMatters;
    mapping(Era => EraConfig) public eraConfigurations;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => uint256) public epochKnowledgeAccumulated; // Knowledge accumulated in specific epoch

    // --- EVENTS ---
    event PioneerMinted(uint256 indexed pioneerId, address indexed owner, ResearchFocus initialFocus);
    event PioneerResearchFocusSet(uint256 indexed pioneerId, ResearchFocus newFocus);
    event ExoticMatterDiscovered(uint256 indexed matterId, uint256 indexed pioneerId, bytes32 propertiesHash);
    event ExoticMatterSynthesized(uint256 indexed newMatterId, uint256 indexed pioneerId, uint256[] burntMatterIds);
    event ExoticMatterEvolved(uint256 indexed matterId, bytes32 newPropertiesHash, uint256 newEvolutionLevel);
    event ResearchStaked(uint256 indexed pioneerId);
    event ResearchOutputClaimed(uint256 indexed pioneerId, uint256 knowledgeGained, uint256 newGlobalKnowledge);
    event EpochAdvanced(uint256 newEpoch);
    event EraAdvanced(Era newEra, uint256 knowledgeAtAdvance);
    event CosmicFluxDataSet(bytes32 newFluxData);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 votingEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ParameterChanged(string paramName, uint256 newValue); // Generic event for governance-driven parameter changes


    // --- CONSTRUCTOR ---
    constructor() ERC721("QuantumLeap Pioneer", "QLP") Ownable(msg.sender) {
        // Initialize base configurations (can be refined or moved to admin functions)
        baseDiscoveryProbability = 500; // 50% chance
        baseResearchRate = 100;        // 100 knowledge per epoch
        baseSynthesisCost = 2;         // 2 Exotic Matter NFTs to synthesize 1

        // Initialize Era thresholds
        // Genesis requires 0 knowledge (starting point)
        eraConfigurations[Era.Genesis] = EraConfig(0);
        eraConfigurations[Era.DawnOfExploration] = EraConfig(1000); // 1,000 knowledge
        eraConfigurations[Era.GalacticExpansion] = EraConfig(5000); // 5,000 knowledge
        eraConfigurations[Era.InterstellarCommunion] = EraConfig(20000); // 20,000 knowledge
        eraConfigurations[Era.Singularity] = EraConfig(100000); // 100,000 knowledge

        currentEpoch = 1;
        currentEra = Era.Genesis;
        cosmicFluxData = keccak256(abi.encodePacked("initial_flux"));
    }

    // --- MODIFIERS ---
    modifier onlyPioneerOwner(uint256 _pioneerId) {
        if (pioneers[_pioneerId].owner == address(0)) revert PioneerDoesNotExist(_pioneerId);
        if (pioneers[_pioneerId].owner != _msgSender()) revert NotPioneerOwner(_pioneerId);
        _;
    }

    modifier onlyExoticMatterOwner(uint256 _matterId) {
        if (exoticMatters[_matterId].owner == address(0)) revert ExoticMatterDoesNotExist(_matterId);
        if (exoticMatters[_matterId].owner != _msgSender()) revert NotExoticMatterOwner(_matterId);
        _;
    }

    modifier onlyActiveEra(Era requiredEra) {
        if (currentEra < requiredEra) revert UnauthorizedCall(); // More specific error desirable
        _;
    }

    // --- PIONEER MANAGEMENT ---

    /**
     * @notice Allows a user to mint a new "Pioneer" NFT.
     * @param _initialFocus The initial research focus for the new Pioneer.
     * @param _tokenURI The URI for the Pioneer's metadata.
     */
    function mintPioneer(ResearchFocus _initialFocus, string calldata _tokenURI) external {
        _pioneerIdCounter.increment();
        uint256 newPioneerId = _pioneerIdCounter.current();

        Pioneer storage newPioneer = pioneers[newPioneerId];
        newPioneer.id = newPioneerId;
        newPioneer.owner = _msgSender();
        newPioneer.researchFocus = _initialFocus;
        newPioneer.quantumAlignment = 100; // Starting quantum alignment
        newPioneer.lastResearchClaimEpoch = currentEpoch;
        newPioneer.isStakedForResearch = false;

        _safeMint(_msgSender(), newPioneerId);
        _setTokenURI(newPioneerId, _tokenURI);

        emit PioneerMinted(newPioneerId, _msgSender(), _initialFocus);
    }

    /**
     * @notice Allows a Pioneer owner to set or change their Pioneer's research focus.
     * @param _pioneerId The ID of the Pioneer NFT.
     * @param _focus The new research focus.
     */
    function setPioneerResearchFocus(uint256 _pioneerId, ResearchFocus _focus) external onlyPioneerOwner(_pioneerId) {
        pioneers[_pioneerId].researchFocus = _focus;
        emit PioneerResearchFocusSet(_pioneerId, _focus);
    }

    /**
     * @notice Retrieves the full details of a specific Pioneer NFT.
     * @param _pioneerId The ID of the Pioneer.
     * @return A tuple containing Pioneer details.
     */
    function getPioneerDetails(uint256 _pioneerId)
        external
        view
        returns (
            uint256 id,
            address owner,
            ResearchFocus researchFocus,
            uint256 quantumAlignment,
            uint256 lastResearchClaimEpoch,
            bool isStakedForResearch
        )
    {
        Pioneer storage p = pioneers[_pioneerId];
        if (p.owner == address(0)) revert PioneerDoesNotExist(_pioneerId);

        return (
            p.id,
            p.owner,
            p.researchFocus,
            p.quantumAlignment,
            p.lastResearchClaimEpoch,
            p.isStakedForResearch
        );
    }

    /**
     * @notice Returns the quantum alignment (reputation score) of a given Pioneer.
     * @param _pioneerId The ID of the Pioneer.
     * @return The quantum alignment score.
     */
    function getQuantumAlignment(uint256 _pioneerId) external view returns (uint256) {
        if (pioneers[_pioneerId].owner == address(0)) revert PioneerDoesNotExist(_pioneerId);
        return pioneers[_pioneerId].quantumAlignment;
    }

    // --- EXOTIC MATTER MANAGEMENT (DYNAMIC ERC721) ---

    /**
     * @notice Allows a Pioneer to attempt to discover new Exotic Matter.
     * Success is probabilistic and influenced by the Pioneer's quantum alignment.
     * @param _pioneerId The ID of the Pioneer attempting the discovery.
     * @param _tokenURI The URI for the new Exotic Matter's metadata.
     */
    function discoverExoticMatter(uint256 _pioneerId, string calldata _tokenURI) external onlyPioneerOwner(_pioneerId) {
        uint256 successRoll = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _pioneerId, _exoticMatterIdCounter.current()))) % 1000;
        uint256 effectiveProbability = baseDiscoveryProbability + (pioneers[_pioneerId].quantumAlignment / 10); // Higher alignment = better chance

        if (successRoll >= effectiveProbability) {
            _updateQuantumAlignment(_pioneerId, false); // Slight alignment decrease for failed attempt
            revert DiscoveryFailed();
        }

        _exoticMatterIdCounter.increment();
        uint256 newMatterId = _exoticMatterIdCounter.current();

        bytes32 initialProperties = keccak256(abi.encodePacked(block.timestamp, msg.sender, newMatterId, currentEpoch));

        ExoticMatter storage newMatter = exoticMatters[newMatterId];
        newMatter.id = newMatterId;
        newMatter.owner = _msgSender();
        newMatter.propertiesHash = initialProperties;
        newMatter.discoveryEpoch = currentEpoch;
        newMatter.evolutionLevel = 1;

        _safeMint(_msgSender(), newMatterId);
        _setTokenURI(newMatterId, _tokenURI);

        _updateQuantumAlignment(_pioneerId, true); // Increase alignment for successful discovery

        emit ExoticMatterDiscovered(newMatterId, _pioneerId, initialProperties);
    }

    /**
     * @notice Allows a Pioneer to combine (burn) multiple Exotic Matter NFTs to synthesize a new one.
     * The new NFT's properties are derived from the burnt ones, potentially increasing its evolution level.
     * @param _pioneerId The ID of the Pioneer performing synthesis.
     * @param _matterIdsToBurn An array of Exotic Matter NFT IDs to be burnt.
     * @param _newTokenURI The URI for the new synthesized Exotic Matter's metadata.
     */
    function synthesizeExoticMatter(uint256 _pioneerId, uint256[] calldata _matterIdsToBurn, string calldata _newTokenURI)
        external
        onlyPioneerOwner(_pioneerId)
    {
        if (_matterIdsToBurn.length < baseSynthesisCost) {
            revert NotEnoughMatterToSynthesize();
        }

        uint256 combinedEvolutionLevel = 0;
        bytes32 combinedPropertiesHash = 0;

        for (uint256 i = 0; i < _matterIdsToBurn.length; i++) {
            uint256 matterId = _matterIdsToBurn[i];
            if (exoticMatters[matterId].owner == address(0)) revert ExoticMatterDoesNotExist(matterId);
            if (exoticMatters[matterId].owner != _msgSender()) revert NotExoticMatterOwner(matterId);

            combinedEvolutionLevel += exoticMatters[matterId].evolutionLevel;
            combinedPropertiesHash = keccak256(abi.encodePacked(combinedPropertiesHash, exoticMatters[matterId].propertiesHash));

            _burn(matterId); // Burn the input Exotic Matter NFTs
            delete exoticMatters[matterId]; // Remove from mapping
        }

        _exoticMatterIdCounter.increment();
        uint256 newMatterId = _exoticMatterIdCounter.current();

        ExoticMatter storage newMatter = exoticMatters[newMatterId];
        newMatter.id = newMatterId;
        newMatter.owner = _msgSender();
        newMatter.propertiesHash = combinedPropertiesHash; // Simple combination, can be more complex
        newMatter.discoveryEpoch = currentEpoch;
        newMatter.evolutionLevel = combinedEvolutionLevel / _matterIdsToBurn.length + 1; // Average + 1 for new level

        _safeMint(_msgSender(), newMatterId);
        _setTokenURI(newMatterId, _newTokenURI);

        _updateQuantumAlignment(_pioneerId, true); // Increase alignment for successful synthesis

        emit ExoticMatterSynthesized(newMatterId, _pioneerId, _matterIdsToBurn);
    }

    /**
     * @notice Triggers the dynamic evolution of an Exotic Matter NFT. Its properties can change
     * based on global parameters (current epoch, cosmic flux data) and its own history.
     * @param _matterId The ID of the Exotic Matter NFT to evolve.
     */
    function evolveExoticMatter(uint256 _matterId) external onlyExoticMatterOwner(_matterId) {
        ExoticMatter storage matter = exoticMatters[_matterId];

        // Simulate complex evolution logic: properties change based on current global state
        bytes32 newProperties = keccak256(abi.encodePacked(
            matter.propertiesHash,
            cosmicFluxData,
            currentEpoch,
            uint256(currentEra)
        ));

        // Only update if properties actually changed to avoid unnecessary re-emits/state changes
        if (newProperties != matter.propertiesHash) {
            matter.propertiesHash = newProperties;
            matter.evolutionLevel++; // Evolution increases level
            emit ExoticMatterEvolved(_matterId, newProperties, matter.evolutionLevel);
        }
    }

    /**
     * @notice Retrieves the full details of a specific Exotic Matter NFT.
     * @param _matterId The ID of the Exotic Matter.
     * @return A tuple containing Exotic Matter details.
     */
    function getExoticMatterDetails(uint256 _matterId)
        external
        view
        returns (
            uint256 id,
            address owner,
            bytes32 propertiesHash,
            uint256 discoveryEpoch,
            uint256 evolutionLevel
        )
    {
        ExoticMatter storage em = exoticMatters[_matterId];
        if (em.owner == address(0)) revert ExoticMatterDoesNotExist(_matterId);

        return (em.id, em.owner, em.propertiesHash, em.discoveryEpoch, em.evolutionLevel);
    }

    // --- RESEARCH & KNOWLEDGE PROGRESSION ---

    /**
     * @notice A Pioneer commits to active research, enabling them to accumulate Knowledge over time.
     * @param _pioneerId The ID of the Pioneer to stake for research.
     */
    function stakeForResearch(uint256 _pioneerId) external onlyPioneerOwner(_pioneerId) {
        Pioneer storage pioneer = pioneers[_pioneerId];
        if (pioneer.isStakedForResearch) revert PioneerAlreadyStaked(_pioneerId);

        pioneer.isStakedForResearch = true;
        // Optionally, reset last claim epoch if staking afresh
        pioneer.lastResearchClaimEpoch = currentEpoch;
        emit ResearchStaked(_pioneerId);
    }

    /**
     * @notice Allows a Pioneer to claim accumulated Knowledge points since their last claim.
     * These points contribute to the globalKnowledge pool.
     * @param _pioneerId The ID of the Pioneer claiming research output.
     */
    function claimResearchOutput(uint256 _pioneerId) external onlyPioneerOwner(_pioneerId) {
        Pioneer storage pioneer = pioneers[_pioneerId];
        if (!pioneer.isStakedForResearch) revert PioneerNotStaked(_pioneerId);

        uint256 epochsPassed = currentEpoch - pioneer.lastResearchClaimEpoch;
        if (epochsPassed == 0) return; // No new epochs, no new knowledge

        uint256 knowledgeGained = calculateResearchYield(_pioneerId) * epochsPassed;
        globalKnowledge += knowledgeGained;
        epochKnowledgeAccumulated[currentEpoch] += knowledgeGained; // Track per epoch

        pioneer.lastResearchClaimEpoch = currentEpoch;
        _updateQuantumAlignment(_pioneerId, true); // Reward for claiming knowledge

        emit ResearchOutputClaimed(_pioneerId, knowledgeGained, globalKnowledge);
    }

    /**
     * @notice Returns the total accumulated knowledge across the entire protocol.
     * @return The global knowledge total.
     */
    function getGlobalKnowledge() external view returns (uint256) {
        return globalKnowledge;
    }

    /**
     * @notice Returns the knowledge accumulated within the current epoch.
     * @return The knowledge accumulated in the current epoch.
     */
    function getCurrentEpochKnowledge() external view returns (uint256) {
        return epochKnowledgeAccumulated[currentEpoch];
    }

    /**
     * @notice Estimates the amount of Knowledge a Pioneer would yield based on its quantum alignment and research focus per epoch.
     * @param _pioneerId The ID of the Pioneer.
     * @return The estimated knowledge yield per epoch.
     */
    function calculateResearchYield(uint256 _pioneerId) public view returns (uint256) {
        Pioneer storage pioneer = pioneers[_pioneerId];
        if (pioneer.owner == address(0)) revert PioneerDoesNotExist(_pioneerId);

        uint256 alignmentBonus = pioneer.quantumAlignment / 50; // Every 50 alignment points adds 1 to multiplier
        uint256 focusBonus = 0; // Specific focus could give bonuses
        if (pioneer.researchFocus == ResearchFocus.QuantumPhysics) focusBonus = 10;

        return baseResearchRate + alignmentBonus + focusBonus;
    }

    // --- EPOCH & ERA PROGRESSION ---

    /**
     * @notice Advances the protocol to the next epoch. Can be permissioned or time-based.
     * For this example, it's permissioned to the owner for simulation.
     */
    function advanceEpoch() external onlyOwner { // In production, consider time-based or DAO controlled
        currentEpoch++;
        // Reset any epoch-specific temporary states if necessary
        // epochKnowledgeAccumulated[currentEpoch] will start at 0 naturally

        // Check if a new era can be advanced to
        _tryAdvanceEra();

        emit EpochAdvanced(currentEpoch);
    }

    /**
     * @notice Private helper function to attempt advancing the era.
     * Checks if global knowledge has surpassed the threshold for the next Era.
     */
    function _tryAdvanceEra() private {
        Era nextEra = Era(uint256(currentEra) + 1);
        if (uint256(nextEra) > uint256(Era.Singularity)) {
            return; // No more eras defined
        }

        if (globalKnowledge >= eraConfigurations[nextEra].knowledgeThreshold) {
            currentEra = nextEra;
            emit EraAdvanced(currentEra, globalKnowledge);
            // Optionally, unlock new features or adjust global parameters here
        }
    }

    /**
     * @notice Public function to attempt advancing the era. Can be called by anyone but only succeeds if conditions are met.
     */
    function advanceEra() external {
        _tryAdvanceEra();
    }

    /**
     * @notice Returns the current epoch number.
     * @return The current epoch.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Returns the current technological era of the protocol.
     * @return The current era.
     */
    function getCurrentEra() external view returns (Era) {
        return currentEra;
    }

    /**
     * @notice Returns the knowledge points required to reach a specific era.
     * @param _era The era to query the threshold for.
     * @return The knowledge threshold for the specified era.
     */
    function getEraThreshold(Era _era) external view returns (uint256) {
        return eraConfigurations[_era].knowledgeThreshold;
    }

    /**
     * @notice Placeholder for calculating time until next epoch. In a real system,
     * this would depend on a predefined epoch duration.
     * @return Time in seconds until the next epoch (dummy value for now).
     */
    function getTimeUntilNextEpoch() external view returns (uint256) {
        // This would require a fixed epoch duration and last epoch advance timestamp
        // For simplicity, returning a dummy value or a placeholder.
        return 0; // Means it can be advanced manually by owner or always ready
    }

    // --- ON-CHAIN ORACLE/EXTERNAL DATA SIMULATION ---

    /**
     * @notice Simulates an on-chain oracle feed providing "cosmic flux data."
     * This data influences the evolveExoticMatter function, making properties truly dynamic.
     * @param _fluxData The new cosmic flux data.
     */
    function setCosmicFluxData(bytes32 _fluxData) external onlyOwner {
        cosmicFluxData = _fluxData;
        emit CosmicFluxDataSet(_fluxData);
    }

    /**
     * @notice Retrieves the current cosmic flux data.
     * @return The current cosmic flux data.
     */
    function getCosmicFluxData() external view returns (bytes32) {
        return cosmicFluxData;
    }

    // --- DECENTRALIZED GOVERNANCE (SIMPLIFIED) ---

    /**
     * @notice Allows any Pioneer owner to propose a change to a protocol parameter.
     * @param _callData The encoded function call (e.g., `abi.encodeWithSelector(this.setDiscoveryProbability.selector, new_value)`).
     * @param _description A description of the proposal.
     * @param _votingPeriod The duration of the voting period in seconds.
     */
    function proposeParameterChange(bytes calldata _callData, string calldata _description, uint256 _votingPeriod) external {
        // Simple check: proposer must own at least one pioneer to prevent spam
        bool foundPioneer = false;
        for (uint256 i = 1; i <= _pioneerIdCounter.current(); i++) {
            if (pioneers[i].owner == _msgSender()) {
                foundPioneer = true;
                break;
            }
        }
        if (!foundPioneer) revert UnauthorizedCall(); // More specific error desirable

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.callData = _callData;
        newProposal.description = _description;
        newProposal.votingEndTime = block.timestamp + _votingPeriod;
        newProposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, _msgSender(), _description, newProposal.votingEndTime);
    }

    /**
     * @notice Allows a Pioneer owner to cast a vote (for or against) on an active proposal.
     * Voting power could be weighted by quantum alignment (simplified to 1 vote per address here).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 || proposal.state != ProposalState.Active) revert InvalidProposalState();
        if (block.timestamp >= proposal.votingEndTime) revert VotingPeriodNotEnded();
        if (proposal.hasVoted[_msgSender()]) revert AlreadyVoted();

        // Simple check: voter must own at least one pioneer
        bool foundPioneer = false;
        for (uint256 i = 1; i <= _pioneerIdCounter.current(); i++) {
            if (pioneers[i].owner == _msgSender()) {
                foundPioneer = true;
                break;
            }
        }
        if (!foundPioneer) revert UnauthorizedCall(); // More specific error desirable

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit VoteCast(_proposalId, _msgSender(), _support);
    }

    /**
     * @notice Executes a successful proposal after its voting period has ended and enough votes have been cast.
     * Requires the proposal to have more 'for' votes than 'against' (simple majority).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 || proposal.state != ProposalState.Active) revert InvalidProposalState();
        if (block.timestamp < proposal.votingEndTime) revert ProposalNotExecutable(); // Voting period not over

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            // Execute the proposal's callData
            (bool success,) = address(this).call(proposal.callData);
            if (!success) {
                // Handle execution failure, maybe revert or log an error
                // For simplicity, we'll let it proceed but in real DAO, might need retry/revert
            }
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.state = ProposalState.Defeated;
            // No event for defeat, or add one if needed
        }
    }

    /**
     * @notice Retrieves the full details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            bytes memory callData,
            string memory description,
            uint256 votingEndTime,
            uint256 votesFor,
            uint256 votesAgainst,
            ProposalState state
        )
    {
        Proposal storage p = proposals[_proposalId];
        if (p.id == 0) revert ProposalNotFound();

        return (
            p.id,
            p.proposer,
            p.callData,
            p.description,
            p.votingEndTime,
            p.votesFor,
            p.votesAgainst,
            p.state
        );
    }

    /**
     * @notice Checks if a specific address has already voted on a given proposal.
     * @param _proposalId The ID of the proposal.
     * @param _voter The address to check.
     * @return True if the address has voted, false otherwise.
     */
    function hasVotedOnProposal(uint256 _proposalId, address _voter) external view returns (bool) {
        Proposal storage p = proposals[_proposalId];
        if (p.id == 0) revert ProposalNotFound();
        return p.hasVoted[_voter];
    }

    // --- PROTOCOL CONFIGURATION (ADMIN/GOVERNANCE) ---

    /**
     * @notice Allows the owner or successful proposal to set a new era threshold.
     * @param _era The era to set the threshold for.
     * @param _threshold The new knowledge threshold.
     */
    function setEraThreshold(Era _era, uint256 _threshold) external onlyOwner {
        eraConfigurations[_era].knowledgeThreshold = _threshold;
        emit ParameterChanged("EraThreshold", _threshold);
    }

    /**
     * @notice Allows the owner or successful proposal to set the base discovery probability.
     * @param _newProbability The new probability (0-1000).
     */
    function setDiscoveryProbability(uint256 _newProbability) external onlyOwner {
        require(_newProbability <= 1000, "Probability must be <= 1000");
        baseDiscoveryProbability = _newProbability;
        emit ParameterChanged("DiscoveryProbability", _newProbability);
    }

    /**
     * @notice Allows the owner or successful proposal to set the base research rate.
     * @param _newRate The new research rate.
     */
    function setResearchRate(uint256 _newRate) external onlyOwner {
        baseResearchRate = _newRate;
        emit ParameterChanged("ResearchRate", _newRate);
    }

    /**
     * @notice Allows the owner or successful proposal to set the synthesis cost.
     * @param _newCost The new number of Exotic Matter NFTs required for synthesis.
     */
    function setSynthesisCost(uint256 _newCost) external onlyOwner {
        baseSynthesisCost = _newCost;
        emit ParameterChanged("SynthesisCost", _newCost);
    }

    // --- INTERNAL HELPERS ---

    /**
     * @dev Internal function to update a Pioneer's quantum alignment.
     * @param _pioneerId The ID of the Pioneer.
     * @param _success True if the action was successful, false if it was a failure.
     */
    function _updateQuantumAlignment(uint256 _pioneerId, bool _success) internal {
        Pioneer storage pioneer = pioneers[_pioneerId];
        if (_success) {
            pioneer.quantumAlignment += 5; // Reward for successful action
        } else {
            if (pioneer.quantumAlignment > 1) { // Prevent going to 0 or negative
                pioneer.quantumAlignment -= 1; // Penalty for failed action
            }
        }
        // Cap alignment to prevent overflow or excessive bonus, e.g., max 1000
        if (pioneer.quantumAlignment > 1000) {
            pioneer.quantumAlignment = 1000;
        }
    }
}
```