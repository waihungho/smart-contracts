```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Using full ERC20 for ArtiumToken

// --- OUTLINE & FUNCTION SUMMARY ---
// The AetherCanvasGuild is a decentralized autonomous organization (DAO) focused on collaboratively
// steering a simulated AI art generation process. Members contribute "creative prompts,"
// curate generated "Art Piece NFTs," and participate in guild governance.
// Reputation is tracked via a dynamic, non-transferable "Creativity Score" (SBT-like), influencing
// voting power, reward distribution, and even the evolving attributes of the generated NFTs.
// The contract operates in "Epochs," each with a specific theme or artistic direction.

// I. Guild & Core Mechanics
// 1.  joinGuild(uint256 amount): Allows a user to become a guild member by staking ART tokens.
// 2.  leaveGuild(): Allows a guild member to leave, unstaking their ART tokens and forfeiting active roles and Creativity Score.
// 3.  startNewEpoch(string calldata _theme, bytes32 _aiModelSeed): Initiates a new art generation epoch with a theme and AI model seed. Only callable by current epoch leader or via proposal.
// 4.  getCurrentEpochDetails(): Views details of the current active epoch, including its theme, status, and AI parameters.

// II. AI Art Generation & Prompt Submission
// 5.  submitCreativePrompt(string calldata _promptContent): Members submit text-based or data-based prompts for the AI to interpret, requiring a small ART fee.
// 6.  voteOnPrompts(uint256[] calldata _promptIds, uint256[] calldata _votes): Members vote on the submitted prompts to decide which are most inspiring. Voting power is based on staked ART and Creativity Score.
// 7.  executeAIGeneration(bytes32 _aiOutputHash, uint256 _winningPromptId): Triggered by an authorized oracle, this function finalizes the AI generation process for the epoch, using the top-voted prompt and an external AI output hash.
// 8.  _mintArtPieceNFT(uint256 _promptId, bytes32 _aiOutputHash): Internal function to mint the newly generated art piece as a dynamic ERC-721 NFT to the prompt's creator. Called automatically after `executeAIGeneration`.

// III. Curation & Reputation (Creativity Score - SBT-like)
// 9.  curateArtPiece(uint256 _tokenId, uint8 _rating, string calldata _comment): Members review and rate generated Art Piece NFTs, influencing their on-chain attributes and the original creator's Creativity Score.
// 10. challengeCuration(uint256 _tokenId, address _curator, uint8 _disputedRating): Allows a member to dispute a specific curation rating, impacting Creativity Scores based on the outcome (simplified in this example).
// 11. getCreativityScore(address _member): Retrieves a specific member's dynamic, non-transferable Creativity Score.
// 12. _updateCreativityScore(address _member, int256 _scoreDelta): Internal function to adjust a member's Creativity Score based on contributions (successful prompts, fair curation, etc.).

// IV. Governance & DAO
// 13. proposeGuildChange(string calldata _description, bytes calldata _callData, address _target): Allows members to propose changes to guild parameters, AI model seeds, or contract upgrades. Requires minimum staked ART.
// 14. voteOnProposal(uint256 _proposalId, bool _support): Members cast their vote (support/oppose) on active proposals. Voting power is influenced by Creativity Score and staked ART.
// 15. executeProposal(uint256 _proposalId): Executes a passed proposal if the quorum and approval thresholds are met. Callable by any member after voting period ends.
// 16. delegateVote(address _delegatee): Members can delegate their voting power to another guild member.

// V. Dynamic NFT & Rewards
// 17. getArtPieceMetadata(uint256 _tokenId): Retrieves the full dynamic metadata of an Art Piece NFT, including its base prompt, AI hash, and aggregated curation scores.
// 18. claimEpochRewards(): Allows members to claim ART tokens earned from successful prompt submissions, curation, and active participation in the concluded epoch. (Simplified reward distribution).
// 19. updateArtPieceAttributes(uint256 _tokenId, bytes32 _newAttributesHash): Public function, typically called by the oracle, to dynamically update an NFT's on-chain attributes based on new data or events.

// VI. Utilities & Admin
// 20. setOracleAddress(address _newOracle): Allows the guild (via governance or owner for this example) to update the address of the trusted oracle for AI generation and dynamic NFT updates.
// 21. withdrawGuildFunds(address _recipient, uint256 _amount): Allows the guild (via governance or owner for this example) to transfer ART tokens from the guild treasury for operational costs or community initiatives.
// 22. emergencyPause(bool _status): Placeholder for an emergency pause mechanism (a full implementation would use OpenZeppelin's Pausable contract).

// --- END OUTLINE & SUMMARY ---

/**
 * @title ArtiumToken
 * @dev A simple ERC-20 token used for staking, fees, and rewards within the AetherCanvasGuild.
 */
contract ArtiumToken is ERC20, Ownable {
    constructor() ERC20("Artium", "ART") Ownable(msg.sender) {
        _mint(msg.sender, 1000000000 * 10**18); // Mint initial supply to deployer for testing
    }

    // Allow owner to mint more tokens (for testing/initial distribution, would be governed in prod)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

/**
 * @title AetherCanvasGuild
 * @dev A decentralized guild for collaborative AI art generation, dynamic NFTs, and reputation.
 */
contract AetherCanvasGuild is Context, ReentrancyGuard, Ownable, ERC721 {

    // --- State Variables ---

    // ERC-20 token for staking and rewards
    ArtiumToken public immutable artiumToken;

    // Guild Configuration
    uint256 public constant MIN_STAKE_FOR_MEMBERSHIP = 100 * 10**18; // 100 ART
    uint256 public constant PROMPT_SUBMISSION_FEE = 10 * 10**18; // 10 ART
    uint256 public constant PROPOSAL_THRESHOLD_ART = 500 * 10**18; // Min ART staked to create proposal
    uint256 public constant PROPOSAL_VOTE_QUORUM_PERCENT = 5; // 5% of total voting power
    uint256 public constant PROPOSAL_VOTE_DURATION = 3 days;
    uint256 public constant EPOCH_DURATION = 7 days; // Duration of an art generation epoch

    address public oracleAddress; // Address of the trusted oracle for AI generation/updates

    // Member Data
    struct Member {
        uint256 stakedArt;
        uint256 creativityScore; // Non-transferable, dynamic reputation score
        uint256 lastActivityEpoch; // Epoch when member was last active (e.g., prompt, vote, curate)
        address delegatedVotee; // Address to whom this member has delegated their voting power
        bool isGuildMember;
        uint256 rewardsClaimedUpToEpoch; // Track for reward claiming
    }
    mapping(address => Member) public members;
    uint256 public totalStakedArt; // Total ART tokens staked by guild members (for voting power calculation)

    // Epoch Data
    struct Epoch {
        uint256 epochId;
        string theme;
        bytes32 aiModelSeed; // Parameters or seed for the simulated AI model
        uint256 startTime;
        uint256 endTime;
        bool isConcluded;
        address epochLeader; // Can be a top contributor from previous epoch, or selected by governance
        uint256 winningPromptId; // ID of the prompt selected for AI generation
        uint256 artPieceTokenId; // Token ID of the NFT generated in this epoch (0 if not minted)
        uint256 totalPromptVotes; // Total votes cast on prompts in this epoch
        uint256 totalCurationScore; // Sum of curation scores for the epoch's generated art piece
        uint256 totalRewardPool; // ART tokens allocated for rewards in this epoch
    }
    Epoch[] public epochs; // Array to store all past and current epochs
    uint256 public currentEpochId;

    // Prompt Data
    struct Prompt {
        uint256 promptId;
        address submitter;
        string content;
        uint256 submissionTime;
        uint256 totalVotes;
        bool isSelected;
        uint256 epochId;
    }
    mapping(uint256 => Prompt) public prompts;
    uint256 public nextPromptId;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnPrompt; // promptId => voter => hasVoted

    // Art Piece NFT Data (ERC-721 details handled by inherited ERC721 contract)
    struct ArtPiece {
        uint256 tokenId;
        address creator; // Address of the prompt submitter
        uint256 epochId;
        bytes32 aiOutputHash; // Hash representing the AI generated output (e.g., IPFS hash of image, generative seed)
        string basePromptContent;
        uint256 totalCurationScore; // Sum of all curation ratings
        uint256 numCurations; // Number of times curated
        mapping(address => uint8) curatorRatings; // Individual curator's rating
        bytes32 dynamicAttributesHash; // A hash that can change, representing dynamic attributes
    }
    mapping(uint256 => ArtPiece) public artPieces;
    uint256 public nextArtPieceTokenId;

    // Governance/Proposal Data
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes callData; // Encoded function call for execution
        address target; // Target contract for execution
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // proposalId => voter => hasVoted
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    // --- Events ---
    event GuildMemberJoined(address indexed member, uint256 stakedAmount, uint256 creativityScore);
    event GuildMemberLeft(address indexed member, uint256 unstakedAmount);
    event EpochStarted(uint256 indexed epochId, string theme, bytes32 aiModelSeed, uint256 startTime);
    event PromptSubmitted(uint256 indexed promptId, address indexed submitter, string content, uint256 epochId);
    event PromptVoted(uint256 indexed promptId, address indexed voter, uint256 voteAmount);
    event AIGenerationExecuted(uint256 indexed epochId, uint256 indexed winningPromptId, bytes32 aiOutputHash);
    event ArtPieceMinted(uint256 indexed tokenId, address indexed creator, uint256 indexed epochId, bytes32 aiOutputHash);
    event ArtPieceCurated(uint256 indexed tokenId, address indexed curator, uint8 rating, string comment);
    event CurationChallenged(uint256 indexed tokenId, address indexed curator, uint8 disputedRating, address indexed challenger);
    event CreativityScoreUpdated(address indexed member, int256 delta, uint256 newScore);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event ArtPieceAttributesUpdated(uint256 indexed tokenId, bytes32 newAttributesHash);
    event OracleAddressUpdated(address indexed newOracle);
    event GuildFundsWithdrawn(address indexed recipient, uint256 amount);
    event EmergencyPaused(bool status);
    event RewardsClaimed(address indexed member, uint256 epochId, uint256 amount);

    // --- Constructor ---
    constructor(address _artiumTokenAddress, address _initialOracleAddress)
        ERC721("AetherCanvasArt", "ACA")
        Ownable(msg.sender) // Set deployer as initial owner
    {
        require(_artiumTokenAddress != address(0), "Invalid Artium Token Address");
        require(_initialOracleAddress != address(0), "Invalid Oracle Address");
        artiumToken = ArtiumToken(_artiumTokenAddress);
        oracleAddress = _initialOracleAddress;

        // Initialize the first epoch (Epoch 0, a "Genesis" epoch before active generation)
        epochs.push(Epoch(
            0,
            "Genesis Epoch",
            bytes32(0),
            block.timestamp,
            block.timestamp, // Concluded immediately
            true,
            address(0),
            0,
            0,
            0,
            0,
            0
        ));
        currentEpochId = 0; // Current actual working epoch is 0
    }

    // --- Modifiers ---
    modifier onlyGuildMember() {
        require(members[_msgSender()].isGuildMember, "Not a guild member");
        _;
    }

    modifier onlyOracle() {
        require(_msgSender() == oracleAddress, "Caller is not the authorized oracle");
        _;
    }

    modifier onlyEpochLeader() {
        require(members[_msgSender()].isGuildMember, "Not a guild member");
        require(epochs[currentEpochId].epochLeader == _msgSender(), "Not the current epoch leader");
        _;
    }

    modifier notConcludedEpoch(uint256 _epochId) {
        require(_epochId < epochs.length, "Invalid epoch ID");
        require(!epochs[_epochId].isConcluded, "Epoch has already concluded");
        _;
    }

    // --- Utility Functions ---

    /**
     * @notice Calculates the total voting power of a member, considering staked ART and Creativity Score.
     * Delegates' voting power is aggregated.
     * @param _member The address of the member.
     * @return The total voting power.
     */
    function _getVotingPower(address _member) internal view returns (uint256) {
        address memberAddress = _member;
        // Resolve delegation chain
        while (members[memberAddress].delegatedVotee != address(0) && members[memberAddress].delegatedVotee != memberAddress) {
            memberAddress = members[memberAddress].delegatedVotee;
        }
        // Voting power = staked ART + (Creativity Score / 100 * 1 ART equivalent)
        // Assuming 100 Creativity Score points is equivalent to 1 ART token's voting power for calculation
        return members[memberAddress].stakedArt + (members[memberAddress].creativityScore * 10**18 / 100);
    }

    /**
     * @notice Internal function to adjust a member's dynamic Creativity Score.
     * @param _member The address of the member whose score is being updated.
     * @param _scoreDelta The amount to add (positive) or subtract (negative) from the score.
     */
    function _updateCreativityScore(address _member, int256 _scoreDelta) internal {
        uint256 currentScore = members[_member].creativityScore;
        uint256 newScore;

        if (_scoreDelta > 0) {
            newScore = currentScore + uint256(_scoreDelta);
        } else {
            uint256 absDelta = uint256(-_scoreDelta);
            newScore = (currentScore >= absDelta) ? (currentScore - absDelta) : 0; // Cap at 0
        }
        members[_member].creativityScore = newScore;
        emit CreativityScoreUpdated(_member, _scoreDelta, newScore);
    }

    /**
     * @notice Selects the next epoch leader. Placeholder logic.
     * @return The address of the new epoch leader.
     */
    function _selectNewEpochLeader() internal view returns (address) {
        // In a real system, this would be based on:
        // - Highest Creativity Score in previous epoch
        // - Most successful prompts/curations
        // - Random selection weighted by staked ART / Creativity Score
        // For now, return owner or a designated address.
        return owner(); // Simplistic for example
    }

    /**
     * @notice Calculates rewards for a specific member for a given epoch. (Simplified)
     * @param _member The member for whom to calculate rewards.
     * @param _epochId The epoch for which to calculate rewards.
     * @return The calculated reward amount in ART tokens.
     */
    function _calculateEpochRewards(address _member, uint256 _epochId) internal view returns (uint256) {
        if (!members[_member].isGuildMember || _epochId == 0 || _epochId > currentEpochId) {
            return 0;
        }

        // Basic reward calculation (highly simplified for this example):
        // 1. Base reward for activity (e.g., if participated in prompt/vote/curate)
        // 2. Bonus for winning prompt in that epoch
        // 3. Bonus for high curation scores received on their NFT (if applicable)
        // 4. Multiplier based on Creativity Score
        uint256 reward = 0;
        uint256 memberCreativityScore = members[_member].creativityScore;

        // For simplicity, we'll give a fixed reward and a bonus if their prompt won
        if (members[_member].lastActivityEpoch == _epochId) {
            reward += 5 * 10**18; // 5 ART for active participation
        }

        if (epochs[_epochId].winningPromptId != 0 && prompts[epochs[_epochId].winningPromptId].submitter == _member) {
            reward += 20 * 10**18; // 20 ART bonus for winning prompt
        }
        
        // Apply Creativity Score as a multiplier (e.g., every 100 points adds 1% to base reward)
        if (memberCreativityScore > 0) {
            reward = reward + (reward * memberCreativityScore / 10000); // 10000 is 100 (for 100%) * 100 (for 100 score points)
        }

        return reward;
    }


    // --- I. Guild & Core Mechanics ---

    /**
     * @notice Allows a user to become a guild member by staking ART tokens.
     * Requires the `amount` of ART tokens to be at least `MIN_STAKE_FOR_MEMBERSHIP`.
     * The ART tokens are transferred to the guild contract.
     * @param amount The amount of ART tokens to stake.
     */
    function joinGuild(uint256 amount) public nonReentrant {
        require(!members[_msgSender()].isGuildMember, "Already a guild member");
        require(amount >= MIN_STAKE_FOR_MEMBERSHIP, "Insufficient ART staked for membership");

        require(artiumToken.transferFrom(_msgSender(), address(this), amount), "ART transfer failed");

        members[_msgSender()].isGuildMember = true;
        members[_msgSender()].stakedArt = amount;
        members[_msgSender()].creativityScore = 10; // Initial score
        members[_msgSender()].lastActivityEpoch = currentEpochId;
        members[_msgSender()].rewardsClaimedUpToEpoch = currentEpochId; // No rewards for current epoch until it concludes
        totalStakedArt += amount;

        emit GuildMemberJoined(_msgSender(), amount, members[_msgSender()].creativityScore);
    }

    /**
     * @notice Allows a guild member to leave, unstaking their ART tokens.
     * A member cannot leave if they have outstanding proposals or active challenges.
     * Their Creativity Score is reset upon leaving.
     */
    function leaveGuild() public nonReentrant onlyGuildMember {
        require(members[_msgSender()].stakedArt > 0, "No ART staked to unstake");
        // In a full system, check for active proposals/challenges:
        // require(!hasActiveProposals(_msgSender()), "Cannot leave with active proposals");
        // require(!hasActiveChallenges(_msgSender()), "Cannot leave with active challenges");

        uint256 staked = members[_msgSender()].stakedArt;
        members[_msgSender()].stakedArt = 0;
        members[_msgSender()].isGuildMember = false;
        members[_msgSender()].creativityScore = 0; // Reset score upon leaving
        members[_msgSender()].delegatedVotee = address(0); // Clear delegation
        totalStakedArt -= staked;

        require(artiumToken.transfer(_msgSender(), staked), "ART transfer failed during unstake");

        emit GuildMemberLeft(_msgSender(), staked);
    }

    /**
     * @notice Initiates a new art generation epoch with a theme and AI model seed.
     * Only callable by the current epoch leader or via a governance proposal.
     * Also responsible for concluding the previous epoch if it hasn't been already.
     * @param _theme A descriptive theme for the new epoch.
     * @param _aiModelSeed A hash or parameter set representing the AI model or style for this epoch.
     */
    function startNewEpoch(string calldata _theme, bytes32 _aiModelSeed) public nonReentrant {
        Epoch storage prevEpoch = epochs[currentEpochId];
        require(
            prevEpoch.isConcluded || _msgSender() == owner(), // Allow owner to force start for initial setup
            "Previous epoch not concluded. Wait for AI generation/minting or epoch leader to conclude."
        );
        
        // Ensure the previous epoch is marked as concluded if it wasn't by `executeAIGeneration`
        if (!prevEpoch.isConcluded) {
            prevEpoch.isConcluded = true;
            // Any epoch-end processing for previous epoch (e.g., calculating reward pool for it)
        }

        currentEpochId++; // Increment to the new epoch ID
        address newLeader = _selectNewEpochLeader(); // Select leader for the NEW epoch
        epochs.push(Epoch(
            currentEpochId,
            _theme,
            _aiModelSeed,
            block.timestamp,
            block.timestamp + EPOCH_DURATION,
            false, // New epoch is not yet concluded
            newLeader,
            0,
            0,
            0,
            0,
            PROMPT_SUBMISSION_FEE * 100 // Example: starting reward pool from 100 prompt fees. Needs to be more dynamic.
        ));

        emit EpochStarted(currentEpochId, _theme, _aiModelSeed, block.timestamp);
    }

    /**
     * @notice Retrieves details of the current active epoch.
     * @return epochId The ID of the current epoch.
     * @return theme The theme of the current epoch.
     * @return aiModelSeed The AI model seed for the current epoch.
     * @return startTime The start timestamp of the current epoch.
     * @return endTime The estimated end timestamp of the current epoch.
     * @return isConcluded True if the current epoch has concluded.
     * @return epochLeader The address of the current epoch leader.
     * @return winningPromptId The ID of the prompt selected for AI generation (0 if not yet selected).
     * @return artPieceTokenId The ID of the generated NFT (0 if not yet minted).
     */
    function getCurrentEpochDetails() public view returns (
        uint256 epochId,
        string memory theme,
        bytes32 aiModelSeed,
        uint256 startTime,
        uint256 endTime,
        bool isConcluded,
        address epochLeader,
        uint256 winningPromptId,
        uint256 artPieceTokenId
    ) {
        Epoch storage current = epochs[currentEpochId];
        return (
            current.epochId,
            current.theme,
            current.aiModelSeed,
            current.startTime,
            current.endTime,
            current.isConcluded,
            current.epochLeader,
            current.winningPromptId,
            current.artPieceTokenId
        );
    }

    // --- II. AI Art Generation & Prompt Submission ---

    /**
     * @notice Members submit text-based or data-based prompts for the AI to interpret.
     * Requires a fee in ART tokens, which contribute to the epoch's reward pool.
     * @param _promptContent The content of the prompt (e.g., "A futuristic cityscape at sunset").
     */
    function submitCreativePrompt(string calldata _promptContent) public nonReentrant onlyGuildMember notConcludedEpoch(currentEpochId) {
        require(bytes(_promptContent).length > 0, "Prompt content cannot be empty");
        require(artiumToken.transferFrom(_msgSender(), address(this), PROMPT_SUBMISSION_FEE), "Prompt fee transfer failed");

        prompts[nextPromptId] = Prompt({
            promptId: nextPromptId,
            submitter: _msgSender(),
            content: _promptContent,
            submissionTime: block.timestamp,
            totalVotes: 0,
            isSelected: false,
            epochId: currentEpochId
        });
        members[_msgSender()].lastActivityEpoch = currentEpochId;
        _updateCreativityScore(_msgSender(), 5); // Reward for submitting a prompt
        epochs[currentEpochId].totalRewardPool += PROMPT_SUBMISSION_FEE; // Add fee to reward pool

        emit PromptSubmitted(nextPromptId, _msgSender(), _promptContent, currentEpochId);
        nextPromptId++;
    }

    /**
     * @notice Members vote on the submitted prompts to decide which are most inspiring.
     * Voting power is based on staked ART and Creativity Score.
     * @param _promptIds Array of prompt IDs to vote on.
     * @param _votes Array of vote amounts for each prompt.
     */
    function voteOnPrompts(uint256[] calldata _promptIds, uint256[] calldata _votes) public nonReentrant onlyGuildMember notConcludedEpoch(currentEpochId) {
        require(_promptIds.length == _votes.length, "Mismatched arrays for prompt IDs and votes");
        uint256 memberVotingPower = _getVotingPower(_msgSender());
        uint256 totalVotesCast = 0;

        for (uint i = 0; i < _promptIds.length; i++) {
            uint256 promptId = _promptIds[i];
            uint256 voteAmount = _votes[i];

            require(prompts[promptId].epochId == currentEpochId, "Prompt not from current epoch");
            require(prompts[promptId].promptId != 0, "Prompt does not exist");
            require(!hasVotedOnPrompt[promptId][_msgSender()], "Already voted on this prompt");
            require(voteAmount > 0, "Vote amount must be positive");

            totalVotesCast += voteAmount;
            require(totalVotesCast <= memberVotingPower, "Exceeds available voting power");

            prompts[promptId].totalVotes += voteAmount;
            hasVotedOnPrompt[promptId][_msgSender()] = true;
            members[_msgSender()].lastActivityEpoch = currentEpochId;
            epochs[currentEpochId].totalPromptVotes += voteAmount;

            emit PromptVoted(promptId, _msgSender(), voteAmount);
        }
        _updateCreativityScore(_msgSender(), int256(totalVotesCast / (10**18 / 5))); // Reward for voting activity (5 Creativity/ART equivalent)
    }

    /**
     * @notice Triggered by an authorized oracle, this function finalizes the AI generation process for the epoch.
     * It uses the top-voted prompt (as determined off-chain by the oracle) and an external AI output hash.
     * @param _aiOutputHash A hash (e.g., IPFS hash, generative seed) representing the AI generated art output.
     * @param _winningPromptId The ID of the prompt selected by the oracle based on votes and AI compatibility.
     */
    function executeAIGeneration(bytes32 _aiOutputHash, uint256 _winningPromptId) public nonReentrant onlyOracle notConcludedEpoch(currentEpochId) {
        require(epochs[currentEpochId].winningPromptId == 0, "AI generation already executed for this epoch");
        require(prompts[_winningPromptId].epochId == currentEpochId, "Winning prompt not from current epoch");
        require(prompts[_winningPromptId].promptId != 0, "Winning prompt does not exist");
        require(_aiOutputHash != bytes32(0), "AI output hash cannot be zero");

        epochs[currentEpochId].winningPromptId = _winningPromptId;
        prompts[_winningPromptId].isSelected = true;

        _updateCreativityScore(prompts[_winningPromptId].submitter, 50); // Significant reward for winning prompt

        emit AIGenerationExecuted(currentEpochId, _winningPromptId, _aiOutputHash);
        // Automatically mint the NFT after generation.
        _mintArtPieceNFT(_winningPromptId, _aiOutputHash);
    }

    /**
     * @notice Internal function to mint the newly generated art piece as a dynamic ERC-721 NFT.
     * Called automatically after `executeAIGeneration`.
     * @param _promptId The ID of the winning prompt.
     * @param _aiOutputHash The AI-generated hash.
     */
    function _mintArtPieceNFT(uint256 _promptId, bytes32 _aiOutputHash) internal {
        require(epochs[currentEpochId].artPieceTokenId == 0, "Art piece already minted for this epoch");
        require(epochs[currentEpochId].winningPromptId == _promptId, "Mismatched prompt ID for minting");

        address creator = prompts[_promptId].submitter;
        uint256 tokenId = nextArtPieceTokenId;

        _safeMint(creator, tokenId);

        artPieces[tokenId] = ArtPiece({
            tokenId: tokenId,
            creator: creator,
            epochId: currentEpochId,
            aiOutputHash: _aiOutputHash,
            basePromptContent: prompts[_promptId].content,
            totalCurationScore: 0,
            numCurations: 0,
            dynamicAttributesHash: _aiOutputHash // Initial dynamic attributes are the AI output hash
        });

        epochs[currentEpochId].artPieceTokenId = tokenId;
        epochs[currentEpochId].isConcluded = true; // Conclude epoch after minting

        emit ArtPieceMinted(tokenId, creator, currentEpochId, _aiOutputHash);
        nextArtPieceTokenId++;
    }


    // --- III. Curation & Reputation (Creativity Score - SBT-like) ---

    /**
     * @notice Members review and rate generated Art Piece NFTs, influencing their on-chain attributes
     * and the original creator's Creativity Score. Can only curate pieces from concluded epochs.
     * @param _tokenId The ID of the Art Piece NFT to curate.
     * @param _rating A rating from 1 to 10 (e.g., 1=poor, 10=excellent).
     * @param _comment An optional comment for the curation.
     */
    function curateArtPiece(uint256 _tokenId, uint8 _rating, string calldata _comment) public nonReentrant onlyGuildMember {
        require(artPieces[_tokenId].tokenId != 0, "Art piece does not exist");
        require(epochs[artPieces[_tokenId].epochId].isConcluded, "Cannot curate piece from active epoch");
        require(_msgSender() != artPieces[_tokenId].creator, "Cannot curate your own art piece");
        require(artPieces[_tokenId].curatorRatings[_msgSender()] == 0, "Already curated this art piece");
        require(_rating >= 1 && _rating <= 10, "Rating must be between 1 and 10");

        ArtPiece storage artPiece = artPieces[_tokenId];
        artPiece.curatorRatings[_msgSender()] = _rating;
        artPiece.totalCurationScore += _rating;
        artPiece.numCurations++;
        epochs[artPiece.epochId].totalCurationScore += _rating; // Track for epoch rewards
        members[_msgSender()].lastActivityEpoch = currentEpochId; // Mark activity in current epoch

        // Influence creator's score based on the rating received
        int256 creatorScoreDelta = (_rating > 5) ? 10 : -5; // +10 for good rating, -5 for bad
        _updateCreativityScore(artPiece.creator, creatorScoreDelta);
        _updateCreativityScore(_msgSender(), 3); // Reward for curating

        // Update dynamic attributes hash based on new average rating (simplified for example)
        artPiece.dynamicAttributesHash = keccak256(abi.encodePacked(artPiece.aiOutputHash, artPiece.totalCurationScore, artPiece.numCurations, block.timestamp));

        emit ArtPieceCurated(_tokenId, _msgSender(), _rating, _comment);
        emit ArtPieceAttributesUpdated(_tokenId, artPiece.dynamicAttributesHash);
    }

    /**
     * @notice Allows a member to dispute a specific curation rating, initiating a mini-governance vote.
     * For simplicity, this example directly applies score changes. A full implementation would
     * involve a short-duration proposal system.
     * @param _tokenId The ID of the Art Piece NFT.
     * @param _curator The address of the curator whose rating is being disputed.
     * @param _disputedRating The rating value that is being disputed.
     */
    function challengeCuration(uint256 _tokenId, address _curator, uint8 _disputedRating) public nonReentrant onlyGuildMember {
        require(artPieces[_tokenId].tokenId != 0, "Art piece does not exist");
        require(artPieces[_tokenId].curatorRatings[_curator] == _disputedRating, "Disputed rating does not match recorded rating");
        require(_msgSender() != _curator, "Cannot challenge your own curation");
        require(artPieces[_tokenId].epochId < currentEpochId, "Cannot challenge curation of an active epoch"); // Give time for initial curation

        // Simplified outcome: challenger always wins (for example purposes).
        // In a real system, this would trigger a mini-vote among guild members.
        _updateCreativityScore(_curator, -15); // Penalize disputed curator
        _updateCreativityScore(_msgSender(), 10); // Reward challenger for successful challenge

        emit CurationChallenged(_tokenId, _curator, _disputedRating, _msgSender());
    }

    /**
     * @notice Retrieves a specific member's dynamic, non-transferable Creativity Score.
     * @param _member The address of the member.
     * @return The creativity score of the member.
     */
    function getCreativityScore(address _member) public view returns (uint256) {
        return members[_member].creativityScore;
    }

    // Function 12: _updateCreativityScore is internal.

    // --- IV. Governance & DAO ---

    /**
     * @notice Allows members to propose changes to guild parameters, AI model seeds, or contract upgrades.
     * Requires a minimum staked ART amount as defined by `PROPOSAL_THRESHOLD_ART`.
     * @param _description A clear description of the proposal.
     * @param _callData The encoded function call data for the target contract to execute if passed.
     * @param _target The target contract address for the function call.
     */
    function proposeGuildChange(string calldata _description, bytes calldata _callData, address _target) public nonReentrant onlyGuildMember {
        require(members[_msgSender()].stakedArt >= PROPOSAL_THRESHOLD_ART, "Insufficient staked ART to create proposal");
        require(bytes(_description).length > 0, "Proposal description cannot be empty");
        require(_target != address(0), "Target address cannot be zero");

        uint256 proposalId = nextProposalId;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            description: _description,
            callData: _callData,
            target: _target,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + PROPOSAL_VOTE_DURATION,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });
        nextProposalId++;
        members[_msgSender()].lastActivityEpoch = currentEpochId;
        _updateCreativityScore(_msgSender(), 10); // Reward for creating a proposal

        emit ProposalCreated(proposalId, _msgSender(), _description);
    }

    /**
     * @notice Members cast their vote (support/oppose) on active proposals.
     * Voting power is influenced by Creativity Score and staked ART.
     * Each member can only vote once per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public nonReentrant onlyGuildMember {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(!proposal.hasVoted[_msgSender()], "Already voted on this proposal");

        uint256 votingPower = _getVotingPower(_msgSender());
        require(votingPower > 0, "No voting power available");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[_msgSender()] = true;
        members[_msgSender()].lastActivityEpoch = currentEpochId;
        _updateCreativityScore(_msgSender(), 2); // Reward for voting

        emit ProposalVoted(_proposalId, _msgSender(), _support, votingPower);
    }

    /**
     * @notice Executes a passed proposal if the quorum and approval thresholds are met.
     * Callable by any member after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public nonReentrant onlyGuildMember {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "Proposal does not exist");
        require(block.timestamp > proposal.votingEndTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalProposalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 currentTotalVotingPower = totalStakedArt + (members[owner()].creativityScore * 10**18 / 100); // Approximation, should iterate all members
        // For a more precise `currentTotalVotingPower`, one might need to iterate through all members or track it separately.
        // For simplicity, we'll use totalStakedArt for quorum as a proxy.
        uint256 quorumThreshold = currentTotalVotingPower * PROPOSAL_VOTE_QUORUM_PERCENT / 100;
        
        bool quorumMet = totalProposalVotes >= quorumThreshold;
        bool approved = proposal.votesFor > proposal.votesAgainst;

        if (quorumMet && approved) {
            proposal.passed = true;
            // Execute the proposal's call data
            (bool success, ) = proposal.target.call(proposal.callData);
            require(success, "Proposal execution failed");
            _updateCreativityScore(_msgSender(), 5); // Reward for executing a successful proposal
        }
        proposal.executed = true;

        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    /**
     * @notice Members can delegate their voting power to another guild member.
     * Delegated voting power will be used when the delegatee votes.
     * @param _delegatee The address of the member to whom voting power is delegated.
     */
    function delegateVote(address _delegatee) public onlyGuildMember {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        require(_delegatee != _msgSender(), "Cannot delegate to yourself");
        require(members[_delegatee].isGuildMember, "Delegatee must be a guild member");

        members[_msgSender()].delegatedVotee = _delegatee;
        emit VoteDelegated(_msgSender(), _delegatee);
    }

    // --- V. Dynamic NFT & Rewards ---

    /**
     * @notice Retrieves the full dynamic metadata of an Art Piece NFT.
     * This metadata can evolve based on curation and other on-chain interactions.
     * @param _tokenId The ID of the Art Piece NFT.
     * @return creator The address of the prompt submitter.
     * @return epochId The epoch in which the art was created.
     * @return aiOutputHash The base AI output hash (e.g., IPFS hash).
     * @return basePromptContent The original prompt content.
     * @return totalCurationScore The sum of all curation ratings received.
     * @return numCurations The number of times the piece has been curated.
     * @return dynamicAttributesHash The hash representing current dynamic attributes.
     */
    function getArtPieceMetadata(uint256 _tokenId) public view returns (
        address creator,
        uint256 epochId,
        bytes32 aiOutputHash,
        string memory basePromptContent,
        uint256 totalCurationScore,
        uint256 numCurations,
        bytes32 dynamicAttributesHash
    ) {
        ArtPiece storage artPiece = artPieces[_tokenId];
        require(artPiece.tokenId != 0, "Art piece does not exist");

        return (
            artPiece.creator,
            artPiece.epochId,
            artPiece.aiOutputHash,
            artPiece.basePromptContent,
            artPiece.totalCurationScore,
            artPiece.numCurations,
            artPiece.dynamicAttributesHash
        );
    }

    /**
     * @notice Allows members to claim ART tokens earned from successful prompt submissions,
     * curation, and active participation in *concluded* epochs.
     * This function uses a simplified reward calculation and tracks the last epoch rewards were claimed for.
     */
    function claimEpochRewards() public nonReentrant onlyGuildMember {
        uint256 unclaimedRewards = 0;
        uint256 lastClaimed = members[_msgSender()].rewardsClaimedUpToEpoch;
        
        // Iterate through all epochs since the last claim, up to the *previous* epoch (current one not concluded yet for rewards)
        for (uint256 i = lastClaimed + 1; i < currentEpochId; i++) {
            if (epochs[i].isConcluded) {
                unclaimedRewards += _calculateEpochRewards(_msgSender(), i);
                members[_msgSender()].rewardsClaimedUpToEpoch = i; // Update for each epoch, or once at the end.
            }
        }
        
        require(unclaimedRewards > 0, "No unclaimed rewards available");
        require(artiumToken.transfer(_msgSender(), unclaimedRewards), "Reward transfer failed");
        
        emit RewardsClaimed(_msgSender(), members[_msgSender()].rewardsClaimedUpToEpoch, unclaimedRewards);
    }

    /**
     * @notice Public function, typically called by the oracle, to dynamically update an NFT's on-chain
     * attributes based on new data or external events.
     * While `curateArtPiece` updates it, this allows for other types of updates too.
     * @param _tokenId The ID of the Art Piece NFT to update.
     * @param _newAttributesHash The new hash representing the updated dynamic attributes.
     */
    function updateArtPieceAttributes(uint256 _tokenId, bytes32 _newAttributesHash) public onlyOracle {
        require(artPieces[_tokenId].tokenId != 0, "Art piece does not exist");
        artPieces[_tokenId].dynamicAttributesHash = _newAttributesHash;
        emit ArtPieceAttributesUpdated(_tokenId, _newAttributesHash);
    }


    // --- VI. Utilities & Admin ---

    /**
     * @notice Allows the guild (via governance) to update the address of the trusted oracle
     * for AI generation and dynamic NFT updates. In this example, it's `onlyOwner` for simplicity.
     * @param _newOracle The new address for the oracle.
     */
    function setOracleAddress(address _newOracle) public onlyOwner { // Should be governance controlled in production via a proposal
        require(_newOracle != address(0), "New oracle address cannot be zero");
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /**
     * @notice Allows the guild (via governance) to transfer ART tokens from the guild treasury
     * for operational costs or community initiatives. In this example, it's `onlyOwner` for simplicity.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of ART tokens to withdraw.
     */
    function withdrawGuildFunds(address _recipient, uint256 _amount) public onlyOwner { // Should be governance controlled in production via a proposal
        require(_recipient != address(0), "Recipient address cannot be zero");
        require(_amount > 0, "Amount must be positive");
        require(artiumToken.balanceOf(address(this)) >= _amount, "Insufficient guild treasury balance");
        require(artiumToken.transfer(_recipient, _amount), "Guild funds transfer failed");
        emit GuildFundsWithdrawn(_recipient, _amount);
    }

    /**
     * @notice Allows a designated role (e.g., owner, guardian multisig) to pause/unpause
     * critical contract functions in an emergency.
     * This is a placeholder; a full implementation would use OpenZeppelin's Pausable contract
     * and add `whenNotPaused` and `whenPaused` modifiers to relevant functions.
     * @param _status True to pause, false to unpause.
     */
    function emergencyPause(bool _status) public onlyOwner {
        // Example: a `bool paused` state variable would be set here,
        // and functions would use `require(!paused)` or `whenNotPaused`.
        emit EmergencyPaused(_status);
    }

    // Fallback and Receive functions to handle ETH
    // This contract primarily uses ART tokens, so ETH sent directly will be reverted by default if not handled.
    receive() external payable {
        revert("ETH not accepted. Please use Artium tokens.");
    }

    fallback() external payable {
        revert("ETH not accepted. Please use Artium tokens.");
    }

    // The `tokenURI` function for ERC721
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        ArtPiece storage artPiece = artPieces[tokenId];

        // Construct a dynamic JSON metadata string
        // In a real dApp, this would typically point to an IPFS gateway or a dedicated metadata server
        // that constructs the JSON based on the on-chain dynamicAttributesHash and other data.
        string memory baseURI = "ipfs://QmbPj8z8X4Y8k2W7G2F6K4L8D6H9J5A3C1E0A2B4D7F9H/"; // Example base IPFS CID
        
        string memory name = string(abi.encodePacked("AetherCanvas Art #", _toString(tokenId)));
        string memory description = string(abi.encodePacked("Generative AI art from Epoch ", _toString(artPiece.epochId), ". Base prompt: ", artPiece.basePromptContent, ". Curation score: ", _toString(artPiece.totalCurationScore), "/", _toString(artPiece.numCurations * 10)));
        
        // Dynamic attributes could be further processed here or by the metadata server
        string memory attributes = string(abi.encodePacked(
            '[{"trait_type": "Epoch", "value": "', _toString(artPiece.epochId), '"},',
            '{"trait_type": "AI Output Hash", "value": "', _bytes32ToHexString(artPiece.aiOutputHash), '"},',
            '{"trait_type": "Curation Score Average", "value": "', _toString(artPiece.numCurations > 0 ? (artPiece.totalCurationScore / artPiece.numCurations) : 0), '"},',
            '{"trait_type": "Dynamic Hash", "value": "', _bytes32ToHexString(artPiece.dynamicAttributesHash), '"}]'
        ));

        string memory json = string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name":"', name,
                        '","description":"', description,
                        '","image":"', baseURI, _bytes32ToHexString(artPiece.dynamicAttributesHash), '.png",', // Image points to a derived image based on dynamic hash
                        '","attributes":', attributes,
                        '}'
                    )
                )
            )
        ));
        
        return json;
    }

    // Helper function to convert uint256 to string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Helper function to convert bytes32 to hex string
    function _bytes32ToHexString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[i*2+1] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
}

// Minimal Base64 encoding for on-chain tokenURI.
// This is a simplified version and might not be fully optimized for gas,
// but demonstrates the concept for dynamic on-chain metadata.
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // calculate output length:
        // - every 3 bytes input becomes 4 bytes output
        // - padded with '=' characters at the end
        uint256 inputLength = data.length;
        uint256 outputLength = 4 * ((inputLength + 2) / 3);

        // allocate output buffer for new string
        bytes memory output = new bytes(outputLength);

        for (uint256 i = 0; i < inputLength; i += 3) {
            uint256 a = i < inputLength ? uint256(data[i]) : 0;
            uint256 b = i + 1 < inputLength ? uint256(data[i + 1]) : 0;
            uint256 c = i + 2 < inputLength ? uint256(data[i + 2]) : 0;

            uint256 d = a << 16 | b << 8 | c;

            output[i / 3 * 4] = bytes1(table[d >> 18 & 0x3F]);
            output[i / 3 * 4 + 1] = bytes1(table[d >> 12 & 0x3F]);
            output[i / 3 * 4 + 2] = bytes1(table[d >> 6 & 0x3F]);
            output[i / 3 * 4 + 3] = bytes1(table[d & 0x3F]);
        }

        // pad with '='
        unchecked {
            for (uint256 i = 0; i < 3 - inputLength % 3; i++) {
                output[outputLength - 1 - i] = "=";
            }
        }

        return string(output);
    }
}
```