This smart contract, **Cognitive Crucible**, is designed to be a decentralized platform for managing AI-generated digital artifacts. It introduces several advanced concepts:

1.  **Adaptive License Tokens (ALTs):** NFTs whose usage rights (licensing terms) dynamically change based on community engagement and the creator's reputation.
2.  **Reputation System:** A scoring mechanism for users (prompters, curators) and AI agents, influencing privileges and rewards.
3.  **AI Agent Integration:** A framework for registering and managing off-chain AI models that generate artifacts, with on-chain verification through content hashes.
4.  **Community Validation:** Mechanisms for users to endorse or challenge artifacts, feeding into the reputation and licensing systems.
5.  **Prediction Markets:** A gamified finance element where users can bet on the future success/quality of AI-generated artifacts.
6.  **On-chain Governance:** A basic system for the community (via GOVERNOR_ROLE) to propose and vote on protocol parameter changes.
7.  **Treasury & Reward System:** Incentivizing high-quality contributions and successful predictions.

---

## **I. Outline**

*   **A. Core Purpose:** To establish a decentralized and self-governing ecosystem for the creation, validation, ownership, and dynamic licensing of AI-generated digital content, fostering quality and innovation through reputation and economic incentives.
*   **B. Key Components:**
    *   **Prompt Management:** Users submit creative prompts for AI.
    *   **AI Agent Registry:** A whitelist for authenticated off-chain AI models/providers.
    *   **Artifact Minting & Dynamic Licensing (Adaptive License Token - ALT):** ERC721 NFTs representing AI outputs, with usage rights that evolve based on on-chain metrics.
    *   **Reputation System:** A mutable score for users (Prompters, Curators) and AI Agents, influencing their standing and permissions within the protocol.
    *   **Community Validation & Challenge Mechanism:** Curators (users with sufficient reputation) can endorse high-quality artifacts or challenge problematic ones, impacting reputation and license terms.
    *   **Prediction Market:** A sub-protocol where participants can stake funds on the future success or failure of an artifact's community acceptance.
    *   **Reward & Treasury System:** A mechanism to accumulate protocol fees and distribute rewards to contributors (prompters, AI agents, successful curators/predictors).
    *   **Governance:** A basic on-chain voting system allowing privileged roles to adjust protocol parameters.

---

## **II. Function Summary**

**Core Contract & Access Control:**
1.  `constructor()`: Initializes the contract, sets the ERC721 name and symbol, and grants `DEFAULT_ADMIN_ROLE` and `GOVERNOR_ROLE` to the deployer.
2.  `registerAI_Agent(address _agentAddress, string memory _name)`: (Admin) Registers an address as an approved AI agent, granting them the `AI_AGENT_ROLE`.
3.  `deregisterAI_Agent(address _agentAddress)`: (Admin) Revokes the `AI_AGENT_ROLE` from an address.

**Prompt & Artifact Management:**
4.  `submitPrompt(string memory _promptURI, bytes32 _promptHash)`: Allows any user to submit a creative prompt, storing its URI and cryptographic hash.
5.  `mintArtifact(uint256 _promptId, address _aiAgent, string memory _artifactURI, bytes32 _artifactHash)`: (AI Agent) Allows a registered AI agent to mint an Adaptive License Token (ALT) NFT, linking it to a prompt and initial artifact data.
6.  `updateArtifactMetadata(uint256 _tokenId, string memory _newURI)`: (Owner) Allows the owner of an ALT to update its associated metadata URI.
7.  `getArtifactDetails(uint256 _tokenId)`: (View) Retrieves all stored details for a given artifact, including its current dynamic license terms.

**Reputation & Community Validation:**
8.  `endorseArtifact(uint256 _tokenId)`: (Curator) Allows users with sufficient reputation to endorse an artifact, increasing its endorsement score and boosting reputations of the endorser, AI agent, and prompter. Triggers license recalculation.
9.  `challengeArtifact(uint256 _tokenId, string memory _reasonURI)`: (Curator) Allows users with sufficient reputation to challenge an artifact, marking it as disputed and providing a reason.
10. `resolveChallenge(uint256 _tokenId, bool _isChallengedValid)`: (Governor) Resolves a pending challenge, adjusting reputations and artifact scores based on the outcome (valid or invalid challenge). Triggers license recalculation.
11. `getReputation(address _user)`: (View) Returns the current reputation score for a specified address (user or AI agent).

**Dynamic Licensing (ALT Specific):**
12. `_updateLicenseTerms(uint256 _tokenId)`: (Internal) Recalculates and updates an artifact's license terms based on its endorsement/challenge scores and the AI agent's reputation. Emits `LicenseTermsUpdated` if changes occur.
13. `getLicenseTerms(uint256 _tokenId)`: (View) Retrieves the current dynamic license terms for a specific ALT.
14. `requestLicenseUpgrade(uint256 _tokenId)`: (Owner) Allows the owner to trigger a recalculation of the artifact's license terms (manually calling `_updateLicenseTerms`).

