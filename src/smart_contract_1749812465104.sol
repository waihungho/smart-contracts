Okay, let's create a smart contract called `QuantumLeapNFT`. This contract will feature NFTs that can "Leap" between different "Dimensions" (states). This leaping action can be triggered by the owner, consumes resources, is subject to cooldowns, and its outcome can be influenced by chance. Additionally, the NFTs can hold resources, generate passive income (in resources), and even merge with other NFTs. This combines dynamic NFTs, resource management, probabilistic outcomes, time-based mechanics, and a unique interaction (merging) into a single system.

We will avoid direct copies of standard ERC implementations or common DeFi patterns like simple staking/swapping.

---

**Contract Name:** QuantumLeapNFT

**Concept:** Dynamic, evolving NFTs (`QuantumLeapNFT`) that can transition between different states ("Dimensions") through a process called "Leaping". Leaping costs resources (an associated ERC-20 token, "QuantumEssence"), is subject to cooldowns, and involves a probabilistic outcome that determines the next Dimension. NFTs can also passively generate QuantumEssence, hold deposited resources, and be merged to combine their properties.

**Outline:**

1.  **Imports:** ERC721, Ownable, ReentrancyGuard, SafeERC20, IERC20.
2.  **Errors:** Custom errors for clearer failures.
3.  **Enums:** `Dimension` enum representing possible states.
4.  **Structs:** `QuantumLeapNFTData` to hold state and dynamic properties per NFT.
5.  **State Variables:**
    *   Standard ERC721 data.
    *   Mapping for `QuantumLeapNFTData`.
    *   Resource Token address (`quantumEssenceToken`).
    *   Mapping to track resource balance *held by the NFT* (`nftResourceBalances`).
    *   Parameters for costs, cooldowns, generation rates, probabilities.
    *   Minter role management.
    *   Pausable state.
    *   Base URI for metadata.
    *   Nonce for pseudo-randomness (note: requires Chainlink VRF or similar for true security).
6.  **Events:** Signify key actions (Mint, Leap, DimensionAttuned, Merge, Deposit, Withdraw, Harvest, Param Updates).
7.  **Modifiers:** Access control (`onlyOwner`, `onlyMinter`), state checks (`whenNotPaused`, `canLeap`).
8.  **Constructor:** Initialize ERC721, set owner, set resource token, initial parameters.
9.  **Core ERC721 Functions:**
    *   `tokenURI`: Dynamic metadata based on NFT state.
10. **Minter Functions:**
    *   `mint`: Create a new NFT.
    *   `batchMint`: Create multiple NFTs.
11. **NFT Interaction Functions:**
    *   `leap`: Trigger the probabilistic state change process.
    *   `attuneToDimension`: Attempt to force a specific state change with a success chance.
    *   `mergeNFTs`: Combine two NFTs into one.
    *   `depositResource`: Deposit QuantumEssence into the NFT's internal balance.
    *   `withdrawResource`: Withdraw QuantumEssence from the NFT's internal balance.
    *   `harvestEssence`: Collect passively generated QuantumEssence.
12. **Query/View Functions:**
    *   `getNFTData`: Get full data for an NFT.
    *   `getCurrentDimension`: Get current state.
    *   `getTimeUntilLeap`: Check remaining cooldown.
    *   `getNFTResourceBalance`: Check resource balance held by NFT.
    *   `calculatePendingEssence`: Calculate passively generated essence available to harvest.
    *   `getLeapCost`: Get current leap cost.
    *   `getLeapCooldown`: Get current leap cooldown.
    *   `getEssenceGenerationRate`: Get current generation rate.
13. **Parameter/Admin Functions (onlyOwner):**
    *   `setLeapCost`.
    *   `setLeapCooldown`.
    *   `setEssenceGenerationRate`.
    *   `setAttunementCost`.
    *   `setAttunementSuccessRate`.
    *   `setMergeCost`.
    *   `addMinter`.
    *   `removeMinter`.
    *   `setBaseURI`.
    *   `pause`.
    *   `unpause`.
    *   `withdrawStuckTokens` (ERC20).
    *   `withdrawStuckETH`.
