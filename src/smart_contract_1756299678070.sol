This smart contract, **Chrysalis Protocol**, introduces a decentralized ecosystem managed by a swarm of dynamic NFTs called "Cognitive Agents" (C-Agents). These C-Agents possess evolving attributes like Processing Power, Resilience, Adaptability Score, and Karma Score, which change based on staked resources, contributions to protocol tasks, simulated environmental stimuli, and novel "Synaptic Links" for attribute transfer. The protocol aims to demonstrate emergent swarm intelligence and adaptive governance without relying on traditional oracles for every dynamic parameter adjustment, instead simulating environmental factors and allowing for collective, gamified contributions.

---

### Outline: Chrysalis Protocol - Adaptive Swarm Intelligence for Decentralized Ecosystems

**I. Core Infrastructure & Protocol Management**
    - Foundation, parameter setting, emergency controls.
**II. C-Agent (Dynamic NFT) Management**
    - Minting, staking resources, attribute evolution, decay, and transfers.
**III. Adaptive Core & Environmental Simulation**
    - Mechanisms for the protocol to adapt, respond to simulated external stimuli, and distribute rewards based on collective performance.
**IV. Protocol Tasks & Collaborative Contributions**
    - System for users to propose, contribute to, and resolve tasks, fostering collaboration and earning rewards.
**V. Synaptic Link - Dynamic Trait Transfer**
    - A novel mechanism allowing C-Agents to strategically share or transfer attributes, promoting emergent swarm behaviors.

---

### Function Summary:

**I. Core Infrastructure & Protocol Management**
1.  **`constructor(address _energyTokenAddress, string memory _name, string memory _symbol)`**: Initializes the protocol, deploys the C-Agent NFT contract, and sets the initial owner.
2.  **`setProtocolParameters(uint256 _mintCost, uint256 _minStakeEnergy, uint256 _decayRate, uint256 _taskProposalFee, uint256 _synapticLinkFee)`**: Allows the owner to configure core operational parameters of the protocol.
3.  **`toggleProtocolPause()`**: Pauses or unpauses the protocol, useful for upgrades or emergency situations, restricting most state-changing operations.
4.  **`setOracleAddress(address _newOracle)`**: Designates an address that can trigger environmental stimuli, separate from the owner.

**II. C-Agent (Dynamic NFT) Management**
5.  **`mintCAgent()`**: Mints a new C-Agent NFT for the caller, burning `EnergyToken` as cost and assigning initial base attributes.
6.  **`stakeEnergyForCAgent(uint256 _tokenId, uint256 _amount)`**: Allows an owner to stake `EnergyToken` to a specific C-Agent, boosting its performance attributes.
7.  **`unstakeEnergyFromCAgent(uint256 _tokenId, uint256 _amount)`**: Enables an owner to unstake `EnergyToken` from a C-Agent, which may result in a reduction of its attributes over time.
8.  **`getCAgentAttributes(uint256 _tokenId)`**: Retrieves the current dynamic attributes of a specified C-Agent.
9.  **`evolveCAgent(uint256 _tokenId)`**: Triggers an individual C-Agent's attribute update based on accumulated staked energy, task contributions, and the effects of recent environmental stimuli.
10. **`decayCAgentAttributes(uint256 _tokenId)`**: Applies a periodic decay to a C-Agent's attributes if it's not actively maintained (e.g., no recent staking or contributions), simulating entropy.

**III. Adaptive Core & Environmental Simulation**
11. **`triggerEnvironmentalStimulus(EnvironmentalType _type, uint256 _intensity)`**: A designated oracle/role injects a simulated "challenge" or "opportunity" into the ecosystem, influencing how C-Agents evolve and perform.
12. **`updateAdaptiveAlgorithmWeights(uint256 _processingWeight, uint256 _resilienceWeight, uint256 _adaptabilityWeight, uint256 _karmaWeight)`**: Owner/governance adjusts the weights used in the adaptive algorithm for attribute calculation and reward distribution, allowing for dynamic protocol tuning.
13. **`calculateGlobalAdaptabilityScore()`**: Aggregates all C-Agent attributes to determine the overall swarm's "adaptability," influencing protocol-wide parameters like reward rates or task difficulty.
14. **`distributeAdaptiveRewards()`**: Distributes a portion of protocol fees or newly minted `EnergyToken` based on the `GlobalAdaptabilityScore` and individual agent contributions to incentivize overall swarm health.

**IV. Protocol Tasks & Collaborative Contributions**
15. **`proposeProtocolTask(string memory _description, uint256 _requiredProcessingPower, uint256 _rewardPoolAmount)`**: Users can propose new tasks for the C-Agent swarm to solve, requiring a `taskProposalFee`.
16. **`contributeToTask(uint256 _taskId, uint256 _tokenId)`**: Owners stake their C-Agents to contribute to an active task, committing their agent's `processingPower` towards its completion.
17. **`resolveProtocolTask(uint256 _taskId)`**: Owner/governance/designated role resolves a task, calculating and allocating `EnergyToken` rewards to contributing agents based on their contribution efficiency and `karmaScore`.
18. **`claimTaskRewards(uint256 _taskId, uint256 _tokenId)`**: Allows C-Agent owners to claim their earned rewards from successfully resolved tasks.

