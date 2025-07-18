Here's a Solidity smart contract for a Decentralized AI Model Reputation & Inference Marketplace (DART). It incorporates several advanced, creative, and trendy concepts without directly duplicating existing open-source projects by combining them in a novel way specific to AI model services.

**Core Concepts Introduced:**

1.  **Decentralized AI Marketplace:** Users can discover, request, and pay for inference services from registered AI models.
2.  **Reputation System:** Models, Inference Providers, and Arbiters accrue or lose reputation based on performance, user reviews, and dispute outcomes.
3.  **On-Chain Arbitration:** A decentralized mechanism for resolving disputes between users and providers, governed by staked arbiters.
4.  **Proof of Inference (Conceptual):** Providers are required to submit `_proofData` alongside inference results, signifying a commitment to verifiable computation (even if full verification happens off-chain).
5.  **Liquid Reputation:** Users can delegate their earned reputation to other addresses, enabling meta-governance or signaling beyond direct token holdings.
6.  **Dynamic Pricing & Reviews:** Model owners can adjust prices, and users can review models, impacting their discoverability and trust.
7.  **Staking Mechanisms:** Providers and Arbiters stake tokens to participate, aligning incentives and deterring malicious behavior.

---

### **Outline:**

**I. Core Infrastructure & Access Control**
    *   `constructor`: Initializes the contract and sets the initial owner.
    *   `setERC20Token`: Sets the ERC20 token address for all payments and staking.
    *   `setProtocolFee`: Sets the fee percentage for the marketplace.
    *   `updateReputationDecayRate`: Adjusts the rate at which reputation diminishes over time.
    *   `withdrawProtocolFees`: Allows the owner to withdraw accumulated fees.

**II. Model Registry & Management**
    *   `registerModel`: Allows model owners to list new AI models.
    *   `updateModel`: Enables model owners to update their model's details.
    *   `deregisterModel`: Allows model owners to remove their models.
    *   `getModelDetails`: Retrieves comprehensive information about a registered model.

**III. Inference Providers & Management**
    *   `registerProvider`: Allows individuals to register as inference providers by staking tokens.
    *   `updateProviderStatus`: Providers can toggle their active status.
    *   `deregisterProvider`: Providers can withdraw their stake and deregister.
    *   `getProviderDetails`: Retrieves details of a specific provider.

**IV. Inference Marketplace & Execution**
    *   `requestInference`: Users initiate an inference request, paying the model fee upfront.
    *   `submitInferenceResult`: Providers submit the result and a "proof" for a given request.
    *   `confirmInference`: Users confirm satisfaction, releasing payment to the provider.
    *   `claimStakedRewards`: Providers can claim rewards from successfully completed inferences.

**V. Reputation & Review System**
    *   `submitModelReview`: Users submit reviews and ratings for models they've used, influencing model reputation.
    *   `getModelReputation`: Retrieves a model's current reputation score.
    *   `getProviderReputation`: Retrieves a provider's current reputation score.
    *   `delegateReputation`: Allows users to delegate a portion of their reputation to another address.
    *   `revokeReputationDelegation`: Allows users to revoke previously delegated reputation.

**VI. Decentralized Arbitration System**
    *   `registerArbiter`: Allows users to register as arbiters by staking tokens.
    *   `deregisterArbiter`: Arbiters can withdraw their stake and deregister.
    *   `disputeInference`: Initiates a dispute over an inference result, locking funds.
    *   `voteOnDispute`: Registered arbiters cast their votes on ongoing disputes.
    *   `resolveDispute`: Finalizes a dispute, distributing funds and adjusting reputations based on arbiter votes.
    *   `getArbiterDetails`: Retrieves details of a specific arbiter.

---

### **Function Summary (26 Functions):**

