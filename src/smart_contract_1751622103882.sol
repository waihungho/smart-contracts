```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/**
 * @title QuantumEntangledNFT
 * @dev A novel ERC721 contract simulating quantum entanglement between pairs of NFTs.
 *      Entangled NFTs share a connection where operations on one can affect the other.
 *      They have a dynamic 'quantum value' which is synchronized or combined when entangled.
 *      'Observation' of an entangled pair collapses their state and disentangles them.
 *      Includes features like minting, burning, entanglement management, value setting,
 *      observation, dynamic metadata based on state, fees, pausing, and ownership control.
 *
 * Outline:
 * 1.  Basic ERC721 functionality (inherited from OpenZeppelin).
 * 2.  Entanglement Mapping: Stores the entangled partner for each token.
 * 3.  Quantum Value: A dynamic property associated with each token.
 * 4.  Base URI: For generating standard token URIs.
 * 5.  Entanglement Fee: Cost associated with creating entanglement.
 * 6.  Events: To signal key state changes (mint, burn, entanglement, observation, value change, fees).
 * 7.  Modifiers: Custom conditions for function execution (e.g., check entanglement state).
 * 8.  Core Functions:
 *     - Standard ERC721 operations (balanceOf, ownerOf, transferFrom, etc.).
 *     - Minting & Burning.
 *     - Entanglement Management (entangle, disentangle).
 *     - State Queries (isEntangled, getEntangledToken, getQuantumValue, getEffectiveQuantumValue).
 *     - Quantum Value Management (setQuantumValue).
 *     - Observation (observeAndCollapse).
 *     - Metadata (tokenURI override, setBaseURI).
 *     - Fee Management (setEntanglementFee, withdrawFees).
 *     - Contract Control (pause, unpause, ownership).
 * 9.  Internal Hooks: To ensure entanglement is broken on transfer/burn.
 */
contract QuantumEntangledNFT is ERC721, Ownable, Pausable, ERC721Burnable {

    // --- State Variables ---

    /// @dev Mapping from token ID to its entangled partner token ID.
    ///      A token ID mapping to 0 means it's not entangled.
    mapping(uint256 => uint256) private _entangledWith;

    /// @dev Mapping from token ID to its stored quantum value.
    mapping(uint256 => uint256) private _quantumValue;

    /// @dev The base URI for token metadata.
    string private _baseTokenURI;

    /// @dev The fee required to entangle a pair of tokens.
    uint256 private _entanglementFee;

    // --- Events ---

    /// @dev Emitted when a token pair becomes entangled.
    event Entangled(uint256 tokenId1, uint256 tokenId2);

    /// @dev Emitted when a token pair becomes disentangled.
    event Disentangled(uint256 tokenId1, uint256 tokenId2);

    /// @dev Emitted when an entangled pair is observed, collapsing their state.
    event Observed(uint256 tokenId, uint256 finalValue);

    /// @dev Emitted when a token's quantum value is changed.
    event QuantumValueChanged(uint256 tokenId, uint256 oldValue, uint256 newValue);

    /// @dev Emitted when the entanglement fee is updated.
    event EntanglementFeeSet(uint256 oldFee, uint256 newFee);

    /// @dev Emitted when fees are withdrawn.
    event FeesWithdrawal(address recipient, uint256 amount);

    // --- Constructor ---

    /// @dev Constructor initializes the contract with a name, symbol, and base URI.
    /// @param name_ The collection name.
    /// @param symbol_ The collection symbol.
    /// @param baseURI_ The base URI for token metadata.
    constructor(string memory name_, string memory symbol_, string memory baseURI_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI_;
        _entanglementFee = 0; // Initial fee is zero
    }

    // --- Modifiers ---

    /// @dev Throws if the token is currently entangled.
    modifier whenNotEntangled(uint256 tokenId) {
        require(!isEntangled(tokenId), "Token is entangled");
        _;
    }

    /// @dev Throws if the token is not currently entangled.
    modifier whenEntangled(uint256 tokenId) {
        require(isEntangled(tokenId), "Token is not entangled");
        _;
    }

    /// @dev Throws if the fee paid is not enough.
    modifier requireEntanglementFee() {
        require(msg.value >= _entanglementFee, "Insufficient entanglement fee");
        _;
    }

    // --- Standard ERC721 Overrides & Hooks ---

    /// @dev Returns the base URI for token metadata.
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev Returns the token URI. Changes based on entanglement status.
    ///      If entangled, returns a URI indicating the entangled state.
    ///      Otherwise, returns the standard URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists

        string memory base = _baseURI();
        if (isEntangled(tokenId)) {
            // Append something distinct for entangled tokens
            return string.concat(base, "entangled/", Strings.toString(tokenId));
        } else {
            return string.concat(base, Strings.toString(tokenId));
        }
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    ///      Breaks entanglement if either token in the transfer is entangled.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If the token being transferred is entangled, disentangle the pair
        if (_entangledWith[tokenId] != 0) {
            // Need to call the internal disentangle logic here
            _disentanglePair(tokenId);
        }
    }

     /// @dev See {ERC721Burnable-_beforeTokenBurn}.
    ///      Breaks entanglement if the token being burned is entangled.
    function _beforeTokenBurn(uint256 tokenId) internal override {
        super._beforeTokenBurn(tokenId);

         // If the token being burned is entangled, disentangle the pair
        if (_entangledWith[tokenId] != 0) {
            _disentanglePair(tokenId);
        }
    }


    // --- Custom Quantum Entanglement Functions ---

    /**
     * @dev Mints a new token and sets its initial quantum value.
     * @param to The address to mint the token to.
     * @param initialValue The initial quantum value for the token.
     */
    function mint(address to, uint256 initialValue) external onlyOwner whenNotPaused {
        uint256 tokenId = totalSupply() + 1; // Simple token ID assignment
        _safeMint(to, tokenId);
        _setQuantumValue(tokenId, initialValue);
        // Note: Mint event handled by ERC721
    }

    /**
     * @dev Burns a token. Overridden to ensure entanglement is handled by _beforeTokenBurn hook.
     * @param tokenId The token ID to burn.
     */
    function burn(uint256 tokenId) public override whenNotPaused {
        super.burn(tokenId);
        // _beforeTokenBurn hook handles disentanglement
    }

    /**
     * @dev Attempts to entangle two tokens.
     *      Requires ownership or approval for both tokens by msg.sender.
     *      Requires payment of the entanglement fee.
     *      Tokens must not be the same and neither should already be entangled.
     * @param tokenId1 The ID of the first token.
     * @param tokenId2 The ID of the second token.
     */
    function entanglePairWithFee(uint256 tokenId1, uint256 tokenId2) external payable whenNotPaused requireEntanglementFee {
        require(tokenId1 != tokenId2, "Cannot entangle token with itself");
        _requireOwnedOrApproved(tokenId1, msg.sender);
        _requireOwnedOrApproved(tokenId2, msg.sender);
        require(!isEntangled(tokenId1), "Token 1 is already entangled");
        require(!isEntangled(tokenId2), "Token 2 is already entangled");

        _entangledWith[tokenId1] = tokenId2;
        _entangledWith[tokenId2] = tokenId1;

        // Refund any excess fee
        if (msg.value > _entanglementFee) {
            payable(msg.sender).transfer(msg.value - _entanglementFee);
        }

        emit Entangled(tokenId1, tokenId2);
    }

    /**
     * @dev Disentangles a token pair.
     *      Requires ownership or approval for the provided token by msg.sender.
     *      The token must be entangled.
     * @param tokenId The ID of one token in the pair.
     */
    function disentanglePair(uint256 tokenId) external whenNotPaused whenEntangled(tokenId) {
         _requireOwnedOrApproved(tokenId, msg.sender);
         _disentanglePair(tokenId);
    }

     /// @dev Internal function to perform the disentanglement logic.
     /// @param tokenId The ID of one token in the pair.
    function _disentanglePair(uint256 tokenId) internal {
        uint256 entangledPartner = _entangledWith[tokenId];
        require(entangledPartner != 0, "Token not entangled (internal error)"); // Should be caught by modifier or hook logic

        _entangledWith[tokenId] = 0;
        _entangledWith[entangledPartner] = 0;

        emit Disentangled(tokenId, entangledPartner);
    }

    /**
     * @dev Checks if a token is currently entangled.
     * @param tokenId The token ID to check.
     * @return True if the token is entangled, false otherwise.
     */
    function isEntangled(uint256 tokenId) public view returns (bool) {
        // Check if token exists implicitly via _exists or similar if needed,
        // but for entanglement mapping, checking if the partner is non-zero is sufficient.
        // However, ensure token exists first for robustness.
         _requireOwned(tokenId); // Check existence/ownership
        return _entangledWith[tokenId] != 0;
    }

    /**
     * @dev Returns the ID of the token entangled with the given token.
     * @param tokenId The token ID.
     * @return The ID of the entangled token, or 0 if not entangled.
     */
    function getEntangledToken(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId); // Check existence/ownership
        return _entangledWith[tokenId];
    }

    /**
     * @dev Sets the quantum value for a token.
     *      Requires ownership or approval for the token by msg.sender.
     * @param tokenId The token ID.
     * @param value The new quantum value.
     */
    function setQuantumValue(uint256 tokenId, uint256 value) external whenNotPaused {
        _requireOwnedOrApproved(tokenId, msg.sender);
        _setQuantumValue(tokenId, value);
    }

    /// @dev Internal function to set the quantum value.
    /// @param tokenId The token ID.
    /// @param value The new quantum value.
    function _setQuantumValue(uint256 tokenId, uint256 value) internal {
         _requireOwned(tokenId); // Check existence/ownership
        uint256 oldValue = _quantumValue[tokenId];
        _quantumValue[tokenId] = value;
        emit QuantumValueChanged(tokenId, oldValue, value);
    }

    /**
     * @dev Gets the raw stored quantum value for a token.
     * @param tokenId The token ID.
     * @return The stored quantum value.
     */
    function getQuantumValue(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId); // Check existence/ownership
        return _quantumValue[tokenId];
    }

    /**
     * @dev Gets the *effective* quantum value for a token.
     *      If entangled, this is the sum of both tokens' raw values.
     *      If not entangled, this is just the token's raw value.
     * @param tokenId The token ID.
     * @return The effective quantum value.
     */
    function getEffectiveQuantumValue(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId); // Check existence/ownership
        uint256 entangledPartner = _entangledWith[tokenId];
        if (entangledPartner != 0) {
            // Note: No check if entangledPartner exists here.
            // This assumes entanglement implies both tokens exist.
            // In a real system, you might add a check or ensure invariant via mint/burn/transfer.
             return _quantumValue[tokenId] + _quantumValue[entangledPartner];
        } else {
            return _quantumValue[tokenId];
        }
    }

    /**
     * @dev Simulates 'observing' an entangled token pair.
     *      Requires the token to be entangled and msg.sender to be owner/approved.
     *      Calculates the effective quantum value, sets *half* of that value
     *      as the *new stored* quantum value for the provided token,
     *      and then disentangles the pair.
     *      This represents collapsing the entangled state into a definite value.
     * @param tokenId The ID of one token in the entangled pair.
     */
    function observeAndCollapse(uint256 tokenId) external whenNotPaused whenEntangled(tokenId) {
        _requireOwnedOrApproved(tokenId, msg.sender);

        uint256 entangledPartner = _entangledWith[tokenId];
        uint256 effectiveValue = getEffectiveQuantumValue(tokenId);
        uint256 finalValue = effectiveValue / 2; // Example collapse logic: split the sum

        // Update the stored value for the observed token
        _setQuantumValue(tokenId, finalValue);

        // Disentangle the pair
        _disentanglePair(tokenId);

        emit Observed(tokenId, finalValue);
    }

    // --- Admin & Fee Management Functions ---

    /**
     * @dev Sets the base URI for token metadata. Only callable by the owner.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev Sets the fee required to entangle a pair. Only callable by the owner.
     * @param fee The new entanglement fee in wei.
     */
    function setEntanglementFee(uint256 fee) external onlyOwner {
        uint256 oldFee = _entanglementFee;
        _entanglementFee = fee;
        emit EntanglementFeeSet(oldFee, fee);
    }

    /**
     * @dev Gets the current entanglement fee.
     * @return The current entanglement fee in wei.
     */
    function getEntanglementFee() public view returns (uint256) {
        return _entanglementFee;
    }

    /**
     * @dev Withdraws accumulated entanglement fees. Only callable by the owner.
     * @param recipient The address to send the fees to.
     */
    function withdrawFees(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees available to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawal(recipient, balance);
    }

    // --- Pausability Functions ---

    /**
     * @dev Pauses the contract. Only callable by the owner.
     *      Prevents minting, burning, entanglement operations, value setting, and observation.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Returns the current paused state of the contract.
     */
    function isPaused() public view returns (bool) {
        return paused();
    }

    // --- Ownable Functions ---

    // transferOwnership and renounceOwnership are inherited and exposed
    // via OpenZeppelin's Ownable contract.

    // --- Internal Utility Functions ---

    /// @dev Helper to check if sender is owner or approved for a token.
    /// @param tokenId The token ID.
    /// @param account The account to check.
    function _requireOwnedOrApproved(uint256 tokenId, address account) internal view {
        require(
            _isApprovedOrOwner(account, tokenId),
            "Caller is not owner or approved"
        );
    }

     /// @dev Helper to check if a token exists (and is owned by someone).
     ///      Used internally before accessing token state specific to existing tokens.
     /// @param tokenId The token ID.
     function _requireOwned(uint256 tokenId) internal view {
         require(_exists(tokenId), "Token does not exist");
     }
}
```