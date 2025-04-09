```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Social Reputation & Utility NFT Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract platform for creating Dynamic Social Reputation NFTs
 *      with built-in utility and advanced features. This contract allows users to
 *      mint NFTs that represent their reputation within a platform, which can
 *      evolve based on their contributions and interactions. These NFTs can also
 *      unlock various utilities and functionalities within the ecosystem.
 *
 * Function Summary:
 * -----------------
 * **NFT Management:**
 * 1.  `createReputationNFT(string memory _initialMetadataURI)`: Mint a new Reputation NFT for a user.
 * 2.  `updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Update the metadata URI of an existing NFT.
 * 3.  `transferNFT(address _to, uint256 _tokenId)`: Transfer ownership of a Reputation NFT.
 * 4.  `burnNFT(uint256 _tokenId)`: Burn (destroy) a Reputation NFT.
 * 5.  `getNFTMetadataURI(uint256 _tokenId)`: Retrieve the metadata URI for a specific NFT.
 * 6.  `getNFTOwner(uint256 _tokenId)`: Get the owner of a specific NFT.
 * 7.  `getTotalNFTSupply()`: Get the total number of Reputation NFTs minted.
 *
 * **Reputation System:**
 * 8.  `increaseReputation(uint256 _tokenId, uint256 _amount)`: Increase the reputation score associated with an NFT.
 * 9.  `decreaseReputation(uint256 _tokenId, uint256 _amount)`: Decrease the reputation score associated with an NFT.
 * 10. `setReputationScore(uint256 _tokenId, uint256 _newScore)`: Directly set the reputation score of an NFT.
 * 11. `getReputationScore(uint256 _tokenId)`: Retrieve the reputation score of an NFT.
 * 12. `rankNFTByReputation(uint256 _tokenId1, uint256 _tokenId2)`: Compare the reputation of two NFTs and return which has higher reputation.
 *
 * **Utility & Feature Unlocks:**
 * 13. `addUtility(uint256 _tokenId, string memory _utilityDescription)`: Add a utility feature unlocked by an NFT.
 * 14. `removeUtility(uint256 _tokenId, string memory _utilityDescription)`: Remove a utility feature from an NFT.
 * 15. `getNFTUtilities(uint256 _tokenId)`: Get a list of utilities unlocked by an NFT.
 * 16. `checkUtilityAvailability(uint256 _tokenId, string memory _utilityDescription)`: Check if a specific utility is unlocked by an NFT.
 *
 * **Community & Social Features:**
 * 17. `endorseNFT(uint256 _tokenId)`: Allow users to endorse (upvote) an NFT, contributing to social reputation.
 * 18. `getEndorsementCount(uint256 _tokenId)`: Get the number of endorsements an NFT has received.
 * 19. `reportNFT(uint256 _tokenId, string memory _reportReason)`: Allow users to report an NFT for inappropriate behavior (governance/moderation).
 * 20. `getReportCount(uint256 _tokenId)`: Get the number of reports an NFT has received.
 *
 * **Platform Management (Admin Only):**
 * 21. `setBaseMetadataURI(string memory _baseURI)`: Set the base URI for all NFT metadata.
 * 22. `pauseContract()`: Pause the contract functionalities (emergency stop).
 * 23. `unpauseContract()`: Unpause the contract functionalities.
 * 24. `setAdmin(address _newAdmin)`: Change the contract administrator.
 */

