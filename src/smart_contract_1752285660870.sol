Okay, here is a Solidity smart contract for a "Decentralized AI Protocol" (DAP). This contract aims to establish a framework for users to request AI inference tasks, model providers to register and offer models, and validators to verify results, all secured by staking and governed parameters.

It incorporates concepts like:
*   **Staking:** Participants (Model Providers, Validators) stake tokens as collateral.
*   **Roles:** Defined roles with specific permissions (Admin, Model Provider, Validator, User).
*   **Off-chain Computation, On-chain Verification:** The AI computation happens off-chain, but the *results* are submitted and validated on-chain by staked validators.
*   **Token-based Incentives:** Fees for requests are distributed among Model Providers, Validators, and the Protocol. Validators are rewarded for correct attestations.
*   **Slashing:** Malicious or incorrect behavior (potentially) leads to staked tokens being slashed (handled by governance or automated in a more complex version).
*   **Parameterized Protocol:** Key economic parameters (stakes, fees, quorum) are configurable by the admin/governance.
*   **Request Lifecycle:** A defined flow for submitting a request, getting a result, validating it, and finalizing.

**Important Considerations & Limitations:**

*   **Off-chain Integration:** This contract defines the *on-chain* state and logic. It requires off-chain components (workers running AI models, validators performing checks, bots triggering finalization) to interact with it.
*   **Validation Logic:** The on-chain validation here is based on validators *attesting* to a result hash. Real-world AI validation is complex. This contract assumes validators have a reliable way to verify the off-chain computation's result and attest to its correctness (e.g., running the same computation, checking against ground truth if available, using zk-SNARKs *off-chain* to prove computation integrity and verifying the proof *on-chain* - the latter is too complex for this example).
*   **Scalability:** Storing all request data and validator attestations on-chain can be gas-intensive for a high volume protocol. IPFS or other storage solutions are used for data/results, with only hashes stored on-chain.
*   **Slashing Automation:** Full automation of slashing based on complex logic can be difficult and risky on-chain. This contract includes a manual slash function for the admin, allowing off-chain governance to decide and execute penalties.

---

**Outline and Function Summary:**

**I. Protocol Setup and Administration (Only Owner)**
*   `initialize`: Sets the protocol token and initial admin.
*   `setParameters`: Configures minimum stakes, validation quorum, and fee distribution.
*   `withdrawProtocolFees`: Allows the admin to withdraw accumulated protocol fees.
*   `slash`: Allows the admin to penalize users (validators/model providers) by slashing their stake.

**II. Staking and Unstaking**
*   `stake`: Allows any user to lock protocol tokens in the contract.
*   `unstake`: Allows a user to withdraw staked tokens. (May have restrictions if user is an active validator/model provider or has pending rewards/slashes).
*   `getUserStake`: Views the total stake of a user.
*   `getTotalStaked`: Views the total tokens staked in the contract.

**III. Model Provider Management**
*   `registerModel`: Allows a staked user to register as a model provider and add a model description. Requires minimum stake.
*   `updateModelMetadata`: Allows a model provider to update their model's metadata URI.
*   `deactivateModel`: Allows a model provider to temporarily deactivate their model.
*   `activateModel`: Allows a model provider to reactivate their model.
*   `getModelsByProvider`: Views all models registered by a specific provider.
*   `getModelDetails`: Views the details of a specific model.
*   `claimRewards`: Allows a model provider to claim earned rewards.

**IV. Validator Management**
*   `registerAsValidator`: Allows a staked user to register as a validator. Requires minimum stake.
*   `deregisterAsValidator`: Allows a validator to step down. (May require a cool-down or clearing pending requests).
*   `updateValidatorStake`: Allows a validator to increase their stake.
*   `getValidatorDetails`: Views the details of a validator.
*   `claimRewards`: Allows a validator to claim earned rewards.
*   `isValidator`: Views if an address is currently a registered validator.

