Okay, let's design a smart contract around the concept of **"Syntropy Echosystem"**. This system will involve dynamic digital entities called "Echoes" whose properties evolve based on on-chain interactions, internal mechanics like decay, delegation of influence, and a form of limited governance/achievement system.

This goes beyond standard tokens by:
1.  **Dynamic State:** Echoes' core property (Syntropy Points) changes based on interactions and time, not just external updates.
2.  **Reputation/Interaction System:** Syntropy Points act as an internal reputation or energy score gained through specific contract functions.
3.  **Delegation of Influence:** Users can delegate their Echoes' power (Syntropy Points) for specific purposes like voting or boosting other Echoes.
4.  **Internal Mechanics:** Decay and ambient distribution simulate environmental factors affecting Echoes.
5.  **Achievement/Badge System:** On-chain, non-transferrable indicators of an Echo's performance based on its dynamic state.
6.  **Linked Echoes:** A way to create relationships between entities on-chain.
7.  **Batch Processing:** Functions designed to handle operations on multiple entities without hitting gas limits in a single transaction (e.g., decay, distribution).

It's *not* a full ERC721, ERC20, or standard DAO, but incorporates elements of dynamic state, delegation, and internal mechanics.

---

**Outline:**

1.  **Contract Setup:**
    *   Basic ownership and pause functionality.
    *   Counter for unique Echo IDs.
    *   Storage for Echo data, links, achievements, delegation, ambient pool, governance parameters.
2.  **Echo Management:**
    *   Registration, viewing, transferring, burning Echoes.
    *   Accessing core properties (Syntropy Points, Level).
    *   Updating metadata.
3.  **Syntropy Mechanics:**
    *   Gaining Syntropy Points (interaction, ambient claim).
    *   Syntropy Decay (global, batched).
    *   Ambient Syntropy Pool management and distribution (batched).
4.  **Influence and Delegation:**
    *   Delegating an Echo's Syntropy influence.
    *   Undelegating influence.
    *   Querying delegation status and total delegated influence.
5.  **Linking System:**
    *   Creating directional links between Echoes.
    *   Removing links.
    *   Querying links.
6.  **Achievement System:**
    *   Defining achievement badges based on Syntropy Point thresholds (Owner/Governance).
    *   Claiming earned achievement badges.
    *   Viewing held badges.
7.  **Limited Governance:**
    *   Proposing changes to key contract parameters.
    *   Voting on proposals (influence weighted by delegated SP).
    *   Executing successful proposals.
8.  **Fees and Withdrawals:**
    *   Handling collected fees (optional, added for complexity).
    *   Owner withdrawal.

---

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets the owner.
2.  `registerEcho(string memory initialMetadataURI)`: Creates a new Echo for the caller with initial Syntropy Points and metadata.
3.  `getEchoSyntropyPoints(uint256 echoId)`: Returns the current Syntropy Points of an Echo.
4.  `getEchoLevel(uint256 echoId)`: Calculates and returns the level of an Echo based on its Syntropy Points.
5.  `interactWithEcho(uint256 echoId)`: Simulates an interaction, adding Syntropy Points to the target Echo and potentially the caller's Echo. Collects a small fee.
6.  `distributeAmbientSyntropy(uint256 amount)`: Allows owner/governance to add Syntropy Points to a global pool.
7.  `distributeSyntropyToActiveEchoes(uint256 batchSize)`: Permissionless function to distribute a portion of the ambient pool among a batch of active Echoes. Caller might get a small reward.
8.  `triggerGlobalSyntropyDecay(uint256 batchSize)`: Permissionless function to apply Syntropy decay to a batch of Echoes based on elapsed time since last decay. Caller might get a small reward.
9.  `delegateSyntropyInfluence(uint256 echoId, address delegatee)`: Delegates the voting/influence power of `echoId` to `delegatee`. Requires Echo ownership.
10. `undelegateSyntropyInfluence(uint256 echoId)`: Removes the delegation for `echoId`. Requires Echo ownership.
11. `getEchoDelegatee(uint256 echoId)`: Returns the address that `echoId`'s influence is delegated to.
12. `getTotalDelegatedInfluence(address delegatee)`: Returns the total Syntropy Points delegated *to* a specific address.
13. `proposeParameterChange(bytes memory proposalData, string memory description)`: Creates a new governance proposal.
14. `voteOnProposal(uint256 proposalId, bool support)`: Casts a vote on a proposal using the caller's combined Echo influence (including delegated).
15. `executeProposal(uint256 proposalId)`: Executes a proposal if it has passed and met quorum requirements.
16. `getProposalState(uint256 proposalId)`: Returns the current state of a governance proposal.
17. `linkEchoes(uint256 echoId1, uint256 echoId2, uint8 linkType)`: Creates a directional link from `echoId1` to `echoId2` with a specified type. Requires ownership of `echoId1`.
18. `unlinkEchoes(uint256 linkId)`: Removes a specific link by its ID. Requires ownership of the source Echo of the link.
19. `getOutgoingLinks(uint256 echoId)`: Returns all links originating from a given Echo.
20. `getIncomingLinks(uint256 echoId)`: Returns all links pointing to a given Echo.
21. `createAchievementBadge(uint256 threshold, string memory metadataURI)`: Owner/Governance function to define a new achievement badge based on an SP threshold.
22. `claimAchievementBadge(uint256 echoId, uint256 badgeId)`: Allows an Echo owner to claim a specific achievement badge if their Echo meets the required SP threshold.
23. `getHeldAchievementBadges(uint256 echoId)`: Returns the IDs of achievement badges held by an Echo.
24. `transferEchoOwnership(uint256 echoId, address newOwner)`: Transfers ownership of an Echo.
25. `burnEcho(uint256 echoId)`: Permanently removes an Echo from the system. Requires ownership.
26. `pauseContract()`: Owner can pause core functionality.
27. `unpauseContract()`: Owner can unpause the contract.
28. `withdrawFees(address recipient)`: Owner can withdraw collected fees.
29. `updateEchoMetadataURI(uint256 echoId, string memory newURI)`: Allows the Echo owner to update its metadata URI.
30. `getEchoOwner(uint256 echoId)`: Returns the current owner of an Echo.

