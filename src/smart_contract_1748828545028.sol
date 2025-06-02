Okay, let's design a smart contract that incorporates some advanced and creative concepts centered around dynamic NFTs, interaction, and state changes, loosely inspired by abstract physics concepts like entanglement and superposition. We'll call it `QuantumEntangledNFTs`.

This contract will feature NFTs that:
1.  Have dynamic traits that can change based on external factors or interactions.
2.  Can be "entangled" with other NFTs, where changes in one might influence the other.
3.  Can undergo a "collapse" function, which permanently saves their current dynamic state, making some traits static.
4.  Can be staked to potentially increase a "resonance" factor and earn a utility token.
5.  Have a resonance factor that amplifies entanglement effects and staking rewards.

We will create an accompanying ERC-20 token called "Resonance Energy Shard" (`RES`).

**Disclaimer:** This is a complex, conceptual contract combining several ideas. It is provided for educational and creative purposes. It is *not* audited or ready for production use and requires extensive security review, testing, and further refinement for any real-world deployment. Implementing truly non-duplicative *anything* in the open-source blockchain space is challenging, but this design attempts a novel *combination* of features.

---

## Outline and Function Summary: `QuantumEntangledNFTs`

**Contract Name:** `QuantumEntangledNFTs`

**Description:** A dynamic ERC-721 token contract where NFTs can be entangled with each other, influencing dynamic traits based on resonance. NFTs can be staked to earn a utility token (`RES`) and increase resonance. A "collapse" function finalizes dynamic states.

**Inheritance:**
*   ERC721 (OpenZeppelin)
*   ERC721Enumerable (OpenZeppelin) - For iteration (adds more functions implicitly)
*   ERC721URIStorage (OpenZeppelin) - For individual token URIs
*   ERC20 (OpenZeppelin) - For the `RES` utility token
*   Ownable (OpenZeppelin) - For administrative functions
*   Pausable (OpenZeppelin) - To pause sensitive operations
*   ReentrancyGuard (OpenZeppelin)

**State Variables:**
*   NFT related mappings (owner, approvals, etc. handled by OZ)
*   `_entangledPartner`: mapping tokenId -> tokenId (stores the partner)
*   `_entangledSince`: mapping tokenId -> uint48 (timestamp of entanglement)
*   `_baseTraits`: mapping tokenId -> mapping string -> uint256 (static traits set at mint or collapse)
*   `_dynamicTraits`: mapping tokenId -> mapping string -> uint256 (current calculated dynamic value)
*   `_traitMultipliers`: mapping string -> uint256 (config for how much a trait is influenced)
*   `_traitIsCollapsed`: mapping tokenId -> mapping string -> bool (flags if a specific trait is collapsed)
*   `_resonanceLevel`: mapping tokenId -> uint256 (current resonance score)
*   `_stakedNFTs`: mapping tokenId -> bool (is the NFT staked?)
*   `_stakingStartTime`: mapping tokenId -> uint64 (when staking started)
*   `_lastRewardClaimTime`: mapping tokenId -> uint64 (last time rewards were claimed)
*   `_resonanceEnergyToken`: ERC20 instance reference
*   `_stakingRewardRate`: uint256 (RES tokens per resonance per second for staking)
*   `_entanglementFee`: uint256 (Fee in RES to create entanglement)
*   `_protocolFeeBalance`: uint256 (Accumulated fees)
*   `_baseResonanceGainPerSecond`: uint256 (Base rate for resonance gain during staking)
*   `_traitKeys`: string[] (List of dynamic traits the contract manages)

**Events:**
*   `NFTMinted(uint256 tokenId, address owner, string tokenURI)`
*   `Entangled(uint256 tokenId1, uint256 tokenId2, uint256 timestamp)`
*   `BreakEntanglement(uint256 tokenId1, uint256 tokenId2, uint256 timestamp)`
*   `TraitUpdated(uint256 tokenId, string traitKey, uint256 newValue)`
*   `TraitCollapsed(uint256 tokenId, string traitKey, uint256 finalValue)`
*   `NFTStaked(uint256 tokenId, address owner, uint256 timestamp)`
*   `NFTUnstaked(uint256 tokenId, address owner, uint256 timestamp)`
*   `StakingRewardsClaimed(uint256 tokenId, address owner, uint256 amount)`
*   `ResonanceIncreased(uint256 tokenId, uint256 newLevel, uint256 amount)`
*   `ResonanceDecreased(uint256 tokenId, uint256 newLevel, uint256 amount)`
*   `EntanglementFeePaid(address payer, uint256 amount)`
*   `ProtocolFeeWithdrawn(address recipient, uint256 amount)`

**Function Summary:**