**Prediction Market & Incentives:**
15. `createPredictionMarket(uint256 _tokenId, uint256 _duration, int256 _targetEndorsementScore)`: (Governor) Creates a prediction market for an artifact, allowing users to bet on its future endorsement score.
16. `placePrediction(uint256 _marketId, bool _willSucceed)`: (Payable) Allows a user to place a bet (ETH) on a prediction market, indicating whether the artifact will meet its target score.
17. `resolvePredictionMarket(uint256 _marketId)`: Resolves a prediction market once its duration has passed, determining the winning side based on the artifact's actual performance.
18. `claimPredictionWinnings(uint256 _marketId)`: Allows winning participants to claim their share of the prediction market's pool, credited to their accumulated rewards.

**Reward & Treasury:**
19. `claimRewards(address _recipient)`: Allows a user to claim their accumulated rewards (ETH) from the contract's treasury.
20. `depositToTreasury()`: (Payable) Allows anyone to deposit ETH into the protocol's treasury.
21. `withdrawFromTreasury(address _to, uint256 _amount)`: (Governor) Allows the Governor to withdraw funds from the treasury to a specified address.

**Governance:**
22. `proposeParameterChange(bytes32 _paramNameHash, uint256 _newValue)`: (Governor) Proposes a change to a configurable system parameter (e.g., `ENDORSE_WEIGHT`, `MIN_REPUTATION_FOR_CURATION`).
23. `voteOnProposal(uint256 _proposalId, bool _for)`: Allows users to vote 'yes' or 'no' on an active governance proposal.
24. `executeProposal(uint256 _proposalId)`: (Governor) Executes a passed proposal after its voting period, applying the proposed parameter change.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom Errors
error InvalidAI_Agent();
error PromptNotFound(uint256 promptId);
error ArtifactNotFound(uint256 tokenId);
error NotAnAIAgent();
error NotOwnerOrApproved();
error ChallengeAlreadyResolved();
error InvalidChallengeResolution();
error PredictionMarketNotFound(uint256 marketId);
error MarketAlreadyActiveOrResolved();
error NotEnoughFunds();
error NoWinningsToClaim();
error NoRewardsToClaim();
error NotAuthorized();
error ProposalNotFound(uint256 proposalId);
error ProposalAlreadyVoted();
error ProposalVotingPeriodNotEnded();
error ProposalFailedToPass();

