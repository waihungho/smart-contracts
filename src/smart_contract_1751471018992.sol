Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts around NFTs representing parts of a conceptual Decentralized AI Model, featuring staking, delegation of AI processing power, dynamic metadata driven by oracle interaction, and a simple reward system.

This contract is **not** a simple copy of common open-source templates. It combines elements of ERC721, staking, delegation patterns, and integrates with an oracle pattern for off-chain computation results (simulating interaction with decentralized AI infrastructure).

**Important Considerations & Limitations:**

1.  **Off-Chain AI:** Smart contracts *cannot* run complex AI models directly. This contract relies on an **oracle** to receive results from off-chain AI computation triggered by events. The security and decentralization of the actual AI processing are *outside* the scope of this contract.
2.  **Oracle Trust:** The `fulfillAIProcessing` function relies on a trusted oracle address. A real-world system would need a robust decentralized oracle network (like Chainlink, or a custom setup) to prevent manipulation.
3.  **Reward System:** The reward system is simplified (based on accrual). A real system might use a separate ERC20 token and more complex distribution logic.
4.  **Dynamic Metadata:** `tokenURI` is dynamic, but requires an off-chain service (like a server or IPFS gateway) to serve the JSON metadata based on the on-chain state returned by `getNFTState`.
5.  **Scalability:** Storing complex dynamic data for potentially many NFTs on-chain can become expensive.
6.  **Completeness:** This is a conceptual example. A production system would require more robust error handling, access control, potential upgradeability, and thorough testing.

---

**Outline:**

1.  **Pragma**
2.  **Imports:** ERC721, Ownable, Pausable, ERC165.
3.  **Errors:** Custom error definitions for clarity.
4.  **Events:** Declarations for significant actions.
5.  **Interfaces (Optional but good practice):** Define expected functions if interacting with other specific contracts (not strictly needed for this self-contained example except standard ERC721).
6.  **State Variables:** Core contract configuration and data storage.
7.  **Structs:** Data structures for holding NFT-specific dynamic state.
8.  **Modifiers:** Custom modifiers for access control beyond `Ownable`.
9.  **ERC721 Core Implementation:** Standard ERC721 functions with customizations (`tokenURI`, `_beforeTokenTransfer`).
10. **Dynamic NFT State Management:** Internal logic for updating and retrieving NFT state.
11. **Staking Logic:** Functions for staking and unstaking NFTs.
12. **Delegation Logic:** Functions for delegating/undelegating AI processing rights of staked NFTs.
13. **AI Processing Interaction:** Functions to request off-chain processing and receive results via oracle callback.
14. **Reward System Logic:** Functions to calculate and claim pending rewards.
15. **Admin/Utility Functions:** Owner-controlled configuration and maintenance functions.
16. **ERC165 Support:** Standard interface detection.

**Function Summary (Counting > 20):**

