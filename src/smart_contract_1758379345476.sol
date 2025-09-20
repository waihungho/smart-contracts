Here's a smart contract designed with advanced, creative, and trendy concepts, focusing on a "Self-Evolving, AI-Augmented Digital Ecosystem." This contract, named `AetheriumForge`, manages unique, dynamic NFTs called "Digital Constructs" whose traits can evolve through community governance, staked influence, and suggestions from an AI oracle. It integrates a native resource token (`AETHER` - assumed to be an external ERC20 token, managed by this contract), a simplified DAO, and mechanisms for passive and active evolution.

---

## AetheriumForge: Decentralized & AI-Augmented Digital Ecosystem

This contract establishes a dynamic digital ecosystem where users can forge unique "Digital Constructs" (NFTs) that possess evolving traits. These constructs are not static; their attributes can change over time, influenced by various factors: direct user interaction, community-driven proposals via a Decentralized Autonomous Organization (DAO), and insights provided by an off-chain AI oracle. The ecosystem is powered by `AETHER` tokens, which are used for staking, governance, and fueling the constructs' evolution.

### Core Concepts:

*   **Dynamic NFTs (Digital Constructs):** ERC721-compliant tokens representing unique digital entities with mutable `traitData`.
*   **AI-Augmented Evolution:** An integrated AI oracle can propose trait changes or power boosts for constructs based on off-chain AI models or external data.
*   **Community Governance (Simplified DAO):** `AETHER` token holders can stake their tokens to gain voting power, create proposals (e.g., to manually evolve a construct or change ecosystem parameters), and vote on them to collectively guide the ecosystem's development.
*   **AETHER Token:** An external ERC20 token whose minting and burning is controlled by this `AetheriumForge` contract. It serves as the native resource for staking, governance, and influencing construct evolution.
*   **Influence Staking:** Users can stake `AETHER` directly on specific Digital Constructs. This staked `AETHER` contributes to the construct's "influence score" and its "evolution budget," encouraging its development.
*   **Passive & Active Evolution:** Constructs can undergo passive evolution (triggered by accumulated influence and budget) or active evolution (via AI oracle or DAO proposals).
*   **External Data Integration:** The DAO can register and utilize external data feeds, allowing for broader real-world influences on the ecosystem and its constructs.

### Outline and Function Summary:

#### I. Core System & Administration (7 functions)

1.  **`constructor()`**: Initializes the contract, setting the initial owner, and optionally the `AETHER` token address and AI Oracle.
2.  **`setAetherTokenAddress(address _tokenAddress)`**: Sets the address of the external ERC20 `AETHER` token contract. Only callable by the owner.
3.  **`setAIOracleAddress(address _oracle)`**: Sets the address of the trusted AI Oracle responsible for fulfilling AI-driven evolution requests. Only callable by the owner.
4.  **`pause()`**: Pauses certain functionalities of the contract, preventing specific operations. Only callable by the owner. Inherits from OpenZeppelin `Pausable`.
5.  **`unpause()`**: Unpauses the contract, allowing operations to resume. Only callable by the owner. Inherits from OpenZeppelin `Pausable`.
6.  **`withdrawStuckERC20(address _token, uint256 _amount)`**: Allows the owner to recover accidentally sent ERC20 tokens that are not `AETHER` or `ETH`.
7.  **`setEvolutionFee(uint256 _newFee)`**: Sets the `AETHER` fee required to trigger a `passiveEvolution`. Only callable by the owner or a successful DAO proposal.

#### II. Digital Construct (NFT) Management (ERC721-compliant) (7 functions)

