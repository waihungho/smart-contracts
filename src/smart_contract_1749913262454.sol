Okay, here is a smart contract concept called "ChronoKey Forge". It aims to be interesting and relatively advanced by combining several concepts:

1.  **Time-Bound NFTs:** Keys with built-in expiry.
2.  **Fractionalization:** Breaking NFTs into fungible tokens *specific to that NFT ID*.
3.  **Per-NFT Fungible Tokens:** Each Key ID has its *own* associated ERC-20-like fungible token supply (Shards).
4.  **Assembly:** Reconstructing the NFT from its fractionalized parts.
5.  **Staking:** Staking the NFTs to potentially gain benefits (even if simple in this example).
6.  **Delegation:** Allowing temporary usage rights without full ownership transfer.
7.  **Dynamic State:** The Key's state (Active, Expired, Fractionalized, Staked) affects what operations are possible.
8.  **Conditional Operations:** Many functions depend on the Key's state and expiry.
9.  **Internal Fee Mechanism:** Fees on shard transfers.

This is not a standard ERC-721 or ERC-20 implementation copied directly, but rather a system that *uses the concepts* of NFTs and fungible tokens and adds layers of custom logic on top.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoKeyForge
 * @dev A smart contract system for managing time-bound, fractionalizable,
 *      stakable, and delegable non-fungible "ChronoKeys" with associated
 *      per-key fungible "ChronoShards".
 */

/*
 * CONTRACT OUTLINE:
 * 1. State Variables & Data Structures: Definitions for Keys, Shards, Staking, Delegation, Fees.
 * 2. Enums: Define possible states for a ChronoKey.
 * 3. Events: Announce key lifecycle, state changes, transfers, fractionalization, etc.
 * 4. Modifiers: Define conditions for function execution (e.g., only owner, only admin, key state).
 * 5. Constructor: Initialize contract owner and basic parameters.
 * 6. Access Control: Basic ownership pattern.
 * 7. Core Key Management: Minting, transfer, burning, getting key details.
 * 8. Fractionalization & Assembly: Converting Keys to Shards and vice versa.
 * 9. Shard Management (Per-Key ERC-20-like): Transferring and querying Shard balances and supply for specific Keys. Includes fee mechanism.
 * 10. Staking: Staking and unstaking active ChronoKeys.
 * 11. Delegation: Granting temporary usage rights for ChronoKeys.
 * 12. Parameters & Fees: Setting system parameters and managing fee withdrawal.
 * 13. View & Helper Functions: Read-only functions to query state and details.
 */

