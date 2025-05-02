Okay, let's design a smart contract that combines dynamic NFTs, token-bound accounts (ERC-6551), and an on-chain crafting/evolution system. We'll call it the "Dynamic NFT Forge".

This contract will allow users to mint "Artifact" NFTs. These artifacts aren't static images; they have internal state (level, stamina, etc.) and can own other tokens (specifically "Essence" tokens) through their own ERC-6551 accounts. Users can use Essences to evolve artifacts, use stamina for actions, craft new Essences, or even combine artifacts.

**Advanced Concepts Used:**

1.  **Dynamic NFTs:** NFT state changes based on on-chain interactions (evolution, stamina).
2.  **ERC-6551 Token Bound Accounts (TBAs):** Each NFT *is* an account that can hold tokens (Essences) and potentially interact with other contracts.
3.  **On-chain State per Token:** The contract manages complex data structures (`Artifact` struct) for each individual NFT ID.
4.  **Crafting/Minting Mechanic:** Users can create new tokens (Essences) by calling a contract function, potentially burning other tokens or paying a fee.
5.  **Evolution Mechanic:** NFTs level up based on criteria (holding specific Essences in their TBA, meeting stamina requirements).
6.  **Combination Mechanic:** Burning multiple NFTs to potentially create a new one with combined/altered properties.
7.  **Configurable Token Types:** Admin can define different types of Artifacts and Essences with distinct properties and rules.
8.  **Internal Token Ownership:** Essences are held *by* the Artifact's TBA, not the owner's wallet directly, providing a strong on-chain link.
9.  **Inter-Token Interaction:** Functions require transferring tokens *between* user wallets and NFT TBAs, or burning tokens held by TBAs.
10. **Arbitrary TBA Calls:** Ability for the NFT owner to trigger calls *from* the NFT's TBA.

**Outline:**

1.  **Pragma, Imports, Interfaces:** Define Solidity version, import ERC721, Ownable, ERC-6551 interfaces, and a custom Essence token interface.
2.  **Errors:** Custom errors for clarity.
3.  **Structs:** Define data structures for Artifacts, Artifact Type Configurations, and Essence Type Configurations.
4.  **State Variables:** Mappings to store Artifact data, type configurations, contract addresses for dependencies (Essence, TBA Registry, TBA Implementation), counters, base URI, pause status.
5.  **Events:** Define events for key actions (Minting, Evolution, Essence Transfer, Crafting, Combination, Usage, Stamina Regen).
6.  **Modifiers:** Standard `Ownable` and potentially `Pausable`.
7.  **Constructor:** Initialize contract with addresses of required dependencies.
8.  **ERC-721 Standard Functions:** (Inherited/Overridden) Name, Symbol, totalSupply, balanceOf, ownerOf, approvals, transfers, supportsInterface.
9.  **Custom Artifact Management:**
    *   Minting (`mintArtifact`)
    *   Getting Details (`getArtifactDetails`)
    *   Burning (`burnArtifact`)
10. **TBA Integration:**
    *   Deploying TBA (`deployArtifactTBA`)
    *   Getting TBA Address (`getArtifactTBA`)
    *   Executing Calls from TBA (`executeCallFromArtifactTBA`)
    *   Checking Essence Balances in TBA (`getArtifactEssenceBalance`)
11. **Essence Interaction & Crafting:**
    *   Adding Essences to TBA (`addEssenceToArtifact`)
    *   Removing Essences from TBA (`removeEssenceFromArtifact`)
    *   Crafting New Essences (`craftEssence`)
12. **Artifact Lifecycle:**
    *   Evolution (`evolveArtifact`)
    *   Stamina Usage (`useArtifact`)
    *   Stamina Regeneration (`regenerateStamina`)
    *   Derived/Helper Functions (`calculateEvolutionCost`, `calculateRequiredEssences`, `getTotalStamina`, `checkEvolutionRequirements`)
13. **Combination Mechanic:**
    *   Combining Artifacts (`combineArtifacts`)
14. **Configuration (Admin):**
    *   Setting Artifact Type Configs (`setArtifactTypeConfig`, `getArtifactTypeConfig`)
    *   Setting Essence Type Configs (`setEssenceTypeConfig`, `getEssenceTypeConfig`)
    *   Setting Base URI (`setBaseURI`)
15. **Metadata:**
    *   Overridden `tokenURI` to provide dynamic metadata.
16. **Admin Utilities:**
    *   Withdrawing Fees (`withdrawFees`)
    *   Pausing Minting (`pauseMinting`, `isMintingPaused`)

**Function Summary (Focusing on Custom/Extended Functions, aiming for >= 20):**

