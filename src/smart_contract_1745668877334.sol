Okay, let's create a contract that implements dynamic, evolving NFTs with mechanics like morphing, fusion, staking, and decay, tied to an integrated resource token. This covers several advanced concepts and requires a significant number of functions.

We'll call it `MetaMorphNFT`.

**Concept:** NFTs representing creatures or items that can evolve (`morph`) through stages by consuming an integrated resource token (`Catalyst`) and meeting certain conditions (like cooldowns). They can also be combined (`fuse`) or staked to earn Catalyst or gain benefits. Lack of interaction might lead to decay.

---

**Outline & Function Summary: `MetaMorphNFT.sol`**

This contract is an ERC721 token with advanced mechanics for dynamic, evolving NFTs.

**Core Concepts:**
1.  **Dynamic State:** NFTs have mutable attributes and a "Stage" that can change.
2.  **Morphing:** NFTs can evolve to a higher stage, changing attributes, requires `Catalyst` tokens and cooldown.
3.  **Catalyst Token:** An integrated, minimal ERC20-like token needed for morphing and fusion.
4.  **Fusion:** Combine multiple NFTs to create a new one (with a chance of success/failure).
5.  **Staking:** Stake NFTs to earn Catalyst tokens over time.
6.  **Decay:** NFTs can potentially degrade in stage or attributes if not interacted with or maintained.
7.  **On-Chain Attributes:** Core attributes are stored on-chain.
8.  **Dynamic Metadata:** `tokenURI` reflects the current state (stage, attributes).
9.  **Admin Configurability:** Key parameters can be adjusted by the contract owner.

**Inheritance:**
*   Inherits from a standard ERC721 implementation (assuming OpenZeppelin, but the code focuses on custom logic).
*   Inherits from Ownable for administrative control.

**State Variables:**
*   Counters: `_tokenIdCounter`, `_catalystSupply`.
*   Mappings: `_nftDetails`, `_catalystBalances`, `_stakedNFTs`.
*   Structs: `NFTDetails`, `NFTAttributes`, `StakingInfo`, `StageConfig`.
*   Configuration: `_stageConfigs`, `_morphCooldown`, `_baseMorphSuccessRate`, `_stakingYieldRate`, `_decayRate`, `_decayEnabled`, `_minFusionNFTs`, `_maxFusionNFTs`, `_baseFusionSuccessRate`, `_tokenURISuffix`.
*   Events: `NFTMinted`, `NFTMorphed`, `CatalystMinted`, `CatalystBurned`, `NFTStaked`, `NFTUnstaked`, `StakingRewardClaimed`, `NFTFused`, `NFTDecayed`, `ParameterChanged`.

**Functions (25+):**

*   **ERC721 Standard (Assumed/Overridden):**
    *   `balanceOf(address owner)`: Standard ERC721.
    *   `ownerOf(uint256 tokenId)`: Standard ERC721.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC721.
    *   `approve(address to, uint256 tokenId)`: Standard ERC721.
    *   `setApprovalForAll(address operator, bool approved)`: Standard ERC721.
    *   `getApproved(uint256 tokenId)`: Standard ERC721.
    *   `isApprovedForAll(address owner, address operator)`: Standard ERC721.
    *   `supportsInterface(bytes4 interfaceId)`: Standard ERC721.
    *   `tokenURI(uint256 tokenId)`: **Override**. Generates metadata URI based on NFT state.

*   **NFT Core Actions & Queries:**
    *   `mintInitialNFT(address to)`: Creates a new Stage 0 NFT.
    *   `morph(uint256 tokenId)`: Attempts to evolve an NFT to the next stage. Requires Catalyst and cooldown.
    *   `fuseNFTs(uint256[] calldata tokenIds)`: Attempts to combine multiple NFTs into one. Requires Catalyst and burns input NFTs.
    *   `applyDecay(uint256 tokenId)`: Applies decay effects based on elapsed time if decay is enabled. Can be called by anyone (gas-gated internally).
    *   `getNFTDetails(uint256 tokenId)`: Returns comprehensive details of an NFT (stage, attributes, last morph time, staking info).
    *   `getRarityScore(uint256 tokenId)`: Calculates a basic rarity score based on stage and attributes.
    *   `isMorphReady(uint256 tokenId)`: Checks if an NFT meets the time condition for morphing.
    *   `isNFTStaked(uint256 tokenId)`: Checks if an NFT is currently staked.

*   **Staking Functions:**
    *   `stakeNFT(uint256 tokenId)`: Stakes an NFT, making it unavailable for transfer/morphing/fusion but eligible for rewards.
    *   `unstakeNFT(uint256 tokenId)`: Unstakes an NFT, ending reward accumulation.
    *   `claimStakingRewards(uint256 tokenId)`: Calculates and transfers pending Catalyst rewards for a staked NFT.
    *   `calculatePendingStakingRewards(uint256 tokenId)`: Views the amount of Catalyst rewards currently accrued for a staked NFT.
    *   `getNFTStakingStartTime(uint256 tokenId)`: Gets the timestamp when an NFT was staked.

