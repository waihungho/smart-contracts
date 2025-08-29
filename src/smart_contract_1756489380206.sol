Here's a Solidity smart contract named `Aetherweave` that implements advanced, creative, and trendy concepts for decentralized strategic intelligence and resource allocation.

The contract features:
*   **Conviction-based Funding:** Users stake governance tokens to build "conviction" over time for specific strategic directives.
*   **Soulbound Tokens (SBTs):** Non-transferable tokens representing reputation and contribution, which influence a user's conviction multiplier.
*   **AI Oracle Integration:** A mechanism to request and receive AI-generated evaluations for directives, aiding informed decision-making.
*   **Dynamic Outcome Badges (NFTs):** NFTs minted upon directive completion, with metadata that can be updated to reflect evolving outcomes or achievements.
*   **Decentralized Strategic Directives:** A structured way for the community to propose, refine, and vote on initiatives.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For efficient tracking of staked users per directive
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI generation

/*
 * @title Aetherweave
 * @author Your Name / AI Assistant
 * @notice Aetherweave is a decentralized collective intelligence protocol for strategic resource allocation.
 * It empowers a community to collaboratively propose, refine, evaluate, and fund "Strategic Directives"
 * (e.g., research initiatives, content campaigns, community projects, investment theses).
 * The protocol incorporates advanced conviction-based funding, a non-transferable reputation system
 * (Soulbound Tokens), AI oracle integration for objective evaluation, and dynamic NFTs ("Outcome Badges")
 * to recognize successful directive completion and contributions.
 */

/*
 * Outline and Function Summary:
 *
 * I. Strategic Directive Management
 * 1.  proposeDirective(string memory _title, string memory _description, address _fundingRecipient, uint256 _requiredFunding):
 *     Allows any user to propose a new strategic directive with a title, description, and requested funding.
 * 2.  updateDirectiveDetails(uint256 _directiveId, string memory _newTitle, string memory _newDescription):
 *     Enables the original proposer (or governance) to modify the title or description of their proposed directive before it's funded.
 * 3.  submitDirectiveRefinement(uint256 _directiveId, string memory _refinementDetails):
 *     Users can suggest improvements or detailed refinements to a pending directive.
 * 4.  acceptDirectiveRefinement(uint256 _directiveId, uint256 _refinementIndex):
 *     The directive proposer (or governance) can officially incorporate a community-submitted refinement into their directive.
 * 5.  markDirectiveAsCompleted(uint256 _directiveId):
 *     Admin/governance marks a funded directive as completed, potentially triggering outcome badge minting.
 * 6.  markDirectiveAsFailed(uint256 _directiveId):
 *     Admin/governance marks a funded directive as failed, potentially allowing for fund reallocation.
 *
 * II. Conviction & Funding Mechanism
 * 7.  stakeForConviction(uint256 _directiveId, uint256 _amount):
 *     Users stake governance tokens towards a specific directive to build "conviction" over time, influencing its funding priority.
 * 8.  withdrawStake(uint256 _directiveId):
 *     Users can unstake their tokens from a directive, halting conviction accumulation.
 * 9.  getEffectiveConviction(uint256 _directiveId, address _staker):
 *     Calculates a user's current effective conviction for a directive, factoring in stake amount, duration, and reputation.
 * 10. triggerFundingRound():
 *     Initiates an automated funding round, distributing available treasury funds to top-ranked directives based on their total effective conviction.
 * 11. getCurrentFundingAllocation(uint256 _directiveId):
 *     Provides a real-time estimate of potential funding for a directive in the current funding round.
 *
 * III. Reputation & Contribution Tracking (Soulbound Tokens - SBTs)
 * 12. mintReputationBadge(address _to, uint256 _badgeType, string memory _tokenURI):
 *     Allows authorized roles (e.g., governance, directive proposers upon successful completion) to mint non-transferable SBTs to users who have made significant contributions.
 * 13. getReputationMultiplier(address _user):
 *     Retrieves a multiplier based on a user's accumulated reputation badges, impacting their effective conviction.
 * 14. revokeReputationBadge(uint256 _badgeId):
 *     Governance can revoke an SBT in cases of malfeasance or severe misconduct.
 *
 * IV. AI Oracle Integration
 * 15. requestAIDirectiveEvaluation(uint256 _directiveId, string memory _prompt):
 *     Sends a request to a configured AI oracle contract to evaluate a specific directive's feasibility, impact, or other metrics.
 * 16. receiveAIOracleFeedback(uint256 _directiveId, bytes32 _queryId, string memory _feedbackJson):
 *     A callback function, exclusively callable by the AI oracle, to submit the evaluation results for a directive.
 * 17. getLatestAIOracleFeedback(uint256 _directiveId):
 *     Retrieves the most recent AI-generated feedback for a given directive.
 *
 * V. Dynamic Outcome Badges (NFTs)
 * 18. mintOutcomeBadge(address _to, uint256 _directiveId, string memory _initialUri):
 *     Mints a unique, dynamic NFT to contributors or the proposer upon the successful completion of a funded directive. The NFT metadata can evolve.
 * 19. updateOutcomeBadgeMetadata(uint256 _badgeId, string memory _newUri):
 *     Allows for the metadata (e.g., image, description) of a minted Outcome Badge to be updated, reflecting further progress or new data related to the directive.
 *
 * VI. Treasury & Governance
 * 20. depositFunds(uint256 _amount):
 *     Allows users or external protocols to deposit ERC20 tokens into the Aetherweave treasury, fueling strategic directives.
 * 21. executeTreasuryWithdrawal(address _recipient, uint256 _amount):
 *     Governance-controlled function to withdraw funds from the treasury for protocol operations or other approved purposes.
 * 22. setGovernanceToken(address _tokenAddress):
 *     Sets the address of the ERC20 token used for staking and conviction.
 * 23. transferOwnership(address newOwner):
 *     Transfers contract ownership (admin role) to a new address.
 * 24. setConvictionGrowthRate(uint256 _newRate):
 *     Allows governance to adjust the rate at which conviction accumulates for staked tokens.
 * 25. setReputationBadgeImpact(uint256 _badgeType, uint256 _newMultiplier):
 *     Allows governance to define the multiplier each reputation badge type applies to conviction.
 */

