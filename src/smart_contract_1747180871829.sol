Okay, let's design a smart contract based on a creative concept: **Quantum Entanglement Tokens (QET)**.

The idea is a pair of Non-Fungible Tokens (NFTs) that are "entangled". Owning and interacting with one token in the pair can affect the state or generate benefits for the *other* token in the pair, even if it's held in a different wallet or state (e.g., not staked). This is an analogy to quantum entanglement where measuring one particle instantaneously affects its entangled partner, regardless of distance.

This contract will be an ERC-721 variant with added state and functions for entanglement, staking, yield, and decay.

---

## QuantumEntanglementToken Contract Outline

This contract implements a Non-Fungible Token (NFT) system where tokens can be minted in entangled pairs. Entangled pairs have a linked state that affects their behavior, particularly regarding staking and yield generation.

1.  **Basic ERC-721 Functionality:** Standard NFT ownership, transfer, and approval.
2.  **Entanglement Pairs:** Tokens are minted in pairs with a shared `entanglementId`.
3.  **Entanglement State:** Pairs can be in an active or inactive entanglement state.
4.  **Entanglement Strength:** Active entanglement has a strength property that decays over time.
5.  **Staking Mechanism:** One token from an *active* entangled pair can be staked in the contract.
6.  **Entangled Yield:** The *non-staked* token in an active, staked entangled pair accrues yield based on the pair's entanglement strength.
7.  **Yield Claiming:** Owners of the non-staked token can claim accrued yield.
8.  **Entanglement Management:** Functions to activate, deactivate, and recharge entanglement strength.
9.  **Decay Control:** Owner can pause/unpause entanglement decay.
10. **Parameters:** Owner can set rates for yield, decay, recharge cost, etc.

---

## QuantumEntanglementToken Function Summary

Here's a summary of the contract's public/external functions:

**ERC-721 Standard (11 functions):**
- `constructor`: Initializes the contract with name and symbol.
- `supportsInterface`: Checks if the contract supports a given interface ID (ERC721, ERC165).
- `balanceOf`: Returns the number of tokens owned by an address.
- `ownerOf`: Returns the owner of a specific token.
- `approve`: Approves another address to transfer a specific token.
- `getApproved`: Returns the approved address for a specific token.
- `setApprovalForAll`: Sets approval for an operator for all owner's tokens.
- `isApprovedForAll`: Checks if an address is an operator for another address.
- `transferFrom`: Transfers ownership of a token (unsafe).
- `safeTransferFrom (address, address, uint256)`: Transfers ownership safely.
- `safeTransferFrom (address, address, uint256, bytes)`: Transfers ownership safely with data.

**Owner Functions (7 functions):**
- `mintPair`: Mints two new, entangled tokens with a new entanglement ID.
- `setBaseYieldRate`: Sets the base rate for yield calculation.
- `setEntanglementDecayRate`: Sets the rate at which entanglement strength decays.
- `setEntanglementRechargeCost`: Sets the ETH cost to recharge entanglement.
- `setEntanglementRechargeAmount`: Sets how much strength is added when recharged.
- `setEntanglementActivationCost`: Sets the ETH cost to activate entanglement.
- `pauseEntanglementDecay`: Pauses the decay of entanglement strength.
- `unpauseEntanglementDecay`: Unpauses the decay of entanglement strength.
- `withdrawETH`: Allows the owner to withdraw collected ETH (from costs).

**User Entanglement & Staking Functions (6 functions):**
- `activateEntanglement`: Activates the entangled state for a pair owned by the caller, paying a cost.
- `deactivateEntanglement`: Deactivates the entangled state for a pair owned by the caller.
- `stakeEntangledToken`: Stakes one token from an active entangled pair owned by the caller.
- `unstakeEntangledToken`: Unstakes a previously staked token.
- `rechargeEntanglementWithETH`: Recharges the strength of an active entangled pair owned by the caller, paying ETH.
- `claimEntangledYield`: Claims accrued yield for the non-staked token in an active, staked pair owned by the caller.