contract DynamicSocialReputationNFT {
    // State Variables

    // NFT Metadata and Management
    string public baseMetadataURI; // Base URI for all NFTs, can be used to construct full URI
    mapping(uint256 => string) private _tokenMetadataURIs; // Token ID to Metadata URI mapping
    mapping(uint256 => address) private _tokenOwners; // Token ID to Owner address mapping
    uint256 private _nextTokenIdCounter; // Counter for generating unique token IDs
    uint256 private _totalSupply; // Total number of NFTs minted

    // Reputation System
    mapping(uint256 => uint256) private _reputationScores; // Token ID to Reputation Score mapping

    // Utility and Feature Unlocks
    mapping(uint256 => string[]) private _nftUtilities; // Token ID to list of Utilities
    mapping(uint256 => mapping(address => bool)) private _nftEndorsements; // Token ID to address to bool (endorsement mapping)
    mapping(uint256 => uint256) private _endorsementCounts; // Token ID to endorsement count
    mapping(uint256 => string[]) private _nftReports; // Token ID to list of report reasons
    mapping(uint256 => uint256) private _reportCounts; // Token ID to report count

    // Contract Administration
    address public admin; // Contract administrator address
    bool public paused; // Contract pause state

    // Events
    event NFTCreated(uint256 tokenId, address owner);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTBurned(uint256 tokenId, address owner);
    event ReputationIncreased(uint256 tokenId, uint256 amount, uint256 newScore);
    event ReputationDecreased(uint256 tokenId, uint256 amount, uint256 newScore);
    event ReputationSet(uint256 tokenId, uint256 newScore);
    event UtilityAdded(uint256 tokenId, string utilityDescription);
    event UtilityRemoved(uint256 tokenId, string utilityDescription);
    event NFTEndorsed(uint256 tokenId, address endorser);
    event NFTReported(uint256 tokenId, uint256 reportCount, string reportReason, address reporter);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminChanged(address oldAdmin, address newAdmin);
    event BaseMetadataURISet(string newBaseURI);


    // Modifiers
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(_tokenOwners[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    // Constructor
    constructor(string memory _baseURI) {
        admin = msg.sender;
        baseMetadataURI = _baseURI;
        paused = false;
        _nextTokenIdCounter = 1; // Start token IDs from 1 for user-friendliness
    }

    // --- NFT Management Functions ---

    /**
     * @dev Mints a new Reputation NFT for the sender.
     * @param _initialMetadataURI The initial metadata URI for the NFT.
     */
    function createReputationNFT(string memory _initialMetadataURI) public whenNotPaused returns (uint256) {
        uint256 tokenId = _nextTokenIdCounter++;
        _tokenOwners[tokenId] = msg.sender;
        _tokenMetadataURIs[tokenId] = _initialMetadataURI;
        _totalSupply++;
        emit NFTCreated(tokenId, msg.sender);
        return tokenId;
    }

    /**
     * @dev Updates the metadata URI of an existing NFT. Only the owner can call this.
     * @param _tokenId The ID of the NFT to update.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) public onlyOwnerOf(_tokenId) whenNotPaused {
        _tokenMetadataURIs[_tokenId] = _newMetadataURI;
        emit NFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Transfers ownership of an NFT to another address.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
        require(_to != address(0), "Transfer to the zero address is not allowed.");
        address from = _tokenOwners[_tokenId];
        _tokenOwners[_tokenId] = _to;
        emit NFTTransferred(_tokenId, from, _to);
    }

    /**
     * @dev Burns (destroys) an NFT. Only the owner can call this.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
        address owner = _tokenOwners[_tokenId];
        delete _tokenOwners[_tokenId];
        delete _tokenMetadataURIs[_tokenId];
        delete _reputationScores[_tokenId];
        delete _nftUtilities[_tokenId];
        delete _nftEndorsements[_tokenId];
        delete _endorsementCounts[_tokenId];
        delete _nftReports[_tokenId];
        delete _reportCounts[_tokenId];
        _totalSupply--;
        emit NFTBurned(_tokenId, owner);
    }

    /**
     * @dev Retrieves the metadata URI for a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function getNFTMetadataURI(uint256 _tokenId) public view returns (string memory) {
        return _tokenMetadataURIs[_tokenId];
    }

    /**
     * @dev Retrieves the owner of a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return The address of the NFT owner.
     */
    function getNFTOwner(uint256 _tokenId) public view returns (address) {
        return _tokenOwners[_tokenId];
    }

    /**
     * @dev Gets the total number of Reputation NFTs minted.
     * @return The total NFT supply.
     */
    function getTotalNFTSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // --- Reputation System Functions ---

    /**
     * @dev Increases the reputation score associated with an NFT. Only the owner can call this (or admin for platform-driven reputation).
     * @param _tokenId The ID of the NFT to increase reputation for.
     * @param _amount The amount to increase reputation by.
     */
    function increaseReputation(uint256 _tokenId, uint256 _amount) public whenNotPaused {
        require(_tokenOwners[_tokenId] == msg.sender || msg.sender == admin, "Only owner or admin can increase reputation.");
        _reputationScores[_tokenId] += _amount;
        emit ReputationIncreased(_tokenId, _amount, _reputationScores[_tokenId]);
    }

    /**
     * @dev Decreases the reputation score associated with an NFT. Only the owner can call this (or admin for platform-driven reputation).
     * @param _tokenId The ID of the NFT to decrease reputation for.
     * @param _amount The amount to decrease reputation by.
     */
    function decreaseReputation(uint256 _tokenId, uint256 _amount) public whenNotPaused {
        require(_tokenOwners[_tokenId] == msg.sender || msg.sender == admin, "Only owner or admin can decrease reputation.");
        // Prevent underflow
        if (_reputationScores[_tokenId] >= _amount) {
             _reputationScores[_tokenId] -= _amount;
        } else {
            _reputationScores[_tokenId] = 0; // Set to 0 if amount is larger than current score
        }
        emit ReputationDecreased(_tokenId, _amount, _reputationScores[_tokenId]);
    }

    /**
     * @dev Directly sets the reputation score of an NFT. Only admin can call this.
     * @param _tokenId The ID of the NFT to set reputation for.
     * @param _newScore The new reputation score.
     */
    function setReputationScore(uint256 _tokenId, uint256 _newScore) public onlyAdmin whenNotPaused {
        _reputationScores[_tokenId] = _newScore;
        emit ReputationSet(_tokenId, _newScore);
    }

    /**
     * @dev Retrieves the reputation score of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The reputation score.
     */
    function getReputationScore(uint256 _tokenId) public view returns (uint256) {
        return _reputationScores[_tokenId];
    }

    /**
     * @dev Compares the reputation of two NFTs and returns which has higher reputation.
     * @param _tokenId1 The ID of the first NFT.
     * @param _tokenId2 The ID of the second NFT.
     * @return 1 if tokenId1 has higher reputation, 2 if tokenId2 has higher, 0 if equal or NFTs don't exist.
     */
    function rankNFTByReputation(uint256 _tokenId1, uint256 _tokenId2) public view returns (uint8) {
        if (_tokenOwners[_tokenId1] == address(0) || _tokenOwners[_tokenId2] == address(0)) {
            return 0; // Indicate one or both NFTs don't exist
        }
        uint256 reputation1 = _reputationScores[_tokenId1];
        uint256 reputation2 = _reputationScores[_tokenId2];

        if (reputation1 > reputation2) {
            return 1;
        } else if (reputation2 > reputation1) {
            return 2;
        } else {
            return 0; // Equal reputation
        }
    }


    // --- Utility & Feature Unlocks Functions ---

    /**
     * @dev Adds a utility feature unlocked by an NFT. Only the owner can add utilities.
     * @param _tokenId The ID of the NFT.
     * @param _utilityDescription A description of the utility feature.
     */
    function addUtility(uint256 _tokenId, string memory _utilityDescription) public onlyOwnerOf(_tokenId) whenNotPaused {
        _nftUtilities[_tokenId].push(_utilityDescription);
        emit UtilityAdded(_tokenId, _utilityDescription);
    }

    /**
     * @dev Removes a utility feature from an NFT. Only the owner can remove utilities.
     * @param _tokenId The ID of the NFT.
     * @param _utilityDescription The description of the utility feature to remove.
     */
    function removeUtility(uint256 _tokenId, string memory _utilityDescription) public onlyOwnerOf(_tokenId) whenNotPaused {
        string[] storage utilities = _nftUtilities[_tokenId];
        for (uint256 i = 0; i < utilities.length; i++) {
            if (keccak256(bytes(utilities[i])) == keccak256(bytes(_utilityDescription))) {
                // Found the utility, remove it (replace with last element and pop)
                utilities[i] = utilities[utilities.length - 1];
                utilities.pop();
                emit UtilityRemoved(_tokenId, _utilityDescription);
                return;
            }
        }
        revert("Utility not found for this NFT.");
    }

    /**
     * @dev Gets a list of utilities unlocked by an NFT.
     * @param _tokenId The ID of the NFT.
     * @return An array of utility descriptions.
     */
    function getNFTUtilities(uint256 _tokenId) public view returns (string[] memory) {
        return _nftUtilities[_tokenId];
    }

    /**
     * @dev Checks if a specific utility is unlocked by an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _utilityDescription The description of the utility to check for.
     * @return True if the utility is unlocked, false otherwise.
     */
    function checkUtilityAvailability(uint256 _tokenId, string memory _utilityDescription) public view returns (bool) {
        string[] memory utilities = _nftUtilities[_tokenId];
        for (uint256 i = 0; i < utilities.length; i++) {
            if (keccak256(bytes(utilities[i])) == keccak256(bytes(_utilityDescription))) {
                return true;
            }
        }
        return false;
    }

    // --- Community & Social Features ---

    /**
     * @dev Allows users to endorse (upvote) an NFT, contributing to social reputation.
     *      Users can only endorse an NFT once.
     * @param _tokenId The ID of the NFT to endorse.
     */
    function endorseNFT(uint256 _tokenId) public whenNotPaused {
        require(_tokenOwners[_tokenId] != address(0), "NFT does not exist."); // Ensure NFT exists
        require(_tokenOwners[_tokenId] != msg.sender, "Cannot endorse your own NFT."); // Cannot endorse self
        if (!_nftEndorsements[_tokenId][msg.sender]) {
            _nftEndorsements[_tokenId][msg.sender] = true;
            _endorsementCounts[_tokenId]++;
            emit NFTEndorsed(_tokenId, msg.sender);
        } else {
            revert("You have already endorsed this NFT.");
        }
    }

    /**
     * @dev Gets the number of endorsements an NFT has received.
     * @param _tokenId The ID of the NFT.
     * @return The endorsement count.
     */
    function getEndorsementCount(uint256 _tokenId) public view returns (uint256) {
        return _endorsementCounts[_tokenId];
    }

    /**
     * @dev Allows users to report an NFT for inappropriate behavior (governance/moderation).
     * @param _tokenId The ID of the NFT being reported.
     * @param _reportReason The reason for reporting.
     */
    function reportNFT(uint256 _tokenId, string memory _reportReason) public whenNotPaused {
        require(_tokenOwners[_tokenId] != address(0), "NFT does not exist."); // Ensure NFT exists
        _nftReports[_tokenId].push(_reportReason);
        _reportCounts[_tokenId]++;
        emit NFTReported(_tokenId, _reportCounts[_tokenId], _reportReason, msg.sender);
    }

    /**
     * @dev Gets the number of reports an NFT has received.
     * @param _tokenId The ID of the NFT.
     * @return The report count.
     */
    function getReportCount(uint256 _tokenId) public view returns (uint256) {
        return _reportCounts[_tokenId];
    }


    // --- Platform Management Functions (Admin Only) ---

    /**
     * @dev Sets the base metadata URI for all NFTs. Only admin can call this.
     * @param _baseURI The new base metadata URI.
     */
    function setBaseMetadataURI(string memory _baseURI) public onlyAdmin whenNotPaused {
        baseMetadataURI = _baseURI;
        emit BaseMetadataURISet(_baseURI);
    }

    /**
     * @dev Pauses the contract, preventing most functionalities. Only admin can call this.
     */
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /**
     * @dev Unpauses the contract, restoring functionalities. Only admin can call this.
     */
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /**
     * @dev Sets a new admin address. Only the current admin can call this.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) public onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "New admin address cannot be the zero address.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    // Fallback function to receive Ether (if needed for future features)
    receive() external payable {}
    fallback() external payable {}
}
```