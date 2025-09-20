This smart contract, named `ElysiumGenesis`, introduces a novel ecosystem centered around "Elysian Entities" (EEs), which are dynamic, evolving digital lifeforms represented as Non-Fungible Tokens (dNFTs). EEs possess a range of attributes (energy, intelligence, resilience, adaptability, growth stage, affinity traits) that can change over time based on on-chain actions, user interactions, and external data fed by a trusted oracle (simulating AI-driven insights and environmental factors).

The ecosystem features a native utility token (`GEN`) used for minting EEs, fueling their activities, and participating in a decentralized governance system. The contract aims to demonstrate advanced concepts like dNFTs with on-chain metadata evolution, oracle-influenced state changes, an internal economic loop (via the `GEN` token), and a comprehensive governance module, all within a single, cohesive smart contract.

---

## ElysiumGenesis Smart Contract Outline & Function Summary

**I. Core Ecosystem & Utility Token (GEN - ERC20 Implementation)**
This section defines the native utility token `GEN`, which is an ERC20 compliant token embedded directly within this contract.
*   **`constructor(address _initialOracle, address _initialDeployer)`:** Initializes the contract, sets the initial oracle and deployer, and mints an initial supply of GEN tokens to the deployer.
*   **`name()`:** Returns the token's name ("GENESIS Token").
*   **`symbol()`:** Returns the token's symbol ("GEN").
*   **`decimals()`:** Returns the number of decimal places the token uses (18).
*   **`totalSupply()`:** Returns the total number of GEN tokens in existence.
*   **`balanceOf(address account)`:** Returns the GEN token balance of a given account.
*   **`transfer(address to, uint256 amount)`:** Transfers GEN tokens from the caller's account to another address.
*   **`approve(address spender, uint256 amount)`:** Allows a `spender` to withdraw `amount` GEN tokens from the caller's account.
*   **`allowance(address owner, address spender)`:** Returns the amount that `spender` is still allowed to spend on behalf of `owner`.
*   **`transferFrom(address from, address to, uint256 amount)`:** Transfers `amount` GEN tokens from `from` to `to` using the `spender`'s allowance.
*   **`mintGenesis(address _to, uint256 _amount)`:** Allows the contract owner or governance to mint new GEN tokens, primarily for rewards or initial distribution.
*   **`burnGenesis(uint256 _amount)`:** Allows a user to burn their own GEN tokens, reducing the total supply.

**II. Elysian Entity (EE) Management (dNFTs - ERC721 Implementation)**
This section defines the Elysian Entities (EEs) as ERC721 compliant dNFTs with dynamic attributes and on-chain generated metadata.
*   **`mintElysianEntity()`:** Mints a new Elysian Entity (EE) to the caller with initial, randomly generated attributes. Requires a cost in GEN tokens.
*   **`name()`:** Returns the NFT collection's name ("Elysian Entities").
*   **`symbol()`:** Returns the NFT collection's symbol ("EE").
*   **`tokenURI(uint256 _tokenId)`:** Generates and returns a base64-encoded SVG metadata URI for a given EE, which dynamically reflects its current attributes.
*   **`balanceOf(address owner)`:** Returns the number of EEs owned by a specific address.
*   **`ownerOf(uint256 tokenId)`:** Returns the owner of a specific EE token.
*   **`safeTransferFrom(address from, address to, uint256 tokenId)`:** Transfers an EE token from `from` to `to`, with safety checks.
*   **`safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)`:** Transfers an EE token with additional data.
*   **`transferFrom(address from, address to, uint256 tokenId)`:** Transfers an EE token (legacy ERC721 transfer).
*   **`approve(address to, uint256 tokenId)`:** Approves an address to transfer a specific EE token.
*   **`getApproved(uint256 tokenId)`:** Returns the approved address for a specific EE token.
*   **`setApprovalForAll(address operator, bool approved)`:** Approves or disapproves an operator to manage all EEs owned by the caller.
*   **`isApprovedForAll(address owner, address operator)`:** Checks if an operator is approved for all EEs of an owner.
*   **`getEntityAttributes(uint256 _tokenId)`:** Retrieves all current dynamic attributes of a specific EE.
*   **`feedEntity(uint256 _tokenId, uint256 _amount)`:** Replenishes an EE's energy using GEN tokens. Essential for continued activity and evolution.
*   **`triggerEvolutionAttempt(uint256 _tokenId)`:** An EE attempts to evolve, consuming energy. The success and nature of evolution are influenced by internal logic and oracle-fed data.
*   **`initiateSynergy(uint256 _tokenIdA, uint256 _tokenIdB)`:** Allows two EEs to interact, potentially leading to mutual attribute boosts or new "affinity traits" for both, consuming energy from both.
*   **`getEvolutionHistory(uint256 _tokenId)`:** Provides a historical record of an EE's past evolution and significant attribute changes.

**III. Oracle & Environmental Data**
This section manages the integration with an off-chain oracle, simulating external data (AI recommendations, environmental factors) influencing the EEs.
*   **`setOracleAddress(address _newOracle)`:** Allows the contract deployer (or governance) to update the trusted oracle address.
*   **`requestEnvironmentalFactors()`:** A placeholder function that would signal an off-chain oracle to fetch and update global environmental factors within the contract.
*   **`updateEnvironmentalFactors(uint256 _globalEnergyDecayRate, uint256 _mutationChance)`:** Callable only by the authorized oracle to update global parameters that universally affect EE behavior and evolution.
*   **`requestAIAttributeRecommendation(uint256 _tokenId)`:** A placeholder signalling the oracle to fetch AI-driven attribute recommendations for a specific EE.
*   **`applyAIAttributeRecommendation(uint256 _tokenId, uint256 _newIntelligence, uint256 _newResilience)`:** Callable only by the oracle to apply AI-recommended attribute changes to an EE.
*   **`getGlobalParameters()`:** Retrieves the current global environmental parameters.

