Okay, here is a smart contract concept that incorporates several interconnected advanced/creative ideas under a metaphorical "Quantum Entangled Treasury" theme. It's designed to be novel and contains more than 20 functions managing assets, entanglement relationships, and state-dependent access.

**Concept:**

The `QuantumEntangledTreasury` is a contract that holds ERC20 tokens and ERC721 NFTs. Its unique features revolve around the concept of simulated "quantum entanglement" and "dimensional" access control:

1.  **Entangled Pairs:** The contract maintains lists of "entangled" addresses and "entangled" asset (ERC20 token) pairs. Operations involving one address or asset in a pair can potentially affect or be conditional on the state of its entangled counterpart.
2.  **Quantum State:** The treasury exists in one of three simulated states: `Superposed`, `CollapsedA`, or `CollapsedB`. This state determines the behavior of certain functions, especially those involving entangled pairs.
3.  **State Collapse:** A special function, `observeState()`, triggers a "collapse" of the quantum state from `Superposed` to either `CollapsedA` or `CollapsedB`. The outcome of the collapse is determined by a deterministic, but intentionally non-trivial (e.g., based on timestamp parity and caller address hash), logic. This simulates the effect of "observation" forcing a quantum state. A minimum time interval is required between collapses.
4.  **Dimensional Access Keys:** Access to certain sensitive functions requires a specific "Dimensional Key" (a `bytes32` value) assigned to a user. The *correct* key required might depend on the current `Collapsed` state.
5.  **Observer Status:** Certain users can be granted "Observer Status", allowing them to trigger state collapses.
6.  **State-Dependent Operations:** Functions like withdrawing funds to an entangled pair or swapping entangled assets behave differently based on whether the state is `CollapsedA` or `CollapsedB`.

This contract is complex and illustrative. In a real-world scenario, the "quantum" logic would need careful tuning, and external inputs (like Chainlink VRF or oracles) could make the state collapse more unpredictable if desired, but we keep it deterministic here for on-chain reliability.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title QuantumEntangledTreasury
 * @dev A novel treasury contract exploring simulated quantum mechanics concepts for access control and state-dependent operations.
 * Assets (ERC20, ERC721) are held, and interactions can be governed by "entangled" pairs, a dynamic "quantum state", and "dimensional keys".
 */
