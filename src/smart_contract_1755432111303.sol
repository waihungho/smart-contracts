This Solidity smart contract, `DecentralizedAdaptiveIdentity (DAI)`, is designed to showcase an advanced, creative, and trendy concept: a dynamic, Soulbound-like identity system where user attributes evolve over time and influence their access to on-chain resources and privileges. It aims to avoid direct duplication of existing open-source projects by combining several advanced concepts in a novel way.

---

## Contract: DecentralizedAdaptiveIdentity (DAI)

**Purpose:**
The DecentralizedAdaptiveIdentity (DAI) protocol establishes a novel framework for creating dynamic, Soulbound-like identities on-chain. Unlike static NFTs or simple reputation scores, DAI profiles possess "Adaptive Attributes" that evolve over time (e.g., decay), are influenced by verifiable on-chain actions, and can react to external oracle data. These attributes collectively determine a user's eligibility for various on-chain resources, exclusive access, and potentially enhanced governance power within an integrated Web3 ecosystem. The protocol's key parameters and attribute configurations are designed to be governed by a Decentralized Autonomous Organization (DAO), ensuring community-driven evolution and fairness.

**Core Concepts:**
1.  **Soulbound Profiles:** Users mint a non-transferable ERC721 token representing their unique on-chain identity.
2.  **Dynamic Attributes:** Profile attributes are not static. They can grow with attestations, decay over time, and be influenced by external factors via oracle feeds.
3.  **DAO Governance:** Critical parameters like attribute types, their influence weights, decay rates, and resource eligibility criteria are proposed and voted upon by a designated DAO.
4.  **Resource Gating & Dynamic Access:** Profile attributes directly determine access to protocol-specific resources, token allocations, exclusive NFT mints, and special feature functionalities.
5.  **Extensible Attestation:** A modular system allows various entities (e.g., dApps, reputable organizations, Oracles) to attest to specific attributes for users.

**Key Features & Function Summaries (25 Functions):**

---

### I. Identity (Profile) Management

1.  `constructor(string memory name_, string memory symbol_)`:
    *   Initializes the ERC721 token (for Soulbound Profiles).
    *   Grants `DEFAULT_ADMIN_ROLE`, `ATTESTER_ROLE`, and `ORACLE_ROLE` to the deployer.
    *   Sets the initial `daoAddress` to the deployer, which can be transferred to a dedicated DAO contract later.
    *   Initializes the counter for attribute types.
2.  `registerProfile(string _tokenURI)`:
    *   Allows a user to mint their unique, non-transferable Soulbound profile NFT.
    *   Ensures a user can only register one profile.
3.  `updateProfileMetadataURI(uint256 _profileId, string _newURI)`:
    *   Enables the profile owner to update their profile's metadata URI.
4.  `_beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)`:
    *   An internal override of ERC721 to enforce the Soulbound nature, preventing any transfers of the profile NFT (except minting/burning).

### II. Attribute Management & Evolution

5.  `proposeNewAttributeType(string _name, string _description, bool _decayEnabled, uint256 _initialWeight)`:
    *   Callable only by the designated `daoAddress`.
    *   Allows the DAO to propose a new type of attribute that can be tracked (e.g., "DeveloperXP", "CommunityScore").
6.  `voteOnAttributeTypeProposal(bytes32 _proposalId, bool _support)`:
    *   Callable only by the designated `daoAddress`.
    *   Allows DAO members to cast a vote on a proposed attribute type. (Simplified voting logic, implies a DAO contract would manage actual voting power).
7.  `executeAttributeTypeProposal(bytes32 _proposalId)`:
    *   Callable only by the designated `daoAddress`.
    *   Executes a successful attribute type proposal once the voting period ends and sufficient 'for' votes are secured.
8.  `attestUserAttribute(address _user, uint256 _attributeTypeId, uint256 _value, string _attestationContext)`:
    *   Callable by addresses with `ATTESTER_ROLE`.
    *   Allows an authorized entity to add or update a specific attribute score for a user's profile.
9.  `revokeUserAttribute(address _user, uint256 _attributeTypeId)`:
    *   Callable by addresses with `ATTESTER_ROLE`.
    *   Allows an authorized entity to revoke (reset to 0) a specific attribute for a user.
10. `batchAttestAttributes(address[] memory _users, uint256[] memory _attributeTypeIds, uint256[] memory _values, string[] memory _attestationContexts)`:
    *   Callable by addresses with `ATTESTER_ROLE`.
    *   Enables attesters to process multiple attribute attestations for different users and attributes in a single transaction.
11. `setAttributeDecayRate(uint256 _attributeTypeId, uint256 _decayRatePerPeriod)`:
    *   Callable only by the designated `daoAddress`.
    *   Sets the rate at which a specific attribute type's score will decay over time (e.g., points per day).
12. `setAttributeInfluenceWeight(uint256 _attributeTypeId, uint256 _weight)`:
    *   Callable only by the designated `daoAddress`.
    *   Determines how much an attribute contributes to the user's overall profile score/power.
13. `decayProfilesAttributes(address[] memory _users)`:
    *   Publicly callable (e.g., by a keeper network or anyone).
    *   Applies the configured time-based decay to the attributes of specified users, updating their scores. This offloads the cost of decay from individual users.
