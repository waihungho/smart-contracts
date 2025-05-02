Okay, let's design a smart contract system around the concept of "Living Digital Assets" or "Evolving Entities". These will be NFTs (ERC721) whose properties decay over time and can be boosted or maintained by interacting with a native ERC20 token. There will also be periodic "global events" that affect all entities.

This involves several advanced concepts:
1.  **Dynamic NFT State:** The properties of the NFT change based on time and interactions, not just static metadata.
2.  **Time-Based Decay/Growth:** Properties decrease over time if not maintained.
3.  **Token Bonding to NFT:** Users can stake/bond tokens *to* a specific NFT, providing ongoing benefits or yield.
4.  **Complex Interaction Mechanics:** Feeding tokens, boosting stats, claiming yield are all tied to the entity's state and time.
5.  **On-Chain Global Events:** A mechanism to trigger events that affect all entities in a structured way.
6.  **Modular Design:** Using separate ERC20 and ERC721 contracts managed by a central "Ecosystem" or "Factory" contract.

We'll focus the 20+ functions on the central *Ecosystem* contract, which orchestrates the interactions between users, tokens, NFTs, and the entity state.

**Outline & Function Summary**

**Contract Name:** `EvolvingEntityEcosystem`

**Concept:** Manages a collection of dynamic NFTs (Evolving Entities) and their associated native ERC20 token (Essence). Entities have properties (Strength, Dexterity, Intelligence, LifeForce) that decay over time. Users must interact with their entities using Essence tokens to maintain or boost properties and can also bond Essence to entities for passive benefits or yield. Periodic global events can significantly impact entity states.

**Dependencies:**
*   Assumes standard ERC20 and ERC721 contracts exist and their addresses are provided.
*   Uses a basic `Ownable` pattern for administrative functions.

**State Variables:**
*   References to the ERC20 (Essence) and ERC721 (Entity) contracts.
*   Mapping to store the dynamic state for each `tokenId`.
*   Configuration parameters (decay rates, boost costs, yield rates).
*   Global event state information.

**Core Mechanics:**
*   `EntityState` Struct: Stores current stats, life force, bonded essence, last update timestamp, etc.
*   `updateEntityState(uint256 _tokenId)`: Internal helper function called by interaction functions. Calculates time elapsed since the last update and applies decay to properties.
*   Interactions: Functions like `feedEntity`, `boostStat`, `bondEssenceToEntity` require users to spend Essence tokens, update entity state, and reset the decay timer for affected properties.
*   Yield: Entities passively generate Essence yield based on bonded tokens and stats over time, claimable by the owner.
*   Global Events: Admin/oracle-triggered events modify entity properties or mechanics based on defined parameters.

**Functions Summary (29 Functions):**

1.  `constructor(address _essenceToken, address _entityNFT)`: Initializes contract with token/NFT addresses.
2.  `setEssenceToken(address _token)`: Admin: Sets the address of the Essence ERC20 contract.
3.  `setEntityNFT(address _nft)`: Admin: Sets the address of the Entity ERC721 contract.
4.  `mintInitialEntities(address[] memory _owners, uint256 _initialEssenceBond)`: Admin: Mints initial entities for specified owners and bonds initial Essence.
5.  `requestNewEntity(address _owner, uint256 _essenceDeposit)`: User/Admin: Initiates a request for a new entity, requiring an Essence deposit.
6.  `fulfillNewEntityRequest(address _owner, uint256 _initialEssenceBond)`: Admin: Fulfills a pending entity request, mints the NFT, and bonds Essence.
7.  `feedEntity(uint256 _tokenId, uint256 _amount)`: User: Spends Essence to restore LifeForce, updates state.
8.  `boostStat(uint256 _tokenId, uint8 _statIndex, uint256 _amount)`: User: Spends Essence to boost a specific stat (Str, Dex, Int), updates state.
9.  `bondEssenceToEntity(uint256 _tokenId, uint256 _amount)`: User: Transfers and bonds Essence tokens to the entity, updating bonded amount and state.
10. `unbondEssenceFromEntity(uint256 _tokenId, uint256 _amount)`: User: Removes bonded Essence from the entity and transfers it back to the owner, updating bonded amount and state.
11. `claimEssenceYield(uint256 _tokenId)`: User: Calculates and transfers accumulated Essence yield based on bonded amount and stats, updates state.
12. `triggerGlobalEvolutionEvent(bytes32 _eventId, uint256 _intensity, uint64 _duration)`: Admin/Oracle: Starts a new global event affecting all entities with given parameters.
13. `endGlobalEvolutionEvent()`: Admin: Ends the current global event.
14. `getEntityProperties(uint256 _tokenId)`: View: Gets the *currently calculated* properties of an entity (applies decay virtually for the read).
15. `getEntityLastUpdateTime(uint256 _tokenId)`: View: Gets the timestamp of the last state update for an entity.
16. `getEssenceBondAmount(uint256 _tokenId)`: View: Gets the amount of Essence bonded to an entity.
17. `getEssenceYieldAvailable(uint256 _tokenId)`: View: Calculates and returns the accumulated Essence yield available for claiming.
18. `getStatDecayRate(uint8 _statIndex)`: View: Gets the configured decay rate for a specific stat.
19. `getLifeForceDecayRate()`: View: Gets the configured decay rate for LifeForce.
20. `getEssenceYieldRate()`: View: Gets the configured yield rate for bonded Essence.
21. `getStatBoostCost(uint8 _statIndex, uint256 _amount)`: View: Calculates the Essence cost to boost a specific stat by an amount.
22. `getFeedCost(uint256 _tokenId, uint256 _desiredLifeForce)`: View: Calculates the Essence cost to feed an entity to reach a desired LifeForce level.
23. `isEntityAlive(uint256 _tokenId)`: View: Checks if an entity's LifeForce is currently above zero.
24. `getGlobalEventState()`: View: Gets information about the current global event.
25. `setStatDecayRate(uint8 _statIndex, uint256 _ratePerSecond)`: Admin: Sets the decay rate for a specific stat.
26. `setLifeForceDecayRate(uint256 _ratePerSecond)`: Admin: Sets the decay rate for LifeForce.
27. `setEssenceYieldRate(uint256 _ratePerSecondPerBondedEssence)`: Admin: Sets the yield rate.
28. `setStatBoostCostPerPoint(uint8 _statIndex, uint256 _cost)`: Admin: Sets the base Essence cost per stat point boost.
29. `withdrawAdminFees(address _tokenAddress, uint256 _amount)`: Admin: Allows withdrawing specified tokens from the contract (e.g., accumulated fees or unclaimed deposits).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // Using OpenZeppelin Math for safety

