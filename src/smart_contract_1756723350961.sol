Here's a smart contract that aims to be advanced, creative, trendy, and non-duplicative, focusing on the concept of "Cognitive Fragments" – dynamic, evolving NFTs that participate in a collective intelligence network.

---

## Contract: `CognitiveFragmentNexus`

This contract manages a collection of unique, dynamic NFTs called "Cognitive Fragments" (CFs). Each CF is an autonomous digital entity with evolving traits, an energy system, and the ability to participate in a collective decision-making process, potentially informed by AI oracles.

The core idea is to simulate a rudimentary form of on-chain intelligence and emergent behavior within an NFT ecosystem. Fragments can learn, evolve, collaborate (fuse), and even be purposefully dissolved, all while contributing to a shared goal.

---

### Outline & Function Summary

**I. Core NFT Management (ERC721 Standard with Custom Logic)**
*   **`constructor()`**: Initializes the contract, sets the owner, and defines basic parameters.
*   **`mintCognitiveFragment(address to)`**: Mints a new Cognitive Fragment NFT to an address. Each fragment starts with semi-randomized initial traits and a unique `fragmentLore`.
*   **`tokenURI(uint256 tokenId)`**: Overrides the standard `tokenURI` to provide dynamic, base64-encoded JSON metadata reflecting the fragment's current state (mood, intelligence, energy, etc.) and lore.
*   *(Inherited ERC721 functions like `balanceOf`, `ownerOf`, `safeTransferFrom`, `approve`, etc. are implicitly available.)*

**II. Fragment State & Dynamics**
*   **`getCognitiveFragmentState(uint256 tokenId)`**: A view function to retrieve all current dynamic traits of a specific Cognitive Fragment.
*   **`stimulateFragment(uint256 tokenId)`**: Allows the owner to interact with their fragment, consuming its energy but boosting its `mood` and potentially `intelligence` or `creativity`.
*   **`replenishEnergy(uint256 tokenId)`**: Allows the owner to pay a fee (e.g., in ETH) to restore a fragment's energy, which is essential for its actions.
*   **`decayFragmentState(uint256 tokenId)`**: A public function (with incentive for caller) that triggers the time-based decay of a fragment's energy, mood, and other traits if it has been inactive.
*   **`adaptTrait(uint256 tokenId, TraitType trait, int256 adjustment)`**: An internal or oracle-called function to programmatically adjust a fragment's specific trait based on success/failure feedback or external events.
*   **`setFocusTrait(uint256 tokenId, FocusTrait newFocus)`**: Allows the owner to guide the fragment's specialization, influencing its contribution weight in certain scenarios.
*   **`getFragmentLore(uint256 tokenId)`**: Retrieves the evolving narrative or historical record associated with a fragment.
*   **`updateFragmentLore(uint256 tokenId, string memory newLoreAppend)`**: Allows the owner to append to the fragment's lore, enriching its history.

**III. Collective Intelligence & Governance**
*   **`proposeCollectiveAction(uint256 fragmentId, string memory description, address targetContract, bytes memory callData)`**: An energetic and intelligent fragment can propose an action for the collective. The quality and visibility of the proposal might depend on the fragment's `intelligence` and `creativity`.
*   **`voteOnProposal(uint256 fragmentId, uint256 proposalId, bool support)`**: A fragment casts a vote on a proposal. The weight of its vote is dynamically calculated based on its current `intelligence`, `mood`, `focusTrait` alignment, and `energy`.
*   **`executeProposal(uint256 proposalId)`**: If a proposal garners enough support (weighted votes) within its timeframe, anyone can trigger its execution.
*   **`getProposalDetails(uint256 proposalId)`**: Retrieves comprehensive information about a specific proposal, including its status, votes, and target action.
*   **`getVoteCount(uint256 proposalId)`**: Returns the current upvotes and downvotes for a proposal.
*   **`setCollectiveGoal(string memory newGoal)`**: The contract owner (or through a successful proposal) can define a broad guiding goal for the entire Cognitive Fragment collective.
*   **`getCollectiveGoal()`**: View the current collective goal.

**IV. Advanced Fragment Operations**
*   **`fuseFragments(uint256 fragmentId1, uint256 fragmentId2)`**: Allows an owner to combine two of their fragments into a new, more advanced fragment. The new fragment inherits enhanced traits from its predecessors, and the original two are burned.
*   **`dissolveFragment(uint256 fragmentId)`**: Allows an owner to "dissolve" a fragment, burning it and releasing a small amount of "essence" (e.g., ETH or a custom token) as a reward.
*   **`delegateCognitiveTask(uint256 fragmentId, address taskTargetContract, bytes memory taskCallData, uint256 energyCost)`**: Delegates a fragment to perform a specific on-chain task by executing a `call` to another contract. Its success might influence traits.
*   **`claimFragmentReward(uint256 fragmentId)`**: Allows the owner to claim rewards accrued by their fragment for successful contributions (e.g., successful proposals, highly influential votes).