14. `triggerOracleAttributeUpdate(address _user, uint256 _attributeTypeId, uint256 _newValue)`:
    *   Callable by addresses with `ORACLE_ROLE`.
    *   Allows an authorized oracle to update a user's attribute based on external, off-chain data feeds (e.g., verified real-world activity, social sentiment).

### III. Resource & Access Control

15. `proposeResourceConfiguration(bytes32 _resourceId, string _description, uint256[] memory _requiredAttributeTypes, uint256[] memory _requiredAttributeMinScores)`:
    *   Callable only by the designated `daoAddress`.
    *   Allows the DAO to propose a new resource (e.g., an exclusive NFT drop, a token allocation) and define the minimum attribute scores required for eligibility.
16. `voteOnResourceConfiguration(bytes32 _proposalId, bool _support)`:
    *   Callable only by the designated `daoAddress`.
    *   Allows DAO members to cast a vote on a proposed resource configuration.
17. `executeResourceConfiguration(bytes32 _proposalId)`:
    *   Callable only by the designated `daoAddress`.
    *   Executes a successful resource configuration proposal once the voting period ends and sufficient 'for' votes are secured.
18. `checkEligibilityForResource(address _user, bytes32 _resourceId)`:
    *   A public view function that allows any external contract or dApp to check if a user's current profile attributes meet the requirements for a specific resource.
19. `claimDynamicResource(bytes32 _resourceId)`:
    *   Allows a user to claim a predefined resource if their profile meets the dynamically configured eligibility criteria.
    *   (Note: In a real system, this would integrate with other contracts for actual token/NFT distribution).
20. `getProfileOverallScore(address _user)`:
    *   A public view function that calculates a user's aggregated "power" or "influence" score based on all their attributes, taking into account their individual decay and DAO-assigned influence weights.
21. `getProfileAttributeScore(address _user, uint256 _attributeTypeId)`:
    *   A public view function that returns the current calculated score for a specific attribute of a user, applying decay if enabled and relevant.
22. `grantAccessToExclusiveFunction(address _user, bytes32 _functionId)`:
    *   An internal helper/example function demonstrating how other internal contract logic could gate access to specific features or functions based on a user's profile attributes.

### IV. Role & Configuration Management

23. `setAttesterStatus(address _attester, bool _status)`:
    *   Callable only by `DEFAULT_ADMIN_ROLE`.
    *   Grants or revokes the `ATTESTER_ROLE` to/from a given address.
24. `setOracleStatus(address _oracle, bool _status)`:
    *   Callable only by `DEFAULT_ADMIN_ROLE`.
    *   Grants or revokes the `ORACLE_ROLE` to/from a given address.
