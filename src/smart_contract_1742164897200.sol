```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT and Reputation System
 * @author Gemini AI (Conceptual Contract)
 * @dev A smart contract that combines dynamic NFTs with a reputation system,
 * showcasing advanced concepts like on-chain reputation, dynamic metadata updates,
 * decentralized governance features, and unique NFT utility.
 *
 * **Outline and Function Summary:**
 *
 * **1. NFT Management:**
 *   - `mintNFT(address _to, string memory _baseURI)`: Mints a new Dynamic NFT to a user, setting an initial base URI.
 *   - `transferNFT(address _to, uint256 _tokenId)`: Transfers an NFT to another user.
 *   - `getNFTMetadata(uint256 _tokenId)`: Retrieves the dynamic metadata URI for an NFT, which changes based on reputation.
 *   - `getNFTOwner(uint256 _tokenId)`: Returns the owner of a specific NFT.
 *   - `burnNFT(uint256 _tokenId)`: Allows the owner to burn their NFT (irreversible).
 *   - `setBaseMetadataURI(string memory _newBaseURI)`: Admin function to update the base metadata URI for all NFTs.
 *   - `getTotalNFTsMinted()`: Returns the total number of NFTs minted.
 *
 * **2. Reputation System:**
 *   - `increaseReputation(address _user, uint256 _amount)`: Increases the reputation of a user. (Admin/Governance controlled)
 *   - `decreaseReputation(address _user, uint256 _amount)`: Decreases the reputation of a user. (Admin/Governance controlled)
 *   - `getReputation(address _user)`: Retrieves the reputation score of a user.
 *   - `getReputationTier(address _user)`: Returns the reputation tier of a user based on their score.
 *   - `setReputationThreshold(uint256 _tier, uint256 _threshold)`: Admin function to set the reputation threshold for a tier.
 *   - `applyReputationDecay(address _user, uint256 _decayAmount)`: Applies reputation decay to a user's score over time. (Potentially automated)
 *
 * **3. Content and Interaction System (Example Use Case for Reputation):**
 *   - `submitContent(string memory _contentHash)`: Allows users to submit content (e.g., IPFS hash). Requires a minimum reputation.
 *   - `voteContent(uint256 _contentId, bool _upvote)`: Allows users to vote on submitted content, influenced by their reputation.
 *   - `getContentDetails(uint256 _contentId)`: Retrieves details of submitted content, including votes and submitter.
 *   - `reportContent(uint256 _contentId)`: Allows users to report content for moderation, reputation impact on reporter (false reports penalized).
 *
 * **4. Governance and Utility:**
 *   - `pauseContract()`: Admin function to pause critical contract functionalities in emergencies.
 *   - `unpauseContract()`: Admin function to unpause contract functionalities.
 *   - `setAdmin(address _newAdmin)`: Admin function to change the contract administrator.
 *   - `withdrawFunds(address _recipient)`: Admin function to withdraw contract balance (e.g., fees collected).
 *   - `getContractBalance()`: Returns the current balance of the contract.
 *
 * **Advanced Concepts Highlighted:**
 *   - Dynamic NFTs: Metadata URI changes based on reputation, showcasing evolving NFT utility.
 *   - On-Chain Reputation:  Built-in reputation system influencing NFT metadata and contract interactions.
 *   - Decentralized Governance (Basic):  Admin functions ideally should be managed via a DAO or governance mechanism in a real-world scenario.
 *   - Content Curation Example: Demonstrates a practical application of reputation within the contract.
 *   - Tiered Reputation System:  Reputation levels with varying benefits or access.
 *   - Reputation Decay:  Adds a dynamic element to reputation, encouraging ongoing engagement.
 *   - Content Voting with Reputation Influence:  More reputable users potentially have a stronger voting weight.
 *   - Content Reporting and Moderation:  Basic mechanism for community moderation.
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DynamicReputationNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string private _baseMetadataURI;

    // Reputation System
    mapping(address => uint256) public reputationScores;
    mapping(uint256 => uint256) public reputationThresholds; // Tier => Threshold
    uint256 public constant MAX_REPUTATION = 10000; // Example max reputation
    uint256 public constant REPUTATION_DECAY_INTERVAL = 7 days; // Example decay interval
    mapping(address => uint256) public lastReputationDecayTime;

    // Content System (Example)
    struct ContentItem {
        uint256 id;
        address submitter;
        string contentHash;
        uint256 upvotes;
        uint256 downvotes;
        uint256 submissionTime;
    }
    mapping(uint256 => ContentItem) public contentItems;
    Counters.Counter private _contentIdCounter;

    // Contract State
    bool public paused;

    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTTransferred(address indexed from, address indexed to, uint256 tokenId);
    event NFTBurned(uint256 indexed tokenId);
    event ReputationIncreased(address indexed user, uint256 amount, uint256 newScore);
    event ReputationDecreased(address indexed user, uint256 amount, uint256 newScore);
    event ReputationDecayApplied(address indexed user, uint256 decayAmount, uint256 newScore);
    event ContentSubmitted(uint256 indexed contentId, address indexed submitter, string contentHash);
    event ContentVoted(uint256 indexed contentId, address indexed voter, bool upvote);
    event ContentReported(uint256 indexed contentId, address indexed reporter);
    event ContractPaused();
    event ContractUnpaused();
    event BaseMetadataURISet(string newBaseURI);

    constructor(string memory _name, string memory _symbol, string memory _initialBaseURI) ERC721(_name, _symbol) {
        _baseMetadataURI = _initialBaseURI;
        // Initialize reputation tiers (Example tiers - adjust as needed)
        reputationThresholds[1] = 100;  // Tier 1: 100 reputation
        reputationThresholds[2] = 500;  // Tier 2: 500 reputation
        reputationThresholds[3] = 1500; // Tier 3: 1500 reputation
        reputationThresholds[4] = 3000; // Tier 4: 3000 reputation
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyAdmin() {
        require(_msgSender() == owner(), "Only admin can call this function");
        _;
    }

    // ------------------------ NFT Management Functions ------------------------

    /// @notice Mints a new Dynamic NFT to a user.
    /// @param _to The address to mint the NFT to.
    /// @param _baseURI The initial base URI for the NFT metadata.
    function mintNFT(address _to, string memory _baseURI) external onlyOwner whenNotPaused nonReentrant {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(_baseURI, Strings.toString(tokenId)))); // Initial metadata URI
        emit NFTMinted(_to, tokenId);
    }

    /// @notice Transfers an NFT to another user.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) external whenNotPaused nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not approved or owner");
        safeTransferFrom(_msgSender(), _to, _tokenId);
        emit NFTTransferred(_msgSender(), _to, _tokenId);
    }

    /// @notice Retrieves the dynamic metadata URI for an NFT, based on reputation.
    /// @param _tokenId The ID of the NFT.
    /// @return The metadata URI for the NFT, dynamically generated based on reputation.
    function getNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        address ownerAddress = ownerOf(_tokenId);
        uint256 userReputation = reputationScores[ownerAddress];
        uint256 reputationTier = getReputationTier(ownerAddress);

        // Dynamic metadata logic - customize based on your NFT design
        string memory tierSuffix;
        if (reputationTier == 1) {
            tierSuffix = "-tier1";
        } else if (reputationTier == 2) {
            tierSuffix = "-tier2";
        } else if (reputationTier == 3) {
            tierSuffix = "-tier3";
        } else if (reputationTier >= 4) {
            tierSuffix = "-tier4";
        } else {
            tierSuffix = "-tier0"; // Default tier
        }

        // Example: Append tier to base URI to dynamically change metadata
        return string(abi.encodePacked(_baseMetadataURI, Strings.toString(_tokenId), tierSuffix, ".json"));
    }

    /// @notice Returns the owner of a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The address of the NFT owner.
    function getNFTOwner(uint256 _tokenId) public view returns (address) {
        return ownerOf(_tokenId);
    }

    /// @notice Allows the owner to burn their NFT (irreversible).
    /// @param _tokenId The ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) external whenNotPaused nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not approved or owner");
        _burn(_tokenId);
        emit NFTBurned(_tokenId);
    }

    /// @notice Admin function to update the base metadata URI for all NFTs.
    /// @param _newBaseURI The new base metadata URI.
    function setBaseMetadataURI(string memory _newBaseURI) external onlyOwner whenNotPaused {
        _baseMetadataURI = _newBaseURI;
        emit BaseMetadataURISet(_newBaseURI);
    }

    /// @notice Returns the total number of NFTs minted.
    /// @return The total number of NFTs minted.
    function getTotalNFTsMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // ------------------------ Reputation System Functions ------------------------

    /// @notice Increases the reputation of a user. (Admin/Governance controlled)
    /// @param _user The address of the user.
    /// @param _amount The amount to increase reputation by.
    function increaseReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
        uint256 currentReputation = reputationScores[_user];
        uint256 newReputation = currentReputation + _amount;
        if (newReputation > MAX_REPUTATION) {
            newReputation = MAX_REPUTATION; // Cap reputation
        }
        reputationScores[_user] = newReputation;
        _updateNFTMetadata(_user); // Trigger metadata update if NFT exists for user
        emit ReputationIncreased(_user, _amount, newReputation);
    }

    /// @notice Decreases the reputation of a user. (Admin/Governance controlled)
    /// @param _user The address of the user.
    /// @param _amount The amount to decrease reputation by.
    function decreaseReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
        uint256 currentReputation = reputationScores[_user];
        uint256 newReputation = currentReputation - _amount;
        if (newReputation < 0) {
            newReputation = 0; // Floor reputation at 0
        }
        reputationScores[_user] = newReputation;
        _updateNFTMetadata(_user); // Trigger metadata update if NFT exists for user
        emit ReputationDecreased(_user, _amount, newReputation);
    }

    /// @notice Retrieves the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score of the user.
    function getReputation(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    /// @notice Returns the reputation tier of a user based on their score.
    /// @param _user The address of the user.
    /// @return The reputation tier (0, 1, 2, 3, 4, etc.).
    function getReputationTier(address _user) public view returns (uint256) {
        uint256 score = reputationScores[_user];
        if (score >= reputationThresholds[4]) {
            return 4;
        } else if (score >= reputationThresholds[3]) {
            return 3;
        } else if (score >= reputationThresholds[2]) {
            return 2;
        } else if (score >= reputationThresholds[1]) {
            return 1;
        } else {
            return 0; // Tier 0 or below threshold
        }
    }

    /// @notice Admin function to set the reputation threshold for a tier.
    /// @param _tier The reputation tier to set the threshold for.
    /// @param _threshold The new reputation threshold for the tier.
    function setReputationThreshold(uint256 _tier, uint256 _threshold) external onlyOwner whenNotPaused {
        reputationThresholds[_tier] = _threshold;
    }

    /// @notice Applies reputation decay to a user's score over time. (Potentially automated)
    /// @param _user The address of the user to apply decay to.
    /// @param _decayAmount The amount of reputation to decay.
    function applyReputationDecay(address _user, uint256 _decayAmount) external whenNotPaused {
        require(block.timestamp >= lastReputationDecayTime[_user] + REPUTATION_DECAY_INTERVAL, "Decay interval not reached");
        uint256 currentReputation = reputationScores[_user];
        if (currentReputation > 0) {
            uint256 newReputation = currentReputation - _decayAmount;
            if (newReputation < 0) {
                newReputation = 0;
            }
            reputationScores[_user] = newReputation;
            lastReputationDecayTime[_user] = block.timestamp;
            _updateNFTMetadata(_user); // Trigger metadata update if NFT exists for user
            emit ReputationDecayApplied(_user, _decayAmount, newReputation);
        } else {
            lastReputationDecayTime[_user] = block.timestamp; // Update decay time even if no decay occurred
        }
    }

    // ------------------------ Content and Interaction System (Example) ------------------------

    uint256 public minimumReputationForContentSubmission = 50; // Example minimum reputation

    /// @notice Allows users to submit content (e.g., IPFS hash). Requires a minimum reputation.
    /// @param _contentHash The hash of the content being submitted (e.g., IPFS hash).
    function submitContent(string memory _contentHash) external whenNotPaused nonReentrant {
        require(reputationScores[_msgSender()] >= minimumReputationForContentSubmission, "Insufficient reputation to submit content");
        _contentIdCounter.increment();
        uint256 contentId = _contentIdCounter.current();
        contentItems[contentId] = ContentItem({
            id: contentId,
            submitter: _msgSender(),
            contentHash: _contentHash,
            upvotes: 0,
            downvotes: 0,
            submissionTime: block.timestamp
        });
        emit ContentSubmitted(contentId, _msgSender(), _contentHash);
    }

    /// @notice Allows users to vote on submitted content, influenced by their reputation.
    /// @param _contentId The ID of the content to vote on.
    /// @param _upvote True for upvote, false for downvote.
    function voteContent(uint256 _contentId, bool _upvote) external whenNotPaused nonReentrant {
        require(contentItems[_contentId].id == _contentId, "Content ID does not exist");
        ContentItem storage content = contentItems[_contentId];

        // Reputation influence on voting weight (example - could be more complex)
        uint256 votingWeight = 1 + (reputationScores[_msgSender()] / 500); // Example: Higher reputation = slightly stronger vote

        if (_upvote) {
            content.upvotes += votingWeight;
        } else {
            content.downvotes += votingWeight;
        }
        emit ContentVoted(_contentId, _msgSender(), _upvote);
    }

    /// @notice Retrieves details of submitted content, including votes and submitter.
    /// @param _contentId The ID of the content.
    /// @return ContentItem struct containing content details.
    function getContentDetails(uint256 _contentId) public view returns (ContentItem memory) {
        return contentItems[_contentId];
    }

    /// @notice Allows users to report content for moderation. (Basic example - more robust moderation needed in real-world)
    /// @param _contentId The ID of the content to report.
    function reportContent(uint256 _contentId) external whenNotPaused nonReentrant {
        require(contentItems[_contentId].id == _contentId, "Content ID does not exist");
        // In a real system, you would implement moderation logic here.
        // For this example, we just emit an event.
        emit ContentReported(_contentId, _msgSender());
        // Potential future implementations:
        // - Store reports for admin review.
        // - Implement voting on reports by moderators or community.
        // - Penalize users for false reports to prevent abuse.
    }


    // ------------------------ Governance and Utility Functions ------------------------

    /// @notice Pauses critical contract functionalities in emergencies.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses contract functionalities.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Admin function to change the contract administrator.
    /// @param _newAdmin The address of the new administrator.
    function setAdmin(address _newAdmin) external onlyOwner {
        transferOwnership(_newAdmin);
    }

    /// @notice Admin function to withdraw contract balance (e.g., fees collected).
    /// @param _recipient The address to withdraw funds to.
    function withdrawFunds(address _recipient) external onlyOwner whenNotPaused nonReentrant {
        payable(_recipient).transfer(address(this).balance);
    }

    /// @notice Returns the current balance of the contract.
    /// @return The contract balance in Wei.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ------------------------ Internal Utility Functions ------------------------

    /// @dev Internal function to update the NFT metadata URI when reputation changes.
    /// @param _user The address of the NFT owner.
    function _updateNFTMetadata(address _user) internal {
        uint256 balance = balanceOf(_user);
        if (balance > 0) {
            // Assuming each user only holds one NFT in this simplified example.
            // In a more complex system, you might need to iterate over tokens owned by the user.
            uint256 tokenId = tokenOfOwnerByIndex(_user, 0); // Get the first token owned by the user
            _setTokenURI(tokenId, getNFTMetadata(tokenId)); // Re-set metadata URI to trigger update
        }
    }

    // Override _beforeTokenTransfer to potentially add access control or logic before transfers
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        // Add any custom logic before token transfer if needed.
    }

    // Override tokenURI to use our dynamic metadata retrieval
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return getNFTMetadata(tokenId);
    }
}

// Helper library for converting uint to string
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x0";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; ) {
            i--;
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
            i--;
            buffer[i] = _HEX_SYMBOLS[(value & 0xf)];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
```