Okay, this is an exciting challenge! Let's design a smart contract called "ChronoForge" that focuses on the concept of *temporal logic, programmable scarcity, and self-evolving digital entities*, leveraging dynamic NFTs and an on-chain factory pattern.

The core idea is that users can "forge" new, time-activated smart contracts (Temporal Manifestations) from "Temporal Blueprint" NFTs, where the characteristics of the forged contract are derived from the NFT's parameters and evolve over time, potentially influencing future blueprints.

---

## ChronoForge: The Temporal Logic Forge

**Contract Name:** `ChronoForge`

**Core Concept:** `ChronoForge` is a decentralized protocol that enables the creation and management of *Temporal Blueprints* (dynamic ERC-721 NFTs) which act as schematics for deploying *Temporal Manifestations* (specialized, time-gated smart contracts). These Manifestations have logic that can activate, evolve, or decay based on defined temporal conditions, oracle feeds, or community governance. The system includes a sophisticated governance model for its own evolution and a feedback loop to influence future Blueprint generation.

---

### **Outline and Function Summary:**

**I. Core Infrastructure & Access Control**
*   **Purpose:** Setup, pausing, and defining administrative roles.
*   `constructor()`: Initializes the contract with an owner.
*   `pause()`: Pauses core functionality in emergencies.
*   `unpause()`: Unpauses core functionality.
*   `transferOwnership()`: Transfers contract ownership.
*   `addGovernor()`: Grants a governor role (for governance proposals).
*   `removeGovernor()`: Revokes a governor role.
*   `addOracle()`: Whitelists an address as an oracle (for external data feeds).
*   `removeOracle()`: Removes an oracle.

**II. Temporal Blueprint (ERC-721) Management**
*   **Purpose:** Functions related to the `TemporalBlueprint` NFTs. These are the "schematics."
*   `mintTemporalBlueprint()`: Mints a new TBP NFT with initial, mutable parameters.
*   `updateBlueprintMetadata()`: Allows TBP owner to update its URI.
*   `setBlueprintMaturityThreshold()`: Sets the time (in seconds from forge time) for a TBP to "mature," unlocking advanced features for its Manifestations.
*   `deactivateBlueprint()`: Governance can deactivate a TBP, preventing new Manifestations from it.
*   `lockBlueprintForForging()`: Locks a TBP, signaling its intent to be used for forging.
*   `unlockBlueprint()`: Unlocks a TBP, returning it to the owner.

**III. Temporal Manifestation (Contract Factory) & Registry**
*   **Purpose:** Functions for deploying and managing `Temporal Manifestation` sub-contracts. These are the "products."
*   `registerTemporalModule()`: Admin function to register pre-audited contract bytecode modules that can be deployed as Manifestations.
*   `deregisterTemporalModule()`: Admin function to remove a module.
*   `forgeTemporalManifestation()`: The core factory function. Deploys a new `TemporalManifestation` contract based on a locked `TemporalBlueprint` and a registered module.
*   `getManifestationDetails()`: Retrieves details of a deployed `TemporalManifestation`.
*   `registerManifestationFeedback()`: Allows Oracles or the Manifestation itself to submit feedback (e.g., performance metrics, state changes) to influence future blueprints or governance.

**IV. Governance & Protocol Evolution**
*   **Purpose:** Decentralized decision-making and protocol self-amendment.
*   `proposeParameterChange()`: Governors can propose changes to core `ChronoForge` parameters (e.g., forge fee, blueprint mint cost).
*   `voteOnProposal()`: Registered governors vote on active proposals.
*   `executeProposal()`: Executes a successful proposal after the voting period ends.
*   `updateCoreParameter()`: Internal/callable by `executeProposal` to modify contract parameters.

