Okay, let's design a smart contract that combines several advanced concepts: a Decentralized Autonomous Organization (DAO) where members are represented by dynamic Non-Fungible Tokens (NFTs), and the collective actions of the DAO influence the traits of these NFTs and the overall "Swarm" state, simulating a form of on-chain evolution or adaptation.

This concept, let's call it `EvolutionaryDAOSwarm`, is unique because it tightly couples governance, individual member identity (NFTs), and collective state change (evolution/adaptation) directly on-chain based on successful proposals and a simulated epoch system.

Here's the outline and function summary, followed by the Solidity code.

---

**Outline and Function Summary for EvolutionaryDAOSwarm**

**Concept Name:** Evolutionary DAO Swarm

**Core Idea:** A DAO where members hold dynamic NFTs. These NFTs have traits that evolve based on successful collective proposals and global "Swarm" parameters that change over time (epochs). The DAO governs its resources, rules, and evolutionary trajectory through proposals.

**Key Components:**
1.  **Swarm Members:** ERC721 NFTs. Each NFT represents a unique member identity.
2.  **Member Traits:** Dynamic attributes stored on-chain for each NFT (e.g., Adaptability, Cooperation, Efficiency, Discovery). These influence voting power and potentially the outcome of certain actions (in a more complex version).
3.  **Swarm State:** Global parameters affecting all members (e.g., Resource Level, Environmental Challenge, current Epoch).
4.  **Proposals:** Members create proposals to change the Swarm State, Trait Evolution Rules, allocate resources, or trigger external interactions. Proposals are voted on by members.
5.  **Evolution/Adaptation:** A process triggered periodically (epochs) that updates the Swarm State and potentially member traits based on collective activity (successful proposals, resource levels, etc.) and predefined (governable) rules.

**Outline:**

1.  Contract Definition (`EvolutionaryDAOSwarm` inheriting `ERC721Enumerable`, `Ownable`).
2.  Enums for Proposal Types and States, Trait Types.
3.  Structs for Swarm Member Traits, Proposal Data, Trait Evolution Rules.
4.  State Variables (mappings for members and proposals, swarm parameters, counters, addresses).
5.  Events for key actions (Minting, Proposal Submission/Voting/Execution, Epoch Evolution).
6.  Constructor.
7.  ERC721 Standard Functions (`balanceOf`, `ownerOf`, `transferFrom`, etc. - provided by `ERC721Enumerable`).
8.  Core Swarm Member / NFT Functions (Minting, Getting Traits, TokenURI).
9.  Swarm State Functions (Getting State, Admin Setup - initially Owner, later maybe DAO proposal).
10. DAO / Governance Functions (Submit different Proposal types, Vote, Execute Proposal, Get Proposal info, Calculate Voting Power).
11. Evolution / Epoch Functions (Trigger Epoch, Internal evolution logic, Get Evolution Rules).
12. Resource Management Functions (Deposit ETH, Get Balance, Withdraw via Proposal).
13. View Helper Functions.

**Function Summary (20+ functions):**

*   **Core Swarm/Member Functions:**
    1.  `constructor(string name, string symbol, uint256 initialEpochPeriod)`: Initializes the contract, ERC721, sets initial parameters, and owner.
    2.  `mintSwarmMember(address to)`: Allows the owner (or later, via DAO proposal) to mint a new Swarm Member NFT with initial traits.
    3.  `getSwarmMemberTraits(uint256 tokenId) view`: Returns the dynamic traits of a specific Swarm Member NFT.
    4.  `tokenURI(uint256 tokenId) view override`: Generates dynamic metadata URI for an NFT based on its current traits and Swarm state.
    5.  `calculateVotingPower(uint256 tokenId) view`: Calculates the voting power of a member based on their traits (e.g., sum or weighted average).
    6.  `getSwarmState() view`: Returns the current global Swarm parameters (epoch, resource level, challenge).
    7.  `getTraitEvolutionRule(TraitType _traitType) view`: Returns the current rule parameters for how a specific trait evolves during an epoch.

*   **DAO / Governance Functions:**
    8.  `submitProposal_ParameterMutation(string description, bytes32 parameterName, uint256 newValue)`: Submit a proposal to change a global Swarm parameter (e.g., `epochPeriod`, `quorumNumerator`).
    9.  `submitProposal_TraitAdaptationRule(string description, TraitType _traitType, int256 baseChange, uint256 positiveVoteInfluence, uint256 negativeVoteInfluence, uint256 swarmStateInfluenceFactor)`: Submit a proposal to change the rules for how a specific trait evolves per epoch.
    10. `submitProposal_ResourceAllocation(string description, address payable recipient, uint256 amount)`: Submit a proposal to send ETH from the Swarm treasury to an address.
    11. `submitProposal_ExternalCall(string description, address targetContract, bytes callData)`: Submit a proposal to call a function on another contract.
    12. `submitProposal_SelfTraitAdaptation(string description, uint256 targetMemberId, TraitType traitToChange, int256 changeAmount)`: Submit a proposal for a specific member to modify one of their *own* traits (could represent personal adaptation effort approved by swarm).
    13. `submitProposal_NewEvolutionGoal(string description, string goalDescription)`: Submit a proposal to define or change the current high-level goal of the swarm (primarily descriptive/signaling on-chain).
    14. `voteOnProposal(uint256 proposalId, bool vote)`: Cast a vote (yay/nay) on an active proposal. Voting power is calculated using `calculateVotingPower`.
    15. `executeProposal(uint256 proposalId)`: Execute a proposal if it has passed its voting period and met quorum/threshold.
    16. `getProposalState(uint256 proposalId) view`: Returns the current state of a proposal (Pending, Active, Succeeded, Failed, Executed).
    17. `getProposalDetails(uint256 proposalId) view`: Returns comprehensive details about a specific proposal.
    18. `getMemberVote(uint256 proposalId, uint256 memberTokenId) view`: Returns how a specific member voted on a proposal.
    19. `getRequiredQuorum() view`: Returns the current required quorum (percentage of total voting power).
    20. `getVotingPeriod() view`: Returns the duration of the voting period in seconds.
    21. `getExecutionDelay() view`: Returns the delay between voting end and execution start.

