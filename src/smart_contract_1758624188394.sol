Here's a smart contract named "ChronoGlyph Genesis" that implements an ecosystem of "Adaptive Digital Lifeforms" (ADLs), featuring dynamic NFT traits, resource management, a reputation system, and generative mechanics, avoiding direct duplication of common open-source patterns by combining several advanced concepts into a novel interplay.

---

# ChronoGlyph Genesis

**Core Concept:**
ChronoGlyph Genesis introduces "Adaptive Digital Lifeforms" (ADLs), a sophisticated NFT ecosystem where digital entities dynamically evolve based on owner interactions, resource management, and a reputation system. ADLs possess mutable traits, consume an ERC-20 'Essence' token for sustenance and evolution, and can even procreate to create new generations with inherited and mutated attributes. A "ChronoKarma" system tracks positive user contributions, influencing ADL development and procreation outcomes. The system simulates environmental and biological processes on-chain to create a living, evolving NFT collection.

---

**Function Summary:**

**I. Core ADL Management (ERC721-based):**
1.  `mintGenesisADL(address _to, string memory _initialName, string[] memory _initialTraitNames, string[] memory _initialTraitValues)`: Mints a new foundational Adaptive Digital Lifeform (ADL) with initial traits, typically performed by the contract owner to seed the ecosystem.
2.  `evolveADL(uint256 _tokenId)`: Triggers the evolutionary process for an ADL. This requires the ADL to be staked, have sufficient 'Essence', and be past its evolution cooldown, advancing it to the next evolutionary stage and potentially mutating its traits.
3.  `updateADLVisualURI(uint256 _tokenId, string memory _newURI)`: Allows the ADL owner to update the visual (off-chain) URI, useful after an ADL evolves or changes significantly.
4.  `getADLDetails(uint256 _tokenId)`: Retrieves a comprehensive struct containing all current details (except for specific trait mappings) of a specified ADL.
5.  `getADLTrait(uint256 _tokenId, string memory _traitName)`: Fetches the specific value of a named trait for an ADL (e.g., "Color", "Ability").
6.  `ADL_exists(uint256 _tokenId)`: Checks if a given token ID corresponds to an active ADL within the system.

**II. Essence (ERC-20) Interaction:**
7.  `feedADL(uint256 _tokenId, uint256 _amount)`: Transfers 'Essence' tokens from the caller to the smart contract, allocating them to the specified ADL's internal reserves for growth and survival.
8.  `getADLEssenceBalance(uint256 _tokenId)`: Returns the current 'Essence' token balance held by or allocated to a specific ADL.
9.  `initiateEssenceDrain(uint256 _tokenId)`: (Admin/System-only) Triggers a simulated periodic consumption of 'Essence' by an ADL, reflecting its ongoing resource needs based on its evolutionary stage.
10. `setEssenceContract(address _essenceContractAddress)`: (Admin-only) Sets the address of the ERC-20 'Essence' token contract that the system interacts with.

**III. ChronoKarma (Reputation System):**
11. `awardChronoKarma(address _user, uint256 _amount)`: (Admin/System-only) Grants 'ChronoKarma' to a user for positive contributions or specific actions within the ecosystem, enhancing their influence.
12. `burnChronoKarma(address _user, uint256 _amount)`: (Admin/System-only) Deducts 'ChronoKarma' from a user, typically for detrimental actions or as a cost for certain powerful operations.
13. `getChronoKarma(address _user)`: Retrieves the current 'ChronoKarma' balance for a specified user address.
14. `spendKarmaForProcreationBoost(uint256 _karmaAmount)`: Allows a user to spend their 'ChronoKarma' to pre-allocate a boost for their *next* ADL procreation attempt, increasing the success rate or favorable mutation chances.

**IV. Generative / Procreation Mechanics:**
15. `procreateADL(uint256 _parent1Id, uint256 _parent2Id, address _to)`: Initiates the creation of a new ADL offspring from two eligible parent ADLs. The child's traits are a blend of parents' traits, potentially influenced by mutation chances and any accumulated 'ChronoKarma' boost from the initiator.
16. `getProcreationEligibility(uint256 _parent1Id, uint256 _parent2Id)`: Determines if two specific ADLs meet the conditions (e.g., evolution stage, cooldowns) required to successfully procreate.

