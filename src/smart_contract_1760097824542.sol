The concept for this smart contract is **"Aetherial Nexus"**. It's a dynamic NFT (dNFT) ecosystem where Aetherial NFTs evolve over time, influenced by global "environmental factors" (fed by oracles), and user-applied "Neural Filters" (represented as ERC1155-like tokens). The core parameters governing this evolution and the protocol itself are controlled by a DAO (Decentralized Autonomous Organization) where Aetherial NFT holders participate in governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // Using OpenZeppelin's Ownable for initial administrative control.
                                                 // All core Aetherial Nexus logic, ERC721-like, ERC1155-like,
                                                 // and DAO implementations are custom to this contract.

/**
 * @title AetherialNexus: Dynamic NFT with On-Chain AI-Assisted Evolution and DAO-Governed Protocol
 * @dev This contract implements a novel ecosystem where Non-Fungible Tokens (Aetherial NFTs)
 *      can evolve over time based on internal rules, global environmental factors (fed by oracles),
 *      and user-applied 'Neural Filters' (ERC1155-like tokens). The protocol's evolution parameters
 *      are governed by a Decentralized Autonomous Organization (DAO) where Aetherial NFT holders
 *      can propose and vote on changes. It also includes staking mechanics.
 *
 * Outline:
 * 1.  Custom Error Definitions
 * 2.  Core Aetherial NFT Data Structures (Traits, Evolution State)
 * 3.  Neural Filter Data Structures (Parameters, Applied Filters, Balances)
 * 4.  Global Protocol Parameters & Environmental Data
 * 5.  DAO Governance Data Structures (Proposals, Voting)
 * 6.  Events for transparency and off-chain indexing
 * 7.  ERC721-like (Aetherial NFT) Core Internal Functions
 * 8.  ERC721-like (Aetherial NFT) External Interface Functions
 * 9.  Aetherial NFT Evolution & Trait Management Logic
 * 10. Neural Filter Creation, Minting, Application & Removal Logic (ERC1155-like)
 * 11. DAO Governance Logic (Proposals, Voting, Execution)
 * 12. Staking and Reward Mechanics
 * 13. Protocol Configuration & Utility Functions (Oracles, Getters)
 */

// Function Summary:
// I. Aetherial NFT Core (ERC721-like) - Custom Implementation
//    1.  constructor() -> Initializes the contract, sets the initial owner and an authorized oracle.
//    2.  balanceOf(address owner) -> Returns the number of Aetherial NFTs owned by `owner`.
//    3.  ownerOf(uint256 tokenId) -> Returns the owner of an Aetherial NFT.
//    4.  approve(address to, uint256 tokenId) -> Approves another address to transfer a specific Aetherial NFT.
//    5.  getApproved(uint256 tokenId) -> Returns the approved address for a given Aetherial NFT.
//    6.  setApprovalForAll(address operator, bool approved) -> Approves or unapproves an operator for all Aetherial NFTs of the sender.
//    7.  isApprovedForAll(address owner, address operator) -> Checks if an address is an operator for another address.
//    8.  transferFrom(address from, address to, uint256 tokenId) -> Transfers ownership of an Aetherial NFT.
//    9.  safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) -> Safely transfers ownership of an Aetherial NFT (overloaded).
//    10. tokenURI(uint256 tokenId) -> Returns the metadata URI for an Aetherial NFT, dynamically reflecting traits.
//
// II. Aetherial NFT Evolution & Traits
//    11. mintAetherialNFT() -> Mints a new Aetherial NFT with initial, randomized traits (only owner/DAO).
//    12. getTraitMatrix(uint256 tokenId) -> Retrieves the current, evolving traits of an Aetherial NFT.
//    13. evolveAetherialNFT(uint256 tokenId) -> Triggers the evolution process for an Aetherial NFT based on internal rules, applied filters, and environment.
//
// III. Neural Filter Core (ERC1155-like) - Custom Implementation
//    14. createNeuralFilter(string memory name, string memory description, uint256 baseInfluence, uint256 complexityCost, uint256 decayRate, bool mintable) -> Creates a new type of Neural Filter (ERC1155-like token type), callable by owner/DAO.
//    15. mintNeuralFilter(uint32 filterTypeId, address to, uint256 amount) -> Mints units of an existing Neural Filter type to `to` (only owner/DAO).
//    16. applyNeuralFilter(uint256 aetherialTokenId, uint32 filterTypeId, uint33 quantity) -> Applies units of a Neural Filter to an Aetherial NFT, influencing its evolution. Consumes the filter tokens.
//    17. removeNeuralFilter(uint256 aetherialTokenId, uint32 filterTypeId, uint32 quantity) -> Removes applied Neural Filters from an Aetherial NFT, returning them to the caller.
//    18. getAppliedFilters(uint256 aetherialTokenId) -> Returns the list of Neural Filters currently applied to an Aetherial NFT.
//    19. getFilterEffectData(uint32 filterTypeId) -> Retrieves the parameters and effects of a specific Neural Filter type.
//    20. balanceOfFilter(address account, uint32 filterTypeId) -> Returns the balance of a specific Neural Filter type for an address.
//    21. burnNeuralFilter(uint32 filterTypeId, uint256 amount) -> Allows burning units of a Neural Filter.
//
// IV. DAO Governance
//    22. proposeEvolutionParameterChange(bytes32 paramKey, uint256 newValue, uint256 proposerTokenId) -> Allows Aetherial NFT holders to propose changes to core protocol parameters.
//    23. voteOnProposal(uint256 proposalId, bool support) -> Allows Aetherial NFT holders to vote on active proposals (each NFT grants one vote).
//    24. executeProposal(uint256 proposalId) -> Executes a proposal if it has passed the voting period and met quorum requirements.
//    25. getProposalState(uint256 proposalId) -> Returns the current state of a proposal (Pending, Active, Defeated, Succeeded, Executed).
//
// V. Staking & Rewards
//    26. stakeAetherialNFT(uint256 tokenId) -> Stakes an Aetherial NFT to earn rewards and potentially boost evolution.
//    27. unstakeAetherialNFT(uint256 tokenId) -> Unstakes a previously staked Aetherial NFT.
//    28. claimStakingRewards() -> Claims accumulated staking rewards (in ETH).
//    29. getStakingRewardEstimate(uint256 tokenId) -> Estimates potential rewards for a currently staked NFT.
//
// VI. Protocol Configuration & Oracles
//    30. registerEnvironmentalOracle(address oracleAddress) -> Registers an address as an authorized oracle (only owner/DAO).
//    31. updateEnvironmentalFactor(uint32 factorId, uint256 value) -> An authorized oracle updates a global environmental factor.
//    32. getEnvironmentalFactors() -> Retrieves all currently set environmental factors.
//    33. getTotalSupplyAetherialNFTs() -> Returns the total number of Aetherial NFTs minted.
//    34. getTotalSupplyNeuralFilter(uint32 filterTypeId) -> Returns the total supply for a specific Neural Filter type.
//    35. getNextFilterTypeId() -> Returns the next available filter type ID for creating new filters.
//
// Internal/Helper Functions (not counted in the minimum 20 public/external functions but critical for logic):
//    - _safeMint(), _exists(), _transfer(), _clamp(), _calculateRarityScore()
//    - setEvolutionCooldown(), setProposalVotingPeriod(), setProposalMinQuorum() -> (These are public onlyOwner for testing/setup, but intended for internal DAO calls via executeProposal)

