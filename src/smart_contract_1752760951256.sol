Here's a Solidity smart contract named `SynapseFabric` designed around the concept of decentralized AI model co-creation, composition, and fractional ownership. It incorporates advanced concepts like composable NFTs, an on-chain reputation/validation system, and a fair revenue distribution model for fractional owners without relying on existing OpenZeppelin implementations for core patterns (ERC-721, Ownable, Pausable) to adhere to the "no open source duplication" constraint.

---

## SynapseFabric Smart Contract

**Solidity Version:** `^0.8.0`
**License:** MIT

### Outline:

1.  **Core State Variables**: Manages global counters, ownership, and administrative settings.
2.  **Structs**: Defines data structures for Knowledge Units (KUs), AI Pipelines (AIPs), and Validation Requests.
3.  **Events**: Declares events for significant actions, enabling off-chain monitoring and indexing.
4.  **Modifiers**: Custom modifiers for access control (ownership, pausing, validation roles, oracle role).
5.  **Knowledge Unit (KU) Management**: Functions for creating, updating, transferring, and querying individual AI components (represented as NFTs).
6.  **AI Pipeline (AIP) Management**: Functions for composing KUs/AIPs into complex AI pipelines (also NFTs), managing their ownership, and establishing fractional shares.
7.  **AIP Usage & Revenue**: Handles fees for using AIPs, simulating off-chain AI result processing (via a trusted oracle), and managing a fair revenue distribution system for fractional share owners.
8.  **Reputation & Validation**: A simplified on-chain system for community validation and quality assessment of Knowledge Units.
9.  **Administrative & Utility**: Functions for the contract owner to manage contract state (pause/unpause) and withdraw general contract funds.

### Function Summary (28 Functions):

#### I. Knowledge Unit (KU) Management
1.  `registerKnowledgeUnit(string memory _uri, address _contributor)`: Mints a new Knowledge Unit NFT and assigns it an owner.
2.  `updateKnowledgeUnitURI(uint256 _kuId, string memory _newUri)`: Allows the owner of a KU to update its metadata URI.
3.  `transferKnowledgeUnit(address _from, address _to, uint256 _kuId)`: Transfers ownership of a KU NFT.
4.  `approveKU(address _approved, uint256 _kuId)`: Grants approval to another address to transfer a specific KU NFT.
5.  `getKnowledgeUnitOwner(uint256 _kuId) view returns (address)`: Returns the current owner of a Knowledge Unit.
6.  `getKnowledgeUnitURI(uint256 _kuId) view returns (string memory)`: Returns the metadata URI associated with a Knowledge Unit.
7.  `getKnowledgeUnitStatus(uint256 _kuId) view returns (bool, uint256, uint256)`: Returns validation status and vote counts for a KU.

#### II. AI Pipeline (AIP) Management
8.  `createAIP(string memory _name, string memory _description, uint256[] memory _kuComponentIds, uint256[] memory _aipComponentIds)`: Creates a new AI Pipeline NFT by combining existing KUs and/or other AIPs.
9.  `updateAIPMetadata(uint256 _aipId, string memory _newName, string memory _newDescription)`: Allows the owner of an AIP to update its name and description.
10. `getAIPComponents(uint256 _aipId) view returns (uint256[] memory, uint256[] memory)`: Retrieves the component KUs and AIPs that make up a specified AI Pipeline.
11. `getAIPOwner(uint256 _aipId) view returns (address)`: Returns the current owner of an AI Pipeline.
12. `transferAIP(address _from, address _to, uint256 _aipId)`: Transfers ownership of an AIP NFT.
13. `setAIPShareAllocation(uint256 _aipId, address[] memory _recipients, uint256[] memory _amounts)`: Establishes initial fractional ownership shares for an AIP amongst contributors.
14. `getAIPShares(uint256 _aipId, address _shareOwner) view returns (uint256)`: Returns the number of fractional shares an address holds for a given AIP.
15. `transferAIPShares(uint256 _aipId, address _from, address _to, uint256 _amount)`: Allows the transfer of fractional shares for an AIP between addresses.

#### III. AIP Usage & Revenue
16. `setAIPUsageFee(uint256 _aipId, uint256 _feeAmount)`: Sets the price (in wei) required to use a specific AI Pipeline.
17. `useAIP(uint256 _aipId, bytes32 _inputHash, bytes memory _callbackData)`: Initiates the use of an AIP. Requires payment of the usage fee and triggers an off-chain execution event.
18. `processAIResult(uint256 _aipId, bytes32 _inputHash, bytes32 _outputHash, bool _isValid)`: Callable by a designated oracle to attest to the successful (or unsuccessful) off-chain execution and verification of an AIP's result.
19. `updateAIPRewardAccrual(uint256 _aipId)`: Updates the global reward accrual rate for an AIP, making accumulated revenue available proportionally to shareholders. Callable by anyone.
20. `claimRevenue(uint256 _aipId)`: Allows an individual fractional share owner to claim their accrued revenue from a specific AIP.
21. `getAIPRevenueClaimable(uint256 _aipId, address _shareOwner) view returns (uint256)`: Returns the amount of revenue an individual share owner can claim for a given AIP.
22. `setOracleAddress(address _oracleAddress)`: Sets the address of the trusted oracle for AI result verification.

