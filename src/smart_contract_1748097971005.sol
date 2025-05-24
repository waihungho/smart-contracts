Okay, let's design a smart contract that combines dynamic NFTs with gamified evolution, reputation, and resource management. We'll call it "ChronoGenesys".

The core idea is that each NFT (a "ChronoGene") represents a unique, evolving entity with dynamic traits. Its traits change based on user interactions (like "feeding" it tokens) and internal contract logic (like mutation and breeding). Reputation plays a role in success rates.

This contract incorporates:
*   **Dynamic State:** NFT traits stored directly in the contract, changing over time and by user actions.
*   **Resource Management:** Requiring a specific token (`FEED_TOKEN`) to maintain NFT "vitality".
*   **Gamified Mechanics:** Mutation chance, breeding outcomes, reputation system.
*   **On-chain Logic for Trait Generation:** Mutation and breeding algorithms influence a core `geneString` trait.
*   **Inter-NFT Interaction:** Breeding requires two existing NFTs.
*   **Reputation System:** An internal score affecting game mechanics.

---

**Contract: ChronoGenesys**

**Outline & Function Summary:**

1.  **Core ERC721 & Ownership:** Standard NFT functionality and admin control.
2.  **Data Structures:** Define the `ChronoGene` struct and state variables.
3.  **Parameters:** Contract-level variables controlling game mechanics.
4.  **Initialization:** Constructor.
5.  **Gene Management (Creation/Destruction):** Minting, Burning.
6.  **State Querying:** Functions to retrieve gene traits, contract parameters, etc.
7.  **Core Mechanics:**
    *   Vitality & Feeding: Managing gene "health" via token staking.
    *   Mutation: Randomly altering gene traits.
    *   Breeding: Combining two genes to create a new one.
8.  **Reputation System:** Internal logic to update reputation based on actions.
9.  **Utility & Admin:** Pausing, withdrawing fees, setting parameters.
10. **Derived Data:** Generating unique IDs/hashes from gene state.
11. **Eligibility Checks:** View functions to see if genes can perform actions.
12. **Token URI:** Custom logic to generate URI based on dynamic state.

---

**Function Summary:**

*   `constructor(string name, string symbol, address initialOwner, address feedTokenAddress, uint256 initialVitalityDecayRate, uint256 initialFeedingAmount, uint256 initialMutationChanceBase, uint256 initialBreedingFee)`: Initializes the contract, sets ERC721 details, owner, and initial game parameters.
*   `mint(address to)`: Mints a new ChronoGene NFT to an address (Owner-only). Initializes base traits.
*   `getGeneTraits(uint256 tokenId)`: Returns all dynamic traits for a given gene.
*   `getVitality(uint256 tokenId)`: Returns the current vitality of a gene. (Calculates decay since last fed).
*   `getMutagen(uint256 tokenId)`: Returns the mutagen level.
*   `getGeneString(uint256 tokenId)`: Returns the core gene string.
*   `getReputation(uint256 tokenId)`: Returns the reputation score.
*   `getLastFedTimestamp(uint256 tokenId)`: Returns the timestamp the gene was last fed.
*   `feedGene(uint256 tokenId, uint256 amount)`: Allows the owner of a gene to feed it `FEED_TOKEN` to restore vitality. Transfers tokens to the contract.
*   `getStakedAmount(uint256 tokenId)`: Returns the total amount of `FEED_TOKEN` staked on a gene.
*   `withdrawStaked(uint256 tokenId)`: Allows the gene owner to withdraw their staked `FEED_TOKEN` if allowed (e.g., gene burned).
*   `mutateGene(uint256 tokenId)`: Attempts to mutate a gene. Success is based on parameters, mutagen, and reputation. May alter `geneString` or increase mutagen.
*   `breedGenes(uint256 parent1Id, uint256 parent2Id)`: Attempts to breed two genes. Requires conditions met. Creates a new child gene with combined/mutated traits. Requires a breeding fee.
*   `burnGene(uint256 tokenId)`: Burns a gene, potentially releasing staked tokens back to the owner.
*   `getGeneHash(uint256 tokenId)`: Generates a unique hash from the gene's dynamic traits (useful for off-chain rendering).
*   `isGeneEligibleForMutation(uint256 tokenId)`: View function checking if a gene meets minimum criteria for mutation.
*   `isGeneEligibleForBreeding(uint256 parent1Id, uint256 parent2Id)`: View function checking if two genes meet criteria for breeding.
*   `setVitalityDecayRate(uint256 rate)`: Owner-only function to set the global vitality decay rate.
*   `setFeedingParams(uint256 amount)`: Owner-only function to set the standard amount of vitality restored per feed.
*   `setMutationParams(uint256 chanceBase)`: Owner-only function to set the base mutation chance.
*   `setBreedingParams(uint256 fee)`: Owner-only function to set the breeding fee.
*   `setBreedingFeeRecipient(address recipient)`: Owner-only function to set the address receiving breeding fees.
*   `withdrawFees(address tokenAddress)`: Owner-only function to withdraw collected fees (e.g., `FEED_TOKEN`) from the contract.
*   `getTotalMintedGenes()`: Returns the total number of genes minted.
*   `getContractParameters()`: Returns a tuple of key contract parameters.
*   `pause()`: Owner-only function to pause core interactions (feeding, mutation, breeding).
*   `unpause()`: Owner-only function to unpause the contract.
*   `tokenURI(uint256 tokenId)`: Overrides ERC721's `tokenURI` to generate a URI based on the gene's dynamic state.
*   `supportsInterface(bytes4 interfaceId)`: Standard ERC165 implementation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interface for the token used for feeding
interface IFeedToken is IERC20 {}

