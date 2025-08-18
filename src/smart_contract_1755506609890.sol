The smart contract below, named `EvolvingAutonomousCollective`, presents a novel approach to decentralized autonomous organizations by integrating dynamic NFTs, a unique liquid democracy governance model, reputation scoring, and epoch-based evolution. It also includes a conceptual integration point for an off-chain AI oracle.

The goal was to create an advanced, creative, and non-duplicated smart contract with at least 20 functions. This contract significantly exceeds that, offering 40 distinct functions covering various complex interactions.

---

**Contract Name:** `EvolvingAutonomousCollective`

**Description:**
A smart contract for a decentralized autonomous collective where participants are represented by evolving "Nodes" (dynamic NFTs). Nodes gain experience and influence through contributions, can delegate their influence, and collectively govern a shared treasury and progress towards goals. The collective itself evolves through distinct epochs, dynamically updating node traits and collective metrics.

**Core Features:**
*   **Dynamic Nodes (dNFTs):** ERC-721 tokens representing participants, with metadata changing dynamically based on their on-chain activity (Experience Points, Generation) and the collective's progress.
*   **Influence-Based Governance (Liquid Democracy):** A sophisticated governance model where individual 'Nodes' accrue 'Influence Score' from their XP and Generation. Nodes can delegate their full influence to another Node, creating a liquid democracy system. Proposals are voted on using this aggregated influence.
*   **Epoch-Driven Evolution:** The collective state and individual Node attributes (XP decay, Generation advancement, Influence recalculation) evolve over time through distinct, time-locked epochs, acting as a periodic reset or progression mechanism.
*   **Shared Treasury:** A common pool of funds managed and allocated by collective governance proposals.
*   **Conceptual AI Oracle Integration:** A dedicated interface for a trusted off-chain AI oracle to submit periodic evaluations of the collective's status or progress, which could then conceptually inform future on-chain decisions or metrics.

**Function Summary:**

**I. ERC-721 Standard Functions:**
1.  `balanceOf(address owner)`: Returns the number of Nodes owned by `owner`.
2.  `ownerOf(uint256 tokenId)`: Returns the owner of the `tokenId` Node.
3.  `approve(address to, uint256 tokenId)`: Approves `to` to manage `tokenId`.
4.  `getApproved(uint256 tokenId)`: Returns the approved address for `tokenId`.
5.  `setApprovalForAll(address operator, bool approved)`: Enables/disables an operator for all NFTs.
6.  `isApprovedForAll(address owner, address operator)`: Checks if `operator` is approved for `owner`.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of `tokenId`.
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers ownership of `tokenId`.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: Safely transfers ownership with data.
10. `supportsInterface(bytes4 interfaceId)`: Returns true if this contract implements `interfaceId`.

**II. Node Management & Dynamics:**
11. `mintNode(address to)`: Mints a new Node NFT for `to`.
12. `tokenURI(uint256 tokenId)`: Generates the dynamic metadata URI for `tokenId` based on its attributes.
13. `recordContribution(uint256 tokenId, uint256 amount)`: Awards XP to a Node for a contribution.
14. `getNodeXP(uint256 tokenId)`: Returns the current Experience Points (XP) of a Node.
15. `getNodeGeneration(uint256 tokenId)`: Returns the generation of a Node.
16. `getNodeInfluence(uint256 tokenId)`: Returns the base influence score of a Node (excluding delegations).

**III. Influence & Delegation:**
17. `delegateInfluence(uint256 tokenId, uint256 toNodeId)`: Delegates `tokenId`'s base influence to `toNodeId`.
18. `undelegateInfluence(uint256 tokenId)`: Revokes influence delegation for `tokenId`.
19. `getEffectiveNodeInfluence(uint256 tokenId)`: Calculates the total influence a Node holds for voting (its own + influence delegated to it).
20. `getDelegatedTo(uint256 tokenId)`: Returns the node ID to which `tokenId` is delegating (0 if none).

**IV. Collective State & Epochs:**
21. `advanceEpoch()`: Advances the collective to the next epoch, triggering state updates and influence recalculations.
22. `getCurrentEpoch()`: Returns the current epoch number.
23. `getCollectiveXP()`: Returns the total XP accumulated by all Nodes.
24. `getCollectiveInfluence()`: Returns the total effective influence of all Nodes in the collective.
25. `setEpochDuration(uint256 _duration)`: Sets the required time between epochs (governable by owner/governance).
26. `setContributionMultiplier(uint256 _multiplier)`: Sets the multiplier for XP gain from contributions (governable).

