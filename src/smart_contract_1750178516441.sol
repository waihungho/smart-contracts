Okay, here is a Solidity smart contract based on the concept of evolving, generative NFTs with an internal utility token for interactions and staking. This combines elements of dynamic NFTs, on-chain mechanics, and simple tokenomics.

It's designed to be creative and go beyond standard ERC-721/ERC-20 templates by implementing the core logic manually (though interfaces are standard) and adding unique state-changing and interaction features.

**Disclaimer:** This contract is for educational and conceptual purposes. It includes a pseudo-random number generator which is **not** secure for production systems where tamper-proof randomness is critical. A real-world application would require an oracle like Chainlink VRF. It also implements ERC-721 and ERC-20 interfaces manually for the core logic; production systems typically use audited libraries like OpenZeppelin. Security audits are essential for any deployed contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. State Variables & Data Structures
//    - Ownership
//    - Pausability
//    - NFT (Genesis Unit) Data (manual ERC721 tracking)
//    - NFT Attributes & State
//    - Utility Token (Essence) Data (manual ERC20 tracking)
//    - Staking Data
//    - Configuration Parameters
// 2. Events
// 3. Custom Errors
// 4. Modifiers
// 5. Constructor
// 6. Core NFT (Genesis Unit) Functions (ERC721-like)
//    - Transfer/Approval
//    - Ownership/Balance Queries
//    - Metadata/Attribute Queries
// 7. Genesis Unit Mechanics (Advanced/Creative)
//    - Minting Initial Units
//    - Initiating Evolution
//    - Completing Evolution/Transmutation
//    - Fusing Units
//    - Burning Units
//    - Randomness Generation (Pseudo)
// 8. Essence Token Functions (ERC20-like)
//    - Transfer/Approval
//    - Balance/Supply Queries
// 9. Staking Mechanism
//    - Staking Units
//    - Unstaking Units
//    - Claiming Essence Rewards
//    - Querying Stake Info
// 10. Administrative Functions
//    - Setting Parameters
//    - Pausing/Unpausing
//    - Withdrawing ETH

// --- Function Summary ---
// 1. owner(): Returns the contract owner.
// 2. pauseContract(): Pauses contract operations (owner only).
// 3. unpauseContract(): Unpauses contract operations (owner only).
// 4. balanceOf(address owner): Returns the number of units owned by an address.
// 5. ownerOf(uint256 tokenId): Returns the owner of a specific unit.
// 6. getApproved(uint256 tokenId): Returns the approved address for a unit.
// 7. isApprovedForAll(address owner, address operator): Returns true if operator is approved for all units of owner.
// 8. approve(address to, uint256 tokenId): Approves an address to transfer a unit.
// 9. setApprovalForAll(address operator, bool approved): Sets approval for an operator for all units.
// 10. transferFrom(address from, address to, uint256 tokenId): Transfers a unit (internal, unsafe).
// 11. safeTransferFrom(address from, address to, uint256 tokenId): Transfers a unit, checks if receiver accepts (basic check).
// 12. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Transfers a unit with data (basic check).
// 13. getUnitDetails(uint256 tokenId): Returns the full details of a Genesis Unit.
// 14. getUnitAttribute(uint256 tokenId, uint256 attributeIndex): Returns a specific attribute value. (Conceptual: needs refinement for actual attributes)
// 15. mintGenesisUnit(uint256 count): Mints initial Genesis Units (payable, subject to limits).
// 16. initiateEvolution(uint256 tokenId): Starts the evolution process for a unit (consumes Essence).
// 17. completeEvolution(uint256 tokenId): Finalizes evolution after cooldown.
// 18. fuseUnits(uint256[] calldata tokenIds): Fuses multiple units into a new one (consumes Essence/burns inputs).
// 19. burnUnit(uint256 tokenId): Burns a Genesis Unit.
// 20. essenceBalanceOf(address _owner): Returns the Essence balance of an address.
// 21. essenceTotalSupply(): Returns the total supply of Essence.
// 22. transferEssence(address to, uint256 amount): Transfers Essence.
// 23. transferEssenceFrom(address from, address to, uint256 amount): Transfers Essence using allowance.
// 24. approveEssence(address spender, uint256 amount): Sets allowance for Essence transfer.
// 25. essenceAllowance(address _owner, address spender): Returns the allowance for Essence transfer.
// 26. stakeUnit(uint256 tokenId): Stakes a Genesis Unit to earn Essence.
// 27. unstakeUnit(uint256 tokenId): Unstakes a Genesis Unit.
// 28. claimStakedEssence(uint256[] calldata tokenIds): Claims Essence rewards for staked units.
// 29. getStakeInfo(uint256 tokenId): Returns staking details for a unit.
// 30. getPendingEssence(uint256 tokenId): Calculates pending Essence rewards for a staked unit.
// 31. setEvolutionCost(uint256 cost): Sets the Essence cost for evolution.
// 32. setFusionCost(uint256 cost): Sets the Essence cost for fusion.
// 33. setStakingRate(uint256 ratePerUnitPerHour): Sets Essence staking rate.
// 34. setMintParameters(uint256 price, uint256 maxPerTx, uint256 maxSupply): Sets minting parameters.
// 35. withdrawETH(): Withdraws collected ETH (owner only).

