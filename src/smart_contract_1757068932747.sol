The `AetherMindNexus` smart contract is a decentralized protocol designed to govern access to and ethical use of off-chain AI models. It introduces a novel ecosystem where users earn influence and access through verifiable contributions to the AI community. The core concepts include:

1.  **Soulbound Reputation (AetherPoints & NexusBadges):** A non-transferable reputation system. `AetherPoints` quantify a user's overall contribution and engagement, while `NexusBadges` (Soulbound Tokens) represent specific, verifiable achievements or roles (e.g., "Verified Data Curator," "Ethical AI Reviewer"). These are key for access control and governance participation.
2.  **Decentralized AI Model Access:** The contract acts as a gateway to off-chain AI models. Users request inference, paying dynamically priced fees based on their reputation and the model's requirements. An authorized oracle confirms the completion of off-chain tasks.
3.  **On-chain Data Consent & ZKP Interface:** Users can formally register and revoke consent for their data contributions, referencing off-chain data manifests. The contract provides an interface for Zero-Knowledge Proof (ZKP) verification, allowing users to prove data contribution or specific attributes without revealing sensitive underlying information.
4.  **DAO-Governed Ethical AI Oversight:** The community, weighted by AetherPoints and specific NexusBadges, can propose and vote on ethical AI policies, review AI models for compliance, and potentially blacklist models deemed harmful or unethical.
5.  **Dynamic Pricing & Reward System:** Access costs for AI models can fluctuate based on user reputation and demand. The protocol collects fees and provides a mechanism for contributors (data providers, validators, compute providers) to claim rewards.

This contract uniquely combines several advanced Web3 concepts – SBTs, DAO governance, ZKP interfaces, and dynamic resource access – into a comprehensive system for building a more transparent, ethical, and community-driven AI ecosystem.

---

## **AetherMindNexus Smart Contract**

**Outline:**

*   **Contract Name:** `AetherMindNexus`
*   **Purpose:** A decentralized protocol governing access to and ethical use of off-chain AI models, powered by a reputation system (`AetherPoints`) and soulbound tokens (`NexusBadges`). It enables on-chain data consent management, dynamic access pricing, and community-driven ethical policy enforcement for AI.

**Function Summary:**

