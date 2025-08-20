Here's a Solidity smart contract named "EchelonEchoes: Generative Sentient NFT Network". This contract aims to be interesting, advanced-concept, creative, and trendy by introducing dynamically evolving NFTs ("Echoes") whose traits are influenced by on-chain interactions and a simulated AI oracle. It also incorporates a fungible resource ("Essence"), inter-NFT mechanics like "harmonization" and "sentience projection," and a challenge system, creating a vibrant, emergent on-chain ecosystem.

To address the "don't duplicate any open source" constraint, this contract implements core NFT (ERC-721-like) and fungible token (ERC-20-like) functionalities internally with custom logic and naming, rather than inheriting from standard OpenZeppelin or similar libraries. While basic Solidity patterns and algorithms (like Base64 encoding) are universally known, their direct inclusion here is to ensure the overall *structure and implementation* of this specific system are unique to this creative concept.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EchelonEchoes: Generative Sentient NFT Network
 * @dev This contract creates a network of dynamically evolving, AI-influenced Non-Fungible Tokens (NFTs) called "Echoes".
 *      Echoes possess unique, mutable "sentience traits" and an "influence score" that change based on owner interactions,
 *      network events, and simulated AI oracle inputs. The system introduces "Essence" as a fungible resource
 *      for various operations, and features network-wide challenges to foster ecosystem interaction.
 *      The design aims for novel inter-NFT dynamics and a living, emergent on-chain digital ecosystem.
 *
 *      Key Features:
 *      - Dynamic NFTs (Echoes): Traits evolve based on interactions and AI inputs, not static.
 *      - Simulated AI Oracle Integration: Allows for external data (e.g., AI model outputs) to influence NFT state.
 *      - Inter-NFT Mechanics: Functions like 'harmonizeEchoes' and 'projectSentience' enable complex interactions between NFTs.
 *      - Resource Management: 'Essence' token acts as a fungible currency for powering operations and rewards.
 *      - Network Challenges: On-chain mini-games/tasks for ecosystem engagement, fostering competition and collaboration.
 *      - Decentralized Governance Simulation: Admin functions represent controlled ecosystem parameters for tuning.
 *      - Anti-Duplication Note: While core NFT/token principles are universally known, this contract implements
 *        them with custom logic and naming internally, avoiding direct inheritance from standard open-source
 *        ERC-721/ERC-20 interfaces to ensure conceptual uniqueness for its specific domain. Helper libraries
 *        for string conversion and Base64 encoding are included directly within the contract for completeness
 *        and to adhere to the spirit of not relying on external open-source imports.
 */

// OUTLINE
// 1.  State Variables & Data Structures: Defines the core data models for Echoes, Essence, Challenges, and global parameters.
// 2.  Events: Declares all events emitted by the contract for external monitoring.
// 3.  Modifiers & Access Control: Custom modifiers to manage function access (e.g., `onlyOwner`, `onlyOracle`).
// 4.  Core NFT (Echo) Management Functions: Handles minting, querying, naming, and dynamic URI generation for Echoes.
// 5.  Sentience & Trait Evolution Functions (AI Oracle Interaction): Manages how Echo traits change through simulated AI probes and 'dream sequences'.
// 6.  Essence Token Functions (Internal Implementation): Provides basic fungible token functionalities (mint, burn, transfer, approve, transferFrom) for the 'Essence' resource.
// 7.  Network Challenges & Ecosystem Functions: Enables creation, participation, resolution, and reward claiming for network-wide challenges.
// 8.  Advanced & Utility Functions: Implements unique inter-Echo mechanics like trait harmonization and influence projection.
// 9.  Admin & System Maintenance Functions: Allows the contract owner to manage system parameters and access roles.

