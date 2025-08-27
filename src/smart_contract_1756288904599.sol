```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

// Custom error definitions for clarity and gas efficiency
error NotAParticipant();
error NotActive();
error VotingRoundNotEnded();
error VotingRoundStillActive();
error PromptAlreadySubmitted();
error ContentDoesNotExist();
error NotAIOracle();
error ContentNotCurated();
error NotAuthorizedToMint();
error InsufficientStake(uint256 required, uint256 actual);
error NoEarningsToClaim();
error AlreadyVoted();
error NotEnoughVotingPower();
error CannotUnstakeWithActiveContributions();
error CannotSubmitEmptyPrompt();
error SelfVotingNotAllowed();
error InvalidRoyaltyPercentage();
error NFTAlreadyMinted();
error ERC721NonexistentToken(uint256 tokenId); // Custom error for non-existent token, similar to OZ but public.

/**
 * @title AetherForge - Decentralized Generative AI Orchestration & Dynamic NFT Co-creation Platform
 * @author AI Smart Contract Guru (Generated)
 * @notice AetherForge is a novel, advanced-concept platform that enables a community to collaboratively
 *         create and curate digital art and content through generative AI models. Participants
 *         stake native `ForgeToken` to gain influence, submit creative prompts, and refine
 *         existing outputs. AI-generated content is then curated by the community via a
 *         reputation-weighted voting system. Approved content can be minted as dynamic NFTs,
 *         whose metadata can evolve. Revenue from NFT sales (e.g., royalties) is distributed
 *         back to contributors based on their stake and reputation.
 *
 * @dev This contract relies on an off-chain AI Oracle to perform actual generative AI
 *      tasks and report results on-chain. It focuses on the on-chain orchestration,
 *      incentivization, governance, and asset management aspects.
 *      It integrates OpenZeppelin's `Ownable`, `ERC721Enumerable`, and `ERC721Royalty`
 *      for robust and standard functionality, with custom extensions for dynamic NFTs
 *      and a reputation system. Custom errors are used for gas efficiency.
 */
contract AetherForge is Ownable, ERC721Enumerable, ERC721Royalty {
    using SafeCast for uint256;

    // --- Outline ---
    // I. State Variables & Constants
    // II. Structs & Mappings
    // III. Events
    // IV. Modifiers
    // V. Core Platform Management (Owner Functions)
    // VI. Staking & Participation
    // VII. Content Submission & Refinement
    // VIII. AI Oracle Interaction & Content Lifecycle
    // IX. Community Curation & Voting
    // X. NFT Management & Dynamic Properties
    // XI. Revenue Distribution & Royalties
    // XII. Reputation & Governance (View Functions)
    // XIII. Internal & Utility Functions

    // --- Function Summary ---

    // I. Initialization & Configuration (Owner-only or Constructor)
    // 1.  constructor(address _forgeToken, address _oracle)
    // 2.  setPlatformActive(bool _status)
    // 3.  updateAIOracleAddress(address _newOracle)
    // 4.  setVotingPeriodDuration(uint256 _duration)
    // 5.  setMinStakingRequirement(uint256 _amount)

    // II. Staking & Participation (User-facing)
    // 6.  stakeForgeTokens(uint256 _amount)
    // 7.  unstakeForgeTokens()
    // 8.  isParticipant(address _user) view returns (bool)

    // III. Content Submission & Refinement (User-facing, Participant-only)
    // 9.  submitInitialPrompt(string memory _promptText)
    // 10. submitRefinementPrompt(bytes32 _parentContentId, string memory _refinementText)

    // IV. AI Oracle Interaction & Content Lifecycle (AI Oracle-only callback & Internal)
    // 11. receiveGeneratedContent(bytes32 _promptId, string memory _contentURI, bytes32 _contentHash)
    // 12. requestContentGeneration(bytes32 _promptId) (Internal, conceptual)

    // V. Community Curation & Voting (Participant-only)
    // 13. voteOnContent(bytes32 _contentId, bool _approve)
    // 14. endorseContent(bytes32 _contentId)
    // 15. finalizeVotingRound(bytes32 _contentId)

    // VI. NFT Management & Dynamic Properties (Minter/Owner-only)
    // 16. mintCuratedNFT(bytes32 _contentId, address _recipient)
    // 17. updateNFTDynamicMetadata(uint256 _tokenId, string memory _newURI, string memory _newDescription)
    // 18. setNFTMinterRole(address _minter, bool _hasRole)

    // VII. Revenue Distribution & Royalties (Owner-only or authorized distributor)
    // 19. distributeContentEarnings(bytes32 _contentId, uint256 _amount)
    // 20. claimMyEarnings()
    // 21. setRoyaltyInfo(address _receiver, uint96 _basisPoints)

    // VIII. Reputation & Governance (View Functions)
    // 22. getParticipantReputation(address _participant) view returns (uint256)
    // 23. getVotingPower(address _participant) view returns (uint256)
    // 24. getContentContributors(bytes32 _contentId) view returns (address[] memory)

    // IX. Security & Ownership (Inherited from Ownable)
    // 25. transferOwnership(address _newOwner)
    // 26. renounceOwnership()

    // --- I. State Variables & Constants ---
    IERC20 public immutable forgeToken;
    address public aiOracle;
    uint256 public minStakingRequirement; // Minimum ForgeToken to participate (in smallest units)
    uint256 public votingPeriodDuration; // Duration for a content voting round in seconds
    bool public platformActive; // Global pause switch

    uint256 private _nextTokenId; // Counter for ERC721 token IDs

    // --- II. Structs & Mappings ---

    // Represents a user's submitted prompt
    struct Prompt {
        address submitter;
        string promptText;
        bytes32 parentContentId; // 0x0 for initial prompts, ID of content being refined
        uint256 submissionTime;
        bytes32 generatedContentId; // ID of content generated from this prompt, once received
        bool isActive; // if prompt is still awaiting generation or has been processed
    }

    // Represents an AI-generated content piece
    enum ContentStatus { Pending, Voting, Curated, Rejected }
    struct Content {
        bytes32 contentHash; // Hash of the contentURI or actual content for integrity
        string contentURI; // IPFS URI or similar
        address submitter; // The original prompt submitter
        bytes32 promptId; // The prompt that led to this content
        uint256 generationTime;
        ContentStatus status;
        uint256 votingEndTime;
        uint256 upvotes;
        uint256 downvotes;
        uint256 totalVoteWeight; // Sum of voting power from all votes
        mapping(address => bool) hasVoted; // Tracks who has voted
        uint256 nftTokenId; // 0 if not minted, otherwise the token ID
        mapping(address => uint256) contributorsStakeAtCreation; // Stake of contributors when content was made
        mapping(address => uint256) earningsClaimed; // Earnings claimed by each contributor
        address[] contributorAddresses; // A list of addresses that contributed to this content (prompter + refiners)
    }

    // Participants data
    struct Participant {
        uint256 stakedAmount;
        uint256 reputation; // Influences voting power and earnings multiplier
        uint256 accumulatedEarnings; // Total earnings for the participant across all content
    }

    // Mappings
    mapping(bytes32 => Prompt) public prompts; // promptId => Prompt
    mapping(bytes32 => Content) public contents; // contentId => Content
    mapping(address => Participant) public participants; // userAddress => Participant
    mapping(address => bool) public isNFTMinter; // Address => bool (can mint NFTs)

    // A mapping to keep track of participant's current involvement to prevent unstaking prematurely
    mapping(address => uint256) public activePromptCount; // number of pending prompts or contents still in voting stage

    // Custom mapping for dynamic per-token URIs (overrides ERC721's default)
    mapping(uint256 => string) private _dynamicTokenURIs;

    // --- III. Events ---
    event PlatformStatusChanged(bool newStatus);
    event AIOracleUpdated(address newOracle);
    event VotingPeriodDurationSet(uint256 duration);
    event MinStakingRequirementSet(uint256 amount);
    event TokensStaked(address indexed participant, uint256 amount);
    event TokensUnstaked(address indexed participant, uint256 amount);
    event PromptSubmitted(bytes32 indexed promptId, address indexed submitter, bytes32 parentContentId);
    event ContentGenerated(bytes32 indexed contentId, bytes32 indexed promptId, string contentURI, bytes32 contentHash);
    event ContentVoted(bytes32 indexed contentId, address indexed voter, bool approved, uint256 votePower);
    event ContentCurated(bytes32 indexed contentId);
    event ContentRejected(bytes32 indexed contentId);
    event NFTMinted(uint256 indexed tokenId, bytes32 indexed contentId, address indexed recipient);
    event NFTMetadataUpdated(uint256 indexed tokenId, string newURI, string newDescription);
    event NFTMinterRoleSet(address indexed minter, bool hasRole);
    event ContentEarningsDistributed(bytes32 indexed contentId, uint256 amount);
    event EarningsClaimed(address indexed participant, uint256 amount);
    event RoyaltyInfoSet(address indexed receiver, uint96 basisPoints);
    event ParticipantReputationUpdated(address indexed participant, int256 delta);

    // --- IV. Modifiers ---

    modifier _checkPlatformActive() {
        if (!platformActive) revert NotActive();
        _;
    }

    modifier _onlyAIOracle() {
        if (_msgSender() != aiOracle) revert NotAIOracle();
        _;
    }

    modifier _onlyParticipant() {
        if (!isParticipant(_msgSender())) revert NotAParticipant();
        _;
    }

    // --- V. Core Platform Management (Owner Functions) ---

    /**
     * @notice Constructor for AetherForge.
     * @param _forgeToken Address of the ERC20 token used for staking.
     * @param _oracle Address of the trusted AI Oracle contract/EOA.
     */
    constructor(address _forgeToken, address _oracle)
        ERC721("AetherForge Dynamic NFT", "AFDN")
        Ownable(_msgSender())
    {
        forgeToken = IERC20(_forgeToken);
        aiOracle = _oracle;
        minStakingRequirement = 10000 * (10 ** forgeToken.decimals()); // Example: 10,000 tokens
        votingPeriodDuration = 3 days; // Example: 3 days for voting
        platformActive = true;
        _nextTokenId = 1; // Start token IDs from 1
    }

    /**
     * @notice Allows the owner to activate or deactivate the platform.
     * @param _status True to activate, false to deactivate.
     */
    function setPlatformActive(bool _status) public onlyOwner {
        platformActive = _status;
        emit PlatformStatusChanged(_status);
    }

    /**
     * @notice Allows the owner to update the address of the AI Oracle.
     * @param _newOracle The new address for the AI Oracle.
     */
    function updateAIOracleAddress(address _newOracle) public onlyOwner {
        aiOracle = _newOracle;
        emit AIOracleUpdated(_newOracle);
    }

    /**
     * @notice Allows the owner to set the duration for content voting rounds.
     * @param _duration The new duration in seconds.
     */
    function setVotingPeriodDuration(uint256 _duration) public onlyOwner {
        votingPeriodDuration = _duration;
        emit VotingPeriodDurationSet(_duration);
    }

    /**
     * @notice Allows the owner to set the minimum ForgeToken required to participate.
     * @param _amount The new minimum staking amount (in smallest units).
     */
    function setMinStakingRequirement(uint256 _amount) public onlyOwner {
        minStakingRequirement = _amount;
        emit MinStakingRequirementSet(_amount);
    }

    // --- VI. Staking & Participation ---

    /**
     * @notice Allows users to stake `ForgeToken` to gain participation rights and influence.
     * @param _amount The amount of ForgeToken to stake.
     */
    function stakeForgeTokens(uint256 _amount) public _checkPlatformActive {
        if (_amount == 0) revert InsufficientStake(minStakingRequirement, 0);
        forgeToken.transferFrom(_msgSender(), address(this), _amount);
        participants[_msgSender()].stakedAmount += _amount;
        if (participants[_msgSender()].reputation == 0) {
            participants[_msgSender()].reputation = 1; // Give initial reputation to new stakers
            emit ParticipantReputationUpdated(_msgSender(), 1);
        }
        emit TokensStaked(_msgSender(), _amount);
    }

    /**
     * @notice Allows users to unstake their tokens.
     * @dev Users cannot unstake if they have active prompts or content in voting phases.
     */
    function unstakeForgeTokens() public _onlyParticipant {
        if (participants[_msgSender()].stakedAmount < minStakingRequirement) {
            revert InsufficientStake(minStakingRequirement, participants[_msgSender()].stakedAmount);
        }
        if (activePromptCount[_msgSender()] > 0) {
            revert CannotUnstakeWithActiveContributions();
        }

        uint256 amountToUnstake = participants[_msgSender()].stakedAmount;
        participants[_msgSender()].stakedAmount = 0;
        forgeToken.transfer(_msgSender(), amountToUnstake);
        emit TokensUnstaked(_msgSender(), amountToUnstake);
    }

    /**
     * @notice Checks if an address meets the current staking requirement.
     * @param _user The address to check.
     * @return True if the user is a participant, false otherwise.
     */
    function isParticipant(address _user) public view returns (bool) {
        return participants[_user].stakedAmount >= minStakingRequirement;
    }

    // --- III. Content Submission & Refinement ---

    /**
     * @notice A participant submits an initial creative prompt for AI generation.
     * @param _promptText The textual description for the AI.
     * @return The unique ID of the submitted prompt.
     */
    function submitInitialPrompt(string memory _promptText) public _checkPlatformActive _onlyParticipant returns (bytes32) {
        if (bytes(_promptText).length == 0) revert CannotSubmitEmptyPrompt();

        bytes32 promptId = keccak256(abi.encodePacked(_msgSender(), _promptText, block.timestamp, "initial")); // Added unique string for different prompt types
        if (prompts[promptId].submitter != address(0)) revert PromptAlreadySubmitted();

        prompts[promptId] = Prompt({
            submitter: _msgSender(),
            promptText: _promptText,
            parentContentId: bytes32(0),
            submissionTime: block.timestamp,
            generatedContentId: bytes32(0),
            isActive: true
        });
        activePromptCount[_msgSender()]++;
        emit PromptSubmitted(promptId, _msgSender(), bytes32(0));

        // In a real system, this would trigger an off-chain call to the AI Oracle.
        // For on-chain logic, we just record the prompt. The oracle needs to pick it up.
        // requestContentGeneration(promptId); // This is an internal conceptual call
        return promptId;
    }

    /**
     * @notice A participant submits a prompt to refine an existing piece of generated content.
     * @param _parentContentId The ID of the content being refined.
     * @param _refinementText The refinement prompt for the AI.
     * @return The unique ID of the submitted refinement prompt.
     */
    function submitRefinementPrompt(bytes32 _parentContentId, string memory _refinementText) public _checkPlatformActive _onlyParticipant returns (bytes32) {
        if (bytes(_refinementText).length == 0) revert CannotSubmitEmptyPrompt();
        if (contents[_parentContentId].submitter == address(0)) revert ContentDoesNotExist();

        bytes32 promptId = keccak256(abi.encodePacked(_msgSender(), _refinementText, _parentContentId, block.timestamp, "refinement"));
        if (prompts[promptId].submitter != address(0)) revert PromptAlreadySubmitted();

        prompts[promptId] = Prompt({
            submitter: _msgSender(),
            promptText: _refinementText,
            parentContentId: _parentContentId,
            submissionTime: block.timestamp,
            generatedContentId: bytes32(0),
            isActive: true
        });
        activePromptCount[_msgSender()]++;
        emit PromptSubmitted(promptId, _msgSender(), _parentContentId);

        // Add the refiner as a contributor to the parent content (indirectly, via the new content created by refinement)
        // The actual `_addContributorToContent` for the new refined content will happen in `receiveGeneratedContent`
        // We add the refiner to the *new* content's contributor list when it's generated, not the parent.

        return promptId;
    }

    // --- IV. AI Oracle Interaction & Content Lifecycle ---

    /**
     * @notice Function called by the trusted AI Oracle to deliver AI-generated content.
     * @dev Only the AI Oracle can call this. It transitions a prompt to a content piece.
     * @param _promptId The ID of the prompt for which content was generated.
     * @param _contentURI The URI (e.g., IPFS) of the generated content.
     * @param _contentHash A hash of the content for integrity verification.
     */
    function receiveGeneratedContent(bytes32 _promptId, string memory _contentURI, bytes32 _contentHash) public _onlyAIOracle {
        Prompt storage prompt = prompts[_promptId];
        if (prompt.submitter == address(0) || !prompt.isActive) revert ContentDoesNotExist(); // Reusing error for invalid prompt ID

        bytes32 contentId = keccak256(abi.encodePacked(_promptId, _contentURI, _contentHash)); // Content ID based on prompt & output
        if (contents[contentId].submitter != address(0)) revert PromptAlreadySubmitted(); // Reusing error for content already existing

        contents[contentId] = Content({
            contentHash: _contentHash,
            contentURI: _contentURI,
            submitter: prompt.submitter,
            promptId: _promptId,
            generationTime: block.timestamp,
            status: ContentStatus.Voting,
            votingEndTime: block.timestamp + votingPeriodDuration,
            upvotes: 0,
            downvotes: 0,
            totalVoteWeight: 0,
            nftTokenId: 0,
            contributorAddresses: new address[](0) // Will be populated next
        });

        // Add the original prompt submitter as a contributor
        _addContributorToContent(contentId, prompt.submitter);

        // If this content is a refinement, all contributors of the parent content are also contributors to the new refined content.
        if (prompt.parentContentId != bytes32(0)) {
            Content storage parentContent = contents[prompt.parentContentId];
            for (uint i = 0; i < parentContent.contributorAddresses.length; i++) {
                _addContributorToContent(contentId, parentContent.contributorAddresses[i]);
            }
        }

        // Store current stake for all contributors at the time of content creation
        for (uint i = 0; i < contents[contentId].contributorAddresses.length; i++) {
            address contributor = contents[contentId].contributorAddresses[i];
            contents[contentId].contributorsStakeAtCreation[contributor] = participants[contributor].stakedAmount;
        }

        prompt.generatedContentId = contentId;
        prompt.isActive = false; // Mark prompt as processed
        activePromptCount[prompt.submitter]--; // Decrement active prompt count

        emit ContentGenerated(contentId, _promptId, _contentURI, _contentHash);
    }

    /**
     * @notice Internal function to conceptually request content generation from the AI Oracle.
     * @dev This function is not directly exposed as it's assumed the AI Oracle monitors for new prompts.
     *      It represents the intent of requesting AI processing.
     * @param _promptId The ID of the prompt to generate content for.
     */
    function requestContentGeneration(bytes32 _promptId) internal {
        // In a real system, this might log an event that an off-chain oracle picks up,
        // or directly call an interface method on the oracle contract if it's on-chain.
        // For this example, the `receiveGeneratedContent` is the callback.
        // No code needed here, as the oracle would listen to PromptSubmitted events.
    }

    // --- V. Community Curation & Voting ---

    /**
     * @notice Participants vote to approve or reject a piece of generated content.
     * @dev Voting power is weighted by stake and reputation.
     * @param _contentId The ID of the content to vote on.
     * @param _approve True for upvote, false for downvote.
     */
    function voteOnContent(bytes32 _contentId, bool _approve) public _checkPlatformActive _onlyParticipant {
        Content storage content = contents[_contentId];
        if (content.submitter == address(0) || content.status != ContentStatus.Voting) revert ContentDoesNotExist();
        if (block.timestamp >= content.votingEndTime) revert VotingRoundNotEnded();
        if (content.hasVoted[_msgSender()]) revert AlreadyVoted();
        if (_msgSender() == content.submitter) revert SelfVotingNotAllowed(); // Prevent self-voting

        uint256 votePower = getVotingPower(_msgSender());
        if (votePower == 0) revert NotEnoughVotingPower();

        if (_approve) {
            content.upvotes += votePower;
        } else {
            content.downvotes += votePower;
        }
        content.totalVoteWeight += votePower;
        content.hasVoted[_msgSender()] = true;

        _updateReputation(_msgSender(), 1); // Small reputation gain for participating

        emit ContentVoted(_contentId, _msgSender(), _approve, votePower);
    }

    /**
     * @notice A participant can "endorse" content, signaling higher confidence.
     * @dev For simplicity, it's a stronger vote (e.g., 2x voting power) and higher reputation gain.
     * @param _contentId The ID of the content to endorse.
     */
    function endorseContent(bytes32 _contentId) public _checkPlatformActive _onlyParticipant {
        Content storage content = contents[_contentId];
        if (content.submitter == address(0) || content.status != ContentStatus.Voting) revert ContentDoesNotExist();
        if (block.timestamp >= content.votingEndTime) revert VotingRoundNotEnded();
        if (content.hasVoted[_msgSender()]) revert AlreadyVoted();
        if (_msgSender() == content.submitter) revert SelfVotingNotAllowed(); // Prevent self-endorsement

        uint256 votePower = getVotingPower(_msgSender());
        if (votePower == 0) revert NotEnoughVotingPower();

        uint256 endorsementPower = votePower * 2; // Endorsement is 2x voting power
        content.upvotes += endorsementPower;
        content.totalVoteWeight += endorsementPower;
        content.hasVoted[_msgSender()] = true;

        _updateReputation(_msgSender(), 5); // Higher reputation gain for endorsement

        emit ContentVoted(_contentId, _msgSender(), true, endorsementPower);
    }

    /**
     * @notice Finalizes a voting round for a specific content piece, tallying votes.
     * @dev Can be called by anyone after the voting period has ended.
     * @param _contentId The ID of the content to finalize.
     */
    function finalizeVotingRound(bytes32 _contentId) public _checkPlatformActive {
        Content storage content = contents[_contentId];
        if (content.submitter == address(0) || content.status != ContentStatus.Voting) revert ContentDoesNotExist();
        if (block.timestamp < content.votingEndTime) revert VotingRoundStillActive();

        // Determine if content is curated or rejected based on vote difference and total participation
        // Example: Must have more upvotes than downvotes and a minimum total vote weight
        if (content.upvotes > content.downvotes && content.totalVoteWeight > 0) { // Simple majority rule
            content.status = ContentStatus.Curated;
            emit ContentCurated(_contentId);
        } else {
            content.status = ContentStatus.Rejected;
            emit ContentRejected(_contentId);
        }

        // Decrement active prompt count for the submitter once voting is finalized
        Prompt storage prompt = prompts[content.promptId];
        // Only decrement if the prompt was actually active and consumed by this content
        if (!prompt.isActive && activePromptCount[prompt.submitter] > 0) {
             activePromptCount[prompt.submitter]--;
        }
    }


    // --- VI. NFT Management & Dynamic Properties ---

    /**
     * @notice Mints a new Dynamic NFT for a *curated* content piece.
     * @dev Callable by approved minters or the content's highest contributor/submitter.
     * @param _contentId The ID of the curated content.
     * @param _recipient The address to receive the NFT.
     */
    function mintCuratedNFT(bytes32 _contentId, address _recipient) public _checkPlatformActive {
        Content storage content = contents[_contentId];
        if (content.submitter == address(0) || content.status != ContentStatus.Curated) revert ContentNotCurated();
        if (content.nftTokenId != 0) revert NFTAlreadyMinted();

        // Only approved minters or the main content submitter can mint
        bool isContributor = false;
        for (uint i = 0; i < content.contributorAddresses.length; i++) {
            if (content.contributorAddresses[i] == _msgSender()) {
                isContributor = true;
                break;
            }
        }
        if (!isNFTMinter[_msgSender()] && !isContributor) revert NotAuthorizedToMint();

        uint256 newTokenId = _nextTokenId++;
        _safeMint(_recipient, newTokenId);
        content.nftTokenId = newTokenId;
        _dynamicTokenURIs[newTokenId] = content.contentURI; // Set initial dynamic URI
        _setTokenRoyalty(newTokenId, _royaltyInfo.receiver, _royaltyInfo.basisPoints); // Set royalty for the NFT

        emit NFTMinted(newTokenId, _contentId, _recipient);
    }

    /**
     * @notice Overrides the default `tokenURI` to support dynamic per-token metadata.
     * @dev This function first checks a custom `_dynamicTokenURIs` mapping for the token ID.
     *      If an entry exists, it returns that URI. Otherwise, it falls back to the default
     *      ERC721 `tokenURI` logic (which would typically use a base URI).
     * @param tokenId The ID of the token.
     * @return The metadata URI for the given token.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        string memory customURI = _dynamicTokenURIs[tokenId];
        if (bytes(customURI).length > 0) {
            return customURI;
        }
        // Fallback to base or default URI if no dynamic URI is set for this token
        // In this setup, _dynamicTokenURIs is the primary source, so `super.tokenURI` might return empty if no baseURI is set.
        return super.tokenURI(tokenId);
    }

    /**
     * @notice Owner can update the metadata URI or description of an existing minted NFT.
     * @dev This makes the NFT dynamic, allowing its visual or contextual metadata to evolve
     *      with new refinements or platform updates.
     * @param _tokenId The ID of the NFT to update.
     * @param _newURI The new URI for the NFT's metadata (e.g., IPFS CID).
     * @param _newDescription A new description for the NFT (not stored on-chain directly in this implementation,
     *                        but serves as a signal for off-chain metadata updates).
     */
    function updateNFTDynamicMetadata(uint256 _tokenId, string memory _newURI, string memory _newDescription) public onlyOwner {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);
        _dynamicTokenURIs[_tokenId] = _newURI; // Update the custom dynamic URI for this token
        emit NFTMetadataUpdated(_tokenId, _newURI, _newDescription);
    }

    /**
     * @notice Owner grants or revokes the ability to mint NFTs to specific addresses.
     * @param _minter The address to grant/revoke minting role.
     * @param _hasRole True to grant, false to revoke.
     */
    function setNFTMinterRole(address _minter, bool _hasRole) public onlyOwner {
        isNFTMinter[_minter] = _hasRole;
        emit NFTMinterRoleSet(_minter, _hasRole);
    }

    // --- VII. Revenue Distribution & Royalties ---

    /**
     * @notice Callable by an authorized entity (e.g., owner or an approved distributor)
     *         to distribute earnings from a specific content piece among its contributors.
     * @dev This simulates receiving royalty payments or direct sales revenue from an external source.
     * @param _contentId The ID of the content that generated earnings.
     * @param _amount The total amount of earnings to distribute for this content.
     */
    function distributeContentEarnings(bytes32 _contentId, uint256 _amount) public onlyOwner { // Or an approved distributor role
        Content storage content = contents[_contentId];
        if (content.submitter == address(0)) revert ContentDoesNotExist();
        if (content.status != ContentStatus.Curated) revert ContentNotCurated();
        if (_amount == 0) return;

        uint256 totalContributorStake = 0;
        for (uint i = 0; i < content.contributorAddresses.length; i++) {
            address contributor = content.contributorAddresses[i];
            totalContributorStake += content.contributorsStakeAtCreation[contributor];
        }

        if (totalContributorStake == 0) {
            // If no stake recorded for contributors, distribute to the primary submitter (if exists) or burn.
            // For now, if no weighted stake, just return.
            return;
        }

        for (uint i = 0; i < content.contributorAddresses.length; i++) {
            address contributor = content.contributorAddresses[i];
            // Share is proportional to stake at creation time, potentially also scaled by reputation.
            // For simplicity, it's just stake proportion.
            uint256 share = (_amount * content.contributorsStakeAtCreation[contributor]) / totalContributorStake;
            participants[contributor].accumulatedEarnings += share;
            _updateReputation(contributor, 10); // Reward reputation for successful earnings
        }
        emit ContentEarningsDistributed(_contentId, _amount);
    }

    /**
     * @notice Participants claim their accrued earnings from successful content.
     */
    function claimMyEarnings() public _onlyParticipant {
        uint256 availableEarnings = participants[_msgSender()].accumulatedEarnings;
        if (availableEarnings == 0) revert NoEarningsToClaim();

        participants[_msgSender()].accumulatedEarnings = 0;
        // Assuming earnings are in ForgeToken for simplicity, or a separate currency
        forgeToken.transfer(_msgSender(), availableEarnings);
        emit EarningsClaimed(_msgSender(), availableEarnings);
    }

    /**
     * @notice Sets the default royalty recipient and percentage for future NFTs.
     * @param _receiver The address to receive royalty fees.
     * @param _basisPoints The royalty percentage in basis points (e.g., 500 for 5%). Max 10000 (100%).
     */
    function setRoyaltyInfo(address _receiver, uint96 _basisPoints) public onlyOwner {
        if (_basisPoints > 10000) revert InvalidRoyaltyPercentage();
        _setDefaultRoyalty(_receiver, _basisPoints); // OpenZeppelin ERC2981 method
        emit RoyaltyInfoSet(_receiver, _basisPoints);
    }

    // --- VIII. Reputation & Governance (View Functions) ---

    /**
     * @notice Returns the current reputation score of a participant.
     * @param _participant The address of the participant.
     * @return The reputation score.
     */
    function getParticipantReputation(address _participant) public view returns (uint256) {
        return participants[_participant].reputation;
    }

    /**
     * @notice Calculates the effective voting power of a participant.
     * @dev Currently `stake * reputation`.
     * @param _participant The address of the participant.
     * @return The calculated voting power.
     */
    function getVotingPower(address _participant) public view returns (uint256) {
        if (!isParticipant(_participant)) return 0;
        // Simple linear weighting for now. Can be more complex (e.g., sqrt, decay).
        return participants[_participant].stakedAmount * participants[_participant].reputation;
    }

    /**
     * @notice Returns a list of addresses that contributed to a specific content piece.
     * @param _contentId The ID of the content.
     * @return An array of contributor addresses.
     */
    function getContentContributors(bytes32 _contentId) public view returns (address[] memory) {
        return contents[_contentId].contributorAddresses;
    }

    // --- IX. Security & Ownership ---

    // The functions `transferOwnership(address _newOwner)` and `renounceOwnership()`
    // are inherited directly from OpenZeppelin's `Ownable` contract.

    // --- XIII. Internal & Utility Functions ---

    /**
     * @dev Internal function to update a participant's reputation.
     * @param _participant The address of the participant.
     * @param _delta The amount to change reputation by (can be negative).
     */
    function _updateReputation(address _participant, int256 _delta) internal {
        if (_delta > 0) {
            participants[_participant].reputation += _delta.toUint256();
        } else {
            uint256 absDelta = (-_delta).toUint256();
            if (participants[_participant].reputation <= absDelta) {
                participants[_participant].reputation = 1; // Minimum reputation is 1
            } else {
                participants[_participant].reputation -= absDelta;
            }
        }
        emit ParticipantReputationUpdated(_participant, _delta);
    }

    /**
     * @dev Adds a contributor to a content piece's list of contributors.
     *      Ensures no duplicates.
     * @param _contentId The ID of the content.
     * @param _contributor The address of the contributor to add.
     */
    function _addContributorToContent(bytes32 _contentId, address _contributor) internal {
        Content storage content = contents[_contentId];
        bool alreadyAdded = false;
        for (uint i = 0; i < content.contributorAddresses.length; i++) {
            if (content.contributorAddresses[i] == _contributor) {
                alreadyAdded = true;
                break;
            }
        }
        if (!alreadyAdded) {
            content.contributorAddresses.push(_contributor);
        }
    }
}
```