1.  `constructor(address _essenceToken, address _tbaRegistry, address _tbaAccountImplementation)`: Initializes the contract with addresses of the required ERC-1155 Essence token, the ERC-6551 Registry, and the ERC-6551 Account implementation.
2.  `mintArtifact(uint256 artifactTypeId)`: Mints a new ERC-721 Artifact token of a specified type to the caller. Initializes its state (level 1, full stamina) and *optionally* lazy-deploys its TBA. Requires payment based on type.
3.  `getArtifactDetails(uint256 tokenId)`: Returns the current on-chain state (level, stamina, essence count, last activity) of a specific Artifact NFT.
4.  `burnArtifact(uint256 tokenId)`: Allows the owner of an Artifact NFT to burn it, potentially reclaiming some resources or simply destroying it. Includes logic to transfer contents from its TBA first.
5.  `deployArtifactTBA(uint256 tokenId)`: Explicitly triggers the deployment of the ERC-6551 Token Bound Account for a given Artifact NFT if it doesn't already exist.
6.  `getArtifactTBA(uint256 tokenId)`: Computes and returns the deterministic address of the ERC-6551 account associated with a specific Artifact NFT.
7.  `executeCallFromArtifactTBA(uint256 tokenId, address target, uint256 value, bytes calldata data)`: Allows the owner of the Artifact NFT to trigger an arbitrary low-level call (`target.call{value}(data)`) *from* the NFT's Token Bound Account.
8.  `getArtifactEssenceBalance(uint256 artifactId, uint256 essenceTypeId)`: Queries the balance of a specific Essence token type held by the specified Artifact's Token Bound Account.
9.  `addEssenceToArtifact(uint256 artifactId, uint256 essenceTypeId, uint256 amount)`: Allows the Artifact owner to transfer a specified amount of a specific Essence token type *from their wallet* into the Artifact's Token Bound Account.
10. `removeEssenceFromArtifact(uint256 artifactId, uint256 essenceTypeId, uint256 amount)`: Allows the Artifact owner to transfer a specified amount of a specific Essence token type *from the Artifact's Token Bound Account* back to their wallet.
11. `craftEssence(uint256 essenceTypeId, uint256 amount)`: Allows a user to craft a specified amount of a specific Essence token type. Requires payment (e.g., ETH) based on the essence type configuration. Mints the Essences to the caller's wallet.
12. `evolveArtifact(uint256 tokenId)`: Attempts to evolve the specified Artifact NFT to the next level. Checks if the artifact meets criteria (e.g., holds required Essences in its TBA, sufficient stamina, current level < max level) and potentially consumes resources (stamina, essences) and/or requires a fee. Updates the artifact's level and stats.
13. `calculateEvolutionCost(uint256 tokenId)`: Pure function that calculates the potential cost (e.g., ETH, burning other tokens, required essences) to evolve a specific Artifact NFT to its next level based on its type and current level.
14. `calculateRequiredEssences(uint256 tokenId)`: Pure function that determines which Essence types and amounts are required to be held in the Artifact's TBA for it to be eligible to evolve to the next level.
15. `useArtifact(uint256 tokenId, uint256 usageCost)`: Decrements the stamina of the specified Artifact NFT by a given amount. Requires the artifact to have enough stamina.
16. `regenerateStamina(uint256 tokenId)`: Updates the stamina of the specified Artifact NFT based on the time elapsed since its `lastActivity` and its type's `staminaRegenRate`. Can be called by anyone to trigger regeneration.
17. `getTotalStamina(uint256 tokenId)`: Calculates the current effective stamina of an artifact, including any regeneration that has occurred since the last activity, without changing state.
18. `checkEvolutionRequirements(uint256 tokenId)`: Helper view function to check if an artifact currently meets all the on-chain criteria (essences held, stamina, level) to be *eligible* for evolution, returning true or false (and potentially details why not).
19. `combineArtifacts(uint256 tokenId1, uint256 tokenId2)`: Allows an owner holding two Artifact NFTs to combine them. This function burns both input NFTs and mints a new Artifact NFT (potentially of a new type or higher level), transferring essences from the burned TBAs to the new TBA and combining/averaging stats. Requires payment or specific conditions.
20. `setArtifactTypeConfig(uint256 artifactTypeId, ArtifactTypeConfig calldata config)`: Owner-only function to define or update the configuration (max level, initial stamina, regen rate, evolution base cost) for a specific artifact type ID.
21. `getArtifactTypeConfig(uint256 artifactTypeId)`: Returns the configuration details for a specific artifact type ID.
22. `setEssenceTypeConfig(uint256 essenceTypeId, EssenceTypeConfig calldata config)`: Owner-only function to define or update the configuration (name, description, properties, crafting cost, isConsumable) for a specific essence type ID.
23. `getEssenceTypeConfig(uint256 essenceTypeId)`: Returns the configuration details for a specific essence type ID.
24. `tokenURI(uint256 tokenId)`: Overrides the standard ERC-721 `tokenURI` to generate a metadata URI pointing to a JSON file or service that *dynamically* reflects the Artifact's current state (level, stamina, essences held in TBA) by fetching details via `getArtifactDetails` and `getArtifactEssenceBalance`.
25. `setBaseURI(string memory newURI)`: Owner-only function to update the base URI used in the `tokenURI` function.
26. `withdrawFees(address payable recipient)`: Owner-only function to withdraw collected ETH fees from the contract to a specified address.
27. `pauseMinting(bool paused)`: Owner-only function to pause or unpause the `mintArtifact` function.
28. `isMintingPaused()`: Returns the current pause status for minting.
29. `supportsInterface(bytes4 interfaceId)`: Standard ERC-165 implementation, required for ERC721Enumerable.

This list provides 28 custom functions, clearly exceeding the minimum requirement of 20 total functions when combined with the standard ERC-721 methods.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol"; // Needed if the Forge receives essences directly, but we transfer to TBA
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IEssenceToken.sol"; // Assuming a separate ERC-1155 contract for Essences

// Outline:
// 1. Pragma, Imports, Interfaces
// 2. Errors
// 3. Structs: Artifact, ArtifactTypeConfig, EssenceTypeConfig
// 4. State Variables: Artifact data, Type configs, Dependencies, Counters, URI, Pause state
// 5. Events
// 6. Modifiers (Ownable, Pausable)
// 7. Constructor
// 8. ERC-721 Standard Functions (Inherited/Overridden)
// 9. Custom Artifact Management: mint, details, burn
// 10. TBA Integration: deploy, get address, execute call from TBA, get essence balance in TBA
// 11. Essence Interaction: add to TBA, remove from TBA, craft new
// 12. Artifact Lifecycle: evolve, use stamina, regenerate stamina, helper checks
// 13. Combination Mechanic: combine artifacts
// 14. Configuration (Admin): set type configs
// 15. Metadata: tokenURI override
// 16. Admin Utilities: withdraw fees, pause minting

/**
 * @title DynamicNFTForge
 * @dev A smart contract for minting, managing, and evolving dynamic NFTs ("Artifacts")
 *      that own items ("Essences") via ERC-6551 Token Bound Accounts.
 *      Includes crafting, evolution, and combination mechanics.
 */
