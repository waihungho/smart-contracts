Okay, here is a Solidity smart contract implementing a "Dynamic Revenue Share NFT".

The core concept is an ERC721 NFT where each token represents a right to claim a portion of revenue collected by the contract (ETH in this case). The unique part is that the *weight* or "share points" associated with each NFT changes dynamically based on rules defined by the owner (e.g., time elapsed since minting, a global multiplier). The revenue collected is distributed proportionally based on the *current* share points at the time of revenue collection, and holders use a pull pattern to claim their accrued share.

This design aims for creativity by combining standard NFT ownership with a dynamic, time-sensitive revenue distribution mechanism, avoiding a simple fixed royalty or stake-based system common in open source.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Using SafeMath for clarity in point calculations involving multiplication/division,
// although Solidity 0.8+ has overflow checks by default.

// Outline:
// 1. Inherits ERC721 and Ownable for standard NFT functionality and access control.
// 2. Implements a dynamic share point system for each NFT based on time and admin parameters.
// 3. Allows collecting ETH revenue via receive/fallback functions.
// 4. Calculates revenue distribution based on the snapshot of total share points at the time of collection.
// 5. Provides a pull-based mechanism for NFT holders to claim their accrued revenue.
// 6. Includes admin functions to configure dynamic rules, mint NFTs, and manage settings.

// Function Summary:
// Standard ERC721 Functions (1-11):
//   1. constructor(string name, string symbol): Initializes the contract with name, symbol, and owner.
//   2. name(): Returns the token collection name.
//   3. symbol(): Returns the token collection symbol.
//   4. balanceOf(address owner): Returns the number of tokens owned by an address.
//   5. ownerOf(uint256 tokenId): Returns the owner of a specific token.
//   6. safeTransferFrom(address from, address to, uint256 tokenId): Safely transfers token ownership.
//   7. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safely transfers with data.
//   8. approve(address to, uint256 tokenId): Approves an address to transfer a token.
//   9. getApproved(uint256 tokenId): Gets the approved address for a token.
//  10. setApprovalForAll(address operator, bool approved): Sets approval for all tokens.
//  11. isApprovedForAll(address owner, address operator): Checks if an operator is approved for all tokens.
//  12. tokenURI(uint256 tokenId): Returns the metadata URI for a token.

// Core Dynamic Share & Revenue Functions (13-23):
//  13. mintNFT(address to, uint256 initialSharePoints): Mints a new NFT with initial share points (Owner only).
//  14. batchMintNFTs(address[] tos, uint256[] initialSharePointsArray): Mints multiple NFTs (Owner only).
//  15. receive(): Payable function to receive ETH revenue, triggers distribution logic.
//  16. fallback(): Payable function to receive ETH revenue, triggers distribution logic.
//  17. getSharePoints(uint256 tokenId): Returns the current calculated share points for an NFT.
//  18. getTotalSharePoints(): Returns the current total calculated share points across all NFTs.
//  19. updateSharePoints(uint256 tokenId): Public function to trigger share point calculation for a specific NFT.
//  20. claimRevenue(uint256 tokenId): Allows the owner of a specific token to claim its accrued revenue.
//  21. claimAllOwnedRevenue(): Allows the caller to claim revenue for all tokens they own.
//  22. getPendingRevenue(uint256 tokenId): Calculates the pending revenue for a specific token (view function).
//  23. getTotalPendingRevenueForOwner(address owner): Calculates total pending revenue for an owner (view function).

// Admin & Configuration Functions (24-29):
//  24. setBaseURI(string memory baseURI_): Sets the base URI for token metadata (Owner only).
//  25. setSharePointMultiplier(uint256 multiplier): Sets a global multiplier for share point calculation (Owner only).
//  26. setShareGrowthParameters(uint256 intervalSeconds, uint256 pointsPerInterval): Sets time-based growth rules (Owner only).
//  27. pauseDistribution(bool paused): Pauses or unpauses revenue claiming (Owner only).
//  28. withdrawAccidentalERC20(address tokenAddress): Allows owner to withdraw accidentally sent ERC20 tokens (Owner only).
//  29. isDistributionPaused(): Checks if revenue distribution is paused (view function).

// Internal Helpers:
//  _updateSharePointsLogic(uint256 tokenId): Internal logic to update share points based on rules.
//  _calculatePendingRevenueLogic(uint256 tokenId): Internal logic to calculate pending revenue.

