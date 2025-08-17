Here's a Solidity smart contract named "CognitoNet" that implements an interesting, advanced, and creative concept: a decentralized intelligence network. It combines dynamic NFTs, an on-chain reputation system for off-chain AI models (via oracle-verified challenges), and a simplified prediction staking mechanism.

---

**Contract Name:** `CognitoNet`

**Concept:**
`CognitoNet` is a decentralized intelligence network designed to foster transparency and reliability in the burgeoning field of AI. It allows AI models (referred to as "AI Agents") to be registered on-chain. The core innovation lies in its **reputation system**: AI Agents' performance is evaluated through a **challenge-and-oracle framework**. Users can submit challenges, and authorized oracles verify the AI's responses, updating the agent's on-chain reputation score. This reputation score directly influences the dynamic traits of **AgentNFTs**, unique Non-Fungible Tokens minted for each AI agent. Furthermore, users can engage in **prediction staking**, supporting AI Agents they believe will perform well and earning rewards if their predictions are accurate. This creates a decentralized feedback loop and quality control mechanism for AI.

**Core Features:**
1.  **AI Agent Registry:** A system to register, manage, and retrieve profiles of off-chain AI models.
2.  **Decentralized Reputation System:** On-chain reputation scores for AI Agents, which are dynamically updated based on oracle-validated challenge outcomes. Reputation decays over time, encouraging continuous performance.
3.  **Challenge & Evaluation Framework:** Users can submit "challenges" (input data hashes and expected output hashes) to AI Agents. A network of authorized oracles then verifies the AI's actual output against the expected one, providing unbiased evaluations.
4.  **Prediction Staking:** Users can stake ETH on specific AI Agents, essentially "betting" on their future performance. Successful predictions (when the agent performs well in a challenge) yield rewards from a shared pool.
5.  **Dynamic AgentNFTs:** Each registered AI Agent can have a unique ERC-721 NFT minted for it. The visual and functional traits (metadata) of these NFTs are not static; they evolve in real-time based on the associated AI Agent's current reputation score, reflecting its standing in the network.
6.  **Incentive Mechanisms:** High-performing AI Agents and accurate predictors are rewarded, promoting quality and active participation. Oracles are also compensated for their verification services.

**Outline:**

*   **I. Contract Overview & Dependencies:** Basic information and OpenZeppelin imports.
*   **II. State Variables & Structs:** Defines the data structures for AI Agents, Challenges, Stakes, Oracles, and protocol parameters.
*   **III. Events:** Declarations for all significant actions to allow off-chain monitoring.
*   **IV. Modifiers:** Access control modifiers for owner and oracle roles.
*   **V. Constructor:** Initializes the contract with the deployer as owner and sets up the ERC721 token.
*   **VI. AI Agent Management Functions (5 functions):** Functions for registering, updating, deactivating, and querying AI Agent profiles.
*   **VII. Reputation & Performance Evaluation Functions (4 functions):** Functions for submitting challenges, oracle evaluation, and querying reputation.
*   **VIII. Oracle Management Functions (3 functions):** Functions for the owner to manage the list of authorized oracles.
*   **IX. Staking & Prediction Functions (5 functions):** Functions for users to stake on agents, withdraw stakes, and claim rewards.
*   **X. Dynamic AgentNFT Functions (3 functions):** Functions for minting AgentNFTs and handling their dynamic metadata (`tokenURI`).
*   **XI. Admin & Protocol Settings Functions (6 functions):** Owner-only functions to configure protocol parameters (fees, rewards, reputation thresholds, etc.) and manage the treasury.
*   **XII. Internal Utility Functions (Helpers):** Private helper functions for reputation calculation, token ID generation, and other internal logic.

**Function Summary (26 functions):**