// Custom Non-transferable ERC721 for Reputation Badges (SBTs)
contract ReputationBadges is ERC721, Ownable {
    mapping(uint256 => uint256) public tokenIdToBadgeType; // Stores the type of each badge

    constructor(address initialOwner) ERC721("Aetherweave Reputation Badge", "AERB") Ownable(initialOwner) {}

    // Override _transfer to prevent transfers for all tokens
    function _transfer(address, address, uint256) internal pure override {
        revert("AERB: Reputation badges are non-transferable.");
    }

    // Override `safeTransferFrom` and `transferFrom` to prevent transfers
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("AERB: Reputation badges are non-transferable.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("AERB: Reputation badges are non-transferable.");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("AERB: Reputation badges are non-transferable.");
    }

    /**
     * @dev Custom minting function for reputation badges.
     * @param to The address to mint the badge to.
     * @param tokenId The ID of the badge to mint.
     * @param tokenURI The URI for the badge's metadata.
     * @param badgeType The type of reputation badge.
     */
    function mint(address to, uint256 tokenId, string memory tokenURI, uint256 badgeType) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        tokenIdToBadgeType[tokenId] = badgeType;
    }

    /**
     * @dev Custom burning function for revocation by owner.
     * @param tokenId The ID of the badge to burn.
     */
    function burn(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "AERB: Badge does not exist.");
        delete tokenIdToBadgeType[tokenId]; // Clear badge type
        _burn(tokenId);
    }

    // This contract technically supports ERC721, but internally restricts transfer.
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }
}

// Custom Dynamic ERC721 for Outcome Badges
contract OutcomeBadges is ERC721, Ownable {
    constructor(address initialOwner) ERC721("Aetherweave Outcome Badge", "AEOB") Ownable(initialOwner) {}

    /**
     * @dev Custom minting function for outcome badges.
     * @param to The address to mint the badge to.
     * @param tokenId The ID of the badge to mint.
     * @param tokenURI The URI for the badge's metadata.
     */
    function mint(address to, uint256 tokenId, string memory tokenURI) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    /**
     * @dev Custom function to update metadata for dynamic NFTs.
     * @param tokenId The ID of the badge to update.
     * @param newTokenURI The new URI for the badge's metadata.
     */
    function updateTokenURI(uint256 tokenId, string memory newTokenURI) public onlyOwner {
        require(_exists(tokenId), "AEOB: Token does not exist.");
        _setTokenURI(tokenId, newTokenURI);
    }
}

// Interface for a hypothetical AI Oracle contract
interface IAIOracle {
    // Function to request an evaluation. Oracle should emit an event with queryId.
    function requestEvaluation(address callbackContract, uint256 directiveId, string memory prompt) external returns (bytes32 queryId);
}

