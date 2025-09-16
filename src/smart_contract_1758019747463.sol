This smart contract, `IntentNexus`, is designed as a decentralized intent orchestration layer. It enables users to express their desired on-chain state transformations (Intents), and specialized off-chain "Resolvers" to compete and fulfill these Intents. The contract incorporates several advanced, creative, and trendy concepts:

1.  **Intent-Centric Architecture:** Users define *what* they want to achieve, rather than *how* to achieve it, abstracting away complex DeFi interactions.
2.  **MEV Protection:** A commit-reveal scheme for fulfillment prevents front-running and harmful MEV extraction by resolvers. Resolvers commit to fulfillment details before revealing them.
3.  **Resolver Reputation System:** Resolvers stake collateral and accrue reputation based on successful, undisputed fulfillments, promoting trustworthy behavior. Malicious resolvers can be slashed.
4.  **Escrow and Settlement Layer:** The contract acts as an escrow for user assets and a settlement layer, ensuring funds are released only upon validated fulfillment.
5.  **Verifiable Fulfillment:** `_proofOfExecution` allows for the integration of off-chain computation/proofs (e.g., ZK-proof hashes, oracle attestations, or hashes of on-chain events) to validate a resolver's work.
6.  **Dispute Resolution:** A simplified mechanism allows users to challenge fulfillments, with a DAO-like (Owner) role for dispute resolution.
7.  **Gas Abstraction Readiness:** While not fully implemented for gas abstraction, the model where resolvers are compensated from user bonds or intent funds sets the stage for future EIP-4337 integration.
8.  **Modularity & Extensibility:** Intent parameters (`intentDataHash`) and fulfillment details (`_fulfillmentDetails`) use generic `bytes` types, allowing for diverse and evolving intent types without contract upgrades.

---

### **Outline and Function Summary**

**Contract Name:** `IntentNexus`

**Core Concept:** A decentralized protocol for submitting and fulfilling user intents with MEV protection, resolver reputation, and dispute resolution.

**I. Core Intent Management**
1.  `submitIntent(IntentParams calldata _params, uint256 _creatorBondAmount)`: Allows a user to submit a new intent, transferring the `inputToken` into escrow and a `creatorBond` for potential fees/disputes.
2.  `cancelIntent(uint256 _intentId)`: Enables the intent creator to cancel an unfulfilled intent and reclaim their escrowed assets.
3.  `getIntentDetails(uint256 _intentId)`: Read-only function to retrieve the complete details of a specific intent.
4.  `getIntentStatus(uint256 _intentId)`: Read-only function to get the current status (e.g., `Pending`, `Committed`, `Fulfilled`) of an intent.

**II. Resolver Management**
5.  `registerResolver(string memory _metadataURI)`: Allows an address to register as a resolver by staking the minimum required bond and providing a metadata URI.
6.  `updateResolverMetadataURI(string memory _newMetadataURI)`: Permits a registered resolver to update their off-chain metadata URI.
7.  `deregisterResolver()`: Allows a resolver to deregister and unstake their bond, provided they have no active commitments or disputes.
8.  `getResolverProfile(address _resolver)`: Read-only function to fetch the full profile (stake, reputation, status) of a resolver.

**III. Intent Fulfillment (Commit-Reveal-Execute)**
9.  `commitFulfillment(uint256 _intentId, bytes32 _fulfillmentHash)`: A resolver commits to fulfilling an intent by submitting a hash of their proposed fulfillment details.
10. `executeFulfillment(uint256 _intentId, bytes memory _fulfillmentDetails, bytes memory _proofOfExecution)`: A resolver reveals the actual fulfillment details and provides a verifiable proof of execution. The contract then validates the fulfillment and settles the escrowed assets.
11. `rejectFulfillmentCommitment(uint256 _intentId)`: Allows the intent creator or any other resolver to reject a commitment if it has expired or if the original intent has been canceled.
12. `getCommitmentDetails(uint256 _intentId)`: Read-only function to fetch the details of a committed fulfillment for a given intent.

**IV. Reputation & Staking**
13. `fundResolverStake(uint256 _amount)`: Allows a resolver to increase their staked bond.
14. `withdrawResolverStake(uint256 _amount)`: Allows a resolver to withdraw excess stake, subject to locks for commitments or disputes.
15. `getResolverReputation(address _resolver)`: Read-only function to query a resolver's current reputation score.
16. `slashResolver(address _resolver, uint256 _amount, string memory _reason)`: Owner/DAO function to slash a resolver's stake due to malicious behavior or dispute resolution.
17. `reclaimCreatorBond(uint256 _intentId)`: Allows the intent creator to reclaim their bond after a successful and undisputed fulfillment (if not automatically returned during execution).

