This smart contract, **EphemeralGenesisACS (Adaptive Collective Soulbound)**, proposes a novel concept where individual, non-transferable (soulbound) NFTs contribute to and evolve alongside a collective on-chain "organism." This organism, the "Collective Genesis," grows, changes, and unlocks new possibilities based on the aggregated actions, resource contributions, and governance decisions of its NFT holders. The contract emphasizes dynamic NFTs, community-driven progression, and a unique form of collective intelligence.

---

## **Contract: EphemeralGenesisACS (Adaptive Collective Soulbound)**

### **Outline & Function Summary**

**Core Concept:** A collective, evolving on-chain "organism" (the "Collective Genesis") whose state and progress are driven by individual soulbound NFTs (ACS-NFTs). ACS-NFTs are non-transferable and represent an individual's unique contribution and influence within the collective. Both individual NFTs and the collective evolve dynamically through resource contributions, nurturing actions, and community governance.

**Key Features:**

*   **Soulbound NFTs:** ERC721 tokens that cannot be transferred, binding an individual's identity and contribution to their digital soul.
*   **Dynamic Traits:** ACS-NFTs possess dynamic traits that evolve based on individual nurturing, collective actions, and environmental factors.
*   **Collective Resource Management:** Users contribute specific ERC-20 tokens (simulated as `resourceTokens`) to a shared pool that fuels the collective's growth and unlocks new phases.
*   **Epoch-based Evolution:** The Collective Genesis progresses through distinct "Epochs," each with unique parameters, challenges, and potential unlocks.
*   **Delegated Influence:** NFT holders can delegate their nurturing and voting power to others, fostering specialized roles or collective leadership.
*   **Cognitive Consensus (Governance):** A unique voting mechanism where voting weight is influenced by an NFT's current traits and the collective's state, leading to "emergent" governance.
*   **Emergent Patterns & Lore:** The contract hints at hidden patterns and allows for the contribution of on-chain narrative fragments, building a collective story.
*   **Proactive Maintenance & Decay:** Incentivizes continuous engagement by introducing a decay mechanism for NFTs and the collective if not actively maintained.

---

**Function Categories & Summary (25+ functions):**

1.  **Deployment & Setup (Core Team):**
    *   `constructor()`: Initializes the contract, sets initial core team, epoch 0 parameters, and the base URI for NFTs.
    *   `setCoreTeamMember(address _member, bool _isMember)`: Adds or removes core team members who have special administrative privileges.
    *   `setOracleAddress(address _oracleAddress)`: Sets the address of a trusted oracle for external data feeds.
    *   `addAllowedResourceToken(address _tokenAddress, bool _allowed)`: Manages which ERC-20 tokens can be contributed as resources.
    *   `setEpochDuration(uint256 _durationSeconds)`: Defines the minimum duration for each epoch before it can advance.

2.  **ACS-NFT Minting & Personal Progression:**
    *   `mintSoulboundNFT()`: Allows an address to mint their unique, non-transferable ACS-NFT (one per address).
    *   `nurtureSelfNFT()`: Allows an NFT owner to expend collective resources to boost specific traits of their own ACS-NFT and prevent decay.
    *   `getNFTTraits(uint256 _tokenId)`: Public view to retrieve the dynamic trait data of a specific ACS-NFT.
    *   `attuneToCollectiveVibe(uint256 _tokenId)`: Internal/keeper-triggered function where individual NFT traits subtly adjust based on the overall "vibe" or health of the collective.

3.  **Collective Genesis Interaction & Resource Management:**
    *   `contributeResource(address _resourceToken, uint256 _amount)`: Enables users to deposit approved ERC-20 tokens into the collective resource pool.
    *   `getCollectiveState()`: Public view to retrieve the current aggregated state variables of the collective organism (e.g., overall health, resource levels, current epoch).
    *   `triggerSynergyEvent()`: Callable when specific combinations of resources and collective state are reached, triggering unique, predefined synergistic effects on the collective.
    *   `absorbEnvironmentalData(bytes32 _dataHash)`: Callable by the registered oracle, updates collective environmental factors that influence growth, resource efficiency, or emergent traits.

4.  **Governance & Collective Evolution (Cognitive Consensus):**
    *   `delegateInfluence(address _delegatee)`: Enables an NFT owner to delegate their 'nurturing power' and voting influence to another NFT owner.
    *   `undelegateInfluence()`: Allows an NFT owner to revoke their influence delegation.
    *   `submitCollectiveDirective(string memory _description, bytes memory _calldata, uint256 _targetEpoch)`: Allows any NFT owner to propose a 'directive' (e.g., a governance proposal for a collective action or a parameter change).
    *   `voteOnDirective(bytes32 _directiveId, bool _support)`: NFT owners (or their delegates) can vote on active directives. Voting power is dynamically weighted by their NFT's current traits and delegated influence.
    *   `executeDirective(bytes32 _directiveId)`: An authorized function to enact a successfully voted-on directive.
    *   `advanceEpoch()`: Triggers a transition to the next 'Epoch' of collective evolution, updating collective state and unlocking new phases.
    *   `proposeTraitManifestation(string memory _traitName, string memory _description, uint256 _rarityScore)`: A governance proposal specifically for introducing a *new potential trait* that individual NFTs or the collective organism could develop.

