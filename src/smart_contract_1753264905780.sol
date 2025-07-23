```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interfaces for external contracts/oracles
// In a real-world scenario, this would likely be Chainlink Functions, Keepers, or a custom oracle network.
interface IAetherOracle {
    // Requests AI-driven evolution data for a specific AetherGenerator
    function requestEvolutionData(uint256 _generatorId, string memory _prompt) external returns (bytes32);
    // Requests AI-driven sentiment analysis for generic text data
    function requestSentimentAnalysis(bytes memory _data) external returns (bytes32);
    // Requests external verification for a real-world impact project
    function requestImpactVerification(uint256 _projectId) external returns (bytes32);
    // Add other oracle request types as needed (e.g., market data, external event triggers)
}

// --- OUTLINE & FUNCTION SUMMARY ---
//
// Contract Name: AetherNexus
// Description: AetherNexus is a Self-Evolving Decentralized Autonomous Protocol (SE-DAP) that combines generative NFTs
//              (AetherGenerators), a dynamic governance token (NexusEssence), an advanced DAO (AetherCore),
//              and an adaptive treasury with a focus on impact funding. It leverages oracle integration for
//              AI-driven insights and external data verification, allowing the protocol and its digital artifacts
//              to dynamically evolve and contribute to real-world positive impact.
//
// Core Concepts:
// 1.  Generative & Evolving NFTs (AetherGenerators): NFTs with mutable traits that can evolve based on protocol
//     actions, user input, and AI insights provided by oracles.
// 2.  Dynamic Governance (AetherCore DAO): Voting power is not static based on token balance alone, but evolves
//     with a "Contribution Score" that rewards long-term engagement, successful proposal participation, and NFT activity.
// 3.  AI-Enhanced Decision Making (via Oracles): The DAO and NFT evolution can query AI models (off-chain)
//     through an oracle for sentiment analysis, generative data, or risk assessment.
// 4.  Symbiotic Treasury & Regenerative Finance (ReFi): A portion of treasury funds can be specifically allocated
//     to verifiable real-world impact projects, incentivizing positive externalities.
// 5.  Adaptive Protocol Parameters: Core parameters of the protocol can be adjusted by the DAO or dynamically
//     based on predefined conditions, enabling self-optimization.
//
// --- FUNCTIONS LIST ---
//
// I. Core Infrastructure & Tokenomics (ERC20, ERC721):
//    1.  constructor(address _initialOwner): Initializes the protocol, deploys NexusEssence and AetherGenerator,
//        sets initial owner and parameters.
//    2.  nexusEssence(): Returns the address of the NexusEssence ERC20 token contract.
//    3.  aetherGenerator(): Returns the address of the AetherGenerator ERC721 token contract.
//    4.  setOracleAddress(address _oracle): Sets the address of the trusted oracle contract for external data.
//    5.  mintEssence(address _to, uint256 _amount): Mints new NexusEssence tokens. Restricted to owner/DAO.
//    6.  burnEssence(uint256 _amount): Burns NexusEssence tokens from caller's balance.
//    7.  createAetherGenerator(string memory _initialPromptURI): Mints a new AetherGenerator NFT. Requires Essence burn.
//    8.  getAetherGeneratorTraits(uint256 _tokenId): Retrieves the current traits (URI) of an AetherGenerator.
//
// II. DAO & Governance (AetherCore):
//    9.  submitProposal(string memory _description, address _target, bytes memory _calldata, uint256 _eta):
//        Allows users to submit a new governance proposal for on-chain action.
//    10. voteOnProposal(uint256 _proposalId, bool _support): Users cast their vote (for/against) on a proposal.
//    11. executeProposal(uint256 _proposalId): Executes a proposal if it has passed the voting period and thresholds.
//    12. calculateDynamicVotingPower(address _voter): Calculates a user's evolving voting power based on Essence
//        holding duration, successful proposal participation, and AetherGenerator activity.
//    13. updateCoreParameter(bytes32 _paramHash, uint256 _newValue): DAO-executable function to update critical
//        protocol parameters (e.g., proposal thresholds, essence burn rates).
//    14. requestAISentimentAnalysis(uint256 _proposalId, bytes memory _data): Requests the oracle to perform
//        sentiment analysis on proposal details, which can influence DAO members' decisions.
//    15. fulfillAISentimentAnalysis(bytes32 _requestId, int256 _sentimentScore): Callback from the oracle for
//        sentiment analysis results, updating internal proposal data.
//
// III. AetherGenerator Evolution & Interaction:
//    16. requestAIEvolutionData(uint256 _generatorId, string memory _prompt): Requests AI-driven evolution data
//        (e.g., new trait suggestions, generative art components) from the oracle for a specific Generator.
//    17. fulfillAIEvolutionData(bytes32 _requestId, uint256 _generatorId, string memory _newTraitsURI): Callback
//        from the oracle providing new evolution data for a Generator.
//    18. evolveAetherGenerator(uint256 _tokenId): Triggers the evolution of an AetherGenerator. Consumes pending
//        AI evolution data and requires NexusEssence burn.
//    19. seedAetherGenerator(uint256 _tokenId, string memory _seedURI): Allows owners to "seed" a Generator
//        with an external URI (e.g., IPFS hash of a custom input for AI generation).
//
// IV. Treasury & Impact Funding:
//    20. depositToTreasury(): Allows anyone to deposit ETH into the protocol's treasury.
//    21. allocateTreasuryFunds(address _recipient, uint256 _amount, string memory _purpose): DAO-controlled
//        function to allocate treasury funds, with a specific focus on impact projects.
//    22. requestImpactVerification(uint256 _projectId): Requests the oracle to verify the completion/impact of
//        a specific real-world project funded by the treasury.
//    23. fulfillImpactVerification(bytes32 _requestId, uint256 _projectId, bool _verified): Callback from
//        the oracle confirming impact project verification.
//
// V. Emergency & Maintenance:
//    24. emergencyPause(): Allows the owner/DAO to pause critical functions in an emergency.
//    25. unpause(): Allows the owner/DAO to unpause the contract.
//    26. retrieveContractBalance(address _tokenAddress): Allows the owner/DAO to retrieve accidentally sent ERC20
//        tokens from the contract.
//    27. retrieveETHBalance(): Allows the owner/DAO to retrieve accidentally sent ETH from the contract.
//    28. receive(): Fallback function to receive direct ETH deposits into the treasury.
//
// Note: This contract demonstrates advanced concepts. Real-world implementation would require extensive
//       auditing, gas optimization, and robust oracle integration (e.g., Chainlink VRF/Keepers/Functions).
//       The "AI" interaction is via an external oracle, as direct on-chain AI is not feasible for complex tasks.
// --- END OF OUTLINE & SUMMARY ---

contract AetherNexus is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Token Contracts (immutable references to deployed instances)
    NexusEssence public immutable essenceToken;
    AetherGenerator public immutable aetherGeneratorToken;

    // Oracle Integration
    IAetherOracle public oracle; // Address of the trusted oracle contract
    mapping(bytes32 => RequestType) public oracleRequests; // Maps request ID to its type
    mapping(bytes32 => uint256) public oracleRequestIds; // Maps request ID to the associated entity ID (generatorId, proposalId, projectId)

    enum RequestType { None, EvolutionData, SentimentAnalysis, ImpactVerification } // Types of oracle requests

    // DAO / Governance
    struct Proposal {
        uint256 id;
        string description;
        address target; // Contract address to call
        bytes calldata; // Encoded function call data
        uint256 eta; // Execution timestamp (earliest time it can be executed)
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        bool executed;
        bool canceled;
        uint256 submissionTime;
        int256 aiSentimentScore; // AI sentiment score for the proposal (e.g., -100 to 100)
    }
    Counters.Counter private _proposalIds; // Counter for unique proposal IDs
    mapping(uint256 => Proposal) public proposals; // Stores all proposals
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // Duration for voting on a proposal
    uint256 public constant PROPOSAL_EXECUTION_DELAY = 1 days; // Delay after voting ends before execution is possible
    uint256 public proposalQuorumThreshold = 100e18; // Minimum total voting power required for a proposal to be valid (100 Essence equivalent)
    uint256 public proposalPassRate = 6000; // 60.00% (6000/10000 basis points) of 'votesFor' required to pass

    // AetherGenerator Evolution
    struct GeneratorEvolutionState {
        string pendingNewTraitsURI; // New URI from oracle, awaiting evolution
        bool hasPendingEvolutionData; // True if oracle data is pending for this generator
    }
    mapping(uint256 => GeneratorEvolutionState) public generatorEvolutionStates;

    // Treasury & Funds
    address public constant TREASURY_ADDRESS = address(this); // Funds are held directly by this contract
    uint256 public impactFundingAllocated; // Sum of funds explicitly allocated to impact projects

    // Core Parameters (flexible protocol parameters, updatable by DAO proposals)
    mapping(bytes32 => uint256) public coreParameters;

    // Pausability (emergency brake)
    bool public paused = false;

    // Events
    event OracleAddressSet(address indexed _oracle);
    event EssenceMinted(address indexed _to, uint256 _amount);
    event EssenceBurned(address indexed _from, uint256 _amount);
    event AetherGeneratorCreated(uint256 indexed _tokenId, address indexed _owner, string _initialPromptURI);
    event AetherGeneratorEvolutionRequested(uint256 indexed _tokenId, string _prompt, bytes32 _requestId);
    event AetherGeneratorEvolutionFulfilled(uint256 indexed _tokenId, string _newTraitsURI, bytes32 _requestId);
    event AetherGeneratorEvolved(uint256 indexed _tokenId, string _newTraitsURI, uint256 _evolutionCount);
    event AetherGeneratorSeeded(uint256 indexed _tokenId, string _seedURI);
    event ProposalSubmitted(uint256 indexed _proposalId, address indexed _proposer);
    event VoteCast(uint256 indexed _proposalId, address indexed _voter, bool _support, uint256 _votingPower);
    event ProposalExecuted(uint256 indexed _proposalId);
    event ProposalCanceled(uint256 indexed _proposalId); // Not explicitly implemented but good practice for DAOs
    event AISentimentAnalysisRequested(uint256 indexed _proposalId, bytes32 _requestId);
    event AISentimentAnalysisFulfilled(uint256 indexed _proposalId, int256 _sentimentScore, bytes32 _requestId);
    event TreasuryDeposit(address indexed _from, uint256 _amount);
    event FundsAllocated(address indexed _recipient, uint256 _amount, string _purpose);
    event ImpactVerificationRequested(uint256 indexed _projectId, bytes32 _requestId);
    event ImpactVerificationFulfilled(uint256 indexed _projectId, bool _verified, bytes32 _requestId);
    event CoreParameterUpdated(bytes32 _paramHash, uint256 _oldValue, uint256 _newValue);
    event Paused(address account);
    event Unpaused(address account);

    // Modifiers
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == address(oracle), "Only oracle can call this function");
        _;
    }

    // --- Constructor ---

    constructor(address _initialOwner) Ownable(_initialOwner) {
        // Deploy NexusEssence ERC20 token
        essenceToken = new NexusEssence(address(this)); // This contract (AetherNexus) is the designated minter
        // Deploy AetherGenerator ERC721 token
        aetherGeneratorToken = new AetherGenerator(address(this)); // This contract (AetherNexus) is the designated minter

        // Initialize some core parameters
        coreParameters[keccak256("ESSENCE_BURN_RATE_GENERATOR")] = 10e18; // 10 Essence tokens per Generator creation
        coreParameters[keccak256("ESSENCE_BURN_RATE_EVOLUTION")] = 5e18; // 5 Essence tokens per Generator evolution
    }

    // --- I. Core Infrastructure & Tokenomics (ERC20, ERC721) ---

    /**
     * @notice Returns the address of the NexusEssence ERC20 token contract.
     */
    function nexusEssence() public view returns (NexusEssence) {
        return essenceToken;
    }

    /**
     * @notice Returns the address of the AetherGenerator ERC721 token contract.
     */
    function aetherGenerator() public view returns (AetherGenerator) {
        return aetherGeneratorToken;
    }

    /**
     * @notice Sets the address of the trusted oracle contract.
     * @param _oracle The address of the oracle contract.
     * @dev Only callable by the owner initially. In a fully decentralized DAO, this would be
     *      set/updated via a successful governance proposal.
     */
    function setOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        oracle = IAetherOracle(_oracle);
        emit OracleAddressSet(_oracle);
    }

    /**
     * @notice Mints new NexusEssence tokens.
     * @param _to The recipient address.
     * @param _amount The amount of tokens to mint.
     * @dev Restricted to owner (simulating initial supply or DAO-controlled emissions).
     */
    function mintEssence(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        essenceToken.mint(_to, _amount);
        emit EssenceMinted(_to, _amount);
    }

    /**
     * @notice Burns NexusEssence tokens from the caller's balance.
     * @param _amount The amount of tokens to burn.
     */
    function burnEssence(uint256 _amount) public whenNotPaused {
        essenceToken.burn(msg.sender, _amount);
        emit EssenceBurned(msg.sender, _amount);
    }

    /**
     * @notice Mints a new AetherGenerator NFT. Requires burning NexusEssence tokens.
     * @param _initialPromptURI An initial URI/hash for the generator's traits or generative prompt.
     *        This could be an IPFS hash pointing to a JSON metadata file, including properties
     *        relevant for generative AI.
     * @return The ID of the newly minted AetherGenerator.
     */
    function createAetherGenerator(string memory _initialPromptURI) public whenNotPaused returns (uint256) {
        uint256 burnAmount = coreParameters[keccak256("ESSENCE_BURN_RATE_GENERATOR")];
        require(essenceToken.balanceOf(msg.sender) >= burnAmount, "Insufficient Essence to create Generator");
        essenceToken.burn(msg.sender, burnAmount);

        uint256 tokenId = aetherGeneratorToken.mint(msg.sender, _initialPromptURI);
        emit AetherGeneratorCreated(tokenId, msg.sender, _initialPromptURI);
        return tokenId;
    }

    /**
     * @notice Retrieves the current traits (URI) of an AetherGenerator NFT.
     * @param _tokenId The ID of the AetherGenerator.
     * @return The URI representing the generator's current traits.
     */
    function getAetherGeneratorTraits(uint256 _tokenId) public view returns (string memory) {
        return aetherGeneratorToken.tokenURI(_tokenId);
    }

    // --- II. DAO & Governance (AetherCore) ---

    /**
     * @notice Allows users to submit a new governance proposal for on-chain action.
     * @param _description A detailed description of the proposal.
     * @param _target The address of the contract to call if the proposal passes.
     * @param _calldata The encoded function call data for the target contract.
     * @param _eta The timestamp at which the proposal can be executed (should be after voting + execution delay).
     * @return The ID of the newly created proposal.
     */
    function submitProposal(string memory _description, address _target, bytes memory _calldata, uint256 _eta)
        public
        whenNotPaused
        returns (uint256)
    {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        require(_eta > block.timestamp + PROPOSAL_VOTING_PERIOD + PROPOSAL_EXECUTION_DELAY, "ETA too soon: requires voting period + execution delay");

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.description = _description;
        newProposal.target = _target;
        newProposal.calldata = _calldata;
        newProposal.eta = _eta;
        newProposal.submissionTime = block.timestamp;
        newProposal.aiSentimentScore = 0; // Default sentiment score, updated by oracle callback

        emit ProposalSubmitted(proposalId, msg.sender);
        return proposalId;
    }

    /**
     * @notice Users cast their vote (for/against) on a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp < proposal.submissionTime + PROPOSAL_VOTING_PERIOD, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal has been canceled");

        uint256 votingPower = calculateDynamicVotingPower(msg.sender);
        require(votingPower > 0, "Voter has no dynamic voting power");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Executes a proposal if it has passed the voting period and thresholds.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.submissionTime + PROPOSAL_VOTING_PERIOD, "Voting period not ended yet");
        require(block.timestamp >= proposal.eta, "Execution time not reached yet");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal has been canceled");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes >= proposalQuorumThreshold, "Quorum not met: not enough total votes");
        require(proposal.votesFor * 10000 / totalVotes >= proposalPassRate, "Proposal failed to pass: insufficient 'for' votes percentage");

        proposal.executed = true;

        // Execute the proposed action using low-level call
        // This allows the DAO to call any function on any contract.
        (bool success,) = proposal.target.call(proposal.calldata);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Calculates a user's evolving voting power.
     * @dev This is a simplified example. In a real system, `calculateDynamicVotingPower` could be
     *      much more complex, potentially involving:
     *      - Time-weighted average balance (requires storing historical balances or using snapshots).
     *      - Successful proposal participation (tracking how many successful proposals a user voted for).
     *      - AetherGenerator evolution progress or unique traits.
     *      - Verifiable Credentials (SBT-like attestations) from an identity system.
     * @param _voter The address of the voter.
     * @return The calculated dynamic voting power.
     */
    function calculateDynamicVotingPower(address _voter) public view returns (uint256) {
        uint256 basePower = essenceToken.balanceOf(_voter); // Direct token balance
        uint256 generatorBonus = aetherGeneratorToken.balanceOf(_voter) * 1e18 / 10; // Example: 0.1 Essence equivalent per Generator owned

        // Example for "contribution score":
        // If a user holds a significant amount of Essence, give them a bonus.
        if (basePower >= 100e18) { // If holds at least 100 Essence
            basePower += basePower / 10; // 10% bonus for larger holders
        }
        // Could add more complex logic here for real "dynamic" power based on engagement history.

        return basePower + generatorBonus;
    }

    /**
     * @notice DAO-executable function to update critical protocol parameters.
     * @param _paramHash The keccak256 hash of the parameter name (e.g., `keccak256("PROPOSAL_QUORUM_THRESHOLD")`).
     * @param _newValue The new value for the parameter.
     * @dev This function should only be callable via a successful DAO proposal's `executeProposal`.
     *      For this example, it's set to `onlyOwner` to simulate the administrative control of the DAO.
     */
    function updateCoreParameter(bytes32 _paramHash, uint256 _newValue) public onlyOwner whenNotPaused {
        require(_paramHash != bytes32(0), "Param hash cannot be zero");

        uint256 oldValue = coreParameters[_paramHash];
        coreParameters[_paramHash] = _newValue;

        // Specific handling for common parameters to update their direct state variables
        if (_paramHash == keccak256("PROPOSAL_QUORUM_THRESHOLD")) {
            proposalQuorumThreshold = _newValue;
        } else if (_paramHash == keccak256("PROPOSAL_PASS_RATE")) {
            require(_newValue <= 10000, "Pass rate cannot exceed 100%"); // Max 10000 basis points
            proposalPassRate = _newValue;
        }
        // Add more `else if` for other direct state variables if needed.

        emit CoreParameterUpdated(_paramHash, oldValue, _newValue);
    }

    /**
     * @notice Requests the oracle to perform sentiment analysis on proposal details.
     * @param _proposalId The ID of the proposal to analyze.
     * @param _data The data to send to the oracle for analysis (e.g., IPFS hash of proposal text, or a summary).
     * @dev Only callable by owner (simulating a DAO decision or a specific protocol role).
     */
    function requestAISentimentAnalysis(uint256 _proposalId, bytes memory _data) public onlyOwner whenNotPaused {
        require(address(oracle) != address(0), "Oracle not set");
        require(proposals[_proposalId].id != 0, "Proposal does not exist");
        require(block.timestamp < proposals[_proposalId].submissionTime + PROPOSAL_VOTING_PERIOD, "Cannot request sentiment analysis after voting period ends");

        bytes32 requestId = oracle.requestSentimentAnalysis(_data);
        oracleRequests[requestId] = RequestType.SentimentAnalysis;
        oracleRequestIds[requestId] = _proposalId;

        emit AISentimentAnalysisRequested(_proposalId, requestId);
    }

    /**
     * @notice Callback from the oracle for sentiment analysis results.
     * @param _requestId The ID of the original oracle request.
     * @param _sentimentScore The sentiment score returned by the AI (e.g., an integer from -100 to 100).
     * @dev Only callable by the trusted oracle. This data can inform future voter decisions.
     */
    function fulfillAISentimentAnalysis(bytes32 _requestId, int256 _sentimentScore) public onlyOracle {
        require(oracleRequests[_requestId] == RequestType.SentimentAnalysis, "Invalid request type for fulfillment");

        uint256 proposalId = oracleRequestIds[_requestId];
        proposals[proposalId].aiSentimentScore = _sentimentScore; // Update the proposal's sentiment score

        delete oracleRequests[_requestId]; // Clear the pending request
        delete oracleRequestIds[_requestId];

        emit AISentimentAnalysisFulfilled(proposalId, _sentimentScore, _requestId);
    }

    // --- III. AetherGenerator Evolution & Interaction ---

    /**
     * @notice Requests AI-driven evolution data from the oracle for a specific AetherGenerator.
     * @param _generatorId The ID of the AetherGenerator to evolve.
     * @param _prompt A prompt or context string for the AI to generate new traits. This could be
     *        based on current traits, owner's preferences, or external data.
     * @dev Only callable by the AetherGenerator owner.
     */
    function requestAIEvolutionData(uint256 _generatorId, string memory _prompt) public whenNotPaused {
        require(aetherGeneratorToken.ownerOf(_generatorId) == msg.sender, "Not owner of AetherGenerator");
        require(address(oracle) != address(0), "Oracle not set");
        require(!generatorEvolutionStates[_generatorId].hasPendingEvolutionData, "Generator already has pending evolution data");

        bytes32 requestId = oracle.requestEvolutionData(_generatorId, _prompt);
        oracleRequests[requestId] = RequestType.EvolutionData;
        oracleRequestIds[requestId] = _generatorId;

        emit AetherGeneratorEvolutionRequested(_generatorId, _prompt, requestId);
    }

    /**
     * @notice Callback from the oracle providing new evolution data (new traits URI) for an AetherGenerator.
     * @param _requestId The ID of the original oracle request.
     * @param _generatorId The ID of the AetherGenerator.
     * @param _newTraitsURI The new URI/hash representing the evolved traits, likely an IPFS hash.
     * @dev Only callable by the trusted oracle. This sets the data that can be "applied" by `evolveAetherGenerator`.
     */
    function fulfillAIEvolutionData(bytes32 _requestId, uint256 _generatorId, string memory _newTraitsURI) public onlyOracle {
        require(oracleRequests[_requestId] == RequestType.EvolutionData, "Invalid request type for fulfillment");
        require(oracleRequestIds[_requestId] == _generatorId, "Mismatched generator ID for request");

        GeneratorEvolutionState storage state = generatorEvolutionStates[_generatorId];
        state.pendingNewTraitsURI = _newTraitsURI;
        state.hasPendingEvolutionData = true;

        delete oracleRequests[_requestId]; // Clear the pending request
        delete oracleRequestIds[_requestId];

        emit AetherGeneratorEvolutionFulfilled(_generatorId, _newTraitsURI, _requestId);
    }

    /**
     * @notice Triggers the evolution of an AetherGenerator. Consumes pending AI evolution data
     *         and requires NexusEssence burn.
     * @param _tokenId The ID of the AetherGenerator to evolve.
     */
    function evolveAetherGenerator(uint256 _tokenId) public whenNotPaused {
        require(aetherGeneratorToken.ownerOf(_tokenId) == msg.sender, "Not owner of AetherGenerator");

        GeneratorEvolutionState storage state = generatorEvolutionStates[_tokenId];
        require(state.hasPendingEvolutionData, "No pending evolution data for this Generator. Request AI data first.");

        uint256 burnAmount = coreParameters[keccak256("ESSENCE_BURN_RATE_EVOLUTION")];
        require(essenceToken.balanceOf(msg.sender) >= burnAmount, "Insufficient Essence for evolution");
        essenceToken.burn(msg.sender, burnAmount); // Burn Essence from the caller

        aetherGeneratorToken.updateTokenURI(_tokenId, state.pendingNewTraitsURI); // Update the NFT's metadata URI
        aetherGeneratorToken.incrementEvolutionCount(_tokenId); // Increment its evolution counter

        delete state.pendingNewTraitsURI; // Clear pending data
        state.hasPendingEvolutionData = false;

        emit AetherGeneratorEvolved(_tokenId, aetherGeneratorToken.tokenURI(_tokenId), aetherGeneratorToken.getEvolutionCount(_tokenId));
    }

    /**
     * @notice Allows owners to "seed" an AetherGenerator with an external URI,
     *         potentially for future AI generation or trait updates. This data could be
     *         referenced by a later `requestAIEvolutionData` call.
     * @param _tokenId The ID of the AetherGenerator.
     * @param _seedURI An IPFS hash or URL for the seed data.
     */
    function seedAetherGenerator(uint256 _tokenId, string memory _seedURI) public whenNotPaused {
        require(aetherGeneratorToken.ownerOf(_tokenId) == msg.sender, "Not owner of AetherGenerator");
        require(bytes(_seedURI).length > 0, "Seed URI cannot be empty");
        // This function doesn't automatically update the NFT's traits, but it signals
        // a user's intent to influence future evolution. The _seedURI could be stored
        // internally in AetherGenerator if per-NFT seed state is needed.
        emit AetherGeneratorSeeded(_tokenId, _seedURI);
    }

    // --- IV. Treasury & Impact Funding ---

    /**
     * @notice Fallback function to receive direct ETH deposits into the protocol's treasury.
     */
    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /**
     * @notice Explicit function to allow anyone to deposit ETH into the protocol's treasury.
     */
    function depositToTreasury() public payable whenNotPaused {
        // Funds are received by the `receive()` function, this simply provides an explicit entry point.
        // No additional logic needed here, as `receive()` handles the ETH transfer and event.
    }

    /**
     * @notice DAO-controlled function to allocate treasury funds to a recipient.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of ETH to send.
     * @param _purpose A description of the allocation purpose (e.g., "development", "liquidity_provision", "impact_project_X").
     * @dev This function is intended to be called by a successful DAO proposal.
     *      For this example, it's set to `onlyOwner` to simulate the administrative control of the DAO.
     */
    function allocateTreasuryFunds(address _recipient, uint256 _amount, string memory _purpose) public onlyOwner whenNotPaused nonReentrant {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(address(this).balance >= _amount, "Insufficient treasury balance");

        // Special tracking for funds allocated towards impact projects
        if (keccak256(abi.encodePacked(_purpose)) == keccak256(abi.encodePacked("impact_project"))) {
            impactFundingAllocated += _amount; // Track total impact funding
        }

        (bool success,) = _recipient.call{value: _amount}("");
        require(success, "Failed to allocate treasury funds");

        emit FundsAllocated(_recipient, _amount, _purpose);
    }

    /**
     * @notice Requests the oracle to verify the completion/impact of a specific real-world project.
     * @param _projectId An identifier for the real-world project (could be an ID from an external registry).
     * @dev Only callable by owner (simulating a DAO decision or a specific protocol role).
     */
    function requestImpactVerification(uint256 _projectId) public onlyOwner whenNotPaused {
        require(address(oracle) != address(0), "Oracle not set");

        bytes32 requestId = oracle.requestImpactVerification(_projectId);
        oracleRequests[requestId] = RequestType.ImpactVerification;
        oracleRequestIds[requestId] = _projectId;

        emit ImpactVerificationRequested(_projectId, requestId);
    }

    /**
     * @notice Callback from the oracle confirming impact project verification.
     * @param _requestId The ID of the original oracle request.
     * @param _projectId The ID of the real-world project.
     * @param _verified True if verified, false otherwise.
     * @dev Only callable by the trusted oracle. This data could trigger further on-chain actions
     *      like releasing bonus funds, updating a project's status, or affecting governance reputation.
     */
    function fulfillImpactVerification(bytes32 _requestId, uint256 _projectId, bool _verified) public onlyOracle {
        require(oracleRequests[_requestId] == RequestType.ImpactVerification, "Invalid request type for fulfillment");
        require(oracleRequestIds[_requestId] == _projectId, "Mismatched project ID for request");

        // Example: Here, the contract can record the verification status.
        // E.g., `mapping(uint256 => bool) public verifiedImpactProjects;`
        // `verifiedImpactProjects[_projectId] = _verified;`
        // Or trigger a reward mechanism if impact is verified:
        // `if (_verified) essenceToken.mint(recipientForImpact, 10e18);`
        // This specific action is left as a conceptual placeholder to keep the code concise.

        delete oracleRequests[_requestId]; // Clear the pending request
        delete oracleRequestIds[_requestId];

        emit ImpactVerificationFulfilled(_projectId, _verified, _requestId);
    }

    // --- V. Emergency & Maintenance ---

    /**
     * @notice Allows the owner to pause critical contract functions in an emergency.
     * @dev Only callable by the owner (or eventually via a DAO emergency proposal).
     */
    function emergencyPause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Allows the owner to unpause the contract.
     * @dev Only callable by the owner (or eventually via a DAO emergency proposal).
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Allows the owner to retrieve accidentally sent ERC20 tokens from the contract.
     * @param _tokenAddress The address of the ERC20 token to retrieve.
     * @dev Only callable by the owner. This is a safeguard against accidental token transfers.
     */
    function retrieveContractBalance(address _tokenAddress) public onlyOwner nonReentrant {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        ERC20 token = ERC20(_tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    /**
     * @notice Allows the owner to retrieve accidentally sent ETH from the contract.
     * @dev Only callable by the owner. This is a safeguard for ETH not explicitly meant for treasury allocation.
     */
    function retrieveETHBalance() public onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        // This retrieves all ETH, assuming the owner/DAO has the responsibility to manage it.
        (bool success, ) = owner().call{value: contractBalance}("");
        require(success, "Failed to retrieve ETH balance");
    }
}

// --- Nested Token Contracts ---
// These are defined as separate contracts but are deployed by the AetherNexus constructor.
// They extend OpenZeppelin's standard implementations but add custom logic for minting/burning
// to be controlled by the `AetherNexus` contract.

contract NexusEssence is ERC20, Ownable {
    address public minter; // The AetherNexus contract is the designated minter

    constructor(address _minter) ERC20("NexusEssence", "ESS") Ownable(msg.sender) {
        minter = _minter;
    }

    /**
     * @dev Overrides the ERC20 mint function to restrict minting to the AetherNexus contract.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public {
        require(msg.sender == minter, "Only AetherNexus can mint ESS");
        _mint(to, amount);
    }

    /**
     * @dev Overrides the ERC20 burn function to allow anyone to burn their own tokens.
     *      This is called by AetherNexus indirectly via `essenceToken.burn(msg.sender, amount)`.
     * @param from The address whose tokens are to be burned.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) public {
        // Allows self-burning or AetherNexus to burn from a user's allowance if approved.
        // For simplicity, directly checking `from == msg.sender` or `msg.sender == minter`.
        // In this architecture, AetherNexus will call this with `msg.sender` as `from`.
        require(from == msg.sender || msg.sender == minter, "Can only burn your own tokens or be the minter");
        _burn(from, amount);
    }
}

contract AetherGenerator is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address public minter; // The AetherNexus contract is the designated minter

    // Mapping to store evolution count for each generator
    mapping(uint256 => uint256) private _evolutionCounts;

    constructor(address _minter) ERC721("AetherGenerator", "AEG") Ownable(msg.sender) {
        minter = _minter;
    }

    /**
     * @dev Mints a new AetherGenerator token and assigns its initial URI.
     * @param to The recipient of the new token.
     * @param tokenURI The initial URI for the token's metadata (e.g., IPFS hash).
     * @return The ID of the newly minted token.
     */
    function mint(address to, string memory tokenURI) public returns (uint256) {
        require(msg.sender == minter, "Only AetherNexus can mint AEG");
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _evolutionCounts[newItemId] = 0; // Initialize evolution count for new generator
        return newItemId;
    }

    /**
     * @dev Updates the token URI for an existing AetherGenerator.
     * @param tokenId The ID of the token to update.
     * @param newURI The new URI for the token's metadata, representing its evolved state.
     */
    function updateTokenURI(uint256 tokenId, string memory newURI) public {
        require(msg.sender == minter, "Only AetherNexus can update URI");
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        _setTokenURI(tokenId, newURI);
    }

    /**
     * @dev Increments the evolution count for a specific AetherGenerator.
     * @param tokenId The ID of the token to update.
     */
    function incrementEvolutionCount(uint256 tokenId) public {
        require(msg.sender == minter, "Only AetherNexus can increment evolution count");
        require(_exists(tokenId), "ERC721Metadata: Evolution count for nonexistent token");
        _evolutionCounts[tokenId]++;
    }

    /**
     * @dev Returns the current evolution count for a specific AetherGenerator.
     * @param tokenId The ID of the token.
     * @return The evolution count.
     */
    function getEvolutionCount(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: Evolution count for nonexistent token");
        return _evolutionCounts[tokenId];
    }
}
```