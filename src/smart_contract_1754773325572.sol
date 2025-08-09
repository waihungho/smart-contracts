This smart contract, named "SynergyNexus," creates a decentralized, evolving ecosystem of "Digital Entities" (NFTs). These entities possess dynamic attributes that change based on community interaction, staked resources (a custom ERC20 "SynergyToken"), and conceptual external factors (fed by an oracle). It integrates elements of dynamic NFTs, reputation systems, gamified governance, and resource management within a creative "living digital organism" framework.

The contract aims to be **creative and trendy** by combining:
*   **Dynamic NFTs:** Entity attributes (energy, resilience, adaptability, synergyFactor) are not static but evolve.
*   **Reputation System:** Users gain reputation for positive actions (nourishing entities, voting), and entities gain reputation through nourishment and successful evolution.
*   **Gamified Governance:** Community proposals and voting influence entity evolution paths and environmental factors.
*   **Resource Allocation Sprints:** Community-driven initiatives to focus resources on specific entities or ecosystem goals.
*   **Conceptual Oracle Integration:** Simulating how external, real-world data might influence the digital ecosystem.
*   **Burn-to-Create NFT Mechanism:** New entities require burning the native SynergyToken, adding to deflationary pressure and a shared resource pool.

---

## SynergyNexus: Evolving Digital Ecosystem

### Outline & Function Summary

**I. Core Setup & Administration**
1.  **`constructor(string memory name, string memory symbol, address initialSynergyToken, address initialOracle)`**: Initializes the contract, ERC721, sets the SynergyToken, and initial oracle address.
2.  **`setSynergyTokenAddress(address _newAddress)`**: Allows the owner to update the address of the SynergyToken contract.
3.  **`setOracleAddress(address _newAddress)`**: Allows the owner to update the address of the conceptual Oracle contract.
4.  **`setBaseEntityURI(string memory _newBaseURI)`**: Allows the owner to set the base URI for Digital Entity NFT metadata.
5.  **`setGrowthParameters(uint256 _nourishmentThreshold, uint256 _evolutionCost, uint256 _reputationDecayRate)`**: Sets key parameters governing entity growth and reputation decay (Owner only).

**II. Digital Entities (NFTs - ERC721 Based)**
6.  **`createDigitalEntity(string memory _name, uint256 _burnAmount)`**: Mints a new Digital Entity NFT by burning SynergyTokens, which are added to the Synergy Pool. Initial attributes are randomized.
7.  **`evolveEntity(uint256 _tokenId)`**: Triggers the evolution of a Digital Entity if it meets nourishment criteria and the owner pays a cost. Evolution alters attributes based on external factors and adaptability.
8.  **`addTraitToEntity(uint256 _tokenId, uint256 _traitId)`**: Allows the owner (or eventually a DAO vote) to assign a specific trait to an entity.
9.  **`removeTraitFromEntity(uint256 _tokenId, uint256 _traitId)`**: Removes a trait from an entity.
10. **`getMutableEntityAttributes(uint256 _tokenId)`**: Retrieves the current dynamic attributes (energy, resilience, adaptability, synergyFactor) of an entity.
11. **`nourishEntity(uint256 _tokenId, uint256 _amount)`**: Allows users to stake SynergyTokens to a specific Digital Entity, increasing its nourishment score. Tokens are locked for a period and contribute to the Synergy Pool.
12. **`withdrawNourishment(uint256 _tokenId, uint256 _amount)`**: Allows a user to withdraw their previously staked nourishment from an entity after the lock-up period.
13. **`triggerEntitySynergy(uint256 _tokenId)`**: Allows an entity owner to trigger a "synergy effect" if the entity possesses relevant traits and sufficient energy, potentially boosting other entities or contributing to the community.
14. **`getEntityTraits(uint256 _tokenId)`**: Returns the list of trait IDs currently possessed by an entity.

**III. Reputation System**
15. **`getUserReputation(address _user)`**: Retrieves the reputation score of a given user.
16. **`getEntityReputation(uint256 _tokenId)`**: Retrieves the reputation score of a given Digital Entity.
17. **`_updateUserReputation(address _user, int256 _delta)`**: (Internal) Adjusts a user's reputation score.
18. **`_updateEntityReputation(uint256 _tokenId, int256 _delta)`**: (Internal) Adjusts an entity's reputation score.

**IV. Community & Governance (Simulated DAO elements)**
19. **`proposeEvolutionPath(string memory _description, uint256 _targetTokenId)`**: Allows users with sufficient reputation to propose a governance action, such as guiding an entity's evolution.
20. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows users to vote on active proposals. Voting power is weighted by user reputation.
21. **`executeProposal(uint256 _proposalId)`**: Executes a proposal if it passes the vote and meets quorum.
22. **`delegateVote(address _delegatee)`**: Allows users to delegate their voting power to another address.
23. **`setResourceAllocationSprint(string memory _name, uint256 _duration, uint256 _targetEntityId)`**: Owner or DAO initiates a time-bound "sprint" to allocate SynergyTokens towards a specific goal or entity.
24. **`allocateSynergyToSprint(uint256 _sprintId, uint256 _amount)`**: Users or the DAO can commit SynergyTokens from the Synergy Pool to an active sprint.