**V. Dispute Resolution (Simplified)**
18. `raiseDispute(uint256 _intentId, string memory _reason)`: Allows the intent creator to raise a dispute regarding a fulfilled intent, locking a dispute bond.
19. `resolveDispute(uint256 _disputeId, bool _resolverIsGuilty)`: Owner/DAO function to resolve a dispute, determining if the resolver was at fault and distributing bonds accordingly.
20. `getDisputeDetails(uint256 _disputeId)`: Read-only function to retrieve the complete details of a specific dispute.
21. `getDisputeStatus(uint256 _disputeId)`: Read-only function to get the current status of a dispute.

**VI. Configuration & Utilities**
22. `setProtocolFee(uint256 _newFeeBps)`: Owner function to set the protocol fee percentage in basis points.
23. `setResolverMinStake(uint256 _newMinStake)`: Owner function to set the minimum stake required for resolvers.
24. `withdrawProtocolFees(address _token)`: Owner function to withdraw accumulated protocol fees for a specific token.
25. `pause()`: Owner function to pause contract functionality in emergencies.
26. `unpause()`: Owner function to unpause the contract.
27. `addSupportedToken(address _token)`: Owner function to add a token address to the list of supported tokens for intents.
28. `removeSupportedToken(address _token)`: Owner function to remove a token address from the list of supported tokens.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For supported tokens

// --- Outline and Function Summary ---
// The IntentNexus contract acts as a decentralized intent orchestration layer.
// Users submit "Intents" defining their desired on-chain state transformations (e.g., swap assets, interact with a DeFi protocol).
// "Resolvers" (specialized off-chain bots/operators) compete to fulfill these intents.
// The contract employs a commit-reveal scheme, a resolver reputation system, and a dispute mechanism to ensure fair,
// MEV-protected execution and foster a trustworthy environment.

// I. Core Intent Management
// 1.  submitIntent(IntentParams calldata _params, uint256 _creatorBondAmount): Users submit an intent, transferring inputToken into escrow and a creator bond.
// 2.  cancelIntent(uint256 _intentId): User cancels their unfulfilled intent, reclaiming deposits.
// 3.  getIntentDetails(uint256 _intentId): Read-only function to fetch full details of an intent.
// 4.  getIntentStatus(uint256 _intentId): Read-only function to check the current status of an intent.

// II. Resolver Management
// 5.  registerResolver(string memory _metadataURI): Resolver stakes a bond to participate and provides a metadata URI.
// 6.  updateResolverMetadataURI(string memory _newMetadataURI): Resolver updates their metadata URI.
// 7.  deregisterResolver(): Resolver unstakes their bond and leaves, provided they have no active commitments or disputes.
// 8.  getResolverProfile(address _resolver): Read-only to get a resolver's full profile.

// III. Intent Fulfillment (Commit-Reveal-Execute)
// 9.  commitFulfillment(uint256 _intentId, bytes32 _fulfillmentHash): Resolver commits a hash of their proposed fulfillment.
// 10. executeFulfillment(uint256 _intentId, bytes memory _fulfillmentDetails, bytes memory _proofOfExecution): Resolver reveals fulfillment details and proof, triggering validation and asset settlement.
// 11. rejectFulfillmentCommitment(uint256 _intentId): Intent creator or anyone can reject a specific committed fulfillment if conditions are not met or timeout.
// 12. getCommitmentDetails(uint256 _intentId): Read-only for the current commitment details.

// IV. Reputation & Staking
// 13. fundResolverStake(uint256 _amount): Resolver adds to their staked bond.
// 14. withdrawResolverStake(uint256 _amount): Resolver withdraws excess stake, subject to locks.
// 15. getResolverReputation(address _resolver): Read-only to fetch a resolver's current reputation score.
// 16. slashResolver(address _resolver, uint256 _amount, string memory _reason): Owner/DAO function to slash a resolver's stake for misconduct.
// 17. reclaimCreatorBond(uint256 _intentId): User reclaims their creator bond after successful, undisputed fulfillment.

// V. Dispute Resolution (Simplified)
// 18. raiseDispute(uint256 _intentId, string memory _reason): User raises a dispute about a fulfillment, requires a bond.
// 19. resolveDispute(uint256 _disputeId, bool _resolverIsGuilty): Owner/DAO resolves a dispute, distributing bonds and potentially slashing.
// 20. getDisputeDetails(uint256 _disputeId): Read-only to fetch details of a specific dispute.
// 21. getDisputeStatus(uint256 _disputeId): Read-only to fetch the status of a dispute.

// VI. Configuration & Utilities
// 22. setProtocolFee(uint256 _newFeeBps): Owner sets the protocol fee percentage (in basis points).
// 23. setResolverMinStake(uint256 _newMinStake): Owner sets the minimum stake required for resolvers.
// 24. withdrawProtocolFees(address _token): Owner withdraws accumulated protocol fees for a specific token.
// 25. pause(): Owner pauses the contract in case of emergency.
// 26. unpause(): Owner unpauses the contract.
// 27. addSupportedToken(address _token): Owner adds a token that can be used for deposits/fees.
// 28. removeSupportedToken(address _token): Owner removes a supported token.