contract DynamicNFTForge is ERC721Enumerable, Ownable, ReentrancyGuard {
    // 2. Errors
    error InvalidArtifactId();
    error InvalidArtifactTypeId();
    error InvalidEssenceTypeId();
    error MintingPaused();
    error NotArtifactOwner();
    error InsufficientStamina(uint256 required, uint256 current);
    error MaxLevelReached(uint256 currentLevel);
    error NotEnoughEssencesInTBA(uint256 essenceTypeId, uint256 required, uint256 current);
    error EvolutionRequirementsNotMet();
    error TBAAlreadyDeployed();
    error TBACallFailed(bytes result);
    error CannotCombineSameArtifact();
    error CannotCombineDifferentOwners();
    error CombinationFailed();
    error TransferFailed();
    error EthTransferFailed();

    // 3. Structs
    struct Artifact {
        uint256 artifactTypeId; // Type determines base stats and evolution path
        uint256 level;          // Current evolution level
        uint256 stamina;        // Current usage points
        uint256 lastActivity;   // Timestamp of last stamina-consuming action or regeneration
        // Essences are owned by the TBA, not stored directly here
        // Other dynamic properties could be added here or derived from Essences
    }

    struct ArtifactTypeConfig {
        string name;
        string description;
        uint256 initialStamina;
        uint256 staminaRegenRate; // Stamina points regenerated per second
        uint256 maxLevel;
        uint256 mintCost; // ETH cost to mint this type
        // Requirements for evolution (e.g., required essences per level) could be stored separately
    }

    struct EssenceTypeConfig {
        string name;
        string description;
        uint256 craftingCost; // ETH cost to craft this essence
        bool isConsumable;    // Can this essence be consumed (e.g., during evolution)?
        // Other properties like 'boost' or 'attribute' could be added here
        uint256 properties; // Example: a bitmask or ID representing inherent properties
    }

    // 4. State Variables
    uint256 private _nextTokenId;

    // Mappings for Artifact state and configs
    mapping(uint256 => Artifact) private _artifacts;
    mapping(uint256 => ArtifactTypeConfig) private _artifactTypeConfigs;
    mapping(uint256 => bool) private _artifactTypeExists; // To track valid types

    mapping(uint256 => EssenceTypeConfig) private _essenceTypeConfigs;
    mapping(uint256 => bool) private _essenceTypeExists; // To track valid types

    // Addresses of dependency contracts
    IEssenceToken public immutable essenceToken;
    IERC6551Registry public immutable tbaRegistry;
    IERC6551Account public immutable tbaAccountImplementation;

    bytes32 public immutable tbaSalt = keccak256("DynamicNFTForge.ArtifactTBA"); // Unique salt for TBA deployment
    bytes public immutable tbaInitData = ""; // Data to initialize the TBA (can be complex)

    string private _baseTokenURI;
    bool private _mintingPaused;

    // 5. Events
    event ArtifactMinted(uint256 indexed tokenId, address indexed owner, uint256 artifactTypeId);
    event ArtifactDetailsUpdated(uint256 indexed tokenId); // Generic event for state changes
    event ArtifactBurned(uint256 indexed tokenId, address indexed owner);
    event TBADeployed(uint256 indexed tokenId, address indexed tbaAddress);
    event EssenceAddedToTBA(uint256 indexed tokenId, uint256 indexed essenceTypeId, uint256 amount);
    event EssenceRemovedFromTBA(uint256 indexed tokenId, uint256 indexed essenceTypeId, uint256 amount);
    event EssencesCrafted(address indexed crafter, uint256 indexed essenceTypeId, uint256 amount);
    event ArtifactEvolved(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event ArtifactUsed(uint256 indexed tokenId, uint256 usageCost, uint256 newStamina);
    event StaminaRegenerated(uint256 indexed tokenId, uint256 oldStamina, uint256 newStamina);
    event ArtifactsCombined(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId);
    event ArtifactTypeConfigUpdated(uint256 indexed artifactTypeId);
    event EssenceTypeConfigUpdated(uint256 indexed essenceTypeId);
    event BaseURIUpdated(string newURI);
    event MintingPausedStatusUpdated(bool isPaused);
    event FeesWithdrawn(address indexed recipient, uint256 amount);


    // 7. Constructor
    constructor(
        address _essenceToken,
        address _tbaRegistry,
        address _tbaAccountImplementation
    ) ERC721Enumerable("Dynamic Artifact", "DART") Ownable(msg.sender) {
        if (_essenceToken == address(0) || _tbaRegistry == address(0) || _tbaAccountImplementation == address(0)) {
            revert("Invalid dependency address");
        }
        essenceToken = IEssenceToken(_essenceToken);
        tbaRegistry = IERC6551Registry(_tbaRegistry);
        tbaAccountImplementation = IERC6551Account(_tbaAccountImplementation);
        _nextTokenId = 1; // Start token IDs from 1
        _mintingPaused = false;
    }

    // 8. ERC-721 Standard Functions are mostly inherited.
    // We override tokenURI for dynamic metadata.
    // We don't need to override transfers as ERC6551 handles interaction with TBAs.
    // supportsInterface is implemented by ERC721Enumerable which imports ERC165.

    // 9. Custom Artifact Management

    /**
     * @dev Mints a new Artifact NFT of a specific type.
     * @param artifactTypeId The ID of the artifact type to mint.
     */
    // Function #1 (Custom) - mintArtifact
    function mintArtifact(uint256 artifactTypeId) external payable nonReentrant {
        if (_mintingPaused) revert MintingPaused();
        if (!_artifactTypeExists[artifactTypeId]) revert InvalidArtifactTypeId();

        ArtifactTypeConfig memory config = _artifactTypeConfigs[artifactTypeId];
        if (msg.value < config.mintCost) revert("Insufficient ETH for minting");

        uint256 newTokenId = _nextTokenId++;
        _safeMint(msg.sender, newTokenId);

        _artifacts[newTokenId] = Artifact({
            artifactTypeId: artifactTypeId,
            level: 1,
            stamina: config.initialStamina,
            lastActivity: block.timestamp
        });

        // Optional: Lazy deploy TBA immediately or deploy on first interaction?
        // Lazy deploy is generally more gas efficient until needed.
        // We'll add a separate function to deploy explicitly.

        emit ArtifactMinted(newTokenId, msg.sender, artifactTypeId);

        // Return excess ETH if any
        if (msg.value > config.mintCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - config.mintCost}("");
            if (!success) revert EthTransferFailed(); // Should ideally handle this gracefully or require exact amount
        }
    }

    /**
     * @dev Gets the detailed on-chain state of an Artifact NFT.
     * @param tokenId The ID of the artifact token.
     * @return Artifact struct containing the artifact's state.
     */
    // Function #2 (Custom) - getArtifactDetails
    function getArtifactDetails(uint256 tokenId) public view returns (Artifact memory) {
        if (!_exists(tokenId)) revert InvalidArtifactId();
        return _artifacts[tokenId];
    }

    /**
     * @dev Allows the owner to burn their Artifact NFT.
     *      Transfers contents from the TBA back to the owner first.
     * @param tokenId The ID of the artifact token to burn.
     */
    // Function #3 (Custom) - burnArtifact
    function burnArtifact(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner) revert NotArtifactOwner();

        // Transfer all essences from TBA back to owner before burning
        address tbaAddress = getArtifactTBA(tokenId); // Gets deterministic address, doesn't require deployment

        // WARNING: This simple implementation transfers *all* known essence types.
        // A more robust version would iterate through held types or require specifying which to transfer.
        // For demonstration, we'll just try to transfer a sample essence type (e.g., type 1)
        // In a real scenario, you'd need a way to list contents or transfer specific known types.
        uint256 sampleEssenceTypeId = 1; // Example: Assuming essence type 1 exists and is transferable
        uint256 balanceInTBA = essenceToken.balanceOf(tbaAddress, sampleEssenceTypeId);
        if (balanceInTBA > 0) {
             try essenceToken.safeTransferFrom(tbaAddress, owner, sampleEssenceTypeId, balanceInTBA, "") returns (bool success) {
                if (!success) {
                    // Handle partial success or failure - maybe log event? Revert for strictness here.
                    revert TransferFailed();
                }
                emit EssenceRemovedFromTBA(tokenId, sampleEssenceTypeId, balanceInTBA);
             } catch Error(string memory reason) {
                 revert(string(abi.encodePacked("Failed to transfer essences from TBA: ", reason)));
             } catch {
                 revert("Failed to transfer essences from TBA (unknown reason)");
             }
        }


        // Burn the NFT
        _burn(tokenId);
        delete _artifacts[tokenId]; // Clear the state data

        // Note: The TBA remains deployed but essentially orphaned. ERC6551 v2 might address this.
        // For now, it's harmless unless it held native tokens or permissions elsewhere.

        emit ArtifactBurned(tokenId, owner);
    }

    // 10. TBA Integration

    /**
     * @dev Deploys the ERC-6551 Token Bound Account for an Artifact NFT.
     *      Anyone can call this, but it's typically triggered by the owner or system.
     * @param tokenId The ID of the artifact token.
     */
    // Function #4 (Custom) - deployArtifactTBA
    function deployArtifactTBA(uint256 tokenId) external nonReentrant {
        if (!_exists(tokenId)) revert InvalidArtifactId();

        // The TBA address is deterministic, we check if code exists there
        address tbaAddress = tbaRegistry.account(
            tbaAccountImplementation,
            block.chainid,
            address(this), // NFT contract address
            tokenId,
            tbaSalt
        );

        if (tbaAddress.code.length > 0) revert TBAAlreadyDeployed();

        tbaRegistry.createAccount(
            tbaAccountImplementation,
            block.chainid,
            address(this),
            tokenId,
            tbaSalt,
            tbaInitData
        );

        emit TBADeployed(tokenId, tbaAddress);
    }

    /**
     * @dev Computes the deterministic address of the ERC-6551 account for an Artifact NFT.
     *      Does NOT deploy the account.
     * @param tokenId The ID of the artifact token.
     * @return The deterministic address of the artifact's TBA.
     */
    // Function #5 (Custom) - getArtifactTBA
    function getArtifactTBA(uint256 tokenId) public view returns (address) {
         if (!_exists(tokenId)) revert InvalidArtifactId(); // Ensure token exists

        return tbaRegistry.account(
            tbaAccountImplementation,
            block.chainid,
            address(this), // NFT contract address
            tokenId,
            tbaSalt
        );
    }

    /**
     * @dev Allows the NFT owner to execute an arbitrary call from the Artifact's TBA.
     *      Requires the TBA implementation to correctly handle execution permissions
     *      (usually by checking if the original caller is the NFT owner).
     * @param tokenId The ID of the artifact token.
     * @param target The address to call from the TBA.
     * @param value The ETH value to send with the call from the TBA.
     * @param data The calldata for the call.
     */
    // Function #6 (Custom) - executeCallFromArtifactTBA
    function executeCallFromArtifactTBA(uint256 tokenId, address target, uint256 value, bytes calldata data) external nonReentrant {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner) revert NotArtifactOwner();

        address tbaAddress = getArtifactTBA(tokenId);

        // This function assumes the TBA implementation is ERC6551Account compatible
        // and has an execute() function that verifies the caller's permission
        // (i.e., checking if msg.sender to the execute function is the NFT owner or approved).
        // The standard ERC6551Account implementation typically does this.
        IERC6551Account tbaAccount = IERC6551Account(tbaAddress);

        (bool success, bytes memory result) = tbaAccount.execute(target, value, data, 0); // Assuming callType 0 for standard call

        if (!success) {
             // Revert with the reason from the call if available
             if (result.length > 0) {
                 // Attempt to decode revert reason string
                 assembly {
                     revert(add(32, result), mload(result))
                 }
             } else {
                 revert TBACallFailed(result);
             }
        }
        // No specific event for arbitrary call success, rely on events from the target contract
    }

    /**
     * @dev Gets the balance of a specific Essence token type held by the Artifact's TBA.
     * @param artifactId The ID of the artifact token.
     * @param essenceTypeId The ID of the essence type.
     * @return The amount of the specified essence type held by the TBA.
     */
    // Function #7 (Custom) - getArtifactEssenceBalance
    function getArtifactEssenceBalance(uint256 artifactId, uint256 essenceTypeId) public view returns (uint256) {
        if (!_exists(artifactId)) revert InvalidArtifactId();
        if (!_essenceTypeExists[essenceTypeId]) revert InvalidEssenceTypeId();

        address tbaAddress = getArtifactTBA(artifactId);
        return essenceToken.balanceOf(tbaAddress, essenceTypeId);
    }


    // 11. Essence Interaction & Crafting

    /**
     * @dev Allows the NFT owner to transfer Essence tokens from their wallet to the Artifact's TBA.
     * @param artifactId The ID of the artifact token.
     * @param essenceTypeId The ID of the essence type to add.
     * @param amount The amount of essences to add.
     */
    // Function #8 (Custom) - addEssenceToArtifact
    function addEssenceToArtifact(uint256 artifactId, uint256 essenceTypeId, uint256 amount) external nonReentrant {
        address owner = ownerOf(artifactId);
        if (msg.sender != owner) revert NotArtifactOwner();
        if (!_essenceTypeExists[essenceTypeId]) revert InvalidEssenceTypeId();
        if (amount == 0) return;

        address tbaAddress = getArtifactTBA(artifactId);

        // Ensure the TBA account is deployed - transferring to a non-existent address might fail
        // A better approach might be to lazy-deploy the TBA if it doesn't exist here.
        // For simplicity, let's add a check or require explicit deployment first.
        if (tbaAddress.code.length == 0) {
             // Consider adding deployArtifactTBA(artifactId); here if gas cost is acceptable
             revert("Artifact TBA not deployed. Call deployArtifactTBA first.");
        }


        // ERC-1155 safeTransferFrom from caller to TBA address
        // Requires the caller to have approved this contract to spend their essences,
        // OR requires the caller to be the essence owner and essence contract allows owner transfers.
        // Assuming standard ERC1155 behavior where caller must approve.
        try essenceToken.safeTransferFrom(msg.sender, tbaAddress, essenceTypeId, amount, "") returns (bool success) {
            if (!success) revert TransferFailed(); // This check might be redundant if safeTransferFrom reverts on failure
        } catch Error(string memory reason) {
             revert(string(abi.encodePacked("Essence transfer to TBA failed: ", reason)));
        } catch {
             revert("Essence transfer to TBA failed (unknown reason)");
        }


        // Note: We don't strictly need to track essences in the Artifact struct,
        // as the TBA is the source of truth via getArtifactEssenceBalance.
        // But we could update a counter if useful for certain logic.

        emit EssenceAddedToTBA(artifactId, essenceTypeId, amount);
        emit ArtifactDetailsUpdated(artifactId);
    }

    /**
     * @dev Allows the NFT owner to transfer Essence tokens from the Artifact's TBA back to their wallet.
     *      This requires executing the transfer *from* the TBA.
     * @param artifactId The ID of the artifact token.
     * @param essenceTypeId The ID of the essence type to remove.
     * @param amount The amount of essences to remove.
     */
    // Function #9 (Custom) - removeEssenceFromArtifact
    function removeEssenceFromArtifact(uint256 artifactId, uint256 essenceTypeId, uint256 amount) external nonReentrant {
        address owner = ownerOf(artifactId);
        if (msg.sender != owner) revert NotArtifactOwner();
        if (!_essenceTypeExists[essenceTypeId]) revert InvalidEssenceTypeId();
        if (amount == 0) return;

        address tbaAddress = getArtifactTBA(artifactId);
        if (essenceToken.balanceOf(tbaAddress, essenceTypeId) < amount) revert NotEnoughEssencesInTBA(essenceTypeId, amount, essenceToken.balanceOf(tbaAddress, essenceTypeId));

        // Need to call safeTransferFrom from the TBA address
        // This requires using the executeCallFromArtifactTBA mechanism.
        // Construct the calldata for essenceToken.safeTransferFrom(tbaAddress, owner, essenceTypeId, amount, "")
        bytes memory callData = abi.encodeWithSelector(
            IEssenceToken.safeTransferFrom.selector,
            tbaAddress, // from (the TBA itself)
            owner,      // to (the NFT owner)
            essenceTypeId,
            amount,
            "" // data
        );

        // Use the execute function of the TBA
        IERC6551Account tbaAccount = IERC6551Account(tbaAddress);
        (bool success, bytes memory result) = tbaAccount.execute(address(essenceToken), 0, callData, 0); // Call type 0

        if (!success) {
             if (result.length > 0) {
                 assembly { revert(add(32, result), mload(result)) }
             } else {
                 revert TBACallFailed(result);
             }
        }

        emit EssenceRemovedFromTBA(artifactId, essenceTypeId, amount);
        emit ArtifactDetailsUpdated(artifactId);
    }

    /**
     * @dev Allows a user to craft new Essence tokens by paying ETH.
     * @param essenceTypeId The ID of the essence type to craft.
     * @param amount The amount of essences to craft.
     */
    // Function #10 (Custom) - craftEssence
    function craftEssence(uint256 essenceTypeId, uint256 amount) external payable nonReentrant {
        if (!_essenceTypeExists[essenceTypeId]) revert InvalidEssenceTypeId();
        if (amount == 0) return;

        EssenceTypeConfig memory config = _essenceTypeConfigs[essenceTypeId];
        uint256 totalCost = config.craftingCost * amount;

        if (msg.value < totalCost) revert("Insufficient ETH for crafting");

        // Mint essences directly to the crafter
        // Assumes the EssenceToken contract has a mint function callable by the Forge contract
        // In IEssenceToken interface, we define a `mint` function callable by this contract.
        // Or, more securely, the Essence contract could allow minting by the Forge contract address.
        essenceToken.mint(msg.sender, essenceTypeId, amount, ""); // Assuming mint function takes (to, id, amount, data)

        emit EssencesCrafted(msg.sender, essenceTypeId, amount);

        // Return excess ETH
         if (msg.value > totalCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
            if (!success) revert EthTransferFailed();
        }
    }


    // 12. Artifact Lifecycle

    /**
     * @dev Attempts to evolve an Artifact NFT to the next level.
     *      Checks requirements (level, stamina, essences in TBA) and potentially consumes resources.
     * @param tokenId The ID of the artifact token.
     */
    // Function #11 (Custom) - evolveArtifact
    function evolveArtifact(uint256 tokenId) external payable nonReentrant {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner) revert NotArtifactOwner();

        Artifact storage artifact = _artifacts[tokenId];
        ArtifactTypeConfig memory typeConfig = _artifactTypeConfigs[artifact.artifactTypeId];

        if (artifact.level >= typeConfig.maxLevel) revert MaxLevelReached(artifact.level);

        // First, update stamina based on time passed
        _regenerateStaminaInternal(tokenId);

        // Check current stamina (after potential regeneration)
        if (artifact.stamina < typeConfig.initialStamina / 2) revert InsufficientStamina(typeConfig.initialStamina / 2, artifact.stamina); // Example requirement: needs >= 50% stamina

        // Check required essences in TBA
        // Example: Evolution requires 5 of Essence Type 1 and 3 of Essence Type 2 per level
        uint256 requiredEssence1 = 5 * artifact.level; // Example requirement scaling with level
        uint256 requiredEssence2 = 3 * artifact.level;

        if (getArtifactEssenceBalance(tokenId, 1) < requiredEssence1) revert NotEnoughEssencesInTBA(1, requiredEssence1, getArtifactEssenceBalance(tokenId, 1));
        if (getArtifactEssenceBalance(tokenId, 2) < requiredEssence2) revert NotEnoughEssencesInTBA(2, requiredEssence2, getArtifactEssenceBalance(tokenId, 2));

        // Check ETH cost (can scale with level)
        uint256 evolutionCost = typeConfig.mintCost * artifact.level / 2; // Example cost scaling

        if (msg.value < evolutionCost) revert("Insufficient ETH for evolution");


        // --- All requirements met, perform evolution actions ---

        // Consume stamina
        artifact.stamina = artifact.stamina >= typeConfig.initialStamina / 2 ? artifact.stamina - typeConfig.initialStamina / 2 : 0; // Consume the required stamina
        artifact.lastActivity = block.timestamp; // Reset activity timer after using stamina

        // Consume essences from TBA
        address tbaAddress = getArtifactTBA(tokenId);
        // This requires calling burn/safeTransferFrom from the TBA's context
        // Need to construct calldata for each burn and execute them via executeCallFromArtifactTBA

        bytes memory callData1 = abi.encodeWithSelector(
             IEssenceToken.safeTransferFrom.selector,
             tbaAddress, // from (the TBA itself)
             address(0), // to (burning address)
             1,          // essenceTypeId
             requiredEssence1,
             ""          // data
         );
        bytes memory callData2 = abi.encodeWithSelector(
             IEssenceToken.safeTransferFrom.selector,
             tbaAddress, // from (the TBA itself)
             address(0), // to (burning address)
             2,          // essenceTypeId
             requiredEssence2,
             ""          // data
         );

        IERC6551Account tbaAccount = IERC6551Account(tbaAddress);

        // Execute burns from TBA (chained calls or separate calls)
        (bool success1,) = tbaAccount.execute(address(essenceToken), 0, callData1, 0);
        if (!success1) revert TBACallFailed("Essence 1 burn failed from TBA");

        (bool success2,) = tbaAccount.execute(address(essenceToken), 0, callData2, 0);
        if (!success2) revert TBACallFailed("Essence 2 burn failed from TBA");

        // Increment level
        uint256 oldLevel = artifact.level;
        artifact.level++;
        // Potentially increase max stamina, regen rate etc. based on new level
        // This depends on how type configs handle scaling - simple here.

        emit ArtifactEvolved(tokenId, oldLevel, artifact.level);
        emit ArtifactDetailsUpdated(tokenId);

        // Return excess ETH
         if (msg.value > evolutionCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - evolutionCost}("");
            if (!success) revert EthTransferFailed();
        }
    }


    /**
     * @dev Calculates the potential cost (ETH) to evolve an artifact to the next level.
     *      Pure function, does not check actual requirements or change state.
     * @param tokenId The ID of the artifact token.
     * @return The ETH cost for the next evolution level.
     */
    // Function #12 (Custom) - calculateEvolutionCost
    function calculateEvolutionCost(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidArtifactId();
        Artifact memory artifact = _artifacts[tokenId];
        ArtifactTypeConfig memory typeConfig = _artifactTypeConfigs[artifact.artifactTypeId];

        if (artifact.level >= typeConfig.maxLevel) return 0; // Already at max level

        // Example cost scaling: Mint cost * current level / 2
        return typeConfig.mintCost * artifact.level / 2;
    }

    /**
     * @dev Determines the required Essence types and amounts for the next evolution level.
     *      Pure function, does not check actual balances or change state.
     *      Returns arrays of essence type IDs and required amounts.
     * @param tokenId The ID of the artifact token.
     * @return essenceTypeIds Array of required essence type IDs.
     * @return requiredAmounts Array of corresponding required amounts.
     */
    // Function #13 (Custom) - calculateRequiredEssences
    function calculateRequiredEssences(uint256 tokenId) public view returns (uint256[] memory essenceTypeIds, uint256[] memory requiredAmounts) {
        if (!_exists(tokenId)) revert InvalidArtifactId();
        Artifact memory artifact = _artifacts[tokenId];
        ArtifactTypeConfig memory typeConfig = _artifactTypeConfigs[artifact.artifactTypeId];

        if (artifact.level >= typeConfig.maxLevel) {
            return (new uint256[](0), new uint256[](0)); // Already at max level
        }

        // Example requirements:
        essenceTypeIds = new uint256[](2);
        requiredAmounts = new uint256[](2);

        essenceTypeIds[0] = 1; // Essence Type 1
        requiredAmounts[0] = 5 * artifact.level; // Scales with current level

        essenceTypeIds[1] = 2; // Essence Type 2
        requiredAmounts[1] = 3 * artifact.level; // Scales with current level

        return (essenceTypeIds, requiredAmounts);
    }

     /**
     * @dev Checks if an artifact meets all requirements for evolution.
     *      View function, calculates current state but doesn't change it.
     * @param tokenId The ID of the artifact token.
     * @return isEligible True if eligible, false otherwise.
     * @return reason A string explaining why it's not eligible (empty if eligible).
     */
    // Function #14 (Custom) - checkEvolutionRequirements
    function checkEvolutionRequirements(uint256 tokenId) public view returns (bool isEligible, string memory reason) {
        if (!_exists(tokenId)) return (false, "Invalid artifact ID");
        Artifact memory artifact = _artifacts[tokenId];
        ArtifactTypeConfig memory typeConfig = _artifactTypeConfigs[artifact.artifactTypeId];

        if (artifact.level >= typeConfig.maxLevel) return (false, "Max level reached");

        // Calculate current effective stamina
        uint256 currentStamina = getTotalStamina(tokenId);
        if (currentStamina < typeConfig.initialStamina / 2) return (false, string(abi.encodePacked("Insufficient stamina: needs ", uint2str(typeConfig.initialStamina / 2), ", has ", uint2str(currentStamina))));

        // Check required essences
        (uint256[] memory ids, uint256[] memory amounts) = calculateRequiredEssences(tokenId);
        address tbaAddress = getArtifactTBA(tokenId);

        for(uint i = 0; i < ids.length; i++) {
            uint256 heldAmount = essenceToken.balanceOf(tbaAddress, ids[i]);
            if (heldAmount < amounts[i]) {
                 return (false, string(abi.encodePacked("Insufficient essence ", uint2str(ids[i]), ": needs ", uint2str(amounts[i]), ", has ", uint2str(heldAmount))));
            }
        }

        // Check ETH cost (assuming caller will provide ETH)
        // This view function can't check msg.value, just calculate the cost needed.
        uint256 requiredEth = calculateEvolutionCost(tokenId);
        // We can't check caller's balance here, but we can indicate the cost.
        // A more advanced version might require a separate "prepare for evolution" step or use permits.

        // All on-chain state requirements met
        return (true, "");
    }


    /**
     * @dev Decrements an Artifact's stamina. Simulates an action costing stamina.
     *      Stamina regenerates over time, but using it resets the activity timer.
     * @param tokenId The ID of the artifact token.
     * @param usageCost The amount of stamina to subtract.
     */
    // Function #15 (Custom) - useArtifact
    function useArtifact(uint256 tokenId, uint256 usageCost) external nonReentrant {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner) revert NotArtifactOwner();
        if (usageCost == 0) return;

        Artifact storage artifact = _artifacts[tokenId];
        ArtifactTypeConfig memory typeConfig = _artifactTypeConfigs[artifact.artifactTypeId];

        // Regenerate stamina first
        _regenerateStaminaInternal(tokenId);

        if (artifact.stamina < usageCost) revert InsufficientStamina(usageCost, artifact.stamina);

        artifact.stamina -= usageCost;
        artifact.lastActivity = block.timestamp; // Reset activity timer

        emit ArtifactUsed(tokenId, usageCost, artifact.stamina);
        emit ArtifactDetailsUpdated(tokenId);
    }

    /**
     * @dev Regenerates the stamina of an Artifact based on elapsed time and regen rate.
     *      Internal helper function, called by useArtifact and evolveArtifact.
     * @param tokenId The ID of the artifact token.
     */
    function _regenerateStaminaInternal(uint256 tokenId) internal {
        Artifact storage artifact = _artifacts[tokenId];
        ArtifactTypeConfig memory typeConfig = _artifactTypeConfigs[artifact.artifactTypeId];

        uint256 timePassed = block.timestamp - artifact.lastActivity;
        uint256 regenerated = timePassed * typeConfig.staminaRegenRate;

        uint256 oldStamina = artifact.stamina;
        artifact.stamina = artifact.stamina + regenerated > typeConfig.initialStamina
            ? typeConfig.initialStamina
            : artifact.stamina + regenerated;

        if (artifact.stamina > oldStamina) {
             artifact.lastActivity = block.timestamp; // Update activity only if stamina actually increased
             emit StaminaRegenerated(tokenId, oldStamina, artifact.stamina);
             emit ArtifactDetailsUpdated(tokenId);
        }
        // If stamina was already full or regen rate is 0, lastActivity isn't updated by regen.
    }


    /**
     * @dev Calculates the current effective stamina of an artifact, including regeneration.
     *      View function, does not change state.
     * @param tokenId The ID of the artifact token.
     * @return The current effective stamina.
     */
    // Function #16 (Custom) - getTotalStamina
    function getTotalStamina(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidArtifactId();
         Artifact memory artifact = _artifacts[tokenId];
         ArtifactTypeConfig memory typeConfig = _artifactTypeConfigs[artifact.artifactTypeId];

         uint256 timePassed = block.timestamp - artifact.lastActivity;
         uint256 regenerated = timePassed * typeConfig.staminaRegenRate;

         uint256 currentStamina = artifact.stamina + regenerated;
         return currentStamina > typeConfig.initialStamina ? typeConfig.initialStamina : currentStamina;
    }


    // 13. Combination Mechanic

    /**
     * @dev Allows the owner to combine two Artifact NFTs into one new one.
     *      Burns the original two, mints a new one, combines/transfers essences and stats.
     *      This is a complex example; actual combination logic would vary.
     * @param tokenId1 The ID of the first artifact token.
     * @param tokenId2 The ID of the second artifact token.
     */
    // Function #17 (Custom) - combineArtifacts
    function combineArtifacts(uint256 tokenId1, uint256 tokenId2) external payable nonReentrant {
        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        if (msg.sender != owner1 || msg.sender != owner2) revert CannotCombineDifferentOwners();
        if (tokenId1 == tokenId2) revert CannotCombineSameArtifact();
        if (!_exists(tokenId1) || !_exists(tokenId2)) revert InvalidArtifactId();

        Artifact storage artifact1 = _artifacts[tokenId1];
        Artifact storage artifact2 = _artifacts[tokenId2];

        // --- Example Combination Logic (can be highly complex) ---
        // This is a simplified example. Real logic might involve:
        // - Specific artifact type combinations
        // - Chance of success/failure
        // - Burning specific essences as cost
        // - Determining the new artifact type based on inputs
        // - Calculating new level/stamina/stats based on combined inputs

        // Basic Example: Burn both, mint a new one of a default/derived type,
        // transfer ALL essences from both TBAs to the new one's TBA,
        // and average the levels and stamina.

        // Determine the new artifact type (e.g., type 3, a "Fused" artifact)
        uint256 newArtifactTypeId = 3; // Example: Assumes type 3 exists and is configured
        if (!_artifactTypeExists[newArtifactTypeId]) revert CombinationFailed(); // New type must be valid

        ArtifactTypeConfig memory newTypeConfig = _artifactTypeConfigs[newArtifactTypeId];

        // Calculate average level and initial stamina for the new artifact
        uint256 newLevel = (artifact1.level + artifact2.level) / 2;
        if (newLevel == 0) newLevel = 1; // Minimum level 1
        if (newLevel > newTypeConfig.maxLevel) newLevel = newTypeConfig.maxLevel;

        uint256 currentStamina1 = getTotalStamina(tokenId1); // Use calculated total stamina
        uint256 currentStamina2 = getTotalStamina(tokenId2);
        uint256 newStamina = (currentStamina1 + currentStamina2) / 2;
        if (newStamina > newTypeConfig.initialStamina) newStamina = newTypeConfig.initialStamina;


        // --- Perform the combination actions ---

        // Get TBA addresses (needs deterministic addresses)
        address tbaAddress1 = getArtifactTBA(tokenId1);
        address tbaAddress2 = getArtifactTBA(tokenId2);

        // Burn the original artifacts (includes clearing state)
        _burn(tokenId1);
        delete _artifacts[tokenId1];
        _burn(tokenId2);
        delete _artifacts[tokenId2];

        // Mint the new artifact
        uint256 newTokenId = _nextTokenId++;
        _safeMint(msg.sender, newTokenId);

        _artifacts[newTokenId] = Artifact({
            artifactTypeId: newArtifactTypeId,
            level: newLevel,
            stamina: newStamina, // Initialize with calculated stamina
            lastActivity: block.timestamp // Set initial activity time
        });

        // Deploy the new artifact's TBA
        deployArtifactTBA(newTokenId); // Must deploy before transferring items
        address newTbaAddress = getArtifactTBA(newTokenId);

        // Transfer all essences from old TBAs to new TBA
        // This is complex! Requires querying balances of *all* essence types
        // in the old TBAs and executing transfers from them.
        // For simplicity, let's assume we only care about a fixed set of essence types (e.g., 1 and 2)
        // A real system would need to handle any essence type dynamically.

        uint256[] memory essenceTypesToCombine = new uint256[](2); // Example: Only transfer types 1 and 2
        essenceTypesToCombine[0] = 1;
        essenceTypesToCombine[1] = 2;

        IERC6551Account tbaAccount1 = IERC6551Account(tbaAddress1);
        IERC6551Account tbaAccount2 = IERC6551Account(tbaAddress2);

        for (uint i = 0; i < essenceTypesToCombine.length; i++) {
            uint256 essenceTypeId = essenceTypesToCombine[i];
            uint256 balance1 = essenceToken.balanceOf(tbaAddress1, essenceTypeId);
            uint256 balance2 = essenceToken.balanceOf(tbaAddress2, essenceTypeId);

            if (balance1 > 0) {
                bytes memory callData = abi.encodeWithSelector(
                    IEssenceToken.safeTransferFrom.selector,
                    tbaAddress1, // from
                    newTbaAddress, // to
                    essenceTypeId,
                    balance1,
                    ""
                );
                (bool success,) = tbaAccount1.execute(address(essenceToken), 0, callData, 0);
                // Decide whether to revert the whole combination if one transfer fails
                // For simplicity, we'll revert. A complex system might allow partial transfers.
                if (!success) revert CombinationFailed();
                 emit EssenceRemovedFromTBA(tokenId1, essenceTypeId, balance1); // Essences moved *from* the old TBA
                 emit EssenceAddedToTBA(newTokenId, essenceTypeId, balance1); // Essences moved *to* the new TBA
            }
             if (balance2 > 0) {
                 bytes memory callData = abi.encodeWithSelector(
                    IEssenceToken.safeTransferFrom.selector,
                    tbaAddress2, // from
                    newTbaAddress, // to
                    essenceTypeId,
                    balance2,
                    ""
                );
                (bool success,) = tbaAccount2.execute(address(essenceToken), 0, callData, 0);
                 if (!success) revert CombinationFailed();
                 emit EssenceRemovedFromTBA(tokenId2, essenceTypeId, balance2);
                 emit EssenceAddedToTBA(newTokenId, essenceTypeId, balance2);
            }
        }

        emit ArtifactsCombined(tokenId1, tokenId2, newTokenId);
        emit ArtifactDetailsUpdated(newTokenId);

        // Return excess ETH if any (combination might have a fee)
        // Example combination fee: sum of mint costs / 2
        uint256 combinationFee = (_artifactTypeConfigs[artifact1.artifactTypeId].mintCost + _artifactTypeConfigs[artifact2.artifactTypeId].mintCost) / 2;
         if (msg.value > combinationFee) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - combinationFee}("");
            if (!success) revert EthTransferFailed();
        }
    }


    // 14. Configuration (Admin)

    /**
     * @dev Owner-only function to set or update the configuration for an artifact type.
     *      Artifacts can only be minted for configured types.
     * @param artifactTypeId The ID of the artifact type.
     * @param config The ArtifactTypeConfig struct containing configuration details.
     */
    // Function #18 (Custom) - setArtifactTypeConfig
    function setArtifactTypeConfig(uint256 artifactTypeId, ArtifactTypeConfig calldata config) external onlyOwner {
        _artifactTypeConfigs[artifactTypeId] = config;
        _artifactTypeExists[artifactTypeId] = true;
        emit ArtifactTypeConfigUpdated(artifactTypeId);
    }

    /**
     * @dev Returns the configuration details for a specific artifact type ID.
     * @param artifactTypeId The ID of the artifact type.
     * @return The ArtifactTypeConfig struct.
     */
    // Function #19 (Custom) - getArtifactTypeConfig
    function getArtifactTypeConfig(uint256 artifactTypeId) external view returns (ArtifactTypeConfig memory) {
         if (!_artifactTypeExists[artifactTypeId]) revert InvalidArtifactTypeId();
         return _artifactTypeConfigs[artifactTypeId];
    }


    /**
     * @dev Owner-only function to set or update the configuration for an essence type.
     *      Essences can only be crafted for configured types.
     * @param essenceTypeId The ID of the essence type.
     * @param config The EssenceTypeConfig struct containing configuration details.
     */
    // Function #20 (Custom) - setEssenceTypeConfig
    function setEssenceTypeConfig(uint256 essenceTypeId, EssenceTypeConfig calldata config) external onlyOwner {
        _essenceTypeConfigs[essenceTypeId] = config;
        _essenceTypeExists[essenceTypeId] = true;
        emit EssenceTypeConfigUpdated(essenceTypeId);
    }

     /**
     * @dev Returns the configuration details for a specific essence type ID.
     * @param essenceTypeId The ID of the essence type.
     * @return The EssenceTypeConfig struct.
     */
    // Function #21 (Custom) - getEssenceTypeConfig
    function getEssenceTypeConfig(uint256 essenceTypeId) external view returns (EssenceTypeConfig memory) {
         if (!_essenceTypeExists[essenceTypeId]) revert InvalidEssenceTypeId();
         return _essenceTypeConfigs[essenceTypeId];
    }

    // 15. Metadata

    /**
     * @dev Returns the metadata URI for a specific Artifact NFT.
     *      This overrides the default ERC721 behavior to provide dynamic metadata.
     *      It constructs a URI pointing to a service that can query the artifact's
     *      on-chain state (level, stamina, essences in TBA) and build a dynamic JSON.
     * @param tokenId The ID of the artifact token.
     * @return The metadata URI.
     */
    // Function #22 (Custom) - tokenURI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidArtifactId();

        // The dynamic metadata should be served from a backend service that
        // reads the on-chain state (getArtifactDetails, getArtifactEssenceBalance)
        // and formats it into ERC721 metadata JSON.
        // The URI typically includes the base URI and the token ID.
        // Example: "https://mydynamicservice.com/api/metadata/artifact/123"

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            // Fallback or default metadata logic if base URI is not set
            // Or return an empty string if no metadata is available without a base URI.
            // Let's return a placeholder or error indicator for this example.
             return string(abi.encodePacked("ERROR: Base URI not set for dynamic metadata for token ", uint2str(tokenId)));
        }

        // Construct the full URI (e.g., baseURI + tokenId)
        // You might need string manipulation helper functions here.
        // Using simple concatenation for demonstration.
        return string(abi.encodePacked(base, uint2str(tokenId)));

        // Note: A more advanced implementation might pass query parameters
        // like chainId, contract address, etc., to the metadata service.
        // E.g., string(abi.encodePacked(base, "?id=", uint2str(tokenId), "&chainId=", uint2str(block.chainid), ...));
    }

    /**
     * @dev Owner-only function to set the base URI for dynamic metadata.
     * @param newURI The new base URI string.
     */
    // Function #23 (Custom) - setBaseURI
    function setBaseURI(string memory newURI) external onlyOwner {
        _baseTokenURI = newURI;
        emit BaseURIUpdated(newURI);
    }


    // 16. Admin Utilities

    /**
     * @dev Owner-only function to withdraw accumulated ETH fees.
     * @param recipient The address to send the ETH to.
     */
    // Function #24 (Custom) - withdrawFees
    function withdrawFees(address payable recipient) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) return;

        (bool success, ) = recipient.call{value: balance}("");
        if (!success) revert EthTransferFailed(); // Revert if transfer fails

        emit FeesWithdrawn(recipient, balance);
    }

    /**
     * @dev Owner-only function to pause or unpause artifact minting.
     * @param paused True to pause, false to unpause.
     */
    // Function #25 (Custom) - pauseMinting
    function pauseMinting(bool paused) external onlyOwner {
        if (_mintingPaused != paused) {
            _mintingPaused = paused;
            emit MintingPausedStatusUpdated(paused);
        }
    }

    /**
     * @dev Returns the current minting pause status.
     * @return True if minting is paused, false otherwise.
     */
    // Function #26 (Custom) - isMintingPaused
    function isMintingPaused() external view returns (bool) {
        return _mintingPaused;
    }

     // 27. uint to string helper (for error messages and URIs)
     // Function #27 (Custom) - uint2str
     function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    // --- Standard ERC721 functions implicitly included ---
    // name()
    // symbol()
    // totalSupply()
    // balanceOf(address owner)
    // ownerOf(uint256 tokenId)
    // getApproved(uint256 tokenId)
    // isApprovedForAll(address owner, address operator)
    // approve(address to, uint256 tokenId)
    // setApprovalForAll(address operator, bool approved)
    // transferFrom(address from, address to, uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
    // supportsInterface(bytes4 interfaceId) - inherited from ERC721Enumerable which imports ERC165

    // Total Custom/Extended Functions Defined: 27
    // Total Standard ERC721/ERC165 Functions (inherited/overridden): 13
    // Total Functions: 27 + 13 = 40+ (Well over 20)
}