**V. Governance & Treasury:**
27. `depositFunds() payable`: Allows depositing funds into the collective treasury.
28. `getTreasuryBalance()`: Returns the current balance of the collective treasury.
29. `submitProposal(string calldata description, address target, bytes calldata callData, uint256 value, uint256 threshold)`: Submits a new governance proposal.
30. `voteOnProposal(uint256 proposalId, bool support, uint256 tokenId)`: Casts a vote on a proposal using a Node's effective influence.
31. `getProposalState(uint256 proposalId)`: Returns the current state of a proposal (e.g., Active, Succeeded, Defeated).
32. `getProposalVotes(uint256 proposalId)`: Returns the current vote counts (for and against) for a proposal.
33. `executeProposal(uint256 proposalId)`: Executes a proposal that has passed its threshold and voting period.
34. `cancelProposal(uint256 proposalId)`: Allows the proposer or governance to cancel a proposal.

**VI. AI Oracle Integration (Conceptual):**
35. `setAIOracleAddress(address _aiOracle)`: Sets the trusted address for the AI oracle (governable).
36. `submitAICollectiveEvaluation(uint256 evaluationScore)`: Allows the designated AI oracle to submit a collective evaluation score.
37. `getLatestAICollectiveEvaluation()`: Returns the latest AI collective evaluation score.

**VII. Administrative/Utility:**
38. `pause()`: Pauses certain contract functionalities (admin/governance only).
39. `unpause()`: Unpauses contract functionalities (admin/governance only).
40. `transferOwnership(address newOwner)`: Transfers contract ownership (initial owner, then potentially by governance via proposal).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title EvolvingAutonomousCollective
 * @notice A smart contract for a decentralized autonomous collective where participants are represented by evolving "Nodes" (dynamic NFTs).
 *         Nodes gain experience and influence through contributions, can delegate their influence, and collectively govern a shared treasury and progress towards goals.
 *         The collective evolves through epochs, dynamically updating node traits and collective metrics.
 *
 * @dev This contract combines elements of dynamic NFTs, liquid democracy, reputation systems, and epoch-based progression.
 *      It includes a conceptual integration point for an off-chain AI oracle.
 *      Many internal calculations are simplified for on-chain execution,
 *      and the actual "AI" or "contribution" logic would be external or more complex in a production environment.
 */

// Outline and Function Summary
// I. ERC-721 Standard Functions:
//    1. balanceOf(address owner): Returns the number of Nodes owned by `owner`.
//    2. ownerOf(uint256 tokenId): Returns the owner of the `tokenId` Node.
//    3. approve(address to, uint256 tokenId): Approves `to` to manage `tokenId`.
//    4. getApproved(uint256 tokenId): Returns the approved address for `tokenId`.
//    5. setApprovalForAll(address operator, bool approved): Enables/disables an operator for all NFTs.
//    6. isApprovedForAll(address owner, address operator): Checks if `operator` is approved for `owner`.
//    7. transferFrom(address from, address to, uint256 tokenId): Transfers ownership of `tokenId`.
//    8. safeTransferFrom(address from, address to, uint256 tokenId): Safely transfers ownership of `tokenId`.
//    9. safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): Safely transfers ownership with data.
//    10. supportsInterface(bytes4 interfaceId): Returns true if this contract implements `interfaceId`.

// II. Node Management & Dynamics:
//     11. mintNode(address to): Mints a new Node NFT for `to`.
//     12. tokenURI(uint256 tokenId): Generates the dynamic metadata URI for `tokenId`.
//     13. recordContribution(uint256 tokenId, uint256 amount): Awards XP to a Node for a contribution.
//     14. getNodeXP(uint256 tokenId): Returns the current XP of a Node.
//     15. getNodeGeneration(uint256 tokenId): Returns the generation of a Node.
//     16. getNodeInfluence(uint256 tokenId): Returns the base influence score of a Node (excluding delegations).

// III. Influence & Delegation:
//      17. delegateInfluence(uint256 tokenId, uint256 toNodeId): Delegates `tokenId`'s base influence to `toNodeId`.
//      18. undelegateInfluence(uint256 tokenId): Revokes influence delegation for `tokenId`.
//      19. getEffectiveNodeInfluence(uint256 tokenId): Calculates the total influence a Node holds for voting (its own + delegated to it).
//      20. getDelegatedTo(uint256 tokenId): Returns the node ID to which `tokenId` is delegating (0 if none).

