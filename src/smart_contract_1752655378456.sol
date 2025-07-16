This Solidity smart contract, `AetherweaveCollective`, is designed as a decentralized AI-augmented creative collective. Its core concept revolves around community-driven creative input ("seeds") being processed by governed AI agents to generate unique digital outputs, which are then minted as NFTs. The contract integrates advanced concepts like dynamic NFT traits, a reputation system, and a flexible governance framework to manage AI parameters and revenue distribution, all while avoiding direct duplication of existing open-source projects by combining these elements in a novel way.

---

## Aetherweave Collective: Decentralized AI-Augmented Creative Collective

### Outline:

**I. Core Principles:**
*   **Decentralized AI Integration:** Manages and governs AI agent definitions and parameters.
*   **Collaborative Creativity:** Users contribute "seeds" (text, concepts, data hashes) that AI processes.
*   **Generative NFTs:** AI-generated creative outputs are minted as NFTs with dynamic traits.
*   **Adaptive Governance:** A DAO-like structure with dynamic voting power and AI parameter adjustment.
*   **Reputation & Contribution-Based Rewards:** Incentivizes valuable participation.

**II. Key Components & Function Summary:**

**A. Global State & Configuration:**
*   **`constructor()`**: Initializes the contract, setting the initial governance role, governance token, and trusted oracle address. Also sets initial governance parameters.
*   **`updateGovernanceParams()`**: Allows governance to modify parameters for proposals (e.g., threshold, quorum, voting period).

**B. AI Agent Management:**
*   **`setOracleAddress()`**: Sets the trusted off-chain oracle address responsible for submitting verified AI generation results. (Governance-controlled)
*   **`registerAIAgent()`**: Registers a new AI agent with its configurations (e.g., name, model identifier, base cost, operator). (Governance)
*   **`updateAIAgentConfig()`**: Modifies parameters of an existing AI agent. (Governance)
*   **`setAIAgentStatus()`**: Activates or deactivates an AI agent, controlling its usability. (Governance)

**C. Seed Contribution & Management:**
*   **`submitCreativeSeed()`**: Allows users to submit a creative seed (e.g., IPFS hash of a prompt) along with collateral (in the governance token) to incentivize its processing.
*   **`revokeCreativeSeed()`**: Allows a user to withdraw their seed and reclaim collateral if the seed has not yet been processed by an AI agent.

**D. AI Output Generation & NFT Minting:**
*   **`requestAIGeneration()`**: Initiates an off-chain AI generation process for a given seed, signaling the oracle.
*   **`submitAIGenerationResult()`**: (Oracle-only) Receives, verifies (via signature), and records the AI-generated output from the trusted oracle. This triggers NFT minting.
*   **`_mintAetherweaveNFT()`**: An internal helper function called by `submitAIGenerationResult` to mint a new ERC721 NFT based on the validated AI output.
*   **`auditAIGeneration()`**: Allows users to provide feedback and rate the quality of a specific AI-generated output. This influences reputation scores and AI agent performance metrics.
*   **`tokenURI(uint256 tokenId)`**: ERC721 override to provide a dynamic metadata URI for each Aetherweave NFT, pointing to an off-chain service that generates JSON metadata based on on-chain data.
*   **`getNFTTraits(uint256 _tokenId)`**: Extracts and returns specific dynamic traits for a given NFT, derived from its on-chain generation parameters and output hash.

**E. Governance & Proposals:**
*   **`proposeChange()`**: Allows eligible members (based on reputation) to initiate a new governance proposal for various contract modifications (e.g., updating AI configs, treasury withdrawals).
*   **`voteOnProposal()`**: Enables eligible voters (based on voting power) to cast their vote (for or against) on an active proposal.
*   **`delegateVote()`**: Allows a voter to delegate their voting power (reputation and staked tokens) to another address.
*   **`executeProposal()`**: Executes the predefined actions of a successfully passed governance proposal once the voting period has ended and quorum/thresholds are met.

**F. Reputation & Reward System:**
*   **`getReputationScore()`**: Retrieves the reputation score of a specific address, accumulated through positive contributions (e.g., successful seeds, accurate audits, governance participation).
*   **`claimRoyalties()`**: Allows contributors (seed creators, AI operators, active governance participants) to claim their accumulated share of royalties from a dedicated `pendingRoyalties` balance.