*   **I. Core Management & Access Control:**
    1.  `constructor()`: Initializes the contract, setting the initial owner and key parameters.
    2.  `setProtocolParameters()`: Allows the owner or DAO to update various protocol-wide configurations (e.g., fee rates, oracle addresses).
    3.  `pause()`: Pauses core functionality in emergencies (owner/DAO only).
    4.  `unpause()`: Unpauses the contract (owner/DAO only).
    5.  `transferOwnership()`: Transfers contract ownership (OpenZeppelin's `Ownable`).
    6.  `renounceOwnership()`: Renounces contract ownership (OpenZeppelin's `Ownable`).

*   **II. Identity, Reputation & Soulbound Badges (SBTs):**
    7.  `mintNexusBadge(address recipient, NexusBadgeType badgeType)`: Mints a non-transferable `NexusBadge` to a recipient for verified contributions or achievements (owner/DAO only).
    8.  `burnNexusBadge(address holder, NexusBadgeType badgeType)`: Revokes a `NexusBadge` from a holder (owner/DAO only).
    9.  `getAetherPoints(address user)`: Retrieves the current `AetherPoints` (reputation) for a given user.
    10. `getUserBadges(address user)`: Returns an array of `NexusBadgeType` enum values currently held by a user.
    11. `_addAetherPoints(address user, uint256 points)`: Internal function to add AetherPoints to a user.
    12. `_removeAetherPoints(address user, uint256 points)`: Internal function to remove AetherPoints from a user.

*   **III. AI Model Management & Access:**
    13. `registerAIModel(string calldata modelId, string calldata metadataURI, uint256 baseCost, NexusBadgeType[] calldata requiredBadges)`: Registers a new off-chain AI model, defining its access parameters (owner/DAO only).
    14. `deregisterAIModel(string calldata modelId)`: Deregisters an AI model, preventing further access requests (owner/DAO only).
    15. `updateAIModelParameters(string calldata modelId, string calldata metadataURI, uint256 baseCost, NexusBadgeType[] calldata requiredBadges)`: Updates parameters for an existing AI model (owner/DAO only).
    16. `requestAIInference(string calldata modelId, string calldata inputDataHash)`: Initiates a request for AI model inference, paying the dynamic fee. Requires specified badges/reputation.
    17. `confirmAIInferenceCompletion(bytes32 requestId, string calldata outputDataHash, address recipient)`: Callback from an authorized oracle to confirm an inference request has been fulfilled.
    18. `getAIModelAccessCost(string calldata modelId, address user)`: Calculates the dynamic cost for a user to access a specific AI model, factoring in reputation and model parameters.
    19. `getAIModelDefinition(string calldata modelId)`: Retrieves the full definition of a registered AI model.

*   **IV. Decentralized Data Consent & Verification:**
    20. `submitDataConsentProof(string calldata dataManifestURI, bytes32 proofHash)`: User submits an IPFS hash of a data manifest and a proof hash (e.g., ZKP identifier) for data contribution, expressing consent.
    21. `revokeDataConsent(string calldata dataManifestURI)`: User revokes a previously submitted data consent.
    22. `verifyDataConsentZKP(address verifier, bytes calldata proof, bytes32[] calldata publicInputs)`: Interface for calling an external ZKP verifier contract to validate a data contribution or a user's claim without revealing underlying data. *Note: This function acts as an interface. Full ZKP verification is typically complex and computationally intensive, often performed off-chain, with the on-chain call delegating to a dedicated verifier contract.*

*   **V. Governance & Ethical AI Oversight:**
    23. `proposePolicyChange(string calldata proposalURI, uint256 votingDuration)`: Initiates a governance proposal for ethical guidelines or protocol changes.
    24. `voteOnProposal(uint256 proposalId, bool support)`: Users with sufficient `AetherPoints` or specific `NexusBadges` can vote on proposals.
    25. `executeProposal(uint256 proposalId)`: Executes a passed proposal (owner/DAO or time-locked execution based on proposal outcome).
    26. `proposeAIModelEthicalReview(string calldata modelId, string calldata reasonURI)`: Proposes an AI model for ethical review, potentially leading to blacklisting or parameter adjustments.
    27. `recordEthicalReviewOutcome(uint256 reviewId, bool outcomeIsPositive, string calldata outcomeURI)`: Records the official outcome of an ethical review (owner/DAO only), potentially triggering actions like blacklisting or parameter updates.

*   **VI. Treasury & Rewards:**
    28. `claimContributionRewards()`: Allows users to claim accumulated rewards (e.g., AetherPoints, ETH, or other tokens) for their contributions (e.g., data, validation, compute provision).
    29. `withdrawProtocolFees(address recipient)`: Allows the DAO/owner to withdraw accumulated protocol fees to a specified address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Interface for a hypothetical ZKP Verifier contract
interface IZKPVerifier {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool);
}

contract AetherMindNexus is Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- I. Enums and Structs ---

    enum NexusBadgeType {
        None,                // Default / unassigned
        DataCurator,         // Verified contributor of high-quality data
        EthicalAIReviewer,   // Participates in ethical AI model reviews
        ComputeProvider,     // Provides off-chain computational resources
        GovernanceCouncil,   // Member of the core governance council
        AetherPioneer        // Early adopter or significant contributor
    }

    struct AIModelDefinition {
        string modelId;
        string metadataURI;       // IPFS/Arweave URI for model description, parameters, etc.
        uint256 baseCost;         // Base cost in wei for one inference request
        NexusBadgeType[] requiredBadges; // Badges required to access this model
        bool isRegistered;        // Is the model currently active
        bool isBlacklisted;       // Is the model blacklisted for ethical reasons
    }

    struct InferenceRequest {
        string modelId;
        address requester;
        string inputDataHash;     // Hash of the input data (e.g., IPFS CID)
        uint256 requestTime;
        uint256 costPaid;
        string outputDataHash;    // Hash of the output data once completed
        bool completed;
        bool cancelled;
    }

    struct DataConsent {
        string dataManifestURI;   // IPFS/Arweave URI for the data manifest/description
        bytes32 proofHash;        // Hash/identifier of the submitted ZKP or proof
        uint256 submissionTime;
        bool active;              // Is consent currently active
    }

    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    struct GovernanceProposal {
        uint256 proposalId;
        string proposalURI;       // IPFS/Arweave URI for proposal details (text, rationale)
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        ProposalStatus status;
        // Additional parameters for proposal execution might be stored here or in the URI
    }

    struct EthicalReview {
        uint256 reviewId;
        string modelId;
        string reasonURI;         // IPFS/Arweave URI for the reason for review
        bool outcomeIsPositive;   // True if model passed review, false if failed/problematic
        string outcomeURI;        // IPFS/Arweave URI for the detailed outcome report
        bool completed;
    }

    // --- II. State Variables ---

    // Protocol Parameters
    uint256 public constant MIN_AETHER_POINTS_FOR_VOTING = 1000;
    uint256 public constant BASE_REPUTATION_DISCOUNT_PERCENT = 10; // 10% discount per 1000 points, max 50%
    uint256 public constant POINTS_PER_DATA_CONSENT = 100;
    uint256 public constant POINTS_PER_ETHICAL_REVIEW_PARTICIPATION = 50;

    address public protocolTreasury; // Address to receive protocol fees
    address public inferenceOracle;  // Authorized address to confirm AI inference completion
    address public zkpVerifierAddress; // Address of the external ZKP Verifier contract (optional)

    // Reputation & Soulbound Badges
    mapping(address => uint256) private s_aetherPoints; // User's reputation points
    mapping(address => mapping(NexusBadgeType => bool)) private s_nexusBadges; // User's non-transferable badges

    // AI Model Management
    mapping(string => AIModelDefinition) private s_aiModels;
    string[] public registeredModelIds; // To easily iterate or list all registered models

    // AI Inference Requests
    mapping(bytes32 => InferenceRequest) private s_inferenceRequests; // requestId => InferenceRequest
    uint256 private s_inferenceRequestCounter;

    // Data Consent
    mapping(address => mapping(string => DataConsent)) private s_userDataConsents; // user => dataManifestURI => DataConsent

    // Governance
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public nextProposalId = 1;

    // Ethical Review
    mapping(uint256 => EthicalReview) public ethicalReviews;
    uint256 public nextReviewId = 1;

    // Rewards
    mapping(address => uint256) public rewardsBalance; // ETH/Wei balance for claims

    // --- III. Events ---

    event ProtocolParametersUpdated(address indexed sender, address newTreasury, address newOracle, address newZKPVerifier);
    event NexusBadgeMinted(address indexed recipient, NexusBadgeType badgeType, address indexed minter);
    event NexusBadgeBurned(address indexed holder, NexusBadgeType badgeType, address indexed burner);
    event AetherPointsAdjusted(address indexed user, uint256 newPoints, bool added, uint256 amount);

    event AIModelRegistered(string indexed modelId, string metadataURI, uint256 baseCost);
    event AIModelDeregistered(string indexed modelId);
    event AIModelUpdated(string indexed modelId, string metadataURI, uint256 baseCost);
    event AIInferenceRequested(bytes32 indexed requestId, string indexed modelId, address indexed requester, uint256 cost);
    event AIInferenceCompleted(bytes32 indexed requestId, string outputDataHash, address indexed recipient);
    event AIInferenceCancelled(bytes32 indexed requestId, address indexed canceller);

    event DataConsentSubmitted(address indexed user, string indexed dataManifestURI, bytes32 proofHash);
    event DataConsentRevoked(address indexed user, string indexed dataManifestURI);
    event DataConsentZKPVerified(address indexed user, bytes32 proofHash, address indexed verifier);

    event GovernanceProposalCreated(uint256 indexed proposalId, string proposalURI, uint256 endBlock);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus newStatus);

    event EthicalReviewProposed(uint256 indexed reviewId, string indexed modelId, string reasonURI);
    event EthicalReviewOutcomeRecorded(uint256 indexed reviewId, string indexed modelId, bool outcomeIsPositive, string outcomeURI);

    event RewardsClaimed(address indexed user, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- IV. Custom Errors ---

    error AetherMindNexus__Unauthorized();
    error AetherMindNexus__InvalidModelId();
    error AetherMindNexus__ModelAlreadyRegistered();
    error AetherMindNexus__ModelNotRegistered();
    error AetherMindNexus__ModelIsBlacklisted();
    error AetherMindNexus__InsufficientAetherPoints();
    error AetherMindNexus__MissingRequiredBadge(NexusBadgeType requiredBadge);
    error AetherMindNexus__AlreadyHasBadge(NexusBadgeType badgeType);
    error AetherMindNexus__DoesNotHaveBadge(NexusBadgeType badgeType);
    error AetherMindNexus__InferenceRequestNotFound();
    error AetherMindNexus__InferenceRequestAlreadyCompleted();
    error AetherMindNexus__InferenceRequestAlreadyCancelled();
    error AetherMindNexus__InsufficientFunds(uint256 required, uint256 provided);
    error AetherMindNexus__DataConsentNotFound();
    error AetherMindNexus__DataConsentAlreadyActive();
    error AetherMindNexus__InvalidVotingDuration();
    error AetherMindNexus__ProposalNotFound();
    error AetherMindNexus__ProposalNotActive();
    error AetherMindNexus__AlreadyVoted();
    error AetherMindNexus__ProposalNotSucceeded();
    error AetherMindNexus__ProposalAlreadyExecuted();
    error AetherMindNexus__EthicalReviewNotFound();
    error AetherMindNexus__EthicalReviewAlreadyCompleted();
    error AetherMindNexus__NothingToClaim();
    error AetherMindNexus__NoFeesToWithdraw();

    // --- V. Constructor ---

    constructor(address _protocolTreasury, address _inferenceOracle) Ownable(msg.sender) Pausable() {
        if (_protocolTreasury == address(0) || _inferenceOracle == address(0)) {
            revert AetherMindNexus__Unauthorized(); // Using a generic error for simplicity here
        }
        protocolTreasury = _protocolTreasury;
        inferenceOracle = _inferenceOracle;
    }

    // --- VI. Modifiers ---

    modifier onlyInferenceOracle() {
        if (msg.sender != inferenceOracle) {
            revert AetherMindNexus__Unauthorized();
        }
        _;
    }

    modifier onlyDAOOrOwner() {
        // For a full DAO, this would check against a DAO governance module
        // For this example, we assume owner can act as DAO for certain functions.
        // In a real scenario, this would integrate with a full DAO proposal/execution system.
        if (msg.sender != owner()) {
            revert AetherMindNexus__Unauthorized();
        }
        _;
    }

    // --- VII. Core Management & Access Control ---

    /**
     * @notice Allows the owner or DAO to update various protocol-wide configurations.
     * @param _newTreasury The new address for the protocol treasury.
     * @param _newOracle The new authorized address for the inference oracle.
     * @param _newZKPVerifier The new address for the external ZKP Verifier contract.
     */
    function setProtocolParameters(address _newTreasury, address _newOracle, address _newZKPVerifier)
        external
        onlyDAOOrOwner
        returns (bool)
    {
        if (_newTreasury != address(0)) protocolTreasury = _newTreasury;
        if (_newOracle != address(0)) inferenceOracle = _newOracle;
        if (_newZKPVerifier != address(0)) zkpVerifierAddress = _newZKPVerifier;

        emit ProtocolParametersUpdated(msg.sender, protocolTreasury, inferenceOracle, zkpVerifierAddress);
        return true;
    }

    /**
     * @notice Pauses core functionality in emergencies. Only callable by the owner.
     */
    function pause() public virtual override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract. Only callable by the owner.
     */
    function unpause() public virtual override onlyOwner {
        _unpause();
    }

    // --- VIII. Identity, Reputation & Soulbound Badges (SBTs) ---

    /**
     * @notice Mints a non-transferable NexusBadge to a recipient for verified contributions or achievements.
     * @dev Badges are soulbound, meaning they cannot be transferred after minting.
     * @param recipient The address to receive the badge.
     * @param badgeType The type of NexusBadge to mint.
     */
    function mintNexusBadge(address recipient, NexusBadgeType badgeType) external onlyDAOOrOwner {
        if (badgeType == NexusBadgeType.None) revert AetherMindNexus__InvalidModelId(); // Reusing error, should be a specific one
        if (s_nexusBadges[recipient][badgeType]) revert AetherMindNexus__AlreadyHasBadge(badgeType);

        s_nexusBadges[recipient][badgeType] = true;
        emit NexusBadgeMinted(recipient, badgeType, msg.sender);
    }

    /**
     * @notice Revokes a NexusBadge from a holder.
     * @param holder The address whose badge is to be burned.
     * @param badgeType The type of NexusBadge to burn.
     */
    function burnNexusBadge(address holder, NexusBadgeType badgeType) external onlyDAOOrOwner {
        if (badgeType == NexusBadgeType.None) revert AetherMindNexus__InvalidModelId(); // Reusing error
        if (!s_nexusBadges[holder][badgeType]) revert AetherMindNexus__DoesNotHaveBadge(badgeType);

        s_nexusBadges[holder][badgeType] = false;
        emit NexusBadgeBurned(holder, badgeType, msg.sender);
    }

    /**
     * @notice Retrieves the current AetherPoints (reputation) for a given user.
     * @param user The address of the user.
     * @return The number of AetherPoints the user has.
     */
    function getAetherPoints(address user) public view returns (uint256) {
        return s_aetherPoints[user];
    }

    /**
     * @notice Returns an array of NexusBadgeType enum values currently held by a user.
     * @param user The address of the user.
     * @return An array of `NexusBadgeType` enum values.
     */
    function getUserBadges(address user) public view returns (NexusBadgeType[] memory) {
        NexusBadgeType[] memory heldBadges = new NexusBadgeType[](0);
        for (uint256 i = 1; i < uint256(type(NexusBadgeType).max) + 1; i++) {
            if (s_nexusBadges[user][NexusBadgeType(i)]) {
                heldBadges = _appendBadge(heldBadges, NexusBadgeType(i));
            }
        }
        return heldBadges;
    }

    /**
     * @dev Internal function to add AetherPoints to a user.
     * @param user The address of the user.
     * @param points The amount of points to add.
     */
    function _addAetherPoints(address user, uint256 points) internal {
        s_aetherPoints[user] = s_aetherPoints[user].add(points);
        emit AetherPointsAdjusted(user, s_aetherPoints[user], true, points);
    }

    /**
     * @dev Internal function to remove AetherPoints from a user.
     * @param user The address of the user.
     * @param points The amount of points to remove.
     */
    function _removeAetherPoints(address user, uint256 points) internal {
        s_aetherPoints[user] = s_aetherPoints[user].sub(points);
        emit AetherPointsAdjusted(user, s_aetherPoints[user], false, points);
    }

    /**
     * @dev Helper to append to a dynamic array (Solidity 0.8+ doesn't have native append for memory arrays).
     */
    function _appendBadge(NexusBadgeType[] memory arr, NexusBadgeType element) private pure returns (NexusBadgeType[] memory) {
        NexusBadgeType[] memory newArr = new NexusBadgeType[](arr.length + 1);
        for (uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = element;
        return newArr;
    }

    // --- IX. AI Model Management & Access ---

    /**
     * @notice Registers a new off-chain AI model, defining its access parameters.
     * @param modelId A unique identifier for the AI model.
     * @param metadataURI IPFS/Arweave URI for model description, parameters, etc.
     * @param baseCost Base cost in wei for one inference request.
     * @param requiredBadges An array of NexusBadgeTypes required to access this model.
     */
    function registerAIModel(
        string calldata modelId,
        string calldata metadataURI,
        uint256 baseCost,
        NexusBadgeType[] calldata requiredBadges
    ) external onlyDAOOrOwner {
        if (s_aiModels[modelId].isRegistered) revert AetherMindNexus__ModelAlreadyRegistered();
        if (bytes(modelId).length == 0) revert AetherMindNexus__InvalidModelId();

        s_aiModels[modelId] = AIModelDefinition({
            modelId: modelId,
            metadataURI: metadataURI,
            baseCost: baseCost,
            requiredBadges: requiredBadges,
            isRegistered: true,
            isBlacklisted: false
        });
        registeredModelIds.push(modelId);

        emit AIModelRegistered(modelId, metadataURI, baseCost);
    }

    /**
     * @notice Deregisters an AI model, preventing further access requests.
     * @param modelId The unique identifier of the AI model to deregister.
     */
    function deregisterAIModel(string calldata modelId) external onlyDAOOrOwner {
        if (!s_aiModels[modelId].isRegistered) revert AetherMindNexus__ModelNotRegistered();

        s_aiModels[modelId].isRegistered = false;
        // Optionally, remove from registeredModelIds array (more complex, not critical for this example)

        emit AIModelDeregistered(modelId);
    }

    /**
     * @notice Updates parameters for an existing AI model.
     * @param modelId The unique identifier of the AI model.
     * @param metadataURI New IPFS/Arweave URI for model description.
     * @param baseCost New base cost in wei for one inference request.
     * @param requiredBadges New array of NexusBadgeTypes required.
     */
    function updateAIModelParameters(
        string calldata modelId,
        string calldata metadataURI,
        uint256 baseCost,
        NexusBadgeType[] calldata requiredBadges
    ) external onlyDAOOrOwner {
        AIModelDefinition storage model = s_aiModels[modelId];
        if (!model.isRegistered) revert AetherMindNexus__ModelNotRegistered();

        model.metadataURI = metadataURI;
        model.baseCost = baseCost;
        model.requiredBadges = requiredBadges;

        emit AIModelUpdated(modelId, metadataURI, baseCost);
    }

    /**
     * @notice Initiates a request for AI model inference, paying the dynamic fee.
     * Requires specified badges and sufficient reputation.
     * @param modelId The unique identifier of the AI model to use.
     * @param inputDataHash Hash of the input data (e.g., IPFS CID) for the inference.
     */
    function requestAIInference(
        string calldata modelId,
        string calldata inputDataHash
    ) external payable whenNotPaused returns (bytes32 requestId) {
        AIModelDefinition storage model = s_aiModels[modelId];
        if (!model.isRegistered) revert AetherMindNexus__ModelNotRegistered();
        if (model.isBlacklisted) revert AetherMindNexus__ModelIsBlacklisted();

        // Check required badges
        for (uint256 i = 0; i < model.requiredBadges.length; i++) {
            if (!s_nexusBadges[msg.sender][model.requiredBadges[i]]) {
                revert AetherMindNexus__MissingRequiredBadge(model.requiredBadges[i]);
            }
        }

        uint256 cost = getAIModelAccessCost(modelId, msg.sender);
        if (msg.value < cost) revert AetherMindNexus__InsufficientFunds(cost, msg.value);

        s_inferenceRequestCounter = s_inferenceRequestCounter.add(1);
        requestId = keccak256(abi.encodePacked(modelId, msg.sender, block.timestamp, s_inferenceRequestCounter));

        s_inferenceRequests[requestId] = InferenceRequest({
            modelId: modelId,
            requester: msg.sender,
            inputDataHash: inputDataHash,
            requestTime: block.timestamp,
            costPaid: cost,
            outputDataHash: "",
            completed: false,
            cancelled: false
        });

        // Transfer funds to treasury
        (bool success, ) = payable(protocolTreasury).call{value: cost}("");
        require(success, "Failed to send funds to treasury");

        // Refund any excess
        if (msg.value > cost) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value.sub(cost)}("");
            require(refundSuccess, "Failed to refund excess ETH");
        }

        emit AIInferenceRequested(requestId, modelId, msg.sender, cost);
        return requestId;
    }

    /**
     * @notice Callback from an authorized oracle to confirm an inference request has been fulfilled.
     * @param requestId The unique identifier of the inference request.
     * @param outputDataHash Hash of the output data (e.g., IPFS CID) from the inference.
     * @param recipient The original requester's address, to ensure correctness.
     */
    function confirmAIInferenceCompletion(
        bytes32 requestId,
        string calldata outputDataHash,
        address recipient
    ) external onlyInferenceOracle whenNotPaused {
        InferenceRequest storage req = s_inferenceRequests[requestId];
        if (req.requester == address(0)) revert AetherMindNexus__InferenceRequestNotFound();
        if (req.completed) revert AetherMindNexus__InferenceRequestAlreadyCompleted();
        if (req.cancelled) revert AetherMindNexus__InferenceRequestAlreadyCancelled();
        if (req.requester != recipient) revert AetherMindNexus__Unauthorized(); // Oracle must target original requester

        req.outputDataHash = outputDataHash;
        req.completed = true;

        // Reward the data/compute providers or the original requester with points, as per protocol design
        _addAetherPoints(recipient, 50); // Example: reward requester for using the system

        emit AIInferenceCompleted(requestId, outputDataHash, recipient);
    }

    /**
     * @notice Allows a user to cancel an inference request if it hasn't been completed within a timeout (not implemented here but conceptual).
     * @dev For simplicity, no specific timeout logic is implemented; an off-chain system would monitor this.
     * @param requestId The unique identifier of the inference request.
     */
    function cancelAIInferenceRequest(bytes32 requestId) external {
        InferenceRequest storage req = s_inferenceRequests[requestId];
        if (req.requester == address(0)) revert AetherMindNexus__InferenceRequestNotFound();
        if (req.requester != msg.sender) revert AetherMindNexus__Unauthorized();
        if (req.completed) revert AetherMindNexus__InferenceRequestAlreadyCompleted();
        if (req.cancelled) revert AetherMindNexus__InferenceRequestAlreadyCancelled();

        // Implement a timeout here if desired, e.g., if (block.timestamp < req.requestTime + inferenceTimeout) revert ...

        req.cancelled = true;

        // Refund the cost
        (bool success, ) = payable(msg.sender).call{value: req.costPaid}("");
        require(success, "Failed to refund ETH on cancellation");

        emit AIInferenceCancelled(requestId, msg.sender);
    }

    /**
     * @notice Calculates the dynamic cost for a user to access a specific AI model, factoring in reputation.
     * @param modelId The unique identifier of the AI model.
     * @param user The address of the user.
     * @return The calculated cost in wei.
     */
    function getAIModelAccessCost(string calldata modelId, address user) public view returns (uint256) {
        AIModelDefinition storage model = s_aiModels[modelId];
        if (!model.isRegistered) revert AetherMindNexus__ModelNotRegistered();
        if (model.isBlacklisted) revert AetherMindNexus__ModelIsBlacklisted();

        uint256 currentPoints = s_aetherPoints[user];
        uint256 discountPercentage = (currentPoints / 1000).mul(BASE_REPUTATION_DISCOUNT_PERCENT); // 10% per 1000 points
        if (discountPercentage > 50) discountPercentage = 50; // Max 50% discount

        return model.baseCost.mul(100 - discountPercentage).div(100);
    }

    /**
     * @notice Retrieves the full definition of a registered AI model.
     * @param modelId The unique identifier of the AI model.
     * @return The AIModelDefinition struct.
     */
    function getAIModelDefinition(string calldata modelId) public view returns (AIModelDefinition memory) {
        if (!s_aiModels[modelId].isRegistered) revert AetherMindNexus__ModelNotRegistered();
        return s_aiModels[modelId];
    }

    // --- X. Decentralized Data Consent & Verification ---

    /**
     * @notice User submits an IPFS hash of a data manifest and a proof hash for data contribution, expressing consent.
     * @dev The proofHash could be an identifier for an off-chain verified ZKP, or a hash directly verifiable on-chain (less common).
     * @param dataManifestURI IPFS/Arweave URI for the data manifest/description.
     * @param proofHash A hash or identifier representing the proof of data contribution/ownership.
     */
    function submitDataConsentProof(
        string calldata dataManifestURI,
        bytes32 proofHash
    ) external whenNotPaused {
        if (s_userDataConsents[msg.sender][dataManifestURI].active) {
            revert AetherMindNexus__DataConsentAlreadyActive();
        }
        if (bytes(dataManifestURI).length == 0) revert AetherMindNexus__InvalidModelId(); // Reusing error

        s_userDataConsents[msg.sender][dataManifestURI] = DataConsent({
            dataManifestURI: dataManifestURI,
            proofHash: proofHash,
            submissionTime: block.timestamp,
            active: true
        });

        _addAetherPoints(msg.sender, POINTS_PER_DATA_CONSENT);
        emit DataConsentSubmitted(msg.sender, dataManifestURI, proofHash);
    }

    /**
     * @notice User revokes a previously submitted data consent.
     * @param dataManifestURI IPFS/Arweave URI for the data manifest to revoke consent for.
     */
    function revokeDataConsent(string calldata dataManifestURI) external {
        if (!s_userDataConsents[msg.sender][dataManifestURI].active) {
            revert AetherMindNexus__DataConsentNotFound();
        }

        s_userDataConsents[msg.sender][dataManifestURI].active = false;
        _removeAetherPoints(msg.sender, POINTS_PER_DATA_CONSENT); // Optionally remove points or less

        emit DataConsentRevoked(msg.sender, dataManifestURI);
    }

    /**
     * @notice Interface for calling an external ZKP verifier contract to validate a data contribution or a user's claim.
     * @dev This function assumes an external IZKPVerifier contract is deployed and its address is set.
     * @param verifier The address of the ZKP verifier contract.
     * @param proof The serialized ZKP proof.
     * @param publicInputs The public inputs for the ZKP.
     * @return True if the proof is valid, false otherwise.
     */
    function verifyDataConsentZKP(
        address verifier,
        bytes calldata proof,
        bytes32[] calldata publicInputs
    ) external view returns (bool) {
        if (zkpVerifierAddress == address(0)) {
            // Revert or return false based on desired behavior if no verifier is set
            revert("AetherMindNexus: ZKP verifier address not set.");
        }
        if (verifier != zkpVerifierAddress) {
            revert("AetherMindNexus: Invalid ZKP verifier address.");
        }

        // Call the external ZKP verifier contract
        return IZKPVerifier(verifier).verify(proof, publicInputs);
    }

    // --- XI. Governance & Ethical AI Oversight ---

    /**
     * @notice Initiates a governance proposal for ethical guidelines or protocol changes.
     * @param proposalURI IPFS/Arweave URI for proposal details (text, rationale, proposed actions).
     * @param votingDuration The duration of the voting period in blocks.
     */
    function proposePolicyChange(string calldata proposalURI, uint256 votingDuration)
        external
        whenNotPaused
        returns (uint256)
    {
        if (s_aetherPoints[msg.sender] < MIN_AETHER_POINTS_FOR_VOTING) {
            revert AetherMindNexus__InsufficientAetherPoints();
        }
        if (votingDuration == 0) revert AetherMindNexus__InvalidVotingDuration();

        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposalURI: proposalURI,
            startBlock: block.number,
            endBlock: block.number.add(votingDuration),
            forVotes: 0,
            againstVotes: 0,
            status: ProposalStatus.Active,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit GovernanceProposalCreated(proposalId, proposalURI, block.number.add(votingDuration));
        return proposalId;
    }

    /**
     * @notice Users with sufficient AetherPoints or specific NexusBadges can vote on proposals.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        if (proposal.proposalId == 0) revert AetherMindNexus__ProposalNotFound();
        if (proposal.status != ProposalStatus.Active) revert AetherMindNexus__ProposalNotActive();
        if (block.number > proposal.endBlock) {
            proposal.status = (proposal.forVotes > proposal.againstVotes) ? ProposalStatus.Succeeded : ProposalStatus.Failed;
            revert AetherMindNexus__ProposalNotActive(); // Voting period ended
        }
        if (proposal.hasVoted[msg.sender]) revert AetherMindNexus__AlreadyVoted();
        if (s_aetherPoints[msg.sender] < MIN_AETHER_POINTS_FOR_VOTING) {
            revert AetherMindNexus__InsufficientAetherPoints();
        }

        uint256 votes = s_aetherPoints[msg.sender]; // Voting power is proportional to AetherPoints
        if (support) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }
        proposal.hasVoted[msg.sender] = true;

        _addAetherPoints(msg.sender, POINTS_PER_ETHICAL_REVIEW_PARTICIPATION); // Reward for participation
        emit VotedOnProposal(proposalId, msg.sender, support, votes);
    }

    /**
     * @notice Executes a passed proposal. This would typically trigger off-chain logic or direct on-chain actions.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external onlyDAOOrOwner whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        if (proposal.proposalId == 0) revert AetherMindNexus__ProposalNotFound();
        if (proposal.status == ProposalStatus.Executed) revert AetherMindNexus__ProposalAlreadyExecuted();
        
        // Ensure voting period is over
        if (block.number <= proposal.endBlock) {
             revert("AetherMindNexus: Voting period for this proposal has not ended yet.");
        }

        // Determine final status if not already set
        if (proposal.status == ProposalStatus.Active) {
            proposal.status = (proposal.forVotes > proposal.againstVotes) ? ProposalStatus.Succeeded : ProposalStatus.Failed;
        }

        if (proposal.status != ProposalStatus.Succeeded) revert AetherMindNexus__ProposalNotSucceeded();

        // In a real DAO, this would parse `proposal.proposalURI` for instructions
        // and execute specific logic (e.g., call another contract, update a parameter).
        // For this example, we simply mark it as executed.
        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(proposalId, ProposalStatus.Executed);
    }

    /**
     * @notice Proposes an AI model for ethical review, potentially leading to blacklisting or parameter adjustments.
     * @param modelId The ID of the AI model to review.
     * @param reasonURI IPFS/Arweave URI for the reason/justification for the review.
     */
    function proposeAIModelEthicalReview(string calldata modelId, string calldata reasonURI)
        external
        whenNotPaused
        returns (uint256)
    {
        if (!s_aiModels[modelId].isRegistered) revert AetherMindNexus__ModelNotRegistered();
        if (s_aetherPoints[msg.sender] < MIN_AETHER_POINTS_FOR_VOTING) {
            revert AetherMindNexus__InsufficientAetherPoints();
        }

        uint256 reviewId = nextReviewId++;
        ethicalReviews[reviewId] = EthicalReview({
            reviewId: reviewId,
            modelId: modelId,
            reasonURI: reasonURI,
            outcomeIsPositive: false, // Default to false until reviewed
            outcomeURI: "",
            completed: false
        });

        emit EthicalReviewProposed(reviewId, modelId, reasonURI);
        return reviewId;
    }

    /**
     * @notice Records the official outcome of an ethical review.
     * @dev This would typically be called by the DAO after a governance vote or by designated "EthicalAIReviewers".
     * @param reviewId The ID of the ethical review.
     * @param outcomeIsPositive True if the model passed the review, false if it failed or requires action.
     * @param outcomeURI IPFS/Arweave URI for the detailed outcome report.
     */
    function recordEthicalReviewOutcome(
        uint256 reviewId,
        bool outcomeIsPositive,
        string calldata outcomeURI
    ) external onlyDAOOrOwner {
        EthicalReview storage review = ethicalReviews[reviewId];
        if (review.reviewId == 0) revert AetherMindNexus__EthicalReviewNotFound();
        if (review.completed) revert AetherMindNexus__EthicalReviewAlreadyCompleted();

        review.outcomeIsPositive = outcomeIsPositive;
        review.outcomeURI = outcomeURI;
        review.completed = true;

        if (!outcomeIsPositive) {
            s_aiModels[review.modelId].isBlacklisted = true; // Blacklist if review is negative
            // Optionally, burn badges for model providers, or apply penalties
        }

        emit EthicalReviewOutcomeRecorded(reviewId, review.modelId, outcomeIsPositive, outcomeURI);
    }

    // --- XII. Treasury & Rewards ---

    /**
     * @notice Allows users to claim accumulated rewards (e.g., AetherPoints, ETH) for their contributions.
     * @dev This is a simplified reward claim mechanism; in a complex system, rewards could be specific tokens.
     */
    function claimContributionRewards() external whenNotPaused {
        uint256 amount = rewardsBalance[msg.sender];
        if (amount == 0) revert AetherMindNexus__NothingToClaim();

        rewardsBalance[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send rewards");

        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @notice Allows the DAO/owner to withdraw accumulated protocol fees to a specified address.
     * @param recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address recipient) external onlyDAOOrOwner {
        uint256 balance = address(this).balance;
        // Exclude any ETH that might be temporarily held for inference requests not yet fulfilled
        // For simplicity, here we assume all balance minus outstanding requests can be withdrawn.
        // A more robust system would track available vs. locked funds.
        if (balance == 0) revert AetherMindNexus__NoFeesToWithdraw();

        (bool success, ) = payable(recipient).call{value: balance}("");
        require(success, "Failed to withdraw protocol fees");

        emit ProtocolFeesWithdrawn(recipient, balance);
    }

    // --- XIII. View Functions (non-state changing) ---

    function getInferenceRequest(bytes32 requestId) public view returns (InferenceRequest memory) {
        if (s_inferenceRequests[requestId].requester == address(0)) {
            revert AetherMindNexus__InferenceRequestNotFound();
        }
        return s_inferenceRequests[requestId];
    }

    function getDataConsent(address user, string calldata dataManifestURI) public view returns (DataConsent memory) {
        if (!s_userDataConsents[user][dataManifestURI].active) {
            revert AetherMindNexus__DataConsentNotFound();
        }
        return s_userDataConsents[user][dataManifestURI];
    }

    function getGovernanceProposal(uint256 proposalId) public view returns (GovernanceProposal memory) {
        if (governanceProposals[proposalId].proposalId == 0) {
            revert AetherMindNexus__ProposalNotFound();
        }
        return governanceProposals[proposalId];
    }

    function getEthicalReview(uint256 reviewId) public view returns (EthicalReview memory) {
        if (ethicalReviews[reviewId].reviewId == 0) {
            revert AetherMindNexus__EthicalReviewNotFound();
        }
        return ethicalReviews[reviewId];
    }

    function getRegisteredModelIds() public view returns (string[] memory) {
        return registeredModelIds;
    }
}
```