contract Aetherweave is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---

    IERC20 public governanceToken; // The token used for staking and conviction
    ReputationBadges public reputationBadges; // SBT contract for reputation
    OutcomeBadges public outcomeBadges;     // Dynamic NFT contract for outcomes
    IAIOracle public aiOracle;              // Interface to the AI Oracle contract

    uint256 public nextDirectiveId;
    uint256 public nextReputationBadgeId;
    uint256 public nextOutcomeBadgeId;

    // Configuration for conviction calculation
    // Scaled by 1e18 for precision; 1e18 means 1x per (1 day * staked amount)
    uint256 public convictionGrowthRate = 1e18;
    uint256 public fundingRoundInterval = 7 days; // How often funding rounds occur
    uint256 public lastFundingRoundTimestamp;
    uint256 public minimumFundingThreshold = 100 * 1e18; // Minimum total conviction required for a directive to be considered (scaled)

    // Mapping for reputation badge types to their conviction multiplier (scaled by 1e18)
    // E.g., badgeType 0 -> 1x (1e18), badgeType 1 -> 1.2x (1.2e18), badgeType 2 -> 1.5x (1.5e18)
    mapping(uint256 => uint256) public reputationBadgeMultipliers;

    enum DirectiveStatus {
        Proposed,
        Accepted, // Accepted for funding (after a funding round)
        Completed,
        Failed
    }

    struct Directive {
        address proposer;
        string title;
        string description;
        address fundingRecipient;
        uint256 requiredFunding;
        DirectiveStatus status;
        uint256 createdAt;
        uint256 fundedAt;
        uint256 totalConvictionStake; // Total tokens staked for this directive (for reporting, not actual accumulated conviction)
        uint256 allocatedFunding; // Actual funding received
        // AI Oracle feedback
        string latestAIFeedback;
        uint256 latestAIFeedbackTimestamp;
        // Refinements
        string[] refinements;
    }

    struct StakerInfo {
        uint256 stakedAmount;
        uint256 lastStakeUpdate; // Timestamp of last stake/unstake or conviction calculation
        uint256 accumulatedConviction; // Actual accumulated conviction for the staker
    }

    mapping(uint256 => Directive) public directives;
    mapping(uint256 => mapping(address => StakerInfo)) public directiveStakers;
    mapping(uint256 => EnumerableSet.AddressSet) private _directiveStakersSet; // To iterate over stakers for a directive

    // Mapping from AI queryId to directiveId for async callbacks
    mapping(bytes32 => uint256) public pendingAIQueries;

    // --- Events ---
    event DirectiveProposed(uint256 indexed directiveId, address indexed proposer, string title, uint256 requiredFunding);
    event DirectiveUpdated(uint256 indexed directiveId, string newTitle, string newDescription);
    event DirectiveRefinementSubmitted(uint256 indexed directiveId, address indexed submitter, uint256 refinementIndex);
    event DirectiveRefinementAccepted(uint256 indexed directiveId, uint256 indexed refinementIndex);
    event ConvictionStaked(uint256 indexed directiveId, address indexed staker, uint256 amount, uint256 effectiveConviction);
    event ConvictionWithdrawn(uint256 indexed directiveId, address indexed staker, uint256 amount);
    event FundingRoundTriggered(uint256 indexed roundTimestamp, uint256 totalFundsDistributed);
    event DirectiveFunded(uint256 indexed directiveId, uint256 amountFunded);
    event DirectiveStatusUpdated(uint256 indexed directiveId, DirectiveStatus newStatus);
    event ReputationBadgeMinted(address indexed receiver, uint256 indexed badgeId, uint256 badgeType);
    event ReputationBadgeRevoked(address indexed holder, uint256 indexed badgeId);
    event AIOracleRequestSent(uint256 indexed directiveId, bytes32 indexed queryId, string prompt);
    event AIOracleFeedbackReceived(uint256 indexed directiveId, bytes32 indexed queryId, string feedbackJson);
    event OutcomeBadgeMinted(address indexed receiver, uint256 indexed outcomeBadgeId, uint256 indexed directiveId);
    event OutcomeBadgeMetadataUpdated(uint256 indexed outcomeBadgeId, string newUri);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event GovernanceTokenSet(address indexed newTokenAddress);
    event ConvictionGrowthRateSet(uint256 newRate);
    event ReputationBadgeImpactSet(uint256 indexed badgeType, uint256 newMultiplier);

    // --- Constructor ---
    constructor(address _governanceTokenAddress, address _aiOracleAddress) Ownable(msg.sender) {
        governanceToken = IERC20(_governanceTokenAddress);
        aiOracle = IAIOracle(_aiOracleAddress);
        reputationBadges = new ReputationBadges(address(this)); // Aetherweave contract itself is owner of SBTs
        outcomeBadges = new OutcomeBadges(address(this));     // Aetherweave contract itself is owner of NFTs
        lastFundingRoundTimestamp = block.timestamp;
        nextDirectiveId = 1;
        nextReputationBadgeId = 1;
        nextOutcomeBadgeId = 1;

        // Initialize default reputation multipliers: Badge type 0 (default) provides 1x multiplier
        reputationBadgeMultipliers[0] = 1e18; // 1x scaled
    }

    // --- Modifiers ---
    modifier onlyDirectiveProposerOrOwner(uint256 _directiveId) {
        require(directives[_directiveId].proposer != address(0), "Aetherweave: Directive does not exist.");
        require(msg.sender == directives[_directiveId].proposer || msg.sender == owner(), "Aetherweave: Not authorized for this directive.");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "Aetherweave: Only AI Oracle can call this function.");
        _;
    }

    modifier notFunded(uint256 _directiveId) {
        require(directives[_directiveId].proposer != address(0), "Aetherweave: Directive does not exist.");
        require(directives[_directiveId].status == DirectiveStatus.Proposed, "Aetherweave: Directive has already been funded or is not in proposed state.");
        _;
    }

    // --- Utility Functions ---

    /**
     * @dev Updates a staker's accumulated conviction based on the time elapsed since last update.
     * This internal function should be called before any stake/unstake operation or conviction query.
     * @param _directiveId The ID of the directive.
     * @param _staker The address of the staker.
     */
    function _updateStakerAccumulatedConviction(uint256 _directiveId, address _staker) internal {
        StakerInfo storage stakerInfo = directiveStakers[_directiveId][_staker];
        if (stakerInfo.stakedAmount == 0) return;

        uint256 timeElapsed = block.timestamp - stakerInfo.lastStakeUpdate;
        if (timeElapsed > 0) {
            // Conviction growth is linear for simplicity: amount * time * rate
            // Normalized by 1 day (86400 seconds) to make convictionGrowthRate meaningful per day.
            // Example: (100 tokens * 1 day * 1e18 rate) / (1e18 * 1 day) = 100 accumulated conviction
            uint256 newConvictionDelta = (stakerInfo.stakedAmount * timeElapsed * convictionGrowthRate) / (1e18 * 1 days);
            stakerInfo.accumulatedConviction += newConvictionDelta;
            stakerInfo.lastStakeUpdate = block.timestamp;
        }
    }

    /**
     * @dev Calculates the effective conviction for a specific staker on a directive.
     * Effective conviction is accumulated conviction multiplied by reputation multiplier.
     * @param _directiveId The ID of the directive.
     * @param _staker The address of the staker.
     * @return The calculated effective conviction.
     */
    function getEffectiveConviction(uint256 _directiveId, address _staker) public view returns (uint256) {
        StakerInfo storage stakerInfo = directiveStakers[_directiveId][_staker];
        if (stakerInfo.stakedAmount == 0) {
            return 0;
        }
        
        // Calculate current accumulated conviction including pending growth
        uint256 timeElapsed = block.timestamp - stakerInfo.lastStakeUpdate;
        uint256 currentAccumulatedConviction = stakerInfo.accumulatedConviction + ((stakerInfo.stakedAmount * timeElapsed * convictionGrowthRate) / (1e18 * 1 days));

        // Apply reputation multiplier
        uint256 reputationMult = getReputationMultiplier(_staker);
        return (currentAccumulatedConviction * reputationMult) / 1e18; // Scale back by 1e18
    }

    /**
     * @notice Retrieves the reputation multiplier for a user based on their owned badges.
     * If a user has multiple badge types, their multipliers are multiplicatively combined.
     * @param _user The address of the user.
     * @return The combined reputation multiplier (scaled by 1e18).
     */
    function getReputationMultiplier(address _user) public view returns (uint256) {
        uint256 currentEffectiveMultiplier = 1e18; // Base multiplier is 1x (scaled)
        uint256 balance = reputationBadges.balanceOf(_user);

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = reputationBadges.tokenOfOwnerByIndex(_user, i);
            uint256 badgeType = reputationBadges.tokenIdToBadgeType(tokenId);
            uint256 badgeMultiplier = reputationBadgeMultipliers[badgeType];
            
            // Multiplicatively combine multipliers (e.g., 1.2x * 1.5x = 1.8x)
            currentEffectiveMultiplier = (currentEffectiveMultiplier * badgeMultiplier) / 1e18;
        }
        return currentEffectiveMultiplier;
    }


    // --- I. Strategic Directive Management ---

    /**
     * @notice Proposes a new strategic directive.
     * @param _title The title of the directive.
     * @param _description A detailed description of the directive.
     * @param _fundingRecipient The address that will receive the funds if the directive is approved.
     * @param _requiredFunding The total amount of governance tokens required for the directive.
     */
    function proposeDirective(
        string memory _title,
        string memory _description,
        address _fundingRecipient,
        uint256 _requiredFunding
    ) external nonReentrant {
        require(bytes(_title).length > 0, "Aetherweave: Title cannot be empty.");
        require(_fundingRecipient != address(0), "Aetherweave: Invalid funding recipient.");
        require(_requiredFunding > 0, "Aetherweave: Required funding must be greater than zero.");

        uint256 id = nextDirectiveId++;
        directives[id] = Directive({
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingRecipient: _fundingRecipient,
            requiredFunding: _requiredFunding,
            status: DirectiveStatus.Proposed,
            createdAt: block.timestamp,
            fundedAt: 0,
            totalConvictionStake: 0, // This will be updated during funding round calculation
            allocatedFunding: 0,
            latestAIFeedback: "",
            latestAIFeedbackTimestamp: 0,
            refinements: new string[](0)
        });

        emit DirectiveProposed(id, msg.sender, _title, _requiredFunding);
    }

    /**
     * @notice Allows the directive proposer or owner to update its details before funding.
     * @param _directiveId The ID of the directive to update.
     * @param _newTitle The new title.
     * @param _newDescription The new description.
     */
    function updateDirectiveDetails(
        uint256 _directiveId,
        string memory _newTitle,
        string memory _newDescription
    ) external onlyDirectiveProposerOrOwner(_directiveId) notFunded(_directiveId) {
        require(bytes(_newTitle).length > 0, "Aetherweave: New title cannot be empty.");
        require(bytes(_newDescription).length > 0, "Aetherweave: New description cannot be empty.");

        directives[_directiveId].title = _newTitle;
        directives[_directiveId].description = _newDescription;

        emit DirectiveUpdated(_directiveId, _newTitle, _newDescription);
    }

    /**
     * @notice Users can submit refinements or suggestions for a directive.
     * @param _directiveId The ID of the directive.
     * @param _refinementDetails The detailed refinement suggestion.
     */
    function submitDirectiveRefinement(uint256 _directiveId, string memory _refinementDetails) external nonReentrant {
        require(directives[_directiveId].proposer != address(0), "Aetherweave: Directive does not exist.");
        require(directives[_directiveId].status == DirectiveStatus.Proposed, "Aetherweave: Directive not in proposed state.");
        require(bytes(_refinementDetails).length > 0, "Aetherweave: Refinement details cannot be empty.");

        directives[_directiveId].refinements.push(_refinementDetails);
        emit DirectiveRefinementSubmitted(_directiveId, msg.sender, directives[_directiveId].refinements.length - 1);
    }

    /**
     * @notice The directive proposer or owner can accept a submitted refinement.
     * This will effectively update the directive's description with the accepted refinement.
     * @param _directiveId The ID of the directive.
     * @param _refinementIndex The index of the refinement to accept.
     */
    function acceptDirectiveRefinement(uint256 _directiveId, uint256 _refinementIndex) external onlyDirectiveProposerOrOwner(_directiveId) notFunded(_directiveId) {
        require(_refinementIndex < directives[_directiveId].refinements.length, "Aetherweave: Invalid refinement index.");

        directives[_directiveId].description = directives[_directiveId].refinements[_refinementIndex]; // Overwrite description for simplicity
        emit DirectiveRefinementAccepted(_directiveId, _refinementIndex);
        emit DirectiveUpdated(_directiveId, directives[_directiveId].title, directives[_directiveId].description);
    }

    /**
     * @notice Admin/governance marks a funded directive as completed.
     * This may trigger the minting of Outcome Badges for contributors.
     * @param _directiveId The ID of the directive.
     */
    function markDirectiveAsCompleted(uint256 _directiveId) external onlyOwner nonReentrant {
        require(directives[_directiveId].proposer != address(0), "Aetherweave: Directive does not exist.");
        require(directives[_directiveId].status == DirectiveStatus.Accepted, "Aetherweave: Directive must be in Accepted status to be completed.");

        directives[_directiveId].status = DirectiveStatus.Completed;
        emit DirectiveStatusUpdated(_directiveId, DirectiveStatus.Completed);
    }

    /**
     * @notice Admin/governance marks a funded directive as failed.
     * Unused funds for this directive could potentially be re-allocated or returned.
     * @param _directiveId The ID of the directive.
     */
    function markDirectiveAsFailed(uint256 _directiveId) external onlyOwner nonReentrant {
        require(directives[_directiveId].proposer != address(0), "Aetherweave: Directive does not exist.");
        require(directives[_directiveId].status == DirectiveStatus.Accepted, "Aetherweave: Directive must be in Accepted status to be failed.");

        directives[_directiveId].status = DirectiveStatus.Failed;
        emit DirectiveStatusUpdated(_directiveId, DirectiveStatus.Failed);
    }

    // --- II. Conviction & Funding Mechanism ---

    /**
     * @notice Stakes governance tokens for a directive to build conviction.
     * Conviction accumulates over time and is influenced by reputation.
     * @param _directiveId The ID of the directive to stake for.
     * @param _amount The amount of tokens to stake.
     */
    function stakeForConviction(uint256 _directiveId, uint256 _amount) external nonReentrant {
        require(directives[_directiveId].proposer != address(0), "Aetherweave: Directive does not exist.");
        require(directives[_directiveId].status == DirectiveStatus.Proposed, "Aetherweave: Only proposed directives can receive stakes.");
        require(_amount > 0, "Aetherweave: Stake amount must be greater than zero.");

        StakerInfo storage stakerInfo = directiveStakers[_directiveId][msg.sender];

        // Update existing conviction before adding new stake
        _updateStakerAccumulatedConviction(_directiveId, msg.sender);

        // Transfer tokens to contract
        require(governanceToken.transferFrom(msg.sender, address(this), _amount), "Aetherweave: Token transfer failed.");

        stakerInfo.stakedAmount += _amount;
        stakerInfo.lastStakeUpdate = block.timestamp;
        _directiveStakersSet[_directiveId].add(msg.sender); // Add to enumerable set

        emit ConvictionStaked(_directiveId, msg.sender, _amount, getEffectiveConviction(_directiveId, msg.sender));
    }

    /**
     * @notice Allows a user to withdraw their staked tokens from a directive.
     * This stops conviction accumulation for the withdrawn amount.
     * @param _directiveId The ID of the directive to withdraw from.
     */
    function withdrawStake(uint256 _directiveId) external nonReentrant {
        StakerInfo storage stakerInfo = directiveStakers[_directiveId][msg.sender];
        require(stakerInfo.stakedAmount > 0, "Aetherweave: No tokens staked for this directive.");
        require(directives[_directiveId].status == DirectiveStatus.Proposed, "Aetherweave: Cannot withdraw stake from an accepted/completed directive.");

        // Update conviction before withdrawing
        _updateStakerAccumulatedConviction(_directiveId, msg.sender);

        uint256 amountToWithdraw = stakerInfo.stakedAmount;
        stakerInfo.stakedAmount = 0;
        stakerInfo.accumulatedConviction = 0; // Reset accumulated conviction for zero stake
        _directiveStakersSet[_directiveId].remove(msg.sender);

        require(governanceToken.transfer(msg.sender, amountToWithdraw), "Aetherweave: Withdrawal failed.");
        emit ConvictionWithdrawn(_directiveId, msg.sender, amountToWithdraw);
    }

    /**
     * @notice Triggers a funding round, allocating available treasury funds to top-ranked directives.
     * This function can only be called after a defined `fundingRoundInterval`.
     * This iteration can be gas-intensive for many directives/stakers.
     * A more scalable solution might involve off-chain calculation with on-chain verification or a capped iteration.
     */
    function triggerFundingRound() external nonReentrant {
        require(block.timestamp >= lastFundingRoundTimestamp + fundingRoundInterval, "Aetherweave: Funding round not yet due.");

        lastFundingRoundTimestamp = block.timestamp;
        uint256 totalAvailableFunds = governanceToken.balanceOf(address(this));
        uint256 totalEffectiveConvictionAcrossAllDirectives = 0;

        // Collect proposed directives and their total effective conviction
        uint256[] memory eligibleDirectiveIds = new uint256[](nextDirectiveId - 1); // Max possible directives
        uint256 currentEligibleCount = 0;

        for (uint256 i = 1; i < nextDirectiveId; i++) {
            Directive storage directive = directives[i];
            if (directive.status == DirectiveStatus.Proposed) {
                uint256 currentDirectiveTotalConviction = 0;
                // Update and sum up conviction for all stakers of this directive
                for (uint256 j = 0; j < _directiveStakersSet[i].length(); j++) {
                    address staker = _directiveStakersSet[i].at(j);
                    _updateStakerAccumulatedConviction(i, staker); // Update individual staker's conviction
                    currentDirectiveTotalConviction += getEffectiveConviction(i, staker);
                }

                if (currentDirectiveTotalConviction >= minimumFundingThreshold) {
                    // Update the directive's conviction summary (not directly used for funding, but for public info)
                    directive.totalConvictionStake = currentDirectiveTotalConviction;
                    totalEffectiveConvictionAcrossAllDirectives += currentDirectiveTotalConviction;
                    eligibleDirectiveIds[currentEligibleCount++] = i;
                }
            }
        }

        uint256 totalFundsDistributed = 0;
        if (totalEffectiveConvictionAcrossAllDirectives > 0 && totalAvailableFunds > 0 && currentEligibleCount > 0) {
            for (uint256 i = 0; i < currentEligibleCount; i++) {
                uint256 directiveId = eligibleDirectiveIds[i];
                Directive storage directive = directives[directiveId];
                
                // Recalculate conviction to ensure it's up-to-date for funding decision
                uint256 directiveEffectiveConviction = 0;
                for (uint256 j = 0; j < _directiveStakersSet[directiveId].length(); j++) {
                    address staker = _directiveStakersSet[directiveId].at(j);
                    directiveEffectiveConviction += getEffectiveConviction(directiveId, staker);
                }

                if (directiveEffectiveConviction == 0 || directiveEffectiveConviction < minimumFundingThreshold) continue; // Skip if conviction dropped

                // Calculate funding share based on conviction proportion
                uint256 fundingShare = (directiveEffectiveConviction * totalAvailableFunds) / totalEffectiveConvictionAcrossAllDirectives;

                // Cap funding at required amount and ensure funds remain
                if (fundingShare > directive.requiredFunding) {
                    fundingShare = directive.requiredFunding;
                }

                if (fundingShare > 0 && totalFundsDistributed + fundingShare <= totalAvailableFunds) {
                    require(governanceToken.transfer(directive.fundingRecipient, fundingShare), "Aetherweave: Funding transfer failed.");
                    directive.allocatedFunding = fundingShare;
                    directive.status = DirectiveStatus.Accepted;
                    directive.fundedAt = block.timestamp;
                    totalFundsDistributed += fundingShare;
                    emit DirectiveFunded(directiveId, fundingShare);
                    emit DirectiveStatusUpdated(directiveId, DirectiveStatus.Accepted);
                }
            }
        }
        emit FundingRoundTriggered(block.timestamp, totalFundsDistributed);
    }

    /**
     * @notice Provides a real-time estimate of potential funding for a directive in the current round.
     * This is a view function and does not trigger the funding round.
     * @param _directiveId The ID of the directive.
     * @return The estimated funding amount.
     */
    function getCurrentFundingAllocation(uint256 _directiveId) public view returns (uint256) {
        require(directives[_directiveId].proposer != address(0), "Aetherweave: Directive does not exist.");
        require(directives[_directiveId].status == DirectiveStatus.Proposed, "Aetherweave: Directive not in proposed state.");

        uint256 totalAvailableFunds = governanceToken.balanceOf(address(this));
        uint256 totalEffectiveConvictionAcrossAllDirectives = 0;
        uint256 currentDirectiveEffectiveConviction = 0;

        // Calculate total effective conviction for the target directive
        for (uint256 j = 0; j < _directiveStakersSet[_directiveId].length(); j++) {
            address staker = _directiveStakersSet[_directiveId].at(j);
            currentDirectiveEffectiveConviction += getEffectiveConviction(_directiveId, staker);
        }

        if (currentDirectiveEffectiveConviction < minimumFundingThreshold) return 0;

        // Calculate total effective conviction across all proposed directives (for the denominator)
        for (uint256 i = 1; i < nextDirectiveId; i++) {
            Directive storage directive = directives[i];
            if (directive.status == DirectiveStatus.Proposed) {
                uint256 directiveTotalEffectiveConviction = 0;
                for (uint256 j = 0; j < _directiveStakersSet[i].length(); j++) {
                    address staker = _directiveStakersSet[i].at(j);
                    directiveTotalEffectiveConviction += getEffectiveConviction(i, staker);
                }
                if (directiveTotalEffectiveConviction >= minimumFundingThreshold) {
                    totalEffectiveConvictionAcrossAllDirectives += directiveTotalEffectiveConviction;
                }
            }
        }

        if (totalEffectiveConvictionAcrossAllDirectives == 0 || totalAvailableFunds == 0) {
            return 0;
        }

        uint256 fundingShare = (currentDirectiveEffectiveConviction * totalAvailableFunds) / totalEffectiveConvictionAcrossAllDirectives;
        return (fundingShare > directives[_directiveId].requiredFunding) ? directives[_directiveId].requiredFunding : fundingShare;
    }


    // --- III. Reputation & Contribution Tracking (Soulbound Tokens - SBTs) ---

    /**
     * @notice Mints a non-transferable reputation badge (SBT) to a user.
     * Callable only by the contract owner (or a DAO governance mechanism in a fully decentralized setup).
     * @param _to The address to mint the badge to.
     * @param _badgeType An identifier for the type of reputation badge (e.g., 0 for "Contributor", 1 for "Refinement Expert").
     * @param _tokenURI The URI for the badge's metadata (e.g., IPFS hash).
     */
    function mintReputationBadge(address _to, uint256 _badgeType, string memory _tokenURI) external onlyOwner nonReentrant {
        uint256 newBadgeId = nextReputationBadgeId++;
        reputationBadges.mint(_to, newBadgeId, _tokenURI, _badgeType);
        emit ReputationBadgeMinted(_to, newBadgeId, _badgeType);
    }

    /**
     * @notice Governance can revoke a reputation badge (SBT) from a user.
     * @param _badgeId The ID of the badge to revoke.
     */
    function revokeReputationBadge(uint256 _badgeId) external onlyOwner nonReentrant {
        // `ownerOf` check is implicit in `reputationBadges.burn` if it requires caller to be owner.
        // As Aetherweave is the owner of ReputationBadges, it can burn any token.
        reputationBadges.burn(_badgeId);
        emit ReputationBadgeRevoked(address(0), _badgeId); // Event won't contain `_from` directly from `burn`
    }

    // --- IV. AI Oracle Integration ---

    /**
     * @notice Requests an evaluation for a directive from the configured AI oracle.
     * @param _directiveId The ID of the directive to evaluate.
     * @param _prompt The specific prompt/question for the AI oracle.
     */
    function requestAIDirectiveEvaluation(uint256 _directiveId, string memory _prompt) external onlyOwner nonReentrant {
        require(directives[_directiveId].proposer != address(0), "Aetherweave: Directive does not exist.");
        require(address(aiOracle) != address(0), "Aetherweave: AI Oracle address not set.");

        bytes32 queryId = aiOracle.requestEvaluation(address(this), _directiveId, _prompt);
        pendingAIQueries[queryId] = _directiveId; // Map queryId to directiveId for callback

        emit AIOracleRequestSent(_directiveId, queryId, _prompt);
    }

    /**
     * @notice Callback function for the AI oracle to submit evaluation results.
     * This function can only be called by the trusted AI oracle contract.
     * @param _directiveId The ID of the directive that was evaluated.
     * @param _queryId The ID of the original query.
     * @param _feedbackJson The AI's evaluation feedback in JSON format.
     */
    function receiveAIOracleFeedback(uint256 _directiveId, bytes32 _queryId, string memory _feedbackJson) external onlyAIOracle {
        require(pendingAIQueries[_queryId] == _directiveId, "Aetherweave: Invalid or unmatched query ID.");
        
        directives[_directiveId].latestAIFeedback = _feedbackJson;
        directives[_directiveId].latestAIFeedbackTimestamp = block.timestamp;
        delete pendingAIQueries[_queryId]; // Clean up pending query

        emit AIOracleFeedbackReceived(_directiveId, _queryId, _feedbackJson);
    }

    /**
     * @notice Retrieves the latest AI-generated feedback for a given directive.
     * @param _directiveId The ID of the directive.
     * @return The latest AI feedback string and its timestamp.
     */
    function getLatestAIOracleFeedback(uint256 _directiveId) external view returns (string memory, uint256) {
        require(directives[_directiveId].proposer != address(0), "Aetherweave: Directive does not exist.");
        return (directives[_directiveId].latestAIFeedback, directives[_directiveId].latestAIFeedbackTimestamp);
    }


    // --- V. Dynamic Outcome Badges (NFTs) ---

    /**
     * @notice Mints a dynamic Outcome Badge NFT upon successful completion of a directive.
     * Callable only by the contract owner (or a DAO governance).
     * @param _to The address to mint the badge to.
     * @param _directiveId The ID of the directive associated with this outcome.
     * @param _initialUri The initial URI for the NFT metadata, representing the outcome.
     */
    function mintOutcomeBadge(address _to, uint256 _directiveId, string memory _initialUri) external onlyOwner nonReentrant {
        require(directives[_directiveId].proposer != address(0), "Aetherweave: Directive does not exist.");
        // Optionally, require directive to be completed for automatic minting:
        // require(directives[_directiveId].status == DirectiveStatus.Completed, "Aetherweave: Directive not completed.");

        uint256 newBadgeId = nextOutcomeBadgeId++;
        outcomeBadges.mint(_to, newBadgeId, _initialUri);
        emit OutcomeBadgeMinted(_to, newBadgeId, _directiveId);
    }

    /**
     * @notice Allows updating the metadata URI of an existing Outcome Badge.
     * This makes the NFT dynamic, reflecting ongoing progress or updated results.
     * Callable only by the contract owner.
     * @param _badgeId The ID of the Outcome Badge NFT.
     * @param _newUri The new URI pointing to updated metadata.
     */
    function updateOutcomeBadgeMetadata(uint256 _badgeId, string memory _newUri) external onlyOwner nonReentrant {
        outcomeBadges.updateTokenURI(_badgeId, _newUri);
        emit OutcomeBadgeMetadataUpdated(_badgeId, _newUri);
    }


    // --- VI. Treasury & Governance ---

    /**
     * @notice Allows users or external protocols to deposit governance tokens into the treasury.
     * These funds will be used for funding approved strategic directives.
     * @param _amount The amount of tokens to deposit.
     */
    function depositFunds(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Aetherweave: Deposit amount must be greater than zero.");
        require(governanceToken.transferFrom(msg.sender, address(this), _amount), "Aetherweave: Deposit failed.");
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @notice Allows the contract owner (governance) to withdraw funds from the treasury.
     * This is intended for protocol operations or special allocations not covered by funding rounds.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of tokens to withdraw.
     */
    function executeTreasuryWithdrawal(address _recipient, uint256 _amount) external onlyOwner nonReentrant {
        require(_recipient != address(0), "Aetherweave: Invalid recipient address.");
        require(_amount > 0, "Aetherweave: Withdrawal amount must be greater than zero.");
        require(governanceToken.balanceOf(address(this)) >= _amount, "Aetherweave: Insufficient treasury balance.");

        require(governanceToken.transfer(_recipient, _amount), "Aetherweave: Withdrawal failed.");
        emit FundsWithdrawn(_recipient, _amount);
    }

    /**
     * @notice Sets the address of the ERC20 governance token.
     * Can only be set by the contract owner.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function setGovernanceToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Aetherweave: Invalid token address.");
        governanceToken = IERC20(_tokenAddress);
        emit GovernanceTokenSet(_tokenAddress);
    }

    /**
     * @notice Transfers ownership of the contract.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /**
     * @notice Allows governance to adjust the rate at which conviction accumulates for staked tokens.
     * @param _newRate The new conviction growth rate (scaled by 1e18, e.g., 1e18 for 1x).
     */
    function setConvictionGrowthRate(uint256 _newRate) external onlyOwner {
        convictionGrowthRate = _newRate;
        emit ConvictionGrowthRateSet(_newRate);
    }

    /**
     * @notice Allows governance to define the multiplier each reputation badge type applies to conviction.
     * @param _badgeType The identifier for the reputation badge type.
     * @param _newMultiplier The new multiplier (scaled by 1e18, e.g., 1.5e18 for 1.5x).
     */
    function setReputationBadgeImpact(uint256 _badgeType, uint256 _newMultiplier) external onlyOwner {
        reputationBadgeMultipliers[_badgeType] = _newMultiplier;
        emit ReputationBadgeImpactSet(_badgeType, _newMultiplier);
    }

    // Fallback function to prevent accidental ETH deposits
    fallback() external {
        revert("Aetherweave: ETH not accepted directly. Use depositFunds for ERC20.");
    }

    receive() external payable {
        revert("Aetherweave: ETH not accepted directly. Use depositFunds for ERC20.");
    }
}
```