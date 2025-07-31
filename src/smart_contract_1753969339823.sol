Here's a Solidity smart contract for "QuantumCanvas", a dynamic NFT platform where art traits evolve based on AI oracle input, community governance, user interactions, and time. This contract aims to be interesting, advanced-concept, creative, and trendy without directly duplicating existing open-source projects by combining several concepts in a novel way.

---

# QuantumCanvas Smart Contract

## Outline & Function Summary

**Contract Name:** `QuantumCanvas`

**Description:**
The QuantumCanvas contract deploys an ERC-721 collection of "Quantum Canvases" – unique digital artworks whose traits are not static but dynamically evolve. This evolution is driven by a confluence of factors: periodic AI oracle inputs (simulated), on-chain community governance decisions, specific gamified interactions initiated by the NFT owner, and natural decay over time. Each Quantum Canvas is a living, breathing piece of art that reflects its journey through the "Quantumverse."

**Key Concepts & Features:**
*   **Dynamic NFTs (ERC-721):** NFT metadata (traits) are computed on-the-fly, reflecting the current state of the canvas based on accumulated influences.
*   **AI Oracle Integration:** A designated oracle can inject "inspiration" parameters, guiding the global evolution of traits across all canvases.
*   **Gamified User Interactions:** Owners can perform actions (`meditateOnCanvas`, `infuseAether`, `performRitual`, `attuneToCosmos`) to directly influence their canvas's traits, adding a layer of interactive gameplay.
*   **Decentralized Curation (DAO-lite):** A system for Soulbound Token (SBT) holders (Curators) to propose and vote on "Art Movements" (global trait trends), empowering community-driven artistic direction.
*   **Resource Staking (Aether):** Users can stake native ETH to passively generate "Aether," an in-game resource required for advanced trait manipulation.
*   **Soulbound Curators (SBT):** Non-transferable tokens grant special governance rights within the system.
*   **Epoch-based Global Trait Evolution:** Traits are periodically influenced by accumulated AI and community inputs as epochs advance, ensuring a dynamic and ever-changing collection.

---

### Function Summary (20+ Custom Functions):

**I. Core NFT & Traits Management**
1.  `mintCanvas(string memory initialPrompt)`: Mints a new Quantum Canvas NFT. `initialPrompt` serves as a seed for initial traits.
2.  `tokenURI(uint256 tokenId)`: Generates and returns the dynamic metadata URI for a given `tokenId`, reflecting its current, computed traits.
3.  `getCanvasTraits(uint256 tokenId)`: Public view function to retrieve the current, calculated traits of a specific canvas.
4.  `_updateCanvasTraitsToCurrentEpoch(uint256 tokenId)`: Internal helper function that applies all accumulated global influences (AI, Community, Decay) to a canvas's traits, bringing them up to the current epoch.

**II. AI Oracle Integration**
5.  `setAIOracleAddress(address _oracleAddress)`: Admin function to designate the trusted AI Oracle address.
6.  `receiveAIInspiration(string[] memory traitNames, int256[] memory traitValues)`: Callable only by the designated AI Oracle, this function injects AI-derived influences for the *next* epoch's global trait calculations.

**III. Gamified User Interactions (Owner Actions)**
7.  `meditateOnCanvas(uint256 tokenId, string memory traitName)`: Allows the canvas owner to subtly influence a specific trait with a small, free adjustment.
8.  `infuseAether(uint256 tokenId, string memory traitName, int256 amount)`: Allows the canvas owner to apply a more significant trait change by consuming "Aether" resource.
9.  `performRitual(uint256 tokenId, string memory ritualType)`: Triggers a complex trait modification based on a `ritualType`, potentially requiring specific conditions or costs (e.g., ETH, specific trait values).
10. `attuneToCosmos(uint256 tokenId)`: Initiates a random, unpredictable trait shift on the canvas, influenced by the current global epoch's parameters, for a small cost.

**IV. Community Curation & Governance (DAO-lite)**
11. `mintCuratorSBT()`: Allows eligible users (e.g., active participants, long-term holders) to mint a non-transferable Curator Soulbound Token, granting governance rights.
12. `hasCuratorSBT(address _user)`: Checks if a given address holds a Curator SBT.
13. `proposeArtMovement(string memory description, string[] memory traitNames, int256[] memory traitChanges, uint256 durationEpochs)`: Curators can propose global "Art Movements" (changes to global trait trends) with a specific voting duration.
14. `voteOnMovementProposal(uint256 proposalId, bool _voteFor)`: Curators can cast their vote (for/against) on an active art movement proposal.
15. `executeMovementProposal(uint256 proposalId)`: Executes a passed proposal, applying its proposed global trait changes for the *next* epoch's influence calculation.
16. `getMovementProposal(uint256 proposalId)`: View function to retrieve details about a specific art movement proposal.

