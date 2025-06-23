Okay, here is a Solidity smart contract implementing a concept I call "Chrono-Bonded Artifacts". It's an ERC-721 based NFT where the metadata and functionality change based on time bonded, accumulated utility token ("Essence"), and simulated external data (oracle). It includes an internally managed fungible token for interaction.

This contract incorporates several advanced concepts:
1.  **Dynamic NFT Metadata:** `tokenURI` changes based on on-chain state (bonding status, elapsed time, accumulated essence, oracle data, evolution state).
2.  **Time-Based Yield Farming:** Artifacts, when "bonded", generate a utility token ("Essence") over time.
3.  **Internally Managed Fungible Token:** The contract manages balances and transfers of an associated "EssenceToken" without deploying a separate ERC-20 contract (implementing necessary functions internally).
4.  **State Evolution:** Artifacts can be permanently evolved by consuming Essence and meeting other conditions (like external data).
5.  **Simulated Oracle Dependency:** Artifact properties or evolution paths can be influenced by a state variable updated by an authorized address, simulating an oracle feed.
6.  **Pausability:** Standard safety mechanism.
7.  **Ownership/Admin Controls:** Standard access control.

It aims for a complex system within a single contract to meet the function count requirement while maintaining a cohesive theme.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/ERC165.sol"; // ERC165 for supportsInterface

/**
 * @title ChronoBondedArtifacts
 * @dev A smart contract for dynamic NFTs ("Artifacts") that evolve based on time bonded,
 *      accrued utility token ("Essence"), and simulated external data.
 *      Manages an internal supply of "EssenceToken".
 */

// --- OUTLINE ---
// 1. State Variables (for ERC721, EssenceToken, Artifacts, Bonding, Oracle, Config)
// 2. Structs (Artifact details, Bonding info, State info)
// 3. Events (NFT, Essence, Bonding, Evolution, Oracle, Admin)
// 4. Modifiers (onlyOwner, whenNotPaused, whenPaused)
// 5. Constructor
// 6. ERC721 Standard Functions (Implemented via inheritance and overrides)
//    - balanceOf, ownerOf, safeTransferFrom, transferFrom, approve, setApprovalForAll,
//    - getApproved, isApprovedForAll, supportsInterface
// 7. Internal EssenceToken Functions (ERC20-like implementation)
//    - _transferEssence, _approveEssence, _mintEssence, _burnEssence
// 8. EssenceToken Public Interaction Functions (ERC20-like public interfaces)
//    - essenceTotalSupply, essenceBalanceOf, transferEssence, approveEssence,
//    - transferFromEssence, essenceAllowance
// 9. Artifact Core Functions (Minting, Burning)
//    - mintArtifact, burnArtifact
// 10. Bonding and Essence Generation Functions
//    - bondArtifact, unbondArtifact, claimEssence, getPendingEssence,
//    - getArtifactBondDetails, getArtifactEssenceYieldRate
// 11. Dynamic State and Evolution Functions
//    - updateOracleData (Simulated Oracle)
//    - evolveArtifact (Consumes Essence, changes state)
//    - getArtifactState (Simple state identifier)
//    - getArtifactStateDetails (Detailed state info)
//    - tokenURI (Dynamic Metadata)
// 12. Admin/Configuration Functions
//    - setBaseEssenceYieldRate
//    - setBondDuration
//    - setEvolutionCost
//    - setMetadataBaseURI
//    - setOracleAddress (Simulated)
// 13. Pausability Functions
//    - pause, unpause
// 14. Ownership Functions (Inherited)
//    - transferOwnership, renounceOwnership

