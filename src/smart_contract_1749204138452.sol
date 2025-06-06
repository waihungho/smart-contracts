Okay, let's create a smart contract concept that is advanced, creative, and avoids direct duplication of standard open-source templates.

**Concept:** A "Dynamic Reputation Crucible" where users earn non-transferable Reputation Points (RP) by locking ERC-20 tokens and ERC-721 NFTs from approved collections for extended periods. These RP then allow users to mint and upgrade a unique, non-transferable Soulbound Reputation Token (SRT) whose metadata/level reflects their accumulated reputation. This system combines elements of staking, locking, soulbound tokens, and dynamic state based on user activity over time.

**Key Advanced/Creative Aspects:**

1.  **Time-Weighted Reputation:** RP accrual is based on the *duration* and *amount/number* of assets locked/staked.
2.  **Multi-Asset Locking:** Supports both ERC-20 and ERC-721 assets from configurable lists.
3.  **Soulbound Reputation:** Both RP and the resulting SRT are non-transferable, preventing reputation farming through market purchase.
4.  **Dynamic SBT:** The Soulbound Reputation Token (SRT) is not static; it can be upgraded to reflect higher reputation tiers. Its `tokenURI` would ideally reflect the current level.
5.  **Reputation Decay (on action):** To encourage continuous participation, reputation points decay slightly upon withdrawing/unlocking assets, making long-term commitment more rewarding.
6.  **Pending Reputation:** Users accrue pending RP which must be claimed, allowing flexibility in when points are finalized.
7.  **Configurable Rates & Thresholds:** Admin can set different RP earning rates per asset type and define the thresholds required for SBT minting and upgrades.

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Imports:** OpenZeppelin for standard functionalities (Ownable, Pausable, ERC721, IERC20, IERC721, SafeERC20, SafeERC721).
3.  **Custom SoulboundERC721:** An internal or inherited contract extending ERC721, specifically overriding transfer functions to prevent transfers.
4.  **Main Contract: `ReputationCrucible`**
    *   Inherits Custom SoulboundERC721, Pausable, Ownable.
    *   **State Variables:**
        *   Owner/Admin address.
        *   Pausable state.
        *   Mappings for user's accumulated reputation points (`reputationPoints`).
        *   Mappings for user's pending (unclaimed) reputation points (`pendingReputation`).
        *   Mapping to track last action time for reputation calculation (`lastActionTime`).
        *   Mappings for staked ERC-20 amounts (`stakedTokens`).
        *   Mappings for locked ERC-721 token IDs (`lockedNFTs`).
        *   Mappings for allowed stake tokens (`allowedStakeTokens`) and lock NFTs (`allowedLockNFTs`).
        *   Mappings for RP earning rates (`tokenRPRates`, `nftRPRates`).
        *   Array of reputation thresholds for SRT levels (`reputationThresholds`).
        *   Decay factor applied on withdrawal/unlock (`withdrawalDecayFactor`).
        *   Mapping to track user's SRT token ID (`userSRT`).
        *   Mapping to track SRT level by token ID (`srtLevel`).
        *   Counter for next available SRT token ID.
    *   **Events:** For staking, unlocking, reputation claimed, SRT minted, SRT upgraded, configuration changes, pause/unpause.
    *   **Modifiers:** `onlyOwner`, `whenNotPaused`.
    *   **Internal Functions:**
        *   `_calculatePendingReputation`: Calculates RP accrued since last action time based on currently locked assets and rates.
        *   `_updateLastActionTime`: Updates the timestamp for a user.
        *   `_applyWithdrawalDecay`: Applies decay to total RP on withdrawal/unlock.
        *   `_getSRTLevelFromReputation`: Helper to determine the eligible SRT level based on RP.
    *   **Admin Functions (`onlyOwner`):**
        *   Set pausable state.
        *   Add/Remove allowed stake tokens.
        *   Add/Remove allowed lock NFT collections.
        *   Set RP earning rate for specific tokens/NFT collections.
        *   Set reputation thresholds for SRT levels.
        *   Set the withdrawal decay factor.
    *   **Reputation Earning Functions (`whenNotPaused`):**
        *   `stakeTokens`: Deposit ERC-20 to earn RP.
        *   `withdrawTokens`: Withdraw staked ERC-20 (calculates pending RP, applies decay, transfers tokens).
        *   `lockNFT`: Deposit ERC-721 to earn RP.
        *   `unlockNFT`: Withdraw locked ERC-721 (calculates pending RP, applies decay, transfers NFT).
        *   `claimReputation`: Finalize pending RP into total RP.
    *   **SBT Management Functions (`whenNotPaused`):**
        *   `mintSRT`: Mint the initial Soulbound Reputation Token if RP threshold met and user doesn't have one.
        *   `upgradeSRT`: Upgrade the existing SRT to the next level if RP threshold met.
        *   `tokenURI`: Override ERC721 function to return URI based on SRT level.
        *   Overrides for soulbound nature (`transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`).
    *   **Query Functions:**
        *   Get user's current reputation points.
        *   Get user's pending reputation points.
        *   Get user's staked amount for a token.
        *   Get user's locked NFTs for a collection.
        *   Get user's SRT token ID.
        *   Get user's SRT level.
        *   Get allowed stake tokens list.
        *   Get allowed lock NFT collections list.
        *   Get RP rate for a token/NFT.
        *   Get reputation thresholds.
        *   Get withdrawal decay factor.
        *   Get next SRT level for a user.