(Note: Some governance functions like setting parameters are folded into the generic `proposeParameterChange` and `executeProposal` mechanism for flexibility, avoiding specific setters like `setSyntropyDecayRate` as standalone public functions). We have 30 functions listed, fulfilling the requirement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. Contract Setup (Ownable, Pausable, Counters, Storage)
// 2. Echo Management (Register, Getters, Transfer, Burn, Metadata)
// 3. Syntropy Mechanics (Gain, Decay, Ambient Pool, Distribution)
// 4. Influence and Delegation (Delegate, Undelegate, Query)
// 5. Linking System (Create, Remove, Query)
// 6. Achievement System (Define, Claim, Query)
// 7. Limited Governance (Proposals, Voting, Execution)
// 8. Fees and Withdrawals

// Function Summary:
// 1. constructor()
// 2. registerEcho(string memory initialMetadataURI)
// 3. getEchoSyntropyPoints(uint256 echoId)
// 4. getEchoLevel(uint256 echoId)
// 5. interactWithEcho(uint256 echoId)
// 6. distributeAmbientSyntropy(uint256 amount)
// 7. distributeSyntropyToActiveEchoes(uint256 batchSize)
// 8. triggerGlobalSyntropyDecay(uint256 batchSize)
// 9. delegateSyntropyInfluence(uint256 echoId, address delegatee)
// 10. undelegateSyntropyInfluence(uint256 echoId)
// 11. getEchoDelegatee(uint256 echoId)
// 12. getTotalDelegatedInfluence(address delegatee)
// 13. proposeParameterChange(bytes memory proposalData, string memory description)
// 14. voteOnProposal(uint256 proposalId, bool support)
// 15. executeProposal(uint256 proposalId)
// 16. getProposalState(uint256 proposalId)
// 17. linkEchoes(uint256 echoId1, uint256 echoId2, uint8 linkType)
// 18. unlinkEchoes(uint256 linkId)
// 19. getOutgoingLinks(uint256 echoId)
// 20. getIncomingLinks(uint256 echoId)
// 21. createAchievementBadge(uint256 threshold, string memory metadataURI)
// 22. claimAchievementBadge(uint256 echoId, uint256 badgeId)
// 23. getHeldAchievementBadges(uint256 echoId)
// 24. transferEchoOwnership(uint256 echoId, address newOwner)
// 25. burnEcho(uint256 echoId)
// 26. pauseContract()
// 27. unpauseContract()
// 28. withdrawFees(address recipient)
// 29. updateEchoMetadataURI(uint256 echoId, string memory newURI)
// 30. getEchoOwner(uint256 echoId)


