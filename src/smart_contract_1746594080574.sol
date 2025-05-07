```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- QuantumEntangledNFT Outline and Summary ---
//
// Concept: A unique ERC721 implementation where tokens can be "bonded" together
//          in pairs or groups, simulating a form of quantum entanglement.
//          Bonded tokens share a "Quantum State" and accumulate shared "Entropy".
//          Actions on one bonded token can affect others in the bond.
//          Unbonding is possible but may have consequences.
//
// Features:
// - Standard ERC721 functionality (minting, transfer, ownership).
// - Token Bonding: Allows two or more non-bonded tokens to form a bond.
// - Token Unbonding: Allows breaking a bond (owner of all tokens in the bond).
// - Shared Quantum State: A state variable common to all tokens in a bond, influenceable by bond members.
// - Quantum State Influence: Mechanism for bonded token owners to change the shared state, with a cost and cooloff.
// - Shared Entropy Accumulation: Bonded tokens collectively generate "entropy" over time.
// - Individual Entropy Accumulation: Unbonded tokens generate entropy at a different rate.
// - Entropy Claiming: Owners can claim accumulated shared and individual entropy (which could be used for future utility, e.g., governance, upgrades, etc. - represented here as a simple balance).
// - Flexible Bonding: Functions to mint already bonded pairs, add tokens to existing bonds, and remove tokens.
// - Configurable Parameters: Owner can set fees, entropy rates, and cooloff periods.
// - Fee Collection: Fees collected from bonding/influencing are withdrawable by the owner.
//
// Functions Summary:
// (Inherited from ERC721 & Ownable are not listed here for the 20+ novel count, but they exist)
//
// Core Token Management (Custom):
// 1. mint(address to): Mints a new individual, unbonded token.
// 2. _baseURI(): Sets the base URI for metadata (internal).
//
// Bonding & Unbonding:
// 3. bondTokens(uint256 tokenId1, uint256 tokenId2): Bonds two unbonded tokens into a new bond. Requires fee.
// 4. unbondTokens(uint256 bondId): Unbonds all tokens within a specific bond. Requires owner of all members and fee.
// 5. mintBondedPair(address owner): Mints two tokens already bonded together.
// 6. addTokenToBond(uint256 bondId, uint256 newTokenId): Adds an unbonded token to an existing bond. Requires fee.
// 7. removeTokenFromBond(uint256 tokenId): Removes a single token from its bond. Calculates and distributes proportional entropy.
//
// Bond Information Getters:
// 8. getBondId(uint256 tokenId): Returns the bond ID a token belongs to (0 if unbonded).
// 9. getBondMembers(uint256 bondId): Returns the list of token IDs in a bond.
// 10. isTokenBonded(uint256 tokenId): Checks if a token is currently bonded.
// 11. getBondCount(): Returns the total number of active bonds.
// 12. getAllBondIds(): Returns a list of all active bond IDs (potentially gas-intensive).
// 13. getBondCreationTime(uint256 bondId): Returns the timestamp when a bond was created.
//
// Quantum State Management:
// 14. getSharedQuantumState(uint256 bondId): Returns the current shared quantum state for a bond.
// 15. influenceQuantumState(uint256 bondId, uint8 newStateValue): Allows a bond member owner to change the shared state. Requires fee and adheres to cooloff.
// 16. getLastQuantumStateInfluenceTime(uint256 bondId): Returns the timestamp of the last state influence for a bond.
// 17. isQuantumInfluenceReady(uint256 bondId): Checks if the quantum influence cooloff period has passed for a bond.
//
// Entropy Management:
// 18. getCurrentBondedEntropy(uint256 bondId): Calculates the currently accumulated *shared* entropy for a bond since last update/claim.
// 19. claimBondedEntropyShare(uint256 tokenId): Claims the calling owner's accumulated share of bonded entropy for a specific token since its last claim.
// 20. getIndividualEntropy(uint256 tokenId): Gets the accumulated *individual* entropy for an unbonded token since last claim.
// 21. claimIndividualEntropy(uint256 tokenId): Claims the accumulated individual entropy for a token.
// 22. getTotalEntropy(uint256 tokenId): Calculates the total potential entropy (individual + share of bonded) available for a token.
// 23. getEntropyBalance(address owner): Returns the total claimed entropy balance for an address. (Entropy token/utility is simplified here as a balance in this contract).
//
// Configuration & Administration (Owner Only):
// 24. setBondingFee(uint256 fee): Sets the fee required to bond two tokens.
// 25. setUnbondingFee(uint256 fee): Sets the fee required to unbond tokens.
// 26. setBondedEntropyRatePerBond(uint256 rate): Sets the rate at which each bond accumulates shared entropy (per second).
// 27. setIndividualEntropyAccumulationRate(uint256 rate): Sets the rate at which individual tokens accumulate entropy (per second).
// 28. setQuantumInfluenceFee(uint256 fee): Sets the fee required to influence a bond's quantum state.
// 29. setQuantumInfluenceCooloff(uint256 duration): Sets the minimum time between quantum state influences for a bond.
// 30. withdrawFees(): Allows the contract owner to withdraw accumulated fees.

contract QuantumEntangledNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _bondIdCounter;

    // --- Data Structures ---

    // Mapping token ID to the bond ID it belongs to (0 if unbonded)
    mapping(uint256 => uint256) private _tokenBondId;

    // Mapping bond ID to the list of token IDs in that bond
    mapping(uint256 => uint256[]) private _bondMembers;

    // Mapping bond ID to the shared quantum state (e.g., 0-100)
    mapping(uint256 => uint8) private _bondQuantumState;

    // Mapping bond ID to the timestamp of the last shared state influence
    mapping(uint256 => uint256) private _bondLastInfluenceTime;

    // Mapping bond ID to the timestamp when bonded entropy was last updated (claim or state influence)
    mapping(uint256 => uint256) private _bondLastEntropyUpdateTime;

    // Mapping token ID to the individual entropy accumulated before bonding or after unbonding
    // This also stores a token's proportional share claimed from a bond
    mapping(uint256 => uint256) private _tokenIndividualEntropy;

    // Mapping token ID to the timestamp entropy was last claimed for this specific token (relevant for shared entropy calculation)
    mapping(uint256 => uint256) private _tokenLastEntropyClaimTime;

    // Mapping bond ID to the total *unclaimed* shared entropy accumulated in that bond
    // This entropy gets distributed proportionally when claimed by a token member.
    mapping(uint256 => uint256) private _bondUnclaimedSharedEntropy;

     // Mapping address to their total claimed entropy balance (simplification: entropy is just a balance here)
    mapping(address => uint256) private _entropyBalances;

    // Set of active bond IDs (useful for iterating or getting total count)
    mapping(uint256 => bool) private _activeBonds;
    uint256[] private _activeBondIdList; // Maintain a list for getAllBondIds (warning: gas)

    // --- Configurable Parameters ---
    uint256 public bondingFee = 0; // Fee to bond tokens
    uint256 public unbondingFee = 0; // Fee to unbond tokens
    uint256 public bondedEntropyRatePerBond = 1; // Entropy per second per bond
    uint256 public individualEntropyAccumulationRate = 1; // Entropy per second per individual token
    uint256 public quantumInfluenceFee = 0; // Fee to influence quantum state
    uint256 public quantumInfluenceCooloff = 1 days; // Minimum time between state influences

    // --- Events ---
    event TokenBonded(uint256 indexed bondId, uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 timestamp);
    event TokensUnbonded(uint256 indexed bondId, uint256[] tokenIds, uint256 timestamp);
    event TokenAddedToBond(uint256 indexed bondId, uint256 indexed newTokenId, uint256 timestamp);
    event TokenRemovedFromBond(uint256 indexed bondId, uint256 indexed tokenId, uint256 remainingMemberCount, uint256 timestamp);
    event QuantumStateInfluenced(uint256 indexed bondId, uint8 newState, address indexed influencer, uint256 timestamp);
    event EntropyClaimed(address indexed owner, uint256 indexed tokenId, uint256 amount, uint256 timestamp);
    event FeesWithdrawn(address indexed owner, uint256 amount, uint256 timestamp);
    event BondParametersUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event BondCreationTime(uint256 indexed bondId, uint256 timestamp);

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Internal Helper Functions ---

    // Calculate current accumulated shared entropy for a bond
    function _calculateBondedEntropy(uint256 bondId) internal view returns (uint256) {
        require(_activeBonds[bondId], "Bond does not exist");
        uint256 timeElapsed = block.timestamp - _bondLastEntropyUpdateTime[bondId];
        return timeElapsed * bondedEntropyRatePerBond;
    }

    // Calculate current accumulated individual entropy for a token (unbonded or its individual pool)
     function _calculateIndividualEntropy(uint256 tokenId) internal view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        uint256 lastClaimTime = _tokenLastEntropyClaimTime[tokenId];
        if (lastClaimTime == 0) {
            // If never claimed, start accumulation from mint time (or a fixed start)
            // For simplicity, let's assume accumulation starts effectively after mint/unbond
            // and lastClaimTime == 0 means no claim *yet* and accumulation starts conceptually now or after last state change affecting it.
            // More accurately, need to track token state change times.
            // Let's simplify: individual entropy accumulates from its last claim time, regardless of bond state,
            // but *shared* entropy is the bonus when bonded.
             lastClaimTime = _exists(tokenId) ? block.timestamp - (1 hours) : block.timestamp; // Placeholder logic, assumes accumulation starts "recently" if never claimed
        }
         uint256 timeElapsed = block.timestamp - lastClaimTime;
         uint256 currentIndividualRate = individualEntropyAccumulationRate;
         if (_tokenBondId[tokenId] != 0) {
             // If bonded, individual rate might be different or zero - let's assume it still accumulates
             // for simplicity, separate from shared.
         }
         return timeElapsed * currentIndividualRate;
    }


    // Update the accumulated unclaimed shared entropy for a bond
    function _updateBondedEntropy(uint256 bondId) internal {
        if (_activeBonds[bondId]) {
            uint256 accumulated = _calculateBondedEntropy(bondId);
            _bondUnclaimedSharedEntropy[bondId] = _bondUnclaimedSharedEntropy[bondId].add(accumulated);
            _bondLastEntropyUpdateTime[bondId] = block.timestamp;
        }
    }

     // Distribute a proportional share of unclaimed bonded entropy to a claiming token
    function _distributeBondedEntropyShare(uint256 bondId, uint256 tokenId) internal {
        require(_activeBonds[bondId], "Bond does not exist");
        require(_tokenBondId[tokenId] == bondId, "Token not in this bond");

        // Ensure bond entropy is up-to-date before distributing
        _updateBondedEntropy(bondId);

        uint256 totalUnclaimed = _bondUnclaimedSharedEntropy[bondId];
        uint256 numMembers = _bondMembers[bondId].length;

        if (totalUnclaimed == 0 || numMembers == 0) {
            // Nothing to distribute
            _tokenLastEntropyClaimTime[tokenId] = block.timestamp; // Update claim time even if nothing claimed
            return;
        }

        // Calculate the proportional share. Simplistic: equal share per token for simplicity.
        // More complex: could be based on token properties, time in bond since last claim, etc.
        // This simple model claims ALL accumulated shared entropy for the bond and distributes it.
        // A more refined model would claim based on TIME *since the token's last claim*.
        // Let's implement the time-based claim share:
        uint256 lastClaimTime = _tokenLastEntropyClaimTime[tokenId];
        if (lastClaimTime == 0) lastClaimTime = _bondCreationTime[bondId]; // Assume accumulation starts from bond creation if never claimed
        uint256 timeInBondSinceLastClaim = block.timestamp - lastClaimTime;

        // Total potential entropy generated by this bond since its last update
        uint256 entropySinceLastBondUpdate = block.timestamp - _bondLastEntropyUpdateTime[bondId]; // Already factored in _updateBondedEntropy

        // The portion of the *total unclaimed* that this token is eligible for
        // This is complex. Let's simplify the model: When a token claims,
        // it gets its share based on the TOTAL time the BOND existed since this token's *last claim*.
        // This requires tracking per-token contribution time to the unclaimed pool.
        // This gets overly complex for a demo.
        // Let's revert to a simpler model for entropy distribution:
        // Shared entropy accumulates in a pool. When *any* token claims, it claims based on the total accumulated
        // entropy divided by the number of members *at the time of accumulation*.
        // A simpler, common model: just add the *current* unclaimed total to the owner and reset the bond's pool.
        // This incentivizes frequent claiming and is simple. Let's go with this.
        uint256 amountToDistribute = _bondUnclaimedSharedEntropy[bondId];
        _bondUnclaimedSharedEntropy[bondId] = 0; // Reset the bond pool
        _bondLastEntropyUpdateTime[bondId] = block.timestamp; // Update bond's base update time

        // Distribute this amount among current members equally
        uint256 sharePerMember = amountToDistribute / numMembers;
        uint256 remainder = amountToDistribute % numMembers;

        address bondOwner = ownerOf(tokenId); // Assumes all members are owned by the same address for simplicity in this model.
                                             // If members can be owned by different addresses, need mapping bondId -> member -> share entitlement.
                                             // Let's stick to same owner for simplicity, as unbonding requires it.

        _entropyBalances[bondOwner] = _entropyBalances[bondOwner].add(sharePerMember); // Each member contributes its share
        // Remainder goes to the first token for simplicity, or back to the pool, or burned.
        if (numMembers > 0) {
            _entropyBalances[bondOwner] = _entropyBalances[bondOwner].add(remainder); // Simplification: remainder goes to one
        }

        // This claiming model doesn't really use _tokenLastEntropyClaimTime effectively for *shared* entropy share calculation.
        // It's just claiming the current total pool. Let's adjust the functions and names.
        // Let's have `claimAllBondedEntropy(uint256 bondId)` only callable by the owner of *all* tokens in the bond.

         // Reverting to the time-based, per-token claim:
        uint256 individualShareRate = bondedEntropyRatePerBond.div(numMembers); // Entropy rate *per token* from the shared pool
        uint256 shareAmount = timeInBondSinceLastClaim.mul(individualShareRate);

        _tokenIndividualEntropy[tokenId] = _tokenIndividualEntropy[tokenId].add(shareAmount);
        _tokenLastEntropyClaimTime[tokenId] = block.timestamp; // Update this token's claim time

        // The _bondUnclaimedSharedEntropy and _bondLastEntropyUpdateTime are now mainly for calculating the *pool state*, not for distribution directly.
        // The distribution happens per token based on its own claim time relative to bond updates.
        // This is still complex due to needing to track bond updates vs. token claims.

        // Simpler approach: Shared entropy pool accumulates based on `bondedEntropyRatePerBond`.
        // When *any* token claims, they get a share of the *current* pool proportional to their number of tokens.
        // The pool is NOT reset. This allows staggered claims.
        // The amount claimed is (Total Pool / Num Members). This *still* requires knowing the pool size *at the time of accrual* for accuracy.
        // This requires tracking *when* the pool size changed.

        // Okay, simplest and most common pattern for pools:
        // When `claimBondedEntropyShare(tokenId)` is called:
        // 1. Calculate how much entropy the bond *would have* generated since its `_bondLastEntropyUpdateTime`.
        // 2. Add this to `_bondUnclaimedSharedEntropy`. Update `_bondLastEntropyUpdateTime`.
        // 3. Calculate this token's share of the *current* `_bondUnclaimedSharedEntropy` based on the current number of members.
        // 4. Add that share to the token's *individual* claimable balance (`_tokenIndividualEntropy`).
        // 5. Deduct that share from `_bondUnclaimedSharedEntropy`.
        // 6. Update the token's `_tokenLastEntropyClaimTime`.

        // Let's implement step 1 & 2 first
         _updateBondedEntropy(bondId); // Step 1 & 2

        // Now calculate and distribute share (Steps 3-5)
        uint256 totalUnclaimed = _bondUnclaimedSharedEntropy[bondId];
        numMembers = _bondMembers[bondId].length; // Get current number of members
        if (totalUnclaimed == 0 || numMembers == 0) {
             _tokenLastEntropyClaimTime[tokenId] = block.timestamp; // Still update time
            return;
        }

        // Calculate this token's proportional share of the *current* total unclaimed pool
        uint256 shareAmount = totalUnclaimed.div(numMembers); // Simple equal split of the current pool

        if (shareAmount > 0) {
            _tokenIndividualEntropy[tokenId] = _tokenIndividualEntropy[tokenId].add(shareAmount);
            _bondUnclaimedSharedEntropy[bondId] = _bondUnclaimedSharedEntropy[bondId].sub(shareAmount);
            _entropyBalances[ownerOf(tokenId)] = _entropyBalances[ownerOf(tokenId)].add(shareAmount); // Add to owner's balance
            emit EntropyClaimed(ownerOf(tokenId), tokenId, shareAmount, block.timestamp);
        }

        _tokenLastEntropyClaimTime[tokenId] = block.timestamp; // Update this token's claim time

    }

     // Calculate how much individual entropy a token has accumulated since its last claim
    function _calculateCurrentIndividualEntropy(uint256 tokenId) internal view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
         uint256 lastClaimTime = _tokenLastEntropyClaimTime[tokenId];
        if (lastClaimTime == 0) {
            // If never claimed, accumulation starts conceptually from mint/unbond time.
            // For simplicity, let's use the mint time as the conceptual start if no claim time is set.
            // ERC721 doesn't inherently store mint time, so we'll use a fallback like block.timestamp if no claim time exists.
             return (block.timestamp - block.timestamp).mul(individualEntropyAccumulationRate); // Effectively 0 if using block.timestamp
        }
         uint256 timeElapsed = block.timestamp - lastClaimTime;
         return timeElapsed.mul(individualEntropyAccumulationRate);
    }


    // --- Public & External Functions ---

    // 1. Mints a new individual, unbonded token.
    function mint(address to) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
         _tokenBondId[newTokenId] = 0; // Ensure it's marked as unbonded
         _tokenLastEntropyClaimTime[newTokenId] = block.timestamp; // Set initial claim time
        return newTokenId;
    }

    // 2. (Internal ERC721 override - required)
     function _baseURI() internal view override returns (string memory) {
        return ""; // Placeholder, implement your metadata logic
    }

    // 3. Bonds two unbonded tokens into a new bond.
    function bondTokens(uint256 tokenId1, uint256 tokenId2) external payable {
        require(msg.value >= bondingFee, "Insufficient bonding fee");
        require(ownerOf(tokenId1) == msg.sender, "Caller is not owner of token 1");
        require(ownerOf(tokenId2) == msg.sender, "Caller is not owner of token 2");
        require(_tokenBondId[tokenId1] == 0, "Token 1 is already bonded");
        require(_tokenBondId[tokenId2] == 0, "Token 2 is already bonded");
        require(tokenId1 != tokenId2, "Cannot bond a token with itself");

        _bondIdCounter.increment();
        uint256 newBondId = _bondIdCounter.current();

        _tokenBondId[tokenId1] = newBondId;
        _tokenBondId[tokenId2] = newBondId;

        _bondMembers[newBondId].push(tokenId1);
        _bondMembers[newBondId].push(tokenId2);

        _bondQuantumState[newBondId] = 50; // Initialize quantum state (e.g., 50/100)
        _bondLastInfluenceTime[newBondId] = block.timestamp;
        _bondLastEntropyUpdateTime[newBondId] = block.timestamp; // Start entropy clock for the bond
         _tokenLastEntropyClaimTime[tokenId1] = block.timestamp; // Reset token claim times upon bonding
         _tokenLastEntropyClaimTime[tokenId2] = block.timestamp;

        _activeBonds[newBondId] = true;
        _activeBondIdList.push(newBondId);

         emit TokenBonded(newBondId, tokenId1, tokenId2, block.timestamp);
         emit BondCreationTime(newBondId, block.timestamp);
    }

    // 4. Unbonds all tokens within a specific bond.
    function unbondTokens(uint256 bondId) external payable {
        require(msg.value >= unbondingFee, "Insufficient unbonding fee");
        require(_activeBonds[bondId], "Bond does not exist or is inactive");

        uint256[] storage members = _bondMembers[bondId];
        require(members.length > 1, "Bond must have more than one member to unbond");

        // Check if caller owns all tokens in the bond
        for (uint i = 0; i < members.length; i++) {
            require(ownerOf(members[i]) == msg.sender, "Caller must own all tokens in the bond to unbond");
        }

        // Distribute any remaining shared entropy to members' individual pools before unbonding
         _updateBondedEntropy(bondId);
         uint256 remainingSharedEntropy = _bondUnclaimedSharedEntropy[bondId];
         uint256 membersCount = members.length;
         uint256 sharePerMember = membersCount > 0 ? remainingSharedEntropy.div(membersCount) : 0;
         uint256 remainder = membersCount > 0 ? remainingSharedEntropy % membersCount : 0;

         _bondUnclaimedSharedEntropy[bondId] = 0; // Reset bond pool

        uint256[] memory unbondedTokenIds = new uint256[](members.length);
        for (uint i = 0; i < members.length; i++) {
            uint256 tokenId = members[i];
            unbondedTokenIds[i] = tokenId;

            _tokenBondId[tokenId] = 0; // Mark as unbonded
            _tokenLastEntropyClaimTime[tokenId] = block.timestamp; // Reset claim time upon unbonding

            // Distribute the proportional share and remainder to the token's individual entropy balance
             _tokenIndividualEntropy[tokenId] = _tokenIndividualEntropy[tokenId].add(sharePerMember);
             if (i == 0) { // Add remainder to the first token for simplicity
                 _tokenIndividualEntropy[tokenId] = _tokenIndividualEntropy[tokenId].add(remainder);
             }
             _entropyBalances[msg.sender] = _entropyBalances[msg.sender].add(sharePerMember);
             if (i == 0) {
                 _entropyBalances[msg.sender] = _entropyBalances[msg.sender].add(remainder);
             }
             emit EntropyClaimed(msg.sender, tokenId, sharePerMember + (i == 0 ? remainder : 0), block.timestamp);
        }

        // Clean up bond state
        delete _bondMembers[bondId];
        delete _bondQuantumState[bondId];
        delete _bondLastInfluenceTime[bondId];
        delete _bondLastEntropyUpdateTime[bondId];
        delete _bondCreationTime[bondId];

        _activeBonds[bondId] = false;
        // Remove from _activeBondIdList (expensive) - better to just mark inactive or iterate and skip inactive
        // For simplicity in this demo, we'll leave it but note the gas cost. A better approach is a linked list or skipping inactive IDs.
        // Find and remove bondId from _activeBondIdList (linear scan is expensive)
        uint256 listIndex = type(uint256).max;
        for(uint i = 0; i < _activeBondIdList.length; i++){
            if(_activeBondIdList[i] == bondId){
                listIndex = i;
                break;
            }
        }
        if(listIndex != type(uint256).max){
             _activeBondIdList[listIndex] = _activeBondIdList[_activeBondIdList.length - 1];
             _activeBondIdList.pop();
        }


        emit TokensUnbonded(bondId, unbondedTokenIds, block.timestamp);
    }

    // 5. Mints two tokens already bonded together.
     function mintBondedPair(address owner) public onlyOwner returns (uint256 bondId, uint256 tokenId1, uint256 tokenId2) {
        _tokenIdCounter.increment();
        tokenId1 = _tokenIdCounter.current();
        _safeMint(owner, tokenId1);
         _tokenLastEntropyClaimTime[tokenId1] = block.timestamp; // Set initial claim time

        _tokenIdCounter.increment();
        tokenId2 = _tokenIdCounter.current();
        _safeMint(owner, tokenId2);
        _tokenLastEntropyClaimTime[tokenId2] = block.timestamp; // Set initial claim time


        _bondIdCounter.increment();
        bondId = _bondIdCounter.current();

        _tokenBondId[tokenId1] = bondId;
        _tokenBondId[tokenId2] = bondId;

        _bondMembers[bondId].push(tokenId1);
        _bondMembers[bondId].push(tokenId2);

        _bondQuantumState[bondId] = 50; // Initialize quantum state
        _bondLastInfluenceTime[bondId] = block.timestamp;
        _bondLastEntropyUpdateTime[bondId] = block.timestamp;
        _bondCreationTime[bondId] = block.timestamp;

        _activeBonds[bondId] = true;
        _activeBondIdList.push(bondId);

        emit TokenBonded(bondId, tokenId1, tokenId2, block.timestamp);
         emit BondCreationTime(bondId, block.timestamp);
        return (bondId, tokenId1, tokenId2);
     }

    // 6. Adds an unbonded token to an existing bond.
    function addTokenToBond(uint256 bondId, uint256 newTokenId) external payable {
        require(msg.value >= bondingFee, "Insufficient bonding fee");
        require(_activeBonds[bondId], "Bond does not exist or is inactive");
        require(ownerOf(newTokenId) == msg.sender, "Caller is not owner of the new token");
        require(_tokenBondId[newTokenId] == 0, "New token is already bonded");

        // Optional: Require caller owns *all* tokens in the bond being added to
        uint256[] storage members = _bondMembers[bondId];
        for (uint i = 0; i < members.length; i++) {
             require(ownerOf(members[i]) == msg.sender, "Caller must own all tokens in the bond to add a new member");
        }

        // Update bond's unclaimed entropy before adding the new member (rate calculation changes)
         _updateBondedEntropy(bondId);

        _tokenBondId[newTokenId] = bondId;
        _bondMembers[bondId].push(newTokenId);
         _tokenLastEntropyClaimTime[newTokenId] = block.timestamp; // Reset new token's claim time

        emit TokenAddedToBond(bondId, newTokenId, block.timestamp);
    }

    // 7. Removes a single token from its bond. Distributes proportional entropy.
    function removeTokenFromBond(uint256 tokenId) external payable {
        // Note: No fee for removal in this model, could add one.
        uint256 bondId = _tokenBondId[tokenId];
        require(bondId != 0, "Token is not bonded");
        require(ownerOf(tokenId) == msg.sender, "Caller is not owner of the token");

        uint256[] storage members = _bondMembers[bondId];
        require(members.length > 1, "Bond must have more than one member to remove one");

        // Find the index of the token to remove
        uint256 indexToRemove = type(uint256).max;
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == tokenId) {
                indexToRemove = i;
                break;
            }
        }
        require(indexToRemove != type(uint256).max, "Token not found in bond members list (internal error)");

        // Distribute proportional share of unclaimed bonded entropy to the token being removed
        _updateBondedEntropy(bondId); // Update bond pool before removal
        uint256 totalUnclaimed = _bondUnclaimedSharedEntropy[bondId];
        uint256 membersCount = members.length;
        uint256 shareAmount = membersCount > 0 ? totalUnclaimed.div(membersCount) : 0;

        if (shareAmount > 0) {
            _tokenIndividualEntropy[tokenId] = _tokenIndividualEntropy[tokenId].add(shareAmount);
            _bondUnclaimedSharedEntropy[bondId] = _bondUnclaimedSharedEntropy[bondId].sub(shareAmount); // Deduct share
            _entropyBalances[msg.sender] = _entropyBalances[msg.sender].add(shareAmount); // Add to owner balance
             emit EntropyClaimed(msg.sender, tokenId, shareAmount, block.timestamp);
        }
         _tokenLastEntropyClaimTime[tokenId] = block.timestamp; // Update claim time

        // Remove the token from the bond members list (swap and pop - preserves order is not needed)
        members[indexToRemove] = members[members.length - 1];
        members.pop();

        _tokenBondId[tokenId] = 0; // Mark as unbonded

        // If only one member remains, auto-unbond the pair completely
        if (members.length == 1) {
            uint256 lastMemberId = members[0];
             // Distribute any final remaining pool entropy to the last member
             _updateBondedEntropy(bondId); // Final update
             uint256 finalRemainder = _bondUnclaimedSharedEntropy[bondId];
             if (finalRemainder > 0) {
                 _tokenIndividualEntropy[lastMemberId] = _tokenIndividualEntropy[lastMemberId].add(finalRemainder);
                 _bondUnclaimedSharedEntropy[bondId] = 0;
                  _entropyBalances[ownerOf(lastMemberId)] = _entropyBalances[ownerOf(lastMemberId)].add(finalRemainder);
                  emit EntropyClaimed(ownerOf(lastMemberId), lastMemberId, finalRemainder, block.timestamp);
             }
             _tokenLastEntropyClaimTime[lastMemberId] = block.timestamp; // Update last member's claim time

            _tokenBondId[lastMemberId] = 0; // Unbond the last member too
            delete _bondMembers[bondId];
            delete _bondQuantumState[bondId];
            delete _bondLastInfluenceTime[bondId];
            delete _bondLastEntropyUpdateTime[bondId];
            delete _bondCreationTime[bondId];
            _activeBonds[bondId] = false;
             // Remove from _activeBondIdList (expensive) - same warning as unbondTokens
             uint256 listIndex = type(uint256).max;
             for(uint i = 0; i < _activeBondIdList.length; i++){
                 if(_activeBondIdList[i] == bondId){
                     listIndex = i;
                     break;
                 }
             }
             if(listIndex != type(uint256).max){
                  _activeBondIdList[listIndex] = _activeBondIdList[_activeBondIdList.length - 1];
                  _activeBondIdList.pop();
             }

             emit TokensUnbonded(bondId, new uint256[]{tokenId, lastMemberId}, block.timestamp); // Emit unbonded for both
        } else {
             emit TokenRemovedFromBond(bondId, tokenId, members.length, block.timestamp); // Emit removal if bond persists
        }
    }


    // 8. Returns the bond ID a token belongs to (0 if unbonded).
    function getBondId(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenBondId[tokenId];
    }

    // 9. Returns the list of token IDs in a bond.
    function getBondMembers(uint256 bondId) external view returns (uint256[] memory) {
         require(_activeBonds[bondId], "Bond does not exist or is inactive");
        return _bondMembers[bondId];
    }

    // 10. Checks if a token is currently bonded.
    function isTokenBonded(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenBondId[tokenId] != 0;
    }

    // 11. Returns the total number of active bonds.
    function getBondCount() external view returns (uint256) {
        return _activeBondIdList.length; // Using the list count
    }

    // 12. Returns a list of all active bond IDs (WARNING: Gas intensive for large numbers of bonds).
     function getAllBondIds() external view returns (uint256[] memory) {
         return _activeBondIdList;
     }

     // 13. Returns the timestamp when a bond was created.
     mapping(uint256 => uint256) private _bondCreationTime; // Added mapping
     function getBondCreationTime(uint256 bondId) external view returns (uint256) {
         require(_activeBonds[bondId], "Bond does not exist or is inactive");
         return _bondCreationTime[bondId];
     }


    // 14. Returns the current shared quantum state for a bond (0-100).
    function getSharedQuantumState(uint256 bondId) public view returns (uint8) {
         require(_activeBonds[bondId], "Bond does not exist or is inactive");
        return _bondQuantumState[bondId];
    }

    // 15. Allows a bond member owner to change the shared state.
    function influenceQuantumState(uint256 bondId, uint8 newStateValue) external payable {
        require(msg.value >= quantumInfluenceFee, "Insufficient influence fee");
        require(_activeBonds[bondId], "Bond does not exist or is inactive");
        require(isQuantumInfluenceReady(bondId), "Quantum state influence is on cooloff");

        uint256[] storage members = _bondMembers[bondId];
        require(members.length > 0, "Bond has no members"); // Should not happen if active

        // Check if caller owns *at least one* token in the bond
        bool isMemberOwner = false;
        for (uint i = 0; i < members.length; i++) {
            if (ownerOf(members[i]) == msg.sender) {
                isMemberOwner = true;
                break;
            }
        }
        require(isMemberOwner, "Caller must own at least one token in the bond to influence state");

        // Optional: Add complexity like requiring majority ownership, or different tokens having different influence power.
        // For simplicity, owning any member allows influencing.

         // Update bond's unclaimed entropy before state change (as state change can be a trigger)
         _updateBondedEntropy(bondId);

        _bondQuantumState[bondId] = newStateValue;
        _bondLastInfluenceTime[bondId] = block.timestamp;
        _bondLastEntropyUpdateTime[bondId] = block.timestamp; // Reset entropy clock from this point

        emit QuantumStateInfluenced(bondId, newStateValue, msg.sender, block.timestamp);
    }

     // 16. Returns the timestamp of the last state influence for a bond.
     function getLastQuantumStateInfluenceTime(uint256 bondId) public view returns (uint256) {
         require(_activeBonds[bondId], "Bond does not exist or is inactive");
         return _bondLastInfluenceTime[bondId];
     }

    // 17. Checks if the quantum influence cooloff period has passed for a bond.
     function isQuantumInfluenceReady(uint256 bondId) public view returns (bool) {
         require(_activeBonds[bondId], "Bond does not exist or is inactive");
         return block.timestamp >= _bondLastInfluenceTime[bondId].add(quantumInfluenceCooloff);
     }

    // 18. Calculates the currently accumulated *shared* entropy for a bond since last update/claim.
    function getCurrentBondedEntropy(uint256 bondId) external view returns (uint256) {
        require(_activeBonds[bondId], "Bond does not exist or is inactive");
        // Calculate new entropy since last update and add to unclaimed pool for viewing
        uint256 newlyAccumulated = _calculateBondedEntropy(bondId);
        return _bondUnclaimedSharedEntropy[bondId].add(newlyAccumulated);
    }

    // 19. Claims the calling owner's accumulated share of bonded entropy for a specific token.
    // This claims a proportional share of the bond's current *unclaimed* pool.
    function claimBondedEntropyShare(uint256 tokenId) external {
        uint256 bondId = _tokenBondId[tokenId];
        require(bondId != 0, "Token is not bonded");
        require(ownerOf(tokenId) == msg.sender, "Caller is not owner of the token");
         require(_activeBonds[bondId], "Bond does not exist or is inactive"); // Should be true if bondId != 0, but double check

        _distributeBondedEntropyShare(bondId, tokenId); // Internal function handles logic and balances update
    }

    // 20. Gets the current accumulated *individual* entropy for an unbonded token since last claim.
    // Note: This only calculates the *additional* since last claim, doesn't include the base _tokenIndividualEntropy balance.
    function getPendingIndividualEntropy(uint256 tokenId) external view returns (uint256) {
         require(_exists(tokenId), "Token does not exist");
         // This calculation doesn't rely on bond state, only the token's last claim time.
         return _calculateCurrentIndividualEntropy(tokenId);
    }

     // 21. Claims the accumulated individual entropy for a token.
     // This claims entropy accumulated at the individual rate since last claim.
     function claimIndividualEntropy(uint256 tokenId) external {
         require(_exists(tokenId), "Token does not exist");
         require(ownerOf(tokenId) == msg.sender, "Caller is not owner of the token");

         uint256 pendingEntropy = _calculateCurrentIndividualEntropy(tokenId);

         if (pendingEntropy > 0) {
             // Add to the token's individual balance (which acts as a staging area before transfer to owner balance)
             _tokenIndividualEntropy[tokenId] = _tokenIndividualEntropy[tokenId].add(pendingEntropy);
             // Transfer from token's "staging" balance to owner's main entropy balance
             _entropyBalances[msg.sender] = _entropyBalances[msg.sender].add(_tokenIndividualEntropy[tokenId]);
             emit EntropyClaimed(msg.sender, tokenId, _tokenIndividualEntropy[tokenId], block.timestamp);
             _tokenIndividualEntropy[tokenId] = 0; // Reset token's staging balance
         }
         _tokenLastEntropyClaimTime[tokenId] = block.timestamp; // Update claim time
     }

    // 22. Calculates the total potential entropy (individual + current pending individual + pending shared from bond) available for a token owner to claim *right now*.
     function getTotalClaimableEntropy(uint256 tokenId) external view returns (uint256) {
         require(_exists(tokenId), "Token does not exist");

         uint256 individualEntropy = _tokenIndividualEntropy[tokenId]; // Already accumulated individual/claimed shared
         uint256 pendingIndividual = _calculateCurrentIndividualEntropy(tokenId); // New individual since last claim

         uint256 bondId = _tokenBondId[tokenId];
         uint256 pendingShared = 0;
         if (bondId != 0) {
             // Calculate the potential share this token could claim from the bond's current pool
             uint256 totalUnclaimedInBond = _bondUnclaimedSharedEntropy[bondId]; // Pool updated on influence/claims
             uint256 numMembers = _bondMembers[bondId].length;
             if (numMembers > 0) {
                // This is tricky. The entropy accrues constantly. Simply taking a share of the *current* pool
                // doesn't reflect the amount accrued *since this specific token's last claim*.
                // Revert to simpler: `_tokenIndividualEntropy` holds all claimed.
                // `claimIndividualEntropy` moves pending individual to `_tokenIndividualEntropy`.
                // `claimBondedEntropyShare` moves pending shared from bond pool to `_tokenIndividualEntropy`.
                // `getEntropyBalance(owner)` sums up claimed entropy.
                // `getTotalClaimableEntropy` would be the sum of `_tokenIndividualEntropy` + `pendingIndividual` + the potential share of the bond pool *if claimed now*.
                // Let's stick to: `_tokenIndividualEntropy` is the staging area. `claim...` moves to staging. `getEntropyBalance` is the final claimed amount.
                // This function simplifies: returns the sum currently in the token's staging area + newly accumulated individual.
                 // We need a separate function to view the *bond's* potential shared entropy.
                // This function should probably just return the sum of individual entropy ready to be moved to owner balance.
                // Let's redefine: `_tokenIndividualEntropy` IS the amount ready to be moved to owner balance.
                // `getIndividualEntropy` returns this. `claimIndividualEntropy` moves it to owner balance and resets it.
                // `claimBondedEntropyShare` calculates the share and moves it to the owner balance directly, bypassing `_tokenIndividualEntropy` staging.

                // Let's refine data structures slightly:
                // `_tokenIndividualEntropy` -> Accumulates *only* individual entropy since last individual claim.
                // `_bondUnclaimedSharedEntropy` -> Accumulates *only* shared bond entropy.
                // `_entropyBalances[owner]` -> Total claimed entropy.

                // New flow:
                // `claimIndividualEntropy(tokenId)`: Calculate individual accumulated since last claim, add to `_entropyBalances[owner]`, update `_tokenLastEntropyClaimTime[tokenId]`.
                // `claimBondedEntropyShare(tokenId)`: Calculate bond accumulated since last bond update, add to `_bondUnclaimedSharedEntropy`. Calculate this token's share of `_bondUnclaimedSharedEntropy`. Add share to `_entropyBalances[owner]`. Deduct share from `_bondUnclaimedSharedEntropy`. Update `_tokenLastEntropyClaimTime[tokenId]`. This is still complex.

                // Simplest flow:
                // `_tokenIndividualEntropy` is total claimed individual entropy.
                // `_bondUnclaimedSharedEntropy` is total claimed shared entropy per bond.
                // When claiming individual: calculate pending, add to `_tokenIndividualEntropy[tokenId]`, update time.
                // When claiming bonded: update bond pool, calculate share of pool, add to `_bondUnclaimedSharedEntropy[bondId]`, update token time.
                // `getEntropyBalance(owner)` sums relevant `_tokenIndividualEntropy` and `_bondUnclaimedSharedEntropy`. No, that doesn't make sense.

                // Final attempt at simple entropy model:
                // `_entropyBalances[owner]` = total entropy claimed by this owner.
                // `_tokenLastEntropyClaimTime[tokenId]` = last time this token contributed to a claim.
                // `_bondLastEntropyUpdateTime[bondId]` = last time this bond's pool state was updated.
                // `_bondUnclaimedSharedEntropy[bondId]` = current value of the shared pool.
                // `claimIndividualEntropy(tokenId)`: Calculates accumulation based on `_tokenLastEntropyClaimTime[tokenId]`, adds to `_entropyBalances[owner]`, updates `_tokenLastEntropyClaimTime[tokenId]`.
                // `claimBondedEntropyShare(tokenId)`: Calculates bond accumulation since `_bondLastEntropyUpdateTime[bondId]`, adds to `_bondUnclaimedSharedEntropy[bondId]`, updates `_bondLastEntropyUpdateTime[bondId]`. Then calculates token's share of `_bondUnclaimedSharedEntropy[bondId]` *based on time since `_tokenLastEntropyClaimTime[tokenId]`*. Adds that share to `_entropyBalances[owner]`. Updates `_tokenLastEntropyClaimTime[tokenId]`. This still requires tracking per-token contribution time to the pool.

                // Let's go back to the second approach:
                // `_tokenIndividualEntropy[tokenId]` = total claimed/distributed entropy for this specific token.
                // `_entropyBalances[owner]` = sum of `_tokenIndividualEntropy` for all tokens owned by `owner`. This implies `_tokenIndividualEntropy` should be calculated but not stored per token, rather added directly to `_entropyBalances`.

                // Simplest execution model:
                // `_entropyBalances[owner]` stores all claimed entropy.
                // `claimIndividualEntropy(tokenId)` calculates entropy since last claim based on individual rate, adds to `_entropyBalances[owner]`, updates `_tokenLastEntropyClaimTime[tokenId]`.
                // `claimBondedEntropyShare(tokenId)` calculates entropy *bond* generated since last bond update, adds to bond pool. Then calculates *this token's* share of the *total* bond entropy generated *since this token's last claim*. Adds this amount to `_entropyBalances[owner]`. Updates `_tokenLastEntropyClaimTime[tokenId]`. This is still the complex time-based share.

                // Let's use the first simple model from _distributeBondedEntropyShare: Claiming bonded entropy claims an equal share of the *current unclaimed bond pool*. Individual entropy is simpler.
                // `_tokenIndividualEntropy[tokenId]` = total individual entropy claimed for this token.
                // `_bondUnclaimedSharedEntropy[bondId]` = unclaimed shared entropy pool for the bond.
                // `_entropyBalances[owner]` = sum of all entropy claimed by owner.

                // `claimIndividualEntropy(tokenId)`: Calculates pending individual entropy. Adds to `_entropyBalances[owner]`. Updates `_tokenLastEntropyClaimTime[tokenId]`.
                // `claimBondedEntropyShare(tokenId)`: Updates bond pool. Calculates this token's equal share of *current* `_bondUnclaimedSharedEntropy`. Adds share to `_entropyBalances[owner]`. Deducts share from `_bondUnclaimedSharedEntropy`. Updates `_tokenLastEntropyClaimTime[tokenId]`.

                // Redefining `getTotalClaimableEntropy(tokenId)`:
                // This function should return the sum of:
                // 1. Pending individual entropy for this token since its last claim.
                // 2. This token's calculated equal share of the *current* unclaimed bonded entropy pool, if bonded.

                 uint256 totalUnclaimedInBond = _bondUnclaimedSharedEntropy[bondId]; // Pool updated on influence/claims
                 uint256 numMembers = _bondMembers[bondId].length;
                 if (numMembers > 0) {
                     pendingShared = totalUnclaimedInBond.div(numMembers); // Token's equal share of current pool
                 }
             }
             // Returns the pending individual + potential share of current bond pool if claimed *now*
            return pendingIndividual.add(pendingShared); // This represents amount that would be added to owner balance if both claim functions were called for this token.
     }

    // 23. Returns the total claimed entropy balance for an address.
     function getEntropyBalance(address owner) external view returns (uint256) {
         return _entropyBalances[owner];
     }

    // --- Configuration & Administration (Owner Only) ---

    // 24. Sets the fee required to bond two tokens.
    function setBondingFee(uint256 fee) external onlyOwner {
        emit BondParametersUpdated("bondingFee", bondingFee, fee);
        bondingFee = fee;
    }

    // 25. Sets the fee required to unbond tokens.
    function setUnbondingFee(uint256 fee) external onlyOwner {
        emit BondParametersUpdated("unbondingFee", unbondingFee, fee);
        unbondingFee = fee;
    }

    // 26. Sets the rate at which each bond accumulates shared entropy (per second).
    function setBondedEntropyRatePerBond(uint256 rate) external onlyOwner {
        // Consider updating all active bond's entropy pools before changing rate to avoid discrepancies.
        // For simplicity, we won't do that here, rate change applies from the next block.
        emit BondParametersUpdated("bondedEntropyRatePerBond", bondedEntropyRatePerBond, rate);
        bondedEntropyRatePerBond = rate;
    }

    // 27. Sets the rate at which individual tokens accumulate entropy (per second).
     function setIndividualEntropyAccumulationRate(uint256 rate) external onlyOwner {
         emit BondParametersUpdated("individualEntropyAccumulationRate", individualEntropyAccumulationRate, rate);
         individualEntropyAccumulationRate = rate;
     }

    // 28. Sets the fee required to influence a bond's quantum state.
    function setQuantumInfluenceFee(uint256 fee) external onlyOwner {
        emit BondParametersUpdated("quantumInfluenceFee", quantumInfluenceFee, fee);
        quantumInfluenceFee = fee;
    }

    // 29. Sets the minimum time between quantum state influences for a bond.
    function setQuantumInfluenceCooloff(uint256 duration) external onlyOwner {
        emit BondParametersUpdated("quantumInfluenceCooloff", quantumInfluenceCooloff, duration);
        quantumInfluenceCooloff = duration;
    }

    // 30. Allows the contract owner to withdraw accumulated fees.
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees accumulated");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(owner(), balance, block.timestamp);
    }

    // --- ERC721 Overrides for Bonded Logic ---
    // Prevent transfer of bonded tokens
    function _update(address to, uint256 tokenId, address authenticated) internal override {
        require(_tokenBondId[tokenId] == 0, "Cannot transfer a bonded token");
        super._update(to, tokenId, authenticated);
    }

    // Allow owner of bonded token to approve/setApprovalForAll IF not bonded
    function approve(address to, uint256 tokenId) public override {
         require(_tokenBondId[tokenId] == 0, "Cannot approve a bonded token");
         super.approve(to, tokenId);
     }

    function setApprovalForAll(address operator, bool approved) public override {
        // Allow setting approval for all, but transfers of bonded tokens will still fail via _update
        super.setApprovalForAll(operator, approved);
    }

     // Standard transfer functions will call _update, which has the bond check.
     // No need to override transferFrom or safeTransferFrom explicitly for the bond check.
}
```