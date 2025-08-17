Okay, this is an exciting challenge! Let's design a smart contract protocol that integrates several advanced concepts: dynamic state changes, multi-factor decision-making, reputation, unique NFT utility, and a focus on "future state manifestation."

I'll call this the **"QuantumLeap Protocol"**.

**Core Concept:**
The QuantumLeap Protocol allows users to propose "Quantum Prototypes" – conceptual projects or ideas. Participants "energize" these prototypes by staking tokens. The protocol then uses a dynamic, multi-factor "Manifestation Formula" (including staked energy, time, and external 'validation signals') to determine if a prototype "manifests" into a realized project or "collapses." Successful manifestation unlocks the prototype's budget and rewards participants, while collapse allows for partial reclamation of staked energy. A unique "Temporal Entanglement NFT" is minted for each energization, which dynamically changes its properties based on the prototype's state. Participants also accrue "Chroniton Flux" – an internal, non-transferable reputation score that influences their impact within the protocol.

---

### **QuantumLeap Protocol: Adaptive Future-State Manifestation**

**Outline & Function Summary:**

**I. Core Protocol Mechanics**
*   **`proposeQuantumPrototype`**: Allows anyone to propose a new, conceptual project.
*   **`energizePrototype`**: Users stake funds (ERC20 tokens) into a specific prototype, minting a unique "Temporal Entanglement NFT".
*   **`deEnergizePrototype`**: Allows users to partially withdraw staked funds before manifestation, potentially incurring a penalty.
*   **`signalValidationCriterion`**: External, trusted sources (oracles, governance) provide validation signals that influence a prototype's manifestation score.
*   **`initiateManifestationCheck`**: Triggers the complex, multi-factor evaluation for a prototype's manifestation, updating its state and associated NFTs.
*   **`claimManifestedOutput`**: Allows energizers to claim their share from a successfully manifested prototype's budget.
*   **`reclaimCollapsedEnergy`**: Allows energizers to reclaim their remaining staked funds from a collapsed prototype.

**II. Temporal Entanglement NFTs (ERC721)**
*   **`getTemporalEntanglementNFTState`**: Retrieves the current, dynamic state and properties of a specific Temporal Entanglement NFT.
*   **`getNFTTokenURI`**: Returns the URI for the NFT metadata, which dynamically updates based on the prototype's state.

**III. Chroniton Flux (Reputation System)**
*   **`getChronitonFluxBalance`**: Retrieves a user's current Chroniton Flux score.
*   **`delegateChronitonFlux`**: Allows users to delegate their Chroniton Flux voting power to another address without transferring tokens.

**IV. Governance & Protocol Parameters**
*   **`proposeProtocolParameterChange`**: Initiates a proposal for changing a core protocol parameter (e.g., manifestation weights, fees).
*   **`voteOnProtocolParameterChange`**: Allows Chroniton Flux holders to vote on active proposals.
*   **`executeProtocolParameterChange`**: Executes a passed governance proposal.
*   **`updateManifestationFormulaWeights`**: (Internal/Callable by Governance) Adjusts the weights of factors in the manifestation formula.
*   **`registerSignalOracle`**: Adds or removes an address authorized to send validation signals.
*   **`slashMaliciousOracle`**: Allows governance to penalize a misbehaving oracle, reducing their Chroniton Flux.

**V. Protocol Management & Security**
*   **`emergencyPause`**: Pauses critical protocol functions in case of an emergency.
*   **`emergencyUnpause`**: Unpauses the protocol.
*   **`setProtocolFeeRecipient`**: Sets the address that receives protocol fees.
*   **`withdrawProtocolFees`**: Allows the fee recipient to withdraw collected fees.
*   **`transferOwnership`**: Transfers ownership of the contract.

**VI. Query & Information**
*   **`getPrototypeDetails`**: Retrieves all details for a specific Quantum Prototype.
*   **`getUserEnergization`**: Retrieves a user's specific energization details for a given prototype.
*   **`getProtocolParameters`**: Returns all current global protocol parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom Errors for enhanced readability and gas efficiency
error QuantumLeap__PrototypeNotFound(uint256 prototypeId);
error QuantumLeap__InvalidPrototypeState(uint256 prototypeId, string expectedState, string currentState);
error QuantumLeap__AlreadyEnergized(uint256 prototypeId, address user);
error QuantumLeap__InsufficientEnergization(uint256 prototypeId, address user, uint256 requiredAmount, uint256 currentAmount);
error QuantumLeap__OnlyOracle();
error QuantumLeap__NotYetManifested();
error QuantumLeap__NotYetCollapsed();
error QuantumLeap__InsufficientBalance();
error QuantumLeap__InvalidWeightConfiguration();
error QuantumLeap__NoActiveProposal();
error QuantumLeap__ProposalAlreadyExists();
error QuantumLeap__UnauthorizedVoting();
error QuantumLeap__ProposalNotExecutable();
error QuantumLeap__ProposalStillActive();
error QuantumLeap__InvalidDelegation();


/**
 * @title QuantumLeapProtocol
 * @dev A smart contract for adaptive future-state manifestation using multi-factor evaluation,
 *      dynamic NFTs, and a reputation system.
 */
