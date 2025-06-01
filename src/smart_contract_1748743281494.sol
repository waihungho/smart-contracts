Okay, let's design an advanced smart contract concept that combines NFTs, crafting/alchemy, time-based mechanics, attribute modification, and configurable outcomes without directly replicating existing major open-source projects like basic ERC-721 marketplaces, DAOs, or standard staking contracts.

We'll create an `NFTAlchemyLab` contract. This contract will *also* be an ERC-721 contract for the unique items it produces. Users will be able to combine existing, approved NFTs (and potentially an ERC-20 token "Essence") through a time-locked "alchemy process" to craft new NFTs with specific attributes, or potentially upgrade/mutate existing ones, with outcomes influenced by the input items and potentially external factors (like a defined 'randomness' source).

This involves burning/locking input NFTs, managing process states, calculating outcomes based on complex logic, minting/transferring output NFTs, handling fees/refunds, and allowing owner configuration of the alchemy "formulas".

---

## Smart Contract: NFTAlchemyLab

**Outline:**

1.  **Contract Information:** Pragmas, imports, contract definition (inherits ERC721, Ownable, ReentrancyGuard).
2.  **Errors & Events:** Custom errors for clarity, events for tracking key actions (ProcessStarted, ProcessCompleted, ProcessCancelled, FormulaUpdated, AttributesUpdated, etc.).
3.  **State Variables:**
    *   Basic ERC721 state (`_tokenIds`, `_tokenURIs`, etc.).
    *   Alchemy Process State: `mapping(uint256 => AlchemyProcess)` to store active/completed processes.
    *   Process Counter: `_processCounter` for unique process IDs.
    *   Input Whitelisting: `mapping(address => bool)` for allowed input NFT contracts.
    *   Essence Token: `address` for the required ERC-20 token.
    *   Alchemy Formulas: A mapping to store rules linking inputs to outputs (`mapping(bytes32 => AlchemyFormula)`). Formula key derived from input types/order.
    *   NFT Attributes: `mapping(uint256 => bytes)` to store dynamic attributes of minted NFTs.
    *   Base URI: `string` for metadata.
    *   Cancellation Fee: `uint256` percentage.
    *   Randomness Source (Placeholder): `address` for an external source (e.g., VRF Coordinator).
    *   Reentrancy Guard state.
4.  **Structs:**
    *   `InputItem`: Represents an NFT input (`address nftContract`, `uint256 tokenId`).
    *   `AlchemyProcess`: Details of a crafting process (`user`, `startTime`, `duration`, `InputItem[] inputs`, `uint256 essenceRequired`, `uint256 outputTokenId`, `bool completed`, `bool cancelled`, `bool failed`, `bytes outcomeAttributes`, `uint256 essenceRefundAmount`).
    *   `OutcomeDetails`: Defines what happens on success/failure (e.g., output NFT type, attribute modifiers, refund percentage).
    *   `AlchemyFormula`: Defines the recipe (`InputItem[] requiredInputs`, `uint256 requiredEssence`, `uint256 duration`, `OutcomeDetails outcomeSuccess`, `OutcomeDetails outcomeFailure`).
5.  **Modifiers:**
    *   `onlyAllowedInput(address nftContract)`: Checks if an NFT contract is whitelisted.
    *   `whenProcessIsActive(uint256 processId)`: Checks if a process exists and is not completed/cancelled.
    *   `whenProcessIsReady(uint256 processId)`: Checks if process is active and duration passed.
    *   `whenProcessIsNotCompleted(uint256 processId)`: Checks if process exists and is not completed.