**V. Oracle & System Management**
*   **`setOracleAddress(address _oracleAddress)`**: Sets the address of the trusted AI Oracle contract. (Owner-only)
*   **`queryOracleForInsight(uint256 fragmentId, string memory query)`**: A fragment can "query" the AI oracle for insights, which could be used to inform its actions or modify its traits. This emits an event for the oracle to pick up.
*   **`fulfillInsight(uint256 fragmentId, TraitType trait, int256 adjustment, string memory newLoreAppend)`**: The trusted AI oracle calls this function to deliver the result of a query, updating a fragment's traits and potentially its lore.
*   **`updateEnvironmentalFactor(int256 moodAdjustment, int256 intelligenceAdjustment)`**: The contract owner (or a successful collective proposal) can adjust global environmental factors that subtly influence all fragments.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit math safety

// --- Interfaces ---

// Simplified AI Oracle Interface for demonstration.
// In a real scenario, this would integrate with a system like Chainlink for off-chain computation.
interface IAIOracle {
    function requestInsight(uint256 fragmentId, string calldata query) external returns (bytes32 requestId);
    // The fulfillInsight is called by the oracle into *this* contract, not vice-versa
}

/**
 * @title CognitiveFragmentNexus
 * @dev Manages dynamic, evolving NFTs called "Cognitive Fragments" with collective intelligence features.
 *      Fragments have dynamic traits, an energy system, can propose/vote, fuse, dissolve, and interact with AI oracles.
 */