14. **Internal Functions:**
    *   `_performLeapLogic`: Handles state transition based on outcome.
    *   `_performAttunementLogic`: Handles attunement state transition.
    *   `_calculateEssenceGenerated`: Helper for passive generation.
    *   `_generatePseudoRandomOutcome`: Placeholder for randomness (needs VRF for production).
    *   Standard ERC721 internal functions (`_safeTransfer`, `_beforeTokenTransfer`, etc.).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Custom Errors
error QuantumLeapNFT__InvalidTokenId();
error QuantumLeapNFT__UnauthorizedMinter();
error QuantumLeapNFT__LeapCooldownActive(uint256 timeRemaining);
error QuantumLeapNFT__InsufficientResource(uint256 required, uint256 available);
error QuantumLeapNFT__AttunementFailed();
error QuantumLeapNFT__MergeConditionsNotMet();
error QuantumLeapNFT__CannotDepositZero();
error QuantumLeapNFT__CannotWithdrawZero();
error QuantumLeapNFT__InsufficientNFTResource(uint256 required, uint256 available);
error QuantumLeapNFT__CannotWithdrawFromNFTIfNotOwner();
error QuantumLeapNFT__CannotMergeWithSelf();
error QuantumLeapNFT__CannotMergeIfNotOwnerOfBoth();
error QuantumLeapNFT__RecipientIsZeroAddress();
error QuantumLeapNFT__CannotTransferToSelf();

