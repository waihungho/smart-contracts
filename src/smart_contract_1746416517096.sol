Okay, here is a Solidity smart contract that implements a "Generative Art Mutation Registry". The concept is that users own unique "DNA" structs on-chain, which represent the parameters or "genes" for a piece of generative art. These DNAs can be dynamically mutated by the owner under certain conditions, leading to the art evolving over time. The contract manages the ownership, mutation process, fees, and provides functions to query the state of these on-chain art parameters.

This contract avoids directly implementing standard interfaces like ERC-721, focusing on a custom ownership and interaction model for the generative parameters themselves.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title GenerativeArtMutationRegistry
 * @dev A contract for managing dynamic, on-chain generative art "DNA".
 * Users own unique DNA structs which represent parameters for generative art.
 * These DNAs can be mutated over time through an on-chain process, causing the art
 * to evolve. The contract handles minting, ownership, mutation mechanics, and fees.
 *
 * Outline:
 * 1.  Defines the GenerativeDNA struct.
 * 2.  Stores DNA structs in a mapping (the "DNA Pool").
 * 3.  Manages contract state (admin, fees, parameters, pause status).
 * 4.  Provides functions for minting new DNA.
 * 5.  Implements a two-step mutation process (request + execute) with fees and cooldowns.
 * 6.  Allows transfer and burning of DNA ownership.
 * 7.  Includes various read functions to query DNA and contract state.
 * 8.  Provides admin functions for configuration and fee withdrawal.
 * 9.  Includes basic access control and pausability.
 *
 * Function Summary:
 * - Constructor: Initializes admin, fees, and parameters.
 * - onlyAdmin: Modifier to restrict functions to the admin.
 * - whenNotPaused / whenPaused: Modifiers for pausability.
 *
 * --- Minting ---
 * 1. mintNewDNA: Mints a single new DNA with initial genes.
 * 2. batchMintNewDNA: Mints multiple new DNAs.
 * 3. setBaseGeneLength: Admin sets the required length of the genes array.
 * 4. setInitialGeneValues: Admin sets default gene values for new mints.
 *
 * --- Mutation ---
 * 5. requestMutation: Owner requests mutation for their DNA, pays fee.
 * 6. executeMutation: Executes the queued mutation after cooldown, applying changes based on randomness.
 * 7. setMutationFee: Admin sets the fee for requesting mutation.
 * 8. setMinMutationInterval: Admin sets the minimum time between mutation execution for a DNA.
 * 9. setGeneMutationRange: Admin sets the max delta for gene values during mutation.
 * 10. setGeneMutationProbability: Admin sets the probability (numerator/denominator) for each gene to mutate.
 * 11. pauseMutations: Admin can pause the mutation process.
 *
 * --- Ownership & Transfer ---
 * 12. transferDNA: Transfers ownership of a single DNA.
 * 13. transferManyDNA: Transfers ownership of multiple DNAs.
 * 14. burnDNA: Owner can burn/destroy a DNA.
 *
 * --- Viewing & Querying ---
 * 15. getDNA: Retrieves the full GenerativeDNA struct by ID.
 * 16. getDNAGenes: Retrieves only the gene array for a DNA.
 * 17. getDNAOwner: Retrieves the owner of a DNA.
 * 18. getTotalSupply: Gets the total number of DNAs minted.
 * 19. getMutationFee: Gets the current mutation request fee.
 * 20. getMinMutationInterval: Gets the current mutation cooldown interval.
 * 21. isMutationRequested: Checks if a mutation request is pending for a DNA.
 * 22. getMutationRequestTime: Gets the block timestamp when mutation was requested.
 * 23. getMutationStatus: Provides a summary status (pending, ready, cooldown, not requested).
 * 24. setRenderingHint: Owner can set a hint string for off-chain renderers.
 * 25. getRenderingHint: Retrieves the rendering hint string.
 *
 * --- Admin ---
 * 26. withdrawFees: Admin can withdraw collected mutation fees.
 * 27. setAdmin: Admin can transfer admin rights.
 */