25. `setDAOAddress(address _newDAOAddress)`:
    *   Callable only by `DEFAULT_ADMIN_ROLE`.
    *   Sets or updates the address of the controlling DAO contract that will manage proposals and executions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/*
    Contract Name: DecentralizedAdaptiveIdentity (DAI)

    Purpose:
    The DecentralizedAdaptiveIdentity (DAI) protocol establishes a novel
    framework for creating dynamic, Soulbound-like identities on-chain.
    Unlike static NFTs or simple reputation scores, DAI profiles possess
    "Adaptive Attributes" that evolve over time (e.g., decay), are influenced
    by verifiable on-chain actions, and can react to external oracle data.
    These attributes collectively determine a user's eligibility for
    various on-chain resources, exclusive access, and potentially enhanced
    governance power within an integrated Web3 ecosystem. The protocol's
    key parameters and attribute configurations are designed to be governed
    by a Decentralized Autonomous Organization (DAO), ensuring community-driven
    evolution and fairness.

    Core Concepts:
    1.  Soulbound Profiles: Users mint a non-transferable ERC721 token
        representing their unique on-chain identity.
    2.  Dynamic Attributes: Profile attributes are not static. They can
        grow with attestations, decay over time, and be influenced by
        external factors via oracle feeds.
    3.  DAO Governance: Critical parameters like attribute types, their
        influence weights, decay rates, and resource eligibility criteria
        are proposed and voted upon by a designated DAO.
    4.  Resource Gating & Dynamic Access: Profile attributes directly
        determine access to protocol-specific resources, token allocations,
        exclusive NFT mints, and special feature functionalities.
    5.  Extensible Attestation: A modular system allows various entities
        (e.g., dApps, reputable organizations, Oracles) to attest to
        specific attributes for users.

    Key Features & Function Summaries (25 Functions):

    I. Identity (Profile) Management:
    1.  constructor(): Initializes roles (DEFAULT_ADMIN_ROLE, ATTESTER_ROLE, ORACLE_ROLE, DAO_ROLE) and ERC721.
    2.  registerProfile(string _tokenURI): Mints a new, unique Soulbound profile NFT for the caller.
    3.  updateProfileMetadataURI(uint256 _profileId, string _newURI): Allows profile owner to update their metadata URI.
    4.  _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize): Internal override to prevent profile transfers.

    II. Attribute Management & Evolution:
    5.  proposeNewAttributeType(string _name, string _description, bool _decayEnabled, uint256 _initialWeight): DAO proposes a new attribute type.
    6.  voteOnAttributeTypeProposal(bytes32 _proposalId, bool _support): DAO members vote on an attribute type proposal.
    7.  executeAttributeTypeProposal(bytes32 _proposalId): Executes a successful attribute type proposal, adding the new type.
    8.  attestUserAttribute(address _user, uint256 _attributeTypeId, uint256 _value, string _attestationContext): An authorized attester adds/updates an attribute score for a user.
    9.  revokeUserAttribute(address _user, uint256 _attributeTypeId): An authorized attester can revoke (reset) an attribute for a user.
    10. batchAttestAttributes(address[] memory _users, uint256[] memory _attributeTypeIds, uint256[] memory _values, string[] memory _attestationContexts): Allows attesters to attest multiple attributes for multiple users in one transaction.
    11. setAttributeDecayRate(uint256 _attributeTypeId, uint256 _decayRatePerPeriod): DAO sets the decay rate for a specific attribute type.
    12. setAttributeInfluenceWeight(uint256 _attributeTypeId, uint256 _weight): DAO sets how much an attribute type influences the overall profile score.
    13. decayProfilesAttributes(address[] memory _users): Callable by anyone (e.g., a keeper bot) to periodically apply decay to specified profiles' attributes.
    14. triggerOracleAttributeUpdate(address _user, uint256 _attributeTypeId, uint256 _newValue): An authorized oracle updates an attribute based on external data.

    III. Resource & Access Control:
    15. proposeResourceConfiguration(bytes32 _resourceId, string _description, uint256[] memory _requiredAttributeTypes, uint256[] memory _requiredAttributeMinScores): DAO proposes a new resource ID and its eligibility criteria.
    16. voteOnResourceConfiguration(bytes32 _proposalId, bool _support): DAO members vote on a resource configuration proposal.
    17. executeResourceConfiguration(bytes32 _proposalId): Executes a successful resource configuration proposal.
    18. checkEligibilityForResource(address _user, bytes32 _resourceId): Checks if a user's profile meets the dynamic criteria for a specific resource ID.
    19. claimDynamicResource(bytes32 _resourceId): Allows users to claim predefined resources (e.g., tokens, special NFT mint) based on their profile eligibility. (Placeholder for integration logic).
    20. getProfileOverallScore(address _user): Calculates a user's combined "power" or "influence" score based on all their attributes and their weights.
    21. getProfileAttributeScore(address _user, uint256 _attributeTypeId): Gets the current calculated score for a specific attribute of a user.
    22. grantAccessToExclusiveFunction(address _user, bytes32 _functionId): Internal helper/example function demonstrating gating access based on profile attributes.

    IV. Role & Configuration Management:
    23. setAttesterStatus(address _attester, bool _status): Admin/DAO grants or revokes ATTESTER_ROLE.
    24. setOracleStatus(address _oracle, bool _status): Admin/DAO grants or revokes ORACLE_ROLE.
    25. setDAOAddress(address _newDAOAddress): Admin sets or updates the address of the controlling DAO.
*/

