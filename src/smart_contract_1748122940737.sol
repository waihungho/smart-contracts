Okay, here is a Solidity smart contract for a Decentralized AI Model and Data Marketplace. This concept is modern, incorporates advanced elements like staking, oracle interaction (simulated), reputation, and dispute resolution, and requires managing different types of digital assets and interactions. It aims to go beyond basic token transfers or simple escrow.

It includes over 20 distinct external/public functions covering listing, staking, requesting services, handling results (via oracle), payments, disputes, and administrative controls.

**Concept:**

A marketplace where:
*   **Model Providers** list AI models (referenced by metadata/hash).
*   **Data Providers** list datasets (referenced by metadata/hash).
*   **Users** pay to execute models or access datasets.
*   Providers stake tokens to ensure reliability.
*   Results/access confirmations are submitted via a trusted Oracle/Provider.
*   Disputes can be initiated and resolved by a Dispute Resolver.
*   Platform fees are collected.
*   A basic reputation (rating) system exists.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- CONTRACT OUTLINE ---
// 1. State Variables & Constants
// 2. Enums & Structs
// 3. Events
// 4. Modifiers (Custom)
// 5. Constructor
// 6. Access Control & Pausability (Inherited & Custom)
// 7. Platform Configuration (Admin)
// 8. Allowed Payment Tokens (Admin)
// 9. Service Management (Model/Dataset Listing)
// 10. Staking Management (Provider)
// 11. Service Request & Execution (User & Oracle/Provider)
// 12. Payments & Earnings Claiming (Provider & Admin)
// 13. Reputation & Feedback (User)
// 14. Dispute Resolution (User, Provider, Dispute Resolver)
// 15. View Functions (Querying Data)

// --- FUNCTION SUMMARY ---

// 6. Access Control & Pausability (Inherited & Custom)
// - pauseContract(): Pauses contract interactions (Owner).
// - unpauseContract(): Unpauses contract interactions (Owner).

// 7. Platform Configuration (Admin)
// - setPlatformFeePercentage(uint16 _feePercentage): Sets the platform fee percentage (Owner).
// - setFeeRecipient(address _feeRecipient): Sets the address receiving platform fees (Owner).
// - setDisputeResolverAddress(address _disputeResolver): Sets the address authorized to resolve disputes (Owner).
// - setMinimumStakeAmount(uint256 _minStake): Sets the minimum staking amount for services (Owner).

// 8. Allowed Payment Tokens (Admin)
// - addAllowedPaymentToken(address _tokenAddress): Adds an ERC20 token to the list of accepted payment tokens (Owner).
// - removeAllowedPaymentToken(address _tokenAddress): Removes an ERC20 token from the list of accepted payment tokens (Owner).
// - isAllowedPaymentToken(address _tokenAddress): Checks if a token is allowed (View).

// 9. Service Management (Model/Dataset Listing)
// - listService(ServiceType _serviceType, string memory _name, string memory _description, string memory _metadataURI, bytes32 _serviceHash, uint256 _cost, uint256 _requiredStake, address _paymentToken): Lists a new service (Model or Dataset) on the marketplace (Callable by anyone, typically providers).
// - updateServiceDetails(bytes32 _serviceId, string memory _description, string memory _metadataURI, uint256 _cost, uint256 _requiredStake, bool _isActive): Updates details of an existing service (Service Provider).
// - retireService(bytes32 _serviceId): Marks a service as inactive, preventing new requests (Service Provider).
// - transferServiceOwnership(bytes32 _serviceId, address _newOwner): Transfers ownership of a service listing (Current Service Owner).

// 10. Staking Management (Provider)
// - stakeForService(bytes32 _serviceId, uint256 _amount): Stakes tokens for a specific service to meet its required stake (Service Provider). Requires _amount of required payment token.
// - unstakeFromService(bytes32 _serviceId, uint256 _amount): Initiates the process to unstake tokens (Service Provider). May have conditions/delays.
// - claimUnstakedFunds(bytes32 _serviceId): Completes the unstaking process after any lockup/delay (Service Provider). (Implementation detail: Simple unstake here, no delay).

// 11. Service Request & Execution (User & Oracle/Provider)
// - requestServiceAccess(bytes32 _serviceId, bytes32 _inputHash, address _paymentToken, uint256 _amount): User requests access (execution for model, access grant for dataset) to a service. Transfers payment (User).
// - submitServiceResult(uint256 _requestId, bytes32 _resultHash, bool _success): Called by the Service Provider/Oracle to submit the outcome of a service request (Service Provider of the service corresponding to request ID).
// - getUserRequests(address _user): Get list of request IDs for a user (View).
// - getServiceRequestDetails(uint256 _requestId): Get details of a specific service request (View).

// 12. Payments & Earnings Claiming (Provider & Admin)
// - claimProviderEarnings(address _tokenAddress): Providers claim accumulated earnings in a specific token (Service Provider).
// - withdrawPlatformFees(address _tokenAddress): Admin claims accumulated platform fees in a specific token (Owner).

// 13. Reputation & Feedback (User)
// - submitFeedback(uint256 _requestId, uint8 _rating, string memory _commentHash): User submits feedback/rating for a completed request (User who made the request). Rating 1-5.
// - getAverageRating(bytes32 _serviceId): Get the average rating for a service (View).
// - getProviderAverageRating(address _provider): Get the average rating for a provider (View).