**Function Summary (at least 20):**

1.  `constructor`: Initializes the contract, owner, pausable state.
2.  `setPausable(bool _state)`: Owner function to pause/unpause transfers and user actions.
3.  `addAllowedStakeToken(address token)`: Owner function to allow an ERC-20 token for staking.
4.  `removeAllowedStakeToken(address token)`: Owner function to disallow an ERC-20 token.
5.  `addAllowedLockNFT(address nftCollection)`: Owner function to allow an ERC-721 collection for locking.
6.  `removeAllowedLockNFT(address nftCollection)`: Owner function to disallow an ERC-721 collection.
7.  `setTokenRPRate(address token, uint256 ratePerSecond)`: Owner function to set RP earning rate per token amount per second.
8.  `setNFTRPRate(address nftCollection, uint256 ratePerSecond)`: Owner function to set RP earning rate per NFT per second.
9.  `setReputationThresholds(uint256[] calldata _thresholds)`: Owner function to set RP required for each SRT level (index 0 for Level 1, etc.).
10. `setWithdrawalDecayFactor(uint256 factor)`: Owner function to set the percentage decay applied on withdrawal/unlock (e.g., 100 = 1%, 10000 = 100%). Factor is per 10000.
11. `stakeTokens(address token, uint256 amount)`: User deposits ERC-20 tokens to earn RP. Requires prior allowance.
12. `withdrawTokens(address token, uint256 amount)`: User withdraws staked ERC-20. Calculates pending RP, applies decay, transfers tokens back.
13. `lockNFT(address nftCollection, uint256 tokenId)`: User locks an ERC-721 NFT. Requires prior approval.
14. `unlockNFT(address nftCollection, uint256 tokenId)`: User unlocks a locked ERC-721 NFT. Calculates pending RP, applies decay, transfers NFT back.
15. `claimReputation()`: User finalizes pending RP into total RP.
16. `mintSRT()`: User mints their unique Soulbound Reputation Token if eligible.
17. `upgradeSRT()`: User upgrades their existing SRT to the next level if eligible.
18. `getReputationPoints(address user)`: Query current total RP for a user.
19. `getPendingReputation(address user)`: Query pending RP for a user.
20. `getStakedAmount(address user, address token)`: Query amount staked for a specific token by user.
21. `getLockedNFTs(address user, address nftCollection)`: Query list of locked NFT IDs for a collection by user.
22. `getUserSRTTokenId(address user)`: Query the SRT token ID owned by a user (0 if none).
23. `getUserSRTLevel(address user)`: Query the current SRT level of a user (0 if no SRT, >0 otherwise).
24. `getSRTLevel(uint256 tokenId)`: Query the SRT level for a given SRT token ID.
25. `getAllowedStakeTokens()`: Query list of allowed stake token addresses.
26. `getAllowedLockNFTs()`: Query list of allowed lock NFT collection addresses.
27. `getTokenRPRate(address token)`: Query RP rate for a specific token.
28. `getNFTRPRate(address nftCollection)`: Query RP rate for a specific NFT collection.
29. `getReputationThresholds()`: Query array of reputation thresholds.
30. `getWithdrawalDecayFactor()`: Query the withdrawal decay factor.
31. `tokenURI(uint256 tokenId)`: Override ERC721 standard - returns metadata URI for an SRT, reflecting its level.
32. `ownerOf(uint256 tokenId)`: Override ERC721 standard - returns owner, but restricted for soulbound nature.
33. `balanceOf(address owner)`: Override ERC721 standard - returns 1 if owner has an SRT, 0 otherwise.
34. `transferFrom(...)`, `safeTransferFrom(...)`, `approve(...)`, `setApprovalForAll(...)`: Overridden to revert, enforcing soulbound property.