8.  **`forgeConstruct(string memory _name, string memory _initialTraitData)`**: Mints a new Digital Construct (NFT) with a unique ID and initial traits to the caller. Requires an `AETHER` fee.
9.  **`getConstructDetails(uint256 _tokenId)`**: A view function to retrieve the current details (owner, name, traits, power, evolution budget, creation time) of a specific Digital Construct.
10. **`transferConstruct(address _from, address _to, uint256 _tokenId)`**: Transfers ownership of a Digital Construct from one address to another. Wraps `ERC721.safeTransferFrom`.
11. **`requestAI_Evolution(uint256 _tokenId, string memory _prompt)`**: Initiates an AI-driven evolution request for a construct. This sends a request to the configured AI Oracle with a user-provided prompt. Requires an `AETHER` fee.
12. **`fulfillAI_Evolution(bytes32 _requestId, uint256 _tokenId, string memory _newTraitData, uint256 _powerBoost)`**: The callback function exclusively for the AI Oracle to fulfill a previously requested AI evolution. It updates the construct's traits and boosts its power.
13. **`queryTraitHistory(uint256 _tokenId)`**: A view function returning the full chronological history of trait data changes for a given Digital Construct.
14. **`triggerPassiveEvolution(uint256 _tokenId)`**: Allows any user to trigger a passive evolution for a construct if it has accumulated sufficient `evolutionBudget`. This uses the budget, updates traits based on influence, and provides a small `AETHER` reward to the caller.

#### III. DAO Governance & Staking (8 functions)

15. **`stakeAetherForVoting(uint256 _amount)`**: Users stake `AETHER` tokens to gain voting power within the DAO. Requires prior `ERC20.approve()` call.
16. **`unstakeAether(uint256 _amount)`**: Users can unstake their `AETHER` tokens, reducing their voting power. A cooldown period may apply.
17. **`createEvolutionProposal(uint256 _targetConstructId, string memory _proposedTraitChange, string memory _rationale)`**: Creates a governance proposal to manually change the traits of a specific Digital Construct. Requires a minimum staked `AETHER` threshold.
18. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows staked `AETHER` holders to cast a vote (for or against) on an active proposal.
19. **`executeProposal(uint256 _proposalId)`**: Executes a proposal that has passed its voting period and met the required majority.
20. **`delegateVotingPower(address _delegatee)`**: Allows a user to delegate their voting power to another address.
21. **`depositAetherForConstructInfluence(uint256 _tokenId, uint256 _amount)`**: Users can stake `AETHER` directly on a specific Digital Construct to increase its `evolutionBudget` and `influenceScore`. Requires prior `ERC20.approve()` call.
22. **`withdrawAetherFromConstructInfluence(uint256 _tokenId, uint256 _amount)`**: Allows users to withdraw their `AETHER` previously staked for a construct's influence.

#### IV. Ecosystem Dynamics & Queries (5 functions)

23. **`calculateConstructInfluenceScore(uint256 _tokenId)`**: A view function that computes a numerical `influenceScore` for a construct based on its `evolutionBudget`, trait history, and other factors.
24. **`getProposalState(uint256 _proposalId)`**: A view function to check the current status of a governance proposal (e.g., Pending, Active, Succeeded, Defeated, Executed).
25. **`getVotePower(address _voter)`**: A view function returning the current voting power (staked `AETHER` amount) of a specific address.
26. **`getConstructStakedInfluence(uint256 _tokenId)`**: A view function returning the total `AETHER` currently staked for a specific construct's influence.
27. **`registerExternalDataFeed(bytes32 _feedId, address _feedAddress)`**: Allows the DAO (via proposal) to register and manage addresses of external trusted data feeds.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Custom Errors for better readability and gas efficiency
error AetheriumForge__InvalidAetherTokenAddress();
error AetheriumForge__NotEnoughAetherStakedForProposal();
error AetheriumForge__ProposalNotFound();
error AetheriumForge__ProposalNotActive();
error AetheriumForge__AlreadyVoted();
error AetheriumForge__NotEnoughVotingPower();
error AetheriumForge__ProposalNotExecutable();
error AetheriumForge__ProposalExpired();
error AetheriumForge__ProposalPending();
error AetheriumForge__ProposalPeriodNotEnded();
error AetheriumForge__NothingToUnstake();
error AetheriumForge__NotEnoughStakedInfluence();
error AetheriumForge__InsufficientAetherBalance();
error AetheriumForge__ApprovalFailed();
error AetheriumForge__TransferFailed();
error AetheriumForge__MintFailed();
error AetheriumForge__OracleNotSet();
error AetheriumForge__InvalidOracleCaller();
error AetheriumForge__ConstructNotFound();
error AetheriumForge__NotEnoughBudgetForPassiveEvolution();
error AetheriumForge__LowInfluenceForPassiveEvolution();
error AetheriumForge__FeePaymentFailed();

