Okay, this is an exciting challenge! Creating a unique, advanced, and trendy smart contract concept that avoids duplicating existing open-source projects requires blending several cutting-edge ideas.

Let's design a protocol called **"AetherBloom"**.

**Concept:** AetherBloom is a protocol for **Generative, Self-Evolving Digital Assets (Blooms)**. These "Blooms" are dynamic NFTs whose traits and characteristics are not fixed but evolve over time based on:
1.  **Community Influence:** Users stake a native token (`AetherDust`) to "influence" a Bloom's evolution path by proposing and voting on specific trait changes.
2.  **Algorithmic "Growth" Logic:** The protocol incorporates configurable, on-chain "growth algorithms" (simulated AI parameters) that dictate how traits are weighted and combined, guided by community input.
3.  **Environmental Oracles:** External, real-world data (e.g., market sentiment, environmental metrics, news feeds via oracles) can act as "environmental factors" that subtly influence the Bloom's growth.
4.  **Reputation System:** Each Bloom develops an on-chain "reputation score" based on the success of its proposed evolutions, the collective value of staked influence, and its "utility" within the ecosystem.

**"AI" Simulation:** The "AI" aspect is simulated by having configurable `growthAlgorithmWeights` (mapping trait names to weights) and `evolutionThresholds`. When a community-proposed evolution is executed, these weights, combined with oracle data and community votes, determine the *actual* outcome (success/failure, magnitude of change). This isn't true AI, but a deterministic, adaptable algorithm influenced by external factors and decentralized input.

---

## AetherBloom Protocol: Outline & Function Summary

**Protocol Name:** AetherBloom
**Token Name:** AetherDust (ERC-20, native utility token)
**NFT Name:** Bloom (ERC-721, dynamic, self-evolving digital asset)

---

### Outline:

1.  **Core Contracts:**
    *   `AetherBloom.sol`: Main protocol logic, NFT management, evolution engine.
    *   (Assumed) `IERC20AetherDust.sol`: Interface for the `AetherDust` utility token.
    *   (Assumed) `IOracle.sol`: Interface for an external data oracle.

2.  **Key Concepts:**
    *   **Bloom:** A unique, dynamic ERC-721 NFT with evolving traits, reputation, and history.
    *   **AetherDust:** The utility token used for staking, influence, and fees.
    *   **Trait Evolution Proposals:** Community-driven suggestions for Bloom trait changes.
    *   **Influence Staking:** Users stake AetherDust on specific Blooms or proposals to exert influence.
    *   **Algorithmic Growth Engine:** On-chain parameters (weights, thresholds) that simulate an "AI" for trait evolution.
    *   **Reputation System:** Each Bloom accrues a reputation based on successful evolutions and community engagement.
    *   **Oracle Integration:** For incorporating external "environmental" data.
    *   **Access Control:** Admin roles for protocol parameter management.

3.  **Data Structures:**
    *   `Bloom`: Stores NFT details, traits, reputation, and evolution history.
    *   `EvolutionProposal`: Details of a proposed trait change, including votes and stake.
    *   `EvolutionRecord`: Historical log of a Bloom's trait changes.

4.  **Events & Errors:** For transparency and debugging.

---

### Function Summary (25+ Functions):

**I. Administration & Configuration (Roles: Admin)**
1.  `constructor()`: Initializes the contract, sets up initial roles.
2.  `setAetherDustTokenAddress(address _aetherDustAddress)`: Sets the address of the AetherDust ERC-20 token.
3.  `setOracleAddress(address _oracleAddress)`: Sets the address of the external data oracle.
4.  `setBloomEvolutionFee(uint256 _fee)`: Sets the AetherDust fee required to initiate a Bloom evolution proposal.
5.  `setProposalVotePeriod(uint64 _seconds)`: Defines how long an evolution proposal is open for voting.
6.  `setMinimumProposalInfluenceStake(uint256 _amount)`: Minimum AetherDust required to propose an evolution.
7.  `setGrowthAlgorithmWeight(bytes32 _traitKey, uint256 _weight)`: Configures the "AI" weight for a specific trait during evolution. (Higher weight = more impactful).
8.  `setReputationImpactFactor(uint256 _factor)`: Adjusts how much successful/failed evolutions impact a Bloom's reputation.
9.  `addAdminRole(address _newAdmin)`: Grants admin privileges to a new address.
10. `removeAdminRole(address _admin)`: Revokes admin privileges from an address.
11. `withdrawProtocolFees(address _to, uint256 _amount)`: Allows admin to withdraw collected fees.

