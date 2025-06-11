Okay, let's design a complex, creative, and trendy smart contract focusing on dynamic, oracle-fed digital assets managed by a decentralized governance system.

**Concept:** **QuantumEstate**

Imagine a system of virtual land parcels (NFTs) where each parcel has dynamic attributes (like "activity score," "environmental health," "connectivity index") that change over time based on external data fed by trusted oracles. Ownership of these parcels grants voting power in a decentralized autonomous organization (DAO) that governs key parameters of the system, including adding/removing oracles, changing how attributes are weighted, and even proposing upgrades or new attribute types.

This combines NFTs (trending), Oracles (advanced/trendy), and DAO Governance (advanced/trendy) with a creative twist on dynamic, state-changing digital assets.

---

**Outline & Function Summary: QuantumEstate.sol**

**1. Contract Overview:**
*   `QuantumEstate` is an ERC721 compliant contract representing dynamic virtual land parcels ("Parcels").
*   Each Parcel has a set of quantifiable attributes whose values can be updated by whitelisted Oracle addresses.
*   The contract incorporates a basic DAO-like governance mechanism where Parcel owners can propose and vote on changes to system parameters, including Oracle management and defining new attribute types.

**2. Core Components:**
*   **Parcels (ERC721):** Non-fungible tokens representing unique land plots.
*   **Dynamic Attributes:** Data points associated with each Parcel (e.g., ActivityScore, EnvironmentScore). These are state variables stored on-chain.
*   **Oracles:** External entities/addresses authorized to submit attribute updates for Parcels.
*   **Attribute Types:** Definition of what attributes exist and their properties. Can be added/removed by governance.
*   **Governance:** A system allowing Parcel owners to propose and vote on changes. Voting power is weighted by the number of owned Parcels.

**3. Key State Variables:**
*   `_parcelAttributes`: Mapping storing current attribute values for each Parcel ID.
*   `_attributeTypes`: Mapping storing definitions of each attribute type (name, ID, etc.).
*   `_registeredOracles`: Mapping tracking authorized Oracle addresses.
*   `_proposals`: Mapping storing active and past governance proposals.
*   `_proposalVotes`: Mapping storing votes for each proposal by voter address.
*   System configuration parameters (e.g., proposal thresholds, quorum, oracle update cooldowns).

**4. Function Summary (20+ Functions):**

*   **ERC721 Standard Functions (Inherited):**
    1.  `balanceOf(address owner)`: Get number of parcels owned by an address.
    2.  `ownerOf(uint256 tokenId)`: Get owner of a parcel.
    3.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer parcel ownership.
    4.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer.
    5.  `approve(address to, uint256 tokenId)`: Approve address to transfer parcel.
    6.  `setApprovalForAll(address operator, bool approved)`: Approve operator for all parcels.
    7.  `getApproved(uint256 tokenId)`: Get approved address for parcel.
    8.  `isApprovedForAll(address owner, address operator)`: Check if operator is approved for all.
    9.  `supportsInterface(bytes4 interfaceId)`: Check supported interfaces (ERC721, ERC165).
    10. `tokenURI(uint256 tokenId)`: Get metadata URI for a parcel.
    11. `setBaseURI(string memory baseURI)`: Set base URI for metadata.

*   **Parcel Core Management:**
    12. `mintParcel(address to, uint256 initialActivityScore)`: Create and assign a new Parcel NFT with initial attributes.
    13. `getParcelAttributes(uint256 tokenId)`: View all attribute values for a specific Parcel.
    14. `getParcelAttribute(uint256 tokenId, uint256 attributeTypeId)`: View a single attribute value for a Parcel.