**V. Synaptic Link - Dynamic Trait Transfer**
19. **`requestSynapticLink(uint256 _sourceTokenId, uint256 _targetTokenId, TraitType _traitToTransfer, uint256 _transferAmount)`**: An owner requests a "synaptic link" between two C-Agents (their own or others) to transfer a specific trait (`ProcessingPower`, `Resilience`, etc.) from source to target. Requires a `synapticLinkFee`.
20. **`approveSynapticLink(uint256 _linkId)`**: The owner of the target C-Agent approves a pending synaptic link request, consenting to the trait transfer.
21. **`executeSynapticTransfer(uint256 _linkId)`**: Finalizes the attribute transfer after approval, modifying both source and target C-Agents' attributes according to the link parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Outline: Chrysalis Protocol - Adaptive Swarm Intelligence for Decentralized Ecosystems
//
// I. Core Infrastructure & Protocol Management
//    - Foundation, parameter setting, emergency controls.
// II. C-Agent (Dynamic NFT) Management
//    - Minting, staking resources, attribute evolution, decay, and transfers.
// III. Adaptive Core & Environmental Simulation
//    - Mechanisms for the protocol to adapt, respond to simulated external stimuli, and distribute rewards based on collective performance.
// IV. Protocol Tasks & Collaborative Contributions
//    - System for users to propose, contribute to, and resolve tasks, fostering collaboration and earning rewards.
// V. Synaptic Link - Dynamic Trait Transfer
//    - A novel mechanism allowing C-Agents to strategically share or transfer attributes, promoting emergent swarm behaviors.
//
// Function Summary:
//
// I. Core Infrastructure & Protocol Management
// 1.  constructor(address _energyTokenAddress, string memory _name, string memory _symbol): Initializes the protocol, deploys the C-Agent NFT contract.
// 2.  setProtocolParameters(uint256 _mintCost, uint256 _minStakeEnergy, uint256 _decayRate, uint256 _taskProposalFee, uint256 _synapticLinkFee): Allows the owner to configure core protocol parameters.
// 3.  toggleProtocolPause(): Pauses or unpauses the protocol, useful for upgrades or emergencies.
// 4.  setOracleAddress(address _newOracle): Designates an address that can trigger environmental stimuli.
//
// II. C-Agent (Dynamic NFT) Management
// 5.  mintCAgent(): Mints a new C-Agent NFT, burning EnergyToken as cost and assigning initial attributes.
// 6.  stakeEnergyForCAgent(uint256 _tokenId, uint256 _amount): Stakes EnergyToken to a specific C-Agent, boosting its performance attributes.
// 7.  unstakeEnergyFromCAgent(uint256 _tokenId, uint256 _amount): Unstakes EnergyToken from a C-Agent, which may reduce its attributes.
// 8.  getCAgentAttributes(uint256 _tokenId): Retrieves the current dynamic attributes of a C-Agent.
// 9.  evolveCAgent(uint256 _tokenId): Triggers an individual C-Agent's attribute update based on accumulated staked energy, task contributions, and environmental stimuli.
// 10. decayCAgentAttributes(uint256 _tokenId): Applies a periodic decay to a C-Agent's attributes if not actively maintained.
//
// III. Adaptive Core & Environmental Simulation
// 11. triggerEnvironmentalStimulus(EnvironmentalType _type, uint256 _intensity): A designated oracle/role injects a simulated "challenge" or "opportunity" influencing C-Agent evolution.
// 12. updateAdaptiveAlgorithmWeights(uint256 _processingWeight, uint256 _resilienceWeight, uint256 _adaptabilityWeight, uint256 _karmaWeight): Owner/governance adjusts the weights used in the adaptive algorithm for attribute calculation and reward distribution.
// 13. calculateGlobalAdaptabilityScore(): Aggregates all C-Agent attributes to determine the overall swarm's "adaptability," influencing protocol-wide parameters.
// 14. distributeAdaptiveRewards(): Distributes a portion of protocol fees or newly minted EnergyToken based on the GlobalAdaptabilityScore and individual agent contributions.
//
// IV. Protocol Tasks & Collaborative Contributions
// 15. proposeProtocolTask(string memory _description, uint256 _requiredProcessingPower, uint256 _rewardPoolAmount): Users can propose tasks for the swarm, requiring a fee.
// 16. contributeToTask(uint256 _taskId, uint256 _tokenId): Owners stake their C-Agents to contribute to an active task, committing their agent's processing power.
// 17. resolveProtocolTask(uint256 _taskId): Owner/governance/designated role resolves a task, calculating and allocating rewards to contributing agents.
// 18. claimTaskRewards(uint256 _taskId, uint256 _tokenId): Allows C-Agent owners to claim their earned rewards from resolved tasks.
//
// V. Synaptic Link - Dynamic Trait Transfer
// 19. requestSynapticLink(uint256 _sourceTokenId, uint256 _targetTokenId, TraitType _traitToTransfer, uint256 _transferAmount): An owner requests a link between two agents (their own or others) to transfer a specific trait.
// 20. approveSynapticLink(uint256 _linkId): The owner of the target C-Agent approves a pending synaptic link request.
// 21. executeSynapticTransfer(uint256 _linkId): Finalizes the attribute transfer, modifying both source and target C-Agents' attributes and consuming fees.

// Custom C-Agent NFT contract
contract CAgentNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor(string memory name, string memory symbol, address initialOwner) ERC721(name, symbol) Ownable(initialOwner) {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://chrysalis/"; // Placeholder for base URI
    }

    function safeMint(address to) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, string(abi.encodePacked(_baseURI(), Strings.toString(newItemId))));
        return newItemId;
    }

    // Prevents direct transfer, all transfers must go through ChrysalisProtocol or via explicit approval logic
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(msg.sender == owner() || isApprovedForAll(from, msg.sender) || getApproved(tokenId) == msg.sender, "CAgentNFT: transfer caller is not owner nor approved");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(msg.sender == owner() || isApprovedForAll(from, msg.sender) || getApproved(tokenId) == msg.sender, "CAgentNFT: transfer caller is not owner nor approved");
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