contract CognitiveCrucible is ERC721, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant AI_AGENT_ROLE = keccak256("AI_AGENT_ROLE"); // For registered off-chain AI models

    // --- State Variables ---

    // Prompts
    struct Prompt {
        address prompter;
        string promptURI; // URI to prompt content (e.g., IPFS)
        bytes32 promptHash; // Hash of the prompt content for verification
        uint256 submissionTime;
    }
    Counters.Counter private _promptIds;
    mapping(uint256 => Prompt) public prompts;

    // Artifacts (Adaptive License Tokens - ALTs)
    struct Artifact {
        uint256 promptId;
        address aiAgent;
        string artifactURI; // URI to artifact content (e.g., IPFS)
        bytes32 artifactHash; // Hash of the artifact content for verification
        uint256 endorsementScore; // Score from community endorsements
        uint256 challengeScore; // Score from community challenges
        bool challengeActive; // True if a challenge is pending resolution
        string challengeReasonURI; // URI to the reason for challenge, if active
        address challenger; // Who initiated the current challenge
        uint256 mintTime;
        LicenseTerms currentLicenseTerms; // Current dynamic license applied
    }
    Counters.Counter private _tokenIds; // Used for NFT token IDs
    mapping(uint256 => Artifact) public artifacts; // tokenId => Artifact details

    // Reputation System
    // int256 allows for negative reputation if significant penalties apply
    mapping(address => int256) public reputationScores; // User/AI Agent address => Reputation score

    // Dynamic License Terms for ALTs
    struct LicenseTerms {
        bool commercialUseAllowed;
        bool derivativeWorksAllowed;
        bool attributionRequired;
        uint16 royaltyFeeBPS; // Basis points (e.g., 100 = 1%) for secondary sales/usage fees
    }

    // Prediction Markets
    struct PredictionMarket {
        uint256 tokenId;
        uint256 creationTime;
        uint256 duration; // Duration in seconds
        bool resolved;
        int256 targetEndorsementScore; // Target endorsement score for 'Yes' outcome
        uint256 totalYesAmount; // Total ETH staked on 'Yes'
        uint256 totalNoAmount;  // Total ETH staked on 'No'
        mapping(address => uint256) yesBets; // User => amount staked on 'Yes'
        mapping(address => uint256) noBets;  // User => amount staked on 'No'
    }
    Counters.Counter private _marketIds;
    mapping(uint256 => PredictionMarket) public predictionMarkets;

    // Treasury for rewards and protocol funds
    uint256 public treasuryBalance;

    // Accumulated rewards for users (e.g., from prediction market winnings, reputation bonuses)
    mapping(address => uint256) public accumulatedRewards;

    // Governance Proposals
    struct Proposal {
        bytes32 paramNameHash; // Keccak256 hash of the parameter name (e.g., keccak256("ENDORSE_WEIGHT"))
        uint256 newValue;
        uint256 proposalEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) hasVoted; // Voter address => true if voted
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // Example duration for proposal voting

    // --- Configurable Parameters (Adjustable by Governance) ---
    uint256 public ENDORSE_WEIGHT = 10; // Reputation points gained/lost per endorsement/challenge resolution
    uint256 public CHALLENGE_WEIGHT = 15; // Penalty for artifact/AI agent on valid challenge
    uint256 public MIN_REPUTATION_FOR_CURATION = 50; // Minimum reputation to endorse/challenge
    // uint256 public AI_AGENT_BOND_AMOUNT = 0.1 ether; // Placeholder: could be a bond required to register AI agent

    // --- Events ---
    event AIPromptSubmitted(uint256 indexed promptId, address indexed prompter, string promptURI);
    event ArtifactMinted(uint256 indexed tokenId, uint256 indexed promptId, address indexed aiAgent, string artifactURI, bytes32 artifactHash);
    event ArtifactEndorsed(uint256 indexed tokenId, address indexed endorser, uint256 newEndorsementScore);
    event ArtifactChallenged(uint256 indexed tokenId, address indexed challenger, string reasonURI);
    event ChallengeResolved(uint256 indexed tokenId, bool isChallengedValid, address resolver);
    event ReputationUpdated(address indexed user, int256 newReputation);
    event LicenseTermsUpdated(uint256 indexed tokenId, LicenseTerms newTerms);
    event AI_AgentRegistered(address indexed aiAgent, string name);
    event AI_AgentDeregistered(address indexed aiAgent);
    event PredictionMarketCreated(uint256 indexed marketId, uint256 indexed tokenId, uint256 duration, int256 targetEndorsementScore);
    event PredictionPlaced(uint256 indexed marketId, address indexed predictor, bool willSucceed, uint256 amount);
    event PredictionMarketResolved(uint256 indexed marketId, bool targetReached);
    event WinningsClaimed(uint256 indexed marketId, address indexed winner, uint256 amount);
    event RewardsClaimed(address indexed recipient, uint256 amount);
    event DepositToTreasury(address indexed depositor, uint256 amount);
    event WithdrawalFromTreasury(address indexed recipient, uint256 amount);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 paramNameHash, uint256 newValue);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Constructor ---
    constructor() ERC721("Cognitive Crucible ALT", "CCALT") {
        // Grant default admin and governor roles to the deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNOR_ROLE, msg.sender);
        // AI_AGENT_ROLE and CURATOR_ROLE (via reputation) are dynamic
    }

    // --- Modifiers ---
    modifier onlyAI_Agent() {
        if (!hasRole(AI_AGENT_ROLE, msg.sender)) revert NotAnAIAgent();
        _;
    }

    modifier onlyCurator() {
        if (reputationScores[msg.sender] < int256(MIN_REPUTATION_FOR_CURATION)) revert NotAuthorized();
        _;
    }

    // --- Admin/Governance Functions ---

    /**
     * @dev Registers an off-chain AI agent by granting them the AI_AGENT_ROLE.
     *      Only callable by an address with the ADMIN_ROLE.
     *      In a more advanced system, this could require a stake/bond.
     * @param _agentAddress The address of the AI agent to register.
     * @param _name A descriptive name for the AI agent.
     */
    function registerAI_Agent(address _agentAddress, string memory _name) public onlyRole(ADMIN_ROLE) {
        // Optional: require(msg.value >= AI_AGENT_BOND_AMOUNT, "Must provide AI agent bond");
        _grantRole(AI_AGENT_ROLE, _agentAddress);
        emit AI_AgentRegistered(_agentAddress, _name);
    }

    /**
     * @dev Deregisters an AI agent by revoking their AI_AGENT_ROLE.
     *      Only callable by an address with the ADMIN_ROLE.
     * @param _agentAddress The address of the AI agent to deregister.
     */
    function deregisterAI_Agent(address _agentAddress) public onlyRole(ADMIN_ROLE) {
        if (!hasRole(AI_AGENT_ROLE, _agentAddress)) revert InvalidAI_Agent();
        _revokeRole(AI_AGENT_ROLE, _agentAddress);
        emit AI_AgentDeregistered(_agentAddress);
    }

    // --- Prompt Management ---

    /**
     * @dev Allows any user to submit a creative prompt to the system.
     *      The prompt content itself is stored off-chain (e.g., IPFS) and referenced by a URI and hash.
     * @param _promptURI URI pointing to the prompt content.
     * @param _promptHash Cryptographic hash of the prompt content for integrity verification.
     * @return The ID of the newly submitted prompt.
     */
    function submitPrompt(string memory _promptURI, bytes32 _promptHash) public returns (uint256) {
        _promptIds.increment();
        uint256 newPromptId = _promptIds.current();
        prompts[newPromptId] = Prompt({
            prompter: msg.sender,
            promptURI: _promptURI,
            promptHash: _promptHash,
            submissionTime: block.timestamp
        });
        emit AIPromptSubmitted(newPromptId, msg.sender, _promptURI);
        return newPromptId;
    }

    // --- Artifact (Adaptive License Token - ALT) Management ---

    /**
     * @dev Allows a registered AI agent to mint a new artifact (ALT) from a specific prompt.
     *      The artifact content is stored off-chain and referenced by a URI and hash.
     *      Mints the ALT to the AI agent who generated it.
     * @param _promptId The ID of the prompt used for generation.
     * @param _aiAgent The address of the AI agent who generated the artifact (must be msg.sender).
     * @param _artifactURI URI pointing to the artifact content.
     * @param _artifactHash Cryptographic hash of the artifact content.
     * @return The ID of the newly minted artifact (ALT).
     */
    function mintArtifact(uint256 _promptId, address _aiAgent, string memory _artifactURI, bytes32 _artifactHash)
        public
        onlyAI_Agent
        returns (uint256)
    {
        if (prompts[_promptId].prompter == address(0)) revert PromptNotFound(_promptId);
        if (_aiAgent != msg.sender) revert NotAnAIAgent(); // Ensure the AI agent minting is itself

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        // Initial, most restrictive license terms
        LicenseTerms memory initialTerms = LicenseTerms({
            commercialUseAllowed: false,
            derivativeWorksAllowed: false,
            attributionRequired: true, // Always require attribution
            royaltyFeeBPS: 0
        });

        artifacts[newItemId] = Artifact({
            promptId: _promptId,
            aiAgent: _aiAgent,
            artifactURI: _artifactURI,
            artifactHash: _artifactHash,
            endorsementScore: 0,
            challengeScore: 0,
            challengeActive: false,
            challengeReasonURI: "",
            challenger: address(0),
            mintTime: block.timestamp,
            currentLicenseTerms: initialTerms
        });

        _mint(msg.sender, newItemId); // Mints the NFT to the AI agent who generated it

        emit ArtifactMinted(newItemId, _promptId, _aiAgent, _artifactURI, _artifactHash);
        return newItemId;
    }

    /**
     * @dev Allows the current owner of an artifact to update its associated metadata URI.
     *      Useful for dynamic NFTs where the content might evolve over time.
     * @param _tokenId The ID of the artifact to update.
     * @param _newURI The new URI pointing to updated content/metadata.
     */
    function updateArtifactMetadata(uint256 _tokenId, string memory _newURI) public {
        if (artifacts[_tokenId].aiAgent == address(0)) revert ArtifactNotFound(_tokenId);
        if (ownerOf(_tokenId) != msg.sender) revert NotOwnerOrApproved();

        artifacts[_tokenId].artifactURI = _newURI;
        // Optionally, update hash as well if content changes significantly:
        // artifacts[_tokenId].artifactHash = keccak256(abi.encodePacked(_newURI));
    }

    /**
     * @dev Retrieves all detailed information about a specific artifact.
     * @param _tokenId The ID of the artifact.
     * @return A tuple containing all stored artifact details.
     */
    function getArtifactDetails(uint256 _tokenId)
        public
        view
        returns (
            uint256 promptId,
            address aiAgent,
            string memory artifactURI,
            bytes32 artifactHash,
            uint256 endorsementScore,
            uint256 challengeScore,
            bool challengeActive,
            string memory challengeReasonURI,
            address challenger,
            uint256 mintTime,
            LicenseTerms memory licenseTerms
        )
    {
        Artifact storage artifact = artifacts[_tokenId];
        if (artifact.aiAgent == address(0)) revert ArtifactNotFound(_tokenId);

        return (
            artifact.promptId,
            artifact.aiAgent,
            artifact.artifactURI,
            artifact.artifactHash,
            artifact.endorsementScore,
            artifact.challengeScore,
            artifact.challengeActive,
            artifact.challengeReasonURI,
            artifact.challenger,
            artifact.mintTime,
            artifact.currentLicenseTerms
        );
    }

    // --- Reputation & Community Validation ---

    /**
     * @dev Allows a curator (user with sufficient reputation) to endorse an artifact.
     *      Increases the artifact's endorsement score and updates reputations of involved parties.
     *      Triggers an update to the artifact's dynamic license terms.
     * @param _tokenId The ID of the artifact to endorse.
     */
    function endorseArtifact(uint256 _tokenId) public nonReentrant onlyCurator {
        Artifact storage artifact = artifacts[_tokenId];
        if (artifact.aiAgent == address(0)) revert ArtifactNotFound(_tokenId);
        if (artifact.challengeActive) revert InvalidChallengeResolution(); // Cannot endorse a currently challenged artifact

        artifact.endorsementScore = artifact.endorsementScore.add(1);

        // Update reputations: endorser gains, AI agent gains, prompter gains
        reputationScores[msg.sender] = reputationScores[msg.sender].add(int256(ENDORSE_WEIGHT));
        reputationScores[artifact.aiAgent] = reputationScores[artifact.aiAgent].add(int256(ENDORSE_WEIGHT));
        reputationScores[prompts[artifact.promptId].prompter] = reputationScores[prompts[artifact.promptId].prompter].add(int256(ENDORSE_WEIGHT).div(2));

        _updateLicenseTerms(_tokenId); // Recalculate license based on new score

        emit ArtifactEndorsed(_tokenId, msg.sender, artifact.endorsementScore);
        emit ReputationUpdated(msg.sender, reputationScores[msg.sender]);
        emit ReputationUpdated(artifact.aiAgent, reputationScores[artifact.aiAgent]);
        emit ReputationUpdated(prompts[artifact.promptId].prompter, reputationScores[prompts[artifact.promptId].prompter]);
    }

    /**
     * @dev Allows a curator (user with sufficient reputation) to challenge an artifact.
     *      Marks the artifact as challenged and records the challenger and reason.
     * @param _tokenId The ID of the artifact to challenge.
     * @param _reasonURI URI pointing to the detailed reason for the challenge.
     */
    function challengeArtifact(uint256 _tokenId, string memory _reasonURI) public nonReentrant onlyCurator {
        Artifact storage artifact = artifacts[_tokenId];
        if (artifact.aiAgent == address(0)) revert ArtifactNotFound(_tokenId);
        if (artifact.challengeActive) revert ChallengeAlreadyResolved(); // Already challenged

        artifact.challengeActive = true;
        artifact.challengeReasonURI = _reasonURI;
        artifact.challenger = msg.sender;

        emit ArtifactChallenged(_tokenId, msg.sender, _reasonURI);
    }

    /**
     * @dev Resolves an ongoing challenge for an artifact. Only callable by an address with GOVERNOR_ROLE.
     *      Adjusts reputations and artifact scores based on whether the challenge was valid or not.
     *      Triggers an update to the artifact's dynamic license terms.
     * @param _tokenId The ID of the artifact with the challenge.
     * @param _isChallengedValid True if the challenge is deemed valid, false otherwise.
     */
    function resolveChallenge(uint256 _tokenId, bool _isChallengedValid) public nonReentrant onlyRole(GOVERNOR_ROLE) {
        Artifact storage artifact = artifacts[_tokenId];
        if (artifact.aiAgent == address(0)) revert ArtifactNotFound(_tokenId);
        if (!artifact.challengeActive) revert InvalidChallengeResolution(); // No active challenge to resolve

        artifact.challengeActive = false; // Mark challenge as resolved
        artifact.challengeReasonURI = "";
        address currentChallenger = artifact.challenger;
        artifact.challenger = address(0); // Reset challenger

        if (_isChallengedValid) {
            // Challenge was valid: decrease artifact/AI agent/prompter reputation, increase challenger rep
            artifact.challengeScore = artifact.challengeScore.add(1);

            reputationScores[artifact.aiAgent] = reputationScores[artifact.aiAgent].sub(int256(CHALLENGE_WEIGHT));
            reputationScores[prompts[artifact.promptId].prompter] = reputationScores[prompts[artifact.promptId].prompter].sub(int256(CHALLENGE_WEIGHT).div(2)); // Prompter less affected
            reputationScores[currentChallenger] = reputationScores[currentChallenger].add(int256(CHALLENGE_WEIGHT));

            emit ReputationUpdated(artifact.aiAgent, reputationScores[artifact.aiAgent]);
            emit ReputationUpdated(prompts[artifact.promptId].prompter, reputationScores[prompts[artifact.promptId].prompter]);
            emit ReputationUpdated(currentChallenger, reputationScores[currentChallenger]);

        } else {
            // Challenge was invalid: decrease challenger reputation, potentially slightly increase artifact/AI agent rep
            reputationScores[currentChallenger] = reputationScores[currentChallenger].sub(int256(CHALLENGE_WEIGHT).div(2));
            reputationScores[artifact.aiAgent] = reputationScores[artifact.aiAgent].add(int256(ENDORSE_WEIGHT).div(2));
            reputationScores[prompts[artifact.promptId].prompter] = reputationScores[prompts[artifact.promptId].prompter].add(int256(ENDORSE_WEIGHT).div(4));

            emit ReputationUpdated(currentChallenger, reputationScores[currentChallenger]);
            emit ReputationUpdated(artifact.aiAgent, reputationScores[artifact.aiAgent]);
            emit ReputationUpdated(prompts[artifact.promptId].prompter, reputationScores[prompts[artifact.promptId].prompter]);
        }

        _updateLicenseTerms(_tokenId); // Recalculate license based on new scores/resolution

        emit ChallengeResolved(_tokenId, _isChallengedValid, msg.sender);
    }

    /**
     * @dev Retrieves the current reputation score of a user or AI agent.
     * @param _user The address of the user or AI agent.
     * @return The reputation score.
     */
    function getReputation(address _user) public view returns (int256) {
        return reputationScores[_user];
    }

    // --- Dynamic Licensing (ALT) ---

    /**
     * @dev Internal function to dynamically update the license terms of an artifact.
     *      This function is called automatically after significant events (endorsements, challenges).
     *      The logic for determining license terms can be adjusted via governance.
     * @param _tokenId The ID of the artifact.
     */
    function _updateLicenseTerms(uint256 _tokenId) internal {
        Artifact storage artifact = artifacts[_tokenId];
        int256 netScore = int256(artifact.endorsementScore) - int256(artifact.challengeScore);
        int256 aiAgentRep = reputationScores[artifact.aiAgent];

        LicenseTerms memory newTerms = artifact.currentLicenseTerms; // Start with current terms

        // Example logic for dynamic terms:
        // Higher net score and AI agent reputation lead to more permissive licenses.
        // This logic can be made more sophisticated (e.g., tier-based, configurable thresholds).
        if (netScore > 10 && aiAgentRep > 100) {
            newTerms.commercialUseAllowed = true;
            newTerms.derivativeWorksAllowed = true;
            newTerms.royaltyFeeBPS = 100; // 1% royalty
        } else if (netScore > 5 || aiAgentRep > 50) {
            newTerms.commercialUseAllowed = false; // Keep it restrictive for commercial
            newTerms.derivativeWorksAllowed = true;
            newTerms.royaltyFeeBPS = 50; // 0.5% royalty
        } else {
            newTerms.commercialUseAllowed = false;
            newTerms.derivativeWorksAllowed = false;
            newTerms.royaltyFeeBPS = 0;
        }
        newTerms.attributionRequired = true; // Always require attribution

        // Only update state and emit event if terms have actually changed
        if (newTerms.commercialUseAllowed != artifact.currentLicenseTerms.commercialUseAllowed ||
            newTerms.derivativeWorksAllowed != artifact.currentLicenseTerms.derivativeWorksAllowed ||
            newTerms.attributionRequired != artifact.currentLicenseTerms.attributionRequired ||
            newTerms.royaltyFeeBPS != artifact.currentLicenseTerms.royaltyFeeBPS)
        {
            artifact.currentLicenseTerms = newTerms;
            emit LicenseTermsUpdated(_tokenId, newTerms);
        }
    }

    /**
     * @dev Retrieves the current dynamic license terms for a specific artifact.
     * @param _tokenId The ID of the artifact.
     * @return The current LicenseTerms struct associated with the artifact.
     */
    function getLicenseTerms(uint256 _tokenId) public view returns (LicenseTerms memory) {
        if (artifacts[_tokenId].aiAgent == address(0)) revert ArtifactNotFound(_tokenId);
        return artifacts[_tokenId].currentLicenseTerms;
    }

    /**
     * @dev Allows the owner of an artifact to manually request a license upgrade review.
     *      This simply triggers the internal `_updateLicenseTerms` function.
     *      In a more complex system, this could involve a fee or a governance vote.
     * @param _tokenId The ID of the artifact.
     */
    function requestLicenseUpgrade(uint256 _tokenId) public nonReentrant {
        if (ownerOf(_tokenId) != msg.sender) revert NotOwnerOrApproved();
        _updateLicenseTerms(_tokenId); // Recalculates and applies new terms based on current scores
    }

    // --- Prediction Market Functions ---

    /**
     * @dev Creates a prediction market for a specific artifact's future endorsement performance.
     *      Only callable by an address with the GOVERNOR_ROLE.
     * @param _tokenId The ID of the artifact to predict on.
     * @param _duration The duration of the prediction market in seconds.
     * @param _targetEndorsementScore The endorsement score target to predict 'Yes' on.
     * @return The ID of the newly created prediction market.
     */
    function createPredictionMarket(uint256 _tokenId, uint256 _duration, int256 _targetEndorsementScore)
        public
        onlyRole(GOVERNOR_ROLE)
        returns (uint256)
    {
        if (artifacts[_tokenId].aiAgent == address(0)) revert ArtifactNotFound(_tokenId);
        
        _marketIds.increment();
        uint256 newMarketId = _marketIds.current();

        predictionMarkets[newMarketId] = PredictionMarket({
            tokenId: _tokenId,
            creationTime: block.timestamp,
            duration: _duration,
            resolved: false,
            targetEndorsementScore: _targetEndorsementScore,
            totalYesAmount: 0,
            totalNoAmount: 0
            // mappings `yesBets` and `noBets` are implicitly initialized
        });

        emit PredictionMarketCreated(newMarketId, _tokenId, _duration, _targetEndorsementScore);
        return newMarketId;
    }

    /**
     * @dev Allows users to place a prediction (bet) on an active market.
     *      The staked ETH goes into the protocol's treasury.
     * @param _marketId The ID of the prediction market.
     * @param _willSucceed True if predicting the artifact will reach the target score, false otherwise.
     */
    function placePrediction(uint256 _marketId, bool _willSucceed) public payable nonReentrant {
        PredictionMarket storage market = predictionMarkets[_marketId];
        if (market.tokenId == 0) revert PredictionMarketNotFound(_marketId);
        if (market.resolved || block.timestamp >= market.creationTime + market.duration) revert MarketAlreadyActiveOrResolved();
        if (msg.value == 0) revert NotEnoughFunds();

        if (_willSucceed) {
            market.yesBets[msg.sender] = market.yesBets[msg.sender].add(msg.value);
            market.totalYesAmount = market.totalYesAmount.add(msg.value);
        } else {
            market.noBets[msg.sender] = market.noBets[msg.sender].add(msg.value);
            market.totalNoAmount = market.totalNoAmount.add(msg.value);
        }

        treasuryBalance = treasuryBalance.add(msg.value); // Funds go to treasury

        emit PredictionPlaced(_marketId, msg.sender, _willSucceed, msg.value);
    }

    /**
     * @dev Resolves a prediction market if its duration has passed.
     *      Determines the winning side based on the artifact's actual endorsement score.
     *      Sets the market as resolved, making winnings claimable.
     * @param _marketId The ID of the prediction market.
     */
    function resolvePredictionMarket(uint256 _marketId) public nonReentrant {
        PredictionMarket storage market = predictionMarkets[_marketId];
        if (market.tokenId == 0) revert PredictionMarketNotFound(_marketId);
        if (market.resolved) revert MarketAlreadyActiveOrResolved(); // Already resolved
        if (block.timestamp < market.creationTime + market.duration) revert MarketAlreadyActiveOrResolved(); // Not yet ended

        Artifact storage artifact = artifacts[market.tokenId];
        bool targetReached = int256(artifact.endorsementScore) >= market.targetEndorsementScore;

        market.resolved = true; // Mark as resolved

        emit PredictionMarketResolved(_marketId, targetReached);
    }

    /**
     * @dev Allows a user to claim their winnings from a resolved prediction market.
     *      Winnings include their original stake plus a proportional share of the losing pool.
     * @param _marketId The ID of the prediction market.
     */
    function claimPredictionWinnings(uint256 _marketId) public nonReentrant {
        PredictionMarket storage market = predictionMarkets[_marketId];
        if (market.tokenId == 0) revert PredictionMarketNotFound(_marketId);
        if (!market.resolved) revert MarketAlreadyActiveOrResolved(); // Not resolved yet

        Artifact storage artifact = artifacts[market.tokenId];
        bool targetReached = int256(artifact.endorsementScore) >= market.targetEndorsementScore;

        uint256 userBet;
        uint256 totalWinningBets;
        uint256 totalLosingBets;

        if (targetReached) {
            userBet = market.yesBets[msg.sender];
            totalWinningBets = market.totalYesAmount;
            totalLosingBets = market.totalNoAmount;
        } else {
            userBet = market.noBets[msg.sender];
            totalWinningBets = market.totalNoAmount;
            totalLosingBets = market.totalYesAmount;
        }

        if (userBet == 0) revert NoWinningsToClaim(); // User had no bet on the winning side or already claimed

        // Calculate winnings: original bet + proportional share of the losing pool
        // Avoid division by zero if totalWinningBets is zero (shouldn't happen if userBet > 0)
        uint256 winnings = userBet.add(totalWinningBets > 0 ? userBet.mul(totalLosingBets).div(totalWinningBets) : 0);

        // Reset user's bet to prevent double claims
        if (targetReached) {
            market.yesBets[msg.sender] = 0;
        } else {
            market.noBets[msg.sender] = 0;
        }

        accumulatedRewards[msg.sender] = accumulatedRewards[msg.sender].add(winnings);
        treasuryBalance = treasuryBalance.sub(winnings); // Subtract from treasury balance

        emit WinningsClaimed(_marketId, msg.sender, winnings);
    }

    // --- Reward & Treasury Functions ---

    /**
     * @dev Allows a user to claim their accumulated rewards (e.g., from prediction market winnings,
     *      or future reputation-based bonuses).
     * @param _recipient The address to which rewards should be paid. Can be msg.sender or another address if called by ADMIN_ROLE.
     */
    function claimRewards(address _recipient) public nonReentrant {
        if (_recipient != msg.sender && !hasRole(ADMIN_ROLE, msg.sender)) revert NotAuthorized(); // Only admin can claim for others
        uint256 amount = accumulatedRewards[_recipient];
        if (amount == 0) revert NoRewardsToClaim();
        if (amount > treasuryBalance) revert NotEnoughFunds(); // Should ideally not happen if funds are managed correctly

        accumulatedRewards[_recipient] = 0; // Reset claimed amount
        treasuryBalance = treasuryBalance.sub(amount);

        (bool success, ) = payable(_recipient).call{value: amount}("");
        require(success, "Reward transfer failed");

        emit RewardsClaimed(_recipient, amount);
    }

    /**
     * @dev Allows anyone to deposit ETH into the protocol's main treasury.
     *      These funds can be used for rewards or future protocol operations.
     */
    function depositToTreasury() public payable {
        if (msg.value == 0) revert NotEnoughFunds();
        treasuryBalance = treasuryBalance.add(msg.value);
        emit DepositToTreasury(msg.sender, msg.value);
    }

    /**
     * @dev Allows an address with the GOVERNOR_ROLE to withdraw funds from the treasury.
     *      In a full DAO, this would typically be part of a governance proposal.
     * @param _to The recipient address for the withdrawal.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawFromTreasury(address _to, uint256 _amount) public nonReentrant onlyRole(GOVERNOR_ROLE) {
        if (_amount == 0 || _amount > treasuryBalance) revert NotEnoughFunds();
        treasuryBalance = treasuryBalance.sub(_amount);

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Withdrawal failed");

        emit WithdrawalFromTreasury(_to, _amount);
    }

    // --- Governance Functions ---

    /**
     * @dev Proposes a change to a configurable system parameter. Only addresses with GOVERNOR_ROLE can propose.
     *      The change requires a community vote to be enacted.
     * @param _paramNameHash Keccak256 hash of the parameter name (e.g., `keccak256("ENDORSE_WEIGHT")`).
     * @param _newValue The new value proposed for the parameter.
     * @return The ID of the newly created proposal.
     */
    function proposeParameterChange(bytes32 _paramNameHash, uint256 _newValue) public onlyRole(GOVERNOR_ROLE) returns (uint256) {
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            paramNameHash: _paramNameHash,
            newValue: _newValue,
            proposalEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            yesVotes: 0,
            noVotes: 0,
            executed: false
            // hasVoted mapping implicitly initialized
        });

        emit ParameterChangeProposed(newProposalId, _paramNameHash, _newValue);
        return newProposalId;
    }

    /**
     * @dev Allows any user to vote on an active governance proposal.
     *      In a more complex DAO, voting power could be weighted by token holdings or reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _for) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.paramNameHash == bytes32(0)) revert ProposalNotFound(_proposalId);
        if (proposal.executed) revert ProposalAlreadyVoted(); // Cannot vote on executed proposals
        if (block.timestamp >= proposal.proposalEndTime) revert ProposalVotingPeriodNotEnded(); // Voting period has ended
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        proposal.hasVoted[msg.sender] = true;
        if (_for) {
            proposal.yesVotes = proposal.yesVotes.add(1);
        } else {
            proposal.noVotes = proposal.noVotes.add(1);
        }
        emit ProposalVoted(_proposalId, msg.sender, _for);
    }

    /**
     * @dev Executes a passed governance proposal. Only callable by an address with GOVERNOR_ROLE.
     *      Requires the voting period to be over and a majority of 'yes' votes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyRole(GOVERNOR_ROLE) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.paramNameHash == bytes32(0)) revert ProposalNotFound(_proposalId);
        if (proposal.executed) revert ProposalAlreadyVoted(); // Already executed
        if (block.timestamp < proposal.proposalEndTime) revert ProposalVotingPeriodNotEnded(); // Voting period not ended

        // Simple majority check: yes votes must strictly exceed no votes
        if (proposal.yesVotes <= proposal.noVotes) revert ProposalFailedToPass();

        // Execute the parameter change based on its hash
        if (proposal.paramNameHash == keccak256("ENDORSE_WEIGHT")) {
            ENDORSE_WEIGHT = proposal.newValue;
        } else if (proposal.paramNameHash == keccak256("CHALLENGE_WEIGHT")) {
            CHALLENGE_WEIGHT = proposal.newValue;
        } else if (proposal.paramNameHash == keccak256("MIN_REPUTATION_FOR_CURATION")) {
            MIN_REPUTATION_FOR_CURATION = proposal.newValue;
        }
        // Add more `else if` blocks here for other configurable parameters

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }
}
```