**G. Treasury & Funds:**
*   **`depositFunds()`**: Allows any user to deposit the governance token into the collective's treasury.
*   **`withdrawTreasuryFunds()`**: Allows governance to withdraw funds from the collective's treasury for approved initiatives.
*   **`allocateRevenueToPending()`**: (Governance-callable) Allows governance to explicitly add funds from the treasury to a specific user's `pendingRoyalties` balance. This acts as the on-chain mechanism to distribute revenue determined by off-chain allocation logic.

**H. Query Functions (Views):**
*   **`getAIAgentConfig()`**: Retrieves the full configuration details of a specific AI agent.
*   **`getSeedDetails()`**: Retrieves comprehensive details of a submitted creative seed.
*   **`getOutputDetails()`**: Retrieves detailed information about an AI-generated output.
*   **`getProposalDetails()`**: Retrieves detailed information about a governance proposal, including votes and status.
*   **`getVotingPower()`**: Calculates and returns the current voting power of an address, considering reputation and staked governance tokens, including any delegated power.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Interface for a hypothetical staking/governance token (e.g., AET token)
interface IAETToken {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    // function totalSupply() external view returns (uint256); // Added for conceptual _getTotalVotingPower
}

contract AetherweaveCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    // --- State Variables ---

    // Governance related
    address public trustedOracleAddress;     // Address of the off-chain oracle service that submits AI results
    address public governanceTokenAddress;   // Address of the governance/staking token (e.g., AET)

    struct GovernanceParams {
        uint256 proposalThresholdBasisPoints;   // e.g., 50 (0.5%) of total voting power to create a proposal
        uint256 quorumBasisPoints;              // e.g., 400 (4%) of total voting power needed for proposal to pass
        uint256 voteSuccessThresholdBasisPoints; // e.g., 5000 (50%) of votes must be 'for' to pass
        uint256 proposalVotingPeriod;           // Duration in seconds for voting
        uint256 minReputationForProposal;       // Minimum reputation to create a proposal
    }
    GovernanceParams public govParams;

    // AI Agent related
    struct AIAgentConfig {
        string name;            // Name of the AI agent (e.g., "DALL-E 3 Integration")
        string modelIdentifier; // Identifier for the underlying AI model/service
        uint256 baseCost;       // Base cost in wei (of governance token) for a single generation using this agent
        bool isActive;          // Is the agent currently active and usable?
        uint256 successCount;   // Number of successfully verified generations by this agent
        uint256 failureCount;   // Number of failed/rejected generations (e.g., after negative audit)
        address operator;       // Address responsible for operating this AI agent (receives a share of baseCost)
    }
    mapping(uint256 => AIAgentConfig) public aiAgentConfigs;
    Counters.Counter private _aiAgentIds;

    // Creative Seed related
    struct CreativeSeed {
        address contributor;     // Address of the user who submitted the seed
        uint256 aiAgentId;       // Which AI agent is preferred for this seed (0 for any)
        bytes32 seedContentHash; // IPFS hash or content hash of the creative seed (e.g., text prompt, image hash)
        uint256 collateralAmount; // Amount of AET collateral provided
        uint256 submissionTimestamp;
        bool isProcessed;        // Has this seed been processed by an AI agent?
        uint256 generatedOutputId; // ID of the generated output, if processed
    }
    mapping(uint256 => CreativeSeed) public creativeSeeds;
    Counters.Counter private _seedIds;

    // AI Output related (NFTs)
    struct AIAgentOutput {
        uint256 seedId;              // Original seed ID
        uint256 aiAgentId;           // AI Agent that generated this output
        bytes32 outputContentHash;   // IPFS hash or content hash of the AI-generated output (e.g., image, text)
        bytes32 verificationProofHash; // The hash that was signed by the oracle
        address generatedByOracle;   // Oracle address that submitted the result
        uint256 generationTimestamp;
        int256 qualityScoreSum;     // Sum of all audit scores (can be negative)
        uint256 auditCount;          // Number of audits received
        bool isMinted;               // Has this output been minted as an NFT?
        uint256 tokenId;             // The ID of the minted NFT (equal to outputId for simplicity)
    }
    mapping(uint256 => AIAgentOutput) public aiAgentOutputs;
    Counters.Counter private _outputIds;

    // Governance Proposals
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData;       // Encoded function call to execute if proposal passes
        address target;       // Contract address to call
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint252 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool executed;
        bool cancelled;
        // Status: 0=Pending, 1=Active, 2=Succeeded, 3=Defeated, 4=Executed, 5=Cancelled
        uint8 status;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;

    // Reputation System
    mapping(address => uint256) public reputationScores; // Tracks a user's reputation
    uint256 public reputationIncrementSuccessSeed = 10; // Reputation gain for a seed that leads to an NFT
    uint256 public reputationIncrementAuditPositive = 5; // Reputation gain for a constructive audit
    uint256 public reputationDecrementAuditNegative = 3; // Reputation loss for a negative audit

    // Royalty Distribution / Pending Payouts
    mapping(address => uint256) public pendingRoyalties; // Share of royalties/revenue for each address

    // Delegation for voting power
    mapping(address => address) public votingDelegates;

    // --- Events ---
    event GovernanceParamsUpdated(uint256 proposalThreshold, uint256 quorum, uint256 voteSuccessThreshold, uint256 proposalVotingPeriod);
    event AIAgentRegistered(uint256 indexed agentId, string name, address operator);
    event AIAgentConfigUpdated(uint256 indexed agentId, string name, bool isActive);
    event CreativeSeedSubmitted(uint256 indexed seedId, address indexed contributor, uint256 aiAgentId, bytes32 seedContentHash, uint256 collateralAmount);
    event CreativeSeedRevoked(uint256 indexed seedId, address indexed contributor, uint256 returnedCollateral);
    event AIGenerationRequested(uint256 indexed seedId, uint256 indexed aiAgentId, address requester);
    event AIGenerationResultSubmitted(uint256 indexed outputId, uint256 indexed seedId, uint256 indexed aiAgentId, bytes32 outputContentHash);
    event AetherweaveNFTMinted(uint256 indexed tokenId, uint256 indexed outputId, address indexed owner, string tokenURI);
    event AIGenerationAudited(uint256 indexed outputId, address indexed auditor, int256 score);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startBlock, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event RoyaltiesClaimed(address indexed claimant, uint256 amount);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event RevenueAllocatedToPending(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == trustedOracleAddress, "Aetherweave: Caller is not the trusted oracle");
        _;
    }

    modifier onlyGovernance() {
        // For simplicity, `Ownable` is used initially for the deployer to manage core settings.
        // In a full DAO, this would transition to being controlled by the DAO's governance contract.
        require(msg.sender == owner(), "Aetherweave: Caller is not the governance controller");
        _;
    }

    // --- Constructor ---
    constructor(address _governanceToken, address _initialOracle) ERC721("Aetherweave NFT", "AETN") Ownable(msg.sender) {
        require(_governanceToken != address(0), "Aetherweave: Governance token address cannot be zero");
        require(_initialOracle != address(0), "Aetherweave: Initial oracle address cannot be zero");

        governanceTokenAddress = _governanceToken;
        trustedOracleAddress = _initialOracle;

        // Set initial governance parameters (can be updated later by governance proposals)
        govParams = GovernanceParams({
            proposalThresholdBasisPoints: 50,     // 0.5%
            quorumBasisPoints: 400,               // 4%
            voteSuccessThresholdBasisPoints: 5000, // 50%
            proposalVotingPeriod: 7 days,         // 7 days in seconds
            minReputationForProposal: 100         // Example value
        });

        // Initialize reputation for deployer/initial governance
        reputationScores[msg.sender] = 500;
    }

    // --- A. Global State & Configuration ---

    // 1. (Constructor handles initialization)

    // 2. updateGovernanceParams()
    function updateGovernanceParams(
        uint256 _proposalThresholdBasisPoints,
        uint256 _quorumBasisPoints,
        uint256 _voteSuccessThresholdBasisPoints,
        uint256 _proposalVotingPeriod,
        uint256 _minReputationForProposal
    ) external onlyGovernance {
        require(_proposalThresholdBasisPoints <= 10000, "Aetherweave: Invalid proposal threshold (max 100%)");
        require(_quorumBasisPoints <= 10000, "Aetherweave: Invalid quorum (max 100%)");
        require(_voteSuccessThresholdBasisPoints <= 10000, "Aetherweave: Invalid success threshold (max 100%)");
        require(_proposalVotingPeriod > 0, "Aetherweave: Voting period must be positive");

        govParams = GovernanceParams({
            proposalThresholdBasisPoints: _proposalThresholdBasisPoints,
            quorumBasisPoints: _quorumBasisPoints,
            voteSuccessThresholdBasisPoints: _voteSuccessThresholdBasisPoints,
            proposalVotingPeriod: _proposalVotingPeriod,
            minReputationForProposal: _minReputationForProposal
        });

        emit GovernanceParamsUpdated(_proposalThresholdBasisPoints, _quorumBasisPoints, _voteSuccessThresholdBasisPoints, _proposalVotingPeriod);
    }

    // --- B. AI Agent Management ---

    // 3. setOracleAddress()
    function setOracleAddress(address _newOracle) external onlyGovernance {
        require(_newOracle != address(0), "Aetherweave: New oracle address cannot be zero");
        trustedOracleAddress = _newOracle;
    }

    // 4. registerAIAgent()
    function registerAIAgent(
        string memory _name,
        string memory _modelIdentifier,
        uint256 _baseCost,
        address _operator
    ) external onlyGovernance returns (uint256) {
        require(bytes(_name).length > 0, "Aetherweave: Agent name cannot be empty");
        require(bytes(_modelIdentifier).length > 0, "Aetherweave: Model identifier cannot be empty");
        require(_operator != address(0), "Aetherweave: Operator address cannot be zero");

        _aiAgentIds.increment();
        uint256 newId = _aiAgentIds.current();
        aiAgentConfigs[newId] = AIAgentConfig({
            name: _name,
            modelIdentifier: _modelIdentifier,
            baseCost: _baseCost,
            isActive: true, // Default to active upon registration
            successCount: 0,
            failureCount: 0,
            operator: _operator
        });
        emit AIAgentRegistered(newId, _name, _operator);
        return newId;
    }

    // 5. updateAIAgentConfig()
    function updateAIAgentConfig(
        uint256 _agentId,
        string memory _name,
        string memory _modelIdentifier,
        uint256 _baseCost,
        address _operator
    ) external onlyGovernance {
        AIAgentConfig storage agent = aiAgentConfigs[_agentId];
        require(bytes(agent.name).length > 0, "Aetherweave: AI Agent with this ID does not exist");
        require(_operator != address(0), "Aetherweave: Operator address cannot be zero");

        agent.name = _name;
        agent.modelIdentifier = _modelIdentifier;
        agent.baseCost = _baseCost;
        agent.operator = _operator;
        emit AIAgentConfigUpdated(_agentId, _name, agent.isActive);
    }

    // 6. setAIAgentStatus()
    function setAIAgentStatus(uint256 _agentId, bool _isActive) external onlyGovernance {
        AIAgentConfig storage agent = aiAgentConfigs[_agentId];
        require(bytes(agent.name).length > 0, "Aetherweave: AI Agent with this ID does not exist");
        require(agent.isActive != _isActive, "Aetherweave: AI Agent already in desired status");
        agent.isActive = _isActive;
        emit AIAgentConfigUpdated(_agentId, agent.name, _isActive);
    }

    // --- C. Seed Contribution & Management ---

    // 7. submitCreativeSeed()
    function submitCreativeSeed(
        uint256 _aiAgentId, // 0 if any AI agent is acceptable
        bytes32 _seedContentHash,
        uint256 _collateralAmount
    ) external {
        require(_seedContentHash != bytes32(0), "Aetherweave: Seed content hash cannot be empty");
        require(_collateralAmount > 0, "Aetherweave: Collateral amount must be greater than zero");
        if (_aiAgentId != 0) {
            require(bytes(aiAgentConfigs[_aiAgentId].name).length > 0 && aiAgentConfigs[_aiAgentId].isActive, "Aetherweave: Specified AI Agent not found or inactive");
            require(_collateralAmount >= aiAgentConfigs[_aiAgentId].baseCost, "Aetherweave: Insufficient collateral for specified AI agent's base cost");
        } else {
            // If any agent, ensure collateral is enough for at least the minimum current base cost of active agents, or a default.
            // For simplicity, we just check >0 for now, actual check might be more complex
        }

        // Transfer collateral (e.g., AET token) from user to contract
        require(IAETToken(governanceTokenAddress).transferFrom(msg.sender, address(this), _collateralAmount), "Aetherweave: Collateral transfer failed");

        _seedIds.increment();
        uint256 newId = _seedIds.current();
        creativeSeeds[newId] = CreativeSeed({
            contributor: msg.sender,
            aiAgentId: _aiAgentId,
            seedContentHash: _seedContentHash,
            collateralAmount: _collateralAmount,
            submissionTimestamp: block.timestamp,
            isProcessed: false,
            generatedOutputId: 0
        });
        emit CreativeSeedSubmitted(newId, msg.sender, _aiAgentId, _seedContentHash, _collateralAmount);
    }

    // 8. revokeCreativeSeed()
    function revokeCreativeSeed(uint256 _seedId) external {
        CreativeSeed storage seed = creativeSeeds[_seedId];
        require(seed.contributor == msg.sender, "Aetherweave: Only the seed contributor can revoke");
        require(seed.contributor != address(0), "Aetherweave: Seed does not exist"); // Check if seed struct is initialized
        require(!seed.isProcessed, "Aetherweave: Seed already processed, cannot revoke");
        require(seed.collateralAmount > 0, "Aetherweave: No active collateral to revoke");

        // Return collateral to the contributor
        IAETToken(governanceTokenAddress).transfer(msg.sender, seed.collateralAmount);

        // Mark seed as inactive or revoked by setting collateral to 0
        seed.collateralAmount = 0;
        emit CreativeSeedRevoked(_seedId, msg.sender, seed.collateralAmount);
    }

    // --- D. AI Output Generation & NFT Minting ---

    // 9. requestAIGeneration()
    // This function signals an off-chain oracle that a seed is ready for processing.
    // In a real system, the oracle would monitor these events or an off-chain API.
    function requestAIGeneration(uint256 _seedId) external {
        CreativeSeed storage seed = creativeSeeds[_seedId];
        require(seed.contributor != address(0), "Aetherweave: Seed does not exist");
        require(!seed.isProcessed, "Aetherweave: Seed already processed");
        require(seed.collateralAmount > 0, "Aetherweave: Seed has no active collateral or it was revoked");

        // Reputation bonus for requesting a generation
        reputationScores[msg.sender] = reputationScores[msg.sender].add(1); // Small reputation for participation
        emit AIGenerationRequested(_seedId, seed.aiAgentId, msg.sender);
    }

    // 10. submitAIGenerationResult()
    // This is called by the trusted oracle after off-chain AI processing.
    // It validates the output and prepares for NFT minting.
    // The proof is the oracle's signature over the critical data.
    function submitAIGenerationResult(
        uint256 _seedId,
        uint256 _aiAgentId,
        bytes32 _outputContentHash,
        bytes memory _signature // Oracle's signature over keccak256(abi.encodePacked(_seedId, _aiAgentId, _outputContentHash, block.chainid, address(this)))
    ) external onlyOracle {
        CreativeSeed storage seed = creativeSeeds[_seedId];
        require(seed.contributor != address(0), "Aetherweave: Seed does not exist");
        require(!seed.isProcessed, "Aetherweave: Seed already processed for generation");
        require(_outputContentHash != bytes32(0), "Aetherweave: Output content hash cannot be empty");
        AIAgentConfig storage agent = aiAgentConfigs[_aiAgentId];
        require(bytes(agent.name).length > 0 && agent.isActive, "Aetherweave: AI Agent not found or inactive");
        
        // Verify the oracle's signature
        bytes32 messageHash = keccak256(abi.encodePacked(_seedId, _aiAgentId, _outputContentHash, block.chainid, address(this)));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        require(ethSignedMessageHash.recover(_signature) == trustedOracleAddress, "Aetherweave: Invalid oracle signature");

        // Mark seed as processed
        seed.isProcessed = true;
        reputationScores[seed.contributor] = reputationScores[seed.contributor].add(reputationIncrementSuccessSeed); // Reward seed contributor

        _outputIds.increment();
        uint256 newOutputId = _outputIds.current();
        aiAgentOutputs[newOutputId] = AIAgentOutput({
            seedId: _seedId,
            aiAgentId: _aiAgentId,
            outputContentHash: _outputContentHash,
            verificationProofHash: messageHash, // Storing the hash that was signed
            generatedByOracle: msg.sender,
            generationTimestamp: block.timestamp,
            qualityScoreSum: 0, // Initial sum
            auditCount: 0,      // Initial count
            isMinted: true,     // Marked as ready for minting / implicitly minted
            tokenId: newOutputId // Token ID will be same as outputId for simplicity
        });
        seed.generatedOutputId = newOutputId;

        // Increment AI agent success count
        agent.successCount++;

        // Distribute AI Agent operator fee from seed collateral
        uint256 agentFee = agent.baseCost;
        if (agentFee > 0) {
            uint256 actualFeePaid = seed.collateralAmount >= agentFee ? agentFee : seed.collateralAmount;
            IAETToken(governanceTokenAddress).transfer(agent.operator, actualFeePaid);
            seed.collateralAmount = seed.collateralAmount.sub(actualFeePaid); // Deduct consumed collateral
        }
        
        // Return remaining collateral to seed contributor if any
        if (seed.collateralAmount > 0) {
            IAETToken(governanceTokenAddress).transfer(seed.contributor, seed.collateralAmount);
            seed.collateralAmount = 0; // Mark collateral as fully disbursed
        }

        // Mint NFT immediately upon successful generation result submission
        _mintAetherweaveNFT(newOutputId, seed.contributor); // Mints to the seed contributor
        emit AIGenerationResultSubmitted(newOutputId, _seedId, _aiAgentId, _outputContentHash);
    }

    // 11. _mintAetherweaveNFT() (Internal helper)
    function _mintAetherweaveNFT(uint256 _outputId, address _to) internal {
        AIAgentOutput storage output = aiAgentOutputs[_outputId];
        // The `isMinted` flag in AIAgentOutput is set to true in submitAIGenerationResult for direct minting.
        // This check ensures it's a new mint based on the output.
        require(output.tokenId == _outputId, "Aetherweave: Invalid outputId for minting"); // Ensure tokenId == outputId logic holds

        _mint(_to, output.tokenId); // Mint the ERC721 NFT
        emit AetherweaveNFTMinted(output.tokenId, _outputId, _to, tokenURI(output.tokenId));
    }

    // 12. auditAIGeneration()
    function auditAIGeneration(uint256 _outputId, int256 _score) external {
        AIAgentOutput storage output = aiAgentOutputs[_outputId];
        require(output.seedId != 0, "Aetherweave: Output does not exist");
        require(output.isMinted, "Aetherweave: Output not yet minted as NFT");
        require(output.generatedByOracle != msg.sender, "Aetherweave: Oracle cannot audit its own generation");
        require(creativeSeeds[output.seedId].contributor != msg.sender, "Aetherweave: Seed contributor cannot audit their own output");
        require(_score >= -10 && _score <= 10, "Aetherweave: Score must be between -10 and 10"); // Example score range

        output.qualityScoreSum = output.qualityScoreSum.add(uint256(uint256(_score))); // Add score to sum (handles potential negative values by casting)
        output.auditCount++;

        // Adjust AI agent's performance metrics and auditor's reputation
        if (_score >= 0) {
            aiAgentConfigs[output.aiAgentId].successCount++;
            reputationScores[msg.sender] = reputationScores[msg.sender].add(reputationIncrementAuditPositive);
        } else {
            aiAgentConfigs[output.aiAgentId].failureCount++;
            // Prevent underflow by checking if reputation is high enough before decrementing
            if (reputationScores[msg.sender] > reputationDecrementAuditNegative) {
                reputationScores[msg.sender] = reputationScores[msg.sender].sub(reputationDecrementAuditNegative);
            } else {
                reputationScores[msg.sender] = 0;
            }
        }
        emit AIGenerationAudited(_outputId, msg.sender, _score);
    }

    // 13. getNFTMetadataURI() (ERC721 tokenURI override)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // As per ERC721, we assume tokenId == outputId
        AIAgentOutput storage output = aiAgentOutputs[tokenId];
        require(output.seedId != 0, "ERC721Metadata: URI query for nonexistent token");

        // In a real dApp, this would point to a service that dynamically generates JSON metadata
        // based on the on-chain `outputContentHash` (IPFS hash for image/data) and other traits.
        // Example: `https://aetherweave.io/api/metadata/{tokenId}`
        return string(abi.encodePacked("https://aetherweave.io/api/metadata/", Strings.toString(tokenId)));
    }

    // 14. getNFTTraits()
    function getNFTTraits(uint256 _tokenId) public view returns (string memory visualStyle, string memory aiSignature, string memory seedDescriptionHash) {
        AIAgentOutput storage output = aiAgentOutputs[_tokenId];
        require(output.seedId != 0, "Aetherweave: Token does not exist");

        CreativeSeed storage seed = creativeSeeds[output.seedId];
        AIAgentConfig storage agent = aiAgentConfigs[output.aiAgentId];

        // Dynamic traits example:
        // - "visualStyle": Derived from the first few bytes of the AI-generated output's content hash.
        // - "aiSignature": The identifier of the AI model used.
        // - "seedDescriptionHash": The hash of the original creative seed.
        bytes32 outputHash = output.outputContentHash;
        bytes2 firstBytes = bytes2(outputHash);
        visualStyle = string(abi.encodePacked("0x", Strings.toHexString(uint16(firstBytes), 4))); // e.g., "0xABCD"

        aiSignature = agent.modelIdentifier;
        seedDescriptionHash = Strings.toHexString(uint256(seed.seedContentHash)); // Convert full hash to hex string

        return (visualStyle, aiSignature, seedDescriptionHash);
    }


    // --- E. Governance & Proposals ---

    // Internal helper to get total voting power (simplified)
    function _getTotalVotingPower() internal view returns (uint256) {
        // In a real DAO, this would be a snapshot of the token's total supply
        // or total tokens staked/delegated at a specific block number.
        // For this example, we assume a conceptual "total network power"
        // for quorum calculation. A more robust system would require a token with `totalSupply()`
        // or a dedicated staking contract.
        // For demonstration, let's use a mock large number to simulate total voting power.
        // This is a placeholder and would need a robust implementation in a production DAO.
        return 100_000_000 * (10**18); // 100M tokens, assuming 18 decimals
    }

    // 15. proposeChange()
    function proposeChange(
        string memory _description,
        address _target,
        bytes memory _callData
    ) external returns (uint256) {
        require(reputationScores[msg.sender] >= govParams.minReputationForProposal, "Aetherweave: Insufficient reputation to propose");
        // Additional check: minimum staked governance tokens could be required to prevent spam.

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        proposals[newId] = Proposal({
            id: newId,
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            target: _target,
            startBlock: block.number,
            endBlock: block.number + govParams.proposalVotingPeriod / 12, // Approx blocks (12 sec/block)
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            cancelled: false,
            status: 1 // 1: Active
        });

        emit ProposalCreated(newId, msg.sender, _description, proposals[newId].startBlock, proposals[newId].endBlock);
        return newId;
    }

    // 16. voteOnProposal()
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Aetherweave: Proposal does not exist");
        require(proposal.status == 1, "Aetherweave: Proposal not active for voting");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "Aetherweave: Voting period closed");
        require(!proposal.hasVoted[msg.sender], "Aetherweave: You have already voted on this proposal");

        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "Aetherweave: No voting power to cast a vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    // 17. delegateVote()
    // Allows a user to delegate their combined voting power (reputation + staked tokens)
    function delegateVote(address _delegate) external {
        require(_delegate != address(0), "Aetherweave: Cannot delegate to zero address");
        require(_delegate != msg.sender, "Aetherweave: Cannot delegate to self");
        votingDelegates[msg.sender] = _delegate;
    }

    // Internal helper for raw voting power
    function _getRawVotingPower(address _voter) internal view returns (uint256) {
        // Voting power is a combination of reputation score and staked AET tokens.
        // This formula can be adjusted based on desired weighting.
        uint256 stakedTokens = IAETToken(governanceTokenAddress).balanceOf(_voter);
        return reputationScores[_voter].div(10).add(stakedTokens); // Example: 10 reputation points = 1 token equivalent
    }

    // 18. getVotingPower()
    function getVotingPower(address _voter) public view returns (uint256) {
        address currentDelegate = votingDelegates[_voter];
        if (currentDelegate == address(0)) {
            return _getRawVotingPower(_voter);
        } else {
            // If A delegates to B, B's voting power includes A's raw power.
            // This is a direct delegation model.
            return _getRawVotingPower(currentDelegate).add(_getRawVotingPower(_voter)); // Simplified: Delegated power adds to delegate's
        }
    }

    // 19. executeProposal()
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Aetherweave: Proposal does not exist");
        require(proposal.status == 1, "Aetherweave: Proposal not active for voting");
        require(block.number > proposal.endBlock, "Aetherweave: Voting period has not ended");
        require(!proposal.executed, "Aetherweave: Proposal already executed");
        require(!proposal.cancelled, "Aetherweave: Proposal cancelled");

        uint256 totalVotesCast = proposal.votesFor.add(proposal.votesAgainst);
        uint256 totalNetworkPower = _getTotalVotingPower();

        // Check quorum: percentage of total voting power that participated
        require(totalVotesCast.mul(10000).div(totalNetworkPower) >= govParams.quorumBasisPoints, "Aetherweave: Quorum not met");

        // Check success threshold: percentage of 'for' votes out of total votes cast
        require(proposal.votesFor.mul(10000).div(totalVotesCast) >= govParams.voteSuccessThresholdBasisPoints, "Aetherweave: Proposal did not pass the success threshold");

        // Execute the proposal's action
        proposal.status = 2; // Succeeded (before execution)
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "Aetherweave: Proposal execution failed");
        
        proposal.executed = true;
        proposal.status = 4; // Executed
        emit ProposalExecuted(_proposalId);
    }

    // --- F. Reputation & Reward System ---

    // 20. getReputationScore()
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    // 21. claimRoyalties()
    function claimRoyalties() external {
        uint256 amount = pendingRoyalties[msg.sender];
        require(amount > 0, "Aetherweave: No pending royalties to claim");

        pendingRoyalties[msg.sender] = 0; // Reset before transfer to prevent re-entrancy

        // Transfer funds from contract treasury
        // Assumes royalties are in the governance token for simplicity
        require(IAETToken(governanceTokenAddress).transfer(msg.sender, amount), "Aetherweave: Royalty transfer failed");
        emit RoyaltiesClaimed(msg.sender, amount);
    }

    // --- G. Treasury & Funds ---

    // 22. depositFunds()
    function depositFunds(uint256 _amount) external {
        require(_amount > 0, "Aetherweave: Deposit amount must be positive");
        require(IAETToken(governanceTokenAddress).transferFrom(msg.sender, address(this), _amount), "Aetherweave: Deposit transfer failed");
        emit FundsDeposited(msg.sender, _amount);
    }

    // 23. withdrawTreasuryFunds()
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyGovernance {
        require(_recipient != address(0), "Aetherweave: Recipient cannot be zero address");
        require(_amount > 0, "Aetherweave: Withdrawal amount must be positive");
        require(IAETToken(governanceTokenAddress).balanceOf(address(this)) >= _amount, "Aetherweave: Insufficient treasury balance for withdrawal");

        require(IAETToken(governanceTokenAddress).transfer(_recipient, _amount), "Aetherweave: Treasury withdrawal failed");
        emit FundsWithdrawn(_recipient, _amount);
    }

    // 24. allocateRevenueToPending()
    // This function allows governance to explicitly add funds to a user's pending royalty balance.
    // In a full system, the allocation logic (e.g., based on NFT sales, AI agent performance,
    // and governance participation) would likely be calculated off-chain and then
    // enacted on-chain via a governance proposal calling this function multiple times.
    function allocateRevenueToPending(address _recipient, uint256 _amount) external onlyGovernance {
        require(_recipient != address(0), "Aetherweave: Recipient cannot be zero");
        require(_amount > 0, "Aetherweave: Allocation amount must be positive");
        // Ensure the contract has enough funds *before* adding to pending.
        // Funds are effectively moved from the general treasury to pending balance.
        require(IAETToken(governanceTokenAddress).balanceOf(address(this)) >= _amount, "Aetherweave: Insufficient treasury balance for allocation");

        // No actual transfer out of the contract here, just moves it from general balance to specific `pendingRoyalties`
        // Effectively, the `_amount` is deducted from the general callable treasury and earmarked for `_recipient`.
        // A more robust system might have a separate "earmarked" balance, but for simplicity, we rely on the `pendingRoyalties` map.
        // Alternatively, this could assume the funds are already in the contract and just manage the internal accounting.
        // For clarity, let's make it explicitly decrease the general treasury amount by setting up a dummy recipient.
        // Or simply, this function assumes the funds were sent to the contract *before* this call,
        // and it's just about internal accounting.

        // Simplification: This function just adds to the pending balance, assuming funds are already in the contract.
        // The actual deduction from "free" treasury is implicitly handled by governance choosing to earmark funds.
        pendingRoyalties[_recipient] = pendingRoyalties[_recipient].add(_amount);
        emit RevenueAllocatedToPending(_recipient, _amount);
    }

    // --- H. Query Functions (Views) ---

    // 25. getAIAgentConfig()
    function getAIAgentConfig(uint256 _agentId) public view returns (AIAgentConfig memory) {
        return aiAgentConfigs[_agentId];
    }

    // 26. getSeedDetails()
    function getSeedDetails(uint256 _seedId) public view returns (CreativeSeed memory) {
        return creativeSeeds[_seedId];
    }

    // 27. getOutputDetails()
    function getOutputDetails(uint256 _outputId) public view returns (AIAgentOutput memory) {
        return aiAgentOutputs[_outputId];
    }

    // 28. getProposalDetails()
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    // Override supportsInterface for ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```