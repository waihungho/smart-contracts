Okay, here is a Solidity smart contract incorporating advanced concepts like simulated cross-chain state mediation, dynamic asset properties based on external proofs, conditional rights, and complex access control.

This contract, `MultiChainAssetMediator`, does *not* implement a full cross-chain bridge or ZK verification on-chain (as that's often done off-chain or with specialized protocols) but provides the *framework and logic* on one chain to manage assets whose state and rights are influenced and verified by events/proofs from other chains.

**Disclaimer:** This is a complex, conceptual contract for educational and creative purposes. A production-ready version would require robust external infrastructure (proof verifiers, cross-chain messengers) and significant security audits.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // Useful for dynamic metadata

// --- Outline ---
// 1. Contract Description: Manages unique tokens (like NFTs) representing assets or states that exist or are verified across multiple blockchain networks.
// 2. Core Concept: Tokens held within this contract have properties and associated rights that can change based on verified proofs or messages received from other chains.
// 3. Key Features:
//    - ERC721 compatibility (Enumerable for iteration).
//    - Stores references to associated assets/states on external chains.
//    - Functions to receive and process simulated cross-chain proofs/messages.
//    - Dynamic 'mediated state' per token, updated based on proofs.
//    - Conditional rights that unlock upon meeting cross-chain conditions.
//    - Conditional ownership transfers.
//    - Role-based access control (Owner, Mediators).
//    - Dynamic fee calculation based on token state.
//    - Registration of local dependent contracts.
//    - Attestation mechanism for external state verification.
// 4. External Dependencies (Simulated): Assumes interaction with a Cross-Chain Messenger and a Proof Verification system (represented by addresses).

// --- Function Summary ---
// ERC721/Enumerable Standard Functions (Inherited and Overridden):
// constructor(string name, string symbol) - Initializes contract with name, symbol, and sets owner.
// supportsInterface(bytes4 interfaceId) - Returns true if the contract implements the requested interface.
// balanceOf(address owner) - Returns the number of tokens owned by `owner`.
// ownerOf(uint256 tokenId) - Returns the owner of the `tokenId`.
// safeTransferFrom(address from, address to, uint256 tokenId) - Transfers token safely.
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) - Transfers token safely with data.
// transferFrom(address from, address to, uint256 tokenId) - Transfers token (less safely).
// approve(address to, uint256 tokenId) - Approves address to spend token.
// getApproved(uint256 tokenId) - Gets approved address for token.
// setApprovalForAll(address operator, bool approved) - Approves/disapproves operator for all tokens.
// isApprovedForAll(address owner, address operator) - Checks if operator is approved for all tokens of owner.
// totalSupply() - Returns total supply of tokens.
// tokenByIndex(uint256 index) - Returns token ID at index (Enumerable).
// tokenOfOwnerByIndex(address owner, uint256 index) - Returns token ID of owner at index (Enumerable).
// tokenURI(uint256 tokenId) - Returns a URI for a given token ID, potentially dynamic based on mediated state.

// Custom Functions:
// mintMediatedAsset(address to, bytes memory initialMediatedState, bytes memory initialCrossChainRef) - Mints a new token with initial state and reference. (Mediator or Owner)
// burnMediatedAsset(uint256 tokenId) - Burns a token. (Owner or Approved/Mediator)
// setCrossChainReference(uint256 tokenId, uint256 targetChainId, bytes memory referenceData) - Sets/updates the reference data for a token on a specific chain. (Mediator)
// getCrossChainReference(uint256 tokenId, uint256 targetChainId) - Retrieves the cross-chain reference for a token on a specific chain. (View)
// receiveAndProcessCrossChainProof(uint256 tokenId, uint256 sourceChainId, bytes memory proofData) - Endpoint for Cross-Chain Messenger to submit a proof. Triggers state updates based on proof validity. (Only Cross-Chain Messenger)
// updateMediatedState(uint256 tokenId, bytes memory newStateData) - Directly updates the mediated state of a token. Requires Mediator role. Intended for updates *derived* from processed proofs. (Mediator)
// getMediatedState(uint256 tokenId) - Retrieves the current dynamic mediated state data for a token. (View)
// registerConditionalRight(uint256 tokenId, bytes32 rightId, bytes memory requiredConditionData, bytes memory rightDetails) - Registers a potential future right associated with a token, contingent on a condition being met (verifiable via proof). (Owner of token)
// claimConditionalRight(uint256 tokenId, bytes32 rightId, bytes memory proofOfConditionMet) - Allows claiming a registered right by providing proof that the required condition has been met. Triggers right fulfillment logic. (Owner or Approved)
// revokeConditionalRight(uint256 tokenId, bytes32 rightId, string memory reason) - Revokes a previously registered conditional right before it's claimed. (Owner of token)
// getConditionalRight(uint256 tokenId, bytes32 rightId) - Retrieves details of a specific conditional right. (View)
// addMediatorRole(address account) - Grants Mediator role. (Owner)
// removeMediatorRole(address account) - Revokes Mediator role. (Owner)
// hasMediatorRole(address account) - Checks if an address has the Mediator role. (View)
// setProofVerificationContract(address verifierAddress) - Sets the address of the external Proof Verification contract. (Owner)
// setCrossChainMessenger(address messengerAddress) - Sets the address of the external Cross-Chain Messenger contract. (Owner)
// initiateCrossChainTransferRequest(uint256 tokenId, uint256 targetChainId, address recipientOnTarget) - Records intent to transfer the token's representation to another chain. Requires off-chain/cross-chain process. (Owner or Approved)
// finalizeCrossChainTransferIn(uint256 tokenId, uint256 sourceChainId, bytes memory sourceAssetIdentifier, address recipient) - Endpoint called by Messenger to finalize a token transfer *into* this contract from another chain. (Only Cross-Chain Messenger)
// attestToStateOnOtherChain(uint256 tokenId, uint256 chainId, bytes32 stateHash, bytes memory attestationProof) - Allows a trusted entity (or owner with proof) to assert a state snapshot on another chain without the contract directly verifying it via the verifier contract. (Mediator or specific role)
// registerDependentContract(uint256 tokenId, address dependentContractAddress, bytes32 requiredStateHash) - Registers a local contract that needs to be potentially notified or relies on the state of this token. (Owner or Mediator)
// notifyDependentContracts(uint256 tokenId) - Emits an event signaling that the token's mediated state has been updated, for registered dependent contracts to listen to. (Mediator or triggered by state update)
// calculateDynamicFee(uint256 tokenId, bytes32 actionType) - Calculates a fee for a specific action based on the token's current mediated state or other properties. (Pure/View, internal helper potential)
// setTokenDescription(uint256 tokenId, string memory descriptionURI) - Sets a specific description URI for a token, overriding the base URI logic. (Owner)
// getTokenDescription(uint256 tokenId) - Gets the specific description URI for a token. (View)
// transferOwnershipWithConditions(uint256 tokenId, address newOwner, bytes memory requiredConditionProof) - Initiates a pending ownership transfer that only becomes effective if a specific condition is met and proven. (Current Owner)
// claimConditionalTransfer(uint256 tokenId, bytes memory proofOfConditionMet) - Finalizes a pending conditional ownership transfer by providing proof the condition is met. (The `newOwner` address defined in the request)
// getPendingTransferRequest(uint256 tokenId) - Retrieves details of a pending conditional ownership transfer request. (View)