1.  `constructor()`: Initializes the contract, sets the owner, and ERC721 token name/symbol.
2.  `registerAIAgent(string memory _name, string memory _metadataURI)`: Allows anyone to register a new AI agent with a name and external metadata URI.
3.  `updateAIAgentProfile(uint256 _agentId, string memory _newName, string memory _newMetadataURI)`: Allows the owner of an AI agent to update its name and metadata URI.
4.  `deactivateAIAgent(uint256 _agentId)`: Allows the owner of an AI agent to temporarily deactivate it.
5.  `getAIAgentDetails(uint256 _agentId)`: Returns the detailed information about a registered AI agent, including its decayed reputation.
6.  `submitAIAgentChallenge(uint256 _agentId, string memory _inputDataHash, string memory _expectedResponseHash)`: Allows any user to challenge an AI agent's performance by providing input and expected output hashes. Requires a challenge fee.
7.  `submitOracleEvaluation(uint256 _challengeId, bool _isSuccess, string memory _actualResponseHash)`: Allows an authorized oracle to submit an evaluation for a pending challenge. Updates the AI agent's reputation and pays the oracle.
8.  `getChallengeDetails(uint256 _challengeId)`: Returns the details of a specific challenge.
9.  `getAIAgentReputation(uint256 _agentId)`: Returns the current reputation score of an AI agent, applying decay.
10. `addOracle(address _oracleAddress)`: Owner-only function to add a new authorized oracle.
11. `removeOracle(address _oracleAddress)`: Owner-only function to remove an authorized oracle.
12. `isOracle(address _addr)`: Checks if an address is an authorized oracle.
13. `stakeOnAIAgent(uint256 _agentId)`: Allows users to stake ETH on an AI agent, expressing confidence in its overall performance.
14. `withdrawStake(uint256 _agentId)`: Allows users to withdraw their general staked ETH.
15. `claimPredictionRewards(uint256 _challengeId)`: Allows stakers to claim rewards if their staked agent performed successfully in the specified challenge.
16. `getAgentTotalStaked(uint256 _agentId)`: Returns the total amount of ETH generally staked on a particular AI agent.
17. `getPendingPredictionRewards(uint256 _challengeId, address _staker)`: Calculates the potential rewards for a specific staker on a resolved challenge.
18. `mintAgentNFT(uint256 _agentId)`: Allows the owner of an AI agent to mint a unique AgentNFT for their agent, provided it meets a minimum reputation threshold.
19. `tokenURI(uint256 _tokenId)`: Overrides ERC721's tokenURI to provide dynamic JSON metadata for AgentNFTs, with traits (like image and reputation level) evolving based on the associated AI agent's reputation score.
20. `setChallengeFee(uint256 _newFee)`: Owner-only function to set the fee required to submit a challenge.
21. `setOracleReward(uint256 _newReward)`: Owner-only function to set the reward paid to oracles for evaluations.
22. `setMinReputationForMint(int256 _minRep)`: Owner-only function to set the minimum reputation score required to mint an AgentNFT.
23. `setReputationDecayRate(uint256 _decayRate)`: Owner-only function to set the rate at which AI agent reputation decays over time.
24. `depositTreasury()`: Allows anyone to deposit ETH into the protocol's general treasury.
25. `withdrawTreasury(uint256 _amount)`: Owner-only function to withdraw funds from the treasury.
26. `setBaseURI(string memory _newBaseURI)`: Owner-only function to set the base URI for AgentNFT metadata (used when not relying on `data:` URIs).

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For dynamic NFT metadata generation

/**
 * @title CognitoNet
 * @dev A decentralized intelligence network for AI agent reputation and dynamic NFTs.
 *      Users can register AI agents, challenge their performance, and stake on their success.
 *      Agent NFTs dynamically evolve based on the AI's on-chain reputation.
 */
