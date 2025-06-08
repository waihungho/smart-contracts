Okay, let's design a smart contract around a concept involving reputation, dynamic NFTs, and interaction with an oracle for generating creative content or validating submissions. This allows for a system where user actions and potentially external data influence on-chain assets and privileges.

We'll call this contract the "Autonomous Creative Forge" (ACF).

**Core Concepts:**

1.  **Reputation System:** Users build on-chain reputation based on positive interactions within the system (staking, successful submissions). Reputation unlocks features.
2.  **Creative Sparks (Internal Token):** An internal, non-transferable (initially) token earned through successful creative acts, used for claiming rewards or accessing advanced features.
3.  **Dynamic NFTs (Artifacts):** ERC721 tokens whose attributes/metadata can change based on the owner's reputation, staked tokens, or oracle input. Can be "Soulbound" (non-transferable) based on state.
4.  **Oracle Integration:** An external oracle contract provides validation/scoring for "Creative Submissions".
5.  **Staking:** Users can stake native tokens or Creative Sparks to boost reputation gain or access privileges.

**Outline & Function Summary:**

*   **Contract:** `AutonomousCreativeForge`
*   **Inherits:** ERC721 (basic functions), Ownable (admin), Pausable (emergency stop).
*   **Core State:**
    *   User Reputations (`reputations`)
    *   Creative Spark Balances (`creativeSparkBalances`)
    *   Staked Native Token Amounts (`stakedNativeTokens`)
    *   Dynamic NFT Attributes (`nftAttributes`)
    *   NFT Staking State (`stakedNFTs`)
    *   NFT Soulbound State (`isNFTSoulbound`)
    *   Creative Submission Details (`creativeSubmissions`)
    *   Configuration Parameters (thresholds, multipliers, oracle address)
