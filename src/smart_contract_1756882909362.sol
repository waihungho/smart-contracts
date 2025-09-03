Here's a Solidity smart contract named "Synthetica Canvas," which is a decentralized, AI-assisted platform for generative art and lore. It incorporates advanced concepts like dynamic NFTs, a reputation system, community curation, and an AI oracle integration (simulated for on-chain interaction). The contract aims to be creative and avoid duplicating existing open-source projects by combining these elements in a novel way.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline: Synthetica Canvas - Decentralized AI-Assisted Generative Art & Lore Platform

// This contract facilitates a decentralized platform where users can submit prompts (Art Seeds or Lore Snippets),
// have them processed by an AI oracle (simulated), and then curate the AI-generated content.
// It incorporates a reputation system, dynamic soulbound-like NFTs ("Synthetica Brushes") that evolve with user
// reputation and achievements, and a reward mechanism for creators and curators.

// Function Summary:

// I. Core Contract & Governance (Owner/Admin Roles)
// 1.  constructor: Initializes the contract with admin roles, NFT details, and core parameters.
// 2.  updateAIOracleAddress: Sets/updates the address of the trusted AI oracle.
// 3.  updateCuratorMinReputation: Defines the minimum reputation required for users to curate content.
// 4.  setPromptSubmissionFee: Configures the ETH fee for submitting a new prompt.
// 5.  setOracleCallCost: Sets the internal cost associated with an AI oracle call.
// 6.  setRewardAmounts: Defines ETH reward amounts for prompt creators and successful curators.
// 7.  withdrawTreasuryFunds: Allows the admin to withdraw accumulated fees/funds from the contract treasury.
// 8.  pauseContract: Puts the contract into a paused state, halting critical operations.
// 9.  unpauseContract: Resumes operations from a paused state.
// 10. grantRole: Grants an access control role (e.g., ADMIN, AI_ORACLE) to an address.
// 11. revokeRole: Revokes an access control role from an address.
// 12. setBaseURI: Allows the admin to update the base URI for NFT metadata.

// II. Prompt & Content Submission (User Interaction)
// 13. submitPrompt: Allows users to submit a text prompt (Art Seed or Lore Snippet). Requires a submission fee.
// 14. getPromptDetails: Retrieves all relevant information for a given prompt ID.

// III. AI Oracle Integration & Content Generation
// 15. resolveAICreation: Callable *only* by the `AI_ORACLE_ROLE`. Provides the AI-generated content's IPFS CID and an initial AI quality score for a prompt.

// IV. Community Curation & Reputation System
// 16. voteOnAICreation: Curators cast up/down votes on AI-generated content based on quality and relevance.
// 17. signalDisputeOnAIResult: Allows curators to flag problematic AI-generated content for admin review.
// 18. resolveDispute: Callable by `DEFAULT_ADMIN_ROLE` to review and resolve flagged content, potentially nullifying results or adjusting scores.
// 19. getReputationPoints: Returns the current reputation score of a user.
// 20. _awardReputation: (Internal) Adds reputation points to a user for positive contributions.
// 21. _penalizeReputation: (Internal) Deducts reputation points from a user for negative actions.

// V. Dynamic NFT & Achievement System
// 22. mintSyntheticaBrushNFT: Mints a unique "Synthetica Brush" (SBT-like, dynamic ERC721) for a user. Each user can only have one.
// 23. tokenURI: Standard ERC721 function that generates dynamic metadata for a Synthetica Brush NFT based on the owner's reputation and achievements.
// 24. hasMintedBrush: Checks if a user has already minted their Synthetica Brush NFT.
// 25. getBrushTokenId: Returns the token ID of a user's Synthetica Brush NFT, if minted.

// VI. Reward Distribution
// 26. processPromptCompletion: Callable by `DEFAULT_ADMIN_ROLE` after a voting period to finalize a prompt, calculate creator/curator rewards, and trigger internal reward distribution.