contract QuantumEntangledTreasury is Ownable, ReentrancyGuard {

    // --- Outline ---
    // 1. State Variables
    //    - Treasury state (Enum)
    //    - Supported Tokens (ERC20, ERC721)
    //    - Entangled Pairs (Address, Asset)
    //    - Quantum State Management
    //    - Access Control (Dimensional Keys, Observers)
    // 2. Events
    // 3. Modifiers
    // 4. Core Treasury Functions (Deposit/Withdraw)
    // 5. Entanglement Management Functions
    // 6. Quantum State Management Functions
    // 7. Access Control Functions (Dimensional)
    // 8. State-Dependent / Conditional Functions
    // 9. Information / Utility Functions
    // 10. Emergency Functions

    // --- Function Summary ---
    // - constructor: Initializes owner and minimum collapse interval.
    // - addSupportedToken(IERC20 token): Adds an ERC20 token to the supported list.
    // - removeSupportedToken(IERC20 token): Removes an ERC20 token from the supported list.
    // - addSupportedNFT(IERC721 nft): Adds an ERC721 token to the supported list.
    // - removeSupportedNFT(IERC721 nft): Removes an ERC721 token from the supported list.
    // - depositERC20(IERC20 token, uint amount): Deposits ERC20 tokens into the treasury.
    // - depositERC721(IERC721 nft, uint tokenId): Deposits an ERC721 NFT into the treasury.
    // - withdrawERC20(IERC20 token, uint amount, address recipient): Withdraws ERC20 tokens (standard).
    // - withdrawERC721(IERC721 nft, uint tokenId, address recipient): Withdraws ERC721 NFT (standard).
    // - createAddressEntanglement(address addrA, address addrB): Creates a bidirectional entanglement between two addresses.
    // - removeAddressEntanglement(address addrA): Removes an address entanglement.
    // - createAssetEntanglement(IERC20 tokenA, IERC20 tokenB): Creates a bidirectional entanglement between two supported ERC20 tokens.
    // - removeAssetEntanglement(IERC20 tokenA): Removes an asset entanglement.
    // - observeState(): Triggers a "collapse" of the quantum state based on deterministic logic (requires observer status or specific key).
    // - getCurrentState(): Returns the current quantum state.
    // - assignDimensionalKey(address user, bytes32 key): Assigns a specific dimensional key to a user (owner only).
    // - removeDimensionalKey(address user): Removes a user's dimensional key (owner only).
    // - grantObserverStatus(address user): Grants a user the ability to trigger state collapses (owner only).
    // - revokeObserverStatus(address user): Revokes a user's observer status (owner only).
    // - conditionalEntangledWithdrawal(address pairAddress, IERC20 token, uint amount): Withdraws tokens to one of the entangled addresses based on the collapsed state. Requires observer status or dimensional key.
    // - stateDependentSwap(IERC20 tokenA, uint amountA, IERC20 tokenB): Swaps between two *entangled* tokens, but only if the current state matches the 'CollapsedA' state (swap A for B) or 'CollapsedB' state (swap B for A). Requires holding both tokens and correct state.
    // - checkDimensionalKey(address user, bytes32 key): Verifies if a user holds a specific dimensional key.
    // - isObserver(address user): Checks if a user has observer status.
    // - getEntangledAddress(address addr): Returns the address entangled with the given address.
    // - getEntangledAsset(IERC20 token): Returns the token entangled with the given token.
    // - getERC20Balance(IERC20 token): Returns the treasury's balance of a supported ERC20 token.
    // - getERC721Owner(IERC721 nft, uint tokenId): Returns the owner of an NFT if held by the treasury.
    // - setMinCollapseInterval(uint interval): Sets the minimum time required between state collapses (owner only).
    // - getMinCollapseInterval(): Returns the minimum collapse interval.
    // - emergencyWithdrawERC20(IERC20 token, uint amount, address recipient): Emergency withdrawal of ERC20 by owner, bypassing state/key checks.
    // - emergencyWithdrawERC721(IERC721 nft, uint tokenId, address recipient): Emergency withdrawal of ERC721 by owner, bypassing state/key checks.

    // --- State Variables ---

    enum State {
        Superposed,
        CollapsedA,
        CollapsedB
    }

    State public currentState;

    mapping(IERC20 => bool) public supportedTokens;
    mapping(IERC721 => bool) public supportedNFTs;

    // Address Entanglement: A -> B and B -> A
    mapping(address => address) private addressEntanglements;
    mapping(address => address) private reverseAddressEntanglements; // For O(1) lookup B -> A

    // Asset Entanglement: TokenA -> TokenB and TokenB -> TokenA
    mapping(IERC20 => IERC20) private assetEntanglements;
    mapping(IERC20 => IERC20) private reverseAssetEntanglements; // For O(1) lookup TokenB -> TokenA

    // Quantum State Management
    uint public minCollapseInterval; // Minimum time (seconds) between state collapses
    uint private lastCollapseTimestamp;

    // Access Control (Dimensional Keys & Observers)
    mapping(address => bytes32) private dimensionalKeys;
    mapping(address => bool) private observers;

    // --- Events ---

    event SupportedTokenAdded(IERC20 indexed token);
    event SupportedTokenRemoved(IERC20 indexed token);
    event SupportedNFTAdded(IERC721 indexed nft);
    event SupportedNFTRemoved(IERC721 indexed nft);
    event ERC20Deposited(IERC20 indexed token, address indexed depositor, uint amount);
    event ERC721Deposited(IERC721 indexed nft, uint indexed tokenId, address indexed depositor);
    event ERC20Withdrawn(IERC20 indexed token, address indexed recipient, uint amount);
    event ERC721Withdrawn(IERC721 indexed nft, uint indexed tokenId, address indexed recipient);
    event AddressEntanglementCreated(address indexed addrA, address indexed addrB);
    event AddressEntanglementRemoved(address indexed addrA, address indexed addrB);
    event AssetEntanglementCreated(IERC20 indexed tokenA, IERC20 indexed tokenB);
    event AssetEntanglementRemoved(IERC20 indexed tokenA, IERC20 indexed tokenB);
    event StateCollapsed(State newState);
    event DimensionalKeyAssigned(address indexed user, bytes32 indexed keyHash); // Log hash, not key
    event DimensionalKeyRemoved(address indexed user);
    event ObserverStatusGranted(address indexed user);
    event ObserverStatusRevoked(address indexed user);
    event ConditionalWithdrawalExecuted(address indexed initiator, address indexed recipient, IERC20 indexed token, uint amount, State indexed stateAtCollapse);
    event StateDependentSwapExecuted(address indexed initiator, IERC20 indexed tokenOut, uint amountOut, IERC20 indexed tokenIn, uint amountIn, State indexed stateAtCollapse); // Note: Simplified - real swap needs price oracle
    event EmergencyWithdrawalERC20(IERC20 indexed token, address indexed recipient, uint amount);
    event EmergencyWithdrawalERC721(IERC721 indexed nft, address indexed recipient, uint indexed tokenId);

    // --- Modifiers ---

    modifier onlySupportedToken(IERC20 token) {
        require(supportedTokens[token], "Token not supported");
        _;
    }

    modifier onlySupportedNFT(IERC721 nft) {
        require(supportedNFTs[nft], "NFT not supported");
        _;
    }

    modifier onlyObserverOrHasKey(bytes32 requiredKey) {
        require(observers[msg.sender] || dimensionalKeys[msg.sender] == requiredKey, "Unauthorized: Requires observer status or specific key");
        _;
    }

    modifier onlyObserver() {
         require(observers[msg.sender], "Unauthorized: Requires observer status");
        _;
    }

    modifier whenStateIs(State requiredState) {
        require(currentState == requiredState, "Operation only valid in specific state");
        _;
    }

    // --- Constructor ---

    constructor(uint _minCollapseInterval) Ownable(msg.sender) {
        currentState = State.Superposed;
        minCollapseInterval = _minCollapseInterval;
        lastCollapseTimestamp = 0; // Allows first collapse immediately
    }

    // --- Supported Token Management ---

    /// @notice Adds an ERC20 token to the list of supported tokens.
    /// @param token The address of the ERC20 token.
    function addSupportedToken(IERC20 token) external onlyOwner {
        supportedTokens[token] = true;
        emit SupportedTokenAdded(token);
    }

    /// @notice Removes an ERC20 token from the list of supported tokens.
    /// @param token The address of the ERC20 token.
    function removeSupportedToken(IERC20 token) external onlyOwner {
        delete supportedTokens[token];
        // Note: Does not remove existing entanglements involving this token
        emit SupportedTokenRemoved(token);
    }

    /// @notice Adds an ERC721 token to the list of supported NFTs.
    /// @param nft The address of the ERC721 token.
    function addSupportedNFT(IERC721 nft) external onlyOwner {
        supportedNFTs[nft] = true;
        emit SupportedNFTAdded(nft);
    }

    /// @notice Removes an ERC721 token from the list of supported NFTs.
    /// @param nft The address of the ERC721 token.
    function removeSupportedNFT(IERC721 nft) external onlyOwner {
        delete supportedNFTs[nft];
        emit SupportedNFTRemoved(nft);
    }

    // --- Core Treasury Functions ---

    /// @notice Deposits ERC20 tokens into the treasury. Requires prior approval.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(IERC20 token, uint amount) external nonReentrant onlySupportedToken(token) {
        require(amount > 0, "Amount must be positive");
        token.transferFrom(msg.sender, address(this), amount);
        emit ERC20Deposited(token, msg.sender, amount);
    }

    /// @notice Deposits an ERC721 NFT into the treasury. Requires prior approval or setApprovalForAll.
    /// @param nft The address of the ERC721 token.
    /// @param tokenId The ID of the NFT to deposit.
    function depositERC721(IERC721 nft, uint tokenId) external nonReentrant onlySupportedNFT(nft) {
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        emit ERC721Deposited(nft, tokenId, msg.sender);
    }

    /// @notice Standard withdrawal of ERC20 tokens. May be restricted by custom modifiers in derived contracts.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to withdraw.
    /// @param recipient The recipient address.
    function withdrawERC20(IERC20 token, uint amount, address recipient) public nonReentrant onlyOwner onlySupportedToken(token) {
        require(amount > 0, "Amount must be positive");
        require(recipient != address(0), "Invalid recipient address");
        require(token.balanceOf(address(this)) >= amount, "Insufficient treasury balance");

        token.transfer(recipient, amount);
        emit ERC20Withdrawn(token, recipient, amount);
    }

    /// @notice Standard withdrawal of an ERC721 NFT. May be restricted by custom modifiers in derived contracts.
    /// @param nft The address of the ERC721 token.
    /// @param tokenId The ID of the NFT to withdraw.
    /// @param recipient The recipient address.
    function withdrawERC721(IERC721 nft, uint tokenId, address recipient) public nonReentrant onlyOwner onlySupportedNFT(nft) {
        require(recipient != address(0), "Invalid recipient address");
        require(nft.ownerOf(tokenId) == address(this), "Treasury does not own this NFT");

        nft.safeTransferFrom(address(this), recipient, tokenId);
        emit ERC721Withdrawn(nft, tokenId, recipient);
    }

    // --- Entanglement Management Functions ---

    /// @notice Creates a bidirectional entanglement between two addresses.
    /// Requires addresses to be non-zero and not already entangled with other addresses.
    /// @param addrA The first address.
    /// @param addrB The second address.
    function createAddressEntanglement(address addrA, address addrB) external onlyOwner {
        require(addrA != address(0) && addrB != address(0), "Invalid address");
        require(addrA != addrB, "Cannot entangle address with itself");
        require(addressEntanglements[addrA] == address(0), "Address A already entangled");
        require(addressEntanglements[addrB] == address(0), "Address B already entangled");

        addressEntanglements[addrA] = addrB;
        reverseAddressEntanglements[addrB] = addrA;
        emit AddressEntanglementCreated(addrA, addrB);
    }

    /// @notice Removes the entanglement involving a specific address.
    /// @param addrA One of the addresses in the entangled pair.
    function removeAddressEntanglement(address addrA) external onlyOwner {
        address addrB = addressEntanglements[addrA];
        require(addrB != address(0), "Address A is not entangled");

        delete addressEntanglements[addrA];
        delete reverseAddressEntanglements[addrB];
        // Also remove B -> A mapping if it exists (redundant due to reverse mapping, but good practice)
        delete addressEntanglements[addrB];
        delete reverseAddressEntanglements[addrA];

        emit AddressEntanglementRemoved(addrA, addrB);
    }

    /// @notice Creates a bidirectional entanglement between two supported ERC20 tokens.
    /// Requires tokens to be supported, non-zero, distinct, and not already entangled.
    /// @param tokenA The first ERC20 token.
    /// @param tokenB The second ERC20 token.
    function createAssetEntanglement(IERC20 tokenA, IERC20 tokenB) external onlyOwner onlySupportedToken(tokenA) onlySupportedToken(tokenB) {
        require(address(tokenA) != address(0) && address(tokenB) != address(0), "Invalid token address");
        require(tokenA != tokenB, "Cannot entangle token with itself");
        require(address(assetEntanglements[tokenA]) == address(0), "Token A already entangled");
        require(address(assetEntanglements[tokenB]) == address(0), "Token B already entangled");

        assetEntanglements[tokenA] = tokenB;
        reverseAssetEntanglements[tokenB] = tokenA;
        emit AssetEntanglementCreated(tokenA, tokenB);
    }

    /// @notice Removes the asset entanglement involving a specific token.
    /// @param tokenA One of the tokens in the entangled pair.
    function removeAssetEntanglement(IERC20 tokenA) external onlyOwner {
        IERC20 tokenB = assetEntanglements[tokenA];
        require(address(tokenB) != address(0), "Token A is not entangled");

        delete assetEntanglements[tokenA];
        delete reverseAssetEntanglements[tokenB];
        // Also remove B -> A mapping if it exists
        delete assetEntanglements[tokenB];
        delete reverseAssetEntanglements[tokenA];

        emit AssetEntanglementRemoved(tokenA, tokenB);
    }

    // --- Quantum State Management Functions ---

    /// @notice Triggers a "collapse" of the quantum state if currently Superposed and minimum interval passed.
    /// The resulting state (CollapsedA or CollapsedB) is determined deterministically based on block data and caller/previous state hash.
    /// Requires observer status or a specific dimensional key.
    function observeState() external nonReentrant onlyObserverOrHasKey(bytes32(uint256(keccak256(abi.encodePacked("OBSERVATION_KEY", address(this)))))) {
        require(currentState == State.Superposed, "State must be Superposed to collapse");
        require(block.timestamp >= lastCollapseTimestamp + minCollapseInterval, "Too soon to collapse state again");

        // Deterministic collapse logic based on block data, sender, and previous state hash
        // This uses a simple check for demonstration. More complex logic could be used.
        bytes32 entropy = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, lastCollapseTimestamp));

        if (uint256(entropy) % 2 == 0) {
             currentState = State.CollapsedA;
        } else {
             currentState = State.CollapsedB;
        }

        lastCollapseTimestamp = block.timestamp;
        emit StateCollapsed(currentState);
    }

    /// @notice Returns the current quantum state of the treasury.
    /// @return The current State enum value.
    function getCurrentState() external view returns (State) {
        return currentState;
    }

    // --- Access Control Functions (Dimensional) ---

    /// @notice Assigns a specific dimensional key to a user. Owner only.
    /// @param user The address of the user.
    /// @param key The 32-byte key to assign. (Consider security implications of assigning known keys)
    function assignDimensionalKey(address user, bytes32 key) external onlyOwner {
        require(user != address(0), "Invalid user address");
        dimensionalKeys[user] = key;
        // Log the hash of the key for privacy, not the key itself
        emit DimensionalKeyAssigned(user, keccak256(abi.encodePacked(key)));
    }

    /// @notice Removes a user's dimensional key. Owner only.
    /// @param user The address of the user.
    function removeDimensionalKey(address user) external onlyOwner {
         require(user != address(0), "Invalid user address");
         delete dimensionalKeys[user];
         emit DimensionalKeyRemoved(user);
    }

    /// @notice Grants observer status to a user, allowing them to trigger state collapses. Owner only.
    /// @param user The address of the user.
    function grantObserverStatus(address user) external onlyOwner {
        require(user != address(0), "Invalid user address");
        observers[user] = true;
        emit ObserverStatusGranted(user);
    }

    /// @notice Revokes observer status from a user. Owner only.
    /// @param user The address of the user.
    function revokeObserverStatus(address user) external onlyOwner {
        require(user != address(0), "Invalid user address");
        delete observers[user];
        emit ObserverStatusRevoked(user);
    }

    /// @notice Verifies if a user holds a specific dimensional key.
    /// @param user The address of the user.
    /// @param key The key to check against.
    /// @return True if the user holds the key, false otherwise.
    function checkDimensionalKey(address user, bytes32 key) external view returns (bool) {
        return dimensionalKeys[user] == key;
    }

    /// @notice Checks if a user has observer status.
    /// @param user The address of the user.
    /// @return True if the user is an observer, false otherwise.
    function isObserver(address user) external view returns (bool) {
        return observers[user];
    }


    // --- State-Dependent / Conditional Functions ---

    /// @notice Withdraws tokens to one of an entangled address pair based on the current collapsed state.
    /// Requires observer status or a specific dimensional key.
    /// Requires the state to be CollapsedA or CollapsedB.
    /// @param pairAddress One of the addresses in the entangled pair.
    /// @param token The ERC20 token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function conditionalEntangledWithdrawal(address pairAddress, IERC20 token, uint amount)
        external
        nonReentrant
        onlySupportedToken(token)
        onlyObserverOrHasKey(bytes32(uint256(keccak256(abi.encodePacked("ENTANGLED_WITHDRAWAL_KEY", address(this))))))
        whenStateIs(currentState == State.CollapsedA || currentState == State.CollapsedB ? currentState : State.Superposed) // Ensure it's CollapsedA or CollapsedB
    {
        address entangledAddr = addressEntanglements[pairAddress];
        require(entangledAddr != address(0), "Provided address is not part of an entanglement pair");
        require(pairAddress != address(0), "Invalid pair address"); // Redundant due to entanglement check but safe
        require(amount > 0, "Amount must be positive");
        require(token.balanceOf(address(this)) >= amount, "Insufficient treasury balance");

        address recipient;
        if (currentState == State.CollapsedA) {
            recipient = pairAddress; // Send to the provided address
        } else { // currentState == State.CollapsedB
            recipient = entangledAddr; // Send to the address entangled with the provided address
        }

        token.transfer(recipient, amount);
        emit ConditionalWithdrawalExecuted(msg.sender, recipient, token, amount, currentState);
    }

    /// @notice Performs a swap between two *entangled* ERC20 tokens, conditional on the collapsed state.
    /// If state is CollapsedA, swaps tokenA (provided as tokenOut) for tokenB (provided as tokenIn).
    /// If state is CollapsedB, swaps tokenB (provided as tokenOut) for tokenA (provided as tokenIn).
    /// This is a simplified example; a real swap would need price/ratio logic (e.g., via oracle or AMM math).
    /// Requires observer status or a specific dimensional key.
    /// @param tokenA The first token in the potential swap pair (acts as tokenOut if state is CollapsedA).
    /// @param amountA The amount of tokenA to swap out (if state is CollapsedA).
    /// @param tokenB The second token in the potential swap pair (acts as tokenIn if state is CollapsedA).
    function stateDependentSwap(IERC20 tokenA, uint amountA, IERC20 tokenB)
        external
        nonReentrant
        onlySupportedToken(tokenA)
        onlySupportedToken(tokenB)
        onlyObserverOrHasKey(bytes32(uint256(keccak256(abi.encodePacked("STATE_SWAP_KEY", address(this))))))
        whenStateIs(currentState == State.CollapsedA || currentState == State.CollapsedB ? currentState : State.Superposed) // Ensure it's CollapsedA or CollapsedB
    {
        require(assetEntanglements[tokenA] == tokenB || reverseAssetEntanglements[tokenA] == tokenB, "Tokens are not entangled");
        require(amountA > 0, "Amount must be positive");

        uint amountB; // Amount of tokenB to swap in

        if (currentState == State.CollapsedA) {
            require(assetEntanglements[tokenA] == tokenB, "State mismatch for swap direction (Expected A->B)");
            require(tokenA.balanceOf(address(this)) >= amountA, "Insufficient treasury balance of tokenA");

            // Simplified swap logic: Assume a 1:1 ratio or use a fixed ratio.
            // In a real scenario, integrate with a price oracle or AMM math here.
            amountB = amountA; // Example: 1:1 swap ratio

            require(tokenB.balanceOf(address(this)) >= amountB, "Insufficient treasury balance of tokenB for swap");

            // Perform the swap
            tokenA.transferFrom(msg.sender, address(this), amountA); // User sends tokenA to treasury
            tokenB.transfer(msg.sender, amountB); // Treasury sends tokenB to user

            emit StateDependentSwapExecuted(msg.sender, tokenA, amountA, tokenB, amountB, currentState);

        } else { // currentState == State.CollapsedB
            require(assetEntanglements[tokenB] == tokenA, "State mismatch for swap direction (Expected B->A)"); // Check entanglement the other way
            require(tokenB.balanceOf(address(this)) >= amountA, "Insufficient treasury balance of tokenB (using A's amount as reference)"); // User provides tokenB

            // Simplified swap logic: Assume a 1:1 ratio or use a fixed ratio.
            // In a real scenario, integrate with a price oracle or AMM math here.
            amountB = amountA; // Example: 1:1 swap ratio, user gives amountA of tokenB to get amountA of tokenA

            require(tokenA.balanceOf(address(this)) >= amountB, "Insufficient treasury balance of tokenA for swap");

            // Perform the swap (reversed)
            tokenB.transferFrom(msg.sender, address(this), amountA); // User sends tokenB to treasury
            tokenA.transfer(msg.sender, amountB); // Treasury sends tokenA to user

            emit StateDependentSwapExecuted(msg.sender, tokenB, amountA, tokenA, amountB, currentState); // Log tokens in correct swap direction
        }
    }


    // --- Information / Utility Functions ---

    /// @notice Returns the address entangled with the given address.
    /// @param addr The address to check.
    /// @return The entangled address, or address(0) if not entangled.
    function getEntangledAddress(address addr) external view returns (address) {
        address entangled = addressEntanglements[addr];
        if (entangled != address(0)) {
            return entangled;
        }
        return reverseAddressEntanglements[addr]; // Check reverse mapping
    }

     /// @notice Returns the token entangled with the given token.
    /// @param token The token to check.
    /// @return The entangled token, or address(0) if not entangled.
    function getEntangledAsset(IERC20 token) external view returns (IERC20) {
        IERC20 entangled = assetEntanglements[token];
        if (address(entangled) != address(0)) {
            return entangled;
        }
        return reverseAssetEntanglements[token]; // Check reverse mapping
    }

    /// @notice Returns the treasury's balance of a supported ERC20 token.
    /// @param token The address of the ERC20 token.
    /// @return The balance.
    function getERC20Balance(IERC20 token) external view onlySupportedToken(token) returns (uint) {
        return token.balanceOf(address(this));
    }

    /// @notice Returns the owner of an NFT by its ID. Useful for checking if treasury owns it.
    /// @param nft The address of the ERC721 token.
    /// @param tokenId The ID of the NFT.
    /// @return The owner's address.
    function getERC721Owner(IERC721 nft, uint tokenId) external view onlySupportedNFT(nft) returns (address) {
        return nft.ownerOf(tokenId);
    }

    /// @notice Gets the configured minimum interval between state collapses.
    function getMinCollapseInterval() external view returns (uint) {
        return minCollapseInterval;
    }

    /// @notice Sets the minimum interval required between state collapses. Owner only.
    /// @param interval The new interval in seconds.
    function setMinCollapseInterval(uint interval) external onlyOwner {
        minCollapseInterval = interval;
        // No event needed for this simple setter
    }


    // --- Emergency Functions ---

    /// @notice Allows owner to withdraw ERC20 in case of emergency, bypassing state/key/observer checks.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount to withdraw.
    /// @param recipient The recipient address.
    function emergencyWithdrawERC20(IERC20 token, uint amount, address recipient) external onlyOwner nonReentrant onlySupportedToken(token) {
        require(amount > 0, "Amount must be positive");
        require(recipient != address(0), "Invalid recipient address");
        require(token.balanceOf(address(this)) >= amount, "Insufficient treasury balance");

        token.transfer(recipient, amount);
        emit EmergencyWithdrawalERC20(token, recipient, amount);
    }

    /// @notice Allows owner to withdraw ERC721 in case of emergency, bypassing state/key/observer checks.
    /// @param nft The address of the ERC721 token.
    /// @param tokenId The ID of the NFT.
    /// @param recipient The recipient address.
    function emergencyWithdrawERC721(IERC721 nft, uint tokenId, address recipient) external onlyOwner nonReentrant onlySupportedNFT(nft) {
        require(recipient != address(0), "Invalid recipient address");
         require(nft.ownerOf(tokenId) == address(this), "Treasury does not own this NFT");

        nft.safeTransferFrom(address(this), recipient, tokenId);
        emit EmergencyWithdrawalERC721(nft, tokenId, recipient);
    }
}
```