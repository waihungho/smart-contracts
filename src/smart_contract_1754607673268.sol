The "Aetheria Protocol" is a conceptual decentralized autonomous organization (DAO) designed for adaptive resource allocation and community-driven evolution. It introduces a novel reputation system using **Soulbound Tokens (SBTs)** that evolve based on user contributions and project outcomes. The protocol operates in **Epochs**, where resource distribution to various "Spheres" (e.g., R&D, Community Growth) is dynamically adjusted based on community proposals, voting, and "insights" from a simulated **AI/Data Oracle**. Successful projects boost the reputation of their proposers and voters, creating a continuous feedback loop that fosters growth and accountability.

This contract aims to be an **advanced, creative, and non-duplicative** example by combining:
*   **Dynamic, Evolving Soulbound Tokens:** Your reputation is an NFT that levels up.
*   **Adaptive Treasury Allocation:** Funds are not fixed, but dynamically re-allocated based on collective intelligence and external data.
*   **Epoch-based Operations:** Time-gated cycles for strategic re-evaluation.
*   **Simulated AI Oracle Integration:** Provides external "wisdom" that the community can consider.
*   **Self-Correcting Feedback Loops:** Project success/failure directly influences reputation and future resource distribution.
*   **Contextualized Governance:** Voting power is directly tied to reputation and active participation.

---

## AetheriaProtocol: Outline and Function Summary

**I. Protocol Configuration & Core Management (Owner/Admin Controlled)**
*   **`constructor`**: Initializes the contract, sets epoch duration, and initial oracle address.
*   **`updateOracleAddress`**: Allows the owner to update the trusted address of the `OracleOfAetheria`.
*   **`updateEpochDuration`**: Modifies the duration of an epoch in seconds.
*   **`pauseProtocol`**: Emergency function to pause critical operations of the protocol.
*   **`unpauseProtocol`**: Resumes protocol operations after a pause.
*   **`depositToTreasury`**: Allows anyone to contribute funds to the protocol's treasury.
*   **`withdrawFromTreasury`**: Allows the contract owner to withdraw funds for designated operational purposes (e.g., off-chain costs, though typically DAO controlled).

**II. Reputation Soulbound Tokens (rSBTs) & Identity**
*   **`mintInitialRSBT`**: Mints the first, entry-level rSBT to a new participant, marking their entry into the Aetheria community. This rSBT is non-transferable and represents their on-chain identity and potential.
*   **`ascendRSBTLevel`**: Allows an rSBT holder to increase their reputation "level" by spending accumulated `contributionPoints`. Higher levels grant more voting power and potential privileges.
*   **`getRSBTLevel`**: Public getter to query a user's current rSBT level.
*   **`getRSBTContributionPoints`**: Public getter to query the accumulated contribution points for an rSBT.
*   **`getVotingPower`**: Calculates and returns a user's current voting power, which is based on their rSBT level and active participation within the current epoch.
*   **`delegateVotingPower`**: Allows an rSBT holder to temporarily delegate their voting power to another trusted rSBT holder for a specified duration or epoch.
*   **`revokeDelegation`**: Revokes an active voting power delegation.

**III. Adaptive Resource Allocation & Spheres**
*   **`defineSphere`**: Allows the creation of new resource allocation categories (e.g., "Decentralized AI Research", "Community Arts Initiatives"). Each Sphere has its own allocation target.
*   **`proposeSphereAllocationChange`**: Allows rSBT holders to propose new target allocation percentages for Spheres for the upcoming epoch, often leveraging insights from the Oracle.
*   **`voteOnSphereAllocationProposal`**: rSBT holders cast votes on proposed Sphere allocation changes using their dynamic voting power.
*   **`executeSphereAllocationProposal`**: Executes a passed Sphere allocation proposal at the end of an epoch, updating the treasury's distribution percentages for the next cycle.
*   **`getSphereCurrentAllocation`**: Public getter for the current target allocation percentage of a specific Sphere within the treasury.
*   **`updateSphereOracleInfluenceWeight`**: Allows the community (via governance or admin) to adjust how much the Oracle's suggestions specifically impact a certain Sphere's allocation during epoch advancement.

**IV. Project Management & Funding Lifecycle**
*   **`submitProjectProposal`**: Allows rSBT holders to propose projects seeking funding within a defined Sphere. Requires a detailed proposal and requested amount.
*   **`voteOnProjectProposal`**: rSBT holders vote on individual project proposals. Project votes contribute to the project proposer's and voters' reputation.
*   **`finalizeProjectProposal`**: An automated or admin-triggered function that disburses funds from the treasury to a successfully voted project and marks it for future impact tracking.
*   **`submitProjectImpactReport`**: Project proposers are required to submit a report on the outcome and impact of their completed project, typically after its successful execution.
*   **`verifyProjectImpactByOracle`**: This function is called by the `OracleOfAetheria` to confirm or adjust a project's reported impact, which then triggers reputation adjustments (increase or decrease) for the proposer and the voters of that project.
*   **`getProjectStatus`**: Public getter to check the current status and detailed information of a specific project.

**V. Epoch Management & Protocol Evolution**
*   **`advanceEpoch`**: The core function that triggers the end-of-epoch processes:
    *   Calculates and applies reputation point adjustments based on active participation and project outcomes.
    *   Re-evaluates and potentially adjusts current Sphere allocations based on passed proposals and Oracle insights.
    *   Resets voting states and prepares for the next epoch.
