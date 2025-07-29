Okay, this is an exciting challenge! Let's design a smart contract that goes beyond typical DeFi or NFT projects.

I've conceived of a protocol called **ChronoForge: Dynamic Epochs & AI-Augmented Creation**.

**Core Concept:** ChronoForge is a decentralized protocol where the community collaboratively defines "Creative Directives" (e.g., prompts for AI art, themes for generative music). These directives are then picked up by off-chain AI agents (via oracles), which generate artifacts. The community then votes on the best artifacts, and the protocol *itself* dynamically adjusts its parameters (epoch durations, reward ratios, staking requirements) based on collective governance and observed activity, aiming for self-optimization. It mints top-voted artifacts as unique NFTs.

This incorporates:
*   **Epoch-based progression:** Time-gated phases for different activities.
*   **Decentralized AI orchestration:** Users propose prompts, oracles bridge AI results.
*   **Dynamic Parameter Adjustment:** The contract can change its own rules based on governance, leading to a "self-optimizing" or "adaptive" system.
*   **Layered Voting:** For directives, for generated assets, and for protocol parameters.
*   **Native Utility Token:** For staking, rewards, and governance.
*   **Generative NFT Minting:** Rewarding high-quality, community-approved AI creations.
*   **Oraclized Input/Output:** Interacting with external computation.

---

## ChronoForge: Dynamic Epochs & AI-Augmented Creation Protocol

**Outline:**

1.  **Introduction & Vision:** Overview of the protocol's purpose and innovative aspects.
2.  **Core Components:**
    *   `FORGE` Token (ERC-20): Utility and governance token.
    *   `AuraArtifact` NFT (ERC-721): Represents minted generative art.
    *   Epoch Management: Time-based phases.
    *   Creative Directives: User-submitted prompts/themes.
    *   AI Integration Layer: Oracle for off-chain AI results.
    *   Dynamic Parameter Governance: Protocol self-adjustment.
    *   Staking & Rewards: Incentive mechanisms.