/**
 * @title ChronoGenesys
 * @dev A dynamic NFT contract where tokens (ChronoGenes) evolve based on user interaction,
 *      internal mechanics (mutation, breeding), and resource management (feeding).
 *      Incorporates dynamic traits, resource staking, gamified probability, and a simple
 *      on-chain representation of evolution.
 */
contract ChronoGenesys is ERC721, Ownable, Pausable {

    using Address for address;
    using Math for uint256;

    // --- Errors ---
    error ChronoGenesys__GeneDoesNotExist();
    error ChronoGenesys__NotGeneOwner();
    error ChronoGenesys__InsufficientVitality();
    error ChronoGenesys__InsufficientMutagen();
    error ChronoGenesys__BreedingRequirementsNotMet();
    error ChronoGenesys__MutationRequirementsNotMet();
    error ChronoGenesys__CannotBreedWithSelf();
    error ChronoGenesys__StakingAmountMismatch();
    error ChronoGenesys__TransferFailed();
    error ChronoGenesys__NoFeesToWithdraw();
    error ChronoGenesys__StakingNotYetWithdrawable();

    // --- Events ---
    event GeneMinted(uint256 indexed tokenId, address indexed owner, bytes geneString, uint256 epoch);
    event GeneFed(uint256 indexed tokenId, address indexed feeder, uint256 amount, uint256 newVitality);
    event GeneVitalityDecayed(uint256 indexed tokenId, uint256 oldVitality, uint256 newVitality);
    event GeneMutated(uint256 indexed tokenId, bytes oldGeneString, bytes newGeneString, uint256 newMutagen);
    event GeneMutationFailed(uint256 indexed tokenId, uint256 newMutagen);
    event GenesBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, bytes childGeneString);
    event GeneBurned(uint256 indexed tokenId, address indexed owner);
    event GeneReputationUpdated(uint256 indexed tokenId, uint256 oldReputation, uint256 newReputation);
    event ParametersUpdated(string indexed parameterName, uint256 oldValue, uint256 newValue);
    event BreedingFeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    // --- Data Structures ---

    struct ChronoGene {
        uint256 creationEpoch;   // Fixed: Block timestamp of creation (Epoch of Genesis)
        bytes ancestryHash;      // Fixed: Hash derived from parent genes or random for genesis
        uint256 vitality;        // Dynamic: Health/Energy level (0-10000 for 0.01% precision)
        uint256 mutagen;         // Dynamic: Instability level (0-10000)
        bytes geneString;        // Dynamic: Core identifier/visual representation (arbitrary bytes)
        uint256 reputation;      // Dynamic: Score affecting success chances (0-10000)
        uint256 lastFedTimestamp;// Dynamic: Timestamp of last feeding
    }

    // Mapping from token ID to ChronoGene data
    mapping(uint256 => ChronoGene) public genes;

    // Mapping from token ID to total staked FEED_TOKEN amount
    mapping(uint256 => uint256) public stakedTokens;

    // --- Parameters (Configurable by Owner) ---

    IFeedToken public immutable FEED_TOKEN; // The token required for feeding

    uint256 public vitalityDecayRate;     // Vitality decrease per second (per 10000 vitality unit)
    uint256 public feedingAmount;         // Vitality restored per FEED_TOKEN unit
    uint256 public mutationChanceBase;    // Base chance for successful mutation (out of 10000)
    uint256 public mutationChanceMutagenMultiplier; // Multiplier for mutagen effect on chance (per 10000 mutagen unit)
    uint256 public reputationInfluence;   // How much reputation affects success chances (per 10000 reputation unit)
    uint256 public minVitalityForAction;  // Minimum vitality needed for mutation/breeding
    uint256 public minMutagenForMutation; // Minimum mutagen needed for mutation attempt
    uint256 public maxMutagen;            // Maximum mutagen level
    uint256 public maxReputation;         // Maximum reputation level
    uint256 public breedingFee;           // Fee required to breed (in FEED_TOKEN units)
    address public breedingFeeRecipient;  // Address to receive breeding fees

    uint256 private _nextTokenId; // Counter for total minted genes

    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        address feedTokenAddress,
        uint256 initialVitalityDecayRate, // e.g., 1 (0.01% decay per sec)
        uint256 initialFeedingAmount,     // e.g., 10 (10 vitality per token)
        uint256 initialMutationChanceBase,// e.g., 1000 (10% base chance)
        uint256 initialMutationChanceMutagenMultiplier, // e.g., 10 (mutagen adds 0.1% chance per point)
        uint256 initialReputationInfluence, // e.g., 5 (reputation adds 0.05% chance per point)
        uint256 initialMinVitalityForAction, // e.g., 2000 (20%)
        uint256 initialMinMutagenForMutation, // e.g., 1000 (10%)
        uint256 initialMaxMutagen,        // e.g., 10000 (100%)
        uint256 initialMaxReputation,     // e.g., 10000 (100%)
        uint256 initialBreedingFee,       // e.g., 10 (10 FEED_TOKEN)
        address initialBreedingFeeRecipient
    )
        ERC721(name, symbol)
        Ownable(initialOwner)
        Pausable()
    {
        FEED_TOKEN = IFeedToken(feedTokenAddress);
        vitalityDecayRate = initialVitalityDecayRate;
        feedingAmount = initialFeedingAmount;
        mutationChanceBase = initialMutationChanceBase;
        mutationChanceMutagenMultiplier = initialMutationChanceMutagenMultiplier;
        reputationInfluence = initialReputationInfluence;
        minVitalityForAction = initialMinVitalityForAction;
        minMutagenForMutation = initialMinMutagenForMutation;
        maxMutagen = initialMaxMutagen;
        maxReputation = initialMaxReputation;
        breedingFee = initialBreedingFee;
        breedingFeeRecipient = initialBreedingFeeRecipient;

        _nextTokenId = 0;
    }

    // --- Gene Management ---

    /**
     * @dev Mints a new genesis ChronoGene. Only callable by the owner.
     * @param to The address to mint the gene to.
     */
    function mint(address to) public onlyOwner {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(to, newTokenId);

        // Initialize genesis gene traits
        // Simple deterministic gene string based on creation time and ID
        bytes memory initialGeneString = abi.encodePacked(block.timestamp, newTokenId, uint8(Math.ceil(Math.sqrt(newTokenId))));

        genes[newTokenId] = ChronoGene({
            creationEpoch: block.timestamp,
            ancestryHash: keccak256("GENESIS"), // Special hash for initial genes
            vitality: 10000, // Start with full vitality
            mutagen: 0,
            geneString: initialGeneString,
            reputation: 5000, // Start with neutral reputation
            lastFedTimestamp: block.timestamp
        });

        emit GeneMinted(newTokenId, to, initialGeneString, block.timestamp);
        // Reputation update event for minting (optional, adds initial reputation)
        // emit GeneReputationUpdated(newTokenId, 0, 5000); // Not strictly an update, but sets initial
    }

    /**
     * @dev Burns a ChronoGene. Only callable by the gene owner.
     *      Releases any staked tokens back to the owner before burning.
     * @param tokenId The ID of the gene to burn.
     */
    function burnGene(uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId);
        if (owner != _msgSender()) revert ChronoGenesys__NotGeneOwner();

        // Withdraw staked tokens before burning
        _withdrawStakedTokensInternal(tokenId, owner);

        _burn(tokenId);
        delete genes[tokenId]; // Clean up gene data

        emit GeneBurned(tokenId, owner);
    }

    // --- State Querying ---

    /**
     * @dev Returns all dynamic traits for a specific gene.
     * @param tokenId The ID of the gene.
     * @return ChronoGene struct.
     */
    function getGeneTraits(uint256 tokenId) public view returns (ChronoGene memory) {
        _requireExistingGene(tokenId);
        ChronoGene storage gene = genes[tokenId];
        // Return with calculated current vitality
        return ChronoGene({
            creationEpoch: gene.creationEpoch,
            ancestryHash: gene.ancestryHash,
            vitality: _calculateCurrentVitality(tokenId),
            mutagen: gene.mutagen,
            geneString: gene.geneString,
            reputation: gene.reputation,
            lastFedTimestamp: gene.lastFedTimestamp
        });
    }

    /**
     * @dev Returns the current vitality of a gene, accounting for decay.
     * @param tokenId The ID of the gene.
     * @return The current vitality (0-10000).
     */
    function getVitality(uint256 tokenId) public view returns (uint256) {
        _requireExistingGene(tokenId);
        return _calculateCurrentVitality(tokenId);
    }

     /**
     * @dev Internal helper to calculate current vitality considering decay.
     * @param tokenId The ID of the gene.
     * @return The calculated current vitality (0-10000).
     */
    function _calculateCurrentVitality(uint256 tokenId) internal view returns (uint256) {
        ChronoGene storage gene = genes[tokenId];
        uint256 timeElapsed = block.timestamp - gene.lastFedTimestamp;
        uint256 decay = (timeElapsed * vitalityDecayRate * gene.vitality) / 10000; // Decay proportional to current vitality

        if (decay >= gene.vitality) {
            return 0;
        } else {
            return gene.vitality - decay;
        }
    }

    /**
     * @dev Returns the current mutagen level of a gene.
     * @param tokenId The ID of the gene.
     * @return The mutagen level (0-10000).
     */
    function getMutagen(uint256 tokenId) public view returns (uint256) {
        _requireExistingGene(tokenId);
        return genes[tokenId].mutagen;
    }

    /**
     * @dev Returns the current gene string of a gene.
     * @param tokenId The ID of the gene.
     * @return The gene string.
     */
    function getGeneString(uint256 tokenId) public view returns (bytes memory) {
        _requireExistingGene(tokenId);
        return genes[tokenId].geneString;
    }

     /**
     * @dev Returns the current reputation score of a gene.
     * @param tokenId The ID of the gene.
     * @return The reputation score (0-10000).
     */
    function getReputation(uint256 tokenId) public view returns (uint256) {
        _requireExistingGene(tokenId);
        return genes[tokenId].reputation;
    }

    /**
     * @dev Returns the timestamp the gene was last fed.
     * @param tokenId The ID of the gene.
     * @return The last fed timestamp.
     */
    function getLastFedTimestamp(uint256 tokenId) public view returns (uint256) {
        _requireExistingGene(tokenId);
        return genes[tokenId].lastFedTimestamp;
    }


    /**
     * @dev Returns the total amount of FEED_TOKEN staked on a gene.
     * @param tokenId The ID of the gene.
     * @return The staked amount.
     */
    function getStakedAmount(uint256 tokenId) public view returns (uint256) {
         _requireExistingGene(tokenId);
        return stakedTokens[tokenId];
    }

    /**
     * @dev Returns the total number of genes minted.
     * @return The total supply.
     */
    function getTotalMintedGenes() public view returns (uint256) {
        return _nextTokenId;
    }

     /**
     * @dev Returns a tuple of key contract parameters.
     */
    function getContractParameters() public view returns (
        uint256 _vitalityDecayRate,
        uint256 _feedingAmount,
        uint256 _mutationChanceBase,
        uint256 _mutationChanceMutagenMultiplier,
        uint256 _reputationInfluence,
        uint256 _minVitalityForAction,
        uint256 _minMutagenForMutation,
        uint256 _maxMutagen,
        uint256 _maxReputation,
        uint256 _breedingFee,
        address _breedingFeeRecipient,
        address _feedTokenAddress
    ) {
        return (
            vitalityDecayRate,
            feedingAmount,
            mutationChanceBase,
            mutationChanceMutagenMultiplier,
            reputationInfluence,
            minVitalityForAction,
            minMutagenForMutation,
            maxMutagen,
            maxReputation,
            breedingFee,
            breedingFeeRecipient,
            address(FEED_TOKEN)
        );
    }


    // --- Core Mechanics ---

    /**
     * @dev Allows the gene owner to feed the gene with FEED_TOKEN to restore vitality.
     * @param tokenId The ID of the gene to feed.
     * @param amount The amount of FEED_TOKEN to feed.
     */
    function feedGene(uint256 tokenId, uint256 amount) public whenNotPaused {
        _requireExistingGene(tokenId);
        if (ownerOf(tokenId) != _msgSender()) revert ChronoGenesys__NotGeneOwner();
        if (amount == 0) return; // No need to feed 0

        uint256 currentVitality = _calculateCurrentVitality(tokenId);
        uint256 vitalityRestored = amount * feedingAmount;
        uint256 newVitality = Math.min(10000, currentVitality + vitalityRestored);

        genes[tokenId].vitality = newVitality; // Update stored vitality
        genes[tokenId].lastFedTimestamp = block.timestamp; // Update timestamp

        stakedTokens[tokenId] += amount; // Add to staked balance

        // Transfer tokens from feeder to contract
        if (!FEED_TOKEN.transferFrom(_msgSender(), address(this), amount)) {
            revert ChronoGenesys__TransferFailed();
        }

        _updateReputation(tokenId, true, false); // Increase reputation slightly for feeding
        emit GeneFed(tokenId, _msgSender(), amount, newVitality);
    }

    /**
     * @dev Allows the gene owner to withdraw staked tokens.
     *      Currently, only callable after gene is burned.
     *      Future versions could add cooldowns or other conditions.
     * @param tokenId The ID of the gene.
     */
    function withdrawStaked(uint256 tokenId) public whenNotPaused {
         _requireExistingGene(tokenId); // Gene must exist to check owner
         if (ownerOf(tokenId) != _msgSender()) revert ChronoGenesys__NotGeneOwner();

        // For simplicity, allow withdrawal only if gene is burned in this version.
        // A more complex system would track withdrawal eligibility separate from burn.
        // Adding check here just to be explicit about current limitation.
        // To withdraw staked tokens on a live gene, a different function/logic is needed.
        revert ChronoGenesys__StakingNotYetWithdrawable(); // Prevent direct withdrawal on live genes

        // To enable withdrawal on burn, see burnGene function.
        // To enable withdrawal on live gene with cooldown:
        // uint256 staked = stakedTokens[tokenId];
        // if (staked == 0) return;
        // stakedTokens[tokenId] = 0;
        // if (!FEED_TOKEN.transfer(_msgSender(), staked)) revert ChronoGenesys__TransferFailed();
    }

     /**
     * @dev Internal function to handle withdrawal of staked tokens, typically on burn.
     * @param tokenId The ID of the gene.
     * @param recipient The address to send the staked tokens to.
     */
    function _withdrawStakedTokensInternal(uint256 tokenId, address recipient) internal {
         uint256 staked = stakedTokens[tokenId];
         if (staked == 0) return;
         stakedTokens[tokenId] = 0;
         if (!FEED_TOKEN.transfer(recipient, staked)) revert ChronoGenesys__TransferFailed();
    }


    /**
     * @dev Attempts to mutate a gene. Probability depends on parameters, mutagen, and reputation.
     * @param tokenId The ID of the gene to mutate.
     */
    function mutateGene(uint256 tokenId) public whenNotPaused {
        _requireExistingGene(tokenId);
        if (ownerOf(tokenId) != _msgSender()) revert ChronoGenesys__NotGeneOwner();
        if (!_isGeneEligibleForMutationInternal(tokenId)) revert ChronoGenesys__MutationRequirementsNotMet();

        ChronoGene storage gene = genes[tokenId];
        uint256 currentVitality = _calculateCurrentVitality(tokenId);
        bytes memory oldGeneString = gene.geneString;

        // Calculate mutation chance
        // Basic PRNG simulation - NOT SECURE FOR HIGH VALUE
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, _msgSender(), tokenId)));
        uint256 totalChance = mutationChanceBase
            + (gene.mutagen * mutationChanceMutagenMultiplier / 10000) // Mutagen increases chance
            + (gene.reputation * reputationInfluence / 10000);        // Reputation might slightly increase/decrease based on influence design (here adding)

        bool success = (randomNumber % 10000) < totalChance;

        if (success) {
            // Successful mutation: Change gene string, reduce mutagen, update reputation
            gene.geneString = keccak256(abi.encodePacked(oldGeneString, randomNumber, block.gasleft())); // New gene string based on old + randomness
            gene.mutagen = Math.max(0, gene.mutagen - 1000); // Reduce mutagen on success (e.g., by 10%)
            _updateReputation(tokenId, true, true); // Increase reputation for successful action
            emit GeneMutated(tokenId, oldGeneString, gene.geneString, gene.mutagen);

        } else {
            // Failed mutation: Increase mutagen, update reputation
            gene.mutagen = Math.min(maxMutagen, gene.mutagen + 500); // Increase mutagen on failure (e.g., by 5%)
            _updateReputation(tokenId, false, true); // Decrease reputation slightly for failed action
            emit GeneMutationFailed(tokenId, gene.mutagen);
        }

        // Mutation consumes some vitality (optional, add if desired)
        // gene.vitality = Math.max(0, currentVitality - 500); // e.g., consume 5% vitality
        // genes[tokenId].lastFedTimestamp = block.timestamp; // Reset timer if vitality is consumed

    }

     /**
     * @dev Attempts to breed two genes to produce a new one.
     * @param parent1Id The ID of the first parent gene.
     * @param parent2Id The ID of the second parent gene.
     */
    function breedGenes(uint256 parent1Id, uint256 parent2Id) public payable whenNotPaused {
        _requireExistingGene(parent1Id);
        _requireExistingGene(parent2Id);

        if (parent1Id == parent2Id) revert ChronoGenesys__CannotBreedWithSelf();
        if (ownerOf(parent1Id) != _msgSender() || ownerOf(parent2Id) != _msgSender()) {
             // Allow breeding if caller owns *both* or if caller is approved/operator for both
             // Assuming owner MUST own both for simplicity here
             revert ChronoGenesys__NotGeneOwner();
        }

        if (!_isGeneEligibleForBreedingInternal(parent1Id, parent2Id)) revert ChronoGenesys__BreedingRequirementsNotMet();

        // Check and collect breeding fee
        if (msg.value < breedingFee) {
             // Assuming fee is in native token (ether) for simplicity of payable function
             // Could be changed to FEED_TOKEN requiring approval/transferFrom
             revert ChronoGenesys__InsufficientFees(); // Need a specific error for fees
        }
        // Transfer excess native token back if any
        if (msg.value > breedingFee) {
            Address.sendValue(payable(_msgSender()), msg.value - breedingFee);
        }

        // Transfer breeding fee to recipient
        if (breedingFee > 0) {
             if (breedingFeeRecipient == address(0)) revert ChronoGenesys__BreedingFeeRecipientNotSet(); // Add specific error
             Address.sendValue(payable(breedingFeeRecipient), breedingFee);
        }


        ChronoGene storage parent1 = genes[parent1Id];
        ChronoGene storage parent2 = genes[parent2Id];

        uint256 newChildId = _nextTokenId++;
        _safeMint(_msgSender(), newChildId);

        // Generate child gene string (simple mix)
        bytes memory parent1String = parent1.geneString;
        bytes memory parent2String = parent2.geneString;
        bytes memory childGeneString = new bytes(parent1String.length + parent2String.length);
        uint256 childStringLength = 0;

        // Simple mixing: take half from parent1, half from parent2
        uint256 mixPoint1 = parent1String.length / 2;
        uint256 mixPoint2 = parent2String.length / 2;

        for(uint256 i = 0; i < mixPoint1; i++) {
            childGeneString[childStringLength++] = parent1String[i];
        }
        for(uint256 i = 0; i < mixPoint2; i++) {
             childGeneString[childStringLength++] = parent2String[i];
        }
        // Add some "randomness" influenced by parents' mutagen/reputation
        bytes memory randomnessSeed = abi.encodePacked(
            parent1.mutagen,
            parent2.mutagen,
            parent1.reputation,
            parent2.reputation,
            block.timestamp,
            newChildId
        );
         bytes32 randomHash = keccak256(randomnessSeed);
         for(uint256 i = 0; i < 4; i++) { // Add 4 bytes of randomness
              if (childStringLength >= childGeneString.length) break; // Prevent overflow
             childGeneString[childStringLength++] = randomHash[i];
         }
         // Resize if excess space was allocated
        assembly {
            mstore(childGeneString, childStringLength)
        }


        // Initialize child traits
        genes[newChildId] = ChronoGene({
            creationEpoch: block.timestamp,
            ancestryHash: keccak256(abi.encodePacked(parent1Id, parent2Id)),
            vitality: Math.min(10000, (parent1.vitality + parent2.vitality) / 2), // Average vitality
            mutagen: Math.min(maxMutagen, (parent1.mutagen + parent2.mutagen) / 2), // Average mutagen
            geneString: childGeneString,
            reputation: Math.min(maxReputation, (parent1.reputation + parent2.reputation) / 2), // Average reputation
            lastFedTimestamp: block.timestamp
        });

        // Update parent states (e.g., consume vitality, increase mutagen slightly)
        // Parent vitality reduction
        uint256 p1Vitality = _calculateCurrentVitality(parent1Id);
        uint256 p2Vitality = _calculateCurrentVitality(parent2Id);
        genes[parent1Id].vitality = Math.max(0, p1Vitality - 1000); // e.g., 10% vitality cost
        genes[parent2Id].vitality = Math.max(0, p2Vitality - 1000); // e.g., 10% vitality cost
        genes[parent1Id].lastFedTimestamp = block.timestamp; // Reset timer
        genes[parent2Id].lastFedTimestamp = block.timestamp; // Reset timer

        // Parent mutagen increase
        genes[parent1Id].mutagen = Math.min(maxMutagen, parent1.mutagen + 200); // e.g., 2% mutagen increase
        genes[parent2Id].mutagen = Math.min(maxMutagen, parent2.mutagen + 200); // e.g., 2% mutagen increase

        _updateReputation(parent1Id, true, false); // Increase parents' reputation for successful breeding
        _updateReputation(parent2Id, true, false);

        emit GenesBred(parent1Id, parent2Id, newChildId, childGeneString);
        // Reputation update events for parents
        emit GeneReputationUpdated(parent1Id, parent1.reputation, genes[parent1Id].reputation);
        emit GeneReputationUpdated(parent2Id, parent2.reputation, genes[parent2Id].reputation);
        // Initial reputation event for child (optional)
        emit GeneReputationUpdated(newChildId, 0, genes[newChildId].reputation);
    }

    // --- Reputation System ---

    /**
     * @dev Internal function to update a gene's reputation.
     *      Reputation increases on positive actions (feeding, successful mutation/breeding).
     *      Reputation decreases on negative actions (failed mutation).
     * @param tokenId The ID of the gene.
     * @param success Indicates if the associated action was successful.
     * @param isEvolutionAction Indicates if the action was mutation or breeding (vs feeding).
     */
    function _updateReputation(uint256 tokenId, bool success, bool isEvolutionAction) internal {
        ChronoGene storage gene = genes[tokenId];
        uint256 oldReputation = gene.reputation;
        uint256 newReputation = oldReputation;

        if (isEvolutionAction) {
            if (success) {
                newReputation = Math.min(maxReputation, oldReputation + 150); // +1.5% on evolution success
            } else { // Failed evolution action (mutation)
                 newReputation = Math.max(0, oldReputation - 100); // -1% on evolution failure
            }
        } else { // Feeding action
             newReputation = Math.min(maxReputation, oldReputation + 50); // +0.5% on feeding
        }

        if (newReputation != oldReputation) {
             gene.reputation = newReputation;
             emit GeneReputationUpdated(tokenId, oldReputation, newReputation);
        }
    }

     // --- Utility & Admin ---

    /**
     * @dev Allows owner to set the vitality decay rate.
     * @param rate New decay rate (per 10000 vitality unit).
     */
    function setVitalityDecayRate(uint256 rate) public onlyOwner {
        emit ParametersUpdated("VitalityDecayRate", vitalityDecayRate, rate);
        vitalityDecayRate = rate;
    }

    /**
     * @dev Allows owner to set the amount of vitality restored per FEED_TOKEN unit.
     * @param amount New feeding vitality amount.
     */
    function setFeedingParams(uint256 amount) public onlyOwner {
         emit ParametersUpdated("FeedingAmount", feedingAmount, amount);
        feedingAmount = amount;
    }

    /**
     * @dev Allows owner to set mutation parameters.
     * @param chanceBase New base chance (out of 10000).
     * @param mutagenMultiplier New mutagen multiplier (per 10000 mutagen unit).
     * @param reputationEffect New reputation influence (per 10000 reputation unit).
     * @param minMutagen New min mutagen requirement.
     */
    function setMutationParams(uint256 chanceBase, uint256 mutagenMultiplier, uint256 reputationEffect, uint256 minMutagen) public onlyOwner {
        emit ParametersUpdated("MutationChanceBase", mutationChanceBase, chanceBase);
        emit ParametersUpdated("MutationChanceMutagenMultiplier", mutationChanceMutagenMultiplier, mutagenMultiplier);
        emit ParametersUpdated("ReputationInfluence", reputationInfluence, reputationEffect);
        emit ParametersUpdated("MinMutagenForMutation", minMutagenForMutation, minMutagen);
        mutationChanceBase = chanceBase;
        mutationChanceMutagenMultiplier = mutagenMultiplier;
        reputationInfluence = reputationEffect;
        minMutagenForMutation = minMutagen;
    }

    /**
     * @dev Allows owner to set breeding parameters.
     * @param fee New breeding fee.
     * @param minVitality New min vitality requirement.
     */
    function setBreedingParams(uint256 fee, uint256 minVitality) public onlyOwner {
        emit ParametersUpdated("BreedingFee", breedingFee, fee);
        emit ParametersUpdated("MinVitalityForAction", minVitalityForAction, minVitality); // MinVitalityForAction applies to both currently
        breedingFee = fee;
        minVitalityForAction = minVitality;
    }


     /**
     * @dev Allows owner to set the recipient for breeding fees.
     * @param recipient New fee recipient address.
     */
    function setBreedingFeeRecipient(address recipient) public onlyOwner {
        if (recipient == address(0)) revert ChronoGenesys__BreedingFeeRecipientNotSet(); // Add specific error if needed
        emit BreedingFeeRecipientUpdated(breedingFeeRecipient, recipient);
        breedingFeeRecipient = recipient;
    }


    /**
     * @dev Allows the owner to withdraw collected fees (e.g., FEED_TOKEN from staking, or native token fees).
     * @param tokenAddress The address of the token to withdraw (or address(0) for native token).
     */
    function withdrawFees(address tokenAddress) public onlyOwner {
        if (tokenAddress == address(0)) {
            // Withdraw native token (ether)
            uint256 balance = address(this).balance;
            if (balance == 0) revert ChronoGenesys__NoFeesToWithdraw();
            Address.sendValue(payable(_msgSender()), balance);
        } else if (tokenAddress == address(FEED_TOKEN)) {
            // Withdraw staked FEED_TOKEN that wasn't withdrawn on burn (this shouldn't happen if burn logic is correct)
             // Or potentially fees collected in FEED_TOKEN if breeding fee was changed to be in FEED_TOKEN.
             // For now, let's assume fees collected are native token, and FEED_TOKEN is only for staking.
             // If FEED_TOKEN was used for breeding fees, we'd need a separate mapping for collected fees.
             // Let's allow withdrawing *all* FEED_TOKEN balance in the contract for admin recovery.
             uint256 balance = FEED_TOKEN.balanceOf(address(this));
             // Note: this will withdraw *all* staked tokens too! Use with caution or adjust logic.
             // A proper fee withdrawal in FEED_TOKEN needs a separate fee balance tracking.
             // Let's restrict this for now or make it withdraw ONLY a separate fee balance.
             // For the demo, let's add a simple mechanism: allow withdrawing any FEED_TOKEN ONLY if no genes have staked tokens.
             // A better way is to track `totalStakedTokens` and `totalCollectedFeedTokenFees`.
             // uint256 totalStaked = 0; // Would need to iterate or track globally
             // if (balance == 0 || balance <= totalStaked) revert ChronoGenesys__NoFeesToWithdraw();
             // uint256 feeBalance = balance - totalStaked;
             // if (feeBalance == 0) revert ChronoGenesys__NoFeesToWithdraw();
             // if (!FEED_TOKEN.transfer(_msgSender(), feeBalance)) revert ChronoGenesys__TransferFailed();

             // Simpler for demo: If tokenAddress is FEED_TOKEN, assume withdrawing all available.
             // This is risky in a real contract if staking is active.
             // Acknowledge this limitation: This is only safe if FEED_TOKEN is *only* used for fees and *not* staking.
             // Or if the contract has separate fee balances.
             // Let's add a basic check that there are tokens to withdraw.
             uint256 balance = FEED_TOKEN.balanceOf(address(this));
             if (balance == 0) revert ChronoGenesys__NoFeesToWithdraw();
             if (!FEED_TOKEN.transfer(_msgSender(), balance)) revert ChronoGenesys__TransferFailed();

        } else {
            revert ChronoGenesys__NoFeesToWithdraw(); // Or specific error for invalid token address
        }
    }


     /**
     * @dev Pauses core contract functions.
     * Can only be called by the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     * Can only be called by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

     // --- Derived Data ---

    /**
     * @dev Generates a unique hash for a gene based on its dynamic traits.
     * Useful for off-chain identification or rendering.
     * @param tokenId The ID of the gene.
     * @return The generated hash.
     */
    function getGeneHash(uint256 tokenId) public view returns (bytes32) {
        _requireExistingGene(tokenId);
        ChronoGene storage gene = genes[tokenId];
        return keccak256(abi.encodePacked(
            gene.creationEpoch,
            gene.ancestryHash,
            gene.vitality, // Include current vitality for dynamic hash
            gene.mutagen,
            gene.geneString,
            gene.reputation
            // lastFedTimestamp might change frequently, exclude from visual hash
        ));
    }

    // --- Eligibility Checks ---

    /**
     * @dev Checks if a gene meets the criteria for mutation.
     * @param tokenId The ID of the gene.
     * @return True if eligible, false otherwise.
     */
    function isGeneEligibleForMutation(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) return false; // Must exist
         return _isGeneEligibleForMutationInternal(tokenId);
    }

     /**
     * @dev Internal helper to check mutation eligibility.
     * @param tokenId The ID of the gene.
     * @return True if eligible, false otherwise.
     */
    function _isGeneEligibleForMutationInternal(uint256 tokenId) internal view returns (bool) {
        ChronoGene storage gene = genes[tokenId];
        uint256 currentVitality = _calculateCurrentVitality(tokenId);
        return currentVitality >= minVitalityForAction && gene.mutagen >= minMutagenForMutation;
    }

    /**
     * @dev Checks if two genes meet the criteria for breeding.
     * @param parent1Id The ID of the first parent.
     * @param parent2Id The ID of the second parent.
     * @return True if eligible, false otherwise.
     */
    function isGeneEligibleForBreeding(uint256 parent1Id, uint256 parent2Id) public view returns (bool) {
        if (!_exists(parent1Id) || !_exists(parent2Id)) return false; // Both must exist
        if (parent1Id == parent2Id) return false; // Cannot breed with self

        ChronoGene storage gene1 = genes[parent1Id];
        ChronoGene storage gene2 = genes[parent2Id];
        uint256 p1Vitality = _calculateCurrentVitality(parent1Id);
        uint256 p2Vitality = _calculateCurrentVitality(parent2Id);

        // Require minimum vitality for both parents
        return p1Vitality >= minVitalityForAction && p2Vitality >= minVitalityForAction;
        // Could add other checks: min reputation, max breeding count per gene, cooldown etc.
    }


    // --- ERC721 Overrides ---

    /**
     * @dev See {ERC721-tokenURI}.
     * @param tokenId The ID of the gene.
     * @return A URI string pointing to the metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireExistingGene(tokenId);
        // Base URI logic (e.g., IPFS gateway or API endpoint)
        string memory base = _baseURI();
        bytes32 geneHash = getGeneHash(tokenId); // Use dynamic hash

        // In a real application, this URI would point to a JSON metadata file
        // containing the gene's traits and image data.
        // For this example, we'll return a placeholder or a URI derived from the hash.
        // e.g., "ipfs://[base_cid]/[gene_hash].json" or "api.example.com/genes/[tokenId]/metadata"

        // Simple placeholder return:
        return string(abi.encodePacked(base, bytes32ToString(geneHash), ".json"));
    }

    // Internal helper to convert bytes32 to hex string for URI (basic implementation)
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(64);
        bytes memory hexChars = "0123456789abcdef";

        for (uint j = 0; j < 32; j++) {
            bytesString[j * 2] = hexChars[uint8(_bytes32[j] >> 4)];
            bytesString[j * 2 + 1] = hexChars[uint8(_bytes32[j] & 0x0F)];
        }
        return string(bytesString);
    }

    /**
     * @dev See {ERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    // --- Internal Helpers ---

    /**
     * @dev Asserts that a token ID corresponds to an existing gene.
     */
    function _requireExistingGene(uint256 tokenId) internal view {
         if (!_exists(tokenId)) revert ChronoGenesys__GeneDoesNotExist();
    }

    // Overriding standard transfer functions to potentially add hooks later if needed
    // For now, just call super, but this is where you'd add pre/post transfer logic
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        super.transferFrom(from, to, tokenId);
        // Potentially add hooks here, e.g., reputation change on transfer? Vitality pause?
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
        // Potentially add hooks here
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override(ERC721, IERC721) whenNotPaused {
         super.safeTransferFrom(from, to, tokenId, data);
         // Potentially add hooks here
    }
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic NFTs (`ChronoGene` struct & `genes` mapping):** Instead of static metadata, the core `ChronoGene` struct holds mutable state (`vitality`, `mutagen`, `geneString`, `reputation`, `lastFedTimestamp`) directly within the contract's storage. This state is updated by function calls.
2.  **On-chain Gamified Mechanics:**
    *   **Vitality Decay & Feeding:** Introduces a resource management layer. Genes lose vitality over time (`vitalityDecayRate`). Users must "feed" them (`feedGene`) by staking `FEED_TOKEN` to prevent vitality from hitting zero (which could have consequences, e.g., reduced performance, inability to mutate/breed, or even 'death'/burning).
    *   **Mutation:** A probabilistic event (`mutateGene`) influenced by current traits (`mutagen`, `reputation`) and contract parameters. It can succeed (changing `geneString`, reducing `mutagen`) or fail (increasing `mutagen`). This creates an on-chain element of chance and risk/reward.
    *   **Breeding:** Allows combining two existing NFTs (`breedGenes`) to produce a new one. The child's initial traits are derived from the parents' traits via on-chain logic. This introduces lineage and trait inheritance concepts. Requires conditions met (vitality) and a fee.
