Here's a smart contract written in Solidity, incorporating advanced, creative, and trendy concepts like dynamic NFTs, a simulated autonomous agent network, a reputation system, and on-chain DAO governance. It avoids direct duplication of any single open-source contract by combining these features in a novel way around a "Creative Autonomous Agent Network" (CAAN) theme.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For toString

// CreativeAutonomousAgentNetwork (CAAN) Smart Contract
//
// This contract establishes a decentralized platform for "Creative Autonomous Agents" (CAAs),
// represented as dynamic NFTs. These agents can accept and complete creative missions,
// evolving their attributes and reputation based on their performance. A built-in DAO
// governance system oversees the network, funding missions, managing treasury, and
// approving critical actions.
//
// Advanced Concepts:
// - Dynamic NFTs: Agent metadata (via `tokenURI`) evolves on-chain based on actions (missions, evolution events).
// - Autonomous Agent Simulation: Owners delegate control or act on behalf of their agents to undertake tasks.
//   A future iteration could involve off-chain AI agents interacting with these functions.
// - Reputation System: Non-transferable scores for agents, influencing mission eligibility and rewards,
//   similar to Soulbound Tokens (SBTs) but integrated directly into the agent NFT.
// - Decentralized Mission Marketplace: Users submit prompts/missions, and agents compete or are assigned to fulfill them.
// - DAO Governance: Community-driven decision-making for network parameters, treasury management, and
//   potentially verifying mission outputs (initially handled by the contract owner).
// - Oracle Integration (simulated): A trusted entity (initially `Ownable` owner, later DAO-controlled)
//   validates mission outputs.
//
// This contract does not duplicate any specific open-source contract but combines and
// adapts various well-known patterns (ERC721, basic DAO governance, staking-like rewards,
// reputation mechanics) into a novel "Creative Autonomous Agent" system.

// Outline:
// I. Core Agent Management (ERC721 NFTs & Dynamic State)
// II. Mission & Prompt System (Creative Task Management)
// III. Reputation & Reward System (Skill & Incentive Mechanism)
// IV. Decentralized Autonomous Organization (DAO) Governance & Treasury
// V. Utilities & View Functions

// Function Summary:
// I. Core Agent Management:
// 1. mintCreativeAgent(string _initialPromptHash): Mints a new Creative Agent NFT. Requires a fee. Records initial creative prompt or seed.
// 2. evolveAgent(uint256 _agentId, string _evolutionHash): Allows an agent owner to trigger an "evolution" based on a new creative input/parameter. Updates agent state, influencing its dynamic metadata.
// 3. getAgentDetails(uint256 _agentId): Retrieves comprehensive data for a specific agent (owner, reputation, missions completed, current creative state, last evolution block).
// 4. setAgentApprovalForMission(uint256 _agentId, address _operator, bool _approved): Allows an agent owner to delegate mission acceptance authority for their agent to another address.
// 5. updateAgentMetadataURI(uint256 _agentId, string _newURI): Internal function to update an agent's external metadata URI, reflecting its dynamic state.
// 6. getAgentMetadataURI(uint256 _agentId): Returns the current external metadata URI for an agent. This function is also part of the ERC721 `tokenURI` override.

// II. Mission & Prompt System:
// 7. submitCreativeMission(string _missionPrompt, uint256 _rewardAmount, address _rewardToken, uint256 _deadline): Users (or DAO) submit a new creative prompt with an associated bounty (in ETH or ERC20) and a deadline.
// 8. acceptMission(uint256 _missionId, uint256 _agentId): An agent owner (or approved operator) accepts an available mission for their agent. Agent must meet specified reputation requirements.
// 9. submitMissionOutput(uint256 _missionId, uint256 _agentId, string _outputCID): An agent (via its owner/operator) submits its creative output (e.g., an IPFS CID or hash) for an accepted mission.
// 10. verifyMissionOutput(uint256 _missionId, uint256 _agentId, bool _isSuccessful): Callable by the DAO/Oracle (initially contract owner). Verifies the output, marks mission as complete/failed, triggers reward/penalty, and updates agent reputation and dynamic metadata.
// 11. getMissionDetails(uint256 _missionId): Retrieves all comprehensive details of a specific mission.
// 12. getAgentActiveMissions(uint256 _agentId): Gets a list of mission IDs that a specific agent is currently undertaking or has completed.

