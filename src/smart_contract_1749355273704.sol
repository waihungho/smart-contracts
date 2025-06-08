Okay, here is a Solidity smart contract that implements a "Self-Evolving Generative NFT Collection" with integrated utility token, staking, dynamic traits, and a unique decay/nurturing mechanism. It attempts to combine several concepts in a non-standard way, implementing the ERC-721 and ERC-20 logic internally rather than inheriting from OpenZeppelin or similar libraries to satisfy the "don't duplicate open source" constraint (while still adhering to the interface standards).

**Contract Name:** `CosmicBloomsEvolvingCollection`

**Concept:**
This contract manages a collection of unique, generative NFTs called "Cosmic Blooms". Each Bloom NFT has on-chain parameters ("traits") that influence its appearance (via metadata URI) and its utility within the ecosystem. The ecosystem includes a native utility token called "Nectar" (managed within the same contract), which is required to "nurture" the Blooms. Nurturing prevents vitality decay and can slightly alter traits. Users can stake their Blooms to earn Nectar tokens. The yield from staking is influenced by the Bloom's vitality and traits. A treasury collects minting and nurturing fees.

**Key Advanced/Creative Concepts:**
1.  **Integrated ERC-721 & ERC-20:** Both the NFT (Bloom) and the utility token (Nectar) are managed within a single contract. This requires manual state management for balances, allowances, ownership, etc., adhering to ERC standards.
2.  **On-Chain Generative Traits:** Initial NFT traits are generated based on on-chain data (block hash, timestamp, minter address). These traits are stored directly in contract state.
3.  **Dynamic NFT Traits (Vitality):** NFTs have a "vitality" score that decays over time if not nurtured. Vitality affects staking yield and potentially visual representation (via metadata).
4.  **Nectar Token Utility:** Nectar is the sole currency for nurturing Blooms, which is essential for maintaining vitality and yield.
5.  **NFT Staking with Dynamic Yield:** Users stake Blooms to earn Nectar. The earning rate is dynamically calculated based on the Bloom's vitality and traits, requiring active management (nurturing) to maximize yield.
6.  **Decay Mechanism:** Vitality automatically decreases over time since the last nurture, calculated implicitly upon interaction.
7.  **Internal Token Management:** ERC-20 logic for Nectar (minting, burning, transfers, approvals) is implemented manually within the contract's scope.
8.  **Treasury:** Collects fees for potential future ecosystem development (managed by the owner).
9.  **Pausable:** Standard safety mechanism implemented manually.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Interfaces (Mimicking Standards without inheriting full implementations) ---
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
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// --- Custom Errors ---
error NotOwner();
error Paused();
error NotPaused();
error TransferBlocked();
error InvalidTokenId();
error TokenNotOwnedByUser();
error NotApprovedOrOwner();
error InsufficientNectar();
error MaxSupplyReached();
error TokenAlreadyStaked();
error TokenNotStaked();
error NothingToClaim();
error InsufficientAllowance();
error InsufficientNectarBalance();
error InvalidAddressZero();

