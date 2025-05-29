Okay, let's design a complex, creative, and advanced smart contract that isn't a standard AMM, lending protocol, or NFT marketplace.

How about a contract that facilitates conditional, multi-asset swaps linked by various "entanglement" conditions? Users can create offers to swap a set of assets for another set, but the offer only becomes fulfillable if a specified on-chain or oracle-verified condition is met (the "entanglement").

We'll call it `QuantumEntanglementSwap`.

**Core Concepts:**

1.  **Conditional Swaps:** Swaps don't happen immediately upon matching; they require an external or time-based condition to be met.
2.  **Multi-Asset Swaps:** Offers can involve multiple ERC20 tokens, ERC721 tokens, and native ETH on both the "offered" and "requested" sides.
3.  **Entanglement Conditions:** Swaps can be linked ("entangled") to different types of conditions:
    *   Time-based (e.g., unlock after a certain block or timestamp).
    *   Oracle-based (e.g., unlock if an asset price crosses a threshold).
    *   Linked Offer fulfillment (e.g., this swap unlocks only if another specific swap offer is fulfilled).
    *   Custom/Registered Conditions (allowing whitelisted external contracts to define and check arbitrary complex conditions).
4.  **Pull Pattern for Assets:** Assets involved in offers are held by the contract and must be explicitly claimed by the participants once the offer reaches a terminal state (fulfilled, cancelled, expired).
5.  **State Management:** Offers and Entanglements have distinct states that change based on user actions, time, or external signals.

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Imports for safe handling of ERC20, ERC721, ownership, and pausing.
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive ERC721
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // Useful for tracking collections

// --- Contract: QuantumEntanglementSwap ---
// A smart contract facilitating conditional, multi-asset swaps linked by various "entanglement" conditions.

// --- Core Data Structures ---
// Asset: Represents a specific quantity of an asset (ETH, ERC20, ERC721).
// SwapOffer: Defines a conditional exchange proposal (offered assets for requested assets).
// Entanglement: Defines the specific condition linked to a SwapOffer that must be met for fulfillment.

// --- States ---
// OfferState: Pending, Entangled, Fulfilled, Cancelled, Expired.
// EntanglementState: Pending, Met, Failed, Inactive.
// AssetType: Ether, ERC20, ERC721.
// EntanglementType: None, TimeLock, OracleCondition, OfferLink, CustomCondition.

// --- Key Mappings & State Variables ---
// offers: Mapping from offerId to SwapOffer struct.
// entanglements: Mapping from entanglementId to Entanglement struct.
// offerToEntanglement: Mapping from offerId to entanglementId (one-to-one).
// offerIdsByOfferer: Mapping from user address to list/set of offerIds created by them.
// claimableAssets: Mapping from user address to map of token address to amount (for ERC20/ETH).
// claimableNFTs: Mapping from user address to map of token address to set of tokenIds (for ERC721).
// approvedTokens: Set of ERC20 token addresses allowed for swaps.
// approvedNFTCollections: Set of ERC721 token addresses allowed for swaps.
// customConditionRegistry: Mapping from entanglementType (uint identifier for custom types) to address of the ICustomEntanglementCondition contract.
// oracleAddress: Address of the trusted oracle contract implementing IQuantumOracle.
// entanglementFee: Fee (in ETH) to create an entanglement.
// protocolFees: Total collected fees.

// --- Interfaces (Required for external interaction) ---
// IQuantumOracle: Interface for the oracle contract (e.g., `checkCondition(bytes calldata conditionData) returns (bool)`).
// ICustomEntanglementCondition: Interface for custom condition contracts (e.g., `checkCondition(uint256 offerId, bytes calldata conditionData) returns (bool)`).

// --- Events ---
// OfferCreated: Logged when a new swap offer is created.
// OfferCancelled: Logged when an offer is cancelled by the offerer.
// OfferFulfilled: Logged when an offer is successfully fulfilled.
// OfferExpired: Logged when an offer's validity period ends.
// EntanglementCreated: Logged when an entanglement condition is linked to an offer.
// EntanglementConditionMet: Logged when an entanglement condition is verified as met.
// AssetsClaimed: Logged when a user successfully claims assets.
// ProtocolFeeClaimed: Logged when protocol fees are withdrawn.
// CustomEntanglementTypeRegistered: Logged when a new custom type is registered.
// AssetApproved: Logged when an asset address is added to the approved list.

// --- Function Summary (20+ functions) ---

// *** Offer Creation & Management ***
// 1. createOffer: Creates a new swap offer, transfers offered assets to contract, sets state to Pending.
// 2. cancelOffer: Allows the offerer to cancel a Pending or Entangled offer, updates state, makes offered assets claimable.
// 3. getOffer: View function to retrieve details of a specific offer.
// 4. getUserOffers: View function to list offer IDs created by a user.
// 5. getAllOffers: View function (careful with gas) to get all offer IDs.
// 6. _expireOffer: Internal function to mark an offer as Expired if past expiryBlock, makes offered assets claimable.

// *** Entanglement Creation & Management ***
// 7. createOfferLinkEntanglement: Links an offer to the fulfillment of another offer. State becomes Entangled.
// 8. createOracleConditionEntanglement: Links an offer to an oracle condition. State becomes Entangled. Requires entanglementFee.
// 9. createTimeLockEntanglement: Links an offer to a future block number or timestamp. State becomes Entangled.
// 10. registerCustomEntanglementType: Owner registers a new type of custom entanglement condition by providing an identifier and contract address.
// 11. unregisterCustomEntanglementType: Owner removes a custom entanglement type registration.
// 12. createCustomEntanglement: Links an offer to a registered custom condition. State becomes Entangled. Requires entanglementFee.
// 13. getEntanglement: View function to retrieve details of an entanglement.
// 14. getOfferEntanglement: View function to retrieve the entanglement linked to a specific offer.

// *** Fulfillment & Condition Resolution ***
// 15. attemptFulfillment: Allows a user to attempt to fulfill an offer. Checks offer state, expiry, and entanglement condition. If all checks pass, transfers requested assets from fulfiller to contract, transfers offered assets from contract to fulfiller, updates state to Fulfilled, makes requested assets claimable by offerer.
// 16. checkAndMarkEntanglementMet: Public function (callable by anyone, perhaps incentivized or triggered by relayer/oracle) to explicitly check an entanglement condition and update its state if met.