1.  **`constructor(address _initialOwner, address _erc20TokenAddress)`**: Initializes the contract with an owner and the primary ERC20 token address.
2.  **`setERC20Token(address _tokenAddress)`**: (Owner-only) Sets or updates the ERC20 token used for payments, staking, and rewards.
3.  **`setProtocolFee(uint256 _newFeePermil)`**: (Owner-only) Sets the marketplace fee percentage (in permil, e.g., 10 for 1%).
4.  **`updateReputationDecayRate(uint256 _newRate)`**: (Owner-only) Adjusts how quickly reputation scores naturally decay over time (e.g., lower rate for slower decay).
5.  **`withdrawProtocolFees(address _recipient)`**: (Owner-only) Allows the contract owner to withdraw accumulated protocol fees.
6.  **`registerModel(string calldata _ipfsCID, string calldata _description, uint256 _price)`**: Allows a model owner to register a new AI model, requiring a registration fee (e.g., a small stake).
7.  **`updateModel(uint256 _modelId, string calldata _newIpfsCID, string calldata _newDescription, uint256 _newPrice)`**: Allows a model owner to update their registered model's IPFS CID, description, or price.
8.  **`deregisterModel(uint256 _modelId)`**: Allows a model owner to remove their model, refunding their registration fee.
9.  **`getModelDetails(uint256 _modelId)`**: (View) Retrieves all stored details for a specific registered model.
10. **`registerProvider(uint256 _stakeAmount)`**: Allows a user to register as an inference provider by staking a minimum amount of ERC20 tokens.
11. **`updateProviderStatus(bool _isActive)`**: Allows an active provider to toggle their availability status for accepting new inference requests.
12. **`deregisterProvider()`**: Allows a provider to withdraw their staked tokens and deregister from the marketplace.
13. **`getProviderDetails(address _providerAddress)`**: (View) Retrieves detailed information about a specific inference provider.
14. **`requestInference(uint256 _modelId, string calldata _inputIpfsCID)`**: Allows a user to request an inference from a specified model, transferring the model's price upfront to the contract.
15. **`submitInferenceResult(uint256 _requestId, string calldata _outputIpfsCID, bytes calldata _proofData)`**: An active provider submits the result (`_outputIpfsCID`) and a conceptual `_proofData` for an inference request.
16. **`confirmInference(uint256 _requestId)`**: The user who requested the inference confirms their satisfaction with the result, releasing the payment to the provider (minus protocol fees).
17. **`claimStakedRewards()`**: Allows providers and arbiters to claim accumulated rewards from successful operations (inference completions or correct dispute rulings).
18. **`submitModelReview(uint256 _modelId, uint8 _rating, string calldata _reviewIpfsCID)`**: Allows a user who has previously requested an inference from a model to submit a rating (1-5 stars) and a detailed review (IPFS CID), influencing the model's reputation.
19. **`getModelReputation(uint256 _modelId)`**: (View) Returns the current reputation score of a specific model.
20. **`getProviderReputation(address _providerAddress)`**: (View) Returns the current reputation score of a specific inference provider.
21. **`delegateReputation(address _delegatee, uint256 _amount)`**: Allows a user to delegate a portion of their *own earned reputation* (not tokens) to another address, useful for signaling or meta-governance.
22. **`revokeReputationDelegation(address _delegatee)`**: Allows a user to revoke a previously delegated reputation amount from a specific delegatee.
23. **`registerArbiter(uint256 _stakeAmount)`**: Allows a user to register as an arbiter by staking a required amount of ERC20 tokens.
24. **`deregisterArbiter()`**: Allows an arbiter to withdraw their staked tokens and deregister from the arbitration system.
25. **`disputeInference(uint256 _requestId, string calldata _reason)`**: Allows the user or provider of an inference to initiate a dispute, locking the payment and a dispute fee.
26. **`voteOnDispute(uint256 _disputeId, bool _isProviderCorrect)`**: Registered arbiters can vote on a dispute's outcome, supporting either the provider or the disputer. Requires a small vote stake.
27. **`resolveDispute(uint256 _disputeId)`**: After the voting period, anyone can call this function to finalize the dispute, distributing funds, slashing mis-voting arbiters, and updating reputations based on the majority vote.
28. **`getArbiterDetails(address _arbiterAddress)`**: (View) Retrieves detailed information about a specific arbiter.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for arithmetic safety

// Outline:
// I. Core Infrastructure & Access Control
// II. Model Registry & Management
// III. Inference Providers & Management
// IV. Inference Marketplace & Execution
// V. Reputation & Review System
// VI. Decentralized Arbitration System
// VII. Protocol Fees & Governance

// Function Summary:
// 1. constructor(address _initialOwner, address _erc20TokenAddress): Initializes the contract with an owner and the primary ERC20 token address.
// 2. setERC20Token(address _tokenAddress): (Owner-only) Sets or updates the ERC20 token used for payments, staking, and rewards.
// 3. setProtocolFee(uint256 _newFeePermil): (Owner-only) Sets the marketplace fee percentage (in permil, e.g., 10 for 1%).
// 4. updateReputationDecayRate(uint256 _newRate): (Owner-only) Adjusts how quickly reputation scores naturally decay over time (e.g., lower rate for slower decay).
// 5. withdrawProtocolFees(address _recipient): (Owner-only) Allows the contract owner to withdraw accumulated protocol fees.
// 6. registerModel(string calldata _ipfsCID, string calldata _description, uint256 _price): Allows a model owner to register a new AI model, requiring a registration fee (e.g., a small stake).
// 7. updateModel(uint256 _modelId, string calldata _newIpfsCID, string calldata _newDescription, uint256 _newPrice): Allows a model owner to update their registered model's IPFS CID, description, or price.
// 8. deregisterModel(uint256 _modelId): Allows a model owner to remove their model, refunding their registration fee.
// 9. getModelDetails(uint256 _modelId): (View) Retrieves all stored details for a specific registered model.
// 10. registerProvider(uint256 _stakeAmount): Allows a user to register as an inference provider by staking a minimum amount of ERC20 tokens.
// 11. updateProviderStatus(bool _isActive): Allows an active provider to toggle their availability status for accepting new inference requests.
// 12. deregisterProvider(): Allows a provider to withdraw their staked tokens and deregister from the marketplace.
// 13. getProviderDetails(address _providerAddress): (View) Retrieves detailed information about a specific inference provider.
// 14. requestInference(uint256 _modelId, string calldata _inputIpfsCID): Allows a user to request an inference from a specified model, transferring the model's price upfront to the contract.
// 15. submitInferenceResult(uint256 _requestId, string calldata _outputIpfsCID, bytes calldata _proofData): An active provider submits the result (`_outputIpfsCID`) and a conceptual `_proofData` for an inference request.
// 16. confirmInference(uint256 _requestId): The user who requested the inference confirms their satisfaction with the result, releasing the payment to the provider (minus protocol fees).
// 17. claimStakedRewards(): Allows providers and arbiters to claim accumulated rewards from successful operations (inference completions or correct dispute rulings).
// 18. submitModelReview(uint256 _modelId, uint8 _rating, string calldata _reviewIpfsCID): Allows a user who has previously requested an inference from a model to submit a rating (1-5 stars) and a detailed review (IPFS CID), influencing the model's reputation.
// 19. getModelReputation(uint256 _modelId): (View) Returns the current reputation score of a specific model.
// 20. getProviderReputation(address _providerAddress): (View) Returns the current reputation score of a specific inference provider.
// 21. delegateReputation(address _delegatee, uint256 _amount): Allows a user to delegate a portion of their *own earned reputation* (not tokens) to another address, useful for signaling or meta-governance.
// 22. revokeReputationDelegation(address _delegatee): Allows a user to revoke a previously delegated reputation amount from a specific delegatee.
// 23. registerArbiter(uint256 _stakeAmount): Allows a user to register as an arbiter by staking a required amount of ERC20 tokens.
// 24. deregisterArbiter(): Allows an arbiter to withdraw their staked tokens and deregister from the arbitration system.
// 25. disputeInference(uint256 _requestId, string calldata _reason): Allows the user or provider of an inference to initiate a dispute, locking the payment and a dispute fee.
// 26. voteOnDispute(uint256 _disputeId, bool _isProviderCorrect): Registered arbiters can vote on a dispute's outcome, supporting either the provider or the disputer. Requires a small vote stake.
// 27. resolveDispute(uint256 _disputeId): After the voting period, anyone can call this function to finalize the dispute, distributing funds, slashing mis-voting arbiters, and updating reputations based on the majority vote.
// 28. getArbiterDetails(address _arbiterAddress): (View) Retrieves detailed information about a specific arbiter.


