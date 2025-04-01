```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Programmable Badge System (DRPBS)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic reputation system with programmable NFT badges.
 *      Users earn reputation based on on-chain activities or external verification.
 *      Reputation tiers are defined, and users receive NFT badges representing their tier.
 *      Badges are programmable and can visually/functionally change based on reputation updates.
 *      This contract incorporates advanced concepts like:
 *          - Dynamic NFT metadata updates based on on-chain state.
 *          - Tiered reputation system with configurable thresholds.
 *          - Decentralized reputation awarding and revocation mechanisms.
 *          - Basic governance features for verifier management.
 *          - Simulated staking mechanism to boost reputation (demonstration).
 *          - Programmable badge URI generation based on reputation tier.
 *
 * Function Summary:
 * ----------------
 * **Admin Functions:**
 * 1.  `setAdmin(address _newAdmin)`: Changes the contract administrator.
 * 2.  `pauseContract()`: Pauses the contract, disabling most functions.
 * 3.  `unpauseContract()`: Resumes contract functionality.
 * 4.  `setBaseBadgeURI(string memory _baseURI)`: Sets the base URI for badge metadata.
 * 5.  `setDefaultBadgeMetadata(string memory _defaultMetadata)`: Sets default badge metadata for unassigned tiers.
 * 6.  `defineReputationTier(uint256 _tierId, uint256 _threshold, string memory _tierName)`: Defines a reputation tier with a threshold and name.
 * 7.  `updateReputationTierThreshold(uint256 _tierId, uint256 _newThreshold)`: Updates the reputation threshold for a tier.
 * 8.  `addVerifier(address _verifier)`: Adds an address authorized to award/revoke reputation.
 * 9.  `removeVerifier(address _verifier)`: Removes a verifier address.
 *
 * **Reputation Management Functions (Verifiers & Admin):**
 * 10. `awardReputation(address _user, uint256 _amount, string memory _reason)`: Awards reputation points to a user.
 * 11. `revokeReputation(address _user, uint256 _amount, string memory _reason)`: Revokes reputation points from a user.
 *
 * **User Functions:**
 * 12. `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 * 13. `getUserBadgeTier(address _user)`: Gets the current badge tier of a user based on reputation.
 * 14. `stakeForReputationBoost(uint256 _amount)`: Allows users to simulate staking for a temporary reputation boost.
 * 15. `unstakeForReputationBoost()`: Removes staked amount and boost.
 * 16. `getEffectiveReputation(address _user)`: Returns the user's reputation, including any staking boost.
 * 17. `transferBadge(address _recipient, uint256 _tokenId)`: Transfers a badge NFT to another address (standard ERC721).
 * 18. `approve(address _approved, uint256 _tokenId)`: Approves another address to transfer a badge (standard ERC721).
 * 19. `setApprovalForAll(address _operator, bool _approved)`: Sets approval for all badges for an operator (standard ERC721).
 * 20. `getApproved(uint256 _tokenId)`: Gets the approved address for a badge (standard ERC721).
 * 21. `isApprovedForAll(address _owner, address _operator)`: Checks if an operator is approved for all badges of an owner (standard ERC721).
 *
 * **Badge NFT Functions (ERC721 & Programmable):**
 * 22. `badgeURI(uint256 _tokenId)`: Returns the dynamic URI for a badge NFT, reflecting reputation tier.
 * 23. `supportsInterface(bytes4 interfaceId)`:  Standard ERC721 interface support.
 *
 * **View/Pure Functions:**
 * 24. `getReputationTierDetails(uint256 _tierId)`: Retrieves details of a specific reputation tier.
 * 25. `getBadgeMetadata(uint256 _tokenId)`: Retrieves the metadata associated with a badge token ID.
 * 26. `isVerifier(address _address)`: Checks if an address is a reputation verifier.
 * 27. `isAdmin(address _address)`: Checks if an address is the contract administrator.
 * 28. `isContractPaused()`: Checks if the contract is currently paused.
 * 29. `name()`: Returns the name of the NFT collection (ERC721).
 * 30. `symbol()`: Returns the symbol of the NFT collection (ERC721).
 * 31. `ownerOf(uint256 _tokenId)`: Returns the owner of a badge token (ERC721).
 * 32. `balanceOf(address _owner)`: Returns the balance of badges owned by an address (ERC721).
 * 33. `totalSupply()`: Returns the total supply of badges minted (ERC721).
 */