1.  `constructor()`: Initializes contract, ERC721 parameters, mints initial supply.
2.  `mint(address to, uint256 capabilityScore)`: Mints a new NFT to `to` with an initial capability score (Owner only).
3.  `tokenURI(uint256 tokenId)`: Returns the dynamic metadata URI for a token.
4.  `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support.
5.  `balanceOf(address owner)`: Standard ERC721.
6.  `ownerOf(uint256 tokenId)`: Standard ERC721.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721.
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC721.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Standard ERC721.
10. `approve(address to, uint256 tokenId)`: Standard ERC721.
11. `setApprovalForAll(address operator, bool approved)`: Standard ERC721.
12. `getApproved(uint256 tokenId)`: Standard ERC721.
13. `isApprovedForAll(address owner, address operator)`: Standard ERC721.
14. `_updateNFTState(uint256 tokenId, uint256 newCapabilityScore, uint256 usageIncrement)`: Internal function to update an NFT's state.
15. `getNFTState(uint256 tokenId)`: Retrieves the current dynamic state of an NFT.
16. `stake(uint256 tokenId)`: Stakes an owned NFT, transferring it to the contract.
17. `unstake(uint256 tokenId)`: Unstakes an NFT owned by the caller *and* staked by them.
18. `getStakedTokens(address owner)`: Lists token IDs staked by an address.
19. `getTotalStaked()`: Returns the total number of NFTs currently staked in the contract.
20. `delegateUsage(uint256 tokenId, address delegatee)`: Delegates AI processing usage rights of a staked NFT to another address.
21. `undelegateUsage(uint256 tokenId)`: Revokes the delegation for a staked NFT.
22. `getDelegatedTo(uint256 tokenId)`: Checks which address a staked NFT is delegated to.
23. `requestAIProcessing(uint256 tokenId, string memory dataHash)`: Requests off-chain AI processing for a specific staked/delegated NFT, paying a fee. Emits an event for the oracle.
24. `fulfillAIProcessing(uint256 requestId, uint256 tokenId, uint256 outputScore, string memory outputDataHash)`: Callback function for the trusted oracle to report AI processing results. Updates NFT state and potentially rewards.
25. `setOracleAddress(address _oracle)`: Sets the trusted oracle address (Owner only).
26. `setProcessorFee(uint256 _fee)`: Sets the fee required to request AI processing (Owner only).
27. `setRewardRate(uint256 _rate)`: Sets the base reward rate per staked token per block (Owner only).
28. `getPendingRewards(address owner)`: Calculates and returns the estimated pending rewards for an owner.
29. `claimRewards()`: Claims accumulated rewards for the caller.
30. `withdrawETH()`: Allows the owner to withdraw accumulated ETH fees (Owner only).
31. `pause()`: Pauses certain contract operations (Owner only).
32. `unpause()`: Unpauses the contract (Owner only).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Often included, adds tokenOfOwnerByIndex, etc.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For dynamic URI handling (though we override tokenURI)
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For address.sendValue if withdrawing ETH

// Outline:
// 1. Pragma & Imports
// 2. Errors
// 3. Events
// 4. State Variables
// 5. Structs
// 6. Modifiers
// 7. ERC721 Core (with dynamic URI logic)
// 8. Dynamic NFT State Management
// 9. Staking Logic
// 10. Delegation Logic
// 11. AI Processing Interaction (Request & Oracle Fulfilment)
// 12. Reward System Logic (Simplified Accrual)
// 13. Admin/Utility Functions
// 14. ERC165 Support

// Function Summary (> 20 functions):
// 1. constructor() - Initializes contract, mints initial supply.
// 2. mint(address to, uint256 capabilityScore) - Mints new NFT (Owner only).
// 3. tokenURI(uint256 tokenId) - Dynamic URI based on state.
// 4. supportsInterface(bytes4 interfaceId) - ERC165 standard.
// 5. balanceOf(address owner) - ERC721 standard.
// 6. ownerOf(uint256 tokenId) - ERC721 standard.
// 7. transferFrom(address from, address to, uint256 tokenId) - ERC721 standard.
// 8. safeTransferFrom(address from, address to, uint256 tokenId) - ERC721 standard.
// 9. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) - ERC721 standard.
// 10. approve(address to, uint256 tokenId) - ERC721 standard.
// 11. setApprovalForAll(address operator, bool approved) - ERC721 standard.
// 12. getApproved(uint256 tokenId) - ERC721 standard.
// 13. isApprovedForAll(address owner, address operator) - ERC721 standard.
// 14. _updateNFTState(uint256 tokenId, uint256 newCapabilityScore, uint256 usageIncrement) - Internal: Update NFT state.
// 15. getNFTState(uint256 tokenId) - Get current dynamic state.
// 16. stake(uint256 tokenId) - Stake an NFT.
// 17. unstake(uint256 tokenId) - Unstake an NFT.
// 18. getStakedTokens(address owner) - List staked tokens for owner.
// 19. getTotalStaked() - Total staked NFTs.
// 20. delegateUsage(uint256 tokenId, address delegatee) - Delegate staked NFT usage.
// 21. undelegateUsage(uint256 tokenId) - Revoke delegation.
// 22. getDelegatedTo(uint256 tokenId) - Check current delegatee.
// 23. requestAIProcessing(uint256 tokenId, string memory dataHash) - Request off-chain AI task.
// 24. fulfillAIProcessing(uint256 requestId, uint256 tokenId, uint256 outputScore, string memory outputDataHash) - Oracle callback for results.
// 25. setOracleAddress(address _oracle) - Set trusted oracle (Owner only).
// 26. setProcessorFee(uint256 _fee) - Set fee for AI requests (Owner only).
// 27. setRewardRate(uint256 _rate) - Set base reward rate (Owner only).
// 28. getPendingRewards(address owner) - Calculate pending rewards.
// 29. claimRewards() - Claim accumulated rewards.
// 30. withdrawETH() - Withdraw contract ETH balance (Owner only).
// 31. pause() - Pause contract (Owner only).
// 32. unpause() - Unpause contract (Owner only).


contract DecentralizedAIModelNFT is ERC721Enumerable, ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    address public oracleAddress; // Address of the trusted oracle contract/account
    uint256 public processorFee;  // Fee required to request AI processing using an NFT
    uint256 public rewardRate;    // Base reward points/unit per block for staked NFTs

    // Struct to hold dynamic state of an NFT
    struct NFTData {
        uint256 capabilityScore; // Represents the 'strength' or 'quality' of this model part/access
        uint256 usageCount;      // How many times this NFT has been used for processing
        uint256 lastProcessedBlock; // Block number of the last successful processing
        uint256 lastRewardUpdateBlock; // Block number when rewards were last calculated/claimed
        uint256 pendingRewards;    // Accumulated reward points
        bytes32 currentDataHash;   // Hash representing the current processed data state (conceptual)
    }

    // Mapping from tokenId to its dynamic data
    mapping(uint256 => NFTData) private _tokenData;

    // Mapping to track staked tokens
    mapping(uint256 => bool) private _isStaked;
    mapping(address => uint256[]) private _stakedTokensOfOwner; // List of staked tokens per address (more for convenience/enumeration)
    mapping(uint256 => uint256) private _stakedTokenIndex; // Index in the stakedTokensOfOwner array

    // Mapping to track delegation of processing rights for *staked* tokens
    // Only the owner of a *staked* token can delegate
    mapping(uint256 => address) private _delegatedTo; // TokenId => Delegatee Address (address(0) means no delegation)
    mapping(address => uint256[]) private _delegatedTokensByAddress; // Delegatee Address => list of tokens delegated *to* them
    mapping(uint256 => uint256) private _delegatedTokenIndex; // Index in delegatedTokensByAddress array

    // Mapping for AI Processing Requests (simplified: just tracking requests)
    // In a real system, this would track request details, status, etc.
    mapping(uint256 => uint256) private _processingRequestIdToTokenId; // Request ID => Token ID

    Counters.Counter private _processingRequestCounter; // Counter for unique request IDs

    // Base URI for metadata. Actual URI will be baseURI + tokenId.
    string private _baseTokenURI;

    // --- Errors ---
    error NFTNotStaked(uint256 tokenId);
    error NFTAlreadyStaked(uint256 tokenId);
    error NotStakedOwner(uint256 tokenId, address caller);
    error NotDelegatee(uint256 tokenId, address caller);
    error NotStakedOrDelegatee(uint256 tokenId, address caller);
    error DelegationNotStaked(uint256 tokenId);
    error DelegationAlreadyExists(uint256 tokenId);
    error NoActiveDelegation(uint256 tokenId);
    error InvalidOracleAddress(address _oracle);
    error OnlyOracle();
    error InsufficientFee(uint256 requiredFee, uint256 sentFee);
    error NoPendingRewards(address owner);


    // --- Events ---
    event NFTMinted(address indexed to, uint256 indexed tokenId, uint256 initialCapability);
    event NFTStateUpdated(uint256 indexed tokenId, uint256 newCapabilityScore, uint256 newUsageCount, bytes32 newDataHash);
    event NFTStaked(address indexed owner, uint256 indexed tokenId);
    event NFTUnstaked(address indexed owner, uint256 indexed tokenId);
    event UsageDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event UsageUndelegated(uint256 indexed tokenId, address indexed delegator, address delegatee);
    event AIProcessingRequested(uint256 indexed requestId, uint256 indexed tokenId, address indexed requestedBy, string dataHash);
    event AIProcessingFulfilled(uint256 indexed requestId, uint256 indexed tokenId, uint256 outputScore, string outputDataHash);
    event RewardsClaimed(address indexed owner, uint256 amount);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event ProcessorFeeSet(uint256 oldFee, uint256 newFee);
    event RewardRateSet(uint256 oldRate, uint256 newRate);


    // --- Modifiers ---
    // Ensures the caller is either the owner of a staked token or its delegatee
    modifier onlyStakedOwnerOrDelegatee(uint256 tokenId) {
        if (!_isStaked[tokenId]) {
            revert NFTNotStaked(tokenId);
        }
        address stakedOwner = ownerOf(tokenId); // When staked, contract is owner, but we need original owner logic
        address originalOwner = _originalOwners[tokenId]; // Need to track original owners for staking context

        address delegatee = _delegatedTo[tokenId];

        if (msg.sender != originalOwner && msg.sender != delegatee) {
             revert NotStakedOrDelegatee(tokenId, msg.sender);
        }
        _;
    }

    // Ensures the caller is the trusted oracle address
    modifier onlyOracle() {
        if (msg.sender != oracleAddress || oracleAddress == address(0)) {
            revert OnlyOracle();
        }
        _;
    }


    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        ERC721Enumerable()
        ERC721URIStorage()
        Ownable(msg.sender)
        Pausable()
    {
        _baseTokenURI = baseURI;
        // Initial parameters - can be set by owner later
        oracleAddress = address(0); // Must be set by owner
        processorFee = 0; // Must be set by owner
        rewardRate = 100; // Example: 100 points per block per staked NFT
    }

    // --- ERC721 Core Implementation Overrides ---

    // Override _update to include state updates (handled in mint)
    // Override _safeTransfer from/to to manage staking status
    // Override _beforeTokenTransfer to manage staking/delegation lists

    // Mapping to track original owners before staking
    mapping(uint256 => address) private _originalOwners;

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Logic for staking/unstaking occurs when transferring to/from THIS contract address
        if (to == address(this) && from != address(0)) {
            // Staking: Track original owner and add to staked list
             _originalOwners[tokenId] = from;
            _addTokenToStakedList(from, tokenId);
            _isStaked[tokenId] = true;

            // Update rewards before staking
            _calculateAndAddPendingRewards(from, tokenId);

        } else if (from == address(this) && to != address(0)) {
            // Unstaking: Remove from staked list
            // Ensure it was actually staked by the recipient
            if (_originalOwners[tokenId] != to) {
                 revert NotStakedOwner(tokenId, to); // Should not happen if unstake logic is correct
            }

            _removeTokenFromStakedList(to, tokenId);
            delete _originalOwners[tokenId];
            _isStaked[tokenId] = false;

             // Update rewards before unstaking
            _calculateAndAddPendingRewards(to, tokenId);

        } else if (from != address(0) && to != address(0)) {
             // Standard transfer - ensure not staked or delegated
            if (_isStaked[tokenId]) revert NFTAlreadyStaked(tokenId);
            if (_delegatedTo[tokenId] != address(0)) revert DelegationAlreadyExists(tokenId); // Cannot transfer if delegated
        }
    }

    // Standard ERC721 functions are inherited, no need to list all 13 explicitly in code comments
    // as they are standard implementations from OpenZeppelin unless overridden.
    // We *will* override tokenURI.

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        _requireOwned(tokenId);

        // In a real application, this would point to an off-chain service
        // that reads getNFTState(tokenId) and generates/serves JSON metadata.
        // For this example, we'll return a placeholder URI.
        // You'd typically return something like `string(abi.encodePacked(_baseTokenURI, toString(tokenId)));`
        // And the server at _baseTokenURI would resolve /tokenId requests.

        // To show dynamic nature, let's just encode the capability score in the URI (highly simplified)
        NFTData storage data = _tokenData[tokenId];
        return string(abi.encodePacked("ipfs://baseuri/", toString(tokenId), "?capability=", toString(data.capabilityScore), "&usage=", toString(data.usageCount)));
    }

    // Helper to convert uint256 to string (for tokenURI)
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
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }

    // --- Dynamic NFT State Management ---

    // Internal function to update NFT state based on AI processing results or minting
    function _updateNFTState(uint256 tokenId, uint256 newCapabilityScore, uint256 usageIncrement) internal {
        // Ensure the token exists
        if (!_exists(tokenId)) return; // Or revert with an error

        NFTData storage data = _tokenData[tokenId];
        data.capabilityScore = newCapabilityScore;
        data.usageCount = data.usageCount.add(usageIncrement);
        data.lastProcessedBlock = block.number;
        // currentDataHash could also be updated here based on outputDataHash

        emit NFTStateUpdated(tokenId, data.capabilityScore, data.usageCount, data.currentDataHash);
    }

    // Get the current dynamic state of an NFT
    function getNFTState(uint256 tokenId) public view returns (uint256 capabilityScore, uint256 usageCount, uint256 lastProcessedBlock, bytes32 currentDataHash) {
         // Ensure the token exists
        if (!_exists(tokenId)) return (0, 0, 0, bytes32(0));

        NFTData storage data = _tokenData[tokenId];
        return (data.capabilityScore, data.usageCount, data.lastProcessedBlock, data.currentDataHash);
    }


    // --- Staking Logic ---

    // Stake an owned NFT
    function stake(uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender) {
            revert NotOwned(msg.sender, tokenId); // Reverts if not owner
        }
        if (_isStaked[tokenId]) {
            revert NFTAlreadyStaked(tokenId);
        }

        // Before transferring, calculate and add pending rewards (for owner's previously staked tokens)
        // This is to capture rewards earned on *other* tokens before changing the staking set
        // _calculateAndAddPendingRewards(msg.sender, tokenId); // Not needed for the token being staked now, it starts earning *after* staking

        // Transfer the token to the contract
        safeTransferFrom(owner, address(this), tokenId);

        emit NFTStaked(owner, tokenId);
        // _beforeTokenTransfer handles the rest (tracking original owner, _isStaked, staked list)
    }

    // Unstake an NFT that the caller originally staked
    function unstake(uint256 tokenId) public whenNotPaused {
        if (!_isStaked[tokenId]) {
            revert NFTNotStaked(tokenId);
        }
        address originalOwner = _originalOwners[tokenId];
        if (originalOwner != msg.sender) {
            revert NotStakedOwner(tokenId, msg.sender);
        }
        if (_delegatedTo[tokenId] != address(0)) {
             revert DelegationAlreadyExists(tokenId); // Cannot unstake if delegated - must undelegate first
        }

        // Calculate and add pending rewards before unstaking
        _calculateAndAddPendingRewards(msg.sender, tokenId);

        // Transfer the token back to the original owner
        // _beforeTokenTransfer handles the rest (_isStaked, staked list cleanup)
        safeTransferFrom(address(this), originalOwner, tokenId);

        emit NFTUnstaked(originalOwner, tokenId);
    }

     // Internal helper to add token to staked list for an address
    function _addTokenToStakedList(address owner, uint256 tokenId) internal {
        _stakedTokenIndex[tokenId] = _stakedTokensOfOwner[owner].length;
        _stakedTokensOfOwner[owner].push(tokenId);
    }

    // Internal helper to remove token from staked list for an address
    function _removeTokenFromStakedList(address owner, uint256 tokenId) internal {
        uint256 index = _stakedTokenIndex[tokenId];
        uint256 lastIndex = _stakedTokensOfOwner[owner].length - 1;
        uint256 lastTokenId = _stakedTokensOfOwner[owner][lastIndex];

        // Move the last token to the removed token's position
        _stakedTokensOfOwner[owner][index] = lastTokenId;
        _stakedTokenIndex[lastTokenId] = index;

        // Remove the last element (which is now a duplicate)
        _stakedTokensOfOwner[owner].pop();

        delete _stakedTokenIndex[tokenId];
    }

    // Get list of token IDs staked by an address (read-only)
    function getStakedTokens(address owner) public view returns (uint256[] memory) {
        return _stakedTokensOfOwner[owner];
    }

    // Get total number of NFTs currently staked in the contract
    function getTotalStaked() public view returns (uint256) {
        // This would require iterating through all tokens or maintaining a separate counter.
        // ERC721Enumerable doesn't provide a direct total supply of *staked* tokens.
        // A simple way is to track it manually or loop through all token IDs if enumerable.
        // For this example, let's return the count of tokens owned by the contract address
        // assuming only staked tokens are owned by the contract.
         return balanceOf(address(this));
    }


    // --- Delegation Logic ---

    // Delegate the AI processing usage rights of a *staked* NFT to another address
    // Only the original owner of the staked NFT can delegate
    function delegateUsage(uint256 tokenId, address delegatee) public whenNotPaused {
        if (!_isStaked[tokenId]) {
            revert DelegationNotStaked(tokenId);
        }
        address originalOwner = _originalOwners[tokenId];
        if (originalOwner != msg.sender) {
            revert NotStakedOwner(tokenId, msg.sender);
        }
        if (_delegatedTo[tokenId] != address(0)) {
            revert DelegationAlreadyExists(tokenId);
        }
        if (delegatee == address(0)) {
             revert InvalidOracleAddress(delegatee); // Using the same error for address(0)
        }

        _delegatedTo[tokenId] = delegatee;
        _addTokenToDelegatedList(delegatee, tokenId);

        emit UsageDelegated(tokenId, msg.sender, delegatee);
    }

    // Revoke the delegation for a staked NFT
    // Only the original owner of the staked NFT can undelegate
    function undelegateUsage(uint256 tokenId) public whenNotPaused {
        if (!_isStaked[tokenId]) {
            revert DelegationNotStaked(tokenId);
        }
        address originalOwner = _originalOwners[tokenId];
        if (originalOwner != msg.sender) {
            revert NotStakedOwner(tokenId, msg.sender);
        }
        if (_delegatedTo[tokenId] == address(0)) {
            revert NoActiveDelegation(tokenId);
        }

        address delegatee = _delegatedTo[tokenId];
        delete _delegatedTo[tokenId];
        _removeTokenFromDelegatedList(delegatee, tokenId);

        emit UsageUndelegated(tokenId, msg.sender, delegatee);
    }

    // Get the address the staked NFT is currently delegated to (address(0) if none)
    function getDelegatedTo(uint256 tokenId) public view returns (address) {
        return _delegatedTo[tokenId];
    }

     // Get list of token IDs delegated *to* a specific address
    function getDelegatedTokensToAddress(address delegatee) public view returns (uint256[] memory) {
        return _delegatedTokensByAddress[delegatee];
    }

    // Internal helper to add token to delegated list for an address
    function _addTokenToDelegatedList(address delegatee, uint256 tokenId) internal {
        _delegatedTokenIndex[tokenId] = _delegatedTokensByAddress[delegatee].length;
        _delegatedTokensByAddress[delegatee].push(tokenId);
    }

     // Internal helper to remove token from delegated list for an address
    function _removeTokenFromDelegatedList(address delegatee, uint256 tokenId) internal {
        uint256 index = _delegatedTokenIndex[tokenId];
        uint256 lastIndex = _delegatedTokensByAddress[delegatee].length - 1;
        uint256 lastTokenId = _delegatedTokensByAddress[delegatee][lastIndex];

        // Move the last token to the removed token's position
        _delegatedTokensByAddress[delegatee][index] = lastTokenId;
        _delegatedTokenIndex[lastTokenId] = index;

        // Remove the last element
        _delegatedTokensByAddress[delegatee].pop();

        delete _delegatedTokenIndex[tokenId];
    }


    // --- AI Processing Interaction ---

    // Request off-chain AI processing for a specific staked NFT
    // Requires payment of `processorFee`. Can be called by the staked owner or the delegatee.
    function requestAIProcessing(uint256 tokenId, string memory dataHash) public payable whenNotPaused onlyStakedOwnerOrDelegatee(tokenId) {
        if (msg.value < processorFee) {
            revert InsufficientFee(processorFee, msg.value);
        }

        // Increment request counter and map it to the token ID
        _processingRequestCounter.increment();
        uint256 requestId = _processingRequestCounter.current();
        _processingRequestIdToTokenId[requestId] = tokenId;

        // Note: The actual data referenced by dataHash is OFF-CHAIN.
        // This event signals the oracle to perform computation using the NFT's
        // current state (_tokenData[tokenId].capabilityScore) and the provided dataHash.
        emit AIProcessingRequested(requestId, tokenId, msg.sender, dataHash);

        // The received ETH fee stays in the contract balance for the owner to withdraw
    }

    // Callback function for the trusted oracle to report AI processing results
    // This function is expected to be called by the `oracleAddress`.
    // It updates the NFT's dynamic state based on the processing outcome.
    function fulfillAIProcessing(uint256 requestId, uint256 tokenId, uint256 outputScore, string memory outputDataHash) public onlyOracle {
        // Basic validation
        if (!_exists(tokenId)) {
             // Log this error? Or ignore? Depends on desired behavior if token was burned after request
            return;
        }

        // Optionally check if the request ID is valid/outstanding if tracking state more rigorously
        // E.g., require(_processingRequestIdToTokenId[requestId] == tokenId, "Invalid request ID");
        // delete _processingRequestIdToTokenId[requestId]; // Clean up the request ID

        // Update the NFT's dynamic state
        // The oracle provides the new capability score and confirms usage.
        _updateNFTState(tokenId, outputScore, 1); // Increment usage count by 1

        // Also update the currentDataHash if needed
        _tokenData[tokenId].currentDataHash = keccak256(abi.encodePacked(outputDataHash));

        // Calculate and add pending rewards for the original owner
        // Processing contributes to rewards for the staked owner
        address originalOwner = _originalOwners[tokenId];
        if (originalOwner != address(0)) {
            _calculateAndAddPendingRewards(originalOwner, tokenId);
        }

        emit AIProcessingFulfilled(requestId, tokenId, outputScore, outputDataHash);
    }

    // --- Reward System Logic (Simplified Accrual) ---

    // Calculate and add pending rewards for a specific token belonging to an owner
    function _calculateAndAddPendingRewards(address owner, uint256 tokenId) internal {
         NFTData storage data = _tokenData[tokenId];
         uint256 blocksStaked = block.number.sub(data.lastRewardUpdateBlock);

         // Prevent calculation if the token wasn't staked or has 0 rate
         if (!_isStaked[tokenId] || rewardRate == 0 || blocksStaked == 0) {
             data.lastRewardUpdateBlock = block.number; // Just update the block
             return;
         }

         // Simple reward calculation: blocks staked * reward rate * capability score (as a multiplier/factor)
         // A more complex system might involve total stake, usage, etc.
         uint256 rewardsEarned = blocksStaked.mul(rewardRate).mul(data.capabilityScore);

         // Add to total pending rewards for the owner
         // We need a separate mapping for total pending rewards per owner,
         // as the tokenData only stores per-token pending rewards if we were to compound.
         // Let's adjust to track total pending rewards per owner directly.

         // Re-structuring rewards: total pending per owner
         // We need a mapping from owner address to total pending rewards
         _totalPendingRewards[owner] = _totalPendingRewards[owner].add(rewardsEarned);

         // Update the last reward update block for the token
         data.lastRewardUpdateBlock = block.number;
    }

    // Mapping from owner address to total accumulated pending rewards
    mapping(address => uint256) private _totalPendingRewards;

    // Get the total pending rewards for an owner across all their staked tokens
    function getPendingRewards(address owner) public view returns (uint256) {
        // Note: This view function does *not* update the state or calculate *new* rewards accrued since the last update.
        // It only returns the value of the _totalPendingRewards mapping.
        // To get an up-to-date pending rewards amount, you'd need a function that calculates
        // rewards for *all* staked tokens of the owner first, then sums them up,
        // which can be gas-expensive.
        // The current implementation calculates and adds rewards when staking, unstaking, or fulfilling processing.
        return _totalPendingRewards[owner];
    }

    // Claim accumulated rewards
    function claimRewards() public whenNotPaused {
        // First, calculate and add any rewards accrued since the last update for *all* staked tokens of the caller
        uint256[] memory stakedTokens = _stakedTokensOfOwner[msg.sender];
        for (uint i = 0; i < stakedTokens.length; i++) {
            _calculateAndAddPendingRewards(msg.sender, stakedTokens[i]);
        }

        uint256 amount = _totalPendingRewards[msg.sender];
        if (amount == 0) {
            revert NoPendingRewards(msg.sender);
        }

        // Reset pending rewards to zero before sending
        _totalPendingRewards[msg.sender] = 0;

        // In a real system, you would transfer an ERC20 reward token here.
        // For this example, we'll just emit an event showing the amount.
        // Assume a function like `IERC20(rewardTokenAddress).transfer(msg.sender, amount);`
        // Replace with actual token transfer logic:
        // require(IERC20(rewardTokenAddress).transfer(msg.sender, amount), "Reward token transfer failed");

        emit RewardsClaimed(msg.sender, amount);
    }


    // --- Admin / Utility Functions ---

    // Set the trusted oracle address (Owner only)
    function setOracleAddress(address _oracle) public onlyOwner {
        if (_oracle == address(0)) revert InvalidOracleAddress(_oracle);
        emit OracleAddressSet(oracleAddress, _oracle);
        oracleAddress = _oracle;
    }

    // Set the fee required to request AI processing (Owner only)
    function setProcessorFee(uint256 _fee) public onlyOwner {
        emit ProcessorFeeSet(processorFee, _fee);
        processorFee = _fee;
    }

    // Set the base reward rate per staked token per block (Owner only)
    function setRewardRate(uint256 _rate) public onlyOwner {
         emit RewardRateSet(rewardRate, _rate);
        rewardRate = _rate;
    }

    // Allow owner to withdraw accumulated ETH fees (Owner only)
    function withdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        // Using address.sendValue recommended by OpenZeppelin
        address payable ownerPayable = payable(owner());
        ownerPayable.sendValue(balance);
    }

    // Pause certain operations (minting, staking, requests, claims) (Owner only)
    function pause() public onlyOwner {
        _pause();
    }

    // Unpause the contract (Owner only)
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- ERC165 Support ---
    // ERC721Enumerable, ERC721URIStorage, Ownable, Pausable handle their own interfaces.
    // We also explicitly state support for ERC721.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
         // Add specific interfaces if custom ones were defined (e.g., for staking/delegation)
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
             super.supportsInterface(interfaceId);
    }

    // --- Internal Minting Function ---
    // Used by the constructor and potentially the owner
    function _mint(address to, uint256 initialCapability) internal whenNotPaused {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId); // Handles ERC721 minting internally

        // Initialize dynamic data for the new token
        _tokenData[newTokenId] = NFTData({
            capabilityScore: initialCapability,
            usageCount: 0,
            lastProcessedBlock: block.number, // Or 0
            lastRewardUpdateBlock: block.number, // Start earning potential rewards now if staked
            pendingRewards: 0,
            currentDataHash: bytes32(0)
        });

        emit NFTMinted(to, newTokenId, initialCapability);
    }

    // Public function for owner to mint
    function mint(address to, uint256 capabilityScore) public onlyOwner whenNotPaused {
        _mint(to, capabilityScore);
    }

    // Override _beforeTokenTransfer requires overriding _burn as well if used
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        // Ensure not staked or delegated before burning
         if (_isStaked[tokenId]) revert NFTAlreadyStaked(tokenId); // Using same error, token is effectively 'staked' in contract
         if (_delegatedTo[tokenId] != address(0)) revert DelegationAlreadyExists(tokenId);

        super._burn(tokenId);
        // Clean up internal data
        delete _tokenData[tokenId];
        delete _originalOwners[tokenId]; // Should not be set if not staked, but good practice
        delete _isStaked[tokenId];
        delete _delegatedTo[tokenId];
        // Delegation list removal handled in undelegate if it was delegated
        // Staked list removal handled in unstake if it was staked
    }

    // Allow owner to burn tokens (careful!)
    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }
}
```