This structure provides a robust framework with more than 20 functions, covering configuration, user interaction for earning and spending reputation (via SBTs), queries, and custom handling for the soulbound NFT.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- OUTLINE ---
// 1. SPDX-License-Identifier & Pragma
// 2. Imports
// 3. Custom SoulboundERC721: Extends ERC721, prevents transfers.
// 4. Main Contract: ReputationCrucible
//    - Inherits SoulboundERC721, Pausable, Ownable, ReentrancyGuard, ERC721Holder (for receiving NFTs).
//    - State Variables for reputation, staked/locked assets, configuration, SBT details.
//    - Events for actions and state changes.
//    - Modifiers.
//    - Internal Helpers for reputation calculation and decay.
//    - Admin Functions: Configure allowed assets, rates, thresholds, decay.
//    - Reputation Earning Functions: Stake ERC20, Lock ERC721, Withdraw ERC20, Unlock ERC721, Claim Reputation.
//    - SBT Management Functions: Mint SRT, Upgrade SRT, Override ERC721 functions for soulbound property and metadata.
//    - Query Functions: Get various state information for users and contract config.

// --- FUNCTION SUMMARY ---
// Constructor: Initialize contract, owner, pausable state.
// setPausable(bool _state): Admin pause/unpause user actions.
// addAllowedStakeToken(address token): Admin allow ERC-20 for staking.
// removeAllowedStakeToken(address token): Admin disallow ERC-20.
// addAllowedLockNFT(address nftCollection): Admin allow ERC-721 collection for locking.
// removeAllowedLockNFT(address nftCollection): Admin disallow ERC-721 collection.
// setTokenRPRate(address token, uint256 ratePerSecond): Admin set ERC-20 RP rate.
// setNFTRPRate(address nftCollection, uint256 ratePerSecond): Admin set ERC-721 RP rate.
// setReputationThresholds(uint256[] calldata _thresholds): Admin set RP thresholds for SRT levels.
// setWithdrawalDecayFactor(uint256 factor): Admin set RP decay factor on withdrawal/unlock.
// stakeTokens(address token, uint256 amount): User stakes ERC-20.
// withdrawTokens(address token, uint256 amount): User withdraws staked ERC-20 (calculates pending RP, applies decay).
// lockNFT(address nftCollection, uint256 tokenId): User locks ERC-721 NFT.
// unlockNFT(address nftCollection, uint256 tokenId): User unlocks ERC-721 NFT (calculates pending RP, applies decay).
// claimReputation(): User finalizes pending RP.
// mintSRT(): User mints SRT if eligible and none owned.
// upgradeSRT(): User upgrades SRT level if eligible.
// getReputationPoints(address user): Query user's total RP.
// getPendingReputation(address user): Query user's pending RP.
// getStakedAmount(address user, address token): Query user's staked amount for a token.
// getLockedNFTs(address user, address nftCollection): Query user's locked NFT IDs for a collection.
// getUserSRTTokenId(address user): Query user's SRT token ID (0 if none).
// getUserSRTLevel(address user): Query user's current SRT level (0 if no SRT).
// getSRTLevel(uint256 tokenId): Query SRT level for a token ID.
// getAllowedStakeTokens(): Query list of allowed stake tokens.
// getAllowedLockNFTs(): Query list of allowed lock NFT collections.
// getTokenRPRate(address token): Query RP rate for a token.
// getNFTRPRate(address nftCollection): Query RP rate for an NFT collection.
// getReputationThresholds(): Query RP thresholds.
// getWithdrawalDecayFactor(): Query withdrawal decay factor.
// getNextSRTLevelThreshold(address user): Query RP needed for the next SRT level for a user.
// supportsInterface(bytes4 interfaceId): ERC165 standard.
// tokenURI(uint256 tokenId): ERC721 standard override - gets metadata URI based on SRT level.
// ownerOf(uint256 tokenId): ERC721 standard override - gets owner (restricted).
// balanceOf(address owner): ERC721 standard override - gets balance (restricted to 0 or 1).
// transferFrom, safeTransferFrom, approve, setApprovalForAll: Overridden to revert for soulbound nature.

/// @custom:security ReentrancyGuard applied to functions modifying state based on external calls (token transfers).
/// @custom:security Pausable allows owner to halt user interactions if necessary.
/// @custom:security Ownable manages administrative functions.
/// @custom:soulbound Transfers of SRTs are disabled.
/// @custom:nft-receiving ERC721Holder allows contract to receive NFTs.

