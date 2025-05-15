Okay, let's design a complex, creative, and advanced Solidity smart contract centered around "Dynamic Chronicle Crystals". These will be NFTs (ERC-721) that can evolve, be staked to yield a utility token (Chronicle Dust - ERC-20), and have traits that can be influenced or crafted using Dust. The metadata for these NFTs will be dynamic, changing based on their state and evolution.

Here's the concept:

**Chronicle Crystals (ERC-721):**
*   Each Crystal is a unique NFT.
*   They have generative attributes determined upon minting.
*   They have state variables: generation, age, last evolution timestamp, staking status.
*   Their attributes can *potentially* change upon 'evolution', triggered by the owner using Dust.
*   New traits can be 'crafted' and added using Dust.
*   Can be staked to earn Dust.

**Chronicle Dust (ERC-20):**
*   A utility token earned by staking Crystals.
*   Used as a currency to trigger Crystal evolution or craft traits.
*   Can be burned for various effects (not explicitly defined here, but a common utility sink).

**Advanced Concepts & Features:**
1.  **Dynamic NFT Metadata:** The `tokenURI` will reflect the current state and attributes of the Crystal, making the NFT truly dynamic.
2.  **On-Chain State Evolution:** Crystal attributes and state change based on actions (`triggerEvolution`, `craftNewTrait`) and time.
3.  **Staking Mechanism:** Users lock their NFTs to earn a fungible token reward.
4.  **Utility Token Sink:** Dust is required for core NFT interactions (evolution, crafting), creating demand.
5.  **Generative Elements:** Initial attributes are 'generated' on-chain (using simplified logic).
6.  **Time-Based Mechanics:** Yield is calculated based on staking duration; age is based on time since minting.
7.  **Role-Based Access Control:** Uses `Ownable` and potentially other roles (e.g., a 'Guardian' role for pausing).
8.  **Internal State Management:** Complex interactions between NFT state, ERC-20 state, and staking logic.
9.  **Error Handling:** Comprehensive `require` statements and custom errors (Solidity 0.8+).
10. **Events:** Detailed events for transparency.

---

### **Outline and Function Summary**

**Contract:** `ChronicleCrystals`

**Base Standards:** ERC-721 (for Crystals), ERC-20 (for Dust), Ownable.

**Components:**
*   Chronicle Crystal (ERC-721 NFT) with dynamic attributes and state.
*   Chronicle Dust (ERC-20) utility token for staking rewards and crafting/evolution.
*   Staking mechanism for locking Crystals and earning Dust.
*   Functions for Crystal evolution and trait crafting using Dust.
*   Role-based access control.

**State Variables:**
*   Metadata base URI
*   Dust token contract address
*   Total minted crystals counter
*   Mapping for Crystal attributes (`CrystalAttributes`)
*   Mapping for Crystal dynamic state (`CrystalState`)
*   Mapping for staking status and timestamps
*   Admin/Guardian addresses
*   Staking yield parameters, evolution/crafting costs
*   Pause flags

**Structs:**
*   `CrystalAttributes`: Represents semi-permanent traits (e.g., numbers representing color, shape, pattern).
*   `CrystalState`: Represents dynamic state (generation, age, last evolution timestamp, last staked timestamp).

**Events:**
*   `CrystalMinted`
*   `CrystalEvolved`
*   `TraitCrafted`
*   `CrystalStaked`
*   `CrystalUnstaked`
*   `DustClaimed`
*   `GuardianSet`
*   `StakingPaused`
*   `StakingUnpaused`

**Function Categories & Summaries (> 20 Functions Total):**

1.  **Core ERC-721 Functions (Inherited/Overridden):**
    *   `balanceOf(address owner)`: Get number of crystals owned by an address.
    *   `ownerOf(uint256 tokenId)`: Get the owner of a crystal.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer of a crystal.
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe transfer with data.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Standard transfer of a crystal.
    *   `approve(address to, uint256 tokenId)`: Approve address to transfer a crystal.
    *   `setApprovalForAll(address operator, bool approved)`: Approve/revoke operator for all crystals.
    *   `getApproved(uint256 tokenId)`: Get approved address for a crystal.
    *   `isApprovedForAll(address owner, address operator)`: Check if operator is approved for all crystals.
    *   `supportsInterface(bytes4 interfaceId)`: ERC165 interface support check.
    *   `tokenURI(uint256 tokenId)`: Get the dynamic metadata URI for a crystal.

