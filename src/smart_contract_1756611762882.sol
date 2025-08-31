The following smart contract, `PersonaNet`, introduces several advanced, creative, and trendy concepts within a decentralized service marketplace. It leverages Soulbound Tokens (SBTs) for identity, integrates a hypothetical AI oracle for reputation assessment, and features a dynamic reputation system, along with a robust task and escrow management.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary for PersonaNet Protocol

/*
Contract Name: PersonaNet

Core Idea: PersonaNet is a decentralized service marketplace where service providers are represented by unique, non-transferable Soulbound Tokens (SBTs) called "Personas". These Personas accumulate a dynamic reputation score, which is augmented by AI-powered sentiment analysis of client reviews and task performance. The protocol aims to foster a high-trust environment for on-chain service provision, where a provider's identity and credibility are tied to their on-chain actions and AI-verified feedback.

Advanced Concepts:
1.  Soulbound Tokens (SBTs): Non-transferable identity tokens (`ERC721` with `_transfer` overridden) representing a provider's on-chain persona and reputation. Once minted, they cannot be sold or transferred, making reputation truly personal.
2.  AI Oracle Integration: An interface for an off-chain AI service to perform sentiment analysis on client reviews and task outcomes. The AI's verdict directly influences a provider's reputation, bringing off-chain intelligence into on-chain trust.
3.  Dynamic Reputation System: Reputation scores are not static; they continuously evolve based on completed tasks, AI-analyzed reviews (positive or negative), and dispute resolutions. This provides a live, adaptive measure of a provider's reliability.
4.  Programmable Escrow: Securely holds funds for service tasks. Funds are released conditionally upon task completion, AI verification, or dispute resolution, mitigating counterparty risk.
5.  Modular Dispute Resolution: A simplified but extensible framework allowing for the resolution of disagreements between parties, with the power to penalize reputation and distribute funds. This can be expanded with DAO-based or more complex arbitration mechanisms in the future.
6.  Gamification Elements: Minimum reputation requirements for service listings introduce a tiered system where higher reputation unlocks access to more lucrative or specialized tasks, incentivizing good behavior.

I. Core Persona SBT & Identity Management
    1.  `mintPersonaSBT()`: Allows any address to mint a new, unique, non-transferable Persona SBT. This establishes their on-chain identity within PersonaNet.
    2.  `burnPersonaSBT()`: Enables a Persona holder to destroy their SBT, effectively resetting their on-chain identity and accumulated reputation.
    3.  `getPersonaReputation(address holder)`: Retrieves the current AI-augmented reputation score associated with a specific Persona holder.
    4.  `updatePersonaProfile(string memory newBio, string memory newSkills)`: Allows Persona holders to update their public profile metadata, such as a biography and list of skills.
    5.  `personaExists(address holder)`: A utility function to check if a given address currently holds an active Persona SBT.

II. AI Oracle & Reputation Augmentation
    6.  `setAIOracleAddress(address _oracle)`: Owner-only function to set the address of the trusted external AI oracle contract.
    7.  `addOracleAllowedCaller(address _caller)`: Owner-only function to authorize an address that is permitted to submit AI analysis verdicts to the contract.
    8.  `removeOracleAllowedCaller(address _caller)`: Owner-only function to revoke authorization for an address that previously submitted AI analysis verdicts.
    9.  `requestAIReputationAnalysis(uint256 taskId, string memory reviewText)`: Initiated by a client after marking a task completed, this function requests the AI oracle to analyze the provided review text for sentiment and performance indicators.
    10. `receiveAIReputationVerdict(uint256 taskId, int256 aiScoreDelta, bytes32 oracleId)`: A callback function, callable only by authorized oracles, to deliver the AI's sentiment analysis verdict. This verdict directly adjusts the provider's reputation score.

III. Service Listing & Discovery
    11. `listService(string memory title, string memory description, uint256 price, uint256 minReputationRequired)`: Allows a Persona holder to list a new service, specifying its details, price, and the minimum reputation a client must have to hire them.
    12. `updateService(uint256 serviceId, string memory title, string memory description, uint256 price)`: Enables a service provider to modify the details of their existing service listing.
    13. `deactivateService(uint256 serviceId)`: Deactivates a service listing, making it temporarily unavailable for new tasks.
    14. `reactivateService(uint256 serviceId)`: Reactivates a previously deactivated service listing.
    15. `getServiceDetails(uint256 serviceId)`: Retrieves comprehensive details about a specific service listing, including provider, price, and reputation requirements.

IV. Task & Escrow Management
    16. `initiateTask(uint256 serviceId, address provider, string memory taskDetails)`: Client initiates a task for a specified service and provider, sending the service price into an escrow.
    17. `providerAcceptTask(uint256 taskId)`: The service provider officially accepts an initiated task, moving it from 'Open' to 'Accepted' status.
    18. `clientMarkTaskCompleted(uint256 taskId, string memory reviewText)`: Client marks a task as successfully completed and provides a review, automatically triggering an AI reputation analysis request.
    19. `providerRequestPayment(uint256 taskId)`: Provider formally requests payment after the client has marked the task complete and AI analysis (if any) has been received.
    20. `releasePayment(uint256 taskId)`: Releases the escrowed funds to the provider after the task is completed, AI analysis is received, and no dispute is active. A platform fee is deducted.
    21. `clientCancelTask(uint256 taskId)`: Client can cancel a task before the provider accepts it, resulting in a full refund of the escrowed amount.
    22. `providerCancelTask(uint256 taskId)`: Provider can cancel a task before accepting it, also resulting in a full refund to the client.

V. Dispute Resolution & Penalties
    23. `raiseDispute(uint256 taskId, string memory reason)`: Either the client or provider can formally raise a dispute over an ongoing or recently completed task.
    24. `submitDisputeEvidence(uint256 taskId, string memory evidenceCID)`: Allows parties involved in a dispute to submit off-chain evidence (e.g., an IPFS Content Identifier) to support their case.
    25. `resolveDispute(uint256 taskId, address winner, int256 reputationPenalty, uint256 payoutToWinner, uint256 refundToLoser)`: Owner-only function to resolve a dispute. It determines the winner, applies a reputation penalty to the loser, and distributes the escrowed funds accordingly.

VI. Platform Configuration & Governance
    26. `setPlatformFee(uint256 newFeeBasisPoints)`: Owner-only function to set the platform's transaction fee, expressed in basis points (e.g., 100 for 1%).
    27. `withdrawFees(address recipient)`: Owner-only function to withdraw accumulated platform fees to a specified recipient address.
    28. `pauseContract()`: Owner-only emergency function to pause core functionalities (like task initiation and payment release) of the contract.
    29. `unpauseContract()`: Owner-only function to unpause the contract after an emergency.
    30. `setMinimumReputationForListing(uint256 minRep)`: Owner-only function to adjust the global minimum reputation score required for a provider to list any service.
    31. `transferOwnership(address newOwner)`: Inherited from `Ownable`, allows the current owner to transfer ownership of the contract to a new address.
*/

