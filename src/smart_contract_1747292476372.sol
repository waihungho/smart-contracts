Okay, let's design a concept smart contract called `QuantumFluctuationsMarketplace`. This contract will represent a marketplace for unique digital "Essences" that have dynamic properties that "fluctuate" based on interactions, time, and simulated quantum-like phenomena (using on-chain data for pseudo-randomness). It incorporates concepts like dynamic NFTs, simulated state evolution, entanglement, and interactive mechanics.

We will implement the core ERC-721 interface ourselves rather than inheriting directly from OpenZeppelin to ensure we are not just duplicating open-source code implementation, while still being ERC-721 compatible.

**Concept:** Users can create and own unique "Quantum Essences". These essences have properties like `fluxLevel` and `stabilityScore` which change over time and through interactions (`observe`, `interact`). Essences can become "entangled", linking their states. They can potentially "evolve" if conditions are met. A marketplace allows trading these dynamic assets.

---

## **QuantumFluctuationsMarketplace: Smart Contract Outline & Function Summary**

This contract manages unique digital assets called "Quantum Essences" with dynamic properties and a marketplace for trading them.

**Outline:**

1.  **Contract Definition:** Basic info, state variables, enums, structs.
2.  **ERC-721 Interface Implementation:** Core NFT functionality (ownership, transfers, approvals).
3.  **Essence State Management:** Functions to update, observe, and interact with Essence properties.
4.  **Entanglement Mechanics:** Functions to link and unlink Essence states.
5.  **Evolution Mechanics:** Functions to trigger potential Essence evolution.
6.  **Marketplace:** Functions for listing, buying, and cancelling Essence listings.
7.  **Utility & Admin:** Helper functions and owner-specific controls.

**Function Summary:**

