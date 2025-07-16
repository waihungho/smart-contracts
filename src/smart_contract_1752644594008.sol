Here's a smart contract written in Solidity, designed with several advanced, creative, and trendy concepts. It focuses on a "Decentralized AI-Assisted Research & Knowledge Nexus" where proposals can be funded, evaluated by humans and AI, and participants earn reputation via Soulbound Tokens (SBTs), all while leveraging Dynamic NFTs (dNFTs) for research projects and adaptive governance.

This contract explicitly avoids duplicating any specific open-source project by combining these concepts in a novel way for this particular application. The ZK-proof integration is simulated, as full on-chain ZKP verification is typically done via specialized precompiles or external verifier contracts, which is beyond the scope of a single contract example.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting numbers to strings for URIs

/**
 * @title AethelResearchNexus
 * @dev A decentralized platform for funding, evaluating, and curating research or knowledge artifacts.
 *      It integrates AI oracle services, a reputation system, Soulbound Tokens (SBTs),
 *      Dynamic NFTs (dNFTs) for proposals, and an adaptive governance model.
 */
contract AethelResearchNexus is ERC721, ERC1155, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Outline ---
    // 1. Core Structures (Enums, Structs)
    // 2. State Variables & Mappings
    // 3. Events
    // 4. Modifiers
    // 5. Constructor
    // 6. Core Registry & Creation Functions
    // 7. Funding & Staking Functions
    // 8. AI Integration & Evaluation Functions
    // 9. Reputation & Soulbound Token (SBT) Management
    // 10. Dynamic NFT (dNFT) Management
    // 11. Adaptive Governance & Parameter Updates
    // 12. Utility & View Functions

    // --- Function Summary ---
    // **I. Core Registry & Creation:**
    // 1. `registerResearchProposal(string memory _title, string memory _ipfsHashDetails)`: Creates a new research proposal and mints a unique dNFT for it, representing the project lifecycle.
    // 2. `registerAIOracle(string memory _name, string memory _description, address _oracleAddress)`: Registers an AI oracle provider, allowing them to submit analyses for proposals.
    // 3. `registerEvaluator(string memory _name, string memory _profileIpfsHash)`: Registers a human evaluator, enabling them to review and score proposals.
    // 4. `issueSoulboundCredential(address _recipient, uint256 _credentialType, string memory _descriptionIpfsHash)`: Issues a non-transferable Soulbound Token (SBT) credential to a recipient for specific achievements or roles within the nexus (e.g., verified evaluator, top AI contributor).

    // **II. Funding & Staking:**
    // 5. `fundProposal(uint256 _proposalId)`: Allows users to contribute ETH to fund a specific research proposal. Progress dynamically updates the associated dNFT.
    // 6. `stakeForEvaluation(uint256 _proposalId)`: Requires evaluators to stake a specific amount of ETH before submitting a review, ensuring commitment and deterring spam.
    // 7. `withdrawStakedEvaluationFunds(uint256 _proposalId)`: Allows an evaluator to reclaim their staked funds after completing their review or if the evaluation period concludes.
    // 8. `claimFunds(uint256 _proposalId)`: Enables a proposal's creator to claim accumulated funds upon successful completion, milestone achievement, or reaching funding goals.

    // **III. AI Integration & Evaluation:**
    // 9. `submitAIAnalysis(uint256 _proposalId, address _oracleAddress, string memory _analysisIpfsHash, bytes memory _zkProofData)`: An AI oracle submits its analysis for a proposal. It includes a `_zkProofData` field to conceptually support verifiable computation (simulated for this example).
    // 10. `submitHumanEvaluation(uint256 _proposalId, uint8 _score, string memory _reviewIpfsHash)`: A registered human evaluator submits their score and review for a proposal.
    // 11. `verifyZKProof(bytes memory _proofData, address _prover, uint256 _proofType)` (Internal): A simulated ZK-proof verification function. In a real scenario, this would interact with a specialized verifier contract or precompile to cryptographically validate off-chain computation.
    // 12. `requestAIAnalysis(uint256 _proposalId, address _oracleAddress, uint256 _analysisType)`: Triggers a request for an AI oracle to perform a specific analysis on a proposal, typically via an off-chain event listener.

    // **IV. Reputation & Soulbound Token (SBT) Management:**
    // 13. `getReputationScore(address _user)`: Returns the current aggregate reputation score of a given user, reflecting their overall contributions and reliability.
    // 14. `getSoulboundCredential(address _user, uint256 _credentialId)`: Retrieves detailed information about a specific SBT held by a user.
    // 15. `updateReputationBasedOnContribution(address _contributor, uint256 _contributionType, int256 _delta)` (Internal): Adjusts a user's reputation score. This function is called internally after verified contributions (e.g., accurate reviews, successful AI analyses).

    // **V. Dynamic NFT (dNFT) Management:**
    // 16. `getProposalNFTURI(uint256 _proposalId)`: Returns the dynamic URI for a proposal's NFT. This URI points to an off-chain metadata API that serves different JSON based on the proposal's real-time on-chain state (e.g., funding status, evaluation progress).
    // 17. `updateProposalNFTState(uint256 _proposalId, uint256 _newState)` (Internal): Updates the on-chain status or progress of a proposal, which implicitly changes the metadata served by the dNFT's URI.

    // **VI. Adaptive Governance & Parameter Updates:**
    // 18. `proposeParameterChange(string memory _parameterName, uint256 _newValue, string memory _description)`: Allows authorized users (owner in this demo, could be high-reputation holders in a full DAO) to propose changes to key contract parameters.
    // 19. `voteOnParameterChange(uint256 _proposalId, bool _approve)`: Enables users to vote on active parameter change proposals. Vote weight is proportional to their on-chain reputation.
    // 20. `executeParameterChange(uint256 _proposalId)`: Executes a governance proposal if it has passed the required vote threshold and its voting period has ended.
    // 21. `updateOracleWhitelist(address _oracleAddress, bool _isWhitelisted)`: Governance function to add or remove AI oracles from the whitelist, controlling who can submit verifiable analyses.
    // 22. `emergencyPause()`: Allows the owner to pause critical contract functions in an emergency situation.
    // 23. `unpause()`: Allows the owner to resume contract operations after an emergency pause.
    // 24. `setMinEvaluationReputation(uint256 _minReputation)`: Sets the minimum reputation score required for users to become evaluators or participate in certain evaluation tasks (can also be done via governance).

    // **VII. Utility & View Functions:**
    // 25. `getProposalDetails(uint256 _proposalId)`: Retrieves comprehensive details about a specific research proposal.
    // 26. `getOracleDetails(address _oracleAddress)`: Fetches the registered details of an AI oracle.
    // 27. `getParameter(string memory _parameterName)`: A general view function to retrieve the current value of any configurable governance parameter.

    // --- 1. Core Structures ---

    // Enum for proposal status
    enum ProposalStatus {
        PendingFunding,
        Funded,
        UnderEvaluation,
        Completed,
        Failed,
        Rejected
    }

    // Enum for Soulbound Credential Types (ERC1155 Token IDs are mapped to these)
    enum CredentialType {
        EvaluatorVerified = 1,      // Issued upon successful registration as an evaluator and first good review
        AIModelApproved = 2,        // Issued to AI oracles for highly accurate/verifiable analyses
        ResearchCompleted = 3,      // Issued to proposers upon successful completion of their research
        TopContributor = 4,         // For significant, sustained positive contributions
        GovernanceParticipant = 5   // For active participation in governance voting
    }

    // Enum for AI Analysis Types (example, used for clarity in requests/proofs)
    enum AnalysisType {
        FeasibilityCheck = 100,
        PlagiarismDetection = 101,
        ImpactPrediction = 102,
        Summarization = 103
    }

    // Struct for Research Proposals (each associated with an ERC721 dNFT)
    struct ResearchProposal {
        Counters.Counter id;
        address creator;
        string title;
        string ipfsHashDetails; // IPFS hash for full proposal details (e.g., PDF, markdown)
        uint256 fundingGoal;    // Target funding amount
        uint256 currentFunding; // Current accumulated funding
        ProposalStatus status;
        uint256 creationTime;
        uint256 lastActivityTime;
        uint256 nftTokenId; // Token ID for the associated ERC721 dNFT

        // Mappings within struct are costly and usually avoided unless necessary.
        // For simplicity and demo, we keep them to show logic.
        // In a large-scale system, these might be separate mappings.
        mapping(address => bool) funders; // Keep track of unique funders
        mapping(address => bool) evaluatorsSubmitted; // Evaluators who submitted for this proposal
        mapping(address => uint256) evaluatorStakes; // Amount staked by evaluators for this proposal
    }

    // Struct for Registered AI Oracles
    struct AIOracle {
        string name;
        string description;
        address oracleAddress;
        bool isWhitelisted; // Only whitelisted oracles can submit results
        uint256 reputation; // Reputation for AI model accuracy/reliability
    }

    // Struct for Registered Human Evaluators
    struct HumanEvaluator {
        string name;
        string profileIpfsHash;
        uint256 reputation; // Reputation for review quality/accuracy
        uint256 lastReviewTime;
    }

    // Struct for Soulbound Credential (details associated with an ERC1155 token ID)
    struct SoulboundCredential {
        uint256 credentialId; // The ERC1155 token ID (corresponds to CredentialType enum value)
        CredentialType credentialType;
        string descriptionIpfsHash; // IPFS hash for credential details (e.g., reason for award, proof link)
        uint256 issueTime;
    }

    // Struct for Governance Parameter Proposals
    struct GovernanceProposal {
        Counters.Counter id;
        string parameterName; // Name of the parameter to change (e.g., "minReputationForEvaluator")
        uint256 newValue;    // The proposed new value
        string description;  // Reason/justification for the proposal
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 yeas;        // Total 'yes' votes weighted by reputation
        uint256 nays;        // Total 'no' votes weighted by reputation
        mapping(address => bool) hasVoted; // Tracks who has voted on this proposal
        bool executed;       // True if the proposal has been successfully applied
    }

    // --- 2. State Variables & Mappings ---

    Counters.Counter private _proposalIds;          // Counter for unique research proposal IDs (also ERC721 token IDs)
    Counters.Counter private _governanceProposalIds; // Counter for unique governance proposal IDs

    mapping(uint256 => ResearchProposal) public proposals; // Maps proposal ID to its details
    mapping(address => AIOracle) public aiOracles;         // Maps AI oracle address to its details
    mapping(address => bool) public isAIOracleRegistered;  // Quick check if address is a registered AI oracle

    mapping(address => HumanEvaluator) public humanEvaluators; // Maps evaluator address to their details
    mapping(address => bool) public isHumanEvaluatorRegistered; // Quick check if address is a registered human evaluator

    mapping(address => uint256) public userReputation; // Aggregate reputation score for any user (evaluator, oracle, proposer, voter)

    // ERC1155 mapping for SBTs: user address => token ID (which is CredentialType enum value) => credential details
    mapping(address => mapping(uint256 => SoulboundCredential)) public userSoulboundCredentials;
    mapping(address => uint256[]) public userSBTTokenIds; // List of ERC1155 token IDs (credential types) held by a user

    mapping(uint256 => GovernanceProposal) public governanceProposals; // Maps governance proposal ID to its details

    // Dynamic parameters controlled by governance (initial values set in constructor)
    uint256 public minReputationForEvaluator;      // Minimum reputation required to evaluate proposals
    uint256 public evaluationStakeAmount;          // Amount an evaluator must stake per proposal
    uint256 public governanceVoteThresholdNumerator; // Numerator for governance vote threshold (e.g., 51 for 51%)
    uint256 public governanceVoteThresholdDenominator; // Denominator for governance vote threshold (e.g., 100)
    uint256 public governanceVotingPeriod;         // Duration for voting on a governance proposal (in seconds)
    uint256 public proposalFundingDuration;        // Max time allowed for a proposal to gather initial funding (in seconds)
    uint256 public aiAnalysisRewardMultiplier;     // Multiplier for reputation rewards for AI oracles (e.g., if AI is more impactful)

    mapping(string => uint256) private governanceParameters; // Generic storage for dynamic parameters (for `getParameter` view)

    bool public paused = false; // Emergency pause switch for critical functions

    // --- 3. Events ---
    event ProposalRegistered(uint256 proposalId, address creator, string title, uint256 nftTokenId);
    event AIOracleRegistered(address oracleAddress, string name);
    event EvaluatorRegistered(address evaluatorAddress, string name);
    event SoulboundCredentialIssued(address recipient, uint256 credentialType, uint256 tokenId, string descriptionIpfsHash);
    event ProposalFunded(uint256 proposalId, address funder, uint256 amount, uint256 totalFunded);
    event FundsClaimed(uint256 proposalId, address recipient, uint256 amount);
    event EvaluationStaked(uint256 proposalId, address evaluator, uint256 amount);
    event EvaluationStakeWithdrawn(uint256 proposalId, address evaluator, uint256 amount);
    event AIAnalysisSubmitted(uint256 proposalId, address oracleAddress, string analysisIpfsHash);
    event HumanEvaluationSubmitted(uint256 proposalId, address evaluator, uint8 score, string reviewIpfsHash);
    event ReputationUpdated(address user, int256 delta, uint256 newScore);
    event ProposalStatusUpdated(uint256 proposalId, ProposalStatus newStatus);
    event GovernanceParameterProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool approved);
    event GovernanceParameterExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event OracleWhitelisted(address oracleAddress, bool isWhitelisted);
    event ContractPaused(address by);
    event ContractUnpaused(address by);

    // --- 4. Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyRegisteredEvaluator() {
        require(isHumanEvaluatorRegistered[msg.sender], "Caller is not a registered evaluator");
        // Apply minimum reputation check for evaluators
        require(userReputation[msg.sender] >= minReputationForEvaluator, "Not enough reputation to evaluate");
        _;
    }

    modifier onlyRegisteredAIOracle() {
        require(isAIOracleRegistered[msg.sender], "Caller is not a registered AI oracle");
        require(aiOracles[msg.sender].isWhitelisted, "AI Oracle not whitelisted");
        _;
    }

    // --- 5. Constructor ---
    /**
     * @dev Initializes the ERC721 (for proposals) and ERC1155 (for SBTs) contracts,
     *      sets the contract owner, and configures initial governance parameters.
     * @param _owner The address to be set as the initial owner of the contract.
     */
    constructor(address _owner) ERC721("ResearchProposalNFT", "RPN") ERC1155("https://aethel.io/sbt/{id}.json") Ownable(_owner) {
        // Initialize governance parameters
        minReputationForEvaluator = 100;
        evaluationStakeAmount = 0.1 ether;
        governanceVoteThresholdNumerator = 51;
        governanceVoteThresholdDenominator = 100;
        governanceVotingPeriod = 3 days;
        proposalFundingDuration = 30 days;
        aiAnalysisRewardMultiplier = 2;

        governanceParameters["minReputationForEvaluator"] = minReputationForEvaluator;
        governanceParameters["evaluationStakeAmount"] = evaluationStakeAmount;
        governanceParameters["governanceVoteThresholdNumerator"] = governanceVoteThresholdNumerator;
        governanceParameters["governanceVoteThresholdDenominator"] = governanceVoteThresholdDenominator;
        governanceParameters["governanceVotingPeriod"] = governanceVotingPeriod;
        governanceParameters["proposalFundingDuration"] = proposalFundingDuration;
        governanceParameters["aiAnalysisRewardMultiplier"] = aiAnalysisRewardMultiplier;
    }

    /**
     * @dev Overrides ERC1155's _beforeTokenTransfer to prevent transfers of Soulbound Tokens (SBTs).
     *      SBTs are designed to be non-transferable and are tied to a specific identity/achievement.
     *      Minting is allowed (`from == address(0)`), but transfers between users are disallowed.
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        virtual
        override(ERC1155)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        // Disallow all transfers of SBTs once they are minted.
        // Transfers are only allowed if `from` is the zero address (i.e., minting).
        require(from == address(0), "SBTs are non-transferable");
    }

    // --- 6. Core Registry & Creation Functions ---

    /**
     * @notice Registers a new research proposal and mints a unique Dynamic NFT (dNFT) for it.
     *         The dNFT's metadata will dynamically update based on the proposal's on-chain state.
     * @param _title The title of the research proposal.
     * @param _ipfsHashDetails IPFS hash pointing to the full details of the proposal (e.g., whitepaper, detailed plan).
     * @return The unique ID of the newly registered proposal.
     */
    function registerResearchProposal(
        string memory _title,
        string memory _ipfsHashDetails
    ) external whenNotPaused nonReentrant returns (uint256) {
        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        // Mint a new ERC721 NFT for the proposal. The creator initially owns it.
        _mint(msg.sender, newId);
        // The URI is set to point to a dynamic endpoint, which will serve metadata based on the proposal's state.
        _setTokenURI(newId, string(abi.encodePacked("https://aethel.io/dynamic-nft-metadata/", Strings.toString(newId))));

        proposals[newId] = ResearchProposal({
            id: Counters.toCounter(newId),
            creator: msg.sender,
            title: _title,
            ipfsHashDetails: _ipfsHashDetails,
            fundingGoal: 0, // A funding goal could be set later via a separate function or governance
            currentFunding: 0,
            status: ProposalStatus.PendingFunding,
            creationTime: block.timestamp,
            lastActivityTime: block.timestamp,
            nftTokenId: newId
        });

        emit ProposalRegistered(newId, msg.sender, _title, newId);
        return newId;
    }

    /**
     * @notice Registers an AI oracle provider. Only the contract owner can perform this.
     *         Registered oracles can submit analyses, and are whitelisted upon registration.
     * @param _name The name of the AI oracle service/provider.
     * @param _description A brief description of the oracle's capabilities and focus areas.
     * @param _oracleAddress The on-chain address (contract or EOA) of the AI oracle.
     */
    function registerAIOracle(
        string memory _name,
        string memory _description,
        address _oracleAddress
    ) external onlyOwner whenNotPaused {
        require(!isAIOracleRegistered[_oracleAddress], "AI Oracle already registered");
        aiOracles[_oracleAddress] = AIOracle({
            name: _name,
            description: _description,
            oracleAddress: _oracleAddress,
            isWhitelisted: true, // Automatically whitelisted by owner
            reputation: 0
        });
        isAIOracleRegistered[_oracleAddress] = true;
        emit AIOracleRegistered(_oracleAddress, _name);
    }

    /**
     * @notice Registers a human evaluator. Any user can register to become an evaluator.
     *         Evaluators must meet a minimum reputation threshold to submit reviews.
     * @param _name The name or alias of the evaluator.
     * @param _profileIpfsHash IPFS hash for the evaluator's public profile or qualifications.
     */
    function registerEvaluator(
        string memory _name,
        string memory _profileIpfsHash
    ) external whenNotPaused {
        require(!isHumanEvaluatorRegistered[msg.sender], "Evaluator already registered");
        humanEvaluators[msg.sender] = HumanEvaluator({
            name: _name,
            profileIpfsHash: _profileIpfsHash,
            reputation: 0,
            lastReviewTime: 0
        });
        isHumanEvaluatorRegistered[msg.sender] = true;
        emit EvaluatorRegistered(msg.sender, _name);
    }

    /**
     * @notice Issues a non-transferable Soulbound Token (SBT) credential to a recipient.
     *         This function is intended for internal or governance-controlled issuance based on achievements.
     *         Each `_credentialType` acts as a unique ERC1155 token ID, meaning a user can hold one of each type.
     * @param _recipient The address to receive the SBT.
     * @param _credentialType The type of credential to issue (e.g., `CredentialType.EvaluatorVerified`).
     * @param _descriptionIpfsHash IPFS hash for the detailed description or proof associated with this credential instance.
     */
    function issueSoulboundCredential(
        address _recipient,
        CredentialType _credentialType,
        string memory _descriptionIpfsHash
    ) external onlyOwner whenNotPaused {
        uint256 tokenId = uint256(_credentialType); // Use the enum value as the ERC1155 token ID

        // Mint the ERC1155 token. Amount is 1 as it's a unique instance per user per type.
        _mint(_recipient, tokenId, 1, "");

        userSoulboundCredentials[_recipient][tokenId] = SoulboundCredential({
            credentialId: tokenId,
            credentialType: _credentialType,
            descriptionIpfsHash: _descriptionIpfsHash,
            issueTime: block.timestamp
        });
        userSBTTokenIds[_recipient].push(tokenId); // Track which token IDs a user has

        emit SoulboundCredentialIssued(_recipient, uint256(_credentialType), tokenId, _descriptionIpfsHash);
    }

    // --- 7. Funding & Staking Functions ---

    /**
     * @notice Allows users to contribute ETH to fund a specific research proposal.
     *         Funds accumulate until claimed by the creator.
     * @param _proposalId The ID of the proposal to fund.
     */
    function fundProposal(uint256 _proposalId) external payable whenNotPaused nonReentrant {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.PendingFunding, "Proposal not in funding phase");
        require(msg.value > 0, "Funding amount must be greater than 0");
        require(block.timestamp <= proposal.creationTime + proposalFundingDuration, "Funding period has ended");

        proposal.currentFunding += msg.value;
        proposal.funders[msg.sender] = true; // Record unique funder for potential future rewards/governance
        proposal.lastActivityTime = block.timestamp;

        // Example: Update the dNFT state based on funding progress (e.g., if 100% funded)
        // This function would trigger an update to the metadata served by the dNFT's URI.
        if (proposal.fundingGoal > 0 && proposal.currentFunding >= proposal.fundingGoal) {
            updateProposalNFTState(_proposalId, uint256(ProposalStatus.Funded)); // Passed a threshold
        }

        emit ProposalFunded(_proposalId, msg.sender, msg.value, proposal.currentFunding);
    }

    /**
     * @notice Allows a proposal's creator to claim accumulated funds.
     *         Requires the proposal to be in a 'Funded' or 'Completed' status to claim.
     * @param _proposalId The ID of the proposal whose funds are to be claimed.
     */
    function claimFunds(uint256 _proposalId) external nonReentrant {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        require(msg.sender == proposal.creator, "Only proposal creator can claim funds");
        require(
            proposal.status == ProposalStatus.Funded || proposal.status == ProposalStatus.Completed,
            "Funds can only be claimed for funded or completed proposals"
        );
        require(proposal.currentFunding > 0, "No funds to claim");

        uint256 amountToClaim = proposal.currentFunding;
        proposal.currentFunding = 0; // Reset funded amount after claiming to prevent double claim

        (bool success,) = payable(proposal.creator).call{value: amountToClaim}("");
        require(success, "Failed to transfer funds to creator");

        emit FundsClaimed(_proposalId, proposal.creator, amountToClaim);
    }

    /**
     * @notice Requires evaluators to stake a specific amount of ETH before submitting a review.
     *         Ensures commitment and helps deter spam or malicious reviews.
     * @param _proposalId The ID of the proposal to evaluate.
     */
    function stakeForEvaluation(uint256 _proposalId) external payable onlyRegisteredEvaluator whenNotPaused nonReentrant {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.PendingFunding || proposal.status == ProposalStatus.Funded, "Proposal not ready for evaluation");
        require(msg.value == evaluationStakeAmount, "Incorrect stake amount required");
        require(proposal.evaluatorStakes[msg.sender] == 0, "Already staked for this proposal");

        proposal.evaluatorStakes[msg.sender] = msg.value;
        emit EvaluationStaked(_proposalId, msg.sender, msg.value);
    }

    /**
     * @notice Allows an evaluator to reclaim their staked funds.
     *         Can be withdrawn after evaluation is submitted, or if the proposal is no longer in active evaluation.
     * @param _proposalId The ID of the proposal.
     */
    function withdrawStakedEvaluationFunds(uint256 _proposalId) external nonReentrant {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        require(proposal.evaluatorStakes[msg.sender] > 0, "No stake found for this proposal");

        // Allow withdrawal if evaluation submitted OR if proposal is no longer in 'UnderEvaluation' or is 'Rejected'
        require(
            proposal.evaluatorsSubmitted[msg.sender] ||
            (proposal.status != ProposalStatus.UnderEvaluation && proposal.status != ProposalStatus.PendingFunding && proposal.status != ProposalStatus.Funded) ||
            proposal.status == ProposalStatus.Rejected,
            "Evaluation not yet submitted or proposal still under active evaluation"
        );

        uint256 amount = proposal.evaluatorStakes[msg.sender];
        proposal.evaluatorStakes[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to transfer funds");

        emit EvaluationStakeWithdrawn(_proposalId, msg.sender, amount);
    }

    // --- 8. AI Integration & Evaluation Functions ---

    /**
     * @notice An AI oracle submits its analysis for a proposal.
     *         Includes `_zkProofData` for conceptual verifiable computation, simulated here.
     * @param _proposalId The ID of the proposal being analyzed.
     * @param _oracleAddress The address of the AI oracle submitting the analysis (must match `msg.sender`).
     * @param _analysisIpfsHash IPFS hash of the analysis result (e.g., JSON output, generated report).
     * @param _zkProofData Optional ZK-proof data validating the AI computation (placeholder).
     */
    function submitAIAnalysis(
        uint256 _proposalId,
        address _oracleAddress,
        string memory _analysisIpfsHash,
        bytes memory _zkProofData
    ) external onlyRegisteredAIOracle whenNotPaused {
        require(aiOracles[_oracleAddress].oracleAddress == msg.sender, "Mismatch in oracle address for submission");
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.PendingFunding || proposal.status == ProposalStatus.Funded, "Proposal not in active phase for analysis");

        // Simulate ZK-proof verification. In a real system, this would call a dedicated verifier contract or precompile.
        // For example, if a ZK-proof attests to the correct execution of a specific AI model on given data.
        bool proofIsValid = verifyZKProof(_zkProofData, msg.sender, uint256(AnalysisType.FeasibilityCheck)); // Placeholder proof type
        require(proofIsValid, "ZK-proof verification failed for AI analysis");

        // Logic to process AI analysis and potentially update proposal status / award reputation.
        // Here, we award reputation for submitting a (conceptually) valid and verifiable analysis.
        updateReputationBasedOnContribution(msg.sender, uint256(CredentialType.AIModelApproved), 10 * int256(aiAnalysisRewardMultiplier)); // Award reputation for verifiable AI work

        emit AIAnalysisSubmitted(_proposalId, _oracleAddress, _analysisIpfsHash);
    }

    /**
     * @notice A registered human evaluator submits their score and review for a proposal.
     *         Requires a prior stake to be active.
     * @param _proposalId The ID of the proposal being evaluated.
     * @param _score The score given by the evaluator (e.g., 1-10, where 10 is excellent).
     * @param _reviewIpfsHash IPFS hash for the detailed text review or evaluation report.
     */
    function submitHumanEvaluation(
        uint256 _proposalId,
        uint8 _score,
        string memory _reviewIpfsHash
    ) external onlyRegisteredEvaluator whenNotPaused {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        require(proposal.evaluatorStakes[msg.sender] > 0, "No active stake for this evaluation from your address");
        require(!proposal.evaluatorsSubmitted[msg.sender], "Already submitted evaluation for this proposal");
        require(_score >= 1 && _score <= 10, "Score must be between 1 and 10");

        proposal.evaluatorsSubmitted[msg.sender] = true; // Mark as submitted
        humanEvaluators[msg.sender].lastReviewTime = block.timestamp;

        // Logic to process human evaluation and update proposal status / reputation.
        // Reputation awarded for active participation and submission.
        updateReputationBasedOnContribution(msg.sender, uint256(CredentialType.EvaluatorVerified), 5); // Award reputation for submitting a valid evaluation

        emit HumanEvaluationSubmitted(_proposalId, msg.sender, _score, _reviewIpfsHash);
    }

    /**
     * @notice Internal simulation of ZK-proof verification.
     *         In a real implementation, this would involve calling a precompiled contract
     *         for specific SNARK operations, or an external verifier contract (e.g., for Groth16, Plonk).
     * @dev For this demo, it simply checks if `_proofData` is not empty.
     * @param _proofData The raw ZK-proof data provided by the prover.
     * @param _prover The address of the entity that generated and provided the proof.
     * @param _proofType An identifier for the type of proof being verified (e.g., for different AI model outputs).
     * @return True if the proof is considered valid (in this demo, if `_proofData` is not empty), false otherwise.
     */
    function verifyZKProof(bytes memory _proofData, address _prover, uint256 _proofType) internal pure returns (bool) {
        // --- Placeholder for actual ZK-proof verification logic ---
        // A true ZKP verification would parse `_proofData` and `_prover` (as public inputs)
        // and execute cryptographic checks. This is highly gas-intensive and complex.
        // Example of a minimal mock check:
        // if (keccak256(_proofData) == keccak256(abi.encodePacked("a_valid_proof_for_type_", _proofType))) {
        //    return true;
        // }

        // For this demo, a simple non-empty check serves to illustrate the concept.
        return _proofData.length > 0;
    }

    /**
     * @notice Triggers a request for an AI oracle to perform a specific analysis on a proposal.
     *         This function would typically emit an event that off-chain AI oracles listen to,
     *         prompting them to perform the analysis and then submit the result via `submitAIAnalysis`.
     * @param _proposalId The ID of the proposal to be analyzed.
     * @param _oracleAddress The address of the specific AI oracle to request.
     * @param _analysisType The type of analysis requested (e.g., `AnalysisType.FeasibilityCheck`).
     */
    function requestAIAnalysis(
        uint256 _proposalId,
        address _oracleAddress,
        uint256 _analysisType
    ) external whenNotPaused {
        require(proposals[_proposalId].creator != address(0), "Proposal does not exist");
        require(isAIOracleRegistered[_oracleAddress] && aiOracles[_oracleAddress].isWhitelisted, "AI Oracle not registered or whitelisted");

        // Emit an event for off-chain oracles to pick up.
        // A more advanced system might include a payment for the request or a specific request ID for tracking.
        emit AIAnalysisSubmitted(_proposalId, _oracleAddress, string(abi.encodePacked("Request for Analysis Type: ", Strings.toString(_analysisType))));
    }

    // --- 9. Reputation & Soulbound Token (SBT) Management ---

    /**
     * @notice Returns the current aggregate reputation score of a given user.
     * @param _user The address of the user (can be an evaluator, AI oracle, or any participant).
     * @return The current reputation score of the user.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @notice Retrieves details about a specific Soulbound Token (SBT) held by a user.
     * @param _user The address of the user who holds the SBT.
     * @param _credentialId The ERC1155 token ID of the credential (corresponds to `CredentialType` enum).
     * @return The `SoulboundCredential` struct containing details about the issued SBT.
     */
    function getSoulboundCredential(address _user, uint256 _credentialId) external view returns (SoulboundCredential memory) {
        return userSoulboundCredentials[_user][_credentialId];
    }

    /**
     * @notice Internal function to adjust a user's reputation score.
     *         This function is called by other internal logic when a user performs a verifiable action
     *         that either contributes positively or negatively to the ecosystem.
     * @param _contributor The address of the user whose reputation is being updated.
     * @param _contributionType An identifier for the type of contribution (e.g., an enum value or arbitrary ID).
     * @param _delta The amount by which to change the reputation. Positive for gain, negative for loss.
     */
    function updateReputationBasedOnContribution(
        address _contributor,
        uint256 _contributionType, // Can be a CredentialType or AnalysisType for context
        int256 _delta
    ) internal {
        uint256 currentReputation = userReputation[_contributor];
        uint256 newReputation;

        if (_delta >= 0) {
            newReputation = currentReputation + uint256(_delta);
        } else {
            // Prevent underflow: reputation cannot go below zero
            if (uint256(-_delta) > currentReputation) {
                newReputation = 0;
            } else {
                newReputation = currentReputation - uint256(-_delta);
            }
        }
        userReputation[_contributor] = newReputation;
        emit ReputationUpdated(_contributor, _delta, newReputation);

        // Optionally, issue SBTs based on reputation thresholds or specific achievements
        if (_contributionType == uint256(CredentialType.EvaluatorVerified) && newReputation >= 10 && !exists(_contributor, uint256(CredentialType.EvaluatorVerified))) {
            // Check `owner()` for permissions if this is auto-issuance.
            // For simplicity, this demo implies a permission to call `issueSoulboundCredential`.
            // A production contract would have a more robust auto-issuance logic or
            // require explicit owner/governance call.
            // issueSoulboundCredential(_contributor, CredentialType.EvaluatorVerified, "Initial verified evaluator badge");
        }
    }

    // --- 10. Dynamic NFT (dNFT) Management ---

    /**
     * @notice Returns the dynamic URI for a proposal's NFT.
     *         This URI is designed to point to an off-chain API that serves mutable metadata
     *         based on the proposal's current on-chain state (e.g., funding status, evaluation progress).
     * @param _proposalId The ID of the proposal (which is also the ERC721 token ID).
     * @return The URI string for the dynamic NFT metadata.
     */
    function getProposalNFTURI(uint256 _proposalId) public view override returns (string memory) {
        require(proposals[_proposalId].creator != address(0), "Proposal does not exist");
        // The URL typically points to an API endpoint that fetches the contract's state
        // for `_proposalId` (e.g., `proposals[_proposalId].status`, `currentFunding`)
        // and dynamically generates the NFT's JSON metadata.
        return string(abi.encodePacked(
            "https://aethel.io/dynamic-nft-metadata/",
            Strings.toString(_proposalId),
            "/status/",
            Strings.toString(uint256(proposals[_proposalId].status)) // Include status in URL for dynamic metadata logic
            // More parameters can be added to the URI to influence dynamic metadata rendering
        ));
    }

    /**
     * @notice Internal function to update the on-chain state of a proposal's NFT.
     *         This does not change the `tokenURI` directly on the ERC721, but rather updates
     *         the underlying `ResearchProposal` struct fields, which the `getProposalNFTURI`
     *         endpoint uses to provide updated metadata.
     * @param _proposalId The ID of the proposal whose NFT state is to be updated.
     * @param _newState A numerical representation of the new state (e.g., funding percentage, completion stage, or direct `ProposalStatus` enum value).
     */
    function updateProposalNFTState(uint256 _proposalId, uint256 _newState) internal {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");

        // Example: Transition proposal status based on `_newState`
        // In a more complex system, _newState might map to specific milestones or funding tiers.
        if (proposal.status != ProposalStatus(_newState)) {
            proposal.status = ProposalStatus(_newState);
            proposal.lastActivityTime = block.timestamp;
            emit ProposalStatusUpdated(_proposalId, ProposalStatus(_newState));
        }
        // Further logic could be added here to trigger other events or actions based on status changes.
    }


    // --- 11. Adaptive Governance & Parameter Updates ---

    /**
     * @notice Allows authorized users (owner in this demo) to propose changes to configurable contract parameters.
     *         These proposals then go through a voting process.
     * @param _parameterName The name of the parameter to change (e.g., "minReputationForEvaluator", "evaluationStakeAmount").
     * @param _newValue The new value for the parameter.
     * @param _description A detailed description of the reason for the proposed change.
     * @return The unique ID of the newly created governance proposal.
     */
    function proposeParameterChange(
        string memory _parameterName,
        uint256 _newValue,
        string memory _description
    ) external onlyOwner whenNotPaused returns (uint256) {
        _governanceProposalIds.increment();
        uint256 newProposalId = _governanceProposalIds.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            id: Counters.toCounter(newProposalId),
            parameterName: _parameterName,
            newValue: _newValue,
            description: _description,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + governanceVotingPeriod,
            yeas: 0,
            nays: 0,
            executed: false
        });

        emit GovernanceParameterProposed(newProposalId, _parameterName, _newValue, msg.sender);
        return newProposalId;
    }

    /**
     * @notice Enables users to vote on active parameter change proposals.
     *         Vote weight is proportional to the user's `userReputation` score.
     * @param _proposalId The ID of the governance proposal to vote on.
     * @param _approve True for a 'yea' vote, false for a 'nay' vote.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _approve) external whenNotPaused {
        GovernanceProposal storage govProposal = governanceProposals[_proposalId];
        require(govProposal.creationTime != 0, "Governance proposal does not exist");
        require(block.timestamp <= govProposal.votingEndTime, "Voting period has ended");
        require(!govProposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(!govProposal.executed, "Proposal already executed");

        uint256 voteWeight = userReputation[msg.sender]; // Vote weight based on reputation
        require(voteWeight > 0, "Not enough reputation to vote (vote weight is zero)");

        if (_approve) {
            govProposal.yeas += voteWeight;
        } else {
            govProposal.nays += voteWeight;
        }
        govProposal.hasVoted[msg.sender] = true;

        emit GovernanceVoteCast(_proposalId, msg.sender, _approve);
    }

    /**
     * @notice Executes a parameter change proposal if it has passed the required vote threshold
     *         and its voting period has ended. Only the owner can trigger execution.
     * @param _proposalId The ID of the governance proposal to execute.
     */
    function executeParameterChange(uint256 _proposalId) external onlyOwner whenNotPaused {
        GovernanceProposal storage govProposal = governanceProposals[_proposalId];
        require(govProposal.creationTime != 0, "Governance proposal does not exist");
        require(block.timestamp > govProposal.votingEndTime, "Voting period has not ended");
        require(!govProposal.executed, "Proposal already executed");

        uint256 totalVotes = govProposal.yeas + govProposal.nays;
        require(totalVotes > 0, "No votes cast for this proposal");

        // Calculate required 'yea' votes based on total votes and threshold
        uint256 requiredYeas = (totalVotes * governanceVoteThresholdNumerator) / governanceVoteThresholdDenominator;
        require(govProposal.yeas >= requiredYeas, "Proposal did not pass required 'yea' threshold");

        // Apply the parameter change based on its name
        // Using keccak256 for string comparison is gas-efficient.
        bytes32 paramHash = keccak256(abi.encodePacked(govProposal.parameterName));

        if (paramHash == keccak256(abi.encodePacked("minReputationForEvaluator"))) {
            minReputationForEvaluator = govProposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("evaluationStakeAmount"))) {
            evaluationStakeAmount = govProposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("governanceVoteThresholdNumerator"))) {
            governanceVoteThresholdNumerator = govProposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("governanceVoteThresholdDenominator"))) {
            governanceVoteThresholdDenominator = govProposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("governanceVotingPeriod"))) {
            governanceVotingPeriod = govProposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("proposalFundingDuration"))) {
            proposalFundingDuration = govProposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("aiAnalysisRewardMultiplier"))) {
            aiAnalysisRewardMultiplier = govProposal.newValue;
        } else {
            revert("Unknown parameter name for execution");
        }
        
        // Update the generic parameters map as well for consistent viewing
        governanceParameters[govProposal.parameterName] = govProposal.newValue;

        govProposal.executed = true; // Mark proposal as executed
        emit GovernanceParameterExecuted(_proposalId, govProposal.parameterName, govProposal.newValue);
    }

    /**
     * @notice Governance function to add or remove AI oracles from the whitelist.
     *         Only whitelisted oracles are allowed to submit verifiable analyses.
     * @param _oracleAddress The address of the AI oracle to update.
     * @param _isWhitelisted True to whitelist the oracle, false to delist it.
     */
    function updateOracleWhitelist(address _oracleAddress, bool _isWhitelisted) external onlyOwner whenNotPaused {
        require(isAIOracleRegistered[_oracleAddress], "AI Oracle not registered");
        aiOracles[_oracleAddress].isWhitelisted = _isWhitelisted;
        emit OracleWhitelisted(_oracleAddress, _isWhitelisted);
    }

    /**
     * @notice Allows the owner to pause critical contract functions in an emergency.
     *         This can prevent malicious activity or allow for upgrades.
     */
    function emergencyPause() external onlyOwner {
        require(!paused, "Contract already paused");
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Allows the owner to unpause the contract after an emergency or maintenance.
     */
    function unpause() external onlyOwner {
        require(paused, "Contract not paused");
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Sets the minimum reputation score required for users to become evaluators or participate in certain evaluation tasks.
     *         While this can be set directly by the owner for flexibility, it's ideally updated via a governance proposal.
     * @param _minReputation The new minimum reputation score.
     */
    function setMinEvaluationReputation(uint256 _minReputation) external onlyOwner whenNotPaused {
        minReputationForEvaluator = _minReputation;
        governanceParameters["minReputationForEvaluator"] = _minReputation;
        emit GovernanceParameterExecuted(0, "minReputationForEvaluator", _minReputation); // Using 0 for direct owner changes
    }


    // --- 12. Utility & View Functions ---

    /**
     * @notice Retrieves comprehensive details about a specific research proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all relevant details of the proposal.
     */
    function getProposalDetails(
        uint256 _proposalId
    ) external view returns (
        uint256 id,
        address creator,
        string memory title,
        string memory ipfsHashDetails,
        uint256 fundingGoal,
        uint256 currentFunding,
        ProposalStatus status,
        uint256 creationTime,
        uint256 lastActivityTime,
        uint256 nftTokenId
    ) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        return (
            proposal.id.current(),
            proposal.creator,
            proposal.title,
            proposal.ipfsHashDetails,
            proposal.fundingGoal,
            proposal.currentFunding,
            proposal.status,
            proposal.creationTime,
            proposal.lastActivityTime,
            proposal.nftTokenId
        );
    }

    /**
     * @notice Fetches the registered details of an AI oracle.
     * @param _oracleAddress The address of the AI oracle.
     * @return A tuple containing the oracle's name, description, address, whitelist status, and reputation.
     */
    function getOracleDetails(
        address _oracleAddress
    ) external view returns (
        string memory name,
        string memory description,
        address oracleAddress,
        bool isWhitelisted,
        uint256 reputation
    ) {
        require(isAIOracleRegistered[_oracleAddress], "AI Oracle not registered");
        AIOracle storage oracle = aiOracles[_oracleAddress];
        return (
            oracle.name,
            oracle.description,
            oracle.oracleAddress,
            oracle.isWhitelisted,
            oracle.reputation
        );
    }

    /**
     * @notice A general view function to retrieve the current value of any configurable governance parameter.
     * @param _parameterName The name of the parameter (e.g., "minReputationForEvaluator").
     * @return The current `uint256` value of the specified parameter.
     */
    function getParameter(string memory _parameterName) external view returns (uint256) {
        return governanceParameters[_parameterName];
    }
}
```