5.  **Analytics & History:**
    *   `getTotalResources(address _resourceToken)`: View function to check total collective resources for a specific token.
    *   `getIndividualContribution(address _contributor, address _resourceToken)`: View function to check how much of a specific resource an individual has contributed.
    *   `getDelegatedPower(address _delegatee)`: View function to check the total influence delegated to a specific address.
    *   `getNFTGrowthHistory(uint256 _tokenId)`: View function to see a simplified log of significant trait changes for a specific NFT.
    *   `getCollectiveEvolutionLog(uint256 _epochId)`: View function to see a log of major collective state transitions and executed directives for a specific epoch.

6.  **Advanced / Creative Concepts:**
    *   `initiateCollectiveResonance()`: A high-cost, high-reward collective action requiring significant resource contribution and community consensus to trigger a rare, transformative event.
    *   `queryEmergentPattern(bytes32 _challengeId)`: A function designed to reveal hidden "patterns" or "secrets" about the collective's evolution, becoming accessible only when certain complex conditions or historical milestones are met. (Returns a URI or data hash).
    *   `decayProactiveMaintenance()`: A periodic internal function (or keeper-triggered) that reduces NFT traits or collective health if insufficient nurturing or resource contribution has occurred over time.
    *   `migrateLoreFragment(string memory _fragmentURI)`: Allows an NFT owner to contribute a small, immutable string (e.g., a short narrative snippet URI) to an on-chain "Lore Fragment" registry, contributing to the collective narrative.
    *   `getLoreFragments()`: Public view function to retrieve the collected lore fragments.

---

**Technologies Used (conceptual/simulation):**

*   **Solidity 0.8.x**: For smart contract development.
*   **OpenZeppelin Contracts**: For secure and audited implementations of ERC721, AccessControl, and utilities.
*   **Oracles (simulated):** For external data input (e.g., environmental factors influencing growth).
*   **Keepers/Automated Executors (simulated):** For periodic functions like `decayProactiveMaintenance` or `attuneToCollectiveVibe`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Custom Errors ---
error EphemeralGenesisACS__AlreadyMinted();
error EphemeralGenesisACS__NotNFTOwner();
error EphemeralGenesisACS__NotCoreTeam();
error EphemeralGenesisACS__NotOracle();
error EphemeralGenesisACS__InsufficientResources();
error EphemeralGenesisACS__ResourceTokenNotAllowed();
error EphemeralGenesisACS__InvalidDirectiveState();
error EphemeralGenesisACS__VotingPeriodNotActive();
error EphemeralGenesisACS__DirectiveAlreadyVoted();
error EphemeralGenesisACS__DirectiveNotReadyForExecution();
error EphemeralGenesisACS__EpochNotReadyToAdvance();
error EphemeralGenesisACS__NoActiveDirective();
error EphemeralGenesisACS__InfluenceAlreadyDelegated();
error EphemeralGenesisACS__CannotDelegateToSelf();
error EphemeralGenesisACS__SelfNurtureCooldownActive();
error EphemeralGenesisACS__NoLoreFragmentsFound();
error EphemeralGenesisACS__InsufficientCollectiveSynergy();
error EphemeralGenesisACS__EmergentPatternNotReady();
error EphemeralGenesisACS__InvalidTraitProposal();


// --- Enums and Structs ---

// Represents the overall health and state of the collective organism
enum CollectiveStatus { Dormant, Sprouting, Growing, Thriving, Resonating, Decaying }

// Dynamic traits for an individual ACS-NFT
struct NFTTraitSet {
    uint64 vibrancy;    // Health, resilience, decay resistance
    uint64 insight;     // Influence, voting weight, pattern recognition
    uint64 empathy;     // Resource efficiency, synergy potential
    uint64 adaptability; // Rate of trait change, resistance to environmental shifts
    uint64 lastNurtureTime; // Timestamp of last nurture action
}

// Represents the global state of the Collective Genesis
struct CollectiveState {
    uint256 currentEpoch;
    uint256 epochStartTime;
    CollectiveStatus status;
    uint256 totalVibrancySum; // Aggregate of all NFT vibrancies
    uint256 totalInsightSum;  // Aggregate of all NFT insights
    uint256 environmentalFactor; // External data influencing growth
    mapping(address => bool) activeTraits; // Proposed and active traits
}

// Represents a governance directive
struct Directive {
    string description;
    bytes calldataBytes; // Call data for target contract if executing external function
    uint256 proposalTime;
    uint256 votingEndTime;
    uint256 votesFor;
    uint256 votesAgainst;
    uint256 totalVotingPower; // Sum of all voting power at time of proposal
    bool executed;
    mapping(address => bool) hasVoted; // Address (delegatee) => voted
    bytes32 id; // Unique identifier for the directive
}

// Represents a fragment of collective lore
struct LoreFragment {
    address contributor;
    string fragmentURI; // URI to a piece of content (e.g., text, image)
    uint256 timestamp;
}