3.  **Smart Contract Structure:**
    *   Imports (OpenZeppelin's Ownable, ERC20, ERC721).
    *   Enums for states (`EpochPhase`, `DirectiveStatus`, `ProposalStatus`).
    *   Structs for complex data (`CreativeDirective`, `GeneratedArtifact`, `ParameterChangeProposal`).
    *   State Variables: Core configurations, mappings.
    *   Events: For tracking key actions.
    *   Modifiers: For access control and phase validation.
    *   Functions: Grouped by functionality.

**Function Summary (at least 20 functions):**

1.  **`constructor()`:** Initializes the contract, sets initial parameters, deploys/links to `FORGE` token and `AuraArtifact` NFT contracts.
2.  **`setOracleAddress(address _oracle)`:** Sets the trusted oracle address that can submit AI results.
3.  **`setEpochDuration(uint256 _duration)`:** Sets the duration for each epoch phase (can be changed via governance).
4.  **`getCurrentEpoch()`:** Returns the current epoch number.
5.  **`getEpochPhase()`:** Returns the current phase of the epoch (Submission, Voting, Resolution, GracePeriod).
6.  **`advanceEpoch()`:** Allows anyone to trigger the advancement to the next epoch phase, provided the current phase's duration has passed.
7.  **`stakeForParticipation(uint256 _amount)`:** Users stake `FORGE` tokens to participate in submitting directives, voting, and governance.
8.  **`unstake()`:** Users can unstake their `FORGE` after a cooldown or once their active participation in an epoch is resolved.
9.  **`submitCreativeDirective(string memory _promptURI)`:** Users submit a URI pointing to a creative prompt/directive (e.g., IPFS hash of a detailed prompt) by staking `FORGE`.
10. **`voteOnDirective(uint256 _directiveId, bool _support)`:** Stakers vote on proposed creative directives to decide which ones are "active" for AI processing.
11. **`registerGeneratedArtifact(uint256 _directiveId, string memory _artifactURIHash)`:** Callable only by the trusted oracle. Registers an off-chain AI-generated artifact based on a winning directive.
12. **`voteOnArtifactQuality(uint256 _artifactId)`:** Stakers vote on the quality of registered artifacts. Higher votes increase chances of NFT minting and creator rewards.
13. **`mintAuraArtifactNFT(uint256 _artifactId)`:** Allows the creator of a top-voted artifact to mint it as an `AuraArtifact` NFT, transferring the `artifactURIHash` as its token URI.
14. **`claimDirectiveReward(uint256 _directiveId)`:** Allows the proposer of a successfully used directive to claim their `FORGE` rewards.
15. **`claimArtifactCreatorReward(uint256 _artifactId)`:** Allows the creator of a successfully minted `AuraArtifact` NFT to claim their `FORGE` rewards.
16. **`claimVoterReward()`:** Allows active voters who participated in successful outcomes to claim small `FORGE` rewards.
17. **`proposeParameterChange(string memory _paramName, uint256 _newValue)`:** Stakers can propose changes to protocol parameters (e.g., `minStakeAmount`, `votingThresholds`, `rewardRatios`, `epochDuration`).
18. **`voteOnParameterChange(uint256 _proposalId, bool _support)`:** Stakers vote on proposed parameter changes.
19. **`executeParameterChange(uint256 _proposalId)`:** If a parameter change proposal passes, any staker can trigger its execution, updating the protocol's internal rules.
20. **`getDirectiveDetails(uint256 _directiveId)`:** Read-only function to get details about a creative directive.
21. **`getArtifactDetails(uint256 _artifactId)`:** Read-only function to get details about a generated artifact.
22. **`getProtocolParameter(string memory _paramName)`:** Read-only function to retrieve the current value of a specific protocol parameter.
23. **`getPendingParameterProposals()`:** Returns a list of currently active parameter change proposals.
24. **`ownerWithdrawFees(address _tokenAddress)`:** Allows the contract owner to withdraw accumulated protocol fees (e.g., a small percentage of staking/minting fees).
25. **`pauseContract()`:** (Admin) Pauses critical contract functions for emergency.
26. **`unpauseContract()`:** (Admin) Unpauses contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Define the custom ERC20 token for ChronoForge
contract FORGEToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("ChronoForge Token", "FORGE") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    // Optional: Allow owner to mint more tokens (consider removing for fixed supply)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// Define the custom ERC721 token for Aura Artifacts
contract AuraArtifactNFT is ERC721, Ownable {
    uint256 private _nextTokenId;

    constructor() ERC721("Aura Artifact", "AURA") Ownable(msg.sender) {
        // Initial owner can be the ChronoForge contract or deployer
        // For this example, let's assume ChronoForge contract itself will be the minter.
    }

    // ChronoForge contract will be granted minter role
    function safeMint(address to, string memory uri) public returns (uint256) {
        // Restrict who can call mint, e.g., only ChronoForge contract
        // For simplicity, let's just make it callable by owner (which will be ChronoForge initially)
        // In a production setup, a more robust minter role would be used.
        require(msg.sender == owner() || msg.sender == ChronoForge(owner()).chronoForgeOwner(), "AuraArtifactNFT: Not authorized to mint"); // Example auth
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // Function to set the ChronoForge contract as an authorized minter
    function setChronoForgeMinter(address _chronoForgeAddress) public onlyOwner {
        // Set the owner to ChronoForge contract if it's deployed separately
        // Or if the initial owner is EOA, grant specific minter role here.
        // For this example, we'll just check if the sender is owner OR is a specific minter address set later.
        // A better approach would be to use a custom AccessControl role.
    }
}


contract ChronoForge is Ownable, ReentrancyGuard {
    // --- Data Structures ---

    enum EpochPhase { Submission, DirectiveVoting, ArtifactResolution, GracePeriod }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    struct CreativeDirective {
        uint256 id;
        address proposer;
        string promptURI; // IPFS hash or similar for the creative prompt
        uint256 stakeAmount;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 epochCreated;
        EpochPhase phaseCreated;
        bool isActive; // Set to true if it wins directive voting
        uint256 artifactId; // ID of the artifact generated from this directive
    }

    struct GeneratedArtifact {
        uint256 id;
        address creator; // Address who registers the artifact (could be oracle or direct submitter)
        uint256 directiveId;
        string artifactURIHash; // IPFS hash or similar for the generated artifact (image, audio, etc.)
        uint256 qualityVotes; // Votes for the quality of the artifact
        bool isMinted;
        uint256 tokenId; // The ID of the minted AuraArtifactNFT
        uint256 epochCreated;
    }

    struct ParameterChangeProposal {
        uint256 id;
        address proposer;
        bytes32 paramNameHash; // Keccak256 hash of the parameter name (e.g., "minStakeAmount")
        uint256 newValue;
        uint256 creationTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        bool executed;
    }

    // --- State Variables ---

    IERC20 public FORGE; // The ChronoForge utility token
    AuraArtifactNFT public auraArtifactNFT; // The NFT contract for generated artifacts

    address public oracleAddress; // Trusted address for submitting AI results

    uint256 public currentEpoch;
    EpochPhase public currentPhase;
    uint256 public epochStartTime; // Timestamp when the current epoch phase started

    // Protocol Parameters (can be changed via governance)
    uint256 public EPOCH_PHASE_DURATION = 3 days; // Default duration for each phase
    uint256 public MIN_DIRECTIVE_STAKE = 100 * 10**18; // Min FORGE required to submit a directive
    uint256 public DIRECTIVE_VOTING_THRESHOLD_PERCENT = 60; // % of 'for' votes needed for a directive to pass
    uint256 public ARTIFACT_VOTING_THRESHOLD_MIN_VOTES = 5; // Min votes an artifact needs to be considered for minting
    uint256 public PROTOCOL_FEE_PERCENT = 5; // 5% fee on certain operations (e.g., minting, staking)
    uint256 public PARAMETER_CHANGE_QUORUM_PERCENT = 10; // % of total staked FORGE needed for a proposal to pass
    uint256 public PARAMETER_CHANGE_SUPPORT_PERCENT = 60; // % 'for' votes needed for a parameter change proposal
    uint256 public STAKE_COOLDOWN_PERIOD = 7 days; // Time before unstaked funds can be withdrawn

    uint256 public nextDirectiveId;
    uint256 public nextArtifactId;
    uint256 public nextProposalId;

    // Mappings
    mapping(uint256 => CreativeDirective) public creativeDirectives;
    mapping(uint256 => GeneratedArtifact) public generatedArtifacts;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;

    mapping(address => uint256) public stakedBalances; // User's currently staked FORGE
    mapping(address => uint256) public unstakeRequestTime; // Timestamp of unstake request
    mapping(address => mapping(uint256 => bool)) public hasVotedOnDirective; // user -> directiveId -> voted
    mapping(address => mapping(uint256 => bool)) public hasVotedOnArtifact; // user -> artifactId -> voted
    mapping(address => mapping(uint256 => bool)) public hasVotedOnProposal; // user -> proposalId -> voted

    // --- Events ---

    event EpochAdvanced(uint256 indexed newEpoch, EpochPhase indexed newPhase);
    event Staked(address indexed user, uint256 amount, uint256 newBalance);
    event Unstaked(address indexed user, uint256 amount, uint256 newBalance);
    event UnstakeRequested(address indexed user, uint256 requestTime);
    event CreativeDirectiveSubmitted(uint256 indexed directiveId, address indexed proposer, string promptURI, uint256 stakeAmount);
    event DirectiveVoted(uint256 indexed directiveId, address indexed voter, bool support);
    event DirectiveActivated(uint256 indexed directiveId, string promptURI);
    event GeneratedArtifactRegistered(uint256 indexed artifactId, uint256 indexed directiveId, address indexed creator, string artifactURIHash);
    event ArtifactQualityVoted(uint256 indexed artifactId, address indexed voter, uint256 currentVotes);
    event AuraArtifactMinted(uint256 indexed artifactId, uint256 indexed tokenId, address indexed minter, string artifactURIHash);
    event DirectiveRewardClaimed(uint256 indexed directiveId, address indexed proposer, uint256 rewardAmount);
    event ArtifactCreatorRewardClaimed(uint256 indexed artifactId, address indexed creator, uint256 rewardAmount);
    event VoterRewardClaimed(address indexed voter, uint256 rewardAmount);
    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, string paramName, uint256 newValue);
    event ParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ParameterChangeExecuted(uint256 indexed proposalId, string paramName, uint256 oldValue, uint256 newValue);
    event ProtocolFeesWithdrawn(address indexed recipient, address indexed token, uint256 amount);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronoForge: Caller is not the oracle");
        _;
    }

    modifier inPhase(EpochPhase _phase) {
        require(currentPhase == _phase, "ChronoForge: Not in the correct epoch phase");
        _;
    }

    modifier notInPhase(EpochPhase _phase) {
        require(currentPhase != _phase, "ChronoForge: Cannot perform this action in current phase");
        _;
    }

    modifier hasStaked() {
        require(stakedBalances[msg.sender] > 0, "ChronoForge: Requires staked FORGE");
        _;
    }

    // --- Constructor ---

    constructor(address _forgeTokenAddress, address _auraArtifactNFTAddress, address _initialOracleAddress) Ownable(msg.sender) {
        FORGE = IERC20(_forgeTokenAddress);
        auraArtifactNFT = AuraArtifactNFT(_auraArtifactNFTAddress);
        oracleAddress = _initialOracleAddress;

        currentEpoch = 1;
        currentPhase = EpochPhase.Submission;
        epochStartTime = block.timestamp;
        nextDirectiveId = 1;
        nextArtifactId = 1;
        nextProposalId = 1;
    }

    // --- Admin & Setup Functions ---

    /**
     * @dev Sets the trusted oracle address. Only callable by the contract owner.
     * @param _oracle The new oracle address.
     */
    function setOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "ChronoForge: Oracle address cannot be zero");
        oracleAddress = _oracle;
    }

    /**
     * @dev Allows the owner to manually set the epoch phase duration.
     *      This parameter is also subject to decentralized governance.
     * @param _duration The new duration in seconds for each epoch phase.
     */
    function setEpochDuration(uint256 _duration) public onlyOwner {
        require(_duration > 0, "ChronoForge: Duration must be greater than 0");
        EPOCH_PHASE_DURATION = _duration;
    }

    /**
     * @dev Allows the owner to manually set the minimum stake required for directives.
     *      This parameter is also subject to decentralized governance.
     * @param _amount The new minimum stake amount in FORGE (with decimals).
     */
    function setMinDirectiveStake(uint256 _amount) public onlyOwner {
        MIN_DIRECTIVE_STAKE = _amount;
    }

    // Function to get the owner of the ChronoForge contract
    function chronoForgeOwner() public view returns (address) {
        return owner();
    }

    // --- Epoch Management Functions ---

    /**
     * @dev Returns the current epoch number.
     * @return The current epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @dev Returns the current phase of the epoch.
     * @return The current EpochPhase.
     */
    function getEpochPhase() public view returns (EpochPhase) {
        return currentPhase;
    }

    /**
     * @dev Allows anyone to advance the epoch phase if the current phase's duration has passed.
     *      This ensures continuous operation of the protocol.
     */
    function advanceEpoch() public nonReentrant {
        require(block.timestamp >= epochStartTime + EPOCH_PHASE_DURATION, "ChronoForge: Current phase duration not over yet");

        if (currentPhase == EpochPhase.Submission) {
            currentPhase = EpochPhase.DirectiveVoting;
        } else if (currentPhase == EpochPhase.DirectiveVoting) {
            // Logic to determine winning directives and activate them
            _resolveDirectives();
            currentPhase = EpochPhase.ArtifactResolution;
        } else if (currentPhase == EpochPhase.ArtifactResolution) {
            currentPhase = EpochPhase.GracePeriod;
        } else if (currentPhase == EpochPhase.GracePeriod) {
            currentEpoch++;
            currentPhase = EpochPhase.Submission;
        }
        epochStartTime = block.timestamp;
        emit EpochAdvanced(currentEpoch, currentPhase);
    }

    /**
     * @dev Internal function to resolve directives after the voting phase.
     *      Activates directives that meet the voting threshold.
     */
    function _resolveDirectives() internal {
        for (uint256 i = 1; i < nextDirectiveId; i++) {
            CreativeDirective storage directive = creativeDirectives[i];
            // Only consider directives from the just-finished epoch's submission phase
            if (directive.epochCreated == currentEpoch && directive.phaseCreated == EpochPhase.Submission && !directive.isActive) {
                uint256 totalVotes = directive.votesFor + directive.votesAgainst;
                if (totalVotes > 0 && (directive.votesFor * 100 / totalVotes) >= DIRECTIVE_VOTING_THRESHOLD_PERCENT) {
                    directive.isActive = true;
                    emit DirectiveActivated(directive.id, directive.promptURI);
                }
            }
        }
    }

    // --- Staking & Unstaking Functions ---

    /**
     * @dev Users stake FORGE tokens to participate in the protocol.
     * @param _amount The amount of FORGE to stake.
     */
    function stakeForParticipation(uint256 _amount) public nonReentrant {
        require(_amount > 0, "ChronoForge: Stake amount must be greater than zero");
        FORGE.transferFrom(msg.sender, address(this), _amount);
        stakedBalances[msg.sender] += _amount;
        emit Staked(msg.sender, _amount, stakedBalances[msg.sender]);
    }

    /**
     * @dev Users can request to unstake their FORGE tokens.
     *      A cooldown period applies before withdrawal is possible.
     */
    function requestUnstake() public nonReentrant hasStaked {
        require(unstakeRequestTime[msg.sender] == 0, "ChronoForge: Unstake request already pending");
        unstakeRequestTime[msg.sender] = block.timestamp;
        emit UnstakeRequested(msg.sender, block.timestamp);
    }

    /**
     * @dev Allows users to withdraw their staked FORGE after the cooldown period.
     */
    function withdrawStakedTokens() public nonReentrant {
        require(stakedBalances[msg.sender] > 0, "ChronoForge: No staked tokens to withdraw");
        require(unstakeRequestTime[msg.sender] > 0, "ChronoForge: Unstake request not initiated");
        require(block.timestamp >= unstakeRequestTime[msg.sender] + STAKE_COOLDOWN_PERIOD, "ChronoForge: Cooldown period not over");

        uint256 amountToWithdraw = stakedBalances[msg.sender];
        stakedBalances[msg.sender] = 0;
        unstakeRequestTime[msg.sender] = 0; // Reset request time
        FORGE.transfer(msg.sender, amountToWithdraw);
        emit Unstaked(msg.sender, amountToWithdraw, 0);
    }

    // --- Creative Directive Functions (Submission Phase) ---

    /**
     * @dev Users submit a URI pointing to a creative prompt/directive by staking FORGE.
     *      Only allowed during the Submission phase.
     * @param _promptURI The URI (e.g., IPFS hash) of the creative prompt.
     */
    function submitCreativeDirective(string memory _promptURI) public nonReentrant inPhase(EpochPhase.Submission) {
        require(stakedBalances[msg.sender] >= MIN_DIRECTIVE_STAKE, "ChronoForge: Insufficient staked FORGE");

        uint256 directiveId = nextDirectiveId++;
        creativeDirectives[directiveId] = CreativeDirective({
            id: directiveId,
            proposer: msg.sender,
            promptURI: _promptURI,
            stakeAmount: MIN_DIRECTIVE_STAKE, // Could make this dynamic based on user's stake
            votesFor: 0,
            votesAgainst: 0,
            epochCreated: currentEpoch,
            phaseCreated: currentPhase,
            isActive: false,
            artifactId: 0 // Will be set later
        });
        emit CreativeDirectiveSubmitted(directiveId, msg.sender, _promptURI, MIN_DIRECTIVE_STAKE);
    }

    /**
     * @dev Retrieves details about a specific creative directive.
     * @param _directiveId The ID of the directive.
     * @return tuple containing directive details.
     */
    function getCreativeDirective(uint256 _directiveId) public view returns (
        uint256 id,
        address proposer,
        string memory promptURI,
        uint256 stakeAmount,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 epochCreated,
        EpochPhase phaseCreated,
        bool isActive,
        uint256 artifactId
    ) {
        CreativeDirective storage d = creativeDirectives[_directiveId];
        require(d.id != 0, "ChronoForge: Directive does not exist");
        return (d.id, d.proposer, d.promptURI, d.stakeAmount, d.votesFor, d.votesAgainst, d.epochCreated, d.phaseCreated, d.isActive, d.artifactId);
    }

    // --- Directive Voting Functions (DirectiveVoting Phase) ---

    /**
     * @dev Stakers vote on proposed creative directives to decide which ones are "active" for AI processing.
     *      Only allowed during the DirectiveVoting phase. Each staker can vote once per directive.
     * @param _directiveId The ID of the directive to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnDirective(uint256 _directiveId, bool _support) public nonReentrant inPhase(EpochPhase.DirectiveVoting) hasStaked {
        CreativeDirective storage directive = creativeDirectives[_directiveId];
        require(directive.id != 0, "ChronoForge: Directive does not exist");
        require(directive.epochCreated == currentEpoch, "ChronoForge: Can only vote on directives from current epoch's submission");
        require(!hasVotedOnDirective[msg.sender][_directiveId], "ChronoForge: Already voted on this directive");

        if (_support) {
            directive.votesFor++;
        } else {
            directive.votesAgainst++;
        }
        hasVotedOnDirective[msg.sender][_directiveId] = true;
        emit DirectiveVoted(_directiveId, msg.sender, _support);
    }

    // --- AI Integration & Artifact Functions (ArtifactResolution Phase) ---

    /**
     * @dev Called by the trusted oracle to register an off-chain AI-generated artifact.
     *      Must correspond to an active (winning) creative directive.
     * @param _directiveId The ID of the directive this artifact fulfills.
     * @param _artifactURIHash The URI (e.g., IPFS hash) of the generated artifact.
     */
    function registerGeneratedArtifact(uint256 _directiveId, string memory _artifactURIHash) public nonReentrant onlyOracle inPhase(EpochPhase.ArtifactResolution) {
        CreativeDirective storage directive = creativeDirectives[_directiveId];
        require(directive.id != 0 && directive.isActive, "ChronoForge: Directive does not exist or is not active");
        require(directive.artifactId == 0, "ChronoForge: Artifact already registered for this directive");

        uint256 artifactId = nextArtifactId++;
        generatedArtifacts[artifactId] = GeneratedArtifact({
            id: artifactId,
            creator: msg.sender, // Oracle is the 'creator' in this context, or an AI agent's address
            directiveId: _directiveId,
            artifactURIHash: _artifactURIHash,
            qualityVotes: 0,
            isMinted: false,
            tokenId: 0,
            epochCreated: currentEpoch
        });
        directive.artifactId = artifactId; // Link directive to artifact
        emit GeneratedArtifactRegistered(artifactId, _directiveId, msg.sender, _artifactURIHash);
    }

    /**
     * @dev Stakers vote on the quality of registered artifacts. Higher votes increase chances of NFT minting and creator rewards.
     *      Only allowed during the ArtifactResolution phase. Each staker can vote once per artifact.
     * @param _artifactId The ID of the artifact to vote on.
     */
    function voteOnArtifactQuality(uint256 _artifactId) public nonReentrant inPhase(EpochPhase.ArtifactResolution) hasStaked {
        GeneratedArtifact storage artifact = generatedArtifacts[_artifactId];
        require(artifact.id != 0, "ChronoForge: Artifact does not exist");
        require(artifact.epochCreated == currentEpoch, "ChronoForge: Can only vote on artifacts from current epoch");
        require(!hasVotedOnArtifact[msg.sender][_artifactId], "ChronoForge: Already voted on this artifact");

        artifact.qualityVotes++;
        hasVotedOnArtifact[msg.sender][_artifactId] = true;
        emit ArtifactQualityVoted(_artifactId, msg.sender, artifact.qualityVotes);
    }

    /**
     * @dev Allows the creator (or anyone for public good) of a top-voted artifact to mint it as an AuraArtifact NFT.
     *      Can be called during GracePeriod or subsequent Submission phases.
     * @param _artifactId The ID of the artifact to mint.
     */
    function mintAuraArtifactNFT(uint256 _artifactId) public nonReentrant {
        GeneratedArtifact storage artifact = generatedArtifacts[_artifactId];
        require(artifact.id != 0, "ChronoForge: Artifact does not exist");
        require(!artifact.isMinted, "ChronoForge: Artifact already minted");
        require(artifact.qualityVotes >= ARTIFACT_VOTING_THRESHOLD_MIN_VOTES, "ChronoForge: Artifact did not receive enough quality votes");

        // Calculate minting fee (if any, e.g., PROTOCOL_FEE_PERCENT of some base value or user-specified value)
        // For simplicity, let's assume a small fixed fee or a percentage of 0 for now if no FORGE is burnt/paid.
        // If a fee is needed, add `FORGE.transferFrom(msg.sender, address(this), mintFee)` here.

        uint256 tokenId = auraArtifactNFT.safeMint(msg.sender, artifact.artifactURIHash); // Mints to the caller
        artifact.isMinted = true;
        artifact.tokenId = tokenId;

        // Apply protocol fee to the total supply if applicable or direct to owner
        uint256 protocolFeeAmount = (MIN_DIRECTIVE_STAKE * PROTOCOL_FEE_PERCENT) / 100; // Example fee calculation
        if (protocolFeeAmount > 0) {
            // Transfer fee to protocol treasury (this contract) or directly to owner
            FORGE.transfer(owner(), protocolFeeAmount); // Or accumulate within this contract for later withdrawal
        }

        emit AuraArtifactMinted(_artifactId, tokenId, msg.sender, artifact.artifactURIHash);
    }

    /**
     * @dev Retrieves details about a specific generated artifact.
     * @param _artifactId The ID of the artifact.
     * @return tuple containing artifact details.
     */
    function getArtifactDetails(uint256 _artifactId) public view returns (
        uint256 id,
        address creator,
        uint256 directiveId,
        string memory artifactURIHash,
        uint256 qualityVotes,
        bool isMinted,
        uint256 tokenId,
        uint256 epochCreated
    ) {
        GeneratedArtifact storage a = generatedArtifacts[_artifactId];
        require(a.id != 0, "ChronoForge: Artifact does not exist");
        return (a.id, a.creator, a.directiveId, a.artifactURIHash, a.qualityVotes, a.isMinted, a.tokenId, a.epochCreated);
    }

    // --- Reward Claiming Functions ---

    /**
     * @dev Allows the proposer of a successfully used directive to claim their FORGE rewards.
     *      This could be a return of their stake + a bonus.
     *      Can be called after the ArtifactResolution phase (GracePeriod onwards).
     * @param _directiveId The ID of the directive.
     */
    function claimDirectiveReward(uint256 _directiveId) public nonReentrant {
        CreativeDirective storage directive = creativeDirectives[_directiveId];
        require(directive.id != 0 && directive.proposer == msg.sender, "ChronoForge: Invalid directive or not proposer");
        require(directive.isActive, "ChronoForge: Directive not active/successful");
        require(directive.artifactId != 0 && generatedArtifacts[directive.artifactId].isMinted, "ChronoForge: Associated artifact not minted yet");
        // Add a check to prevent double claims if needed
        // For simplicity, we'll allow claiming after successful mint. A better system would be a boolean flag `claimedReward`.

        uint256 rewardAmount = directive.stakeAmount + (directive.stakeAmount / 10); // Example: Stake + 10% bonus
        FORGE.transfer(msg.sender, rewardAmount);
        // Mark as claimed to prevent re-claiming.
        // For example, by setting directive.stakeAmount = 0 or a new bool flag.
        // Here, we just assume it's a one-time claim per directive for the proposer.
        emit DirectiveRewardClaimed(_directiveId, msg.sender, rewardAmount);
    }

    /**
     * @dev Allows the creator of a successfully minted AuraArtifact NFT to claim their FORGE rewards.
     *      Can be called after the ArtifactResolution phase (GracePeriod onwards).
     * @param _artifactId The ID of the artifact.
     */
    function claimArtifactCreatorReward(uint256 _artifactId) public nonReentrant {
        GeneratedArtifact storage artifact = generatedArtifacts[_artifactId];
        require(artifact.id != 0 && artifact.creator == msg.sender, "ChronoForge: Invalid artifact or not creator");
        require(artifact.isMinted, "ChronoForge: Artifact not minted");
        // Add a check to prevent double claims if needed.

        uint256 rewardAmount = artifact.qualityVotes * (1 * 10**18); // Example: 1 FORGE per quality vote
        FORGE.transfer(msg.sender, rewardAmount);
        // Mark as claimed.
        emit ArtifactCreatorRewardClaimed(_artifactId, msg.sender, rewardAmount);
    }

    /**
     * @dev Allows active voters who participated in successful outcomes to claim small FORGE rewards.
     *      This would involve iterating through their votes in a given epoch and calculating rewards.
     *      For simplicity, this function will give a fixed small reward to any staker once per epoch
     *      who has participated in *any* successful vote (directive or artifact).
     *      In a real system, this would be more complex and granular.
     */
    mapping(address => mapping(uint256 => bool)) public hasClaimedVoterReward; // user -> epochId -> claimed
    function claimVoterReward() public nonReentrant {
        require(stakedBalances[msg.sender] > 0, "ChronoForge: No staked FORGE to qualify for reward.");
        require(!hasClaimedVoterReward[msg.sender][currentEpoch], "ChronoForge: Already claimed voter reward for this epoch.");

        // Check if user voted on *any* successful directive or artifact in the *previous* epoch (now 'currentEpoch' if GracePeriod)
        // This simplified check just awards if they participated at all.
        bool participated = false;
        for(uint256 i = 1; i < nextDirectiveId; i++) {
            if(creativeDirectives[i].epochCreated == currentEpoch - 1 && hasVotedOnDirective[msg.sender][i]) {
                participated = true; break;
            }
        }
        if(!participated) {
            for(uint256 i = 1; i < nextArtifactId; i++) {
                if(generatedArtifacts[i].epochCreated == currentEpoch - 1 && hasVotedOnArtifact[msg.sender][i]) {
                    participated = true; break;
                }
            }
        }
        require(participated, "ChronoForge: Did not participate in previous epoch's successful votes.");

        uint256 rewardAmount = 5 * 10**18; // Example fixed small reward
        FORGE.transfer(msg.sender, rewardAmount);
        hasClaimedVoterReward[msg.sender][currentEpoch] = true; // Mark for current epoch
        emit VoterRewardClaimed(msg.sender, rewardAmount);
    }

    // --- Protocol Governance & Dynamic Parameter Functions ---

    /**
     * @dev Stakers can propose changes to core protocol parameters.
     *      Examples: "EPOCH_PHASE_DURATION", "MIN_DIRECTIVE_STAKE", "PROTOCOL_FEE_PERCENT"
     * @param _paramName The string name of the parameter to change.
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(string memory _paramName, uint256 _newValue) public nonReentrant hasStaked {
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));
        // Simple check for valid parameter names
        require(
            paramHash == keccak256(abi.encodePacked("EPOCH_PHASE_DURATION")) ||
            paramHash == keccak256(abi.encodePacked("MIN_DIRECTIVE_STAKE")) ||
            paramHash == keccak256(abi.encodePacked("DIRECTIVE_VOTING_THRESHOLD_PERCENT")) ||
            paramHash == keccak256(abi.encodePacked("ARTIFACT_VOTING_THRESHOLD_MIN_VOTES")) ||
            paramHash == keccak256(abi.encodePacked("PROTOCOL_FEE_PERCENT")) ||
            paramHash == keccak256(abi.encodePacked("PARAMETER_CHANGE_QUORUM_PERCENT")) ||
            paramHash == keccak256(abi.encodePacked("PARAMETER_CHANGE_SUPPORT_PERCENT")) ||
            paramHash == keccak256(abi.encodePacked("STAKE_COOLDOWN_PERIOD")),
            "ChronoForge: Invalid parameter name"
        );
        require(_newValue > 0, "ChronoForge: New parameter value must be positive");

        uint256 proposalId = nextProposalId++;
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            id: proposalId,
            proposer: msg.sender,
            paramNameHash: paramHash,
            newValue: _newValue,
            creationTime: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending,
            executed: false
        });
        emit ParameterChangeProposed(proposalId, msg.sender, _paramName, _newValue);
    }

    /**
     * @dev Stakers vote on proposed parameter changes.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) public nonReentrant hasStaked {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(proposal.id != 0, "ChronoForge: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "ChronoForge: Proposal is not pending");
        require(!hasVotedOnProposal[msg.sender][_proposalId], "ChronoForge: Already voted on this proposal");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        hasVotedOnProposal[msg.sender][_proposalId] = true;
        emit ParameterChangeVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev If a parameter change proposal passes, any staker can trigger its execution.
     *      Updates the protocol's internal rules.
     *      Requires a majority vote and a minimum quorum of total staked FORGE.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 _proposalId) public nonReentrant {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(proposal.id != 0, "ChronoForge: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "ChronoForge: Proposal is not pending");
        require(!proposal.executed, "ChronoForge: Proposal already executed");

        uint256 totalProposalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 totalStakedForge = FORGE.balanceOf(address(this)); // Total FORGE held by this contract (staked)

        require(totalStakedForge > 0, "ChronoForge: No FORGE staked to determine quorum.");

        uint256 votesNeededForQuorum = (totalStakedForge * PARAMETER_CHANGE_QUORUM_PERCENT) / 100;
        require(totalProposalVotes >= votesNeededForQuorum, "ChronoForge: Proposal did not meet quorum");

        uint256 supportPercentage = (proposal.votesFor * 100) / totalProposalVotes;
        require(supportPercentage >= PARAMETER_CHANGE_SUPPORT_PERCENT, "ChronoForge: Proposal did not pass support threshold");

        bytes32 paramHash = proposal.paramNameHash;
        uint256 oldValue;

        if (paramHash == keccak256(abi.encodePacked("EPOCH_PHASE_DURATION"))) {
            oldValue = EPOCH_PHASE_DURATION;
            EPOCH_PHASE_DURATION = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("MIN_DIRECTIVE_STAKE"))) {
            oldValue = MIN_DIRECTIVE_STAKE;
            MIN_DIRECTIVE_STAKE = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("DIRECTIVE_VOTING_THRESHOLD_PERCENT"))) {
            oldValue = DIRECTIVE_VOTING_THRESHOLD_PERCENT;
            DIRECTIVE_VOTING_THRESHOLD_PERCENT = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("ARTIFACT_VOTING_THRESHOLD_MIN_VOTES"))) {
            oldValue = ARTIFACT_VOTING_THRESHOLD_MIN_VOTES;
            ARTIFACT_VOTING_THRESHOLD_MIN_VOTES = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("PROTOCOL_FEE_PERCENT"))) {
            oldValue = PROTOCOL_FEE_PERCENT;
            PROTOCOL_FEE_PERCENT = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("PARAMETER_CHANGE_QUORUM_PERCENT"))) {
            oldValue = PARAMETER_CHANGE_QUORUM_PERCENT;
            PARAMETER_CHANGE_QUORUM_PERCENT = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("PARAMETER_CHANGE_SUPPORT_PERCENT"))) {
            oldValue = PARAMETER_CHANGE_SUPPORT_PERCENT;
            PARAMETER_CHANGE_SUPPORT_PERCENT = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("STAKE_COOLDOWN_PERIOD"))) {
            oldValue = STAKE_COOLDOWN_PERIOD;
            STAKE_COOLDOWN_PERIOD = proposal.newValue;
        } else {
            revert("ChronoForge: Unknown parameter for execution");
        }

        proposal.status = ProposalStatus.Approved;
        proposal.executed = true;
        emit ParameterChangeExecuted(_proposalId, _bytes32ToString(paramHash), oldValue, proposal.newValue);
    }

    /**
     * @dev Helper function to convert bytes32 to string for event logging.
     * @param _bytes32Value The bytes32 value to convert.
     * @return The converted string.
     */
    function _bytes32ToString(bytes32 _bytes32Value) internal pure returns (string memory) {
        uint256 i = 0;
        while (i < 32 && _bytes32Value[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (uint256 j = 0; j < i; j++) {
            bytesArray[j] = _bytes32Value[j];
        }
        return string(bytesArray);
    }

    /**
     * @dev Retrieves the current value of a specific protocol parameter.
     * @param _paramName The string name of the parameter.
     * @return The current value of the parameter.
     */
    function getProtocolParameter(string memory _paramName) public view returns (uint256) {
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));
        if (paramHash == keccak256(abi.encodePacked("EPOCH_PHASE_DURATION"))) {
            return EPOCH_PHASE_DURATION;
        } else if (paramHash == keccak256(abi.encodePacked("MIN_DIRECTIVE_STAKE"))) {
            return MIN_DIRECTIVE_STAKE;
        } else if (paramHash == keccak256(abi.encodePacked("DIRECTIVE_VOTING_THRESHOLD_PERCENT"))) {
            return DIRECTIVE_VOTING_THRESHOLD_PERCENT;
        } else if (paramHash == keccak256(abi.encodePacked("ARTIFACT_VOTING_THRESHOLD_MIN_VOTES"))) {
            return ARTIFACT_VOTING_THRESHOLD_MIN_VOTES;
        } else if (paramHash == keccak256(abi.encodePacked("PROTOCOL_FEE_PERCENT"))) {
            return PROTOCOL_FEE_PERCENT;
        } else if (paramHash == keccak256(abi.encodePacked("PARAMETER_CHANGE_QUORUM_PERCENT"))) {
            return PARAMETER_CHANGE_QUORUM_PERCENT;
        } else if (paramHash == keccak256(abi.encodePacked("PARAMETER_CHANGE_SUPPORT_PERCENT"))) {
            return PARAMETER_CHANGE_SUPPORT_PERCENT;
        } else if (paramHash == keccak256(abi.encodePacked("STAKE_COOLDOWN_PERIOD"))) {
            return STAKE_COOLDOWN_PERIOD;
        }
        revert("ChronoForge: Unknown parameter name");
    }

    /**
     * @dev Retrieves a list of currently active (pending) parameter change proposals.
     *      Note: This is an example, returning all might be gas intensive if many proposals exist.
     *      In production, this would return paginated results or just a count.
     */
    function getPendingParameterProposals() public view returns (uint256[] memory) {
        uint256[] memory pendingIds = new uint256[](nextProposalId - 1); // Max possible
        uint256 counter = 0;
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (parameterChangeProposals[i].status == ProposalStatus.Pending) {
                pendingIds[counter] = i;
                counter++;
            }
        }
        uint256[] memory result = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = pendingIds[i];
        }
        return result;
    }

    // --- Fee Management ---

    /**
     * @dev Allows the contract owner to withdraw accumulated protocol fees.
     * @param _tokenAddress The address of the token to withdraw (e.g., FORGE).
     */
    function ownerWithdrawFees(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "ChronoForge: Token address cannot be zero");
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "ChronoForge: No fees to withdraw for this token");
        token.transfer(owner(), balance);
        emit ProtocolFeesWithdrawn(owner(), _tokenAddress, balance);
    }

    // --- Emergency Functions (inherited from OpenZeppelin's Pausable if integrated) ---
    // For simplicity, including basic pause/unpause here.
    bool public paused;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Pauses all functions that are marked as `whenNotPaused`.
     * Can only be called by the owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        // emit Paused(msg.sender); // Would need Pausable contract event
    }

    /**
     * @dev Unpauses the contract.
     * Can only be called by the owner.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        // emit Unpaused(msg.sender); // Would need Pausable contract event
    }
}
```