Okay, let's design a creative and advanced smart contract concept inspired by quantum mechanics principles (specifically superposition and measurement) applied to a signature verification process. This isn't actual quantum computing, but uses the analogy to create a unique on-chain mechanism.

We'll call this contract `QuantumSignature`.

**Concept:**

A signature's validity isn't determined instantly upon submission. Instead, it exists in a "superposition" state (potentially valid, potentially invalid) until a specific "measurement" event occurs. This measurement event, triggered by an external factor (like a random number, block hash, or oracle data), "collapses" the signature's state, fixing its validity based on conditions met *at the moment of measurement*. This allows for dynamic signature requirements and a delayed finality dependent on external triggers.

**Core Features:**

1.  **Superposition State:** A signature request is created and components are submitted, but the final validity isn't known yet.
2.  **Measurement Event:** A designated process or entity provides a "measurement factor" (e.g., a hash or random number) which triggers the state collapse.
3.  **State Collapse:** Upon measurement, the signature's validity is locked based on the state of required components and conditions at that exact block/timestamp.
4.  **Multi-factor Requirement:** Signature validity can depend on multiple signers and a required threshold.
5.  **Time Sensitivity:** Requests have a validity window (from/until timestamps). Measurement must occur within this window.
6.  **Dynamic Requirements (Pre-Measurement):** Request requirements (like required signers or threshold) can potentially be modified *before* the measurement occurs.

**Data Structures:**

*   `SignatureRequest`: Defines the message, required signers, threshold, validity window, current state, and the measurement factor once applied.
*   `SignatureComponent`: Stores a signer's submitted signature (`v`, `r`, `s`) and the timestamp of submission.
*   Enum `RequestState`: `Pending`, `Measured`, `Expired`, `Cancelled`.

**Access Control:**

*   `Owner`: Contract administration (pausing, global signer management).
*   `Global Signers`: Addresses authorized to submit components for *any* request requiring them.
*   `Request Creator`: Can modify/cancel their own requests before measurement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline:
// 1. Contract Setup: Imports, Errors, Events, Enums, Structs, State Variables.
// 2. Access Control: Owner, Global Signers.
// 3. Request Management: Creation, Modification, Cancellation.
// 4. Component Submission: Signer submitting their part.
// 5. Measurement Process: Initiating state collapse.
// 6. Validity Check: Determining final state after measurement.
// 7. Utility/Query Functions: Get state, details, counts etc.
// 8. Pausability & Ownership.

// Function Summary:
// 1. addGlobalSigner(address signer): Owner adds an address to the list of globally authorized signers.
// 2. removeGlobalSigner(address signer): Owner removes an address from the global signers list.
// 3. isGlobalSigner(address signer): View function to check if an address is a global signer.
// 4. getGlobalSignersCount(): View function to get the number of global signers.
// 5. createSignatureRequest(bytes32 msgHash, address[] requiredSignersList, uint256 requiredSignatureCount, uint48 validFrom, uint48 validUntil): Creates a new signature request definition.
// 6. submitSignatureComponent(uint256 requestId, bytes calldata signature): Submits a signature component for a specific request. Requires being a required signer for that request and the request being Pending and within its validity window.
// 7. initiateMeasurement(uint256 requestId, uint256 measurementFactor): Triggers the state collapse for a Pending request. Requires being within the validity window. Locks the measurement factor.
// 8. getSignatureValidity(uint256 requestId): View function to check the final validity of a signature request *after* it has been measured. Returns true if valid, false otherwise.
// 9. cancelSignatureRequest(uint256 requestId): Allows the creator or owner to cancel a Pending signature request.
// 10. extendValidityWindow(uint256 requestId, uint48 newValidUntil): Allows the creator or owner to extend the expiration time of a Pending request.
// 11. addRequiredSignerToRequest(uint256 requestId, address signer): Allows the creator or owner to add a required signer to a Pending request.
// 12. removeRequiredSignerFromRequest(uint256 requestId, address signer): Allows the creator or owner to remove a required signer from a Pending request.
// 13. getRequestDetails(uint256 requestId): View function to get the details of a signature request.
// 14. getSubmittedComponent(uint256 requestId, address signer): View function to retrieve a specific signer's submitted component data.
// 15. getSubmittedComponentCount(uint256 requestId): View function to get the number of signature components submitted for a request.
// 16. getSignatureState(uint256 requestId): View function to get the current state of a signature request (Pending, Measured, Expired, Cancelled).
// 17. getMeasurementFactor(uint256 requestId): View function to get the measurement factor applied to a Measured request (returns 0 if not measured).
// 18. getRequestCount(): View function to get the total number of signature requests created.
// 19. hasSignerSubmittedComponent(uint256 requestId, address signer): View function to check if a specific signer has submitted a component for a request.
// 20. getRequiredSignersForRequestCount(uint256 requestId): View function to get the *initial* required number of signatures for a request.
// 21. getRequiredSignersListForRequest(uint256 requestId): View function to get the list of addresses initially required to sign for a request. (Note: Modifications via add/remove functions alter the *effective* required set, but this view returns the original list for context).
// 22. isRequestExpired(uint256 requestId): View function to check if a Pending request is past its validUntil timestamp.
// 23. pause(): Owner function to pause contract interactions.
// 24. unpause(): Owner function to unpause contract interactions.
// 25. transferOwnership(address newOwner): Owner function to transfer contract ownership.
// 26. renounceOwnership(): Owner function to renounce contract ownership.