// --- Error Definitions ---
error NotAdmin();
error Paused();
error NotOwner(uint256 dnaId, address caller);
error DNADoesNotExist(uint256 dnaId);
error InsufficientPayment(uint256 required, uint256 provided);
error MutationNotRequested(uint256 dnaId);
error MutationIntervalNotPassed(uint256 dnaId, uint256 timeRemaining);
error MutationAlreadyRequested(uint256 dnaId);
error ZeroAddressRecipient();
error ZeroAmount();
error GenesLengthMismatch(uint256 expected, uint256 provided);
error MaxBatchSizeExceeded(uint256 maxBatchSize, uint256 requestedSize);


// --- Event Definitions ---
event DNAMinted(uint256 indexed dnaId, address indexed owner, uint256 creationBlock, uint256[] genes);
event DNATransferred(uint256 indexed dnaId, address indexed from, address indexed to);
event DNABurned(uint256 indexed dnaId, address indexed owner);
event MutationRequested(uint256 indexed dnaId, address indexed requester, uint256 feePaid, uint256 requestTime);
event MutationExecuted(uint256 indexed dnaId, uint256 indexed newGeneration, uint256 newMutationCount, uint256 executionTime);
event FeesWithdrawn(address indexed recipient, uint256 amount);
event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
event MutationPaused(bool paused);
event RenderingHintSet(uint256 indexed dnaId, string hint);

// --- Struct Definitions ---
struct GenerativeDNA {
    uint256 id;
    address owner;
    uint256 generation;         // Number of successful mutations applied
    uint256 creationBlock;
    uint256 mutationCount;      // Total mutation attempts (requests)
    uint256 lastMutationBlock;  // Block when executeMutation last happened
    uint256 mutationRequestTime; // Timestamp when mutation was requested
    uint256[] genes;            // The array of parameters defining the art
    string renderingHint;       // Optional hint for off-chain rendering
}