contract SoulboundERC721 is ERC721 {
    // Mapping from token ID to its level
    mapping(uint256 => uint8) internal _srtLevel;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /// @notice Internal function to set the level of an SRT
    function _setSRTLevel(uint256 tokenId, uint8 level) internal {
        _srtLevel[tokenId] = level;
    }

    /// @notice Gets the level of a specific SRT
    function getSRTLevel(uint256 tokenId) public view returns (uint8) {
        require(_exists(tokenId), "SRT does not exist");
        return _srtLevel[tokenId];
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    /// Overridden to prevent any transfer (minting `from == address(0)` is allowed).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Prevent transfer if not a minting operation
        require(from == address(0), "SRT is soulbound and cannot be transferred");
    }

    /// @dev See {IERC721-transferFrom}. Overridden to revert.
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert("SRT is soulbound and cannot be transferred");
    }

    /// @dev See {IERC721-safeTransferFrom}. Overridden to revert.
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert("SRT is soulbound and cannot be transferred");
    }

    /// @dev See {IERC721-safeTransferFrom}. Overridden to revert.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        revert("SRT is soulbound and cannot be transferred");
    }

    /// @dev See {IERC721-approve}. Overridden to revert.
    function approve(address to, uint256 tokenId) public virtual override {
        revert("SRT is soulbound and cannot be approved");
    }

    /// @dev See {IERC721-setApprovalForAll}. Overridden to revert.
    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("SRT is soulbound and cannot be approved");
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    /// This is a placeholder. A real implementation would likely delegate to an external service
    /// passing the token ID and potentially the level.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint8 level = _srtLevel[tokenId];
        // Example URI construction (can be replaced with a base URI + token ID or other logic)
        // A real dApp would use a metadata server returning JSON based on the level.
        // For simplicity here, just indicate the level in the URI.
        string memory base = "ipfs://your_metadata_CID/"; // Replace with your base URI
        bytes memory levelBytes = bytes(string(abi.encodePacked(uint256(level))));
        bytes memory tokenIdBytes = bytes(string(abi.encodePacked(tokenId)));
        return string(abi.encodePacked(base, "level_", levelBytes, "/token/", tokenIdBytes));
    }
}

