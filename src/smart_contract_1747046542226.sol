Okay, here is a smart contract designed around a "Decentralized AI Oracle with ZK Proof Hints".

This concept is advanced because:
1.  **It's a multi-party oracle:** Data isn't from a single source but from multiple decentralized AI providers.
2.  **It handles arbitrary AI tasks:** Not just price feeds, but results from specific AI models (defined by governance).
3.  **It incorporates a consensus mechanism:** Results from multiple providers are compared to reach a trusted output.
4.  **It integrates a ZK Proof 'Hint':** Providers can submit a hash referencing a Zero-Knowledge Proof calculated off-chain. The contract *doesn't verify the ZK proof itself* (that's usually too complex/expensive on-chain without specific precompiles or dedicated verifiers), but the *presence* and *challenge status* of this proof hash can be used in the protocol's logic (e.g., higher trust, required for certain tasks, slashable if proven false later). It's a signal for off-chain verification.
5.  **It includes staking and slashing:** Providers stake tokens, which can be slashed for malicious behavior (like submitting incorrect results or invalid proof hashes if proven off-chain).
6.  **It has a basic governance structure:** Allowing updates to supported AI models and protocol parameters.

It aims to be non-duplicative by combining these specific elements into a single system for generalized AI computation results.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DecentralizedAIOracle
 * @dev A decentralized oracle network for obtaining results from AI models.
 *      Providers stake tokens, compute off-chain, and submit results with optional ZK proof hashes.
 *      Requests are processed via a multi-provider consensus mechanism, with staking and slashing
 *      for reliability. Governance manages supported AI models and parameters.
 */