contract SyntheticaCanvas is AccessControl, Pausable, ERC721URIStorage {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Roles ---
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE");
    // CURATOR_ROLE can be used for explicit privileges, but minReputation gates voting.
    // bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE"); 

    // --- State Variables ---
    Counters.Counter private _promptIds; // Counter for unique prompt IDs
    Counters.Counter private _brushTokenIds; // Counter for Synthetica Brush NFT token IDs

    uint256 public promptSubmissionFee; // Fee to submit a prompt (in wei)
    uint256 public oracleCallCost;      // Internal cost for AI oracle to process a prompt (in wei)
    uint256 public creatorRewardAmount; // Reward for original prompt creator (in wei)
    uint256 public curatorRewardPerVote; // Reward for each accurate curator vote (in wei) - simplified, real implementation would track specific voters
    uint256 public minCuratorReputation; // Minimum reputation points required to be a curator
    
    uint256 public constant BASE_REPUTATION_AWARD = 10;
    uint256 public constant BASE_REPUTATION_PENALTY = 5;
    uint256 public constant DISPUTE_THRESHOLD = 3; // Number of disputes to flag a prompt for admin review

    address public AIOracleAddress; // Address of the AI oracle (trusted off-chain component)

    // --- Enums ---
    enum PromptType { ArtSeed, LoreSnippet }
    enum PromptStatus { PendingAI, AwaitingVoting, VotingCompleted, Disputed, Finalized }

    // --- Structs ---
    struct Prompt {
        PromptType promptType;      // Type of prompt
        address creator;            // Address of the prompt creator
        uint256 submissionTime;     // Timestamp of submission
        string promptText;          // The actual prompt text
        string aiOutputCID;         // IPFS CID of the AI-generated content (e.g., image, text)
        uint256 aiQualityScore;     // AI's internal quality assessment (0-100)
        uint256 communityUpvotes;   // Number of upvotes from curators
        uint256 communityDownvotes; // Number of downvotes from curators
        uint256 disputeCount;       // Number of times this content has been flagged for dispute
        PromptStatus status;        // Current status of the prompt
        bool rewardsClaimed;        // Flag to prevent double claiming of rewards
        mapping(address => bool) hasVoted; // Tracks if a user has voted on this prompt
    }

    // --- Mappings ---
    mapping(uint256 => Prompt) public prompts;                  // promptId => Prompt struct
    mapping(address => uint256) public reputationPoints;         // user address => total reputation points
    mapping(address => uint256) private _userBrushTokenId;      // user address => brush NFT token ID
    mapping(uint256 => address) private _brushTokenIdToOwner;   // brush NFT token ID => user address (for quick lookup)
    
    // --- Events ---
    event PromptSubmitted(uint256 indexed promptId, address indexed creator, PromptType promptType, string promptText, uint256 submissionFee);
    event AICreationResolved(uint256 indexed promptId, string aiOutputCID, uint256 aiQualityScore);
    event VoteCast(uint256 indexed promptId, address indexed voter, bool isUpvote);
    event DisputeSignaled(uint256 indexed promptId, address indexed signaler);
    event DisputeResolved(uint256 indexed promptId, bool resolvedSuccessfully, address indexed userAdjusted, int256 reputationChange);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event BrushNFTMinted(address indexed owner, uint256 indexed tokenId);
    event RewardsDistributed(uint256 indexed promptId, address indexed creator, uint256 creatorAmount, uint256 totalCuratorAmount);
    event FundsWithdrawn(address indexed to, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address initialAIOracle,
        uint256 _promptSubmissionFee,
        uint256 _oracleCallCost,
        uint256 _creatorRewardAmount,
        uint256 _curatorRewardPerVote,
        uint256 _minCuratorReputation
    ) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is the default admin
        _grantRole(AI_ORACLE_ROLE, initialAIOracle); // Grant AI Oracle role to initial address

        // Set initial parameters
        _setBaseURI(baseURI_);
        AIOracleAddress = initialAIOracle;
        promptSubmissionFee = _promptSubmissionFee;
        oracleCallCost = _oracleCallCost;
        creatorRewardAmount = _creatorRewardAmount;
        curatorRewardPerVote = _curatorRewardPerVote;
        minCuratorReputation = _minCuratorReputation;
    }

    // --- I. Core Contract & Governance (Owner/Admin Roles) ---

    /// @notice Updates the address of the trusted AI oracle. Only callable by an admin.
    /// @param newAIOracle The new address for the AI oracle.
    function updateAIOracleAddress(address newAIOracle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAIOracle != address(0), "Invalid AI Oracle address");
        _revokeRole(AI_ORACLE_ROLE, AIOracleAddress); // Revoke from old
        AIOracleAddress = newAIOracle;
        _grantRole(AI_ORACLE_ROLE, newAIOracle); // Grant to new
    }

    /// @notice Updates the minimum reputation points required for users to curate content. Only callable by an admin.
    /// @param _minReputation The new minimum reputation threshold.
    function updateCuratorMinReputation(uint256 _minReputation) public onlyRole(DEFAULT_ADMIN_ROLE) {
        minCuratorReputation = _minReputation;
    }

    /// @notice Sets the fee required to submit a new prompt. Only callable by an admin.
    /// @param _fee The new prompt submission fee in wei.
    function setPromptSubmissionFee(uint256 _fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        promptSubmissionFee = _fee;
    }

    /// @notice Sets the internal cost associated with an AI oracle call. Only callable by an admin.
    /// @param _cost The new oracle call cost in wei.
    function setOracleCallCost(uint256 _cost) public onlyRole(DEFAULT_ADMIN_ROLE) {
        oracleCallCost = _cost;
    }

    /// @notice Sets the reward amounts for prompt creators and curators. Only callable by an admin.
    /// @param _creatorAmount The new reward for creators.
    /// @param _curatorAmount The new reward for curators per successful vote.
    function setRewardAmounts(uint256 _creatorAmount, uint256 _curatorAmount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        creatorRewardAmount = _creatorAmount;
        curatorRewardPerVote = _curatorAmount;
    }

    /// @notice Allows the admin to withdraw accumulated fees/funds from the contract treasury.
    /// @param to The address to send the funds to.
    /// @param amount The amount of funds to withdraw in wei.
    function withdrawTreasuryFunds(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(this).balance >= amount, "Insufficient contract balance");
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to withdraw funds");
        emit FundsWithdrawn(to, amount);
    }

    /// @notice Puts the contract into a paused state, halting critical operations. Only callable by an admin.
    function pauseContract() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Resumes operations from a paused state. Only callable by an admin.
    function unpauseContract() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
    
    // `grantRole` and `revokeRole` are inherited from AccessControl, making them available.
    // They are public and follow the access control policies defined by OpenZeppelin.

    /// @notice Allows the admin to update the base URI for NFT metadata.
    /// @param newBaseURI The new base URI string.
    function setBaseURI(string memory newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(newBaseURI);
    }

    // --- II. Prompt & Content Submission (User Interaction) ---

    /// @notice Allows users to submit a text prompt (Art Seed or Lore Snippet).
    /// @dev Requires `promptSubmissionFee` to be sent with the transaction.
    /// @param _promptType The type of prompt (ArtSeed or LoreSnippet).
    /// @param _promptText The actual text of the prompt.
    function submitPrompt(PromptType _promptType, string memory _promptText) public payable whenNotPaused {
        require(msg.value >= promptSubmissionFee, "Insufficient fee for prompt submission");
        require(bytes(_promptText).length > 0, "Prompt text cannot be empty");

        _promptIds.increment();
        uint256 newPromptId = _promptIds.current();

        prompts[newPromptId].promptType = _promptType;
        prompts[newPromptId].creator = msg.sender;
        prompts[newPromptId].submissionTime = block.timestamp;
        prompts[newPromptId].promptText = _promptText;
        prompts[newPromptId].status = PromptStatus.PendingAI; // Initial status
        prompts[newPromptId].rewardsClaimed = false;

        // In a real scenario, this would emit an event that an off-chain AI oracle service
        // listens to, to pick up the prompt and process it. The oracle would then call
        // `resolveAICreation` once done.

        emit PromptSubmitted(newPromptId, msg.sender, _promptType, _promptText, msg.value);
    }

    /// @notice Retrieves all relevant information for a given prompt ID.
    /// @param _promptId The ID of the prompt to retrieve.
    /// @return promptType_ The type of prompt.
    /// @return creator_ The address of the prompt creator.
    /// @return submissionTime_ The timestamp of submission.
    /// @return promptText_ The actual text of the prompt.
    /// @return aiOutputCID_ The IPFS CID of the AI-generated content.
    /// @return aiQualityScore_ The AI's internal quality assessment.
    /// @return communityUpvotes_ The number of upvotes.
    /// @return communityDownvotes_ The number of downvotes.
    /// @return disputeCount_ The number of disputes.
    /// @return status_ The current status of the prompt.
    function getPromptDetails(
        uint256 _promptId
    )
        public
        view
        returns (
            PromptType promptType_,
            address creator_,
            uint256 submissionTime_,
            string memory promptText_,
            string memory aiOutputCID_,
            uint256 aiQualityScore_,
            uint256 communityUpvotes_,
            uint256 communityDownvotes_,
            uint256 disputeCount_,
            PromptStatus status_
        )
    {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "Prompt does not exist");

        return (
            prompt.promptType,
            prompt.creator,
            prompt.submissionTime,
            prompt.promptText,
            prompt.aiOutputCID,
            prompt.aiQualityScore,
            prompt.communityUpvotes,
            prompt.communityDownvotes,
            prompt.disputeCount,
            prompt.status
        );
    }

    // --- III. AI Oracle Integration & Content Generation ---

    /// @notice Callable *only* by the `AI_ORACLE_ROLE`. Provides the AI-generated content's IPFS CID and an initial AI quality score for a prompt.
    /// @dev This function transitions the prompt from `PendingAI` to `AwaitingVoting` status.
    /// @param _promptId The ID of the prompt that was processed by the AI.
    /// @param _aiOutputCID The IPFS CID of the generated content (e.g., image, text).
    /// @param _aiQualityScore The AI's internal quality assessment (0-100).
    function resolveAICreation(uint256 _promptId, string memory _aiOutputCID, uint256 _aiQualityScore) public onlyRole(AI_ORACLE_ROLE) whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "Prompt does not exist");
        require(prompt.status == PromptStatus.PendingAI, "Prompt not in PendingAI status");
        require(bytes(_aiOutputCID).length > 0, "AI output CID cannot be empty");

        prompt.aiOutputCID = _aiOutputCID;
        prompt.aiQualityScore = _aiQualityScore;
        prompt.status = PromptStatus.AwaitingVoting; // Now awaiting community curation

        emit AICreationResolved(_promptId, _aiOutputCID, _aiQualityScore);
    }

    // --- IV. Community Curation & Reputation System ---

    /// @notice Allows curators to cast up/down votes on AI-generated content.
    /// @dev Users must have `minCuratorReputation` to vote. Each user can vote once per prompt.
    /// @param _promptId The ID of the prompt to vote on.
    /// @param _isUpvote True for an upvote, false for a downvote.
    function voteOnAICreation(uint256 _promptId, bool _isUpvote) public whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "Prompt does not exist");
        require(prompt.status == PromptStatus.AwaitingVoting, "Prompt is not in voting phase");
        require(reputationPoints[msg.sender] >= minCuratorReputation, "Insufficient reputation to curate");
        require(!prompt.hasVoted[msg.sender], "You have already voted on this prompt");
        require(msg.sender != prompt.creator, "Creator cannot vote on their own prompt");

        prompt.hasVoted[msg.sender] = true;

        if (_isUpvote) {
            prompt.communityUpvotes++;
            _awardReputation(msg.sender, BASE_REPUTATION_AWARD / 2); // Smaller reward for just voting
        } else {
            prompt.communityDownvotes++;
        }

        emit VoteCast(_promptId, msg.sender, _isUpvote);
    }

    /// @notice Allows curators to flag problematic AI-generated content for admin review.
    /// @dev This can be for content that is off-topic, offensive, or clearly low quality.
    /// @param _promptId The ID of the prompt to dispute.
    function signalDisputeOnAIResult(uint256 _promptId) public whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "Prompt does not exist");
        require(prompt.status == PromptStatus.AwaitingVoting, "Prompt not in voting phase");
        require(reputationPoints[msg.sender] >= minCuratorReputation, "Insufficient reputation to signal dispute");
        require(msg.sender != prompt.creator, "Creator cannot dispute their own prompt");

        prompt.disputeCount++;
        if (prompt.disputeCount >= DISPUTE_THRESHOLD) {
            prompt.status = PromptStatus.Disputed; // Change status for admin review
        }
        emit DisputeSignaled(_promptId, msg.sender);
    }

    /// @notice Callable by `DEFAULT_ADMIN_ROLE` to review and resolve flagged content.
    /// @dev Can nullify results, adjust scores, or just close the dispute.
    /// @param _promptId The ID of the disputed prompt.
    /// @param _isResolvedSuccessfully True if the dispute is resolved and content is deemed acceptable, false to reject content.
    /// @param _adjustmentReputationUser The address whose reputation should be adjusted (e.g., if a dispute was baseless or very accurate).
    /// @param _reputationChange The amount of reputation to add (positive) or deduct (negative) for the user.
    function resolveDispute(
        uint256 _promptId,
        bool _isResolvedSuccessfully,
        address _adjustmentReputationUser,
        int256 _reputationChange // Positive for award, negative for penalty
    ) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "Prompt does not exist");
        require(prompt.status == PromptStatus.Disputed, "Prompt is not in dispute status");

        if (!_isResolvedSuccessfully) {
            // If dispute successful, content is rejected
            prompt.status = PromptStatus.VotingCompleted; // Content is no longer available for voting
            prompt.aiOutputCID = ""; // Clear output
            prompt.aiQualityScore = 0; // Reset score
            _penalizeReputation(prompt.creator, BASE_REPUTATION_PENALTY * 2); // Penalize creator for failed output
        } else {
            // Dispute resolved, content is acceptable. Resume voting.
            prompt.status = PromptStatus.AwaitingVoting;
        }

        if (_adjustmentReputationUser != address(0)) {
            if (_reputationChange > 0) {
                _awardReputation(_adjustmentReputationUser, uint256(_reputationChange));
            } else if (_reputationChange < 0) {
                _penalizeReputation(_adjustmentReputationUser, uint256(-_reputationChange));
            }
        }

        emit DisputeResolved(_promptId, _isResolvedSuccessfully, _adjustmentReputationUser, _reputationChange);
    }

    /// @notice Returns the current reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation points of the user.
    function getReputationPoints(address _user) public view returns (uint256) {
        return reputationPoints[_user];
    }

    /// @notice (Internal) Adds reputation points to a user for positive contributions.
    /// @param _user The address of the user to award reputation to.
    /// @param _amount The amount of reputation points to add.
    function _awardReputation(address _user, uint256 _amount) internal {
        reputationPoints[_user] += _amount;
        emit ReputationUpdated(_user, reputationPoints[_user]);
        // Trigger NFT metadata update if user has a brush NFT
        if (_userBrushTokenId[_user] != 0) {
            _updateBrushMetadata(_userBrushTokenId[_user]);
        }
    }

    /// @notice (Internal) Deducts reputation points from a user for negative actions.
    /// @param _user The address of the user to penalize.
    /// @param _amount The amount of reputation points to deduct.
    function _penalizeReputation(address _user, uint256 _amount) internal {
        if (reputationPoints[_user] > _amount) {
            reputationPoints[_user] -= _amount;
        } else {
            reputationPoints[_user] = 0;
        }
        emit ReputationUpdated(_user, reputationPoints[_user]);
        // Trigger NFT metadata update if user has a brush NFT
        if (_userBrushTokenId[_user] != 0) {
            _updateBrushMetadata(_userBrushTokenId[_user]);
        }
    }

    // --- V. Dynamic NFT & Achievement System (Synthetica Brush) ---

    /// @notice Mints a unique "Synthetica Brush" (SBT-like, dynamic ERC721) for a user.
    /// @dev Each user can only have one brush NFT. The brush is non-transferable.
    function mintSyntheticaBrushNFT() public whenNotPaused {
        require(_userBrushTokenId[msg.sender] == 0, "You have already minted a Synthetica Brush NFT");

        _brushTokenIds.increment();
        uint256 newTokenId = _brushTokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _userBrushTokenId[msg.sender] = newTokenId;
        _brushTokenIdToOwner[newTokenId] = msg.sender;
        _updateBrushMetadata(newTokenId); // Set initial metadata

        emit BrushNFTMinted(msg.sender, newTokenId);
    }

    /// @notice Standard ERC721 function that generates dynamic metadata for a Synthetica Brush NFT.
    /// @dev The metadata reflects the owner's current reputation and achievements.
    /// @param tokenId The ID of the brush NFT.
    /// @return A URI pointing to the dynamically generated metadata JSON.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        address owner = _brushTokenIdToOwner[tokenId]; 
        uint256 rep = reputationPoints[owner];

        // This URI would typically point to an off-chain API that serves the dynamic JSON metadata
        // based on the token ID and other on-chain data fetched by the API.
        // Example: https://synthetica-canvas.xyz/api/brush/{tokenId}
        // The API would query reputationPoints[owner] to generate a fresh JSON,
        // which might include a `level` or `trait` based on reputation.
        // For this example, we directly embed a few parameters into the URI itself
        // to illustrate the dynamic nature. A real frontend would parse this.
        string memory base = _baseURI();
        string memory repString = rep.toString();
        
        // Dynamic "Level" based on reputation
        string memory level;
        if (rep < 100) level = "Novice";
        else if (rep < 500) level = "Apprentice";
        else if (rep < 2000) level = "Journeyman";
        else if (rep < 5000) level = "Master";
        else level = "Grandmaster";

        return string(abi.encodePacked(
            base,
            tokenId.toString(),
            "?reputation=", repString,
            "&level=", level
            // More dynamic traits can be added here
        ));
    }
    
    /// @notice Checks if a user has already minted their Synthetica Brush NFT.
    /// @param _user The address of the user.
    /// @return True if the user has minted a brush, false otherwise.
    function hasMintedBrush(address _user) public view returns (bool) {
        return _userBrushTokenId[_user] != 0;
    }

    /// @notice Returns the token ID of a user's Synthetica Brush NFT, if minted.
    /// @param _user The address of the user.
    /// @return The token ID, or 0 if no brush has been minted.
    function getBrushTokenId(address _user) public view returns (uint256) {
        return _userBrushTokenId[_user];
    }

    /// @notice (Internal) Function to conceptually "update" the metadata for a Synthetica Brush NFT.
    /// @dev For dynamic NFTs where metadata is served off-chain based on on-chain state,
    ///      this function merely signals that the `tokenURI` will now reflect the latest changes
    ///      (e.g., updated reputation). No explicit on-chain URI storage update is needed.
    /// @param tokenId The ID of the brush NFT.
    function _updateBrushMetadata(uint256 tokenId) internal view {
        // No explicit `_setTokenURI` needed for dynamic metadata that is generated off-chain
        // based on contract state. The `tokenURI` function itself dynamically queries the state.
        // This function acts as a reminder that the NFT's visual/textual representation has changed.
    }

    // --- VI. Reward Distribution ---

    /// @notice Callable by `DEFAULT_ADMIN_ROLE` after a voting period to finalize a prompt,
    ///         calculate creator/curator rewards, and trigger internal reward distribution.
    /// @dev This marks a prompt as `Finalized` and ensures rewards are distributed once.
    /// @param _promptId The ID of the prompt to finalize and process rewards for.
    function processPromptCompletion(uint256 _promptId) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.creator != address(0), "Prompt does not exist");
        require(prompt.status != PromptStatus.Finalized, "Prompt already finalized");
        require(!prompt.rewardsClaimed, "Rewards already claimed for this prompt");
        require(prompt.status == PromptStatus.AwaitingVoting || prompt.status == PromptStatus.VotingCompleted, "Prompt not in a state to be finalized (e.g., still PendingAI or Disputed)");
        
        prompt.status = PromptStatus.Finalized;
        prompt.rewardsClaimed = true;

        uint256 totalRewardToCurators = 0;

        // Determine if the AI creation was successful enough for rewards
        // Criteria: More upvotes than downvotes, and AI's initial quality score is decent.
        bool isSuccessfulCreation = (prompt.communityUpvotes > prompt.communityDownvotes) && (prompt.aiQualityScore >= 50);

        if (isSuccessfulCreation) {
            // Reward creator
            if (creatorRewardAmount > 0) {
                (bool success, ) = prompt.creator.call{value: creatorRewardAmount}("");
                require(success, "Failed to send creator reward");
                _awardReputation(prompt.creator, BASE_REPUTATION_AWARD * 2); // Larger rep for successful creation
            }

            // Calculate total conceptual reward for curators.
            // Distributing to individual curators based on `hasVoted` mapping is highly gas-intensive
            // if many people vote. In a real application, this would likely involve:
            // 1. A separate `claimCuratorReward(promptId)` function where curators claim their portion.
            // 2. Off-chain reward calculation and Merkle proof for on-chain claims.
            // For this example, we calculate the total amount and acknowledge it.
            totalRewardToCurators = prompt.communityUpvotes * curatorRewardPerVote;
            // Funds for curators would need to be moved to a separate pool or claimed one-by-one.
            // For simplicity, we assume this amount is now notionally available for distribution
            // (e.g., via manual admin payout or a more complex claim system).
        } else {
            // Penalize creator if creation was unsuccessful after community review
            _penalizeReputation(prompt.creator, BASE_REPUTATION_PENALTY);
        }

        emit RewardsDistributed(_promptId, prompt.creator, creatorRewardAmount, totalRewardToCurators);
    }

    // --- ERC721 Overrides for Soulbound-like NFT ---

    /// @dev Prevents transfer of Synthetica Brush NFTs, making them soulbound-like.
    ///      Allows minting (from address(0)) and burning (to address(0)).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) {
            revert("Synthetica Brush NFTs are non-transferable.");
        }
    }
}
```