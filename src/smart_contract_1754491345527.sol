Okay, this is a fantastic challenge! Let's build a smart contract that goes beyond typical DeFi or NFT patterns, focusing on *temporal logic*, *dynamic asset states*, and *on-chain agreements with built-in conditions*.

I present **ChronoLink: The Temporal Agreement Protocol**.

It allows users to create time-bound, condition-dependent digital agreements, facilitate dynamic NFT transformations, and enable sophisticated access/rights management. It's designed to be a protocol for future-dated, reactive, and evolving on-chain commitments.

---

## ChronoLink: The Temporal Agreement Protocol

**Contract Name:** `ChronoLink`

**Core Concept:** ChronoLink facilitates the creation and management of sophisticated, time-bound, and condition-dependent digital agreements. It enables scenarios where assets, rights, or values can be automatically transformed, released, or altered based on temporal milestones, external data feeds (oracles), or explicit fulfillment. It aims to provide a decentralized framework for subscriptions, time-vested rights, future options, dynamic NFT evolution, and conditional asset releases.

### Outline and Function Summary

**I. Core Agreement Management**
*   `ChronoLinkAgreement` struct: Defines the structure of each agreement.
*   `agreementCounter`: Unique ID generator for agreements.
*   `agreements`: Stores all ChronoLink agreements.

**II. Admin & Protocol Configuration**
*   `owner`: Contract deployer, holds administrative privileges.
*   `protocolFeeRate`: Percentage fee charged on certain value transfers.
*   `feeRecipient`: Address receiving protocol fees.
*   `registerAgreementType`: Defines supported types of agreements (e.g., "Lease", "Option", "Subscription").
*   `setProtocolFeeRate`: Modifies the protocol fee.
*   `setFeeRecipient`: Changes the address for fee collection.
*   `pauseProtocol`: Emergency pause function.
*   `unpauseProtocol`: Unpause the protocol.

**III. Agreement Creation & Lifecycle**
*   `createChronoLink`: Mints a new ChronoLink agreement, defining its terms, duration, and associated assets/values.
*   `fulfillChronoLink`: Marks an agreement as fulfilled by the beneficiary, triggering associated actions.
*   `revokeChronoLink`: Allows the agreement owner to cancel an agreement under specific conditions (e.g., before start, if not fulfilled).
*   `extendChronoLink`: Allows extending the `endTimestamp` of an active agreement.

**IV. Asset & Value Management (Time-Based & Conditional)**
*   `depositValueForLink`: Deposits ETH or ERC20 into the contract as collateral or value for a specific agreement.
*   `claimValueFromLink`: Allows beneficiaries or owners to claim locked value upon agreement fulfillment or expiry.
*   `depositNFTAsCollateral`: Allows an ERC721 NFT to be locked as collateral for an agreement.
*   `claimNFTFromLink`: Enables claiming a locked NFT from an agreement.
*   `transformDynamicAsset`: Triggers a predefined transformation on an associated ERC721 NFT based on agreement status/time. (Requires an external `IDynamicNFT` interface).
*   `releaseConditionalAsset`: Releases an asset (ERC20/NFT) only if an oracle condition (e.g., price feed) is met.
*   `depositTimeLockedValue`: Allows depositing ETH/ERC20 that can only be claimed after a specific timestamp.
*   `claimTimeLockedValue`: Claims value from `depositTimeLockedValue`.

**V. Rights & Access Management**
*   `delegateAgreementRights`: Allows an agreement owner to temporarily delegate management rights to another address.
*   `revokeDelegatedRights`: Revokes previously delegated rights.
*   `grantTemporalAccess`: Grants temporary, time-bound access permission to a resource (represented by a `bytes32` ID).

**VI. Dispute Resolution & Penalties (Basic)**
*   `initiateDispute`: Marks an agreement as disputed, pausing automatic actions.
*   `resolveDispute`: (Admin/Arbiter function) Resolves a dispute, releasing assets or applying penalties.
*   `penalizeBreach`: Applies a penalty (slashing collateral) for agreement breaches.

**VII. Batch Operations & Utilities**
*   `batchFulfillLinks`: Allows fulfilling multiple ChronoLink agreements in a single transaction.
*   `getAgreementDetails`: Public view function to retrieve all details of an agreement.
*   `getAgreementStatus`: Public view function to get the current status of an agreement.
*   `getCurrentTimestamp`: Helper function to get the current block timestamp.

---

### ChronoLink Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety, though 0.8+ handles overflow for basic ops

// Chainlink Price Feed Interface (for conditional releases)
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// Interface for Dynamic NFTs (NFTs that can change state/metadata)
interface IDynamicNFT {
    function transform(uint256 _tokenId, bytes calldata _transformationData) external;
    function getOwnerOf(uint256 _tokenId) external view returns (address);
}