contract CognitoNet is Ownable, ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- II. State Variables & Structs ---

    // @dev AIAgent represents an off-chain AI model registered on CognitoNet.
    struct AIAgent {
        string name;
        address owner;
        string metadataURI; // URI to off-chain details (e.g., API endpoint, detailed description)
        bool isActive; // True if the agent is active and can be challenged/evaluated
        int256 reputation; // On-chain reputation score
        uint256 lastReputationUpdate; // Timestamp of the last reputation change or decay calculation
        uint256 nftTokenId; // 0 if no AgentNFT minted, otherwise the tokenId
        uint256 totalStakedAmount; // Total ETH staked generally on this agent
    }
    mapping(uint256 => AIAgent) public aiAgents; // Maps agentId to AIAgent struct
    Counters.Counter private _agentIds; // Counter for unique AI agent IDs
    mapping(address => uint256[]) public agentOwnerToAgentIds; // Maps owner address to a list of agent IDs they own
    mapping(uint256 => uint256) public nftTokenIdToAgentId; // Maps AgentNFT tokenId to its associated AI agent ID

    // @dev ChallengeStatus defines the lifecycle of a challenge.
    enum ChallengeStatus { Pending, Evaluated, Withdrawn }

    // @dev Challenge represents a single performance test submitted for an AI agent.
    struct Challenge {
        uint256 agentId; // The ID of the AI agent being challenged
        address challenger; // The address who submitted the challenge
        string inputDataHash; // Hash of the input data provided to the AI agent (off-chain)
        string expectedResponseHash; // Hash of the expected correct response from the AI agent (off-chain)
        string actualResponseHash; // Hash of the actual output from the AI agent (set by oracle)
        ChallengeStatus status; // Current status of the challenge
        uint256 challengeTime; // Timestamp when the challenge was submitted
        uint256 evaluationTime; // Timestamp when the challenge was evaluated by an oracle
        bool isSuccess; // True if AI agent's response met expectations (set by oracle)
    }
    mapping(uint256 => Challenge) public challenges; // Maps challengeId to Challenge struct
    Counters.Counter private _challengeIds; // Counter for unique challenge IDs

    // @dev Stake represents a user's general stake on an AI agent's performance.
    // For simplicity, stakes are general per agent, not specific to a challenge.
    mapping(uint256 => mapping(address => uint256)) public agentStakerGeneralStake; // agentId => stakerAddress => amount

    // @dev pendingRewards tracks rewards for a specific challenge that haven't been claimed yet.
    mapping(uint256 => mapping(address => uint256)) public pendingRewards; // challengeId => stakerAddress => rewardAmount

    // @dev authorizedOracles maps an address to a boolean indicating if it's an authorized oracle.
    mapping(address => bool) public authorizedOracles;

    // --- Protocol Parameters ---
    uint256 public challengeFee = 0.01 ether; // Fee (in ETH) required to submit a challenge
    uint252 public oracleReward = 0.005 ether; // Reward (in ETH) paid to oracles for evaluations
    int256 public minReputationForMint = 50; // Minimum reputation an agent needs to mint an NFT
    uint256 public reputationSuccessBoost = 10; // Amount reputation increases on success
    uint256 public reputationFailurePenalty = 20; // Amount reputation decreases on failure
    uint256 public reputationDecayRate = 1; // Amount of reputation lost per decay period
    uint256 public constant REPUTATION_DECAY_PERIOD = 1 days; // Time interval for reputation decay

    // --- Treasury ---
    uint256 public treasuryBalance; // Funds collected from fees and stakes, used for rewards and protocol operations

    // --- III. Events ---
    event AgentRegistered(uint256 indexed agentId, address indexed owner, string name, string metadataURI);
    event AgentProfileUpdated(uint256 indexed agentId, string newName, string newMetadataURI);
    event AgentDeactivated(uint256 indexed agentId);
    event ChallengeSubmitted(uint256 indexed challengeId, uint256 indexed agentId, address indexed challenger, string inputDataHash);
    event EvaluationReceived(uint256 indexed challengeId, uint256 indexed agentId, address indexed oracle, bool isSuccess, string actualResponseHash);
    event ReputationUpdated(uint256 indexed agentId, int256 newReputation);
    event OracleAdded(address indexed oracleAddress);
    event OracleRemoved(address indexed oracleAddress);
    event Staked(uint256 indexed agentId, address indexed staker, uint256 amount);
    event StakeWithdrawn(uint256 indexed agentId, address indexed staker, uint256 amount);
    event RewardsClaimed(uint256 indexed challengeId, address indexed staker, uint256 amount);
    event AgentNFTMinted(uint256 indexed agentId, uint256 indexed tokenId, address indexed minter);
    event ParameterUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event TreasuryDeposited(address indexed depositor, uint256 amount);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    // --- IV. Modifiers ---
    /**
     * @dev Throws if called by any account other than an authorized oracle.
     */
    modifier onlyOracle() {
        require(authorizedOracles[msg.sender], "CognitoNet: Not an authorized oracle");
        _;
    }

    /**
     * @dev Throws if called by any account other than the specified AI agent's owner.
     * @param _agentId The ID of the AI agent to check ownership for.
     */
    modifier onlyAIAgentOwner(uint256 _agentId) {
        require(aiAgents[_agentId].owner == msg.sender, "CognitoNet: Not the agent owner");
        _;
    }

    // --- V. Constructor ---
    /**
     * @dev Initializes the contract, setting the deployer as the owner.
     */
    constructor() ERC721("CognitoNet AgentNFT", "CNFT") Ownable(msg.sender) {}

    // --- VI. AI Agent Management Functions ---

    /**
     * @notice Registers a new AI agent with a name and a URI pointing to its metadata/endpoint.
     *         Anyone can register an AI agent.
     * @param _name The human-readable name of the AI agent.
     * @param _metadataURI URI to off-chain details (e.g., API endpoint, detailed description JSON).
     */
    function registerAIAgent(string memory _name, string memory _metadataURI) public {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();
        aiAgents[newAgentId] = AIAgent({
            name: _name,
            owner: msg.sender,
            metadataURI: _metadataURI,
            isActive: true,
            reputation: 0, // Agents start with neutral reputation
            lastReputationUpdate: block.timestamp,
            nftTokenId: 0, // No NFT minted initially
            totalStakedAmount: 0 // No stake initially
        });
        agentOwnerToAgentIds[msg.sender].push(newAgentId);
        emit AgentRegistered(newAgentId, msg.sender, _name, _metadataURI);
    }

    /**
     * @notice Allows the owner of an AI agent to update its profile details.
     * @param _agentId The ID of the AI agent to update.
     * @param _newName The new name for the AI agent. If empty, name is unchanged.
     * @param _newMetadataURI The new metadata URI for the AI agent. If empty, URI is unchanged.
     */
    function updateAIAgentProfile(uint256 _agentId, string memory _newName, string memory _newMetadataURI) public onlyAIAgentOwner(_agentId) {
        AIAgent storage agent = aiAgents[_agentId];
        if (bytes(_newName).length > 0) {
            agent.name = _newName;
        }
        if (bytes(_newMetadataURI).length > 0) {
            agent.metadataURI = _newMetadataURI;
        }
        emit AgentProfileUpdated(_agentId, agent.name, agent.metadataURI);
    }

    /**
     * @notice Allows the owner of an AI agent to temporarily deactivate it.
     *         Deactivated agents cannot be challenged or have NFTs minted.
     * @param _agentId The ID of the AI agent to deactivate.
     */
    function deactivateAIAgent(uint256 _agentId) public onlyAIAgentOwner(_agentId) {
        aiAgents[_agentId].isActive = false;
        emit AgentDeactivated(_agentId);
    }

    /**
     * @notice Retrieves the detailed information about a registered AI agent.
     * @param _agentId The ID of the AI agent.
     * @return name The name of the agent.
     * @return owner The owner's address.
     * @return metadataURI The metadata URI.
     * @return isActive Whether the agent is active.
     * @return reputation The current reputation score (decayed).
     * @return nftTokenId The NFT token ID associated, or 0 if none.
     * @return totalStaked The total amount of ETH generally staked on this agent.
     */
    function getAIAgentDetails(uint256 _agentId) public view returns (string memory name, address owner, string memory metadataURI, bool isActive, int256 reputation, uint256 nftTokenId, uint256 totalStaked) {
        AIAgent storage agent = aiAgents[_agentId];
        // Apply decay on read for display purposes; persistent update occurs on evaluation.
        int256 currentReputation = _decayReputation(_agentId);
        return (agent.name, agent.owner, agent.metadataURI, agent.isActive, currentReputation, agent.nftTokenId, agent.totalStakedAmount);
    }

    // --- VII. Reputation & Performance Evaluation Functions ---

    /**
     * @notice Allows any user to submit a challenge against an AI agent, paying a fee.
     *         The hashes should refer to off-chain data.
     * @param _agentId The ID of the AI agent being challenged.
     * @param _inputDataHash Hash of the input data given to the AI agent.
     * @param _expectedResponseHash Hash of the expected correct response from the AI agent.
     */
    function submitAIAgentChallenge(uint256 _agentId, string memory _inputDataHash, string memory _expectedResponseHash) public payable {
        require(aiAgents[_agentId].isActive, "CognitoNet: Agent is not active");
        require(msg.value >= challengeFee, "CognitoNet: Insufficient challenge fee");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            agentId: _agentId,
            challenger: msg.sender,
            inputDataHash: _inputDataHash,
            expectedResponseHash: _expectedResponseHash,
            actualResponseHash: "", // To be filled by oracle
            status: ChallengeStatus.Pending,
            challengeTime: block.timestamp,
            evaluationTime: 0,
            isSuccess: false
        });

        treasuryBalance += msg.value; // Challenge fee goes to treasury for rewards/operations
        emit ChallengeSubmitted(newChallengeId, _agentId, msg.sender, _inputDataHash);
    }

    /**
     * @notice Allows an authorized oracle to submit an evaluation for a pending challenge.
     *         This function updates the AI agent's reputation and pays the oracle.
     * @param _challengeId The ID of the challenge being evaluated.
     * @param _isSuccess True if the AI agent's performance was successful, false otherwise.
     * @param _actualResponseHash Hash of the actual response given by the AI agent.
     */
    function submitOracleEvaluation(uint256 _challengeId, bool _isSuccess, string memory _actualResponseHash) public onlyOracle {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.agentId != 0, "CognitoNet: Invalid challenge ID"); // Ensure challenge exists
        require(challenge.status == ChallengeStatus.Pending, "CognitoNet: Challenge not pending");

        challenge.status = ChallengeStatus.Evaluated;
        challenge.evaluationTime = block.timestamp;
        challenge.isSuccess = _isSuccess;
        challenge.actualResponseHash = _actualResponseHash;

        _updateAIAgentReputation(challenge.agentId, _isSuccess);

        // Pay oracle reward from treasury
        uint256 rewardAmount = oracleReward;
        require(treasuryBalance >= rewardAmount, "CognitoNet: Treasury has insufficient funds for oracle reward");
        treasuryBalance -= rewardAmount;
        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        require(success, "CognitoNet: Failed to pay oracle reward");

        emit EvaluationReceived(_challengeId, challenge.agentId, msg.sender, _isSuccess, _actualResponseHash);
    }

    /**
     * @notice Retrieves the details of a specific challenge.
     * @param _challengeId The ID of the challenge.
     */
    function getChallengeDetails(uint256 _challengeId) public view returns (
        uint256 agentId,
        address challenger,
        string memory inputDataHash,
        string memory expectedResponseHash,
        string memory actualResponseHash,
        ChallengeStatus status,
        uint256 challengeTime,
        uint256 evaluationTime,
        bool isSuccess
    ) {
        Challenge storage challenge = challenges[_challengeId];
        return (
            challenge.agentId,
            challenge.challenger,
            challenge.inputDataHash,
            challenge.expectedResponseHash,
            challenge.actualResponseHash,
            challenge.status,
            challenge.challengeTime,
            challenge.evaluationTime,
            challenge.isSuccess
        );
    }

    /**
     * @notice Returns the current reputation score of an AI agent, applying decay.
     * @param _agentId The ID of the AI agent.
     * @return The current reputation score.
     */
    function getAIAgentReputation(uint256 _agentId) public view returns (int256) {
        return _decayReputation(_agentId);
    }

    // --- VIII. Oracle Management Functions ---

    /**
     * @notice Adds an address to the list of authorized oracles. Only owner can call.
     * @param _oracleAddress The address to authorize as an oracle.
     */
    function addOracle(address _oracleAddress) public onlyOwner {
        authorizedOracles[_oracleAddress] = true;
        emit OracleAdded(_oracleAddress);
    }

    /**
     * @notice Removes an address from the list of authorized oracles. Only owner can call.
     * @param _oracleAddress The address to deauthorize.
     */
    function removeOracle(address _oracleAddress) public onlyOwner {
        authorizedOracles[_oracleAddress] = false;
        emit OracleRemoved(_oracleAddress);
    }

    /**
     * @notice Checks if a given address is an authorized oracle.
     * @param _addr The address to check.
     * @return True if the address is an oracle, false otherwise.
     */
    function isOracle(address _addr) public view returns (bool) {
        return authorizedOracles[_addr];
    }

    // --- IX. Staking & Prediction Functions ---

    /**
     * @notice Allows users to stake ETH on an AI agent, expressing general confidence in its performance.
     *         Staked amounts contribute to the agent's total staked pool.
     * @param _agentId The ID of the AI agent to stake on.
     */
    function stakeOnAIAgent(uint256 _agentId) public payable {
        require(aiAgents[_agentId].isActive, "CognitoNet: Agent is not active");
        require(msg.value > 0, "CognitoNet: Stake amount must be greater than zero");

        aiAgents[_agentId].totalStakedAmount += msg.value; // Update total stake on agent
        agentStakerGeneralStake[_agentId][msg.sender] += msg.value; // Record user's general stake
        treasuryBalance += msg.value; // Staked amount goes to treasury as part of the reward pool

        emit Staked(_agentId, msg.sender, msg.value);
    }

    /**
     * @notice Allows a user to withdraw their general stake from an AI agent.
     * @param _agentId The ID of the AI agent from which to withdraw the stake.
     * @dev In a more complex system, a cool-down period or no pending challenges might be required.
     */
    function withdrawStake(uint256 _agentId) public {
        uint256 amountToWithdraw = agentStakerGeneralStake[_agentId][msg.sender];
        require(amountToWithdraw > 0, "CognitoNet: No stake to withdraw");

        agentStakerGeneralStake[_agentId][msg.sender] = 0; // Reset user's stake
        aiAgents[_agentId].totalStakedAmount -= amountToWithdraw; // Reduce total stake on agent

        require(treasuryBalance >= amountToWithdraw, "CognitoNet: Treasury has insufficient funds for withdrawal");
        treasuryBalance -= amountToWithdraw;
        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "CognitoNet: Failed to withdraw stake");

        emit StakeWithdrawn(_agentId, msg.sender, amountToWithdraw);
    }

    /**
     * @notice Allows stakers to claim rewards from a specific challenge if their staked agent performed successfully.
     *         Rewards are proportional to the staker's general stake on the agent when the challenge was evaluated.
     * @param _challengeId The ID of the challenge for which to claim rewards.
     */
    function claimPredictionRewards(uint256 _challengeId) public {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Evaluated, "CognitoNet: Challenge not evaluated");
        require(challenge.isSuccess, "CognitoNet: Agent did not succeed in this challenge");

        uint256 agentId = challenge.agentId;
        uint256 stakerStake = agentStakerGeneralStake[agentId][msg.sender]; // User's stake on this agent
        require(stakerStake > 0, "CognitoNet: No stake found for this agent");
        require(pendingRewards[_challengeId][msg.sender] == 0, "CognitoNet: Rewards already claimed for this challenge");

        uint256 totalStakedForAgent = aiAgents[agentId].totalStakedAmount; // Total general stake on this agent
        require(totalStakedForAgent > 0, "CognitoNet: No total stake for agent, cannot calculate rewards.");

        // Calculate reward: a portion of the initial challengeFee, distributed proportionally.
        // For simplicity: If an agent succeeds, stakers share 50% of the initial challenge fee.
        uint256 rewardPool = challengeFee / 2;
        uint256 rewardAmount = (stakerStake * rewardPool) / totalStakedForAgent;
        
        require(treasuryBalance >= rewardAmount, "CognitoNet: Treasury has insufficient funds for rewards");
        treasuryBalance -= rewardAmount;
        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        require(success, "CognitoNet: Failed to send rewards");

        pendingRewards[_challengeId][msg.sender] = rewardAmount; // Mark as claimed (by setting to amount received)
        emit RewardsClaimed(_challengeId, msg.sender, rewardAmount);
    }

    /**
     * @notice Returns the total amount of ETH generally staked on a particular AI agent.
     * @param _agentId The ID of the AI agent.
     * @return The total amount of ETH staked.
     */
    function getAgentTotalStaked(uint256 _agentId) public view returns (uint256) {
        return aiAgents[_agentId].totalStakedAmount;
    }

    /**
     * @notice Calculates the potential rewards for a specific staker on a *resolved* challenge.
     *         Does not actually send funds. Used for estimation.
     * @param _challengeId The ID of the challenge.
     * @param _staker The address of the staker.
     * @return The calculated pending reward amount.
     */
    function getPendingPredictionRewards(uint256 _challengeId, address _staker) public view returns (uint256) {
        Challenge storage challenge = challenges[_challengeId];
        // Ensure the challenge is evaluated and was successful, and rewards not already claimed
        if (challenge.status != ChallengeStatus.Evaluated || !challenge.isSuccess || pendingRewards[_challengeId][_staker] > 0) {
            return 0;
        }

        uint256 agentId = challenge.agentId;
        uint256 stakerStake = agentStakerGeneralStake[agentId][_staker];
        if (stakerStake == 0) return 0;

        uint256 totalStakedForAgent = aiAgents[agentId].totalStakedAmount;
        if (totalStakedForAgent == 0) return 0;

        uint256 rewardPool = challengeFee / 2; // 50% of the initial challenge fee
        return (stakerStake * rewardPool) / totalStakedForAgent;
    }

    // --- X. Dynamic AgentNFT Functions ---

    /**
     * @notice Mints an AgentNFT for a registered AI agent, provided its owner meets the
     *         minimum reputation threshold and an NFT has not already been minted for it.
     * @param _agentId The ID of the AI agent for which to mint an NFT.
     */
    function mintAgentNFT(uint256 _agentId) public onlyAIAgentOwner(_agentId) {
        AIAgent storage agent = aiAgents[_agentId];
        require(agent.nftTokenId == 0, "CognitoNet: NFT already minted for this agent");
        require(agent.isActive, "CognitoNet: Agent must be active to mint NFT");
        require(_decayReputation(_agentId) >= minReputationForMint, "CognitoNet: Agent reputation too low to mint NFT");

        uint256 tokenId = _nextTokenId(); // Get next available ERC721 token ID
        _safeMint(msg.sender, tokenId); // Mint the NFT to the agent's owner
        
        agent.nftTokenId = tokenId;
        nftTokenIdToAgentId[tokenId] = _agentId; // Map NFT to agent

        emit AgentNFTMinted(_agentId, tokenId, msg.sender);
    }

    /**
     * @notice Overrides ERC721's tokenURI to provide dynamic JSON metadata for AgentNFTs.
     *         The metadata (especially image and "Reputation Level" trait) changes based
     *         on the associated AI agent's live reputation score.
     * @param _tokenId The ID of the NFT.
     * @return A data URI containing the JSON metadata, Base64 encoded.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 agentId = nftTokenIdToAgentId[_tokenId];
        require(agentId != 0, "CognitoNet: NFT not associated with an agent");

        AIAgent storage agent = aiAgents[agentId];
        int256 currentReputation = _decayReputation(agentId); // Get current decayed reputation

        // Determine dynamic traits (reputation level and image URL) based on reputation score
        string memory reputationLevel;
        string memory imageUrl; // Placeholder image URLs, replace with actual IPFS links
        // For demonstration, these are hardcoded. In a real dApp, they might come from a config or IPFS.
        if (currentReputation >= 100) {
            reputationLevel = "Legendary";
            imageUrl = "ipfs://QmYtH7L9cM4jFpZ1xV2B6W3D8X5J0K9I7G2Q1S0R4E3U6F/legendary.png"; 
        } else if (currentReputation >= 50) {
            reputationLevel = "Esteemed";
            imageUrl = "ipfs://QmYtH7L9cM4jFpZ1xV2B6W3D8X5J0K9I7G2Q1S0R4E3U6F/esteemed.png";
        } else if (currentReputation >= 0) {
            reputationLevel = "Established";
            imageUrl = "ipfs://QmYtH7L9cM4jFpZ1xV2B6W3D8X5J0K9I7G2Q1S0R4E3U6F/established.png";
        } else {
            reputationLevel = "Developing";
            imageUrl = "ipfs://QmYtH7L9cM4jFpZ1xV2B6W3D8X5J0K9I7G2Q1S0R4E3U6F/developing.png";
        }

        // Construct the JSON metadata string
        string memory json = string(abi.encodePacked(
            '{"name": "', agent.name, ' AgentNFT #', _tokenId.toString(), '",',
            '"description": "Dynamic NFT for the AI Agent: ', agent.name, '. Reputation score: ', Strings.toString(currentReputation), '",',
            '"image": "', imageUrl, '",',
            '"attributes": [',
                '{"trait_type": "Agent ID", "value": "', agentId.toString(), '"},',
                '{"trait_type": "Reputation Score", "value": ', Strings.toString(currentReputation), '},',
                '{"trait_type": "Reputation Level", "value": "', reputationLevel, '"},',
                '{"trait_type": "Active", "value": ', (agent.isActive ? "true" : "false"), '}',
            ']}'
        ));

        // Encode the JSON string to Base64 and prefix with data URI scheme
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- XI. Admin & Protocol Settings Functions ---

    /**
     * @notice Sets the fee required to submit a challenge. Only owner can call.
     * @param _newFee The new challenge fee in wei.
     */
    function setChallengeFee(uint256 _newFee) public onlyOwner {
        emit ParameterUpdated("challengeFee", challengeFee, _newFee);
        challengeFee = _newFee;
    }

    /**
     * @notice Sets the reward paid to oracles for evaluations. Only owner can call.
     * @param _newReward The new oracle reward in wei.
     */
    function setOracleReward(uint256 _newReward) public onlyOwner {
        emit ParameterUpdated("oracleReward", oracleReward, _newReward);
        oracleReward = _newReward;
    }

    /**
     * @notice Sets the minimum reputation score required for an agent to mint an NFT. Only owner can call.
     * @param _minRep The new minimum reputation.
     */
    function setMinReputationForMint(int256 _minRep) public onlyOwner {
        // No event for int256 in current setup, could add specific event if needed.
        minReputationForMint = _minRep;
    }

    /**
     * @notice Sets the rate at which AI agent reputation decays over time. Only owner can call.
     * @param _decayRate The amount of reputation lost per `REPUTATION_DECAY_PERIOD`.
     */
    function setReputationDecayRate(uint256 _decayRate) public onlyOwner {
        emit ParameterUpdated("reputationDecayRate", reputationDecayRate, _decayRate);
        reputationDecayRate = _decayRate;
    }

    /**
     * @notice Allows anyone to deposit ETH into the protocol's general treasury.
     */
    function depositTreasury() public payable {
        require(msg.value > 0, "CognitoNet: Deposit amount must be greater than zero");
        treasuryBalance += msg.value;
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Allows the owner to withdraw funds from the treasury.
     * @param _amount The amount to withdraw in wei.
     */
    function withdrawTreasury(uint256 _amount) public onlyOwner {
        require(_amount > 0, "CognitoNet: Withdraw amount must be greater than zero");
        require(treasuryBalance >= _amount, "CognitoNet: Insufficient treasury balance");
        
        treasuryBalance -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "CognitoNet: Failed to withdraw from treasury");
        emit TreasuryWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice Sets the base URI for AgentNFT metadata. This can be used if not relying on `data:` URIs.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    // --- XII. Internal Utility Functions ---

    /**
     * @dev Internal function to update an AI agent's reputation based on a challenge outcome.
     *      Applies the success boost or failure penalty.
     * @param _agentId The ID of the AI agent.
     * @param _isSuccess True if the agent succeeded in the challenge, false otherwise.
     */
    function _updateAIAgentReputation(uint256 _agentId, bool _isSuccess) internal {
        AIAgent storage agent = aiAgents[_agentId];
        
        // First, apply any decay that should have occurred since the last *explicit* update
        // This makes sure decay is accounted for before adding/subtracting for the current event.
        agent.reputation = _decayReputation(_agentId); // Update agent.reputation in storage
        
        if (_isSuccess) {
            agent.reputation += int256(reputationSuccessBoost);
        } else {
            agent.reputation -= int256(reputationFailurePenalty);
        }
        agent.lastReputationUpdate = block.timestamp; // Update timestamp after this reputation change
        emit ReputationUpdated(_agentId, agent.reputation);
    }

    /**
     * @dev Internal function to calculate reputation decay based on time elapsed since last update.
     *      This function is `view` as it calculates, but does not persist the decay unless
     *      called from a state-modifying function like `_updateAIAgentReputation`.
     * @param _agentId The ID of the AI agent.
     * @return The calculated (decayed) reputation score.
     */
    function _decayReputation(uint256 _agentId) internal view returns (int256) {
        AIAgent storage agent = aiAgents[_agentId];
        uint256 timePassed = block.timestamp - agent.lastReputationUpdate;
        
        // Calculate how many full decay periods have passed
        uint256 decayPeriods = timePassed / REPUTATION_DECAY_PERIOD;
        
        // Calculate the decayed reputation
        int256 decayedReputation = agent.reputation - int256(decayPeriods * reputationDecayRate);

        return decayedReputation;
    }

    /**
     * @dev Internal function to get the next available NFT token ID from ERC721's internal counter.
     * @return The next token ID.
     */
    function _nextTokenId() internal returns (uint256) {
        Counters.Counter storage _tokenIds = Counters.current(super._tokenIds); // Access _tokenIds from ERC721
        _tokenIds.increment();
        return _tokenIds.current();
    }
}
```