// Interface for a hypothetical AI Oracle contract
// This interface defines the expected function signature for the PersonaNet contract to
// interact with an off-chain AI service provider, typically via a Chainlink adapter
// or a custom oracle network. The actual AI computation happens off-chain.
interface IAIOracle {
    /**
     * @dev Requests an AI analysis of a task's review.
     * The AI Oracle contract would listen for this call, perform off-chain analysis,
     * and then call `receiveAIReputationVerdict` on the PersonaNet contract.
     * @param taskId The ID of the task being reviewed.
     * @param provider The address of the service provider.
     * @param client The address of the client who provided the review.
     * @param reviewText The actual text of the review.
     */
    function requestAnalysis(uint256 taskId, address provider, address client, string memory reviewText) external;
}

contract PersonaNet is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Persona SBT specific data
    struct Persona {
        address holder;
        uint256 tokenId;
        int256 reputationScore; // Can be negative for bad actors
        string bio;
        string skills;
        uint256 lastReputationUpdate; // Timestamp of last update
    }

    mapping(address => uint256) private _addressToTokenId; // Maps address to their Persona Token ID
    mapping(uint256 => Persona) public personas; // Maps Persona Token ID to Persona details
    Counters.Counter private _personaTokenIds; // Counter for Persona Token IDs (starts at 1)

    // Service Listing Data
    struct Service {
        uint256 serviceId;
        address provider;
        string title;
        string description;
        uint256 price; // In native token (e.g., Ether)
        uint256 minReputationRequired; // Minimum reputation score a client must have to hire this service
        bool active;
        uint255 createdAt;
    }

    mapping(uint256 => Service) public services;
    Counters.Counter private _serviceIds; // Counter for service listings (starts at 1)

    // Task & Escrow Data
    enum TaskStatus {
        Open,               // Initiated by client, waiting for provider acceptance
        Accepted,           // Provider accepted, task in progress
        ClientCompleted,    // Client marked complete, waiting for AI analysis & provider request
        ProviderRequestedPayment, // Provider requested payment after client completed
        Completed,          // Funds released to provider
        ClientCanceled,     // Client canceled before acceptance, funds refunded
        ProviderCanceled,   // Provider canceled before acceptance, funds refunded
        Disputed,           // Task is under formal dispute
        DisputeResolved     // Dispute resolved, funds distributed
    }

    struct Task {
        uint256 taskId;
        uint256 serviceId;
        address client;
        address provider;
        string taskDetails;
        uint256 amountEscrowed; // Amount held in escrow for this task
        TaskStatus status;
        uint224 createdAt;
        uint224 completedAt; // Timestamp when client marked completed

        // AI reputation related fields
        string clientReviewText; // Review text provided by client for AI analysis
        int256 aiReputationDelta; // AI's suggested reputation change for the provider
        bool aiAnalysisReceived; // True if AI oracle has submitted its verdict for this task

        // Dispute related fields
        bool disputeRaised;
        address disputeRaiser; // Address that raised the dispute
        string disputeReason;
        string disputeEvidenceCID; // IPFS CID for submitted evidence (simplified, could be array)
    }

    mapping(uint256 => Task) public tasks;
    Counters.Counter private _taskIds; // Counter for tasks (starts at 1)

    // Platform Configuration
    address public aiOracleAddress; // Address of the trusted AI oracle contract
    mapping(address => bool) public isOracleAllowedCaller; // Addresses authorized to call receiveAIReputationVerdict
    uint256 public platformFeeBasisPoints; // e.g., 100 for 1% (10000 basis points = 100%)
    uint256 public accumulatedFees; // Total fees collected by the platform
    int256 public minimumReputationForListing; // Minimum reputation required for a provider to list services

    // --- Events ---
    event PersonaMinted(address indexed holder, uint256 tokenId, int256 initialReputation);
    event PersonaBurned(address indexed holder, uint256 tokenId);
    event PersonaProfileUpdated(address indexed holder, uint256 tokenId, string newBio, string newSkills);
    event ReputationUpdated(address indexed holder, uint256 tokenId, int256 oldScore, int256 newScore, string reason);

    event AIOracleAddressSet(address indexed newAddress);
    event OracleAllowedCallerUpdated(address indexed caller, bool allowed);
    event AIReputationAnalysisRequested(uint256 indexed taskId, address indexed provider, address indexed client, string reviewText);
    event AIReputationVerdictReceived(uint256 indexed taskId, address indexed provider, int256 aiScoreDelta, bytes32 oracleId);

    event ServiceListed(uint256 indexed serviceId, address indexed provider, string title, uint256 price, uint256 minReputationRequired);
    event ServiceUpdated(uint256 indexed serviceId, string title, uint256 price);
    event ServiceStatusChanged(uint256 indexed serviceId, bool active);

    event TaskInitiated(uint256 indexed taskId, uint256 indexed serviceId, address indexed client, address provider, uint256 amount);
    event TaskStatusChanged(uint256 indexed taskId, TaskStatus oldStatus, TaskStatus newStatus);
    event PaymentReleased(uint256 indexed taskId, address indexed provider, uint256 amount);
    event TaskCanceled(uint256 indexed taskId, address indexed by, string reason);

    event DisputeRaised(uint256 indexed taskId, address indexed raiser, string reason);
    event DisputeEvidenceSubmitted(uint256 indexed taskId, address indexed submitter, string evidenceCID);
    event DisputeResolved(uint256 indexed taskId, address indexed winner, address indexed loser, int256 reputationPenalty, uint256 payoutToWinner, uint256 refundToLoser);

    event PlatformFeeSet(uint256 newFeeBasisPoints);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event MinimumReputationForListingSet(int256 newMinRep);

    // --- Modifiers ---
    modifier onlyPersonaHolder() {
        require(_addressToTokenId[msg.sender] != 0, "PersonaNet: Caller does not hold a Persona SBT");
        _;
    }

    modifier onlyServiceOwner(uint256 _serviceId) {
        require(services[_serviceId].provider == msg.sender, "PersonaNet: Not service owner");
        _;
    }

    modifier onlyTaskClient(uint256 _taskId) {
        require(tasks[_taskId].client == msg.sender, "PersonaNet: Not task client");
        _;
    }

    modifier onlyTaskProvider(uint256 _taskId) {
        require(tasks[_taskId].provider == msg.sender, "PersonaNet: Not task provider");
        _;
    }

    modifier onlyOracleAllowed() {
        require(isOracleAllowedCaller[msg.sender], "PersonaNet: Not an allowed oracle caller");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the PersonaNet contract, setting the name and symbol for the SBT,
     * assigning initial ownership, and configuring the AI oracle address and default fees.
     * @param _aiOracleAddress The address of the trusted AI Oracle contract.
     */
    constructor(address _aiOracleAddress) ERC721("PersonaNet Persona SBT", "PN_SBT") Ownable(msg.sender) {
        require(_aiOracleAddress != address(0), "PersonaNet: AI Oracle address cannot be zero");
        aiOracleAddress = _aiOracleAddress;
        isOracleAllowedCaller[msg.sender] = true; // Owner can initially act as an oracle caller for testing/initial setup
        platformFeeBasisPoints = 100; // 1% fee by default
        minimumReputationForListing = 0; // No minimum reputation required to list initially
    }

    // --- I. Core Persona SBT & Identity Management ---

    /**
     * @dev Mints a new Persona SBT for the caller. Each address can only hold one Persona.
     * @return newTokenId The ID of the newly minted Persona SBT.
     */
    function mintPersonaSBT() public payable nonReentrant whenNotPaused returns (uint256) {
        require(_addressToTokenId[msg.sender] == 0, "PersonaNet: Address already holds a Persona SBT");
        require(msg.value == 0, "PersonaNet: Minting fee not supported yet, send 0 ETH."); // Could be extended to charge a minting fee

        _personaTokenIds.increment();
        uint256 newTokenId = _personaTokenIds.current();

        Persona storage newPersona = personas[newTokenId];
        newPersona.holder = msg.sender;
        newPersona.tokenId = newTokenId;
        newPersona.reputationScore = 0; // Start with neutral reputation
        newPersona.lastReputationUpdate = block.timestamp;

        _safeMint(msg.sender, newTokenId); // Mint the ERC721 token
        _addressToTokenId[msg.sender] = newTokenId; // Map address to token ID

        emit PersonaMinted(msg.sender, newTokenId, 0);
        return newTokenId;
    }

    /**
     * @dev Overrides the ERC721 _transfer function to prevent transfers, making Personas Soulbound.
     * @param from The address from which the token is being transferred.
     * @param to The address to which the token is being transferred.
     * @param tokenId The ID of the token being transferred.
     */
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        revert("PersonaNet: Persona SBTs are non-transferable (Soulbound).");
    }

    /**
     * @dev Allows a Persona holder to burn their Persona SBT, effectively resetting their on-chain identity.
     * All associated reputation and profile data will be lost.
     */
    function burnPersonaSBT() public virtual onlyPersonaHolder {
        uint256 tokenId = _addressToTokenId[msg.sender];
        require(personas[tokenId].holder == msg.sender, "PersonaNet: Only holder can burn their Persona");

        _addressToTokenId[msg.sender] = 0; // Clear the address-to-token mapping
        delete personas[tokenId]; // Delete persona data from storage

        _burn(tokenId); // Burn the underlying ERC721 token
        emit PersonaBurned(msg.sender, tokenId);
    }

    /**
     * @dev Retrieves the current AI-augmented reputation score for a specific Persona holder.
     * @param holder The address of the Persona holder.
     * @return The current reputation score.
     */
    function getPersonaReputation(address holder) public view returns (int256) {
        require(personaExists(holder), "PersonaNet: No Persona SBT found for address");
        uint256 tokenId = _addressToTokenId[holder];
        return personas[tokenId].reputationScore;
    }

    /**
     * @dev Allows a Persona holder to update their public profile's biography and skills.
     * @param newBio The new biography string.
     * @param newSkills The new skills string.
     */
    function updatePersonaProfile(string memory newBio, string memory newSkills) public onlyPersonaHolder whenNotPaused {
        uint256 tokenId = _addressToTokenId[msg.sender];
        personas[tokenId].bio = newBio;
        personas[tokenId].skills = newSkills;
        emit PersonaProfileUpdated(msg.sender, tokenId, newBio, newSkills);
    }

    /**
     * @dev Checks if a given address holds an active Persona SBT.
     * @param holder The address to check.
     * @return True if the address holds a Persona SBT, false otherwise.
     */
    function personaExists(address holder) public view returns (bool) {
        return _addressToTokenId[holder] != 0;
    }

    // --- II. AI Oracle & Reputation Augmentation ---

    /**
     * @dev Owner-only function to set the address of the trusted AI oracle contract.
     * @param _oracle The new address for the AI oracle.
     */
    function setAIOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "PersonaNet: AI Oracle address cannot be zero");
        aiOracleAddress = _oracle;
        emit AIOracleAddressSet(_oracle);
    }

    /**
     * @dev Owner-only function to authorize an address to submit AI analysis verdicts.
     * This is crucial for managing which external entities can update reputation.
     * @param _caller The address to authorize.
     */
    function addOracleAllowedCaller(address _caller) public onlyOwner {
        require(_caller != address(0), "PersonaNet: Caller address cannot be zero");
        isOracleAllowedCaller[_caller] = true;
        emit OracleAllowedCallerUpdated(_caller, true);
    }

    /**
     * @dev Owner-only function to revoke authorization for an address to submit AI analysis verdicts.
     * @param _caller The address to de-authorize.
     */
    function removeOracleAllowedCaller(address _caller) public onlyOwner {
        require(_caller != address(0), "PersonaNet: Caller address cannot be zero");
        isOracleAllowedCaller[_caller] = false;
        emit OracleAllowedCallerUpdated(_caller, false);
    }

    /**
     * @dev Client initiates a request to the AI oracle for sentiment analysis of a completed task's review.
     * This function is typically called by the client after `clientMarkTaskCompleted`.
     * @param taskId The ID of the task to be analyzed.
     * @param reviewText The review text provided by the client.
     */
    function requestAIReputationAnalysis(uint256 taskId, string memory reviewText) public onlyTaskClient(taskId) whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.ClientCompleted, "PersonaNet: Task not in ClientCompleted status for AI analysis");
        require(!task.aiAnalysisReceived, "PersonaNet: AI analysis already requested or received for this task");
        require(bytes(reviewText).length > 0, "PersonaNet: Review text cannot be empty");

        task.clientReviewText = reviewText;
        
        // Call the external AI Oracle contract to request analysis
        // The actual AI processing happens off-chain, and the oracle will call back `receiveAIReputationVerdict`
        IAIOracle(aiOracleAddress).requestAnalysis(taskId, task.provider, task.client, reviewText);

        emit AIReputationAnalysisRequested(taskId, task.provider, task.client, reviewText);
    }

    /**
     * @dev Callback function for an authorized AI oracle to deliver its sentiment analysis verdict.
     * This function updates the provider's reputation based on the AI's `aiScoreDelta`.
     * @param taskId The ID of the task that was analyzed.
     * @param aiScoreDelta The change in reputation score suggested by the AI (can be positive or negative).
     * @param oracleId A unique identifier for the oracle's request/response, useful for preventing replay attacks.
     */
    function receiveAIReputationVerdict(uint256 taskId, int256 aiScoreDelta, bytes32 oracleId) public onlyOracleAllowed whenNotPaused {
        Task storage task = tasks[taskId];
        // Allow verdict for ClientCompleted or ProviderRequestedPayment states
        require(task.status == TaskStatus.ClientCompleted || task.status == TaskStatus.ProviderRequestedPayment, "PersonaNet: Task not ready for AI verdict");
        require(!task.aiAnalysisReceived, "PersonaNet: AI analysis already received for this task");
        require(personaExists(task.provider), "PersonaNet: Provider's Persona does not exist");
        // Further checks could be added here, e.g., verifying oracleId against a mapping of pending requests

        task.aiReputationDelta = aiScoreDelta;
        task.aiAnalysisReceived = true;

        // Apply reputation update to provider
        uint256 providerTokenId = _addressToTokenId[task.provider];
        int256 oldScore = personas[providerTokenId].reputationScore;
        personas[providerTokenId].reputationScore += aiScoreDelta;
        personas[providerTokenId].lastReputationUpdate = block.timestamp;

        emit AIReputationVerdictReceived(taskId, task.provider, aiScoreDelta, oracleId);
        emit ReputationUpdated(task.provider, providerTokenId, oldScore, personas[providerTokenId].reputationScore, "AI analysis of task review");
    }

    // --- III. Service Listing & Discovery ---

    /**
     * @dev Allows a Persona holder to list a new service on the marketplace.
     * Requires the provider to meet a minimum reputation threshold.
     * @param title The title of the service.
     * @param description A detailed description of the service.
     * @param price The price of the service in the native token (e.g., ETH).
     * @param minReputationRequired The minimum reputation a client must have to initiate a task for this service.
     * @return newServiceId The ID of the newly listed service.
     */
    function listService(string memory title, string memory description, uint256 price, uint256 minReputationRequired) public onlyPersonaHolder whenNotPaused returns (uint256) {
        require(price > 0, "PersonaNet: Service price must be greater than zero");
        require(bytes(title).length > 0, "PersonaNet: Service title cannot be empty");
        require(getPersonaReputation(msg.sender) >= minimumReputationForListing, "PersonaNet: Insufficient reputation to list services");

        _serviceIds.increment();
        uint256 newServiceId = _serviceIds.current();

        services[newServiceId] = Service({
            serviceId: newServiceId,
            provider: msg.sender,
            title: title,
            description: description,
            price: price,
            minReputationRequired: minReputationRequired,
            active: true,
            createdAt: block.timestamp
        });

        emit ServiceListed(newServiceId, msg.sender, title, price, minReputationRequired);
        return newServiceId;
    }

    /**
     * @dev Allows a service provider to update the details of their existing service listing.
     * @param serviceId The ID of the service to update.
     * @param title The new title for the service.
     * @param description The new description for the service.
     * @param price The new price for the service.
     */
    function updateService(uint256 serviceId, string memory title, string memory description, uint256 price) public onlyServiceOwner(serviceId) whenNotPaused {
        Service storage service = services[serviceId];
        require(service.active, "PersonaNet: Cannot update an inactive service");
        require(price > 0, "PersonaNet: Service price must be greater than zero");
        require(bytes(title).length > 0, "PersonaNet: Service title cannot be empty");

        service.title = title;
        service.description = description;
        service.price = price;

        emit ServiceUpdated(serviceId, title, price);
    }

    /**
     * @dev Deactivates a service listing, making it unavailable for new tasks.
     * @param serviceId The ID of the service to deactivate.
     */
    function deactivateService(uint256 serviceId) public onlyServiceOwner(serviceId) whenNotPaused {
        Service storage service = services[serviceId];
        require(service.active, "PersonaNet: Service is already inactive");
        service.active = false;
        emit ServiceStatusChanged(serviceId, false);
    }

    /**
     * @dev Reactivates a previously deactivated service listing.
     * @param serviceId The ID of the service to reactivate.
     */
    function reactivateService(uint256 serviceId) public onlyServiceOwner(serviceId) whenNotPaused {
        Service storage service = services[serviceId];
        require(!service.active, "PersonaNet: Service is already active");
        service.active = true;
        emit ServiceStatusChanged(serviceId, true);
    }

    /**
     * @dev Retrieves comprehensive details about a specific service listing.
     * @param serviceId The ID of the service.
     * @return sId The service ID.
     * @return provider The address of the service provider.
     * @return title The title of the service.
     * @return description The description of the service.
     * @return price The price of the service.
     * @return minReputationRequired The minimum reputation required to hire this service.
     * @return active The active status of the service.
     * @return createdAt The timestamp when the service was listed.
     */
    function getServiceDetails(uint256 serviceId) public view returns (
        uint256 sId, address provider, string memory title, string memory description,
        uint256 price, uint256 minReputationRequired, bool active, uint256 createdAt
    ) {
        Service storage service = services[serviceId];
        require(service.serviceId != 0, "PersonaNet: Service not found");
        return (
            service.serviceId,
            service.provider,
            service.title,
            service.description,
            service.price,
            service.minReputationRequired,
            service.active,
            service.createdAt
        );
    }

    // --- IV. Task & Escrow Management ---

    /**
     * @dev Client initiates a task for a specific service and provider, funding an escrow with the service price.
     * Requires the client to hold a Persona SBT and the provider to meet the service's reputation requirements.
     * @param serviceId The ID of the service to be engaged.
     * @param provider The address of the service provider.
     * @param taskDetails Detailed specifications of the task.
     * @return newTaskId The ID of the newly initiated task.
     */
    function initiateTask(uint256 serviceId, address provider, string memory taskDetails) public payable onlyPersonaHolder whenNotPaused nonReentrant returns (uint256) {
        Service storage service = services[serviceId];
        require(service.serviceId != 0, "PersonaNet: Service does not exist");
        require(service.active, "PersonaNet: Service is not active");
        require(service.provider == provider, "PersonaNet: Provider mismatch for service");
        require(msg.sender != provider, "PersonaNet: Cannot initiate task with self");
        require(msg.value == service.price, "PersonaNet: Sent amount does not match service price");
        require(personaExists(provider), "PersonaNet: Provider does not have a Persona SBT");
        require(getPersonaReputation(provider) >= service.minReputationRequired, "PersonaNet: Provider does not meet minimum reputation for this service");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            taskId: newTaskId,
            serviceId: serviceId,
            client: msg.sender,
            provider: provider,
            taskDetails: taskDetails,
            amountEscrowed: msg.value,
            status: TaskStatus.Open,
            createdAt: uint224(block.timestamp), // Cast to uint224
            completedAt: 0,
            clientReviewText: "",
            aiReputationDelta: 0,
            aiAnalysisReceived: false,
            disputeRaised: false,
            disputeRaiser: address(0),
            disputeReason: "",
            disputeEvidenceCID: ""
        });

        emit TaskInitiated(newTaskId, serviceId, msg.sender, provider, msg.value);
        emit TaskStatusChanged(newTaskId, TaskStatus.Open, TaskStatus.Open);
        return newTaskId;
    }

    /**
     * @dev Provider officially accepts an initiated task, moving it to 'Accepted' status.
     * @param taskId The ID of the task to accept.
     */
    function providerAcceptTask(uint256 taskId) public onlyTaskProvider(taskId) whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Open, "PersonaNet: Task not in Open status");
        
        task.status = TaskStatus.Accepted;
        emit TaskStatusChanged(taskId, TaskStatus.Open, TaskStatus.Accepted);
    }

    /**
     * @dev Client marks a task as completed and provides a review.
     * This action also triggers an AI reputation analysis request for the provider.
     * @param taskId The ID of the task to mark completed.
     * @param reviewText The review text provided by the client.
     */
    function clientMarkTaskCompleted(uint256 taskId, string memory reviewText) public onlyTaskClient(taskId) whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Accepted, "PersonaNet: Task not in Accepted status");
        require(bytes(reviewText).length > 0, "PersonaNet: Review text cannot be empty");

        task.status = TaskStatus.ClientCompleted;
        task.completedAt = uint224(block.timestamp); // Cast to uint224
        task.clientReviewText = reviewText;

        // Automatically request AI analysis
        IAIOracle(aiOracleAddress).requestAnalysis(taskId, task.provider, task.client, reviewText);

        emit TaskStatusChanged(taskId, TaskStatus.Accepted, TaskStatus.ClientCompleted);
    }

    /**
     * @dev Provider formally requests payment after the client has marked the task complete.
     * This changes the task status to `ProviderRequestedPayment`.
     * @param taskId The ID of the task for which payment is requested.
     */
    function providerRequestPayment(uint256 taskId) public onlyTaskProvider(taskId) whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.ClientCompleted, "PersonaNet: Task not marked as completed by client");
        
        task.status = TaskStatus.ProviderRequestedPayment;
        emit TaskStatusChanged(taskId, TaskStatus.ClientCompleted, TaskStatus.ProviderRequestedPayment);
    }

    /**
     * @dev Releases the escrowed funds to the provider.
     * This function can be called by the client (implicitly approving the payment)
     * after the provider requested payment, AI analysis is received, and no dispute is active.
     * A platform fee is deducted from the payment.
     * @param taskId The ID of the task for which to release payment.
     */
    function releasePayment(uint256 taskId) public onlyTaskClient(taskId) whenNotPaused nonReentrant {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.ProviderRequestedPayment, "PersonaNet: Task not in ProviderRequestedPayment status");
        require(task.aiAnalysisReceived, "PersonaNet: AI analysis not yet received");
        require(!task.disputeRaised, "PersonaNet: Cannot release payment while dispute is active");

        uint256 platformFee = (task.amountEscrowed * platformFeeBasisPoints) / 10000;
        uint256 payoutAmount = task.amountEscrowed - platformFee;

        accumulatedFees += platformFee; // Accumulate fees for later withdrawal by owner

        task.status = TaskStatus.Completed;
        emit TaskStatusChanged(taskId, TaskStatus.ProviderRequestedPayment, TaskStatus.Completed);
        emit PaymentReleased(taskId, task.provider, payoutAmount);

        (bool success, ) = task.provider.call{value: payoutAmount}("");
        require(success, "PersonaNet: Failed to send payment to provider");
    }

    /**
     * @dev Client cancels a task before the provider accepts it, reclaiming their escrowed funds.
     * @param taskId The ID of the task to cancel.
     */
    function clientCancelTask(uint256 taskId) public onlyTaskClient(taskId) whenNotPaused nonReentrant {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Open, "PersonaNet: Task cannot be cancelled by client at this stage");

        task.status = TaskStatus.ClientCanceled;
        emit TaskStatusChanged(taskId, TaskStatus.Open, TaskStatus.ClientCanceled);
        emit TaskCanceled(taskId, msg.sender, "Client cancelled before provider acceptance");

        (bool success, ) = msg.sender.call{value: task.amountEscrowed}("");
        require(success, "PersonaNet: Failed to refund client");
    }

    /**
     * @dev Provider cancels a task before accepting it, resulting in a full refund to the client.
     * @param taskId The ID of the task to cancel.
     */
    function providerCancelTask(uint256 taskId) public onlyTaskProvider(taskId) whenNotPaused nonReentrant {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Open, "PersonaNet: Task cannot be cancelled by provider at this stage");

        task.status = TaskStatus.ProviderCanceled;
        emit TaskStatusChanged(taskId, TaskStatus.Open, TaskStatus.ProviderCanceled);
        emit TaskCanceled(taskId, msg.sender, "Provider cancelled before acceptance");

        (bool success, ) = task.client.call{value: task.amountEscrowed}("");
        require(success, "PersonaNet: Failed to refund client on provider cancellation");
    }

    // --- V. Dispute Resolution & Penalties ---

    /**
     * @dev Allows either the client or provider to formally raise a dispute over a task.
     * This freezes the task and prevents payment release until resolved.
     * @param taskId The ID of the task for which to raise a dispute.
     * @param reason The reason for raising the dispute.
     */
    function raiseDispute(uint256 taskId, string memory reason) public whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.taskId != 0, "PersonaNet: Task not found");
        require(msg.sender == task.client || msg.sender == task.provider, "PersonaNet: Only client or provider can raise dispute");
        require(!task.disputeRaised, "PersonaNet: Dispute already raised for this task");
        require(
            task.status == TaskStatus.Accepted ||
            task.status == TaskStatus.ClientCompleted ||
            task.status == TaskStatus.ProviderRequestedPayment,
            "PersonaNet: Cannot raise dispute in current task status"
        );
        require(bytes(reason).length > 0, "PersonaNet: Dispute reason cannot be empty");

        task.disputeRaised = true;
        task.disputeRaiser = msg.sender;
        task.disputeReason = reason;
        task.status = TaskStatus.Disputed;

        emit DisputeRaised(taskId, msg.sender, reason);
        emit TaskStatusChanged(taskId, TaskStatus.Accepted, TaskStatus.Disputed); // Assuming Accepted as previous state, could be more granular with previous_status
    }

    /**
     * @dev Allows parties involved in a dispute to submit off-chain evidence.
     * This evidence is typically a Content Identifier (CID) for data stored on IPFS or similar decentralized storage.
     * @param taskId The ID of the disputed task.
     * @param evidenceCID The IPFS CID or similar identifier for the evidence.
     */
    function submitDisputeEvidence(uint256 taskId, string memory evidenceCID) public whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.disputeRaised, "PersonaNet: No active dispute for this task");
        require(msg.sender == task.client || msg.sender == task.provider, "PersonaNet: Only client or provider can submit evidence");
        require(bytes(evidenceCID).length > 0, "PersonaNet: Evidence CID cannot be empty");

        task.disputeEvidenceCID = evidenceCID; // Simplified: only stores the last submitted CID. Could be an array for multiple submissions.
        emit DisputeEvidenceSubmitted(taskId, msg.sender, evidenceCID);
    }

    /**
     * @dev Owner-only function to resolve a dispute.
     * The owner acts as an arbiter, deciding the winner, applying reputation penalties,
     * and distributing the escrowed funds.
     * @param taskId The ID of the task under dispute.
     * @param winner The address of the party determined to be the winner (client or provider).
     * @param reputationPenalty The reputation score change to apply to the loser (usually a negative value).
     * @param payoutToWinner The amount of ETH to send to the winner.
     * @param refundToLoser The amount of ETH to refund to the loser.
     */
    function resolveDispute(
        uint256 taskId,
        address winner,
        int256 reputationPenalty, // Penalty applied to the loser
        uint256 payoutToWinner,
        uint256 refundToLoser
    ) public onlyOwner nonReentrant {
        Task storage task = tasks[taskId];
        require(task.disputeRaised, "PersonaNet: No active dispute to resolve");
        require(task.status == TaskStatus.Disputed, "PersonaNet: Task not in Disputed status");
        require(winner == task.client || winner == task.provider, "PersonaNet: Winner must be client or provider");
        require(payoutToWinner + refundToLoser <= task.amountEscrowed, "PersonaNet: Payouts exceed escrowed amount");

        address loser = (winner == task.client) ? task.provider : task.client;

        // Apply reputation penalty to loser if applicable
        if (personaExists(loser) && reputationPenalty != 0) {
            uint256 loserTokenId = _addressToTokenId[loser];
            int256 oldScore = personas[loserTokenId].reputationScore;
            personas[loserTokenId].reputationScore += reputationPenalty; // Penalty is usually negative
            personas[loserTokenId].lastReputationUpdate = block.timestamp;
            emit ReputationUpdated(loser, loserTokenId, oldScore, personas[loserTokenId].reputationScore, "Dispute resolution penalty");
        }

        // Distribute funds
        if (payoutToWinner > 0) {
            (bool success, ) = winner.call{value: payoutToWinner}("");
            require(success, "PersonaNet: Failed to send payout to winner");
        }
        if (refundToLoser > 0) {
            (bool success, ) = loser.call{value: refundToLoser}("");
            require(success, "PersonaNet: Failed to send refund to loser");
        }

        // Any remaining amount (e.g., if neither party gets full amount) goes to platform fees
        accumulatedFees += task.amountEscrowed - (payoutToWinner + refundToLoser);

        task.status = TaskStatus.DisputeResolved;
        emit DisputeResolved(taskId, winner, loser, reputationPenalty, payoutToWinner, refundToLoser);
        emit TaskStatusChanged(taskId, TaskStatus.Disputed, TaskStatus.DisputeResolved);
    }

    // --- VI. Platform Configuration & Governance ---

    /**
     * @dev Owner-only function to set the platform's transaction fee.
     * Fee is expressed in basis points (e.g., 100 for 1%, 500 for 5%).
     * @param newFeeBasisPoints The new fee percentage in basis points.
     */
    function setPlatformFee(uint256 newFeeBasisPoints) public onlyOwner {
        require(newFeeBasisPoints <= 10000, "PersonaNet: Fee basis points cannot exceed 100%"); // 10000 bps = 100%
        platformFeeBasisPoints = newFeeBasisPoints;
        emit PlatformFeeSet(newFeeBasisPoints);
    }

    /**
     * @dev Owner-only function to withdraw accumulated platform fees to a specified recipient.
     * @param recipient The address to which the fees will be sent.
     */
    function withdrawFees(address recipient) public onlyOwner nonReentrant {
        require(recipient != address(0), "PersonaNet: Recipient address cannot be zero");
        uint256 amount = accumulatedFees;
        require(amount > 0, "PersonaNet: No fees to withdraw");
        accumulatedFees = 0; // Reset accumulated fees before transfer to prevent reentrancy
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "PersonaNet: Failed to withdraw fees");
        emit FeesWithdrawn(recipient, amount);
    }

    /**
     * @dev Owner-only emergency function to pause core functionality of the contract.
     * Prevents new tasks, payments, and other critical actions during emergencies.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Owner-only function to unpause the contract after an emergency.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Owner-only function to adjust the global minimum reputation required for a provider to list services.
     * @param minRep The new minimum reputation score.
     */
    function setMinimumReputationForListing(int252 minRep) public onlyOwner {
        minimumReputationForListing = minRep;
        emit MinimumReputationForListingSet(minRep);
    }

    // `transferOwnership` is inherited from Ownable.sol and not explicitly redefined here.
}

```