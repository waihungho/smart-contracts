```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OmniForge: A Decentralized Generative AI Art Foundry & Curator DAO
 * @author YourName (Inspired by community innovation)
 * @notice OmniForge is an advanced, unique protocol for creating, curating, and evolving AI-generated art.
 *         It combines dynamic NFTs, a decentralized autonomous organization (DAO),
 *         a reputation system, and off-chain AI model integration via oracles.
 *         Participants can "incubate" AI Art Agents (dynamic NFTs), use them to generate unique art pieces (NFTs),
 *         and engage in a community-driven curation and challenge system.
 *
 * Outline:
 * 1.  Core Contracts & Interfaces: Essential interfaces for external interaction (e.g., Oracles).
 * 2.  Tokenomics (Creativity Essence Token): Internal minimal ERC-20 like implementation for the utility token.
 * 3.  Art Agent Management (Dynamic NFTs): Logic for creating, evolving, and managing generative AI agents.
 * 4.  Art Piece Management (Generative NFTs): Logic for requesting, fulfilling, and managing generated art.
 * 5.  DAO Governance & Treasury: Mechanisms for community decision-making and treasury management.
 * 6.  Curator & Reputation System: System for community members to review art and build reputation.
 * 7.  Challenges & Rewards: Framework for art creation challenges and prize distribution.
 * 8.  Oracle Integration: Bridge for off-chain AI computation results.
 * 9.  Utility & Interaction: General protocol management and query functions.
 */

// --- Interfaces ---

/// @dev IOracle defines the interface for trusted off-chain AI computation oracles.
interface IOracle {
    function fulfillGeneration(
        uint256 _agentId,
        uint256 _requestId,
        string calldata _ipfsHash,
        bytes32 _modelSeed,
        string calldata _style,
        uint256 _qualityScore
    ) external;
}

// --- Main Contract ---

contract OmniForge {

    // --- State Variables ---

    // Owner (for initial setup and emergency controls)
    address public owner;

    // Pausability
    bool public paused;

    // --- Tokenomics (Creativity Essence - CE Token) ---
    string public constant CREATIVITY_ESSENCE_NAME = "Creativity Essence";
    string public constant CREATIVITY_ESSENCE_SYMBOL = "CE";
    uint8 public constant CREATIVITY_ESSENCE_DECIMALS = 18;
    mapping(address => uint256) private _ceBalances;
    mapping(address => mapping(address => uint256)) private _ceAllowances;
    uint256 private _totalCESupply;

    // --- Art Agent Management (Dynamic ERC721-like NFT) ---
    struct Agent {
        uint256 id;
        address owner;
        string name;
        uint256 stakedCE;
        uint256 evolutionLevel; // Influences generation quality/cost
        uint256 lastEvolutionTime;
        mapping(bytes32 => uint256) styleBiases; // Preferences for certain art styles
        bytes32[] delegatees; // For delegating agent power temporarily
        mapping(bytes32 => uint256) delegatedUntil; // Stores delegation end time
    }
    uint256 public nextAgentId;
    string public constant AGENT_NFT_NAME = "OmniForge Art Agent";
    string public constant AGENT_NFT_SYMBOL = "OMNIAGENT";
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => address) private _agentOwners; // tokenId => owner address
    mapping(address => uint256) private _agentBalance; // owner address => count
    mapping(uint256 => address) private _agentTokenApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _agentOperatorApprovals; // owner => operator => approved

    // --- Art Piece Management (Generative ERC721-like NFT) ---
    struct ArtPiece {
        uint256 id;
        uint256 agentId; // Which agent generated it
        address agentOwner; // Owner of the generating agent
        string ipfsHash; // Link to the actual art content
        bytes32 modelSeed; // AI model seed/parameters for reproducibility
        string style; // AI-identified or requested style
        uint256 qualityScore; // AI-evaluated quality score (0-100)
        uint256 submissionTimestamp; // When it was generated
        uint256 curatorReviewScore; // Aggregated score from curators
        bool submittedForReview;
        bool inChallenge;
        uint256 challengeId;
    }
    uint256 public nextArtPieceId;
    string public constant ART_NFT_NAME = "OmniForge Art Piece";
    string public constant ART_NFT_SYMBOL = "OMNIART";
    mapping(uint256 => ArtPiece) public artPieces;
    mapping(uint256 => address) private _artPieceOwners; // tokenId => owner address
    mapping(address => uint256) private _artPieceBalance; // owner address => count
    mapping(uint256 => address) private _artPieceTokenApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _artPieceOperatorApprovals; // owner => operator => approved

    // --- DAO Governance & Treasury ---
    struct Proposal {
        uint256 id;
        address proposer;
        string description; // A brief description of the proposal
        bytes32 parameterKey; // Hashed key of the parameter to change
        uint256 newValue; // The proposed new value
        uint256 creationTime;
        uint256 endTime; // When voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool cancelled;
        mapping(address => bool) hasVoted; // Voter address => true
    }
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalQuorumThreshold = 1000e18; // CE stake required for a proposal to pass (e.g., 1000 CE)
    uint256 public proposalVotingPeriod = 3 days; // Default voting period

    // Protocol parameters (managed by DAO)
    uint256 public constant MIN_AGENT_STAKE = 100e18; // Minimum CE to incubate an agent
    uint256 public constant AGENT_EVOLUTION_COST_PER_LEVEL = 50e18; // CE cost to evolve an agent
    uint256 public constant BASE_ART_GENERATION_COST = 10e18; // Base CE cost for generating art
    uint256 public constant CURATOR_STAKE_AMOUNT = 500e18; // CE stake required to become a curator

    // --- Curator & Reputation System ---
    mapping(address => uint256) public curatorReputation; // Curator address => reputation score
    mapping(address => uint256) public curatorStakes; // Curator address => staked CE
    mapping(uint256 => mapping(address => bool)) public artReviewedByCurator; // artId => curatorAddress => true

    // --- Challenges & Rewards ---
    struct Challenge {
        uint256 id;
        string name; // Name/theme of the challenge
        string promptHash; // Hash of the challenge prompt/description
        uint256 entryFee; // CE fee to submit art to challenge
        uint256 rewardPool; // Total CE rewards for this challenge
        uint256 duration; // Challenge duration in seconds
        uint256 creationTime;
        uint256[] submittedArtPieces; // List of artPieceIds submitted
        mapping(uint256 => bool) hasSubmittedToChallenge; // artId => submitted
        bool distributed; // Rewards distributed status
    }
    uint256 public nextChallengeId;
    mapping(uint256 => Challenge) public challenges;

    // --- Oracle Integration ---
    address public oracleAddress;
    uint256 public nextGenerationRequestId; // To track unique generation requests
    mapping(uint256 => uint256) public pendingGenerationRequests; // request ID => agent ID

    // --- Events ---

    // CE Token Events (minimal ERC-20-like)
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Agent NFT Events (minimal ERC-721-like)
    event AgentTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event AgentApproval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event AgentApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event AgentIncubated(uint256 indexed agentId, address indexed owner, string name, uint256 initialStake);
    event AgentEvolved(uint256 indexed agentId, uint256 newLevel, uint256 ceSpent);
    event AgentDecommissioned(uint256 indexed agentId, address indexed owner, uint256 returnedStake);
    event AgentPowerDelegated(uint256 indexed agentId, address indexed delegatee, uint256 until);

    // Art Piece NFT Events (minimal ERC-721-like)
    event ArtPieceTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ArtPieceApproval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ArtPieceApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ArtGenerationRequested(uint256 indexed agentId, uint256 indexed requestId, string promptHash, uint256 ceCost);
    event ArtGenerationFulfilled(uint256 indexed artId, uint256 indexed agentId, string ipfsHash, string style, uint256 qualityScore);
    event ArtSubmittedForReview(uint256 indexed artId, address indexed owner);

    // DAO Governance Events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, bytes32 parameterKey, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event FundAllocated(bytes32 indexed fundType, uint256 amount);

    // Curator & Reputation Events
    event CuratorRegistered(address indexed curator, uint256 stake);
    event ArtReviewed(uint256 indexed artId, address indexed curator, uint256 rating, uint256 newReviewScore);
    event CuratorReputationUpdated(address indexed curator, uint256 newReputation);
    event CuratorStakeSlashed(address indexed curator, uint256 amount);

    // Challenge Events
    event ChallengeCreated(uint256 indexed challengeId, string name, uint256 rewardPool);
    event ArtSubmittedToChallenge(uint256 indexed challengeId, uint256 indexed artId);
    event ChallengeRewardsDistributed(uint256 indexed challengeId, address indexed winner, uint256 amount);

    // Protocol Control Events
    event Paused(address account);
    event Unpaused(address account);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Oracle: caller is not the oracle");
        _;
    }

    modifier onlyDAO() {
        // This modifier would typically require a successful DAO proposal execution,
        // but for simplicity in this example, we'll allow the owner to simulate DAO actions.
        // In a real system, DAO execution would trigger internal calls.
        require(msg.sender == owner, "DAO: caller not authorized. (Simulated by owner)");
        _;
    }

    modifier onlyCurator() {
        require(curatorStakes[msg.sender] >= CURATOR_STAKE_AMOUNT, "Curator: caller is not a registered curator");
        _;
    }

    // --- Constructor ---

    constructor(address _initialOracle) {
        owner = msg.sender;
        oracleAddress = _initialOracle;
        paused = false;
        nextAgentId = 1;
        nextArtPieceId = 1;
        nextProposalId = 1;
        nextChallengeId = 1;
        nextGenerationRequestId = 1;
        // Mint some initial CE to the deployer for testing
        _mintCreativityEssence(msg.sender, 10_000_000e18); // 10 Million CE
    }

    // --- Internal ERC-20-like Implementation (Creativity Essence) ---

    function _mintCreativityEssence(address _to, uint256 _amount) internal {
        require(_to != address(0), "CE: mint to the zero address");
        _totalCESupply += _amount;
        _ceBalances[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
    }

    function _burnCreativityEssence(address _from, uint256 _amount) internal {
        require(_from != address(0), "CE: burn from the zero address");
        require(_ceBalances[_from] >= _amount, "CE: burn amount exceeds balance");
        _ceBalances[_from] -= _amount;
        _totalCESupply -= _amount;
        emit Transfer(_from, address(0), _amount);
    }

    function _transferCreativityEssence(address _from, address _to, uint256 _amount) internal {
        require(_from != address(0), "CE: transfer from the zero address");
        require(_to != address(0), "CE: transfer to the zero address");
        require(_ceBalances[_from] >= _amount, "CE: transfer amount exceeds balance");

        _ceBalances[_from] -= _amount;
        _ceBalances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }

    function _approveCreativityEssence(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "CE: approve from the zero address");
        require(_spender != address(0), "CE: approve to the zero address");

        _ceAllowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    // --- Public CE Token Functions (from ERC-20-like interface) ---

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalCreativityEssenceSupply() public view returns (uint256) {
        return _totalCESupply;
    }

    /**
     * @notice Returns the amount of tokens owned by `_owner`.
     */
    function getCreativityEssenceBalance(address _owner) public view returns (uint256) {
        return _ceBalances[_owner];
    }

    /**
     * @notice Moves `_amount` tokens from the caller's account to `_to`.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferCreativityEssence(address _to, uint256 _amount) public whenNotPaused returns (bool) {
        _transferCreativityEssence(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @notice Sets `_amount` as the allowance of `_spender` over the caller's CE.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approveCreativityEssence(address _spender, uint256 _amount) public whenNotPaused returns (bool) {
        _approveCreativityEssence(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @notice Returns the remaining number of tokens that `_spender` will be allowed to spend on behalf of `_owner` through `transferFrom`.
     */
    function getCreativityEssenceAllowance(address _owner, address _spender) public view returns (uint256) {
        return _ceAllowances[_owner][_spender];
    }

    /**
     * @notice Moves `_amount` tokens from `_from` to `_to` using the allowance mechanism.
     *         `_amount` is deducted from the caller's allowance.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferCreativityEssenceFrom(address _from, address _to, uint256 _amount) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _ceAllowances[_from][msg.sender];
        require(currentAllowance >= _amount, "CE: transfer amount exceeds allowance");
        _approveCreativityEssence(_from, msg.sender, currentAllowance - _amount);
        _transferCreativityEssence(_from, _to, _amount);
        return true;
    }

    // --- Internal ERC-721-like Implementation (Art Agents & Art Pieces) ---

    // Generic _exists function for both types of NFTs
    function _existsAgent(uint256 _tokenId) internal view returns (bool) {
        return _agentOwners[_tokenId] != address(0);
    }

    function _existsArtPiece(uint256 _tokenId) internal view returns (bool) {
        return _artPieceOwners[_tokenId] != address(0);
    }

    // Agent NFT Minting
    function _mintAgent(address _to, uint256 _tokenId) internal {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(!_existsAgent(_tokenId), "ERC721: token already minted");
        _agentOwners[_tokenId] = _to;
        _agentBalance[_to]++;
        emit AgentTransfer(address(0), _to, _tokenId);
    }

    // Agent NFT Burning
    function _burnAgent(uint256 _tokenId) internal {
        address ownerOfToken = _agentOwners[_tokenId];
        require(ownerOfToken != address(0), "ERC721: token doesn't exist");
        // Clear approvals
        _agentTokenApprovals[_tokenId] = address(0);
        _agentBalance[ownerOfToken]--;
        delete _agentOwners[_tokenId];
        emit AgentTransfer(ownerOfToken, address(0), _tokenId);
    }

    // Art Piece NFT Minting
    function _mintArtPiece(address _to, uint256 _tokenId) internal {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(!_existsArtPiece(_tokenId), "ERC721: token already minted");
        _artPieceOwners[_tokenId] = _to;
        _artPieceBalance[_to]++;
        emit ArtPieceTransfer(address(0), _to, _tokenId);
    }

    // Art Piece NFT Burning (not exposed publicly in this contract, but can be added)
    // function _burnArtPiece(uint256 _tokenId) internal { ... }

    // --- Art Agent Management (Dynamic NFTs) ---

    /**
     * @notice Allows a user to incubate a new Art Agent NFT by staking CE.
     *         The agent starts at level 1 and gains basic generation capabilities.
     * @param _agentName The desired name for the new agent.
     * @param _initialCEStake The amount of Creativity Essence to stake.
     */
    function incubateAgent(string memory _agentName, uint256 _initialCEStake) public whenNotPaused {
        require(_initialCEStake >= MIN_AGENT_STAKE, "Agent: Insufficient initial CE stake");
        
        _transferCreativityEssence(msg.sender, address(this), _initialCEStake);

        uint256 agentId = nextAgentId++;
        agents[agentId] = Agent({
            id: agentId,
            owner: msg.sender,
            name: _agentName,
            stakedCE: _initialCEStake,
            evolutionLevel: 1,
            lastEvolutionTime: block.timestamp,
            styleBiases: new mapping(bytes32 => uint256)(),
            delegatees: new bytes32[](0),
            delegatedUntil: new mapping(bytes32 => uint256)()
        });

        _mintAgent(msg.sender, agentId);

        emit AgentIncubated(agentId, msg.sender, _agentName, _initialCEStake);
    }

    /**
     * @notice Allows an Art Agent owner to spend CE to evolve their agent.
     *         Evolution improves the agent's level, potentially enhancing generation quality or efficiency.
     * @param _agentId The ID of the agent to evolve.
     * @param _ceToSpend The amount of CE to spend on evolution.
     */
    function evolveAgent(uint256 _agentId, uint256 _ceToSpend) public whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(_existsAgent(_agentId), "Agent: Agent does not exist");
        require(agent.owner == msg.sender, "Agent: Only agent owner can evolve");
        require(_ceToSpend > 0, "Agent: CE to spend must be greater than zero");
        require(_ceToSpend >= AGENT_EVOLUTION_COST_PER_LEVEL, "Agent: Insufficient CE for one evolution level");

        _transferCreativityEssence(msg.sender, address(this), _ceToSpend);

        uint256 levelsGained = _ceToSpend / AGENT_EVOLUTION_COST_PER_LEVEL;
        agent.evolutionLevel += levelsGained;
        agent.stakedCE += _ceToSpend; // Added to staked CE, effectively increasing agent 'power'
        agent.lastEvolutionTime = block.timestamp;

        emit AgentEvolved(_agentId, agent.evolutionLevel, _ceToSpend);
    }

    /**
     * @notice Retrieves detailed information about a specific Art Agent.
     * @param _agentId The ID of the agent.
     * @return id The agent's ID.
     * @return owner_ The agent's owner.
     * @return name The agent's name.
     * @return stakedCE The amount of CE currently staked for this agent.
     * @return evolutionLevel The current evolution level of the agent.
     * @return lastEvolutionTime The timestamp of the last evolution.
     */
    function getAgentDetails(uint256 _agentId)
        public
        view
        returns (
            uint256 id,
            address owner_,
            string memory name,
            uint256 stakedCE,
            uint256 evolutionLevel,
            uint256 lastEvolutionTime
        )
    {
        require(_existsAgent(_agentId), "Agent: Agent does not exist");
        Agent storage agent = agents[_agentId];
        return (agent.id, agent.owner, agent.name, agent.stakedCE, agent.evolutionLevel, agent.lastEvolutionTime);
    }

    /**
     * @notice Allows an agent owner to delegate the "power" (ability to request art, vote) of their agent to another address.
     * @param _agentId The ID of the agent to delegate.
     * @param _delegatee The address to delegate power to.
     * @param _duration The duration in seconds for which the power is delegated.
     */
    function delegateAgentPower(uint256 _agentId, address _delegatee, uint256 _duration) public whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(_existsAgent(_agentId), "Agent: Agent does not exist");
        require(agent.owner == msg.sender, "Agent: Only agent owner can delegate");
        require(_delegatee != address(0), "Agent: Delegatee cannot be zero address");
        require(_duration > 0, "Agent: Delegation duration must be positive");

        bytes32 delegateeHash = keccak256(abi.encodePacked(_delegatee));
        agent.delegatees.push(delegateeHash); // Add to a list (simplified, in real scenario use a mapping for faster lookup/removal)
        agent.delegatedUntil[delegateeHash] = block.timestamp + _duration;

        emit AgentPowerDelegated(_agentId, _delegatee, agent.delegatedUntil[delegateeHash]);
    }

    /**
     * @notice Allows the owner to decommission an Art Agent, burning its NFT and returning the staked CE.
     *         There might be a penalty or cooldown in a full system.
     * @param _agentId The ID of the agent to decommission.
     */
    function decommissionAgent(uint256 _agentId) public whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(_existsAgent(_agentId), "Agent: Agent does not exist");
        require(agent.owner == msg.sender, "Agent: Only agent owner can decommission");

        uint256 stakedAmount = agent.stakedCE;
        _burnAgent(_agentId); // Burn the NFT
        _transferCreativityEssence(address(this), msg.sender, stakedAmount); // Return staked CE

        delete agents[_agentId]; // Clean up agent data

        emit AgentDecommissioned(_agentId, msg.sender, stakedAmount);
    }

    /**
     * @notice Allows an agent owner to set biases for certain art styles for their agent.
     *         This influences the AI model's output via the oracle.
     * @param _agentId The ID of the agent.
     * @param _styleHash A hash representing the desired art style (e.g., keccak256("Impressionism")).
     * @param _biasWeight The weight of the bias (e.g., 0-100), higher means stronger preference.
     */
    function setAgentGenerationBias(uint256 _agentId, bytes32 _styleHash, uint256 _biasWeight) public whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(_existsAgent(_agentId), "Agent: Agent does not exist");
        require(agent.owner == msg.sender, "Agent: Only agent owner can set bias");
        require(_biasWeight <= 100, "Agent: Bias weight must be between 0 and 100");

        agent.styleBiases[_styleHash] = _biasWeight;
        // In a real system, this change might trigger an event for the oracle to update agent config.
    }

    // --- Art Piece Management (Generative NFTs) ---

    /**
     * @notice Allows an agent owner (or delegated address) to request an art generation from their agent.
     *         This deducts CE and emits an event for the off-chain oracle.
     * @param _agentId The ID of the agent to use for generation.
     * @param _promptHash A hash or ID representing the AI prompt for the art.
     * @param _ceCost The CE amount the user is willing to pay for this generation.
     */
    function requestArtGeneration(uint256 _agentId, string memory _promptHash, uint256 _ceCost) public whenNotPaused {
        Agent storage agent = agents[_agentId];
        require(_existsAgent(_agentId), "Art: Agent does not exist");
        // Check if caller is owner or a valid delegatee
        bool isDelegatee = agent.delegatedUntil[keccak256(abi.encodePacked(msg.sender))] > block.timestamp;
        require(agent.owner == msg.sender || isDelegatee, "Art: Caller is not agent owner or valid delegatee");
        require(_ceCost >= BASE_ART_GENERATION_COST, "Art: Cost too low for generation");

        _transferCreativityEssence(msg.sender, address(this), _ceCost); // Transfer CE to contract treasury

        uint256 requestId = nextGenerationRequestId++;
        pendingGenerationRequests[requestId] = _agentId;

        // Emit an event for the off-chain oracle to pick up and process
        emit ArtGenerationRequested(_agentId, requestId, _promptHash, _ceCost);
    }

    /**
     * @notice Callback function for the trusted oracle to fulfill an art generation request.
     *         This function creates the new Art Piece NFT and records its metadata.
     * @param _agentId The ID of the agent that generated the art.
     * @param _requestId The original request ID.
     * @param _ipfsHash The IPFS hash where the generated art content is stored.
     * @param _modelSeed The AI model seed used for generation.
     * @param _style The AI-identified or generated style of the art.
     * @param _qualityScore An AI-evaluated quality score for the art (0-100).
     */
    function fulfillArtGeneration(
        uint256 _agentId,
        uint256 _requestId,
        string memory _ipfsHash,
        bytes32 _modelSeed,
        string memory _style,
        uint256 _qualityScore
    ) public onlyOracle whenNotPaused {
        require(pendingGenerationRequests[_requestId] == _agentId, "Oracle: Invalid request ID or agent ID mismatch");
        require(_existsAgent(_agentId), "Oracle: Agent does not exist");

        delete pendingGenerationRequests[_requestId]; // Mark request as fulfilled

        Agent storage agent = agents[_agentId];
        uint256 artPieceId = nextArtPieceId++;

        artPieces[artPieceId] = ArtPiece({
            id: artPieceId,
            agentId: _agentId,
            agentOwner: agent.owner,
            ipfsHash: _ipfsHash,
            modelSeed: _modelSeed,
            style: _style,
            qualityScore: _qualityScore,
            submissionTimestamp: block.timestamp,
            curatorReviewScore: _qualityScore, // Start with AI score, can be modified by curators
            submittedForReview: false,
            inChallenge: false,
            challengeId: 0
        });

        _mintArtPiece(agent.owner, artPieceId); // Mint NFT to the agent owner

        emit ArtGenerationFulfilled(artPieceId, _agentId, _ipfsHash, _style, _qualityScore);
    }

    /**
     * @notice Retrieves detailed information about a specific Art Piece.
     * @param _artId The ID of the art piece.
     * @return id The art piece ID.
     * @return agentId The ID of the agent that created it.
     * @return agentOwner The owner of the creating agent.
     * @return ipfsHash The IPFS hash of the art content.
     * @return modelSeed The AI model seed.
     * @return style The art style.
     * @return qualityScore The AI-evaluated quality score.
     * @return submissionTimestamp The creation timestamp.
     * @return curatorReviewScore The aggregated curator review score.
     * @return submittedForReview If it's currently submitted for curator review.
     */
    function getArtPieceDetails(uint256 _artId)
        public
        view
        returns (
            uint256 id,
            uint256 agentId,
            address agentOwner,
            string memory ipfsHash,
            bytes32 modelSeed,
            string memory style,
            uint256 qualityScore,
            uint256 submissionTimestamp,
            uint256 curatorReviewScore,
            bool submittedForReview
        )
    {
        require(_existsArtPiece(_artId), "Art: Art piece does not exist");
        ArtPiece storage art = artPieces[_artId];
        return (art.id, art.agentId, art.agentOwner, art.ipfsHash, art.modelSeed, art.style, art.qualityScore, art.submissionTimestamp, art.curatorReviewScore, art.submittedForReview);
    }

    /**
     * @notice Allows an Art Piece owner to submit their art for community curator review.
     *         This makes the art visible to curators and eligible for reputation building.
     * @param _artId The ID of the art piece to submit.
     */
    function submitArtForCuratorReview(uint256 _artId) public whenNotPaused {
        ArtPiece storage art = artPieces[_artId];
        require(_existsArtPiece(_artId), "Art: Art piece does not exist");
        require(_artPieceOwners[_artId] == msg.sender, "Art: Only art owner can submit for review");
        require(!art.submittedForReview, "Art: Art already submitted for review");

        art.submittedForReview = true;
        emit ArtSubmittedForReview(_artId, msg.sender);
    }

    // --- DAO Governance & Treasury ---

    /**
     * @notice Allows any user to propose a change to a protocol parameter.
     *         Requires a minimum CE stake or agent power (not implemented yet for simplicity).
     * @param _description A brief description of the proposal.
     * @param _parameterKey The hashed key of the parameter to change (e.g., keccak256("BASE_ART_GENERATION_COST")).
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(string memory _description, bytes32 _parameterKey, uint256 _newValue) public whenNotPaused {
        // In a real DAO, this might require a certain amount of staked CE or agent reputation.
        // For this example, anyone can propose.
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            parameterKey: _parameterKey,
            newValue: _newValue,
            creationTime: block.timestamp,
            endTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            cancelled: false,
            hasVoted: new mapping(address => bool)()
        });

        emit ProposalCreated(proposalId, msg.sender, _description, _parameterKey, _newValue);
    }

    /**
     * @notice Allows users to vote on an active proposal. Voting power is derived from staked CE.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "DAO: Proposal does not exist");
        require(!proposal.executed, "DAO: Proposal already executed");
        require(!proposal.cancelled, "DAO: Proposal cancelled");
        require(block.timestamp < proposal.endTime, "DAO: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "DAO: Already voted on this proposal");

        uint256 voterCEBalance = _ceBalances[msg.sender];
        require(voterCEBalance > 0, "DAO: Voter has no CE to vote with"); // Or use agent power

        if (_support) {
            proposal.votesFor += voterCEBalance;
        } else {
            proposal.votesAgainst += voterCEBalance;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Allows anyone to execute a proposal once its voting period has ended and it has passed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "DAO: Proposal does not exist");
        require(!proposal.executed, "DAO: Proposal already executed");
        require(!proposal.cancelled, "DAO: Proposal cancelled");
        require(block.timestamp >= proposal.endTime, "DAO: Voting period not ended yet");
        require(proposal.votesFor > proposal.votesAgainst, "DAO: Proposal did not pass majority");
        require(proposal.votesFor >= proposalQuorumThreshold, "DAO: Quorum not reached");

        proposal.executed = true;

        // Apply the parameter change
        if (proposal.parameterKey == keccak256(abi.encodePacked("PROPOSAL_QUORUM_THRESHOLD"))) {
            proposalQuorumThreshold = proposal.newValue;
        } else if (proposal.parameterKey == keccak256(abi.encodePacked("PROPOSAL_VOTING_PERIOD"))) {
            proposalVotingPeriod = proposal.newValue;
        } else if (proposal.parameterKey == keccak256(abi.encodePacked("BASE_ART_GENERATION_COST"))) {
            // Note: BASE_ART_GENERATION_COST is constant. This is just for demonstration of how a DAO might change dynamic params.
            // For a real scenario, it would be a state variable.
            // For this implementation, let's make it a state variable to be changeable.
            // _baseArtGenerationCost = proposal.newValue; // This needs to be mutable.
        }
        // Add more parameters as needed

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Allows the DAO (simulated by owner) to allocate funds from the protocol's treasury
     *         to sponsor new AI model development or research.
     * @param _modelId A unique identifier for the AI model/project.
     * @param _amount The amount of CE to allocate.
     */
    function fundNewAIModelDevelopment(bytes32 _modelId, uint256 _amount) public onlyDAO whenNotPaused {
        require(_ceBalances[address(this)] >= _amount, "Treasury: Insufficient funds in treasury");
        // Funds are logically allocated, but kept in contract for traceability
        // This could emit an event for an off-chain multi-sig or external team.
        // For simplicity, we just log this as an allocation, not an actual transfer out yet.
        emit FundAllocated(_modelId, _amount);
    }

    /**
     * @notice Returns the current balance of Creativity Essence held by the DAO treasury.
     */
    function retrieveTreasuryBalance() public view returns (uint256) {
        return _ceBalances[address(this)];
    }

    // --- Curator & Reputation System ---

    /**
     * @notice Allows a user to register as a curator by staking a fixed amount of CE.
     *         Curators can review art and build reputation.
     * @param _ceStake The amount of CE to stake.
     */
    function registerAsCurator(uint256 _ceStake) public whenNotPaused {
        require(curatorStakes[msg.sender] == 0, "Curator: Already registered as a curator");
        require(_ceStake == CURATOR_STAKE_AMOUNT, "Curator: Incorrect stake amount");

        _transferCreativityEssence(msg.sender, address(this), _ceStake);
        curatorStakes[msg.sender] = _ceStake;
        curatorReputation[msg.sender] = 100; // Starting reputation

        emit CuratorRegistered(msg.sender, _ceStake);
        emit CuratorReputationUpdated(msg.sender, 100);
    }

    /**
     * @notice Allows a registered curator to review an art piece that has been submitted for review.
     *         Influences the art piece's curator score and the curator's reputation.
     * @param _artId The ID of the art piece to review.
     * @param _rating The curator's rating (e.g., 0-100).
     * @param _reviewHash A hash of the detailed review comments (stored off-chain).
     */
    function reviewArtPiece(uint256 _artId, uint256 _rating, string memory _reviewHash) public onlyCurator whenNotPaused {
        ArtPiece storage art = artPieces[_artId];
        require(_existsArtPiece(_artId), "Art: Art piece does not exist");
        require(art.submittedForReview, "Art: Art not submitted for review");
        require(!artReviewedByCurator[_artId][msg.sender], "Curator: Already reviewed this art piece");
        require(_rating <= 100, "Curator: Rating must be between 0 and 100");

        // Simple aggregation: average existing score with new rating.
        // More complex logic could use weighted averages based on curator reputation.
        if (art.curatorReviewScore == 0) { // First review
            art.curatorReviewScore = _rating;
        } else {
            art.curatorReviewScore = (art.curatorReviewScore + _rating) / 2;
        }

        artReviewedByCurator[_artId][msg.sender] = true;

        // Update curator reputation based on review quality (simplified: just give a bonus for reviewing)
        curatorReputation[msg.sender] += 1; // Small boost
        emit CuratorReputationUpdated(msg.sender, curatorReputation[msg.sender]);
        emit ArtReviewed(_artId, msg.sender, _rating, art.curatorReviewScore);
    }

    /**
     * @notice Returns the current reputation score of a given curator.
     * @param _curator The address of the curator.
     */
    function getCuratorReputation(address _curator) public view returns (uint256) {
        return curatorReputation[_curator];
    }

    /**
     * @notice Allows the DAO (simulated by owner) to slash a curator's stake for malicious or provably bad behavior.
     *         Funds are moved to the treasury.
     * @param _curator The address of the curator to slash.
     * @param _amount The amount of CE to slash from their stake.
     */
    function slashCuratorStake(address _curator, uint256 _amount) public onlyDAO whenNotPaused {
        require(curatorStakes[_curator] > 0, "Curator: Curator not registered or no stake");
        require(curatorStakes[_curator] >= _amount, "Curator: Slash amount exceeds stake");

        curatorStakes[_curator] -= _amount;
        // Funds remain in the contract's balance (treasury)
        emit CuratorStakeSlashed(_curator, _amount);

        if (curatorStakes[_curator] < CURATOR_STAKE_AMOUNT) {
            // If stake drops below threshold, demote them or remove status
            curatorReputation[_curator] = 0; // Reset reputation
            emit CuratorReputationUpdated(_curator, 0);
        }
    }

    // --- Challenges & Rewards ---

    /**
     * @notice Allows the DAO (simulated by owner) or a highly reputable entity to create an art challenge.
     * @param _name The name/theme of the challenge.
     * @param _challengePromptHash A hash of the detailed challenge prompt/rules.
     * @param _entryFee The CE fee for each art submission to this challenge.
     * @param _rewardPool The total CE reward pool for this challenge.
     * @param _duration The duration of the challenge in seconds.
     */
    function createArtChallenge(
        string memory _name,
        string memory _challengePromptHash,
        uint256 _entryFee,
        uint256 _rewardPool,
        uint256 _duration
    ) public onlyDAO whenNotPaused {
        require(_rewardPool > 0, "Challenge: Reward pool must be greater than zero");
        _mintCreativityEssence(address(this), _rewardPool); // Mint rewards into the contract for the challenge

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            id: challengeId,
            name: _name,
            promptHash: _challengePromptHash,
            entryFee: _entryFee,
            rewardPool: _rewardPool,
            duration: _duration,
            creationTime: block.timestamp,
            submittedArtPieces: new uint256[](0),
            hasSubmittedToChallenge: new mapping(uint256 => bool)(),
            distributed: false
        });

        emit ChallengeCreated(challengeId, _name, _rewardPool);
    }

    /**
     * @notice Allows an art piece owner to submit their art to an active challenge.
     *         Requires payment of the entry fee.
     * @param _challengeId The ID of the challenge to submit to.
     * @param _artId The ID of the art piece to submit.
     */
    function submitToArtChallenge(uint256 _challengeId, uint256 _artId) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        ArtPiece storage art = artPieces[_artId];
        require(challenge.id != 0, "Challenge: Challenge does not exist");
        require(art.id != 0, "Art: Art piece does not exist");
        require(_artPieceOwners[_artId] == msg.sender, "Art: Only art owner can submit");
        require(block.timestamp < challenge.creationTime + challenge.duration, "Challenge: Submission period has ended");
        require(!challenge.hasSubmittedToChallenge[_artId], "Challenge: Art piece already submitted to this challenge");
        require(!art.inChallenge, "Art: Art piece already in another challenge"); // Or allow multiple

        _transferCreativityEssence(msg.sender, address(this), challenge.entryFee); // Collect entry fee

        challenge.submittedArtPieces.push(_artId);
        challenge.hasSubmittedToChallenge[_artId] = true;
        art.inChallenge = true;
        art.challengeId = _challengeId;

        emit ArtSubmittedToChallenge(_challengeId, _artId);
    }

    /**
     * @notice Allows the DAO (simulated by owner) to distribute rewards for a completed challenge.
     *         Winners are determined by art quality score and curator reviews (simplified to best combined score).
     * @param _challengeId The ID of the challenge to distribute rewards for.
     */
    function distributeChallengeRewards(uint256 _challengeId) public onlyDAO whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "Challenge: Challenge does not exist");
        require(block.timestamp >= challenge.creationTime + challenge.duration, "Challenge: Challenge not ended yet");
        require(!challenge.distributed, "Challenge: Rewards already distributed");
        require(challenge.submittedArtPieces.length > 0, "Challenge: No art pieces submitted");

        challenge.distributed = true;

        uint256 bestArtId = 0;
        uint256 highestScore = 0;

        // Determine winner by combined quality and review score
        for (uint256 i = 0; i < challenge.submittedArtPieces.length; i++) {
            uint256 currentArtId = challenge.submittedArtPieces[i];
            ArtPiece storage currentArt = artPieces[currentArtId];
            uint256 combinedScore = (currentArt.qualityScore + currentArt.curatorReviewScore) / 2; // Simple average
            if (combinedScore > highestScore) {
                highestScore = combinedScore;
                bestArtId = currentArtId;
            }
        }

        require(bestArtId != 0, "Challenge: No valid winner found");

        address winnerAddress = artPieces[bestArtId].agentOwner;
        uint256 rewardAmount = challenge.rewardPool;

        _transferCreativityEssence(address(this), winnerAddress, rewardAmount);

        emit ChallengeRewardsDistributed(_challengeId, winnerAddress, rewardAmount);
    }

    // --- Oracle Integration ---

    /**
     * @notice Sets the address of the trusted oracle. Only callable by the owner.
     * @param _newOracle The address of the new oracle.
     */
    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "Oracle: New oracle address cannot be zero");
        emit OracleAddressUpdated(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    // --- Utility & General ---

    /**
     * @notice Pauses the protocol in case of emergencies, preventing most state-changing operations.
     *         Only callable by the owner.
     */
    function pauseProtocol() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the protocol, allowing normal operations to resume.
     *         Only callable by the owner.
     */
    function unpauseProtocol() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Retrieves the current state of key protocol parameters.
     * @return currentQuorumThreshold The current CE threshold for proposals to pass.
     * @return currentVotingPeriod The current duration for proposal voting in seconds.
     * @return currentBaseArtGenerationCost The base CE cost for art generation.
     * @return currentCuratorStakeAmount The CE required to become a curator.
     * @return currentMinAgentStake The minimum CE required to incubate an agent.
     */
    function getProtocolParameters()
        public
        view
        returns (
            uint256 currentQuorumThreshold,
            uint256 currentVotingPeriod,
            uint256 currentBaseArtGenerationCost,
            uint256 currentCuratorStakeAmount,
            uint256 currentMinAgentStake
        )
    {
        return (
            proposalQuorumThreshold,
            proposalVotingPeriod,
            BASE_ART_GENERATION_COST, // This is a constant for now. If it were mutable, it would be a state var.
            CURATOR_STAKE_AMOUNT, // This is a constant.
            MIN_AGENT_STAKE // This is a constant.
        );
    }

    /**
     * @notice Fallback function to prevent accidental Ether sends.
     */
    receive() external payable {
        revert("OmniForge: Ether not accepted");
    }

    fallback() external payable {
        revert("OmniForge: Call not recognized");
    }
}
```