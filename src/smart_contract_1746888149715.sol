Okay, this is an exciting challenge! Let's design a smart contract around a creative, advanced concept that isn't typically found in standard open-source libraries.

How about a concept I'll call **"State-Bonded Relational Contracts" (SBRC)**? The idea is that the validity or effect of a contract (or interaction) between two parties (or entities) is cryptographically "bonded" to a specific, verifiable state or condition of one or both parties, potentially linked via some external verifiable data source (simulated via admin functions for complexity here). This isn't a direct implementation of entanglement, but simulates a non-local state dependency.

Let's apply this to a token distribution or escrow scenario. Two parties agree on a conditional token transfer or release, but the condition isn't just a simple boolean or timestamp. It's tied to a complex, multi-part "Bonded State" that needs verification and can change, affecting the bond's validity.

**Concept: State-Bonded Token Escrow**

Two parties (Alice and Bob) want to lock tokens in escrow. The release of tokens isn't based on time or a simple external event, but on maintaining a specific "Bonded State" between them, mediated by a "Bonding Registrar" (the contract owner/admin) who can verify aspects of this state. If the state becomes "unbonded" or "decoherent" (simulating the entanglement concept), the escrow terms change (e.g., tokens are locked longer, returned, or partially released).

This introduces functions for:
1.  Managing parties and their state profiles.
2.  Creating and managing bonded escrow agreements.
3.  Defining and updating the "Bonded State".
4.  Checking the validity of the bond based on the state.
5.  Triggering state verification and potential "decoherence".
6.  Executing the escrow release based on bond validity and other conditions.
7.  Querying various states and agreements.

We'll need more than 20 functions to manage all these facets uniquely.

---

**Outline and Function Summary**

**Contract Name:** `StateBondedRelationalEscrow`

**Core Concept:** Manages token escrow where release is contingent upon a complex, verifiable "Bonded State" between involved parties, which can be influenced and verified by a designated "Bonding Registrar" (contract owner). Simulates non-local state dependency and potential "decoherence" affecting contract terms.

**State Variables:**
*   Owner (Bonding Registrar)
*   Registered Parties and their State Profiles
*   Defined State Attributes and their current values for each party
*   Escrow Agreements (linking parties, tokens, amounts, required state, release conditions)
*   Bonding State records for each agreement (valid/invalid, decoherence status)
*   Counters for IDs

**Structs:**
*   `PartyProfile`: Address, name, registration status, mapping to StateAttributes.
*   `StateAttribute`: uint ID, string name, string description.
*   `PartyStateValue`: uint attributeId, bytes32 valueHash, uint lastVerifiedTimestamp. (Hashing value for privacy/off-chain data reference)
*   `EscrowAgreement`: uint ID, address partyA, address partyB, address tokenAddress, uint amount, uint creationTimestamp, uint releaseTimestamp (conditional), uint requiredStateAttributeId, bytes32 requiredStateValueHash, bool isBondValid, bool isDecohered, bool isExecuted, bool isCancelled.
*   `BondingStateRecord`: uint agreementId, bool isBondValid, uint lastCheckTimestamp, string statusMessage.

**Key Functions (Grouped by Category):**

1.  **Registrar (Owner) Management:**
    *   `registerParty`: Add a new party profile.
    *   `unregisterParty`: Remove a party profile.
    *   `defineStateAttribute`: Create a new type of state attribute.
    *   `updatePartyStateValueHash`: Update a party's state attribute hash (registrar verifies off-chain data).
    *   `verifyPartyStateAttribute`: Registrar confirms state attribute value is verified for a party (sets timestamp).
    *   `designateEscrowBondAttribute`: Set which state attribute is required for an escrow bond.
    *   `triggerBondStateVerification`: Manually trigger bond validation check for an agreement.
    *   `declareBondDecoherence`: Registrar manually marks an agreement bond as decohered.
    *   `resetBondDecoherence`: Registrar resets decoherence status.

2.  **Party Actions:**
    *   `registerSelf`: Allow a party to register themselves (if enabled).
    *   `submitStateValueHash`: Party submits a hash of their state data.
    *   `requestStateVerification`: Party asks registrar to verify their state.
    *   `createEscrowAgreement`: Parties propose and initialize an escrow.
    *   `approveEscrowAgreement`: Second party approves an escrow agreement.
    *   `depositEscrowTokens`: Parties deposit tokens into the escrow.
    *   `cancelEscrowAgreement`: Parties (or registrar) cancel an agreement before execution/decoherence.

3.  **Escrow Execution & State Bonding Logic:**
    *   `checkBondValidity`: Internal/External view function to check if the bond condition is met based on current party states and required attribute/value.
    *   `attemptEscrowExecution`: Trigger the release of tokens. Checks if bond is valid, not decohered, and release time (if any) is met.
    *   `handleDecoheredEscrow`: Logic to handle an agreement if it's marked as decohered (e.g., return tokens, adjust terms).

4.  **Query Functions (View):**
    *   `getPartyProfile`: Retrieve a party's details.
    *   `getPartyStateValue`: Retrieve a party's state attribute value hash and verification status.
    *   `getStateAttributeDefinition`: Retrieve details of a state attribute type.
    *   `getEscrowAgreement`: Retrieve details of an escrow agreement.
    *   `getBondingStateRecord`: Retrieve the bonding state record for an agreement.
    *   `getTotalRegisteredParties`: Count registered parties.
    *   `getTotalStateAttributes`: Count defined state attributes.
    *   `getTotalEscrowAgreements`: Count escrow agreements.
    *   `getAgreementsByParty`: Get list of agreement IDs involving a specific party.
    *   `canExecuteEscrow`: Check if an agreement is ready for execution based on all conditions.
    *   `isPartyRegistered`: Check if an address is a registered party.