contract DynamicReputationBadge {
    // --- State Variables ---

    address public admin;
    bool public paused;
    string public baseBadgeURI;
    string public defaultBadgeMetadata;

    mapping(address => uint256) public reputationScores; // User address => reputation points
    mapping(uint256 => ReputationTier) public reputationTiers; // Tier ID => Tier details
    uint256 public nextTierId = 1; // Auto-incrementing tier ID

    mapping(address => bool) public isVerifierAddress; // Address => isVerifier?
    mapping(address => uint256) public stakingBalances; // User address => staked amount (simulated)

    // ERC721 Data
    string private _name = "Reputation Badge";
    string private _symbol = "REPBADGE";
    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _currentTokenId = 1; // Start token IDs from 1

    struct ReputationTier {
        uint256 threshold; // Reputation points required for this tier
        string tierName;    // Name of the tier (e.g., "Bronze", "Silver", "Gold")
    }

    // --- Events ---
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event ContractPaused(address indexed pausedBy);
    event ContractUnpaused(address indexed unpausedBy);
    event ReputationAwarded(address indexed user, uint256 amount, string reason, uint256 newReputation);
    event ReputationRevoked(address indexed user, uint256 amount, string reason, uint256 newReputation);
    event ReputationTierDefined(uint256 tierId, uint256 threshold, string tierName);
    event ReputationTierThresholdUpdated(uint256 tierId, uint256 newThreshold);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event BadgeMinted(address indexed owner, uint256 tokenId, uint256 tierId);
    event BadgeTransferred(address indexed from, address indexed to, uint256 tokenId);
    event StakedForReputationBoost(address indexed user, uint256 amount);
    event UnstakedForReputationBoost(address indexed user, uint256 amount);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyVerifier() {
        require(isVerifierAddress[msg.sender] || msg.sender == admin, "Only verifier or admin can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        emit AdminChanged(address(0), admin);
    }

    // --- Admin Functions ---

    /**
     * @dev Sets a new contract administrator.
     * @param _newAdmin The address of the new administrator.
     */
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin cannot be zero address");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    /**
     * @dev Pauses the contract, preventing most functions from being executed.
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, restoring normal functionality.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Sets the base URI for badge metadata. This URI will be a prefix for badgeURIs.
     * @param _baseURI The base URI string.
     */
    function setBaseBadgeURI(string memory _baseURI) external onlyAdmin {
        baseBadgeURI = _baseURI;
    }

    /**
     * @dev Sets the default metadata to be used if no tier-specific metadata is defined.
     * @param _defaultMetadata The default metadata string.
     */
    function setDefaultBadgeMetadata(string memory _defaultMetadata) external onlyAdmin {
        defaultBadgeMetadata = _defaultMetadata;
    }

    /**
     * @dev Defines a new reputation tier.
     * @param _tierId Unique identifier for the tier.
     * @param _threshold Reputation points required to reach this tier.
     * @param _tierName Name of the tier (e.g., "Bronze", "Silver").
     */
    function defineReputationTier(uint256 _tierId, uint256 _threshold, string memory _tierName) external onlyAdmin {
        require(reputationTiers[_tierId].threshold == 0, "Tier already defined");
        reputationTiers[_tierId] = ReputationTier({threshold: _threshold, tierName: _tierName});
        emit ReputationTierDefined(_tierId, _threshold, _tierName);
        if (_tierId >= nextTierId) {
            nextTierId = _tierId + 1;
        }
    }

    /**
     * @dev Updates the reputation threshold required for an existing tier.
     * @param _tierId The ID of the tier to update.
     * @param _newThreshold The new reputation threshold.
     */
    function updateReputationTierThreshold(uint256 _tierId, uint256 _newThreshold) external onlyAdmin {
        require(reputationTiers[_tierId].threshold != 0, "Tier not defined");
        reputationTiers[_tierId].threshold = _newThreshold;
        emit ReputationTierThresholdUpdated(_tierId, _newThreshold);
    }

    /**
     * @dev Adds an address to the list of reputation verifiers.
     * @param _verifier The address to add as a verifier.
     */
    function addVerifier(address _verifier) external onlyAdmin {
        isVerifierAddress[_verifier] = true;
        emit VerifierAdded(_verifier);
    }

    /**
     * @dev Removes an address from the list of reputation verifiers.
     * @param _verifier The address to remove as a verifier.
     */
    function removeVerifier(address _verifier) external onlyAdmin {
        isVerifierAddress[_verifier] = false;
        emit VerifierRemoved(_verifier);
    }


    // --- Reputation Management Functions ---

    /**
     * @dev Awards reputation points to a user. Callable by verifiers and admin.
     * @param _user The address of the user to award reputation to.
     * @param _amount The amount of reputation points to award.
     * @param _reason A string describing the reason for awarding reputation.
     */
    function awardReputation(address _user, uint256 _amount, string memory _reason) external onlyVerifier whenNotPaused {
        require(_user != address(0), "Invalid user address");
        reputationScores[_user] += _amount;
        _updateBadgeForReputationChange(_user);
        emit ReputationAwarded(_user, _amount, _reason, reputationScores[_user]);
    }

    /**
     * @dev Revokes reputation points from a user. Callable by verifiers and admin.
     * @param _user The address of the user to revoke reputation from.
     * @param _amount The amount of reputation points to revoke.
     * @param _reason A string describing the reason for revoking reputation.
     */
    function revokeReputation(address _user, uint256 _amount, string memory _reason) external onlyVerifier whenNotPaused {
        require(_user != address(0), "Invalid user address");
        require(reputationScores[_user] >= _amount, "Insufficient reputation to revoke");
        reputationScores[_user] -= _amount;
        _updateBadgeForReputationChange(_user);
        emit ReputationRevoked(_user, _amount, _reason, reputationScores[_user]);
    }

    // --- User Functions ---

    /**
     * @dev Retrieves the reputation score of a user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @dev Gets the current badge tier of a user based on their reputation.
     * @param _user The address of the user.
     * @return The ID of the user's current badge tier, or 0 if no tier is reached.
     */
    function getUserBadgeTier(address _user) external view returns (uint256) {
        uint256 reputation = getEffectiveReputation(_user);
        for (uint256 tierId = nextTierId - 1; tierId >= 1; tierId--) {
            if (reputation >= reputationTiers[tierId].threshold) {
                return tierId;
            }
            if (tierId == 1) break; // Prevent underflow in loop
        }
        return 0; // No tier reached
    }

    /**
     * @dev Allows users to simulate staking for a temporary reputation boost.
     *      This is a simplified demonstration and does not involve actual token transfer.
     * @param _amount A placeholder for a staked amount (for demonstration).
     */
    function stakeForReputationBoost(uint256 _amount) external whenNotPaused {
        // In a real implementation, this could involve locking tokens.
        stakingBalances[msg.sender] += _amount; // Just tracking a "staked" amount for demonstration
        emit StakedForReputationBoost(msg.sender, _amount);
    }

    /**
     * @dev Removes the simulated staking boost.
     */
    function unstakeForReputationBoost() external whenNotPaused {
        uint256 stakedAmount = stakingBalances[msg.sender];
        stakingBalances[msg.sender] = 0;
        emit UnstakedForReputationBoost(msg.sender, stakedAmount);
    }

    /**
     * @dev Returns the user's effective reputation, including any staking boost.
     *      In this example, staking boost is simply added to the reputation.
     * @param _user The address of the user.
     * @return The user's effective reputation.
     */
    function getEffectiveReputation(address _user) public view returns (uint256) {
        return reputationScores[_user] + stakingBalances[_user]; // Simple boost example
    }


    // --- Badge NFT Functions (ERC721 & Programmable) ---

    /**
     * @dev Returns the URI for a badge NFT, dynamically generated based on reputation tier.
     * @param _tokenId The ID of the badge token.
     * @return The URI string for the badge metadata.
     */
    function badgeURI(uint256 _tokenId) external view returns (string memory) {
        address owner = ownerOf(_tokenId);
        uint256 tierId = getUserBadgeTier(owner);
        string memory tierName = reputationTiers[tierId].tierName;

        string memory metadata;
        if (tierId > 0) {
            // Example: Constructing dynamic metadata based on tier.
            metadata = string(abi.encodePacked(baseBadgeURI, "tier_", uint2str(tierId), ".json"));
            // In a real application, you might have more complex logic or off-chain services to generate metadata.
        } else {
            metadata = defaultBadgeMetadata; // Use default if no tier reached
        }
        return metadata;
    }

    /**
     * @dev Internal function to update a user's badge when their reputation changes.
     *      Mints a new badge if they reach a tier for the first time, or updates existing badge metadata.
     * @param _user The address of the user whose reputation changed.
     */
    function _updateBadgeForReputationChange(address _user) internal {
        uint256 currentTier = getUserBadgeTier(_user);
        uint256 currentTokenId = _getTokenIdForUser(_user);

        if (currentTier > 0 && currentTokenId == 0) {
            // Mint a new badge if user reaches a tier and doesn't have a badge yet
            _mintBadge(_user, currentTier);
        } else if (currentTokenId > 0) {
            // Badge already exists, could potentially update metadata or visual aspects based on tier change.
            // (In this simplified example, metadata update is handled by badgeURI dynamically)
            // Future enhancement: Could implement on-chain badge appearance update logic here.
        }
    }

    /**
     * @dev Internal function to mint a new badge NFT to a user for a specific tier.
     * @param _user The address of the user to mint the badge to.
     * @param _tierId The ID of the reputation tier the badge represents.
     */
    function _mintBadge(address _user, uint256 _tierId) internal {
        uint256 tokenId = _currentTokenId++; // Get and increment token ID
        _balanceOf[_user]++;
        _ownerOf[tokenId] = _user;
        _setTokenIdForUser(_user, tokenId); // Store the token ID associated with the user (for tracking)
        emit BadgeMinted(_user, tokenId, _tierId);
    }

    /**
     * @dev Internal function to get the token ID associated with a user.
     *      This is a simplified approach for demonstration. In a real system, you might have multiple badges per user.
     * @param _user The address of the user.
     * @return The token ID associated with the user, or 0 if none.
     */
    mapping(address => uint256) private _userToTokenId; // Simplified: One token ID per user for demonstration
    function _getTokenIdForUser(address _user) internal view returns (uint256) {
        return _userToTokenId[_user];
    }
    function _setTokenIdForUser(address _user, uint256 _tokenId) internal {
        _userToTokenId[_user] = _tokenId;
    }

    // --- ERC721 Core Functions ---

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual whenNotPaused {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {safeTransferFrom}, this function does not perform a
     *  {receiverIsImplementer} check.
     *  - Requirements:
     *    - `from` cannot be the zero address.
     *    - `to` cannot be the zero address.
     *    - `tokenId` must be owned by `from`.
     *  - Emits {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(from != address(0), "ERC721: transfer from incorrect address");
        require(to != address(0), "ERC721: transfer to incorrect address");
        require(_ownerOf[tokenId] == from, "ERC721: transfer of token that is not own");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId); // Clear approvals from the token owner
        _balanceOf[from] -= 1;
        _balanceOf[to] += 1;
        _ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
        emit BadgeTransferred(from, to, tokenId); // Custom event for badge transfer.
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *  - Requirements:
     *    - `from` cannot be the zero address.
     *    - `to` cannot be the zero address.
     *    - `tokenId` must be owned by `from`.
     *    - If `to` contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *  - Emits {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *  Emits {Approval} event.
     */
    function approve(address _approved, uint256 tokenId) public virtual whenNotPaused {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        _approve(_approved, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *  Emits {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual whenNotPaused {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Get the approved address for a single tokenId
     *  Reverts if tokenId is not valid.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Check if `operator` is approved to operate on all of `owner` tokens
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns the owner of the `tokenId`.
     *  Reverts if `tokenId` does not exist.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _ownerOf[tokenId];
        require(owner != address(0), "ERC721: ownerOf query for nonexistent token");
        return owner;
    }

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balanceOf[owner];
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * Tokens may be burned (destroyed), but we don't track burn in this simplified example.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _currentTokenId - 1; // Since _currentTokenId starts at 1 and increments after minting.
    }

    /**
     * @dev Function to mint a new token. Internal function.
     *  Mints `tokenId` and assigns it to `to`
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balanceOf[to] += 1;
        _ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * Reverts if `tokenId` does not exist.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId); // Get owner before clearing _ownerOf
        _approve(address(0), tokenId); // Clear approvals

        _balanceOf[owner] -= 1;
        delete _ownerOf[tokenId]; // Set owner to zero address to mark as non-existent

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Approve `approved` address to operate on `tokenId`
     */
    function _approve(address approved, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = approved;
        emit Approval(ownerOf(tokenId), approved, tokenId);
    }

    /**
     * @dev Set or revoke approval for `operator` to operate on all of `owner` tokens
     *  Emits {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     * Tokens can be managed off-chain, so check _ownerOf mapping directly
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    /**
     * @dev Returns whether the caller is the owner or operator.
     *  Operator can be spender or approved address.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     *  The call is not executed if the target address is not a contract.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 tokenId to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        mrevert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // --- ERC721 Metadata (Optional) ---

    /**
     * @dev Returns the token name.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    // --- ERC165 Interface Support ---

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    // --- Helper Functions (View/Pure) ---

    /**
     * @dev Retrieves details of a specific reputation tier.
     * @param _tierId The ID of the tier.
     * @return Tuple containing (threshold, tierName).
     */
    function getReputationTierDetails(uint256 _tierId) external view returns (uint256 threshold, string memory tierName) {
        require(reputationTiers[_tierId].threshold != 0, "Tier not defined");
        return (reputationTiers[_tierId].threshold, reputationTiers[_tierId].tierName);
    }

    /**
     * @dev Retrieves the metadata associated with a badge token ID.
     *      In this simplified example, it directly returns the badgeURI.
     * @param _tokenId The ID of the badge token.
     * @return The metadata URI string.
     */
    function getBadgeMetadata(uint256 _tokenId) external view returns (string memory) {
        return badgeURI(_tokenId);
    }

    /**
     * @dev Checks if an address is a reputation verifier.
     * @param _address The address to check.
     * @return True if the address is a verifier, false otherwise.
     */
    function isVerifier(address _address) external view returns (bool) {
        return isVerifierAddress[_address];
    }

    /**
     * @dev Checks if an address is the contract administrator.
     * @param _address The address to check.
     * @return True if the address is the admin, false otherwise.
     */
    function isAdmin(address _address) external view returns (bool) {
        return _address == admin;
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if paused, false otherwise.
     */
    function isContractPaused() external view returns (bool) {
        return paused;
    }

    // --- Internal Utility Functions ---
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// --- Interfaces ---
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained using `IERC721Receiver.onERC721Received.selector`.
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param tokenId The ID of the token being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` unless reverting
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     *
     * Triggered when tokens are minted (`from` is the zero address),
     * burned (`to` is the zero address),
     * or transferred from one owner to another.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` operator to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Emitted when the approved address for an NFT is changed or reaffirmed. The zero
     * address indicates there is no approved address. When a Transfer event is emitted for this
     * token, the approval is cleared as well.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Approve `to` to operate on `tokenId` token
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     */
    function approve(address approved, uint256 tokenId) external;

    /**
     * @dev Approve or unapprove `operator` to manage all of the caller's tokens.
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token, if any.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is approved to manage all of the `owner` tokens.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See {IERC165-supportsInterface}.
     *
     * @param interfaceId The interface ID that will be queried.
     * @return bool if the contract implements `interfaceId` and
     *         `interfaceId` is not 0xffffffff, otherwise returns false.
     * @notice Interface identification is specified in ERC-165.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
```