**V. Synergy Pool & Rewards**
25. **`depositToSynergyPool(uint256 _amount)`**: Allows users to deposit SynergyTokens directly into the central Synergy Pool.
26. **`distributeSynergyRewards(uint256 _amount, address[] memory _recipients, uint256[] memory _shares)`**: Allows owner/DAO to distribute rewards from the Synergy Pool to specified recipients based on shares.
27. **`claimSynergyRewards(address _user)`**: (Conceptual) A placeholder function for users to claim accrued rewards, requiring a more complex off-chain or dedicated on-chain accounting system.

**VI. Oracle & External Factors (Conceptual Integration)**
28. **`updateExternalFactor(uint256 _factorId, int256 _newValue)`**: Allows the designated oracle address to update an external environmental factor that can influence entities.
29. **`getExternalFactor(uint256 _factorId)`**: Retrieves the current value of an external environmental factor.

**VII. Metadata & Utilities**
30. **`tokenURI(uint256 _tokenId)`**: Returns the URI for a Digital Entity's metadata, incorporating dynamic attributes (metadata served off-chain).
31. **`getSynergyPoolBalance()`**: Returns the current balance of SynergyTokens held in the Synergy Pool (i.e., this contract).

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For toString()

// Dummy ERC20 for demonstration purposes.
// In a real scenario, this would be a separately deployed and potentially more complex token contract.
contract SynergyToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18; // Standard decimals
        _mint(msg.sender, 1_000_000 * (10 ** uint256(_decimals))); // Mint initial supply to deployer
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}


/**
 * @title SynergyNexus: Evolving Digital Ecosystem
 * @dev This contract manages a decentralized, evolving ecosystem of "Digital Entities" (NFTs) that derive
 *      their attributes and "evolutionary path" from community interaction, staked resources (SynergyToken),
 *      and conceptual external factors (via an oracle). It blends concepts of dynamic NFTs, reputation systems,
 *      gamified governance, and resource pooling.
 */
