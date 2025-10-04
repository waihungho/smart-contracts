This smart contract, `AetherialForge`, introduces a novel decentralized protocol for the creation, evolution, and curation of unique digital assets, termed "Aetherial Artifacts." These artifacts are NFTs whose properties and metadata can dynamically change based on AI input (via an oracle), community governance, and user interactions. The protocol emphasizes a reputation-gated curation system where a soulbound, on-chain reputation score determines a user's influence, rewards, and ability to shape the protocol's future.

---

## **AetherialForge: Outline & Function Summary**

**Contract Name:** `AetherialForge`

**Core Concept:** `AetherialForge` is a dynamic, AI-assisted, reputation-gated protocol for creating, evolving, and curating unique digital assets (Aetherial Artifacts, NFTs). It blends on-chain governance, reputation mechanics, and oracle-driven AI integration to foster a vibrant, community-driven ecosystem around evolving digital collectibles.

---

### **Key Features Summary:**

*   **AI-Driven Artifact Generation & Evolution:** Users mint new Aetherial Artifacts (ERC-721 NFTs) based on prompts, and their properties can evolve over time, with both initial generation and subsequent evolution influenced by off-chain AI models via a secure oracle.
*   **Reputation-Gated Curation & Governance:** A non-transferable (soulbound) on-chain reputation score dictates a user's influence in the protocol. Higher reputation grants more voting power, greater rewards, and enhanced privileges (e.g., challenging oracle outputs). Reputation is earned through constructive participation like staking and successful curation.
*   **Dynamic NFTs:** Artifact properties, metadata, and even visual representations can change based on governance decisions, AI updates, or external triggers, making them truly living assets.
*   **Community-Owned Treasury:** A native ERC-20 token (`$FORGE`) fuels the ecosystem, used for staking, rewards, and governing a community-controlled treasury.
*   **Oracle Integration:** Securely connects the smart contract to off-chain AI models and data feeds, allowing for verifiable and dispute-resolvable integration of external intelligence.

---

### **Function Summary:**

**I. Protocol Management & Configuration (5 Functions)**

1.  `constructor(address _initialOwner, address _forgeToken, address _artifactNFT, address _oracle, address _aiModel)`: Initializes the contract with an owner, references to the Forge token and Artifact NFT contracts, and oracle/AI model addresses.
2.  `toggleProtocolPause()`: Allows the owner or governance to pause/unpause critical protocol operations in emergencies.
3.  `setForgeOracle(address _oracle)`: Updates the address of the trusted oracle responsible for AI feedback and external data. (Governance-controlled)
4.  `setAIModelContract(address _aiModel)`: Updates the address of the AI model router/aggregator contract. (Governance-controlled)
5.  `withdrawProtocolFees(address _to, uint256 _amount)`: Allows the owner/governance to withdraw collected protocol fees to a specified address.

**II. Aetherial Artifact (NFT) Lifecycle (4 Functions)**

6.  `forgeNewArtifact(string calldata _prompt, string calldata _initialMetadataURI)`: Mints a new Aetherial Artifact NFT, sending a prompt to the AI oracle for initial property generation. Requires a fee in `$FORGE`.
7.  `requestArtifactEvolution(uint256 _tokenId, string calldata _evolutionPrompt)`: Initiates a request for a specific artifact to evolve, based on a new prompt sent to the AI oracle. Requires a fee.
8.  `finalizeArtifactEvolution(uint256 _tokenId, bytes32 _requestId, string calldata _newPropertiesJson, string calldata _newMetadataURI)`: An oracle-only callback to update an artifact's properties and metadata URI after an AI processing request.
9.  `getArtifactDetails(uint256 _tokenId)`: Retrieves all key details of an Aetherial Artifact, including owner, current properties, metadata URI, and evolution status.

**III. Reputation & Curation System (8 Functions)**

