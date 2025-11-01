This smart contract, **"Aethelgard - The Evolving Sanctuary"**, envisions a decentralized ecosystem where participants (Stewards) manage and evolve unique, sentient Non-Fungible Tokens (NFTs) called "Aethels". These Aethels collectively influence and protect a shared on-chain "Sanctuary" state, whose parameters (like resilience and threat level) are dynamic and react to actions within the system. Governance is reputation-based, and a resource management system facilitates Aethel evolution and upgrades.

The core innovation lies in the deep interconnectedness of its systems:
*   **Dynamic NFTs (Aethels):** Aethels gain experience, level up, and their traits (Power, Resilience, Wisdom) can be upgraded or even mutated using on-chain resources, directly impacting their utility and the Sanctuary's state.
*   **Reputation-Based Governance with NFT Synergy:** Stewards' voting power is a combination of their accumulated reputation and the collective strength of their bonded Aethels. This incentivizes active participation and Aethel development.
*   **Adaptive Sanctuary State:** A central `SanctuaryResilienceIndex` and `currentThreatLevel` dynamically adjust based on internal actions (Aethel power, Steward contributions) and conceptual external events (via an oracle). These global parameters, in turn, influence resource generation, upgrade costs, and governance thresholds, creating a living, reactive environment.
*   **Integrated Resource Economy:** Custom ERC20 tokens (`AetherDust`, `CoreFragments`) are generated based on the Sanctuary's health and distributed to active Stewards, serving as fuel for Aethel upgrades and interaction.

---

## **Aethelgard - The Evolving Sanctuary: Outline and Function Summary**

**I. Core Infrastructure & Setup**
1.  `constructor()`: Initializes the contract, sets up initial admin and deploys/assigns ownership of resource tokens.
2.  `setOracleAddress(address _oracle)`: (Admin) Sets the address of the external Threat Oracle for system updates.
3.  `pauseContract()`: (Admin) Pauses critical contract functionality during emergencies.
4.  `unpauseContract()`: (Admin) Unpauses contract functionality.
5.  `emergencyWithdrawFunds(address _tokenAddress, uint256 _amount)`: (Admin) Allows emergency withdrawal of specified ERC20 tokens or ETH from the contract.

**II. Aethel (NFT) Management & Interaction (ERC721-Like)**
6.  `mintAethel(address _to, string memory _element, string memory _uri)`: (Admin/System) Mints a new Aethel NFT to `_to` with initial stats, an elemental affinity, and metadata URI. Requires an ETH fee.
7.  `getAethelDetails(uint256 _aethelId)`: Retrieves comprehensive details (stats, level, owner, bond status) of a specific Aethel.
8.  `bondAethel(uint256 _aethelId)`: A Steward bonds their Aethel to their profile, activating governance bonuses and other potential benefits.
9.  `unbondAethel(uint256 _aethelId)`: A Steward unbonds their Aethel, removing associated bonuses.
10. `getBondedAethels(address _steward)`: Returns an array of Aethel IDs currently bonded by a given Steward.

**III. Steward (User) & Reputation Management**
11. `getStewardReputation(address _steward)`: Retrieves a Steward's current reputation score.
12. `_updateReputation(address _steward, int256 _change)`: (Internal/System) Adjusts a Steward's reputation score. Used by other functions (e.g., bonding, successful proposals).
13. `claimReputationReward()`: Allows Stewards to claim reputation for specific achievements (e.g., Aethel leveling, proposal success). *Placeholder, logic to be expanded.*

**IV. Resource Management (ERC20-Like)**
14. `distributeSanctuaryResources()`: (Admin/System) Distributes newly generated `AetherDust` and `CoreFragments` to Stewards based on the Sanctuary's state (Resilience, Threat Level).
15. `getAetherDustContract()`: Returns the address of the `AetherDust` ERC20 token contract.
16. `getCoreFragmentsContract()`: Returns the address of the `CoreFragments` ERC20 token contract.