*   **Evolution / Epoch Functions:**
    22. `triggerEpochEvolution()`: Advances the Swarm to the next epoch. This function calculates changes to the Swarm state and member traits based on the defined rules and recent activity. Can only be called after `epochPeriod` has passed since the last epoch.

*   **Resource Management:**
    23. `depositResources() payable`: Allows anyone to send ETH to the Swarm treasury.
    24. `getResourceBalance() view`: Returns the current ETH balance of the contract.

*   **Admin / Setup Functions:**
    25. `setInitialSwarmState(uint256 initialResourceLevel, uint256 initialEnvironmentalChallenge)`: Sets initial values for core Swarm state parameters (callable only once by owner).
    26. `setTraitEvolutionRule(TraitType _traitType, int256 baseChange, uint256 positiveVoteInfluence, uint256 negativeVoteInfluence, uint256 swarmStateInfluenceFactor)`: Sets the rules for how a specific trait evolves (initially owner-only, later maybe via DAO proposal).

*   **ERC721 Required Functions (from `ERC721Enumerable`):**
    -   `balanceOf(address owner) view`
    -   `ownerOf(uint256 tokenId) view`
    -   `transferFrom(address from, address to, uint256 tokenId)`
    -   `safeTransferFrom(address from, address to, uint256 tokenId)`
    -   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`
    -   `approve(address to, uint256 tokenId)`
    -   `getApproved(uint256 tokenId) view`
    -   `setApprovalForAll(address operator, bool approved)`
    -   `isApprovedForAll(address owner, address operator) view`
    -   `supportsInterface(bytes4 interfaceId) view`
    -   `totalSupply() view`
    -   `tokenByIndex(uint256 index) view`
    -   `tokenOfOwnerByIndex(address owner, uint256 index) view`

*(Note: Including the standard ERC721 functions brings the total well over 20. The unique, concept-specific functions are numbered 1-26 above).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline and Function Summary ---
// Concept Name: Evolutionary DAO Swarm
// Core Idea: A DAO where members hold dynamic NFTs. These NFTs have traits that evolve based on successful collective proposals and global "Swarm" parameters that change over time (epochs). The DAO governs its resources, rules, and evolutionary trajectory through proposals.
//
// Key Components:
// 1. Swarm Members: ERC721 NFTs with dynamic traits.
// 2. Member Traits: Adaptability, Cooperation, Efficiency, Discovery etc.
// 3. Swarm State: Global parameters like Resource Level, Environmental Challenge, Epoch.
// 4. Proposals: DAO votes on changes to state, rules, resources, external calls.
// 5. Evolution/Adaptation: Epoch-based update mechanism for traits and swarm state.
//
// Outline:
// 1. Contract Definition (EvolutionaryDAOSwarm inheriting ERC721Enumerable, Ownable).
// 2. Enums for Proposal Types/States, Trait Types.
// 3. Structs for Member Traits, Proposals, Trait Evolution Rules.
// 4. State Variables.
// 5. Events.
// 6. Constructor.
// 7. Core Swarm/Member Functions (Minting, Traits, tokenURI, Voting Power).
// 8. Swarm State Functions (Get State, Admin Setup).
// 9. DAO/Governance Functions (Submit Proposals, Vote, Execute, Get Info).
// 10. Evolution Functions (Trigger Epoch, Get Rules).
// 11. Resource Management (Deposit, Get Balance).
// 12. View Helpers.
// 13. ERC721 Standard Functions.
//
// Function Summary (20+ functions):
// - Core Swarm/Member Functions:
//   1. constructor(string name, string symbol, uint256 initialEpochPeriod)
//   2. mintSwarmMember(address to)
//   3. getSwarmMemberTraits(uint256 tokenId) view
//   4. tokenURI(uint256 tokenId) view override
//   5. calculateVotingPower(uint256 tokenId) view
//   6. getSwarmState() view
//   7. getTraitEvolutionRule(TraitType _traitType) view
// - DAO / Governance Functions:
//   8. submitProposal_ParameterMutation(string description, bytes32 parameterName, uint256 newValue)
//   9. submitProposal_TraitAdaptationRule(string description, TraitType _traitType, int256 baseChange, uint256 positiveVoteInfluence, uint256 negativeVoteInfluence, uint256 swarmStateInfluenceFactor)
//   10. submitProposal_ResourceAllocation(string description, address payable recipient, uint256 amount)
//   11. submitProposal_ExternalCall(string description, address targetContract, bytes callData)
//   12. submitProposal_SelfTraitAdaptation(string description, uint256 targetMemberId, TraitType traitToChange, int256 changeAmount)
//   13. submitProposal_NewEvolutionGoal(string description, string goalDescription)
//   14. voteOnProposal(uint256 proposalId, bool vote)
//   15. executeProposal(uint256 proposalId)
//   16. getProposalState(uint256 proposalId) view
//   17. getProposalDetails(uint256 proposalId) view
//   18. getMemberVote(uint256 proposalId, uint256 memberTokenId) view
//   19. getRequiredQuorum() view
//   20. getVotingPeriod() view
//   21. getExecutionDelay() view
// - Evolution / Epoch Functions:
//   22. triggerEpochEvolution()
// - Resource Management:
//   23. depositResources() payable
//   24. getResourceBalance() view
// - Admin / Setup Functions:
//   25. setInitialSwarmState(uint256 initialResourceLevel, uint256 initialEnvironmentalChallenge)
//   26. setTraitEvolutionRule(TraitType _traitType, int256 baseChange, uint256 positiveVoteInfluence, uint256 negativeVoteInfluence, uint256 swarmStateInfluenceFactor)
// - ERC721 Standard Functions (from ERC721Enumerable):
//   (balanceOf, ownerOf, transferFrom, safeTransferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll, supportsInterface, totalSupply, tokenByIndex, tokenOfOwnerByIndex)
//
// Note: The combination of dynamic on-chain traits influenced by governance and an epoch-based evolution mechanism makes this contract unique. ERC721 standard functions contribute to the >20 function count.

contract EvolutionaryDAOSwarm is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Enums ---
    enum ProposalType {
        ParameterMutation,
        TraitAdaptationRule,
        ResourceAllocation,
        ExternalCall,
        SelfTraitAdaptation,
        NewEvolutionGoal // Primarily descriptive
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    enum TraitType {
        Adaptability,
        Cooperation,
        Efficiency,
        Discovery
    }

    // --- Structs ---
    struct SwarmMemberTraits {
        uint256 adaptability; // How well the member responds to swarm state changes
        uint256 cooperation; // Influence on collective actions, voting
        uint256 efficiency; // Resource usage, proposal execution likelihood
        uint256 discovery; // Chance of finding new "resources" or opportunities (simulated)
        uint256 lastEpochAdapted; // Last epoch this member's traits were directly affected by evolution
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        ProposalType proposalType;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 executionTime; // Time after votingEndTime when execution is possible
        ProposalState state;

        // Voting state
        uint256 yayVotes;
        uint256 nayVotes;
        uint256 totalVotingSupplyAtProposal; // Total voting power when proposal was created

        // Specific proposal data (use bytes to store flexibly based on type)
        bytes proposalData;
    }

    struct TraitEvolutionRule {
        int256 baseChange; // Flat change per epoch
        uint256 positiveVoteInfluence; // Influence from successful proposals
        uint256 negativeVoteInfluence; // Influence from failed proposals/environmental challenge
        uint256 swarmStateInfluenceFactor; // How much current swarm state affects change
    }

    // --- State Variables ---

    // Member data
    mapping(uint256 => SwarmMemberTraits) private _memberTraits; // tokenId -> traits

    // Swarm State
    uint256 public currentEpoch = 0;
    uint256 public lastEpochTime; // Timestamp of the last epoch evolution
    uint256 public epochPeriod = 7 days; // Default duration between epochs

    uint256 public swarmResourceLevel = 1000; // Simulated resource level
    uint256 public swarmEnvironmentalChallenge = 500; // Simulated challenge/pressure

    // DAO Parameters
    uint256 public quorumNumerator = 4; // 4 out of quorumDenominator
    uint256 public constant quorumDenominator = 10; // 40% quorum
    uint256 public votingPeriod = 3 days; // Duration proposals are active for voting
    uint256 public executionDelay = 1 days; // Delay after voting ends before execution is possible
    uint256 public proposalThreshold = 50; // % of yay votes required to pass (out of 100)

    // Proposal Data
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(uint256 => bool)) private _hasVoted; // proposalId -> memberTokenId -> voted (true/false)
    mapping(uint256 => mapping(uint256 => bool)) private _memberVote; // proposalId -> memberTokenId -> vote (yay/nay)

    // Evolution Rules
    mapping(TraitType => TraitEvolutionRule) public traitEvolutionRules;

    // Setup State
    bool private _swarmStateInitialised = false;

    // --- Events ---
    event SwarmMemberMinted(address indexed owner, uint256 indexed tokenId, SwarmMemberTraits initialTraits);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, ProposalType indexed proposalType, string description);
    event VoteCast(uint256 indexed proposalId, uint256 indexed memberTokenId, bool vote);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event EpochEvolutionTriggered(uint256 indexed newEpoch, uint256 newResourceLevel, uint256 newEnvironmentalChallenge);
    event TraitEvolutionRuleSet(TraitType indexed traitType, int256 baseChange, uint256 positiveVoteInfluence, uint256 negativeVoteInfluence, uint256 swarmStateInfluenceFactor);
    event SwarmStateInitialised(uint256 initialResourceLevel, uint256 initialEnvironmentalChallenge);
    event ResourceDeposit(address indexed depositor, uint256 amount);
    event ResourceWithdrawal(address indexed recipient, uint256 amount);
    event MemberTraitsAdapted(uint256 indexed memberTokenId, TraitType indexed traitType, int256 changeAmount, uint256 newTraitValue);
    event SwarmParameterChanged(bytes32 parameterName, uint256 newValue);
    event ExternalCallExecuted(uint256 indexed proposalId, address indexed target, bytes data, bool success, bytes result);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint256 initialEpochPeriod)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        epochPeriod = initialEpochPeriod;
        lastEpochTime = block.timestamp; // Start the clock for the first epoch

        // Set some initial default trait evolution rules (can be changed by DAO later)
        // These are just illustrative numbers
        traitEvolutionRules[TraitType.Adaptability] = TraitEvolutionRule(1, 5, 2, 10);
        traitEvolutionRules[TraitType.Cooperation] = TraitEvolutionRule(0, 10, 5, 0);
        traitEvolutionRules[TraitType.Efficiency] = TraitEvolutionRule(0, 7, 3, 5);
        traitEvolutionRules[TraitType.Discovery] = TraitEvolutionRule(1, 3, 1, 8);

        emit TraitEvolutionRuleSet(TraitType.Adaptability, 1, 5, 2, 10);
        emit TraitEvolutionRuleSet(TraitType.Cooperation, 0, 10, 5, 0);
        emit TraitEvolutionRuleSet(TraitType.Efficiency, 0, 7, 3, 5);
        emit TraitEvolutionRuleSet(TraitType.Discovery, 1, 3, 1, 8);
    }

    // --- ERC721 Standard Functions ---
    // Inherited from ERC721Enumerable:
    // - balanceOf(address owner) view
    // - ownerOf(uint256 tokenId) view
    // - transferFrom(address from, address to, uint256 tokenId)
    // - safeTransferFrom(address from, address to, uint256 tokenId)
    // - safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
    // - approve(address to, uint256 tokenId)
    // - getApproved(uint256 tokenId) view
    // - setApprovalForAll(address operator, bool approved)
    // - isApprovedForAll(address owner, address operator) view
    // - supportsInterface(bytes4 interfaceId) view
    // - totalSupply() view
    // - tokenByIndex(uint256 index) view
    // - tokenOfOwnerByIndex(address owner, uint256 index) view


    // --- Core Swarm Member / NFT Functions ---

    /**
     * @notice Mints a new Swarm Member NFT to an address with initial random-ish traits.
     * @dev Currently callable only by the owner. Could be changed to require a DAO proposal.
     * @param to The address to mint the NFT to.
     */
    function mintSwarmMember(address to) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Generate some simple initial traits (could be more complex, e.g., based on hash)
        SwarmMemberTraits memory initialTraits;
        initialTraits.adaptability = 50 + (newTokenId % 50); // 50-99
        initialTraits.cooperation = 50 + ((newTokenId * 7) % 50); // 50-99
        initialTraits.efficiency = 50 + ((newTokenId * 13) % 50); // 50-99
        initialTraits.discovery = 50 + ((newTokenId * 23) % 50); // 50-99
        initialTraits.lastEpochAdapted = currentEpoch;

        _safeMint(to, newTokenId);
        _memberTraits[newTokenId] = initialTraits;

        emit SwarmMemberMinted(to, newTokenId, initialTraits);
    }

    /**
     * @notice Gets the current dynamic traits of a Swarm Member NFT.
     * @param tokenId The ID of the NFT.
     * @return The SwarmMemberTraits struct for the given token ID.
     */
    function getSwarmMemberTraits(uint256 tokenId) public view returns (SwarmMemberTraits memory) {
        require(_exists(tokenId), "Token does not exist");
        return _memberTraits[tokenId];
    }

    /**
     * @notice Generates the dynamic metadata URI for a Swarm Member NFT.
     * @dev This function makes the NFT dynamic. The metadata includes the current traits.
     * @param tokenId The ID of the NFT.
     * @return The Base64 encoded JSON metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        SwarmMemberTraits memory traits = _memberTraits[tokenId];
        SwarmState memory swarmState = getSwarmState(); // Get current swarm state for context

        string memory json = string(abi.encodePacked(
            '{"name": "Swarm Member #', Strings.toString(tokenId), '",',
            '"description": "An evolutionary member of the DAO Swarm. Traits adapt based on collective actions and environmental challenges.",',
            '"image": "data:image/svg+xml;base64,...",', // Placeholder for potential dynamic SVG
            '"attributes": [',
                '{"trait_type": "Epoch", "value": ', Strings.toString(swarmState.currentEpoch), '},',
                '{"trait_type": "Swarm Resource Level", "value": ', Strings.toString(swarmState.resourceLevel), '},',
                '{"trait_type": "Swarm Environmental Challenge", "value": ', Strings.toString(swarmState.environmentalChallenge), '},',
                '{"trait_type": "Adaptability", "value": ', Strings.toString(traits.adaptability), '},',
                '{"trait_type": "Cooperation", "value": ', Strings.toString(traits.cooperation), '},',
                '{"trait_type": "Efficiency", "value": ', Strings.toString(traits.efficiency), '},',
                '{"trait_type": "Discovery", "value": ', Strings.toString(traits.discovery), '}',
            ']}'
        ));

        // Encode the JSON as Base64
        string memory base64Json = Base64.encode(bytes(json));

        return string(abi.encodePacked('data:application/json;base64,', base64Json));
    }

    /**
     * @notice Calculates the voting power of a member.
     * @dev Simple implementation: sum of all trait values. Could be weighted or use a curve.
     * @param tokenId The ID of the Swarm Member NFT.
     * @return The voting power for the member holding this token. Returns 0 if token doesn't exist.
     */
    function calculateVotingPower(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) {
            return 0;
        }
        SwarmMemberTraits memory traits = _memberTraits[tokenId];
        // Example: Simple sum of traits
        return traits.adaptability + traits.cooperation + traits.efficiency + traits.discovery;
        // More complex: return (traits.cooperation * 2 + traits.efficiency + traits.adaptability + traits.discovery) / 4;
    }

    // --- Swarm State Functions ---

    struct SwarmState {
        uint256 currentEpoch;
        uint256 lastEpochTime;
        uint256 epochPeriod;
        uint256 resourceLevel;
        uint256 environmentalChallenge;
        uint256 quorumNumerator;
        uint256 quorumDenominator;
        uint256 votingPeriod;
        uint256 executionDelay;
        uint256 proposalThreshold;
        uint256 totalVotingSupply;
    }

    /**
     * @notice Gets the current global state parameters of the Swarm.
     * @return A struct containing the current Swarm state.
     */
    function getSwarmState() public view returns (SwarmState memory) {
         // Calculate total voting supply (sum of all member voting power)
        uint256 totalPower = 0;
        uint256 totalTokens = totalSupply();
        for(uint256 i = 0; i < totalTokens; i++) {
            uint256 tokenId = tokenByIndex(i);
            totalPower += calculateVotingPower(tokenId);
        }

        return SwarmState({
            currentEpoch: currentEpoch,
            lastEpochTime: lastEpochTime,
            epochPeriod: epochPeriod,
            resourceLevel: swarmResourceLevel,
            environmentalChallenge: swarmEnvironmentalChallenge,
            quorumNumerator: quorumNumerator,
            quorumDenominator: quorumDenominator,
            votingPeriod: votingPeriod,
            executionDelay: executionDelay,
            proposalThreshold: proposalThreshold,
            totalVotingSupply: totalPower // Dynamic calculation
        });
    }

    /**
     * @notice Allows the owner to set the initial swarm state parameters.
     * @dev Can only be called once. Future changes require DAO proposals.
     * @param initialResourceLevel Initial value for swarmResourceLevel.
     * @param initialEnvironmentalChallenge Initial value for swarmEnvironmentalChallenge.
     */
    function setInitialSwarmState(uint256 initialResourceLevel, uint256 initialEnvironmentalChallenge) public onlyOwner {
        require(!_swarmStateInitialised, "Swarm state already initialised");
        swarmResourceLevel = initialResourceLevel;
        swarmEnvironmentalChallenge = initialEnvironmentalChallenge;
        _swarmStateInitialised = true;
        emit SwarmStateInitialised(initialResourceLevel, initialEnvironmentalChallenge);
    }

    /**
     * @notice Allows the owner to set the rules for how a specific trait evolves.
     * @dev This should eventually be moved to a DAO proposal type.
     */
    function setTraitEvolutionRule(
        TraitType _traitType,
        int256 baseChange,
        uint256 positiveVoteInfluence,
        uint256 negativeVoteInfluence,
        uint256 swarmStateInfluenceFactor
    ) public onlyOwner {
        traitEvolutionRules[_traitType] = TraitEvolutionRule(
            baseChange,
            positiveVoteInfluence,
            negativeVoteInfluence,
            swarmStateInfluenceFactor
        );
        emit TraitEvolutionRuleSet(_traitType, baseChange, positiveVoteInfluence, negativeVoteInfluence, swarmStateInfluenceFactor);
    }


    // --- DAO / Governance Functions ---

    /**
     * @dev Internal function to create a new proposal boilerplate.
     */
    function _createProposal(string memory description, ProposalType _type, bytes memory data) internal returns (uint256) {
         // Proposer must be a member (own an NFT)
        uint256 proposerTokenId = 0;
        uint256 totalTokens = totalSupply();
        address msgSender = msg.sender; // Cache msg.sender
        for(uint256 i = 0; i < totalTokens; i++) {
            uint256 tokenId = tokenByIndex(i);
            if (ownerOf(tokenId) == msgSender) {
                proposerTokenId = tokenId;
                break;
            }
        }
        require(proposerTokenId != 0, "Proposer must be a Swarm Member");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        uint256 totalVotingSupply = getSwarmState().totalVotingSupply; // Calculate supply at proposal creation

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            description: description,
            proposalType: _type,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + votingPeriod,
            executionTime: block.timestamp + votingPeriod + executionDelay,
            state: ProposalState.Active,
            yayVotes: 0,
            nayVotes: 0,
            totalVotingSupplyAtProposal: totalVotingSupply,
            proposalData: data
        });

        emit ProposalSubmitted(newProposalId, msg.sender, _type, description);
        return newProposalId;
    }

    /**
     * @notice Submit a proposal to change a global Swarm parameter.
     * @param description Short description of the proposal.
     * @param parameterName The name of the parameter to change (e.g., "epochPeriod").
     * @param newValue The new value for the parameter.
     */
    function submitProposal_ParameterMutation(string memory description, bytes32 parameterName, uint256 newValue) public {
        // Encode specific data: parameterName, newValue
        bytes memory data = abi.encode(parameterName, newValue);
        _createProposal(description, ProposalType.ParameterMutation, data);
    }

    /**
     * @notice Submit a proposal to change the rules for how a specific trait evolves per epoch.
     * @param description Short description.
     * @param _traitType The trait type whose rule is being modified.
     * @param baseChange New base change value.
     * @param positiveVoteInfluence New positive vote influence.
     * @param negativeVoteInfluence New negative vote influence.
     * @param swarmStateInfluenceFactor New swarm state influence factor.
     */
    function submitProposal_TraitAdaptationRule(
        string memory description,
        TraitType _traitType,
        int256 baseChange,
        uint256 positiveVoteInfluence,
        uint256 negativeVoteInfluence,
        uint256 swarmStateInfluenceFactor
    ) public {
        // Encode specific data: traitType, rule parameters
        bytes memory data = abi.encode(
            _traitType,
            baseChange,
            positiveVoteInfluence,
            negativeVoteInfluence,
            swarmStateInfluenceFactor
        );
        _createProposal(description, ProposalType.TraitAdaptationRule, data);
    }

    /**
     * @notice Submit a proposal to send ETH from the Swarm treasury.
     * @param description Short description.
     * @param recipient The address to send ETH to.
     * @param amount The amount of ETH to send (in wei).
     */
    function submitProposal_ResourceAllocation(string memory description, address payable recipient, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= address(this).balance, "Insufficient balance in treasury");

        // Encode specific data: recipient, amount
        bytes memory data = abi.encode(recipient, amount);
        _createProposal(description, ProposalType.ResourceAllocation, data);
    }

    /**
     * @notice Submit a proposal to call a function on another contract.
     * @dev Be cautious with external calls; they can be risky. Should ideally restrict target contracts or functions.
     * @param description Short description.
     * @param targetContract The address of the contract to call.
     * @param callData The calldata for the external function call.
     */
    function submitProposal_ExternalCall(string memory description, address targetContract, bytes memory callData) public {
        require(targetContract != address(0), "Invalid target contract address");
        // Encode specific data: targetContract, callData
        bytes memory data = abi.encode(targetContract, callData);
        _createProposal(description, ProposalType.ExternalCall, data);
    }

    /**
     * @notice Submit a proposal for a specific member to modify one of their own traits.
     * @dev This allows members to "adapt" themselves, but requires swarm approval.
     * @param description Short description.
     * @param targetMemberId The token ID of the member proposing the self-adaptation (must be msg.sender's token).
     * @param traitToChange The specific trait type to change.
     * @param changeAmount The amount to change the trait by (can be positive or negative, but logic in execution should handle bounds).
     */
    function submitProposal_SelfTraitAdaptation(string memory description, uint256 targetMemberId, TraitType traitToChange, int256 changeAmount) public {
         require(ownerOf(targetMemberId) == msg.sender, "Can only propose self-adaptation for your own token");
         // Encode specific data: targetMemberId, traitToChange, changeAmount
         bytes memory data = abi.encode(targetMemberId, traitToChange, changeAmount);
        _createProposal(description, ProposalType.SelfTraitAdaptation, data);
    }

    /**
     * @notice Submit a proposal to define or change the current high-level goal of the swarm.
     * @dev This is primarily a signaling mechanism and doesn't change on-chain state directly, but helps align the swarm.
     * @param description Short description.
     * @param goalDescription A longer description of the proposed goal.
     */
    function submitProposal_NewEvolutionGoal(string memory description, string memory goalDescription) public {
         // Encode specific data: goalDescription
         bytes memory data = abi.encode(goalDescription);
        _createProposal(description, ProposalType.NewEvolutionGoal, data);
    }

    /**
     * @notice Cast a vote (yay/nay) on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param vote True for Yay, False for Nay.
     */
    function voteOnProposal(uint256 proposalId, bool vote) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");

        // Voter must be a member (own an NFT) and must use one of their tokens to vote
        uint256 voterTokenId = 0;
        uint256 totalTokens = totalSupply();
        address msgSender = msg.sender; // Cache msg.sender
        for(uint256 i = 0; i < totalTokens; i++) {
            uint256 tokenId = tokenByIndex(i);
            if (ownerOf(tokenId) == msgSender) {
                voterTokenId = tokenId;
                break;
            }
        }
        require(voterTokenId != 0, "Voter must be a Swarm Member");
        require(!_hasVoted[proposalId][voterTokenId], "Member has already voted with this token");

        uint256 votingPower = calculateVotingPower(voterTokenId);
        require(votingPower > 0, "Voter has no voting power");

        _hasVoted[proposalId][voterTokenId] = true;
        _memberVote[proposalId][voterTokenId] = vote;

        if (vote) {
            proposal.yayVotes += votingPower;
        } else {
            proposal.nayVotes += votingPower;
        }

        emit VoteCast(proposalId, voterTokenId, vote);
    }

    /**
     * @notice Execute a proposal if it has passed its voting period and met conditions.
     * @dev Callable by anyone.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.state == ProposalState.Active || proposal.state == ProposalState.Succeeded || proposal.state == ProposalState.Failed, "Proposal is not in a state to be executed");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended");
        require(block.timestamp > proposal.executionTime, "Execution delay has not passed");

        if (proposal.state == ProposalState.Active) {
             // Determine final state based on votes and requirements
            uint256 totalVotes = proposal.yayVotes + proposal.nayVotes;
            uint256 requiredQuorumVotes = (proposal.totalVotingSupplyAtProposal * quorumNumerator) / quorumDenominator;

            if (totalVotes >= requiredQuorumVotes && proposal.yayVotes * 100 / totalVotes >= proposalThreshold) {
                proposal.state = ProposalState.Succeeded;
                emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
            } else {
                proposal.state = ProposalState.Failed;
                 emit ProposalStateChanged(proposalId, ProposalState.Failed);
            }
        }

        require(proposal.state == ProposalState.Succeeded, "Proposal failed or cannot be executed");

        _executeProposal(proposalId, proposal);

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

     /**
     * @dev Internal function to handle proposal execution logic based on type.
     */
    function _executeProposal(uint256 proposalId, Proposal storage proposal) internal {
        if (proposal.proposalType == ProposalType.ParameterMutation) {
            (bytes32 parameterName, uint256 newValue) = abi.decode(proposal.proposalData, (bytes32, uint256));
            _applyParameterMutation(parameterName, newValue);
            emit SwarmParameterChanged(parameterName, newValue);

        } else if (proposal.proposalType == ProposalType.TraitAdaptationRule) {
             (TraitType _traitType, int256 baseChange, uint256 positiveVoteInfluence, uint256 negativeVoteInfluence, uint256 swarmStateInfluenceFactor) = abi.decode(
                 proposal.proposalData,
                 (TraitType, int256, uint256, uint256, uint256)
             );
             traitEvolutionRules[_traitType] = TraitEvolutionRule(
                 baseChange,
                 positiveVoteInfluence,
                 negativeVoteInfluence,
                 swarmStateInfluenceFactor
             );
             emit TraitEvolutionRuleSet(_traitType, baseChange, positiveVoteInfluence, negativeVoteInfluence, swarmStateInfluenceFactor);

        } else if (proposal.proposalType == ProposalType.ResourceAllocation) {
            (address payable recipient, uint256 amount) = abi.decode(proposal.proposalData, (address payable, uint256));
            require(address(this).balance >= amount, "Insufficient balance for resource allocation"); // Double check balance before sending
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "ETH transfer failed");
            emit ResourceWithdrawal(recipient, amount);

        } else if (proposal.proposalType == ProposalType.ExternalCall) {
             (address targetContract, bytes memory callData) = abi.decode(proposal.proposalData, (address, bytes));
             (bool success, bytes memory result) = targetContract.call(callData);
             // Decide if failed external calls automatically fail the proposal execution.
             // For now, we'll just emit an event indicating success/failure. The proposal state is already Succeeded if executed.
             emit ExternalCallExecuted(proposalId, targetContract, callData, success, result);
             // require(success, "External call failed"); // Optional: revert if call fails

        } else if (proposal.proposalType == ProposalType.SelfTraitAdaptation) {
            (uint256 targetMemberId, TraitType traitToChange, int256 changeAmount) = abi.decode(proposal.proposalData, (uint256, TraitType, int256));
             // Apply trait change (with bounds checking, e.g., traits cannot go below 0 or above a max)
             _applyTraitChange(targetMemberId, traitToChange, changeAmount);

        } else if (proposal.proposalType == ProposalType.NewEvolutionGoal) {
             // This proposal type is primarily signaling. No state change required here.
             // Could potentially store the current goal description if needed.
             // (string memory goalDescription) = abi.decode(proposal.proposalData, (string));
             // Store goalDescription if a state variable exists for it.
        }
    }

     /**
     * @dev Internal function to apply a parameter mutation.
     * @param parameterName Name of the parameter to mutate.
     * @param newValue The new value.
     */
    function _applyParameterMutation(bytes32 parameterName, uint256 newValue) internal {
        if (parameterName == "epochPeriod") {
            epochPeriod = newValue;
        } else if (parameterName == "quorumNumerator") {
            require(newValue > 0 && newValue <= quorumDenominator, "Invalid quorum numerator");
            quorumNumerator = newValue;
        } else if (parameterName == "votingPeriod") {
            votingPeriod = newValue;
        } else if (parameterName == "executionDelay") {
            executionDelay = newValue;
        } else if (parameterName == "proposalThreshold") {
             require(newValue <= 100, "Threshold cannot exceed 100%");
            proposalThreshold = newValue;
        } else if (parameterName == "swarmResourceLevel") {
             swarmResourceLevel = newValue; // Direct change, could be part of resource proposals
        } else if (parameterName == "swarmEnvironmentalChallenge") {
             swarmEnvironmentalChallenge = newValue; // Direct change
        } else {
            revert("Unknown parameter name");
        }
    }

     /**
     * @dev Internal function to apply a trait change to a member.
     * Handles bounds checking (e.g., min 0, max 255 or 1000).
     * @param memberTokenId The ID of the member.
     * @param traitType The trait to change.
     * @param changeAmount The amount to change (signed).
     */
    function _applyTraitChange(uint256 memberTokenId, TraitType traitType, int256 changeAmount) internal {
        SwarmMemberTraits storage traits = _memberTraits[memberTokenId];
        int256 currentTrait;
        int256 maxTrait = 1000; // Example max trait value

        if (traitType == TraitType.Adaptability) currentTrait = int256(traits.adaptability);
        else if (traitType == TraitType.Cooperation) currentTrait = int256(traits.cooperation);
        else if (traitType == TraitType.Efficiency) currentTrait = int256(traits.efficiency);
        else if (traitType == TraitType.Discovery) currentTrait = int256(traits.discovery);
        else return; // Unknown trait type

        int256 newTrait = currentTrait + changeAmount;

        // Apply bounds
        if (newTrait < 0) newTrait = 0;
        if (newTrait > maxTrait) newTrait = maxTrait;

        // Update the trait
        if (traitType == TraitType.Adaptability) traits.adaptability = uint256(newTrait);
        else if (traitType == TraitType.Cooperation) traits.cooperation = uint256(newTrait);
        else if (traitType == TraitType.Efficiency) traits.efficiency = uint256(newTrait);
        else if (traitType == TraitType.Discovery) traits.discovery = uint256(newTrait);

        emit MemberTraitsAdapted(memberTokenId, traitType, changeAmount, uint256(newTrait));
    }


    /**
     * @notice Gets the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The ProposalState enum value.
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        require(proposalId > 0 && proposalId <= _proposalIdCounter.current(), "Invalid proposal ID");
        return proposals[proposalId].state;
    }

    /**
     * @notice Gets the full details of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The Proposal struct.
     */
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        require(proposalId > 0 && proposalId <= _proposalIdCounter.current(), "Invalid proposal ID");
        return proposals[proposalId];
    }

     /**
     * @notice Gets whether a specific member token has voted on a proposal and how.
     * @param proposalId The ID of the proposal.
     * @param memberTokenId The ID of the member's token.
     * @return voted True if the member voted, False otherwise.
     * @return vote True if the member voted Yay, False if Nay (only meaningful if voted is true).
     */
    function getMemberVote(uint256 proposalId, uint256 memberTokenId) public view returns (bool voted, bool vote) {
        require(proposalId > 0 && proposalId <= _proposalIdCounter.current(), "Invalid proposal ID");
        require(_exists(memberTokenId), "Member token does not exist");
        return (_hasVoted[proposalId][memberTokenId], _memberVote[proposalId][memberTokenId]);
    }

    /**
     * @notice Returns the current required quorum percentage.
     * @return Quorum numerator (out of quorumDenominator).
     */
    function getRequiredQuorum() public view returns (uint256) {
        return quorumNumerator;
    }

    /**
     * @notice Returns the current voting period duration in seconds.
     */
    function getVotingPeriod() public view returns (uint256) {
        return votingPeriod;
    }

     /**
     * @notice Returns the current execution delay duration in seconds.
     */
    function getExecutionDelay() public view returns (uint256) {
        return executionDelay;
    }


    // --- Evolution / Epoch Functions ---

    /**
     * @notice Triggers the next epoch evolution cycle.
     * @dev Can only be called if enough time has passed since the last epoch.
     * Applies global swarm state changes and member trait adaptations.
     * Callable by anyone to advance time, but logic depends on contract state.
     */
    function triggerEpochEvolution() public {
        require(block.timestamp >= lastEpochTime + epochPeriod, "Epoch period has not passed");

        currentEpoch++;
        lastEpochTime = block.timestamp;

        // --- Apply Swarm State Evolution ---
        // Example: Environmental challenge increases slightly every epoch
        swarmEnvironmentalChallenge = swarmEnvironmentalChallenge + (swarmEnvironmentalChallenge / 100) + 1;
        // Resource level decreases based on challenge and number of members
        uint256 resourceBurn = (swarmEnvironmentalChallenge * totalSupply()) / 1000; // Example calculation
        if (swarmResourceLevel > resourceBurn) {
            swarmResourceLevel -= resourceBurn;
        } else {
            swarmResourceLevel = 0;
        }

        // --- Apply Member Trait Evolution ---
        // Traits change based on rules and swarm state
        uint256 totalTokens = totalSupply();
        for(uint256 i = 0; i < totalTokens; i++) {
            uint256 tokenId = tokenByIndex(i);
            SwarmMemberTraits storage traits = _memberTraits[tokenId];

            // Only adapt traits if they haven't been adapted this epoch OR by a recent proposal
            // (This prevents double-dipping if a self-adaptation proposal just passed)
            if (traits.lastEpochAdapted < currentEpoch) {
                 _applyEpochTraitAdaptation(tokenId, traits);
                 traits.lastEpochAdapted = currentEpoch;
            }
        }

        emit EpochEvolutionTriggered(currentEpoch, swarmResourceLevel, swarmEnvironmentalChallenge);
    }

    /**
     * @dev Internal function to apply epoch-specific trait changes to a member.
     * Based on predefined TraitEvolutionRules and current Swarm State.
     */
    function _applyEpochTraitAdaptation(uint256 memberTokenId, SwarmMemberTraits storage traits) internal {
        TraitEvolutionRule memory rule;
        int256 change;
        int256 currentTrait;
        int256 maxTrait = 1000; // Example max trait value

        // Adaptability
        rule = traitEvolutionRules[TraitType.Adaptability];
        currentTrait = int256(traits.adaptability);
        change = rule.baseChange +
                 int256((swarmEnvironmentalChallenge * rule.swarmStateInfluenceFactor) / 100); // Example influence
        _applyTraitChange(memberTokenId, TraitType.Adaptability, change);

        // Cooperation
        rule = traitEvolutionRules[TraitType.Cooperation];
        currentTrait = int256(traits.cooperation);
        // Could add influence from successful/failed proposals in the last epoch here
        change = rule.baseChange; // + some influence from governance outcome?
        _applyTraitChange(memberTokenId, TraitType.Cooperation, change);

        // Efficiency
        rule = traitEvolutionRules[TraitType.Efficiency];
        currentTrait = int256(traits.efficiency);
         change = rule.baseChange +
                 int256((swarmResourceLevel * rule.swarmStateInfluenceFactor) / 100); // Example influence
        _applyTraitChange(memberTokenId, TraitType.Efficiency, change);


        // Discovery
        rule = traitEvolutionRules[TraitType.Discovery];
        currentTrait = int256(traits.discovery);
         change = rule.baseChange +
                 int256((swarmEnvironmentalChallenge * rule.swarmStateInfluenceFactor) / 200); // Example influence
        _applyTraitChange(memberTokenId, TraitType.Discovery, change);

        // Note: This is a simple linear example. Real evolution could involve more complex interactions,
        // genetic algorithms (off-chain simulation influencing on-chain state), etc.
    }


    // --- Resource Management ---

    /**
     * @notice Allows anyone to deposit native ETH into the Swarm treasury.
     * @dev The ETH can only be withdrawn via a successful ResourceAllocation proposal.
     */
    receive() external payable {
        emit ResourceDeposit(msg.sender, msg.value);
    }

    /**
     * @notice Public function to trigger the receive payable function.
     * @dev This makes it clearer how to deposit compared to just sending raw ETH.
     */
    function depositResources() public payable {
        emit ResourceDeposit(msg.sender, msg.value);
    }


    /**
     * @notice Gets the current ETH balance of the Swarm treasury.
     * @return The current balance in wei.
     */
    function getResourceBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- View Helper Functions ---

    /**
     * @notice Returns the total number of proposals submitted.
     */
    function getTotalProposals() public view returns (uint256) {
        return _proposalIdCounter.current();
    }

    // You could add more view functions here, e.g.,
    // getMemberProposalCount(uint256 memberTokenId) view
    // getMemberSuccessfulProposalCount(uint256 memberTokenId) view
    // getProposalsByState(ProposalState state) view (requires iterating over all proposals)
    // getProposalsByType(ProposalType _type) view (requires iterating)

}
```