10. `getReputationScore(address _user)`: Queries the non-transferable reputation score of a specific user.
11. `stakeForgeForCuration(uint256 _amount)`: Users stake `$FORGE` tokens to gain curation power, accrue reputation, and participate in governance.
12. `unstakeForgeFromCuration(uint256 _amount)`: Allows users to unstake their `$FORGE` after a cooldown period.
13. `submitCurationProposal(uint256 _targetId, uint8 _proposalType, bytes calldata _data)`: Submits various types of proposals (e.g., dispute AI output, suggest artifact attribute change, protocol parameter change).
14. `voteOnProposal(uint256 _proposalId, bool _support)`: Users vote on active proposals using their staked `$FORGE` and reputation-weighted power.
15. `executeProposal(uint256 _proposalId)`: Executes a proposal if it has passed the voting phase and quorum requirements.
16. `claimCurationRewards()`: Allows active curators and voters to claim their accumulated `$FORGE` rewards and reputation points.
17. `challengeOracleResponse(uint256 _artifactId, bytes32 _requestId)`: Enables high-reputation users to formally challenge an oracle's AI output for an artifact, potentially triggering a community review.

**IV. Treasury & Tokenomics Governance (4 Functions)**

18. `getForgeTokenAddress()`: Returns the address of the `$FORGE` ERC-20 token contract.
19. `depositIntoTreasury(uint256 _amount)`: Allows any user or contract to deposit `$FORGE` tokens directly into the protocol's community treasury.
20. `proposeTreasurySpend(address _recipient, uint256 _amount, string calldata _description)`: Initiates a governance proposal to spend a specific amount of `$FORGE` from the treasury to a recipient for a described purpose.
21. `executeTreasurySpend(uint256 _proposalId)`: Executes a passed treasury spend proposal, transferring `$FORGE` from the treasury.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interfaces for external contracts (Oracle, AI Model)
interface IForgeOracle {
    function requestAIGeneration(
        uint256 _artifactId,
        bytes32 _requestId,
        string calldata _prompt
    ) external;

    function requestAIEvolution(
        uint256 _artifactId,
        bytes32 _requestId,
        string calldata _prompt
    ) external;
}

interface IAIModel {
    // This could be a router or a direct AI interface
    // For this example, we assume the Oracle handles direct interaction
    // but the Forge might need to change which 'AI model' the oracle uses.
    function getModelName() external view returns (string memory);
}

// --- CORE CONTRACT ---