/*
 * FUNCTION SUMMARY:
 * - constructor(): Initializes the contract with an owner and sets initial parameters.
 * - setMintingParameters(): Admin function to set cost and default expiry duration for new keys.
 * - setFractionalizationParameters(): Admin function to set how many shards a key produces and required for assembly.
 * - setShardTransferFeeRate(): Admin function to set the percentage fee on shard transfers.
 * - setShardTransferFeeRecipient(): Admin function to set the address receiving shard transfer fees.
 * - mintChronoKey(uint256 _customExpiryDuration): Mints a new ChronoKey with a calculated expiry time.
 * - transferFrom(address _from, address _to, uint256 _tokenId): Transfers a ChronoKey (standard ERC721 logic, restricted by state).
 * - safeTransferFrom(address _from, address _to, uint256 _tokenId): Safe transfer of a ChronoKey (standard ERC721 logic, restricted by state).
 * - approve(address _approved, uint256 _tokenId): Approves an address to transfer a specific ChronoKey (standard ERC721 logic).
 * - setApprovalForAll(address _operator, bool _approved): Sets approval for an operator for all Keys (standard ERC721 logic).
 * - burnChronoKey(uint256 _tokenId): Burns/destroys a ChronoKey (restricted by state).
 * - fractionalizeKey(uint256 _tokenId): Breaks an active ChronoKey into its associated ChronoShards.
 * - assembleKeyFromShards(uint256 _tokenId): Reconstructs a ChronoKey by burning the required amount of its Shards.
 * - transferShards(uint256 _tokenId, address _to, uint256 _amount): Transfers ChronoShards for a specific Key ID between addresses, applying a fee.
 * - approveShards(uint256 _tokenId, address _spender, uint256 _amount): Approves a spender to transfer a specific amount of Shards for a Key ID.
 * - stakeKey(uint256 _tokenId): Stakes an active, non-fractionalized ChronoKey.
 * - unstakeKey(uint256 _tokenId): Unstakes a previously staked ChronoKey.
 * - delegateKeyUsage(uint256 _tokenId, address _delegatee, uint256 _duration): Delegates temporary usage rights of a Key without transferring ownership.
 * - revokeKeyUsageDelegation(uint256 _tokenId): Revokes an active delegation for a Key.
 * - withdrawFees(): Allows the designated fee recipient to withdraw accumulated shard transfer fees.
 * - getKeyDetails(uint256 _tokenId): View: Gets detailed information about a ChronoKey.
 * - isKeyActive(uint256 _tokenId): View: Checks if a ChronoKey is currently active (not expired, not fractionalized, not burned).
 * - getShardsPerKey(): View: Gets the current parameter for how many shards a key generates.
 * - getShardSupplyForSpecificKey(uint256 _tokenId): View: Gets the total supply of shards minted for a specific Key ID.
 * - balanceOfShards(uint256 _tokenId, address _owner): View: Gets the balance of shards for a specific Key ID owned by an address.
 * - allowanceShards(uint256 _tokenId, address _owner, address _spender): View: Gets the allowance of shards for a specific Key ID granted by owner to spender.
 * - getStakedKeyInfo(uint256 _tokenId): View: Gets staking information for a ChronoKey.
 * - getDelegatee(uint256 _tokenId): View: Gets the current delegatee and expiry for a ChronoKey.
 * - getKeyOwner(uint256 _tokenId): View: Gets the owner of a ChronoKey (standard ERC721 ownerOf logic).
 * - getTokenIdsByOwner(address _owner): View: Gets all ChronoKey IDs owned by an address (Note: potentially gas-intensive for large collections).
 * - canAssembleKey(uint256 _tokenId, address _assembler): View: Checks if an address has enough shards to assemble a Key.
 * - getRequiredShardsForAssembly(uint256 _tokenId): View: Gets the number of shards required to assemble a specific key.
 */