// --- FUNCTION SUMMARY ---
// 1.  constructor(string memory name, string memory symbol) - Initializes the contract, NFT name, symbol, and sets owner.
// 2.  supportsInterface(bytes4 interfaceId) - Standard ERC165, checks supported interfaces (ERC721, ERC721Enumerable, ERC721Metadata).
// 3.  balanceOf(address owner) view - Returns the number of NFTs owned by `owner`.
// 4.  ownerOf(uint256 tokenId) view - Returns the owner of the NFT `tokenId`.
// 5.  safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) - Transfers NFT with data.
// 6.  safeTransferFrom(address from, address to, uint256 tokenId) - Transfers NFT.
// 7.  transferFrom(address from, address to, uint256 tokenId) - Transfers NFT (less safe).
// 8.  approve(address to, uint256 tokenId) - Approves `to` to manage `tokenId`.
// 9.  setApprovalForAll(address operator, bool approved) - Sets approval for an operator for all owner's NFTs.
// 10. getApproved(uint256 tokenId) view - Gets the approved address for `tokenId`.
// 11. isApprovedForAll(address owner, address operator) view - Checks if operator is approved for all of owner's NFTs.
// 12. essenceTotalSupply() view - Returns the total supply of EssenceToken.
// 13. essenceBalanceOf(address account) view - Returns the EssenceToken balance of `account`.
// 14. transferEssence(address to, uint256 amount) returns (bool) - Transfers `amount` of EssenceToken from sender to `to`.
// 15. approveEssence(address spender, uint256 amount) returns (bool) - Approves `spender` to spend `amount` of EssenceToken on sender's behalf.
// 16. transferFromEssence(address from, address to, uint256 amount) returns (bool) - Transfers `amount` of EssenceToken from `from` to `to` using allowance.
// 17. essenceAllowance(address owner, address spender) view returns (uint256) - Returns the allowance granted by `owner` to `spender`.
// 18. mintArtifact() returns (uint256) - Mints a new Artifact NFT to the caller. Increments artifact counter.
// 19. burnArtifact(uint256 tokenId) - Burns an Artifact NFT. Only owner or approved can burn.
// 20. bondArtifact(uint256 tokenId) - Bonds the specified Artifact. Starts time-based Essence generation. Requires ownership or approval.
// 21. unbondArtifact(uint256 tokenId) - Unbonds the specified Artifact. Claims all pending Essence and stops generation. Requires ownership or approval.
// 22. claimEssence(uint256 tokenId) - Claims accrued Essence from a bonded Artifact without unbonding. Requires ownership or approval. Updates last claim time.
// 23. getPendingEssence(uint256 tokenId) view returns (uint256) - Calculates and returns the Essence pending claim for a bonded Artifact.
// 24. getArtifactBondDetails(uint256 tokenId) view returns (bool isBonded, uint40 bondStartTime, uint40 lastClaimTimestamp) - Gets bonding status and timestamps.
// 25. getArtifactEssenceYieldRate(uint256 tokenId) view returns (uint256 ratePerSecond) - Gets the current Essence yield rate for an Artifact.
// 26. updateOracleData(uint256 newData) - Updates the simulated external data. Only callable by owner or oracle address.
// 27. evolveArtifact(uint256 tokenId) - Attempts to evolve the Artifact. Requires spending Essence and potentially meeting other conditions (e.g., oracle data state). Changes the artifact's state permanently.
// 28. getArtifactState(uint256 tokenId) view returns (uint8 state) - Returns the current evolution state of the Artifact (0=Young, 1=Mature, etc.).
// 29. getArtifactStateDetails(uint256 tokenId) view returns (uint8 currentState, uint256 essenceRequiredForNext, bool oracleConditionMet) - Gets detailed info about the current state and next evolution requirements.
// 30. tokenURI(uint256 tokenId) view - Returns the dynamic metadata URI for the Artifact. Reflects state, bonding, yield, etc.
// 31. setBaseEssenceYieldRate(uint256 rate) - Sets the base Essence yield rate per second (Admin).
// 32. setBondDuration(uint40 duration) - Sets the required bonding duration (Admin).
// 33. setEvolutionCost(uint8 state, uint256 cost) - Sets the Essence cost for a specific evolution state (Admin).
// 34. setMetadataBaseURI(string memory uri) - Sets the base URI for token metadata (Admin).
// 35. setOracleAddress(address _oracleAddress) - Sets the address authorized to update oracle data (Admin).
// 36. pause() - Pauses contract functionality (Admin).
// 37. unpause() - Unpauses contract functionality (Admin).
// 38. transferOwnership(address newOwner) - Transfers contract ownership (Admin).
// 39. renounceOwnership() - Renounces contract ownership (Admin).
// 40. getTotalArtifactsMinted() view returns (uint256) - Returns the total number of artifacts ever minted.