**IV. Governance Module**
A decentralized governance system allowing GEN token holders to propose and vote on significant contract changes and global parameters.
*   **`stakeForGovernance(uint256 _amount)`:** Users stake their GEN tokens to gain voting power for governance proposals.
*   **`unstakeFromGovernance(uint256 _amount)`:** Allows users to withdraw their staked GEN tokens after a cooldown period.
*   **`proposeParameterChange(string memory _description, address _target, uint256 _value, bytes memory _calldata)`:** Users with sufficient staked GEN can propose a change to the contract's parameters or execute arbitrary calls, requiring a description, target contract, value, and calldata.
*   **`voteOnProposal(uint256 _proposalId, bool _support)`:** Staked GEN holders cast their vote (for or against) on an active proposal.
*   **`executeProposal(uint256 _proposalId)`:** Executes a proposal that has reached the required quorum, majority vote, and whose voting period has ended.
*   **`getProposalDetails(uint256 _proposalId)`:** Retrieves comprehensive information about a specific governance proposal.
*   **`setEvolutionPath(uint256 _pathId, uint256 _energyCost, uint256 _intelligenceBoost, uint256 _resilienceBoost, uint256 _adaptabilityBoost)`:** Callable only via governance proposal execution, this function allows the DAO to define new, named evolutionary paths or specific trait boosts that EEs can subsequently attempt to follow.
*   **`getEvolutionPathDetails(uint256 _pathId)`:** Retrieves details about a specific, defined evolutionary path.

**V. Reputation System**
A system to track and reward user engagement and positive contributions to the ecosystem.
*   **`claimReputationReward()`:** Allows users to claim accumulated reputation points, typically earned from their EEs successfully evolving or engaging in synergy.
*   **`getReputationScore(address _user)`:** Retrieves the current reputation score for a specific user address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ElysiumGenesis
/// @author Your Name/AI
/// @notice ElysiumGenesis is a sophisticated smart contract that introduces "Elysian Entities" (EEs),
///         which are dynamic, evolving digital lifeforms represented as Non-Fungible Tokens (dNFTs).
///         EEs possess a range of attributes (energy, intelligence, resilience, adaptability, growth stage,
///         affinity traits) that can change over time based on on-chain actions, user interactions,
///         and external data fed by a trusted oracle (simulating AI-driven insights and environmental factors).
///         The ecosystem features a native utility token ($GENESIS) used for minting EEs, fueling their activities,
///         and participating in a decentralized governance system. The contract aims to demonstrate advanced concepts
///         like dNFTs with on-chain metadata evolution, oracle-influenced state changes, an internal economic loop,
///         and a comprehensive governance module.

// Minimal ERC165 Interface for `supportsInterface`
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Minimal ERC721 Interface for reference (actual implementation is within this contract)
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint255 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Minimal ERC721Metadata Interface for reference
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Minimal ERC20 Interface for reference (actual implementation is within this contract)
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