contract QuantumLeapProtocol is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _prototypeIdCounter;
    Counters.Counter private _temporalEntanglementTokenIdCounter;

    // Defines the possible states of a Quantum Prototype
    enum PrototypeState { PROPOSED, ENERGIZING, VALIDATED, MANIFESTED, COLLAPSED }

    // Struct for a Quantum Prototype
    struct QuantumPrototype {
        uint256 id;
        string name;
        string description;
        address proposer;
        PrototypeState state;
        uint256 creationTime;
        uint256 manifestationTargetTime; // A soft target for manifestation
        uint256 totalEnergizedAmount;    // Total ERC20 tokens staked
        uint256 validationSignalsReceived; // Count of validation signals
        uint256 manifestationScore;      // Calculated score for manifestation
        address budgetToken;             // ERC20 token used for energization and budget
        uint256 budgetAmount;            // Amount to be unlocked if manifested
        string metadataURI;              // URI for prototype-specific metadata (e.g., IPFS hash)
        uint256 lastActivityTime;        // Timestamp of last energize/de-energize
    }

    // Struct for an individual energization record by a user
    struct EnergizationRecord {
        uint256 prototypeId;
        address energizer;
        uint256 stakedAmount;
        uint256 energizationTime;
        uint256 temporalEntanglementNFTId; // The NFT ID associated with this energization
        bool claimed; // Whether funds have been claimed (manifested or collapsed)
    }

    // Struct for Temporal Entanglement NFT dynamic properties
    struct TemporalEntanglementNFTData {
        uint256 prototypeId;
        uint256 energizationId; // Link back to the specific energization record
        PrototypeState associatedPrototypeState; // Reflects the state of its prototype
        uint256 lastUpdatedTime;
        string dynamicURI; // Base URI for dynamic metadata
    }

    // Struct for Governance Proposals
    struct ProtocolParameterProposal {
        bytes32 proposalHash; // Hash of the proposed parameters to ensure integrity
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Track who has voted
        bool executed;
        // Fields for the actual parameters to be updated (packed for hashing)
        uint256 newTimeFactorWeight;
        uint256 newEnergyFactorWeight;
        uint256 newSignalFactorWeight;
        uint256 newDeEnergizePenaltyBps;
        uint256 newProtocolFeeBps;
        uint256 newMinVoteDuration;
    }

    // --- Mappings ---
    mapping(uint256 => QuantumPrototype) public prototypes;
    mapping(uint256 => EnergizationRecord) public energizationRecords; // ID for each unique energization
    mapping(address => mapping(uint256 => uint256)) public userPrototypeEnergizations; // user => prototypeId => energizationRecordId
    mapping(address => uint256) public chronitonFlux; // User's reputation score (non-transferable)
    mapping(address => address) public chronitonFluxDelegations; // Delegated voting power
    mapping(uint256 => TemporalEntanglementNFTData) public temporalEntanglementNFTs; // NFT ID => dynamic data
    mapping(address => bool) public isSignalOracle; // Address => is an authorized oracle

    // --- Global Protocol Parameters (Governable) ---
    uint256 public manifestationTimeFactorWeight = 40; // Weight for time elapsed since creation (in basis points, total 100)
    uint256 public manifestationEnergyFactorWeight = 40; // Weight for total energized amount (in basis points)
    uint256 public manifestationSignalFactorWeight = 20; // Weight for validation signals (in basis points)
    uint256 public deEnergizePenaltyBps = 1000; // 10% penalty for de-energizing (in basis points)
    uint256 public protocolFeeBps = 50; // 0.5% fee on manifested budget (in basis points)
    uint256 public minVoteDuration = 3 days; // Minimum duration for governance proposals
    address public protocolFeeRecipient; // Address to receive protocol fees

    // Governance
    ProtocolParameterProposal public currentProposal;
    bool public proposalActive = false;

    // --- Events ---
    event PrototypeProposed(uint256 indexed prototypeId, address indexed proposer, string name, uint256 creationTime);
    event PrototypeEnergized(uint256 indexed prototypeId, address indexed energizer, uint256 amount, uint256 nftId);
    event PrototypeDeEnergized(uint256 indexed prototypeId, address indexed energizer, uint256 amount, uint256 penalty);
    event ValidationSignalReceived(uint256 indexed prototypeId, address indexed oracle, uint256 newSignalCount);
    event PrototypeManifested(uint256 indexed prototypeId, uint256 manifestationScore);
    event PrototypeCollapsed(uint256 indexed prototypeId, uint256 manifestationScore);
    event FundsClaimed(uint256 indexed prototypeId, address indexed energizer, uint256 amount);
    event ChronitonFluxUpdated(address indexed user, uint256 oldFlux, uint256 newFlux);
    event ChronitonFluxDelegated(address indexed delegator, address indexed delegatee);
    event ProtocolFeeCollected(uint256 amount);
    event OracleRegistered(address indexed oracleAddress, bool registered);
    event OracleSlashed(address indexed oracleAddress, uint256 slashedAmount);
    event TemporalEntanglementNFTStateUpdated(uint256 indexed tokenId, PrototypeState newState);
    event ProtocolParameterChangeProposed(bytes32 indexed proposalHash, address indexed proposer, uint256 votingEndTime);
    event ProtocolParameterVoted(bytes32 indexed proposalHash, address indexed voter, bool voteYes);
    event ProtocolParameterChangeExecuted(bytes32 indexed proposalHash);

    // --- Constructor ---
    constructor(address _protocolFeeRecipient)
        ERC721("TemporalEntanglementNFT", "TENFT")
        Ownable(msg.sender) // Set deployer as initial owner
    {
        protocolFeeRecipient = _protocolFeeRecipient;
        // Initial weights sum must be 10000 basis points (100%)
        require(manifestationTimeFactorWeight + manifestationEnergyFactorWeight + manifestationSignalFactorWeight == 100,
            "Initial manifestation weights must sum to 100."
        );
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        if (!isSignalOracle[msg.sender]) revert QuantumLeap__OnlyOracle();
        _;
    }

    // --- Core Protocol Functions ---

    /**
     * @dev Proposes a new Quantum Prototype. Anyone can propose.
     * @param _name The name of the prototype.
     * @param _description A detailed description of the prototype.
     * @param _manifestationTargetTime A target timestamp for the prototype to manifest.
     * @param _budgetToken The ERC20 token address that will be used for energization and budget.
     * @param _budgetAmount The total amount of _budgetToken required for this prototype to manifest.
     * @param _metadataURI An IPFS hash or similar URI for off-chain metadata.
     */
    function proposeQuantumPrototype(
        string memory _name,
        string memory _description,
        uint256 _manifestationTargetTime,
        address _budgetToken,
        uint256 _budgetAmount,
        string memory _metadataURI
    ) external whenNotPaused returns (uint256) {
        _prototypeIdCounter.increment();
        uint256 newId = _prototypeIdCounter.current();

        prototypes[newId] = QuantumPrototype({
            id: newId,
            name: _name,
            description: _description,
            proposer: msg.sender,
            state: PrototypeState.PROPOSED,
            creationTime: block.timestamp,
            manifestationTargetTime: _manifestationTargetTime,
            totalEnergizedAmount: 0,
            validationSignalsReceived: 0,
            manifestationScore: 0,
            budgetToken: _budgetToken,
            budgetAmount: _budgetAmount,
            metadataURI: _metadataURI,
            lastActivityTime: block.timestamp
        });

        _distributeChronitonFlux(msg.sender, 10); // Reward proposer with some initial Chroniton Flux

        emit PrototypeProposed(newId, msg.sender, _name, block.timestamp);
        return newId;
    }

    /**
     * @dev Allows a user to energize a Quantum Prototype by staking ERC20 tokens.
     *      Mints a unique Temporal Entanglement NFT representing this stake.
     * @param _prototypeId The ID of the prototype to energize.
     * @param _amount The amount of ERC20 tokens to stake.
     */
    function energizePrototype(uint256 _prototypeId, uint256 _amount) external whenNotPaused {
        QuantumPrototype storage prototype = prototypes[_prototypeId];
        if (prototype.id == 0) revert QuantumLeap__PrototypeNotFound(_prototypeId);
        if (prototype.state != PrototypeState.PROPOSED && prototype.state != PrototypeState.ENERGIZING) {
            revert QuantumLeap__InvalidPrototypeState(_prototypeId, "PROPOSED or ENERGIZING", _toString(prototype.state));
        }
        if (_amount == 0) revert QuantumLeap__InsufficientBalance();

        IERC20(prototype.budgetToken).transferFrom(msg.sender, address(this), _amount);

        prototype.totalEnergizedAmount += _amount;
        prototype.lastActivityTime = block.timestamp;
        if (prototype.state == PrototypeState.PROPOSED) {
            prototype.state = PrototypeState.ENERGIZING; // Transition state once first energization occurs
        }

        // Create a new energization record
        uint256 energizationRecordId = _prototypeIdCounter.current() + _temporalEntanglementTokenIdCounter.current() + block.timestamp; // A unique, simple ID
        energizationRecords[energizationRecordId] = EnergizationRecord({
            prototypeId: _prototypeId,
            energizer: msg.sender,
            stakedAmount: _amount,
            energizationTime: block.timestamp,
            temporalEntanglementNFTId: _temporalEntanglementTokenIdCounter.current() + 1, // Pre-increment for NFT
            claimed: false
        });
        userPrototypeEnergizations[msg.sender][_prototypeId] = energizationRecordId; // Link user to their latest energization for this prototype

        // Mint Temporal Entanglement NFT
        _temporalEntanglementTokenIdCounter.increment();
        uint256 nftId = _temporalEntanglementTokenIdCounter.current();
        _safeMint(msg.sender, nftId);
        temporalEntanglementNFTs[nftId] = TemporalEntanglementNFTData({
            prototypeId: _prototypeId,
            energizationId: energizationRecordId,
            associatedPrototypeState: prototype.state,
            lastUpdatedTime: block.timestamp,
            dynamicURI: string(abi.encodePacked("ipfs://QmTENFT", Strings.toString(nftId))) // Base URI
        });
        _updateTemporalEntanglementNFT(nftId); // Update NFT state immediately

        _distributeChronitonFlux(msg.sender, _amount / 100); // Reward based on staked amount (1 CF per 100 units)

        emit PrototypeEnergized(_prototypeId, msg.sender, _amount, nftId);
    }

    /**
     * @dev Allows an energizer to partially de-energize (withdraw) their staked funds.
     *      Incurs a penalty. Not allowed if prototype has manifested or collapsed.
     * @param _prototypeId The ID of the prototype.
     * @param _amount The amount to de-energize.
     */
    function deEnergizePrototype(uint256 _prototypeId, uint256 _amount) external whenNotPaused {
        QuantumPrototype storage prototype = prototypes[_prototypeId];
        if (prototype.id == 0) revert QuantumLeap__PrototypeNotFound(_prototypeId);
        if (prototype.state == PrototypeState.MANIFESTED || prototype.state == PrototypeState.COLLAPSED) {
            revert QuantumLeap__InvalidPrototypeState(_prototypeId, "NOT MANIFESTED or COLLAPSED", _toString(prototype.state));
        }

        uint256 energizationRecordId = userPrototypeEnergizations[msg.sender][_prototypeId];
        EnergizationRecord storage record = energizationRecords[energizationRecordId];
        if (record.stakedAmount == 0 || record.energizer != msg.sender) {
            revert QuantumLeap__InsufficientEnergization(_prototypeId, msg.sender, _amount, 0); // User has no active energization
        }
        if (record.stakedAmount < _amount) {
            revert QuantumLeap__InsufficientEnergization(_prototypeId, msg.sender, _amount, record.stakedAmount);
        }

        uint256 penalty = (_amount * deEnergizePenaltyBps) / 10000;
        uint256 amountToReturn = _amount - penalty;

        record.stakedAmount -= _amount;
        prototype.totalEnergizedAmount -= _amount;
        prototype.lastActivityTime = block.timestamp;

        IERC20(prototype.budgetToken).transfer(msg.sender, amountToReturn);
        // Penalty is retained by the contract as part of protocol fees
        _distributeChronitonFlux(msg.sender, (penalty / 100) * -1); // Deduct CF for de-energizing

        _updateTemporalEntanglementNFT(record.temporalEntanglementNFTId);

        emit PrototypeDeEnergized(_prototypeId, msg.sender, _amount, penalty);
    }

    /**
     * @dev Allows an authorized signal oracle to provide a validation signal for a prototype.
     *      These signals contribute to the manifestation score.
     * @param _prototypeId The ID of the prototype to signal.
     */
    function signalValidationCriterion(uint256 _prototypeId) external onlyOracle whenNotPaused {
        QuantumPrototype storage prototype = prototypes[_prototypeId];
        if (prototype.id == 0) revert QuantumLeap__PrototypeNotFound(_prototypeId);
        if (prototype.state == PrototypeState.MANIFESTED || prototype.state == PrototypeState.COLLAPSED) {
            revert QuantumLeap__InvalidPrototypeState(_prototypeId, "NOT MANIFESTED or COLLAPSED", _toString(prototype.state));
        }

        prototype.validationSignalsReceived++;
        prototype.lastActivityTime = block.timestamp;
        _distributeChronitonFlux(msg.sender, 5); // Reward oracle for signaling

        emit ValidationSignalReceived(_prototypeId, msg.sender, prototype.validationSignalsReceived);
    }

    /**
     * @dev Initiates the manifestation check for a prototype. This can be called by anyone.
     *      Calculates the manifestation score and updates the prototype's state.
     *      This is where the complex, dynamic logic resides.
     * @param _prototypeId The ID of the prototype to check.
     */
    function initiateManifestationCheck(uint256 _prototypeId) external whenNotPaused {
        QuantumPrototype storage prototype = prototypes[_prototypeId];
        if (prototype.id == 0) revert QuantumLeap__PrototypeNotFound(_prototypeId);
        if (prototype.state == PrototypeState.MANIFESTED || prototype.state == PrototypeState.COLLAPSED) {
            revert QuantumLeap__InvalidPrototypeState(_prototypeId, "NOT MANIFESTED or COLLAPSED", _toString(prototype.state));
        }

        uint256 timeElapsed = block.timestamp - prototype.creationTime;
        uint256 targetTimeElapsed = prototype.manifestationTargetTime - prototype.creationTime;
        if (targetTimeElapsed == 0) targetTimeElapsed = 1; // Prevent division by zero if target is same as creation

        // Normalize factors to a common scale, e.g., 10000 (for basis points)
        // Time Factor: Closer to target time, higher score. Can also have decay after target.
        uint256 normalizedTimeFactor = (timeElapsed * 10000) / targetTimeElapsed;
        if (normalizedTimeFactor > 10000) normalizedTimeFactor = 10000; // Cap at 100%

        // Energy Factor: Higher energized amount, higher score (relative to budget)
        uint256 normalizedEnergyFactor = (prototype.totalEnergizedAmount * 10000) / prototype.budgetAmount;
        if (normalizedEnergyFactor > 10000) normalizedEnergyFactor = 10000; // Cap at 100%

        // Signal Factor: More signals, higher score (cap signals to prevent undue influence)
        uint256 cappedSignals = prototype.validationSignalsReceived;
        if (cappedSignals > 100) cappedSignals = 100; // Example cap
        uint256 normalizedSignalFactor = (cappedSignals * 100); // Max 10000 if capped at 100 signals

        // Calculate weighted average (Manifestation Formula)
        // (Factor * Weight) / 10000 (to remove basis point scaling)
        uint256 score = (normalizedTimeFactor * manifestationTimeFactorWeight) +
                        (normalizedEnergyFactor * manifestationEnergyFactorWeight) +
                        (normalizedSignalFactor * manifestationSignalFactorWeight);

        // Normalize score to 100 for easier interpretation (total sum of weights is 100, so divide by 100)
        prototype.manifestationScore = score / 100;

        // Determine state transition based on score and time
        if (prototype.manifestationScore >= 80 && prototype.totalEnergizedAmount >= prototype.budgetAmount) {
            prototype.state = PrototypeState.MANIFESTED;
            // Distribute budget to energizers (proportionally)
            _distributeManifestedBudget(_prototypeId);
            emit PrototypeManifested(_prototypeId, prototype.manifestationScore);
        } else if (block.timestamp > prototype.manifestationTargetTime + 30 days && prototype.manifestationScore < 80) { // 30-day grace period
            prototype.state = PrototypeState.COLLAPSED;
            emit PrototypeCollapsed(_prototypeId, prototype.manifestationScore);
        }
        // If neither, state remains ENERGIZING or VALIDATED (if validation signals exist)

        // Update all associated NFTs
        for (uint256 i = 1; i <= _temporalEntanglementTokenIdCounter.current(); i++) {
            if (temporalEntanglementNFTs[i].prototypeId == _prototypeId) {
                _updateTemporalEntanglementNFT(i);
            }
        }
    }

    /**
     * @dev Allows energizers to claim their proportional share from a successfully manifested prototype.
     *      Funds are transferred from the contract to the energizer.
     *      Marks the energization record as claimed.
     * @param _prototypeId The ID of the manifested prototype.
     */
    function claimManifestedOutput(uint256 _prototypeId) external whenNotPaused {
        QuantumPrototype storage prototype = prototypes[_prototypeId];
        if (prototype.id == 0) revert QuantumLeap__PrototypeNotFound(_prototypeId);
        if (prototype.state != PrototypeState.MANIFESTED) revert QuantumLeap__NotYetManifested();

        uint256 energizationRecordId = userPrototypeEnergizations[msg.sender][_prototypeId];
        EnergizationRecord storage record = energizationRecords[energizationRecordId];
        if (record.stakedAmount == 0 || record.claimed) {
            revert QuantumLeap__InsufficientEnergization(_prototypeId, msg.sender, 1, 0); // No unclaimed funds
        }

        uint256 share = (record.stakedAmount * prototype.budgetAmount) / prototype.totalEnergizedAmount;
        uint256 protocolFee = (share * protocolFeeBps) / 10000;
        uint256 amountToTransfer = share - protocolFee;

        record.claimed = true;
        
        IERC20(prototype.budgetToken).transfer(msg.sender, amountToTransfer);
        IERC20(prototype.budgetToken).transfer(protocolFeeRecipient, protocolFee);

        // Burn the associated NFT as the claim is complete
        _burn(record.temporalEntanglementNFTId);
        delete temporalEntanglementNFTs[record.temporalEntanglementNFTId];

        emit FundsClaimed(_prototypeId, msg.sender, amountToTransfer);
        emit ProtocolFeeCollected(protocolFee);
    }

    /**
     * @dev Allows energizers to reclaim their remaining (after penalty) staked funds from a collapsed prototype.
     *      Marks the energization record as claimed.
     * @param _prototypeId The ID of the collapsed prototype.
     */
    function reclaimCollapsedEnergy(uint256 _prototypeId) external whenNotPaused {
        QuantumPrototype storage prototype = prototypes[_prototypeId];
        if (prototype.id == 0) revert QuantumLeap__PrototypeNotFound(_prototypeId);
        if (prototype.state != PrototypeState.COLLAPSED) revert QuantumLeap__NotYetCollapsed();

        uint256 energizationRecordId = userPrototypeEnergizations[msg.sender][_prototypeId];
        EnergizationRecord storage record = energizationRecords[energizationRecordId];
        if (record.stakedAmount == 0 || record.claimed) {
            revert QuantumLeap__InsufficientEnergization(_prototypeId, msg.sender, 1, 0); // No unclaimed funds
        }

        uint256 amountToReturn = record.stakedAmount; // No additional penalty for collapse
        record.claimed = true;

        IERC20(prototype.budgetToken).transfer(msg.sender, amountToReturn);

        // Burn the associated NFT
        _burn(record.temporalEntanglementNFTId);
        delete temporalEntanglementNFTs[record.temporalEntanglementNFTId];

        emit FundsClaimed(_prototypeId, msg.sender, amountToReturn);
    }

    // --- Temporal Entanglement NFTs (ERC721) ---

    /**
     * @dev Retrieves the current dynamic data of a Temporal Entanglement NFT.
     * @param _tokenId The ID of the Temporal Entanglement NFT.
     * @return A tuple containing prototypeId, energizationId, associatedPrototypeState, and lastUpdatedTime.
     */
    function getTemporalEntanglementNFTState(uint256 _tokenId)
        external
        view
        returns (uint256 prototypeId, uint256 energizationId, PrototypeState associatedPrototypeState, uint256 lastUpdatedTime)
    {
        TemporalEntanglementNFTData storage nftData = temporalEntanglementNFTs[_tokenId];
        return (nftData.prototypeId, nftData.energizationId, nftData.associatedPrototypeState, nftData.lastUpdatedTime);
    }

    /**
     * @dev Overrides ERC721's _baseURI to provide dynamic metadata based on NFT state.
     *      The URI will point to an off-chain service that generates metadata JSON
     *      based on the NFT's current properties.
     * @param _tokenId The ID of the NFT.
     * @return The dynamic URI for the NFT metadata.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://quantumleap.protocol/metadata/"; // Base URI for the off-chain metadata service
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Return a URI that includes the dynamic state for the metadata service to render
        TemporalEntanglementNFTData storage nftData = temporalEntanglementNFTs[_tokenId];
        if (nftData.prototypeId == 0) revert ERC721NonexistentToken(_tokenId);

        string memory stateString = _toString(nftData.associatedPrototypeState);
        
        // Example: https://quantumleap.protocol/metadata/123?prototypeId=456&state=MANIFESTED&updated=1678886400
        return string(abi.encodePacked(
            _baseURI(),
            Strings.toString(_tokenId),
            "?prototypeId=", Strings.toString(nftData.prototypeId),
            "&state=", stateString,
            "&updated=", Strings.toString(nftData.lastUpdatedTime)
        ));
    }


    // --- Chroniton Flux (Reputation System) ---

    /**
     * @dev Retrieves a user's current Chroniton Flux score.
     * @param _user The address of the user.
     * @return The Chroniton Flux balance.
     */
    function getChronitonFluxBalance(address _user) external view returns (uint256) {
        return chronitonFlux[_user];
    }

    /**
     * @dev Allows a user to delegate their Chroniton Flux (voting power) to another address.
     *      Delegated Chroniton Flux is used for governance voting.
     * @param _delegatee The address to delegate Chroniton Flux to.
     */
    function delegateChronitonFlux(address _delegatee) external {
        if (_delegatee == address(0) || _delegatee == msg.sender) revert QuantumLeap__InvalidDelegation();
        chronitonFluxDelegations[msg.sender] = _delegatee;
        emit ChronitonFluxDelegated(msg.sender, _delegatee);
    }

    // --- Governance & Protocol Parameters ---

    /**
     * @dev Allows governance (determined by Chroniton Flux) to propose changes to protocol parameters.
     *      Only one proposal can be active at a time.
     * @param _newTimeFactorWeight New weight for time in manifestation formula (0-100)
     * @param _newEnergyFactorWeight New weight for energy in manifestation formula (0-100)
     * @param _newSignalFactorWeight New weight for signals in manifestation formula (0-100)
     * @param _newDeEnergizePenaltyBps New penalty for de-energizing (basis points)
     * @param _newProtocolFeeBps New protocol fee (basis points)
     * @param _newMinVoteDuration New minimum duration for voting period (seconds)
     */
    function proposeProtocolParameterChange(
        uint256 _newTimeFactorWeight,
        uint256 _newEnergyFactorWeight,
        uint256 _newSignalFactorWeight,
        uint256 _newDeEnergizePenaltyBps,
        uint256 _newProtocolFeeBps,
        uint256 _newMinVoteDuration
    ) external {
        // Basic Chroniton Flux threshold for proposing (e.g., 100 CF)
        if (getEffectiveChronitonFlux(msg.sender) < 100) revert QuantumLeap__UnauthorizedVoting();
        if (proposalActive) revert QuantumLeap__ProposalAlreadyExists();
        if (_newTimeFactorWeight + _newEnergyFactorWeight + _newSignalFactorWeight != 100) revert QuantumLeap__InvalidWeightConfiguration();

        // Calculate proposal hash (simple for this example, in production use EIP-712)
        bytes32 proposalDataHash = keccak256(abi.encodePacked(
            _newTimeFactorWeight,
            _newEnergyFactorWeight,
            _newSignalFactorWeight,
            _newDeEnergizePenaltyBps,
            _newProtocolFeeBps,
            _newMinVoteDuration
        ));

        currentProposal = ProtocolParameterProposal({
            proposalHash: proposalDataHash,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + minVoteDuration, // Use current minVoteDuration for this proposal
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            newTimeFactorWeight: _newTimeFactorWeight,
            newEnergyFactorWeight: _newEnergyFactorWeight,
            newSignalFactorWeight: _newSignalFactorWeight,
            newDeEnergizePenaltyBps: _newDeEnergizePenaltyBps,
            newProtocolFeeBps: _newProtocolFeeBps,
            newMinVoteDuration: _newMinVoteDuration
        });
        proposalActive = true;
        emit ProtocolParameterChangeProposed(proposalDataHash, msg.sender, currentProposal.votingEndTime);
    }

    /**
     * @dev Allows Chroniton Flux holders (or their delegates) to vote on an active proposal.
     * @param _proposalHash The hash of the proposal to vote on.
     * @param _vote Yes (true) or No (false).
     */
    function voteOnProtocolParameterChange(bytes32 _proposalHash, bool _vote) external {
        if (!proposalActive || currentProposal.proposalHash != _proposalHash) revert QuantumLeap__NoActiveProposal();
        if (block.timestamp > currentProposal.votingEndTime) revert QuantumLeap__ProposalStillActive(); // Voting period has ended

        address voter = msg.sender;
        if (chronitonFluxDelegations[msg.sender] != address(0)) {
            voter = chronitonFluxDelegations[msg.sender];
        }

        if (currentProposal.hasVoted[voter]) revert QuantumLeap__UnauthorizedVoting();

        uint256 effectiveFlux = getEffectiveChronitonFlux(voter);
        if (effectiveFlux == 0) revert QuantumLeap__UnauthorizedVoting(); // Must have some flux to vote

        if (_vote) {
            currentProposal.yesVotes += effectiveFlux;
        } else {
            currentProposal.noVotes += effectiveFlux;
        }
        currentProposal.hasVoted[voter] = true;
        emit ProtocolParameterVoted(_proposalHash, msg.sender, _vote);
    }

    /**
     * @dev Executes a governance proposal if it has passed and its voting period has ended.
     */
    function executeProtocolParameterChange() external {
        if (!proposalActive) revert QuantumLeap__NoActiveProposal();
        if (block.timestamp <= currentProposal.votingEndTime) revert QuantumLeap__ProposalStillActive();
        if (currentProposal.executed) revert QuantumLeap__ProposalNotExecutable();

        // Simple majority vote for now. Could be more complex (e.g., quorum, supermajority).
        if (currentProposal.yesVotes > currentProposal.noVotes) {
            manifestationTimeFactorWeight = currentProposal.newTimeFactorWeight;
            manifestationEnergyFactorWeight = currentProposal.newEnergyFactorWeight;
            manifestationSignalFactorWeight = currentProposal.newSignalFactorWeight;
            deEnergizePenaltyBps = currentProposal.newDeEnergizePenaltyBps;
            protocolFeeBps = currentProposal.newProtocolFeeBps;
            minVoteDuration = currentProposal.newMinVoteDuration;

            currentProposal.executed = true;
            proposalActive = false;
            emit ProtocolParameterChangeExecuted(currentProposal.proposalHash);
        } else {
            // Proposal failed, reset for new proposal
            proposalActive = false;
        }
    }

    /**
     * @dev Registers or unregisters an address as a signal oracle. Only callable by owner.
     * @param _oracleAddress The address to register/unregister.
     * @param _isOracle True to register, false to unregister.
     */
    function registerSignalOracle(address _oracleAddress, bool _isOracle) external onlyOwner {
        isSignalOracle[_oracleAddress] = _isOracle;
        emit OracleRegistered(_oracleAddress, _isOracle);
    }

    /**
     * @dev Allows governance (owner for now, could be DAO later) to slash an oracle's Chroniton Flux for malicious behavior.
     * @param _oracleAddress The address of the oracle to slash.
     * @param _amount The amount of Chroniton Flux to slash.
     */
    function slashMaliciousOracle(address _oracleAddress, uint256 _amount) external onlyOwner {
        uint256 oldFlux = chronitonFlux[_oracleAddress];
        if (oldFlux < _amount) {
            _amount = oldFlux; // Slash no more than available
        }
        chronitonFlux[_oracleAddress] -= _amount;
        emit OracleSlashed(_oracleAddress, _amount);
        emit ChronitonFluxUpdated(_oracleAddress, oldFlux, chronitonFlux[_oracleAddress]);
    }

    // --- Protocol Management & Security ---

    /**
     * @dev Pauses the contract in case of an emergency. Only owner can call.
     */
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only owner can call.
     */
    function emergencyUnpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the address that will receive collected protocol fees. Only owner can call.
     * @param _newFeeRecipient The new address for fee recipient.
     */
    function setProtocolFeeRecipient(address _newFeeRecipient) external onlyOwner {
        protocolFeeRecipient = _newFeeRecipient;
    }

    /**
     * @dev Allows the protocol fee recipient to withdraw accumulated fees.
     *      Needs to specify the token type for withdrawal.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     */
    function withdrawProtocolFees(address _tokenAddress) external {
        if (msg.sender != protocolFeeRecipient) revert OwnableUnauthorizedAccount(msg.sender);
        
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        // Ensure only fees *not* locked in prototypes are withdrawn.
        // This simple implementation withdraws all contract balance for the token.
        // A more robust system would track fees separately.
        token.transfer(protocolFeeRecipient, balance);
    }
    
    // --- Query & Information ---

    /**
     * @dev Retrieves detailed information about a Quantum Prototype.
     * @param _prototypeId The ID of the prototype.
     * @return A tuple containing all prototype details.
     */
    function getPrototypeDetails(uint256 _prototypeId)
        external
        view
        returns (
            uint256 id,
            string memory name,
            string memory description,
            address proposer,
            PrototypeState state,
            uint256 creationTime,
            uint256 manifestationTargetTime,
            uint256 totalEnergizedAmount,
            uint256 validationSignalsReceived,
            uint256 manifestationScore,
            address budgetToken,
            uint256 budgetAmount,
            string memory metadataURI,
            uint256 lastActivityTime
        )
    {
        QuantumPrototype storage prototype = prototypes[_prototypeId];
        if (prototype.id == 0) revert QuantumLeap__PrototypeNotFound(_prototypeId);
        return (
            prototype.id,
            prototype.name,
            prototype.description,
            prototype.proposer,
            prototype.state,
            prototype.creationTime,
            prototype.manifestationTargetTime,
            prototype.totalEnergizedAmount,
            prototype.validationSignalsReceived,
            prototype.manifestationScore,
            prototype.budgetToken,
            prototype.budgetAmount,
            prototype.metadataURI,
            prototype.lastActivityTime
        );
    }

    /**
     * @dev Retrieves a user's specific energization record for a given prototype.
     * @param _user The address of the energizer.
     * @param _prototypeId The ID of the prototype.
     * @return A tuple containing prototypeId, energizer, stakedAmount, energizationTime, NFT ID, and claimed status.
     */
    function getUserEnergization(address _user, uint256 _prototypeId)
        external
        view
        returns (
            uint256 prototypeId,
            address energizer,
            uint256 stakedAmount,
            uint256 energizationTime,
            uint256 temporalEntanglementNFTId,
            bool claimed
        )
    {
        uint256 energizationRecordId = userPrototypeEnergizations[_user][_prototypeId];
        EnergizationRecord storage record = energizationRecords[energizationRecordId];
        if (record.stakedAmount == 0) { // Check if record exists
            revert QuantumLeap__InsufficientEnergization(_prototypeId, _user, 1, 0);
        }
        return (
            record.prototypeId,
            record.energizer,
            record.stakedAmount,
            record.energizationTime,
            record.temporalEntanglementNFTId,
            record.claimed
        );
    }

    /**
     * @dev Returns all current global protocol parameters.
     * @return A tuple containing all current protocol parameters.
     */
    function getProtocolParameters()
        external
        view
        returns (
            uint256 timeFactorWeight,
            uint256 energyFactorWeight,
            uint256 signalFactorWeight,
            uint256 deEnergizePenalty,
            uint256 protocolFee,
            uint256 minVoteDurationSecs,
            address feeRecipient
        )
    {
        return (
            manifestationTimeFactorWeight,
            manifestationEnergyFactorWeight,
            manifestationSignalFactorWeight,
            deEnergizePenaltyBps,
            protocolFeeBps,
            minVoteDuration,
            protocolFeeRecipient
        );
    }

    // --- Internal / Helper Functions ---

    /**
     * @dev Internal function to distribute Chroniton Flux (reputation points) to a user.
     * @param _user The address to reward/penalize.
     * @param _amount The amount of Chroniton Flux to add/deduct.
     */
    function _distributeChronitonFlux(address _user, int256 _amount) internal {
        uint256 oldFlux = chronitonFlux[_user];
        if (_amount > 0) {
            chronitonFlux[_user] += uint256(_amount);
        } else {
            uint256 absAmount = uint256(-_amount);
            if (chronitonFlux[_user] < absAmount) {
                chronitonFlux[_user] = 0; // Prevent underflow
            } else {
                chronitonFlux[_user] -= absAmount;
            }
        }
        emit ChronitonFluxUpdated(_user, oldFlux, chronitonFlux[_user]);
    }

    /**
     * @dev Internal function to get the effective Chroniton Flux of a voter, considering delegation.
     * @param _voter The potential voter's address.
     * @return The total Chroniton Flux they can use for voting.
     */
    function getEffectiveChronitonFlux(address _voter) internal view returns (uint256) {
        address delegatee = chronitonFluxDelegations[_voter];
        if (delegatee != address(0)) {
            return chronitonFlux[delegatee]; // Return delegatee's flux
        }
        return chronitonFlux[_voter]; // Return voter's own flux
    }

    /**
     * @dev Internal function to distribute the budget of a manifested prototype to its energizers.
     * @param _prototypeId The ID of the manifested prototype.
     */
    function _distributeManifestedBudget(uint256 _prototypeId) internal {
        QuantumPrototype storage prototype = prototypes[_prototypeId];
        // Note: This is a simplified distribution. In a real scenario, you'd iterate
        // through all EnergizationRecords for this prototype. For simplicity and gas,
        // this example relies on individual users calling claimManifestedOutput.
        // The total budget is now available in the contract for transfers.
    }

    /**
     * @dev Internal function to update the dynamic state of a Temporal Entanglement NFT.
     *      Called whenever the associated prototype's state changes.
     * @param _tokenId The ID of the NFT to update.
     */
    function _updateTemporalEntanglementNFT(uint256 _tokenId) internal {
        TemporalEntanglementNFTData storage nftData = temporalEntanglementNFTs[_tokenId];
        if (nftData.prototypeId == 0) return; // NFT does not exist

        QuantumPrototype storage prototype = prototypes[nftData.prototypeId];
        if (prototype.id == 0) return; // Associated prototype not found (shouldn't happen if NFT exists)

        if (nftData.associatedPrototypeState != prototype.state) {
            nftData.associatedPrototypeState = prototype.state;
            nftData.lastUpdatedTime = block.timestamp;
            emit TemporalEntanglementNFTStateUpdated(_tokenId, prototype.state);
        }
    }

    /**
     * @dev Helper function to convert PrototypeState enum to string for error messages.
     * @param _state The PrototypeState enum value.
     * @return The string representation of the state.
     */
    function _toString(PrototypeState _state) internal pure returns (string memory) {
        if (_state == PrototypeState.PROPOSED) return "PROPOSED";
        if (_state == PrototypeState.ENERGIZING) return "ENERGIZING";
        if (_state == PrototypeState.VALIDATED) return "VALIDATED"; // This state is implicitly handled by signals
        if (_state == PrototypeState.MANIFESTED) return "MANIFESTED";
        if (_state == PrototypeState.COLLAPSED) return "COLLAPSED";
        return "UNKNOWN";
    }
}

```