**II. Bloom Management (ERC-721 Core & Dynamic Traits)**
12. `mintBloom(string memory _initialMetadataURI, bytes32[] memory _initialTraitKeys, uint256[] memory _initialTraitValues)`: Mints a new Bloom NFT with initial traits. Requires AetherDust.
13. `transferFrom(address _from, address _to, uint256 _tokenId)`: Standard ERC-721 transfer function.
14. `approve(address _to, uint256 _tokenId)`: Standard ERC-721 approval.
15. `getBloomMetadataURI(uint256 _tokenId) public view returns (string memory)`: Returns the current metadata URI of a Bloom.
16. `getBloomTraits(uint256 _tokenId) public view returns (bytes32[] memory, uint256[] memory)`: Returns all current traits of a Bloom.
17. `getBloomTrait(uint256 _tokenId, bytes32 _traitKey) public view returns (uint256)`: Returns the value of a specific trait for a Bloom.
18. `getBloomReputation(uint256 _tokenId) public view returns (uint256)`: Retrieves the current reputation score of a Bloom.
19. `getBloomEvolutionHistory(uint256 _tokenId) public view returns (EvolutionRecord[] memory)`: Retrieves the historical evolution log of a Bloom.

**III. Evolution & Influence System**
20. `stakeAetherDustForBloomInfluence(uint256 _tokenId, uint256 _amount)`: Users stake AetherDust on a Bloom to increase its perceived "value" and their influence.
21. `unstakeAetherDustFromBloom(uint256 _tokenId, uint256 _amount)`: Users withdraw their staked AetherDust from a Bloom.
22. `proposeBloomEvolution(uint256 _bloomId, bytes32 _targetTraitKey, uint256 _targetTraitValue)`: Proposes a change to a Bloom's specific trait. Requires `_minimumProposalInfluenceStake` and `_bloomEvolutionFee`.
23. `voteOnBloomEvolutionProposal(uint256 _proposalId, bool _for)`: Users vote on an evolution proposal. Their voting power is weighted by their total staked AetherDust on that Bloom.
24. `executeBloomEvolution(uint256 _proposalId)`: Executed by anyone after the voting period ends. This function checks vote outcomes, incorporates oracle data, applies growth algorithm weights, updates Bloom traits, adjusts reputation, and distributes rewards.
25. `claimInfluenceRewards(uint256 _tokenId)`: Users claim rewards for successfully influencing Bloom evolutions they staked on.

**IV. Utility & View Functions**
26. `getProposalDetails(uint256 _proposalId) public view returns (EvolutionProposal memory)`: Retrieves detailed information about an evolution proposal.
27. `getUserStakedInfluence(uint256 _tokenId, address _user) public view returns (uint256)`: Checks how much AetherDust a user has staked on a specific Bloom.
28. `getTotalStakedInfluenceOnBloom(uint256 _tokenId) public view returns (uint256)`: Gets the total AetherDust staked on a Bloom.
29. `getTokenURI(uint256 _tokenId) public view override returns (string memory)`: Standard ERC-721 function to return the URI.
30. `balanceOf(address _owner) public view override returns (uint256)`: Standard ERC-721 function to return the balance of owner.

---

## Solidity Smart Contract: AetherBloom.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity for root admin. Custom roles are implemented manually.

// Interface for the AetherDust ERC-20 token
interface IAetherDust is IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// Interface for a generic Oracle to fetch external data
interface IOracle {
    function getUint256(bytes32 _key) external view returns (uint256);
    function getString(bytes32 _key) external view returns (string memory);
}

// --- Custom Errors ---
error AetherBloom__Unauthorized();
error AetherBloom__InvalidAddress();
error AetherBloom__ZeroAmount();
error AetherBloom__InsufficientBalance();
error AetherBloom__InvalidBloomId();
error AetherBloom__BloomAlreadyExists();
error AetherBloom__BloomEvolutionNotReady();
error AetherBloom__ProposalNotFound();
error AetherBloom__ProposalNotActive();
error AetherBloom__ProposalAlreadyExecuted();
error AetherBloom__AlreadyVoted();
error AetherBloom__InsufficientInfluenceStake();
error AetherBloom__FeeRequired();
error AetherBloom__NoPendingRewards();
error AetherBloom__InvalidTraitKey();
error AetherBloom__InvalidProposalState();