contract DecentralizedAIOracle is Ownable, ReentrancyGuard {

    // --- Outline ---
    // 1. State Variables: Store contract configuration, provider data, request data, etc.
    // 2. Structs: Define data structures for Providers, Requests, and Results.
    // 3. Enums: Define states for requests.
    // 4. Events: Log important contract actions.
    // 5. Modifiers: Control access and enforce conditions.
    // 6. Provider Management: Register, update, deregister, stake management for AI providers.
    // 7. Request Management: Users request data, check status, claim results.
    // 8. Result Submission & Verification: Providers submit results and ZK proof hashes.
    // 9. Consensus & Finalization: Tally results, reach consensus, finalize requests, distribute rewards/slashes.
    // 10. Challenge Mechanism: Allow challenging results or proofs.
    // 11. Governance: Add/remove AI models, update parameters, resolve challenges.
    // 12. View Functions: Read contract state.

    // --- Function Summary ---
    // Provider Management:
    // 1.  registerProvider(uint[] calldata modelIds, string calldata infoLink): Stake tokens and register as a provider.
    // 2.  updateProviderInfo(string calldata infoLink): Update provider metadata.
    // 3.  deregisterProvider(): Initiate the stake withdrawal process.
    // 4.  withdrawStake(): Complete stake withdrawal after the cooldown period.
    // 5.  providerHeartbeat(): Signal liveness of a provider.
    // 6.  updateSupportedModels(uint[] calldata modelIds): Update the list of models a provider supports.
    // Request Management (User):
    // 7.  requestOracleData(uint modelId, bytes32 inputDataHash): Submit a request for AI data, paying a fee.
    // 8.  cancelRequest(uint requestId): Cancel a request before processing starts.
    // 9.  claimRequestOutput(uint requestId): (Conceptual - Output is read via view function). No-op function to mark user acknowledgement.
    // Result Submission & Verification (Provider):
    // 10. submitResult(uint requestId, bytes32 outputDataHash): Submit the AI computation result hash.
    // 11. submitVerificationProof(uint requestId, bytes32 zkProofHash): Submit the hash of an off-chain ZK proof for the result.
    // Consensus & Finalization:
    // 12. tallyResults(uint requestId): Trigger the tallying process to find consensus.
    // 13. finalizeRequest(uint requestId): Finalize a request after consensus or challenge resolution, distributing rewards/slashes.
    // Challenge Mechanism:
    // 14. challengeResult(uint requestId, address providerAddress, string calldata reason): Challenge a specific provider's result or proof. Requires a challenge bond.
    // 15. resolveChallenge(uint requestId, address challengedProvider, bool providerWasCorrect): (Governance/Trusted Call) Resolve a challenge based on off-chain verification, handling bonds and slashing.
    // Governance (Requires `onlyGovernance`):
    // 16. addSupportedModel(uint modelId, string calldata modelInfo, bytes calldata parameters): Add a new AI model definition.
    // 17. removeSupportedModel(uint modelId): Remove a supported AI model.
    // 18. setParameters(uint _quorumSize, uint _consensusThreshold, uint _submissionPeriod, uint _verificationPeriod, uint _challengePeriod, uint _oracleFee, uint _minStakeAmount, uint _deregistrationCooldown): Update core protocol parameters.
    // 19. setGovernanceAddress(address newGovernance): Change the address authorized for governance actions.
    // 20. distributeReward(uint requestId, address providerAddress, uint amount): (Internal/Governance Call) Distribute reward to a specific provider. Called by finalizeRequest.
    // 21. slashStake(address providerAddress, uint amount): (Internal/Governance Call) Slash stake from a provider. Called by resolveChallenge.
    // View Functions:
    // 22. getProvider(address providerAddress): Get details of a provider.
    // 23. getActiveProviders(uint modelId): Get list of active providers supporting a model.
    // 24. getRequestStatus(uint requestId): Get the current state of a request.
    // 25. getRequestDetails(uint requestId): Get full details of a request.
    // 26. getResult(uint requestId, address providerAddress): Get a specific provider's result for a request.
    // 27. getSupportedModels(): Get list of supported model IDs.
    // 28. getModelDetails(uint modelId): Get details for a specific supported model.
    // 29. getOracleFee(): Get the current request fee.
    // 30. getMinStakeAmount(): Get the minimum required stake for providers.
    // 31. getProviderStake(address provider): Get a provider's current staked amount.
    // 32. getRewardPoolBalance(): Get the contract's current balance in the stake token.

    // --- State Variables ---
    IERC20 public stakeToken;
    address public governanceAddress; // Address authorized for governance actions

    uint public minStakeAmount;
    uint public oracleFee; // Fee per request in stakeToken units

    uint public quorumSize; // Minimum number of providers needed for consensus calculation
    uint public consensusThreshold; // Percentage (0-100) of providers needed to agree on a result hash for consensus

    uint public submissionPeriod; // Time window (seconds) for providers to submit results
    uint public verificationPeriod; // Time window (seconds) for providers to submit ZK proof hashes
    uint public challengePeriod; // Time window (seconds) to challenge results after tally
    uint public deregistrationCooldown; // Time window (seconds) before stake can be withdrawn after deregistering

    uint public nextRequestId = 1; // Counter for unique request IDs

    mapping(address => Provider) public providers;
    address[] public activeProviderAddresses; // Simple array - might be inefficient for many providers
    mapping(uint => Request) public requests;
    mapping(uint => mapping(address => Result)) public results; // requestId => providerAddress => Result

    mapping(uint => SupportedModel) public supportedModels; // modelId => SupportedModel details
    uint[] public supportedModelIds;

    // --- Structs ---
    struct Provider {
        uint stakedAmount;
        bool isActive; // Becomes false after deregistration initiated
        uint deregistrationTime; // Timestamp when deregistration was initiated
        uint lastHeartbeat;
        string infoLink; // Link to off-chain info about the provider
        uint[] registeredModels; // IDs of models provider claims to support
    }

    enum RequestState {
        None,              // Initial state (should not be used for valid requests)
        Requested,         // Request submitted, awaiting provider submission
        SubmittingResults, // Within the result submission window
        VerifyingResults,  // Within the ZK proof hash submission window
        Tallying,          // Results are being tallied (internal transition state)
        ConsensusReached,  // Consensus achieved on a result hash
        NoConsensus,       // No consensus reached within the period
        Challenged,        // The consensus result or specific provider result is challenged
        ResolvingChallenge,// Challenge is being resolved (internal transition state)
        Completed,         // Request processed successfully, results finalized
        Failed             // Request failed for any reason (e.g., cancelled, no providers, no consensus, unresolved challenge)
    }

    struct Request {
        address requester;
        uint modelId;
        bytes32 inputDataHash; // Hash reference to off-chain input data
        uint feePaid; // Amount paid by the requester
        uint requestTime;
        uint submissionDeadline;
        uint verificationDeadline;
        uint challengeDeadline;
        RequestState state;
        bytes32 winningResultHash; // The hash that reached consensus
        address[] participatingProviders; // Providers who submitted results
        address[] challengingProviders; // Providers/users who issued challenges
        bool needsChallengeResolution; // Set to true if challenges are active/unresolved
    }

    struct Result {
        address provider;
        bytes32 outputDataHash; // Hash reference to off-chain output data
        uint submissionTime;
        bytes32 zkProofHash; // Hash reference to off-chain ZK proof
        uint verificationTime; // Timestamp proof was submitted
        bool wasChallenged; // True if this specific result/proof was challenged
    }

    struct SupportedModel {
        string modelInfo; // Description or link to model details
        bytes parameters; // ABI-encoded parameters specific to the model
        bool isSupported; // Whether the model is currently active
    }

    // --- Events ---
    event ProviderRegistered(address indexed provider, uint stakedAmount, uint[] modelIds);
    event ProviderDeregistered(address indexed provider, uint deregistrationTime);
    event StakeWithdrawn(address indexed provider, uint amount);
    event ProviderHeartbeat(address indexed provider, uint timestamp);
    event SupportedModelsUpdated(address indexed provider, uint[] modelIds);

    event RequestCreated(uint indexed requestId, address indexed requester, uint modelId, bytes32 inputDataHash, uint feePaid);
    event RequestCancelled(uint indexed requestId);
    event RequestStateChanged(uint indexed requestId, RequestState newState);

    event ResultSubmitted(uint indexed requestId, address indexed provider, bytes32 outputDataHash);
    event VerificationProofSubmitted(uint indexed requestId, address indexed provider, bytes32 zkProofHash);

    event ConsensusReached(uint indexed requestId, bytes32 winningResultHash);
    event NoConsensus(uint indexed requestId);
    event RequestFinalized(uint indexed requestId, RequestState finalState, bytes32 finalResultHash);

    event ChallengeIssued(uint indexed requestId, address indexed challenger, address indexed challengedProvider, string reason);
    event ChallengeResolved(uint indexed requestId, address indexed challengedProvider, bool providerWasCorrect);

    event ModelAdded(uint indexed modelId, string modelInfo);
    event ModelRemoved(uint indexed modelId);
    event ParametersUpdated(uint quorum, uint threshold, uint submission, uint verification, uint challenge, uint fee, uint minStake, uint cooldown);
    event GovernanceAddressSet(address indexed oldGovernance, address indexed newGovernance);

    event StakeSlashed(address indexed provider, uint amount);
    event RewardDistributed(address indexed provider, uint amount);

    // --- Modifiers ---
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Not governance");
        _;
    }

    modifier onlyActiveProvider() {
        Provider storage provider = providers[msg.sender];
        require(provider.stakedAmount >= minStakeAmount, "Provider has insufficient stake");
        require(provider.isActive, "Provider is not active");
        _;
    }

    modifier onlyRequester(uint _requestId) {
        require(requests[_requestId].requester == msg.sender, "Not the requester");
        _;
    }

    modifier requestExists(uint _requestId) {
        require(requests[_requestId].state != RequestState.None, "Request does not exist");
        _;
    }

    modifier requestInState(uint _requestId, RequestState _state) {
        require(requests[_requestId].state == _state, "Request not in expected state");
        _;
    }

    // --- Constructor ---
    constructor(
        address _stakeTokenAddress,
        uint _minStakeAmount,
        uint _oracleFee,
        uint _quorumSize,
        uint _consensusThreshold, // e.g., 60 for 60%
        uint _submissionPeriod,
        uint _verificationPeriod,
        uint _challengePeriod,
        uint _deregistrationCooldown
    ) Ownable(msg.sender) {
        require(_stakeTokenAddress != address(0), "Stake token address cannot be zero");
        stakeToken = IERC20(_stakeTokenAddress);
        governanceAddress = msg.sender; // Initially set governance to deployer

        minStakeAmount = _minStakeAmount;
        oracleFee = _oracleFee;
        quorumSize = _quorumSize;
        consensusThreshold = _consensusThreshold;
        submissionPeriod = _submissionPeriod;
        verificationPeriod = _verificationPeriod;
        challengePeriod = _challengePeriod;
        deregistrationCooldown = _deregistrationCooldown;
    }

    // --- Provider Management ---

    /**
     * @dev Providers stake tokens and register to participate in the network.
     * @param modelIds The IDs of the AI models the provider is capable of running.
     * @param infoLink Off-chain link for more info about the provider.
     */
    function registerProvider(uint[] calldata modelIds, string calldata infoLink) external nonReentrant {
        Provider storage provider = providers[msg.sender];
        require(!provider.isActive, "Provider is already active");
        require(stakeToken.balanceOf(msg.sender) >= minStakeAmount, "Insufficient token balance for stake");
        require(stakeToken.allowance(msg.sender, address(this)) >= minStakeAmount, "Insufficient token allowance");
        require(modelIds.length > 0, "Must support at least one model");

        // Check if supported models exist
        for(uint i=0; i < modelIds.length; i++) {
            require(supportedModels[modelIds[i]].isSupported, "Unsupported model ID");
        }

        if (provider.stakedAmount == 0) {
             // First time registration, transfer stake
            bool success = stakeToken.transferFrom(msg.sender, address(this), minStakeAmount);
            require(success, "Stake transfer failed");
            provider.stakedAmount = minStakeAmount;
        } else {
             // Re-registering after deregistration (stake already held)
            require(provider.stakedAmount >= minStakeAmount, "Existing stake too low");
        }

        provider.isActive = true;
        provider.deregistrationTime = 0; // Reset cooldown
        provider.lastHeartbeat = block.timestamp;
        provider.infoLink = infoLink;
        provider.registeredModels = modelIds;

        activeProviderAddresses.push(msg.sender); // Naive list, consider indexed list or similar for scale

        emit ProviderRegistered(msg.sender, provider.stakedAmount, modelIds);
    }

    /**
     * @dev Allows a provider to update their off-chain info link.
     * @param infoLink New off-chain link.
     */
    function updateProviderInfo(string calldata infoLink) external onlyActiveProvider {
        providers[msg.sender].infoLink = infoLink;
    }

    /**
     * @dev Allows a provider to update the list of models they support.
     * @param modelIds The new list of supported model IDs.
     */
    function updateSupportedModels(uint[] calldata modelIds) external onlyActiveProvider {
         for(uint i=0; i < modelIds.length; i++) {
            require(supportedModels[modelIds[i]].isSupported, "Unsupported model ID");
        }
        providers[msg.sender].registeredModels = modelIds;
        emit SupportedModelsUpdated(msg.sender, modelIds);
    }


    /**
     * @dev Initiates the deregistration process for a provider.
     *      Stake cannot be withdrawn until the cooldown period passes.
     */
    function deregisterProvider() external onlyActiveProvider {
        Provider storage provider = providers[msg.sender];
        provider.isActive = false;
        provider.deregistrationTime = block.timestamp;

        // Remove from active list (inefficient for large arrays)
        for (uint i = 0; i < activeProviderAddresses.length; i++) {
            if (activeProviderAddresses[i] == msg.sender) {
                activeProviderAddresses[i] = activeProviderAddresses[activeProviderAddresses.length - 1];
                activeProviderAddresses.pop();
                break;
            }
        }

        emit ProviderDeregistered(msg.sender, block.timestamp);
    }

    /**
     * @dev Allows a provider to withdraw their stake after the deregistration cooldown.
     */
    function withdrawStake() external nonReentrant {
        Provider storage provider = providers[msg.sender];
        require(!provider.isActive, "Provider must be deregistered");
        require(provider.stakedAmount > 0, "Provider has no stake");
        require(provider.deregistrationTime > 0, "Deregistration not initiated");
        require(block.timestamp >= provider.deregistrationTime + deregistrationCooldown, "Deregistration cooldown not passed");

        uint amount = provider.stakedAmount;
        provider.stakedAmount = 0;
        provider.deregistrationTime = 0; // Reset

        bool success = stakeToken.transfer(msg.sender, amount);
        require(success, "Stake withdrawal failed");

        emit StakeWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Providers call this periodically to signal liveness.
     */
    function providerHeartbeat() external onlyActiveProvider {
        providers[msg.sender].lastHeartbeat = block.timestamp;
        emit ProviderHeartbeat(msg.sender, block.timestamp);
    }

    // --- Request Management (User) ---

    /**
     * @dev Submits a request for AI data from a specific model.
     *      Requires payment of the oracle fee.
     * @param modelId The ID of the desired AI model.
     * @param inputDataHash A hash referencing the off-chain input data.
     */
    function requestOracleData(uint modelId, bytes32 inputDataHash) external nonReentrant {
        require(supportedModels[modelId].isSupported, "Unsupported model ID");
        require(oracleFee > 0, "Oracle fee must be greater than zero");
        require(stakeToken.balanceOf(msg.sender) >= oracleFee, "Insufficient token balance for fee");
        require(stakeToken.allowance(msg.sender, address(this)) >= oracleFee, "Insufficient token allowance for fee");

        uint currentRequestId = nextRequestId++;
        uint reqTime = block.timestamp;

        requests[currentRequestId] = Request({
            requester: msg.sender,
            modelId: modelId,
            inputDataHash: inputDataHash,
            feePaid: oracleFee,
            requestTime: reqTime,
            submissionDeadline: reqTime + submissionPeriod,
            verificationDeadline: reqTime + submissionPeriod + verificationPeriod,
            challengeDeadline: 0, // Set after consensus
            state: RequestState.Requested,
            winningResultHash: bytes32(0),
            participatingProviders: new address[](0),
            challengingProviders: new address[](0),
            needsChallengeResolution: false
        });

        // Transfer fee to the contract's reward pool
        bool success = stakeToken.transferFrom(msg.sender, address(this), oracleFee);
        require(success, "Fee transfer failed");

        emit RequestCreated(currentRequestId, msg.sender, modelId, inputDataHash, oracleFee);
        emit RequestStateChanged(currentRequestId, RequestState.Requested);
    }

    /**
     * @dev Allows the requester to cancel their request if it hasn't passed the submission deadline.
     * @param requestId The ID of the request to cancel.
     */
    function cancelRequest(uint requestId) external nonReentrant requestExists(requestId) onlyRequester(requestId) {
        Request storage req = requests[requestId];
        require(req.state <= RequestState.SubmittingResults, "Request is too far into processing to cancel");
        require(block.timestamp < req.submissionDeadline, "Submission window has closed");

        // Refund the fee
        uint fee = req.feePaid;
        req.feePaid = 0; // Prevent double refund
        bool success = stakeToken.transfer(req.requester, fee);
        require(success, "Fee refund failed");

        req.state = RequestState.Failed; // Mark as failed due to cancellation

        emit RequestCancelled(requestId);
        emit RequestStateChanged(requestId, RequestState.Failed);
    }

    /**
     * @dev Conceptual function for the requester to acknowledge they have the result.
     *      Doesn't perform any state changes beyond marking completion if needed.
     *      In this design, results are read via `getConsensusResult` or similar view functions.
     * @param requestId The ID of the request.
     */
    function claimRequestOutput(uint requestId) external requestExists(requestId) onlyRequester(requestId) {
        // This function is mostly symbolic. The requester reads the state and result hash off-chain.
        // Could potentially add a state like RequestState.Claimed if needed for tracking.
        // require(requests[requestId].state == RequestState.Completed, "Request not completed");
        // (Optional) Add logic to mark the request as 'claimed' by the requester
        // requests[requestId].isClaimed = true;
        // event RequestClaimed(uint indexed requestId, address indexed requester);
    }


    // --- Result Submission & Verification (Provider) ---

    /**
     * @dev Allows an active provider to submit their AI result for a request.
     * @param requestId The ID of the request.
     * @param outputDataHash A hash referencing the off-chain output data.
     */
    function submitResult(uint requestId, bytes32 outputDataHash) external onlyActiveProvider requestExists(requestId) {
        Request storage req = requests[requestId];
        require(req.state == RequestState.Requested || req.state == RequestState.SubmittingResults, "Request is not in result submission phase");
        require(block.timestamp < req.submissionDeadline, "Submission window has closed");

        // Ensure provider supports the requested model
        bool supportsModel = false;
        uint[] storage providerModels = providers[msg.sender].registeredModels;
        for(uint i=0; i < providerModels.length; i++) {
            if (providerModels[i] == req.modelId) {
                supportsModel = true;
                break;
            }
        }
        require(supportsModel, "Provider does not support this model");

        // Ensure provider hasn't already submitted
        require(results[requestId][msg.sender].submissionTime == 0, "Provider already submitted result");

        results[requestId][msg.sender] = Result({
            provider: msg.sender,
            outputDataHash: outputDataHash,
            submissionTime: block.timestamp,
            zkProofHash: bytes32(0), // Proof submitted separately
            verificationTime: 0,
            wasChallenged: false
        });

        req.participatingProviders.push(msg.sender); // Add provider to list for this request

        // If state is still Requested, move to SubmittingResults
        if (req.state == RequestState.Requested) {
             req.state = RequestState.SubmittingResults;
             emit RequestStateChanged(requestId, RequestState.SubmittingResults);
        }

        emit ResultSubmitted(requestId, msg.sender, outputDataHash);
    }

    /**
     * @dev Allows an active provider to submit a hash referencing an off-chain ZK proof for their result.
     * @param requestId The ID of the request.
     * @param zkProofHash A hash referencing the off-chain ZK proof data.
     */
    function submitVerificationProof(uint requestId, bytes32 zkProofHash) external onlyActiveProvider requestExists(requestId) {
        Request storage req = requests[requestId];
        require(req.state == RequestState.SubmittingResults || req.state == RequestState.VerifyingResults, "Request is not in verification phase");
        require(block.timestamp < req.verificationDeadline, "Verification window has closed");

        Result storage result = results[requestId][msg.sender];
        require(result.submissionTime > 0, "Provider must submit a result first");
        require(result.zkProofHash == bytes32(0), "Provider already submitted proof hash");
        require(zkProofHash != bytes32(0), "ZK Proof hash cannot be zero");

        result.zkProofHash = zkProofHash;
        result.verificationTime = block.timestamp;

         // If state is still SubmittingResults (end of period might transition here), move to VerifyingResults
        if (req.state == RequestState.SubmittingResults && block.timestamp >= req.submissionDeadline) {
             req.state = RequestState.VerifyingResults;
             emit RequestStateChanged(requestId, RequestState.VerifyingResults);
        } else if (req.state == RequestState.Requested) {
             // Should not happen if submitResult is called first, but as a fallback
             req.state = RequestState.VerifyingResults;
             emit RequestStateChanged(requestId, RequestState.VerifyingResults);
        }


        emit VerificationProofSubmitted(requestId, msg.sender, zkProofHash);
    }

    // --- Consensus & Finalization ---

    /**
     * @dev Can be called by anyone after the verification deadline to tally results and find consensus.
     * @param requestId The ID of the request.
     */
    function tallyResults(uint requestId) external nonReentrant requestExists(requestId) {
        Request storage req = requests[requestId];
        require(req.state >= RequestState.SubmittingResults && req.state < RequestState.ConsensusReached, "Request not in tallying phase");
        require(block.timestamp >= req.verificationDeadline, "Verification window is still open");

        // Move state to VerifyingResults if still in SubmittingResults
         if (req.state == RequestState.SubmittingResults) {
             req.state = RequestState.VerifyingResults;
             emit RequestStateChanged(requestId, RequestState.VerifyingResults);
         }

        // Check if it's past the verification deadline
        require(block.timestamp >= req.verificationDeadline, "Cannot tally before verification deadline");


        uint participatingCount = req.participatingProviders.length;

        if (participatingCount < quorumSize) {
            req.state = RequestState.NoConsensus;
            emit NoConsensus(requestId);
            emit RequestStateChanged(requestId, RequestState.NoConsensus);
            return;
        }

        // Tallying logic: Count votes for each unique output hash
        mapping(bytes32 => uint) voteCounts;
        bytes32 mostVotedHash = bytes32(0);
        uint maxVotes = 0;

        for (uint i = 0; i < participatingCount; i++) {
            address providerAddr = req.participatingProviders[i];
            Result storage result = results[requestId][providerAddr];

            // Only count results that were submitted
            if (result.submissionTime > 0) {
                voteCounts[result.outputDataHash]++;

                // Simple majority wins - first one to reach max votes
                if (voteCounts[result.outputDataHash] > maxVotes) {
                    maxVotes = voteCounts[result.outputDataHash];
                    mostVotedHash = result.outputDataHash;
                }
                // TODO: Add tie-breaking logic if needed
            }
        }

        // Check if consensus threshold is met
        // Note: Integer division, multiply before divide
        if (maxVotes * 100 >= participatingCount * consensusThreshold && mostVotedHash != bytes32(0)) {
            req.state = RequestState.ConsensusReached;
            req.winningResultHash = mostVotedHash;
            req.challengeDeadline = block.timestamp + challengePeriod; // Set challenge deadline
            emit ConsensusReached(requestId, mostVotedHash);
            emit RequestStateChanged(requestId, RequestState.ConsensusReached);
        } else {
            req.state = RequestState.NoConsensus;
            emit NoConsensus(requestId);
            emit RequestStateChanged(requestId, RequestState.NoConsensus);
        }
    }

    /**
     * @dev Finalizes a request after the challenge period ends (if consensus was reached).
     *      Distributes rewards or marks as failed if no consensus/challenge unresolved.
     *      Can be called by anyone after the challenge deadline.
     * @param requestId The ID of the request to finalize.
     */
    function finalizeRequest(uint requestId) external nonReentrant requestExists(requestId) {
        Request storage req = requests[requestId];

        // Handle cases where finalize is called after tally but state is not ConsensusReached
         if (req.state == RequestState.SubmittingResults || req.state == RequestState.VerifyingResults) {
             // If deadlines passed but tally wasn't called
             if (block.timestamp >= req.verificationDeadline) {
                 // Try to tally first if not already done
                 tallyResults(requestId); // This might transition state to ConsensusReached or NoConsensus
             } else {
                 revert("Cannot finalize before verification deadline");
             }
         }


        // Now check the state after potential tallying
        if (req.state == RequestState.ConsensusReached) {
             require(block.timestamp >= req.challengeDeadline, "Challenge window is still open");
             require(!req.needsChallengeResolution, "Challenges require manual resolution by governance");

            // Distribute rewards to providers who submitted the winning hash
            uint rewardAmount = req.feePaid; // Simple model: fee is distributed

            address[] memory winningProviders;
            uint winningProviderCount = 0;

            // First pass to count and identify winning providers
            for (uint i = 0; i < req.participatingProviders.length; i++) {
                address providerAddr = req.participatingProviders[i];
                Result storage result = results[requestId][providerAddr];
                if (result.submissionTime > 0 && result.outputDataHash == req.winningResultHash) {
                     winningProviderCount++;
                }
            }

            // If there are winning providers, prepare the array
             if (winningProviderCount > 0) {
                 winningProviders = new address[](winningProviderCount);
                 uint index = 0;
                 for (uint i = 0; i < req.participatingProviders.length; i++) {
                     address providerAddr = req.participatingProviders[i];
                     Result storage result = results[requestId][providerAddr];
                     if (result.submissionTime > 0 && result.outputDataHash == req.winningResultHash) {
                          winningProviders[index++] = providerAddr;
                     }
                 }
             }


            // Distribute reward (only if there are winning providers to receive it)
            if (winningProviderCount > 0) {
                 uint rewardPerProvider = rewardAmount / winningProviderCount;
                 for (uint i = 0; i < winningProviderCount; i++) {
                      distributeReward(requestId, winningProviders[i], rewardPerProvider);
                 }
            } else {
                 // No providers submitted the winning hash? Should not happen if ConsensusReached, but handle defensively.
                 // Refund fee to requester or leave in contract? Leave in contract for now.
            }


            req.state = RequestState.Completed;
            emit RequestFinalized(requestId, RequestState.Completed, req.winningResultHash);

        } else if (req.state == RequestState.NoConsensus) {
            // No consensus reached, request fails
            req.state = RequestState.Failed;
            emit RequestFinalized(requestId, RequestState.Failed, bytes32(0));

        } else if (req.state == RequestState.Challenged || req.needsChallengeResolution) {
             // If challenges were issued and not resolved, request is stalled/failed
             // Governance needs to call resolveChallenge
             req.state = RequestState.Failed; // Mark as failed if governance doesn't resolve in time? Or just leave as challenged?
             // Let's leave as Challenged, requiring governance action to move forward.
             revert("Request is challenged and requires governance resolution.");

        } else {
             // Any other state means it's not ready to be finalized
             revert("Request is not in a finalizable state (ConsensusReached, NoConsensus, or needs challenge resolution)");
        }
    }


    // --- Challenge Mechanism ---

    /**
     * @dev Allows anyone to challenge a specific provider's result or ZK proof hash for a request.
     *      Requires staking a challenge bond.
     * @param requestId The ID of the request.
     * @param challengedProvider The address of the provider whose result/proof is challenged.
     * @param reason A string describing the reason for the challenge (e.g., link to off-chain evidence).
     */
    function challengeResult(uint requestId, address challengedProvider, string calldata reason) external nonReentrant requestExists(requestId) {
        Request storage req = requests[requestId];
        Result storage result = results[requestId][challengedProvider];

        require(req.state == RequestState.ConsensusReached, "Request is not in the challengeable state");
        require(block.timestamp < req.challengeDeadline, "Challenge window has closed");
        require(result.submissionTime > 0, "Challenged provider did not submit a result");
        require(!result.wasChallenged, "This specific result has already been challenged");

        // Require a challenge bond (e.g., a small amount of the stake token)
        // This bond is used to reward governance/validators if the challenge is upheld,
        // or returned to the challenger if upheld, or given to the provider if dismissed.
        // Simple version: Bond amount is hardcoded or a parameter. Let's use a small percentage of oracleFee or minStake.
        uint challengeBond = oracleFee / 2; // Example bond amount

        require(stakeToken.balanceOf(msg.sender) >= challengeBond, "Insufficient token balance for challenge bond");
        require(stakeToken.allowance(msg.sender, address(this)) >= challengeBond, "Insufficient token allowance for challenge bond");

        bool success = stakeToken.transferFrom(msg.sender, address(this), challengeBond);
        require(success, "Challenge bond transfer failed");

        result.wasChallenged = true;
        req.state = RequestState.Challenged; // Move request state to Challenged
        req.needsChallengeResolution = true; // Mark that governance needs to act
        req.challengingProviders.push(msg.sender); // Add challenger to list

        // Store challenge bond amount related to this challenge? Or just track that a bond was paid?
        // For simplicity, the bond is held by the contract and handled during resolution.
        // A more complex system might need a mapping for bond amounts per challenge.

        emit ChallengeIssued(requestId, msg.sender, challengedProvider, reason);
        emit RequestStateChanged(requestId, RequestState.Challenged);
    }

    /**
     * @dev Called by governance to resolve a challenge after off-chain verification.
     *      Handles redistribution of the challenge bond and potential slashing.
     * @param requestId The ID of the request.
     * @param challengedProvider The address of the provider who was challenged.
     * @param providerWasCorrect True if the challenged provider's result/proof was deemed correct, false otherwise.
     */
    function resolveChallenge(uint requestId, address challengedProvider, bool providerWasCorrect) external onlyGovernance nonReentrant requestExists(requestId) {
        Request storage req = requests[requestId];
        Result storage result = results[requestId][challengedProvider];

        require(req.state == RequestState.Challenged || req.needsChallengeResolution, "Request not in challenged state");
        require(result.wasChallenged, "Provider's result was not challenged");

        // Challenge bond amount (needs to be tracked, let's assume it's the oracleFee/2 from challengeResult)
        uint challengeBond = oracleFee / 2;

        // Find the original challenger for this specific result (can be multiple if multiple results challenged)
        // Simple: just use the *first* challenger listed for the request for now, or require specific challenger address
        // More complex: need mapping from challenge event/ID to bond holder.
        // Let's assume the first challenger in the list is the one whose bond is relevant here.
        address challengerAddress = req.challengingProviders.length > 0 ? req.challengingProviders[0] : address(0);
         require(challengerAddress != address(0), "No challenger recorded for this request"); // Or requires parameter

        if (providerWasCorrect) {
            // Challenger was wrong, provider was correct. Provider keeps their stake, challenger loses bond.
            // Bond stays in the contract (e.g., added to reward pool or governance decides).
            // Let's add it to the reward pool for simplicity.
             // No need to explicitly move bond, it's already in contract balance.
        } else {
            // Challenger was correct, provider was wrong.
            // Slash provider's stake. Amount could be the challenge bond, or a fixed penalty, or related to staked amount.
            // Simple: slash an amount equal to the challenge bond from the provider's stake.
            uint slashAmount = challengeBond; // Example slash amount
            slashStake(challengedProvider, slashAmount);

            // Return bond to the challenger.
            bool success = stakeToken.transfer(challengerAddress, challengeBond);
            require(success, "Challenger bond refund failed");
        }

        result.wasChallenged = false; // Mark this specific result's challenge as resolved

        // Check if there are other unresolved challenges for this request
        bool anyRemainingChallenges = false;
        for (uint i = 0; i < req.participatingProviders.length; i++) {
            address providerAddr = req.participatingProviders[i];
            if (results[requestId][providerAddr].wasChallenged) {
                anyRemainingChallenges = true;
                break;
            }
        }

        if (!anyRemainingChallenges) {
            // All specific result challenges resolved for this request
            req.needsChallengeResolution = false;
            // Move request state back to ConsensusReached (to allow finalization) or Failed if overall outcome warrants
             if (req.state == RequestState.Challenged) { // Only if the request state was explicitly set to Challenged
                 // If the winning result was challenged and proven wrong, the consensus is invalid.
                 // Mark request as failed. If a non-winning result was challenged, consensus might still stand.
                 // This logic is complex. Simple: If ANY challenge was upheld (providerWasCorrect=false), request fails.
                 if (!providerWasCorrect) {
                      req.state = RequestState.Failed;
                      emit RequestStateChanged(requestId, RequestState.Failed);
                 } else {
                     // All resolved challenges resulted in provider being correct
                      req.state = RequestState.ConsensusReached; // Allow finalization
                      emit RequestStateChanged(requestId, RequestState.ConsensusReached);
                 }
             }
        }

        emit ChallengeResolved(requestId, challengedProvider, providerWasCorrect);

        // Note: Finalization still needs to be called separately after resolution if state allows (ConsensusReached).
    }

    // --- Governance (onlyGovernance) ---

    /**
     * @dev Adds a new AI model that providers can register for and users can request.
     * @param modelId A unique ID for the new model.
     * @param modelInfo Description or link for the model.
     * @param parameters ABI-encoded parameters specific to the model.
     */
    function addSupportedModel(uint modelId, string calldata modelInfo, bytes calldata parameters) external onlyGovernance {
        require(!supportedModels[modelId].isSupported, "Model ID already supported");
        supportedModels[modelId] = SupportedModel({
            modelInfo: modelInfo,
            parameters: parameters,
            isSupported: true
        });
        supportedModelIds.push(modelId); // Add to the list
        emit ModelAdded(modelId, modelInfo);
    }

    /**
     * @dev Removes support for an existing AI model.
     *      Providers supporting this model might need to update their registration.
     * @param modelId The ID of the model to remove.
     */
    function removeSupportedModel(uint modelId) external onlyGovernance {
        require(supportedModels[modelId].isSupported, "Model ID not supported");
        supportedModels[modelId].isSupported = false; // Mark as unsupported
        // Remove from the list (inefficient for large arrays)
        for (uint i = 0; i < supportedModelIds.length; i++) {
            if (supportedModelIds[i] == modelId) {
                supportedModelIds[i] = supportedModelIds[supportedModelIds.length - 1];
                supportedModelIds.pop();
                break;
            }
        }
        // TODO: Consider impact on active requests for this model. Maybe mark them as failed?
        emit ModelRemoved(modelId, supportedModels[modelId].modelInfo);
    }

    /**
     * @dev Sets core protocol parameters.
     */
    function setParameters(
        uint _quorumSize,
        uint _consensusThreshold,
        uint _submissionPeriod,
        uint _verificationPeriod,
        uint _challengePeriod,
        uint _oracleFee,
        uint _minStakeAmount,
        uint _deregistrationCooldown
    ) external onlyGovernance {
        quorumSize = _quorumSize;
        consensusThreshold = _consensusThreshold;
        submissionPeriod = _submissionPeriod;
        verificationPeriod = _verificationPeriod;
        challengePeriod = _challengePeriod;
        oracleFee = _oracleFee;
        minStakeAmount = _minStakeAmount;
        deregistrationCooldown = _deregistrationCooldown;

        emit ParametersUpdated(
            _quorumSize,
            _consensusThreshold,
            _submissionPeriod,
            _verificationPeriod,
            _challengePeriod,
            _oracleFee,
            _minStakeAmount,
            _deregistrationCooldown
        );
    }

    /**
     * @dev Sets the address authorized to perform governance actions.
     * @param newGovernance The new governance address.
     */
    function setGovernanceAddress(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "New governance address cannot be zero");
        address oldGovernance = governanceAddress;
        governanceAddress = newGovernance;
        emit GovernanceAddressSet(oldGovernance, newGovernance);
    }

    /**
     * @dev Internal function (or can be exposed only to governance/trusted relayer) to distribute reward.
     * @param requestId The ID of the request this reward is for.
     * @param providerAddress The address of the provider receiving the reward.
     * @param amount The amount of stake tokens to distribute.
     */
    function distributeReward(uint requestId, address providerAddress, uint amount) internal { // Made internal, called by finalizeRequest
        // Ensure request is finalized or in process of finalization?
        // Or ensure caller is trusted (finalizeRequest, governance)? Let's trust internal call from finalizeRequest.
        require(amount > 0, "Reward amount must be positive");
        // No need to check provider existence/status here, as finalizeRequest selects winners.

        bool success = stakeToken.transfer(providerAddress, amount);
        require(success, "Reward distribution failed");

        emit RewardDistributed(providerAddress, amount);
    }

    /**
     * @dev Internal function (or onlyGovernance) to slash stake from a provider.
     * @param providerAddress The address of the provider to slash.
     * @param amount The amount of stake tokens to slash.
     */
    function slashStake(address providerAddress, uint amount) internal { // Made internal, called by resolveChallenge
        Provider storage provider = providers[providerAddress];
        require(provider.stakedAmount >= amount, "Insufficient stake to slash");
        require(amount > 0, "Slash amount must be positive");

        provider.stakedAmount -= amount;
        // Slashed tokens remain in the contract or are transferred somewhere else?
        // Let's keep them in the contract for now (increases reward pool).
        // Options: Burn, transfer to a treasury, transfer to governance, keep in pool. Keeping in pool is simplest.

        emit StakeSlashed(providerAddress, amount);
    }

    // --- View Functions ---

    /**
     * @dev Gets details of a provider.
     * @param providerAddress The address of the provider.
     * @return Provider struct details.
     */
    function getProvider(address providerAddress) external view returns (Provider memory) {
        return providers[providerAddress];
    }

     /**
     * @dev Gets the current staked amount for a provider.
     * @param provider The address of the provider.
     * @return The staked amount.
     */
    function getProviderStake(address provider) external view returns (uint) {
        return providers[provider].stakedAmount;
    }

    /**
     * @dev Gets the active status and cooldown time for a provider.
     * @param provider The address of the provider.
     * @return isActive Status, deregistration time, last heartbeat, supported models count.
     */
    function getProviderStatus(address provider) external view returns (bool isActive, uint deregistrationTime, uint lastHeartbeat, uint supportedModelsCount) {
        Provider storage p = providers[provider];
        return (p.isActive, p.deregistrationTime, p.lastHeartbeat, p.registeredModels.length);
    }

    /**
     * @dev Gets the list of currently active provider addresses that support a specific model.
     *      Note: This can be gas-intensive if `activeProviderAddresses` is large.
     * @param modelId The ID of the model.
     * @return An array of active provider addresses.
     */
    function getActiveProviders(uint modelId) external view returns (address[] memory) {
        uint count = 0;
        // First pass to count
        for (uint i = 0; i < activeProviderAddresses.length; i++) {
            address providerAddr = activeProviderAddresses[i];
            Provider storage provider = providers[providerAddr];
            for (uint j = 0; j < provider.registeredModels.length; j++) {
                if (provider.registeredModels[j] == modelId) {
                    count++;
                    break; // Provider supports the model, count once and move to next provider
                }
            }
        }

        address[] memory modelProviders = new address[](count);
        uint index = 0;
        // Second pass to populate the array
        for (uint i = 0; i < activeProviderAddresses.length; i++) {
            address providerAddr = activeProviderAddresses[i];
            Provider storage provider = providers[providerAddr];
            for (uint j = 0; j < provider.registeredModels.length; j++) {
                 if (provider.registeredModels[j] == modelId) {
                    modelProviders[index++] = providerAddr;
                    break; // Provider supports the model, add once
                }
            }
        }

        return modelProviders;
    }

    /**
     * @dev Gets the current state of a request.
     * @param requestId The ID of the request.
     * @return The request state enum.
     */
    function getRequestStatus(uint requestId) external view requestExists(requestId) returns (RequestState) {
        return requests[requestId].state;
    }

     /**
     * @dev Gets full details of a request.
     * @param requestId The ID of the request.
     * @return The Request struct details.
     */
    function getRequestDetails(uint requestId) external view requestExists(requestId) returns (Request memory) {
        return requests[requestId];
    }


    /**
     * @dev Gets a specific provider's submitted result for a request.
     * @param requestId The ID of the request.
     * @param providerAddress The address of the provider.
     * @return The Result struct details.
     */
    function getResult(uint requestId, address providerAddress) external view requestExists(requestId) returns (Result memory) {
        return results[requestId][providerAddress];
    }

    /**
     * @dev Gets all results submitted for a given request.
     *      Note: This can be gas-intensive if many providers submitted results.
     * @param requestId The ID of the request.
     * @return An array of Result structs for participating providers.
     */
     function getProviderResults(uint requestId) external view requestExists(requestId) returns (Result[] memory) {
         Request storage req = requests[requestId];
         uint participatingCount = req.participatingProviders.length;
         Result[] memory submittedResults = new Result[](participatingCount);

         for(uint i=0; i < participatingCount; i++) {
             submittedResults[i] = results[requestId][req.participatingProviders[i]];
         }
         return submittedResults;
     }

    /**
     * @dev Gets the list of all supported model IDs.
     * @return An array of supported model IDs.
     */
    function getSupportedModels() external view returns (uint[] memory) {
        return supportedModelIds;
    }

    /**
     * @dev Gets details for a specific supported model.
     * @param modelId The ID of the model.
     * @return The SupportedModel struct details.
     */
    function getModelDetails(uint modelId) external view returns (SupportedModel memory) {
        require(supportedModels[modelId].isSupported, "Model ID not supported");
        return supportedModels[modelId];
    }


    /**
     * @dev Gets the current request fee.
     * @return The current oracle fee in stake token units.
     */
    function getOracleFee() external view returns (uint) {
        return oracleFee;
    }

    /**
     * @dev Gets the minimum required stake for providers.
     * @return The minimum stake amount in stake token units.
     */
    function getMinStakeAmount() external view returns (uint) {
        return minStakeAmount;
    }

    /**
     * @dev Gets the current balance of the stake token held by the contract (reward pool).
     * @return The contract's stake token balance.
     */
    function getRewardPoolBalance() external view returns (uint) {
        return stakeToken.balanceOf(address(this));
    }
}
```