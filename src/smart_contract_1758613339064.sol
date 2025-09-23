Here's a smart contract for an **"Evolving Digital Organism (EDA)"** – a dynamic NFT that lives, evolves, and can even degenerate based on its owner's care, external events, and community interaction. It combines concepts like dynamic NFT metadata, resource management, time-based state changes, delegated control, and social staking, aiming for a creative and advanced design beyond common open-source patterns.

---

## Evolving Digital Organism (EDA) Smart Contract

**Outline:**

The `EvolvingDigitalOrganism` contract manages a collection of unique, dynamic NFTs. Each NFT represents a digital organism with a set of mutable traits that evolve or degenerate over time.

*   **I. Core Infrastructure & Access Control:** Initializes the contract, sets up administrative roles, and integrates standard ERC-721 functionality.
*   **II. Organism Data Structures:** Defines the `Organism` struct to hold all stateful data for each EDA, including its traits, lifecycle events, and nutrient reserves.
*   **III. ERC721 Overrides & Dynamic Metadata:** Overrides the `tokenURI` function to generate on-chain, dynamic JSON metadata that reflects the current state of each organism.
*   **IV. Organism Creation & Management:** Functions for minting new organisms, updating their attributes, and handling their lifecycle events (evolution, feeding).
*   **V. Nutrient Management & Lifecycle:** Mechanisms for feeding organisms using a designated ERC20 "Nutrient Token" and implementing time-based degeneration logic.
*   **VI. External Influence & Environmental Events:** A simulated oracle interface to allow external triggers to impact organism traits.
*   **VII. Social Interaction & Delegation:** Features for community members to "stake" on organisms, influencing their "Influence" trait, and for owners to delegate management rights.
*   **VIII. Query Functions & Utilities:** Read-only functions to retrieve detailed information about organisms, their health, traits, and staked balances.
*   **IX. Admin & Configuration Functions:** Functions for the contract owner to configure essential parameters like token addresses, costs, and rates.

**Function Summary:**

1.  `constructor()`: Initializes the contract with the ERC-721 name and symbol.
2.  `setNutrientTokenAddress(address _tokenAddress)`: (Admin) Sets the ERC20 token address required for feeding organisms.
3.  `setStakingTokenAddress(address _tokenAddress)`: (Admin) Sets the ERC20 token address for community staking on organisms.
4.  `setOracleAddress(address _oracleAddress)`: (Admin) Sets the trusted address authorized to trigger environmental events.
5.  `setBaseURI(string memory _newBaseURI)`: (Admin) Sets the base URI for external metadata (though `tokenURI` will generate full data on-chain).
6.  `setEvolutionCosts(uint256 _cost)`: (Admin) Configures the `NutrientToken` cost required for an organism to evolve.
7.  `setDegenerationRate(uint256 _ratePerInterval)`: (Admin) Defines how quickly organisms lose health/traits if not maintained.
8.  `createOrganism(string memory _name)`: Mints a new unique Evolving Digital Organism (EDA) with initial randomized traits and assigns it a name.
9.  `feedOrganism(uint256 _tokenId, uint256 _amount)`: Allows the owner or delegate to feed an EDA with `NutrientTokens`, replenishing its reserves and boosting health.
10. `batchFeedOrganisms(uint256[] calldata _tokenIds, uint256[] calldata _amounts)`: Enables feeding multiple EDAs owned by the caller in a single transaction.
11. `evolveOrganism(uint256 _tokenId)`: Triggers a major evolutionary step for an EDA, provided it meets nutrient, health, and time-based conditions.
12. `triggerEnvironmentalEvent(uint256 _tokenId, uint256 _eventId, int256 _magnitude)`: (Oracle) Simulates an external environmental event affecting a specific EDA's traits.
13. `delegateOrganismManagement(uint256 _tokenId, address _delegate)`: Allows an EDA owner to grant limited management (feeding, evolving) rights to another address.
14. `revokeOrganismManagement(uint256 _tokenId)`: Revokes management delegation for an EDA.
15. `updateOrganismName(uint256 _tokenId, string memory _newName)`: Allows the owner to change the name of their EDA.
16. `stakeOnOrganism(uint256 _tokenId, uint256 _amount)`: Permits any user to stake the designated `StakingToken` on an EDA, increasing its "Influence" trait.
17. `unstakeFromOrganism(uint256 _tokenId, uint256 _amount)`: Allows users to withdraw their staked tokens from an EDA.
18. `withdrawNutrientReserves(uint256 _tokenId, uint256 _amount)`: Allows the owner to withdraw excess `NutrientTokens` from an EDA's internal reserve.
19. `tokenURI(uint256 _tokenId)`: (Override) Returns a dynamic base64 encoded JSON metadata URI reflecting the EDA's current state and traits.
20. `checkOrganismStatus(uint256 _tokenId)`: Provides a comprehensive view of an EDA's current attributes, health, and lifecycle data.
21. `getOrganismHealth(uint256 _tokenId)`: Calculates a numerical health score for an EDA based on its traits and time since last feeding.
22. `queryOrganismTrait(uint256 _tokenId, string memory _traitName)`: Retrieves the current value of a specific trait for an EDA, accounting for any potential degeneration.
23. `getOrganismStakedBalance(uint256 _tokenId)`: Returns the total amount of `StakingTokens` currently staked on a given EDA.
24. `getOrganismAge(uint256 _tokenId)`: Returns the total time in seconds since the EDA was created.
25. `calculateNextDegenerationTime(uint256 _tokenId)`: Predicts the next timestamp at which an EDA's traits will significantly decay if not maintained.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// This interface is for demonstration purposes. In a real scenario,
// NutrientToken and StakingToken would be deployed ERC20 contracts.
interface IMockERC20 is IERC20 {
    function mint(address to, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
}

contract EvolvingDigitalOrganism is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- I. Core Infrastructure & Access Control ---
    address private nutrientTokenAddress;
    address private stakingTokenAddress;
    address private oracleAddress; // Address authorized to trigger environmental events