6.  **Constructor:** Initializes ERC721 name/symbol, sets owner.
7.  **ERC721 Implementation:** Basic ERC721 functions (`balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom`, `tokenURI`). `_mint` will be called internally by `completeAlchemyProcess`. `_burn` might be used on input NFTs *or* potentially on output NFTs for re-crafting (though we won't implement re-crafting here for brevity).
8.  **Alchemy Core Functions:**
    *   `startAlchemyProcess`: Initiates a process, takes input NFTs and essence, locks them, records process details.
    *   `completeAlchemyProcess`: Finalizes a process after duration, calculates outcome, mints/transfers output NFT, handles essence.
    *   `cancelAlchemyProcess`: Allows user to cancel an active process (before completion), potentially with a fee.
9.  **Alchemy Configuration Functions (Owner Only):**
    *   `addAllowedInputNFTContract`: Whitelists an external ERC721 contract for use as input.
    *   `removeAllowedInputNFTContract`: Removes a whitelisted contract.
    *   `setEssenceTokenAddress`: Sets the address of the required ERC-20 token.
    *   `setAlchemyFormula`: Defines or updates a crafting recipe based on input items.
    *   `removeAlchemyFormula`: Removes a recipe.
    *   `setBaseURI`: Sets the base URI for minted NFT metadata.
    *   `setCancellationFeePercentage`: Sets the fee for cancelling processes.
    *   `setRandomnessSourceAddress`: Sets the address of a potential external randomness source (e.g., VRF).
10. **Attribute Management Functions:**
    *   `updateNFTAttributes`: Allows updating attributes of *output* NFTs post-minting (e.g., based on successful alchemy, future upgrades).
    *   `getNFTAttributes`: Retrieves stored attributes for an NFT.
11. **Query/View Functions:**
    *   `getAlchemyProcessDetails`: Retrieves the state of a specific process.
    *   `getProcessesByUser`: Retrieves a list of process IDs owned by an address.
    *   `getRequiredEssenceForFormula`: Calculates essence needed for a specific input combination.
    *   `getAlchemyDurationForFormula`: Calculates duration for a specific input combination.
    *   `predictAlchemyOutcome`: Predicts the outcome (success/failure/attributes) for a given input combination *without* starting the process.
    *   `isInputNFTAllowed`: Checks if a specific NFT contract is whitelisted.
    *   `getAllowedInputNFTContracts`: Returns the list of whitelisted contracts (requires iterative state access, potentially gas-heavy, but useful view).
12. **Utility/Admin Functions:**
    *   `withdrawERC20`: Allows owner to withdraw ERC-20 tokens (like collected fees) from the contract.
    *   `withdrawERC721`: Allows owner to rescue ERC-721 tokens mistakenly sent to the contract or stuck.

**Function Summaries (Total: ~35 functions including ERC721 basics):**

*   **ERC721 Standard Functions (12):**
    *   `name()`: Returns the collection name.
    *   `symbol()`: Returns the collection symbol.
    *   `totalSupply()`: Returns the total number of NFTs minted by this contract.
    *   `balanceOf(address owner)`: Returns the number of NFTs owned by an address.
    *   `ownerOf(uint256 tokenId)`: Returns the owner of a specific NFT.
    *   `tokenURI(uint256 tokenId)`: Returns the metadata URI for a specific NFT. (Custom logic to include attributes).
    *   `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific NFT.
    *   `getApproved(uint256 tokenId)`: Returns the approved address for a specific NFT.
    *   `setApprovalForAll(address operator, bool approved)`: Approves or revokes approval for an operator to manage all of sender's NFTs.
    *   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for an owner.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers an NFT (standard, requires owner/approved).
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safer transfer using ERC721Receiver hook. (Overloaded).

*   **Alchemy Core Functions (3):**
    *   `startAlchemyProcess(InputItem[] memory inputItems)`: Initiates a crafting process. Requires user to approve input NFTs and Essence tokens to the contract. The contract pulls the required tokens/NFTs and locks them for a set duration based on the determined formula. Records process state. *Creative/Advanced: Handles multiple input NFT types, requires ERC-20 alongside NFTs, time-locked process.*
    *   `completeAlchemyProcess(uint256 processId)`: Callable by anyone *after* the process duration has passed. Calculates the outcome (success/failure) based on the formula and potentially randomness. Mints the resulting NFT (with determined attributes), transfers it to the process owner, and handles any essence refunds or penalties. Burns input NFTs. *Creative/Advanced: Time-locked finalization, outcome calculation based on complex internal rules, dynamic NFT attribute assignment upon minting.*
    *   `cancelAlchemyProcess(uint256 processId)`: Allows the process owner to cancel an active process *before* completion. Returns the input NFTs and a percentage of the required essence, minus a configured cancellation fee. Burns the locked items/essence according to rules. *Creative/Advanced: State-dependent action, applies a configurable penalty/fee.*

*   **Alchemy Configuration Functions (Owner Only) (7):**
    *   `addAllowedInputNFTContract(address nftContract)`: Whitelists an external ERC721 contract address, allowing its NFTs to be used as inputs in alchemy. *Advanced: Interacts with external contracts, controlled access.*
    *   `removeAllowedInputNFTContract(address nftContract)`: Removes an address from the whitelist.
    *   `setEssenceTokenAddress(address essenceTokenAddress)`: Sets the address of the ERC-20 token required for crafting. *Advanced: Linkage to external token contract.*
    *   `setAlchemyFormula(InputItem[] memory inputPattern, uint256 requiredEssence, uint256 duration, OutcomeDetails memory outcomeSuccess, OutcomeDetails memory outcomeFailure)`: Defines or updates a specific crafting recipe. The `inputPattern` determines the `bytes32` formula key. *Creative/Advanced: Configurable complex recipes, mapping specific input *combinations* to unique outcomes, defines success/failure states including attribute modifications and refunds.*
    *   `removeAlchemyFormula(InputItem[] memory inputPattern)`: Removes a defined formula.
    *   `setBaseURI(string memory newBaseURI)`: Sets the base URI for token metadata, common for IPFS.
    *   `setCancellationFeePercentage(uint256 percentage)`: Sets the percentage of essence retained by the contract when a process is cancelled (0-100).

*   **Attribute Management Functions (2):**
    *   `updateNFTAttributes(uint256 tokenId, bytes memory encodedAttributes)`: Allows the owner (or potentially other authorized roles based on the system) to modify the on-chain attributes associated with a specific NFT minted by this contract *after* it has been created. *Creative/Advanced: Dynamic NFT properties post-minting, stored on-chain (using `bytes` for flexibility).*
    *   `getNFTAttributes(uint256 tokenId)`: Retrieves the stored on-chain attributes for a specific NFT. Returns raw `bytes`.

*   **Query/View Functions (6):**
    *   `getAlchemyProcessDetails(uint256 processId)`: Returns all stored details for a specific alchemy process.
    *   `getProcessesByUser(address user)`: Returns an array of process IDs associated with a specific user. (Requires iterating, might be gas-heavy if many processes per user, common limitation for on-chain arrays).
    *   `getRequiredEssenceForFormula(InputItem[] memory inputItems)`: Calculates and returns the amount of Essence token needed for a given set of input items based on defined formulas.
    *   `getAlchemyDurationForFormula(InputItem[] memory inputItems)`: Calculates and returns the time duration for a given set of input items based on defined formulas.
    *   `predictAlchemyOutcome(InputItem[] memory inputItems)`: Simulates the `_calculateOutcome` logic and returns the *predicted* outcome details (success/failure, potential attributes, refund) *without* starting a process. Useful for UI/users planning crafts. *Creative/Advanced: On-chain simulation/prediction for user planning.*
    *   `isInputNFTAllowed(address nftContract)`: Checks if a specific NFT contract is currently whitelisted.

*   **Advanced Interaction / Utility (2):**
    *   `delegateAlchemyPermission(address delegatee, bool authorized)`: Allows an owner of NFTs/tokens to authorize another address (a delegatee) to call `startAlchemyProcess` *on their behalf*, using the delegator's assets (requires delegatee to use `approve` on the delegator's NFTs/tokens towards the contract, or the delegator to `setApprovalForAll`). *Creative/Advanced: Custom delegation logic beyond standard ERC-721 approval.*
    *   `setRandomnessSourceAddress(address randomnessSource)`: Sets the address of a contract that provides external randomness (e.g., a Chainlink VRF coordinator). This address would be called internally by `_calculateOutcome` to introduce unpredictability. *Advanced: Pattern for integrating external oracle/randomness sources.*

*   **Admin/Withdrawal Functions (2):**
    *   `withdrawERC20(address tokenAddress, uint256 amount)`: Allows the contract owner to withdraw any ERC-20 tokens held by the contract (useful for withdrawing collected essence fees).
    *   `withdrawERC721(address nftContractAddress, uint256 tokenId)`: Allows the contract owner to withdraw any ERC-721 token held by the contract (useful for rescuing inputs from cancelled processes if needed, or any accidentally sent NFTs).

*   **Internal Helper Functions (Not counted in the 20+):**
    *   `_mintNFTWithAttributes`: Handles the actual minting and attribute assignment.
    *   `_burnNFT`: Handles burning input NFTs.
    *   `_getFormulaHash`: Calculates a unique hash for an input pattern to look up formulas. *Advanced: Deterministic key generation for complex inputs.*
    *   `_calculateOutcome`: Core logic for determining the result of an alchemy process based on formula and potentially randomness. *Advanced: Contains the core game logic.*
    *   `_pullInputs`: Handles transferring input NFTs and Essence tokens from the user to the contract.
    *   `_returnInputs`: Handles returning NFTs/Essence on cancel/failure.

---

Here is the Solidity code for the `NFTAlchemyLab`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // Example of another utility

// Minimal interface for an external randomness source (e.g., a simplified VRF Coordinator)
interface IRandomnessSource {
    // Example function - a real VRF would have request/receive patterns
    function getRandomNumber(uint256 seed) external view returns (uint256);
}


/**
 * @title NFTAlchemyLab
 * @dev An advanced smart contract combining ERC721 NFTs, time-locked crafting,
 * configurable formulas, dynamic attributes, and token requirements.
 * Users can combine whitelisted input NFTs and Essence tokens to start a timed
 * alchemy process which burns inputs and yields new NFTs minted by this contract,
 * with outcomes determined by input combinations and potentially randomness.
 */
contract NFTAlchemyLab is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeERC721 for IERC721;
    using SafeERC20 for IERC20; // For safe token transfers

    // --- Errors ---
    error InvalidInputNFTContract(address nftContract);
    error InputsNotApprovedOrBalanceTooLow();
    error FormulaNotFound();
    error ProcessNotFound();
    error ProcessNotActive();
    error ProcessNotReadyToComplete();
    error ProcessAlreadyCompleted();
    error ProcessAlreadyCancelled();
    error ProcessOwnerOnly();
    error InvalidCancellationFee();
    error ZeroAddressNotAllowed();
    error ERC20TransferFailed();
    error ERC721TransferFailed();
    error BatchLengthMismatch();

    // --- Events ---
    event AlchemyProcessStarted(uint256 indexed processId, address indexed user, InputItem[] inputItems, uint256 essenceRequired, uint256 duration);
    event AlchemyProcessCompleted(uint256 indexed processId, address indexed user, uint256 indexed outputTokenId, bool success, bytes outcomeAttributes, uint256 essenceRefunded);
    event AlchemyProcessCancelled(uint256 indexed processId, address indexed user, uint256 essenceReturned, uint256 cancellationFeePaid);
    event FormulaSet(bytes32 indexed formulaHash, InputItem[] inputPattern);
    event FormulaRemoved(bytes32 indexed formulaHash);
    event InputNFTContractWhitelisted(address indexed nftContract);
    event InputNFTContractRemoved(address indexed nftContract);
    event EssenceTokenSet(address indexed essenceToken);
    event NFTAttributesUpdated(uint256 indexed tokenId, bytes encodedAttributes);
    event CancellationFeeSet(uint256 percentage);
    event RandomnessSourceSet(address indexed randomnessSource);
    event AlchemyPermissionDelegated(address indexed delegator, address indexed delegatee, bool authorized);

    // --- Structs ---

    struct InputItem {
        address nftContract;
        uint256 tokenId;
    }

    // Defines the result of an alchemy attempt
    struct OutcomeDetails {
        enum OutcomeType { Success, Failure, PartialSuccess } // Success = intended output, Failure = minimal/nothing, Partial = less than intended
        OutcomeType outcomeType;
        // Template for output NFT (if applicable). Address is this contract for new mints,
        // or another contract for transformation (not fully implemented here for simplicity).
        address outputNFTContractTemplate;
        // Can use this as a base token ID or property to determine metadata/type
        uint256 outputTokenIdTemplate;
        bytes successAttributes; // Encoded attributes on success
        bytes failureAttributes; // Encoded attributes on failure/partial
        uint256 essenceRefundPercentage; // Percentage of required essence to refund on *this* outcome type
    }

    // Defines a crafting recipe
    struct AlchemyFormula {
        InputItem[] requiredInputs; // Specific combination of NFTs (contract + ID or just contract)
        uint256 requiredEssence; // Amount of Essence token needed
        uint256 duration; // Time required for the process
        OutcomeDetails outcomeSuccess; // Details if process is successful
        OutcomeDetails outcomeFailure; // Details if process fails/partial success (can be same struct)
    }

    // Details of an active or completed alchemy process
    struct AlchemyProcess {
        address user; // Who initiated the process
        uint256 startTime; // When it started
        uint256 duration; // How long it takes
        InputItem[] inputs; // The exact NFTs used
        uint256 essenceRequired; // Essence used
        bytes32 formulaUsed; // Hash of the formula used
        uint256 outputTokenId; // Token ID of the resulting NFT (if successful)
        bool completed; // True if finalized
        bool cancelled; // True if user cancelled
        bool failed; // True if the outcome was failure
        bytes outcomeAttributes; // The final attributes of the output NFT
        uint256 essenceRefundAmount; // Actual essence amount refunded/to be refunded
    }

    // --- State Variables ---

    // Standard ERC721 token counter for NFTs minted by this contract
    Counters.Counter private _nextTokenId;
    // Mapping to store dynamic NFT attributes
    mapping(uint256 => bytes) private _tokenAttributes;
    // Base URI for metadata
    string private _baseTokenURI;

    // Counter for unique alchemy process IDs
    Counters.Counter private _processCounter;
    // Store details for each alchemy process
    mapping(uint256 => AlchemyProcess) private _alchemyProcesses;
    // Mapping to quickly check processes by user (stores processIds, potential gas issue for large arrays)
    mapping(address => uint256[]) private _userProcesses; // Store IDs for lookup

    // Whitelist of ERC721 contracts allowed as input materials
    mapping(address => bool) private _allowedInputNFTContracts;
    // List of allowed input NFT contracts (for view function, iterative)
    address[] private _allowedInputNFTContractsList;

    // Address of the ERC-20 token required for alchemy (Essence)
    address private _essenceToken;

    // Mapping from formula hash (derived from input pattern) to formula details
    mapping(bytes32 => AlchemyFormula) private _alchemyFormulas;

    // Percentage of essence retained by contract on cancellation (0-100)
    uint256 private _cancellationFeePercentage;

    // Address of an external contract providing randomness (e.g., Chainlink VRF Coordinator)
    address private _randomnessSource;

    // Delegation mapping: delegator => delegatee => authorized status
    mapping(address => mapping(address => bool)) private _alchemyDelegates;


    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) ReentrancyGuard() {}

    // --- Modifiers ---

    modifier onlyAllowedInput(address nftContract) {
        if (!_allowedInputNFTContracts[nftContract]) {
            revert InvalidInputNFTContract(nftContract);
        }
        _;
    }

    modifier whenProcessIsActive(uint256 processId) {
        AlchemyProcess storage process = _alchemyProcesses[processId];
        if (process.user == address(0)) revert ProcessNotFound();
        if (process.completed) revert ProcessAlreadyCompleted();
        if (process.cancelled) revert ProcessAlreadyCancelled();
        _;
    }

    modifier whenProcessIsReady(uint256 processId) {
        whenProcessIsActive(processId);
        AlchemyProcess storage process = _alchemyProcesses[processId];
        if (block.timestamp < process.startTime + process.duration) revert ProcessNotReadyToComplete();
        _;
    }

    modifier whenProcessIsNotCompleted(uint256 processId) {
        AlchemyProcess storage process = _alchemyProcesses[processId];
        if (process.user == address(0)) revert ProcessNotFound(); // Ensure process exists
        if (process.completed) revert ProcessAlreadyCompleted();
        _;
    }

    // --- ERC721 Functions (Implementation / Overrides) ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists
        string memory base = _baseTokenURI;
        // In a real application, you'd fetch metadata from a service,
        // potentially including the on-chain attributes from _tokenAttributes.
        // For this example, we just append the token ID to a base URI.
        // A metadata service would read token ID and call getNFTAttributes(tokenId)
        // to include dynamic properties.
        return bytes(base).length > 0 ? string(abi.encodePacked(base, _toString(tokenId))) : "";
    }

    // Standard ERC721 functions like balanceOf, ownerOf, approve, getApproved,
    // setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom are inherited
    // from OpenZeppelin and work automatically with the internal _owners, _balances, etc.
    // mappings managed by _mint and _burn (which are called internally).
    // ERC721Enumerable's tokenOfOwnerByIndex, tokenByIndex are not included to keep it simpler
    // and avoid potential gas costs of large on-chain arrays.

    // --- Alchemy Core Functions ---

    /**
     * @dev Starts an alchemy process by consuming input NFTs and Essence tokens.
     * Requires the caller to have approved the contract for the input NFTs and Essence tokens.
     * Finds the relevant formula and records the process details.
     * @param inputItems Array of InputItem structs representing the NFTs to use.
     */
    function startAlchemyProcess(InputItem[] memory inputItems) external nonReentrant {
        if (_essenceToken == address(0)) revert ZeroAddressNotAllowed(); // Essence token must be set

        // 1. Validate inputs against allowed contracts
        for (uint i = 0; i < inputItems.length; i++) {
            if (!_allowedInputNFTContracts[inputItems[i].nftContract]) {
                revert InvalidInputNFTContract(inputItems[i].nftContract);
            }
        }

        // 2. Determine formula based on inputs
        // NOTE: This is a simplified hashing. A real system might require inputs in a specific order,
        // or use more complex logic based on NFT traits (which aren't stored here for inputs).
        // This hash is sensitive to the order of items in the array.
        bytes32 formulaHash = _getFormulaHash(inputItems);
        AlchemyFormula storage formula = _alchemyFormulas[formulaHash];
        if (formula.duration == 0 && formula.requiredEssence == 0 && formula.requiredInputs.length == 0) {
             revert FormulaNotFound();
        }

        // 3. Check if user has enough Essence and approved the transfer
        // We don't check formula.requiredEssence here, the formula check implies it.
        // The formula *must* define required essence.
        if (IERC20(_essenceToken).balanceOf(msg.sender) < formula.requiredEssence) {
            revert InputsNotApprovedOrBalanceTooLow(); // Or insufficient balance
        }
        // Safe transferFrom handles allowance check
        IERC20(_essenceToken).safeTransferFrom(msg.sender, address(this), formula.requiredEssence);


        // 4. Check if user owns input NFTs and approved the transfer
        // Also burn or transfer inputs to the contract
        for (uint i = 0; i < inputItems.length; i++) {
            address nftContract = inputItems[i].nftContract;
            uint256 tokenId = inputItems[i].tokenId;

            // Check ownership - SafeTransferFrom handles approval check
            IERC721 inputNFT = IERC721(nftContract);
            if (inputNFT.ownerOf(tokenId) != msg.sender && !inputNFT.isApprovedForAll(msg.sender, address(this)) && inputNFT.getApproved(tokenId) != address(this)) {
                 // Also check delegation - is caller authorized to act for owner?
                 address nftOwner = inputNFT.ownerOf(tokenId);
                 if (nftOwner != msg.sender && !_alchemyDelegates[nftOwner][msg.sender]) {
                     revert InputsNotApprovedOrBalanceTooLow(); // Ownership or approval/delegation missing
                 }
                 // If delegated, the *delegatee* (msg.sender) must have been approved by the *owner* (nftOwner)
                 // This relies on standard ERC721 approvals by the actual owner.
                 if (inputNFT.ownerOf(tokenId) != msg.sender && !inputNFT.isApprovedForAll(nftOwner, address(this)) && inputNFT.getApproved(tokenId) != address(this)) {
                     revert InputsNotApprovedOrBalanceTooLow(); // Delegation active, but owner hasn't approved contract
                 }
            }


            // Transfer NFT to contract or burn directly if protocol requires.
            // For this lab, let's transfer to the contract, marking them as 'locked'
            // within the process struct, and burn them only on successful completion.
            // This allows refunding on cancellation.
             // Note: SafeTransferFrom checks approval/ownership. If delegated, it needs owner approval.
            IERC721(nftContract).safeTransferFrom(inputNFT.ownerOf(tokenId), address(this), tokenId);
        }

        // 5. Record the alchemy process
        uint256 processId = _processCounter.current();
        _alchemyProcesses[processId] = AlchemyProcess({
            user: msg.sender,
            startTime: block.timestamp,
            duration: formula.duration,
            inputs: inputItems,
            essenceRequired: formula.requiredEssence,
            formulaUsed: formulaHash,
            outputTokenId: 0, // Will be set on completion if successful
            completed: false,
            cancelled: false,
            failed: false,
            outcomeAttributes: "", // Will be set on completion
            essenceRefundAmount: 0 // Will be set on completion/cancellation
        });

        _userProcesses[msg.sender].push(processId); // Add process ID to user's list

        _processCounter.increment();

        emit AlchemyProcessStarted(processId, msg.sender, inputItems, formula.requiredEssence, formula.duration);
    }

    /**
     * @dev Completes an alchemy process after its duration has passed.
     * Calculates the outcome, mints/transfers the output NFT (if successful),
     * handles burning input NFTs, and manages essence refunds.
     * Callable by anyone to finalize, but results go to the process owner.
     * @param processId The ID of the alchemy process to complete.
     */
    function completeAlchemyProcess(uint256 processId) external nonReentrant whenProcessIsReady(processId) {
        AlchemyProcess storage process = _alchemyProcesses[processId];
        AlchemyFormula storage formula = _alchemyFormulas[process.formulaUsed];

        // Ensure formula exists (should exist if process started)
        if (formula.duration == 0 && formula.requiredEssence == 0 && formula.requiredInputs.length == 0) {
             revert FormulaNotFound(); // Should not happen if start was successful
        }

        // 1. Calculate Outcome (Success/Failure)
        OutcomeDetails memory finalOutcome = _calculateOutcome(processId, formula.outcomeSuccess, formula.outcomeFailure);
        process.failed = (finalOutcome.outcomeType != OutcomeDetails.OutcomeType.Success);
        process.outcomeAttributes = finalOutcome.outcomeType == OutcomeDetails.OutcomeType.Success ? finalOutcome.successAttributes : finalOutcome.failureAttributes;
        process.essenceRefundAmount = (process.essenceRequired * finalOutcome.essenceRefundPercentage) / 100;

        // 2. Handle Output
        if (finalOutcome.outcomeType == OutcomeDetails.OutcomeType.Success) {
            // Mint a new NFT from this contract collection
            uint256 newTokenId = _nextTokenId.current();
            _nextTokenId.increment();

            // Mint the new NFT to the process owner
            _mint(process.user, newTokenId);
            _setTokenAttributes(newTokenId, process.outcomeAttributes); // Assign attributes
            process.outputTokenId = newTokenId; // Record the output token ID

        } else {
            // On failure or partial success, no new NFT is minted.
            // The outcome attributes could represent a "failed item" or similar.
            process.outputTokenId = 0; // Indicate no token minted
        }

        // 3. Burn Input NFTs
        for (uint i = 0; i < process.inputs.length; i++) {
             // Burn the NFT that was transferred to the contract
            IERC721(process.inputs[i].nftContract).safeTransferFrom(address(this), address(0), process.inputs[i].tokenId);
        }

        // 4. Refund Essence (if any)
        if (process.essenceRefundAmount > 0) {
             IERC20(_essenceToken).safeTransfer(process.user, process.essenceRefundAmount);
        }

        // 5. Mark process as completed
        process.completed = true;

        emit AlchemyProcessCompleted(
            processId,
            process.user,
            process.outputTokenId,
            !process.failed, // success is !failed
            process.outcomeAttributes,
            process.essenceRefundAmount
        );
    }

    /**
     * @dev Allows the process owner to cancel an active alchemy process before completion.
     * Burns input NFTs and refunds a percentage of the essence, minus a fee.
     * @param processId The ID of the alchemy process to cancel.
     */
    function cancelAlchemyProcess(uint256 processId) external nonReentrant whenProcessIsActive(processId) {
        AlchemyProcess storage process = _alchemyProcesses[processId];

        // Only process owner can cancel
        if (process.user != msg.sender) revert ProcessOwnerOnly();

        // 1. Calculate refund amount
        uint256 refundPercentage = 100 - _cancellationFeePercentage;
        uint256 essenceRefund = (process.essenceRequired * refundPercentage) / 100;
        uint256 cancellationFee = process.essenceRequired - essenceRefund;

        // 2. Burn Input NFTs
        for (uint i = 0; i < process.inputs.length; i++) {
            // Burn the NFT that was transferred to the contract
            IERC721(process.inputs[i].nftContract).safeTransferFrom(address(this), address(0), process.inputs[i].tokenId);
        }

        // 3. Refund Essence
        if (essenceRefund > 0) {
            IERC20(_essenceToken).safeTransfer(process.user, essenceRefund);
        }

        // 4. Mark process as cancelled
        process.cancelled = true;
        process.essenceRefundAmount = essenceRefund; // Record refunded amount

        emit AlchemyProcessCancelled(processId, msg.sender, essenceRefund, cancellationFee);
    }

    // --- Alchemy Configuration Functions (Owner Only) ---

    /**
     * @dev Whitelists an external ERC721 contract to be used as input materials.
     * Only callable by the owner.
     * @param nftContract The address of the ERC721 contract to whitelist.
     */
    function addAllowedInputNFTContract(address nftContract) external onlyOwner {
        if (nftContract == address(0)) revert ZeroAddressNotAllowed();
        if (!_allowedInputNFTContracts[nftContract]) {
            _allowedInputNFTContracts[nftContract] = true;
            _allowedInputNFTContractsList.push(nftContract); // Add to list for view function
            emit InputNFTContractWhitelisted(nftContract);
        }
    }

     /**
     * @dev Removes an external ERC721 contract from the whitelist.
     * Only callable by the owner. Does NOT affect ongoing processes using NFTs from this contract.
     * @param nftContract The address of the ERC721 contract to remove.
     */
    function removeAllowedInputNFTContract(address nftContract) external onlyOwner {
        if (_allowedInputNFTContracts[nftContract]) {
            _allowedInputNFTContracts[nftContract] = false;
            // Remove from list - potentially inefficient for large lists
            for(uint i = 0; i < _allowedInputNFTContractsList.length; i++) {
                if (_allowedInputNFTContractsList[i] == nftContract) {
                    _allowedInputNFTContractsList[i] = _allowedInputNFTContractsList[_allowedInputNFTContractsList.length - 1];
                    _allowedInputNFTContractsList.pop();
                    break;
                }
            }
            emit InputNFTContractRemoved(nftContract);
        }
    }

    /**
     * @dev Sets the address of the ERC-20 token required for alchemy.
     * Only callable by the owner. Must be set before alchemy can start.
     * @param essenceTokenAddress The address of the Essence ERC-20 token.
     */
    function setEssenceTokenAddress(address essenceTokenAddress) external onlyOwner {
        if (essenceTokenAddress == address(0)) revert ZeroAddressNotAllowed();
        _essenceToken = essenceTokenAddress;
        emit EssenceTokenSet(essenceTokenAddress);
    }

    /**
     * @dev Defines or updates a crafting formula.
     * The formula key is derived from the input pattern hash.
     * Only callable by the owner.
     * @param inputPattern Array defining the specific combination of input NFTs.
     * @param requiredEssence Amount of Essence token needed for this formula.
     * @param duration Time in seconds the process takes.
     * @param outcomeSuccess Details for a successful outcome.
     * @param outcomeFailure Details for a failed/partial outcome.
     */
    function setAlchemyFormula(
        InputItem[] memory inputPattern,
        uint256 requiredEssence,
        uint256 duration,
        OutcomeDetails memory outcomeSuccess,
        OutcomeDetails memory outcomeFailure
    ) external onlyOwner {
        // Basic validation (can add more complex checks)
        if (inputPattern.length == 0) revert FormulaNotFound(); // Require at least one input

        bytes32 formulaHash = _getFormulaHash(inputPattern);
        _alchemyFormulas[formulaHash] = AlchemyFormula({
            requiredInputs: inputPattern, // Storing pattern might be gas-heavy for complex patterns
            requiredEssence: requiredEssence,
            duration: duration,
            outcomeSuccess: outcomeSuccess,
            outcomeFailure: outcomeFailure
        });

        emit FormulaSet(formulaHash, inputPattern);
    }

    /**
     * @dev Removes a defined crafting formula.
     * Only callable by the owner. Does NOT affect ongoing processes using this formula.
     * @param inputPattern Array defining the input combination for the formula key.
     */
    function removeAlchemyFormula(InputItem[] memory inputPattern) external onlyOwner {
        bytes32 formulaHash = _getFormulaHash(inputPattern);
        // Check if formula exists before deleting
        if (_alchemyFormulas[formulaHash].duration == 0 && _alchemyFormulas[formulaHash].requiredEssence == 0 && _alchemyFormulas[formulaHash].requiredInputs.length == 0) {
             revert FormulaNotFound();
        }
        delete _alchemyFormulas[formulaHash];
        emit FormulaRemoved(formulaHash);
    }

     /**
     * @dev Sets the base URI for token metadata.
     * Appended with token ID to get full metadata URI.
     * Only callable by the owner.
     * @param newBaseURI The new base URI string.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

     /**
     * @dev Sets the percentage of Essence token retained by the contract
     * if a user cancels an alchemy process.
     * Only callable by the owner.
     * @param percentage The fee percentage (0-100).
     */
    function setCancellationFeePercentage(uint256 percentage) external onlyOwner {
        if (percentage > 100) revert InvalidCancellationFee();
        _cancellationFeePercentage = percentage;
        emit CancellationFeeSet(percentage);
    }

    /**
     * @dev Sets the address of an external contract to be used as a randomness source.
     * This contract should implement a function like `getRandomNumber(uint256 seed)`.
     * Only callable by the owner.
     * @param randomnessSource The address of the randomness source contract.
     */
    function setRandomnessSourceAddress(address randomnessSource) external onlyOwner {
        // Optional: Add interface check if needed: `require(randomnessSource.code.length > 0, "Not a contract");`
        _randomnessSource = randomnessSource;
        emit RandomnessSourceSet(randomnessSource);
    }

    // --- Attribute Management Functions ---

    /**
     * @dev Updates the custom on-chain attributes for a specific NFT minted by this contract.
     * Can be used to reflect changes based on alchemy outcomes or other game logic.
     * Only callable by the owner (can extend to specific roles if needed).
     * @param tokenId The ID of the NFT.
     * @param encodedAttributes The attributes encoded as bytes (interpretation is off-chain).
     */
    function updateNFTAttributes(uint256 tokenId, bytes memory encodedAttributes) external onlyOwner {
        // Basic check if token exists and is minted by this contract
        _requireOwned(tokenId);
        _setTokenAttributes(tokenId, encodedAttributes);
        emit NFTAttributesUpdated(tokenId, encodedAttributes);
    }

     /**
     * @dev Retrieves the custom on-chain attributes for a specific NFT.
     * @param tokenId The ID of the NFT.
     * @return bytes The encoded attributes.
     */
    function getNFTAttributes(uint256 tokenId) external view returns (bytes memory) {
        _requireOwned(tokenId); // Ensure token exists
        return _tokenAttributes[tokenId];
    }

    // Internal helper to set attributes
    function _setTokenAttributes(uint256 tokenId, bytes memory encodedAttributes) internal {
         _tokenAttributes[tokenId] = encodedAttributes;
         // Note: tokenURI does not automatically reflect this change.
         // A metadata service listening to the NFTAttributesUpdated event
         // would need to provide the updated metadata JSON.
    }

    // --- Query/View Functions ---

    /**
     * @dev Retrieves details for a specific alchemy process.
     * @param processId The ID of the process.
     * @return AlchemyProcess Struct containing all process details.
     */
    function getAlchemyProcessDetails(uint256 processId) external view returns (AlchemyProcess memory) {
        AlchemyProcess storage process = _alchemyProcesses[processId];
        if (process.user == address(0)) revert ProcessNotFound();
        return process;
    }

    /**
     * @dev Retrieves a list of process IDs initiated by a specific user.
     * Note: Could be gas-heavy for users with many processes.
     * @param user The address of the user.
     * @return uint256[] An array of process IDs.
     */
    function getProcessesByUser(address user) external view returns (uint256[] memory) {
        return _userProcesses[user];
    }

    /**
     * @dev Calculates the required Essence for a given set of input items
     * based on defined formulas.
     * @param inputItems Array of InputItem structs.
     * @return uint256 Required Essence amount.
     */
    function getRequiredEssenceForFormula(InputItem[] memory inputItems) external view returns (uint256) {
         bytes32 formulaHash = _getFormulaHash(inputItems);
         AlchemyFormula storage formula = _alchemyFormulas[formulaHash];
         if (formula.duration == 0 && formula.requiredEssence == 0 && formula.requiredInputs.length == 0) {
              revert FormulaNotFound();
         }
         return formula.requiredEssence;
    }

    /**
     * @dev Calculates the duration for a given set of input items based on formulas.
     * @param inputItems Array of InputItem structs.
     * @return uint256 Duration in seconds.
     */
    function getAlchemyDurationForFormula(InputItem[] memory inputItems) external view returns (uint256) {
         bytes32 formulaHash = _getFormulaHash(inputItems);
         AlchemyFormula storage formula = _alchemyFormulas[formulaHash];
          if (formula.duration == 0 && formula.requiredEssence == 0 && formula.requiredInputs.length == 0) {
              revert FormulaNotFound();
         }
         return formula.duration;
    }

    /**
     * @dev Predicts the outcome (success/failure details, attributes, refund)
     * for a given set of input items *without* starting the process.
     * Uses the same logic as `_calculateOutcome`.
     * @param inputItems Array of InputItem structs.
     * @return OutcomeDetails Predicted outcome details (can be success or failure outcome struct).
     */
    function predictAlchemyOutcome(InputItem[] memory inputItems) external view returns (OutcomeDetails memory) {
        bytes32 formulaHash = _getFormulaHash(inputItems);
        AlchemyFormula storage formula = _alchemyFormulas[formulaHash];
         if (formula.duration == 0 && formula.requiredEssence == 0 && formula.requiredInputs.length == 0) {
              revert FormulaNotFound();
         }
        // Simulate outcome calculation. We use a dummy process ID and timestamp.
        // The actual outcome logic would need to be re-run, ideally using a specific
        // seed or block info relevant to *this* view call, not a future block.
        // For true prediction, randomness should be deterministic or user-provided for simulation.
        // Here, we'll just return the SUCCESS outcome struct from the formula for simplicity in prediction,
        // implying the formula *defines* the potential outcomes, but the actual random choice
        // happens on complete. A more complex version would take a seed.
        return formula.outcomeSuccess; // Simplified prediction: just show the success outcome possibility.
                                      // True prediction of a random event isn't possible client-side without the seed.
    }


    /**
     * @dev Checks if a specific NFT contract address is currently whitelisted as an input.
     * @param nftContract The address of the NFT contract.
     * @return bool True if whitelisted, false otherwise.
     */
    function isInputNFTAllowed(address nftContract) external view returns (bool) {
        return _allowedInputNFTContracts[nftContract];
    }

     /**
     * @dev Returns the list of all currently whitelisted input NFT contract addresses.
     * Note: Could be gas-heavy if many contracts are whitelisted.
     * @return address[] An array of whitelisted addresses.
     */
    function getAllowedInputNFTContracts() external view returns (address[] memory) {
        return _allowedInputNFTContractsList;
    }


    // --- Advanced Interaction / Utility ---

     /**
     * @dev Allows a user (the delegator) to authorize another address (delegatee)
     * to start alchemy processes on their behalf, using the delegator's assets.
     * Note: The delegatee still needs standard ERC721/ERC20 approvals from the delegator
     * for the specific assets they will use in the alchemy process. This function
     * just allows the delegatee to *call* startAlchemyProcess with the delegator's intent.
     * @param delegatee The address to grant or revoke permission to.
     * @param authorized True to authorize, false to revoke.
     */
    function delegateAlchemyPermission(address delegatee, bool authorized) external {
        if (delegatee == address(0)) revert ZeroAddressNotAllowed();
        _alchemyDelegates[msg.sender][delegatee] = authorized;
        emit AlchemyPermissionDelegated(msg.sender, delegatee, authorized);
    }

    /**
     * @dev Allows a user to start multiple alchemy processes in a single transaction.
     * Each tuple in the array represents the inputs for one process.
     * Requires approvals for all inputs across all processes.
     * @param processes An array of input item arrays, one for each process to start.
     */
    function batchStartAlchemy(InputItem[][] memory processes) external nonReentrant {
        for (uint i = 0; i < processes.length; i++) {
            // Call the single start function for each process definition.
            // This relies on the single startAlchemyProcess function handling approvals and logic.
            // Note: The nonReentrant guard on startAlchemyProcess prevents reentrancy issues
            // between batch items, but means each start will block the next until transfers complete.
            // A more gas-optimized batch might combine all transfers upfront, but is more complex.
            startAlchemyProcess(processes[i]);
        }
    }


    // --- Admin/Withdrawal Functions ---

    /**
     * @dev Allows the contract owner to withdraw any ERC-20 tokens held by the contract.
     * Useful for withdrawing collected cancellation fees or accidentally sent tokens.
     * @param tokenAddress The address of the ERC-20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        if (tokenAddress == address(0)) revert ZeroAddressNotAllowed();
        IERC20 token = IERC20(tokenAddress);
        if (token.balanceOf(address(this)) < amount) revert ERC20TransferFailed(); // Or insufficient balance error
        token.safeTransfer(owner(), amount);
    }

     /**
     * @dev Allows the contract owner to withdraw any ERC-721 token held by the contract.
     * Useful for rescuing inputs from cancelled/stuck processes or accidentally sent NFTs.
     * @param nftContractAddress The address of the ERC-721 token contract.
     * @param tokenId The ID of the token to withdraw.
     */
    function withdrawERC721(address nftContractAddress, uint256 tokenId) external onlyOwner nonReentrant {
         if (nftContractAddress == address(0)) revert ZeroAddressNotAllowed();
         IERC721 token = IERC721(nftContractAddress);
         // Check if contract owns the token
         if (token.ownerOf(tokenId) != address(this)) revert ERC721TransferFailed(); // Or not owned error
         token.safeTransferFrom(address(this), owner(), tokenId);
     }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to calculate a deterministic hash for a given input pattern.
     * Used as the key for the alchemyFormulas mapping. Order-sensitive.
     * @param inputItems Array of InputItem structs.
     * @return bytes32 The Keccak-256 hash of the encoded input items.
     */
    function _getFormulaHash(InputItem[] memory inputItems) internal pure returns (bytes32) {
        // Encode input items deterministically. Order matters.
        // abi.encodePacked is efficient but sensitive to packing rules;
        // abi.encode is safer regarding future solidity changes, but might be slightly more expensive.
        // Using abi.encodePacked here for potential gas saving assuming fixed struct layout.
        bytes memory encoded = abi.encodePacked(inputItems);
        return keccak256(encoded);
    }

    /**
     * @dev Internal function to calculate the outcome of an alchemy process.
     * Deterministic based on process ID and formula, potentially influenced by an external randomness source.
     * @param processId The ID of the process.
     * @param outcomeSuccess Details for the success outcome.
     * @param outcomeFailure Details for the failure outcome.
     * @return OutcomeDetails The final outcome details (success or failure struct from formula).
     */
    function _calculateOutcome(uint256 processId, OutcomeDetails memory outcomeSuccess, OutcomeDetails memory outcomeFailure) internal view returns (OutcomeDetails memory) {
        // This is where complex outcome logic would live.
        // Factors could include:
        // - Properties of the input NFTs (if stored/accessible)
        // - Block hash (pseudo-random, discouraged for security-critical outcomes)
        // - External randomness source (recommended for unbiased randomness)
        // - Time of day/block number (less common)
        // - A hardcoded probability based on the formula
        // - Success based on matching *exact* requiredInputs vs provided inputs (not just hash)

        // Example simplified logic: 80% chance success, 20% chance failure, or use external randomness if set.
        uint256 randomNumber;

        if (_randomnessSource != address(0)) {
             // Use external randomness source - requires this contract to trust the source
             // A real VRF integration is async and more complex (request/fulfill).
             // This example calls a synchronous view function pattern.
             try IRandomnessSource(_randomnessSource).getRandomNumber(processId) returns (uint256 randomValue) {
                 randomNumber = randomValue;
             } catch {
                 // Fallback or revert if randomness source fails
                 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, processId))); // Fallback pseudo-random
             }
        } else {
             // Use fallback pseudo-randomness if no source set
             randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, processId)));
        }

        // Determine outcome based on randomness (e.g., 80% success chance)
        uint256 successChance = 8000; // 80.00% (using percentage * 100)
        uint256 randomPercentage = randomNumber % 10000; // Get a number between 0 and 9999

        if (randomPercentage < successChance) {
            return outcomeSuccess; // Success!
        } else {
            return outcomeFailure; // Failure or Partial Success
        }

        // More advanced: Could use different thresholds for Success, PartialSuccess, Failure based on randomPercentage
    }

    // The _mint and _burn internal functions from ERC721 are used internally
    // by OpenZeppelin's implementation and do not need explicit overrides
    // unless adding custom logic (like hooks). _mint is called implicitly
    // when `_mint(owner, tokenId)` is used.

    // _requireOwned is an internal OZ ERC721 function used for checks

    // Needed for tokenURI
    function _toString(uint256 tokenId) internal pure returns (string memory) {
        if (tokenId == 0) {
            return "0";
        }
        uint256 temp = tokenId;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (tokenId != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(tokenId % 10)));
            tokenId /= 10;
        }
        return string(buffer);
    }

    // Override ERC721 _update function to hook into transfers if needed (optional)
    // function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
    //     address from = ERC721._update(to, tokenId, auth);
    //     // Add custom logic here if needed before/after transfer
    //     return from;
    // }

}
```