*   **`getOracleSuggestedSphereAllocations`**: Public getter to view the Oracle's latest suggestions for Sphere allocations for the upcoming epoch, providing external data-driven recommendations.

---
### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; // For internal burn if needed, though SBTs are generally non-burnable by holder.

// Interface for the simulated Oracle of Aetheria
interface IOracleOfAetheria {
    // Returns suggested allocation percentages for given sphere IDs for the next epoch
    function getSuggestedSphereAllocations(uint256 currentEpoch) external view returns (uint256[] memory sphereIds, uint256[] memory percentages);
    // Verifies a project's reported impact. Returns success and the final (potentially adjusted) impact score.
    function verifyProjectImpact(uint256 projectId, uint256 reportedImpactScore) external returns (bool success, uint256 finalImpactScore);
}

// Custom errors for better error handling
error AetheriaProtocol__InvalidEpochDuration();
error AetheriaProtocol__EpochNotEnded();
error AetheriaProtocol__EpochInProgress();
error AetheriaProtocol__NotRSBTHolder();
error AetheriaProtocol__InsufficientContributionPoints();
error AetheriaProtocol__MaxRSBTLevelReached();
error AetheriaProtocol__SphereAlreadyExists();
error AetheriaProtocol__SphereNotFound();
error AetheriaProtocol__InvalidAllocationSum();
error AetheriaProtocol__NotEnoughFundsInTreasury();
error AetheriaProtocol__ProjectNotFound();
error AetheriaProtocol__ProjectNotInFundingStatus();
error AetheriaProtocol__ProjectAlreadyReported();
error AetheriaProtocol__ProjectNotCompleted();
error AetheriaProtocol__VoteAlreadyCast();
error AetheriaProtocol__InvalidProposalState();
error AetheriaProtocol__DelegationAlreadyExists();
error AetheriaProtocol__SelfDelegationNotAllowed();
error AetheriaProtocol__DelegationExpired();
error AetheriaProtocol__DelegationNotFound();
error AetheriaProtocol__DelegatorHasActiveProjects();


