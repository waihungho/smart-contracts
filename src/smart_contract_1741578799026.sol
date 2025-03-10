```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT and Social Reputation System
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT system tied to a social reputation score.
 * Users mint profile NFTs that evolve based on their on-chain interactions and reputation.
 * This contract features dynamic NFT metadata updates, a reputation system based on positive and negative interactions,
 * tiered reputation levels, and governance mechanisms.
 *
 * **Outline:**
 * 1. **NFT Core Functionality:** Minting, Burning, Transferring Profile NFTs.
 * 2. **Profile Management:** Setting and updating user profile details associated with NFTs.
 * 3. **Dynamic NFT Metadata:**  NFT metadata updates based on reputation level.
 * 4. **Reputation System:** Earning and losing reputation through social interactions.
 * 5. **Reputation Tiers:**  Tiered reputation levels with associated benefits (e.g., NFT visual changes).
 * 6. **Social Interactions:**  "Liking" or "Voting" mechanism to influence reputation.
 * 7. **Governance/Admin:**  Pausing contract, setting reputation thresholds, managing tiers.
 * 8. **Utility Functions:** View functions for accessing reputation, profile details, and NFT data.
 * 9. **Security and Control:**  Access control modifiers, pause functionality.
 *
 * **Function Summary:**
 * 1. `mintProfileNFT(string memory _name, string memory _bio)`: Mints a new profile NFT for the caller.
 * 2. `transferNFT(address _to, uint256 _tokenId)`: Transfers a profile NFT to another address.
 * 3. `burnNFT(uint256 _tokenId)`: Burns (destroys) a profile NFT.
 * 4. `setProfileDetails(uint256 _tokenId, string memory _name, string memory _bio)`: Sets or updates the profile details (name, bio) associated with an NFT.
 * 5. `getProfileDetails(uint256 _tokenId)`: Retrieves the profile details associated with an NFT.
 * 6. `likeContent(uint256 _targetTokenId)`: Allows a user to "like" another user's profile NFT, increasing their reputation.
 * 7. `reportContent(uint256 _targetTokenId)`: Allows a user to "report" another user's profile NFT, potentially decreasing their reputation.
 * 8. `getReputation(uint256 _tokenId)`: Retrieves the reputation score associated with an NFT.
 * 9. `getReputationTier(uint256 _tokenId)`: Retrieves the reputation tier of the user associated with an NFT.
 * 10. `setReputationThresholds(uint256[] memory _thresholds)`: (Admin) Sets the reputation thresholds for different tiers.
 * 11. `getReputationThresholds()`: (View) Retrieves the current reputation thresholds.
 * 12. `pauseContract()`: (Admin) Pauses the contract, preventing most state-changing operations.
 * 13. `unpauseContract()`: (Admin) Unpauses the contract, restoring normal functionality.
 * 14. `isContractPaused()`: (View) Checks if the contract is currently paused.
 * 15. `getOwnerOfNFT(uint256 _tokenId)`: Retrieves the owner of a specific profile NFT.
 * 16. `tokenURI(uint256 _tokenId)`: Returns the URI for the metadata of a profile NFT (dynamic metadata).
 * 17. `supportsInterface(bytes4 interfaceId)`:  Standard ERC165 interface support check.
 * 18. `setBaseURI(string memory _baseURI)`: (Admin) Sets the base URI for NFT metadata.
 * 19. `getBaseURI()`: (View) Retrieves the current base URI for NFT metadata.
 * 20. `setMetadataUpdateInterval(uint256 _interval)`: (Admin) Sets the interval (in blocks) after which NFT metadata can be updated based on reputation changes.
 * 21. `getLastMetadataUpdateBlock(uint256 _tokenId)`: (View) Retrieves the last block number when the NFT metadata was updated.
 * 22. `_updateNFTMetadata(uint256 _tokenId)`: (Internal) Updates the NFT metadata based on the user's current reputation tier.
 */
contract DynamicReputationNFT {
    // ** State Variables **

    string public name = "DynamicReputationNFT";
    string public symbol = "DRNFT";

    address public owner;
    bool public paused;

    uint256 public totalSupply;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public balance;
    mapping(uint256 => string) public profileNames;
    mapping(uint256 => string) public profileBios;
    mapping(uint256 => uint256) public reputationScores;
    mapping(uint256 => uint256) public lastMetadataUpdateBlock; // Track last metadata update time per token

    uint256[] public reputationThresholds = [10, 50, 100, 200]; // Example thresholds for tiers
    string public baseURI = "ipfs://default/"; // Base URI for NFT metadata
    uint256 public metadataUpdateInterval = 10; // Minimum blocks between metadata updates

    // ** Events **

    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTTransfer(address indexed from, address indexed to, uint256 tokenId);
    event NFTBurned(uint256 tokenId);
    event ProfileDetailsUpdated(uint256 tokenId, string name, string bio);
    event ReputationChanged(uint256 tokenId, uint256 oldReputation, uint256 newReputation);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event BaseURISet(string newBaseURI);
    event MetadataUpdateIntervalSet(uint256 newInterval);
    event ReputationThresholdsUpdated(uint256[] newThresholds);


    // ** Modifiers **

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    // ** Constructor **

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    // ** 1. NFT Core Functionality **

    /// @notice Mints a new profile NFT for the caller.
    /// @param _name The name associated with the profile.
    /// @param _bio The bio associated with the profile.
    function mintProfileNFT(string memory _name, string memory _bio) external whenNotPaused returns (uint256) {
        totalSupply++;
        uint256 newTokenId = totalSupply;
        tokenOwner[newTokenId] = msg.sender;
        balance[msg.sender]++;
        profileNames[newTokenId] = _name;
        profileBios[newTokenId] = _bio;
        reputationScores[newTokenId] = 0; // Initial reputation is 0
        lastMetadataUpdateBlock[newTokenId] = block.number;

        emit NFTMinted(msg.sender, newTokenId);
        emit ProfileDetailsUpdated(newTokenId, _name, _bio);
        return newTokenId;
    }

    /// @notice Transfers a profile NFT to another address.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        address from = msg.sender;
        _transfer(from, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0), "Transfer to the zero address.");
        require(tokenOwner[_tokenId] == _from, "Not token owner.");

        balance[_from]--;
        balance[_to]++;
        tokenOwner[_tokenId] = _to;

        emit NFTTransfer(_from, _to, _tokenId);
    }


    /// @notice Burns (destroys) a profile NFT.
    /// @param _tokenId The ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        _burn(_tokenId);
    }

    function _burn(uint256 _tokenId) internal {
        address ownerAddress = tokenOwner[_tokenId];
        require(ownerAddress != address(0), "Invalid token ID.");

        balance[ownerAddress]--;
        delete tokenOwner[_tokenId];
        delete profileNames[_tokenId];
        delete profileBios[_tokenId];
        delete reputationScores[_tokenId];
        delete lastMetadataUpdateBlock[_tokenId];

        emit NFTBurned(_tokenId);
    }

    /// @notice Retrieves the owner of a specific profile NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The address of the NFT owner.
    function getOwnerOfNFT(uint256 _tokenId) external view validTokenId(_tokenId) returns (address) {
        return tokenOwner[_tokenId];
    }


    // ** 2. Profile Management **

    /// @notice Sets or updates the profile details (name, bio) associated with an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @param _name The new profile name.
    /// @param _bio The new profile bio.
    function setProfileDetails(uint256 _tokenId, string memory _name, string memory _bio) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        profileNames[_tokenId] = _name;
        profileBios[_tokenId] = _bio;
        emit ProfileDetailsUpdated(_tokenId, _name, _bio);
    }

    /// @notice Retrieves the profile details associated with an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The profile name and bio.
    function getProfileDetails(uint256 _tokenId) external view validTokenId(_tokenId) returns (string memory name, string memory bio) {
        return (profileNames[_tokenId], profileBios[_tokenId]);
    }

    // ** 3. Dynamic NFT Metadata & 5. Reputation Tiers **

    /// @notice Returns the URI for the metadata of a profile NFT (dynamic metadata).
    /// @param _tokenId The ID of the NFT.
    /// @return The metadata URI.
    function tokenURI(uint256 _tokenId) external view validTokenId(_tokenId) returns (string memory) {
        uint256 reputationTier = getReputationTier(_tokenId);
        return string(abi.encodePacked(baseURI, uint2str(reputationTier), "/", uint2str(_tokenId), ".json"));
        // Example: ipfs://default/1/123.json  (Tier 1, Token ID 123)
    }

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
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 lsb = uint8(_i % 10 + 48);
            bstr[k] = bytes1(lsb);
            _i /= 10;
        }
        return string(bstr);
    }

    /// @notice Retrieves the current base URI for NFT metadata.
    /// @return The base URI string.
    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    /// @notice (Admin) Sets the base URI for NFT metadata.
    /// @param _baseURI The new base URI to set.
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    /// @notice (Admin) Sets the interval (in blocks) after which NFT metadata can be updated based on reputation changes.
    /// @param _interval The new metadata update interval in blocks.
    function setMetadataUpdateInterval(uint256 _interval) external onlyOwner {
        metadataUpdateInterval = _interval;
        emit MetadataUpdateIntervalSet(_interval);
    }

    /// @notice (View) Retrieves the last block number when the NFT metadata was updated.
    /// @param _tokenId The ID of the NFT.
    /// @return The last metadata update block number.
    function getLastMetadataUpdateBlock(uint256 _tokenId) external view validTokenId(_tokenId) returns (uint256) {
        return lastMetadataUpdateBlock[_tokenId];
    }

    /// @notice (Internal) Updates the NFT metadata based on the user's current reputation tier.
    /// @param _tokenId The ID of the NFT to update metadata for.
    function _updateNFTMetadata(uint256 _tokenId) internal validTokenId(_tokenId){
        lastMetadataUpdateBlock[_tokenId] = block.number;
        // In a real implementation, this function would trigger an off-chain metadata refresh
        // based on the current reputation tier.
        // For example, you could emit an event that an off-chain service listens to,
        // and then updates the metadata on IPFS or a similar storage.
        // The tokenURI function would then serve the updated metadata.
    }


    /// @notice Retrieves the reputation tier of the user associated with an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The reputation tier (starting from 1).
    function getReputationTier(uint256 _tokenId) public view validTokenId(_tokenId) returns (uint256) {
        uint256 reputation = reputationScores[_tokenId];
        for (uint256 i = 0; i < reputationThresholds.length; i++) {
            if (reputation < reputationThresholds[i]) {
                return i + 1; // Tier starts from 1
            }
        }
        return reputationThresholds.length + 1; // Highest tier if reputation exceeds all thresholds
    }

    /// @notice (Admin) Sets the reputation thresholds for different tiers.
    /// @param _thresholds An array of reputation thresholds (must be in ascending order).
    function setReputationThresholds(uint256[] memory _thresholds) external onlyOwner {
        // Add validation to ensure thresholds are in ascending order if needed.
        reputationThresholds = _thresholds;
        emit ReputationThresholdsUpdated(_thresholds);
    }

    /// @notice (View) Retrieves the current reputation thresholds.
    /// @return An array of reputation thresholds.
    function getReputationThresholds() external view returns (uint256[] memory) {
        return reputationThresholds;
    }


    // ** 4. Reputation System & 6. Social Interactions **

    /// @notice Allows a user to "like" another user's profile NFT, increasing their reputation.
    /// @param _targetTokenId The ID of the profile NFT to like.
    function likeContent(uint256 _targetTokenId) external whenNotPaused validTokenId(_targetTokenId) {
        require(_targetTokenId != _getTokenIdOfSender(), "Cannot like your own content."); // Prevent self-liking
        uint256 oldReputation = reputationScores[_targetTokenId];
        reputationScores[_targetTokenId]++;
        emit ReputationChanged(_targetTokenId, oldReputation, reputationScores[_targetTokenId]);
        _maybeUpdateMetadata(_targetTokenId);
    }

    /// @notice Allows a user to "report" another user's profile NFT, potentially decreasing their reputation.
    /// @param _targetTokenId The ID of the profile NFT to report.
    function reportContent(uint256 _targetTokenId) external whenNotPaused validTokenId(_targetTokenId) {
        require(_targetTokenId != _getTokenIdOfSender(), "Cannot report your own content."); // Prevent self-reporting
        uint256 oldReputation = reputationScores[_targetTokenId];
        if (reputationScores[_targetTokenId] > 0) {
            reputationScores[_targetTokenId]--;
        }
        emit ReputationChanged(_targetTokenId, oldReputation, reputationScores[_targetTokenId]);
        _maybeUpdateMetadata(_targetTokenId);
    }

    function _maybeUpdateMetadata(uint256 _tokenId) internal {
        if(block.number >= lastMetadataUpdateBlock[_tokenId] + metadataUpdateInterval){
            _updateNFTMetadata(_tokenId);
        }
    }

    function _getTokenIdOfSender() internal view returns (uint256) {
        address sender = msg.sender;
        for (uint256 tokenId = 1; tokenId <= totalSupply; tokenId++) {
            if (tokenOwner[tokenId] == sender) {
                return tokenId;
            }
        }
        return 0; // Sender does not own an NFT in this contract.
    }


    /// @notice Retrieves the reputation score associated with an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The reputation score.
    function getReputation(uint256 _tokenId) external view validTokenId(_tokenId) returns (uint256) {
        return reputationScores[_tokenId];
    }


    // ** 7. Governance/Admin **

    /// @notice (Admin) Pauses the contract, preventing most state-changing operations.
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice (Admin) Unpauses the contract, restoring normal functionality.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice (View) Checks if the contract is currently paused.
    /// @return True if the contract is paused, false otherwise.
    function isContractPaused() external view returns (bool) {
        return paused;
    }


    // ** 9. Security and Control (Already implemented with Modifiers and Pause) **


    // ** 17. ERC165 Interface Support **
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-to-detect-interface-support[EIP]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     *
     * Triggered when minting (``from`` is address(0)), burning (``to`` is address(0)),
     * or transferring (when ``from`` and ``to`` are both non-zero).
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` approves `approved` to operate on the `tokenId` token.
     * Approval is granted per token id, which allows marketplaces to perform safe trades
     * without requiring operators to hold erc721 tokens.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` approves `operator` to operate on all of their tokens.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

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
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Approve `to` to operate on `tokenId` token.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - Caller must own token or be approved to manage all of owner's tokens.
     */
    function approve(address approved, uint256 tokenId) external payable;

    /**
     * @dev Approve or unapprove `operator` to manage all of caller's tokens.
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be caller.
     */
    function setApprovalForAll(address operator, bool approved) external payable;

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
```