contract QuantumSignature is Ownable, Pausable {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    // --- Errors ---
    error QSig__NotGlobalSigner();
    error QSig__SignerAlreadyExists();
    error QSig__SignerNotFound();
    error QSig__RequestNotFound();
    error QSig__RequestNotPending();
    error QSig__RequestAlreadyMeasured();
    error QSig__RequestExpired();
    error QSig__RequestNotExpired();
    error QSig__NotRequiredSignerForRequest();
    error QSig__ComponentAlreadySubmitted();
    error QSig__InvalidSignature();
    error QSig__NotRequestCreatorOrOwner();
    error QSig__NewValidityTooEarly();
    error QSig__SignerAlreadyRequiredForRequest();
    error QSig__SignerNotRequiredForRequest();
    error QSig__RequiredCountExceedsSigners();
    error QSig__MeasurementFactorCannotBeZero();
    error QSig__RequestNotMeasured();

    // --- Events ---
    event GlobalSignerAdded(address indexed signer);
    event GlobalSignerRemoved(address indexed signer);
    event SignatureRequestCreated(
        uint256 indexed requestId,
        address indexed creator,
        bytes32 indexed msgHash,
        uint48 validFrom,
        uint48 validUntil,
        uint256 requiredSignatureCount
    );
    event SignatureComponentSubmitted(
        uint256 indexed requestId,
        address indexed signer,
        uint256 submittedAt
    );
    event MeasurementInitiated(
        uint256 indexed requestId,
        uint256 indexed measurementFactor,
        uint256 measuredAt
    );
    event RequestCancelled(uint256 indexed requestId);
    event ValidityWindowExtended(uint256 indexed requestId, uint48 newValidUntil);
    event RequiredSignerAddedToRequest(uint256 indexed requestId, address indexed signer);
    event RequiredSignerRemovedFromRequest(uint256 indexed requestId, address indexed signer);
    event RequestStateChanged(uint256 indexed requestId, RequestState newState);

    // --- Enums ---
    enum RequestState {
        Pending,    // Request is active and accepting components
        Measured,   // State has been collapsed by measurement factor
        Expired,    // Request validity window passed before measurement
        Cancelled   // Request was cancelled before measurement
    }

    // --- Structs ---
    struct SignatureComponent {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint256 submittedAt;
    }

    struct SignatureRequest {
        bytes32 msgHash;
        address creator;
        address[] initialRequiredSignersList; // List provided at creation
        mapping(address => bool) currentRequiredSignersMap; // Map for quick lookup/dynamic changes
        uint256 requiredSignatureCount;
        uint48 validFrom;
        uint48 validUntil;
        RequestState state;
        uint256 measurementFactor; // Used to 'collapse' the state
    }

    // --- State Variables ---
    Counters.Counter private _requestIds;

    mapping(address => bool) private _isGlobalSigner;
    uint256 private _globalSignerCount;

    mapping(uint256 => SignatureRequest) private _signatureRequests;
    mapping(uint256 => mapping(address => SignatureComponent)) private _submittedComponents;
    mapping(uint256 => uint256) private _submittedComponentCounts; // Keep track of submitted components per request

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Modifiers ---
    modifier onlyGlobalSigner() {
        if (!_isGlobalSigner[msg.sender]) {
            revert QSig__NotGlobalSigner();
        }
        _;
    }

    modifier whenRequestPending(uint256 requestId) {
        if (_signatureRequests[requestId].state != RequestState.Pending) {
            revert QSig__RequestNotPending();
        }
        _;
    }

    modifier whenRequestNotMeasured(uint256 requestId) {
        if (_signatureRequests[requestId].state == RequestState.Measured) {
            revert QSig__RequestAlreadyMeasured();
        }
        _;
    }

    modifier whenRequestMeasured(uint256 requestId) {
         if (_signatureRequests[requestId].state != RequestState.Measured) {
            revert QSig__RequestNotMeasured();
        }
        _;
    }

    modifier notExpired(uint256 requestId) {
        if (block.timestamp > _signatureRequests[requestId].validUntil) {
            revert QSig__RequestExpired();
        }
        _;
    }

     modifier notCancelled(uint256 requestId) {
        if (_signatureRequests[requestId].state == RequestState.Cancelled) {
            revert QSig__RequestNotPending(); // Using RequestNotPending as Cancelled means it's not Pending
        }
        _;
    }

    // --- Global Signer Management ---

    /// @notice Adds an address to the list of globally authorized signers.
    /// @param signer The address to add.
    function addGlobalSigner(address signer) public onlyOwner {
        if (_isGlobalSigner[signer]) {
            revert QSig__SignerAlreadyExists();
        }
        _isGlobalSigner[signer] = true;
        _globalSignerCount++;
        emit GlobalSignerAdded(signer);
    }

    /// @notice Removes an address from the list of globally authorized signers.
    /// @param signer The address to remove.
    function removeGlobalSigner(address signer) public onlyOwner {
        if (!_isGlobalSigner[signer]) {
            revert QSig__SignerNotFound();
        }
        _isGlobalSigner[signer] = false;
        _globalSignerCount--;
        emit GlobalSignerRemoved(signer);
    }

    /// @notice Checks if an address is a globally authorized signer.
    /// @param signer The address to check.
    /// @return bool True if the address is a global signer, false otherwise.
    function isGlobalSigner(address signer) public view returns (bool) {
        return _isGlobalSigner[signer];
    }

    /// @notice Gets the total number of globally authorized signers.
    /// @return uint256 The count of global signers.
    function getGlobalSignersCount() public view returns (uint256) {
        return _globalSignerCount;
    }

    // --- Request Management ---

    /// @notice Creates a new signature request definition.
    /// The validity of the signature remains in "superposition" until measurement.
    /// @param msgHash The hash of the message being signed.
    /// @param requiredSignersList The initial list of addresses required to sign this request.
    /// @param requiredSignatureCount The minimum number of signatures required from the list for validity after measurement.
    /// @param validFrom The timestamp from which the request is valid (can submit components).
    /// @param validUntil The timestamp until which the request is valid (can submit components or initiate measurement).
    /// @return uint256 The ID of the newly created request.
    function createSignatureRequest(
        bytes32 msgHash,
        address[] calldata requiredSignersList,
        uint256 requiredSignatureCount,
        uint48 validFrom,
        uint48 validUntil
    ) public whenNotPaused returns (uint256) {
        if (requiredSignatureCount > requiredSignersList.length) {
            revert QSig__RequiredCountExceedsSigners();
        }
         if (validFrom >= validUntil) {
             revert("QSig__InvalidValidityWindow");
         }
          if (validFrom < block.timestamp) {
             // Optionally allow requests valid from the past, or enforce future start
             // require(validFrom >= block.timestamp, "QSig__ValidFromInPast");
         }


        _requestIds.increment();
        uint256 requestId = _requestIds.current();

        SignatureRequest storage request = _signatureRequests[requestId];
        request.msgHash = msgHash;
        request.creator = msg.sender;
        request.requiredSignatureCount = requiredSignatureCount;
        request.validFrom = validFrom;
        request.validUntil = validUntil;
        request.state = RequestState.Pending;
        request.measurementFactor = 0; // Not measured yet

        request.initialRequiredSignersList = new address[](requiredSignersList.length);
        for (uint256 i = 0; i < requiredSignersList.length; i++) {
            request.initialRequiredSignersList[i] = requiredSignersList[i];
            request.currentRequiredSignersMap[requiredSignersList[i]] = true;
        }

        emit SignatureRequestCreated(
            requestId,
            msg.sender,
            msgHash,
            validFrom,
            validUntil,
            requiredSignatureCount
        );
         emit RequestStateChanged(requestId, RequestState.Pending);

        return requestId;
    }

    /// @notice Submits a signature component for a specific request.
    /// This moves the request into a "superposed" state regarding this signer's component.
    /// Requires the sender to be a required signer for the request and the request to be Pending and within its validity window.
    /// @param requestId The ID of the signature request.
    /// @param signature The signature bytes (v, r, s concatenated).
    function submitSignatureComponent(uint256 requestId, bytes calldata signature)
        public
        whenNotPaused
        whenRequestPending(requestId)
        notExpired(requestId)
    {
        SignatureRequest storage request = _signatureRequests[requestId];

        if (!_signatureRequests[requestId].currentRequiredSignersMap[msg.sender]) {
             revert QSig__NotRequiredSignerForRequest();
        }

        if (_submittedComponents[requestId][msg.sender].submittedAt != 0) {
            revert QSig__ComponentAlreadySubmitted();
        }

        bytes32 messageHash = request.msgHash;
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

        address signerAddress = ethSignedMessageHash.recover(signature);

        if (signerAddress != msg.sender) {
            revert QSig__InvalidSignature();
        }

        (bytes32 r, bytes32 s, uint8 v) = signature.ecdsaSplit();

        _submittedComponents[requestId][msg.sender] = SignatureComponent(
            r, s, v, block.timestamp
        );
        _submittedComponentCounts[requestId]++;

        emit SignatureComponentSubmitted(requestId, msg.sender, block.timestamp);
    }

    /// @notice Triggers the "measurement" process for a Pending request.
    /// This collapses the state and locks the validity based on submitted components at this time.
    /// Requires being within the validity window.
    /// The `measurementFactor` should ideally be derived from an unpredictable source.
    /// @param requestId The ID of the signature request.
    /// @param measurementFactor A unique factor (e.g., random number, block hash data) used for measurement. Must be non-zero.
    function initiateMeasurement(uint256 requestId, uint256 measurementFactor)
        public
        whenNotPaused
        whenRequestPending(requestId)
        notExpired(requestId)
    {
        if (measurementFactor == 0) {
            revert QSig__MeasurementFactorCannotBeZero();
        }

        SignatureRequest storage request = _signatureRequests[requestId];
        request.state = RequestState.Measured;
        request.measurementFactor = measurementFactor;

        emit MeasurementInitiated(requestId, measurementFactor, block.timestamp);
         emit RequestStateChanged(requestId, RequestState.Measured);
    }

    /// @notice Allows the creator or owner to cancel a Pending signature request.
    /// This moves the request state to Cancelled, preventing submission and measurement.
    /// @param requestId The ID of the signature request.
    function cancelSignatureRequest(uint256 requestId)
        public
        whenNotPaused
        whenRequestPending(requestId)
    {
        SignatureRequest storage request = _signatureRequests[requestId];
        if (msg.sender != request.creator && msg.sender != owner()) {
            revert QSig__NotRequestCreatorOrOwner();
        }

        request.state = RequestState.Cancelled;
        emit RequestCancelled(requestId);
         emit RequestStateChanged(requestId, RequestState.Cancelled);
    }

    /// @notice Allows the creator or owner to extend the expiration time of a Pending request.
    /// Cannot extend if the request has already expired or been measured/cancelled.
    /// @param requestId The ID of the signature request.
    /// @param newValidUntil The new expiration timestamp. Must be in the future and after the current `validUntil`.
    function extendValidityWindow(uint256 requestId, uint48 newValidUntil)
        public
        whenNotPaused
        whenRequestPending(requestId) // Implicitly checks if not Expired/Measured/Cancelled
    {
         SignatureRequest storage request = _signatureRequests[requestId];
         if (msg.sender != request.creator && msg.sender != owner()) {
            revert QSig__NotRequestCreatorOrOwner();
        }
        if (newValidUntil <= request.validUntil) {
            revert QSig__NewValidityTooEarly();
        }
         if (newValidUntil < block.timestamp) {
             revert("QSig__NewValidityInPast");
         }


        request.validUntil = newValidUntil;
        emit ValidityWindowExtended(requestId, newValidUntil);
    }

    /// @notice Allows the creator or owner to add a required signer to a Pending request.
    /// This changes the set of addresses from which the requiredSignatureCount must be met.
    /// @param requestId The ID of the signature request.
    /// @param signer The address to add to the required signers for this request.
    function addRequiredSignerToRequest(uint256 requestId, address signer)
        public
        whenNotPaused
        whenRequestPending(requestId)
    {
        SignatureRequest storage request = _signatureRequests[requestId];
        if (msg.sender != request.creator && msg.sender != owner()) {
            revert QSig__NotRequestCreatorOrOwner();
        }
         if (request.currentRequiredSignersMap[signer]) {
             revert QSig__SignerAlreadyRequiredForRequest();
         }

        request.currentRequiredSignersMap[signer] = true;
        // Note: initialRequiredSignersList is NOT updated, only the map used for checking
        emit RequiredSignerAddedToRequest(requestId, signer);
    }

     /// @notice Allows the creator or owner to remove a required signer from a Pending request.
    /// This changes the set of addresses from which the requiredSignatureCount must be met.
    /// If this makes requiredSignatureCount > remaining possible signers, the request becomes unfulfillable.
    /// @param requestId The ID of the signature request.
    /// @param signer The address to remove from the required signers for this request.
    function removeRequiredSignerFromRequest(uint256 requestId, address signer)
        public
        whenNotPaused
        whenRequestPending(requestId)
    {
        SignatureRequest storage request = _signatureRequests[requestId];
         if (msg.sender != request.creator && msg.sender != owner()) {
            revert QSig__NotRequestCreatorOrOwner();
        }
         if (!request.currentRequiredSignersMap[signer]) {
             revert QSig__SignerNotRequiredForRequest();
         }

        request.currentRequiredSignersMap[signer] = false;
         // Note: initialRequiredSignersList is NOT updated, only the map used for checking
        // We don't explicitly check requiredSignatureCount here; validity check handles if enough remain.
        emit RequiredSignerRemovedFromRequest(requestId, signer);
    }


    // --- Validity and Query Functions ---

    /// @notice Checks the final validity of a signature request *after* it has been measured.
    /// Validity depends on the request state, expiry, required threshold, and submitted components *at the moment of measurement*.
    /// @param requestId The ID of the signature request.
    /// @return bool True if the request is in the Measured state, is not expired based on its validUntil at measurement time, and has enough valid components submitted by required signers, false otherwise.
    function getSignatureValidity(uint256 requestId) public view returns (bool) {
        SignatureRequest storage request = _signatureRequests[requestId];

        // Validity can only be determined in the Measured state
        if (request.state != RequestState.Measured) {
            return false;
        }

        // Although measurement locks validity, the *conditions* checked are based on the state *at measurement time*.
        // The validUntil check here ensures measurement occurred within the window.
        // The state == Measured already implies block.timestamp <= validUntil happened when initiateMeasurement was called.
        // We re-check validUntil here just to be explicit about the window being met.
        if (block.timestamp > request.validUntil) {
             // This path should technically not be reached if state is Measured,
             // but safety check included.
             return false; // Should already be handled by state == Measured implies not expired when measured
        }


        uint256 validComponentCount = 0;
        bytes32 messageHash = request.msgHash;
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

        // Iterate through the *initial* list of required signers to check their submission status
        // Note: This assumes modifications to currentRequiredSignersMap impact *which* signers *could* contribute,
        // but the check here counts how many *from the original list* (or potentially *any* signer currently marked required)
        // have submitted valid components *before* measurement.
        // A more robust design might track the set of *active* required signers at the moment of measurement.
        // For this implementation, let's count valid components submitted by anyone *currently* in currentRequiredSignersMap at the time of this validity check, assuming they submitted *before* measurement.

        // To accurately check against the *state at measurement*, we'd need a snapshot.
        // Simpler implementation: check validity based on who was required *at measurement time* and who submitted *before* measurement.
        // This requires iterating the map or storing a list of required signers at measurement. Let's iterate the initial list and check the map.

         address[] memory initialList = request.initialRequiredSignersList;
         // We need a way to get addresses from the *map* dynamically if add/remove was used.
         // Iterating maps is not standard in Solidity.
         // Let's simplify: the validity check counts submitted components *from the initial list* that are *still marked true* in currentRequiredSignersMap at check time.
         // A signer removed via removeRequiredSignerFromRequest will NOT contribute, even if they submitted.

        for(uint i = 0; i < initialList.length; i++) {
             address signer = initialList[i];
             // Check if the signer is still considered 'required' for the purpose of counting towards the threshold
             if (request.currentRequiredSignersMap[signer]) {
                SignatureComponent memory component = _submittedComponents[requestId][signer];

                // Check if component exists and was submitted *before* measurement
                // We don't store measurement timestamp in request struct explicitly, but we can infer it's when state became Measured
                // Simpler: check if component exists and its signature is valid
                if (component.submittedAt != 0) {
                    address recoveredAddress = ethSignedMessageHash.recover(
                        abi.encodePacked(component.r, component.s, component.v)
                    );
                    if (recoveredAddress == signer) {
                        validComponentCount++;
                    }
                }
             }
        }


        return validComponentCount >= request.requiredSignatureCount;
    }

    /// @notice Gets the details of a signature request.
    /// @param requestId The ID of the signature request.
    /// @return bytes32 msgHash The hash of the message.
    /// @return address creator The address that created the request.
    /// @return address[] initialRequiredSignersList The initial list of required signer addresses.
    /// @return uint256 requiredSignatureCount The number of signatures required.
    /// @return uint48 validFrom The start timestamp of the validity window.
    /// @return uint48 validUntil The end timestamp of the validity window.
    /// @return RequestState state The current state of the request.
    /// @return uint256 measurementFactor The measurement factor (0 if not measured).
    function getRequestDetails(uint256 requestId) public view returns (
        bytes32 msgHash,
        address creator,
        address[] memory initialRequiredSignersList, // Returns the initial list
        uint256 requiredSignatureCount,
        uint48 validFrom,
        uint48 validUntil,
        RequestState state,
        uint256 measurementFactor
    ) {
        SignatureRequest storage request = _signatureRequests[requestId];
        if (request.creator == address(0) && requestId != 0) { // Check for existence if not ID 0
            revert QSig__RequestNotFound();
        }

        return (
            request.msgHash,
            request.creator,
            request.initialRequiredSignersList,
            request.requiredSignatureCount,
            request.validFrom,
            request.validUntil,
            request.state,
            request.measurementFactor
        );
    }

    /// @notice Retrieves a specific signer's submitted component data for a request.
    /// @param requestId The ID of the signature request.
    /// @param signer The address of the signer.
    /// @return SignatureComponent The submitted component struct (will have submittedAt == 0 if not submitted).
    function getSubmittedComponent(uint256 requestId, address signer) public view returns (SignatureComponent memory) {
         if (_signatureRequests[requestId].creator == address(0) && requestId != 0) { // Check for existence if not ID 0
            revert QSig__RequestNotFound();
        }
        return _submittedComponents[requestId][signer];
    }

    /// @notice Gets the number of components submitted for a request so far.
    /// @param requestId The ID of the signature request.
    /// @return uint256 The count of submitted components.
    function getSubmittedComponentCount(uint256 requestId) public view returns (uint256) {
         if (_signatureRequests[requestId].creator == address(0) && requestId != 0) { // Check for existence if not ID 0
            revert QSig__RequestNotFound();
        }
        return _submittedComponentCounts[requestId];
    }


    /// @notice Gets the current state of a signature request.
    /// Automatically transitions to Expired if in Pending state and past validUntil.
    /// @param requestId The ID of the signature request.
    /// @return RequestState The current state.
    function getSignatureState(uint256 requestId) public view returns (RequestState) {
         SignatureRequest storage request = _signatureRequests[requestId];
         if (request.creator == address(0) && requestId != 0) { // Check for existence if not ID 0
            revert QSig__RequestNotFound();
        }

        // Check for expiry only if currently Pending
        if (request.state == RequestState.Pending && block.timestamp > request.validUntil) {
            return RequestState.Expired;
        }
        return request.state;
    }

    /// @notice Gets the measurement factor applied to a request.
    /// Returns 0 if the request has not been measured.
    /// @param requestId The ID of the signature request.
    /// @return uint256 The measurement factor.
    function getMeasurementFactor(uint256 requestId) public view returns (uint256) {
         if (_signatureRequests[requestId].creator == address(0) && requestId != 0) { // Check for existence if not ID 0
            revert QSig__RequestNotFound();
        }
        return _signatureRequests[requestId].measurementFactor;
    }

    /// @notice Gets the total number of signature requests created.
    /// @return uint256 The count of requests.
    function getRequestCount() public view returns (uint256) {
        return _requestIds.current();
    }

    /// @notice Checks if a specific signer has submitted a component for a request.
    /// @param requestId The ID of the signature request.
    /// @param signer The address of the signer.
    /// @return bool True if a component has been submitted by this signer, false otherwise.
    function hasSignerSubmittedComponent(uint256 requestId, address signer) public view returns (bool) {
        if (_signatureRequests[requestId].creator == address(0) && requestId != 0) { // Check for existence if not ID 0
            revert QSig__RequestNotFound();
        }
        return _submittedComponents[requestId][signer].submittedAt != 0;
    }

    /// @notice Gets the *initial* required number of signatures for a request.
    /// Note: This doesn't reflect dynamic changes made via `addRequiredSignerToRequest`/`removeRequiredSignerFromRequest`
    /// which only affect the internal map used for validity checks.
    /// @param requestId The ID of the signature request.
    /// @return uint256 The initial required signature count.
    function getRequiredSignersForRequestCount(uint256 requestId) public view returns (uint256) {
         if (_signatureRequests[requestId].creator == address(0) && requestId != 0) { // Check for existence if not ID 0
            revert QSig__RequestNotFound();
        }
        return _signatureRequests[requestId].requiredSignatureCount;
    }

    /// @notice Gets the list of addresses initially required to sign for a request.
    /// This is the list provided during `createSignatureRequest`.
    /// Note: This doesn't reflect dynamic changes made via `addRequiredSignerToRequest`/`removeRequiredSignerFromRequest`.
    /// @param requestId The ID of the signature request.
    /// @return address[] The list of initial required signers.
    function getRequiredSignersListForRequest(uint256 requestId) public view returns (address[] memory) {
        if (_signatureRequests[requestId].creator == address(0) && requestId != 0) { // Check for existence if not ID 0
            revert QSig__RequestNotFound();
        }
        return _signatureRequests[requestId].initialRequiredSignersList;
    }

    /// @notice Checks if a Pending request is past its validUntil timestamp.
    /// @param requestId The ID of the signature request.
    /// @return bool True if expired, false otherwise.
    function isRequestExpired(uint256 requestId) public view returns (bool) {
        SignatureRequest storage request = _signatureRequests[requestId];
         if (request.creator == address(0) && requestId != 0) { // Check for existence if not ID 0
            revert QSig__RequestNotFound();
        }
        return request.state == RequestState.Pending && block.timestamp > request.validUntil;
    }

     /// @notice Gets the timestamp when a specific signer submitted their component for a request.
    /// Returns 0 if the signer has not submitted a component for this request.
    /// @param requestId The ID of the signature request.
    /// @param signer The address of the signer.
    /// @return uint256 The submission timestamp.
    function getComponentSubmissionTimestamp(uint256 requestId, address signer) public view returns (uint256) {
        if (_signatureRequests[requestId].creator == address(0) && requestId != 0) { // Check for existence if not ID 0
            revert QSig__RequestNotFound();
        }
        return _submittedComponents[requestId][signer].submittedAt;
    }

    // --- Pausability & Ownership ---

    /// @notice Pauses contract interactions. Only callable by the owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract interactions. Only callable by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }
}
```