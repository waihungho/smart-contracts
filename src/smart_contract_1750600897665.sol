Okay, let's design a smart contract that combines elements of programmable NFTs (or assets), a dynamic environment influenced by an oracle, resource management, and decentralized governance. We'll call it "ChronoForge Protocol".

The core idea is that users own unique digital assets called "Chronicles". These Chronicles have traits and dynamic "Lore". The protocol has a global "Environment Affinity" that changes based on external data provided by a trusted oracle. Users can send their Chronicles on "Expeditions". The success and rewards of an Expedition (including earning the protocol's "Essence" token and updating the Chronicle's Lore/Traits) depend on the Chronicle's properties and how well they align with the *current* Environment Affinity. There's also a forging mechanism to modify traits and a governance system to manage key parameters.

This design avoids direct copies of standard ERC contracts or well-known DeFi/NFT mechanisms while incorporating advanced concepts like dynamic asset state, oracle interaction driving core logic, and resource sinks. We will simulate the token behavior (ERC20-like Essence, ERC721-like Chronicles) within this single contract for the sake of fulfilling the "single contract with many functions" request, rather than deploying separate standard contracts.

---

**ChronoForge Protocol Smart Contract**

**Outline:**

1.  **Core Concepts:**
    *   **Chronicle:** A unique, programmable digital asset with traits and dynamic lore.
    *   **Essence:** A fungible utility/governance token used for actions and rewards.
    *   **Environment Affinity:** A global state parameter updated by an Oracle, affecting Expedition outcomes.
    *   **Expedition:** The core action loop where Chronicles interact with the Environment to earn Essence and update Lore.
    *   **Forging:** A mechanism to consume Essence and potentially modify Chronicle Traits.
    *   **Lore Scribing:** A mechanism to consume Essence and add/update Chronicle Lore.
    *   **Governance:** Allows Essence holders/delegates to propose and vote on parameter changes.
    *   **Oracle:** An address responsible for updating the Environment Affinity.

2.  **Data Structures:**
    *   `Chronicle`: Stores asset details (ID, owner, traits, lore, expedition status).
    *   `Trait`: Defines a type and strength for Chronicle properties.
    *   `LorePiece`: Stores dynamic data associated with a Chronicle (key-value pairs).
    *   `ExpeditionStatus`: Tracks if a Chronicle is currently on an expedition.
    *   `Environment`: Stores the current affinity data and last update time.
    *   `Proposal`: Stores details for governance votes (calldata, votes, state).

3.  **State Variables:**
    *   Mappings for Chronicle data (`chronicles`, `ownerChronicles`, `chronicleApprovals`).
    *   Mappings for Essence token data (`essenceBalances`, `essenceAllowances`).
    *   Global counters (`nextChronicleId`, `totalEssenceSupply`).
    *   Environment state (`currentEnvironment`).
    *   Protocol configurations (`expeditionConfig`, `forgingConfig`).
    *   Governance state (`proposals`, `nextProposalId`, `votingPower`, `delegates`, governance parameters).
    *   Access control addresses (`owner`, `oracleAddress`).

4.  **Events:** To signal key actions and state changes.

5.  **Modifiers:** For access control (`onlyOwner`, `onlyOracle`, `onlyGovExecute`).

6.  **Functions (20+):**
    *   Initialization/Admin (Set up parameters, update oracle).
    *   Oracle Interaction (Update environment).
    *   Chronicle Management (Mint, burn, simulate transfer/approval/ownership).
    *   Essence Management (Simulate transfer/approval/balance).
    *   Core Protocol Logic (Start/complete expedition, forge, scribe).
    *   Governance (Create/vote/execute proposals, delegate power).
    *   View/Getter Functions (Query state).

**Function Summary:**

1.  `constructor()`: Initializes the contract with the deployer as owner.
2.  `initializeProtocol(address _oracleAddress)`: Sets initial oracle address and potentially other default configs (callable once).
3.  `updateOracleAddress(address _newOracleAddress)`: Owner function to change the oracle address.
4.  `setExpeditionConfig(uint256 _baseEssenceCost, uint256 _minExpeditionDuration, uint256 _baseEssenceReward, uint256 _successChanceFactor)`: Admin function to set expedition parameters.
5.  `setForgingConfig(uint256 _essenceCost, uint256 _minTraitsRequired)`: Admin function to set forging parameters.
6.  `setGovernanceConfig(uint256 _minEssenceToPropose, uint256 _proposalVotingPeriod, uint256 _proposalThreshold)`: Admin function to set governance parameters.
7.  `updateEnvironmentAffinity(uint256 _affinityType, uint256 _affinityStrength)`: Called by the Oracle to update the global environment state.
8.  `mintChronicle()`: Allows anyone to mint a new Chronicle (e.g., for a fixed Essence cost or free initially), assigning initial traits and an ID.
9.  `burnChronicle(uint256 _chronicleId)`: Allows a Chronicle owner to destroy it, potentially receiving some Essence back.
10. `startExpedition(uint256 _chronicleId, uint256 _targetAffinityType)`: Owner of a Chronicle sends it on an expedition towards a specific affinity type. Costs Essence, locks the Chronicle.
11. `completeExpedition(uint256 _chronicleId)`: Owner attempts to complete an expedition. Calculates success based on Chronicle traits, lore, target affinity, and current environment affinity. Rewards Essence and updates Lore/Traits on success. Unlocks the Chronicle.
12. `forgeTrait(uint256 _chronicleId)`: Allows a Chronicle owner to attempt forging a new trait. Costs Essence, requires minimum traits. Success/trait type may depend on current environment/lore.
13. `scribeLore(uint256 _chronicleId, string calldata _key, string calldata _value)`: Allows a Chronicle owner to add or update a piece of Lore data. Costs Essence.
14. `transferChronicle(address _to, uint256 _chronicleId)`: Simulates ERC721 transfer logic.
15. `approveChronicle(address _approved, uint256 _chronicleId)`: Simulates ERC721 approval logic.
16. `transferEssence(address _to, uint256 _amount)`: Simulates ERC20 transfer logic for Essence.
17. `approveEssence(address _spender, uint256 _amount)`: Simulates ERC20 approval logic for Essence.
18. `transferFromEssence(address _from, address _to, uint256 _amount)`: Simulates ERC20 transferFrom logic for Essence.
19. `delegateVotingPower(address _delegatee)`: Allows an Essence holder to delegate their voting power.
20. `createProposal(string calldata _description, bytes calldata _callData)`: Allows an address with sufficient voting power to create a governance proposal to execute a specific function call on the contract.
21. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows addresses with voting power (or delegates) to vote on an active proposal.
22. `executeProposal(uint256 _proposalId)`: Anyone can call to execute a proposal that has passed the voting period and met the threshold.
23. `getChronicleTraits(uint256 _chronicleId)`: View function to get a Chronicle's traits.
24. `getChronicleLore(uint256 _chronicleId)`: View function to get a Chronicle's lore.
25. `getChronicleExpeditionStatus(uint256 _chronicleId)`: View function to get a Chronicle's current expedition status.
26. `getCurrentEnvironmentAffinity()`: View function to get the current global environment affinity.
27. `getEssenceBalance(address _holder)`: View function to get an address's Essence balance.
28. `getAllowanceEssence(address _owner, address _spender)`: View function to get the approved Essence amount.
29. `getProposalState(uint256 _proposalId)`: View function to get the current state (active, passed, failed, executed) of a proposal.
30. `getProposalVotes(uint256 _proposalId)`: View function to get the vote counts for a proposal.
31. `getTotalMintedChronicles()`: View function for the total number of Chronicles minted.
32. `getTotalEssenceSupply()`: View function for the total supply of Essence.
33. `ownerOfChronicle(uint256 _chronicleId)`: View function to get the owner of a Chronicle (simulated ERC721).