contract ChronoKeyForge {
    // --- State Variables & Data Structures ---

    address private _owner; // Admin address
    uint256 private _nextTokenId; // Counter for minting new keys

    // ChronoKey Data
    struct Key {
        address owner;
        uint256 mintTimestamp;
        uint256 expiryTimestamp;
        KeyState state;
        string metadataURI; // Optional: Link to off-chain metadata
        uint256 linkedShardSupply; // How many shards this key *would* represent/did represent
    }
    mapping(uint256 => Key) private _keys; // tokenId => Key data
    mapping(uint256 => address) private _tokenApprovals; // tokenId => approved address (ERC721-like)
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved (ERC721-like)
    mapping(address => uint256[]) private _ownedTokens; // owner => list of tokenIds (simple list, can be gas heavy for large lists)

    // ChronoShard Data (Per Key ID)
    // tokenId => owner => balance
    mapping(uint256 => mapping(address => uint256)) private _shardBalances;
    // tokenId => owner => spender => allowance
    mapping(uint256 => mapping(address => mapping(address => uint256))) private _shardAllowances;

    // Staking Data
    struct StakedKeyInfo {
        address staker;
        uint256 stakeTimestamp;
        bool isStaked;
    }
    mapping(uint256 => StakedKeyInfo) private _stakedKeys; // tokenId => staking data

    // Delegation Data (Usage rights, not ownership)
    struct KeyDelegation {
        address delegatee;
        uint256 expiryTimestamp;
    }
    mapping(uint256 => KeyDelegation) private _keyDelegations; // tokenId => delegation data

    // Parameters
    uint256 public mintingCost = 0.01 ether; // Cost to mint a key
    uint256 public defaultExpiryDuration = 365 days; // Default active duration for new keys
    uint256 public shardsPerKey = 1000; // How many shards one key represents
    uint256 public shardTransferFeeRate = 100; // Fee rate in basis points (100 = 1%)
    address public shardTransferFeeRecipient; // Address to receive fees
    uint256 public totalAccumulatedFees;

    // --- Enums ---

    enum KeyState {
        Active,
        Expired,
        Fractionalized,
        Staked,
        Burned
    }

    // --- Events ---

    event ChronoKeyMinted(uint256 indexed tokenId, address indexed owner, uint256 expiryTimestamp);
    event ChronoKeyTransfer(address indexed from, address indexed to, uint256 indexed tokenId); // ERC721-like
    event ChronoKeyApproval(address indexed owner, address indexed approved, uint256 indexed tokenId); // ERC721-like
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // ERC721-like
    event ChronoKeyBurned(uint256 indexed tokenId, address indexed owner);
    event ChronoKeyFractionalized(uint256 indexed tokenId, address indexed owner, uint256 shardSupply);
    event ChronoKeyAssembled(uint256 indexed tokenId, address indexed assembler, uint256 shardsBurned);
    event ChronoShardTransfer(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);
    event ChronoShardApproval(uint256 indexed tokenId, address indexed owner, address indexed spender, uint256 amount);
    event ChronoKeyStaked(uint256 indexed tokenId, address indexed staker, uint256 stakeTimestamp);
    event ChronoKeyUnstaked(uint256 indexed tokenId, address indexed staker, uint256 unstakeTimestamp);
    event ChronoKeyDelegated(uint256 indexed tokenId, address indexed owner, address indexed delegatee, uint256 expiryTimestamp);
    event ChronoKeyDelegationRevoked(uint256 indexed tokenId, address indexed owner, address indexed delegatee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event ShardFeeParametersUpdated(uint256 newRate, address newRecipient);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not contract owner");
        _;
    }

    modifier whenKeyExists(uint256 _tokenId) {
        require(_keys[_tokenId].owner != address(0), "Key does not exist");
        _;
    }

    modifier whenKeyActive(uint256 _tokenId) {
        require(isKeyActive(_tokenId), "Key not in active state");
        _;
    }

    modifier whenKeyFractionalized(uint256 _tokenId) {
        require(_keys[_tokenId].state == KeyState.Fractionalized, "Key not fractionalized");
        _;
    }

    modifier whenKeyStaked(uint256 _tokenId) {
        require(_keys[_tokenId].state == KeyState.Staked, "Key not staked");
        _;
    }

    modifier onlyKeyOwnerOrApprovedOrDelegatee(uint256 _tokenId) {
        require(
            _isApprovedOrOwner(msg.sender, _tokenId) || _isDelegatee(msg.sender, _tokenId),
            "Not owner, approved, or delegatee"
        );
        _;
    }

    modifier onlyKeyOwnerOrApproved(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not owner or approved");
        _;
    }


    // --- Constructor ---

    constructor(address initialOwner) {
        _owner = initialOwner;
        _nextTokenId = 1; // Start token IDs from 1
        shardTransferFeeRecipient = initialOwner; // Default fee recipient
    }

    // --- Access Control ---

    function owner() public view returns (address) {
        return _owner;
    }

    // (No explicit transfer ownership function for simplicity, but could add)

    // --- Parameters & Fees ---

    function setMintingParameters(uint256 _mintingCost, uint256 _defaultExpiryDuration) external onlyOwner {
        mintingCost = _mintingCost;
        defaultExpiryDuration = _defaultExpiryDuration;
    }

    function setFractionalizationParameters(uint256 _shardsPerKey) external onlyOwner {
        shardsPerKey = _shardsPerKey;
    }

    function setShardTransferFeeRate(uint256 _shardTransferFeeRate) external onlyOwner {
        require(_shardTransferFeeRate <= 10000, "Fee rate cannot exceed 100%"); // 10000 basis points
        shardTransferFeeRate = _shardTransferFeeRate;
    }

    function setShardTransferFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Recipient cannot be zero address");
        shardTransferFeeRecipient = _recipient;
        emit ShardFeeParametersUpdated(shardTransferFeeRate, _recipient);
    }

    function withdrawFees() external {
        require(msg.sender == shardTransferFeeRecipient, "Not fee recipient");
        uint256 amount = totalAccumulatedFees;
        totalAccumulatedFees = 0;
        (bool success, ) = payable(shardTransferFeeRecipient).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(shardTransferFeeRecipient, amount);
    }

    // --- Core Key Management ---

    function mintChronoKey(uint256 _customExpiryDuration) external payable {
        require(msg.value >= mintingCost, "Insufficient payment");

        uint256 tokenId = _nextTokenId++;
        uint256 expiry = block.timestamp + _customExpiryDuration;

        _keys[tokenId] = Key({
            owner: msg.sender,
            mintTimestamp: block.timestamp,
            expiryTimestamp: expiry,
            state: KeyState.Active,
            metadataURI: "", // Can be updated later
            linkedShardSupply: shardsPerKey // Store the parameter used at mint time
        });

        // Add token to owner's list (simple but potentially gas heavy)
        _ownedTokens[msg.sender].push(tokenId);

        emit ChronoKeyMinted(tokenId, msg.sender, expiry);

        // Refund excess payment if any
        if (msg.value > mintingCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - mintingCost}("");
            require(success, "Refund failed");
        }
    }

    // ERC721-like transfer functions, adapted for ChronoKey state
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenKeyExists(_tokenId)
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Transfer caller not owner or approved");
        require(_keys[_tokenId].owner == _from, "Transfer from incorrect owner");
        require(_to != address(0), "Transfer to zero address");
        // Allow transfer only if Active or Expired state
        require(
            _keys[_tokenId].state == KeyState.Active || _keys[_tokenId].state == KeyState.Expired,
            "Key not in transferable state (Active/Expired)"
        );

        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        // Simple implementation redirects to transferFrom, standard ERC721 requires receiver check
        transferFrom(_from, _to, _tokenId);
        // TODO: Implement ERC721Receiver check for production use
    }

    function approve(address _approved, uint256 _tokenId) external whenKeyExists(_tokenId) {
        address owner = _keys[_tokenId].owner;
        require(msg.sender == owner || _isApprovedForAll(owner, msg.sender), "Approval caller not owner or operator");
        _approve(_approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender, "Cannot approve self");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function burnChronoKey(uint256 _tokenId)
        external
        whenKeyExists(_tokenId)
        onlyKeyOwnerOrApproved(_tokenId)
    {
        Key storage key = _keys[_tokenId];
        address owner = key.owner;

        // Can only burn if Active or Expired state (not fractionalized or staked)
        require(
            key.state == KeyState.Active || key.state == KeyState.Expired,
            "Key not in burnable state (Active/Expired)"
        );

        // Clear approval
        _approve(address(0), _tokenId);

        // Update state and clear ownership info
        key.state = KeyState.Burned;
        key.owner = address(0); // Clear owner

        _removeTokenFromOwnerList(owner, _tokenId);

        emit ChronoKeyBurned(_tokenId, owner);
    }

    function getKeyDetails(uint256 _tokenId)
        external
        view
        whenKeyExists(_tokenId)
        returns (
            address owner,
            uint256 mintTimestamp,
            uint256 expiryTimestamp,
            KeyState state,
            string memory metadataURI,
            uint256 linkedShardSupply
        )
    {
        Key storage key = _keys[_tokenId];
        return (
            key.owner,
            key.mintTimestamp,
            key.expiryTimestamp,
            key.state,
            key.metadataURI,
            key.linkedShardSupply
        );
    }

    function isKeyActive(uint256 _tokenId) public view whenKeyExists(_tokenId) returns (bool) {
        Key storage key = _keys[_tokenId];
        return key.state == KeyState.Active && block.timestamp < key.expiryTimestamp;
    }

    // --- Fractionalization & Assembly ---

    function fractionalizeKey(uint256 _tokenId)
        external
        whenKeyExists(_tokenId)
        onlyKeyOwnerOrApprovedOrDelegatee(_tokenId)
        whenKeyActive(_tokenId) // Must be active to fractionalize
    {
        Key storage key = _keys[_tokenId];
        address owner = key.owner;

        require(key.state == KeyState.Active, "Key must be active to fractionalize");

        // Mint shards to the key owner
        uint256 amount = key.linkedShardSupply;
        _shardBalances[_tokenId][owner] += amount;

        // Update key state
        key.state = KeyState.Fractionalized;

        // Clear approvals and delegation for the key itself
        _approve(address(0), _tokenId);
        delete _keyDelegations[_tokenId];

        emit ChronoKeyFractionalized(_tokenId, owner, amount);
        emit ChronoShardTransfer(_tokenId, address(0), owner, amount); // Indicate minting
    }

    function assembleKeyFromShards(uint256 _tokenId)
        external
        whenKeyExists(_tokenId)
        whenKeyFractionalized(_tokenId) // Must be fractionalized to assemble
    {
        Key storage key = _keys[_tokenId];
        uint256 requiredShards = key.linkedShardSupply; // Use the linked supply from when it was fractionalized

        require(
            _shardBalances[_tokenId][msg.sender] >= requiredShards,
            "Not enough shards to assemble"
        );

        // Burn shards from the assembler
        _shardBalances[_tokenId][msg.sender] -= requiredShards;

        // Transfer key ownership to the assembler
        address currentOwner = key.owner; // Should be address(0) or previous owner conceptually, but contract state is Fractionalized
        key.owner = msg.sender; // Assembler becomes the new owner
        key.state = KeyState.Active; // Key becomes active again upon assembly

        // Update owned token lists (simple list approach)
        _removeTokenFromOwnerList(currentOwner, _tokenId); // Remove from old owner (if any conceptually)
        _ownedTokens[msg.sender].push(_tokenId); // Add to new owner

        emit ChronoKeyAssembled(_tokenId, msg.sender, requiredShards);
        emit ChronoKeyTransfer(currentOwner, msg.sender, _tokenId); // Signal ownership change
        emit ChronoShardTransfer(_tokenId, msg.sender, address(0), requiredShards); // Indicate burning
    }

    // --- Shard Management (Per-Key ERC-20-like) ---

    function transferShards(uint256 _tokenId, address _to, uint256 _amount)
        external
        whenKeyExists(_tokenId) // Shards only exist if Key exists
        returns (bool)
    {
        require(_to != address(0), "Transfer to zero address");
        require(_shardBalances[_tokenId][msg.sender] >= _amount, "Insufficient shard balance");

        // Calculate fee
        uint256 feeAmount = (_amount * shardTransferFeeRate) / 10000;
        uint256 amountAfterFee = _amount - feeAmount;

        // Perform transfers
        _shardBalances[_tokenId][msg.sender] -= _amount; // Deduct total amount (including fee)
        _shardBalances[_tokenId][_to] += amountAfterFee; // Send net amount to recipient
        if (feeAmount > 0) {
            _shardBalances[_tokenId][shardTransferFeeRecipient] += feeAmount; // Send fee to recipient
            totalAccumulatedFees += feeAmount; // Accumulate total contract fees
        }

        emit ChronoShardTransfer(_tokenId, msg.sender, _to, amountAfterFee);
        if (feeAmount > 0) {
             // Optional: emit a separate event for fee transfer
             emit ChronoShardTransfer(_tokenId, msg.sender, shardTransferFeeRecipient, feeAmount);
        }

        return true;
    }

    function transferShardsFrom(uint256 _tokenId, address _from, address _to, uint256 _amount)
        external
        whenKeyExists(_tokenId) // Shards only exist if Key exists
        returns (bool)
    {
        require(_to != address(0), "Transfer to zero address");
        require(_shardBalances[_tokenId][_from] >= _amount, "Insufficient shard balance");
        require(_shardAllowances[_tokenId][_from][msg.sender] >= _amount, "Insufficient shard allowance");

        // Calculate fee
        uint256 feeAmount = (_amount * shardTransferFeeRate) / 10000;
        uint256 amountAfterFee = _amount - feeAmount;

        // Update allowance
        _shardAllowances[_tokenId][_from][msg.sender] -= _amount;

        // Perform transfers
        _shardBalances[_tokenId][_from] -= _amount; // Deduct total amount (including fee)
        _shardBalances[_tokenId][_to] += amountAfterFee; // Send net amount to recipient
        if (feeAmount > 0) {
             _shardBalances[_tokenId][shardTransferFeeRecipient] += feeAmount; // Send fee to recipient
             totalAccumulatedFees += feeAmount; // Accumulate total contract fees
        }

        emit ChronoShardTransfer(_tokenId, _from, _to, amountAfterFee);
         if (feeAmount > 0) {
             // Optional: emit a separate event for fee transfer
             emit ChronoShardTransfer(_tokenId, _from, shardTransferFeeRecipient, feeAmount);
        }
        return true;
    }


    function approveShards(uint256 _tokenId, address _spender, uint256 _amount)
        external
        whenKeyExists(_tokenId) // Shards only exist if Key exists
        returns (bool)
    {
        _shardAllowances[_tokenId][msg.sender][_spender] = _amount;
        emit ChronoShardApproval(_tokenId, msg.sender, _spender, _amount);
        return true;
    }

    // --- Staking ---

    function stakeKey(uint256 _tokenId)
        external
        whenKeyExists(_tokenId)
        onlyKeyOwnerOrApprovedOrDelegatee(_tokenId)
        whenKeyActive(_tokenId) // Only active keys can be staked
    {
        Key storage key = _keys[_tokenId];
        require(key.state == KeyState.Active, "Key must be Active to stake");
        require(!_stakedKeys[_tokenId].isStaked, "Key is already staked");

        // Update key state
        key.state = KeyState.Staked;

        // Record staking info
        _stakedKeys[_tokenId] = StakedKeyInfo({
            staker: msg.sender, // The address initiating the stake
            stakeTimestamp: block.timestamp,
            isStaked: true
        });

        // Clear approvals and delegation for the key itself
        _approve(address(0), _tokenId);
         delete _keyDelegations[_tokenId];


        emit ChronoKeyStaked(_tokenId, msg.sender, block.timestamp);
    }

    function unstakeKey(uint256 _tokenId) external whenKeyExists(_tokenId) whenKeyStaked(_tokenId) {
         StakedKeyInfo storage stakeInfo = _stakedKeys[_tokenId];
         // Only the original staker or owner/approved/delegatee can unstake
         require(
             msg.sender == stakeInfo.staker || _isApprovedOrOwner(msg.sender, _tokenId) || _isDelegatee(msg.sender, _tokenId),
             "Not the staker, owner, approved, or delegatee"
         );

        Key storage key = _keys[_tokenId];

        // Check if key is still active based on original expiry, even if staked
        // If expired while staked, it unstakes into the Expired state
        if (block.timestamp >= key.expiryTimestamp) {
             key.state = KeyState.Expired;
        } else {
             key.state = KeyState.Active;
        }

        // Clear staking info
        delete _stakedKeys[_tokenId];

        emit ChronoKeyUnstaked(_tokenId, msg.sender, block.timestamp);

        // Note: Reward claiming logic would typically be here or in a separate function.
        // This contract does not implement complex reward calculations.
    }

    // --- Delegation ---

    function delegateKeyUsage(uint256 _tokenId, address _delegatee, uint256 _duration)
        external
        whenKeyExists(_tokenId)
        onlyKeyOwnerOrApproved(_tokenId) // Only owner or approved can delegate
        whenKeyActive(_tokenId) // Only active keys can be delegated
    {
        require(_delegatee != address(0), "Delegatee cannot be zero address");
        require(_duration > 0, "Delegation duration must be greater than zero");

        // Check that the key is in a state that allows delegation
        // Active keys can be delegated. Staked/Fractionalized cannot.
         require(
             _keys[_tokenId].state == KeyState.Active,
             "Key not in delegable state (Active)"
         );

        _keyDelegations[_tokenId] = KeyDelegation({
            delegatee: _delegatee,
            expiryTimestamp: block.timestamp + _duration
        });

        emit ChronoKeyDelegated(_tokenId, _keys[_tokenId].owner, _delegatee, _keyDelegations[_tokenId].expiryTimestamp);
    }

    function revokeKeyUsageDelegation(uint256 _tokenId)
        external
        whenKeyExists(_tokenId)
        onlyKeyOwnerOrApproved(_tokenId) // Only owner or approved can revoke
    {
        require(_keyDelegations[_tokenId].delegatee != address(0), "No active delegation for this key");
        address delegatee = _keyDelegations[_tokenId].delegatee;
        delete _keyDelegations[_tokenId]; // Revoke immediately
        emit ChronoKeyDelegationRevoked(_tokenId, _keys[_tokenId].owner, delegatee);
    }


    // --- View & Helper Functions ---

    function getKeyOwner(uint256 _tokenId) public view whenKeyExists(_tokenId) returns (address) {
        return _keys[_tokenId].owner;
    }

    function getShardsPerKey() public view returns (uint256) {
        return shardsPerKey;
    }

    function getShardSupplyForSpecificKey(uint256 _tokenId) public view whenKeyExists(_tokenId) returns (uint256) {
        // In this simplified model, the total supply for a specific key's shards
        // is the `linkedShardSupply` recorded when it was minted or fractionalized.
        // Balances are tracked in _shardBalances.
         return _keys[_tokenId].linkedShardSupply;
    }

    function balanceOfShards(uint256 _tokenId, address _owner)
        public
        view
        whenKeyExists(_tokenId) // Implies shards only exist if key does
        returns (uint256)
    {
        return _shardBalances[_tokenId][_owner];
    }

    function allowanceShards(uint256 _tokenId, address _owner, address _spender)
        public
        view
        whenKeyExists(_tokenId) // Implies allowances only exist if key does
        returns (uint256)
    {
        return _shardAllowances[_tokenId][_owner][_spender];
    }

    function getStakedKeyInfo(uint256 _tokenId)
        public
        view
        whenKeyExists(_tokenId)
        returns (address staker, uint256 stakeTimestamp, bool isStaked)
    {
        StakedKeyInfo storage info = _stakedKeys[_tokenId];
        return (info.staker, info.stakeTimestamp, info.isStaked);
    }

    function getDelegatee(uint256 _tokenId)
        public
        view
        whenKeyExists(_tokenId)
        returns (address delegatee, uint256 expiryTimestamp, bool isActive)
    {
        KeyDelegation storage delegation = _keyDelegations[_tokenId];
        bool active = (delegation.delegatee != address(0) && block.timestamp < delegation.expiryTimestamp);
        return (delegation.delegatee, delegation.expiryTimestamp, active);
    }

    function getTokenIdsByOwner(address _owner) external view returns (uint256[] memory) {
         // WARNING: This is a simple implementation and can be gas-intensive
         // if an owner has a very large number of tokens.
         // A more robust solution might involve pagination or external indexing.
        return _ownedTokens[_owner];
    }

     function canAssembleKey(uint256 _tokenId, address _assembler) public view whenKeyExists(_tokenId) returns (bool) {
         Key storage key = _keys[_tokenId];
         if (key.state != KeyState.Fractionalized) return false;
         uint256 requiredShards = key.linkedShardSupply;
         return _shardBalances[_tokenId][_assembler] >= requiredShards;
     }

     function getRequiredShardsForAssembly(uint256 _tokenId) public view whenKeyExists(_tokenId) returns (uint256) {
          return _keys[_tokenId].linkedShardSupply;
     }

    // --- Internal Helper Functions ---

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(_keys[_tokenId].owner == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), _tokenId); // Clear approval for the transferred token

        // Update ownership mappings
        _keys[_tokenId].owner = _to;
         _removeTokenFromOwnerList(_from, _tokenId);
         _ownedTokens[_to].push(_tokenId);

        emit ChronoKeyTransfer(_from, _to, _tokenId);
    }

    function _approve(address _approved, uint256 _tokenId) internal {
        _tokenApprovals[_tokenId] = _approved;
        emit ChronoKeyApproval(_keys[_tokenId].owner, _approved, _tokenId);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = _keys[_tokenId].owner;
        return (_spender == owner || _tokenApprovals[_tokenId] == _spender || _isApprovedForAll(owner, _spender));
    }

    function _isApprovedForAll(address _owner, address _operator) internal view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

     function _isDelegatee(address _addr, uint256 _tokenId) internal view returns (bool) {
         KeyDelegation storage delegation = _keyDelegations[_tokenId];
         return delegation.delegatee == _addr && block.timestamp < delegation.expiryTimestamp;
     }

    // Simple helper to remove token ID from an owner's list.
    // Note: Linear search, inefficient for large lists.
    function _removeTokenFromOwnerList(address _owner, uint256 _tokenId) internal {
        uint256[] storage tokenList = _ownedTokens[_owner];
        for (uint i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == _tokenId) {
                // Replace found token with the last token and shorten the array
                tokenList[i] = tokenList[tokenList.length - 1];
                tokenList.pop();
                break; // Token ID should only appear once per owner
            }
        }
    }
}
```