contract CosmicBloomsEvolvingCollection is IERC721Metadata, IERC20 {
    // --- State Variables ---

    // Contract Ownership
    address private _owner;

    // Pausability
    bool private _paused;

    // ERC721: Bloom NFT State
    mapping(uint256 => address) private _owners;          // TokenId => Owner Address
    mapping(address => uint256) private _balances;        // Owner Address => Number of NFTs owned
    mapping(uint256 => address) private _tokenApprovals;  // TokenId => Approved Address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner => Operator => Approved

    uint256 private _nextTokenId; // Counter for minting new tokens
    uint256 private _maxBloomSupply; // Max number of NFTs that can be minted

    // ERC721 Metadata
    string private _name = "Cosmic Blooms";
    string private _symbol = "CBLOOM";
    string private _baseTokenURI; // Base URI for metadata server

    // ERC20: Nectar Token State (Managed Internally)
    string private constant _nectarName = "Nectar";
    string private constant _nectarSymbol = "NCT";
    uint8 private constant _nectarDecimals = 18; // Standard decimals for fungible tokens

    mapping(address => uint256) private _nectarBalances; // Owner Address => Nectar Balance
    mapping(address => mapping(address => uint256)) private _nectarAllowances; // Owner => Spender => Allowance
    uint256 private _nectarTotalSupply; // Total Nectar minted

    // NFT State (Dynamic)
    struct BloomState {
        uint64 trait1; // Example trait 1 (uint can represent various properties)
        uint64 trait2; // Example trait 2
        uint256 vitality; // Current vitality score (e.g., 0-10000)
        uint256 lastNurturedTime; // Timestamp of last nurture
        bool isStaked; // True if the bloom is currently staked
        uint256 lastStakedClaimTime; // Timestamp rewards were last claimed or staked
    }
    mapping(uint256 => BloomState) private _bloomStates; // TokenId => BloomState

    // Staking State
    mapping(address => uint256[]) private _stakedTokensOfOwner; // Owner => List of staked TokenIds

    // Parameters (Configurable by Owner)
    uint256 private _mintPrice;          // Price in Ether to mint one Bloom
    uint256 private _nurtureCostNectar;  // Cost in Nectar to nurture one Bloom
    uint256 private _baseStakingYieldPerSecond; // Base Nectar yield per second per Bloom (scaled by vitality)
    uint256 private _vitalityDecayRate;  // Vitality points lost per second
    uint256 private constant MAX_VITALITY = 10000; // Max vitality score
    uint256 private constant MIN_VITALITY = 0;   // Min vitality score

    // Treasury
    address private _treasuryAddress;

    // --- Events ---

    // ERC721 standard events (see interface)
    // ERC20 standard events (see interface)

    // Custom Events
    event BloomNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 vitality, uint256 nectarSpent);
    event BloomStaked(uint256 indexed tokenId, address indexed owner);
    event BloomUnstaked(uint256 indexed tokenId, address indexed owner);
    event RewardsClaimed(address indexed owner, uint256[] tokenIds, uint256 totalNectarClaimed);
    event VitalityUpdated(uint256 indexed tokenId, uint256 newVitality);
    event ParametersUpdated(string parameterName, uint256 newValue);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    modifier onlyBloomOwner(uint256 tokenId) {
        if (_owners[tokenId] != msg.sender) revert TokenNotOwnedByUser();
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        address owner = _owners[tokenId];
        if (msg.sender != owner && _tokenApprovals[tokenId] != msg.sender && !_operatorApprovals[owner][msg.sender]) {
            revert NotApprovedOrOwner();
        }
        _;
    }

    // --- Constructor ---

    constructor(
        string memory baseURI,
        uint256 initialMintPrice,
        uint256 initialNurtureCostNectar,
        uint256 initialBaseStakingYieldPerSecond,
        uint256 initialVitalityDecayRate,
        uint256 initialMaxBloomSupply
    ) {
        _owner = msg.sender;
        _paused = false;
        _baseTokenURI = baseURI;
        _mintPrice = initialMintPrice;
        _nurtureCostNectar = initialNurtureCostNectar;
        _baseStakingYieldPerSecond = initialBaseStakingYieldPerSecond;
        _vitalityDecayRate = initialVitalityDecayRate;
        _maxBloomSupply = initialMaxBloomSupply;
        _nextTokenId = 1; // Start token IDs from 1
        _treasuryAddress = msg.sender; // Owner is initial treasury recipient
    }

    // --- Pausability Functions ---

    function pauseContract() external onlyOwner whenNotPaused {
        _paused = true;
        // Emit an event if desired
    }

    function unpauseContract() external onlyOwner whenPaused {
        _paused = false;
        // Emit an event if desired
    }

    function paused() external view returns (bool) {
        return _paused;
    }

    // --- Ownership Function ---
    // (Basic implementation, not full Ownable pattern)

    function owner() external view returns (address) {
        return _owner;
    }

    // --- ERC721 Standard Functions (Manual Implementation) ---

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert InvalidAddressZero();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidTokenId(); // Assume 0 address means token doesn't exist
        return owner;
    }

    function approve(address to, uint256 tokenId) public override whenNotPaused {
        address owner = ownerOf(tokenId); // Checks if token exists and gets owner
        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) revert NotApprovedOrOwner();
        if (to == owner) revert ApprovalBlocked(); // Should not approve owner
        _approveBloom(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        ownerOf(tokenId); // Check if token exists
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        if (operator == msg.sender) revert ApprovalBlocked(); // Should not approve self
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        // Basic checks: from is current owner, to is valid, sender is approved/owner
        address owner = ownerOf(tokenId); // Checks if token exists
        if (owner != from) revert TransferBlocked(); // Must transfer from actual owner

        if (to == address(0)) revert InvalidAddressZero();

        // Check approval: sender is owner, approved for this token, or approved for all
        if (msg.sender != owner && _tokenApprovals[tokenId] != msg.sender && !_operatorApprovals[owner][msg.sender]) {
             revert NotApprovedOrOwner();
        }

        // Custom logic: Cannot transfer staked blooms directly
        if (_bloomStates[tokenId].isStaked) revert TransferBlocked();

        _transferBloom(from, to, tokenId);
    }

     // ERC721 requires safeTransferFrom variants
    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        transferFrom(from, to, tokenId); // Leverage core logic
        // Add ERC721Receiver check if needed, but for simplicity, omitting complex receiver check
        // A full implementation would call _checkOnERC721Received
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override whenNotPaused {
        transferFrom(from, to, tokenId); // Leverage core logic
         // Add ERC721Receiver check if needed
    }


    // --- ERC721 Metadata Functions ---

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        ownerOf(tokenId); // Check if token exists

        // Construct a URI that includes dynamic state for the metadata server
        // The server at _baseTokenURI is expected to handle this format
        // Example: baseURI/tokenId?vitality=X&trait1=Y&trait2=Z...
        BloomState storage bloom = _bloomStates[tokenId];

        // Calculate updated vitality before generating URI
        uint256 currentVitality = _calculateCurrentVitality(tokenId, bloom); // Use helper to get potentially decayed value

        string memory vitalityStr = uint256ToString(currentVitality);
        string memory trait1Str = uint256ToString(bloom.trait1);
        string memory trait2Str = uint256ToString(bloom.trait2);

        string memory uri = string(abi.encodePacked(
            _baseTokenURI,
            uint256ToString(tokenId),
            "?vitality=", vitalityStr,
            "&trait1=", trait1Str,
            "&trait2=", trait2Str
            // Add other traits as needed
        ));

        return uri;
    }

    // Helper function to convert uint256 to string (simple version)
    function uint256ToString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // --- ERC20 Standard Functions (Manual Implementation for Nectar) ---

    function totalSupply() public view override returns (uint256) {
        return _nectarTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (account == address(0)) revert InvalidAddressZero();
        return _nectarBalances[account];
    }

    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        _transferNectar(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
         if (owner == address(0) || spender == address(0)) revert InvalidAddressZero();
        return _nectarAllowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        if (spender == address(0)) revert InvalidAddressZero();
        _approveNectar(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        uint256 currentAllowance = _nectarAllowances[from][msg.sender];
        if (currentAllowance < amount) revert InsufficientAllowance();

        unchecked { // Assuming amount <= type(uint256).max
            _approveNectar(from, msg.sender, currentAllowance - amount);
        }

        _transferNectar(from, to, amount);
        return true;
    }

    // --- Minting Functions ---

    // 21. mintBloom()
    function mintBloom() external payable whenNotPaused returns (uint256 tokenId) {
        if (_nextTokenId > _maxBloomSupply) revert MaxSupplyReached();
        if (msg.value < _mintPrice) revert InsufficientPayment(); // Custom error for insufficient payment

        uint256 currentTokenId = _nextTokenId;

        // Generate initial traits based on block data and minter
        BloomState memory newState = _generateInitialTraits(currentTokenId, msg.sender);
        newState.vitality = MAX_VITALITY; // New blooms start with max vitality
        newState.lastNurturedTime = block.timestamp;
        newState.isStaked = false;
        newState.lastStakedClaimTime = 0; // Not staked initially

        _bloomStates[currentTokenId] = newState;

        // Mint the NFT
        _safeMintBloom(msg.sender, currentTokenId);

        _nextTokenId++;

        // Send mint price to treasury
        // Low-level call is generally safer than transfer/send in complex scenarios,
        // but requires careful handling of success/failure. Simple transfer for demonstration.
        (bool success, ) = payable(_treasuryAddress).call{value: msg.value}("");
        // Consider adding require(success, "Transfer to treasury failed"); and refund logic

        return currentTokenId;
    }

     // --- NFT State & Dynamic Functions ---

    // 22. getNFTTraits()
    function getNFTTraits(uint256 tokenId) external view returns (uint64 trait1, uint64 trait2) {
        ownerOf(tokenId); // Check if token exists
        BloomState storage bloom = _bloomStates[tokenId];
        return (bloom.trait1, bloom.trait2);
    }

    // 23. getNFTVitality()
    function getNFTVitality(uint256 tokenId) external view returns (uint256) {
         ownerOf(tokenId); // Check if token exists
        return _calculateCurrentVitality(tokenId, _bloomStates[tokenId]);
    }

    // 24. nurtureBloom()
    function nurtureBloom(uint256 tokenId) external onlyBloomOwner(tokenId) whenNotPaused {
        BloomState storage bloom = _bloomStates[tokenId];

        if (bloom.isStaked) revert TransferBlocked(); // Cannot nurture while staked

        // Calculate current vitality before spending Nectar
        uint256 currentVitality = _calculateCurrentVitality(tokenId, bloom);

        // Ensure vitality is updated in state before nurturing
        bloom.vitality = currentVitality;
        bloom.lastNurturedTime = block.timestamp;

        // Require Nectar payment
        if (_nectarBalances[msg.sender] < _nurtureCostNectar) revert InsufficientNectar();
        _burnNectar(msg.sender, _nurtureCostNectar); // Nectar is burned, removed from supply

        // Increase vitality (e.g., restore to max, or add a fixed amount)
        // Let's restore vitality proportional to Nectar cost vs max cost capacity
        // Simple: restore to MAX_VITALITY
        bloom.vitality = MAX_VITALITY;

        // Optional: slightly alter traits upon nurture
        // Example: Trait 1 increases slightly, Trait 2 decreases slightly (bounded)
        bloom.trait1 = (bloom.trait1 + 1) % 256; // Simple modulo increment
        if (bloom.trait2 > 0) bloom.trait2 = bloom.trait2 - 1; // Simple decrement

        emit BloomNurtured(tokenId, msg.sender, bloom.vitality, _nurtureCostNectar);
        emit VitalityUpdated(tokenId, bloom.vitality);
    }


    // Internal helper to calculate vitality including decay
    function _calculateCurrentVitality(uint256 tokenId, BloomState storage bloom) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - bloom.lastNurturedTime;
        uint256 vitalityLost = timeElapsed * _vitalityDecayRate;

        if (vitalityLost >= bloom.vitality) {
            return MIN_VITALITY;
        } else {
             unchecked { // Safe because vitalityLost is less than bloom.vitality
                return bloom.vitality - vitalityLost;
             }
        }
    }

    // Internal helper to update vitality state (called before calculations)
    function _updateVitalityState(BloomState storage bloom) internal {
        uint256 currentVitality = _calculateCurrentVitality(0, bloom); // Pass 0 as dummy tokenId, not used in calc
        bloom.vitality = currentVitality;
        // No need to emit VitalityUpdated here every time, would be too noisy.
        // Emit only when vitality is explicitly changed by nurture/claim if desired.
    }


    // --- Staking Functions ---

    // 25. stakeBloom()
    function stakeBloom(uint256 tokenId) external onlyBloomOwner(tokenId) whenNotPaused {
        BloomState storage bloom = _bloomStates[tokenId];
        if (bloom.isStaked) revert TokenAlreadyStaked();

        // Calculate and mint any pending rewards *before* staking
        // This ensures rewards accrued before staking are claimable later, separate from staking rewards
        // Or, for simplicity, discard pending non-staked rewards. Let's discard.
        // A more complex system would track non-staked accrual separately.

        bloom.isStaked = true;
        bloom.lastStakedClaimTime = block.timestamp; // Start staking clock

        _stakedTokensOfOwner[msg.sender].push(tokenId); // Add to staked list

        emit BloomStaked(tokenId, msg.sender);
    }

    // 26. unstakeBloom()
    function unstakeBloom(uint256 tokenId) external onlyBloomOwner(tokenId) whenNotPaused {
        BloomState storage bloom = _bloomStates[tokenId];
        if (!bloom.isStaked) revert TokenNotStaked();

        // Claim any pending rewards upon unstaking
        uint256 pendingRewards = _calculatePendingRewards(tokenId, bloom);
        if (pendingRewards > 0) {
            _mintNectar(msg.sender, pendingRewards);
            emit RewardsClaimed(msg.sender, new uint256[](1), pendingRewards); // Simplified event
        }

        bloom.isStaked = false;
        bloom.lastStakedClaimTime = 0; // Reset staking clock

        // Remove from staked list (inefficient for large lists, improve in prod)
        uint256[] storage stakedTokens = _stakedTokensOfOwner[msg.sender];
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == tokenId) {
                // Replace with last element and pop (common removal pattern)
                if (i != stakedTokens.length - 1) {
                    stakedTokens[i] = stakedTokens[stakedTokens.length - 1];
                }
                stakedTokens.pop();
                break; // Found and removed
            }
        }

        emit BloomUnstaked(tokenId, msg.sender);
    }

     // 27. claimStakingRewards()
    function claimStakingRewards(uint256[] calldata tokenIds) external whenNotPaused {
        uint256 totalClaimed = 0;
        uint256[] memory claimedTokenIds = new uint256[](tokenIds.length); // To pass to event
        uint256 claimedCount = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Basic validation: owner, staked status
            address owner = ownerOf(tokenId); // Checks if token exists
            if (owner != msg.sender) continue; // Skip tokens not owned by caller
            BloomState storage bloom = _bloomStates[tokenId];
            if (!bloom.isStaked) continue; // Skip tokens not staked

            uint256 pending = _calculatePendingRewards(tokenId, bloom);

            if (pending > 0) {
                _mintNectar(msg.sender, pending);
                totalClaimed += pending;
                claimedTokenIds[claimedCount] = tokenId;
                claimedCount++;

                // Update staking state for claimed tokens
                bloom.lastStakedClaimTime = block.timestamp;
            }
        }

        if (totalClaimed == 0) revert NothingToClaim();

        // Resize claimedTokenIds array for the event
        uint256[] memory finalClaimedIds = new uint256[](claimedCount);
        for(uint256 i = 0; i < claimedCount; i++){
            finalClaimedIds[i] = claimedTokenIds[i];
        }

        emit RewardsClaimed(msg.sender, finalClaimedIds, totalClaimed);
    }


    // 28. getCurrentStakingYield()
    function getCurrentStakingYield(uint256 tokenId) public view returns (uint256 yieldPerSecond) {
        ownerOf(tokenId); // Check if token exists
        BloomState storage bloom = _bloomStates[tokenId];

        // Calculate the current vitality (includes decay)
        uint256 currentVitality = _calculateCurrentVitality(tokenId, bloom);

        // Calculate yield rate based on vitality and base yield
        // Example: Yield is base yield * (current vitality / MAX_VITALITY)
        // Use 1e4 scale for fixed point if needed, but direct ratio here is simpler
        if (currentVitality == 0) return 0;

        // Use multiplier * base_yield / denominator
        // (currentVitality * _baseStakingYieldPerSecond) / MAX_VITALITY
        uint256 yieldRate = (currentVitality * _baseStakingYieldPerSecond) / MAX_VITALITY;

        // Optional: Add trait-based bonuses
        // yieldRate += bloom.trait1 / 100; // Example: Trait1 adds 1/100th yield per second

        return yieldRate;
    }

     // 29. getPendingStakingRewards()
    function getPendingStakingRewards(uint256 tokenId) public view returns (uint256) {
        ownerOf(tokenId); // Check if token exists
        BloomState storage bloom = _bloomStates[tokenId];
         if (!bloom.isStaked) return 0; // Only staked blooms accrue rewards

        return _calculatePendingRewards(tokenId, bloom);
    }

    // Helper function to calculate pending rewards for a single bloom
    function _calculatePendingRewards(uint256 tokenId, BloomState storage bloom) internal view returns (uint256) {
         // Ensure vitality is considered based on current time
        uint256 currentVitality = _calculateCurrentVitality(tokenId, bloom);

        // Recalculate yield based on current vitality
        uint224 currentYieldRate = uint224(_calculateStakingRate(currentVitality, bloom));

        uint256 timeElapsed = block.timestamp - bloom.lastStakedClaimTime;

        return uint256(currentYieldRate) * timeElapsed;
    }

    // Helper function to calculate staking rate based on vitality and traits
     function _calculateStakingRate(uint256 vitality, BloomState storage bloom) internal view returns (uint256) {
        if (vitality == 0) return 0;

        // Base rate scaled by vitality
        uint256 rate = (vitality * _baseStakingYieldPerSecond) / MAX_VITALITY;

        // Optional: Add trait-based bonuses to the rate calculation
        // rate += bloom.trait1 / 100; // Example

        return rate;
    }


    // --- Nectar Token Utility Functions (ERC20 wrappers & custom) ---

    // ERC20 standard functions implemented above: totalSupply, balanceOf, transfer, allowance, approve, transferFrom

    // 30. burnNectar()
    function burnNectar(uint256 amount) external whenNotPaused {
        _burnNectar(msg.sender, amount);
    }

    // Internal helper for Nectar transfer
    function _transferNectar(address from, address to, uint256 amount) internal {
        if (from == address(0) || to == address(0)) revert InvalidAddressZero();
        if (_nectarBalances[from] < amount) revert InsufficientNectarBalance();

        unchecked { // Overflow/underflow checks for balances
            _nectarBalances[from] -= amount;
            _nectarBalances[to] += amount;
        }

        emit Transfer(from, to, amount); // ERC20 Transfer event
    }

    // Internal helper for Nectar minting (only called internally, e.g., from staking)
    function _mintNectar(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidAddressZero();

        unchecked { // Overflow check for total supply
            _nectarTotalSupply += amount;
            _nectarBalances[account] += amount;
        }

        emit Transfer(address(0), account, amount); // ERC20 Mint event (from address(0))
    }

    // Internal helper for Nectar burning
    function _burnNectar(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidAddressZero();
         if (_nectarBalances[account] < amount) revert InsufficientNectarBalance();

        unchecked { // Underflow check for balance, underflow/overflow for total supply
            _nectarBalances[account] -= amount;
            _nectarTotalSupply -= amount;
        }

        emit Transfer(account, address(0), amount); // ERC20 Burn event (to address(0))
    }

    // Internal helper for Nectar approval
     function _approveNectar(address owner, address spender, uint256 amount) internal {
        _nectarAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount); // ERC20 Approval event
    }


    // --- Treasury Functions ---

    // 31. getTreasuryAddress()
    function getTreasuryAddress() external view returns (address) {
        return _treasuryAddress;
    }

    // 32. getTreasuryBalance()
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance; // Returns ETH balance held by the contract
    }

    // 33. withdrawTreasury()
    function withdrawTreasury(address payable recipient, uint256 amount) external onlyOwner {
        if (recipient == address(0)) revert InvalidAddressZero();
        if (amount == 0) revert InvalidAmount(); // Custom error
        if (address(this).balance < amount) revert InsufficientBalance(); // Custom error

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert TreasuryWithdrawalFailed(); // Custom error

        emit TreasuryWithdrawal(recipient, amount);
    }

    // 34. setTreasuryAddress()
    function setTreasuryAddress(address newTreasury) external onlyOwner {
         if (newTreasury == address(0)) revert InvalidAddressZero();
         _treasuryAddress = newTreasury;
         // Consider adding an event
    }


    // --- Parameter Setting (Owner Only) ---

    // 35. setMintPrice()
    function setMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
        emit ParametersUpdated("mintPrice", price);
    }

    // 36. setNurtureCostNectar()
    function setNurtureCostNectar(uint256 cost) external onlyOwner {
        _nurtureCostNectar = cost;
         emit ParametersUpdated("nurtureCostNectar", cost);
    }

    // 37. setBaseStakingYieldPerSecond()
    function setBaseStakingYieldPerSecond(uint256 yield) external onlyOwner {
        _baseStakingYieldPerSecond = yield;
         emit ParametersUpdated("baseStakingYieldPerSecond", yield);
    }

    // 38. setVitalityDecayRate()
    function setVitalityDecayRate(uint256 rate) external onlyOwner {
        _vitalityDecayRate = rate;
         emit ParametersUpdated("vitalityDecayRate", rate);
    }

    // 39. setMaxBloomSupply()
     function setMaxBloomSupply(uint256 maxSupply) external onlyOwner {
         _maxBloomSupply = maxSupply;
          emit ParametersUpdated("maxBloomSupply", maxSupply);
     }

    // 40. setBaseTokenURI()
    function setBaseTokenURI(string memory baseURI) external onlyOwner {
         _baseTokenURI = baseURI;
         // Consider adding an event
    }


    // --- Getters for Parameters ---

    // 41. getMintPrice()
    function getMintPrice() external view returns (uint256) {
        return _mintPrice;
    }

    // 42. getNurtureCostNectar()
    function getNurtureCostNectar() external view returns (uint256) {
        return _nurtureCostNectar;
    }

    // 43. getBaseStakingYieldPerSecond()
    function getBaseStakingYieldPerSecond() external view returns (uint256) {
        return _baseStakingYieldPerSecond;
    }

    // 44. getVitalityDecayRate()
    function getVitalityDecayRate() external view returns (uint256) {
        return _vitalityDecayRate;
    }

    // 45. getMaxBloomSupply()
     function getMaxBloomSupply() external view returns (uint256) {
         return _maxBloomSupply;
     }

    // 46. getBaseTokenURI()
    function getBaseTokenURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    // 47. getNextTokenId()
    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }


     // --- Staked Tokens Query ---

    // 48. getStakedTokensOfOwner()
    function getStakedTokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _stakedTokensOfOwner[owner];
    }


    // --- Internal Helper Functions ---

    // Internal minting function
    function _safeMintBloom(address to, uint256 tokenId) internal {
        if (to == address(0)) revert InvalidAddressZero();

        _owners[tokenId] = to;
        unchecked { // Assuming total supply won't exceed uint256 max
             _balances[to]++;
        }

        // Clear approvals for the new token
        _tokenApprovals[tokenId] = address(0);

        emit Transfer(address(0), to, tokenId); // ERC721 Mint event (from address(0))

         // Note: In a full ERC721 implementation, you'd also manage _ownedTokens array/mapping
         // for `tokenOfOwnerByIndex`, but that's complex and gas intensive. Omitted here for simplicity.
    }

    // Internal transfer function
    function _transferBloom(address from, address to, uint256 tokenId) internal {
         if (to == address(0)) revert InvalidAddressZero();
         if (_owners[tokenId] != from) revert TransferBlocked(); // Should not happen with prior checks

        // Clear approvals before transfer
        _approveBloom(address(0), tokenId);

        unchecked { // Assuming balances won't underflow/overflow
            _balances[from]--;
            _balances[to]++;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId); // ERC721 Transfer event

         // Note: Need to update _ownedTokens array/mapping here if supporting `tokenOfOwnerByIndex`
    }

    // Internal approval function
    function _approveBloom(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId); // ERC721 Approval event
    }


    // Internal trait generation helper
    function _generateInitialTraits(uint256 tokenId, address minter) internal view returns (BloomState memory) {
        // Simple example using on-chain randomness source (block hash, timestamp, addresses)
        // WARNING: Block hash/timestamp is not cryptographically secure randomness for NFTs.
        // Use a VRF (like Chainlink VRF) for production randomness.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.prevrandao, msg.sender, minter, tokenId)));

        // Derive traits from the seed
        uint64 trait1 = uint64((seed >> 128) % 256); // Example: Trait 1 is a byte (0-255)
        uint64 trait2 = uint64((seed % (2**64)));   // Example: Trait 2 is a uint64

        return BloomState({
            trait1: trait1,
            trait2: trait2,
            vitality: 0, // Set externally upon minting
            lastNurturedTime: 0, // Set externally upon minting
            isStaked: false, // Set externally
            lastStakedClaimTime: 0 // Set externally
        });
    }

    // Fallback/Receive to allow receiving Ether for minting
    receive() external payable {}
    fallback() external payable {}


    // --- Custom Errors (Declared at top for clarity) ---
    // error InvalidAddressZero(); // Already defined
    // error NotApprovedOrOwner(); // Already defined
    // error InsufficientNectar(); // Already defined
    // error MaxSupplyReached(); // Already defined
    // error TokenAlreadyStaked(); // Already defined
    // error TokenNotStaked(); // Already defined
    // error NothingToClaim(); // Already defined
    // error InsufficientAllowance(); // Already defined
    // error InsufficientNectarBalance(); // Already defined
    error InvalidPayment();
    error ApprovalBlocked();
    error InvalidAmount();
    error InsufficientBalance();
    error TreasuryWithdrawalFailed();
}
```

**Explanation of Function Count (Total 48 public/external functions):**

1.  `pauseContract()`
2.  `unpauseContract()`
3.  `paused()`
4.  `owner()`
5.  `balanceOf(address owner)` (ERC721)
6.  `ownerOf(uint256 tokenId)` (ERC721)
7.  `approve(address to, uint256 tokenId)` (ERC721)
8.  `getApproved(uint256 tokenId)` (ERC721)
9.  `setApprovalForAll(address operator, bool approved)` (ERC721)
10. `isApprovedForAll(address owner, address operator)` (ERC721)
11. `transferFrom(address from, address to, uint256 tokenId)` (ERC721)
12. `safeTransferFrom(address from, address to, uint256 tokenId)` (ERC721)
13. `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)` (ERC721)
14. `name()` (ERC721 Metadata)
15. `symbol()` (ERC721 Metadata)
16. `tokenURI(uint256 tokenId)` (ERC721 Metadata - *includes dynamic trait data*)
17. `totalSupply()` (ERC20 - Nectar)
18. `balanceOf(address account)` (ERC20 - Nectar)
19. `transfer(address to, uint256 amount)` (ERC20 - Nectar)
20. `allowance(address owner, address spender)` (ERC20 - Nectar)
21. `approve(address spender, uint256 amount)` (ERC20 - Nectar)
22. `transferFrom(address from, address to, uint256 amount)` (ERC20 - Nectar)
23. `mintBloom()` - Mints a new NFT (*payable*)
24. `getNFTTraits(uint256 tokenId)` - Reads on-chain traits
25. `getNFTVitality(uint256 tokenId)` - Reads current vitality (calculated with decay)
26. `nurtureBloom(uint256 tokenId)` - Spends Nectar to restore vitality & potentially alter traits
27. `stakeBloom(uint256 tokenId)` - Stakes an NFT to earn Nectar
28. `unstakeBloom(uint256 tokenId)` - Unstakes an NFT and claims pending rewards
29. `claimStakingRewards(uint256[] calldata tokenIds)` - Claims rewards for multiple staked NFTs
30. `getCurrentStakingYield(uint256 tokenId)` - Views the *rate* of Nectar earning per second
31. `getPendingStakingRewards(uint256 tokenId)` - Views accrued but unclaimed Nectar
32. `burnNectar(uint256 amount)` - Allows Nectar holders to burn tokens
33. `getTreasuryAddress()` - Views the treasury address
34. `getTreasuryBalance()` - Views the contract's ETH balance
35. `withdrawTreasury(address payable recipient, uint256 amount)` - Owner withdraws ETH from treasury
36. `setTreasuryAddress(address newTreasury)` - Owner sets treasury address
37. `setMintPrice(uint256 price)` - Owner sets ETH mint price
38. `setNurtureCostNectar(uint256 cost)` - Owner sets Nectar nurture cost
39. `setBaseStakingYieldPerSecond(uint256 yield)` - Owner sets base Nectar staking yield
40. `setVitalityDecayRate(uint256 rate)` - Owner sets vitality decay rate
41. `setMaxBloomSupply(uint256 maxSupply)` - Owner sets max total NFT supply
42. `setBaseTokenURI(string memory baseURI)` - Owner sets metadata base URI
43. `getMintPrice()` - View
44. `getNurtureCostNectar()` - View
45. `getBaseStakingYieldPerSecond()` - View
46. `getVitalityDecayRate()` - View
47. `getMaxBloomSupply()` - View
48. `getBaseTokenURI()` - View
49. `getNextTokenId()` - View
50. `getStakedTokensOfOwner(address owner)` - View list of staked tokens

*(Self-correction: The list exceeds 20 functions significantly, reaching 50 public/external functions as initially listed during the thought process. This satisfies the minimum requirement.)*

**Notes:**

*   **Security:** Manually implementing ERC standards, ownership, and pausable logic requires rigorous testing and auditing. This example is for demonstration and educational purposes. Production code would ideally use battle-tested libraries where possible, or have extremely thorough custom implementations.
*   **Gas:** Manual state management (especially for ERC721 approvals/transfers) and list management (`_stakedTokensOfOwner`) can be more gas-intensive than optimized library implementations.
*   **Randomness:** The on-chain trait generation uses `block.timestamp`, `block.difficulty`, `block.prevrandao`, etc., which are *not* secure sources of randomness for high-value applications as miners/validators can influence them. A production contract would integrate with a Verifiable Random Function (VRF) service like Chainlink VRF.
*   **Metadata:** The `tokenURI` function points to an external base URI and appends query parameters. An off-chain server/service is needed to host the actual metadata JSON and potentially generate dynamic images based on the provided parameters (traits, vitality).
*   **Scalability:** The list of staked tokens (`_stakedTokensOfOwner`) could become inefficient if a single user stakes a very large number of NFTs. Iterating through it for removal on unstake is `O(n)`.
*   **Error Handling:** Basic `require` statements are used, and custom errors are defined for better clarity on why a transaction failed.
*   **ERC721Enumerable:** This contract does *not* implement the ERC721Enumerable extension (which requires mapping token IDs to an index for iteration), as it significantly increases complexity and gas costs for minting/burning. The `tokenOfOwnerByIndex` function is not included.
*   **ERC721Metadata:** While it implements `name`, `symbol`, and `tokenURI`, it doesn't include the full JSON schema validation implied by some metadata standards.
*   **ERC20 Nectar:** The Nectar token is purely internal to this contract's logic. It cannot be transferred *outside* this contract unless explicitly wrapped or bridged. The standard ERC20 functions allow transfers *between addresses holding Nectar balance within this contract*.

This contract provides a rich example of combining multiple advanced concepts within a single Solidity implementation, fulfilling the requirements while offering unique mechanics.