contract ChronoBondedArtifacts is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // NFT State
    Counters.Counter private _artifactIds;
    mapping(uint256 => ArtifactDetails) private _artifactDetails;
    mapping(uint256 => BondingInfo) private _bondingInfo;
    string private _metadataBaseURI;

    // EssenceToken State (Internal ERC20-like)
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;
    uint256 private _essenceTotalSupply;
    string public constant ESSENCE_TOKEN_NAME = "Artifact Essence";
    string public constant ESSENCE_TOKEN_SYMBOL = "ESSENCE";
    uint8 public constant ESSENCE_TOKEN_DECIMALS = 18; // Standard for tokens

    // Configuration & Dynamics
    uint256 public baseEssenceYieldRatePerSecond = 100; // Base rate (e.g., 100 * 1e18 per second)
    uint40 public bondDuration = 30 days; // Example: minimum bond duration
    mapping(uint8 => uint256) public evolutionCosts; // Cost in Essence for state 0->1, 1->2, etc.
    uint256 public latestOracleData = 0; // Simulated oracle feed
    address public oracleAddress; // Address authorized to update oracle data

    // Artifact States (Example)
    uint8 public constant STATE_YOUNG = 0;
    uint8 public constant STATE_MATURE = 1;
    uint8 public constant STATE_ANCIENT = 2;
    uint8 public constant MAX_STATE = STATE_ANCIENT;

    // --- Structs ---

    struct ArtifactDetails {
        uint8 state; // Evolution state (0=Young, 1=Mature, etc.)
        // Future: Could add more permanent attributes here
    }

    struct BondingInfo {
        bool isBonded;
        uint40 bondStartTime; // Timestamp when bonding started (0 if not bonded)
        uint40 lastClaimTimestamp; // Timestamp of the last Essence claim or bonding start
    }

    // --- Events ---

    event ArtifactMinted(address indexed owner, uint256 indexed tokenId);
    event ArtifactBurned(address indexed owner, uint256 indexed tokenId);
    event ArtifactBonded(uint256 indexed tokenId, uint40 bondStartTime);
    event ArtifactUnbonded(uint256 indexed tokenId, uint40 unbondTime, uint256 claimedEssence);
    event EssenceClaimed(uint256 indexed tokenId, uint256 claimedAmount, uint40 claimTime);
    event EssenceTransfer(address indexed from, address indexed to, uint256 amount);
    event EssenceApproval(address indexed owner, address indexed spender, uint256 amount);
    event ArtifactEvolved(uint256 indexed tokenId, uint8 newState, uint256 essenceCost);
    event OracleDataUpdated(uint256 indexed newData, address indexed updater);
    event BaseYieldRateUpdated(uint256 newRate);
    event BondDurationUpdated(uint40 newDuration);
    event EvolutionCostUpdated(uint8 state, uint256 cost);
    event MetadataBaseURIUpdated(string newURI);
    event OracleAddressUpdated(address indexed newAddress);
    // Paused/Unpaused events inherited from Pausable
    // OwnershipTransferred event inherited from Ownable

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        ERC721Enumerable()
        Ownable(msg.sender)
        Pausable()
    {
        // Set initial values
        _metadataBaseURI = "ipfs://placeholder/"; // Placeholder URI
        evolutionCosts[STATE_YOUNG] = 1000 * (10**uint256(ESSENCE_TOKEN_DECIMALS)); // Cost to evolve from Young to Mature
        evolutionCosts[STATE_MATURE] = 5000 * (10**uint256(ESSENCE_TOKEN_DECIMALS)); // Cost to evolve from Mature to Ancient
        oracleAddress = msg.sender; // Initially owner is the oracle updater
    }

    // --- ERC165 Standard ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- ERC721 Standard Implementations (Inherited from ERC721Enumerable) ---
    // Need to override internal functions to hook into _beforeTokenTransfer and _afterTokenTransfer

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        // Before transfer: if bonded, unbond it implicitly (or prevent transfer?)
        // Let's choose to unbond implicitly for simplicity.
        if (_bondingInfo[tokenId].isBonded) {
            _unbondArtifact(tokenId); // Unbond and claim Essence automatically
        }

        return super._update(to, tokenId, auth);
    }

    // _beforeTokenTransfer and _afterTokenTransfer hooks are provided by ERC721Enumerable
    // We don't need to override them explicitly unless we add custom logic here.
    // The _update override above handles the unbonding on transfer.

    // --- Internal EssenceToken Functions (ERC20-like) ---

    function _mintEssence(address account, uint256 amount) internal {
        require(account != address(0), "ESSENCE: mint to the zero address");
        _essenceTotalSupply += amount;
        _essenceBalances[account] += amount;
        emit EssenceTransfer(address(0), account, amount);
    }

    function _burnEssence(address account, uint256 amount) internal {
        require(account != address(0), "ESSENCE: burn from the zero address");
        require(_essenceBalances[account] >= amount, "ESSENCE: burn amount exceeds balance");
        _essenceBalances[account] -= amount;
        _essenceTotalSupply -= amount;
        emit EssenceTransfer(account, address(0), amount);
    }

    function _transferEssence(address from, address to, uint256 amount) internal {
        require(from != address(0), "ESSENCE: transfer from the zero address");
        require(to != address(0), "ESSENCE: transfer to the zero address");
        require(_essenceBalances[from] >= amount, "ESSENCE: transfer amount exceeds balance");

        unchecked {
            _essenceBalances[from] -= amount;
            _essenceBalances[to] += amount;
        }
        emit EssenceTransfer(from, to, amount);
    }

    function _approveEssence(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ESSENCE: approve from the zero address");
        require(spender != address(0), "ESSENCE: approve to the zero address");

        _essenceAllowances[owner][spender] = amount;
        emit EssenceApproval(owner, spender, amount);
    }

    // --- EssenceToken Public Interaction Functions (ERC20-like) ---

    function essenceTotalSupply() public view returns (uint256) {
        return _essenceTotalSupply;
    }

    function essenceBalanceOf(address account) public view returns (uint256) {
        return _essenceBalances[account];
    }

    function transferEssence(address to, uint256 amount) public whenNotPaused returns (bool) {
        _transferEssence(_msgSender(), to, amount);
        return true;
    }

    function approveEssence(address spender, uint256 amount) public whenNotPaused returns (bool) {
        _approveEssence(_msgSender(), spender, amount);
        return true;
    }

    function transferFromEssence(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _essenceAllowances[from][_msgSender()];
        require(currentAllowance >= amount, "ESSENCE: transfer amount exceeds allowance");

        unchecked {
            _approveEssence(from, _msgSender(), currentAllowance - amount);
        }
        _transferEssence(from, to, amount);
        return true;
    }

    function essenceAllowance(address owner, address spender) public view returns (uint256) {
        return _essenceAllowances[owner][spender];
    }

    // --- Artifact Core Functions ---

    function mintArtifact() public payable whenNotPaused returns (uint256) {
        _artifactIds.increment();
        uint256 newTokenId = _artifactIds.current();

        _artifactDetails[newTokenId] = ArtifactDetails({
            state: STATE_YOUNG
            // Initialize other details if added to struct
        });

        // Start unbonded
        _bondingInfo[newTokenId] = BondingInfo({
            isBonded: false,
            bondStartTime: 0,
            lastClaimTimestamp: 0
        });

        _safeMint(msg.sender, newTokenId);
        emit ArtifactMinted(msg.sender, newTokenId);
        return newTokenId;
    }

    function burnArtifact(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "CBA: Not owner or approved");

        // If bonded, unbond first (claims pending essence)
        if (_bondingInfo[tokenId].isBonded) {
             _unbondArtifact(tokenId); // This also claims essence
        } else {
             // If not bonded, check if there's any unclaimed essence from a previous bond session
             // This logic might be complex depending on design choices.
             // For simplicity here, unbonding always claims. If not bonded, no pending essence.
        }

        // Clean up storage associated with the artifact
        delete _artifactDetails[tokenId];
        delete _bondingInfo[tokenId]; // Ensure bonding info is removed

        _burn(tokenId); // ERC721Enumerable handles removal from enumerations
        emit ArtifactBurned(_msgSender(), tokenId);
    }


    // --- Bonding and Essence Generation Functions ---

    function bondArtifact(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "CBA: Not owner or approved");
        require(!_bondingInfo[tokenId].isBonded, "CBA: Artifact already bonded");

        BondingInfo storage bond = _bondingInfo[tokenId];
        bond.isBonded = true;
        bond.bondStartTime = uint40(block.timestamp);
        bond.lastClaimTimestamp = uint40(block.timestamp); // Start timer for essence generation

        emit ArtifactBonded(tokenId, bond.bondStartTime);
    }

    function unbondArtifact(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "CBA: Not owner or approved");
        require(_bondingInfo[tokenId].isBonded, "CBA: Artifact not bonded");

        uint256 pending = _calculatePendingEssence(tokenId);
        BondingInfo storage bond = _bondingInfo[tokenId];

        bond.isBonded = false;
        bond.bondStartTime = 0; // Reset bond start time
        bond.lastClaimTimestamp = 0; // Reset claim timer

        if (pending > 0) {
            _mintEssence(ownerOf(tokenId), pending); // Mint essence to the current owner
            emit EssenceClaimed(tokenId, pending, uint40(block.timestamp)); // Use current time for claim event
        }

        emit ArtifactUnbonded(tokenId, uint40(block.timestamp), pending);
    }

    function claimEssence(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "CBA: Not owner or approved");
        require(_bondingInfo[tokenId].isBonded, "CBA: Artifact not bonded to claim");

        uint256 pending = _calculatePendingEssence(tokenId);
        require(pending > 0, "CBA: No essence pending claim");

        BondingInfo storage bond = _bondingInfo[tokenId];
        bond.lastClaimTimestamp = uint40(block.timestamp); // Update claim timestamp

        _mintEssence(ownerOf(tokenId), pending); // Mint essence to the current owner
        emit EssenceClaimed(tokenId, pending, uint40(block.timestamp));
    }

    function getPendingEssence(uint256 tokenId) public view returns (uint256) {
        // Check if token exists and is bonded before calculating
        if (ownerOf(tokenId) == address(0) || !_bondingInfo[tokenId].isBonded) {
             return 0;
        }
        return _calculatePendingEssence(tokenId);
    }

    function _calculatePendingEssence(uint256 tokenId) internal view returns (uint256) {
        BondingInfo storage bond = _bondingInfo[tokenId];
        // Only calculate if bonded and last claim time is valid
        if (!bond.isBonded || bond.lastClaimTimestamp == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - bond.lastClaimTimestamp;
        if (timeElapsed == 0) return 0; // No time has passed since last claim/bond start

        uint256 yieldRate = getArtifactEssenceYieldRate(tokenId);
        return timeElapsed * yieldRate;
    }

    function getArtifactBondDetails(uint256 tokenId) public view returns (bool isBonded, uint40 bondStartTime, uint40 lastClaimTimestamp) {
         // Return zero values if token doesn't exist or no bonding info
        if (ownerOf(tokenId) == address(0)) {
            return (false, 0, 0);
        }
        BondingInfo storage bond = _bondingInfo[tokenId];
        return (bond.isBonded, bond.bondStartTime, bond.lastClaimTimestamp);
    }

    function getArtifactEssenceYieldRate(uint256 tokenId) public view returns (uint256 ratePerSecond) {
        // The yield rate could be dynamic based on artifact state, oracle data, etc.
        // Simple example: Base rate + bonus based on state and oracle data
        uint256 rate = baseEssenceYieldRatePerSecond;
        ArtifactDetails storage details = _artifactDetails[tokenId];

        // Example bonus logic:
        if (details.state == STATE_MATURE) {
            rate += baseEssenceYieldRatePerSecond / 2; // 50% bonus for Mature
        } else if (details.state == STATE_ANCIENT) {
            rate += baseEssenceYieldRatePerSecond; // 100% bonus for Ancient
        }

        // Influence by oracle data (simple modulo example)
        rate += latestOracleData % 100; // Add 0-99 based on oracle data

        return rate; // Rate is already scaled by 1e18 if baseEssenceYieldRatePerSecond is
    }

    // --- Dynamic State and Evolution Functions ---

    // Simulate Oracle Data Update (only callable by owner or designated oracle address)
    function updateOracleData(uint256 newData) public whenNotPaused {
        require(msg.sender == owner() || msg.sender == oracleAddress, "CBA: Only owner or oracle address can update");
        latestOracleData = newData;
        emit OracleDataUpdated(newData, msg.sender);
    }

    function evolveArtifact(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "CBA: Not owner or approved");

        ArtifactDetails storage details = _artifactDetails[tokenId];
        uint8 currentState = details.state;
        require(currentState < MAX_STATE, "CBA: Artifact is already at max state");

        uint8 nextState = currentState + 1;
        uint256 cost = evolutionCosts[currentState];
        require(_essenceBalances[_msgSender()] >= cost, "CBA: Not enough Essence to evolve");

        // Add dynamic conditions based on oracle data or other factors
        // Example: Require oracle data to be above a certain threshold to evolve to ANCIENT
        if (nextState == STATE_ANCIENT) {
             require(latestOracleData > 500, "CBA: Oracle condition not met for Ancient evolution");
        }
        // Add more complex conditions here...

        _burnEssence(_msgSender(), cost); // Burn the required Essence
        details.state = nextState; // Update the state permanently

        emit ArtifactEvolved(tokenId, nextState, cost);
    }

    function getArtifactState(uint256 tokenId) public view returns (uint8 state) {
         // Return 0 if token doesn't exist
         if (ownerOf(tokenId) == address(0)) return 0; // Or handle appropriately
         return _artifactDetails[tokenId].state;
    }

    function getArtifactStateDetails(uint256 tokenId) public view returns (
        uint8 currentState,
        uint256 essenceRequiredForNext,
        bool oracleConditionMetForNext
    ) {
        ArtifactDetails storage details = _artifactDetails[tokenId];
        currentState = details.state;

        if (currentState == MAX_STATE) {
            return (currentState, 0, true); // No next state, no cost, condition met (or N/A)
        }

        uint8 nextState = currentState + 1;
        essenceRequiredForNext = evolutionCosts[currentState];

        // Calculate oracle condition status for the *next* evolution
        if (nextState == STATE_ANCIENT) {
            oracleConditionMetForNext = latestOracleData > 500;
        } else {
            oracleConditionMetForNext = true; // No specific oracle condition for other states in this example
        }

        return (currentState, essenceRequiredForNext, oracleConditionMetForNext);
    }


    // Dynamic Metadata URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists

        ArtifactDetails storage details = _artifactDetails[tokenId];
        BondingInfo storage bond = _bondingInfo[tokenId];

        string memory stateIdentifier;
        if (details.state == STATE_YOUNG) stateIdentifier = "young";
        else if (details.state == STATE_MATURE) stateIdentifier = "mature";
        else if (details.state == STATE_ANCIENT) stateIdentifier = "ancient";
        else stateIdentifier = "unknown"; // Should not happen with defined states

        // Example logic: add modifier based on bonding status and pending essence
        string memory bondStatus = bond.isBonded ? "bonded" : "unbonded";
        uint256 pendingEssence = _calculatePendingEssence(tokenId);
        string memory essenceStatus = (pendingEssence > 0 || bond.isBonded) ? "yielding" : "idle";

        // Construct a URI that includes key dynamic attributes
        // A real implementation would point to an API gateway or IPFS path
        // where the actual JSON metadata is generated based on these parameters.
        // Here, we just construct a symbolic URI path.

        // Example: ipfs://baseURI/tokenId/state/bondStatus/essenceStatus/oracle_X.json
        // A more robust way might involve base64 encoding JSON directly on-chain (gas intensive)
        // or having the off-chain service query these parameters.

        // Simplified URI construction for demonstration:
        string memory dynamicPath = string(abi.encodePacked(
            tokenId.toString(), "/",
            stateIdentifier, "/",
            bondStatus, "/",
            essenceStatus,
             "/oracle_", latestOracleData.toString() // Include oracle data
        ));

        return string(abi.encodePacked(_metadataBaseURI, dynamicPath, ".json"));
    }


    // --- Admin/Configuration Functions ---

    function setBaseEssenceYieldRate(uint256 rate) public onlyOwner whenNotPaused {
        require(rate > 0, "CBA: Yield rate must be positive");
        baseEssenceYieldRatePerSecond = rate;
        emit BaseYieldRateUpdated(rate);
    }

    function setBondDuration(uint40 duration) public onlyOwner whenNotPaused {
        require(duration > 0, "CBA: Bond duration must be positive");
        bondDuration = duration;
        emit BondDurationUpdated(duration);
    }

    function setEvolutionCost(uint8 state, uint256 cost) public onlyOwner whenNotPaused {
        require(state < MAX_STATE, "CBA: Invalid state for cost setting");
        evolutionCosts[state] = cost;
        emit EvolutionCostUpdated(state, cost);
    }

    function setMetadataBaseURI(string memory uri) public onlyOwner {
        _metadataBaseURI = uri;
        emit MetadataBaseURIUpdated(uri);
    }

    function setOracleAddress(address _oracleAddress) public onlyOwner {
         require(_oracleAddress != address(0), "CBA: Oracle address cannot be zero");
         oracleAddress = _oracleAddress;
         emit OracleAddressUpdated(_oracleAddress);
    }


    // --- Pausability Functions ---

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- Ownership Functions ---
    // Inherited from Ownable: transferOwnership, renounceOwnership

    // --- Utility/Read Functions (Additional) ---

    function getTotalArtifactsMinted() public view returns (uint256) {
        return _artifactIds.current();
    }
}
```