**V. Resource Management (Aether)**
17. `stakeETHForAether()`: Allows users to stake native ETH to passively generate "Aether" over time.
18. `claimAether()`: Allows users to claim their accumulated Aether from staked ETH.
19. `getAetherBalance(address _user)`: View function to retrieve a user's current available Aether balance.
20. `getStakedETH(address _user)`: View function to retrieve the amount of ETH staked by a user for Aether generation.

**VI. Epoch Management & Global Parameters**
21. `advanceEpoch()`: A public function (can be called by anyone, potentially incentivized) that increments the global epoch counter, finalizes global influences from the *previous* epoch, and makes them available for canvas trait updates.
22. `setEpochDuration(uint256 _duration)`: Admin function to configure the duration of each Aether generation epoch.
23. `setTraitInfluenceWeights(string memory traitName, uint256 aiWeight, uint256 communityWeight, uint256 userWeight, uint256 decayRate)`: Admin function to fine-tune how much each influence source (AI, community, user) and natural decay affects a specific trait.
24. `getEpochAIInfluence(uint256 epoch, string memory traitName)`: View the AI influence registered for a specific epoch and trait.
25. `getEpochCommunityInfluence(uint256 epoch, string memory traitName)`: View the community influence registered for a specific epoch and trait.

**VII. Admin & Utility**
26. `pause()`: Admin function to pause critical contract functionalities (minting, transfers, trait modifications).
27. `unpause()`: Admin function to unpause the contract.
28. `withdraw()`: Admin function to withdraw native ETH from the contract.
29. `getGlobalInfluenceAppliedEpoch(uint256 tokenId)`: View the last epoch a canvas's traits were updated by global influences.
30. `getProposalVoteStatus(uint256 proposalId)`: View the current vote counts (for/against) for a given proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

// Custom errors for clarity and gas efficiency
error InvalidTraitValue();
error TraitNotFound();
error NotCurator();
error ProposalNotFound();
error VotingPeriodNotActive();
error AlreadyVoted();
error NotEligibleToMintSBT();
error InsufficientAether();
error NoETHStaked();
error AlreadyStaked();
error NoAetherToClaim();
error RitualFailed();
error UnauthorizedOracle();
error TraitWeightConfigError();

