Okay, here is a Solidity smart contract implementing a concept called "EtherealNexus," managing dynamic, evolving digital assets called "Fragments." This contract incorporates various advanced, creative, and trendy concepts like dynamic NFT attributes, energy mechanics, scheduled/incentivized decay, on-chain combining rules, permissioned off-chain delegation via signatures, external data influence simulation, prediction views, and role-based access control beyond standard ownership.

It uses OpenZeppelin libraries for standard functionalities like ERC721 and Ownable, as requested implicitly by the need for standard NFT behavior without reinventing basic building blocks. The *custom logic* for fragment dynamics, interactions, delegation, and system management is novel.

---

### **EtherealNexus Smart Contract Outline & Function Summary**

**Contract Name:** `EtherealNexus`

**Concept:** Manages a collection of unique, dynamic digital assets called "Fragments" (ERC721 tokens). Fragments possess static attributes and dynamic state (e.g., "Charge," "Essence"). Their state evolves over time (decay) and through user interactions (charging, combining, extracting). The system allows for configurable parameters, operator roles, and advanced interactions like delegated actions via signatures and influence from simulated external data.

**Core Features & Concepts:**

1.  **Dynamic NFTs:** Fragment state (`charge`, `essence`) changes over time and interaction.
2.  **Energy Mechanics:** Fragments have "Charge" which accrues "Essence" over time.
3.  **Scheduled/Incentivized Decay:** A mechanism for fragment state to degrade, callable by anyone (requiring incentives in a real system).
4.  **Yield Extraction:** Users can extract "Essence" from charged fragments.
5.  **On-chain Combining:** Fragments can be combined, potentially consuming them and altering resulting attributes/state based on defined rules.
6.  **Permissioned Delegation:** Owners can authorize specific actions on their fragments to third parties off-chain using signed messages (meta-transaction potential).
7.  **External Influence Simulation:** System operators can record simulated external events that influence fragment dynamics (e.g., decay rates).
8.  **Prediction Views:** View functions to estimate future fragment states.
9.  **Configurable Parameters:** Owner/Operators can adjust key dynamics like extraction rates, decay rates, etc.
10. **Role-Based Access Control:** Custom "SystemOperator" role for specific management functions.
11. **Protocol Fees:** Mechanisms for collecting fees on certain operations (e.g., Essence extraction).
12. **Token Sacrifice:** Option to burn a fragment for a system-wide or owner-specific benefit.
13. **Simulated Randomness:** Function to request a pseudo-random attribute value (with security disclaimer).

**Function Summary (Grouped by Functionality):**

*   **Core ERC721 Operations (Standard):**
    *   `balanceOf(address owner)`: Get number of fragments owned by an address.
    *   `ownerOf(uint256 tokenId)`: Get owner of a specific fragment.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfer fragment (safe version).
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Transfer fragment with data.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer fragment (unsafe version).
    *   `approve(address to, uint256 tokenId)`: Approve an address to transfer a specific fragment.
    *   `getApproved(uint256 tokenId)`: Get the approved address for a fragment.
    *   `setApprovalForAll(address operator, bool approved)`: Approve/disapprove an operator for all fragments.
    *   `isApprovedForAll(address owner, address operator)`: Check operator approval status.
    *   `supportsInterface(bytes4 interfaceId)`: Standard interface support check.
    *   `setTokenMetadataURI(uint256 tokenId, string uri)`: Set token URI (using ERC721URIStorage).

*   **Fragment Lifecycle & State:**
    *   `mintFragment(address recipient, uint256 initialAttributeValue)`: Mint a new fragment with initial attributes. (Owner/Operator only)
    *   `getFragmentAttributes(uint256 tokenId)`: Get the static attributes of a fragment.
    *   `getFragmentDynamicState(uint256 tokenId)`: Get the current dynamic state (charge, last decay time) of a fragment.
    *   `chargeFragment(uint256 tokenId)`: Add "Charge" to a fragment (user initiated, potentially costs something).
    *   `decayFragments(uint256[] tokenIds)`: Apply decay to specified fragments (permissionless, incentivizable).
    *   `extractEssence(uint256 tokenId)`: Extract accrued "Essence" from a fragment (burns charge, potentially pays user).
    *   `sacrificeFragment(uint256 tokenId)`: Burn a fragment for a specific effect.

*   **Fragment Interactions & Evolution:**
    *   `combineFragments(uint256 tokenId1, uint256 tokenId2)`: Attempt to combine two fragments based on configured rules (burns inputs, potentially mints new).
    *   `configureFragmentInteractionRules(uint256 type1, uint256 type2, bytes memory resultingAttributesPacked)`: Set rules for combining specific fragment types. (Owner/Operator only)
    *   `getFragmentInteractionRules(uint256 type1, uint256 type2)`: Get the combination rules for two fragment types.
    *   `getCombinedFragmentPreview(uint256 tokenId1, uint256 tokenId2)`: View function to preview potential outcome of combining (without executing).