contract IntentNexus is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Events ---
    event IntentSubmitted(uint256 indexed intentId, address indexed creator, address inputToken, uint256 inputAmount);
    event IntentCanceled(uint256 indexed intentId, address indexed creator);
    event ResolverRegistered(address indexed resolver, uint256 stakeAmount, string metadataURI);
    event ResolverDeregistered(address indexed resolver);
    event FulfillmentCommitted(uint256 indexed intentId, address indexed resolver, bytes32 fulfillmentHash);
    event FulfillmentExecuted(uint256 indexed intentId, address indexed resolver, uint256 actualOutputAmount, uint256 resolverFeePaid, uint256 protocolFeeCollected);
    event FulfillmentCommitmentRejected(uint256 indexed intentId, address indexed rejectingParty);
    event ResolverStaked(address indexed resolver, uint256 amount);
    event ResolverUnstaked(address indexed resolver, uint256 amount);
    event ResolverSlashed(address indexed resolver, uint256 amount, string reason);
    event CreatorBondReclaimed(uint256 indexed intentId, address indexed creator, uint256 amount);
    event DisputeRaised(uint256 indexed disputeId, uint256 indexed intentId, address indexed challenger, string reason);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed intentId, bool resolverIsGuilty);
    event ProtocolFeeUpdated(uint256 newFeeBps);
    event ResolverMinStakeUpdated(uint256 newMinStake);
    event ProtocolFeesWithdrawn(address indexed token, uint256 amount);
    event SupportedTokenAdded(address indexed token);
    event SupportedTokenRemoved(address indexed token);

    // --- Enums ---
    enum IntentStatus { Pending, Committed, Fulfilled, Canceled, Disputed }
    enum DisputeStatus { Pending, Resolved }

    // --- Structs ---
    struct IntentParams {
        address inputToken;
        uint256 inputAmount;
        address outputToken;
        uint256 minOutputAmount;
        uint256 maxResolverFee;
        address resolverFeeToken; // Token the resolver wants their fee in (can be inputToken or another)
        uint256 deadline;
        bytes32 intentDataHash; // A hash of the detailed intent specification (e.g., EIP-712 data)
        bytes32 expectedProofHash; // A hash against which the _proofOfExecution will be checked (e.g., oracle attestation hash)
    }

    struct Intent {
        uint256 intentId;
        address creator;
        IntentStatus status;
        address inputToken;
        uint256 inputAmount;
        address outputToken;
        uint256 minOutputAmount;
        uint256 maxResolverFee;
        address resolverFeeToken;
        uint256 deadline;
        bytes32 intentDataHash; // Hash of the complete intent details (off-chain)
        bytes32 expectedProofHash; // Hash for verifying _proofOfExecution
        address committedResolver;
        bytes32 fulfillmentCommitmentHash; // Hash committed by the resolver
        uint256 commitmentTimestamp;
        uint256 creatorBondAmount; // The amount user deposited as bond
        address creatorBondToken; // The token used for the bond (e.g., WETH/ETH)
        uint256 protocolFeeCollected; // Protocol fee from this intent
    }

    struct ResolverProfile {
        uint256 stake;
        string metadataURI;
        int256 reputation; // Can be negative for bad behavior
        bool isActive;
        uint256 committedIntentsCount; // Number of intents a resolver has an active commitment for
    }

    struct Dispute {
        uint256 disputeId;
        uint256 intentId;
        address challenger; // The address who raised the dispute
        address challengedResolver;
        string reason;
        uint256 challengerBond; // Bond locked by the challenger
        address challengerBondToken;
        DisputeStatus status;
        bool resolverIsGuilty; // Result of the resolution
        uint256 resolutionTimestamp;
    }

    // --- State Variables ---
    uint256 private _nextIntentId;
    uint256 private _nextDisputeId;
    uint256 public protocolFeeBps; // Protocol fee in basis points (e.g., 100 = 1%)
    uint256 public minResolverStake;
    address public feeCollector;

    mapping(uint256 => Intent) public intents;
    mapping(address => ResolverProfile) public resolvers;
    mapping(uint256 => Dispute) public disputes;

    // Mapping for tracking protocol fees per token
    mapping(address => uint256) public protocolFeeBalances;

    // Supported tokens for deposits, fees, etc.
    EnumerableSet.AddressSet private _supportedTokens;

    // --- Constructor ---
    constructor(uint256 _initialProtocolFeeBps, uint256 _initialMinResolverStake, address _initialFeeCollector) Ownable(msg.sender) {
        require(_initialFeeCollector != address(0), "Zero fee collector");
        protocolFeeBps = _initialProtocolFeeBps;
        minResolverStake = _initialMinResolverStake;
        feeCollector = _initialFeeCollector;
        _nextIntentId = 1;
        _nextDisputeId = 1;
        _supportedTokens.add(address(0)); // Support native ETH (represented by address(0))
    }

    // --- Modifiers ---
    modifier onlyResolver() {
        require(resolvers[msg.sender].isActive, "Not a registered resolver");
        _;
    }

    modifier onlyIntentCreator(uint256 _intentId) {
        require(intents[_intentId].creator == msg.sender, "Not intent creator");
        _;
    }

    modifier onlyCommittedResolver(uint256 _intentId) {
        require(intents[_intentId].committedResolver == msg.sender, "Not committed resolver");
        _;
    }

    modifier notDisputed(uint256 _intentId) {
        require(intents[_intentId].status != IntentStatus.Disputed, "Intent is under dispute");
        _;
    }

    modifier isSupportedToken(address _token) {
        require(_supportedTokens.contains(_token), "Token not supported");
        _;
    }

    // --- I. Core Intent Management ---

    /// @notice Submits a new intent, transferring inputToken into escrow and a creator bond.
    /// @param _params Struct containing intent parameters.
    /// @param _creatorBondAmount Amount to deposit as creator bond.
    /// @dev User must approve `inputToken` and `_params.resolverFeeToken` (if different from inputToken) to the contract prior to calling.
    ///      If `inputToken` or `resolverFeeToken` is `address(0)`, native ETH is used.
    function submitIntent(IntentParams calldata _params, uint256 _creatorBondAmount)
        external
        payable
        whenNotPaused
        nonReentrant
        isSupportedToken(_params.inputToken)
        isSupportedToken(_params.resolverFeeToken)
    {
        require(_params.deadline > block.timestamp, "Intent: Deadline in past");
        require(_params.inputToken != address(0) || msg.value > 0, "Intent: Input ETH amount required");
        require(_params.minOutputAmount > 0, "Intent: Min output must be greater than 0");
        require(_params.maxResolverFee < _params.inputAmount, "Intent: Resolver fee too high"); // Basic sanity check

        uint256 currentIntentId = _nextIntentId++;
        uint256 inputAmountReceived = 0;
        uint256 creatorBondReceived = 0;

        // Handle ETH and ERC20 for inputToken
        if (_params.inputToken == address(0)) {
            require(msg.value >= _params.inputAmount, "Intent: Insufficient ETH input");
            inputAmountReceived = _params.inputAmount;
        } else {
            IERC20(_params.inputToken).safeTransferFrom(msg.sender, address(this), _params.inputAmount);
            inputAmountReceived = _params.inputAmount;
        }

        // Handle creator bond. If bond token is ETH, it must be part of msg.value.
        // If creatorBondToken is specified as ETH (address(0)) but _params.resolverFeeToken is not,
        // we take the remaining msg.value as creator bond.
        // For simplicity in this example, let's assume creatorBondToken is always _params.resolverFeeToken.
        // In a real scenario, this would be more flexible (e.g., dedicated collateral token).
        // Here, we'll take creator bond in the same token as resolverFeeToken.
        // For ETH-based creator bond:
        if (_params.resolverFeeToken == address(0)) {
             require(msg.value >= inputAmountReceived + _creatorBondAmount, "Intent: Insufficient ETH for bond");
             creatorBondReceived = _creatorBondAmount;
             // Any excess ETH from msg.value will be returned to sender or revert if not specified.
             // For this example, we assume exact ETH payment.
        } else {
            IERC20(_params.resolverFeeToken).safeTransferFrom(msg.sender, address(this), _creatorBondAmount);
            creatorBondReceived = _creatorBondAmount;
        }
        
        // Return excess ETH if any, after deducting input token and creator bond
        uint256 totalEthRequired = 0;
        if (_params.inputToken == address(0)) totalEthRequired += _params.inputAmount;
        if (_params.resolverFeeToken == address(0)) totalEthRequired += _creatorBondAmount;

        if (msg.value > totalEthRequired) {
            payable(msg.sender).transfer(msg.value - totalEthRequired);
        } else if (msg.value < totalEthRequired) {
            revert("Intent: Insufficient ETH for all required amounts");
        }


        intents[currentIntentId] = Intent({
            intentId: currentIntentId,
            creator: msg.sender,
            status: IntentStatus.Pending,
            inputToken: _params.inputToken,
            inputAmount: inputAmountReceived,
            outputToken: _params.outputToken,
            minOutputAmount: _params.minOutputAmount,
            maxResolverFee: _params.maxResolverFee,
            resolverFeeToken: _params.resolverFeeToken,
            deadline: _params.deadline,
            intentDataHash: _params.intentDataHash,
            expectedProofHash: _params.expectedProofHash,
            committedResolver: address(0),
            fulfillmentCommitmentHash: bytes32(0),
            commitmentTimestamp: 0,
            creatorBondAmount: creatorBondReceived,
            creatorBondToken: _params.resolverFeeToken, // Assuming bond is in resolverFeeToken
            protocolFeeCollected: 0
        });

        emit IntentSubmitted(currentIntentId, msg.sender, _params.inputToken, inputAmountReceived);
    }

    /// @notice Allows the intent creator to cancel an unfulfilled intent.
    /// @param _intentId The ID of the intent to cancel.
    function cancelIntent(uint256 _intentId) external onlyIntentCreator(_intentId) whenNotPaused nonReentrant {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.Pending, "Intent: Not in Pending status or already committed");
        require(block.timestamp <= intent.deadline, "Intent: Already expired");

        intent.status = IntentStatus.Canceled;

        // Return inputToken
        _safeTransfer(intent.inputToken, intent.creator, intent.inputAmount);

        // Return creator bond
        _safeTransfer(intent.creatorBondToken, intent.creator, intent.creatorBondAmount);

        emit IntentCanceled(_intentId, msg.sender);
    }

    /// @notice Retrieves the complete details of a specific intent.
    /// @param _intentId The ID of the intent.
    /// @return Intent struct containing all intent parameters.
    function getIntentDetails(uint256 _intentId) external view returns (Intent memory) {
        return intents[_intentId];
    }

    /// @notice Retrieves the current status of an intent.
    /// @param _intentId The ID of the intent.
    /// @return IntentStatus enum value.
    function getIntentStatus(uint256 _intentId) external view returns (IntentStatus) {
        return intents[_intentId].status;
    }


    // --- II. Resolver Management ---

    /// @notice Registers an address as a resolver by staking the minimum required bond.
    /// @param _metadataURI URI pointing to off-chain resolver metadata.
    function registerResolver(string memory _metadataURI) external payable whenNotPaused nonReentrant {
        require(!resolvers[msg.sender].isActive, "Resolver: Already registered");
        require(msg.value >= minResolverStake, "Resolver: Insufficient stake");

        resolvers[msg.sender] = ResolverProfile({
            stake: msg.value,
            metadataURI: _metadataURI,
            reputation: 0,
            isActive: true,
            committedIntentsCount: 0
        });

        emit ResolverRegistered(msg.sender, msg.value, _metadataURI);
    }

    /// @notice Permits a registered resolver to update their off-chain metadata URI.
    /// @param _newMetadataURI The new URI for resolver metadata.
    function updateResolverMetadataURI(string memory _newMetadataURI) external onlyResolver whenNotPaused {
        resolvers[msg.sender].metadataURI = _newMetadataURI;
    }

    /// @notice Allows a resolver to deregister and unstake their bond, if no active commitments or disputes.
    function deregisterResolver() external onlyResolver whenNotPaused nonReentrant {
        ResolverProfile storage resolver = resolvers[msg.sender];
        require(resolver.committedIntentsCount == 0, "Resolver: Has active commitments");
        // For simplicity, no check for active disputes. In a real system, would need to check.

        resolver.isActive = false;
        uint256 stakeAmount = resolver.stake;
        resolver.stake = 0; // Clear stake before transfer

        payable(msg.sender).transfer(stakeAmount); // Transfer ETH stake
        emit ResolverDeregistered(msg.sender);
    }

    /// @notice Fetches the full profile of a resolver.
    /// @param _resolver The address of the resolver.
    /// @return ResolverProfile struct.
    function getResolverProfile(address _resolver) external view returns (ResolverProfile memory) {
        return resolvers[_resolver];
    }

    // --- III. Intent Fulfillment (Commit-Reveal-Execute) ---

    /// @notice A resolver commits to fulfilling an intent by submitting a hash of their proposed fulfillment details.
    /// @param _intentId The ID of the intent.
    /// @param _fulfillmentHash A hash representing the resolver's proposed fulfillment.
    function commitFulfillment(uint256 _intentId, bytes32 _fulfillmentHash) external onlyResolver whenNotPaused {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.Pending, "Intent: Not in Pending status");
        require(block.timestamp <= intent.deadline, "Intent: Already expired");
        require(_fulfillmentHash != bytes32(0), "Fulfillment: Hash cannot be zero");

        // Prevent multiple commitments or self-commit by a resolver
        require(intent.committedResolver == address(0), "Fulfillment: Intent already committed");

        intent.committedResolver = msg.sender;
        intent.fulfillmentCommitmentHash = _fulfillmentHash;
        intent.commitmentTimestamp = block.timestamp;
        resolvers[msg.sender].committedIntentsCount++;

        emit FulfillmentCommitted(_intentId, msg.sender, _fulfillmentHash);
    }

    /// @notice Resolver reveals the actual fulfillment details and provides a verifiable proof of execution.
    /// Contract validates the fulfillment and settles escrowed assets.
    /// Resolver must have already sent `outputToken` to `intent.creator` off-chain.
    /// @param _intentId The ID of the intent.
    /// @param _fulfillmentDetails A bytes array containing details of the actual fulfillment (e.g., actual output amount, actual fee).
    /// @param _proofOfExecution A bytes array or hash serving as cryptographic proof of execution.
    function executeFulfillment(
        uint256 _intentId,
        bytes memory _fulfillmentDetails,
        bytes memory _proofOfExecution
    ) external onlyCommittedResolver(_intentId) whenNotPaused nonReentrant {
        Intent storage intent = intents[_intentId];
        ResolverProfile storage resolver = resolvers[msg.sender];

        require(intent.status == IntentStatus.Committed, "Fulfillment: Intent not in Committed state");
        require(intent.fulfillmentCommitmentHash == keccak256(_fulfillmentDetails), "Fulfillment: Details mismatch commitment");
        require(intent.expectedProofHash == keccak256(_proofOfExecution), "Fulfillment: Proof of execution invalid"); // Simplified verification
        require(block.timestamp <= intent.deadline, "Fulfillment: Intent expired during commitment period");
        
        // Parse _fulfillmentDetails (simplified - in real-world, might use abi.decode or specific struct)
        // For this example, let's assume _fulfillmentDetails bytes directly encode actualOutputAmount and actualFeeAmount
        // (This is a simplified assumption for demonstration. Real-world parsing would be complex).
        uint256 actualOutputAmount;
        uint256 actualResolverFee;
        assembly {
            actualOutputAmount := mload(add(_fulfillmentDetails, 32)) // Assuming first 32 bytes is output amount
            actualResolverFee := mload(add(_fulfillmentDetails, 64))  // Assuming next 32 bytes is resolver fee
        }

        require(actualOutputAmount >= intent.minOutputAmount, "Fulfillment: Actual output below minimum");
        require(actualResolverFee <= intent.maxResolverFee, "Fulfillment: Actual fee exceeds maximum");

        // Calculate protocol fee
        uint256 protocolFee = (actualResolverFee * protocolFeeBps) / 10_000;
        uint256 resolverPayout = actualResolverFee - protocolFee;

        // Transfer resolver payout from creator's bond
        _safeTransfer(intent.creatorBondToken, msg.sender, resolverPayout);
        intent.creatorBondAmount -= resolverPayout;

        // Collect protocol fee
        _safeTransfer(intent.creatorBondToken, feeCollector, protocolFee);
        intent.protocolFeeCollected += protocolFee;
        protocolFeeBalances[intent.creatorBondToken] += protocolFee;
        intent.creatorBondAmount -= protocolFee;

        // Mark intent as fulfilled
        intent.status = IntentStatus.Fulfilled;
        resolver.committedIntentsCount--;
        _updateReputation(msg.sender, 10); // Reward reputation for successful fulfillment

        // NOTE: The inputToken (escrowed by the user) is returned to the user or paid to resolver as compensation.
        // In this model, the resolver *performs* the action off-chain and sends output to the user.
        // The *inputToken* in escrow is actually part of the resolver's compensation.
        // Let's modify: inputToken is transferred to the resolver as their primary compensation.
        _safeTransfer(intent.inputToken, msg.sender, intent.inputAmount);
        
        emit FulfillmentExecuted(_intentId, msg.sender, actualOutputAmount, actualResolverFee, protocolFee);
    }

    /// @notice Allows the intent creator or anyone to reject a commitment if it has expired or if the intent is no longer committed.
    /// @param _intentId The ID of the intent.
    function rejectFulfillmentCommitment(uint256 _intentId) external whenNotPaused {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.Committed, "Fulfillment: Not in Committed state");
        
        // Anyone can reject if commitment is too old (e.g., if resolver didn't reveal in time)
        // Or if the original intent creator decides to reject after a certain period if no reveal.
        require(block.timestamp > intent.commitmentTimestamp + 1 days || msg.sender == intent.creator, "Fulfillment: Commitment not expired or not creator"); // Example timeout: 1 day

        address formerCommittedResolver = intent.committedResolver;
        resolvers[formerCommittedResolver].committedIntentsCount--;
        _updateReputation(formerCommittedResolver, -5); // Penalize for unrevealed commitment

        intent.committedResolver = address(0);
        intent.fulfillmentCommitmentHash = bytes32(0);
        intent.commitmentTimestamp = 0;
        intent.status = IntentStatus.Pending; // Revert to pending for other resolvers to pick up

        emit FulfillmentCommitmentRejected(_intentId, msg.sender);
    }

    /// @notice Fetches the details of a committed fulfillment for a given intent.
    /// @param _intentId The ID of the intent.
    /// @return The resolver address who committed, the fulfillment hash, and commitment timestamp.
    function getCommitmentDetails(uint256 _intentId) external view returns (address, bytes32, uint256) {
        Intent storage intent = intents[_intentId];
        return (intent.committedResolver, intent.fulfillmentCommitmentHash, intent.commitmentTimestamp);
    }


    // --- IV. Reputation & Staking ---

    /// @notice Allows a resolver to increase their staked bond.
    /// @param _amount The amount of ETH to add to the stake.
    function fundResolverStake(uint256 _amount) external payable onlyResolver whenNotPaused {
        require(msg.value == _amount, "Stake: ETH amount mismatch");
        resolvers[msg.sender].stake += _amount;
        emit ResolverStaked(msg.sender, _amount);
    }

    /// @notice Allows a resolver to withdraw excess stake, subject to locks.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawResolverStake(uint256 _amount) external onlyResolver whenNotPaused nonReentrant {
        ResolverProfile storage resolver = resolvers[msg.sender];
        require(resolver.stake - resolver.committedIntentsCount * minResolverStake >= _amount, "Stake: Insufficient withdrawable stake"); // Simplified lock for active commitments
        // In a more complex system, resolver stake could be locked for dispute periods too.

        resolver.stake -= _amount;
        payable(msg.sender).transfer(_amount);
        emit ResolverUnstaked(msg.sender, _amount);
    }

    /// @notice Queries a resolver's current reputation score.
    /// @param _resolver The address of the resolver.
    /// @return The reputation score as an int256.
    function getResolverReputation(address _resolver) external view returns (int256) {
        return resolvers[_resolver].reputation;
    }

    /// @notice Owner/DAO function to slash a resolver's stake due to malicious behavior or dispute resolution.
    /// @param _resolver The address of the resolver to slash.
    /// @param _amount The amount of stake to slash.
    /// @param _reason The reason for slashing.
    function slashResolver(address _resolver, uint256 _amount, string memory _reason) external onlyOwner whenNotPaused nonReentrant {
        ResolverProfile storage resolver = resolvers[_resolver];
        require(resolver.isActive, "Slash: Resolver not active");
        require(resolver.stake >= _amount, "Slash: Insufficient stake to slash");

        resolver.stake -= _amount;
        _updateReputation(_resolver, -50); // Significant reputation hit for slashing
        
        protocolFeeBalances[address(0)] += _amount; // Slashed amount goes to protocol fees (ETH)
        emit ResolverSlashed(_resolver, _amount, _reason);
    }

    /// @notice Internal function to update resolver's reputation.
    /// @param _resolver The resolver's address.
    /// @param _change The change in reputation (positive for good, negative for bad).
    function _updateReputation(address _resolver, int256 _change) internal {
        resolvers[_resolver].reputation += _change;
    }

    /// @notice Allows the intent creator to reclaim their bond after a successful and undisputed fulfillment.
    /// This is for cases where the bond was not fully consumed by fees.
    /// @param _intentId The ID of the intent.
    function reclaimCreatorBond(uint256 _intentId) external onlyIntentCreator(_intentId) whenNotPaused nonReentrant notDisputed(_intentId) {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.Fulfilled, "Bond: Intent not fulfilled");
        require(intent.creatorBondAmount > 0, "Bond: No remaining bond to reclaim");

        uint256 amountToReclaim = intent.creatorBondAmount;
        intent.creatorBondAmount = 0; // Clear remaining bond

        _safeTransfer(intent.creatorBondToken, msg.sender, amountToReclaim);
        emit CreatorBondReclaimed(_intentId, msg.sender, amountToReclaim);
    }


    // --- V. Dispute Resolution (Simplified) ---

    /// @notice Allows the intent creator to raise a dispute regarding a fulfilled intent.
    /// @param _intentId The ID of the intent.
    /// @param _reason A string describing the reason for the dispute.
    function raiseDispute(uint256 _intentId, string memory _reason) external onlyIntentCreator(_intentId) payable whenNotPaused nonReentrant {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.Fulfilled, "Dispute: Intent not fulfilled");
        require(intent.committedResolver != address(0), "Dispute: No resolver committed");
        
        // For simplicity, dispute bond is ETH. In real system, it would be more configurable.
        uint256 disputeBond = 1 ether; // Example dispute bond
        require(msg.value >= disputeBond, "Dispute: Insufficient bond provided");

        // Refund any excess ETH
        if (msg.value > disputeBond) {
            payable(msg.sender).transfer(msg.value - disputeBond);
        }

        intent.status = IntentStatus.Disputed; // Mark intent as disputed
        uint256 currentDisputeId = _nextDisputeId++;

        disputes[currentDisputeId] = Dispute({
            disputeId: currentDisputeId,
            intentId: _intentId,
            challenger: msg.sender,
            challengedResolver: intent.committedResolver,
            reason: _reason,
            challengerBond: disputeBond,
            challengerBondToken: address(0), // ETH for simplicity
            status: DisputeStatus.Pending,
            resolverIsGuilty: false,
            resolutionTimestamp: 0
        });

        emit DisputeRaised(currentDisputeId, _intentId, msg.sender, _reason);
    }

    /// @notice Owner/DAO function to resolve a dispute, determining if the resolver was at fault.
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _resolverIsGuilty True if the resolver is found guilty, false otherwise.
    function resolveDispute(uint256 _disputeId, bool _resolverIsGuilty) external onlyOwner whenNotPaused nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Pending, "Dispute: Already resolved");

        Intent storage intent = intents[dispute.intentId];
        ResolverProfile storage resolver = resolvers[dispute.challengedResolver];

        dispute.status = DisputeStatus.Resolved;
        dispute.resolverIsGuilty = _resolverIsGuilty;
        dispute.resolutionTimestamp = block.timestamp;

        if (_resolverIsGuilty) {
            // Resolver guilty: slash resolver stake, give challenger their bond back, and potentially creator's lost funds.
            _slashResolverInternal(dispute.challengedResolver, dispute.challengerBond, "Guilty in dispute"); // Slash resolver by challenger's bond amount
            payable(dispute.challenger).transfer(dispute.challengerBond); // Return challenger's bond
            _updateReputation(dispute.challengedResolver, -100); // Major reputation hit
            intent.status = IntentStatus.Canceled; // The intent is considered failed and canceled
            // In a real system, the user's initial inputToken would be returned here as well.
            _safeTransfer(intent.inputToken, intent.creator, intent.inputAmount);
            _safeTransfer(intent.creatorBondToken, intent.creator, intent.creatorBondAmount);
        } else {
            // Resolver not guilty: challenger loses their bond, resolver gets a reputation boost.
            protocolFeeBalances[dispute.challengerBondToken] += dispute.challengerBond; // Challenger bond goes to protocol
            _updateReputation(dispute.challengedResolver, 20); // Reward resolver
            // The intent remains in 'Fulfilled' status, and creator still needs to reclaim their bond if any.
            intent.status = IntentStatus.Fulfilled; // Set back to fulfilled as resolver was not guilty
        }

        emit DisputeResolved(_disputeId, dispute.intentId, _resolverIsGuilty);
    }

    /// @notice Fetches the complete details of a specific dispute.
    /// @param _disputeId The ID of the dispute.
    /// @return Dispute struct.
    function getDisputeDetails(uint256 _disputeId) external view returns (Dispute memory) {
        return disputes[_disputeId];
    }

    /// @notice Fetches the current status of a dispute.
    /// @param _disputeId The ID of the dispute.
    /// @return DisputeStatus enum value.
    function getDisputeStatus(uint256 _disputeId) external view returns (DisputeStatus) {
        return disputes[_disputeId].status;
    }

    // Internal helper for slashing, to be used by dispute resolution as well.
    function _slashResolverInternal(address _resolver, uint256 _amount, string memory _reason) internal {
        ResolverProfile storage resolver = resolvers[_resolver];
        require(resolver.isActive, "Slash: Resolver not active");
        require(resolver.stake >= _amount, "Slash: Insufficient stake to slash");

        resolver.stake -= _amount;
        protocolFeeBalances[address(0)] += _amount;
        emit ResolverSlashed(_resolver, _amount, _reason);
    }


    // --- VI. Configuration & Utilities ---

    /// @notice Owner function to set the protocol fee percentage in basis points.
    /// @param _newFeeBps The new protocol fee in basis points (e.g., 100 for 1%). Max 1000 (10%).
    function setProtocolFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 1000, "Fee: Max 10% fee"); // 1000 bps = 10%
        protocolFeeBps = _newFeeBps;
        emit ProtocolFeeUpdated(_newFeeBps);
    }

    /// @notice Owner function to set the minimum stake required for resolvers.
    /// @param _newMinStake The new minimum stake amount.
    function setResolverMinStake(uint256 _newMinStake) external onlyOwner {
        minResolverStake = _newMinStake;
        emit ResolverMinStakeUpdated(_newMinStake);
    }

    /// @notice Owner function to withdraw accumulated protocol fees for a specific token.
    /// @param _token The address of the token to withdraw (address(0) for ETH).
    function withdrawProtocolFees(address _token) external onlyOwner nonReentrant isSupportedToken(_token) {
        uint256 amount = protocolFeeBalances[_token];
        require(amount > 0, "No fees to withdraw");
        protocolFeeBalances[_token] = 0; // Reset balance before transfer

        _safeTransfer(_token, feeCollector, amount);
        emit ProtocolFeesWithdrawn(_token, amount);
    }

    /// @notice Pauses contract functionality in emergencies.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Owner function to add a token address to the list of supported tokens.
    /// @param _token The address of the token to add.
    function addSupportedToken(address _token) external onlyOwner {
        require(_token != address(0), "Cannot add zero address again");
        require(!_supportedTokens.contains(_token), "Token already supported");
        _supportedTokens.add(_token);
        emit SupportedTokenAdded(_token);
    }

    /// @notice Owner function to remove a token address from the list of supported tokens.
    /// @param _token The address of the token to remove.
    function removeSupportedToken(address _token) external onlyOwner {
        require(_token != address(0), "Cannot remove native ETH support");
        require(_supportedTokens.contains(_token), "Token not supported");
        _supportedTokens.remove(_token);
        emit SupportedTokenRemoved(_token);
    }

    /// @notice Internal helper for safe ERC20 and ETH transfers.
    /// @param _token The address of the token (address(0) for ETH).
    /// @param _to The recipient address.
    /// @param _amount The amount to transfer.
    function _safeTransfer(address _token, address _to, uint256 _amount) internal {
        if (_amount == 0) return;
        if (_token == address(0)) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    /// @notice Allows the contract to receive ETH.
    receive() external payable {
        // This function is empty as ETH is handled directly in submitIntent for bond/inputToken.
        // Any unexpected ETH sent directly to the contract (not via submitIntent)
        // could be considered protocol fees or simply locked here. For this example, it's locked.
    }
}
```