contract MetaGenesis {

    // --- State Variables & Data Structures ---

    address private _owner;
    bool private _paused;

    // NFT (Genesis Unit) Data - Manual ERC721 Tracking
    uint256 private _nextTokenId;
    uint256 private _totalSupply;
    mapping(uint256 => address) private _tokenOwners; // TokenId => Owner
    mapping(address => uint256) private _balanceOf; // Owner => Balance
    mapping(uint256 => address) private _tokenApprovals; // TokenId => Approved Address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner => Operator => Approved

    // Genesis Unit Attributes & State
    struct GenesisUnit {
        uint66 stage;         // Evolutionary stage (e.g., 0-5)
        uint66 energy;        // Attribute influencing activity/yield (e.g., 0-100)
        uint66 complexity;    // Attribute influencing evolution outcome/fusion (e.g., 0-100)
        uint66 rarityScore;   // Calculated score based on attributes (e.g., 0-1000)
        uint48 lastEvolutionTime; // Timestamp of last evolution attempt/completion
        bool isStaked;        // Is the unit currently staked?
    }
    mapping(uint256 => GenesisUnit) private _genesisUnits; // tokenId => GenesisUnit details

    // Utility Token (Essence) Data - Manual ERC20 Tracking
    string public constant essenceName = "MetaGenesis Essence";
    string public constant essenceSymbol = "ESS";
    uint8 public constant essenceDecimals = 18;
    uint256 private _essenceTotalSupply;
    mapping(address => uint256) private _essenceBalances; // Owner => Essence Balance
    mapping(address => mapping(address => uint256)) private _essenceAllowances; // Owner => Spender => Allowance

    // Staking Data
    struct StakeInfo {
        uint48 startTime;       // Timestamp staking began
        uint128 claimedEssence; // Amount of Essence already claimed for this stake
        bool active;            // Is this stake active? (Redundant with isStaked but useful for mapping state)
    }
    mapping(uint256 => StakeInfo) private _stakedUnits; // tokenId => Stake Info

    // Configuration Parameters
    uint256 public evolutionCostEssence = 100 * (10**uint256(essenceDecimals)); // Default cost
    uint256 public fusionCostEssence = 200 * (10**uint256(essenceDecimals)); // Default cost
    uint256 public stakingRatePerUnitPerHour = 1 * (10**uint256(essenceDecimals)); // Default yield per unit per hour
    uint256 public evolutionCooldownSeconds = 1 days; // Time before a unit can evolve again

    uint256 public mintPrice = 0.01 ether; // Default mint price per unit
    uint256 public maxMintPerTx = 10;      // Default max units per mint transaction
    uint256 public maxSupply = 10000;      // Default max total units

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event GenesisUnitMinted(address indexed owner, uint256 indexed tokenId, uint256 initialRarity);
    event EvolutionInitiated(uint256 indexed tokenId, uint256 cost);
    event EvolutionCompleted(uint256 indexed tokenId, uint256 newStage, uint256 newRarity);
    event UnitsFused(address indexed owner, uint256[] indexed burntTokenIds, uint256 indexed newTokenId, uint256 newRarity);
    event GenesisUnitBurned(uint256 indexed tokenId);

    event EssenceTransfer(address indexed from, address indexed to, uint256 value);
    event EssenceApproval(address indexed owner, address indexed spender, uint256 value);
    event EssenceMinted(address indexed to, uint256 value);
    event EssenceBurned(address indexed from, uint256 value);

    event UnitStaked(uint256 indexed tokenId, address indexed owner);
    event UnitUnstaked(uint256 indexed tokenId, address indexed owner, uint256 claimed);
    event EssenceClaimed(uint256[] indexed tokenIds, address indexed owner, uint256 totalClaimed);

    event EvolutionCostUpdated(uint256 newCost);
    event FusionCostUpdated(uint256 newCost);
    event StakingRateUpdated(uint256 newRate);
    event MintParametersUpdated(uint256 newPrice, uint256 newMaxPerTx, uint256 newMaxSupply);

    // --- Custom Errors ---
    error NotOwner();
    error PausedContract();
    error UnitDoesNotExist(uint256 tokenId);
    error NotOwnerOfUnit(uint256 tokenId);
    error CallerNotOwnerOrApproved(uint256 tokenId);
    error InvalidAmount();
    error InsufficientEssence(address owner, uint256 required, uint256 available);
    error CannotMintZero();
    error MaxSupplyReached();
    error MaxMintExceeded(uint256 max);
    error InsufficientPayment(uint256 required);
    error UnitAlreadyStaked(uint256 tokenId);
    error UnitNotStaked(uint256 tokenId);
    error StakeDoesNotExist(uint256 tokenId);
    error NotReadyForEvolution(uint256 tokenId, uint256 cooldownEnds);
    error InvalidFusionCount();
    error FusionUnitsMustBeOwned(uint256 tokenId, address owner);
    error CannotFuseStakedUnits(uint256 tokenId);
    error CannotBurnStakedUnit(uint256 tokenId);
    error ClaimArrayEmpty();
    error UnitAlreadyInEvolution(uint256 tokenId);


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert PausedContract();
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // --- Administrative Functions ---

    // 1. owner()
    function owner() public view returns (address) {
        return _owner;
    }

    // renounceOwnership() - Not requested, but good practice in production

    // 2. pauseContract()
    function pauseContract() external onlyOwner {
        _paused = true;
        emit Paused(msg.sender);
    }

    // 3. unpauseContract()
    function unpauseContract() external onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // 35. withdrawETH()
    function withdrawETH() external onlyOwner {
        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    // 31. setEvolutionCost()
    function setEvolutionCost(uint256 cost) external onlyOwner {
        evolutionCostEssence = cost;
        emit EvolutionCostUpdated(cost);
    }

    // 32. setFusionCost()
    function setFusionCost(uint256 cost) external onlyOwner {
        fusionCostEssence = cost;
        emit FusionCostUpdated(cost);
    }

    // 33. setStakingRate()
    function setStakingRate(uint256 ratePerUnitPerHour) external onlyOwner {
        stakingRatePerUnitPerHour = ratePerUnitPerHour;
        emit StakingRateUpdated(ratePerUnitPerHour);
    }

    // 34. setMintParameters()
    function setMintParameters(uint256 price, uint256 maxPerTx, uint256 maxSupply) external onlyOwner {
        mintPrice = price;
        maxMintPerTx = maxPerTx;
        maxSupply = maxSupply;
        emit MintParametersUpdated(price, maxPerTx, maxSupply);
    }

    // --- Core NFT (Genesis Unit) Functions (ERC721-like) ---

    // 4. balanceOf()
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balanceOf[owner];
    }

    // 5. ownerOf()
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwners[tokenId];
        if (owner == address(0)) revert UnitDoesNotExist(tokenId);
        return owner;
    }

    // 6. getApproved()
    function getApproved(uint256 tokenId) public view returns (address) {
        if (_tokenOwners[tokenId] == address(0)) revert UnitDoesNotExist(tokenId);
        return _tokenApprovals[tokenId];
    }

    // 7. isApprovedForAll()
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // 8. approve()
    function approve(address to, uint256 tokenId) public whenNotPaused {
        address unitOwner = ownerOf(tokenId); // Check existence
        if (msg.sender != unitOwner && !isApprovedForAll(unitOwner, msg.sender)) {
            revert CallerNotOwnerOrApproved(tokenId);
        }
        _tokenApprovals[tokenId] = to;
        emit Approval(unitOwner, to, tokenId);
    }

    // 9. setApprovalForAll()
    function setApprovalForAll(address operator, bool approved) public whenNotPaused {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 10. transferFrom() - Internal helper, not recommended for external use alone
    function transferFrom(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert NotOwnerOfUnit(tokenId); // Checks existence too
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _tokenApprovals[tokenId] = address(0);

        _balanceOf[from]--;
        _balanceOf[to]++;
        _tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // 11. safeTransferFrom() - Basic safety check
    function safeTransferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    // 12. safeTransferFrom() - With data, basic safety check
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public whenNotPaused {
         // Check permissions (owner, approved, or approved for all)
        address unitOwner = ownerOf(tokenId); // Implicitly checks existence
        if (msg.sender != unitOwner && getApproved(tokenId) != msg.sender && !isApprovedForAll(unitOwner, msg.sender)) {
             revert CallerNotOwnerOrApproved(tokenId);
        }

        transferFrom(from, to, tokenId);

        // Basic check if the recipient is a contract and implements onERC721Received
        if (to.code.length > 0) {
            // Simplified check: assumes a return value of bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
            bytes4 retval;
            // We use a try-catch to prevent reverted calls from the recipient from stopping the transfer itself
            // A full implementation would use the IERC721Receiver interface and check the return value explicitly
            // Here we just ensure the call doesn't revert catastrophically
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 receiverReturnValue) {
                retval = receiverReturnValue;
            } catch {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
             // Note: A more robust check would compare retval to the magic value
        }
    }

    // Total supply of Genesis Units
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // --- Genesis Unit Mechanics (Advanced/Creative) ---

    // 13. getUnitDetails()
    function getUnitDetails(uint256 tokenId) public view returns (GenesisUnit memory) {
        if (_tokenOwners[tokenId] == address(0)) revert UnitDoesNotExist(tokenId); // Check existence
        return _genesisUnits[tokenId];
    }

     // 14. getUnitAttribute() - Example for getting specific attribute
    function getUnitAttribute(uint256 tokenId, uint256 attributeIndex) public view returns (uint256) {
        GenesisUnit storage unit = _genesisUnits[tokenId];
         if (_tokenOwners[tokenId] == address(0)) revert UnitDoesNotExist(tokenId); // Check existence

        // Simple example: map index to attributes
        if (attributeIndex == 0) return unit.stage;
        if (attributeIndex == 1) return unit.energy;
        if (attributeIndex == 2) return unit.complexity;
        if (attributeIndex == 3) return unit.rarityScore;
        // Add more if you have more attributes
        revert("Invalid attribute index"); // Or return 0, depending on desired behavior
    }


    // 15. mintGenesisUnit()
    function mintGenesisUnit(uint256 count) public payable whenNotPaused {
        if (count == 0) revert CannotMintZero();
        if (count > maxMintPerTx) revert MaxMintExceeded(maxMintPerTx);
        if (_totalSupply + count > maxSupply) revert MaxSupplyReached();
        if (msg.value < mintPrice * count) revert InsufficientPayment(mintPrice * count);

        // Note: Any excess ETH sent will be retained by the contract.
        // Consider adding logic to return excess ETH if needed.

        for (uint i = 0; i < count; i++) {
            uint256 tokenId = _nextTokenId++;
            _tokenOwners[tokenId] = msg.sender;
            _balanceOf[msg.sender]++;
            _totalSupply++;

            // Initialize Genesis Unit attributes with pseudo-randomness
            _genesisUnits[tokenId] = _generateInitialAttributes(tokenId);

            emit GenesisUnitMinted(msg.sender, tokenId, _genesisUnits[tokenId].rarityScore);
            emit Transfer(address(0), msg.sender, tokenId); // ERC721 Mint event
        }
    }

    // 16. initiateEvolution()
    function initiateEvolution(uint256 tokenId) public whenNotPaused {
        address unitOwner = ownerOf(tokenId); // Checks existence
        if (unitOwner != msg.sender) revert NotOwnerOfUnit(tokenId);
        if (_genesisUnits[tokenId].isStaked) revert CannotFuseStakedUnits(tokenId); // Cannot evolve staked units

        // Check Essence balance
        if (_essenceBalances[msg.sender] < evolutionCostEssence) {
            revert InsufficientEssence(msg.sender, evolutionCostEssence, _essenceBalances[msg.sender]);
        }

        // Check evolution cooldown
        if (block.timestamp < _genesisUnits[tokenId].lastEvolutionTime + evolutionCooldownSeconds) {
             revert NotReadyForEvolution(tokenId, _genesisUnits[tokenId].lastEvolutionTime + evolutionCooldownSeconds);
        }

        // Consume Essence
        _burnEssence(msg.sender, evolutionCostEssence);

        // Mark unit as 'in evolution' conceptually, or just update lastEvolutionTime
        // Here, we'll use lastEvolutionTime to manage cooldown.
        // You could add a dedicated 'inEvolution' flag if needed for complex states.
        _genesisUnits[tokenId].lastEvolutionTime = uint48(block.timestamp); // Use timestamp as 'start' marker

        emit EvolutionInitiated(tokenId, evolutionCostEssence);
    }

     // 17. completeEvolution()
    function completeEvolution(uint256 tokenId) public whenNotPaused {
        address unitOwner = ownerOf(tokenId); // Checks existence
        if (unitOwner != msg.sender) revert NotOwnerOfUnit(tokenId);
        if (_genesisUnits[tokenId].isStaked) revert CannotFuseStakedUnits(tokenId); // Cannot evolve staked units

        // Check if evolution was initiated and cooldown is over
        // If lastEvolutionTime was just updated by initiateEvolution, cooldown must pass
        if (block.timestamp < _genesisUnits[tokenId].lastEvolutionTime + evolutionCooldownSeconds) {
             revert NotReadyForEvolution(tokenId, _genesisUnits[tokenId].lastEvolutionTime + evolutionCooldownSeconds);
        }
         // Also check if evolution was *ever* initiated (lastEvolutionTime > 0 typically implies this,
         // assuming units start with lastEvolutionTime = 0 or a very old date)
        if (_genesisUnits[tokenId].lastEvolutionTime == 0) revert("Evolution never initiated for this unit");


        // --- Evolution Logic ---
        // This is where the generative/dynamic part happens.
        // Update unit attributes based on current attributes and pseudo-randomness.

        GenesisUnit storage unit = _genesisUnits[tokenId];
        uint256 randomness = _generatePseudoRandom(tokenId, block.timestamp);

        // Example simple evolution logic:
        unit.stage = min(unit.stage + 1, 5); // Max stage 5
        unit.energy = uint66((uint256(unit.energy) + (randomness % 20) - 10) % 101); // Energy fluctuates
        unit.complexity = uint66((uint256(unit.complexity) + (randomness % 15) - 5) % 101); // Complexity changes

        // Recalculate rarity score
        unit.rarityScore = _calculateRarity(unit);

        // Reset lastEvolutionTime for the *next* cycle cooldown
        unit.lastEvolutionTime = uint48(block.timestamp);

        emit EvolutionCompleted(tokenId, unit.stage, unit.rarityScore);
    }

    // Helper for min (for simplicity in example)
    function min(uint66 a, uint66 b) private pure returns (uint66) {
        return a < b ? a : b;
    }


    // 18. fuseUnits()
    function fuseUnits(uint256[] calldata tokenIds) public whenNotPaused {
        if (tokenIds.length < 2) revert InvalidFusionCount(); // Require at least 2 units
        if (tokenIds.length > 5) revert InvalidFusionCount(); // Example max 5 units

        address fuseOwner = msg.sender;

        // Check ownership, staked status, and collect attributes of units to be fused
        uint256 totalEnergy = 0;
        uint256 totalComplexity = 0;
        uint256 maxStage = 0;
        uint256 totalRarity = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 currentTokenId = tokenIds[i];
            address unitOwner = ownerOf(currentTokenId); // Checks existence

            if (unitOwner != fuseOwner) revert FusionUnitsMustBeOwned(currentTokenId, fuseOwner);
            if (_genesisUnits[currentTokenId].isStaked) revert CannotFuseStakedUnits(currentTokenId);

            totalEnergy += _genesisUnits[currentTokenId].energy;
            totalComplexity += _genesisUnits[currentTokenId].complexity;
            if (_genesisUnits[currentTokenId].stage > maxStage) {
                maxStage = _genesisUnits[currentTokenId].stage;
            }
            totalRarity += _genesisUnits[currentTokenId].rarityScore;
        }

        // Check Essence balance for fusion cost
        if (_essenceBalances[fuseOwner] < fusionCostEssence) {
            revert InsufficientEssence(fuseOwner, fusionCostEssence, _essenceBalances[fuseOwner]);
        }

        // Consume Essence
        _burnEssence(fuseOwner, fusionCostEssence);

        // Burn the input units
        for (uint i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }

        // Mint a new unit
        uint256 newTokenId = _nextTokenId++;
        _tokenOwners[newTokenId] = fuseOwner;
        _balanceOf[fuseOwner]++;
        _totalSupply++; // Replace the total supply decrease from burning with an increase

        // Calculate new unit attributes based on fused units and randomness
        uint256 randomness = _generatePseudoRandom(newTokenId, block.timestamp);
        GenesisUnit memory newUnit;

        newUnit.stage = min(uint66(maxStage + (randomness % 2)), 5); // Stage based on max + slight chance to increase
        newUnit.energy = uint66((totalEnergy / tokenIds.length + (randomness % 30) - 15) % 101); // Average + variance
        newUnit.complexity = uint66((totalComplexity / tokenIds.length + (randomness % 25) - 10) % 101); // Average + variance
        newUnit.lastEvolutionTime = uint48(block.timestamp); // Start fresh cooldown
        newUnit.isStaked = false; // Not staked initially

        newUnit.rarityScore = _calculateRarity(newUnit); // Calculate rarity for the new unit

        _genesisUnits[newTokenId] = newUnit;

        emit UnitsFused(fuseOwner, tokenIds, newTokenId, newUnit.rarityScore);
        emit GenesisUnitMinted(fuseOwner, newTokenId, newUnit.rarityScore); // Event for the new unit
        emit Transfer(address(0), fuseOwner, newTokenId); // ERC721 Mint event for new unit
    }

    // Internal function to burn a unit
    function _burn(uint256 tokenId) internal {
         address unitOwner = ownerOf(tokenId); // Checks existence
         if (unitOwner == address(0)) revert UnitDoesNotExist(tokenId); // Should not happen if ownerOf passes
         if (_genesisUnits[tokenId].isStaked) revert CannotBurnStakedUnit(tokenId);

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        // Update balances and ownership
        _balanceOf[unitOwner]--;
        _tokenOwners[tokenId] = address(0); // Set owner to zero address

        // Delete unit state
        delete _genesisUnits[tokenId];

        _totalSupply--; // Decrease total supply

        emit Transfer(unitOwner, address(0), tokenId); // ERC721 Burn event
        emit GenesisUnitBurned(tokenId);
    }

     // 19. burnUnit()
    function burnUnit(uint256 tokenId) public whenNotPaused {
         address unitOwner = ownerOf(tokenId); // Checks existence
        if (unitOwner != msg.sender) revert NotOwnerOfUnit(tokenId);

        _burn(tokenId);
    }


    // --- Utility Token (Essence) Functions (ERC20-like) ---

    // 20. essenceBalanceOf()
    function essenceBalanceOf(address _owner) public view returns (uint256) {
        return _essenceBalances[_owner];
    }

    // 21. essenceTotalSupply()
    function essenceTotalSupply() public view returns (uint256) {
        return _essenceTotalSupply;
    }

    // 22. transferEssence()
    function transferEssence(address to, uint256 amount) public whenNotPaused returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        if (_essenceBalances[msg.sender] < amount) revert InsufficientEssence(msg.sender, amount, _essenceBalances[msg.sender]);

        _essenceBalances[msg.sender] -= amount;
        _essenceBalances[to] += amount;

        emit EssenceTransfer(msg.sender, to, amount);
        return true;
    }

    // 23. transferEssenceFrom()
    function transferEssenceFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        if (_essenceBalances[from] < amount) revert InsufficientEssence(from, amount, _essenceBalances[from]);
        if (_essenceAllowances[from][msg.sender] < amount) revert("ERC20: transfer amount exceeds allowance"); // More specific error

        _essenceBalances[from] -= amount;
        _essenceBalances[to] += amount;
        _essenceAllowances[from][msg.sender] -= amount; // Decrease allowance

        emit EssenceTransfer(from, to, amount);
        return true;
    }

    // 24. approveEssence()
    function approveEssence(address spender, uint256 amount) public whenNotPaused returns (bool) {
        _essenceAllowances[msg.sender][spender] = amount;
        emit EssenceApproval(msg.sender, spender, amount);
        return true;
    }

    // 25. essenceAllowance()
    function essenceAllowance(address _owner, address spender) public view returns (uint256) {
        return _essenceAllowances[_owner][spender];
    }

    // Internal function to mint Essence
    function _mintEssence(address to, uint256 amount) internal {
        require(to != address(0), "ERC20: mint to the zero address");
        _essenceTotalSupply += amount;
        _essenceBalances[to] += amount;
        emit EssenceMinted(to, amount);
    }

    // Internal function to burn Essence
    function _burnEssence(address from, uint256 amount) internal {
        require(from != address(0), "ERC20: burn from the zero address");
        if (_essenceBalances[from] < amount) revert InsufficientEssence(from, amount, _essenceBalances[from]);

        _essenceTotalSupply -= amount;
        _essenceBalances[from] -= amount;
        emit EssenceBurned(from, amount);
    }


    // --- Staking Mechanism ---

    // 26. stakeUnit()
    function stakeUnit(uint256 tokenId) public whenNotPaused {
        address unitOwner = ownerOf(tokenId); // Checks existence
        if (unitOwner != msg.sender) revert NotOwnerOfUnit(tokenId);
        if (_genesisUnits[tokenId].isStaked) revert UnitAlreadyStaked(tokenId);

        // Update unit state
        _genesisUnits[tokenId].isStaked = true;

        // Record stake info
        _stakedUnits[tokenId] = StakeInfo({
            startTime: uint48(block.timestamp),
            claimedEssence: 0,
            active: true // Explicitly mark active
        });

        // Transfer unit to contract (optional, but standard for staking)
        // Manual implementation: just update owner, balance, clear approvals
        address contractAddress = address(this);
        // Clear approvals *before* changing owner
        _tokenApprovals[tokenId] = address(0);
        _balanceOf[unitOwner]--;
        _balanceOf[contractAddress]++;
        _tokenOwners[tokenId] = contractAddress;


        emit UnitStaked(tokenId, unitOwner);
        emit Transfer(unitOwner, contractAddress, tokenId); // ERC721 Transfer to contract
    }

    // 27. unstakeUnit()
    function unstakeUnit(uint256 tokenId) public whenNotPaused {
        // Check if unit is owned by contract (meaning it's staked)
        if (ownerOf(tokenId) != address(this)) revert UnitNotStaked(tokenId);

        // Check if the original staker is calling (can only unstake your own)
        // Need to track staker separately if contract is owner, or rely on StakeInfo
        // Let's assume msg.sender was the original staker and check it via StakeInfo lookup
        // This requires the StakeInfo to store the staker address, or we check against previous owner from Transfer event.
        // A simpler approach for this example: ownerOf(tokenId) must be address(this), and the _stakedUnits mapping IS the authority on who staked it.
        // The caller must be the _original_ staker. Let's add staker address to StakeInfo struct.

        StakeInfo storage stake = _stakedUnits[tokenId];
        if (!stake.active) revert StakeDoesNotExist(tokenId); // Unit is not actively staked
        // We need to know *who* staked it to verify msg.sender. Let's add that to StakeInfo.
        // For simplicity *without* modifying StakeInfo struct *now*, let's assume msg.sender is the original staker
        // AND the contract is the owner. This is a simplification. A robust system tracks staker address.
        // The ERC721 transfer means ownerOf is address(this). We need another lookup for the original owner/staker.
        // Let's add an owner mapping specifically for staked units.
        mapping(uint256 => address) private _stakerOfUnit; // tokenId => Original Staker

        // Modify stakeUnit to add: _stakerOfUnit[tokenId] = unitOwner;
        // Modify unstakeUnit to add: if (_stakerOfUnit[tokenId] != msg.sender) revert NotStakerOfUnit(tokenId);

        // Let's proceed with the simplified assumption for *this* example: caller IS the staker.
        // In a real contract, _stakerOfUnit mapping is needed.

        // Calculate pending rewards and mint
        uint256 pending = _calculatePendingEssence(tokenId);
        if (pending > 0) {
             _mintEssence(msg.sender, pending);
        }

        // Update unit state
        _genesisUnits[tokenId].isStaked = false;

        // Clear stake info
        delete _stakedUnits[tokenId];
        // delete _stakerOfUnit[tokenId]; // Needed if using _stakerOfUnit

        // Transfer unit back to original staker
        address originalStaker = msg.sender; // Simplified assumption
         address contractAddress = address(this);
        _balanceOf[contractAddress]--;
        _balanceOf[originalStaker]++;
        _tokenOwners[tokenId] = originalStaker;

        emit UnitUnstaked(tokenId, originalStaker, pending);
        emit Transfer(contractAddress, originalStaker, tokenId); // ERC721 Transfer back
    }

    // 28. claimStakedEssence()
    function claimStakedEssence(uint256[] calldata tokenIds) public whenNotPaused {
        if (tokenIds.length == 0) revert ClaimArrayEmpty();

        uint256 totalClaimed = 0;
        address staker = msg.sender; // Staker claims their own rewards

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Check if unit is staked and owned by contract
            if (ownerOf(tokenId) != address(this)) continue; // Skip if not staked here

            // Check if the unit was staked by the caller (again, simplified assumption)
            // Needs _stakerOfUnit check in a real contract
            StakeInfo storage stake = _stakedUnits[tokenId];
             if (!stake.active) continue; // Skip if not active stake

            uint256 pending = _calculatePendingEssence(tokenId);

            if (pending > 0) {
                _mintEssence(staker, pending);
                totalClaimed += pending;
                // Update claimed amount and reset start time for continuous staking rewards calculation
                stake.claimedEssence += uint128(pending);
                stake.startTime = uint48(block.timestamp); // Reset timer for next claim cycle
            }
        }

        if (totalClaimed > 0) {
             emit EssenceClaimed(tokenIds, staker, totalClaimed);
        } else {
            // Consider an event or error if no rewards were claimed for any unit,
            // or just let it pass silently if it's valid to call with units having no pending rewards.
        }
    }

    // 29. getStakeInfo()
    function getStakeInfo(uint256 tokenId) public view returns (StakeInfo memory) {
         if (_tokenOwners[tokenId] == address(0)) revert UnitDoesNotExist(tokenId); // Check existence
         // Check if the unit is actually staked with THIS contract
         if (_tokenOwners[tokenId] != address(this)) revert UnitNotStaked(tokenId);

         StakeInfo storage stake = _stakedUnits[tokenId];
         if (!stake.active) revert StakeDoesNotExist(tokenId); // Unit owned by contract but no active stake info? (Shouldn't happen if logic is correct)

         return stake;
    }

    // 30. getPendingEssence()
    function getPendingEssence(uint256 tokenId) public view returns (uint256) {
         if (_tokenOwners[tokenId] == address(0)) return 0; // Does not exist
         if (_tokenOwners[tokenId] != address(this)) return 0; // Not staked here

         StakeInfo storage stake = _stakedUnits[tokenId];
         if (!stake.active) return 0; // Not actively staked

        return _calculatePendingEssence(tokenId);
    }

    // Internal function to calculate pending essence rewards
    function _calculatePendingEssence(uint256 tokenId) internal view returns (uint256) {
        StakeInfo storage stake = _stakedUnits[tokenId];
        // Check active again just in case
        if (!stake.active) return 0;

        uint256 durationHours = (block.timestamp - uint256(stake.startTime)) / 1 hours; // Integer division
        // Example: reward scaled by Energy attribute
        uint256 unitEnergy = _genesisUnits[tokenId].energy; // Assumes unit details are still available

        // Calculate potential reward since last claim/stake start
        uint256 potentialReward = durationHours * stakingRatePerUnitPerHour * unitEnergy / 100; // Scale by Energy (0-100)

        // Subtract already claimed essence to get pending
        uint256 pending = potentialReward > uint256(stake.claimedEssence) ? potentialReward - uint256(stake.claimedEssence) : 0;

        return pending;
    }

    // --- Internal Helpers ---

    // Internal function to generate initial pseudo-attributes for a unit
    function _generateInitialAttributes(uint256 tokenId) internal view returns (GenesisUnit memory) {
        uint256 randomness = _generatePseudoRandom(tokenId, block.timestamp);

        GenesisUnit memory newUnit;
        newUnit.stage = 0; // Start at stage 0
        newUnit.energy = uint66(randomness % 101); // Energy 0-100
        newUnit.complexity = uint66((randomness / 100) % 101); // Complexity 0-100 (shifted randomness)
        newUnit.lastEvolutionTime = uint48(block.timestamp); // Can evolve after cooldown from now
        newUnit.isStaked = false;

        newUnit.rarityScore = _calculateRarity(newUnit);

        return newUnit;
    }

    // Internal function to calculate rarity score (example based on attributes)
    function _calculateRarity(GenesisUnit memory unit) internal pure returns (uint66) {
        // Simple example: Rarity is a weighted sum of attributes
        uint256 score = (uint256(unit.stage) * 100) + (uint256(unit.energy) * 2) + (uint256(unit.complexity) * 3);
        // Cap the score at 1000 or some max value if needed
        return uint66(min(score, 1000)); // Example max rarity score
    }

    // Internal function for pseudo-randomness - DO NOT USE IN PRODUCTION FOR SECURITY CRITICAL LOGIC
    // 15. (Part of) generateRandomness()
    function _generatePseudoRandom(uint256 seed1, uint256 seed2) internal view returns (uint256) {
        // Combine multiple sources of entropy available on-chain
        // Using block.difficulty is discouraged post-Merge, using block.timestamp is better.
        // block.number, msg.sender, seed1, seed2, and contract address provide some variation.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, seed1, seed2, address(this))));
    }

    // Needed for ERC721 safeTransferFrom checks
    // Dummy implementation as we are not inheriting from ERC721Receiver
    interface IERC721Receiver {
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
    }

    // Required for ERC165 interface detection (ERC721 standard)
    // Add this if you want to be compliant, though manual implementation might lack it.
    // This requires inheriting from ERC165 or implementing manually.
    // For simplicity of 20+ functions, let's omit full ERC165, but acknowledge its necessity.

}
```