*   **System Management & Configuration:**
    *   `setEssenceExtractionRate(uint256 rate)`: Set the rate of Essence generation per Charge. (Owner/Operator only)
    *   `setMinChargeValue(uint256 minCharge)`: Set minimum charge required for extraction. (Owner/Operator only)
    *   `setDecayRate(uint256 decayPerSecond)`: Set the base rate of Charge decay. (Owner/Operator only)
    *   `addSystemOperator(address operator)`: Grant SystemOperator role. (Owner only)
    *   `removeSystemOperator(address operator)`: Revoke SystemOperator role. (Owner only)
    *   `hasSystemOperatorRole(address account)`: Check if an address is a SystemOperator.
    *   `recordExternalInfluence(uint256 influenceFactor)`: Record a simulated external event factor affecting dynamics. (Operator only)
    *   `getProtocolFeeRate()`: Get the current fee percentage for extractions.
    *   `setProtocolFeeRate(uint256 feeBasisPoints)`: Set the fee percentage (in basis points). (Owner only)
    *   `claimProtocolFees()`: Owner/Operator can claim accumulated protocol fees (ETH).

*   **Advanced & Utility:**
    *   `delegateFragmentActionSignature(uint256 tokenId, bytes32 actionHash, uint256 nonce, uint256 expiration)`: Helper view to calculate the hash signed for delegation.
    *   `executeDelegatedFragmentAction(address signer, uint256 tokenId, bytes32 actionHash, uint256 nonce, uint256 expiration, bytes memory signature)`: Execute a specific action on a fragment on behalf of its owner using a signature.
    *   `predictFragmentFutureState(uint256 tokenId, uint256 timeDelta)`: View function to predict fragment state after a time period.
    *   `simulateDecayForFragment(uint256 tokenId, uint256 timeDelta)`: View function to simulate decay effect over a period.
    *   `requestRandomAttributeValue()`: Simulate generating a pseudo-random value for potential attribute assignment. (Owner/Operator only for minting context)
    *   `transferOwnership(address newOwner)`: Transfer ownership of the contract (from Ownable).

*(Note: The count exceeds 20 functions significantly, providing ample examples of distinct logic).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For getting all token IDs
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max if needed
import "@openzeppelin/contracts/utils/Context.sol"; // To use _msgSender()

// Custom Error Definitions
error EtherealNexus__InvalidTokenId();
error EtherealNexus__NotFragmentOwnerOrApproved();
error EtherealNexus__NotFragmentOwnerOrSystemOperator();
error EtherealNexus__InsufficientCharge();
error EtherealNexus__CannotCombine();
error EtherealNexus__InvalidSignature();
error EtherealNexus__SignatureExpired();
error EtherealNexus__NonceAlreadyUsed();
error EtherealNexus__OnlySystemOperator();
error EtherealNexus__OnlyOperatorOrOwner();
error EtherealNexus__NoFeesToClaim();
error EtherealNexus__InvalidFeeRate();

/**
 * @title EtherealNexus
 * @dev A contract managing dynamic, evolving digital assets (Fragments).
 * Includes advanced features like dynamic state, energy mechanics,
 * incentivized decay, on-chain combining with rules, permissioned
 * delegation via signatures, external data influence simulation,
 * prediction views, and custom role-based access control.
 */