// FUNCTION SUMMARY
// 1.  mintEcho(string memory _initialTraitSeed): Mints a new Echo NFT with an initial configuration based on a provided seed string.
// 2.  getEchoTraits(uint256 _tokenId): Retrieves the current array of AI-influenced trait values for a specific Echo.
// 3.  getEchoInfluence(uint256 _tokenId): Returns the current 'Influence Score' of an Echo, indicating its potential impact within the network.
// 4.  getEchoStatus(uint256 _tokenId): Provides the current operational state of an Echo (e.g., Idle, Dreaming, Challenging).
// 5.  setEchoName(uint256 _tokenId, string memory _newName): Allows an Echo's owner to assign or change its name, requiring a cost in Essence.
// 6.  getCurrentTokenURI(uint256 _tokenId): Dynamically generates a base64 encoded tokenURI, describing the Echo's current traits and status.
// 7.  initiateSentienceProbe(uint256 _tokenId, bytes32 _externalPromptHash): Initiates a request to the simulated AI oracle for updated trait values for an Echo, costing Essence.
// 8.  fulfillSentienceProbe(uint256 _tokenId, bytes32 _externalPromptHash, uint256[] memory _newTraitValues): A restricted callback function, callable only by the designated oracle, to apply AI-generated trait updates.
// 9.  invokeDreamSequence(uint256 _tokenId): Puts an Echo into a time-locked 'dream state', potentially leading to unpredictable trait shifts, costing Essence.
// 10. concludeDreamSequence(uint256 _tokenId): Allows an owner to end an Echo's dream sequence after its duration, applying the outcome based on internal logic.
// 11. escalateInfluence(uint256 _tokenId, uint256 _essenceAmount): Increases an Echo's permanent 'Influence Score' by burning a specified amount of Essence.
// 12. decayAllEchoesTraits(): An admin or time-triggered function designed to gradually reduce the trait values of all active Echoes, simulating entropy.
// 13. createNetworkChallenge(string memory _challengeDescription, uint256 _rewardEssence, uint256 _durationBlocks, uint256 _minInfluenceRequired): Admin function to propose and start a new ecosystem-wide challenge with defined parameters and rewards.
// 14. participateInChallenge(uint256 _tokenId, uint256 _challengeId): Registers an Echo to participate in an active network challenge, subject to eligibility criteria.
// 15. resolveChallengeOutcome(uint256 _challengeId): Admin function to determine and finalize the results of a network challenge, making rewards available for claiming.
// 16. claimChallengeReward(uint256 _challengeId, uint256 _tokenId): Allows successful challenge participants to claim their allocated Essence rewards.
// 17. mintEssence(address _to, uint256 _amount): Admin function to issue new Essence tokens, primarily for distributing rewards or initial liquidity.
// 18. burnEssence(uint256 _amount): Allows any user to destroy a specified amount of their Essence tokens from their balance.
// 19. transferEssence(address _to, uint256 _amount): Standard function for transferring Essence tokens between user addresses.
// 20. approveEssence(address _spender, uint256 _amount): Allows a user to set an allowance for a third-party address to spend their Essence on their behalf.
// 21. transferFromEssence(address _from, address _to, uint256 _amount): Allows an approved third-party to transfer Essence tokens from one address to another, consuming from the allowance.
// 22. harmonizeEchoes(uint256 _tokenId1, uint256 _tokenId2): A complex function enabling two Echoes to merge or average their traits, impacting both and costing Essence.
// 23. projectSentience(uint256 _sourceId, uint256 _targetId, uint256 _durationBlocks): Allows a source Echo to temporarily boost a target Echo's influence score, requiring Essence.
// 24. updateNetworkGenesisParameters(uint256 _newDecayFactor, uint256 _newChallengeBaseReward, uint256 _newDreamDurationBlocks): Admin function to adjust core global ecosystem parameters like trait decay rate and challenge rewards.
// 25. setOracleAddress(address _newOracle): Sets the designated address authorized to provide simulated AI oracle responses for trait updates.

