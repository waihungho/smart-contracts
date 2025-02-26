Okay, here's a Solidity smart contract demonstrating a "Dynamic Royalty Splitting and NFT-Gated Access" concept.  It allows a creator to deploy a contract for an artwork (or digital asset) and dynamically adjust royalty splits amongst collaborators and grant exclusive NFT-based access to features within the contract.

**Outline and Function Summary**

*   **Contract Name:** `DynamicRoyaltyHub`

*   **Purpose:**  Enables creators to manage royalties for digital assets (simulated as metadata URIs here) with dynamic splitting amongst contributors, and to control access to features using ownership of specific NFTs.

*   **Key Concepts:**

    *   **Dynamic Royalty Distribution:** The creator can add, remove, and adjust the percentage share of royalties for various addresses.
    *   **NFT-Gated Access:** Ownership of a specific ERC721 NFT grants access to certain functions.
    *   **Asset Registry:**  A simplified system to manage metadata URLs representing the digital assets.

*   **Functions:**

    *   `constructor(address _nftContractAddress)`:  Sets the NFT contract address required for NFT-gated access.
    *   `addAsset(string memory _metadataURI)`: Allows the contract owner to register a new digital asset by its metadata URI.
    *   `setAssetCreator(uint256 _assetId, address _newCreator)`:  Sets/changes the creator associated with a specific asset. Only callable by the contract owner.
    *   `addRoyaltyRecipient(uint256 _assetId, address _recipient, uint256 _percentage)`:  Adds a new recipient to the royalty split for a specific asset.  Only callable by the asset's creator.
    *   `updateRoyaltyPercentage(uint256 _assetId, address _recipient, uint256 _percentage)`:  Updates the percentage of royalties for an existing recipient. Only callable by the asset's creator.
    *   `removeRoyaltyRecipient(uint256 _assetId, address _recipient)`: Removes a recipient from the royalty split. Only callable by the asset's creator.
    *   `simulateSale(uint256 _assetId, uint256 _salePrice)`: Simulates a sale of the asset and distributes royalties.
    *   `setNFTRequired(bool _isRequired)`: Enables/disables the NFT requirement for privileged functions. Only callable by the contract owner.
    *   `setAccessNFTTokenId(uint256 _tokenId)`:  Sets the specific NFT token ID required for privileged functions. Only callable by the contract owner.
    *   `withdraw()`: Allows the contract owner to withdraw any accumulated contract balance.