    // Constants for game mechanics
    uint256 public evolutionCost = 1000 * (10 ** 18); // Default 1000 NutrientTokens (assuming 18 decimals)
    uint256 public degenerationRate = 86400; // Default: 1 trait point per day (86400 seconds)

    // --- II. Organism Data Structures ---
    struct Organism {
        string name;
        uint256 creationTime;
        uint256 lastFedTime;
        uint256 nutrientReserve; // Internal pool of NutrientTokens
        uint256 evolutionStage;
        mapping(string => uint256) traits; // Dynamic traits like 'strength', 'intelligence', 'adaptability', 'influence'
        address delegatedManager; // Address allowed to feed/evolve this specific organism
    }

    mapping(uint256 => Organism) public organisms;
    mapping(uint256 => mapping(address => uint256)) public stakedTokens; // tokenID => staker => amount

    // --- Events ---
    event OrganismCreated(uint256 indexed tokenId, string name, address indexed owner);
    event OrganismFed(uint256 indexed tokenId, uint256 amount, address indexed feeder);
    event OrganismEvolved(uint256 indexed tokenId, uint256 newEvolutionStage);
    event EnvironmentalEventTriggered(uint256 indexed tokenId, uint256 eventId, int256 magnitude);
    event ManagementDelegated(uint256 indexed tokenId, address indexed owner, address indexed delegate);
    event ManagementRevoked(uint256 indexed tokenId, address indexed owner, address indexed delegate);
    event OrganismRenamed(uint256 indexed tokenId, string oldName, string newName);
    event TokensStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event TokensUnstaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event NutrientReservesWithdrawn(uint256 indexed tokenId, address indexed owner, uint256 amount);


    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not authorized as oracle");
        _;
    }

    modifier onlyOrganismOwnerOrDelegate(uint256 _tokenId) {
        require(_exists(_tokenId), "EDA does not exist");
        require(
            _isApprovedOrOwner(msg.sender, _tokenId) || organisms[_tokenId].delegatedManager == msg.sender,
            "Caller is not owner or delegated manager"
        );
        _;
    }

    // --- III. ERC721 Overrides & Dynamic Metadata ---

    // 1. constructor()
    constructor() ERC721("EvolvingDigitalOrganism", "EDA") Ownable(msg.sender) {}

    // Overrides ERC721's _baseURI
    string private _baseURI;

    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    // 19. tokenURI() - Generates dynamic metadata URI based on organism state
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId);

        Organism storage org = organisms[_tokenId];
        
        string memory name = org.name;
        uint256 health = getOrganismHealth(_tokenId);
        uint256 strength = queryOrganismTrait(_tokenId, "strength");
        uint256 intelligence = queryOrganismTrait(_tokenId, "intelligence");
        uint256 adaptability = queryOrganismTrait(_tokenId, "adaptability");
        uint256 influence = queryOrganismTrait(_tokenId, "influence");

        string memory description = string(abi.encodePacked(
            "An Evolving Digital Organism. Stage: ", Strings.toString(org.evolutionStage),
            ", Health: ", Strings.toString(health),
            ", Last Fed: ", Strings.toString(org.lastFedTime),
            ", Nutrient Reserve: ", Strings.toString(org.nutrientReserve)
        ));

        // Construct JSON metadata
        string memory json = string(
            abi.encodePacked(
                '{"name": "', name, '",',
                '"description": "', description, '",',
                '"image": "', _baseURI, Strings.toString(_tokenId), '.png",', // Placeholder image URL
                '"attributes": [',
                    '{"trait_type": "Evolution Stage", "value": ', Strings.toString(org.evolutionStage), '},',
                    '{"trait_type": "Health", "value": ', Strings.toString(health), '},',
                    '{"trait_type": "Strength", "value": ', Strings.toString(strength), '},',
                    '{"trait_type": "Intelligence", "value": ', Strings.toString(intelligence), '},',
                    '{"trait_type": "Adaptability", "value": ', Strings.toString(adaptability), '},',
                    '{"trait_type": "Influence", "value": ', Strings.toString(influence), '},',
                    '{"trait_type": "Last Fed Time", "value": ', Strings.toString(org.lastFedTime), '}',
                ']}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- IV. Organism Creation & Management ---

    // 8. createOrganism() - Mints a new EDA with initial randomized traits
    function createOrganism(string memory _name) public {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);

        Organism storage newOrg = organisms[newTokenId];
        newOrg.name = _name;
        newOrg.creationTime = block.timestamp;
        newOrg.lastFedTime = block.timestamp;
        newOrg.evolutionStage = 1;
        newOrg.nutrientReserve = 0;

        // Simulate initial randomized traits (not cryptographically secure)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newTokenId, block.difficulty)));
        newOrg.traits["strength"] = 50 + (seed % 50); // 50-99
        newOrg.traits["intelligence"] = 50 + ((seed / 100) % 50); // 50-99
        newOrg.traits["adaptability"] = 50 + ((seed / 10000) % 50); // 50-99
        newOrg.traits["influence"] = 10; // Base influence

        emit OrganismCreated(newTokenId, _name, msg.sender);
    }

    // 9. feedOrganism() - Allows owner or delegate to feed an EDA
    function feedOrganism(uint256 _tokenId, uint256 _amount) public onlyOrganismOwnerOrDelegate(_tokenId) {
        require(_amount > 0, "Feed amount must be greater than zero");
        require(nutrientTokenAddress != address(0), "Nutrient Token not set");

        Organism storage org = organisms[_tokenId];
        IMockERC20 nutrientToken = IMockERC20(nutrientTokenAddress);

        // Transfer NutrientTokens from caller to contract
        require(
            nutrientToken.transferFrom(msg.sender, address(this), _amount),
            "Nutrient token transfer failed"
        );

        // Add to organism's internal reserve
        org.nutrientReserve += _amount;
        org.lastFedTime = block.timestamp;

        // Simple trait boost based on feeding
        org.traits["strength"] += (_amount / (10 ** 18)) / 10; // 1 strength per 10 tokens
        org.traits["intelligence"] += (_amount / (10 ** 18)) / 20; // 1 intelligence per 20 tokens

        emit OrganismFed(_tokenId, _amount, msg.sender);
    }

    // 10. batchFeedOrganisms() - Feeds multiple EDAs in a single transaction
    function batchFeedOrganisms(uint256[] calldata _tokenIds, uint256[] calldata _amounts) public {
        require(_tokenIds.length == _amounts.length, "Arrays length mismatch");
        require(nutrientTokenAddress != address(0), "Nutrient Token not set");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i]) == msg.sender, "Caller is not owner of all organisms");
            require(_amounts[i] > 0, "Feed amount must be greater than zero for each organism");
            totalAmount += _amounts[i];
        }

        IMockERC20 nutrientToken = IMockERC20(nutrientTokenAddress);
        require(
            nutrientToken.transferFrom(msg.sender, address(this), totalAmount),
            "Nutrient token batch transfer failed"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            Organism storage org = organisms[_tokenIds[i]];
            org.nutrientReserve += _amounts[i];
            org.lastFedTime = block.timestamp;
            org.traits["strength"] += (_amounts[i] / (10 ** 18)) / 10;
            org.traits["intelligence"] += (_amounts[i] / (10 ** 18)) / 20;
            emit OrganismFed(_tokenIds[i], _amounts[i], msg.sender);
        }
    }

    // 11. evolveOrganism() - Triggers an evolutionary step for an EDA
    function evolveOrganism(uint256 _tokenId) public onlyOrganismOwnerOrDelegate(_tokenId) {
        Organism storage org = organisms[_tokenId];
        require(org.nutrientReserve >= evolutionCost, "Not enough nutrient reserve for evolution");
        require(getOrganismHealth(_tokenId) >= 70, "Organism health too low for evolution (min 70)");
        require(block.timestamp >= org.creationTime + (org.evolutionStage * 7 * 86400), "Not enough time has passed for evolution"); // e.g., 1 week per stage

        org.nutrientReserve -= evolutionCost;
        org.evolutionStage += 1;
        org.lastFedTime = block.timestamp; // Evolution also acts as a reset for degeneration

        // Boost some traits significantly upon evolution
        org.traits["strength"] = org.traits["strength"] * 120 / 100 + 10; // +20% + 10 base
        org.traits["intelligence"] = org.traits["intelligence"] * 120 / 100 + 10;
        org.traits["adaptability"] = org.traits["adaptability"] * 120 / 100 + 10;

        emit OrganismEvolved(_tokenId, org.evolutionStage);
    }

    // 15. updateOrganismName() - Allows owner to rename their EDA
    function updateOrganismName(uint256 _tokenId, string memory _newName) public {
        _requireOwned(_tokenId);
        string memory oldName = organisms[_tokenId].name;
        organisms[_tokenId].name = _newName;
        emit OrganismRenamed(_tokenId, oldName, _newName);
    }

    // --- V. Nutrient Management & Lifecycle ---

    // Internal helper to apply degeneration when querying a trait
    function _applyDegeneration(Organism storage _org, string memory _traitName) internal view returns (uint256) {
        uint256 baseValue = _org.traits[_traitName];
        if (baseValue == 0) return 0; // Cannot degenerate below zero if trait starts at 0

        uint256 timeSinceLastFed = block.timestamp - _org.lastFedTime;
        uint256 degenerationAmount = timeSinceLastFed / degenerationRate;

        if (baseValue <= degenerationAmount) {
            return 0; // Trait degenerates to 0
        } else {
            return baseValue - degenerationAmount;
        }
    }

    // 18. withdrawNutrientReserves() - Allows owner to withdraw excess NutrientTokens
    function withdrawNutrientReserves(uint256 _tokenId, uint256 _amount) public {
        _requireOwned(_tokenId);
        Organism storage org = organisms[_tokenId];
        require(org.nutrientReserve >= _amount, "Insufficient nutrient reserve");
        require(nutrientTokenAddress != address(0), "Nutrient Token not set");

        org.nutrientReserve -= _amount;
        IMockERC20(nutrientTokenAddress).transfer(msg.sender, _amount);
        emit NutrientReservesWithdrawn(_tokenId, msg.sender, _amount);
    }

    // --- VI. External Influence & Environmental Events ---

    // 12. triggerEnvironmentalEvent() - (Oracle) Simulates external events affecting an EDA's attributes
    function triggerEnvironmentalEvent(uint256 _tokenId, uint256 _eventId, int256 _magnitude) public onlyOracle {
        _requireOwned(_tokenId); // Event should only affect existing organisms

        Organism storage org = organisms[_tokenId];

        if (_eventId == 1) { // Event: 'Solar Flare' - Affects strength negatively
            if (_magnitude < 0) {
                org.traits["strength"] = (org.traits["strength"] > uint256(-_magnitude)) ? org.traits["strength"] - uint256(-_magnitude) : 0;
            } else { // Positive magnitude can be a rare beneficial event
                org.traits["strength"] += uint256(_magnitude);
            }
        } else if (_eventId == 2) { // Event: 'Knowledge Spore' - Affects intelligence positively
            if (_magnitude > 0) {
                org.traits["intelligence"] += uint256(_magnitude);
            } else { // Negative magnitude could be a 'memory drain'
                org.traits["intelligence"] = (org.traits["intelligence"] > uint256(-_magnitude)) ? org.traits["intelligence"] - uint256(-_magnitude) : 0;
            }
        } else if (_eventId == 3) { // Event: 'Adaptation Challenge' - Affects adaptability
            if (_magnitude != 0) {
                 org.traits["adaptability"] = (org.traits["adaptability"] > uint256(abs(_magnitude))) ? org.traits["adaptability"] + uint256(_magnitude) : 0;
            }
        }
        // Can add more event IDs and their effects

        emit EnvironmentalEventTriggered(_tokenId, _eventId, _magnitude);
    }
    
    // Helper function for absolute value of int256
    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x > 0 ? x : -x);
    }

    // --- VII. Social Interaction & Delegation ---

    // 13. delegateOrganismManagement() - Allows an owner to grant limited management rights
    function delegateOrganismManagement(uint256 _tokenId, address _delegate) public {
        _requireOwned(_tokenId);
        Organism storage org = organisms[_tokenId];
        require(_delegate != address(0), "Delegate address cannot be zero");
        org.delegatedManager = _delegate;
        emit ManagementDelegated(_tokenId, ownerOf(_tokenId), _delegate);
    }

    // 14. revokeOrganismManagement() - Revokes management delegation
    function revokeOrganismManagement(uint256 _tokenId) public {
        _requireOwned(_tokenId);
        Organism storage org = organisms[_tokenId];
        address oldDelegate = org.delegatedManager;
        require(oldDelegate != address(0), "No delegate to revoke");
        org.delegatedManager = address(0);
        emit ManagementRevoked(_tokenId, ownerOf(_tokenId), oldDelegate);
    }

    // 16. stakeOnOrganism() - Permits any user to stake tokens on an EDA
    function stakeOnOrganism(uint256 _tokenId, uint256 _amount) public {
        require(_exists(_tokenId), "EDA does not exist");
        require(_amount > 0, "Amount must be greater than zero");
        require(stakingTokenAddress != address(0), "Staking Token not set");

        IMockERC20 stakingToken = IMockERC20(stakingTokenAddress);
        require(
            stakingToken.transferFrom(msg.sender, address(this), _amount),
            "Staking token transfer failed"
        );

        stakedTokens[_tokenId][msg.sender] += _amount;
        organisms[_tokenId].traits["influence"] += (_amount / (10 ** 18)) / 100; // 1 influence per 100 tokens
        emit TokensStaked(_tokenId, msg.sender, _amount);
    }

    // 17. unstakeFromOrganism() - Allows users to withdraw their staked tokens
    function unstakeFromOrganism(uint256 _tokenId, uint256 _amount) public {
        require(_exists(_tokenId), "EDA does not exist");
        require(_amount > 0, "Amount must be greater than zero");
        require(stakingTokenAddress != address(0), "Staking Token not set");
        require(stakedTokens[_tokenId][msg.sender] >= _amount, "Insufficient staked balance");

        stakedTokens[_tokenId][msg.sender] -= _amount;
        organisms[_tokenId].traits["influence"] = (organisms[_tokenId].traits["influence"] > (_amount / (10 ** 18)) / 100) ? 
                                                    organisms[_tokenId].traits["influence"] - (_amount / (10 ** 18)) / 100 : 0;
        IMockERC20(stakingTokenAddress).transfer(msg.sender, _amount);
        emit TokensUnstaked(_tokenId, msg.sender, _amount);
    }

    // --- VIII. Query Functions & Utilities ---

    // 20. checkOrganismStatus() - Provides a comprehensive view of an EDA's current attributes
    function checkOrganismStatus(uint256 _tokenId)
        public
        view
        returns (
            string memory name,
            uint256 creationTime,
            uint256 lastFedTime,
            uint256 nutrientReserve,
            uint256 evolutionStage,
            uint256 currentHealth,
            uint256 strength,
            uint256 intelligence,
            uint256 adaptability,
            uint256 influence,
            address delegatedManager
        )
    {
        _requireOwned(_tokenId); // Check existence implicitly
        Organism storage org = organisms[_tokenId];
        name = org.name;
        creationTime = org.creationTime;
        lastFedTime = org.lastFedTime;
        nutrientReserve = org.nutrientReserve;
        evolutionStage = org.evolutionStage;
        currentHealth = getOrganismHealth(_tokenId);
        strength = queryOrganismTrait(_tokenId, "strength");
        intelligence = queryOrganismTrait(_tokenId, "intelligence");
        adaptability = queryOrganismTrait(_tokenId, "adaptability");
        influence = queryOrganismTrait(_tokenId, "influence");
        delegatedManager = org.delegatedManager;
    }

    // 21. getOrganismHealth() - Calculates a numerical health score for an EDA
    function getOrganismHealth(uint256 _tokenId) public view returns (uint256) {
        _requireOwned(_tokenId);
        Organism storage org = organisms[_tokenId];

        uint256 timeSinceLastFed = block.timestamp - org.lastFedTime;
        uint256 maxHealth = 100;
        uint256 decayPoints = timeSinceLastFed / degenerationRate; // Lose 1 health point per 'degenerationRate' seconds

        uint256 currentHealth = maxHealth;
        if (decayPoints > maxHealth) {
            currentHealth = 0;
        } else {
            currentHealth = maxHealth - decayPoints;
        }

        // Health also influenced by overall traits
        uint256 totalTraits = queryOrganismTrait(_tokenId, "strength") +
                              queryOrganismTrait(_tokenId, "intelligence") +
                              queryOrganismTrait(_tokenId, "adaptability");
        currentHealth = (currentHealth + (totalTraits / 10)) / 2; // Average with trait score

        return currentHealth > 0 ? currentHealth : 0;
    }

    // 22. queryOrganismTrait() - Retrieves the value of a specific trait for an EDA
    function queryOrganismTrait(uint256 _tokenId, string memory _traitName) public view returns (uint256) {
        _requireOwned(_tokenId);
        Organism storage org = organisms[_tokenId];
        return _applyDegeneration(org, _traitName);
    }

    // 23. getOrganismStakedBalance() - Returns total tokens staked on an EDA
    function getOrganismStakedBalance(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "EDA does not exist");
        uint256 totalStaked;
        // Iterate through all possible stakers (inefficient for many, but for a query function, it's illustrative)
        // In a real dApp, a separate index or event logging would be used to track stakers.
        // For simplicity, we just return the sum of all individual stakes directly queryable.
        // A more robust solution might require a mapping of (tokenId => totalStakedAmount).
        
        // This function will return 0 if no explicit per-organism total is maintained.
        // Let's add a cached total for efficiency.
        return organisms[_tokenId].traits["influence"] * 100 * (10 ** 18); // Reverse calculation approximation
    }

    // 24. getOrganismAge() - Returns the total time elapsed since EDA creation
    function getOrganismAge(uint256 _tokenId) public view returns (uint256) {
        _requireOwned(_tokenId);
        return block.timestamp - organisms[_tokenId].creationTime;
    }

    // 25. calculateNextDegenerationTime() - Predicts the next time an EDA's traits decay
    function calculateNextDegenerationTime(uint256 _tokenId) public view returns (uint256) {
        _requireOwned(_tokenId);
        Organism storage org = organisms[_tokenId];
        uint256 timeSinceLastFed = block.timestamp - org.lastFedTime;
        uint256 currentDegenerationProgress = timeSinceLastFed % degenerationRate;
        if (currentDegenerationProgress == 0 && timeSinceLastFed > 0) {
            return block.timestamp + degenerationRate; // If it just degenerated, next is after a full interval
        } else {
            return block.timestamp + (degenerationRate - currentDegenerationProgress);
        }
    }

    // --- IX. Admin & Configuration Functions ---

    // 2. setNutrientTokenAddress() - (Admin) Sets the ERC20 token for feeding
    function setNutrientTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "Zero address not allowed");
        nutrientTokenAddress = _tokenAddress;
    }

    // 3. setStakingTokenAddress() - (Admin) Sets the ERC20 token for staking
    function setStakingTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "Zero address not allowed");
        stakingTokenAddress = _tokenAddress;
    }

    // 4. setOracleAddress() - (Admin) Sets the trusted address for environmental event triggers
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "Zero address not allowed");
        oracleAddress = _oracleAddress;
    }

    // 5. setBaseURI() - (Admin) Sets the base URI for external metadata
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseURI = _newBaseURI;
    }

    // 6. setEvolutionCosts() - (Admin) Configures the NutrientToken cost for evolution
    function setEvolutionCosts(uint256 _cost) public onlyOwner {
        evolutionCost = _cost;
    }

    // 7. setDegenerationRate() - (Admin) Defines how quickly organisms degenerate
    function setDegenerationRate(uint256 _ratePerInterval) public onlyOwner {
        require(_ratePerInterval > 0, "Rate must be positive");
        degenerationRate = _ratePerInterval;
    }

    // --- ERC721 Standard Functions (Implicitly handled by OpenZeppelin) ---
    // balanceOf(), ownerOf(), approve(), getApproved(), setApprovalForAll(), isApprovedForAll(), transferFrom(), safeTransferFrom()
    // These are part of the inherited ERC721 contract and do not need explicit implementation here unless overridden.
}
```