// IV. Collective State & Epochs:
//     21. advanceEpoch(): Advances the collective to the next epoch, triggering state updates and influence decay.
//     22. getCurrentEpoch(): Returns the current epoch number.
//     23. getCollectiveXP(): Returns the total XP accumulated by all Nodes.
//     24. getCollectiveInfluence(): Returns the total effective influence of all Nodes.
//     25. setEpochDuration(uint256 _duration): Sets the required time between epochs (governable).
//     26. setContributionMultiplier(uint256 _multiplier): Sets the multiplier for XP gain from contributions (governable).

// V. Governance & Treasury:
//    27. depositFunds() payable: Allows depositing funds into the collective treasury.
//    28. getTreasuryBalance(): Returns the current balance of the collective treasury.
//    29. submitProposal(string calldata description, address target, bytes calldata callData, uint256 value, uint256 threshold): Submits a new governance proposal.
//    30. voteOnProposal(uint256 proposalId, bool support, uint256 tokenId): Casts a vote on a proposal using a Node's effective influence.
//    31. getProposalState(uint256 proposalId): Returns the current state of a proposal.
//    32. getProposalVotes(uint256 proposalId): Returns the current vote counts for a proposal (for and against).
//    33. executeProposal(uint256 proposalId): Executes a proposal that has passed and elapsed its voting period.
//    34. cancelProposal(uint256 proposalId): Allows the proposer or governance to cancel a proposal.

// VI. AI Oracle Integration (Conceptual):
//     35. setAIOracleAddress(address _aiOracle): Sets the trusted address for the AI oracle (governable).
//     36. submitAICollectiveEvaluation(uint256 evaluationScore): Allows the designated AI oracle to submit a collective evaluation score.
//     37. getLatestAICollectiveEvaluation(): Returns the latest AI collective evaluation score.

// VII. Administrative/Utility:
//      38. pause(): Pauses certain contract functionalities (admin/governance only).
//      39. unpause(): Unpause contract functionalities (admin/governance only).
//      40. transferOwnership(address newOwner): Transfers contract ownership (initial owner, then by governance).