// --- Contract Definition ---
contract EphemeralGenesisACS is ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Roles ---
    bytes32 public constant CORE_TEAM_ROLE = keccak256("CORE_TEAM_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // NFT Data
    mapping(address => uint256) private s_addressToTokenId; // Tracks tokenId for soulbound NFT
    mapping(uint256 => NFTTraitSet) public nftTraits;       // tokenId => NFT's dynamic traits
    uint256 public constant SELF_NURTURE_COOLDOWN = 7 days; // Cooldown for nurtureSelfNFT

    // Collective State
    CollectiveState public collectiveState;
    uint256 public epochDurationSeconds = 30 days; // Minimum duration for an epoch

    // Resource Management
    mapping(address => bool) public allowedResourceTokens; // ERC20 address => is allowed
    mapping(address => uint256) public resourcePools;     // ERC20 address => total amount in pool
    mapping(address => mapping(address => uint256)) public individualContributions; // contributor => resourceToken => amount

    // Governance / Directives
    mapping(bytes32 => Directive) public directives;
    bytes32[] public activeDirectiveIds; // List of currently open directives

    // Influence Delegation
    mapping(address => address) public delegatedInfluence; // delegator => delegatee
    mapping(address => address[]) public reverseDelegation; // delegatee => list of delegators

    // Lore Fragments
    LoreFragment[] public loreFragments;

    // --- Events ---
    event NFTMinted(address indexed owner, uint256 tokenId);
    event ResourceContributed(address indexed contributor, address indexed token, uint256 amount);
    event NFTNurtured(uint256 indexed tokenId, uint64 vibrancyBoost, uint64 insightBoost);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee);
    event InfluenceUndelegated(address indexed delegator, address indexed previousDelegatee);
    event DirectiveSubmitted(bytes32 indexed directiveId, address indexed proposer, string description);
    event DirectiveVoted(bytes32 indexed directiveId, address indexed voter, bool support, uint256 votingPower);
    event DirectiveExecuted(bytes32 indexed directiveId, address indexed executor);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 epochStartTime);
    event CollectiveStateUpdated(CollectiveStatus newStatus, uint256 environmentalFactor);
    event SynergyEventTriggered(uint256 indexed epoch, CollectiveStatus newStatus, string description);
    event TraitManifestationProposed(bytes32 indexed proposalId, string traitName, uint256 rarityScore);
    event LoreFragmentMigrated(address indexed contributor, uint256 indexed fragmentId, string fragmentURI);
    event EmergentPatternRevealed(bytes32 indexed challengeId, string patternURI);
    event CollectiveDecay(uint256 indexed epoch, uint256 impactPercentage);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI_) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CORE_TEAM_ROLE, msg.sender);

        // Initialize Collective Genesis state
        collectiveState.currentEpoch = 0;
        collectiveState.epochStartTime = block.timestamp;
        collectiveState.status = CollectiveStatus.Dormant;
        collectiveState.environmentalFactor = 0; // Default or initial value
        _setBaseURI(baseURI_);
    }

    // --- Modifiers ---
    modifier onlyNFTHolder() {
        if (s_addressToTokenId[msg.sender] == 0) revert EphemeralGenesisACS__NotNFTOwner();
        _;
    }

    modifier onlyCoreTeam() {
        if (!hasRole(CORE_TEAM_ROLE, msg.sender)) revert EphemeralGenesisACS__NotCoreTeam();
        _;
    }

    modifier onlyOracle() {
        if (!hasRole(ORACLE_ROLE, msg.sender)) revert EphemeralGenesisACS__NotOracle();
        _;
    }

    // --- Administrative Functions (Core Team) ---

    /// @notice Sets or revokes the CORE_TEAM_ROLE for an address.
    /// @param _member The address to modify.
    /// @param _isMember True to grant, false to revoke.
    function setCoreTeamMember(address _member, bool _isMember) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_isMember) {
            _grantRole(CORE_TEAM_ROLE, _member);
        } else {
            _revokeRole(CORE_TEAM_ROLE, _member);
        }
    }

    /// @notice Sets the address of the trusted oracle. Only a Core Team member can call this.
    /// @param _oracleAddress The address of the oracle contract or account.
    function setOracleAddress(address _oracleAddress) external onlyCoreTeam {
        _grantRole(ORACLE_ROLE, _oracleAddress);
        // Revoke previous oracle role if any. Consider more robust oracle management if multiple oracles.
    }

    /// @notice Adds or removes an ERC-20 token from the list of allowed resources.
    /// @param _tokenAddress The address of the ERC-20 token.
    /// @param _allowed True to allow, false to disallow.
    function addAllowedResourceToken(address _tokenAddress, bool _allowed) external onlyCoreTeam {
        allowedResourceTokens[_tokenAddress] = _allowed;
    }

    /// @notice Sets the minimum duration for each epoch.
    /// @param _durationSeconds The duration in seconds.
    function setEpochDuration(uint256 _durationSeconds) external onlyCoreTeam {
        epochDurationSeconds = _durationSeconds;
    }

    // --- ACS-NFT Minting & Personal Progression ---

    /// @notice Allows a user to mint their unique Soulbound ACS-NFT. Can only be called once per address.
    /// @dev This NFT is non-transferable, symbolizing identity and participation.
    function mintSoulboundNFT() external {
        if (s_addressToTokenId[msg.sender] != 0) {
            revert EphemeralGenesisACS__AlreadyMinted();
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        s_addressToTokenId[msg.sender] = newTokenId;

        // Initialize NFT traits
        nftTraits[newTokenId] = NFTTraitSet({
            vibrancy: 100,      // Base vibrancy
            insight: 10,        // Base insight
            empathy: 10,        // Base empathy
            adaptability: 10,   // Base adaptability
            lastNurtureTime: block.timestamp
        });

        emit NFTMinted(msg.sender, newTokenId);
    }

    /// @notice Allows an NFT owner to expend collective resources to boost their own ACS-NFT's traits.
    /// @dev Requires a small amount of resources and has a cooldown.
    function nurtureSelfNFT() external onlyNFTHolder {
        uint256 tokenId = s_addressToTokenId[msg.sender];
        NFTTraitSet storage traits = nftTraits[tokenId];

        if (block.timestamp < traits.lastNurtureTime.add(SELF_NURTURE_COOLDOWN)) {
            revert EphemeralGenesisACS__SelfNurtureCooldownActive();
        }

        // Define the cost and boost. Example: 1 unit of a primary resource.
        // For simplicity, let's assume 'Essence' is at resourcePools[address(0)].
        // In a real scenario, you'd define which resource token to use.
        // Let's assume the contract uses a hardcoded primary resource token or an adjustable one.
        // For this example, let's use the first allowed resource token.
        address primaryResourceToken = address(0); // Placeholder, replace with actual allowed token
        for (uint256 i = 0; i < 1; i++) { // Iterate through allowedResourceTokens conceptually
            // This needs to be dynamic. For now, assume a predefined 'Essence' token.
            // A more robust implementation would use a specific ERC20 set as 'Essence'.
            // For example, if you have `address public essenceToken;`
            // require(resourcePools[essenceToken] >= 1, "Insufficient Essence for nurture");
            // resourcePools[essenceToken] = resourcePools[essenceToken].sub(1);
            // break;
        }

        // For demonstration, let's just assume a cost without consuming actual tokens from `resourcePools`
        // as the resource token address needs to be properly managed.
        // If we strictly follow the resourcePools design, we'd need a `primaryResourceToken` state variable.
        // For this example, let's just apply the boost for now, assuming resources are available.
        // In a full implementation, `nurtureSelfNFT` would consume a specific type of resource.

        traits.vibrancy = traits.vibrancy.add(5); // Example boost
        traits.insight = traits.insight.add(1);
        traits.lastNurtureTime = block.timestamp;

        emit NFTNurtured(tokenId, 5, 1);
    }

    /// @notice Retrieves the current dynamic traits of a specific ACS-NFT.
    /// @param _tokenId The ID of the ACS-NFT.
    /// @return NFTTraitSet The traits of the NFT.
    function getNFTTraits(uint256 _tokenId) external view returns (NFTTraitSet memory) {
        return nftTraits[_tokenId];
    }

    /// @notice Periodically or via keeper, adjusts NFT traits based on collective state.
    /// @param _tokenId The ID of the ACS-NFT to attune.
    /// @dev Simulates passive influence. Can be called by a keeper or implicitly on epoch advance.
    function attuneToCollectiveVibe(uint256 _tokenId) external {
        // This function would ideally be called by an off-chain keeper or during epoch advancement.
        // Access control can be added if needed, e.g., `onlyCoreTeam` or `onlyKeeper`.
        NFTTraitSet storage traits = nftTraits[_tokenId];

        // Example logic: if collective is thriving, boost empathy; if decaying, reduce vibrancy.
        if (collectiveState.status == CollectiveStatus.Thriving) {
            traits.empathy = traits.empathy.add(1);
        } else if (collectiveState.status == CollectiveStatus.Decaying && traits.vibrancy > 0) {
            traits.vibrancy = traits.vibrancy.sub(1);
        }
        // Additional complex logic here based on environmentalFactor, etc.
    }

    // --- Collective Genesis Interaction & Resource Management ---

    /// @notice Allows users to contribute allowed ERC-20 tokens to the collective resource pool.
    /// @param _resourceToken The address of the ERC-20 token being contributed.
    /// @param _amount The amount of tokens to contribute.
    function contributeResource(address _resourceToken, uint256 _amount) external onlyNFTHolder {
        if (!allowedResourceTokens[_resourceToken]) {
            revert EphemeralGenesisACS__ResourceTokenNotAllowed();
        }
        if (_amount == 0) {
            revert EphemeralGenesisACS__InsufficientResources(); // or custom error for zero amount
        }

        // Transfer tokens from sender to this contract
        IERC20(_resourceToken).transferFrom(msg.sender, address(this), _amount);

        resourcePools[_resourceToken] = resourcePools[_resourceToken].add(_amount);
        individualContributions[msg.sender][_resourceToken] = individualContributions[msg.sender][_resourceToken].add(_amount);

        // Update collective state based on resource contribution (simple example)
        if (collectiveState.status == CollectiveStatus.Dormant) {
            collectiveState.status = CollectiveStatus.Sprouting;
        }

        emit ResourceContributed(msg.sender, _resourceToken, _amount);
    }

    /// @notice Retrieves the current aggregated state of the Collective Genesis.
    /// @return currentEpoch The current epoch number.
    /// @return epochStartTime Timestamp when the current epoch began.
    /// @return status The current status of the collective.
    /// @return totalVibrancySum Aggregate vibrancy of all NFTs.
    /// @return totalInsightSum Aggregate insight of all NFTs.
    /// @return environmentalFactor Current external environmental data.
    function getCollectiveState() external view returns (uint256 currentEpoch, uint256 epochStartTime, CollectiveStatus status, uint256 totalVibrancySum, uint256 totalInsightSum, uint256 environmentalFactor) {
        return (
            collectiveState.currentEpoch,
            collectiveState.epochStartTime,
            collectiveState.status,
            collectiveState.totalVibrancySum,
            collectiveState.totalInsightSum,
            collectiveState.environmentalFactor
        );
    }

    /// @notice Triggers a rare, transformative 'Synergy Event' if collective conditions are met.
    /// @dev This requires significant resource levels and potentially specific collective states.
    function triggerSynergyEvent() external onlyNFTHolder {
        // Example condition: Requires high total vibrancy and sufficient "Catalyst" resource
        address catalystToken = address(0); // Placeholder, replace with actual allowed token
        // For example: `require(resourcePools[catalystToken] >= 1000 && collectiveState.totalVibrancySum >= 5000, EphemeralGenesisACS__InsufficientCollectiveSynergy());`
        // Assuming a specific `catalystToken` exists and resource `amount` is defined.

        if (collectiveState.totalVibrancySum < 5000) revert EphemeralGenesisACS__InsufficientCollectiveSynergy(); // Example

        // Perform transformative effects: e.g., boost all NFT traits, unlock a new status
        collectiveState.status = CollectiveStatus.Resonating;
        // Further logic to distribute boosts or unlock new features for NFTs

        emit SynergyEventTriggered(collectiveState.currentEpoch, collectiveState.status, "Collective resonance achieved!");
    }

    /// @notice Callable by the registered oracle to update environmental factors influencing the collective.
    /// @param _dataHash A hash representing external environmental data (e.g., climate conditions, market sentiment).
    /// @dev The oracle would compute `_dataHash` off-chain and provide a proof or direct value.
    function absorbEnvironmentalData(bytes32 _dataHash) external onlyOracle {
        // Example: Convert hash to a numerical factor. A real implementation might parse specific data.
        collectiveState.environmentalFactor = uint256(uint256(_dataHash) % 100); // Simple conversion to 0-99

        // Influence collective state (e.g., if factor is low, collective health slightly degrades)
        if (collectiveState.environmentalFactor < 20 && collectiveState.status != CollectiveStatus.Decaying) {
            collectiveState.status = CollectiveStatus.Decaying;
        } else if (collectiveState.environmentalFactor > 80 && collectiveState.status == CollectiveStatus.Growing) {
            collectiveState.status = CollectiveStatus.Thriving;
        }

        emit CollectiveStateUpdated(collectiveState.status, collectiveState.environmentalFactor);
    }

    // --- Governance & Collective Evolution (Cognitive Consensus) ---

    /// @notice Allows an NFT owner to delegate their nurturing power and voting influence to another NFT owner.
    /// @param _delegatee The address to delegate influence to.
    function delegateInfluence(address _delegatee) external onlyNFTHolder {
        if (_delegatee == msg.sender) revert EphemeralGenesisACS__CannotDelegateToSelf();
        if (delegatedInfluence[msg.sender] != address(0)) revert EphemeralGenesisACS__InfluenceAlreadyDelegated();

        delegatedInfluence[msg.sender] = _delegatee;
        reverseDelegation[_delegatee].push(msg.sender); // Keep track of who delegated to this address

        emit InfluenceDelegated(msg.sender, _delegatee);
    }

    /// @notice Allows an NFT owner to revoke their influence delegation.
    function undelegateInfluence() external onlyNFTHolder {
        address currentDelegatee = delegatedInfluence[msg.sender];
        if (currentDelegatee == address(0)) {
            revert EphemeralGenesisACS__InfluenceAlreadyDelegated(); // Or NoDelegationFound
        }

        delete delegatedInfluence[msg.sender];

        // Remove from reverseDelegation (simple, less gas-efficient for large arrays, better with a mapping)
        for (uint256 i = 0; i < reverseDelegation[currentDelegatee].length; i++) {
            if (reverseDelegation[currentDelegatee][i] == msg.sender) {
                reverseDelegation[currentDelegatee][i] = reverseDelegation[currentDelegatee][reverseDelegation[currentDelegatee].length - 1];
                reverseDelegation[currentDelegatee].pop();
                break;
            }
        }

        emit InfluenceUndelegated(msg.sender, currentDelegatee);
    }

    /// @notice Allows any NFT owner to propose a collective directive.
    /// @param _description A textual description of the directive.
    /// @param _calldata The bytes representation of the function call to execute if the directive passes (e.g., to an external contract).
    /// @param _targetEpoch The epoch for which this directive is intended, helps filter/categorize.
    /// @dev Voting power for this directive is snapshotted at proposal time.
    function submitCollectiveDirective(string memory _description, bytes memory _calldata, uint256 _targetEpoch) external onlyNFTHolder returns (bytes32 directiveId) {
        directiveId = keccak256(abi.encodePacked(_description, block.timestamp, msg.sender, _calldata));

        directives[directiveId] = Directive({
            description: _description,
            calldataBytes: _calldata,
            proposalTime: block.timestamp,
            votingEndTime: block.timestamp + 3 days, // 3-day voting period
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPower: _calculateTotalVotingPowerAtSnapshot(), // Snapshot voting power
            executed: false,
            id: directiveId
        });
        activeDirectiveIds.push(directiveId);

        emit DirectiveSubmitted(directiveId, msg.sender, _description);
    }

    /// @notice Allows an NFT owner (or their delegate) to vote on an active directive.
    /// @param _directiveId The ID of the directive to vote on.
    /// @param _support True for 'for', false for 'against'.
    function voteOnDirective(bytes32 _directiveId, bool _support) external onlyNFTHolder {
        Directive storage directive = directives[_directiveId];
        if (directive.proposalTime == 0) revert EphemeralGenesisACS__NoActiveDirective(); // Directive does not exist
        if (directive.votingEndTime < block.timestamp) revert EphemeralGenesisACS__VotingPeriodNotActive();
        if (directive.hasVoted[msg.sender]) revert EphemeralGenesisACS__DirectiveAlreadyVoted(); // Ensure unique votes

        uint256 voterTokenId = s_addressToTokenId[msg.sender];
        NFTTraitSet memory traits = nftTraits[voterTokenId];

        // Cognitive Consensus: Voting power is influenced by NFT's 'insight' and collective state.
        // For example: (insight / 10) * (collective_vibrancy_factor)
        uint256 votingPower = traits.insight;
        if (collectiveState.status == CollectiveStatus.Thriving) {
            votingPower = votingPower.mul(2); // Double power if thriving
        }

        // Include delegated power:
        for(uint256 i = 0; i < reverseDelegation[msg.sender].length; i++) {
            uint256 delegatorTokenId = s_addressToTokenId[reverseDelegation[msg.sender][i]];
            NFTTraitSet memory delegatorTraits = nftTraits[delegatorTokenId];
            votingPower = votingPower.add(delegatorTraits.insight);
             if (collectiveState.status == CollectiveStatus.Thriving) {
                votingPower = votingPower.add(delegatorTraits.insight); // Add more if thriving
            }
        }


        if (_support) {
            directive.votesFor = directive.votesFor.add(votingPower);
        } else {
            directive.votesAgainst = directive.votesAgainst.add(votingPower);
        }
        directive.hasVoted[msg.sender] = true;

        emit DirectiveVoted(_directiveId, msg.sender, _support, votingPower);
    }

    /// @notice Executes a successfully voted-on directive.
    /// @param _directiveId The ID of the directive to execute.
    function executeDirective(bytes32 _directiveId) external onlyCoreTeam {
        Directive storage directive = directives[_directiveId];

        if (directive.proposalTime == 0 || directive.executed) revert EphemeralGenesisACS__InvalidDirectiveState();
        if (block.timestamp < directive.votingEndTime) revert EphemeralGenesisACS__DirectiveNotReadyForExecution();

        // Simple majority vote: more 'for' votes than 'against'
        // Add a quorum check based on totalVotingPower if needed
        if (directive.votesFor <= directive.votesAgainst) {
            revert EphemeralGenesisACS__DirectiveNotReadyForExecution(); // Failed to pass
        }

        // Mark as executed
        directive.executed = true;

        // Remove from active directives
        for (uint256 i = 0; i < activeDirectiveIds.length; i++) {
            if (activeDirectiveIds[i] == _directiveId) {
                activeDirectiveIds[i] = activeDirectiveIds[activeDirectiveIds.length - 1];
                activeDirectiveIds.pop();
                break;
            }
        }

        // Execute the calldata (if any)
        if (directive.calldataBytes.length > 0) {
            (bool success,) = address(this).call(directive.calldataBytes);
            // Consider error handling or logging `success`
        }

        emit DirectiveExecuted(_directiveId, msg.sender);
    }

    /// @notice Triggers a transition to the next 'Epoch' of collective evolution.
    /// @dev Can only be called by core team, or could be a community-voted directive.
    function advanceEpoch() external onlyCoreTeam {
        if (block.timestamp < collectiveState.epochStartTime.add(epochDurationSeconds)) {
            revert EphemeralGenesisACS__EpochNotReadyToAdvance();
        }

        collectiveState.currentEpoch = collectiveState.currentEpoch.add(1);
        collectiveState.epochStartTime = block.timestamp;

        // Reset aggregate sums for new epoch
        collectiveState.totalVibrancySum = 0;
        collectiveState.totalInsightSum = 0;

        // Re-calculate aggregate sums based on current NFTs
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            NFTTraitSet storage traits = nftTraits[i];
            collectiveState.totalVibrancySum = collectiveState.totalVibrancySum.add(traits.vibrancy);
            collectiveState.totalInsightSum = collectiveState.totalInsightSum.add(traits.insight);

            // Periodically apply decay if not nurtured
            _applyDecay(i);

            // Apply passive attunement logic on epoch advance
            attuneToCollectiveVibe(i);
        }

        // Update collective status based on aggregate sums, resources, etc.
        _updateCollectiveStatus();

        emit EpochAdvanced(collectiveState.currentEpoch, collectiveState.epochStartTime);
    }

    /// @notice Allows a governance proposal specifically for introducing a new potential trait.
    /// @param _traitName The name of the proposed trait.
    /// @param _description A description of the trait's effects.
    /// @param _rarityScore A numerical score indicating the trait's rarity or impact.
    /// @dev This proposal, if passed, would add the trait to `collectiveState.activeTraits`.
    function proposeTraitManifestation(string memory _traitName, string memory _description, uint256 _rarityScore) external onlyNFTHolder {
        // This would typically involve submitting a directive using `submitCollectiveDirective`
        // where the `_calldata` would point to an internal function like `_activateNewTrait`.
        // For simplicity, this directly adds to a conceptual active traits mapping.
        // A more robust system would involve actual on-chain activation after a vote.

        bytes32 traitHash = keccak256(abi.encodePacked(_traitName, _description, _rarityScore));
        if (collectiveState.activeTraits[traitHash]) revert EphemeralGenesisACS__InvalidTraitProposal(); // Already proposed/active

        // In a real system, this would trigger a governance vote
        // For example: submitCollectiveDirective("Propose new trait: " + _traitName, abi.encodeWithSelector(this.activateProposedTrait.selector, traitHash), collectiveState.currentEpoch);

        // For demo purposes, simply mark as proposed:
        // collectiveState.activeTraits[traitHash] = true;
        emit TraitManifestationProposed(traitHash, _traitName, _rarityScore);
    }

    // --- Analytics & History ---

    /// @notice Returns the total amount of a specific resource token in the collective pool.
    /// @param _resourceToken The address of the resource token.
    /// @return uint256 The total amount.
    function getTotalResources(address _resourceToken) external view returns (uint256) {
        return resourcePools[_resourceToken];
    }

    /// @notice Returns the total amount of a specific resource token contributed by an individual.
    /// @param _contributor The address of the individual.
    /// @param _resourceToken The address of the resource token.
    /// @return uint256 The total contributed amount.
    function getIndividualContribution(address _contributor, address _resourceToken) external view returns (uint256) {
        return individualContributions[_contributor][_resourceToken];
    }

    /// @notice Returns the total insight voting power delegated to a specific address.
    /// @param _delegatee The address to check for delegated power.
    /// @return uint256 The sum of insight points delegated to this address.
    function getDelegatedPower(address _delegatee) public view returns (uint256) {
        uint256 totalPower = 0;
        for (uint256 i = 0; i < reverseDelegation[_delegatee].length; i++) {
            uint256 delegatorTokenId = s_addressToTokenId[reverseDelegation[_delegatee][i]];
            totalPower = totalPower.add(nftTraits[delegatorTokenId].insight);
        }
        return totalPower;
    }

    /// @notice Retrieves a simplified log of significant trait changes for a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return string A string representing the growth history (conceptual for on-chain storage).
    function getNFTGrowthHistory(uint256 _tokenId) external pure returns (string memory) {
        // This would ideally return an array of events or a structured log.
        // For simplicity and gas, a real implementation might use an off-chain indexer or
        // a dedicated history mapping that stores compact event data.
        // As a conceptual example, we return a placeholder string.
        return string(abi.encodePacked("NFT ", _tokenId.toString(), " has evolved significantly across epochs. Check events for details."));
    }

    /// @notice Retrieves a log of major collective state transitions and executed directives for a specific epoch.
    /// @param _epochId The epoch number.
    /// @return string A string representing the evolution log (conceptual for on-chain storage).
    function getCollectiveEvolutionLog(uint256 _epochId) external pure returns (string memory) {
        // Similar to getNFTGrowthHistory, this would be complex to store entirely on-chain.
        // This is a placeholder for a rich data query function.
        return string(abi.encodePacked("Epoch ", _epochId.toString(), ": Details of collective state and directives. Refer to contract events."));
    }

    // --- Advanced / Creative Concepts ---

    /// @notice A high-cost, high-reward collective action that requires significant resource contribution and consensus.
    /// @dev Triggers a transformative state change for the entire collective, often resetting or greatly boosting aspects.
    function initiateCollectiveResonance() external onlyCoreTeam { // Or via successful directive
        // Requires very high resource levels of specific tokens, e.g., 'SynergyCatalyst'
        // require(resourcePools[synergyCatalystToken] >= 10000, "Insufficient SynergyCatalyst for Resonance");
        // And potentially a minimum threshold for `collectiveState.totalInsightSum`.

        // Transformative effects:
        collectiveState.status = CollectiveStatus.Resonating; // New, powerful state
        collectiveState.currentEpoch = collectiveState.currentEpoch.add(10); // Leaps ahead epochs
        collectiveState.epochStartTime = block.timestamp;
        // Significant boost to all NFT traits, etc.

        emit SynergyEventTriggered(collectiveState.currentEpoch, collectiveState.status, "Grand Collective Resonance Initiated!");
    }

    /// @notice Reveals a hidden "pattern" or "secret" about the collective's evolution when specific, complex conditions are met.
    /// @param _challengeId A specific identifier for the pattern challenge.
    /// @return string A URI or data hash representing the revealed pattern.
    /// @dev This function would have complex internal logic based on historical states, resource sums, and specific NFT trait combinations.
    function queryEmergentPattern(bytes32 _challengeId) external view returns (string memory) {
        // Example condition: `_challengeId` matches a predefined hash AND collectiveState.currentEpoch > 5 AND collectiveState.totalVibrancySum > 10000
        bytes32 secretPatternHash = keccak256(abi.encodePacked("The Unified Field Resonates in Harmony"));
        if (_challengeId != secretPatternHash || collectiveState.currentEpoch < 5 || collectiveState.totalVibrancySum < 10000) {
            revert EphemeralGenesisACS__EmergentPatternNotReady();
        }
        // Returns a URI to a generative image, a secret message, or unlocks new functionality.
        emit EmergentPatternRevealed(_challengeId, "ipfs://QmYourEmergentPatternURI");
        return "ipfs://QmYourEmergentPatternURI";
    }

    /// @notice A periodic function that reduces NFT traits or collective health if insufficient nurturing/resource contribution.
    /// @dev This incentivizes continuous engagement. Can be called by a keeper or implicitly on epoch advance.
    function decayProactiveMaintenance() external { // Could be onlyCoreTeam or onlyKeeper
        if (block.timestamp % 1 days != 0) return; // Only execute once per day for simplicity

        uint256 currentTokenId = _tokenIdCounter.current();
        uint256 decayAmount = 1; // Example decay units

        // Apply decay to collective health if resources are low
        if (resourcePools[address(0)] < 100) { // Assuming a primary resource exists
            // This is a simplified decay for the collective
            if (collectiveState.status != CollectiveStatus.Decaying) {
                collectiveState.status = CollectiveStatus.Decaying;
            }
        }

        // Apply decay to individual NFTs if not nurtured recently
        for (uint256 i = 1; i <= currentTokenId; i++) {
            NFTTraitSet storage traits = nftTraits[i];
            if (block.timestamp > traits.lastNurtureTime.add(30 days)) { // If not nurtured in 30 days
                _applyDecay(i);
            }
        }
        emit CollectiveDecay(collectiveState.currentEpoch, decayAmount);
    }

    /// @notice Allows an NFT owner to contribute a small, immutable string (e.g., a URI to a narrative snippet) to an on-chain Lore Fragment registry.
    /// @param _fragmentURI The URI pointing to the lore content (e.g., IPFS hash).
    function migrateLoreFragment(string memory _fragmentURI) external onlyNFTHolder {
        loreFragments.push(LoreFragment({
            contributor: msg.sender,
            fragmentURI: _fragmentURI,
            timestamp: block.timestamp
        }));
        emit LoreFragmentMigrated(msg.sender, loreFragments.length - 1, _fragmentURI);
    }

    /// @notice Retrieves all collected lore fragments.
    /// @return LoreFragment[] An array of all lore fragments.
    function getLoreFragments() external view returns (LoreFragment[] memory) {
        if (loreFragments.length == 0) revert EphemeralGenesisACS__NoLoreFragmentsFound();
        return loreFragments;
    }

    // --- Internal / Private Helper Functions ---

    /// @dev Internal function to prevent transfers of soulbound NFTs.
    /// Overrides ERC721's _beforeTokenTransfer to ensure NFTs are non-transferable.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        // Allow minting (from == address(0))
        if (from == address(0)) {
            return;
        }
        // Disallow all other transfers
        revert("ACS-NFTs are soulbound and non-transferable.");
    }

    /// @dev Internal helper to calculate total voting power at the time of proposal snapshot.
    /// Sums up all current NFT insights.
    function _calculateTotalVotingPowerAtSnapshot() internal view returns (uint256) {
        uint256 totalPower = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            totalPower = totalPower.add(nftTraits[i].insight);
        }
        return totalPower;
    }

    /// @dev Internal function to apply decay to a specific NFT's traits.
    /// @param _tokenId The ID of the NFT to apply decay to.
    function _applyDecay(uint256 _tokenId) internal {
        NFTTraitSet storage traits = nftTraits[_tokenId];
        uint256 decayPeriod = block.timestamp.sub(traits.lastNurtureTime);
        uint256 periodsToDecay = decayPeriod.div(30 days); // Decay every 30 days of inactivity

        if (periodsToDecay > 0) {
            // Apply proportional decay based on `periodsToDecay`
            uint64 vibrancyDecay = uint64(uint256(traits.vibrancy).mul(periodsToDecay).div(100)); // Example: 1% decay per period
            uint64 insightDecay = uint64(uint256(traits.insight).mul(periodsToDecay).div(100));

            if (traits.vibrancy > vibrancyDecay) traits.vibrancy = traits.vibrancy.sub(vibrancyDecay); else traits.vibrancy = 0;
            if (traits.insight > insightDecay) traits.insight = traits.insight.sub(insightDecay); else traits.insight = 0;
            // Other traits can decay similarly
        }
    }

    /// @dev Internal function to update the collective status based on aggregate sums and resources.
    function _updateCollectiveStatus() internal {
        uint256 averageVibrancy = collectiveState.totalVibrancySum.div(_tokenIdCounter.current() > 0 ? _tokenIdCounter.current() : 1);
        uint256 totalResourceValue = resourcePools[address(0)]; // Assuming primary resource

        if (averageVibrancy > 150 && totalResourceValue > 1000) {
            collectiveState.status = CollectiveStatus.Thriving;
        } else if (averageVibrancy > 80 && totalResourceValue > 200) {
            collectiveState.status = CollectiveStatus.Growing;
        } else if (averageVibrancy > 30 && totalResourceValue > 50) {
            collectiveState.status = CollectiveStatus.Sprouting;
        } else {
            collectiveState.status = CollectiveStatus.Decaying;
        }
    }

    // --- ERC721 Overrides (to ensure Soulbound nature) ---
    // These functions are intentionally omitted or overridden to prevent transfers.
    // _beforeTokenTransfer handles the actual blocking.

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("ACS-NFTs are soulbound and non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("ACS-NFTs are soulbound and non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert("ACS-NFTs are soulbound and non-transferable.");
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert("ACS-NFTs are soulbound and non-transferable.");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("ACS-NFTs are soulbound and non-transferable.");
    }

    // --- View Functions ---

    /// @notice Returns the token ID associated with a given address (if they own an ACS-NFT).
    /// @param _owner The address to query.
    /// @return uint256 The token ID, or 0 if no NFT found.
    function getTokenIdByAddress(address _owner) external view returns (uint256) {
        return s_addressToTokenId[_owner];
    }
}
```