contract DecentralizedAdaptiveIdentity is ERC721URIStorage, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Roles for AccessControl
    bytes32 public constant ATTESTER_ROLE = keccak256("ATTESTER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // Profile Management
    Counters.Counter private _profileIds; // Total number of profiles minted
    mapping(address => uint256) private _userToProfileId; // Maps user address to their profileId
    mapping(uint256 => address) private _profileIdToUser; // Maps profileId to user address

    // Attribute Management
    struct AttributeType {
        string name;
        string description;
        bool decayEnabled;
        uint256 decayRatePerPeriod; // e.g., points per day
        uint256 influenceWeight;    // How much this attribute contributes to overall score (e.g., 1-100)
        bool exists;                // To check if a type ID is valid
    }
    uint256 private _nextAttributeTypeId; // Counter for new attribute types
    mapping(uint256 => AttributeType) public attributeTypes; // Stores definitions of all attribute types

    struct UserAttribute {
        uint256 score;             // Current score of the attribute
        uint256 lastUpdatedTimestamp; // Last time this attribute was updated or decayed
        // uint256 initialAttestationValue; // Value when first attested or reset (for decay calculation, not strictly needed with current decay logic)
    }
    mapping(address => mapping(uint256 => UserAttribute)) public userAttributes; // userAddress => attributeTypeId => UserAttribute

    // Resource Configuration
    struct ResourceConfig {
        string description;
        uint256[] requiredAttributeTypes;
        uint256[] requiredAttributeMinScores;
        bool exists;
    }
    mapping(bytes32 => ResourceConfig) public resourceConfigs; // resourceId => ResourceConfig

    // Basic DAO Proposal System (simplified for attribute type and resource config)
    struct Proposal {
        bytes32 id;
        bytes32 dataHash; // Hash of the proposed data (e.g., encoded new attribute type)
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        mapping(address => bool) hasVoted; // User address => has voted on this proposal
    }
    mapping(bytes32 => Proposal) public proposals;
    mapping(bytes32 => bytes) private _proposalData; // Stores the actual data for execution

    uint256 public proposalVotingPeriod = 3 days; // Default voting period

    // DAO related address - a separate DAO contract would typically manage this.
    // This address has special permissions to propose and execute attribute types and resource configs.
    address public daoAddress;

    // --- Events ---
    event ProfileRegistered(address indexed user, uint256 profileId);
    event ProfileMetadataUpdated(uint256 indexed profileId, string newURI);
    event AttributeAttested(address indexed user, uint256 indexed attributeTypeId, uint256 value, string context);
    event AttributeRevoked(address indexed user, uint256 indexed attributeTypeId);
    event AttributeDecayed(address indexed user, uint256 indexed attributeTypeId, uint256 oldScore, uint256 newScore);
    event OracleAttributeUpdated(address indexed user, uint256 indexed attributeTypeId, uint256 newValue);
    event AttributeTypeProposed(bytes32 indexed proposalId, string name, uint256 anticipatedAttributeTypeId);
    event AttributeTypeExecuted(bytes32 indexed proposalId, uint256 attributeTypeId);
    event ResourceConfigProposed(bytes32 indexed proposalId, bytes32 indexed resourceId, string description);
    event ResourceConfigExecuted(bytes32 indexed proposalId, bytes32 indexed resourceId);
    event ProposalVoted(bytes32 indexed proposalId, address indexed voter, bool support);
    event ResourceClaimed(address indexed user, bytes32 indexed resourceId);

    // --- Modifiers ---
    modifier onlyAttester() {
        require(hasRole(ATTESTER_ROLE, _msgSender()), "DAI: Must have ATTESTER_ROLE");
        _;
    }

    modifier onlyOracle() {
        require(hasRole(ORACLE_ROLE, _msgSender()), "DAI: Must have ORACLE_ROLE");
        _;
    }

    modifier onlyDAO() {
        require(_msgSender() == daoAddress, "DAI: Only designated DAO address can call this function");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the contract, sets up ERC721 properties, and grants initial roles.
     *      The deployer is granted admin, attester, and oracle roles, and is set as the initial DAO address.
     * @param name_ The name of the ERC721 token (e.g., "DAI Profile").
     * @param symbol_ The symbol of the ERC721 token (e.g., "DAI").
     */
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        daoAddress = _msgSender(); // Deployer is initially the DAO address
        _grantRole(ATTESTER_ROLE, _msgSender()); // Deployer is also an initial attester
        _grantRole(ORACLE_ROLE, _msgSender());   // Deployer is also an initial oracle
        _nextAttributeTypeId = 1; // Start attribute type IDs from 1
    }

    // --- I. Identity (Profile) Management ---

    /**
     * @dev Mints a new, unique Soulbound profile NFT for the caller.
     *      A user can only register one profile.
     * @param _tokenURI The URI for the profile's metadata.
     */
    function registerProfile(string memory _tokenURI) public nonReentrant {
        require(_userToProfileId[_msgSender()] == 0, "DAI: Profile already registered for this address");

        _profileIds.increment();
        uint256 newProfileId = _profileIds.current();

        _mint(_msgSender(), newProfileId);
        _setTokenURI(newProfileId, _tokenURI);

        _userToProfileId[_msgSender()] = newProfileId;
        _profileIdToUser[newProfileId] = _msgSender();

        emit ProfileRegistered(_msgSender(), newProfileId);
    }

    /**
     * @dev Allows the profile owner to update their metadata URI.
     * @param _profileId The ID of the profile NFT.
     * @param _newURI The new URI for the profile's metadata.
     */
    function updateProfileMetadataURI(uint256 _profileId, string memory _newURI) public {
        require(ownerOf(_profileId) == _msgSender(), "DAI: Not profile owner");
        _setTokenURI(_profileId, _newURI);
        emit ProfileMetadataUpdated(_profileId, _newURI);
    }

    /**
     * @dev Internal function to prevent profile NFT transfers, making them Soulbound.
     *      Overrides the standard ERC721 transfer logic.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer if it's not a mint (from address zero) or burn (to address zero)
        require(from == address(0) || to == address(0), "DAI: Profiles are soulbound and non-transferable");
    }

    // --- II. Attribute Management & Evolution ---

    /**
     * @dev Proposes a new attribute type to be added to the protocol.
     *      Only callable by the designated DAO address.
     * @param _name The name of the attribute (e.g., "DeveloperXP", "CommunityContribution").
     * @param _description A detailed description of the attribute.
     * @param _decayEnabled True if this attribute should decay over time.
     * @param _initialWeight The initial influence weight of this attribute on overall score (e.g., 1-100).
     * @return proposalId The unique identifier of the created proposal.
     */
    function proposeNewAttributeType(string memory _name, string memory _description, bool _decayEnabled, uint256 _initialWeight) public onlyDAO returns (bytes32 proposalId) {
        require(_initialWeight > 0, "DAI: Influence weight must be positive");

        uint256 anticipatedTypeId = _nextAttributeTypeId; // The ID this type will get if executed

        // Encode the parameters for the proposal data
        bytes memory data = abi.encode(_name, _description, _decayEnabled, anticipatedTypeId, _initialWeight);
        proposalId = keccak256(data); // Hash of the encoded data acts as proposal ID

        require(proposals[proposalId].proposer == address(0), "DAI: Proposal with this ID already exists");

        proposals[proposalId] = Proposal({
            id: proposalId,
            dataHash: keccak256(data), // Store hash of data to verify integrity during execution
            proposer: _msgSender(),
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + proposalVotingPeriod,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize empty mapping for votes
        });
        _proposalData[proposalId] = data; // Store actual data for execution

        emit AttributeTypeProposed(proposalId, _name, anticipatedTypeId);
    }

    /**
     * @dev Allows the designated DAO address to vote on an attribute type proposal.
     *      This is a simplified voting mechanism. A full DAO would typically have more complex voting power.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnAttributeTypeProposal(bytes32 _proposalId, bool _support) public onlyDAO {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "DAI: Proposal does not exist");
        require(block.timestamp <= proposal.deadline, "DAI: Proposal voting period ended");
        require(!proposal.hasVoted[_msgSender()], "DAI: Already voted on this proposal");

        proposal.hasVoted[_msgSender()] = true;
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ProposalVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Executes a successful attribute type proposal.
     *      Requires a majority of 'for' votes from the DAO address and must be called after the deadline.
     *      Only callable by the designated DAO address.
     * @param _proposalId The ID of the proposal.
     */
    function executeAttributeTypeProposal(bytes32 _proposalId) public onlyDAO nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "DAI: Proposal does not exist");
        require(block.timestamp > proposal.deadline, "DAI: Proposal voting period not ended");
        require(!proposal.executed, "DAI: Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "DAI: Proposal failed to pass (not enough 'for' votes)");

        // Retrieve and decode the data
        bytes memory data = _proposalData[_proposalId];
        bytes32 dataHash = keccak256(data);
        require(dataHash == proposal.dataHash, "DAI: Proposal data hash mismatch"); // Sanity check

        (string memory name, string memory description, bool decayEnabled, uint256 proposedTypeId, uint256 initialWeight) =
            abi.decode(data, (string, string, bool, uint256, uint256));

        require(proposedTypeId == _nextAttributeTypeId, "DAI: Attribute type ID mismatch or already taken");

        attributeTypes[proposedTypeId] = AttributeType({
            name: name,
            description: description,
            decayEnabled: decayEnabled,
            decayRatePerPeriod: 0, // Default to 0, DAO can set later using `setAttributeDecayRate`
            influenceWeight: initialWeight,
            exists: true
        });

        _nextAttributeTypeId++; // Increment for the next new attribute type
        proposal.executed = true;

        // Clear proposal data after execution to save gas
        delete _proposalData[_proposalId];

        emit AttributeTypeExecuted(_proposalId, proposedTypeId);
    }

    /**
     * @dev An authorized attester adds or updates an attribute score for a specific user.
     *      The attribute type must be pre-defined by the DAO.
     * @param _user The address of the user whose attribute is being attested.
     * @param _attributeTypeId The ID of the attribute type (must be pre-defined by DAO).
     * @param _value The new score value for the attribute.
     * @param _attestationContext Optional context/reason for the attestation.
     */
    function attestUserAttribute(address _user, uint256 _attributeTypeId, uint256 _value, string memory _attestationContext) public onlyAttester {
        require(attributeTypes[_attributeTypeId].exists, "DAI: Attribute type does not exist");
        require(_userToProfileId[_user] != 0, "DAI: User has no registered profile");

        userAttributes[_user][_attributeTypeId] = UserAttribute({
            score: _value,
            lastUpdatedTimestamp: block.timestamp
        });

        emit AttributeAttested(_user, _attributeTypeId, _value, _attestationContext);
    }

    /**
     * @dev An authorized attester can revoke (reset to 0) an attribute for a user.
     * @param _user The address of the user whose attribute is being revoked.
     * @param _attributeTypeId The ID of the attribute type to revoke.
     */
    function revokeUserAttribute(address _user, uint256 _attributeTypeId) public onlyAttester {
        require(attributeTypes[_attributeTypeId].exists, "DAI: Attribute type does not exist");
        require(_userToProfileId[_user] != 0, "DAI: User has no registered profile");
        require(userAttributes[_user][_attributeTypeId].score > 0, "DAI: Attribute already 0 or not set");

        delete userAttributes[_user][_attributeTypeId]; // Effectively resets it to default (0,0)

        emit AttributeRevoked(_user, _attributeTypeId);
    }

    /**
     * @dev Allows attesters to attest multiple attributes for multiple users in a single transaction.
     *      Useful for batch operations. All input arrays must have the same length.
     * @param _users Array of user addresses.
     * @param _attributeTypeIds Array of attribute type IDs, corresponding to each user.
     * @param _values Array of score values, corresponding to each user and attribute type.
     * @param _attestationContexts Array of attestation contexts (can be empty strings).
     */
    function batchAttestAttributes(
        address[] memory _users,
        uint256[] memory _attributeTypeIds,
        uint256[] memory _values,
        string[] memory _attestationContexts
    ) public onlyAttester {
        require(_users.length == _attributeTypeIds.length &&
                _users.length == _values.length &&
                _users.length == _attestationContexts.length,
                "DAI: Input arrays must have same length");

        for (uint i = 0; i < _users.length; i++) {
            attestUserAttribute(_users[i], _attributeTypeIds[i], _values[i], _attestationContexts[i]);
        }
    }

    /**
     * @dev DAO sets the decay rate for a specific attribute type.
     *      Only callable by the designated DAO address.
     * @param _attributeTypeId The ID of the attribute type.
     * @param _decayRatePerPeriod The rate at which the attribute score decays (e.g., 10 points per 1 day period).
     */
    function setAttributeDecayRate(uint256 _attributeTypeId, uint256 _decayRatePerPeriod) public onlyDAO {
        require(attributeTypes[_attributeTypeId].exists, "DAI: Attribute type does not exist");
        attributeTypes[_attributeTypeId].decayRatePerPeriod = _decayRatePerPeriod;
        attributeTypes[_attributeTypeId].decayEnabled = (_decayRatePerPeriod > 0); // Enable decay if rate > 0
    }

    /**
     * @dev DAO sets how much an attribute type influences the overall profile score.
     *      Only callable by the designated DAO address.
     * @param _attributeTypeId The ID of the attribute type.
     * @param _weight The influence weight (e.g., 1-100), higher means more impact.
     */
    function setAttributeInfluenceWeight(uint256 _attributeTypeId, uint256 _weight) public onlyDAO {
        require(attributeTypes[_attributeTypeId].exists, "DAI: Attribute type does not exist");
        attributeTypes[_attributeTypeId].influenceWeight = _weight;
    }

    /**
     * @dev Applies time-based decay to specified profiles' attributes.
     *      Designed to be called periodically, e.g., by a keeper network or anyone.
     *      This avoids forcing users to pay for decay, allowing a third-party to trigger updates.
     * @param _users An array of user addresses whose attributes should be decayed.
     */
    function decayProfilesAttributes(address[] memory _users) public {
        for (uint i = 0; i < _users.length; i++) {
            address user = _users[i];
            // Iterate through all currently defined attribute types
            for (uint256 typeId = 1; typeId < _nextAttributeTypeId; typeId++) {
                if (attributeTypes[typeId].exists && attributeTypes[typeId].decayEnabled) {
                    UserAttribute storage userAttr = userAttributes[user][typeId];
                    if (userAttr.score > 0 && userAttr.lastUpdatedTimestamp > 0) {
                        uint256 timeElapsed = block.timestamp - userAttr.lastUpdatedTimestamp;
                        uint256 decayPeriods = timeElapsed / 1 days; // Assuming decay period is 1 day (can be made configurable)

                        if (decayPeriods > 0) {
                            uint256 decayAmount = decayPeriods * attributeTypes[typeId].decayRatePerPeriod;
                            uint256 oldScore = userAttr.score;
                            userAttr.score = (userAttr.score > decayAmount) ? userAttr.score - decayAmount : 0;
                            userAttr.lastUpdatedTimestamp = block.timestamp; // Update timestamp after decay

                            if (userAttr.score != oldScore) {
                                emit AttributeDecayed(user, typeId, oldScore, userAttr.score);
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * @dev An authorized oracle updates an attribute based on external data.
     *      e.g., "DAO participation" based on off-chain Snapshot votes, "Carbon Footprint Score" from a data provider.
     * @param _user The address of the user.
     * @param _attributeTypeId The ID of the attribute type.
     * @param _newValue The new score value provided by the oracle.
     */
    function triggerOracleAttributeUpdate(address _user, uint256 _attributeTypeId, uint256 _newValue) public onlyOracle {
        require(attributeTypes[_attributeTypeId].exists, "DAI: Attribute type does not exist");
        require(_userToProfileId[_user] != 0, "DAI: User has no registered profile");

        userAttributes[_user][_attributeTypeId] = UserAttribute({
            score: _newValue,
            lastUpdatedTimestamp: block.timestamp
        });

        emit OracleAttributeUpdated(_user, _attributeTypeId, _newValue);
    }

    // --- III. Resource & Access Control ---

    /**
     * @dev Proposes a new resource ID and its eligibility criteria.
     *      Only callable by the designated DAO address.
     * @param _resourceId A unique identifier for the resource (e.g., keccak256("ExclusiveNFTDropA")).
     * @param _description A description of the resource and its benefits.
     * @param _requiredAttributeTypes An array of attribute type IDs required for eligibility.
     * @param _requiredAttributeMinScores An array of minimum scores required for each corresponding attribute type.
     * @return proposalId The unique identifier of the created proposal.
     */
    function proposeResourceConfiguration(
        bytes32 _resourceId,
        string memory _description,
        uint256[] memory _requiredAttributeTypes,
        uint256[] memory _requiredAttributeMinScores
    ) public onlyDAO returns (bytes32 proposalId) {
        require(_requiredAttributeTypes.length == _requiredAttributeMinScores.length, "DAI: Mismatched array lengths");
        require(resourceConfigs[_resourceId].exists == false, "DAI: Resource config ID already exists");

        // Check if all required attribute types exist
        for (uint i = 0; i < _requiredAttributeTypes.length; i++) {
            require(attributeTypes[_requiredAttributeTypes[i]].exists, "DAI: Required attribute type does not exist");
        }

        bytes memory data = abi.encode(_resourceId, _description, _requiredAttributeTypes, _requiredAttributeMinScores);
        proposalId = keccak256(data);

        require(proposals[proposalId].proposer == address(0), "DAI: Proposal with this ID already exists");

        proposals[proposalId] = Proposal({
            id: proposalId,
            dataHash: keccak256(data),
            proposer: _msgSender(),
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + proposalVotingPeriod,
            executed: false,
            hasVoted: new mapping(address => bool)
        });
        _proposalData[proposalId] = data;

        emit ResourceConfigProposed(proposalId, _resourceId, _description);
    }

    /**
     * @dev Allows the designated DAO address to vote on a resource configuration proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnResourceConfiguration(bytes32 _proposalId, bool _support) public onlyDAO {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "DAI: Proposal does not exist");
        require(block.timestamp <= proposal.deadline, "DAI: Proposal voting period ended");
        require(!proposal.hasVoted[_msgSender()], "DAI: Already voted on this proposal");

        proposal.hasVoted[_msgSender()] = true;
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ProposalVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Executes a successful resource configuration proposal.
     *      Requires a majority of 'for' votes from the DAO address and must be called after the deadline.
     *      Only callable by the designated DAO address.
     * @param _proposalId The ID of the proposal.
     */
    function executeResourceConfiguration(bytes32 _proposalId) public onlyDAO nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "DAI: Proposal does not exist");
        require(block.timestamp > proposal.deadline, "DAI: Proposal voting period not ended");
        require(!proposal.executed, "DAI: Proposal already executed");
        require(proposal.votesFor > proposal.votesAgainst, "DAI: Proposal failed to pass");

        bytes memory data = _proposalData[_proposalId];
        bytes32 dataHash = keccak256(data);
        require(dataHash == proposal.dataHash, "DAI: Proposal data hash mismatch");

        (bytes32 resourceId, string memory description, uint256[] memory requiredAttributeTypes, uint256[] memory requiredAttributeMinScores) =
            abi.decode(data, (bytes32, string, uint256[], uint256[]));

        resourceConfigs[resourceId] = ResourceConfig({
            description: description,
            requiredAttributeTypes: requiredAttributeTypes,
            requiredAttributeMinScores: requiredAttributeMinScores,
            exists: true
        });

        proposal.executed = true;
        delete _proposalData[_proposalId]; // Clear proposal data after execution

        emit ResourceConfigExecuted(_proposalId, resourceId, description);
    }

    /**
     * @dev Checks if a user's profile meets the dynamic criteria for a specific resource ID.
     *      This function can be called by other contracts or off-chain systems to verify eligibility.
     * @param _user The address of the user.
     * @param _resourceId The unique identifier of the resource.
     * @return True if the user is eligible, false otherwise.
     */
    function checkEligibilityForResource(address _user, bytes32 _resourceId) public view returns (bool) {
        require(_userToProfileId[_user] != 0, "DAI: User has no registered profile");
        ResourceConfig storage config = resourceConfigs[_resourceId];
        require(config.exists, "DAI: Resource config does not exist");

        for (uint i = 0; i < config.requiredAttributeTypes.length; i++) {
            uint256 requiredTypeId = config.requiredAttributeTypes[i];
            uint256 minScore = config.requiredAttributeMinScores[i];
            uint256 userScore = getProfileAttributeScore(_user, requiredTypeId);

            if (userScore < minScore) {
                return false; // User does not meet minimum score for this attribute
            }
        }
        return true; // User meets all required criteria
    }

    /**
     * @dev Allows users to "claim" resources based on their profile eligibility.
     *      This function would typically interact with other contracts (e.g., an NFT minter, a token distributor)
     *      to facilitate the actual resource transfer.
     *      For this example, it just checks eligibility and emits an event.
     * @param _resourceId The unique identifier of the resource to claim.
     */
    function claimDynamicResource(bytes32 _resourceId) public nonReentrant {
        require(checkEligibilityForResource(_msgSender(), _resourceId), "DAI: Not eligible to claim this resource");

        // --- Placeholder for actual resource distribution logic ---
        // In a real scenario, this would trigger an external call or internal transfer:
        // e.g., IERC20(tokenAddress).transfer(_msgSender(), amount);
        // e.g., INFTMinter(nftMinterAddress).mintNFT(_msgSender(), nftId);
        // For demonstration, we simply emit an event.
        // -----------------------------------------------------------

        emit ResourceClaimed(_msgSender(), _resourceId);
    }

    /**
     * @dev Calculates a user's combined "power" or "influence" score based on all their attributes and their weights.
     *      This could be used for dynamic governance weight, tiering, etc.
     * @param _user The address of the user.
     * @return The overall calculated score.
     */
    function getProfileOverallScore(address _user) public view returns (uint256) {
        uint256 totalScore = 0;
        // Iterate through all defined attribute types (up to _nextAttributeTypeId - 1)
        for (uint256 typeId = 1; typeId < _nextAttributeTypeId; typeId++) {
            if (attributeTypes[typeId].exists) {
                uint256 attributeScore = getProfileAttributeScore(_user, typeId); // Get current, potentially decayed score
                totalScore += (attributeScore * attributeTypes[typeId].influenceWeight);
            }
        }
        return totalScore;
    }

    /**
     * @dev Gets the current calculated score for a specific attribute of a user,
     *      applying decay if enabled and relevant.
     * @param _user The address of the user.
     * @param _attributeTypeId The ID of the attribute type.
     * @return The current score of the attribute.
     */
    function getProfileAttributeScore(address _user, uint256 _attributeTypeId) public view returns (uint256) {
        if (!attributeTypes[_attributeTypeId].exists) {
            return 0; // Attribute type doesn't exist
        }
        UserAttribute storage userAttr = userAttributes[_user][_attributeTypeId];
        if (userAttr.score == 0) {
            return 0; // User doesn't have this attribute or it decayed to 0
        }

        if (attributeTypes[_attributeTypeId].decayEnabled) {
            uint256 timeElapsed = block.timestamp - userAttr.lastUpdatedTimestamp;
            uint256 decayPeriods = timeElapsed / 1 days; // Assuming decay period is 1 day, matching `decayProfilesAttributes`

            if (decayPeriods > 0) {
                uint256 decayAmount = decayPeriods * attributeTypes[_attributeTypeId].decayRatePerPeriod;
                return (userAttr.score > decayAmount) ? userAttr.score - decayAmount : 0;
            }
        }
        return userAttr.score;
    }

    /**
     * @dev Internal helper/example function demonstrating gating access based on profile attributes.
     *      Other contracts could call `checkEligibilityForResource` or implement similar logic.
     *      This function itself is not directly callable externally but is illustrative.
     * @param _user The address of the user attempting to access.
     * @param _functionId A specific identifier for the function/access point (e.g., keccak256("VIP_DAO_VOTE")).
     * @return True if access should be granted, false otherwise.
     */
    function grantAccessToExclusiveFunction(address _user, bytes32 _functionId) internal view returns (bool) {
        // This is a simplified example. In a real scenario, _functionId
        // would map to specific attribute requirements defined either directly
        // in code or via `resourceConfigs` (by using checkEligibilityForResource).

        if (_functionId == keccak256("VIP_DAO_VOTE")) {
            // Example: VIP_DAO_VOTE requires "GovernanceParticipation" (assuming attributeTypeId 2) >= 50
            uint256 govParticipationTypeId = 2;
            if (attributeTypes[govParticipationTypeId].exists && getProfileAttributeScore(_user, govParticipationTypeId) >= 50) {
                return true;
            }
        } else if (_functionId == keccak256("ExclusiveContentAccess")) {
            // Example: ExclusiveContentAccess requires "ContentCreator" (assuming attributeTypeId 3) >= 100
            uint256 contentCreatorTypeId = 3;
             if (attributeTypes[contentCreatorTypeId].exists && getProfileAttributeScore(_user, contentCreatorTypeId) >= 100) {
                return true;
            }
        }
        // Add more logic for other _functionId checks as needed.
        return false;
    }

    // --- IV. Role & Configuration Management ---

    /**
     * @dev Grants or revokes the `ATTESTER_ROLE` to/from an address.
     *      Only callable by an account with `DEFAULT_ADMIN_ROLE`.
     * @param _attester The address to grant/revoke the role.
     * @param _status True to grant, false to revoke.
     */
    function setAttesterStatus(address _attester, bool _status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_status) {
            _grantRole(ATTESTER_ROLE, _attester);
        } else {
            _revokeRole(ATTESTER_ROLE, _attester);
        }
    }

    /**
     * @dev Grants or revokes the `ORACLE_ROLE` to/from an address.
     *      Only callable by an account with `DEFAULT_ADMIN_ROLE`.
     * @param _oracle The address to grant/revoke the role.
     * @param _status True to grant, false to revoke.
     */
    function setOracleStatus(address _oracle, bool _status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_status) {
            _grantRole(ORACLE_ROLE, _oracle);
        } else {
            _revokeRole(ORACLE_ROLE, _oracle);
        }
    }

    /**
     * @dev Sets or updates the address of the controlling DAO.
     *      This DAO address is what can propose and execute attribute types and resource configurations.
     *      Only callable by an account with `DEFAULT_ADMIN_ROLE`.
     * @param _newDAOAddress The new address for the DAO.
     */
    function setDAOAddress(address _newDAOAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newDAOAddress != address(0), "DAI: DAO address cannot be zero");
        daoAddress = _newDAOAddress;
    }

    // --- View Functions for External Access ---

    /**
     * @dev Returns the profile ID for a given user address.
     * @param _user The address of the user.
     * @return The profile ID, or 0 if no profile is registered for the user.
     */
    function getProfileId(address _user) public view returns (uint256) {
        return _userToProfileId[_user];
    }

    /**
     * @dev Returns the user address for a given profile ID.
     * @param _profileId The ID of the profile.
     * @return The user's address, or address(0) if the profile ID is not valid.
     */
    function getUserAddress(uint256 _profileId) public view returns (address) {
        return _profileIdToUser[_profileId];
    }

    /**
     * @dev Returns the total number of profiles minted.
     * @return The total count of registered profiles.
     */
    function getTotalProfiles() public view returns (uint256) {
        return _profileIds.current();
    }

    /**
     * @dev Returns the current value of the next attribute type ID to be assigned.
     *      This indicates the ID that a newly proposed and executed attribute type will receive.
     * @return The next available attribute type ID.
     */
    function getNextAttributeTypeId() public view returns (uint256) {
        return _nextAttributeTypeId;
    }
}
```