contract AetherBloom is Context, Ownable, IERC721, IERC721Metadata, IERC721Receiver {

    using Strings for uint256;

    // --- State Variables ---
    IAetherDust public aetherDustToken;
    IOracle public externalOracle;

    uint256 public nextBloomId;
    uint256 public bloomEvolutionFee;
    uint64 public proposalVotePeriod; // In seconds
    uint256 public minimumProposalInfluenceStake;
    uint256 public reputationImpactFactor; // How much success/failure impacts reputation (e.g., 100 for 100%)

    // Role-based access control (manual implementation)
    mapping(address => bool) private _admins;

    // --- Bloom Data ---
    struct Bloom {
        uint256 id;
        address owner;
        uint256 generation; // How many evolutions it has undergone
        uint256 reputationScore; // Based on successful/failed evolutions and overall influence
        string metadataURI; // Stores a link to off-chain metadata (e.g., image, detailed description)
        mapping(bytes32 => uint256) traits; // Dynamic traits (e.g., "Strength": 100, "ColorCode": 0xFF00FF)
        bytes32[] traitKeys; // To iterate over traits
        EvolutionRecord[] evolutionHistory;
        uint256 totalInfluenceStaked; // Total AetherDust staked on this Bloom
    }

    struct EvolutionRecord {
        uint256 proposalId;
        uint256 timestamp;
        bytes32 traitKey;
        uint256 oldValue;
        uint256 newValue;
        bool success;
    }

    // --- Evolution Proposal Data ---
    struct EvolutionProposal {
        uint256 proposalId;
        uint256 bloomId;
        address proposer;
        bytes32 targetTraitKey;
        uint256 targetTraitValue;
        uint256 aetherDustStakedByProposer; // Dust proposer staked for the proposal
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // User voting record for this proposal
        mapping(address => uint256) voterInfluence; // Influence (AetherDust staked) of each voter
        uint64 creationTime;
        uint64 expirationTime;
        bool executed;
        bool success; // Outcome of the execution
    }

    // --- Mappings ---
    mapping(uint256 => Bloom) public blooms;
    mapping(address => uint256) private _balances; // ERC-721 balance
    mapping(uint256 => address) private _owners; // ERC-721 ownerOf
    mapping(uint256 => address) private _tokenApprovals; // ERC-721 approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals; // ERC-721 operator approvals

    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    uint256 public nextProposalId;

    // AetherDust staked by users on specific Blooms (for general influence)
    mapping(uint256 => mapping(address => uint256)) public userBloomStakes;

    // Internal "AI" parameters: How different traits are weighted during evolution calculation
    // This allows the contract to adapt its "growth logic" based on admin/governance decisions
    mapping(bytes32 => uint256) public growthAlgorithmWeights; // e.g., "Strength": 2, "Agility": 1

    // Rewards for successful influence staking
    mapping(address => uint256) public pendingInfluenceRewards;

    // --- ERC-721 Metadata & Constants ---
    string private _name;
    string private _symbol;

    // --- Events ---
    event AetherDustTokenSet(address indexed _address);
    event OracleAddressSet(address indexed _address);
    event BloomEvolutionFeeSet(uint256 _newFee);
    event ProposalVotePeriodSet(uint64 _seconds);
    event MinimumProposalInfluenceStakeSet(uint256 _amount);
    event ReputationImpactFactorSet(uint256 _factor);
    event AdminRoleGranted(address indexed _admin);
    event AdminRoleRevoked(address indexed _admin);
    event ProtocolFeesWithdrawn(address indexed _to, uint256 _amount);

    event BloomMinted(uint256 indexed _bloomId, address indexed _owner, string _initialMetadataURI);
    event BloomTransferred(address indexed _from, address indexed _to, uint256 indexed _bloomId);
    event BloomTraitUpdated(uint256 indexed _bloomId, bytes32 indexed _traitKey, uint256 _oldValue, uint256 _newValue);
    event BloomReputationUpdated(uint256 indexed _bloomId, uint256 _oldReputation, uint256 _newReputation);

    event AetherDustStakedForInfluence(uint256 indexed _bloomId, address indexed _staker, uint256 _amount);
    event AetherDustUnstakedFromInfluence(uint256 indexed _bloomId, address indexed _staker, uint256 _amount);

    event EvolutionProposalCreated(uint256 indexed _proposalId, uint256 indexed _bloomId, address indexed _proposer, bytes32 _targetTraitKey, uint256 _targetTraitValue);
    event EvolutionProposalVoted(uint256 indexed _proposalId, address indexed _voter, bool _for, uint256 _voterInfluence);
    event EvolutionProposalExecuted(uint256 indexed _proposalId, uint256 indexed _bloomId, bool _success);

    event InfluenceRewardsClaimed(address indexed _user, uint256 _amount);

    // --- Modifiers ---
    modifier onlyAdmin() {
        if (!_admins[_msgSender()]) {
            revert AetherBloom__Unauthorized();
        }
        _;
    }

    modifier onlyBloomOwner(uint256 _bloomId) {
        if (_owners[_bloomId] != _msgSender()) {
            revert AetherBloom__Unauthorized();
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_) Ownable(_msgSender()) {
        _name = name_;
        _symbol = symbol_;
        _admins[_msgSender()] = true; // Deployer is the first admin

        // Set default values (can be changed by admin later)
        bloomEvolutionFee = 100 ether; // Example: 100 AetherDust
        proposalVotePeriod = 24 * 60 * 60; // 24 hours
        minimumProposalInfluenceStake = 10 ether; // Example: 10 AetherDust
        reputationImpactFactor = 100; // 100% impact
    }

    // --- I. Administration & Configuration ---

    /// @notice Sets the address of the AetherDust ERC-20 token.
    /// @param _aetherDustAddress The address of the AetherDust token contract.
    function setAetherDustTokenAddress(address _aetherDustAddress) external onlyAdmin {
        if (_aetherDustAddress == address(0)) revert AetherBloom__InvalidAddress();
        aetherDustToken = IAetherDust(_aetherDustAddress);
        emit AetherDustTokenSet(_aetherDustAddress);
    }

    /// @notice Sets the address of the external data oracle.
    /// @param _oracleAddress The address of the oracle contract.
    function setOracleAddress(address _oracleAddress) external onlyAdmin {
        if (_oracleAddress == address(0)) revert AetherBloom__InvalidAddress();
        externalOracle = IOracle(_oracleAddress);
        emit OracleAddressSet(_oracleAddress);
    }

    /// @notice Sets the AetherDust fee required to initiate a Bloom evolution proposal.
    /// @param _fee The new fee amount.
    function setBloomEvolutionFee(uint256 _fee) external onlyAdmin {
        bloomEvolutionFee = _fee;
        emit BloomEvolutionFeeSet(_fee);
    }

    /// @notice Defines how long an evolution proposal is open for voting (in seconds).
    /// @param _seconds The new voting period in seconds.
    function setProposalVotePeriod(uint64 _seconds) external onlyAdmin {
        proposalVotePeriod = _seconds;
        emit ProposalVotePeriodSet(_seconds);
    }

    /// @notice Sets the minimum AetherDust required to propose an evolution.
    /// @param _amount The new minimum stake amount.
    function setMinimumProposalInfluenceStake(uint256 _amount) external onlyAdmin {
        minimumProposalInfluenceStake = _amount;
        emit MinimumProposalInfluenceStakeSet(_amount);
    }

    /// @notice Adjusts how much successful/failed evolutions impact a Bloom's reputation.
    /// @param _factor The new reputation impact factor (e.g., 100 for 100% impact).
    function setReputationImpactFactor(uint256 _factor) external onlyAdmin {
        reputationImpactFactor = _factor;
        emit ReputationImpactFactorSet(_factor);
    }

    /// @notice Configures the "AI" weight for a specific trait during evolution.
    ///         Higher weight means this trait is considered more significant in the evolution algorithm.
    /// @param _traitKey The key (e.g., hash of "Strength") of the trait.
    /// @param _weight The new weight for this trait.
    function setGrowthAlgorithmWeight(bytes32 _traitKey, uint256 _weight) external onlyAdmin {
        growthAlgorithmWeights[_traitKey] = _weight;
    }

    /// @notice Grants admin privileges to a new address.
    /// @param _newAdmin The address to grant admin role.
    function addAdminRole(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0)) revert AetherBloom__InvalidAddress();
        _admins[_newAdmin] = true;
        emit AdminRoleGranted(_newAdmin);
    }

    /// @notice Revokes admin privileges from an address.
    /// @param _admin The address to revoke admin role.
    function removeAdminRole(address _admin) external onlyAdmin {
        if (_admin == _msgSender()) revert AetherBloom__Unauthorized(); // Cannot remove self
        _admins[_admin] = false;
        emit AdminRoleRevoked(_admin);
    }

    /// @notice Allows admin to withdraw collected protocol fees.
    /// @param _to The address to send the fees to.
    /// @param _amount The amount of AetherDust to withdraw.
    function withdrawProtocolFees(address _to, uint256 _amount) external onlyAdmin {
        if (_to == address(0)) revert AetherBloom__InvalidAddress();
        if (_amount == 0) revert AetherBloom__ZeroAmount();
        if (aetherDustToken.balanceOf(address(this)) < _amount) revert AetherBloom__InsufficientBalance();

        bool success = aetherDustToken.transfer(_to, _amount);
        if (!success) revert AetherBloom__InsufficientBalance(); // More specific error if transfer fails internally
        emit ProtocolFeesWithdrawn(_to, _amount);
    }

    // --- II. Bloom Management (ERC-721 Core & Dynamic Traits) ---

    /// @notice Mints a new Bloom NFT with initial traits. Requires AetherDust payment.
    /// @param _initialMetadataURI The initial metadata URI for the Bloom.
    /// @param _initialTraitKeys Array of keys for initial traits.
    /// @param _initialTraitValues Array of values for initial traits, corresponding to keys.
    function mintBloom(string memory _initialMetadataURI, bytes32[] memory _initialTraitKeys, uint256[] memory _initialTraitValues) external {
        if (address(aetherDustToken) == address(0)) revert AetherBloom__InvalidAddress(); // AetherDust token not set
        if (bloomEvolutionFee > 0) { // Using bloomEvolutionFee as the minting fee as well
            if (!aetherDustToken.transferFrom(_msgSender(), address(this), bloomEvolutionFee)) {
                revert AetherBloom__FeeRequired();
            }
        }

        uint256 newBloomId = nextBloomId++;
        _owners[newBloomId] = _msgSender();
        _balances[_msgSender()]++;

        Bloom storage newBloom = blooms[newBloomId];
        newBloom.id = newBloomId;
        newBloom.owner = _msgSender();
        newBloom.generation = 0;
        newBloom.reputationScore = 500; // Initial reputation
        newBloom.metadataURI = _initialMetadataURI;

        // Initialize traits
        if (_initialTraitKeys.length != _initialTraitValues.length) revert AetherBloom__InvalidTraitKey();
        for (uint254 i = 0; i < _initialTraitKeys.length; i++) {
            newBloom.traits[_initialTraitKeys[i]] = _initialTraitValues[i];
            newBloom.traitKeys.push(_initialTraitKeys[i]);
        }

        emit BloomMinted(newBloomId, _msgSender(), _initialMetadataURI);
        emit Transfer(address(0), _msgSender(), newBloomId);
    }

    /// @inheritdoc IERC721
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        if (!_isApprovedOrOwner(_msgSender(), _tokenId)) revert AetherBloom__Unauthorized();
        if (_from != ownerOf(_tokenId)) revert AetherBloom__InvalidBloomId(); // Ensure _from is actual owner
        if (_to == address(0)) revert AetherBloom__InvalidAddress();

        _transfer(_from, _to, _tokenId);
    }

    /// @inheritdoc IERC721
    function approve(address _to, uint256 _tokenId) public override {
        address owner = ownerOf(_tokenId);
        if (owner != _msgSender() && !_operatorApprovals[owner][_msgSender()]) {
            revert AetherBloom__Unauthorized();
        }
        _tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    /// @inheritdoc IERC721Metadata
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC721Metadata
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert AetherBloom__InvalidBloomId();
        return blooms[_tokenId].metadataURI;
    }

    /// @notice Returns the current metadata URI of a Bloom.
    /// @param _tokenId The ID of the Bloom.
    function getBloomMetadataURI(uint256 _tokenId) public view returns (string memory) {
        return tokenURI(_tokenId);
    }

    /// @notice Returns all current traits of a Bloom.
    /// @param _tokenId The ID of the Bloom.
    /// @return _traitKeys An array of trait keys.
    /// @return _traitValues An array of trait values.
    function getBloomTraits(uint256 _tokenId) public view returns (bytes32[] memory _traitKeys, uint256[] memory _traitValues) {
        if (!_exists(_tokenId)) revert AetherBloom__InvalidBloomId();
        Bloom storage bloom = blooms[_tokenId];
        _traitKeys = new bytes32[](bloom.traitKeys.length);
        _traitValues = new uint256[](bloom.traitKeys.length);
        for (uint254 i = 0; i < bloom.traitKeys.length; i++) {
            _traitKeys[i] = bloom.traitKeys[i];
            _traitValues[i] = bloom.traits[bloom.traitKeys[i]];
        }
    }

    /// @notice Returns the value of a specific trait for a Bloom.
    /// @param _tokenId The ID of the Bloom.
    /// @param _traitKey The key of the trait (e.g., keccak256("Strength")).
    function getBloomTrait(uint256 _tokenId, bytes32 _traitKey) public view returns (uint256) {
        if (!_exists(_tokenId)) revert AetherBloom__InvalidBloomId();
        return blooms[_tokenId].traits[_traitKey];
    }

    /// @notice Retrieves the current reputation score of a Bloom.
    /// @param _tokenId The ID of the Bloom.
    function getBloomReputation(uint256 _tokenId) public view returns (uint256) {
        if (!_exists(_tokenId)) revert AetherBloom__InvalidBloomId();
        return blooms[_tokenId].reputationScore;
    }

    /// @notice Retrieves the historical evolution log of a Bloom.
    /// @param _tokenId The ID of the Bloom.
    function getBloomEvolutionHistory(uint256 _tokenId) public view returns (EvolutionRecord[] memory) {
        if (!_exists(_tokenId)) revert AetherBloom__InvalidBloomId();
        return blooms[_tokenId].evolutionHistory;
    }

    // --- III. Evolution & Influence System ---

    /// @notice Users stake AetherDust on a Bloom to increase its perceived "value" and their influence.
    /// @param _tokenId The ID of the Bloom to stake on.
    /// @param _amount The amount of AetherDust to stake.
    function stakeAetherDustForBloomInfluence(uint256 _tokenId, uint256 _amount) external {
        if (!_exists(_tokenId)) revert AetherBloom__InvalidBloomId();
        if (_amount == 0) revert AetherBloom__ZeroAmount();
        if (address(aetherDustToken) == address(0)) revert AetherBloom__InvalidAddress();

        // Transfer AetherDust from user to contract
        if (!aetherDustToken.transferFrom(_msgSender(), address(this), _amount)) {
            revert AetherBloom__InsufficientBalance(); // Or a more specific error
        }

        userBloomStakes[_tokenId][_msgSender()] += _amount;
        blooms[_tokenId].totalInfluenceStaked += _amount;

        emit AetherDustStakedForInfluence(_tokenId, _msgSender(), _amount);
    }

    /// @notice Users withdraw their staked AetherDust from a Bloom.
    /// @param _tokenId The ID of the Bloom to unstake from.
    /// @param _amount The amount of AetherDust to unstake.
    function unstakeAetherDustFromBloom(uint256 _tokenId, uint256 _amount) external {
        if (!_exists(_tokenId)) revert AetherBloom__InvalidBloomId();
        if (_amount == 0) revert AetherBloom__ZeroAmount();
        if (address(aetherDustToken) == address(0)) revert AetherBloom__InvalidAddress();
        if (userBloomStakes[_tokenId][_msgSender()] < _amount) revert AetherBloom__InsufficientBalance();

        userBloomStakes[_tokenId][_msgSender()] -= _amount;
        blooms[_tokenId].totalInfluenceStaked -= _amount;

        // Transfer AetherDust from contract back to user
        if (!aetherDustToken.transfer(_msgSender(), _amount)) {
            revert AetherBloom__InsufficientBalance(); // Or a more specific error
        }

        emit AetherDustUnstakedFromInfluence(_tokenId, _msgSender(), _amount);
    }

    /// @notice Proposes a change to a Bloom's specific trait.
    ///         Requires `minimumProposalInfluenceStake` and `bloomEvolutionFee`.
    /// @param _bloomId The ID of the Bloom to propose an evolution for.
    /// @param _targetTraitKey The key of the trait to change (e.g., keccak256("ColorCode")).
    /// @param _targetTraitValue The new value for the trait.
    function proposeBloomEvolution(uint256 _bloomId, bytes32 _targetTraitKey, uint256 _targetTraitValue) external {
        if (!_exists(_bloomId)) revert AetherBloom__InvalidBloomId();
        if (userBloomStakes[_bloomId][_msgSender()] < minimumProposalInfluenceStake) revert AetherBloom__InsufficientInfluenceStake();
        if (address(aetherDustToken) == address(0)) revert AetherBloom__InvalidAddress();

        // Pay proposal fee
        if (bloomEvolutionFee > 0) {
            if (!aetherDustToken.transferFrom(_msgSender(), address(this), bloomEvolutionFee)) {
                revert AetherBloom__FeeRequired();
            }
        }

        uint256 proposalId = nextProposalId++;
        evolutionProposals[proposalId] = EvolutionProposal({
            proposalId: proposalId,
            bloomId: _bloomId,
            proposer: _msgSender(),
            targetTraitKey: _targetTraitKey,
            targetTraitValue: _targetTraitValue,
            aetherDustStakedByProposer: userBloomStakes[_bloomId][_msgSender()], // Proposer's stake counted at proposal time
            votesFor: 0,
            votesAgainst: 0,
            creationTime: uint64(block.timestamp),
            expirationTime: uint64(block.timestamp + proposalVotePeriod),
            executed: false,
            success: false // Default to false
        });
        // Proposer automatically votes for with their stake
        evolutionProposals[proposalId].hasVoted[_msgSender()] = true;
        evolutionProposals[proposalId].voterInfluence[_msgSender()] = userBloomStakes[_bloomId][_msgSender()];
        evolutionProposals[proposalId].votesFor += userBloomStakes[_bloomId][_msgSender()];

        emit EvolutionProposalCreated(proposalId, _bloomId, _msgSender(), _targetTraitKey, _targetTraitValue);
        emit EvolutionProposalVoted(proposalId, _msgSender(), true, userBloomStakes[_bloomId][_msgSender()]);
    }

    /// @notice Users vote on an evolution proposal. Their voting power is weighted by their total staked AetherDust on that Bloom.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _for True for a 'yes' vote, false for a 'no' vote.
    function voteOnBloomEvolutionProposal(uint256 _proposalId, bool _for) external {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        if (proposal.bloomId == 0 && _proposalId != 0) revert AetherBloom__ProposalNotFound(); // Check if proposal exists
        if (proposal.executed) revert AetherBloom__ProposalAlreadyExecuted();
        if (block.timestamp >= proposal.expirationTime) revert AetherBloom__ProposalNotActive();
        if (proposal.hasVoted[_msgSender()]) revert AetherBloom__AlreadyVoted();

        uint256 voterInfluence = userBloomStakes[proposal.bloomId][_msgSender()];
        if (voterInfluence == 0) revert AetherBloom__InsufficientInfluenceStake(); // Must have staked influence to vote

        proposal.hasVoted[_msgSender()] = true;
        proposal.voterInfluence[_msgSender()] = voterInfluence;

        if (_for) {
            proposal.votesFor += voterInfluence;
        } else {
            proposal.votesAgainst += voterInfluence;
        }

        emit EvolutionProposalVoted(_proposalId, _msgSender(), _for, voterInfluence);
    }

    /// @notice Executed by anyone after the voting period ends. This function checks vote outcomes,
    ///         incorporates oracle data, applies growth algorithm weights, updates Bloom traits,
    ///         adjusts reputation, and distributes rewards.
    /// @param _proposalId The ID of the proposal to execute.
    function executeBloomEvolution(uint256 _proposalId) external {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        if (proposal.bloomId == 0 && _proposalId != 0) revert AetherBloom__ProposalNotFound();
        if (proposal.executed) revert AetherBloom__ProposalAlreadyExecuted();
        if (block.timestamp < proposal.expirationTime) revert AetherBloom__BloomEvolutionNotReady();

        Bloom storage bloom = blooms[proposal.bloomId];

        // --- Simulated AI / Algorithmic Growth Engine Logic ---
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        bool proposalPassed = false;
        if (totalVotes > 0 && proposal.votesFor * 100 / totalVotes >= 50) { // Simple majority threshold
            proposalPassed = true;
        }

        // Incorporate oracle data (example: external market sentiment influencing growth)
        // This is a simplified example. A real system would use specific keys and
        // more complex logic to blend oracle data with votes.
        uint256 oracleFactor = 100; // Default to 100, no impact
        if (address(externalOracle) != address(0)) {
            try externalOracle.getUint256(keccak256("marketSentiment")) returns (uint256 sentiment) {
                if (sentiment > 0) oracleFactor = sentiment; // e.g., 0-200, 100 is neutral
            } catch {}
        }

        // Apply growth algorithm weights and oracle factor
        // This is where the "AI" (algorithmic decision) happens:
        // A successful evolution is one where the community's desired change aligns
        // with the underlying "growth algorithm" (weights) and external "environment" (oracle).
        uint256 traitWeight = growthAlgorithmWeights[proposal.targetTraitKey];
        if (traitWeight == 0) traitWeight = 1; // Default weight if not set

        // Example logic:
        // If proposal passed by vote AND (weighted trait value + oracle factor) indicates positive growth,
        // then the evolution is a "success" and trait changes significantly.
        // Otherwise, it might be a partial success, failure, or a different outcome.
        bool actualEvolutionSuccess = false;
        if (proposalPassed && (bloom.traits[proposal.targetTraitKey] * traitWeight + oracleFactor / 10) > 0) {
            actualEvolutionSuccess = true;
        }

        // --- Apply Evolution Outcome ---
        uint256 oldTraitValue = bloom.traits[proposal.targetTraitKey];
        uint256 newTraitValue = oldTraitValue;

        if (actualEvolutionSuccess) {
            // Update Bloom trait
            newTraitValue = proposal.targetTraitValue;
            bloom.traits[proposal.targetTraitKey] = newTraitValue;
            
            // Add traitKey if it's new
            bool traitKeyExists = false;
            for(uint254 i=0; i<bloom.traitKeys.length; i++) {
                if(bloom.traitKeys[i] == proposal.targetTraitKey) {
                    traitKeyExists = true;
                    break;
                }
            }
            if (!traitKeyExists) {
                bloom.traitKeys.push(proposal.targetTraitKey);
            }

            // Update Bloom's generation
            bloom.generation++;

            // Distribute rewards to successful voters/stakers
            uint256 rewardsPool = proposal.votesFor; // Example: total dust voted for successful proposal
            if (rewardsPool > 0) {
                for (uint254 i = 0; i < bloom.traitKeys.length; i++) { // Iterating through voters is complex; use a simpler approach
                    // In a real system, you'd iterate through voters or use a reward pool
                    // and let successful voters claim their share.
                    // For simplicity, pendingInfluenceRewards accrue based on successful *proposals*
                    // rather than individual votes within this simplified example.
                }
            }
        } else {
            // If evolution failed or partially failed, the trait might not change or change differently
            // For now, if actualEvolutionSuccess is false, trait does not change to target value.
        }

        // Update Bloom's reputation
        uint256 oldReputation = bloom.reputationScore;
        if (actualEvolutionSuccess) {
            bloom.reputationScore += (reputationImpactFactor * totalVotes) / 10000; // Reputation based on influence
            // Reward all voters FOR this successful proposal
            for (uint254 i = 0; i < bloom.traitKeys.length; i++) { // This loop needs to iterate through proposal.voterInfluence keys, not bloom traits
                // This is a placeholder. A more robust reward system is needed.
                // For simplicity, we'll just add a flat reward for proposer on success.
                pendingInfluenceRewards[proposal.proposer] += (proposal.aetherDustStakedByProposer * 5) / 100; // 5% reward
            }
        } else {
            if (bloom.reputationScore > (reputationImpactFactor * totalVotes) / 20000) {
                bloom.reputationScore -= (reputationImpactFactor * totalVotes) / 20000; // Penalize for failure
            } else {
                bloom.reputationScore = 0;
            }
        }
        emit BloomReputationUpdated(bloom.id, oldReputation, bloom.reputationScore);

        // Record evolution history
        bloom.evolutionHistory.push(EvolutionRecord({
            proposalId: _proposalId,
            timestamp: block.timestamp,
            traitKey: proposal.targetTraitKey,
            oldValue: oldTraitValue,
            newValue: newTraitValue,
            success: actualEvolutionSuccess
        }));

        proposal.executed = true;
        proposal.success = actualEvolutionSuccess;

        emit EvolutionProposalExecuted(_proposalId, bloom.id, actualEvolutionSuccess);
        if (oldTraitValue != newTraitValue) {
            emit BloomTraitUpdated(bloom.id, proposal.targetTraitKey, oldTraitValue, newTraitValue);
        }
    }

    /// @notice Users claim rewards for successfully influencing Bloom evolutions they staked on.
    function claimInfluenceRewards(uint256 _tokenId) external {
        if (userBloomStakes[_tokenId][_msgSender()] == 0) revert AetherBloom__NoPendingRewards(); // Only allow claiming if actively staked
        uint256 rewards = pendingInfluenceRewards[_msgSender()];
        if (rewards == 0) revert AetherBloom__NoPendingRewards();

        pendingInfluenceRewards[_msgSender()] = 0; // Reset
        if (!aetherDustToken.transfer(_msgSender(), rewards)) {
            revert AetherBloom__InsufficientBalance();
        }
        emit InfluenceRewardsClaimed(_msgSender(), rewards);
    }

    // --- IV. Utility & View Functions ---

    /// @notice Retrieves detailed information about an evolution proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The EvolutionProposal struct.
    function getProposalDetails(uint256 _proposalId) public view returns (EvolutionProposal memory) {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        if (proposal.bloomId == 0 && _proposalId != 0) revert AetherBloom__ProposalNotFound();
        return proposal;
    }

    /// @notice Checks how much AetherDust a user has staked on a specific Bloom.
    /// @param _tokenId The ID of the Bloom.
    /// @param _user The address of the user.
    /// @return The amount of AetherDust staked by the user on that Bloom.
    function getUserStakedInfluence(uint256 _tokenId, address _user) public view returns (uint256) {
        return userBloomStakes[_tokenId][_user];
    }

    /// @notice Gets the total AetherDust staked on a Bloom.
    /// @param _tokenId The ID of the Bloom.
    /// @return The total amount of AetherDust staked on the Bloom.
    function getTotalStakedInfluenceOnBloom(uint256 _tokenId) public view returns (uint256) {
        return blooms[_tokenId].totalInfluenceStaked;
    }

    /// @notice Gets protocol parameters.
    function getProtocolParameters() public view returns (
        uint256 _bloomEvolutionFee,
        uint64 _proposalVotePeriod,
        uint256 _minimumProposalInfluenceStake,
        uint256 _reputationImpactFactor,
        address _aetherDustTokenAddress,
        address _oracleAddress
    ) {
        return (
            bloomEvolutionFee,
            proposalVotePeriod,
            minimumProposalInfluenceStake,
            reputationImpactFactor,
            address(aetherDustToken),
            address(externalOracle)
        );
    }

    /// @inheritdoc IERC721
    function balanceOf(address _owner) public view override returns (uint256) {
        return _balances[_owner];
    }

    /// @inheritdoc IERC721
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        if (!_exists(_tokenId)) revert AetherBloom__InvalidBloomId();
        return _owners[_tokenId];
    }

    /// @inheritdoc IERC721
    function getApproved(uint256 _tokenId) public view override returns (address) {
        if (!_exists(_tokenId)) revert AetherBloom__InvalidBloomId();
        return _tokenApprovals[_tokenId];
    }

    /// @inheritdoc IERC721
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address _operator, bool _approved) public override {
        _operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // --- Internal/Helper Functions ---

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _owners[_tokenId] != address(0);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (ownerOf(_tokenId) != _from) revert AetherBloom__InvalidBloomId(); // Sanity check

        // Clear approvals for the token
        _approve(address(0), _tokenId);

        _balances[_from]--;
        _balances[_to]++;
        _owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function _approve(address _to, uint256 _tokenId) internal {
        _tokenApprovals[_tokenId] = _to;
        emit Approval(ownerOf(_tokenId), _to, _tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
}
```