contract EvolvingAutonomousCollective is ERC721, Ownable, Pausable {
    using Strings for uint256;

    // --- Data Structures ---

    struct Node {
        uint256 xp; // Experience Points
        uint256 generation; // How many epochs it has existed
        uint256 influenceScore; // Base influence score derived from XP and generation
    }

    struct Proposal {
        string description;
        address proposer;
        address target;
        bytes callData;
        uint256 value;
        uint256 threshold; // Minimum effective influence required to pass
        uint256 startTime;
        uint256 votingPeriod; // Duration of voting
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool canceled;
        mapping(uint256 => bool) hasVoted; // nodeID => voted
    }

    enum ProposalState { Pending, Active, Succeeded, Defeated, Expired, Executed, Canceled }

    // --- State Variables ---

    uint256 private _nextTokenId;
    mapping(uint256 => Node) public nodes; // tokenId => Node struct
    uint256[] public allNodeIds; // Keep track of all node IDs for iteration in epoch progression

    mapping(uint256 => uint256) public nodeToDelegatee; // nodeID => delegateeNodeID (0 if no delegation)
    mapping(uint256 => uint256) public delegateeToTotalDelegatedInfluence; // delegateeNodeID => sum of base influence of nodes delegated *to* it

    uint256 public currentEpoch;
    uint256 public lastEpochAdvanceTime;
    uint256 public epochDuration = 7 days; // Default epoch duration

    uint256 public contributionMultiplier = 1; // XP gain multiplier

    uint256 public collectiveXP; // Total XP accumulated by all nodes
    uint256 public collectiveInfluence; // Total effective influence of all nodes (sum of all voting power)

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public proposalVotingPeriod = 3 days; // Default voting period for proposals

    address public aiOracleAddress; // Address of the trusted AI oracle
    uint256 public latestAICollectiveEvaluation; // Latest evaluation score from AI oracle

    // --- Events ---

    event NodeMinted(address indexed owner, uint256 indexed tokenId, uint256 generation);
    event ContributionRecorded(uint256 indexed tokenId, uint256 xpGained, uint256 newXP);
    event InfluenceDelegated(uint256 indexed delegatorNodeId, uint256 indexed delegateeNodeId);
    event InfluenceUndelegated(uint256 indexed delegatorNodeId, uint256 indexed oldDelegateeNodeId);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 totalCollectiveXP, uint256 totalCollectiveInfluence);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description, uint256 threshold);
    event VoteCast(uint256 indexed proposalId, uint256 indexed voterNodeId, bool support, uint256 influenceUsed);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event AICollectiveEvaluationSubmitted(address indexed aiOracle, uint256 evaluationScore);

    // --- Constructor ---

    constructor() ERC721("EvolvingAutonomousCollectiveNode", "EACN") Ownable(msg.sender) {
        currentEpoch = 1;
        lastEpochAdvanceTime = block.timestamp;
    }

    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "EAC: Not the AI oracle");
        _;
    }

    modifier onlyNodeOwner(uint256 _tokenId) {
        // _isApprovedOrOwner is an internal ERC721 function
        require(_isApprovedOrOwner(msg.sender, _tokenId), "EAC: Not authorized to manage this Node");
        _;
    }

    // --- I. ERC-721 Standard Functions (from OpenZeppelin) ---
    // These functions are inherited and implicitly exposed:
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom, supportsInterface

    // --- II. Node Management & Dynamics ---

    /**
     * @notice Mints a new Node NFT for a specified address.
     * @param to The address to mint the Node for.
     * @return The ID of the newly minted Node.
     */
    function mintNode(address to) public virtual payable whenNotPaused returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        nodes[tokenId] = Node({
            xp: 0,
            generation: currentEpoch,
            influenceScore: 0 // Will be calculated upon first contribution or epoch advance
        });
        allNodeIds.push(tokenId);
        emit NodeMinted(to, tokenId, currentEpoch);
        return tokenId;
    }

    /**
     * @notice Generates the dynamic metadata URI for a given Node.
     * @dev The URI includes Node's XP, influence, and generation, encoded as Base64 JSON.
     *      Placeholder IPFS image URIs are used for conceptual dynamic visuals.
     * @param tokenId The ID of the Node.
     * @return The Base64 encoded JSON metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure the token exists

        Node storage node = nodes[tokenId];
        string memory name = string(abi.encodePacked("EAC Node #", tokenId.toString()));
        string memory description = string(
            abi.encodePacked(
                "An evolving autonomous collective node. XP: ", node.xp.toString(),
                ", Influence: ", node.influenceScore.toString(),
                ", Generation: ", node.generation.toString(),
                ", Epoch: ", currentEpoch.toString()
            )
        );

        // Simple placeholder image based on XP for visual progression
        string memory imageUri;
        if (node.xp < 100) {
            imageUri = "ipfs://QmZ1Y2X3Y4Z5A6B7C8D9E0F1G2H3I4J5K6L7M8N9O0P"; // Base form
        } else if (node.xp < 500) {
            imageUri = "ipfs://QmY0X1Y2X3Y4Z5A6B7C8D9E0F1G2H3I4J5K6L7M8N9Q"; // Evolved form 1
        } else if (node.xp < 1000) {
            imageUri = "ipfs://QmX0X1Y2X3Y4Z5A6B7C8D9E0F1G2H3I4J5K6L7M8N9R"; // Evolved form 2
        } else {
            imageUri = "ipfs://QmZ0X1Y2X3Y4Z5A6B7C8D9E0F1G2H3I4J5K6L7M8N9S"; // Advanced form
        }

        string memory json = string(
            abi.encodePacked(
                '{"name": "', name,
                '", "description": "', description,
                '", "image": "', imageUri,
                '", "attributes": [',
                '{"trait_type": "XP", "value": ', node.xp.toString(), '},',
                '{"trait_type": "Influence Score", "value": ', node.influenceScore.toString(), '},',
                '{"trait_type": "Generation", "value": ', node.generation.toString(), '},',
                '{"trait_type": "Epoch", "value": ', currentEpoch.toString(), '}',
                ']}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @notice Awards Experience Points (XP) to a specific Node.
     * @dev This function can be called by external modules (e.g., another contract representing a task completion or resource provision)
     *      to reward contributions, or by the owner for manual distribution.
     * @param tokenId The ID of the Node to award XP to.
     * @param amount The base amount of XP to add before multiplier.
     */
    function recordContribution(uint256 tokenId, uint256 amount) public virtual whenNotPaused {
        _requireOwned(tokenId); // Ensure the node exists

        uint256 xpGained = amount * contributionMultiplier;
        nodes[tokenId].xp += xpGained;
        
        // Update this node's base influence immediately, and adjust delegated influence if applicable
        uint256 oldBaseInfluence = nodes[tokenId].influenceScore;
        uint256 newBaseInfluence = _calculateNodeBaseInfluence(nodes[tokenId].xp, nodes[tokenId].generation);
        nodes[tokenId].influenceScore = newBaseInfluence;

        if (nodeToDelegatee[tokenId] != 0) {
            delegateeToTotalDelegatedInfluence[nodeToDelegatee[tokenId]] -= oldBaseInfluence;
            delegateeToTotalDelegatedInfluence[nodeToDelegatee[tokenId]] += newBaseInfluence;
        }
        // Collective XP and Influence are recalculated in advanceEpoch
        
        emit ContributionRecorded(tokenId, xpGained, nodes[tokenId].xp);
    }

    /**
     * @notice Returns the current XP of a specific Node.
     * @param tokenId The ID of the Node.
     * @return The XP of the Node.
     */
    function getNodeXP(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return nodes[tokenId].xp;
    }

    /**
     * @notice Returns the generation number of a specific Node.
     * @param tokenId The ID of the Node.
     * @return The generation of the Node.
     */
    function getNodeGeneration(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return nodes[tokenId].generation;
    }

    /**
     * @notice Returns the base influence score of a specific Node.
     * @dev This is the node's individual influence, derived from XP and Generation, not including delegations.
     * @param tokenId The ID of the Node.
     * @return The base influence score.
     */
    function getNodeInfluence(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return nodes[tokenId].influenceScore;
    }

    /**
     * @dev Internal function to calculate a node's base influence score based on XP and Generation.
     *      This formula defines the 'reputation' aspect of a node.
     * @param _xp The node's current XP.
     * @param _generation The node's current generation.
     * @return The calculated base influence score.
     */
    function _calculateNodeBaseInfluence(uint256 _xp, uint256 _generation) internal pure returns (uint256) {
        uint256 influence = (_xp / 100) + (_generation * 10); // Simple formula: 100 XP = 1 influence, 1 generation = 10 influence
        if (influence == 0 && _xp > 0) influence = 1; // Minimum influence for any XP earned
        if (influence > 1000) influence = 1000; // Cap influence to prevent overflow or excessive power
        return influence;
    }

    // --- III. Influence & Delegation ---

    /**
     * @notice Allows a Node owner to delegate their Node's base influence to another Node.
     * @dev Once delegated, the delegating Node cannot directly vote. Its influence is added to the delegatee.
     * @param tokenId The ID of the Node delegating its influence. Must be owned by msg.sender.
     * @param toNodeId The ID of the Node to delegate influence to.
     */
    function delegateInfluence(uint256 tokenId, uint256 toNodeId) public virtual whenNotPaused onlyNodeOwner(tokenId) {
        require(tokenId != toNodeId, "EAC: Cannot delegate to self");
        _requireOwned(toNodeId); // Ensure delegatee exists

        uint256 oldDelegateeNodeId = nodeToDelegatee[tokenId];
        uint256 nodeBaseInfluence = nodes[tokenId].influenceScore;

        if (oldDelegateeNodeId != 0) {
            // If already delegating, first remove influence from old delegatee
            delegateeToTotalDelegatedInfluence[oldDelegateeNodeId] -= nodeBaseInfluence;
        } else {
            // If not delegating before, subtract its own influence from the total collective influence
            // as its power is now transferred to a delegatee.
            collectiveInfluence -= nodeBaseInfluence;
        }

        nodeToDelegatee[tokenId] = toNodeId;
        delegateeToTotalDelegatedInfluence[toNodeId] += nodeBaseInfluence;
        collectiveInfluence += nodeBaseInfluence; // Add the delegated influence to the collective total via the delegatee.

        emit InfluenceDelegated(tokenId, toNodeId);
    }

    /**
     * @notice Allows a Node owner to revoke their Node's influence delegation.
     * @param tokenId The ID of the Node to undelegate. Must be owned by msg.sender.
     */
    function undelegateInfluence(uint256 tokenId) public virtual whenNotPaused onlyNodeOwner(tokenId) {
        uint256 oldDelegateeNodeId = nodeToDelegatee[tokenId];
        require(oldDelegateeNodeId != 0, "EAC: Node is not delegating influence");

        uint256 nodeBaseInfluence = nodes[tokenId].influenceScore;

        nodeToDelegatee[tokenId] = 0; // Clear delegation
        delegateeToTotalDelegatedInfluence[oldDelegateeNodeId] -= nodeBaseInfluence;

        // Add back to collective via itself, as it's no longer accounted for by a delegatee
        collectiveInfluence -= nodeBaseInfluence;
        collectiveInfluence += nodeBaseInfluence;

        emit InfluenceUndelegated(tokenId, oldDelegateeNodeId);
    }

    /**
     * @notice Calculates the total effective influence a Node holds for voting.
     * @dev This includes the Node's own base influence if not delegating, plus any influence delegated to it.
     *      If the Node itself is delegating its influence, its own base influence component for direct voting is 0.
     * @param tokenId The ID of the Node.
     * @return The total effective influence.
     */
    function getEffectiveNodeInfluence(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        uint256 baseInfluence = nodes[tokenId].influenceScore;
        uint256 delegatedInInfluence = delegateeToTotalDelegatedInfluence[tokenId];

        // If this node is delegating its own influence, it cannot vote directly,
        // so its base influence isn't counted as part of its *own* effective voting power.
        if (nodeToDelegatee[tokenId] != 0) {
            baseInfluence = 0;
        }
        return baseInfluence + delegatedInInfluence;
    }

    /**
     * @notice Returns the node ID to which a given Node is delegating its influence.
     * @param tokenId The ID of the Node.
     * @return The node ID of the delegatee, or 0 if not delegating.
     */
    function getDelegatedTo(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return nodeToDelegatee[tokenId];
    }

    // --- IV. Collective State & Epochs ---

    /**
     * @notice Advances the collective to the next epoch.
     * @dev Can only be called after `epochDuration` has passed since the last advance.
     *      Triggers XP decay for all nodes, updates their generations, recalculates influence scores,
     *      and updates total collective metrics. Can be called by anyone, which implies external incentives
     *      or a gas refund mechanism in a live system to ensure timely execution.
     */
    function advanceEpoch() public virtual whenNotPaused {
        require(block.timestamp >= lastEpochAdvanceTime + epochDuration, "EAC: Epoch duration not elapsed");

        currentEpoch++;
        lastEpochAdvanceTime = block.timestamp;

        // Reset collective totals before recalculating
        collectiveXP = 0;
        collectiveInfluence = 0;

        // Phase 1: Update individual node XP, generation, and base influence scores.
        // Also update the `delegateeToTotalDelegatedInfluence` for active delegations.
        for (uint256 i = 0; i < allNodeIds.length; i++) {
            uint256 tokenId = allNodeIds[i];
            Node storage node = nodes[tokenId];

            node.generation++;
            node.xp = node.xp / 2; // Simple XP decay over epochs

            // Store old influence to adjust delegated sums
            uint256 oldBaseInfluence = node.influenceScore;
            // Recalculate base influence based on new XP and generation
            node.influenceScore = _calculateNodeBaseInfluence(node.xp, node.generation);

            collectiveXP += node.xp; // Accumulate collective XP

            // If this node is delegating, update the delegated influence sum of its delegatee
            if (nodeToDelegatee[tokenId] != 0) {
                delegateeToTotalDelegatedInfluence[nodeToDelegatee[tokenId]] -= oldBaseInfluence;
                delegateeToTotalDelegatedInfluence[nodeToDelegatee[tokenId]] += node.influenceScore;
            }
        }

        // Phase 2: Calculate total collective influence by summing up the effective influence
        //          of only those nodes that are not delegating their power.
        //          This ensures each unit of influence is counted exactly once (either directly or via a delegatee).
        for (uint256 i = 0; i < allNodeIds.length; i++) {
            uint256 tokenId = allNodeIds[i];
            if (nodeToDelegatee[tokenId] == 0) { // Only sum effective influence for "active" voters/delegatees
                collectiveInfluence += getEffectiveNodeInfluence(tokenId);
            }
        }
        
        emit EpochAdvanced(currentEpoch, collectiveXP, collectiveInfluence);
    }

    /**
     * @notice Returns the current epoch number.
     * @return The current epoch.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @notice Returns the total XP accumulated by all Nodes in the collective.
     * @return The total collective XP.
     */
    function getCollectiveXP() public view returns (uint256) {
        return collectiveXP;
    }

    /**
     * @notice Returns the total effective influence of all Nodes in the collective.
     * @dev This sum reflects the total available voting power for proposals.
     * @return The total collective influence.
     */
    function getCollectiveInfluence() public view returns (uint256) {
        return collectiveInfluence;
    }

    /**
     * @notice Sets the duration for each epoch.
     * @dev Only callable by the current owner (which can transition to being governed by proposals).
     * @param _duration The new epoch duration in seconds. Must be greater than 0.
     */
    function setEpochDuration(uint256 _duration) public virtual onlyOwner {
        require(_duration > 0, "EAC: Epoch duration must be positive");
        epochDuration = _duration;
    }

    /**
     * @notice Sets the multiplier for XP gain from contributions.
     * @dev Only callable by the current owner (governance).
     * @param _multiplier The new contribution multiplier. Must be greater than 0.
     */
    function setContributionMultiplier(uint256 _multiplier) public virtual onlyOwner {
        require(_multiplier > 0, "EAC: Multiplier must be positive");
        contributionMultiplier = _multiplier;
    }

    // --- V. Governance & Treasury ---

    /**
     * @notice Allows depositing funds into the collective treasury.
     * @dev Any user can deposit ETH to support the collective.
     */
    function depositFunds() public payable whenNotPaused {
        require(msg.value > 0, "EAC: Deposit amount must be greater than zero");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Returns the current balance of the collective treasury.
     * @return The treasury balance in wei.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Submits a new governance proposal.
     * @dev Anyone can submit a proposal. The proposal defines a target contract/address,
     *      a function to call (callData), an ETH value to send, and a minimum influence threshold for passing.
     * @param description A concise description of the proposal.
     * @param target The address of the contract or account the proposal aims to interact with.
     * @param callData The ABI-encoded function call to execute on the target.
     * @param value The amount of wei (ETH) to send with the execution call.
     * @param threshold The minimum total effective influence required for the proposal to be considered "Succeeded".
     * @return The ID of the newly created proposal.
     */
    function submitProposal(
        string calldata description,
        address target,
        bytes calldata callData,
        uint256 value,
        uint256 threshold
    ) public virtual whenNotPaused returns (uint256) {
        require(bytes(description).length > 0, "EAC: Proposal description cannot be empty");
        require(target != address(0), "EAC: Proposal target cannot be zero address");
        require(threshold > 0, "EAC: Proposal threshold must be positive");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            description: description,
            proposer: msg.sender,
            target: target,
            callData: callData,
            value: value,
            threshold: threshold,
            startTime: block.timestamp,
            votingPeriod: proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            canceled: false
        });

        emit ProposalSubmitted(proposalId, msg.sender, description, threshold);
        return proposalId;
    }

    /**
     * @notice Casts a vote on a proposal using a Node's effective influence.
     * @dev Only Nodes that are NOT delegating their influence can directly vote.
     *      Their effective influence (including influence delegated TO them) is used.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for' vote, false for 'against' vote.
     * @param tokenId The ID of the Node used to cast the vote. Must be owned by msg.sender.
     */
    function voteOnProposal(uint256 proposalId, bool support, uint256 tokenId) public virtual whenNotPaused onlyNodeOwner(tokenId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "EAC: Proposal does not exist");
        require(!proposal.executed, "EAC: Proposal already executed");
        require(!proposal.canceled, "EAC: Proposal canceled");
        require(block.timestamp >= proposal.startTime, "EAC: Voting has not started");
        require(block.timestamp < proposal.startTime + proposal.votingPeriod, "EAC: Voting period has ended");
        require(!proposal.hasVoted[tokenId], "EAC: Node has already voted on this proposal");
        require(nodeToDelegatee[tokenId] == 0, "EAC: This Node's influence is delegated, cannot vote directly"); // Only non-delegating nodes can vote

        uint256 effectiveInfluence = getEffectiveNodeInfluence(tokenId);
        require(effectiveInfluence > 0, "EAC: Node has no effective influence to vote");

        if (support) {
            proposal.votesFor += effectiveInfluence;
        } else {
            proposal.votesAgainst += effectiveInfluence;
        }
        proposal.hasVoted[tokenId] = true;

        emit VoteCast(proposalId, tokenId, support, effectiveInfluence);
    }

    /**
     * @notice Returns the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal as an enum (`ProposalState`).
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) {
            return ProposalState.Pending; // Represents non-existent proposal for consistency
        }
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (proposal.canceled) {
            return ProposalState.Canceled;
        }
        if (block.timestamp < proposal.startTime) {
            return ProposalState.Pending;
        }
        if (block.timestamp < proposal.startTime + proposal.votingPeriod) {
            return ProposalState.Active;
        }
        // Voting period ended, check results
        if (proposal.votesFor >= proposal.threshold && proposal.votesFor > proposal.votesAgainst) {
            return ProposalState.Succeeded;
        }
        if (proposal.votesFor < proposal.threshold || proposal.votesFor <= proposal.votesAgainst) {
            return ProposalState.Defeated;
        }
        return ProposalState.Expired; // Should not reach here if logic is correct
    }

    /**
     * @notice Returns the current vote counts (for and against) for a proposal.
     * @param proposalId The ID of the proposal.
     * @return votesFor_ The total influence accumulated for the proposal.
     * @return votesAgainst_ The total influence accumulated against the proposal.
     */
    function getProposalVotes(uint256 proposalId) public view returns (uint256 votesFor_, uint256 votesAgainst_) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "EAC: Proposal does not exist");
        return (proposal.votesFor, proposal.votesAgainst);
    }

    /**
     * @notice Executes a proposal that has succeeded.
     * @dev Can be called by anyone once the proposal is in the `Succeeded` state.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public virtual whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "EAC: Proposal does not exist");
        require(getProposalState(proposalId) == ProposalState.Succeeded, "EAC: Proposal not in succeeded state");
        require(!proposal.executed, "EAC: Proposal already executed");

        proposal.executed = true;

        // Perform the proposed action via a low-level call
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        require(success, "EAC: Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Allows the proposer or contract owner (governance) to cancel a proposal.
     * @dev A proposal can only be canceled if it's still `Pending` or `Active`.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 proposalId) public virtual whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "EAC: Proposal does not exist");
        require(msg.sender == proposal.proposer || msg.sender == owner(), "EAC: Not authorized to cancel proposal");
        require(getProposalState(proposalId) == ProposalState.Pending || getProposalState(proposalId) == ProposalState.Active, "EAC: Proposal not in cancellable state");
        require(!proposal.executed, "EAC: Proposal already executed");
        require(!proposal.canceled, "EAC: Proposal already canceled");

        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    // --- VI. AI Oracle Integration (Conceptual) ---

    /**
     * @notice Sets the trusted address for the AI oracle.
     * @dev Only callable by the current owner (governance). This address is used to verify `submitAICollectiveEvaluation` calls.
     * @param _aiOracle The address of the AI oracle. Must not be zero.
     */
    function setAIOracleAddress(address _aiOracle) public virtual onlyOwner {
        require(_aiOracle != address(0), "EAC: AI Oracle address cannot be zero");
        aiOracleAddress = _aiOracle;
    }

    /**
     * @notice Allows the designated AI oracle to submit a collective evaluation score.
     * @dev This score can be used to influence future collective decisions or metrics,
     *      or serve as an on-chain record of an off-chain AI analysis.
     * @param evaluationScore The score submitted by the AI oracle.
     */
    function submitAICollectiveEvaluation(uint256 evaluationScore) public virtual onlyAIOracle {
        latestAICollectiveEvaluation = evaluationScore;
        emit AICollectiveEvaluationSubmitted(msg.sender, evaluationScore);
    }

    /**
     * @notice Returns the latest collective evaluation score submitted by the AI oracle.
     * @return The latest AI collective evaluation score.
     */
    function getLatestAICollectiveEvaluation() public view returns (uint256) {
        return latestAICollectiveEvaluation;
    }

    // --- VII. Administrative/Utility ---

    /**
     * @notice Pauses certain contract functionalities.
     * @dev Only callable by the owner (governance). When paused, actions like minting, contributions, and voting are restricted.
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract functionalities.
     * @dev Only callable by the owner (governance).
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /**
     * @notice Overrides the ERC721 `_approve` function to incorporate the `whenNotPaused` modifier.
     * @dev Ensures that NFT approvals respect the contract's paused state.
     */
    function _approve(address to, uint256 tokenId) internal override whenNotPaused {
        super._approve(to, tokenId);
    }

    /**
     * @notice Overrides the ERC721 `_transfer` function to incorporate the `whenNotPaused` modifier
     *         and handle influence delegation upon transfer.
     * @dev If a Node is being transferred and it was delegating its influence,
     *      its delegation is automatically revoked to ensure correct influence accounting.
     *      The new owner would need to re-delegate if desired.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        // If the node being transferred was delegating its influence, undelegate it first.
        // This ensures the influence is removed from the old delegatee's sum.
        if (nodeToDelegatee[tokenId] != 0) {
            uint256 oldDelegatee = nodeToDelegatee[tokenId];
            uint256 nodeBaseInfluence = nodes[tokenId].influenceScore;

            delegateeToTotalDelegatedInfluence[oldDelegatee] -= nodeBaseInfluence;
            nodeToDelegatee[tokenId] = 0; // Clear delegation for the transferred node

            // The node's influence is now 'unassigned' from delegation pool, so it's effectively back to collective via itself
            collectiveInfluence -= nodeBaseInfluence; // remove from old delegatee's total
            collectiveInfluence += nodeBaseInfluence; // add back via its own potential direct voting power
        }
        super._transfer(from, to, tokenId);
    }
}
```