**V. Aethel Evolution & Upgrades**
17. `gainAethelExperience(uint256 _aethelId, uint256 _xpAmount)`: (Admin/System) Grants experience points to an Aethel, potentially causing it to level up and gain base stats.
18. `upgradeAethelTraits(uint256 _aethelId, uint8 _traitIndex)`: Stewards use `AetherDust` and `CoreFragments` to selectively enhance an Aethel's Power, Resilience, or Wisdom.
19. `mutateAethelElement(uint256 _aethelId, string memory _newElement)`: (Advanced) Stewards can attempt to change an Aethel's elemental affinity by consuming rare resources and experience points.

**VI. Sanctuary State & Governance**
20. `getSanctuaryStatus()`: Returns the current `SanctuaryResilienceIndex`, `currentThreatLevel`, and `resourceFlowRate`.
21. `proposeSanctuaryAction(string memory _description, bytes memory _calldata, address _target, uint256 _value)`: Stewards propose actions (e.g., changing Sanctuary parameters, calling external contracts) requiring a minimum reputation and resource fee.
22. `voteOnProposal(uint256 _proposalId, bool _support)`: Stewards vote on an active proposal, with their voting power determined by reputation and bonded Aethels.
23. `executeProposal(uint256 _proposalId)`: (System) Executes a successfully approved proposal after the voting period, if it meets quorum and approval thresholds.
24. `updateThreatLevel(uint256 _newThreatLevel)`: (Oracle) Updates the global `currentThreatLevel`, influencing resource generation and governance thresholds.
25. `adjustSanctuaryResilience(int256 _change)`: (Admin/System) Adjusts the `SanctuaryResilienceIndex` based on collective Aethel power, external events, or maintenance.
26. `calculateVotePower(address _steward)`: Calculates the total effective voting power of a Steward, combining their reputation and the stats of their bonded Aethels.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Custom ERC20 for AetherDust resource
contract AetherDust is ERC20, Ownable {
    constructor() ERC20("AetherDust", "ADUST") Ownable(msg.sender) {}

    /// @notice Mints new AetherDust tokens to a specified address.
    /// @dev Only the owner (Aethelgard contract) can call this.
    /// @param to The recipient address.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

// Custom ERC20 for CoreFragments resource
contract CoreFragments is ERC20, Ownable {
    constructor() ERC20("CoreFragments", "CFRAG") ERC20Permit("CoreFragments", "CFRAG", msg.sender) Ownable(msg.sender) {} // ERC20Permit just for demonstrating a different base, not actively used here.

    /// @notice Mints new CoreFragments tokens to a specified address.
    /// @dev Only the owner (Aethelgard contract) can call this.
    /// @param to The recipient address.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}


// Main contract: Aethelgard - The Evolving Sanctuary
contract Aethelgard is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Aethel (NFT) related
    struct Aethel {
        uint256 id;
        uint256 experience;
        uint256 level;
        string element; // e.g., "Fire", "Water", "Earth", "Air", "Spirit"
        uint256 power;
        uint256 resilience;
        uint256 wisdom;
        bool isBonded; // True if bonded to a steward for governance/benefits
    }
    mapping(uint256 => Aethel) public aethels;
    Counters.Counter private _aethelIds;

    // Steward (User) related
    mapping(address => uint256) public stewardReputation;
    mapping(address => uint256[]) public bondedAethels; // Aethel IDs bonded by a steward

    // Sanctuary State related
    uint256 public sanctuaryResilienceIndex; // Overall health/stability (0-2000)
    uint256 public currentThreatLevel; // External/internal threats (1-10), influences resource/costs
    uint256 public resourceFlowRate; // Base rate of AetherDust generation

    // Governance related
    struct Proposal {
        uint256 id;
        string description;
        bytes calldataPayload; // Encoded function call for execution
        address targetContract; // Contract to call if proposal passes
        uint256 value; // Ether to send with call
        address proposer; // Address of the Steward who created the proposal
        uint256 voteThreshold; // Dynamic threshold based on ThreatLevel, etc.
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool executed;
        bool cancelled;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days; // Example duration
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 100; // Minimum reputation to propose

    // Resource Tokens
    AetherDust public immutable aethelDust;
    CoreFragments public immutable coreFragments;

    // Oracle Address (for external updates like ThreatLevel)
    address public threatOracle;

    // Constants for Aethel stats and costs
    uint256 public constant XP_PER_LEVEL = 1000;
    uint256 public constant BASE_AETHEL_MINT_ETH_COST = 0.01 ether; // Example ETH cost to mint
    uint256 public constant UPGRADE_COST_ADUST = 100;
    uint256 public constant UPGRADE_COST_CFRAG = 1;
    uint256 public constant MUTATION_COST_ADUST = 500;
    uint256 public constant MUTATION_COST_CFRAG = 5;
    uint256 public constant MUTATION_XP_COST = 500;
    uint256 public constant PROPOSAL_ADUST_FEE = 100;

    // Events
    event AethelMinted(uint256 indexed aethelId, address indexed owner, string element, uint256 initialPower);
    event AethelBonded(address indexed steward, uint256 indexed aethelId);
    event AethelUnbonded(address indexed steward, uint256 indexed aethelId);
    event ReputationUpdated(address indexed steward, uint256 newReputation);
    event AethelExperienceGained(uint256 indexed aethelId, uint256 newExperience, uint256 newLevel);
    event AethelTraitsUpgraded(uint256 indexed aethelId, uint8 traitIndex, uint256 newValue);
    event AethelElementMutated(uint256 indexed aethelId, string oldElement, string newElement);
    event SanctuaryThreatLevelUpdated(uint256 newThreatLevel);
    event SanctuaryResilienceAdjusted(int256 change, uint256 newResilienceIndex);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ResourcesDistributed(uint256 adustAmount, uint256 cfragAmount);
    event EmergencyFundsWithdrawn(address indexed recipient, address indexed tokenAddress, uint256 amount);

    // Modifiers
    modifier onlyOracle() {
        require(msg.sender == threatOracle, "Aethelgard: Only threat oracle can call");
        _;
    }

    constructor() ERC721("Aethel", "AETHL") Ownable(msg.sender) {
        // Initialize Sanctuary state
        sanctuaryResilienceIndex = 1000; // Starting health, max 2000
        currentThreatLevel = 1; // Starting low threat, max 10
        resourceFlowRate = 100; // Base resource flow rate

        // Deploy resource tokens
        aethelDust = new AetherDust();
        coreFragments = new CoreFragments();

        // Transfer ownership of resource tokens to Aethelgard contract for managing minting
        // This allows Aethelgard to mint resources without needing owner intervention for each mint.
        aethelDust.transferOwnership(address(this));
        coreFragments.transferOwnership(address(this));
    }

    // --- I. Core Infrastructure & Setup ---

    /// @notice Sets the address of the external Threat Oracle.
    /// @dev Only callable by the contract owner.
    /// @param _oracle The address of the new oracle contract.
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Aethelgard: Invalid oracle address");
        threatOracle = _oracle;
    }

    /// @notice Pauses critical contract functionality.
    /// @dev Can be called by the owner. Useful during upgrades or emergencies.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses critical contract functionality.
    /// @dev Can be called by the owner.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw specific ERC20 tokens or ETH from the contract in emergencies.
    /// @dev Can be called by the owner. Funds sent to the owner address.
    /// @param _tokenAddress The address of the ERC20 token to withdraw. Use address(0) for ETH.
    /// @param _amount The amount of tokens/ETH to withdraw.
    function emergencyWithdrawFunds(address _tokenAddress, uint256 _amount) external onlyOwner {
        if (_tokenAddress == address(0)) {
            // Withdraw ETH
            (bool success, ) = msg.sender.call{value: _amount}("");
            require(success, "Aethelgard: ETH withdrawal failed");
        } else {
            // Withdraw ERC20 token
            IERC20 token = IERC20(_tokenAddress);
            require(token.transfer(msg.sender, _amount), "Aethelgard: ERC20 withdrawal failed");
        }
        emit EmergencyFundsWithdrawn(msg.sender, _tokenAddress, _amount);
    }

    // --- II. Aethel (NFT) Management & Interaction ---

    /// @notice Mints a new Aethel NFT and assigns it to an owner.
    /// @dev Callable only by the contract owner. Requires an initial ETH cost.
    /// @param _to The address of the new Aethel owner.
    /// @param _element The elemental affinity of the Aethel (e.g., "Fire", "Water").
    /// @param _uri The URI for the Aethel's metadata.
    /// @return The ID of the newly minted Aethel.
    function mintAethel(address _to, string memory _element, string memory _uri) external payable onlyOwner whenNotPaused returns (uint256) {
        require(msg.value >= BASE_AETHEL_MINT_ETH_COST, "Aethelgard: Insufficient ETH to mint Aethel");

        _aethelIds.increment();
        uint256 newId = _aethelIds.current();

        Aethel storage newAethel = aethels[newId];
        newAethel.id = newId;
        newAethel.experience = 0;
        newAethel.level = 1;
        newAethel.element = _element;
        newAethel.power = 10; // Base stats
        newAethel.resilience = 10;
        newAethel.wisdom = 10;
        newAethel.isBonded = false;

        _safeMint(_to, newId);
        _setTokenURI(newId, _uri);

        emit AethelMinted(newId, _to, _element, newAethel.power);
        return newId;
    }

    /// @notice Retrieves comprehensive details of an Aethel.
    /// @param _aethelId The ID of the Aethel.
    /// @return A tuple containing all Aethel properties.
    function getAethelDetails(uint256 _aethelId) public view returns (
        uint256 id,
        uint256 experience,
        uint256 level,
        string memory element,
        uint256 power,
        uint256 resilience,
        uint256 wisdom,
        address currentOwner,
        bool isBonded
    ) {
        Aethel storage aethel = aethels[_aethelId];
        require(aethel.id != 0, "Aethelgard: Aethel does not exist"); // Check if Aethel exists

        return (
            aethel.id,
            aethel.experience,
            aethel.level,
            aethel.element,
            aethel.power,
            aethel.resilience,
            aethel.wisdom,
            ownerOf(_aethelId), // Get current owner from ERC721
            aethel.isBonded
        );
    }

    /// @notice Allows a Steward to bond their Aethel to their profile.
    /// @dev Bonding provides governance bonuses and potentially other benefits.
    /// @param _aethelId The ID of the Aethel to bond.
    function bondAethel(uint256 _aethelId) external whenNotPaused {
        require(ownerOf(_aethelId) == msg.sender, "Aethelgard: Not owner of Aethel");
        require(!aethels[_aethelId].isBonded, "Aethelgard: Aethel is already bonded");

        aethels[_aethelId].isBonded = true;
        bondedAethels[msg.sender].push(_aethelId);

        // Provide a reputation bonus for bonding
        _updateReputation(msg.sender, int256(aethels[_aethelId].level * 10)); // Example bonus
        emit AethelBonded(msg.sender, _aethelId);
    }

    /// @notice Allows a Steward to unbond their Aethel.
    /// @dev Unbonding removes governance bonuses and other associated benefits.
    /// @param _aethelId The ID of the Aethel to unbond.
    function unbondAethel(uint256 _aethelId) external whenNotPaused {
        require(ownerOf(_aethelId) == msg.sender, "Aethelgard: Not owner of Aethel");
        require(aethels[_aethelId].isBonded, "Aethelgard: Aethel is not bonded");

        aethels[_aethelId].isBonded = false;
        // Remove from bondedAethels array. This is an O(n) operation.
        uint256[] storage stewardBonds = bondedAethels[msg.sender];
        for (uint256 i = 0; i < stewardBonds.length; i++) {
            if (stewardBonds[i] == _aethelId) {
                stewardBonds[i] = stewardBonds[stewardBonds.length - 1]; // Replace with last element
                stewardBonds.pop(); // Remove last element
                break;
            }
        }
        // Apply a reputation penalty for unbonding
        _updateReputation(msg.sender, int256(-(aethels[_aethelId].level * 5))); // Example penalty
        emit AethelUnbonded(msg.sender, _aethelId);
    }

    /// @notice Retrieves all Aethels currently bonded by a specific Steward.
    /// @param _steward The address of the Steward.
    /// @return An array of Aethel IDs.
    function getBondedAethels(address _steward) public view returns (uint256[] memory) {
        return bondedAethels[_steward];
    }

    // --- III. Steward (User) & Reputation Management ---

    /// @notice Retrieves a Steward's current reputation score.
    /// @param _steward The address of the Steward.
    /// @return The reputation score.
    function getStewardReputation(address _steward) public view returns (uint256) {
        return stewardReputation[_steward];
    }

    /// @notice Internal function to update a Steward's reputation score.
    /// @dev This function should only be called by the system (e.g., successful proposal execution, Aethel bonding/unbonding).
    /// @param _steward The address of the Steward.
    /// @param _change The amount to change the reputation by (can be negative).
    function _updateReputation(address _steward, int256 _change) internal {
        uint256 currentRep = stewardReputation[_steward];
        if (_change > 0) {
            stewardReputation[_steward] = currentRep + uint256(_change);
        } else {
            uint256 absChange = uint256(-_change);
            if (currentRep < absChange) {
                stewardReputation[_steward] = 0; // Reputation cannot go below zero
            } else {
                stewardReputation[_steward] = currentRep - absChange;
            }
        }
        emit ReputationUpdated(_steward, stewardReputation[_steward]);
    }

    /// @notice Allows Stewards to claim reputation for certain achievements.
    /// @dev This is a placeholder; actual logic would be tied to specific on-chain events or external task completion.
    function claimReputationReward() external whenNotPaused {
        revert("Aethelgard: Reputation claiming mechanism not fully implemented yet. This is a conceptual function.");
        // Example: If an Aethel reaches level 10, its owner might claim a one-time reputation reward.
        // Or for completing specific in-game "quests".
        // _updateReputation(msg.sender, 50); // Example, actual logic would be more complex
    }

    // --- IV. Resource Management ---

    /// @notice Distributes newly generated AetherDust and CoreFragments.
    /// @dev Callable by the contract owner, representing a system-level resource generation event.
    /// Resource generation rate depends on Sanctuary state (Resilience and Threat Level).
    function distributeSanctuaryResources() external onlyOwner whenNotPaused {
        // Calculate base resource generation based on resourceFlowRate
        uint256 baseAetherDust = resourceFlowRate * 10; // More common
        uint256 baseCoreFragments = resourceFlowRate / 100; // Scarcer

        // Adjust generation based on Sanctuary Resilience (higher resilience -> more resources)
        // And Threat Level (higher threat -> less resources)
        uint256 effectiveAetherDust = (baseAetherDust * sanctuaryResilienceIndex) / 2000; // Max Resilience is 2000
        uint256 effectiveCoreFragments = (baseCoreFragments * sanctuaryResilienceIndex) / 2000;

        // Threat level impact
        if (currentThreatLevel > 1) { // Apply reduction if threat is active
            effectiveAetherDust = effectiveAetherDust / currentThreatLevel;
            effectiveCoreFragments = effectiveCoreFragments / currentThreatLevel;
        }

        // Ensure minimums
        if (effectiveAetherDust == 0 && baseAetherDust > 0) effectiveAetherDust = 1;
        if (effectiveCoreFragments == 0 && baseCoreFragments > 0) effectiveCoreFragments = 1;


        // Mint resources to the Aethelgard contract itself, which stewards can then claim or which are used for game functions.
        // A more complex system might distribute directly to active stewards based on their contributions.
        aethelDust.mint(address(this), effectiveAetherDust);
        coreFragments.mint(address(this), effectiveCoreFragments);

        emit ResourcesDistributed(effectiveAetherDust, effectiveCoreFragments);
    }

    /// @notice Returns the address of the AetherDust ERC20 token contract.
    function getAetherDustContract() public view returns (address) {
        return address(aethelDust);
    }

    /// @notice Returns the address of the CoreFragments ERC20 token contract.
    function getCoreFragmentsContract() public view returns (address) {
        return address(coreFragments);
    }

    // --- V. Aethel Evolution & Upgrades ---

    /// @notice Grants experience points to an Aethel.
    /// @dev Callable by the contract owner, typically after an Aethel completes a "task" (conceptual).
    /// @param _aethelId The ID of the Aethel.
    /// @param _xpAmount The amount of experience to grant.
    function gainAethelExperience(uint256 _aethelId, uint256 _xpAmount) external onlyOwner whenNotPaused {
        Aethel storage aethel = aethels[_aethelId];
        require(aethel.id != 0, "Aethelgard: Aethel does not exist");

        aethel.experience += _xpAmount;
        uint256 oldLevel = aethel.level;
        aethel.level = 1 + (aethel.experience / XP_PER_LEVEL); // Levels up every XP_PER_LEVEL

        if (aethel.level > oldLevel) {
            // Provide base stat increase on level up
            aethel.power += 2;
            aethel.resilience += 2;
            aethel.wisdom += 2;
            _updateReputation(ownerOf(_aethelId), 5); // Small reputation bonus for owner
        }

        emit AethelExperienceGained(_aethelId, aethel.experience, aethel.level);
    }

    /// @notice Stewards use resources to selectively upgrade an Aethel's stats.
    /// @dev Requires AetherDust and CoreFragments. TraitIndex: 0=Power, 1=Resilience, 2=Wisdom.
    /// @param _aethelId The ID of the Aethel to upgrade.
    /// @param _traitIndex The index of the trait to upgrade (0=Power, 1=Resilience, 2=Wisdom).
    function upgradeAethelTraits(uint256 _aethelId, uint8 _traitIndex) external whenNotPaused {
        Aethel storage aethel = aethels[_aethelId];
        require(aethel.id != 0, "Aethelgard: Aethel does not exist");
        require(ownerOf(_aethelId) == msg.sender, "Aethelgard: Not owner of Aethel");
        require(_traitIndex < 3, "Aethelgard: Invalid trait index");

        // Check and consume resources from the sender
        require(aethelDust.balanceOf(msg.sender) >= UPGRADE_COST_ADUST, "Aethelgard: Insufficient AetherDust");
        require(coreFragments.balanceOf(msg.sender) >= UPGRADE_COST_CFRAG, "Aethelgard: Insufficient CoreFragments");

        // Transfer resources to the contract (acting as a sink)
        aethelDust.transferFrom(msg.sender, address(this), UPGRADE_COST_ADUST);
        coreFragments.transferFrom(msg.sender, address(this), UPGRADE_COST_CFRAG);

        uint256 oldValue;
        if (_traitIndex == 0) {
            oldValue = aethel.power;
            aethel.power += 1;
        } else if (_traitIndex == 1) {
            oldValue = aethel.resilience;
            aethel.resilience += 1;
        } else { // _traitIndex == 2
            oldValue = aethel.wisdom;
            aethel.wisdom += 1;
        }

        _updateReputation(msg.sender, 2); // Small reputation bonus for upgrading
        emit AethelTraitsUpgraded(_aethelId, _traitIndex, oldValue + 1);
    }

    /// @notice Stewards can attempt to change an Aethel's elemental affinity.
    /// @dev Requires rare resources and consumes Aethel experience. A successful mutation grants reputation.
    /// @param _aethelId The ID of the Aethel to mutate.
    /// @param _newElement The new elemental affinity (e.g., "Spirit", "Shadow").
    function mutateAethelElement(uint256 _aethelId, string memory _newElement) external whenNotPaused {
        Aethel storage aethel = aethels[_aethelId];
        require(aethel.id != 0, "Aethelgard: Aethel does not exist");
        require(ownerOf(_aethelId) == msg.sender, "Aethelgard: Not owner of Aethel");
        require(aethel.experience >= MUTATION_XP_COST, "Aethelgard: Insufficient Aethel XP for mutation");

        // Check and consume resources
        require(aethelDust.balanceOf(msg.sender) >= MUTATION_COST_ADUST, "Aethelgard: Insufficient AetherDust");
        require(coreFragments.balanceOf(msg.sender) >= MUTATION_COST_CFRAG, "Aethelgard: Insufficient CoreFragments");

        aethelDust.transferFrom(msg.sender, address(this), MUTATION_COST_ADUST);
        coreFragments.transferFrom(msg.sender, address(this), MUTATION_COST_CFRAG);
        aethel.experience -= MUTATION_XP_COST; // Consume XP

        string memory oldElement = aethel.element;
        // For demonstration, we'll assume mutations are always successful.
        // In a real system, this might involve a VRF, a chance factor based on Aethel wisdom, etc.
        aethel.element = _newElement;
        _updateReputation(msg.sender, 15); // Bonus for successful mutation
        emit AethelElementMutated(_aethelId, oldElement, _newElement);
    }

    // --- VI. Sanctuary State & Governance ---

    /// @notice Returns the current Resilience Index, Threat Level, and Resource Flow of the Sanctuary.
    function getSanctuaryStatus() public view returns (uint256 resilience, uint256 threat, uint256 resource) {
        return (sanctuaryResilienceIndex, currentThreatLevel, resourceFlowRate);
    }

    /// @notice Stewards propose changes to Sanctuary parameters or invoke actions on other contracts.
    /// @dev Requires a minimum reputation score and AetherDust fee.
    /// @param _description A summary of the proposal.
    /// @param _calldata The encoded function call to be executed if the proposal passes.
    /// @param _target The address of the target contract for the function call.
    /// @param _value The amount of Ether (if any) to send with the function call.
    function proposeSanctuaryAction(string memory _description, bytes memory _calldata, address _target, uint256 _value) external whenNotPaused {
        require(stewardReputation[msg.sender] >= MIN_REPUTATION_FOR_PROPOSAL, "Aethelgard: Insufficient reputation to propose");
        require(aethelDust.balanceOf(msg.sender) >= PROPOSAL_ADUST_FEE, "Aethelgard: Requires AetherDust fee to propose");

        aethelDust.transferFrom(msg.sender, address(this), PROPOSAL_ADUST_FEE); // Transfer fee to contract

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        uint256 dynamicThreshold = 500; // Base voting power needed for approval
        // Adjust threshold based on current Threat Level: higher threat requires more consensus.
        if (currentThreatLevel > 1) {
            dynamicThreshold += (currentThreatLevel * 100); // Higher threat, higher threshold
        }

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            calldataPayload: _calldata,
            targetContract: _target,
            value: _value,
            proposer: msg.sender,
            voteThreshold: dynamicThreshold,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            cancelled: false
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /// @notice Stewards vote on an active proposal.
    /// @dev Voting power is weighted by their reputation and bonded Aethels.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Aethelgard: Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime, "Aethelgard: Voting has not started");
        require(block.timestamp < proposal.voteEndTime, "Aethelgard: Voting has ended");
        require(!proposal.hasVoted[msg.sender], "Aethelgard: Already voted on this proposal");
        require(!proposal.executed, "Aethelgard: Proposal already executed");
        require(!proposal.cancelled, "Aethelgard: Proposal cancelled");

        uint256 votePower = calculateVotePower(msg.sender);
        require(votePower > 0, "Aethelgard: No voting power");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += votePower;
        } else {
            proposal.votesAgainst += votePower;
        }

        _updateReputation(msg.sender, 1); // Small reputation bonus for active participation
        emit ProposalVoted(_proposalId, msg.sender, _support, votePower);
    }

    /// @notice Executes a successfully approved proposal.
    /// @dev Can be called by anyone after the voting period ends and criteria are met.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Aethelgard: Proposal does not exist");
        require(block.timestamp >= proposal.voteEndTime, "Aethelgard: Voting period not ended");
        require(!proposal.executed, "Aethelgard: Proposal already executed");
        require(!proposal.cancelled, "Aethelgard: Proposal cancelled");
        require(proposal.votesFor > proposal.votesAgainst, "Aethelgard: Proposal did not pass by simple majority");
        require(proposal.votesFor >= proposal.voteThreshold, "Aethelgard: Proposal did not meet dynamic threshold");

        proposal.executed = true;

        // Execute the payload on the target contract
        (bool success, ) = proposal.targetContract.call{value: proposal.value}(proposal.calldataPayload);
        require(success, "Aethelgard: Proposal execution failed");

        _updateReputation(proposal.proposer, 20); // Bonus for the proposer of a successful proposal
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Updates the global Threat Level of the Sanctuary.
    /// @dev Callable only by the designated Threat Oracle. This impacts resource generation and governance thresholds.
    /// @param _newThreatLevel The new Threat Level value (e.g., 1-10).
    function updateThreatLevel(uint256 _newThreatLevel) external onlyOracle whenNotPaused {
        require(_newThreatLevel <= 10, "Aethelgard: Threat level cannot exceed 10"); // Example cap
        currentThreatLevel = _newThreatLevel;
        emit SanctuaryThreatLevelUpdated(_newThreatLevel);
    }

    /// @notice Adjusts the Sanctuary's Resilience Index.
    /// @dev Callable by the contract owner, representing system-level adjustments based on collective Aethel power, external events, or maintenance.
    /// @param _change The amount to change the Resilience Index by (can be negative).
    function adjustSanctuaryResilience(int256 _change) external onlyOwner whenNotPaused {
        if (_change > 0) {
            sanctuaryResilienceIndex += uint256(_change);
            if (sanctuaryResilienceIndex > 2000) sanctuaryResilienceIndex = 2000; // Cap resilience
        } else {
            uint256 absChange = uint256(-_change);
            if (sanctuaryResilienceIndex < absChange) {
                sanctuaryResilienceIndex = 0; // Resilience cannot go below zero
            } else {
                sanctuaryResilienceIndex -= absChange;
            }
        }
        emit SanctuaryResilienceAdjusted(_change, sanctuaryResilienceIndex);
    }

    /// @notice Calculates the effective voting power of a steward.
    /// @dev Based on their current reputation score and the combined power/level of their bonded Aethels.
    /// @param _steward The address of the Steward.
    /// @return The total calculated voting power.
    function calculateVotePower(address _steward) public view returns (uint256) {
        uint256 basePower = stewardReputation[_steward];
        uint256 aethelBonus = 0;

        uint256[] memory bonds = bondedAethels[_steward];
        for (uint256 i = 0; i < bonds.length; i++) {
            uint256 aethelId = bonds[i];
            Aethel storage aethel = aethels[aethelId];
            // Verify the Aethel is still bonded and owned by the steward
            if (aethel.isBonded && ownerOf(aethelId) == _steward) {
                // Aethel bonus formula: (sum of base stats) * level / scaling factor
                aethelBonus += (aethel.power + aethel.resilience + aethel.wisdom) * aethel.level / 10; // Example formula
            }
        }
        return basePower + aethelBonus;
    }

    // The following functions are standard ERC721 overrides, implicitly part of NFT management.
    // _approve(to, tokenId), _transfer(from, to, tokenId), supportsInterface(interfaceId),
    // tokenURI(tokenId), setApprovalForAll(operator, approved), getApproved(tokenId),
    // isApprovedForAll(owner, operator), transferFrom(from, to, tokenId) are standard.
    // They are available through the ERC721 inheritance but not listed explicitly as custom functions.
}
```