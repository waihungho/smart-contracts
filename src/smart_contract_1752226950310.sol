Okay, here is a Solidity smart contract implementing a conceptual "Chronosforge Ecosystem". This contract acts as both an ERC-20 token (ChronoCrystals) and a dynamic ERC-721 token (Forged Artifacts), incorporating mechanics like staking, forging, attribute modification, state decay, reputation, and a global "Temporal Flux" influence.

It aims for novelty by integrating token standards and custom dynamic logic within a single contract and designing interactions between users, fungible tokens, and non-fungible assets based on time, state, and participation, without copying standard library implementations directly (though it adheres to interface standards).

**Disclaimer:** This contract is complex and conceptual. It is provided as an educational example and has not been audited or gas-optimized. Deploying such a contract requires thorough testing, security audits, and careful consideration of economic implications. Time-based logic in Solidity (using `block.timestamp`) can be susceptible to miner manipulation in certain scenarios, though less critical in this specific design.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Chronosforge Ecosystem
 * @dev A decentralized ecosystem combining ERC20 (ChronoCrystals) and
 *      dynamic ERC721 (Forged Artifacts) with features like staking,
 *      forging, attribute modification, temporal flux influence, and reputation.
 *      This contract implements both token standards and ecosystem logic.
 *      It avoids duplicating standard open-source implementations by integrating
 *      the core logic and state management directly within the custom contract.
 */

/**
 * CONTRACT OUTLINE:
 *
 * 1. State Variables:
 *    - ERC20 (ChronoCrystals) State: Balances, allowances, total supply.
 *    - ERC721 (Forged Artifacts) State: Owners, balances, approvals, token URIs.
 *    - Ecosystem State: Owner, pause status, temporal flux, artifact attributes,
 *      user reputation, staking data (artifacts and crystals), costs/yields settings.
 *
 * 2. Structs & Enums:
 *    - ArtifactAttributes: Defines dynamic properties of a Forged Artifact.
 *    - ArtifactState: Enum for artifact lifecycle stages (Dormant, Active, Decaying).
 *
 * 3. Events:
 *    - Standard ERC20/ERC721 events (Transfer, Approval).
 *    - Ecosystem specific events (Forge, StakeArtifact, UnstakeArtifact,
 *      ClaimArtifactRewards, StakeCrystals, UnstakeCrystals, ClaimCrystalRewards,
 *      LevelUp, RefillEnergy, ModifyAttribute, MergeArtifacts, FluxUpdate,
 *      ReputationUpdate, StateChange, CostsUpdated, YieldsUpdated).
 *
 * 4. Modifiers:
 *    - onlyOwner: Restricts access to the contract owner.
 *    - whenNotPaused: Prevents execution when the contract is paused.
 *    - whenPaused: Allows execution only when the contract is paused.
 *    - notStaked: Prevents actions on artifacts while staked.
 *
 * 5. Interfaces:
 *    - IERC165: For interface detection.
 *    - IERC721, IERC721Metadata, IERC721Enumerable: For ERC721 compliance.
 *    - IERC20: For ERC20 compliance.
 *    - IERC721Receiver: For safeTransferFrom compatibility check.
 *
 * 6. Constructor:
 *    - Initializes the contract, sets owner, mints initial supply of ChronoCrystals.
 *
 * 7. Access Control & Pausability:
 *    - pause, unpause: Functions to pause/unpause core functionality.
 *
 * 8. ERC20 (ChronoCrystals) Implementation:
 *    - name, symbol, decimals, totalSupply, balanceOf, transfer, allowance,
 *      approve, transferFrom.
 *    - Internal _mint, _burn, _transfer, _approve helpers.
 *
 * 9. ERC721 (Forged Artifacts) Implementation:
 *    - supportsInterface, balanceOf, ownerOf, approve, getApproved,
 *      setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom.
 *    - ERC721Enumerable (partial): totalArtifactSupply, tokenByIndex, tokenOfOwnerByIndex.
 *    - ERC721Metadata: tokenURI.
 *    - Internal _mint, _burn, _transfer helpers with enumeration and metadata updates.
 *
 * 10. Ecosystem Core Logic:
 *     - updateTemporalFlux: Admin function to change global flux.
 *     - forgeArtifact: Creates a new artifact (costs crystals).
 *     - levelUpArtifact: Increases artifact level (costs crystals, impacts yield/energy).
 *     - refillEnergy: Restores artifact energy (costs crystals).
 *     - modifyArtifactAttribute: Randomly modifies an attribute (costs crystals, influenced by flux/reputation).
 *     - mergeArtifacts: Burns two artifacts to create a new, potentially stronger one (costs crystals, properties derived).
 *
 * 11. Staking Mechanisms:
 *     - stakeArtifact: Stakes an artifact for yield.
 *     - unstakeArtifact: Unstakes an artifact.
 *     - claimArtifactStakingRewards: Claims accrued crystal rewards from artifact staking.
 *     - stakeCrystals: Stakes ChronoCrystals for yield.
 *     - unstakeCrystals: Unstakes ChronoCrystals.
 *     - claimCrystalStakingRewards: Claims accrued crystal rewards from crystal staking.
 *
 * 12. Dynamic State & Calculations:
 *     - refreshArtifactState: Public helper to update an artifact's energy and state based on time.
 *     - getCurrentEnergy: View function to get current energy considering time elapsed.
 *     - getArtifactState: View function to get current state considering time elapsed.
 *     - calculateArtifactStakingYield: View function to calculate yield rate for an artifact stake.
 *     - calculateCrystalStakingYield: View function to calculate yield rate for a crystal stake.
 *     - _updateArtifactState: Internal function to calculate and update artifact state/energy.
 *     - _calculateArtifactEnergy: Internal helper for energy calculation.
 *     - _calculateEffectiveReputation: Internal helper for weighted reputation.
 *     - _calculateArtifactRawYield: Internal helper for artifact base yield.
 *     - _calculateCrystalRawYield: Internal helper for crystal base yield.
 *     - _calculateAccruedArtifactRewards: Internal helper for accrued artifact rewards.
 *     - _calculateAccruedCrystalRewards: Internal helper for accrued crystal rewards.
 *
 * 13. View Functions:
 *     - getTemporalFlux: Gets the current temporal flux value.
 *     - getArtifactAttributes: Gets attributes of an artifact.
 *     - getUserReputation: Gets reputation score of a user.
 *     - isArtifactStaked: Checks if an artifact is staked.
 *     - getUserArtifactStake: Gets details of a staked artifact.
 *     - getUserCrystalStake: Gets details of a staked crystal amount.
 *     - getBaseCosts: Gets base costs settings.
 *     - getBaseYields: Gets base yields settings.
 *     - getReputationEffects: Gets reputation effects settings.
 *     - getTotalCrystalsStaked: Gets total crystals staked.
 *     - getTotalArtifactsStaked: Gets total artifacts staked.
 *     - getArtifactLastStateUpdateTime: Gets last state update time for an artifact.
 *
 * 14. Admin Functions:
 *     - adminMintCrystals: Mints new crystals (carefully used, e.g., for initial supply).
 *     - adminBurnArtifact: Burns an artifact.
 *     - adminSetReputation: Manually sets a user's reputation (for specific scenarios).
 *     - setBaseCosts: Sets ecosystem base costs.
 *     - setBaseYields: Sets ecosystem base yields.
 *     - setReputationEffects: Sets effects of reputation on costs/yields.
 */