// --- Required Interfaces (to be defined in separate files) ---

// interface IEssenceToken is IERC1155 {
//     function mint(address to, uint256 id, uint256 amount, bytes calldata data) external; // Example mint function callable by Forge
//     // Add other relevant ERC1155 functions if needed
// }

// interface IERC6551Registry {
//     function account(address implementation, uint256 chainid, address tokenContract, uint256 tokenId, uint256 salt) external view returns (address);
//     function createAccount(address implementation, uint256 chainid, address tokenContract, uint256 tokenId, uint256 salt, bytes calldata initData) external returns (address);
// }

// interface IERC6551Account {
//    function execute(address target, uint256 value, bytes calldata data, uint256 callType) external payable returns (bool success, bytes memory result);
//    function token() external view returns (uint256 chainid, address tokenContract, uint256 tokenId);
//    // Add other relevant functions if needed by the Forge
// }

// --- Note on EssenceToken.sol ---
// For this contract to compile and work, you would need a separate ERC-1155
// contract deployed as the EssenceToken. This EssenceToken contract must:
// 1. Implement the standard ERC-1155 interface.
// 2. Have a `mint` function that allows this DynamicNFTForge contract address
//    to mint new essence tokens (e.g., restricted via Ownable, AccessControl, or a simple check).
// 3. Be deployed and its address provided to the DynamicNFTForge constructor.

// --- Note on ERC-6551 ---
// This contract depends on a deployed ERC-6551 Registry contract and an ERC-6551
// Account Implementation contract. These are standard components of the ERC-6551
// ecosystem and would need to be deployed on the target chain or sourced from a
// well-known deployment (like the ones provided by the ERC-6551 community).
// The implementation address provided to the constructor determines the behavior
// and security model of the artifact's accounts.

// --- Note on Dynamic Metadata ---
// The `tokenURI` implementation points to an external service. This service is
// crucial for displaying the dynamic state of the NFT on marketplaces or wallets.
// It would need to query the blockchain (using `getArtifactDetails`,
// `getArtifactEssenceBalance`, `getArtifactTBA`, etc.) and construct the
// metadata JSON object according to the ERC721 metadata standard, reflecting
// the current level, stamina, and contents of the artifact's TBA.
```