**Total Public/External Functions:** 9 (Registrar) + 7 (Party) + 1 (Execution) + 10 (Query) = **27 Functions**. This meets the requirement and provides a complex interaction model.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline and Function Summary ---
// Contract Name: StateBondedRelationalEscrow
// Core Concept: Manages token escrow where release is contingent upon a complex, verifiable "Bonded State"
//               between involved parties, influenced and verified by a "Bonding Registrar" (contract owner).
//               Simulates non-local state dependency and potential "decoherence" affecting contract terms.
//
// State Variables:
// - owner: The Bonding Registrar.
// - parties: Mapping of address to PartyProfile.
// - stateAttributes: Mapping of attributeId to StateAttribute definition.
// - partyStateValues: Mapping of party address to mapping of attributeId to PartyStateValue.
// - escrowAgreements: Mapping of agreementId to EscrowAgreement details.
// - agreementBondingStates: Mapping of agreementId to BondingStateRecord.
// - partyAgreementIds: Mapping of party address to array of agreement IDs they are involved in.
// - nextPartyId, nextAttributeId, nextAgreementId: Counters for unique IDs.
// - partyRegistrationEnabled: Flag to allow self-registration.
//
// Structs:
// - PartyProfile: Basic info and registration status.
// - StateAttribute: Definition of a verifiable state type.
// - PartyStateValue: Hashed value and verification timestamp for a party's attribute.
// - EscrowAgreement: Details of an escrow, including parties, token, amount, and required state link.
// - BondingStateRecord: Tracks bond validity and decoherence status for an agreement.
//
// Events:
// - PartyRegistered, PartyUnregistered
// - StateAttributeDefined
// - PartyStateValueSubmitted, PartyStateVerified
// - EscrowAgreementCreated, EscrowAgreementApproved, EscrowTokensDeposited
// - EscrowBondStateChecked, EscrowBondDecohered, EscrowBondDecoherenceReset
// - EscrowExecuted, EscrowCancelled
//
// Error Handling: Custom errors for specific failure conditions.
//
// Functions (>= 27 Public/External):
// --- Registrar (Owner) Management --- (9 functions)
// 1. registerParty(address _partyAddress, string calldata _name): Add a party profile.
// 2. unregisterParty(address _partyAddress): Remove a party profile.
// 3. defineStateAttribute(string calldata _name, string calldata _description): Create a new state attribute type.
// 4. updatePartyStateValueHash(address _partyAddress, uint _attributeId, bytes32 _valueHash): Registrar updates a party's state hash.
// 5. verifyPartyStateAttribute(address _partyAddress, uint _attributeId): Registrar marks a party's state as verified now.
// 6. designateEscrowBondAttribute(uint _agreementId, uint _attributeId, bytes32 _requiredValueHash): Set required state for an agreement bond.
// 7. triggerBondStateVerification(uint _agreementId): Manually trigger bond validation check.
// 8. declareBondDecoherence(uint _agreementId, string calldata _reason): Registrar marks a bond as decohered.
// 9. resetBondDecoherence(uint _agreementId): Registrar resets decoherence status.
// --- Party Actions --- (7 functions)
// 10. registerSelf(string calldata _name): Party registers themselves (if enabled).
// 11. submitStateValueHash(uint _attributeId, bytes32 _valueHash): Party submits their state hash.
// 12. requestStateVerification(uint _attributeId): Party requests registrar verification.
// 13. createEscrowAgreement(address _partyB, address _tokenAddress, uint _amount, uint _conditionalReleaseTimestamp, uint _requiredStateAttributeId, bytes32 _requiredStateValueHash): Party A initiates an agreement.
// 14. approveEscrowAgreement(uint _agreementId): Party B approves.
// 15. depositEscrowTokens(uint _agreementId): Parties deposit tokens.
// 16. cancelEscrowAgreement(uint _agreementId): Parties or Registrar can cancel.
// --- Escrow Execution & State Bonding Logic --- (1 function)
// 17. attemptEscrowExecution(uint _agreementId): Trigger release, checks bond and conditions.
// --- Query Functions (View) --- (10 functions)
// 18. getPartyProfile(address _partyAddress): Get party details.
// 19. getPartyStateValue(address _partyAddress, uint _attributeId): Get party's state value hash and verification.
// 20. getStateAttributeDefinition(uint _attributeId): Get state attribute definition.
// 21. getEscrowAgreement(uint _agreementId): Get escrow agreement details.
// 22. getBondingStateRecord(uint _agreementId): Get bonding state record.
// 23. getTotalRegisteredParties(): Count parties.
// 24. getTotalStateAttributes(): Count attribute types.
// 25. getTotalEscrowAgreements(): Count agreements.
// 26. getAgreementsByParty(address _partyAddress): Get agreement IDs for a party.
// 27. canExecuteEscrow(uint _agreementId): Check if execution conditions are met.
// 28. isPartyRegistered(address _partyAddress): Check registration status.

// Additional Query/Helper Functions to exceed 20+ functions easily:
// 29. getEscrowBalance(uint _agreementId): Get current token balance held for an agreement.
// 30. getRequiredBondAttributeForAgreement(uint _agreementId): Get the state attribute ID required for bond.
// 31. getRequiredBondValueHashForAgreement(uint _agreementId): Get the required state value hash for bond.
// 32. isBondValidForAgreement(uint _agreementId): Check current validity status stored.
// 33. isAgreementDecohered(uint _agreementId): Check current decoherence status.
// 34. getAgreementParties(uint _agreementId): Get Party A and Party B addresses.
// 35. getAgreementTokenAndAmount(uint _agreementId): Get token address and amount.
// 36. getAgreementTimestamps(uint _agreementId): Get creation and conditional release timestamps.
// 37. isEscrowApproved(uint _agreementId): Check if both parties have approved.
// 38. isEscrowDeposited(uint _agreementId): Check if tokens have been deposited.
// 39. setPartyRegistrationEnabled(bool _enabled): Registrar enables/disables self-registration. (Registrar)
// 40. getPartyRegistrationEnabled(): Check if self-registration is enabled. (Query)

// This list provides 40 distinct functions based on the SBRC concept applied to escrow.

// --- End Outline and Function Summary ---