#### IV. Reputation & Validation
23. `submitKUForValidation(uint256 _kuId)`: Submits a Knowledge Unit for community validation, opening a voting period.
24. `voteOnKUQuality(uint256 _kuId, bool _isGood)`: Allows designated validators to cast a vote on the quality of a KU.
25. `finalizeKUValidation(uint256 _kuId)`: Finalizes the validation status of a KU based on collected votes.
26. `setValidator(address _validator, bool _status)`: Grants or revokes the `isValidator` role for an address.

#### V. Administrative & Utility
27. `pauseContract()`: Pauses certain sensitive functions in emergencies.
28. `unpauseContract()`: Resumes functions after a pause.
29. `withdrawContractBalance(address _to, uint256 _amount)`: Allows the contract owner to withdraw general contract funds.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SynapseFabric
 * @dev A decentralized platform for co-creating, composing, and monetizing modular AI knowledge units and pipelines.
 *
 * Outline:
 * 1.  Core State Variables: Manages global counters, ownership, and administrative settings.
 * 2.  Structs: Defines data structures for Knowledge Units (KUs), AI Pipelines (AIPs), and Validation Requests.
 * 3.  Events: Declares events for significant actions, enabling off-chain monitoring.
 * 4.  Modifiers: Custom modifiers for access control (ownership, pausing, validation roles, oracle role).
 * 5.  Knowledge Unit (KU) Management: Functions for creating, updating, transferring, and querying individual AI components.
 * 6.  AI Pipeline (AIP) Management: Functions for composing KUs/AIPs into complex pipelines, managing ownership, and fractional shares.
 * 7.  AIP Usage & Revenue: Handles fees for using AIPs, processing off-chain AI results (via oracle), and distributing revenue to share owners.
 * 8.  Reputation & Validation: A simplified system for community validation of Knowledge Units.
 * 9.  Administrative & Utility: Functions for contract owner to manage contract state and withdraw funds.
 *
 * Function Summary:
 *
 * I. Knowledge Unit (KU) Management
 * 1.  `registerKnowledgeUnit(string memory _uri, address _contributor)`: Mints a new Knowledge Unit NFT and assigns it an owner.
 * 2.  `updateKnowledgeUnitURI(uint256 _kuId, string memory _newUri)`: Allows the owner of a KU to update its metadata URI.
 * 3.  `transferKnowledgeUnit(address _from, address _to, uint256 _kuId)`: Transfers ownership of a KU NFT.
 * 4.  `approveKU(address _approved, uint256 _kuId)`: Grants approval to another address to transfer a specific KU NFT.
 * 5.  `getKnowledgeUnitOwner(uint256 _kuId) view returns (address)`: Returns the current owner of a Knowledge Unit.
 * 6.  `getKnowledgeUnitURI(uint256 _kuId) view returns (string memory)`: Returns the metadata URI associated with a Knowledge Unit.
 * 7.  `getKnowledgeUnitStatus(uint256 _kuId) view returns (bool, uint255, uint255)`: Returns validation status and vote counts for a KU.
 *
 * II. AI Pipeline (AIP) Management
 * 8.  `createAIP(string memory _name, string memory _description, uint255[] memory _kuComponentIds, uint255[] memory _aipComponentIds)`: Creates a new AI Pipeline NFT by combining existing KUs and/or other AIPs.
 * 9.  `updateAIPMetadata(uint255 _aipId, string memory _newName, string memory _newDescription)`: Allows the owner of an AIP to update its name and description.
 * 10. `getAIPComponents(uint255 _aipId) view returns (uint255[] memory, uint255[] memory)`: Retrieves the component KUs and AIPs that make up a specified AI Pipeline.
 * 11. `getAIPOwner(uint255 _aipId) view returns (address)`: Returns the current owner of an AI Pipeline.
 * 12. `transferAIP(address _from, address _to, uint255 _aipId)`: Transfers ownership of an AIP NFT.
 * 13. `setAIPShareAllocation(uint255 _aipId, address[] memory _recipients, uint255[] memory _amounts)`: Establishes initial fractional ownership shares for an AIP amongst contributors.
 * 14. `getAIPShares(uint255 _aipId, address _shareOwner) view returns (uint255)`: Returns the number of fractional shares an address holds for a given AIP.
 * 15. `transferAIPShares(uint255 _aipId, address _from, address _to, uint255 _amount)`: Allows the transfer of fractional shares for an AIP between addresses.
 *
 * III. AIP Usage & Revenue
 * 16. `setAIPUsageFee(uint255 _aipId, uint255 _feeAmount)`: Sets the price (in wei) required to use a specific AI Pipeline.
 * 17. `useAIP(uint255 _aipId, bytes32 _inputHash, bytes memory _callbackData)`: Initiates the use of an AIP. Requires payment of the usage fee and triggers an off-chain execution event.
 * 18. `processAIResult(uint255 _aipId, bytes32 _inputHash, bytes32 _outputHash, bool _isValid)`: Callable by a designated oracle to attest to the successful (or unsuccessful) off-chain execution and verification of an AIP's result.
 * 19. `updateAIPRewardAccrual(uint255 _aipId)`: Updates the global reward accrual rate for an AIP, making accumulated revenue available proportionally to shareholders. Callable by anyone.
 * 20. `claimRevenue(uint255 _aipId)`: Allows an individual fractional share owner to claim their accrued revenue from a specific AIP.
 * 21. `getAIPRevenueClaimable(uint255 _aipId, address _shareOwner) view returns (uint255)`: Returns the amount of revenue an individual share owner can claim for a given AIP.
 * 22. `setOracleAddress(address _oracleAddress)`: Sets the address of the trusted oracle for AI result verification.
 *
 * IV. Reputation & Validation
 * 23. `submitKUForValidation(uint255 _kuId)`: Submits a Knowledge Unit for community validation, opening a voting period.
 * 24. `voteOnKUQuality(uint255 _kuId, bool _isGood)`: Allows designated validators to cast a vote on the quality of a KU.
 * 25. `finalizeKUValidation(uint255 _kuId)`: Finalizes the validation status of a KU based on collected votes.
 * 26. `setValidator(address _validator, bool _status)`: Grants or revokes the `isValidator` role for an address.
 *
 * V. Administrative & Utility
 * 27. `pauseContract()`: Pauses certain sensitive functions in emergencies.
 * 28. `unpauseContract()`: Resumes functions after a pause.
 * 29. `withdrawContractBalance(address _to, uint255 _amount)`: Allows the contract owner to withdraw general contract funds.
 */