contract ReputationCrucible is SoulboundERC721, Pausable, Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;
    using Address for address;

    // --- State Variables ---

    // User Reputation Points
    mapping(address => uint256) public reputationPoints;
    mapping(address => uint256) public pendingReputation;
    mapping(address => uint256) private lastActionTime; // Last timestamp reputation was calculated

    // Staked ERC20
    mapping(address => mapping(address => uint256)) private stakedTokens; // user => token => amount
    address[] private _allowedStakeTokens;
    mapping(address => bool) private _isAllowedStakeToken;
    mapping(address => uint256) private _tokenRPRates; // token => rate per second per unit

    // Locked ERC721
    mapping(address => mapping(address => uint256[])) private lockedNFTs; // user => collection => array of tokenIds
    address[] private _allowedLockNFTs;
    mapping(address => bool) private _isAllowedLockNFT;
    mapping(address => uint256) private _nftRPRates; // collection => rate per second per NFT

    // SRT Configuration
    mapping(address => uint256) public userSRT; // user => SRT tokenId (0 if none)
    uint256 private _nextSRTTokenId;
    uint256[] public reputationThresholds; // RP needed for level 1, level 2, etc.

    // Decay Factor (applied on withdrawal/unlock)
    uint256 public withdrawalDecayFactor = 0; // Factor out of 10000 (e.g., 100 = 1% decay)

    // --- Events ---
    event Paused(address account);
    event Unpaused(address account);
    event AllowedStakeTokenAdded(address indexed token);
    event AllowedStakeTokenRemoved(address indexed token);
    event AllowedLockNFTAdded(address indexed nftCollection);
    event AllowedLockNFTRemoved(address indexed nftCollection);
    event TokenRPRateSet(address indexed token, uint256 ratePerSecond);
    event NFTRPRateSet(address indexed nftCollection, uint256 ratePerSecond);
    event ReputationThresholdsSet(uint256[] thresholds);
    event WithdrawalDecayFactorSet(uint256 factor);

    event TokensStaked(address indexed user, address indexed token, uint256 amount, uint256 newStakedAmount);
    event TokensWithdrawn(address indexed user, address indexed token, uint256 amount, uint256 newStakedAmount);
    event NFTLocked(address indexed user, address indexed nftCollection, uint256 tokenId);
    event NFTUnlocked(address indexed user, address indexed nftCollection, uint256 tokenId);

    event ReputationClaimed(address indexed user, uint256 claimedAmount, uint256 totalReputation);
    event SRTMinted(address indexed user, uint256 indexed tokenId, uint8 level);
    event SRTUpgraded(address indexed user, uint256 indexed tokenId, uint8 newLevel);

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        SoulboundERC721(name, symbol)
        Ownable(msg.sender) // Set deployer as owner
        Pausable()
        ReentrancyGuard() // Helps prevent reentrancy, especially with token transfers
    {
        _nextSRTTokenId = 1; // Start token IDs from 1
    }

    // --- Internal Helpers ---

    /// @dev Calculates pending reputation for a user based on time elapsed and staked/locked assets.
    /// Updates pendingReputation and lastActionTime.
    function _calculatePendingReputation(address user) internal {
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - lastActionTime[user];

        if (timeElapsed == 0) {
            return; // No time has passed since last calculation
        }

        uint256 accruedRP = 0;

        // Calculate RP from staked tokens
        for (uint i = 0; i < _allowedStakeTokens.length; i++) {
            address token = _allowedStakeTokens[i];
            uint256 amount = stakedTokens[user][token];
            uint256 rate = _tokenRPRates[token];
            if (amount > 0 && rate > 0) {
                accruedRP += (amount * rate * timeElapsed);
            }
        }

        // Calculate RP from locked NFTs
        for (uint i = 0; i < _allowedLockNFTs.length; i++) {
            address nftCollection = _allowedLockNFTs[i];
            uint256 numNFTs = lockedNFTs[user][nftCollection].length;
            uint256 rate = _nftRPRates[nftCollection];
            if (numNFTs > 0 && rate > 0) {
                 // Calculate RP per NFT per second * number of NFTs * time elapsed
                 accruedRP += (rate * numNFTs * timeElapsed);
            }
        }

        pendingReputation[user] += accruedRP;
        lastActionTime[user] = currentTime;
    }

    /// @dev Applies a decay factor to the user's total reputation points.
    /// Only called when withdrawing/unlocking assets.
    function _applyWithdrawalDecay(address user) internal {
        uint256 currentRP = reputationPoints[user];
        uint256 decayAmount = (currentRP * withdrawalDecayFactor) / 10000; // Factor is out of 10000
        reputationPoints[user] = currentRP > decayAmount ? currentRP - decayAmount : 0;
    }

    /// @dev Determines the maximum eligible SRT level based on reputation points.
    function _getSRTLevelFromReputation(uint256 rp) internal view returns (uint8) {
        uint8 level = 0;
        for (uint i = 0; i < reputationThresholds.length; i++) {
            if (rp >= reputationThresholds[i]) {
                level = uint8(i + 1); // Level 1 corresponds to thresholds[0], Level 2 to thresholds[1], etc.
            } else {
                break; // Threshold not met, can't reach this level or higher
            }
        }
        return level;
    }

    // --- Admin Functions ---

    /// @dev See {Pausable-setPausable}. Owner can pause/unpause user actions.
    function setPausable(bool _state) public onlyOwner {
        if (_state) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @dev Adds an ERC-20 token to the list of allowed stake tokens.
    function addAllowedStakeToken(address token) public onlyOwner {
        require(token != address(0), "Invalid address");
        require(!_isAllowedStakeToken[token], "Token already allowed");
        _allowedStakeTokens.push(token);
        _isAllowedStakeToken[token] = true;
        emit AllowedStakeTokenAdded(token);
    }

    /// @dev Removes an ERC-20 token from the list of allowed stake tokens.
    /// Note: This doesn't affect already staked amounts, but prevents new stakes.
    function removeAllowedStakeToken(address token) public onlyOwner {
        require(token != address(0), "Invalid address");
        require(_isAllowedStakeToken[token], "Token not allowed");

        // Find and remove from array (less efficient for large arrays)
        for (uint i = 0; i < _allowedStakeTokens.length; i++) {
            if (_allowedStakeTokens[i] == token) {
                _allowedStakeTokens[i] = _allowedStakeTokens[_allowedStakeTokens.length - 1];
                _allowedStakeTokens.pop();
                break;
            }
        }

        _isAllowedStakeToken[token] = false;
        _tokenRPRates[token] = 0; // Also reset rate
        emit AllowedStakeTokenRemoved(token);
    }

    /// @dev Adds an ERC-721 collection to the list of allowed lock NFTs.
    function addAllowedLockNFT(address nftCollection) public onlyOwner {
        require(nftCollection != address(0), "Invalid address");
        require(nftCollection.isContract(), "Address is not a contract"); // Basic check
        require(!_isAllowedLockNFT[nftCollection], "NFT collection already allowed");
        _allowedLockNFTs.push(nftCollection);
        _isAllowedLockNFT[nftCollection] = true;
        emit AllowedLockNFTAdded(nftCollection);
    }

    /// @dev Removes an ERC-721 collection from the list of allowed lock NFTs.
    /// Note: Doesn't affect already locked NFTs, but prevents new locks.
    function removeAllowedLockNFT(address nftCollection) public onlyOwner {
        require(nftCollection != address(0), "Invalid address");
        require(_isAllowedLockNFT[nftCollection], "NFT collection not allowed");

        // Find and remove from array
        for (uint i = 0; i < _allowedLockNFTs.length; i++) {
            if (_allowedLockNFTs[i] == nftCollection) {
                _allowedLockNFTs[i] = _allowedLockNFTs[_allowedLockNFTs.length - 1];
                _allowedLockNFTs.pop();
                break;
            }
        }

        _isAllowedLockNFT[nftCollection] = false;
        _nftRPRates[nftCollection] = 0; // Also reset rate
        emit AllowedLockNFTRemoved(nftCollection);
    }

    /// @dev Sets the RP earning rate per unit of a specific token per second.
    function setTokenRPRate(address token, uint256 ratePerSecond) public onlyOwner {
        require(_isAllowedStakeToken[token], "Token not allowed for staking");
        _tokenRPRates[token] = ratePerSecond;
        emit TokenRPRateSet(token, ratePerSecond);
    }

    /// @dev Sets the RP earning rate per NFT from a specific collection per second.
    function setNFTRPRate(address nftCollection, uint256 ratePerSecond) public onlyOwner {
        require(_isAllowedLockNFT[nftCollection], "NFT collection not allowed for locking");
        _nftRPRates[nftCollection] = ratePerSecond;
        emit NFTRateSet(nftCollection, ratePerSecond);
    }

    /// @dev Sets the reputation thresholds for each SRT level.
    /// thresholds[0] is for Level 1, thresholds[1] for Level 2, etc. Must be strictly increasing.
    function setReputationThresholds(uint256[] calldata _thresholds) public onlyOwner {
        for (uint i = 0; i < _thresholds.length; i++) {
            if (i > 0) {
                require(_thresholds[i] > _thresholds[i - 1], "Thresholds must be strictly increasing");
            }
        }
        reputationThresholds = _thresholds;
        emit ReputationThresholdsSet(_thresholds);
    }

    /// @dev Sets the decay factor applied to total RP on withdrawal/unlock.
    /// Factor is out of 10000 (e.g., 100 = 1%, 0 = no decay).
    function setWithdrawalDecayFactor(uint256 factor) public onlyOwner {
        require(factor <= 10000, "Decay factor cannot exceed 100%");
        withdrawalDecayFactor = factor;
        emit WithdrawalDecayFactorSet(factor);
    }

    // --- Reputation Earning Functions ---

    /// @dev Allows a user to stake allowed ERC-20 tokens.
    /// Requires the user to have approved the contract to spend the tokens.
    function stakeTokens(address token, uint256 amount) public whenNotPaused nonReentrant {
        require(_isAllowedStakeToken[token], "Token not allowed for staking");
        require(amount > 0, "Amount must be > 0");

        // Calculate pending RP before changing state
        _calculatePendingReputation(msg.sender);

        // Transfer tokens into the contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Update staked amount
        stakedTokens[msg.sender][token] += amount;

        emit TokensStaked(msg.sender, token, amount, stakedTokens[msg.sender][token]);
    }

    /// @dev Allows a user to withdraw staked ERC-20 tokens.
    /// Applies decay and calculates pending RP before withdrawal.
    function withdrawTokens(address token, uint256 amount) public whenNotPaused nonReentrant {
        require(_isAllowedStakeToken[token], "Token not allowed for staking");
        require(amount > 0, "Amount must be > 0");
        require(stakedTokens[msg.sender][token] >= amount, "Insufficient staked amount");

        // Calculate pending RP before changing state and apply decay
        _calculatePendingReputation(msg.sender);
        _applyWithdrawalDecay(msg.sender);

        // Update staked amount
        stakedTokens[msg.sender][token] -= amount;

        // Transfer tokens back to the user
        IERC20(token).safeTransfer(msg.sender, amount);

        emit TokensWithdrawn(msg.sender, token, amount, stakedTokens[msg.sender][token]);
    }

    /// @dev Allows a user to lock an allowed ERC-721 NFT.
    /// Requires the user to have approved the contract to take the NFT.
    /// Implements ERC721Holder `onERC721Received` for receiving logic.
    function lockNFT(address nftCollection, uint256 tokenId) public whenNotPaused nonReentrant {
        require(_isAllowedLockNFT[nftCollection], "NFT collection not allowed for locking");
        require(IERC721(nftCollection).ownerOf(tokenId) == msg.sender, "Caller is not the owner of the NFT");

        // Check if the NFT is already locked by this user
        bool alreadyLocked = false;
        for (uint i = 0; i < lockedNFTs[msg.sender][nftCollection].length; i++) {
            if (lockedNFTs[msg.sender][nftCollection][i] == tokenId) {
                alreadyLocked = true;
                break;
            }
        }
        require(!alreadyLocked, "NFT already locked by this user");

        // Calculate pending RP before changing state
        _calculatePendingReputation(msg.sender);

        // Transfer NFT into the contract (will trigger onERC721Received)
        IERC721(nftCollection).safeTransferFrom(msg.sender, address(this), tokenId);

        // Add NFT ID to locked list
        lockedNFTs[msg.sender][nftCollection].push(tokenId);

        emit NFTLocked(msg.sender, nftCollection, tokenId);
    }

    /// @dev Allows a user to unlock a locked ERC-721 NFT.
    /// Applies decay and calculates pending RP before unlocking.
    function unlockNFT(address nftCollection, uint256 tokenId) public whenNotPaused nonReentrant {
        require(_isAllowedLockNFT[nftCollection], "NFT collection not allowed for locking");

        // Check if the NFT is locked by this user
        bool found = false;
        uint256 index = 0;
        uint256[] storage userLockedNFTs = lockedNFTs[msg.sender][nftCollection];

        for (uint i = 0; i < userLockedNFTs.length; i++) {
            if (userLockedNFTs[i] == tokenId) {
                found = true;
                index = i;
                break;
            }
        }
        require(found, "NFT not locked by this user in this collection");

        // Calculate pending RP before changing state and apply decay
        _calculatePendingReputation(msg.sender);
        _applyWithdrawalDecay(msg.sender);

        // Remove NFT ID from locked list (simple swap and pop)
        userLockedNFTs[index] = userLockedNFTs[userLockedNFTs.length - 1];
        userLockedNFTs.pop();

        // Transfer NFT back to the user
        IERC721(nftCollection).safeTransferFrom(address(this), msg.sender, tokenId);

        emit NFTUnlocked(msg.sender, nftCollection, tokenId);
    }

    /// @dev Allows a user to claim their accrued pending reputation points.
    function claimReputation() public whenNotPaused nonReentrant {
        // Calculate and finalize pending RP
        _calculatePendingReputation(msg.sender);

        uint256 amountToClaim = pendingReputation[msg.sender];
        require(amountToClaim > 0, "No pending reputation to claim");

        reputationPoints[msg.sender] += amountToClaim;
        pendingReputation[msg.sender] = 0;

        emit ReputationClaimed(msg.sender, amountToClaim, reputationPoints[msg.sender]);
    }

    // --- SBT Management Functions ---

    /// @dev Allows a user to mint their Soulbound Reputation Token if they meet the first threshold and don't have one.
    function mintSRT() public whenNotPaused nonReentrant {
        require(userSRT[msg.sender] == 0, "User already has an SRT");
        require(reputationThresholds.length > 0, "SRT thresholds not configured");
        require(reputationPoints[msg.sender] >= reputationThresholds[0], "Insufficient reputation to mint SRT Level 1");

        // Mint the new SRT
        uint256 newTokenId = _nextSRTTokenId++;
        _mint(msg.sender, newTokenId);

        // Set user's SRT ID and level
        userSRT[msg.sender] = newTokenId;
        _setSRTLevel(newTokenId, 1); // Minting always starts at Level 1

        emit SRTMinted(msg.sender, newTokenId, 1);
    }

    /// @dev Allows a user to upgrade their existing Soulbound Reputation Token level.
    function upgradeSRT() public whenNotPaused nonReentrant {
        uint256 tokenId = userSRT[msg.sender];
        require(tokenId != 0, "User does not have an SRT to upgrade");

        uint8 currentLevel = _srtLevel[tokenId];
        uint8 nextLevel = currentLevel + 1;

        require(nextLevel <= reputationThresholds.length, "No higher SRT level available");
        require(reputationPoints[msg.sender] >= reputationThresholds[nextLevel - 1], "Insufficient reputation for next level");

        // Upgrade the SRT level
        _setSRTLevel(tokenId, nextLevel);

        emit SRTUpgraded(msg.sender, tokenId, nextLevel);
    }

    /// @dev Overrides ERC721's supportsInterface for ERC721Holder compatibility.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Holder) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || // if inheriting enumerable
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- Query Functions ---

    /// @dev Gets a user's total accumulated reputation points.
    function getReputationPoints(address user) public view returns (uint256) {
        // Calculate pending RP before returning total for most up-to-date value in view
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - lastActionTime[user];
        uint256 accruedRP = 0;

         if (timeElapsed > 0) {
            for (uint i = 0; i < _allowedStakeTokens.length; i++) {
                address token = _allowedStakeTokens[i];
                uint256 amount = stakedTokens[user][token];
                uint256 rate = _tokenRPRates[token];
                if (amount > 0 && rate > 0) {
                    accruedRP += (amount * rate * timeElapsed);
                }
            }
             for (uint i = 0; i < _allowedLockNFTs.length; i++) {
                address nftCollection = _allowedLockNFTs[i];
                uint256 numNFTs = lockedNFTs[user][nftCollection].length;
                uint256 rate = _nftRPRates[nftCollection];
                if (numNFTs > 0 && rate > 0) {
                     accruedRP += (rate * numNFTs * timeElapsed);
                }
            }
         }
         return reputationPoints[user] + pendingReputation[user] + accruedRP;
    }


    /// @dev Gets a user's currently pending (unclaimed) reputation points.
    function getPendingReputation(address user) public view returns (uint256) {
         // Calculate pending RP before returning for most up-to-date value in view
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - lastActionTime[user];
        uint256 accruedRP = 0;

         if (timeElapsed > 0) {
            for (uint i = 0; i < _allowedStakeTokens.length; i++) {
                address token = _allowedStakeTokens[i];
                uint256 amount = stakedTokens[user][token];
                uint256 rate = _tokenRPRates[token];
                if (amount > 0 && rate > 0) {
                    accruedRP += (amount * rate * timeElapsed);
                }
            }
             for (uint i = 0; i < _allowedLockNFTs.length; i++) {
                address nftCollection = _allowedLockNFTs[i];
                uint256 numNFTs = lockedNFTs[user][nftCollection].length;
                uint256 rate = _nftRPRates[nftCollection];
                if (numNFTs > 0 && rate > 0) {
                     accruedRP += (rate * numNFTs * timeElapsed);
                }
            }
         }
        return pendingReputation[user] + accruedRP;
    }

    /// @dev Gets the amount of a specific token staked by a user.
    function getStakedAmount(address user, address token) public view returns (uint256) {
        return stakedTokens[user][token];
    }

    /// @dev Gets the list of NFT token IDs locked by a user for a specific collection.
    function getLockedNFTs(address user, address nftCollection) public view returns (uint256[] memory) {
        return lockedNFTs[user][nftCollection];
    }

    /// @dev Gets the SRT token ID owned by a user (0 if none).
    function getUserSRTTokenId(address user) public view returns (uint256) {
        return userSRT[user];
    }

    /// @dev Gets the current SRT level of a user (0 if no SRT, >0 otherwise).
    function getUserSRTLevel(address user) public view returns (uint8) {
        uint256 tokenId = userSRT[user];
        if (tokenId == 0) {
            return 0;
        }
        return _srtLevel[tokenId]; // Access internal mapping directly for view function
    }

    /// @dev Gets the list of allowed stake token addresses.
    function getAllowedStakeTokens() public view returns (address[] memory) {
        return _allowedStakeTokens;
    }

    /// @dev Gets the list of allowed lock NFT collection addresses.
    function getAllowedLockNFTs() public view returns (address[] memory) {
        return _allowedLockNFTs;
    }

    /// @dev Gets the current RP rate for a specific stake token.
    function getTokenRPRate(address token) public view returns (uint256) {
         require(_isAllowedStakeToken[token], "Token not allowed for staking");
        return _tokenRPRates[token]; // Access internal mapping directly for view function
    }

    /// @dev Gets the current RP rate for a specific lock NFT collection.
    function getNFTRPRate(address nftCollection) public view returns (uint256) {
        require(_isAllowedLockNFT[nftCollection], "NFT collection not allowed for locking");
        return _nftRPRates[nftCollection]; // Access internal mapping directly for view function
    }

    /// @dev Gets the reputation thresholds for each SRT level.
    function getReputationThresholds() public view returns (uint256[] memory) {
        return reputationThresholds;
    }

    /// @dev Gets the current withdrawal decay factor.
    function getWithdrawalDecayFactor() public view returns (uint256) {
        return withdrawalDecayFactor;
    }

    /// @dev Gets the reputation threshold required for a user's *next* possible SRT level upgrade.
    /// Returns 0 if no upgrade is possible.
    function getNextSRTLevelThreshold(address user) public view returns (uint256) {
        uint8 currentLevel = getUserSRTLevel(user);
        if (currentLevel == 0) {
            // User doesn't have SRT, next is Level 1
             if (reputationThresholds.length > 0) return reputationThresholds[0];
             return 0; // No thresholds set
        }

        uint8 nextLevel = currentLevel + 1;
        if (nextLevel > reputationThresholds.length) {
            return 0; // No higher level configured
        }

        return reputationThresholds[nextLevel - 1]; // thresholds[0] is Level 1, thresholds[1] is Level 2, etc.
    }
}
```