// 14. Dispute Resolution (User, Provider, Dispute Resolver)
// - initiateDispute(uint256 _requestId, string memory _reasonHash): Initiates a dispute over a service request outcome (User or Service Provider involved in request). Requires a dispute fee/stake (not implemented for simplicity, but crucial in real system).
// - resolveDispute(uint256 _requestId, DisputeResolution _resolution): Called by the Dispute Resolver to finalize a dispute (Dispute Resolver).
// - slashStake(bytes32 _serviceId, uint256 _amount, string memory _reasonHash): Allows Dispute Resolver or Owner to slash provider stake as a penalty (Dispute Resolver or Owner).

// 15. View Functions (Querying Data)
// - getServiceDetails(bytes32 _serviceId): Get details of a service (View).
// - getModelDetails(bytes32 _serviceId): Get model-specific details (View).
// - getDatasetDetails(bytes32 _serviceId): Get dataset-specific details (View).
// - listProviderServices(address _provider): Get list of service IDs for a provider (View).
// - getProviderStake(address _provider, bytes32 _serviceId): Get stake amount for a provider on a service (View).
// - getProviderEarnings(address _provider, address _tokenAddress): Get unclaimed earnings for a provider in a token (View).
// - getPlatformMetrics(): Get platform fee percentage, recipient, min stake, dispute resolver (View).
// - getAllServices(): Get list of all service IDs (View - potentially large, simplified for example).