contract QuantumLeapNFT is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    // --- State Definitions ---
    enum Dimension {
        PrimalVoid,      // Starting state
        ChronoBloom,     // Time-sensitive properties
        AetherDrift,     // Resource generation boosted
        KineticSurge,    // Leap costs reduced
        SyntacticNexus,  // Can merge more easily
        EntropySink      // Resource generation reduced, riskier leaps
    }

    // --- Structs ---
    struct QuantumLeapNFTData {
        Dimension currentDimension;
        uint66 lastLeapTime; // Use uint66 for timestamp up to ~2^64 seconds (far in future)
        uint66 lastHarvestTime; // Timestamp of last resource harvest
        uint64 leapCount; // How many times this NFT has leaped
        uint64 mergeCount; // How many times this NFT has been merged *into* another
        // Future fields could include: unique traits, stats modified by dimension/leaps
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => QuantumLeapNFTData) private _nftsData;
    mapping(address => bool) private _minters;
    address public immutable quantumEssenceToken; // The associated ERC-20 resource token

    // Resources held *by* the NFT, indexed by tokenId
    mapping(uint256 => uint256) private _nftResourceBalances;

    // Parameters (configurable by owner)
    uint256 public leapCost; // Cost in QuantumEssence to perform a leap
    uint256 public leapCooldown; // Time in seconds before next leap is possible
    uint256 public essenceGenerationRate; // Essence generated per second
    uint256 public attunementCost; // Cost in QuantumEssence for attunement attempt
    uint256 public attunementSuccessRate; // Probability (0-10000, e.g., 5000 for 50%)
    uint256 public mergeCost; // Cost in QuantumEssence to merge two NFTs

    uint256 private _pseudoRandomNonce; // For internal, insecure randomness example

    string private _baseTokenURI;

    // --- Events ---
    event NFTMinted(uint256 indexed tokenId, address indexed owner, Dimension initialDimension);
    event NFTLeaped(uint256 indexed tokenId, Dimension fromDimension, Dimension toDimension, uint64 leapCount);
    event DimensionAttuned(uint256 indexed tokenId, Dimension fromDimension, Dimension toDimension, bool successful);
    event NFTsMerged(uint256 indexed primaryTokenId, uint256 indexed secondaryTokenId, address indexed newOwner);
    event ResourceDeposited(uint256 indexed tokenId, address indexed depositor, uint256 amount);
    event ResourceWithdrawal(uint256 indexed tokenId, address indexed receiver, uint256 amount);
    event EssenceHarvested(uint256 indexed tokenId, address indexed receiver, uint256 amount);
    event ParameterUpdated(string paramName, uint256 newValue);
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    // --- Modifiers ---
    modifier onlyMinter() {
        if (!_minters[msg.sender]) {
            revert QuantumLeapNFT__UnauthorizedMinter();
        }
        _;
    }

    modifier canLeap(uint256 tokenId) {
        if (!_exists(tokenId)) {
             revert QuantumLeapNFT__InvalidTokenId();
        }
        uint256 timeSinceLastLeap = block.timestamp - _nftsData[tokenId].lastLeapTime;
        if (timeSinceLastLeap < leapCooldown) {
            revert QuantumLeapNFT__LeapCooldownActive(leapCooldown - timeSinceLastLeap);
        }
        _;
    }

    // --- Constructor ---
    constructor(
        address initialOwner,
        address _quantumEssenceToken,
        uint256 _leapCost,
        uint256 _leapCooldown,
        uint256 _essenceGenerationRate,
        uint256 _attunementCost,
        uint256 _attunementSuccessRate,
        uint256 _mergeCost
    ) ERC721("Quantum Leap NFT", "QLNFT") Ownable(initialOwner) Pausable(false) {
        if (_quantumEssenceToken == address(0)) {
            revert QuantumLeapNFT__RecipientIsZeroAddress();
        }
        quantumEssenceToken = _quantumEssenceToken;

        leapCost = _leapCost;
        leapCooldown = _leapCooldown;
        essenceGenerationRate = _essenceGenerationRate;
        attunementCost = _attunementCost;
        attunementSuccessRate = _attunementSuccessRate; // Expected 0-10000
        mergeCost = _mergeCost;

        _minters[initialOwner] = true; // Owner is also a minter by default
        _pseudoRandomNonce = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, initialOwner))); // Simple seed
    }

    // --- Core ERC721 Overrides ---

    /// @dev Returns the base URI for token metadata. Overridden to include base URI.
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev Returns the token URI for a given token ID. Should point to metadata service.
    /// The metadata service should query the contract state to provide dynamic JSON.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert QuantumLeapNFT__InvalidTokenId();
        }
        string memory base = _baseURI();
        // In a real application, this should likely include state data or point
        // to a service that fetches state data to build dynamic metadata.
        // Example: A service at baseURI would listen for NFT state changes
        // and serve different JSON based on the current dimension.
        // For this example, we'll append the ID and the dimension name (conceptually).
        // A real impl would require off-chain service or Chainlink Any API/Functions.
        // string memory dimensionName = _getDimensionName(_nftsData[tokenId].currentDimension);
        // return string(abi.encodePacked(base, Strings.toString(tokenId), "-", dimensionName)); // Conceptual
        return string(abi.encodePacked(base, Strings.toString(tokenId))); // Simple example
    }

    // --- Minter Functions ---

    /// @notice Mints a new Quantum Leap NFT.
    /// @param to The address to mint the NFT to.
    /// @param initialDimension The starting dimension for the NFT.
    function mint(address to, Dimension initialDimension) public onlyMinter whenNotPaused {
        if (to == address(0)) {
             revert QuantumLeapNFT__RecipientIsZeroAddress();
        }
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _nftsData[newTokenId] = QuantumLeapNFTData({
            currentDimension: initialDimension,
            lastLeapTime: uint66(block.timestamp), // Can potentially leap immediately after mint
            lastHarvestTime: uint66(block.timestamp),
            leapCount: 0,
            mergeCount: 0
        });

        _safeMint(to, newTokenId);
        emit NFTMinted(newTokenId, to, initialDimension);
    }

    /// @notice Mints multiple Quantum Leap NFTs.
    /// @param to The address to mint the NFTs to.
    /// @param count The number of NFTs to mint.
    /// @param initialDimension The starting dimension for all minted NFTs.
    function batchMint(address to, uint256 count, Dimension initialDimension) public onlyMinter whenNotPaused {
         if (to == address(0)) {
             revert QuantumLeapNFT__RecipientIsZeroAddress();
         }
        for (uint256 i = 0; i < count; i++) {
            mint(to, initialDimension);
        }
    }

    // --- NFT Interaction Functions ---

    /// @notice Attempts to perform a "Leap" for the NFT, changing its dimension probabilistically.
    /// @dev Consumes resources and is subject to a cooldown. Outcome is pseudo-random in this example.
    /// @param tokenId The ID of the NFT to leap.
    function leap(uint256 tokenId) public payable nonReentrant whenNotPaused canLeap(tokenId) {
        address nftOwner = ownerOf(tokenId);
        if (msg.sender != nftOwner) {
             revert OwnableUnauthorizedAccount(msg.sender); // Using inherited error
        }

        // --- Resource Check and Consumption ---
        // This example uses resources held BY the NFT itself via depositResource
        // A different design could use resources held BY the owner (msg.sender)
        if (_nftResourceBalances[tokenId] < leapCost) {
             revert QuantumLeapNFT__InsufficientNFTResource(leapCost, _nftResourceBalances[tokenId]);
        }
        _nftResourceBalances[tokenId] -= leapCost;
        // Note: This uses internal balance. If using sender's balance:
        // IERC20(quantumEssenceToken).safeTransferFrom(msg.sender, address(this), leapCost);

        // --- Perform Leap Logic (Probabilistic) ---
        Dimension fromDimension = _nftsData[tokenId].currentDimension;
        Dimension toDimension = _performLeapLogic(tokenId); // Logic based on random outcome

        // --- Update NFT State ---
        _nftsData[tokenId].currentDimension = toDimension;
        _nftsData[tokenId].lastLeapTime = uint66(block.timestamp);
        _nftsData[tokenId].leapCount++;

        emit NFTLeaped(tokenId, fromDimension, toDimension, _nftsData[tokenId].leapCount);
    }

    /// @notice Attempts to force an NFT into a specific dimension with a success chance.
    /// @dev Consumes resources and is subject to a success rate parameter.
    /// @param tokenId The ID of the NFT to attune.
    /// @param targetDimension The dimension to attempt to attune to.
    function attuneToDimension(uint256 tokenId, Dimension targetDimension) public payable nonReentrant whenNotPaused {
         address nftOwner = ownerOf(tokenId);
         if (msg.sender != nftOwner) {
              revert OwnableUnauthorizedAccount(msg.sender);
         }
         if (!_exists(tokenId)) {
              revert QuantumLeapNFT__InvalidTokenId();
         }

         // Resource Check and Consumption
         if (_nftResourceBalances[tokenId] < attunementCost) {
              revert QuantumLeapNFT__InsufficientNFTResource(attunementCost, _nftResourceBalances[tokenId]);
         }
         _nftResourceBalances[tokenId] -= attunementCost;
         // If using sender's balance: IERC20(quantumEssenceToken).safeTransferFrom(msg.sender, address(this), attunementCost);


         // Perform Attunement Logic (Probabilistic Success)
         Dimension fromDimension = _nftsData[tokenId].currentDimension;
         bool success = _performAttunementLogic(tokenId, targetDimension);

         if (success) {
             _nftsData[tokenId].currentDimension = targetDimension;
             // Note: Attunement might not reset leap cooldown, depends on game design
             emit DimensionAttuned(tokenId, fromDimension, targetDimension, true);
         } else {
              emit DimensionAttuned(tokenId, fromDimension, _nftsData[tokenId].currentDimension, false);
              revert QuantumLeapNFT__AttunementFailed();
         }
    }

    /// @notice Merges a secondary NFT into a primary NFT.
    /// @dev Burns the secondary NFT. Transfers resources from secondary to primary. Can have a cost.
    /// @param primaryTokenId The ID of the NFT to merge into (this one survives).
    /// @param secondaryTokenId The ID of the NFT to be merged (this one is burned).
    function mergeNFTs(uint256 primaryTokenId, uint256 secondaryTokenId) public payable nonReentrant whenNotPaused {
        if (!_exists(primaryTokenId) || !_exists(secondaryTokenId)) {
             revert QuantumLeapNFT__InvalidTokenId();
        }
        if (primaryTokenId == secondaryTokenId) {
             revert QuantumLeapNFT__CannotMergeWithSelf();
        }

        address primaryOwner = ownerOf(primaryTokenId);
        address secondaryOwner = ownerOf(secondaryTokenId);

        if (msg.sender != primaryOwner || msg.sender != secondaryOwner) {
             revert QuantumLeapNFT__CannotMergeIfNotOwnerOfBoth();
        }

        // Check merge cost (using primary NFT's balance)
         if (_nftResourceBalances[primaryTokenId] < mergeCost) {
              revert QuantumLeapNFT__InsufficientNFTResource(mergeCost, _nftResourceBalances[primaryTokenId]);
         }
         _nftResourceBalances[primaryTokenId] -= mergeCost;
         // If using sender's balance: IERC20(quantumEssenceToken).safeTransferFrom(msg.sender, address(this), mergeCost);


        // --- Perform Merge Logic ---
        // This could involve combining properties, boosting stats, or changing primary's dimension
        // For this example, we simply transfer resources and increment merge count
        uint256 secondaryResources = _nftResourceBalances[secondaryTokenId];
        if (secondaryResources > 0) {
            _nftResourceBalances[primaryTokenId] += secondaryResources;
            _nftResourceBalances[secondaryTokenId] = 0; // Clear secondary's balance
        }

        _nftsData[primaryTokenId].mergeCount++; // Primary NFT records it has absorbed one

        // Burn the secondary NFT
        _burn(secondaryTokenId);
        delete _nftsData[secondaryTokenId]; // Clear its data

        emit NFTsMerged(primaryTokenId, secondaryTokenId, msg.sender);
    }

    /// @notice Deposits QuantumEssence tokens into the contract, allocated to a specific NFT's balance.
    /// @dev Requires msg.sender to have approved the contract to spend the tokens.
    /// @param tokenId The ID of the NFT to deposit resources for.
    /// @param amount The amount of QuantumEssence to deposit.
    function depositResource(uint256 tokenId, uint256 amount) public payable nonReentrant whenNotPaused {
         if (!_exists(tokenId)) {
              revert QuantumLeapNFT__InvalidTokenId();
         }
         if (amount == 0) {
             revert QuantumLeapNFT__CannotDepositZero();
         }

         // Ensure the depositor owns the NFT (or add allowance logic if others can deposit)
         // For simplicity, only owner can deposit into their NFT's balance
         address nftOwner = ownerOf(tokenId);
         if (msg.sender != nftOwner) {
             revert OwnableUnauthorizedAccount(msg.sender);
         }

        IERC20(quantumEssenceToken).safeTransferFrom(msg.sender, address(this), amount);
        _nftResourceBalances[tokenId] += amount;

        emit ResourceDeposited(tokenId, msg.sender, amount);
    }

    /// @notice Withdraws QuantumEssence tokens from an NFT's internal balance.
    /// @param tokenId The ID of the NFT to withdraw resources from.
    /// @param amount The amount of QuantumEssence to withdraw.
    function withdrawResource(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused {
         if (!_exists(tokenId)) {
              revert QuantumLeapNFT__InvalidTokenId();
         }
          if (amount == 0) {
             revert QuantumLeapNFT__CannotWithdrawZero();
         }

         // Ensure only the owner can withdraw
         address nftOwner = ownerOf(tokenId);
         if (msg.sender != nftOwner) {
             revert QuantumLeapNFT__CannotWithdrawFromNFTIfNotOwner();
         }

         if (_nftResourceBalances[tokenId] < amount) {
             revert QuantumLeapNFT__InsufficientNFTResource(amount, _nftResourceBalances[tokenId]);
         }

         _nftResourceBalances[tokenId] -= amount;
         IERC20(quantumEssenceToken).safeTransfer(msg.sender, amount);

         emit ResourceWithdrawal(tokenId, msg.sender, amount);
    }

     /// @notice Allows the NFT owner to harvest passively generated QuantumEssence.
    /// @param tokenId The ID of the NFT to harvest from.
    function harvestEssence(uint256 tokenId) public nonReentrant whenNotPaused {
         if (!_exists(tokenId)) {
              revert QuantumLeapNFT__InvalidTokenId();
         }
         address nftOwner = ownerOf(tokenId);
         if (msg.sender != nftOwner) {
              revert OwnableUnauthorizedAccount(msg.sender);
         }

        uint256 pendingEssence = _calculateEssenceGenerated(tokenId);

        if (pendingEssence > 0) {
            _nftsData[tokenId].lastHarvestTime = uint66(block.timestamp);
            // Add generated essence to the NFT's internal balance
            _nftResourceBalances[tokenId] += pendingEssence;
            // Note: Resources are added to internal balance, then owner can withdraw
            // Alternatively, transfer directly to owner: IERC20(quantumEssenceToken).safeTransfer(msg.sender, pendingEssence);

            emit EssenceHarvested(tokenId, msg.sender, pendingEssence);
        }
        // No explicit error if 0, just nothing happens
    }


    // --- Query / View Functions ---

    /// @notice Get all Quantum Leap NFT data for a token ID.
    function getNFTData(uint256 tokenId) public view returns (QuantumLeapNFTData memory) {
        if (!_exists(tokenId)) {
             revert QuantumLeapNFT__InvalidTokenId();
        }
        return _nftsData[tokenId];
    }

    /// @notice Get the current dimension of an NFT.
    function getCurrentDimension(uint256 tokenId) public view returns (Dimension) {
         if (!_exists(tokenId)) {
              revert QuantumLeapNFT__InvalidTokenId();
         }
        return _nftsData[tokenId].currentDimension;
    }

    /// @notice Calculate the time remaining until an NFT can leap again.
    function getTimeUntilLeap(uint256 tokenId) public view returns (uint256 timeRemaining) {
         if (!_exists(tokenId)) {
              revert QuantumLeapNFT__InvalidTokenId();
         }
        uint256 lastLeap = _nftsData[tokenId].lastLeapTime;
        if (block.timestamp >= lastLeap + leapCooldown) {
            return 0;
        } else {
            return (lastLeap + leapCooldown) - block.timestamp;
        }
    }

     /// @notice Get the resource balance held by a specific NFT.
    function getNFTResourceBalance(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
              revert QuantumLeapNFT__InvalidTokenId();
         }
        return _nftResourceBalances[tokenId];
    }

    /// @notice Calculate the amount of passively generated essence available to harvest.
    function calculatePendingEssence(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
              revert QuantumLeapNFT__InvalidTokenId();
         }
         return _calculateEssenceGenerated(tokenId);
    }

    /// @notice Check if an address is a minter.
    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }

    /// @notice Get the current leap cost.
    function getLeapCost() public view returns (uint256) {
        return leapCost;
    }

     /// @notice Get the current leap cooldown.
    function getLeapCooldown() public view returns (uint256) {
        return leapCooldown;
    }

     /// @notice Get the current essence generation rate.
    function getEssenceGenerationRate() public view returns (uint256) {
        return essenceGenerationRate;
    }

     /// @notice Get the current attunement cost.
    function getAttunementCost() public view returns (uint256) {
        return attunementCost;
    }

    /// @notice Get the current attunement success rate (0-10000).
    function getAttunementSuccessRate() public view returns (uint256) {
        return attunementSuccessRate;
    }

    /// @notice Get the current merge cost.
    function getMergeCost() public view returns (uint256) {
        return mergeCost;
    }


    // --- Parameter / Admin Functions (onlyOwner) ---

    /// @notice Sets the cost in QuantumEssence for performing a leap.
    function setLeapCost(uint256 _newCost) public onlyOwner {
        leapCost = _newCost;
        emit ParameterUpdated("leapCost", _newCost);
    }

     /// @notice Sets the cooldown period in seconds between leaps.
    function setLeapCooldown(uint256 _newCooldown) public onlyOwner {
        leapCooldown = _newCooldown;
        emit ParameterUpdated("leapCooldown", _newCooldown);
    }

     /// @notice Sets the rate of passive QuantumEssence generation per second.
    function setEssenceGenerationRate(uint256 _newRate) public onlyOwner {
        essenceGenerationRate = _newRate;
        emit ParameterUpdated("essenceGenerationRate", _newRate);
    }

     /// @notice Sets the cost in QuantumEssence for attempting dimension attunement.
    function setAttunementCost(uint256 _newCost) public onlyOwner {
        attunementCost = _newCost;
        emit ParameterUpdated("attunementCost", _newCost);
    }

     /// @notice Sets the success rate (0-10000) for dimension attunement attempts.
    function setAttunementSuccessRate(uint256 _newRate) public onlyOwner {
        if (_newRate > 10000) revert("Rate cannot exceed 10000");
        attunementSuccessRate = _newRate;
        emit ParameterUpdated("attunementSuccessRate", _newRate);
    }

    /// @notice Sets the cost in QuantumEssence for merging two NFTs.
    function setMergeCost(uint256 _newCost) public onlyOwner {
        mergeCost = _newCost;
        emit ParameterUpdated("mergeCost", _newCost);
    }

    /// @notice Adds an address to the list of authorized minters.
    function addMinter(address account) public onlyOwner {
        if (account == address(0)) revert QuantumLeapNFT__RecipientIsZeroAddress();
        _minters[account] = true;
        emit MinterAdded(account);
    }

    /// @notice Removes an address from the list of authorized minters.
    function removeMinter(address account) public onlyOwner {
        if (account == address(0)) revert QuantumLeapNFT__RecipientIsZeroAddress();
        _minters[account] = false;
        emit MinterRemoved(account);
    }

    /// @notice Sets the base URI for the token metadata.
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit ParameterUpdated("baseTokenURI", 0); // Using 0 as value isn't relevant for string
    }

    /// @notice Pauses the contract, preventing most state-changing operations.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing operations again.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw any ERC20 tokens (other than the main resource token)
    /// accidentally sent to the contract.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    /// @param amount The amount to withdraw.
    function withdrawStuckTokens(address tokenAddress, uint256 amount) public onlyOwner nonReentrant {
        if (tokenAddress == address(0)) revert QuantumLeapNFT__RecipientIsZeroAddress();
         // Prevent withdrawing the main resource token this way, use specific functions if needed
        if (tokenAddress == quantumEssenceToken) revert("Cannot withdraw primary resource token via this function");
        IERC20 stuckToken = IERC20(tokenAddress);
        stuckToken.safeTransfer(owner(), amount);
    }

    /// @notice Allows the owner to withdraw any ETH accidentally sent to the contract.
    function withdrawStuckETH() public onlyOwner nonReentrant {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }


    // --- Internal Helper Functions ---

    /// @dev Internal logic for determining the outcome of a Leap.
    /// @param tokenId The ID of the NFT performing the leap.
    /// @return The dimension the NFT transitions to.
    function _performLeapLogic(uint256 tokenId) internal returns (Dimension) {
        // IMPORTANT: This pseudo-randomness is INSECURE and for demonstration only.
        // For production, use Chainlink VRF or similar verifiable randomness.
        uint256 randomness = _generatePseudoRandomOutcome();

        Dimension currentDim = _nftsData[tokenId].currentDimension;
        uint256 numDimensions = uint256(type(Dimension).max) + 1;

        // Example Leap Logic: Cycle dimensions, with a chance to skip or jump
        uint256 currentDimIndex = uint256(currentDim);
        uint256 nextDimIndex = (currentDimIndex + 1) % numDimensions; // Default: simple cycle

        // Introduce pseudo-random variation
        if (randomness % 100 < 20) { // 20% chance of different outcome
            nextDimIndex = randomness % numDimensions; // Jump to a random dimension
        } else if (randomness % 100 < 30) { // 10% chance to stay in same dimension
             nextDimIndex = currentDimIndex;
        }
        // More complex logic could factor in currentDim, leapCount, held resources, etc.

        return Dimension(nextDimIndex);
    }

    /// @dev Internal logic for determining the success and outcome of an Attunement attempt.
    /// @param tokenId The ID of the NFT.
    /// @param targetDimension The desired dimension.
    /// @return True if attunement succeeded, false otherwise.
    function _performAttunementLogic(uint256 tokenId, Dimension targetDimension) internal returns (bool) {
         // IMPORTANT: This pseudo-randomness is INSECURE and for demonstration only.
        uint256 randomness = _generatePseudoRandomOutcome();

        uint256 randomThreshold = randomness % 10001; // Get a number between 0 and 10000

        // Success if random number is below the configured rate
        bool success = randomThreshold < attunementSuccessRate;

        // More complex logic could make certain attunements harder/easier based on dimensions
        // or other NFT properties.

        return success;
    }


    /// @dev Calculates the amount of QuantumEssence generated since the last harvest.
    function _calculateEssenceGenerated(uint256 tokenId) internal view returns (uint256) {
        uint256 lastHarvest = _nftsData[tokenId].lastHarvestTime;
        if (lastHarvest == 0 || essenceGenerationRate == 0) {
            return 0; // Not yet harvested or rate is zero
        }
        uint256 timeElapsed = block.timestamp - lastHarvest;
        return timeElapsed * essenceGenerationRate;
    }

    /// @dev Generates a basic pseudo-random number. INSECURE for production.
    /// @dev Use Chainlink VRF, API3 QRNG, or similar for production applications.
    function _generatePseudoRandomOutcome() internal returns (uint256) {
        _pseudoRandomNonce++;
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _pseudoRandomNonce)));
        return randomness;
    }

    // --- Overrides for Pausability ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Add custom checks if needed before transfer (e.g., can't transfer in certain dimensions)
         if (to == address(0)) {
             revert QuantumLeapNFT__RecipientIsZeroAddress();
         }
         if (from != address(0) && to != address(0) && from == to) {
             revert QuantumLeapNFT__CannotTransferToSelf();
         }
    }

    // The following ERC721 functions are inherited and work as expected:
    // approve, getApproved, isApprovedForAll, setApprovalForAll, transferFrom, safeTransferFrom

    // --- ERC165 Support (already included via ERC721) ---
    // function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }

}
```

---

**Explanation of Advanced/Interesting Concepts:**

1.  **Dynamic State (Dimensions):** The `Dimension` enum and the `currentDimension` field make the NFT's state mutable on-chain. This allows for NFTs that visually or functionally change over time or interaction.
2.  **Probabilistic Evolution (`leap`):** The `leap` function introduces chance into the NFT's evolution. While the pseudo-randomness here is insecure for production, the *concept* of an on-chain asset whose properties can change based on a provably fair random outcome (via VRF) is powerful for games, collectibles, etc.
3.  **Resource Sink/Faucet (`depositResource`, `harvestEssence`, `leapCost`, `attunementCost`, `mergeCost`):** Integrates an associated ERC-20 token ("QuantumEssence") as a key part of the NFT's mechanics. Essence is required for actions (sink) and generated passively (faucet), creating a simple internal economy centered around the NFTs.
4.  **Internal Resource Balance (`_nftResourceBalances`):** Instead of resources being held *only* by the NFT owner, tokens can be deposited *into* the contract, allocated to a specific NFT. This makes the NFT itself a container for value and resources, enabling mechanics like "an NFT carrying X resource".
5.  **Time-Based Mechanics (`leapCooldown`, `essenceGenerationRate`, `lastLeapTime`, `lastHarvestTime`):** Incorporates the concept of time passing on the blockchain to gate actions and generate value.
6.  **Unique Interaction (`mergeNFTs`):** The ability to merge two NFTs into one, transferring value and state, is a creative mechanic not found in standard ERC templates. It allows for deflationary mechanisms and combining/evolving collections.
7.  **Attunement (`attuneToDimension`):** Offers an alternative, potentially less random, way to influence state, but still with a probabilistic success rate and cost, adding strategic depth.
8.  **Role-Based Access (`onlyMinter`):** While `Ownable` is standard, adding a separate `Minter` role is a common but important pattern for managing contract privileges more granularly.
9.  **Pausability:** Standard but crucial for emergency situations in complex contracts.
10. **Dynamic Metadata URI:** `tokenURI` is overridden to suggest that the metadata should be dynamic and potentially change based on the NFT's `currentDimension` and other state variables (requiring an off-chain service or Chainlink Functions/AnyAPI for a full implementation).

This contract provides a framework for dynamic, interactive NFTs with internal resource mechanics and unique state-changing abilities, going beyond simple static image collectibles. Remember that the pseudo-randomness needs to be replaced with a secure solution for any real-world application.