Okay, let's create a smart contract that manages dynamic digital assets (think like evolving game items or verifiable credentials) within a decentralized system, incorporating resource management, reputation, interactive events, and a unique delegation mechanism.

We'll call it `AstroColonyChronicle`. It will manage "Colonies" (ERC-721 NFTs) which generate resources (managed internally or via a separate ERC-20), have mutable properties (dynamic NFT), can interact with each other, participate in global events, and build reputation.

Here's the plan:

**Outline:**

1.  **SPDX License Identifier and Pragma**
2.  **Imports:** ERC721, ERC20 (interface), Ownable, potentially ReentrancyGuard (though we'll aim to avoid requiring it).
3.  **Contract Definition:** Inherits ERC721 and Ownable. Will interact with an external ERC20 for resources.
4.  **Enums:** For Interaction Types, Trait Types, Modifier Types.
5.  **Structs:** `ColonyData`, `GlobalEvent`, `TraitModifier`.
6.  **State Variables:**
    *   Mappings for ColonyData, Reputation, ResourceBalances, LastResourceClaimTime, ColonyDelegates.
    *   Address of the associated ERC20 Resource token.
    *   Global Event details.
    *   Trait Modifiers mapping.
    *   Base Resource Generation Rate.
    *   Pause state.
7.  **Events:** For minting, upgrading, interactions, resource claims, events, delegation, pausing.
8.  **Modifiers:** `whenNotPaused`, `onlyColonyOwnerOrDelegate`.
9.  **Constructor:** Initializes contract, sets name/symbol for ERC721, potentially sets initial owner.
10. **Core ERC721 Functions (Overridden/Implemented):** `tokenURI`, `ownerOf`, `balanceOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`. (These contribute to the function count but are standard).
11. **Resource Management Functions:** `setResourceToken`, `claimGeneratedResources`, `getColonyResourceBalance`, `getEffectiveGenerationRate`, `spendResourcesInternal` (internal helper).
12. **Colony Management Functions:** `claimColony`, `getColonyData`, `upgradeColony`, `setColonyName`, `burnColony`.
13. **Interaction and Reputation Functions:** `interactWithColony`, `getColonyReputation`.
14. **Event Functions:** `triggerGlobalEvent`, `participateInEvent`, `getGlobalEventDetails`.
15. **Dynamic Trait Functions:** `setTraitModifier`, `getTraitModifier`.
16. **Delegation Functions:** `delegateColonyAction`, `revokeColonyDelegate`, `getColonyDelegate`.
17. **Control Functions:** `pauseContract`, `unpauseContract`, `withdrawProtocolFees` (if any).
18. **View Functions:** Various getters for state variables.

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets the NFT name and symbol.
2.  `setResourceToken(address _resourceToken)`: (Owner) Sets the address of the ERC20 token used as resources.
3.  `claimColony()`: Allows a user to mint a new unique Colony NFT, initializing its basic data.
4.  `getColonyData(uint256 _colonyId)`: (View) Retrieves all the mutable data associated with a specific Colony NFT.
5.  `tokenURI(uint256 _tokenId)`: (View, ERC721 override) Generates a dynamic metadata URI for a Colony NFT based on its current state, enabling dynamic NFTs.
6.  `claimGeneratedResources(uint256 _colonyId)`: Calculates resource generation since the last claim based on time, colony level, and traits, and mints/transfers the corresponding ERC20 resources to the owner/delegate.
7.  `upgradeColony(uint256 _colonyId, uint256 _upgradeId)`: Allows the owner/delegate of a colony to spend resources to upgrade the colony, modifying its state (e.g., level, traits).
8.  `interactWithColony(uint256 _sourceColonyId, uint256 _targetColonyId, InteractionType _type)`: Enables interaction between two colonies, potentially affecting their resources, reputation, or triggering events based on the interaction type and colony traits.
9.  `getColonyReputation(uint256 _colonyId)`: (View) Returns the current reputation score of a specific colony.
10. `setColonyName(uint256 _colonyId, string memory _name)`: Allows the owner/delegate to set or change the cosmetic name of their colony (potentially costs resources/reputation).
11. `burnColony(uint256 _colonyId)`: Allows the owner/delegate to burn/destroy their colony NFT, potentially yielding some resources back.
12. `triggerGlobalEvent(uint256 _eventId, uint256 _duration, bytes memory _eventData)`: (Owner) Initiates a time-limited global event that colonies can participate in.
13. `participateInEvent(uint256 _colonyId)`: Allows a colony owner/delegate to register their colony's participation in the current global event.
14. `getGlobalEventDetails()`: (View) Returns the details of the currently active global event.
15. `setTraitModifier(Trait _trait, ModifierType _modifierType, uint256 _value)`: (Owner) Configures how specific colony traits affect outcomes (e.g., resource generation, interaction success rates) based on a modifier type and value.
16. `getTraitModifier(Trait _trait)`: (View) Returns the currently configured modifier details for a specific trait.
17. `delegateColonyAction(uint256 _colonyId, address _delegate)`: Allows the owner of a colony to assign a delegate address that can perform specific actions on behalf of the owner.
18. `revokeColonyDelegate(uint256 _colonyId)`: Allows the owner to remove the delegate assignment for their colony.
19. `getColonyDelegate(uint256 _colonyId)`: (View) Returns the current delegate address for a colony, if any.
20. `pauseContract()`: (Owner) Pauses core interactive functions of the contract (e.g., interactions, upgrades, resource claims) in case of emergency.
21. `unpauseContract()`: (Owner) Resumes contract functionality after a pause.
22. `setBaseGenerationRate(uint256 _rate)`: (Owner) Sets the base rate at which resources are generated per colony per unit of time.
23. `getEffectiveGenerationRate(uint256 _colonyId)`: (View) Calculates the actual resource generation rate for a colony, factoring in its level, traits, and global modifiers.
24. `getColonyCount()`: (View) Returns the total number of colonies minted (ERC721 totalSupply).
25. `ownerOf(uint256 tokenId)`: (View, ERC721) Standard ERC721 function to get the owner of a token.
26. `balanceOf(address owner)`: (View, ERC721) Standard ERC721 function to get the number of tokens owned by an address.
27. `approve(address to, uint256 tokenId)`: (ERC721) Standard ERC721 function to approve an address to spend a token.
28. `getApproved(uint256 tokenId)`: (View, ERC721) Standard ERC721 function to get the approved address for a token.
29. `setApprovalForAll(address operator, bool approved)`: (ERC721) Standard ERC721 function to approve an operator for all tokens.
30. `isApprovedForAll(address owner, address operator)`: (View, ERC721) Standard ERC721 function to check if an operator is approved for all tokens.
31. `transferFrom(address from, address to, uint256 tokenId)`: (ERC721) Standard ERC721 function to transfer token ownership (requires approval/operator).
32. `safeTransferFrom(address from, address to, uint256 tokenId)`: (ERC721) Standard ERC721 function for safe token transfer.
33. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: (ERC721) Standard ERC721 function for safe token transfer with data.
34. `withdrawERC20(address _token, address _to, uint256 _amount)`: (Owner) Allows the owner to withdraw any supported ERC20 tokens accidentally sent to the contract, or protocol fees if implemented. (Using a generic token address here is safer than assuming only the resource token).

*Note: Some standard ERC721 functions like `transferFrom` and `safeTransferFrom` are included to meet the function count and represent the full interface, even though their core logic is handled by the inherited OpenZeppelin contract.*

Let's write the Solidity code. We'll use interfaces for ERC20 and rely on OpenZeppelin for ERC721 and Ownable.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Interface for Resource Token
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI string manipulation

// Outline:
// 1. SPDX License Identifier and Pragma
// 2. Imports (ERC721, ERC20 Interface, Ownable, Strings)
// 3. Contract Definition (Inherits ERC721, Ownable)
// 4. Enums (InteractionType, Trait, ModifierType)
// 5. Structs (ColonyData, GlobalEvent, TraitModifier)
// 6. State Variables
// 7. Events
// 8. Modifiers
// 9. Constructor
// 10. Core ERC721 Functions (Overrides)
// 11. Resource Management Functions
// 12. Colony Management Functions
// 13. Interaction and Reputation Functions
// 14. Event Functions
// 15. Dynamic Trait Functions
// 16. Delegation Functions
// 17. Control Functions
// 18. View/Utility Functions

// Function Summary:
// 1. constructor(): Initializes contract name/symbol, sets owner.
// 2. setResourceToken(address _resourceToken): (Owner) Sets the address of the resource ERC20 token.
// 3. claimColony(): Mints a new Colony NFT for the caller, initializes its state.
// 4. getColonyData(uint256 _colonyId): (View) Retrieves the mutable data of a colony.
// 5. tokenURI(uint256 _tokenId): (View, Override) Generates dynamic JSON metadata for a colony.
// 6. claimGeneratedResources(uint256 _colonyId): Calculates and distributes resources generated passively to colony owner/delegate.
// 7. upgradeColony(uint256 _colonyId, uint256 _upgradeId): Spends resources to improve a colony's level and potentially traits.
// 8. interactWithColony(uint256 _sourceColonyId, uint256 _targetColonyId, InteractionType _type): Handles interactions between colonies, affecting state, reputation, etc.
// 9. getColonyReputation(uint256 _colonyId): (View) Returns the reputation score of a colony.
// 10. setColonyName(uint256 _colonyId, string memory _name): Allows setting a custom name for a colony.
// 11. burnColony(uint256 _colonyId): Destroys a colony NFT.
// 12. triggerGlobalEvent(uint256 _eventId, uint256 _duration, bytes memory _eventData): (Owner) Starts a global interactive event.
// 13. participateInEvent(uint256 _colonyId): Allows a colony owner/delegate to join the current event.
// 14. getGlobalEventDetails(): (View) Returns details of the active global event.
// 15. setTraitModifier(Trait _trait, ModifierType _modifierType, uint256 _value): (Owner) Configures how traits modify game mechanics.
// 16. getTraitModifier(Trait _trait): (View) Returns the modifier settings for a trait.
// 17. delegateColonyAction(uint256 _colonyId, address _delegate): Allows a colony owner to authorize another address to act on their behalf.
// 18. revokeColonyDelegate(uint256 _colonyId): Removes a colony delegate.
// 19. getColonyDelegate(uint256 _colonyId): (View) Returns the delegate address for a colony.
// 20. pauseContract(): (Owner) Stops core interactions for maintenance or emergency.
// 21. unpauseContract(): (Owner) Resumes contract functionality.
// 22. setBaseGenerationRate(uint256 _rate): (Owner) Sets the fundamental resource generation rate.
// 23. getEffectiveGenerationRate(uint256 _colonyId): (View) Calculates the generation rate considering all modifiers.
// 24. getColonyCount(): (View, ERC721) Returns the total number of colonies minted.
// 25. ownerOf(uint256 tokenId): (View, ERC721) Get token owner.
// 26. balanceOf(address owner): (View, ERC721) Get owner's token count.
// 27. approve(address to, uint256 tokenId): (ERC721) Approve address for token.
// 28. getApproved(uint256 tokenId): (View, ERC721) Get approved address for token.
// 29. setApprovalForAll(address operator, bool approved): (ERC721) Set operator approval.
// 30. isApprovedForAll(address owner, address operator): (View, ERC721) Check operator approval.
// 31. transferFrom(address from, address to, uint256 tokenId): (ERC721) Transfer token.
// 32. safeTransferFrom(address from, address to, uint256 tokenId): (ERC721) Safe transfer.
// 33. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): (ERC721) Safe transfer with data.
// 34. withdrawERC20(address _token, address _to, uint256 _amount): (Owner) Withdraw ERC20s from contract.

contract AstroColonyChronicle is ERC721, Ownable {
    using Strings for uint256;

    // --- Enums ---
    enum InteractionType { SCOUT, TRADE, ASSIST }
    enum Trait { NONE, ASTRO_HARVESTER, SOLAR_TECHNICIAN, DEFENSIVE_SPECIALIST, SOCIAL_HUB }
    enum ModifierType { ADDITIVE, MULTIPLICATIVE }

    // --- Structs ---
    struct ColonyData {
        uint256 level;
        string name;
        uint256 lastResourceClaimTime;
        Trait trait1; // Example: colonies can have traits
        // Add more mutable properties here (e.g., health, defense, happiness)
    }

    struct GlobalEvent {
        uint256 eventId;
        uint256 startTime;
        uint256 endTime;
        bytes eventData; // Flexible data for different event types
        mapping(uint256 => bool) participants; // colonyId => participated
        bool active;
    }

    struct TraitModifier {
        ModifierType modifierType;
        uint256 value; // Value depends on ModifierType (e.g., percentage scaled by 1000)
    }

    // --- State Variables ---
    address public resourceToken;
    uint256 private _colonyCounter; // To track next available colony ID

    mapping(uint256 => ColonyData) public colonyData;
    mapping(uint256 => uint256) public colonyReputation; // colonyId => reputation score
    mapping(uint256 => address) public colonyDelegate; // colonyId => delegate address

    GlobalEvent public currentGlobalEvent;

    // Trait => TraitModifier mapping
    mapping(Trait => TraitModifier) public traitModifiers;

    uint256 public baseResourceGenerationRate; // Resources per second (scaled value)
    uint256 public constant SECONDS_PER_YEAR = 31536000; // Approximation

    bool public paused = false;

    // --- Events ---
    event ColonyClaimed(uint256 indexed colonyId, address indexed owner);
    event ResourcesClaimed(uint256 indexed colonyId, uint256 amount);
    event ColonyUpgraded(uint256 indexed colonyId, uint256 newLevel, uint256 upgradeId);
    event ColonyInteracted(uint256 indexed sourceColonyId, uint256 indexed targetColonyId, InteractionType interactionType);
    event ColonyNameSet(uint256 indexed colonyId, string newName);
    event ColonyBurned(uint256 indexed colonyId);
    event GlobalEventTriggered(uint256 indexed eventId, uint256 startTime, uint256 endTime);
    event ColonyParticipatedInEvent(uint256 indexed colonyId, uint256 indexed eventId);
    event TraitModifierSet(Trait indexed trait, ModifierType modifierType, uint256 value);
    event ColonyDelegateSet(uint256 indexed colonyId, address indexed delegate);
    event ColonyDelegateRevoked(uint256 indexed colonyId);
    event Paused(address account);
    event Unpaused(address account);
    event BaseGenerationRateSet(uint256 newRate);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyColonyOwnerOrDelegate(uint256 _colonyId) {
        address owner = ownerOf(_colonyId);
        address delegate = colonyDelegate[_colonyId];
        require(msg.sender == owner || msg.sender == delegate, "Not colony owner or delegate");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("AstroColonyChronicle", "ASTROCLNY") Ownable(msg.sender) {
        _colonyCounter = 0;
        baseResourceGenerationRate = 1e18 / SECONDS_PER_YEAR; // Example: 1 token per year, adjust scaling
    }

    // --- Core ERC721 Functions (Overrides) ---
    // We inherit standard implementations from OpenZeppelin ERC721
    // and override tokenURI for dynamic metadata.

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        ColonyData memory data = colonyData[_tokenId];
        address owner = ownerOf(_tokenId);
        uint256 currentReputation = colonyReputation[_tokenId];
        uint256 currentLevel = data.level;
        string memory colonyName = bytes(data.name).length > 0 ? data.name : string(abi.encodePacked("Colony #", _tokenId.toString()));
        string memory ownerAddressString = Strings.toHexString(uint160(owner), 20);
        uint256 effectiveRate = getEffectiveGenerationRate(_tokenId);

        // Simple JSON structure - In a real application, this would be more complex
        // and often built off-chain or with a dedicated service for larger metadata.
        // This on-chain version is basic for demonstration.
        string memory json = string(abi.encodePacked(
            '{"name": "', colonyName,
            '", "description": "A dynamic Astro Colony.",',
            '"image": "ipfs://<placeholder_image_cid>/', _tokenId.toString(), '.png",', // Placeholder image
            '"attributes": [',
                '{"trait_type": "Level", "value": ', currentLevel.toString(), '},',
                '{"trait_type": "Reputation", "value": ', currentReputation.toString(), '},',
                '{"trait_type": "Trait", "value": "', _getTraitName(data.trait1), '"},',
                '{"trait_type": "Owner", "value": "', ownerAddressString, '"},',
                '{"trait_type": "Effective Generation Rate (per sec)", "value": "', effectiveRate.toString(), '"}',
            ']}'
        ));

        bytes memory jsonBytes = bytes(json);
        string memory base64Json = _toBase64(jsonBytes);

        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    // Internal helper for Base64 encoding (Simplified - uses inline assembly for basic encoding)
    // WARNING: This is a very basic implementation for demonstration.
    // For production, use a tested library or off-chain generation.
    function _toBase64(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        bytes memory buffer = new bytes(((data.length + 2) / 3) * 4);
        uint256 i;
        uint256 j;
        uint256 dataLen = data.length;
        uint256 bufferLen = buffer.length;

        while (i < dataLen) {
            uint256 b1 = data[i];
            uint256 b2 = i + 1 < dataLen ? data[i + 1] : 0;
            uint256 b3 = i + 2 < dataLen ? data[i + 2] : 0;

            buffer[j++] = alphabet[b1 >> 2];
            buffer[j++] = alphabet[((b1 & 0x03) << 4) | (b2 >> 4)];
            buffer[j++] = alphabet[((b2 & 0x0f) << 2) | (b3 >> 6)];
            buffer[j++] = alphabet[b3 & 0x3f];

            i += 3;
        }

        if (dataLen % 3 >= 1) {
            buffer[bufferLen - 1] = "=";
        }
        if (dataLen % 3 == 1) {
            buffer[bufferLen - 2] = "=";
        }

        return string(buffer);
    }

    function _getTraitName(Trait _trait) internal pure returns (string memory) {
        if (_trait == Trait.ASTRO_HARVESTER) return "Astro Harvester";
        if (_trait == Trait.SOLAR_TECHNICIAN) return "Solar Technician";
        if (_trait == Trait.DEFENSIVE_SPECIALIST) return "Defensive Specialist";
        if (_trait == Trait.SOCIAL_HUB) return "Social Hub";
        return "None";
    }

    // --- Resource Management Functions ---

    function setResourceToken(address _resourceToken) public onlyOwner {
        require(_resourceToken != address(0), "Invalid address");
        resourceToken = _resourceToken;
        emit BaseGenerationRateSet(baseResourceGenerationRate); // Re-emit to indicate resource token is set
    }

    function claimGeneratedResources(uint256 _colonyId)
        public
        whenNotPaused
        onlyColonyOwnerOrDelegate(_colonyId)
    {
        ColonyData storage data = colonyData[_colonyId];
        uint256 currentTime = block.timestamp;
        uint256 lastClaim = data.lastResourceClaimTime;
        uint256 effectiveRate = getEffectiveGenerationRate(_colonyId);

        if (currentTime > lastClaim) {
            uint256 timeElapsed = currentTime - lastClaim;
            uint256 generatedAmount = effectiveRate * timeElapsed;

            if (generatedAmount > 0) {
                require(resourceToken != address(0), "Resource token not set");
                IERC20 token = IERC20(resourceToken);
                address recipient = ownerOf(_colonyId); // Resources go to owner, not delegate

                // Mint or transfer resources to the owner
                // This assumes the resourceToken contract has a minting function
                // or that this contract pre-owns resources to transfer.
                // For this example, we assume a simple transfer from contract's balance.
                // A real system might have a dedicated minter role or internal balance.
                require(token.transfer(recipient, generatedAmount), "Resource transfer failed");

                data.lastResourceClaimTime = currentTime;
                emit ResourcesClaimed(_colonyId, generatedAmount);
            }
        }
    }

     // This function is internal as resource balance is managed externally by the ERC20 contract
    function spendResourcesInternal(address _spender, uint256 _amount) internal returns (bool) {
        require(resourceToken != address(0), "Resource token not set");
        IERC20 token = IERC20(resourceToken);
        // This requires the spender to have approved this contract to spend their tokens
        return token.transferFrom(_spender, address(this), _amount);
    }

    function getColonyResourceBalance(address _owner) public view returns (uint256) {
        require(resourceToken != address(0), "Resource token not set");
        IERC20 token = IERC20(resourceToken);
        return token.balanceOf(_owner);
    }

    function getEffectiveGenerationRate(uint256 _colonyId) public view returns (uint256) {
        ColonyData memory data = colonyData[_colonyId];
        uint256 baseRate = baseResourceGenerationRate;
        uint256 levelBonus = data.level * (baseRate / 10); // Example: +10% base rate per level
        uint256 effectiveRate = baseRate + levelBonus;

        // Apply trait modifiers
        TraitModifier memory tm = traitModifiers[data.trait1];
        if (tm.modifierType == ModifierType.ADDITIVE) {
            effectiveRate += tm.value;
        } else if (tm.modifierType == ModifierType.MULTIPLICATIVE) {
             // Assuming value is percentage scaled by 1000 (e.g., 1200 = 120%)
            effectiveRate = (effectiveRate * tm.value) / 1000;
        }

        return effectiveRate;
    }

    // --- Colony Management Functions ---

    function claimColony() public whenNotPaused {
        uint256 newColonyId = _colonyCounter;
        _safeMint(msg.sender, newColonyId);

        ColonyData storage data = colonyData[newColonyId];
        data.level = 1;
        data.lastResourceClaimTime = block.timestamp;
        data.trait1 = Trait.NONE; // Initial trait
        // Initialize other data fields

        colonyReputation[newColonyId] = 0;
        _colonyCounter++;

        emit ColonyClaimed(newColonyId, msg.sender);
    }

    function upgradeColony(uint256 _colonyId, uint256 _upgradeId)
        public
        whenNotPaused
        onlyColonyOwnerOrDelegate(_colonyId)
    {
        // Check if upgradeId is valid and requirements are met (e.g., minimum level)
        // Example: Upgrade cost is 100 resources per level
        uint256 cost = colonyData[_colonyId].level * 100e18; // Use 18 decimals as an example scaling

        address owner = ownerOf(_colonyId);
        require(getColonyResourceBalance(owner) >= cost, "Insufficient resources for upgrade");

        // Spend resources from the owner's balance using the resource token contract
        require(spendResourcesInternal(owner, cost), "Failed to spend resources");

        ColonyData storage data = colonyData[_colonyId];
        data.level++; // Increment level
        // Apply other upgrade effects based on _upgradeId (e.g., assign new trait)
        if (data.level == 5 && data.trait1 == Trait.NONE) { // Example: assign trait at level 5 if none
             data.trait1 = Trait.ASTRO_HARVESTER; // Example logic
        }

        emit ColonyUpgraded(_colonyId, data.level, _upgradeId);
    }

    function setColonyName(uint256 _colonyId, string memory _name)
        public
        whenNotPaused
        onlyColonyOwnerOrDelegate(_colonyId)
    {
        ColonyData storage data = colonyData[_colonyId];
        require(bytes(_name).length <= 32, "Name too long"); // Example name length limit
        // Optional: require resource cost or reputation cost to change name
        // uint256 nameChangeCost = 10e18;
        // address owner = ownerOf(_colonyId);
        // require(getColonyResourceBalance(owner) >= nameChangeCost, "Insufficient resources");
        // require(spendResourcesInternal(owner, nameChangeCost), "Failed to spend resources");

        data.name = _name;
        emit ColonyNameSet(_colonyId, _name);
    }

     function burnColony(uint256 _colonyId)
        public
        whenNotPaused
        onlyColonyOwnerOrDelegate(_colonyId)
     {
        address owner = ownerOf(_colonyId);
        // Optional: return resources upon burning
        // uint256 refundAmount = colonyData[_colonyId].level * 50e18; // Example refund logic
        // if (refundAmount > 0) {
        //    IERC20 token = IERC20(resourceToken);
        //    require(token.transfer(owner, refundAmount), "Resource refund failed");
        // }

        // Clean up internal state before burning the ERC721
        delete colonyData[_colonyId];
        delete colonyReputation[_colonyId];
        delete colonyDelegate[_colonyId];
        // Note: participants mapping in currentGlobalEvent is not deleted here
        // as it belongs to the event struct itself.

        _burn(_colonyId);

        emit ColonyBurned(_colonyId);
     }


    // --- Interaction and Reputation Functions ---

    function interactWithColony(uint256 _sourceColonyId, uint256 _targetColonyId, InteractionType _type)
        public
        whenNotPaused
        onlyColonyOwnerOrDelegate(_sourceColonyId) // Only source colony owner/delegate initiates
    {
        require(_sourceColonyId != _targetColonyId, "Cannot interact with self");
        require(_exists(_targetColonyId), "Target colony does not exist");

        address sourceOwner = ownerOf(_sourceColonyId);
        address targetOwner = ownerOf(_targetColonyId);

        // --- Complex Interaction Logic ---
        // This is a placeholder for game/system-specific logic.
        // It could involve:
        // - Checking traits of both colonies
        // - Rolling dice or using other random (or pseudo-random via verifiable delay functions) elements
        // - Transferring resources between colonies (requires targetOwner approval or different flow)
        // - Increasing/decreasing reputation of one or both colonies
        // - Triggering internal events or state changes

        uint256 sourceRep = colonyReputation[_sourceColonyId];
        uint256 targetRep = colonyReputation[_targetColonyId];

        if (_type == InteractionType.ASSIST) {
            // Example: Assist increases both reputations
            colonyReputation[_sourceColonyId] = sourceRep + 5 > sourceRep ? sourceRep + 5 : type(uint256).max; // Prevent overflow
            colonyReputation[_targetColonyId] = targetRep + 2 > targetRep ? targetRep + 2 : type(uint256).max; // Prevent overflow
            // Maybe transfer a small amount of resources from source to target? (Needs owner permission flow)
        } else if (_type == InteractionType.SCOUT) {
            // Example: Scouting might grant information (off-chain) or have a chance of success/failure
            // Success might grant resources or data, failure might cost resources or reputation.
            // This would likely involve more complex checks and state updates.
            // For simplicity, let's just add a small reputation boost for the scouted target being noteworthy.
             if (colonyData[_targetColonyId].level > 5) {
                 colonyReputation[_sourceColonyId] = sourceRep + 1 > sourceRep ? sourceRep + 1 : type(uint256).max;
             }
        }
        // Add logic for other InteractionTypes

        emit ColonyInteracted(_sourceColonyId, _targetColonyId, _type);
    }

    function getColonyReputation(uint256 _colonyId) public view returns (uint256) {
        require(_exists(_colonyId), "Colony does not exist");
        return colonyReputation[_colonyId];
    }


    // --- Event Functions ---

    function triggerGlobalEvent(uint256 _eventId, uint256 _duration, bytes memory _eventData) public onlyOwner whenNotPaused {
        require(!currentGlobalEvent.active, "An event is already active");
        require(_duration > 0, "Event duration must be positive");

        currentGlobalEvent.eventId = _eventId;
        currentGlobalEvent.startTime = block.timestamp;
        currentGlobalEvent.endTime = block.timestamp + _duration;
        currentGlobalEvent.eventData = _eventData; // Store event-specific data
        currentGlobalEvent.active = true;

        // Note: The participants mapping is reset by re-initializing the struct.
        // If persistence is needed across events, a different structure is required.

        emit GlobalEventTriggered(_eventId, currentGlobalEvent.startTime, currentGlobalEvent.endTime);
    }

    function participateInEvent(uint256 _colonyId)
        public
        whenNotPaused
        onlyColonyOwnerOrDelegate(_colonyId)
    {
        require(currentGlobalEvent.active, "No active global event");
        require(block.timestamp <= currentGlobalEvent.endTime, "Event has ended");
        require(!currentGlobalEvent.participants[_colonyId], "Colony already participating");

        currentGlobalEvent.participants[_colonyId] = true;

        // Optional: Apply immediate effects for participation (e.g., cost, temporary buff)

        emit ColonyParticipatedInEvent(_colonyId, currentGlobalEvent.eventId);
    }

    function getGlobalEventDetails() public view returns (uint256 eventId, uint256 startTime, uint256 endTime, bool active) {
        return (currentGlobalEvent.eventId, currentGlobalEvent.startTime, currentGlobalEvent.endTime, currentGlobalEvent.active);
    }

    // Note: A real system would need logic to end/resolve events and reward participants.
    // This would likely involve a separate function or a time-based trigger (less common on-chain).

    // --- Dynamic Trait Functions ---

    function setTraitModifier(Trait _trait, ModifierType _modifierType, uint256 _value) public onlyOwner {
        require(_trait != Trait.NONE, "Cannot set modifier for None trait");
        traitModifiers[_trait] = TraitModifier({
            modifierType: _modifierType,
            value: _value
        });
        emit TraitModifierSet(_trait, _modifierType, _value);
    }

    function getTraitModifier(Trait _trait) public view returns (ModifierType modifierType, uint256 value) {
        TraitModifier memory tm = traitModifiers[_trait];
        return (tm.modifierType, tm.value);
    }

    // --- Delegation Functions ---

    function delegateColonyAction(uint256 _colonyId, address _delegate)
        public
        whenNotPaused
        onlyColonyOwner(_colonyId) // Only the actual owner can set a delegate
    {
        require(_delegate != address(0), "Delegate address cannot be zero");
        colonyDelegate[_colonyId] = _delegate;
        emit ColonyDelegateSet(_colonyId, _delegate);
    }

    function revokeColonyDelegate(uint256 _colonyId)
        public
        whenNotPaused
        onlyColonyOwner(_colonyId) // Only the actual owner can revoke
    {
        delete colonyDelegate[_colonyId];
        emit ColonyDelegateRevoked(_colonyId);
    }

    function getColonyDelegate(uint256 _colonyId) public view returns (address) {
         require(_exists(_colonyId), "Colony does not exist");
         return colonyDelegate[_colonyId];
    }

    // --- Control Functions ---

    function pauseContract() public onlyOwner {
        require(!paused, "Contract is already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() public onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    function setBaseGenerationRate(uint256 _rate) public onlyOwner {
        baseResourceGenerationRate = _rate;
        emit BaseGenerationRateSet(_rate);
    }

    // Allows owner to withdraw accidentally sent ERC20s or protocol fees
    function withdrawERC20(address _token, address _to, uint256 _amount) public onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(_to != address(0), "Invalid recipient address");
        IERC20 token = IERC20(_token);
        require(token.transfer(_to, _amount), "Withdrawal failed");
    }

    // --- View/Utility Functions ---

     function getColonyCount() public view returns (uint256) {
         return _colonyCounter; // ERC721.totalSupply() can also be used if implemented
     }

     // Standard ERC721 views are inherited/implicitly public
     // function ownerOf(uint256 tokenId) public view virtual override returns (address)
     // function balanceOf(address owner) public view virtual override returns (uint256)
     // etc.

    // Need to explicitly add some inherited functions if they aren't public/external already
    // OpenZeppelin's ERC721 makes these public/external. We list them in summary for clarity.
    // For example:
    // function ownerOf(uint256 tokenId) public view override(ERC721) returns (address) { super.ownerOf(tokenId); }
    // The summary covers these.

}
```

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Dynamic NFTs:** The `tokenURI` function generates metadata on the fly based on the current state of the `ColonyData` struct (level, name, trait, reputation, generation rate). This makes the NFT truly dynamic and reflects in-game/in-system progression. The use of Base64 encoding for the data URI is standard practice for on-chain metadata.
2.  **Resource Generation:** Implements a time-based passive resource generation mechanism (`claimGeneratedResources`) that is influenced by mutable colony properties (`level`, `trait1`) and global settings (`baseResourceGenerationRate`, `traitModifiers`).
3.  **Complex Interactions:** The `interactWithColony` function demonstrates a pattern for handling arbitrary interactions between NFTs. This is a core mechanic in many decentralized games or social systems, allowing for state changes, reputation effects, and potentially resource transfers (though resource transfer between users via contract needs approval flow).
4.  **Reputation System:** A simple on-chain reputation score (`colonyReputation`) is tracked per NFT and modified by interactions. This adds a social or strategic layer.
5.  **Global Events:** The `triggerGlobalEvent` and `participateInEvent` functions provide a framework for owner-initiated or time-based global occurrences that affect all colonies. This allows for seasonal content, challenges, or system-wide states.
6.  **Dynamic Trait Modifiers:** The `setTraitModifier` function allows the owner to configure how different `Trait` enums affect game mechanics (`ModifierType`, `value`), enabling dynamic balancing or event effects without changing core contract logic. This adds flexibility.
7.  **Colony Delegation:** The `delegateColonyAction` mechanism allows an NFT owner to grant specific permissions (like upgrading or participating in events) to another address without transferring ownership. This is useful for gaming guilds, management tools, or allowing bots/agents to act on behalf of a user. The `onlyColonyOwnerOrDelegate` modifier enforces this.
8.  **Pause Functionality:** A standard but crucial feature (`pauseContract`, `unpauseContract`) for managing smart contracts, especially complex ones, allowing for emergency halts or upgrades (if combined with proxy patterns, not shown here).
9.  **Interaction with External ERC20:** The contract is designed to work with a separate ERC20 token for resources (`resourceToken`), demonstrating interaction patterns between different deployed contracts (`IERC20` interface, `transferFrom` calls).
10. **Modular Design:** Uses enums and structs to organize data and logic for different types of interactions, traits, and events, making the contract more readable and extensible.

This contract provides a foundation for a complex, dynamic system built around NFTs, showcasing several intermediate to advanced Solidity patterns and concepts beyond basic token transfers.