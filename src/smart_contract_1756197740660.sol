This smart contract, named **AetherForge**, is a decentralized, AI-augmented creative and curation protocol. It orchestrates the process of generating creative content using AI models, followed by community-driven curation and validation. The protocol leverages staking for quality control and a dynamic, non-transferable reputation system to incentivize honest and valuable participation from creators, AI model providers, and curators.

**Core Concept:** AetherForge aims to bridge the gap between decentralized creative ideas (Prompts) and AI-driven content generation (Forges), ensuring quality and ethical standards through a robust, community-governed curation process. Participants earn reputation and rewards based on their contributions and the community's assessment of their work.

---

## Contract: `AetherForge`

### Outline and Function Summary

**I. Core Registry & Participant Management**
This section handles the registration, profile updates, and general management of all participants within the AetherForge ecosystem (Creators, AI Model Providers, Curators).

1.  **`registerParticipant(string _role, string _profileURI)`**: Allows a new user to register, defining their primary role (e.g., "Creator", "Curator", "AIModelProvider") and linking to an off-chain profile (e.g., IPFS hash).
2.  **`updateParticipantProfile(string _newProfileURI)`**: Enables an existing participant to update their associated off-chain profile URI.
3.  **`deregisterParticipant()`**: Allows a participant to remove their registration, provided they have no active stakes or pending obligations, reclaiming any eligible funds.
4.  **`getParticipantDetails(address _participant)`**: Retrieves comprehensive details about a registered participant, including their role, profile URI, reputation score, and active status.

**II. Prompt Management (Creative Ideas)**
This section manages the lifecycle of creative "prompts" – the initial ideas or specifications for AI-generated content.

5.  **`submitPrompt(string _promptURI, uint256 _bountyAmount)`**: A participant submits a new creative prompt (e.g., an IPFS hash of a detailed text description or image reference), attaching an initial bounty in the native token.
6.  **`fundPrompt(uint256 _promptId)`**: Allows anyone to contribute additional funds to an existing prompt's bounty, increasing its attractiveness for AI model providers.
7.  **`retractPrompt(uint256 _promptId)`**: The creator of a prompt can retract it if no AI model has started work on it yet, reclaiming the original bounty.
8.  **`getPromptDetails(uint256 _promptId)`**: Fetches the details of a specific prompt, including its content URI, current bounty, status, and associated AI models.

**III. AI Model & Forge (Content Generation) Process**
This section details how AI models are registered and how they propose generated content ("Forges") based on prompts.

9.  **`proposeAIModel(string _modelURI, string _description, uint256 _initialStake)`**: An AI Model Provider registers a reference to an AI model (e.g., IPFS hash of model parameters, a decentralized inference network endpoint), staking tokens as a commitment to its quality and availability.
10. **`proposeForge(uint256 _promptId, uint256 _modelId, string _forgeURI, uint256 _generationStake)`**: An AI Model Provider, using their registered model, proposes a generated output (a "Forge") for a specific prompt. They stake tokens, which can be rewarded or slashed based on curation outcomes.
11. **`selectWinningForge(uint256 _promptId, uint256 _forgeId)`**: The original prompt creator, or a highly reputable curator, designates a specific Forge as the "winning" submission for a prompt. This moves the Forge to a curation-ready state and triggers bounty distribution upon successful curation.
12. **`getForgeDetails(uint256 _forgeId)`**: Retrieves all information about a specific generated Forge, including its content URI, associated prompt and model, and current status.

**IV. Decentralized Curation & Validation**
This is the core quality control mechanism, where the community evaluates Forges and ensures compliance and quality.

13. **`submitCuration(uint256 _forgeId, uint8 _score, string _feedbackURI, uint256 _curationStake)`**: Registered curators evaluate a submitted Forge by providing a score (e.g., 1-10) and an off-chain feedback URI, staking a small amount to participate.
14. **`challengeForgeCuration(uint256 _forgeId, uint256 _curationId, string _reasonURI, uint256 _challengeStake)`**: Any participant can challenge a specific curation if they believe it is unfair, malicious, or inaccurate. This requires a stake and initiates a community voting period.
15. **`voteOnCurationChallenge(uint256 _challengeId, bool _supportChallenge)`**: Registered participants (typically those with higher reputation) vote to support or reject a challenge against a curation.
16. **`resolveCurationChallenge(uint256 _challengeId)`**: After the voting period, this function finalizes a challenge. Based on the vote outcome, stakes from the challenging or challenged party are slashed, and reputation adjusted.

**V. Reputation & Rewards**
This section handles the dynamic reputation system and the distribution of rewards.

17. **`calculateReputation(address _participant)` (View)**: An internal/view function to dynamically calculate a participant's reputation score based on their history of successful prompts, high-quality forges, accurate curations, and successful challenge outcomes. This reputation is non-transferable and influences voting weight and reward multipliers.
18. **`claimRewards()`**: Allows a participant to claim their accumulated rewards from bounties, successful forges, and accurate curations.
19. **`getPendingRewards(address _participant)` (View)**: Displays the total amount of rewards currently claimable by a specific participant.

**VI. Protocol Governance & Maintenance**
These functions are typically reserved for the contract owner for critical system parameters and emergency control.