contract SynergyNexus is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    IERC20 public synergyToken;
    address public oracleAddress;
    string private _baseTokenURI;

    // Digital Entity Struct: Represents the core NFT with mutable and immutable properties.
    struct DigitalEntity {
        uint256 id;
        string name;
        address owner;
        uint256 creationTime;
        uint256 lastNourishmentTime;
        uint256 nourishmentPoints; // Accumulates from staked tokens, used for evolution
        uint256 energy; // Mutable attribute, impacts actions and synergy effects (e.g., costs 50 for synergy)
        uint256 resilience; // Mutable attribute, impacts decay resistance
        uint256 adaptability; // Mutable attribute, impacts evolution success and external factor influence
        uint256 synergyFactor; // Mutable attribute, impacts benefits provided to other entities
        uint256 reputation; // Entity's reputation score, gained through nourishment/evolution
        uint256 lastEvolutionTime;
        uint256[] traits; // IDs of special traits possessed by the entity
    }

    mapping(uint256 => DigitalEntity) public digitalEntities;
    mapping(address => uint256) public userReputation; // Reputation score for users
    // Staking information for nourishment: tokenId => stakerAddress => amount
    mapping(uint256 => mapping(address => uint256)) public entityNourishmentStakes;
    // Unlock timestamp for staked nourishment: tokenId => stakerAddress => unlockTimestamp
    mapping(uint256 => mapping(address => uint256)) public nourishmentUnlockTime;

    // Governance Proposal Struct
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 targetTokenId; // If proposal is for a specific entity (0 if general)
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        bool executed;
        bool passed;
    }

    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => address) public voteDelegates; // User => delegatee for voting power

    // Resource Allocation Sprint Struct
    struct AllocationSprint {
        uint256 id;
        string name;
        address initiator;
        uint256 startTime;
        uint256 endTime;
        uint256 targetEntityId; // The entity this sprint focuses on (0 if general ecosystem)
        uint256 allocatedAmount; // Total SynergyTokens conceptually allocated to this sprint
        bool completed;
    }

    Counters.Counter private _sprintIdCounter;
    mapping(uint256 => AllocationSprint) public allocationSprints;

    // External Factors: conceptual data fed by an oracle.
    // factorId => value (e.g., 1 for "Climate Index", 2 for "Social Sentiment")
    mapping(uint256 => int256) public externalFactors;

    // Parameters (Configurable by owner or DAO)
    uint256 public NOURISHMENT_UNLOCK_DURATION = 7 days; // Duration before staked nourishment can be withdrawn
    uint256 public EVOLUTION_NOURISHMENT_THRESHOLD = 1000 * (10 ** 18); // Minimum nourishment for evolution
    uint256 public EVOLUTION_COST = 500 * (10 ** 18); // Cost in SynergyTokens for evolution
    uint256 public USER_REPUTATION_DECAY_RATE = 1; // Simplified decay (conceptual, not auto-applied)
    uint256 public ENTITY_REPUTATION_DECAY_RATE = 1; // Simplified decay (conceptual, not auto-applied)
    uint256 public PROPOSAL_VOTING_DURATION = 3 days; // Duration for proposals to be open for voting
    uint256 public MIN_REPUTATION_TO_PROPOSE = 100; // Minimum user reputation to create a proposal
    uint256 public MIN_VOTE_POWER_FOR_PROPOSAL = 100; // Minimum total vote power for a proposal to be valid

    // --- Events ---
    event DigitalEntityCreated(uint256 indexed tokenId, string name, address indexed owner, uint256 burnAmount);
    event EntityNourished(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event NourishmentWithdrawn(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event EntityEvolved(uint256 indexed tokenId, uint256 newEnergy, uint256 newResilience, uint256 newAdaptability, uint256 newSynergyFactor);
    event TraitAdded(uint256 indexed tokenId, uint256 traitId);
    event TraitRemoved(uint256 indexed tokenId, uint256 traitId);
    event UserReputationUpdated(address indexed user, int256 delta, uint256 newReputation);
    event EntityReputationUpdated(uint256 indexed tokenId, int256 delta, uint256 newReputation);
    event SynergyPoolDeposit(address indexed depositor, uint256 amount);
    event RewardsDistributed(address indexed distributor, uint256 amount, address[] recipients, uint256[] shares);
    event ProposalCreated(uint256 indexed proposalId, string description, address indexed proposer, uint256 targetTokenId, uint256 endTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event SprintInitiated(uint256 indexed sprintId, string name, address indexed initiator, uint256 targetEntityId, uint256 endTime);
    event SynergyAllocatedToSprint(uint256 indexed sprintId, address indexed contributor, uint256 amount);
    event ExternalFactorUpdated(uint256 indexed factorId, int256 newValue);
    event EntitySynergyTriggered(uint256 indexed tokenId, uint256 energyCost, uint256 synergyBenefit);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "SynergyNexus: Only the designated oracle can call this function");
        _;
    }

    modifier entityExists(uint256 _tokenId) {
        require(_exists(_tokenId), "SynergyNexus: Entity does not exist");
        _;
    }

    modifier hasMinimumReputation(uint256 _minReputation) {
        require(userReputation[msg.sender] >= _minReputation, "SynergyNexus: Insufficient reputation");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address initialSynergyToken, address initialOracle)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        require(initialSynergyToken != address(0), "SynergyNexus: SynergyToken address cannot be zero");
        require(initialOracle != address(0), "SynergyNexus: Oracle address cannot be zero");
        synergyToken = IERC20(initialSynergyToken);
        oracleAddress = initialOracle;
        // Default IPFS CID for base URI. This will be concatenated with tokenId to form the full URI.
        _baseTokenURI = "ipfs://Qmbn71mXJvK4x3Kz2NfQ8K5s2Z9Y6w7Z2b8C1j5G4H9E0L/";
    }

    // --- I. Core Setup & Administration ---

    /**
     * @dev Allows the owner to update the address of the SynergyToken contract.
     * @param _newAddress The new address of the SynergyToken contract.
     */
    function setSynergyTokenAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "SynergyNexus: New SynergyToken address cannot be zero");
        synergyToken = IERC20(_newAddress);
    }

    /**
     * @dev Allows the owner to update the address of the conceptual Oracle contract.
     * @param _newAddress The new address of the Oracle contract.
     */
    function setOracleAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "SynergyNexus: New Oracle address cannot be zero");
        oracleAddress = _newAddress;
    }

    /**
     * @dev Allows the owner to set the base URI for Digital Entity NFT metadata.
     * @param _newBaseURI The new base URI.
     */
    function setBaseEntityURI(string memory _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    /**
     * @dev Sets key parameters governing entity growth and reputation decay.
     * @param _nourishmentThreshold Minimum nourishment points required for evolution.
     * @param _evolutionCost Cost in SynergyTokens to trigger evolution.
     * @param _reputationDecayRate The simplified rate at which user/entity reputation decays.
     */
    function setGrowthParameters(uint256 _nourishmentThreshold, uint256 _evolutionCost, uint256 _reputationDecayRate) external onlyOwner {
        require(_nourishmentThreshold > 0 && _evolutionCost > 0, "SynergyNexus: Parameters must be greater than zero");
        EVOLUTION_NOURISHMENT_THRESHOLD = _nourishmentThreshold;
        EVOLUTION_COST = _evolutionCost;
        USER_REPUTATION_DECAY_RATE = _reputationDecayRate;
        ENTITY_REPUTATION_DECAY_RATE = _reputationDecayRate;
    }

    // --- II. Digital Entities (NFTs - ERC721 Based) ---

    /**
     * @dev Mints a new Digital Entity NFT. Requires burning a specified amount of SynergyToken.
     *      The burnt tokens are transferred to this contract, effectively adding to the Synergy Pool.
     *      Initial attributes are pseudo-randomly generated within a healthy range.
     * @param _name The name of the new Digital Entity.
     * @param _burnAmount The amount of SynergyToken to burn to create this entity.
     */
    function createDigitalEntity(string memory _name, uint256 _burnAmount) external {
        require(_burnAmount > 0, "SynergyNexus: Burn amount must be greater than zero");
        synergyToken.safeTransferFrom(msg.sender, address(this), _burnAmount); // Tokens go to the Synergy Pool
        emit SynergyPoolDeposit(msg.sender, _burnAmount);

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // Simple pseudo-random initialization based on block timestamp and msg.sender.
        // NOT cryptographically secure, only for demonstrating mutable initial states.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newItemId, block.difficulty)));

        digitalEntities[newItemId] = DigitalEntity({
            id: newItemId,
            name: _name,
            owner: msg.sender,
            creationTime: block.timestamp,
            lastNourishmentTime: block.timestamp,
            nourishmentPoints: 0,
            energy: (seed % 50) + 100, // Initial 100-149
            resilience: (seed % 50) + 100, // Initial 100-149
            adaptability: (seed % 50) + 100, // Initial 100-149
            synergyFactor: (seed % 10) + 5, // Initial 5-14
            reputation: 0,
            lastEvolutionTime: block.timestamp,
            traits: new uint256[](0)
        });

        _mint(msg.sender, newItemId);
        _updateUserReputation(msg.sender, 10); // Reward reputation for creating entity
        emit DigitalEntityCreated(newItemId, _name, msg.sender, _burnAmount);
    }

    /**
     * @dev Triggers the evolution of a Digital Entity if it meets nourishment criteria and owner pays cost.
     *      Evolution alters attributes based on its adaptability and current external factors.
     * @param _tokenId The ID of the Digital Entity to evolve.
     */
    function evolveEntity(uint256 _tokenId) external entityExists(_tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "SynergyNexus: Only the entity owner can trigger evolution");
        DigitalEntity storage entity = digitalEntities[_tokenId];
        require(entity.nourishmentPoints >= EVOLUTION_NOURISHMENT_THRESHOLD, "SynergyNexus: Insufficient nourishment for evolution");
        require(synergyToken.balanceOf(msg.sender) >= EVOLUTION_COST, "SynergyNexus: Insufficient SynergyTokens for evolution cost");

        synergyToken.safeTransferFrom(msg.sender, address(this), EVOLUTION_COST); // Pay evolution cost
        emit SynergyPoolDeposit(msg.sender, EVOLUTION_COST); // Add cost to pool

        // Reset nourishment after evolution
        entity.nourishmentPoints = 0;

        // Apply attribute changes based on external factors and adaptability.
        // For simplicity, using pre-defined factor IDs.
        int256 climateFactor = externalFactors[1]; // e.g., 1 for "Climate Index"
        int256 socialFactor = externalFactors[2]; // e.g., 2 for "Social Sentiment"

        // Attributes change based on external factors, scaled by entity's adaptability.
        // Capping changes to prevent extreme swings.
        int256 energyDelta = (climateFactor / 10).mul(int256(entity.adaptability) / 100);
        int256 resilienceDelta = (socialFactor / 10).mul(int256(entity.adaptability) / 100);
        int256 adaptabilityDelta = (climateFactor + socialFactor).div(20);
        int256 synergyFactorDelta = (climateFactor + socialFactor).div(30);

        // Clamp attribute changes to a reasonable range (e.g., +/- 20 for main attributes)
        entity.energy = _safeAddInt(entity.energy, _clamp(energyDelta, -20, 20));
        entity.resilience = _safeAddInt(entity.resilience, _clamp(resilienceDelta, -20, 20));
        entity.adaptability = _safeAddInt(entity.adaptability, _clamp(adaptabilityDelta, -10, 10));
        entity.synergyFactor = _safeAddInt(entity.synergyFactor, _clamp(synergyFactorDelta, -5, 5));

        // Ensure attributes don't go below a certain minimum or exceed a maximum (conceptual limits)
        entity.energy = _clamp(int256(entity.energy), 10, 200);
        entity.resilience = _clamp(int256(entity.resilience), 10, 200);
        entity.adaptability = _clamp(int256(entity.adaptability), 10, 200);
        entity.synergyFactor = _clamp(int256(entity.synergyFactor), 1, 50);


        entity.lastEvolutionTime = block.timestamp;
        _updateEntityReputation(_tokenId, 50); // Reward entity reputation for evolving
        _updateUserReputation(msg.sender, 20); // Reward user for evolving entity

        emit EntityEvolved(_tokenId, entity.energy, entity.resilience, entity.adaptability, entity.synergyFactor);
    }

    /**
     * @dev Allows the owner (or DAO) to assign a specific trait to an entity.
     *      Traits can be conceptual or unlock specific functions/effects.
     * @param _tokenId The ID of the entity.
     * @param _traitId The ID of the trait to add.
     */
    function addTraitToEntity(uint256 _tokenId, uint256 _traitId) external onlyOwner entityExists(_tokenId) {
        // In a full DAO, this would ideally be behind a governance vote.
        DigitalEntity storage entity = digitalEntities[_tokenId];
        for (uint256 i = 0; i < entity.traits.length; i++) {
            require(entity.traits[i] != _traitId, "SynergyNexus: Entity already has this trait");
        }
        entity.traits.push(_traitId);
        emit TraitAdded(_tokenId, _traitId);
    }

    /**
     * @dev Removes a trait from an entity.
     * @param _tokenId The ID of the entity.
     * @param _traitId The ID of the trait to remove.
     */
    function removeTraitFromEntity(uint256 _tokenId, uint256 _traitId) external onlyOwner entityExists(_tokenId) {
        DigitalEntity storage entity = digitalEntities[_tokenId];
        bool found = false;
        for (uint256 i = 0; i < entity.traits.length; i++) {
            if (entity.traits[i] == _traitId) {
                entity.traits[i] = entity.traits[entity.traits.length - 1]; // Swap with last element
                entity.traits.pop(); // Remove last element
                found = true;
                break;
            }
        }
        require(found, "SynergyNexus: Entity does not have this trait");
        emit TraitRemoved(_tokenId, _traitId);
    }

    /**
     * @dev Retrieves the current dynamic attributes of an entity.
     * @param _tokenId The ID of the entity.
     * @return energy, resilience, adaptability, synergyFactor.
     */
    function getMutableEntityAttributes(uint256 _tokenId) external view entityExists(_tokenId) returns (uint256 energy, uint256 resilience, uint256 adaptability, uint256 synergyFactor) {
        DigitalEntity storage entity = digitalEntities[_tokenId];
        return (entity.energy, entity.resilience, entity.adaptability, entity.synergyFactor);
    }

    /**
     * @dev Allows users to stake SynergyTokens to a specific Digital Entity, increasing its nourishment score.
     *      These tokens enter a lock-up period and contribute to the Synergy Pool.
     * @param _tokenId The ID of the Digital Entity to nourish.
     * @param _amount The amount of SynergyToken to stake.
     */
    function nourishEntity(uint256 _tokenId, uint256 _amount) external entityExists(_tokenId) {
        require(_amount > 0, "SynergyNexus: Nourishment amount must be greater than zero");
        synergyToken.safeTransferFrom(msg.sender, address(this), _amount); // Tokens go to Synergy Pool

        DigitalEntity storage entity = digitalEntities[_tokenId];
        entity.nourishmentPoints += _amount;
        entity.lastNourishmentTime = block.timestamp;

        entityNourishmentStakes[_tokenId][msg.sender] += _amount;
        nourishmentUnlockTime[_tokenId][msg.sender] = block.timestamp + NOURISHMENT_UNLOCK_DURATION;

        // Scale reputation gain by amount, dividing by 10^(decimals-2) to normalize for large token values
        _updateEntityReputation(_tokenId, int256(_amount / (10**(synergyToken.decimals() - 2))));
        _updateUserReputation(msg.sender, int256(_amount / (10**(synergyToken.decimals() - 2))));

        emit EntityNourished(_tokenId, msg.sender, _amount);
    }

    /**
     * @dev Allows a user to withdraw their previously staked nourishment from an entity after the lock-up period.
     *      Withdrawal of nourishment reduces the entity's nourishment points.
     * @param _tokenId The ID of the Digital Entity.
     * @param _amount The amount of SynergyToken to withdraw.
     */
    function withdrawNourishment(uint256 _tokenId, uint256 _amount) external entityExists(_tokenId) {
        require(_amount > 0, "SynergyNexus: Withdrawal amount must be greater than zero");
        require(entityNourishmentStakes[_tokenId][msg.sender] >= _amount, "SynergyNexus: Insufficient staked nourishment");
        require(block.timestamp >= nourishmentUnlockTime[_tokenId][msg.sender], "SynergyNexus: Nourishment is still locked");

        DigitalEntity storage entity = digitalEntities[_tokenId];
        entityNourishmentStakes[_tokenId][msg.sender] -= _amount;

        // Deduct from entity nourishment points. This means entities lose "progress" if nourishment is withdrawn.
        entity.nourishmentPoints = entity.nourishmentPoints > _amount ? entity.nourishmentPoints - _amount : 0;

        synergyToken.safeTransfer(msg.sender, _amount);
        // Apply a slight reputation penalty for withdrawing nourishment, scaled.
        _updateUserReputation(msg.sender, -int256(_amount / (10**(synergyToken.decimals() - 2))).div(2));
        emit NourishmentWithdrawn(_tokenId, msg.sender, _amount);
    }

    /**
     * @dev Allows an entity owner to trigger a "synergy effect" if the entity possesses relevant traits and sufficient energy.
     *      This could boost other entities' attributes or contribute to the community.
     * @param _tokenId The ID of the entity performing the synergy.
     */
    function triggerEntitySynergy(uint256 _tokenId) external entityExists(_tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "SynergyNexus: Only the entity owner can trigger synergy");
        DigitalEntity storage entity = digitalEntities[_tokenId];
        uint256 synergyCost = 50; // Example fixed energy cost for synergy
        require(entity.energy >= synergyCost, "SynergyNexus: Entity does not have enough energy to trigger synergy");

        // Reduce energy as a cost
        entity.energy -= synergyCost;

        // Example synergy effect: Boost 2 random other entities' energy based on this entity's synergyFactor.
        // Pseudo-random selection, not for critical security.
        uint265 numEntities = _tokenIdCounter.current();
        if (numEntities > 1) {
            uint256 boostAmount = entity.synergyFactor * 10; // Benefit scaled by synergyFactor

            uint256 target1Id = (uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, 1, block.difficulty))) % numEntities) + 1;
            uint256 target2Id = (uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, 2, block.difficulty))) % numEntities) + 1;

            if (_exists(target1Id) && target1Id != _tokenId) {
                digitalEntities[target1Id].energy += boostAmount;
                _updateEntityReputation(target1Id, 5); // Target entity gains reputation
            }
            if (_exists(target2Id) && target2Id != _tokenId && target2Id != target1Id) {
                digitalEntities[target2Id].energy += boostAmount;
                _updateEntityReputation(target2Id, 5); // Target entity gains reputation
            }
        }
        _updateEntityReputation(_tokenId, 10); // Gainer reputation for triggering synergy
        emit EntitySynergyTriggered(_tokenId, synergyCost, entity.synergyFactor);
    }

    /**
     * @dev Returns the list of trait IDs currently possessed by an entity.
     * @param _tokenId The ID of the entity.
     * @return An array of trait IDs.
     */
    function getEntityTraits(uint256 _tokenId) external view entityExists(_tokenId) returns (uint256[] memory) {
        return digitalEntities[_tokenId].traits;
    }


    // --- III. Reputation System ---

    /**
     * @dev Retrieves the reputation score of a given user.
     * @param _user The address of the user.
     * @return The user's current reputation score.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Retrieves the reputation score of a given Digital Entity.
     * @param _tokenId The ID of the Digital Entity.
     * @return The entity's current reputation score.
     */
    function getEntityReputation(uint256 _tokenId) public view entityExists(_tokenId) returns (uint256) {
        return digitalEntities[_tokenId].reputation;
    }

    /**
     * @dev Internal function to adjust a user's reputation score.
     *      Handles both positive and negative delta.
     * @param _user The address of the user.
     * @param _delta The amount to add (positive) or subtract (negative) from reputation.
     */
    function _updateUserReputation(address _user, int256 _delta) internal {
        if (_delta > 0) {
            userReputation[_user] += uint256(_delta);
        } else {
            userReputation[_user] = userReputation[_user] >= uint256(-_delta) ? userReputation[_user] - uint256(-_delta) : 0;
        }
        emit UserReputationUpdated(_user, _delta, userReputation[_user]);
    }

    /**
     * @dev Internal function to adjust an entity's reputation score.
     *      Handles both positive and negative delta.
     * @param _tokenId The ID of the Digital Entity.
     * @param _delta The amount to add (positive) or subtract (negative) from reputation.
     */
    function _updateEntityReputation(uint256 _tokenId, int256 _delta) internal entityExists(_tokenId) {
        if (_delta > 0) {
            digitalEntities[_tokenId].reputation += uint256(_delta);
        } else {
            digitalEntities[_tokenId].reputation = digitalEntities[_tokenId].reputation >= uint256(-_delta) ? digitalEntities[_tokenId].reputation - uint256(-_delta) : 0;
        }
        emit EntityReputationUpdated(_tokenId, _delta, digitalEntities[_tokenId].reputation);
    }

    // --- IV. Community & Governance (Simulated DAO elements) ---

    /**
     * @dev Allows users with sufficient reputation to propose a governance action, like guiding an entity's evolution.
     * @param _description A description of the proposal.
     * @param _targetTokenId The ID of the entity the proposal targets (0 if general ecosystem proposal).
     */
    function proposeEvolutionPath(string memory _description, uint256 _targetTokenId) external hasMinimumReputation(MIN_REPUTATION_TO_PROPOSE) {
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            description: _description,
            proposer: msg.sender,
            targetTokenId: _targetTokenId,
            startTime: block.timestamp,
            endTime: block.timestamp + PROPOSAL_VOTING_DURATION,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)(), // Initialize a new mapping for this proposal
            executed: false,
            passed: false
        });
        _updateUserReputation(msg.sender, 5); // Reward for creating a proposal
        emit ProposalCreated(newProposalId, _description, msg.sender, _targetTokenId, proposals[newProposalId].endTime);
    }

    /**
     * @dev Allows users to vote on active proposals. Voting power is weighted by user reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' (yes), false for 'against' (no).
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startTime != 0, "SynergyNexus: Proposal does not exist");
        require(block.timestamp < proposal.endTime, "SynergyNexus: Voting period has ended");

        address voter = msg.sender;
        if (voteDelegates[msg.sender] != address(0)) {
            voter = voteDelegates[msg.sender]; // Use delegatee's vote if delegated
        }

        require(!proposal.hasVoted[voter], "SynergyNexus: Already voted on this proposal");

        uint256 voteWeight = userReputation[vvoter] / 10; // Reputation-weighted voting (simplified)
        require(voteWeight > 0, "SynergyNexus: No voting power (reputation too low)");

        if (_support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[voter] = true;
        _updateUserReputation(msg.sender, 2); // Reward for voting
        emit VoteCast(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @dev Executes a proposal if it passes the vote and meets quorum.
     *      Only callable after voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startTime != 0, "SynergyNexus: Proposal does not exist");
        require(block.timestamp >= proposal.endTime, "SynergyNexus: Voting period has not ended");
        require(!proposal.executed, "SynergyNexus: Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        // Simple quorum: minimum total vote power needed, and more votes for than against.
        bool passed = (proposal.votesFor > proposal.votesAgainst) && (totalVotes >= MIN_VOTE_POWER_FOR_PROPOSAL);

        proposal.passed = passed;
        proposal.executed = true;

        if (passed) {
            // Example effect: If proposal targets an entity, boost its adaptability and reputation.
            if (proposal.targetTokenId != 0 && _exists(proposal.targetTokenId)) {
                digitalEntities[proposal.targetTokenId].adaptability += 10;
                _updateEntityReputation(proposal.targetTokenId, 20); // Reward entity for being target of successful proposal
            }
            _updateUserReputation(proposal.proposer, 10); // Reward proposer for successful proposal
        } else {
            _updateUserReputation(proposal.proposer, -5); // Small penalty for failed proposal
        }
        emit ProposalExecuted(_proposalId, passed);
    }

    /**
     * @dev Allows users to delegate their voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) external {
        require(_delegatee != address(0) && _delegatee != msg.sender, "SynergyNexus: Invalid delegatee address");
        voteDelegates[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Owner or DAO initiates a time-bound "sprint" to allocate SynergyTokens towards a specific goal or entity.
     *      In a full DAO, this would be a governance action rather than onlyOwner.
     * @param _name The name of the sprint.
     * @param _duration The duration of the sprint in seconds.
     * @param _targetEntityId The ID of the entity this sprint targets (0 if general ecosystem goal).
     */
    function setResourceAllocationSprint(string memory _name, uint256 _duration, uint256 _targetEntityId) external onlyOwner {
        require(_duration > 0, "SynergyNexus: Sprint duration must be greater than zero");
        _sprintIdCounter.increment();
        uint256 newSprintId = _sprintIdCounter.current();

        allocationSprints[newSprintId] = AllocationSprint({
            id: newSprintId,
            name: _name,
            initiator: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            targetEntityId: _targetEntityId,
            allocatedAmount: 0,
            completed: false
        });
        emit SprintInitiated(newSprintId, _name, msg.sender, _targetEntityId, allocationSprints[newSprintId].endTime);
    }

    /**
     * @dev Users or the DAO can commit SynergyTokens from the Synergy Pool to an active sprint.
     *      This function transfers tokens from the pool and conceptually allocates them.
     * @param _sprintId The ID of the sprint to allocate to.
     * @param _amount The amount of SynergyTokens to allocate.
     */
    function allocateSynergyToSprint(uint256 _sprintId, uint256 _amount) external {
        AllocationSprint storage sprint = allocationSprints[_sprintId];
        require(sprint.startTime != 0, "SynergyNexus: Sprint does not exist");
        require(block.timestamp < sprint.endTime, "SynergyNexus: Sprint has ended");
        require(!sprint.completed, "SynergyNexus: Sprint is already completed");
        require(_amount > 0, "SynergyNexus: Allocation amount must be greater than zero");
        require(synergyToken.balanceOf(address(this)) >= _amount, "SynergyNexus: Insufficient funds in Synergy Pool");

        sprint.allocatedAmount += _amount;
        // The tokens remain within the contract's balance but are conceptually "allocated"

        // For simplicity, directly add nourishment to the target entity during the sprint.
        if (sprint.targetEntityId != 0 && _exists(sprint.targetEntityId)) {
            digitalEntities[sprint.targetEntityId].nourishmentPoints += _amount;
            digitalEntities[sprint.targetEntityId].lastNourishmentTime = block.timestamp;
            _updateEntityReputation(sprint.targetEntityId, int256(_amount / (10**(synergyToken.decimals() - 2))));
        }
        _updateUserReputation(msg.sender, 5); // Reward for contributing to sprint
        emit SynergyAllocatedToSprint(_sprintId, msg.sender, _amount);
    }

    // --- V. Synergy Pool & Rewards ---

    /**
     * @dev Allows users to deposit SynergyTokens directly into the central Synergy Pool.
     *      These tokens can then be used for entity creation, evolution costs, or rewards.
     * @param _amount The amount of SynergyToken to deposit.
     */
    function depositToSynergyPool(uint256 _amount) external {
        require(_amount > 0, "SynergyNexus: Deposit amount must be greater than zero");
        synergyToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit SynergyPoolDeposit(msg.sender, _amount);
        _updateUserReputation(msg.sender, 5); // Reward for contributing to the pool
    }

    /**
     * @dev Allows owner/DAO to distribute rewards from the Synergy Pool to specified recipients based on shares.
     *      In a real DAO, this distribution logic would be decided by a governance proposal.
     * @param _amount The total amount of SynergyTokens to distribute.
     * @param _recipients An array of recipient addresses.
     * @param _shares An array of shares corresponding to recipients. Sum of shares defines total points.
     */
    function distributeSynergyRewards(uint256 _amount, address[] memory _recipients, uint256[] memory _shares) external onlyOwner {
        require(_recipients.length == _shares.length, "SynergyNexus: Recipients and shares array length mismatch");
        require(_amount > 0, "SynergyNexus: Distribution amount must be greater than zero");
        require(synergyToken.balanceOf(address(this)) >= _amount, "SynergyNexus: Insufficient funds in Synergy Pool");

        uint256 totalShares;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares += _shares[i];
        }
        require(totalShares > 0, "SynergyNexus: Total shares must be greater than zero");

        for (uint256 i = 0; i < _recipients.length; i++) {
            uint256 shareAmount = (_amount * _shares[i]) / totalShares; // Integer division
            if (shareAmount > 0) {
                synergyToken.safeTransfer(_recipients[i], shareAmount);
                _updateUserReputation(_recipients[i], 10); // Reward for receiving rewards
            }
        }
        emit RewardsDistributed(msg.sender, _amount, _recipients, _shares);
    }

    /**
     * @dev (Conceptual) Allows users to claim their accrued rewards.
     *      This function is a placeholder for a more complex reward accounting system (e.g., Merkle Tree distribution
     *      for off-chain calculation of rewards, or a dedicated rewards accumulation mapping on-chain).
     *      For this example, `distributeSynergyRewards` handles direct transfers.
     */
    function claimSynergyRewards(address _user) external pure returns(bool) {
        // This function would typically check _user's claimable balance and then transfer tokens.
        // As a conceptual function to meet the requirement, it reverts.
        revert("SynergyNexus: Claiming rewards is handled by direct distribution or requires a specific reward pool logic.");
    }


    // --- VI. Oracle & External Factors (Conceptual Integration) ---

    /**
     * @dev Allows the designated oracle address to update an external environmental factor that can influence entities.
     * @param _factorId An ID representing the type of factor (e.g., 1 for "Climate Index", 2 for "Social Sentiment").
     * @param _newValue The new integer value for the factor. Can be positive or negative.
     */
    function updateExternalFactor(uint256 _factorId, int256 _newValue) external onlyOracle {
        externalFactors[_factorId] = _newValue;
        emit ExternalFactorUpdated(_factorId, _newValue);
        // The effect of this update is primarily seen in functions like `evolveEntity` where factors are read.
    }

    /**
     * @dev Retrieves the current value of an external environmental factor.
     * @param _factorId The ID of the factor.
     * @return The current integer value of the factor.
     */
    function getExternalFactor(uint256 _factorId) external view returns (int256) {
        return externalFactors[_factorId];
    }

    // --- VII. Metadata & Utilities ---

    /**
     * @dev Returns the URI for a Digital Entity's metadata.
     *      The metadata will be dynamically generated off-chain by an external service that queries
     *      the contract for the entity's current mutable attributes.
     * @param _tokenId The ID of the Digital Entity.
     * @return The full URI pointing to the metadata.
     */
    function tokenURI(uint256 _tokenId) public view override entityExists(_tokenId) returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Returns the current balance of SynergyTokens held in the Synergy Pool (i.e., this contract).
     * @return The total SynergyToken balance.
     */
    function getSynergyPoolBalance() external view returns (uint256) {
        return synergyToken.balanceOf(address(this));
    }

    // --- Internal Helpers for int256 arithmetic and clamping ---
    function _safeAddInt(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            uint256 res = a + uint256(b);
            require(res >= a, "SynergyNexus: Addition overflow"); // Check for overflow if a+b exceeds max uint256
            return res;
        } else {
            uint256 absB = uint256(-b);
            require(a >= absB, "SynergyNexus: Subtraction underflow"); // Check for underflow if a < abs(b)
            return a - absB;
        }
    }

    function _clamp(int256 value, int256 minVal, int256 maxVal) internal pure returns (uint256) {
        if (value < minVal) return uint256(minVal);
        if (value > maxVal) return uint256(maxVal);
        return uint256(value);
    }

    // Simple int256 multiplication/division - for small, controlled values used in attribute changes.
    // Caution for large numbers or untrusted inputs.
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SynergyNexus: division by zero");
        return a / b;
    }
}
```