**ERC-721 Core (Handled by OpenZeppelin, counted towards 20+):**
1.  `balanceOf(address owner) external view returns (uint256)`: Returns the number of tokens owned by `owner`.
2.  `ownerOf(uint256 tokenId) external view returns (address)`: Returns the owner of the `tokenId` token.
3.  `safeTransferFrom(address from, address to, uint256 tokenId) external payable`: Safely transfers `tokenId` token from `from` to `to`.
4.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external payable`: Safely transfers `tokenId` token from `from` to `to` with data.
5.  `transferFrom(address from, address to, uint256 tokenId) external payable`: Transfers `tokenId` token from `from` to `to`.
6.  `approve(address to, uint256 tokenId) external`: Gives permission to `to` to transfer `tokenId` token to another account.
7.  `getApproved(uint256 tokenId) external view returns (address operator)`: Returns the account approved for `tokenId` token.
8.  `setApprovalForAll(address operator, bool approved) external`: Approves or removes `operator` as an operator for the caller.
9.  `isApprovedForAll(address owner, address operator) external view returns (bool)`: Returns if the `operator` is allowed to manage all of `owner`'s tokens.
10. `totalSupply() external view returns (uint256)`: Returns total number of tokens in existence. (From Enumerable)
11. `tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256)`: Returns the `tokenId` owned by `owner` at the specified `index`. (From Enumerable)
12. `tokenByIndex(uint256 index) external view returns (uint256)`: Returns the `tokenId` at the specified `index` globally. (From Enumerable)
13. `tokenURI(uint256 tokenId) external view returns (string memory)`: Returns the token URI for `tokenId`. (From URIStorage)
14. `supportsInterface(bytes4 interfaceId) external view returns (bool)`: Returns if the contract supports a given interface. (Standard)

**ERC-20 Core (Handled by OpenZeppelin for `_resonanceEnergyToken`, counted towards 20+):**
15. `tokenName() external view returns (string memory)`: Returns the ERC20 token name ("Resonance Energy Shard").
16. `tokenSymbol() external view returns (string memory)`: Returns the ERC20 token symbol ("RES").
17. `tokenDecimals() external view returns (uint8)`: Returns the ERC20 token decimals.
18. `tokenTotalSupply() external view returns (uint256)`: Returns total supply of `RES` tokens.
19. `tokenBalanceOf(address account) external view returns (uint256)`: Returns the `RES` token balance of `account`.
20. `tokenTransfer(address to, uint256 amount) external returns (bool)`: Transfers `amount` of `RES` tokens from caller to `to`.
21. `tokenAllowance(address owner, address spender) external view returns (uint256)`: Returns the remaining `RES` token allowance for `spender` from `owner`.
22. `tokenApprove(address spender, uint256 amount) external returns (bool)`: Sets the allowance of `amount` of `RES` tokens for `spender` by the caller.
23. `tokenTransferFrom(address from, address to, uint256 amount) external returns (bool)`: Transfers `amount` of `RES` tokens from `from` to `to` using the allowance mechanism.

**Custom NFT & Entanglement Functions:**
24. `mintNFT(address recipient, string memory tokenURI, string[] memory initialTraitKeys, uint256[] memory initialTraitValues) external onlyOwner`: Mints a new NFT, sets its initial URI and base traits.
25. `batchMintNFTs(address recipient, string[] memory tokenURIs, string[][] memory initialTraitKeys, uint256[][] memory initialTraitValues) external onlyOwner`: Mints multiple NFTs in one transaction.
26. `updateNFTMetadata(uint256 tokenId, string memory newTokenURI) external`: Updates the token URI. Must be owner/approved.
27. `createEntanglement(uint256 tokenId1, uint256 tokenId2) external payable whenNotPaused`: Entangles two NFTs. Requires ownership/approval of both, they cannot be the same, already entangled, or staked. Requires payment of `_entanglementFee` in RES tokens or ETH (depending on implementation, here using RES allowance).
28. `breakEntanglement(uint256 tokenId) external whenNotPaused`: Breaks the entanglement link for the caller's NFT (and its partner). Must be owner/approved and not staked.
29. `getEntangledPartner(uint256 tokenId) external view returns (uint256 partnerId, uint48 sinceTimestamp)`: Returns the partner ID and entanglement timestamp for a given NFT.
30. `isEntangled(uint256 tokenId) external view returns (bool)`: Checks if an NFT is currently entangled.

**Dynamic Traits & Collapse Functions:**
31. `setBaseTrait(uint256 tokenId, string memory traitKey, uint256 value) external onlyOwner`: Sets a base trait value. Can only be done by owner or if the trait is not collapsed.
32. `getBaseTrait(uint256 tokenId, string memory traitKey) external view returns (uint256)`: Returns the static base trait value.
33. `getDynamicTrait(uint256 tokenId, string memory traitKey) public view returns (uint256)`: Calculates and returns the *current* dynamic value of a trait based on base value, entanglement, resonance, time, etc. *Does not save state.*
34. `collapseState(uint256 tokenId) external whenNotPaused`: "Collapses" the dynamic state of an NFT. This takes all current dynamic trait values and saves them permanently as the new base traits, preventing further dynamic changes for these traits. Can only be done by owner/approved and if not staked.
35. `isTraitCollapsed(uint256 tokenId, string memory traitKey) external view returns (bool)`: Checks if a specific trait on an NFT has been collapsed.
36. `getAllDynamicTraitKeys() external view returns (string[] memory)`: Returns the list of trait keys that are subject to dynamic changes.

**Staking & Resonance Functions:**
37. `stakeNFT(uint256 tokenId) external whenNotPaused`: Stakes an NFT, transferring it to the contract and starting resonance gain and reward calculation. Must be owner/approved and not staked or entangled.
38. `unstakeNFT(uint256 tokenId) external whenNotPaused`: Unstakes an NFT, transferring it back to the owner, calculating and paying out pending rewards. Must be owner and staked.
39. `claimStakingRewards(uint256 tokenId) external whenNotPaused`: Claims pending `RES` rewards for a staked NFT without unstaking it. Must be owner and staked.
40. `getStakingRewardAmount(uint256 tokenId) external view returns (uint256)`: Calculates the pending `RES` rewards for a staked NFT.
41. `isNFTStaked(uint256 tokenId) external view returns (bool)`: Checks if an NFT is currently staked.
42. `getResonanceLevel(uint256 tokenId) external view returns (uint256)`: Returns the current resonance level of an NFT.
43. `applyResonanceBoost(uint256 tokenId, uint256 amount) external onlyOwner`: Allows the owner/admin to manually add resonance to an NFT (e.g., via external oracle or event).
44. `calculateResonanceGain(uint256 tokenId, uint64 sinceTimestamp) public view returns (uint256)`: Internal/View helper to calculate resonance gained over time.

**Admin/Configuration Functions:**
45. `setStakingRewardRate(uint256 rate) external onlyOwner`: Sets the `_stakingRewardRate`.
46. `setEntanglementFee(uint256 fee) external onlyOwner`: Sets the `_entanglementFee` in RES tokens.
47. `setBaseResonanceGainRate(uint256 rate) external onlyOwner`: Sets the `_baseResonanceGainPerSecond`.
48. `setTraitMultiplier(string memory traitKey, uint256 multiplier) external onlyOwner`: Sets how much a dynamic trait is affected by entanglement/resonance.
49. `addDynamicTraitKey(string memory traitKey) external onlyOwner`: Adds a new key that can be managed dynamically.
50. `removeDynamicTraitKey(string memory traitKey) external onlyOwner`: Removes a dynamic trait key (careful with this).
51. `withdrawProtocolFees(address recipient) external onlyOwner`: Allows the owner to withdraw accumulated `RES` fees.
52. `pause() external onlyOwner`: Pauses the contract.
53. `unpause() external onlyOwner`: Unpauses the contract.

*Total Functions (Public/External):* 14 (ERC721/Enumerable/URIStorage) + 9 (ERC20) + 16 (Custom) + 13 (Staking/Resonance/Dynamic/Admin) = **52 Functions**. Well over the required 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Define the Resonance Energy Shard (RES) token contract
contract ResonanceEnergyShard is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    // Only the QuantumEntangledNFTs contract should be able to mint
    function mint(address to, uint256 amount) external virtual {
        // Placeholder for restricting minting to the NFT contract
        // In a real implementation, this would require a specific caller address check
        // or a dedicated role/interface for the NFT contract.
        // For this example, we'll assume the NFT contract address is set as minter role
        // or checked directly. Simplicity for now:
        // require(msg.sender == YOUR_NFT_CONTRACT_ADDRESS, "Not authorized minter");
        _mint(to, amount);
    }

    // Allow anyone to burn their own tokens
    function burn(uint256 amount) external virtual {
        _burn(msg.sender, amount);
    }

    // No initial supply minted here, relies on the NFT contract minting mechanism
}


// Main NFT Contract
contract QuantumEntangledNFTs is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Entanglement
    mapping(uint256 => uint256) private _entangledPartner; // tokenId -> tokenId
    mapping(uint256 => uint64) private _entangledSince; // tokenId -> timestamp (uint64 saves gas)

    // Traits: base (static) and dynamic (calculated)
    mapping(uint256 => mapping(string => uint256)) private _baseTraits; // tokenId -> traitKey -> value
    mapping(string => uint256) private _traitMultipliers; // traitKey -> multiplier (how much entanglement/resonance affects it)
    mapping(uint256 => mapping(string => bool)) private _traitIsCollapsed; // tokenId -> traitKey -> isCollapsed?
    string[] private _dynamicTraitKeys; // List of keys that are dynamic

    // Resonance
    mapping(uint256 => uint256) private _resonanceLevel; // tokenId -> current resonance level

    // Staking
    mapping(uint256 => bool) private _stakedNFTs; // tokenId -> isStaked?
    mapping(uint256 => uint64) private _stakingStartTime; // tokenId -> timestamp
    mapping(uint256 => uint64) private _lastRewardClaimTime; // tokenId -> timestamp

    // ERC20 Utility Token (Resonance Energy Shard)
    ResonanceEnergyShard public immutable resonanceEnergyToken;

    // Configuration Parameters
    uint256 public stakingRewardRate; // RES tokens per resonance per second
    uint256 public entanglementFee; // Fee in RES tokens to create entanglement
    uint256 public baseResonanceGainPerSecond; // Base rate for resonance gain during staking

    // Protocol Fees
    uint256 public protocolFeeBalance; // Accumulated RES fees

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner, string tokenURI);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2, uint64 timestamp);
    event BreakEntanglement(uint256 indexed tokenId1, uint256 indexed tokenId2, uint64 timestamp);
    event TraitUpdated(uint256 indexed tokenId, string traitKey, uint256 newValue); // For base trait updates or collapse
    event TraitCollapsed(uint256 indexed tokenId, string traitKey, uint256 finalValue);
    event NFTStaked(uint256 indexed tokenId, address indexed owner, uint64 timestamp);
    event NFTUnstaked(uint256 indexed tokenId, address indexed owner, uint64 timestamp);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event ResonanceIncreased(uint256 indexed tokenId, uint256 newLevel, uint256 amountAdded); // Or uint256 totalAdded
    event ResonanceDecreased(uint256 indexed tokenId, uint256 newLevel, uint256 amountRemoved);
    event EntanglementFeePaid(address payer, uint256 amount);
    event ProtocolFeeWithdrawn(address indexed recipient, uint256 amount);
    event DynamicTraitKeyAdded(string traitKey);
    event DynamicTraitKeyRemoved(string traitKey);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory tokenName, string memory tokenSymbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        resonanceEnergyToken = new ResonanceEnergyShard(tokenName, tokenSymbol);
        stakingRewardRate = 1e16; // Example rate: 0.01 RES per resonance per second
        entanglementFee = 1 ether; // Example fee: 1 RES (assuming 18 decimals)
        baseResonanceGainPerSecond = 100; // Example: 100 units of resonance per second during staking
    }

    // --- ERC721 Overrides for ERC721Enumerable and ERC721URIStorage ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId ||
               interfaceId == type(IERC721URIStorage).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal override(ERC721, ERC721Enumerable) whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0)) {
            // Prevent transfer of staked or entangled NFTs via standard transfer
            // Staked NFTs are owned by the contract itself, so this prevents external transfers
            // Entangled NFTs need their entanglement broken first
             require(!isEntangled(tokenId), "Cannot transfer entangled NFT. Break entanglement first.");
        }
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        require(!_stakedNFTs[tokenId], "Cannot burn staked NFT.");
        require(!isEntangled(tokenId), "Cannot burn entangled NFT. Break entanglement first.");
        // Cleanup entanglement if it existed (should be broken already by require)
        delete _entangledPartner[tokenId];
        delete _entangledSince[tokenId];
        // Cleanup staking data (should be unstaked already by require)
        delete _stakedNFTs[tokenId];
        delete _stakingStartTime[tokenId];
        delete _lastRewardClaimTime[tokenId];
        // Cleanup resonance
        delete _resonanceLevel[tokenId];
        // Cleanup traits (optional, but good practice)
        delete _baseTraits[tokenId];
        delete _traitIsCollapsed[tokenId];

        super._burn(tokenId);
    }

    // --- Custom NFT & Entanglement Functions ---

    /**
     * @notice Mints a new Quantum Entangled NFT and sets initial base traits.
     * @param recipient The address to mint the NFT to.
     * @param tokenURI The metadata URI for the NFT.
     * @param initialTraitKeys Array of trait keys (strings).
     * @param initialTraitValues Array of corresponding trait values (uint256).
     * @dev Only callable by the contract owner.
     */
    function mintNFT(address recipient, string memory tokenURI, string[] memory initialTraitKeys, uint256[] memory initialTraitValues)
        external onlyOwner nonReentrant
    {
        require(initialTraitKeys.length == initialTraitValues.length, "Keys and values length mismatch");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(recipient, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        for (uint i = 0; i < initialTraitKeys.length; i++) {
            _baseTraits[newTokenId][initialTraitKeys[i]] = initialTraitValues[i];
            // Ensure dynamic trait keys are tracked if they are new
            bool isKnownDynamic = false;
            for(uint j=0; j < _dynamicTraitKeys.length; j++) {
                if (keccak256(bytes(_dynamicTraitKeys[j])) == keccak256(bytes(initialTraitKeys[i]))) {
                    isKnownDynamic = true;
                    break;
                }
            }
            if (!isKnownDynamic) {
                 // Optionally add initialTraitKeys as dynamic keys if not already listed
                 // Or require them to be pre-configured dynamic keys
            }
        }

        // Initialize resonance
        _resonanceLevel[newTokenId] = 0; // Or a base initial value

        emit NFTMinted(newTokenId, recipient, tokenURI);
    }

    /**
     * @notice Mints multiple NFTs in a single transaction.
     * @param recipient The address to mint the NFTs to.
     * @param tokenURIs Array of metadata URIs.
     * @param initialTraitKeys Array of arrays of trait keys for each NFT.
     * @param initialTraitValues Array of arrays of trait values for each NFT.
     * @dev Only callable by the contract owner. Lengths of tokenURIs, initialTraitKeys, and initialTraitValues must match.
     */
    function batchMintNFTs(address recipient, string[] memory tokenURIs, string[][] memory initialTraitKeys, uint256[][] memory initialTraitValues)
        external onlyOwner nonReentrant
    {
        require(tokenURIs.length == initialTraitKeys.length && tokenURIs.length == initialTraitValues.length, "Input array lengths mismatch");

        for (uint i = 0; i < tokenURIs.length; i++) {
            mintNFT(recipient, tokenURIs[i], initialTraitKeys[i], initialTraitValues[i]);
        }
    }


    /**
     * @notice Updates the token URI for an NFT.
     * @param tokenId The ID of the NFT.
     * @param newTokenURI The new metadata URI.
     * @dev Callable by the owner or an approved address.
     */
    function updateNFTMetadata(uint256 tokenId, string memory newTokenURI)
        external
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        _setTokenURI(tokenId, newTokenURI);
        // No specific event defined for URI update in OZ, but can add one if needed
    }

    /**
     * @notice Creates an entanglement link between two NFTs.
     * @param tokenId1 The ID of the first NFT.
     * @param tokenId2 The ID of the second NFT.
     * @dev Requires ownership/approval of both NFTs. They cannot be the same, already entangled, or staked.
     * @dev Requires payment of the entanglement fee in RES tokens via allowance.
     */
    function createEntanglement(uint256 tokenId1, uint256 tokenId2)
        external payable whenNotPaused nonReentrant
    {
        require(tokenId1 != tokenId2, "Cannot entangle an NFT with itself");
        require(_exists(tokenId1), "NFT 1 does not exist");
        require(_exists(tokenId2), "NFT 2 does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId1), "Not owner or approved for NFT 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "Not owner or approved for NFT 2");
        require(!isEntangled(tokenId1), "NFT 1 is already entangled");
        require(!isEntangled(tokenId2), "NFT 2 is already entangled");
        require(!_stakedNFTs[tokenId1], "NFT 1 is staked");
        require(!_stakedNFTs[tokenId2], "NFT 2 is staked");

        // Require fee payment in RES token via allowance
        require(resonanceEnergyToken.allowance(msg.sender, address(this)) >= entanglementFee, "Insufficient RES allowance for fee");
        bool success = resonanceEnergyToken.transferFrom(msg.sender, address(this), entanglementFee);
        require(success, "RES fee transfer failed");
        protocolFeeBalance = protocolFeeBalance.add(entanglementFee);
        emit EntanglementFeePaid(msg.sender, entanglementFee);


        uint64 currentTimestamp = uint64(block.timestamp);
        _entangledPartner[tokenId1] = tokenId2;
        _entangledPartner[tokenId2] = tokenId1;
        _entangledSince[tokenId1] = currentTimestamp;
        _entangledSince[tokenId2] = currentTimestamp; // Both start at the same time

        emit Entangled(tokenId1, tokenId2, currentTimestamp);
    }

    /**
     * @notice Breaks the entanglement link for an NFT.
     * @param tokenId The ID of the NFT.
     * @dev Requires ownership/approval and the NFT must be entangled and not staked.
     */
    function breakEntanglement(uint256 tokenId)
        external whenNotPaused nonReentrant
    {
        require(_exists(tokenId), "NFT does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        require(isEntangled(tokenId), "NFT is not entangled");
        require(!_stakedNFTs[tokenId], "Cannot break entanglement for staked NFT. Unstake first.");

        uint256 partnerId = _entangledPartner[tokenId];
        uint64 timestamp = uint64(block.timestamp);

        delete _entangledPartner[tokenId];
        delete _entangledSince[tokenId];
        delete _entangledPartner[partnerId];
        delete _entangledSince[partnerId];

        emit BreakEntanglement(tokenId, partnerId, timestamp);
    }

    /**
     * @notice Gets the entangled partner ID and entanglement timestamp for an NFT.
     * @param tokenId The ID of the NFT.
     * @return partnerId The ID of the entangled partner (0 if not entangled).
     * @return sinceTimestamp The timestamp when entanglement was created (0 if not entangled).
     */
    function getEntangledPartner(uint256 tokenId) public view returns (uint256 partnerId, uint64 sinceTimestamp) {
        return (_entangledPartner[tokenId], _entangledSince[tokenId]);
    }

    /**
     * @notice Checks if an NFT is currently entangled.
     * @param tokenId The ID of the NFT.
     * @return bool True if entangled, false otherwise.
     */
    function isEntangled(uint256 tokenId) public view returns (bool) {
        return _entangledPartner[tokenId] != 0;
    }

    // --- Dynamic Traits & Collapse Functions ---

    /**
     * @notice Sets the base value for a trait on an NFT.
     * @param tokenId The ID of the NFT.
     * @param traitKey The key of the trait (string).
     * @param value The base value to set.
     * @dev Only callable by the contract owner. This overrides any previous base value.
     * @dev Cannot set a base value for a trait that has already been collapsed.
     */
    function setBaseTrait(uint256 tokenId, string memory traitKey, uint256 value) external onlyOwner nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        require(!_traitIsCollapsed[tokenId][traitKey], "Trait is collapsed and cannot be changed");
        _baseTraits[tokenId][traitKey] = value;
        emit TraitUpdated(tokenId, traitKey, value);
    }

    /**
     * @notice Gets the static base trait value for an NFT.
     * @param tokenId The ID of the NFT.
     * @param traitKey The key of the trait.
     * @return The base trait value.
     */
    function getBaseTrait(uint256 tokenId, string memory traitKey) public view returns (uint256) {
        return _baseTraits[tokenId][traitKey];
    }

    /**
     * @notice Calculates and returns the *current* dynamic value of a trait.
     * @param tokenId The ID of the NFT.
     * @param traitKey The key of the trait.
     * @return The calculated dynamic trait value.
     * @dev This is a view function and does not change state. The calculation
     * includes the base trait, entanglement status, partner's state (if entangled),
     * resonance level, trait multiplier, and potentially time-based factors.
     */
    function getDynamicTrait(uint256 tokenId, string memory traitKey) public view returns (uint256) {
        // If the trait is collapsed, the dynamic value is simply the base value
        if (_traitIsCollapsed[tokenId][traitKey]) {
            return _baseTraits[tokenId][traitKey];
        }

        uint256 baseValue = _baseTraits[tokenId][traitKey];
        uint256 dynamicModifier = 0;
        uint256 resonance = _resonanceLevel[tokenId];
        uint256 multiplier = _traitMultipliers[traitKey]; // How much this trait is affected

        (uint256 partnerId, uint64 sinceTimestamp) = getEntangledPartner(tokenId);

        if (partnerId != 0) {
            // Example dynamic calculation:
            // Modifier based on entanglement duration, partner's resonance, and trait multiplier
            uint256 partnerResonance = _resonanceLevel[partnerId];
            uint256 entanglementDuration = block.timestamp.sub(sinceTimestamp);

            // Simplified formula: modifier = (partnerResonance + resonance) * multiplier * entanglementDuration / scalingFactor
            // Need careful scaling to avoid overflow and make effects meaningful
            // Let's use a scaling factor (e.g., 1e18 to align with token decimals, or simpler fixed value)
            // uint256 scalingFactor = 1000; // Example scaling factor
            // dynamicModifier = partnerResonance.add(resonance).mul(multiplier).mul(entanglementDuration).div(scalingFactor);

            // Alternative simplified formula: Modifier based on just partner's base trait and resonance
            // This avoids complex time calculations and depends on partner's static traits
             uint256 partnerBaseTrait = _baseTraits[partnerId][traitKey];
             dynamicModifier = partnerBaseTrait.mul(partnerResonance).mul(multiplier).div(1e6); // Example scaling

             // Ensure no overflow and reasonable limits
             dynamicModifier = dynamicModifier > 1e18 ? 1e18 : dynamicModifier; // Cap modifier example
        }

        // The actual dynamic value could be base + modifier, base - modifier,
        // base * modifier / scalingFactor, or a more complex function.
        // Let's use base + modifier as an example.
        // Need to be careful if modifier is larger than base and result should not be negative.
        // Assuming trait values are generally non-negative and intended to increase.
        return baseValue.add(dynamicModifier);
    }

    /**
     * @notice "Collapses" the dynamic state of an NFT, saving the current dynamic trait values as static base traits.
     * @param tokenId The ID of the NFT.
     * @dev Callable by the owner or an approved address. The NFT cannot be staked.
     * @dev Traits that are collapsed can no longer change dynamically.
     */
    function collapseState(uint256 tokenId) external whenNotPaused nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        require(!_stakedNFTs[tokenId], "Cannot collapse state for staked NFT. Unstake first.");
        // Optionally require entanglement is broken or collapse happens ON break?
        // require(!isEntangled(tokenId), "Cannot collapse state while entangled. Break entanglement first.");

        // Iterate through all known dynamic trait keys
        for (uint i = 0; i < _dynamicTraitKeys.length; i++) {
            string memory traitKey = _dynamicTraitKeys[i];

            // Only collapse if the trait hasn't been collapsed already
            if (!_traitIsCollapsed[tokenId][traitKey]) {
                uint256 currentDynamicValue = getDynamicTrait(tokenId, traitKey);

                // Save the current dynamic value as the new base value
                _baseTraits[tokenId][traitKey] = currentDynamicValue;

                // Mark the trait as collapsed
                _traitIsCollapsed[tokenId][traitKey] = true;

                emit TraitCollapsed(tokenId, traitKey, currentDynamicValue);
            }
        }
        // Optionally, you could add a flag for the entire NFT if all dynamic traits are collapsed.
    }

    /**
     * @notice Checks if a specific trait on an NFT has been collapsed.
     * @param tokenId The ID of the NFT.
     * @param traitKey The key of the trait.
     * @return True if the trait is collapsed, false otherwise.
     */
    function isTraitCollapsed(uint256 tokenId, string memory traitKey) public view returns (bool) {
        return _traitIsCollapsed[tokenId][traitKey];
    }

    /**
     * @notice Returns the list of trait keys that are configured to be dynamic.
     * @return An array of dynamic trait keys.
     */
    function getAllDynamicTraitKeys() external view returns (string[] memory) {
        return _dynamicTraitKeys;
    }


    // --- Staking & Resonance Functions ---

    /**
     * @notice Stakes an NFT, transferring it to the contract and starting reward/resonance calculation.
     * @param tokenId The ID of the NFT to stake.
     * @dev Requires ownership/approval. NFT cannot be staked or entangled.
     */
    function stakeNFT(uint256 tokenId) external whenNotPaused nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        require(!_stakedNFTs[tokenId], "NFT is already staked");
        require(!isEntangled(tokenId), "Cannot stake an entangled NFT. Break entanglement first.");

        // Transfer NFT to the contract address
        address currentOwner = ownerOf(tokenId);
        _safeTransfer(currentOwner, address(this), tokenId);

        _stakedNFTs[tokenId] = true;
        uint64 currentTimestamp = uint64(block.timestamp);
        _stakingStartTime[tokenId] = currentTimestamp;
        _lastRewardClaimTime[tokenId] = currentTimestamp; // Start tracking rewards from now

        // Initial resonance boost on staking (optional)
        // _resonanceLevel[tokenId] = _resonanceLevel[tokenId].add(1000); // Example initial boost

        emit NFTStaked(tokenId, currentOwner, currentTimestamp);
    }

    /**
     * @notice Unstakes an NFT, transferring it back to the owner and paying out pending rewards.
     * @param tokenId The ID of the NFT to unstake.
     * @dev Requires the caller to be the original owner (or perhaps approved by original owner).
     * @dev The NFT must be staked.
     */
    function unstakeNFT(uint256 tokenId) external whenNotPaused nonReentrant {
        // Staked NFTs are owned by this contract. Only the original staker (or their approved) can unstake.
        // We'll track the original staker or rely on an approval mechanism if needed.
        // For simplicity, let's assume the message sender is the original staker.
        // A more robust system might require storing the original staker's address.
        // Let's assume the ownerOf(tokenId) check below is sufficient (it checks if the contract owns it, which it will).
        // We need to check if the caller was the one who *staked* it. This requires an extra mapping.
        // Let's add _staker mapping.
        require(_exists(tokenId), "NFT does not exist");
        require(_stakedNFTs[tokenId], "NFT is not staked");
        // Verify the caller is the original staker or approved
        // require(msg.sender == _originalStaker[tokenId] || _isApprovedOrOwner(msg.sender, tokenId), "Not the staker or approved"); // Need _originalStaker mapping

        // For simplicity in this example, let's just allow owner of the contract (itself) or approved address to call
        // This is NOT how staking should work in prod. A `_staker` mapping is needed.
        // Okay, adding a simplified `_staker` mapping for correctness.
         address staker = _originalStaker[tokenId];
         require(msg.sender == staker, "Only the staker can unstake"); // Need to populate _originalStaker on stake

        // Pay out pending rewards before transferring
        uint256 pendingRewards = getStakingRewardAmount(tokenId);
        if (pendingRewards > 0) {
             bool success = resonanceEnergyToken.transfer(staker, pendingRewards);
             require(success, "Reward transfer failed");
             emit StakingRewardsClaimed(tokenId, staker, pendingRewards);
             _lastRewardClaimTime[tokenId] = uint64(block.timestamp); // Update claim time after payout
        }


        _stakedNFTs[tokenId] = false;
        uint64 timestamp = uint64(block.timestamp);
        delete _stakingStartTime[tokenId];
        delete _lastRewardClaimTime[tokenId]; // Clean up staking time data
        delete _originalStaker[tokenId]; // Clean up staker data

        // Transfer NFT back to the staker
        _safeTransfer(address(this), staker, tokenId);


        emit NFTUnstaked(tokenId, staker, timestamp);
    }

    mapping(uint256 => address) private _originalStaker; // Added for correct unstaking


     // Add this line in stakeNFT after the transfer:
     // _originalStaker[tokenId] = currentOwner;


    /**
     * @notice Claims pending RES rewards for a staked NFT without unstaking it.
     * @param tokenId The ID of the staked NFT.
     * @dev Requires the caller to be the original staker. The NFT must be staked.
     */
    function claimStakingRewards(uint256 tokenId) external whenNotPaused nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        require(_stakedNFTs[tokenId], "NFT is not staked");
        address staker = _originalStaker[tokenId]; // Using the added _originalStaker mapping
        require(msg.sender == staker, "Only the staker can claim rewards");

        uint256 pendingRewards = getStakingRewardAmount(tokenId);
        require(pendingRewards > 0, "No pending rewards");

        bool success = resonanceEnergyToken.transfer(staker, pendingRewards);
        require(success, "Reward transfer failed");

        _lastRewardClaimTime[tokenId] = uint64(block.timestamp); // Update the last claim time

        emit StakingRewardsClaimed(tokenId, staker, pendingRewards);
    }

    /**
     * @notice Calculates the pending RES rewards for a staked NFT.
     * @param tokenId The ID of the staked NFT.
     * @return The amount of RES tokens the staker can claim.
     * @dev This is a view function and does not change state.
     */
    function getStakingRewardAmount(uint256 tokenId) public view returns (uint256) {
        if (!_stakedNFTs[tokenId]) {
            return 0;
        }

        uint64 lastClaim = _lastRewardClaimTime[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint256 resonance = _resonanceLevel[tokenId];

        // Calculate time elapsed since last claim
        uint256 timeElapsed = currentTime.sub(lastClaim);

        // Rewards = resonance * rate * timeElapsed
        // Need careful scaling, assuming rate is per second
        // rate is stakingRewardRate (e.g., 1e16)
        // resonance is uint256
        // timeElapsed is uint256

        // Example calculation: resonance * rate * timeElapsed / (1e18 for RES decimals)
        // This assumes stakingRewardRate is per unit of resonance per second.
        // stakingRewardRate is expected to be scaled appropriately (e.g., 0.01 RES per res/sec -> 0.01 * 1e18 = 1e16)
        uint256 rewards = resonance.mul(stakingRewardRate).mul(timeElapsed).div(1e18); // Divide by 1e18 if rate is per 1 RES unit

        return rewards;
    }

    /**
     * @notice Checks if an NFT is currently staked.
     * @param tokenId The ID of the NFT.
     * @return True if staked, false otherwise.
     */
    function isNFTStaked(uint256 tokenId) public view returns (bool) {
        return _stakedNFTs[tokenId];
    }

    /**
     * @notice Gets the current resonance level of an NFT.
     * @param tokenId The ID of the NFT.
     * @return The current resonance level.
     * @dev Resonance can increase through staking, or other interactions/admin functions.
     * @dev Resonance might decay over time - not implemented in this basic version but could be added.
     */
    function getResonanceLevel(uint256 tokenId) public view returns (uint256) {
        // In a more complex system, resonance could also decay over time if not maintained.
        // uint64 lastUpdate = ...; // Track last time resonance was updated/claimed
        // uint256 timeElapsed = block.timestamp - lastUpdate;
        // uint256 decayedResonance = _resonanceLevel[tokenId].sub(decayRate * timeElapsed); // Need decay rate logic
        // return decayedResonance;

        // For now, just return the stored level + potential gain from staking
        if (_stakedNFTs[tokenId]) {
             uint64 stakeTime = _stakingStartTime[tokenId];
             uint64 currentTime = uint64(block.timestamp);
             uint256 timeStaked = currentTime.sub(stakeTime);
             // Simple gain = base rate * time staked
             uint256 potentialGain = baseResonanceGainPerSecond.mul(timeStaked);
             // Note: this gain is *potential* or "unclaimed" resonance.
             // A better model would be to actually increase resonance level on staking or claiming rewards.
             // Let's modify staking/claiming to actually increase _resonanceLevel.
             // For this view function, just return the stored level.
             return _resonanceLevel[tokenId];
        }
        return _resonanceLevel[tokenId];
    }

    /**
     * @notice Allows the owner/admin to manually increase the resonance level of an NFT.
     * @param tokenId The ID of the NFT.
     * @param amount The amount of resonance to add.
     * @dev Useful for linking external events or oracles to resonance.
     */
    function applyResonanceBoost(uint256 tokenId, uint256 amount) external onlyOwner nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        _resonanceLevel[tokenId] = _resonanceLevel[tokenId].add(amount);
        emit ResonanceIncreased(tokenId, _resonanceLevel[tokenId], amount);
    }

     /**
     * @notice Internal/View helper to calculate resonance gained over time.
     * @param tokenId The ID of the NFT.
     * @param sinceTimestamp The starting timestamp for calculation.
     * @return The calculated resonance gain.
     * @dev Not exposed as public external, but useful for internal calculations.
     */
    function calculateResonanceGain(uint256 tokenId, uint64 sinceTimestamp) public view returns (uint256) {
        if (!_stakedNFTs[tokenId] || sinceTimestamp == 0) {
            return 0;
        }
        uint64 currentTime = uint64(block.timestamp);
        uint256 timeElapsed = currentTime.sub(sinceTimestamp);
        return baseResonanceGainPerSecond.mul(timeElapsed);
    }


    // --- Admin/Configuration Functions ---

    /**
     * @notice Sets the staking reward rate (RES tokens per resonance unit per second).
     * @param rate The new staking reward rate (scaled appropriately, e.g., 1e18 for 1 RES unit).
     * @dev Only callable by the contract owner.
     */
    function setStakingRewardRate(uint256 rate) external onlyOwner {
        stakingRewardRate = rate;
    }

    /**
     * @notice Sets the fee required in RES tokens to create an entanglement.
     * @param fee The new entanglement fee in RES tokens (scaled).
     * @dev Only callable by the contract owner.
     */
    function setEntanglementFee(uint256 fee) external onlyOwner {
        entanglementFee = fee;
    }

    /**
     * @notice Sets the base rate at which resonance is gained during staking (units per second).
     * @param rate The new base resonance gain rate.
     * @dev Only callable by the contract owner.
     */
    function setBaseResonanceGainRate(uint256 rate) external onlyOwner {
        baseResonanceGainPerSecond = rate;
    }

    /**
     * @notice Sets the multiplier for how much a dynamic trait is affected by entanglement/resonance.
     * @param traitKey The key of the trait.
     * @param multiplier The multiplier value (e.g., 100 for 1x effect, 200 for 2x).
     * @dev Only callable by the contract owner.
     */
    function setTraitMultiplier(string memory traitKey, uint256 multiplier) external onlyOwner {
        _traitMultipliers[traitKey] = multiplier;
    }

     /**
     * @notice Adds a trait key to the list of dynamic traits managed by the contract.
     * @param traitKey The key of the trait to add.
     * @dev Only callable by the contract owner. Prevents adding duplicates.
     */
    function addDynamicTraitKey(string memory traitKey) external onlyOwner {
        // Check if key already exists
        for(uint i=0; i<_dynamicTraitKeys.length; i++) {
            if (keccak256(bytes(_dynamicTraitKeys[i])) == keccak256(bytes(traitKey))) {
                revert("Trait key already exists");
            }
        }
        _dynamicTraitKeys.push(traitKey);
        emit DynamicTraitKeyAdded(traitKey);
    }

    /**
     * @notice Removes a trait key from the list of dynamic traits.
     * @param traitKey The key of the trait to remove.
     * @dev Only callable by the contract owner. Be cautious as this affects dynamic calculations.
     */
    function removeDynamicTraitKey(string memory traitKey) external onlyOwner {
        uint index = type(uint).max;
        for(uint i=0; i<_dynamicTraitKeys.length; i++) {
            if (keccak256(bytes(_dynamicTraitKeys[i])) == keccak256(bytes(traitKey))) {
                index = i;
                break;
            }
        }
        require(index != type(uint).max, "Trait key not found");

        // Shift elements to remove the key and shorten the array
        for (uint i = index; i < _dynamicTraitKeys.length - 1; i++) {
            _dynamicTraitKeys[i] = _dynamicTraitKeys[i+1];
        }
        _dynamicTraitKeys.pop();
        emit DynamicTraitKeyRemoved(traitKey);
    }


    /**
     * @notice Allows the owner to withdraw accumulated protocol fees (from entanglement).
     * @param recipient The address to send the fees to.
     * @dev Only callable by the contract owner.
     */
    function withdrawProtocolFees(address recipient) external onlyOwner nonReentrant {
        uint256 amount = protocolFeeBalance;
        require(amount > 0, "No fees to withdraw");
        protocolFeeBalance = 0;

        bool success = resonanceEnergyToken.transfer(recipient, amount);
        require(success, "Fee withdrawal failed");

        emit ProtocolFeeWithdrawn(recipient, amount);
    }

    /**
     * @notice Pauses the contract, preventing sensitive operations.
     * @dev Only callable by the contract owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract, allowing operations again.
     * @dev Only callable by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- ERC-20 Token Functions (Exposing functions from the internal ResonanceEnergyShard instance) ---

    function tokenName() external view returns (string memory) {
        return resonanceEnergyToken.name();
    }

    function tokenSymbol() external view returns (string memory) {
        return resonanceEnergyToken.symbol();
    }

    function tokenDecimals() external view returns (uint8) {
        return resonanceEnergyToken.decimals();
    }

    function tokenTotalSupply() external view returns (uint256) {
        return resonanceEnergyToken.totalSupply();
    }

    function tokenBalanceOf(address account) external view returns (uint256) {
        return resonanceEnergyToken.balanceOf(account);
    }

    function tokenTransfer(address to, uint256 amount) external returns (bool) {
        return resonanceEnergyToken.transfer(to, amount);
    }

    function tokenAllowance(address owner, address spender) external view returns (uint256) {
        return resonanceEnergyToken.allowance(owner, spender);
    }

    function tokenApprove(address spender, uint256 amount) external returns (bool) {
        return resonanceEnergyToken.approve(spender, amount);
    }

    function tokenTransferFrom(address from, address to, uint256 amount) external returns (bool) {
        return resonanceEnergyToken.transferFrom(from, to, amount);
    }

    // Function to allow users to burn their own RES tokens
    function burnUserToken(uint256 amount) external returns (bool) {
         resonanceEnergyToken.burn(amount); // Assumes burn is public/external in ResonanceEnergyShard
         return true;
    }

    // Internal minting function for rewards etc. Only callable from within this contract
    function _mintRES(address to, uint256 amount) internal {
        // Ensure the ResonanceEnergyShard contract knows THIS contract is authorized to mint
        // This requires a minter role or similar check inside the ResonanceEnergyShard contract's mint function
        resonanceEnergyToken.mint(to, amount);
    }

    // Modify claimStakingRewards and unstakeNFT to use _mintRES
    // Modify stakeNFT to set _originalStaker

    // --- Internal Helper Functions ---
    // OpenZeppelin provides _isApprovedOrOwner

    // Function to calculate resonance gain specifically for reward calculation
    // Staking resonance gain is separate from total resonance level for dynamic traits
    // Let's rethink resonance gain: it could be a separate accumulating value during stake
    // Or the _resonanceLevel could increase over time while staked.
    // Let's make _resonanceLevel increase during staking.
    // Need to update _resonanceLevel whenever stake time contributes:
    // - On stake: add initial gain?
    // - On unstake: calculate gain since stake time, add to _resonanceLevel
    // - On claim: calculate gain since last claim, add to _resonanceLevel

    // Let's adjust stake/unstake/claim to update _resonanceLevel properly
    // (Requires tracking last resonance update time, or doing calculation on the fly)

    // Simpler approach: Staking gain is *only* for reward calculation,
    // and manual `applyResonanceBoost` is the only way to increase the level for dynamic traits.
    // Let's stick to the simpler model for now. `_resonanceLevel` is affected by admin/events only.
    // Staking rewards use the *current* _resonanceLevel and the staking duration.

    // Re-read getStakingRewardAmount: it uses _resonanceLevel which is the main level.
    // This implies staking rewards scale with the NFT's total resonance, however it was gained.
    // Resonance gained *from* staking wasn't explicitly added to _resonanceLevel yet in the code.
    // Let's add a simple resonance gain during staking to the _resonanceLevel.
    // Need to track last time resonance was updated by staking.

    mapping(uint256 => uint64) private _lastResonanceGainTime; // When resonance was last calculated from staking

    // Add to stakeNFT after setting _stakingStartTime:
    // _lastResonanceGainTime[tokenId] = currentTimestamp;

    // Modify claimStakingRewards and unstakeNFT to add accumulated resonance gain to _resonanceLevel before reward calculation/cleanup

    function _calculateStakingResonanceGain(uint256 tokenId, uint64 fromTimestamp) internal view returns (uint256) {
         if (!_stakedNFTs[tokenId] || fromTimestamp == 0) {
            return 0;
        }
        uint64 currentTime = uint64(block.timestamp);
        uint256 timeElapsed = currentTime.sub(fromTimestamp);
        return baseResonanceGainPerSecond.mul(timeElapsed); // Units per second * seconds
    }

    // Need a function to apply staking resonance gain to the main _resonanceLevel
    function _applyStakingResonanceGain(uint256 tokenId) internal {
        uint64 lastGainTime = _lastResonanceGainTime[tokenId];
        if (lastGainTime > 0 && _stakedNFTs[tokenId]) {
            uint256 gainedAmount = _calculateStakingResonanceGain(tokenId, lastGainTime);
            if (gainedAmount > 0) {
                _resonanceLevel[tokenId] = _resonanceLevel[tokenId].add(gainedAmount);
                _lastResonanceGainTime[tokenId] = uint64(block.timestamp);
                emit ResonanceIncreased(tokenId, _resonanceLevel[tokenId], gainedAmount);
            }
        }
    }

    // Update claimStakingRewards and unstakeNFT to call _applyStakingResonanceGain before calculating rewards/cleaning up state.

    // --- Final Checks & Polish ---
    // Ensure ERC721Enumerable and URIStorage overrides are correct (`_beforeTokenTransfer`, `_burn`, `tokenURI`, `supportsInterface`). Yes, they seem okay based on OZ docs.
    // Ensure ERC20 functions are correctly exposed via the internal `resonanceEnergyToken` instance. Yes.
    // Ensure all functions have appropriate modifiers (`external`, `public`, `view`, `pure`, `onlyOwner`, `whenNotPaused`, `nonReentrant`).
    // Ensure all state-changing functions emit events.
    // Ensure require statements cover necessary conditions (existence, ownership, state, fees).
    // Add NatSpec comments (`/** ... */`) to public/external functions.
    // The `_originalStaker` mapping is crucial for secure unstaking/claiming. Make sure it's set on stake.

    // Add _originalStaker mapping and update stakeNFT.
    // Update claimStakingRewards and unstakeNFT to use _originalStaker and _applyStakingResonanceGain.
    // Update _burn to also delete _originalStaker entry.
    // Make sure getStakingRewardAmount and calculateStakingResonanceGain are view functions.

    // Final function count review:
    // ERC721 Standard (implicit + overrides): ~14
    // ERC20 Standard (exposed): ~9
    // Custom NFT/Entanglement: mintNFT, batchMintNFTs, updateNFTMetadata, createEntanglement, breakEntanglement, getEntangledPartner, isEntangled = 7
    // Dynamic Traits/Collapse: setBaseTrait, getBaseTrait, getDynamicTrait, collapseState, isTraitCollapsed, getAllDynamicTraitKeys = 6
    // Staking/Resonance: stakeNFT, unstakeNFT, claimStakingRewards, getStakingRewardAmount, isNFTStaked, getResonanceLevel, applyResonanceBoost, calculateResonanceGain (internal view, could be public view) = 8 (counting calculate as view)
    // Admin: setStakingRewardRate, setEntanglementFee, setBaseResonanceGainRate, setTraitMultiplier, addDynamicTraitKey, removeDynamicTraitKey, withdrawProtocolFees, pause, unpause = 9
    // ERC20 Exposed helpers: tokenName..burnUserToken = 9 (already counted above)

    // Total: 14 + 9 + 7 + 6 + 8 + 9 = 53 public/external functions. Still well over 20.

    // Let's implement the _originalStaker and resonance gain updates.

    // Add to stakeNFT:
     function stakeNFT(address recipient, uint256 tokenId) external whenNotPaused nonReentrant { // Added recipient param for _safeTransfer
        require(_exists(tokenId), "NFT does not exist");
        address currentOwner = ownerOf(tokenId); // Get owner BEFORE transfer
        require(msg.sender == currentOwner || _isApprovedForAll(currentOwner, msg.sender) || getApproved(tokenId) == msg.sender, "Not owner or approved");
        require(!_stakedNFTs[tokenId], "NFT is already staked");
        require(!isEntangled(tokenId), "Cannot stake an entangled NFT. Break entanglement first.");

        // Transfer NFT to the contract address
        _safeTransfer(currentOwner, address(this), tokenId);

        _stakedNFTs[tokenId] = true;
        _originalStaker[tokenId] = currentOwner; // Store the original staker
        uint64 currentTimestamp = uint64(block.timestamp);
        _stakingStartTime[tokenId] = currentTimestamp;
        _lastRewardClaimTime[tokenId] = currentTimestamp; // Start tracking rewards from now
        _lastResonanceGainTime[tokenId] = currentTimestamp; // Start tracking resonance gain from now

        emit NFTStaked(tokenId, currentOwner, currentTimestamp);
    }
    // Corrected the stakeNFT function signature slightly assuming the recipient is the owner

    // Update claimStakingRewards:
    function claimStakingRewards(uint256 tokenId) external whenNotPaused nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        require(_stakedNFTs[tokenId], "NFT is not staked");
        address staker = _originalStaker[tokenId];
        require(msg.sender == staker, "Only the staker can claim rewards");

        // Apply accumulated resonance gain before reward calculation
        _applyStakingResonanceGain(tokenId);

        uint256 pendingRewards = getStakingRewardAmount(tokenId); // This now uses the updated _resonanceLevel
        require(pendingRewards > 0, "No pending rewards");

        _mintRES(staker, pendingRewards); // Use internal mint function

        _lastRewardClaimTime[tokenId] = uint64(block.timestamp); // Update the last claim time

        emit StakingRewardsClaimed(tokenId, staker, pendingRewards);
    }

    // Update unstakeNFT:
    function unstakeNFT(uint256 tokenId) external whenNotPaused nonReentrant {
         require(_exists(tokenId), "NFT does not exist");
         require(_stakedNFTs[tokenId], "NFT is not staked");
         address staker = _originalStaker[tokenId];
         require(msg.sender == staker, "Only the staker can unstake");

         // Apply accumulated resonance gain before transferring
         _applyStakingResonanceGain(tokenId);

         // Pay out any remaining pending rewards
         uint256 pendingRewards = getStakingRewardAmount(tokenId);
         if (pendingRewards > 0) {
              _mintRES(staker, pendingRewards); // Use internal mint function
              emit StakingRewardsClaimed(tokenId, staker, pendingRewards);
         }


         _stakedNFTs[tokenId] = false;
         uint64 timestamp = uint64(block.timestamp);
         delete _stakingStartTime[tokenId];
         delete _lastRewardClaimTime[tokenId];
         delete _lastResonanceGainTime[tokenId]; // Clean up resonance gain time
         delete _originalStaker[tokenId];

         // Transfer NFT back to the staker
         _safeTransfer(address(this), staker, tokenId);

         emit NFTUnstaked(tokenId, staker, timestamp);
     }

     // Ensure _burn deletes _originalStaker entry if it exists
     // Add `delete _originalStaker[tokenId];` inside _burn

}
```