// *** Asset Claiming ***
// 17. claimAssets: Allows a user to claim any ETH, ERC20, or ERC721 assets currently claimable by them from completed, cancelled, or expired offers.
// 18. getClaimableERC20: View function to see claimable ERC20 balance for a user and token.
// 19. getClaimableERC721: View function to see claimable ERC721 IDs for a user and collection.
// 20. getClaimableETH: View function to see claimable ETH balance for a user.

// *** Protocol Configuration & Administration (Owner/Admin) ***
// 21. addApprovedToken: Owner adds an ERC20 address to the approved list.
// 22. removeApprovedToken: Owner removes an ERC20 address from the approved list.
// 23. addApprovedNFTCollection: Owner adds an ERC721 address to the approved list.
// 24. removeApprovedNFTCollection: Owner removes an ERC721 address from the approved list.
// 25. setOracleAddress: Owner sets the address of the trusted Oracle contract.
// 26. setEntanglementFee: Owner sets the fee for creating certain entanglement types.
// 27. withdrawFees: Owner withdraws accumulated protocol fees (in ETH).
// 28. pause: Owner pauses the contract (prevents most interactions).
// 29. unpause: Owner unpauses the contract.
// 30. transferOwnership: Owner transfers ownership.
// 31. renounceOwnership: Owner renounces ownership.

// *** Helper/View Functions ***
// 32. isApprovedToken: View function check if an ERC20 is approved.
// 33. isApprovedNFTCollection: View function check if an ERC721 is approved.
// 34. getCustomEntanglementContract: View function to get the contract address for a custom entanglement type.
// 35. getTotalOffers: View function for the total number of offers created.
// 36. getTotalEntanglements: View function for the total number of entanglements created.

