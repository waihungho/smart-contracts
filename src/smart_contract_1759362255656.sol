```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For address.call

/*
██╗░░░██╗██╗░░░██╗███╗░░░███╗███████╗██╗░░██╗██╗░░░░░░██████╗░██╗░░██╗
██║░░░██║██║░░░██║████╗░████║██╔════╝██║░██╔╝██║░░░░░░██╔══██╗██║░░██║
██║░░░██║██║░░░██║██╔████╔██║█████╗░░█████═╝░██║░░░░░░██████╔╝███████║
██║░░░██║██║░░░██║██║╚██╔╝██║██╔══╝░░██╔═██╗░██║░░░░░░██╔══██╗██╔══██║
╚██████╔╝╚██████╔╝██║░╚═╝░██║███████╗██║░╚██╗███████╗██████╔╝██║░░██║
░╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝╚══════╝╚╚══════╝╚══════╝╚═════╝░╚═╝░░╚═╝
*/

// --- QuantumFlux Forge Smart Contract ---
// A dynamic, AI-curated NFT ecosystem with gamified evolution and decentralized treasury management.
// This contract introduces "Flux Shards" (dynamic NFTs), "Essence" (an ERC20 utility token),
// a "Chronos Oracle" (simulated AI influence), a "Graviton Pool" (staking), and
// a "Quantum Core" (on-chain governance).

// Outline:
// 1.  **QuantumFluxForge (Core Contract):** The main contract orchestrating the ecosystem. It inherits
//     ERC721URIStorage for NFTs, ERC20 for the native token, Ownable for administrative control,
//     and Pausable for emergency halts.
// 2.  **Flux Shards (NFTs):** ERC721 tokens representing unique digital entities with dynamic traits.
//     These traits can evolve, transmute, and be influenced by external factors from the Chronos Oracle.
// 3.  **Essence (ERC20 Token):** The fungible utility token of the ecosystem. It's used for:
//     - Forging new Flux Shards.
//     - Evolving and transmuting Flux Shard traits.
//     - Staking in the Graviton Pool to earn rewards.
//     - Participating in Quantum Core governance (proposals and voting).
// 4.  **Chronos Oracle (Simulated AI Influence):** An authorized external entity (EOA or contract)
//     that periodically updates global "environmental conditions" or "AI insights" on-chain.
//     These conditions can dynamically affect Flux Shard evolution and interactions.
// 5.  **Graviton Pool (Staking):** A mechanism where users can stake their Essence tokens to
//     earn more Essence as rewards over time, promoting long-term holding and engagement.
// 6.  **Quantum Core (Decentralized Treasury & Governance):** A simple DAO-like structure that
//     enables Essence holders to propose and vote on actions (e.g., funding grants, parameter changes,
//     upgrades) for the protocol's treasury. Passed proposals can execute arbitrary calls.

// Function Summary:

// --- ERC721 Flux Shard Management ---
// 1.  `forgeFluxShard(address _to, string memory _tokenURI)`: Mints a new dynamic Flux Shard NFT to `_to` for a cost in Essence. Assigns initial dynamic traits.
// 2.  `evolveFluxShard(uint256 _tokenId, uint8 _traitIndex, uint8 _evolutionPoints)`: Upgrades specific traits of a Flux Shard using Essence, potentially influenced by Chronos conditions.
// 3.  `attuneToOracle(uint256 _tokenId)`: Temporarily boosts a Flux Shard's traits based on current Chronos Oracle conditions (requires Essence, has cooldown).
// 4.  `transmuteFluxShard(uint256 _tokenId, uint8 _traitIndex)`: Randomly alters a specific trait of a Flux Shard, requiring Essence, with a chance for rare outcomes.
// 5.  `getFluxShardTraits(uint256 _tokenId)`: Returns the current dynamic trait values for a given Flux Shard.
// 6.  `getFluxShardHistory(uint256 _tokenId)`: (Conceptual) Retrieves a log or summary of significant evolution/transmutation events for a Flux Shard.
// 7.  `tokenURI(uint256 tokenId)`: Returns the URI for a given token ID, enhanced with dynamic trait data.

// --- ERC20 Essence Token Management (Beyond standard inherited functions) ---
// 8.  `mintEssence(address _to, uint256 _amount)`: (Admin/Controlled) Mints new Essence tokens to `_to`, primarily for initial distribution or governance-approved rewards.
// 9.  `burnEssence(uint256 _amount)`: Allows the caller to burn their own Essence tokens.
// (Standard ERC20 functions like `transfer`, `transferFrom`, `approve`, `allowance`, `balanceOf`, `totalSupply` are inherited and available)

// --- Graviton Pool (Staking) ---
// 10. `stakeEssence(uint256 _amount)`: Allows users to stake Essence tokens into the Graviton Pool to earn rewards.
// 11. `unstakeEssence(uint256 _amount)`: Allows users to unstake their Essence tokens from the Graviton Pool. Rewards are claimed automatically.
// 12. `claimGravitonRewards()`: Allows users to manually claim accumulated rewards from staking.
// 13. `getPendingGravitonRewards(address _staker)`: View function to check pending staking rewards for a user.

// --- Chronos Oracle Integration ---
// 14. `updateChronosConditions(uint256 _conditionCode, uint256 _conditionValue)`: (Chronos Oracle Only) Sets global environmental conditions that influence NFT behavior.
// 15. `getChronosConditions()`: View function to retrieve the current global Chronos conditions.

// --- Quantum Core (Governance) ---
// 16. `proposeCatalyst(address _target, uint256 _value, bytes calldata _calldata, string memory _description)`: Allows Essence holders to propose a governance action for the treasury.
// 17. `voteOnCatalyst(uint256 _proposalId, bool _support)`: Allows Essence holders to vote on active proposals using their Essence balance as weight.
// 18. `executeCatalyst(uint256 _proposalId)`: Executes a passed governance proposal after the voting period ends, subject to quorum and majority checks.
// 19. `getProposalDetails(uint256 _proposalId)`: View function to retrieve details of a specific proposal.

// --- Administrative & Utility Functions ---
// 20. `setForgeParameters(uint256 _forgeCost, uint256 _evolutionCostPerPoint, uint256 _transmutationCost, uint256 _attuneCost)`: (Admin) Adjusts various operational costs for NFT interactions.
// 21. `setChronosOracleAddress(address _newOracle)`: (Admin) Changes the authorized address for the Chronos Oracle.
// 22. `setGovernanceParameters(uint256 _minEssenceForProposal, uint256 _votingPeriodDays, uint256 _quorumPercent, uint256 _thresholdPercent)`: (Admin) Adjusts Quantum Core governance parameters.
// 23. `setEssenceRewardRate(uint256 _newRate)`: (Admin) Adjusts the reward rate for Graviton Pool staking.
// 24. `pause()`: (Admin) Pauses contract functionality in case of an emergency (inherited from Pausable).
// 25. `unpause()`: (Admin) Unpauses the contract (inherited from Pausable).
// 26. `withdrawProtocolFees(address _to)`: (Admin) Allows withdrawal of accumulated protocol fees (Essence) to a specified address.
// 27. `_baseURI()`: Internal helper for `tokenURI` (ERC721 override).
// 28. `supportsInterface(bytes4 interfaceId)`: ERC165 interface support (ERC721 override).
// 29. `onERC721Received()`: ERC721 receiver hook for safe transfers (implementation).

contract QuantumFluxForge is ERC721URIStorage, ERC20, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address; // For Address.functionCall

    Counters.Counter private _tokenIdCounter;

    // --- Events ---
    event FluxShardForged(uint256 indexed tokenId, address indexed owner, string tokenURI, uint256 forgeCost);
    event FluxShardEvolved(uint256 indexed tokenId, address indexed owner, uint8 traitIndex, uint8 evolutionPoints);
    event FluxShardAttuned(uint256 indexed tokenId, address indexed owner, uint256 conditionCode, uint256 conditionValue);
    event FluxShardTransmuted(uint256 indexed tokenId, address indexed owner, uint8 traitIndex);
    event ChronosConditionsUpdated(uint256 conditionCode, uint256 conditionValue, uint256 timestamp);
    event EssenceStaked(address indexed staker, uint256 amount);
    event EssenceUnstaked(address indexed staker, uint256 amount);
    event GravitonRewardsClaimed(address indexed staker, uint256 amount);
    event CatalystProposed(uint256 indexed proposalId, address indexed proposer, string description);
    event CatalystVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event CatalystExecuted(uint256 indexed proposalId, bool success);

    // --- Configuration Parameters ---
    // Governance
    uint256 public minEssenceForProposal = 1000 ether; // 1000 Essence tokens
    uint256 public proposalVotingPeriod = 3 days;
    uint256 public proposalQuorumPercent = 4; // 4% of total supply must vote
    uint256 public proposalThresholdPercent = 50; // 50% majority needed (of votes cast)

    // NFT Costs
    uint256 public forgeCost = 100 ether; // 100 Essence to forge a new Shard
    uint256 public evolutionCostPerPoint = 10 ether; // 10 Essence per evolution point
    uint256 public transmutationCost = 500 ether; // 500 Essence for transmutation
    uint256 public attuneCost = 50 ether; // 50 Essence for attunement

    // Graviton Pool (Staking)
    uint256 public essenceRewardRate = 100_000_000_000_000_000; // 0.1 Essence per staked unit per hour (0.1 ether)
    uint256 public constant SECONDS_PER_HOUR = 3600;
    uint256 public constant ATTUNE_COOLDOWN_PERIOD = 1 days;

    // --- State Variables ---

    // Chronos Oracle
    address public chronosOracleAddress;
    uint256 public currentChronosConditionCode;
    uint256 public currentChronosConditionValue;
    uint256 public lastChronosUpdateTimestamp;

    // Flux Shards (NFTs)
    struct FluxShardData {
        uint8 power; // 0-100
        uint8 resilience; // 0-100
        uint8 agility; // 0-100
        uint8 affinityToChronos; // How well it reacts to oracle conditions (0-100)
        uint256 lastEvolutionTimestamp;
        uint256 lastAttuneTimestamp;
    }
    mapping(uint256 => FluxShardData) public fluxShardData;

    // Graviton Pool (Staking)
    mapping(address => uint256) public stakedEssence;
    mapping(address => uint256) public lastRewardUpdateTime; // Last time rewards were calculated/claimed
    uint256 public totalStakedEssence; // Total Essence staked in the pool

    // Quantum Core (Governance)
    struct CatalystProposal {
        uint256 id;
        address proposer;
        address target; // The contract to call
        uint256 value; // ETH to send (if any)
        bytes calldata; // The data to send to the target
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor; // Total Essence voted 'for'
        uint256 votesAgainst; // Total Essence voted 'against'
        bool executed;
        bool canceled; // To allow proposals to be marked invalid if necessary
    }
    mapping(uint256 => CatalystProposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voterAddress => voted
    Counters.Counter public nextProposalId;

    // --- Modifiers ---
    modifier onlyChronosOracle() {
        require(msg.sender == chronosOracleAddress, "QFF: Caller is not the Chronos Oracle");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the QuantumFluxForge contract.
     * @param _name The name for the ERC721 Flux Shards (e.g., "Flux Shard").
     * @param _symbol The symbol for the ERC721 Flux Shards (e.g., "FLUX").
     * @param _chronosOracle The address designated as the Chronos Oracle.
     */
    constructor(string memory _name, string memory _symbol, address _chronosOracle)
        ERC721(_name, _symbol)
        ERC20("Essence Token", "ESS") // Initialize Essence ERC20
        Ownable(msg.sender) // Deployer is the initial owner
        Pausable()
    {
        require(_chronosOracle != address(0), "QFF: Chronos Oracle address cannot be zero");
        chronosOracleAddress = _chronosOracle;
        // Mint an initial supply of Essence for the deployer's address (or a designated treasury)
        _mint(msg.sender, 1_000_000_000 ether); // 1 Billion Essence (with 18 decimals)
    }

    // --- ERC721 Flux Shard Management ---

    /**
     * @dev Mints a new dynamic Flux Shard NFT to `_to`.
     * The caller must approve and transfer `forgeCost` Essence tokens to the contract.
     * Initial traits are assigned based on a simple pseudo-random generation.
     * @param _to The address to mint the NFT to.
     * @param _tokenURI The base URI for the NFT's metadata (e.g., IPFS hash).
     */
    function forgeFluxShard(address _to, string memory _tokenURI) external whenNotPaused {
        require(balanceOf(msg.sender) >= forgeCost, "QFF: Insufficient Essence to forge");
        _transfer(msg.sender, address(this), forgeCost); // Transfer Essence to contract treasury

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(_to, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        // Assign initial traits using a pseudo-random seed
        // NOTE: For true randomness, an oracle like Chainlink VRF would be used in production.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newItemId, block.difficulty)));
        fluxShardData[newItemId] = FluxShardData({
            power: uint8(randomSeed % 101), // 0-100
            resilience: uint8((randomSeed / 100) % 101),
            agility: uint8((randomSeed / 10000) % 101),
            affinityToChronos: uint8((randomSeed / 1000000) % 101),
            lastEvolutionTimestamp: block.timestamp,
            lastAttuneTimestamp: 0
        });

        emit FluxShardForged(newItemId, _to, _tokenURI, forgeCost);
    }

    /**
     * @dev Allows the owner to upgrade specific traits of a Flux Shard.
     * Costs `evolutionCostPerPoint` Essence per point. Traits are capped at 100.
     * Evolution can receive a boost if the shard has high affinity to current Chronos conditions.
     * @param _tokenId The ID of the Flux Shard to evolve.
     * @param _traitIndex The index of the trait to evolve (0=power, 1=resilience, 2=agility, 3=affinityToChronos).
     * @param _evolutionPoints The number of points to add to the trait.
     */
    function evolveFluxShard(uint256 _tokenId, uint8 _traitIndex, uint8 _evolutionPoints) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "QFF: Not owner or approved for token");
        require(_evolutionPoints > 0, "QFF: Evolution points must be positive");
        require(_traitIndex < 4, "QFF: Invalid trait index (0-3)");

        uint256 totalEvolutionCost = uint256(_evolutionPoints).mul(evolutionCostPerPoint);
        require(balanceOf(msg.sender) >= totalEvolutionCost, "QFF: Insufficient Essence for evolution");
        _transfer(msg.sender, address(this), totalEvolutionCost); // Transfer Essence to contract treasury

        FluxShardData storage shard = fluxShardData[_tokenId];
        uint8 effectiveEvolutionPoints = _evolutionPoints;

        // Dynamic boost from Chronos Oracle: high affinity shards get a bonus
        // Example logic: if Chronos conditions match a certain code and shard's affinity is high.
        if (currentChronosConditionCode == 1 && shard.affinityToChronos > 75) { // Condition 1 = "Growth Spurt"
            effectiveEvolutionPoints = uint8(effectiveEvolutionPoints.add(shard.affinityToChronos.div(15))); // Up to +6 points
        } else if (currentChronosConditionCode == 2 && shard.affinityToChronos > 50) { // Condition 2 = "Resilience Wave"
             if (_traitIndex == 1) effectiveEvolutionPoints = uint8(effectiveEvolutionPoints.add(shard.affinityToChronos.div(20)));
        }

        if (_traitIndex == 0) shard.power = uint8(SafeMath.min(100, uint256(shard.power).add(effectiveEvolutionPoints)));
        else if (_traitIndex == 1) shard.resilience = uint8(SafeMath.min(100, uint256(shard.resilience).add(effectiveEvolutionPoints)));
        else if (_traitIndex == 2) shard.agility = uint8(SafeMath.min(100, uint256(shard.agility).add(effectiveEvolutionPoints)));
        else if (_traitIndex == 3) shard.affinityToChronos = uint8(SafeMath.min(100, uint256(shard.affinityToChronos).add(effectiveEvolutionPoints)));
        
        shard.lastEvolutionTimestamp = block.timestamp;

        emit FluxShardEvolved(_tokenId, msg.sender, _traitIndex, effectiveEvolutionPoints);
    }

    /**
     * @dev Allows a Flux Shard to temporarily benefit from current Chronos Oracle conditions.
     * This might apply a temporary trait boost (for dApp display), or enable specific actions.
     * Requires `attuneCost` Essence and has a cooldown period to prevent spam.
     * @param _tokenId The ID of the Flux Shard to attune.
     */
    function attuneToOracle(uint256 _tokenId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "QFF: Not owner or approved for token");
        require(currentChronosConditionCode > 0, "QFF: No active Chronos conditions to attune to");
        require(block.timestamp >= fluxShardData[_tokenId].lastAttuneTimestamp.add(ATTUNE_COOLDOWN_PERIOD), "QFF: Shard recently attuned. Cooldown active.");

        require(balanceOf(msg.sender) >= attuneCost, "QFF: Insufficient Essence for attunement");
        _transfer(msg.sender, address(this), attuneCost); // Transfer Essence to contract treasury

        // This attunement doesn't permanently change on-chain traits, but `lastAttuneTimestamp`
        // and `currentChronosConditionCode/Value` can be used by dApps to calculate
        // temporary boosts or unlock specific content/abilities for the NFT.
        fluxShardData[_tokenId].lastAttuneTimestamp = block.timestamp;

        emit FluxShardAttuned(_tokenId, msg.sender, currentChronosConditionCode, currentChronosConditionValue);
    }

    /**
     * @dev Randomly alters a specific trait of a Flux Shard, requiring Essence.
     * Offers a chance for rare or unique trait outcomes, but also potential regression.
     * @param _tokenId The ID of the Flux Shard to transmute.
     * @param _traitIndex The index of the trait to transmute (0-3).
     */
    function transmuteFluxShard(uint256 _tokenId, uint8 _traitIndex) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "QFF: Not owner or approved for token");
        require(_traitIndex < 4, "QFF: Invalid trait index (0-3)");
        require(balanceOf(msg.sender) >= transmutationCost, "QFF: Insufficient Essence for transmutation");
        _transfer(msg.sender, address(this), transmutationCost); // Transfer Essence to contract treasury

        FluxShardData storage shard = fluxShardData[_tokenId];
        // NOTE: For true randomness, an oracle like Chainlink VRF would be used in production.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId, _traitIndex, block.difficulty, currentChronosConditionCode, currentChronosConditionValue)));
        uint8 newTraitValue = uint8(randomSeed % 101); // Random value between 0 and 100

        // Example: introduce a slight bias based on Chronos conditions
        if (currentChronosConditionCode == 3) { // Condition 3 = "Unpredictable Flux"
            newTraitValue = uint8(SafeMath.min(100, newTraitValue.add(uint8(randomSeed % 21)))); // More volatile
        } else if (currentChronosConditionCode == 4) { // Condition 4 = "Stabilizing Aura"
            newTraitValue = uint8(SafeMath.max(0, newTraitValue.sub(uint8(randomSeed % 11)))); // Less volatile or leaning lower
        }

        if (_traitIndex == 0) shard.power = newTraitValue;
        else if (_traitIndex == 1) shard.resilience = newTraitValue;
        else if (_traitIndex == 2) shard.agility = newTraitValue;
        else if (_traitIndex == 3) shard.affinityToChronos = newTraitValue;

        emit FluxShardTransmuted(_tokenId, msg.sender, _traitIndex);
    }

    /**
     * @dev Returns the current dynamic trait values for a given Flux Shard.
     * @param _tokenId The ID of the Flux Shard.
     * @return (uint8 power, uint8 resilience, uint8 agility, uint8 affinityToChronos).
     */
    function getFluxShardTraits(uint256 _tokenId) external view returns (uint8, uint8, uint8, uint8) {
        require(_exists(_tokenId), "QFF: Token does not exist");
        FluxShardData memory shard = fluxShardData[_tokenId];
        return (shard.power, shard.resilience, shard.agility, shard.affinityToChronos);
    }

    /**
     * @dev (Conceptual) Retrieves a log or summary of significant evolution/transmutation events for a Flux Shard.
     * In a full implementation, this would involve storing an array of structs or emitting more detailed events
     * and querying them off-chain. For this example, it returns a conceptual string.
     * @param _tokenId The ID of the Flux Shard.
     * @return string A conceptual representation of the shard's event history.
     */
    function getFluxShardHistory(uint256 _tokenId) external view returns (string memory) {
        require(_exists(_tokenId), "QFF: Token does not exist");
        return string(abi.encodePacked(
            "Token ", Strings.toString(_tokenId),
            " (P:", Strings.toString(fluxShardData[_tokenId].power),
            " R:", Strings.toString(fluxShardData[_tokenId].resilience),
            " A:", Strings.toString(fluxShardData[_tokenId].agility),
            " Af:", Strings.toString(fluxShardData[_tokenId].affinityToChronos),
            ") last evolved at ", Strings.toString(fluxShardData[_tokenId].lastEvolutionTimestamp)
        ));
    }

    /**
     * @dev See {ERC721-tokenURI}. Returns a potentially dynamic URI based on token traits.
     * The base URI is concatenated with dynamic trait data, which dApps can parse.
     * @param tokenId The ID of the NFT.
     * @return string The URI of the NFT including dynamic traits.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory base = _baseURI();
        string memory currentTokenURI = _tokenURIs[tokenId];

        // If a specific token URI is set, append dynamic traits to it.
        // Otherwise, use the base URI and append token ID.
        string memory finalURI;
        if (bytes(currentTokenURI).length > 0) {
            finalURI = currentTokenURI;
        } else if (bytes(base).length > 0) {
            finalURI = string(abi.encodePacked(base, Strings.toString(tokenId)));
        } else {
            return ""; // No URI configured
        }

        // Append dynamic trait data as query parameters (dApps can parse these)
        FluxShardData memory shard = fluxShardData[tokenId];
        string memory dynamicPart = string(abi.encodePacked(
            "?power=", Strings.toString(shard.power),
            "&resilience=", Strings.toString(shard.resilience),
            "&agility=", Strings.toString(shard.agility),
            "&affinity=", Strings.toString(shard.affinityToChronos),
            "&chronos_code=", Strings.toString(currentChronosConditionCode), // Include global context
            "&chronos_value=", Strings.toString(currentChronosConditionValue)
        ));
        return string(abi.encodePacked(finalURI, dynamicPart));
    }


    // --- ERC20 Essence Token Management ---

    /**
     * @dev Mints new Essence tokens to `_to`.
     * Only callable by the contract owner (or via a successful governance proposal targeting this function).
     * This function is primarily for initial distribution or reward systems.
     * @param _to The address to mint tokens to.
     * @param _amount The amount of Essence tokens to mint (with 18 decimals).
     */
    function mintEssence(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        _mint(_to, _amount);
    }

    /**
     * @dev Burns `_amount` of Essence tokens from the caller's balance.
     * Users might burn Essence for specific in-game benefits or to reduce personal supply.
     * @param _amount The amount of Essence tokens to burn (with 18 decimals).
     */
    function burnEssence(uint256 _amount) public whenNotPaused {
        _burn(msg.sender, _amount);
    }
    // Standard ERC20 functions (transfer, transferFrom, approve, allowance, balanceOf, totalSupply)
    // are inherited from OpenZeppelin's ERC20 and are directly callable.


    // --- Graviton Pool (Staking) ---

    /**
     * @dev Allows users to stake Essence tokens into the Graviton Pool.
     * Any pending rewards are claimed before the new stake is added.
     * @param _amount The amount of Essence tokens to stake (with 18 decimals).
     */
    function stakeEssence(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "QFF: Cannot stake 0 Essence");
        require(balanceOf(msg.sender) >= _amount, "QFF: Insufficient Essence to stake");

        if (stakedEssence[msg.sender] > 0) {
            _calculateAndDistributeRewards(msg.sender); // Claim rewards before new stake
        }

        _transfer(msg.sender, address(this), _amount); // Transfer Essence to contract
        stakedEssence[msg.sender] = stakedEssence[msg.sender].add(_amount);
        totalStakedEssence = totalStakedEssence.add(_amount);
        lastRewardUpdateTime[msg.sender] = block.timestamp;

        emit EssenceStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows users to unstake their Essence tokens from the Graviton Pool.
     * Rewards are automatically claimed upon unstaking.
     * @param _amount The amount of Essence tokens to unstake (with 18 decimals).
     */
    function unstakeEssence(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "QFF: Cannot unstake 0 Essence");
        require(stakedEssence[msg.sender] >= _amount, "QFF: Insufficient staked Essence");

        _calculateAndDistributeRewards(msg.sender); // Claim rewards before unstaking

        stakedEssence[msg.sender] = stakedEssence[msg.sender].sub(_amount);
        totalStakedEssence = totalStakedEssence.sub(_amount);
        lastRewardUpdateTime[msg.sender] = block.timestamp; // Update timestamp even if nothing left

        _transfer(address(this), msg.sender, _amount); // Transfer Essence back from contract
        emit EssenceUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Allows users to manually claim accumulated rewards from staking.
     */
    function claimGravitonRewards() external whenNotPaused {
        _calculateAndDistributeRewards(msg.sender);
    }

    /**
     * @dev Internal function to calculate and distribute staking rewards to a specific staker.
     * Rewards are minted to the staker, making the staking pool inflationary.
     * @param _staker The address of the staker.
     */
    function _calculateAndDistributeRewards(address _staker) internal {
        uint256 pendingRewards = getPendingGravitonRewards(_staker);
        if (pendingRewards > 0) {
            _mint(_staker, pendingRewards); // Mint new Essence for rewards
            emit GravitonRewardsClaimed(_staker, pendingRewards);
        }
        lastRewardUpdateTime[_staker] = block.timestamp;
    }

    /**
     * @dev View function to check pending staking rewards for a user.
     * @param _staker The address of the staker.
     * @return uint256 The amount of pending Essence rewards (with 18 decimals).
     */
    function getPendingGravitonRewards(address _staker) public view returns (uint256) {
        if (stakedEssence[_staker] == 0 || lastRewardUpdateTime[_staker] == 0) {
            return 0;
        }
        // No rewards if the contract is paused, for security
        if (paused()) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp.sub(lastRewardUpdateTime[_staker]);
        uint256 rewards = (stakedEssence[_staker].mul(essenceRewardRate).mul(timeElapsed)).div(SECONDS_PER_HOUR);
        return rewards;
    }


    // --- Chronos Oracle Integration ---

    /**
     * @dev Sets the global "environmental conditions" or "AI insights" that influence NFT evolution.
     * Only callable by the designated `chronosOracleAddress`.
     * @param _conditionCode A numerical code representing the type of condition (e.g., 1 for "Growth Spurt", 2 for "Resilience Wave").
     * @param _conditionValue A numerical value associated with the condition (e.g., intensity, duration).
     */
    function updateChronosConditions(uint256 _conditionCode, uint256 _conditionValue) external onlyChronosOracle whenNotPaused {
        currentChronosConditionCode = _conditionCode;
        currentChronosConditionValue = _conditionValue;
        lastChronosUpdateTimestamp = block.timestamp;
        emit ChronosConditionsUpdated(_conditionCode, _conditionValue, block.timestamp);
    }

    /**
     * @dev View function to retrieve the current global Chronos conditions.
     * @return (uint256 conditionCode, uint256 conditionValue, uint256 lastUpdateTimestamp).
     */
    function getChronosConditions() external view returns (uint256, uint256, uint256) {
        return (currentChronosConditionCode, currentChronosConditionValue, lastChronosUpdateTimestamp);
    }


    // --- Quantum Core (Governance) ---

    /**
     * @dev Allows Essence holders to propose a governance action.
     * Requires a minimum amount of Essence (`minEssenceForProposal`) to propose.
     * @param _target The address of the contract to call for the proposal (e.g., this contract itself, or another protocol contract).
     * @param _value The amount of native currency (ETH) to send with the call.
     * @param _calldata The encoded function call data for the target contract.
     * @param _description A concise description of the proposal.
     */
    function proposeCatalyst(address _target, uint256 _value, bytes calldata _calldata, string memory _description) external whenNotPaused {
        require(balanceOf(msg.sender) >= minEssenceForProposal, "QFF: Insufficient Essence to propose");
        require(bytes(_description).length > 0, "QFF: Proposal description cannot be empty");
        require(_target != address(0), "QFF: Proposal target cannot be zero address");

        nextProposalId.increment();
        uint256 proposalId = nextProposalId.current();

        proposals[proposalId] = CatalystProposal({
            id: proposalId,
            proposer: msg.sender,
            target: _target,
            value: _value,
            calldata: _calldata,
            description: _description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(proposalVotingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            canceled: false
        });

        emit CatalystProposed(proposalId, msg.sender, _description);
    }

    /**
     * @dev Allows Essence holders to vote on active proposals.
     * Voters' Essence balance *at the time of voting* counts towards their vote weight.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against'.
     */
    function voteOnCatalyst(uint256 _proposalId, bool _support) external whenNotPaused {
        CatalystProposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "QFF: Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime, "QFF: Voting has not started yet");
        require(block.timestamp < proposal.voteEndTime, "QFF: Voting has ended");
        require(!proposal.executed, "QFF: Proposal already executed");
        require(!proposal.canceled, "QFF: Proposal canceled");
        require(!hasVoted[_proposalId][msg.sender], "QFF: Already voted on this proposal");

        uint256 voterEssenceBalance = balanceOf(msg.sender);
        require(voterEssenceBalance > 0, "QFF: Voter must hold Essence to cast a vote");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterEssenceBalance);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterEssenceBalance);
        }
        hasVoted[_proposalId][msg.sender] = true;

        emit CatalystVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a passed governance proposal after the voting period ends.
     * Requires sufficient quorum and a simple majority of votes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeCatalyst(uint256 _proposalId) external whenNotPaused {
        CatalystProposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "QFF: Proposal does not exist");
        require(block.timestamp >= proposal.voteEndTime, "QFF: Voting period not ended yet");
        require(!proposal.executed, "QFF: Proposal already executed");
        require(!proposal.canceled, "QFF: Proposal canceled");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 totalEssenceSupply = totalSupply();
        require(totalEssenceSupply > 0, "QFF: Total Essence supply is zero, cannot check quorum.");

        // Check quorum: percentage of total supply that must vote
        require(totalVotes.mul(100) >= totalEssenceSupply.mul(proposalQuorumPercent), "QFF: Quorum not reached");

        // Check majority: percentage of 'for' votes out of total votes cast
        require(proposal.votesFor.mul(100) >= totalVotes.mul(proposalThresholdPercent), "QFF: Proposal did not pass majority");

        proposal.executed = true;

        // Execute the proposed action using low-level call
        // If the proposal sends ETH, ensure the contract has enough.
        (bool success, ) = proposal.target.functionCallWithValue(proposal.calldata, proposal.value);
        require(success, "QFF: Proposal execution failed");

        emit CatalystExecuted(_proposalId, success);
    }

    /**
     * @dev View function to retrieve details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return CatalystProposal struct containing all details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (CatalystProposal memory) {
        return proposals[_proposalId];
    }


    // --- Administrative & Utility Functions ---

    /**
     * @dev Adjusts various operational costs for NFT interactions (forge, evolve, transmute, attune).
     * Only callable by the contract owner.
     * @param _forgeCost New cost for forging a Flux Shard.
     * @param _evolutionCostPerPoint New cost per point for evolving a trait.
     * @param _transmutationCost New cost for transmuting a trait.
     * @param _attuneCost New cost for attuning to the Chronos Oracle.
     */
    function setForgeParameters(
        uint256 _forgeCost,
        uint256 _evolutionCostPerPoint,
        uint256 _transmutationCost,
        uint256 _attuneCost
    ) external onlyOwner {
        forgeCost = _forgeCost;
        evolutionCostPerPoint = _evolutionCostPerPoint;
        transmutationCost = _transmutationCost;
        attuneCost = _attuneCost;
    }

    /**
     * @dev Changes the address authorized to update Chronos conditions.
     * Only callable by the contract owner.
     * @param _newOracle The new address of the Chronos Oracle.
     */
    function setChronosOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "QFF: Oracle address cannot be zero");
        chronosOracleAddress = _newOracle;
    }

    /**
     * @dev Adjusts Quantum Core governance parameters.
     * Only callable by the contract owner.
     * @param _minEssenceForProposal The new minimum Essence required to propose.
     * @param _votingPeriodDays The new duration of the voting period in days.
     * @param _quorumPercent The new percentage of total supply that must vote for quorum.
     * @param _thresholdPercent The new percentage of 'for' votes required for majority.
     */
    function setGovernanceParameters(
        uint256 _minEssenceForProposal,
        uint256 _votingPeriodDays,
        uint256 _quorumPercent,
        uint256 _thresholdPercent
    ) external onlyOwner {
        require(_votingPeriodDays > 0, "QFF: Voting period must be positive");
        require(_quorumPercent <= 100, "QFF: Quorum percent invalid");
        require(_thresholdPercent <= 100, "QFF: Threshold percent invalid");

        minEssenceForProposal = _minEssenceForProposal;
        proposalVotingPeriod = _votingPeriodDays.mul(1 days);
        proposalQuorumPercent = _quorumPercent;
        proposalThresholdPercent = _thresholdPercent;
    }

    /**
     * @dev Adjusts the reward rate for Graviton Pool staking.
     * Only callable by the contract owner.
     * @param _newRate The new reward rate (e.g., 0.1 ether for 0.1 Essence per hour per staked unit).
     */
    function setEssenceRewardRate(uint256 _newRate) external onlyOwner {
        essenceRewardRate = _newRate;
    }

    /**
     * @dev Pauses contract functionality in case of an emergency.
     * Only callable by the contract owner. Inherited from `Pausable`.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     * Only callable by the contract owner. Inherited from `Pausable`.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows withdrawal of collected protocol fees (Essence used for forging, evolving, etc.)
     * to a specified address. This ensures that staked Essence remains untouched.
     * Only callable by the contract owner.
     * @param _to The address to send the collected Essence fees to.
     */
    function withdrawProtocolFees(address _to) external onlyOwner {
        // The contract holds staked Essence + collected fees.
        // We only want to withdraw the fees.
        uint256 contractEssenceBalance = balanceOf(address(this));
        uint256 withdrawableEssence = contractEssenceBalance.sub(totalStakedEssence);
        
        require(withdrawableEssence > 0, "QFF: No withdrawable Essence fees");
        _transfer(address(this), _to, withdrawableEssence);
    }

    // --- Internal/Override Functions ---

    /**
     * @dev Base URI for computing {tokenURI}. If set, the token URI for a given
     * token ID will be the concatenation of the base URI and the token ID (and dynamic traits).
     * Override this function to change the base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return "ipfs://"; // Example IPFS base URI. Should be a gateway to resolve metadata.
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev ERC721 receiver hook. If the contract receives an ERC721 token, it returns its selector.
     * This contract does not explicitly support receiving NFTs as a core feature,
     * but implements the hook for `ERC721-safeTransferFrom` compliance.
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Fallback function to prevent accidental ETH transfers if not intended
    receive() external payable {
        revert("QFF: ETH not directly receivable. Use governance for funding proposals if needed.");
    }
}
```