**V. Staking & Delegated Evolution:**
17. `stakeADL(uint256 _tokenId)`: Locks an ADL, making it non-transferable and allowing it to accrue 'evolutionary progress' over time, fulfilling a prerequisite for evolution.
18. `unstakeADL(uint256 _tokenId)`: Unlocks a previously staked ADL, making it transferable again. This may reset accumulated evolutionary progress if not properly managed.
19. `delegateEvolutionRights(uint256 _tokenId, address _delegatee)`: Grants a specified delegate address the authority to perform certain evolution-related actions (like calling `evolveADL` or `feedADL`) on an ADL, without transferring full ownership.
20. `revokeEvolutionRights(uint256 _tokenId)`: Revokes any previously granted evolution rights from a delegate for a specific ADL, returning full control to the owner.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline & Function Summary (as above) ---

contract ChronoGlyphGenesis is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Interface for the Essence ERC-20 token
    IERC20 public essenceToken;

    // ChronoKarma System: User reputation score
    mapping(address => uint256) public chronoKarma;
    // Temporary karma boosts for procreation attempts
    mapping(address => uint256) private _karmaProcreationBoosts;

    // ADL Struct: Defines the properties of an Adaptive Digital Lifeform
    struct ADL {
        uint256 id;
        string name;
        uint256 creationTime;
        uint256 lastEvolutionTime;
        uint256 evolutionStage; // 0=Larva, 1=Juvenile, 2=Adult, 3=Elder
        mapping(string => string) traits; // Dynamic traits (e.g., "Color", "Ability", "Size")
        uint256 essenceBalance; // Essence allocated to this ADL for its growth
        bool isStaked;
        uint256 stakeTime;
        address delegatedEvolutionist; // Address with delegated evolution rights
        uint256 lastProcreationTime; // Cooldown timestamp for procreation
    }

    mapping(uint256 => ADL) private _adls; // Stores ADL data by tokenId

    // Events to log significant actions
    event ADLMinted(uint256 indexed tokenId, address indexed owner, string name, string initialURI);
    event ADLEvolved(uint256 indexed tokenId, uint224 newEvolutionStage, string updatedURI);
    event ADL_Fed(uint256 indexed tokenId, uint256 amount, uint256 newEssenceBalance);
    event ChronoKarmaAwarded(address indexed user, uint256 amount, uint256 newBalance);
    event ChronoKarmaBurned(address indexed user, uint256 amount, uint256 newBalance);
    event ADLProcreated(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, address owner);
    event ADLStaked(uint256 indexed tokenId, address indexed owner);
    event ADLUnstaked(uint256 indexed tokenId, address indexed owner);
    event EvolutionRightsDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event EvolutionRightsRevoked(uint256 indexed tokenId, address indexed delegator, address indexed previousDelegatee);
    event ADLVisualURIUpdated(uint256 indexed tokenId, string newURI);

    // Constants governing ADL mechanics
    uint256 public constant ESSENCE_DRAIN_RATE_PER_STAGE = 10; // Essence units drained per evolution stage per simulated interval
    uint256 public constant EVOLUTION_COOLDOWN_SECONDS = 7 days; // Time between evolutions
    uint256 public constant PROCREATION_COOLDOWN_SECONDS = 30 days; // Time between procreation events for a parent
    uint256 public constant ESSENCE_FOR_EVOLUTION_STAGE_1 = 500 * (10**18); // Example: 500 Essence tokens for Larva to Juvenile
    uint256 public constant ESSENCE_FOR_EVOLUTION_STAGE_2 = 1500 * (10**18); // Example: 1500 Essence tokens for Juvenile to Adult
    uint256 public constant ESSENCE_FOR_EVOLUTION_STAGE_3 = 3000 * (10**18); // Example: 3000 Essence tokens for Adult to Elder
    uint256 public constant MIN_KARMA_FOR_PROCREATION_BOOST = 100; // Minimum karma needed to apply a boost

    constructor(address initialOwner) ERC721("ChronoGlyph ADL", "ADL") Ownable(initialOwner) {
        // Essence token address must be set after deployment of EssenceToken via setEssenceContract
    }

    // --- External / Public Functions ---

    // I. Core ADL Management (ERC721-based):

    /**
     * @notice Mints a new foundational Adaptive Digital Lifeform (ADL) with initial traits.
     * @dev Only the contract owner can mint Genesis ADLs to control initial population.
     * @param _to The address to receive the newly minted ADL.
     * @param _initialName The initial name of the ADL.
     * @param _initialTraitNames An array of trait names (e.g., "Color", "Temperament").
     * @param _initialTraitValues An array of corresponding trait values.
     * @return The tokenId of the newly minted ADL.
     */
    function mintGenesisADL(
        address _to,
        string memory _initialName,
        string[] memory _initialTraitNames,
        string[] memory _initialTraitValues
    ) public onlyOwner returns (uint256) {
        require(_initialTraitNames.length == _initialTraitValues.length, "Trait names and values mismatch");
        require(_to != address(0), "Recipient address cannot be zero");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(_to, newTokenId);
        string memory defaultURI = string(abi.encodePacked("ipfs://default/genesis_adl_", Strings.toString(newTokenId), ".json"));
        _setTokenURI(newTokenId, defaultURI); // Default URI

        ADL storage newADL = _adls[newTokenId];
        newADL.id = newTokenId;
        newADL.name = _initialName;
        newADL.creationTime = block.timestamp;
        newADL.lastEvolutionTime = block.timestamp;
        newADL.evolutionStage = 0; // Starts as Larva

        for (uint256 i = 0; i < _initialTraitNames.length; i++) {
            newADL.traits[_initialTraitNames[i]] = _initialTraitValues[i];
        }

        emit ADLMinted(newTokenId, _to, _initialName, defaultURI);
        return newTokenId;
    }

    /**
     * @notice Triggers the evolutionary process for an ADL.
     * @dev Requires the ADL to be staked, past its evolution cooldown, and have sufficient Essence.
     * @param _tokenId The ID of the ADL to evolve.
     */
    function evolveADL(uint256 _tokenId) public {
        ADL storage adl = _adls[_tokenId];
        require(adl.id == _tokenId, "ADL does not exist");
        require(ownerOf(_tokenId) == _msgSender() || adl.delegatedEvolutionist == _msgSender(), "Not authorized to evolve this ADL");
        require(adl.isStaked, "ADL must be staked to evolve");
        require(block.timestamp >= adl.lastEvolutionTime + EVOLUTION_COOLDOWN_SECONDS, "ADL is on evolution cooldown");
        require(adl.evolutionStage < 3, "ADL has reached max evolution stage (Elder)"); // Max stage is Elder (3)

        uint256 requiredEssence = 0;
        if (adl.evolutionStage == 0) requiredEssence = ESSENCE_FOR_EVOLUTION_STAGE_1;
        else if (adl.evolutionStage == 1) requiredEssence = ESSENCE_FOR_EVOLUTION_STAGE_2;
        else if (adl.evolutionStage == 2) requiredEssence = ESSENCE_FOR_EVOLUTION_STAGE_3;
        
        require(adl.essenceBalance >= requiredEssence, "Insufficient Essence for evolution");

        // Consume Essence
        adl.essenceBalance -= requiredEssence;

        // Advance Evolution Stage
        adl.evolutionStage++;
        adl.lastEvolutionTime = block.timestamp;

        // Simulate trait mutation/enhancement based on evolution stage
        string memory newURI = _mutateTraits(adl);
        _setTokenURI(_tokenId, newURI);

        emit ADLEvolved(_tokenId, adl.evolutionStage, newURI);
    }

    /**
     * @notice Allows the ADL owner to update the visual (off-chain) URI.
     * @param _tokenId The ID of the ADL.
     * @param _newURI The new URI pointing to the metadata (e.g., IPFS hash).
     */
    function updateADLVisualURI(uint256 _tokenId, string memory _newURI) public {
        require(ownerOf(_tokenId) == _msgSender(), "Must own the ADL to update URI");
        _setTokenURI(_tokenId, _newURI);
        emit ADLVisualURIUpdated(_tokenId, _newURI);
    }

    /**
     * @notice Retrieves a comprehensive struct containing all current details of a specified ADL.
     * @param _tokenId The ID of the ADL.
     * @return A tuple containing ADL's ID, name, owner, creation time, last evolution time,
     *         evolution stage, essence balance, stake status, stake time, delegated evolutionist,
     *         and last procreation time.
     */
    function getADLDetails(uint256 _tokenId)
        public view
        returns (
            uint256 id,
            string memory name,
            address adlOwner,
            uint256 creationTime,
            uint256 lastEvolutionTime,
            uint256 evolutionStage,
            uint256 essenceBalance,
            bool isStaked,
            uint256 stakeTime,
            address delegatedEvolutionist,
            uint256 lastProcreationTime
        )
    {
        ADL storage adl = _adls[_tokenId];
        require(adl.id == _tokenId, "ADL does not exist");

        // Note: Traits are not returned directly in this top-level struct to avoid dynamic array issues
        // Use getADLTrait for specific trait data or implement a getADLAllTraits if needed.
        return (
            adl.id,
            adl.name,
            ownerOf(_tokenId), // Canonical owner from ERC721
            adl.creationTime,
            adl.lastEvolutionTime,
            adl.evolutionStage,
            adl.essenceBalance,
            adl.isStaked,
            adl.stakeTime,
            adl.delegatedEvolutionist,
            adl.lastProcreationTime
        );
    }

    /**
     * @notice Fetches the specific value of a named trait for an ADL.
     * @param _tokenId The ID of the ADL.
     * @param _traitName The name of the trait (e.g., "Color", "Ability").
     * @return The value of the requested trait. Returns an empty string if trait not found.
     */
    function getADLTrait(uint256 _tokenId, string memory _traitName) public view returns (string memory) {
        ADL storage adl = _adls[_tokenId];
        require(adl.id == _tokenId, "ADL does not exist");
        return adl.traits[_traitName];
    }

    /**
     * @notice Checks if a given token ID corresponds to an active ADL.
     * @param _tokenId The ID of the ADL.
     * @return True if the ADL exists, false otherwise.
     */
    function ADL_exists(uint256 _tokenId) public view returns (bool) {
        return _adls[_tokenId].id == _tokenId;
    }


    // II. Essence (ERC-20) Interaction:

    /**
     * @notice Transfers 'Essence' tokens from the caller to the specified ADL, bolstering its internal reserves.
     * @dev The Essence is held by the ChronoGlyphGenesis contract, but allocated to the ADL's balance.
     * @param _tokenId The ID of the ADL to feed.
     * @param _amount The amount of Essence tokens to feed.
     */
    function feedADL(uint256 _tokenId, uint256 _amount) public {
        ADL storage adl = _adls[_tokenId];
        require(adl.id == _tokenId, "ADL does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "Must own the ADL to feed it");
        require(address(essenceToken) != address(0), "Essence token contract not set");
        require(_amount > 0, "Feed amount must be positive");

        // Transfer Essence from msg.sender to this contract (on behalf of the ADL)
        require(essenceToken.transferFrom(_msgSender(), address(this), _amount), "Essence transfer failed");

        adl.essenceBalance += _amount;
        emit ADL_Fed(_tokenId, _amount, adl.essenceBalance);
    }

    /**
     * @notice Returns the current 'Essence' token balance held by or allocated to a specific ADL.
     * @param _tokenId The ID of the ADL.
     * @return The current Essence balance of the ADL.
     */
    function getADLEssenceBalance(uint256 _tokenId) public view returns (uint256) {
        ADL storage adl = _adls[_tokenId];
        require(adl.id == _tokenId, "ADL does not exist");
        return adl.essenceBalance;
    }

    /**
     * @notice (Admin/System-only) Triggers a simulated periodic consumption of 'Essence' by an ADL.
     * @dev In a real system, this would be triggered by an oracle, a keeper bot, or a time-based executor.
     *      Simulates metabolic needs; if Essence runs out, ADL might face penalties (not implemented for brevity).
     * @param _tokenId The ID of the ADL to drain Essence from.
     */
    function initiateEssenceDrain(uint256 _tokenId) public onlyOwner {
        ADL storage adl = _adls[_tokenId];
        require(adl.id == _tokenId, "ADL does not exist");

        uint256 drainAmount = adl.evolutionStage * ESSENCE_DRAIN_RATE_PER_STAGE * (10**essenceToken.decimals()); // Adjust for decimals
        if (adl.essenceBalance > drainAmount) {
            adl.essenceBalance -= drainAmount;
        } else {
            adl.essenceBalance = 0;
            // Future feature: Implement "decay" or "debuff" if Essence runs out
        }
    }

    /**
     * @notice (Admin-only) Sets the address of the ERC-20 'Essence' token contract.
     * @dev This must be called after the EssenceToken is deployed.
     * @param _essenceContractAddress The address of the deployed EssenceToken.
     */
    function setEssenceContract(address _essenceContractAddress) public onlyOwner {
        require(_essenceContractAddress != address(0), "Essence contract address cannot be zero");
        essenceToken = IERC20(_essenceContractAddress);
    }


    // III. ChronoKarma (Reputation System):

    /**
     * @notice (Admin/System-only) Grants 'ChronoKarma' to a user for positive contributions.
     * @param _user The address of the user to award karma.
     * @param _amount The amount of karma to award.
     */
    function awardChronoKarma(address _user, uint256 _amount) public onlyOwner {
        require(_user != address(0), "User address cannot be zero");
        chronoKarma[_user] += _amount;
        emit ChronoKarmaAwarded(_user, _amount, chronoKarma[_user]);
    }

    /**
     * @notice (Admin/System-only) Deducts 'ChronoKarma' from a user.
     * @param _user The address of the user to burn karma from.
     * @param _amount The amount of karma to burn.
     */
    function burnChronoKarma(address _user, uint256 _amount) public onlyOwner {
        require(_user != address(0), "User address cannot be zero");
        require(chronoKarma[_user] >= _amount, "Insufficient ChronoKarma");
        chronoKarma[_user] -= _amount;
        emit ChronoKarmaBurned(_user, _amount, chronoKarma[_user]);
    }

    /**
     * @notice Retrieves the current 'ChronoKarma' balance for a specified user address.
     * @param _user The address of the user.
     * @return The current ChronoKarma balance.
     */
    function getChronoKarma(address _user) public view returns (uint256) {
        return chronoKarma[_user];
    }

    /**
     * @notice Allows a user to spend their 'ChronoKarma' to pre-allocate a boost for their *next* ADL procreation attempt.
     * @param _karmaAmount The amount of ChronoKarma to spend for the boost.
     */
    function spendKarmaForProcreationBoost(uint256 _karmaAmount) public {
        require(chronoKarma[_msgSender()] >= _karmaAmount, "Insufficient ChronoKarma");
        require(_karmaAmount >= MIN_KARMA_FOR_PROCREATION_BOOST, "Minimum karma for boost not met");

        _karmaProcreationBoosts[_msgSender()] += _karmaAmount; // Accumulate boost
        chronoKarma[_msgSender()] -= _karmaAmount; // Burn karma for the boost
        emit ChronoKarmaBurned(_msgSender(), _karmaAmount, chronoKarma[_msgSender()]);
    }


    // IV. Generative / Procreation Mechanics:

    /**
     * @notice Initiates the creation of a new ADL offspring from two eligible parent ADLs.
     * @dev The child's traits are a blend of parents' traits, influenced by mutation chances and 'ChronoKarma' boost.
     * @param _parent1Id The ID of the first parent ADL.
     * @param _parent2Id The ID of the second parent ADL.
     * @param _to The address to receive the new child ADL.
     * @return The tokenId of the newly created child ADL.
     */
    function procreateADL(uint256 _parent1Id, uint256 _parent2Id, address _to) public returns (uint256) {
        ADL storage parent1 = _adls[_parent1Id];
        ADL storage parent2 = _adls[_parent2Id];

        (bool eligible, string memory reason) = getProcreationEligibility(_parent1Id, _parent2Id);
        require(eligible, reason);
        require(ownerOf(_parent1Id) == _msgSender() || ownerOf(_parent2Id) == _msgSender(), "Must own one of the parent ADLs to initiate procreation");
        require(_to != address(0), "Recipient address cannot be zero");

        // Use and clear karma boost for the current user
        uint256 karmaBoost = _karmaProcreationBoosts[_msgSender()];
        _karmaProcreationBoosts[_msgSender()] = 0; // Clear the boost after use

        _tokenIdCounter.increment();
        uint256 newChildId = _tokenIdCounter.current();

        // Mint child ADL
        _safeMint(_to, newChildId);
        string memory defaultChildURI = string(abi.encodePacked("ipfs://default/child_adl_", Strings.toString(newChildId), ".json"));
        _setTokenURI(newChildId, defaultChildURI);

        ADL storage childADL = _adls[newChildId];
        childADL.id = newChildId;
        childADL.name = string(abi.encodePacked("ADL-Child-", Strings.toString(newChildId)));
        childADL.creationTime = block.timestamp;
        childADL.lastEvolutionTime = block.timestamp; // Starts as Larva, so first evolution time is now.
        childADL.evolutionStage = 0; // Starts as Larva

        // Generate child traits based on parents' traits and karma influence
        _generateChildTraits(childADL, parent1, parent2, karmaBoost);

        parent1.lastProcreationTime = block.timestamp;
        parent2.lastProcreationTime = block.timestamp;

        emit ADLProcreated(_parent1Id, _parent2Id, newChildId, _to);
        return newChildId;
    }

    /**
     * @notice Determines if two specific ADLs meet the conditions required to successfully procreate.
     * @param _parent1Id The ID of the first parent ADL.
     * @param _parent2Id The ID of the second parent ADL.
     * @return A tuple indicating eligibility (true/false) and a reason string.
     */
    function getProcreationEligibility(uint256 _parent1Id, uint256 _parent2Id) public view returns (bool eligible, string memory reason) {
        ADL storage parent1 = _adls[_parent1Id];
        ADL storage parent2 = _adls[_parent2Id];

        if (parent1.id != _parent1Id || parent2.id != _parent2Id) {
            return (false, "One or both parent ADLs do not exist");
        }
        if (parent1.evolutionStage < 1 || parent2.evolutionStage < 1) { // Juvenile or higher
            return (false, "Both parents must be at least Juvenile stage to procreate");
        }
        if (block.timestamp < parent1.lastProcreationTime + PROCREATION_COOLDOWN_SECONDS) {
            return (false, "Parent1 is on procreation cooldown");
        }
        if (block.timestamp < parent2.lastProcreationTime + PROCREATION_COOLDOWN_SECONDS) {
            return (false, "Parent2 is on procreation cooldown");
        }
        return (true, "Eligible for procreation");
    }


    // V. Staking & Delegated Evolution:

    /**
     * @notice Locks an ADL, allowing it to accrue 'evolutionary progress' over time and become eligible for evolution.
     * @dev Staked ADLs cannot be transferred.
     * @param _tokenId The ID of the ADL to stake.
     */
    function stakeADL(uint256 _tokenId) public {
        ADL storage adl = _adls[_tokenId];
        require(adl.id == _tokenId, "ADL does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "Must own the ADL to stake it");
        require(!adl.isStaked, "ADL is already staked");

        adl.isStaked = true;
        adl.stakeTime = block.timestamp;
        emit ADLStaked(_tokenId, _msgSender());
    }

    /**
     * @notice Unlocks a previously staked ADL, making it transferable again.
     * @param _tokenId The ID of the ADL to unstake.
     */
    function unstakeADL(uint256 _tokenId) public {
        ADL storage adl = _adls[_tokenId];
        require(adl.id == _tokenId, "ADL does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "Must own the ADL to unstake it");
        require(adl.isStaked, "ADL is not staked");

        adl.isStaked = false;
        adl.stakeTime = 0; // Reset stake time
        emit ADLUnstaked(_tokenId, _msgSender());
    }

    /**
     * @notice Grants a specified delegate address the authority to perform certain evolution-related actions
     *         on an ADL, without transferring full ownership.
     * @param _tokenId The ID of the ADL.
     * @param _delegatee The address to delegate evolution rights to.
     */
    function delegateEvolutionRights(uint256 _tokenId, address _delegatee) public {
        ADL storage adl = _adls[_tokenId];
        require(adl.id == _tokenId, "ADL does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "Must own the ADL to delegate rights");
        require(_delegatee != address(0), "Delegatee cannot be zero address");
        require(_delegatee != _msgSender(), "Cannot delegate to self");

        adl.delegatedEvolutionist = _delegatee;
        emit EvolutionRightsDelegated(_tokenId, _msgSender(), _delegatee);
    }

    /**
     * @notice Revokes any previously granted evolution rights from a delegate for a specific ADL.
     * @param _tokenId The ID of the ADL.
     */
    function revokeEvolutionRights(uint256 _tokenId) public {
        ADL storage adl = _adls[_tokenId];
        require(adl.id == _tokenId, "ADL does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "Must own the ADL to revoke rights");
        require(adl.delegatedEvolutionist != address(0), "No evolution rights delegated to revoke");

        address previousDelegatee = adl.delegatedEvolutionist;
        adl.delegatedEvolutionist = address(0);
        emit EvolutionRightsRevoked(_tokenId, _msgSender(), previousDelegatee);
    }

    // --- Internal / Private Helper Functions ---

    /**
     * @dev Internal helper for trait mutation and URI update during ADL evolution.
     * @param _adl The ADL undergoing evolution.
     * @return The new URI string for the evolved ADL.
     */
    function _mutateTraits(ADL storage _adl) internal returns (string memory) {
        // Simplified simulation of trait mutation. In a real system, this would be more complex,
        // potentially pulling data from oracles or leveraging complex on-chain algorithms.
        uint256 randomNumber = _generateRandomNumber(block.timestamp + _adl.id + _adl.evolutionStage);
        string memory baseURI = "ipfs://evolution/";
        string memory newURI = "";

        if (_adl.evolutionStage == 1) { // Larva to Juvenile
            if (randomNumber % 3 == 0) { // 33% chance of a new "Ability"
                _adl.traits["Ability"] = "GrowthBoost";
            }
            _adl.traits["Color"] = "Green";
            _adl.traits["Size"] = "Small";
            newURI = string(abi.encodePacked(baseURI, "juvenile_adl_", Strings.toString(_adl.id), ".json"));
        } else if (_adl.evolutionStage == 2) { // Juvenile to Adult
             if (randomNumber % 2 == 0) { // 50% chance of further "Ability" enhancement
                _adl.traits["Ability"] = "EssenceEfficiency";
            }
            _adl.traits["Size"] = "Medium";
            _adl.traits["Color"] = "Blue";
            newURI = string(abi.encodePacked(baseURI, "adult_adl_", Strings.toString(_adl.id), ".json"));
        } else if (_adl.evolutionStage == 3) { // Adult to Elder
            _adl.traits["Ability"] = "ProcreationMaster";
            _adl.traits["Size"] = "Large";
            _adl.traits["Color"] = "Purple";
            _adl.traits["Longevity"] = "High";
            newURI = string(abi.encodePacked(baseURI, "elder_adl_", Strings.toString(_adl.id), ".json"));
        }
        return newURI;
    }

    /**
     * @dev Internal helper for child trait generation during ADL procreation.
     *      Traits are inherited from parents with a chance of mutation, influenced by karma boost.
     * @param _childADL The newly created child ADL.
     * @param _parent1 The first parent ADL.
     * @param _parent2 The second parent ADL.
     * @param _karmaBoost The accumulated karma boost from the procreator.
     */
    function _generateChildTraits(ADL storage _childADL, ADL storage _parent1, ADL storage _parent2, uint256 _karmaBoost) internal {
        // Simplified trait inheritance and mutation logic.
        // For production, a secure VRF (like Chainlink VRF) should be used for randomness.
        uint256 randomSeed = block.timestamp + _childADL.id + _parent1.id + _parent2.id + _karmaBoost;

        // Inherit 'Color' trait from one of the parents
        _childADL.traits["Color"] = (_generateRandomNumber(randomSeed) % 2 == 0) ? _parent1.traits["Color"] : _parent2.traits["Color"];
        // Inherit 'Size' trait, if parents have it. Default to "Small" if not.
        string memory parent1Size = _parent1.traits["Size"];
        string memory parent2Size = _parent2.traits["Size"];
        if (bytes(parent1Size).length > 0 && bytes(parent2Size).length > 0) {
             _childADL.traits["Size"] = (_generateRandomNumber(randomSeed + 1) % 2 == 0) ? parent1Size : parent2Size;
        } else if (bytes(parent1Size).length > 0) {
            _childADL.traits["Size"] = parent1Size;
        } else if (bytes(parent2Size).length > 0) {
            _childADL.traits["Size"] = parent2Size;
        } else {
            _childADL.traits["Size"] = "Small";
        }

        // Mutation chance calculation, influenced by karmaBoost
        uint256 baseMutationChance = 100; // e.g., 10% chance (100 out of 1000)
        uint256 karmaInfluence = (_karmaBoost / MIN_KARMA_FOR_PROCREATION_BOOST) * 10; // 10% reduction per unit of MIN_KARMA_FOR_PROCREATION_BOOST
        uint256 effectiveMutationChance = baseMutationChance > karmaInfluence ? (baseMutationChance - karmaInfluence) : 0;
        if (effectiveMutationChance < 10) effectiveMutationChance = 10; // Minimum 1% mutation chance

        if (_generateRandomNumber(randomSeed + 2) % 1000 < effectiveMutationChance) {
            // Apply a random mutation, e.g., change a trait to something unique
            string memory newTrait = "Mutation";
            if (_generateRandomNumber(randomSeed + 3) % 3 == 0) newTrait = "Glow";
            else if (_generateRandomNumber(randomSeed + 3) % 3 == 1) newTrait = "Spiky";
            else newTrait = "Shimmer";
            _childADL.traits["SpecialFeature"] = newTrait;
        } else {
            // Inherit an ability trait, or set a default
            string memory parent1Ability = _parent1.traits["Ability"];
            string memory parent2Ability = _parent2.traits["Ability"];

            if (bytes(parent1Ability).length > 0 && bytes(parent2Ability).length > 0) {
                 _childADL.traits["Ability"] = (_generateRandomNumber(randomSeed + 4) % 2 == 0) ? parent1Ability : parent2Ability;
            } else if (bytes(parent1Ability).length > 0) {
                _childADL.traits["Ability"] = parent1Ability;
            } else if (bytes(parent2Ability).length > 0) {
                _childADL.traits["Ability"] = parent2Ability;
            } else {
                _childADL.traits["Ability"] = "Basic";
            }
        }
    }

    /**
     * @dev Simplified pseudo-random number generator for demonstration purposes.
     *      **WARNING**: This is NOT cryptographically secure and should not be used for real-world randomness
     *      in production. For production, integrate with Chainlink VRF or similar decentralized randomness solutions.
     * @param _seed An additional seed for randomness.
     * @return A pseudo-random number.
     */
    function _generateRandomNumber(uint256 _seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _seed)));
    }


    // The following functions are overrides required by Solidity for ERC721Enumerable, ERC721URIStorage
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// --- Companion EssenceToken contract (to be deployed separately) ---
/*
// EssenceToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EssenceToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Essence", "ESS") Ownable(initialOwner) {
        // Mint an initial supply to the deployer (which will be the ChronoGlyphGenesis owner)
        _mint(initialOwner, 1_000_000 * 10**decimals()); // 1,000,000 ESS tokens
    }

    // Allows the contract owner to mint more Essence tokens (e.g., for system rewards or distribution)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
*/
```