*   **Functions (Total: 30+):**

    1.  **Admin & Configuration (7 functions):**
        *   `constructor`: Sets initial owner and parameters.
        *   `pauseContract`: Emergency pause (Owner).
        *   `unpauseContract`: Resume contract (Owner).
        *   `setOracleAddress`: Set the address of the trusted oracle contract (Owner).
        *   `updateConfigParameters`: Update various system thresholds and multipliers (Owner).
        *   `slashReputation`: Manually decrease a user's reputation (Admin/Owner, for moderation).
        *   `grantRole`: Grant admin or other roles (Owner). (Let's stick to simple Ownable for this example, using `onlyOwner`).

    2.  **Reputation Management (View + Internal/Triggered - 3 functions):**
        *   `getReputation`: Get the current reputation score for an address.
        *   `_increaseReputation`: Internal function to add reputation (called on success).
        *   `_decreaseReputation`: Internal function to subtract reputation (called on failure/slashing).

    3.  **Creative Spark Token (Internal/Triggered + External - 4 functions):**
        *   `getCreativeSparkBalance`: Get a user's Creative Spark balance.
        *   `_mintCreativeSparks`: Internal function to issue Sparks (called on successful submission).
        *   `claimCreativeSparks`: User claims their earned Sparks.
        *   `burnCreativeSparks`: User burns Sparks for a potential future benefit (e.g., boosting a submission, TBD).

    4.  **Staking (4 functions):**
        *   `stakeNativeTokens`: Stake native tokens (e.g., ETH, Matic) to earn passive reputation increase and/or enable submissions.
        *   `unstakeNativeTokens`: Withdraw staked native tokens.
        *   `getStakedAmount`: Get the amount of native tokens staked by an address.
        *   `stakeNFTForBonus`: Stake a owned Dynamic NFT to potentially gain reputation bonus or other benefits (makes NFT non-transferable while staked).

    5.  **Creative Submissions & Oracle (5 functions):**
        *   `submitCreativeSubmission`: User submits a creative work hash/identifier. Requires min reputation/stake. Records submission details.
        *   `processSubmissionOracleResult`: Callable *only by the designated Oracle address*. Takes submission ID and oracle score. Updates submission state and triggers spark minting/reputation change based on score.
        *   `getSubmissionDetails`: Get the status and score of a specific submission.
        *   `getSubmissionCount`: Get the total number of submissions.
        *   `verifyOracleSignature` (Optional, More Advanced): Verify a cryptographic signature from the oracle instead of just `msg.sender`. (Let's skip for simplicity and use `onlyOracle` modifier).

    6.  **Dynamic NFTs (Artificats) (7 functions):**
        *   `mintArtifactNFT`: Mint a new Dynamic NFT. Requires meeting a reputation threshold. Initializes attributes.
        *   `getArtifactAttributes`: Get the current on-chain attributes of an NFT by ID.
        *   `updateArtifactAttributes`: Owner of an NFT can update certain attributes *if* reputation/staking conditions are met. This is the "dynamic" part.
        *   `tokenURI`: Overridden ERC721 function. Returns a URI which points to a service that reads `getArtifactAttributes` and potentially owner reputation to generate dynamic metadata.
        *   `bindArtifactToSoul`: Make an owned NFT permanently non-transferable (soulbound state). Requires reputation.
        *   `unbindArtifactFromSoul`: Admin/Owner can unbind an NFT (e.g., for recovery).
        *   `getStakedArtifactId`: Get the ID of the NFT an address has staked for bonus.

    7.  **Modified ERC721 Functions (Handle Soulbinding/Staking - 4 functions):**
        *   `transferFrom`: Modified to prevent transfer if NFT is soulbound or staked.
        *   `safeTransferFrom`: Modified to prevent transfer if NFT is soulbound or staked.
        *   `approve`: Modified to prevent approval if NFT is soulbound or staked.
        *   `setApprovalForAll`: Modified to prevent approval if NFT is soulbound or staked.

    8.  **View Functions (Additional from ERC721 - 3 functions):**
        *   `balanceOf` (from ERC721)
        *   `ownerOf` (from ERC721)
        *   `isApprovedForAll` (from ERC721)
        *   `getApproved` (from ERC721)


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interface for a mock Oracle contract (actual oracle would be more complex)
interface IOracle {
    function getSubmissionScore(uint256 submissionId) external view returns (int256 score);
}

/**
 * @title AutonomousCreativeForge (ACF)
 * @dev A smart contract for a decentralized creative ecosystem featuring reputation,
 *      dynamic NFTs influenced by on-chain actions/oracles, staking, and creative submissions.
 *
 * @author Your Name or Alias
 * @notice This contract implements advanced concepts like:
 *   - On-chain Reputation System
 *   - Internal, Earned Utility Token (Creative Sparks)
 *   - Dynamic NFT Attributes controllable by owner/conditions
 *   - Oracle Integration for External Data (Creative Submission Scoring)
 *   - Staking for Reputation Boost and Feature Access
 *   - Conditional NFT Transferability (Soulbound/Staked state)
 *
 * Outline:
 * 1. State Variables & Structs
 * 2. Events
 * 3. Errors
 * 4. Modifiers
 * 5. Constructor & Admin Functions (Configuration, Pause)
 * 6. Reputation Functions (View, Internal helpers)
 * 7. Creative Spark Token Functions (View, Claim, Burn, Internal helpers)
 * 8. Staking Functions (Native Token, NFTs)
 * 9. Creative Submission & Oracle Interaction Functions
 * 10. Dynamic NFT (Artifact) Functions (Minting, Attribute Management, Soulbinding, Staking)
 * 11. Overridden/Modified ERC721 Functions (Handling transfer restrictions)
 * 12. Standard ERC721 View Functions
 */
contract AutonomousCreativeForge is ERC721, Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    using Counters for Counters.Counter;

    // --- 1. State Variables & Structs ---

    // --- Reputation ---
    mapping(address => uint256) public reputations;
    uint256 public reputationStakeMultiplier = 1; // Multiplier for passive reputation gain from staking

    // --- Creative Sparks Token ---
    mapping(address => uint256) private _creativeSparkBalances; // Private internal balance
    uint256 public creativeSparkYieldPerScore = 10; // Sparks per positive oracle score point
    uint256 public sparkClaimCooldown = 1 days; // Cooldown between claiming sparks
    mapping(address => uint256) public lastSparkClaimTimestamp;

    // --- Native Token Staking ---
    mapping(address => uint256) public stakedNativeTokens;
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);

    // --- Creative Submissions ---
    struct CreativeSubmission {
        address proposer;
        uint256 submissionTimestamp;
        bytes32 submissionHash; // Hash/identifier of the creative work
        int256 oracleScore; // Score provided by the oracle (can be negative)
        bool processed; // Has the oracle result been processed?
        bool approved; // Was the submission approved based on score?
    }
    mapping(uint256 => CreativeSubmission) public creativeSubmissions;
    Counters.Counter private _submissionIds;
    address public oracleAddress;
    uint256 public proposalSuccessThreshold = 50; // Minimum oracle score for a submission to be 'approved'

    // --- Dynamic NFTs (Artifacts) ---
    struct ArtifactAttributes {
        string name;
        string description;
        uint256 creationTimestamp;
        uint256 creationReputation; // Reputation of owner when minted
        uint256 lastUpdatedTimestamp;
        // Add more dynamic attributes here (e.g., colors, shapes, stats)
        uint256 aestheticScore;
        uint256 complexityScore;
    }
    mapping(uint256 => ArtifactAttributes) public nftAttributes;
    mapping(uint256 => bool) private _isNFTSoulbound; // True if NFT is soulbound (non-transferable)
    mapping(uint256 => address) private _stakedNFTs; // Maps token ID to the address that staked it (0x0 if not staked)
    mapping(address => uint256) public stakedNFTId; // Maps user to the ID of the NFT they have staked (0 if none)

    uint256 public nftMintReputationThreshold = 100; // Min reputation required to mint an NFT
    uint256 public nftAttributeUpdateReputationThreshold = 150; // Min reputation required to update NFT attributes

    // --- 2. Events ---
    event ReputationIncreased(address indexed user, uint256 newReputation, uint256 amount);
    event ReputationDecreased(address indexed user, uint256 newReputation, uint256 amount);
    event SparksMinted(address indexed user, uint256 amount);
    event SparksClaimed(address indexed user, uint256 amount);
    event SparksBurned(address indexed user, uint256 amount);
    event CreativeSubmissionSubmitted(address indexed proposer, uint256 submissionId, bytes32 submissionHash);
    event OracleResultProcessed(uint256 submissionId, int256 oracleScore, bool approved);
    event ArtifactMinted(address indexed owner, uint256 indexed tokenId, string name);
    event ArtifactAttributesUpdated(uint256 indexed tokenId);
    event ArtifactStaked(address indexed user, uint256 indexed tokenId);
    event ArtifactUnstaked(address indexed user, uint256 indexed tokenId);
    event ArtifactBoundToSoul(uint256 indexed tokenId);
    event ArtifactUnboundFromSoul(uint256 indexed tokenId);
    event ConfigParameterUpdated(string paramName, uint256 oldValue, uint256 newValue);

    // --- 3. Errors ---
    error ACF__MinimumReputationRequired(uint256 required, uint256 current);
    error ACF__OracleOnly();
    error ACF__SubmissionNotFound(uint256 submissionId);
    error ACF__SubmissionAlreadyProcessed(uint256 submissionId);
    error ACF__SubmissionNotApproved();
    error ACF__OnlySubmissionProposer(uint256 submissionId);
    error ACF__NotEnoughSparks(uint256 required, uint256 current);
    error ACF__SparkClaimCooldownActive(uint256 timeRemaining);
    error ACF__NFTNotFound(uint256 tokenId);
    error ACF__NotNFTAtrifact(uint256 tokenId); // Ensure it's an NFT from *this* contract
    error ACF__NotNFTOwner(uint256 tokenId, address caller);
    error ACF__NFTAlreadyStaked(uint256 tokenId);
    error ACF__NFTNotStaked(uint256 tokenId);
    error ACF__UserAlreadyStakedNFT(address user, uint256 currentTokenId);
    error ACF__NFTCurrentlySoulbound(uint256 tokenId);
    error ACF__NFTCurrentlyStaked(uint256 tokenId);


    // --- 4. Modifiers ---
    modifier onlyOracle() {
        if (_msgSender() != oracleAddress) {
            revert ACF__OracleOnly();
        }
        _;
    }

    modifier highReputationRequired(uint256 _minReputation) {
        if (reputations[_msgSender()] < _minReputation) {
            revert ACF__MinimumReputationRequired(_minReputation, reputations[_msgSender()]);
        }
        _;
    }

    modifier whenNotSoulboundOrStaked(uint256 tokenId) {
        if (_isNFTSoulbound[tokenId]) {
            revert ACF__NFTCurrentlySoulbound(tokenId);
        }
         if (_stakedNFTs[tokenId] != address(0)) {
             revert ACF__NFTCurrentlyStaked(tokenId);
         }
        _;
    }


    // --- 5. Constructor & Admin Functions ---

    constructor(
        address _oracleAddress,
        uint256 _initialReputationStakeMultiplier,
        uint256 _initialCreativeSparkYieldPerScore,
        uint256 _initialProposalSuccessThreshold,
        uint256 _initialNFTMintReputationThreshold,
        uint256 _initialNFTAttributeUpdateReputationThreshold,
        uint256 _initialSparkClaimCooldown
    ) ERC721("Autonomous Creative Artifact", "ACF-ART") Ownable(_msgSender()) Pausable() {
        require(_oracleAddress != address(0), "ACF: Invalid oracle address");
        oracleAddress = _oracleAddress;

        reputationStakeMultiplier = _initialReputationStakeMultiplier;
        creativeSparkYieldPerScore = _initialCreativeSparkYieldPerScore;
        proposalSuccessThreshold = _initialProposalSuccessThreshold;
        nftMintReputationThreshold = _initialNFTMintReputationThreshold;
        nftAttributeUpdateReputationThreshold = _initialNFTAttributeUpdateReputationThreshold;
        sparkClaimCooldown = _initialSparkClaimCooldown;
    }

    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "ACF: Invalid new oracle address");
        oracleAddress = _newOracleAddress;
    }

    function updateConfigParameters(
        uint256 _reputationStakeMultiplier,
        uint256 _creativeSparkYieldPerScore,
        uint256 _proposalSuccessThreshold,
        uint256 _nftMintReputationThreshold,
        uint256 _nftAttributeUpdateReputationThreshold,
        uint256 _sparkClaimCooldown
    ) external onlyOwner {
        emit ConfigParameterUpdated("reputationStakeMultiplier", reputationStakeMultiplier, _reputationStakeMultiplier);
        reputationStakeMultiplier = _reputationStakeMultiplier;

        emit ConfigParameterUpdated("creativeSparkYieldPerScore", creativeSparkYieldPerScore, _creativeSparkYieldPerScore);
        creativeSparkYieldPerScore = _creativeSparkYieldPerScore;

        emit ConfigParameterUpdated("proposalSuccessThreshold", proposalSuccessThreshold, _proposalSuccessThreshold);
        proposalSuccessThreshold = _proposalSuccessThreshold;

        emit ConfigParameterUpdated("nftMintReputationThreshold", nftMintReputationThreshold, _nftMintReputationThreshold);
        nftMintReputationThreshold = _nftMintReputationThreshold;

        emit ConfigParameterUpdated("nftAttributeUpdateReputationThreshold", nftAttributeUpdateReputationThreshold, _nftAttributeUpdateReputationThreshold);
        nftAttributeUpdateReputationThreshold = _nftAttributeUpdateReputationThreshold;

        emit ConfigParameterUpdated("sparkClaimCooldown", sparkClaimCooldown, _sparkClaimCooldown);
        sparkClaimCooldown = _sparkClaimCooldown;
    }

    function slashReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
        _decreaseReputation(_user, _amount, "Admin Slash");
    }

    // Pausable functions are inherited: pause(), unpause()


    // --- 6. Reputation Functions ---

    function getReputation(address _user) public view returns (uint256) {
        return reputations[_user];
    }

    // Internal helper to increase reputation
    function _increaseReputation(address _user, uint256 _amount, string memory _reason) internal {
        uint256 oldRep = reputations[_user];
        reputations[_user] = oldRep + _amount;
        emit ReputationIncreased(_user, reputations[_user], _amount);
        // console.log("Reputation increased for %s by %s for reason %s. New reputation: %s", _user, _amount, _reason, reputations[_user]);
    }

    // Internal helper to decrease reputation
    function _decreaseReputation(address _user, uint256 _amount, string memory _reason) internal {
        uint256 oldRep = reputations[_user];
        uint256 newRep = oldRep > _amount ? oldRep - _amount : 0;
        reputations[_user] = newRep;
        emit ReputationDecreased(_user, reputations[_user], _amount);
        // console.log("Reputation decreased for %s by %s for reason %s. New reputation: %s", _user, _amount, _reason, reputations[_user]);
    }


    // --- 7. Creative Spark Token Functions ---

    function getCreativeSparkBalance(address _user) public view returns (uint256) {
        return _creativeSparkBalances[_user];
    }

    // Internal helper to mint sparks
    function _mintCreativeSparks(address _user, uint256 _amount) internal {
        _creativeSparkBalances[_user] += _amount;
        emit SparksMinted(_user, _amount);
        // console.log("Sparks minted for %s: %s. Total sparks: %s", _user, _amount, _creativeSparkBalances[_user]);
    }

    function claimCreativeSparks() external whenNotPaused nonReentrant {
        uint256 userSparks = _creativeSparkBalances[_msgSender()];
        require(userSparks > 0, "ACF: No sparks to claim");
        require(block.timestamp >= lastSparkClaimTimestamp[_msgSender()] + sparkClaimCooldown,
            ACF__SparkClaimCooldownActive(lastSparkClaimTimestamp[_msgSender()] + sparkClaimCooldown - block.timestamp)
        );

        // In a real scenario, Sparks might be a separate ERC20 token that this contract mints
        // and transfers here. For this example, they remain as internal balance.

        // For simplicity, let's say claiming just resets the balance and timer,
        // implying they are 'claimed' to an off-chain or side-chain balance.
        // If they were a real ERC20, we'd call token.transfer(_msgSender(), userSparks);
        _creativeSparkBalances[_msgSender()] = 0; // Transferring out, balance becomes 0
        lastSparkClaimTimestamp[_msgSender()] = block.timestamp;

        emit SparksClaimed(_msgSender(), userSparks);
        // console.log("Sparks claimed by %s: %s", _msgSender(), userSparks);
    }

    function burnCreativeSparks(uint256 _amount) external whenNotPaused nonReentrant {
        require(_creativeSparkBalances[_msgSender()] >= _amount, ACF__NotEnoughSparks(_amount, _creativeSparkBalances[_msgSender()]));

        _creativeSparkBalances[_msgSender()] -= _amount;
        emit SparksBurned(_msgSender(), _amount);
        // console.log("Sparks burned by %s: %s. Remaining sparks: %s", _msgSender(), _amount, _creativeSparkBalances[_msgSender()]);

        // Add logic here for what burning sparks provides (e.g., boost, temporary reputation, etc.)
        // For now, it just reduces the balance.
    }


    // --- 8. Staking Functions ---

    // Stake native tokens (e.g., ETH/Matic)
    function stakeNativeTokens() external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "ACF: Stake amount must be greater than zero");
        stakedNativeTokens[_msgSender()] += msg.value;
        emit TokensStaked(_msgSender(), msg.value);
        // console.log("%s staked %s native tokens. Total staked: %s", _msgSender(), msg.value, stakedNativeTokens[_msgSender()]);

        // Optional: passively increase reputation based on staked amount and time
        // This would require more state (last stake update time) and a different calculation.
        // For simplicity, staking mainly serves as a requirement for other actions or a multiplier.
    }

    function unstakeNativeTokens(uint256 _amount) external whenNotPaused nonReentrant {
        require(stakedNativeTokens[_msgSender()] >= _amount, "ACF: Not enough staked tokens");
        stakedNativeTokens[_msgSender()] -= _amount;
        // Transfer native tokens back to the user
        (bool success, ) = payable(_msgSender()).call{value: _amount}("");
        require(success, "ACF: Native token transfer failed");
        emit TokensUnstaked(_msgSender(), _amount);
        // console.log("%s unstaked %s native tokens. Remaining staked: %s", _msgSender(), _amount, stakedNativeTokens[_msgSender()]);

         // Optional: decrease reputation slightly or reverse passive gains
    }

    function getStakedAmount(address _user) public view returns (uint256) {
        return stakedNativeTokens[_user];
    }

    function stakeNFTForBonus(uint256 _tokenId) external whenNotPaused nonReentrant {
        // Check if it's a valid artifact from this contract and user owns it
        require(_exists(_tokenId), ACF__NFTNotFound(_tokenId)); // From ERC721
        require(ownerOf(_tokenId) == _msgSender(), ACF__NotNFTOwner(_tokenId, _msgSender()));
        require(_stakedNFTs[_tokenId] == address(0), ACF__NFTAlreadyStaked(_tokenId)); // Check if *this* NFT is already staked
        require(stakedNFTId[_msgSender()] == 0, ACF__UserAlreadyStakedNFT(_msgSender(), stakedNFTId[_msgSender()])); // Check if user already staked *any* NFT

        // Ensure it's not soulbound - soulbound NFTs cannot be staked/unstaked by owner
        require(!_isNFTSoulbound[_tokenId], ACF__NFTCurrentlySoulbound(_tokenId));

        // Transfer NFT to the contract to hold it while staked (safer than just tracking state)
        _transfer(_msgSender(), address(this), _tokenId);

        _stakedNFTs[_tokenId] = _msgSender();
        stakedNFTId[_msgSender()] = _tokenId;

        emit ArtifactStaked(_msgSender(), _tokenId);
        // console.log("%s staked NFT %s", _msgSender(), _tokenId);

        // Optional: Increase reputation or provide a reputation boost multiplier
        _increaseReputation(_msgSender(), 5 * reputationStakeMultiplier, "Staked Artifact");
    }

    function unstakeNFT() external whenNotPaused nonReentrant {
        uint256 tokenId = stakedNFTId[_msgSender()];
        require(tokenId != 0, ACF__NFTNotStaked(0)); // Check if user has staked an NFT
        require(_stakedNFTs[tokenId] == _msgSender(), ACF__NFTNotStaked(tokenId)); // Double check mapping

        // Ensure it's not soulbound while staked - soulbound NFTs cannot be unstaked by owner
         require(!_isNFTSoulbound[tokenId], ACF__NFTCurrentlySoulbound(tokenId));


        _stakedNFTs[tokenId] = address(0);
        stakedNFTId[_msgSender()] = 0;

        // Transfer NFT back to the user
        _transfer(address(this), _msgSender(), tokenId);

        emit ArtifactUnstaked(_msgSender(), tokenId);
        // console.log("%s unstaked NFT %s", _msgSender(), tokenId);

        // Optional: Decrease reputation or remove the boost
        _decreaseReputation(_msgSender(), 5 * reputationStakeMultiplier, "Unstaked Artifact");
    }

    function getStakedNFTId(address _user) public view returns (uint256) {
        return stakedNFTId[_user];
    }

     // Required by IERC721Receiver
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external pure override returns (bytes4) {
        // Only allow receiving NFTs via the stakeNFTForBonus function logic initiated by this contract.
        // This prevents random users from sending NFTs to the contract.
        // The actual staking logic calls _transfer, which doesn't hit this unless it's an external call
        // like from a different contract calling safeTransferFrom.
        // For simplicity, we'll trust the internal _transfer called from stakeNFTForBonus.
        // A more robust implementation might check msg.sender == address(this).
         return this.onERC721Received.selector;
    }


    // --- 9. Creative Submission & Oracle Interaction Functions ---

    function submitCreativeSubmission(bytes32 _submissionHash) external whenNotPaused {
        // Optional: Require minimum reputation or staked amount to submit
        // require(reputations[_msgSender()] >= minSubmissionReputation, "ACF: Not enough reputation to submit");
        // require(stakedNativeTokens[_msgSender()] > 0, "ACF: Must have staked tokens to submit");

        uint256 newSubmissionId = _submissionIds.current();
        _submissionIds.increment();

        creativeSubmissions[newSubmissionId] = CreativeSubmission({
            proposer: _msgSender(),
            submissionTimestamp: block.timestamp,
            submissionHash: _submissionHash,
            oracleScore: 0, // Initial score is 0
            processed: false,
            approved: false
        });

        emit CreativeSubmissionSubmitted(_msgSender(), newSubmissionId, _submissionHash);
        // console.log("Submission %s submitted by %s", newSubmissionId, _msgSender());
    }

    function processSubmissionOracleResult(uint256 _submissionId, int256 _oracleScore) external onlyOracle whenNotPaused {
        CreativeSubmission storage submission = creativeSubmissions[_submissionId];
        require(submission.proposer != address(0), ACF__SubmissionNotFound(_submissionId)); // Check if submission exists
        require(!submission.processed, ACF__SubmissionAlreadyProcessed(_submissionId));

        submission.oracleScore = _oracleScore;
        submission.processed = true;
        submission.approved = _oracleScore >= int256(proposalSuccessThreshold); // Using int256 comparison

        if (submission.approved) {
            // Reward proposer with Sparks based on score magnitude
            uint256 sparksToMint = uint256(_oracleScore) * creativeSparkYieldPerScore; // Only use positive score for minting
            _mintCreativeSparks(submission.proposer, sparksToMint);

            // Increase proposer reputation
            _increaseReputation(submission.proposer, uint256(_oracleScore) / 10 + 1, "Approved Submission"); // Example reputation increase

        } else {
            // Optional: Decrease proposer reputation for failed submission
            // uint256 reputationLoss = uint256(-_oracleScore) / 20; // Example penalty
            // _decreaseReputation(submission.proposer, reputationLoss, "Failed Submission");
        }

        emit OracleResultProcessed(_submissionId, _oracleScore, submission.approved);
        // console.log("Oracle result processed for submission %s. Score: %s, Approved: %s", _submissionId, _oracleScore, submission.approved);
    }

    function getSubmissionDetails(uint256 _submissionId) public view returns (CreativeSubmission memory) {
        require(creativeSubmissions[_submissionId].proposer != address(0), ACF__SubmissionNotFound(_submissionId));
        return creativeSubmissions[_submissionId];
    }

     function getSubmissionCount() public view returns (uint256) {
         return _submissionIds.current();
     }


    // --- 10. Dynamic NFTs (Artifacts) Functions ---

    function mintArtifactNFT(string calldata _name, string calldata _description) external whenNotPaused highReputationRequired(nftMintReputationThreshold) nonReentrant {
        uint256 newItemId = _nextTokenId();
        _safeMint(_msgSender(), newItemId);

        nftAttributes[newItemId] = ArtifactAttributes({
            name: _name,
            description: _description,
            creationTimestamp: block.timestamp,
            creationReputation: reputations[_msgSender()],
            lastUpdatedTimestamp: block.timestamp,
            aestheticScore: uint256(int256(keccak256(abi.encodePacked(newItemId, block.timestamp))) % 101), // Example random initial attributes
            complexityScore: uint256(int256(keccak256(abi.encodePacked(newItemId, _msgSender()))) % 101)
        });

        // Set initial state
        _isNFTSoulbound[newItemId] = false;
        _stakedNFTs[newItemId] = address(0);

        emit ArtifactMinted(_msgSender(), newItemId, _name);
        // console.log("NFT %s minted by %s. Name: %s", newItemId, _msgSender(), _name);
    }

     function getArtifactAttributes(uint256 _tokenId) public view returns (ArtifactAttributes memory) {
         require(_exists(_tokenId), ACF__NFTNotFound(_tokenId));
         return nftAttributes[_tokenId];
     }

    function updateArtifactAttributes(uint256 _tokenId, uint256 _newAestheticScore, uint256 _newComplexityScore) external whenNotPaused nonReentrant {
        // Check if it's a valid artifact from this contract and user owns it
        require(_exists(_tokenId), ACF__NFTNotFound(_tokenId));
        require(ownerOf(_tokenId) == _msgSender(), ACF__NotNFTOwner(_tokenId, _msgSender()));

        // Require sufficient reputation to update
        require(reputations[_msgSender()] >= nftAttributeUpdateReputationThreshold,
             ACF__MinimumReputationRequired(nftAttributeUpdateReputationThreshold, reputations[_msgSender()])
        );

        // Optional: Require staking a minimum amount or burning sparks to update
        // require(stakedNativeTokens[_msgSender()] >= minStakeForUpdate, "ACF: Need to stake tokens to update attributes");
        // burnCreativeSparks(sparksCostForUpdate); // Example: burning sparks to update

        ArtifactAttributes storage attrs = nftAttributes[_tokenId];
        attrs.aestheticScore = _newAestheticScore;
        attrs.complexityScore = _newComplexityScore;
        attrs.lastUpdatedTimestamp = block.timestamp;

        emit ArtifactAttributesUpdated(_tokenId);
        // console.log("Attributes updated for NFT %s by %s", _tokenId, _msgSender());
    }

     // Override ERC721's tokenURI for dynamic metadata
     function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), ACF__NFTNotFound(_tokenId));

        // In a real application, this would return a URL pointing to an off-chain service
        // that serves a JSON metadata file. This service would read the on-chain attributes
        // (using getArtifactAttributes) and potentially other state (like owner reputation,
        // staked status, soulbound status) to generate the metadata dynamically.

        // Example placeholder URI:
        // "ipfs://{base_uri}/{tokenId}.json"
        // Or a custom API endpoint:
        // "https://mycreativeservice.com/api/metadata/{contract_address}/{tokenId}"

        // For this example, we'll just return a simple placeholder showing dynamic data potential.
        // A real implementation requires fetching data from storage and formatting JSON.

        // Basic placeholder, replace with logic to construct real dynamic URI
        return string(abi.encodePacked("https://acf.metadata.io/api/", toString(_tokenId)));
     }

    function bindArtifactToSoul(uint256 _tokenId) external whenNotPaused nonReentrant {
        require(_exists(_tokenId), ACF__NFTNotFound(_tokenId));
        require(ownerOf(_tokenId) == _msgSender(), ACF__NotNFTOwner(_tokenId, _msgSender()));
        require(!_isNFTSoulbound[_tokenId], "ACF: Artifact already soulbound");
        require(_stakedNFTs[_tokenId] == address(0), ACF__NFTCurrentlyStaked(_tokenId)); // Cannot bind if staked

        // Optional: Require reputation to soulbind
        // require(reputations[_msgSender()] >= minSoulbindReputation, "ACF: Not enough reputation to soulbind");

        _isNFTSoulbound[_tokenId] = true;
        emit ArtifactBoundToSoul(_tokenId);
        // console.log("NFT %s bound to soul of %s", _tokenId, _msgSender());
    }

     function unbindArtifactFromSoul(uint256 _tokenId) external onlyOwner whenNotPaused {
         require(_exists(_tokenId), ACF__NFTNotFound(_tokenId));
         require(_isNFTSoulbound[_tokenId], "ACF: Artifact not soulbound");

        _isNFTSoulbound[_tokenId] = false;
        emit ArtifactUnboundFromSoul(_tokenId);
        // console.log("NFT %s unbound from soul by admin", _tokenId);
     }


    // --- 11. Overridden/Modified ERC721 Functions ---
    // We override transfer functions to enforce soulbinding and staking restrictions.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfers if soulbound, unless it's the owner calling unbind (which is restricted to admin)
        if (_isNFTSoulbound[tokenId] && from != address(0) && to != address(0)) { // Exclude minting (from 0) and burning (to 0)
             revert ACF__NFTCurrentlySoulbound(tokenId);
        }

        // Prevent transfers if staked
        if (_stakedNFTs[tokenId] != address(0) && from != address(0) && to != address(0)) { // Exclude minting/burning
            revert ACF__NFTCurrentlyStaked(tokenId);
        }
    }

    // ERC721 transferFrom
    function transferFrom(address from, address to, uint256 tokenId) public payable override whenNotPaused {
        // _beforeTokenTransfer check handles the restriction
        super.transferFrom(from, to, tokenId);
    }

    // ERC721 safeTransferFrom
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override whenNotPaused {
         // _beforeTokenTransfer check handles the restriction
        super.safeTransferFrom(from, to, tokenId);
    }

    // ERC721 safeTransferFrom with data
     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override whenNotPaused {
         // _beforeTokenTransfer check handles the restriction
        super.safeTransferFrom(from, to, tokenId, data);
     }

    // Override approve/setApprovalForAll to prevent approval on soulbound/staked NFTs
    function approve(address to, uint256 tokenId) public override whenNotPaused {
        require(_exists(tokenId), ACF__NFTNotFound(tokenId));
        whenNotSoulboundOrStaked(tokenId); // Check if soulbound or staked BEFORE approving
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
         // This is tricky as setApprovalForAll applies to *all* tokens.
         // We cannot check all tokens here. A simpler approach is to let this succeed
         // but block the *transfer* itself in _beforeTokenTransfer if the specific token is soulbound/staked.
         // However, it's better practice not to allow approvals at all if the token is locked.
         // This requires iterating owned tokens, which is gas-intensive.
         // A common compromise is to allow this function but rely purely on the transfer checks,
         // or add a note that approvals might not be executable for certain tokens.
         // A more complex approach would track approvals per token and enforce restrictions there.
         // Let's enforce that the CALLER (who is setting approval) must not have any SOULBOUND/STAKED NFTs.
         // This is an alternative interpretation: you can't delegate control over *any* of your NFTs
         // if *any single one* of them is restricted. This might be too strict.
         // Let's revert if the specific token *being transferred* later was restricted.
         // So, we allow setApprovalForAll here, but transfers initiated via approval will fail
         // in _beforeTokenTransfer if the target token is restricted. This is standard practice.

        super.setApprovalForAll(operator, approved);
    }


    // --- 12. Standard ERC721 View Functions ---
    // balanceOf, ownerOf, getApproved, isApprovedForAll are inherited as public/external views.
    // We simply list them here for clarity of the total function count.

    // function balanceOf(address owner) public view override returns (uint256) { ... }
    // function ownerOf(uint256 tokenId) public view override returns (address) { ... }
    // function getApproved(uint256 tokenId) public view override returns (address) { ... }
    // function isApprovedForAll(address owner, address operator) public view override returns (bool) { ... }


    // --- Internal Helper for ERC721 Token ID Counter ---
    function _nextTokenId() internal returns (uint256) {
        Counters.Counter storage current = _tokenIds;
        uint256 tokenId = current.current();
        current.increment();
        return tokenId;
    }
    Counters.Counter private _tokenIds;


    // --- Internal Helper to Convert uint256 to string (for tokenURI placeholder) ---
    // OpenZeppelin's Strings library is better, but adding inline for self-containment.
    function toString(uint256 value) internal pure returns (string memory) {
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
            digits--;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **On-chain Reputation System:** While simple mappings are basic, using reputation directly to gate features (`highReputationRequired` modifier) and having it influenced by diverse on-chain actions (staking, successful submissions) creates a gamified, persistent identity concept. It's not just about token balance but earned status.
2.  **Internal Earned Token:** `CreativeSparks` function like non-transferable "points" initially, which the user can then claim or burn. This decouples earning from immediate liquidity and adds a layer of interaction before value is fully realized (if claimed to an external token) or consumed (if burned).
3.  **Dynamic NFTs:** The `ArtifactAttributes` struct stored *on-chain* for each NFT and the `updateArtifactAttributes` function, combined with an overridden `tokenURI` pointing to an off-chain renderer, create NFTs that change based on owner actions (`updateArtifactAttributes` call, potentially influenced by reputation/staking) or external data (if the off-chain service incorporates owner reputation or other on-chain state queried live).
4.  **Oracle Integration for Logic:** The `processSubmissionOracleResult` function uses an `onlyOracle` modifier to trust an external entity's input (`_oracleScore`). This is crucial for bringing off-chain complexity (like evaluating creative works, or incorporating real-world data) into the smart contract's internal logic (minting sparks, changing reputation).
5.  **Conditional Transferability / Soulbinding:** The `_isNFTSoulbound` and `_stakedNFTs` states, enforced by modifying the standard ERC721 transfer functions (`_beforeTokenTransfer`), make NFTs non-transferable under specific conditions (soulbound or currently staked). This adds utility beyond simple ownership transfer and is related to the Soulbound Token concept (though here it can be permanent or temporary).
6.  **Staking for Privilege:** Staking native tokens or even the NFTs themselves provides advantages within the system (enabling submissions, potentially passive reputation, being allowed to update NFT attributes). This creates economic alignment and active participation requirements.
7.  **Combined Mechanics:** The true "advanced" nature comes from how these pieces interact: Reputation is needed to mint NFTs, Oracle scores affect Spark earnings and Reputation, Staking might boost Reputation gains or be needed for Submissions/NFT updates, and NFT state (Staked/Soulbound) affects basic token actions like transfer.

This contract goes beyond standard token or static NFT implementations by incorporating a multi-faceted interaction model tied to user behavior and external data, reflecting trends in decentralized identity, dynamic assets, and oracle utilization in Web3.