**View & Helper Functions (11 functions):**
- `getEntanglementInfo`: Returns detailed information about an entangled pair.
- `getEntanglementId`: Returns the entanglement ID for a given token.
- `getPairTokenId`: Returns the token ID of the entangled partner.
- `isEntangled`: Checks if a token belongs to an actively entangled pair.
- `isStaked`: Checks if a specific token is staked.
- `getEntanglementStrength`: Returns the current strength of a token's entangled pair.
- `getLastEntanglementActionTime`: Returns the timestamp of the last action affecting entanglement strength.
- `getAccruedYield`: Calculates and returns the potential yield accrued for a specific token (non-staked in a pair).
- `getEntanglementDecayRate`: Returns the current decay rate.
- `getBaseYieldRate`: Returns the current base yield rate.
- `getEntanglementRechargeCost`: Returns the current recharge cost.
- `getEntanglementRechargeAmount`: Returns the current recharge amount.
- `getEntanglementActivationCost`: Returns the current activation cost.
- `isDecayPaused`: Returns if entanglement decay is currently paused.
- `owner`: Returns the contract owner (from Ownable).

**(Total: 11 + 8 + 6 + 14 = 39 functions listed, well over the 20 required)**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Added for total supply/tokenOfOwnerByIndex if needed, though not explicitly used in core logic functions below count. Let's stick to the minimal ERC721 base and calculated functions to meet the count without Enumerable if possible, to avoid complexity. Re-counting main functions confirms we have plenty without Enumerable. Removing Enumerable import and extension for a more focused example.

// Minimal ERC721 standard imports are sufficient for the core function list.
// Let's add ERC721URIStorage if we want to store metadata URI per token.
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// For this example, let's keep it simple and omit URIStorage to focus on the entanglement mechanics.