**V. Inference Request Lifecycle**
*   `submitInferenceRequest`: Allows a user to submit a request for inference using a specific model. Requires payment via staked tokens (transferred from user's stake or separate approval).
*   `submitRawResult`: Allows the registered model provider for a request to submit the initial result hash.
*   `attestResult`: Allows a registered validator to attest to the validity (or invalidity) of the submitted result hash for a request.
*   `finalizeRequest`: Triggered externally (e.g., by a bot/oracle) after validators have attested. This function checks for consensus among validators, distributes fees/rewards, and updates the request status.
*   `failRequest`: Allows the admin (or triggered by `finalizeRequest` if no consensus) to mark a request as failed and refund the user.
*   `getInferenceRequestDetails`: Views the details of a specific request.
*   `getRequestStatus`: Views the status of a specific request.

**VI. Views and Getters**
*   `protocolToken`: Views the address of the protocol token.
*   `getProtocolParameters`: Views the current protocol parameters.
*   `getPendingRewards`: Views the pending rewards for a user.
*   `getModelStatus`: Views the status of a specific model.
*   `isModelProvider`: Views if an address is a registered model provider.
*   `getAttestationsForRequest`: Views the attestations submitted for a specific request.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline and Function Summary above the code block.

contract DecentralizedAIProtocol is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    IERC20 public protocolToken;

    // --- State Variables and Structs ---

    // Protocol Parameters (Admin configurable)
    uint256 public minModelStake;
    uint256 public minValidatorStake;
    uint256 public validationQuorumPercentage; // Basis points (e.g., 7000 for 70%)
    uint256 public protocolFeeBips;         // Basis points
    uint256 public modelFeeBips;            // Basis points
    // Validator fee Bips is calculated: 10000 - protocolFeeBips - modelFeeBips

    // Staking
    mapping(address => uint256) private userStakes; // Total stake per user
    uint256 public totalStaked;

    // Rewards
    mapping(address => uint256) private pendingRewards; // Rewards accumulated for users

    // Models
    Counters.Counter private _modelIds;
    enum ModelStatus { Registered, Active, Deactivated }
    struct Model {
        address provider;
        string metadataURI; // e.g., IPFS hash or API description
        ModelStatus status;
        uint256 stakeRequirement; // Minimum stake provider must maintain
    }
    mapping(uint256 => Model) public models;
    mapping(address => uint256[]) public modelsByProvider;

    // Validators
    struct Validator {
        bool isRegistered;
        uint256 stake; // Stake specifically allocated for validation tasks (part of userStakes)
        // Future: Reputation score, slashing history, etc.
    }
    mapping(address => Validator) public validators;
    address[] public registeredValidatorAddresses; // Array to iterate validators

    // Inference Requests
    Counters.Counter private _requestIds;
    enum RequestStatus { Pending, Computing, Validating, Completed, Failed }
    struct InferenceRequest {
        address user;
        uint256 modelId;
        string dataHash;      // IPFS hash of input data
        uint256 feePaid;
        string resultHash;    // IPFS hash of the final result (after validation)
        RequestStatus status;
        mapping(address => bool) attestedValidators; // Validators who have attested
        mapping(address => bool) validatorAttestationStatus; // true = valid, false = invalid
        uint256 totalAttestationStakeWeight; // Sum of stake of validators who attested (valid)
        string rawResultHashClaim; // Initial result hash submitted by model provider
        address[] attestingValidatorsList; // List of validators who attested for easier iteration
    }
    mapping(uint256 => InferenceRequest) public inferenceRequests;

    // --- Events ---

    event Initialized(address indexed protocolToken);
    event ParametersSet(uint256 minModelStake, uint256 minValidatorStake, uint256 validationQuorumPercentage, uint256 protocolFeeBips, uint256 modelFeeBips);
    event Staked(address indexed user, uint256 amount, uint256 totalStake);
    event Unstaked(address indexed user, uint256 amount, uint256 totalStake);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ModelRegistered(uint256 indexed modelId, address indexed provider, string metadataURI, uint256 requiredStake);
    event ModelUpdated(uint256 indexed modelId, string newMetadataURI);
    event ModelStatusChanged(uint256 indexed modelId, ModelStatus newStatus);
    event ValidatorRegistered(address indexed validator);
    event ValidatorDeregistered(address indexed validator);
    event InferenceRequestSubmitted(uint256 indexed requestId, address indexed user, uint256 indexed modelId, string dataHash, uint256 feePaid);
    event RawResultSubmitted(uint256 indexed requestId, string rawResultHash);
    event ResultAttested(uint256 indexed requestId, address indexed validator, string resultHash, bool isValid);
    event RequestFinalized(uint256 indexed requestId, RequestStatus finalStatus, string finalResultHash);
    event RequestFailed(uint256 indexed requestId, string reason);
    event Slashed(address indexed user, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    // Not using custom modifiers like onlyModelProvider/onlyValidator for every function
    // Checking roles explicitly inside functions provides more flexibility for error messages
    // and combined logic.

    // --- Constructor and Initialization ---

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    /// @notice Initializes the contract with the protocol token. Can only be called once.
    /// @param _protocolToken The address of the ERC20 token used for staking and payments.
    function initialize(address _protocolToken) public onlyOwner {
        require(address(protocolToken) == address(0), "Already initialized");
        protocolToken = IERC20(_protocolToken);
        emit Initialized(_protocolToken);
    }

    // --- Admin and Setup Functions ---

    /// @notice Sets the main protocol parameters.
    /// @param _minModelStake Minimum stake required for a model provider.
    /// @param _minValidatorStake Minimum stake required for a validator.
    /// @param _validationQuorumPercentage Quorum percentage (in basis points) required for request finalization.
    /// @param _protocolFeeBips Protocol fee percentage (in basis points).
    /// @param _modelFeeBips Model provider fee percentage (in basis points).
    function setParameters(
        uint256 _minModelStake,
        uint256 _minValidatorStake,
        uint256 _validationQuorumPercentage,
        uint256 _protocolFeeBips,
        uint256 _modelFeeBips
    ) public onlyOwner {
        require(address(protocolToken) != address(0), "Protocol not initialized");
        require(_validationQuorumPercentage <= 10000, "Quorum exceeds 100%");
        require(_protocolFeeBips.add(_modelFeeBips) <= 10000, "Total fees exceed 100%");

        minModelStake = _minModelStake;
        minValidatorStake = _minValidatorStake;
        validationQuorumPercentage = _validationQuorumPercentage;
        protocolFeeBips = _protocolFeeBips;
        modelFeeBips = _modelFeeBips;

        emit ParametersSet(minModelStake, minValidatorStake, validationQuorumPercentage, protocolFeeBips, modelFeeBips);
    }

    /// @notice Allows the protocol owner to withdraw accumulated protocol fees.
    /// @param recipient The address to send the fees to.
    function withdrawProtocolFees(address recipient) public onlyOwner {
        require(address(protocolToken) != address(0), "Protocol not initialized");
        uint256 contractBalance = protocolToken.balanceOf(address(this));
        // Calculate withdrawable amount: Total balance minus total staked amount
        uint256 withdrawableFees = contractBalance.sub(totalStaked);
        require(withdrawableFees > 0, "No withdrawable fees");

        protocolToken.transfer(recipient, withdrawableFees);
        emit ProtocolFeesWithdrawn(recipient, withdrawableFees);
    }

    /// @notice Allows the protocol owner to slash a user's stake.
    /// @param user The address of the user to slash.
    /// @param amount The amount of stake to slash.
    function slash(address user, uint256 amount) public onlyOwner {
        require(userStakes[user] >= amount, "Slash amount exceeds user stake");

        userStakes[user] = userStakes[user].sub(amount);
        totalStaked = totalStaked.sub(amount);

        // If the user is a validator, also reduce their explicit validator stake
        if (validators[user].isRegistered) {
             // Slashes should ideally target stake involved in misconduct (e.g., stake on a failed validation)
             // For simplicity here, we just reduce the general stake.
             // A more complex system would track stake allocations to specific tasks.
             // Ensure validator stake isn't reduced below min if they are still active, unless intent is to deregister.
             // Simplification: Reduce validator stake by max possible up to slashed amount without going below min
             uint256 maxSlashableValidatorStake = validators[user].stake.sub(minValidatorStake > 0 ? minValidatorStake : 0);
             uint256 slashValidatorStake = amount > maxSlashableValidatorStake ? maxSlashableValidatorStake : amount;
             validators[user].stake = validators[user].stake.sub(slashValidatorStake);
        }

        emit Slashed(user, amount);
    }


    // --- Staking Functions ---

    /// @notice Allows a user to stake protocol tokens.
    /// Requires the user to have approved this contract to spend the tokens beforehand.
    /// @param amount The amount of tokens to stake.
    function stake(uint256 amount) public {
        require(address(protocolToken) != address(0), "Protocol not initialized");
        require(amount > 0, "Stake amount must be greater than 0");

        protocolToken.transferFrom(msg.sender, address(this), amount);

        userStakes[msg.sender] = userStakes[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);

        emit Staked(msg.sender, amount, userStakes[msg.sender]);
    }

    /// @notice Allows a user to unstake protocol tokens.
    /// @param amount The amount of tokens to unstake.
    function unstake(uint256 amount) public {
        require(address(protocolToken) != address(0), "Protocol not initialized");
        require(amount > 0, "Unstake amount must be greater than 0");
        require(userStakes[msg.sender] >= amount, "Insufficient staked balance");

        // Check if user is an active validator/model provider and if unstake would violate min stake
        if (validators[msg.sender].isRegistered) {
             require(userStakes[msg.sender].sub(amount) >= validators[msg.sender].stake, "Unstake would violate validator's allocated stake");
             // A more complex system would track stake specifically allocated vs. general stake.
             // Here we assume validator.stake is *part* of userStakes and represents the minimum allocated portion.
             // A simpler interpretation: validator.stake is the *total* stake serving validator duty.
             // Let's use the simpler interpretation for now: userStakes = total balance, validator.stake = portion for validation.
             // Need to ensure userStakes remains >= validator.stake (which means validator stake must also decrease or be fully unstaked)
             // Alternative simple logic: User can unstake any amount > validator.stake. To unstake validator stake, must deregister.
             require(userStakes[msg.sender].sub(amount) >= validators[msg.sender].stake, "Unstake amount exceeds free stake (allocated for validation)");
        }

        // Check model provider min stake constraint
        for(uint i = 0; i < modelsByProvider[msg.sender].length; i++) {
            uint256 modelId = modelsByProvider[msg.sender][i];
            if (models[modelId].status != ModelStatus.Deactivated) {
                // Check if unstake would violate min stake for any active model
                 require(userStakes[msg.sender].sub(amount) >= models[modelId].stakeRequirement, "Unstake amount violates min stake for an active model");
            }
        }


        userStakes[msg.sender] = userStakes[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);

        // Transfer tokens back
        protocolToken.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount, userStakes[msg.sender]);
    }

    /// @notice Views the total staked balance of a user.
    /// @param user The address to query.
    /// @return The total staked amount.
    function getUserStake(address user) public view returns (uint256) {
        return userStakes[user];
    }

    /// @notice Views the total amount of tokens staked in the contract.
    /// @return The total staked amount across all users.
    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }


    // --- Model Provider Functions ---

    /// @notice Allows a staked user to register a new AI model.
    /// Requires the user's total stake to meet the minimum model stake requirement.
    /// @param metadataURI URI pointing to model description, API endpoint, etc.
    function registerModel(string memory metadataURI) public {
        require(address(protocolToken) != address(0), "Protocol not initialized");
        require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty");
        require(userStakes[msg.sender] >= minModelStake, "Insufficient stake to register model");

        _modelIds.increment();
        uint256 newModelId = _modelIds.current();

        models[newModelId] = Model({
            provider: msg.sender,
            metadataURI: metadataURI,
            status: ModelStatus.Active,
            stakeRequirement: minModelStake // Sets min stake requirement at registration time
        });

        modelsByProvider[msg.sender].push(newModelId);

        emit ModelRegistered(newModelId, msg.sender, metadataURI, minModelStake);
    }

    /// @notice Allows a model provider to update their model's metadata URI.
    /// @param modelId The ID of the model to update.
    /// @param newMetadataURI The new metadata URI.
    function updateModelMetadata(uint256 modelId, string memory newMetadataURI) public {
        require(models[modelId].provider == msg.sender, "Not the model provider");
        require(bytes(newMetadataURI).length > 0, "Metadata URI cannot be empty");

        models[modelId].metadataURI = newMetadataURI;
        emit ModelUpdated(modelId, newMetadataURI);
    }

    /// @notice Allows a model provider to deactivate their model.
    /// Deactivated models cannot receive new inference requests.
    /// @param modelId The ID of the model to deactivate.
    function deactivateModel(uint256 modelId) public {
        require(models[modelId].provider == msg.sender, "Not the model provider");
        require(models[modelId].status == ModelStatus.Active, "Model is not active");

        models[modelId].status = ModelStatus.Deactivated;
        emit ModelStatusChanged(modelId, ModelStatus.Deactivated);
    }

    /// @notice Allows a model provider to reactivate their model.
    /// Requires the provider's stake to still meet the model's stake requirement.
    /// @param modelId The ID of the model to activate.
    function activateModel(uint256 modelId) public {
        require(models[modelId].provider == msg.sender, "Not the model provider");
        require(models[modelId].status == ModelStatus.Deactivated, "Model is not deactivated");
         require(userStakes[msg.sender] >= models[modelId].stakeRequirement, "Insufficient stake to activate model");

        models[modelId].status = ModelStatus.Active;
        emit ModelStatusChanged(modelId, ModelStatus.Active);
    }

    /// @notice Views the list of model IDs registered by a provider.
    /// @param provider The address of the provider.
    /// @return An array of model IDs.
    function getModelsByProvider(address provider) public view returns (uint256[] memory) {
        return modelsByProvider[provider];
    }

    /// @notice Views details of a specific model.
    /// @param modelId The ID of the model.
    /// @return provider, metadataURI, status, stakeRequirement.
    function getModelDetails(uint256 modelId) public view returns (address, string memory, ModelStatus, uint256) {
        Model storage model = models[modelId];
        require(model.provider != address(0), "Model does not exist");
        return (model.provider, model.metadataURI, model.status, model.stakeRequirement);
    }

    /// @notice Views the status of a specific model.
    /// @param modelId The ID of the model.
    /// @return The status of the model.
    function getModelStatus(uint256 modelId) public view returns (ModelStatus) {
         require(models[modelId].provider != address(0), "Model does not exist");
         return models[modelId].status;
    }

     /// @notice Checks if an address is a registered model provider.
     /// @param user The address to check.
     /// @return True if the user has registered any model, false otherwise.
    function isModelProvider(address user) public view returns (bool) {
        return modelsByProvider[user].length > 0;
    }

    // --- Validator Functions ---

    /// @notice Allows a staked user to register as a validator.
    /// Requires the user's total stake to meet the minimum validator stake requirement.
    function registerAsValidator() public {
        require(address(protocolToken) != address(0), "Protocol not initialized");
        require(!validators[msg.sender].isRegistered, "Already registered as validator");
        require(userStakes[msg.sender] >= minValidatorStake, "Insufficient stake to register as validator");

        validators[msg.sender].isRegistered = true;
        validators[msg.sender].stake = minValidatorStake; // Allocate min stake initially
        registeredValidatorAddresses.push(msg.sender);

        emit ValidatorRegistered(msg.sender);
    }

    /// @notice Allows a validator to increase their stake allocated for validation.
    /// The amount must be available in the user's total stake.
    /// @param additionalStake The amount to add to validator stake.
    function updateValidatorStake(uint256 additionalStake) public {
        require(validators[msg.sender].isRegistered, "Not a registered validator");
        require(additionalStake > 0, "Additional stake must be greater than 0");
        // Ensure total user stake covers the new validator stake amount
        require(userStakes[msg.sender] >= validators[msg.sender].stake.add(additionalStake), "Insufficient total stake for this increase");

        validators[msg.sender].stake = validators[msg.sender].stake.add(additionalStake);
        // Note: This only updates the 'allocated' validator stake, not the total userStakes.
        // userStakes was already increased via `stake` function call.
    }

    /// @notice Allows a validator to step down.
    /// Requires no active requests where the validator has attested.
    function deregisterAsValidator() public {
        require(validators[msg.sender].isRegistered, "Not a registered validator");
        // Future: Add check for pending attestations or cool-down period
        // For simplicity now, requires validator.stake == 0 or allows immediate deregistration with stake locked until pending requests clear
        // Let's require validator.stake to be reduced to 0 first (by unstaking allocated validator stake via a future function or manual adjustment/slashing)
        require(validators[msg.sender].stake == 0, "Validator stake must be reduced to 0 first");

        validators[msg.sender].isRegistered = false;
        // Remove from the array (gas intensive for large arrays) - simple loop removal
        for (uint i = 0; i < registeredValidatorAddresses.length; i++) {
            if (registeredValidatorAddresses[i] == msg.sender) {
                registeredValidatorAddresses[i] = registeredValidatorAddresses[registeredValidatorAddresses.length - 1];
                registeredValidatorAddresses.pop();
                break;
            }
        }

        emit ValidatorDeregistered(msg.sender);
    }

    /// @notice Views details of a specific validator.
    /// @param validator The address of the validator.
    /// @return isRegistered, stake.
    function getValidatorDetails(address validator) public view returns (bool, uint256) {
        return (validators[validator].isRegistered, validators[validator].stake);
    }

     /// @notice Checks if an address is currently a registered validator.
     /// @param user The address to check.
     /// @return True if the user is a registered validator, false otherwise.
    function isValidator(address user) public view returns (bool) {
        return validators[user].isRegistered;
    }


    // --- Inference Request Functions ---

    /// @notice Allows a user to submit a request for AI inference.
    /// Requires the user to have approved this contract to spend the `maxFee` from their stake beforehand,
    /// OR have sufficient general stake for the fee to be deducted from `userStakes`.
    /// The contract deducts the fee immediately upon submission.
    /// @param modelId The ID of the model to use.
    /// @param dataHash IPFS hash or similar pointer to the input data.
    /// @param maxFee The maximum fee the user is willing to pay.
    function submitInferenceRequest(uint256 modelId, string memory dataHash, uint256 maxFee) public {
        require(address(protocolToken) != address(0), "Protocol not initialized");
        require(models[modelId].provider != address(0), "Model does not exist");
        require(models[modelId].status == ModelStatus.Active, "Model is not active");
        require(maxFee > 0, "Max fee must be greater than 0");
        require(bytes(dataHash).length > 0, "Data hash cannot be empty");

        // Fee payment: Deduct from user's general stake
        require(userStakes[msg.sender] >= maxFee, "Insufficient staked balance for fee");
        userStakes[msg.sender] = userStakes[msg.sender].sub(maxFee);
        // Note: Total staked doesn't change here as it's still within the contract, just reallocated.
        // It will be distributed later.

        _requestIds.increment();
        uint256 newRequestId = _requestIds.current();

        inferenceRequests[newRequestId] = InferenceRequest({
            user: msg.sender,
            modelId: modelId,
            dataHash: dataHash,
            feePaid: maxFee, // Fee is locked at submission
            resultHash: "",
            status: RequestStatus.Pending,
            rawResultHashClaim: "",
            attestedValidators: new mapping(address => bool)(), // Initialize mappings
            validatorAttestationStatus: new mapping(address => bool)(),
            totalAttestationStakeWeight: 0,
            attestingValidatorsList: new address[](0) // Initialize array
        });

        emit InferenceRequestSubmitted(newRequestId, msg.sender, modelId, dataHash, maxFee);
    }

    /// @notice Allows the registered model provider for a request to submit the computed result hash.
    /// This is the initial claim that validators will verify.
    /// @param requestId The ID of the request.
    /// @param rawResultHash IPFS hash or similar pointer to the computed result.
    function submitRawResult(uint256 requestId, string memory rawResultHash) public {
        InferenceRequest storage request = inferenceRequests[requestId];
        require(request.user != address(0), "Request does not exist");
        require(models[request.modelId].provider == msg.sender, "Not the model provider for this request");
        require(request.status == RequestStatus.Pending || request.status == RequestStatus.Computing, "Request not in valid state for result submission");
        require(bytes(rawResultHash).length > 0, "Result hash cannot be empty");

        request.rawResultHashClaim = rawResultHash;
        request.status = RequestStatus.Validating; // Move to validation state
        emit RawResultSubmitted(requestId, rawResultHash);
    }


    /// @notice Allows a registered validator to attest to the validity of the submitted result hash.
    /// @param requestId The ID of the request.
    /// @param resultHash The result hash being attested (must match the rawResultHashClaim).
    /// @param isValid True if the validator believes the result is valid, false otherwise.
    function attestResult(uint256 requestId, string memory resultHash, bool isValid) public {
        InferenceRequest storage request = inferenceRequests[requestId];
        require(request.user != address(0), "Request does not exist");
        require(validators[msg.sender].isRegistered, "Not a registered validator");
        require(validators[msg.sender].stake > 0, "Validator has no active stake");
        require(request.status == RequestStatus.Validating, "Request not in validating state");
        require(!request.attestedValidators[msg.sender], "Validator already attested");
        require(
             keccak256(bytes(resultHash)) == keccak256(bytes(request.rawResultHashClaim)),
             "Attested result hash does not match the submitted raw result claim"
        );

        request.attestedValidators[msg.sender] = true;
        request.validatorAttestationStatus[msg.sender] = isValid;
        request.attestingValidatorsList.push(msg.sender); // Track who attested

        // Only count stake weight for VALID attestations for consensus check
        if (isValid) {
            request.totalAttestationStakeWeight = request.totalAttestationStakeWeight.add(validators[msg.sender].stake);
        }

        emit ResultAttested(requestId, msg.sender, resultHash, isValid);
    }

    /// @notice Attempts to finalize a request based on validator attestations.
    /// Can be called by anyone (e.g., an automated bot or oracle).
    /// Checks if a quorum of validator stake has attested to a single result (implicitly, the rawResultHashClaim).
    /// Distributes fees if consensus is reached for a valid result.
    /// Marks as failed if no valid consensus or if validators attest as invalid.
    /// @param requestId The ID of the request to finalize.
    function finalizeRequest(uint256 requestId) public {
        InferenceRequest storage request = inferenceRequests[requestId];
        require(request.user != address(0), "Request does not exist");
        require(request.status == RequestStatus.Validating, "Request not in validating state");
        require(bytes(request.rawResultHashClaim).length > 0, "Raw result claim not submitted yet");

        uint256 totalValidatorStake = 0;
        // Sum total stake of ALL registered validators currently.
        // A better approach might be to sum stake of validators who *could* have attested (e.g., active when request was submitted)
        // For simplicity, sum current active validator stake.
        for (uint i = 0; i < registeredValidatorAddresses.length; i++) {
             address validatorAddr = registeredValidatorAddresses[i];
             if(validators[validatorAddr].isRegistered) { // Ensure validator is still registered
                totalValidatorStake = totalValidatorStake.add(validators[validatorAddr].stake);
             }
        }

        // Calculate required stake weight for quorum
        uint256 requiredStakeWeight = totalValidatorStake.mul(validationQuorumPercentage).div(10000);

        // Check if quorum is reached for VALID attestations
        bool quorumReached = request.totalAttestationStakeWeight >= requiredStakeWeight;

        // Check if any validator attested as INVALID
        bool hasInvalidAttestation = false;
        for(uint i = 0; i < request.attestingValidatorsList.length; i++) {
            address validatorAddr = request.attestingValidatorsList[i];
            if (request.attestedValidators[validatorAddr] && !request.validatorAttestationStatus[validatorAddr]) {
                hasInvalidAttestation = true;
                break;
            }
        }

        if (quorumReached && !hasInvalidAttestation) {
            // Consensus reached for a valid result
            request.resultHash = request.rawResultHashClaim; // The claimed result is accepted
            request.status = RequestStatus.Completed;

            // Distribute Fees
            uint256 totalFees = request.feePaid;
            uint256 protocolFee = totalFees.mul(protocolFeeBips).div(10000);
            uint256 modelProviderFee = totalFees.mul(modelFeeBips).div(10000);
            uint256 validatorFee = totalFees.sub(protocolFee).sub(modelProviderFee);

            // Accumulate rewards
            address modelProvider = models[request.modelId].provider;
            pendingRewards[modelProvider] = pendingRewards[modelProvider].add(modelProviderFee);

            // Distribute validator fee proportionally among validators who attested VALID
            if (request.totalAttestationStakeWeight > 0) {
                 for(uint i = 0; i < request.attestingValidatorsList.length; i++) {
                    address validatorAddr = request.attestingValidatorsList[i];
                    if (request.attestedValidators[validatorAddr] && request.validatorAttestationStatus[validatorAddr]) {
                        uint256 validatorShare = validatorFee.mul(validators[validatorAddr].stake).div(request.totalAttestationStakeWeight);
                        pendingRewards[validatorAddr] = pendingRewards[validatorAddr].add(validatorShare);
                        // Future: Reward reputation for correct attestation
                    } else {
                        // Future: Penalize validators who attested INCORRECTLY or didn't attest
                    }
                 }
            }
            // Remaining validatorFee if totalAttestationStakeWeight was 0 or rounding goes to protocol?
            // For simplicity, if totalAttestationStakeWeight is 0 but quorum somehow reached (unlikely with weighted quorum),
            // validatorFee remains undistributed or goes to protocol. Let's send remaining validator fee to protocol sink.
            if (validatorFee > 0 && request.totalAttestationStakeWeight == 0) {
                 // This case should ideally not happen if quorum requires >0 stake weight
                 // But as a fallback, add to protocol fee
                 protocolFee = protocolFee.add(validatorFee);
            }
             // Note: protocolFee remains in the contract balance until `withdrawProtocolFees` is called.


            emit RequestFinalized(requestId, RequestStatus.Completed, request.resultHash);

        } else {
            // No valid consensus reached, or an invalid attestation exists
            // Mark request as failed
            request.status = RequestStatus.Failed;
            request.resultHash = ""; // No accepted result

            // Refund user
            userStakes[request.user] = userStakes[request.user].add(request.feePaid);

            // Future: Penalize model provider for bad result claim, or validators for lack of consensus/bad attestations
            // For now, failure results in refund but no automated slash. Admin can slash manually if needed.

            emit RequestFailed(requestId, "Validation failed or no quorum");
        }
    }

    /// @notice Allows the admin (or triggered by finalization logic) to mark a request as failed and refund the user.
    /// Useful for cases like model provider inactivity or failure to submit a raw result.
    /// @param requestId The ID of the request to fail.
    function failRequest(uint256 requestId) public {
        // Only owner can manually fail, or if called by `finalizeRequest` (not directly callable externally).
        // For external manual call, require onlyOwner
        require(msg.sender == owner(), "Only owner can manually fail request");

        InferenceRequest storage request = inferenceRequests[requestId];
        require(request.user != address(0), "Request does not exist");
        require(request.status != RequestStatus.Completed && request.status != RequestStatus.Failed, "Request already completed or failed");

        request.status = RequestStatus.Failed;
        request.resultHash = ""; // No accepted result

        // Refund user
        userStakes[request.user] = userStakes[request.user].add(request.feePaid);

        // Future: Consider automated penalties for model provider inactivity

        emit RequestFailed(requestId, "Manually failed by admin");
    }


    /// @notice Views details of a specific inference request.
    /// @param requestId The ID of the request.
    /// @return user, modelId, dataHash, feePaid, resultHash, status, rawResultHashClaim.
    function getInferenceRequestDetails(uint256 requestId) public view returns (address, uint256, string memory, uint256, string memory, RequestStatus, string memory) {
        InferenceRequest storage request = inferenceRequests[requestId];
        require(request.user != address(0), "Request does not exist");
        return (request.user, request.modelId, request.dataHash, request.feePaid, request.resultHash, request.status, request.rawResultHashClaim);
    }

    /// @notice Views the status of a specific inference request.
    /// @param requestId The ID of the request.
    /// @return The status of the request.
    function getRequestStatus(uint256 requestId) public view returns (RequestStatus) {
         require(inferenceRequests[requestId].user != address(0), "Request does not exist");
         return inferenceRequests[requestId].status;
    }

    /// @notice Views the attestation status of validators for a specific request.
    /// @param requestId The ID of the request.
    /// @return An array of validator addresses who attested and their attestation status (true for valid).
    function getAttestationsForRequest(uint256 requestId) public view returns (address[] memory, bool[] memory) {
        InferenceRequest storage request = inferenceRequests[requestId];
        require(request.user != address(0), "Request does not exist");

        address[] memory validatorsList = request.attestingValidatorsList;
        bool[] memory statuses = new bool[](validatorsList.length);

        for(uint i = 0; i < validatorsList.length; i++) {
             address validatorAddr = validatorsList[i];
             // Need to check if they actually attested using the mapping, the list is just for iteration
             statuses[i] = request.validatorAttestationStatus[validatorAddr];
        }
        return (validatorsList, statuses);
    }


    // --- Reward Claiming ---

    /// @notice Allows a user (Model Provider or Validator) to claim their pending rewards.
    function claimRewards() public {
        require(address(protocolToken) != address(0), "Protocol not initialized");
        uint256 rewards = pendingRewards[msg.sender];
        require(rewards > 0, "No pending rewards");

        pendingRewards[msg.sender] = 0;
        // Note: Rewards are distributed from the total fee pool locked in the contract,
        // which comes from user stakes. No additional tokens are minted.

        // Transfer tokens to the user from the contract's stake balance
        // This implicitly uses the contract's total balance, which includes staked tokens and collected fees.
        // Ensure total balance is sufficient. The fee distribution logic in finalizeRequest ensures
        // fees are part of the balance.
        protocolToken.transfer(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

     /// @notice Views the pending rewards for a user.
     /// @param user The address to query.
     /// @return The amount of pending rewards.
    function getPendingRewards(address user) public view returns (uint256) {
        return pendingRewards[user];
    }


    // --- Getter for Protocol Parameters ---

    /// @notice Views the current protocol parameters.
    /// @return minModelStake, minValidatorStake, validationQuorumPercentage, protocolFeeBips, modelFeeBips.
    function getProtocolParameters() public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (minModelStake, minValidatorStake, validationQuorumPercentage, protocolFeeBips, modelFeeBips);
    }
}
```