contract AetherialNexus is Ownable {

    // --- Custom Errors ---
    error InvalidTokenId();
    error NotOwnerOrApproved();
    error ApprovalToCurrentOwner();
    error ApproveCallerIsOwner();
    error TransferToZeroAddress();
    error MaxSupplyReached();
    error EvolutionOnCooldown();
    error InvalidFilterType();
    error InsufficientFilterBalance();
    error FilterNotApplied();
    error AlreadyStaked();
    error NotStaked();
    error NoRewardsToClaim();
    error InvalidProposalId();
    error ProposalAlreadyExecuted();
    error ProposalPeriodEnded();
    error ProposalNotYetEnded();
    error AlreadyVoted();
    error QuorumNotMet();
    error ProposalNotExecutable();
    error InvalidProposalParameter();
    error UnauthorizedOracle();
    error AlreadyMinted(); // For filters, if minting unique ones
    error InsufficientNFTsForProposal();
    error InsufficientNFTsForVote();
    error TransferFailed();

    // --- Data Structures ---

    /// @dev Represents the core evolving traits of an Aetherial NFT.
    struct AetherialTraits {
        uint256 vitality;     // Represents life force, health, resilience (0-1000)
        uint256 adaptability; // Represents how well it reacts to environmental changes (0-1000)
        uint256 complexity;   // Represents depth of traits, increases with evolution (0-1000)
        uint256 rarityScore;  // Derived score based on trait combination (calculated)
    }

    /// @dev Stores information about a Neural Filter applied to an Aetherial NFT.
    struct AppliedFilter {
        uint32 filterTypeId;  // ID of the Neural Filter type
        uint32 quantity;      // How many units of this filter were applied
        uint48 appliedTime;   // Timestamp when it was applied, for decay/effect duration
    }

    /// @dev Defines the parameters and effects of a specific Neural Filter type.
    struct NeuralFilterParams {
        string name;
        string description;
        uint256 baseInfluence;  // Base power of this filter's evolutionary effect
        uint256 complexityCost; // Cost in Aetherial NFT's complexity to apply this filter
        uint256 decayRate;      // Rate at which this filter's influence diminishes over time (e.g., 1 day per unit of influence). 0 for no decay.
        bool mintable;          // Whether more units of this filter can be minted (false for unique, fixed-supply ones)
    }

    /// @dev Represents a proposal for changing protocol parameters via DAO.
    struct EvolutionProposal {
        bytes32 paramKey;      // Hash of the parameter name (e.g., keccak256("evolutionCooldownDuration"))
        uint256 newValue;      // The new value for the parameter
        uint256 proposerTokenId; // Token ID of the NFT used to propose (for identification/tracking)
        uint256 startTime;     // Timestamp when the proposal started
        uint256 endTime;       // Timestamp when the voting period ends
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool executed;         // True if the proposal has been executed
    }

    // --- State Variables ---

    // Global Protocol Parameters
    uint256 public constant MAX_SUPPLY_AETHERIAL_NFTS = 10_000; // Max number of Aetherial NFTs
    uint256 public evolutionCooldownDuration = 1 days;          // Time between evolutions for an NFT
    uint256 public proposalVotingPeriod = 3 days;               // Duration of a proposal's voting phase
    uint256 public proposalMinQuorum = 5;                       // Minimum total votes (NFTs) for a proposal to pass
    uint256 public proposalThreshold = 1;                       // Minimum number of NFTs an address needs to propose/vote

    // Aetherial NFT (ERC721-like) State
    uint256 private _nextTokenId; // Counter for Aetherial NFTs, starts from 1
    mapping(uint256 => address) private _owners; // tokenId => owner address
    mapping(address => uint256) private _balances; // owner address => NFT count
    mapping(uint256 => address) private _tokenApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // Aetherial NFT Specific State
    mapping(uint256 => AetherialTraits) public aetherialTraits;
    mapping(uint256 => uint256) public aetherialEvolutionAge;      // Number of evolution cycles
    mapping(uint256 => uint256) public aetherialLastEvolutionTime; // Last time the NFT evolved
    mapping(uint256 => AppliedFilter[]) public appliedNeuralFilters; // tokenId => array of applied filters

    // Neural Filter (ERC1155-like) State
    uint32 public nextFilterTypeId = 1; // Counter for new Neural Filter types, starts from 1
    mapping(uint32 => NeuralFilterParams) public neuralFilterParams;
    mapping(address => mapping(uint33 => uint256)) public neuralFilterBalances; // Owner => filterTypeId => balance
    mapping(uint33 => uint256) public neuralFilterTotalSupply; // filterTypeId => total supply of that filter type

    // Environmental Factors (Oracle Data)
    mapping(uint32 => uint256) public environmentalFactors; // factorId => value (e.g., 1 for "globalEnergy", 2 for "cosmicRadiation")
    mapping(address => bool) public authorizedOracles; // Whitelisted oracle addresses

    // Staking State
    mapping(uint256 => uint256) public stakedAetherialNFTs; // tokenId => stakeTime (0 if not staked)
    mapping(address => uint256) public stakingRewardsAccumulated; // Address => accumulated rewards (in wei, for ETH)
    uint256 public constant STAKING_REWARD_RATE_PER_DAY = 1e16; // 0.01 ETH per day per NFT (example rate)

    // DAO Governance State
    uint256 public nextProposalId = 1;
    mapping(uint256 => EvolutionProposal) public proposals;

    // --- Events ---

    event AetherialNFTMinted(address indexed owner, uint256 indexed tokenId, AetherialTraits initialTraits);
    event AetherialNFTEvolved(uint256 indexed tokenId, uint256 newEvolutionAge, AetherialTraits newTraits, uint256 lastEvolutionTime);
    event NeuralFilterCreated(uint33 indexed filterTypeId, string name, uint256 baseInfluence);
    event NeuralFilterMinted(address indexed to, uint33 indexed filterTypeId, uint256 amount);
    event NeuralFilterApplied(uint256 indexed aetherialTokenId, uint33 indexed filterTypeId, uint33 quantity, address indexed by);
    event NeuralFilterRemoved(uint256 indexed aetherialTokenId, uint33 indexed filterTypeId, uint33 quantity, address indexed by);
    event NeuralFilterBurned(address indexed from, uint33 indexed filterTypeId, uint256 amount);
    event EnvironmentalFactorUpdated(uint33 indexed factorId, uint256 value, address indexed oracle);
    event AetherialNFTStaked(address indexed owner, uint256 indexed tokenId, uint256 stakeTime);
    event AetherialNFTUnstaked(address indexed owner, uint256 indexed tokenId, uint256 unstakeTime, uint22 rewardsClaimed);
    event StakingRewardsClaimed(address indexed owner, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue, uint256 proposerTokenId, uint256 startTime, uint256 endTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event ParameterChanged(bytes32 indexed paramKey, uint256 oldValue, uint256 newValue);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    // --- Constructor ---

    constructor(address initialOracle) Ownable(msg.sender) {
        authorizedOracles[initialOracle] = true;
        // Set initial environmental factors for the simulation
        environmentalFactors[1] = 500; // Example: "GlobalEnergy" - influences vitality
        environmentalFactors[2] = 100; // Example: "CosmicRadiation" - influences adaptability
    }

    // --- Internal / ERC721-like Functions (for custom implementation) ---

    /**
     * @dev Internal function to mint a new Aetherial NFT and assign it to `to`.
     * @param to The address of the recipient.
     * @param initialTraits The initial traits for the new NFT.
     * @return The ID of the newly minted token.
     */
    function _safeMint(address to, AetherialTraits memory initialTraits) internal returns (uint256) {
        if (to == address(0)) revert TransferToZeroAddress();
        if (_nextTokenId >= MAX_SUPPLY_AETHERIAL_NFTS) revert MaxSupplyReached();

        unchecked { _nextTokenId++; } // Increment token ID
        uint256 tokenId = _nextTokenId;
        _owners[tokenId] = to;
        _balances[to]++;
        aetherialTraits[tokenId] = initialTraits;
        aetherialEvolutionAge[tokenId] = 0;
        aetherialLastEvolutionTime[tokenId] = block.timestamp; // Initial evolution time

        emit AetherialNFTMinted(to, tokenId, initialTraits);
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    /**
     * @dev Checks if `_tokenId` is a valid Aetherial NFT (i.e., has an owner).
     */
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _owners[_tokenId] != address(0);
    }

    /**
     * @dev Internal function to transfer ownership of `tokenId` from `from` to `to`.
     * Does not perform approval or sender checks, these should be done by the caller.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) revert TransferToZeroAddress();

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        delete _tokenApprovals[tokenId]; // Clear approvals when transferred

        emit Transfer(from, to, tokenId);
    }

    // --- I. Aetherial NFT Core (ERC721-like) ---

    /// @notice Returns the number of Aetherial NFTs owned by `owner`.
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /// @notice Returns the owner of the `tokenId` Aetherial NFT.
    function ownerOf(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _owners[tokenId];
    }

    /// @notice Approves `to` to take ownership of `tokenId`.
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId); // Implicitly checks _exists
        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) revert ApproveCallerIsOwner();
        if (to == owner) revert ApprovalToCurrentOwner();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /// @notice Gets the approved address for `tokenId`.
    function getApproved(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenApprovals[tokenId];
    }

    /// @notice Sets or unsets `operator` as an operator for `msg.sender` for all NFTs.
    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert ApprovalToCurrentOwner(); // Cannot approve self as operator
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Checks if `operator` is an approved operator for `owner`.
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @notice Transfers ownership of `tokenId` from `from` to `to`.
    function transferFrom(address from, address to, uint256 tokenId) public {
        if (ownerOf(tokenId) != from) revert NotOwnerOrApproved(); // Checks _exists and owner
        if (msg.sender != from && getApproved(tokenId) != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert NotOwnerOrApproved();
        }
        _transfer(from, to, tokenId);
    }

    /// @notice Safely transfers ownership of `tokenId` from `from` to `to` with data.
    /// @dev This implementation does not include the full ERC721 `onERC721Received` hook check for brevity.
    ///      A robust implementation would require this check if `to` is a contract.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId); // Handles ownership transfer
        // Omitted ERC721 `onERC721Received` check for brevity in this example.
    }

    /// @notice Safely transfers ownership of `tokenId` from `from` to `to`.
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @notice Returns the metadata URI for a given Aetherial NFT.
    /// @dev This provides a generic base URI. For a full dynamic NFT, this would return a data URI
    ///      with base64 encoded JSON reflecting the current on-chain traits from `getTraitMatrix`.
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        string memory baseURI = "ipfs://aetherial-nexus/metadata/"; // Placeholder base URI
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }


    // --- II. Aetherial NFT Evolution & Traits ---

    /// @notice Mints a new Aetherial NFT with initial, randomized traits.
    /// @dev Only the contract owner (initially deployer, later can be transferred to DAO) can mint.
    function mintAetherialNFT() public onlyOwner returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, _nextTokenId, environmentalFactors[1])));
        AetherialTraits memory initialTraits = AetherialTraits({
            vitality: (seed % 200) + 400, // Range 400-600
            adaptability: ((seed / 100) % 200) + 400, // Range 400-600
            complexity: 100, // Starting complexity
            rarityScore: 0 // Will be calculated dynamically
        });
        initialTraits.rarityScore = _calculateRarityScore(initialTraits);

        return _safeMint(msg.sender, initialTraits);
    }

    /// @notice Retrieves the current traits of an Aetherial NFT.
    /// @param tokenId The ID of the Aetherial NFT.
    function getTraitMatrix(uint256 tokenId) public view returns (AetherialTraits memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return aetherialTraits[tokenId];
    }

    /// @notice Triggers the evolution process for an Aetherial NFT.
    /// @dev Can only be called by the NFT owner or an approved operator, and after a cooldown period.
    function evolveAetherialNFT(uint256 tokenId) public {
        address owner = ownerOf(tokenId); // Implicitly checks _exists
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert NotOwnerOrApproved();
        if (block.timestamp < aetherialLastEvolutionTime[tokenId] + evolutionCooldownDuration) revert EvolutionOnCooldown();

        AetherialTraits storage currentTraits = aetherialTraits[tokenId];
        uint256 currentAge = aetherialEvolutionAge[tokenId];

        // 1. Time-based decay/growth: Older NFTs gain complexity, potentially lose vitality
        currentTraits.vitality = _clamp(currentTraits.vitality - 1, 10, 1000); // Slight decay
        currentTraits.complexity = _clamp(currentTraits.complexity + 5, 100, 1000); // Always grows

        // 2. Environmental influence: Global oracle data affects trait changes
        uint256 globalEnergy = environmentalFactors[1]; // Factor 1: e.g., "Global Energy"
        uint22 cosmicRadiation = environmentalFactors[2]; // Factor 2: e.g., "Cosmic Radiation"

        currentTraits.vitality = _clamp(currentTraits.vitality + (globalEnergy / 100), 1, 1000);
        currentTraits.adaptability = _clamp(currentTraits.adaptability + (cosmicRadiation / 50), 1, 1000);

        // 3. Neural Filter influence: User-applied filters modify traits
        uint256 totalFilterInfluence = 0;
        uint256 totalComplexityCost = 0;

        AppliedFilter[] storage filters = appliedNeuralFilters[tokenId];
        for (uint256 i = 0; i < filters.length; ) {
            AppliedFilter storage applied = filters[i];
            NeuralFilterParams storage filterParams = neuralFilterParams[applied.filterTypeId];

            // Calculate effective quantity considering decay
            uint256 effectiveQuantity = applied.quantity;
            if (filterParams.decayRate > 0) {
                uint256 timeElapsed = block.timestamp - applied.appliedTime;
                uint256 decayedAmount = (effectiveQuantity * timeElapsed) / filterParams.decayRate;
                if (decayedAmount >= effectiveQuantity) {
                    // Filter fully decayed, remove it from array
                    filters[i] = filters[filters.length - 1];
                    filters.pop();
                    continue; // Re-evaluate current index after pop
                }
                effectiveQuantity -= decayedAmount;
            }

            if (effectiveQuantity > 0) {
                totalFilterInfluence += (filterParams.baseInfluence * effectiveQuantity);
                totalComplexityCost += (filterParams.complexityCost * effectiveQuantity);
            }
            unchecked { ++i; } // Increment only if not popped
        }

        // Apply cumulative filter effects, scaled to prevent immediate maxing out
        currentTraits.vitality = _clamp(currentTraits.vitality + (totalFilterInfluence / 200), 1, 1000);
        currentTraits.adaptability = _clamp(currentTraits.adaptability + (totalFilterInfluence / 100), 1, 1000);
        currentTraits.complexity = _clamp(currentTraits.complexity + (totalComplexityCost / 50), 100, 1000);

        // Update rarity score based on new traits
        currentTraits.rarityScore = _calculateRarityScore(currentTraits);

        aetherialEvolutionAge[tokenId] = currentAge + 1;
        aetherialLastEvolutionTime[tokenId] = block.timestamp;

        emit AetherialNFTEvolved(tokenId, currentAge + 1, currentTraits, block.timestamp);
    }

    /// @dev Internal helper function to clamp a value between a min and max.
    function _clamp(uint256 value, uint256 min, uint256 max) internal pure returns (uint256) {
        return value > max ? max : (value < min ? min : value);
    }

    /// @dev Internal helper to calculate a dynamic rarity score based on current traits.
    function _calculateRarityScore(AetherialTraits memory traits) internal pure returns (uint256) {
        // A simple example of a weighted sum; can be made more complex
        uint256 score = (traits.vitality / 10) + (traits.adaptability / 10) + (traits.complexity / 5);
        // Add bonus for specific high trait values or combinations
        if (traits.complexity > 900) score += 50;
        if (traits.vitality > 900) score += 30;
        if (traits.adaptability > 900) score += 20;
        return score;
    }


    // --- III. Neural Filter Core (ERC1155-like) ---

    /// @notice Creates a new type of Neural Filter. Only owner (or DAO via proposal) can call.
    /// @param name The name of the new filter type.
    /// @param description A brief description.
    /// @param baseInfluence The base evolutionary influence of one unit of this filter.
    /// @param complexityCost The cost in Aetherial NFT's complexity to apply.
    /// @param decayRate The rate at which the filter's influence diminishes over time (0 for no decay).
    /// @param mintable Whether this filter type can be minted multiple times.
    /// @return The ID of the newly created filter type.
    function createNeuralFilter(
        string memory name,
        string memory description,
        uint256 baseInfluence,
        uint256 complexityCost,
        uint256 decayRate,
        bool mintable
    ) public onlyOwner returns (uint33) {
        uint33 newFilterId = nextFilterTypeId;
        unchecked { nextFilterTypeId++; } // Increment before assignment
        neuralFilterParams[newFilterId] = NeuralFilterParams({
            name: name,
            description: description,
            baseInfluence: baseInfluence,
            complexityCost: complexityCost,
            decayRate: decayRate,
            mintable: mintable
        });
        emit NeuralFilterCreated(newFilterId, name, baseInfluence);
        return newFilterId;
    }

    /// @notice Mints units of an existing Neural Filter type to `to`. Only owner (or DAO via proposal) can call.
    /// @dev If the filter type is not `mintable`, this can only be called once for that `filterTypeId`.
    function mintNeuralFilter(uint33 filterTypeId, address to, uint256 amount) public onlyOwner {
        NeuralFilterParams storage params = neuralFilterParams[filterTypeId];
        if (bytes(params.name).length == 0) revert InvalidFilterType(); // Check if filter type exists
        if (!params.mintable && neuralFilterTotalSupply[filterTypeId] > 0) revert AlreadyMinted(); // For non-mintable filters

        neuralFilterBalances[to][filterTypeId] += amount;
        neuralFilterTotalSupply[filterTypeId] += amount;
        emit NeuralFilterMinted(to, filterTypeId, amount);
    }

    /// @notice Applies `quantity` of `filterTypeId` to `aetherialTokenId`.
    /// @dev The caller must own the Aetherial NFT (or be an approved operator) and have enough Neural Filters. Consumes filters.
    function applyNeuralFilter(uint252 aetherialTokenId, uint33 filterTypeId, uint33 quantity) public {
        address nftOwner = ownerOf(aetherialTokenId); // Implicitly checks _exists
        if (msg.sender != nftOwner && !isApprovedForAll(nftOwner, msg.sender)) revert NotOwnerOrApproved();
        if (quantity == 0) return;

        NeuralFilterParams storage params = neuralFilterParams[filterTypeId];
        if (bytes(params.name).length == 0) revert InvalidFilterType();
        if (neuralFilterBalances[msg.sender][filterTypeId] < quantity) revert InsufficientFilterBalance();

        // Deduct filters from sender's balance
        neuralFilterBalances[msg.sender][filterTypeId] -= quantity;

        // Add filter to the Aetherial NFT's applied list
        appliedNeuralFilters[aetherialTokenId].push(AppliedFilter({
            filterTypeId: filterTypeId,
            quantity: quantity,
            appliedTime: uint48(block.timestamp)
        }));

        emit NeuralFilterApplied(aetherialTokenId, filterTypeId, quantity, msg.sender);
    }

    /// @notice Removes `quantity` of `filterTypeId` from `aetherialTokenId` and returns to caller.
    /// @dev Only the NFT owner/operator can remove filters.
    function removeNeuralFilter(uint252 aetherialTokenId, uint33 filterTypeId, uint33 quantity) public {
        address nftOwner = ownerOf(aetherialTokenId); // Implicitly checks _exists
        if (msg.sender != nftOwner && !isApprovedForAll(nftOwner, msg.sender)) revert NotOwnerOrApproved();
        if (quantity == 0) return;

        AppliedFilter[] storage filters = appliedNeuralFilters[aetherialTokenId];
        bool found = false;
        for (uint256 i = 0; i < filters.length; i++) {
            if (filters[i].filterTypeId == filterTypeId) {
                if (filters[i].quantity < quantity) revert FilterNotApplied();
                filters[i].quantity -= quantity;
                neuralFilterBalances[msg.sender][filterTypeId] += quantity; // Return filters to sender

                if (filters[i].quantity == 0) {
                    // Remove entry if quantity becomes zero by swapping with last and popping
                    filters[i] = filters[filters.length - 1];
                    filters.pop();
                }
                found = true;
                break;
            }
        }
        if (!found) revert FilterNotApplied();

        emit NeuralFilterRemoved(aetherialTokenId, filterTypeId, quantity, msg.sender);
    }

    /// @notice Returns the list of Neural Filters currently applied to an Aetherial NFT.
    function getAppliedFilters(uint256 aetherialTokenId) public view returns (AppliedFilter[] memory) {
        if (!_exists(aetherialTokenId)) revert InvalidTokenId();
        return appliedNeuralFilters[aetherialTokenId];
    }

    /// @notice Retrieves the parameters and effects of a specific Neural Filter type.
    function getFilterEffectData(uint33 filterTypeId) public view returns (NeuralFilterParams memory) {
        NeuralFilterParams storage params = neuralFilterParams[filterTypeId];
        if (bytes(params.name).length == 0) revert InvalidFilterType(); // Check if filter type exists
        return params;
    }

    /// @notice Returns the balance of a specific Neural Filter type for an address.
    function balanceOfFilter(address account, uint33 filterTypeId) public view returns (uint256) {
        return neuralFilterBalances[account][filterTypeId];
    }

    /// @notice Allows burning units of a Neural Filter.
    function burnNeuralFilter(uint33 filterTypeId, uint256 amount) public {
        if (amount == 0) return;
        NeuralFilterParams storage params = neuralFilterParams[filterTypeId];
        if (bytes(params.name).length == 0) revert InvalidFilterType();
        if (neuralFilterBalances[msg.sender][filterTypeId] < amount) revert InsufficientFilterBalance();

        neuralFilterBalances[msg.sender][filterTypeId] -= amount;
        neuralFilterTotalSupply[filterTypeId] -= amount;
        emit NeuralFilterBurned(msg.sender, filterTypeId, amount);
    }


    // --- IV. DAO Governance ---

    /// @notice Allows Aetherial NFT holders to propose changes to core parameters.
    /// @dev Requires the proposer to own at least `proposalThreshold` Aetherial NFTs.
    /// @param paramKey The hash of the parameter name (e.g., keccak256("evolutionCooldownDuration")).
    /// @param newValue The new value for the parameter.
    /// @param proposerTokenId The ID of one of the proposer's Aetherial NFTs (used for identification).
    function proposeEvolutionParameterChange(bytes32 paramKey, uint256 newValue, uint256 proposerTokenId) public {
        if (balanceOf(msg.sender) < proposalThreshold) revert InsufficientNFTsForProposal();
        if (ownerOf(proposerTokenId) != msg.sender) revert InvalidTokenId(); // Must own the token used to propose

        // Ensure paramKey is a recognized modifiable parameter
        bool recognizedParam = false;
        if (paramKey == keccak256("evolutionCooldownDuration") ||
            paramKey == keccak256("proposalVotingPeriod") ||
            paramKey == keccak256("proposalMinQuorum") ||
            paramKey == keccak256("proposalThreshold")) {
            recognizedParam = true;
        }
        if (!recognizedParam) revert InvalidProposalParameter();

        uint256 newProposalId = nextProposalId;
        unchecked { nextProposalId++; }
        proposals[newProposalId] = EvolutionProposal({
            paramKey: paramKey,
            newValue: newValue,
            proposerTokenId: proposerTokenId,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize empty mapping
            executed: false
        });

        emit ProposalCreated(newProposalId, paramKey, newValue, proposerTokenId, block.timestamp, block.timestamp + proposalVotingPeriod);
    }

    /// @notice Allows Aetherial NFT holders to vote on active proposals.
    /// @dev Each NFT held grants one vote. Requires at least `proposalThreshold` NFTs.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'for' vote, false for 'against'.
    function voteOnProposal(uint256 proposalId, bool support) public {
        EvolutionProposal storage proposal = proposals[proposalId];
        if (proposal.startTime == 0) revert InvalidProposalId(); // Proposal doesn't exist
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (block.timestamp < proposal.startTime || block.timestamp > proposal.endTime) revert ProposalPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();
        if (balanceOf(msg.sender) < proposalThreshold) revert InsufficientNFTsForVote(); // Only NFT holders with enough NFTs can vote

        uint256 voterNFTCount = balanceOf(msg.sender); // Each NFT counts as one vote
        if (support) {
            proposal.votesFor += voterNFTCount;
        } else {
            proposal.votesAgainst += voterNFTCount;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support);
    }

    /// @notice Executes a proposal if it has passed the voting period and quorum.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public {
        EvolutionProposal storage proposal = proposals[proposalId];
        if (proposal.startTime == 0) revert InvalidProposalId();
        if (block.timestamp < proposal.endTime) revert ProposalNotYetEnded();
        if (proposal.executed) revert ProposalAlreadyExecuted();

        uint252 totalVotes = proposal.votesFor + proposal.votesAgainst;
        if (totalVotes < proposalMinQuorum) revert QuorumNotMet();
        if (proposal.votesFor <= proposal.votesAgainst) revert ProposalNotExecutable(); // Must have more 'for' votes

        proposal.executed = true; // Mark as executed

        bytes32 paramKey = proposal.paramKey;
        uint256 oldValue;
        if (paramKey == keccak256("evolutionCooldownDuration")) {
            oldValue = evolutionCooldownDuration;
            evolutionCooldownDuration = proposal.newValue;
        } else if (paramKey == keccak256("proposalVotingPeriod")) {
            oldValue = proposalVotingPeriod;
            proposalVotingPeriod = proposal.newValue;
        } else if (paramKey == keccak256("proposalMinQuorum")) {
            oldValue = proposalMinQuorum;
            proposalMinQuorum = proposal.newValue;
        } else if (paramKey == keccak256("proposalThreshold")) {
            oldValue = proposalThreshold;
            proposalThreshold = proposal.newValue;
        } else {
            revert InvalidProposalParameter(); // Should not happen if `propose` validates, but good for safety
        }

        emit ProposalExecuted(proposalId, paramKey, proposal.newValue);
        emit ParameterChanged(paramKey, oldValue, proposal.newValue);
    }

    /// @notice Returns the current state of a proposal.
    /// @return State: 0 (NonExistent), 1 (Active), 2 (Defeated), 3 (Succeeded), 4 (Executed)
    function getProposalState(uint256 proposalId) public view returns (uint8) {
        EvolutionProposal storage proposal = proposals[proposalId];
        if (proposal.startTime == 0) return 0; // Proposal does not exist
        if (proposal.executed) return 4; // Executed

        if (block.timestamp < proposal.endTime) return 1; // Active

        // Voting period has ended
        uint252 totalVotes = proposal.votesFor + proposal.votesAgainst;
        if (totalVotes < proposalMinQuorum || proposal.votesFor <= proposal.votesAgainst) {
            return 2; // Defeated (either quorum not met or 'against' votes are equal/higher)
        }
        return 3; // Succeeded (quorum met, 'for' votes outweigh 'against')
    }


    // --- V. Staking & Rewards ---

    /// @notice Stakes an Aetherial NFT. The caller must own the NFT (or be an approved operator).
    /// @param tokenId The ID of the Aetherial NFT to stake.
    function stakeAetherialNFT(uint256 tokenId) public {
        address nftOwner = ownerOf(tokenId); // Implicitly checks _exists
        if (msg.sender != nftOwner && !isApprovedForAll(nftOwner, msg.sender)) revert NotOwnerOrApproved();
        if (stakedAetherialNFTs[tokenId] != 0) revert AlreadyStaked(); // Check if already staked

        stakedAetherialNFTs[tokenId] = block.timestamp;
        emit AetherialNFTStaked(nftOwner, tokenId, block.timestamp);
    }

    /// @notice Unstakes a previously staked Aetherial NFT and calculates rewards.
    /// @param tokenId The ID of the Aetherial NFT to unstake.
    function unstakeAetherialNFT(uint256 tokenId) public {
        address nftOwner = ownerOf(tokenId); // Implicitly checks _exists
        if (msg.sender != nftOwner && !isApprovedForAll(nftOwner, msg.sender)) revert NotOwnerOrApproved();
        uint252 stakeTime = stakedAetherialNFTs[tokenId];
        if (stakeTime == 0) revert NotStaked();

        // Calculate rewards for the duration it was staked
        uint252 duration = block.timestamp - stakeTime;
        uint252 rewards = (duration * STAKING_REWARD_RATE_PER_DAY) / 1 days; // Rewards are proportional to time

        // Accumulate rewards for the NFT owner, to be claimed separately
        stakingRewardsAccumulated[nftOwner] += rewards;

        delete stakedAetherialNFTs[tokenId]; // Remove from staked list
        emit AetherialNFTUnstaked(nftOwner, tokenId, block.timestamp, rewards);
    }

    /// @notice Claims accumulated staking rewards (in ETH).
    /// @dev Transfers ETH to the caller.
    function claimStakingRewards() public {
        uint252 rewards = stakingRewardsAccumulated[msg.sender];
        if (rewards == 0) revert NoRewardsToClaim();

        stakingRewardsAccumulated[msg.sender] = 0; // Reset rewards before transfer
        (bool success, ) = msg.sender.call{value: rewards}("");
        if (!success) {
            // Revert rewards if transfer fails to prevent loss
            stakingRewardsAccumulated[msg.sender] = rewards;
            revert TransferFailed();
        }
        emit StakingRewardsClaimed(msg.sender, rewards);
    }

    /// @notice Estimates potential rewards for a currently staked NFT.
    /// @param tokenId The ID of the staked Aetherial NFT.
    function getStakingRewardEstimate(uint256 tokenId) public view returns (uint256) {
        uint252 stakeTime = stakedAetherialNFTs[tokenId];
        if (stakeTime == 0) return 0; // Not staked

        uint252 duration = block.timestamp - stakeTime;
        return (duration * STAKING_REWARD_RATE_PER_DAY) / 1 days;
    }


    // --- VI. Protocol Configuration & Oracles ---

    /// @notice Registers an address as an authorized oracle. Only `owner` can call.
    function registerEnvironmentalOracle(address oracleAddress) public onlyOwner {
        authorizedOracles[oracleAddress] = true;
    }

    /// @notice An authorized oracle updates a global environmental factor.
    /// @dev `factorId` is an arbitrary ID representing different environmental data points.
    ///      `value` is the new reading for that factor.
    function updateEnvironmentalFactor(uint33 factorId, uint256 value) public {
        if (!authorizedOracles[msg.sender]) revert UnauthorizedOracle();
        environmentalFactors[factorId] = value;
        emit EnvironmentalFactorUpdated(factorId, value, msg.sender);
    }

    /// @notice Sets the duration for the evolution cooldown.
    /// @dev This function is intended to be called only via `executeProposal` after a successful DAO vote.
    ///      It is `public onlyOwner` for initial setup and testing, but should be considered internal to DAO logic.
    function setEvolutionCooldown(uint256 duration) public onlyOwner {
        uint252 oldValue = evolutionCooldownDuration;
        evolutionCooldownDuration = duration;
        emit ParameterChanged(keccak256("evolutionCooldownDuration"), oldValue, duration);
    }

    /// @notice Sets the proposal voting period.
    /// @dev This function is intended to be called only via `executeProposal` after a successful DAO vote.
    function setProposalVotingPeriod(uint256 period) public onlyOwner {
        uint252 oldValue = proposalVotingPeriod;
        proposalVotingPeriod = period;
        emit ParameterChanged(keccak256("proposalVotingPeriod"), oldValue, period);
    }

    /// @notice Sets the minimum quorum required for a proposal to pass.
    /// @dev This function is intended to be called only via `executeProposal` after a successful DAO vote.
    function setProposalMinQuorum(uint256 quorum) public onlyOwner {
        uint252 oldValue = proposalMinQuorum;
        proposalMinQuorum = quorum;
        emit ParameterChanged(keccak256("proposalMinQuorum"), oldValue, quorum);
    }

    /// @notice Retrieves all currently set environmental factors.
    /// @dev This is a simplified approach, a real system might store factor names or a dynamic list.
    ///      For now, it returns a fixed set of known factor IDs (1 and 2) and their values.
    function getEnvironmentalFactors() public view returns (uint33[] memory factorIds, uint252[] memory values) {
        factorIds = new uint33[](2); // Assuming 2 factors for this example
        values = new uint252[](2);

        factorIds[0] = 1; values[0] = environmentalFactors[1];
        factorIds[1] = 2; values[1] = environmentalFactors[2];
        return (factorIds, values);
    }

    /// @notice Returns the total number of Aetherial NFTs minted so far.
    function getTotalSupplyAetherialNFTs() public view returns (uint256) {
        return _nextTokenId; // Since _nextTokenId is incremented before assignment
    }

    /// @notice Returns the total supply for a specific Neural Filter type.
    function getTotalSupplyNeuralFilter(uint33 filterTypeId) public view returns (uint256) {
        return neuralFilterTotalSupply[filterTypeId];
    }

    /// @notice Returns the next available filter type ID.
    function getNextFilterTypeId() public view returns (uint33) {
        return nextFilterTypeId;
    }

    // Helper for converting uint256 to string for tokenURI - similar to OpenZeppelin's Strings library
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
}
```