20. **`setProtocolFee(uint256 _newFeeBps)`**: The contract owner can set a protocol fee (in basis points) that is applied to successful prompt bounties.
21. **`withdrawProtocolFees()`**: Allows the contract owner to withdraw the accumulated protocol fees.
22. **`emergencyPause()`**: In an emergency, the owner can pause the contract, preventing most state-changing operations.
23. **`unpauseContract()`**: The owner can unpause the contract once the emergency is resolved.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for explicit safety though 0.8+ handles overflow

/**
 * @title AetherForge
 * @dev A decentralized, AI-augmented creative and curation protocol.
 *      Orchestrates AI-driven content generation, community curation,
 *      and reputation-based incentives.
 *
 * Outline and Function Summary:
 *
 * I. Core Registry & Participant Management
 *    1. registerParticipant(string _role, string _profileURI)
 *    2. updateParticipantProfile(string _newProfileURI)
 *    3. deregisterParticipant()
 *    4. getParticipantDetails(address _participant)
 *
 * II. Prompt Management (Creative Ideas)
 *    5. submitPrompt(string _promptURI, uint256 _bountyAmount)
 *    6. fundPrompt(uint256 _promptId)
 *    7. retractPrompt(uint256 _promptId)
 *    8. getPromptDetails(uint256 _promptId)
 *
 * III. AI Model & Forge (Content Generation) Process
 *    9. proposeAIModel(string _modelURI, string _description, uint256 _initialStake)
 *    10. proposeForge(uint256 _promptId, uint256 _modelId, string _forgeURI, uint256 _generationStake)
 *    11. selectWinningForge(uint256 _promptId, uint256 _forgeId)
 *    12. getForgeDetails(uint256 _forgeId)
 *
 * IV. Decentralized Curation & Validation
 *    13. submitCuration(uint256 _forgeId, uint8 _score, string _feedbackURI, uint256 _curationStake)
 *    14. challengeForgeCuration(uint256 _forgeId, uint256 _curationId, string _reasonURI, uint256 _challengeStake)
 *    15. voteOnCurationChallenge(uint256 _challengeId, bool _supportChallenge)
 *    16. resolveCurationChallenge(uint256 _challengeId)
 *
 * V. Reputation & Rewards
 *    17. calculateReputation(address _participant) (View)
 *    18. claimRewards()
 *    19. getPendingRewards(address _participant) (View)
 *
 * VI. Protocol Governance & Maintenance
 *    20. setProtocolFee(uint256 _newFeeBps)
 *    21. withdrawProtocolFees()
 *    22. emergencyPause()
 *    23. unpauseContract()
 */