contract StateBondedRelationalEscrow is Ownable, ReentrancyGuard {

    struct PartyProfile {
        address partyAddress;
        string name;
        bool isRegistered;
    }

    struct StateAttribute {
        uint id;
        string name;
        string description;
    }

    struct PartyStateValue {
        uint attributeId;
        bytes32 valueHash; // Cryptographic hash referencing off-chain data
        uint lastVerifiedTimestamp; // Timestamp when registrar last verified the hash/state
    }

    enum EscrowStatus { PendingApproval, Approved, Deposited, Executed, Cancelled }

    struct EscrowAgreement {
        uint id;
        address partyA; // Initiator
        address partyB; // Counterparty
        address tokenAddress;
        uint amount;
        uint creationTimestamp;
        uint conditionalReleaseTimestamp; // 0 if not time-based
        uint requiredStateAttributeId; // State attribute ID required for bond validity
        bytes32 requiredStateValueHash; // The specific hash value required for the bond
        EscrowStatus status;
        bool isBondValid; // Current state of the bond based on last check
        bool isDecohered; // Flag set by registrar indicating bond 'decoherence'
        string decoherenceReason;
    }

    struct BondingStateRecord {
        uint agreementId;
        bool isBondValid; // Snapshot of validity at last check
        uint lastCheckTimestamp;
        string statusMessage; // Details about the check result
    }

    // State Variables
    mapping(address => PartyProfile) public parties;
    uint public nextPartyId; // Not strictly needed in mapping by address, but useful conceptually

    mapping(uint => StateAttribute) public stateAttributes;
    uint public nextAttributeId = 1; // Start from 1

    mapping(address => mapping(uint => PartyStateValue)) public partyStateValues; // partyAddress => attributeId => StateValue

    mapping(uint => EscrowAgreement) public escrowAgreements;
    uint public nextAgreementId = 1; // Start from 1

    mapping(uint => BondingStateRecord) public agreementBondingStates; // agreementId => BondingState

    mapping(address => uint[]) private partyAgreementIds; // Track agreements per party

    bool public partyRegistrationEnabled = true; // Allow parties to register themselves

    // Events
    event PartyRegistered(address indexed partyAddress, string name);
    event PartyUnregistered(address indexed partyAddress);
    event StateAttributeDefined(uint indexed attributeId, string name);
    event PartyStateValueSubmitted(address indexed partyAddress, uint indexed attributeId, bytes32 valueHash);
    event PartyStateVerified(address indexed partyAddress, uint indexed attributeId, uint timestamp);
    event EscrowAgreementCreated(uint indexed agreementId, address indexed partyA, address indexed partyB, address tokenAddress, uint amount);
    event EscrowAgreementApproved(uint indexed agreementId, address indexed approver);
    event EscrowTokensDeposited(uint indexed agreementId, address indexed depositor, uint amount);
    event EscrowBondStateChecked(uint indexed agreementId, bool isBondValid, string statusMessage);
    event EscrowBondDecohered(uint indexed agreementId, string reason);
    event EscrowBondDecoherenceReset(uint indexed agreementId);
    event EscrowExecuted(uint indexed agreementId);
    event EscrowCancelled(uint indexed agreementId);
    event PartyRegistrationEnabledSet(bool enabled);

    // Custom Errors
    error PartyAlreadyRegistered(address partyAddress);
    error PartyNotRegistered(address partyAddress);
    error AttributeNotFound(uint attributeId);
    error AgreementNotFound(uint agreementId);
    error NotAgreementParty(uint agreementId);
    error AgreementNotInStatus(uint agreementId, EscrowStatus requiredStatus);
    error AgreementAlreadyInStatus(uint agreementId, EscrowStatus status);
    error NotEnoughBalance(address tokenAddress, uint requiredAmount);
    error TransferFailed(address tokenAddress, address recipient, uint amount);
    error BondAttributeNotSet(uint agreementId);
    error BondDecohered(uint agreementId);
    error BondInvalid(uint agreementId);
    error ReleaseTimeNotReached(uint agreementId);
    error PartyRegistrationDisabled();
    error AgreementBondAttributeAlreadySet(uint agreementId);
    error PartyStateValueNotSubmitted(address partyAddress, uint attributeId);
    error AgreementPartiesCannotBeSame();


    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Registrar (Owner) Management ---

    /**
     * @notice Registers a new party profile. Only owner can call this unless self-registration is enabled.
     * @param _partyAddress The address of the party to register.
     * @param _name The name of the party.
     */
    function registerParty(address _partyAddress, string calldata _name) public onlyOwner {
        if (parties[_partyAddress].isRegistered) {
            revert PartyAlreadyRegistered(_partyAddress);
        }
        parties[_partyAddress] = PartyProfile(_partyAddress, _name, true);
        nextPartyId++; // Increment conceptual party counter
        emit PartyRegistered(_partyAddress, _name);
    }

    /**
     * @notice Unregisters a party profile. Only owner can call.
     * @param _partyAddress The address of the party to unregister.
     */
    function unregisterParty(address _partyAddress) public onlyOwner {
        if (!parties[_partyAddress].isRegistered) {
            revert PartyNotRegistered(_partyAddress);
        }
        delete parties[_partyAddress];
        // Agreements involving this party might become invalid or require manual handling by owner
        emit PartyUnregistered(_partyAddress);
    }

    /**
     * @notice Defines a new type of state attribute that can be part of a party's state profile. Only owner can call.
     * @param _name The name of the attribute (e.g., "KYCLevel", "CreditScoreHash").
     * @param _description A brief description of the attribute.
     * @return The ID of the newly created state attribute.
     */
    function defineStateAttribute(string calldata _name, string calldata _description) public onlyOwner returns (uint) {
        uint attributeId = nextAttributeId++;
        stateAttributes[attributeId] = StateAttribute(attributeId, _name, _description);
        emit StateAttributeDefined(attributeId, _name);
        return attributeId;
    }

    /**
     * @notice Registrar updates the hashed value of a specific state attribute for a party.
     *         This implies the registrar has verified the underlying off-chain data corresponds to the hash.
     * @param _partyAddress The address of the party.
     * @param _attributeId The ID of the state attribute.
     * @param _valueHash The new cryptographic hash of the state value.
     */
    function updatePartyStateValueHash(address _partyAddress, uint _attributeId, bytes32 _valueHash) public onlyOwner {
        if (!parties[_partyAddress].isRegistered) revert PartyNotRegistered(_partyAddress);
        if (stateAttributes[_attributeId].id == 0) revert AttributeNotFound(_attributeId);

        partyStateValues[_partyAddress][_attributeId].attributeId = _attributeId;
        partyStateValues[_partyAddress][_attributeId].valueHash = _valueHash;
        // Verification timestamp is updated by verifyPartyStateAttribute
        emit PartyStateValueSubmitted(_partyAddress, _attributeId, _valueHash);
    }

    /**
     * @notice Registrar marks a party's state attribute hash as verified at the current time.
     *         This timestamp is crucial for bond validity checks.
     * @param _partyAddress The address of the party.
     * @param _attributeId The ID of the state attribute.
     */
    function verifyPartyStateAttribute(address _partyAddress, uint _attributeId) public onlyOwner {
        if (!parties[_partyAddress].isRegistered) revert PartyNotRegistered(_partyAddress);
        if (stateAttributes[_attributeId].id == 0) revert AttributeNotFound(_attributeId);
        // Check if a hash has been submitted for this attribute
        if (partyStateValues[_partyAddress][_attributeId].attributeId == 0) revert PartyStateValueNotSubmitted(_partyAddress, _attributeId);

        partyStateValues[_partyAddress][_attributeId].lastVerifiedTimestamp = block.timestamp;
        emit PartyStateVerified(_partyAddress, _attributeId, block.timestamp);
    }

    /**
     * @notice Designates which state attribute and its required hash value are essential for a specific escrow agreement's bond validity.
     *         This links the escrow's fate to the verifiable state of one of the parties. Only owner can call.
     * @param _agreementId The ID of the escrow agreement.
     * @param _attributeId The ID of the state attribute required for the bond.
     * @param _requiredValueHash The specific hash value the attribute must match for the bond to be valid.
     */
    function designateEscrowBondAttribute(uint _agreementId, uint _attributeId, bytes32 _requiredValueHash) public onlyOwner {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        if (agreement.id == 0) revert AgreementNotFound(_agreementId);
        if (stateAttributes[_attributeId].id == 0) revert AttributeNotFound(_attributeId);
        if (agreement.requiredStateAttributeId != 0) revert AgreementBondAttributeAlreadySet(_agreementId); // Only set once

        agreement.requiredStateAttributeId = _attributeId;
        agreement.requiredStateValueHash = _requiredValueHash;
        // Initial bond check could be triggered here or manually/later
    }


    /**
     * @notice Manually triggers a verification check for a specific escrow agreement's bond validity.
     *         The check compares the current verified state of the required party against the required state value hash.
     *         Updates the `isBondValid` status for the agreement. Only owner can call.
     * @param _agreementId The ID of the escrow agreement.
     */
    function triggerBondStateVerification(uint _agreementId) public onlyOwner {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        if (agreement.id == 0) revert AgreementNotFound(_agreementId);
        if (agreement.requiredStateAttributeId == 0) revert BondAttributeNotSet(_agreementId);

        // Assume Party A's state is checked for the bond (can be made more complex)
        address partyToCheck = agreement.partyA;
        uint attributeId = agreement.requiredStateAttributeId;
        bytes32 requiredHash = agreement.requiredStateValueHash;

        PartyStateValue storage partyAttrValue = partyStateValues[partyToCheck][attributeId];

        bool currentBondValidity = (partyAttrValue.attributeId != 0) &&
                                   (partyAttrValue.valueHash == requiredHash) &&
                                   (partyAttrValue.lastVerifiedTimestamp > 0); // Must have been verified at least once

        agreement.isBondValid = currentBondValidity;

        string memory statusMsg = currentBondValidity ? "Bond valid" : "Bond invalid";
        if (!currentBondValidity) {
             if (partyAttrValue.attributeId == 0) statusMsg = "Party state value not submitted";
             else if (partyAttrValue.valueHash != requiredHash) statusMsg = "Party state hash mismatch";
             else if (partyAttrValue.lastVerifiedTimestamp == 0) statusMsg = "Party state not verified by registrar";
        }

        agreementBondingStates[_agreementId] = BondingStateRecord(
            _agreementId,
            currentBondValidity,
            block.timestamp,
            statusMsg
        );

        emit EscrowBondStateChecked(_agreementId, currentBondValidity, statusMsg);
    }

    /**
     * @notice Registrar manually declares an agreement's bond as "decohered".
     *         This simulates a critical state change that invalidates the bond, potentially permanently or until reset.
     *         A decohered bond typically prevents successful escrow execution under normal terms.
     * @param _agreementId The ID of the escrow agreement.
     * @param _reason A string explaining the reason for decoherence.
     */
    function declareBondDecoherence(uint _agreementId, string calldata _reason) public onlyOwner {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        if (agreement.id == 0) revert AgreementNotFound(_agreementId);
        if (agreement.isDecohered) revert AgreementAlreadyInStatus(_agreementId, EscrowStatus.Cancelled); // Using Cancelled status enum value as a placeholder for already decohered check

        agreement.isBondValid = false; // Decoherence implies the bond is not valid
        agreement.isDecohered = true;
        agreement.decoherenceReason = _reason;

         agreementBondingStates[_agreementId] = BondingStateRecord(
            _agreementId,
            false, // Decohered bond is invalid
            block.timestamp,
            string(abi.encodePacked("Decohered: ", _reason))
        );

        emit EscrowBondDecohered(_agreementId, _reason);
    }

     /**
     * @notice Registrar resets the decoherence status of an agreement's bond.
     *         Allows the bond to potentially become valid again if the underlying state issues are resolved.
     * @param _agreementId The ID of the escrow agreement.
     */
    function resetBondDecoherence(uint _agreementId) public onlyOwner {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        if (agreement.id == 0) revert AgreementNotFound(_agreementId);
        if (!agreement.isDecohered) revert AgreementNotInStatus(_agreementId, EscrowStatus.Cancelled); // Using Cancelled status enum value as a placeholder for not decohered check

        agreement.isDecohered = false;
        agreement.decoherenceReason = "";
        agreement.isBondValid = false; // Bond must be re-verified to become valid after reset

        agreementBondingStates[_agreementId].isBondValid = false;
        agreementBondingStates[_agreementId].statusMessage = "Decoherence reset. Bond needs re-verification.";

        emit EscrowBondDecoherenceReset(_agreementId);
    }

    // --- Party Actions ---

    /**
     * @notice Allows a party to register themselves if self-registration is enabled.
     * @param _name The name of the party.
     */
    function registerSelf(string calldata _name) public {
        if (!partyRegistrationEnabled) revert PartyRegistrationDisabled();
        if (parties[msg.sender].isRegistered) revert PartyAlreadyRegistered(msg.sender);

        parties[msg.sender] = PartyProfile(msg.sender, _name, true);
        nextPartyId++; // Conceptual increment
        emit PartyRegistered(msg.sender, _name);
    }

    /**
     * @notice Allows a registered party to submit a hash of their state data for a specific attribute.
     *         This is typically a hash of off-chain data the registrar can later verify.
     * @param _attributeId The ID of the state attribute.
     * @param _valueHash The cryptographic hash of the party's state value.
     */
    function submitStateValueHash(uint _attributeId, bytes32 _valueHash) public {
        if (!parties[msg.sender].isRegistered) revert PartyNotRegistered(msg.sender);
        if (stateAttributes[_attributeId].id == 0) revert AttributeNotFound(_attributeId);

        partyStateValues[msg.sender][_attributeId].attributeId = _attributeId;
        partyStateValues[msg.sender][_attributeId].valueHash = _valueHash;
        // Timestamp is updated by registrar verification
        emit PartyStateValueSubmitted(msg.sender, _attributeId, _valueHash);
    }

     /**
     * @notice Allows a registered party to request the registrar verify their state attribute.
     *         This is an explicit request, the actual verification and timestamp update is done by the registrar.
     * @param _attributeId The ID of the state attribute the party wants verified.
     */
    function requestStateVerification(uint _attributeId) public {
        if (!parties[msg.sender].isRegistered) revert PartyNotRegistered(msg.sender);
        if (stateAttributes[_attributeId].id == 0) revert AttributeNotFound(_attributeId);
         if (partyStateValues[msg.sender][_attributeId].attributeId == 0) revert PartyStateValueNotSubmitted(msg.sender, _attributeId);

        // Event signifies the request, registrar acts on it off-chain and calls verifyPartyStateAttribute
        // No state change here, just signaling intent. Could add a request mapping if needed.
    }


    /**
     * @notice Party A initiates a new escrow agreement. Both parties must be registered.
     *         The required state attribute and its required value hash are set at creation.
     * @param _partyB The address of the counterparty.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to escrow.
     * @param _conditionalReleaseTimestamp A timestamp after which tokens can be released (0 if only state-bonded).
     * @param _requiredStateAttributeId The ID of the state attribute required for bond validity (must exist).
     * @param _requiredStateValueHash The specific hash value required for the bond.
     * @return The ID of the newly created agreement.
     */
    function createEscrowAgreement(
        address _partyB,
        address _tokenAddress,
        uint _amount,
        uint _conditionalReleaseTimestamp,
        uint _requiredStateAttributeId,
        bytes32 _requiredStateValueHash
    ) public returns (uint) {
        address partyA = msg.sender;
        if (!parties[partyA].isRegistered) revert PartyNotRegistered(partyA);
        if (!parties[_partyB].isRegistered) revert PartyNotRegistered(_partyB);
        if (partyA == _partyB) revert AgreementPartiesCannotBeSame();
        if (stateAttributes[_requiredStateAttributeId].id == 0) revert AttributeNotFound(_requiredStateAttributeId);

        uint agreementId = nextAgreementId++;
        escrowAgreements[agreementId] = EscrowAgreement(
            agreementId,
            partyA,
            _partyB,
            _tokenAddress,
            _amount,
            block.timestamp,
            _conditionalReleaseTimestamp,
            _requiredStateAttributeId,
            _requiredStateValueHash,
            false, // Bond initially invalid until checked
            false, // Not decohered initially
            "" , // No decoherence reason
            EscrowStatus.PendingApproval
        );

        partyAgreementIds[partyA].push(agreementId);
        partyAgreementIds[_partyB].push(agreementId);

        emit EscrowAgreementCreated(agreementId, partyA, _partyB, _tokenAddress, _amount);
        return agreementId;
    }

    /**
     * @notice Party B (the counterparty) approves an escrow agreement initiated by Party A.
     * @param _agreementId The ID of the agreement to approve.
     */
    function approveEscrowAgreement(uint _agreementId) public {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        if (agreement.id == 0) revert AgreementNotFound(_agreementId);
        if (msg.sender != agreement.partyB) revert NotAgreementParty(_agreementId);
        if (agreement.status != EscrowStatus.PendingApproval) revert AgreementNotInStatus(_agreementId, EscrowStatus.PendingApproval);

        agreement.status = EscrowStatus.Approved;
        emit EscrowAgreementApproved(_agreementId, msg.sender);
    }

     /**
     * @notice Parties deposit their share of tokens into the escrow contract for a specific agreement.
     *         Both parties must deposit the full amount before the agreement can proceed to execution.
     *         This simplified model requires each party to deposit the *full* amount for clarity, or could be split.
     *         Let's assume *each* party deposits the *full* amount as a condition, making the total escrowed 2 * amount.
     *         Alternatively, each party deposits half. Let's go with each party depositing half the total amount.
     * @param _agreementId The ID of the agreement.
     */
    function depositEscrowTokens(uint _agreementId) public nonReentrant {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        if (agreement.id == 0) revert AgreementNotFound(_agreementId);
        if (msg.sender != agreement.partyA && msg.sender != agreement.partyB) revert NotAgreementParty(_agreementId);
        if (agreement.status != EscrowStatus.Approved) revert AgreementNotInStatus(_agreementId, EscrowStatus.Approved);

        // Prevent depositing multiple times? Assume each party deposits once.
        // A more robust contract would track individual deposits.
        // For simplicity here, let's just move to Deposited status after *any* deposit call
        // and assume an off-chain check or a more complex on-chain state tracking exists.
        // Simpler approach: Allow multiple deposits, check total balance later.
        // Let's make it simpler: Allow *either* party to trigger deposit *after* approval,
        // but require the *total* balance held by the contract for this agreement ID
        // to be >= 2 * agreement.amount for execution. Deposit can be partial.

        uint amountToTransfer = agreement.amount; // Assume each party contributes 'amount'
        IERC20 token = IERC20(agreement.tokenAddress);

        uint callerBalance = token.balanceOf(msg.sender);
        if (callerBalance < amountToTransfer) revert NotEnoughBalance(agreement.tokenAddress, amountToTransfer);

        bool success = token.transferFrom(msg.sender, address(this), amountToTransfer);
        if (!success) revert TransferFailed(agreement.tokenAddress, address(this), amountToTransfer);

        // Note: We don't change status to Deposited here, because both need to deposit.
        // The check happens before execution.
        emit EscrowTokensDeposited(_agreementId, msg.sender, amountToTransfer);

        // We could track which party deposited using a mapping: mapping(uint => mapping(address => bool)) depositReceived;
        // For this example, we'll rely on total balance check during execution.
    }

    /**
     * @notice Allows parties or the registrar to cancel an escrow agreement before execution.
     * @param _agreementId The ID of the agreement to cancel.
     */
    function cancelEscrowAgreement(uint _agreementId) public nonReentrant {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        if (agreement.id == 0) revert AgreementNotFound(_agreementId);
        if (msg.sender != owner() && msg.sender != agreement.partyA && msg.sender != agreement.partyB) revert NotAgreementParty(_agreementId);
        if (agreement.status == EscrowStatus.Executed || agreement.status == EscrowStatus.Cancelled) {
             revert AgreementAlreadyInStatus(_agreementId, agreement.status);
        }

        agreement.status = EscrowStatus.Cancelled;

        // Return any deposited tokens
        IERC20 token = IERC20(agreement.tokenAddress);
        uint contractBalance = token.balanceOf(address(this));
        if (contractBalance > 0) {
             // This is simplified. A real contract needs to track who deposited how much.
             // Here, we'll just send the total balance held for this agreement ID back, assuming equal split
             // or handling by parties off-chain.
             // A better approach: track deposits per party per agreement.
             // Simple split: give half back to A, half to B if enough balance
             // This is a simplification for function count, a real contract would need more state.
             uint amountToReturn = contractBalance / 2; // Simplified split
             if (amountToReturn > 0) {
                 bool successA = token.transfer(agreement.partyA, amountToReturn);
                 bool successB = token.transfer(agreement.partyB, amountToReturn);
                 // Handle potential failures (e.g., log, leave funds in contract for owner)
                 require(successA && successB, "Token refund failed"); // Simplified failure handling
             }
        }

        emit EscrowCancelled(_agreementId);
    }

    // --- Escrow Execution & State Bonding Logic ---

    /**
     * @notice Attempts to execute an escrow agreement.
     *         Requires the agreement to be approved, tokens deposited, bond to be valid (not decohered and passing check),
     *         and conditional release time (if set) reached.
     *         Transfers tokens from the contract to Party B upon success.
     * @param _agreementId The ID of the agreement to execute.
     */
    function attemptEscrowExecution(uint _agreementId) public nonReentrant {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        if (agreement.id == 0) revert AgreementNotFound(_agreementId);
        if (agreement.status != EscrowStatus.Approved && agreement.status != EscrowStatus.Deposited) {
             // Allow execution if status is Approved or Deposited (assuming deposit doesn't change status automatically)
             revert AgreementNotInStatus(_agreementId, EscrowStatus.Approved); // Or Deposited
        }
        if (msg.sender != agreement.partyA && msg.sender != agreement.partyB && msg.sender != owner()) revert NotAgreementParty(_agreementId); // Either party or owner can trigger

        // Check deposit status
        IERC20 token = IERC20(agreement.tokenAddress);
        uint requiredTotalDeposit = agreement.amount * 2; // Based on simplified deposit logic above
        if (token.balanceOf(address(this)) < requiredTotalDeposit) {
            revert NotEnoughBalance(agreement.tokenAddress, requiredTotalDeposit);
        }
         agreement.status = EscrowStatus.Deposited; // Update status once deposit is sufficient (simplified)


        // Check release timestamp (if applicable)
        if (agreement.conditionalReleaseTimestamp > 0 && block.timestamp < agreement.conditionalReleaseTimestamp) {
            revert ReleaseTimeNotReached(_agreementId);
        }

        // --- Bond Validity Check ---
        // Re-check bond validity immediately before execution, unless already decohered
        if (agreement.isDecohered) {
            revert BondDecohered(_agreementId);
        }

        // Trigger a fresh bond state verification check
        // This repeats logic from triggerBondStateVerification but is crucial at execution time
        address partyToCheck = agreement.partyA; // Assume Party A's state is checked for bond
        uint attributeId = agreement.requiredStateAttributeId;
        bytes32 requiredHash = agreement.requiredStateValueHash;

        if (attributeId == 0) revert BondAttributeNotSet(_agreementId); // Should have been set at creation/designation

        PartyStateValue storage partyAttrValue = partyStateValues[partyToCheck][attributeId];

        bool currentBondValidity = (partyAttrValue.attributeId != 0) &&
                                   (partyAttrValue.valueHash == requiredHash) &&
                                   (partyAttrValue.lastVerifiedTimestamp > 0);

        agreement.isBondValid = currentBondValidity; // Update state in agreement struct

        if (!currentBondValidity) {
            string memory statusMsg = "Bond invalid at execution attempt";
            if (partyAttrValue.attributeId == 0) statusMsg = "Party state value not submitted for bond check";
             else if (partyAttrValue.valueHash != requiredHash) statusMsg = "Party state hash mismatch for bond check";
             else if (partyAttrValue.lastVerifiedTimestamp == 0) statusMsg = "Party state not verified by registrar for bond check";

            agreementBondingStates[_agreementId] = BondingStateRecord(
                _agreementId,
                false,
                block.timestamp,
                statusMsg
            );
            emit EscrowBondStateChecked(_agreementId, false, statusMsg);
            revert BondInvalid(_agreementId);
        }
        // --- End Bond Validity Check ---

        // If all checks pass: Bond is valid, not decohered, time is right, tokens deposited
        agreement.status = EscrowStatus.Executed;

        // Transfer the total amount (2 * agreement.amount in this model) to Party B
        uint totalAmountToTransfer = token.balanceOf(address(this)); // Transfer whatever is held for this agreement
        bool success = token.transfer(agreement.partyB, totalAmountToTransfer);
        if (!success) revert TransferFailed(agreement.tokenAddress, agreement.partyB, totalAmountToTransfer);

        emit EscrowExecuted(_agreementId);
    }


    // --- Query Functions (View) ---

    /**
     * @notice Gets the profile details for a registered party.
     * @param _partyAddress The address of the party.
     * @return PartyProfile struct containing details.
     */
    function getPartyProfile(address _partyAddress) public view returns (PartyProfile memory) {
        return parties[_partyAddress];
    }

    /**
     * @notice Gets the state value hash and verification timestamp for a specific party's attribute.
     * @param _partyAddress The address of the party.
     * @param _attributeId The ID of the state attribute.
     * @return PartyStateValue struct containing hash and timestamp.
     */
    function getPartyStateValue(address _partyAddress, uint _attributeId) public view returns (PartyStateValue memory) {
        return partyStateValues[_partyAddress][_attributeId];
    }

    /**
     * @notice Gets the definition of a state attribute type.
     * @param _attributeId The ID of the state attribute.
     * @return StateAttribute struct containing definition.
     */
    function getStateAttributeDefinition(uint _attributeId) public view returns (StateAttribute memory) {
        return stateAttributes[_attributeId];
    }

    /**
     * @notice Gets the details of an escrow agreement.
     * @param _agreementId The ID of the agreement.
     * @return EscrowAgreement struct containing details.
     */
    function getEscrowAgreement(uint _agreementId) public view returns (EscrowAgreement memory) {
        return escrowAgreements[_agreementId];
    }

    /**
     * @notice Gets the latest bonding state record for an agreement.
     * @param _agreementId The ID of the agreement.
     * @return BondingStateRecord struct containing bond validity, last check time, and status.
     */
    function getBondingStateRecord(uint _agreementId) public view returns (BondingStateRecord memory) {
        return agreementBondingStates[_agreementId];
    }

    /**
     * @notice Gets the total number of registered parties.
     * @return The count of registered parties (conceptual based on incrementing counter).
     */
    function getTotalRegisteredParties() public view returns (uint) {
        // This counter is conceptual. A real count requires iterating or a separate list.
        // Returning the counter for simplicity in this example.
        return nextPartyId;
    }

    /**
     * @notice Gets the total number of defined state attribute types.
     * @return The count of defined state attributes.
     */
    function getTotalStateAttributes() public view returns (uint) {
        return nextAttributeId - 1; // Adjust for starting from 1
    }

    /**
     * @notice Gets the total number of created escrow agreements.
     * @return The count of created agreements.
     */
    function getTotalEscrowAgreements() public view returns (uint) {
        return nextAgreementId - 1; // Adjust for starting from 1
    }

    /**
     * @notice Gets the list of agreement IDs a specific party is involved in.
     * @param _partyAddress The address of the party.
     * @return An array of agreement IDs.
     */
    function getAgreementsByParty(address _partyAddress) public view returns (uint[] memory) {
        return partyAgreementIds[_partyAddress];
    }

    /**
     * @notice Checks if an escrow agreement is currently ready for execution.
     *         Combines checks for status, deposit, time, and bond validity/decoherence.
     * @param _agreementId The ID of the agreement.
     * @return True if the agreement can be executed, false otherwise.
     */
    function canExecuteEscrow(uint _agreementId) public view returns (bool) {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        if (agreement.id == 0 || agreement.status == EscrowStatus.Executed || agreement.status == EscrowStatus.Cancelled) {
            return false;
        }

        // Check deposit status (simplified: check contract balance)
        IERC20 token = IERC20(agreement.tokenAddress);
        uint requiredTotalDeposit = agreement.amount * 2;
        if (token.balanceOf(address(this)) < requiredTotalDeposit) {
            return false;
        }

        // Check release timestamp
        if (agreement.conditionalReleaseTimestamp > 0 && block.timestamp < agreement.conditionalReleaseTimestamp) {
            return false;
        }

        // Check bond state
        if (agreement.isDecohered) {
            return false;
        }

        // Perform a simulated bond validity check (doesn't update state)
        if (agreement.requiredStateAttributeId == 0) return false; // Bond attribute not set

        address partyToCheck = agreement.partyA; // Assume Party A's state is checked
        uint attributeId = agreement.requiredStateAttributeId;
        bytes32 requiredHash = agreement.requiredStateValueHash;

        PartyStateValue storage partyAttrValue = partyStateValues[partyToCheck][attributeId];

        bool currentBondValidity = (partyAttrValue.attributeId != 0) &&
                                   (partyAttrValue.valueHash == requiredHash) &&
                                   (partyAttrValue.lastVerifiedTimestamp > 0);

        return currentBondValidity; // True only if bond is valid based on current state/verification
    }

    /**
     * @notice Checks if an address is a registered party.
     * @param _partyAddress The address to check.
     * @return True if the address is registered, false otherwise.
     */
    function isPartyRegistered(address _partyAddress) public view returns (bool) {
        return parties[_partyAddress].isRegistered;
    }

    // --- Additional Query/Helper Functions (>= 20 functions total now) ---

    /**
     * @notice Gets the current token balance held by the contract for a specific agreement ID.
     *         Note: This is the total balance of the token held by the contract.
     *         A more specific implementation would track balances per agreement.
     * @param _agreementId The ID of the agreement.
     * @return The balance of the token held by the contract.
     */
    function getEscrowBalance(uint _agreementId) public view returns (uint) {
         EscrowAgreement storage agreement = escrowAgreements[_agreementId];
         if (agreement.id == 0) return 0; // Agreement not found
         IERC20 token = IERC20(agreement.tokenAddress);
         // This is a simplification; ideally, track balance per agreement ID.
         // Returning the total balance of that token held by the contract.
         return token.balanceOf(address(this));
    }

    /**
     * @notice Gets the state attribute ID required for the bond of a specific agreement.
     * @param _agreementId The ID of the agreement.
     * @return The required state attribute ID, or 0 if not set.
     */
    function getRequiredBondAttributeForAgreement(uint _agreementId) public view returns (uint) {
         EscrowAgreement storage agreement = escrowAgrowments[_agreementId];
         if (agreement.id == 0) return 0;
         return agreement.requiredStateAttributeId;
    }

    /**
     * @notice Gets the required state value hash for the bond of a specific agreement.
     * @param _agreementId The ID of the agreement.
     * @return The required state value hash.
     */
    function getRequiredBondValueHashForAgreement(uint _agreementId) public view returns (bytes32) {
         EscrowAgreement storage agreement = escrowAgreements[_agreementId];
         if (agreement.id == 0) return bytes32(0);
         return agreement.requiredStateValueHash;
    }

    /**
     * @notice Checks the current bond validity status stored for an agreement.
     *         Note: This is the status from the *last* check (`triggerBondStateVerification`), not necessarily real-time.
     * @param _agreementId The ID of the agreement.
     * @return True if the bond is currently marked as valid, false otherwise.
     */
    function isBondValidForAgreement(uint _agreementId) public view returns (bool) {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        if (agreement.id == 0) return false;
        return agreement.isBondValid;
    }

    /**
     * @notice Checks the current decoherence status of an agreement's bond.
     * @param _agreementId The ID of the agreement.
     * @return True if the bond is currently marked as decohered, false otherwise.
     */
    function isAgreementDecohered(uint _agreementId) public view returns (bool) {
         EscrowAgreement storage agreement = escrowAgreements[_agreementId];
         if (agreement.id == 0) return false;
         return agreement.isDecohered;
    }

    /**
     * @notice Gets the addresses of Party A and Party B for an agreement.
     * @param _agreementId The ID of the agreement.
     * @return partyA The address of the initiator.
     * @return partyB The address of the counterparty.
     */
    function getAgreementParties(uint _agreementId) public view returns (address partyA, address partyB) {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        // Returning zero addresses if not found, avoids reverting in view function
        return (agreement.partyA, agreement.partyB);
    }

     /**
     * @notice Gets the token address and amount for an agreement.
     * @param _agreementId The ID of the agreement.
     * @return tokenAddress The address of the escrowed token.
     * @return amount The agreed amount for the escrow.
     */
    function getAgreementTokenAndAmount(uint _agreementId) public view returns (address tokenAddress, uint amount) {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
         // Returning zero address/amount if not found
        return (agreement.tokenAddress, agreement.amount);
    }

     /**
     * @notice Gets the creation and conditional release timestamps for an agreement.
     * @param _agreementId The ID of the agreement.
     * @return creationTimestamp The timestamp when the agreement was created.
     * @return conditionalReleaseTimestamp The timestamp after which release is possible (0 if none).
     */
    function getAgreementTimestamps(uint _agreementId) public view returns (uint creationTimestamp, uint conditionalReleaseTimestamp) {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        // Returning zero timestamps if not found
        return (agreement.creationTimestamp, agreement.conditionalReleaseTimestamp);
    }

    /**
     * @notice Checks if an escrow agreement has been approved by Party B.
     * @param _agreementId The ID of the agreement.
     * @return True if the agreement status is Approved or later, false otherwise.
     */
    function isEscrowApproved(uint _agreementId) public view returns (bool) {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        return agreement.id != 0 && agreement.status >= EscrowStatus.Approved;
    }

    /**
     * @notice Checks if tokens have been sufficiently deposited for an agreement based on the simplified model.
     *         Checks if the contract holds at least 2 * agreement.amount of the token.
     * @param _agreementId The ID of the agreement.
     * @return True if enough tokens are deposited according to the simplified rule, false otherwise.
     */
    function isEscrowDeposited(uint _agreementId) public view returns (bool) {
        EscrowAgreement storage agreement = escrowAgreements[_agreementId];
        if (agreement.id == 0) return false;
         IERC20 token = IERC20(agreement.tokenAddress);
        uint requiredTotalDeposit = agreement.amount * 2;
        return token.balanceOf(address(this)) >= requiredTotalDeposit;
    }

     /**
     * @notice Allows the Registrar (owner) to enable or disable self-registration for parties.
     * @param _enabled True to enable, false to disable.
     */
    function setPartyRegistrationEnabled(bool _enabled) public onlyOwner {
        partyRegistrationEnabled = _enabled;
        emit PartyRegistrationEnabledSet(_enabled);
    }

    /**
     * @notice Checks if party self-registration is currently enabled.
     * @return True if self-registration is enabled, false otherwise.
     */
    function getPartyRegistrationEnabled() public view returns (bool) {
        return partyRegistrationEnabled;
    }

     // --- Internal/Private Helper Functions (Not counted in the 20+) ---
    // For example, internal functions to manage partyAgreementIds array (add/remove)


    // Fallback function to receive potential ETH if needed (not part of the SBRC concept, added for robustness)
    receive() external payable {}
    fallback() external payable {}
}
```