// Note: The number of functions exceeds 20. This design incorporates concepts like state machines, external contract interaction (oracles, custom conditions), asset management (multiple types, pull pattern), fee collection, access control, and pausing. It avoids directly replicating standard AMM/lending pool logic. The "Entanglement" concept is a creative abstraction for complex conditional logic.
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // For receiving NFTs
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // Inherit to handle receiving NFTs
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract QuantumEntanglementSwap is Ownable, Pausable, ERC721Holder {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    // --- Data Structures ---

    enum AssetType {
        Ether,
        ERC20,
        ERC721
    }

    struct Asset {
        AssetType assetType;
        address tokenAddress; // Relevant for ERC20/ERC721
        uint256 tokenId;      // Relevant for ERC721 (0 for ERC20/Ether)
        uint256 amount;       // Relevant for ERC20/Ether (1 for ERC721 quantity)
    }

    enum OfferState {
        Pending,    // Offer created, waiting for entanglement or fulfillment attempt
        Entangled,  // Offer linked to an entanglement condition
        Fulfilled,  // Offer successfully matched and assets swapped
        Cancelled,  // Offer cancelled by offerer
        Expired     // Offer passed its expiry block without fulfillment
    }

    struct SwapOffer {
        uint256 offerId;
        address payable offerer; // Use payable as they might receive ETH
        Asset[] assetsOffered;
        Asset[] assetsRequested;
        uint256 expiryBlock; // Block number after which the offer expires
        OfferState state;
    }

    enum EntanglementType {
        None,              // No entanglement
        TimeLock,          // Condition is based on block timestamp or number
        OracleCondition,   // Condition is based on external data from an oracle
        OfferLink,         // Condition is based on the fulfillment of another offer
        CustomCondition    // Condition checked by a registered external contract
    }

    enum EntanglementState {
        Pending, // Condition not yet met
        Met,     // Condition has been met
        Failed,  // Condition can no longer be met (e.g., linked offer cancelled)
        Inactive // Entanglement no longer relevant (e.g., linked offer expired)
    }

    struct Entanglement {
        uint256 entanglementId;
        uint256 offerId;
        EntanglementType entanglementType;
        bytes conditionData; // Data specific to the entanglement type
        EntanglementState state;
    }

    // --- State Variables ---

    uint256 private _offerIdCounter = 0;
    uint256 private _entanglementIdCounter = 0;
    uint256 private _customEntanglementTypeCounter = 100; // Start custom types from a higher ID

    mapping(uint256 => SwapOffer) public offers;
    mapping(uint256 => Entanglement) public entanglements;
    mapping(uint256 => uint256) private offerToEntanglement; // offerId -> entanglementId

    mapping(address => uint256[]) private offerIdsByOfferer; // offerer -> list of offerIds

    // Assets claimable by users (pull pattern)
    mapping(address => mapping(address => uint256)) private claimableERC20; // user -> tokenAddress -> amount
    mapping(address => mapping(address => EnumerableSet.UintSet)) private claimableERC721Ids; // user -> tokenAddress -> set of tokenIds
    mapping(address => uint256) private claimableETH; // user -> amount

    EnumerableSet.AddressSet private approvedTokens;
    EnumerableSet.AddressSet private approvedNFTCollections;

    address public oracleAddress; // Address of the trusted IQuantumOracle contract
    mapping(uint256 => address) private customConditionRegistry; // customType -> contract address
    mapping(address => uint256) private customConditionAddressToType; // contract address -> customType

    uint256 public entanglementFee = 0; // Fee in wei for creating some entanglement types
    uint256 public protocolFees = 0; // Accumulated fees in wei

    // --- Interfaces ---

    interface IQuantumOracle {
        // Example function signature - actual implementation depends on oracle provider
        // This might check a price feed, a random number, etc.
        function checkCondition(bytes calldata conditionData) external view returns (bool);
        // Add other necessary oracle functions here based on integration needs
    }

    interface ICustomEntanglementCondition {
        // Contract must implement a function to check the specific condition
        function checkCondition(uint256 offerId, bytes calldata conditionData) external view returns (bool);
    }

    // --- Events ---

    event OfferCreated(uint256 offerId, address offerer, Asset[] assetsOffered, Asset[] assetsRequested, uint256 expiryBlock, OfferState initialState);
    event OfferCancelled(uint256 offerId, address offerer);
    event OfferFulfilled(uint256 offerId, address fulfiller);
    event OfferExpired(uint256 offerId);
    event EntanglementCreated(uint256 entanglementId, uint256 offerId, EntanglementType entanglementType, bytes conditionData);
    event EntanglementConditionMet(uint256 entanglementId);
    event EntanglementConditionFailed(uint256 entanglementId); // Condition can no longer be met
    event AssetsClaimed(address user, address tokenAddress, uint256 amountOrId, AssetType assetType);
    event ProtocolFeeClaimed(address owner, uint256 amount);
    event CustomEntanglementTypeRegistered(uint256 customType, address contractAddress);
    event CustomEntanglementTypeUnregistered(uint256 customType, address contractAddress);
    event AssetApproved(address assetAddress, AssetType assetType, bool approved);
    event OracleAddressUpdated(address oldAddress, address newAddress);
    event EntanglementFeeUpdated(uint256 oldFee, uint256 newFee);

    // --- Modifiers ---

    modifier offerExists(uint256 _offerId) {
        require(_offerId > 0 && _offerId <= _offerIdCounter, "Invalid offer ID");
        _;
    }

    modifier offerIsInState(uint256 _offerId, OfferState _state) {
        require(offers[_offerId].state == _state, "Offer not in required state");
        _;
    }

    modifier offerIsNotInState(uint256 _offerId, OfferState _state) {
        require(offers[_offerId].state != _state, "Offer in forbidden state");
        _;
    }

    modifier onlyApprovedToken(address _tokenAddress) {
        require(approvedTokens.contains(_tokenAddress), "Token not approved");
        _;
    }

    modifier onlyApprovedNFTCollection(address _tokenAddress) {
        require(approvedNFTCollections.contains(_tokenAddress), "NFT collection not approved");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle can call this function");
        _;
    }

    modifier onlyCustomEntanglementContract(uint256 _entanglementId) {
        Entanglement storage entanglement = entanglements[_entanglementId];
        require(entanglement.entanglementType == EntanglementType.CustomCondition, "Not a custom condition entanglement");
        require(msg.sender == customConditionRegistry[uint256(entanglement.conditionData)], "Not the registered custom contract for this type");
        _;
    }


    // --- Constructor ---

    constructor(address _oracleAddress) Ownable(msg.sender) Pausable() {
        oracleAddress = _oracleAddress;
        // Reserve type 0 for None
        _offerIdCounter = 0;
        _entanglementIdCounter = 0;
    }

    // --- Receive ETH ---
    receive() external payable {} // Allow receiving ETH for swaps and fees

    // --- Internal Asset Handling Helpers ---

    /// @dev Transfers assets from the caller to the contract. Requires prior approval for tokens.
    function _transferAssetIn(Asset calldata _asset, address _from) internal {
        if (_asset.amount == 0 && _asset.assetType != AssetType.ERC721) {
             revert("Asset amount cannot be zero");
        }
         if (_asset.assetType == AssetType.Ether) {
             require(_asset.tokenAddress == address(0), "Ether asset must have zero address");
             require(msg.value >= _asset.amount, "Insufficient ETH sent");
             // No explicit transfer needed here, as the ETH is received by the payable function
             // if used in a payable context, or needs Address.sendValue if called internally
             // We assume ETH for offers is sent alongside the createOffer call.
             // ETH for fulfillment is sent alongside attemptFulfillment.
         } else if (_asset.assetType == AssetType.ERC20) {
             require(_asset.tokenAddress != address(0), "ERC20 asset must have token address");
             require(approvedTokens.contains(_asset.tokenAddress), "ERC20 token not approved");
             IERC20(_asset.tokenAddress).safeTransferFrom(_from, address(this), _asset.amount);
         } else if (_asset.assetType == AssetType.ERC721) {
             require(_asset.tokenAddress != address(0), "ERC721 asset must have token address");
             require(approvedNFTCollections.contains(_asset.tokenAddress), "ERC721 collection not approved");
             require(_asset.amount == 1, "ERC721 asset amount must be 1");
             IERC721(_asset.tokenAddress).safeTransferFrom(_from, address(this), _asset.tokenId);
         } else {
             revert("Unknown asset type");
         }
    }

    /// @dev Transfers assets from the contract to a recipient.
    function _transferAssetOut(Asset memory _asset, address payable _to) internal {
         if (_asset.amount == 0 && _asset.assetType != AssetType.ERC721) {
             revert("Asset amount cannot be zero");
        }
        if (_asset.assetType == AssetType.Ether) {
            require(_asset.tokenAddress == address(0), "Ether asset must have zero address");
            // Check contract balance sufficient before sending
            require(address(this).balance >= _asset.amount, "Insufficient contract ETH balance");
            _to.sendValue(_asset.amount); // Use sendValue for safer ETH transfer
        } else if (_asset.assetType == AssetType.ERC20) {
            require(_asset.tokenAddress != address(0), "ERC20 asset must have token address");
             // No approved check needed here, assumed checked on deposit
            IERC20(_asset.tokenAddress).safeTransfer(_to, _asset.amount);
        } else if (_asset.assetType == Asset721) {
            require(_asset.tokenAddress != address(0), "ERC721 asset must have token address");
            require(_asset.amount == 1, "ERC721 asset amount must be 1");
             // No approved check needed here, assumed checked on deposit
            IERC721(_asset.tokenAddress).safeTransferFrom(address(this), _to, _asset.tokenId);
        } else {
            revert("Unknown asset type");
        }
    }

    /// @dev Adds assets to a user's claimable balance.
    function _addClaimableAsset(address _user, Asset memory _asset) internal {
        if (_user == address(0)) return;
        if (_asset.amount == 0 && _asset.assetType != AssetType.ERC721) {
             return; // Don't add zero amount assets
        }
        if (_asset.assetType == AssetType.Ether) {
            claimableETH[_user] += _asset.amount;
        } else if (_asset.assetType == AssetType.ERC20) {
            claimableERC20[_user][_asset.tokenAddress] += _asset.amount;
        } else if (_asset.assetType == AssetType.ERC721) {
            claimableERC721Ids[_user][_asset.tokenAddress].add(_asset.tokenId);
        }
    }

     /// @dev Removes assets from a user's claimable balance.
    function _removeClaimableAsset(address _user, Asset memory _asset) internal {
         if (_user == address(0)) return;
         if (_asset.amount == 0 && _asset.assetType != AssetType.ERC721) {
             return; // Don't remove zero amount assets
         }
        if (_asset.assetType == AssetType.Ether) {
            // This assumes the user is claiming the full amount available, adjust if partial claims are needed
            claimableETH[_user] = 0;
        } else if (_asset.assetType == AssetType.ERC20) {
             // This assumes the user is claiming the full amount available, adjust if partial claims are needed
            claimableERC20[_user][_asset.tokenAddress] = 0;
        } else if (_asset.assetType == AssetType.ERC721) {
             // This assumes the user is claiming the specific token ID
            claimableERC721Ids[_user][_asset.tokenAddress].remove(_asset.tokenId);
        }
    }


    // --- Offer Creation & Management ---

    /// @summary Creates a new swap offer.
    /// @param _assetsOffered Array of assets the offerer is putting up.
    /// @param _assetsRequested Array of assets the offerer wants in return.
    /// @param _expiryBlock Block number after which the offer can be considered expired.
    /// @param _entanglementType Type of entanglement for this offer. Use None for no entanglement.
    /// @param _conditionData Data specific to the chosen entanglement type (e.g., block number, oracle query ID, linked offer ID, custom data).
    /// @dev The caller must have approved the contract to spend ERC20/ERC721 tokens or send native ETH in the call value.
    function createOffer(
        Asset[] calldata _assetsOffered,
        Asset[] calldata _assetsRequested,
        uint256 _expiryBlock,
        EntanglementType _entanglementType,
        bytes calldata _conditionData
    ) external payable whenNotPaused returns (uint256 offerId) {
        require(_assetsOffered.length > 0, "Must offer at least one asset");
        require(_assetsRequested.length > 0, "Must request at least one asset");
        require(_expiryBlock > block.number, "Expiry block must be in the future");

        offerId = ++_offerIdCounter;
        uint256 entanglementId = 0;
        OfferState initialState = OfferState.Pending;

        // Handle entanglement creation if type is not None
        if (_entanglementType != EntanglementType.None) {
            entanglementId = ++_entanglementIdCounter;
            initialState = OfferState.Entangled;

            EntanglementState entanglementInitialState = EntanglementState.Pending;

            if (_entanglementType == EntanglementType.OfferLink) {
                uint256 linkedOfferId = abi.decode(_conditionData, (uint256));
                require(linkedOfferId > 0 && linkedOfferId <= _offerIdCounter, "Invalid linked offer ID");
                require(offers[linkedOfferId].state != OfferState.Fulfilled, "Linked offer already fulfilled");
                 // Consider other terminal states that would make the entanglement fail
                if (offers[linkedOfferId].state == OfferState.Cancelled || offers[linkedOfferId].state == OfferState.Expired) {
                    entanglementInitialState = EntanglementState.Failed;
                }

            } else if (_entanglementType == EntanglementType.OracleCondition) {
                require(oracleAddress != address(0), "Oracle address not set");
                require(msg.value >= entanglementFee, "Insufficient fee for Oracle entanglement");
                 protocolFees += entanglementFee; // Collect fee
            } else if (_entanglementType == EntanglementType.CustomCondition) {
                 uint256 customType;
                 (customType) = abi.decode(_conditionData, (uint256));
                 require(customConditionRegistry[customType] != address(0), "Custom condition type not registered");
                 require(msg.value >= entanglementFee, "Insufficient fee for Custom entanglement");
                 protocolFees += entanglementFee; // Collect fee
            } else if (_entanglementType == EntanglementType.TimeLock) {
                 // No extra checks on conditionData format here, checked during evaluation
            } else {
                 revert("Unsupported entanglement type");
            }

            entanglements[entanglementId] = Entanglement({
                entanglementId: entanglementId,
                offerId: offerId,
                entanglementType: _entanglementType,
                conditionData: _conditionData,
                state: entanglementInitialState
            });
            offerToEntanglement[offerId] = entanglementId;
        } else {
             // If no entanglement, ensure no conditionData is provided
             require(_conditionData.length == 0, "Condition data provided for None entanglement type");
        }


        offers[offerId] = SwapOffer({
            offerId: offerId,
            offerer: payable(msg.sender),
            assetsOffered: _assetsOffered,
            assetsRequested: _assetsRequested,
            expiryBlock: _expiryBlock,
            state: initialState
        });

        // Transfer offered assets to the contract
        uint256 ethSent = msg.value;
        uint256 ethUsedForFee = (_entanglementType == EntanglementType.OracleCondition || _entanglementType == EntanglementType.CustomCondition) ? entanglementFee : 0;
        uint256 ethForOffer = ethSent - ethUsedForFee;

        uint256 ethAssetAmount = 0;
        for (uint i = 0; i < _assetsOffered.length; i++) {
            if (_assetsOffered[i].assetType == AssetType.Ether) {
                ethAssetAmount += _assetsOffered[i].amount;
            }
            _transferAssetIn(_assetsOffered[i], msg.sender);
        }
        require(ethForOffer == ethAssetAmount, "Mismatch between sent ETH and Ether asset amount");


        offerIdsByOfferer[msg.sender].push(offerId); // Simple array, could be optimized with EnumerableSet for scalability

        emit OfferCreated(offerId, msg.sender, _assetsOffered, _assetsRequested, _expiryBlock, initialState);
    }

    /// @summary Allows the offerer to cancel a pending or entangled offer.
    /// @param _offerId The ID of the offer to cancel.
    function cancelOffer(uint256 _offerId) external whenNotPaused offerExists(_offerId) {
        SwapOffer storage offer = offers[_offerId];
        require(offer.offerer == msg.sender, "Only offerer can cancel");
        require(offer.state == OfferState.Pending || offer.state == OfferState.Entangled, "Offer not in cancelable state");

        _updateOfferState(_offerId, OfferState.Cancelled);

        // Make offered assets claimable by the offerer
        for (uint i = 0; i < offer.assetsOffered.length; i++) {
             _addClaimableAsset(offer.offerer, offer.assetsOffered[i]);
        }

        emit OfferCancelled(_offerId, msg.sender);
    }

    /// @summary Internal function to handle offer expiry.
    function _expireOffer(uint256 _offerId) internal offerExists(_offerId) {
         SwapOffer storage offer = offers[_offerId];
         if (offer.state != OfferState.Pending && offer.state != OfferState.Entangled) {
             return; // Only expire offers that are Pending or Entangled
         }
         if (block.number <= offer.expiryBlock) {
             return; // Not expired yet
         }

        _updateOfferState(_offerId, OfferState.Expired);

        // Make offered assets claimable by the offerer
        for (uint i = 0; i < offer.assetsOffered.length; i++) {
             _addClaimableAsset(offer.offerer, offer.assetsOffered[i]);
        }

        emit OfferExpired(_offerId);
    }


    /// @summary Gets the details of a swap offer.
    /// @param _offerId The ID of the offer.
    /// @return SwapOffer struct containing offer details.
    function getOffer(uint256 _offerId) external view offerExists(_offerId) returns (SwapOffer memory) {
        return offers[_offerId];
    }

     /// @summary Gets the list of offer IDs created by a specific user.
     /// @param _user The address of the user.
     /// @return Array of offer IDs.
    function getUserOffers(address _user) external view returns (uint256[] memory) {
        return offerIdsByOfferer[_user];
    }

    /// @summary Gets all active offer IDs. (Gas intensive for large number of offers)
    /// @dev This function is potentially gas-intensive and should be used with caution off-chain.
    /// @return Array of all offer IDs created.
    function getAllOffers() external view returns (uint256[] memory) {
        uint256[] memory allIds = new uint256[](_offerIdCounter);
        for(uint i = 1; i <= _offerIdCounter; i++) {
            allIds[i-1] = i;
        }
        return allIds;
    }


    // --- Entanglement Creation & Management ---

     /// @summary Creates a TimeLock entanglement for an offer.
     /// @param _offerId The ID of the offer to entangle.
     /// @param _unlockBlockOrTimestamp The future block number or timestamp when the condition is met.
    function createTimeLockEntanglement(uint256 _offerId, uint256 _unlockBlockOrTimestamp)
         external whenNotPaused offerExists(_offerId) offerIsInState(_offerId, OfferState.Pending) {
        SwapOffer storage offer = offers[_offerId];
        require(offer.offerer == msg.sender, "Only offerer can entangle their offer");
        require(offerToEntanglement[_offerId] == 0, "Offer already entangled");
        require(_unlockBlockOrTimestamp > block.number, "Unlock must be in the future"); // Simple check, could be timestamp based

        uint256 entanglementId = ++_entanglementIdCounter;
        entanglements[entanglementId] = Entanglement({
            entanglementId: entanglementId,
            offerId: _offerId,
            entanglementType: EntanglementType.TimeLock,
            conditionData: abi.encode(_unlockBlockOrTimestamp),
            state: EntanglementState.Pending
        });
        offerToEntanglement[_offerId] = entanglementId;
        _updateOfferState(_offerId, OfferState.Entangled);

        emit EntanglementCreated(entanglementId, _offerId, EntanglementType.TimeLock, abi.encode(_unlockBlockOrTimestamp));
    }

     /// @summary Creates an OracleCondition entanglement for an offer.
     /// @param _offerId The ID of the offer to entangle.
     /// @param _conditionData Data required by the oracle to check the condition.
     /// @dev Requires sending the `entanglementFee` with the transaction.
    function createOracleConditionEntanglement(uint256 _offerId, bytes calldata _conditionData)
         external payable whenNotPaused offerExists(_offerId) offerIsInState(_offerId, OfferState.Pending) {
        SwapOffer storage offer = offers[_offerId];
        require(offer.offerer == msg.sender, "Only offerer can entangle their offer");
        require(offerToEntanglement[_offerId] == 0, "Offer already entangled");
        require(oracleAddress != address(0), "Oracle address not set");
        require(msg.value >= entanglementFee, "Insufficient fee for Oracle entanglement");

        protocolFees += entanglementFee; // Collect fee

        uint256 entanglementId = ++_entanglementIdCounter;
        entanglements[entanglementId] = Entanglement({
            entanglementId: entanglementId,
            offerId: _offerId,
            entanglementType: EntanglementType.OracleCondition,
            conditionData: _conditionData,
            state: EntanglementState.Pending
        });
        offerToEntanglement[_offerId] = entanglementId;
        _updateOfferState(_offerId, OfferState.Entangled);

        emit EntanglementCreated(entanglementId, _offerId, EntanglementType.OracleCondition, _conditionData);
    }

     /// @summary Creates an OfferLink entanglement for an offer.
     /// @param _offerId The ID of the offer to entangle.
     /// @param _linkedOfferId The ID of the offer whose fulfillment triggers this entanglement.
    function createOfferLinkEntanglement(uint256 _offerId, uint256 _linkedOfferId)
         external whenNotPaused offerExists(_offerId) offerIsInState(_offerId, OfferState.Pending) offerExists(_linkedOfferId) offerIsNotInState(_linkedOfferId, OfferState.Fulfilled) {
        SwapOffer storage offer = offers[_offerId];
        require(offer.offerer == msg.sender, "Only offerer can entangle their offer");
        require(offerToEntanglement[_offerId] == 0, "Offer already entangled");
        require(_offerId != _linkedOfferId, "Cannot link an offer to itself");

        uint256 entanglementId = ++_entanglementIdCounter;
         EntanglementState initialState = (offers[_linkedOfferId].state == OfferState.Cancelled || offers[_linkedOfferId].state == OfferState.Expired) ? EntanglementState.Failed : EntanglementState.Pending;

        entanglements[entanglementId] = Entanglement({
            entanglementId: entanglementId,
            offerId: _offerId,
            entanglementType: EntanglementType.OfferLink,
            conditionData: abi.encode(_linkedOfferId),
            state: initialState
        });
        offerToEntanglement[_offerId] = entanglementId;
        _updateOfferState(_offerId, OfferState.Entangled);

        emit EntanglementCreated(entanglementId, _offerId, EntanglementType.OfferLink, abi.encode(_linkedOfferId));
    }


     /// @summary Owner registers a new type of custom entanglement condition.
     /// @param _customTypeIdentifier A unique identifier for this custom type. Should be > 99.
     /// @param _contractAddress The address of the contract implementing ICustomEntanglementCondition.
    function registerCustomEntanglementType(uint256 _customTypeIdentifier, address _contractAddress) external onlyOwner whenNotPaused {
        require(_customTypeIdentifier >= _customEntanglementTypeCounter, "Custom type identifier too low");
        require(_contractAddress.isContract(), "Address must be a contract");
        require(customConditionRegistry[_customTypeIdentifier] == address(0), "Custom type identifier already registered");
        require(customConditionAddressToType[_contractAddress] == 0, "Contract address already registered for a custom type");

        customConditionRegistry[_customTypeIdentifier] = _contractAddress;
        customConditionAddressToType[_contractAddress] = _customTypeIdentifier;
        _customEntanglementTypeCounter = _customTypeIdentifier + 1; // Ensure next type is higher

        emit CustomEntanglementTypeRegistered(_customTypeIdentifier, _contractAddress);
    }

     /// @summary Owner unregisters a custom entanglement type.
     /// @param _customTypeIdentifier The identifier of the custom type to unregister.
    function unregisterCustomEntanglementType(uint256 _customTypeIdentifier) external onlyOwner whenNotPaused {
         require(customConditionRegistry[_customTypeIdentifier] != address(0), "Custom type identifier not registered");
         address contractAddress = customConditionRegistry[_customTypeIdentifier];

         delete customConditionRegistry[_customTypeIdentifier];
         delete customConditionAddressToType[contractAddress];

         // Note: Existing offers entangled with this type cannot be checked anymore unless a new contract is registered for the same type.
         // This is a design choice; more robust handling might require failing existing entanglements.

         emit CustomEntanglementTypeUnregistered(_customTypeIdentifier, contractAddress);
    }


     /// @summary Creates a CustomCondition entanglement for an offer.
     /// @param _offerId The ID of the offer to entangle.
     /// @param _customTypeIdentifier The identifier of the registered custom condition type.
     /// @param _conditionData Data specific to the custom condition contract.
     /// @dev Requires sending the `entanglementFee` with the transaction.
    function createCustomEntanglement(uint256 _offerId, uint256 _customTypeIdentifier, bytes calldata _conditionData)
         external payable whenNotPaused offerExists(_offerId) offerIsInState(_offerId, OfferState.Pending) {
        SwapOffer storage offer = offers[_offerId];
        require(offer.offerer == msg.sender, "Only offerer can entangle their offer");
        require(offerToEntanglement[_offerId] == 0, "Offer already entangled");
        require(customConditionRegistry[_customTypeIdentifier] != address(0), "Custom condition type not registered");
         require(msg.value >= entanglementFee, "Insufficient fee for Custom entanglement");

        protocolFees += entanglementFee; // Collect fee

        uint256 entanglementId = ++_entanglementIdCounter;
        entanglements[entanglementId] = Entanglement({
            entanglementId: entanglementId,
            offerId: _offerId,
            entanglementType: EntanglementType.CustomCondition,
            conditionData: abi.encode(_customTypeIdentifier, _conditionData), // Store type and data together
            state: EntanglementState.Pending
        });
        offerToEntanglement[_offerId] = entanglementId;
        _updateOfferState(_offerId, OfferState.Entangled);

        emit EntanglementCreated(entanglementId, _offerId, EntanglementType.CustomCondition, abi.encode(_customTypeIdentifier, _conditionData));
    }

     /// @summary Gets the details of an entanglement.
     /// @param _entanglementId The ID of the entanglement.
     /// @return Entanglement struct containing entanglement details.
    function getEntanglement(uint256 _entanglementId) external view returns (Entanglement memory) {
        require(_entanglementId > 0 && _entanglementId <= _entanglementIdCounter, "Invalid entanglement ID");
        return entanglements[_entanglementId];
    }

     /// @summary Gets the entanglement linked to a specific offer.
     /// @param _offerId The ID of the offer.
     /// @return Entanglement struct containing entanglement details, or zeroed struct if none.
    function getOfferEntanglement(uint256 _offerId) external view offerExists(_offerId) returns (Entanglement memory) {
         uint256 entanglementId = offerToEntanglement[_offerId];
         if (entanglementId == 0) {
             return Entanglement(0, 0, EntanglementType.None, "", EntanglementState.Inactive);
         }
        return entanglements[entanglementId];
    }


    // --- Fulfillment & Condition Resolution ---

     /// @summary Attempts to fulfill a swap offer.
     /// @param _offerId The ID of the offer to fulfill.
     /// @dev Requires sending the requested ETH amount (if any) and having approved ERC20/ERC721 transfers for requested assets.
    function attemptFulfillment(uint256 _offerId) external payable whenNotPaused offerExists(_offerId) {
        SwapOffer storage offer = offers[_offerId];

        // 1. Check Offer State
        require(offer.state == OfferState.Pending || offer.state == OfferState.Entangled, "Offer not fulfillable");
        _expireOffer(_offerId); // Check for expiry before proceeding
         require(offer.state == OfferState.Pending || offer.state == OfferState.Entangled, "Offer expired");

        // 2. Check Entanglement Condition (if applicable)
        if (offer.state == OfferState.Entangled) {
             uint256 entanglementId = offerToEntanglement[_offerId];
             Entanglement storage entanglement = entanglements[entanglementId];

             if (entanglement.state == EntanglementState.Pending) {
                bool conditionMet = _checkEntanglementCondition(entanglementId, entanglement.entanglementType, entanglement.conditionData);
                require(conditionMet, "Entanglement condition not met");
                _markEntanglementMet(entanglementId); // Mark as met for future checks
             } else if (entanglement.state == EntanglementState.Failed || entanglement.state == EntanglementState.Inactive) {
                 revert("Entanglement condition failed or is inactive");
             }
             // If state is already Met, proceed
        }

        // 3. Transfer Requested Assets from Fulfiller to Contract
        uint256 ethSent = msg.value;
        uint256 ethAssetAmount = 0;
         for (uint i = 0; i < offer.assetsRequested.length; i++) {
             if (offer.assetsRequested[i].assetType == AssetType.Ether) {
                 ethAssetAmount += offer.assetsRequested[i].amount;
             }
             _transferAssetIn(offer.assetsRequested[i], msg.sender);
         }
         require(ethSent == ethAssetAmount, "Mismatch between sent ETH and requested Ether asset amount");


        // 4. Transfer Offered Assets from Contract to Fulfiller
        address payable fulfiller = payable(msg.sender);
        for (uint i = 0; i < offer.assetsOffered.length; i++) {
             _transferAssetOut(offer.assetsOffered[i], fulfiller);
        }

        // 5. Make Requested Assets Claimable by Offerer (Pull Pattern)
         for (uint i = 0; i < offer.assetsRequested.length; i++) {
             _addClaimableAsset(offer.offerer, offer.assetsRequested[i]);
        }

        // 6. Update Offer State
        _updateOfferState(_offerId, OfferState.Fulfilled);

        emit OfferFulfilled(_offerId, msg.sender);

        // Handle potential OfferLink entanglements dependent on this offer
        // This requires searching all entanglements, which is inefficient.
        // A mapping linkedOfferId -> list of entanglementIds would be better.
        // For simplicity in this example, we omit this potentially gas-heavy step.
        // A more scalable design would use events and off-chain indexing or a dedicated resolver contract.
    }

     /// @summary Public function to explicitly check an entanglement condition and update its state if met.
     /// @param _entanglementId The ID of the entanglement to check.
     /// @dev Callable by anyone. Could potentially be incentivized in a production system.
    function checkAndMarkEntanglementMet(uint256 _entanglementId) external whenNotPaused {
         require(_entanglementId > 0 && _entanglementId <= _entanglementIdCounter, "Invalid entanglement ID");
         Entanglement storage entanglement = entanglements[_entanglementId];
         require(entanglement.state == EntanglementState.Pending, "Entanglement not in Pending state");

         bool conditionMet = _checkEntanglementCondition(_entanglementId, entanglement.entanglementType, entanglement.conditionData);

         if (conditionMet) {
             _markEntanglementMet(_entanglementId);
         }
         // If condition is not met, state remains Pending.
         // If condition *can never* be met (e.g., linked offer cancelled), _checkEntanglementCondition should ideally handle this.
    }

     /// @dev Internal function to check if an entanglement condition is met.
     function _checkEntanglementCondition(uint256 _entanglementId, EntanglementType _type, bytes memory _conditionData) internal view returns (bool) {
         if (_type == EntanglementType.None) return true; // No condition means it's always met (shouldn't reach here if state is Entangled)

         if (_type == EntanglementType.TimeLock) {
             uint256 unlockBlockOrTimestamp = abi.decode(_conditionData, (uint256));
             // Simple check against block.number. Could be block.timestamp depending on data.
             // Be mindful of timestamp reliance on miners vs. block number determinism.
             return block.number >= unlockBlockOrTimestamp;
         } else if (_type == EntanglementType.OracleCondition) {
             require(oracleAddress != address(0), "Oracle address not set for check");
             // Pass conditionData to the oracle contract
             return IQuantumOracle(oracleAddress).checkCondition(_conditionData);
         } else if (_type == EntanglementType.OfferLink) {
             uint256 linkedOfferId = abi.decode(_conditionData, (uint256));
             require(linkedOfferId > 0 && linkedOfferId <= _offerIdCounter, "Invalid linked offer ID in condition data");
             // Condition is met if the linked offer is Fulfilled
             if (offers[linkedOfferId].state == OfferState.Fulfilled) return true;
             // Condition fails if the linked offer is Cancelled or Expired
             if (offers[linkedOfferId].state == OfferState.Cancelled || offers[linkedOfferId].state == OfferState.Expired) {
                 // Marking as Failed here is tricky in a view function.
                 // This needs to be handled by an external trigger or during attemptFulfillment.
                 // For now, we just return false. A separate checkAndMarkEntanglementFailed function could exist.
                 // For simplicity, we'll rely on attemptFulfillment or checkAndMarkEntanglementMet to update state.
                 return false;
             }
             return false; // Linked offer not yet fulfilled
         } else if (_type == EntanglementType.CustomCondition) {
              uint256 customType;
              bytes memory customData;
              (customType, customData) = abi.decode(_conditionData, (uint256, bytes));
              address customContract = customConditionRegistry[customType];
              require(customContract != address(0), "Custom condition contract not registered");
              return ICustomEntanglementCondition(customContract).checkCondition(_entanglementId, customData);
         } else {
             revert("Unsupported entanglement type for checking");
         }
     }

     /// @dev Internal function to mark an entanglement state as Met.
     function _markEntanglementMet(uint256 _entanglementId) internal {
          Entanglement storage entanglement = entanglements[_entanglementId];
          require(entanglement.state == EntanglementState.Pending, "Entanglement not in Pending state to be marked Met");
          entanglement.state = EntanglementState.Met;
          emit EntanglementConditionMet(_entanglementId);
     }

     /// @dev Internal function to mark an entanglement state as Failed or Inactive.
     function _markEntanglementFailed(uint256 _entanglementId) internal {
         Entanglement storage entanglement = entanglements[_entanglementId];
         if (entanglement.state == EntanglementState.Pending) {
             entanglement.state = EntanglementState.Failed;
             emit EntanglementConditionFailed(_entanglementId);
         } else if (entanglement.state == EntanglementState.Met) {
              // If condition was met but linked offer later failed/expired, this might be Inactive
              entanglement.state = EntanglementState.Inactive;
              // Maybe a different event like EntanglementBecameInactive
         }
          // Do nothing if already Failed or Inactive
     }


     /// @dev Internal function to update the state of an offer.
     function _updateOfferState(uint256 _offerId, OfferState _newState) internal {
         SwapOffer storage offer = offers[_offerId];
         offer.state = _newState;

         // Handle linked entanglements if the offer reaches a terminal state (Cancelled, Expired, Fulfilled)
         if (_newState == OfferState.Cancelled || _newState == OfferState.Expired || _newState == OfferState.Fulfilled) {
             // Need to find any entanglements that use *this* offerId as their conditionData
             // This is inefficient without a reverse mapping. Omitted for simplicity in this example.
             // A production system would need `mapping(uint256 linkedOfferId => uint256[] dependantEntanglementIds)`
             // and iterate through that list calling _markEntanglementFailed or _markEntanglementMet accordingly.
         }
     }


    // --- Asset Claiming ---

     /// @summary Allows a user to claim any assets currently claimable by them.
    function claimAssets() external whenNotPaused {
        address payable claimant = payable(msg.sender);

        // Claim ETH
        uint256 ethAmount = claimableETH[claimant];
        if (ethAmount > 0) {
            claimableETH[claimant] = 0; // Set to 0 BEFORE transfer (check-effects-interactions)
            (bool success, ) = claimant.call{value: ethAmount}("");
            require(success, "ETH claim failed");
            emit AssetsClaimed(claimant, address(0), ethAmount, AssetType.Ether);
        }

        // Claim ERC20 tokens
        // Iterate through approved tokens to find claimable balances
        address[] memory tokenAddresses = approvedTokens.values();
        for (uint i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            uint256 tokenAmount = claimableERC20[claimant][tokenAddress];
            if (tokenAmount > 0) {
                 claimableERC20[claimant][tokenAddress] = 0; // Set to 0 BEFORE transfer
                 IERC20(tokenAddress).safeTransfer(claimant, tokenAmount);
                 emit AssetsClaimed(claimant, tokenAddress, tokenAmount, AssetType.ERC20);
            }
        }

        // Claim ERC721 tokens
         address[] memory collectionAddresses = approvedNFTCollections.values();
         for (uint i = 0; i < collectionAddresses.length; i++) {
             address collectionAddress = collectionAddresses[i];
             // Get the set of claimable token IDs for this collection
             EnumerableSet.UintSet storage tokenIds = claimableERC721Ids[claimant][collectionAddress];
             uint256[] memory idsToClaim = tokenIds.values(); // Get all IDs in the set
             uint256 numIds = idsToClaim.length;

             // Clear the set BEFORE transfers
             for(uint j = 0; j < numIds; j++) {
                 tokenIds.remove(idsToClaim[j]);
             }

             // Perform transfers
             for (uint j = 0; j < numIds; j++) {
                 IERC721(collectionAddress).safeTransferFrom(address(this), claimant, idsToClaim[j]);
                 emit AssetsClaimed(claimant, collectionAddress, idsToClaim[j], AssetType.ERC721);
             }
         }
    }

     /// @summary View function to check claimable ERC20 balance for a user and token.
     /// @param _user The user's address.
     /// @param _tokenAddress The ERC20 token address.
     /// @return The claimable amount.
    function getClaimableERC20(address _user, address _tokenAddress) external view returns (uint256) {
        return claimableERC20[_user][_tokenAddress];
    }

     /// @summary View function to check claimable ERC721 token IDs for a user and collection.
     /// @param _user The user's address.
     /// @param _tokenAddress The ERC721 collection address.
     /// @return An array of claimable token IDs.
    function getClaimableERC721(address _user, address _tokenAddress) external view returns (uint256[] memory) {
        return claimableERC721Ids[_user][_tokenAddress].values();
    }

     /// @summary View function to check claimable ETH balance for a user.
     /// @param _user The user's address.
     /// @return The claimable amount in wei.
    function getClaimableETH(address _user) external view returns (uint256) {
        return claimableETH[_user];
    }


    // --- Protocol Configuration & Administration (Owner/Admin) ---

    /// @summary Owner adds an ERC20 token address to the approved list for swaps.
    /// @param _tokenAddress The address of the ERC20 token.
    function addApprovedToken(address _tokenAddress) external onlyOwner whenNotPaused {
        require(_tokenAddress != address(0), "Invalid address");
        require(!approvedTokens.contains(_tokenAddress), "Token already approved");
        approvedTokens.add(_tokenAddress);
        emit AssetApproved(_tokenAddress, AssetType.ERC20, true);
    }

    /// @summary Owner removes an ERC20 token address from the approved list.
    /// @param _tokenAddress The address of the ERC20 token.
    function removeApprovedToken(address _tokenAddress) external onlyOwner whenNotPaused {
        require(approvedTokens.contains(_tokenAddress), "Token not approved");
        approvedTokens.remove(_tokenAddress);
        emit AssetApproved(_tokenAddress, AssetType.ERC20, false);
    }

    /// @summary Owner adds an ERC721 collection address to the approved list for swaps.
    /// @param _tokenAddress The address of the ERC721 collection.
    function addApprovedNFTCollection(address _tokenAddress) external onlyOwner whenNotPaused {
        require(_tokenAddress != address(0), "Invalid address");
         require(!approvedNFTCollections.contains(_tokenAddress), "Collection already approved");
        approvedNFTCollections.add(_tokenAddress);
        emit AssetApproved(_tokenAddress, AssetType.ERC721, true);
    }

    /// @summary Owner removes an ERC721 collection address from the approved list.
    /// @param _tokenAddress The address of the ERC721 collection.
    function removeApprovedNFTCollection(address _tokenAddress) external onlyOwner whenNotPaused {
        require(approvedNFTCollections.contains(_tokenAddress), "Collection not approved");
        approvedNFTCollections.remove(_tokenAddress);
        emit AssetApproved(_tokenAddress, AssetType.ERC721, false);
    }

     /// @summary Owner sets the address of the trusted Oracle contract.
     /// @param _oracleAddress The address of the IQuantumOracle contract.
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid address");
        emit OracleAddressUpdated(oracleAddress, _oracleAddress);
        oracleAddress = _oracleAddress;
    }

     /// @summary Owner sets the fee required for creating certain entanglement types (Oracle, Custom).
     /// @param _feeInWei The fee amount in wei.
    function setEntanglementFee(uint256 _feeInWei) external onlyOwner {
        emit EntanglementFeeUpdated(entanglementFee, _feeInWei);
        entanglementFee = _feeInWei;
    }

     /// @summary Owner withdraws accumulated protocol fees (in ETH).
    function withdrawFees() external onlyOwner {
        uint256 amount = protocolFees;
        require(amount > 0, "No fees to withdraw");
        protocolFees = 0; // Set to 0 BEFORE transfer
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit ProtocolFeeClaimed(owner(), amount);
    }

    /// @summary Pauses the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @summary Unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    // Override required for ERC721Holder to accept NFTs
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external virtual override returns (bytes4)
    {
        // Add checks here if needed, e.g., only allow receive in createOffer context
        return this.onERC721Received.selector;
    }

    // --- Helper/View Functions ---

    /// @summary Checks if an ERC20 token is approved.
    function isApprovedToken(address _tokenAddress) external view returns (bool) {
        return approvedTokens.contains(_tokenAddress);
    }

     /// @summary Checks if an ERC721 collection is approved.
    function isApprovedNFTCollection(address _tokenAddress) external view returns (bool) {
        return approvedNFTCollections.contains(_tokenAddress);
    }

     /// @summary Gets the contract address registered for a custom entanglement type.
     /// @param _customTypeIdentifier The identifier for the custom type.
     /// @return The contract address, or zero address if not registered.
    function getCustomEntanglementContract(uint256 _customTypeIdentifier) external view returns (address) {
        return customConditionRegistry[_customTypeIdentifier];
    }

    /// @summary Gets the total number of offers created.
    function getTotalOffers() external view returns (uint256) {
        return _offerIdCounter;
    }

     /// @summary Gets the total number of entanglements created.
    function getTotalEntanglements() external view returns (uint256) {
        return _entanglementIdCounter;
    }

    // Fallback function to reject unexpected ETH transfers unless explicitly handled
    fallback() external payable {
        revert("Fallback not intended for general use");
    }

     // Note: The implementation of _checkEntanglementCondition for Oracle and Custom types
     // assumes specific interfaces (IQuantumOracle, ICustomEntanglementCondition) that
     // need to be defined and deployed separately. The `bytes conditionData` allows
     // flexibility for these external contracts to define their own condition parameters.
     // The OfferLink entanglement could be optimized by having a reverse mapping
     // from linked offer ID to dependent entanglement IDs to avoid searching.
     // Error handling for failed external calls (oracle, custom) should be robust.
     // Gas costs for iterating through assets/claims should be considered for large numbers.
}
```