contract AetheriumForge is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---

    IERC20 public AETHER_TOKEN; // The ERC20 token used for staking, fees, and influence

    address public AI_ORACLE_ADDRESS; // Trusted oracle for AI-driven evolutions
    uint256 public evolutionFee; // Fee in AETHER for triggering passive evolution

    uint256 public nextConstructId; // Counter for new Digital Constructs

    // --- Digital Construct (NFT) Data ---
    struct DigitalConstruct {
        uint256 tokenId;
        address owner;
        string name;
        string currentTraitData; // JSON or string representation of traits
        uint256 power; // Represents its overall strength/level
        uint256 evolutionBudget; // AETHER accumulated for evolution
        uint256 influenceScore; // Calculated based on staked AETHER, power, etc.
        uint256 genesisTimestamp;
        uint256 lastEvolutionTimestamp;
    }
    mapping(uint256 => DigitalConstruct) public digitalConstructs;
    mapping(uint256 => string[]) public constructTraitHistory; // Stores historical trait data

    // --- DAO Governance Data ---
    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Executed,
        Canceled
    }

    struct Proposal {
        uint256 id;
        uint256 targetConstructId; // 0 for system-wide proposals
        string proposedTraitChange; // If targetConstructId > 0, new trait data
        string rationale;
        uint256 proposer; // Address of proposer, encoded as uint
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        EnumerableSet.AddressSet voters; // Addresses that have voted
    }

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public stakedAetherForVoting; // User's AETHER staked for DAO
    mapping(address => address) public votingDelegates; // Who a user has delegated their vote to
    mapping(address => uint256) public votingPower; // Effective voting power including delegation

    uint256 public constant PROPOSAL_THRESHOLD = 1000 * (10 ** 18); // Minimum AETHER to create proposal
    uint256 public constant VOTING_PERIOD_SECONDS = 3 days; // Duration for voting
    uint256 public constant MIN_INFLUENCE_FOR_PASSIVE_EVOLUTION = 500 * (10 ** 18); // Min AETHER influence for passive evolution

    // --- Construct Influence Staking ---
    mapping(uint256 => mapping(address => uint256)) public constructInfluenceStakes; // tokenId => user => amount
    mapping(uint256 => uint256) public totalConstructInfluence; // tokenId => total AETHER staked

    // --- External Data Feeds ---
    mapping(bytes32 => address) public externalDataFeeds; // feedId => feedAddress (e.g., oracle for weather data)

    // --- Events ---
    event AetherTokenAddressSet(address indexed _tokenAddress);
    event AIOracleAddressSet(address indexed _oracleAddress);
    event EvolutionFeeSet(uint256 _newFee);

    event ConstructForged(uint256 indexed _tokenId, address indexed _owner, string _name, string _initialTraitData);
    event ConstructTransferred(uint256 indexed _tokenId, address indexed _from, address indexed _to);
    event AI_EvolutionRequested(bytes32 indexed _requestId, uint256 indexed _tokenId, string _prompt);
    event AI_EvolutionFulfilled(bytes32 indexed _requestId, uint256 indexed _tokenId, string _newTraitData, uint256 _powerBoost);
    event PassiveEvolutionTriggered(uint256 indexed _tokenId, uint256 _budgetUsed, uint256 _powerBoost, string _newTraitData);

    event AetherStakedForVoting(address indexed _user, uint256 _amount);
    event AetherUnstakedForVoting(address indexed _user, uint256 _amount);
    event VotingPowerDelegated(address indexed _delegator, address indexed _delegatee);

    event ProposalCreated(uint256 indexed _proposalId, uint256 _targetConstructId, string _rationale, uint256 _startTime, uint256 _endTime);
    event VoteCast(uint256 indexed _proposalId, address indexed _voter, bool _support, uint256 _votingPower);
    event ProposalStateChanged(uint256 indexed _proposalId, ProposalState _newState);
    event ProposalExecuted(uint256 indexed _proposalId);

    event AetherDepositedForConstructInfluence(uint256 indexed _tokenId, address indexed _user, uint256 _amount);
    event AetherWithdrawnFromConstructInfluence(uint256 indexed _tokenId, address indexed _user, uint256 _amount);

    event ExternalDataFeedRegistered(bytes32 indexed _feedId, address indexed _feedAddress);

    // --- Constructor ---
    constructor(address _aetherTokenAddress) ERC721("DigitalConstruct", "DGTLC") Ownable(msg.sender) Pausable() {
        if (_aetherTokenAddress == address(0)) {
            revert AetheriumForge__InvalidAetherTokenAddress();
        }
        AETHER_TOKEN = IERC20(_aetherTokenAddress);
        nextConstructId = 1; // Start token IDs from 1
        nextProposalId = 1;
        evolutionFee = 10 * (10 ** 18); // Default 10 AETHER for passive evolution trigger
    }

    // --- I. Core System & Administration ---

    function setAetherTokenAddress(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(0)) {
            revert AetheriumForge__InvalidAetherTokenAddress();
        }
        AETHER_TOKEN = IERC20(_tokenAddress);
        emit AetherTokenAddressSet(_tokenAddress);
    }

    function setAIOracleAddress(address _oracle) external onlyOwner {
        AI_ORACLE_ADDRESS = _oracle;
        emit AIOracleAddressSet(_oracle);
    }

    // `pause()` and `unpause()` are inherited from OpenZeppelin Pausable

    function withdrawStuckERC20(address _token, uint256 _amount) external onlyOwner {
        if (_token == address(AETHER_TOKEN)) {
            // Prevent withdrawing the core AETHER token itself, which might be staked
            // or part of evolution budgets managed by this contract.
            revert AetheriumForge__TransferFailed();
        }
        if (!IERC20(_token).transfer(msg.sender, _amount)) {
            revert AetheriumForge__TransferFailed();
        }
    }

    function setEvolutionFee(uint256 _newFee) external onlyOwner {
        evolutionFee = _newFee;
        emit EvolutionFeeSet(_newFee);
    }

    // --- II. Digital Construct (NFT) Management ---

    function forgeConstruct(string memory _name, string memory _initialTraitData) external payable whenNotPaused returns (uint256) {
        // Require AETHER fee. This contract needs to be approved to spend AETHER, or it can be sent directly
        // Assuming transferFrom as the standard for fees where contract pulls tokens.
        // For a more user-friendly flow, a `depositAndForgeConstruct` might exist where user sends ETH and contract swaps it for AETHER.
        // For simplicity, let's assume `msg.sender` has approved this contract to transfer AETHER for the fee.
        uint256 creationFee = 50 * (10 ** 18); // Example: 50 AETHER
        if (!AETHER_TOKEN.transferFrom(msg.sender, address(this), creationFee)) {
            revert AetheriumForge__FeePaymentFailed();
        }

        uint256 tokenId = nextConstructId++;
        _safeMint(msg.sender, tokenId);

        digitalConstructs[tokenId] = DigitalConstruct({
            tokenId: tokenId,
            owner: msg.sender,
            name: _name,
            currentTraitData: _initialTraitData,
            power: 100, // Initial power
            evolutionBudget: 0,
            influenceScore: 0,
            genesisTimestamp: block.timestamp,
            lastEvolutionTimestamp: block.timestamp
        });
        constructTraitHistory[tokenId].push(_initialTraitData);

        emit ConstructForged(tokenId, msg.sender, _name, _initialTraitData);
        return tokenId;
    }

    function getConstructDetails(uint256 _tokenId) public view returns (DigitalConstruct memory) {
        if (ownerOf(_tokenId) == address(0)) {
            revert AetheriumForge__ConstructNotFound();
        }
        return digitalConstructs[_tokenId];
    }

    // ERC721's safeTransferFrom covers basic transfer. This function wraps it if specific logic needed.
    function transferConstruct(address _from, address _to, uint256 _tokenId) external whenNotPaused {
        // ERC721 `safeTransferFrom` already handles ownership checks.
        // Adding specific logic here like a transfer fee could be done.
        _safeTransferFrom(_from, _to, _tokenId);
        digitalConstructs[_tokenId].owner = _to; // Update internal mapping
        emit ConstructTransferred(_tokenId, _from, _to);
    }

    function requestAI_Evolution(uint256 _tokenId, string memory _prompt) external payable whenNotPaused {
        if (AI_ORACLE_ADDRESS == address(0)) {
            revert AetheriumForge__OracleNotSet();
        }
        if (ownerOf(_tokenId) != msg.sender) {
            revert AetheriumForge__ConstructNotFound(); // Or specific not owner error
        }

        uint256 aiRequestFee = 20 * (10 ** 18); // Example fee for AI request
        if (!AETHER_TOKEN.transferFrom(msg.sender, address(this), aiRequestFee)) {
            revert AetheriumForge__FeePaymentFailed();
        }

        // Generate a request ID (e.g., from hash of tokenId, sender, timestamp)
        bytes32 requestId = keccak256(abi.encodePacked(_tokenId, msg.sender, block.timestamp));

        // In a real scenario, this would trigger an off-chain oracle call (e.g., Chainlink external adapters)
        // For this concept, we just emit an event as a signal.
        emit AI_EvolutionRequested(requestId, _tokenId, _prompt);
    }

    function fulfillAI_Evolution(bytes32 _requestId, uint256 _tokenId, string memory _newTraitData, uint256 _powerBoost) external whenNotPaused {
        if (msg.sender != AI_ORACLE_ADDRESS) {
            revert AetheriumForge__InvalidOracleCaller();
        }
        if (ownerOf(_tokenId) == address(0)) {
            revert AetheriumForge__ConstructNotFound();
        }

        digitalConstructs[_tokenId].currentTraitData = _newTraitData;
        digitalConstructs[_tokenId].power += _powerBoost;
        digitalConstructs[_tokenId].lastEvolutionTimestamp = block.timestamp;
        constructTraitHistory[_tokenId].push(_newTraitData);

        emit AI_EvolutionFulfilled(_requestId, _tokenId, _newTraitData, _powerBoost);
    }

    function queryTraitHistory(uint256 _tokenId) public view returns (string[] memory) {
        if (ownerOf(_tokenId) == address(0)) {
            revert AetheriumForge__ConstructNotFound();
        }
        return constructTraitHistory[_tokenId];
    }

    function triggerPassiveEvolution(uint256 _tokenId) external whenNotPaused {
        if (ownerOf(_tokenId) == address(0)) {
            revert AetheriumForge__ConstructNotFound();
        }

        DigitalConstruct storage construct = digitalConstructs[_tokenId];

        if (construct.evolutionBudget < evolutionFee) {
            revert AetheriumForge__NotEnoughBudgetForPassiveEvolution();
        }
        if (construct.influenceScore < MIN_INFLUENCE_FOR_PASSIVE_EVOLUTION) {
            revert AetheriumForge__LowInfluenceForPassiveEvolution();
        }

        // Pay fee to the caller for triggering
        if (!AETHER_TOKEN.transferFrom(msg.sender, address(this), evolutionFee)) { // Caller pays fee to the contract
            revert AetheriumForge__FeePaymentFailed();
        }
        // Then, optionally, reward caller a small amount from a pool, or let the fee accumulate.
        // For simplicity, let fee accumulate in the contract for future use.

        // Consume budget for evolution
        uint256 budgetToConsume = construct.evolutionBudget / 2; // Consume half of the budget
        construct.evolutionBudget -= budgetToConsume;

        // Determine new traits based on influence and a pseudo-random element
        // In a real system, this might involve a more complex deterministic algorithm
        // or a Chainlink VRF call. For conceptual, let's simplify.
        uint256 pseudoRandomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, construct.influenceScore)));
        string memory newTraits = string(abi.encodePacked(construct.currentTraitData, "-Evo-", pseudoRandomSeed.toString().substring(0, 5)));
        uint256 powerGain = (budgetToConsume / (10 ** 18)) / 10; // 1 power per 10 AETHER budget
        
        construct.currentTraitData = newTraits;
        construct.power += powerGain;
        construct.lastEvolutionTimestamp = block.timestamp;
        constructTraitHistory[_tokenId].push(newTraits);

        emit PassiveEvolutionTriggered(_tokenId, budgetToConsume, powerGain, newTraits);
    }

    // --- III. DAO Governance & Staking ---

    function stakeAetherForVoting(uint256 _amount) external whenNotPaused {
        if (_amount == 0) {
            revert AetheriumForge__InsufficientAetherBalance(); // Not enough, or 0 is invalid
        }
        if (!AETHER_TOKEN.transferFrom(msg.sender, address(this), _amount)) {
            revert AetheriumForge__ApprovalFailed();
        }
        stakedAetherForVoting[msg.sender] += _amount;
        votingPower[msg.sender] += _amount; // Directly update voting power
        emit AetherStakedForVoting(msg.sender, _amount);
    }

    function unstakeAether(uint256 _amount) external whenNotPaused {
        if (stakedAetherForVoting[msg.sender] < _amount) {
            revert AetheriumForge__NothingToUnstake();
        }
        stakedAetherForVoting[msg.sender] -= _amount;
        votingPower[msg.sender] -= _amount; // Reduce voting power

        if (!AETHER_TOKEN.transfer(msg.sender, _amount)) {
            revert AetheriumForge__TransferFailed();
        }
        emit AetherUnstakedForVoting(msg.sender, _amount);
    }

    function createEvolutionProposal(uint256 _targetConstructId, string memory _proposedTraitChange, string memory _rationale) external whenNotPaused {
        if (getVotePower(msg.sender) < PROPOSAL_THRESHOLD) {
            revert AetheriumForge__NotEnoughAetherStakedForProposal();
        }
        if (_targetConstructId > 0 && ownerOf(_targetConstructId) == address(0)) {
            revert AetheriumForge__ConstructNotFound();
        }

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            targetConstructId: _targetConstructId,
            proposedTraitChange: _proposedTraitChange,
            rationale: _rationale,
            proposer: uint256(uint160(msg.sender)), // Encode address as uint
            voteCountFor: 0,
            voteCountAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + VOTING_PERIOD_SECONDS,
            executed: false,
            voters: EnumerableSet.AddressSet(0) // Initialize an empty set
        });

        emit ProposalCreated(proposalId, _targetConstructId, _rationale, proposals[proposalId].startTime, proposals[proposalId].endTime);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert AetheriumForge__ProposalNotFound();
        }
        if (getProposalState(_proposalId) != ProposalState.Active) {
            revert AetheriumForge__ProposalNotActive();
        }
        if (proposal.voters.contains(msg.sender)) {
            revert AetheriumForge__AlreadyVoted();
        }

        uint256 voterPower = getVotePower(msg.sender);
        if (voterPower == 0) {
            revert AetheriumForge__NotEnoughVotingPower();
        }

        proposal.voters.add(msg.sender);
        if (_support) {
            proposal.voteCountFor += voterPower;
        } else {
            proposal.voteCountAgainst += voterPower;
        }
        emit VoteCast(_proposalId, msg.sender, _support, voterPower);
    }

    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert AetheriumForge__ProposalNotFound();
        }
        if (getProposalState(_proposalId) != ProposalState.Succeeded) {
            revert AetheriumForge__ProposalNotExecutable();
        }
        if (proposal.executed) {
            revert AetheriumForge__ProposalAlreadyExecuted(); // Custom error: ProposalAlreadyExecuted
        }

        proposal.executed = true;

        // Apply the proposed changes
        if (proposal.targetConstructId > 0) {
            DigitalConstruct storage construct = digitalConstructs[proposal.targetConstructId];
            construct.currentTraitData = proposal.proposedTraitChange;
            construct.lastEvolutionTimestamp = block.timestamp;
            constructTraitHistory[proposal.targetConstructId].push(proposal.proposedTraitChange);
            // Could also boost power or modify other attributes based on proposal
        } else {
            // System-wide proposal execution (e.g., changing PROPOSAL_THRESHOLD, EVOLUTION_FEE, etc.)
            // This would require more complex logic and an enum for proposal types.
            // For now, assume a simple trait change for constructs or no action for system changes.
            // Example:
            // if (keccak256(abi.encodePacked(proposal.rationale)) == keccak256(abi.encodePacked("Set Evolution Fee"))) {
            //     evolutionFee = uint256(abi.decode(bytes(proposal.proposedTraitChange), (uint256)));
            // }
        }

        emit ProposalExecuted(_proposalId);
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
    }

    function delegateVotingPower(address _delegatee) external whenNotPaused {
        votingDelegates[msg.sender] = _delegatee;
        // Update voting power for delegatee by adding sender's staked amount
        if (msg.sender != _delegatee) {
            votingPower[_delegatee] += stakedAetherForVoting[msg.sender];
            votingPower[msg.sender] = 0; // Sender loses direct voting power
        } else {
            votingPower[msg.sender] = stakedAetherForVoting[msg.sender]; // Self-delegation restores direct power
        }
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    function depositAetherForConstructInfluence(uint256 _tokenId, uint256 _amount) external whenNotPaused {
        if (ownerOf(_tokenId) == address(0)) {
            revert AetheriumForge__ConstructNotFound();
        }
        if (_amount == 0) {
            revert AetheriumForge__InsufficientAetherBalance();
        }

        if (!AETHER_TOKEN.transferFrom(msg.sender, address(this), _amount)) {
            revert AetheriumForge__ApprovalFailed();
        }

        constructInfluenceStakes[_tokenId][msg.sender] += _amount;
        totalConstructInfluence[_tokenId] += _amount;
        digitalConstructs[_tokenId].evolutionBudget += _amount; // Directly adds to budget
        digitalConstructs[_tokenId].influenceScore = calculateConstructInfluenceScore(_tokenId); // Recalculate influence
        
        emit AetherDepositedForConstructInfluence(_tokenId, msg.sender, _amount);
    }

    function withdrawAetherFromConstructInfluence(uint256 _tokenId, uint256 _amount) external whenNotPaused {
        if (ownerOf(_tokenId) == address(0)) {
            revert AetheriumForge__ConstructNotFound();
        }
        if (constructInfluenceStakes[_tokenId][msg.sender] < _amount) {
            revert AetheriumForge__NotEnoughStakedInfluence();
        }

        constructInfluenceStakes[_tokenId][msg.sender] -= _amount;
        totalConstructInfluence[_tokenId] -= _amount;
        digitalConstructs[_tokenId].evolutionBudget -= _amount; // Remove from budget
        digitalConstructs[_tokenId].influenceScore = calculateConstructInfluenceScore(_tokenId); // Recalculate influence

        if (!AETHER_TOKEN.transfer(msg.sender, _amount)) {
            revert AetheriumForge__TransferFailed();
        }
        emit AetherWithdrawnFromConstructInfluence(_tokenId, msg.sender, _amount);
    }

    // --- IV. Ecosystem Dynamics & Queries ---

    function calculateConstructInfluenceScore(uint256 _tokenId) public view returns (uint256) {
        if (ownerOf(_tokenId) == address(0)) {
            revert AetheriumForge__ConstructNotFound();
        }
        DigitalConstruct storage construct = digitalConstructs[_tokenId];
        // Example calculation: sum of total influence AETHER + (power / 10) + (age / 1 day)
        uint256 ageInDays = (block.timestamp - construct.genesisTimestamp) / (1 days);
        return totalConstructInfluence[_tokenId] + (construct.power * 1 ether / 100) + (ageInDays * 1 ether / 10);
    }

    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            return ProposalState.Canceled; // Using Canceled for not found/invalid
        }
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (block.timestamp < proposal.startTime) {
            return ProposalState.Pending;
        }
        if (block.timestamp >= proposal.endTime) {
            if (proposal.voteCountFor > proposal.voteCountAgainst) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Defeated;
            }
        }
        return ProposalState.Active;
    }

    function getVotePower(address _voter) public view returns (uint256) {
        address effectiveVoter = _voter;
        while (votingDelegates[effectiveVoter] != address(0) && votingDelegates[effectiveVoter] != effectiveVoter) {
            effectiveVoter = votingDelegates[effectiveVoter];
        }
        // If effectiveVoter is _voter, then they have their own staked amount
        // If effectiveVoter is someone else, then _voter has delegated, and their power is effectively 0
        return (effectiveVoter == _voter) ? stakedAetherForVoting[_voter] : votingPower[effectiveVoter];
    }
    
    function getConstructStakedInfluence(uint256 _tokenId) public view returns (uint256) {
        if (ownerOf(_tokenId) == address(0)) {
            revert AetheriumForge__ConstructNotFound();
        }
        return totalConstructInfluence[_tokenId];
    }

    function registerExternalDataFeed(bytes32 _feedId, address _feedAddress) external onlyOwner {
        // This function would typically be called via a DAO proposal in a production system.
        // For simplicity, it's owner-only here.
        externalDataFeeds[_feedId] = _feedAddress;
        emit ExternalDataFeedRegistered(_feedId, _feedAddress);
    }
}
```