contract EtherealNexus is Context, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    using ECDSA for bytes32;

    // --- Structs ---

    struct FragmentAttributes {
        uint256 fragmentType; // e.g., 1=Basic, 2=Charged, 3=Mystic
        uint256 level;        // General progression/tier
        uint256 power;        // Base attribute
        uint256 resilience;   // Base attribute
        // Add more static attributes as needed
    }

    struct FragmentDynamicState {
        uint256 charge;          // Current "energy" stored
        uint64 lastDecayTimestamp; // Timestamp of last decay application
        uint256 essence;         // Accrued yield (can be extracted) - derived from charge over time
    }

    struct FragmentInteractionRule {
        bool enabled;
        bytes resultingAttributesPacked; // Packed attributes for the resulting fragment
        // Could add other effects: fee, burn chance, etc.
    }

    // --- State Variables ---

    // Fragment Data
    mapping(uint256 => FragmentAttributes) private _fragmentAttributes;
    mapping(uint256 => FragmentDynamicState) private _fragmentDynamicState;
    mapping(uint256 => uint256) private _fragmentCreationTime; // Track creation time

    // System Parameters
    uint256 public essenceExtractionRate = 1e16; // How much essence per unit of charge per second (e.g., 0.01 ETH per charge per second)
    uint256 public minChargeValue = 1e18;     // Minimum charge needed to extract essence (e.g., 1 ETH worth of charge)
    uint256 public decayRatePerSecond = 1;    // How much charge decays per second (linear for simplicity)
    uint256 public protocolFeeBasisPoints = 500; // 500 basis points = 5%

    // Role-Based Access Control (Custom Operator Role)
    mapping(address => bool) private _isSystemOperator;

    // Fragment Interaction Rules (Mapping type pairs to a rule)
    // Use a packed uint256 key for the pair: (type1 << 128) | type2
    mapping(uint256 => FragmentInteractionRule) private _fragmentInteractionRules;

    // Delegation Nonces (Prevent replay attacks)
    mapping(address => uint256) private _delegationNonces; // Mapping owner address to its next valid nonce

    // External Influence Simulation
    uint256 public currentExternalInfluenceFactor = 1e18; // Default 1x influence

    // Protocol Fees
    uint256 public collectedProtocolFees; // In native token (ETH)

    // --- Events ---

    event FragmentMinted(uint256 indexed tokenId, address indexed owner, uint256 initialAttributeValue);
    event FragmentCharged(uint256 indexed tokenId, address indexed user, uint256 chargeAdded, uint256 newCharge);
    event FragmentDecayed(uint256 indexed tokenId, uint256 decayAmount, uint256 newCharge, uint256 essenceLost);
    event EssenceExtracted(uint256 indexed tokenId, address indexed user, uint256 essenceAmount, uint256 protocolFee, uint256 remainingCharge);
    event FragmentsCombined(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId); // newTokenId = 0 if no new token minted
    event FragmentSacrificed(uint256 indexed tokenId, address indexed owner);
    event InteractionRuleConfigured(uint256 type1, uint256 type2, bool enabled, bytes resultingAttributesPacked);
    event SystemOperatorAdded(address indexed operator);
    event SystemOperatorRemoved(address indexed operator);
    event ParametersUpdated(string paramName, uint256 newValue);
    event ExternalInfluenceRecorded(uint256 influenceFactor);
    event ProtocolFeesClaimed(address indexed receiver, uint256 amount);
    event DelegationActionExecuted(address indexed signer, uint256 indexed tokenId, bytes32 indexed actionHash, uint256 nonce);


    // --- Modifiers ---

    modifier onlySystemOperator() {
        if (!_isSystemOperator[_msgSender()] && owner() != _msgSender()) {
            revert OnlySystemOperator();
        }
        _;
    }

    modifier onlyOperatorOrOwner() {
         if (!_isSystemOperator[_msgSender()] && owner() != _msgSender()) {
            revert OnlyOperatorOrOwner();
        }
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(_msgSender()) {}

    // --- ERC721 Overrides ---

    // The standard ERC721 functions are available via inheritance:
    // balanceOf, ownerOf, safeTransferFrom, transferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId ||
               interfaceId == type(IERC721URIStorage).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        delete _fragmentAttributes[tokenId];
        delete _fragmentDynamicState[tokenId];
        delete _fragmentCreationTime[tokenId];
        _resetApproved(tokenId); // Clean up approval
    }

    // --- Fragment Lifecycle & State ---

    /**
     * @dev Mints a new fragment.
     * @param recipient The address to mint the fragment to.
     * @param initialAttributeValue A value used to determine initial attributes (simplified).
     */
    function mintFragment(address recipient, uint256 initialAttributeValue) external onlyOperatorOrOwner {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(recipient, newItemId);

        // Initialize static attributes (simplified based on input)
        _fragmentAttributes[newItemId] = FragmentAttributes({
            fragmentType: (initialAttributeValue % 3) + 1, // Basic type derivation
            level: 1,
            power: (initialAttributeValue % 100) + 10,
            resilience: (initialAttributeValue % 50) + 5
        });

        // Initialize dynamic state
        _fragmentDynamicState[newItemId] = FragmentDynamicState({
            charge: 0,
            lastDecayTimestamp: uint64(block.timestamp),
            essence: 0 // Essence is calculated, not stored directly here, but placeholder
        });

        _fragmentCreationTime[newItemId] = block.timestamp;

        emit FragmentMinted(newItemId, recipient, initialAttributeValue);
    }

    /**
     * @dev Gets the static attributes of a fragment.
     * @param tokenId The ID of the fragment.
     * @return The fragment's static attributes.
     */
    function getFragmentAttributes(uint256 tokenId) public view returns (FragmentAttributes memory) {
        if (!_exists(tokenId)) revert EtherealNexus__InvalidTokenId();
        return _fragmentAttributes[tokenId];
    }

    /**
     * @dev Gets the dynamic state of a fragment.
     * Automatically applies pending decay before returning.
     * @param tokenId The ID of the fragment.
     * @return The fragment's dynamic state (adjusted for decay).
     */
    function getFragmentDynamicState(uint256 tokenId) public view returns (FragmentDynamicState memory) {
        if (!_exists(tokenId)) revert EtherealNexus__InvalidTokenId();
        FragmentDynamicState memory state = _fragmentDynamicState[tokenId];

        // Calculate decay since last timestamp
        uint256 timeElapsed = block.timestamp - state.lastDecayTimestamp;
        uint256 decayAmount = timeElapsed * decayRatePerSecond * currentExternalInfluenceFactor / 1e18; // Apply influence factor
        decayAmount = Math.min(decayAmount, state.charge); // Decay cannot exceed current charge

        state.charge -= decayAmount;
        // Essence calculation is complex; simplified: derived from charge.
        // In a real system, Essence generation rate based on charge * decay period * influence factor.
        // For this view, we just return the decayed charge. Essence needs a dedicated calculation function.

        return state;
    }

    /**
     * @dev Adds "Charge" to a fragment. Requires fragment owner or approved.
     * In a real system, this might require sending ETH or a specific token.
     * @param tokenId The ID of the fragment.
     */
    function chargeFragment(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()) && getApproved(tokenId) != _msgSender()) {
             revert EtherealNexus__NotFragmentOwnerOrApproved();
        }
         if (!_exists(tokenId)) revert EtherealNexus__InvalidTokenId();

        _applyDecay(tokenId); // Apply decay before adding charge

        // Simulate adding a fixed amount of charge.
        // In reality, this would be proportional to ETH sent or token amount.
        uint256 chargeToAdd = 1e18; // Example: Add 1 unit of charge
        _fragmentDynamicState[tokenId].charge += chargeToAdd;

        emit FragmentCharged(tokenId, _msgSender(), chargeToAdd, _fragmentDynamicState[tokenId].charge);
    }

    /**
     * @dev Applies decay to a list of fragments. Can be called by anyone.
     * In a real system, calling this function might be incentivized (e.g., with a small token reward).
     * @param tokenIds The IDs of the fragments to decay.
     */
    function decayFragments(uint256[] memory tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_exists(tokenIds[i])) {
                _applyDecay(tokenIds[i]);
            }
        }
        // Potential: Add a small reward here for the caller in a real system
    }

     /**
     * @dev Internal function to apply decay logic to a single fragment.
     * @param tokenId The ID of the fragment.
     */
    function _applyDecay(uint256 tokenId) internal {
         FragmentDynamicState storage state = _fragmentDynamicState[tokenId];

         // Calculate time elapsed since last decay
         uint256 timeElapsed = block.timestamp - state.lastDecayTimestamp;

         if (timeElapsed > 0) {
             // Calculate potential decay amount considering external influence
             uint256 potentialDecayAmount = timeElapsed * decayRatePerSecond * currentExternalInfluenceFactor / 1e18;

             // Calculate essence generated before decay (based on charge * time * rate)
             // Simplified: Assume average charge over the period for essence calculation.
             // A more precise model would integrate charge over time.
             uint256 essenceGenerated = state.charge * timeElapsed * essenceExtractionRate / 1e36; // Scale appropriately

             // Apply decay
             uint256 actualDecay = Math.min(potentialDecayAmount, state.charge);
             state.charge -= actualDecay;

             // Essence accrual might be complex. For simplicity, let's just calculate potential loss from decay
             // and perhaps track a separate "essence debt" or accrue to a pool.
             // Let's simplify: essence is *extracted* from charge based on a rate, not passively accrued.
             // So decay simply reduces the source of future essence.
             // The state.essence variable is unused in this simplified decay, only used in extractEssence calculation.

             state.lastDecayTimestamp = uint64(block.timestamp); // Update last decay timestamp

             emit FragmentDecayed(tokenId, actualDecay, state.charge, 0); // Essence loss info could be added
         }
     }


    /**
     * @dev Extracts "Essence" from a fragment. Burns charge and pays user (after fee).
     * Requires fragment owner or approved.
     * @param tokenId The ID of the fragment.
     */
    function extractEssence(uint256 tokenId) public payable {
        address owner = ownerOf(tokenId);
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()) && getApproved(tokenId) != _msgSender()) {
             revert EtherealNexus__NotFragmentOwnerOrApproved();
        }
        if (!_exists(tokenId)) revert EtherealNexus__InvalidTokenId();

        _applyDecay(tokenId); // Apply pending decay first

        FragmentDynamicState storage state = _fragmentDynamicState[tokenId];

        if (state.charge < minChargeValue) {
            revert EtherealNexus__InsufficientCharge();
        }

        // Calculate extractable essence based on current charge and rate
        // Simplified calculation: Essence = Charge * rate. More complex models possible.
        uint256 essenceAmount = state.charge * essenceExtractionRate / 1e18; // Scale factor

        // Calculate protocol fee
        uint256 protocolFee = essenceAmount * protocolFeeBasisPoints / 10000;
        uint256 ownerShare = essenceAmount - protocolFee;

        // Burn the charge used for extraction
        uint256 chargeBurned = state.charge; // Burn all charge for simplicity
        state.charge = 0;
        state.lastDecayTimestamp = uint64(block.timestamp); // Reset decay timer after extraction

        // Simulate paying out essence - here using native ETH for simplicity
        // In a real system, this might be a separate ERC20 token
        collectedProtocolFees += protocolFee;

        (bool success, ) = payable(owner).call{value: ownerShare}("");
        require(success, "Essence payout failed"); // Basic check

        emit EssenceExtracted(tokenId, _msgSender(), essenceAmount, protocolFee, state.charge);
    }

     /**
     * @dev Burns a fragment for a specific effect (e.g., temporary boost, contribution to system pool).
     * Requires fragment owner or approved.
     * @param tokenId The ID of the fragment to sacrifice.
     */
    function sacrificeFragment(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()) && getApproved(tokenId) != _msgSender()) {
             revert EtherealNexus__NotFragmentOwnerOrApproved();
        }
        if (!_exists(tokenId)) revert EtherealNexus__InvalidTokenId();

        // Implement specific sacrifice effect here
        // Example: Increase external influence factor temporarily, or add to a community pool
        // currentExternalInfluenceFactor += _fragmentAttributes[tokenId].level * 1e17; // Example effect

        _burn(tokenId); // Burn the token

        emit FragmentSacrificed(tokenId, owner);
    }


    // --- Fragment Interactions & Evolution ---

    /**
     * @dev Attempts to combine two fragments into one or none, based on configured rules.
     * Burns the input fragments. Requires owner/approved for both.
     * @param tokenId1 The ID of the first fragment.
     * @param tokenId2 The ID of the second fragment.
     */
    function combineFragments(uint256 tokenId1, uint256 tokenId2) public {
        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        // Ensure caller is authorized for both tokens
        bool auth1 = (_msgSender() == owner1 || isApprovedForAll(owner1, _msgSender()) || getApproved(tokenId1) == _msgSender());
        bool auth2 = (_msgSender() == owner2 || isApprovedForAll(owner2, _msgSender()) || getApproved(tokenId2) == _msgSender());
        if (!auth1 || !auth2) {
            revert EtherealNexus__NotFragmentOwnerOrApproved();
        }

        if (!_exists(tokenId1) || !_exists(tokenId2)) revert EtherealNexus__InvalidTokenId();
        if (tokenId1 == tokenId2) revert EtherealNexus__CannotCombine(); // Cannot combine with self

        FragmentAttributes memory attr1 = _fragmentAttributes[tokenId1];
        FragmentAttributes memory attr2 = _fragmentAttributes[tokenId2];

        // Determine rule key (ensure consistent order)
        uint256 typeA = Math.min(attr1.fragmentType, attr2.fragmentType);
        uint256 typeB = Math.max(attr1.fragmentType, attr2.fragmentType);
        uint256 ruleKey = (typeA << 128) | typeB;

        FragmentInteractionRule storage rule = _fragmentInteractionRules[ruleKey];

        if (!rule.enabled) {
            revert EtherealNexus__CannotCombine(); // No rule defined or enabled for these types
        }

        // Burn input tokens
        _burn(tokenId1);
        _burn(tokenId2);

        uint256 newTokenId = 0; // Default to no new token minted

        // If resultingAttributesPacked is not empty, mint a new token
        if (rule.resultingAttributesPacked.length > 0) {
            _tokenIdCounter.increment();
            newTokenId = _tokenIdCounter.current();
            address newOwner = owner1; // Or decide ownership based on rules

            _safeMint(newOwner, newTokenId);

            // Unpack attributes (simplified example)
            bytes memory packed = rule.resultingAttributesPacked;
            uint256 newType = uint256(packed[0]);
            uint256 newLevel = uint256(packed[1]);
            uint256 newPower = uint256(packed[2]);
            uint256 newResilience = uint256(packed[3]);

            _fragmentAttributes[newTokenId] = FragmentAttributes({
                fragmentType: newType,
                level: newLevel,
                power: newPower,
                resilience: newResilience
            });

             _fragmentDynamicState[newTokenId] = FragmentDynamicState({
                charge: 0, // Start with no charge
                lastDecayTimestamp: uint64(block.timestamp),
                essence: 0
            });
            _fragmentCreationTime[newTokenId] = block.timestamp;
        }

        emit FragmentsCombined(tokenId1, tokenId2, newTokenId);
    }

    /**
     * @dev Configures the rules for combining two specific fragment types.
     * Uses packed bytes for resulting attributes (simplified).
     * @param type1 The type of the first fragment.
     * @param type2 The type of the second fragment.
     * @param resultingAttributesPacked Packed bytes representing the attributes of the resulting fragment.
     */
    function configureFragmentInteractionRules(
        uint256 type1,
        uint256 type2,
        bytes memory resultingAttributesPacked
    ) external onlyOperatorOrOwner {
        // Ensure consistent order for the key
        uint256 typeA = Math.min(type1, type2);
        uint256 typeB = Math.max(type1, type2);
        uint256 ruleKey = (typeA << 128) | typeB;

        _fragmentInteractionRules[ruleKey] = FragmentInteractionRule({
            enabled: true, // Rule is enabled upon configuration
            resultingAttributesPacked: resultingAttributesPacked
        });

        emit InteractionRuleConfigured(typeA, typeB, true, resultingAttributesPacked);
    }

     /**
     * @dev Gets the combination rules for two fragment types.
     * @param type1 The type of the first fragment.
     * @param type2 The type of the second fragment.
     * @return The interaction rule struct.
     */
    function getFragmentInteractionRules(uint256 type1, uint256 type2) public view returns (FragmentInteractionRule memory) {
         // Ensure consistent order for the key
        uint256 typeA = Math.min(type1, type2);
        uint256 typeB = Math.max(type1, type2);
        uint256 ruleKey = (typeA << 128) | typeB;
        return _fragmentInteractionRules[ruleKey];
    }

     /**
     * @dev View function to preview the potential outcome (attributes) of combining two fragments.
     * Does not execute the combination.
     * @param tokenId1 The ID of the first fragment.
     * @param tokenId2 The ID of the second fragment.
     * @return FragmentAttributes of the potential result, or zeroed struct if no rule exists or enabled.
     */
    function getCombinedFragmentPreview(uint256 tokenId1, uint256 tokenId2) public view returns (FragmentAttributes memory) {
        if (!_exists(tokenId1) || !_exists(tokenId2) || tokenId1 == tokenId2) {
            return FragmentAttributes(0, 0, 0, 0); // Return zeroed struct for invalid input
        }

        FragmentAttributes memory attr1 = _fragmentAttributes[tokenId1];
        FragmentAttributes memory attr2 = _fragmentAttributes[tokenId2];

        uint256 typeA = Math.min(attr1.fragmentType, attr2.fragmentType);
        uint256 typeB = Math.max(attr1.fragmentType, attr2.fragmentType);
        uint256 ruleKey = (typeA << 128) | typeB;

        FragmentInteractionRule storage rule = _fragmentInteractionRules[ruleKey];

        if (!rule.enabled || rule.resultingAttributesPacked.length == 0) {
            return FragmentAttributes(0, 0, 0, 0); // No enabled rule or no resulting token
        }

        // Unpack attributes (simplified example)
        bytes memory packed = rule.resultingAttributesPacked;
        if (packed.length < 4) return FragmentAttributes(0, 0, 0, 0); // Not enough data

        return FragmentAttributes({
            fragmentType: uint256(packed[0]),
            level: uint256(packed[1]),
            power: uint256(packed[2]),
            resilience: uint256(packed[3])
        });
    }


    // --- System Management & Configuration ---

    /**
     * @dev Sets the rate at which Essence is generated per unit of Charge per second.
     * @param rate The new essence extraction rate (scaled).
     */
    function setEssenceExtractionRate(uint256 rate) external onlyOperatorOrOwner {
        essenceExtractionRate = rate;
        emit ParametersUpdated("essenceExtractionRate", rate);
    }

    /**
     * @dev Sets the minimum charge required for essence extraction.
     * @param minCharge The new minimum charge value (scaled).
     */
    function setMinChargeValue(uint256 minCharge) external onlyOperatorOrOwner {
        minChargeValue = minCharge;
        emit ParametersUpdated("minChargeValue", minCharge);
    }

    /**
     * @dev Sets the base decay rate for fragment charge per second.
     * @param decayPerSecond The new decay rate.
     */
    function setDecayRate(uint256 decayPerSecond) external onlyOperatorOrOwner {
        decayRatePerSecond = decayPerSecond;
        emit ParametersUpdated("decayRatePerSecond", decayPerSecond);
    }

    /**
     * @dev Grants the SystemOperator role to an address.
     * System Operators can perform certain management functions.
     * @param operator The address to grant the role to.
     */
    function addSystemOperator(address operator) external onlyOwner {
        require(operator != address(0), "Invalid address");
        _isSystemOperator[operator] = true;
        emit SystemOperatorAdded(operator);
    }

    /**
     * @dev Revokes the SystemOperator role from an address.
     * @param operator The address to revoke the role from.
     */
    function removeSystemOperator(address operator) external onlyOwner {
        require(operator != address(0), "Invalid address");
        _isSystemOperator[operator] = false;
        emit SystemOperatorRemoved(operator);
    }

    /**
     * @dev Checks if an address has the SystemOperator role.
     * @param account The address to check.
     * @return True if the address is a SystemOperator, false otherwise.
     */
    function hasSystemOperatorRole(address account) public view returns (bool) {
        return _isSystemOperator[account] || owner() == account;
    }

     /**
     * @dev Records a simulated external influence factor affecting fragment dynamics.
     * This could represent game events, environmental factors, etc.
     * @param influenceFactor The new influence factor (1e18 = 1x, 2e18 = 2x, 0.5e18 = 0.5x).
     */
    function recordExternalInfluence(uint256 influenceFactor) external onlySystemOperator {
        currentExternalInfluenceFactor = influenceFactor;
        emit ExternalInfluenceRecorded(influenceFactor);
    }

     /**
     * @dev Gets the current protocol fee rate in basis points.
     */
    function getProtocolFeeRate() public view returns (uint256) {
        return protocolFeeBasisPoints;
    }

    /**
     * @dev Sets the protocol fee percentage for Essence extraction (in basis points).
     * 100 basis points = 1%. Max 10000 bp (100%).
     * @param feeBasisPoints The new fee rate in basis points.
     */
    function setProtocolFeeRate(uint256 feeBasisPoints) external onlyOwner {
        if (feeBasisPoints > 10000) revert EtherealNexus__InvalidFeeRate();
        protocolFeeBasisPoints = feeBasisPoints;
        emit ParametersUpdated("protocolFeeBasisPoints", feeBasisPoints);
    }

     /**
     * @dev Allows the owner/operator to claim collected protocol fees (ETH).
     */
    function claimProtocolFees() external onlyOperatorOrOwner {
        uint256 amount = collectedProtocolFees;
        if (amount == 0) revert EtherealNexus__NoFeesToClaim();

        collectedProtocolFees = 0;

        (bool success, ) = payable(_msgSender()).call{value: amount}("");
        require(success, "Fee payout failed");

        emit ProtocolFeesClaimed(_msgSender(), amount);
    }


    // --- Advanced & Utility ---

    /**
     * @dev Helper view function for off-chain clients to construct the hash
     * that needs to be signed by the fragment owner for a delegated action.
     * @param tokenId The ID of the fragment the action is for.
     * @param actionHash A unique identifier hash for the specific action being delegated.
     *                   (e.g., keccak256("CHARGE_FRAGMENT"), keccak256("EXTRACT_ESSENCE"))
     * @param nonce A unique number (usually incremented by owner) to prevent replay attacks.
     * @param expiration Timestamp when the delegation expires.
     * @return The structured data hash to be signed.
     */
    function delegateFragmentActionSignature(
        uint256 tokenId,
        bytes32 actionHash,
        uint256 nonce,
        uint256 expiration
    ) public view returns (bytes32) {
        bytes32 typedDataHash = keccak256(
            abi.encode(
                keccak256("DelegatedFragmentAction(uint256 tokenId,bytes32 actionHash,uint256 nonce,uint256 expiration,address contractAddress)"),
                tokenId,
                actionHash,
                nonce,
                expiration,
                address(this)
            )
        );
        return typedDataHash.toEthSignedMessageHash();
    }

     /**
     * @dev Executes a specific action on a fragment on behalf of the owner,
     * validated by a signature from the owner (or approved address).
     * This enables meta-transactions or third-party interactions without owner
     * directly sending the transaction.
     * @param signer The address that signed the message (should be owner or approved).
     * @param tokenId The ID of the fragment.
     * @param actionHash The unique identifier hash for the action (must match signed hash).
     * @param nonce The nonce used by the signer.
     * @param expiration Timestamp when the delegation expires.
     * @param signature The ECDSA signature from the signer.
     */
    function executeDelegatedFragmentAction(
        address signer,
        uint256 tokenId,
        bytes32 actionHash,
        uint256 nonce,
        uint256 expiration,
        bytes memory signature
    ) external {
         if (!_exists(tokenId)) revert EtherealNexus__InvalidTokenId();

         // 1. Verify signer authorization (owner or approved)
        address owner = ownerOf(tokenId);
        if (signer != owner && !isApprovedForAll(owner, signer) && getApproved(tokenId) != signer) {
            revert EtherealNexus__NotFragmentOwnerOrApproved(); // Signer must be owner or approved
        }

        // 2. Verify signature expiration
        if (block.timestamp > expiration) {
            revert SignatureExpired();
        }

        // 3. Verify nonce (prevent replay)
        if (_delegationNonces[signer] > nonce) {
             revert NonceAlreadyUsed();
        }
        _delegationNonces[signer] = nonce + 1; // Increment nonce for this signer

        // 4. Recover signer from signature
        bytes32 signedHash = delegateFragmentActionSignature(tokenId, actionHash, nonce, expiration);
        address recoveredSigner = signedHash.recover(signature);

        if (recoveredSigner != signer) {
            revert EtherealNexus__InvalidSignature();
        }

        // 5. Execute the action based on actionHash
        // --- IMPORTANT ---
        // This section MUST ONLY execute predefined, safe actions.
        // Avoid using arbitrary `delegatecall` or low-level calls here.
        // Use a dispatcher or direct function calls based on the hash.

        bytes32 CHARGE_FRAGMENT_ACTION_HASH = keccak256("CHARGE_FRAGMENT");
        bytes32 EXTRACT_ESSENCE_ACTION_HASH = keccak256("EXTRACT_ESSENCE");
        bytes32 SACRIFICE_FRAGMENT_ACTION_HASH = keccak256("SACRIFICE_FRAGMENT");
        // Add more defined action hashes here

        if (actionHash == CHARGE_FRAGMENT_ACTION_HASH) {
            // Temporarily change msg.sender context to the signer for the call
            // NOTE: This requires careful consideration of function permissions.
            // A cleaner way is to pass the signer explicitly to the called function.
            // For demonstration, let's *assume* chargeFragment logic checks owner/approved.
            // The `_msgSender()` within chargeFragment will still be the transaction sender,
            // NOT the `signer`. The logic inside chargeFragment needs to check if the CALLER
            // (i.e., this contract via delegate execution) is authorized by the `signer`
            // for this specific action. This is tricky.
            // A better pattern: Define internal functions like `_chargeFragmentForDelegated(uint256 tokenId, address authSigner)`

            // Let's simulate by checking authorization *here* based on the recovered signer.
            // The actual function call will be made by the transaction sender.
            // The called function (e.g. chargeFragment) must NOT rely on msg.sender being the owner.
            // It should be re-written to accept an 'authorizedBy' parameter.
            // For simplicity in this example, we'll just call the function,
            // assuming a robust permission check was moved internally, which isn't shown here.
            // --- Reverting to a simpler, SAFER design ---
            // We will NOT call other functions directly.
            // Instead, the execution logic for the action is *replicated* or *dispatched* here.

            // --- Simplified Execution Dispatch ---
            if (actionHash == CHARGE_FRAGMENT_ACTION_HASH) {
                // Simulate charging logic here, authorized by 'signer'
                 if (!_exists(tokenId)) revert EtherealNexus__InvalidTokenId(); // Re-check existence

                _applyDecay(tokenId); // Apply decay before adding charge
                uint256 chargeToAdd = 1e18; // Example: Add 1 unit of charge
                _fragmentDynamicState[tokenId].charge += chargeToAdd;
                 emit FragmentCharged(tokenId, signer, chargeToAdd, _fragmentDynamicState[tokenId].charge); // Use signer as the effective user

            } else if (actionHash == EXTRACT_ESSENCE_ACTION_HASH) {
                // Simulate essence extraction logic here, authorized by 'signer'
                 if (!_exists(tokenId)) revert EtherealNexus__InvalidTokenId(); // Re-check existence

                _applyDecay(tokenId);
                FragmentDynamicState storage state = _fragmentDynamicState[tokenId];
                 if (state.charge < minChargeValue) {
                    revert EtherealNexus__InsufficientCharge();
                }
                uint256 essenceAmount = state.charge * essenceExtractionRate / 1e18;
                uint256 protocolFee = essenceAmount * protocolFeeBasisPoints / 10000;
                uint256 ownerShare = essenceAmount - protocolFee;

                uint256 chargeBurned = state.charge;
                state.charge = 0;
                state.lastDecayTimestamp = uint64(block.timestamp);

                collectedProtocolFees += protocolFee;
                // Send share to the actual owner of the token (could be different from signer)
                address actualOwner = ownerOf(tokenId);
                (bool success, ) = payable(actualOwner).call{value: ownerShare}("");
                require(success, "Delegated essence payout failed");

                emit EssenceExtracted(tokenId, signer, essenceAmount, protocolFee, state.charge); // Use signer as the effective user

            } else if (actionHash == SACRIFICE_FRAGMENT_ACTION_HASH) {
                 // Simulate sacrifice logic here, authorized by 'signer'
                 if (!_exists(tokenId)) revert EtherealNexus__InvalidTokenId(); // Re-check existence

                 // Apply sacrifice effect (example)
                 // currentExternalInfluenceFactor += _fragmentAttributes[tokenId].level * 1e17; // Example effect

                 _burn(tokenId); // Burn the token
                 emit FragmentSacrificed(tokenId, signer); // Use signer as the effective user

            } else {
                revert("Unknown delegated action"); // Action hash not recognized
            }
        }

        emit DelegationActionExecuted(signer, tokenId, actionHash, nonce);
    }

    /**
     * @dev View function to predict the dynamic state of a fragment after a given time delta.
     * Purely theoretical calculation, does not alter state.
     * @param tokenId The ID of the fragment.
     * @param timeDelta The time in seconds to simulate forward.
     * @return The predicted dynamic state.
     */
    function predictFragmentFutureState(uint256 tokenId, uint256 timeDelta) public view returns (FragmentDynamicState memory) {
        if (!_exists(tokenId)) revert EtherealNexus__InvalidTokenId();
        FragmentDynamicState memory state = _fragmentDynamicState[tokenId];

        // Calculate decay over timeDelta starting from current state
        uint256 timeElapsedSinceLastDecay = block.timestamp - state.lastDecayTimestamp;
        uint256 totalTimeForDecay = timeElapsedSinceLastDecay + timeDelta;

        uint256 potentialDecayAmount = totalTimeForDecay * decayRatePerSecond * currentExternalInfluenceFactor / 1e18;
        uint256 actualDecay = Math.min(potentialDecayAmount, state.charge);

        state.charge -= actualDecay;
        // Essence calculation is complex for prediction without state changes.
        // For simplicity, just return predicted charge.
        // A more complex prediction would need to model charge decay vs. essence generation.

        return state;
    }

    /**
     * @dev View function to simulate the amount of charge decay that would occur
     * over a specific time period, based on current state and parameters.
     * @param tokenId The ID of the fragment.
     * @param timeDelta The time in seconds to simulate decay for.
     * @return The amount of charge that would decay.
     */
    function simulateDecayForFragment(uint256 tokenId, uint256 timeDelta) public view returns (uint256) {
        if (!_exists(tokenId)) revert EtherealNexus__InvalidTokenId();
        FragmentDynamicState memory state = _fragmentDynamicState[tokenId];

        uint256 potentialDecayAmount = timeDelta * decayRatePerSecond * currentExternalInfluenceFactor / 1e18;
        uint256 actualDecay = Math.min(potentialDecayAmount, state.charge);

        return actualDecay;
    }


    /**
     * @dev Simulates generating a pseudo-random value for potential attribute assignment.
     * WARNING: This is NOT cryptographically secure and should not be used for
     * sensitive outcomes in production. Uses block variables.
     * @return A pseudo-random uint256 value.
     */
    function requestRandomAttributeValue() public view returns (uint256) {
        // Using blockhash, block.timestamp, etc. is predictable by miners/validators.
        // For real randomness, use Chainlink VRF or a similar solution.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _msgSender(), block.number, tx.origin)));
    }

    // --- Metadata / URI ---
    // The standard ERC721URIStorage function `tokenURI(uint256 tokenId)` is available.
    // We add a setter for the URI. In a dynamic system, the URI might point to an
    // API that serves metadata reflecting the *current* dynamic state.

    /**
     * @dev Sets the URI for a token's metadata. Requires owner or approved.
     * @param tokenId The ID of the token.
     * @param uri The URI for the token's metadata.
     */
    function setTokenMetadataURI(uint256 tokenId, string memory uri) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: approve caller is not owner nor approved");
        _setTokenURI(tokenId, uri);
    }
}
```