// Define a simple interface for ERC721 minting if not using ERC721 directly
interface IMintableERC721 is IERC721 {
    function safeMint(address to, uint256 tokenId) external;
    function _safeMint(address to, uint256 tokenId) external; // Assuming _safeMint is internal on the NFT contract, maybe expose via adapter or use a factory pattern
    // For this example, let's assume the ecosystem contract *is* allowed to call _safeMint
    // In a real system, you might have a dedicated NFT factory or minter role.
    // Let's simplify and assume the NFT contract is configured to allow this contract to mint.
    // Or, we could implement a simple minting logic here if this contract *also* controlled the token IDs and metadata pointing.
    // Let's assume the NFT contract has a public `mint` function callable by this owner/minter role.
    function mint(address to, uint256 tokenId) external; // Assuming a simple mint function
    function tokenCounter() external view returns (uint256); // Assuming a counter
}

interface IEntityNFT is IMintableERC721 {
    // Any specific NFT functions could go here
}

interface IEssenceToken is IERC20 {
    // Any specific token functions could go here
}


contract EvolvingEntityEcosystem is Ownable, ERC721Holder {

    IEssenceToken public essenceToken;
    IEntityNFT public entityNFT;

    // --- Entity Properties ---
    // We'll use fixed indices for stats: 0=Strength, 1=Dexterity, 2=Intelligence
    uint8 public constant STAT_STRENGTH = 0;
    uint8 public constant STAT_DEXTERITY = 1;
    uint8 public constant STAT_INTELLIGENCE = 2;
    uint8 public constant STAT_COUNT = 3; // Number of core stats

    // Max possible value for stats and life force
    uint256 public constant MAX_STAT_VALUE = 10000;
    uint256 public constant MAX_LIFE_FORCE = 10000;
    uint256 public constant MIN_LIFE_FORCE_ALIVE = 1;

    struct EntityState {
        uint256 strength;
        uint256 dexterity;
        uint256 intelligence;
        uint256 lifeForce;
        uint256 bondedEssence; // Essence tokens bonded to this specific entity
        uint265 lastUpdateTime; // Use uint265 to fit timestamp
        uint256 unclaimedEssenceYield; // Accumulated yield ready to be claimed
    }

    mapping(uint256 => EntityState) public entityStates; // tokenId => state

    // --- Configuration ---
    uint256[STAT_COUNT] public statDecayRatePerSecond; // How much each stat decays per second
    uint256 public lifeForceDecayRatePerSecond;      // How much LifeForce decays per second

    uint256[STAT_COUNT] public statBoostCostPerPoint; // Essence cost to add 1 point to a stat
    uint256 public feedCostPerPoint;                 // Essence cost to add 1 point to LifeForce

    uint256 public essenceYieldRatePerSecondPerBondedEssence; // How much yield 1 bonded Essence generates per second

    // --- Global Events ---
    bytes32 public currentGlobalEventId;
    uint256 public currentGlobalEventIntensity;
    uint256 public currentGlobalEventEndTime; // 0 if no event active

    // --- Entity Request System ---
    struct EntityRequest {
        address owner;
        uint256 essenceDeposit;
        bool fulfilled;
    }
    bytes32[] public entityRequestIds; // Store active request IDs
    mapping(bytes32 => EntityRequest) public entityRequests; // request ID => request details

    // --- Events ---
    event EntityStateUpdated(uint256 indexed tokenId, uint256 strength, uint256 dexterity, uint256 intelligence, uint256 lifeForce, uint256 bondedEssence, uint256 unclaimedEssenceYield, uint256 lastUpdateTime);
    event EntityMinted(uint256 indexed tokenId, address indexed owner, uint256 initialBond);
    event EntityFed(uint256 indexed tokenId, uint256 amount, uint256 newLifeForce);
    event StatBoosted(uint256 indexed tokenId, uint8 statIndex, uint256 amount, uint256 newStatValue);
    event EssenceBonded(uint256 indexed tokenId, address indexed owner, uint256 amount, uint256 totalBonded);
    event EssenceUnbonded(uint256 indexed tokenId, address indexed owner, uint256 amount, uint256 totalBonded);
    event EssenceYieldClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event EntityDied(uint256 indexed tokenId);
    event EntityRevived(uint256 indexed tokenId);
    event GlobalEventTriggered(bytes32 indexed eventId, uint256 intensity, uint256 duration, uint256 endTime);
    event GlobalEventEnded(bytes32 indexed eventId);
    event EntityRequestCreated(bytes32 indexed requestId, address indexed owner, uint256 essenceDeposit);
    event EntityRequestFulfilled(bytes32 indexed requestId, uint256 indexed tokenId, uint256 initialEssenceBond);
    event ConfigurationUpdated(string configName, uint256 value);

    modifier onlyEntityOwner(uint256 _tokenId) {
        require(entityNFT.ownerOf(_tokenId) == msg.sender, "Not entity owner");
        _;
    }

    modifier entityExists(uint256 _tokenId) {
         require(entityNFT.ownerOf(_tokenId) != address(0), "Entity does not exist"); // ownerOf(tokenId) reverts if not minted
        _;
    }

    // 1. Constructor
    constructor(address _essenceToken, address _entityNFT) Ownable(msg.sender) {
        essenceToken = IEssenceToken(_essenceToken);
        entityNFT = IEntityNFT(_entityNFT);

        // Set initial default decay/cost/yield rates (can be changed by admin)
        statDecayRatePerSecond[STAT_STRENGTH] = 1; // Example: 1 point per second
        statDecayRatePerSecond[STAT_DEXTERITY] = 1;
        statDecayRatePerSecond[STAT_INTELLIGENCE] = 1;
        lifeForceDecayRatePerSecond = 5; // Example: 5 points per second

        statBoostCostPerPoint[STAT_STRENGTH] = 10 ether; // Example: 10 Essence per strength point
        statBoostCostPerPoint[STAT_DEXTERITY] = 10 ether;
        statBoostCostPerPoint[STAT_INTELLIGENCE] = 10 ether;
        feedCostPerPoint = 5 ether; // Example: 5 Essence per LifeForce point

        essenceYieldRatePerSecondPerBondedEssence = 100; // Example: 1 bonded Essence yields 100 wei per second
                                                        // Use higher number for practical yield (e.g., 1e12 wei)
    }

    // --- Admin Configuration Functions ---

    // 2. setEssenceToken
    function setEssenceToken(address _token) external onlyOwner {
        essenceToken = IEssenceToken(_token);
    }

    // 3. setEntityNFT
    function setEntityNFT(address _nft) external onlyOwner {
        entityNFT = IEntityNFT(_nft);
    }

    // 25. setStatDecayRate
    function setStatDecayRate(uint8 _statIndex, uint256 _ratePerSecond) external onlyOwner {
        require(_statIndex < STAT_COUNT, "Invalid stat index");
        statDecayRatePerSecond[_statIndex] = _ratePerSecond;
        emit ConfigurationUpdated(string(abi.encodePacked("StatDecayRate-", _statIndex)), _ratePerSecond);
    }

    // 26. setLifeForceDecayRate
    function setLifeForceDecayRate(uint256 _ratePerSecond) external onlyOwner {
        lifeForceDecayRatePerSecond = _ratePerSecond;
        emit ConfigurationUpdated("LifeForceDecayRate", _ratePerSecond);
    }

    // 27. setEssenceYieldRate
    function setEssenceYieldRate(uint256 _ratePerSecondPerBondedEssence) external onlyOwner {
        essenceYieldRatePerSecondPerBondedEssence = _ratePerSecondPerBondedEssence;
        emit ConfigurationUpdated("EssenceYieldRate", _ratePerSecondPerBondedEssence);
    }

    // 28. setStatBoostCostPerPoint
    function setStatBoostCostPerPoint(uint8 _statIndex, uint256 _cost) external onlyOwner {
        require(_statIndex < STAT_COUNT, "Invalid stat index");
        statBoostCostPerPoint[_statIndex] = _cost;
         emit ConfigurationUpdated(string(abi.encodePacked("StatBoostCost-", _statIndex)), _cost);
    }

    // 29. withdrawAdminFees
    function withdrawAdminFees(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner(), _amount), "Token transfer failed");
    }

    // --- Internal State Update ---

    function _updateEntityState(uint256 _tokenId) internal {
        EntityState storage state = entityStates[_tokenId];
        uint256 timeElapsed = block.timestamp - state.lastUpdateTime;

        if (timeElapsed > 0) {
            // Apply decay
            uint256 lifeForceDecay = timeElapsed * lifeForceDecayRatePerSecond;
            state.lifeForce = Math.max(0, state.lifeForce - lifeForceDecay);

            for (uint8 i = 0; i < STAT_COUNT; i++) {
                uint256 statDecay = timeElapsed * statDecayRatePerSecond[i];
                if (state.lifeForce > 0) { // Stats only decay if the entity is alive
                     if (i == STAT_STRENGTH) state.strength = Math.max(0, state.strength - statDecay);
                     else if (i == STAT_DEXTERITY) state.dexterity = Math.max(0, state.dexterity - statDecay);
                     else if (i == STAT_INTELLIGENCE) state.intelligence = Math.max(0, state.intelligence - statDecay);
                }
            }

            // Calculate yield (only if alive and bonded essence exists)
            if (state.lifeForce > 0 && state.bondedEssence > 0) {
                 uint256 yieldEarned = (state.bondedEssence * essenceYieldRatePerSecondPerBondedEssence * timeElapsed) / 1 ether; // Adjust division based on Essence token decimals
                 state.unclaimedEssenceYield += yieldEarned;
            }


            // Apply global event effects if active and entity is alive
            if (currentGlobalEventEndTime > block.timestamp && state.lifeForce > 0) {
                 // Example: Event increases yield multiplier
                 // uint256 eventYieldBonus = state.bondedEssence * currentGlobalEventIntensity * timeElapsed / 1 ether;
                 // state.unclaimedEssenceYield += eventYieldBonus;

                 // Example: Event boosts a random stat temporarily (hard to model 'temporary' on-chain easily)
                 // Alternative: Event modifies decay/yield rates for its duration (applied above via config setters called by trigger)
                 // Simpler approach for this example: Event adds a flat bonus yield
                 uint256 eventBonusYield = currentGlobalEventIntensity * timeElapsed / 1 ether;
                 state.unclaimedEssenceYield += eventBonusYield;
            }

            state.lastUpdateTime = block.timestamp;

            if (state.lifeForce == 0) {
                emit EntityDied(_tokenId);
            }

            emit EntityStateUpdated(
                _tokenId,
                state.strength,
                state.dexterity,
                state.intelligence,
                state.lifeForce,
                state.bondedEssence,
                state.unclaimedEssenceYield,
                state.lastUpdateTime
            );
        }
    }

    // --- Minting & Entity Creation ---

    // 4. mintInitialEntities
    // Admin can mint the very first entities
    function mintInitialEntities(address[] memory _owners, uint256 _initialEssenceBond) external onlyOwner {
        uint256 currentTokenId = entityNFT.tokenCounter(); // Get the next available token ID from the NFT contract

        for (uint i = 0; i < _owners.length; i++) {
            uint256 newTokenId = currentTokenId + i;
            entityNFT.mint(_owners[i], newTokenId); // Mint the NFT

            // Set initial state
            entityStates[newTokenId] = EntityState({
                strength: 100, // Base stats
                dexterity: 100,
                intelligence: 100,
                lifeForce: MAX_LIFE_FORCE, // Start full LifeForce
                bondedEssence: 0,
                lastUpdateTime: uint256(block.timestamp),
                unclaimedEssenceYield: 0
            });

            // Bond initial Essence if requested
            if (_initialEssenceBond > 0) {
                // Admin must pre-approve this contract to spend Essence
                require(essenceToken.transferFrom(msg.sender, address(this), _initialEssenceBond), "Essence transfer failed for initial bond");
                entityStates[newTokenId].bondedEssence = _initialEssenceBond;
            }

             emit EntityMinted(newTokenId, _owners[i], _initialEssenceBond);
             emit EntityStateUpdated(
                newTokenId,
                entityStates[newTokenId].strength,
                entityStates[newTokenId].dexterity,
                entityStates[newTokenId].intelligence,
                entityStates[newTokenId].lifeForce,
                entityStates[newTokenId].bondedEssence,
                entityStates[newTokenId].unclaimedEssenceYield,
                entityStates[newTokenId].lastUpdateTime
            );
        }
    }


    // 5. requestNewEntity
    // Users can request a new entity by depositing Essence
    function requestNewEntity(address _owner, uint256 _essenceDeposit) external {
        require(_essenceDeposit > 0, "Deposit must be greater than 0");

        bytes32 requestId = keccak256(abi.encodePacked(_owner, _essenceDeposit, block.timestamp, msg.sender));
        require(entityRequests[requestId].owner == address(0), "Request already exists"); // Prevent duplicate requests with same parameters at same time

        require(essenceToken.transferFrom(msg.sender, address(this), _essenceDeposit), "Essence deposit failed");

        entityRequests[requestId] = EntityRequest({
            owner: _owner,
            essenceDeposit: _essenceDeposit,
            fulfilled: false
        });
        entityRequestIds.push(requestId); // Add to the list of pending requests

        emit EntityRequestCreated(requestId, _owner, _essenceDeposit);
    }

    // 6. fulfillNewEntityRequest
    // Admin fulfills a request (can be triggered by off-chain logic, or manual)
    function fulfillNewEntityRequest(bytes32 _requestId, uint256 _initialEssenceBond) external onlyOwner {
        EntityRequest storage req = entityRequests[_requestId];
        require(req.owner != address(0), "Request does not exist");
        require(!req.fulfilled, "Request already fulfilled");

        // Use the deposited essence, the rest (_initialEssenceBond - req.essenceDeposit)
        // must be covered by contract's own balance or Admin's pre-approval if bond > deposit
        uint256 totalBondAmount = _initialEssenceBond;
        uint256 bondFromDeposit = Math.min(req.essenceDeposit, totalBondAmount);
        uint256 additionalBondNeeded = totalBondAmount > bondFromDeposit ? totalBondAmount - bondFromDeposit : 0;

        require(essenceToken.transfer(address(this), additionalBondNeeded), "Failed to cover additional bond"); // Contract must hold enough Essence or admin pre-approves

        // Mint the NFT
        uint256 newTokenId = entityNFT.tokenCounter(); // Get next available ID
        entityNFT.mint(req.owner, newTokenId);

        // Set initial state
        entityStates[newTokenId] = EntityState({
            strength: 100, // Base stats
            dexterity: 100,
            intelligence: 100,
            lifeForce: MAX_LIFE_FORCE, // Start full LifeForce
            bondedEssence: totalBondAmount,
            lastUpdateTime: uint256(block.timestamp),
            unclaimedEssenceYield: 0
        });

        // Mark request as fulfilled
        req.fulfilled = true;

        emit EntityRequestFulfilled(_requestId, newTokenId, totalBondAmount);
        emit EntityMinted(newTokenId, req.owner, totalBondAmount);
         emit EntityStateUpdated(
            newTokenId,
            entityStates[newTokenId].strength,
            entityStates[newTokenId].dexterity,
            entityStates[newTokenId].intelligence,
            entityStates[newTokenId].lifeForce,
            entityStates[newTokenId].bondedEssence,
            entityStates[newTokenId].unclaimedEssenceYield,
            entityStates[newTokenId].lastUpdateTime
        );

        // Any excess deposit not used for bond remains in the contract, could be admin fees etc.
    }


    // --- Entity Interaction Functions ---

    // 7. feedEntity
    function feedEntity(uint256 _tokenId, uint256 _amount) external onlyEntityOwner(_tokenId) entityExists(_tokenId) {
        _updateEntityState(_tokenId); // Apply decay before feeding

        EntityState storage state = entityStates[_tokenId];
        require(state.lifeForce > 0, "Entity is dead"); // Cannot feed a dead entity (must revive first)
        require(_amount > 0, "Amount must be greater than 0");

        uint256 lifeForceGain = (_amount * 1 ether) / feedCostPerPoint; // How many LF points gained per Essence
        uint256 actualEssenceCost = (lifeForceGain * feedCostPerPoint) / 1 ether; // Recalculate cost based on whole points gained
        if (actualEssenceCost == 0 && lifeForceGain > 0) actualEssenceCost = feedCostPerPoint / 1 ether; // Ensure minimum cost if any gain

        require(essenceToken.transferFrom(msg.sender, address(this), actualEssenceCost), "Essence transfer failed");

        state.lifeForce = Math.min(MAX_LIFE_FORCE, state.lifeForce + lifeForceGain);
        state.lastUpdateTime = block.timestamp; // Feeding resets the decay timer

        emit EntityFed(_tokenId, actualEssenceCost, state.lifeForce);
        emit EntityStateUpdated(
            _tokenId,
            state.strength,
            state.dexterity,
            state.intelligence,
            state.lifeForce,
            state.bondedEssence,
            state.unclaimedEssenceYield,
            state.lastUpdateTime
        );
    }

    // 8. boostStat
    function boostStat(uint256 _tokenId, uint8 _statIndex, uint256 _amount) external onlyEntityOwner(_tokenId) entityExists(_tokenId) {
        require(_statIndex < STAT_COUNT, "Invalid stat index");
         _updateEntityState(_tokenId); // Apply decay before boosting

        EntityState storage state = entityStates[_tokenId];
        require(state.lifeForce > 0, "Entity is dead");
         require(_amount > 0, "Amount must be greater than 0");

        uint256 statGain = (_amount * 1 ether) / statBoostCostPerPoint[_statIndex]; // How many stat points gained per Essence
        uint256 actualEssenceCost = (statGain * statBoostCostPerPoint[_statIndex]) / 1 ether; // Recalculate cost based on whole points gained
         if (actualEssenceCost == 0 && statGain > 0) actualEssenceCost = statBoostCostPerPoint[_statIndex] / 1 ether; // Ensure minimum cost if any gain

        require(essenceToken.transferFrom(msg.sender, address(this), actualEssenceCost), "Essence transfer failed");

        if (_statIndex == STAT_STRENGTH) state.strength = Math.min(MAX_STAT_VALUE, state.strength + statGain);
        else if (_statIndex == STAT_DEXTERITY) state.dexterity = Math.min(MAX_STAT_VALUE, state.dexterity + statGain);
        else if (_statIndex == STAT_INTELLIGENCE) state.intelligence = Math.min(MAX_STAT_VALUE, state.intelligence + statGain);

        state.lastUpdateTime = block.timestamp; // Boosting resets decay timer

        emit StatBoosted(_tokenId, _statIndex, actualEssenceCost, (_statIndex == STAT_STRENGTH ? state.strength : (_statIndex == STAT_DEXTERITY ? state.dexterity : state.intelligence)));
         emit EntityStateUpdated(
            _tokenId,
            state.strength,
            state.dexterity,
            state.intelligence,
            state.lifeForce,
            state.bondedEssence,
            state.unclaimedEssenceYield,
            state.lastUpdateTime
        );
    }

    // 9. bondEssenceToEntity
    function bondEssenceToEntity(uint256 _tokenId, uint256 _amount) external onlyEntityOwner(_tokenId) entityExists(_tokenId) {
        require(_amount > 0, "Amount must be greater than 0");
         _updateEntityState(_tokenId); // Calculate yield/decay before bonding

        EntityState storage state = entityStates[_tokenId];
         require(state.lifeForce > 0, "Entity is dead");

        require(essenceToken.transferFrom(msg.sender, address(this), _amount), "Essence transfer failed");

        state.bondedEssence += _amount;
        state.lastUpdateTime = block.timestamp; // Bonding resets timer (or just updates state?) Let's make it update state for consistency

        emit EssenceBonded(_tokenId, msg.sender, _amount, state.bondedEssence);
         emit EntityStateUpdated(
            _tokenId,
            state.strength,
            state.dexterity,
            state.intelligence,
            state.lifeForce,
            state.bondedEssence,
            state.unclaimedEssenceYield,
            state.lastUpdateTime
        );
    }

    // 10. unbondEssenceFromEntity
    function unbondEssenceFromEntity(uint256 _tokenId, uint256 _amount) external onlyEntityOwner(_tokenId) entityExists(_tokenId) {
         require(_amount > 0, "Amount must be greater than 0");
        _updateEntityState(_tokenId); // Calculate yield/decay before unbonding

        EntityState storage state = entityStates[_tokenId];
        require(state.bondedEssence >= _amount, "Not enough bonded essence");

        state.bondedEssence -= _amount;
         state.lastUpdateTime = block.timestamp; // Unbonding updates state

        require(essenceToken.transfer(msg.sender, _amount), "Essence transfer failed");

        emit EssenceUnbonded(_tokenId, msg.sender, _amount, state.bondedEssence);
         emit EntityStateUpdated(
            _tokenId,
            state.strength,
            state.dexterity,
            state.intelligence,
            state.lifeForce,
            state.bondedEssence,
            state.unclaimedEssenceYield,
            state.lastUpdateTime
        );
    }

    // 11. claimEssenceYield
    function claimEssenceYield(uint256 _tokenId) external onlyEntityOwner(_tokenId) entityExists(_tokenId) {
        _updateEntityState(_tokenId); // Calculate yield until now

        EntityState storage state = entityStates[_tokenId];
        uint256 yieldToClaim = state.unclaimedEssenceYield;
        require(yieldToClaim > 0, "No yield available");

        state.unclaimedEssenceYield = 0;
        // No need to update lastUpdateTime here, as it was updated in _updateEntityState

        require(essenceToken.transfer(msg.sender, yieldToClaim), "Essence transfer failed");

        emit EssenceYieldClaimed(_tokenId, msg.sender, yieldToClaim);
        emit EntityStateUpdated(
            _tokenId,
            state.strength,
            state.dexterity,
            state.intelligence,
            state.lifeForce,
            state.bondedEssence,
            state.unclaimedEssenceYield,
            state.lastUpdateTime
        );
    }

    // Optional: Revive mechanism for dead entities
    function reviveEntity(uint256 _tokenId, uint256 _essenceCost) external onlyEntityOwner(_tokenId) entityExists(_tokenId) {
         _updateEntityState(_tokenId); // Ensure state is current

        EntityState storage state = entityStates[_tokenId];
        require(state.lifeForce == 0, "Entity is not dead");
         require(_essenceCost > 0, "Revival cost must be greater than 0");

        require(essenceToken.transferFrom(msg.sender, address(this), _essenceCost), "Essence transfer failed for revival");

        // Set initial stats/LifeForce upon revival (can be less than initial mint)
        state.lifeForce = MAX_LIFE_FORCE / 2; // Example: Revives with half life
        state.strength = Math.max(1, state.strength / 2); // Example: Stats reduced upon death
        state.dexterity = Math.max(1, state.dexterity / 2);
        state.intelligence = Math.max(1, state.intelligence / 2);
        state.lastUpdateTime = block.timestamp; // Reset timer
        state.unclaimedEssenceYield = 0; // Reset unclaimed yield upon death/revival
        state.bondedEssence = 0; // Maybe unbond essence upon death? Or keep it bonded? Let's keep it bonded for now.

        emit EntityRevived(_tokenId);
         emit EntityStateUpdated(
            _tokenId,
            state.strength,
            state.dexterity,
            state.intelligence,
            state.lifeForce,
            state.bondedEssence,
            state.unclaimedEssenceYield,
            state.lastUpdateTime
        );
    }


    // --- Global Event Functions ---

    // 12. triggerGlobalEvolutionEvent
    function triggerGlobalEvolutionEvent(bytes32 _eventId, uint256 _intensity, uint64 _duration) external onlyOwner {
        require(currentGlobalEventEndTime <= block.timestamp, "Another event is already active");
        require(_duration > 0, "Event duration must be greater than 0");

        currentGlobalEventId = _eventId;
        currentGlobalEventIntensity = _intensity; // Interpretation of intensity depends on event logic within _updateEntityState
        currentGlobalEventEndTime = block.timestamp + _duration;

        emit GlobalEventTriggered(_eventId, _intensity, _duration, currentGlobalEventEndTime);
         // Note: Effects are applied incrementally in _updateEntityState when entities are interacted with or state is queried
    }

    // 13. endGlobalEvolutionEvent
    function endGlobalEvolutionEvent() external onlyOwner {
        require(currentGlobalEventEndTime > block.timestamp, "No active event to end");

        bytes32 endedEventId = currentGlobalEventId;
        currentGlobalEventEndTime = block.timestamp; // End it immediately

        // Reset event state variables (optional, can keep ID for history)
        // currentGlobalEventId = bytes32(0);
        // currentGlobalEventIntensity = 0;

        emit GlobalEventEnded(endedEventId);
    }

    // --- Query Functions (View) ---

    // 14. getEntityProperties
    function getEntityProperties(uint256 _tokenId) public view entityExists(_tokenId) returns (uint256 strength, uint256 dexterity, uint256 intelligence, uint256 lifeForce, uint256 bondedEssence, uint256 unclaimedEssenceYield) {
        EntityState memory state = entityStates[_tokenId];
        uint256 timeElapsed = block.timestamp - state.lastUpdateTime;

        // Calculate decay for reading (doesn't save state)
        uint256 currentLifeForce = state.lifeForce;
        uint256 currentStrength = state.strength;
        uint256 currentDexterity = state.dexterity;
        uint256 currentIntelligence = state.intelligence;
         uint256 currentUnclaimedYield = state.unclaimedEssenceYield;


        if (timeElapsed > 0) {
             uint256 lifeForceDecay = timeElapsed * lifeForceDecayRatePerSecond;
             currentLifeForce = Math.max(0, currentLifeForce - lifeForceDecay);

            if (currentLifeForce > 0) { // Stats only decay if entity is currently calculated as alive
                uint256 strengthDecay = timeElapsed * statDecayRatePerSecond[STAT_STRENGTH];
                currentStrength = Math.max(0, currentStrength - strengthDecay);

                uint256 dexterityDecay = timeElapsed * statDecayRatePerSecond[STAT_DEXTERITY];
                currentDexterity = Math.max(0, currentDexterity - dexterityDecay);

                uint256 intelligenceDecay = timeElapsed * statDecayRatePerSecond[STAT_INTELLIGENCE];
                currentIntelligence = Math.max(0, currentIntelligence - intelligenceDecay);
            }

            // Calculate potential yield for reading (doesn't add to stored unclaimed)
             if (state.lifeForce > 0 && state.bondedEssence > 0) { // Yield only accrues if entity was alive at last update
                 uint256 yieldEarned = (state.bondedEssence * essenceYieldRatePerSecondPerBondedEssence * timeElapsed) / 1 ether;
                 currentUnclaimedYield += yieldEarned;
            }

             // Apply global event bonus yield for reading (doesn't add to stored unclaimed)
             if (currentGlobalEventEndTime > block.timestamp && state.lifeForce > 0) { // Event must be active and entity alive (at last update)
                 uint256 eventBonusYield = currentGlobalEventIntensity * timeElapsed / 1 ether;
                 currentUnclaimedYield += eventBonusYield;
            }

        }


        return (
            currentStrength,
            currentDexterity,
            currentIntelligence,
            currentLifeForce,
            state.bondedEssence, // Bonded essence is static until interaction
            currentUnclaimedYield
        );
    }

    // 15. getEntityLastUpdateTime
    function getEntityLastUpdateTime(uint256 _tokenId) external view entityExists(_tokenId) returns (uint256) {
        return entityStates[_tokenId].lastUpdateTime;
    }

    // 16. getEssenceBondAmount
     function getEssenceBondAmount(uint256 _tokenId) external view entityExists(_tokenId) returns (uint256) {
        return entityStates[_tokenId].bondedEssence;
    }

    // 17. getEssenceYieldAvailable
    function getEssenceYieldAvailable(uint256 _tokenId) external view entityExists(_tokenId) returns (uint256) {
        // This view function calls the complex getter to get the calculated current yield
        (, , , , , uint256 calculatedYield) = getEntityProperties(_tokenId);
        return calculatedYield;
    }

    // 18. getStatDecayRate
    function getStatDecayRate(uint8 _statIndex) external view returns (uint256) {
        require(_statIndex < STAT_COUNT, "Invalid stat index");
        return statDecayRatePerSecond[_statIndex];
    }

    // 19. getLifeForceDecayRate
    function getLifeForceDecayRate() external view returns (uint256) {
        return lifeForceDecayRatePerSecond;
    }

    // 20. getEssenceYieldRate
    function getEssenceYieldRate() external view returns (uint256) {
        return essenceYieldRatePerSecondPerBondedEssence;
    }

    // 21. getStatBoostCost
     function getStatBoostCost(uint8 _statIndex, uint256 _amount) external view returns (uint256) {
         require(_statIndex < STAT_COUNT, "Invalid stat index");
         // Calculate cost for boosting _amount points
         uint256 statGain = (_amount * 1 ether) / statBoostCostPerPoint[_statIndex];
         uint256 cost = (statGain * statBoostCostPerPoint[_statIndex]) / 1 ether;
         if (cost == 0 && statGain > 0) cost = statBoostCostPerPoint[_statIndex] / 1 ether;
         return cost;
    }

    // 22. getFeedCost
    function getFeedCost(uint256 _tokenId, uint256 _desiredLifeForce) external view entityExists(_tokenId) returns (uint256) {
        EntityState memory state = entityStates[_tokenId];
        uint256 currentLifeForce = getEntityProperties(_tokenId).lifeForce; // Get current calculated LF
        require(_desiredLifeForce > currentLifeForce, "Desired LifeForce must be higher than current");
        require(_desiredLifeForce <= MAX_LIFE_FORCE, "Desired LifeForce exceeds maximum");

        uint256 lifeForceNeeded = _desiredLifeForce - currentLifeForce;
        uint256 cost = (lifeForceNeeded * feedCostPerPoint) / 1 ether;
         if (cost == 0 && lifeForceNeeded > 0) cost = feedCostPerPoint / 1 ether; // Ensure minimum cost if any gain
        return cost;
    }

     // 23. isEntityAlive
    function isEntityAlive(uint256 _tokenId) external view entityExists(_tokenId) returns (bool) {
        return getEntityProperties(_tokenId).lifeForce >= MIN_LIFE_FORCE_ALIVE;
    }

    // 24. getGlobalEventState
    function getGlobalEventState() external view returns (bytes32 eventId, uint256 intensity, uint256 endTime, bool isActive) {
        isActive = currentGlobalEventEndTime > block.timestamp;
        return (currentGlobalEventId, currentGlobalEventIntensity, currentGlobalEventEndTime, isActive);
    }

    // Additional function to list pending requests
    function getPendingEntityRequests() external view returns (bytes32[] memory) {
        bytes32[] memory pending;
        uint256 count = 0;
        for (uint i = 0; i < entityRequestIds.length; i++) {
            if (!entityRequests[entityRequestIds[i]].fulfilled) {
                count++;
            }
        }

        pending = new bytes32[](count);
        uint256 index = 0;
         for (uint i = 0; i < entityRequestIds.length; i++) {
            if (!entityRequests[entityRequestIds[i]].fulfilled) {
                pending[index] = entityRequestIds[i];
                index++;
            }
        }
        return pending;
    }

    // Additional function to get details of a specific request
    function getEntityRequestDetails(bytes32 _requestId) external view returns (address owner, uint256 essenceDeposit, bool fulfilled) {
        EntityRequest memory req = entityRequests[_requestId];
        return (req.owner, req.essenceDeposit, req.fulfilled);
    }

     // ERC721Holder receiver function (required if this contract will receive NFTs, e.g. for future features like trading or breeding pools)
     // Not directly used by the current set of functions, but good practice if NFTs might be sent here.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // This contract is not designed to hold entities directly in this version
        // but implementing the receiver allows future extensions.
        // Returning the selector signifies successful reception.
        // In a real scenario, add checks if this contract should *actually* receive this NFT.
        return this.onERC721Received.selector;
    }

    // Fallback/Receive to prevent accidental ETH sends
    receive() external payable {
        revert("ETH not accepted");
    }

    fallback() external payable {
        revert("Calls not accepted");
    }
}
```

**Explanation of Advanced/Creative Concepts Implemented:**

1.  **Dynamic State & Time-Based Decay:** The `EntityState` struct holds mutable properties for each NFT. The `_updateEntityState` internal function is the core mechanism that calculates how much decay has occurred since the entity was last interacted with (`lastUpdateTime`) and applies it. This makes the NFTs "alive" in the sense that they require maintenance.
2.  **Calculated Properties (View Functions):** View functions like `getEntityProperties` don't just return the stored state; they calculate the *current* state by applying decay based on `block.timestamp` *at the time of the view call*. This gives users an up-to-date view without requiring a transaction to update the stored state every time. The stored state is only updated by state-changing (transactional) functions.
3.  **Token Bonding:** The `bondedEssence` field in `EntityState` allows users to lock ERC20 tokens *within* the entity's state managed by this contract. This is different from just holding tokens in their wallet. These bonded tokens then contribute to passive yield calculation (`unclaimedEssenceYield`).
4.  **Yield Accrual:** Yield (`unclaimedEssenceYield`) is calculated incrementally based on bonded Essence, time elapsed, and potentially other factors like LifeForce or global events. It's stored and accumulated on-chain until claimed.
5.  **Global Events:** The `currentGlobalEvent` variables and the logic within `_updateEntityState` allow for external triggers (via the admin `triggerGlobalEvolutionEvent` function) to influence the state calculation for *all* entities based on the event's parameters (`intensity`). This adds a layer of environmental change to the ecosystem.
6.  **Entity Life Cycle (Decay & Revival):** Entities can "die" if their LifeForce reaches zero due to decay. This inactivates them for certain interactions (like feeding or boosting). A separate `reviveEntity` function provides a mechanism (at a cost) to bring them back to a functional state, potentially with penalties.
7.  **Entity Request System:** Instead of simple admin minting, a system where users `requestNewEntity` by depositing tokens, and an admin/oracle `fulfills` the request, adds a more complex minting process potentially involving off-chain computation or approval.

This contract provides a framework for a complex, evolving digital ecosystem built on NFTs and a native token, moving beyond static asset representation to incorporate dynamic state, maintenance mechanics, and environmental factors managed entirely on-chain (excluding off-chain components that might *call* the admin functions).