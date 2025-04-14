```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Metaverse Asset Marketplace & Management - "MetaVerseMarket"
 * @author Bard (AI Assistant)
 * @dev A smart contract for managing and trading virtual assets within a metaverse.
 *      This contract implements advanced concepts like dynamic asset attributes,
 *      reputation-based features, decentralized governance for asset evolution,
 *      and mechanisms for in-world asset utility.
 *
 * **Outline & Function Summary:**
 *
 * **1. Asset Management:**
 *    - `mintAsset(string memory _assetName, string memory _assetType, string memory _assetMetadata)`: Allows contract owner to mint new metaverse assets.
 *    - `burnAsset(uint256 _assetId)`: Allows asset owner to burn/destroy their asset.
 *    - `transferAsset(address _to, uint256 _assetId)`: Allows asset owner to transfer asset to another address.
 *    - `setAssetMetadata(uint256 _assetId, string memory _newMetadata)`: Allows asset owner to update asset metadata (within limits).
 *    - `getAssetMetadata(uint256 _assetId) view returns (string memory)`: Retrieves asset metadata.
 *    - `getAssetOwner(uint256 _assetId) view returns (address)`: Retrieves the owner of an asset.
 *    - `getTotalAssets() view returns (uint256)`: Returns the total number of assets minted.
 *    - `getAssetsOfOwner(address _owner) view returns (uint256[] memory)`: Returns a list of asset IDs owned by a specific address.
 *
 * **2. Dynamic Asset Attributes & Evolution:**
 *    - `setAttribute(uint256 _assetId, string memory _attributeName, string memory _attributeValue)`: Allows asset owner to set custom attributes.
 *    - `getAttribute(uint256 _assetId, string memory _attributeName) view returns (string memory)`: Retrieves a specific asset attribute.
 *    - `evolveAsset(uint256 _assetId, string memory _evolutionData)`: Allows asset owner to trigger asset evolution based on predefined rules (requires governance or oracle in real-world).
 *
 * **3. Marketplace Functionality:**
 *    - `listAssetForSale(uint256 _assetId, uint256 _price)`: Allows asset owner to list their asset for sale in the marketplace.
 *    - `buyAsset(uint256 _listingId)`: Allows anyone to buy a listed asset.
 *    - `cancelListing(uint256 _listingId)`: Allows asset owner to cancel a listing.
 *    - `getListingDetails(uint256 _listingId) view returns (tuple(uint256 assetId, address seller, uint256 price, bool isActive))`: Retrieves details of a marketplace listing.
 *    - `getAllListings() view returns (uint256[] memory)`: Returns a list of all active listing IDs.
 *
 * **4. Reputation & Community Features:**
 *    - `reportAsset(uint256 _assetId, string memory _reportReason)`: Allows users to report assets for inappropriate content (governance needed to act on reports).
 *    - `getUserReputation(address _user) view returns (uint256)`: Retrieves a user's reputation score (initially based on asset ownership, can be expanded).
 *    - `endorseUser(address _user)`: Allows users to endorse other users, potentially increasing reputation.
 *
 * **5. Metaverse Utility & Interaction (Conceptual):**
 *    - `useAssetInMetaverse(uint256 _assetId, string memory _action)`:  A placeholder for triggering in-metaverse actions using assets (requires external metaverse integration).
 *    - `stakeAssetForUtility(uint256 _assetId, uint256 _duration)`: Allows users to stake assets for in-metaverse benefits (e.g., access to features, resources - conceptual).
 *    - `unstakeAssetForUtility(uint256 _assetId)`: Allows users to unstake assets.
 *
 * **6. Governance (Simple Example - Can be expanded):**
 *    - `proposeMarketplaceFeeChange(uint256 _newFee)`: Allows users with reputation to propose changes (simple example, needs voting mechanism in real-world).
 *    - `getMarketplaceFee() view returns (uint256)`: Returns the current marketplace fee (conceptual).
 */
contract MetaVerseMarket {
    // --- State Variables ---

    address public owner;
    uint256 public assetCounter;
    uint256 public listingCounter;
    uint256 public marketplaceFee = 100; // 1% Fee (example)

    struct Asset {
        string assetName;
        string assetType;
        string assetMetadata;
        address owner;
        mapping(string => string) attributes; // Dynamic attributes
        uint256 reputationScore; // Example reputation associated with asset
    }

    struct Listing {
        uint256 assetId;
        address seller;
        uint256 price;
        bool isActive;
    }

    mapping(uint256 => Asset) public assets;
    mapping(uint256 => Listing) public listings;
    mapping(address => uint256) public userReputation; // Simple reputation system
    mapping(uint256 => uint256) public assetToListingId; // Map assetId to listingId for quick lookup
    mapping(uint256 => bool) public activeListings; // Track active listing IDs for iteration

    // --- Events ---

    event AssetMinted(uint256 assetId, address owner, string assetName, string assetType);
    event AssetBurned(uint256 assetId, address owner);
    event AssetTransferred(uint256 assetId, address from, address to);
    event AssetMetadataUpdated(uint256 assetId, string newMetadata);
    event AssetAttributeSet(uint256 assetId, string attributeName, string attributeValue);
    event AssetEvolved(uint256 assetId, string evolutionData);
    event AssetListedForSale(uint256 listingId, uint256 assetId, address seller, uint256 price);
    event AssetBought(uint256 listingId, uint256 assetId, address buyer, address seller, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 assetId);
    event AssetReported(uint256 assetId, address reporter, string reason);
    event UserEndorsed(address endorser, address endorsedUser);
    event AssetStakedForUtility(uint256 assetId, address staker, uint256 duration);
    event AssetUnstakedFromUtility(uint256 assetId, address unstaker);
    event MarketplaceFeeChangeProposed(uint256 newFee, address proposer);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAssetOwner(uint256 _assetId) {
        require(assets[_assetId].owner == msg.sender, "You are not the asset owner.");
        _;
    }

    modifier validAssetId(uint256 _assetId) {
        require(_assetId > 0 && _assetId <= assetCounter, "Invalid asset ID.");
        _;
    }

    modifier validListingId(uint256 _listingId) {
        require(_listingId > 0 && listings[_listingId].isActive, "Invalid or inactive listing ID.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        assetCounter = 0;
        listingCounter = 0;
    }

    // --- 1. Asset Management Functions ---

    /**
     * @dev Mints a new metaverse asset. Only contract owner can call this.
     * @param _assetName Name of the asset.
     * @param _assetType Type of the asset (e.g., "Land", "Avatar", "Item").
     * @param _assetMetadata JSON string or URI containing asset details.
     */
    function mintAsset(string memory _assetName, string memory _assetType, string memory _assetMetadata) public onlyOwner {
        assetCounter++;
        assets[assetCounter] = Asset({
            assetName: _assetName,
            assetType: _assetType,
            assetMetadata: _assetMetadata,
            owner: msg.sender, // Initially owned by minter (contract owner in this example)
            reputationScore: 0 // Initial reputation
        });
        emit AssetMinted(assetCounter, msg.sender, _assetName, _assetType);
    }

    /**
     * @dev Burns (destroys) an asset. Only asset owner can call this.
     * @param _assetId ID of the asset to burn.
     */
    function burnAsset(uint256 _assetId) public onlyAssetOwner(_assetId) validAssetId(_assetId) {
        address assetOwner = assets[_assetId].owner;
        delete assets[_assetId];
        emit AssetBurned(_assetId, assetOwner);
    }

    /**
     * @dev Transfers an asset to a new owner. Only asset owner can call this.
     * @param _to Address of the new owner.
     * @param _assetId ID of the asset to transfer.
     */
    function transferAsset(address _to, uint256 _assetId) public onlyAssetOwner(_assetId) validAssetId(_assetId) {
        require(_to != address(0), "Invalid recipient address.");
        assets[_assetId].owner = _to;
        emit AssetTransferred(_assetId, msg.sender, _to);
    }

    /**
     * @dev Sets or updates the metadata of an asset. Only asset owner can call this.
     * @param _assetId ID of the asset to update.
     * @param _newMetadata New metadata string or URI.
     */
    function setAssetMetadata(uint256 _assetId, string memory _newMetadata) public onlyAssetOwner(_assetId) validAssetId(_assetId) {
        assets[_assetId].assetMetadata = _newMetadata;
        emit AssetMetadataUpdated(_assetId, _newMetadata);
    }

    /**
     * @dev Retrieves the metadata of an asset.
     * @param _assetId ID of the asset.
     * @return Asset metadata string.
     */
    function getAssetMetadata(uint256 _assetId) public view validAssetId(_assetId) returns (string memory) {
        return assets[_assetId].assetMetadata;
    }

    /**
     * @dev Retrieves the owner of an asset.
     * @param _assetId ID of the asset.
     * @return Address of the asset owner.
     */
    function getAssetOwner(uint256 _assetId) public view validAssetId(_assetId) returns (address) {
        return assets[_assetId].owner;
    }

    /**
     * @dev Returns the total number of assets minted.
     * @return Total asset count.
     */
    function getTotalAssets() public view returns (uint256) {
        return assetCounter;
    }

    /**
     * @dev Returns a list of asset IDs owned by a specific address.
     * @param _owner Address to query for assets.
     * @return Array of asset IDs.
     */
    function getAssetsOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256[] memory ownedAssets = new uint256[](assetCounter); // Maximum possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= assetCounter; i++) {
            if (assets[i].owner == _owner) {
                ownedAssets[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of owned assets
        assembly {
            mstore(ownedAssets, count) // Update the length of the array in memory
        }
        return ownedAssets;
    }


    // --- 2. Dynamic Asset Attributes & Evolution Functions ---

    /**
     * @dev Sets a custom attribute for an asset. Only asset owner can call this.
     * @param _assetId ID of the asset.
     * @param _attributeName Name of the attribute.
     * @param _attributeValue Value of the attribute.
     */
    function setAttribute(uint256 _assetId, string memory _attributeName, string memory _attributeValue) public onlyAssetOwner(_assetId) validAssetId(_assetId) {
        assets[_assetId].attributes[_attributeName] = _attributeValue;
        emit AssetAttributeSet(_assetId, _attributeName, _attributeValue);
    }

    /**
     * @dev Retrieves a specific attribute of an asset.
     * @param _assetId ID of the asset.
     * @param _attributeName Name of the attribute to retrieve.
     * @return Value of the attribute.
     */
    function getAttribute(uint256 _assetId, string memory _attributeName) public view validAssetId(_assetId) returns (string memory) {
        return assets[_assetId].attributes[_attributeName];
    }

    /**
     * @dev Triggers asset evolution. This is a conceptual function, in a real-world
     *      scenario, this would likely involve complex logic, oracles, or governance.
     *      For this example, it's a placeholder to show the concept.
     * @param _assetId ID of the asset to evolve.
     * @param _evolutionData Data related to the evolution process (e.g., new form, stats).
     */
    function evolveAsset(uint256 _assetId, string memory _evolutionData) public onlyAssetOwner(_assetId) validAssetId(_assetId) {
        // In a real application, this would involve more complex logic:
        // - Check evolution requirements (e.g., time passed, resources spent, etc.)
        // - Update asset attributes, metadata, or even change asset type based on _evolutionData
        assets[_assetId].assetMetadata = string(abi.encodePacked(assets[_assetId].assetMetadata, " - Evolved: ", _evolutionData)); // Simple metadata update as example
        emit AssetEvolved(_assetId, _evolutionData);
    }


    // --- 3. Marketplace Functionality Functions ---

    /**
     * @dev Lists an asset for sale in the marketplace. Only asset owner can call this.
     * @param _assetId ID of the asset to list.
     * @param _price Sale price in Wei.
     */
    function listAssetForSale(uint256 _assetId, uint256 _price) public onlyAssetOwner(_assetId) validAssetId(_assetId) {
        require(assets[_assetId].owner == msg.sender, "You are not the owner of this asset.");
        require(assetToListingId[_assetId] == 0 || !listings[assetToListingId[_assetId]].isActive, "Asset already listed or in another active listing.");

        listingCounter++;
        listings[listingCounter] = Listing({
            assetId: _assetId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        assetToListingId[_assetId] = listingCounter;
        activeListings[listingCounter] = true; // Track active listings for iteration
        emit AssetListedForSale(listingCounter, _assetId, msg.sender, _price);
    }

    /**
     * @dev Allows anyone to buy a listed asset.
     * @param _listingId ID of the marketplace listing.
     */
    function buyAsset(uint256 _listingId) public payable validListingId(_listingId) {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds sent.");

        address seller = listing.seller;
        uint256 assetId = listing.assetId;
        uint256 price = listing.price;

        // Transfer asset ownership
        assets[assetId].owner = msg.sender;

        // Deactivate listing
        listing.isActive = false;
        activeListings[_listingId] = false;

        // Transfer funds to seller (minus marketplace fee - conceptual)
        uint256 feeAmount = (price * marketplaceFee) / 10000; // Calculate fee (example 1%)
        uint256 sellerAmount = price - feeAmount;
        payable(seller).transfer(sellerAmount);
        payable(owner).transfer(feeAmount); // Send fee to contract owner (marketplace operator)

        emit AssetBought(_listingId, assetId, msg.sender, seller, price);
    }

    /**
     * @dev Cancels a marketplace listing. Only the seller can call this.
     * @param _listingId ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) public validListingId(_listingId) {
        require(listings[_listingId].seller == msg.sender, "Only the seller can cancel the listing.");
        listings[_listingId].isActive = false;
        activeListings[_listingId] = false;
        emit ListingCancelled(_listingId, listings[_listingId].assetId);
    }

    /**
     * @dev Retrieves details of a marketplace listing.
     * @param _listingId ID of the listing.
     * @return Tuple containing listing details: (assetId, seller, price, isActive).
     */
    function getListingDetails(uint256 _listingId) public view validListingId(_listingId) returns (tuple(uint256 assetId, address seller, uint256 price, bool isActive)) {
        Listing storage listing = listings[_listingId];
        return (listing.assetId, listing.seller, listing.price, listing.isActive);
    }

    /**
     * @dev Returns a list of all active listing IDs.
     * @return Array of active listing IDs.
     */
    function getAllListings() public view returns (uint256[] memory) {
        uint256[] memory allListings = new uint256[](listingCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (activeListings[i]) {
                allListings[count] = i;
                count++;
            }
        }
        assembly {
            mstore(allListings, count) // Resize array to actual number of listings
        }
        return allListings;
    }


    // --- 4. Reputation & Community Features Functions ---

    /**
     * @dev Allows users to report an asset for inappropriate content.
     *      In a real-world scenario, governance or moderators would review reports.
     * @param _assetId ID of the asset being reported.
     * @param _reportReason Reason for the report.
     */
    function reportAsset(uint256 _assetId, string memory _reportReason) public validAssetId(_assetId) {
        emit AssetReported(_assetId, msg.sender, _reportReason);
        // In a real application, you would store reports, trigger governance, etc.
        // For simplicity, this just emits an event in this example.
    }

    /**
     * @dev Retrieves a user's reputation score.
     * @param _user Address of the user.
     * @return User's reputation score.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Allows users to endorse another user, potentially increasing their reputation.
     *      This is a basic reputation mechanic. In a real system, it could be more complex.
     * @param _user Address of the user being endorsed.
     */
    function endorseUser(address _user) public {
        require(_user != msg.sender, "Cannot endorse yourself.");
        userReputation[_user] += 1; // Simple reputation increase
        emit UserEndorsed(msg.sender, _user);
    }


    // --- 5. Metaverse Utility & Interaction Functions (Conceptual) ---

    /**
     * @dev Placeholder function for using an asset in the metaverse.
     *      This is highly conceptual and would require integration with a specific metaverse platform.
     * @param _assetId ID of the asset being used.
     * @param _action Action being performed with the asset (e.g., "Equip", "Use", "Display").
     */
    function useAssetInMetaverse(uint256 _assetId, string memory _action) public onlyAssetOwner(_assetId) validAssetId(_assetId) {
        // In a real application, this function would:
        // 1. Communicate with an external metaverse platform (e.g., via oracles or cross-chain communication).
        // 2. Trigger actions within the metaverse based on the asset and _action.
        // 3. Potentially update asset attributes or state based on metaverse interactions.
        emit AssetUsedInMetaverse(_assetId, msg.sender, _action); // Example event (define event)
    }
    event AssetUsedInMetaverse(uint256 assetId, address user, string action); // Example event definition

    /**
     * @dev Allows users to stake an asset for in-metaverse utility (conceptual).
     *      Utility could be access to features, resources, etc. Duration is also conceptual.
     * @param _assetId ID of the asset to stake.
     * @param _duration Duration of staking (in blocks or time units - conceptual).
     */
    function stakeAssetForUtility(uint256 _assetId, uint256 _duration) public onlyAssetOwner(_assetId) validAssetId(_assetId) {
        // In a real application, this would:
        // 1. Track staked assets and their staking duration.
        // 2. Implement logic to grant utility/benefits based on staking (potentially using external systems).
        // 3. Handle unstaking and potential rewards/penalties.
        emit AssetStakedForUtility(_assetId, msg.sender, _duration);
    }

    /**
     * @dev Allows users to unstake an asset previously staked for utility.
     * @param _assetId ID of the asset to unstake.
     */
    function unstakeAssetForUtility(uint256 _assetId) public onlyAssetOwner(_assetId) validAssetId(_assetId) {
        // In a real application, this would:
        // 1. Remove the asset from staking tracking.
        // 2. Potentially revoke utility/benefits.
        // 3. Handle any rewards or penalties related to unstaking.
        emit AssetUnstakedFromUtility(_assetId, msg.sender);
    }


    // --- 6. Governance Functions (Simple Example) ---

    /**
     * @dev Allows users with a certain reputation level to propose a change to the marketplace fee.
     *      This is a very basic governance example. In a real system, you'd need voting mechanisms, etc.
     * @param _newFee New marketplace fee in basis points (e.g., 100 for 1%).
     */
    function proposeMarketplaceFeeChange(uint256 _newFee) public {
        require(userReputation[msg.sender] >= 10, "Reputation too low to propose changes."); // Example reputation requirement
        // In a real application, this would trigger a governance proposal, voting process, etc.
        // For this example, it just emits an event and the owner could manually update the fee.
        emit MarketplaceFeeChangeProposed(_newFee, msg.sender);
        // Example: Owner could then call a function like `setMarketplaceFee(_newFee)` after governance approval.
    }

    /**
     * @dev Returns the current marketplace fee.
     * @return Marketplace fee in basis points.
     */
    function getMarketplaceFee() public view returns (uint256) {
        return marketplaceFee;
    }

    /**
     * @dev (Example - Owner function to set marketplace fee - would be controlled by governance in real-world)
     */
    function setMarketplaceFee(uint256 _newFee) public onlyOwner {
        marketplaceFee = _newFee;
    }
}
```