contract AetherialForge is Ownable, ReentrancyGuard {
    // --- State Variables ---

    // External Contract References
    IERC20 public immutable FORGE_TOKEN; // The native ERC-20 token of the protocol
    ERC721URIStorage public immutable AETHERIAL_ARTIFACTS; // The ERC-721 NFT contract
    IForgeOracle public forgeOracle; // Oracle for AI interactions and external data
    IAIModel public aiModelContract; // Reference to the AI Model contract (for governance)

    // Protocol State
    bool public paused;
    uint256 public nextArtifactId;
    uint256 public nextProposalId;
    uint256 public totalStakedForge; // Total FORGE staked for curation

    // Fees
    uint256 public forgeArtifactCreationFee = 10 ether; // Fee in FORGE for minting
    uint256 public forgeEvolutionRequestFee = 5 ether; // Fee in FORGE for evolution request
    uint256 public minReputationForChallenge = 1000; // Min reputation to challenge oracle

    // Mappings
    mapping(address => uint256) public reputationScores; // Soulbound reputation score per user
    mapping(address => uint256) public stakedForgeBalance; // Forge tokens staked by user for curation
    mapping(uint256 => uint256) public stakingTimestamp; // Timestamp when user last staked/unstaked for cooldown
    mapping(uint256 => Artifact) public artifacts; // Details of each Aetherial Artifact
    mapping(uint256 => Proposal) public proposals; // Governance proposals

    // --- Structs ---

    struct Artifact {
        address owner;
        string currentPropertiesJson; // JSON string of dynamic properties
        uint256 evolutionCount;
        bytes32 pendingEvolutionRequestId; // Request ID for ongoing evolution
        string currentPrompt; // The prompt used to generate/evolve this artifact
        bool isChallenged; // True if an oracle response for this artifact is under challenge
    }

    enum ProposalType {
        AI_OUTPUT_DISPUTE,
        ARTIFACT_ATTRIBUTE_CHANGE,
        PROTOCOL_PARAMETER_CHANGE,
        TREASURY_SPEND
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        uint256 targetId; // Artifact ID, or a generic ID for protocol/treasury
        bytes data; // Encoded data specific to the proposal type
        address proposer;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // User has voted
        bool executed;
        bool passed;
    }

    // --- Events ---

    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);
    event ForgeOracleSet(address indexed newOracle);
    event AIModelContractSet(address indexed newAIModel);
    event FeesWithdrawn(address indexed to, uint256 amount);

    event ArtifactForged(
        uint256 indexed tokenId,
        address indexed owner,
        string prompt,
        string initialURI
    );
    event ArtifactEvolutionRequested(
        uint256 indexed tokenId,
        address indexed requester,
        string evolutionPrompt,
        bytes32 requestId
    );
    event ArtifactEvolutionFinalized(
        uint256 indexed tokenId,
        string newPropertiesJson,
        string newMetadataURI
    );
    event ArtifactChallenge(
        uint256 indexed tokenId,
        bytes32 indexed requestId,
        address indexed challenger
    );

    event ReputationIncreased(address indexed user, uint256 amount);
    event ReputationDecreased(address indexed user, uint256 amount);
    event ForgeStaked(address indexed user, uint256 amount);
    event ForgeUnstaked(address indexed user, uint256 amount);

    event ProposalSubmitted(
        uint256 indexed proposalId,
        ProposalType indexed pType,
        address indexed proposer
    );
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 voteWeight
    );
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event CurationRewardsClaimed(
        address indexed user,
        uint256 forgeAmount,
        uint256 reputationAmount
    );

    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasurySpendProposed(
        uint256 indexed proposalId,
        address indexed recipient,
        uint256 amount
    );
    event TreasurySpendExecuted(
        uint256 indexed proposalId,
        address indexed recipient,
        uint256 amount
    );

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Protocol is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Protocol is not paused");
        _;
    }

    modifier onlyForgeOracle() {
        require(msg.sender == address(forgeOracle), "Caller is not the Forge Oracle");
        _;
    }

    modifier onlyGovernance() {
        // For a full DAO, this would be `only(GOVERNANCE_CONTRACT_ADDRESS)`
        // For this example, we assume `owner` has governance powers for critical config
        // or proposals handle this.
        require(
            msg.sender == owner() || stakedForgeBalance[msg.sender] > 0, // Placeholder: active stakers might also initiate
            "Caller is not owner or governance entity"
        );
        _;
    }

    // --- Constructor ---

    constructor(
        address _initialOwner,
        address _forgeToken,
        address _artifactNFT,
        address _oracle,
        address _aiModel
    ) Ownable(_initialOwner) {
        require(_forgeToken != address(0), "Invalid FORGE_TOKEN address");
        require(_artifactNFT != address(0), "Invalid AETHERIAL_ARTIFACTS address");
        require(_oracle != address(0), "Invalid ForgeOracle address");
        require(_aiModel != address(0), "Invalid AIModel address");

        FORGE_TOKEN = IERC20(_forgeToken);
        AETHERIAL_ARTIFACTS = ERC721URIStorage(_artifactNFT); // Cast to ERC721URIStorage
        forgeOracle = IForgeOracle(_oracle);
        aiModelContract = IAIModel(_aiModel);
        nextArtifactId = 1; // Artifact IDs start from 1
        nextProposalId = 1; // Proposal IDs start from 1
        paused = false;
    }

    // --- I. Protocol Management & Configuration (5 Functions) ---

    /// @notice Toggles the paused state of the protocol. Only owner can call.
    function toggleProtocolPause() external onlyOwner {
        paused = !paused;
        if (paused) {
            emit ProtocolPaused(_msgSender());
        } else {
            emit ProtocolUnpaused(_msgSender());
        }
    }

    /// @notice Sets the address of the Forge Oracle contract. Callable by governance.
    /// @param _oracle The new address for the Forge Oracle.
    function setForgeOracle(address _oracle) external onlyGovernance whenNotPaused {
        require(_oracle != address(0), "Invalid oracle address");
        forgeOracle = IForgeOracle(_oracle);
        emit ForgeOracleSet(_oracle);
    }

    /// @notice Sets the address of the AI Model contract. Callable by governance.
    /// @param _aiModel The new address for the AI Model contract.
    function setAIModelContract(address _aiModel)
        external
        onlyGovernance
        whenNotPaused
    {
        require(_aiModel != address(0), "Invalid AI model address");
        aiModelContract = IAIModel(_aiModel);
        emit AIModelContractSet(_aiModel);
    }

    /// @notice Allows the owner to withdraw accumulated protocol fees.
    /// @param _to The address to send the fees to.
    /// @param _amount The amount of FORGE tokens to withdraw.
    function withdrawProtocolFees(address _to, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_to != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be greater than zero");
        // Ensure the contract holds enough FORGE tokens
        require(
            FORGE_TOKEN.balanceOf(address(this)) >= _amount,
            "Insufficient FORGE balance in contract"
        );

        FORGE_TOKEN.transfer(_to, _amount);
        emit FeesWithdrawn(_to, _amount);
    }

    /// @notice Returns the address of the Forge ERC-20 token contract.
    function getForgeTokenAddress() external view returns (address) {
        return address(FORGE_TOKEN);
    }

    // --- II. Aetherial Artifact (NFT) Lifecycle (4 Functions) ---

    /// @notice Mints a new Aetherial Artifact NFT. Requires a FORGE fee and triggers an AI generation request.
    /// @param _prompt The creative prompt for the AI to generate the artifact.
    /// @param _initialMetadataURI An initial URI for the NFT metadata, which can be updated later.
    function forgeNewArtifact(
        string calldata _prompt,
        string calldata _initialMetadataURI
    ) external payable whenNotPaused nonReentrant {
        require(bytes(_prompt).length > 0, "Prompt cannot be empty");
        require(forgeArtifactCreationFee > 0, "Artifact creation fee must be set");

        // Transfer FORGE fee from user to contract treasury
        FORGE_TOKEN.transferFrom(
            _msgSender(),
            address(this),
            forgeArtifactCreationFee
        );

        uint256 tokenId = nextArtifactId++;
        AETHERIAL_ARTIFACTS.safeMint(_msgSender(), tokenId);
        AETHERIAL_ARTIFACTS.setTokenURI(tokenId, _initialMetadataURI);

        artifacts[tokenId] = Artifact({
            owner: _msgSender(),
            currentPropertiesJson: "", // Will be filled by AI oracle callback
            evolutionCount: 0,
            pendingEvolutionRequestId: bytes32(0),
            currentPrompt: _prompt,
            isChallenged: false
        });

        // Request initial AI generation from oracle
        bytes32 requestId = keccak256(abi.encodePacked(tokenId, _prompt, block.timestamp));
        artifacts[tokenId].pendingEvolutionRequestId = requestId;
        forgeOracle.requestAIGeneration(tokenId, requestId, _prompt);

        emit ArtifactForged(tokenId, _msgSender(), _prompt, _initialMetadataURI);
    }

    /// @notice Initiates a request for a specific artifact to evolve. Requires a FORGE fee and triggers an AI evolution request.
    /// @param _tokenId The ID of the Aetherial Artifact to evolve.
    /// @param _evolutionPrompt The new prompt for the AI to guide the artifact's evolution.
    function requestArtifactEvolution(
        uint256 _tokenId,
        string calldata _evolutionPrompt
    ) external payable whenNotPaused nonReentrant {
        require(AETHERIAL_ARTIFACTS.ownerOf(_tokenId) == _msgSender(), "Not artifact owner");
        require(bytes(_evolutionPrompt).length > 0, "Evolution prompt cannot be empty");
        require(forgeEvolutionRequestFee > 0, "Evolution request fee must be set");
        require(
            artifacts[_tokenId].pendingEvolutionRequestId == bytes32(0),
            "Artifact already has a pending evolution request"
        );

        // Transfer FORGE fee
        FORGE_TOKEN.transferFrom(
            _msgSender(),
            address(this),
            forgeEvolutionRequestFee
        );

        // Request AI evolution from oracle
        bytes32 requestId = keccak256(
            abi.encodePacked(_tokenId, _evolutionPrompt, block.timestamp)
        );
        artifacts[_tokenId].pendingEvolutionRequestId = requestId;
        forgeOracle.requestAIEvolution(_tokenId, requestId, _evolutionPrompt);

        emit ArtifactEvolutionRequested(
            _tokenId,
            _msgSender(),
            _evolutionPrompt,
            requestId
        );
    }

    /// @notice Oracle callback to finalize an artifact's evolution or initial generation.
    /// @dev This function should only be callable by the designated ForgeOracle.
    /// @param _tokenId The ID of the Aetherial Artifact.
    /// @param _requestId The request ID that matches the pending request.
    /// @param _newPropertiesJson The JSON string representing the artifact's new dynamic properties.
    /// @param _newMetadataURI The new URI for the NFT's metadata.
    function finalizeArtifactEvolution(
        uint256 _tokenId,
        bytes32 _requestId,
        string calldata _newPropertiesJson,
        string calldata _newMetadataURI
    ) external onlyForgeOracle whenNotPaused {
        require(artifacts[_tokenId].owner != address(0), "Artifact does not exist");
        require(
            artifacts[_tokenId].pendingEvolutionRequestId == _requestId,
            "Mismatching request ID for evolution"
        );
        require(!artifacts[_tokenId].isChallenged, "Evolution is under challenge");

        artifacts[_tokenId].currentPropertiesJson = _newPropertiesJson;
        AETHERIAL_ARTIFACTS.setTokenURI(_tokenId, _newMetadataURI);
        artifacts[_tokenId].evolutionCount++;
        artifacts[_tokenId].pendingEvolutionRequestId = bytes32(0); // Clear pending request

        emit ArtifactEvolutionFinalized(
            _tokenId,
            _newPropertiesJson,
            _newMetadataURI
        );
    }

    /// @notice Retrieves all key details of an Aetherial Artifact.
    /// @param _tokenId The ID of the Aetherial Artifact.
    /// @return owner The current owner of the artifact.
    /// @return currentPropertiesJson The JSON string of its current dynamic properties.
    /// @return currentMetadataURI The current URI for its metadata.
    /// @return evolutionCount The number of times the artifact has evolved.
    /// @return pendingEvolutionRequestId The request ID if an evolution is pending, else 0.
    /// @return currentPrompt The last prompt used for its generation/evolution.
    /// @return isChallenged True if the artifact's oracle response is under challenge.
    function getArtifactDetails(uint256 _tokenId)
        external
        view
        returns (
            address owner,
            string memory currentPropertiesJson,
            string memory currentMetadataURI,
            uint256 evolutionCount,
            bytes32 pendingEvolutionRequestId,
            string memory currentPrompt,
            bool isChallenged
        )
    {
        Artifact storage artifact = artifacts[_tokenId];
        require(artifact.owner != address(0), "Artifact does not exist");
        return (
            artifact.owner,
            artifact.currentPropertiesJson,
            AETHERIAL_ARTIFACTS.tokenURI(_tokenId),
            artifact.evolutionCount,
            artifact.pendingEvolutionRequestId,
            artifact.currentPrompt,
            artifact.isChallenged
        );
    }

    // --- III. Reputation & Curation System (8 Functions) ---

    /// @notice Retrieves a user's current reputation score.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getReputationScore(address _user) external view returns (uint256) {
        return reputationScores[_user];
    }

    /// @dev Internal function to increase a user's reputation.
    function _increaseReputation(address _user, uint256 _amount) internal {
        reputationScores[_user] += _amount;
        emit ReputationIncreased(_user, _amount);
    }

    /// @dev Internal function to decrease a user's reputation (e.g., for malicious behavior).
    function _decreaseReputation(address _user, uint256 _amount) internal {
        reputationScores[_user] = reputationScores[_user] < _amount
            ? 0
            : reputationScores[_user] - _amount;
        emit ReputationDecreased(_user, _amount);
    }

    /// @notice Stakes FORGE tokens to gain curation power and accrue reputation.
    /// @param _amount The amount of FORGE to stake.
    function stakeForgeForCuration(uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "Amount must be greater than zero");

        FORGE_TOKEN.transferFrom(_msgSender(), address(this), _amount);
        stakedForgeBalance[_msgSender()] += _amount;
        totalStakedForge += _amount;
        stakingTimestamp[_msgSender()] = block.timestamp; // Update timestamp for cooldown

        _increaseReputation(_msgSender(), _amount / 100); // Example: 1 reputation per 100 FORGE staked

        emit ForgeStaked(_msgSender(), _amount);
    }

    /// @notice Unstakes FORGE tokens after a cooldown period.
    /// @param _amount The amount of FORGE to unstake.
    function unstakeForgeFromCuration(uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "Amount must be greater than zero");
        require(stakedForgeBalance[_msgSender()] >= _amount, "Insufficient staked FORGE");
        // Example cooldown: 7 days
        // require(
        //     block.timestamp >= stakingTimestamp[_msgSender()] + 7 days,
        //     "Cooldown period not over"
        // );

        stakedForgeBalance[_msgSender()] -= _amount;
        totalStakedForge -= _amount;
        stakingTimestamp[_msgSender()] = block.timestamp; // Reset timestamp on unstake

        FORGE_TOKEN.transfer(_msgSender(), _amount);

        _decreaseReputation(_msgSender(), _amount / 200); // Example: Lose half the reputation gained

        emit ForgeUnstaked(_msgSender(), _amount);
    }

    /// @notice Submits a curation or governance proposal.
    /// @param _targetId The ID of the artifact, proposal, or a generic ID related to the proposal.
    /// @param _proposalType The type of proposal (e.g., AI_OUTPUT_DISPUTE, TREASURY_SPEND).
    /// @param _data Encoded data specific to the proposal type.
    function submitCurationProposal(
        uint256 _targetId,
        uint8 _proposalType,
        bytes calldata _data
    ) external whenNotPaused nonReentrant {
        require(stakedForgeBalance[_msgSender()] > 0, "Must stake FORGE to submit proposals");
        // Further checks based on proposalType and reputation could be added here

        uint256 proposalId = nextProposalId++;
        ProposalType pType = ProposalType(_proposalType);

        proposals[proposalId].id = proposalId;
        proposals[proposalId].proposalType = pType;
        proposals[proposalId].targetId = _targetId;
        proposals[proposalId].data = _data;
        proposals[proposalId].proposer = _msgSender();
        proposals[proposalId].startTimestamp = block.timestamp;
        proposals[proposalId].endTimestamp = block.timestamp + 3 days; // Example: 3-day voting period

        emit ProposalSubmitted(proposalId, pType, _msgSender());
    }

    /// @notice Users vote on an active proposal. Voting power is proportional to staked FORGE and reputation.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for', false for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.startTimestamp, "Voting has not started");
        require(block.timestamp <= proposal.endTimestamp, "Voting has ended");
        require(!proposal.hasVoted[_msgSender()], "Already voted on this proposal");
        require(stakedForgeBalance[_msgSender()] > 0, "Must stake FORGE to vote");

        // Calculate vote weight: staked FORGE + (reputation / X)
        uint256 voteWeight = stakedForgeBalance[_msgSender()] + (reputationScores[_msgSender()] / 10); // Example: 1 reputation = 0.1 FORGE vote weight
        require(voteWeight > 0, "Insufficient vote weight");

        if (_support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit VoteCast(_proposalId, _msgSender(), _support, voteWeight);
    }

    /// @notice Executes a passed proposal.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId)
        external
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.endTimestamp, "Voting has not ended yet");

        // Example: Quorum and majority check
        uint224 totalVotes = uint224(proposal.votesFor + proposal.votesAgainst);
        require(totalVotes > (totalStakedForge / 10), "Quorum not met (10% of total staked)"); // Example: 10% quorum
        proposal.passed = proposal.votesFor > proposal.votesAgainst;
        require(proposal.passed, "Proposal did not pass");

        proposal.executed = true; // Mark as executed regardless of pass/fail to prevent re-execution

        if (proposal.passed) {
            // Logic based on proposal type
            if (proposal.proposalType == ProposalType.AI_OUTPUT_DISPUTE) {
                // Example: If dispute passes, artifact.isChallenged is resolved, and AI might re-run
                Artifact storage artifact = artifacts[proposal.targetId];
                require(artifact.owner != address(0), "Target artifact does not exist");
                artifact.isChallenged = false; // Resolved challenge
                // Trigger re-request to oracle or another action
                // forgeOracle.requestAIEvolution(artifact.targetId, artifact.pendingEvolutionRequestId, artifact.currentPrompt);
            } else if (proposal.proposalType == ProposalType.ARTIFACT_ATTRIBUTE_CHANGE) {
                // Example: Parse data to update artifact properties directly (dangerous, better through oracle)
                // bytes memory decodedData = proposal.data;
                // (string memory newProps, string memory newURI) = abi.decode(decodedData, (string, string));
                // AETHERIAL_ARTIFACTS.setTokenURI(proposal.targetId, newURI);
                // artifacts[proposal.targetId].currentPropertiesJson = newProps;
            } else if (proposal.proposalType == ProposalType.PROTOCOL_PARAMETER_CHANGE) {
                // Example: Decode data to change a protocol parameter like forgeArtifactCreationFee
                // bytes memory decodedData = proposal.data;
                // (bytes32 paramName, uint256 newValue) = abi.decode(decodedData, (bytes32, uint256));
                // if (paramName == "forgeArtifactCreationFee") forgeArtifactCreationFee = newValue;
            } else if (proposal.proposalType == ProposalType.TREASURY_SPEND) {
                // This is handled by executeTreasurySpend directly if treasury proposals are unique
                // For simplicity, let's assume `executeTreasurySpend` is the final step
                // or the `data` field encodes recipient and amount
                (address recipient, uint224 amount) = abi.decode(proposal.data, (address, uint224));
                FORGE_TOKEN.transfer(recipient, amount);
                emit TreasurySpendExecuted(proposal.id, recipient, amount);
            }
        }

        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    /// @notice Allows users to claim accumulated FORGE rewards and reputation for active participation.
    function claimCurationRewards() external whenNotPaused nonReentrant {
        // This function would require a more complex reward distribution logic
        // based on active participation, vote accuracy, proposal success, etc.
        // For simplicity, a placeholder example:
        uint256 rewards = (stakedForgeBalance[_msgSender()] * 10) / 1000; // Example: 1% return on staked FORGE
        uint256 repGains = stakedForgeBalance[_msgSender()] / 50; // Example: 1 rep for every 50 FORGE staked as base reward

        require(rewards > 0, "No rewards to claim");
        require(FORGE_TOKEN.balanceOf(address(this)) >= rewards, "Insufficient treasury for rewards");

        _increaseReputation(_msgSender(), repGains);
        FORGE_TOKEN.transfer(_msgSender(), rewards);

        emit CurationRewardsClaimed(_msgSender(), rewards, repGains);
    }

    /// @notice Allows high-reputation users to challenge an oracle's AI output for an artifact.
    /// @param _artifactId The ID of the artifact whose oracle response is being challenged.
    /// @param _requestId The request ID of the specific oracle response.
    function challengeOracleResponse(uint256 _artifactId, bytes32 _requestId)
        external
        whenNotPaused
        nonReentrant
    {
        require(artifacts[_artifactId].owner != address(0), "Artifact does not exist");
        require(
            artifacts[_artifactId].pendingEvolutionRequestId == _requestId,
            "No pending oracle response matching this request"
        );
        require(
            reputationScores[_msgSender()] >= minReputationForChallenge,
            "Insufficient reputation to challenge"
        );
        require(!artifacts[_artifactId].isChallenged, "Oracle response already under challenge");

        artifacts[_artifactId].isChallenged = true;

        // Automatically create a proposal for community review
        bytes memory challengeData = abi.encode(_artifactId, _requestId);
        submitCurationProposal(
            _artifactId,
            uint8(ProposalType.AI_OUTPUT_DISPUTE),
            challengeData
        );

        emit ArtifactChallenge(_artifactId, _requestId, _msgSender());
    }

    // --- IV. Treasury & Tokenomics Governance (4 Functions) ---

    /// @notice Allows any user or contract to deposit FORGE tokens into the protocol's community treasury.
    /// @param _amount The amount of FORGE tokens to deposit.
    function depositIntoTreasury(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        FORGE_TOKEN.transferFrom(_msgSender(), address(this), _amount);
        emit TreasuryDeposit(_msgSender(), _amount);
    }

    /// @notice Initiates a governance proposal for spending treasury funds.
    /// @param _recipient The address to receive the funds.
    /// @param _amount The amount of FORGE tokens to spend.
    /// @param _description A description of the spending purpose.
    function proposeTreasurySpend(
        address _recipient,
        uint256 _amount,
        string calldata _description // Not directly used in bytes data, but good for context
    ) external whenNotPaused nonReentrant {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be greater than zero");
        require(stakedForgeBalance[_msgSender()] > 0, "Must stake FORGE to propose treasury spend");

        bytes memory spendData = abi.encode(_recipient, uint224(_amount)); // Use uint224 to fit in bytes

        submitCurationProposal(
            0, // TargetId can be 0 for general treasury proposals
            uint8(ProposalType.TREASURY_SPEND),
            spendData
        );

        emit TreasurySpendProposed(nextProposalId - 1, _recipient, _amount); // nextProposalId was incremented by submitCurationProposal
    }

    /// @notice Executes a passed treasury spend proposal, transferring FORGE from the treasury.
    /// @param _proposalId The ID of the treasury spend proposal.
    // This function will likely be called internally by `executeProposal` after a `TREASURY_SPEND` proposal passes.
    // Making it internal for better encapsulation. `executeProposal` handles external call.
    function _executeTreasurySpendInternal(uint256 _proposalId) internal nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.proposalType == ProposalType.TREASURY_SPEND, "Not a treasury spend proposal");
        require(proposal.passed, "Proposal did not pass");
        require(!proposal.executed, "Proposal already executed");

        (address recipient, uint224 amount) = abi.decode(proposal.data, (address, uint224));
        require(
            FORGE_TOKEN.balanceOf(address(this)) >= amount,
            "Insufficient FORGE balance in treasury for spend"
        );

        FORGE_TOKEN.transfer(recipient, amount);
        proposal.executed = true;
        emit TreasurySpendExecuted(proposal.id, recipient, amount);
    }
}
```