contract MultiChainAssetMediator is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Represents the dynamic state of the token, potentially derived from cross-chain inputs.
    // Mapping: tokenId -> mediatedStateData
    mapping(uint256 tokenId => bytes mediatedState) private _mediatedStates;

    // Stores references to equivalent or related assets/states on other chains.
    // Mapping: tokenId -> chainId -> referenceData
    mapping(uint256 tokenId => mapping(uint256 chainId => bytes referenceData)) private _crossChainReferences;

    // Role-based access control for operations requiring trust (processing proofs, state updates).
    mapping(address account => bool isMediator) private _mediators;

    // Address of the contract responsible for verifying cryptographic proofs from other chains.
    address public proofVerificationContract;

    // Address of the cross-chain messaging protocol's relayer/gateway contract allowed to submit proofs.
    address public crossChainMessenger;

    // Structure for storing conditional rights associated with a token.
    struct ConditionalRight {
        bytes requiredConditionData; // Data describing the condition (e.g., hash of target state, event signature + params)
        bytes rightDetails;          // Data describing the right granted (e.g., amount unlockable, privilege granted)
        address claimant;            // Address allowed to claim the right (usually token owner, but could be specific)
        bool claimed;                // True if the right has been claimed
    }
    // Mapping: tokenId -> rightId -> ConditionalRight
    mapping(uint256 tokenId => mapping(bytes32 rightId => ConditionalRight)) private _conditionalRights;

    // Structure for pending conditional ownership transfers.
    struct ConditionalTransfer {
        address newOwner;                 // The recipient address
        bytes requiredConditionProofData; // Data describing the condition proof needed
        uint64 requestTimestamp;          // Timestamp of the request
        bool finalized;                   // True if the transfer has been finalized
    }
    // Mapping: tokenId -> ConditionalTransfer
    mapping(uint256 tokenId => ConditionalTransfer) private _pendingTransfers;

    // Store custom description URIs per token, overrides base URI if set.
    mapping(uint256 tokenId => string descriptionURI) private _tokenDescriptionURIs;

    // Registered local contracts that depend on this token's state.
    // Mapping: tokenId -> dependentContractAddress -> requiredStateHash (optional check)
    mapping(uint256 tokenId => mapping(address dependentContract => bytes32 requiredStateHash)) private _dependentContracts;

    // --- Events ---

    event MediatedAssetMinted(uint256 indexed tokenId, address indexed owner, bytes initialMediatedState);
    event MediatedAssetBurned(uint256 indexed tokenId, address indexed burner);
    event CrossChainReferenceUpdated(uint256 indexed tokenId, uint256 indexed chainId, bytes referenceData);
    event CrossChainProofReceived(uint256 indexed tokenId, uint256 indexed sourceChainId, bytes proofData);
    event MediatedStateUpdated(uint256 indexed tokenId, bytes newStateData); // Indicates state changed, dependent contracts should check
    event ConditionalRightRegistered(uint256 indexed tokenId, bytes32 indexed rightId, address indexed claimant);
    event ConditionalRightClaimed(uint256 indexed tokenId, bytes32 indexed rightId, address indexed claimant);
    event MediatorRoleGranted(address indexed account);
    event MediatorRoleRevoked(address indexed account);
    event ProofVerificationContractSet(address indexed verifierAddress);
    event CrossChainMessengerSet(address indexed messengerAddress);
    event CrossChainTransferRequestInitiated(uint256 indexed tokenId, uint256 indexed targetChainId, address recipientOnTarget);
    event CrossChainTransferFinalizedIn(uint256 indexed tokenId, uint256 indexed sourceChainId, address indexed recipient);
    event AttestationToStateRecorded(uint256 indexed tokenId, uint256 indexed chainId, bytes32 stateHash, address indexed attestor);
    event DependentContractRegistered(uint256 indexed tokenId, address indexed dependentContract, bytes32 requiredStateHash);
    event TokenDescriptionSet(uint256 indexed tokenId, string descriptionURI);
    event ConditionalTransferRequested(uint256 indexed tokenId, address indexed newOwner, uint64 requestTimestamp);
    event ConditionalTransferClaimed(uint256 indexed tokenId, address indexed finalOwner);

    // --- Errors ---

    error MultiChainAssetMediator__NotMediator();
    error MultiChainAssetMediator__ProofVerificationContractNotSet();
    error MultiChainAssetMediator__CrossChainMessengerNotSet();
    error MultiChainAssetMediator__InvalidProof(); // Simulated error for proof verification
    error MultiChainAssetMediator__TokenDoesNotExist();
    error MultiChainAssetMediator__UnauthorizedMediatedStateUpdate();
    error MultiChainAssetMediator__RightAlreadyClaimed();
    error MultiChainAssetMediator__RightDoesNotExist();
    error MultiChainAssetMediator__NotRightClaimant();
    error MultiChainAssetMediator__ConditionalTransferAlreadyFinalized();
    error MultiChainAssetMediator__ConditionalTransferDoesNotExist();
    error MultiChainAssetMediator__NotConditionalTransferRecipient();
    error MultiChainAssetMediator__ConditionalTransferConditionNotMet(); // Simulated error for condition check
    error MultiChainAssetMediator__ConditionNotMet(); // Simulated error for general condition check
    error MultiChainAssetMediator__DependentContractAlreadyRegistered();


    // --- Modifiers ---

    modifier onlyMediator() {
        if (!_mediators[msg.sender]) {
            revert MultiChainAssetMediator__NotMediator();
        }
        _;
    }

    modifier onlyCrossChainMessenger() {
        if (msg.sender != crossChainMessenger) {
            revert MultiChainAssetMediator__CrossChainMessengerNotSet(); // Or a more specific unauthorized error
        }
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Owner is initially the deployer and also gets the mediator role by default
        _mediators[msg.sender] = true;
        emit MediatorRoleGranted(msg.sender);
    }

    // --- ERC721/Enumerable Overrides ---

    // Override tokenURI to allow specific URIs per token or fall back to base URI (not implemented base URI here for simplicity)
    // A real dynamic tokenURI might encode the mediated state or point to an IPFS hash updated by the contract.
    // Here, we allow setting a specific URI per token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         if (!_exists(tokenId)) {
            revert ERC721Enumerable.ERC721NonexistentToken(tokenId);
        }
        // Check for a specific description URI first
        string memory customURI = _tokenDescriptionURIs[tokenId];
        if (bytes(customURI).length > 0) {
            return customURI;
        }
        // Fallback: A more advanced contract would construct a dynamic URI here
        // based on _mediatedStates[tokenId] data, potentially encoding it or
        // pointing to a dynamic renderer service.
        // For simplicity, let's just return a placeholder or error.
        // return string(abi.encodePacked("ipfs://[placeholder_metadata_uri]/", Strings.toString(tokenId)));
         // Or return a URI that signifies no custom URI is set
         return ""; // Indicate no specific URI set
    }

    // Standard overrides for ERC721Enumerable work as expected.

    // --- Custom Core Functionality ---

    /// @notice Mints a new mediated asset token.
    /// @param to The address to mint the token to.
    /// @param initialMediatedState Initial state data for the new token.
    /// @param initialCrossChainRef Initial cross-chain reference data (optional).
    /// @return tokenId The ID of the newly minted token.
    function mintMediatedAsset(address to, bytes memory initialMediatedState, bytes memory initialCrossChainRef) external onlyOwnerOrMediator returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        _safeMint(to, tokenId);
        _mediatedStates[tokenId] = initialMediatedState;

        // Example: Assuming initialCrossChainRef contains {chainId}{referenceData}
        if (initialCrossChainRef.length >= 8) { // minimum 4 bytes for chainId + some ref data
             uint256 initialChainId;
             bytes memory refData;

             // Simple naive decoding: first 4 bytes are chainId (uint32 encoded as uint256), rest is refData
             assembly {
                 initialChainId := and(mload(add(initialCrossChainRef, 0x20)), 0xffffffff) // Load 4 bytes for chainId
             }
             if (initialCrossChainRef.length > 4) {
                 refData = initialCrossChainRef[4:];
             } else {
                  refData = bytes(""); // No reference data if only chainId is provided
             }
            _crossChainReferences[tokenId][initialChainId] = refData;
             emit CrossChainReferenceUpdated(tokenId, initialChainId, refData);
        }

        emit MediatedAssetMinted(tokenId, to, initialMediatedState);
    }

    /// @notice Burns a mediated asset token.
    /// @param tokenId The ID of the token to burn.
    function burnMediatedAsset(uint256 tokenId) external {
        // Only owner or approved/operator can burn
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender && !_mediators[msg.sender]) {
             revert ERC721.ERC721InsufficientApproval(msg.sender, tokenId);
        }
        _burn(tokenId);
        // Clean up state - important for gas efficiency if tokens are burned frequently
        delete _mediatedStates[tokenId];
        delete _crossChainReferences[tokenId]; // This only deletes the outer mapping, inner mappings persist? No, needs iteration or different structure for full cleanup.
        delete _conditionalRights[tokenId]; // Same here - needs iteration or different structure.
        delete _pendingTransfers[tokenId];
        delete _tokenDescriptionURIs[tokenId];
        delete _dependentContracts[tokenId]; // Same structure issue.

        emit MediatedAssetBurned(tokenId, msg.sender);
    }

    /// @notice Sets or updates the cross-chain reference data for a token on a specific target chain.
    /// @param tokenId The ID of the token.
    /// @param targetChainId The ID of the target blockchain network.
    /// @param referenceData Data identifying the asset/state on the target chain (e.g., contract address + token ID encoded).
    function setCrossChainReference(uint256 tokenId, uint256 targetChainId, bytes memory referenceData) external onlyMediator {
        if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();
        _crossChainReferences[tokenId][targetChainId] = referenceData;
        emit CrossChainReferenceUpdated(tokenId, targetChainId, referenceData);
    }

    /// @notice Retrieves the cross-chain reference data for a token on a specific target chain.
    /// @param tokenId The ID of the token.
    /// @param targetChainId The ID of the target blockchain network.
    /// @return referenceData The data stored for the reference.
    function getCrossChainReference(uint256 tokenId, uint256 targetChainId) external view returns (bytes memory) {
        if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();
        return _crossChainReferences[tokenId][targetChainId];
    }

    /// @notice Endpoint for the Cross-Chain Messenger to submit proof of an event on another chain.
    /// @dev This function *simulates* verification and processing. A real implementation
    /// would call an external verifier contract (`proofVerificationContract`) or perform on-chain verification.
    /// The proofData and sourceChainId are used to derive state updates.
    /// @param tokenId The ID of the token related to the cross-chain event.
    /// @param sourceChainId The ID of the chain where the event occurred.
    /// @param proofData The cryptographic proof data.
    function receiveAndProcessCrossChainProof(uint256 tokenId, uint256 sourceChainId, bytes memory proofData) external onlyCrossChainMessenger {
         if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();
         if (proofVerificationContract == address(0)) revert MultiChainAssetMediator__ProofVerificationContractNotSet();

         // --- SIMULATION OF PROOF VERIFICATION AND PROCESSING ---
         // In a real scenario:
         // 1. Call proofVerificationContract.verify(sourceChainId, proofData) -> returns (bool success, bytes memory eventPayload)
         // 2. If success, parse eventPayload to understand what happened on the other chain.
         // 3. Based on the parsed event, determine how the token's _mediatedStates or _conditionalRights should be updated.

         // For this example, we'll simply assume the proof is valid and contains data
         // that *implies* a state update. The specific update logic is placeholder.
         bool proofIsValid = true; // Replace with actual verification call
         bytes memory simulatedEventPayload = proofData; // In reality, this comes from verifier output

         if (!proofIsValid) {
             revert MultiChainAssetMediator__InvalidProof();
         }

         emit CrossChainProofReceived(tokenId, sourceChainId, proofData);

         // Example state update logic based on *simulated* event payload
         // A real contract would have complex logic here parsing simulatedEventPayload
         // For demonstration, let's just append data derived from the proof.
         bytes memory currentMediatedState = _mediatedStates[tokenId];
         bytes memory newState = abi.encodePacked(currentMediatedState, bytes("::ProofProcessed"), abi.encodePacked(sourceChainId), simulatedEventPayload);
         _mediatedStates[tokenId] = newState; // This is just an example update

         emit MediatedStateUpdated(tokenId, newState);

         // Check and potentially fulfill conditional rights or transfers triggered by this proof
         _checkForFulfilledConditions(tokenId, sourceChainId, proofData);
    }

     /// @notice Internal helper to check if any conditional rights or transfers are fulfilled by a proof.
     /// @dev This function would contain logic to iterate through pending conditions
     /// and check if the provided proof matches any of them. Placeholder logic here.
     function _checkForFulfilledConditions(uint256 tokenId, uint256 sourceChainId, bytes memory proofData) internal {
         // This is a complex part in a real implementation.
         // It would likely involve:
         // 1. Iterating through registered _conditionalRights for this tokenId.
         // 2. For each right, checking if its `requiredConditionData` is satisfied by the `proofData`
         //    and `sourceChainId` by interacting with the proof verification contract or having internal logic.
         // 3. If satisfied, trigger the right fulfillment.
         // 4. Checking if the _pendingTransfers condition is satisfied by the proofData.
         // 5. If satisfied, update the _pendingTransfers state.

         // Simplified Example: Assume proofData matches a condition ID directly
         bytes32 potentialRightId = keccak256(proofData); // Naive mapping of proof to condition ID
         ConditionalRight storage right = _conditionalRights[tokenId][potentialRightId];

         if (bytes(right.requiredConditionData).length > 0 && !right.claimed) {
             // Simulated condition check: Assume the proof itself is the condition data
             // A real check would be more complex, verifying proofData against right.requiredConditionData
             bool conditionMet = keccak256(proofData) == keccak256(right.requiredConditionData); // Placeholder check

             if (conditionMet) {
                 // Condition for this specific right is met
                 _fulfillConditionalRight(tokenId, potentialRightId, right); // Internal fulfillment logic
             }
         }

         // Check for pending conditional transfer as well
         ConditionalTransfer storage pendingTransfer = _pendingTransfers[tokenId];
         if (!pendingTransfer.finalized && pendingTransfer.newOwner != address(0)) {
              // Simulated check: Is proofData related to the condition for this transfer?
              // A real check would verify proofData against pendingTransfer.requiredConditionProofData
              bool transferConditionMet = keccak256(proofData) == keccak256(pendingTransfer.requiredConditionProofData); // Placeholder check

              if (transferConditionMet) {
                  // Condition for conditional transfer is met
                  _finalizedConditionalTransferInternal(tokenId, pendingTransfer); // Internal fulfillment
              }
         }

     }


    /// @notice Allows a Mediator to update the mediated state data of a token.
    /// @dev This function is intended to be called after a cross-chain proof has been processed,
    /// reflecting the state change on the other chain, but can be used for manual updates by mediators.
    /// @param tokenId The ID of the token.
    /// @param newStateData The new data representing the mediated state.
    function updateMediatedState(uint256 tokenId, bytes memory newStateData) external onlyMediator {
        if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();
         _updateMediatedStateInternal(tokenId, newStateData);
    }

    /// @dev Internal helper for updating mediated state.
    function _updateMediatedStateInternal(uint256 tokenId, bytes memory newStateData) internal {
        _mediatedStates[tokenId] = newStateData;
        emit MediatedStateUpdated(tokenId, newStateData);
         // Potentially trigger checks for conditional rights/transfers here too,
         // if conditions can be met purely by changes to the *local* mediated state
         // without an explicit cross-chain proof.
    }


    /// @notice Retrieves the current dynamic mediated state data for a token.
    /// @param tokenId The ID of the token.
    /// @return The mediated state data.
    function getMediatedState(uint256 tokenId) external view returns (bytes memory) {
        if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();
        return _mediatedStates[tokenId];
    }

    /// @notice Registers a potential future right associated with a token.
    /// @dev This right becomes claimable once the `requiredConditionData` is proven to be met,
    /// typically via a cross-chain proof submitted through `receiveAndProcessCrossChainProof`.
    /// @param tokenId The ID of the token.
    /// @param rightId A unique identifier for this specific right on the token.
    /// @param requiredConditionData Data describing the condition that must be proven (e.g., hash of state, event details).
    /// @param rightDetails Data describing the right being granted (e.g., details for an external contract to unlock funds).
    /// @param claimant The address allowed to claim this right (typically token owner).
    function registerConditionalRight(uint256 tokenId, bytes32 rightId, bytes memory requiredConditionData, bytes memory rightDetails, address claimant) external {
        // Only token owner or approved can register rights
        _requireOwnedOrApproved(tokenId);
        if (bytes(_conditionalRights[tokenId][rightId].requiredConditionData).length > 0) {
             // Prevent overwriting an existing right ID
             // Alternatively, could allow overwriting by owner with specific logic
             revert ("Right ID already exists"); // Custom error better
        }

        _conditionalRights[tokenId][rightId] = ConditionalRight(
            requiredConditionData,
            rightDetails,
            claimant,
            false
        );

        emit ConditionalRightRegistered(tokenId, rightId, claimant);
    }

     /// @notice Retrieves details of a specific conditional right registered on a token.
    /// @param tokenId The ID of the token.
    /// @param rightId The ID of the right.
    /// @return requiredConditionData Data describing the condition.
    /// @return rightDetails Data describing the right.
    /// @return claimant Address allowed to claim.
    /// @return claimed Whether the right has been claimed.
    function getConditionalRight(uint256 tokenId, bytes32 rightId) external view returns (bytes memory requiredConditionData, bytes memory rightDetails, address claimant, bool claimed) {
         if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();
         ConditionalRight storage right = _conditionalRights[tokenId][rightId];
         if (bytes(right.requiredConditionData).length == 0) revert MultiChainAssetMediator__RightDoesNotExist(); // Check if right exists by looking at condition data length

         return (right.requiredConditionData, right.rightDetails, right.claimant, right.claimed);
    }

    /// @notice Allows a claimant to claim a registered right by providing proof the required condition is met.
    /// @dev This function verifies the proof (simulated) and if valid, marks the right as claimed
    /// and potentially triggers external logic based on `rightDetails`.
    /// @param tokenId The ID of the token.
    /// @param rightId The ID of the right to claim.
    /// @param proofOfConditionMet The proof data verifying the condition.
    function claimConditionalRight(uint256 tokenId, bytes32 rightId, bytes memory proofOfConditionMet) external {
        if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();
        ConditionalRight storage right = _conditionalRights[tokenId][rightId];

        if (bytes(right.requiredConditionData).length == 0) revert MultiChainAssetMediator__RightDoesNotExist();
        if (right.claimed) revert MultiChainAssetMediator__RightAlreadyClaimed();
        if (msg.sender != right.claimant) revert MultiChainAssetMediator__NotRightClaimant();

        // --- SIMULATION OF PROOF VERIFICATION FOR CLAIM ---
        // This part would interact with the proofVerificationContract or contain
        // complex internal logic to verify proofOfConditionMet against right.requiredConditionData.
        if (proofVerificationContract == address(0)) revert MultiChainAssetMediator__ProofVerificationContractNotSet();
        // bool conditionMet = proofVerificationContract.verifyCondition(right.requiredConditionData, proofOfConditionMet); // Placeholder

        // For this example, we'll use a simple hash comparison simulation
        bool conditionMet = keccak256(proofOfConditionMet) == keccak256(right.requiredConditionData);

        if (!conditionMet) {
            revert MultiChainAssetMediator__ConditionNotMet();
        }

        // --- FULFILLMENT LOGIC (PLACEHOLDER) ---
        // Based on `right.rightDetails`, this contract could:
        // - Call another contract (e.g., unlock funds in a vault).
        // - Update the token's mediated state further.
        // - Grant a role or privilege.
        // This depends heavily on what the "right" represents.
        // For this example, we just mark it claimed and emit an event.

        right.claimed = true;
        emit ConditionalRightClaimed(tokenId, rightId, msg.sender);
         // Potentially emit an event with right.rightDetails for external listeners/contracts to act upon.
    }

     /// @dev Internal helper to fulfill a conditional right.
    function _fulfillConditionalRight(uint256 tokenId, bytes32 rightId, ConditionalRight storage right) internal {
         if (right.claimed) return; // Already claimed, avoid double fulfillment

         // --- FULFILLMENT LOGIC (CALLED INTERNALLY AFTER PROOF PROCESSING) ---
         // This is similar to the fulfillment logic in `claimConditionalRight` but called
         // automatically when a proof processed by `receiveAndProcessCrossChainProof`
         // is found to fulfill a condition.
         // The `rightDetails` could encode information about what external action to take.

         right.claimed = true;
         emit ConditionalRightClaimed(tokenId, rightId, right.claimant);
         // Emit event with right.rightDetails for external listeners/contracts.
    }


    /// @notice Revokes a previously registered conditional right before it is claimed.
    /// @dev Only the current token owner can revoke a pending right.
    /// @param tokenId The ID of the token.
    /// @param rightId The ID of the right to revoke.
    /// @param reason A string explaining the reason for revocation.
    function revokeConditionalRight(uint256 tokenId, bytes32 rightId, string memory reason) external {
        _requireOwned(tokenId); // Only token owner can revoke
        ConditionalRight storage right = _conditionalRights[tokenId][rightId];

        if (bytes(right.requiredConditionData).length == 0) revert MultiChainAssetMediator__RightDoesNotExist();
        if (right.claimed) revert ("Right already claimed, cannot revoke"); // Custom error better

        delete _conditionalRights[tokenId][rightId]; // Remove the right

        emit ("ConditionalRightRevoked(tokenId, rightId, reason)"); // Custom event better
    }


    /// @notice Adds an account to the list of authorized Mediators.
    /// @param account The address to grant the Mediator role.
    function addMediatorRole(address account) external onlyOwner {
        if (!_mediators[account]) {
            _mediators[account] = true;
            emit MediatorRoleGranted(account);
        }
    }

    /// @notice Removes an account from the list of authorized Mediators.
    /// @param account The address to revoke the Mediator role from.
    function removeMediatorRole(address account) external onlyOwner {
        if (_mediators[account]) {
            _mediators[account] = false;
            emit MediatorRoleRevoked(account);
        }
    }

    /// @notice Checks if an address has the Mediator role.
    /// @param account The address to check.
    /// @return True if the account is a Mediator, false otherwise.
    function hasMediatorRole(address account) external view returns (bool) {
        return _mediators[account];
    }

    /// @notice Sets the address of the external Proof Verification contract.
    /// @dev This contract is assumed to have a function like `verify(uint256 chainId, bytes memory proofData)`
    /// and potentially `verifyCondition(bytes memory conditionData, bytes memory proofData)`.
    /// @param verifierAddress The address of the verifier contract.
    function setProofVerificationContract(address verifierAddress) external onlyOwner {
        proofVerificationContract = verifierAddress;
        emit ProofVerificationContractSet(verifierAddress);
    }

    /// @notice Sets the address of the external Cross-Chain Messenger contract.
    /// @dev This address is the only one allowed to call `receiveAndProcessCrossChainProof`
    /// and `finalizeCrossChainTransferIn`.
    /// @param messengerAddress The address of the messenger contract.
    function setCrossChainMessenger(address messengerAddress) external onlyOwner {
        crossChainMessenger = messengerAddress;
        emit CrossChainMessengerSet(messengerAddress);
    }

    /// @notice Records the intent to transfer the token's representation to another chain.
    /// @dev This initiates an off-chain or cross-chain bridge process. The token *remains* on this chain
    /// until `finalizeCrossChainTransferIn` is called on the *target* chain's instance of this contract,
    /// and then this contract's token is potentially burned or locked.
    /// @param tokenId The ID of the token to transfer.
    /// @param targetChainId The ID of the destination chain.
    /// @param recipientOnTarget The recipient's address on the destination chain.
    function initiateCrossChainTransferRequest(uint256 tokenId, uint256 targetChainId, address recipientOnTarget) external {
        _requireOwnedOrApproved(tokenId); // Only owner or approved can initiate

        // --- SIMULATION: Record the intent ---
        // A real bridge would lock the token here and relay a message.
        // This contract just records the request. The actual token transfer happens
        // off-chain or requires a separate call/protocol interaction.
        // We could add state to lock the token here if needed.

        // For this simple example, we just emit an event.
        // In a more complex scenario, we might move the token to an escrow address
        // or add a state variable marking it as 'transferring'.

        emit CrossChainTransferRequestInitiated(tokenId, targetChainId, recipientOnTarget);

        // The actual burning on this chain or minting on the target chain happens
        // as part of the cross-chain messaging protocol's fulfillment,
        // potentially triggered by a successful `finalizeCrossChainTransferIn` on the target side.
    }

    /// @notice Endpoint called by the Cross-Chain Messenger to finalize a token transfer *into* this contract.
    /// @dev This signifies that a representation of the asset/state was locked or burned
    /// on the `sourceChainId` and should now be represented by `tokenId` on this chain.
    /// Assumes `tokenId` either pre-existed or is assigned as part of the cross-chain process.
    /// If `tokenId` exists, ownership is transferred. If not, it might be minted (more complex).
    /// @param tokenId The ID of the token on *this* chain.
    /// @param sourceChainId The chain ID the transfer originated from.
    /// @param sourceAssetIdentifier Data identifying the asset/state on the source chain.
    /// @param recipient The address on this chain who should receive the token.
    function finalizeCrossChainTransferIn(uint256 tokenId, uint256 sourceChainId, bytes memory sourceAssetIdentifier, address recipient) external onlyCrossChainMessenger {
        if (!_exists(tokenId)) {
            // Case 1: Token needs to be minted as it's arriving for the first time or returning
            // This is complex. For simplicity, let's assume the tokenId corresponds to an existing token.
            // A real system might require minting here based on sourceAssetIdentifier.
             revert MultiChainAssetMediator__TokenDoesNotExist(); // Assuming token must pre-exist for now
        }

        // Case 2: Token exists, ownership is being transferred in
        address currentOwner = ownerOf(tokenId);
        // If it's currently owned by an escrow/bridge address, proceed.
        // If it's owned by a regular user, this might be an error or specific re-entry logic.
        // For simplicity, we'll just transfer it.

        _transfer(currentOwner, recipient, tokenId); // Use _transfer for internal call

        // Optionally, update the mediated state based on arrival or source state.
        // _updateMediatedStateInternal(tokenId, abi.encodePacked("ArrivedFromChain", sourceChainId, sourceAssetIdentifier));

        // Update the cross-chain reference to reflect its origin point for this transfer
         setCrossChainReference(tokenId, sourceChainId, sourceAssetIdentifier); // Reuse internal setter logic

        emit CrossChainTransferFinalizedIn(tokenId, sourceChainId, recipient);
    }


    /// @notice Allows a trusted entity (Mediator) or potentially the owner with a simple proof
    /// to assert a state snapshot (represented by a hash) for a token on another chain.
    /// @dev This is useful when full on-chain verification is too costly or complex.
    /// It relies on the attester's trustworthiness but records the attestation on-chain.
    /// Does *not* verify the proof cryptographically on-chain, just records it.
    /// @param tokenId The ID of the token.
    /// @param chainId The chain ID the state is on.
    /// @param stateHash The hash representing the state snapshot.
    /// @param attestationProof Optional data supporting the attestation (e.g., signed message).
    function attestToStateOnOtherChain(uint256 tokenId, uint256 chainId, bytes32 stateHash, bytes memory attestationProof) external onlyMediator { // Could add specific attester role or allow owner with signed proof
        if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();

        // Store the attestation. The stateHash can become part of the token's mediated state
        // or be stored separately. Let's add it to the mediated state for simplicity.
        bytes memory currentState = _mediatedStates[tokenId];
        bytes memory attestedStateUpdate = abi.encodePacked(currentState, bytes("::AttestedState"), abi.encodePacked(chainId), abi.encodePacked(stateHash), attestationProof);

        _updateMediatedStateInternal(tokenId, attestedStateUpdate); // Update mediated state to include attestation info

        emit AttestationToStateRecorded(tokenId, chainId, stateHash, msg.sender);
    }

    /// @notice Registers a local contract that depends on the state of this mediated token.
    /// @dev Allows external contracts to signal their dependency. This contract can emit events
    /// to notify them upon state changes. The `requiredStateHash` is optional, could be
    /// a hash of a specific state the dependent contract needs.
    /// @param tokenId The ID of the token.
    /// @param dependentContractAddress The address of the dependent contract.
    /// @param requiredStateHash An optional hash representing the state dependency. Use bytes32(0) if none.
    function registerDependentContract(uint256 tokenId, address dependentContractAddress, bytes32 requiredStateHash) external {
        _requireOwnedOrApproved(tokenId); // Only token owner or approved can register dependencies

        if (_dependentContracts[tokenId][dependentContractAddress] != bytes32(0) && requiredStateHash != bytes32(0)) {
             // Simple check: if already registered with a specific hash, disallow re-registration
             revert MultiChainAssetMediator__DependentContractAlreadyRegistered(); // Or allow update? Let's disallow for now.
        }
        _dependentContracts[tokenId][dependentContractAddress] = requiredStateHash; // Store dependency

        emit DependentContractRegistered(tokenId, dependentContractAddress, requiredStateHash);
    }

    /// @notice Emits an event to notify registered dependent contracts that the token's state *might* have changed.
    /// @dev This function does *not* make external calls to avoid reentrancy issues.
    /// Dependent contracts must listen for the `MediatedStateUpdated` event.
    /// This function serves as a manual trigger *after* a state update occurred if needed,
    /// though `_updateMediatedStateInternal` already emits `MediatedStateUpdated`.
    /// Could be useful if updates happen outside of `receiveAndProcessCrossChainProof` or `updateMediatedState`.
    /// @param tokenId The ID of the token.
    function notifyDependentContracts(uint256 tokenId) external onlyMediator { // Or maybe only owner? Let's stick to Mediator for state management context.
        if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();

        // The primary notification is the `MediatedStateUpdated` event.
        // This function can be called manually by a mediator to nudge dependents,
        // or could iterate through registered addresses and emit targeted events
        // (more complex, avoided here).
        // We'll just rely on the general state updated event.

        // A more complex version would iterate:
        // for (address dependent : _getDependentContracts(tokenId)) { // Requires storing dependents in an array or iterable map
        //     emit DependentContractNotification(tokenId, dependent, _mediatedStates[tokenId]);
        // }

        // For this version, we just assume they listen to the main event.
        // If no state update occurred recently, this call doesn't trigger a new state update event.
        // We could add an event specifically for *this* notification call if needed.
         emit ("DependentContractsNotified(tokenId)"); // Placeholder event
    }


    /// @notice Calculates a dynamic fee for a specific action based on the token's state.
    /// @dev This is a placeholder logic. A real implementation would have complex fee calculation
    /// based on the content of _mediatedStates, number of cross-chain refs, etc.
    /// @param tokenId The ID of the token.
    /// @param actionType A hash or identifier for the action (e.g., keccak256("TRANSFER"), keccak256("CLAIM_RIGHT")).
    /// @return fee The calculated fee amount.
    function calculateDynamicFee(uint256 tokenId, bytes32 actionType) public view returns (uint256 fee) {
         if (!_exists(tokenId)) return 0; // No fee for non-existent token

        // --- SIMULATION OF DYNAMIC FEE CALCULATION ---
        // Example: Fee based on the length of the mediated state data.
        // Longer state = potentially more complex history = higher fee.
        uint256 stateLength = _mediatedStates[tokenId].length;
        uint256 baseFee = 1e16; // 0.01 ether or token units

        // Example logic:
        if (actionType == keccak256("TRANSFER")) {
            fee = baseFee + (stateLength * 1e15); // Add 0.001 per byte of state
        } else if (actionType == keccak256("CLAIM_RIGHT")) {
             fee = baseFee / 2 + (stateLength * 1e14); // Half base fee + 0.0001 per byte
        } else {
            fee = baseFee; // Default fee
        }

        // Could also factor in number of cross-chain references, specific state flags, etc.
    }

    /// @notice Sets a specific description URI for a token, overriding any base URI logic.
    /// @dev Useful for dynamic metadata where the URI itself changes based on mediated state.
    /// @param tokenId The ID of the token.
    /// @param descriptionURI The URI pointing to the token's metadata.
    function setTokenDescription(uint256 tokenId, string memory descriptionURI) external {
        _requireOwnedOrApproved(tokenId); // Only token owner or approved can set description

        _tokenDescriptionURIs[tokenId] = descriptionURI;
        emit TokenDescriptionSet(tokenId, descriptionURI);
    }

    /// @notice Gets the specific description URI for a token.
    /// @param tokenId The ID of the token.
    /// @return descriptionURI The custom URI set for the token, or empty string if none.
    function getTokenDescription(uint256 tokenId) external view returns (string memory) {
         if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();
        return _tokenDescriptionURIs[tokenId];
    }

    /// @notice Initiates a pending ownership transfer for a token, contingent on a condition.
    /// @dev The token's ownership is not transferred immediately. The `newOwner` must call
    /// `claimConditionalTransfer` with proof that `requiredConditionProofData` is met.
    /// @param tokenId The ID of the token.
    /// @param newOwner The address that will become the new owner if the condition is met.
    /// @param requiredConditionProofData Data describing the proof required to finalize the transfer.
    function transferOwnershipWithConditions(uint256 tokenId, address newOwner, bytes memory requiredConditionProofData) external {
         _requireOwned(tokenId); // Only current owner can initiate conditional transfer
         if (newOwner == address(0)) revert ERC721.ERC721InvalidReceiver(address(0));

         // Overwrite any existing pending transfer for this token
         _pendingTransfers[tokenId] = ConditionalTransfer(
            newOwner,
            requiredConditionProofData,
            uint64(block.timestamp),
            false
         );

         emit ConditionalTransferRequested(tokenId, newOwner, uint64(block.timestamp));
         // Note: The token is NOT transferred at this stage.
    }

    /// @notice Finalizes a pending conditional ownership transfer by providing proof the condition is met.
    /// @dev Only the designated `newOwner` from the pending request can call this function.
    /// @param tokenId The ID of the token.
    /// @param proofOfConditionMet The proof data verifying the condition required by the pending request.
    function claimConditionalTransfer(uint256 tokenId, bytes memory proofOfConditionMet) external {
         if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();
         ConditionalTransfer storage pendingTransfer = _pendingTransfers[tokenId];

         if (pendingTransfer.newOwner == address(0)) revert MultiChainAssetMediator__ConditionalTransferDoesNotExist();
         if (pendingTransfer.finalized) revert MultiChainAssetMediator__ConditionalTransferAlreadyFinalized();
         if (msg.sender != pendingTransfer.newOwner) revert MultiChainAssetMediator__NotConditionalTransferRecipient();

         // --- SIMULATION OF PROOF VERIFICATION FOR TRANSFER ---
         // This part would interact with the proofVerificationContract or contain
         // complex internal logic to verify proofOfConditionMet against pendingTransfer.requiredConditionProofData.
         if (proofVerificationContract == address(0)) revert MultiChainAssetMediator__ProofVerificationContractNotSet();
         // bool conditionMet = proofVerificationContract.verifyCondition(pendingTransfer.requiredConditionProofData, proofOfConditionMet); // Placeholder

         // For this example, we'll use a simple hash comparison simulation
         bool conditionMet = keccak256(proofOfConditionMet) == keccak256(pendingTransfer.requiredConditionProofData);

         if (!conditionMet) {
             revert MultiChainAssetMediator__ConditionalTransferConditionNotMet();
         }

         // Condition met! Finalize the transfer.
         address currentOwner = ownerOf(tokenId);
         _transfer(currentOwner, pendingTransfer.newOwner, tokenId); // Transfer ownership

         pendingTransfer.finalized = true; // Mark as finalized

         emit ConditionalTransferClaimed(tokenId, pendingTransfer.newOwner);
         // Could also delete the pending request after finalization to save space, but keeping it
         // marked finalized allows querying historical requests.
    }

     /// @dev Internal helper to finalize a conditional transfer when the condition is met internally (e.g., via `receiveAndProcessCrossChainProof`).
     function _finalizedConditionalTransferInternal(uint256 tokenId, ConditionalTransfer storage pendingTransfer) internal {
         if (pendingTransfer.finalized) return; // Already finalized

         // Condition met! Finalize the transfer.
         address currentOwner = ownerOf(tokenId);
         _transfer(currentOwner, pendingTransfer.newOwner, tokenId); // Transfer ownership

         pendingTransfer.finalized = true; // Mark as finalized

         emit ConditionalTransferClaimed(tokenId, pendingTransfer.newOwner);
     }


    /// @notice Retrieves details of a pending conditional ownership transfer request.
    /// @param tokenId The ID of the token.
    /// @return newOwner The potential new owner address.
    /// @return requiredConditionProofData Data describing the proof needed.
    /// @return requestTimestamp Timestamp when the request was made.
    /// @return finalized Whether the transfer has been finalized.
    function getPendingTransferRequest(uint256 tokenId) external view returns (address newOwner, bytes memory requiredConditionProofData, uint64 requestTimestamp, bool finalized) {
         if (!_exists(tokenId)) revert MultiChainAssetMediator__TokenDoesNotExist();
         ConditionalTransfer storage pendingTransfer = _pendingTransfers[tokenId];
         return (pendingTransfer.newOwner, pendingTransfer.requiredConditionProofData, pendingTransfer.requestTimestamp, pendingTransfer.finalized);
    }


    // --- Internal Helpers ---

    /// @dev Checks if the caller is the token owner or is approved/approved for all.
    function _requireOwnedOrApproved(uint256 tokenId) internal view {
         address owner = ownerOf(tokenId); // ERC721Enumerable handles existence check
         if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
             revert ERC721.ERC721InsufficientApproval(msg.sender, tokenId);
         }
     }

     /// @dev Checks if the caller is the token owner.
     function _requireOwned(uint256 tokenId) internal view {
         address owner = ownerOf(tokenId); // ERC721Enumerable handles existence check
         if (msg.sender != owner) {
             revert ERC721.ERC721IncorrectOwner(msg.sender, tokenId, owner);
         }
     }

     /// @dev Checks if a token exists.
     function _exists(uint256 tokenId) internal view returns (bool) {
        // Using ownerOf check as ERC721Enumerable makes it efficient via _tokenOwners
        return ownerOf(tokenId) != address(0);
    }

    // --- Owner/Mediator Combined Modifier ---
    // Useful for functions that can be triggered by either role.
    modifier onlyOwnerOrMediator() {
        if (msg.sender != owner() && !_mediators[msg.sender]) {
             revert MultiChainAssetMediator__NotMediator(); // Reuse mediator error or create a specific one
        }
        _;
    }


    // --- Additional potential complex features not implemented here: ---
    // - On-chain logic execution triggered by state changes/proofs.
    // - More sophisticated dynamic fee logic (e.g., tiering, time-based).
    // - Integration with IPFS for metadata hosting updated on state changes.
    // - Governance mechanisms (DAO) for critical changes instead of simple Ownable/Mediator roles.
    // - Batched proof processing.
    // - Timestamps or versioning for mediated state updates and cross-chain references.
    // - Pause/Unpause mechanisms for certain functions.
    // - ERC165 for interfaces. (Added supportsInterface)
    // - Using Libraries for complex data encoding/decoding in proofs or state.
    // - Gas optimization techniques specific to storage patterns.
    // - Proper cleanup of mapping entries upon burning (requires iteration or more complex structures).

}
```