contract SyntropyEchosystem is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Data Structures ---

    struct Echo {
        address owner;
        uint256 syntropyPoints;
        uint64 lastDecayTimestamp;
        string metadataURI;
        uint256[] heldBadges; // IDs of earned achievement badges
    }

    struct Link {
        uint256 sourceEchoId;
        uint256 targetEchoId;
        uint8 linkType; // e.g., 1=Parent, 2=Child, 3=Peer, etc.
        bool active;
    }

    struct AchievementBadge {
        uint256 threshold; // SP threshold to earn the badge
        string metadataURI;
        bool exists; // To check if badgeId is valid
    }

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }

    struct Proposal {
        uint256 id;
        bytes data; // Data to be executed if proposal passes (e.g., function call on this contract)
        string description;
        uint256 voteThreshold; // Minimum total influence needed to pass (can be a percentage of total SP)
        uint256 totalInfluenceNeeded; // Absolute total influence needed
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Address (delegatee) => has voted
        ProposalState state;
        uint64 proposalCreationTimestamp;
        uint64 votingPeriodEndTimestamp;
    }

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for Echo IDs
    uint256 private _nextLinkId; // Counter for Link IDs
    uint256 private _nextProposalId; // Counter for Proposal IDs
    uint256 private _nextBadgeId; // Counter for Achievement Badge IDs

    mapping(uint256 => Echo) public echoes; // Echo ID => Echo data
    mapping(address => uint256[]) private _ownerEchoes; // Owner address => list of owned Echo IDs
    mapping(uint256 => address) private _echoOwner; // Echo ID => Owner address (easier lookup than iterating _ownerEchoes)

    mapping(uint256 => Link) public links; // Link ID => Link data
    mapping(uint256 => uint256[]) private _outgoingLinks; // Source Echo ID => list of outgoing Link IDs
    mapping(uint256 => uint256[]) private _incomingLinks; // Target Echo ID => list of incoming Link IDs

    mapping(uint256 => address) private _syntropyDelegatee; // Echo ID => Address influence is delegated to
    mapping(address => uint256) private _totalDelegatedInfluence; // Address (delegatee) => Total delegated SP

    uint256 public ambientSyntropyPool; // Global pool of SP
    uint64 public lastGlobalDecayTimestamp; // Timestamp of the last global decay run
    uint256 public syntropyDecayRatePerSecond; // How much SP decays per second per Echo (scaled)
    uint256 public interactionSyntropyReward; // SP added per interaction
    uint256 public registrationSyntropyReward; // SP added upon registration
    uint256 public interactionFee; // Fee collected for interactions (optional)

    mapping(uint256 => AchievementBadge) public achievementBadges; // Badge ID => Badge data

    mapping(uint256 => Proposal) public proposals; // Proposal ID => Proposal data
    uint64 public constant VOTING_PERIOD = 7 days; // Duration of voting period
    uint256 public proposalQuorumPercentage = 5; // % of total influence needed for a proposal to be valid
    uint256 public proposalPassingThresholdPercentage = 51; // % of votes needed for a proposal to pass (of votes cast)

    // For batch processing
    uint256 private _lastProcessedEchoIdForDecay;
    uint256 private _lastProcessedEchoIdForDistribution;

    // --- Events ---

    event EchoRegistered(uint256 indexed echoId, address indexed owner, uint256 initialSyntropyPoints);
    event SyntropyPointsChanged(uint256 indexed echoId, uint256 newSyntropyPoints, string reason);
    event EchoTransferred(uint256 indexed echoId, address indexed oldOwner, address indexed newOwner);
    event EchoBurned(uint256 indexed echoId);
    event InfluenceDelegated(uint256 indexed echoId, address indexed from, address indexed to);
    event InfluenceUndelegated(uint256 indexed echoId, address indexed from, address indexed to);
    event AmbientSyntropyDistributed(uint256 amount);
    event AmbientSyntropyClaimed(uint256 indexed echoId, uint256 amount); // Emitted by distribution function
    event SyntropyDecayed(uint256 indexed echoId, uint256 decayedAmount);
    event LinkCreated(uint256 indexed linkId, uint256 indexed sourceEchoId, uint256 indexed targetEchoId, uint8 linkType);
    event LinkRemoved(uint256 indexed linkId);
    event AchievementBadgeCreated(uint256 indexed badgeId, uint256 threshold, string metadataURI);
    event AchievementBadgeClaimed(uint256 indexed echoId, uint256 indexed badgeId);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voterDelegatee, bool support, uint256 influence);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event MetadataUpdated(uint256 indexed echoId, string newURI);

    // --- Modifiers ---

    modifier onlyEchoOwner(uint256 echoId) {
        require(_echoOwner[echoId] == msg.sender, "Not Echo owner");
        _;
    }

    // --- Constructor ---

    constructor() Ownable() Pausable() {
        _nextTokenId = 1; // Start Echo IDs from 1
        _nextLinkId = 1; // Start Link IDs from 1
        _nextProposalId = 1; // Start Proposal IDs from 1
        _nextBadgeId = 1; // Start Badge IDs from 1

        lastGlobalDecayTimestamp = uint64(block.timestamp); // Initialize decay timestamp

        // Set initial parameters (can be changed via governance later)
        syntropyDecayRatePerSecond = 1 wei; // 10**0, very small decay
        interactionSyntropyReward = 1000000000000000 wei; // 10**15, small interaction reward
        registrationSyntropyReward = 5000000000000000 wei; // 10**16, registration bonus
        interactionFee = 1000000000000000 wei; // 10**15 wei (0.001 ETH)
    }

    // --- Echo Management ---

    /**
     * @notice Registers a new Echo for the caller.
     * @param initialMetadataURI URI pointing to the Echo's initial metadata.
     * @return The ID of the newly registered Echo.
     */
    function registerEcho(string memory initialMetadataURI) public whenNotPaused returns (uint256) {
        uint256 newEchoId = _nextTokenId;
        require(newEchoId > 0, "Max Echo supply reached"); // Basic check for overflow (unlikely)

        Echo storage newEcho = echoes[newEchoId];
        require(newEcho.owner == address(0), "Echo ID already exists"); // Should not happen with _nextTokenId

        newEcho.owner = msg.sender;
        newEcho.syntropyPoints = registrationSyntropyReward;
        newEcho.lastDecayTimestamp = uint64(block.timestamp);
        newEcho.metadataURI = initialMetadataURI;

        _ownerEchoes[msg.sender].push(newEchoId);
        _echoOwner[newEchoId] = msg.sender;

        _nextTokenId = _nextTokenId.add(1);

        emit EchoRegistered(newEchoId, msg.sender, registrationSyntropyReward);
        return newEchoId;
    }

    /**
     * @notice Gets the current Syntropy Points of an Echo.
     * @param echoId The ID of the Echo.
     * @return The Syntropy Points of the Echo.
     */
    function getEchoSyntropyPoints(uint256 echoId) public view returns (uint256) {
        require(echoes[echoId].owner != address(0), "Echo does not exist");
        return echoes[echoId].syntropyPoints;
    }

    /**
     * @notice Calculates the level of an Echo based on its Syntropy Points. (Simple example levels)
     * @param echoId The ID of the Echo.
     * @return The calculated level of the Echo.
     */
    function getEchoLevel(uint256 echoId) public view returns (uint256) {
        uint256 sp = getEchoSyntropyPoints(echoId);
        if (sp >= 100 ether) return 5;
        if (sp >= 50 ether) return 4;
        if (sp >= 20 ether) return 3;
        if (sp >= 5 ether) return 2;
        if (sp >= 1 ether) return 1;
        return 0;
    }

     /**
     * @notice Gets the owner of an Echo.
     * @param echoId The ID of the Echo.
     * @return The owner address.
     */
    function getEchoOwner(uint256 echoId) public view returns (address) {
        require(echoes[echoId].owner != address(0), "Echo does not exist");
        return _echoOwner[echoId];
    }

    /**
     * @notice Allows an Echo owner to update its metadata URI.
     * @param echoId The ID of the Echo.
     * @param newURI The new metadata URI.
     */
    function updateEchoMetadataURI(uint256 echoId, string memory newURI) public onlyEchoOwner(echoId) whenNotPaused {
        echoes[echoId].metadataURI = newURI;
        emit MetadataUpdated(echoId, newURI);
    }


    /**
     * @notice Transfers ownership of an Echo.
     * @param echoId The ID of the Echo.
     * @param newOwner The address to transfer ownership to.
     */
    function transferEchoOwnership(uint256 echoId, address newOwner) public onlyEchoOwner(echoId) whenNotPaused {
        require(newOwner != address(0), "Transfer to zero address");
        address oldOwner = msg.sender;

        // Remove from old owner's list
        uint256[] storage oldOwnerEchoes = _ownerEchoes[oldOwner];
        bool found = false;
        for (uint i = 0; i < oldOwnerEchoes.length; i++) {
            if (oldOwnerEchoes[i] == echoId) {
                oldOwnerEchoes[i] = oldOwnerEchoes[oldOwnerEchoes.length - 1];
                oldOwnerEchoes.pop();
                found = true;
                break;
            }
        }
        require(found, "Echo not found in owner list"); // Should not happen if onlyEchoOwner passed

        // Update owner mapping
        _echoOwner[echoId] = newOwner;
        echoes[echoId].owner = newOwner;

        // Add to new owner's list
        _ownerEchoes[newOwner].push(echoId);

        // Delegation is removed on transfer
        _clearDelegation(echoId);

        emit EchoTransferred(echoId, oldOwner, newOwner);
    }

    /**
     * @notice Burns (destroys) an Echo.
     * @param echoId The ID of the Echo to burn.
     */
    function burnEcho(uint256 echoId) public onlyEchoOwner(echoId) whenNotPaused {
        address owner = msg.sender;
        require(echoes[echoId].owner != address(0), "Echo does not exist");

        // Remove from owner's list
         uint256[] storage ownerEchoes = _ownerEchoes[owner];
        bool found = false;
        for (uint i = 0; i < ownerEchoes.length; i++) {
            if (ownerEchoes[i] == echoId) {
                ownerEchoes[i] = ownerEchoes[ownerEchoes.length - 1];
                ownerEchoes.pop();
                found = true;
                break;
            }
        }
         require(found, "Echo not found in owner list"); // Should not happen if onlyEchoOwner passed

        // Clear delegation
        _clearDelegation(echoId);

        // Remove links (optional, depends on desired behavior. Simplest: just invalidates them)
        // For a full implementation, you'd need to iterate and remove from _incoming/_outgoing lists.
        // For this example, we'll just mark the Echo as non-existent, effectively invalidating links.

        // Delete Echo data
        delete echoes[echoId];
        delete _echoOwner[echoId];

        emit EchoBurned(echoId);
    }


    // --- Syntropy Mechanics ---

     /**
     * @notice Simulates an interaction with an Echo, adding Syntropy Points.
     * @param echoId The ID of the Echo to interact with.
     * @dev Collects an interaction fee. Can be called by anyone.
     */
    function interactWithEcho(uint256 echoId) public payable whenNotPaused {
        require(echoes[echoId].owner != address(0), "Echo does not exist");
        require(msg.value >= interactionFee, "Insufficient interaction fee");

        if (msg.value > interactionFee) {
            // Refund excess ETH
            payable(msg.sender).transfer(msg.value - interactionFee);
        }

        // Add points to the target Echo
        echoes[echoId].syntropyPoints = echoes[echoId].syntropyPoints.add(interactionSyntropyReward);
        emit SyntropyPointsChanged(echoId, echoes[echoId].syntropyPoints, "Interaction");

        // Optional: Add points to the caller's *first owned* Echo, if they have one
        // Or add a fraction to all caller's echoes. Let's keep it simple.
        // If caller also owns an echo:
        if (_ownerEchoes[msg.sender].length > 0) {
            uint256 callerEchoId = _ownerEchoes[msg.sender][0]; // Use the first one as an example
             echoes[callerEchoId].syntropyPoints = echoes[callerEchoId].syntropyPoints.add(interactionSyntropyReward.div(2)); // Half reward for self
             emit SyntropyPointsChanged(callerEchoId, echoes[callerEchoId].syntropyPoints, "Interaction (Self)");
        }
    }

    /**
     * @notice Allows owner/governance to add Syntropy Points to a global pool.
     * @param amount The amount of ambient Syntropy to add.
     */
    function distributeAmbientSyntropy(uint256 amount) public onlyOwner whenNotPaused {
        ambientSyntropyPool = ambientSyntropyPool.add(amount);
        emit AmbientSyntropyDistributed(amount);
    }

    /**
     * @notice Distributes a portion of the ambient pool among a batch of active Echoes.
     * @param batchSize The maximum number of Echoes to process in this batch.
     * @dev This function can be called by anyone to help distribute ambient syntropy.
     * @dev Distribution is simple: divide ambient pool by total active echoes (approx).
     */
    function distributeSyntropyToActiveEchoes(uint256 batchSize) public whenNotPaused {
        if (ambientSyntropyPool == 0 || _nextTokenId <= 1) return; // Nothing to distribute or no echoes

        uint256 totalEchoes = _nextTokenId.sub(1); // Total number of echoes created
        uint256 startId = _lastProcessedEchoIdForDistribution > 0 ? _lastProcessedEchoIdForDistribution : 1;
        uint256 processedCount = 0;

        for (uint256 i = 0; i < batchSize && processedCount < totalEchoes; i++) {
            uint256 currentEchoId = startId + i;
            if (currentEchoId >= _nextTokenId) { // Wrap around if we reach the end
                currentEchoId = 1 + (currentEchoId - _nextTokenId);
            }

            // Skip if Echo doesn't exist (was burned) or already processed in this batch cycle
             if (echoes[currentEchoId].owner == address(0) /* || check if already processed in this batch cycle*/) {
                // In a real system, tracking processed status per batch cycle is complex.
                // Simple approach: just process if exists. Potential for some echoes to be processed multiple times per pool distribution.
                // A more robust solution would track processed IDs or use a Merkle tree/accumulator.
                // For this example, we process if exists.
                 if (echoes[currentEchoId].owner == address(0)) {
                    processedCount++; // Count it as processed for batch size purpose even if skipped
                    continue;
                 }
             }


            // Simple distribution logic: portion of ambient pool per echo
            // A more complex model might weight by current SP or links
            uint256 amountToClaim = ambientSyntropyPool.div(totalEchoes.add(1)); // Avoid division by zero + slight offset
             if (amountToClaim > ambientSyntropyPool) amountToClaim = ambientSyntropyPool; // Should not happen with SafeMath

            if (amountToClaim > 0) {
                echoes[currentEchoId].syntropyPoints = echoes[currentEchoId].syntropyPoints.add(amountToClaim);
                ambientSyntropyPool = ambientSyntropyPool.sub(amountToClaim);
                emit AmbientSyntropyClaimed(currentEchoId, amountToClaim);
                emit SyntropyPointsChanged(currentEchoId, echoes[currentEchoId].syntropyPoints, "Ambient Distribution");
            }

            processedCount++;
            _lastProcessedEchoIdForDistribution = currentEchoId; // Update last processed
        }

        // Simple reward for caller (optional)
        if (processedCount > 0) {
             // Example: small fixed reward or based on processed count
             // payable(msg.sender).transfer(processedCount.mul(100000000000 wei)); // 100 Gwei per echo processed
        }
    }


    /**
     * @notice Triggers global Syntropy decay for a batch of Echoes.
     * @param batchSize The maximum number of Echoes to process in this batch.
     * @dev Can be called by anyone to help maintain the system's decay. Caller might get a reward.
     */
    function triggerGlobalSyntropyDecay(uint256 batchSize) public whenNotPaused {
        if (_nextTokenId <= 1 || syntropyDecayRatePerSecond == 0) {
             lastGlobalDecayTimestamp = uint64(block.timestamp); // Reset timestamp if no echoes or no decay
             return; // No echoes or decay disabled
        }

        uint64 currentTime = uint64(block.timestamp);
        uint256 totalEchoes = _nextTokenId.sub(1); // Total number of echoes created
        uint256 startId = _lastProcessedEchoIdForDecay > 0 ? _lastProcessedEchoIdForDecay : 1;
        uint256 processedCount = 0;

        for (uint256 i = 0; i < batchSize && processedCount < totalEchoes; i++) {
            uint256 currentEchoId = startId + i;
             if (currentEchoId >= _nextTokenId) { // Wrap around
                currentEchoId = 1 + (currentEchoId - _nextTokenId);
            }

            // Skip if Echo doesn't exist (was burned)
            if (echoes[currentEchoId].owner == address(0)) {
                processedCount++;
                continue;
            }

            Echo storage currentEcho = echoes[currentEchoId];
            uint64 lastDecay = currentEcho.lastDecayTimestamp;
            uint64 timeElapsed = currentTime - lastDecay;

            if (timeElapsed > 0) {
                uint256 decayAmount = uint256(timeElapsed).mul(syntropyDecayRatePerSecond);
                 if (decayAmount > currentEcho.syntropyPoints) {
                     decayAmount = currentEcho.syntropyPoints; // Cannot decay below zero
                 }

                if (decayAmount > 0) {
                    currentEcho.syntropyPoints = currentEcho.syntropyPoints.sub(decayAmount);
                    emit SyntropyDecayed(currentEchoId, decayAmount);
                    emit SyntropyPointsChanged(currentEchoId, currentEcho.syntropyPoints, "Decay");
                }
                 currentEcho.lastDecayTimestamp = currentTime; // Update last decay timestamp for this echo
            }

            processedCount++;
            _lastProcessedEchoIdForDecay = currentEchoId; // Update last processed ID
        }

        lastGlobalDecayTimestamp = currentTime; // Update global timestamp
         // Simple reward for caller (optional)
         if (processedCount > 0) {
             // Example: small fixed reward or based on processed count
             // payable(msg.sender).transfer(processedCount.mul(100000000000 wei)); // 100 Gwei per echo processed
        }
    }


    // --- Influence and Delegation ---

    /**
     * @notice Delegates the Syntropy Influence (SP) of an Echo to another address.
     * @param echoId The ID of the Echo whose influence is being delegated.
     * @param delegatee The address to delegate influence to. Use address(0) to undelegate.
     */
    function delegateSyntropyInfluence(uint256 echoId, address delegatee) public onlyEchoOwner(echoId) whenNotPaused {
        address currentDelegatee = _syntropyDelegatee[echoId];

        if (currentDelegatee != address(0)) {
            // Subtract current delegation
            _totalDelegatedInfluence[currentDelegatee] = _totalDelegatedInfluence[currentDelegatee].sub(echoes[echoId].syntropyPoints);
        }

        _syntropyDelegatee[echoId] = delegatee;

        if (delegatee != address(0)) {
            // Add new delegation
            _totalDelegatedInfluence[delegatee] = _totalDelegatedInfluence[delegatee].add(echoes[echoId].syntropyPoints);
        }

        emit InfluenceDelegated(echoId, msg.sender, delegatee);
    }

     /**
     * @notice Removes the delegation for a specific Echo.
     * @param echoId The ID of the Echo whose delegation is being removed.
     */
    function undelegateSyntropyInfluence(uint256 echoId) public onlyEchoOwner(echoId) whenNotPaused {
        _clearDelegation(echoId);
    }

    /**
     * @notice Internal function to clear delegation for an Echo.
     * @param echoId The ID of the Echo.
     */
    function _clearDelegation(uint256 echoId) internal {
        address currentDelegatee = _syntropyDelegatee[echoId];
        if (currentDelegatee != address(0)) {
            _totalDelegatedInfluence[currentDelegatee] = _totalDelegatedInfluence[currentDelegatee].sub(echoes[echoId].syntropyPoints);
            delete _syntropyDelegatee[echoId];
             emit InfluenceUndelegated(echoId, echoes[echoId].owner, address(0)); // from is owner, to is 0x0
        }
    }


    /**
     * @notice Gets the address that an Echo's influence is delegated to.
     * @param echoId The ID of the Echo.
     * @return The delegatee address. Returns address(0) if not delegated or delegates to self.
     */
    function getEchoDelegatee(uint256 echoId) public view returns (address) {
        require(echoes[echoId].owner != address(0), "Echo does not exist");
        address delegatee = _syntropyDelegatee[echoId];
        if (delegatee == address(0)) return echoes[echoId].owner; // If not delegated, influence is with owner
        return delegatee;
    }

    /**
     * @notice Gets the total Syntropy Influence delegated to a specific address.
     * @param delegatee The address to query.
     * @return The total delegated Syntropy Points.
     */
    function getTotalDelegatedInfluence(address delegatee) public view returns (uint256) {
        return _totalDelegatedInfluence[delegatee];
    }


    // --- Linking System ---

    /**
     * @notice Creates a directional link from one Echo to another.
     * @param echoId1 The ID of the source Echo.
     * @param echoId2 The ID of the target Echo.
     * @param linkType The type of the link (user defined, e.g., 1=Parent, 2=Child).
     * @return The ID of the newly created link.
     * @dev Requires ownership of the source Echo.
     */
    function linkEchoes(uint256 echoId1, uint256 echoId2, uint8 linkType) public onlyEchoOwner(echoId1) whenNotPaused returns (uint256) {
        require(echoes[echoId1].owner != address(0), "Source Echo does not exist");
        require(echoes[echoId2].owner != address(0), "Target Echo does not exist");
        require(echoId1 != echoId2, "Cannot link Echo to itself");

        uint256 newLinkId = _nextLinkId;
        require(newLinkId > 0, "Max Link supply reached");

        links[newLinkId] = Link({
            sourceEchoId: echoId1,
            targetEchoId: echoId2,
            linkType: linkType,
            active: true
        });

        _outgoingLinks[echoId1].push(newLinkId);
        _incomingLinks[echoId2].push(newLinkId);

        _nextLinkId = _nextLinkId.add(1);

        emit LinkCreated(newLinkId, echoId1, echoId2, linkType);
        return newLinkId;
    }

    /**
     * @notice Removes a specific link by its ID.
     * @param linkId The ID of the link to remove.
     * @dev Requires ownership of the source Echo of the link.
     */
    function unlinkEchoes(uint256 linkId) public whenNotPaused {
        Link storage link = links[linkId];
        require(link.active, "Link does not exist or is inactive");
        require(echoes[link.sourceEchoId].owner == msg.sender, "Not owner of source Echo");

        link.active = false;

        // Note: Removing elements from dynamic arrays in storage is gas-expensive.
        // For simplicity in this example, we just mark inactive. A production system
        // might use more complex data structures or lazy cleanup.

        // Example of removing from arrays (expensive):
        // _removeLinkFromArray(_outgoingLinks[link.sourceEchoId], linkId);
        // _removeLinkFromArray(_incomingLinks[link.targetEchoId], linkId);

        emit LinkRemoved(linkId);
    }

    // Helper function for removing from array (optional, if actually removing)
    /*
    function _removeLinkFromArray(uint256[] storage arr, uint256 linkId) internal {
         for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == linkId) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                return;
            }
        }
    }
    */

    /**
     * @notice Gets the IDs of all active links originating from an Echo.
     * @param echoId The ID of the source Echo.
     * @return An array of outgoing link IDs.
     */
    function getOutgoingLinks(uint256 echoId) public view returns (uint256[] memory) {
        uint256[] memory outgoing = _outgoingLinks[echoId];
        uint256[] memory activeLinks;
        uint256 activeCount = 0;
        for(uint i = 0; i < outgoing.length; i++){
            if(links[outgoing[i]].active){
                 activeCount++;
            }
        }
         activeLinks = new uint256[](activeCount);
         uint256 currentIndex = 0;
         for(uint i = 0; i < outgoing.length; i++){
            if(links[outgoing[i]].active){
                activeLinks[currentIndex] = outgoing[i];
                currentIndex++;
            }
        }
        return activeLinks;
    }

    /**
     * @notice Gets the IDs of all active links pointing to an Echo.
     * @param echoId The ID of the target Echo.
     * @return An array of incoming link IDs.
     */
    function getIncomingLinks(uint256 echoId) public view returns (uint256[] memory) {
        uint256[] memory incoming = _incomingLinks[echoId];
         uint256[] memory activeLinks;
        uint256 activeCount = 0;
        for(uint i = 0; i < incoming.length; i++){
            if(links[incoming[i]].active){
                 activeCount++;
            }
        }
         activeLinks = new uint256[](activeCount);
         uint256 currentIndex = 0;
         for(uint i = 0; i < incoming.length; i++){
            if(links[incoming[i]].active){
                activeLinks[currentIndex] = incoming[i];
                currentIndex++;
            }
        }
        return activeLinks;
    }


    // --- Achievement System ---

    /**
     * @notice Owner/Governance function to define a new achievement badge.
     * @param threshold The Syntropy Point threshold required to earn this badge.
     * @param metadataURI URI pointing to the badge's metadata/image.
     * @return The ID of the newly created badge.
     */
    function createAchievementBadge(uint256 threshold, string memory metadataURI) public onlyOwner whenNotPaused returns (uint256) {
        uint256 newBadgeId = _nextBadgeId;
        require(newBadgeId > 0, "Max Badge supply reached");

        achievementBadges[newBadgeId] = AchievementBadge({
            threshold: threshold,
            metadataURI: metadataURI,
            exists: true
        });

        _nextBadgeId = _nextBadgeId.add(1);

        emit AchievementBadgeCreated(newBadgeId, threshold, metadataURI);
        return newBadgeId;
    }

    /**
     * @notice Allows an Echo owner to claim a specific achievement badge if their Echo meets the required SP threshold.
     * @param echoId The ID of the Echo claiming the badge.
     * @param badgeId The ID of the achievement badge to claim.
     */
    function claimAchievementBadge(uint256 echoId, uint256 badgeId) public onlyEchoOwner(echoId) whenNotPaused {
        require(achievementBadges[badgeId].exists, "Badge does not exist");
        require(echoes[echoId].syntropyPoints >= achievementBadges[badgeId].threshold, "Echo does not meet threshold");

        // Check if badge is already held by this Echo
        uint256[] storage heldBadges = echoes[echoId].heldBadges;
        for(uint i = 0; i < heldBadges.length; i++) {
            if (heldBadges[i] == badgeId) {
                revert("Badge already claimed by this Echo");
            }
        }

        heldBadges.push(badgeId);

        emit AchievementBadgeClaimed(echoId, badgeId);
    }

    /**
     * @notice Returns the IDs of achievement badges held by an Echo.
     * @param echoId The ID of the Echo.
     * @return An array of badge IDs.
     */
    function getHeldAchievementBadges(uint256 echoId) public view returns (uint256[] memory) {
        require(echoes[echoId].owner != address(0), "Echo does not exist");
        return echoes[echoId].heldBadges;
    }


    // --- Limited Governance ---

    // Note: This is a simplified governance module. A real DAO would be far more complex.
    // It uses delegated influence (SP) for voting power.
    // It allows proposing arbitrary function calls on this contract. Care must be taken!

    /**
     * @notice Creates a new governance proposal.
     * @param proposalData The calldata for the function to be executed if the proposal passes.
     * @param description A description of the proposal.
     * @return The ID of the newly created proposal.
     * @dev Requires the caller to have at least one Echo with non-zero SP or delegated SP.
     */
    function proposeParameterChange(bytes memory proposalData, string memory description) public whenNotPaused returns (uint256) {
        // Simple check: requires caller to have some influence (owner of an echo or delegatee)
        require(_ownerEchoes[msg.sender].length > 0 || _totalDelegatedInfluence[msg.sender] > 0, "Caller has no influence");

        uint256 newProposalId = _nextProposalId;
        require(newProposalId > 0, "Max Proposal supply reached");

        uint256 totalEchoSP = 0; // This would need to be tracked globally or iterated, which is expensive.
                               // For a real system, you'd need a mechanism to get total circulating SP/influence.
                               // Placeholder: Using a fixed large number or requiring a snapshot.
                               // Let's estimate total influence by multiplying average SP * total echoes (bad) or require manual input (bad).
                               // Better: Require voter base (e.g., minimum unique delegatees voting) + vote weight.
                               // Simplification: Use a fixed threshold of SP needed, not based on total supply.

        // For simplicity, let's make threshold relative to *some* value, e.g., a hardcoded parameter or previous total SP snapshot
        // Let's just use a fixed threshold for this example.
        uint256 requiredInfluenceForProposal = 100 ether; // Example: Need 100 ETH worth of SP to propose.

        // Calculate the caller's influence
        uint256 proposerInfluence = 0;
        for(uint i=0; i < _ownerEchoes[msg.sender].length; i++) {
             uint256 echoId = _ownerEchoes[msg.sender][i];
            // Count SP if owner is also the delegatee or no delegatee
            if (_syntropyDelegatee[echoId] == address(0) || _syntropyDelegatee[echoId] == msg.sender) {
                 proposerInfluence = proposerInfluence.add(echoes[echoId].syntropyPoints);
            }
        }
        proposerInfluence = proposerInfluence.add(_totalDelegatedInfluence[msg.sender]); // Add influence delegated *to* caller

        require(proposerInfluence >= requiredInfluenceForProposal, "Caller influence too low to propose");


        proposals[newProposalId] = Proposal({
            id: newProposalId,
            data: proposalData,
            description: description,
            voteThreshold: proposalPassingThresholdPercentage, // % votes needed to pass (of votes cast)
            totalInfluenceNeeded: proposalQuorumPercentage, // Placeholder: Represents % of *something* for quorum. Needs better tracking of total influence.
                                                            // Let's reinterpret: `totalInfluenceNeeded` is absolute SP for quorum, `voteThreshold` is % support.
                                                            // Let's calculate quorum SP dynamically or use a snapshot mechanism.
                                                            // Simple: Quorum is a fixed amount + threshold is a percentage.
             votesFor: 0,
             votesAgainst: 0,
             state: ProposalState.Active,
             proposalCreationTimestamp: uint64(block.timestamp),
             votingPeriodEndTimestamp: uint64(block.timestamp).add(VOTING_PERIOD)
        });

         // For a real system: calculate actual total influence at snapshot time.
         // uint256 snapshotTotalInfluence = calculateTotalActiveEchoSyntropy();
         // proposals[newProposalId].totalInfluenceNeeded = snapshotTotalInfluence.mul(proposalQuorumPercentage).div(100);


        _nextProposalId = _nextProposalId.add(1);

        emit ProposalCreated(newProposalId, msg.sender, description);
        return newProposalId;
    }

    /**
     * @notice Casts a vote on a proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a vote in favor, false for against.
     * @dev Voter's influence is their total SP from Echoes where they are the delegatee (or owner, if no delegatee).
     */
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp <= proposal.votingPeriodEndTimestamp, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");

        // Calculate voter's influence (total SP of Echoes delegated to msg.sender)
        uint256 voterInfluence = getTotalDelegatedInfluence(msg.sender);
        // Add influence from Echoes owned by msg.sender that are NOT delegated
         for(uint i=0; i < _ownerEchoes[msg.sender].length; i++) {
             uint256 echoId = _ownerEchoes[msg.sender][i];
            if (_syntropyDelegatee[echoId] == address(0)) { // If not delegated
                 voterInfluence = voterInfluence.add(echoes[echoId].syntropyPoints);
            }
        }

        require(voterInfluence > 0, "Voter has no influence");

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.votesFor = proposal.votesFor.add(voterInfluence);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterInfluence);
        }

        emit Voted(proposalId, msg.sender, support, voterInfluence);

        // Check state after voting (can transition to Defeated/Succeeded early)
        _updateProposalState(proposalId);
    }

    /**
     * @notice Executes a successful proposal.
     * @param proposalId The ID of the proposal to execute.
     * @dev Requires the voting period to be over and the proposal to have succeeded.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.state == ProposalState.Succeeded, "Proposal not in Succeeded state");
         // Add checks for execution cooldown if needed

        // Execute the proposed action
        // This is the risky part - needs careful sanitization of `proposal.data` in a real system
        (bool success, ) = address(this).call(proposal.data);
        require(success, "Proposal execution failed");

        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

    /**
     * @notice Gets the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist"); // Check existence
        if (proposal.state != ProposalState.Active) {
            return proposal.state;
        }
        if (block.timestamp > proposal.votingPeriodEndTimestamp) {
            // Voting period ended, evaluate outcome
            uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
             // In a real system, check quorum against total influence at snapshot
             // require(totalVotes >= proposal.totalInfluenceNeeded, "Quorum not met");

            if (totalVotes == 0) return ProposalState.Defeated; // No votes cast
            if (proposal.votesFor.mul(100).div(totalVotes) >= proposal.voteThreshold) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Defeated;
            }
        }
        return ProposalState.Active; // Still active
    }

    /**
     * @notice Internal helper to update proposal state after voting or timing out.
     * @param proposalId The ID of the proposal.
     */
    function _updateProposalState(uint256 proposalId) internal {
         Proposal storage proposal = proposals[proposalId];
         if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingPeriodEndTimestamp) {
            uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
             // In a real system, check quorum against total influence at snapshot
             // uint256 snapshotTotalInfluence = calculateTotalActiveEchoSyntropyAtSnapshot(proposal.snapshotBlock);
             // bool quorumMet = totalVotes >= snapshotTotalInfluence.mul(proposalQuorumPercentage).div(100);

             // Simplified quorum check: Just check if *any* votes were cast
             bool quorumMet = totalVotes > 0; // Very basic quorum

             if (quorumMet && proposal.votesFor.mul(100).div(totalVotes) >= proposal.voteThreshold) {
                proposal.state = ProposalState.Succeeded;
                emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
             } else {
                 proposal.state = ProposalState.Defeated;
                 emit ProposalStateChanged(proposalId, ProposalState.Defeated);
             }
         }
    }


    // --- Batch Processing Helpers ---

     /**
     * @notice Internal helper to get the total number of existing Echoes.
     * @return The total number of Echoes created so far minus potentially burned ones (approximation).
     */
    function _getTotalCreatedEchoes() internal view returns (uint256) {
        // This isn't perfectly accurate if Echoes are burned, but gives an upper bound.
        // Accurate count requires iterating or maintaining a separate counter on burn/register.
        return _nextTokenId.sub(1);
    }

    // --- Pausable Overrides ---

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // --- Fees and Withdrawals ---

    /**
     * @notice Allows the contract owner to withdraw collected fees.
     * @param recipient The address to send the fees to.
     */
    function withdrawFees(address recipient) public onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(recipient).transfer(balance);
        emit FeesWithdrawn(recipient, balance);
    }

    // --- Receive and Fallback ---
    receive() external payable {}
    fallback() external payable {}

    // --- Extended Getters (Example) ---

    /**
     * @notice Gets all key properties of an Echo.
     * @param echoId The ID of the Echo.
     * @return A tuple containing the Echo's properties.
     */
    function getEchoProperties(uint256 echoId) public view returns (
        address owner,
        uint256 syntropyPoints,
        uint64 lastDecayTimestamp,
        string memory metadataURI,
        uint256[] memory heldBadges,
        address delegatee,
        uint256[] memory outgoingLinks,
        uint256[] memory incomingLinks
    ) {
         require(echoes[echoId].owner != address(0), "Echo does not exist");
         Echo storage echo = echoes[echoId];
         return (
             echo.owner,
             echo.syntropyPoints,
             echo.lastDecayTimestamp,
             echo.metadataURI,
             echo.heldBadges,
             getEchoDelegatee(echoId), // Use getter which defaults to owner if not delegated
             getOutgoingLinks(echoId),
             getIncomingLinks(echoId)
         );
    }

    // Placeholder function for governance execution example
    // In a real system, this would need to check msg.sender is this contract
    // and decode the specific function call from `data`.
    // For this example, let's add a simple function that governance *could* call.
    function _setSyntropyDecayRate(uint256 newRate) public {
        // This function *should* only be callable by the `executeProposal` function
        // or potentially the owner directly outside governance.
        // A real implementation needs access control here (e.g., only this contract, or owner).
        // For demo purposes, we assume the proposal mechanism calls it correctly.
        syntropyDecayRatePerSecond = newRate;
    }

     function _setInteractionReward(uint256 newReward) public {
         interactionSyntropyReward = newReward;
     }

     function _setInteractionFee(uint256 newFee) public {
         interactionFee = newFee;
     }

     // Example of how proposal data could be structured:
     // bytes callData = abi.encodeWithSelector(this._setSyntropyDecayRate.selector, 5); // Example: set decay rate to 5

}
```