**V. Financials & Rewards**
*   **Purpose:** Managing fees and reward distribution.
*   `setBaseForgeFee()`: Sets the base fee for forging a Manifestation.
*   `setBlueprintMintCost()`: Sets the cost to mint a new Blueprint NFT.
*   `getContractBalance()`: Returns the contract's ETH balance.
*   `withdrawFunds()`: Allows governors (via proposal) to withdraw funds to a treasury.
*   `claimForgingRewards()`: A hypothetical function (could be implemented as part of a staking mechanism) to claim rewards for successful forging.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Custom Errors for Gas Efficiency ---
error ChronoForge__NotGovernor();
error ChronoForge__NotOracle();
error ChronoForge__ContractPaused();
error ChronoForge__ContractNotPaused();
error ChronoForge__Unauthorized();
error ChronoForge__InvalidBlueprintID();
error ChronoForge__BlueprintNotOwned();
error ChronoForge__BlueprintLockedForForging();
error ChronoForge__BlueprintNotLocked();
error ChronoForge__BlueprintAlreadyActive();
error ChronoForge__BlueprintDeactivated();
error ChronoForge__InsufficientForgeFee();
error ChronoForge__InvalidModuleID();
error ChronoForge__ModuleNotRegistered();
error ChronoForge__ModuleAlreadyRegistered();
error ChronoForge__ModuleDeploymentFailed();
error ChronoForge__ProposalAlreadyExists();
error ChronoForge__ProposalNotFound();
error ChronoForge__VotingPeriodActive();
error ChronoForge__VotingPeriodEnded();
error ChronoForge__ProposalNotExecutable();
error ChronoForge__AlreadyVoted();
error ChronoForge__InvalidMintCost();
error ChronoForge__InsufficientMintPayment();
error ChronoForge__NoFundsToWithdraw();


/**
 * @title ChronoForge
 * @dev A smart contract factory for creating time-activated digital entities (Temporal Manifestations)
 *      from dynamic ERC-721 NFTs (Temporal Blueprints), incorporating governance and feedback loops.
 */