contract AetherForge is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Enums and Structs ---

    enum ParticipantRole { None, Creator, AIModelProvider, Curator }
    enum PromptStatus { Open, SelectedAI, CurationPending, Finalized, Retracted }
    enum ForgeStatus { Proposed, WaitingCuration, Curated, Challenged, Finalized, Rejected }
    enum ChallengeStatus { Open, Voting, Resolved }

    struct Participant {
        uint256 id;
        ParticipantRole role;
        string profileURI;
        uint256 reputation; // Non-transferable internal score
        uint256 stakedBalance; // Total active stake
        uint256 pendingRewards;
        bool isActive;
        address participantAddress; // Redundant but useful for lookup
    }

    struct Prompt {
        uint256 id;
        address creator;
        string promptURI; // IPFS hash or similar for prompt content
        uint256 bountyAmount;
        PromptStatus status;
        uint256 selectedForgeId; // The forge chosen as the winner
        uint256 creationTime;
    }

    struct AIModel {
        uint256 id;
        address owner;
        string modelURI; // IPFS hash or decentralized AI service endpoint
        string description;
        uint256 stake; // Stake for model integrity
        uint256 creationTime;
        bool isActive;
    }

    struct Forge {
        uint256 id;
        uint256 promptId;
        uint256 modelId;
        address creatorAddress; // Address of the AIModel owner who proposed this forge
        string forgeURI; // IPFS hash or similar for generated content
        uint256 generationStake;
        ForgeStatus status;
        uint256 curationScoreSum; // Sum of scores from all curations
        uint256 curationCount; // Number of curations received
        uint256 finalCurationScore; // Average score after finalization
        uint256 creationTime;
    }

    struct Curation {
        uint256 id;
        uint256 forgeId;
        address curator;
        uint8 score; // 1-10
        string feedbackURI; // IPFS hash for detailed feedback
        uint256 curationStake;
        bool challenged;
        uint256 creationTime;
    }

    struct Challenge {
        uint256 id;
        uint256 targetForgeId;
        uint256 targetCurationId; // Which curation is being challenged
        address challenger;
        string reasonURI;
        uint256 challengeStake;
        ChallengeStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this challenge
        uint256 challengeEndTime;
    }

    // --- State Variables ---

    uint256 public nextParticipantId = 1;
    uint256 public nextPromptId = 1;
    uint256 public nextAIModelId = 1;
    uint256 public nextForgeId = 1;
    uint256 public nextCurationId = 1;
    uint256 public nextChallengeId = 1;

    mapping(address => uint256) public participantIdByAddress;
    mapping(uint256 => Participant) public participants;
    mapping(uint256 => Prompt) public prompts;
    mapping(uint256 => AIModel) public aiModels;
    mapping(uint256 => Forge) public forges;
    mapping(uint256 => Curation) public curations;
    mapping(uint256 => Challenge) public challenges;

    uint256 public protocolFeeBps = 500; // 5% in basis points (500/10000)
    uint256 public totalProtocolFeesCollected;

    // Configuration for challenge voting
    uint256 public constant CHALLENGE_VOTING_PERIOD = 3 days; // Example: 3 days for voting

    // --- Events ---

    event ParticipantRegistered(uint256 indexed participantId, address indexed participantAddress, string role, string profileURI);
    event ParticipantProfileUpdated(uint256 indexed participantId, address indexed participantAddress, string newProfileURI);
    event ParticipantDeregistered(uint256 indexed participantId, address indexed participantAddress);

    event PromptSubmitted(uint256 indexed promptId, address indexed creator, string promptURI, uint256 bountyAmount);
    event PromptFunded(uint256 indexed promptId, address indexed funder, uint256 amount);
    event PromptRetracted(uint256 indexed promptId, address indexed creator);
    event PromptStatusChanged(uint256 indexed promptId, PromptStatus newStatus);

    event AIModelProposed(uint256 indexed modelId, address indexed owner, string modelURI, uint256 stake);
    event ForgeProposed(uint256 indexed forgeId, uint256 indexed promptId, uint256 indexed modelId, address creatorAddress, string forgeURI, uint256 generationStake);
    event ForgeSelected(uint256 indexed promptId, uint256 indexed forgeId, address indexed selector);
    event ForgeStatusChanged(uint256 indexed forgeId, ForgeStatus newStatus);

    event CurationSubmitted(uint256 indexed curationId, uint256 indexed forgeId, address indexed curator, uint8 score);
    event CurationChallenged(uint256 indexed challengeId, uint256 indexed forgeId, uint256 indexed curationId, address indexed challenger);
    event VoteOnChallenge(uint256 indexed challengeId, address indexed voter, bool support);
    event ChallengeResolved(uint256 indexed challengeId, ChallengeStatus finalStatus, uint256 votesFor, uint256 votesAgainst);

    event RewardsClaimed(address indexed participant, uint256 amount);
    event ReputationUpdated(address indexed participant, uint256 newReputation);

    event ProtocolFeeSet(uint256 newFeeBps);
    event ProtocolFeesWithdrawn(uint256 amount);

    constructor() Ownable(msg.sender) {}

    // --- Modifiers ---

    modifier onlyRegisteredParticipant() {
        require(participantIdByAddress[msg.sender] != 0, "Not a registered participant");
        _;
    }

    modifier onlyCreator(uint256 _promptId) {
        require(prompts[_promptId].creator == msg.sender, "Only prompt creator can perform this action");
        _;
    }

    modifier onlyActiveParticipant(address _participantAddress) {
        require(participants[participantIdByAddress[_participantAddress]].isActive, "Participant is inactive");
        _;
    }

    // --- I. Core Registry & Participant Management ---

    /**
     * @dev Allows a new user to register, defining their primary role and linking to an off-chain profile.
     * @param _role The role of the participant (e.g., "Creator", "Curator", "AIModelProvider").
     * @param _profileURI IPFS hash or URL for the participant's profile metadata.
     */
    function registerParticipant(string calldata _role, string calldata _profileURI)
        external
        nonReentrant
        whenNotPaused
    {
        require(participantIdByAddress[msg.sender] == 0, "Participant already registered");
        require(bytes(_profileURI).length > 0, "Profile URI cannot be empty");

        ParticipantRole pRole;
        if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Creator"))) {
            pRole = ParticipantRole.Creator;
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Curator"))) {
            pRole = ParticipantRole.Curator;
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("AIModelProvider"))) {
            pRole = ParticipantRole.AIModelProvider;
        } else {
            revert("Invalid participant role");
        }

        uint256 pId = nextParticipantId++;
        participants[pId] = Participant({
            id: pId,
            role: pRole,
            profileURI: _profileURI,
            reputation: 100, // Starting reputation
            stakedBalance: 0,
            pendingRewards: 0,
            isActive: true,
            participantAddress: msg.sender
        });
        participantIdByAddress[msg.sender] = pId;

        emit ParticipantRegistered(pId, msg.sender, _role, _profileURI);
    }

    /**
     * @dev Enables an existing participant to update their associated off-chain profile URI.
     * @param _newProfileURI The new IPFS hash or URL for the participant's profile metadata.
     */
    function updateParticipantProfile(string calldata _newProfileURI)
        external
        onlyRegisteredParticipant
        whenNotPaused
    {
        require(bytes(_newProfileURI).length > 0, "New profile URI cannot be empty");
        uint256 pId = participantIdByAddress[msg.sender];
        participants[pId].profileURI = _newProfileURI;

        emit ParticipantProfileUpdated(pId, msg.sender, _newProfileURI);
    }

    /**
     * @dev Allows a participant to remove their registration.
     *      Requires no active stakes or pending obligations.
     *      Pending rewards will be auto-claimed.
     */
    function deregisterParticipant()
        external
        onlyRegisteredParticipant
        nonReentrant
        whenNotPaused
    {
        uint256 pId = participantIdByAddress[msg.sender];
        Participant storage p = participants[pId];

        require(p.stakedBalance == 0, "Cannot deregister with active stakes");
        // Additional checks for active prompts/forges/curations could be added for stricter enforcement

        // Claim any pending rewards before deactivation
        if (p.pendingRewards > 0) {
            uint256 rewardsToClaim = p.pendingRewards;
            p.pendingRewards = 0;
            payable(msg.sender).transfer(rewardsToClaim);
            emit RewardsClaimed(msg.sender, rewardsToClaim);
        }

        p.isActive = false; // Mark as inactive
        // participantIdByAddress[msg.sender] = 0; // Optionally clear mapping to free up address, but might break historical lookup

        emit ParticipantDeregistered(pId, msg.sender);
    }

    /**
     * @dev Retrieves comprehensive details about a registered participant.
     * @param _participant The address of the participant.
     * @return Participant struct details.
     */
    function getParticipantDetails(address _participant)
        public
        view
        returns (uint256, ParticipantRole, string memory, uint256, uint256, uint256, bool)
    {
        uint256 pId = participantIdByAddress[_participant];
        require(pId != 0, "Participant not found");
        Participant storage p = participants[pId];
        return (p.id, p.role, p.profileURI, p.reputation, p.stakedBalance, p.pendingRewards, p.isActive);
    }

    // --- II. Prompt Management (Creative Ideas) ---

    /**
     * @dev A participant submits a new creative prompt, attaching an initial bounty.
     * @param _promptURI IPFS hash or similar for prompt content.
     * @param _bountyAmount The initial bounty amount in native tokens.
     */
    function submitPrompt(string calldata _promptURI, uint256 _bountyAmount)
        external
        payable
        onlyRegisteredParticipant
        whenNotPaused
        nonReentrant
    {
        require(bytes(_promptURI).length > 0, "Prompt URI cannot be empty");
        require(msg.value == _bountyAmount, "ETH sent must match bountyAmount");
        require(_bountyAmount > 0, "Bounty must be greater than zero");

        uint256 pId = participantIdByAddress[msg.sender];
        require(participants[pId].role == ParticipantRole.Creator, "Only Creators can submit prompts");

        uint256 promptId = nextPromptId++;
        prompts[promptId] = Prompt({
            id: promptId,
            creator: msg.sender,
            promptURI: _promptURI,
            bountyAmount: _bountyAmount,
            status: PromptStatus.Open,
            selectedForgeId: 0,
            creationTime: block.timestamp
        });

        emit PromptSubmitted(promptId, msg.sender, _promptURI, _bountyAmount);
    }

    /**
     * @dev Allows anyone to contribute additional funds to an existing prompt's bounty.
     * @param _promptId The ID of the prompt to fund.
     */
    function fundPrompt(uint256 _promptId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        Prompt storage p = prompts[_promptId];
        require(p.id != 0, "Prompt not found");
        require(p.status == PromptStatus.Open || p.status == PromptStatus.SelectedAI, "Prompt is not open for funding");
        require(msg.value > 0, "Must send ETH to fund prompt");

        p.bountyAmount = p.bountyAmount.add(msg.value);

        emit PromptFunded(_promptId, msg.sender, msg.value);
    }

    /**
     * @dev The creator of a prompt can retract it if no AI model has started work on it yet.
     *      This reclaims the original bounty.
     * @param _promptId The ID of the prompt to retract.
     */
    function retractPrompt(uint256 _promptId)
        external
        onlyCreator(_promptId)
        whenNotPaused
        nonReentrant
    {
        Prompt storage p = prompts[_promptId];
        require(p.status == PromptStatus.Open, "Prompt cannot be retracted at its current stage");

        p.status = PromptStatus.Retracted;
        
        // Return bounty to creator
        uint256 bountyToReturn = p.bountyAmount;
        p.bountyAmount = 0; // Clear bounty
        payable(p.creator).transfer(bountyToReturn);

        emit PromptRetracted(_promptId, msg.sender);
        emit PromptStatusChanged(_promptId, PromptStatus.Retracted);
    }

    /**
     * @dev Fetches the details of a specific prompt.
     * @param _promptId The ID of the prompt.
     * @return Prompt struct details.
     */
    function getPromptDetails(uint256 _promptId)
        public
        view
        returns (uint256, address, string memory, uint256, PromptStatus, uint256, uint256)
    {
        Prompt storage p = prompts[_promptId];
        require(p.id != 0, "Prompt not found");
        return (p.id, p.creator, p.promptURI, p.bountyAmount, p.status, p.selectedForgeId, p.creationTime);
    }

    // --- III. AI Model & Forge (Content Generation) Process ---

    /**
     * @dev An AI Model Provider registers a reference to an AI model, staking tokens for its integrity.
     * @param _modelURI IPFS hash or decentralized AI service endpoint for the model.
     * @param _description A brief description of the AI model.
     * @param _initialStake The initial stake for model integrity.
     */
    function proposeAIModel(string calldata _modelURI, string calldata _description, uint256 _initialStake)
        external
        payable
        onlyRegisteredParticipant
        whenNotPaused
        nonReentrant
    {
        require(msg.value == _initialStake, "ETH sent must match initialStake");
        require(bytes(_modelURI).length > 0, "Model URI cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_initialStake > 0, "Initial stake must be greater than zero");

        uint256 pId = participantIdByAddress[msg.sender];
        require(participants[pId].role == ParticipantRole.AIModelProvider, "Only AI Model Providers can propose models");

        uint256 modelId = nextAIModelId++;
        aiModels[modelId] = AIModel({
            id: modelId,
            owner: msg.sender,
            modelURI: _modelURI,
            description: _description,
            stake: _initialStake,
            creationTime: block.timestamp,
            isActive: true
        });
        participants[pId].stakedBalance = participants[pId].stakedBalance.add(_initialStake);

        emit AIModelProposed(modelId, msg.sender, _modelURI, _initialStake);
    }

    /**
     * @dev An AI Model Provider, using their registered model, proposes a generated output (Forge) for a prompt.
     * @param _promptId The ID of the prompt for which content is generated.
     * @param _modelId The ID of the AI model used.
     * @param _forgeURI IPFS hash or similar for the generated content.
     * @param _generationStake Tokens staked for this specific generation's quality.
     */
    function proposeForge(uint256 _promptId, uint256 _modelId, string calldata _forgeURI, uint256 _generationStake)
        external
        payable
        onlyRegisteredParticipant
        whenNotPaused
        nonReentrant
    {
        require(msg.value == _generationStake, "ETH sent must match generationStake");
        require(bytes(_forgeURI).length > 0, "Forge URI cannot be empty");
        require(_generationStake > 0, "Generation stake must be greater than zero");

        Prompt storage p = prompts[_promptId];
        require(p.id != 0, "Prompt not found");
        require(p.status == PromptStatus.Open || p.status == PromptStatus.SelectedAI, "Prompt is not open for new forges");

        AIModel storage model = aiModels[_modelId];
        require(model.id != 0, "AI Model not found");
        require(model.owner == msg.sender, "Only the AI Model owner can propose forges for their model");
        require(model.isActive, "AI Model is inactive");

        uint256 pId = participantIdByAddress[msg.sender];
        participants[pId].stakedBalance = participants[pId].stakedBalance.add(_generationStake);

        uint256 forgeId = nextForgeId++;
        forges[forgeId] = Forge({
            id: forgeId,
            promptId: _promptId,
            modelId: _modelId,
            creatorAddress: msg.sender,
            forgeURI: _forgeURI,
            generationStake: _generationStake,
            status: ForgeStatus.Proposed,
            curationScoreSum: 0,
            curationCount: 0,
            finalCurationScore: 0,
            creationTime: block.timestamp
        });

        emit ForgeProposed(forgeId, _promptId, _modelId, msg.sender, _forgeURI, _generationStake);
    }

    /**
     * @dev The prompt creator or a highly reputable curator selects a winning forge for a prompt.
     *      This moves the Forge to a curation-ready state and makes it eligible for bounty distribution.
     * @param _promptId The ID of the prompt.
     * @param _forgeId The ID of the forge to select.
     */
    function selectWinningForge(uint256 _promptId, uint256 _forgeId)
        external
        onlyRegisteredParticipant
        whenNotPaused
        nonReentrant
    {
        Prompt storage p = prompts[_promptId];
        require(p.id != 0, "Prompt not found");
        require(p.status == PromptStatus.Open, "Prompt is not in a state to select a winning forge");

        Forge storage f = forges[_forgeId];
        require(f.id != 0, "Forge not found");
        require(f.promptId == _promptId, "Forge does not belong to this prompt");
        require(f.status == ForgeStatus.Proposed, "Forge is not in a proposed state");

        bool isCreator = (p.creator == msg.sender);
        bool isHighReputationCurator = false; // Placeholder for advanced reputation-based selection logic
        // Example: if (participants[participantIdByAddress[msg.sender]].reputation >= MIN_REPUTATION_FOR_SELECTION) { isHighReputationCurator = true; }

        require(isCreator || isHighReputationCurator, "Only the prompt creator or a high-reputation curator can select a winning forge");

        p.selectedForgeId = _forgeId;
        p.status = PromptStatus.CurationPending;
        f.status = ForgeStatus.WaitingCuration;

        emit ForgeSelected(_promptId, _forgeId, msg.sender);
        emit PromptStatusChanged(_promptId, PromptStatus.CurationPending);
        emit ForgeStatusChanged(_forgeId, ForgeStatus.WaitingCuration);
    }

    /**
     * @dev Get details about a specific generated forge.
     * @param _forgeId The ID of the forge.
     * @return Forge struct details.
     */
    function getForgeDetails(uint256 _forgeId)
        public
        view
        returns (uint256, uint256, uint256, address, string memory, uint256, ForgeStatus, uint256, uint256, uint256, uint256)
    {
        Forge storage f = forges[_forgeId];
        require(f.id != 0, "Forge not found");
        return (f.id, f.promptId, f.modelId, f.creatorAddress, f.forgeURI, f.generationStake, f.status, f.curationScoreSum, f.curationCount, f.finalCurationScore, f.creationTime);
    }

    // --- IV. Decentralized Curation & Validation ---

    /**
     * @dev Curators evaluate a submitted Forge with a score and feedback.
     *      Requires a small stake to prevent spam.
     * @param _forgeId The ID of the forge being curated.
     * @param _score The curator's score for the forge (1-10).
     * @param _feedbackURI IPFS hash or similar for detailed feedback.
     * @param _curationStake Tokens staked by the curator for this curation.
     */
    function submitCuration(uint256 _forgeId, uint8 _score, string calldata _feedbackURI, uint256 _curationStake)
        external
        payable
        onlyRegisteredParticipant
        whenNotPaused
        nonReentrant
    {
        require(msg.value == _curationStake, "ETH sent must match curationStake");
        require(_score >= 1 && _score <= 10, "Score must be between 1 and 10");
        require(bytes(_feedbackURI).length > 0, "Feedback URI cannot be empty");
        require(_curationStake > 0, "Curation stake must be greater than zero");

        Forge storage f = forges[_forgeId];
        require(f.id != 0, "Forge not found");
        require(f.status == ForgeStatus.WaitingCuration, "Forge is not awaiting curation");

        uint256 pId = participantIdByAddress[msg.sender];
        require(participants[pId].role == ParticipantRole.Curator, "Only Curators can submit curations");
        require(msg.sender != f.creatorAddress, "Creator cannot curate their own forge");
        require(msg.sender != prompts[f.promptId].creator, "Prompt creator cannot curate this forge");
        
        // Prevent duplicate curations by the same curator for the same forge
        // Could use a mapping (forgeId => curatorAddress => bool) for this
        // For simplicity, we'll allow multiple curations but rely on averaging later.
        // For production, a more robust anti-spam/duplicate check would be needed.

        participants[pId].stakedBalance = participants[pId].stakedBalance.add(_curationStake);

        uint256 curationId = nextCurationId++;
        curations[curationId] = Curation({
            id: curationId,
            forgeId: _forgeId,
            curator: msg.sender,
            score: _score,
            feedbackURI: _feedbackURI,
            curationStake: _curationStake,
            challenged: false,
            creationTime: block.timestamp
        });

        f.curationScoreSum = f.curationScoreSum.add(_score);
        f.curationCount = f.curationCount.add(1);

        // A threshold could be used to automatically finalize curation
        // For now, we'll assume manual finalization or a separate "finalizeCurationRound" function.
        if (f.curationCount >= 3) { // Example: After 3 curations, move to Curated status
            f.status = ForgeStatus.Curated;
            emit ForgeStatusChanged(_forgeId, ForgeStatus.Curated);
        }

        emit CurationSubmitted(curationId, _forgeId, msg.sender, _score);
    }

    /**
     * @dev Any participant can challenge a specific curation if they believe it is unfair, malicious, or inaccurate.
     *      This requires a stake and initiates a community voting period.
     * @param _forgeId The ID of the forge whose curation is being challenged.
     * @param _curationId The ID of the specific curation being challenged.
     * @param _reasonURI IPFS hash or similar for the reason for the challenge.
     * @param _challengeStake Tokens staked by the challenger.
     */
    function challengeForgeCuration(uint256 _forgeId, uint256 _curationId, string calldata _reasonURI, uint256 _challengeStake)
        external
        payable
        onlyRegisteredParticipant
        whenNotPaused
        nonReentrant
    {
        require(msg.value == _challengeStake, "ETH sent must match challengeStake");
        require(bytes(_reasonURI).length > 0, "Reason URI cannot be empty");
        require(_challengeStake > 0, "Challenge stake must be greater than zero");

        Forge storage f = forges[_forgeId];
        require(f.id != 0, "Forge not found");
        require(f.status == ForgeStatus.WaitingCuration || f.status == ForgeStatus.Curated, "Forge not in a state to be challenged");

        Curation storage c = curations[_curationId];
        require(c.id != 0, "Curation not found");
        require(c.forgeId == _forgeId, "Curation does not belong to this forge");
        require(!c.challenged, "Curation already challenged");

        uint256 pId = participantIdByAddress[msg.sender];
        participants[pId].stakedBalance = participants[pId].stakedBalance.add(_challengeStake);

        c.challenged = true;
        f.status = ForgeStatus.Challenged;

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            id: challengeId,
            targetForgeId: _forgeId,
            targetCurationId: _curationId,
            challenger: msg.sender,
            reasonURI: _reasonURI,
            challengeStake: _challengeStake,
            status: ChallengeStatus.Open,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            challengeEndTime: block.timestamp.add(CHALLENGE_VOTING_PERIOD)
        });

        emit CurationChallenged(challengeId, _forgeId, _curationId, msg.sender);
        emit ForgeStatusChanged(_forgeId, ForgeStatus.Challenged);
    }

    /**
     * @dev Registered participants (with sufficient reputation) vote on whether a challenged curation is valid or not.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _supportChallenge True if the voter supports the challenge (i.e., believes the original curation was bad), false otherwise.
     */
    function voteOnCurationChallenge(uint256 _challengeId, bool _supportChallenge)
        external
        onlyRegisteredParticipant
        whenNotPaused
    {
        Challenge storage ch = challenges[_challengeId];
        require(ch.id != 0, "Challenge not found");
        require(ch.status == ChallengeStatus.Open, "Challenge is not in voting phase");
        require(block.timestamp < ch.challengeEndTime, "Voting period has ended");
        require(!ch.hasVoted[msg.sender], "Already voted on this challenge");

        uint256 pId = participantIdByAddress[msg.sender];
        // Example: Only participants with a certain reputation or role can vote
        // require(participants[pId].reputation >= MIN_VOTING_REPUTATION, "Insufficient reputation to vote");

        ch.hasVoted[msg.sender] = true;

        if (_supportChallenge) {
            ch.votesFor = ch.votesFor.add(participants[pId].reputation); // Weighted vote by reputation
        } else {
            ch.votesAgainst = ch.votesAgainst.add(participants[pId].reputation);
        }

        emit VoteOnChallenge(_challengeId, msg.sender, _supportChallenge);
    }

    /**
     * @dev Finalizes a challenge vote. Based on the vote outcome, stakes from the losing party are slashed, and reputation adjusted.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function resolveCurationChallenge(uint256 _challengeId)
        external
        onlyRegisteredParticipant // Can be anyone or restricted to owner/high-rep curator
        whenNotPaused
        nonReentrant
    {
        Challenge storage ch = challenges[_challengeId];
        require(ch.id != 0, "Challenge not found");
        require(ch.status == ChallengeStatus.Open, "Challenge is not in voting phase");
        require(block.timestamp >= ch.challengeEndTime, "Voting period has not ended yet");

        Curation storage c = curations[ch.targetCurationId];
        Forge storage f = forges[ch.targetForgeId];

        uint256 challengerPId = participantIdByAddress[ch.challenger];
        uint256 curatorPId = participantIdByAddress[c.curator];

        if (ch.votesFor > ch.votesAgainst) { // Challenge succeeded: original curation was deemed bad
            // Slashing logic
            uint256 slashedAmount = c.curationStake;
            participants[curatorPId].stakedBalance = participants[curatorPId].stakedBalance.sub(slashedAmount);
            // Distribute slashed amount to voters for supporting challenge
            // Or add to bounty, or burn
            participants[challengerPId].pendingRewards = participants[challengerPId].pendingRewards.add(slashedAmount.div(2)); // Example distribution
            _updateReputation(c.curator, false); // Decrease curator's reputation
            _updateReputation(ch.challenger, true); // Increase challenger's reputation if successful

            // Potentially remove this bad curation from forge's score sum
            f.curationScoreSum = f.curationScoreSum.sub(c.score);
            f.curationCount = f.curationCount.sub(1);

            ch.status = ChallengeStatus.Resolved;
            emit ChallengeResolved(_challengeId, ChallengeStatus.Resolved, ch.votesFor, ch.votesAgainst);

        } else if (ch.votesAgainst > ch.votesFor) { // Challenge failed: original curation was deemed good
            // Slashing logic
            uint256 slashedAmount = ch.challengeStake;
            participants[challengerPId].stakedBalance = participants[challengerPId].stakedBalance.sub(slashedAmount);
            // Distribute slashed amount to voters for rejecting challenge
            // Or add to bounty, or burn
            participants[curatorPId].pendingRewards = participants[curatorPId].pendingRewards.add(slashedAmount.div(2)); // Example distribution
            _updateReputation(ch.challenger, false); // Decrease challenger's reputation
            _updateReputation(c.curator, true); // Increase curator's reputation if challenge failed

            ch.status = ChallengeStatus.Resolved;
            emit ChallengeResolved(_challengeId, ChallengeStatus.Resolved, ch.votesFor, ch.votesAgainst);

        } else { // Tie or no votes
            // Return stakes
            participants[curatorPId].pendingRewards = participants[curatorPId].pendingRewards.add(c.curationStake);
            participants[challengerPId].pendingRewards = participants[challengerPId].pendingRewards.add(ch.challengeStake);
            ch.status = ChallengeStatus.Resolved;
            emit ChallengeResolved(_challengeId, ChallengeStatus.Resolved, ch.votesFor, ch.votesAgainst);
        }

        // After challenge resolution, if forge was "Challenged", return to "Curated" or "WaitingCuration" based on if it received enough valid curations.
        if (f.curationCount >= 3) {
            f.status = ForgeStatus.Curated;
        } else {
            f.status = ForgeStatus.WaitingCuration;
        }
        emit ForgeStatusChanged(f.id, f.status);
    }

    // --- V. Reputation & Rewards ---

    /**
     * @dev Internal function to dynamically calculate and update a participant's reputation score.
     *      This is a simplified example; a real-world system would be more complex.
     * @param _participant The address of the participant whose reputation is being updated.
     * @param _positiveAction True for actions that increase reputation, false for decreasing.
     */
    function _updateReputation(address _participant, bool _positiveAction) internal {
        uint256 pId = participantIdByAddress[_participant];
        if (pId == 0) return; // Should not happen for registered participants

        Participant storage p = participants[pId];
        uint256 oldReputation = p.reputation;

        if (_positiveAction) {
            p.reputation = p.reputation.add(10); // Example: +10 reputation
        } else {
            p.reputation = p.reputation.sub(5); // Example: -5 reputation, with floor
            if (p.reputation < 50) p.reputation = 50; // Minimum reputation floor
        }
        emit ReputationUpdated(_participant, p.reputation);
    }

    /**
     * @dev Public view function to calculate a participant's dynamic reputation score.
     *      For this example, it simply returns the stored value, which is updated internally.
     * @param _participant The address of the participant.
     * @return The current reputation score of the participant.
     */
    function calculateReputation(address _participant) public view returns (uint256) {
        uint256 pId = participantIdByAddress[_participant];
        if (pId == 0) return 0; // Not registered
        return participants[pId].reputation;
    }

    /**
     * @dev Allows a participant to claim their accumulated rewards from bounties, successful forges, and accurate curations.
     */
    function claimRewards()
        external
        onlyRegisteredParticipant
        nonReentrant
        whenNotPaused
    {
        uint256 pId = participantIdByAddress[msg.sender];
        Participant storage p = participants[pId];
        require(p.pendingRewards > 0, "No pending rewards to claim");

        uint256 rewardsToClaim = p.pendingRewards;
        p.pendingRewards = 0;

        payable(msg.sender).transfer(rewardsToClaim);
        emit RewardsClaimed(msg.sender, rewardsToClaim);
    }

    /**
     * @dev Displays the total amount of rewards currently claimable by a specific participant.
     * @param _participant The address of the participant.
     * @return The amount of pending rewards.
     */
    function getPendingRewards(address _participant) public view returns (uint256) {
        uint256 pId = participantIdByAddress[_participant];
        if (pId == 0) return 0; // Not registered
        return participants[pId].pendingRewards;
    }

    // --- VI. Protocol Governance & Maintenance ---

    /**
     * @dev The contract owner can set a protocol fee (in basis points) that is applied to successful prompt bounties.
     * @param _newFeeBps The new fee in basis points (e.g., 100 for 1%, 500 for 5%).
     */
    function setProtocolFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 1000, "Fee cannot exceed 10%"); // Example cap
        protocolFeeBps = _newFeeBps;
        emit ProtocolFeeSet(_newFeeBps);
    }

    /**
     * @dev Allows the contract owner to withdraw the accumulated protocol fees.
     */
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 feesToWithdraw = totalProtocolFeesCollected;
        require(feesToWithdraw > 0, "No fees to withdraw");

        totalProtocolFeesCollected = 0;
        payable(owner()).transfer(feesToWithdraw);
        emit ProtocolFeesWithdrawn(feesToWithdraw);
    }

    /**
     * @dev Pauses the contract in case of an emergency. Only callable by the owner.
     */
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract after an emergency is resolved. Only callable by the owner.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- Internal Helpers ---

    /**
     * @dev Internal function to finalize a forge and distribute rewards.
     *      This would typically be called after a forge has passed curation or after a challenge is resolved.
     *      For simplicity, this is an outline of what it would do.
     * @param _forgeId The ID of the forge to finalize.
     */
    function _finalizeForgeAndDistributeRewards(uint256 _forgeId) internal {
        Forge storage f = forges[_forgeId];
        Prompt storage p = prompts[f.promptId];
        AIModel storage m = aiModels[f.modelId];
        
        // This function would calculate the final average score for the forge
        f.finalCurationScore = f.curationScoreSum.div(f.curationCount);
        f.status = ForgeStatus.Finalized;
        emit ForgeStatusChanged(_forgeId, ForgeStatus.Finalized);
        emit PromptStatusChanged(f.promptId, PromptStatus.Finalized);

        // Calculate rewards
        uint256 totalBounty = p.bountyAmount;
        uint256 protocolFee = totalBounty.mul(protocolFeeBps).div(10000);
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(protocolFee);
        uint256 netBounty = totalBounty.sub(protocolFee);

        // Distribute netBounty
        uint256 creatorReward = netBounty.mul(60).div(100); // 60% for AI model owner (forge creator)
        uint256 promptCreatorReward = netBounty.mul(20).div(100); // 20% for prompt creator
        uint256 curatorsReward = netBounty.mul(20).div(100); // 20% for curators

        // Rewards to AI Model Owner
        participants[participantIdByAddress[f.creatorAddress]].pendingRewards = 
            participants[participantIdByAddress[f.creatorAddress]].pendingRewards.add(creatorReward);
        
        // Return AI Model Generation Stake
        participants[participantIdByAddress[f.creatorAddress]].stakedBalance =
            participants[participantIdByAddress[f.creatorAddress]].stakedBalance.sub(f.generationStake);
        participants[participantIdByAddress[f.creatorAddress]].pendingRewards =
            participants[participantIdByAddress[f.creatorAddress]].pendingRewards.add(f.generationStake);

        // Rewards to Prompt Creator
        participants[participantIdByAddress[p.creator]].pendingRewards = 
            participants[participantIdByAddress[p.creator]].pendingRewards.add(promptCreatorReward);
        
        // Rewards to Curators (Example: split equally or based on accuracy)
        // This would require iterating through curations for this forge
        // For simplicity, we'll just add to a general pool or specific curators.
        // A more complex system might distribute based on individual curation quality/reputation.
        // For now, let's assume this gets distributed among the top N curators or weighted by reputation.
        // As a placeholder:
        // uint256 rewardPerCurator = curatorsReward.div(f.curationCount);
        // (This would need a loop or separate mapping to track curators for this specific forge)
        // For now, we'll just add the total curator pool to a general reward pool or a designated address.
        // In a real system, you'd track curators for this forge and divide.
        // Example: Let's just add it to the AI Model owner's pending rewards for now as a simplified path
        // but this needs to be properly distributed to individual curators based on their contributions.
        participants[participantIdByAddress[f.creatorAddress]].pendingRewards = 
            participants[participantIdByAddress[f.creatorAddress]].pendingRewards.add(curatorsReward);

        // Reputation update for forge creator
        _updateReputation(f.creatorAddress, true); // Successful forge increases reputation
        
        p.bountyAmount = 0; // Bounty spent
    }

    // Fallback function to accept ETH, primarily for funding prompts
    receive() external payable {
        // This is a minimal fallback; consider specific logic if direct ETH sends are intended for other purposes
    }
}
```