contract ElysiumGenesis is IERC165, IERC721Metadata, IERC20 {
    // --- State Variables & Constants ---

    // GENESIS Token (ERC20)
    string private constant _GENESIS_NAME = "GENESIS Token";
    string private constant _GENESIS_SYMBOL = "GEN";
    uint8 private constant _GENESIS_DECIMALS = 18;
    uint256 private _genesisTotalSupply;
    mapping(address => uint256) private _genesisBalances;
    mapping(address => mapping(address => uint256)) private _genesisAllowances;

    // Elysian Entity (EE) dNFT (ERC721)
    string private constant _EE_NAME = "Elysian Entities";
    string private constant _EE_SYMBOL = "EE";
    uint256 private _nextTokenId;
    mapping(uint256 => address) private _eeOwners;
    mapping(address => uint256) private _eeBalances;
    mapping(uint256 => address) private _eeTokenApprovals;
    mapping(address => mapping(address => bool)) private _eeOperatorApprovals;

    // EE Attributes and State
    struct ElysianEntity {
        uint256 intelligence;
        uint256 resilience;
        uint256 adaptability;
        uint256 energy;
        uint256 growthStage; // 0=Larva, 1=Juvenile, 2=Adult, 3=Evolved
        uint256 lastActionTime;
        bool isAlive;
        uint256[] affinityTraits; // Arbitrary trait IDs
    }
    mapping(uint256 => ElysianEntity) private _entities;
    mapping(uint256 => uint256[]) private _evolutionHistory; // tokenId => array of timestamps/eventIds

    // Oracle Configuration
    address public oracleAddress;
    address public deployer; // For initial admin-like tasks, can be replaced by governance

    // Environmental Parameters (updated by oracle)
    uint256 public globalEnergyDecayRate = 1; // Energy decay per block/hour (mock)
    uint256 public mutationChance = 100; // Chance out of 10000 (0.01%) for mutation on evolution

    // Governance
    struct Proposal {
        string description;
        address target;
        uint256 value;
        bytes calldataBytes;
        uint256 creationTime;
        uint256 votingPeriodEnd;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
    }
    Proposal[] public proposals;
    uint256 public constant MIN_STAKE_FOR_PROPOSAL = 100 * (10 ** _GENESIS_DECIMALS);
    uint256 public constant VOTING_PERIOD_DURATION = 7 days; // 7 days for voting
    uint256 public constant QUORUM_PERCENTAGE = 10; // 10% of total staked supply
    mapping(address => uint256) private _stakedGovernanceTokens;
    uint256 private _totalStakedGovernanceTokens;
    uint256 public constant UNSTAKE_COOLDOWN = 3 days; // Cooldown before unstaking
    mapping(address => uint256) private _unstakeCooldowns;

    // Evolution Paths (defined by governance)
    struct EvolutionPath {
        uint256 energyCost;
        uint256 intelligenceBoost;
        uint256 resilienceBoost;
        uint256 adaptabilityBoost;
        bool isActive;
    }
    mapping(uint256 => EvolutionPath) public evolutionPaths;
    uint256 private _nextEvolutionPathId = 1;

    // Reputation System
    mapping(address => uint256) private _reputationScores;
    uint256 public constant REPUTATION_PER_EVOLUTION = 5;
    uint256 public constant REPUTATION_PER_SYNERGY = 2;

    // --- Events ---
    event GenesisMinted(address indexed to, uint256 amount);
    event GenesisBurnt(address indexed from, uint256 amount);
    event GenesisTransfer(address indexed from, address indexed to, uint256 value);
    event GenesisApproval(address indexed owner, address indexed spender, uint256 value);

    event EntityMinted(uint256 indexed tokenId, address indexed owner, uint256 initialIntelligence, uint256 initialResilience, uint256 initialAdaptability);
    event EntityFed(uint256 indexed tokenId, address indexed feeder, uint256 amount);
    event EntityEvolutionAttempt(uint256 indexed tokenId, bool success, uint256 newIntelligence, uint256 newResilience, uint256 newAdaptability);
    event EntitySynergyInitiated(uint256 indexed tokenIdA, uint256 indexed tokenIdB, bool success);

    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event EnvironmentalFactorsUpdated(uint256 globalEnergyDecayRate, uint256 mutationChance);
    event AIAttributeRecommendationApplied(uint256 indexed tokenId, uint256 newIntelligence, uint256 newResilience);

    event StakedForGovernance(address indexed staker, uint256 amount);
    event UnstakedFromGovernance(address indexed staker, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 votingPeriodEnd);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event EvolutionPathSet(uint256 indexed pathId, uint256 energyCost, uint256 intelligenceBoost, uint256 resilienceBoost, uint256 adaptabilityBoost);

    event ReputationClaimed(address indexed user, uint256 amount);

    // --- Modifiers ---
    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer can call this function");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle can call this function");
        _;
    }

    modifier entityOwnerOrApproved(uint256 _tokenId) {
        require(_eeOwners[_tokenId] == msg.sender || _eeTokenApprovals[_tokenId] == msg.sender || _eeOperatorApprovals[_eeOwners[_tokenId]][msg.sender], "Not owner nor approved");
        _;
    }

    modifier entityExists(uint256 _tokenId) {
        require(_eeOwners[_tokenId] != address(0), "Entity does not exist");
        _;
    }

    // --- Constructor ---
    constructor(address _initialOracle, address _initialDeployer) {
        deployer = _initialDeployer;
        oracleAddress = _initialOracle;

        // Mint initial GENESIS tokens to the deployer
        _mint(_initialDeployer, 10_000_000 * (10 ** _GENESIS_DECIMALS)); // 10 million GENESIS
    }

    // --- ERC165: supportsInterface ---
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               interfaceId == type(IERC20).interfaceId;
    }

    // =========================================================================
    // I. Core Ecosystem & Utility Token (GEN - ERC20 Implementation)
    // =========================================================================

    /// @notice Returns the name of the GENESIS token.
    function name() public pure override returns (string memory) {
        return _GENESIS_NAME;
    }

    /// @notice Returns the symbol of the GENESIS token.
    function symbol() public pure override returns (string memory) {
        return _GENESIS_SYMBOL;
    }

    /// @notice Returns the number of decimals used by the GENESIS token.
    function decimals() public pure returns (uint8) {
        return _GENESIS_DECIMALS;
    }

    /// @notice Returns the total supply of GENESIS tokens.
    function totalSupply() public view override returns (uint256) {
        return _genesisTotalSupply;
    }

    /// @notice Returns the GENESIS token balance of a given account.
    /// @param account The address to query the balance of.
    function balanceOf(address account) public view override returns (uint256) {
        return _genesisBalances[account];
    }

    /// @notice Transfers `amount` GENESIS tokens from the caller's account to `to`.
    /// @param to The recipient's address.
    /// @param amount The amount of tokens to transfer.
    /// @return A boolean indicating if the transfer was successful.
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Allows `spender` to withdraw `amount` GENESIS tokens from the caller's account.
    /// @param spender The address to be approved.
    /// @param amount The amount of tokens to approve.
    /// @return A boolean indicating if the approval was successful.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @notice Returns the amount that `spender` is still allowed to spend on behalf of `owner`.
    /// @param owner The address of the token owner.
    /// @param spender The address of the allowed spender.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _genesisAllowances[owner][spender];
    }

    /// @notice Transfers `amount` GENESIS tokens from `from` to `to` using the `spender`'s allowance.
    /// @param from The sender's address.
    /// @param to The recipient's address.
    /// @param amount The amount of tokens to transfer.
    /// @return A boolean indicating if the transfer was successful.
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _genesisAllowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(from, msg.sender, currentAllowance - amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    /// @notice Internal transfer function for GENESIS token.
    /// @param from The sender's address.
    /// @param to The recipient's address.
    /// @param amount The amount of tokens to transfer.
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _genesisBalances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked {
            _genesisBalances[from] = fromBalance - amount;
            _genesisBalances[to] += amount;
        }

        emit GenesisTransfer(from, to, amount);
    }

    /// @notice Internal approve function for GENESIS token.
    /// @param owner The address of the token owner.
    /// @param spender The address to be approved.
    /// @param amount The amount of tokens to approve.
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _genesisAllowances[owner][spender] = amount;
        emit GenesisApproval(owner, spender, amount);
    }

    /// @notice Mints `amount` GENESIS tokens to `_to`. Callable only by deployer/governance.
    /// @param _to The recipient's address.
    /// @param _amount The amount of tokens to mint.
    function mintGenesis(address _to, uint256 _amount) public onlyDeployer { // In future, change to governance
        _mint(_to, _amount);
    }

    /// @notice Internal mint function for GENESIS token.
    /// @param _to The recipient's address.
    /// @param _amount The amount of tokens to mint.
    function _mint(address _to, uint256 _amount) internal {
        require(_to != address(0), "ERC20: mint to the zero address");
        _genesisTotalSupply += _amount;
        _genesisBalances[_to] += _amount;
        emit GenesisMinted(_to, _amount);
        emit GenesisTransfer(address(0), _to, _amount);
    }

    /// @notice Burns `amount` GENESIS tokens from the caller's account.
    /// @param _amount The amount of tokens to burn.
    function burnGenesis(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    /// @notice Internal burn function for GENESIS token.
    /// @param _from The address from which tokens are burnt.
    /// @param _amount The amount of tokens to burn.
    function _burn(address _from, uint256 _amount) internal {
        require(_from != address(0), "ERC20: burn from the zero address");
        require(_genesisBalances[_from] >= _amount, "ERC20: burn amount exceeds balance");

        unchecked {
            _genesisBalances[_from] -= _amount;
            _genesisTotalSupply -= _amount;
        }

        emit GenesisBurnt(_from, _amount);
        emit GenesisTransfer(_from, address(0), _amount);
    }


    // =========================================================================
    // II. Elysian Entity (EE) Management (dNFTs - ERC721 Implementation)
    // =========================================================================

    /// @notice Mints a new Elysian Entity (EE) to the caller with initial, randomly generated attributes.
    ///         Requires a cost in GEN tokens.
    /// @dev The cost and initial attributes can be tuned.
    function mintElysianEntity() public returns (uint256) {
        uint256 mintCost = 100 * (10 ** _GENESIS_DECIMALS); // Example cost: 100 GEN
        require(_genesisBalances[msg.sender] >= mintCost, "Insufficient GENESIS to mint an entity");
        _burn(msg.sender, mintCost); // Burn GENESIS for minting

        _nextTokenId++;
        uint256 newId = _nextTokenId;

        // Generate initial random-ish attributes based on block hash and current timestamp
        // (Note: Block hash is not truly random, but sufficient for initial variations)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newId)));

        _entities[newId] = ElysianEntity({
            intelligence: (seed % 50) + 50, // 50-99
            resilience: ((seed / 10) % 50) + 50, // 50-99
            adaptability: ((seed / 100) % 50) + 50, // 50-99
            energy: 100, // Starting energy
            growthStage: 0, // Larva
            lastActionTime: block.timestamp,
            isAlive: true,
            affinityTraits: new uint256[](0)
        });
        _evolutionHistory[newId].push(block.timestamp); // Record initial creation

        _mintEntity(msg.sender, newId);
        emit EntityMinted(newId, msg.sender, _entities[newId].intelligence, _entities[newId].resilience, _entities[newId].adaptability);
        return newId;
    }

    /// @notice Returns the name of the EE NFT collection.
    function name() public pure override returns (string memory) {
        return _EE_NAME;
    }

    /// @notice Returns the symbol of the EE NFT collection.
    function symbol() public pure override returns (string memory) {
        return _EE_SYMBOL;
    }

    /// @notice Generates and returns a base64-encoded SVG metadata URI for a given EE,
    ///         which dynamically reflects its current attributes.
    /// @param tokenId The ID of the EE.
    /// @dev This function dynamically generates metadata on-chain.
    function tokenURI(uint256 tokenId) public view override entityExists(tokenId) returns (string memory) {
        ElysianEntity storage entity = _entities[tokenId];
        string memory growthStage;
        if (entity.growthStage == 0) growthStage = "Larva";
        else if (entity.growthStage == 1) growthStage = "Juvenile";
        else if (entity.growthStage == 2) growthStage = "Adult";
        else growthStage = "Evolved";

        string memory svg = string(abi.encodePacked(
            "<svg width='350' height='350' viewBox='0 0 350 350' xmlns='http://www.w3.org/2000/svg'>",
            "<rect x='0' y='0' width='350' height='350' fill='#", _getBackgroundColor(entity.energy), "'/>", // Dynamic background
            "<text x='175' y='50' font-family='monospace' font-size='20' fill='#FFF' text-anchor='middle'>", "Elysian Entity #", toString(tokenId), "</text>",
            "<text x='175' y='80' font-family='monospace' font-size='16' fill='#FFF' text-anchor='middle'>Stage: ", growthStage, "</text>",
            "<text x='50' y='120' font-family='monospace' font-size='14' fill='#FFF'>Intelligence: ", toString(entity.intelligence), "</text>",
            "<text x='50' y='140' font-family='monospace' font-size='14' fill='#FFF'>Resilience: ", toString(entity.resilience), "</text>",
            "<text x='50' y='160' font-family='monospace' font-size='14' fill='#FFF'>Adaptability: ", toString(entity.adaptability), "</text>",
            "<text x='50' y='180' font-family='monospace' font-size='14' fill='#FFF'>Energy: ", toString(entity.energy), "</text>",
            "<text x='50' y='200' font-family='monospace' font-size='14' fill='#FFF'>Alive: ", entity.isAlive ? "Yes" : "No", "</text>",
            // Add more dynamic elements based on attributes
            "</svg>"
        ));

        string memory json = string(abi.encodePacked(
            '{"name": "', _EE_NAME, ' #', toString(tokenId), '",',
            '"description": "A dynamic Elysian Entity evolving on-chain.",',
            '"image": "data:image/svg+xml;base64,', _encodeBase64(bytes(svg)), '",',
            '"attributes": [',
                '{"trait_type": "Growth Stage", "value": "', growthStage, '"},',
                '{"trait_type": "Intelligence", "value": ', toString(entity.intelligence), '},',
                '{"trait_type": "Resilience", "value": ', toString(entity.resilience), '},',
                '{"trait_type": "Adaptability", "value": ', toString(entity.adaptability), '},',
                '{"trait_type": "Energy", "value": ', toString(entity.energy), '},',
                '{"trait_type": "Is Alive", "value": ', entity.isAlive ? "true" : "false", '}'
            ']}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", _encodeBase64(bytes(json))));
    }

    /// @notice Returns the number of EEs owned by a specific address.
    /// @param owner The address to query the EE balance of.
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _eeBalances[owner];
    }

    /// @notice Returns the owner of a specific EE token.
    /// @param tokenId The ID of the EE.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _eeOwners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /// @notice Transfers an EE token from `from` to `to`, with safety checks.
    /// @param from The current owner of the EE.
    /// @param to The recipient's address.
    /// @param tokenId The ID of the EE to transfer.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @notice Transfers an EE token from `from` to `to` with additional data.
    /// @param from The current owner of the EE.
    /// @param to The recipient's address.
    /// @param tokenId The ID of the EE to transfer.
    /// @param _data Additional data to pass.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /// @notice Transfers an EE token (legacy ERC721 transfer).
    /// @param from The current owner of the EE.
    /// @param to The recipient's address.
    /// @param tokenId The ID of the EE to transfer.
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _transferEntity(from, to, tokenId);
    }

    /// @notice Approves an address to transfer a specific EE token.
    /// @param to The address to be approved.
    /// @param tokenId The ID of the EE to approve.
    function approve(address to, uint256 tokenId) public override {
        address owner = _eeOwners[tokenId];
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || _eeOperatorApprovals[owner][msg.sender], "ERC721: approve caller is not owner nor approved for all");

        _eeTokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /// @notice Returns the approved address for a specific EE token.
    /// @param tokenId The ID of the EE.
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_eeOwners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return _eeTokenApprovals[tokenId];
    }

    /// @notice Approves or disapproves an operator to manage all EEs owned by the caller.
    /// @param operator The address to approve/disapprove.
    /// @param approved True to approve, false to disapprove.
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _eeOperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Checks if an operator is approved for all EEs of an owner.
    /// @param owner The address of the EE owner.
    /// @param operator The address of the operator.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _eeOperatorApprovals[owner][operator];
    }

    /// @notice Internal function to check if an address is approved or owner of a token.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _eeOwners[tokenId];
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /// @notice Internal mint function for EE dNFT.
    function _mintEntity(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_eeOwners[tokenId] == address(0), "ERC721: token already minted");

        _eeOwners[tokenId] = to;
        _eeBalances[to]++;
        emit Transfer(address(0), to, tokenId);
    }

    /// @notice Internal transfer function for EE dNFT.
    function _transferEntity(address from, address to, uint256 tokenId) internal {
        require(_eeOwners[tokenId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals for the tokenId being transferred
        delete _eeTokenApprovals[tokenId];

        _eeBalances[from]--;
        _eeOwners[tokenId] = to;
        _eeBalances[to]++;

        emit Transfer(from, to, tokenId);
    }

    /// @notice Internal safe transfer function for EE dNFT.
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferEntity(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /// @notice Internal check for ERC721Receiver.
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (empty reason)");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    /// @notice Retrieves all current dynamic attributes of a specific EE.
    /// @param _tokenId The ID of the EE.
    /// @return intelligence, resilience, adaptability, energy, growthStage, isAlive, lastActionTime
    function getEntityAttributes(uint256 _tokenId) public view entityExists(_tokenId) returns (
        uint256 intelligence,
        uint256 resilience,
        uint256 adaptability,
        uint256 energy,
        uint256 growthStage,
        bool isAlive,
        uint256 lastActionTime
    ) {
        ElysianEntity storage entity = _entities[_tokenId];
        return (
            entity.intelligence,
            entity.resilience,
            entity.adaptability,
            entity.energy,
            entity.growthStage,
            entity.isAlive,
            entity.lastActionTime
        );
    }

    /// @notice Replenishes an EE's energy using GEN tokens. Essential for continued activity and evolution.
    /// @param _tokenId The ID of the EE.
    /// @param _amount The amount of GENESIS to convert to energy.
    /// @dev 1 GENESIS = 100 Energy (example conversion)
    function feedEntity(uint256 _tokenId, uint256 _amount) public entityOwnerOrApproved(_tokenId) entityExists(_tokenId) {
        ElysianEntity storage entity = _entities[_tokenId];
        require(entity.isAlive, "Entity is not alive");
        require(_genesisBalances[msg.sender] >= _amount, "Insufficient GENESIS to feed entity");

        _burn(msg.sender, _amount);
        uint256 energyGained = _amount * 100; // Example conversion rate
        entity.energy += energyGained;
        entity.lastActionTime = block.timestamp; // Update last action time

        emit EntityFed(_tokenId, msg.sender, energyGained);
    }

    /// @notice An EE attempts to evolve, consuming energy. The success and nature of evolution are
    ///         influenced by internal logic and oracle-fed data.
    /// @param _tokenId The ID of the EE.
    /// @dev Consumes 50 energy, has a base chance of success, and can be influenced by global mutation chance.
    function triggerEvolutionAttempt(uint256 _tokenId) public entityOwnerOrApproved(_tokenId) entityExists(_tokenId) {
        ElysianEntity storage entity = _entities[_tokenId];
        require(entity.isAlive, "Entity is not alive");
        require(entity.energy >= 50, "Not enough energy for evolution attempt (requires 50)");

        // Deduct energy
        entity.energy -= 50;

        bool success = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _tokenId))) % 10000) < (5000 + mutationChance); // Base 50% chance + global mutation chance
        uint256 intelBoost = 0;
        uint256 resilBoost = 0;
        uint256 adaptBoost = 0;

        if (success) {
            // Apply base evolution boosts
            intelBoost = (uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, "intel"))) % 5) + 1; // 1-5
            resilBoost = (uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, "resil"))) % 5) + 1; // 1-5
            adaptBoost = (uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, "adapt"))) % 5) + 1; // 1-5

            // Apply boosts from a chosen evolution path if applicable and entity is ready for it
            uint256 chosenPathId = _entities[_tokenId].growthStage + 1; // Example: path 1 for larva, path 2 for juvenile etc.
            if (evolutionPaths[chosenPathId].isActive) {
                EvolutionPath storage path = evolutionPaths[chosenPathId];
                if (entity.energy >= path.energyCost) {
                    entity.energy -= path.energyCost;
                    intelBoost += path.intelligenceBoost;
                    resilBoost += path.resilienceBoost;
                    adaptBoost += path.adaptabilityBoost;
                }
            }
            
            entity.intelligence += intelBoost;
            entity.resilience += resilBoost;
            entity.adaptability += adaptBoost;

            // Advance growth stage
            if (entity.growthStage < 3) {
                entity.growthStage++;
            }
            _reputationScores[_eeOwners[_tokenId]] += REPUTATION_PER_EVOLUTION;
        } else {
            // Minor energy penalty or attribute decay on failed attempt
            entity.energy = entity.energy > 10 ? entity.energy - 10 : 0;
        }

        // Apply global energy decay and check aliveness (can be triggered by keeper/oracle)
        _applyEnergyDecay(_tokenId);
        
        entity.lastActionTime = block.timestamp;
        _evolutionHistory[_tokenId].push(block.timestamp); // Record evolution attempt

        emit EntityEvolutionAttempt(_tokenId, success, entity.intelligence, entity.resilience, entity.adaptability);
    }

    /// @notice Allows two EEs to interact, potentially leading to mutual attribute boosts or new "affinity traits" for both.
    /// @param _tokenIdA The ID of the first EE.
    /// @param _tokenIdB The ID of the second EE.
    /// @dev Both EEs must be owned or approved by the caller. Costs energy from both.
    function initiateSynergy(uint256 _tokenIdA, uint256 _tokenIdB) public entityExists(_tokenIdA) entityExists(_tokenIdB) {
        require(_tokenIdA != _tokenIdB, "Cannot initiate synergy with itself");
        require(_isApprovedOrOwner(msg.sender, _tokenIdA), "Caller is not owner or approved for Entity A");
        require(_isApprovedOrOwner(msg.sender, _tokenIdB), "Caller is not owner or approved for Entity B");

        ElysianEntity storage entityA = _entities[_tokenIdA];
        ElysianEntity storage entityB = _entities[_tokenIdB];

        require(entityA.isAlive && entityB.isAlive, "Both entities must be alive for synergy");
        require(entityA.energy >= 30 && entityB.energy >= 30, "Not enough energy for synergy (requires 30 each)");

        entityA.energy -= 30;
        entityB.energy -= 30;

        bool success = (uint256(keccak256(abi.encodePacked(block.timestamp, _tokenIdA, _tokenIdB))) % 100) < 70; // 70% chance of success
        if (success) {
            // Apply minor boosts to both entities
            entityA.intelligence += 1; entityA.resilience += 1;
            entityB.intelligence += 1; entityB.adaptability += 1;
            
            // Add a new affinity trait (example: trait 1 for synergy)
            _addAffinityTrait(entityA, 1);
            _addAffinityTrait(entityB, 1);

            _reputationScores[_eeOwners[_tokenIdA]] += REPUTATION_PER_SYNERGY;
            _reputationScores[_eeOwners[_tokenIdB]] += REPUTATION_PER_SYNERGY;
        }

        _applyEnergyDecay(_tokenIdA);
        _applyEnergyDecay(_tokenIdB);

        entityA.lastActionTime = block.timestamp;
        entityB.lastActionTime = block.timestamp;

        emit EntitySynergyInitiated(_tokenIdA, _tokenIdB, success);
    }

    /// @notice Provides a historical record of an EE's past evolution events.
    /// @param _tokenId The ID of the EE.
    /// @return An array of timestamps or event IDs corresponding to evolution events.
    function getEvolutionHistory(uint256 _tokenId) public view entityExists(_tokenId) returns (uint256[] memory) {
        return _evolutionHistory[_tokenId];
    }

    /// @notice Internal helper to apply energy decay and check aliveness.
    function _applyEnergyDecay(uint256 _tokenId) internal {
        ElysianEntity storage entity = _entities[_tokenId];
        if (!entity.isAlive) return;

        uint256 timeSinceLastAction = block.timestamp - entity.lastActionTime;
        uint256 decayAmount = timeSinceLastAction * globalEnergyDecayRate; // Simplified decay

        if (entity.energy <= decayAmount) {
            entity.energy = 0;
            entity.isAlive = false; // Entity dies if energy drops to 0
        } else {
            entity.energy -= decayAmount;
        }
    }

    /// @notice Internal helper to add an affinity trait, avoiding duplicates.
    function _addAffinityTrait(ElysianEntity storage entity, uint256 traitId) internal {
        bool found = false;
        for (uint256 i = 0; i < entity.affinityTraits.length; i++) {
            if (entity.affinityTraits[i] == traitId) {
                found = true;
                break;
            }
        }
        if (!found) {
            entity.affinityTraits.push(traitId);
        }
    }

    // =========================================================================
    // III. Oracle & Environmental Data
    // =========================================================================

    /// @notice Allows the contract deployer (or governance) to update the trusted oracle address.
    /// @param _newOracle The address of the new oracle.
    function setOracleAddress(address _newOracle) public onlyDeployer {
        require(_newOracle != address(0), "Oracle address cannot be zero");
        emit OracleAddressUpdated(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    /// @notice A placeholder function that would signal an off-chain oracle to fetch and update global environmental factors within the contract.
    /// @dev This function would typically emit an event that an off-chain service listens to.
    function requestEnvironmentalFactors() public {
        // In a real-world scenario, this would trigger an off-chain oracle service.
        // For this example, it's a no-op that just allows anyone to signal a request.
        // A more robust system would involve a Chainlink Keepers or similar solution.
    }

    /// @notice Callable only by the authorized oracle to update global parameters that universally affect EE behavior and evolution.
    /// @param _globalEnergyDecayRate The new global energy decay rate.
    /// @param _mutationChance The new global mutation chance (0-10000).
    function updateEnvironmentalFactors(uint256 _globalEnergyDecayRate, uint256 _mutationChance) public onlyOracle {
        globalEnergyDecayRate = _globalEnergyDecayRate;
        mutationChance = _mutationChance;
        emit EnvironmentalFactorsUpdated(globalEnergyDecayRate, mutationChance);
    }

    /// @notice A placeholder signalling the oracle to fetch AI-driven attribute recommendations for a specific EE.
    /// @param _tokenId The ID of the EE for which to request recommendations.
    /// @dev Similar to `requestEnvironmentalFactors`, this signals an off-chain service.
    function requestAIAttributeRecommendation(uint256 _tokenId) public entityExists(_tokenId) {
        // Signals an off-chain AI service to analyze _tokenId's state and provide recommendations.
    }

    /// @notice Callable only by the oracle to apply AI-recommended attribute changes to an EE.
    /// @param _tokenId The ID of the EE.
    /// @param _newIntelligence The AI-recommended new intelligence value.
    /// @param _newResilience The AI-recommended new resilience value.
    /// @dev Only the oracle can call this to update attributes based on off-chain AI.
    function applyAIAttributeRecommendation(uint256 _tokenId, uint256 _newIntelligence, uint256 _newResilience) public onlyOracle entityExists(_tokenId) {
        ElysianEntity storage entity = _entities[_tokenId];
        require(entity.isAlive, "Entity is not alive");
        
        // Apply AI recommendations, potentially with bounds
        entity.intelligence = _newIntelligence;
        entity.resilience = _newResilience;
        // AI might also recommend other attributes or changes
        
        emit AIAttributeRecommendationApplied(_tokenId, _newIntelligence, _newResilience);
    }

    /// @notice Retrieves the current global environmental parameters.
    /// @return currentGlobalEnergyDecayRate, currentMutationChance
    function getGlobalParameters() public view returns (uint256, uint256) {
        return (globalEnergyDecayRate, mutationChance);
    }

    // =========================================================================
    // IV. Governance Module
    // =========================================================================

    /// @notice Users stake their GEN tokens to gain voting power for governance proposals.
    /// @param _amount The amount of GEN to stake.
    function stakeForGovernance(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than zero");
        _transfer(msg.sender, address(this), _amount); // Transfer GEN to contract
        _stakedGovernanceTokens[msg.sender] += _amount;
        _totalStakedGovernanceTokens += _amount;
        emit StakedForGovernance(msg.sender, _amount);
    }

    /// @notice Allows users to withdraw their staked GEN tokens after a cooldown period.
    /// @param _amount The amount of GEN to unstake.
    function unstakeFromGovernance(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than zero");
        require(_stakedGovernanceTokens[msg.sender] >= _amount, "Insufficient staked tokens");
        require(_unstakeCooldowns[msg.sender] <= block.timestamp, "Unstake cooldown in effect");

        _stakedGovernanceTokens[msg.sender] -= _amount;
        _totalStakedGovernanceTokens -= _amount;
        _transfer(address(this), msg.sender, _amount); // Transfer GEN from contract
        _unstakeCooldowns[msg.sender] = block.timestamp + UNSTAKE_COOLDOWN; // Reset cooldown

        emit UnstakedFromGovernance(msg.sender, _amount);
    }

    /// @notice Proposes a change to the contract's parameters or execute arbitrary calls.
    ///         Requires staked GENESIS to prevent spam.
    /// @param _description A description of the proposal.
    /// @param _target The address of the contract to call (can be this contract).
    /// @param _value The Ether value to send with the call.
    /// @param _calldata The calldata for the target function.
    function proposeParameterChange(string memory _description, address _target, uint256 _value, bytes memory _calldata) public {
        require(_stakedGovernanceTokens[msg.sender] >= MIN_STAKE_FOR_PROPOSAL, "Not enough staked GENESIS to propose");
        
        proposals.push(Proposal({
            description: _description,
            target: _target,
            value: _value,
            calldataBytes: _calldata,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + VOTING_PERIOD_DURATION,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            executed: false
        }));
        emit ProposalCreated(proposals.length - 1, msg.sender, _description, block.timestamp + VOTING_PERIOD_DURATION);
    }

    /// @notice Staked GEN holders cast their vote (for or against) on an active proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'for', false for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.votingPeriodEnd, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(_stakedGovernanceTokens[msg.sender] > 0, "Must stake GENESIS to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += _stakedGovernanceTokens[msg.sender];
        } else {
            proposal.votesAgainst += _stakedGovernanceTokens[msg.sender];
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a proposal that has reached the required quorum, majority vote, and whose voting period has ended.
    /// @param _proposalId The ID of the proposal.
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp > proposal.votingPeriodEnd, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredQuorum = (_totalStakedGovernanceTokens * QUORUM_PERCENTAGE) / 100;

        require(totalVotes >= requiredQuorum, "Proposal did not reach quorum");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass majority vote");

        proposal.executed = true;
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.calldataBytes);
        require(success, "Proposal execution failed");
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Retrieves comprehensive information about a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    function getProposalDetails(uint256 _proposalId) public view returns (
        string memory description,
        address target,
        uint256 value,
        bytes memory calldataBytes,
        uint256 creationTime,
        uint256 votingPeriodEnd,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        return (
            proposal.description,
            proposal.target,
            proposal.value,
            proposal.calldataBytes,
            proposal.creationTime,
            proposal.votingPeriodEnd,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed
        );
    }

    /// @notice Callable only via governance proposal execution, this function allows the DAO to define new, named evolutionary paths or specific trait boosts that EEs can subsequently attempt to follow.
    /// @param _pathId The ID for the new evolution path.
    /// @param _energyCost The energy required to follow this path.
    /// @param _intelligenceBoost Intelligence gain.
    /// @param _resilienceBoost Resilience gain.
    /// @param _adaptabilityBoost Adaptability gain.
    /// @dev This function can only be called by the contract itself via a successful governance proposal.
    function setEvolutionPath(uint256 _pathId, uint256 _energyCost, uint256 _intelligenceBoost, uint256 _resilienceBoost, uint256 _adaptabilityBoost) public {
        // Ensure this is called by the contract itself through governance execution
        require(msg.sender == address(this), "This function can only be called by governance");
        
        evolutionPaths[_pathId] = EvolutionPath({
            energyCost: _energyCost,
            intelligenceBoost: _intelligenceBoost,
            resilienceBoost: _resilienceBoost,
            adaptabilityBoost: _adaptabilityBoost,
            isActive: true
        });
        _nextEvolutionPathId = _pathId + 1; // Increment for next potential path ID
        emit EvolutionPathSet(_pathId, _energyCost, _intelligenceBoost, _resilienceBoost, _adaptabilityBoost);
    }

    /// @notice Retrieves details about a specific defined evolutionary path.
    /// @param _pathId The ID of the evolution path.
    function getEvolutionPathDetails(uint256 _pathId) public view returns (uint256 energyCost, uint256 intelligenceBoost, uint256 resilienceBoost, uint256 adaptabilityBoost, bool isActive) {
        EvolutionPath storage path = evolutionPaths[_pathId];
        return (path.energyCost, path.intelligenceBoost, path.resilienceBoost, path.adaptabilityBoost, path.isActive);
    }

    // =========================================================================
    // V. Reputation System
    // =========================================================================

    /// @notice Allows users to claim accumulated reputation points, typically earned from their EEs successfully evolving or engaging in synergy.
    /// @dev Reputation is automatically increased when EEs evolve or synergize. This function allows for 'claiming' or updating.
    function claimReputationReward() public {
        // Reputation is directly updated in _reputationScores map when events occur.
        // This function could be expanded to include other claimable rewards,
        // but for now it's a simple way to acknowledge the score.
        // No tokens are transferred here, just acknowledging the score.
        // In a more complex system, this might trigger a reward distribution.
        require(_reputationScores[msg.sender] > 0, "No reputation to claim or acknowledge.");
        emit ReputationClaimed(msg.sender, _reputationScores[msg.sender]);
    }

    /// @notice Retrieves the current reputation score for a specific user address.
    /// @param _user The address to query the reputation score for.
    function getReputationScore(address _user) public view returns (uint256) {
        return _reputationScores[_user];
    }


    // =========================================================================
    // Internal/Helper Functions (mostly for tokenURI & base64 encoding)
    // =========================================================================

    // Helper to convert uint256 to string for tokenURI
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

    // Helper for dynamic background color based on energy
    function _getBackgroundColor(uint256 energy) internal pure returns (string memory) {
        if (energy >= 150) return "28a745"; // Green for high energy
        if (energy >= 75) return "ffc107"; // Yellow for medium energy
        return "dc3545"; // Red for low energy
    }

    // Base64 encoding for tokenURI (simplified, no padding)
    string private constant _base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function _encodeBase64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        bytes memory encoded = new bytes(encodedLen);

        uint256 i = 0;
        uint256 j = 0;
        while (i < data.length) {
            uint8 b1 = data[i];
            uint8 b2 = i + 1 < data.length ? data[i + 1] : 0;
            uint8 b3 = i + 2 < data.length ? data[i + 2] : 0;

            uint256 enc1 = b1 >> 2;
            uint256 enc2 = ((b1 & 0x03) << 4) | (b2 >> 4);
            uint256 enc3 = ((b2 & 0x0F) << 2) | (b3 >> 6);
            uint256 enc4 = b3 & 0x3F;

            encoded[j] = bytes1(_base64Chars[enc1]);
            encoded[j + 1] = bytes1(_base64Chars[enc2]);
            encoded[j + 2] = bytes1(_base64Chars[enc3]);
            encoded[j + 3] = bytes1(_base64Chars[enc4]);

            i += 3;
            j += 4;
        }

        // Handle padding manually for simplicity for this example,
        // a full Base64 implementation handles it rigorously.
        if (data.length % 3 == 1) {
            encoded[encodedLen - 2] = "=";
            encoded[encodedLen - 1] = "=";
        } else if (data.length % 3 == 2) {
            encoded[encodedLen - 1] = "=";
        }

        return string(encoded);
    }
}


// Minimal IERC721Receiver for safeTransferFrom
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
```