2.  **Core ERC-20 (Chronicle Dust) Functions (Interactions via address):**
    *   `dustTotalSupply()`: Get total supply of Dust.
    *   `dustBalanceOf(address account)`: Get Dust balance of an address.
    *   `dustTransfer(address to, uint256 amount)`: Transfer Dust from caller.
    *   `dustAllowance(address owner, address spender)`: Get allowance.
    *   `dustApprove(address spender, uint256 amount)`: Approve spender.
    *   `dustTransferFrom(address from, address to, uint256 amount)`: Transfer Dust using allowance.

3.  **Crystal Management Functions:**
    *   `mintInitialCrystal()`: Mints a new Crystal (caller is owner). Includes initial attribute generation.
    *   `getCrystalAttributes(uint256 tokenId)`: View attributes of a crystal.
    *   `getCrystalState(uint256 tokenId)`: View dynamic state of a crystal.
    *   `triggerEvolution(uint256 tokenId)`: Initiates the evolution process for a crystal (burns Dust, updates state, potentially changes attributes).
    *   `craftNewTrait(uint256 tokenId, uint256 traitType, uint256 traitValue)`: Adds or modifies a specific trait using Dust.
    *   `reseedAttributes(uint256 tokenId)`: Reseeds/randomizes *all* attributes (high Dust cost/risk?).

4.  **Staking Functions:**
    *   `stakeCrystal(uint256 tokenId)`: Stakes a crystal owned by the caller.
    *   `unstakeCrystal(uint256 tokenId)`: Unstakes a crystal owned by the caller.
    *   `claimDustYield(uint256[] calldata tokenIds)`: Claims accumulated Dust yield for multiple staked crystals owned by the caller.
    *   `isCrystalStaked(uint256 tokenId)`: Check if a specific crystal is staked.
    *   `getPendingDust(uint256 tokenId)`: Calculate potential Dust yield for a staked crystal.
    *   `getTotalStakedCrystals()`: Get the total number of crystals currently staked across all users.

5.  **Admin/Guardian Functions:**
    *   `setGuardian(address _guardian)`: Set the address for the Guardian role (Owner only).
    *   `pauseStaking()`: Pause the staking and yield claiming process (Owner or Guardian).
    *   `unpauseStaking()`: Unpause staking (Owner or Guardian).
    *   `setBaseDustYield(uint256 _baseYieldPerSecond)`: Set the base Dust yield rate (Owner only).
    *   `setEvolutionCost(uint256 _cost)`: Set the Dust cost for evolution (Owner only).
    *   `setCraftingCost(uint256 _cost)`: Set the Dust cost for crafting (Owner only).

6.  **View Functions (Additional):**
    *   `getGuardian()`: Get the current Guardian address.
    *   `getStakingPausedStatus()`: Check if staking is paused.
    *   `getBaseDustYield()`: Get the current base Dust yield rate.
    *   `getEvolutionCost()`: Get the current evolution cost.
    *   `getCraftingCost()`: Get the current crafting cost.
    *   `getTotalMintedCrystals()`: Get the total number of crystals minted so far.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom Errors for better revert messages
error NotCrystalOwnerOrApproved();
error CrystalNotStaked();
error CrystalAlreadyStaked();
error StakingIsPaused();
error InsufficientDust(uint256 required, uint256 has);
error InvalidTrait();
error CannotTransferStakedCrystal();