// Standard Interfaces (Defining them here to avoid direct OZ imports for the *implementation* parts)
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
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

interface IERC721Metadata is IERC721 {
    function name() external view returns (string calldata);
    function symbol() external view returns (string calldata);
    function tokenURI(uint256 tokenId) external view returns (string calldata);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256 tokenId);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract ChronosforgeEcosystem is IERC20, IERC721, IERC721Metadata, IERC721Enumerable, IERC165 {
    // --- State Variables ---

    // ERC20 (ChronoCrystals) State
    string private _name20 = "ChronoCrystal";
    string private _symbol20 = "CHR";
    uint8 private _decimals = 18;
    uint256 private _totalSupply20;
    mapping(address => uint256) private _balances20;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ERC721 (Forged Artifacts) State
    string private _name721 = "ForgedArtifact";
    string private _symbol721 = "ART";
    uint256 private _totalArtifactSupply;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances721;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs;

    // ERC721 Enumeration (partial manual implementation)
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(address => uint256[] ) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Ecosystem State
    address private _owner;
    bool private _paused;
    uint256 private _temporalFlux; // Global state influencing artifact attributes/yields

    enum ArtifactState { Dormant, Active, Decaying }

    struct ArtifactAttributes {
        uint256 level;
        uint256 affinity; // Affinity to temporal flux
        uint256 baseEnergy; // Max energy potential
        uint256 currentEnergy;
        uint256 creationTime;
        uint256 lastStateUpdateTime;
        ArtifactState state;
        // More attributes could be added (e.g., rarity, element, history...)
    }

    mapping(uint256 => ArtifactAttributes) private _artifactAttributes;
    mapping(address => uint256) private _userReputation; // Simple participation score

    // Staking State
    mapping(uint256 => address) private _stakedArtifacts; // tokenId => staker (address(0) if not staked)
    mapping(address => uint256) private _artifactStakingStartTime; // staker => timestamp
    mapping(address => uint256) private _artifactStakingRewardsClaimed; // staker => claimed amount

    mapping(address => uint256) private _stakedCrystals; // staker => amount
    mapping(address => uint256) private _crystalStakingStartTime; // staker => timestamp
    mapping(address => uint256) private _crystalStakingRewardsClaimed; // staker => claimed amount

    uint256 private _totalCrystalsStaked;
    uint256 private _totalArtifactsStaked;

    // Configuration Costs & Yields (Admin adjustable)
    struct BaseCosts {
        uint256 forgeCost; // CHR to forge
        uint256 levelUpCostPerLevel; // CHR per level
        uint256 refillEnergyCost; // CHR per energy unit
        uint256 modifyAttributeCost; // CHR per modification
        uint256 mergeCost; // CHR to merge
    }
    BaseCosts public baseCosts;

    struct BaseYields {
        uint256 artifactYieldPerSec; // CHR per sec base yield for artifacts
        uint256 crystalYieldPerSecPerToken; // CHR per sec per token base yield for crystals
        uint256 energyRegenPerSec; // Energy per sec
    }
    BaseYields public baseYields;

    struct ReputationEffects {
        uint256 yieldBonusPercentage; // % bonus on yield per reputation point (e.g., 100 for 1%)
        uint256 costReductionPercentage; // % reduction on costs per reputation point
    }
    ReputationEffects public reputationEffects;

    // Interface IDs for ERC165
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80415575;
    bytes4 private constant _INTERFACE_ID_ERC721Enumerable = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_ERC721Metadata = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x36372b07; // Not strictly required for ERC165 but good practice if supporting EIPs


    // --- Events ---

    // ERC20 Events (Standard)
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ERC721 Events (Standard)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Ecosystem Events
    event Forge(address indexed owner, uint256 indexed tokenId, uint256 cost);
    event StakeArtifact(address indexed staker, uint256 indexed tokenId, uint256 timestamp);
    event UnstakeArtifact(address indexed staker, uint256 indexed tokenId, uint256 timestamp);
    event ClaimArtifactRewards(address indexed staker, uint256 indexed tokenId, uint256 amount);
    event StakeCrystals(address indexed staker, uint256 amount, uint256 timestamp);
    event UnstakeCrystals(address indexed staker, uint256 amount, uint256 timestamp);
    event ClaimCrystalRewards(address indexed staker, uint256 amount, uint256 timestamp);
    event LevelUp(uint256 indexed tokenId, uint256 newLevel, uint256 cost);
    event RefillEnergy(uint256 indexed tokenId, uint256 energyAdded, uint256 cost);
    event ModifyAttribute(uint256 indexed tokenId, string attributeName, uint256 oldValue, uint256 newValue, uint256 cost);
    event MergeArtifacts(address indexed owner, uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 newArtifactId, uint256 cost);
    event FluxUpdate(uint256 oldFlux, uint256 newFlux);
    event ReputationUpdate(address indexed user, uint256 oldReputation, uint256 newReputation);
    event ArtifactStateChange(uint256 indexed tokenId, ArtifactState oldState, ArtifactState newState, uint256 currentEnergy);
    event CostsUpdated(BaseCosts newCosts);
    event YieldsUpdated(BaseYields newYields);
    event ReputationEffectsUpdated(ReputationEffects newEffects);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    modifier notStaked(uint256 tokenId) {
        require(_stakedArtifacts[tokenId] == address(0), "Artifact is staked");
        _;
    }


    // --- Constructor ---

    constructor(uint256 initialCrystalSupply) {
        _owner = msg.sender;
        _paused = false;
        _temporalFlux = 0; // Initial flux

        // Initial crystal supply
        _mintERC20(msg.sender, initialCrystalSupply);

        // Default costs & yields
        baseCosts = BaseCosts({
            forgeCost: 100e18,
            levelUpCostPerLevel: 50e18,
            refillEnergyCost: 1e18, // Cost per energy unit
            modifyAttributeCost: 200e18,
            mergeCost: 500e18
        });

        baseYields = BaseYields({
            artifactYieldPerSec: 1e15, // 0.001 CHR per sec per artifact base
            crystalYieldPerSecPerToken: 1e12, // 0.000001 CHR per sec per crystal base
            energyRegenPerSec: 1 // 1 energy per sec base
        });

        reputationEffects = ReputationEffects({
            yieldBonusPercentage: 50, // 0.5% bonus per reputation
            costReductionPercentage: 20 // 0.2% reduction per reputation
        });
    }


    // --- Access Control & Pausability ---

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        // Emit an event if desired
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
        // Emit an event if desired
    }


    // --- IERC165 Implementation ---

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165 ||
               interfaceId == _INTERFACE_ID_ERC721 ||
               interfaceId == _INTERFACE_ID_ERC721Metadata ||
               interfaceId == _INTERFACE_ID_ERC721Enumerable ||
               interfaceId == _INTERFACE_ID_ERC20;
    }


    // --- ERC20 (ChronoCrystals) Implementation ---

    function name() public view override returns (string memory) {
        return _name20;
    }

    function symbol() public view override returns (string memory) {
        return _symbol20;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply20;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances20[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferERC20(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approveERC20(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approveERC20(sender, msg.sender, currentAllowance - amount);
        }
        _transferERC20(sender, recipient, amount);
        return true;
    }

    // Internal ERC20 helpers
    function _transferERC20(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances20[sender] >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances20[sender] -= amount;
            _balances20[recipient] += amount;
        }
        emit Transfer(sender, recipient, amount);
    }

    function _mintERC20(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply20 += amount;
        _balances20[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Callable by ecosystem functions to burn crystals for actions
    function _burnERC20ForAction(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances20[account] >= amount, "ERC20: burn amount exceeds balance");

        unchecked {
            _balances20[account] -= amount;
        }
        _totalSupply20 -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approveERC20(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    // --- ERC721 (Forged Artifacts) Implementation ---

    function name() public view override(IERC721Metadata, IERC721) returns (string memory) {
         return _name721;
    }

    function symbol() public view override(IERC721Metadata, IERC721) returns (string memory) {
         return _symbol721;
    }

    function balanceOf(address owner) public view override(IERC721, IERC721Enumerable) returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances721[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_owners[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function approve(address to, uint256 tokenId) public override whenNotPaused {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not token owner or approved for all");
        _approveERC721(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        require(_isApprovedOrOwnerERC721(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transferERC721(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused {
        require(_isApprovedOrOwnerERC721(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transferERC721(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // ERC721Enumerable partial implementation
    function totalArtifactSupply() public view returns (uint256) {
         return _totalArtifactSupply; // Distinct name from ERC20 totalSupply
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < _allTokens.length, "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < _ownedTokens[owner].length, "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

     // Custom function for getting all token IDs owned by an address
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }


    // Internal ERC721 helpers
    function _isApprovedOrOwnerERC721(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _approveERC721(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _transferERC721(address from, address to, uint256 tokenId) internal notStaked(tokenId) {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approveERC721(address(0), tokenId);

        _balances721[from] -= 1;
        _balances721[to] += 1;
        _owners[tokenId] = to;

        // Update enumeration mappings
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _mintERC721(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[tokenId] == address(0), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _totalArtifactSupply += 1;
        _balances721[to] += 1;
        _owners[tokenId] = to;

        // Update enumeration mappings
        _addTokenToAllTokensEnumeration(tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burnERC721(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Ensure it exists

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approveERC721(address(0), tokenId);

        _balances721[owner] -= 1;
        _owners[tokenId] = address(0); // Clear ownership

        // Update enumeration mappings
        _removeTokenFromAllTokensEnumeration(tokenId);
        _removeTokenFromOwnerEnumeration(owner, tokenId);

        // Clear token URI and attributes
        delete _tokenURIs[tokenId];
        delete _artifactAttributes[tokenId];

        _totalArtifactSupply -= 1;

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal {
        if (from == address(0)) {
            // Minting
        } else if (to == address(0)) {
            // Burning
             require(_stakedArtifacts[tokenId] == address(0), "Artifact is staked and cannot be burned");
             // Potential cleanup if artifact was staked or had rewards pending
        } else {
            // Transferring
             require(_stakedArtifacts[tokenId] == address(0), "Artifact is staked and cannot be transferred");
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal {
         if (from != address(0) && _stakedArtifacts[tokenId] != address(0)) {
            // Handle unstaking or reward claiming if transfer happens from stake manager
            // In this simple implementation, transfer from/to stake manager isn't exposed
            // publicly, so the notStaked modifier handles this.
         }
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                 if (reason.length == 0) {
                    revert("ERC721: Transfer to non ERC721Receiver implementer or invalid return value");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true; // Regular wallet
        }
    }

    // ERC721 Enumeration Helpers (manual implementation)
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        _allTokens.pop();
        delete _allTokensIndex[tokenId];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

        _ownedTokens[from][tokenIndex] = lastTokenId;
        _ownedTokensIndex[lastTokenId] = tokenIndex;

        _ownedTokens[from].pop();
        delete _ownedTokensIndex[tokenId];
    }

    // --- Ecosystem Core Logic ---

    /**
     * @dev Updates the global Temporal Flux. Influences artifact attributes and yields.
     * @param newFlux The new value for the temporal flux.
     */
    function updateTemporalFlux(uint256 newFlux) external onlyOwner whenNotPaused {
        uint256 oldFlux = _temporalFlux;
        _temporalFlux = newFlux;
        emit FluxUpdate(oldFlux, newFlux);
    }

    /**
     * @dev Allows a user to forge a new Forged Artifact. Costs ChronoCrystals.
     *      New artifact attributes are generated (simplified random).
     * @param initialAffinity The initial affinity value for the new artifact.
     * @param initialBaseEnergy The initial base energy for the new artifact.
     */
    function forgeArtifact(uint256 initialAffinity, uint256 initialBaseEnergy) external whenNotPaused {
        uint256 cost = baseCosts.forgeCost;
        uint256 effectiveCost = _applyCostReduction(cost, msg.sender);
        require(_balances20[msg.sender] >= effectiveCost, "Insufficient ChronoCrystals to forge");

        _burnERC20ForAction(msg.sender, effectiveCost);

        uint256 newTokenId = _totalArtifactSupply + 1; // Simple sequential ID
        _mintERC721(msg.sender, newTokenId);

        _artifactAttributes[newTokenId] = ArtifactAttributes({
            level: 1,
            affinity: initialAffinity,
            baseEnergy: initialBaseEnergy,
            currentEnergy: initialBaseEnergy, // Starts full
            creationTime: block.timestamp,
            lastStateUpdateTime: block.timestamp,
            state: ArtifactState.Active // Starts active
        });

        _updateUserReputation(msg.sender, _userReputation[msg.sender] + 1); // Gain reputation for forging

        emit Forge(msg.sender, newTokenId, effectiveCost);
        emit ArtifactStateChange(newTokenId, ArtifactState.Dormant, ArtifactState.Active, initialBaseEnergy); // Assuming Dormant is initial "non-existent" state
    }

    /**
     * @dev Levels up a Forged Artifact. Costs ChronoCrystals.
     *      Increases level, potentially boosting baseEnergy or other stats.
     * @param tokenId The ID of the artifact to level up.
     */
    function levelUpArtifact(uint256 tokenId) external whenNotPaused notStaked(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of this artifact");
        ArtifactAttributes storage attrs = _artifactAttributes[tokenId];

        // Ensure state is updated before calculating cost or applying changes
        _updateArtifactState(tokenId);

        uint256 cost = baseCosts.levelUpCostPerLevel * attrs.level; // Cost increases with level
        uint256 effectiveCost = _applyCostReduction(cost, msg.sender);
        require(_balances20[msg.sender] >= effectiveCost, "Insufficient ChronoCrystals to level up");

        _burnERC20ForAction(msg.sender, effectiveCost);

        attrs.level += 1;
        // Simple attribute boost on level up (example)
        attrs.baseEnergy += 10;
        attrs.currentEnergy = attrs.baseEnergy; // Refill energy on level up

        emit LevelUp(tokenId, attrs.level, effectiveCost);
        emit RefillEnergy(tokenId, attrs.baseEnergy, 0); // Emit energy refill event
    }

    /**
     * @dev Refills energy of a Forged Artifact. Costs ChronoCrystals per energy unit.
     * @param tokenId The ID of the artifact to refill energy.
     */
    function refillEnergy(uint256 tokenId) external whenNotPaused notStaked(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of this artifact");
        ArtifactAttributes storage attrs = _artifactAttributes[tokenId];

         // Ensure state is updated first
        _updateArtifactState(tokenId);

        uint256 neededEnergy = attrs.baseEnergy - attrs.currentEnergy;
        require(neededEnergy > 0, "Artifact energy is already full");

        uint256 costPerUnit = baseCosts.refillEnergyCost;
        uint256 totalCost = costPerUnit * neededEnergy;
        uint256 effectiveCost = _applyCostReduction(totalCost, msg.sender);
        require(_balances20[msg.sender] >= effectiveCost, "Insufficient ChronoCrystals to refill energy");

        _burnERC20ForAction(msg.sender, effectiveCost);

        attrs.currentEnergy = attrs.baseEnergy; // Refill to max
        attrs.lastStateUpdateTime = block.timestamp; // Reset timer

        // Check if state changes after refill
        ArtifactState oldState = attrs.state;
        _updateArtifactState(tokenId); // Recalculate state immediately

        emit RefillEnergy(tokenId, neededEnergy, effectiveCost);
         if (oldState != attrs.state) {
            emit ArtifactStateChange(tokenId, oldState, attrs.state, attrs.currentEnergy);
        }
    }

    /**
     * @dev Modifies a random attribute of a Forged Artifact. Costs ChronoCrystals.
     *      Modification outcome might be influenced by Temporal Flux.
     * @param tokenId The ID of the artifact to modify.
     */
    function modifyArtifactAttribute(uint256 tokenId) external whenNotPaused notStaked(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of this artifact");
        ArtifactAttributes storage attrs = _artifactAttributes[tokenId];

        uint256 cost = baseCosts.modifyAttributeCost;
        uint256 effectiveCost = _applyCostReduction(cost, msg.sender);
        require(_balances20[msg.sender] >= effectiveCost, "Insufficient ChronoCrystals to modify attribute");

        _burnERC20ForAction(msg.sender, effectiveCost);

        // Simple pseudo-random attribute modification
        // In a real scenario, use a more robust randomness solution (Chainlink VRF, etc.)
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, _temporalFlux, attrs.level)));
        uint256 attributeToModify = randomNumber % 2; // 0 for affinity, 1 for baseEnergy

        if (attributeToModify == 0) { // Modify Affinity
            uint256 oldAffinity = attrs.affinity;
            // Example: Influence by flux - maybe closer to flux value is better?
            uint256 fluxInfluence = _temporalFlux % 100; // Simplified influence
            uint256 change = (randomNumber % 20) - 10; // Random change between -10 and +10
            int256 newAffinity = int256(oldAffinity) + int256(change);
            if (fluxInfluence > 50) newAffinity += (randomNumber % 5); // Bonus if flux is high

            attrs.affinity = uint256(newAffinity > 0 ? newAffinity : 0); // Ensure non-negative

            emit ModifyAttribute(tokenId, "affinity", oldAffinity, attrs.affinity, effectiveCost);
        } else { // Modify Base Energy
            uint256 oldBaseEnergy = attrs.baseEnergy;
            uint256 change = (randomNumber % 50) - 25; // Random change between -25 and +25
             int256 newBaseEnergy = int256(oldBaseEnergy) + int256(change);
             attrs.baseEnergy = uint256(newBaseEnergy > 0 ? newBaseEnergy : 0); // Ensure non-negative
             // If max energy changes, current energy might need adjustment or full refill logic could be applied
             attrs.currentEnergy = attrs.baseEnergy; // Simplify: refill on modify

            emit ModifyAttribute(tokenId, "baseEnergy", oldBaseEnergy, attrs.baseEnergy, effectiveCost);
             emit RefillEnergy(tokenId, attrs.baseEnergy, 0);
        }
        _updateUserReputation(msg.sender, _userReputation[msg.sender] + 1); // Gain reputation
    }

     /**
     * @dev Merges two Forged Artifacts owned by the user into a new one.
     *      Burns the two input artifacts and mints a new one.
     *      New artifact properties are derived from the merged ones. Costs ChronoCrystals.
     * @param tokenId1 The ID of the first artifact to merge.
     * @param tokenId2 The ID of the second artifact to merge.
     */
    function mergeArtifacts(uint256 tokenId1, uint256 tokenId2) external whenNotPaused {
        require(tokenId1 != tokenId2, "Cannot merge an artifact with itself");
        require(ownerOf(tokenId1) == msg.sender, "Not the owner of artifact 1");
        require(ownerOf(tokenId2) == msg.sender, "Not the owner of artifact 2");
        require(_stakedArtifacts[tokenId1] == address(0), "Artifact 1 is staked");
        require(_stakedArtifacts[tokenId2] == address(0), "Artifact 2 is staked");


        uint256 cost = baseCosts.mergeCost;
        uint256 effectiveCost = _applyCostReduction(cost, msg.sender);
        require(_balances20[msg.sender] >= effectiveCost, "Insufficient ChronoCrystals to merge");

        _burnERC20ForAction(msg.sender, effectiveCost);

        ArtifactAttributes memory attrs1 = _artifactAttributes[tokenId1];
        ArtifactAttributes memory attrs2 = _artifactAttributes[tokenId2];

        // Burn the old artifacts
        _burnERC721(tokenId1);
        _burnERC721(tokenId2);

        // Mint the new artifact
        uint256 newArtifactId = _totalArtifactSupply + 1; // Use next available ID
        _mintERC721(msg.sender, newArtifactId);

        // Derive new attributes (example logic: average + bonus)
        uint256 newLevel = (attrs1.level + attrs2.level) / 2 + 1; // Average plus one level bonus
        uint256 newAffinity = (attrs1.affinity + attrs2.affinity) / 2;
        uint256 newBaseEnergy = (attrs1.baseEnergy + attrs2.baseEnergy) / 2 + 50; // Average plus base energy bonus

         _artifactAttributes[newArtifactId] = ArtifactAttributes({
            level: newLevel,
            affinity: newAffinity,
            baseEnergy: newBaseEnergy,
            currentEnergy: newBaseEnergy, // New artifact starts full energy
            creationTime: block.timestamp,
            lastStateUpdateTime: block.timestamp,
            state: ArtifactState.Active
        });

        _updateUserReputation(msg.sender, _userReputation[msg.sender] + 2); // Gain more reputation for merging

        emit MergeArtifacts(msg.sender, tokenId1, tokenId2, newArtifactId, effectiveCost);
        emit Forge(msg.sender, newArtifactId, 0); // Treat merge as a type of forge for the new token
        emit ArtifactStateChange(newArtifactId, ArtifactState.Dormant, ArtifactState.Active, newBaseEnergy);
    }


    // --- Staking Mechanisms ---

    /**
     * @dev Stakes a Forged Artifact owned by the user.
     * @param tokenId The ID of the artifact to stake.
     */
    function stakeArtifact(uint256 tokenId) external whenNotPaused notStaked(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of this artifact");

        // Claim any pending rewards for the *user* from previous artifact stakes
        uint256 pendingRewards = _calculateAccruedArtifactRewards(msg.sender);
        if (pendingRewards > 0) {
            _mintERC20(msg.sender, pendingRewards);
             // Assuming rewards are claimed for all artifacts staked by this user,
             // we reset the claimable time based on *total* staking duration
             // This approach simplifies tracking per-artifact, but means unstaking one
             // requires claiming for all or loses unclaimed yield on *other* stakes.
             // A more granular system would track start time per-stake.
             // For this example, we'll use the simplified per-user start time.
             _artifactStakingRewardsClaimed[msg.sender] += pendingRewards; // Track total claimed
        }

        // Update artifact state before staking to record last update time
        _updateArtifactState(tokenId);

        // Transfer artifact to the contract (staking address)
        _transferERC721(msg.sender, address(this), tokenId); // Use internal transfer
        _stakedArtifacts[tokenId] = msg.sender; // Record the original staker

        _totalArtifactsStaked += 1;
        // If this is the user's first artifact stake, record start time
        if (_artifactStakingStartTime[msg.sender] == 0) {
             _artifactStakingStartTime[msg.sender] = block.timestamp;
        }
        // Otherwise, the start time remains for the overall user's stake pool

         _updateUserReputation(msg.sender, _userReputation[msg.sender] + 1); // Gain reputation for staking

        emit StakeArtifact(msg.sender, tokenId, block.timestamp);
    }

    /**
     * @dev Unstakes a Forged Artifact. Claims accrued rewards for all user's staked artifacts.
     * @param tokenId The ID of the artifact to unstake.
     */
    function unstakeArtifact(uint256 tokenId) external whenNotPaused {
        require(_stakedArtifacts[tokenId] == msg.sender, "Artifact is not staked by this user");

        // Claim all pending rewards for the user before unstaking
        uint256 pendingRewards = _calculateAccruedArtifactRewards(msg.sender);
        if (pendingRewards > 0) {
            _mintERC20(msg.sender, pendingRewards);
            _artifactStakingRewardsClaimed[msg.sender] += pendingRewards;
        }

        // Transfer artifact back to the staker
        _transferERC721(address(this), msg.sender, tokenId); // Use internal transfer
        _stakedArtifacts[tokenId] = address(0); // Clear stake record

        _totalArtifactsStaked -= 1;

        // Reset user's artifact staking start time ONLY if they have no more artifacts staked
        uint256 userStakedCount = 0;
        for (uint256 i = 0; i < _allTokens.length; i++) {
             uint256 currentTokenId = _allTokens[i];
             if (_stakedArtifacts[currentTokenId] == msg.sender) {
                 userStakedCount++;
             }
        }
        if (userStakedCount == 0) {
             _artifactStakingStartTime[msg.sender] = 0; // Reset start time when no artifacts are staked
             _artifactStakingRewardsClaimed[msg.sender] = 0; // Reset claimed amount too
        }


        emit UnstakeArtifact(msg.sender, tokenId, block.timestamp);
        if (pendingRewards > 0) {
             emit ClaimArtifactRewards(msg.sender, 0, pendingRewards); // Emitting with token 0 to signify total claim
        }
    }

     /**
     * @dev Claims accrued ChronoCrystal rewards from staked Forged Artifacts.
     *      Claims rewards for ALL artifacts currently staked by the user.
     */
    function claimArtifactStakingRewards() external whenNotPaused {
        require(_artifactStakingStartTime[msg.sender] > 0, "No artifacts currently staked by this user");

        uint256 pendingRewards = _calculateAccruedArtifactRewards(msg.sender);
        require(pendingRewards > 0, "No accrued artifact staking rewards to claim");

        _mintERC20(msg.sender, pendingRewards);
        _artifactStakingRewardsClaimed[msg.sender] += pendingRewards; // Track claimed amount
        // The _artifactStakingStartTime is NOT reset here, only on unstake of the last artifact.
        // This means yield calculation needs to account for total earned vs total claimed.

        emit ClaimArtifactRewards(msg.sender, 0, pendingRewards); // Emitting with token 0 to signify total claim
    }


    /**
     * @dev Stakes a user's ChronoCrystals.
     * @param amount The amount of ChronoCrystals to stake.
     */
    function stakeCrystals(uint256 amount) external whenNotPaused {
        require(amount > 0, "Cannot stake 0 amount");
        require(_balances20[msg.sender] >= amount, "Insufficient ChronoCrystals balance");

         // Claim any pending rewards for the user from previous crystal stakes
        uint256 pendingRewards = _calculateAccruedCrystalRewards(msg.sender);
        if (pendingRewards > 0) {
            _mintERC20(msg.sender, pendingRewards);
            _crystalStakingRewardsClaimed[msg.sender] += pendingRewards;
        }

        _burnERC20ForAction(msg.sender, amount); // Transfer to staking pool (contract)

        _stakedCrystals[msg.sender] += amount;
        _totalCrystalsStaked += amount;

        // If this is the user's first crystal stake, record start time
        if (_crystalStakingStartTime[msg.sender] == 0) {
             _crystalStakingStartTime[msg.sender] = block.timestamp;
        }
        // Otherwise, start time remains for the user's total crystal stake

         _updateUserReputation(msg.sender, _userReputation[msg.sender] + 1); // Gain reputation

        emit StakeCrystals(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Unstakes a user's ChronoCrystals. Claims accrued rewards.
     * @param amount The amount of ChronoCrystals to unstake.
     */
    function unstakeCrystals(uint256 amount) external whenNotPaused {
        require(amount > 0, "Cannot unstake 0 amount");
        require(_stakedCrystals[msg.sender] >= amount, "Cannot unstake more crystals than staked");

        // Claim all pending rewards for the user before unstaking
        uint256 pendingRewards = _calculateAccruedCrystalRewards(msg.sender);
        if (pendingRewards > 0) {
            _mintERC20(msg.sender, pendingRewards);
            _crystalStakingRewardsClaimed[msg.sender] += pendingRewards;
        }

        _stakedCrystals[msg.sender] -= amount;
        _totalCrystalsStaked -= amount;

        _mintERC20(msg.sender, amount); // Transfer unstaked amount back

        // Reset user's crystal staking start time ONLY if they have no more crystals staked
        if (_stakedCrystals[msg.sender] == 0) {
             _crystalStakingStartTime[msg.sender] = 0; // Reset start time
             _crystalStakingRewardsClaimed[msg.sender] = 0; // Reset claimed amount too
        }

        emit UnstakeCrystals(msg.sender, amount, block.timestamp);
         if (pendingRewards > 0) {
             emit ClaimCrystalRewards(msg.sender, pendingRewards, block.timestamp);
         }
    }

     /**
     * @dev Claims accrued ChronoCrystal rewards from staked ChronoCrystals.
     */
    function claimCrystalStakingRewards() external whenNotPaused {
        require(_stakedCrystals[msg.sender] > 0, "No crystals currently staked by this user");

        uint256 pendingRewards = _calculateAccruedCrystalRewards(msg.sender);
        require(pendingRewards > 0, "No accrued crystal staking rewards to claim");

        _mintERC20(msg.sender, pendingRewards);
        _crystalStakingRewardsClaimed[msg.sender] += pendingRewards;
        // The _crystalStakingStartTime is NOT reset here, only on unstake of the last crystal.

        emit ClaimCrystalRewards(msg.sender, pendingRewards, block.timestamp);
    }


    // --- Dynamic State & Calculations ---

    /**
     * @dev Public helper to trigger an artifact's state and energy update based on time elapsed.
     *      Anyone can call this to refresh an artifact's status.
     * @param tokenId The ID of the artifact to refresh.
     */
    function refreshArtifactState(uint256 tokenId) external whenNotPaused {
        _updateArtifactState(tokenId);
    }

    /**
     * @dev Internal function to calculate and update an artifact's energy and state.
     *      Called by any function interacting with an artifact or via refreshArtifactState.
     * @param tokenId The ID of the artifact to update.
     */
    function _updateArtifactState(uint256 tokenId) internal {
        require(_owners[tokenId] != address(0) || _stakedArtifacts[tokenId] != address(0), "Artifact does not exist or is not owned/staked"); // Artifact must exist

        ArtifactAttributes storage attrs = _artifactAttributes[tokenId];
        require(attrs.lastStateUpdateTime <= block.timestamp, "Invalid last state update time"); // Sanity check

        uint256 timeElapsed = block.timestamp - attrs.lastStateUpdateTime;
        if (timeElapsed == 0) {
            // No time has passed, no update needed
            return;
        }

        // Calculate energy regeneration
        uint256 energyGained = timeElapsed * baseYields.energyRegenPerSec;
        attrs.currentEnergy += energyGained;

        // Cap energy at baseEnergy (max energy)
        if (attrs.currentEnergy > attrs.baseEnergy) {
            attrs.currentEnergy = attrs.baseEnergy;
        }

        // Update state based on energy level
        ArtifactState oldState = attrs.state;
        if (attrs.currentEnergy >= attrs.baseEnergy / 2) {
            attrs.state = ArtifactState.Active;
        } else if (attrs.currentEnergy > 0) {
            attrs.state = ArtifactState.Dormant;
        } else { // currentEnergy == 0
            attrs.state = ArtifactState.Decaying;
        }

        attrs.lastStateUpdateTime = block.timestamp; // Update last update time

        if (oldState != attrs.state) {
            emit ArtifactStateChange(tokenId, oldState, attrs.state, attrs.currentEnergy);
        }
    }

    /**
     * @dev Calculates the current energy of an artifact, considering time elapsed since last update.
     * @param tokenId The ID of the artifact.
     * @return The current energy.
     */
    function getCurrentEnergy(uint256 tokenId) public view returns (uint256) {
        require(_owners[tokenId] != address(0) || _stakedArtifacts[tokenId] != address(0), "Artifact does not exist or is not owned/staked");
        ArtifactAttributes memory attrs = _artifactAttributes[tokenId];
        uint256 timeElapsed = block.timestamp - attrs.lastStateUpdateTime;
        uint256 energyGained = timeElapsed * baseYields.energyRegenPerSec;
        uint256 current = attrs.currentEnergy + energyGained;
        return current > attrs.baseEnergy ? attrs.baseEnergy : current; // Cap at max energy
    }

     /**
     * @dev Calculates the current state of an artifact, considering time elapsed and energy.
     * @param tokenId The ID of the artifact.
     * @return The current state (Dormant, Active, Decaying).
     */
    function getArtifactState(uint256 tokenId) public view returns (ArtifactState) {
         require(_owners[tokenId] != address(0) || _stakedArtifacts[tokenId] != address(0), "Artifact does not exist or is not owned/staked");
         ArtifactAttributes memory attrs = _artifactAttributes[tokenId];
         uint256 current = getCurrentEnergy(tokenId);

         if (current >= attrs.baseEnergy / 2) {
             return ArtifactState.Active;
         } else if (current > 0) {
             return ArtifactState.Dormant;
         } else { // currentEnergy == 0
             return ArtifactState.Decaying;
         }
    }


    /**
     * @dev Calculates the effective ChronoCrystal yield rate per second for a staked artifact.
     *      Yield depends on artifact level, energy, affinity, temporal flux, and user reputation.
     * @param tokenId The ID of the staked artifact.
     * @return The yield rate in ChronoCrystals per second.
     */
    function calculateArtifactStakingYield(uint256 tokenId) public view returns (uint256) {
        address staker = _stakedArtifacts[tokenId];
        require(staker != address(0), "Artifact is not staked");

        ArtifactAttributes memory attrs = _artifactAttributes[tokenId];

        // Decay penalty if in Decaying state (example)
        if (getArtifactState(tokenId) == ArtifactState.Decaying) {
             return 0; // No yield if decaying
        }

        // Base yield * level multiplier
        uint256 rawYield = _calculateArtifactRawYield(tokenId);

        // Flux influence (example: yield is maximized when affinity matches flux)
        uint256 fluxDiff = attrs.affinity > _temporalFlux ? attrs.affinity - _temporalFlux : _temporalFlux - attrs.affinity;
        uint256 fluxMultiplier = 10000 - (fluxDiff * 100); // Max 10000, reduces by 100 for each point difference
        if (fluxMultiplier < 0) fluxMultiplier = 0;
        rawYield = (rawYield * fluxMultiplier) / 10000; // Apply as a percentage out of 10000

        // Reputation bonus
        uint256 effectiveRep = _calculateEffectiveReputation(staker);
        uint256 repBonus = (rawYield * effectiveRep * reputationEffects.yieldBonusPercentage) / 10000; // Use 10000 for 100% precision
        uint256 totalYield = rawYield + repBonus;

        // Energy influence (example: yield scales with current energy percentage)
        uint256 currentEnergy = getCurrentEnergy(tokenId);
        uint256 energyPercentage = attrs.baseEnergy > 0 ? (currentEnergy * 10000) / attrs.baseEnergy : 0;
        totalYield = (totalYield * energyPercentage) / 10000; // Scale yield by energy %

        return totalYield; // This is yield per second
    }

    /**
     * @dev Calculates the effective ChronoCrystal yield rate per second per token for staked crystals.
     *      Yield depends on temporal flux and user reputation.
     * @param staker The address of the staker.
     * @return The yield rate in ChronoCrystals per second per staked token.
     */
    function calculateCrystalStakingYield(address staker) public view returns (uint256) {
        require(_stakedCrystals[staker] > 0, "User has no crystals staked");

        uint256 rawYieldPerToken = baseYields.crystalYieldPerSecPerToken;

        // Flux influence (example: some global multiplier based on flux)
        uint256 fluxMultiplier = 10000 + (_temporalFlux * 10); // Simple example: higher flux is better
        rawYieldPerToken = (rawYieldPerToken * fluxMultiplier) / 10000;

        // Reputation bonus
        uint256 effectiveRep = _calculateEffectiveReputation(staker);
        uint256 repBonus = (rawYieldPerToken * effectiveRep * reputationEffects.yieldBonusPercentage) / 10000;
        uint256 totalYieldPerToken = rawYieldPerToken + repBonus;

        return totalYieldPerToken; // This is yield per second per token staked
    }

    /**
     * @dev Calculates the total accrued ChronoCrystal rewards for a user's staked artifacts.
     * @param staker The address of the staker.
     * @return The total amount of pending rewards.
     */
    function _calculateAccruedArtifactRewards(address staker) internal view returns (uint256) {
        uint256 startTime = _artifactStakingStartTime[staker];
        if (startTime == 0) {
            return 0; // No staking started or currently active
        }

        uint256 timeElapsed = block.timestamp - startTime;
        if (timeElapsed == 0) {
            return 0; // No time has passed since last check/stake
        }

        uint256 totalYieldPerSecForUser = 0;
         // Iterate through all tokens globally (expensive for large number of tokens)
         // In a real system, you'd need a more efficient way to track staked tokens per user.
         // For this example, we iterate global list and check who staked it.
         // NOTE: This global iteration is very inefficient and gas-costly for many artifacts.
         // A better approach involves mapping staker => list of staked tokenIds.
        for (uint256 i = 0; i < _allTokens.length; i++) {
             uint256 tokenId = _allTokens[i];
             if (_stakedArtifacts[tokenId] == staker) {
                 // Must update state conceptually for yield calculation
                 // In view function, we simulate the update without state change
                 ArtifactAttributes memory attrs = _artifactAttributes[tokenId];
                 if (getArtifactState(tokenId) != ArtifactState.Decaying) {
                      totalYieldPerSecForUser += calculateArtifactStakingYield(tokenId);
                 }
             }
        }

        uint256 totalPossibleEarned = totalYieldPerSecForUser * timeElapsed;

        // Subtract already claimed rewards
        uint256 totalClaimed = _artifactStakingRewardsClaimed[staker];
        return totalPossibleEarned > totalClaimed ? totalPossibleEarned - totalClaimed : 0;
    }

     /**
     * @dev Calculates the total accrued ChronoCrystal rewards for a user's staked crystals.
     * @param staker The address of the staker.
     * @return The total amount of pending rewards.
     */
    function _calculateAccruedCrystalRewards(address staker) internal view returns (uint256) {
        uint256 startTime = _crystalStakingStartTime[staker];
        uint256 stakedAmount = _stakedCrystals[staker];
        if (startTime == 0 || stakedAmount == 0) {
            return 0; // No staking started or currently active
        }

        uint256 timeElapsed = block.timestamp - startTime;
        if (timeElapsed == 0) {
            return 0; // No time has passed since last check/stake
        }

        uint256 yieldPerSecPerToken = calculateCrystalStakingYield(staker);
        uint256 totalPossibleEarned = (yieldPerSecPerToken * stakedAmount * timeElapsed) / 1e18; // Adjust for token decimals

        uint256 totalClaimed = _crystalStakingRewardsClaimed[staker];
        return totalPossibleEarned > totalClaimed ? totalPossibleEarned - totalClaimed : 0;
    }


    /**
     * @dev Calculates the base yield for an artifact based on its level and base yield settings.
     * @param tokenId The ID of the artifact.
     * @return The raw base yield per second.
     */
    function _calculateArtifactRawYield(uint256 tokenId) internal view returns (uint256) {
        ArtifactAttributes memory attrs = _artifactAttributes[tokenId];
        // Example: Yield scales linearly with level
        return baseYields.artifactYieldPerSec * attrs.level;
    }

     /**
     * @dev Calculates the effective reputation of a user, possibly capped or weighted.
     * @param user The address of the user.
     * @return The effective reputation score.
     */
    function _calculateEffectiveReputation(address user) internal view returns (uint256) {
        // Simple example: raw reputation score
        return _userReputation[user];
        // Could add capping: return _userReputation[user] > 100 ? 100 : _userReputation[user];
    }

    /**
     * @dev Applies reputation-based cost reduction.
     * @param cost The base cost.
     * @param user The user's address.
     * @return The effective cost after reduction.
     */
    function _applyCostReduction(uint256 cost, address user) internal view returns (uint256) {
        uint256 effectiveRep = _calculateEffectiveReputation(user);
        uint256 reduction = (cost * effectiveRep * reputationEffects.costReductionPercentage) / 10000;
        return cost > reduction ? cost - reduction : 0;
    }

     /**
     * @dev Updates a user's reputation score.
     * @param user The address of the user.
     * @param newReputation The new reputation value.
     */
    function _updateUserReputation(address user, uint256 newReputation) internal {
        uint256 oldReputation = _userReputation[user];
        if (oldReputation != newReputation) {
            _userReputation[user] = newReputation;
            emit ReputationUpdate(user, oldReputation, newReputation);
        }
    }

    // --- View Functions ---

    function getTemporalFlux() public view returns (uint256) {
        return _temporalFlux;
    }

    function getArtifactAttributes(uint256 tokenId) public view returns (ArtifactAttributes memory) {
        require(_owners[tokenId] != address(0) || _stakedArtifacts[tokenId] != address(0), "Artifact does not exist or is not owned/staked");
        return _artifactAttributes[tokenId];
    }

    function getUserReputation(address user) public view returns (uint256) {
        return _userReputation[user];
    }

    function isArtifactStaked(uint256 tokenId) public view returns (bool) {
         return _stakedArtifacts[tokenId] != address(0);
    }

    function getUserArtifactStake(uint256 tokenId) public view returns (address staker) {
         return _stakedArtifacts[tokenId];
    }

    function getUserCrystalStake(address staker) public view returns (uint256 amount) {
         return _stakedCrystals[staker];
    }

     function getBaseCosts() public view returns (BaseCosts memory) {
         return baseCosts;
     }

     function getBaseYields() public view returns (BaseYields memory) {
         return baseYields;
     }

     function getReputationEffects() public view returns (ReputationEffects memory) {
         return reputationEffects;
     }

    function getTotalCrystalsStaked() public view returns (uint256) {
        return _totalCrystalsStaked;
    }

    function getTotalArtifactsStaked() public view returns (uint256) {
        return _totalArtifactsStaked;
    }

    function getArtifactLastStateUpdateTime(uint256 tokenId) public view returns (uint256) {
         require(_owners[tokenId] != address(0) || _stakedArtifacts[tokenId] != address(0), "Artifact does not exist or is not owned/staked");
         return _artifactAttributes[tokenId].lastStateUpdateTime;
    }

    // --- Admin Functions ---

    /**
     * @dev Admin function to mint ChronoCrystals. Use cautiously.
     * @param account The address to mint to.
     * @param amount The amount to mint.
     */
    function adminMintCrystals(address account, uint256 amount) external onlyOwner whenNotPaused {
        _mintERC20(account, amount);
    }

    /**
     * @dev Admin function to burn a Forged Artifact. Use cautiously.
     * @param tokenId The ID of the artifact to burn.
     */
    function adminBurnArtifact(uint256 tokenId) external onlyOwner whenNotPaused {
        _burnERC721(tokenId);
    }

     /**
     * @dev Admin function to set a user's reputation manually. Use cautiously.
     * @param user The address of the user.
     * @param reputation The new reputation value.
     */
    function adminSetReputation(address user, uint256 reputation) external onlyOwner {
        _updateUserReputation(user, reputation);
    }

    /**
     * @dev Admin function to update base costs.
     * @param newCosts The new BaseCosts struct.
     */
    function setBaseCosts(BaseCosts memory newCosts) external onlyOwner {
        baseCosts = newCosts;
        emit CostsUpdated(newCosts);
    }

     /**
     * @dev Admin function to update base yields.
     * @param newYields The new BaseYields struct.
     */
    function setBaseYields(BaseYields memory newYields) external onlyOwner {
        baseYields = newYields;
        emit YieldsUpdated(newYields);
    }

     /**
     * @dev Admin function to update reputation effects.
     * @param newEffects The new ReputationEffects struct.
     */
    function setReputationEffects(ReputationEffects memory newEffects) external onlyOwner {
        reputationEffects = newEffects;
        emit ReputationEffectsUpdated(newEffects);
    }
}
```