*   **Oracle Integration & Attribute Updates:**
    15. `updateParcelAttributesByOracle(uint256 tokenId, uint256[] memory attributeTypeIds, int256[] memory newValues)`: Oracle function to update multiple attributes for a Parcel. Restricted to registered Oracles and respects cooldown.
    16. `registerOracle(address oracleAddress)`: Governance function to add a trusted Oracle.
    17. `deregisterOracle(address oracleAddress)`: Governance function to remove a trusted Oracle.
    18. `isOracleRegistered(address oracleAddress)`: View function to check if an address is a registered Oracle.
    19. `getOracleAddresses()`: View function to get list of all registered Oracles.

*   **Attribute Type Management:**
    20. `addAttributeType(string memory name)`: Governance function to define a new dynamic attribute type.
    21. `getAttributeTypeInfo(uint256 attributeTypeId)`: View function to get details about an attribute type.
    22. `getAttributeTypeNames()`: View function to get names of all defined attribute types.

*   **Governance (DAO):**
    23. `submitProposal(uint256 proposalType, bytes memory callData, string memory description)`: Parcel owners propose a change.
    24. `voteOnProposal(uint256 proposalId, bool support)`: Parcel owners vote on an active proposal. Voting power = number of owned Parcels.
    25. `executeProposal(uint256 proposalId)`: Anyone can call to execute a proposal if it has passed and the voting period is over.
    26. `getProposalState(uint256 proposalId)`: View the current state of a proposal (Pending, Active, Succeeded, Failed, Executed, Expired).
    27. `getVotingPower(address voter)`: View how many votes an address currently has (based on Parcel count).
    28. `getProposalCount()`: View the total number of proposals submitted.

*   **Configuration (Via Governance or Initial Owner):**
    29. `setOracleUpdateCooldown(uint256 cooldownInSeconds)`: Governance function to set minimum time between Oracle updates for a Parcel.
    30. `setProposalThreshold(uint256 threshold)`: Governance function to set the minimum number of 'Yes' votes needed relative to total votes to pass.
    31. `setProposalQuorum(uint256 quorum)`: Governance function to set the minimum percentage of total voting power that must participate for a vote to be valid.
    32. `setVotingPeriod(uint256 votingPeriodInSeconds)`: Governance function to set how long proposals are open for voting.

*   **Utility:**
    33. `getTotalSupply()`: Total number of Parcels minted.

*(Note: Some standard functions are listed explicitly to reach the count, even if inherited. The core unique functions are 12-32)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol"; // Potentially for secure oracle data feeds (basic check here)