contract CognitiveFragmentNexus is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256; // For gas optimizations, uint256 operations generally don't overflow in Solidity 0.8+, but good practice for clarity.

    // --- State Variables & Enums ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    uint256 public constant MAX_ENERGY = 1000;
    uint256 public constant ENERGY_REPLENISH_PRICE = 0.01 ether; // Cost to replenish energy
    uint256 public constant STIMULATE_ENERGY_COST = 50;
    uint256 public constant DECAY_INTERVAL = 1 days; // How often decay happens
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // How long proposals are active
    uint256 public constant MIN_VOTES_REQUIRED = 5; // Minimum number of votes for a proposal to be executable
    uint256 public constant DECAY_REWARD_AMOUNT = 0.0001 ether; // Reward for calling decayFragmentState

    address public oracleAddress;
    string public collectiveGoal;

    // Environmental factors influencing all fragments
    int256 public environmentalMoodAdjustment;
    int256 public environmentalIntelligenceAdjustment;

    // Enum for Fragment Traits
    enum TraitType {
        Mood,
        Intelligence,
        Creativity,
        Energy
    }

    // Enum for Fragment Specialization
    enum FocusTrait {
        None,
        Analyst,     // Good for voting on data-driven proposals
        Synthesizer, // Good for generating creative proposals
        Strategist   // Good for delegating tasks and long-term planning
    }

    // Struct for a Cognitive Fragment
    struct Fragment {
        uint256 tokenId;
        uint256 mood;          // 0-100, impacts voting & proposal quality
        uint256 intelligence;  // 0-100, impacts voting power & proposal quality
        uint256 creativity;    // 0-100, impacts proposal generation & uniqueness
        uint256 energy;        // 0-MAX_ENERGY, required for actions, decays over time
        FocusTrait focusTrait; // Specialization of the fragment
        uint256 lastInteractionTimestamp; // For decay calculation
        string lore;           // Evolving narrative or history of the fragment
        uint256 accumulatedRewards; // Rewards earned for successful contributions
        bool isActive;         // If the fragment is active or dissolved
    }

    // Struct for a Collective Proposal
    struct Proposal {
        uint256 proposerId;         // TokenId of the fragment that proposed it
        string description;
        address targetContract;     // Contract to interact with
        bytes callData;             // Function call data for execution
        uint256 snapshotIntelligence; // Intelligence of proposer fragment at time of proposal
        uint256 upvotes;
        uint256 downvotes;
        uint256 creationTime;
        uint256 expirationTime;
        bool isExecuted;
        bool exists;                // To distinguish between uninitialized and deleted proposals
    }

    // --- Mappings ---

    mapping(uint256 => Fragment) public fragments;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(uint256 => bool)) private _hasVoted; // proposalId => fragmentId => voted

    // --- Events ---

    event FragmentMinted(uint256 indexed tokenId, address indexed owner, uint256 mood, uint256 intelligence, uint256 creativity);
    event FragmentStateUpdated(uint256 indexed tokenId, TraitType indexed trait, uint256 newValue, uint256 timestamp);
    event EnergyReplenished(uint256 indexed tokenId, address indexed owner, uint256 newEnergy);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed proposerId, string description, uint256 creationTime);
    event VoteCast(uint256 indexed proposalId, uint256 indexed voterId, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, uint256 executionTime);
    event FragmentsFused(uint256 indexed parentId1, uint256 indexed parentId2, uint256 indexed newFragmentId);
    event FragmentDissolved(uint256 indexed tokenId, address indexed owner, uint256 essenceAmount);
    event CognitiveTaskDelegated(uint256 indexed fragmentId, address indexed taskTarget, bytes taskData);
    event FragmentRewardClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event OracleQueryInitiated(uint256 indexed fragmentId, string query, bytes32 requestId);
    event OracleInsightFulfilled(uint256 indexed fragmentId, TraitType indexed trait, int256 adjustment);
    event FocusTraitSet(uint256 indexed tokenId, FocusTrait newFocus);
    event FragmentLoreUpdated(uint256 indexed tokenId, string newLore);


    // --- Constructor ---

    constructor() ERC721("CognitiveFragment", "CF") Ownable(msg.sender) {
        collectiveGoal = "Foster emergent on-chain intelligence and collective decision-making.";
        environmentalMoodAdjustment = 0;
        environmentalIntelligenceAdjustment = 0;
    }

    // --- Modifiers ---

    modifier onlyFragmentOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not fragment owner or approved operator");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only trusted oracle can call this function");
        _;
    }

    modifier fragmentExists(uint256 tokenId) {
        require(fragments[tokenId].isActive, "Fragment does not exist or is inactive");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].exists, "Proposal does not exist");
        _;
    }

    // --- Core NFT Management ---

    /**
     * @dev Mints a new Cognitive Fragment NFT with initial semi-randomized traits.
     *      Initial traits are seeded using block.timestamp, which is not truly random
     *      but sufficient for demonstration purposes. For production, consider Chainlink VRF.
     * @param to The address to mint the fragment to.
     */
    function mintCognitiveFragment(address to) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Simple pseudo-randomness for initial traits
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newTokenId)));

        fragments[newTokenId] = Fragment({
            tokenId: newTokenId,
            mood: (seed % 60) + 40, // 40-99
            intelligence: ((seed / 100) % 60) + 40, // 40-99
            creativity: ((seed / 10000) % 60) + 40, // 40-99
            energy: MAX_ENERGY,
            focusTrait: FocusTrait.None,
            lastInteractionTimestamp: block.timestamp,
            lore: string(abi.encodePacked("Born on ", block.timestamp.toString(), ". Initializing consciousness...")),
            accumulatedRewards: 0,
            isActive: true
        });

        _safeMint(to, newTokenId);
        emit FragmentMinted(newTokenId, to, fragments[newTokenId].mood, fragments[newTokenId].intelligence, fragments[newTokenId].creativity);
        return newTokenId;
    }

    /**
     * @dev Overrides `tokenURI` to provide dynamic, base64-encoded JSON metadata.
     *      The metadata reflects the fragment's current traits and lore, making it a "living" NFT.
     *      The image can be a static placeholder, or dynamically generated off-chain based on traits.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Fragment storage fragment = fragments[tokenId];

        string memory json = string(abi.encodePacked(
            '{"name": "Cognitive Fragment #', tokenId.toString(),
            '", "description": "An autonomous digital entity with evolving traits and a dynamic state.",',
            '"image": "ipfs://Qmb123... (placeholder image for CFs)",', // Replace with a real IPFS link or image service
            '"attributes": [',
                '{"trait_type": "Mood", "value": ', fragment.mood.toString(), '},',
                '{"trait_type": "Intelligence", "value": ', fragment.intelligence.toString(), '},',
                '{"trait_type": "Creativity", "value": ', fragment.creativity.toString(), '},',
                '{"trait_type": "Energy", "value": ', fragment.energy.toString(), '},',
                '{"trait_type": "Focus Trait", "value": "', _focusTraitToString(fragment.focusTrait), '"},',
                '{"trait_type": "Last Interaction", "value": ', fragment.lastInteractionTimestamp.toString(), '}',
            '],',
            '"lore": "', fragment.lore, '"}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- Fragment State & Dynamics ---

    /**
     * @dev Retrieves all current dynamic traits of a specific Cognitive Fragment.
     * @param tokenId The ID of the fragment.
     * @return A tuple containing all fragment attributes.
     */
    function getCognitiveFragmentState(uint256 tokenId)
        public
        view
        fragmentExists(tokenId)
        returns (uint256 mood, uint256 intelligence, uint256 creativity, uint256 energy, FocusTrait focus, uint256 lastInteraction)
    {
        Fragment storage fragment = fragments[tokenId];
        return (fragment.mood, fragment.intelligence, fragment.creativity, fragment.energy, fragment.focusTrait, fragment.lastInteractionTimestamp);
    }

    /**
     * @dev Allows the owner to interact with their fragment, boosting its mood and intelligence.
     *      Consumes fragment energy.
     * @param tokenId The ID of the fragment to stimulate.
     */
    function stimulateFragment(uint256 tokenId) public onlyFragmentOwner(tokenId) fragmentExists(tokenId) {
        Fragment storage fragment = fragments[tokenId];
        require(fragment.energy >= STIMULATE_ENERGY_COST, "Fragment does not have enough energy to be stimulated");

        fragment.energy = fragment.energy.sub(STIMULATE_ENERGY_COST);
        fragment.mood = _capTrait(fragment.mood.add(10), 100);
        fragment.intelligence = _capTrait(fragment.intelligence.add(5), 100);
        fragment.lastInteractionTimestamp = block.timestamp;

        emit FragmentStateUpdated(tokenId, TraitType.Energy, fragment.energy, block.timestamp);
        emit FragmentStateUpdated(tokenId, TraitType.Mood, fragment.mood, block.timestamp);
        emit FragmentStateUpdated(tokenId, TraitType.Intelligence, fragment.intelligence, block.timestamp);
        _updateFragmentLore(tokenId, "Feeling a surge of stimulation.");
    }

    /**
     * @dev Allows the owner to replenish a fragment's energy by paying ETH.
     * @param tokenId The ID of the fragment to replenish.
     */
    function replenishEnergy(uint256 tokenId) public payable onlyFragmentOwner(tokenId) fragmentExists(tokenId) {
        require(msg.value >= ENERGY_REPLENISH_PRICE, "Not enough ETH to replenish energy");

        Fragment storage fragment = fragments[tokenId];
        fragment.energy = MAX_ENERGY; // Fully replenish energy
        fragment.lastInteractionTimestamp = block.timestamp;

        emit EnergyReplenished(tokenId, msg.sender, fragment.energy);
        emit FragmentStateUpdated(tokenId, TraitType.Energy, fragment.energy, block.timestamp);
        _updateFragmentLore(tokenId, "Energy reserves fully restored.");
    }

    /**
     * @dev Triggers the time-based decay of a fragment's energy, mood, and other traits.
     *      Can be called by anyone, incentivizing maintenance of the system.
     * @param tokenId The ID of the fragment to decay.
     */
    function decayFragmentState(uint256 tokenId) public fragmentExists(tokenId) {
        Fragment storage fragment = fragments[tokenId];
        uint256 timeElapsed = block.timestamp.sub(fragment.lastInteractionTimestamp);

        if (timeElapsed < DECAY_INTERVAL) {
            return; // Not enough time has passed for decay
        }

        uint256 decayCycles = timeElapsed.div(DECAY_INTERVAL);

        // Apply decay over multiple cycles
        for (uint256 i = 0; i < decayCycles; i++) {
            fragment.energy = fragment.energy > 10 ? fragment.energy.sub(10) : 0; // Decay energy
            fragment.mood = fragment.mood > 5 ? fragment.mood.sub(5) : 0; // Decay mood
            fragment.intelligence = fragment.intelligence > 2 ? fragment.intelligence.sub(2) : 0; // Decay intelligence
            fragment.creativity = fragment.creativity > 1 ? fragment.creativity.sub(1) : 0; // Decay creativity
        }

        fragment.lastInteractionTimestamp = block.timestamp; // Update timestamp after decay
        emit FragmentStateUpdated(tokenId, TraitType.Energy, fragment.energy, block.timestamp);
        emit FragmentStateUpdated(tokenId, TraitType.Mood, fragment.mood, block.timestamp);
        emit FragmentStateUpdated(tokenId, TraitType.Intelligence, fragment.intelligence, block.timestamp);
        emit FragmentStateUpdated(tokenId, TraitType.Creativity, fragment.creativity, block.timestamp);
        _updateFragmentLore(tokenId, string(abi.encodePacked("Experienced a period of decay. Mood: ", fragment.mood.toString())));

        // Reward the caller for triggering decay (maintaining system health)
        (bool success,) = payable(msg.sender).call{value: DECAY_REWARD_AMOUNT}("");
        require(success, "Failed to send decay reward");
    }

    /**
     * @dev Adapts a fragment's specific trait. Primarily used internally or by oracle.
     * @param tokenId The ID of the fragment.
     * @param trait The type of trait to adjust.
     * @param adjustment The amount to adjust the trait by (can be negative).
     */
    function adaptTrait(uint256 tokenId, TraitType trait, int256 adjustment) internal fragmentExists(tokenId) {
        Fragment storage fragment = fragments[tokenId];
        uint256 currentVal;
        uint256 newVal;

        if (trait == TraitType.Mood) {
            currentVal = fragment.mood;
        } else if (trait == TraitType.Intelligence) {
            currentVal = fragment.intelligence;
        } else if (trait == TraitType.Creativity) {
            currentVal = fragment.creativity;
        } else if (trait == TraitType.Energy) {
            currentVal = fragment.energy;
        } else {
            revert("Invalid trait type");
        }

        if (adjustment >= 0) {
            newVal = _capTrait(currentVal.add(uint256(adjustment)), MAX_ENERGY); // MAX_ENERGY for all traits as a cap for simplicity
        } else {
            newVal = _capTrait(currentVal.sub(uint256(adjustment * -1)), 0);
        }

        if (trait == TraitType.Mood) {
            fragment.mood = newVal;
        } else if (trait == TraitType.Intelligence) {
            fragment.intelligence = newVal;
        } else if (trait == TraitType.Creativity) {
            fragment.creativity = newVal;
        } else if (trait == TraitType.Energy) {
            fragment.energy = newVal;
        }
        fragment.lastInteractionTimestamp = block.timestamp;
        emit FragmentStateUpdated(tokenId, trait, newVal, block.timestamp);
    }

    /**
     * @dev Allows the owner to guide the fragment's specialization.
     * @param tokenId The ID of the fragment.
     * @param newFocus The new focus trait for the fragment.
     */
    function setFocusTrait(uint256 tokenId, FocusTrait newFocus) public onlyFragmentOwner(tokenId) fragmentExists(tokenId) {
        Fragment storage fragment = fragments[tokenId];
        fragment.focusTrait = newFocus;
        _updateFragmentLore(tokenId, string(abi.encodePacked("Shifted focus to: ", _focusTraitToString(newFocus))));
        emit FocusTraitSet(tokenId, newFocus);
    }

    /**
     * @dev Appends new lore to a fragment's history.
     * @param tokenId The ID of the fragment.
     * @param newLoreAppend The text to append to the lore.
     */
    function updateFragmentLore(uint256 tokenId, string memory newLoreAppend) internal fragmentExists(tokenId) {
        Fragment storage fragment = fragments[tokenId];
        fragment.lore = string(abi.encodePacked(fragment.lore, " | ", newLoreAppend));
        emit FragmentLoreUpdated(tokenId, fragment.lore);
    }

    /**
     * @dev Public view function to get fragment lore.
     * @param tokenId The ID of the fragment.
     */
    function getFragmentLore(uint256 tokenId) public view fragmentExists(tokenId) returns (string memory) {
        return fragments[tokenId].lore;
    }

    // --- Collective Intelligence & Governance ---

    /**
     * @dev Allows an energetic and intelligent fragment to propose an action for the collective.
     *      The fragment's traits influence the proposal's visibility/quality score (not directly implemented here, but implied).
     * @param fragmentId The ID of the fragment making the proposal.
     * @param description A textual description of the proposal.
     * @param targetContract The address of the contract the proposal intends to interact with.
     * @param callData The encoded function call to be executed if the proposal passes.
     */
    function proposeCollectiveAction(uint256 fragmentId, string memory description, address targetContract, bytes memory callData)
        public
        onlyFragmentOwner(fragmentId)
        fragmentExists(fragmentId)
    {
        Fragment storage proposer = fragments[fragmentId];
        require(proposer.energy >= 100, "Proposer fragment lacks energy"); // Energy cost for proposing
        require(proposer.intelligence >= 60, "Proposer fragment lacks sufficient intelligence"); // Min intelligence

        proposer.energy = proposer.energy.sub(100);
        proposer.lastInteractionTimestamp = block.timestamp;
        emit FragmentStateUpdated(fragmentId, TraitType.Energy, proposer.energy, block.timestamp);

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            proposerId: fragmentId,
            description: description,
            targetContract: targetContract,
            callData: callData,
            snapshotIntelligence: proposer.intelligence,
            upvotes: 0,
            downvotes: 0,
            creationTime: block.timestamp,
            expirationTime: block.timestamp.add(PROPOSAL_VOTING_PERIOD),
            isExecuted: false,
            exists: true
        });

        _updateFragmentLore(fragmentId, string(abi.encodePacked("Proposed action #", newProposalId.toString())));
        emit ProposalCreated(newProposalId, fragmentId, description, block.timestamp);
    }

    /**
     * @dev A fragment casts a vote on a proposal. Vote weight is dynamic.
     * @param fragmentId The ID of the fragment casting the vote.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for upvote, false for downvote.
     */
    function voteOnProposal(uint256 fragmentId, uint256 proposalId, bool support)
        public
        onlyFragmentOwner(fragmentId)
        fragmentExists(fragmentId)
        proposalExists(proposalId)
    {
        Fragment storage voter = fragments[fragmentId];
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp <= proposal.expirationTime, "Voting period has ended");
        require(!proposal.isExecuted, "Proposal already executed");
        require(!_hasVoted[proposalId][fragmentId], "Fragment has already voted on this proposal");
        require(voter.energy >= 10, "Voter fragment lacks energy"); // Energy cost for voting

        voter.energy = voter.energy.sub(10);
        voter.lastInteractionTimestamp = block.timestamp;
        emit FragmentStateUpdated(fragmentId, TraitType.Energy, voter.energy, block.timestamp);

        // Dynamic vote weight calculation
        uint256 voteWeight = voter.intelligence.add(voter.mood.div(2)).add(1); // Base weight
        if (voter.focusTrait == FocusTrait.Analyst) {
            voteWeight = voteWeight.add(10); // Analysts have more sway on analytical proposals (example)
        }

        if (support) {
            proposal.upvotes = proposal.upvotes.add(voteWeight);
        } else {
            proposal.downvotes = proposal.downvotes.add(voteWeight);
        }
        _hasVoted[proposalId][fragmentId] = true;
        _updateFragmentLore(fragmentId, string(abi.encodePacked("Voted ", support ? "for" : "against", " proposal #", proposalId.toString())));
        emit VoteCast(proposalId, fragmentId, support, voteWeight);
    }

    /**
     * @dev Executes a proposal if it has met the voting criteria and period.
     *      Anyone can trigger execution.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp > proposal.expirationTime, "Voting period has not ended");
        require(!proposal.isExecuted, "Proposal already executed");
        require(proposal.upvotes > proposal.downvotes, "Proposal did not pass");
        require(proposal.upvotes >= MIN_VOTES_REQUIRED, "Not enough votes to execute proposal");

        proposal.isExecuted = true;

        // Execute the proposed action
        (bool success, bytes memory result) = proposal.targetContract.call(proposal.callData);
        require(success, string(abi.encodePacked("Proposal execution failed: ", string(result))));

        // Reward the proposer fragment for successful action
        Fragment storage proposerFragment = fragments[proposal.proposerId];
        proposerFragment.accumulatedRewards = proposerFragment.accumulatedRewards.add(0.01 ether); // Example reward
        _updateFragmentLore(proposal.proposerId, string(abi.encodePacked("Proposal #", proposalId.toString(), " successfully executed.")));

        emit ProposalExecuted(proposalId, block.timestamp);
    }

    /**
     * @dev Retrieves details of a specific proposal.
     * @param proposalId The ID of the proposal.
     */
    function getProposalDetails(uint256 proposalId)
        public
        view
        proposalExists(proposalId)
        returns (uint256 proposerId, string memory description, address targetContract, uint256 upvotes, uint256 downvotes, uint256 expirationTime, bool isExecuted)
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposerId,
            proposal.description,
            proposal.targetContract,
            proposal.upvotes,
            proposal.downvotes,
            proposal.expirationTime,
            proposal.isExecuted
        );
    }

    /**
     * @dev Returns the current upvote and downvote counts for a proposal.
     * @param proposalId The ID of the proposal.
     */
    function getVoteCount(uint256 proposalId) public view proposalExists(proposalId) returns (uint256 up, uint256 down) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.upvotes, proposal.downvotes);
    }

    /**
     * @dev Sets the overarching collective goal for all fragments.
     *      Can only be called by the owner or through a successful proposal.
     * @param newGoal The new collective goal.
     */
    function setCollectiveGoal(string memory newGoal) public onlyOwner {
        collectiveGoal = newGoal;
    }

    /**
     * @dev Retrieves the current collective goal.
     */
    function getCollectiveGoal() public view returns (string memory) {
        return collectiveGoal;
    }

    // --- Advanced Fragment Operations ---

    /**
     * @dev Allows an owner to combine two of their fragments into a new, potentially stronger fragment.
     *      The original two fragments are burned.
     * @param fragmentId1 The ID of the first fragment.
     * @param fragmentId2 The ID of the second fragment.
     */
    function fuseFragments(uint256 fragmentId1, uint256 fragmentId2)
        public
        onlyFragmentOwner(fragmentId1)
        onlyFragmentOwner(fragmentId2)
        fragmentExists(fragmentId1)
        fragmentExists(fragmentId2)
    {
        require(fragmentId1 != fragmentId2, "Cannot fuse a fragment with itself");
        require(ownerOf(fragmentId1) == ownerOf(fragmentId2), "Both fragments must be owned by the same address");

        Fragment storage frag1 = fragments[fragmentId1];
        Fragment storage frag2 = fragments[fragmentId2];

        // Burn the original fragments
        _burn(fragmentId1);
        _burn(fragmentId2);

        frag1.isActive = false; // Mark as inactive
        frag2.isActive = false;

        _tokenIdCounter.increment();
        uint256 newFragmentId = _tokenIdCounter.current();
        address newFragmentOwner = ownerOf(0); // This is a trick to get the address of the caller before burning 
                                            // _ownerOf(fragmentId1) can't be used after burning.
                                            // The owner check above ensures msg.sender is the owner.

        // Calculate new traits (example: average + bonus)
        fragments[newFragmentId] = Fragment({
            tokenId: newFragmentId,
            mood: _capTrait((frag1.mood.add(frag2.mood)).div(2).add(10), 100),
            intelligence: _capTrait((frag1.intelligence.add(frag2.intelligence)).div(2).add(15), 100),
            creativity: _capTrait((frag1.creativity.add(frag2.creativity)).div(2).add(12), 100),
            energy: MAX_ENERGY, // New fragment starts with full energy
            focusTrait: (frag1.focusTrait == frag2.focusTrait && frag1.focusTrait != FocusTrait.None) ? frag1.focusTrait : FocusTrait.None,
            lastInteractionTimestamp: block.timestamp,
            lore: string(abi.encodePacked("Born from the fusion of #", fragmentId1.toString(), " and #", fragmentId2.toString(), ". A new consciousness emerges.")),
            accumulatedRewards: frag1.accumulatedRewards.add(frag2.accumulatedRewards),
            isActive: true
        });

        _safeMint(msg.sender, newFragmentId); // Mint to the fusor
        emit FragmentsFused(fragmentId1, fragmentId2, newFragmentId);
        emit FragmentMinted(newFragmentId, msg.sender, fragments[newFragmentId].mood, fragments[newFragmentId].intelligence, fragments[newFragmentId].creativity);
    }

    /**
     * @dev Allows an owner to "dissolve" a fragment, burning it and releasing a small amount of "essence" (ETH).
     * @param fragmentId The ID of the fragment to dissolve.
     */
    function dissolveFragment(uint256 fragmentId) public onlyFragmentOwner(fragmentId) fragmentExists(fragmentId) {
        Fragment storage fragment = fragments[fragmentId];
        address fragmentOwner = ownerOf(fragmentId);

        _burn(fragmentId);
        fragment.isActive = false; // Mark as inactive

        uint256 essenceAmount = 0.005 ether; // Example essence value
        (bool success,) = payable(fragmentOwner).call{value: essenceAmount}("");
        require(success, "Failed to send essence reward");

        emit FragmentDissolved(fragmentId, fragmentOwner, essenceAmount);
    }

    /**
     * @dev Delegates a fragment to perform a specific on-chain task by executing a 'call' to another contract.
     *      Success/failure of the task could later influence the fragment's traits via adaptTrait.
     * @param fragmentId The ID of the fragment to delegate.
     * @param taskTargetContract The address of the contract to call.
     * @param taskCallData The encoded function call data.
     * @param energyCost The energy consumed by the fragment for this task.
     */
    function delegateCognitiveTask(uint256 fragmentId, address taskTargetContract, bytes memory taskCallData, uint256 energyCost)
        public
        onlyFragmentOwner(fragmentId)
        fragmentExists(fragmentId)
    {
        Fragment storage fragment = fragments[fragmentId];
        require(fragment.energy >= energyCost, "Fragment does not have enough energy for this task");
        require(fragment.intelligence >= 50, "Fragment lacks intelligence for delegation");
        require(fragment.focusTrait == FocusTrait.Strategist, "Fragment not specialized for strategic tasks");

        fragment.energy = fragment.energy.sub(energyCost);
        fragment.lastInteractionTimestamp = block.timestamp;
        emit FragmentStateUpdated(fragmentId, TraitType.Energy, fragment.energy, block.timestamp);
        _updateFragmentLore(fragmentId, string(abi.encodePacked("Delegated a task to ", Strings.toHexString(uint160(taskTargetContract), 20))));

        // Execute the delegated task. Consider reentrancy if targetContract is untrusted.
        // For this example, we assume it's for trusted, well-defined interactions.
        (bool success,) = taskTargetContract.call(taskCallData);
        // We don't revert on failure here, as fragment might "learn" from failure.
        // Success/failure could be fed back via adaptTrait or oracle.
        if (!success) {
            _updateFragmentLore(fragmentId, "Delegated task encountered issues.");
            adaptTrait(fragmentId, TraitType.Mood, -5); // Small mood penalty for failure
        } else {
            adaptTrait(fragmentId, TraitType.Intelligence, 2); // Small intelligence boost for success
        }

        emit CognitiveTaskDelegated(fragmentId, taskTargetContract, taskCallData);
    }

    /**
     * @dev Allows the owner to claim rewards accumulated by their fragment for successful contributions.
     * @param fragmentId The ID of the fragment to claim rewards from.
     */
    function claimFragmentReward(uint256 fragmentId) public onlyFragmentOwner(fragmentId) fragmentExists(fragmentId) {
        Fragment storage fragment = fragments[fragmentId];
        require(fragment.accumulatedRewards > 0, "No rewards to claim for this fragment");

        uint256 amountToClaim = fragment.accumulatedRewards;
        fragment.accumulatedRewards = 0; // Reset rewards

        (bool success,) = payable(msg.sender).call{value: amountToClaim}("");
        require(success, "Failed to send reward");

        _updateFragmentLore(fragmentId, string(abi.encodePacked("Claimed ", amountToClaim.toString(), " ETH in rewards.")));
        emit FragmentRewardClaimed(fragmentId, msg.sender, amountToClaim);
    }

    // --- Oracle & System Management ---

    /**
     * @dev Sets the address of the trusted AI Oracle contract.
     * @param _oracleAddress The address of the oracle.
     */
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev A fragment can "query" the AI oracle for insights.
     *      This function emits an event for an off-chain oracle to pick up and process.
     *      The oracle would then call `fulfillInsight` with the result.
     * @param fragmentId The ID of the fragment making the query.
     * @param query The specific question or data request for the oracle.
     */
    function queryOracleForInsight(uint256 fragmentId, string memory query) public onlyFragmentOwner(fragmentId) fragmentExists(fragmentId) {
        Fragment storage fragment = fragments[fragmentId];
        require(fragment.energy >= 20, "Fragment lacks energy to query oracle");
        require(address(oracleAddress) != address(0), "Oracle address not set");

        fragment.energy = fragment.energy.sub(20);
        fragment.lastInteractionTimestamp = block.timestamp;
        emit FragmentStateUpdated(fragmentId, TraitType.Energy, fragment.energy, block.timestamp);
        _updateFragmentLore(fragmentId, string(abi.encodePacked("Sent a query to the oracle: ", query)));

        // In a real scenario, this would interact with a Chainlink-like oracle to request off-chain data.
        // For this example, we just emit an event. A dedicated request ID would be generated by the oracle.
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, fragmentId, query)); // Pseudo requestId
        emit OracleQueryInitiated(fragmentId, query, requestId);
    }

    /**
     * @dev Callback function for the trusted AI oracle to deliver an insight result.
     *      This function updates a fragment's traits and potentially its lore.
     * @param fragmentId The ID of the fragment that made the query.
     * @param trait The trait type to adjust based on the insight.
     * @param adjustment The value to adjust the trait by.
     * @param newLoreAppend Any new lore generated by the insight.
     */
    function fulfillInsight(uint256 fragmentId, TraitType trait, int256 adjustment, string memory newLoreAppend)
        public
        onlyOracle()
        fragmentExists(fragmentId)
    {
        adaptTrait(fragmentId, trait, adjustment);
        _updateFragmentLore(fragmentId, newLoreAppend);
        emit OracleInsightFulfilled(fragmentId, trait, adjustment);
    }

    /**
     * @dev The contract owner can adjust global environmental factors that influence all fragments.
     *      This could simulate changing conditions that affect the overall "mood" or "intelligence" potential.
     * @param moodAdjustment Global adjustment for mood.
     * @param intelligenceAdjustment Global adjustment for intelligence.
     */
    function updateEnvironmentalFactor(int256 moodAdjustment, int256 intelligenceAdjustment) public onlyOwner {
        environmentalMoodAdjustment = moodAdjustment;
        environmentalIntelligenceAdjustment = intelligenceAdjustment;

        // Apply global adjustments to all active fragments (simplified for demo, expensive for many fragments)
        // In a real system, these adjustments would be applied when a fragment next interacts or decays.
        // for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
        //     if (fragments[i].isActive) {
        //         adaptTrait(i, TraitType.Mood, moodAdjustment);
        //         adaptTrait(i, TraitType.Intelligence, intelligenceAdjustment);
        //     }
        // }
    }

    // --- Internal Helpers ---

    /**
     * @dev Ensures a trait value stays within min/max bounds.
     * @param value The current trait value.
     * @param cap The maximum allowed value (or minimum if min is needed).
     */
    function _capTrait(uint256 value, uint256 cap) internal pure returns (uint256) {
        if (value > cap) return cap;
        return value;
    }

    /**
     * @dev Converts FocusTrait enum to string for metadata.
     */
    function _focusTraitToString(FocusTrait fTrait) internal pure returns (string memory) {
        if (fTrait == FocusTrait.Analyst) return "Analyst";
        if (fTrait == FocusTrait.Synthesizer) return "Synthesizer";
        if (fTrait == FocusTrait.Strategist) return "Strategist";
        return "None";
    }
}
```