contract ChrysalisProtocol is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum EnvironmentalType {
        None,
        ResourceScarcity,   // Reduces processingPower, tests resilience
        TechnologicalBoom,  // Boosts adaptabilityScore, new tasks
        SocialUpheaval      // Affects karma, resilience
    }

    enum TraitType {
        ProcessingPower,
        Resilience,
        AdaptabilityScore,
        KarmaScore
    }

    // --- Structs ---

    struct CAgentAttributes {
        uint256 lastEvolutionBlock;      // Block number when attributes were last updated
        uint256 lastDecayBlock;          // Block number when attributes were last decayed
        uint256 processingPower;         // Efficiency in tasks, base 100
        uint256 resilience;              // Resistance to decay, negative stimuli, base 100
        uint256 adaptabilityScore;       // Rate of attribute gain, response to stimuli, base 100
        uint256 karmaScore;              // Reputation from successful contributions, base 0
        uint256 stakedEnergyAmount;      // Total EnergyToken staked to this agent
        uint256 taskContributionBalance; // Accumulated contribution from active tasks
        uint256 pendingRewards;          // Rewards accumulated for this agent
    }

    struct ProtocolTask {
        uint256 taskId;
        string description;
        uint256 requiredProcessingPower; // Total required to complete task
        uint256 rewardPoolAmount;        // Total rewards for this task
        uint256 currentContributions;    // Sum of processing power contributed
        uint256 contributorsCount;       // Number of unique agents contributed
        bool isResolved;
        bool isActive;
        address proposer;
        uint256 creationBlock;
        uint256 resolutionBlock;
        mapping(uint256 => uint256) agentContributionAmount; // tokenId => contributed processing power
        mapping(uint256 => bool) hasClaimedReward;           // tokenId => claimed?
        uint256[] contributingAgents; // List of tokenIds that contributed
    }

    struct SynapticLink {
        uint256 linkId;
        uint256 sourceTokenId;
        uint256 targetTokenId;
        address sourceOwner;
        address targetOwner;
        TraitType traitToTransfer;
        uint256 transferAmount; // The absolute amount to transfer
        bool isApprovedByTarget;
        bool isExecuted;
        uint256 requestedBlock;
    }

    // --- State Variables ---

    CAgentNFT public cAgentNFT;
    IERC20 public energyToken;

    bool public paused;
    address public oracleAddress; // Can trigger environmental stimuli

    // Protocol Parameters
    uint256 public mintCost;
    uint256 public minStakeEnergy; // Minimum energy required to maintain agent
    uint256 public decayRate;      // % decay per block interval for attributes (e.g., 100 = 1%)
    uint256 public decayIntervalBlocks; // How often decay happens
    uint256 public taskProposalFee;
    uint256 public synapticLinkFee;

    // Adaptive Algorithm Weights
    uint256 public processingWeight;
    uint256 public resilienceWeight;
    uint256 public adaptabilityWeight;
    uint256 public karmaWeight;

    // Environmental Stimuli
    EnvironmentalType public currentEnvironmentalType;
    uint256 public currentEnvironmentalIntensity;
    uint256 public lastEnvironmentalUpdateBlock;

    // Counters for NFTs, Tasks, Links
    Counters.Counter private _taskIdCounter;
    Counters.Counter private _linkIdCounter;

    // Mappings for data storage
    mapping(uint256 => CAgentAttributes) public cAgentAttributes;
    mapping(uint256 => ProtocolTask) public protocolTasks;
    mapping(uint256 => SynapticLink) public synapticLinks;

    // --- Events ---

    event ProtocolPaused(bool _isPaused);
    event ProtocolParametersUpdated(uint256 _mintCost, uint256 _minStakeEnergy, uint256 _decayRate, uint256 _taskProposalFee, uint256 _synapticLinkFee);
    event OracleAddressUpdated(address _newOracle);

    event CAgentMinted(address indexed owner, uint256 indexed tokenId, uint256 initialProcessing, uint256 initialResilience, uint256 initialAdaptability);
    event EnergyStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event EnergyUnstaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event CAgentEvolved(uint256 indexed tokenId, uint256 newProcessing, uint256 newResilience, uint256 newAdaptability, uint256 newKarma);
    event CAgentDecayed(uint256 indexed tokenId, uint256 oldProcessing, uint256 newProcessing, uint256 oldResilience, uint256 newResilience);

    event EnvironmentalStimulusTriggered(EnvironmentalType _type, uint256 _intensity, uint256 blockNumber);
    event AdaptiveAlgorithmWeightsUpdated(uint256 _processingWeight, uint256 _resilienceWeight, uint256 _adaptabilityWeight, uint256 _karmaWeight);
    event GlobalAdaptabilityScoreCalculated(uint256 score);
    event AdaptiveRewardsDistributed(uint256 totalRewards, uint256 countOfAgents);

    event ProtocolTaskProposed(uint256 indexed taskId, address indexed proposer, uint256 requiredPower, uint256 rewardAmount);
    event CAgentContributedToTask(uint256 indexed taskId, uint256 indexed tokenId, uint256 amount);
    event ProtocolTaskResolved(uint256 indexed taskId, address indexed resolver, uint256 totalContributions, uint256 totalRewardDistributed);
    event TaskRewardsClaimed(uint256 indexed taskId, uint256 indexed tokenId, address indexed claimant, uint256 amount);

    event SynapticLinkRequested(uint256 indexed linkId, uint256 indexed sourceTokenId, uint256 indexed targetTokenId, TraitType _trait, uint256 _amount);
    event SynapticLinkApproved(uint256 indexed linkId, uint256 indexed targetTokenId);
    event SynapticLinkExecuted(uint256 indexed linkId, uint256 indexed sourceTokenId, uint256 indexed targetTokenId, TraitType _trait, uint256 _amount);

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Protocol: Paused");
        _;
    }

    modifier onlyOwnerOrOracle() {
        require(msg.sender == owner() || msg.sender == oracleAddress, "Protocol: Not owner or oracle");
        _;
    }

    // --- Constructor ---

    constructor(address _energyTokenAddress, string memory _name, string memory _symbol) Ownable(msg.sender) {
        require(_energyTokenAddress != address(0), "Protocol: Zero address for EnergyToken");
        energyToken = IERC20(_energyTokenAddress);
        cAgentNFT = new CAgentNFT(_name, _symbol, address(this)); // Protocol owns the NFT factory
        
        // Initial parameters
        mintCost = 100 ether; // Example: 100 EnergyToken
        minStakeEnergy = 10 ether; // Example: 10 EnergyToken
        decayRate = 1; // 1% decay
        decayIntervalBlocks = 100; // Decay every 100 blocks
        taskProposalFee = 5 ether; // Example: 5 EnergyToken
        synapticLinkFee = 2 ether; // Example: 2 EnergyToken

        // Initial adaptive algorithm weights (sum to 100 for percentage like calculations)
        processingWeight = 30;
        resilienceWeight = 20;
        adaptabilityWeight = 30;
        karmaWeight = 20;

        currentEnvironmentalType = EnvironmentalType.None;
        currentEnvironmentalIntensity = 0;
        lastEnvironmentalUpdateBlock = block.number;
        
        oracleAddress = msg.sender; // Owner is initially the oracle
    }

    // --- I. Core Infrastructure & Protocol Management ---

    function setProtocolParameters(
        uint256 _mintCost,
        uint256 _minStakeEnergy,
        uint256 _decayRate,
        uint256 _taskProposalFee,
        uint256 _synapticLinkFee
    ) public onlyOwner whenNotPaused {
        mintCost = _mintCost;
        minStakeEnergy = _minStakeEnergy;
        decayRate = _decayRate;
        taskProposalFee = _taskProposalFee;
        synapticLinkFee = _synapticLinkFee;
        emit ProtocolParametersUpdated(_mintCost, _minStakeEnergy, _decayRate, _taskProposalFee, _synapticLinkFee);
    }

    function toggleProtocolPause() public onlyOwner {
        paused = !paused;
        emit ProtocolPaused(paused);
    }

    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "Protocol: Zero address for oracle");
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    // --- II. C-Agent (Dynamic NFT) Management ---

    function mintCAgent() public whenNotPaused nonReentrant returns (uint256) {
        require(energyToken.transferFrom(msg.sender, address(this), mintCost), "CAgent: EnergyToken transfer failed for minting");
        
        // Random-ish initial attributes based on blockhash
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenIdCounter.current())));
        
        // Initial attributes: Base value + a small random offset
        uint256 initialProcessing = 100 + (seed % 20); // 100-119
        uint256 initialResilience = 100 + ((seed / 100) % 20); // 100-119
        uint256 initialAdaptability = 100 + ((seed / 10000) % 20); // 100-119

        uint256 tokenId = cAgentNFT.safeMint(msg.sender);

        CAgentAttributes storage attributes = cAgentAttributes[tokenId];
        attributes.lastEvolutionBlock = block.number;
        attributes.lastDecayBlock = block.number;
        attributes.processingPower = initialProcessing;
        attributes.resilience = initialResilience;
        attributes.adaptabilityScore = initialAdaptability;
        attributes.karmaScore = 0; // Starts with 0 karma
        attributes.stakedEnergyAmount = 0;
        attributes.taskContributionBalance = 0;
        attributes.pendingRewards = 0;

        emit CAgentMinted(msg.sender, tokenId, initialProcessing, initialResilience, initialAdaptability);
        return tokenId;
    }

    function stakeEnergyForCAgent(uint256 _tokenId, uint256 _amount) public whenNotPaused nonReentrant {
        require(cAgentNFT.ownerOf(_tokenId) == msg.sender, "CAgent: Not owner of token");
        require(_amount > 0, "CAgent: Amount must be positive");
        require(energyToken.transferFrom(msg.sender, address(this), _amount), "CAgent: EnergyToken transfer failed for staking");

        cAgentAttributes[_tokenId].stakedEnergyAmount += _amount;
        // Immediate small boost to attributes from staking
        cAgentAttributes[_tokenId].processingPower += (_amount / 10 ether); // Example: 10 energy gives 1 power
        cAgentAttributes[_tokenId].resilience += (_amount / 20 ether);
        cAgentAttributes[_tokenId].adaptabilityScore += (_amount / 15 ether);
        
        // Ensure values don't overflow uint256 if they reach extremely high levels
        // For simplicity, we assume they won't reach max uint256 with reasonable amounts
        // In a real scenario, cap values or use safe math.

        emit EnergyStaked(_tokenId, msg.sender, _amount);
    }

    function unstakeEnergyFromCAgent(uint256 _tokenId, uint256 _amount) public whenNotPaused nonReentrant {
        require(cAgentNFT.ownerOf(_tokenId) == msg.sender, "CAgent: Not owner of token");
        require(_amount > 0, "CAgent: Amount must be positive");
        require(cAgentAttributes[_tokenId].stakedEnergyAmount >= _amount, "CAgent: Insufficient staked energy");

        cAgentAttributes[_tokenId].stakedEnergyAmount -= _amount;
        require(energyToken.transfer(msg.sender, _amount), "CAgent: Failed to return EnergyToken");

        // Immediate small reduction of attributes from unstaking
        cAgentAttributes[_tokenId].processingPower = cAgentAttributes[_tokenId].processingPower > (_amount / 10 ether) ? cAgentAttributes[_tokenId].processingPower - (_amount / 10 ether) : 0;
        cAgentAttributes[_tokenId].resilience = cAgentAttributes[_tokenId].resilience > (_amount / 20 ether) ? cAgentAttributes[_tokenId].resilience - (_amount / 20 ether) : 0;
        cAgentAttributes[_tokenId].adaptabilityScore = cAgentAttributes[_tokenId].adaptabilityScore > (_amount / 15 ether) ? cAgentAttributes[_tokenId].adaptabilityScore - (_amount / 15 ether) : 0;

        emit EnergyUnstaked(_tokenId, msg.sender, _amount);
    }

    function getCAgentAttributes(uint256 _tokenId) public view returns (CAgentAttributes memory) {
        return cAgentAttributes[_tokenId];
    }

    function evolveCAgent(uint256 _tokenId) public whenNotPaused nonReentrant {
        require(cAgentNFT.ownerOf(_tokenId) == msg.sender, "CAgent: Not owner of token");
        CAgentAttributes storage attrs = cAgentAttributes[_tokenId];
        
        // Apply decay if due
        decayCAgentAttributes(_tokenId);

        // Factors influencing evolution: staked energy, task contributions, environmental stimuli, karma
        uint256 timeSinceLastEvolution = block.number - attrs.lastEvolutionBlock;
        if (timeSinceLastEvolution == 0) return; // Already evolved this block

        // Base attribute gain (e.g., small amount per block interval)
        uint256 baseGain = timeSinceLastEvolution / 10; // Example: 1 power per 10 blocks

        // Staked energy bonus
        uint256 energyBonus = attrs.stakedEnergyAmount / (1 ether * 10); // 1 bonus per 10 energy staked

        // Task contribution bonus (resets after evolution)
        uint256 taskBonus = attrs.taskContributionBalance / 100; // 1 bonus per 100 contribution
        attrs.karmaScore += attrs.taskContributionBalance / 1000; // Increase karma based on contribution

        // Environmental influence (simplified: direct impact based on type/intensity)
        uint256 envEffectProcessing = 0;
        uint256 envEffectResilience = 0;
        uint256 envEffectAdaptability = 0;

        if (currentEnvironmentalType == EnvironmentalType.ResourceScarcity) {
            envEffectProcessing = (currentEnvironmentalIntensity * 1 ether) / 100; // Penalty
            envEffectResilience = (currentEnvironmentalIntensity * 1 ether) / 200; // Boost resilience slightly
        } else if (currentEnvironmentalType == EnvironmentalType.TechnologicalBoom) {
            envEffectAdaptability = (currentEnvironmentalIntensity * 1 ether) / 100; // Boost adaptability
        } else if (currentEnvironmentalType == EnvironmentalType.SocialUpheaval) {
            envEffectResilience = (currentEnvironmentalIntensity * 1 ether) / 150; // Boost resilience
            attrs.karmaScore = attrs.karmaScore > (currentEnvironmentalIntensity * 1 ether) / 1000 ? attrs.karmaScore - (currentEnvironmentalIntensity * 1 ether) / 1000 : 0; // Penalty to karma
        }

        uint256 oldProcessing = attrs.processingPower;
        uint256 oldResilience = attrs.resilience;
        uint256 oldAdaptability = attrs.adaptabilityScore;
        uint256 oldKarma = attrs.karmaScore;

        // Apply gains/penalties
        attrs.processingPower = attrs.processingPower + baseGain + energyBonus + taskBonus - envEffectProcessing;
        attrs.resilience = attrs.resilience + baseGain + energyBonus + taskBonus + envEffectResilience;
        attrs.adaptabilityScore = attrs.adaptabilityScore + baseGain + energyBonus + taskBonus + envEffectAdaptability;
        
        attrs.taskContributionBalance = 0; // Reset contribution balance after evolution

        attrs.lastEvolutionBlock = block.number;

        emit CAgentEvolved(_tokenId, attrs.processingPower, attrs.resilience, attrs.adaptabilityScore, attrs.karmaScore);
    }

    function decayCAgentAttributes(uint256 _tokenId) public whenNotPaused {
        require(cAgentNFT.ownerOf(_tokenId) == msg.sender || msg.sender == address(this), "CAgent: Not owner or protocol");
        CAgentAttributes storage attrs = cAgentAttributes[_tokenId];

        uint256 blocksSinceLastDecay = block.number - attrs.lastDecayBlock;
        if (blocksSinceLastDecay < decayIntervalBlocks) {
            return; // Not enough time has passed for decay
        }

        uint256 decayPeriods = blocksSinceLastDecay / decayIntervalBlocks;
        
        // Decay attributes if staked energy is below min threshold, or generally over time
        // Calculate decay based on minimum staked energy threshold
        uint256 actualDecayRate = decayRate;
        if (attrs.stakedEnergyAmount < minStakeEnergy) {
            actualDecayRate += 5; // Higher decay if not enough energy (e.g., +5% per period)
        }

        uint256 oldProcessing = attrs.processingPower;
        uint256 oldResilience = attrs.resilience;

        attrs.processingPower = attrs.processingPower * (100 - (actualDecayRate * decayPeriods)) / 100;
        attrs.resilience = attrs.resilience * (100 - (actualDecayRate * decayPeriods)) / 100;
        attrs.adaptabilityScore = attrs.adaptabilityScore * (100 - (actualDecayRate * decayPeriods)) / 100;

        // Ensure attributes don't go below a certain minimum (e.g., 10 for core stats, 0 for karma)
        if (attrs.processingPower < 10) attrs.processingPower = 10;
        if (attrs.resilience < 10) attrs.resilience = 10;
        if (attrs.adaptabilityScore < 10) attrs.adaptabilityScore = 10;

        attrs.lastDecayBlock = block.number;
        emit CAgentDecayed(_tokenId, oldProcessing, attrs.processingPower, oldResilience, attrs.resilience);
    }


    // --- III. Adaptive Core & Environmental Simulation ---

    function triggerEnvironmentalStimulus(EnvironmentalType _type, uint256 _intensity) public onlyOwnerOrOracle whenNotPaused {
        require(_type != EnvironmentalType.None, "Environmental: Cannot set None type");
        require(_intensity > 0, "Environmental: Intensity must be positive");
        currentEnvironmentalType = _type;
        currentEnvironmentalIntensity = _intensity;
        lastEnvironmentalUpdateBlock = block.number;
        emit EnvironmentalStimulusTriggered(_type, _intensity, block.number);
    }

    function updateAdaptiveAlgorithmWeights(
        uint256 _processingWeight,
        uint256 _resilienceWeight,
        uint256 _adaptabilityWeight,
        uint256 _karmaWeight
    ) public onlyOwner whenNotPaused {
        require(_processingWeight + _resilienceWeight + _adaptabilityWeight + _karmaWeight == 100, "Weights must sum to 100");
        processingWeight = _processingWeight;
        resilienceWeight = _resilienceWeight;
        adaptabilityWeight = _adaptabilityWeight;
        karmaWeight = _karmaWeight;
        emit AdaptiveAlgorithmWeightsUpdated(processingWeight, resilienceWeight, adaptabilityWeight, karmaWeight);
    }

    function calculateGlobalAdaptabilityScore() public view returns (uint256) {
        uint256 totalScore = 0;
        uint256 totalAgents = cAgentNFT._tokenIdCounter.current(); // Assuming contiguous token IDs from 1

        for (uint256 i = 1; i <= totalAgents; i++) {
            CAgentAttributes storage attrs = cAgentAttributes[i];
            uint256 agentScore = (attrs.processingPower * processingWeight +
                                 attrs.resilience * resilienceWeight +
                                 attrs.adaptabilityScore * adaptabilityWeight +
                                 attrs.karmaScore * karmaWeight) / 100; // Weighted average
            totalScore += agentScore;
        }
        // Emit event for observation without state change
        // Cannot emit directly in a view function, consider a state-changing wrapper if needed for event logs.
        // For now, this is a pure calculation.
        return totalScore / totalAgents; // Average adaptability score
    }

    function distributeAdaptiveRewards() public onlyOwner whenNotPaused nonReentrant {
        uint256 globalScore = calculateGlobalAdaptabilityScore();
        uint256 protocolBalance = energyToken.balanceOf(address(this));
        
        // Example: Allocate 10% of protocol balance as adaptive rewards, capped at 1000 EnergyToken
        uint256 rewardsPool = (protocolBalance * 10 / 100);
        if (rewardsPool > 1000 ether) {
            rewardsPool = 1000 ether; // Cap the rewards pool
        }
        
        if (rewardsPool == 0) return;

        uint256 totalAgents = cAgentNFT._tokenIdCounter.current();
        if (totalAgents == 0) return;

        uint256 rewardPerAgent = rewardsPool / totalAgents; // Simple distribution for now

        uint256 distributedAmount = 0;
        for (uint256 i = 1; i <= totalAgents; i++) {
            address owner = cAgentNFT.ownerOf(i);
            if (owner != address(0)) {
                cAgentAttributes[i].pendingRewards += rewardPerAgent;
                distributedAmount += rewardPerAgent;
            }
        }
        
        // This implicitly 'mints' rewards by assigning from contract balance.
        // If contract balance is insufficient, it will fail or need a different mechanism.
        // For simplicity, we assume the contract holds enough token (e.g., from fees).
        // If new tokens are minted, IERC20 should have a mint function.

        emit AdaptiveRewardsDistributed(distributedAmount, totalAgents);
    }

    // --- IV. Protocol Tasks & Collaborative Contributions ---

    function proposeProtocolTask(
        string memory _description,
        uint256 _requiredProcessingPower,
        uint256 _rewardPoolAmount
    ) public whenNotPaused nonReentrant returns (uint256) {
        require(energyToken.transferFrom(msg.sender, address(this), taskProposalFee), "Task: Proposal fee transfer failed");
        require(_rewardPoolAmount > 0, "Task: Reward pool must be positive");
        require(energyToken.transferFrom(msg.sender, address(this), _rewardPoolAmount), "Task: Reward pool transfer failed");

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        ProtocolTask storage newTask = protocolTasks[newTaskId];
        newTask.taskId = newTaskId;
        newTask.description = _description;
        newTask.requiredProcessingPower = _requiredProcessingPower;
        newTask.rewardPoolAmount = _rewardPoolAmount;
        newTask.currentContributions = 0;
        newTask.contributorsCount = 0;
        newTask.isResolved = false;
        newTask.isActive = true;
        newTask.proposer = msg.sender;
        newTask.creationBlock = block.number;

        emit ProtocolTaskProposed(newTaskId, msg.sender, _requiredProcessingPower, _rewardPoolAmount);
        return newTaskId;
    }

    function contributeToTask(uint256 _taskId, uint256 _tokenId) public whenNotPaused nonReentrant {
        require(protocolTasks[_taskId].isActive, "Task: Task is not active");
        require(cAgentNFT.ownerOf(_tokenId) == msg.sender, "Task: Not owner of C-Agent");
        require(cAgentAttributes[_tokenId].processingPower > 0, "Task: C-Agent has no processing power");

        ProtocolTask storage task = protocolTasks[_taskId];
        CAgentAttributes storage agentAttrs = cAgentAttributes[_tokenId];

        uint256 effectiveContribution = agentAttrs.processingPower + (agentAttrs.karmaScore / 10); // Karma boosts contribution

        task.currentContributions += effectiveContribution;
        task.agentContributionAmount[_tokenId] += effectiveContribution;
        agentAttrs.taskContributionBalance += effectiveContribution; // Accumulate for agent's own evolution

        bool alreadyContributed = false;
        for (uint256 i = 0; i < task.contributingAgents.length; i++) {
            if (task.contributingAgents[i] == _tokenId) {
                alreadyContributed = true;
                break;
            }
        }
        if (!alreadyContributed) {
            task.contributingAgents.push(_tokenId);
            task.contributorsCount++;
        }

        emit CAgentContributedToTask(_taskId, _tokenId, effectiveContribution);

        // Optional: Auto-resolve if sufficient contributions are met
        if (task.currentContributions >= task.requiredProcessingPower) {
            resolveProtocolTask(_taskId);
        }
    }

    function resolveProtocolTask(uint256 _taskId) public onlyOwnerOrOracle whenNotPaused nonReentrant {
        ProtocolTask storage task = protocolTasks[_taskId];
        require(task.isActive, "Task: Task not active");
        require(task.currentContributions >= task.requiredProcessingPower, "Task: Not enough contributions to resolve");

        task.isResolved = true;
        task.isActive = false;
        task.resolutionBlock = block.number;

        uint256 totalRewardDistributed = 0;
        
        // Distribute rewards proportionally to contributors
        for (uint256 i = 0; i < task.contributingAgents.length; i++) {
            uint256 agentTokenId = task.contributingAgents[i];
            uint256 agentContribution = task.agentContributionAmount[agentTokenId];
            
            uint256 rewardShare = (agentContribution * task.rewardPoolAmount) / task.currentContributions;
            
            cAgentAttributes[agentTokenId].pendingRewards += rewardShare;
            totalRewardDistributed += rewardShare;
            
            // Boost karma for successful contribution
            cAgentAttributes[agentTokenId].karmaScore += (rewardShare / 1 ether); // Example: 1 karma per 1 EnergyToken reward
        }
        
        // Refund any excess reward pool to proposer if currentContributions exceeded required (edge case)
        if (totalRewardDistributed < task.rewardPoolAmount) {
            uint256 refundAmount = task.rewardPoolAmount - totalRewardDistributed;
            require(energyToken.transfer(task.proposer, refundAmount), "Task: Failed to refund proposer excess rewards");
        }

        emit ProtocolTaskResolved(_taskId, msg.sender, task.currentContributions, totalRewardDistributed);
    }

    function claimTaskRewards(uint256 _taskId, uint256 _tokenId) public whenNotPaused nonReentrant {
        ProtocolTask storage task = protocolTasks[_taskId];
        require(task.isResolved, "Task: Task not resolved yet");
        require(cAgentNFT.ownerOf(_tokenId) == msg.sender, "Task: Not owner of C-Agent");
        require(task.agentContributionAmount[_tokenId] > 0, "Task: C-Agent did not contribute to this task");
        require(!task.hasClaimedReward[_tokenId], "Task: Rewards already claimed for this C-Agent");
        
        uint256 rewardShare = (task.agentContributionAmount[_tokenId] * task.rewardPoolAmount) / task.currentContributions;
        require(rewardShare > 0, "Task: No rewards to claim");

        task.hasClaimedReward[_tokenId] = true;
        
        // Transfer from pendingRewards balance, if implemented
        // For simplicity, directly transfer from contract balance if rewards were allocated this way
        // Or, update agent's pendingRewards from global adaptive rewards
        require(cAgentAttributes[_tokenId].pendingRewards >= rewardShare, "Insufficient pending rewards");
        cAgentAttributes[_tokenId].pendingRewards -= rewardShare;
        require(energyToken.transfer(msg.sender, rewardShare), "Task: Failed to transfer reward");

        emit TaskRewardsClaimed(_taskId, _tokenId, msg.sender, rewardShare);
    }
    
    // Function to claim general pending rewards (from distributeAdaptiveRewards or other sources)
    function claimPendingRewards(uint256 _tokenId) public whenNotPaused nonReentrant {
        require(cAgentNFT.ownerOf(_tokenId) == msg.sender, "Rewards: Not owner of C-Agent");
        uint256 amount = cAgentAttributes[_tokenId].pendingRewards;
        require(amount > 0, "Rewards: No pending rewards");
        
        cAgentAttributes[_tokenId].pendingRewards = 0;
        require(energyToken.transfer(msg.sender, amount), "Rewards: Failed to transfer pending rewards");
        
        emit TaskRewardsClaimed(0, _tokenId, msg.sender, amount); // TaskId 0 for general rewards
    }

    // --- V. Synaptic Link - Dynamic Trait Transfer ---

    function requestSynapticLink(
        uint256 _sourceTokenId,
        uint256 _targetTokenId,
        TraitType _traitToTransfer,
        uint256 _transferAmount
    ) public whenNotPaused nonReentrant returns (uint256) {
        require(cAgentNFT.ownerOf(_sourceTokenId) == msg.sender, "SynapticLink: Not owner of source token");
        require(_sourceTokenId != _targetTokenId, "SynapticLink: Cannot link agent to itself");
        require(_transferAmount > 0, "SynapticLink: Transfer amount must be positive");
        
        // Ensure source has enough of the trait to transfer
        if (_traitToTransfer == TraitType.ProcessingPower) {
            require(cAgentAttributes[_sourceTokenId].processingPower >= _transferAmount, "SynapticLink: Source has insufficient ProcessingPower");
        } else if (_traitToTransfer == TraitType.Resilience) {
            require(cAgentAttributes[_sourceTokenId].resilience >= _transferAmount, "SynapticLink: Source has insufficient Resilience");
        } else if (_traitToTransfer == TraitType.AdaptabilityScore) {
            require(cAgentAttributes[_sourceTokenId].adaptabilityScore >= _transferAmount, "SynapticLink: Source has insufficient AdaptabilityScore");
        } else if (_traitToTransfer == TraitType.KarmaScore) {
            require(cAgentAttributes[_sourceTokenId].karmaScore >= _transferAmount, "SynapticLink: Source has insufficient KarmaScore");
        }

        require(energyToken.transferFrom(msg.sender, address(this), synapticLinkFee), "SynapticLink: Fee transfer failed");

        _linkIdCounter.increment();
        uint256 newLinkId = _linkIdCounter.current();

        SynapticLink storage newLink = synapticLinks[newLinkId];
        newLink.linkId = newLinkId;
        newLink.sourceTokenId = _sourceTokenId;
        newLink.targetTokenId = _targetTokenId;
        newLink.sourceOwner = msg.sender;
        newLink.targetOwner = cAgentNFT.ownerOf(_targetTokenId); // Owner at time of request
        newLink.traitToTransfer = _traitToTransfer;
        newLink.transferAmount = _transferAmount;
        newLink.isApprovedByTarget = false;
        newLink.isExecuted = false;
        newLink.requestedBlock = block.number;

        emit SynapticLinkRequested(newLinkId, _sourceTokenId, _targetTokenId, _traitToTransfer, _transferAmount);
        return newLinkId;
    }

    function approveSynapticLink(uint256 _linkId) public whenNotPaused {
        SynapticLink storage link = synapticLinks[_linkId];
        require(link.targetTokenId != 0, "SynapticLink: Link does not exist");
        require(link.targetOwner == msg.sender, "SynapticLink: Not owner of target token");
        require(!link.isApprovedByTarget, "SynapticLink: Link already approved");
        require(!link.isExecuted, "SynapticLink: Link already executed");
        
        // Re-check target owner, in case NFT was transferred since request
        require(cAgentNFT.ownerOf(link.targetTokenId) == msg.sender, "SynapticLink: Target token owner changed");

        link.isApprovedByTarget = true;
        emit SynapticLinkApproved(_linkId, link.targetTokenId);
    }

    function executeSynapticTransfer(uint256 _linkId) public whenNotPaused nonReentrant {
        SynapticLink storage link = synapticLinks[_linkId];
        require(link.targetTokenId != 0, "SynapticLink: Link does not exist");
        require(link.sourceOwner == msg.sender || link.targetOwner == msg.sender, "SynapticLink: Not party to link");
        require(link.isApprovedByTarget, "SynapticLink: Link not approved by target");
        require(!link.isExecuted, "SynapticLink: Link already executed");
        
        // Final ownership checks
        require(cAgentNFT.ownerOf(link.sourceTokenId) == link.sourceOwner, "SynapticLink: Source token owner changed");
        require(cAgentNFT.ownerOf(link.targetTokenId) == link.targetOwner, "SynapticLink: Target token owner changed");

        CAgentAttributes storage sourceAttrs = cAgentAttributes[link.sourceTokenId];
        CAgentAttributes storage targetAttrs = cAgentAttributes[link.targetTokenId];

        // Perform the trait transfer
        if (link.traitToTransfer == TraitType.ProcessingPower) {
            require(sourceAttrs.processingPower >= link.transferAmount, "SynapticLink: Source insufficient ProcessingPower");
            sourceAttrs.processingPower -= link.transferAmount;
            targetAttrs.processingPower += link.transferAmount;
        } else if (link.traitToTransfer == TraitType.Resilience) {
            require(sourceAttrs.resilience >= link.transferAmount, "SynapticLink: Source insufficient Resilience");
            sourceAttrs.resilience -= link.transferAmount;
            targetAttrs.resilience += link.transferAmount;
        } else if (link.traitToTransfer == TraitType.AdaptabilityScore) {
            require(sourceAttrs.adaptabilityScore >= link.transferAmount, "SynapticLink: Source insufficient AdaptabilityScore");
            sourceAttrs.adaptabilityScore -= link.transferAmount;
            targetAttrs.adaptabilityScore += link.transferAmount;
        } else if (link.traitToTransfer == TraitType.KarmaScore) {
            require(sourceAttrs.karmaScore >= link.transferAmount, "SynapticLink: Source insufficient KarmaScore");
            sourceAttrs.karmaScore -= link.transferAmount;
            targetAttrs.karmaScore += link.transferAmount;
        }

        link.isExecuted = true;
        emit SynapticLinkExecuted(link.linkId, link.sourceTokenId, link.targetTokenId, link.traitToTransfer, link.transferAmount);
    }

    // --- Utility Functions (not part of the 20+ count but good for a full contract) ---

    function getProtocolBalance() public view returns (uint256) {
        return energyToken.balanceOf(address(this));
    }

    function getTaskDetails(uint256 _taskId) public view returns (ProtocolTask memory) {
        return protocolTasks[_taskId];
    }
}
```