contract ChronicleCrystals is ERC721, Ownable, IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    using SafeMath for uint256;

    // --- State Variables ---

    // Address of the Chronicle Dust ERC-20 contract
    IERC20 public immutable chronicleDust;

    // Base URI for dynamic metadata
    string private _baseTokenURI;

    // Structs for Crystal data
    struct CrystalAttributes {
        uint256 attribute1; // e.g., Color, Shape
        uint256 attribute2; // e.g., Pattern, Texture
        uint256 attribute3; // e.g., Core Type, Aura
        // Add more attributes as needed
    }

    struct CrystalState {
        uint256 generation;
        uint256 mintTimestamp;
        uint256 lastEvolutionTimestamp;
        uint256 lastStakedTimestamp; // 0 if not staked or unstaked
        bool isStaked;
    }

    // Mappings for Crystal data
    mapping(uint256 => CrystalAttributes) private _crystalAttributes;
    mapping(uint256 => CrystalState) private _crystalState;

    // Admin roles
    address public guardian;

    // System parameters
    uint256 public baseDustYieldPerSecond = 100; // Dust units per second staked
    uint256 public evolutionCost = 5000; // Dust units to evolve
    uint256 public craftingCost = 2000; // Dust units to craft a trait

    // Pause mechanism
    bool public stakingPaused = false;

    // Keep track of staked tokens per owner (Gas concerns: this can become expensive
    // for users with many staked tokens. A more gas-efficient approach might involve
    // users providing token IDs for staking actions rather than querying lists,
    // or using a specialized library for iterable mappings)
    mapping(address => uint256[] private _stakedTokenIdsByOwner; // This mapping should ideally be private and managed internally

    // --- Events ---

    event CrystalMinted(uint256 indexed tokenId, address indexed owner);
    event CrystalEvolved(uint256 indexed tokenId, uint256 newGeneration, CrystalAttributes newAttributes);
    event TraitCrafted(uint256 indexed tokenId, uint256 traitType, uint256 traitValue);
    event CrystalStaked(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event CrystalUnstaked(uint256 indexed tokenId, address indexed owner, uint256 timestamp, uint256 yieldedDust);
    event DustClaimed(address indexed owner, uint256[] indexed tokenIds, uint256 totalClaimedDust);
    event GuardianSet(address indexed oldGuardian, address indexed newGuardian);
    event StakingPaused(uint256 timestamp);
    event StakingUnpaused(uint256 timestamp);

    // --- Modifiers ---

    modifier onlyGuardianOrOwner() {
        require(msg.sender == owner() || msg.sender == guardian, "Not owner or guardian");
        _;
    }

    // --- Constructor ---

    constructor(address _dustTokenAddress, string memory baseURI)
        ERC721("Chronicle Crystal", "CHC")
        Ownable(msg.sender)
    {
        chronicleDust = IERC20(_dustTokenAddress);
        _baseTokenURI = baseURI;
        guardian = msg.sender; // Owner is initially the guardian
    }

    // --- ERC-721 Functions (Inherited/Overridden) ---

    // Override to prevent transfer if staked
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Check if the crystal is staked before allowing transfer (if transferring 1 token)
        if (batchSize == 1) {
             if (_crystalState[tokenId].isStaked) {
                revert CannotTransferStakedCrystal();
            }
        }
        // Note: For batched transfers, this check would need to be inside a loop,
        // or the batch transfer mechanism needs to be handled separately.
        // Standard ERC721 doesn't have batch transfers, but extensions might.
        // Assuming standard ERC721 _beforeTokenTransfer is called for single tokens.

        // Handle staking lists if maintaining them (gas heavy) - NOT RECOMMENDED IN PRACTICE
        // if (from != address(0)) {
        //     _removeStakedToken(from, tokenId);
        // }
        // if (to != address(0) && _crystalState[tokenId].isStaked) {
        //     _addStakedToken(to, tokenId);
        // }
        // The current design avoids managing this list for gas efficiency and relies on per-token checks.
    }

    // Override burn if needed, though not strictly necessary here
    function _burn(uint256 tokenId) internal override {
        // Optional: Add specific logic before burning, e.g., ensure unstaked
        require(!_crystalState[tokenId].isStaked, "Cannot burn staked crystal");
        super._burn(tokenId);
        // Clean up state and attributes mappings
        delete _crystalAttributes[tokenId];
        delete _crystalState[tokenId];
        // If maintaining staked lists, clean up here too (gas heavy)
    }

    // Dynamic metadata URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and caller is authorized (optional, depends on desired privacy)
        // Alternatively, just require token exists: require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Return a base URI plus the token ID.
        // An external service (e.g., an API or IPFS gateway) will receive this URI,
        // query the contract for the token's attributes and state using view functions,
        // and generate the final JSON metadata including image URI dynamically.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    // We also need to implement onERC721Received if we want other contracts to be able to deposit NFTs here (e.g., for staking)
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // This contract isn't designed to receive arbitrary NFTs, only its own crystals for staking.
        // A simpler implementation would be to ensure only the staking function calls transferFrom.
        // If we *did* allow deposits for staking initiated by a different contract, this would be needed.
        // For this example, we assume staking is initiated by the NFT owner calling `stakeCrystal`.
        // So, this implementation simply returns the required value, allowing transfers *to* this contract.
        return this.onERC721Received.selector;
    }


    // --- Core ERC-20 (Chronicle Dust) Interactions ---
    // These are wrappers to interact with the separate Dust token contract.
    // Note: User interacts with Dust directly for approval, but this contract interacts with it for transfers (burning/minting).

    function dustTotalSupply() public view returns (uint256) {
        return chronicleDust.totalSupply();
    }

    function dustBalanceOf(address account) public view returns (uint256) {
        return chronicleDust.balanceOf(account);
    }

    // Users will interact with the Dust contract directly for transfer, allowance, approve
    // These wrappers are mostly for internal clarity or specific cases if needed.
    // Omitting direct user transfer/approve wrappers here as they'd call Dust contract directly.
    // Adding burn functionality as a utility sink:
    function burnDust(uint256 amount) public {
        chronicleDust.transferFrom(msg.sender, address(this), amount); // User must approve this contract first
        // Optional: Add specific logic/event for burning
        chronicleDust.transfer(address(0), amount); // Send to burn address
    }


    // --- Crystal Management Functions ---

    function mintInitialCrystal() public {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _crystalAttributes[newItemId] = _generateInitialAttributes(newItemId, msg.sender);
        _crystalState[newItemId] = CrystalState({
            generation: 1,
            mintTimestamp: block.timestamp,
            lastEvolutionTimestamp: block.timestamp, // Starts evolved
            lastStakedTimestamp: 0, // Not staked initially
            isStaked: false
        });

        _safeMint(msg.sender, newItemId); // Mints to caller
        emit CrystalMinted(newItemId, msg.sender);
    }

    function getCrystalAttributes(uint256 tokenId) public view returns (CrystalAttributes memory) {
        _requireOwned(tokenId); // Ensure token exists and caller is authorized
        return _crystalAttributes[tokenId];
    }

     function getCrystalState(uint256 tokenId) public view returns (CrystalState memory) {
         _requireOwned(tokenId); // Ensure token exists and caller is authorized
         return _crystalState[tokenId];
     }

    function triggerEvolution(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Not crystal owner");
        require(!_crystalState[tokenId].isStaked, "Cannot evolve staked crystal"); // Prevent evolution while staked

        // Check Dust balance and allowance
        if (chronicleDust.balanceOf(msg.sender) < evolutionCost) {
            revert InsufficientDust(evolutionCost, chronicleDust.balanceOf(msg.sender));
        }
        require(chronicleDust.allowance(msg.sender, address(this)) >= evolutionCost, "Dust allowance too low");

        // Burn Dust (transferFrom requires prior approval by the user)
        bool success = chronicleDust.transferFrom(msg.sender, address(this), evolutionCost);
        require(success, "Dust transfer failed");
        // Send the received dust to address(0) to burn it
        chronicleDust.transfer(address(0), evolutionCost);


        // Perform evolution logic
        CrystalState storage state = _crystalState[tokenId];
        state.generation = state.generation.add(1);
        state.lastEvolutionTimestamp = block.timestamp;

        // Example simple attribute evolution: increment an attribute based on generation
        CrystalAttributes storage attributes = _crystalAttributes[tokenId];
        attributes.attribute1 = attributes.attribute1.add(state.generation % 10); // Simple change based on generation

        // More complex evolution logic could involve randomness, other state variables, etc.
        // _evolveAttributes(tokenId, attributes, state); // Call internal complex evolution

        emit CrystalEvolved(tokenId, state.generation, attributes);
    }

    function craftNewTrait(uint256 tokenId, uint256 traitType, uint256 traitValue) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Not crystal owner");
        require(!_crystalState[tokenId].isStaked, "Cannot craft on staked crystal");

        // Check Dust balance and allowance
        if (chronicleDust.balanceOf(msg.sender) < craftingCost) {
             revert InsufficientDust(craftingCost, chronicleDust.balanceOf(msg.sender));
        }
         require(chronicleDust.allowance(msg.sender, address(this)) >= craftingCost, "Dust allowance too low");

        // Burn Dust
        bool success = chronicleDust.transferFrom(msg.sender, address(this), craftingCost);
        require(success, "Dust transfer failed");
        chronicleDust.transfer(address(0), craftingCost);

        // Apply trait crafting logic
        CrystalAttributes storage attributes = _crystalAttributes[tokenId];
        _applyCraftedTrait(attributes, traitType, traitValue);

        emit TraitCrafted(tokenId, traitType, traitValue);
    }

     function reseedAttributes(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Not crystal owner");
        require(!_crystalState[tokenId].isStaked, "Cannot reseed staked crystal");

        uint256 reseedCost = craftingCost.mul(3); // Example: make reseeding more expensive

         // Check Dust balance and allowance
        if (chronicleDust.balanceOf(msg.sender) < reseedCost) {
             revert InsufficientDust(reseedCost, chronicleDust.balanceOf(msg.sender));
        }
         require(chronicleDust.allowance(msg.sender, address(this)) >= reseedCost, "Dust allowance too low");

        // Burn Dust
        bool success = chronicleDust.transferFrom(msg.sender, address(this), reseedCost);
        require(success, "Dust transfer failed");
        chronicleDust.transfer(address(0), reseedCost);

        // Regenerate attributes
        _crystalAttributes[tokenId] = _generateInitialAttributes(tokenId, msg.sender); // Use initial generation logic

        // Optional: Reset state partially, e.g., generation? Depends on game design.
        // CrystalState storage state = _crystalState[tokenId];
        // state.generation = 1; // Or reset to a specific value

        emit CrystalEvolved(tokenId, _crystalState[tokenId].generation, _crystalAttributes[tokenId]); // Re-using evolve event for state change clarity
    }

    // --- Staking Functions ---

    function stakeCrystal(uint256 tokenId) public {
        // Check ownership and approval
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Not crystal owner");
        // No need to check getApproved/isApprovedForAll here as msg.sender is owner

        // Check if staking is paused
        require(!stakingPaused, StakingIsPaused());

        // Check if already staked
        if (_crystalState[tokenId].isStaked) {
            revert CrystalAlreadyStaked();
        }

        // Transfer NFT to this contract
        _transfer(owner, address(this), tokenId); // Standard transfer is fine here

        // Update staking state
        CrystalState storage state = _crystalState[tokenId];
        state.isStaked = true;
        state.lastStakedTimestamp = block.timestamp;

        // Add to staked token list (Gas concerns) - REMOVING list management for simplicity/gas
        // _addStakedToken(owner, tokenId);

        emit CrystalStaked(tokenId, owner, block.timestamp);
    }

    function unstakeCrystal(uint256 tokenId) public {
        // Check ownership (of the staked NFT, which is this contract) and original owner
        address originalOwner = _ownerOf(tokenId); // Use internal to bypass staked check
        require(msg.sender == originalOwner, "Not original owner"); // Only original owner can unstake

        // Check if staked
        if (!_crystalState[tokenId].isStaked) {
            revert CrystalNotStaked();
        }

        // Calculate pending dust before state change
        uint256 pendingDust = _calculateDustYield(tokenId);

        // Update staking state
        CrystalState storage state = _crystalState[tokenId];
        state.isStaked = false;
        state.lastStakedTimestamp = 0; // Reset timestamp

         // Remove from staked token list (Gas concerns) - REMOVING list management
        // _removeStakedToken(msg.sender, tokenId);

        // Transfer NFT back to original owner
        _transfer(address(this), msg.sender, tokenId);

        // Mint and transfer dust (only if > 0)
        if (pendingDust > 0) {
            _mintDustForYield(msg.sender, pendingDust);
             // Optional: Emit DustClaimed event here or combine with claim function
        }

        emit CrystalUnstaked(tokenId, msg.sender, block.timestamp, pendingDust);
    }

    // Allows claiming dust without unstaking
    function claimDustYield(uint256[] calldata tokenIds) public {
        require(!stakingPaused, StakingIsPaused());
        uint256 totalClaimed = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address originalOwner = _ownerOf(tokenId); // Check using internal to see who staked it
            require(msg.sender == originalOwner, "Not original owner of all tokens");
            require(_crystalState[tokenId].isStaked, "Token not staked");

            uint256 pending = _calculateDustYield(tokenId);

            if (pending > 0) {
                // Update timestamp *before* minting to prevent double claim
                _crystalState[tokenId].lastStakedTimestamp = block.timestamp;
                _mintDustForYield(msg.sender, pending);
                totalClaimed = totalClaimed.add(pending);
            }
        }

        if (totalClaimed > 0) {
             emit DustClaimed(msg.sender, tokenIds, totalClaimed);
        }
    }

    function isCrystalStaked(uint256 tokenId) public view returns (bool) {
         // No ownership check needed for this view
        return _crystalState[tokenId].isStaked;
    }

    function getPendingDust(uint256 tokenId) public view returns (uint256) {
        // No ownership check needed for this view
        if (!_crystalState[tokenId].isStaked) {
            return 0;
        }
        return _calculateDustYield(tokenId);
    }

     function getTotalStakedCrystals() public view returns (uint256) {
        // This is difficult to track efficiently with the current state without iterating all token IDs.
        // A dedicated counter or iterable mapping library would be needed for O(1) access.
        // For demonstration, returning 0 or implementing a potentially gas-heavy iteration is options.
        // A simple counter incremented/decremented on stake/unstake is best practice. Let's add that.
        return _totalStakedCrystals;
     }
     uint256 private _totalStakedCrystals; // Add state variable

    // Modify stake/unstake to update the counter
    function stakeCrystal(uint256 tokenId) public {
        // ... existing checks ...
        _transfer(owner, address(this), tokenId);
        // ... update state ...
        _totalStakedCrystals = _totalStakedCrystals.add(1); // Increment counter
        emit CrystalStaked(tokenId, owner, block.timestamp);
    }

    function unstakeCrystal(uint256 tokenId) public {
        // ... existing checks ...
        uint256 pendingDust = _calculateDustYield(tokenId);
        // ... update state ...
        _totalStakedCrystals = _totalStakedCrystals.sub(1); // Decrement counter
        _transfer(address(this), msg.sender, tokenId);
        // ... mint dust ...
        emit CrystalUnstaked(tokenId, msg.sender, block.timestamp, pendingDust);
    }


    // --- Admin/Guardian Functions ---

    function setGuardian(address _guardian) public onlyOwner {
        address oldGuardian = guardian;
        guardian = _guardian;
        emit GuardianSet(oldGuardian, guardian);
    }

    function pauseStaking() public onlyGuardianOrOwner {
        stakingPaused = true;
        emit StakingPaused(block.timestamp);
    }

    function unpauseStaking() public onlyGuardianOrOwner {
        stakingPaused = false;
        emit StakingUnpaused(block.timestamp);
    }

    function setBaseDustYield(uint256 _baseYieldPerSecond) public onlyOwner {
        baseDustYieldPerSecond = _baseYieldPerSecond;
    }

    function setEvolutionCost(uint256 _cost) public onlyOwner {
        evolutionCost = _cost;
    }

    function setCraftingCost(uint256 _cost) public onlyOwner {
        craftingCost = _cost;
    }

    // --- View Functions (Additional Getters) ---

    function getGuardian() public view returns (address) {
        return guardian;
    }

    function getStakingPausedStatus() public view returns (bool) {
        return stakingPaused;
    }

     function getBaseDustYield() public view returns (uint256) {
        return baseDustYieldPerSecond;
     }

     function getEvolutionCost() public view returns (uint256) {
        return evolutionCost;
     }

     function getCraftingCost() public view returns (uint256) {
        return craftingCost;
     }

    function getTotalMintedCrystals() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- Internal Helper Functions ---

    // Generates initial attributes based on factors like tokenId, minter address, and timestamp
    function _generateInitialAttributes(uint256 tokenId, address minter) internal view returns (CrystalAttributes memory) {
        // Simple pseudorandom generation using block data and token ID/address
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, block.number)));

        return CrystalAttributes({
            attribute1: (seed % 1000) + 1, // Range 1-1000
            attribute2: ((seed / 1000) % 100) + 1, // Range 1-100
            attribute3: ((seed / 100000) % 10) + 1 // Range 1-10
        });
    }

    // Calculates the amount of Dust yielded for a staked crystal
    function _calculateDustYield(uint256 tokenId) internal view returns (uint256) {
        CrystalState memory state = _crystalState[tokenId];
        if (!state.isStaked || state.lastStakedTimestamp == 0 || stakingPaused) {
            return 0;
        }

        uint256 timeStaked = block.timestamp.sub(state.lastStakedTimestamp);
        // Yield could be more complex: influenced by attributes, generation, total staked, etc.
        uint256 yieldAmount = timeStaked.mul(baseDustYieldPerSecond);

        return yieldAmount;
    }

    // Mints Dust and transfers to the recipient
    function _mintDustForYield(address recipient, uint256 amount) internal {
        // Requires the Dust token contract to have a minting function
        // that is callable by this contract.
        // Assuming ChronicleDust contract has a mint function like:
        // `function mint(address to, uint256 amount) public onlyMinter { _mint(to, amount); }`
        // and this contract address is set as a Minter role in the Dust contract.
        ChronicleDust(address(chronicleDust)).mint(recipient, amount);
    }


    // Example internal evolution logic (can be complex)
    function _evolveAttributes(uint256 tokenId, CrystalAttributes storage attributes, CrystalState storage state) internal {
        // Add complex logic here based on state, time, external data (oracles?), etc.
        // Example: Small chance to change an attribute dramatically based on generation
        uint256 evolutionSeed = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, state.generation)));
        if (evolutionSeed % 10 == 0) { // 10% chance
            attributes.attribute2 = (attributes.attribute2 + (evolutionSeed % 50)) % 100 + 1; // Modify within range
        }
         // Add more complex attribute changes here...
    }

     // Example internal crafting logic
    function _applyCraftedTrait(CrystalAttributes storage attributes, uint256 traitType, uint256 traitValue) internal {
        // Basic validation for traitType/Value
        require(traitType > 0 && traitType <= 3, InvalidTrait()); // Example: only attributes 1, 2, 3 are craftable
        // Add more specific range checks for traitValue based on traitType if needed

        // Apply the crafted trait
        if (traitType == 1) attributes.attribute1 = traitValue;
        else if (traitType == 2) attributes.attribute2 = traitValue;
        else if (traitType == 3) attributes.attribute3 = traitValue;
        // Add cases for more attributes...
    }

    // Helper to check if caller is owner or approved (useful for view functions accessing sensitive data)
    // Note: _requireOwned(tokenId) from ERC721 already checks ownership, not approval.
    // If views should be callable by approved operators, this helper is useful.
    // For public views like getCrystalAttributes/State, deciding who can view is important.
    // Current implementation uses _requireOwned which means only owner or contract itself can view.
    // Let's remove this helper and rely on ERC721's internal checks where appropriate,
    // or make views truly public if attributes/state are not sensitive.
    // Making views public is more common for NFT metadata components.
    // Let's modify getCrystalAttributes/State to *not* require ownership check, assuming attributes/state are public data.

    // --- Count Functions (Internal Helpers for Staked List - REMOVING FOR GAS) ---
    // These helpers would manage the _stakedTokenIdsByOwner mapping, but are gas prohibitive.
    // Keeping them commented out to illustrate the pattern if gas were not an issue or using iterable mapping library.
    /*
    function _addStakedToken(address owner, uint256 tokenId) internal {
        _stakedTokenIdsByOwner[owner].push(tokenId);
    }

    function _removeStakedToken(address owner, uint256 tokenId) internal {
        uint256[] storage stakedTokens = _stakedTokenIdsByOwner[owner];
        for (uint i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == tokenId) {
                stakedTokens[i] = stakedTokens[stakedTokens.length - 1]; // Replace with last element
                stakedTokens.pop(); // Remove last element
                break;
            }
        }
    }
    */
}