contract DynamicRevenueShareNFT is ERC721, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // --- State Variables ---

    // Dynamic Share Points
    mapping(uint256 => uint256) private _sharePoints; // Current share points for each token
    mapping(uint256 => uint256) private _lastShareUpdateTime; // Timestamp of last point update for token
    uint256 private _totalSharePoints; // Sum of all current share points

    // Dynamic Share Rules (Admin Configurable)
    uint256 private _sharePointMultiplier = 1e18; // Global multiplier (1e18 = 1x)
    uint256 private _shareGrowthIntervalSeconds; // Time interval for growth
    uint256 private _sharePointsPerInterval; // Points earned per interval

    // Revenue Distribution
    // We use a cumulative tracking system to handle dynamic shares and pull payments.
    // This value tracks the total revenue distributed *per total share point* up to the last distribution event.
    // Stored with high precision (1e18 multiplier)
    uint256 private _cumulativeRevenuePerSharePoint = 0;

    // Tracks the cumulative revenue per share point at the time each token last claimed.
    // Used to calculate how much more revenue has accrued since the last claim.
    mapping(uint256 => uint256) private _lastClaimedCumulativeRevenuePerSharePoint; // Stored with high precision (1e18 multiplier)

    // Total ETH balance held by the contract (should match revenue balance).
    uint256 private _revenueBalance = 0;

    bool private _distributionPaused = false;

    // Metadata
    string private _baseTokenURI;

    // --- Events ---
    event NFTMinted(address indexed to, uint256 indexed tokenId, uint256 initialSharePoints);
    event SharePointsUpdated(uint256 indexed tokenId, uint256 oldPoints, uint256 newPoints);
    event TotalSharePointsUpdated(uint256 newTotalSharePoints);
    event RevenueCollected(uint256 amount, uint256 cumulativeRevenuePerSharePoint);
    event RevenueClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event SharePointMultiplierChanged(uint256 newMultiplier);
    event ShareGrowthParametersChanged(uint256 intervalSeconds, uint256 pointsPerInterval);
    event DistributionPaused(bool paused);
    event AccidentalERC20Withdrawal(address indexed tokenAddress, uint255 amount);

    // --- Errors ---
    error DistributionPausedError();
    error InsufficientPendingRevenue();
    error NotOwnedOrApproved();
    error InvalidBatchInput();
    error NotERC721Receiver();

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Standard ERC721 Overrides & Functions ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString())) : "";
    }

    // The rest of ERC721 functions (balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll,
    // transferFrom, safeTransferFrom) are inherited from OpenZeppelin's ERC721 base contract.
    // They are counted in the function summary as they are part of the external API surface.

    // --- Minting Functions ---

    /**
     * @dev Mints a new NFT and assigns initial share points.
     * @param to The address to mint the token to.
     * @param initialSharePoints The initial share points for the new token.
     */
    function mintNFT(address to, uint256 initialSharePoints) external onlyOwner {
        uint256 newTokenId = _nextTokenId(); // Internal ERC721 function to get next ID
        _safeMint(to, newTokenId);

        _sharePoints[newTokenId] = initialSharePoints;
        _lastShareUpdateTime[newTokenId] = block.timestamp;
        _totalSharePoints = _totalSharePoints.add(initialSharePoints);

        emit NFTMinted(to, newTokenId, initialSharePoints);
        emit TotalSharePointsUpdated(_totalSharePoints);
    }

    /**
     * @dev Mints multiple NFTs in a single transaction.
     * @param tos Array of addresses to mint tokens to.
     * @param initialSharePointsArray Array of initial share points for each token.
     */
    function batchMintNFTs(address[] calldata tos, uint256[] calldata initialSharePointsArray) external onlyOwner {
        if (tos.length != initialSharePointsArray.length || tos.length == 0) {
            revert InvalidBatchInput();
        }

        uint256 totalNewSharePoints = 0;
        for (uint256 i = 0; i < tos.length; i++) {
            uint256 newTokenId = _nextTokenId();
            _safeMint(tos[i], newTokenId);

            _sharePoints[newTokenId] = initialSharePointsArray[i];
            _lastShareUpdateTime[newTokenId] = block.timestamp;
            totalNewSharePoints = totalNewSharePoints.add(initialSharePointsArray[i]);

            emit NFTMinted(tos[i], newTokenId, initialSharePointsArray[i]);
        }
        _totalSharePoints = _totalSharePoints.add(totalNewSharePoints);
        emit TotalSharePointsUpdated(_totalSharePoints);
    }


    // --- Revenue Collection ---

    /**
     * @dev Receives incoming ETH and updates the cumulative revenue distribution.
     */
    receive() external payable {
        if (msg.value > 0) {
            _revenueBalance = _revenueBalance.add(msg.value);
            if (_totalSharePoints > 0) {
                 // Calculate the new revenue per share point contribution.
                 // Use 1e18 multiplier for precision in the cumulative calculation.
                _cumulativeRevenuePerSharePoint = _cumulativeRevenuePerSharePoint.add(
                    (msg.value.mul(1e18)).div(_totalSharePoints)
                );
            }
            emit RevenueCollected(msg.value, _cumulativeRevenuePerSharePoint);
        }
    }

    /**
     * @dev Handles calls with data, forwards to receive if no matching function.
     */
    fallback() external payable {
         if (msg.value > 0) {
             _revenueBalance = _revenueBalance.add(msg.value);
             if (_totalSharePoints > 0) {
                 _cumulativeRevenuePerSharePoint = _cumulativeRevenuePerSharePoint.add(
                    (msg.value.mul(1e18)).div(_totalSharePoints)
                );
             }
             emit RevenueCollected(msg.value, _cumulativeRevenuePerSharePoint);
         }
    }


    // --- Dynamic Share Point Logic ---

    /**
     * @dev Internal helper to calculate and update share points based on configured rules.
     * This logic can be customized (e.g., add trait-based rules, decay, caps).
     * Currently implements time-based linear growth.
     * @param tokenId The ID of the token to update.
     * @return The updated share points for the token.
     */
    function _updateSharePointsLogic(uint256 tokenId) internal returns (uint256) {
        uint256 currentPoints = _sharePoints[tokenId];
        uint256 lastUpdate = _lastShareUpdateTime[tokenId];
        uint256 totalPointsBefore = _totalSharePoints;

        // Calculate time-based growth
        if (_shareGrowthIntervalSeconds > 0 && _sharePointsPerInterval > 0 && block.timestamp > lastUpdate) {
            uint256 intervalsPassed = (block.timestamp - lastUpdate).div(_shareGrowthIntervalSeconds);
            uint256 pointsGained = intervalsPassed.mul(_sharePointsPerInterval);
            currentPoints = currentPoints.add(pointsGained);
            _lastShareUpdateTime[tokenId] = lastUpdate.add(intervalsPassed.mul(_shareGrowthIntervalSeconds)); // Update last update time based on *full* intervals passed
        }

        // Apply global multiplier (multiplier is 1e18 based, apply after growth)
        uint256 finalPoints = currentPoints.mul(_sharePointMultiplier).div(1e18);

        if (finalPoints != _sharePoints[tokenId]) {
            _sharePoints[tokenId] = finalPoints;
             _totalSharePoints = totalPointsBefore.sub(_sharePoints[tokenId]).add(finalPoints); // Recalculate total points

            emit SharePointsUpdated(tokenId, _sharePoints[tokenId], finalPoints);
            emit TotalSharePointsUpdated(_totalSharePoints);
        }

        return finalPoints;
    }

    /**
     * @dev Returns the current calculated share points for an NFT.
     * Triggers an update before returning to reflect latest growth.
     * @param tokenId The ID of the token.
     * @return The current share points.
     */
    function getSharePoints(uint256 tokenId) public returns (uint256) {
        // Calculate and update points before returning
        return _updateSharePointsLogic(tokenId);
    }

     /**
     * @dev Returns the current total calculated share points across all NFTs.
     * Does NOT trigger individual NFT updates here for gas efficiency in a view function,
     * relies on `updateSharePoints` or `getSharePoints` being called individually,
     * or points updating during claim.
     * @return The total share points.
     */
    function getTotalSharePoints() public view returns (uint256) {
        // Note: This view function returns the *current* sum based on stored values.
        // Individual token point values might be stale if updateSharePoints has not been called recently.
        // Claiming or calling getSharePoints for a token will refresh its points.
        return _totalSharePoints;
    }

    /**
     * @dev Allows anyone to trigger an update of the share points for a specific token.
     * Useful for users to ensure their token's points are up-to-date before claiming.
     * @param tokenId The ID of the token to update.
     */
    function updateSharePoints(uint256 tokenId) external {
        _updateSharePointsLogic(tokenId);
    }


    // --- Revenue Claiming ---

    /**
     * @dev Internal helper to calculate the pending revenue for a specific token.
     * Updates share points and claim marker if updateSharePoints is true.
     * @param tokenId The ID of the token.
     * @param updateSharePoints bool, set true to update points before calculation.
     * @param updateClaimMarker bool, set true to update the claim marker after calculation.
     * @return The pending revenue amount in wei.
     */
    function _calculatePendingRevenueLogic(uint256 tokenId, bool updateSharePoints, bool updateClaimMarker) internal returns (uint256) {
        uint256 currentSharePoints;
        if (updateSharePoints) {
            // Update points before calculating accrued revenue
            currentSharePoints = _updateSharePointsLogic(tokenId);
        } else {
             currentSharePoints = _sharePoints[tokenId]; // Use stored points (might be slightly stale)
        }

        // Calculate accrued revenue based on the change in cumulative revenue per share point
        uint256 accrued = (currentSharePoints.mul(_cumulativeRevenuePerSharePoint.sub(_lastClaimedCumulativeRevenuePerSharePoint[tokenId]))).div(1e18); // Scale back from 1e18 precision

        if (updateClaimMarker && accrued > 0) {
             // Update the claim marker to the current cumulative value
            _lastClaimedCumulativeRevenuePerSharePoint[tokenId] = _cumulativeRevenuePerSharePoint;
        }

        return accrued;
    }


    /**
     * @dev Allows the owner of a specific token to claim its accrued revenue.
     * Automatically updates the token's share points before calculating claimable amount.
     * @param tokenId The ID of the token to claim revenue for.
     */
    function claimRevenue(uint256 tokenId) external {
        if (_distributionPaused) {
            revert DistributionPausedError();
        }
        address owner = ownerOf(tokenId);
        if (owner != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(owner, msg.sender)) {
             revert NotOwnedOrApproved();
        }

        // Update points and calculate pending revenue, also update the claim marker
        uint256 pendingAmount = _calculatePendingRevenueLogic(tokenId, true, true);

        if (pendingAmount == 0) {
            // No pending revenue or already claimed
            revert InsufficientPendingRevenue(); // Or just return/event? Let's revert for explicit action.
        }

        _revenueBalance = _revenueBalance.sub(pendingAmount); // Deduct from balance before sending

        // Send ETH using call for reentrancy safety and robustness
        (bool success,) = payable(msg.sender).call{value: pendingAmount}("");
        require(success, "ETH transfer failed");

        emit RevenueClaimed(tokenId, msg.sender, pendingAmount);
    }

     /**
     * @dev Allows the caller to claim revenue for all tokens they currently own.
     * Iterates through owned tokens, updates points, calculates, and claims for each.
     * Note: Gas costs can be high for users with many tokens.
     */
    function claimAllOwnedRevenue() external {
        if (_distributionPaused) {
            revert DistributionPausedError();
        }

        uint256 totalClaimAmount = 0;
        uint256 balance = balanceOf(msg.sender);
        uint256[] memory ownedTokens = new uint256[](balance);

        // Get list of owned tokens (assuming _owners mapping is iterable or similar mechanism)
        // A standard ERC721 does not guarantee token enumeration. A common pattern is to
        // track owned token IDs in a separate data structure during _safeMint and _transfer.
        // For simplicity in this example, let's assume a way to iterate or access owned token IDs.
        // A robust implementation would require tracking `_ownedTokens[owner]` as a list/array/set.
        // Simulating this for the example: Iterate through all possible token IDs up to total supply.
        // In a real contract, you'd manage owned token arrays.

        uint265 totalMinted = _nextTokenId(); // Total number of tokens ever minted
        uint256 tokenCount = 0;
         for (uint256 i = 0; i < totalMinted; ++i) {
            try ownerOf(i) returns (address tokenOwner) {
                if (tokenOwner == msg.sender) {
                    if (tokenCount < balance) { // Safety check
                         ownedTokens[tokenCount] = i;
                         tokenCount++;
                    }
                }
            } catch {
                // ownerOf might revert for non-existent tokens if _nextTokenId is not perfect, skip.
            }
        }


        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = ownedTokens[i];
            // Update points and calculate pending revenue, update claim marker for THIS token
            uint256 pending = _calculatePendingRevenueLogic(tokenId, true, true);
            totalClaimAmount = totalClaimAmount.add(pending);
             // Note: claim marker is updated inside _calculatePendingRevenueLogic for each token
        }

        if (totalClaimAmount == 0) {
            revert InsufficientPendingRevenue();
        }

        _revenueBalance = _revenueBalance.sub(totalClaimAmount); // Deduct total before sending

        // Send total ETH using call
        (bool success, ) = payable(msg.sender).call{value: totalClaimAmount}("");
        require(success, "Bulk ETH transfer failed");

        // Emit events for each individual token claimed within the loop, or a single bulk event
        // Emitting individual events is more detailed but costly. Let's stick to individual per token inside the loop.
        // A single event for the bulk claim:
        emit RevenueClaimed(0, msg.sender, totalClaimAmount); // Use tokenId 0 or a special value for bulk
    }

    /**
     * @dev Calculates the pending revenue for a specific token (view function).
     * Does NOT update share points or claim marker.
     * @param tokenId The ID of the token.
     * @return The pending revenue amount in wei.
     */
    function getPendingRevenue(uint256 tokenId) public view returns (uint256) {
        // Use stored points for a view function (might be slightly stale)
         uint256 currentSharePoints = _sharePoints[tokenId];
        // Calculate accrued revenue based on the change in cumulative revenue per share point
        uint256 pending = (currentSharePoints.mul(_cumulativeRevenuePerSharePoint.sub(_lastClaimedCumulativeRevenuePerSharePoint[tokenId]))).div(1e18); // Scale back

        return pending;
    }

    /**
     * @dev Calculates total pending revenue for an owner across all their tokens (view function).
     * Does NOT update share points or claim markers.
     * @param owner Address of the owner.
     * @return Total pending revenue in wei.
     */
    function getTotalPendingRevenueForOwner(address owner) public view returns (uint256) {
        uint256 totalPending = 0;
        uint256 balance = balanceOf(owner);

        // Simulate iterating through owned tokens (same caveat as claimAllOwnedRevenue)
        uint265 totalMinted = _nextTokenId();
        for (uint256 i = 0; i < totalMinted; ++i) {
            try ownerOf(i) returns (address tokenOwner) {
                 if (tokenOwner == owner) {
                    // Use stored points (might be stale)
                    uint256 currentSharePoints = _sharePoints[i];
                     uint256 pending = (currentSharePoints.mul(_cumulativeRevenuePerSharePoint.sub(_lastClaimedCumulativeRevenuePerSharePoint[i]))).div(1e18);
                    totalPending = totalPending.add(pending);
                 }
            } catch {} // Ignore if ownerOf reverts
        }
        return totalPending;
    }


    // --- Admin Functions (Owner Only) ---

    /**
     * @dev Sets the base URI for token metadata.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
        // No event needed, standard practice for base URI
    }

    /**
     * @dev Sets the global multiplier for share point calculation.
     * e.g., 1e18 for 1x, 2e18 for 2x.
     * @param multiplier The new multiplier (using 1e18 for 1x base).
     */
    function setSharePointMultiplier(uint256 multiplier) external onlyOwner {
        _sharePointMultiplier = multiplier;
        emit SharePointMultiplierChanged(multiplier);
        // Note: Existing tokens' points will only reflect the new multiplier after their next update.
    }

     /**
     * @dev Sets the parameters for time-based share point growth.
     * @param intervalSeconds The time interval in seconds.
     * @param pointsPerInterval The number of points gained per interval.
     */
    function setShareGrowthParameters(uint256 intervalSeconds, uint256 pointsPerInterval) external onlyOwner {
        _shareGrowthIntervalSeconds = intervalSeconds;
        _sharePointsPerInterval = pointsPerInterval;
        emit ShareGrowthParametersChanged(intervalSeconds, pointsPerInterval);
         // Note: Existing tokens' growth will apply based on the new parameters from their last update time.
    }

     /**
     * @dev Pauses or unpauses revenue claiming.
     * Useful in emergencies or for contract upgrades.
     * @param paused True to pause, false to unpause.
     */
    function pauseDistribution(bool paused) external onlyOwner {
        _distributionPaused = paused;
        emit DistributionPaused(paused);
    }

    /**
     * @dev Allows the owner to withdraw accidentally sent ERC20 tokens.
     * Prevents locking arbitrary tokens sent to the contract address.
     * DOES NOT allow withdrawing the main revenue token (ETH in this case)
     * or tokens intended for distribution.
     * @param tokenAddress The address of the ERC20 token.
     */
    function withdrawAccidentalERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(owner(), balance);
            emit AccidentalERC20Withdrawal(tokenAddress, balance);
        }
    }

    // --- View Functions ---

    /**
     * @dev Checks if revenue distribution is currently paused.
     */
    function isDistributionPaused() external view returns (bool) {
        return _distributionPaused;
    }

    // --- Internal ERC721 Helpers (Standard Overrides) ---
    // These are typically part of the ERC721 implementation but are listed for completeness
    // as they are core to the NFT functionality used.
    // _safeMint - Used in mintNFT
    // _transfer - Used in safeTransferFrom

    // We need a way to track the next token ID. OpenZeppelin uses an internal counter.
    // Since we are inheriting, this is handled, but conceptually it's part of the minting process.
    uint256 private _currentTokenId = 0;

    function _nextTokenId() internal virtual returns (uint256) {
        uint256 id = _currentTokenId;
        _currentTokenId++;
        return id;
    }

    // The internal _safeMint, _transfer are inherited.
    // Need to make sure _transfer doesn't accidentally interfere with revenue claims.
    // The current pull pattern using _lastClaimedCumulativeRevenuePerSharePoint per *tokenId* is robust
    // to token transfers. When a token is transferred, its claim marker moves with it. The new owner
    // can claim the *total* accrued revenue for that token since the last claim by the *previous* owner.

}