*   **Catalyst Token (Integrated) Functions:**
    *   `getCatalystBalance(address owner)`: Returns the Catalyst balance for an address.
    *   `transferCatalyst(address recipient, uint256 amount)`: Transfers Catalyst tokens (basic).
    *   `approveCatalyst(address spender, uint256 amount)`: Allows a spender to withdraw Catalyst (basic).
    *   `transferFromCatalyst(address sender, address recipient, uint256 amount)`: Transfers Catalyst using allowance (basic).
    *   `mintCatalystAdmin(address recipient, uint256 amount)`: Mints Catalyst tokens (Admin only, potentially for ecosystem use or initial distribution).
    *   `burnCatalyst(uint256 amount)`: Burns Catalyst tokens from the caller's balance. (Used internally by morph/fuse, but exposed for potential external burn mechanics).

*   **Admin/Configuration Functions (Owner Only):**
    *   `setMorphCooldown(uint256 cooldown)`: Sets the time required between morph attempts.
    *   `setBaseMorphSuccessRate(uint16 rate)`: Sets the base success rate for morphing (0-10000 representing 0-100%).
    *   `setStageConfig(uint8 stage, uint16 minAttr, uint16 maxAttr)`: Sets attribute boundaries for a given stage.
    *   `setStakingYieldRate(uint256 ratePerSecond)`: Sets the rate at which staked NFTs earn Catalyst.
    *   `setDecayRate(uint256 ratePerSecond)`: Sets the rate at which decay accumulates (higher stage/attributes might decay faster, logic implemented internally).
    *   `toggleDecay(bool enabled)`: Enables or disables the decay mechanic.
    *   `setMinFusionNFTs(uint8 min)`: Sets the minimum number of NFTs required for fusion.
    *   `setMaxFusionNFTs(uint8 max)`: Sets the maximum number of NFTs allowed for fusion.
    *   `setBaseFusionSuccessRate(uint16 rate)`: Sets the base success rate for fusion.
    *   `setFusionOutputStage(uint8 stage)`: Sets the stage of the NFT minted upon successful fusion.
    *   `setTokenURISuffix(string memory suffix)`: Sets the base path/suffix for the metadata URI.
    *   `setStakingCatalystMintAmount(uint256 amount)`: Sets the amount of Catalyst minted *per second* globally for staking rewards (distributed proportionally). *Correction:* Staking yield rate is simpler (`_stakingYieldRate`), representing rate per NFT per second. Let's stick to that. We need a function to *fund* the staking rewards or just mint them on claim. Minting on claim is simpler for this example. Rename this func to `setStakingCatalystMintRatePerNFT`.
    *   `setStakingCatalystMintRatePerNFT(uint256 rate)`: Sets the rate (amount per second) of Catalyst minted per staked NFT. (Replaces the previous idea).
    *   `renounceOwnership()`: Standard Ownable.
    *   `transferOwnership(address newOwner)`: Standard Ownable.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // To get total supply easily
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For on-chain metadata JSON

// Minimal ERC20 interface for clarity on integrated token
interface ICatalyst {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}


/**
 * @title MetaMorphNFT
 * @dev An ERC721 contract with dynamic, evolving NFTs.
 * Features: Morphing, Fusion, Staking, Decay, Integrated Catalyst Token, Dynamic Metadata.
 */