contract DecentralizedAIModelMarketplace is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- 1. State Variables & Constants ---
    uint16 public platformFeePercentage; // Stored as basis points (e.g., 100 = 1%)
    address public feeRecipient;
    address public disputeResolver; // Address authorized to resolve disputes and potentially slash stake
    uint256 public minimumStakeAmount; // Minimum stake required for any service listing

    mapping(address => bool) public allowedPaymentTokens;
    mapping(address => mapping(address => uint256)) private platformCollectedFees; // tokenAddress => amount

    mapping(bytes32 => Service) public services;
    mapping(bytes32 => ModelDetails) public modelDetails;
    mapping(bytes32 => DatasetDetails) public datasetDetails;
    bytes32[] public serviceIds; // List of all service IDs (simplified, consider pagination for many services)

    mapping(address => bytes32[]) public providerServiceIds; // Provider address => list of their service IDs

    Counters.Counter private _requestIds;
    mapping(uint256 => ServiceRequest) public serviceRequests;
    mapping(address => uint256[]) public userRequests; // User address => list of request IDs

    mapping(address => mapping(bytes32 => uint256)) public providerStakes; // provider address => serviceId => staked amount

    mapping(address => mapping(address => uint256)) private providerEarnings; // provider address => tokenAddress => amount

    mapping(bytes32 => uint256[]) private serviceRatings; // serviceId => list of ratings (1-5)
    mapping(address => uint256[]) private providerRatings; // provider address => list of ratings (1-5)

    mapping(uint256 => Dispute) public disputes; // requestId => Dispute details

    // --- 2. Enums & Structs ---
    enum ServiceType { Unknown, Model, Dataset }
    enum RequestStatus { Pending, ExecutingOrAccessing, CompletedSuccess, CompletedFailure, Disputed }
    enum DisputeStatus { NoDispute, Initiated, ResolvedSuccessForRequester, ResolvedSuccessForProvider, ResolvedCancelled }
    enum DisputeResolution { SuccessForRequester, SuccessForProvider, Cancelled }

    struct Service {
        bytes32 id;
        address provider;
        ServiceType serviceType;
        string name;
        string description;
        string metadataURI; // Link to external metadata
        uint256 cost; // Cost per request in the payment token
        uint256 requiredStake; // Required stake in the payment token
        address paymentToken; // Specific token required for this service
        bool isActive; // Can be requested if active
        bool exists; // To check if a serviceId is valid
    }

    struct ModelDetails {
        bytes32 modelHash; // IPFS hash or identifier for the model logic/executable
        // Add more model-specific fields if needed (e.g., input/output specs hash)
    }

    struct DatasetDetails {
        bytes32 dataHash; // IPFS hash or identifier for the dataset
        // Add more dataset-specific fields if needed (e.g., sample hash, size info)
    }

    struct ServiceRequest {
        uint256 id;
        bytes32 serviceId;
        address user;
        address provider; // Stored for convenience
        address paymentToken; // Stored for convenience
        uint256 amountPaid;
        bytes32 inputHash; // Hash or identifier for the user's input data
        bytes32 resultHash; // Hash or identifier for the execution result (for models)
        bool accessGranted; // Whether data access was confirmed (for datasets)
        RequestStatus status;
        uint256 timestamp;
    }

    struct Feedback {
        uint8 rating; // 1-5
        string commentHash; // IPFS hash of the comment
        uint256 requestId;
        address submitter;
    }

    struct Dispute {
        uint256 requestId;
        address initiator;
        string reasonHash; // IPFS hash of the dispute reason
        DisputeStatus status;
        uint256 initiatedTimestamp;
        // Potentially add stake related to dispute
    }

    // --- 3. Events ---
    event PlatformFeePercentageUpdated(uint16 oldPercentage, uint16 newPercentage);
    event FeeRecipientUpdated(address oldRecipient, address newRecipient);
    event DisputeResolverUpdated(address oldResolver, address newResolver);
    event MinimumStakeAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event AllowedPaymentTokenAdded(address tokenAddress);
    event AllowedPaymentTokenRemoved(address tokenAddress);

    event ServiceListed(bytes32 serviceId, address provider, ServiceType serviceType, address paymentToken, uint256 cost, uint256 requiredStake);
    event ServiceUpdated(bytes32 serviceId, address provider, uint256 newCost, uint256 newRequiredStake, bool isActive);
    event ServiceRetired(bytes32 serviceId, address provider);
    event ServiceOwnershipTransferred(bytes32 serviceId, address oldOwner, address newOwner);

    event ServiceStaked(bytes32 serviceId, address provider, uint256 amount, address tokenAddress);
    event ServiceUnstaked(bytes32 serviceId, address provider, uint256 amount, address tokenAddress);

    event ServiceRequestCreated(uint256 requestId, bytes32 serviceId, address user, address paymentToken, uint256 amountPaid, bytes32 inputHash);
    event ServiceResultSubmitted(uint256 requestId, bytes32 resultHash, bool success);
    event DatasetAccessConfirmed(uint256 requestId);

    event ProviderEarningsClaimed(address provider, address tokenAddress, uint256 amount);
    event PlatformFeesClaimed(address recipient, address tokenAddress, uint256 amount);

    event FeedbackSubmitted(uint256 requestId, address submitter, uint8 rating);

    event DisputeInitiated(uint256 requestId, address initiator, string reasonHash);
    event DisputeResolved(uint256 requestId, DisputeResolution resolution);
    event StakeSlashed(bytes32 serviceId, address provider, uint256 amount, string reasonHash);

    // --- 4. Modifiers (Custom) ---
    modifier onlyDisputeResolver() {
        require(msg.sender == disputeResolver, "Not dispute resolver");
        _;
    }

    modifier serviceExists(bytes32 _serviceId) {
        require(services[_serviceId].exists, "Service does not exist");
        _;
    }

    modifier requestExists(uint256 _requestId) {
        require(serviceRequests[_requestId].user != address(0), "Request does not exist");
        _;
    }

    modifier isServiceProvider(bytes32 _serviceId) {
        require(services[_serviceId].provider == msg.sender, "Not service provider");
        _;
    }

    modifier isRequestProvider(uint256 _requestId) {
        require(serviceRequests[_requestId].provider == msg.sender, "Not request provider");
        _;
    }

     modifier isRequestUser(uint256 _requestId) {
        require(serviceRequests[_requestId].user == msg.sender, "Not request user");
        _;
    }

    // --- 5. Constructor ---
    constructor(address _feeRecipient, address _disputeResolver, uint16 _initialFeePercentage, uint256 _minimumStake) Ownable(msg.sender) Pausable(false) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_disputeResolver != address(0), "Invalid dispute resolver");
        require(_initialFeePercentage <= 10000, "Fee percentage > 100%"); // 10000 basis points = 100%

        feeRecipient = _feeRecipient;
        disputeResolver = _disputeResolver;
        platformFeePercentage = _initialFeePercentage;
        minimumStakeAmount = _minimumStake;
    }

    // --- 6. Access Control & Pausability (Inherited & Custom) ---
    // pause() and unpause() inherited from Pausable

    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    // transferOwnership() inherited from Ownable

    // --- 7. Platform Configuration (Admin) ---

    /**
     * @notice Sets the percentage of service costs collected as platform fees.
     * @param _feePercentage The new fee percentage in basis points (e.g., 100 for 1%). Max 10000.
     */
    function setPlatformFeePercentage(uint16 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100%");
        emit PlatformFeePercentageUpdated(platformFeePercentage, _feePercentage);
        platformFeePercentage = _feePercentage;
    }

    /**
     * @notice Sets the address where platform fees are sent.
     * @param _feeRecipient The new address for collecting fees.
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient address");
        emit FeeRecipientUpdated(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Sets the address authorized to resolve disputes and slash stake.
     * @param _disputeResolver The new dispute resolver address.
     */
    function setDisputeResolverAddress(address _disputeResolver) external onlyOwner {
        require(_disputeResolver != address(0), "Invalid dispute resolver address");
        emit DisputeResolverUpdated(disputeResolver, _disputeResolver);
        disputeResolver = _disputeResolver;
    }

     /**
     * @notice Sets the minimum required stake amount for providers to list services.
     * @param _minStake The new minimum stake amount.
     */
    function setMinimumStakeAmount(uint256 _minStake) external onlyOwner {
        emit MinimumStakeAmountUpdated(minimumStakeAmount, _minStake);
        minimumStakeAmount = _minStake;
    }

    // --- 8. Allowed Payment Tokens (Admin) ---

    /**
     * @notice Adds an ERC20 token to the list of accepted payment tokens.
     * @param _tokenAddress The address of the ERC20 token to add.
     */
    function addAllowedPaymentToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        require(!allowedPaymentTokens[_tokenAddress], "Token already allowed");
        // Optional: Check if it's a valid ERC20 by calling a view function? Riskier as some tokens might revert. Trust owner input for this example.
        allowedPaymentTokens[_tokenAddress] = true;
        emit AllowedPaymentTokenAdded(_tokenAddress);
    }

    /**
     * @notice Removes an ERC20 token from the list of accepted payment tokens.
     * @param _tokenAddress The address of the ERC20 token to remove.
     */
    function removeAllowedPaymentToken(address _tokenAddress) external onlyOwner {
        require(allowedPaymentTokens[_tokenAddress], "Token not allowed");
        allowedPaymentTokens[_tokenAddress] = false;
        emit AllowedPaymentTokenRemoved(_tokenAddress);
    }

    /**
     * @notice Checks if a token is currently allowed as a payment token.
     * @param _tokenAddress The address of the token to check.
     * @return bool True if allowed, false otherwise.
     */
    function isAllowedPaymentToken(address _tokenAddress) external view returns (bool) {
        return allowedPaymentTokens[_tokenAddress];
    }

    // --- 9. Service Management (Model/Dataset Listing) ---

    /**
     * @notice Lists a new AI model or dataset on the marketplace.
     * Provider must have already approved this contract to spend the required stake amount of the payment token.
     * @param _serviceType The type of service being listed (Model or Dataset).
     * @param _name The name of the service.
     * @param _description A brief description.
     * @param _metadataURI URI pointing to detailed metadata (e.g., IPFS).
     * @param _serviceHash A unique hash or identifier for the model/dataset logic/data.
     * @param _cost The cost per execution/access request in the payment token.
     * @param _requiredStake The required stake amount for this service in the payment token.
     * @param _paymentToken The ERC20 token address accepted for payment and staking for this service.
     */
    function listService(
        ServiceType _serviceType,
        string memory _name,
        string memory _description,
        string memory _metadataURI,
        bytes32 _serviceHash,
        uint256 _cost,
        uint256 _requiredStake,
        address _paymentToken
    ) external whenNotPaused nonReentrant returns (bytes32 serviceId) {
        require(_serviceType == ServiceType.Model || _serviceType == ServiceType.Dataset, "Invalid service type");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty");
        require(_paymentToken != address(0) && allowedPaymentTokens[_paymentToken], "Invalid or disallowed payment token");
        require(_requiredStake >= minimumStakeAmount, "Required stake below minimum");

        // Generate a unique service ID based on provider, name, and type
        serviceId = keccak256(abi.encodePacked(msg.sender, _name, uint8(_serviceType), block.timestamp));
        require(!services[serviceId].exists, "Service ID collision, try again"); // Highly unlikely

        services[serviceId] = Service({
            id: serviceId,
            provider: msg.sender,
            serviceType: _serviceType,
            name: _name,
            description: _description,
            metadataURI: _metadataURI,
            cost: _cost,
            requiredStake: _requiredStake,
            paymentToken: _paymentToken,
            isActive: true,
            exists: true
        });

        if (_serviceType == ServiceType.Model) {
            modelDetails[serviceId] = ModelDetails({ modelHash: _serviceHash });
        } else { // ServiceType.Dataset
            datasetDetails[serviceId] = DatasetDetails({ dataHash: _serviceHash });
        }

        providerServiceIds[msg.sender].push(serviceId);
        serviceIds.push(serviceId); // Add to global list

        emit ServiceListed(serviceId, msg.sender, _serviceType, _paymentToken, _cost, _requiredStake);
    }

    /**
     * @notice Updates the details of an existing service.
     * @param _serviceId The ID of the service to update.
     * @param _description The new description.
     * @param _metadataURI The new metadata URI.
     * @param _cost The new cost per request.
     * @param _requiredStake The new required stake amount.
     * @param _isActive The new active status.
     */
    function updateServiceDetails(
        bytes32 _serviceId,
        string memory _description,
        string memory _metadataURI,
        uint256 _cost,
        uint256 _requiredStake,
        bool _isActive
    ) external whenNotPaused serviceExists(_serviceId) isServiceProvider(_serviceId) {
        Service storage service = services[_serviceId];
        require(_requiredStake >= minimumStakeAmount, "Required stake below minimum");

        service.description = _description;
        service.metadataURI = _metadataURI;
        service.cost = _cost;
        service.requiredStake = _requiredStake;
        service.isActive = _isActive;

        emit ServiceUpdated(_serviceId, msg.sender, _cost, _requiredStake, _isActive);
    }

    /**
     * @notice Marks a service as inactive, preventing new requests.
     * Existing requests can still be processed.
     * @param _serviceId The ID of the service to retire.
     */
    function retireService(bytes32 _serviceId) external whenNotPaused serviceExists(_serviceId) isServiceProvider(_serviceId) {
        services[_serviceId].isActive = false;
        emit ServiceRetired(_serviceId, msg.sender);
    }

    /**
     * @notice Transfers ownership of a service listing to another address.
     * @param _serviceId The ID of the service.
     * @param _newOwner The address of the new provider.
     */
    function transferServiceOwnership(bytes32 _serviceId, address _newOwner) external whenNotPaused serviceExists(_serviceId) isServiceProvider(_serviceId) {
        require(_newOwner != address(0), "Invalid new owner address");
        Service storage service = services[_serviceId];
        address oldOwner = service.provider;

        // Remove service from old owner's list (simple implementation, doesn't handle gaps)
        bytes32[] storage oldOwnerServices = providerServiceIds[oldOwner];
        for (uint i = 0; i < oldOwnerServices.length; i++) {
            if (oldOwnerServices[i] == _serviceId) {
                oldOwnerServices[i] = oldOwnerServices[oldOwnerServices.length - 1];
                oldOwnerServices.pop();
                break;
            }
        }

        // Add service to new owner's list
        providerServiceIds[_newOwner].push(_serviceId);
        service.provider = _newOwner;

        emit ServiceOwnershipTransferred(_serviceId, oldOwner, _newOwner);
    }


    // --- 10. Staking Management (Provider) ---

    /**
     * @notice Stakes tokens for a specific service listing.
     * The provider must have approved this contract to spend the tokens first.
     * @param _serviceId The ID of the service to stake for.
     * @param _amount The amount of tokens to stake.
     */
    function stakeForService(bytes32 _serviceId, uint256 _amount) external whenNotPaused nonReentrant serviceExists(_serviceId) isServiceProvider(_serviceId) {
        Service storage service = services[_serviceId];
        require(_amount > 0, "Stake amount must be greater than 0");
        // Check if staking this amount meets or exceeds required stake IF current stake is below requirement
        // require(providerStakes[msg.sender][_serviceId] + _amount >= service.requiredStake, "Staking amount doesn't meet requirement"); // Optional, can allow partial staking below min

        IERC20 token = IERC20(service.paymentToken);
        token.safeTransferFrom(msg.sender, address(this), _amount);

        providerStakes[msg.sender][_serviceId] += _amount;

        emit ServiceStaked(_serviceId, msg.sender, _amount, service.paymentToken);
    }

    /**
     * @notice Initiates the process to unstake tokens from a service.
     * Note: A real system might include a lock-up period or conditions based on active requests/disputes.
     * This implementation is simplified and allows immediate unstaking if stake remains >= requiredStake.
     * Full unstaking is only allowed if service is retired or no active requests.
     * @param _serviceId The ID of the service to unstake from.
     * @param _amount The amount to unstake.
     */
    function unstakeFromService(bytes32 _serviceId, uint256 _amount) external whenNotPaused nonReentrant serviceExists(_serviceId) isServiceProvider(_serviceId) {
        Service storage service = services[_serviceId];
        uint256 currentStake = providerStakes[msg.sender][_serviceId];
        require(_amount > 0 && _amount <= currentStake, "Invalid unstake amount");

        // Prevent unstaking below required stake unless service is retired
        if (service.isActive) {
             require(currentStake - _amount >= service.requiredStake, "Cannot unstake below required stake for active service");
        } else {
            // If service is retired, allow full unstake IF no active requests/disputes... (simplified check here)
            // In a real system, you'd track outstanding requests for this service
            // For simplicity, we allow full unstake from retired service if amount is max staked amount
             if (currentStake - _amount < service.requiredStake && _amount < currentStake) {
                 revert("Cannot partial unstake below required stake on inactive service");
             }
        }

        providerStakes[msg.sender][_serviceId] -= _amount;

        IERC20 token = IERC20(service.paymentToken);
        token.safeTransfer(msg.sender, _amount); // Transfer funds back immediately (simplification)

        emit ServiceUnstaked(_serviceId, msg.sender, _amount, service.paymentToken);
    }

    // --- 11. Service Request & Execution (User & Oracle/Provider) ---

    /**
     * @notice User requests access (execution for model, access grant for dataset) to a service.
     * User must have approved this contract to spend the cost amount of the payment token.
     * @param _serviceId The ID of the service to request.
     * @param _inputHash Hash or identifier for the user's input data (if applicable).
     * @param _paymentToken The token used for payment (must match service's required payment token).
     * @param _amount The amount of tokens sent (must equal service cost).
     */
    function requestServiceAccess(
        bytes32 _serviceId,
        bytes32 _inputHash,
        address _paymentToken,
        uint256 _amount
    ) external whenNotPaused nonReentrant serviceExists(_serviceId) returns (uint256 requestId) {
        Service storage service = services[_serviceId];
        require(service.isActive, "Service is not active");
        require(service.paymentToken == _paymentToken, "Incorrect payment token for service");
        require(service.cost == _amount, "Incorrect payment amount");
        require(providerStakes[service.provider][_serviceId] >= service.requiredStake, "Service provider does not meet stake requirement");

        IERC20 token = IERC20(_paymentToken);
        token.safeTransferFrom(msg.sender, address(this), _amount); // Pull tokens from user

        uint256 platformFee = (_amount * platformFeePercentage) / 10000;
        uint256 providerEarning = _amount - platformFee;

        // Record fees/earnings internally
        platformCollectedFees[_paymentToken] += platformFee;
        providerEarnings[service.provider][_paymentToken] += providerEarning;

        requestId = _requestIds.current();
        serviceRequests[requestId] = ServiceRequest({
            id: requestId,
            serviceId: _serviceId,
            user: msg.sender,
            provider: service.provider,
            paymentToken: _paymentToken,
            amountPaid: _amount,
            inputHash: _inputHash,
            resultHash: bytes32(0), // To be filled by provider/oracle
            accessGranted: false,   // To be filled by provider/oracle
            status: RequestStatus.ExecutingOrAccessing, // State waiting for provider action
            timestamp: block.timestamp
        });
        _requestIds.increment();

        userRequests[msg.sender].push(requestId);

        emit ServiceRequestCreated(requestId, _serviceId, msg.sender, _paymentToken, _amount, _inputHash);

        // Note: Off-chain system should listen for this event to trigger execution/access grant
    }

    /**
     * @notice Called by the Service Provider (or a trusted Oracle/Automation tied to them)
     * to submit the result hash for a model execution or confirm data access grant.
     * Updates the request status.
     * @param _requestId The ID of the request being fulfilled.
     * @param _resultHash Hash or identifier for the execution result (for models). Ignored for datasets.
     * @param _success True if the service execution/access was successful, false otherwise.
     */
    function submitServiceResult(uint256 _requestId, bytes32 _resultHash, bool _success)
        external
        whenNotPaused
        nonReentrant
        requestExists(_requestId)
        isRequestProvider(_requestId) // Only the provider who earned the fee can submit
    {
        ServiceRequest storage request = serviceRequests[_requestId];
        Service storage service = services[request.serviceId];

        require(request.status == RequestStatus.ExecutingOrAccessing, "Request not in Executing/Accessing status");
        require(disputes[_requestId].status == DisputeStatus.NoDispute, "Cannot submit result during dispute");

        if (_success) {
            request.status = RequestStatus.CompletedSuccess;
            if (service.serviceType == ServiceType.Model) {
                 require(_resultHash != bytes32(0), "Result hash cannot be zero for successful model execution");
                 request.resultHash = _resultHash;
                 emit ServiceResultSubmitted(_requestId, _resultHash, true);
            } else if (service.serviceType == ServiceType.Dataset) {
                request.accessGranted = true;
                emit DatasetAccessConfirmed(_requestId);
            }
        } else {
             // Service failed, potentially slash stake or allow dispute
             request.status = RequestStatus.CompletedFailure;
             // Note: A failure might automatically trigger a penalty or require a dispute to claw back user payment/stake
             emit ServiceResultSubmitted(_requestId, bytes33(0), false); // Use 0 hash for failure
        }
    }

    // --- 12. Payments & Earnings Claiming (Provider & Admin) ---

    /**
     * @notice Allows a service provider to claim their accumulated earnings in a specific token.
     * @param _tokenAddress The address of the token to claim earnings in.
     */
    function claimProviderEarnings(address _tokenAddress) external whenNotPaused nonReentrant {
        require(_tokenAddress != address(0) && allowedPaymentTokens[_tokenAddress], "Invalid or disallowed token");
        uint256 amount = providerEarnings[msg.sender][_tokenAddress];
        require(amount > 0, "No earnings to claim");

        providerEarnings[msg.sender][_tokenAddress] = 0;
        IERC20 token = IERC20(_tokenAddress);
        token.safeTransfer(msg.sender, amount);

        emit ProviderEarningsClaimed(msg.sender, _tokenAddress, amount);
    }

    /**
     * @notice Allows the fee recipient to withdraw accumulated platform fees in a specific token.
     * @param _tokenAddress The address of the token to withdraw fees in.
     */
    function withdrawPlatformFees(address _tokenAddress) external whenNotPaused nonReentrant {
        require(msg.sender == feeRecipient || msg.sender == owner(), "Only fee recipient or owner can withdraw fees");
        require(_tokenAddress != address(0) && allowedPaymentTokens[_tokenAddress], "Invalid or disallowed token");

        uint256 amount = platformCollectedFees[_tokenAddress];
        require(amount > 0, "No fees to withdraw");

        platformCollectedFees[_tokenAddress] = 0;
        IERC20 token = IERC20(_tokenAddress);
        token.safeTransfer(msg.sender, amount);

        emit PlatformFeesClaimed(msg.sender, _tokenAddress, amount);
    }

    // --- 13. Reputation & Feedback (User) ---

    /**
     * @notice Allows the user who made a request to submit feedback (rating) for the service/provider.
     * Can only be submitted after the request is completed (success or failure) and not under dispute.
     * @param _requestId The ID of the completed request.
     * @param _rating The rating (1-5).
     * @param _commentHash IPFS hash or identifier for the comment text.
     */
    function submitFeedback(uint256 _requestId, uint8 _rating, string memory _commentHash) external whenNotPaused requestExists(_requestId) isRequestUser(_requestId) {
        ServiceRequest storage request = serviceRequests[_requestId];
        require(request.status == RequestStatus.CompletedSuccess || request.status == RequestStatus.CompletedFailure, "Request not completed");
        require(disputes[_requestId].status == DisputeStatus.NoDispute, "Cannot submit feedback during a dispute");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        // Prevent multiple feedbacks for the same request (simplified check - could use a mapping)
        // For this example, we allow submitting feedback once.

        serviceRatings[request.serviceId].push(_rating);
        providerRatings[request.provider].push(_rating);

        // Store feedback details if needed, maybe in a separate mapping keyed by requestId
        // feedbacks[_requestId] = Feedback({ rating: _rating, commentHash: _commentHash, requestId: _requestId, submitter: msg.sender });

        emit FeedbackSubmitted(_requestId, msg.sender, _rating);
    }

     /**
     * @notice Calculates the average rating for a service.
     * @param _serviceId The ID of the service.
     * @return uint256 The average rating (multiplied by 100 to retain two decimal places), or 0 if no ratings.
     */
    function getAverageRating(bytes32 _serviceId) external view serviceExists(_serviceId) returns (uint256) {
        uint256[] storage ratings = serviceRatings[_serviceId];
        if (ratings.length == 0) {
            return 0;
        }
        uint256 totalRating = 0;
        for (uint i = 0; i < ratings.length; i++) {
            totalRating += ratings[i];
        }
        // Return average * 100 to keep precision
        return (totalRating * 100) / ratings.length;
    }

    /**
     * @notice Calculates the average rating for a provider across all their services.
     * @param _provider The address of the provider.
     * @return uint256 The average rating (multiplied by 100), or 0 if no ratings.
     */
    function getProviderAverageRating(address _provider) external view returns (uint256) {
         uint256[] storage ratings = providerRatings[_provider];
        if (ratings.length == 0) {
            return 0;
        }
        uint256 totalRating = 0;
        for (uint i = 0; i < ratings.length; i++) {
            totalRating += ratings[i];
        }
        // Return average * 100 to keep precision
        return (totalRating * 100) / ratings.length;
    }

    // --- 14. Dispute Resolution (User, Provider, Dispute Resolver) ---

    /**
     * @notice Initiates a dispute for a completed service request.
     * Can be called by the user or the provider involved in the request.
     * @param _requestId The ID of the completed request to dispute.
     * @param _reasonHash IPFS hash or identifier of the reason for the dispute.
     */
    function initiateDispute(uint256 _requestId, string memory _reasonHash) external whenNotPaused requestExists(_requestId) {
        ServiceRequest storage request = serviceRequests[_requestId];
        require(msg.sender == request.user || msg.sender == request.provider, "Not involved in this request");
        require(request.status == RequestStatus.CompletedSuccess || request.status == RequestStatus.CompletedFailure, "Request not in a completed state");
        require(disputes[_requestId].status == DisputeStatus.NoDispute, "Dispute already initiated for this request");
        require(bytes(_reasonHash).length > 0, "Reason hash cannot be empty");

        // A real system would require staking a dispute fee here
        // IERC20 disputeToken = IERC20(settings.disputeToken); // Example
        // disputeToken.safeTransferFrom(msg.sender, address(this), settings.disputeFee);

        disputes[_requestId] = Dispute({
            requestId: _requestId,
            initiator: msg.sender,
            reasonHash: _reasonHash,
            status: DisputeStatus.Initiated,
            initiatedTimestamp: block.timestamp
        });

        // Optionally change request status to Disputed
        // request.status = RequestStatus.Disputed; // If you want requests to show 'Disputed' state

        emit DisputeInitiated(_requestId, msg.sender, _reasonHash);
    }

    /**
     * @notice Called by the Dispute Resolver to resolve a dispute.
     * Determines the final outcome and handles potential stake slashing or refunding.
     * @param _requestId The ID of the request with an ongoing dispute.
     * @param _resolution The resolution outcome (SuccessForRequester, SuccessForProvider, Cancelled).
     */
    function resolveDispute(uint256 _requestId, DisputeResolution _resolution) external whenNotPaused nonReentrant requestExists(_requestId) onlyDisputeResolver {
        Dispute storage dispute = disputes[_requestId];
        require(dispute.status == DisputeStatus.Initiated, "No active dispute for this request");

        ServiceRequest storage request = serviceRequests[_requestId];
        Service storage service = services[request.serviceId];

        // --- Implement resolution logic ---
        // This logic is simplified. A real system needs complex rules:
        // - If SuccessForRequester (e.g., model failed, data not provided):
        //   - User gets refund of request cost from Provider's stake or earnings.
        //   - Provider stake might be slashed.
        //   - Dispute initiator might get dispute fee back.
        // - If SuccessForProvider (e.g., user dispute invalid):
        //   - Provider keeps earnings.
        //   - User (if initiator) loses dispute fee/stake.
        // - If Cancelled:
        //   - Fees/Stakes returned to initiators.

        // For this example, we'll just update dispute status and potentially revert request status.
        // NO token transfers or stake slashing implemented directly here for simplicity.

        if (_resolution == DisputeResolution.SuccessForRequester) {
            dispute.status = DisputeStatus.ResolvedSuccessForRequester;
             // In a real system:
             // - Transfer request.amountPaid from provider to user.
             // - Potentially slash provider stake.
             // Example (not fully implemented): slashStake(request.serviceId, slashAmount, "Dispute lost");
        } else if (_resolution == DisputeResolution.SuccessForProvider) {
            dispute.status = DisputeStatus.ResolvedSuccessForProvider;
             // In a real system:
             // - Provider keeps earnings.
             // - User (if initiator) loses dispute stake.
        } else if (_resolution == DisputeResolution.Cancelled) {
             dispute.status = DisputeStatus.ResolvedCancelled;
             // In a real system:
             // - Refund dispute stakes.
        } else {
            revert("Invalid dispute resolution");
        }

        // Optionally revert request status from 'Disputed' if it was changed, or leave it as is.
        // request.status = RequestStatus.CompletedSuccess/Failure based on original outcome? Or add a new 'Resolved' status?

        emit DisputeResolved(_requestId, _resolution);
    }

    /**
     * @notice Allows the Dispute Resolver or Owner to slash a provider's stake as a penalty.
     * Used typically after a dispute resolution or violation.
     * @param _serviceId The ID of the service whose provider's stake is being slashed.
     * @param _amount The amount of tokens to slash.
     * @param _reasonHash IPFS hash or identifier of the reason for slashing.
     */
    function slashStake(bytes32 _serviceId, uint256 _amount, string memory _reasonHash) external whenNotPaused nonReentrant serviceExists(_serviceId) {
        require(msg.sender == disputeResolver || msg.sender == owner(), "Not authorized to slash stake");
        Service storage service = services[_serviceId];
        address provider = service.provider;
        uint256 currentStake = providerStakes[provider][_serviceId];
        require(_amount > 0 && _amount <= currentStake, "Invalid slash amount");

        providerStakes[provider][_serviceId] -= _amount;

        // Slashed amount could be sent to a treasury, burned, or sent to the user who won a dispute.
        // For simplicity, we'll just reduce the stake amount and the tokens remain in the contract.
        // A real system needs a clear destination for slashed funds.

        emit StakeSlashed(_serviceId, provider, _amount, _reasonHash);
    }


    // --- 15. View Functions (Querying Data) ---

    /**
     * @notice Gets the details of a specific service.
     * @param _serviceId The ID of the service.
     * @return Service struct details.
     */
    function getServiceDetails(bytes32 _serviceId) external view serviceExists(_serviceId) returns (Service memory) {
        return services[_serviceId];
    }

    /**
     * @notice Gets the model-specific details for a service.
     * Requires the service to be of type Model.
     * @param _serviceId The ID of the model service.
     * @return ModelDetails struct details.
     */
    function getModelDetails(bytes32 _serviceId) external view serviceExists(_serviceId) returns (ModelDetails memory) {
        require(services[_serviceId].serviceType == ServiceType.Model, "Service is not a Model");
        return modelDetails[_serviceId];
    }

     /**
     * @notice Gets the dataset-specific details for a service.
     * Requires the service to be of type Dataset.
     * @param _serviceId The ID of the dataset service.
     * @return DatasetDetails struct details.
     */
    function getDatasetDetails(bytes32 _serviceId) external view serviceExists(_serviceId) returns (DatasetDetails memory) {
         require(services[_serviceId].serviceType == ServiceType.Dataset, "Service is not a Dataset");
        return datasetDetails[_serviceId];
    }

    /**
     * @notice Gets the list of service IDs offered by a specific provider.
     * @param _provider The address of the provider.
     * @return bytes32[] An array of service IDs.
     */
    function listProviderServices(address _provider) external view returns (bytes32[] memory) {
        return providerServiceIds[_provider];
    }

    /**
     * @notice Gets the current staked amount for a provider on a specific service.
     * @param _provider The address of the provider.
     * @param _serviceId The ID of the service.
     * @return uint256 The staked amount.
     */
    function getProviderStake(address _provider, bytes32 _serviceId) external view returns (uint256) {
        return providerStakes[_provider][_serviceId];
    }

     /**
     * @notice Gets the accumulated, unclaimed earnings for a provider in a specific token.
     * @param _provider The address of the provider.
     * @param _tokenAddress The address of the token.
     * @return uint256 The unclaimed earnings amount.
     */
    function getProviderEarnings(address _provider, address _tokenAddress) external view returns (uint256) {
        return providerEarnings[_provider][_tokenAddress];
    }

    /**
     * @notice Gets the details of a specific service request.
     * @param _requestId The ID of the request.
     * @return ServiceRequest struct details.
     */
    function getServiceRequestDetails(uint256 _requestId) external view requestExists(_requestId) returns (ServiceRequest memory) {
        return serviceRequests[_requestId];
    }

     /**
     * @notice Gets platform configuration metrics.
     * @return uint16 currentPlatformFeePercentage
     * @return address currentFeeRecipient
     * @return address currentDisputeResolver
     * @return uint256 currentMinimumStakeAmount
     */
    function getPlatformMetrics() external view returns (uint16, address, address, uint256) {
        return (platformFeePercentage, feeRecipient, disputeResolver, minimumStakeAmount);
    }

    /**
     * @notice Gets a list of all service IDs listed on the marketplace.
     * Note: For a very large number of services, this might exceed block gas limits.
     * Pagination or filtering in a real application is recommended.
     * @return bytes32[] An array of all service IDs.
     */
    function getAllServices() external view returns (bytes32[] memory) {
        return serviceIds;
    }

    /**
     * @notice Get the list of request IDs made by a user.
     * @param _user The address of the user.
     * @return uint256[] An array of request IDs.
     */
    function getUserRequests(address _user) external view returns (uint256[] memory) {
        return userRequests[_user];
    }

    /**
     * @notice Get the amount of fees collected by the platform for a specific token.
     * @param _tokenAddress The address of the token.
     * @return uint256 The collected amount.
     */
    function getPlatformCollectedFees(address _tokenAddress) external view returns (uint256) {
        return platformCollectedFees[_tokenAddress];
    }

     /**
     * @notice Check the status of a dispute for a given request.
     * @param _requestId The ID of the request.
     * @return DisputeStatus The status of the dispute.
     */
    function getDisputeStatus(uint256 _requestId) external view returns (DisputeStatus) {
        return disputes[_requestId].status;
    }

    // Add more view functions as needed, e.g., get feedback details, get dispute details etc.
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **AI/ML & Data Marketplace:** The core concept is a decentralized marketplace specifically for AI models and datasets. This directly taps into a current technology trend.
2.  **Service Abstraction:** Using `ServiceType` (Model/Dataset) and a base `Service` struct allows for managing different digital assets (models, datasets) under a unified system, enabling features applicable to both (listing, staking, requests, disputes).
3.  **Staking for Reliability:** Providers must stake tokens (`stakeForService`) to list services. This aligns incentives – providers with high stake are expected to be more reliable, and losing stake (`slashStake`) is a penalty for failure or malicious behavior, enforced via the dispute mechanism.
4.  **Oracle/Provider Role for Results:** The `submitServiceResult` function simulates interaction with an off-chain component. The smart contract doesn't *run* the AI or provide the data itself. It relies on the *provider* (or a trusted oracle system managed by the provider) to perform the service off-chain and report the result/confirmation back on-chain. This is a common pattern for integrating real-world computation with smart contracts.
5.  **Payment Splitting & Earnings:** The contract handles payment flows, splitting the cost between the provider's earnings and the platform fee (`requestServiceAccess`). Providers can then claim their accumulated earnings (`claimProviderEarnings`).
6.  **Dispute Resolution:** A mechanism for users or providers to `initiateDispute` is included. A designated `disputeResolver` address (representing a DAO, a set of oracles, or a trusted third party in a more complex system) is empowered to `resolveDispute` and potentially `slashStake`. This adds a layer of trust and accountability beyond simple automated execution.
7.  **Reputation System:** A basic on-chain rating system (`submitFeedback`) is included to allow users to provide feedback, which can be aggregated (`getAverageRating`, `getProviderAverageRating`). While simple here, this is a foundation for more complex decentralized reputation.
8.  **Flexible Payments:** The `allowedPaymentTokens` system allows the platform owner to add support for multiple ERC20 tokens for service payments and staking, rather than being locked into a single native or platform token.
9.  **Access Control Granularity:** Beyond standard `onlyOwner`, it includes `onlyDisputeResolver`, `isServiceProvider`, `isRequestProvider`, `isRequestUser` modifiers for specific permissions.
10. **Pausability & Upgradeability Consideration:** Inheriting `Pausable` is standard but crucial for managing potential issues. While a full proxy upgrade pattern isn't coded here, the structure is compatible, and the `transferServiceOwnership` function adds flexibility for provider changes.
11. **Unique Identifiers:** Using `keccak256` based on specific parameters to generate `serviceId`s helps ensure uniqueness for each listing.
12. **State Tracking:** Detailed structs (`Service`, `ServiceRequest`, `Dispute`) and mappings are used to maintain the complex state of listings, requests, payments, stakes, and disputes on-chain.

This contract structure provides a foundation for a decentralized marketplace focused on computational/data services, incorporating several modern patterns necessary for such a system to function reliably and handle potential disagreements. Remember that this is a simplified example; a production system would require more robust error handling, potentially more detailed dispute logic, gas optimizations, and potentially integration with specific oracle networks (like Chainlink) for dispute outcomes or verified execution results.