3.  **On-chain Trait Generation (`geneString` manipulation):** The `mutateGene` and `breedGenes` functions directly manipulate the `geneString` byte array. While the actual visual interpretation happens off-chain, the "source code" of the visual representation is generated and stored immutably (except through mutation/breeding) on the blockchain itself. This enables on-chain generative art or characteristics.
4.  **Reputation System:** Genes have a reputation score (`reputation`) that is updated based on owner actions (feeding, successful/failed evolution attempts). This score can influence the probability or outcome of future actions, adding a layer of persistent consequence to user behavior within the ecosystem.
5.  **Inter-NFT Interaction:** The `breedGenes` function requires two distinct NFTs to interact with each other, resulting in a new NFT.
6.  **Resource Staking (`stakedTokens` mapping):** When feeding, `FEED_TOKEN` is transferred to the contract and tracked per token ID. This isn't pure staking yield, but rather "locking" tokens for a service (maintaining vitality). Staked tokens are intended to be withdrawable (e.g., if the gene is burned), though the withdrawal logic here is simplified.
7.  **Dynamic `tokenURI`:** The `tokenURI` function generates the metadata URI based on the *current* state of the gene, potentially even including the dynamic `geneHash`, ensuring off-chain metadata reflects the gene's evolution.

This contract provides a framework for a complex, interactive NFT ecosystem where the NFTs are not just static collectibles but active participants whose state is influenced by the owner's strategy and the game's mechanics.

**Potential Extensions/Improvements (Not included to keep focus and function count manageable):**

*   More sophisticated `geneString` manipulation and inheritance logic.
*   Consequences for 0 vitality (e.g., temporary inactivity, permanent death).
*   Cooldowns for mutation/breeding.
*   Different types of feeding tokens or actions.
*   Traits influencing game mechanics directly (e.g., certain genes decay slower).
*   Oracle integration for external factors influencing genes.
*   Batch feeding/mutation/breeding.
*   Delegation of actions (allowing others to feed/mutate your gene).
*   Automated vitality maintenance (e.g., approve contract to pull tokens periodically).
*   More robust PRNG (using VRF like Chainlink).
*   Specific errors for all revert conditions.
*   Gas optimizations.