contract MetaMorphNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Math for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _catalystSupply; // Integrated token supply counter

    // NFT Data
    struct NFTAttributes {
        uint16 strength;
        uint16 dexterity;
        uint16 constitution;
        uint16 intelligence;
        uint16 wisdom;
        uint16 charisma;
    }

    struct NFTDetails {
        uint8 stage;
        NFTAttributes attributes;
        uint48 lastMorphTime; // Use uint48 for timestamps to save gas
        uint48 lastDecayTime; // Use uint48 for timestamps
    }
    mapping(uint255 => NFTDetails) private _nftDetails; // Use uint255 key for mapping optimization

    // Staking Data
    struct StakingInfo {
        uint48 startTime; // 0 if not staked
        uint256 claimedRewards; // Amount of catalyst already claimed
    }
    mapping(uint255 => StakingInfo) private _stakedNFTs; // Use uint255 key for mapping optimization
    mapping(address => uint256[]) private _stakedTokenIdsByOwner; // Track staked NFTs per owner

    // Integrated Catalyst Token (Minimal ERC20-like)
    mapping(address => uint256) private _catalystBalances;
    mapping(address => mapping(address => uint256)) private _catalystAllowances;

    // Configuration Parameters (Owner Configurable)
    uint256 public morphCooldown = 7 days; // Time required between morph attempts
    uint16 public baseMorphSuccessRate = 7500; // Base success chance (75.00%), 0-10000
    uint256 public stakingYieldRatePerNFT = 1e18; // Catalyst per NFT per second (1 token per second)
    uint256 public decayRatePerSecond = 1; // Decay points per second (abstract unit)
    bool public decayEnabled = true;

    uint8 public minFusionNFTs = 2;
    uint8 public maxFusionNFTs = 5;
    uint16 public baseFusionSuccessRate = 5000; // Base success chance (50.00%), 0-10000
    uint8 public fusionOutputStage = 1; // Stage of the new NFT upon successful fusion

    string public tokenURISuffix = ""; // Base URI suffix for metadata

    // Stage Configuration (Attribute bounds)
    struct StageConfig {
        uint16 minAttributeValue;
        uint16 maxAttributeValue;
    }
    // Mapping from stage number to config
    mapping(uint8 => StageConfig) public stageConfigs;

    // --- Events ---

    event NFTMinted(address indexed owner, uint256 indexed tokenId, uint8 initialStage);
    event NFTMorphed(uint256 indexed tokenId, uint8 fromStage, uint8 toStage, NFTAttributes newAttributes);
    event MorphFailed(uint256 indexed tokenId, uint8 currentStage);
    event CatalystMinted(address indexed recipient, uint256 amount);
    event CatalystBurned(address indexed burner, uint256 amount);
    event NFTStaked(uint256 indexed tokenId, address indexed owner);
    event NFTUnstaked(uint256 indexed tokenId, address indexed owner);
    event StakingRewardClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event NFTFused(address indexed owner, uint256[] indexed burnedTokenIds, uint256 indexed newTokenId, bool success);
    event NFTDecayed(uint256 indexed tokenId, uint8 fromStage, uint8 toStage, NFTAttributes newAttributes);
    event ParameterChanged(string name, uint256 oldValue, uint256 newValue); // Generic event for admin changes

    // --- Constructor ---

    constructor() ERC721("MetaMorph NFT", "MMNFT") Ownable(msg.sender) {
        // Set initial stage configurations (example)
        stageConfigs[0] = StageConfig(1, 10);
        stageConfigs[1] = StageConfig(5, 15);
        stageConfigs[2] = StageConfig(10, 25);
        stageConfigs[3] = StageConfig(20, 40);
        stageConfigs[4] = StageConfig(35, 60); // Max Stage Example

        // Initial Catalyst supply (optional)
        // _mintCatalyst(msg.sender, 100000 * 1e18); // Example: Mint 100k to deployer
    }

    // --- ERC721 Standard Overrides ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Generates a dynamic tokenURI based on the NFT's current state.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721Metadata__URINotFound(tokenId);
        }

        NFTDetails memory details = _nftDetails[uint255(tokenId)];

        // Construct JSON metadata
        string memory json = string(abi.encodePacked(
            '{"name": "MetaMorph #', toString(tokenId), '",',
            '"description": "An evolving digital entity.",',
            '"image": "ipfs://YOUR_BASE_IMAGE_CID/', toString(details.stage), '.png",', // Placeholder image based on stage
            '"attributes": [',
                '{"trait_type": "Stage", "value": ', toString(details.stage), '},',
                '{"trait_type": "Strength", "value": ', toString(details.attributes.strength), '},',
                '{"trait_type": "Dexterity", "value": ', toString(details.attributes.dexterity), '},',
                '{"trait_type": "Constitution", "value": ', toString(details.attributes.constitution), '},',
                '{"trait_type": "Intelligence", "value": ', toString(details.attributes.intelligence), '},',
                '{"trait_type": "Wisdom", "value": ', toString(details.attributes.wisdom), '},',
                '{"trait_type": "Charisma", "value": ', toString(details.attributes.charisma), '}',
            ']}'
        ));

        // Encode JSON to Base64 and prefix with data URI schema
        string memory base64Json = Base64.encode(bytes(json));
        return string(abi.encodePacked("data:application/json;base64,", base64Json, tokenURISuffix));
    }

    // --- NFT Core Actions & Queries ---

    /**
     * @dev Mints a new NFT at stage 0.
     * @param to The address to mint the NFT to.
     */
    function mintInitialNFT(address to) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // Generate initial attributes within Stage 0 bounds
        StageConfig memory initialConfig = stageConfigs[0];
        NFTAttributes memory initialAttributes = _generateRandomAttributes(initialConfig.minAttributeValue, initialConfig.maxAttributeValue, newItemId);

        _nftDetails[uint255(newItemId)] = NFTDetails({
            stage: 0,
            attributes: initialAttributes,
            lastMorphTime: uint48(block.timestamp),
            lastDecayTime: uint48(block.timestamp)
        });

        _safeMint(to, newItemId);

        emit NFTMinted(to, newItemId, 0);
    }

    /**
     * @dev Attempts to morph an NFT to the next stage.
     * Requires cooldown met and Catalyst token payment.
     * Outcome (success/failure) is probabilistic and influenced by attributes.
     * @param tokenId The ID of the NFT to morph.
     */
    function morph(uint256 tokenId) public {
        address currentOwner = ownerOf(tokenId);
        require(currentOwner == msg.sender, "Morph: Must own the NFT");
        require(!isNFTStaked(tokenId), "Morph: Cannot morph staked NFT");

        NFTDetails storage details = _nftDetails[uint255(tokenId)];
        uint8 currentStage = details.stage;
        uint8 nextStage = currentStage + 1;

        StageConfig memory nextStageConfig = stageConfigs[nextStage];
        require(nextStageConfig.maxAttributeValue > 0, "Morph: No config for next stage"); // Check if next stage is defined
        require(details.lastMorphTime + morphCooldown <= block.timestamp, "Morph: Cooldown not met");
        require(_catalystBalances[msg.sender] >= _getMorphCost(currentStage), "Morph: Insufficient Catalyst");

        // Burn Catalyst cost
        _burnCatalyst(msg.sender, _getMorphCost(currentStage));

        // Calculate success rate (can be influenced by attributes)
        uint16 calculatedSuccessRate = _calculateMorphSuccessRate(tokenId);
        uint256 randomness = uint256(blockhash(block.number - 1)); // Simple pseudo-randomness
        bool success = (randomness % 10000) < calculatedSuccessRate;

        details.lastMorphTime = uint48(block.timestamp); // Update last morph time regardless of success

        if (success) {
            details.stage = nextStage;
            // Generate new attributes within the bounds of the new stage
            details.attributes = _generateRandomAttributes(
                nextStageConfig.minAttributeValue,
                nextStageConfig.maxAttributeValue,
                tokenId + block.timestamp // Add timestamp for more entropy
            );
            emit NFTMorphed(tokenId, currentStage, nextStage, details.attributes);
        } else {
            // Optional: Penalty on failure (e.g., reduced attributes, longer cooldown)
            // For simplicity, just emit failure event here.
            emit MorphFailed(tokenId, currentStage);
        }
    }

    /**
     * @dev Attempts to fuse multiple NFTs into a new one.
     * Requires Catalyst payment and burns the input NFTs.
     * Success is probabilistic.
     * @param tokenIds The IDs of the NFTs to fuse. Must be owned by the caller.
     */
    function fuseNFTs(uint256[] calldata tokenIds) public {
        address currentOwner = msg.sender;
        require(tokenIds.length >= minFusionNFTs && tokenIds.length <= maxFusionNFTs, "Fuse: Invalid number of NFTs");

        // Check ownership and ensure none are staked
        uint256 totalAttributesSum = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == currentOwner, "Fuse: Must own all NFTs");
            require(!isNFTStaked(tokenIds[i]), "Fuse: Cannot fuse staked NFTs");
            NFTAttributes memory attrs = _nftDetails[uint255(tokenIds[i])].attributes;
            totalAttributesSum += attrs.strength + attrs.dexterity + attrs.constitution +
                                  attrs.intelligence + attrs.wisdom + attrs.charisma;
        }

        uint256 fuseCost = _getFusionCost(tokenIds.length);
        require(_catalystBalances[currentOwner] >= fuseCost, "Fuse: Insufficient Catalyst");

        // Burn Catalyst cost
        _burnCatalyst(currentOwner, fuseCost);

        // Calculate success rate (can be influenced by number of NFTs, total attributes, etc.)
        uint16 calculatedSuccessRate = _calculateFusionSuccessRate(tokenIds.length, totalAttributesSum);
        uint256 randomness = uint256(blockhash(block.number - 1)); // Simple pseudo-randomness
        bool success = (randomness % 10000) < calculatedSuccessRate;

        // Burn input NFTs regardless of fusion success
        for (uint i = 0; i < tokenIds.length; i++) {
             _burn(tokenIds[i]);
        }

        uint256 newTokenId = 0; // Initialize to 0

        if (success) {
            _tokenIdCounter.increment();
            newTokenId = _tokenIdCounter.current();

            // Generate attributes for the new NFT
            StageConfig memory outputConfig = stageConfigs[fusionOutputStage];
             NFTAttributes memory newAttributes = _generateRandomAttributes(
                outputConfig.minAttributeValue,
                outputConfig.maxAttributeValue,
                block.timestamp + totalAttributesSum // Use combination for entropy
            );

            _nftDetails[uint255(newTokenId)] = NFTDetails({
                stage: fusionOutputStage,
                attributes: newAttributes,
                lastMorphTime: uint48(block.timestamp),
                lastDecayTime: uint48(block.timestamp)
            });

            _safeMint(currentOwner, newTokenId);
        }

        emit NFTFused(currentOwner, tokenIds, newTokenId, success);
    }

     /**
     * @dev Applies decay to an NFT based on time since last decay/interaction.
     * Can be called by anyone to update the NFT's state (gas costs considered).
     * @param tokenId The ID of the NFT to potentially decay.
     */
    function applyDecay(uint256 tokenId) public {
        if (!decayEnabled) return;
        require(_exists(tokenId), "Decay: NFT does not exist");
        require(!isNFTStaked(tokenId), "Decay: Staked NFT cannot decay"); // Staking prevents decay

        NFTDetails storage details = _nftDetails[uint255(tokenId)];
        uint48 lastDecay = details.lastDecayTime;
        uint48 currentTime = uint48(block.timestamp);

        if (currentTime <= lastDecay) return; // No time has passed

        uint256 timeElapsed = currentTime - lastDecay;
        uint256 potentialDecayPoints = timeElapsed * decayRatePerSecond;

        if (potentialDecayPoints == 0) return;

        // Calculate actual decay based on stage and attributes (example logic)
        // Higher stage/attributes might accrue decay points faster, or decay resistance could be based on stats.
        // For simplicity, let's just use the elapsed time and decay rate directly.
        uint256 decayAmount = potentialDecayPoints / (1 hours); // Example: 1 decay point per hour

        if (decayAmount > 0) {
            uint8 currentStage = details.stage;
            NFTAttributes memory currentAttributes = details.attributes; // Store before potentially changing

            // Apply decay effects (example: reduce a random attribute, potentially reduce stage)
            uint256 randomness = uint256(blockhash(block.number - 1));
            uint8 attributeToDecay = uint8(randomness % 6); // Choose random attribute (0-5)

            uint16 decayAttrValue = uint16(decayAmount.min(uint256(details.attributes.strength))); // Example: decay affects strength
            if (attributeToDecay == 0) details.attributes.strength = details.attributes.strength > decayAttrValue ? details.attributes.strength - decayAttrValue : 0;
            else if (attributeToDecay == 1) details.attributes.dexterity = details.attributes.dexterity > decayAttrValue ? details.attributes.dexterity - decayAttrValue : 0;
            else if (attributeToDecay == 2) details.attributes.constitution = details.attributes.constitution > decayAttrValue ? details.attributes.constitution - decayAttrValue : 0;
            else if (attributeToDecay == 3) details.attributes.intelligence = details.attributes.intelligence > decayAttrValue ? details.attributes.intelligence - decayAttrValue : 0;
            else if (attributeToDecay == 4) details.attributes.wisdom = details.attributes.wisdom > decayAttrValue ? details.attributes.wisdom - decayAttrValue : 0;
            else details.attributes.charisma = details.attributes.charisma > decayAttrValue ? details.attributes.charisma - decayAttrValue : 0;

            // Optional: Reduce stage if attributes fall below a threshold or enough decay accrues
            // This logic can be complex. For this example, let's keep stage decay simple or skip it.
             if (details.stage > 0 && details.attributes.strength + details.attributes.dexterity + details.attributes.constitution +
                 details.attributes.intelligence + details.attributes.wisdom + details.attributes.charisma < details.stage * 10) { // Example threshold
                  details.stage--;
             }


            details.lastDecayTime = currentTime; // Update last decay time

            emit NFTDecayed(tokenId, currentStage, details.stage, details.attributes);
        }
    }

    /**
     * @dev Returns comprehensive details for a given NFT.
     * @param tokenId The ID of the NFT.
     * @return NFTDetails struct.
     */
    function getNFTDetails(uint256 tokenId) public view returns (NFTDetails memory) {
        require(_exists(tokenId), "NFT does not exist");
        return _nftDetails[uint255(tokenId)];
    }

     /**
     * @dev Calculates a basic rarity score for an NFT.
     * Example: Rarity is proportional to stage and total attribute points.
     * @param tokenId The ID of the NFT.
     * @return The rarity score.
     */
    function getRarityScore(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "NFT does not exist");
         NFTDetails memory details = _nftDetails[uint255(tokenId)];
         uint256 totalAttributes = uint256(details.attributes.strength) + details.attributes.dexterity + details.attributes.constitution +
                                   details.attributes.intelligence + details.attributes.wisdom + details.attributes.charisma;
         return uint256(details.stage) * 1000 + totalAttributes; // Simple arbitrary score calculation
    }

     /**
     * @dev Checks if an NFT has met the cooldown requirement for morphing.
     * @param tokenId The ID of the NFT.
     * @return True if morphing is ready, false otherwise.
     */
    function isMorphReady(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "NFT does not exist");
        return _nftDetails[uint255(tokenId)].lastMorphTime + morphCooldown <= block.timestamp;
    }

    /**
     * @dev Checks if an NFT is currently staked.
     * @param tokenId The ID of the NFT.
     * @return True if staked, false otherwise.
     */
    function isNFTStaked(uint256 tokenId) public view returns (bool) {
        return _stakedNFTs[uint255(tokenId)].startTime > 0;
    }

    // --- Staking Functions ---

    /**
     * @dev Stakes an NFT.
     * @param tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 tokenId) public {
        address currentOwner = ownerOf(tokenId);
        require(currentOwner == msg.sender, "Stake: Must own the NFT");
        require(!isNFTStaked(tokenId), "Stake: NFT already staked");
        // Optional: require NFT is not currently locked in morph/fusion process (handled by owner check)

        // Transfer NFT to contract address for staking (custodial staking)
        _transfer(currentOwner, address(this), tokenId);

        _stakedNFTs[uint255(tokenId)] = StakingInfo({
            startTime: uint48(block.timestamp),
            claimedRewards: 0
        });

        _stakedTokenIdsByOwner[currentOwner].push(tokenId); // Track staked IDs per owner

        emit NFTStaked(tokenId, currentOwner);
    }

    /**
     * @dev Unstakes an NFT.
     * Claims pending rewards upon unstaking.
     * @param tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 tokenId) public {
        require(ownerOf(tokenId) == address(this), "Unstake: NFT not staked or not owned by contract"); // Check ownership by contract
        StakingInfo storage staking = _stakedNFTs[uint255(tokenId)];
        require(staking.startTime > 0, "Unstake: NFT not staked");

        address originalOwner = msg.sender; // Assume caller is the original staker

        // Claim pending rewards before unstaking
        uint256 pendingRewards = calculatePendingStakingRewards(tokenId);
         if (pendingRewards > 0) {
             _mintCatalyst(originalOwner, pendingRewards);
             staking.claimedRewards += pendingRewards;
             emit StakingRewardClaimed(tokenId, originalOwner, pendingRewards);
         }

        // Transfer NFT back to the original owner
        _transfer(address(this), originalOwner, tokenId);

        // Clean up staking info
        staking.startTime = 0;
        // Note: claimedRewards is reset implicitly when startTime is 0 for a tokenID not currently staked

        // Remove from staked token IDs list (simple but potentially inefficient if list is large)
        uint256[] storage stakedIds = _stakedTokenIdsByOwner[originalOwner];
        for (uint i = 0; i < stakedIds.length; i++) {
            if (stakedIds[i] == tokenId) {
                stakedIds[i] = stakedIds[stakedIds.length - 1];
                stakedIds.pop();
                break;
            }
        }


        emit NFTUnstaked(tokenId, originalOwner);
    }

    /**
     * @dev Claims pending Catalyst rewards for a staked NFT.
     * @param tokenId The ID of the staked NFT.
     */
    function claimStakingRewards(uint256 tokenId) public {
        require(ownerOf(tokenId) == address(this), "Claim: NFT not staked or not owned by contract");
        StakingInfo storage staking = _stakedNFTs[uint255(tokenId)];
        require(staking.startTime > 0, "Claim: NFT not staked");

        address originalOwner = msg.sender; // Assume caller is the original staker

        uint256 pendingRewards = calculatePendingStakingRewards(tokenId);
        if (pendingRewards > 0) {
            _mintCatalyst(originalOwner, pendingRewards); // Mint rewards
            staking.claimedRewards += pendingRewards;
            // Update start time to reflect rewards up to this point (or just track last claim time)
            // Let's recalculate based on original startTime each time, it's simpler.
             emit StakingRewardClaimed(tokenId, originalOwner, pendingRewards);
        }
    }

    /**
     * @dev Calculates the pending Catalyst rewards for a staked NFT.
     * @param tokenId The ID of the staked NFT.
     * @return The amount of Catalyst rewards accrued since the last claim or stake time.
     */
    function calculatePendingStakingRewards(uint256 tokenId) public view returns (uint256) {
        StakingInfo memory staking = _stakedNFTs[uint255(tokenId)];
        if (staking.startTime == 0) {
            return 0; // Not staked
        }

        // Total theoretical rewards since staking started
        uint256 totalEarned = (block.timestamp - staking.startTime) * stakingYieldRatePerNFT;

        // Rewards already claimed
        uint256 alreadyClaimed = staking.claimedRewards;

        // Pending rewards are total earned minus claimed
        return totalEarned > alreadyClaimed ? totalEarned - alreadyClaimed : 0;
    }

     /**
     * @dev Gets the timestamp when an NFT was staked.
     * @param tokenId The ID of the NFT.
     * @return The staking start time (0 if not staked).
     */
    function getNFTStakingStartTime(uint256 tokenId) public view returns (uint48) {
        return _stakedNFTs[uint255(tokenId)].startTime;
    }

    // --- Catalyst Token (Integrated) Functions ---

    /**
     * @dev Returns the balance of the integrated Catalyst token for an address.
     * @param owner The address to query.
     * @return The Catalyst token balance.
     */
    function getCatalystBalance(address owner) public view returns (uint256) {
        return _catalystBalances[owner];
    }

    /**
     * @dev Basic Catalyst token transfer function.
     * @param recipient The address to transfer to.
     * @param amount The amount to transfer.
     * @return True on success.
     */
    function transferCatalyst(address recipient, uint256 amount) public returns (bool) {
        _transferCatalyst(msg.sender, recipient, amount);
        return true;
    }

     /**
     * @dev Basic Catalyst token approve function.
     * @param spender The address allowed to spend.
     * @param amount The amount allowed.
     * @return True on success.
     */
    function approveCatalyst(address spender, uint256 amount) public returns (bool) {
         _catalystAllowances[msg.sender][spender] = amount;
         // Optional: emit Approval event (like ERC20)
         return true;
    }

     /**
     * @dev Basic Catalyst token transferFrom function using allowance.
     * @param sender The address sending the tokens.
     * @param recipient The address receiving the tokens.
     * @param amount The amount to transfer.
     * @return True on success.
     */
    function transferFromCatalyst(address sender, address recipient, uint256 amount) public returns (bool) {
         uint256 currentAllowance = _catalystAllowances[sender][msg.sender];
         require(currentAllowance >= amount, "Catalyst: transfer amount exceeds allowance");
         _transferCatalyst(sender, recipient, amount);
         _catalystAllowances[sender][msg.sender] = currentAllowance - amount;
         return true;
    }


    /**
     * @dev Mints Catalyst tokens to a recipient. Admin only.
     * Used for initial distribution or funding mechanisms.
     * @param recipient The address to mint to.
     * @param amount The amount to mint.
     */
    function mintCatalystAdmin(address recipient, uint256 amount) public onlyOwner {
        _mintCatalyst(recipient, amount);
        emit CatalystMinted(recipient, amount);
    }

     /**
     * @dev Burns Catalyst tokens from the caller's balance.
     * Public for potential external utility (e.g., crafting).
     * Also used internally by morph/fusion.
     * @param amount The amount to burn.
     */
    function burnCatalyst(uint256 amount) public {
        _burnCatalyst(msg.sender, amount);
        emit CatalystBurned(msg.sender, amount);
    }

    // --- Admin/Configuration Functions ---

    /**
     * @dev Sets the cooldown period required between morph attempts (in seconds). Owner only.
     * @param cooldown The new cooldown period.
     */
    function setMorphCooldown(uint256 cooldown) public onlyOwner {
        emit ParameterChanged("morphCooldown", morphCooldown, cooldown);
        morphCooldown = cooldown;
    }

    /**
     * @dev Sets the base success rate for morphing (0-10000). Owner only.
     * @param rate The new base success rate.
     */
    function setBaseMorphSuccessRate(uint16 rate) public onlyOwner {
        require(rate <= 10000, "Rate must be <= 10000");
        emit ParameterChanged("baseMorphSuccessRate", baseMorphSuccessRate, rate); // Note: Emitting uint16 in uint256 field
        baseMorphSuccessRate = rate;
    }

     /**
     * @dev Sets the min/max attribute values for a specific stage. Owner only.
     * @param stage The stage number.
     * @param minAttr The minimum attribute value.
     * @param maxAttr The maximum attribute value.
     */
    function setStageConfig(uint8 stage, uint16 minAttr, uint16 maxAttr) public onlyOwner {
        require(minAttr <= maxAttr, "Min must be <= Max");
        // No simple parameter change event here, as it's a struct update
        stageConfigs[stage] = StageConfig(minAttr, maxAttr);
    }

     /**
     * @dev Sets the Catalyst yield rate per staked NFT per second. Owner only.
     * @param ratePerSecond The new yield rate.
     */
    function setStakingYieldRatePerNFT(uint256 ratePerSecond) public onlyOwner {
        emit ParameterChanged("stakingYieldRatePerNFT", stakingYieldRatePerNFT, ratePerSecond);
        stakingYieldRatePerNFT = ratePerSecond;
    }

    /**
     * @dev Sets the decay rate per second (abstract points). Owner only.
     * @param ratePerSecond The new decay rate.
     */
    function setDecayRate(uint256 ratePerSecond) public onlyOwner {
        emit ParameterChanged("decayRatePerSecond", decayRatePerSecond, ratePerSecond);
        decayRatePerSecond = ratePerSecond;
    }

     /**
     * @dev Enables or disables the decay mechanic. Owner only.
     * @param enabled True to enable, false to disable.
     */
    function toggleDecay(bool enabled) public onlyOwner {
         // No ParameterChanged event for boolean with current struct
        decayEnabled = enabled;
    }

     /**
     * @dev Sets the minimum number of NFTs required for fusion. Owner only.
     * @param min The new minimum.
     */
    function setMinFusionNFTs(uint8 min) public onlyOwner {
         require(min >= 2, "Min fusion NFTs must be at least 2");
         require(min <= maxFusionNFTs, "Min must be <= max");
         // No ParameterChanged event for uint8 with current struct
         minFusionNFTs = min;
     }

     /**
     * @dev Sets the maximum number of NFTs allowed for fusion. Owner only.
     * @param max The new maximum.
     */
     function setMaxFusionNFTs(uint8 max) public onlyOwner {
         require(max >= minFusionNFTs, "Max must be >= min");
         // No ParameterChanged event for uint8 with current struct
         maxFusionNFTs = max;
     }

     /**
     * @dev Sets the base success rate for fusion (0-10000). Owner only.
     * @param rate The new base success rate.
     */
     function setBaseFusionSuccessRate(uint16 rate) public onlyOwner {
         require(rate <= 10000, "Rate must be <= 10000");
         // No ParameterChanged event for uint16 with current struct
         baseFusionSuccessRate = rate;
     }

      /**
     * @dev Sets the stage of the output NFT upon successful fusion. Owner only.
     * @param stage The new output stage.
     */
     function setFusionOutputStage(uint8 stage) public onlyOwner {
         require(stageConfigs[stage].maxAttributeValue > 0, "Fusion output stage must have config");
          // No ParameterChanged event for uint8 with current struct
         fusionOutputStage = stage;
     }

     /**
     * @dev Sets the suffix appended to the base64 data URI for tokenURI. Owner only.
     * Useful for adding a base URL or identifier.
     * @param suffix The suffix string.
     */
    function setTokenURISuffix(string memory suffix) public onlyOwner {
         tokenURISuffix = suffix;
     }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to calculate the Catalyst cost for morphing a given stage.
     * Example: Cost increases with stage.
     */
    function _getMorphCost(uint8 stage) internal pure returns (uint256) {
        // Example: Stage 0 -> 1 costs 100, Stage 1 -> 2 costs 200, etc.
        return (stage + 1) * 100 * 1e18; // Cost in Catalyst units (with 18 decimals)
    }

     /**
     * @dev Internal function to calculate the Catalyst cost for fusion based on number of inputs.
     * Example: Cost increases with number of NFTs fused.
     */
    function _getFusionCost(uint256 numInputs) internal pure returns (uint256) {
        // Example: 2 NFTs cost 500, 3 cost 700, etc.
        return (numInputs * 200 + 100) * 1e18; // Cost in Catalyst units (with 18 decimals)
    }

    /**
     * @dev Internal function to calculate the morph success rate for an NFT.
     * Can be influenced by base rate and NFT attributes.
     * @param tokenId The ID of the NFT.
     * @return Success rate (0-10000).
     */
    function _calculateMorphSuccessRate(uint256 tokenId) internal view returns (uint16) {
         NFTDetails memory details = _nftDetails[uint255(tokenId)];
         // Example: Add bonus rate based on total attributes
         uint256 totalAttributes = uint256(details.attributes.strength) + details.attributes.dexterity + details.attributes.constitution +
                                   details.attributes.intelligence + details.attributes.wisdom + details.attributes.charisma;
         uint16 attributeBonus = uint16(totalAttributes / 10); // 1 bonus point per 10 total attributes
         uint16 rate = baseMorphSuccessRate + attributeBonus;
         return rate > 10000 ? 10000 : rate; // Cap at 100%
    }

    /**
     * @dev Internal function to calculate the fusion success rate.
     * Can be influenced by base rate, number of inputs, and total attributes.
     * @param numInputs The number of NFTs being fused.
     * @param totalAttributesSum The sum of attributes from all input NFTs.
     * @return Success rate (0-10000).
     */
    function _calculateFusionSuccessRate(uint256 numInputs, uint256 totalAttributesSum) internal view returns (uint16) {
        // Example: Base rate + bonus from attributes - penalty from number of inputs
        uint16 attributeBonus = uint16(totalAttributesSum / 20); // 1 bonus point per 20 total attributes
        uint16 inputPenalty = uint16((numInputs - minFusionNFTs) * 50); // Penalty increases with more inputs

        uint16 rate = baseFusionSuccessRate + attributeBonus;
        if (rate > inputPenalty) {
            rate -= inputPenalty;
        } else {
            rate = 0;
        }
         return rate > 10000 ? 10000 : rate; // Cap at 100%
    }


    /**
     * @dev Internal function to generate random attributes within a given range.
     * WARNING: Blockhash is predictable. Use Chainlink VRF for production randomness.
     */
    function _generateRandomAttributes(uint16 min, uint16 max, uint256 seed) internal view returns (NFTAttributes memory) {
         uint256 randomness = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tx.origin, seed)));
         uint16 range = max - min + 1;

         return NFTAttributes({
             strength: min + uint16((randomness >> 16*0) % range),
             dexterity: min + uint16((randomness >> 16*1) % range),
             constitution: min + uint16((randomness >> 16*2) % range),
             intelligence: min + uint16((randomness >> 16*3) % range),
             wisdom: min + uint16((randomness >> 16*4) % range),
             charisma: min + uint16((randomness >> 16*5) % range)
         });
    }

    /**
     * @dev Internal function to mint Catalyst tokens.
     */
    function _mintCatalyst(address recipient, uint256 amount) internal {
        _catalystSupply.increment(amount);
        _catalystBalances[recipient] += amount;
        // Optional: Emit Transfer(address(0), recipient, amount) event for ERC20 compatibility
    }

    /**
     * @dev Internal function to burn Catalyst tokens.
     */
    function _burnCatalyst(address owner, uint256 amount) internal {
        require(_catalystBalances[owner] >= amount, "Catalyst: burn amount exceeds balance");
        _catalystBalances[owner] -= amount;
        _catalystSupply.decrement(amount);
         // Optional: Emit Transfer(owner, address(0), amount) event for ERC20 compatibility
    }

     /**
     * @dev Internal function to transfer Catalyst tokens.
     */
    function _transferCatalyst(address sender, address recipient, uint256 amount) internal {
         require(sender != address(0), "Catalyst: transfer from the zero address");
         require(recipient != address(0), "Catalyst: transfer to the zero address");
         require(_catalystBalances[sender] >= amount, "Catalyst: transfer amount exceeds balance");

         _catalystBalances[sender] -= amount;
         _catalystBalances[recipient] += amount;
         // Optional: Emit Transfer(sender, recipient, amount) event for ERC20 compatibility
    }


    // Helper function from OpenZeppelin's Strings library (simplified)
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
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```

---

**Explanation of Advanced/Unique Concepts:**

1.  **Dynamic State (On-Chain Attributes):** Unlike many NFTs where metadata is static and off-chain (e.g., IPFS), core attributes (`NFTAttributes`) and `stage` are stored directly within the smart contract's storage. This allows contract logic to directly interact with and change these properties.
2.  **Morphing Mechanic:** A complex state transition. It's not a simple "level up" but a process requiring a specific resource (`Catalyst`), waiting a `cooldown` period, and involves a `baseMorphSuccessRate` potentially modified by the NFT's attributes, introducing a probabilistic element on success and attribute outcome.
3.  **Integrated Catalyst Token:** A minimal ERC20-like token (`Catalyst`) is managed *within* the same contract. This avoids needing a separate deployment for a simple resource and simplifies interactions (no external contract calls needed for balance checks/transfers). It serves as the fuel for the ecosystem actions (morphing, fusion).
4.  **Fusion Mechanic:** A resource-intensive operation (`fuseNFTs`) that burns multiple existing NFTs and attempts to create a new one. This adds a deflationary mechanism and a way to consolidate weaker NFTs or chase specific outcomes. It's also probabilistic (`baseFusionSuccessRate`).
5.  **Staking with Integrated Rewards:** NFTs can be locked in the contract (`stakeNFT`), making them unusable for other actions, but earning the integrated `Catalyst` token over time (`stakingYieldRatePerNFT`). Rewards are calculated based on time staked and can be claimed (`claimStakingRewards`) or are paid out upon unstaking (`unstakeNFT`).
6.  **Decay Mechanic:** Introduces a concept of maintenance or active participation. If `decayEnabled` is true and an NFT hasn't been interacted with (specifically, its `lastDecayTime` isn't updated, or a separate trigger is implemented), its attributes or even stage can degrade (`applyDecay`). This encourages engagement or provides a risk for inactive holders.
7.  **Dynamic Metadata (`tokenURI`):** The `tokenURI` function is overridden to generate a data URI containing Base64 encoded JSON. This JSON is constructed *on-the-fly* based on the NFT's current `stage` and `attributes`, ensuring that the NFT's metadata in marketplaces or explorers always reflects its latest state without needing external servers or oracles for simple attribute updates. (Note: image would still typically point to an external resource, but could potentially also be dynamic via rendering services).
8.  **Probabilistic Outcomes:** Both `morph` and `fuseNFTs` use simple pseudo-randomness based on `blockhash` to determine success and new attributes. **Important Caveat:** `blockhash` is not truly random and can be manipulated by miners. For production-level randomness, Chainlink VRF or similar solutions are recommended. The code includes a note about this.
9.  **Gas Considerations:** Structs like `NFTDetails` use gas-efficient types (`uint48` for timestamps). The `applyDecay` function is designed to be callable by anyone, shifting the gas cost of updating inactive NFTs from the protocol to the user who benefits from the update (e.g., by seeing correct metadata or enabling a subsequent action).

This contract provides a rich ecosystem of interactions centered around the NFT's lifecycle and state changes, going beyond simple ownership and transfer.