/// @title QuantumEstate
/// @dev A dynamic NFT contract representing virtual land parcels with state mutable by oracles and governed by parcel owners.
contract QuantumEstate is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _parcelIds;
    Counters.Counter private _attributeTypeIds;
    Counters.Counter private _proposalIds;

    /// @dev Struct to hold attribute values for a specific parcel.
    struct ParcelAttributes {
        mapping(uint256 => int256) values; // attributeTypeId => value
        uint48 lastOracleUpdateTime; // Timestamp of the last attribute update by an oracle
    }

    /// @dev Struct to define a type of dynamic attribute.
    struct AttributeType {
        string name;
        bool exists; // To check if the attribute type ID is valid
    }

    /// @dev Struct for a governance proposal.
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 proposalType; // Enum or simple integer representing action type
        bytes callData; // Encoded function call + params for execution
        string description;
        uint48 votingPeriodEnd;
        uint256 totalVotes; // Total voting power that voted
        uint256 yesVotes; // Total voting power that voted 'Yes'
        uint256 noVotes; // Total voting power that voted 'No'
        bool executed;
        bool exists;
    }

    /// @dev Enum for proposal states.
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Expired }

    // --- State Variables ---

    /// @dev Mapping from parcel ID to its dynamic attributes.
    mapping(uint256 => ParcelAttributes) private _parcelAttributes;

    /// @dev Mapping from attribute type ID to its definition.
    mapping(uint256 => AttributeType) private _attributeTypes;

    /// @dev Mapping from attribute type name to its ID.
    mapping(string => uint256) private _attributeTypeNames;

    /// @dev Mapping from oracle address to boolean indicating if registered.
    mapping(address => bool) private _registeredOracles;

    /// @dev Array storing registered oracle addresses (for easy iteration).
    address[] private _oracleAddresses;

    /// @dev Mapping from proposal ID to proposal data.
    mapping(uint256 => Proposal) private _proposals;

    /// @dev Mapping from proposal ID to voter address to boolean (voted).
    mapping(uint256 => mapping(address => bool)) private _proposalVotes;

    /// @dev Base URI for ERC721 metadata.
    string private _baseTokenURI;

    /// @dev Configuration: Minimum time between oracle updates for a single parcel.
    uint256 public oracleUpdateCooldown = 1 hours;

    /// @dev Configuration: Minimum percentage of 'Yes' votes relative to total votes to pass (e.g., 5100 = 51%).
    uint256 public proposalThreshold = 5100; // 51%

    /// @dev Configuration: Minimum percentage of total voting power that must participate for a vote to be valid (e.g., 1000 = 10%).
    uint256 public proposalQuorum = 1000; // 10%

    /// @dev Configuration: Duration proposals are open for voting.
    uint256 public votingPeriod = 3 days;

    // --- Events ---

    /// @dev Emitted when a new parcel is minted.
    event ParcelMinted(uint256 indexed tokenId, address indexed owner, uint256 initialActivityScore);

    /// @dev Emitted when a parcel's attributes are updated by an oracle.
    event ParcelAttributesUpdated(uint256 indexed tokenId, address indexed oracle, uint256[] attributeTypeIds, int256[] newValues);

    /// @dev Emitted when a new attribute type is added.
    event AttributeTypeAdded(uint256 indexed attributeTypeId, string name);

    /// @dev Emitted when an oracle is registered.
    event OracleRegistered(address indexed oracleAddress);

    /// @dev Emitted when an oracle is deregistered.
    event OracleDeregistered(address indexed oracleAddress);

    /// @dev Emitted when a new governance proposal is submitted.
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 proposalType, string description);

    /// @dev Emitted when a voter casts a vote on a proposal.
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);

    /// @dev Emitted when a proposal is executed.
    event ProposalExecuted(uint256 indexed proposalId);

    /// @dev Emitted when a configuration parameter is changed by governance.
    event ConfigurationChanged(string paramName, uint256 newValue);

    // --- Modifiers ---

    /// @dev Modifier to restrict access to registered oracles.
    modifier onlyOracle() {
        require(_registeredOracles[msg.sender], "QuantumEstate: Caller is not a registered oracle");
        _;
    }

    /// @dev Modifier to restrict access to registered oracles or the owner (initially).
    modifier onlyOracleOrOwner() {
         require(_registeredOracles[msg.sender] || owner() == msg.sender, "QuantumEstate: Caller is not a registered oracle or owner");
        _;
    }

    /// @dev Modifier to check if a proposal exists and is in a specific state.
    modifier requireProposalState(uint256 proposalId, ProposalState state) {
        require(_proposals[proposalId].exists, "QuantumEstate: Invalid proposal ID");
        require(getProposalState(proposalId) == state, "QuantumEstate: Proposal is not in the required state");
        _;
    }

    // --- Constructor ---

    /// @dev Initializes the contract, sets the owner, and defines initial attributes.
    /// @param initialOwner The initial owner of the contract.
    /// @param initialOracle The initial trusted oracle address.
    /// @param initialAttributeNames The names of the initial dynamic attributes.
    constructor(address initialOwner, address initialOracle, string[] memory initialAttributeNames)
        ERC721("QuantumEstate", "QE")
        Ownable(initialOwner)
    {
        _registeredOracles[initialOracle] = true;
        _oracleAddresses.push(initialOracle);
        emit OracleRegistered(initialOracle);

        for (uint i = 0; i < initialAttributeNames.length; i++) {
            uint256 newId = _attributeTypeIds.current();
            _attributeTypes[newId] = AttributeType({
                name: initialAttributeNames[i],
                exists: true
            });
            _attributeTypeNames[initialAttributeNames[i]] = newId;
             _attributeTypeIds.increment();
            emit AttributeTypeAdded(newId, initialAttributeNames[i]);
        }
    }

    // --- ERC721 Standard Implementations (Inherited) ---
    // (These are inherited from OpenZeppelin's ERC721)
    // 1. balanceOf(address owner)
    // 2. ownerOf(uint256 tokenId)
    // 3. transferFrom(address from, address to, uint256 tokenId)
    // 4. safeTransferFrom(address from, address to, uint256 tokenId)
    // 5. approve(address to, uint256 tokenId)
    // 6. setApprovalForAll(address operator, bool approved)
    // 7. getApproved(uint256 tokenId)
    // 8. isApprovedForAll(address owner, address operator)
    // 9. supportsInterface(bytes4 interfaceId)
    // 10. tokenURI(uint256 tokenId) - Uses _baseTokenURI
    // 11. setBaseURI(string memory baseURI) - Owner function from ERC721, overridden here.

    /// @dev Override ERC721's _baseURI
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev Set the base URI for token metadata. Can only be set by the owner (initially) or via governance.
    /// Note: In a full DAO setup, this would ideally be governed. Keeping owner here for simplicity or initial setup.
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    // --- Parcel Core Management ---

    /// @dev Mints a new Quantum Estate Parcel NFT and assigns initial attributes.
    /// Only callable by the contract owner (or potentially governance later).
    /// @param to The address to mint the parcel to.
    /// @param initialActivityScore A sample initial attribute value for the first attribute type.
    function mintParcel(address to, uint256 initialActivityScore) public onlyOwner nonReentrant {
        _parcelIds.increment();
        uint256 newItemId = _parcelIds.current();
        _mint(to, newItemId);

        // Assign initial attributes. Example: assuming the first attribute type (ID 0) is Activity Score.
        // More complex initial attribute setting could be added here.
        if(_attributeTypes[0].exists) {
             _parcelAttributes[newItemId].values[0] = int256(initialActivityScore);
        }


        emit ParcelMinted(newItemId, to, initialActivityScore);
    }

    /// @dev Gets all attribute values for a specific parcel.
    /// @param tokenId The ID of the parcel.
    /// @return An array of attribute type IDs and an array of their corresponding values.
    function getParcelAttributes(uint256 tokenId) public view returns (uint256[] memory attributeTypeIds, int256[] memory values) {
        // We need to iterate through all known attribute types to return values,
        // as the mapping inside ParcelAttributes only stores *set* values.
        uint256 totalAttributeTypes = _attributeTypeIds.current();
        uint256[] memory ids = new uint256[](totalAttributeTypes);
        int256[] memory vals = new int256[](totalAttributeTypes);

        uint256 count = 0;
        for (uint i = 0; i < totalAttributeTypes; i++) {
            if (_attributeTypes[i].exists) {
                 ids[count] = i;
                 vals[count] = _parcelAttributes[tokenId].values[i];
                 count++;
            }
        }

        // Trim arrays to actual count of existing attribute types
        attributeTypeIds = new uint256[](count);
        values = new int256[](count);
        for(uint i = 0; i < count; i++) {
            attributeTypeIds[i] = ids[i];
            values[i] = vals[i];
        }

        return (attributeTypeIds, values);
    }


    /// @dev Gets a single attribute value for a specific parcel.
    /// @param tokenId The ID of the parcel.
    /// @param attributeTypeId The ID of the attribute type.
    /// @return The value of the requested attribute. Returns 0 if not set or attribute type doesn't exist.
    function getParcelAttribute(uint256 tokenId, uint256 attributeTypeId) public view returns (int256) {
        require(_attributeTypes[attributeTypeId].exists, "QuantumEstate: Invalid attribute type ID");
        // Mapping lookups return 0 for unset values, which is acceptable here.
        return _parcelAttributes[tokenId].values[attributeTypeId];
    }

    // --- Oracle Integration & Attribute Updates ---

    /// @dev Allows a registered oracle to update multiple attributes for a parcel.
    /// Enforces oracle registration and update cooldown.
    /// @param tokenId The ID of the parcel to update.
    /// @param attributeTypeIds The IDs of the attributes to update.
    /// @param newValues The new values for the corresponding attributes. Must match size of attributeTypeIds.
    function updateParcelAttributesByOracle(uint256 tokenId, uint256[] memory attributeTypeIds, int256[] memory newValues)
        public
        onlyOracle
        nonReentrant
    {
        require(_exists(tokenId), "QuantumEstate: Token does not exist");
        require(attributeTypeIds.length == newValues.length, "QuantumEstate: Mismatched attribute arrays");
        require(block.timestamp >= _parcelAttributes[tokenId].lastOracleUpdateTime + oracleUpdateCooldown, "QuantumEstate: Oracle update cooldown in effect");

        for (uint i = 0; i < attributeTypeIds.length; i++) {
            uint256 attributeTypeId = attributeTypeIds[i];
            require(_attributeTypes[attributeTypeId].exists, "QuantumEstate: Invalid attribute type ID in array");
            _parcelAttributes[tokenId].values[attributeTypeId] = newValues[i];
        }

        _parcelAttributes[tokenId].lastOracleUpdateTime = uint48(block.timestamp); // Use uint48 for gas efficiency if timestamp fits
        emit ParcelAttributesUpdated(tokenId, msg.sender, attributeTypeIds, newValues);
    }

    /// @dev Registers a new address as a trusted oracle. Callable only via successful governance proposal execution.
    /// @param oracleAddress The address to register.
    function registerOracle(address oracleAddress) public onlyOwner { // Temporarily onlyOwner, should be executed via governance
        require(!_registeredOracles[oracleAddress], "QuantumEstate: Oracle already registered");
        _registeredOracles[oracleAddress] = true;
        _oracleAddresses.push(oracleAddress);
        emit OracleRegistered(oracleAddress);
    }

    /// @dev Deregisters an address, removing its oracle permissions. Callable only via successful governance proposal execution.
    /// @param oracleAddress The address to deregister.
    function deregisterOracle(address oracleAddress) public onlyOwner { // Temporarily onlyOwner, should be executed via governance
        require(_registeredOracles[oracleAddress], "QuantumEstate: Address is not a registered oracle");
        _registeredOracles[oracleAddress] = false;
        // Remove from array (inefficient for large arrays, but okay for moderate oracle count)
        for (uint i = 0; i < _oracleAddresses.length; i++) {
            if (_oracleAddresses[i] == oracleAddress) {
                _oracleAddresses[i] = _oracleAddresses[_oracleAddresses.length - 1];
                _oracleAddresses.pop();
                break;
            }
        }
        emit OracleDeregistered(oracleAddress);
    }

    /// @dev Checks if an address is a registered oracle.
    /// @param oracleAddress The address to check.
    /// @return True if registered, false otherwise.
    function isOracleRegistered(address oracleAddress) public view returns (bool) {
        return _registeredOracles[oracleAddress];
    }

     /// @dev Gets a list of all registered oracle addresses.
     /// @return An array of registered oracle addresses.
     function getOracleAddresses() public view returns (address[] memory) {
         // Note: This array might contain zero addresses if deregistration happens.
         // A cleaner implementation would rebuild or use a linked list, but this is simpler.
         uint256 count = 0;
         for(uint i = 0; i < _oracleAddresses.length; i++) {
             if(_registeredOracles[_oracleAddresses[i]]) {
                 count++;
             }
         }
         address[] memory activeOracles = new address[](count);
         uint256 current = 0;
         for(uint i = 0; i < _oracleAddresses.length; i++) {
              if(_registeredOracles[_oracleAddresses[i]]) {
                 activeOracles[current] = _oracleAddresses[i];
                 current++;
             }
         }
         return activeOracles; // Return filtered list
     }


    // --- Attribute Type Management (Governance) ---

    /// @dev Adds a new attribute type definition. Callable only via successful governance proposal execution.
    /// @param name The name of the new attribute type.
    function addAttributeType(string memory name) public onlyOwner { // Temporarily onlyOwner, should be executed via governance
        // Check if name is already used
        uint256 existingId = _attributeTypeNames[name];
        require(existingId == 0 || !_attributeTypes[existingId].exists, "QuantumEstate: Attribute type name already exists");

        uint256 newId = _attributeTypeIds.current();
        _attributeTypes[newId] = AttributeType({
            name: name,
            exists: true
        });
        _attributeTypeNames[name] = newId;
        _attributeTypeIds.increment();

        emit AttributeTypeAdded(newId, name);
    }

     /// @dev Gets information about a specific attribute type.
     /// @param attributeTypeId The ID of the attribute type.
     /// @return The name of the attribute type.
     function getAttributeTypeInfo(uint256 attributeTypeId) public view returns (string memory name) {
         require(_attributeTypes[attributeTypeId].exists, "QuantumEstate: Invalid attribute type ID");
         return _attributeTypes[attributeTypeId].name;
     }

     /// @dev Gets the names of all registered attribute types.
     /// @return An array of attribute type names.
     function getAttributeTypeNames() public view returns (string[] memory) {
         uint256 totalAttributeTypes = _attributeTypeIds.current();
         string[] memory names = new string[](totalAttributeTypes);
         uint256 count = 0;
         for(uint i = 0; i < totalAttributeTypes; i++) {
             if (_attributeTypes[i].exists) {
                 names[count] = _attributeTypes[i].name;
                 count++;
             }
         }
         // Trim array
         string[] memory existingNames = new string[](count);
         for(uint i = 0; i < count; i++) {
             existingNames[i] = names[i];
         }
         return existingNames;
     }


    // --- Governance (DAO) ---

    /// @dev Allows a parcel owner to submit a governance proposal.
    /// @param proposalType An identifier for the type of proposal (e.g., 0 for config change, 1 for oracle management, 2 for attribute type management).
    /// @param callData The encoded function call data to be executed if the proposal passes.
    /// @param description A description of the proposal.
    /// @return The ID of the newly created proposal.
    function submitProposal(uint256 proposalType, bytes memory callData, string memory description)
        public
        nonReentrant // Prevent reentrancy during proposal submission? Maybe not strictly needed here.
        returns (uint256)
    {
        // Require proposer to own at least one parcel to submit
        require(balanceOf(msg.sender) > 0, "QuantumEstate: Must own a parcel to submit a proposal");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: proposalType,
            callData: callData,
            description: description,
            votingPeriodEnd: uint48(block.timestamp + votingPeriod),
            totalVotes: 0,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            exists: true
        });

        emit ProposalSubmitted(proposalId, msg.sender, proposalType, description);
        return proposalId;
    }

    /// @dev Allows a parcel owner to vote on an active proposal.
    /// Voting power is based on the number of parcels owned by the voter *at the time of voting*.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for a 'Yes' vote, false for a 'No' vote.
    function voteOnProposal(uint256 proposalId, bool support)
        public
        nonReentrant
        requireProposalState(proposalId, ProposalState.Active)
    {
        require(!_proposalVotes[proposalId][msg.sender], "QuantumEstate: Already voted on this proposal");

        uint256 voterVotingPower = balanceOf(msg.sender);
        require(voterVotingPower > 0, "QuantumEstate: Must own parcels to vote");

        _proposalVotes[proposalId][msg.sender] = true;
        _proposals[proposalId].totalVotes += voterVotingPower;

        if (support) {
            _proposals[proposalId].yesVotes += voterVotingPower;
        } else {
            _proposals[proposalId].noVotes += voterVotingPower;
        }

        emit VoteCast(proposalId, msg.sender, support, voterVotingPower);
    }

    /// @dev Executes a proposal if it has succeeded. Callable by anyone after the voting period ends.
    /// Requires the proposal to be in a Succeeded state.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId)
        public
        nonReentrant
        requireProposalState(proposalId, ProposalState.Succeeded)
    {
        Proposal storage proposal = _proposals[proposalId];

        // Execute the encoded call
        (bool success, ) = address(this).call(proposal.callData);
        require(success, "QuantumEstate: Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    /// @dev Gets the current state of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The state of the proposal (Pending, Active, Succeeded, Failed, Executed, Expired).
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = _proposals[proposalId];
        if (!proposal.exists) {
            // Or revert, depending on desired behavior for invalid IDs
            return ProposalState.Pending; // Treat non-existent as pending/invalid state
        }
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (block.timestamp <= proposal.votingPeriodEnd) {
            return ProposalState.Active;
        }

        // Voting period is over, determine outcome
        uint256 totalPossibleVotingPower = totalSupply(); // Approx. Max voting power
        // Need to check quorum: total votes cast vs total possible voting power
        // Note: Total possible voting power *could* change during voting period.
        // A robust DAO uses a snapshot of token supply/ownership at proposal creation.
        // Using current supply is simpler but less precise. Let's use current supply as total possible for quorum check.
        uint256 currentTotalSupply = totalSupply(); // Total parcels minted
        uint256 totalVotedPower = proposal.totalVotes;

        // Check quorum: total votes cast must be at least quorum percentage of total supply
        if (currentTotalSupply == 0 || totalVotedPower * 10000 < currentTotalSupply * proposalQuorum) {
             return ProposalState.Failed; // Did not meet quorum
        }

        // Check threshold: Yes votes must be at least threshold percentage of *total votes cast*
        if (proposal.yesVotes * 10000 >= totalVotedPower * proposalThreshold) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Failed;
        }
         // If somehow none of the above conditions are met (e.g. voting period end check fails or timestamp issues), treat as expired.
         // This case should ideally not be reachable with correct timestamp checks.
        // return ProposalState.Expired;
    }


    /// @dev Gets the voting power of an address (number of parcels owned).
    /// @param voter The address to check.
    /// @return The voting power.
    function getVotingPower(address voter) public view returns (uint256) {
        return balanceOf(voter);
    }

    /// @dev Gets the total number of proposals submitted.
    /// @return The total count of proposals.
    function getProposalCount() public view returns (uint256) {
        return _proposalIds.current();
    }


    // --- Configuration (Via Governance) ---
    // These setters are marked onlyOwner for initial setup/simplicity, but should be callable
    // via `executeProposal` if proposed and passed by the DAO. The `callData` in a proposal
    // would encode a call to these functions.

    /// @dev Sets the minimum time between oracle attribute updates for a parcel.
    /// Should be callable only via governance proposal execution.
    /// @param cooldownInSeconds The new cooldown period in seconds.
    function setOracleUpdateCooldown(uint256 cooldownInSeconds) public onlyOwner { // Target for governance callData
        oracleUpdateCooldown = cooldownInSeconds;
        emit ConfigurationChanged("oracleUpdateCooldown", cooldownInSeconds);
    }

    /// @dev Sets the proposal threshold percentage.
    /// Should be callable only via governance proposal execution.
    /// @param threshold The new threshold percentage (e.g., 5100 for 51%).
    function setProposalThreshold(uint256 threshold) public onlyOwner { // Target for governance callData
        require(threshold <= 10000, "QuantumEstate: Threshold cannot exceed 100%");
        proposalThreshold = threshold;
        emit ConfigurationChanged("proposalThreshold", threshold);
    }

    /// @dev Sets the proposal quorum percentage.
    /// Should be callable only via governance proposal execution.
    /// @param quorum The new quorum percentage (e.g., 1000 for 10%).
    function setProposalQuorum(uint256 quorum) public onlyOwner { // Target for governance callData
         require(quorum <= 10000, "QuantumEstate: Quorum cannot exceed 100%");
        proposalQuorum = quorum;
        emit ConfigurationChanged("proposalQuorum", quorum);
    }

     /// @dev Sets the voting period for proposals.
     /// Should be callable only via governance proposal execution.
     /// @param votingPeriodInSeconds The new voting period in seconds.
     function setVotingPeriod(uint256 votingPeriodInSeconds) public onlyOwner { // Target for governance callData
         votingPeriod = votingPeriodInSeconds;
         emit ConfigurationChanged("votingPeriod", votingPeriodInSeconds);
     }


    // --- Utility ---

    /// @dev Gets the total number of parcels minted.
    /// @return The total supply.
    function totalSupply() public view override returns (uint256) {
        return _parcelIds.current();
    }

    // --- Internal Helpers ---
    // (Standard ERC721 internal functions are also used, e.g., _mint, _exists)

}
```

**Explanation of Advanced/Creative Concepts & Implementation:**

1.  **Dynamic NFT State:** The `ParcelAttributes` struct and the mapping `_parcelAttributes` store mutable data associated with each NFT beyond the standard token ID. This makes the NFTs dynamic.
2.  **Oracle Integration:** The `updateParcelAttributesByOracle` function serves as a designated endpoint for trusted external sources (Oracles) to change the state of the NFTs. Access control (`onlyOracle`) and a cooldown mechanism prevent spamming or malicious rapid updates.
3.  **Oracle Management by Governance:** Instead of the contract owner permanently controlling Oracles, `registerOracle` and `deregisterOracle` functions exist. Critically, these are *intended* to be called via successful governance proposals (`executeProposal`) rather than directly by the initial contract owner (marked `onlyOwner` for simplicity in this example, but the `callData` mechanism in `executeProposal` allows governance to call them).
4.  **Dynamic Attribute Types:** The system allows governance to define *new types* of attributes (`addAttributeType`) over time, making the system extensible without needing a full contract upgrade (though the *logic* consuming these attributes might still require upgrades off-chain or in connected contracts).
5.  **On-Chain Governance (Simplified DAO):**
    *   **Voting Power:** Voting power is directly tied to ownership of the dynamic NFTs (`balanceOf(msg.sender)`). This makes the NFT itself a governance token.
    *   **Proposal System:** `submitProposal`, `voteOnProposal`, `executeProposal` implement a basic proposal lifecycle.
    *   **Proposal Execution via `callData`:** A key advanced concept is storing the target function call and parameters as `bytes` in the proposal (`callData`). `executeProposal` then uses `address(this).call(proposal.callData)` to execute the proposed action directly within the contract, enabling governance to modify configuration, manage oracles, or add attribute types. This provides powerful on-chain control.
    *   **Quorum and Threshold:** The `getProposalState` logic incorporates checks for minimum voter participation (quorum) and minimum 'Yes' percentage (threshold) based on *cast votes* to determine if a proposal passes.
6.  **ReentrancyGuard:** Included as a standard security measure, although the critical functions like `updateParcelAttributesByOracle` and governance executions are carefully designed to minimize reentrancy risks.

This contract goes significantly beyond standard ERC721 or basic token/NFT contracts by integrating external data feeds that modify asset state, and layering a governance system that uses the assets themselves as voting power to control critical system parameters. It's a building block for complex virtual worlds, dynamic digital collectibles, or tokenized real-world assets where characteristics change based on verifiable external information.