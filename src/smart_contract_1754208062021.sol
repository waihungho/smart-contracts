Okay, this is an exciting challenge! Let's design a smart contract for an "EonFlow Collective: Dynamic Asset & Identity Protocol."

This protocol will allow users to mint and manage "Archetypes" – unique, adaptive digital entities represented by NFTs. Each Archetype can represent a programmable financial strategy, a reputation-based identity, or even a digital twin of a real-world asset/concept. These Archetypes are not static; they can evolve their strategies, interact with external protocols, and accrue reputation, all governed by a Decentralized Autonomous Organization (DAO).

**Core Concepts:**

1.  **Archetypes (ERC721 NFTs):** Unique, programmable digital entities. Each Archetype has an owner, a set of parameters defining its behavior/strategy, a reputation score, and a designated "Treasury" holding assets it manages or earns.
2.  **Adaptive Strategies:** Archetypes can be assigned and execute various pre-defined or DAO-approved strategies (e.g., yield farming, liquidity provision, data collection, automated lending/borrowing). These strategies can be updated or changed.
3.  **Reputation System:** Archetypes accumulate reputation based on their performance, governance participation, and successful execution of strategies. Higher reputation can unlock features, boost rewards, or grant more voting power.
4.  **DAO Governance:** The core protocol parameters, approval of new strategy types, Archetype parameter changes, and treasury management are controlled by a decentralized governance system.
5.  **Oracle Integration (Simplified):** Archetypes can leverage external data feeds to inform their strategies, making them responsive to real-world events.
6.  **Modular & Upgradable:** Designed with upgradeability in mind (e.g., UUPS proxy pattern compatibility).

---

## EonFlow Collective: Dynamic Asset & Identity Protocol

**Contract Name:** `EonFlowCollective`

**Description:**
The `EonFlowCollective` is a decentralized protocol for creating, managing, and governing "Archetypes" – programmable, adaptive digital entities represented as ERC721 NFTs. Archetypes can embody financial strategies, digital identities, or serve as dynamic representations of real-world concepts. The protocol features a built-in reputation system for Archetypes and is governed by a decentralized autonomous organization (DAO).

**Core Capabilities:**
*   **Archetype Creation & Management:** Mint unique Archetype NFTs, update their parameters and metadata.
*   **Strategy Definition & Execution:** Assign and manage distinct operational strategies for Archetypes, allowing them to interact with other DeFi protocols or perform specific functions.
*   **Dynamic Reputation System:** Track and update Archetype reputation based on on-chain actions and performance, influencing their capabilities and rewards.
*   **Decentralized Governance:** A comprehensive DAO system for proposing, voting on, and executing critical protocol changes and Archetype-level decisions.
*   **Oracle Integration:** Facilitate Archetype access to external real-world data feeds for informed decision-making.
*   **Asset Management:** Each Archetype maintains its own internal "treasury" for managing assets related to its operations.

---

### Function Categories & Summary:

**I. Core Protocol Management (Owner/DAO only)**
1.  `pause()`: Pauses core operations, primarily for emergency.
2.  `unpause()`: Unpauses core operations.
3.  `transferOwnership(address newOwner)`: Transfers contract ownership (initially to DAO upon deployment).
4.  `upgradeTo(address newImplementation)`: Upgrades the contract logic (assuming a UUPS proxy setup).
5.  `setProtocolFeeRate(uint256 newRateBps)`: Sets the protocol fee rate on Archetype revenue (DAO governed).

**II. Archetype (NFT) Management**
6.  `mintArchetype(string calldata name, string calldata metadataURI, bytes calldata initialStrategyParams)`: Mints a new Archetype NFT with initial parameters.
7.  `updateArchetypeMetadataURI(uint256 archetypeId, string calldata newMetadataURI)`: Allows Archetype owner to update its metadata URI.
8.  `proposeArchetypeParameterUpdate(uint256 archetypeId, bytes calldata newParams, string calldata description)`: Initiates a DAO proposal to update an Archetype's core parameters (e.g., strategy type, risk profile).
9.  `getArchetypeDetails(uint256 archetypeId)`: Retrieves detailed information about a specific Archetype.
10. `getTotalArchetypes()`: Returns the total number of Archetypes minted.