---
Let's write the Solidity code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronoForgeProtocol
 * @dev A smart contract for managing programmable digital assets (Chronicles)
 *      interacting with a dynamic environment influenced by an oracle,
 *      utilizing a native utility/governance token (Essence),
 *      and governed by decentralized proposals.
 *      This contract simulates core ERC20 and ERC721 behaviors internally
 *      for demonstration purposes within a single contract.
 */

// --- Outline ---
// 1. Core Concepts: Chronicle, Essence, Environment Affinity, Expedition, Forging, Lore Scribing, Governance, Oracle.
// 2. Data Structures: Chronicle, Trait, LorePiece, ExpeditionStatus, Environment, Proposal.
// 3. State Variables: Mappings for assets/tokens, global counters, environment state, configs, governance data, access control.
// 4. Events: Signal key actions.
// 5. Modifiers: Access control.
// 6. Functions (20+): Initialization/Admin, Oracle Interaction, Asset/Token Management (Simulated), Core Logic (Expedition, Forge, Scribe), Governance, View/Getters.

// --- Function Summary ---
// constructor(): Initializes contract owner.
// initializeProtocol(address _oracleAddress): Sets initial oracle and configs.
// updateOracleAddress(address _newOracleAddress): Changes oracle address (owner).
// setExpeditionConfig(...): Sets expedition parameters (admin/governance).
// setForgingConfig(...): Sets forging parameters (admin/governance).
// setGovernanceConfig(...): Sets governance parameters (admin/governance).
// updateEnvironmentAffinity(uint256 _affinityType, uint256 _affinityStrength): Updates environment (oracle).
// mintChronicle(): Creates a new Chronicle (user).
// burnChronicle(uint256 _chronicleId): Destroys a Chronicle (owner).
// startExpedition(uint256 _chronicleId, uint256 _targetAffinityType): Sends Chronicle on expedition (owner).
// completeExpedition(uint256 _chronicleId): Completes expedition, calculates results, rewards (owner).
// forgeTrait(uint256 _chronicleId): Attempts to add a new trait to Chronicle (owner).
// scribeLore(uint256 _chronicleId, string calldata _key, string calldata _value): Adds/updates Chronicle lore (owner).
// transferChronicle(address _to, uint256 _chronicleId): Simulate ERC721 transfer.
// approveChronicle(address _approved, uint256 _chronicleId): Simulate ERC721 approval.
// transferEssence(address _to, uint256 _amount): Simulate ERC20 transfer.
// approveEssence(address _spender, uint256 _amount): Simulate ERC20 approve.
// transferFromEssence(address _from, address _to, uint256 _amount): Simulate ERC20 transferFrom.
// delegateVotingPower(address _delegatee): Delegate governance voting power.
// createProposal(string calldata _description, bytes calldata _callData): Create a governance proposal.
// voteOnProposal(uint256 _proposalId, bool _support): Vote on a proposal.
// executeProposal(uint256 _proposalId): Execute a passed proposal.
// getChronicleTraits(uint256 _chronicleId): View Chronicle traits.
// getChronicleLore(uint256 _chronicleId): View Chronicle lore.
// getChronicleExpeditionStatus(uint256 _chronicleId): View Chronicle expedition status.
// getCurrentEnvironmentAffinity(): View current environment affinity.
// getEssenceBalance(address _holder): View Essence balance.
// getAllowanceEssence(address _owner, address _spender): View Essence allowance.
// getProposalState(uint256 _proposalId): View proposal state.
// getProposalVotes(uint256 _proposalId): View proposal vote counts.
// getTotalMintedChronicles(): View total chronicles.
// getTotalEssenceSupply(): View total essence supply.
// ownerOfChronicle(uint256 _chronicleId): View chronicle owner.