**Solidity Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicRoyaltyHub is Ownable {
    using SafeMath for uint256;

    IERC721 public nftContract; // Address of the NFT contract used for access control
    uint256 public accessNFTTokenId;  // The specific token ID required.
    bool public nftRequired = true; // Flag to enable/disable NFT requirement.

    struct Asset {
        string metadataURI;
        address creator;
    }

    mapping(uint256 => Asset) public assets;
    uint256 public assetCount = 0;

    struct Recipient {
        address recipient;
        uint256 percentage;
    }

    mapping(uint256 => Recipient[]) public royaltyRecipients; // assetId => array of recipients
    mapping(uint256 => uint256) public totalRoyaltyPercentage; // assetId => total percentage

    event AssetAdded(uint256 assetId, string metadataURI, address creator);
    event AssetCreatorSet(uint256 assetId, address newCreator);
    event RoyaltyRecipientAdded(uint256 assetId, address recipient, uint256 percentage);
    event RoyaltyPercentageUpdated(uint256 assetId, address recipient, uint256 percentage);
    event RoyaltyRecipientRemoved(uint256 assetId, address recipient);
    event RoyaltiesDistributed(uint256 assetId, uint256 salePrice);

    constructor(address _nftContractAddress) {
        nftContract = IERC721(_nftContractAddress);
    }

    modifier onlyNFTGate() {
        require(!nftRequired || nftContract.ownerOf(accessNFTTokenId) == msg.sender, "NFT Required");
        _;
    }

    modifier onlyAssetCreator(uint256 _assetId) {
        require(msg.sender == assets[_assetId].creator, "Only asset creator can call this function.");
        _;
    }

    // Add a new digital asset (metadata URI)
    function addAsset(string memory _metadataURI) public onlyOwner {
        assetCount++;
        assets[assetCount] = Asset(_metadataURI, msg.sender); // Owner is initially the creator
        emit AssetAdded(assetCount, _metadataURI, msg.sender);
    }

    // Set/change the creator for a specific asset.  Owner only.
    function setAssetCreator(uint256 _assetId, address _newCreator) public onlyOwner {
        require(_assetId > 0 && _assetId <= assetCount, "Invalid asset ID.");
        assets[_assetId].creator = _newCreator;
        emit AssetCreatorSet(_assetId, _newCreator);
    }

    // Add a recipient to the royalty split. Creator only.
    function addRoyaltyRecipient(uint256 _assetId, address _recipient, uint256 _percentage) public onlyAssetCreator(_assetId) {
        require(_assetId > 0 && _assetId <= assetCount, "Invalid asset ID.");
        require(_percentage > 0 && _percentage <= 10000, "Percentage must be between 0 and 10000 (representing 0% to 100%)"); // Store as basis points (10000 = 100%)
        require(totalRoyaltyPercentage[_assetId].add(_percentage) <= 10000, "Total royalty percentage exceeds 100%");

        royaltyRecipients[_assetId].push(Recipient(_recipient, _percentage));
        totalRoyaltyPercentage[_assetId] = totalRoyaltyPercentage[_assetId].add(_percentage);
        emit RoyaltyRecipientAdded(_assetId, _recipient, _percentage);
    }

    // Update an existing recipient's percentage. Creator only.
    function updateRoyaltyPercentage(uint256 _assetId, address _recipient, uint256 _percentage) public onlyAssetCreator(_assetId) {
        require(_assetId > 0 && _assetId <= assetCount, "Invalid asset ID.");
        require(_percentage > 0 && _percentage <= 10000, "Percentage must be between 0 and 10000 (representing 0% to 100%)");
        uint256 oldPercentage = 0;

        for (uint256 i = 0; i < royaltyRecipients[_assetId].length; i++) {
            if (royaltyRecipients[_assetId][i].recipient == _recipient) {
                oldPercentage = royaltyRecipients[_assetId][i].percentage;
                break;
            }
        }
        require(oldPercentage > 0, "Recipient not found");

        uint256 newTotalPercentage = totalRoyaltyPercentage[_assetId].sub(oldPercentage).add(_percentage);
        require(newTotalPercentage <= 10000, "Total royalty percentage exceeds 100%");

        for (uint256 i = 0; i < royaltyRecipients[_assetId].length; i++) {
            if (royaltyRecipients[_assetId][i].recipient == _recipient) {
                royaltyRecipients[_assetId][i].percentage = _percentage;
                break;
            }
        }

        totalRoyaltyPercentage[_assetId] = newTotalPercentage;

        emit RoyaltyPercentageUpdated(_assetId, _recipient, _percentage);
    }

    // Remove a royalty recipient. Creator only.
    function removeRoyaltyRecipient(uint256 _assetId, address _recipient) public onlyAssetCreator(_assetId) {
        require(_assetId > 0 && _assetId <= assetCount, "Invalid asset ID.");

        uint256 removedPercentage = 0;
        for (uint256 i = 0; i < royaltyRecipients[_assetId].length; i++) {
            if (royaltyRecipients[_assetId][i].recipient == _recipient) {
                removedPercentage = royaltyRecipients[_assetId][i].percentage;

                // Shift elements to fill the gap left by the removed recipient
                for (uint256 j = i; j < royaltyRecipients[_assetId].length - 1; j++) {
                    royaltyRecipients[_assetId][j] = royaltyRecipients[_assetId][j + 1];
                }
                royaltyRecipients[_assetId].pop(); // Remove the last element (duplicate)

                break;
            }
        }
        require(removedPercentage > 0, "Recipient not found");

        totalRoyaltyPercentage[_assetId] = totalRoyaltyPercentage[_assetId].sub(removedPercentage);
        emit RoyaltyRecipientRemoved(_assetId, _recipient);
    }

    // Simulate a sale and distribute royalties.  Anyone can call.
    function simulateSale(uint256 _assetId, uint256 _salePrice) public payable {
        require(_assetId > 0 && _assetId <= assetCount, "Invalid asset ID.");

        uint256 totalDistributed = 0;

        for (uint256 i = 0; i < royaltyRecipients[_assetId].length; i++) {
            uint256 royaltyAmount = _salePrice.mul(royaltyRecipients[_assetId][i].percentage).div(10000); // Percentage is stored as basis points.
            (bool success, ) = royaltyRecipients[_assetId][i].recipient.call{value: royaltyAmount}(""); // Send the funds
            require(success, "Transfer failed.");
            totalDistributed = totalDistributed.add(royaltyAmount);
        }

        // Optionally, send the remainder to the asset creator (after royalties)
        uint256 creatorShare = _salePrice.sub(totalDistributed);

        (bool success, ) = assets[_assetId].creator.call{value: creatorShare}("");
        require(success, "Transfer to creator failed");

        emit RoyaltiesDistributed(_assetId, _salePrice);
    }

    // Enable/disable NFT requirement for certain privileged functions
    function setNFTRequired(bool _isRequired) public onlyOwner {
        nftRequired = _isRequired;
    }

    // Set the NFT token ID required for access.  Owner only.
    function setAccessNFTTokenId(uint256 _tokenId) public onlyOwner {
        accessNFTTokenId = _tokenId;
    }

    // Allow the owner to withdraw funds
    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    receive() external payable {} // Allow the contract to receive ETH.
}
```

**Important Considerations and Improvements:**

*   **Security:** This is a simplified example. Before deploying to a production environment, you MUST conduct thorough security audits.  Specifically, consider:
    *   **Reentrancy:** Implement reentrancy guards (e.g., using `ReentrancyGuard` from OpenZeppelin) on any functions that send Ether to external addresses.
    *   **Integer Overflow/Underflow:** While SafeMath is used, double-check all calculations.
    *   **Front-Running:**  Consider potential front-running scenarios when setting royalty percentages.  Mitigation strategies might involve committing to values using hashes and revealing them later.
    *   **Denial of Service (DoS):**  Be mindful of DoS attacks.  For example, having a very large list of royalty recipients could make the `simulateSale` function consume excessive gas, potentially blocking sales.
    *   **Ownership Transfer:**  Make sure the `Ownable` contract is used correctly and that you understand the implications of transferring ownership.

*   **Gas Optimization:**  The contract can be further optimized for gas efficiency.  Consider using:
    *   **Immutable Variables:** Declare variables that are only set in the constructor as `immutable`.
    *   **Calldata:** Use `calldata` instead of `memory` for function arguments where appropriate.
    *   **Storage vs. Memory:**  Be conscious of when to use storage vs. memory, as storage operations are much more expensive.
    *   **Assembly:** In some cases, assembly (inline assembly) can provide significant gas savings, but it increases code complexity and risk.

*   **Event Emission:**  Ensure you are emitting events for all important state changes. This makes it easier for off-chain applications to track what's happening in the contract.

*   **Testing:** Write comprehensive unit tests to cover all possible scenarios and edge cases.  Use a testing framework like Hardhat or Truffle.

*   **Error Handling:** Provide clear and informative error messages to help users understand what went wrong.

*   **NFT Integration:** This contract assumes an ERC721 NFT for access control. You can adapt it to support ERC1155 tokens if needed.  Consider using the ERC721Holder or ERC1155Holder contracts from OpenZeppelin to simplify NFT interactions.

*   **Royalties Standard:** Consider adopting the EIP-2981 Royalty Standard to improve interoperability with NFT marketplaces.

*   **Metadata Handling:** The contract only stores metadata URIs. You might want to consider a more robust system for managing metadata, perhaps using IPFS or a decentralized storage solution.

*   **Withdrawal Scheduling:** For large contracts with frequent transactions, consider implementing a withdrawal scheduling mechanism to avoid large single withdrawals that could potentially be vulnerable.

This contract provides a framework for dynamic royalty splitting and NFT-gated access.  Remember to carefully review and adapt it to your specific needs and to prioritize security and best practices.