contract SynapseFabric {
    // --------------------------------------------------------------------------------
    // 1. Core State Variables
    // --------------------------------------------------------------------------------

    address private immutable _owner; // Contract deployer and admin
    bool private _paused; // Pause flag

    uint255 private _kuTokenIdCounter; // Counter for unique Knowledge Unit IDs
    uint255 private _aipTokenIdCounter; // Counter for unique AI Pipeline IDs

    // ERC-721-like mappings for Knowledge Units (KUs)
    mapping(uint255 => address) private _kuOwners;
    mapping(address => uint255) private _kuBalances;
    mapping(uint255 => address) private _kuApprovals; // approved address for a single KU

    // ERC-721-like mappings for AI Pipelines (AIPs)
    mapping(uint255 => address) private _aipOwners;
    mapping(address => uint255) private _aipBalances;
    mapping(uint255 => address) private _aipApprovals; // approved address for a single AIP

    address public oracleAddress; // Address of the trusted oracle for AI result verification

    // --------------------------------------------------------------------------------
    // 2. Structs
    // --------------------------------------------------------------------------------

    struct KnowledgeUnit {
        address owner;
        string uri; // IPFS hash or metadata URL pointing to KU specifics
        uint255 creationTime;
        bool isValidated; // True if successfully validated by community
        uint255 upvotes; // Votes for quality during validation
        uint255 downvotes; // Votes against quality during validation
    }

    struct AI_Pipeline {
        address owner;
        string name;
        string description;
        uint255[] kuComponentIds; // IDs of KnowledgeUnits composing this AIP
        uint255[] aipComponentIds; // IDs of other AI_Pipelines composing this AIP (for nested structures)
        uint255 creationTime;
        uint255 usageFee; // Fee in wei to use this AIP
        uint255 totalAccumulatedRevenue; // Total revenue collected over time for this AIP
        uint255 totalWeiPerShareAccumulated; // Accumulates total wei per share for fair distribution
        mapping(address => uint255) shares; // Fractional ownership: shareOwner => amount_of_shares
        uint255 totalSharesSupply; // Total shares minted for this AIP
        mapping(address => uint255) lastWeiPerShareClaimed; // Tracks the `totalWeiPerShareAccumulated` at last claim for each share owner
    }

    // For validation system
    struct ValidationRequest {
        uint255 kuId;
        mapping(address => bool) hasVoted; // Validator address => true if voted for this request
        uint255 upvotes;
        uint255 downvotes;
        uint255 submissionTime;
        bool finalized;
    }

    // Storage for structs
    mapping(uint255 => KnowledgeUnit) public knowledgeUnits;
    mapping(uint255 => AI_Pipeline) public aiPipelines;
    mapping(uint255 => ValidationRequest) public validationRequests;

    // Mapping for validator roles
    mapping(address => bool) public isValidator;

    // --------------------------------------------------------------------------------
    // 3. Events
    // --------------------------------------------------------------------------------

    event KnowledgeUnitRegistered(uint255 indexed kuId, address indexed owner, string uri);
    event KnowledgeUnitURIDataUpdated(uint255 indexed kuId, string newUri);
    event KnowledgeUnitTransferred(address indexed from, address indexed to, uint255 indexed kuId);
    event KnowledgeUnitApproved(address indexed approved, uint255 indexed kuId);

    event AIPCreated(uint255 indexed aipId, address indexed owner, string name);
    event AIPMetadataUpdated(uint255 indexed aipId, string newName);
    event AIPTransferred(address indexed from, address indexed to, uint255 indexed aipId);
    event AIPApproved(address indexed approved, uint255 indexed aipId);
    event AIPShareAllocationSet(uint255 indexed aipId, uint255 totalShares);
    event AIPSharesTransferred(uint255 indexed aipId, address indexed from, address indexed to, uint255 amount);

    event AIPUsageFeeSet(uint255 indexed aipId, uint255 feeAmount);
    event AIPUsed(uint255 indexed aipId, address indexed user, uint255 feePaid, bytes32 inputHash);
    event AIResultProcessed(uint255 indexed aipId, bytes32 indexed inputHash, bytes32 outputHash, bool isValid);
    event AIPRewardAccrualUpdated(uint255 indexed aipId, uint255 accruedRevenue);
    event RevenueClaimed(uint255 indexed aipId, address indexed claimant, uint255 amount);

    event KUSubmittedForValidation(uint255 indexed kuId);
    event KUVoted(uint255 indexed kuId, address indexed voter, bool isGood);
    event KUValidationFinalized(uint255 indexed kuId, bool isValidated);
    event ValidatorRoleSet(address indexed validator, bool status);

    event OracleAddressSet(address indexed newOracleAddress);
    event Paused(address account);
    event Unpaused(address account);
    event ContractBalanceWithdrawn(address indexed to, uint255 amount);

    // --------------------------------------------------------------------------------
    // 4. Modifiers
    // --------------------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == _owner, "SynapseFabric: Not contract owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "SynapseFabric: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "SynapseFabric: Contract is not paused");
        _;
    }

    modifier onlyKUNFTOwner(uint255 _kuId) {
        require(_kuOwners[_kuId] == msg.sender, "SynapseFabric: Not KU owner");
        _;
    }

    modifier onlyAIPNFTOwner(uint255 _aipId) {
        require(_aipOwners[_aipId] == msg.sender, "SynapseFabric: Not AIP owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "SynapseFabric: Not the oracle");
        _;
    }

    modifier onlyValidator() {
        require(isValidator[msg.sender], "SynapseFabric: Not a validator");
        _;
    }

    // --------------------------------------------------------------------------------
    // Constructor
    // --------------------------------------------------------------------------------

    constructor() {
        _owner = msg.sender;
        _paused = false;
        _kuTokenIdCounter = 0;
        _aipTokenIdCounter = 0;
    }

    // --------------------------------------------------------------------------------
    // Internal Helper Functions for NFT-like logic (KU & AIP)
    // --------------------------------------------------------------------------------

    function _existsKU(uint255 _kuId) internal view returns (bool) {
        return _kuOwners[_kuId] != address(0);
    }

    function _mintKU(address _to, string memory _uri) internal returns (uint255) {
        uint255 newId = ++_kuTokenIdCounter;
        _kuOwners[newId] = _to;
        _kuBalances[_to]++;
        knowledgeUnits[newId] = KnowledgeUnit({
            owner: _to,
            uri: _uri,
            creationTime: uint255(block.timestamp),
            isValidated: false,
            upvotes: 0,
            downvotes: 0
        });
        emit KnowledgeUnitRegistered(newId, _to, _uri);
        return newId;
    }

    function _transferKU(address _from, address _to, uint255 _kuId) internal {
        require(_kuOwners[_kuId] == _from, "SynapseFabric: KU transfer from wrong owner");
        require(_to != address(0), "SynapseFabric: transfer to the zero address");

        _kuBalances[_from]--;
        _kuOwners[_kuId] = _to;
        _kuBalances[_to]++;
        knowledgeUnits[_kuId].owner = _to; // Update owner in struct as well

        delete _kuApprovals[_kuId]; // Clear approval upon transfer

        emit KnowledgeUnitTransferred(_from, _to, _kuId);
    }

    function _existsAIP(uint255 _aipId) internal view returns (bool) {
        return _aipOwners[_aipId] != address(0);
    }

    function _mintAIP(address _to, string memory _name, string memory _description, uint255[] memory _kuComponentIds, uint255[] memory _aipComponentIds) internal returns (uint255) {
        uint255 newId = ++_aipTokenIdCounter;
        _aipOwners[newId] = _to;
        _aipBalances[_to]++;
        aiPipelines[newId] = AI_Pipeline({
            owner: _to,
            name: _name,
            description: _description,
            kuComponentIds: _kuComponentIds,
            aipComponentIds: _aipComponentIds,
            creationTime: uint255(block.timestamp),
            usageFee: 0,
            totalAccumulatedRevenue: 0,
            totalWeiPerShareAccumulated: 0,
            totalSharesSupply: 0
        });
        emit AIPCreated(newId, _to, _name);
        return newId;
    }

    function _transferAIP(address _from, address _to, uint255 _aipId) internal {
        require(_aipOwners[_aipId] == _from, "SynapseFabric: AIP transfer from wrong owner");
        require(_to != address(0), "SynapseFabric: transfer to the zero address");

        _aipBalances[_from]--;
        _aipOwners[_aipId] = _to;
        _aipBalances[_to]++;
        aiPipelines[_aipId].owner = _to; // Update owner in struct

        delete _aipApprovals[_aipId]; // Clear approval upon transfer

        emit AIPTransferred(_from, _to, _aipId);
    }

    // --------------------------------------------------------------------------------
    // I. Knowledge Unit (KU) Management (7 functions)
    // --------------------------------------------------------------------------------

    /**
     * @dev Mints a new Knowledge Unit NFT and assigns it an owner.
     * @param _uri The metadata URI for the Knowledge Unit (e.g., IPFS hash).
     * @param _contributor The initial owner/contributor of this KU.
     * @return The ID of the newly minted Knowledge Unit.
     */
    function registerKnowledgeUnit(string memory _uri, address _contributor)
        external
        whenNotPaused
        returns (uint255)
    {
        require(_contributor != address(0), "SynapseFabric: Contributor cannot be zero address");
        return _mintKU(_contributor, _uri);
    }

    /**
     * @dev Allows the owner of a KU to update its metadata URI.
     * @param _kuId The ID of the Knowledge Unit.
     * @param _newUri The new metadata URI.
     */
    function updateKnowledgeUnitURI(uint255 _kuId, string memory _newUri)
        external
        whenNotPaused
        onlyKUNFTOwner(_kuId)
    {
        require(_existsKU(_kuId), "SynapseFabric: KU does not exist");
        knowledgeUnits[_kuId].uri = _newUri;
        emit KnowledgeUnitURIDataUpdated(_kuId, _newUri);
    }

    /**
     * @dev Transfers ownership of a Knowledge Unit NFT.
     * The `msg.sender` must be the current owner or approved.
     * @param _from The current owner of the KU.
     * @param _to The recipient of the KU.
     * @param _kuId The ID of the Knowledge Unit to transfer.
     */
    function transferKnowledgeUnit(address _from, address _to, uint255 _kuId)
        external
        whenNotPaused
    {
        require(_existsKU(_kuId), "SynapseFabric: KU does not exist");
        require(knowledgeUnits[_kuId].owner == _from, "SynapseFabric: _from must be KU owner");
        require(msg.sender == _from || _kuApprovals[_kuId] == msg.sender, "SynapseFabric: Caller not owner nor approved");
        
        _transferKU(_from, _to, _kuId);
    }

    /**
     * @dev Grants approval to another address to transfer a specific KU NFT.
     * @param _approved The address to be approved.
     * @param _kuId The ID of the Knowledge Unit.
     */
    function approveKU(address _approved, uint255 _kuId)
        external
        whenNotPaused
        onlyKUNFTOwner(_kuId)
    {
        require(_existsKU(_kuId), "SynapseFabric: KU does not exist");
        _kuApprovals[_kuId] = _approved;
        emit KnowledgeUnitApproved(_approved, _kuId);
    }

    /**
     * @dev Returns the current owner of a Knowledge Unit.
     * @param _kuId The ID of the Knowledge Unit.
     * @return The owner's address.
     */
    function getKnowledgeUnitOwner(uint255 _kuId)
        public
        view
        returns (address)
    {
        require(_existsKU(_kuId), "SynapseFabric: KU does not exist");
        return _kuOwners[_kuId];
    }

    /**
     * @dev Returns the metadata URI associated with a Knowledge Unit.
     * @param _kuId The ID of the Knowledge Unit.
     * @return The metadata URI.
     */
    function getKnowledgeUnitURI(uint255 _kuId)
        public
        view
        returns (string memory)
    {
        require(_existsKU(_kuId), "SynapseFabric: KU does not exist");
        return knowledgeUnits[_kuId].uri;
    }

    /**
     * @dev Returns validation status and vote counts for a KU.
     * @param _kuId The ID of the Knowledge Unit.
     * @return isValidated Status, upvotes, downvotes.
     */
    function getKnowledgeUnitStatus(uint255 _kuId)
        public
        view
        returns (bool isValidated, uint255 upvotes, uint255 downvotes)
    {
        require(_existsKU(_kuId), "SynapseFabric: KU does not exist");
        KnowledgeUnit storage ku = knowledgeUnits[_kuId];
        return (ku.isValidated, ku.upvotes, ku.downvotes);
    }

    // --------------------------------------------------------------------------------
    // II. AI Pipeline (AIP) Management (8 functions)
    // --------------------------------------------------------------------------------

    /**
     * @dev Creates a new AI Pipeline NFT by combining existing KUs and/or other AIPs.
     * @param _name The name of the AI Pipeline.
     * @param _description A description of the pipeline's function.
     * @param _kuComponentIds An array of Knowledge Unit IDs to include.
     * @param _aipComponentIds An array of AI Pipeline IDs to include (for nested pipelines).
     * @return The ID of the newly created AI Pipeline.
     */
    function createAIP(
        string memory _name,
        string memory _description,
        uint255[] memory _kuComponentIds,
        uint255[] memory _aipComponentIds
    )
        external
        whenNotPaused
        returns (uint255)
    {
        require(bytes(_name).length > 0, "SynapseFabric: AIP name cannot be empty");
        // Ensure all component KUs exist
        for (uint255 i = 0; i < _kuComponentIds.length; i++) {
            require(_existsKU(_kuComponentIds[i]), "SynapseFabric: KU component does not exist");
        }
        // Ensure all component AIPs exist and prevent trivial circular dependencies
        uint255 nextAIPId = _aipTokenIdCounter + 1;
        for (uint255 i = 0; i < _aipComponentIds.length; i++) {
            require(_existsAIP(_aipComponentIds[i]), "SynapseFabric: AIP component does not exist");
            require(_aipComponentIds[i] != nextAIPId, "SynapseFabric: Cannot compose self directly");
        }

        return _mintAIP(msg.sender, _name, _description, _kuComponentIds, _aipComponentIds);
    }

    /**
     * @dev Allows the owner of an AIP to update its name and description.
     * @param _aipId The ID of the AI Pipeline.
     * @param _newName The new name for the AIP.
     * @param _newDescription The new description for the AIP.
     */
    function updateAIPMetadata(uint255 _aipId, string memory _newName, string memory _newDescription)
        external
        whenNotPaused
        onlyAIPNFTOwner(_aipId)
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        aiPipelines[_aipId].name = _newName;
        aiPipelines[_aipId].description = _newDescription;
        emit AIPMetadataUpdated(_aipId, _newName);
    }

    /**
     * @dev Retrieves the component KUs and AIPs that make up a specified AI Pipeline.
     * @param _aipId The ID of the AI Pipeline.
     * @return Two arrays: one for KU component IDs and one for AIP component IDs.
     */
    function getAIPComponents(uint255 _aipId)
        public
        view
        returns (uint255[] memory, uint255[] memory)
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        return (aiPipelines[_aipId].kuComponentIds, aiPipelines[_aipId].aipComponentIds);
    }

    /**
     * @dev Returns the current owner of an AI Pipeline.
     * @param _aipId The ID of the AI Pipeline.
     * @return The owner's address.
     */
    function getAIPOwner(uint255 _aipId)
        public
        view
        returns (address)
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        return _aipOwners[_aipId];
    }

    /**
     * @dev Transfers ownership of an AIP NFT.
     * The `msg.sender` must be the current owner or approved.
     * @param _from The current owner of the AIP.
     * @param _to The recipient of the AIP.
     * @param _aipId The ID of the AI Pipeline to transfer.
     */
    function transferAIP(address _from, address _to, uint255 _aipId)
        external
        whenNotPaused
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        require(aiPipelines[_aipId].owner == _from, "SynapseFabric: _from must be AIP owner");
        require(msg.sender == _from || _aipApprovals[_aipId] == msg.sender, "SynapseFabric: Caller not owner nor approved");

        _transferAIP(_from, _to, _aipId);
    }

    /**
     * @dev Establishes initial fractional ownership shares for an AIP amongst contributors.
     * Callable only by the AIP owner. Total shares are distributed.
     * @param _aipId The ID of the AI Pipeline.
     * @param _recipients An array of addresses to receive shares.
     * @param _amounts An array of share amounts corresponding to recipients.
     */
    function setAIPShareAllocation(uint255 _aipId, address[] memory _recipients, uint255[] memory _amounts)
        external
        whenNotPaused
        onlyAIPNFTOwner(_aipId)
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        require(_recipients.length == _amounts.length, "SynapseFabric: Recipient and amount arrays must match length");
        require(aiPipelines[_aipId].totalSharesSupply == 0, "SynapseFabric: Shares already allocated for this AIP");

        uint255 totalAllocatedShares = 0;
        for (uint255 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "SynapseFabric: Recipient cannot be zero address");
            require(_amounts[i] > 0, "SynapseFabric: Share amount must be positive");
            aiPipelines[_aipId].shares[_recipients[i]] += _amounts[i];
            totalAllocatedShares += _amounts[i];
        }
        aiPipelines[_aipId].totalSharesSupply = totalAllocatedShares;
        emit AIPShareAllocationSet(_aipId, totalAllocatedShares);
    }

    /**
     * @dev Returns the number of fractional shares an address holds for a given AIP.
     * @param _aipId The ID of the AI Pipeline.
     * @param _shareOwner The address whose shares are queried.
     * @return The number of shares owned.
     */
    function getAIPShares(uint255 _aipId, address _shareOwner)
        public
        view
        returns (uint255)
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        return aiPipelines[_aipId].shares[_shareOwner];
    }

    /**
     * @dev Allows the transfer of fractional shares for an AIP between addresses.
     * @param _aipId The ID of the AI Pipeline.
     * @param _from The sender of the shares.
     * @param _to The recipient of the shares.
     * @param _amount The number of shares to transfer.
     */
    function transferAIPShares(uint255 _aipId, address _from, address _to, uint255 _amount)
        external
        whenNotPaused
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        require(aiPipelines[_aipId].shares[_from] >= _amount, "SynapseFabric: Insufficient shares");
        require(_to != address(0), "SynapseFabric: Cannot transfer to zero address");
        require(msg.sender == _from, "SynapseFabric: Caller not share owner"); // Simplified, no approve for shares
        
        aiPipelines[_aipId].shares[_from] -= _amount;
        aiPipelines[_aipId].shares[_to] += _amount;
        emit AIPSharesTransferred(_aipId, _from, _to, _amount);
    }

    // --------------------------------------------------------------------------------
    // III. AIP Usage & Revenue (7 functions including setOracleAddress)
    // --------------------------------------------------------------------------------

    /**
     * @dev Sets the price (in wei) required to use a specific AI Pipeline.
     * Callable only by the AIP owner.
     * @param _aipId The ID of the AI Pipeline.
     * @param _feeAmount The new usage fee in wei.
     */
    function setAIPUsageFee(uint255 _aipId, uint255 _feeAmount)
        external
        whenNotPaused
        onlyAIPNFTOwner(_aipId)
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        aiPipelines[_aipId].usageFee = _feeAmount;
        emit AIPUsageFeeSet(_aipId, _feeAmount);
    }

    /**
     * @dev Initiates the use of an AIP. Requires payment of the usage fee and
     * logs an event for off-chain execution.
     * @param _aipId The ID of the AI Pipeline to use.
     * @param _inputHash A hash of the input data for the off-chain AI execution.
     * @param _callbackData Any data required by the off-chain system for callback/identification.
     */
    function useAIP(uint255 _aipId, bytes32 _inputHash, bytes memory _callbackData)
        external
        payable
        whenNotPaused
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        AI_Pipeline storage aip = aiPipelines[_aipId];
        require(msg.value >= aip.usageFee, "SynapseFabric: Insufficient payment for AIP usage");

        // Refund any excess payment
        if (msg.value > aip.usageFee) {
            payable(msg.sender).transfer(msg.value - aip.usageFee);
        }

        aip.totalAccumulatedRevenue += aip.usageFee; // Add to overall pool

        emit AIPUsed(_aipId, msg.sender, aip.usageFee, _inputHash);

        // Here, an off-chain system would listen for AIPUsed event,
        // perform the AI computation, and then call processAIResult via oracle.
    }

    /**
     * @dev Callable by a designated oracle to attest to the successful (or unsuccessful)
     * off-chain execution and verification of an AIP's result.
     * @param _aipId The ID of the AI Pipeline.
     * @param _inputHash The hash of the input data that was used.
     * @param _outputHash The hash of the output result from the AI execution.
     * @param _isValid True if the AI execution and result are verified as valid.
     */
    function processAIResult(uint255 _aipId, bytes32 _inputHash, bytes32 _outputHash, bool _isValid)
        external
        onlyOracle
        whenNotPaused
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        // Further logic could be added here, e.g., slashing for invalid results,
        // or triggering events based on _isValid for specific applications.
        emit AIResultProcessed(_aipId, _inputHash, _outputHash, _isValid);
    }

    /**
     * @dev Updates the global reward accrual rate for an AIP, making accumulated
     * revenue available proportionally to shareholders. Callable by anyone.
     * This function "snapshots" the current revenue into the `totalWeiPerShareAccumulated` pool.
     * @param _aipId The ID of the AI Pipeline.
     */
    function updateAIPRewardAccrual(uint255 _aipId)
        external
        whenNotPaused
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        AI_Pipeline storage aip = aiPipelines[_aipId];
        require(aip.totalSharesSupply > 0, "SynapseFabric: No shares allocated for this AIP");

        uint255 revenueToAccrue = aip.totalAccumulatedRevenue;
        if (revenueToAccrue == 0) {
            return; // No new revenue to accrue
        }

        aip.totalAccumulatedRevenue = 0; // Clear for next cycle

        // Update the per-share accumulator. Scaling by 1e18 to maintain precision
        // Prevents floating point issues and ensures fair distribution to all shares.
        aip.totalWeiPerShareAccumulated += (revenueToAccrue * 1e18) / aip.totalSharesSupply;

        emit AIPRewardAccrualUpdated(_aipId, revenueToAccrue);
    }

    /**
     * @dev Allows an individual fractional share owner to claim their accrued revenue from a specific AIP.
     * This follows a pull-based reward distribution model.
     * @param _aipId The ID of the AI Pipeline.
     */
    function claimRevenue(uint255 _aipId)
        external
        whenNotPaused
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        AI_Pipeline storage aip = aiPipelines[_aipId];
        uint255 userShares = aip.shares[msg.sender];
        require(userShares > 0, "SynapseFabric: Caller has no shares");

        // Calculate pending rewards based on current `totalWeiPerShareAccumulated`
        uint255 pendingRewardWeiPerShare = aip.totalWeiPerShareAccumulated - aip.lastWeiPerShareClaimed[msg.sender];
        uint255 claimableAmount = (userShares * pendingRewardWeiPerShare) / 1e18; // Scale back down

        require(claimableAmount > 0, "SynapseFabric: No revenue to claim");

        aip.lastWeiPerShareClaimed[msg.sender] = aip.totalWeiPerShareAccumulated; // Update claimed state

        // Transfer the revenue
        payable(msg.sender).transfer(claimableAmount);
        emit RevenueClaimed(_aipId, msg.sender, claimableAmount);
    }

    /**
     * @dev Returns the amount of revenue an individual share owner can claim for a given AIP.
     * @param _aipId The ID of the AI Pipeline.
     * @param _shareOwner The address of the share owner.
     * @return The amount of claimable revenue in wei.
     */
    function getAIPRevenueClaimable(uint255 _aipId, address _shareOwner)
        public
        view
        returns (uint255)
    {
        require(_existsAIP(_aipId), "SynapseFabric: AIP does not exist");
        AI_Pipeline storage aip = aiPipelines[_aipId];
        uint255 userShares = aip.shares[_shareOwner];
        if (userShares == 0) {
            return 0;
        }

        uint255 pendingRewardWeiPerShare = aip.totalWeiPerShareAccumulated - aip.lastWeiPerShareClaimed[_shareOwner];
        return (userShares * pendingRewardWeiPerShare) / 1e18;
    }

    /**
     * @dev Sets the address of the trusted oracle. Only callable by the contract owner.
     * @param _oracleAddress The address of the oracle.
     */
    function setOracleAddress(address _oracleAddress)
        external
        onlyOwner
    {
        require(_oracleAddress != address(0), "SynapseFabric: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    // --------------------------------------------------------------------------------
    // IV. Reputation & Validation (4 functions)
    // --------------------------------------------------------------------------------

    /**
     * @dev Submits a Knowledge Unit for community validation, opening a voting period.
     * The KU owner initiates this to seek validation.
     * @param _kuId The ID of the Knowledge Unit to validate.
     */
    function submitKUForValidation(uint255 _kuId)
        external
        whenNotPaused
        onlyKUNFTOwner(_kuId)
    {
        require(_existsKU(_kuId), "SynapseFabric: KU does not exist");
        require(!knowledgeUnits[_kuId].isValidated, "SynapseFabric: KU already validated");
        require(validationRequests[_kuId].submissionTime == 0, "SynapseFabric: KU already in validation process");

        validationRequests[_kuId] = ValidationRequest({
            kuId: _kuId,
            upvotes: 0,
            downvotes: 0,
            submissionTime: uint255(block.timestamp),
            finalized: false
            // hasVoted mapping is initialized implicitly for new struct
        });
        emit KUSubmittedForValidation(_kuId);
    }

    /**
     * @dev Allows designated validators to cast a vote on the quality of a KU.
     * Simplified: No voting power/weight, just a simple vote count.
     * @param _kuId The ID of the Knowledge Unit.
     * @param _isGood True for an upvote, false for a downvote.
     */
    function voteOnKUQuality(uint255 _kuId, bool _isGood)
        external
        whenNotPaused
        onlyValidator
    {
        require(_existsKU(_kuId), "SynapseFabric: KU does not exist");
        ValidationRequest storage req = validationRequests[_kuId];
        require(req.submissionTime > 0, "SynapseFabric: KU not submitted for validation");
        require(!req.finalized, "SynapseFabric: Validation period ended");
        require(!req.hasVoted[msg.sender], "SynapseFabric: Already voted on this KU");

        if (_isGood) {
            req.upvotes++;
        } else {
            req.downvotes++;
        }
        req.hasVoted[msg.sender] = true;
        emit KUVoted(_kuId, msg.sender, _isGood);
    }

    /**
     * @dev Finalizes the validation status of a KU based on collected votes.
     * Can be called by anyone after a "voting period" (not enforced here, could add time-based check).
     * Simple majority rule: more upvotes than downvotes means valid.
     * @param _kuId The ID of the Knowledge Unit.
     */
    function finalizeKUValidation(uint255 _kuId)
        external
        whenNotPaused
    {
        require(_existsKU(_kuId), "SynapseFabric: KU does not exist");
        ValidationRequest storage req = validationRequests[_kuId];
        require(req.submissionTime > 0, "SynapseFabric: KU not submitted for validation");
        require(!req.finalized, "SynapseFabric: Validation already finalized");
        // Optional: require(block.timestamp > req.submissionTime + VALIDATION_PERIOD, "Voting period not over");

        req.finalized = true;
        bool isValid = req.upvotes > req.downvotes;
        knowledgeUnits[_kuId].isValidated = isValid;
        knowledgeUnits[_kuId].upvotes = req.upvotes; // Store final votes in KU struct
        knowledgeUnits[_kuId].downvotes = req.downvotes;
        emit KUValidationFinalized(_kuId, isValid);

        // Optional: delete validationRequests[_kuId]; // To clear storage and save gas, if history is not needed on-chain
    }

    /**
     * @dev Grants or revokes the `isValidator` role for an address. Only contract owner can call.
     * Validators participate in the KU quality voting process.
     * @param _validator The address to set/unset as validator.
     * @param _status True to grant, false to revoke.
     */
    function setValidator(address _validator, bool _status)
        external
        onlyOwner
        whenNotPaused
    {
        require(_validator != address(0), "SynapseFabric: Validator address cannot be zero");
        isValidator[_validator] = _status;
        emit ValidatorRoleSet(_validator, _status);
    }

    // --------------------------------------------------------------------------------
    // V. Administrative & Utility (3 functions)
    // --------------------------------------------------------------------------------

    /**
     * @dev Pauses certain sensitive functions in emergencies. Only contract owner can call.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Resumes functions after a pause. Only contract owner can call.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw funds from the contract's balance.
     * This is for scenarios like upgrading the contract, or collecting treasury.
     * Does not affect AIP accumulated revenue, only general contract ETH balance.
     * It's made safer by only allowing withdrawal when the contract is paused.
     * @param _to The address to send the funds to.
     * @param _amount The amount of wei to withdraw.
     */
    function withdrawContractBalance(address _to, uint255 _amount)
        external
        onlyOwner
        whenPaused // Can only withdraw when paused (safer for a contract potentially holding funds)
    {
        require(_to != address(0), "SynapseFabric: Target address cannot be zero");
        require(address(this).balance >= _amount, "SynapseFabric: Insufficient contract balance");
        payable(_to).transfer(_amount);
        emit ContractBalanceWithdrawn(_to, _amount);
    }

    // Fallback function to receive Ether (e.g., for direct deposits or refunds)
    receive() external payable {}
}
```