*   **ERC-721 Core (Implemented):**
    *   `balanceOf(address owner)`: Get the number of Essences owned by an address.
    *   `ownerOf(uint256 essenceId)`: Get the owner of a specific Essence.
    *   `approve(address to, uint256 essenceId)`: Approve another address to transfer a specific Essence.
    *   `getApproved(uint256 essenceId)`: Get the approved address for a specific Essence.
    *   `setApprovalForAll(address operator, bool approved)`: Set approval for an operator for all owner's Essences.
    *   `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for an owner.
    *   `transferFrom(address from, address to, uint256 essenceId)`: Transfer ownership of an Essence (checked transfer).
    *   `safeTransferFrom(address from, address to, uint256 essenceId)`: Safely transfer ownership (checks if recipient is a contract capable of receiving ERC-721).
    *   `safeTransferFrom(address from, address to, uint256 essenceId, bytes data)`: Safely transfer with additional data.
*   **Essence Creation & Base Management:**
    *   `createEssence()`: Mints a new Quantum Essence. Requires a fee. Initial properties are set.
    *   `getEssenceDetails(uint256 essenceId)`: Retrieve the current detailed state of an Essence. Automatically updates state if necessary.
    *   `burnEssence(uint256 essenceId)`: Destroys a Quantum Essence. Requires ownership.
    *   `getTotalEssences()`: Returns the total number of Essences ever created.
    *   `getEssencesOwnedBy(address owner)`: Returns a list of Essence IDs owned by an address (Note: Can be gas-intensive for many tokens).
*   **Essence State Manipulation (Dynamic/Fluctuating):**
    *   `observeEssence(uint256 essenceId)`: Triggers an update to the Essence's state (`fluxLevel`, `stabilityScore`) based on time elapsed and parameters. Requires ownership.
    *   `interactWithEssence(uint256 essenceId)`: Triggers a more significant state change, potentially influenced by the caller's address or other factors. Requires ownership.
    *   `transferFlux(uint256 essenceId1, uint256 essenceId2, uint256 amount)`: Allows an owner to attempt transferring `fluxLevel` between two of their owned Essences. Outcome may be probabilistic.
    *   `influenceEssenceStability(uint256 essenceId, int256 influence)`: Allows an owner to attempt to increase or decrease the `stabilityScore` of their Essence. Limited effect.
*   **Entanglement Mechanics:**
    *   `entangleEssences(uint256 essenceId1, uint256 essenceId2)`: Attempts to entangle two owned, non-entangled Essences. Success may depend on properties.
    *   `disentangleEssence(uint256 essenceId)`: Attempts to disentangle an owned, entangled Essence.
    *   `getEntanglementPartner(uint256 essenceId)`: Returns the ID of the Essence an Essence is entangled with, or 0 if not entangled.
*   **Evolution Mechanics:**
    *   `evolveEssence(uint256 essenceId)`: Attempts to evolve an owned Essence to its next `EvolutionState`. Requires specific conditions (`fluxLevel`, `stabilityScore`, `entanglementPartner` state) to be met. Consumes resources (e.g., resets `fluxLevel`).
    *   `queryPotentialEvolution(uint256 essenceId)`: Checks and returns whether an Essence is currently eligible for evolution *without* attempting the evolution.
    *   `getEvolutionState(uint256 essenceId)`: Returns the current `EvolutionState` of an Essence.
*   **Marketplace:**
    *   `listEssenceForSale(uint256 essenceId, uint256 price)`: Lists an owned Essence for sale at a specified price.
    *   `cancelListing(uint256 essenceId)`: Removes an Essence from the sale listing. Requires ownership or approval.
    *   `buyEssence(uint256 essenceId)`: Purchases a listed Essence. Requires sending the correct Ether amount.
    *   `getListing(uint256 essenceId)`: Returns the listing details (seller, price) for an Essence, or signals it's not listed.
*   **Utility & Admin:**
    *   `withdrawFees()`: Owner function to withdraw collected fees from Essence creation and marketplace sales.
    *   `setFluxParameters(int256 fluxChangeFactor, int256 stabilityChangeFactor, uint256 timeFactor)`: Owner function to adjust parameters affecting how Essence states fluctuate over time.
    *   `getFluxParameters()`: Returns the current global flux parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Simple interface definition for ERC-721 to ensure compatibility.
// We will implement these functions manually, not inherit from OpenZeppelin or similar.
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Helper interface to check if a contract is ERC721Receiver compliant
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


contract QuantumFluctuationsMarketplace is IERC721 {
    address public immutable contractOwner;
    uint256 private _nextTokenId;
    uint256 public creationFee = 0.01 ether; // Fee to create a new Essence
    uint256 public marketplaceFeeBasisPoints = 250; // 2.5% marketplace fee

    // --- Data Structures ---

    enum EvolutionState { Unstable, Nascent, Ethereal, QuantumPeak, Decaying }

    struct Essence {
        uint256 id;
        address owner; // Redundant with _essenceOwner, but useful for struct return
        uint256 creationBlock;
        uint256 lastObservedBlock; // Block number when state was last updated
        int256 fluxLevel; // Can be positive or negative, fluctuates
        uint256 stabilityScore; // Affects how much fluxLevel changes, 0-100
        uint256 entanglementPartner; // 0 if not entangled, otherwise partner's ID
        EvolutionState evolutionState;
        mapping(string => string) properties; // Extra arbitrary properties
    }

    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
    }

    // --- State Variables ---

    // Core ERC721 mappings (Implementing manually)
    mapping(uint256 => address) private _essenceOwner; // tokenId => owner
    mapping(address => uint256) private _ownerEssenceCount; // owner => count
    mapping(uint256 => address) private _tokenApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // Custom Essence data
    mapping(uint256 => Essence) private _essences;
    mapping(address => uint256[]) private _essencesOwnedBy; // owner => list of tokenIds (potentially gas intensive)

    // Marketplace data
    mapping(uint256 => Listing) private _listings; // tokenId => Listing

    // Global parameters for state fluctuation
    int256 public fluxChangeFactor = 10; // Base factor for flux change per block
    int256 public stabilityChangeFactor = 5; // Base factor for stability change per block
    uint256 public timeFactor = 100; // Multiplier for time elapsed effect

    // Fee collection
    uint256 public collectedFees;

    // --- Events ---

    event EssenceCreated(uint256 indexed essenceId, address indexed owner, uint256 initialFlux, uint256 initialStability);
    event EssenceStateUpdated(uint256 indexed essenceId, int256 newFlux, uint256 newStability, EvolutionState newState);
    event EssenceEntangled(uint256 indexed essenceId1, uint256 indexed essenceId2);
    event EssenceDisentangled(uint256 indexed essenceId1, uint256 indexed essenceId2);
    event EssenceEvolved(uint256 indexed essenceId, EvolutionState newState);
    event EssenceBurned(uint256 indexed essenceId);
    event EssenceListed(uint256 indexed essenceId, address indexed seller, uint256 price);
    event ListingCancelled(uint256 indexed essenceId);
    event EssenceBought(uint256 indexed essenceId, address indexed buyer, uint256 price);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only owner can call this function");
        _;
    }

    modifier exists(uint256 essenceId) {
        require(_essenceOwner[essenceId] != address(0), "Essence does not exist");
        _;
    }

    modifier isOwnedBy(uint256 essenceId, address account) {
        require(_essenceOwner[essenceId] == account, "Not owned by caller");
        _;
    }

    modifier isApprovedOrOwner(uint256 essenceId) {
        address owner = _essenceOwner[essenceId];
        require(owner == msg.sender || getApproved(essenceId) == msg.sender || isApprovedForAll(owner, msg.sender), "Not owner nor approved");
        _;
    }

    // --- Constructor ---

    constructor() {
        contractOwner = msg.sender;
    }

    // --- Internal Helpers (ERC-721 & State Logic) ---

    function _exists(uint256 essenceId) internal view returns (bool) {
        return _essenceOwner[essenceId] != address(0);
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
        require(
            to.code.length == 0 ||
            IERC721Receiver(to).onERC721Received(msg.sender, address(0), tokenId, "") == IERC721Receiver.onERC721Received.selector,
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _essenceOwner[tokenId] = to;
        _ownerEssenceCount[to]++;
        _essencesOwnedBy[to].push(tokenId); // Add to owner's list

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal exists(tokenId) {
        address owner = _essenceOwner[tokenId];

        // Clear approvals
        approve(address(0), tokenId);

        // Remove from owner's list (inefficient, better managed off-chain or with a different data structure)
        uint256[] storage ownedList = _essencesOwnedBy[owner];
        for (uint256 i = 0; i < ownedList.length; i++) {
            if (ownedList[i] == tokenId) {
                ownedList[i] = ownedList[ownedList.length - 1];
                ownedList.pop();
                break;
            }
        }

        delete _essenceOwner[tokenId];
        _ownerEssenceCount[owner]--;

        // Handle entanglement break on burn
        if (_essences[tokenId].entanglementPartner != 0) {
            uint256 partnerId = _essences[tokenId].entanglementPartner;
            _essences[partnerId].entanglementPartner = 0;
            emit EssenceDisentangled(tokenId, partnerId);
        }

        // Delete the essence data
        delete _essences[tokenId];

        emit Transfer(owner, address(0), tokenId);
        emit EssenceBurned(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal isOwnedBy(tokenId, from) {
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals for the token
        approve(address(0), tokenId);

        _ownerEssenceCount[from]--;
        _ownerEssenceCount[to]++;
        _essenceOwner[tokenId] = to;

        // Update owner's list (again, inefficient)
        uint256[] storage fromList = _essencesOwnedBy[from];
         for (uint256 i = 0; i < fromList.length; i++) {
            if (fromList[i] == tokenId) {
                fromList[i] = fromList[fromList.length - 1];
                fromList.pop();
                break;
            }
        }
        _essencesOwnedBy[to].push(tokenId);


        // Update owner in the Essence struct itself (for consistency/return values)
        _essences[tokenId].owner = to;

        emit Transfer(from, to, tokenId);
    }

    // Core logic for updating Essence state based on time and parameters
    function _updateEssenceState(uint256 essenceId) internal exists(essenceId) {
        Essence storage essence = _essences[essenceId];
        uint256 timeElapsed = block.number - essence.lastObservedBlock;

        if (timeElapsed > 0) {
            int256 fluxChange = (int256(timeElapsed) * fluxChangeFactor);
            int256 stabilityChange = (int256(timeElapsed) * stabilityChangeFactor);

            // Introduce pseudo-randomness based on recent block data
            uint256 randomness = uint256(keccak256(abi.encodePacked(essenceId, block.timestamp, block.number, blockhash(block.number - 1))));

            if (randomness % 2 == 0) fluxChange = -fluxChange;
            if (randomness % 3 == 0) stabilityChange = -stabilityChange;

             // Apply changes
            essence.fluxLevel += fluxChange;
            // Stability is bounded
            essence.stabilityScore = uint256(int256(essence.stabilityScore) + stabilityChange).clamp(0, 100);

            // Handle entanglement effect
            if (essence.entanglementPartner != 0 && _exists(essence.entanglementPartner)) {
                Essence storage partner = _essences[essence.entanglementPartner];
                // Simple entanglement: partner's flux changes in the opposite direction
                 partner.fluxLevel -= fluxChange / 2; // Half the change, opposite sign
                 partner.stabilityScore = uint256(int256(partner.stabilityScore) - stabilityChange / 2).clamp(0, 100); // Half the change, opposite sign

                 // Also update partner's last observed block to prevent double-update immediately
                 partner.lastObservedBlock = block.number;
                 // Note: This could lead to complex cascade updates if entanglement forms loops.
                 // For simplicity, we only update the direct partner here.
            }


            essence.lastObservedBlock = block.number;

            // Trigger potential state changes based on flux/stability/evolution
             // (More complex evolution logic is in evolveEssence, this is for general state updates)
            EvolutionState oldState = essence.evolutionState;
            if (essence.fluxLevel > 1000 && essence.evolutionState < EvolutionState.QuantumPeak) {
                 if(essence.evolutionState != EvolutionState.Ethereal) essence.evolutionState = EvolutionState.Ethereal;
            } else if (essence.fluxLevel < -500 && essence.evolutionState < EvolutionState.Decaying) {
                 if(essence.evolutionState != EvolutionState.Decaying) essence.evolutionState = EvolutionState.Decaying;
            } else if (essence.fluxLevel >= -500 && essence.fluxLevel <= 1000 && essence.evolutionState > EvolutionState.Nascent && essence.evolutionState != EvolutionState.Unstable) {
                // Maybe revert to a more stable state
                 essence.evolutionState = EvolutionState.Nascent;
            }


             if (oldState != essence.evolutionState) {
                emit EssenceEvolved(essenceId, essence.evolutionState); // Re-using evolution event for general state change visualization
             }


            emit EssenceStateUpdated(essenceId, essence.fluxLevel, essence.stabilityScore, essence.evolutionState);
        }
    }

    // Safely clamp an integer value between a min and max
    function clamp(int256 value, int256 min, int256 max) internal pure returns (uint256) {
        if (value < min) return uint256(min);
        if (value > max) return uint256(max);
        return uint256(value);
    }

    // --- ERC-721 Standard Function Implementations ---

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _ownerEssenceCount[owner];
    }

    function ownerOf(uint256 essenceId) public view override exists(essenceId) returns (address) {
        return _essenceOwner[essenceId];
    }

    function approve(address to, uint256 essenceId) public override exists(essenceId) isOwnedBy(essenceId, msg.sender) {
        _tokenApprovals[essenceId] = to;
        emit Approval(msg.sender, to, essenceId);
    }

    function getApproved(uint256 essenceId) public view override exists(essenceId) returns (address) {
        return _tokenApprovals[essenceId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 essenceId) public override isApprovedOrOwner(essenceId) exists(essenceId) {
        require(_essenceOwner[essenceId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // If listed, cancel the listing before transfer
        if (_listings[essenceId].isListed) {
            cancelListing(essenceId);
        }

        _transfer(from, to, essenceId);
    }

     function safeTransferFrom(address from, address to, uint256 essenceId) public override {
        safeTransferFrom(from, to, essenceId, "");
    }

    function safeTransferFrom(address from, address to, uint256 essenceId, bytes calldata data) public override isApprovedOrOwner(essenceId) exists(essenceId) {
         require(_essenceOwner[essenceId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

         // If listed, cancel the listing before transfer
        if (_listings[essenceId].isListed) {
            cancelListing(essenceId);
        }

        _transfer(from, to, essenceId);

        // If recipient is a contract, check if it implements ERC721Receiver
        if (to.code.length > 0) {
            require(
                IERC721Receiver(to).onERC721Received(msg.sender, from, essenceId, data) == IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    // --- Essence Creation & Base Management ---

    /**
     * @notice Mints a new Quantum Essence. Requires a creation fee.
     * Initial properties are set based on creation details.
     */
    function createEssence() public payable returns (uint256) {
        require(msg.value >= creationFee, "Insufficient creation fee");

        collectedFees += msg.value; // Collect the fee

        uint256 newTokenId = _nextTokenId++;
        address creator = msg.sender;

        // Initialize the essence struct
        _essences[newTokenId].id = newTokenId;
        _essences[newTokenId].owner = creator; // Stored for struct access convenience
        _essences[newTokenId].creationBlock = block.number;
        _essences[newTokenId].lastObservedBlock = block.number; // Start fresh
        _essences[newTokenId].fluxLevel = 0; // Initial flux
        // Initial stability slightly random, bounded 50-80
        _essences[newTokenId].stabilityScore = uint256(keccak256(abi.encodePacked(newTokenId, block.timestamp))) % 31 + 50;
        _essences[newTokenId].entanglementPartner = 0; // Not entangled initially
        _essences[newTokenId].evolutionState = EvolutionState.Unstable; // Start unstable

        // Mint the ERC721 token
        _safeMint(creator, newTokenId);

        emit EssenceCreated(newTokenId, creator, int256(_essences[newTokenId].fluxLevel), _essences[newTokenId].stabilityScore);

        return newTokenId;
    }

     /**
     * @notice Retrieves the current detailed state of an Essence.
     * Automatically updates the Essence's state before returning.
     * @param essenceId The ID of the Essence.
     * @return The Essence struct details.
     */
    function getEssenceDetails(uint256 essenceId) public exists(essenceId) returns (Essence memory) {
        _updateEssenceState(essenceId); // Update state before returning

         // Need to copy to memory struct because mapping inside struct is not supported in memory
         Essence storage storageEssence = _essences[essenceId];
         Essence memory memoryEssence;
         memoryEssence.id = storageEssence.id;
         memoryEssence.owner = storageEssence.owner;
         memoryEssence.creationBlock = storageEssence.creationBlock;
         memoryEssence.lastObservedBlock = storageEssence.lastObservedBlock;
         memoryEssence.fluxLevel = storageEssence.fluxLevel;
         memoryEssence.stabilityScore = storageEssence.stabilityScore;
         memoryEssence.entanglementPartner = storageEssence.entanglementPartner;
         memoryEssence.evolutionState = storageEssence.evolutionState;
         // Note: Properties mapping cannot be copied to memory this way.
         // A separate function or different struct design would be needed to expose properties.

        return memoryEssence;
    }

    /**
     * @notice Destroys a Quantum Essence, removing it permanently.
     * @param essenceId The ID of the Essence to burn.
     */
    function burnEssence(uint256 essenceId) public isOwnedBy(essenceId, msg.sender) exists(essenceId) {
        // If listed, cancel the listing before burning
        if (_listings[essenceId].isListed) {
            cancelListing(essenceId);
        }
        _burn(essenceId);
    }

    /**
     * @notice Returns the total number of Essences ever minted.
     * @return The total supply.
     */
    function getTotalEssences() public view returns (uint256) {
        return _nextTokenId;
    }

     /**
     * @notice Returns a list of Essence IDs owned by a specific address.
     * WARNING: This can be very gas-intensive if an address owns many Essences.
     * Consider using off-chain indexing for large collections.
     * @param owner The address to query.
     * @return An array of Essence IDs.
     */
    function getEssencesOwnedBy(address owner) public view returns (uint256[] memory) {
        require(owner != address(0), "Owner address cannot be zero");
        return _essencesOwnedBy[owner];
    }


    // --- Essence State Manipulation (Dynamic/Fluctuating) ---

    /**
     * @notice Triggers an update to the Essence's state based on time elapsed and global parameters.
     * Requires ownership.
     * @param essenceId The ID of the Essence to observe.
     */
    function observeEssence(uint256 essenceId) public isOwnedBy(essenceId, msg.sender) exists(essenceId) {
        _updateEssenceState(essenceId);
    }

    /**
     * @notice Triggers a more significant state change for the Essence,
     * potentially influenced by the caller or interaction type (simulated).
     * Requires ownership.
     * @param essenceId The ID of the Essence to interact with.
     */
    function interactWithEssence(uint256 essenceId) public isOwnedBy(essenceId, msg.sender) exists(essenceId) {
        _updateEssenceState(essenceId); // Update based on time first

        Essence storage essence = _essences[essenceId];

        // Introduce interaction-specific pseudo-randomness and larger effects
        uint256 interactionEntropy = uint256(keccak256(abi.encodePacked(essenceId, msg.sender, block.timestamp, block.number)));

        int256 interactionFluxChange = int256(interactionEntropy % 200) - 100; // -100 to 100
        int256 interactionStabilityChange = int256(interactionEntropy % 20) - 10; // -10 to 10

        essence.fluxLevel += interactionFluxChange * 5; // Larger flux change
        essence.stabilityScore = uint256(int26(essence.stabilityScore) + interactionStabilityChange * 2).clamp(0, 100); // Larger stability change

         // Entangled partner also feels interaction effects
        if (essence.entanglementPartner != 0 && _exists(essence.entanglementPartner)) {
             Essence storage partner = _essences[essence.entanglementPartner];
             partner.fluxLevel += interactionFluxChange * 2; // Reduced, same direction
             partner.stabilityScore = uint256(int256(partner.stabilityScore) + interactionStabilityChange).clamp(0, 100); // Reduced, same direction
             partner.lastObservedBlock = block.number; // Prevent double-update
        }

        emit EssenceStateUpdated(essenceId, essence.fluxLevel, essence.stabilityScore, essence.evolutionState);
    }

     /**
     * @notice Allows an owner to attempt transferring fluxLevel between two of their owned Essences.
     * Outcome may be probabilistic or based on stability.
     * @param essenceId1 The ID of the first Essence.
     * @param essenceId2 The ID of the second Essence.
     * @param amount The amount of flux to attempt to transfer.
     */
    function transferFlux(uint256 essenceId1, uint256 essenceId2, uint256 amount) public isOwnedBy(essenceId1, msg.sender) isOwnedBy(essenceId2, msg.sender) exists(essenceId1) exists(essenceId2) {
         require(essenceId1 != essenceId2, "Cannot transfer flux to self");
         require(amount > 0, "Amount must be positive");

         // Update states first to get current values
         _updateEssenceState(essenceId1);
         _updateEssenceState(essenceId2);

         Essence storage essence1 = _essences[essenceId1];
         Essence storage essence2 = _essences[essenceId2];

         // Simulate transfer success/efficiency based on stability
         uint256 totalStability = essence1.stabilityScore + essence2.stabilityScore;
         uint256 randomness = uint256(keccak256(abi.encodePacked(essenceId1, essenceId2, block.timestamp, block.number))) % 101; // 0-100

         // Higher total stability means more efficient transfer
         uint256 effectiveAmount = (amount * totalStability) / 200; // Max 100+100 stability = 200, 100% efficiency
         // Randomness can introduce variance
         effectiveAmount = (effectiveAmount * randomness) / 100; // Random factor 0-100%

         // Ensure we don't transfer more flux than available (considering signs)
         int256 actualAmountToTransfer = int256(effectiveAmount);
         if (essence1.fluxLevel < actualAmountToTransfer) {
             actualAmountToTransfer = essence1.fluxLevel; // Only transfer up to available flux
         }

         essence1.fluxLevel -= actualAmountToTransfer;
         essence2.fluxLevel += actualAmountToTransfer;

         // Transferring flux might affect stability inversely
         int256 stabilityCost = actualAmountToTransfer / 50; // Small cost
         if (essence1.stabilityScore > uint256(stabilityCost)) essence1.stabilityScore -= uint256(stabilityCost); else essence1.stabilityScore = 0;
         if (essence2.stabilityScore > uint256(stabilityCost)) essence2.stabilityScore -= uint256(stabilityCost); else essence2.stabilityScore = 0;


         emit EssenceStateUpdated(essenceId1, essence1.fluxLevel, essence1.stabilityScore, essence1.evolutionState);
         emit EssenceStateUpdated(essenceId2, essence2.fluxLevel, essence2.stabilityScore, essence2.evolutionState);
    }

     /**
     * @notice Allows an owner to attempt to increase or decrease the stabilityScore of their Essence.
     * Effect is limited and may depend on current state.
     * @param essenceId The ID of the Essence.
     * @param influence A positive or negative value representing the attempted influence.
     */
    function influenceEssenceStability(uint256 essenceId, int256 influence) public isOwnedBy(essenceId, msg.sender) exists(essenceId) {
         _updateEssenceState(essenceId); // Update state first

         Essence storage essence = _essences[essenceId];

         // Influence is filtered by current stability and flux
         int256 effectiveInfluence = influence;
         // Make it harder to change stability if flux is high/low or stability is already max/min
         effectiveInfluence = (effectiveInfluence * (100 - essence.stabilityScore)) / 100; // Harder to increase high stability
         if (effectiveInfluence < 0) {
             effectiveInfluence = (effectiveInfluence * essence.stabilityScore) / 100; // Harder to decrease low stability
         }

         essence.stabilityScore = uint256(int256(essence.stabilityScore) + effectiveInfluence / 10).clamp(0, 100); // Apply a fraction of the influence

         emit EssenceStateUpdated(essenceId, essence.fluxLevel, essence.stabilityScore, essence.evolutionState);
    }


    // --- Entanglement Mechanics ---

    /**
     * @notice Attempts to entangle two owned, non-entangled Essences.
     * Requires ownership of both. Success may depend on properties (simulated).
     * @param essenceId1 The ID of the first Essence.
     * @param essenceId2 The ID of the second Essence.
     */
    function entangleEssences(uint256 essenceId1, uint256 essenceId2) public isOwnedBy(essenceId1, msg.sender) isOwnedBy(essenceId2, msg.sender) exists(essenceId1) exists(essenceId2) {
        require(essenceId1 != essenceId2, "Cannot entangle an Essence with itself");
        require(_essences[essenceId1].entanglementPartner == 0, "Essence 1 is already entangled");
        require(_essences[essenceId2].entanglementPartner == 0, "Essence 2 is already entangled");

        // Update states before checking / entangling
        _updateEssenceState(essenceId1);
        _updateEssenceState(essenceId2);

        // Simulate entanglement success chance based on properties (e.g., flux levels alignment)
        // Simple check: closer flux levels have higher chance
        int256 fluxDifference = essenceId1 > essenceId2 ? _essences[essenceId1].fluxLevel - _essences[essenceId2].fluxLevel : _essences[essenceId2].fluxLevel - _essences[essenceId1].fluxLevel;
        uint256 maxFluxDiffForChance = 2000; // Max diff where success is possible
        uint256 successChance = 0;
        if (fluxDifference < int256(maxFluxDiffForChance)) {
            successChance = ((maxFluxDiffForChance - uint256(fluxDifference)) * 100) / maxFluxDiffForChance; // 0-100%
        }
         // Also factor in stability
         successChance = (successChance * (_essences[essenceId1].stabilityScore + _essences[essenceId2].stabilityScore)) / 200; // Avg stability factor

         uint256 randomness = uint256(keccak256(abi.encodePacked(essenceId1, essenceId2, block.timestamp, block.number))) % 101; // 0-100

        if (randomness <= successChance) {
            // Success
            _essences[essenceId1].entanglementPartner = essenceId2;
            _essences[essenceId2].entanglementPartner = essenceId1;
            emit EssenceEntangled(essenceId1, essenceId2);
        } else {
            // Failure - maybe apply a penalty? E.g., temporary flux change
            int256 penalty = int256(randomness % 100) * -1; // 0 to -100
            _essences[essenceId1].fluxLevel += penalty;
            _essences[essenceId2].fluxLevel += penalty;
             emit EssenceStateUpdated(essenceId1, _essences[essenceId1].fluxLevel, _essences[essenceId1].stabilityScore, _essences[essenceId1].evolutionState);
             emit EssenceStateUpdated(essenceId2, _essences[essenceId2].fluxLevel, _essences[essenceId2].stabilityScore, _essences[essenceId2].evolutionState);

            // No event for failed entanglement, implicitly understood if EssenceEntangled event isn't emitted.
        }
    }

    /**
     * @notice Attempts to disentangle an owned, entangled Essence.
     * May require a stability check or have a chance of failure (simulated).
     * @param essenceId The ID of the Essence to disentangle.
     */
    function disentangleEssence(uint256 essenceId) public isOwnedBy(essenceId, msg.sender) exists(essenceId) {
        Essence storage essence = _essences[essenceId];
        require(essence.entanglementPartner != 0, "Essence is not entangled");
        uint256 partnerId = essence.entanglementPartner;
        require(_exists(partnerId), "Entanglement partner no longer exists"); // Should ideally not happen if _burn cleans up

         _updateEssenceState(essenceId); // Update state first
         _updateEssenceState(partnerId); // Update partner state

        // Simulate disentanglement chance based on stability (less stable = harder)
         uint256 successChance = essence.stabilityScore; // Stability (0-100) is direct chance
         uint256 randomness = uint256(keccak256(abi.encodePacked(essenceId, partnerId, block.timestamp, block.number))) % 101; // 0-100

        if (randomness <= successChance) {
             // Success
            essence.entanglementPartner = 0;
            _essences[partnerId].entanglementPartner = 0; // Disentangle partner as well
            emit EssenceDisentangled(essenceId, partnerId);
        } else {
            // Failure - maybe apply a penalty? E.g., larger flux change or stability hit
            int256 penalty = int256(randomness % 50) * -1; // 0 to -50
            essence.fluxLevel += penalty * 2; // Larger penalty
            essence.stabilityScore = uint256(int256(essence.stabilityScore) + penalty/2).clamp(0, 100); // Small stability hit
             emit EssenceStateUpdated(essenceId, essence.fluxLevel, essence.stabilityScore, essence.evolutionState);

            // No event for failed disentanglement
        }
    }

    /**
     * @notice Returns the ID of the Essence an Essence is entangled with.
     * @param essenceId The ID of the Essence.
     * @return The ID of the entanglement partner, or 0 if not entangled.
     */
    function getEntanglementPartner(uint256 essenceId) public view exists(essenceId) returns (uint256) {
        return _essences[essenceId].entanglementPartner;
    }

    // --- Evolution Mechanics ---

    /**
     * @notice Attempts to evolve an owned Essence to its next EvolutionState.
     * Requires specific conditions to be met. Consumes resources (resets flux).
     * @param essenceId The ID of the Essence to evolve.
     */
    function evolveEssence(uint256 essenceId) public isOwnedBy(essenceId, msg.sender) exists(essenceId) {
         _updateEssenceState(essenceId); // Update state first

         Essence storage essence = _essences[essenceId];
         EvolutionState currentState = essence.evolutionState;
         bool eligible = false;

         // Define evolution conditions based on current state
         if (currentState == EvolutionState.Unstable && essence.stabilityScore >= 70 && essence.fluxLevel > 500) {
             eligible = true; // Stable enough with sufficient flux to reach Nascent
             essence.evolutionState = EvolutionState.Nascent;
         } else if (currentState == EvolutionState.Nascent && essence.fluxLevel > 1500 && essence.entanglementPartner != 0) {
              // Requires high flux and entanglement to become Ethereal
              if (_exists(essence.entanglementPartner)) { // Check if partner still exists
                  // Maybe require partner to be a certain state too?
                   eligible = true;
                   essence.evolutionState = EvolutionState.Ethereal;
              }
         } else if (currentState == EvolutionState.Ethereal && essence.fluxLevel > 3000 && essence.stabilityScore >= 90) {
              eligible = true; // Very high flux and stability for QuantumPeak
              essence.evolutionState = EvolutionState.QuantumPeak;
         } else if (currentState == EvolutionState.QuantumPeak && essence.fluxLevel < -2000) {
              eligible = true; // Significant negative flux can trigger Decaying
              essence.evolutionState = EvolutionState.Decaying;
         }
         // Evolution is generally forward-only through this function, Decaying is a terminal state

         require(eligible, "Essence is not eligible for evolution");

         // Evolution cost/reset: Reset flux level
         essence.fluxLevel = 0;
         // Stability might change slightly
         essence.stabilityScore = uint256(int256(essence.stabilityScore) + int256(essence.evolutionState) * 5).clamp(0, 100); // Higher state = slightly higher stability boost

         emit EssenceEvolved(essenceId, essence.evolutionState);
         emit EssenceStateUpdated(essenceId, essence.fluxLevel, essence.stabilityScore, essence.evolutionState); // Also emit general update event
    }

    /**
     * @notice Checks and returns whether an Essence is currently eligible for evolution
     * based on its state *without* attempting the evolution.
     * @param essenceId The ID of the Essence.
     * @return true if eligible, false otherwise.
     */
    function queryPotentialEvolution(uint256 essenceId) public view exists(essenceId) returns (bool) {
        // Need to simulate state update for the check without modifying storage
        // This is complex to do perfectly in a view function without duplicating _updateEssenceState logic.
        // For simplicity here, we will check based on the *current* storage state,
        // acknowledging this might be slightly outdated if state hasn't been updated recently.
        // A more robust approach would involve calculating the state change based on current block.timestamp
        // in a pure or view helper function.

         Essence storage essence = _essences[essenceId]; // Read storage directly
         EvolutionState currentState = essence.evolutionState;

         if (currentState == EvolutionState.Unstable && essence.stabilityScore >= 70 && essence.fluxLevel > 500) {
             return true;
         } else if (currentState == EvolutionState.Nascent && essence.fluxLevel > 1500 && essence.entanglementPartner != 0 && _exists(essence.entanglementPartner)) {
             return true;
         } else if (currentState == EvolutionState.Ethereal && essence.fluxLevel > 3000 && essence.stabilityScore >= 90) {
             return true;
         } else if (currentState == EvolutionState.QuantumPeak && essence.fluxLevel < -2000) {
             return true;
         }

         return false;
    }

    /**
     * @notice Returns the current EvolutionState of an Essence.
     * @param essenceId The ID of the Essence.
     * @return The EvolutionState enum value.
     */
    function getEvolutionState(uint256 essenceId) public view exists(essenceId) returns (EvolutionState) {
        return _essences[essenceId].evolutionState;
    }


    // --- Marketplace ---

    /**
     * @notice Lists an owned Essence for sale at a specified price.
     * Cancels any existing approval for the token upon listing.
     * @param essenceId The ID of the Essence to list.
     * @param price The price in Wei. Must be greater than 0.
     */
    function listEssenceForSale(uint256 essenceId, uint256 price) public isOwnedBy(essenceId, msg.sender) exists(essenceId) {
        require(price > 0, "Listing price must be greater than 0");

        // Clear any existing approval as the marketplace will handle transfers
        approve(address(0), essenceId);

        _listings[essenceId] = Listing({
            seller: msg.sender,
            price: price,
            isListed: true
        });

        emit EssenceListed(essenceId, msg.sender, price);
    }

    /**
     * @notice Removes an Essence from the sale listing.
     * Requires ownership or approval for the Essence.
     * @param essenceId The ID of the Essence to de-list.
     */
    function cancelListing(uint256 essenceId) public isApprovedOrOwner(essenceId) exists(essenceId) {
         require(_listings[essenceId].isListed, "Essence is not listed for sale");
         require(_listings[essenceId].seller == _essenceOwner[essenceId], "Listing seller mismatch"); // Double check ownership

        delete _listings[essenceId];

        emit ListingCancelled(essenceId);
    }

     /**
     * @notice Purchases a listed Essence. Requires sending the correct Ether amount.
     * Transfers ownership and sends Ether to the seller (minus fee).
     * @param essenceId The ID of the Essence to buy.
     */
    function buyEssence(uint256 essenceId) public payable exists(essenceId) {
        Listing storage listing = _listings[essenceId];
        require(listing.isListed, "Essence is not listed for sale");
        require(msg.sender != listing.seller, "Cannot buy your own Essence");
        require(msg.value >= listing.price, "Insufficient Ether sent"); // Allow overpayment

        address seller = listing.seller;
        uint256 price = listing.price;

        // Calculate fee
        uint256 feeAmount = (price * marketplaceFeeBasisPoints) / 10000;
        uint256 sellerPayout = price - feeAmount;

        // Transfer Ether to seller and collected fees
        (bool successSeller, ) = payable(seller).call{value: sellerPayout}("");
        require(successSeller, "Ether transfer to seller failed");

        collectedFees += feeAmount; // Add marketplace fee to collected fees

        // Perform the token transfer (internal _transfer handles ERC721 state)
        // Seller is 'from', buyer is 'to'. Need to be msg.sender or approved/owner.
        // The listing logic implies the seller has given implicit approval to the marketplace contract.
        // However, the standard ERC721 transferFrom requires msg.sender to be owner/approved/operator.
        // A simpler approach is to have the buyer call `buyEssence` and the contract perform the transfer
        // *if* the contract itself is the approved operator for the seller, or if the seller
        // implicitly approves the contract by listing. Let's make `buyEssence` callable by anyone,
        // and the transfer logic inside it assumes the listing constitutes approval for the contract
        // to move the token.
        // NOTE: In a real implementation, the marketplace contract might need to be an approved operator,
        // or the transfer logic needs careful access control.
        // For this example, we'll assume the listing grants the contract authority to move.
        // We bypass the standard `transferFrom` public function's `isApprovedOrOwner` check
        // and call the internal `_transfer` directly, assuming the listing *is* the authorization.
        // A safer pattern involves the seller approving the marketplace contract.
        // Let's add a check that the current owner is still the seller who listed it.
        require(_essenceOwner[essenceId] == seller, "Essence owner changed since listing");

        // The buyer (msg.sender) is the 'to' address. The seller is the 'from' address.
        // We call _transfer directly from the contract's context.
        _transfer(seller, msg.sender, essenceId); // seller is `from`, msg.sender is `to`

        // Remove listing
        delete _listings[essenceId];

        // Handle any potential overpayment refund
        if (msg.value > price) {
            (bool successRefund, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(successRefund, "Overpayment refund failed");
        }


        emit EssenceBought(essenceId, msg.sender, price);
    }


     /**
     * @notice Returns the listing details for an Essence.
     * @param essenceId The ID of the Essence.
     * @return seller The address of the seller.
     * @return price The price in Wei.
     * @return isListed Whether the Essence is currently listed.
     */
    function getListing(uint256 essenceId) public view returns (address seller, uint256 price, bool isListed) {
        Listing storage listing = _listings[essenceId];
        return (listing.seller, listing.price, listing.isListed);
    }


    // --- Utility & Admin ---

    /**
     * @notice Allows the contract owner to withdraw collected fees.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawFees(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be positive");
        require(amount <= collectedFees, "Insufficient collected fees");

        collectedFees -= amount;

        (bool success, ) = payable(contractOwner).call{value: amount}("");
        require(success, "Withdrawal failed");
    }

     /**
     * @notice Owner function to adjust global parameters affecting Essence state fluctuation.
     * @param _fluxChangeFactor New base factor for flux change per block.
     * @param _stabilityChangeFactor New base factor for stability change per block.
     * @param _timeFactor New multiplier for time elapsed effect (currently unused directly in update, but can be integrated).
     */
    function setFluxParameters(int256 _fluxChangeFactor, int256 _stabilityChangeFactor, uint256 _timeFactor) public onlyOwner {
         fluxChangeFactor = _fluxChangeFactor;
         stabilityChangeFactor = _stabilityChangeFactor;
         timeFactor = _timeFactor; // Note: timeFactor needs to be integrated into _updateEssenceState if intended to scale timeEffect.
    }

     /**
     * @notice Returns the current global flux parameters.
     * @return fluxChangeFactor, stabilityChangeFactor, timeFactor.
     */
    function getFluxParameters() public view returns (int256, int256, uint256) {
        return (fluxChangeFactor, stabilityChangeFactor, timeFactor);
    }

}
```