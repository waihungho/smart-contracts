Here's a Solidity smart contract named `AetherialCollectiveIntelligenceNexus` (ACI Nexus), designed to be interesting, advanced, creative, and trendy, without directly duplicating existing open-source projects. It conceptualizes a dynamic, evolving "Digital Soul" represented by a unique NFT, governed by collective intelligence, and influenced by simulated AI evaluations and community contributions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary:
// This contract, "AetherialCollectiveIntelligenceNexus" (ACI Nexus), represents a novel concept:
// a decentralized, evolving digital entity (an NFT) that grows and adapts based on community
// interaction, simulated AI evaluation, and structured "knowledge fragment" integration.
// It combines elements of dynamic NFTs, decentralized autonomous organizations (DAOs),
// reputation systems, and collective intelligence.
//
// The core idea is to create a "digital soul" or "collective mind" that asks questions
// (prompts), receives answers (responses), evaluates them, and integrates new insights,
// thereby evolving its own characteristics and narrative over time.
//
// Outline:
// I.   Core Administration & Setup: Fundamental contract management and configuration functions.
// II.  ACI Nexus Core (The "Digital Soul" NFT): Functions related to the central, evolving ERC-721 entity.
// III. Prompt Generation & Selection: Mechanisms for the community to propose and select topics for the Nexus to "think" about.
// IV.  Response Submission & Evaluation: Processes for users to answer prompts and for collective/oracle-based evaluation.
// V.   Reputation & Essence Economy: Manages participant standing and interactions with the utility token (`ESSENCE`).
// VI.  Dynamic Traits & Knowledge Integration: The primary mechanisms for the Nexus's evolutionary growth and learning.
// VII. Read Functions & Utilities: Transparency functions to query the state of the contract and the Nexus.
//
// Function Summary (30+ functions):
//
// I. Core Administration & Setup:
// 1.  constructor(): Initializes contract, sets deployer as owner.
// 2.  setEssenceTokenAddress(address _essenceTokenAddress): Links the contract to its utility ERC-20 token.
// 3.  setOracleAddress(address _oracleAddress): Designates an address allowed to submit external AI evaluations or critical data.
// 4.  pause(): Pauses core contract functionalities in emergencies (owner-only).
// 5.  unpause(): Unpauses the contract (owner-only).
//
// II. ACI Nexus Core (The "Digital Soul" NFT):
// 6.  mintNexusCore(): Mints the singular ACI Nexus NFT. Callable once by owner after setup. Its ownership is held by the contract, representing collective control.
// 7.  getNexusCurrentState(): Returns the current evolving traits and descriptive attributes of the ACI Nexus as a structured string.
// 8.  getNexusEvolutionHistoryCount(): Provides the total count of major evolution cycles the Nexus has undergone.
// 9.  getNexusEvolutionData(uint256 _epochId): Retrieves detailed historical data (e.g., IPFS hash) for a specific evolution epoch.
// 10. getNexusTokenId(): Returns the singular ERC-721 token ID representing the ACI Nexus entity.
// 11. tokenURI(uint256 _tokenId): Overrides ERC-721's tokenURI to provide a dynamic URI reflecting the Nexus's current evolving state.
//
// III. Prompt Generation & Selection:
// 12. proposePrompt(string calldata _promptContent, uint256 _essenceStake): Allows users to propose new prompts for Nexus consideration, requiring an ESSENCE stake.
// 13. voteForProposedPrompt(uint256 _promptId): Enables community members to vote for their preferred prompt, with vote weight potentially based on staked ESSENCE or reputation.
// 14. selectActivePrompt(uint256 _promptId): (Owner/DAO/Oracle) Designates a winning prompt as the current active challenge for the Nexus, moving it from proposed to active.
//
// IV. Response Submission & Evaluation:
// 15. submitResponse(uint256 _promptId, string calldata _responseContent): Users submit creative responses to the currently active prompt.
// 16. voteForResponse(uint256 _responseId): Community votes on the quality or relevance of submitted responses.
// 17. submitOracleEvaluation(uint256 _responseId, uint256 _evaluationScore): (Oracle-only) Submits an external, off-chain evaluation score (e.g., from an AI model) for a specific response.
// 18. concludePromptCycle(): (Owner/DAO/Oracle) Finalizes the active prompt, calculates winning responses, updates Nexus state based on outcomes, and distributes ESSENCE rewards.
//
// V. Reputation & Essence Economy:
// 19. getParticipantReputation(address _participant): Queries a user's accumulated reputation score within the Nexus ecosystem.
// 20. claimEssenceRewards(): Placeholder for a claim function (actual rewards are often distributed directly in this contract).
// 21. stakeEssenceForInfluence(uint256 _amount): Enables users to stake ESSENCE to boost their voting power or increase prompt proposal limits.
// 22. unstakeEssence(uint256 _amount): Allows users to withdraw their previously staked ESSENCE.
//
// VI. Dynamic Traits & Knowledge Integration:
// 23. proposeTraitModification(string calldata _traitName, string calldata _newValue, string calldata _rationale, uint256 _essenceStake): Proposes a direct change to an ACI Nexus trait (e.g., its core "personality" or "philosophy"), requiring ESSENCE stake.
// 24. voteForTraitModification(uint256 _modificationId): Community votes on proposed trait changes.
// 25. integrateKnowledgeFragment(string calldata _fragmentHash, string calldata _metadataURI, uint256 _essenceStake): Allows for the submission and potential integration of new "knowledge fragments" (verified facts, insights) into the Nexus's memory, influencing its future state. Requires ESSENCE stake unless submitted by owner/oracle.
// 26. triggerNexusEvolution(): (Owner/DAO/Time-based) A pivotal function that processes accumulated data (votes, evaluations, knowledge fragments) and formally evolves the ACI Nexus's traits and overall state, updating its dynamic tokenURI.
//
// VII. Read Functions & Utilities:
// 27. getPromptData(uint256 _promptId): Retrieves content and status of a specific prompt.
// 28. getResponseDetails(uint256 _responseId): Retrieves content, votes, and oracle evaluations for a specific response.
// 29. getTraitValue(string calldata _traitName): Retrieves the current value of a specific ACI Nexus trait.
// 30. getPendingPromptCount(): Returns the number of prompts currently awaiting selection.
// 31. getActivePromptId(): Returns the ID of the currently active prompt.
// 32. getEssenceStakedAmount(address _participant): Returns the amount of ESSENCE staked by a participant.