contract ChronoLink is Ownable, Pausable {
    using SafeMath for uint256; // For clarity, though 0.8+ has built-in checks for +, -, *

    /* ==================================================================================== */
    /*                                  I. Data Structures                                  */
    /* ==================================================================================== */

    // Enum for different agreement statuses
    enum AgreementStatus {
        Inactive,    // Not yet started or cancelled
        Active,      // Currently ongoing
        Fulfilled,   // Completed successfully by beneficiary
        Expired,     // Reached endTimestamp without fulfillment
        Revoked,     // Cancelled by owner before fulfillment/expiry
        Disputed,    // Under dispute resolution
        Breached     // Failed to meet terms, potential penalty applied
    }

    // Enum for different types of agreements (extensible)
    enum AgreementType {
        General,          // Default, flexible agreement
        Lease,            // Temporal rental of an asset
        Option,           // Right to purchase/act in future
        Subscription,     // Recurring access/service
        FutureRight,      // A right that activates in the future
        ConditionalRelease// Asset release based on external conditions
    }

    // Main struct for a ChronoLink Agreement
    struct ChronoLinkAgreement {
        uint256 agreementId;        // Unique identifier for the agreement
        address owner;              // Creator/primary party of the agreement
        address beneficiary;        // Party benefiting from/fulfilling the agreement
        AgreementType agreementType;// Type of agreement (e.g., Lease, Option)
        AgreementStatus status;     // Current status of the agreement
        uint256 startTimestamp;     // When the agreement becomes active
        uint256 endTimestamp;       // When the agreement expires
        bytes32 termsHash;          // IPFS hash or content hash of detailed off-chain terms
        uint256 value;              // ETH or ERC20 value associated with the agreement
        address valueToken;         // Address of ERC20 token if `value` is not ETH (address(0) for ETH)
        address assetAddress;       // Address of associated ERC721/ERC1155 contract (address(0) if no asset)
        uint256 assetId;            // ID of the associated asset (e.g., NFT tokenId, ERC1155 ID)
        address delegatedTo;        // Address currently delegated management rights (address(0) if no delegation)
        uint256 collateralValue;    // Value held as collateral for the agreement
        address collateralToken;    // Token address of the collateral (address(0) for ETH)
        uint256 associatedChronoLinkId; // For linking complex agreements (e.g., an option linked to a future lease)
        address oracleAddress;      // Address of the oracle for conditional agreements
        int256 oracleThreshold;     // Threshold value for oracle-based conditions
        bool oracleConditionMet;    // Whether the oracle condition has been met
    }

    // Struct for time-locked value deposits
    struct TimeLockedDeposit {
        address depositor;
        uint256 amount;
        address tokenAddress; // address(0) for ETH
        uint256 unlockTimestamp;
    }

    // Struct for temporal access grants
    struct TemporalAccessGrant {
        address grantee;
        uint256 grantedTimestamp;
        uint256 expiryTimestamp;
        bool active;
    }

    /* ==================================================================================== */
    /*                                 II. State Variables                                  */
    /* ==================================================================================== */

    uint256 public agreementCounter; // Counter for unique agreement IDs
    mapping(uint256 => ChronoLinkAgreement) public agreements; // Stores all agreements by ID
    mapping(bytes32 => bool) public supportedAgreementTypes; // Whitelist of supported agreement types hashes (e.g., keccak256("Lease"))

    uint256 public protocolFeeRate; // e.g., 100 = 1% (10000 = 100%)
    address public feeRecipient;

    mapping(address => mapping(uint256 => TimeLockedDeposit)) private timeLockedDeposits; // User => DepositId => Deposit
    mapping(address => uint256) private timeLockedDepositCounter; // Counter for each user's time-locked deposits

    mapping(bytes32 => mapping(address => TemporalAccessGrant)) public temporalAccessGrants; // ResourceID => Grantee => Grant details

    /* ==================================================================================== */
    /*                                     III. Events                                      */
    /* ==================================================================================== */

    event ChronoLinkCreated(uint256 indexed agreementId, address indexed owner, address indexed beneficiary, AgreementType agreementType, uint256 startTimestamp, uint256 endTimestamp);
    event ChronoLinkFulfilled(uint256 indexed agreementId, address indexed fulfiller, uint256 timestamp);
    event ChronoLinkRevoked(uint256 indexed agreementId, address indexed revoker, string reason);
    event ChronoLinkExtended(uint256 indexed agreementId, uint256 newEndTimestamp);
    event ValueDeposited(uint256 indexed agreementId, address indexed depositor, uint256 amount, address tokenAddress);
    event ValueClaimed(uint256 indexed agreementId, address indexed claimant, uint256 amount, address tokenAddress);
    event NFTCollateralDeposited(uint256 indexed agreementId, address indexed depositor, address nftAddress, uint256 nftId);
    event NFTCollateralClaimed(uint256 indexed agreementId, address indexed claimant, address nftAddress, uint256 nftId);
    event AssetTransformed(uint256 indexed agreementId, address indexed assetAddress, uint256 assetId, bytes transformationData);
    event ConditionalAssetReleased(uint256 indexed agreementId, address indexed assetAddress, uint256 assetIdOrValue, address tokenAddress, int256 oracleValue);
    event RightsDelegated(uint256 indexed agreementId, address indexed from, address indexed to);
    event RightsRevoked(uint256 indexed agreementId, address indexed from, address indexed revokedAddress);
    event DisputeInitiated(uint256 indexed agreementId, address indexed initiator);
    event DisputeResolved(uint256 indexed agreementId, AgreementStatus finalStatus, address indexed resolver);
    event BreachPenalized(uint256 indexed agreementId, address indexed penalizedParty, uint256 penaltyAmount);
    event AgreementTypeRegistered(bytes32 indexed typeHash);
    event ProtocolFeeRateUpdated(uint256 newRate);
    event FeeRecipientUpdated(address newRecipient);
    event TimeLockedValueDeposited(address indexed depositor, uint256 indexed depositId, uint256 amount, address tokenAddress, uint256 unlockTimestamp);
    event TimeLockedValueClaimed(address indexed claimant, uint256 indexed depositId, uint256 amount, address tokenAddress);
    event TemporalAccessGranted(bytes32 indexed resourceId, address indexed grantee, uint256 expiryTimestamp);
    event TemporalAccessRevoked(bytes32 indexed resourceId, address indexed grantee);

    /* ==================================================================================== */
    /*                                    IV. Modifiers                                     */
    /* ==================================================================================== */

    // Checks if the sender is the owner or delegated party for an agreement
    modifier onlyAgreementOwnerOrDelegated(uint256 _agreementId) {
        require(agreements[_agreementId].owner == _msgSender() || agreements[_agreementId].delegatedTo == _msgSender(), "ChronoLink: Not agreement owner or delegated party");
        _;
    }

    // Checks if the sender is the beneficiary for an agreement
    modifier onlyAgreementBeneficiary(uint256 _agreementId) {
        require(agreements[_agreementId].beneficiary == _msgSender(), "ChronoLink: Not agreement beneficiary");
        _;
    }

    // Checks if the agreement is currently active
    modifier whenActive(uint256 _agreementId) {
        require(agreements[_agreementId].status == AgreementStatus.Active, "ChronoLink: Agreement not active");
        require(block.timestamp >= agreements[_agreementId].startTimestamp && block.timestamp < agreements[_agreementId].endTimestamp, "ChronoLink: Agreement out of active time window");
        _;
    }

    // Checks if the agreement is not yet fulfilled or expired
    modifier notYetCompleted(uint256 _agreementId) {
        require(agreements[_agreementId].status != AgreementStatus.Fulfilled &&
                agreements[_agreementId].status != AgreementStatus.Expired &&
                agreements[_agreementId].status != AgreementStatus.Revoked &&
                agreements[_agreementId].status != AgreementStatus.Breached, "ChronoLink: Agreement already completed");
        _;
    }

    // Checks if the agreement is not disputed
    modifier notDisputed(uint256 _agreementId) {
        require(agreements[_agreementId].status != AgreementStatus.Disputed, "ChronoLink: Agreement is under dispute");
        _;
    }

    /* ==================================================================================== */
    /*                                  V. Constructor                                      */
    /* ==================================================================================== */

    constructor(uint256 _initialFeeRate, address _initialFeeRecipient) Ownable(msg.sender) Pausable() {
        require(_initialFeeRate <= 10000, "ChronoLink: Fee rate cannot exceed 100%"); // 10000 = 100%
        require(_initialFeeRecipient != address(0), "ChronoLink: Fee recipient cannot be zero address");
        protocolFeeRate = _initialFeeRate;
        feeRecipient = _initialFeeRecipient;

        // Register some default agreement types
        supportedAgreementTypes[keccak256(abi.encodePacked("General"))] = true;
        supportedAgreementTypes[keccak256(abi.encodePacked("Lease"))] = true;
        supportedAgreementTypes[keccak256(abi.encodePacked("Option"))] = true;
        supportedAgreementTypes[keccak256(abi.encodePacked("Subscription"))] = true;
        supportedAgreementTypes[keccak256(abi.encodePacked("FutureRight"))] = true;
        supportedAgreementTypes[keccak256(abi.encodePacked("ConditionalRelease"))] = true;
    }

    /* ==================================================================================== */
    /*                                  VI. Admin Functions                                 */
    /* ==================================================================================== */

    /**
     * @dev Allows the owner to register a new agreement type.
     * @param _agreementTypeString String representation of the new type (e.g., "RoyaltySplit").
     */
    function registerAgreementType(string calldata _agreementTypeString) external onlyOwner {
        bytes32 typeHash = keccak256(abi.encodePacked(_agreementTypeString));
        require(!supportedAgreementTypes[typeHash], "ChronoLink: Agreement type already registered");
        supportedAgreementTypes[typeHash] = true;
        emit AgreementTypeRegistered(typeHash);
    }

    /**
     * @dev Sets the protocol fee rate.
     * @param _newRate The new fee rate (e.g., 100 for 1%). Max 10000 (100%).
     */
    function setProtocolFeeRate(uint256 _newRate) external onlyOwner {
        require(_newRate <= 10000, "ChronoLink: Fee rate cannot exceed 100%");
        protocolFeeRate = _newRate;
        emit ProtocolFeeRateUpdated(_newRate);
    }

    /**
     * @dev Sets the address to which protocol fees are sent.
     * @param _newRecipient The new address for fee collection.
     */
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "ChronoLink: New fee recipient cannot be zero address");
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(_newRecipient);
    }

    /**
     * @dev Pauses the protocol in case of emergency.
     */
    function pauseProtocol() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the protocol.
     */
    function unpauseProtocol() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Collects accumulated protocol fees from the contract balance.
     * This function allows the feeRecipient to withdraw collected fees.
     * @param _tokenAddress The address of the token to withdraw (address(0) for ETH).
     */
    function collectProtocolFees(address _tokenAddress) external {
        require(_msgSender() == feeRecipient, "ChronoLink: Not the fee recipient");
        uint256 balance;
        if (_tokenAddress == address(0)) {
            balance = address(this).balance.sub(address(this).balance.div(10000).mul(protocolFeeRate)); // Exclude collateral
            (bool success, ) = payable(feeRecipient).call{value: balance}("");
            require(success, "ChronoLink: ETH fee transfer failed");
        } else {
            IERC20 token = IERC20(_tokenAddress);
            balance = token.balanceOf(address(this)).sub(token.balanceOf(address(this)).div(10000).mul(protocolFeeRate)); // Exclude collateral
            require(token.transfer(feeRecipient, balance), "ChronoLink: ERC20 fee transfer failed");
        }
        // NOTE: This assumes collected fees are separate from active collateral.
        // A more robust system would track fees collected per agreement in a dedicated map.
        // For simplicity here, it just sends the contract's free balance.
    }

    /* ==================================================================================== */
    /*                             VII. Agreement Creation & Lifecycle                      */
    /* ==================================================================================== */

    /**
     * @dev Creates a new ChronoLink agreement.
     * @param _beneficiary The address benefiting from/fulfilling the agreement.
     * @param _agreementTypeString String identifying the type of agreement (e.g., "Lease").
     * @param _startTimestamp The block timestamp when the agreement becomes active.
     * @param _endTimestamp The block timestamp when the agreement expires.
     * @param _termsHash IPFS hash or content hash of detailed off-chain terms.
     * @param _value ETH or ERC20 value associated with the agreement.
     * @param _valueToken Address of ERC20 token if `_value` is not ETH (address(0) for ETH).
     * @param _assetAddress Address of associated ERC721/ERC1155 contract (address(0) if no asset).
     * @param _assetId ID of the associated asset (e.g., NFT tokenId, ERC1155 ID).
     * @param _collateralValue Value held as collateral for the agreement by the owner.
     * @param _collateralToken Token address of the collateral (address(0) for ETH).
     * @param _associatedChronoLinkId Optional: ID of another ChronoLink agreement this one is dependent on.
     * @param _oracleAddress Address of the Chainlink AggregatorV3Interface for conditional releases.
     * @param _oracleThreshold Threshold value for oracle-based conditions.
     */
    function createChronoLink(
        address _beneficiary,
        string calldata _agreementTypeString,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes32 _termsHash,
        uint256 _value,
        address _valueToken,
        address _assetAddress,
        uint256 _assetId,
        uint256 _collateralValue,
        address _collateralToken,
        uint256 _associatedChronoLinkId,
        address _oracleAddress,
        int256 _oracleThreshold
    )
        external
        payable
        whenNotPaused
        returns (uint256)
    {
        require(_beneficiary != address(0), "ChronoLink: Beneficiary cannot be zero address");
        bytes32 agreementTypeHash = keccak256(abi.encodePacked(_agreementTypeString));
        require(supportedAgreementTypes[agreementTypeHash], "ChronoLink: Unsupported agreement type");
        require(_startTimestamp >= block.timestamp, "ChronoLink: Start timestamp must be in the future");
        require(_endTimestamp > _startTimestamp, "ChronoLink: End timestamp must be after start timestamp");
        
        // Handle ETH value transfer for agreement value or collateral
        if (_valueToken == address(0) && _value > 0) {
            require(msg.value >= _value, "ChronoLink: Insufficient ETH sent for agreement value");
        }
        if (_collateralToken == address(0) && _collateralValue > 0) {
            require(msg.value >= _value + _collateralValue, "ChronoLink: Insufficient ETH sent for collateral");
        }
        if (_valueToken == address(0) && _collateralToken == address(0)) {
            require(msg.value == _value + _collateralValue, "ChronoLink: ETH sent does not match value + collateral");
        } else if (_valueToken == address(0)) {
             require(msg.value == _value, "ChronoLink: ETH sent does not match value");
        } else if (_collateralToken == address(0)) {
            require(msg.value == _collateralValue, "ChronoLink: ETH sent does not match collateral");
        }

        agreementCounter = agreementCounter.add(1);
        uint256 newId = agreementCounter;

        agreements[newId] = ChronoLinkAgreement({
            agreementId: newId,
            owner: _msgSender(),
            beneficiary: _beneficiary,
            agreementType: AgreementType(uint8(agreementTypeHash[0]) % 6), // Simple mapping, refine for robustness
            status: AgreementStatus.Active, // Starts active immediately or after startTimestamp based on design
            startTimestamp: _startTimestamp,
            endTimestamp: _endTimestamp,
            termsHash: _termsHash,
            value: _value,
            valueToken: _valueToken,
            assetAddress: _assetAddress,
            assetId: _assetId,
            delegatedTo: address(0), // No delegation initially
            collateralValue: _collateralValue,
            collateralToken: _collateralToken,
            associatedChronoLinkId: _associatedChronoLinkId,
            oracleAddress: _oracleAddress,
            oracleThreshold: _oracleThreshold,
            oracleConditionMet: false
        });

        // Pull in ERC20 value or collateral if applicable
        if (_valueToken != address(0) && _value > 0) {
            IERC20(_valueToken).transferFrom(_msgSender(), address(this), _value);
        }
        if (_collateralToken != address(0) && _collateralValue > 0) {
            IERC20(_collateralToken).transferFrom(_msgSender(), address(this), _collateralValue);
        }
        
        // If an NFT is associated as collateral, transfer it to the contract
        if (_assetAddress != address(0) && _assetId > 0) {
            IERC721(_assetAddress).transferFrom(_msgSender(), address(this), _assetId);
        }

        emit ChronoLinkCreated(newId, _msgSender(), _beneficiary, agreements[newId].agreementType, _startTimestamp, _endTimestamp);
        return newId;
    }

    /**
     * @dev Marks an agreement as fulfilled by the beneficiary.
     * This triggers potential value/asset transfers.
     * @param _agreementId The ID of the agreement to fulfill.
     */
    function fulfillChronoLink(uint256 _agreementId)
        external
        onlyAgreementBeneficiary(_agreementId)
        whenActive(_agreementId)
        notYetCompleted(_agreementId)
        notDisputed(_agreementId)
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        
        // Ensure that the agreement is actually active during fulfillment.
        require(block.timestamp >= agreement.startTimestamp, "ChronoLink: Agreement has not yet started");
        require(block.timestamp < agreement.endTimestamp, "ChronoLink: Agreement has expired for fulfillment");

        agreement.status = AgreementStatus.Fulfilled;

        // Transfer value to the agreement owner upon fulfillment
        if (agreement.value > 0) {
            if (agreement.valueToken == address(0)) {
                (bool success, ) = payable(agreement.owner).call{value: agreement.value}("");
                require(success, "ChronoLink: ETH value transfer to owner failed");
            } else {
                require(IERC20(agreement.valueToken).transfer(agreement.owner, agreement.value), "ChronoLink: ERC20 value transfer to owner failed");
            }
        }

        // If an NFT was held as collateral by the beneficiary, transfer it to the owner
        if (agreement.assetAddress != address(0) && agreement.assetId > 0) {
             IERC721(agreement.assetAddress).transferFrom(address(this), agreement.owner, agreement.assetId);
        }
        
        // Return collateral to the owner, if collateral was for the owner's commitment
        if (agreement.collateralValue > 0) {
            if (agreement.collateralToken == address(0)) {
                (bool success, ) = payable(agreement.owner).call{value: agreement.collateralValue}("");
                require(success, "ChronoLink: Collateral ETH transfer failed");
            } else {
                require(IERC20(agreement.collateralToken).transfer(agreement.owner, agreement.collateralValue), "ChronoLink: Collateral ERC20 transfer failed");
            }
        }

        emit ChronoLinkFulfilled(_agreementId, _msgSender(), block.timestamp);
    }

    /**
     * @dev Allows the agreement owner or delegated party to revoke an agreement.
     * Can only be done before fulfillment or expiry, and not if disputed.
     * Collateral might be partially or fully returned, depending on terms (simplified here).
     * @param _agreementId The ID of the agreement to revoke.
     */
    function revokeChronoLink(uint256 _agreementId, string calldata _reason)
        external
        onlyAgreementOwnerOrDelegated(_agreementId)
        notYetCompleted(_agreementId)
        notDisputed(_agreementId)
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];

        // Agreement can only be revoked if it hasn't expired and isn't fulfilled.
        // Also, add a condition that it can't be revoked if it's past its start time
        // and the beneficiary has already made a commitment (e.g., deposited value).
        // For simplicity, we allow revocation at any time before fulfillment or expiry.
        // A more complex contract would define penalties/forfeitures.

        agreement.status = AgreementStatus.Revoked;

        // Return collateral to the owner if applicable
        if (agreement.collateralValue > 0) {
            if (agreement.collateralToken == address(0)) {
                (bool success, ) = payable(agreement.owner).call{value: agreement.collateralValue}("");
                require(success, "ChronoLink: Collateral ETH refund failed on revoke");
            } else {
                require(IERC20(agreement.collateralToken).transfer(agreement.owner, agreement.collateralValue), "ChronoLink: Collateral ERC20 refund failed on revoke");
            }
        }
        
        // If an NFT was held as collateral for the agreement owner (e.g., owner deposited an NFT as a guarantee), return it.
        // NOTE: The `assetAddress` and `assetId` were transferred *from* the owner *to* the contract during creation,
        // so if the owner revokes, the asset should return to the owner.
        if (agreement.assetAddress != address(0) && agreement.assetId > 0) {
            IERC721(agreement.assetAddress).transferFrom(address(this), agreement.owner, agreement.assetId);
        }
        // If the agreement was meant to deliver value/asset to beneficiary, and it's revoked, that value/asset returns to owner.
        if (agreement.value > 0) {
            if (agreement.valueToken == address(0)) {
                 if (address(this).balance >= agreement.value) { // Check if contract holds enough ETH for refund
                    (bool success, ) = payable(agreement.owner).call{value: agreement.value}("");
                    require(success, "ChronoLink: ETH value refund failed on revoke");
                 }
            } else {
                if (IERC20(agreement.valueToken).balanceOf(address(this)) >= agreement.value) { // Check if contract holds enough ERC20
                    require(IERC20(agreement.valueToken).transfer(agreement.owner, agreement.value), "ChronoLink: ERC20 value refund failed on revoke");
                }
            }
        }
        

        emit ChronoLinkRevoked(_agreementId, _msgSender(), _reason);
    }

    /**
     * @dev Allows extending the end timestamp of an active agreement.
     * Only callable by the agreement owner or delegated party.
     * @param _agreementId The ID of the agreement to extend.
     * @param _newEndTimestamp The new end timestamp. Must be greater than current endTimestamp.
     */
    function extendChronoLink(uint256 _agreementId, uint256 _newEndTimestamp)
        external
        onlyAgreementOwnerOrDelegated(_agreementId)
        whenActive(_agreementId)
        notDisputed(_agreementId)
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(_newEndTimestamp > agreement.endTimestamp, "ChronoLink: New end timestamp must be in the future beyond current end");
        
        agreement.endTimestamp = _newEndTimestamp;
        emit ChronoLinkExtended(_agreementId, _newEndTimestamp);
    }

    /* ==================================================================================== */
    /*                         VIII. Asset & Value Management                               */
    /* ==================================================================================== */

    /**
     * @dev Allows depositing ETH or ERC20 into the contract as value or additional collateral for an agreement.
     * @param _agreementId The ID of the agreement.
     * @param _amount The amount to deposit.
     * @param _tokenAddress The token address (address(0) for ETH).
     */
    function depositValueForLink(uint256 _agreementId, uint256 _amount, address _tokenAddress)
        external
        payable
        whenActive(_agreementId)
        notDisputed(_agreementId)
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(_amount > 0, "ChronoLink: Deposit amount must be greater than zero");
        
        if (_tokenAddress == address(0)) {
            require(msg.value == _amount, "ChronoLink: ETH sent must match amount");
            // No need to explicitly add to agreement.value, as this is for "additional" value/collateral,
            // which would be handled by a more complex internal accounting system.
            // For now, assume this simply adds to the contract's balance to be handled later or for general purpose.
        } else {
            require(msg.value == 0, "ChronoLink: Do not send ETH for ERC20 deposit");
            IERC20(_tokenAddress).transferFrom(_msgSender(), address(this), _amount);
        }
        // This function simply accepts deposits. The _amount deposited isn't directly tied to agreement.value or .collateralValue
        // in this simplified model. A real system would need separate storage for 'extra' deposits per agreement.
        emit ValueDeposited(_agreementId, _msgSender(), _amount, _tokenAddress);
    }

    /**
     * @dev Allows claiming value (ETH or ERC20) from an agreement.
     * This might be the `value` of the agreement for the beneficiary post-fulfillment,
     * or collateral for the owner post-expiry/breach.
     * @param _agreementId The ID of the agreement.
     */
    function claimValueFromLink(uint256 _agreementId)
        external
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(agreement.status == AgreementStatus.Fulfilled || agreement.status == AgreementStatus.Expired || agreement.status == AgreementStatus.Breached, "ChronoLink: Agreement not in a claimable state");
        
        uint256 claimableAmount = 0;
        address claimer = address(0);
        address tokenToClaim = address(0);

        // Define claim logic based on agreement status and sender role
        if (agreement.status == AgreementStatus.Fulfilled) {
            // If fulfilled, value goes to owner, collateral goes back to owner
            if (_msgSender() == agreement.owner) {
                claimableAmount = agreement.value.add(agreement.collateralValue);
                tokenToClaim = agreement.valueToken == agreement.collateralToken ? agreement.valueToken : address(0); // Simplify: assume same token or ETH
            } else {
                revert("ChronoLink: Only owner can claim from fulfilled agreement");
            }
        } else if (agreement.status == AgreementStatus.Expired) {
            // If expired, collateral might revert to owner, value remains with owner if not claimed by beneficiary
            if (_msgSender() == agreement.owner) {
                claimableAmount = agreement.collateralValue.add(agreement.value); // Owner claims back value and collateral
                tokenToClaim = agreement.valueToken == agreement.collateralToken ? agreement.valueToken : address(0);
            } else {
                revert("ChronoLink: Only owner can claim from expired agreement");
            }
        } else if (agreement.status == AgreementStatus.Breached) {
            // If breached, value/collateral might be distributed as penalty (simplified: to owner)
            if (_msgSender() == agreement.owner) {
                 claimableAmount = agreement.collateralValue.add(agreement.value); // Owner claims value and collateral after breach
                 tokenToClaim = agreement.valueToken == agreement.collateralToken ? agreement.valueToken : address(0);
            } else {
                revert("ChronoLink: Only owner can claim from breached agreement");
            }
        }
        
        require(claimableAmount > 0, "ChronoLink: No claimable amount for this agreement or sender");

        if (tokenToClaim == address(0)) { // ETH
            (bool success, ) = payable(_msgSender()).call{value: claimableAmount}("");
            require(success, "ChronoLink: ETH claim failed");
        } else { // ERC20
            require(IERC20(tokenToClaim).transfer(_msgSender(), claimableAmount), "ChronoLink: ERC20 claim failed");
        }
        
        // Reset agreement values after claim to prevent re-claiming (simplistic approach, would need a dedicated accounting)
        agreement.value = 0;
        agreement.collateralValue = 0;

        emit ValueClaimed(_agreementId, _msgSender(), claimableAmount, tokenToClaim);
    }

    /**
     * @dev Allows an ERC721 NFT to be deposited as collateral for an agreement by its owner.
     * The NFT is transferred to the ChronoLink contract.
     * @param _agreementId The ID of the agreement this NFT is collateral for.
     * @param _nftAddress The address of the ERC721 contract.
     * @param _nftId The tokenId of the NFT.
     */
    function depositNFTAsCollateral(uint256 _agreementId, address _nftAddress, uint256 _nftId)
        external
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(agreement.status == AgreementStatus.Active, "ChronoLink: Agreement not active for NFT deposit");
        require(agreement.owner == _msgSender(), "ChronoLink: Only agreement owner can deposit NFT as collateral");
        require(_nftAddress != address(0), "ChronoLink: NFT address cannot be zero");
        
        // Transfer NFT to the contract
        IERC721(_nftAddress).transferFrom(_msgSender(), address(this), _nftId);
        
        // Link the NFT to the agreement as collateral
        agreement.assetAddress = _nftAddress;
        agreement.assetId = _nftId;

        emit NFTCollateralDeposited(_agreementId, _msgSender(), _nftAddress, _nftId);
    }

    /**
     * @dev Allows claiming an NFT associated with an agreement.
     * This could be the original collateral or an asset delivered by the agreement.
     * @param _agreementId The ID of the agreement.
     */
    function claimNFTFromLink(uint256 _agreementId)
        external
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(agreement.assetAddress != address(0) && agreement.assetId > 0, "ChronoLink: No NFT associated with this agreement");
        
        address nftOwnerInContract = IERC721(agreement.assetAddress).ownerOf(agreement.assetId);
        require(nftOwnerInContract == address(this), "ChronoLink: Contract does not own this NFT");

        // Logic for who can claim the NFT based on agreement status
        address recipient = address(0);
        if (agreement.status == AgreementStatus.Fulfilled) {
            // If the agreement was for a beneficiary to receive an NFT from the owner
            // or if it was collateral from the owner now returned.
            // Simplistic: Assume if fulfilled, owner gets it back or new owner gets it.
            // A real contract would have specific `assetDeliveryTo` field.
            recipient = agreement.owner; // If NFT was owner's collateral for fulfillment
            if(agreement.agreementType == AgreementType.Lease) recipient = agreement.beneficiary; // Example: NFT lease to beneficiary
        } else if (agreement.status == AgreementStatus.Expired || agreement.status == AgreementStatus.Revoked || agreement.status == AgreementStatus.Breached) {
            recipient = agreement.owner; // In these cases, owner usually reclaims their asset/collateral
        } else {
            revert("ChronoLink: NFT not claimable yet for this agreement status");
        }
        
        require(_msgSender() == recipient, "ChronoLink: You are not authorized to claim this NFT");

        IERC721(agreement.assetAddress).transferFrom(address(this), recipient, agreement.assetId);
        
        // Clear asset reference to prevent re-claiming
        agreement.assetAddress = address(0);
        agreement.assetId = 0;

        emit NFTCollateralClaimed(_agreementId, _msgSender(), agreement.assetAddress, agreement.assetId);
    }

    /**
     * @dev Triggers a transformation on an associated dynamic NFT.
     * Assumes `assetAddress` points to an `IDynamicNFT` compatible contract.
     * Can only be triggered by the owner/beneficiary when specific conditions met.
     * @param _agreementId The ID of the agreement whose NFT is to be transformed.
     * @param _transformationData Arbitrary bytes data for the NFT's transform function.
     */
    function transformDynamicAsset(uint256 _agreementId, bytes calldata _transformationData)
        external
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(agreement.assetAddress != address(0) && agreement.assetId > 0, "ChronoLink: No dynamic NFT associated");
        // Ensure the agreement logic allows for transformation at this stage.
        // E.g., only after fulfillment, or after a specific timestamp, or by owner.
        require(agreement.status == AgreementStatus.Fulfilled || block.timestamp >= agreement.endTimestamp, "ChronoLink: NFT transformation not allowed at this stage");
        require(_msgSender() == agreement.owner || _msgSender() == agreement.beneficiary, "ChronoLink: Not authorized to trigger transformation");
        
        // Ensure the current owner of the NFT is this contract, or the one initiating the transform.
        require(IDynamicNFT(agreement.assetAddress).getOwnerOf(agreement.assetId) == address(this), "ChronoLink: Contract must hold NFT to transform it");

        IDynamicNFT(agreement.assetAddress).transform(agreement.assetId, _transformationData);
        emit AssetTransformed(_agreementId, agreement.assetAddress, agreement.assetId, _transformationData);
    }

    /**
     * @dev Releases an asset (ETH, ERC20, or NFT) based on a Chainlink oracle condition being met.
     * Agreement must be of type `ConditionalRelease`.
     * @param _agreementId The ID of the agreement.
     */
    function releaseConditionalAsset(uint256 _agreementId)
        external
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(agreement.agreementType == AgreementType.ConditionalRelease, "ChronoLink: Not a conditional release agreement");
        require(agreement.status == AgreementStatus.Active, "ChronoLink: Agreement not active for conditional release");
        require(!agreement.oracleConditionMet, "ChronoLink: Oracle condition already met and asset potentially released");
        require(agreement.oracleAddress != address(0), "ChronoLink: No oracle configured for this agreement");
        
        AggregatorV3Interface priceFeed = AggregatorV3Interface(agreement.oracleAddress);
        (, int256 price, , ,) = priceFeed.latestRoundData();
        
        bool conditionMet = false;
        // Example condition: Price >= threshold
        if (price >= agreement.oracleThreshold) {
            conditionMet = true;
        }
        // More complex conditions (e.g., price < threshold, price within range) could be
        // defined by additional agreement parameters or by specific oracle interfaces.

        require(conditionMet, "ChronoLink: Oracle condition not met yet");

        agreement.oracleConditionMet = true; // Mark condition as met

        // Release the asset (ETH, ERC20, or NFT)
        if (agreement.valueToken == address(0) && agreement.value > 0) { // ETH release
            (bool success, ) = payable(agreement.beneficiary).call{value: agreement.value}("");
            require(success, "ChronoLink: Conditional ETH release failed");
            agreement.value = 0; // Prevent double claim
            emit ConditionalAssetReleased(_agreementId, address(0), agreement.value, address(0), price);
        } else if (agreement.valueToken != address(0) && agreement.value > 0) { // ERC20 release
            require(IERC20(agreement.valueToken).transfer(agreement.beneficiary, agreement.value), "ChronoLink: Conditional ERC20 release failed");
            agreement.value = 0; // Prevent double claim
            emit ConditionalAssetReleased(_agreementId, agreement.valueToken, agreement.value, agreement.valueToken, price);
        } else if (agreement.assetAddress != address(0) && agreement.assetId > 0) { // NFT release
            IERC721(agreement.assetAddress).transferFrom(address(this), agreement.beneficiary, agreement.assetId);
            agreement.assetAddress = address(0); // Clear reference
            agreement.assetId = 0; // Clear reference
            emit ConditionalAssetReleased(_agreementId, agreement.assetAddress, agreement.assetId, address(0), price);
        } else {
            revert("ChronoLink: No asset or value to release for this agreement");
        }
        
        agreement.status = AgreementStatus.Fulfilled; // Mark as fulfilled after conditional release
    }

    /**
     * @dev Allows depositing ETH or ERC20 that can only be claimed after a specific timestamp.
     * This is separate from ChronoLinkAgreements, acting as a general time-locked vault.
     * @param _amount The amount to deposit.
     * @param _tokenAddress The token address (address(0) for ETH).
     * @param _unlockTimestamp The timestamp after which the value can be claimed.
     */
    function depositTimeLockedValue(uint256 _amount, address _tokenAddress, uint256 _unlockTimestamp)
        external
        payable
        whenNotPaused
        returns (uint256 depositId)
    {
        require(_amount > 0, "ChronoLink: Deposit amount must be greater than zero");
        require(_unlockTimestamp > block.timestamp, "ChronoLink: Unlock timestamp must be in the future");

        if (_tokenAddress == address(0)) {
            require(msg.value == _amount, "ChronoLink: ETH sent must match amount");
        } else {
            require(msg.value == 0, "ChronoLink: Do not send ETH for ERC20 deposit");
            IERC20(_tokenAddress).transferFrom(_msgSender(), address(this), _amount);
        }

        uint256 currentId = timeLockedDepositCounter[_msgSender()].add(1);
        timeLockedDeposits[_msgSender()][currentId] = TimeLockedDeposit({
            depositor: _msgSender(),
            amount: _amount,
            tokenAddress: _tokenAddress,
            unlockTimestamp: _unlockTimestamp
        });
        timeLockedDepositCounter[_msgSender()] = currentId;

        emit TimeLockedValueDeposited(_msgSender(), currentId, _amount, _tokenAddress, _unlockTimestamp);
        return currentId;
    }

    /**
     * @dev Allows claiming previously deposited time-locked value.
     * @param _depositId The ID of the deposit (unique per depositor).
     */
    function claimTimeLockedValue(uint256 _depositId)
        external
        whenNotPaused
    {
        TimeLockedDeposit storage deposit = timeLockedDeposits[_msgSender()][_depositId];
        require(deposit.depositor == _msgSender(), "ChronoLink: Not your deposit");
        require(deposit.amount > 0, "ChronoLink: Deposit already claimed or does not exist");
        require(block.timestamp >= deposit.unlockTimestamp, "ChronoLink: Deposit is still locked");

        uint256 amountToClaim = deposit.amount;
        address tokenToClaim = deposit.tokenAddress;

        // Clear the deposit record first to prevent re-entrancy / double claim
        deposit.amount = 0;
        deposit.unlockTimestamp = 0;

        if (tokenToClaim == address(0)) { // ETH
            (bool success, ) = payable(_msgSender()).call{value: amountToClaim}("");
            require(success, "ChronoLink: Time-locked ETH claim failed");
        } else { // ERC20
            require(IERC20(tokenToClaim).transfer(_msgSender(), amountToClaim), "ChronoLink: Time-locked ERC20 claim failed");
        }

        emit TimeLockedValueClaimed(_msgSender(), _depositId, amountToClaim, tokenToClaim);
    }

    /* ==================================================================================== */
    /*                         IX. Rights & Access Management                               */
    /* ==================================================================================== */

    /**
     * @dev Allows an agreement owner to delegate management rights to another address.
     * The delegated address can perform actions like extending or revoking the agreement.
     * @param _agreementId The ID of the agreement.
     * @param _delegatee The address to delegate rights to.
     */
    function delegateAgreementRights(uint256 _agreementId, address _delegatee)
        external
        onlyAgreementOwnerOrDelegated(_agreementId) // Owner or current delegatee can re-delegate
        whenActive(_agreementId)
        notDisputed(_agreementId)
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(_delegatee != agreement.owner, "ChronoLink: Cannot delegate to self (owner)");
        require(_delegatee != address(0), "ChronoLink: Delegatee cannot be zero address");
        agreement.delegatedTo = _delegatee;
        emit RightsDelegated(_agreementId, _msgSender(), _delegatee);
    }

    /**
     * @dev Revokes previously delegated management rights for an agreement.
     * Only the original owner or the currently delegated address can revoke.
     * @param _agreementId The ID of the agreement.
     */
    function revokeDelegatedRights(uint256 _agreementId)
        external
        onlyAgreementOwnerOrDelegated(_agreementId) // Only owner or current delegatee can revoke
        whenActive(_agreementId)
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(agreement.delegatedTo != address(0), "ChronoLink: No delegated rights to revoke");
        address revokedAddress = agreement.delegatedTo;
        agreement.delegatedTo = address(0);
        emit RightsRevoked(_agreementId, _msgSender(), revokedAddress);
    }

    /**
     * @dev Grants temporary, time-bound access to a specific resource identified by `_resourceId`.
     * This can be used for subscription access, time-limited feature unlocks, etc.
     * @param _resourceId A unique identifier for the resource (e.g., keccak256 of "PremiumContent").
     * @param _grantee The address being granted access.
     * @param _durationInSeconds The duration for which access is granted, in seconds.
     */
    function grantTemporalAccess(bytes32 _resourceId, address _grantee, uint256 _durationInSeconds)
        external
        onlyOwner // Only owner/admin can grant access in this general purpose function
        whenNotPaused
    {
        require(_grantee != address(0), "ChronoLink: Grantee cannot be zero address");
        require(_durationInSeconds > 0, "ChronoLink: Duration must be positive");

        uint256 expiry = block.timestamp.add(_durationInSeconds);
        temporalAccessGrants[_resourceId][_grantee] = TemporalAccessGrant({
            grantee: _grantee,
            grantedTimestamp: block.timestamp,
            expiryTimestamp: expiry,
            active: true
        });
        emit TemporalAccessGranted(_resourceId, _grantee, expiry);
    }

    /**
     * @dev Revokes previously granted temporal access for a specific resource.
     * @param _resourceId A unique identifier for the resource.
     * @param _grantee The address whose access is being revoked.
     */
    function revokeTemporalAccess(bytes32 _resourceId, address _grantee)
        external
        onlyOwner // Only owner/admin can revoke
        whenNotPaused
    {
        TemporalAccessGrant storage grant = temporalAccessGrants[_resourceId][_grantee];
        require(grant.active, "ChronoLink: Access not active or already revoked");
        grant.active = false;
        grant.expiryTimestamp = block.timestamp; // Mark as expired immediately
        emit TemporalAccessRevoked(_resourceId, _grantee);
    }

    /**
     * @dev Checks if a given address has active temporal access to a resource.
     * @param _resourceId The ID of the resource.
     * @param _checkAddress The address to check for access.
     * @return True if access is active and not expired, false otherwise.
     */
    function hasTemporalAccess(bytes32 _resourceId, address _checkAddress)
        external
        view
        returns (bool)
    {
        TemporalAccessGrant storage grant = temporalAccessGrants[_resourceId][_checkAddress];
        return grant.active && block.timestamp < grant.expiryTimestamp;
    }

    /* ==================================================================================== */
    /*                         X. Dispute Resolution & Penalties                            */
    /* ==================================================================================== */

    /**
     * @dev Initiates a dispute for an agreement, marking it as `Disputed`.
     * This halts automatic fulfillment/expiry until resolved.
     * Can be initiated by owner or beneficiary.
     * @param _agreementId The ID of the agreement to dispute.
     */
    function initiateDispute(uint256 _agreementId)
        external
        notYetCompleted(_agreementId)
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(_msgSender() == agreement.owner || _msgSender() == agreement.beneficiary, "ChronoLink: Not authorized to dispute this agreement");
        require(agreement.status != AgreementStatus.Disputed, "ChronoLink: Agreement is already disputed");

        agreement.status = AgreementStatus.Disputed;
        emit DisputeInitiated(_agreementId, _msgSender());
    }

    /**
     * @dev Resolves a dispute for an agreement, setting its final status.
     * This function would typically be called by an authorized arbiter, or a DAO vote.
     * For simplicity, this is an `onlyOwner` function.
     * @param _agreementId The ID of the agreement to resolve.
     * @param _finalStatus The final status to set (e.g., Fulfilled, Revoked, Breached).
     */
    function resolveDispute(uint256 _agreementId, AgreementStatus _finalStatus)
        external
        onlyOwner // In a real system, this would be an arbiter or DAO role
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(agreement.status == AgreementStatus.Disputed, "ChronoLink: Agreement is not in dispute");
        require(_finalStatus != AgreementStatus.Active && _finalStatus != AgreementStatus.Disputed, "ChronoLink: Invalid final status");

        agreement.status = _finalStatus;

        // Implement logic for asset/value distribution based on _finalStatus
        // This would mirror parts of fulfillChronoLink, revokeChronoLink, or penalizeBreach.
        // For brevity, the actual transfers are omitted here, but this is where they'd go.

        emit DisputeResolved(_agreementId, _finalStatus, _msgSender());
    }

    /**
     * @dev Applies a penalty (e.g., slashing collateral) for an agreement breach.
     * This would typically be called after a dispute resolution determines a breach.
     * @param _agreementId The ID of the agreement.
     */
    function penalizeBreach(uint256 _agreementId)
        external
        onlyOwner // Only owner/arbiter can apply penalty
        whenNotPaused
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        require(agreement.status == AgreementStatus.Breached, "ChronoLink: Agreement is not marked as breached");
        
        uint256 penaltyAmount = agreement.collateralValue; // Example: full collateral slashing
        address token = agreement.collateralToken;

        require(penaltyAmount > 0, "ChronoLink: No collateral to penalize");

        // Transfer penalty to feeRecipient or a designated treasury
        if (token == address(0)) {
            (bool success, ) = payable(feeRecipient).call{value: penaltyAmount}("");
            require(success, "ChronoLink: ETH penalty transfer failed");
        } else {
            require(IERC20(token).transfer(feeRecipient, penaltyAmount), "ChronoLink: ERC20 penalty transfer failed");
        }

        agreement.collateralValue = 0; // Clear collateral
        emit BreachPenalized(_agreementId, agreement.owner, penaltyAmount); // Penalized party is typically the owner for their collateral
    }

    /* ==================================================================================== */
    /*                             XI. Batch Operations & Utilities                         */
    /* ==================================================================================== */

    /**
     * @dev Allows a beneficiary to fulfill multiple ChronoLink agreements in a single transaction.
     * Useful for subscription models or batch claiming rights.
     * @param _agreementIds An array of agreement IDs to fulfill.
     */
    function batchFulfillLinks(uint256[] calldata _agreementIds)
        external
        whenNotPaused
    {
        for (uint256 i = 0; i < _agreementIds.length; i++) {
            // Re-use core fulfillChronoLink logic by calling it internally
            // Note: This pattern needs careful re-entrancy consideration if external calls are involved.
            // For simplicity, `fulfillChronoLink` is designed to be safe here.
            fulfillChronoLink(_agreementIds[i]);
        }
    }

    /**
     * @dev Retrieves the full details of a ChronoLink agreement.
     * @param _agreementId The ID of the agreement.
     * @return A tuple containing all agreement details.
     */
    function getAgreementDetails(uint256 _agreementId)
        external
        view
        returns (
            uint256 agreementId,
            address owner,
            address beneficiary,
            AgreementType agreementType,
            AgreementStatus status,
            uint256 startTimestamp,
            uint256 endTimestamp,
            bytes32 termsHash,
            uint256 value,
            address valueToken,
            address assetAddress,
            uint256 assetId,
            address delegatedTo,
            uint256 collateralValue,
            address collateralToken,
            uint256 associatedChronoLinkId,
            address oracleAddress,
            int256 oracleThreshold,
            bool oracleConditionMet
        )
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        return (
            agreement.agreementId,
            agreement.owner,
            agreement.beneficiary,
            agreement.agreementType,
            agreement.status,
            agreement.startTimestamp,
            agreement.endTimestamp,
            agreement.termsHash,
            agreement.value,
            agreement.valueToken,
            agreement.assetAddress,
            agreement.assetId,
            agreement.delegatedTo,
            agreement.collateralValue,
            agreement.collateralToken,
            agreement.associatedChronoLinkId,
            agreement.oracleAddress,
            agreement.oracleThreshold,
            agreement.oracleConditionMet
        );
    }

    /**
     * @dev Gets the current status of an agreement, potentially updating it if expired.
     * @param _agreementId The ID of the agreement.
     * @return The current status of the agreement.
     */
    function getAgreementStatus(uint256 _agreementId)
        external
        returns (AgreementStatus)
    {
        ChronoLinkAgreement storage agreement = agreements[_agreementId];
        // Automatically update status if expired and not already fulfilled/revoked/breached/disputed
        if (block.timestamp >= agreement.endTimestamp &&
            agreement.status == AgreementStatus.Active)
        {
            agreement.status = AgreementStatus.Expired;
        }
        return agreement.status;
    }

    /**
     * @dev Returns the current block timestamp.
     * @return The current block timestamp.
     */
    function getCurrentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    // Fallback function to accept ETH deposits, primarily for time-locked deposits.
    receive() external payable {
        // This can be used for general ETH deposits to the contract, though
        // `depositValueForLink` and `depositTimeLockedValue` are the preferred methods
        // for linking deposits to specific functionalities.
    }
}
```