// Dummy Chronicle Dust ERC-20 contract for demonstration purposes.
// In a real scenario, this would be a separate deployed contract with proper access control
// for its minting function (e.g., only callable by the ChronicleCrystals contract).
contract ChronicleDust is ERC20 {
    address public minter; // Address allowed to mint

    constructor(address _minter) ERC20("Chronicle Dust", "CDUST") {
        minter = _minter;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    // Function for the ChronicleCrystals contract to mint dust
    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    // Renounce minter role (optional security feature)
    function renounceMinter() public onlyMinter {
        minter = address(0);
    }
}
```

**Explanation of Advanced/Creative Aspects:**

1.  **Dynamic `tokenURI`:** The `tokenURI` function returns a URL that includes the `tokenId`. An off-chain service (which you would need to build) would listen for events or poll the contract's public view functions (`getCrystalAttributes`, `getCrystalState`) to get the latest state and attributes for that token ID, then generate the appropriate JSON metadata and image URL. This makes the NFT's appearance and properties change *after* minting, driven by on-chain actions.
2.  **On-Chain State & Attributes:** The `CrystalAttributes` and `CrystalState` structs are stored directly in the contract. Functions like `triggerEvolution` and `craftNewTrait` modify these on-chain structs, providing the basis for the dynamic NFT.
3.  **Staking & Yield:** The `stakeCrystal` and `unstakeCrystal` functions manage the locking of the NFT within the contract itself (via `_transfer`). The `claimDustYield` and `getPendingDust` functions calculate rewards based on the duration the NFT has been staked, using `block.timestamp`.
4.  **Utility Token Sink:** Dust (`chronicleDust`) isn't just earned; it's required to perform key actions (`triggerEvolution`, `craftNewTrait`, `reseedAttributes`). This creates a circular economy within the contract ecosystem. The Dust is burned when used for these actions.
5.  **Pseudo-Generative Attributes:** The `_generateInitialAttributes` uses simple on-chain data (`block.timestamp`, `block.difficulty`, `msg.sender`, `tokenId`, `block.number`) combined with `keccak256` to create initial attribute values. This isn't true visual generative art on-chain (which is very complex), but the *numeric representation* of the traits is generated on-chain. The evolution and crafting functions modify these numbers.
6.  **Role-Based Pausing:** The `guardian` role, in addition to the `owner`, can pause staking. This provides a potential layer of operational control separate from full ownership, which is common in more complex protocols.
7.  **Gas Considerations (and noted limitations):** The challenge of efficiently tracking all staked tokens per user is acknowledged. The provided code *removes* the gas-heavy list management approach (`_stakedTokenIdsByOwner`) in favor of per-token state checks (`_crystalState[tokenId].isStaked`) and relies on users knowing their token IDs for bulk actions like `claimDustYield`. A dedicated counter `_totalStakedCrystals` is added for a total count.
8.  **Separation of Concerns:** The Chronicle Crystal and Chronicle Dust contracts are separate, interacting via interfaces (`IERC20`). This is good practice. The Crystal contract needs the ability to *mint* Dust, requiring a specific function (`mint`) and access control (`onlyMinter`) on the Dust contract.

This contract provides a framework for a dynamic, interactive NFT ecosystem with integrated DeFi (staking) and utility token mechanics, going significantly beyond a standard static ERC-721 implementation. Remember that for a production system, you would need to deploy the `ChronicleDust` contract first, then deploy `ChronicleCrystals` with the Dust contract's address, and finally set the `ChronicleCrystals` contract address as the `minter` on the `ChronicleDust` contract. You would also need to build the off-chain service for dynamic metadata.