**III. Strategy & Operation**
11. `activateArchetypeStrategy(uint256 archetypeId, StrategyType strategyType, bytes calldata strategyConfig)`: Activates a specific operational strategy for an Archetype.
12. `deactivateArchetypeStrategy(uint256 archetypeId)`: Deactivates the current strategy of an Archetype.
13. `executeArchetypeAction(uint256 archetypeId, address targetContract, bytes calldata callData, uint256 ethValue)`: Allows an Archetype owner to trigger a complex action based on its strategy (e.g., interact with a DeFi protocol). This is a generalized "dispatch" function.
14. `depositFundsForArchetype(uint256 archetypeId, address tokenAddress, uint256 amount)`: Allows anyone to deposit supported tokens into an Archetype's internal treasury.
15. `withdrawArchetypeFunds(uint256 archetypeId, address tokenAddress, uint256 amount)`: Allows Archetype owner or DAO to withdraw funds from its treasury.

**IV. Reputation System**
16. `recordArchetypePerformance(uint256 archetypeId, int256 reputationDelta, string calldata reason)`: Internal/DAO-callable function to update an Archetype's reputation based on performance or events.
17. `getArchetypeReputation(uint256 archetypeId)`: Retrieves the current reputation score of an Archetype.

**V. Decentralized Governance (DAO)**
18. `propose(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, string calldata description)`: Creates a new governance proposal.
19. `castVote(uint256 proposalId, bool support)`: Allows token holders to cast a vote on a proposal.
20. `queue(uint256 proposalId)`: Queues an approved proposal for execution after a timelock.
21. `execute(uint256 proposalId)`: Executes a queued proposal.
22. `collectProtocolFees(address tokenAddress)`: Allows the DAO to collect accumulated protocol fees.

**VI. Oracle Integration (Simplified)**
23. `registerTrustedOracle(address oracleAddress, bytes32 feedId)`: Registers a trusted oracle for specific data feeds (DAO only).
24. `updateOracleData(bytes32 feedId, uint256 value, uint256 timestamp)`: Allows registered oracles to push data updates.
25. `getLatestOracleData(bytes32 feedId)`: Retrieves the latest data from a registered oracle feed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol"; // For Archetype treasury management

// For UUPS proxy compatibility (though proxy itself is external)
// contract UUPSProxiable {
//     function proxiableUUID() internal view virtual returns (bytes32) {
//         return 0x360894a13ba1a3210667c828492db98dca3eaeeec37b4add806f0823dc0da985;
//     }
// }


/**
 * @title EonFlowCollective
 * @dev The core contract for the Dynamic Asset & Identity Protocol.
 *      Manages Archetype NFTs, their strategies, reputation, and DAO governance.
 */