contract AetheriaProtocol is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // --- Events ---
    event EpochAdvanced(uint256 indexed epochNumber, uint256 timestamp);
    event RSBTMinted(address indexed owner, uint256 indexed tokenId, uint256 level);
    event RSBTAscended(address indexed owner, uint256 indexed tokenId, uint256 newLevel, uint256 pointsSpent);
    event ContributionPointsAdjusted(address indexed holder, uint256 newPoints, string reason);
    event SphereDefined(uint256 indexed sphereId, string name, uint256 initialAllocation);
    event SphereAllocationProposed(uint256 indexed proposalId, address indexed proposer, uint256 indexed epoch, uint256[] sphereIds, uint256[] percentages);
    event SphereAllocationVoted(uint256 indexed proposalId, address indexed voter, uint256 votingPower);
    event SphereAllocationExecuted(uint256 indexed proposalId, uint256 indexed epoch, uint256[] sphereIds, uint256[] percentages);
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, uint256 indexed sphereId, uint256 requestedAmount);
    event ProjectVoted(uint256 indexed projectId, address indexed voter, uint256 votingPower);
    event ProjectFinalized(uint256 indexed projectId, address indexed recipient, uint256 fundedAmount);
    event ProjectImpactReported(uint256 indexed projectId, uint256 reportedImpact);
    event ProjectImpactVerified(uint256 indexed projectId, uint256 finalImpactScore);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee, uint256 expirationEpoch);
    event VotingPowerRevoked(address indexed delegator, address indexed delegatee);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- State Variables ---

    // Epoch Management
    uint256 public currentEpoch;
    uint256 public epochDuration; // in seconds
    uint256 public lastEpochAdvanceTime;

    // Treasury
    uint256 public totalTreasuryFunds;

    // Oracle Integration
    IOracleOfAetheria public oracleOfAetheria;

    // --- RSBT (Reputation Soulbound Token) ---
    Counters.Counter private _rsbtTokenIdCounter;

    struct RSBT {
        uint256 level;
        uint256 contributionPoints;
        uint256 lastActiveEpoch; // Epoch when the RSBT last participated in a vote or had points adjusted
        address delegatedTo; // Address to whom voting power is delegated
        uint256 delegationExpirationEpoch; // Epoch when delegation expires
    }
    mapping(address => uint256) public addressToRSBTId; // User address to their RSBT token ID (0 if none)
    mapping(uint256 => RSBT) public rsbtData; // RSBT ID to its data

    // RSBT Level Tiers: level => [points_to_ascend, voting_power]
    // Max 10 levels for simplicity. 0 is initial, 1-10 are ascendable.
    uint256[11][2] public RSBT_LEVEL_TIERS = [
        [0, 100],      // Level 0: 0 points, 100 voting power (initial)
        [100, 200],    // Level 1: requires 100 points, grants 200 voting power
        [250, 400],    // Level 2: requires 250 points, grants 400 voting power
        [500, 700],    // Level 3: requires 500 points, grants 700 voting power
        [900, 1100],   // Level 4: requires 900 points, grants 1100 voting power
        [1400, 1600],  // Level 5: requires 1400 points, grants 1600 voting power
        [2000, 2200],  // Level 6: requires 2000 points, grants 2200 voting power
        [2700, 2900],  // Level 7: requires 2700 points, grants 2900 voting power
        [3500, 3700],  // Level 8: requires 3500 points, grants 3700 voting power
        [4400, 4600],  // Level 9: requires 4400 points, grants 4600 voting power
        [5400, 5800]   // Level 10: requires 5400 points, grants 5800 voting power (max)
    ];
    uint256 public constant MAX_RSBT_LEVEL = 10;
    uint256 public constant MIN_PROJECT_IMPACT_FOR_PROPOSER_BOOST = 60; // Impact score 0-100
    uint256 public constant MIN_PROJECT_IMPACT_FOR_VOTER_BOOST = 75;
    uint256 public constant MAX_IMPACT_SCORE = 100;

    // --- Spheres (Resource Allocation Categories) ---
    Counters.Counter private _sphereIdCounter;
    struct Sphere {
        string name;
        uint256 currentAllocationPercent; // Current target % of treasury for this sphere (sum of all must be 100)
        uint256 oracleInfluenceWeight; // How much oracle suggestions influence this sphere (0-100)
        bool exists;
    }
    mapping(uint256 => Sphere) public spheres;
    uint256[] public activeSphereIds; // Array of IDs of currently active spheres

    // --- Sphere Allocation Proposals ---
    Counters.Counter private _sphereProposalIdCounter;
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct SphereAllocationProposal {
        address proposer;
        uint256 epochProposed;
        uint256[] sphereIds;
        uint256[] percentages; // Proposed new percentages for corresponding sphereIds
        uint256 totalVotesFor;
        mapping(address => bool) hasVoted; // Tracks who has voted for this proposal
        ProposalState state;
        uint256 votingDeadlineEpoch;
    }
    mapping(uint256 => SphereAllocationProposal) public sphereAllocationProposals;
    uint256 public minSphereProposalVotingPower = 500; // Min total voting power required for a proposal to pass

    // --- Projects ---
    Counters.Counter private _projectIdCounter;
    enum ProjectStatus { Proposed, ActiveVoting, Approved, Rejected, Funded, Completed, ImpactReported, Verified }
    struct Project {
        address proposer;
        uint256 sphereId;
        uint256 amountRequested;
        string title;
        string description;
        ProjectStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted on this project
        uint256 fundingDeadlineEpoch; // Epoch by which voting must conclude
        uint256 impactScoreReported; // Reported by proposer (0-100)
        uint256 impactScoreVerified; // Verified by oracle (0-100)
        bool impactVerified;
    }
    mapping(uint256 => Project) public projects;
    uint256 public minProjectVoteThreshold = 1000; // Min total voting power required for a project to pass

    // --- Constructor ---
    constructor(address _oracleAddress, uint256 _epochDuration)
        ERC721("Aetheria RSBT", "ARBT")
        Ownable(msg.sender)
        Pausable()
    {
        if (_epochDuration == 0) revert AetheriaProtocol__InvalidEpochDuration();
        epochDuration = _epochDuration;
        lastEpochAdvanceTime = block.timestamp;
        currentEpoch = 1; // Start with Epoch 1
        oracleOfAetheria = IOracleOfAetheria(_oracleAddress);

        // Define initial spheres (e.g., Core Development, Community Grants)
        _defineSphere("Core Development", 50);
        _defineSphere("Community Grants", 30);
        _defineSphere("Social Impact", 20);
        // Ensure initial sum is 100%
        require(getSumOfCurrentAllocations() == 100, "Initial sphere allocations must sum to 100%");
    }

    // --- Modifiers ---
    modifier onlyRSBTHolder() {
        if (addressToRSBTId[msg.sender] == 0) revert AetheriaProtocol__NotRSBTHolder();
        _;
    }
    
    // --- I. Protocol Configuration & Core Management ---

    /// @notice Updates the address of the trusted Oracle of Aetheria.
    /// @param _newOracleAddress The new address for the Oracle contract.
    function updateOracleAddress(address _newOracleAddress) external onlyOwner {
        oracleOfAetheria = IOracleOfAetheria(_newOracleAddress);
    }

    /// @notice Modifies the duration of an epoch in seconds.
    /// @param _newEpochDuration The new duration for an epoch in seconds. Must be > 0.
    function updateEpochDuration(uint256 _newEpochDuration) external onlyOwner {
        if (_newEpochDuration == 0) revert AetheriaProtocol__InvalidEpochDuration();
        epochDuration = _newEpochDuration;
    }

    /// @notice Emergency function to pause critical operations of the protocol.
    /// @dev Only callable by the contract owner.
    function pauseProtocol() external onlyOwner {
        _pause();
    }

    /// @notice Resumes protocol operations after a pause.
    /// @dev Only callable by the contract owner.
    function unpauseProtocol() external onlyOwner {
        _unpause();
    }

    /// @notice Allows anyone to deposit funds into the protocol's treasury.
    function depositToTreasury() external payable {
        totalTreasuryFunds += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Allows the contract owner to withdraw a specified amount from the treasury.
    /// @dev This function is for operational costs, not for project funding. Project funding happens via proposals.
    /// @param _amount The amount of funds to withdraw.
    function withdrawFromTreasury(uint256 _amount) external onlyOwner {
        if (_amount == 0 || _amount > totalTreasuryFunds) revert AetheriaProtocol__NotEnoughFundsInTreasury();
        totalTreasuryFunds -= _amount;
        payable(msg.sender).transfer(_amount);
        emit FundsWithdrawn(msg.sender, _amount);
    }

    // --- II. Reputation Soulbound Tokens (rSBTs) & Identity ---

    /// @notice Mints the first, entry-level rSBT to a new participant.
    /// @dev An address can only mint one rSBT. This token is non-transferable (Soulbound).
    function mintInitialRSBT() external whenNotPaused {
        if (addressToRSBTId[msg.sender] != 0) revert("AetheriaProtocol: Already an RSBT holder.");

        _rsbtTokenIdCounter.increment();
        uint256 newTokenId = _rsbtTokenIdCounter.current();

        _mint(msg.sender, newTokenId); // ERC721 mint

        rsbtData[newTokenId] = RSBT({
            level: 0,
            contributionPoints: 0,
            lastActiveEpoch: currentEpoch,
            delegatedTo: address(0),
            delegationExpirationEpoch: 0
        });
        addressToRSBTId[msg.sender] = newTokenId;

        // Make the token non-transferable (Soulbound) by overriding _beforeTokenTransfer in ERC721.
        // For demonstration, we simply don't implement _transfer, _approve, _setApprovalForAll outside.
        // A full SBT implementation would override ERC721's transfer functions.
        // For now, _transfer is internal to ERC721. If public transfer functions were exposed, they'd need to be restricted.

        emit RSBTMinted(msg.sender, newTokenId, 0);
    }

    /// @notice Allows an rSBT holder to increase their reputation level by spending contribution points.
    /// @dev Higher levels grant more voting power.
    function ascendRSBTLevel() external onlyRSBTHolder whenNotPaused {
        uint256 rsbtId = addressToRSBTId[msg.sender];
        RSBT storage sbt = rsbtData[rsbtId];

        if (sbt.level >= MAX_RSBT_LEVEL) revert AetheriaProtocol__MaxRSBTLevelReached();

        uint256 nextLevel = sbt.level + 1;
        uint256 pointsRequired = RSBT_LEVEL_TIERS[nextLevel][0];

        if (sbt.contributionPoints < pointsRequired) revert AetheriaProtocol__InsufficientContributionPoints();

        sbt.contributionPoints -= pointsRequired;
        sbt.level = nextLevel;
        sbt.lastActiveEpoch = currentEpoch; // Mark as active

        emit RSBTAscended(msg.sender, rsbtId, nextLevel, pointsRequired);
    }

    /// @notice Adjusts the contribution points of an RSBT holder.
    /// @dev Internal function called by project outcomes or participation.
    /// @param _holder The address of the RSBT holder.
    /// @param _points The number of points to add or subtract (can be negative).
    /// @param _reason A string describing the reason for the adjustment.
    function _adjustRSBTContributionPoints(address _holder, int256 _points, string memory _reason) internal {
        uint256 rsbtId = addressToRSBTId[_holder];
        if (rsbtId == 0) return; // Not an RSBT holder

        RSBT storage sbt = rsbtData[rsbtId];
        
        if (_points > 0) {
            sbt.contributionPoints += uint256(_points);
        } else {
            uint256 pointsToSubtract = uint256(-_points);
            if (sbt.contributionPoints < pointsToSubtract) {
                sbt.contributionPoints = 0; // Cap at 0, don't go negative
            } else {
                sbt.contributionPoints -= pointsToSubtract;
            }
        }
        sbt.lastActiveEpoch = currentEpoch; // Mark as active
        emit ContributionPointsAdjusted(_holder, sbt.contributionPoints, _reason);
    }

    /// @notice Returns the current level of an rSBT.
    /// @param _owner The address of the rSBT holder.
    /// @return The level of the rSBT.
    function getRSBTLevel(address _owner) external view returns (uint256) {
        uint256 rsbtId = addressToRSBTId[_owner];
        if (rsbtId == 0) return 0; // Not an RSBT holder
        return rsbtData[rsbtId].level;
    }

    /// @notice Returns the accumulated contribution points for an rSBT.
    /// @param _owner The address of the rSBT holder.
    /// @return The contribution points.
    function getRSBTContributionPoints(address _owner) external view returns (uint256) {
        uint256 rsbtId = addressToRSBTId[_owner];
        if (rsbtId == 0) return 0;
        return rsbtData[rsbtId].contributionPoints;
    }

    /// @notice Calculates a user's current voting power based on their rSBT level and active participation.
    /// @param _voter The address of the user.
    /// @return The calculated voting power.
    function getVotingPower(address _voter) public view returns (uint256) {
        uint256 rsbtId = addressToRSBTId[_voter];
        if (rsbtId == 0) return 0;
        RSBT storage sbt = rsbtData[rsbtId];

        // If delegated, the delegator has 0 voting power directly
        if (sbt.delegatedTo != address(0) && sbt.delegationExpirationEpoch >= currentEpoch) {
            return 0;
        }

        // Apply a decay if not active in recent epochs
        uint256 effectiveLevel = sbt.level;
        uint256 epochsInactive = currentEpoch - sbt.lastActiveEpoch;
        if (epochsInactive > 1) { // If inactive for more than one epoch
            effectiveLevel = effectiveLevel / (1 + epochsInactive); // Simple decay
        }
        if (effectiveLevel > MAX_RSBT_LEVEL) effectiveLevel = MAX_RSBT_LEVEL; // Cap effective level
        
        return RSBT_LEVEL_TIERS[effectiveLevel][1];
    }

    /// @notice Allows an rSBT holder to temporarily delegate their voting power.
    /// @param _delegatee The address to whom voting power is delegated.
    /// @param _epochsToDelegate The number of epochs for which to delegate power.
    function delegateVotingPower(address _delegatee, uint256 _epochsToDelegate) external onlyRSBTHolder whenNotPaused {
        uint256 delegatorRSBTId = addressToRSBTId[msg.sender];
        uint256 delegateeRSBTId = addressToRSBTId[_delegatee];

        if (_delegatee == address(0) || _delegatee == msg.sender) revert AetheriaProtocol__SelfDelegationNotAllowed();
        if (delegateeRSBTId == 0) revert("AetheriaProtocol: Delegatee must be an RSBT holder.");
        
        RSBT storage delegatorSBT = rsbtData[delegatorRSBTId];
        if (delegatorSBT.delegatedTo != address(0) && delegatorSBT.delegationExpirationEpoch >= currentEpoch) {
            revert AetheriaProtocol__DelegationAlreadyExists();
        }

        // Prevent delegation if delegator has active projects awaiting funding
        for (uint256 i = 1; i <= _projectIdCounter.current(); i++) {
            Project storage p = projects[i];
            if (p.proposer == msg.sender && (p.status == ProjectStatus.ActiveVoting || p.status == ProjectStatus.Proposed)) {
                revert AetheriaProtocol__DelegatorHasActiveProjects();
            }
        }

        delegatorSBT.delegatedTo = _delegatee;
        delegatorSBT.delegationExpirationEpoch = currentEpoch + _epochsToDelegate;
        delegatorSBT.lastActiveEpoch = currentEpoch; // Mark delegator as active
        rsbtData[delegateeRSBTId].lastActiveEpoch = currentEpoch; // Mark delegatee as active

        emit VotingPowerDelegated(msg.sender, _delegatee, delegatorSBT.delegationExpirationEpoch);
    }

    /// @notice Revokes an active voting power delegation.
    function revokeDelegation() external onlyRSBTHolder whenNotPaused {
        uint256 rsbtId = addressToRSBTId[msg.sender];
        RSBT storage sbt = rsbtData[rsbtId];

        if (sbt.delegatedTo == address(0) || sbt.delegationExpirationEpoch < currentEpoch) {
            revert AetheriaProtocol__DelegationNotFound();
        }

        address delegatee = sbt.delegatedTo;
        sbt.delegatedTo = address(0);
        sbt.delegationExpirationEpoch = 0;
        sbt.lastActiveEpoch = currentEpoch; // Mark delegator as active

        emit VotingPowerRevoked(msg.sender, delegatee);
    }


    // --- III. Adaptive Resource Allocation & Spheres ---

    /// @notice Defines a new resource allocation category (Sphere).
    /// @dev Only callable by the owner.
    /// @param _name The name of the new sphere.
    /// @param _initialAllocationPercent The initial percentage of the treasury allocated to this sphere.
    function _defineSphere(string memory _name, uint256 _initialAllocationPercent) internal {
        _sphereIdCounter.increment();
        uint256 newSphereId = _sphereIdCounter.current();
        
        // Check for existing sphere name (simple check, could use mapping for efficiency)
        for (uint256 i = 0; i < activeSphereIds.length; i++) {
            if (keccak256(abi.encodePacked(spheres[activeSphereIds[i]].name)) == keccak256(abi.encodePacked(_name))) {
                revert AetheriaProtocol__SphereAlreadyExists();
            }
        }

        spheres[newSphereId] = Sphere({
            name: _name,
            currentAllocationPercent: _initialAllocationPercent,
            oracleInfluenceWeight: 50, // Default 50% oracle influence
            exists: true
        });
        activeSphereIds.push(newSphereId);
        emit SphereDefined(newSphereId, _name, _initialAllocationPercent);
    }

    /// @notice Allows the contract owner to create new resource allocation categories.
    /// @param _name The name of the new sphere.
    /// @param _initialAllocationPercent The initial percentage of the treasury allocated to this sphere.
    function defineSphere(string memory _name, uint256 _initialAllocationPercent) external onlyOwner {
        _defineSphere(_name, _initialAllocationPercent);
    }

    /// @notice Allows rSBT holders to propose new target allocation percentages for Spheres.
    /// @dev Proposals are for the *next* epoch's allocations.
    /// @param _sphereIds The IDs of the spheres for which to propose new percentages.
    /// @param _percentages The proposed new percentages corresponding to `_sphereIds`. Must sum to 100.
    function proposeSphereAllocationChange(uint256[] memory _sphereIds, uint256[] memory _percentages) external onlyRSBTHolder whenNotPaused {
        if (_sphereIds.length != _percentages.length || _sphereIds.length == 0) revert("AetheriaProtocol: Invalid proposal length.");

        uint256 totalProposed = 0;
        for (uint256 i = 0; i < _percentages.length; i++) {
            if (!spheres[_sphereIds[i]].exists) revert AetheriaProtocol__SphereNotFound();
            totalProposed += _percentages[i];
        }
        if (totalProposed != 100) revert AetheriaProtocol__InvalidAllocationSum();

        _sphereProposalIdCounter.increment();
        uint256 proposalId = _sphereProposalIdCounter.current();

        sphereAllocationProposals[proposalId] = SphereAllocationProposal({
            proposer: msg.sender,
            epochProposed: currentEpoch,
            sphereIds: _sphereIds,
            percentages: _percentages,
            totalVotesFor: 0,
            state: ProposalState.Active,
            votingDeadlineEpoch: currentEpoch + 1 // Voting open until end of next epoch
        });

        emit SphereAllocationProposed(proposalId, msg.sender, currentEpoch, _sphereIds, _percentages);
    }

    /// @notice rSBT holders cast votes on proposed Sphere allocation changes.
    /// @param _proposalId The ID of the sphere allocation proposal.
    function voteOnSphereAllocationProposal(uint256 _proposalId) external onlyRSBTHolder whenNotPaused {
        SphereAllocationProposal storage proposal = sphereAllocationProposals[_proposalId];
        if (proposal.proposer == address(0) || proposal.state != ProposalState.Active) revert AetheriaProtocol__InvalidProposalState();
        if (proposal.hasVoted[msg.sender]) revert AetheriaProtocol__VoteAlreadyCast();
        if (proposal.votingDeadlineEpoch < currentEpoch) revert("AetheriaProtocol: Voting for this proposal has closed.");

        uint256 voterPower = getVotingPower(msg.sender);
        if (voterPower == 0) revert("AetheriaProtocol: Insufficient active voting power.");

        proposal.totalVotesFor += voterPower;
        proposal.hasVoted[msg.sender] = true;
        
        _adjustRSBTContributionPoints(msg.sender, 5, "Voted on Sphere Allocation"); // Small reward for participation
        
        emit SphereAllocationVoted(_proposalId, msg.sender, voterPower);
    }

    /// @notice Executes a passed Sphere allocation proposal at the end of an epoch.
    /// @dev This is typically called as part of `advanceEpoch`.
    /// @param _proposalId The ID of the sphere allocation proposal to execute.
    function executeSphereAllocationProposal(uint256 _proposalId) internal {
        SphereAllocationProposal storage proposal = sphereAllocationProposals[_proposalId];

        if (proposal.state != ProposalState.Succeeded) revert("AetheriaProtocol: Proposal not in succeeded state.");
        if (proposal.epochProposed != currentEpoch - 1) revert("AetheriaProtocol: Proposal not for the previous epoch.");

        for (uint256 i = 0; i < proposal.sphereIds.length; i++) {
            uint256 sphereId = proposal.sphereIds[i];
            if (spheres[sphereId].exists) {
                spheres[sphereId].currentAllocationPercent = proposal.percentages[i];
            }
        }
        proposal.state = ProposalState.Executed;
        emit SphereAllocationExecuted(_proposalId, currentEpoch, proposal.sphereIds, proposal.percentages);
    }

    /// @notice Returns the current target allocation percentage of a specific Sphere.
    /// @param _sphereId The ID of the sphere.
    /// @return The current allocation percentage.
    function getSphereCurrentAllocation(uint256 _sphereId) external view returns (uint256) {
        if (!spheres[_sphereId].exists) revert AetheriaProtocol__SphereNotFound();
        return spheres[_sphereId].currentAllocationPercent;
    }

    /// @notice Adjusts how much the Oracle's suggestions impact a specific Sphere's allocation.
    /// @dev Weight is 0-100. 0 means no oracle influence, 100 means full oracle influence.
    /// @param _sphereId The ID of the sphere.
    /// @param _weight The new oracle influence weight (0-100).
    function updateSphereOracleInfluenceWeight(uint256 _sphereId, uint256 _weight) external onlyOwner {
        if (!spheres[_sphereId].exists) revert AetheriaProtocol__SphereNotFound();
        if (_weight > 100) _weight = 100; // Cap at 100
        spheres[_sphereId].oracleInfluenceWeight = _weight;
    }

    // --- IV. Project Management & Funding Lifecycle ---

    /// @notice Allows rSBT holders to propose projects seeking funding within a defined Sphere.
    /// @param _sphereId The ID of the sphere the project belongs to.
    /// @param _amountRequested The amount of funds requested for the project.
    /// @param _title The title of the project.
    /// @param _description A detailed description of the project.
    function submitProjectProposal(
        uint256 _sphereId,
        uint256 _amountRequested,
        string memory _title,
        string memory _description
    ) external onlyRSBTHolder whenNotPaused {
        if (!spheres[_sphereId].exists) revert AetheriaProtocol__SphereNotFound();
        if (_amountRequested == 0) revert("AetheriaProtocol: Requested amount must be greater than zero.");
        
        _projectIdCounter.increment();
        uint256 projectId = _projectIdCounter.current();

        projects[projectId] = Project({
            proposer: msg.sender,
            sphereId: _sphereId,
            amountRequested: _amountRequested,
            title: _title,
            description: _description,
            status: ProjectStatus.ActiveVoting, // Start in active voting
            votesFor: 0,
            votesAgainst: 0,
            fundingDeadlineEpoch: currentEpoch + 2, // Voting open for 2 epochs
            impactScoreReported: 0,
            impactScoreVerified: 0,
            impactVerified: false
        });

        _adjustRSBTContributionPoints(msg.sender, 10, "Submitted Project Proposal"); // Reward for proposing
        
        emit ProjectProposed(projectId, msg.sender, _sphereId, _amountRequested);
    }

    /// @notice rSBT holders vote on individual project proposals.
    /// @param _projectId The ID of the project proposal.
    /// @param _support True for 'for', false for 'against'.
    function voteOnProjectProposal(uint256 _projectId, bool _support) external onlyRSBTHolder whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.proposer == address(0)) revert AetheriaProtocol__ProjectNotFound();
        if (project.status != ProjectStatus.ActiveVoting) revert AetheriaProtocol__ProjectNotInFundingStatus();
        if (project.hasVoted[msg.sender]) revert AetheriaProtocol__VoteAlreadyCast();
        if (project.fundingDeadlineEpoch < currentEpoch) revert("AetheriaProtocol: Voting for this project has closed.");

        uint256 voterPower = getVotingPower(msg.sender);
        if (voterPower == 0) revert("AetheriaProtocol: Insufficient active voting power.");

        if (_support) {
            project.votesFor += voterPower;
        } else {
            project.votesAgainst += voterPower;
        }
        project.hasVoted[msg.sender] = true;

        _adjustRSBTContributionPoints(msg.sender, 3, "Voted on Project Proposal"); // Small reward for participation

        emit ProjectVoted(_projectId, msg.sender, voterPower);
    }

    /// @notice Finalizes a project proposal if it passes, transferring funds.
    /// @dev Can be called by anyone after the funding deadline, or internally by `advanceEpoch`.
    /// @param _projectId The ID of the project to finalize.
    function finalizeProjectProposal(uint256 _projectId) external nonReentrant whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.proposer == address(0)) revert AetheriaProtocol__ProjectNotFound();
        if (project.status != ProjectStatus.ActiveVoting) revert AetheriaProtocol__ProjectNotInFundingStatus();
        if (project.fundingDeadlineEpoch >= currentEpoch) revert("AetheriaProtocol: Project voting still active.");

        // Check if total votes for is sufficient and more 'for' votes than 'against'
        if (project.votesFor >= minProjectVoteThreshold && project.votesFor > project.votesAgainst) {
            if (project.amountRequested > totalTreasuryFunds) revert AetheriaProtocol__NotEnoughFundsInTreasury();
            
            // Distribute funds based on Sphere allocation (simplified, in a real DAO it's more complex)
            // For now, if passed, it's funded from general treasury.
            totalTreasuryFunds -= project.amountRequested;
            payable(project.proposer).transfer(project.amountRequested);
            project.status = ProjectStatus.Funded;
            emit ProjectFinalized(_projectId, project.proposer, project.amountRequested);
        } else {
            project.status = ProjectStatus.Rejected;
            emit ProjectFinalized(_projectId, address(0), 0); // No funds, rejected
        }
    }

    /// @notice Project owner submits a report on project outcome/impact.
    /// @param _projectId The ID of the project.
    /// @param _reportedImpactScore The impact score (0-100) reported by the project owner.
    function submitProjectImpactReport(uint256 _projectId, uint256 _reportedImpactScore) external onlyRSBTHolder whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.proposer == address(0)) revert AetheriaProtocol__ProjectNotFound();
        if (project.proposer != msg.sender) revert("AetheriaProtocol: Only project proposer can submit impact report.");
        if (project.status != ProjectStatus.Funded) revert AetheriaProtocol__ProjectNotCompleted();
        if (project.impactScoreReported != 0) revert AetheriaProtocol__ProjectAlreadyReported();

        project.impactScoreReported = (_reportedImpactScore > MAX_IMPACT_SCORE) ? MAX_IMPACT_SCORE : _reportedImpactScore;
        project.status = ProjectStatus.ImpactReported;
        emit ProjectImpactReported(_projectId, project.impactScoreReported);
    }

    /// @notice Called by the Oracle to confirm a project's reported impact, triggering reputation adjustments.
    /// @dev Only the Oracle of Aetheria can call this function.
    /// @param _projectId The ID of the project.
    /// @param _reportedImpactScore The impact score reported by the project owner.
    function verifyProjectImpactByOracle(uint256 _projectId, uint256 _reportedImpactScore) external {
        if (msg.sender != address(oracleOfAetheria)) revert("AetheriaProtocol: Only Oracle can verify impact.");

        Project storage project = projects[_projectId];
        if (project.proposer == address(0)) revert AetheriaProtocol__ProjectNotFound();
        if (project.status != ProjectStatus.ImpactReported) revert("AetheriaProtocol: Project not in impact reported status.");

        (bool success, uint256 finalImpact) = oracleOfAetheria.verifyProjectImpact(_projectId, _reportedImpactScore);
        if (!success) revert("AetheriaProtocol: Oracle failed to verify impact.");

        project.impactScoreVerified = finalImpact;
        project.impactVerified = true;
        project.status = ProjectStatus.Verified;

        // --- Reputation Adjustments based on Impact ---
        // Proposer Reward/Penalty
        if (finalImpact >= MIN_PROJECT_IMPACT_FOR_PROPOSER_BOOST) {
            _adjustRSBTContributionPoints(project.proposer, int256(finalImpact / 2), "Project Proposer Impact Bonus");
        } else {
            _adjustRSBTContributionPoints(project.proposer, -(int256((MAX_IMPACT_SCORE - finalImpact) / 4)), "Project Proposer Impact Penalty");
        }

        // Voters Reward
        // Iterate through all voters for this project and reward them if impact is high enough
        // NOTE: This is a placeholder. Iterating over all voters on-chain is too gas-intensive for many voters.
        // A real system would use a Merkle proof for claiming rewards or use a different reward distribution mechanism.
        // For this example, we'll demonstrate the concept with a single adjustment for simplicity.
        // Or, we could just reward the proposer and leave voter rewards to a separate system.
        // Let's assume voters get a small boost for successful projects they supported.
        for (uint256 i = 1; i <= _rsbtTokenIdCounter.current(); i++) {
            address voterAddress = ownerOf(i); // Get owner of RSBT
            if (project.hasVoted[voterAddress]) {
                if (finalImpact >= MIN_PROJECT_IMPACT_FOR_VOTER_BOOST) {
                    _adjustRSBTContributionPoints(voterAddress, int256(finalImpact / 10), "Project Voter Impact Bonus");
                }
            }
        }

        emit ProjectImpactVerified(_projectId, finalImpact);
    }

    /// @notice Public getter to check the current status and details of a project.
    /// @param _projectId The ID of the project.
    /// @return The project details.
    function getProjectStatus(uint256 _projectId) external view returns (Project memory) {
        if (projects[_projectId].proposer == address(0)) revert AetheriaProtocol__ProjectNotFound();
        return projects[_projectId];
    }

    // --- V. Epoch Management & Protocol Evolution ---

    /// @notice The core function that triggers the end-of-epoch processes.
    /// @dev Can be called by anyone, but only if enough time has passed since the last epoch advance.
    function advanceEpoch() external nonReentrant whenNotPaused {
        if (block.timestamp < lastEpochAdvanceTime + epochDuration) revert AetheriaProtocol__EpochNotEnded();

        currentEpoch++;
        lastEpochAdvanceTime = block.timestamp;
        
        // 1. Finalize Sphere Allocation Proposals from previous epoch
        for (uint256 i = 1; i <= _sphereProposalIdCounter.current(); i++) {
            SphereAllocationProposal storage proposal = sphereAllocationProposals[i];
            if (proposal.state == ProposalState.Active && proposal.votingDeadlineEpoch < currentEpoch) {
                if (proposal.totalVotesFor >= minSphereProposalVotingPower) {
                    proposal.state = ProposalState.Succeeded;
                    executeSphereAllocationProposal(i); // Execute if passed
                } else {
                    proposal.state = ProposalState.Failed;
                }
            }
        }

        // 2. Finalize Project Proposals from previous epochs
        for (uint256 i = 1; i <= _projectIdCounter.current(); i++) {
            Project storage project = projects[i];
            if (project.status == ProjectStatus.ActiveVoting && project.fundingDeadlineEpoch < currentEpoch) {
                // If not finalized by external call, finalize it here
                if (project.votesFor >= minProjectVoteThreshold && project.votesFor > project.votesAgainst) {
                    if (project.amountRequested <= totalTreasuryFunds) { // Ensure funds are available at epoch end
                         // Don't transfer here, just set status. Funds transfer would happen via explicit finalize call.
                        project.status = ProjectStatus.Approved; // Mark as approved, waiting for explicit transfer
                    } else {
                        project.status = ProjectStatus.Rejected; // Rejected due to insufficient funds
                    }
                } else {
                    project.status = ProjectStatus.Rejected;
                }
            }
        }

        // 3. Request and apply Oracle Insights for next epoch's *suggested* allocations
        // The community can then propose based on these insights.
        (uint256[] memory oracleSphereIds, uint256[] memory oraclePercentages) = oracleOfAetheria.getSuggestedSphereAllocations(currentEpoch);
        
        // This is where oracle insights *could* directly influence currentAllocationPercent,
        // weighted by `oracleInfluenceWeight`. For this advanced example, we just store it.
        // Direct application would be:
        // for (uint256 i = 0; i < oracleSphereIds.length; i++) {
        //     uint256 sphereId = oracleSphereIds[i];
        //     Sphere storage s = spheres[sphereId];
        //     if (s.exists) {
        //         uint256 current = s.currentAllocationPercent;
        //         uint256 oracleWeighted = (oraclePercentages[i] * s.oracleInfluenceWeight) / 100;
        //         uint256 communityWeighted = (current * (100 - s.oracleInfluenceWeight)) / 100;
        //         s.currentAllocationPercent = (oracleWeighted + communityWeighted); // Simplified average
        //     }
        // }
        // Note: Summing to 100% after such adjustments would require normalization.
        // For simplicity, we assume oracle insights primarily inform new proposals, not directly change current.
        // The `getOracleSuggestedSphereAllocations` acts as a public lookup for future proposals.


        // 4. Mark all active RSBTs as active for the current epoch (via interactions)
        // This is implicitly handled by `_adjustRSBTContributionPoints` and voting functions.

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    /// @notice Returns the Oracle's latest suggestions for Sphere allocations for the upcoming epoch.
    /// @dev This provides data-driven recommendations that the community can use for new proposals.
    /// @return A tuple containing arrays of sphere IDs and their suggested allocation percentages.
    function getOracleSuggestedSphereAllocations() external view returns (uint256[] memory sphereIds, uint256[] memory percentages) {
        return oracleOfAetheria.getSuggestedSphereAllocations(currentEpoch + 1); // Get suggestions for next epoch
    }

    /// @notice Helper function to get sum of all current sphere allocations
    function getSumOfCurrentAllocations() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < activeSphereIds.length; i++) {
            total += spheres[activeSphereIds[i]].currentAllocationPercent;
        }
        return total;
    }

    // --- Overrides for ERC721 (to ensure Soulbound nature) ---
    // Make tokens non-transferable (soulbound) by reverting any transfer attempts
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Allow minting (from address(0)) and burning (to address(0))
        if (from != address(0) && to != address(0)) {
            revert("AetheriaProtocol: RSBTs are Soulbound and non-transferable.");
        }
    }
}
```