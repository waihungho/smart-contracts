Okay, let's design a smart contract that manages dynamic, evolving digital entities (like NFTs) whose properties change over time and based on external data provided via an oracle. We'll call these entities "Metamorphs".

This concept combines:
1.  **Dynamic NFTs:** Properties aren't static; they can change after minting.
2.  **Epoch System:** Time is segmented into phases, potentially triggering or influencing changes.
3.  **Oracle Integration:** External data (simulating environmental factors, AI analysis, etc.) influences the evolution process.
4.  **Owner Interaction:** Owners can trigger attempts at evolution, perhaps at a cost.
5.  **Parametric Evolution:** Evolution rules are based on current state, external data, and internal "seed" data.

This avoids directly copying common patterns like standard ERC20/ERC721 (though it uses ERC721 base), simple staking, basic marketplaces, or standard upgradeable proxies (the logic isn't *upgraded*, but the state and parameters change).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial admin control
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// 1. Define Struct for Metamorph Properties
// 2. State Variables (Epoch, Oracle, Admin, Fees, Counters, Mappings)
// 3. Events
// 4. Modifiers (Admin, Oracle, Paused)
// 5. ERC721 Standard Functions (Inherited/Overridden)
// 6. Core Minting Logic
// 7. Oracle Interaction & Environmental Data Update
// 8. Epoch Management
// 9. Metamorph Evolution Logic (Internal & External Trigger)
// 10. View Functions (Getters for state and properties)
// 11. Admin & Fee Management Functions
// 12. Pause/Unpause Mechanism
// 13. Burning

// Function Summary:
// 1. constructor: Initializes the contract with admin, oracle address, and initial parameters.
// 2. mint: Allows users to mint a new Metamorph NFT, paying a fee. Initializes properties based on seed and current state.
// 3. burn: Allows the owner of a Metamorph to destroy it.
// 4. tokenURI: Returns the dynamic metadata URI for a Metamorph (requires off-chain service).
// 5. getMetamorphProperties: View function to retrieve the full property struct of a Metamorph.
// 6. getMetamorphBirthEpoch: View function to get the epoch a Metamorph was minted in.
// 7. getMetamorphLastEvolutionEpoch: View function to get the last epoch a Metamorph evolved.
// 8. getMetamorphSeed: View function to get the unique seed of a Metamorph.
// 9. updateEnvironmentalVector: Callable only by the designated oracle address to update global environmental data.
// 10. getEnvironmentalVector: View function to get the current global environmental data.
// 11. advanceEpoch: Allows admin (or anyone, if timed) to advance the contract's internal epoch counter.
// 12. getCurrentEpoch: View function to get the current epoch number.
// 13. triggerEvolutionAttempt: Allows a Metamorph owner to pay a fee and attempt to evolve their Metamorph based on current epoch and environmental data.
// 14. setOracleAddress: Admin function to change the oracle address.
// 15. getOracleAddress: View function to get the current oracle address.
// 16. setAdminAddress: Admin function to transfer administrative control.
// 17. getAdminAddress: View function to get the current admin address.
// 18. setMintPrice: Admin function to set the price for minting.
// 19. getMintPrice: View function to get the current mint price.
// 20. setEvolutionAttemptPrice: Admin function to set the price for triggering an evolution attempt.
// 21. getEvolutionAttemptPrice: View function to get the current evolution attempt price.
// 22. withdrawFees: Admin function to withdraw collected ETH fees.
// 23. pause: Admin function to pause core interactions (minting, evolution attempts).
// 24. unpause: Admin function to unpause the contract.
// 25. isPaused: View function to check if the contract is paused.
// (Plus standard ERC721Enumerable functions: ownerOf, balanceOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom, totalSupply, tokenByIndex, tokenOfOwnerByIndex - total > 20)


contract MetaMorph is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // 1. Struct for Metamorph Properties
    // Example properties - can be expanded
    struct MetamorphProperties {
        uint256 birthEpoch;
        uint256 lastEvolutionEpoch;
        uint256 seed; // Unique seed for this metamorph, influences evolution
        // Example Attributes - using uint for simplicity
        uint256 strength;
        uint256 agility;
        int256 vitality; // Using int for potential negative impacts
        uint256 rarityScore; // Derived from properties
    }

    // 2. State Variables
    mapping(uint256 => MetamorphProperties) private _metamorphs;
    uint256 public currentEpoch;
    mapping(uint8 => int256) public environmentalVector; // Represents global external factors
    address public oracleAddress; // Address authorized to update environmental data
    address public adminAddress; // Separate admin role for configuration
    uint256 public mintPrice; // Price to mint a new Metamorph
    uint256 public evolutionAttemptPrice; // Price to attempt evolving a Metamorph
    uint256 public MAX_SUPPLY = 1000; // Example maximum supply
    uint256 public constant EPOCH_DURATION = 1 days; // Example: Epoch advances every day
    uint256 public lastEpochAdvanceTimestamp;

    bool public paused = false;

    // 3. Events
    event MetamorphMinted(uint256 indexed tokenId, address indexed owner, uint256 birthEpoch);
    event PropertiesChanged(uint256 indexed tokenId, uint256 epoch, MetamorphProperties oldProps, MetamorphProperties newProps);
    event EnvironmentalVectorUpdated(address indexed oracle, uint256 indexed epoch);
    event EpochAdvanced(uint256 indexed oldEpoch, uint256 indexed newEpoch);
    event EvolutionAttemptTriggered(uint256 indexed tokenId, address indexed caller, uint256 epoch, bool success);
    event ContractPaused(address indexed admin);
    event ContractUnpaused(address indexed admin);
    event FeeWithdrawal(address indexed admin, address indexed recipient, uint256 amount);
    event MetamorphBurned(uint256 indexed tokenId, address indexed owner);


    // 4. Modifiers
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not the oracle");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not the admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // 5. ERC721 Standard Functions are mostly handled by inheritance.
    // We need to override transfer/safeTransfer to ensure _metamorphs mapping is clean if using storage pointers,
    // but with value types (struct copied on assignment), it's less critical.
    // However, ERC721Enumerable requires overriding hooks for tracking.
    // We also need to override tokenURI.

    // 1. constructor
    constructor(address initialAdmin, address initialOracle, uint256 initialMintPrice, uint256 initialEvolutionPrice)
        ERC721Enumerable("MetaMorph", "MORPH")
        Ownable(initialAdmin) // Owner initially is the admin
    {
        adminAddress = initialAdmin; // Set admin explicitly
        oracleAddress = initialOracle;
        mintPrice = initialMintPrice;
        evolutionAttemptPrice = initialEvolutionPrice;
        currentEpoch = 1;
        lastEpochAdvanceTimestamp = block.timestamp;
    }

    // ERC721Enumerable overrides
    // ERC721Enumerable requires _beforeTokenTransfer and _afterTokenTransfer overrides
    // to update its internal indexing structures. We don't need special Metamorph logic here
    // as the struct is mapped by tokenId, which doesn't change.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    // 4. tokenURI
    // This function should point to an external service that generates metadata JSON dynamically
    // based on the token ID and potentially the contract's state (like current epoch).
    // Example: base URI could be "https://api.metamorph.io/metadata/"
    // The service at https://api.metamorph.io/metadata/123 would query the contract state for token 123
    // and generate a JSON like { name: "Metamorph #123", description: "...", attributes: [...] }
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Base URI needs to be set (e.g., via an admin function, or hardcoded)
        // For this example, let's use a placeholder. In a real app, manage this.
        // string memory baseURI = "https://api.metamorph.io/metadata/"; // Example base URI
        // return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));

        // Placeholder implementation - you MUST replace this with a real metadata service URI
        return string(abi.encodePacked("ipfs://QmWt", Strings.toString(tokenId))); // Example IPFS-like placeholder
    }

    // 6. Core Minting Logic
    // 2. mint
    function mint() external payable whenNotPaused nonReentrant {
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        require(msg.value >= mintPrice, "Insufficient payment");

        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, newItemId);

        // Generate a seed for the new metamorph (can be improved for better pseudo-randomness)
        // Using block.timestamp, block.difficulty (or chainid/gasprice on modern chains), and msg.sender is common but predictable.
        // A more robust approach might involve a Chainlink VRF or similar.
        uint256 metamorphSeed = uint256(keccak256(abi.encodePacked(newItemId, msg.sender, block.timestamp, block.difficulty)));

        // Initialize properties (simple example)
        MetamorphProperties memory newProps;
        newProps.birthEpoch = currentEpoch;
        newProps.lastEvolutionEpoch = currentEpoch;
        newProps.seed = metamorphSeed;
        newProps.strength = (metamorphSeed % 100) + 50; // Base 50-149
        newProps.agility = ((metamorphSeed / 100) % 100) + 50; // Base 50-149
        newProps.vitality = 100; // Start with 100 vitality
        newProps.rarityScore = 0; // Calculated later or starts low

        _metamorphs[newItemId] = newProps;

        emit MetamorphMinted(newItemId, msg.sender, currentEpoch);

        // Refund excess ETH if any
        if (msg.value > mintPrice) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }
    }

     // 13. Burning
    // 3. burn
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");

        address owner = ownerOf(tokenId); // Get owner before burning
        _burn(tokenId); // Standard ERC721 burn

        // Clean up the metamorph properties mapping (optional but good practice)
        delete _metamorphs[tokenId];

        emit MetamorphBurned(tokenId, owner);
    }


    // 7. Oracle Interaction & Environmental Data Update
    // 9. updateEnvironmentalVector
    function updateEnvironmentalVector(uint8[] calldata keys, int256[] calldata values) external onlyOracle whenNotPaused {
        require(keys.length == values.length, "Keys and values mismatch");
        // Optional: Check if enough time has passed or if epoch has advanced since last update
        // require(currentEpoch > lastOracleUpdateEpoch, "Oracle already updated this epoch");

        for (uint i = 0; i < keys.length; i++) {
            environmentalVector[keys[i]] = values[i];
        }

        // lastOracleUpdateEpoch = currentEpoch; // Track last update epoch if needed
        emit EnvironmentalVectorUpdated(msg.sender, currentEpoch);
    }

    // 10. getEnvironmentalVector (View)
    function getEnvironmentalVector(uint8 key) external view returns (int256) {
        return environmentalVector[key];
    }

    // 8. Epoch Management
    // 11. advanceEpoch
    function advanceEpoch() external whenNotPaused nonReentrant {
        // This can be called by anyone, but it only advances if enough time has passed
        // Or restrict to admin if preferred
        require(block.timestamp >= lastEpochAdvanceTimestamp + EPOCH_DURATION, "Epoch duration not passed");

        emit EpochAdvanced(currentEpoch, currentEpoch + 1);
        currentEpoch++;
        lastEpochAdvanceTimestamp = block.timestamp;

        // Optional: Trigger batch evolution for all metamorphs in this function?
        // This could be gas-intensive. The current design allows owners to trigger evolution.
        // A separate "batchEvolve" function might be better, potentially callable by admin or with a fee.
    }

    // 12. getCurrentEpoch (View)
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }


    // 9. Metamorph Evolution Logic
    // Internal function containing the core evolution rules
    function _evolveMetamorph(uint256 tokenId) internal {
        MetamorphProperties storage props = _metamorphs[tokenId];
        require(props.birthEpoch > 0, "Metamorph does not exist"); // Basic check
        require(props.lastEvolutionEpoch < currentEpoch, "Metamorph already evolved this epoch");

        MetamorphProperties memory oldProps = props; // Store old properties for event

        // --- Evolution Rules (Example Logic) ---
        // This is where the core, creative logic goes.
        // Rules depend on:
        // 1. Current properties (`props`)
        // 2. Environmental vector (`environmentalVector`)
        // 3. Metamorph's unique seed (`props.seed`)
        // 4. Current epoch (`currentEpoch`)

        // Example Rule 1: Strength increases if environmental vector element 0 is positive
        if (environmentalVector[0] > 0) {
            props.strength += uint256(environmentalVector[0] / 10 + 1); // Add based on vector value
        } else if (environmentalVector[0] < 0) {
             // Example Rule 2: Strength decreases if environmental vector element 0 is negative
             // Ensure strength doesn't go below a minimum (e.g., 1)
            int256 decrease = environmentalVector[0] / 20 - 1;
            if (int256(props.strength) + decrease > 0) {
                 props.strength = uint256(int256(props.strength) + decrease);
            } else {
                 props.strength = 1; // Minimum strength
            }
        }

        // Example Rule 3: Agility is influenced by environmental vector element 1 and seed
        int256 agilityModifier = (environmentalVector[1] + int256(props.seed % 50 - 25)); // Seed adds randomness
        if (agilityModifier > 0) {
             props.agility += uint256(agilityModifier) / 5 + 1;
        } else {
             int256 agiDecrease = agilityModifier / 10 -1;
             if (int256(props.agility) + agiDecrease > 0) {
                  props.agility = uint256(int256(props.agility) + agiDecrease);
             } else {
                  props.agility = 1; // Minimum agility
             }
        }

        // Example Rule 4: Vitality changes based on epoch and other properties
        // Vitality decreases each epoch, but gains based on combined strength/agility
        props.vitality -= 5; // Base decay
        props.vitality += int256((props.strength + props.agility) / 20); // Gain from stats
        props.vitality += environmentalVector[2]; // Environmental influence on vitality

        // Cap vitality
        if (props.vitality > 200) props.vitality = 200;
        if (props.vitality < 0) props.vitality = 0; // Metamorph dies if vitality hits 0? (Requires burning logic)

        // Example Rule 5: Rarity Score is a function of other stats
        props.rarityScore = (props.strength + props.agility + uint256(props.vitality)) * uint256(currentEpoch);


        // Ensure properties stay within reasonable bounds if needed
        if (props.strength > 500) props.strength = 500;
        if (props.agility > 500) props.agility = 500;


        // --- End Evolution Rules ---

        props.lastEvolutionEpoch = currentEpoch; // Mark as evolved this epoch

        emit PropertiesChanged(tokenId, currentEpoch, oldProps, props);

        // Note: If vitality hits 0, you might want to burn the token here or mark it as "deceased".
        // This requires additional state/logic not included in this example for brevity.
        // if (props.vitality == 0) { _burn(tokenId); delete _metamorphs[tokenId]; emit MetamorphBurned(...); }
    }

    // 13. triggerEvolutionAttempt
    function triggerEvolutionAttempt(uint256 tokenId) external payable whenNotPaused nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        require(msg.value >= evolutionAttemptPrice, "Insufficient payment");
        require(_metamorphs[tokenId].lastEvolutionEpoch < currentEpoch, "Metamorph already evolved this epoch");

        // Refund excess ETH
        if (msg.value > evolutionAttemptPrice) {
            payable(msg.sender).transfer(msg.value - evolutionAttemptPrice);
        }

        _evolveMetamorph(tokenId); // Perform the evolution

        // Emit success explicitly
        emit EvolutionAttemptTriggered(tokenId, msg.sender, currentEpoch, true);
    }

    // 10. View Functions (Getters)
    // 5. getMetamorphProperties
    function getMetamorphProperties(uint256 tokenId) external view returns (MetamorphProperties memory) {
        require(_exists(tokenId), "Metamorph does not exist");
        return _metamorphs[tokenId];
    }

    // 6. getMetamorphBirthEpoch
    function getMetamorphBirthEpoch(uint256 tokenId) external view returns (uint256) {
         require(_exists(tokenId), "Metamorph does not exist");
         return _metamorphs[tokenId].birthEpoch;
    }

    // 7. getMetamorphLastEvolutionEpoch
    function getMetamorphLastEvolutionEpoch(uint256 tokenId) external view returns (uint256) {
         require(_exists(tokenId), "Metamorph does not exist");
         return _metamorphs[tokenId].lastEvolutionEpoch;
    }

    // 8. getMetamorphSeed
    function getMetamorphSeed(uint256 tokenId) external view returns (uint256) {
         require(_exists(tokenId), "Metamorph does not exist");
         return _metamorphs[tokenId].seed;
    }


    // 11. Admin & Fee Management Functions
    // 14. setOracleAddress
    function setOracleAddress(address _oracleAddress) external onlyAdmin {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }

    // 15. getOracleAddress (View)
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

    // 16. setAdminAddress
    // Overrides Ownable's transferOwnership to allow a separate admin role transfer
    function setAdminAddress(address _adminAddress) external onlyAdmin {
        require(_adminAddress != address(0), "Admin address cannot be zero");
        adminAddress = _adminAddress;
        // If you want the ERC721 Ownable owner to also be the admin,
        // you might transfer ownership here as well, or just rely on this custom admin role.
        // transferOwnership(_adminAddress); // Optional: Keep ERC721 Ownable owner in sync
    }

     // 17. getAdminAddress (View)
    function getAdminAddress() external view returns (address) {
        return adminAddress;
    }

    // 18. setMintPrice
    function setMintPrice(uint256 _mintPrice) external onlyAdmin {
        mintPrice = _mintPrice;
    }

    // 19. getMintPrice (View)
     function getMintPrice() external view returns (uint256) {
        return mintPrice;
    }

    // 20. setEvolutionAttemptPrice
    function setEvolutionAttemptPrice(uint256 _evolutionAttemptPrice) external onlyAdmin {
        evolutionAttemptPrice = _evolutionAttemptPrice;
    }

     // 21. getEvolutionAttemptPrice (View)
     function getEvolutionAttemptPrice() external view returns (uint256) {
        return evolutionAttemptPrice;
    }


    // 22. withdrawFees
    function withdrawFees() external onlyAdmin nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        // Sending to the current admin address
        payable(adminAddress).transfer(balance);
        emit FeeWithdrawal(msg.sender, adminAddress, balance);
    }

    // 12. Pause/Unpause Mechanism
    // 23. pause
    function pause() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    // 24. unpause
    function unpause() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // 25. isPaused (View)
    function isPaused() external view returns (bool) {
        return paused;
    }

    // Total functions:
    // - constructor (1)
    // - mint (1)
    // - burn (1)
    // - tokenURI (1)
    // - getMetamorphProperties (1)
    // - getMetamorphBirthEpoch (1)
    // - getMetamorphLastEvolutionEpoch (1)
    // - getMetamorphSeed (1)
    // - updateEnvironmentalVector (1)
    // - getEnvironmentalVector (1)
    // - advanceEpoch (1)
    // - getCurrentEpoch (1)
    // - triggerEvolutionAttempt (1)
    // - setOracleAddress (1)
    // - getOracleAddress (1)
    // - setAdminAddress (1)
    // - getAdminAddress (1)
    // - setMintPrice (1)
    // - getMintPrice (1)
    // - setEvolutionAttemptPrice (1)
    // - getEvolutionAttemptPrice (1)
    // - withdrawFees (1)
    // - pause (1)
    // - unpause (1)
    // - isPaused (1)
    // Subtotal: 25 custom/overridden functions.

    // - ERC721Enumerable includes (public/external):
    //   ownerOf, balanceOf, approve, getApproved, setApprovalForAll,
    //   isApprovedForAll, transferFrom, safeTransferFrom(address,address,uint256),
    //   safeTransferFrom(address,address,uint256,bytes), totalSupply,
    //   tokenByIndex, tokenOfOwnerByIndex.
    //   That's 12 more standard ERC721Enumerable functions.

    // Total public/external functions = 25 + 12 = 37 functions. This meets the requirement.
}
```

---

**Explanation of Concepts and Design Choices:**

1.  **Dynamic State:** The `MetamorphProperties` struct mapped by `tokenId` holds the dynamic state of each NFT. This state is mutable by specific contract logic, not just transferrable like standard NFTs.
2.  **Epoch System:** `currentEpoch` and `lastEpochAdvanceTimestamp` create discrete time periods. Evolution happens *per epoch* per Metamorph. The `advanceEpoch` function allows moving to the next phase, potentially controlled by time elapsed or an admin trigger.
3.  **Oracle Integration:** `oracleAddress` and `updateEnvironmentalVector` demonstrate how external data can influence the contract. An off-chain oracle service would call `updateEnvironmentalVector` periodically or in response to real-world events, updating the global `environmentalVector`. This vector serves as a shared environmental influence for all Metamorphs.
4.  **Triggered Evolution:** Instead of forcing all Metamorphs to evolve every epoch (which would be gas-prohibitive for a large collection), owners (or potentially anyone paying a fee) can `triggerEvolutionAttempt` for a *specific* token. This decentralizes the gas cost of evolution. The check `props.lastEvolutionEpoch < currentEpoch` ensures each Metamorph can only evolve once per epoch via this method.
5.  **Parametric Evolution Logic (`_evolveMetamorph`):** This internal function is the heart of the "metamorphosis". The example rules show how properties can change based on:
    *   Their current values.
    *   The global `environmentalVector` (external influence).
    *    The Metamorph's unique `seed` (introducing a fixed individual variation).
    *   The `currentEpoch` (allowing for epoch-specific rules or scaling effects).
    *   The logic is deterministic given the inputs. True randomness would require a service like Chainlink VRF.
6.  **Separation of Concerns:** Admin functions (`onlyAdmin`), Oracle functions (`onlyOracle`), and user functions (mint, trigger evolution) are distinct. `Ownable` is used for initial deployment and admin role setting, but a separate `adminAddress` state variable allows transferring the custom admin role independently if desired (though in this simple case, they are linked initially).
7.  **Fee Mechanism:** `mintPrice` and `evolutionAttemptPrice` allow the contract deployer/admin to monetize the creation and evolution processes. `withdrawFees` is a standard pattern to collect accumulated ETH.
8.  **Pause Mechanism:** A standard safety feature allowing the admin to temporarily halt core mutable operations in case of issues.
9.  **Dynamic Metadata (`tokenURI`):** The contract only provides a URI. A separate off-chain service is crucial to serve dynamic JSON metadata by reading the Metamorph's current properties from the blockchain and formatting them according to the ERC721 metadata standard.
10. **Inheritance:** Uses standard OpenZeppelin libraries (`ERC721Enumerable`, `Ownable`, `Counters`, `ReentrancyGuard`) for robustness and standard compliance where applicable. `ERC721Enumerable` adds functions to iterate over tokens, which is useful for external applications displaying the collection.

This contract provides a framework for a dynamic, data-influenced NFT collection with built-in mechanics for change and interaction, moving beyond static image-based NFTs.