contract EonFlowCollective is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Address for address;

    // --- State Variables ---

    Counters.Counter private _archetypeIds;

    // Mapping of Archetype ID to Archetype struct
    mapping(uint256 => Archetype) public archetypes;

    // Mapping of Archetype ID to its current reputation score
    mapping(uint256 => int256) public archetypeReputations;

    // Mapping for Archetype internal treasuries: Archetype ID -> Token Address -> Balance
    mapping(uint256 => mapping(address => uint256)) public archetypeTreasuries;

    // Protocol fee rate in basis points (e.g., 100 = 1%)
    uint256 public protocolFeeRateBps;
    address public protocolFeeRecipient; // Address to send collected protocol fees

    // --- Oracle Integration (Simplified) ---
    // mapping: Feed ID -> Oracle Address (trusted sources)
    mapping(bytes32 => address) public trustedOracles;
    // mapping: Feed ID -> Latest Data
    mapping(bytes32 => OracleData) public oracleDataFeeds;

    struct OracleData {
        uint256 value;
        uint256 timestamp;
    }

    // --- Governance (Simplified DAO) ---
    Counters.Counter private _proposalIds;
    uint256 public constant MIN_QUORUM_VOTES = 1; // Simplified quorum, should be based on total voting power
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant TIMELOCK_DELAY = 2 days;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voterAddress => voted

    // --- Structs ---

    enum StrategyType { None, YieldFarming, Lending, LiquidityProvision, DataCollection, Custom }

    struct Archetype {
        string name;
        address owner; // ERC721 handles this, but explicit is good
        StrategyType currentStrategyType;
        bytes currentStrategyConfig; // ABI-encoded parameters for the active strategy
        bool isActive;
        uint256 lastPerformanceUpdate;
        // Add more parameters like risk profile, investment allocation, etc.
    }

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Executed, Expired }

    struct Proposal {
        uint256 id;
        string description;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 timelockEndTime; // Time after which a queued proposal can be executed
        uint256 forVotes;
        uint256 againstVotes;
        ProposalState state;
        bool executed;
    }

    // --- Events ---

    event ArchetypeMinted(uint256 indexed archetypeId, address indexed owner, string name, string metadataURI);
    event ArchetypeMetadataUpdated(uint256 indexed archetypeId, string newMetadataURI);
    event ArchetypeStrategyActivated(uint256 indexed archetypeId, StrategyType strategyType, bytes config);
    event ArchetypeStrategyDeactivated(uint256 indexed archetypeId);
    event ArchetypeActionExecuted(uint256 indexed archetypeId, address target, bytes data);
    event ArchetypeFundsDeposited(uint256 indexed archetypeId, address indexed token, uint256 amount);
    event ArchetypeFundsWithdrawn(uint256 indexed archetypeId, address indexed token, uint256 amount);
    event ArchetypeReputationUpdated(uint256 indexed archetypeId, int256 newReputation, int256 delta, string reason);

    event ProtocolFeeRateSet(uint256 newRateBps);
    event ProtocolFeesCollected(address indexed token, uint256 amount);

    event OracleRegistered(bytes32 indexed feedId, address indexed oracleAddress);
    event OracleDataUpdated(bytes32 indexed feedId, uint256 value, uint256 timestamp);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event ContractUpgraded(address indexed newImplementation);

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_, address initialFeeRecipient)
        ERC721(name_, symbol_)
        Ownable(msg.sender) // Initial owner is deployer, to be transferred to DAO later
        Pausable()
    {
        protocolFeeRateBps = 0; // Start with no fees
        protocolFeeRecipient = initialFeeRecipient;
    }

    // --- Modifiers ---

    modifier onlyArchetypeOwner(uint256 _archetypeId) {
        require(ownerOf(_archetypeId) == msg.sender, "Caller is not Archetype owner");
        _;
    }

    modifier onlyTrustedOracle(bytes32 _feedId) {
        require(trustedOracles[_feedId] == msg.sender, "Caller is not a trusted oracle for this feed");
        _;
    }

    // --- I. Core Protocol Management ---

    /**
     * @dev Pauses core operations. Only callable by the current owner (or DAO).
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses core operations. Only callable by the current owner (or DAO).
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Transfers ownership of the contract. Intended to be transferred to a governance contract.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /**
     * @dev Upgrades the contract to a new implementation.
     *      This function is designed to be called by a proxy contract (e.g., UUPS).
     *      In a full UUPS implementation, this would be part of a `UUPSUpgradeable` base contract.
     *      For this example, it demonstrates the concept of an upgrade.
     *      Needs to be gated by DAO governance in production.
     * @param newImplementation The address of the new implementation contract.
     */
    function upgradeTo(address newImplementation) public onlyOwner {
        // In a real UUPS setup, this would involve `_authorizeUpgrade` and `_upgradeToAndCall`
        // For simplicity, this acts as a placeholder. The proxy contract handles the actual upgrade.
        emit ContractUpgraded(newImplementation);
    }

    /**
     * @dev Sets the protocol fee rate in basis points.
     *      Fees are collected on Archetype revenue.
     *      This function must be called via a successful DAO governance proposal.
     * @param newRateBps New fee rate in basis points (e.g., 100 for 1%). Max 10000.
     */
    function setProtocolFeeRate(uint256 newRateBps) public onlyOwner {
        require(newRateBps <= 10000, "Fee rate cannot exceed 100%");
        protocolFeeRateBps = newRateBps;
        emit ProtocolFeeRateSet(newRateBps);
    }

    // --- II. Archetype (NFT) Management ---

    /**
     * @dev Mints a new Archetype NFT.
     * @param name The name of the Archetype.
     * @param metadataURI The URI for the Archetype's ERC721 metadata.
     * @param initialStrategyParams ABI-encoded initial configuration for the Archetype's behavior.
     * @return The ID of the newly minted Archetype.
     */
    function mintArchetype(string calldata name, string calldata metadataURI, bytes calldata initialStrategyParams)
        public
        whenNotPaused
        returns (uint256)
    {
        _archetypeIds.increment();
        uint256 newArchetypeId = _archetypeIds.current();

        _safeMint(msg.sender, newArchetypeId);
        _setTokenURI(newArchetypeId, metadataURI);

        archetypes[newArchetypeId] = Archetype({
            name: name,
            owner: msg.sender, // The owner of the NFT is the Archetype's functional owner
            currentStrategyType: StrategyType.None,
            currentStrategyConfig: initialStrategyParams,
            isActive: false,
            lastPerformanceUpdate: block.timestamp
        });

        // Initialize reputation to 0
        archetypeReputations[newArchetypeId] = 0;

        emit ArchetypeMinted(newArchetypeId, msg.sender, name, metadataURI);
        return newArchetypeId;
    }

    /**
     * @dev Allows the owner of an Archetype to update its metadata URI.
     * @param archetypeId The ID of the Archetype.
     * @param newMetadataURI The new metadata URI.
     */
    function updateArchetypeMetadataURI(uint256 archetypeId, string calldata newMetadataURI)
        public
        onlyArchetypeOwner(archetypeId)
        whenNotPaused
    {
        _setTokenURI(archetypeId, newMetadataURI);
        emit ArchetypeMetadataUpdated(archetypeId, newMetadataURI);
    }

    /**
     * @dev Submits a DAO proposal to update an Archetype's core parameters (e.g., its strategy type, risk profile).
     *      This ensures critical Archetype changes are community-governed if Archetype owner wishes for that.
     * @param archetypeId The ID of the Archetype to update.
     * @param newParams ABI-encoded new parameters for the Archetype's internal config.
     * @param description A description of the proposed change.
     */
    function proposeArchetypeParameterUpdate(
        uint256 archetypeId,
        bytes calldata newParams,
        string calldata description
    ) public whenNotPaused {
        // This function creates a governance proposal.
        // The `target` would be this contract, `calldata` would be a call to an internal function
        // like `_applyArchetypeParameterUpdate(archetypeId, newParams)`.
        // For simplicity, we'll just create a generic proposal for now.
        // In a real system, there would be an internal function `_applyArchetypeParameterUpdate`
        // that only the governance `execute` function could call.
        address[] memory targets = new address[](1);
        targets[0] = address(this); // Target is this contract

        uint256[] memory values = new uint256[](1);
        values[0] = 0; // No ETH value

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(this.setArchetypeStrategyConfig.selector, archetypeId, newParams); // Example: setting strategy config

        _propose(targets, values, calldatas, description);
    }

    /**
     * @dev Internal function to be called by DAO `execute` for Archetype parameter updates.
     * @param archetypeId The ID of the Archetype.
     * @param newConfig The new ABI-encoded strategy configuration.
     */
    function setArchetypeStrategyConfig(uint256 archetypeId, bytes calldata newConfig) external onlyOwner {
        // This function should ONLY be callable by the `execute` function of the DAO.
        // `onlyOwner` here assumes the owner is the DAO/governance contract.
        require(archetypes[archetypeId].owner != address(0), "Archetype does not exist");
        archetypes[archetypeId].currentStrategyConfig = newConfig;
        emit ArchetypeStrategyActivated(archetypeId, archetypes[archetypeId].currentStrategyType, newConfig);
    }

    /**
     * @dev Retrieves detailed information about a specific Archetype.
     * @param archetypeId The ID of the Archetype.
     * @return A tuple containing Archetype details.
     */
    function getArchetypeDetails(uint256 archetypeId)
        public
        view
        returns (
            string memory name,
            address owner,
            StrategyType currentStrategyType,
            bytes memory currentStrategyConfig,
            bool isActive,
            uint256 lastPerformanceUpdate,
            string memory metadataURI,
            int256 reputation
        )
    {
        Archetype storage archetype = archetypes[archetypeId];
        require(archetype.owner != address(0), "Archetype does not exist");

        return (
            archetype.name,
            ownerOf(archetypeId), // Use ERC721's ownerOf for current owner
            archetype.currentStrategyType,
            archetype.currentStrategyConfig,
            archetype.isActive,
            archetype.lastPerformanceUpdate,
            tokenURI(archetypeId),
            archetypeReputations[archetypeId]
        );
    }

    /**
     * @dev Returns the total number of Archetypes minted.
     */
    function getTotalArchetypes() public view returns (uint256) {
        return _archetypeIds.current();
    }

    // --- III. Strategy & Operation ---

    /**
     * @dev Activates a specific operational strategy for an Archetype.
     *      Strategy config is stored, actual execution logic is external or triggered.
     * @param archetypeId The ID of the Archetype.
     * @param strategyType The type of strategy to activate.
     * @param strategyConfig ABI-encoded configuration specific to the chosen strategy.
     */
    function activateArchetypeStrategy(
        uint256 archetypeId,
        StrategyType strategyType,
        bytes calldata strategyConfig
    ) public onlyArchetypeOwner(archetypeId) whenNotPaused {
        require(strategyType != StrategyType.None, "Cannot activate None strategy");
        archetypes[archetypeId].currentStrategyType = strategyType;
        archetypes[archetypeId].currentStrategyConfig = strategyConfig;
        archetypes[archetypeId].isActive = true;
        emit ArchetypeStrategyActivated(archetypeId, strategyType, strategyConfig);
    }

    /**
     * @dev Deactivates the current strategy of an Archetype.
     * @param archetypeId The ID of the Archetype.
     */
    function deactivateArchetypeStrategy(uint256 archetypeId)
        public
        onlyArchetypeOwner(archetypeId)
        whenNotPaused
    {
        archetypes[archetypeId].currentStrategyType = StrategyType.None;
        archetypes[archetypeId].currentStrategyConfig = ""; // Clear config
        archetypes[archetypeId].isActive = false;
        emit ArchetypeStrategyDeactivated(archetypeId);
    }

    /**
     * @dev Allows an Archetype owner to trigger a generic external action on behalf of the Archetype.
     *      This function acts as a dispatcher for Archetype strategies to interact with other contracts.
     *      WARNING: Be extremely careful with external calls. In a production system, this would be
     *      heavily restricted to whitelisted contracts and specific function selectors.
     * @param archetypeId The ID of the Archetype executing the action.
     * @param targetContract The address of the contract to interact with.
     * @param callData The ABI-encoded call data for the target contract function.
     * @param ethValue The amount of Ether to send with the call.
     */
    function executeArchetypeAction(
        uint256 archetypeId,
        address targetContract,
        bytes calldata callData,
        uint256 ethValue
    ) public onlyArchetypeOwner(archetypeId) whenNotPaused {
        require(archetypes[archetypeId].isActive, "Archetype strategy is not active");
        require(targetContract != address(0), "Invalid target contract address");

        // Transfer ETH if value is specified
        if (ethValue > 0) {
            require(address(this).balance >= ethValue, "Contract balance too low for ETH transfer");
            // No direct Archetype treasury for ETH, it comes from contract itself
            // In a real system, Archetypes would manage their own ETH balances
        }

        // Perform the low-level call
        // IMPORTANT: This is highly risky for arbitrary calls. Implement strong whitelisting/permissions.
        (bool success, bytes memory result) = targetContract.call{value: ethValue}(callData);
        require(success, string(abi.encodePacked("Archetype action failed: ", result)));

        emit ArchetypeActionExecuted(archetypeId, targetContract, callData);
    }

    /**
     * @dev Allows anyone to deposit supported tokens into an Archetype's internal treasury.
     * @param archetypeId The ID of the Archetype to fund.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositFundsForArchetype(uint256 archetypeId, address tokenAddress, uint256 amount)
        public
        whenNotPaused
    {
        require(archetypes[archetypeId].owner != address(0), "Archetype does not exist");
        require(amount > 0, "Amount must be greater than zero");

        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        archetypeTreasuries[archetypeId][tokenAddress] += amount;
        emit ArchetypeFundsDeposited(archetypeId, tokenAddress, amount);
    }

    /**
     * @dev Allows the Archetype owner or DAO to withdraw funds from its internal treasury.
     * @param archetypeId The ID of the Archetype.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawArchetypeFunds(uint256 archetypeId, address tokenAddress, uint256 amount)
        public
        whenNotPaused
    {
        require(archetypes[archetypeId].owner != address(0), "Archetype does not exist");
        require(amount > 0, "Amount must be greater than zero");
        require(archetypeTreasuries[archetypeId][tokenAddress] >= amount, "Insufficient funds in Archetype treasury");

        // Only Archetype owner or DAO can withdraw
        require(
            ownerOf(archetypeId) == msg.sender || owner() == msg.sender,
            "Caller is neither Archetype owner nor contract owner (DAO)"
        );

        archetypeTreasuries[archetypeId][tokenAddress] -= amount;
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit ArchetypeFundsWithdrawn(archetypeId, tokenAddress, amount);
    }

    // --- IV. Reputation System ---

    /**
     * @dev Internal/DAO-callable function to update an Archetype's reputation based on performance or events.
     *      This would typically be triggered by an automated system or DAO governance based on Archetype performance metrics.
     * @param archetypeId The ID of the Archetype.
     * @param reputationDelta The amount by which reputation changes (can be positive or negative).
     * @param reason A string explaining the reason for the reputation update.
     */
    function recordArchetypePerformance(uint256 archetypeId, int256 reputationDelta, string calldata reason)
        public
        onlyOwner // Only owner (DAO) can call this for now
        whenNotPaused
    {
        require(archetypes[archetypeId].owner != address(0), "Archetype does not exist");
        archetypeReputations[archetypeId] += reputationDelta;
        archetypes[archetypeId].lastPerformanceUpdate = block.timestamp; // Update last activity

        emit ArchetypeReputationUpdated(
            archetypeId,
            archetypeReputations[archetypeId],
            reputationDelta,
            reason
        );
    }

    /**
     * @dev Retrieves the current reputation score of an Archetype.
     * @param archetypeId The ID of the Archetype.
     * @return The current reputation score.
     */
    function getArchetypeReputation(uint256 archetypeId) public view returns (int256) {
        require(archetypes[archetypeId].owner != address(0), "Archetype does not exist");
        return archetypeReputations[archetypeId];
    }

    // --- V. Decentralized Governance (Simplified DAO) ---

    /**
     * @dev Creates a new governance proposal.
     *      Anyone can propose, but only token holders (Archetype owners implied, or a specific governance token) can vote.
     *      For simplicity, `msg.sender` is the proposer.
     * @param targets Array of addresses to call.
     * @param values Array of ETH values to send with each call.
     * @param calldatas Array of calldata for each call.
     * @param description A description of the proposal.
     * @return The ID of the created proposal.
     */
    function propose(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        string calldata description
    ) public whenNotPaused returns (uint256) {
        require(targets.length == values.length && targets.length == calldatas.length, "Invalid proposal data length");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            targets: targets,
            values: values,
            calldatas: calldatas,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + VOTING_PERIOD,
            timelockEndTime: 0, // Not set until queued
            forVotes: 0,
            againstVotes: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }

    /**
     * @dev Allows Archetype owners (or specific governance token holders) to cast a vote on a proposal.
     *      Simplified: 1 Archetype owned = 1 vote. In production, this would use a governance token balance.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'for' vote, false for 'against'.
     */
    function castVote(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active for voting");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting not open");
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");

        // Simplified voting: Check if sender owns any Archetype
        // In a real DAO, this would check a governance token balance and potentially reputation.
        // For demonstration, assume 1 Archetype owned grants voting power.
        bool hasVotingPower = false;
        for (uint256 i = 1; i <= _archetypeIds.current(); i++) {
            if (ownerOf(i) == msg.sender) {
                hasVotingPower = true;
                break;
            }
        }
        require(hasVotingPower, "Caller has no voting power (owns no Archetype)");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @dev Gets the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The current state of the proposal.
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");

        if (proposal.state == ProposalState.Executed) return ProposalState.Executed;
        if (proposal.state == ProposalState.Canceled) return ProposalState.Canceled;

        if (block.timestamp < proposal.voteStartTime) return ProposalState.Pending;
        if (block.timestamp <= proposal.voteEndTime) return ProposalState.Active;

        // Voting period has ended
        if (proposal.forVotes <= proposal.againstVotes || (proposal.forVotes + proposal.againstVotes) < MIN_QUORUM_VOTES) {
            return ProposalState.Defeated;
        }

        if (proposal.executed) return ProposalState.Executed;
        if (proposal.timelockEndTime == 0) return ProposalState.Succeeded; // Succeeded, not yet queued
        if (block.timestamp < proposal.timelockEndTime) return ProposalState.Queued;
        return ProposalState.Expired; // Queued but timelock passed without execution
    }


    /**
     * @dev Queues an approved proposal for execution after a timelock.
     * @param proposalId The ID of the proposal to queue.
     */
    function queue(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(state(proposalId) == ProposalState.Succeeded, "Proposal not in Succeeded state");

        proposal.state = ProposalState.Queued;
        proposal.timelockEndTime = block.timestamp + TIMELOCK_DELAY;
        emit ProposalStateChanged(proposalId, ProposalState.Queued);
    }

    /**
     * @dev Executes a queued proposal.
     * @param proposalId The ID of the proposal to execute.
     */
    function execute(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(state(proposalId) == ProposalState.Queued, "Proposal not in Queued state or timelock not yet passed");
        require(block.timestamp >= proposal.timelockEndTime, "Timelock not yet passed");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, bytes memory result) = proposal.targets[i].call{value: proposal.values[i]}(proposal.calldatas[i]);
            require(success, string(abi.encodePacked("Execution failed for sub-call ", Strings.toString(i), ": ", result)));
        }

        emit ProposalExecuted(proposalId);
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

    /**
     * @dev Allows the DAO (via `execute` function) to collect accumulated protocol fees.
     * @param tokenAddress The address of the token to collect.
     */
    function collectProtocolFees(address tokenAddress) public onlyOwner {
        // This function should be called by the DAO's execute function
        uint256 totalFees = archetypeTreasuries[0][tokenAddress]; // Archetype ID 0 for protocol treasury
        require(totalFees > 0, "No fees to collect");

        archetypeTreasuries[0][tokenAddress] = 0; // Reset balance
        IERC20(tokenAddress).transfer(protocolFeeRecipient, totalFees);
        emit ProtocolFeesCollected(tokenAddress, totalFees);
    }

    /**
     * @dev Calculate and apply protocol fees from an Archetype's revenue.
     *      This is an internal helper function that would be called after Archetype earns revenue.
     * @param archetypeId The ID of the Archetype.
     * @param tokenAddress The address of the token earned.
     * @param revenueAmount The gross revenue amount.
     */
    function _applyProtocolFees(uint256 archetypeId, address tokenAddress, uint256 revenueAmount) internal {
        if (protocolFeeRateBps == 0 || revenueAmount == 0) {
            return;
        }

        uint256 feeAmount = (revenueAmount * protocolFeeRateBps) / 10000;
        uint256 netRevenue = revenueAmount - feeAmount;

        // Move fee portion to protocol treasury (Archetype ID 0)
        archetypeTreasuries[0][tokenAddress] += feeAmount;
        // Keep net revenue in Archetype's own treasury
        archetypeTreasuries[archetypeId][tokenAddress] += netRevenue;
    }

    // --- VI. Oracle Integration (Simplified) ---

    /**
     * @dev Registers a trusted oracle address for a specific data feed ID.
     *      Only the contract owner (DAO) can register oracles.
     * @param oracleAddress The address of the oracle.
     * @param feedId A unique identifier for the data feed (e.g., keccak256("ETH_USD_PRICE")).
     */
    function registerTrustedOracle(address oracleAddress, bytes32 feedId) public onlyOwner {
        require(oracleAddress != address(0), "Invalid oracle address");
        trustedOracles[feedId] = oracleAddress;
        emit OracleRegistered(feedId, oracleAddress);
    }

    /**
     * @dev Allows a registered oracle to push data updates to a specific feed.
     * @param feedId The unique identifier for the data feed.
     * @param value The updated data value.
     * @param timestamp The timestamp of the data (block.timestamp is recommended).
     */
    function updateOracleData(bytes32 feedId, uint256 value, uint256 timestamp) public onlyTrustedOracle(feedId) {
        oracleDataFeeds[feedId] = OracleData({value: value, timestamp: timestamp});
        emit OracleDataUpdated(feedId, value, timestamp);
    }

    /**
     * @dev Retrieves the latest data from a registered oracle feed.
     * @param feedId The unique identifier for the data feed.
     * @return The latest data value and its timestamp.
     */
    function getLatestOracleData(bytes32 feedId) public view returns (uint256 value, uint256 timestamp) {
        require(trustedOracles[feedId] != address(0), "Feed ID not registered or no trusted oracle");
        OracleData storage data = oracleDataFeeds[feedId];
        require(data.timestamp > 0, "No data available for this feed");
        return (data.value, data.timestamp);
    }

    // --- Internal/Helper Functions for DAO ---

    /**
     * @dev Internal function to create a proposal, used by `propose`.
     */
    function _propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) internal returns (uint256) {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            targets: targets,
            values: values,
            calldatas: calldatas,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + VOTING_PERIOD,
            timelockEndTime: 0,
            forVotes: 0,
            againstVotes: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }
}
```