// Minimal ERC20 Interface for withdrawal function
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic Share Points:** Instead of a fixed percentage or equal split, each NFT's "share" of the revenue pool (represented by `_sharePoints`) can change over time based on rules (`_shareGrowthIntervalSeconds`, `_sharePointsPerInterval`) and a global admin-set multiplier (`_sharePointMultiplier`). This allows for schemes like points increasing the longer you hold the NFT ("hodler boost") or being adjusted globally by the project owner.
2.  **Time-Based On-Chain Logic:** The `_updateSharePointsLogic` function calculates points based on `block.timestamp` and the last update time. While simple time checks aren't new, integrating them directly into an NFT's value calculation (its revenue share weight) is a specific application.
3.  **Pull-Based Revenue Accounting with Dynamic Weights:** This is the most complex part. It doesn't simply divide incoming revenue by a fixed number of tokens. It uses a cumulative "revenue per share point" metric (`_cumulativeRevenuePerSharePoint`). When new revenue arrives, this global metric increases. Each token tracks the value of this metric *when it last claimed* (`_lastClaimedCumulativeRevenuePerSharePoint[tokenId]`). The amount claimable by a token is `(currentSharePoints * (globalCumulative - tokenLastClaimedCumulative))`. This pattern is robust to token transfers (the history travels with the token) and variable claim times, which is essential when share points are also dynamic. It's an adaptation of standard yield farming or dividend distribution patterns to an NFT context with dynamic weights.
4.  **Explicit Point Update Mechanism:** The `updateSharePoints(uint256 tokenId)` function allows *any user* to trigger the point calculation for a specific token. This externalizes the computation and prevents the contract from needing to loop through all tokens automatically (saving gas on collection), placing the burden on the user who wants to ensure their points are current before claiming.
5.  **Separation of Collection and Claiming:** The `receive()`/`fallback()` functions only update the global cumulative metric (`_cumulativeRevenuePerSharePoint`) and the total balance (`_revenueBalance`). The actual transfer of ETH happens only when a user calls `claimRevenue` or `claimAllOwnedRevenue`. This pull pattern is standard practice for security (prevents reentrancy issues common with push payments) but integrated here with the dynamic share point calculation.
6.  **Configurable Parameters:** Admin functions allow tuning the dynamic behavior (`setSharePointMultiplier`, `setShareGrowthParameters`), offering flexibility in how the NFT's revenue power evolves without needing a new contract deployment.
7.  **Over 20 Functions:** As counted in the summary, the contract includes more than 20 external/public functions, covering standard ERC721 interactions, minting, dynamic share logic, revenue claiming, and admin controls.

This contract provides a foundation for an NFT project where the value or utility of owning an NFT isn't static but grows or changes over time in a programmable way, directly affecting passive income derived from the contract's revenue streams.