contract ChronoForgeProtocol {

    address public owner;
    address public oracleAddress;
    bool private initialized;

    // --- Data Structures ---

    enum ExpeditionStatus { Idle, OnExpedition }

    struct Trait {
        uint256 traitType;    // Represents different types of traits (e.g., 1=Fire, 2=Water, 3=Earth)
        uint256 strength;     // Strength/level of the trait
    }

    struct Chronicle {
        uint256 tokenId;
        address owner;
        Trait[] traits;
        mapping(string => string) lore; // Dynamic key-value storage for lore
        ExpeditionStatus expeditionStatus;
        uint256 expeditionStartTime;
        uint256 targetAffinityType; // The affinity type this expedition is targeting
        uint256 expeditionIdCounter; // Simple counter for unique expeditions
    }

    struct Environment {
        uint256 affinityType;    // Current dominant affinity type
        uint256 affinityStrength; // Current strength of the affinity
        uint256 lastUpdateTime;   // Timestamp of the last update
    }

    struct ExpeditionConfig {
        uint256 baseEssenceCost;
        uint256 minExpeditionDuration; // in seconds
        uint256 baseEssenceReward;
        uint256 successChanceFactor; // A multiplier for success calculation
        uint256 loreUpdateChance;    // Percentage chance (0-100) to update lore on success
    }

    struct ForgingConfig {
        uint256 essenceCost;
        uint256 minTraitsRequired; // Minimum traits chronicle must have to attempt forging
        uint256 successChance;     // Percentage chance (0-100) to successfully forge a trait
        uint256 newTraitStrength;  // Base strength for newly forged traits
    }

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // The function call to execute if proposal passes
        ProposalState state;
        uint256 voteCountYay;
        uint256 voteCountNay;
        mapping(address => bool) voted; // Track who has voted
        uint256 creationTime;
        uint256 votingEndTime;
    }

    // --- State Variables ---

    // Chronicles (Simulated ERC721)
    mapping(uint256 => Chronicle) public chronicles;
    mapping(address => uint256[]) private _ownerChronicles; // Helper for ownerOf/balanceOf
    mapping(uint256 => address) public chronicleApprovals;
    uint256 public nextChronicleId;
    uint256 public totalMintedChronicles; // Count of non-burned chronicles

    // Essence Token (Simulated ERC20)
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;
    uint256 private _totalEssenceSupply;

    // Environment
    Environment public currentEnvironment;

    // Configs
    ExpeditionConfig public expeditionConfig;
    ForgingConfig public forgingConfig;

    // Governance
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public minEssenceToPropose; // Minimum Essence balance needed to create a proposal
    uint256 public proposalVotingPeriod; // Duration of voting in seconds
    uint256 public proposalThreshold;   // Minimum 'Yay' votes (as percentage of total voting power) to succeed
    mapping(address => address) public delegates; // Who an address has delegated to
    mapping(address => uint256) public votingPower; // Snapshot of voting power when delegation occurs or proposal starts (simplified to current balance in this example)

    // Access Control
    address public admin; // A role between owner and general users

    // --- Events ---

    event ProtocolInitialized(address indexed owner, address indexed oracle);
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event ExpeditionConfigUpdated(ExpeditionConfig config);
    event ForgingConfigUpdated(ForgingConfig config);
    event GovernanceConfigUpdated(uint256 minEssence, uint256 votingPeriod, uint256 threshold);
    event EnvironmentAffinityUpdated(uint256 indexed affinityType, uint256 affinityStrength, uint256 timestamp);

    event ChronicleMinted(uint256 indexed tokenId, address indexed owner, uint256 initialTraitCount);
    event ChronicleBurned(uint256 indexed tokenId, address indexed owner);
    event ChronicleTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event ChronicleApproved(uint256 indexed tokenId, address indexed approved);

    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);
    event EssenceApproved(address indexed owner, address indexed spender, uint256 amount);

    event ExpeditionStarted(uint256 indexed tokenId, address indexed owner, uint256 targetAffinityType, uint256 startTime);
    event ExpeditionCompleted(uint256 indexed tokenId, address indexed owner, bool success, uint256 essenceReward, uint256 newLorePieces);
    event ExpeditionFailed(uint256 indexed tokenId, address indexed owner);

    event TraitForged(uint256 indexed tokenId, uint256 traitType, uint256 traitStrength);
    event LoreScribed(uint256 indexed tokenId, string key, string value);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == admin, "Only admin or owner");
        _;
    }

    modifier onlyGovExecute(uint256 _proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Succeeded, "Proposal not in Succeeded state");
        require(block.timestamp > proposal.votingEndTime, "Voting period not ended"); // Should have checked this in execute, but double check here
        require(proposal.executed == false, "Proposal already executed");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        nextChronicleId = 1; // Token IDs start from 1
        nextProposalId = 1;
        initialized = false;
        admin = address(0); // No admin initially
    }

    // --- Initialization & Admin Functions ---

    /**
     * @dev Initializes core protocol parameters. Callable only once.
     * @param _oracleAddress The address of the trusted oracle.
     */
    function initializeProtocol(address _oracleAddress) external onlyOwner {
        require(!initialized, "Protocol already initialized");
        require(_oracleAddress != address(0), "Invalid oracle address");

        oracleAddress = _oracleAddress;
        initialized = true;

        // Set some default configurations - these can be updated later by admin/governance
        expeditionConfig = ExpeditionConfig({
            baseEssenceCost: 10 ether, // Example: 10 Essence
            minExpeditionDuration: 1 hours, // Example: 1 hour
            baseEssenceReward: 20 ether, // Example: 20 Essence
            successChanceFactor: 100, // Higher means higher chance based on trait/env match
            loreUpdateChance: 50 // 50% chance to update lore on success
        });

        forgingConfig = ForgingConfig({
            essenceCost: 50 ether, // Example: 50 Essence
            minTraitsRequired: 2,
            successChance: 70, // 70% chance to forge
            newTraitStrength: 1 // Base strength for a new trait
        });

        minEssenceToPropose = 100 ether; // Example: Need 100 Essence to propose
        proposalVotingPeriod = 3 days; // Example: 3 days for voting
        proposalThreshold = 50; // Example: 50% + 1 of voting power needed (percentage)

        emit ProtocolInitialized(owner, oracleAddress);
        emit ExpeditionConfigUpdated(expeditionConfig);
        emit ForgingConfigUpdated(forgingConfig);
        emit GovernanceConfigUpdated(minEssenceToPropose, proposalVotingPeriod, proposalThreshold);
    }

    /**
     * @dev Updates the address of the oracle.
     * @param _newOracleAddress The new oracle address.
     */
    function updateOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "Invalid oracle address");
        emit OracleAddressUpdated(oracleAddress, _newOracleAddress);
        oracleAddress = _newOracleAddress;
    }

     /**
     * @dev Grants admin role to an address. Admin can change configs without governance.
     * @param _newAdmin The address to grant admin role to.
     */
    function grantAdminRole(address _newAdmin) external onlyOwner {
         require(_newAdmin != address(0), "Invalid admin address");
         admin = _newAdmin;
    }

    /**
     * @dev Revokes admin role from an address.
     * @param _oldAdmin The address to revoke admin role from.
     */
    function revokeAdminRole(address _oldAdmin) external onlyOwner {
         require(_oldAdmin == admin, "Address is not the current admin");
         admin = address(0);
    }

    /**
     * @dev Sets the configuration parameters for expeditions.
     * @param _baseEssenceCost Cost in Essence to start an expedition.
     * @param _minExpeditionDuration Minimum duration an expedition must last (seconds).
     * @param _baseEssenceReward Base Essence reward for successful expeditions.
     * @param _successChanceFactor Multiplier affecting success chance calculation.
     * @param _loreUpdateChance Percentage chance (0-100) to update lore on success.
     */
    function setExpeditionConfig(
        uint256 _baseEssenceCost,
        uint256 _minExpeditionDuration,
        uint256 _baseEssenceReward,
        uint256 _successChanceFactor,
        uint256 _loreUpdateChance
    ) external onlyAdmin {
        expeditionConfig = ExpeditionConfig(_baseEssenceCost, _minExpeditionDuration, _baseEssenceReward, _successChanceFactor, _loreUpdateChance);
        emit ExpeditionConfigUpdated(expeditionConfig);
    }

    /**
     * @dev Sets the configuration parameters for forging traits.
     * @param _essenceCost Cost in Essence to attempt forging.
     * @param _minTraitsRequired Minimum number of traits a Chronicle must have.
     * @param _successChance Percentage chance (0-100) of successful forging.
     * @param _newTraitStrength Base strength of a newly forged trait.
     */
    function setForgingConfig(
        uint256 _essenceCost,
        uint256 _minTraitsRequired,
        uint256 _successChance,
        uint256 _newTraitStrength
    ) external onlyAdmin {
        forgingConfig = ForgingConfig(_essenceCost, _minTraitsRequired, _successChance, _newTraitStrength);
        emit ForgingConfigUpdated(forgingConfig);
    }

    /**
     * @dev Sets the configuration parameters for governance.
     * @param _minEssenceToPropose Minimum Essence balance to create a proposal.
     * @param _proposalVotingPeriod Duration of voting period in seconds.
     * @param _proposalThreshold Minimum 'Yay' votes (as percentage of total voting power) to succeed.
     */
     function setGovernanceConfig(
        uint256 _minEssenceToPropose,
        uint256 _proposalVotingPeriod,
        uint256 _proposalThreshold
    ) external onlyAdmin {
        minEssenceToPropose = _minEssenceToPropose;
        proposalVotingPeriod = _proposalVotingPeriod;
        proposalThreshold = _proposalThreshold;
        emit GovernanceConfigUpdated(_minEssenceToPropose, _proposalVotingPeriod, _proposalThreshold);
    }

    // --- Oracle Interaction ---

    /**
     * @dev Updates the global environment affinity. Callable only by the designated oracle address.
     * @param _affinityType The new dominant affinity type.
     * @param _affinityStrength The strength of the new affinity.
     */
    function updateEnvironmentAffinity(uint256 _affinityType, uint256 _affinityStrength) external onlyOracle {
        currentEnvironment = Environment(_affinityType, _affinityStrength, block.timestamp);
        emit EnvironmentAffinityUpdated(_affinityType, _affinityStrength, block.timestamp);
    }

    // --- Chronicle (Simulated ERC721) Management ---

    /**
     * @dev Mints a new Chronicle token and assigns it to the caller.
     * Simulates initial random traits. Costs Essence.
     */
    function mintChronicle() external {
        // Require Essence cost (example)
        uint256 mintCost = 5 ether; // Example cost
        require(_essenceBalances[msg.sender] >= mintCost, "Not enough Essence to mint");
        _burnEssence(msg.sender, mintCost);

        uint256 tokenId = nextChronicleId++;
        totalMintedChronicles++;

        Chronicle storage newChronicle = chronicles[tokenId];
        newChronicle.tokenId = tokenId;
        newChronicle.owner = msg.sender;
        newChronicle.expeditionStatus = ExpeditionStatus.Idle;
        newChronicle.expeditionIdCounter = 0; // Initialize expedition counter

        // Simulate assigning some random initial traits
        uint256 initialTraitCount = 2; // Example: starts with 2 traits
        for (uint256 i = 0; i < initialTraitCount; i++) {
             // Simple pseudo-random trait generation (not secure)
             uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, i)));
             uint256 traitType = (randomSeed % 5) + 1; // Example: 5 possible trait types (1-5)
             uint256 strength = (randomSeed % 10) + 1; // Example: strength 1-10
             newChronicle.traits.push(Trait(traitType, strength));
        }

        _ownerChronicles[msg.sender].push(tokenId); // Add to owner's list

        emit ChronicleMinted(tokenId, msg.sender, newTraitCount);
    }

    /**
     * @dev Burns (destroys) a Chronicle token.
     * @param _chronicleId The ID of the Chronicle to burn.
     */
    function burnChronicle(uint256 _chronicleId) external {
        require(chronicles[_chronicleId].owner == msg.sender, "Not your Chronicle");
        require(chronicles[_chronicleId].expeditionStatus == ExpeditionStatus.Idle, "Cannot burn while on expedition");

        address currentOwner = msg.sender;
        delete chronicleApprovals[_chronicleId]; // Clear any approval
        delete chronicles[_chronicleId]; // Delete the chronicle data
        totalMintedChronicles--;

        // Remove from owner's list (inefficient for large lists)
        uint256[] storage ownersTokens = _ownerChronicles[currentOwner];
        for (uint256 i = 0; i < ownersTokens.length; i++) {
            if (ownersTokens[i] == _chronicleId) {
                ownersTokens[i] = ownersTokens[ownersTokens.length - 1];
                ownersTokens.pop();
                break;
            }
        }

        // Optional: Refund some essence on burn
        uint256 refundAmount = 2 ether; // Example refund
        _mintEssence(currentOwner, refundAmount);

        emit ChronicleBurned(_chronicleId, currentOwner);
        emit EssenceTransferred(address(0), currentOwner, refundAmount); // Signal refund as a mint from zero address
    }

    /**
     * @dev Transfers a Chronicle token. Simulates ERC721 transferFrom.
     * @param _from The current owner (or approved address).
     * @param _to The recipient address.
     * @param _chronicleId The ID of the Chronicle to transfer.
     */
    function transferChronicle(address _from, address _to, uint256 _chronicleId) public {
        address currentOwner = chronicles[_chronicleId].owner;
        require(currentOwner != address(0), "Chronicle does not exist");
        require(currentOwner == _from, "Incorrect from address");
        require(_to != address(0), "Cannot transfer to zero address");
        require(msg.sender == currentOwner || chronicleApprovals[_chronicleId] == msg.sender, "Not authorized to transfer");
        require(chronicles[_chronicleId].expeditionStatus == ExpeditionStatus.Idle, "Cannot transfer while on expedition");


        // Update owner's lists (inefficient)
        uint256[] storage fromTokens = _ownerChronicles[_from];
        for (uint256 i = 0; i < fromTokens.length; i++) {
            if (fromTokens[i] == _chronicleId) {
                fromTokens[i] = fromTokens[fromTokens.length - 1];
                fromTokens.pop();
                break;
            }
        }
        _ownerChronicles[_to].push(_chronicleId);

        chronicles[_chronicleId].owner = _to;
        delete chronicleApprovals[_chronicleId]; // Clear approval after transfer

        emit ChronicleTransferred(_chronicleId, _from, _to);
    }

    /**
     * @dev Approves an address to manage a specific Chronicle. Simulates ERC721 approve.
     * @param _approved The address to approve.
     * @param _chronicleId The ID of the Chronicle.
     */
    function approveChronicle(address _approved, uint256 _chronicleId) external {
        require(chronicles[_chronicleId].owner == msg.sender, "Not your Chronicle to approve");
        chronicleApprovals[_chronicleId] = _approved;
        emit ChronicleApproved(_chronicleId, _approved);
    }


    // --- Essence Token (Simulated ERC20) Management ---

    /**
     * @dev Mints Essence tokens to a recipient. Only callable internally or by governance/admin logic.
     */
    function _mintEssence(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");
        _totalEssenceSupply += amount;
        _essenceBalances[account] += amount;
        // No event here, called internally by other functions which emit their own events
    }

    /**
     * @dev Burns Essence tokens from an account. Only callable internally or by governance/admin logic.
     */
     function _burnEssence(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");
        require(_essenceBalances[account] >= amount, "Burn amount exceeds balance");
        _essenceBalances[account] -= amount;
        _totalEssenceSupply -= amount;
         // No event here, called internally by other functions which emit their own events
    }

    /**
     * @dev Internal function to transfer Essence.
     */
    function _transferEssence(address from, address to, uint256 amount) internal {
         require(from != address(0), "Transfer from the zero address");
         require(to != address(0), "Transfer to the zero address");
         require(_essenceBalances[from] >= amount, "Transfer amount exceeds balance");

         _essenceBalances[from] -= amount;
         _essenceBalances[to] += amount;
         emit EssenceTransferred(from, to, amount);
    }


    /**
     * @dev Transfers Essence tokens. Simulates ERC20 transfer.
     * @param _to The recipient address.
     * @param _amount The amount of Essence to transfer.
     */
    function transferEssence(address _to, uint256 _amount) external {
        _transferEssence(msg.sender, _to, _amount);
    }

    /**
     * @dev Approves a spender to withdraw Essence from the caller's account. Simulates ERC20 approve.
     * @param _spender The address to approve.
     * @param _amount The amount to approve.
     */
    function approveEssence(address _spender, uint256 _amount) external {
        _essenceAllowances[msg.sender][_spender] = _amount;
        emit EssenceApproved(msg.sender, _spender, _amount);
    }

    /**
     * @dev Transfers Essence from one address to another using the allowance mechanism. Simulates ERC20 transferFrom.
     * @param _from The sender address.
     * @param _to The recipient address.
     * @param _amount The amount to transfer.
     */
    function transferFromEssence(address _from, address _to, uint256 _amount) external {
        uint256 currentAllowance = _essenceAllowances[_from][msg.sender];
        require(currentAllowance >= _amount, "Transfer amount exceeds allowance");
        _essenceAllowances[_from][msg.sender] = currentAllowance - _amount;
        _transferEssence(_from, _to, _amount);
    }

    // --- Core Protocol Logic ---

    /**
     * @dev Sends a Chronicle on an expedition. Requires Essence cost and locks the Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     * @param _targetAffinityType The affinity type the expedition is focused on (e.g., 1-5).
     */
    function startExpedition(uint256 _chronicleId, uint256 _targetAffinityType) external {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.owner == msg.sender, "Not your Chronicle");
        require(chronicle.expeditionStatus == ExpeditionStatus.Idle, "Chronicle is already on an expedition");
        require(_essenceBalances[msg.sender] >= expeditionConfig.baseEssenceCost, "Not enough Essence for expedition cost");
        require(_targetAffinityType > 0, "Invalid target affinity type"); // Example validation

        _burnEssence(msg.sender, expeditionConfig.baseEssenceCost); // Consume Essence
        chronicle.expeditionStatus = ExpeditionStatus.OnExpedition;
        chronicle.expeditionStartTime = block.timestamp;
        chronicle.targetAffinityType = _targetAffinityType;
        chronicle.expeditionIdCounter++; // Increment for potential random seed

        emit ExpeditionStarted(_chronicleId, msg.sender, _targetAffinityType, block.timestamp);
    }

    /**
     * @dev Attempts to complete an expedition. Calculates success, rewards Essence, updates Lore/Traits.
     * @param _chronicleId The ID of the Chronicle.
     */
    function completeExpedition(uint256 _chronicleId) external {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.owner == msg.sender, "Not your Chronicle");
        require(chronicle.expeditionStatus == ExpeditionStatus.OnExpedition, "Chronicle is not on an expedition");
        require(block.timestamp >= chronicle.expeditionStartTime + expeditionConfig.minExpeditionDuration, "Expedition duration not met");

        // Calculate expedition success chance
        uint256 successChance = calculateExpeditionSuccessChance(chronicle);

        // Determine success using a pseudo-random number (NOT cryptographically secure)
        // For a real application, use Chainlink VRF or similar.
        uint256 randomness = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Can be manipulated by miners
            chronicle.tokenId,
            chronicle.expeditionIdCounter,
            msg.sender
        )));
        uint256 randomPercentage = (randomness % 100) + 1; // 1 to 100

        bool success = randomPercentage <= successChance;

        uint256 essenceReward = 0;
        uint256 loreUpdatesCount = 0;

        if (success) {
            // Calculate reward (can be more complex)
            essenceReward = expeditionConfig.baseEssenceReward;
            _mintEssence(msg.sender, essenceReward);

            // Check for Lore update
            uint256 loreRandomness = uint256(keccak256(abi.encodePacked(randomness, "lore")));
            if ((loreRandomness % 100) < expeditionConfig.loreUpdateChance) {
                // Simulate a simple lore update - add a timestamp or outcome summary
                string memory key = string(abi.encodePacked("Expedition_", Strings.toString(chronicle.expeditionIdCounter)));
                string memory value = string(abi.encodePacked("Success @ ", Strings.toString(block.timestamp)));
                chronicle.lore[key] = value;
                loreUpdatesCount = 1;
                emit LoreScribed(_chronicleId, key, value); // Emit lore update event
            }

            // Optional: Small chance to gain a trait or improve one on success
             uint256 traitRandomness = uint256(keccak256(abi.encodePacked(randomness, "trait")));
             if ((traitRandomness % 100) < 5) { // 5% chance to gain/improve trait
                  uint256 numTraits = chronicle.traits.length;
                  if (numTraits < 5) { // Limit max traits
                       uint256 traitType = (traitRandomness % 5) + 1; // Example: 5 possible trait types
                       uint256 strength = (traitRandomness % 3) + 1; // Small strength boost
                       chronicle.traits.push(Trait(traitType, strength));
                       emit TraitForged(_chronicleId, traitType, strength); // Re-use trait forged event
                  } else { // If max traits, improve a random one
                       uint256 traitIndex = traitRandomness % numTraits;
                       chronicle.traits[traitIndex].strength += 1;
                       emit TraitForged(_chronicleId, chronicle.traits[traitIndex].traitType, chronicle.traits[traitIndex].strength); // Emit with new strength
                  }
             }

            emit ExpeditionCompleted(_chronicleId, msg.sender, true, essenceReward, loreUpdatesCount);

        } else {
            // Handle failure (e.g., no reward, potential small lore penalty or just a log)
             string memory key = string(abi.encodePacked("Expedition_", Strings.toString(chronicle.expeditionIdCounter)));
             string memory value = string(abi.encodePacked("Failure @ ", Strings.toString(block.timestamp)));
             chronicle.lore[key] = value; // Log failure in lore
             loreUpdatesCount = 1;
             emit LoreScribed(_chronicleId, key, value); // Emit lore update event

            emit ExpeditionFailed(_chronicleId, msg.sender);
        }

        // Reset expedition status
        chronicle.expeditionStatus = ExpeditionStatus.Idle;
        chronicle.expeditionStartTime = 0;
        chronicle.targetAffinityType = 0;
    }

    /**
     * @dev Calculates the success chance for an expedition based on Chronicle traits,
     * target affinity, and current environment affinity.
     * @param _chronicle The Chronicle struct.
     * @return successChance Percentage chance (0-100).
     */
    function calculateExpeditionSuccessChance(Chronicle storage _chronicle) internal view returns (uint256) {
        // Example calculation logic:
        // Success chance starts base + (sum of trait strength * affinity match factor)
        // Affinity match factor could be higher if trait.type == environment.type or trait.type == target.type

        uint256 baseChance = 30; // Base 30% chance
        uint256 affinityBonus = 0;

        for (uint256 i = 0; i < _chronicle.traits.length; i++) {
            Trait storage trait = _chronicle.traits[i];
            uint256 traitMatchFactor = 1; // Base factor

            if (trait.traitType == currentEnvironment.affinityType) {
                traitMatchFactor += 1; // Bonus for matching current environment
            }
             if (trait.traitType == _chronicle.targetAffinityType) {
                traitMatchFactor += 2; // Bigger bonus for matching target
            }
            // Could also add penalty for mismatching or add Lore influence

            affinityBonus += (trait.strength * traitMatchFactor);
        }

        uint256 totalChance = baseChance + (affinityBonus * expeditionConfig.successChanceFactor / 100); // Scale by factor
        return Math.min(totalChance, 95); // Cap chance at 95%
    }


    /**
     * @dev Attempts to forge a new trait onto a Chronicle. Costs Essence.
     * Chance of success is configured. New trait type/strength is simulated.
     * @param _chronicleId The ID of the Chronicle.
     */
    function forgeTrait(uint256 _chronicleId) external {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.owner == msg.sender, "Not your Chronicle");
        require(chronicle.expeditionStatus == ExpeditionStatus.Idle, "Cannot forge while on expedition");
        require(_essenceBalances[msg.sender] >= forgingConfig.essenceCost, "Not enough Essence for forging cost");
        require(chronicle.traits.length >= forgingConfig.minTraitsRequired, "Chronicle needs more traits to forge");
        require(chronicle.traits.length < 10, "Chronicle cannot have more than 10 traits"); // Max trait limit

        _burnEssence(msg.sender, forgingConfig.essenceCost); // Consume Essence

        // Simulate success chance using pseudo-random (NOT secure)
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _chronicleId, chronicle.traits.length)));
        uint256 randomPercentage = (randomness % 100) + 1; // 1 to 100

        if (randomPercentage <= forgingConfig.successChance) {
            // Success: Forge a new trait
            uint256 traitType = (randomness % 5) + 1; // Example: 5 possible trait types (1-5)
            uint256 strength = forgingConfig.newTraitStrength; // Base strength

            chronicle.traits.push(Trait(traitType, strength));
            emit TraitForged(_chronicleId, traitType, strength);

        } else {
            // Failure: Essence is still consumed, maybe add failure lore?
            string memory key = string(abi.encodePacked("ForgeFail_", Strings.toString(block.timestamp)));
            string memory value = "Forging attempt failed.";
            chronicle.lore[key] = value;
             emit LoreScribed(_chronicleId, key, value); // Log failure
        }
    }

    /**
     * @dev Adds or updates a piece of Lore data on a Chronicle. Costs Essence.
     * @param _chronicleId The ID of the Chronicle.
     * @param _key The key for the lore entry.
     * @param _value The value for the lore entry.
     */
    function scribeLore(uint256 _chronicleId, string calldata _key, string calldata _value) external {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.owner == msg.sender, "Not your Chronicle");
        require(chronicle.expeditionStatus == ExpeditionStatus.Idle, "Cannot scribe lore while on expedition");
        uint256 scribeCost = 1 ether; // Example cost
        require(_essenceBalances[msg.sender] >= scribeCost, "Not enough Essence for scribing cost");

        _burnEssence(msg.sender, scribeCost); // Consume Essence
        chronicle.lore[_key] = _value; // Add or update lore
        emit LoreScribed(_chronicleId, _key, _value);
    }


    // --- Governance Functions ---

    /**
     * @dev Delegates voting power from the caller to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) external {
        address currentDelegate = delegates[msg.sender];
        require(currentDelegate != _delegatee, "Already delegated to this address");
        delegates[msg.sender] = _delegatee;
        emit DelegateChanged(msg.sender, currentDelegate, _delegatee);
        // Note: For accurate voting power, this would ideally involve checkpoints
        // based on balance *at the time of delegation or proposal creation*.
        // This simplified example uses current balance for voting power.
    }

    /**
     * @dev Gets the voting power of an address. Simplified to use current Essence balance.
     * In a real DAO, this would likely use checkpoints based on historical balance or locked tokens.
     * @param _voter The address to check voting power for.
     * @return The current voting power (Essence balance).
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        // In a real DAO, this would resolve delegation and check historical balance snapshots.
        // For this example, we simplify to the current balance of the delegatee.
        address delegatee = delegates[_voter] == address(0) ? _voter : delegates[_voter];
        return _essenceBalances[delegatee];
    }

    /**
     * @dev Creates a new governance proposal.
     * @param _description The description of the proposal.
     * @param _callData The encoded function call to be executed if the proposal passes.
     */
    function createProposal(string calldata _description, bytes calldata _callData) external {
        require(_essenceBalances[msg.sender] >= minEssenceToPropose, "Not enough Essence to propose"); // Basic check
        require(_callData.length > 0, "Call data is required");

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = _description;
        proposal.callData = _callData;
        proposal.state = ProposalState.Active;
        proposal.creationTime = block.timestamp;
        proposal.votingEndTime = block.timestamp + proposalVotingPeriod;

        emit ProposalCreated(proposalId, msg.sender, _description);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
    }

    /**
     * @dev Allows an address (or their delegatee) to vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for Yay (support), False for Nay (oppose).
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");

        address voter = msg.sender; // Voting using own power
        address delegatee = delegates[voter]; // Check if delegated
        address actualVoter = delegatee == address(0) ? voter : delegatee;

        require(!proposal.voted[actualVoter], "Already voted on this proposal");

        uint256 voterVotingPower = getVotingPower(actualVoter);
        require(voterVotingPower > 0, "No voting power");

        proposal.voted[actualVoter] = true;

        if (_support) {
            proposal.voteCountYay += voterVotingPower;
        } else {
            proposal.voteCountNay += voterVotingPower;
        }

        emit VoteCast(_proposalId, actualVoter, _support, voterVotingPower);
    }

    /**
     * @dev Transitions proposal state and executes the proposal's function call if successful.
     * Callable by anyone once the voting period has ended.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal must be active to execute");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        // Calculate total voting power snapshot at the end of the proposal?
        // Simplified: Calculate total power based on *current* total supply for percentage threshold check
        uint256 totalVotingPower = _totalEssenceSupply; // Simplified total supply as total power

        // Check if threshold met
        uint256 requiredYayVotes = (totalVotingPower * proposalThreshold) / 100;

        if (proposal.voteCountYay > requiredYayVotes) {
            proposal.state = ProposalState.Succeeded;
            emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);

            // Execute the proposal's function call
            // Using low-level call, be cautious of the target and calldata
            (bool success, ) = address(this).call(proposal.callData);
            require(success, "Proposal execution failed");

            proposal.executed = true;
            emit ProposalExecuted(_proposalId);

        } else {
            proposal.state = ProposalState.Defeated;
            emit ProposalStateChanged(_proposalId, ProposalState.Defeated);
        }
    }


    // --- View / Getter Functions ---

    /**
     * @dev Gets the traits of a Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     * @return An array of Trait structs.
     */
    function getChronicleTraits(uint256 _chronicleId) external view returns (Trait[] memory) {
        require(chronicles[_chronicleId].owner != address(0), "Chronicle does not exist");
        return chronicles[_chronicleId].traits;
    }

     /**
     * @dev Gets a specific lore value for a Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     * @param _key The key for the lore entry.
     * @return The value of the lore entry.
     */
    function getChronicleLore(uint256 _chronicleId, string calldata _key) external view returns (string memory) {
        require(chronicles[_chronicleId].owner != address(0), "Chronicle does not exist");
        return chronicles[_chronicleId].lore[_key];
    }

    /**
     * @dev Gets the current expedition status of a Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     * @return The ExpeditionStatus enum value.
     */
    function getChronicleExpeditionStatus(uint256 _chronicleId) external view returns (ExpeditionStatus) {
        require(chronicles[_chronicleId].owner != address(0), "Chronicle does not exist");
        return chronicles[_chronicleId].expeditionStatus;
    }

    /**
     * @dev Gets the current environment affinity state.
     * @return The Environment struct.
     */
    function getCurrentEnvironmentAffinity() external view returns (Environment memory) {
        return currentEnvironment;
    }

    /**
     * @dev Gets the Essence balance of an address. Simulates ERC20 balanceOf.
     * @param _holder The address to check the balance for.
     * @return The Essence balance.
     */
    function getEssenceBalance(address _holder) external view returns (uint256) {
        return _essenceBalances[_holder];
    }

    /**
     * @dev Gets the approved amount of Essence a spender can withdraw from an owner. Simulates ERC20 allowance.
     * @param _owner The address whose funds are approved.
     * @param _spender The address approved to spend.
     * @return The approved amount.
     */
    function getAllowanceEssence(address _owner, address _spender) external view returns (uint256) {
        return _essenceAllowances[_owner][_spender];
    }

    /**
     * @dev Gets the current state of a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The ProposalState enum value.
     */
    function getProposalState(uint256 _proposalId) external view returns (ProposalState) {
         Proposal storage proposal = proposals[_proposalId];
         if (proposal.id == 0) return ProposalState.Pending; // Proposal doesn't exist

         if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingEndTime) {
             // Voting period ended, determine state (this check is normally done before execution)
             // For view function, we can derive it, but state is only *officially* updated on execute
             // Simplified: return current state, state transition happens on executeProposal.
             return proposal.state;
         }

        return proposal.state;
    }

    /**
     * @dev Gets the vote counts for a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return yayVotes Total 'Yay' votes.
     * @return nayVotes Total 'Nay' votes.
     */
    function getProposalVotes(uint256 _proposalId) external view returns (uint256 yayVotes, uint256 nayVotes) {
        require(proposals[_proposalId].id != 0, "Proposal does not exist");
        return (proposals[_proposalId].voteCountYay, proposals[_proposalId].voteCountNay);
    }

    /**
     * @dev Gets the total number of Chronicles that have been minted and not burned.
     * @return The total count of Chronicles.
     */
    function getTotalMintedChronicles() external view returns (uint256) {
        return totalMintedChronicles;
    }

     /**
     * @dev Gets the total circulating supply of Essence tokens. Simulates ERC20 totalSupply.
     * @return The total supply of Essence.
     */
    function getTotalEssenceSupply() external view returns (uint256) {
        return _totalEssenceSupply;
    }

     /**
     * @dev Gets the owner of a Chronicle. Simulates ERC721 ownerOf.
     * @param _chronicleId The ID of the Chronicle.
     * @return The owner address.
     */
    function ownerOfChronicle(uint256 _chronicleId) external view returns (address) {
        return chronicles[_chronicleId].owner;
    }

    /**
     * @dev Gets the number of Chronicles owned by an address. Simulates ERC721 balanceOf.
     * Note: This implementation iterates over the private _ownerChronicles array,
     * which can be inefficient for addresses with many tokens.
     * @param _owner The address to check.
     * @return The number of Chronicles owned.
     */
    function balanceOfChronicles(address _owner) external view returns (uint256) {
        return _ownerChronicles[_owner].length;
    }


    // --- Internal Helpers ---

    /**
     * @dev Simple string conversion utility (for lore keys/values).
     * Note: More robust libraries exist (e.g., OpenZeppelin Strings)
     * but implementing a basic one here for the example.
     */
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint252(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }

    /**
     * @dev Simple Math utility.
     */
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
    }
}
```