contract QuantumEntanglementToken is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _entanglementIdCounter;

    // Mapping from token ID to its entanglement ID
    mapping(uint256 => uint256) private _tokenEntanglementId;

    // Mapping from entanglement ID to the two token IDs in the pair
    mapping(uint256 => uint256[2]) private _entanglementPairs;

    // Mapping from entanglement ID to the active entanglement state
    mapping(uint256 => bool) private _isEntangled;

    // Mapping from entanglement ID to current entanglement strength
    mapping(uint256 => uint256) private _entanglementStrength;

    // Mapping from entanglement ID to the timestamp of the last action affecting strength (for decay)
    mapping(uint256 => uint256) private _lastEntanglementActionTime;

    // Mapping from token ID to its staking status
    mapping(uint256 => bool) private _isStaked;

    // Mapping from entanglement ID to the token ID that is currently staked in the pair (0 if none staked)
    mapping(uint256 => uint256) private _stakedTokenInPair;

    // Mapping from token ID to accumulated yield (in a base unit, e.g., wei) for the non-staked token
    mapping(uint256 => uint256) private _accumulatedYield;

    // Contract Parameters (Configurable by Owner)
    uint256 public BASE_YIELD_RATE; // Yield rate per unit strength per second (e.g., wei per strength per second)
    uint256 public ENTANGLEMENT_DECAY_RATE; // Strength decay rate per second
    uint256 public MAX_ENTANGLEMENT_STRENGTH = 10000; // Maximum possible entanglement strength
    uint256 public ENTANGLEMENT_RECHARGE_AMOUNT; // How much strength is added on recharge
    uint256 public ENTANGLEMENT_RECHARGE_COST; // ETH cost for recharge
    uint256 public ENTANGLEMENT_ACTIVATION_COST; // ETH cost to activate entanglement

    // Decay state
    bool private _decayPaused = false;

    // --- Events ---

    event PairMinted(uint256 indexed entanglementId, uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner);
    event EntanglementActivated(uint256 indexed entanglementId);
    event EntanglementDeactivated(uint256 indexed entanglementId);
    event TokenStaked(uint256 indexed tokenId, uint256 indexed entanglementId);
    event TokenUnstaked(uint256 indexed tokenId, uint256 indexed entanglementId);
    event YieldClaimed(uint256 indexed tokenId, uint256 indexed entanglementId, uint256 amount);
    event EntanglementRecharged(uint256 indexed entanglementId, uint256 strengthBefore, uint256 strengthAfter, uint256 costPaid);
    event EntanglementDecayPaused();
    event EntanglementDecayUnpaused();
    event ParametersUpdated();

    // --- Modifiers ---

    modifier onlyEntanglementPair(uint256 _tokenId1, uint256 _tokenId2) {
        require(_tokenId1 != _tokenId2, "Cannot use the same token ID");
        uint256 entanglementId1 = _tokenEntanglementId[_tokenId1];
        uint256 entanglementId2 = _tokenEntanglementId[_tokenId2];
        require(entanglementId1 != 0 && entanglementId1 == entanglementId2, "Tokens must belong to the same entangled pair");
        _;
    }

    modifier onlyEntangledPairOwner(uint256 _tokenId1, uint256 _tokenId2) {
        require(ownerOf(_tokenId1) == _msgSender(), "Caller must own token 1");
        require(ownerOf(_tokenId2) == _msgSender(), "Caller must own token 2");
        _;
    }

    modifier whenNotDecayPaused() {
        require(!_decayPaused, "Entanglement decay is currently paused");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, uint256 initialBaseYieldRate, uint256 initialDecayRate, uint256 initialRechargeCost, uint256 initialRechargeAmount, uint256 initialActivationCost)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        BASE_YIELD_RATE = initialBaseYieldRate;
        ENTANGLEMENT_DECAY_RATE = initialDecayRate;
        ENTANGLEMENT_RECHARGE_COST = initialRechargeCost;
        ENTANGLEMENT_RECHARGE_AMOUNT = initialRechargeAmount;
        ENTANGLEMENT_ACTIVATION_COST = initialActivationCost;
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Applies entanglement decay to a specific pair if not paused.
     * Updates strength and last action time.
     * @param _entanglementId The ID of the entangled pair.
     */
    function _applyDecay(uint256 _entanglementId) internal {
        if (_entanglementId == 0 || !_isEntangled[_entanglementId] || _decayPaused) {
            return;
        }

        uint256 lastTime = _lastEntanglementActionTime[_entanglementId];
        uint256 currentTime = block.timestamp;
        uint256 timeDelta = currentTime - lastTime;

        uint256 currentStrength = _entanglementStrength[_entanglementId];
        uint256 decayAmount = timeDelta * ENTANGLEMENT_DECAY_RATE;

        uint256 newStrength = currentStrength > decayAmount ? currentStrength - decayAmount : 0;

        _entanglementStrength[_entanglementId] = newStrength;
        _lastEntanglementActionTime[_entanglementId] = currentTime; // Update time even if strength is 0
    }

    /**
     * @dev Calculates and adds pending yield to the non-staked token in a pair.
     * This function *updates* the accumulated yield state.
     * Should be called before actions like claiming or getting accrued yield.
     * @param _entanglementId The ID of the entangled pair.
     */
    function _calculateAndAccrueYield(uint256 _entanglementId) internal {
         if (_entanglementId == 0 || !_isEntangled[_entanglementId] || _stakedTokenInPair[_entanglementId] == 0) {
            // No yield if not entangled or no token is staked
            return;
        }

        // Apply decay before calculating yield based on current strength
        _applyDecay(_entanglementId);

        uint256 currentStrength = _entanglementStrength[_entanglementId];
        if (currentStrength == 0) {
            return; // No yield if strength is zero
        }

        uint256 lastTime = _lastEntanglementActionTime[_entanglementId]; // Use potentially updated time after decay
        uint256 currentTime = block.timestamp;
        uint256 timeDelta = currentTime - lastTime;

        // Yield accrues based on strength and time elapsed since last update/action
        uint256 yieldAmount = (currentStrength * BASE_YIELD_RATE * timeDelta) / MAX_ENTANGLEMENT_STRENGTH; // Scale by max strength

        uint256 stakedTokenId = _stakedTokenInPair[_entanglementId];
        uint256 nonStakedTokenId = (_entanglementPairs[_entanglementId][0] == stakedTokenId) ? _entanglementPairs[_entanglementId][1] : _entanglementPairs[_entanglementId][0];

        _accumulatedYield[nonStakedTokenId] += yieldAmount;
        _lastEntanglementActionTime[_entanglementId] = currentTime; // Update time after calculating yield
    }

     /**
     * @dev Internal function to find the other token ID in an entangled pair.
     * @param _tokenId The ID of one token in the pair.
     * @return The token ID of the entangled partner, or 0 if not in a pair.
     */
    function _getPairTokenId(uint256 _tokenId) internal view returns (uint256) {
        uint256 entanglementId = _tokenEntanglementId[_tokenId];
        if (entanglementId == 0) {
            return 0;
        }
        uint256 token1 = _entanglementPairs[entanglementId][0];
        uint256 token2 = _entanglementPairs[entanglementId][1];
        return (token1 == _tokenId) ? token2 : token1;
    }


    // --- ERC-721 Overrides ---

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     * Automatically unstakes a token and breaks entanglement if transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If transferring FROM a valid address (not minting to address(0))
        if (from != address(0)) {
            uint256 entanglementId = _tokenEntanglementId[tokenId];
            if (entanglementId != 0) {
                // If the token is staked, unstake it
                if (_isStaked[tokenId]) {
                     // Note: This calls _unstakeToken which updates state.
                    _unstakeToken(tokenId);
                }

                // Automatically break entanglement on transfer
                // Only deactivate the entanglement *pair* state if this transfer breaks it
                 if (_isEntangled[entanglementId]) {
                     // Make sure the other token in the pair isn't also being transferred in the same batch (unlikely for single tokens, but good practice)
                     uint256 pairTokenId = _getPairTokenId(tokenId);
                     // Simple check: if the 'to' address for the pair token is different, or if 'from' is address(0) (minting), we don't break.
                     // For a standard single transfer from A to B, both tokens in the pair are owned by A. Transferring one breaks the pair owned by A.
                     // If transferring from address(0) (mint), the pair is just being created, not transferred out of an existing state.
                     if (to != address(0) && from != address(0) && ownerOf(pairTokenId) == from) {
                        _deactivateEntanglement(entanglementId);
                     }
                 }
            }

            // Yield that was accumulated for this token stays with the token,
            // but yield calculation is zeroed out until it's part of a new active, staked pair.
        }
    }

    // --- Owner Functions ---

    /**
     * @dev Mints a new entangled pair of tokens to a specified address.
     * Only the owner can call this.
     * @param to The address to mint the tokens to.
     */
    function mintPair(address to) external onlyOwner {
        require(to != address(0), "Cannot mint to the zero address");

        _entanglementIdCounter.increment();
        uint256 entanglementId = _entanglementIdCounter.current();

        _tokenIdCounter.increment();
        uint256 tokenId1 = _tokenIdCounter.current();

        _tokenIdCounter.increment();
        uint256 tokenId2 = _tokenIdCounter.current();

        _safeMint(to, tokenId1);
        _safeMint(to, tokenId2);

        _tokenEntanglementId[tokenId1] = entanglementId;
        _tokenEntanglementId[tokenId2] = entanglementId;

        _entanglementPairs[entanglementId][0] = tokenId1;
        _entanglementPairs[entanglementId][1] = tokenId2;

        // Pairs are minted in a non-entangled state by default
        _isEntangled[entanglementId] = false;
        _entanglementStrength[entanglementId] = 0;
        _lastEntanglementActionTime[entanglementId] = block.timestamp;
        _stakedTokenInPair[entanglementId] = 0;

        emit PairMinted(entanglementId, tokenId1, tokenId2, to);
    }

    /**
     * @dev Sets the base yield rate. Only owner.
     * @param rate The new base yield rate.
     */
    function setBaseYieldRate(uint256 rate) external onlyOwner {
        BASE_YIELD_RATE = rate;
        emit ParametersUpdated();
    }

    /**
     * @dev Sets the entanglement decay rate. Only owner.
     * @param rate The new decay rate.
     */
    function setEntanglementDecayRate(uint256 rate) external onlyOwner {
        ENTANGLEMENT_DECAY_RATE = rate;
        emit ParametersUpdated();
    }

    /**
     * @dev Sets the ETH cost for recharging entanglement. Only owner.
     * @param cost The new recharge cost in wei.
     */
    function setEntanglementRechargeCost(uint256 cost) external onlyOwner {
        ENTANGLEMENT_RECHARGE_COST = cost;
         emit ParametersUpdated();
    }

    /**
     * @dev Sets the amount of strength added when recharging. Only owner.
     * @param amount The new recharge strength amount.
     */
    function setEntanglementRechargeAmount(uint256 amount) external onlyOwner {
        require(amount <= MAX_ENTANGLEMENT_STRENGTH, "Amount exceeds max strength");
        ENTANGLEMENT_RECHARGE_AMOUNT = amount;
         emit ParametersUpdated();
    }

     /**
     * @dev Sets the ETH cost for activating entanglement. Only owner.
     * @param cost The new activation cost in wei.
     */
    function setEntanglementActivationCost(uint256 cost) external onlyOwner {
        ENTANGLEMENT_ACTIVATION_COST = cost;
         emit ParametersUpdated();
    }

    /**
     * @dev Pauses the entanglement decay. Only owner.
     * Useful for maintenance or specific events.
     */
    function pauseEntanglementDecay() external onlyOwner {
        require(!_decayPaused, "Entanglement decay is already paused");
        _decayPaused = true;
        emit EntanglementDecayPaused();
    }

    /**
     * @dev Unpauses the entanglement decay. Only owner.
     */
    function unpauseEntanglementDecay() external onlyOwner {
        require(_decayPaused, "Entanglement decay is not paused");
        _decayPaused = false;
        emit EntanglementDecayUnpaused();
    }

    /**
     * @dev Allows the owner to withdraw collected ETH (from activation/recharge costs).
     */
    function withdrawETH() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "ETH withdrawal failed");
    }


    // --- User Entanglement & Staking Functions ---

    /**
     * @dev Activates the entangled state for a pair owned by the caller.
     * Requires payment of ENTANGLEMENT_ACTIVATION_COST.
     * @param _tokenId1 One token ID in the pair.
     * @param _tokenId2 The other token ID in the pair.
     */
    function activateEntanglement(uint256 _tokenId1, uint256 _tokenId2)
        external
        payable
        onlyEntanglementPair(_tokenId1, _tokenId2)
        onlyEntangledPairOwner(_tokenId1, _tokenId2)
    {
        uint256 entanglementId = _tokenEntanglementId[_tokenId1];
        require(!_isEntangled[entanglementId], "Entanglement is already active for this pair");
        require(_isStaked[_tokenId1] == false && _isStaked[_tokenId2] == false, "Neither token can be staked to activate entanglement");
        require(msg.value >= ENTANGLEMENT_ACTIVATION_COST, "Insufficient ETH for activation cost");

        // Refund excess ETH if any
        if (msg.value > ENTANGLEMENT_ACTIVATION_COST) {
            payable(msg.sender).transfer(msg.value - ENTANGLEMENT_ACTIVATION_COST);
        }

        _isEntangled[entanglementId] = true;
        _entanglementStrength[entanglementId] = MAX_ENTANGLEMENT_STRENGTH; // Start at max strength
        _lastEntanglementActionTime[entanglementId] = block.timestamp;

        emit EntanglementActivated(entanglementId);
    }

    /**
     * @dev Deactivates the entangled state for a pair owned by the caller.
     * @param _tokenId1 One token ID in the pair.
     * @param _tokenId2 The other token ID in the pair.
     */
    function deactivateEntanglement(uint256 _tokenId1, uint256 _tokenId2)
        external
        onlyEntanglementPair(_tokenId1, _tokenId2)
        onlyEntangledPairOwner(_tokenId1, _tokenId2)
    {
        uint256 entanglementId = _tokenEntanglementId[_tokenId1];
        require(_isEntangled[entanglementId], "Entanglement is not active for this pair");
        require(_isStaked[_tokenId1] == false && _isStaked[_tokenId2] == false, "Neither token can be staked to deactivate entanglement");

        // Before deactivating, apply any pending yield calculation for the non-staked token (if any was staked before)
        // This ensures yield is calculated up to the moment entanglement is broken.
        // Although the require above checks for staking, previous staking might have happened.
        // A safer approach is to just calculate accrued yield on claim. Deactivation simply stops future accrual.
        // Let's keep it simple: Deactivation stops future yield. Claim calculates up to claim time.

        _isEntangled[entanglementId] = false;
        _entanglementStrength[entanglementId] = 0; // Reset strength
        _lastEntanglementActionTime[entanglementId] = block.timestamp; // Update time

        emit EntanglementDeactivated(entanglementId);
    }

    /**
     * @dev Stakes one token from an active entangled pair owned by the caller.
     * Only one token in a pair can be staked at a time.
     * @param _tokenId The ID of the token to stake.
     */
    function stakeEntangledToken(uint256 _tokenId) external nonReentrant {
        require(ownerOf(_tokenId) == _msgSender(), "Caller must own the token");

        uint256 entanglementId = _tokenEntanglementId[_tokenId];
        require(entanglementId != 0, "Token is not part of an entangled pair");
        require(_isEntangled[entanglementId], "Pair is not actively entangled");
        require(!_isStaked[_tokenId], "Token is already staked");
        require(_stakedTokenInPair[entanglementId] == 0, "The other token in the pair is already staked");

        // Ensure any yield for the *other* token is calculated BEFORE staking this one,
        // as staking this one changes which token accrues yield.
        uint256 pairTokenId = _getPairTokenId(_tokenId);
        _calculateAndAccrueYield(entanglementId); // Calculate yield for pairTokenId up to now

        _isStaked[_tokenId] = true;
        _stakedTokenInPair[entanglementId] = _tokenId;

        // Update time after staking, as it's an action affecting the pair state for decay/yield calculation
        _lastEntanglementActionTime[entanglementId] = block.timestamp;

        emit TokenStaked(_tokenId, entanglementId);
    }

    /**
     * @dev Unstakes a token that was previously staked.
     * @param _tokenId The ID of the token to unstake.
     */
    function unstakeEntangledToken(uint256 _tokenId) external nonReentrant {
        require(ownerOf(_tokenId) == _msgSender(), "Caller must own the token");
        require(_isStaked[_tokenId], "Token is not staked");

        uint256 entanglementId = _tokenEntanglementId[_tokenId];
        require(entanglementId != 0, "Token is not part of an entangled pair"); // Should be true if _isStaked is true for this contract
        require(_stakedTokenInPair[entanglementId] == _tokenId, "Internal error: Staked token mismatch"); // Sanity check

        // Any yield accrued for the *other* token must be calculated BEFORE unstaking.
        // Unstaking pauses yield accrual for the pair until re-staked.
        uint256 pairTokenId = _getPairTokenId(_tokenId);
        _calculateAndAccrueYield(entanglementId); // Calculate yield for pairTokenId up to now

        _isStaked[_tokenId] = false;
        _stakedTokenInPair[entanglementId] = 0;

        // Update time after unstaking
        _lastEntanglementActionTime[entanglementId] = block.timestamp;

        emit TokenUnstaked(_tokenId, entanglementId);
    }

    /**
     * @dev Recharges the entanglement strength for an active pair owned by the caller.
     * Requires payment of ENTANGLEMENT_RECHARGE_COST.
     * @param _tokenId1 One token ID in the pair.
     * @param _tokenId2 The other token ID in the pair.
     */
    function rechargeEntanglementWithETH(uint256 _tokenId1, uint256 _tokenId2)
        external
        payable
        nonReentrant // Prevent reentrancy if ETH transfer is involved
        onlyEntanglementPair(_tokenId1, _tokenId2)
        onlyEntangledPairOwner(_tokenId1, _tokenId2)
        whenNotDecayPaused // Cannot recharge if decay is paused (no need to)
    {
        uint256 entanglementId = _tokenEntanglementId[_tokenId1];
        require(_isEntangled[entanglementId], "Pair is not actively entangled");
        require(msg.value >= ENTANGLEMENT_RECHARGE_COST, "Insufficient ETH for recharge cost");

        // Refund excess ETH
        if (msg.value > ENTANGLEMENT_RECHARGE_COST) {
            payable(msg.sender).transfer(msg.value - ENTANGLEMENT_RECHARGE_COST);
        }

        // Calculate yield for the non-staked token before recharging (updates time and yield state)
        // Recharging is an action that affects strength, so apply decay and calculate yield first.
        _calculateAndAccrueYield(entanglementId);

        uint256 currentStrength = _entanglementStrength[entanglementId];
        uint256 newStrength = currentStrength + ENTANGLEMENT_RECHARGE_AMOUNT;
        if (newStrength > MAX_ENTANGLEMENT_STRENGTH) {
            newStrength = MAX_ENTANGLEMENT_STRENGTH;
        }

        _entanglementStrength[entanglementId] = newStrength;
        // _lastEntanglementActionTime is already updated by _calculateAndAccrueYield or _applyDecay just before.
        // No need to update time again here immediately.

        emit EntanglementRecharged(entanglementId, currentStrength, newStrength, ENTANGLEMENT_RECHARGE_COST);
    }


    /**
     * @dev Claims accrued yield for a token, provided it is the non-staked token
     * in an active, staked entangled pair owned by the caller.
     * @param _tokenId The ID of the token to claim yield for.
     */
    function claimEntangledYield(uint256 _tokenId) external nonReentrant {
        require(ownerOf(_tokenId) == _msgSender(), "Caller must own the token");

        uint256 entanglementId = _tokenEntanglementId[_tokenId];
        require(entanglementId != 0, "Token is not part of an entangled pair");
        require(_isEntangled[entanglementId], "Pair is not actively entangled");
        require(!_isStaked[_tokenId], "Token is staked, yield accrues to the partner token"); // This token must be the *non*-staked one
        require(_stakedTokenInPair[entanglementId] != 0, "Neither token in the pair is staked"); // A token must be staked for yield to accrue

        // Ensure yield is calculated up to the moment of claiming
        _calculateAndAccrueYield(entanglementId);

        uint256 yieldAmount = _accumulatedYield[_tokenId];
        require(yieldAmount > 0, "No yield accrued for this token");

        _accumulatedYield[_tokenId] = 0; // Reset yield for this token

        (bool success, ) = payable(msg.sender).call{value: yieldAmount}("");
        require(success, "Yield transfer failed");

        emit YieldClaimed(_tokenId, entanglementId, yieldAmount);
    }


    // --- View Functions ---

    /**
     * @dev Returns the entanglement ID for a given token.
     * @param _tokenId The token ID.
     * @return The entanglement ID (0 if not in a pair).
     */
    function getEntanglementId(uint256 _tokenId) external view returns (uint256) {
        return _tokenEntanglementId[_tokenId];
    }

    /**
     * @dev Returns the token ID of the entangled partner.
     * @param _tokenId The token ID.
     * @return The token ID of the partner (0 if not in a pair).
     */
    function getPairTokenId(uint256 _tokenId) external view returns (uint256) {
        return _getPairTokenId(_tokenId);
    }

    /**
     * @dev Checks if a token belongs to an actively entangled pair.
     * @param _tokenId The token ID.
     * @return True if actively entangled, false otherwise.
     */
    function isEntangled(uint256 _tokenId) external view returns (bool) {
        uint256 entanglementId = _tokenEntanglementId[_tokenId];
        if (entanglementId == 0) return false;
        return _isEntangled[entanglementId];
    }

     /**
     * @dev Checks if a specific token is staked.
     * @param _tokenId The token ID.
     * @return True if staked, false otherwise.
     */
    function isStaked(uint256 _tokenId) external view returns (bool) {
        return _isStaked[_tokenId];
    }

    /**
     * @dev Returns the current strength of a token's entangled pair,
     * applying decay for calculation purposes without state update.
     * @param _tokenId The token ID.
     * @return The current entanglement strength.
     */
    function getEntanglementStrength(uint256 _tokenId) external view returns (uint256) {
        uint256 entanglementId = _tokenEntanglementId[_tokenId];
        if (entanglementId == 0 || !_isEntangled[entanglementId]) return 0;

        uint256 lastTime = _lastEntanglementActionTime[entanglementId];
        uint256 currentTime = block.timestamp;
        uint256 timeDelta = currentTime - lastTime;

        uint256 currentStrength = _entanglementStrength[entanglementId];
        uint256 decayAmount = (_decayPaused) ? 0 : timeDelta * ENTANGLEMENT_DECAY_RATE;

        return currentStrength > decayAmount ? currentStrength - decayAmount : 0;
    }

    /**
     * @dev Returns the timestamp of the last action affecting entanglement strength for a pair.
     * @param _tokenId The token ID.
     * @return The timestamp.
     */
    function getLastEntanglementActionTime(uint256 _tokenId) external view returns (uint256) {
        uint256 entanglementId = _tokenEntanglementId[_tokenId];
        if (entanglementId == 0) return 0;
        return _lastEntanglementActionTime[entanglementId];
    }

    /**
     * @dev Calculates and returns the potential yield accrued for a specific token,
     * assuming it is the non-staked token in a pair. Does not update state.
     * @param _tokenId The token ID.
     * @return The potential yield amount.
     */
    function getAccruedYield(uint256 _tokenId) external view returns (uint256) {
        uint256 entanglementId = _tokenEntanglementId[_tokenId];
        if (entanglementId == 0 || !_isEntangled[entanglementId] || _isStaked[_tokenId] || _stakedTokenInPair[entanglementId] == 0) {
            return _accumulatedYield[_tokenId]; // Return already accumulated if not eligible for new yield
        }

        // Calculate potential new yield since last update
        uint256 lastTime = _lastEntanglementActionTime[entanglementId];
        uint256 currentTime = block.timestamp;
        uint256 timeDelta = currentTime - lastTime;

        uint256 currentStrength = getEntanglementStrength(_tokenId); // Use calculated strength applying decay
        if (currentStrength == 0) return _accumulatedYield[_tokenId];

        uint256 potentialNewYield = (currentStrength * BASE_YIELD_RATE * timeDelta) / MAX_ENTANGLEMENT_STRENGTH;

        return _accumulatedYield[_tokenId] + potentialNewYield;
    }

     /**
     * @dev Returns comprehensive information about an entangled pair.
     * @param _entanglementId The entanglement ID.
     * @return A tuple containing: token1Id, token2Id, isEntangled, currentStrength, lastActionTime, stakedTokenId.
     */
    function getEntangledPairInfo(uint256 _entanglementId)
        external
        view
        returns (
            uint256 tokenId1,
            uint256 tokenId2,
            bool currentlyEntangled,
            uint256 currentStrength,
            uint256 lastActionTime,
            uint256 stakedTokenId
        )
    {
        require(_entanglementPairs[_entanglementId][0] != 0, "Invalid entanglement ID");

        tokenId1 = _entanglementPairs[_entanglementId][0];
        tokenId2 = _entanglementPairs[_entanglementId][1];
        currentlyEntangled = _isEntangled[_entanglementId];
        lastActionTime = _lastEntanglementActionTime[_entanglementId];
        stakedTokenId = _stakedTokenInPair[_entanglementId];

        // Calculate current strength applying decay for viewing purposes
        if (currentlyEntangled) {
             uint256 timeDelta = block.timestamp - lastActionTime;
             uint256 rawStrength = _entanglementStrength[_entanglementId];
             uint256 decayAmount = (_decayPaused) ? 0 : timeDelta * ENTANGLEMENT_DECAY_RATE;
             currentStrength = rawStrength > decayAmount ? rawStrength - decayAmount : 0;
        } else {
            currentStrength = 0;
        }
    }

    // --- Parameter View Functions ---

    function getEntanglementDecayRate() external view returns (uint256) {
        return ENTANGLEMENT_DECAY_RATE;
    }

    function getBaseYieldRate() external view returns (uint256) {
        return BASE_YIELD_RATE;
    }

    function getEntanglementRechargeCost() external view returns (uint256) {
        return ENTANGLEMENT_RECHARGE_COST;
    }

    function getEntanglementRechargeAmount() external view returns (uint256) {
        return ENTANGLEMENT_RECHARGE_AMOUNT;
    }

     function getEntanglementActivationCost() external view returns (uint256) {
        return ENTANGLEMENT_ACTIVATION_COST;
    }

    function isDecayPaused() external view returns (bool) {
        return _decayPaused;
    }

    // owner() function is inherited from Ownable

    // --- Keep ERC721 default implementations ---
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll,
    // transferFrom, safeTransferFrom are handled by inheriting ERC721.
    // supportsInterface is handled by inheriting ERC721 and Ownable.
}
```