contract ChronoForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Address for address;

    // --- State Variables ---

    Counters.Counter private _blueprintTokenIds; // NFT counter for Temporal Blueprints

    struct TemporalBlueprint {
        uint256 tokenId;
        address owner;
        uint256 creationTime; // Timestamp of blueprint creation
        uint256 maturityThreshold; // Time in seconds from creation for blueprint to mature
        bool isActive; // Can new manifestations be forged from this blueprint?
        bool isLockedForForging; // Is the blueprint currently locked for forging a manifestation?
        string uri; // Metadata URI for the blueprint NFT
        // Add more complex, mutable parameters here that define the "essence" of the blueprint
        // These could be arrays of uints, bytes32, or even a struct hash reference.
        // For simplicity, let's use a dynamic bytes array for raw parameters.
        bytes blueprintParameters;
    }

    mapping(uint256 => TemporalBlueprint) public temporalBlueprints;
    mapping(uint256 => address[]) public blueprintManifestations; // blueprintId => list of deployed manifestation addresses

    struct TemporalManifestationDetails {
        address manifestationAddress;
        uint256 blueprintId;
        uint256 forgeTime; // Timestamp when manifestation was forged
        uint256 moduleId; // ID of the module used to create this manifestation
        // Add other relevant details like initial state, derived parameters, etc.
        bytes initialDerivedParameters;
    }

    mapping(address => TemporalManifestationDetails) public temporalManifestations;

    // Registered modules for contract deployment (pre-audited bytecode/logic)
    struct TemporalModule {
        uint256 id;
        string name;
        bytes creationBytecode; // The bytecode for the contract to be deployed
        bool isActive;
    }
    mapping(uint256 => TemporalModule) public temporalModules;
    mapping(string => uint256) private _moduleNameToId; // Map module name to ID
    Counters.Counter private _moduleIds;

    // --- Access Control Roles ---
    mapping(address => bool) public isGovernor;
    mapping(address => bool) public isOracle;

    // --- Governance System ---
    struct Proposal {
        uint256 id;
        bytes32 descriptionHash; // Hash of the proposal's description
        address proposer;
        uint256 votingDeadline; // Timestamp when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        // Parameter for change: represents a key-value pair to update in the contract
        bytes32 paramNameHash; // E.g., keccak256("baseForgeFee")
        bytes paramValue;      // New value for the parameter
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted; // governor => proposalId => voted
    Counters.Counter private _proposalIds;
    uint256 public votingPeriodDuration = 3 days; // Default voting period

    // --- Protocol Parameters (modifiable via governance) ---
    uint256 public baseForgeFee = 0.05 ether; // Fee to forge a new manifestation
    uint256 public blueprintMintCost = 0.1 ether; // Cost to mint a new blueprint NFT

    // --- Events ---
    event BlueprintMinted(uint255 indexed tokenId, address indexed owner, uint256 creationTime, string uri, bytes parameters);
    event BlueprintMetadataUpdated(uint256 indexed tokenId, string newUri);
    event BlueprintMaturitySet(uint256 indexed tokenId, uint256 maturityThreshold);
    event BlueprintDeactivated(uint256 indexed tokenId);
    event BlueprintLocked(uint256 indexed tokenId);
    event BlueprintUnlocked(uint256 indexed tokenId);

    event TemporalModuleRegistered(uint256 indexed moduleId, string name, address indexed creator);
    event TemporalModuleDeregistered(uint256 indexed moduleId);

    event TemporalManifestationForged(
        address indexed manifestationAddress,
        uint256 indexed blueprintId,
        uint256 indexed moduleId,
        address indexed forger,
        uint256 forgeTime,
        bytes initialDerivedParameters
    );
    event ManifestationFeedbackReceived(address indexed manifestationAddress, bytes32 indexed feedbackType, bytes feedbackData);

    event GovernorAdded(address indexed governor);
    event GovernorRemoved(address indexed governor);
    event OracleAdded(address indexed oracle);
    event OracleRemoved(address indexed oracle);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 descriptionHash, uint256 votingDeadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event CoreParameterUpdated(bytes32 indexed paramNameHash, bytes newValue);

    constructor() ERC721("TemporalBlueprint", "TBP") Ownable(msg.sender) Pausable() {
        // Initial owner is also the first governor and oracle for setup
        isGovernor[msg.sender] = true;
        isOracle[msg.sender] = true;
        emit GovernorAdded(msg.sender);
        emit OracleAdded(msg.sender);
    }

    // --- I. Core Infrastructure & Access Control ---

    modifier onlyGovernor() {
        if (!isGovernor[msg.sender]) revert ChronoForge__NotGovernor();
        _;
    }

    modifier onlyOracle() {
        if (!isOracle[msg.sender]) revert ChronoForge__NotOracle();
        _;
    }

    // `pause()` and `unpause()` are inherited from Pausable.
    function pause() public onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /**
     * @dev Adds an address as a governor. Governors can create and vote on proposals.
     * @param _governor The address to grant governor role.
     */
    function addGovernor(address _governor) public onlyOwner {
        if (_governor == address(0)) revert ChronoForge__Unauthorized(); // Using common error, specific can be added
        isGovernor[_governor] = true;
        emit GovernorAdded(_governor);
    }

    /**
     * @dev Removes an address from the governor role.
     * @param _governor The address to revoke governor role from.
     */
    function removeGovernor(address _governor) public onlyOwner {
        if (_governor == address(0)) revert ChronoForge__Unauthorized();
        isGovernor[_governor] = false;
        emit GovernorRemoved(_governor);
    }

    /**
     * @dev Adds an address as an oracle. Oracles can submit feedback.
     * @param _oracle The address to grant oracle role.
     */
    function addOracle(address _oracle) public onlyOwner {
        if (_oracle == address(0)) revert ChronoForge__Unauthorized();
        isOracle[_oracle] = true;
        emit OracleAdded(_oracle);
    }

    /**
     * @dev Removes an address from the oracle role.
     * @param _oracle The address to revoke oracle role from.
     */
    function removeOracle(address _oracle) public onlyOwner {
        if (_oracle == address(0)) revert ChronoForge__Unauthorized();
        isOracle[_oracle] = false;
        emit OracleRemoved(_oracle);
    }


    // --- II. Temporal Blueprint (ERC-721) Management ---

    /**
     * @dev Mints a new Temporal Blueprint NFT.
     * @param _uri The metadata URI for the blueprint.
     * @param _initialParameters Initial byte-encoded parameters for the blueprint.
     * @return The tokenId of the newly minted blueprint.
     */
    function mintTemporalBlueprint(string memory _uri, bytes memory _initialParameters)
        public
        payable
        whenNotPaused
        returns (uint256)
    {
        if (msg.value < blueprintMintCost) revert ChronoForge__InsufficientMintPayment();

        _blueprintTokenIds.increment();
        uint256 newItemId = _blueprintTokenIds.current();

        temporalBlueprints[newItemId] = TemporalBlueprint({
            tokenId: newItemId,
            owner: msg.sender,
            creationTime: block.timestamp,
            maturityThreshold: 0, // Default to 0, can be set later
            isActive: true,
            isLockedForForging: false,
            uri: _uri,
            blueprintParameters: _initialParameters
        });

        _mint(msg.sender, newItemId);
        emit BlueprintMinted(newItemId, msg.sender, block.timestamp, _uri, _initialParameters);
        return newItemId;
    }

    /**
     * @dev Allows the owner of a TBP to update its metadata URI.
     * @param _tokenId The ID of the blueprint NFT.
     * @param _newUri The new metadata URI.
     */
    function updateBlueprintMetadata(uint256 _tokenId, string memory _newUri)
        public
        whenNotPaused
    {
        if (ownerOf(_tokenId) != msg.sender) revert ChronoForge__BlueprintNotOwned();
        temporalBlueprints[_tokenId].uri = _newUri;
        emit BlueprintMetadataUpdated(_tokenId, _newUri);
    }

    /**
     * @dev Sets the maturity threshold for a Temporal Blueprint.
     *      Manifestations forged from a mature blueprint might unlock advanced features.
     * @param _tokenId The ID of the blueprint NFT.
     * @param _maturityThreshold The time in seconds from creation time for the blueprint to be considered mature.
     */
    function setBlueprintMaturityThreshold(uint256 _tokenId, uint256 _maturityThreshold)
        public
        whenNotPaused
    {
        if (ownerOf(_tokenId) != msg.sender) revert ChronoForge__BlueprintNotOwned();
        temporalBlueprints[_tokenId].maturityThreshold = _maturityThreshold;
        emit BlueprintMaturitySet(_tokenId, _maturityThreshold);
    }

    /**
     * @dev Deactivates a Temporal Blueprint, preventing new Manifestations from being forged from it.
     *      This is a governance-controlled function, perhaps after a proposal vote.
     * @param _tokenId The ID of the blueprint NFT.
     */
    function deactivateBlueprint(uint256 _tokenId) public onlyGovernor whenNotPaused {
        if (!temporalBlueprints[_tokenId].isActive) revert ChronoForge__BlueprintDeactivated();
        temporalBlueprints[_tokenId].isActive = false;
        emit BlueprintDeactivated(_tokenId);
    }

    /**
     * @dev Locks a Temporal Blueprint, signaling it's being prepared for forging.
     *      Transfers the NFT to the ChronoForge contract temporarily.
     * @param _tokenId The ID of the blueprint NFT.
     */
    function lockBlueprintForForging(uint256 _tokenId) public whenNotPaused {
        if (ownerOf(_tokenId) != msg.sender) revert ChronoForge__BlueprintNotOwned();
        if (temporalBlueprints[_tokenId].isLockedForForging) revert ChronoForge__BlueprintLockedForForging();

        _transfer(msg.sender, address(this), _tokenId);
        temporalBlueprints[_tokenId].isLockedForForging = true;
        emit BlueprintLocked(_tokenId);
    }

    /**
     * @dev Unlocks a Temporal Blueprint, returning it to its original owner.
     *      Only callable by the original owner if not currently in a forging process.
     * @param _tokenId The ID of the blueprint NFT.
     */
    function unlockBlueprint(uint256 _tokenId) public whenNotPaused {
        // Ensure blueprint is locked and the caller is the original owner
        if (ownerOf(_tokenId) != address(this)) revert ChronoForge__BlueprintNotLocked();
        if (temporalBlueprints[_tokenId].owner != msg.sender) revert ChronoForge__BlueprintNotOwned(); // Original owner check

        temporalBlueprints[_tokenId].isLockedForForging = false;
        _transfer(address(this), msg.sender, _tokenId); // Transfer back to original owner
        emit BlueprintUnlocked(_tokenId);
    }


    // --- III. Temporal Manifestation (Contract Factory) & Registry ---

    /**
     * @dev Registers a new Temporal Module (bytecode for a deployable contract).
     *      Only callable by the contract owner.
     * @param _name A unique name for the module.
     * @param _creationBytecode The compiled bytecode of the contract to be deployed.
     */
    function registerTemporalModule(string memory _name, bytes memory _creationBytecode)
        public
        onlyOwner
        whenNotPaused
    {
        if (_moduleNameToId[_name] != 0) revert ChronoForge__ModuleAlreadyRegistered(); // Ensure unique name

        _moduleIds.increment();
        uint256 newModuleId = _moduleIds.current();
        temporalModules[newModuleId] = TemporalModule({
            id: newModuleId,
            name: _name,
            creationBytecode: _creationBytecode,
            isActive: true
        });
        _moduleNameToId[_name] = newModuleId;
        emit TemporalModuleRegistered(newModuleId, _name, msg.sender);
    }

    /**
     * @dev Deactivates a registered Temporal Module.
     *      Only callable by the contract owner.
     * @param _moduleId The ID of the module to deactivate.
     */
    function deregisterTemporalModule(uint256 _moduleId) public onlyOwner {
        if (temporalModules[_moduleId].id == 0) revert ChronoForge__InvalidModuleID();
        temporalModules[_moduleId].isActive = false; // Mark as inactive
        emit TemporalModuleDeregistered(_moduleId);
    }

    /**
     * @dev Forges and deploys a new Temporal Manifestation contract.
     *      Requires a locked Temporal Blueprint and a registered Temporal Module.
     * @param _blueprintId The ID of the locked Temporal Blueprint NFT.
     * @param _moduleId The ID of the Temporal Module to use for deployment.
     * @param _constructorArgs A byte-encoded packed list of constructor arguments for the deployed contract.
     * @return The address of the newly deployed Temporal Manifestation contract.
     */
    function forgeTemporalManifestation(
        uint256 _blueprintId,
        uint256 _moduleId,
        bytes memory _constructorArgs
    ) public payable whenNotPaused returns (address) {
        // 1. Validate Blueprint
        TemporalBlueprint storage blueprint = temporalBlueprints[_blueprintId];
        if (blueprint.tokenId == 0) revert ChronoForge__InvalidBlueprintID();
        if (ownerOf(_blueprintId) != address(this) || !blueprint.isLockedForForging) {
            revert ChronoForge__BlueprintNotLocked();
        }
        if (!blueprint.isActive) revert ChronoForge__BlueprintDeactivated();
        // Blueprint is consumed in this process, it remains locked (or can be burned / transferred to a "forged" state)
        // For simplicity, it stays locked, indicating it has "parented" a manifestation.

        // 2. Validate Module
        TemporalModule storage module = temporalModules[_moduleId];
        if (module.id == 0 || !module.isActive) revert ChronoForge__ModuleNotRegistered();

        // 3. Validate Fees
        if (msg.value < baseForgeFee) revert ChronoForge__InsufficientForgeFee();

        // 4. Derive initial parameters for the new Manifestation
        // This is a placeholder for complex logic. For example, some parameters
        // could be derived directly from `blueprint.blueprintParameters`,
        // others could be adjusted based on `block.timestamp` vs `blueprint.maturityThreshold`,
        // or even by a specific `_constructorArgs` interpretation.
        // For demonstration, let's just pass the blueprint's parameters directly.
        bytes memory derivedParams = blueprint.blueprintParameters;

        // 5. Deploy the new Temporal Manifestation contract using the module's bytecode
        address manifestationAddr;
        bytes memory bytecodeWithArgs = abi.encodePacked(module.creationBytecode, _constructorArgs);

        assembly {
            manifestationAddr := create(0, add(bytecodeWithArgs, 0x20), mload(bytecodeWithArgs))
        }

        if (manifestationAddr == address(0)) revert ChronoForge__ModuleDeploymentFailed();

        // 6. Register the new Manifestation
        temporalManifestations[manifestationAddr] = TemporalManifestationDetails({
            manifestationAddress: manifestationAddr,
            blueprintId: _blueprintId,
            forgeTime: block.timestamp,
            moduleId: _moduleId,
            initialDerivedParameters: derivedParams
        });
        blueprintManifestations[_blueprintId].push(manifestationAddr);

        // 7. Emit Event
        emit TemporalManifestationForged(
            manifestationAddr,
            _blueprintId,
            _moduleId,
            msg.sender,
            block.timestamp,
            derivedParams
        );

        return manifestationAddr;
    }

    /**
     * @dev Retrieves details of a deployed Temporal Manifestation.
     * @param _manifestationAddress The address of the Manifestation contract.
     * @return A struct containing the manifestation's details.
     */
    function getManifestationDetails(address _manifestationAddress)
        public
        view
        returns (TemporalManifestationDetails memory)
    {
        return temporalManifestations[_manifestationAddress];
    }

    /**
     * @dev Allows whitelisted Oracles (or the Manifestation itself if coded) to submit feedback.
     *      This feedback could influence future blueprint parameter generation or governance proposals.
     * @param _manifestationAddress The address of the Manifestation providing feedback.
     * @param _feedbackType A hash identifying the type of feedback (e.g., performance, state change).
     * @param _feedbackData Raw data of the feedback.
     */
    function registerManifestationFeedback(
        address _manifestationAddress,
        bytes32 _feedbackType,
        bytes memory _feedbackData
    ) public onlyOracle whenNotPaused {
        if (temporalManifestations[_manifestationAddress].manifestationAddress == address(0)) {
            revert ChronoForge__InvalidBlueprintID(); // Using a generic error, could be more specific
        }
        // In a real system, this feedback would trigger off-chain processing or on-chain state updates
        // that could influence future blueprint minting or governance decisions.
        emit ManifestationFeedbackReceived(_manifestationAddress, _feedbackType, _feedbackData);
    }


    // --- IV. Governance & Protocol Evolution ---

    /**
     * @dev Allows governors to propose changes to core ChronoForge parameters.
     * @param _descriptionHash A hash of the proposal's detailed description (e.g., IPFS hash).
     * @param _paramNameHash The keccak256 hash of the parameter name to change (e.g., keccak256("baseForgeFee")).
     * @param _paramValue The new value for the parameter, encoded as bytes.
     */
    function proposeParameterChange(
        bytes32 _descriptionHash,
        bytes32 _paramNameHash,
        bytes memory _paramValue
    ) public onlyGovernor whenNotPaused returns (uint256) {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            descriptionHash: _descriptionHash,
            proposer: msg.sender,
            votingDeadline: block.timestamp + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            paramNameHash: _paramNameHash,
            paramValue: _paramValue
        });

        emit ProposalCreated(proposalId, msg.sender, _descriptionHash, proposals[proposalId].votingDeadline);
        return proposalId;
    }

    /**
     * @dev Allows governors to vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "for", false for "against".
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyGovernor whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ChronoForge__ProposalNotFound();
        if (block.timestamp >= proposal.votingDeadline) revert ChronoForge__VotingPeriodEnded();
        if (hasVoted[msg.sender][_proposalId]) revert ChronoForge__AlreadyVoted();

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        hasVoted[msg.sender][_proposalId] = true;

        emit Voted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a successful proposal after the voting period has ended.
     *      Requires a majority of 'for' votes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyGovernor whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ChronoForge__ProposalNotFound();
        if (proposal.executed) revert ChronoForge__ProposalNotExecutable();
        if (block.timestamp < proposal.votingDeadline) revert ChronoForge__VotingPeriodActive();

        // Simple majority: more 'for' votes than 'against' votes.
        // For a more robust DAO, you'd integrate with a governance token for weighted voting.
        if (proposal.votesFor <= proposal.votesAgainst) revert ChronoForge__ProposalNotExecutable();

        // Execute the parameter change
        _updateCoreParameter(proposal.paramNameHash, proposal.paramValue);
        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Internal function to update core contract parameters based on governance proposals.
     * @param _paramNameHash The keccak256 hash of the parameter's name.
     * @param _newValue The new value for the parameter, encoded as bytes.
     */
    function _updateCoreParameter(bytes32 _paramNameHash, bytes memory _newValue) internal {
        // This uses a simple if-else structure, for many parameters, a more dynamic
        // approach with a 'Config' struct and direct setting might be considered.
        if (_paramNameHash == keccak256("baseForgeFee")) {
            baseForgeFee = abi.decode(_newValue, (uint256));
        } else if (_paramNameHash == keccak256("blueprintMintCost")) {
            blueprintMintCost = abi.decode(_newValue, (uint256));
        } else if (_paramNameHash == keccak256("votingPeriodDuration")) {
            votingPeriodDuration = abi.decode(_newValue, (uint256));
        }
        // Add more parameters as the contract evolves
        else {
            revert ChronoForge__ProposalNotExecutable(); // Unknown parameter to change
        }
        emit CoreParameterUpdated(_paramNameHash, _newValue);
    }


    // --- V. Financials & Rewards ---

    /**
     * @dev Sets the base fee required to forge a new Temporal Manifestation.
     *      Only callable by governance via a successful proposal.
     * @param _newFee The new base fee in wei.
     */
    function setBaseForgeFee(uint256 _newFee) public onlyGovernor {
        // This function would typically be called by `_updateCoreParameter`
        // after a governance vote, not directly. Made public for demonstration.
        baseForgeFee = _newFee;
        emit CoreParameterUpdated(keccak256("baseForgeFee"), abi.encode(_newFee));
    }

    /**
     * @dev Sets the cost to mint a new Temporal Blueprint NFT.
     *      Only callable by governance via a successful proposal.
     * @param _newCost The new minting cost in wei.
     */
    function setBlueprintMintCost(uint256 _newCost) public onlyGovernor {
        // Similarly, this would be called by `_updateCoreParameter`.
        if (_newCost == 0) revert ChronoForge__InvalidMintCost();
        blueprintMintCost = _newCost;
        emit CoreParameterUpdated(keccak256("blueprintMintCost"), abi.encode(_newCost));
    }

    /**
     * @dev Returns the current ETH balance of the ChronoForge contract.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allows governors (via a successful proposal) to withdraw accumulated funds.
     *      This would typically be part of a separate treasury management proposal.
     * @param _amount The amount of ETH to withdraw.
     * @param _recipient The address to send the funds to.
     */
    function withdrawFunds(uint256 _amount, address _recipient) public onlyGovernor {
        // This function should ideally be called as part of a governance proposal execution.
        // For simplicity, it's a direct governor call here.
        if (address(this).balance < _amount) revert ChronoForge__NoFundsToWithdraw();
        Address.sendValue(_recipient, _amount);
    }

    /**
     * @dev A placeholder function for claiming rewards.
     *      In a full system, this would integrate with a separate reward pool,
     *      potentially based on the success/performance of forged Manifestations,
     *      governance participation, or other metrics.
     * @param _user The user claiming rewards.
     */
    function claimForgingRewards(address _user) public pure returns (uint256) {
        // This would require a complex reward calculation logic,
        // potentially pulling data from Manifestation feedback or an external oracle.
        // For now, it's a placeholder.
        _user; // Unused, just to satisfy compiler
        return 0; // No rewards implemented in this simplified example
    }
}
```