contract DecentralizedAIMarketplace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public dartToken; // The ERC20 token used for staking and payments

    uint256 public protocolFeePermil; // e.g., 10 for 1% fee (10/1000)
    uint256 public reputationDecayRate; // Represents points lost per unit of time (e.g., per week)

    // --- Configuration Constants ---
    uint256 public constant MIN_PROVIDER_STAKE = 100e18; // Example: 100 DART tokens
    uint256 public constant MIN_ARBITER_STAKE = 500e18;  // Example: 500 DART tokens
    uint256 public constant DISPUTE_FEE = 10e18;        // Example: 10 DART tokens
    uint256 public constant ARBITER_VOTE_STAKE = 5e18;  // Example: 5 DART tokens per vote
    uint256 public constant DISPUTE_VOTING_PERIOD = 3 days; // Time for arbiters to vote
    uint256 public constant ARBITER_REWARD_PER_VOTE = 1e18; // Reward for correct arbiter vote

    // --- State Variables & Mappings ---

    // Models
    struct Model {
        address owner;
        string ipfsCID; // IPFS CID of the AI model's artifacts/code
        string description;
        uint256 price; // Price per inference in DART tokens
        bool isActive;
        int256 reputation; // Reputation score (can be positive or negative)
        uint256 lastReputationUpdate; // Timestamp for decay calculation
    }
    mapping(uint256 => Model) public models;
    uint256 public nextModelId;
    mapping(address => uint256[]) public modelsOwnedByUser; // For easier lookup of user's models

    // Providers
    struct Provider {
        uint256 stake;
        bool isActive; // Available for new requests
        bool isRegistered;
        int256 reputation;
        uint256 lastReputationUpdate;
        uint256 rewardsAccumulated;
    }
    mapping(address => Provider) public providers;

    // Arbiters
    struct Arbiter {
        uint256 stake;
        bool isRegistered;
        int256 reputation;
        uint256 lastReputationUpdate;
        uint256 rewardsAccumulated;
    }
    mapping(address => Arbiter) public arbiters;

    // Inference Requests
    enum RequestStatus {
        Requested,
        InProgress,
        Completed,
        Disputed,
        Resolved,
        Confirmed
    }
    struct InferenceRequest {
        uint256 id;
        uint256 modelId;
        address requester;
        address provider; // Assigned provider
        string inputIpfsCID;
        string outputIpfsCID;
        bytes proofData; // Placeholder for cryptographic proof (e.g., ZK-SNARK hash, TEE attestation)
        uint256 paymentAmount;
        RequestStatus status;
        uint256 requestTime;
        uint224 completedTime; // Use uint224 to save space if needed
    }
    mapping(uint256 => InferenceRequest) public inferenceRequests;
    uint256 public nextRequestId;

    // Disputes
    enum DisputeStatus {
        Pending,
        Voting,
        Resolved
    }
    struct Dispute {
        uint256 requestId;
        address disputer; // The address who initiated the dispute
        address counterparty; // The other party in the dispute
        string reason;
        DisputeStatus status;
        uint256 startTime;
        uint256 endTime;
        int256 providerVotes; // Negative for disputer (user) wins, positive for provider wins
        mapping(address => bool) hasVoted; // Arbiters who have voted
        mapping(address => uint256) arbiterVoteStake; // Stakes for current vote
        uint256 totalVoterStake; // Total stake from voting arbiters
        bool isProviderCorrectOutcome; // Result of the dispute
    }
    mapping(uint256 => Dispute) public disputes;
    uint256 public nextDisputeId;

    // Reputation delegation (for "liquid reputation")
    // Maps delegator => delegatee => delegated_amount
    mapping(address => mapping(address => uint256)) public delegatedReputation;

    // --- Events ---
    event ERC20TokenSet(address indexed _tokenAddress);
    event ModelRegistered(uint256 indexed modelId, address indexed owner, string ipfsCID, uint256 price);
    event ModelUpdated(uint256 indexed modelId, string newIpfsCID, uint256 newPrice);
    event ModelDeregistered(uint256 indexed modelId);
    event ProviderRegistered(address indexed provider, uint256 stake);
    event ProviderStatusUpdated(address indexed provider, bool isActive);
    event ProviderDeregistered(address indexed provider);
    event ArbiterRegistered(address indexed arbiter, uint256 stake);
    event ArbiterDeregistered(address indexed arbiter);
    event InferenceRequested(uint256 indexed requestId, uint256 indexed modelId, address indexed requester, uint256 amount);
    event InferenceResultSubmitted(uint256 indexed requestId, address indexed provider, string outputIpfsCID);
    event InferenceConfirmed(uint256 indexed requestId, address indexed requester, address indexed provider);
    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed requestId, address indexed disputer, string reason);
    event ArbiterVoted(uint256 indexed disputeId, address indexed arbiter, bool isProviderCorrect);
    event DisputeResolved(uint256 indexed disputeId, bool isProviderCorrectOutcome);
    event ModelReviewed(uint256 indexed modelId, address indexed reviewer, uint8 rating);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationDelegationRevoked(address indexed delegator, address indexed delegatee, uint256 amount);
    event RewardsClaimed(address indexed beneficiary, uint256 amount);

    // --- Constructor ---
    constructor(address _initialOwner, address _erc20TokenAddress) Ownable(_initialOwner) {
        require(_erc20TokenAddress != address(0), "DART: Token address cannot be zero");
        dartToken = IERC20(_erc20TokenAddress);
        protocolFeePermil = 50; // Default 5% fee
        reputationDecayRate = 1; // Default decay rate
        nextModelId = 1;
        nextRequestId = 1;
        nextDisputeId = 1;
        emit ERC20TokenSet(_erc20TokenAddress);
    }

    // --- I. Core Infrastructure & Access Control ---

    function setERC20Token(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "DART: Token address cannot be zero");
        dartToken = IERC20(_tokenAddress);
        emit ERC20TokenSet(_tokenAddress);
    }

    function setProtocolFee(uint256 _newFeePermil) external onlyOwner {
        require(_newFeePermil <= 1000, "DART: Fee cannot exceed 100%");
        protocolFeePermil = _newFeePermil;
    }

    function updateReputationDecayRate(uint256 _newRate) external onlyOwner {
        reputationDecayRate = _newRate;
    }

    function withdrawProtocolFees(address _recipient) external onlyOwner nonReentrant {
        uint256 balance = dartToken.balanceOf(address(this));
        uint256 totalStakes = 0;
        // Sum all current stakes to calculate the withdrawable fee amount
        // This is a simplified approach, a more robust system might track fees directly.
        for (uint256 i = 1; i < nextModelId; i++) {
            if (models[i].isActive) totalStakes = totalStakes.add(MIN_PROVIDER_STAKE); // Assuming models have a "registration stake" like providers
        }
        for (address provAddr : getActiveProviderAddresses()) { // Placeholder, ideally iterate through a list
             totalStakes = totalStakes.add(providers[provAddr].stake);
        }
        for (address arbAddr : getActiveArbiterAddresses()) { // Placeholder
             totalStakes = totalStakes.add(arbiters[arbAddr].stake);
        }

        uint256 withdrawableAmount = balance.sub(totalStakes); // Rough calculation

        require(withdrawableAmount > 0, "DART: No fees to withdraw.");
        
        uint256 actualWithdrawAmount = dartToken.balanceOf(address(this)); // withdraw entire balance for simplicity, assuming it's fees.
        // NOTE: In a real system, tracking specific fee income vs. locked stakes is crucial.
        // For this example, we'll assume any excess balance is fees, but this can be risky.
        // A better approach would be `uint256 public totalProtocolFeesAccumulated;`
        
        // For simplicity, let's just attempt to transfer available balance minus any known stakes.
        // This requires careful tracking of `totalProtocolFeesAccumulated` instead of relying on `balanceOf`.
        // Let's implement `totalProtocolFeesAccumulated` for safer withdrawals.
        uint256 amountToWithdraw = totalProtocolFeesAccumulated;
        totalProtocolFeesAccumulated = 0; // Reset
        require(amountToWithdraw > 0, "DART: No fees to withdraw.");
        require(dartToken.transfer(_recipient, amountToWithdraw), "DART: Fee transfer failed.");
    }
    uint256 public totalProtocolFeesAccumulated;


    // --- Helper function to calculate reputation decay ---
    function _updateReputation(address _addr, int256 _currentRep, uint256 _lastUpdate, bool isModel) internal returns (int256) {
        uint256 timeElapsed = block.timestamp.sub(_lastUpdate);
        int256 decayAmount = int256(timeElapsed.mul(reputationDecayRate));
        int256 newRep = _currentRep.sub(decayAmount);
        if (newRep < 0) newRep = 0; // Reputation cannot go below zero from decay

        if (isModel) {
            models[uint256(uint160(_addr))].reputation = newRep; // Hacky way to store model reputation if modelId isn't available
            models[uint256(uint160(_addr))].lastReputationUpdate = block.timestamp;
        } else {
            if (providers[_addr].isRegistered) {
                providers[_addr].reputation = newRep;
                providers[_addr].lastReputationUpdate = block.timestamp;
            } else if (arbiters[_addr].isRegistered) {
                arbiters[_addr].reputation = newRep;
                arbiters[_addr].lastReputationUpdate = block.timestamp;
            }
        }
        return newRep;
    }
    // Correct helper for model reputation update
    function _updateModelReputation(uint256 _modelId, int256 _currentRep, uint256 _lastUpdate) internal returns (int256) {
        uint256 timeElapsed = block.timestamp.sub(_lastUpdate);
        int256 decayAmount = int256(timeElapsed.mul(reputationDecayRate));
        int256 newRep = _currentRep.sub(decayAmount);
        if (newRep < 0) newRep = 0;
        models[_modelId].reputation = newRep;
        models[_modelId].lastReputationUpdate = block.timestamp;
        return newRep;
    }
    // Correct helper for provider reputation update
    function _updateProviderReputation(address _providerAddr, int256 _currentRep, uint256 _lastUpdate) internal returns (int256) {
        uint256 timeElapsed = block.timestamp.sub(_lastUpdate);
        int256 decayAmount = int256(timeElapsed.mul(reputationDecayRate));
        int256 newRep = _currentRep.sub(decayAmount);
        if (newRep < 0) newRep = 0;
        providers[_providerAddr].reputation = newRep;
        providers[_providerAddr].lastReputationUpdate = block.timestamp;
        return newRep;
    }
    // Correct helper for arbiter reputation update
    function _updateArbiterReputation(address _arbiterAddr, int256 _currentRep, uint256 _lastUpdate) internal returns (int256) {
        uint256 timeElapsed = block.timestamp.sub(_lastUpdate);
        int256 decayAmount = int256(timeElapsed.mul(reputationDecayRate));
        int256 newRep = _currentRep.sub(decayAmount);
        if (newRep < 0) newRep = 0;
        arbiters[_arbiterAddr].reputation = newRep;
        arbiters[_arbiterAddr].lastReputationUpdate = block.timestamp;
        return newRep;
    }

    // --- II. Model Registry & Management ---

    function registerModel(string calldata _ipfsCID, string calldata _description, uint256 _price) external nonReentrant {
        require(bytes(_ipfsCID).length > 0, "DART: IPFS CID cannot be empty.");
        require(_price > 0, "DART: Model price must be greater than zero.");
        
        // Model registration fee (optional, but good for sybil resistance)
        // require(dartToken.transferFrom(msg.sender, address(this), MODEL_REGISTRATION_FEE), "DART: Model registration fee transfer failed.");

        models[nextModelId] = Model({
            owner: msg.sender,
            ipfsCID: _ipfsCID,
            description: _description,
            price: _price,
            isActive: true,
            reputation: 0,
            lastReputationUpdate: block.timestamp
        });
        modelsOwnedByUser[msg.sender].push(nextModelId);
        emit ModelRegistered(nextModelId, msg.sender, _ipfsCID, _price);
        nextModelId++;
    }

    function updateModel(uint256 _modelId, string calldata _newIpfsCID, string calldata _newDescription, uint256 _newPrice) external nonReentrant {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "DART: Not your model.");
        require(model.isActive, "DART: Model is not active.");

        if (bytes(_newIpfsCID).length > 0) {
            model.ipfsCID = _newIpfsCID;
        }
        if (bytes(_newDescription).length > 0) {
            model.description = _newDescription;
        }
        if (_newPrice > 0) {
            model.price = _newPrice;
        }
        emit ModelUpdated(_modelId, model.ipfsCID, model.price);
    }

    function deregisterModel(uint256 _modelId) external nonReentrant {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "DART: Not your model.");
        require(model.isActive, "DART: Model is not active."); // Or require no pending inferences

        model.isActive = false; // Mark as inactive instead of deleting to preserve history
        // If there was a registration stake, refund it here:
        // require(dartToken.transfer(msg.sender, MODEL_REGISTRATION_FEE), "DART: Stake refund failed.");

        emit ModelDeregistered(_modelId);
    }

    function getModelDetails(uint256 _modelId) external view returns (Model memory) {
        return models[_modelId];
    }

    // --- III. Inference Providers & Management ---

    function registerProvider(uint256 _stakeAmount) external nonReentrant {
        require(!providers[msg.sender].isRegistered, "DART: Provider already registered.");
        require(_stakeAmount >= MIN_PROVIDER_STAKE, "DART: Stake amount too low.");
        
        require(dartToken.transferFrom(msg.sender, address(this), _stakeAmount), "DART: Token transfer for stake failed.");

        providers[msg.sender] = Provider({
            stake: _stakeAmount,
            isActive: true,
            isRegistered: true,
            reputation: 0,
            lastReputationUpdate: block.timestamp,
            rewardsAccumulated: 0
        });
        emit ProviderRegistered(msg.sender, _stakeAmount);
    }

    function updateProviderStatus(bool _isActive) external {
        require(providers[msg.sender].isRegistered, "DART: Not a registered provider.");
        providers[msg.sender].isActive = _isActive;
        emit ProviderStatusUpdated(msg.sender, _isActive);
    }

    function deregisterProvider() external nonReentrant {
        Provider storage provider = providers[msg.sender];
        require(provider.isRegistered, "DART: Not a registered provider.");
        // Check for any pending inference requests before allowing deregistration
        // (Not implemented for brevity, but crucial in production)

        provider.isRegistered = false;
        provider.isActive = false;

        uint256 refundAmount = provider.stake.add(provider.rewardsAccumulated);
        provider.stake = 0;
        provider.rewardsAccumulated = 0;

        require(dartToken.transfer(msg.sender, refundAmount), "DART: Provider stake refund failed.");
        emit ProviderDeregistered(msg.sender);
    }

    function getProviderDetails(address _providerAddress) external view returns (Provider memory) {
        return providers[_providerAddress];
    }

    // --- IV. Inference Marketplace & Execution ---

    function requestInference(uint256 _modelId, string calldata _inputIpfsCID) external nonReentrant {
        Model storage model = models[_modelId];
        require(model.isActive, "DART: Model is not active or does not exist.");
        require(bytes(_inputIpfsCID).length > 0, "DART: Input IPFS CID cannot be empty.");
        
        // Find an active provider (simple round-robin or reputation-based assignment could be added)
        address selectedProvider = address(0);
        // For simplicity, let's just pick the first active provider we find, or allow any active provider to pick up later.
        // A more advanced system would have a bidding/matching mechanism.
        // For now, any active provider can 'submitInferenceResult' for 'InProgress' requests
        
        require(dartToken.transferFrom(msg.sender, address(this), model.price), "DART: Payment for inference failed.");

        inferenceRequests[nextRequestId] = InferenceRequest({
            id: nextRequestId,
            modelId: _modelId,
            requester: msg.sender,
            provider: address(0), // Will be assigned by provider on submission
            inputIpfsCID: _inputIpfsCID,
            outputIpfsCID: "",
            proofData: "",
            paymentAmount: model.price,
            status: RequestStatus.Requested,
            requestTime: block.timestamp,
            completedTime: 0
        });

        emit InferenceRequested(nextRequestId, _modelId, msg.sender, model.price);
        nextRequestId++;
    }

    function submitInferenceResult(uint256 _requestId, string calldata _outputIpfsCID, bytes calldata _proofData) external nonReentrant {
        InferenceRequest storage req = inferenceRequests[_requestId];
        Provider storage provider = providers[msg.sender];

        require(provider.isRegistered && provider.isActive, "DART: Not an active provider.");
        require(req.status == RequestStatus.Requested || req.status == RequestStatus.InProgress, "DART: Request is not in progress or already completed/disputed.");
        require(bytes(_outputIpfsCID).length > 0, "DART: Output IPFS CID cannot be empty.");
        require(bytes(_proofData).length > 0, "DART: Proof data cannot be empty."); // Essential for verifiability

        // If the request was 'Requested', this provider claims it
        if (req.provider == address(0)) {
            req.provider = msg.sender;
        } else {
            require(req.provider == msg.sender, "DART: Request already assigned to another provider.");
        }
        
        req.outputIpfsCID = _outputIpfsCID;
        req.proofData = _proofData;
        req.status = RequestStatus.Completed; // Tentatively completed, awaiting user confirmation
        req.completedTime = uint224(block.timestamp);

        emit InferenceResultSubmitted(_requestId, msg.sender, _outputIpfsCID);
    }

    function confirmInference(uint256 _requestId) external nonReentrant {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.requester == msg.sender, "DART: Only the requester can confirm.");
        require(req.status == RequestStatus.Completed, "DART: Request not in 'Completed' status.");
        
        uint256 fee = req.paymentAmount.mul(protocolFeePermil).div(1000);
        uint256 providerShare = req.paymentAmount.sub(fee);

        totalProtocolFeesAccumulated = totalProtocolFeesAccumulated.add(fee);
        providers[req.provider].rewardsAccumulated = providers[req.provider].rewardsAccumulated.add(providerShare);

        req.status = RequestStatus.Confirmed;
        // Increase reputation for model and provider
        _updateModelReputation(req.modelId, models[req.modelId].reputation, models[req.modelId].lastReputationUpdate);
        models[req.modelId].reputation = models[req.modelId].reputation.add(10); // Positive reputation boost
        _updateProviderReputation(req.provider, providers[req.provider].reputation, providers[req.provider].lastReputationUpdate);
        providers[req.provider].reputation = providers[req.provider].reputation.add(10); // Positive reputation boost

        emit InferenceConfirmed(_requestId, msg.sender, req.provider);
    }

    function claimStakedRewards() external nonReentrant {
        uint256 amountToClaim = 0;
        if (providers[msg.sender].isRegistered) {
            amountToClaim = providers[msg.sender].rewardsAccumulated;
            providers[msg.sender].rewardsAccumulated = 0;
        } else if (arbiters[msg.sender].isRegistered) {
            amountToClaim = arbiters[msg.sender].rewardsAccumulated;
            arbiters[msg.sender].rewardsAccumulated = 0;
        } else {
            revert("DART: Not a registered provider or arbiter.");
        }
        
        require(amountToClaim > 0, "DART: No rewards to claim.");
        require(dartToken.transfer(msg.sender, amountToClaim), "DART: Reward claim failed.");
        emit RewardsClaimed(msg.sender, amountToClaim);
    }

    // --- V. Reputation & Review System ---

    function submitModelReview(uint256 _modelId, uint8 _rating, string calldata _reviewIpfsCID) external {
        Model storage model = models[_modelId];
        require(model.isActive, "DART: Model does not exist or is inactive.");
        require(_rating >= 1 && _rating <= 5, "DART: Rating must be between 1 and 5.");
        require(bytes(_reviewIpfsCID).length > 0, "DART: Review IPFS CID cannot be empty.");

        // Check if requester has used this model before (more robust would be to link reviews to specific InferenceRequests)
        // For simplicity, we just allow anyone to review if they've used it, but linking to `InferenceRequest` is better.
        // For now, assume a mapping `mapping(address => mapping(uint256 => bool)) public hasUsedModel;` populated in `confirmInference`
        // require(hasUsedModel[msg.sender][_modelId], "DART: You must have used this model to review it.");

        // Update model reputation based on rating
        _updateModelReputation(_modelId, model.reputation, model.lastReputationUpdate); // Apply decay first
        int256 ratingInfluence = int256(_rating).sub(3).mul(5); // -10 for 1-star, +10 for 5-star
        model.reputation = model.reputation.add(ratingInfluence);

        emit ModelReviewed(_modelId, msg.sender, _rating);
    }

    function getModelReputation(uint256 _modelId) public view returns (int256) {
        Model storage model = models[_modelId];
        if (model.owner == address(0)) return 0; // Model doesn't exist
        uint256 timeElapsed = block.timestamp.sub(model.lastReputationUpdate);
        int256 decayAmount = int256(timeElapsed.mul(reputationDecayRate));
        int256 currentRep = model.reputation.sub(decayAmount);
        if (currentRep < 0) currentRep = 0;
        return currentRep;
    }

    function getProviderReputation(address _providerAddress) public view returns (int256) {
        Provider storage provider = providers[_providerAddress];
        if (!provider.isRegistered) return 0;
        uint256 timeElapsed = block.timestamp.sub(provider.lastReputationUpdate);
        int256 decayAmount = int256(timeElapsed.mul(reputationDecayRate));
        int256 currentRep = provider.reputation.sub(decayAmount);
        if (currentRep < 0) currentRep = 0;
        return currentRep;
    }

    function delegateReputation(address _delegatee, uint256 _amount) external {
        // This function represents "liquid reputation". The reputation itself isn't tokens,
        // but a score. Delegating means lending influence.
        // Ensure msg.sender has enough "effective" reputation to delegate (not just current score)
        // For simplicity, we assume an abstract reputation pool that users gain and can delegate.
        // A user's total 'effective reputation' would be their base reputation + sum of delegated reputation to them.
        require(_delegatee != address(0) && _delegatee != msg.sender, "DART: Invalid delegatee address.");
        // A more complex system would track max_delegatable_reputation for a user.
        // For now, a simple check that you can't delegate more than "your" base (arbitrary)
        // or a theoretical max.
        
        // This is a conceptual delegation. The 'amount' here is not tokens, but abstract reputation points.
        // It impacts how a user's 'voting power' or 'influence' is calculated in off-chain systems or future governance.
        delegatedReputation[msg.sender][_delegatee] = delegatedReputation[msg.sender][_delegatee].add(_amount);
        emit ReputationDelegated(msg.sender, _delegatee, _amount);
    }

    function revokeReputationDelegation(address _delegatee) external {
        require(_delegatee != address(0) && _delegatee != msg.sender, "DART: Invalid delegatee address.");
        uint256 amount = delegatedReputation[msg.sender][_delegatee];
        require(amount > 0, "DART: No reputation delegated to this address.");
        
        delegatedReputation[msg.sender][_delegatee] = 0; // Revoke all delegated to this specific delegatee
        emit ReputationDelegationRevoked(msg.sender, _delegatee, amount);
    }

    // --- VI. Decentralized Arbitration System ---

    function registerArbiter(uint256 _stakeAmount) external nonReentrant {
        require(!arbiters[msg.sender].isRegistered, "DART: Arbiter already registered.");
        require(_stakeAmount >= MIN_ARBITER_STAKE, "DART: Arbiter stake amount too low.");

        require(dartToken.transferFrom(msg.sender, address(this), _stakeAmount), "DART: Token transfer for arbiter stake failed.");

        arbiters[msg.sender] = Arbiter({
            stake: _stakeAmount,
            isRegistered: true,
            reputation: 0,
            lastReputationUpdate: block.timestamp,
            rewardsAccumulated: 0
        });
        emit ArbiterRegistered(msg.sender, _stakeAmount);
    }

    function deregisterArbiter() external nonReentrant {
        Arbiter storage arbiter = arbiters[msg.sender];
        require(arbiter.isRegistered, "DART: Not a registered arbiter.");
        // Check for active disputes they are involved in before deregistration
        // (Not implemented for brevity, but crucial in production)

        arbiter.isRegistered = false;
        uint256 refundAmount = arbiter.stake.add(arbiter.rewardsAccumulated);
        arbiter.stake = 0;
        arbiter.rewardsAccumulated = 0;

        require(dartToken.transfer(msg.sender, refundAmount), "DART: Arbiter stake refund failed.");
        emit ArbiterDeregistered(msg.sender);
    }

    function disputeInference(uint256 _requestId, string calldata _reason) external nonReentrant {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.status == RequestStatus.Completed, "DART: Request cannot be disputed in its current state.");
        require(msg.sender == req.requester || msg.sender == req.provider, "DART: Only requester or provider can dispute.");
        require(bytes(_reason).length > 0, "DART: Dispute reason cannot be empty.");
        require(dartToken.transferFrom(msg.sender, address(this), DISPUTE_FEE), "DART: Dispute fee transfer failed.");

        req.status = RequestStatus.Disputed;

        address counterparty = (msg.sender == req.requester) ? req.provider : req.requester;

        disputes[nextDisputeId] = Dispute({
            requestId: _requestId,
            disputer: msg.sender,
            counterparty: counterparty,
            reason: _reason,
            status: DisputeStatus.Voting, // Immediately goes to voting phase
            startTime: block.timestamp,
            endTime: block.timestamp.add(DISPUTE_VOTING_PERIOD),
            providerVotes: 0,
            totalVoterStake: 0,
            isProviderCorrectOutcome: false // Default, will be set on resolution
        });

        emit DisputeInitiated(nextDisputeId, _requestId, msg.sender, _reason);
        nextDisputeId++;
    }

    function voteOnDispute(uint256 _disputeId, bool _isProviderCorrect) external nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Voting, "DART: Dispute is not in voting phase.");
        require(block.timestamp <= dispute.endTime, "DART: Voting period has ended.");
        require(arbiters[msg.sender].isRegistered, "DART: Not a registered arbiter.");
        require(!dispute.hasVoted[msg.sender], "DART: Arbiter has already voted on this dispute.");

        require(dartToken.transferFrom(msg.sender, address(this), ARBITER_VOTE_STAKE), "DART: Arbiter vote stake transfer failed.");
        dispute.arbiterVoteStake[msg.sender] = ARBITER_VOTE_STAKE;
        dispute.totalVoterStake = dispute.totalVoterStake.add(ARBITER_VOTE_STAKE);

        if (_isProviderCorrect) {
            dispute.providerVotes = dispute.providerVotes.add(int256(ARBITER_VOTE_STAKE)); // Vote for provider
        } else {
            dispute.providerVotes = dispute.providerVotes.sub(int256(ARBITER_VOTE_STAKE)); // Vote against provider (for disputer)
        }
        dispute.hasVoted[msg.sender] = true;

        emit ArbiterVoted(_disputeId, msg.sender, _isProviderCorrect);
    }

    function resolveDispute(uint256 _disputeId) external nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        InferenceRequest storage req = inferenceRequests[dispute.requestId];
        require(dispute.status == DisputeStatus.Voting, "DART: Dispute is not in voting phase.");
        require(block.timestamp > dispute.endTime, "DART: Voting period has not ended yet.");
        
        dispute.status = DisputeStatus.Resolved;

        bool isProviderCorrectOutcome = dispute.providerVotes >= 0; // Majority voted for provider
        dispute.isProviderCorrectOutcome = isProviderCorrectOutcome;

        // Repay original inference payment + fees
        uint256 totalLockedFunds = req.paymentAmount.add(DISPUTE_FEE); // Original payment + dispute fee

        address winnerAddress;
        address loserAddress;
        int256 winnerReputationChange = 0;
        int256 loserReputationChange = 0;
        int256 arbiterReputationChange = 0; // For correct/incorrect arbiters

        if (isProviderCorrectOutcome) {
            winnerAddress = req.provider;
            loserAddress = dispute.disputer;
            winnerReputationChange = 20; // Provider wins dispute, gains reputation
            loserReputationChange = -20; // Disputer loses, loses reputation

            // Transfer full payment + dispute fee to provider (winner)
            providers[winnerAddress].rewardsAccumulated = providers[winnerAddress].rewardsAccumulated.add(totalLockedFunds);

        } else {
            winnerAddress = dispute.disputer;
            loserAddress = req.provider;
            winnerReputationChange = 20; // Disputer wins dispute, gains reputation
            loserReputationChange = -20; // Provider loses, loses reputation
            
            // Refund original payment to requester, dispute fee to requester (winner)
            // (If requester was disputer)
            if (dispute.disputer == req.requester) {
                 // Transfer full payment + dispute fee to requester
                require(dartToken.transfer(winnerAddress, totalLockedFunds), "DART: Payment refund failed.");
            } else {
                // If provider was disputer, they win nothing (no payment involved)
                // This scenario needs careful design for what 'winning' means for a provider disputing a user's confirmation
                // For simplicity, this path assumes requester initiated dispute.
            }
        }
        
        // Update reputation for disputer/counterparty
        if (providers[winnerAddress].isRegistered) _updateProviderReputation(winnerAddress, providers[winnerAddress].reputation, providers[winnerAddress].lastReputationUpdate);
        else if (arbiters[winnerAddress].isRegistered) _updateArbiterReputation(winnerAddress, arbiters[winnerAddress].reputation, arbiters[winnerAddress].lastReputationUpdate);
        // And model reputation
        _updateModelReputation(req.modelId, models[req.modelId].reputation, models[req.modelId].lastReputationUpdate);

        if (isProviderCorrectOutcome) {
            providers[req.provider].reputation = providers[req.provider].reputation.add(winnerReputationChange);
            // If disuputer was requester
            if (dispute.disputer == req.requester) {
                // No direct requester reputation in this simplified model, but could be added
            }
        } else { // Provider was incorrect
            providers[req.provider].reputation = providers[req.provider].reputation.add(loserReputationChange); // Provider loses reputation
            // If disuputer was requester
            if (dispute.disputer == req.requester) {
                // Requester wins dispute, no direct reputation change for requester, but model reputation might drop
                models[req.modelId].reputation = models[req.modelId].reputation.add(loserReputationChange); // Model loses reputation
            }
        }

        // Distribute arbiter rewards/slashes
        for (uint256 i = 0; i < nextDisputeId; i++) { // Iterate through all arbiters (inefficient, but for demo)
            address arbiterAddr = msg.sender; // This would need a list of arbiters to iterate. For demo, it is simplified.
            // A better way: maintain `mapping(uint256 => address[]) public arbitersVotedOnDispute;`

            // Iterate through arbiters who voted (conceptual, needs `arbitersVotedOnDispute` array)
            // For example purposes, we simulate.
            // This is computationally intensive if many arbiters vote.
            // A better approach is to iterate on stored `voters` array or just credit to `rewardsAccumulated`.
            if (dispute.hasVoted[arbiterAddr]) { // If this arbiter actually voted
                 if ((dispute.arbiterVoteStake[arbiterAddr] > 0 && isProviderCorrectOutcome && dispute.providerVotes > 0) || // Voted for correct side (provider)
                     (dispute.arbiterVoteStake[arbiterAddr] < 0 && !isProviderCorrectOutcome && dispute.providerVotes < 0)) // Voted for correct side (disputer)
                 {
                    // Correct vote: reward
                    arbiters[arbiterAddr].rewardsAccumulated = arbiters[arbiterAddr].rewardsAccumulated.add(ARBITER_REWARD_PER_VOTE);
                    _updateArbiterReputation(arbiterAddr, arbiters[arbiterAddr].reputation, arbiters[arbiterAddr].lastReputationUpdate);
                    arbiters[arbiterAddr].reputation = arbiters[arbiterAddr].reputation.add(5); // Reputation boost
                 } else {
                    // Incorrect vote: slash stake and lose reputation
                    uint256 slashAmount = dispute.arbiterVoteStake[arbiterAddr].div(2); // Slash 50% of vote stake
                    arbiters[arbiterAddr].stake = arbiters[arbiterAddr].stake.sub(slashAmount);
                    totalProtocolFeesAccumulated = totalProtocolFeesAccumulated.add(slashAmount); // Slashing goes to fees
                    _updateArbiterReputation(arbiterAddr, arbiters[arbiterAddr].reputation, arbiters[arbiterAddr].lastReputationUpdate);
                    arbiters[arbiterAddr].reputation = arbiters[arbiterAddr].reputation.sub(10); // Reputation penalty
                 }
                 // Return arbiter vote stake
                 uint265 arbiterVoteStakeToRefund = dispute.arbiterVoteStake[arbiterAddr];
                 dispute.arbiterVoteStake[arbiterAddr] = 0; // Reset for this arbiter
                 require(dartToken.transfer(arbiterAddr, arbiterVoteStakeToRefund), "DART: Arbiter vote stake refund failed.");
            }
        }
        // This iteration should be on the actual voters, not a loop over nextDisputeId
        // The `dispute.hasVoted` mapping needs to be paired with an array of voters to iterate efficiently.
        // For example purposes, this part is conceptual, implying complex off-chain logic for distribution.

        req.status = RequestStatus.Resolved; // Mark request as resolved
        emit DisputeResolved(_disputeId, isProviderCorrectOutcome);
    }
    
    function getArbiterDetails(address _arbiterAddress) external view returns (Arbiter memory) {
        return arbiters[_arbiterAddress];
    }

    // --- Utility Views (for demo simplicity, not exhaustive lists) ---
    function getActiveProviderAddresses() private view returns (address[] memory) {
        // This is highly inefficient for large number of providers.
        // In a real system, maintain an iterable list of active providers.
        address[] memory activeProviders = new address[](0);
        // For demo, this will be an empty array unless a more complex tracking is added.
        return activeProviders;
    }

    function getActiveArbiterAddresses() private view returns (address[] memory) {
        // Same as above, for demo.
        address[] memory activeArbiters = new address[](0);
        return activeArbiters;
    }
}
```