contract EchelonEchoes {

    // --- 1. State Variables & Data Structures ---

    address public owner; // Contract owner, simple access control
    address public oracleAddress; // Address authorized to fulfill AI oracle requests

    uint256 private _nextTokenId; // Counter for new Echo NFTs

    // Echo NFT Data Structure
    struct Echo {
        uint256 id;
        address owner;
        string name;
        uint256[] traits; // e.g., [Curiosity, Resilience, Empathy, Creativity, Logic]
        uint256 influenceScore;
        uint256 lastInteractionBlock;
        EchoStatus status;
        uint256 statusEndTime; // For DreamSequence/Challenge time-locking
        uint256 currentChallengeId; // If participating in a challenge
    }

    // Enum for Echo's operational status
    enum EchoStatus {
        Idle,
        Dreaming,
        Challenging
    }

    mapping(uint256 => Echo) public echoes;             // Stores Echo data by tokenId
    mapping(address => uint256) private _echoBalances;  // Tracks number of Echoes owned by an address (ERC721-like)
    mapping(uint256 => address) private _echoOwners;    // Tracks owner of each Echo by tokenId (ERC721-like)

    // Essence Token Data (Internal ERC-20 like implementation)
    string public constant ESSENCE_NAME = "EchelonEssence";
    string public constant ESSENCE_SYMBOL = "ESS";
    uint8 public constant ESSENCE_DECIMALS = 18;
    uint256 public essenceTotalSupply;
    mapping(address => uint256) private _essenceBalances;        // User balances of Essence
    mapping(address => mapping(address => uint256)) private _essenceAllowances; // Spender allowances for Essence

    // Network Challenge Data Structure
    uint256 private _nextChallengeId;
    struct Challenge {
        uint256 id;
        string description;
        uint256 rewardEssence;
        uint256 durationBlocks;
        uint256 minInfluenceRequired;
        uint256 startTime;
        uint256 endTime;
        mapping(uint256 => bool) participants; // tokenId => true if participating
        uint256 participantCount;
        bool resolved;
        bool rewardsClaimed; // To prevent double claims for entire challenge (not per-participant)
    }

    mapping(uint256 => Challenge) public challenges;
    // Tracks if a specific Echo has claimed rewards for a specific challenge
    mapping(uint256 => mapping(uint256 => bool)) public hasClaimedChallengeReward; // challengeId => tokenId => claimed

    // Global Ecosystem Parameters (Tunable by owner)
    uint256 public traitDecayFactor = 1;      // Amount by which traits decay per cycle
    uint256 public challengeBaseReward = 100 * (10**uint256(ESSENCE_DECIMALS)); // Base reward for challenges (in wei)
    uint256 public dreamDurationBlocks = 100; // Default blocks for a dream sequence


    // --- 2. Events ---

    event EchoMinted(uint256 indexed tokenId, address indexed owner, string initialTraitSeed);
    event EchoTraitsUpdated(uint256 indexed tokenId, uint256[] newTraits, string reason);
    event EchoInfluenceEscalated(uint256 indexed tokenId, uint256 newInfluenceScore, uint256 essenceBurned);
    event EchoStatusChanged(uint256 indexed tokenId, EchoStatus oldStatus, EchoStatus newStatus);
    event EchoNameSet(uint256 indexed tokenId, string newName);

    event EssenceMinted(address indexed to, uint256 amount);
    event EssenceBurned(address indexed from, uint256 amount);
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);
    event EssenceApproval(address indexed owner, address indexed spender, uint256 amount);

    event ChallengeCreated(uint256 indexed challengeId, string description, uint256 reward, uint256 durationBlocks);
    event ChallengeParticipated(uint256 indexed challengeId, uint256 indexed tokenId);
    event ChallengeResolved(uint256 indexed challengeId, bool success);
    event ChallengeRewardClaimed(uint256 indexed challengeId, uint256 indexed tokenId, uint256 amount);

    event NetworkParametersUpdated(uint256 newDecayFactor, uint256 newChallengeBaseReward, uint256 newDreamDurationBlocks);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);

    // --- 3. Modifiers & Access Control ---

    modifier onlyOwner() {
        require(msg.sender == owner, "EchelonEchoes: Not contract owner.");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "EchelonEchoes: Not authorized oracle.");
        _;
    }

    // Constructor: Sets the initial contract owner and a default oracle address (can be changed).
    constructor() {
        owner = msg.sender;
        oracleAddress = msg.sender; // Owner is initial oracle, can be changed later
        _nextTokenId = 1;
        _nextChallengeId = 1;
    }

    // --- 4. Core NFT (Echo) Management Functions ---

    /**
     * @dev Mints a new Echo NFT with an initial trait configuration seed.
     *      Each Echo has a unique ID and its initial traits are pseudo-randomly
     *      generated based on the seed and current block data.
     * @param _initialTraitSeed A string seed for initial trait generation (simulated).
     * @return The ID of the newly minted Echo.
     */
    function mintEcho(string memory _initialTraitSeed) public returns (uint256) {
        // Simple limit to prevent excessive minting in a demo environment.
        require(_echoBalances[msg.sender] < 5, "EchelonEchoes: Max 5 Echoes per owner for demo.");

        uint256 tokenId = _nextTokenId++;
        Echo storage newEcho = echoes[tokenId];
        newEcho.id = tokenId;
        newEcho.owner = msg.sender;
        newEcho.name = string(abi.encodePacked("Echo #", Strings.toString(tokenId)));
        newEcho.influenceScore = 100; // Base influence score for new Echoes
        newEcho.lastInteractionBlock = block.number;
        newEcho.status = EchoStatus.Idle; // All new Echoes start as idle

        // Initialize traits based on seed (simplified: pseudo-random array based on seed hash)
        bytes32 seedHash = keccak256(abi.encodePacked(_initialTraitSeed, block.timestamp, tokenId));
        newEcho.traits = new uint256[](5); // Example: 5 traits (e.g., Curiosity, Resilience, Empathy, Creativity, Logic)
        for (uint i = 0; i < 5; i++) {
            newEcho.traits[i] = (uint256(seedHash) % 100) + 50; // Traits initialized between 50-149
            seedHash = keccak256(abi.encodePacked(seedHash, i)); // Simple pseudo-randomization for next trait
        }

        _echoOwners[tokenId] = msg.sender;       // Update owner mapping
        _echoBalances[msg.sender]++;             // Increment owner's Echo balance

        emit EchoMinted(tokenId, msg.sender, _initialTraitSeed);
        return tokenId;
    }

    /**
     * @dev Retrieves the current AI-influenced trait values of a specific Echo.
     * @param _tokenId The ID of the Echo.
     * @return An array of trait values.
     */
    function getEchoTraits(uint256 _tokenId) public view returns (uint256[] memory) {
        require(_echoOwners[_tokenId] != address(0), "EchelonEchoes: Echo does not exist.");
        return echoes[_tokenId].traits;
    }

    /**
     * @dev Returns the current 'Influence Score' of an Echo, reflecting its network impact.
     * @param _tokenId The ID of the Echo.
     * @return The Echo's current influence score.
     */
    function getEchoInfluence(uint256 _tokenId) public view returns (uint256) {
        require(_echoOwners[_tokenId] != address(0), "EchelonEchoes: Echo does not exist.");
        return echoes[_tokenId].influenceScore;
    }

    /**
     * @dev Provides the current operational state of an Echo.
     * @param _tokenId The ID of the Echo.
     * @return The Echo's current status (Idle, Dreaming, Challenging).
     */
    function getEchoStatus(uint256 _tokenId) public view returns (EchoStatus) {
        require(_echoOwners[_tokenId] != address(0), "EchelonEchoes: Echo does not exist.");
        return echoes[_tokenId].status;
    }

    /**
     * @dev Allows an Echo's owner to assign or change its name, costing Essence.
     * @param _tokenId The ID of the Echo to name.
     * @param _newName The new name for the Echo. Must be between 1 and 32 characters.
     */
    function setEchoName(uint256 _tokenId, string memory _newName) public {
        require(_echoOwners[_tokenId] == msg.sender, "EchelonEchoes: Not Echo owner.");
        require(bytes(_newName).length > 0 && bytes(_newName).length <= 32, "EchelonEchoes: Name must be 1-32 chars.");
        require(balanceOfEssence(msg.sender) >= 10 * (10**uint256(ESSENCE_DECIMALS)), "EchelonEchoes: Not enough Essence to name.");

        _burnEssence(msg.sender, 10 * (10**uint256(ESSENCE_DECIMALS))); // Cost to name an Echo
        echoes[_tokenId].name = _newName;
        emit EchoNameSet(_tokenId, _newName);
    }

    /**
     * @dev Dynamically generates a base64 encoded tokenURI (simulated, pointing to trait data) for an Echo.
     *      This URI would be consumed by frontends or NFT marketplaces to display dynamic metadata.
     *      In a real application, this would construct a more complex JSON or SVG URI based on current traits.
     * @param _tokenId The ID of the Echo.
     * @return The dynamically generated tokenURI string.
     */
    function getCurrentTokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_echoOwners[_tokenId] != address(0), "EchelonEchoes: Echo does not exist.");
        Echo storage currentEcho = echoes[_tokenId];

        // Simplified dynamic URI generation based on current traits and influence
        string memory name = currentEcho.name;
        string memory traitsStr = "";
        for (uint i = 0; i < currentEcho.traits.length; i++) {
            traitsStr = string(abi.encodePacked(traitsStr, Strings.toString(currentEcho.traits[i]), (i == currentEcho.traits.length - 1 ? "" : ",")));
        }

        // Construct a JSON object containing dynamic metadata
        string memory json = string(abi.encodePacked(
            '{"name":"', name,
            '","description":"An evolving sentient Echo. Influence: ', Strings.toString(currentEcho.influenceScore),
            '. Status: ', Strings.toString(uint256(currentEcho.status)),
            '. Traits: [', traitsStr, ']",',
            '"attributes":[{"trait_type":"Influence","value":', Strings.toString(currentEcho.influenceScore), '}]}'
        ));

        // Return a data URI with base64 encoded JSON
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- 5. Sentience & Trait Evolution Functions (AI Oracle Interaction) ---

    /**
     * @dev Initiates a request to the simulated AI oracle for updated trait values for a specific Echo.
     *      This function would typically dispatch an event that an off-chain oracle service listens to.
     *      Costs Essence to perform a "probe" to simulate resource consumption for AI processing.
     * @param _tokenId The ID of the Echo to probe.
     * @param _externalPromptHash A hash representing the external prompt sent to the AI (for oracle verification/matching).
     */
    function initiateSentienceProbe(uint256 _tokenId, bytes32 _externalPromptHash) public {
        require(_echoOwners[_tokenId] == msg.sender, "EchelonEchoes: Not Echo owner.");
        require(echoes[_tokenId].status == EchoStatus.Idle, "EchelonEchoes: Echo not idle for probe.");
        require(balanceOfEssence(msg.sender) >= 50 * (10**uint256(ESSENCE_DECIMALS)), "EchelonEchoes: Not enough Essence for probe.");

        _burnEssence(msg.sender, 50 * (10**uint256(ESSENCE_DECIMALS))); // Cost to send a probe request

        // In a real scenario, this would trigger an off-chain oracle request (e.g., Chainlink external adapter).
        // For this simulation, we imagine the oracle has received this request and will later call fulfillSentienceProbe.
        emit EchoTraitsUpdated(_tokenId, echoes[_tokenId].traits, "Probe Initiated (Awaiting Oracle)");
    }

    /**
     * @dev Restricted callback function to apply AI oracle responses to an Echo's traits.
     *      Only callable by the designated `oracleAddress`. This simulates the 'fulfill' pattern.
     * @param _tokenId The ID of the Echo to update.
     * @param _externalPromptHash The original prompt hash to ensure request matching (simulated verification).
     * @param _newTraitValues An array of new trait values provided by the oracle (e.g., [120, 85, 90, 110, 75]).
     */
    function fulfillSentienceProbe(uint256 _tokenId, bytes32 _externalPromptHash, uint256[] memory _newTraitValues) public onlyOracle {
        require(_echoOwners[_tokenId] != address(0), "EchelonEchoes: Echo does not exist.");
        // In a real system, you'd verify _externalPromptHash against a stored request queue from initiateSentienceProbe
        // to ensure the response matches an active request. For this demo, we assume correct linking.
        require(_newTraitValues.length == echoes[_tokenId].traits.length, "EchelonEchoes: Mismatched trait array length from oracle.");

        echoes[_tokenId].traits = _newTraitValues;
        echoes[_tokenId].lastInteractionBlock = block.number; // Mark interaction
        emit EchoTraitsUpdated(_tokenId, _newTraitValues, "Oracle Fulfilled");
    }

    /**
     * @dev Initiates a time-locked 'dream state' for an Echo, potentially leading to trait shifts.
     *      Costs Essence. During dreaming, an Echo cannot participate in challenges or be probed.
     * @param _tokenId The ID of the Echo to put into dream state.
     */
    function invokeDreamSequence(uint256 _tokenId) public {
        require(_echoOwners[_tokenId] == msg.sender, "EchelonEchoes: Not Echo owner.");
        require(echoes[_tokenId].status == EchoStatus.Idle, "EchelonEchoes: Echo not idle to dream.");
        require(balanceOfEssence(msg.sender) >= 20 * (10**uint256(ESSENCE_DECIMALS)), "EchelonEchoes: Not enough Essence for dream.");

        _burnEssence(msg.sender, 20 * (10**uint256(ESSENCE_DECIMALS))); // Cost to initiate a dream

        echoes[_tokenId].status = EchoStatus.Dreaming;
        echoes[_tokenId].statusEndTime = block.number + dreamDurationBlocks; // Set dream end time
        emit EchoStatusChanged(_tokenId, EchoStatus.Idle, EchoStatus.Dreaming);
    }

    /**
     * @dev Allows an owner to end an Echo's dream sequence, applying its pre-determined or AI-influenced outcome.
     *      Can only be called after the specified dream duration has passed.
     * @param _tokenId The ID of the Echo to conclude dreaming.
     */
    function concludeDreamSequence(uint256 _tokenId) public {
        require(_echoOwners[_tokenId] == msg.sender, "EchelonEchoes: Not Echo owner.");
        require(echoes[_tokenId].status == EchoStatus.Dreaming, "EchelonEchoes: Echo not dreaming.");
        require(block.number >= echoes[_tokenId].statusEndTime, "EchelonEchoes: Dream sequence not over yet.");

        // Simulate dream outcome: random trait modification or influence boost
        Echo storage echo = echoes[_tokenId];
        for (uint i = 0; i < echo.traits.length; i++) {
            // Simple pseudo-random change based on block hash and tokenId for unpredictability
            uint256 change = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, i, blockhash(block.number - 1)))) % 20; // up to +/- 19
            if (uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, i, blockhash(block.number - 2), "sign"))) % 2 == 0) {
                echo.traits[i] = echo.traits[i] + change;
            } else {
                echo.traits[i] = echo.traits[i] > change ? echo.traits[i] - change : 0; // Prevent negative traits
            }
        }
        echo.influenceScore += uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, "inf", blockhash(block.number - 3)))) % 10; // Small influence boost from dreaming

        echo.status = EchoStatus.Idle; // Return to idle state
        echo.lastInteractionBlock = block.number;
        emit EchoStatusChanged(_tokenId, EchoStatus.Dreaming, EchoStatus.Idle);
        emit EchoTraitsUpdated(_tokenId, echo.traits, "Dream Concluded");
    }

    /**
     * @dev Increases an Echo's permanent 'Influence Score' by burning a specified amount of Essence.
     *      This provides a direct mechanism for owners to boost their Echo's standing.
     * @param _tokenId The ID of the Echo.
     * @param _essenceAmount The amount of Essence to burn.
     */
    function escalateInfluence(uint256 _tokenId, uint256 _essenceAmount) public {
        require(_echoOwners[_tokenId] == msg.sender, "EchelonEchoes: Not Echo owner.");
        require(_essenceAmount > 0, "EchelonEchoes: Amount must be positive.");
        require(balanceOfEssence(msg.sender) >= _essenceAmount, "EchelonEchoes: Insufficient Essence balance.");

        _burnEssence(msg.sender, _essenceAmount); // Burn Essence
        uint256 influenceGain = _essenceAmount / (10**uint256(ESSENCE_DECIMALS)) / 5; // Example: 5 Essence per 1 Influence point
        echoes[_tokenId].influenceScore += influenceGain;
        echoes[_tokenId].lastInteractionBlock = block.number;
        emit EchoInfluenceEscalated(_tokenId, echoes[_tokenId].influenceScore, _essenceAmount);
    }

    /**
     * @dev An admin or time-triggered function to gradually reduce the trait values of all active Echoes, simulating entropy.
     *      Designed to be called periodically (e.g., once a day/week by an automated keeper service).
     *      Note: Iterating over all NFTs can be gas-intensive for large collections.
     *      A more scalable solution might use a "pull" model where decay is applied on interaction,
     *      or a paginated processing system.
     */
    function decayAllEchoesTraits() public onlyOwner {
        for (uint256 i = 1; i < _nextTokenId; i++) {
            if (_echoOwners[i] != address(0)) { // Check if Echo exists
                Echo storage echo = echoes[i];
                // Apply decay only if the Echo is currently idle.
                if (echo.status == EchoStatus.Idle) {
                    for (uint j = 0; j < echo.traits.length; j++) {
                        // Decay by traitDecayFactor, ensuring traits don't go below a minimum (e.g., 1)
                        if (echo.traits[j] > traitDecayFactor) {
                            echo.traits[j] -= traitDecayFactor;
                        } else {
                            echo.traits[j] = 1; // Minimum trait value
                        }
                    }
                    echo.lastInteractionBlock = block.number; // Mark as processed
                    emit EchoTraitsUpdated(i, echo.traits, "Decayed");
                }
            }
        }
    }

    // --- 6. Essence Token Functions (Internal Implementation) ---

    /**
     * @dev Returns the Essence balance of a specific address.
     * @param _owner The address to query the balance of.
     * @return The amount of Essence owned by `_owner`.
     */
    function balanceOfEssence(address _owner) public view returns (uint256) {
        return _essenceBalances[_owner];
    }

    /**
     * @dev Returns the amount of Essence that `_spender` is allowed to spend on behalf of `_owner`.
     * @param _owner The address of the Essence owner.
     * @param _spender The address of the spender.
     * @return The remaining allowance.
     */
    function allowanceEssence(address _owner, address _spender) public view returns (uint256) {
        return _essenceAllowances[_owner][_spender];
    }

    /**
     * @dev Admin function to issue new Essence tokens, primarily for rewards or initial distribution.
     *      This increases the total supply of Essence.
     * @param _to The address to mint Essence to.
     * @param _amount The amount of Essence to mint (in smallest units, like wei).
     */
    function mintEssence(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "EchelonEchoes: Mint to zero address.");
        essenceTotalSupply += _amount;
        _essenceBalances[_to] += _amount;
        emit EssenceMinted(_to, _amount);
    }

    /**
     * @dev Allows any user to destroy a specified amount of their Essence tokens.
     *      This reduces the total supply of Essence.
     * @param _amount The amount of Essence to burn.
     */
    function burnEssence(uint256 _amount) public {
        _burnEssence(msg.sender, _amount);
    }

    /**
     * @dev Internal helper function to burn Essence from a specified address.
     * @param _from The address from which Essence is burned.
     * @param _amount The amount of Essence to burn.
     */
    function _burnEssence(address _from, uint256 _amount) internal {
        require(_essenceBalances[_from] >= _amount, "EchelonEchoes: Insufficient Essence balance to burn.");
        essenceTotalSupply -= _amount;
        _essenceBalances[_from] -= _amount;
        emit EssenceBurned(_from, _amount);
    }

    /**
     * @dev Standard transfer function for Essence tokens between users.
     * @param _to The recipient address.
     * @param _amount The amount of Essence to transfer.
     * @return True if successful.
     */
    function transferEssence(address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0), "EchelonEchoes: Transfer to zero address.");
        require(_essenceBalances[msg.sender] >= _amount, "EchelonEchoes: Insufficient Essence balance.");

        _essenceBalances[msg.sender] -= _amount;
        _essenceBalances[_to] += _amount;
        emit EssenceTransferred(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev Allows a user to set an allowance for a third-party to spend their Essence.
     * @param _spender The address authorized to spend.
     * @param _amount The amount of Essence the spender is allowed to spend.
     * @return True if successful.
     */
    function approveEssence(address _spender, uint256 _amount) public returns (bool) {
        _essenceAllowances[msg.sender][_spender] = _amount;
        emit EssenceApproval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Allows an approved third-party to transfer Essence on behalf of another user.
     * @param _from The original owner of the Essence.
     * @param _to The recipient address.
     * @param _amount The amount of Essence to transfer.
     * @return True if successful.
     */
    function transferFromEssence(address _from, address _to, uint256 _amount) public returns (bool) {
        require(_from != address(0), "EchelonEchoes: Transfer from zero address.");
        require(_to != address(0), "EchelonEchoes: Transfer to zero address.");
        require(_essenceBalances[_from] >= _amount, "EchelonEchoes: Insufficient Essence balance.");
        require(_essenceAllowances[_from][msg.sender] >= _amount, "EchelonEchoes: Insufficient Essence allowance.");

        _essenceBalances[_from] -= _amount;
        _essenceBalances[_to] += _amount;
        _essenceAllowances[_from][msg.sender] -= _amount; // Reduce allowance
        emit EssenceTransferred(_from, _to, _amount);
        return true;
    }

    // --- 7. Network Challenges & Ecosystem Functions ---

    /**
     * @dev Admin function to propose and start a new network-wide challenge.
     *      Challenges are time-limited events where Echoes can participate to earn rewards.
     * @param _challengeDescription A brief description of the challenge.
     * @param _rewardEssence The total Essence reward for successful participants of this challenge.
     * @param _durationBlocks The duration of the challenge in blocks.
     * @param _minInfluenceRequired The minimum influence score an Echo needs to participate.
     * @return The ID of the newly created challenge.
     */
    function createNetworkChallenge(
        string memory _challengeDescription,
        uint256 _rewardEssence,
        uint256 _durationBlocks,
        uint256 _minInfluenceRequired
    ) public onlyOwner returns (uint256) {
        require(_durationBlocks > 0, "EchelonEchoes: Challenge duration must be positive.");
        require(_rewardEssence > 0, "EchelonEchoes: Challenge reward must be positive.");
        // In a live system, you might require _rewardEssence to be pre-funded or minted here.
        // For this demo, we assume existence for simplicity.

        uint256 challengeId = _nextChallengeId++;
        Challenge storage newChallenge = challenges[challengeId];
        newChallenge.id = challengeId;
        newChallenge.description = _challengeDescription;
        newChallenge.rewardEssence = _rewardEssence;
        newChallenge.durationBlocks = _durationBlocks;
        newChallenge.minInfluenceRequired = _minInfluenceRequired;
        newChallenge.startTime = block.number;
        newChallenge.endTime = block.number + _durationBlocks;
        newChallenge.resolved = false;
        newChallenge.rewardsClaimed = false; // per-challenge claim state, not per-participant

        emit ChallengeCreated(challengeId, _challengeDescription, _rewardEssence, _durationBlocks);
        return challengeId;
    }

    /**
     * @dev Registers an Echo to participate in an active network challenge.
     *      An Echo must be idle, meet influence requirements, and cannot be already participating.
     * @param _tokenId The ID of the Echo participating.
     * @param _challengeId The ID of the challenge.
     */
    function participateInChallenge(uint256 _tokenId, uint256 _challengeId) public {
        require(_echoOwners[_tokenId] == msg.sender, "EchelonEchoes: Not Echo owner.");
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "EchelonEchoes: Challenge does not exist.");
        require(challenge.startTime <= block.number && block.number < challenge.endTime, "EchelonEchoes: Challenge not active.");
        require(echoes[_tokenId].status == EchoStatus.Idle, "EchelonEchoes: Echo not idle to participate.");
        require(echoes[_tokenId].influenceScore >= challenge.minInfluenceRequired, "EchelonEchoes: Echo influence too low to participate.");
        require(!challenge.participants[_tokenId], "EchelonEchoes: Echo already participating in this challenge.");

        challenge.participants[_tokenId] = true; // Mark Echo as participant
        challenge.participantCount++;
        echoes[_tokenId].status = EchoStatus.Challenging; // Set Echo status to challenging
        echoes[_tokenId].currentChallengeId = _challengeId; // Link Echo to current challenge
        echoes[_tokenId].lastInteractionBlock = block.number;

        emit ChallengeParticipated(_challengeId, _tokenId);
        emit EchoStatusChanged(_tokenId, EchoStatus.Idle, EchoStatus.Challenging);
    }

    /**
     * @dev Admin function to determine and finalize the results of a network challenge, distributing rewards.
     *      This function would typically contain complex logic for determining 'winners' based on Echo traits,
     *      influence, a vote, or oracle outcome. For this demo, all valid participants are considered 'winners'.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function resolveChallengeOutcome(uint256 _challengeId) public onlyOwner {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "EchelonEchoes: Challenge does not exist.");
        require(!challenge.resolved, "EchelonEchoes: Challenge already resolved.");
        require(block.number >= challenge.endTime, "EchelonEchoes: Challenge not over yet.");

        challenge.resolved = true; // Mark challenge as resolved

        // Restore status for all participants who were in this challenge.
        // This loop is potentially expensive for many participants. A more scalable approach
        // might require participants to manually conclude their participation, or use a separate tracking mechanism.
        for (uint256 i = 1; i < _nextTokenId; i++) {
            if (_echoOwners[i] != address(0) && echoes[i].currentChallengeId == _challengeId) {
                echoes[i].status = EchoStatus.Idle; // Return Echo to idle
                echoes[i].currentChallengeId = 0;   // Clear challenge ID
                emit EchoStatusChanged(i, EchoStatus.Challenging, EchoStatus.Idle);
            }
        }

        // Rewards are claimed individually via `claimChallengeReward` once resolved.
        emit ChallengeResolved(_challengeId, true);
    }

    /**
     * @dev Allows successful challenge participants to claim their allocated Essence rewards.
     *      Rewards are minted to the claimant's address.
     * @param _challengeId The ID of the challenge.
     * @param _tokenId The ID of the Echo that participated.
     */
    function claimChallengeReward(uint256 _challengeId, uint256 _tokenId) public {
        require(_echoOwners[_tokenId] == msg.sender, "EchelonEchoes: Not Echo owner.");
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "EchelonEchoes: Challenge does not exist.");
        require(challenge.resolved, "EchelonEchoes: Challenge not yet resolved.");
        require(challenge.participants[_tokenId], "EchelonEchoes: Echo did not participate in this challenge.");
        require(!hasClaimedChallengeReward[_challengeId][_tokenId], "EchelonEchoes: Rewards already claimed for this Echo.");
        require(challenge.participantCount > 0, "EchelonEchoes: No participants to share reward with.");

        // Calculate reward per participant (simplified: total_reward / participant_count)
        // More complex systems might use weighted rewards based on influence, trait matches, etc.
        uint256 rewardPerParticipant = challenge.rewardEssence / challenge.participantCount;
        require(rewardPerParticipant > 0, "EchelonEchoes: No reward available (division by zero or too small).");

        mintEssence(msg.sender, rewardPerParticipant); // Mint reward to participant
        hasClaimedChallengeReward[_challengeId][_tokenId] = true; // Mark as claimed
        emit ChallengeRewardClaimed(_challengeId, _tokenId, rewardPerParticipant);
    }

    // --- 8. Advanced & Utility Functions ---

    /**
     * @dev A complex function allowing two Echoes to combine or merge their traits, potentially impacting both.
     *      This function demonstrates inter-NFT dynamics. For demonstration, it averages traits
     *      and provides an influence boost to both participating Echoes. Costs Essence.
     *      Both Echoes must be idle.
     * @param _tokenId1 The ID of the first Echo.
     * @param _tokenId2 The ID of the second Echo.
     */
    function harmonizeEchoes(uint256 _tokenId1, uint256 _tokenId2) public {
        require(_tokenId1 != _tokenId2, "EchelonEchoes: Cannot harmonize an Echo with itself.");
        // Requires owning at least one of the Echoes. For a more strict rule, uncomment the second require.
        require(_echoOwners[_tokenId1] == msg.sender || _echoOwners[_tokenId2] == msg.sender, "EchelonEchoes: Must own at least one Echo to initiate harmonization.");
        // require(_echoOwners[_tokenId1] == msg.sender && _echoOwners[_tokenId2] == msg.sender, "EchelonEchoes: Must own both Echoes.");


        Echo storage echo1 = echoes[_tokenId1];
        Echo storage echo2 = echoes[_tokenId2];

        require(echo1.status == EchoStatus.Idle && echo2.status == EchoStatus.Idle, "EchelonEchoes: Both Echoes must be idle for harmonization.");
        require(balanceOfEssence(msg.sender) >= 100 * (10**uint256(ESSENCE_DECIMALS)), "EchelonEchoes: Not enough Essence for harmonization.");
        require(echo1.traits.length == echo2.traits.length, "EchelonEchoes: Echoes must have same number of traits to harmonize.");

        // Simulate harmonization: Average trait values between the two Echoes
        for (uint i = 0; i < echo1.traits.length; i++) {
            uint256 avgTrait = (echo1.traits[i] + echo2.traits[i]) / 2;
            echo1.traits[i] = avgTrait;
            echo2.traits[i] = avgTrait;
        }

        // Apply an influence boost to both Echoes as a result of harmonization
        echo1.influenceScore += 10;
        echo2.influenceScore += 10;

        _burnEssence(msg.sender, 100 * (10**uint256(ESSENCE_DECIMALS))); // Cost to harmonize

        echo1.lastInteractionBlock = block.number; // Mark interaction
        echo2.lastInteractionBlock = block.number; // Mark interaction

        emit EchoTraitsUpdated(_tokenId1, echo1.traits, "Harmonized");
        emit EchoTraitsUpdated(_tokenId2, echo2.traits, "Harmonized");
        emit EchoInfluenceEscalated(_tokenId1, echo1.influenceScore, 0); // 0 essence burned for this specific emit, cost is overall
        emit EchoInfluenceEscalated(_tokenId2, echo2.influenceScore, 0); // 0 essence burned for this specific emit
    }

    /**
     * @dev Allows a source Echo to temporarily (conceptually) boost a target Echo's influence.
     *      Requires ownership of the source Echo and costs Essence. The target Echo can be owned by anyone.
     *      The influence boost is simplified to be permanent for demo purposes; a full implementation
     *      would require tracking temporary buffs and their expiration times.
     * @param _sourceId The ID of the Echo projecting influence.
     * @param _targetId The ID of the Echo receiving influence.
     * @param _durationBlocks The conceptual number of blocks for which the influence projection lasts (not fully implemented as temporary).
     */
    function projectSentience(uint256 _sourceId, uint256 _targetId, uint256 _durationBlocks) public {
        require(_sourceId != _targetId, "EchelonEchoes: Cannot project sentience onto itself.");
        require(_echoOwners[_sourceId] == msg.sender, "EchelonEchoes: Not owner of source Echo.");
        require(_echoOwners[_targetId] != address(0), "EchelonEchoes: Target Echo does not exist."); // Target can be any existing Echo

        Echo storage sourceEcho = echoes[_sourceId];
        Echo storage targetEcho = echoes[_targetId];

        require(sourceEcho.status == EchoStatus.Idle, "EchelonEchoes: Source Echo must be idle to project sentience.");
        require(_durationBlocks > 0, "EchelonEchoes: Projection duration must be positive.");
        require(sourceEcho.influenceScore > 100, "EchelonEchoes: Source Echo needs sufficient influence ( > 100) to project."); // Example threshold
        require(balanceOfEssence(msg.sender) >= 50 * (10**uint256(ESSENCE_DECIMALS)), "EchelonEchoes: Not enough Essence for projection.");

        _burnEssence(msg.sender, 50 * (10**uint256(ESSENCE_DECIMALS))); // Cost to project sentience

        // Calculate influence boost based on source Echo's influence
        uint256 influenceBoost = sourceEcho.influenceScore / 10; // 10% of source's influence as a boost
        targetEcho.influenceScore += influenceBoost; // This boost is currently permanent for simplicity.
        // A fully temporary buff would require a separate mapping like:
        // mapping(uint256 => mapping(uint256 => uint256)) public temporaryInfluenceBoosts; // tokenId => endTime => amount
        // and a mechanism to check/decay it.

        sourceEcho.lastInteractionBlock = block.number;
        targetEcho.lastInteractionBlock = block.number;

        emit EchoInfluenceEscalated(_targetId, targetEcho.influenceScore, 0); // 0 essence burned for this specific emit (cost is overall for projection)
        emit EchoTraitsUpdated(_sourceId, sourceEcho.traits, "Sentience Projected"); // Event to reflect source used its sentience
    }

    // --- 9. Admin & System Maintenance Functions ---

    /**
     * @dev Admin function to adjust core ecosystem parameters that govern trait decay, challenge rewards, and dream durations.
     *      These parameters allow the contract owner to fine-tune the economic and evolutionary aspects of the network.
     * @param _newDecayFactor New value for trait decay (e.g., 1 for 1 point per cycle). Must be positive.
     * @param _newChallengeBaseReward New base reward for challenges (in wei). Must be positive.
     * @param _newDreamDurationBlocks New default duration for dream sequences in blocks. Must be positive.
     */
    function updateNetworkGenesisParameters(
        uint256 _newDecayFactor,
        uint256 _newChallengeBaseReward,
        uint256 _newDreamDurationBlocks
    ) public onlyOwner {
        require(_newDecayFactor > 0, "EchelonEchoes: Decay factor must be positive.");
        require(_newChallengeBaseReward > 0, "EchelonEchoes: Challenge reward must be positive.");
        require(_newDreamDurationBlocks > 0, "EchelonEchoes: Dream duration must be positive.");

        traitDecayFactor = _newDecayFactor;
        challengeBaseReward = _newChallengeBaseReward;
        dreamDurationBlocks = _newDreamDurationBlocks;

        emit NetworkParametersUpdated(traitDecayFactor, challengeBaseReward, dreamDurationBlocks);
    }

    /**
     * @dev Sets the designated address authorized to provide simulated AI oracle responses.
     *      This address is crucial for `fulfillSentienceProbe` to function.
     * @param _newOracle The new oracle address.
     */
    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "EchelonEchoes: Oracle address cannot be zero.");
        emit OracleAddressSet(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfers to the contract.
     */
    receive() external payable {
        revert("EchelonEchoes: Ether not accepted directly.");
    }

    /**
     * @dev Fallback function for calls to non-existent functions or direct Ether sends.
     */
    fallback() external payable {
        revert("EchelonEchoes: Call to non-existent function or direct Ether.");
    }
}

// --- Helper Libraries ---
// These are included directly in the contract to avoid external imports and adhere to the "no open source duplication" spirit.

// Strings: Utility for converting uint256 to string.
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// Base64: Utility for encoding bytes to a Base64 string. Used for dynamic tokenURIs.
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = TABLE;
        uint256 len = data.length;
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory buf = new bytes(encodedLen);

        uint256 ptr = 0;
        for (uint256 i = 0; i < len; i += 3) {
            uint256 input = 0;
            for (uint256 j = 0; j < 3; j++) {
                if (i + j < len) {
                    input |= uint256(data[i + j]) << (8 * (2 - j));
                }
            }

            buf[ptr++] = bytes1(table[input >> 18]);
            buf[ptr++] = bytes1(table[(input >> 12) & 0x3F]);
            buf[ptr++] = bytes1(table[(input >> 6) & 0x3F]);
            buf[ptr++] = bytes1(table[input & 0x3F]);
        }

        // Handle padding characters
        if (len % 3 == 1) {
            buf[encodedLen - 1] = "=";
            buf[encodedLen - 2] = "=";
        } else if (len % 3 == 2) {
            buf[encodedLen - 1] = "=";
        }

        return string(buf);
    }
}

```