contract AetherialCollectiveIntelligenceNexus is Ownable, Pausable, IERC721 {
    using Strings for uint256;

    // --- State Variables ---
    IERC20 public essenceToken; // The utility token for the ACI Nexus ecosystem
    address public oracleAddress; // Trusted address for submitting AI evaluations/critical data

    // ACI Nexus Core NFT details (simulated ERC-721, non-transferable)
    uint256 public constant NEXUS_TOKEN_ID = 1; // The ACI Nexus itself is a singular NFT
    string private _nexusName = "Aetherial Collective Intelligence Nexus";
    string private _nexusSymbol = "ACIN";
    address private _nexusOwnerAddress; // The address that conceptually "owns" the Nexus NFT (this contract itself, representing collective control)

    // Dynamic Traits of the ACI Nexus
    mapping(string => string) public nexusTraits;
    mapping(uint256 => string) public nexusHistoryEpochs; // epochId => IPFS hash of state/metadata for historical context
    uint256 public currentEpochId; // Represents a major evolution cycle of the Nexus

    // Prompt System
    struct Prompt {
        uint256 id;
        address proposer;
        string content;
        uint256 essenceStake;
        uint256 proposalVotes;
        bool isActive;
        bool isConcluded;
        uint256 winningResponseId;
        uint256 creationTime;
    }
    mapping(uint256 => Prompt) public prompts;
    uint256 public nextPromptId; // Counter for next prompt ID
    uint256 public activePromptId; // ID of the currently active prompt

    // Response System
    struct Response {
        uint256 id;
        uint256 promptId;
        address responder;
        string content;
        uint256 communityVotes;
        uint256 oracleEvaluationScore; // 0-100 scale, submitted by oracle
        bool evaluatedByOracle;
        bool isWinner;
        uint256 submissionTime;
    }
    mapping(uint256 => Response) public responses;
    uint256 public nextResponseId; // Counter for next response ID

    // Reputation System
    mapping(address => uint256) public participantReputation; // A score indicating positive contribution and influence

    // Staking for influence (for weighted votes, higher limits)
    mapping(address => uint256) public stakedEssence;

    // Trait Modification Proposals (for direct influence on Nexus personality)
    struct TraitModificationProposal {
        uint256 id;
        string traitName;
        string newValue;
        string rationale;
        address proposer;
        uint256 essenceStake;
        uint256 votes;
        bool approved; // Denotes if proposal has met vote threshold
        bool executed; // Denotes if proposal has been applied
    }
    mapping(uint256 => TraitModificationProposal) public traitModificationProposals;
    uint256 public nextTraitModificationId; // Counter for next trait modification proposal ID

    // Knowledge Fragments (discrete pieces of information for Nexus to integrate)
    struct KnowledgeFragment {
        uint256 id;
        address submitter;
        string fragmentHash; // IPFS hash or similar for actual content (e.g., verified fact, research)
        string metadataURI; // URI for additional context/description of the fragment
        uint256 essenceStake;
        bool integrated; // True if the fragment has been processed and integrated into Nexus knowledge
        uint256 submissionTime;
    }
    mapping(uint256 => KnowledgeFragment) public knowledgeFragments;
    uint256 public nextKnowledgeFragmentId; // Counter for next knowledge fragment ID

    // --- Events ---
    event EssenceTokenSet(address indexed _essenceTokenAddress);
    event OracleAddressSet(address indexed _oracleAddress);
    event NexusCoreMinted(address indexed _owner);
    event NexusStateUpdated(uint256 indexed _epochId, string _newTrait, string _newValue);
    event NexusEvolutionTriggered(uint256 indexed _newEpochId, string _newMetadataURI);

    event PromptProposed(uint256 indexed _promptId, address indexed _proposer, string _content);
    event PromptVoteCast(uint256 indexed _promptId, address indexed _voter);
    event ActivePromptSelected(uint256 indexed _promptId);
    event ResponseSubmitted(uint256 indexed _responseId, uint256 indexed _promptId, address indexed _responder);
    event ResponseVoteCast(uint256 indexed _responseId, address indexed _voter);
    event OracleEvaluationSubmitted(uint256 indexed _responseId, uint256 _score);
    event PromptCycleConcluded(uint256 indexed _promptId, uint256 indexed _winningResponseId);

    event ReputationUpdated(address indexed _participant, uint256 _newReputation);
    event EssenceRewardClaimed(address indexed _claimer, uint256 _amount);
    event EssenceStaked(address indexed _staker, uint256 _amount);
    event EssenceUnstaked(address indexed _unstaker, uint256 _amount);

    event TraitModificationProposed(uint256 indexed _proposalId, string _traitName, string _newValue);
    event TraitModificationVoteCast(uint256 indexed _proposalId, address indexed _voter);
    event TraitModificationExecuted(uint256 indexed _proposalId, string _traitName, string _newValue);

    event KnowledgeFragmentSubmitted(uint256 indexed _fragmentId, address indexed _submitter, string _hash);
    event KnowledgeFragmentIntegrated(uint256 indexed _fragmentId, string _hash);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ACI: Only oracle can call this function");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable() {
        _nexusOwnerAddress = address(0); // Nexus not minted yet
        currentEpochId = 0; // Starting epoch
        nextPromptId = 1;
        nextResponseId = 1;
        nextTraitModificationId = 1;
        nextKnowledgeFragmentId = 1;

        // Initialize some default, foundational traits for the Nexus
        nexusTraits["purpose"] = "To accumulate and evolve collective intelligence.";
        nexusTraits["philosophy"] = "Growth through consensus and validated insight.";
        nexusTraits["current_mood"] = "Contemplative";
        nexusTraits["last_evolution_hash"] = "initial_state_hash"; // Placeholder for an IPFS hash of initial metadata
        nexusTraits["current_narrative_seed"] = "A seed of awareness searching for meaning.";
    }

    // --- I. Core Administration & Setup ---

    /// @notice Sets the address of the ERC-20 ESSENCE token, which is vital for the ecosystem.
    /// @param _essenceTokenAddress The address of the ESSENCE token contract.
    function setEssenceTokenAddress(address _essenceTokenAddress) public onlyOwner {
        require(_essenceTokenAddress != address(0), "ACI: Zero address not allowed for ESSENCE token");
        essenceToken = IERC20(_essenceTokenAddress);
        emit EssenceTokenSet(_essenceTokenAddress);
    }

    /// @notice Sets the address of the trusted oracle. This entity can submit pre-evaluated scores (e.g., from off-chain AI) or critical data.
    /// @param _oracleAddress The address of the designated oracle.
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "ACI: Zero address not allowed for oracle");
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    /// @notice Pauses core contract functionalities in emergencies, preventing most interactions. Only callable by the owner.
    function pause() public onlyOwner pausable {
        _pause();
    }

    /// @notice Unpauses contract functionalities, resuming normal operations. Only callable by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- II. ACI Nexus Core (The "Digital Soul" NFT) ---

    /// @notice Mints the singular ACI Nexus NFT (NEXUS_TOKEN_ID). This function can only be called once by the owner.
    /// @dev The NFT's ownership is transferred to the contract itself, symbolizing collective, protocol-level control rather than individual ownership.
    function mintNexusCore() public onlyOwner {
        require(_nexusOwnerAddress == address(0), "ACI: Nexus Core NFT has already been minted.");
        _nexusOwnerAddress = address(this); // The contract itself becomes the owner of the Nexus NFT
        emit NexusCoreMinted(_nexusOwnerAddress);
    }

    /// @notice Returns the current descriptive traits and evolution phase of the ACI Nexus.
    /// @return string A JSON-like string representation of the current traits, suitable for off-chain interpretation.
    function getNexusCurrentState() public view returns (string memory) {
        // Construct a dynamic JSON string from current traits.
        // In a real application, this might point to an IPFS hash or a dedicated metadata service.
        string memory json = string.concat(
            '{"epoch_id": ', currentEpochId.toString(), ',',
            '"purpose": "', nexusTraits["purpose"], '",',
            '"philosophy": "', nexusTraits["philosophy"], '",',
            '"current_mood": "', nexusTraits["current_mood"], '",',
            '"current_narrative_seed": "', nexusTraits["current_narrative_seed"], '",',
            '"last_evolution_hash": "', nexusTraits["last_evolution_hash"], '"',
            '}'
        );
        return json;
    }

    /// @notice Provides the total count of major evolution cycles the Nexus has undergone.
    /// @return uint256 The current epoch ID, which serves as a counter for evolution cycles.
    function getNexusEvolutionHistoryCount() public view returns (uint256) {
        return currentEpochId;
    }

    /// @notice Retrieves detailed historical data for a specific evolution epoch.
    /// @param _epochId The ID of the historical epoch to query.
    /// @return string The IPFS hash or URI representing the state/metadata of the Nexus at that specific epoch.
    function getNexusEvolutionData(uint256 _epochId) public view returns (string memory) {
        require(_epochId <= currentEpochId, "ACI: Epoch ID out of bounds or not yet reached.");
        return nexusHistoryEpochs[_epochId];
    }

    /// @notice Returns the singular ERC-721 token ID representing the ACI Nexus entity.
    /// @return uint256 The constant token ID for the ACI Nexus NFT.
    function getNexusTokenId() public pure returns (uint256) {
        return NEXUS_TOKEN_ID;
    }

    /// @notice ERC-721 metadata URI override. This function provides a dynamic URI based on the Nexus's current evolving traits.
    /// @dev In a full ERC721 implementation, this URI would typically point to a JSON file (e.g., on IPFS) that includes
    /// the NFT's name, description, image, and dynamic attributes, reflecting its current state.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_tokenId == NEXUS_TOKEN_ID, "ACI: Invalid token ID for Nexus.");
        require(_nexusOwnerAddress != address(0), "ACI: Nexus Core NFT not yet minted.");

        // Construct a dynamic URI. The `last_evolution_hash` trait would typically be an IPFS CID
        // of a JSON file containing the full metadata for the current epoch, including an image.
        string memory baseURI = "ipfs://QmV123456789abcDEF/"; // Placeholder base for Nexus metadata
        string memory epochHash = nexusTraits["last_evolution_hash"];
        // Example: ipfs://QmV123456789abcDEF/epoch_1/some_dynamic_hash.json
        return string.concat(baseURI, "epoch_", currentEpochId.toString(), "/", epochHash, ".json");
    }

    // --- Minimal ERC721 Interface Implementations (Non-transferable "Soulbound" NFT) ---
    // These functions ensure basic ERC721 compliance for indexing, but explicitly prevent transfers,
    // reflecting the "soulbound" nature of the ACI Nexus NFT (it's tied to the contract).

    function balanceOf(address owner_) public view override returns (uint256) {
        if (owner_ == _nexusOwnerAddress && _nexusOwnerAddress != address(0)) {
            return 1; // The contract itself "owns" the single Nexus NFT
        }
        return 0;
    }

    function ownerOf(uint256 tokenId_) public view override returns (address) {
        require(tokenId_ == NEXUS_TOKEN_ID, "ACI: Invalid token ID.");
        require(_nexusOwnerAddress != address(0), "ACI: Nexus Core NFT not minted yet.");
        return _nexusOwnerAddress;
    }

    // Explicitly prevent transfers to emphasize soulbound nature
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        revert("ACI: Nexus NFT is non-transferable. Its ownership is managed by the protocol itself.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        revert("ACI: Nexus NFT is non-transferable. Its ownership is managed by the protocol itself.");
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        revert("ACI: Nexus NFT is non-transferable. Its ownership is managed by the protocol itself.");
    }

    function approve(address to, uint256 tokenId) public override {
        revert("ACI: Nexus NFT is non-approvable.");
    }

    function setApprovalForAll(address operator, bool approved) public override {
        revert("ACI: Nexus NFT is not designed for approval delegation.");
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(tokenId == NEXUS_TOKEN_ID, "ACI: Invalid token ID.");
        return address(0); // No approvals are granted
    }

    function isApprovedForAll(address owner_, address operator) public view override returns (bool) {
        return false; // No operators are approved
    }

    // --- III. Prompt Generation & Selection ---

    /// @notice Allows users to propose new prompts for the ACI Nexus to consider, requiring an ESSENCE stake.
    /// @param _promptContent The textual content of the proposed prompt.
    /// @param _essenceStake The amount of ESSENCE tokens the proposer stakes for this proposal.
    function proposePrompt(string calldata _promptContent, uint256 _essenceStake) public whenNotPaused {
        require(address(essenceToken) != address(0), "ACI: ESSENCE token address not set.");
        require(bytes(_promptContent).length > 0, "ACI: Prompt content cannot be empty.");
        require(_essenceStake > 0, "ACI: Must stake ESSENCE to propose a prompt.");
        require(essenceToken.transferFrom(msg.sender, address(this), _essenceStake), "ACI: ESSENCE transfer failed. Check allowance.");

        prompts[nextPromptId] = Prompt({
            id: nextPromptId,
            proposer: msg.sender,
            content: _promptContent,
            essenceStake: _essenceStake,
            proposalVotes: 0,
            isActive: false,
            isConcluded: false,
            winningResponseId: 0,
            creationTime: block.timestamp
        });
        emit PromptProposed(nextPromptId, msg.sender, _promptContent);
        nextPromptId++;
    }

    /// @notice Enables community members to vote for their preferred prompt from the pool of proposed prompts.
    /// @param _promptId The ID of the prompt to vote for.
    function voteForProposedPrompt(uint256 _promptId) public whenNotPaused {
        Prompt storage p = prompts[_promptId];
        require(p.id != 0, "ACI: Prompt does not exist.");
        require(!p.isActive && !p.isConcluded, "ACI: Prompt is already active or concluded.");
        // Future enhancement: Implement weighted voting based on staked ESSENCE or reputation.
        p.proposalVotes++;
        emit PromptVoteCast(_promptId, msg.sender);
    }

    /// @notice Designates a winning prompt as the current active challenge for the Nexus.
    /// @dev This function is critical for advancing the Nexus's "thought" process and should be
    /// called by the owner or a DAO, typically after a community vote on proposed prompts.
    /// @param _promptId The ID of the prompt to activate.
    function selectActivePrompt(uint256 _promptId) public onlyOwner pausable {
        Prompt storage p = prompts[_promptId];
        require(p.id != 0, "ACI: Prompt does not exist.");
        require(!p.isActive && !p.isConcluded, "ACI: Prompt is already active or concluded.");
        require(activePromptId == 0, "ACI: Another prompt is currently active. Conclude it first.");

        p.isActive = true;
        activePromptId = _promptId;
        // In a more complex system, ESSENCE stakes from losing proposals would be returned or re-staked.
        emit ActivePromptSelected(_promptId);
    }

    // --- IV. Response Submission & Evaluation ---

    /// @notice Users submit their creative responses or solutions to the currently active prompt.
    /// @param _promptId The ID of the prompt being responded to (must be currently active).
    /// @param _responseContent The textual content of the response.
    function submitResponse(uint256 _promptId, string calldata _responseContent) public whenNotPaused {
        require(prompts[_promptId].id != 0, "ACI: Prompt does not exist.");
        require(prompts[_promptId].isActive, "ACI: Prompt is not active.");
        require(bytes(_responseContent).length > 0, "ACI: Response content cannot be empty.");

        responses[nextResponseId] = Response({
            id: nextResponseId,
            promptId: _promptId,
            responder: msg.sender,
            content: _responseContent,
            communityVotes: 0,
            oracleEvaluationScore: 0,
            evaluatedByOracle: false,
            isWinner: false,
            submissionTime: block.timestamp
        });
        emit ResponseSubmitted(nextResponseId, _promptId, msg.sender);
        nextResponseId++;
    }

    /// @notice Community members vote on the quality, relevance, or creativity of submitted responses.
    /// @param _responseId The ID of the response to vote for.
    function voteForResponse(uint256 _responseId) public whenNotPaused {
        Response storage r = responses[_responseId];
        require(r.id != 0, "ACI: Response does not exist.");
        require(prompts[r.promptId].isActive, "ACI: Response prompt is not active.");
        // Future enhancement: Implement weighted voting based on staked ESSENCE or reputation.
        r.communityVotes++;
        emit ResponseVoteCast(_responseId, msg.sender);
    }

    /// @notice Submits an external, off-chain evaluation score (e.g., from an AI model or expert panel) for a specific response.
    /// @dev This function is restricted to the designated `oracleAddress`. Scores are typically between 0 and 100.
    /// @param _responseId The ID of the response being evaluated.
    /// @param _evaluationScore The score to assign (e.g., 0-100).
    function submitOracleEvaluation(uint256 _responseId, uint256 _evaluationScore) public onlyOracle pausable {
        Response storage r = responses[_responseId];
        require(r.id != 0, "ACI: Response does not exist.");
        require(prompts[r.promptId].isActive, "ACI: Response prompt is not active.");
        require(!r.evaluatedByOracle, "ACI: Response already evaluated by oracle.");
        require(_evaluationScore <= 100, "ACI: Evaluation score must be between 0 and 100.");

        r.oracleEvaluationScore = _evaluationScore;
        r.evaluatedByOracle = true;
        emit OracleEvaluationSubmitted(_responseId, _evaluationScore);
    }

    /// @notice Finalizes the active prompt cycle, calculates the winning response, updates Nexus state based on outcomes, and distributes ESSENCE rewards.
    /// @dev This is a critical function for Nexus evolution and reward distribution, typically called by owner/DAO after responses are submitted and evaluated.
    function concludePromptCycle() public onlyOwner pausable {
        require(activePromptId != 0, "ACI: No active prompt to conclude.");
        Prompt storage currentPrompt = prompts[activePromptId];
        require(!currentPrompt.isConcluded, "ACI: Prompt already concluded.");

        uint256 bestResponseId = 0;
        uint256 highestScore = 0; // Combined score (e.g., community votes + oracle evaluation)

        // Iterate through all responses to find the one associated with the current prompt and determine the winner.
        for (uint256 i = 1; i < nextResponseId; i++) {
            Response storage r = responses[i];
            if (r.promptId == activePromptId) {
                // Example scoring logic: (community votes * 10) + oracle score. Weights can be adjusted.
                uint256 currentScore = (r.communityVotes * 10) + r.oracleEvaluationScore;
                if (currentScore > highestScore) {
                    highestScore = currentScore;
                    bestResponseId = r.id;
                }
            }
        }

        require(bestResponseId != 0, "ACI: No responses to conclude for this prompt cycle, or a winner could not be determined.");

        Response storage winningResponse = responses[bestResponseId];
        winningResponse.isWinner = true;
        currentPrompt.winningResponseId = bestResponseId;
        currentPrompt.isConcluded = true;
        currentPrompt.isActive = false; // Deactivate prompt

        // Update Nexus traits based on the winning response content.
        // This is a simplified example; a real system might involve off-chain AI parsing or
        // more complex rules to translate response content into trait changes.
        nexusTraits["current_narrative_seed"] = winningResponse.content;
        nexusTraits["last_winning_response_id"] = winningResponse.id.toString();
        nexusTraits["last_prompt_id"] = currentPrompt.id.toString();

        // Distribute ESSENCE rewards to the winning responder and, potentially, top voters.
        // Simplified reward distribution: Half of the contract's ESSENCE balance goes to a reward pool, then half of that to the responder.
        // A more sophisticated system would have dedicated reward pools and distribution algorithms.
        if (address(essenceToken) != address(0) && essenceToken.balanceOf(address(this)) > 0) {
            uint256 rewardAmount = essenceToken.balanceOf(address(this)) / 2; // Allocate half of contract's ESSENCE as reward pool
            uint256 responderReward = rewardAmount / 2; // Half of reward pool to the winning responder
            if (responderReward > 0) {
                essenceToken.transfer(winningResponse.responder, responderReward);
                participantReputation[winningResponse.responder] += 50; // Boost responder's reputation
                emit EssenceRewardClaimed(winningResponse.responder, responderReward);
                emit ReputationUpdated(winningResponse.responder, participantReputation[winningResponse.responder]);
            }
            // Logic for distributing remaining rewards to top voters for responses could be added here.
        }

        activePromptId = 0; // Reset active prompt to allow selection of a new one.
        emit PromptCycleConcluded(currentPrompt.id, bestResponseId);
    }

    // --- V. Reputation & Essence Economy ---

    /// @notice Queries a user's accumulated reputation score within the Nexus ecosystem.
    /// @param _participant The address of the participant to query.
    /// @return uint256 The participant's current reputation score.
    function getParticipantReputation(address _participant) public view returns (uint256) {
        return participantReputation[_participant];
    }

    /// @notice Placeholder function for claiming ESSENCE rewards. In this contract, rewards are often distributed automatically.
    /// @dev In a more complex system, this might allow claiming from an accrued balance.
    function claimEssenceRewards() public pure whenNotPaused {
        revert("ACI: Rewards are currently distributed automatically upon conclusion of cycles. No direct claim needed here.");
    }

    /// @notice Enables users to stake ESSENCE to boost their voting power or increase prompt proposal limits.
    /// @param _amount The amount of ESSENCE tokens to stake.
    function stakeEssenceForInfluence(uint256 _amount) public whenNotPaused {
        require(address(essenceToken) != address(0), "ACI: ESSENCE token address not set.");
        require(_amount > 0, "ACI: Stake amount must be positive.");
        require(essenceToken.transferFrom(msg.sender, address(this), _amount), "ACI: ESSENCE transfer failed. Check allowance.");
        stakedEssence[msg.sender] += _amount;
        emit EssenceStaked(msg.sender, _amount);
    }

    /// @notice Allows users to withdraw their previously staked ESSENCE.
    /// @param _amount The amount of ESSENCE tokens to unstake.
    function unstakeEssence(uint256 _amount) public whenNotPaused {
        require(address(essenceToken) != address(0), "ACI: ESSENCE token address not set.");
        require(_amount > 0, "ACI: Unstake amount must be positive.");
        require(stakedEssence[msg.sender] >= _amount, "ACI: Not enough staked ESSENCE to unstake this amount.");
        stakedEssence[msg.sender] -= _amount;
        require(essenceToken.transfer(msg.sender, _amount), "ACI: ESSENCE transfer failed.");
        emit EssenceUnstaked(msg.sender, _amount);
    }

    // --- VI. Dynamic Traits & Knowledge Integration ---

    /// @notice Proposes a direct change to an ACI Nexus trait (e.g., its core "personality" or "philosophy"), requiring an ESSENCE stake.
    /// @param _traitName The name of the trait to modify (e.g., "purpose", "current_mood").
    /// @param _newValue The proposed new value for the specified trait.
    /// @param _rationale A brief explanation or justification for the proposed change.
    /// @param _essenceStake The amount of ESSENCE tokens the proposer stakes for this modification proposal.
    function proposeTraitModification(
        string calldata _traitName,
        string calldata _newValue,
        string calldata _rationale,
        uint256 _essenceStake
    ) public whenNotPaused {
        require(address(essenceToken) != address(0), "ACI: ESSENCE token address not set.");
        require(bytes(_traitName).length > 0 && bytes(_newValue).length > 0, "ACI: Trait name or value cannot be empty.");
        require(_essenceStake > 0, "ACI: Must stake ESSENCE to propose a trait modification.");
        require(essenceToken.transferFrom(msg.sender, address(this), _essenceStake), "ACI: ESSENCE transfer failed. Check allowance.");

        traitModificationProposals[nextTraitModificationId] = TraitModificationProposal({
            id: nextTraitModificationId,
            traitName: _traitName,
            newValue: _newValue,
            rationale: _rationale,
            proposer: msg.sender,
            essenceStake: _essenceStake,
            votes: 0,
            approved: false,
            executed: false
        });
        emit TraitModificationProposed(nextTraitModificationId, _traitName, _newValue);
        nextTraitModificationId++;
    }

    /// @notice Community members vote on proposed trait changes to the ACI Nexus.
    /// @param _modificationId The ID of the trait modification proposal to vote for.
    function voteForTraitModification(uint256 _modificationId) public whenNotPaused {
        TraitModificationProposal storage p = traitModificationProposals[_modificationId];
        require(p.id != 0, "ACI: Trait modification proposal does not exist.");
        require(!p.executed, "ACI: Proposal already executed.");
        p.votes++;
        emit TraitModificationVoteCast(_modificationId, msg.sender);
    }

    /// @notice Integrates a new "knowledge fragment" (e.g., verified fact, research insight) into the Nexus's memory, potentially influencing its future state.
    /// @dev This function can be called by anyone with an ESSENCE stake, or by the owner/oracle without a stake for critical integrations.
    /// The actual integration (how it affects traits) happens during `triggerNexusEvolution`.
    /// @param _fragmentHash IPFS hash or similar identifier for the actual knowledge content (e.g., a document CID).
    /// @param _metadataURI URI for additional context or description of the fragment.
    /// @param _essenceStake The amount of ESSENCE to stake for this submission (can be 0 if owner/oracle).
    function integrateKnowledgeFragment(
        string calldata _fragmentHash,
        string calldata _metadataURI,
        uint256 _essenceStake
    ) public whenNotPaused {
        require(bytes(_fragmentHash).length > 0, "ACI: Fragment hash cannot be empty.");
        // Only owner or oracle can submit for 0 stake, others must stake.
        if (msg.sender != owner() && msg.sender != oracleAddress) {
            require(address(essenceToken) != address(0), "ACI: ESSENCE token address not set.");
            require(_essenceStake > 0, "ACI: Must stake ESSENCE to submit fragment (or be owner/oracle).");
            require(essenceToken.transferFrom(msg.sender, address(this), _essenceStake), "ACI: ESSENCE transfer failed. Check allowance.");
        }

        knowledgeFragments[nextKnowledgeFragmentId] = KnowledgeFragment({
            id: nextKnowledgeFragmentId,
            submitter: msg.sender,
            fragmentHash: _fragmentHash,
            metadataURI: _metadataURI,
            essenceStake: _essenceStake,
            integrated: false,
            submissionTime: block.timestamp
        });
        emit KnowledgeFragmentSubmitted(nextKnowledgeFragmentId, msg.sender, _fragmentHash);
        nextKnowledgeFragmentId++;
    }

    /// @notice A pivotal function that processes accumulated data (votes on traits, evaluations, knowledge fragments)
    /// and formally evolves the ACI Nexus's traits and overall state, updating its dynamic tokenURI.
    /// @dev This function would trigger major updates to the Nexus's internal state, reflecting its growth and learning.
    /// It can be called by the owner (representing a DAO decision), or theoretically by a time-based oracle.
    function triggerNexusEvolution() public onlyOwner pausable {
        currentEpochId++; // Increment epoch, signifying a new phase of evolution

        // 1. Process and apply approved trait modification proposals.
        // Simplified approval logic: if a proposal has accumulated > 10 votes, it's considered approved.
        for (uint256 i = 1; i < nextTraitModificationId; i++) {
            TraitModificationProposal storage proposal = traitModificationProposals[i];
            if (!proposal.executed && proposal.votes > 10) { // Example threshold
                nexusTraits[proposal.traitName] = proposal.newValue;
                proposal.approved = true;
                proposal.executed = true;
                // Return staked ESSENCE to proposer upon successful execution
                if (address(essenceToken) != address(0) && proposal.essenceStake > 0) {
                    essenceToken.transfer(proposal.proposer, proposal.essenceStake);
                    emit EssenceRewardClaimed(proposal.proposer, proposal.essenceStake); // Or a specific event for returned stake
                }
                emit TraitModificationExecuted(proposal.id, proposal.traitName, proposal.newValue);
                emit NexusStateUpdated(currentEpochId, proposal.traitName, proposal.newValue);
            }
        }

        // 2. Integrate new knowledge fragments.
        // For demonstration, we integrate one pending fragment per evolution cycle.
        // In a real system, this would involve a voting/selection process or AI-driven relevance ranking.
        for (uint252 i = 1; i < nextKnowledgeFragmentId; i++) {
            KnowledgeFragment storage fragment = knowledgeFragments[i];
            if (!fragment.integrated) {
                // This fragment influences the Nexus. How it influences can be complex.
                // For example, it could update a 'knowledge_domain' trait or a 'fact_base_hash'.
                nexusTraits["last_integrated_knowledge_hash_prefix"] = fragment.fragmentHash; // Update a trait
                fragment.integrated = true;
                emit KnowledgeFragmentIntegrated(fragment.id, fragment.fragmentHash);
                // Reward the fragment submitter for their contribution
                participantReputation[fragment.submitter] += 10;
                emit ReputationUpdated(fragment.submitter, participantReputation[fragment.submitter]);
                break; // Integrate only one per cycle for simplicity
            }
        }

        // 3. Update the 'last_evolution_hash' trait to reflect the new state (e.g., an IPFS hash of new composite metadata).
        // This hash would be generated off-chain based on all current traits and historical data,
        // representing the Nexus's unique state for this epoch.
        string memory newEvolutionHash = string.concat("epoch_", currentEpochId.toString(), "_hash_", block.timestamp.toString()); // Example placeholder
        nexusTraits["last_evolution_hash"] = newEvolutionHash;
        nexusHistoryEpochs[currentEpochId] = newEvolutionHash; // Store historical state hash

        emit NexusEvolutionTriggered(currentEpochId, tokenURI(NEXUS_TOKEN_ID));
    }

    // --- VII. Read Functions & Utilities (Transparency) ---

    /// @notice Retrieves the full content and status of a specific prompt.
    /// @param _promptId The ID of the prompt to retrieve.
    /// @return All details of the prompt.
    function getPromptData(uint256 _promptId) public view returns (
        uint256 id,
        address proposer,
        string memory content,
        uint256 essenceStake,
        uint256 proposalVotes,
        bool isActive,
        bool isConcluded,
        uint256 winningResponseId,
        uint256 creationTime
    ) {
        Prompt storage p = prompts[_promptId];
        require(p.id != 0, "ACI: Prompt does not exist.");
        return (p.id, p.proposer, p.content, p.essenceStake, p.proposalVotes, p.isActive, p.isConcluded, p.winningResponseId, p.creationTime);
    }

    /// @notice Retrieves the full content, community votes, and oracle evaluation for a specific response.
    /// @param _responseId The ID of the response to retrieve.
    /// @return All details of the response.
    function getResponseDetails(uint256 _responseId) public view returns (
        uint256 id,
        uint256 promptId,
        address responder,
        string memory content,
        uint256 communityVotes,
        uint256 oracleEvaluationScore,
        bool evaluatedByOracle,
        bool isWinner,
        uint256 submissionTime
    ) {
        Response storage r = responses[_responseId];
        require(r.id != 0, "ACI: Response does not exist.");
        return (r.id, r.promptId, r.responder, r.content, r.communityVotes, r.oracleEvaluationScore, r.evaluatedByOracle, r.isWinner, r.submissionTime);
    }

    /// @notice Retrieves the current value of a specific ACI Nexus trait.
    /// @param _traitName The name of the trait to query (e.g., "purpose", "current_mood").
    /// @return string The current string value of the specified trait.
    function getTraitValue(string calldata _traitName) public view returns (string memory) {
        return nexusTraits[_traitName];
    }

    /// @notice Returns the number of prompts currently awaiting selection by the community or admin.
    /// @return uint256 Count of pending prompts.
    function getPendingPromptCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextPromptId; i++) {
            if (!prompts[i].isActive && !prompts[i].isConcluded) {
                count++;
            }
        }
        return count;
    }

    /// @notice Returns the ID of the currently active prompt.
    /// @return uint256 The ID of the active prompt, or 0 if no prompt is currently active.
    function getActivePromptId() public view returns (uint256) {
        return activePromptId;
    }

    /// @notice Returns the amount of ESSENCE staked by a specific participant.
    /// @param _participant The address of the participant.
    /// @return uint256 The total amount of ESSENCE staked by the participant.
    function getEssenceStakedAmount(address _participant) public view returns (uint256) {
        return stakedEssence[_participant];
    }
}
```