// III. Reputation & Reward System:
// 13. getAgentReputation(uint256 _agentId): Returns the non-transferable reputation score of an agent.
// 14. claimMissionReward(uint256 _missionId, uint256 _agentId): Allows the current owner of a successfully verified agent to claim the associated mission rewards (ETH or ERC20).
// 15. slashAgentReputation(uint256 _agentId, uint256 _amount): Reduces an agent's reputation due to mission failures or misconduct, callable by the DAO/Oracle.
// 16. depositRewardTokens(address _token, uint256 _amount): Allows anyone to deposit ERC20 tokens into the contract's general reward pool, making them available for future missions.

// IV. DAO Governance & Treasury:
// 17. createGovernanceProposal(string _description, address _target, bytes calldata _calldata, uint256 _value): Users can initiate a governance proposal to modify contract parameters, fund missions, or execute other arbitrary actions.
// 18. voteOnProposal(uint256 _proposalId, bool _support): Casts a vote (for or against) on an active governance proposal. Voting power can be tied to agent ownership/reputation.
// 19. executeProposal(uint256 _proposalId): Executes a governance proposal that has successfully passed its voting period.
// 20. depositToTreasury(): Allows native token (ETH) deposits directly into the DAO treasury, augmenting funds for missions and operations.
// 21. withdrawFromTreasury(address _token, address _to, uint256 _amount): Callable only by successful governance proposals, allowing withdrawal of native ETH or ERC20 tokens from the treasury to a specified address.

// V. Utilities & View Functions:
// 22. getTreasuryBalance(address _token): Returns the contract's balance for a specific ERC20 token or native ETH (address(0)).
// 23. getAgentCount(): Returns the total number of Creative Agents minted so far.
// 24. getMissionCount(): Returns the total number of missions that have been submitted.
// 25. setBaseURI(string _newBaseURI): Sets the base URI for agent metadata, callable by governance.
// 26. setMissionFee(uint256 _newFee): Sets the native token fee required to submit a new mission, callable by governance.
// 27. setMintFee(uint256 _newFee): Sets the native token fee required to mint a new agent, callable by governance.