// --- Contract Implementation ---
contract GenerativeArtMutationRegistry {

    // --- State Variables ---
    mapping(uint256 => GenerativeDNA) private dnaPool;
    uint256 public nextDNAId;

    address public admin;
    uint256 public mutationFee; // in wei
    uint256 public minMutationInterval; // in seconds
    bool public paused;

    uint256 public baseGeneLength;
    uint256 public geneMutationRange; // Max +/- delta for a gene during mutation
    uint256 public geneMutationProbabilityNumerator;
    uint256 public geneMutationProbabilityDenominator; // e.g., 1/100 (1%)

    uint256 public constant MAX_BATCH_SIZE = 100; // Limit batch operations

    uint256[] private initialGeneValues; // Default genes for new mints

    // --- Constructor ---
    constructor(
        uint256 _initialMutationFee,
        uint256 _initialMinMutationInterval,
        uint256 _initialBaseGeneLength,
        uint256 _initialGeneMutationRange,
        uint256 _initialGeneMutationProbabilityNumerator,
        uint256 _initialGeneMutationProbabilityDenominator
    ) {
        admin = msg.sender;
        mutationFee = _initialMutationFee;
        minMutationInterval = _initialMinMutationInterval;
        baseGeneLength = _initialBaseGeneLength;
        geneMutationRange = _initialGeneMutationRange;
        geneMutationProbabilityNumerator = _initialGeneMutationProbabilityNumerator;
        geneMutationProbabilityDenominator = _initialGeneMutationProbabilityDenominator;
        paused = false;
        nextDNAId = 1;
    }

    // --- Modifiers ---
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert Paused();
        _;
    }

    // --- Internal Helpers ---
    /**
     * @dev Generates the initial gene array for a new DNA.
     * Uses initialGeneValues if set, otherwise creates a default array.
     */
    function _generateInitialGenes() internal view returns (uint256[] memory) {
        if (initialGeneValues.length == baseGeneLength) {
            return initialGeneValues;
        }
        // Fallback: Create a default gene array (e.g., all zeros)
        uint256[] memory genes = new uint256[](baseGeneLength);
        // Optional: add some non-zero default values based on nextDNAId or block.timestamp
        // for basic variance even without initialGeneValues set.
        return genes;
    }

    /**
     * @dev Applies mutation logic to a gene array based on randomness and contract parameters.
     * @param genes The gene array to mutate.
     * @param randomness A source of randomness (e.g., blockhash or other input).
     */
    function _applyMutation(uint256[] storage genes, uint256 randomness) internal {
        uint256 rngSeed = randomness;
        for (uint256 i = 0; i < genes.length; i++) {
            // Simple PRNG logic: hash previous seed
            rngSeed = uint256(keccak256(abi.encodePacked(rngSeed, i)));

            // Determine if this gene mutates based on probability
            if (rngSeed % geneMutationProbabilityDenominator < geneMutationProbabilityNumerator) {
                rngSeed = uint256(keccak256(abi.encodePacked(rngSeed, "mutate")));
                int256 delta = 0;
                // Determine mutation delta (+/- geneMutationRange)
                if (rngSeed % 2 == 0) { // 50% chance of positive/negative delta
                     delta = int256(rngSeed % (geneMutationRange + 1));
                } else {
                     delta = -int256(rngSeed % (geneMutationRange + 1));
                }

                // Apply delta. Handle potential wrapping around uint256 max/min.
                // A more complex system might have gene-specific clamping or wrap logic.
                // Here, we'll use checked arithmetic and let it wrap if necessary (simple approach).
                // A safer approach would be to clamp values between 0 and MAX_GENE_VALUE
                unchecked {
                    genes[i] = uint256(int256(genes[i]) + delta);
                }
            }
        }
    }


    /**
     * @dev Gets a source of randomness for mutation execution.
     * NOTE: blockhash is NOT cryptographically secure randomness and can be manipulated by miners.
     * For production systems requiring secure randomness, use Chainlink VRF or a similar oracle.
     */
    function _getRandomness() internal view returns (uint256) {
        // Combine block properties for slightly more variance (still not secure)
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number)));
    }

    // --- Minting Functions ---

    /**
     * @dev Mints a single new Generative DNA token.
     * The new DNA is assigned an ID, ownership is set to the caller,
     * and initial genes are generated.
     */
    function mintNewDNA() external whenNotPaused {
        uint256 dnaId = nextDNAId;
        require(baseGeneLength > 0, "Base gene length must be set");

        GenerativeDNA storage newDNA = dnaPool[dnaId];
        newDNA.id = dnaId;
        newDNA.owner = msg.sender;
        newDNA.generation = 0;
        newDNA.creationBlock = block.number;
        newDNA.mutationCount = 0;
        newDNA.lastMutationBlock = 0; // Not mutated yet
        newDNA.mutationRequestTime = 0; // Not requested yet
        newDNA.genes = _generateInitialGenes();
        newDNA.renderingHint = ""; // Default empty hint

        nextDNAId++;

        emit DNAMinted(dnaId, msg.sender, block.number, newDNA.genes);
    }

    /**
     * @dev Mints multiple new Generative DNA tokens in a single transaction.
     * Limited by MAX_BATCH_SIZE.
     * @param count The number of DNAs to mint.
     */
    function batchMintNewDNA(uint256 count) external whenNotPaused {
        if (count == 0 || count > MAX_BATCH_SIZE) revert MaxBatchSizeExceeded(MAX_BATCH_SIZE, count);
        for (uint256 i = 0; i < count; i++) {
            mintNewDNA(); // Call the single mint function
        }
    }

    /**
     * @dev Admin function to set the required length for gene arrays.
     * Affects all subsequent mints.
     * @param length The new base gene length.
     */
    function setBaseGeneLength(uint256 length) external onlyAdmin {
        baseGeneLength = length;
    }

    /**
     * @dev Admin function to set the default gene values for new mints.
     * The length must match baseGeneLength if set.
     * @param values The array of default gene values.
     */
    function setInitialGeneValues(uint256[] calldata values) external onlyAdmin {
         if (values.length > 0 && values.length != baseGeneLength) revert GenesLengthMismatch(baseGeneLength, values.length);
        initialGeneValues = values;
    }


    // --- Mutation Functions ---

    /**
     * @dev Allows the owner of a DNA to request a mutation.
     * Requires payment of the mutation fee and checks if a request is already pending.
     * Does not perform the mutation immediately; it queues it for execution.
     * @param dnaId The ID of the DNA to mutate.
     */
    function requestMutation(uint256 dnaId) external payable whenNotPaused {
        GenerativeDNA storage dna = dnaPool[dnaId];
        if (dna.owner == address(0)) revert DNADoesNotExist(dnaId); // Check if DNA exists
        if (dna.owner != msg.sender) revert NotOwner(dnaId, msg.sender);
        if (msg.value < mutationFee) revert InsufficientPayment(mutationFee, msg.value);
        if (dna.mutationRequestTime > 0) revert MutationAlreadyRequested(dnaId);

        // Check if minimum interval since last EXECUTION has passed (if any)
        // This prevents requesting too soon after a successful mutation
        if (dna.lastMutationBlock > 0 && block.timestamp < dna.lastMutationBlock + minMutationInterval) {
             revert MutationIntervalNotPassed(dnaId, dna.lastMutationBlock + minMutationInterval - block.timestamp);
        }


        dna.mutationRequestTime = block.timestamp;
        // Fees are held in the contract balance until withdrawn by admin

        emit MutationRequested(dnaId, msg.sender, msg.value, dna.mutationRequestTime);
    }

    /**
     * @dev Executes a previously requested mutation for a DNA.
     * Can be called by anyone, but only if a mutation was requested and
     * the minimum interval since the *request* time has passed (or since last execution if configured differently).
     * This design allows off-chain services to trigger the execution.
     * Applies mutation logic based on a source of randomness (here, block data).
     * @param dnaId The ID of the DNA to mutate.
     * NOTE: Using blockhash/block.timestamp is insecure for critical randomness.
     * A real system might use Chainlink VRF or similar secure oracle randomness.
     */
    function executeMutation(uint256 dnaId) external whenNotPaused {
         GenerativeDNA storage dna = dnaPool[dnaId];
        if (dna.owner == address(0)) revert DNADoesNotExist(dnaId); // Check if DNA exists
        if (dna.mutationRequestTime == 0) revert MutationNotRequested(dnaId);

        // Check if the minimum interval since the *request* time has passed
        // This ensures the owner had time between requesting and execution if needed,
        // and prevents immediate execution after request.
        // Alternatively, the interval could be since lastMutationBlock, checked in requestMutation.
        // Current logic: Interval since request, *plus* requestMutation also checks interval since last execution.
         if (block.timestamp < dna.mutationRequestTime + minMutationInterval) {
             revert MutationIntervalNotPassed(dnaId, dna.mutationRequestTime + minMutationInterval - block.timestamp);
        }


        uint256 randomness = _getRandomness(); // Insecure randomness source!

        _applyMutation(dna.genes, randomness);

        dna.generation++;
        dna.mutationCount++;
        dna.lastMutationBlock = block.timestamp; // Use timestamp for interval checks
        dna.mutationRequestTime = 0; // Clear the request status

        emit MutationExecuted(dnaId, dna.generation, dna.mutationCount, block.timestamp);
    }

    /**
     * @dev Admin function to set the fee required for requesting mutation.
     * @param newFee The new fee amount in wei.
     */
    function setMutationFee(uint256 newFee) external onlyAdmin {
        mutationFee = newFee;
    }

    /**
     * @dev Admin function to set the minimum time interval (in seconds) between mutation executions for a single DNA.
     * @param seconds The new minimum interval in seconds.
     */
    function setMinMutationInterval(uint256 seconds) external onlyAdmin {
        minMutationInterval = seconds;
    }

    /**
     * @dev Admin function to set the maximum range (+/-) for gene value changes during mutation.
     * @param maxDelta The new maximum delta.
     */
    function setGeneMutationRange(uint256 maxDelta) external onlyAdmin {
        geneMutationRange = maxDelta;
    }

     /**
     * @dev Admin function to set the probability of each gene mutating during executeMutation.
     * Probability = numerator / denominator. E.g., 1/100 for 1%.
     * @param probabilityNumerator The numerator for the probability fraction.
     * @param probabilityDenominator The denominator for the probability fraction.
     */
    function setGeneMutationProbability(uint256 probabilityNumerator, uint256 probabilityDenominator) external onlyAdmin {
        // Basic sanity check
        require(probabilityDenominator > 0, "Denominator cannot be zero");
        require(probabilityNumerator <= probabilityDenominator, "Numerator cannot exceed denominator");
        geneMutationProbabilityNumerator = probabilityNumerator;
        geneMutationProbabilityDenominator = probabilityDenominator;
    }

    /**
     * @dev Admin function to pause or unpause the mutation process (request and execute).
     * @param _paused True to pause, false to unpause.
     */
    function pauseMutations(bool _paused) external onlyAdmin {
        paused = _paused;
        emit MutationPaused(paused);
    }

    // --- Ownership & Transfer Functions ---

    /**
     * @dev Transfers ownership of a single DNA from the caller to a recipient.
     * Caller must be the current owner.
     * @param recipient The address to transfer the DNA to.
     * @param dnaId The ID of the DNA to transfer.
     */
    function transferDNA(address recipient, uint256 dnaId) external whenNotPaused {
         GenerativeDNA storage dna = dnaPool[dnaId];
        if (dna.owner == address(0)) revert DNADoesNotExist(dnaId); // Check if DNA exists
        if (dna.owner != msg.sender) revert NotOwner(dnaId, msg.sender);
        if (recipient == address(0)) revert ZeroAddressRecipient();

        address oldOwner = dna.owner;
        dna.owner = recipient;

        emit DNATransferred(dnaId, oldOwner, recipient);
    }

    /**
     * @dev Transfers ownership of multiple DNAs from the caller to a recipient.
     * Caller must be the owner of all specified DNAs.
     * Limited by MAX_BATCH_SIZE.
     * @param recipient The address to transfer the DNAs to.
     * @param dnaIds The array of DNA IDs to transfer.
     */
    function transferManyDNA(address recipient, uint256[] calldata dnaIds) external whenNotPaused {
        if (dnaIds.length == 0 || dnaIds.length > MAX_BATCH_SIZE) revert MaxBatchSizeExceeded(MAX_BATCH_SIZE, dnaIds.length);
        if (recipient == address(0)) revert ZeroAddressRecipient();

        for (uint256 i = 0; i < dnaIds.length; i++) {
             GenerativeDNA storage dna = dnaPool[dnaIds[i]];
            if (dna.owner == address(0)) revert DNADoesNotExist(dnaIds[i]); // Check if DNA exists
            if (dna.owner != msg.sender) revert NotOwner(dnaIds[i], msg.sender);

            address oldOwner = dna.owner;
            dna.owner = recipient;
            emit DNATransferred(dnaIds[i], oldOwner, recipient);
        }
    }

    /**
     * @dev Allows the owner to burn/destroy a DNA.
     * Removes the DNA from the registry.
     * @param dnaId The ID of the DNA to burn.
     */
    function burnDNA(uint256 dnaId) external {
        GenerativeDNA storage dna = dnaPool[dnaId];
        if (dna.owner == address(0)) revert DNADoesNotExist(dnaId); // Check if DNA exists
        if (dna.owner != msg.sender) revert NotOwner(dnaId, msg.sender);

        address owner = dna.owner;

        // Clear storage for the DNA
        delete dnaPool[dnaId];

        emit DNABurned(dnaId, owner);
    }


    // --- Viewing & Querying Functions ---

    /**
     * @dev Retrieves the full GenerativeDNA struct for a given ID.
     * @param dnaId The ID of the DNA.
     * @return The GenerativeDNA struct.
     */
    function getDNA(uint256 dnaId) external view returns (GenerativeDNA memory) {
        GenerativeDNA memory dna = dnaPool[dnaId];
        if (dna.owner == address(0) && dnaId != 0) revert DNADoesNotExist(dnaId); // Check if DNA exists (exclude default 0)
        return dna;
    }

    /**
     * @dev Retrieves only the gene array for a given DNA ID.
     * @param dnaId The ID of the DNA.
     * @return The gene array.
     */
    function getDNAGenes(uint256 dnaId) external view returns (uint256[] memory) {
         GenerativeDNA memory dna = dnaPool[dnaId];
        if (dna.owner == address(0) && dnaId != 0) revert DNADoesNotExist(dnaId); // Check if DNA exists
        return dna.genes;
    }

    /**
     * @dev Retrieves the owner of a given DNA ID.
     * @param dnaId The ID of the DNA.
     * @return The owner's address.
     */
    function getDNAOwner(uint256 dnaId) external view returns (address) {
         GenerativeDNA memory dna = dnaPool[dnaId];
        if (dna.owner == address(0) && dnaId != 0) revert DNADoesNotExist(dnaId); // Check if DNA exists
        return dna.owner;
    }

    /**
     * @dev Gets the total number of DNAs that have been minted.
     * @return The total supply.
     */
    function getTotalSupply() external view returns (uint256) {
        return nextDNAId - 1; // nextDNAId is the ID of the *next* token
    }

    /**
     * @dev Gets the current fee required to request a mutation.
     * @return The mutation fee in wei.
     */
    function getMutationFee() external view returns (uint256) {
        return mutationFee;
    }

    /**
     * @dev Gets the minimum time interval (in seconds) required between mutation executions for a DNA.
     * @return The minimum interval in seconds.
     */
    function getMinMutationInterval() external view returns (uint256) {
        return minMutationInterval;
    }

    /**
     * @dev Checks if a mutation request is currently pending for a DNA.
     * @param dnaId The ID of the DNA.
     * @return True if a request is pending, false otherwise.
     */
    function isMutationRequested(uint256 dnaId) external view returns (bool) {
         GenerativeDNA memory dna = dnaPool[dnaId];
        if (dna.owner == address(0) && dnaId != 0) revert DNADoesNotExist(dnaId); // Check if DNA exists
        return dna.mutationRequestTime > 0;
    }

     /**
     * @dev Gets the block timestamp when a mutation was requested for a DNA.
     * Returns 0 if no mutation is currently requested.
     * @param dnaId The ID of the DNA.
     * @return The timestamp of the mutation request.
     */
    function getMutationRequestTime(uint256 dnaId) external view returns (uint256) {
        GenerativeDNA memory dna = dnaPool[dnaId];
        if (dna.owner == address(0) && dnaId != 0) revert DNADoesNotExist(dnaId); // Check if DNA exists
        return dna.mutationRequestTime;
    }

    /**
     * @dev Provides a status summary for a DNA's mutation state.
     * @param dnaId The ID of the DNA.
     * @return A string indicating the status ("Does Not Exist", "Paused", "Not Requested", "Requested, Cooldown Active", "Ready for Execution").
     */
    function getMutationStatus(uint256 dnaId) external view returns (string memory) {
         GenerativeDNA memory dna = dnaPool[dnaId];
        if (dna.owner == address(0) && dnaId != 0) return "Does Not Exist";
        if (paused) return "Paused";

        if (dna.mutationRequestTime == 0) {
            // Not requested, check last execution cooldown
             if (dna.lastMutationBlock > 0 && block.timestamp < dna.lastMutationBlock + minMutationInterval) {
                return "Not Requested (Cooldown Active)";
            }
            return "Not Requested";
        } else {
             // Mutation is requested, check request cooldown
             if (block.timestamp < dna.mutationRequestTime + minMutationInterval) {
                 return "Requested, Cooldown Active";
             }
            return "Ready for Execution";
        }
    }

     /**
     * @dev Allows the owner to store a string hint for off-chain renderers or metadata.
     * @param dnaId The ID of the DNA.
     * @param hint The rendering hint string.
     */
    function setRenderingHint(uint256 dnaId, string calldata hint) external {
        GenerativeDNA storage dna = dnaPool[dnaId];
        if (dna.owner == address(0)) revert DNADoesNotExist(dnaId); // Check if DNA exists
        if (dna.owner != msg.sender) revert NotOwner(dnaId, msg.sender);
        dna.renderingHint = hint;
        emit RenderingHintSet(dnaId, hint);
    }

    /**
     * @dev Retrieves the rendering hint string for a DNA.
     * @param dnaId The ID of the DNA.
     * @return The rendering hint string.
     */
    function getRenderingHint(uint256 dnaId) external view returns (string memory) {
        GenerativeDNA memory dna = dnaPool[dnaId];
        if (dna.owner == address(0) && dnaId != 0) revert DNADoesNotExist(dnaId); // Check if DNA exists
        return dna.renderingHint;
    }


    // --- Admin Functions ---

    /**
     * @dev Allows the admin to withdraw collected mutation fees from the contract balance.
     * @param payableRecipient The address to send the fees to.
     */
    function withdrawFees(address payable payableRecipient) external onlyAdmin {
        uint256 balance = address(this).balance;
        if (balance == 0) revert ZeroAmount();
        if (payableRecipient == address(0)) revert ZeroAddressRecipient();

        (bool success, ) = payableRecipient.call{value: balance}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(payableRecipient, balance);
    }

    /**
     * @dev Allows the current admin to transfer admin rights to a new address.
     * @param newAdmin The address of the new admin.
     */
    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddressRecipient();
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminChanged(oldAdmin, newAdmin);
    }

    // Fallback function to receive ether if needed for fees directly
    receive() external payable {}
    fallback() external payable {}
}
```