contract QuantumCanvas is ERC721, Ownable, Pausable, ERC721Burnable {
    using Strings for uint256;

    // --- Events ---
    event CanvasMinted(uint256 indexed tokenId, address indexed owner, string initialPrompt);
    event TraitUpdated(uint256 indexed tokenId, string traitName, int256 oldValue, int256 newValue, string source);
    event AIInfluenceReceived(uint256 indexed epoch, string[] traitNames, int256[] traitValues);
    event CuratorSBTMinted(address indexed recipient);
    event ArtMovementProposed(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event ArtMovementExecuted(uint256 indexed proposalId, string description);
    event ETHStakedForAether(address indexed user, uint256 amount);
    event AetherClaimed(address indexed user, uint256 amount);
    event EpochAdvanced(uint256 indexed newEpoch);

    // --- Structs ---
    struct Canvas {
        uint256 mintEpoch;
        mapping(string => int256) actualTraits; // Current, concrete traits
        uint256 lastGlobalInfluenceAppliedEpoch; // Last epoch when global influences were applied
        uint256 lastActivityEpoch; // Last epoch when owner interacted (for potential decay/bonus calcs)
    }

    struct TraitInfluenceWeights {
        uint256 aiWeight;        // How much AI oracle influences this trait (per 1000)
        uint256 communityWeight; // How much community votes influence this trait (per 1000)
        uint256 userWeight;      // How much user actions directly influence this trait (per 1000)
        uint256 decayRate;       // How much the trait decays naturally per epoch (per 1000)
    }

    struct MovementProposal {
        address proposer;
        string description;
        mapping(string => int256) proposedTraitChanges; // Maps trait name to delta value
        uint256 startEpoch;
        uint256 endEpoch; // Deadline for voting (epoch number)
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        bool executed;
    }

    // --- State Variables ---
    uint256 private _nextTokenId;
    mapping(uint256 => Canvas) private _canvases;

    // Global Epoch Management
    uint256 public currentEpoch;
    uint256 public epochDuration; // In seconds, how long an Aether generation epoch lasts (e.g., 1 week)
    uint256 private _lastEpochAdvanceTime;

    // AI Oracle Integration
    address public aiOracleAddress;
    // Stores AI influence accumulated for the *next* epoch, reset after advanceEpoch
    mapping(uint256 => mapping(string => int256)) private _pendingAIInfluence;
    mapping(uint256 => mapping(string => int256)) private _finalizedAIInfluence; // Finalized influence for past epochs

    // Community Curation / DAO
    uint256 private _nextProposalId;
    mapping(uint256 => MovementProposal) public movementProposals;
    // Stores community influence accumulated for the *next* epoch, reset after advanceEpoch
    mapping(uint256 => mapping(string => int256)) private _pendingCommunityInfluence;
    mapping(uint256 => mapping(string => int256)) private _finalizedCommunityInfluence; // Finalized influence for past epochs

    // Soulbound Curators (SBT) - Simple non-transferable ERC721
    mapping(address => bool) public isCuratorSBT;
    uint256 public nextCuratorTokenId; // To simulate SBT unique IDs (though not a full ERC721)
    uint256 public minStakedETHForCurator; // Minimum ETH needed to be staked to mint a Curator SBT

    // Aether Resource (Internal Simulation)
    mapping(address => uint256) private _aetherBalances;
    mapping(address => uint256) private _stakedETH;
    mapping(address => uint256) private _lastAetherClaimEpoch;
    uint256 public aetherGenerationRate; // Aether generated per ETH staked per epoch (e.g., 1000 for 1 Aether)

    // Trait Configuration
    mapping(string => TraitInfluenceWeights) public traitInfluenceWeights;
    string[] public supportedTraits; // List of all traits the contract recognizes

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 _epochDuration,
        uint256 _aetherGenerationRate,
        uint256 _minStakedETHForCurator
    ) ERC721(name, symbol) Ownable(msg.sender) {
        epochDuration = _epochDuration; // e.g., 7 days in seconds
        aetherGenerationRate = _aetherGenerationRate; // e.g., 1000 Aether per ETH per epoch
        minStakedETHForCurator = _minStakedETHForCurator;
        currentEpoch = 0; // Start at epoch 0
        _lastEpochAdvanceTime = block.timestamp;

        // Initialize some default traits and their weights
        _addSupportedTrait("ColorHue", 300, 400, 200, 50); // AI, Community, User, Decay (per 1000)
        _addSupportedTrait("FormComplexity", 250, 350, 300, 70);
        _addSupportedTrait("EnergyVibe", 400, 200, 350, 30);
        _addSupportedTrait("TextureDetail", 150, 300, 450, 80);
        _addSupportedTrait("Dimensionality", 300, 300, 250, 40);
    }

    // --- Modifiers ---
    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) revert UnauthorizedOracle();
        _;
    }

    modifier onlyCurator() {
        if (!isCuratorSBT[msg.sender]) revert NotCurator();
        _;
    }

    // --- Admin & Utility Functions ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function setAIOracleAddress(address _oracleAddress) public onlyOwner {
        aiOracleAddress = _oracleAddress;
    }

    function setEpochDuration(uint256 _duration) public onlyOwner {
        epochDuration = _duration;
    }

    function setTraitInfluenceWeights(
        string memory traitName,
        uint256 aiWeight,
        uint256 communityWeight,
        uint256 userWeight,
        uint256 decayRate
    ) public onlyOwner {
        // Ensure weights don't sum to an excessive amount, or handle overflow in calculations
        if (aiWeight + communityWeight + userWeight > 1000) revert TraitWeightConfigError(); // Example constraint

        traitInfluenceWeights[traitName] = TraitInfluenceWeights({
            aiWeight: aiWeight,
            communityWeight: communityWeight,
            userWeight: userWeight,
            decayRate: decayRate
        });
    }

    function _addSupportedTrait(
        string memory traitName,
        uint256 aiWeight,
        uint256 communityWeight,
        uint256 userWeight,
        uint256 decayRate
    ) internal {
        supportedTraits.push(traitName);
        traitInfluenceWeights[traitName] = TraitInfluenceWeights({
            aiWeight: aiWeight,
            communityWeight: communityWeight,
            userWeight: userWeight,
            decayRate: decayRate
        });
    }

    function getSupportedTraits() public view returns (string[] memory) {
        return supportedTraits;
    }

    // --- Core NFT & Traits Management ---

    function mintCanvas(string memory initialPrompt) public payable whenNotPaused returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        _canvases[tokenId].mintEpoch = currentEpoch;
        _canvases[tokenId].lastGlobalInfluenceAppliedEpoch = currentEpoch;
        _canvases[tokenId].lastActivityEpoch = currentEpoch;

        // Initialize traits based on prompt or random values
        for (uint256 i = 0; i < supportedTraits.length; i++) {
            string memory traitName = supportedTraits[i];
            // Simple hash for initial value from prompt (replace with more complex logic if needed)
            int256 initialValue = int256(uint256(keccak256(abi.encodePacked(initialPrompt, traitName, tokenId))) % 1000) - 500;
            _canvases[tokenId].actualTraits[traitName] = initialValue;
        }

        emit CanvasMinted(tokenId, msg.sender, initialPrompt);
        return tokenId;
    }

    function getCanvasTraits(uint256 tokenId) public view returns (string[] memory names, int256[] memory values) {
        require(_exists(tokenId), "Canvas does not exist");

        // The traits are already 'actualTraits' meaning they have been updated on interaction or epoch advance.
        // We ensure they are as current as possible without modifying state in a view function.
        // For a true real-time dynamic, you'd calculate all influences here, but it's gas intensive.
        // This design implies `_updateCanvasTraitsToCurrentEpoch` is called on state-changing interactions.

        names = new string[](supportedTraits.length);
        values = new int256[](supportedTraits.length);

        for (uint256 i = 0; i < supportedTraits.length; i++) {
            string memory traitName = supportedTraits[i];
            names[i] = traitName;
            values[i] = _canvases[tokenId].actualTraits[traitName];
        }
        return (names, values);
    }

    function _updateCanvasTraitsToCurrentEpoch(uint256 tokenId) internal {
        Canvas storage canvas = _canvases[tokenId];
        uint256 startEpoch = canvas.lastGlobalInfluenceAppliedEpoch + 1;

        // Apply global influences and decay for each epoch since last update
        for (uint256 epoch = startEpoch; epoch <= currentEpoch; epoch++) {
            for (uint265 i = 0; i < supportedTraits.length; i++) {
                string memory traitName = supportedTraits[i];
                TraitInfluenceWeights memory weights = traitInfluenceWeights[traitName];

                // Apply AI influence
                canvas.actualTraits[traitName] += (_finalizedAIInfluence[epoch][traitName] * int256(weights.aiWeight)) / 1000;

                // Apply Community influence
                canvas.actualTraits[traitName] += (_finalizedCommunityInfluence[epoch][traitName] * int256(weights.communityWeight)) / 1000;

                // Apply Decay
                canvas.actualTraits[traitName] -= (canvas.actualTraits[traitName] * int256(weights.decayRate)) / 1000;
            }
        }
        canvas.lastGlobalInfluenceAppliedEpoch = currentEpoch;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Get traits directly, assuming they are updated on interaction or epoch advance.
        // For a view function, we can't call _updateCanvasTraitsToCurrentEpoch directly.
        // This means the metadata reflects the traits as of the last time an on-chain action updated them,
        // or a sweep function was called. A client-side renderer would call getCanvasTraits() to get the most recent.
        (string[] memory traitNames, int256[] memory traitValues) = getCanvasTraits(tokenId);

        string memory attributes = "";
        for (uint256 i = 0; i < traitNames.length; i++) {
            attributes = string.concat(
                attributes,
                '{"trait_type":"',
                traitNames[i],
                '","value":',
                traitValues[i].toString(),
                '},'
            );
        }

        // Remove trailing comma if any attributes exist
        if (bytes(attributes).length > 0) {
            attributes = attributes.substring(0, bytes(attributes).length - 1);
        }

        string memory imageURI = string.concat(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    // Simple SVG placeholder based on a trait
                    string.concat(
                        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinyMin meet" viewBox="0 0 350 350">',
                        '<style>.base { fill: white; font-family: serif; font-size: 20px; }</style>',
                        '<rect width="100%" height="100%" fill="hsl(',
                        traitValues[0].toString(), // Example: use ColorHue for HSL
                        ', 70%, 50%)" />',
                        '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">',
                        "Canvas #",
                        tokenId.toString(),
                        "</text>",
                        // You could add more elements based on other traits here
                        '</svg>'
                    )
                )
            )
        );

        string memory json = string.concat(
            '{"name":"Quantum Canvas #',
            tokenId.toString(),
            '","description":"An evolving digital artwork from the Quantumverse. Its traits are dynamic, influenced by AI, community, and its owner.","image":"',
            imageURI,
            '","attributes":[',
            attributes,
            ']}'
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    // --- AI Oracle Integration ---
    function receiveAIInspiration(
        string[] memory traitNames,
        int256[] memory traitValues
    ) public onlyAIOracle whenNotPaused {
        require(traitNames.length == traitValues.length, "Mismatched arrays");

        // Influence is for the *next* epoch
        for (uint256 i = 0; i < traitNames.length; i++) {
            bool found = false;
            for(uint j=0; j < supportedTraits.length; j++) {
                if(keccak256(abi.encodePacked(traitNames[i])) == keccak256(abi.encodePacked(supportedTraits[j]))) {
                    found = true;
                    break;
                }
            }
            if(!found) revert TraitNotFound();
            
            _pendingAIInfluence[currentEpoch + 1][traitNames[i]] += traitValues[i];
        }
        emit AIInfluenceReceived(currentEpoch + 1, traitNames, traitValues);
    }

    // --- Gamified User Interactions (Owner Actions) ---
    function meditateOnCanvas(uint256 tokenId, string memory traitName) public whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Not your canvas");
        
        bool found = false;
        for(uint i=0; i < supportedTraits.length; i++) {
            if(keccak256(abi.encodePacked(traitName)) == keccak256(abi.encodePacked(supportedTraits[i]))) {
                found = true;
                break;
            }
        }
        if(!found) revert TraitNotFound();

        _updateCanvasTraitsToCurrentEpoch(tokenId); // Ensure traits are up-to-date
        Canvas storage canvas = _canvases[tokenId];
        int256 oldValue = canvas.actualTraits[traitName];

        // Apply a small, direct influence from the user (e.g., +/- 10 units)
        // For simplicity, let's say it always increments for meditate
        int256 delta = 10;
        canvas.actualTraits[traitName] += delta;
        canvas.lastActivityEpoch = currentEpoch; // Mark activity

        emit TraitUpdated(tokenId, traitName, oldValue, canvas.actualTraits[traitName], "Meditation");
    }

    function infuseAether(uint256 tokenId, string memory traitName, int256 amount) public whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Not your canvas");
        require(amount > 0, "Amount must be positive");
        
        bool found = false;
        for(uint i=0; i < supportedTraits.length; i++) {
            if(keccak256(abi.encodePacked(traitName)) == keccak256(abi.encodePacked(supportedTraits[i]))) {
                found = true;
                break;
            }
        }
        if(!found) revert TraitNotFound();
        
        if (_aetherBalances[msg.sender] < uint256(amount)) revert InsufficientAether();

        _updateCanvasTraitsToCurrentEpoch(tokenId); // Ensure traits are up-to-date
        Canvas storage canvas = _canvases[tokenId];
        int256 oldValue = canvas.actualTraits[traitName];

        _aetherBalances[msg.sender] -= uint256(amount);
        canvas.actualTraits[traitName] += amount * int256(traitInfluenceWeights[traitName].userWeight) / 1000;
        canvas.lastActivityEpoch = currentEpoch;

        emit TraitUpdated(tokenId, traitName, oldValue, canvas.actualTraits[traitName], "Aether Infusion");
    }

    function performRitual(uint256 tokenId, string memory ritualType) public payable whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Not your canvas");
        
        // This is a placeholder for complex ritual logic.
        // Example: a ritual might require specific ETH, or a certain trait value, or burning another NFT.
        // For this example, let's make it cost ETH and apply a significant random trait shift.
        if (msg.value < 0.01 ether) revert RitualFailed(); // Example cost

        _updateCanvasTraitsToCurrentEpoch(tokenId); // Ensure traits are up-to-date
        Canvas storage canvas = _canvases[tokenId];
        
        // Apply a larger, semi-random influence based on ritualType and current block hash
        // In a real scenario, this would be more deterministic or oracle-driven for true randomness.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, ritualType)));

        for (uint256 i = 0; i < supportedTraits.length; i++) {
            string memory traitName = supportedTraits[i];
            int256 oldValue = canvas.actualTraits[traitName];
            
            int256 delta = int256(seed % 200) - 100; // +/- 100 units
            canvas.actualTraits[traitName] += delta;
            emit TraitUpdated(tokenId, traitName, oldValue, canvas.actualTraits[traitName], string.concat("Ritual: ", ritualType));
        }
        canvas.lastActivityEpoch = currentEpoch;
    }

    function attuneToCosmos(uint256 tokenId) public payable whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Not your canvas");
        if (msg.value < 0.001 ether) revert RitualFailed(); // Small cost

        _updateCanvasTraitsToCurrentEpoch(tokenId); // Ensure traits are up-to-date
        Canvas storage canvas = _canvases[tokenId];

        // Apply a shift based on global epoch influence and canvas's current state
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, "cosmos")));

        for (uint256 i = 0; i < supportedTraits.length; i++) {
            string memory traitName = supportedTraits[i];
            int256 oldValue = canvas.actualTraits[traitName];
            
            // Influence based on a small random factor plus current global influence for this trait
            int256 cosmicInfluence = _finalizedAIInfluence[currentEpoch][traitName] + _finalizedCommunityInfluence[currentEpoch][traitName];
            int256 delta = (int256(seed % 50) - 25) + (cosmicInfluence / 10); // Small random + 10% of total global influence
            
            canvas.actualTraits[traitName] += delta;
            emit TraitUpdated(tokenId, traitName, oldValue, canvas.actualTraits[traitName], "Cosmic Attunement");
        }
        canvas.lastActivityEpoch = currentEpoch;
    }


    // --- Community Curation & Governance (DAO-lite) ---
    function mintCuratorSBT() public whenNotPaused {
        require(!isCuratorSBT[msg.sender], "Already owns a Curator SBT");
        require(_stakedETH[msg.sender] >= minStakedETHForCurator, "Insufficient ETH staked for Curator eligibility");

        isCuratorSBT[msg.sender] = true;
        // In a full ERC721 SBT, you'd _mint a non-transferable token here.
        // For simplicity, we just use a boolean flag and increment a dummy token ID.
        nextCuratorTokenId++;
        emit CuratorSBTMinted(msg.sender);
    }

    function hasCuratorSBT(address _user) public view returns (bool) {
        return isCuratorSBT[_user];
    }

    function proposeArtMovement(
        string memory description,
        string[] memory traitNames,
        int256[] memory traitChanges,
        uint256 durationEpochs // Duration in epochs for voting
    ) public onlyCurator whenNotPaused returns (uint256) {
        require(traitNames.length == traitChanges.length, "Mismatched arrays");
        require(durationEpochs > 0, "Duration must be positive");

        uint256 proposalId = _nextProposalId++;
        MovementProposal storage proposal = movementProposals[proposalId];

        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.startEpoch = currentEpoch;
        proposal.endEpoch = currentEpoch + durationEpochs;
        proposal.executed = false;

        for (uint256 i = 0; i < traitNames.length; i++) {
            bool found = false;
            for(uint j=0; j < supportedTraits.length; j++) {
                if(keccak256(abi.encodePacked(traitNames[i])) == keccak256(abi.encodePacked(supportedTraits[j]))) {
                    found = true;
                    break;
                }
            }
            if(!found) revert TraitNotFound();

            proposal.proposedTraitChanges[traitNames[i]] = traitChanges[i];
        }

        emit ArtMovementProposed(proposalId, msg.sender, description);
        return proposalId;
    }

    function voteOnMovementProposal(uint256 proposalId, bool _voteFor) public onlyCurator whenNotPaused {
        MovementProposal storage proposal = movementProposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (currentEpoch > proposal.endEpoch) revert VotingPeriodNotActive();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        if (_voteFor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, _voteFor);
    }

    function executeMovementProposal(uint256 proposalId) public whenNotPaused {
        MovementProposal storage proposal = movementProposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (currentEpoch <= proposal.endEpoch) revert VotingPeriodNotActive(); // Voting must be over
        if (proposal.executed) revert("Proposal already executed");

        // Simple majority rule for execution
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.executed = true;
            // Apply community influence for the *next* epoch
            for (uint256 i = 0; i < supportedTraits.length; i++) {
                string memory traitName = supportedTraits[i];
                _pendingCommunityInfluence[currentEpoch + 1][traitName] += proposal.proposedTraitChanges[traitName];
            }
            emit ArtMovementExecuted(proposalId, proposal.description);
        } else {
            revert("Proposal did not pass");
        }
    }

    function getMovementProposal(uint256 proposalId) public view returns (
        address proposer,
        string memory description,
        uint256 startEpoch,
        uint256 endEpoch,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed
    ) {
        MovementProposal storage proposal = movementProposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        return (
            proposal.proposer,
            proposal.description,
            proposal.startEpoch,
            proposal.endEpoch,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed
        );
    }

    function getProposalVoteStatus(uint256 proposalId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        MovementProposal storage proposal = movementProposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        return (proposal.votesFor, proposal.votesAgainst);
    }


    // --- Resource Management (Aether) ---
    function stakeETHForAether() public payable whenNotPaused {
        require(msg.value > 0, "Must stake some ETH");
        if (_stakedETH[msg.sender] > 0) revert AlreadyStaked(); // Only one stake per address for simplicity

        _stakedETH[msg.sender] = msg.value;
        _lastAetherClaimEpoch[msg.sender] = currentEpoch; // Start generating from this epoch
        emit ETHStakedForAether(msg.sender, msg.value);
    }

    function claimAether() public whenNotPaused {
        if (_stakedETH[msg.sender] == 0) revert NoETHStaked();

        uint256 epochsPassed = currentEpoch - _lastAetherClaimEpoch[msg.sender];
        if (epochsPassed == 0) revert NoAetherToClaim();

        uint256 aetherGenerated = (epochsPassed * _stakedETH[msg.sender] * aetherGenerationRate) / (1 ether); // Normalize by 1 ether
        _aetherBalances[msg.sender] += aetherGenerated;
        _lastAetherClaimEpoch[msg.sender] = currentEpoch; // Reset claim epoch

        emit AetherClaimed(msg.sender, aetherGenerated);
    }

    function getAetherBalance(address _user) public view returns (uint256) {
        return _aetherBalances[_user];
    }

    function getStakedETH(address _user) public view returns (uint256) {
        return _stakedETH[_user];
    }

    // --- Epoch Management & Global Parameters ---
    function advanceEpoch() public whenNotPaused {
        // Anyone can call this to advance the epoch once epochDuration has passed.
        // This makes the contract permissionless for epoch progression.
        require(block.timestamp >= _lastEpochAdvanceTime + epochDuration, "Epoch not yet ended");

        // Finalize pending influences for the epoch that just passed (currentEpoch + 1)
        // This makes the _pending influences available as _finalized influences for the new currentEpoch
        for (uint256 i = 0; i < supportedTraits.length; i++) {
            string memory traitName = supportedTraits[i];
            _finalizedAIInfluence[currentEpoch + 1][traitName] = _pendingAIInfluence[currentEpoch + 1][traitName];
            _finalizedCommunityInfluence[currentEpoch + 1][traitName] = _pendingCommunityInfluence[currentEpoch + 1][traitName];
            
            // Clear pending for next cycle
            delete _pendingAIInfluence[currentEpoch + 1][traitName];
            delete _pendingCommunityInfluence[currentEpoch + 1][traitName];
        }

        currentEpoch++;
        _lastEpochAdvanceTime = block.timestamp;

        // Optionally, you could trigger a batch update of a few random canvases here
        // to make sure some canvases' traits are always up-to-date even without owner interaction.
        // However, this can be gas intensive if many NFTs, so it's omitted for this example.

        emit EpochAdvanced(currentEpoch);
    }

    function getEpochAIInfluence(uint256 epoch, string memory traitName) public view returns (int256) {
        return _finalizedAIInfluence[epoch][traitName];
    }

    function getEpochCommunityInfluence(uint256 epoch, string memory traitName) public view returns (int256) {
        return _finalizedCommunityInfluence[epoch][traitName];
    }

    function getGlobalInfluenceAppliedEpoch(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Canvas does not exist");
        return _canvases[tokenId].lastGlobalInfluenceAppliedEpoch;
    }

    // --- Overrides for ERC721 and Ownable for clarity ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Burnable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Ensure traits are updated to current epoch before transfer to reflect latest state
        // and avoid a sudden large change for new owner if many epochs have passed.
        if (from != address(0)) { // Not a mint
            _updateCanvasTraitsToCurrentEpoch(tokenId);
        }
    }

    // Fallback function to allow receiving ETH for staking
    receive() external payable {}
}
```