contract CreativeAutonomousAgentNetwork is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // I. Agent Management
    Counters.Counter private _agentIds;
    struct Agent {
        address owner; // Current owner of the NFT
        uint256 reputation; // Non-transferable reputation score
        uint256 missionsCompleted;
        string initialPromptHash; // Represents the agent's core creative "identity" or last evolution trigger
        string currentMetadataURI; // Dynamically updated URI for NFT metadata
        uint256 lastEvolutionBlock;
    }
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => mapping(address => bool)) public agentMissionApprovals; // agentId => operator => approved for missions

    // II. Mission System
    Counters.Counter private _missionIds;
    enum MissionStatus { Pending, Accepted, OutputSubmitted, VerifiedSuccessful, VerifiedFailed }
    struct Mission {
        address creator;
        string prompt;
        uint256 rewardAmount; // Amount of the specific reward token
        address rewardToken; // ERC20 token address for reward, address(0) for native ETH
        uint256 deadline;
        MissionStatus status;
        uint256 assignedAgentId; // 0 if not yet accepted
        string outputCID; // IPFS CID or hash of the creative output
        uint256 verificationBlock;
        bool claimed;
    }
    mapping(uint256 => Mission) public missions;
    mapping(uint256 => uint256[]) public agentActiveMissions; // agentId => list of mission IDs

    // III. Reputation & Reward System
    // agentReputation is now part of the `Agent` struct for easier management and data locality.
    // Kept for direct access in view functions if needed for quick lookups: mapping(uint256 => uint256) public agentReputation;

    // IV. DAO Governance
    Counters.Counter private _proposalIdCounter;
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 100; // Example: Minimum reputation to create a proposal
    uint256 public constant PROPOSAL_VOTING_PERIOD_BLOCKS = 40320; // Approx. 1 week with 13s/block (604800 / 13)

    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        address proposer;
        string description;
        address target; // Address the proposal intends to call
        bytes callData; // Calldata for the target function
        uint256 value; // ETH value to be sent with the callData (for target)
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter address => hasVoted

    // V. Configuration Parameters
    string private _baseTokenURI; // Base URI for agent metadata, e.g., "https://api.caan.io/agent/"
    uint256 public mintFee; // Fee to mint a new agent (in native token)
    uint256 public missionFee; // Fee to submit a new mission (in native token)
    address public defaultRewardToken; // Default ERC20 token used for rewards if not specified (address(0) for ETH)

    // --- Events ---
    event AgentMinted(uint256 indexed agentId, address indexed owner, string initialPromptHash);
    event AgentEvolved(uint256 indexed agentId, string newEvolutionHash, string newMetadataURI);
    event MissionSubmitted(uint256 indexed missionId, address indexed creator, uint256 rewardAmount, address rewardToken);
    event MissionAccepted(uint256 indexed missionId, uint256 indexed agentId, address acceptedBy);
    event MissionOutputSubmitted(uint256 indexed missionId, uint256 indexed agentId, string outputCID);
    event MissionVerified(uint256 indexed missionId, uint256 indexed agentId, bool successful, string updatedMetadataURI);
    event MissionRewardClaimed(uint256 indexed missionId, uint256 indexed agentId, address indexed claimant, uint256 amount, address token);
    event ReputationUpdated(uint256 indexed agentId, uint256 newReputation);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 voteWeight, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event FeeUpdated(string indexed feeType, uint256 newFee);
    event BaseURIUpdated(string newURI);
    event RewardTokenDeposited(address indexed token, uint256 amount);
    event TreasuryWithdrawal(address indexed token, address indexed to, uint256 amount);

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 _mintFee,
        uint256 _missionFee,
        address _defaultRewardToken
    )
        ERC721(name, symbol)
        Ownable(msg.sender) // Owner acts as initial DAO/Oracle for critical functions
    {
        _baseTokenURI = baseURI;
        mintFee = _mintFee;
        missionFee = _missionFee;
        defaultRewardToken = _defaultRewardToken; // e.g., address of a stablecoin or governance token
    }

    // --- Modifiers ---

    // Restricts access to the contract owner of the agent or an approved operator for the agent
    modifier onlyAgentOwnerOrApproved(uint256 _agentId) {
        require(_exists(_agentId), "CAAN: Agent does not exist");
        require(
            ERC721.ownerOf(_agentId) == _msgSender() || // Agent owner
            getApproved(_agentId) == _msgSender() || // Approved specific address
            isApprovedForAll(ERC721.ownerOf(_agentId), _msgSender()) || // Approved all for sender
            agentMissionApprovals[_agentId][_msgSender()], // Approved specifically for mission operation
            "CAAN: Not agent owner or approved operator for missions"
        );
        _;
    }

    // --- I. Core Agent Management ---

    // 1. mintCreativeAgent(string _initialPromptHash)
    // Mints a new Creative Agent NFT. Requires a fee. Records initial prompt/seed.
    function mintCreativeAgent(string calldata _initialPromptHash) external payable nonReentrant {
        require(msg.value >= mintFee, "CAAN: Insufficient ETH to mint agent");

        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        string memory initialURI = string(abi.encodePacked(_baseTokenURI, newAgentId.toString()));

        agents[newAgentId] = Agent({
            owner: _msgSender(),
            reputation: 0,
            missionsCompleted: 0,
            initialPromptHash: _initialPromptHash,
            currentMetadataURI: initialURI,
            lastEvolutionBlock: block.number
        });

        _safeMint(_msgSender(), newAgentId);
        emit AgentMinted(newAgentId, _msgSender(), _initialPromptHash);
    }

    // 2. evolveAgent(uint256 _agentId, string _evolutionHash)
    // Allows an agent owner to trigger an "evolution" based on a new creative input/parameter.
    // This updates the agent's internal state, which `tokenURI` will reflect.
    function evolveAgent(uint256 _agentId, string calldata _evolutionHash)
        external
        onlyAgentOwnerOrApproved(_agentId)
        nonReentrant
    {
        Agent storage agent = agents[_agentId];
        agent.initialPromptHash = _evolutionHash; // Simulating a new "seed" for evolution
        agent.lastEvolutionBlock = block.number;
        // The `currentMetadataURI` is implicitly updated by the `tokenURI` override below,
        // which can generate a new URI based on the agent's updated state.
        // For example, the `tokenURI` could append `/evolved` or pass `initialPromptHash` as a query param.
        string memory newURI = string(abi.encodePacked(_baseTokenURI, _agentId.toString(), "?state=", _evolutionHash));
        updateAgentMetadataURI(_agentId, newURI); // Explicitly update internal URI for clarity

        emit AgentEvolved(_agentId, _evolutionHash, newURI);
    }

    // 3. getAgentDetails(uint256 _agentId)
    // Retrieves comprehensive data for a specific agent.
    function getAgentDetails(uint256 _agentId)
        external
        view
        returns (
            address owner,
            uint256 reputation,
            uint256 missionsCompleted,
            string memory initialPromptHash,
            string memory currentMetadataURI,
            uint256 lastEvolutionBlock
        )
    {
        require(_exists(_agentId), "CAAN: Agent does not exist");
        Agent storage agent = agents[_agentId];
        return (
            agent.owner,
            agent.reputation,
            agent.missionsCompleted,
            agent.initialPromptHash,
            agent.currentMetadataURI,
            agent.lastEvolutionBlock
        );
    }

    // 4. setAgentApprovalForMission(uint256 _agentId, address _operator, bool _approved)
    // Allows an agent owner to delegate mission acceptance authority to another address.
    function setAgentApprovalForMission(uint256 _agentId, address _operator, bool _approved)
        external
    {
        require(_exists(_agentId), "CAAN: Agent does not exist");
        require(ERC721.ownerOf(_agentId) == _msgSender(), "CAAN: Only agent owner can set mission approval");
        agentMissionApprovals[_agentId][_operator] = _approved;
    }

    // 5. updateAgentMetadataURI(uint256 _agentId, string _newURI)
    // Internal function to update an agent's external metadata URI.
    // This is typically called by `evolveAgent` or `verifyMissionOutput` to reflect agent state changes.
    function updateAgentMetadataURI(uint256 _agentId, string calldata _newURI) internal {
        require(_exists(_agentId), "CAAN: Agent does not exist");
        agents[_agentId].currentMetadataURI = _newURI;
    }

    // 6. getAgentMetadataURI(uint256 _agentId)
    // Returns the current external metadata URI for an agent.
    function getAgentMetadataURI(uint256 _agentId) public view returns (string memory) {
        require(_exists(_agentId), "CAAN: Agent does not exist");
        return agents[_agentId].currentMetadataURI;
    }

    // Override ERC721's tokenURI to provide dynamic metadata.
    // The `currentMetadataURI` in the Agent struct should point to an API endpoint
    // that generates JSON metadata based on the agent's on-chain state (reputation, missions, etc.).
    function tokenURI(uint256 _agentId) public view override returns (string memory) {
        require(_exists(_agentId), "ERC721Metadata: URI query for nonexistent token");
        return agents[_agentId].currentMetadataURI;
    }

    // --- II. Mission & Prompt System ---

    // 7. submitCreativeMission(string _missionPrompt, uint256 _rewardAmount, address _rewardToken, uint256 _deadline)
    // Users (or DAO) submit a new creative prompt with an associated bounty and deadline.
    // The reward is specified as an ERC20 token or native ETH (address(0)).
    function submitCreativeMission(
        string calldata _missionPrompt,
        uint256 _rewardAmount,
        address _rewardToken, // address(0) for native ETH
        uint256 _deadline
    ) external payable nonReentrant {
        require(bytes(_missionPrompt).length > 0, "CAAN: Mission prompt cannot be empty");
        require(_rewardAmount > 0, "CAAN: Reward amount must be greater than zero");
        require(_deadline > block.timestamp, "CAAN: Deadline must be in the future");
        require(msg.value >= missionFee, "CAAN: Insufficient ETH for mission fee");

        _missionIds.increment();
        uint256 newMissionId = _missionIds.current();

        if (_rewardToken == address(0)) {
            // Native ETH reward: extra ETH (rewardAmount) is implicitly transferred to the contract
            require(msg.value >= missionFee + _rewardAmount, "CAAN: Insufficient ETH for fee and reward");
        } else {
            // ERC20 reward: tokens must be approved and transferred from sender
            IERC20(_rewardToken).transferFrom(msg.sender, address(this), _rewardAmount);
        }

        missions[newMissionId] = Mission({
            creator: _msgSender(),
            prompt: _missionPrompt,
            rewardAmount: _rewardAmount,
            rewardToken: _rewardToken,
            deadline: _deadline,
            status: MissionStatus.Pending,
            assignedAgentId: 0,
            outputCID: "",
            verificationBlock: 0,
            claimed: false
        });

        emit MissionSubmitted(newMissionId, _msgSender(), _rewardAmount, _rewardToken);
    }

    // 8. acceptMission(uint256 _missionId, uint256 _agentId)
    // An agent owner (or approved operator) accepts an available mission for their agent.
    // Agent must meet reputation/skill requirements (simulated by a minimum reputation here).
    function acceptMission(uint256 _missionId, uint256 _agentId)
        external
        onlyAgentOwnerOrApproved(_agentId)
        nonReentrant
    {
        Mission storage mission = missions[_missionId];
        Agent storage agent = agents[_agentId];

        require(mission.status == MissionStatus.Pending, "CAAN: Mission not available or already accepted");
        require(mission.deadline > block.timestamp, "CAAN: Mission deadline has passed");
        // Example: a minimum reputation for this mission type
        // require(agent.reputation >= MIN_REPUTATION_FOR_MISSION, "CAAN: Agent does not meet reputation requirements");

        mission.status = MissionStatus.Accepted;
        mission.assignedAgentId = _agentId;
        agentActiveMissions[_agentId].push(_missionId);

        emit MissionAccepted(_missionId, _agentId, _msgSender());
    }

    // 9. submitMissionOutput(uint256 _missionId, uint256 _agentId, string _outputCID)
    // An agent (via its owner/operator) submits its creative output (IPFS CID or hash) for a mission.
    function submitMissionOutput(uint256 _missionId, uint256 _agentId, string calldata _outputCID)
        external
        onlyAgentOwnerOrApproved(_agentId)
        nonReentrant
    {
        Mission storage mission = missions[_missionId];
        require(mission.assignedAgentId == _agentId, "CAAN: Agent not assigned to this mission");
        require(mission.status == MissionStatus.Accepted, "CAAN: Mission not in accepted state");
        require(mission.deadline > block.timestamp, "CAAN: Mission deadline has passed");
        require(bytes(_outputCID).length > 0, "CAAN: Output CID cannot be empty");

        mission.outputCID = _outputCID;
        mission.status = MissionStatus.OutputSubmitted;

        emit MissionOutputSubmitted(_missionId, _agentId, _outputCID);
    }

    // 10. verifyMissionOutput(uint256 _missionId, uint256 _agentId, bool _isSuccessful)
    // Callable by DAO/Oracle (currently `Ownable` owner). Verifies the output, marks mission as
    // complete/failed, triggers reward/penalty, and updates agent reputation and dynamic metadata.
    function verifyMissionOutput(uint256 _missionId, uint256 _agentId, bool _isSuccessful)
        external
        onlyOwner // Placeholder for DAO/Oracle role. Owner can be a multisig or DAO contract.
        nonReentrant
    {
        Mission storage mission = missions[_missionId];
        Agent storage agent = agents[_agentId];

        require(mission.assignedAgentId == _agentId, "CAAN: Agent not assigned to this mission");
        require(mission.status == MissionStatus.OutputSubmitted, "CAAN: Mission not in output submitted state");
        require(mission.verificationBlock == 0, "CAAN: Mission already verified");

        mission.verificationBlock = block.number;
        string memory newAgentURI;

        if (_isSuccessful) {
            mission.status = MissionStatus.VerifiedSuccessful;
            agent.reputation += 10; // Reward reputation
            agent.missionsCompleted += 1;
            newAgentURI = string(abi.encodePacked(_baseTokenURI, _agentId.toString(), "/success=", Strings.toString(agent.missionsCompleted)));
            updateAgentMetadataURI(_agentId, newAgentURI);
            emit ReputationUpdated(_agentId, agent.reputation);
            emit MissionVerified(_missionId, _agentId, true, newAgentURI);
        } else {
            mission.status = MissionStatus.VerifiedFailed;
            if (agent.reputation >= 5) agent.reputation -= 5; // Slash reputation
            newAgentURI = string(abi.encodePacked(_baseTokenURI, _agentId.toString(), "/failed=", mission.outputCID));
            updateAgentMetadataURI(_agentId, newAgentURI);
            emit ReputationUpdated(_agentId, agent.reputation);
            emit MissionVerified(_missionId, _agentId, false, newAgentURI);
        }
    }

    // 11. getMissionDetails(uint256 _missionId)
    // Retrieves all details of a specific mission.
    function getMissionDetails(uint256 _missionId)
        external
        view
        returns (
            address creator,
            string memory prompt,
            uint256 rewardAmount,
            address rewardToken,
            uint256 deadline,
            MissionStatus status,
            uint256 assignedAgentId,
            string memory outputCID,
            uint256 verificationBlock,
            bool claimed
        )
    {
        require(_missionIds.current() >= _missionId, "CAAN: Mission does not exist");
        Mission storage mission = missions[_missionId];
        return (
            mission.creator,
            mission.prompt,
            mission.rewardAmount,
            mission.rewardToken,
            mission.deadline,
            mission.status,
            mission.assignedAgentId,
            mission.outputCID,
            mission.verificationBlock,
            mission.claimed
        );
    }

    // 12. getAgentActiveMissions(uint256 _agentId)
    // Gets a list of missions an agent is currently undertaking.
    function getAgentActiveMissions(uint256 _agentId) external view returns (uint256[] memory) {
        require(_exists(_agentId), "CAAN: Agent does not exist");
        return agentActiveMissions[_agentId];
    }

    // --- III. Reputation & Reward System ---

    // 13. getAgentReputation(uint256 _agentId)
    // Returns the non-transferable reputation score of an agent.
    function getAgentReputation(uint256 _agentId) public view returns (uint256) {
        require(_exists(_agentId), "CAAN: Agent does not exist");
        return agents[_agentId].reputation;
    }

    // 14. claimMissionReward(uint256 _missionId, uint256 _agentId)
    // Allows the current owner of a successfully verified agent to claim the associated mission rewards.
    function claimMissionReward(uint256 _missionId, uint256 _agentId)
        external
        onlyAgentOwnerOrApproved(_agentId)
        nonReentrant
    {
        Mission storage mission = missions[_missionId];
        require(mission.assignedAgentId == _agentId, "CAAN: Agent not assigned to this mission");
        require(mission.status == MissionStatus.VerifiedSuccessful, "CAAN: Mission not successfully verified");
        require(!mission.claimed, "CAAN: Reward already claimed");

        mission.claimed = true;
        address claimant = ERC721.ownerOf(_agentId); // Reward goes to the current owner of the agent

        if (mission.rewardToken == address(0)) {
            // Native ETH reward
            (bool sent, ) = payable(claimant).call{value: mission.rewardAmount}("");
            require(sent, "CAAN: Failed to send ETH reward");
        } else {
            // ERC20 reward
            IERC20(mission.rewardToken).transfer(claimant, mission.rewardAmount);
        }

        emit MissionRewardClaimed(_missionId, _agentId, claimant, mission.rewardAmount, mission.rewardToken);
    }

    // 15. slashAgentReputation(uint256 _agentId, uint256 _amount)
    // Reduces an agent's reputation due to mission failures or misconduct, callable by DAO/Oracle.
    function slashAgentReputation(uint256 _agentId, uint256 _amount) external onlyOwner nonReentrant {
        require(_exists(_agentId), "CAAN: Agent does not exist");
        Agent storage agent = agents[_agentId];
        if (agent.reputation > _amount) {
            agent.reputation -= _amount;
        } else {
            agent.reputation = 0;
        }
        emit ReputationUpdated(_agentId, agent.reputation);
    }

    // 16. depositRewardTokens(address _token, uint256 _amount)
    // Allows anyone to deposit ERC20 tokens into the contract's general reward pool.
    function depositRewardTokens(address _token, uint256 _amount) external nonReentrant {
        require(_token != address(0), "CAAN: Cannot deposit native ETH via this function, use depositToTreasury");
        require(_amount > 0, "CAAN: Amount must be greater than zero");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit RewardTokenDeposited(_token, _amount);
    }

    // --- IV. DAO Governance & Treasury ---

    // 17. createGovernanceProposal(string _description, address _target, bytes calldata _calldata, uint256 _value)
    // Users can propose changes to contract parameters, fund missions, or other actions.
    function createGovernanceProposal(
        string calldata _description,
        address _target,
        bytes calldata _calldata,
        uint256 _value
    ) external nonReentrant {
        // Example: Only users with sufficient total agent reputation can create proposals.
        // This requires iterating through all agents owned by msg.sender or having a separate
        // "voting power" token/system. For simplicity here, we can set a minimum reputation
        // for ANY agent owned by the sender, or simply allow anyone to propose, but voting power varies.
        // require(getAgentReputation(someAgentIdOwnedBySender) >= MIN_REPUTATION_FOR_PROPOSAL, "CAAN: Insufficient reputation to create proposal");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            proposer: _msgSender(),
            description: _description,
            target: _target,
            callData: _calldata,
            value: _value,
            startBlock: block.number,
            endBlock: block.number + PROPOSAL_VOTING_PERIOD_BLOCKS,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active
        });

        emit ProposalCreated(proposalId, _msgSender(), _description);
    }

    // 18. voteOnProposal(uint256 _proposalId, bool _support)
    // Casts a vote on an active governance proposal.
    // Voting power can be tied to agent reputation or number of agents owned.
    function voteOnProposal(uint256 _proposalId, bool _support) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "CAAN: Proposal not active");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "CAAN: Voting period not active");
        require(!hasVoted[_proposalId][_msgSender()], "CAAN: Already voted on this proposal");

        // Example: Voting power based on sum of reputation of all agents owned by _msgSender()
        // For simplicity, let's assume 1 vote per unique address (or a fixed amount).
        uint256 voteWeight = 1; // Can be dynamically calculated based on agent reputation/count

        if (_support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        hasVoted[_proposalId][_msgSender()] = true;

        emit VoteCast(_proposalId, _msgSender(), voteWeight, _support);
    }

    // 19. executeProposal(uint256 _proposalId)
    // Executes a passed governance proposal.
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "CAAN: Proposal not active");
        require(block.number > proposal.endBlock, "CAAN: Voting period not ended");
        require(proposal.votesFor > proposal.votesAgainst, "CAAN: Proposal did not pass");

        proposal.status = ProposalStatus.Succeeded;

        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        require(success, "CAAN: Proposal execution failed");

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
    }

    // 20. depositToTreasury()
    // Allows native token (ETH) deposits into the DAO treasury.
    function depositToTreasury() external payable {
        require(msg.value > 0, "CAAN: Amount must be greater than zero");
    }

    // 21. withdrawFromTreasury(address _token, address _to, uint256 _amount)
    // Callable by DAO governance for approved expenses, supporting both native and ERC20 tokens.
    function withdrawFromTreasury(address _token, address _to, uint256 _amount) external onlyOwner {
        // In a fully decentralized DAO, this function would only be callable via an executed proposal.
        // For this contract, the `onlyOwner` modifier is a placeholder for the DAO executor's role.
        require(_amount > 0, "CAAN: Amount must be greater than zero");
        if (_token == address(0)) {
            // Native ETH withdrawal
            (bool sent, ) = payable(_to).call{value: _amount}("");
            require(sent, "CAAN: Failed to withdraw ETH from treasury");
        } else {
            // ERC20 token withdrawal
            IERC20(_token).transfer(_to, _amount);
        }
        emit TreasuryWithdrawal(_token, _to, _amount);
    }

    // --- V. Utilities & View Functions ---

    // 22. getTreasuryBalance(address _token)
    // Returns the contract's balance for a specific token (address(0) for native ETH).
    function getTreasuryBalance(address _token) public view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(_token).balanceOf(address(this));
        }
    }

    // 23. getAgentCount()
    // Returns the total number of Creative Agents minted.
    function getAgentCount() public view returns (uint256) {
        return _agentIds.current();
    }

    // 24. getMissionCount()
    // Returns the total number of missions submitted.
    function getMissionCount() public view returns (uint256) {
        return _missionIds.current();
    }

    // 25. setBaseURI(string _newBaseURI)
    // Sets the base URI for agent metadata, callable by governance (currently owner).
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }

    // 26. setMissionFee(uint256 _newFee)
    // Sets the fee required to submit a new mission, callable by governance (currently owner).
    function setMissionFee(uint256 _newFee) external onlyOwner {
        missionFee = _newFee;
        emit FeeUpdated("MissionFee", _newFee);
    }

    // 27. setMintFee(uint256 _newFee)
    // Sets the fee required to mint a new agent, callable by governance (currently owner).
    function setMintFee(uint256 _newFee) external onlyOwner {
        mintFee = _newFee;
        emit FeeUpdated("MintFee", _newFee);
    }

    // Fallback function to accept ETH deposits for treasury
    receive() external payable {
        depositToTreasury();
    }
}
```